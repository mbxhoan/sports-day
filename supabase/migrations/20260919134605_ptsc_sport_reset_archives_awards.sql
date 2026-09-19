create or replace function public.reset_sport_results_and_awards(p_sport_id uuid, p_confirm boolean default false)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_tenant_id uuid := (select private.current_tenant_id());
  v_result jsonb;
  tournament_ids uuid[];
  entry_ids uuid[];
  participant_ids uuid[];
  award_count integer;
begin
  -- The existing reset owns PTSC/admin validation, fixture locks and atomic result cleanup.
  v_result := public.reset_sport_results(p_sport_id, p_confirm);

  select coalesce(array_agg(tournament.id), '{}'::uuid[])
  into tournament_ids
  from public.tournaments tournament
  where tournament.tenant_id = v_tenant_id
    and tournament.sport_id = p_sport_id;

  select coalesce(array_agg(entry.id), '{}'::uuid[])
  into entry_ids
  from public.entries entry
  where entry.tenant_id = v_tenant_id
    and entry.tournament_id = any(tournament_ids);

  select coalesce(array_agg(member.participant_id), '{}'::uuid[])
  into participant_ids
  from public.entry_members member
  join public.entries entry on entry.id = member.entry_id
  where member.tenant_id = v_tenant_id
    and entry.tournament_id = any(tournament_ids);

  if p_confirm is true then
    update public.awards award
    set archived_at = now()
    where award.tenant_id = v_tenant_id
      and award.archived_at is null
      and (award.sport_id = p_sport_id or award.tournament_id = any(tournament_ids) or award.entry_id = any(entry_ids) or award.participant_id = any(participant_ids));
    get diagnostics award_count = row_count;

    if exists (
      select 1
      from public.awards award
      where award.tenant_id = v_tenant_id
        and award.archived_at is null
        and (award.sport_id = p_sport_id or award.tournament_id = any(tournament_ids) or award.entry_id = any(entry_ids) or award.participant_id = any(participant_ids))
    ) then
      raise exception 'Reset môn chưa lưu trữ hết huy chương';
    end if;
  else
    select count(*) into award_count
    from public.awards award
    where award.tenant_id = v_tenant_id
      and award.archived_at is null
      and (award.sport_id = p_sport_id or award.tournament_id = any(tournament_ids) or award.entry_id = any(entry_ids) or award.participant_id = any(participant_ids));
  end if;

  return jsonb_set(v_result, '{awards}', to_jsonb(award_count), true);
end;
$$;

revoke all on function public.reset_sport_results_and_awards(uuid, boolean) from public, anon;
grant execute on function public.reset_sport_results_and_awards(uuid, boolean) to authenticated;
