-- PTSC clone starts with sport templates only.
-- Tournaments, organizations, participants, entries, fixtures stay empty.
insert into public.sports (id, slug, name_vi, name_en, emoji, description_vi, description_en, rules_vi, rules_en, sort_order) values
  ('10000000-0000-0000-0000-000000000001', 'pickleball', 'Pickleball', 'Pickleball', '/icons/pickleball.png', '', '', '', '', 1),
  ('10000000-0000-0000-0000-000000000002', 'bong-ban', 'Bóng bàn', 'Table Tennis', '🏓', '', '', '', '', 2),
  ('10000000-0000-0000-0000-000000000003', 'cau-long', 'Cầu lông', 'Badminton', '🏸', '', '', '', '', 3),
  ('10000000-0000-0000-0000-000000000004', 'boi-loi', 'Bơi lội', 'Swimming', '🏊', '', '', '', '', 4),
  ('10000000-0000-0000-0000-000000000005', 'keo-co', 'Kéo co', 'Tug of War', '🪢', '', '', '', '', 5),
  ('10000000-0000-0000-0000-000000000006', 'dien-kinh', 'Điền kinh', 'Athletics', '🏃', '', '', '', '', 6),
  ('10000000-0000-0000-0000-000000000007', 'co-vua', 'Cờ vua', 'Chess', '♟️', '', '', '', '', 7),
  ('10000000-0000-0000-0000-000000000008', 'co-tuong', 'Cờ tướng', 'Xiangqi', '♜', '', '', '', '', 8)
on conflict (slug) do update set
  name_vi = excluded.name_vi, name_en = excluded.name_en, emoji = excluded.emoji,
  description_vi = excluded.description_vi, description_en = excluded.description_en,
  rules_vi = excluded.rules_vi, rules_en = excluded.rules_en,
  sort_order = excluded.sort_order, archived_at = null;
