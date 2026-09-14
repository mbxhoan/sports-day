-- PTSC-only gallery link, public sport read model, and placeholder KV fallback.
set app.tenant_slug = 'ptsc2026';

alter table public.sports add column if not exists gallery_drive_url text;

create or replace function public.get_public_sport_gallery(p_sport_slug text)
returns jsonb
language plpgsql
security invoker
stable
set search_path = public, private
as $$
declare
  v_tenant_id uuid := private.current_tenant_id();
begin
  if v_tenant_id is null then raise exception 'Tenant không hợp lệ'; end if;
  return jsonb_build_object('gallery_drive_url', coalesce((select gallery_drive_url from sports where tenant_id = v_tenant_id and slug = p_sport_slug and archived_at is null), ''));
end;
$$;

revoke all on function public.get_public_sport_gallery(text) from public;
grant execute on function public.get_public_sport_gallery(text) to anon, authenticated;

update public.event_settings
set hero_path = case when nullif(trim(hero_path), '') is null or hero_path in ('/kv.png', '/kv.webp') then '/kv-ptsc-placeholder.png' else hero_path end,
    hero_mobile_path = case when nullif(trim(hero_mobile_path), '') is null or hero_mobile_path in ('/kv-mobile.png', '/kv-mobile.webp') then '/kv-ptsc-mobile-placeholder.png' else hero_mobile_path end
where tenant_id = private.current_tenant_id()
  and singleton_key = 'main'
  and archived_at is null;
