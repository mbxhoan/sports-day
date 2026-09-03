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

-- Re-run the existing merge against the repaired identity for every tenant.
do $$
declare
  tenant record;
begin
  for tenant in select id from public.tenants loop
    perform private.merge_entry_variants(tenant.id);
  end loop;
end
$$;
