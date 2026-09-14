-- PTSC public read model.  This migration is tenant-safe and contains no seed or data repair.
create or replace function public.get_public_page(page text, sport_slug text default null)
returns jsonb
language plpgsql
security invoker
stable
set search_path = public, private
as $$
declare
  v_tenant_id uuid := private.current_tenant_id();
  v_sport_id uuid;
begin
  if v_tenant_id is null then raise exception 'Tenant không hợp lệ'; end if;

  if page = 'shell' then
    return jsonb_build_object(
      'event', coalesce((select jsonb_build_object(
        'event_name_vi', event_name_vi, 'event_name_en', event_name_en,
        'subtitle_vi', subtitle_vi, 'subtitle_en', subtitle_en,
        'about_vi', about_vi, 'about_en', about_en,
        'venue_vi', venue_vi, 'venue_en', venue_en,
        'hero_path', hero_path, 'hero_mobile_path', hero_mobile_path,
        'start_at', start_at, 'end_at', end_at, 'gallery_drive_url', gallery_drive_url
      ) from event_settings where tenant_id = v_tenant_id and singleton_key = 'main' and archived_at is null), '{}'::jsonb),
      'contacts', coalesce((select jsonb_agg(jsonb_build_object(
        'id', id, 'label_vi', label_vi, 'label_en', label_en, 'value', value,
        'href', coalesce(href, ''), 'sort_order', sort_order
      ) order by sort_order) from contacts where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'footerLinks', coalesce((select jsonb_agg(jsonb_build_object(
        'id', id, 'label_vi', label_vi, 'label_en', label_en, 'href', href, 'sort_order', sort_order
      ) order by sort_order) from footer_links where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb)
    );
  end if;

  if page in ('home', 'sports-index') then
    return jsonb_build_object(
      'sports', coalesce((select jsonb_agg(jsonb_build_object(
        'id', id, 'slug', slug, 'name_vi', name_vi, 'name_en', name_en, 'emoji', emoji,
        'description_vi', description_vi, 'description_en', description_en,
        'rules_vi', rules_vi, 'rules_en', rules_en, 'sort_order', sort_order
      ) order by sort_order) from sports where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'tournaments', coalesce((select jsonb_agg(jsonb_build_object(
        'id', id, 'sport_id', sport_id, 'slug', slug, 'name_vi', name_vi, 'name_en', name_en,
        'category_vi', category_vi, 'category_en', category_en, 'format_vi', format_vi, 'format_en', format_en,
        'rules_vi', rules_vi, 'rules_en', rules_en, 'competition_mode', competition_mode,
        'scoring_rule', scoring_rule, 'source_metadata', source_metadata, 'sort_order', sort_order
      ) order by sort_order) from tournaments where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'fixtureCounts', coalesce((select jsonb_object_agg(s.id::text, (select count(*) from fixtures f join tournaments t on t.id = f.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null where f.tenant_id = v_tenant_id and f.archived_at is null and t.sport_id = s.id)) from sports s where s.tenant_id = v_tenant_id and s.archived_at is null), '{}'::jsonb)
    ) || case when page = 'home' then jsonb_build_object(
      'counts', jsonb_build_object(
        'sports', (select count(*) from sports where tenant_id = v_tenant_id and archived_at is null),
        'organizations', (select count(*) from organizations where tenant_id = v_tenant_id and archived_at is null),
        'participants', (select count(*) from participants where tenant_id = v_tenant_id and archived_at is null),
        'fixtures', (select count(*) from fixtures where tenant_id = v_tenant_id and archived_at is null)
      )
    ) else '{}'::jsonb end;
  end if;

  if page = 'sport' then
    select id into v_sport_id from sports where tenant_id = v_tenant_id and slug = sport_slug and archived_at is null;
    return jsonb_build_object(
      'sport', (select jsonb_build_object(
        'id', id, 'slug', slug, 'name_vi', name_vi, 'name_en', name_en, 'emoji', emoji,
        'description_vi', description_vi, 'description_en', description_en,
        'rules_vi', rules_vi, 'rules_en', rules_en, 'sort_order', sort_order
      ) from sports where id = v_sport_id and tenant_id = v_tenant_id and archived_at is null),
      'tournaments', coalesce((select jsonb_agg(jsonb_build_object(
        'id', id, 'sport_id', sport_id, 'slug', slug, 'name_vi', name_vi, 'name_en', name_en,
        'category_vi', category_vi, 'category_en', category_en, 'format_vi', format_vi, 'format_en', format_en,
        'rules_vi', rules_vi, 'rules_en', rules_en, 'competition_mode', competition_mode,
        'scoring_rule', scoring_rule, 'source_metadata', source_metadata, 'sort_order', sort_order
      ) order by sort_order) from tournaments where tenant_id = v_tenant_id and sport_id = v_sport_id and archived_at is null), '[]'::jsonb),
      'organizations', coalesce((select jsonb_agg(jsonb_build_object(
        'id', o.id, 'code', o.code, 'name_vi', o.name_vi, 'name_en', o.name_en, 'logo_path', o.logo_path, 'sort_order', o.sort_order,
        'leaderboard_rank', o.leaderboard_rank, 'gold_medals', o.gold_medals, 'silver_medals', o.silver_medals, 'bronze_medals', o.bronze_medals
      ) order by o.sort_order) from organizations o where o.tenant_id = v_tenant_id and o.archived_at is null and exists (
        select 1 from entries e join tournaments t on t.id = e.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null
        where e.tenant_id = v_tenant_id and e.archived_at is null and t.sport_id = v_sport_id and e.organization_id = o.id
      )), '[]'::jsonb),
      'participants', coalesce((select jsonb_agg(jsonb_build_object(
        'id', p.id, 'organization_id', p.organization_id, 'full_name', p.full_name, 'full_name_en', p.full_name_en
      ) order by p.full_name) from participants p where p.tenant_id = v_tenant_id and p.archived_at is null and exists (
        select 1 from entry_members em join entries e on e.id = em.entry_id and e.tenant_id = v_tenant_id and e.archived_at is null join tournaments t on t.id = e.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null
        where em.tenant_id = v_tenant_id and em.archived_at is null and t.sport_id = v_sport_id and em.participant_id = p.id
      )), '[]'::jsonb),
      'entries', coalesce((select jsonb_agg(jsonb_build_object(
        'id', e.id, 'tournament_id', e.tournament_id, 'organization_id', e.organization_id, 'kind', e.kind, 'name_vi', e.name_vi, 'name_en', e.name_en
      ) order by e.name_vi) from entries e join tournaments t on t.id = e.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null where e.tenant_id = v_tenant_id and e.archived_at is null and t.sport_id = v_sport_id), '[]'::jsonb),
      'entryMembers', coalesce((select jsonb_agg(jsonb_build_object(
        'id', em.id, 'entry_id', em.entry_id, 'participant_id', em.participant_id, 'role_vi', em.role_vi, 'role_en', em.role_en, 'sort_order', em.sort_order
      ) order by em.sort_order) from entry_members em join entries e on e.id = em.entry_id and e.tenant_id = v_tenant_id and e.archived_at is null join tournaments t on t.id = e.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null where em.tenant_id = v_tenant_id and em.archived_at is null and t.sport_id = v_sport_id), '[]'::jsonb),
      'groups', coalesce((select jsonb_agg(jsonb_build_object(
        'id', g.id, 'tournament_id', g.tournament_id, 'name_vi', g.name_vi, 'name_en', g.name_en, 'sort_order', g.sort_order, 'standings_confirmed_at', g.standings_confirmed_at
      ) order by g.sort_order) from groups g join tournaments t on t.id = g.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null where g.tenant_id = v_tenant_id and g.archived_at is null and t.sport_id = v_sport_id), '[]'::jsonb),
      'groupEntries', coalesce((select jsonb_agg(jsonb_build_object(
        'id', ge.id, 'group_id', ge.group_id, 'entry_id', ge.entry_id, 'seed_order', ge.seed_order
      ) order by ge.seed_order) from group_entries ge join groups g on g.id = ge.group_id and g.tenant_id = v_tenant_id and g.archived_at is null join tournaments t on t.id = g.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null where ge.tenant_id = v_tenant_id and ge.archived_at is null and t.sport_id = v_sport_id), '[]'::jsonb),
      'fixtures', coalesce((select jsonb_agg(jsonb_build_object(
        'id', f.id, 'tournament_id', f.tournament_id, 'group_id', f.group_id, 'venue_id', f.venue_id, 'court_id', f.court_id,
        'starts_at', f.starts_at, 'ends_at', f.ends_at, 'status', f.status, 'round_vi', f.round_vi, 'round_en', f.round_en,
        'result_summary_vi', f.result_summary_vi, 'result_summary_en', f.result_summary_en, 'round_order', f.round_order,
        'bracket_position', f.bracket_position, 'next_fixture_id', f.next_fixture_id, 'winner_entry_id', f.winner_entry_id, 'source_code', f.source_code
      ) order by f.starts_at) from fixtures f join tournaments t on t.id = f.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null where f.tenant_id = v_tenant_id and f.archived_at is null and t.sport_id = v_sport_id), '[]'::jsonb),
      'fixtureEntries', coalesce((select jsonb_agg(jsonb_build_object(
        'id', fe.id, 'fixture_id', fe.fixture_id, 'entry_id', fe.entry_id, 'side', fe.side, 'lane', fe.lane, 'seed_order', fe.seed_order,
        'score', fe.score, 'score_numeric', fe.score_numeric, 'rank', fe.rank, 'result_status', fe.result_status, 'result_detail', fe.result_detail
      ) order by fe.seed_order) from fixture_entries fe join fixtures f on f.id = fe.fixture_id and f.tenant_id = v_tenant_id and f.archived_at is null join tournaments t on t.id = f.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null where fe.tenant_id = v_tenant_id and fe.archived_at is null and t.sport_id = v_sport_id), '[]'::jsonb),
      'fixtureSlots', coalesce((select jsonb_agg(jsonb_build_object(
        'id', fs.id, 'fixture_id', fs.fixture_id, 'side', fs.side, 'source_kind', fs.source_kind, 'source_entry_id', fs.source_entry_id,
        'source_group_id', fs.source_group_id, 'source_fixture_id', fs.source_fixture_id, 'source_rank', fs.source_rank, 'label_vi', fs.label_vi, 'label_en', fs.label_en
      )) from fixture_slots fs join fixtures f on f.id = fs.fixture_id and f.tenant_id = v_tenant_id and f.archived_at is null join tournaments t on t.id = f.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null where fs.tenant_id = v_tenant_id and fs.archived_at is null and t.sport_id = v_sport_id), '[]'::jsonb),
      'standings', coalesce((select jsonb_agg(jsonb_build_object(
        'id', s.id, 'tournament_id', s.tournament_id, 'group_id', s.group_id, 'entry_id', s.entry_id, 'played', s.played, 'won', s.won,
        'drawn', s.drawn, 'lost', s.lost, 'score_for', s.score_for, 'score_against', s.score_against, 'points', s.points, 'rank', s.rank
      ) order by s.rank) from standings s join tournaments t on t.id = s.tournament_id and t.tenant_id = v_tenant_id and t.archived_at is null where s.tenant_id = v_tenant_id and s.archived_at is null and t.sport_id = v_sport_id), '[]'::jsonb),
      'venues', coalesce((select jsonb_agg(jsonb_build_object(
        'id', id, 'name_vi', name_vi, 'name_en', name_en, 'address_vi', address_vi, 'address_en', address_en, 'sort_order', sort_order
      ) order by sort_order) from venues where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'courts', coalesce((select jsonb_agg(jsonb_build_object(
        'id', id, 'venue_id', venue_id, 'name_vi', name_vi, 'name_en', name_en, 'sort_order', sort_order
      ) order by sort_order) from courts where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb)
    );
  end if;

  if page = 'schedule' then
    return jsonb_build_object(
      'sports', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'slug', slug, 'name_vi', name_vi, 'name_en', name_en, 'emoji', emoji, 'description_vi', description_vi, 'description_en', description_en, 'rules_vi', rules_vi, 'rules_en', rules_en, 'sort_order', sort_order) order by sort_order) from sports where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'tournaments', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'sport_id', sport_id, 'slug', slug, 'name_vi', name_vi, 'name_en', name_en, 'category_vi', category_vi, 'category_en', category_en, 'format_vi', format_vi, 'format_en', format_en, 'rules_vi', rules_vi, 'rules_en', rules_en, 'competition_mode', competition_mode, 'scoring_rule', scoring_rule, 'source_metadata', source_metadata, 'sort_order', sort_order) order by sort_order) from tournaments where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'organizations', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'code', code, 'name_vi', name_vi, 'name_en', name_en, 'logo_path', logo_path, 'sort_order', sort_order, 'leaderboard_rank', leaderboard_rank, 'gold_medals', gold_medals, 'silver_medals', silver_medals, 'bronze_medals', bronze_medals) order by sort_order) from organizations where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'entries', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'tournament_id', tournament_id, 'organization_id', organization_id, 'kind', kind, 'name_vi', name_vi, 'name_en', name_en) order by name_vi) from entries where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'groups', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'tournament_id', tournament_id, 'name_vi', name_vi, 'name_en', name_en, 'sort_order', sort_order, 'standings_confirmed_at', standings_confirmed_at) order by sort_order) from groups where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'groupEntries', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'group_id', group_id, 'entry_id', entry_id, 'seed_order', seed_order) order by seed_order) from group_entries where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'fixtures', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'tournament_id', tournament_id, 'group_id', group_id, 'venue_id', venue_id, 'court_id', court_id, 'starts_at', starts_at, 'ends_at', ends_at, 'status', status, 'round_vi', round_vi, 'round_en', round_en, 'result_summary_vi', result_summary_vi, 'result_summary_en', result_summary_en, 'round_order', round_order, 'bracket_position', bracket_position, 'next_fixture_id', next_fixture_id, 'winner_entry_id', winner_entry_id, 'source_code', source_code) order by starts_at) from fixtures where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'fixtureEntries', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'fixture_id', fixture_id, 'entry_id', entry_id, 'side', side, 'lane', lane, 'seed_order', seed_order, 'score', score, 'score_numeric', score_numeric, 'rank', rank, 'result_status', result_status, 'result_detail', result_detail) order by seed_order) from fixture_entries where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'fixtureSlots', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'fixture_id', fixture_id, 'side', side, 'source_kind', source_kind, 'source_entry_id', source_entry_id, 'source_group_id', source_group_id, 'source_fixture_id', source_fixture_id, 'source_rank', source_rank, 'label_vi', label_vi, 'label_en', label_en)) from fixture_slots where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'standings', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'tournament_id', tournament_id, 'group_id', group_id, 'entry_id', entry_id, 'played', played, 'won', won, 'drawn', drawn, 'lost', lost, 'score_for', score_for, 'score_against', score_against, 'points', points, 'rank', rank) order by rank) from standings where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'venues', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'name_vi', name_vi, 'name_en', name_en, 'address_vi', address_vi, 'address_en', address_en, 'sort_order', sort_order) order by sort_order) from venues where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'courts', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'venue_id', venue_id, 'name_vi', name_vi, 'name_en', name_en, 'sort_order', sort_order) order by sort_order) from courts where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'participants', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'organization_id', organization_id, 'full_name', full_name, 'full_name_en', full_name_en) order by full_name) from participants where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'entryMembers', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'entry_id', entry_id, 'participant_id', participant_id, 'role_vi', role_vi, 'role_en', role_en, 'sort_order', sort_order) order by sort_order) from entry_members where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb)
    );
  end if;

  if page = 'leaderboard' then
    return jsonb_build_object(
      'organizations', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'code', code, 'name_vi', name_vi, 'name_en', name_en, 'logo_path', logo_path, 'sort_order', sort_order, 'leaderboard_rank', leaderboard_rank, 'gold_medals', gold_medals, 'silver_medals', silver_medals, 'bronze_medals', bronze_medals) order by sort_order) from organizations where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'awards', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'organization_id', organization_id, 'entry_id', entry_id, 'participant_id', participant_id, 'medal', medal, 'title_vi', title_vi, 'title_en', title_en) order by sort_order) from awards where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'entries', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'tournament_id', tournament_id, 'organization_id', organization_id, 'kind', kind, 'name_vi', name_vi, 'name_en', name_en) order by name_vi) from entries where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb),
      'participants', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'organization_id', organization_id, 'full_name', full_name, 'full_name_en', full_name_en) order by full_name) from participants where tenant_id = v_tenant_id and archived_at is null), '[]'::jsonb)
    );
  end if;

  if page = 'gallery' then
    return jsonb_build_object('gallery_drive_url', coalesce((select gallery_drive_url from event_settings where tenant_id = v_tenant_id and singleton_key = 'main' and archived_at is null), ''));
  end if;

  raise exception 'Public page không hợp lệ: %', page using errcode = '22023';
end;
$$;

-- Public pages use the read model, not private source/media tables.
grant usage on schema private to anon;
revoke select on table public.source_documents, public.media from anon;
revoke select on table public.participants from anon, authenticated;
grant select (id, organization_id, full_name, full_name_en) on table public.participants to anon;
grant select on table public.participants to authenticated;

revoke all on function public.get_public_page(text, text) from public;
grant execute on function public.get_public_page(text, text) to anon, authenticated;
