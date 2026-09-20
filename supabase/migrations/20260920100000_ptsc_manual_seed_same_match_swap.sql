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
  target_manual_seed boolean := false;
  other_slot_id uuid;
  other_manual_seed boolean := false;
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;

  select fixture.tournament_id, fixture.round_order, fixture.bracket_position,
    exists (
      select 1
      from public.tenants tenant
      where tenant.id = fixture.tenant_id
        and tenant.slug = 'ptsc2026'
        and tenant.archived_at is null
    ),
    coalesce(nullif(trim(slot.label_en), ''), trim(slot.label_vi), '') ~* '^seed[[:space:]]+[0-9]+$'
  into tournament_id, fixture_round_order, fixture_bracket_position, ptsc_tenant, target_manual_seed
  from public.fixture_slots slot
  join public.fixtures fixture on fixture.id = slot.fixture_id
  where slot.id = p_slot_id
    and slot.tenant_id = (select private.current_tenant_id())
    and slot.archived_at is null;
  if not found then raise exception 'Không tìm thấy ô nhánh'; end if;
  if tournament_id is null then raise exception 'Không tìm thấy trận đấu'; end if;

  if ptsc_tenant and p_source_kind = 'entry' and fixture_round_order = 1 and fixture_bracket_position is not null then
    -- ponytail: serialize seed changes per tournament; split by bracket only if write volume grows.
    perform pg_advisory_xact_lock(hashtextextended(tournament_id::text, 0));
  end if;

  select slot.* into slot_row
  from public.fixture_slots slot
  where slot.id = p_slot_id
    and slot.tenant_id = (select private.current_tenant_id())
    and slot.archived_at is null
  for update;
  if not found then raise exception 'Không tìm thấy ô nhánh'; end if;

  if ptsc_tenant and p_source_kind = 'entry' and fixture_round_order = 1 and fixture_bracket_position is not null then
    select other_slot.id,
      coalesce(nullif(trim(other_slot.label_en), ''), trim(other_slot.label_vi), '') ~* '^seed[[:space:]]+[0-9]+$'
    into other_slot_id, other_manual_seed
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
    for update of other_slot;

    if other_slot_id is not null then
      if not target_manual_seed or not other_manual_seed or slot_row.source_kind not in ('entry', 'bye') then
        raise exception 'Đội đã được chọn ở ô khác trong vòng đầu bracket';
      end if;

      -- Vacate the target before swapping: the unique index also covers two seeds in one match.
      update public.fixture_slots
      set source_kind = 'bye', source_entry_id = null, source_group_id = null, source_fixture_id = null, source_rank = null
      where id = p_slot_id;

      update public.fixture_slots other_slot
      set source_kind = case when slot_row.source_kind = 'entry' and slot_row.source_entry_id is not null then 'entry' else 'bye' end,
        source_entry_id = case when slot_row.source_kind = 'entry' then slot_row.source_entry_id else null end,
        source_group_id = null,
        source_fixture_id = null,
        source_rank = null
      where other_slot.id = other_slot_id;
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
