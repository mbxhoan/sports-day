set app.tenant_slug = 'petrovietnam2026';

-- Source tables name the stage but not a separate clock time for each individual match.
update public.fixtures f set starts_at = schedule.starts_at
from public.tournaments t join public.sports s on s.id = t.sport_id
join (values
  ('bong-ban','doi-nam-41-50','2026-09-05 07:30:00+07'::timestamptz),
  ('bong-ban','doi-nam-31-40','2026-09-05 07:30:00+07'::timestamptz),
  ('bong-ban','doi-nam-duoi-30','2026-09-05 08:30:00+07'::timestamptz),
  ('bong-ban','doi-nam-nu-31-40','2026-09-05 14:30:00+07'::timestamptz),
  ('bong-ban','doi-nam-nu-41-50','2026-09-05 14:30:00+07'::timestamptz),
  ('bong-ban','doi-nu','2026-09-05 14:30:00+07'::timestamptz),
  ('cau-long','doi-nam-duoi-30','2026-09-05 07:30:00+07'::timestamptz),
  ('cau-long','doi-nam-41-50','2026-09-05 07:30:00+07'::timestamptz),
  ('cau-long','doi-nu-duoi-30','2026-09-05 08:30:00+07'::timestamptz),
  ('cau-long','doi-nu-31-40','2026-09-05 08:30:00+07'::timestamptz),
  ('cau-long','doi-nam-nu-31-40','2026-09-05 09:00:00+07'::timestamptz),
  ('cau-long','doi-nam-nu-41-50','2026-09-05 14:00:00+07'::timestamptz),
  ('pickleball','doi-nam-duoi-30','2026-09-05 07:00:00+07'::timestamptz),
  ('pickleball','doi-nu-duoi-30','2026-09-05 07:00:00+07'::timestamptz),
  ('pickleball','doi-nam-31-40','2026-09-05 07:00:00+07'::timestamptz),
  ('pickleball','doi-nam-41-50','2026-09-05 07:00:00+07'::timestamptz),
  ('pickleball','doi-nu-41-50','2026-09-05 07:00:00+07'::timestamptz),
  ('pickleball','doi-nam-nu-tren-51','2026-09-05 07:00:00+07'::timestamptz),
  ('pickleball','doi-nu-tren-50','2026-09-05 07:00:00+07'::timestamptz),
  ('pickleball','doi-nam-nu-duoi-30','2026-09-06 07:00:00+07'::timestamptz),
  ('pickleball','doi-nam-nu-31-40','2026-09-06 07:00:00+07'::timestamptz),
  ('pickleball','doi-nu-31-40','2026-09-06 07:00:00+07'::timestamptz),
  ('pickleball','doi-nu-41-50','2026-09-06 07:00:00+07'::timestamptz),
  ('pickleball','doi-nam-nu-41-50','2026-09-06 07:00:00+07'::timestamptz)
) as schedule(sport_slug, tournament_slug, starts_at)
  on s.slug = schedule.sport_slug and t.slug = schedule.tournament_slug
where f.tournament_id = t.id and f.group_id is not null and f.starts_at is null;
