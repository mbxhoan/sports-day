insert into public.event_settings (
  id, singleton_key, event_name_vi, event_name_en, subtitle_vi, subtitle_en,
  about_vi, about_en, venue_vi, venue_en, hero_path, hero_mobile_path, start_at, end_at
) values (
  '00000000-0000-0000-0000-000000000001', 'main',
  'Hội thao Petrovietnam 2026', 'Petrovietnam Southern Sports Day 2026',
  'Khu vực phía Nam', 'Southern Region',
  'Sân chơi thể thao gắn kết người lao động Petrovietnam khu vực phía Nam.',
  'A sports festival connecting Petrovietnam employees in the Southern Region.',
  '', '', '/kv.png', '/kv-mobile.png', '2026-09-04 07:00:00+07', '2026-09-06 18:00:00+07'
) on conflict (singleton_key) do update set
  event_name_vi = excluded.event_name_vi,
  event_name_en = excluded.event_name_en,
  subtitle_vi = excluded.subtitle_vi,
  subtitle_en = excluded.subtitle_en,
  about_vi = excluded.about_vi,
  about_en = excluded.about_en,
  hero_path = excluded.hero_path,
  hero_mobile_path = excluded.hero_mobile_path,
  start_at = excluded.start_at,
  end_at = excluded.end_at,
  archived_at = null;

-- Contact fields intentionally remain empty until the organizer supplies approved details.
