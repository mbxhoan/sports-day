-- The leaderboard JSON had a second, unfiltered organizations key after awards.
-- jsonb_build_object keeps the last duplicate key, so it overrode the filtered list.
do $fix$
declare
  v_definition text := pg_get_functiondef('public.get_public_page(text, text)'::regprocedure);
  v_leaderboard_key constant text := $$if page = 'leaderboard' then$$;
  v_awards_key constant text := $$      'awards', coalesce($$;
  v_organizations_key constant text := $$      'organizations', coalesce($$;
  v_entries_key constant text := $$      'entries', coalesce($$;
  v_organization_query constant text := 'from organizations where tenant_id = v_tenant_id and archived_at is null';
  v_leaderboard_pos integer;
  v_awards_pos integer;
  v_org_pos integer;
  v_entries_pos integer;
  v_query_pos integer;
begin
  v_leaderboard_pos := strpos(v_definition, v_leaderboard_key);
  if v_leaderboard_pos = 0 then
    raise exception 'PTSC leaderboard visibility fix could not locate the leaderboard branch';
  end if;

  v_awards_pos := strpos(substring(v_definition from v_leaderboard_pos), v_awards_key);
  if v_awards_pos = 0 then
    raise exception 'PTSC leaderboard visibility fix could not locate the leaderboard awards block';
  end if;
  v_awards_pos := v_leaderboard_pos + v_awards_pos - 1;

  v_org_pos := strpos(substring(v_definition from v_awards_pos + length(v_awards_key)), v_organizations_key);
  if v_org_pos = 0 then
    if strpos(substring(v_definition from v_leaderboard_pos for v_awards_pos - v_leaderboard_pos), v_organization_query || ' and leaderboard_hidden = false') > 0 then
      return;
    end if;
    raise exception 'PTSC leaderboard visibility fix could not locate the duplicate organizations key';
  end if;
  v_org_pos := v_awards_pos + length(v_awards_key) + v_org_pos - 1;

  v_entries_pos := strpos(substring(v_definition from v_org_pos), v_entries_key);
  v_query_pos := strpos(substring(v_definition from v_org_pos), v_organization_query);
  if v_entries_pos = 0 or v_query_pos = 0 or v_query_pos >= v_entries_pos then
    raise exception 'PTSC leaderboard visibility fix found an unexpected organizations block';
  end if;
  v_entries_pos := v_org_pos + v_entries_pos - 1;

  v_definition := overlay(v_definition placing '' from v_org_pos for v_entries_pos - v_org_pos);
  execute v_definition;
end;
$fix$;
