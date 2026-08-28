insert into public.event_settings (
  id, tenant_id, singleton_key, event_name_vi, event_name_en, subtitle_vi, subtitle_en,
  about_vi, about_en, venue_vi, venue_en, hero_path, hero_mobile_path, start_at, end_at
) values (
  '00000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'main',
  'Hội Thao Tổng Công Ty Cổ Phần Dịch Vụ Kỹ Thuật Dầu Khí Việt Nam Lần Thứ 15', 'PTSC 15th Sports Festival',
  '', '', '', '', '', '', '', '', null, null
) on conflict (tenant_id, singleton_key) do update set
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

insert into public.sports (id, tenant_id, slug, name_vi, name_en, emoji, sort_order) values
  ('20000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'pickleball', 'Pickleball', 'Pickleball', '/icons/pickleball.png', 1),
  ('20000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'bong-ban', 'Bóng bàn', 'Table Tennis', '🏓', 2),
  ('20000000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'cau-long', 'Cầu lông', 'Badminton', '🏸', 3),
  ('20000000-0000-0000-0000-000000000004', '22222222-2222-2222-2222-222222222222', 'boi-loi', 'Bơi lội', 'Swimming', '🏊', 4),
  ('20000000-0000-0000-0000-000000000005', '22222222-2222-2222-2222-222222222222', 'keo-co', 'Kéo co', 'Tug of War', '🪢', 5),
  ('20000000-0000-0000-0000-000000000006', '22222222-2222-2222-2222-222222222222', 'dien-kinh', 'Điền kinh', 'Athletics', '🏃', 6),
  ('20000000-0000-0000-0000-000000000007', '22222222-2222-2222-2222-222222222222', 'co-vua', 'Cờ vua', 'Chess', '♟️', 7),
  ('20000000-0000-0000-0000-000000000008', '22222222-2222-2222-2222-222222222222', 'co-tuong', 'Cờ tướng', 'Xiangqi', '♜', 8)
on conflict (tenant_id, slug) do update set
  name_vi = excluded.name_vi, name_en = excluded.name_en, emoji = excluded.emoji, sort_order = excluded.sort_order, archived_at = null;
