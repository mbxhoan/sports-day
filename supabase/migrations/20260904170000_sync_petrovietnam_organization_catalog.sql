set app.tenant_slug = 'petrovietnam2026';

create temporary table desired_organizations (
  code text primary key,
  name_vi text not null,
  name_en text not null,
  sort_order integer not null
) on commit drop;

insert into desired_organizations values
  ('BMĐH','CĐ Bộ máy Điều hành Tập đoàn Công nghiệp Năng lượng Quốc gia VN','Petrovietnam Executive Board',1),
  ('PVEP','CĐ Tổng công ty Thăm Dò Khai thác Dầu khí','Petrovietnam Exploration Production Corporation',2),
  ('PVPOWER','CĐ Tổng Công ty Điện lực Dầu khí VN','Petrovietnam Power Corporation',3),
  ('PVCOMBANK','CĐ Ngân hàng TMCP Đại chúng Việt Nam','Vietnam Public Joint Stock Commercial Bank',4),
  ('PVCHEM','CĐ TCT Hóa chất và Dịch vụ Dầu khí','Petrovietnam Chemical and Services Corporation',5),
  ('PETROCONs','CĐ TCT Cổ phần Xây lắp Dầu khí Việt Nam','Petrovietnam Construction Joint Stock Corporation',6),
  ('PVI','CĐ Công ty Cổ phần PVI','PVI Corporation',7),
  ('NCKH&ĐT','CĐ Nghiên cứu Khoa học và Đào tạo','Petrovietnam Research and Training',8),
  ('PTSC','CĐ Tổng công ty CP Dịch vụ kỹ thuật Dầu khí','Petrovietnam Technical Services Corporation',9),
  ('PVOIL','CĐ Tổng Công ty Dầu Việt Nam','Vietnam Oil Corporation',10),
  ('PVGAS','CĐ Tổng công ty Khí Việt Nam','Petrovietnam Gas Corporation',11),
  ('PVFCCo','CĐ TCty Phân bón & Hóa chất Dầu khí','Petrovietnam Fertilizer and Chemicals Corporation',12),
  ('PETROSETCO','CĐ TCT CP Dịch vụ Tổng hợp DKVN','Petrovietnam General Services Corporation',13),
  ('PVD','CĐ TCT CP Khoan & Dịch vụ Khoan DK','Petrovietnam Drilling and Well Services Corporation',14),
  ('PVTRANS','CĐ TCT CP Vận Tải Dầu khí','Petrovietnam Transportation Corporation',15),
  ('VSP','CĐ Liên doanh Việt – Nga VIETSOVPETRO','Vietsovpetro Joint Venture',16),
  ('PVMR','CĐ CT Bảo dưỡng-sửa chữa công trình Dầu khí','Petrovietnam Maintenance and Repair Corporation',17),
  ('PVCFC','CĐ Tổng Công ty Phân bón Dầu khí Cà Mau','Petrovietnam Ca Mau Fertilizer Corporation',18),
  ('BĐPOC','CĐ Công ty Điều hành Dầu khí Biển Đông','Bien Dong Petroleum Operating Company',19),
  ('SWPOC','CĐ Công ty Điều hành Đường ống Tây Nam','Southwest Pipeline Operating Company',20),
  ('PQPOC','CĐ Công ty Điều hành Dầu khí Phú Quốc','Phu Quoc Petroleum Operating Company',21),
  ('PVPMP','CĐ Ban QLDA chuyên ngành Điện','Power Projects Management Board',22),
  ('LP1PP','CĐ Ban QLDA Điện lực Dầu khí Long Phú 1','Long Phu 1 Power Project Management Board',23),
  ('PVE','CĐ TCT Tư vấn Thiết kế Dầu khí','Petrovietnam Design and Consulting Joint Stock Corporation',24);

create temporary table organization_aliases (
  alias text primary key,
  canonical text not null references desired_organizations(code)
) on commit drop;

insert into organization_aliases values
  ('PV DRILLING','PVD'), ('PV Drilling','PVD'), ('PV GAS','PVGAS'), ('PVPMB','PVPMP'),
  ('PVFCCO','PVFCCo'), ('PCFCCo','PVFCCo'), ('PCFCCCo','PVFCCo'), ('NCKHĐT','NCKH&ĐT'),
  ('NCKH','NCKH&ĐT'), ('Đội 2 - NCKHĐT','NCKH&ĐT'), ('PETOCONs','PETROCONs'),
  ('PTROCONs','PETROCONs'), ('PETRCONs','PETROCONs'), ('PVCCHEM','PVCHEM'),
  ('PVChem','PVCHEM'), ('PV CHEM','PVCHEM'), ('PV POWER','PVPOWER'), ('POWER','PVPOWER'),
  ('PVG','PVGAS'), ('PVFC','PVCFC'), ('PVMB','PVPMP'), ('PVMP','PVPMP'),
  ('MNĐH PETRO','BMĐH'), ('BMĐH PETROVIETNAM','BMĐH'), ('BỘ MÁY QL&ĐH PETROVN','BMĐH'),
  ('PVTANS','PVTRANS'), ('PVTRAN','PVTRANS'), ('PVTRAS','PVTRANS'), ('PCTRANS','PVTRANS'),
  ('PCOIL','PVOIL'), ('PVI HOLDINGS','PVI'), ('PET','PETROSETCO'), ('Vietsovpetro','VSP'),
  ('PVCom','PVCOMBANK'), ('PVcomBank','PVCOMBANK'), ('PVCombank','PVCOMBANK');

insert into public.organizations (tenant_id, code, name_vi, name_en, sort_order)
select private.seed_tenant_id(), code, name_vi, name_en, sort_order
from desired_organizations
on conflict (tenant_id, code) do update set
  name_vi = excluded.name_vi,
  name_en = excluded.name_en,
  sort_order = excluded.sort_order,
  archived_at = null;

with grouped as (
  select coalesce(aliases.canonical, source.code) as code,
    sum(coalesce(source.gold_medals, 0))::integer as gold_medals,
    sum(coalesce(source.silver_medals, 0))::integer as silver_medals,
    sum(coalesce(source.bronze_medals, 0))::integer as bronze_medals,
    min(source.leaderboard_rank) as leaderboard_rank
  from public.organizations source
  left join organization_aliases aliases on aliases.alias = source.code
  where source.tenant_id = private.seed_tenant_id()
  group by coalesce(aliases.canonical, source.code)
)
update public.organizations target
set gold_medals = grouped.gold_medals,
  silver_medals = grouped.silver_medals,
  bronze_medals = grouped.bronze_medals,
  leaderboard_rank = grouped.leaderboard_rank
from grouped
where target.tenant_id = private.seed_tenant_id()
  and target.code = grouped.code;

-- Do not reassign participants: production duplicate-identity protection can
-- reject a link change when live rows share the same normalized full name.
-- Keeping these links intact avoids changing or merging live participant data.

with links as (
  select source.id, target.id as target_id
  from public.organizations source
  join organization_aliases aliases on aliases.alias = source.code
  join public.organizations target on target.tenant_id = source.tenant_id and target.code = aliases.canonical
  where source.tenant_id = private.seed_tenant_id()
)
update public.entries item
set organization_id = links.target_id
from links
where item.tenant_id = private.seed_tenant_id() and item.organization_id = links.id;

with links as (
  select source.id, target.id as target_id
  from public.organizations source
  join organization_aliases aliases on aliases.alias = source.code
  join public.organizations target on target.tenant_id = source.tenant_id and target.code = aliases.canonical
  where source.tenant_id = private.seed_tenant_id()
)
update public.awards item
set organization_id = links.target_id
from links
where item.tenant_id = private.seed_tenant_id() and item.organization_id = links.id;

update public.organizations organization
set archived_at = now()
where organization.tenant_id = private.seed_tenant_id()
  and not exists (select 1 from desired_organizations desired where desired.code = organization.code);
