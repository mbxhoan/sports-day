set app.tenant_slug = 'petrovietnam2026';

-- `schedules.pdf` is the formatted master calendar. Sport-specific PDFs keep their more precise times.
create temporary table seed_schedule_blocks (
  sport_slug text, tournament_slug text, starts_at timestamptz, round_vi text, round_en text, round_order integer
) on commit drop;

insert into seed_schedule_blocks values
  ('co-vua','nu','2026-09-05 07:00:00+07','Ván 1 - 4','Games 1 - 4',1),
  ('co-vua','nam-duoi-45','2026-09-05 07:00:00+07','Ván 1 - 4','Games 1 - 4',1),
  ('co-vua','nam-tren-45','2026-09-05 07:00:00+07','Ván 1 - 4','Games 1 - 4',1),
  ('co-tuong','nam-duoi-45','2026-09-05 07:00:00+07','Ván 1 - 4','Games 1 - 4',1),
  ('co-tuong','nam-tren-45','2026-09-05 07:00:00+07','Ván 1 - 4','Games 1 - 4',1),
  ('co-vua','nu','2026-09-05 13:30:00+07','Ván 5 - 7','Games 5 - 7',2),
  ('co-vua','nam-duoi-45','2026-09-05 13:30:00+07','Ván 5 - 7','Games 5 - 7',2),
  ('co-vua','nam-tren-45','2026-09-05 13:30:00+07','Ván 5 - 7','Games 5 - 7',2),
  ('co-tuong','nam-duoi-45','2026-09-05 13:30:00+07','Ván 5 - 7','Games 5 - 7',2),
  ('co-tuong','nam-tren-45','2026-09-05 13:30:00+07','Ván 5 - 7','Games 5 - 7',2),
  ('pickleball','doi-nam-duoi-30','2026-09-05 07:00:00+07','Vòng bảng - Vòng 1/16','Groups - Round of 16',1),
  ('pickleball','doi-nu-duoi-30','2026-09-05 07:00:00+07','Vòng bảng','Group stage',1),
  ('pickleball','doi-nam-31-40','2026-09-05 07:00:00+07','Vòng bảng - Vòng 1/16','Groups - Round of 16',1),
  ('pickleball','doi-nam-41-50','2026-09-05 07:00:00+07','Vòng bảng - Vòng 1/16','Groups - Round of 16',1),
  ('pickleball','doi-nu-41-50','2026-09-05 07:00:00+07','Vòng bảng','Group stage',1),
  ('pickleball','doi-nam-nu-tren-51','2026-09-05 07:00:00+07','Vòng bảng','Group stage',1),
  ('pickleball','doi-nu-tren-50','2026-09-05 07:00:00+07','Vòng tròn - 3 lượt','Round robin - 3 rounds',1),
  ('pickleball','doi-nam-duoi-30','2026-09-05 13:30:00+07','Tứ kết - Bán kết - Chung kết','Quarterfinal - Semifinal - Final',2),
  ('pickleball','doi-nu-duoi-30','2026-09-05 13:30:00+07','Tứ kết - Bán kết - Chung kết','Quarterfinal - Semifinal - Final',2),
  ('pickleball','doi-nam-31-40','2026-09-05 13:30:00+07','Tứ kết - Bán kết - Chung kết','Quarterfinal - Semifinal - Final',2),
  ('pickleball','doi-nam-41-50','2026-09-05 13:30:00+07','Tứ kết - Bán kết - Chung kết','Quarterfinal - Semifinal - Final',2),
  ('pickleball','doi-nu-41-50','2026-09-05 13:30:00+07','Tứ kết - Bán kết - Chung kết','Quarterfinal - Semifinal - Final',2),
  ('pickleball','doi-nam-nu-tren-51','2026-09-05 13:30:00+07','Tứ kết - Bán kết - Chung kết','Quarterfinal - Semifinal - Final',2),
  ('pickleball','doi-nu-tren-50','2026-09-05 13:30:00+07','Thi đấu hai vòng','Two round-robin cycles',2),
  ('pickleball','doi-nam-nu-duoi-30','2026-09-06 07:00:00+07','Vòng bảng - Vòng 1/16 - Tứ kết','Groups - Round of 16 - Quarterfinal',1),
  ('pickleball','doi-nam-nu-31-40','2026-09-06 07:00:00+07','Vòng bảng - Vòng 1/16','Groups - Round of 16',1),
  ('pickleball','doi-nu-31-40','2026-09-06 07:00:00+07','Vòng bảng - Vòng 1/16 - Tứ kết','Groups - Round of 16 - Quarterfinal',1),
  ('pickleball','doi-nu-41-50','2026-09-06 07:00:00+07','Vòng bảng - Tứ kết','Groups - Quarterfinal',1),
  ('pickleball','doi-nam-nu-41-50','2026-09-06 07:00:00+07','Vòng bảng - Vòng 1/16','Groups - Round of 16',1),
  ('pickleball','doi-nam-nu-31-40','2026-09-06 13:30:00+07','Tứ kết - Bán kết - Chung kết','Quarterfinal - Semifinal - Final',2),
  ('pickleball','doi-nam-nu-duoi-30','2026-09-06 13:30:00+07','Bán kết - Chung kết','Semifinal - Final',2),
  ('pickleball','doi-nam-nu-41-50','2026-09-06 13:30:00+07','Bán kết - Chung kết','Semifinal - Final',2),
  ('pickleball','doi-nu-31-40','2026-09-06 13:30:00+07','Bán kết - Chung kết','Semifinal - Final',2),
  ('pickleball','doi-nu-41-50','2026-09-06 13:30:00+07','Bán kết - Chung kết','Semifinal - Final',2);

insert into public.fixtures (tournament_id, starts_at, status, round_vi, round_en, round_order)
select t.id, b.starts_at, 'scheduled', b.round_vi, b.round_en, b.round_order
from seed_schedule_blocks b join public.sports s on s.slug = b.sport_slug
join public.tournaments t on t.sport_id = s.id and t.slug = b.tournament_slug
where not exists (
  select 1 from public.fixtures f
  where f.tournament_id = t.id and f.group_id is null and f.starts_at = b.starts_at and f.round_vi = b.round_vi
);
