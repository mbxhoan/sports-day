-- Treat pair-member order, separators, accents, and attached organization codes consistently.
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
  identity text;
begin
  if p_kind = 'pair' and position('/' in normalized) > 0 then
    select string_agg(part_identity, '' order by part_identity)
    into identity
    from (
      select regexp_replace(part_value, '[^[:alnum:]]', '', 'g') as part_identity
      from regexp_split_to_table(normalized, '/') as split_part(part_value)
    ) parts;
  else
    identity := regexp_replace(normalized, '[^[:alnum:]]', '', 'g');
  end if;

  if p_kind = 'team' or (p_kind = 'pair' and position('/' in normalized) > 0) then
    for organization_code in
      select lower(trim(code))
      from public.organizations
      where archived_at is null
      order by length(code) desc
    loop
      organization_code := regexp_replace(
        translate(
          organization_code,
          'áàảãạăắằẳẵặâấầẩẫậđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ' || chr(768) || chr(769) || chr(771) || chr(777) || chr(803) || chr(774) || chr(770) || chr(795),
          'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy'
        ),
        '[^[:alnum:]]', '', 'g'
      );
      if length(identity) > length(organization_code)
        and right(identity, length(organization_code)) = organization_code then
        identity := left(identity, length(identity) - length(organization_code));
        exit;
      end if;
    end loop;
  end if;

  return identity;
end
$$;

revoke all on function private.entry_identity(text, text) from public;

-- The latest 31-40 workbook replaces this older PDF-only pair registration.
create or replace function private.archive_obsolete_pickleball_pair(p_tenant_id uuid)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
declare
  obsolete_entry_id uuid;
begin
  select entry.id
  into obsolete_entry_id
  from public.entries entry
  join public.tournaments tournament on tournament.id = entry.tournament_id
  join public.sports sport on sport.id = tournament.sport_id
  where entry.tenant_id = p_tenant_id
    and sport.slug = 'pickleball'
    and tournament.slug = 'doi-nam-31-40'
    and entry.kind = 'pair'
    and entry.name_vi = 'Hoàng Ngọc Quý / Nguyễn Minh Tú-PVG'
    and entry.archived_at is null
  order by entry.id
  limit 1;

  if obsolete_entry_id is null then return; end if;

  update public.fixtures fixture
  set archived_at = now()
  where fixture.tenant_id = p_tenant_id
    and fixture.archived_at is null
    and fixture.status in ('scheduled', 'postponed', 'cancelled')
    and fixture.winner_entry_id is null
    and exists (
      select 1 from public.fixture_entries item
      where item.fixture_id = fixture.id and item.entry_id = obsolete_entry_id and item.archived_at is null
    )
    and not exists (
      select 1 from public.fixture_entries item
      where item.fixture_id = fixture.id and item.archived_at is null
        and (item.score is not null or item.score_numeric is not null or item.rank is not null or item.result_status is not null)
    );

  update public.fixture_entries item
  set archived_at = coalesce(item.archived_at, now())
  where item.tenant_id = p_tenant_id and item.entry_id = obsolete_entry_id and item.archived_at is null;
  update public.group_entries item
  set archived_at = coalesce(item.archived_at, now())
  where item.tenant_id = p_tenant_id and item.entry_id = obsolete_entry_id and item.archived_at is null;
  update public.standings item
  set archived_at = coalesce(item.archived_at, now())
  where item.tenant_id = p_tenant_id and item.entry_id = obsolete_entry_id and item.archived_at is null;
  update public.entry_members item
  set archived_at = coalesce(item.archived_at, now())
  where item.tenant_id = p_tenant_id and item.entry_id = obsolete_entry_id and item.archived_at is null;
  update public.entries item
  set archived_at = now()
  where item.tenant_id = p_tenant_id and item.id = obsolete_entry_id;
end
$$;

revoke all on function private.archive_obsolete_pickleball_pair(uuid) from public;

-- Re-run the existing merge against the repaired identity for every tenant.
do $$
declare
  tenant record;
begin
  for tenant in select id from public.tenants loop
    perform private.merge_entry_variants(tenant.id);
    perform private.archive_obsolete_pickleball_pair(tenant.id);
  end loop;
end
$$;
