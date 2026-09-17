-- PTSC seeded bracket slots are assigned manually after group standings are known.
-- The existing source-driven propagation remains responsible for every later round.

create or replace function private.lock_started_bracket_structure()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  target_fixture_id uuid;
  target_tournament_id uuid;
  target_round_order integer;
  target_bracket_position integer;
  ptsc_tenant boolean := false;
  manual_seed_change boolean := false;
begin
  target_fixture_id := case when tg_op = 'DELETE' then old.fixture_id else new.fixture_id end;

  select fixture.tournament_id, fixture.round_order, fixture.bracket_position,
    exists (
      select 1
      from public.tenants tenant
      where tenant.id = fixture.tenant_id
        and tenant.slug = 'ptsc2026'
        and tenant.archived_at is null
    )
  into target_tournament_id, target_round_order, target_bracket_position, ptsc_tenant
  from public.fixtures fixture
  where fixture.id = target_fixture_id;

  if tg_op = 'INSERT' and ptsc_tenant and target_round_order = 1 and target_bracket_position is not null
    and new.source_kind in ('bye', 'entry')
    and coalesce(nullif(trim(new.label_en), ''), trim(new.label_vi), '') ~* '^seed[[:space:]]+[0-9]+$' then
    manual_seed_change := true;
  elsif tg_op = 'UPDATE' and ptsc_tenant and target_round_order = 1 and target_bracket_position is not null
    and old.source_kind in ('bye', 'entry')
    and new.source_kind in ('bye', 'entry')
    and coalesce(nullif(trim(new.label_en), ''), trim(new.label_vi), '') ~* '^seed[[:space:]]+[0-9]+$' then
    manual_seed_change := true;
  end if;

  if manual_seed_change and not exists (
    select 1
    from public.fixtures fixture
    where fixture.tournament_id = target_tournament_id
      and fixture.bracket_position is not null
      and fixture.archived_at is null
      and (
        fixture.status in ('live', 'completed') or
        fixture.winner_entry_id is not null or
        exists (
          select 1 from public.fixture_entries item
          where item.fixture_id = fixture.id
            and item.archived_at is null
            and (
              item.score is not null or item.score_numeric is not null or
              item.result_status is not null
            )
        )
      )
  ) then
    return new;
  end if;

  if exists (
    select 1
    from public.fixtures fixture
    where fixture.tournament_id = target_tournament_id
      and fixture.archived_at is null
      and (
        fixture.status in ('live', 'completed') or
        fixture.winner_entry_id is not null or
        exists (
          select 1 from public.fixture_entries item
          where item.fixture_id = fixture.id
            and item.archived_at is null
            and (
              item.score is not null or item.score_numeric is not null or
              item.rank is not null or item.result_status is not null
            )
        )
      )
  ) then
    raise exception 'Cấu trúc đã khóa vì hạng mục đã có kết quả';
  end if;

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

revoke all on function private.lock_started_bracket_structure() from public;

create or replace function public.save_fixture_slot_and_sync(
  p_slot_id uuid,
  p_source_kind text,
  p_source_entry_id uuid,
  p_source_group_id uuid,
  p_source_fixture_id uuid,
  p_source_rank integer,
  p_label_vi text,
  p_label_en text
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  slot_row public.fixture_slots%rowtype;
  tournament_id uuid;
  fixture_round_order integer;
  fixture_bracket_position integer;
  ptsc_tenant boolean := false;
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;

  select slot.* into slot_row
  from public.fixture_slots slot
  where slot.id = p_slot_id
    and slot.tenant_id = (select private.current_tenant_id())
    and slot.archived_at is null
  for update;
  if not found then raise exception 'Không tìm thấy ô nhánh'; end if;

  select fixture.tournament_id, fixture.round_order, fixture.bracket_position,
    exists (
      select 1
      from public.tenants tenant
      where tenant.id = fixture.tenant_id
        and tenant.slug = 'ptsc2026'
        and tenant.archived_at is null
    )
  into tournament_id, fixture_round_order, fixture_bracket_position, ptsc_tenant
  from public.fixtures fixture
  where fixture.id = slot_row.fixture_id
    and fixture.archived_at is null;
  if tournament_id is null then raise exception 'Không tìm thấy trận đấu'; end if;

  if ptsc_tenant and p_source_kind = 'entry' and fixture_round_order = 1 and fixture_bracket_position is not null then
    -- ponytail: one transaction lock per tournament keeps seed assignment atomic; split by bracket only if write volume grows.
    perform pg_advisory_xact_lock(hashtextextended(tournament_id::text, 0));
    if exists (
      select 1
      from public.fixture_slots other_slot
      join public.fixtures other_fixture on other_fixture.id = other_slot.fixture_id
      where other_slot.id <> p_slot_id
        and other_slot.tenant_id = (select private.current_tenant_id())
        and other_slot.archived_at is null
        and other_slot.source_kind = 'entry'
        and other_slot.source_entry_id = p_source_entry_id
        and other_fixture.tournament_id = tournament_id
        and other_fixture.round_order = 1
        and other_fixture.bracket_position is not null
        and other_fixture.archived_at is null
    ) then
      raise exception 'Đội đã được chọn ở ô khác trong vòng đầu bracket';
    end if;
  end if;

  update public.fixture_slots
  set source_kind = p_source_kind,
    source_entry_id = p_source_entry_id,
    source_group_id = p_source_group_id,
    source_fixture_id = p_source_fixture_id,
    source_rank = p_source_rank,
    label_vi = coalesce(p_label_vi, ''),
    label_en = coalesce(p_label_en, '')
  where id = p_slot_id;

  perform public.sync_tournament_slots(tournament_id);
end;
$$;

revoke execute on function public.save_fixture_slot_and_sync(uuid, text, uuid, uuid, uuid, integer, text, text) from public, anon;
grant execute on function public.save_fixture_slot_and_sync(uuid, text, uuid, uuid, uuid, integer, text, text) to authenticated;
