-- Merge the same competitor when source files spell its organization differently.
-- Keep the row with the most live result data, move references, archive the duplicate.
create or replace function private.merge_entry_variants(p_tenant_id uuid)
returns integer
language plpgsql
set search_path = public, pg_temp
as $$
declare
  merged_count integer;
begin
  drop table if exists pg_temp.entry_variant_merges;
  create temporary table entry_variant_merges (
    duplicate_id uuid primary key,
    keeper_id uuid not null
  ) on commit drop;

  with candidates as (
    select
      entry.id,
      entry.tournament_id,
      entry.kind,
      case
        when entry.kind in ('pair', 'team') then regexp_replace(lower(trim(entry.name_vi)), '\s*-[^-]*$', '')
        else lower(trim(entry.name_vi))
      end as identity,
      length(entry.name_vi) as name_length,
      (select count(*) from public.fixture_entries item where item.entry_id = entry.id and item.archived_at is null) as fixture_refs,
      (select count(*) from public.standings item where item.entry_id = entry.id and item.archived_at is null) as standing_refs,
      (select count(*) from public.group_entries item where item.entry_id = entry.id and item.archived_at is null) as group_refs
    from public.entries entry
    where entry.tenant_id = p_tenant_id and entry.archived_at is null
  ), ranked as (
    select id, first_value(id) over (
      partition by tournament_id, kind, identity
      order by fixture_refs desc, standing_refs desc, group_refs desc, name_length desc, id
    ) as keeper_id
    from candidates
    where identity <> ''
  )
  insert into entry_variant_merges (duplicate_id, keeper_id)
  select id, keeper_id from ranked where id <> keeper_id;

  update public.fixtures item
  set winner_entry_id = merge.keeper_id
  from entry_variant_merges merge
  where item.tenant_id = p_tenant_id and item.winner_entry_id = merge.duplicate_id;

  update public.fixture_slots item
  set source_entry_id = merge.keeper_id
  from entry_variant_merges merge
  where item.tenant_id = p_tenant_id and item.source_entry_id = merge.duplicate_id;

  update public.awards item
  set entry_id = merge.keeper_id
  from entry_variant_merges merge
  where item.tenant_id = p_tenant_id and item.entry_id = merge.duplicate_id;

  insert into public.entry_members (tenant_id, entry_id, participant_id, role_vi, role_en, sort_order, archived_at)
  select member.tenant_id, merge.keeper_id, member.participant_id, member.role_vi, member.role_en, member.sort_order, member.archived_at
  from public.entry_members member
  join entry_variant_merges merge on merge.duplicate_id = member.entry_id
  where member.tenant_id = p_tenant_id
  on conflict (entry_id, participant_id) do update set
    sort_order = least(public.entry_members.sort_order, excluded.sort_order),
    archived_at = case when public.entry_members.archived_at is null or excluded.archived_at is null then null else excluded.archived_at end;
  delete from public.entry_members item using entry_variant_merges merge
  where item.tenant_id = p_tenant_id and item.entry_id = merge.duplicate_id;

  insert into public.group_entries (tenant_id, group_id, entry_id, seed_order, archived_at)
  select member.tenant_id, member.group_id, merge.keeper_id, member.seed_order, member.archived_at
  from public.group_entries member
  join entry_variant_merges merge on merge.duplicate_id = member.entry_id
  where member.tenant_id = p_tenant_id
  on conflict (group_id, entry_id) do update set
    seed_order = coalesce(public.group_entries.seed_order, excluded.seed_order),
    archived_at = case when public.group_entries.archived_at is null or excluded.archived_at is null then null else excluded.archived_at end;
  delete from public.group_entries item using entry_variant_merges merge
  where item.tenant_id = p_tenant_id and item.entry_id = merge.duplicate_id;

  update public.fixture_entries target
  set side = coalesce(target.side, source.side),
      lane = coalesce(target.lane, source.lane),
      seed_order = coalesce(target.seed_order, source.seed_order),
      score = coalesce(target.score, source.score),
      score_numeric = coalesce(target.score_numeric, source.score_numeric),
      rank = coalesce(target.rank, source.rank),
      result_detail = case when target.result_detail = '{}'::jsonb then source.result_detail else target.result_detail end,
      result_status = coalesce(target.result_status, source.result_status),
      archived_at = case when target.archived_at is null or source.archived_at is null then null else source.archived_at end
  from public.fixture_entries source
  join entry_variant_merges merge on merge.duplicate_id = source.entry_id
  where target.tenant_id = p_tenant_id and source.tenant_id = p_tenant_id
    and target.fixture_id = source.fixture_id and target.entry_id = merge.keeper_id;
  delete from public.fixture_entries source using entry_variant_merges merge
  where source.tenant_id = p_tenant_id and source.entry_id = merge.duplicate_id
    and exists (select 1 from public.fixture_entries target where target.fixture_id = source.fixture_id and target.entry_id = merge.keeper_id);
  update public.fixture_entries item
  set entry_id = merge.keeper_id
  from entry_variant_merges merge
  where item.tenant_id = p_tenant_id and item.entry_id = merge.duplicate_id;

  update public.standings target
  set played = case when target.played = 0 then source.played else target.played end,
      won = case when target.won = 0 then source.won else target.won end,
      drawn = case when target.drawn = 0 then source.drawn else target.drawn end,
      lost = case when target.lost = 0 then source.lost else target.lost end,
      score_for = case when target.score_for = 0 then source.score_for else target.score_for end,
      score_against = case when target.score_against = 0 then source.score_against else target.score_against end,
      points = case when target.points = 0 then source.points else target.points end,
      rank = coalesce(target.rank, source.rank),
      note_vi = coalesce(nullif(target.note_vi, ''), source.note_vi),
      note_en = coalesce(nullif(target.note_en, ''), source.note_en),
      archived_at = case when target.archived_at is null or source.archived_at is null then null else source.archived_at end
  from public.standings source
  join entry_variant_merges merge on merge.duplicate_id = source.entry_id
  where target.tenant_id = p_tenant_id and source.tenant_id = p_tenant_id
    and target.tournament_id = source.tournament_id and target.group_id is not distinct from source.group_id
    and target.entry_id = merge.keeper_id;
  delete from public.standings source using entry_variant_merges merge
  where source.tenant_id = p_tenant_id and source.entry_id = merge.duplicate_id
    and exists (
      select 1 from public.standings target
      where target.tournament_id = source.tournament_id
        and target.group_id is not distinct from source.group_id
        and target.entry_id = merge.keeper_id
    );
  update public.standings item
  set entry_id = merge.keeper_id
  from entry_variant_merges merge
  where item.tenant_id = p_tenant_id and item.entry_id = merge.duplicate_id;

  update public.entries item
  set archived_at = coalesce(item.archived_at, now())
  from entry_variant_merges merge
  where item.tenant_id = p_tenant_id and item.id = merge.duplicate_id;
  get diagnostics merged_count = row_count;
  return merged_count;
end;
$$;

revoke all on function private.merge_entry_variants(uuid) from public;

do $$
declare
  tenant record;
begin
  for tenant in select id from public.tenants loop
    perform private.merge_entry_variants(tenant.id);
  end loop;
end;
$$;
