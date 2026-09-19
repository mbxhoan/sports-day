alter table public.organizations
  add column if not exists leaderboard_hidden boolean not null default false;

do $migration$
declare
  v_definition text := pg_get_functiondef('public.get_public_page(text, text)'::regprocedure);
  v_old text := $old$      'organizations', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'code', code, 'short_name', short_name, 'name_vi', name_vi, 'name_en', name_en, 'logo_path', logo_path, 'sort_order', sort_order, 'leaderboard_rank', leaderboard_rank, 'gold_medals', gold_medals, 'silver_medals', silver_medals, 'bronze_medals', bronze_medals) order by sort_order) from organizations where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'awards'$old$;
  v_new text := $new$      'organizations', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'code', code, 'short_name', short_name, 'name_vi', name_vi, 'name_en', name_en, 'logo_path', logo_path, 'sort_order', sort_order, 'leaderboard_rank', leaderboard_rank, 'gold_medals', gold_medals, 'silver_medals', silver_medals, 'bronze_medals', bronze_medals) order by sort_order) from organizations where tenant_id = v_tenant_id and archived_at is null and leaderboard_hidden = false), '[]'::jsonb),
      'awards'$new$;
begin
  if strpos(v_definition, v_old) = 0
     or length(v_definition) - length(replace(v_definition, v_old, '')) <> length(v_old) then
    raise exception 'PTSC leaderboard visibility migration could not locate its unique RPC target';
  end if;

  execute replace(v_definition, v_old, v_new);
end;
$migration$;
