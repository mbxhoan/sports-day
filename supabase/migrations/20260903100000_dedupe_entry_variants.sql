-- Fold composed/decomposed Vietnamese spellings before comparing competitors.
create or replace function private.entry_identity(p_name text, p_kind text)
returns text
language plpgsql
stable
set search_path = public, pg_temp
as $$
declare
  normalized text := translate(
    lower(trim(coalesce(p_name, ''))),
    'áàảãạăắằẳẵặâấầẩẫậđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ' || chr(768) || chr(769) || chr(771) || chr(777) || chr(803) || chr(774) || chr(770) || chr(795),
    'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy'
  );
  organization_code text;
begin
  if p_kind in ('pair', 'team') then
    for organization_code in
      select lower(trim(code))
      from public.organizations
      where archived_at is null
      order by length(code) desc
    loop
      if length(normalized) > length(organization_code)
        and right(normalized, length(organization_code)) = organization_code
        and left(normalized, length(normalized) - length(organization_code)) ~ '[-[:space:]]$' then
        normalized := regexp_replace(left(normalized, length(normalized) - length(organization_code)), '[-[:space:]]+$', '');
        exit;
      end if;
    end loop;
  end if;
  return regexp_replace(normalized, '[^[:alnum:]]', '', 'g');
end
$$;

revoke all on function private.entry_identity(text, text) from public;

create or replace function private.merge_participant_variants(p_tenant_id uuid)
returns integer
language plpgsql
set search_path = public, pg_temp
as $$
declare
  merged_count integer;
begin
  drop table if exists pg_temp.participant_variant_merges;
  create temporary table participant_variant_merges (
    duplicate_id uuid primary key,
    keeper_id uuid not null
  ) on commit drop;

  with candidates as (
    select
      participant.id,
      participant.organization_id,
      participant.full_name,
      private.entry_identity(participant.full_name, 'individual') as identity,
      participant.full_name !~ ('[' || chr(768) || chr(769) || chr(771) || chr(777) || chr(803) || chr(774) || chr(770) || chr(795) || ']') as composed_name,
      (select count(*) from public.entry_members item where item.participant_id = participant.id and item.archived_at is null) as member_refs,
      (select count(*) from public.awards item where item.participant_id = participant.id and item.archived_at is null) as award_refs
    from public.participants participant
    where participant.tenant_id = p_tenant_id and participant.archived_at is null
  ), ranked as (
    select id, first_value(id) over (
      partition by organization_id, identity
      order by composed_name desc, member_refs desc, award_refs desc, length(full_name) desc, id
    ) as keeper_id
    from candidates
    where identity <> ''
  )
  insert into participant_variant_merges (duplicate_id, keeper_id)
  select id, keeper_id from ranked where id <> keeper_id;

  insert into public.entry_members (tenant_id, entry_id, participant_id, role_vi, role_en, sort_order, archived_at)
  select distinct on (merge.keeper_id, member.entry_id) member.tenant_id, member.entry_id, merge.keeper_id, member.role_vi, member.role_en, member.sort_order, member.archived_at
  from public.entry_members member
  join participant_variant_merges merge on merge.duplicate_id = member.participant_id
  where member.tenant_id = p_tenant_id
  order by merge.keeper_id, member.entry_id, member.archived_at nulls first, member.sort_order, member.id
  on conflict (entry_id, participant_id) do update set
    sort_order = least(public.entry_members.sort_order, excluded.sort_order),
    archived_at = case when public.entry_members.archived_at is null or excluded.archived_at is null then null else excluded.archived_at end;
  delete from public.entry_members item using participant_variant_merges merge
  where item.tenant_id = p_tenant_id and item.participant_id = merge.duplicate_id;

  update public.awards item
  set participant_id = merge.keeper_id
  from participant_variant_merges merge
  where item.tenant_id = p_tenant_id and item.participant_id = merge.duplicate_id;

  update public.participants item
  set archived_at = coalesce(item.archived_at, now())
  from participant_variant_merges merge
  where item.tenant_id = p_tenant_id and item.id = merge.duplicate_id;
  get diagnostics merged_count = row_count;
  return merged_count;
end;
$$;

revoke all on function private.merge_participant_variants(uuid) from public;

do $$
declare
  tenant record;
begin
  for tenant in select id from public.tenants loop
    perform private.merge_participant_variants(tenant.id);
  end loop;
end;
$$;

-- Prefer a precomposed display name before the old reference-preserving merge picks a keeper.
do $$
declare
  tenant record;
begin
  for tenant in select id from public.tenants loop
    with candidates as (
      select
        entry.id,
        entry.tournament_id,
        entry.kind,
        entry.name_vi,
        private.entry_identity(entry.name_vi, entry.kind) as identity,
        entry.name_vi !~ ('[' || chr(768) || chr(769) || chr(771) || chr(777) || chr(803) || chr(774) || chr(770) || chr(795) || ']') as composed_name
      from public.entries entry
      where entry.tenant_id = tenant.id and entry.archived_at is null
    ), ranked as (
      select
        id,
        first_value(name_vi) over (partition by tournament_id, kind, identity order by composed_name desc, length(name_vi) desc, id) as preferred_name,
        count(*) over (partition by tournament_id, kind, identity) as variant_count
      from candidates
      where identity <> ''
    )
    update public.entries item
    set name_vi = ranked.preferred_name
    from ranked
    where item.id = ranked.id
      and ranked.variant_count > 1
      and item.name_vi <> ranked.preferred_name;
  end loop;
end;
$$;

-- Clean existing imports before protecting future admin/import writes.
do $$
declare
  tenant record;
begin
  for tenant in select id from public.tenants loop
    perform private.merge_entry_variants(tenant.id);
  end loop;
end;
$$;

create or replace function private.prevent_duplicate_entry()
returns trigger
language plpgsql
stable
set search_path = public, pg_temp
as $$
begin
  if new.archived_at is null and exists (
    select 1
    from public.entries existing
    where existing.tenant_id = new.tenant_id
      and existing.tournament_id = new.tournament_id
      and existing.kind = new.kind
      and existing.archived_at is null
      and existing.id <> new.id
      and private.entry_identity(existing.name_vi, existing.kind) = private.entry_identity(new.name_vi, new.kind)
  ) then
    raise exception 'Đội/VĐV đã tồn tại trong hạng mục này';
  end if;
  return new;
end;
$$;

drop trigger if exists entries_prevent_duplicate_identity on public.entries;
create trigger entries_prevent_duplicate_identity
before insert or update of tenant_id, tournament_id, kind, name_vi, archived_at on public.entries
for each row execute function private.prevent_duplicate_entry();

revoke all on function private.prevent_duplicate_entry() from public;

create or replace function private.prevent_duplicate_participant()
returns trigger
language plpgsql
stable
set search_path = public, pg_temp
as $$
begin
  if new.archived_at is null and exists (
    select 1
    from public.participants existing
    where existing.tenant_id = new.tenant_id
      and existing.organization_id is not distinct from new.organization_id
      and existing.archived_at is null
      and existing.id <> new.id
      and private.entry_identity(existing.full_name, 'individual') = private.entry_identity(new.full_name, 'individual')
  ) then
    raise exception 'VĐV đã tồn tại trong đơn vị này';
  end if;
  return new;
end;
$$;

drop trigger if exists participants_prevent_duplicate_identity on public.participants;
create trigger participants_prevent_duplicate_identity
before insert or update of tenant_id, organization_id, full_name, archived_at on public.participants
for each row execute function private.prevent_duplicate_participant();

revoke all on function private.prevent_duplicate_participant() from public;
