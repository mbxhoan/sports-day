set app.tenant_slug = 'petrovietnam2026';

insert into public.source_documents (raw_filename, sha256, page_count, sport_slug, imported, notes, reviewed_at) values
  ('cl p nam2026 (1).pdf','467cdc0f60c31015f7373777c02e8ed3f0544c0b35ce0f9a5593e1fec69e576e',13,'cau-long',true,'Lịch và bảng đấu; một số ô kết quả để trống trong nguồn.',now()),
  ('cờ tướng bảng nam trên 45t.pdf','7663b049432edc860f652da6a1eaf12165b3e25972c360161b0762f3e908e5ba',1,'co-tuong',true,'Danh sách ban đầu từ Chess-Results.',now()),
  ('cờ tướng bảng nam dưới 45t.pdf','13f9ff74428673edc37c0d1f8a90ba2e70c88bcb1c8b645031c8e1661afa7405',1,'co-tuong',true,'Danh sách ban đầu từ Chess-Results.',now()),
  ('cờ vua bảng nam trên 45t.pdf','67b7daa29a9e167761b330b522c306717787cdfa48450db259801fe7e1505845',1,'co-vua',true,'Danh sách ban đầu từ Chess-Results.',now()),
  ('cờ vua bảng nam dưới 45t.pdf','dbb12a4569997683104731229beac9a29f1cf63e3bbc59ea4f73a980e8893a3a',1,'co-vua',true,'Danh sách ban đầu từ Chess-Results.',now()),
  ('cờ vua bảng nữ.pdf','0828d2996a6a8e662ee7eb41a0c41a6074a10ad8d95f91c568066df573f9ee06',1,'co-vua',true,'Danh sách ban đầu từ Chess-Results.',now()),
  ('Schedule_All_Sports_2026-08-27.pdf','0f79e2aadc3c1301a702d58d7c9ae9fbeb3971ac6ad410565f7f97e830b3869c',1,null,false,'Loại khỏi seed thi đấu: bản xuất PTSC cũ ngày 19/04/2026.',now()),
  ('DÔI NỮ 41-50.pdf','9f4b941b7ae7265c1a2d677aecdb1b63c65b2066241e583ac3faf091bde086ae',4,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('DÔI NAM NƯ D30T-22.pdf','da3282ae4abf00cd0965a2f6a46050eabefd002304779f0d7c6385fa466006ea',6,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('ĐÔI NỮ 50T.pdf','ffdcfaaba9163516769e98bd2867ead2173f235e5b247162e642bdd4ce7e195f',1,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('DÔI NAM NỮ 31-40T-31.pdf','0349799934e20e5aa59a6d3b3edff7d9418a0aa954b69963b91221962ed7664f',5,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('DÔI NAM 31-40T 37 (1).pdf','e1eba3889b5321a1373448c35f0b6784a726e5b81cfc920186d6fad426990e4b',7,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('DÔI NỮ 31-40T-18.pdf','1260a4839dc858a91798f1aa81a750b10cf460218739c8e5788dd491ad66c1f0',4,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('DÔI NAM NỮ 41-50T-21.pdf','959d6ed9488807ab207531b2f8ba8bddad763d64f15279a44b322844422eb0ae',5,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('DÔI NAM d30t-32.pdf','55982a93554aedd4cf3d288d1923b29ac9fc054906794fdc5c8ecaa829a91c34',7,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('ĐÔI NAM NỮ 51-10.pdf','d05ddd845c92f7e02ab49770e839221f5718755a21208f779d74e7fdd6810d3c',3,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('DÔI NAM 41-50T-40.pdf','7f276bb7511376435b83951d735bad5c5f8f3e5ef22e6c333f66c97abe4fba10',12,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('DÔI NAM 51T-26.pdf','2949df48b27e1b6b70bae59f92f0b8a21033650c8e7c51168030fdc53e42b145',6,'pickleball',true,'Bảng đấu nguồn.',now()),
  ('B Bàn pn 26 (1).pdf','702bdc80e411a14b4ce7ded0f7103905b90409528b3adcc06cb1a9257cc70081',20,'bong-ban',true,'Lịch và bảng đấu; ô kết quả chưa có dữ liệu.',now()),
  ('ĐKinh pvn 2026.pdf','33984d8e0f8c344a2f72e989437d5f9f87e30988d43f9d05f431b01facda4911',12,'dien-kinh',true,'Lịch và danh sách vận động viên.',now()),
  ('Boi pn 2026.pdf','c8bfddec94a95c677bac105f5907ccfcd1615e4e2bddf33d557c44a14a323d98',8,'boi-loi',true,'Lịch và danh sách vận động viên; KV quyết định năm sự kiện.',now()),
  ('ĐK KEO CO pvn 2026 (1) (1).pdf','f660b49d442e37655387e89fbeacf9cd9e972f96939eb2a5addb317e82f2c754',3,'keo-co',true,'Lịch và bảng đấu; không suy đoán kết quả trống.',now())
on conflict (tenant_id, raw_filename) do update set
  sha256 = excluded.sha256, page_count = excluded.page_count, sport_slug = excluded.sport_slug,
  imported = excluded.imported, notes = excluded.notes, reviewed_at = excluded.reviewed_at, archived_at = null;
