set app.tenant_slug = 'ptsc2026';

create or replace function public.apply_sport_excel_import(p_import_id uuid, p_confirm boolean default false)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_tenant_id uuid := (select private.current_tenant_id());
  import_row public.sport_excel_imports%rowtype;
  export_row public.sport_excel_exports%rowtype;
  v_before_snapshot jsonb;
  v_after_snapshot jsonb;
  operations jsonb := '[]'::jsonb;
  new_refs jsonb := '{}'::jsonb;
  resolved_ops jsonb := '[]'::jsonb;
  op jsonb;
  data jsonb;
  table_name text;
  row_ref text;
  action text;
  row_id uuid;
  current_data jsonb;
  relation_column text;
  relation_table text;
  relation_tenant uuid;
  relation_active boolean;
  dependency text;
  set_data jsonb;
  touched_fixtures jsonb := '{}'::jsonb;
  standing_groups jsonb := '{}'::jsonb;
  v_fixture_id uuid;
  fixture_state record;
  fixture_entries jsonb;
  desired_status text;
  desired_winner uuid;
  desired_summary_vi text;
  desired_summary_en text;
  result_op_found boolean;
  standing_key text;
  standing_tournament uuid;
  standing_group uuid;
  standing_rows jsonb;
  item jsonb;
  change_after jsonb;
  table_order text[] := array['organizations','participants','tournaments','entries','entry_members','venues','courts','groups','group_entries','fixture_entries','fixtures','awards'];
  table_name_loop text;
  ptsc_tenant boolean;
begin
  if not (select private.is_admin()) then raise exception 'Không có quyền quản trị'; end if;
  select exists (
    select 1 from public.tenants tenant
    where tenant.id = v_tenant_id and tenant.slug = 'ptsc2026' and tenant.archived_at is null
  ) into ptsc_tenant;
  select * into import_row from public.sport_excel_imports import_item where import_item.id = p_import_id and import_item.tenant_id = v_tenant_id for update;
  if not found then raise exception 'Không tìm thấy import'; end if;
  if import_row.status <> 'prepared' then raise exception 'Import không còn ở trạng thái chờ áp dụng'; end if;
  if not p_confirm and coalesce(jsonb_array_length(import_row.preview->'warnings'), 0) > 0 then raise exception 'Cần xác nhận các cảnh báo trước khi áp dụng'; end if;
  if coalesce(jsonb_array_length(import_row.preview->'blockers'), 0) > 0 then raise exception 'Import còn lỗi chặn'; end if;
  select * into export_row from public.sport_excel_exports export_item where export_item.id = import_row.export_id and export_item.tenant_id = v_tenant_id and export_item.sport_id = import_row.sport_id and export_item.archived_at is null for update;
  if not found then raise exception 'Snapshot export không tồn tại'; end if;
  operations := import_row.payload->'operations';

  v_before_snapshot := private.sport_excel_snapshot(v_tenant_id, import_row.sport_id);

  for op in select value from jsonb_array_elements(operations) value loop
    table_name := op->>'table'; row_ref := op->>'ref'; action := op->>'action';
    if private.sport_excel_columns(table_name) is null then raise exception 'Bảng Excel không được phép'; end if;
    if action not in ('UPDATE','UPSERT','ARCHIVE') then raise exception 'Thao tác Excel không hợp lệ'; end if;
    if op->>'id' is null or op->>'id' = '' then
      if action <> 'UPSERT' or not left(row_ref, 4) = 'NEW-' then raise exception 'Dòng mới phải dùng mã NEW-* và UPSERT'; end if;
      if new_refs ? (table_name || ':' || row_ref) then raise exception 'Mã dòng mới bị trùng'; end if;
      new_refs := jsonb_set(new_refs, array[table_name || ':' || row_ref], to_jsonb(gen_random_uuid()::text), true);
    else
      row_id := (op->>'id')::uuid;
      if not exists (select 1 from jsonb_array_elements(export_row.payload->'tables'->table_name) exported where exported->>'id' = row_id::text) then raise exception 'Dòng không thuộc snapshot export: %', row_ref; end if;
      execute format('select to_jsonb(item) from public.%I item where item.id = $1 and item.tenant_id = $2', table_name) into current_data using row_id, v_tenant_id;
      if current_data is distinct from op->'base' then raise exception 'Dữ liệu đã thay đổi từ lúc export: %', row_ref; end if;
    end if;
  end loop;

  for op in select value from jsonb_array_elements(operations) value loop
    table_name := op->>'table'; row_ref := op->>'ref'; action := op->>'action';
    if op->>'id' is null or op->>'id' = '' then row_id := (new_refs ->> (table_name || ':' || row_ref))::uuid; else row_id := (op->>'id')::uuid; end if;
    data := private.sport_excel_resolve_data(table_name, op->'data', new_refs);
    foreach relation_column in array private.sport_excel_relation_columns(table_name) loop
      if data ->> relation_column is null or data ->> relation_column = '' then continue; end if;
      relation_table := private.sport_excel_parent_table(table_name, relation_column);
      execute format('select tenant_id, archived_at is null from public.%I where id = $1', relation_table) into relation_tenant, relation_active using (data ->> relation_column)::uuid;
      if relation_tenant is distinct from v_tenant_id or not coalesce(relation_active, false) then raise exception 'Liên kết không hợp lệ tại %', row_ref; end if;
    end loop;
    if action = 'ARCHIVE' then
      dependency := private.sport_excel_archive_dependency(table_name, row_id, v_tenant_id);
      if dependency is not null then raise exception 'Không thể lưu trữ % vì còn dữ liệu phụ thuộc: %', row_ref, dependency; end if;
    end if;
    if table_name = 'organizations' and ((data->>'leaderboard_rank' is not null and (data->>'leaderboard_rank')::integer < 1) or coalesce((data->>'gold_medals')::integer, 0) < 0 or coalesce((data->>'silver_medals')::integer, 0) < 0 or coalesce((data->>'bronze_medals')::integer, 0) < 0) then raise exception 'Hạng hoặc huy chương không hợp lệ tại %', row_ref; end if;
    if table_name = 'entries' and data->>'seed_number' is not null and (data->>'seed_number')::integer < 1 then raise exception 'Seed không hợp lệ tại %', row_ref; end if;
    if table_name = 'fixture_entries' and ((data->>'lane' is not null and (data->>'lane')::integer < 1) or (data->>'rank' is not null and (data->>'rank')::integer < 1) or (data->>'seed_order' is not null and (data->>'seed_order')::integer < 1) or (data->>'score_numeric' is not null and (data->>'score_numeric')::numeric < 0)) then raise exception 'Làn, hạng, seed hoặc điểm trận không hợp lệ tại %', row_ref; end if;
    if table_name = 'fixture_slots' then raise exception 'NGUỒN_NHÁNH chỉ đọc trong Excel'; end if;
    if table_name = 'fixtures' and op->>'id' is not null and data->>'source_code' is distinct from op->'base'->>'source_code' then raise exception 'Không được đổi mã nguồn trận: %', row_ref; end if;
    if table_name = 'fixture_entries' and op->>'id' is not null and exists (select 1 from public.fixture_slots slot where slot.fixture_id = (data->>'fixture_id')::uuid and slot.archived_at is null) and (data->>'entry_id' is distinct from op->'base'->>'entry_id' or data->>'side' is distinct from op->'base'->>'side') then raise exception 'Không được đổi đội/side của trận có nguồn nhánh: %', row_ref; end if;
    set_data := jsonb_set(op, array['data'], data, true);
    set_data := jsonb_set(set_data, array['id'], to_jsonb(row_id::text), true);
    set_data := jsonb_set(set_data, array['is_new'], to_jsonb((op->>'id') is null), true);
    resolved_ops := resolved_ops || jsonb_build_array(set_data);
    if table_name = 'standings' then
      standing_key := (data->>'tournament_id') || ':' || coalesce(data->>'group_id', '');
      standing_groups := jsonb_set(standing_groups, array[standing_key], 'true'::jsonb, true);
    elsif table_name = 'fixtures' and (op->>'id' is null or data->>'status' is distinct from op->'base'->>'status' or data->>'winner_entry_id' is distinct from op->'base'->>'winner_entry_id' or data->>'result_summary_vi' is distinct from op->'base'->>'result_summary_vi' or data->>'result_summary_en' is distinct from op->'base'->>'result_summary_en') then
      touched_fixtures := jsonb_set(touched_fixtures, array[row_id::text], 'true'::jsonb, true);
    elsif table_name = 'fixture_entries' then
      touched_fixtures := jsonb_set(touched_fixtures, array[(data->>'fixture_id')], 'true'::jsonb, true);
    end if;
  end loop;

  for table_name_loop in select unnest(table_order) loop
    for op in select value from jsonb_array_elements(resolved_ops) value where value->>'table' = table_name_loop loop
      table_name := op->>'table'; action := op->>'action'; row_id := (op->>'id')::uuid; data := op->'data';
      if table_name = 'standings' then continue; end if;
      if action = 'ARCHIVE' then perform private.sport_excel_write_row(table_name, row_id, v_tenant_id, data, true); continue; end if;
      if table_name = 'fixtures' and op->>'is_new' <> 'true' and (touched_fixtures ? row_id::text) then
        perform private.sport_excel_write_row(table_name, row_id, v_tenant_id, data, false, array['status','winner_entry_id','result_summary_vi','result_summary_en']);
      elsif table_name = 'fixtures' and op->>'is_new' <> 'true' then
        perform private.sport_excel_write_row(table_name, row_id, v_tenant_id, data, false);
      elsif table_name = 'fixtures' then
        set_data := jsonb_set(data, array['status'], to_jsonb('scheduled'::text), true);
        set_data := jsonb_set(set_data, array['winner_entry_id'], 'null'::jsonb, true);
        set_data := jsonb_set(set_data, array['result_summary_vi'], to_jsonb(''::text), true);
        set_data := jsonb_set(set_data, array['result_summary_en'], to_jsonb(''::text), true);
        perform private.sport_excel_write_row(table_name, row_id, v_tenant_id, set_data, false);
      else
        perform private.sport_excel_write_row(table_name, row_id, v_tenant_id, data, false);
      end if;
    end loop;
  end loop;

  for standing_key in select jsonb_object_keys(standing_groups) loop
    standing_tournament := split_part(standing_key, ':', 1)::uuid;
    standing_group := nullif(split_part(standing_key, ':', 2), '')::uuid;
    select coalesce(jsonb_agg(jsonb_build_object('entry_id', item.entry_id, 'played', item.played, 'won', item.won, 'drawn', item.drawn, 'lost', item.lost, 'score_for', item.score_for, 'score_against', item.score_against, 'points', item.points, 'rank', item.rank) order by item.id), '[]'::jsonb) into standing_rows
    from public.standings item
    where item.tenant_id = v_tenant_id and item.tournament_id = standing_tournament and item.group_id is not distinct from standing_group and item.archived_at is null;
    for op in select value from jsonb_array_elements(resolved_ops) value where value->>'table' = 'standings' and value->'data'->>'tournament_id' = standing_tournament::text and value->'data'->>'group_id' is not distinct from standing_group::text loop
      data := op->'data';
      select coalesce(jsonb_agg(item) filter (where item->>'entry_id' is distinct from data->>'entry_id'), '[]'::jsonb) into standing_rows from jsonb_array_elements(standing_rows) item;
      if op->>'action' <> 'ARCHIVE' then
        standing_rows := standing_rows || jsonb_build_array(jsonb_build_object('entry_id', (data->>'entry_id')::uuid, 'played', coalesce((data->>'played')::integer, 0), 'won', coalesce((data->>'won')::integer, 0), 'drawn', coalesce((data->>'drawn')::integer, 0), 'lost', coalesce((data->>'lost')::integer, 0), 'score_for', coalesce((data->>'score_for')::numeric, 0), 'score_against', coalesce((data->>'score_against')::numeric, 0), 'points', coalesce((data->>'points')::numeric, 0), 'rank', nullif(data->>'rank', '')::integer));
      end if;
    end loop;
    perform public.save_manual_standings(standing_tournament, standing_group, standing_rows);
  end loop;

  for v_fixture_id in
    select fixture.id
    from jsonb_object_keys(touched_fixtures) with ordinality as touched(key, original_order)
    join public.fixtures fixture on fixture.id = touched.key::uuid
      and fixture.tenant_id = v_tenant_id
      and fixture.archived_at is null
    order by
      case when ptsc_tenant then fixture.round_order end nulls first,
      case when ptsc_tenant then fixture.bracket_position end nulls first,
      case when ptsc_tenant then fixture.id::text end,
      touched.original_order
  loop
    select fixture.status, fixture.winner_entry_id, fixture.result_summary_vi, fixture.result_summary_en into fixture_state
    from public.fixtures fixture where fixture.id = v_fixture_id and fixture.tenant_id = v_tenant_id and fixture.archived_at is null;
    if not found then raise exception 'Không tìm thấy trận sau khi cập nhật'; end if;
    select coalesce(jsonb_agg(jsonb_build_object('entry_id', item.entry_id, 'side', item.side, 'lane', item.lane, 'score', item.score, 'score_numeric', item.score_numeric, 'rank', item.rank, 'result_status', item.result_status, 'result_detail', item.result_detail) order by item.id), '[]'::jsonb) into fixture_entries
    from public.fixture_entries item where item.fixture_id = v_fixture_id and item.tenant_id = v_tenant_id and item.archived_at is null;
    select resolved_item->'data'->>'status', nullif(resolved_item->'data'->>'winner_entry_id', '')::uuid, resolved_item->'data'->>'result_summary_vi', resolved_item->'data'->>'result_summary_en' into desired_status, desired_winner, desired_summary_vi, desired_summary_en
    from jsonb_array_elements(resolved_ops) resolved_item where resolved_item->>'table' = 'fixtures' and (resolved_item->>'id')::uuid = v_fixture_id;
    result_op_found := found;
    if not result_op_found then
      desired_status := fixture_state.status;
      desired_winner := fixture_state.winner_entry_id;
      desired_summary_vi := fixture_state.result_summary_vi;
      desired_summary_en := fixture_state.result_summary_en;
    end if;
    if jsonb_array_length(fixture_entries) = 0 and desired_status in ('scheduled','live','postponed','cancelled') and desired_winner is null then
      perform private.sport_excel_write_row('fixtures', v_fixture_id, v_tenant_id, jsonb_build_object('status', desired_status, 'winner_entry_id', desired_winner, 'result_summary_vi', desired_summary_vi, 'result_summary_en', desired_summary_en), false, array['tournament_id','group_id','venue_id','court_id','starts_at','ends_at','round_vi','round_en','round_order','bracket_position','next_fixture_id','source_code']);
    else
      perform public.save_fixture_result(v_fixture_id, desired_status, desired_winner, desired_summary_vi, desired_summary_en, fixture_entries, null);
    end if;
  end loop;

  v_after_snapshot := private.sport_excel_snapshot(v_tenant_id, import_row.sport_id);
  update public.sport_excel_imports import_item set status = 'applied', applied_at = now(), before_snapshot = v_before_snapshot, after_snapshot = v_after_snapshot where import_item.id = p_import_id;

  for table_name_loop in select unnest(array['organizations','participants','tournaments','entries','entry_members','venues','courts','groups','group_entries','fixtures','fixture_entries','fixture_slots','standings','awards']) loop
    for item in select value from jsonb_array_elements(v_before_snapshot->'tables'->table_name_loop) value loop
      select value into change_after from jsonb_array_elements(v_after_snapshot->'tables'->table_name_loop) value where value->>'id' = item->>'id';
      if change_after is null then
        insert into public.sport_excel_changes (tenant_id, import_id, table_name, row_id, action, before_data, after_data) values (v_tenant_id, p_import_id, table_name_loop, (item->>'id')::uuid, 'archive', item, null);
      elsif change_after is distinct from item then
        insert into public.sport_excel_changes (tenant_id, import_id, table_name, row_id, action, before_data, after_data) values (v_tenant_id, p_import_id, table_name_loop, (item->>'id')::uuid, 'update', item, change_after);
      end if;
    end loop;
    for item in select value from jsonb_array_elements(v_after_snapshot->'tables'->table_name_loop) value loop
      if not exists (select 1 from jsonb_array_elements(v_before_snapshot->'tables'->table_name_loop) value where value->>'id' = item->>'id') then
        insert into public.sport_excel_changes (tenant_id, import_id, table_name, row_id, action, before_data, after_data) values (v_tenant_id, p_import_id, table_name_loop, (item->>'id')::uuid, 'insert', null, item);
      end if;
    end loop;
  end loop;
  return jsonb_build_object('import_id', p_import_id, 'status', 'applied');
end;
$$;

revoke execute on function public.apply_sport_excel_import(uuid, boolean) from public, anon;
grant execute on function public.apply_sport_excel_import(uuid, boolean) to authenticated;
