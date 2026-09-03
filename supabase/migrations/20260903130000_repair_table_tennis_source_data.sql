set app.tenant_slug = 'petrovietnam2026';

-- Repair source typos and page-continuation groups without deleting history.
do $$
declare
  tournament_id uuid;
  old_group_id uuid;
  target_group_id uuid;
begin
  -- Bảng 6 is the second 31-40 group used by the source bracket: Bảng B.
  select t.id into tournament_id
  from public.tournaments t
  join public.sports s on s.id = t.sport_id
  where s.slug = 'bong-ban' and t.slug = 'doi-nam-31-40';
  if tournament_id is not null then
    select group_row.id into old_group_id from public.groups group_row where group_row.tournament_id = tournament_id and group_row.name_vi = 'Bảng 6' and group_row.archived_at is null;
    select group_row.id into target_group_id from public.groups group_row where group_row.tournament_id = tournament_id and group_row.name_vi = 'Bảng B' and group_row.archived_at is null;
    if old_group_id is not null and target_group_id is not null then
      insert into public.group_entries (tenant_id, group_id, entry_id)
      select tenant_id, target_group_id, entry_id from public.group_entries
      where group_id = old_group_id and archived_at is null
      on conflict (group_id, entry_id) do update set archived_at = null;
      update public.group_entries set archived_at = now() where group_id = old_group_id and archived_at is null;
      update public.standings source_standing set archived_at = now()
      where source_standing.group_id = old_group_id and source_standing.archived_at is null
        and exists (select 1 from public.standings current where current.group_id = target_group_id and current.entry_id = source_standing.entry_id and current.archived_at is null);
      update public.standings set group_id = target_group_id where group_id = old_group_id and archived_at is null;
      update public.groups set archived_at = now() where id = old_group_id;
    end if;
  end if;

  -- Continuation-page lists belong to Bảng B for these two table-tennis events.
  for tournament_id, old_group_id, target_group_id in
    select t.id, list_group.id, target_group.id
    from public.tournaments t
    join public.sports s on s.id = t.sport_id
    join public.groups list_group on list_group.tournament_id = t.id and list_group.name_vi = 'Danh sách' and list_group.archived_at is null
    join public.groups target_group on target_group.tournament_id = t.id and target_group.name_vi = 'Bảng B' and target_group.archived_at is null
    where s.slug = 'bong-ban' and t.slug in ('doi-nu', 'doi-nam-nu-31-40')
  loop
    insert into public.group_entries (tenant_id, group_id, entry_id)
    select tenant_id, target_group_id, entry_id from public.group_entries
    where group_id = old_group_id and archived_at is null
    on conflict (group_id, entry_id) do update set archived_at = null;
    update public.group_entries set archived_at = now() where group_id = old_group_id and archived_at is null;
    update public.standings set archived_at = now() where group_id = old_group_id and archived_at is null;
    update public.groups set archived_at = now() where id = old_group_id;
  end loop;

  -- Other lists are roster rows, never competition groups.
  for tournament_id, old_group_id in
    select t.id, g.id
    from public.groups g
    join public.tournaments t on t.id = g.tournament_id
    join public.sports s on s.id = t.sport_id
    where s.slug in ('bong-ban', 'cau-long') and g.name_vi = 'Danh sách' and g.archived_at is null
  loop
    update public.group_entries set archived_at = now() where group_id = old_group_id and archived_at is null;
    update public.standings set archived_at = now() where group_id = old_group_id and archived_at is null;
    update public.groups set archived_at = now() where id = old_group_id;
  end loop;

  -- Table tennis 41-50 entries 13-16 belong to D, not C.
  select g.id into target_group_id
  from public.groups g
  join public.tournaments t on t.id = g.tournament_id
  join public.sports s on s.id = t.sport_id
  where s.slug = 'bong-ban' and t.slug = 'doi-nam-41-50' and g.name_vi = 'Bảng D' and g.archived_at is null;
  if target_group_id is not null then
    insert into public.group_entries (tenant_id, group_id, entry_id)
    select ge.tenant_id, target_group_id, ge.entry_id
    from public.group_entries ge
    join public.entries e on e.id = ge.entry_id
    where ge.archived_at is null and e.name_vi in (
      'Đinh Chí Thanh / Nguyễn Ngọc Hòe-PVE',
      'Hoàng Quang Thịnh / Trần Quang Bình-VSP',
      'Đinh Quang Vinh / Lê Văn ChoPVFCCo',
      'Bùi Công Tâm / Nguyễn Vũ Hiệp-PVG'
    )
    on conflict (group_id, entry_id) do update set archived_at = null;
    update public.group_entries ge set archived_at = now()
    from public.entries e
    where ge.entry_id = e.id and ge.archived_at is null and ge.group_id <> target_group_id
      and e.name_vi in ('Đinh Chí Thanh / Nguyễn Ngọc Hòe-PVE','Hoàng Quang Thịnh / Trần Quang Bình-VSP','Đinh Quang Vinh / Lê Văn ChoPVFCCo','Bùi Công Tâm / Nguyễn Vũ Hiệp-PVG');
  end if;
end
$$;

update public.entries e
set name_vi = 'Nguyễn Văn Hiếu / Vũ Văn Sỹ-VSP', name_en = 'Nguyễn Văn Hiếu / Vũ Văn Sỹ-VSP'
where e.name_vi = 'Nguyễn Văn Hiếu / Vũ Văn Sỹ--VSP' and e.archived_at is null;
update public.participants p
set full_name = 'Vũ Văn Sỹ'
where p.full_name = 'Vũ Văn Sỹ-' and p.archived_at is null;

-- Remove duplicate scheduled round-robin fixtures across supplied pair-sport seeds.
do $$
declare
  duplicate_fixture uuid;
begin
  for duplicate_fixture in
    with fixture_pairs as (
      select f.id, f.tournament_id, f.group_id, array_agg(fe.entry_id order by fe.entry_id) as pair_key
      from public.fixtures f
      join public.tournaments t on t.id = f.tournament_id
      join public.sports s on s.id = t.sport_id
      join public.fixture_entries fe on fe.fixture_id = f.id and fe.archived_at is null
      where s.slug in ('bong-ban', 'cau-long')
        and f.group_id is not null and f.round_vi = 'Vòng bảng' and f.archived_at is null
      group by f.id
      having count(*) = 2
    ), duplicates as (
      select id, row_number() over (partition by tournament_id, group_id, pair_key order by id) as duplicate_number
      from fixture_pairs
    )
    select id from duplicates where duplicate_number > 1
  loop
    update public.fixture_entries set archived_at = now() where fixture_id = duplicate_fixture and archived_at is null;
    update public.fixtures set archived_at = now() where id = duplicate_fixture;
  end loop;
end
$$;

-- Unplayed 31-40 Bảng B must not display imported ranking.
update public.standings standing
set played = 0, won = 0, drawn = 0, lost = 0,
    score_for = 0, score_against = 0, points = 0, rank = null
from public.groups group_row
join public.tournaments tournament on tournament.id = group_row.tournament_id
join public.sports sport on sport.id = tournament.sport_id
where standing.group_id = group_row.id
  and sport.slug = 'bong-ban' and tournament.slug = 'doi-nam-31-40'
  and group_row.name_vi = 'Bảng B'
  and not exists (select 1 from public.fixtures f where f.group_id = group_row.id and f.status = 'completed' and f.archived_at is null);
update public.groups group_row
set standings_confirmed_at = null
from public.tournaments tournament
join public.sports sport on sport.id = tournament.sport_id
where group_row.tournament_id = tournament.id
  and sport.slug = 'bong-ban' and tournament.slug = 'doi-nam-31-40'
  and group_row.name_vi = 'Bảng B'
  and not exists (select 1 from public.fixtures f where f.group_id = group_row.id and f.status = 'completed' and f.archived_at is null);
