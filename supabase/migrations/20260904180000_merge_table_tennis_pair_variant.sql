set app.tenant_slug = 'petrovietnam2026';

-- Merge the PDF typo "Nguyễn V Vinh" into the canonical "Nguyễn Văn Vinh" pair.
do $$
declare
  v_tournament_id uuid;
  keeper_id uuid;
  duplicate_id uuid;
begin
  select t.id into v_tournament_id
  from public.tournaments t
  join public.sports s on s.id = t.sport_id
  where s.slug = 'bong-ban' and t.slug = 'doi-nam-31-40';

  if v_tournament_id is null then return; end if;

  select e.id into keeper_id
  from public.entries e
  where e.tournament_id = v_tournament_id
    and e.kind = 'pair'
    and e.name_vi = 'Phan Ngọc Lai / Nguyễn Văn Vinh - PVTRANS'
    and e.archived_at is null
  order by e.id
  limit 1;

  select e.id into duplicate_id
  from public.entries e
  where e.tournament_id = v_tournament_id
    and e.kind = 'pair'
    and e.name_vi = 'Phan Ngọc Lai/ Nguyễn V Vinh- PVTRANS'
    and e.archived_at is null
  order by e.id
  limit 1;

  if duplicate_id is null then return; end if;

  if keeper_id is null then
    update public.entries
    set name_vi = 'Phan Ngọc Lai / Nguyễn Văn Vinh - PVTRANS',
        name_en = 'Phan Ngọc Lai / Nguyễn Văn Vinh - PVTRANS'
    where id = duplicate_id;
    return;
  end if;

  update public.group_entries duplicate
  set archived_at = coalesce(duplicate.archived_at, now())
  where duplicate.entry_id = duplicate_id
    and duplicate.archived_at is null
    and exists (
      select 1 from public.group_entries keeper
      where keeper.group_id = duplicate.group_id
        and keeper.entry_id = keeper_id
        and keeper.archived_at is null
    );
  update public.group_entries
  set entry_id = keeper_id
  where entry_id = duplicate_id and archived_at is null;

  update public.standings duplicate
  set archived_at = coalesce(duplicate.archived_at, now())
  where duplicate.entry_id = duplicate_id
    and duplicate.archived_at is null
    and exists (
      select 1 from public.standings keeper
      where keeper.tournament_id = duplicate.tournament_id
        and keeper.group_id is not distinct from duplicate.group_id
        and keeper.entry_id = keeper_id
    );
  update public.standings
  set entry_id = keeper_id
  where entry_id = duplicate_id and archived_at is null;

  update public.fixture_entries duplicate
  set archived_at = coalesce(duplicate.archived_at, now())
  where duplicate.entry_id = duplicate_id
    and duplicate.archived_at is null
    and exists (
      select 1 from public.fixture_entries keeper
      where keeper.fixture_id = duplicate.fixture_id
        and keeper.entry_id = keeper_id
        and keeper.archived_at is null
    );
  update public.fixture_entries
  set entry_id = keeper_id
  where entry_id = duplicate_id and archived_at is null;

  update public.entry_members
  set archived_at = coalesce(archived_at, now())
  where entry_id = duplicate_id and archived_at is null;
  update public.entries
  set archived_at = coalesce(archived_at, now())
  where id = duplicate_id;
end
$$;
