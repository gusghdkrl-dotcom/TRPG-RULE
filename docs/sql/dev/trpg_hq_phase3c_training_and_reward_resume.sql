-- DEV ONLY: training-to-chronicle qualification gate and private reward resume view.
-- No automated grade points, new awards, free progression, or manual mission success.

create or replace function trpg_hq.certify_training(
  p_segment_id uuid, p_player_id uuid, p_expected_revision bigint
)
returns jsonb language plpgsql set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_segment trpg_hq.hq_mission_segments%rowtype;
  v_agent trpg_hq.hq_agents%rowtype;
  v_data jsonb;
begin
  select m.* into v_mission from trpg_hq.hq_missions m
    join trpg_hq.hq_mission_segments s on s.mission_id=m.mission_id
    where s.segment_id=p_segment_id;
  if not found then raise exception 'hq_segment_not_found'; end if;
  select * into v_team from trpg_hq.hq_teams
    where team_id=v_mission.team_id for update;
  select * into v_segment from trpg_hq.hq_mission_segments
    where segment_id=p_segment_id for update;
  if v_mission.mission_scale<>'major' or v_mission.status<>'completed'
    or v_segment.status<>'returned'
    or v_segment.terminal_scope<>'CAMPAIGN_TERMINAL'
    or v_segment.terminal_status<>'completed'
    or v_segment.evaluation is null then
    raise exception 'hq_training_not_completed_and_evaluated';
  end if;
  if not (p_player_id=any(v_segment.returning_agent_ids))
    or not exists(select 1 from trpg_cards.campaign_members
      where campaign_id=v_mission.campaign_id and player_id=p_player_id)
    or not exists(select 1 from trpg_hq.hq_team_members
      where team_id=v_mission.team_id and agent_id=p_player_id) then
    raise exception 'hq_training_player_not_confirmed_returnee';
  end if;
  select * into v_agent from trpg_hq.hq_agents
    where agent_id=p_player_id for update;
  if not found then raise exception 'hq_agent_not_found'; end if;
  if v_agent.training_completed then
    return jsonb_build_object('applied',false,'qualified',true,
      'qualification',v_agent.qualification,
      'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',
      p_expected_revision,v_team.revision;
  end if;
  update trpg_hq.hq_agents set training_completed=true,
    qualification=case when qualification='recruit'
      then 'training_qualified' else qualification end
    where agent_id=p_player_id;
  v_data:=jsonb_build_object('segment_id',p_segment_id,
    'player_id',p_player_id,'campaign_id',v_mission.campaign_id,
    'terminal_event_id',v_segment.terminal_event_id,
    'verified_checkpoint_version',v_segment.verified_checkpoint_version,
    'new_qualification',case when v_agent.qualification='recruit'
      then 'training_qualified' else v_agent.qualification end);
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,
    actor_key,listened_by,audience,summary,event_data,request_sha256)
  values(v_team.team_id,
    'qualification:'||p_segment_id::text||':'||p_player_id::text,
    'training_qualified',v_team.hq_elapsed_minutes,'npc:martin',
    to_jsonb(array[p_player_id::text]),to_jsonb(array[p_player_id::text]),
    '대사건 훈련의 실제 완수 및 요원 자격 등록',v_data,
    encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=v_team.team_id;
  return jsonb_build_object('applied',true,'qualified',true,
    'qualification',case when v_agent.qualification='recruit'
      then 'training_qualified' else v_agent.qualification end,
    'current_revision',v_team.revision+1);
end $hq$;

-- Checked by any new chronicle dispatch, including the original prepare_mission.
-- Existing pre-gate synthetic test records remain historical test data.
create or replace function trpg_hq.reject_unqualified_chronicle()
returns trigger language plpgsql
set search_path to 'pg_catalog'
as $hq$
begin
  if new.mission_scale='chronicle'
    and exists(select 1 from trpg_hq.hq_team_members tm
      join trpg_hq.hq_agents a on a.agent_id=tm.agent_id
      where tm.team_id=new.team_id and tm.left_at_minutes is null
        and a.training_completed is not true) then
    raise exception 'hq_chronicle_requires_training_qualified_team';
  end if;
  return new;
end $hq$;
create trigger hq_chronicle_requires_qualified_team
  before insert on trpg_hq.hq_missions
  for each row execute function trpg_hq.reject_unqualified_chronicle();

create or replace function trpg_hq.load_team_rewards(p_team_id uuid)
returns jsonb language sql stable
set search_path to 'pg_catalog'
as $hq$
select coalesce(jsonb_agg(
  jsonb_build_object(
    'segment_id',r.segment_id,'player_id',r.player_id,
    'campaign_id',r.campaign_id,'event_key',r.event_key,
    'source_event_id',r.source_event_id,
    'hq_status',r.status,'approval_reason',r.approval_reason,
    'offers',r.offers,'chosen_slot',r.chosen_slot,
    'outcome',r.outcome,'approved_at',r.approved_at,
    'card_draft_status',d.status,'card_source_event_id',d.source_event_id,
    'card_chosen_slot',d.chosen_slot,'card_outcome',d.outcome,
    'ledger_consistent',
      (case
        when r.status='approved' then d.event_key is null
        when r.status='offered' then d.status='offered'
          and d.offers is not distinct from r.offers
          and d.source_event_id=r.source_event_id
        when r.status='exhausted' then d.status='exhausted'
          and d.offers is not distinct from r.offers
          and d.source_event_id=r.source_event_id
        when r.status='resolved' then d.status='resolved'
          and d.offers is not distinct from r.offers
          and d.source_event_id=r.source_event_id
          and d.chosen_slot=r.chosen_slot and d.outcome is not distinct from r.outcome
        else false
      end))
  order by r.approved_at,r.player_id),'[]'::jsonb)
from trpg_hq.hq_reward_grants r
join trpg_hq.hq_mission_segments s on s.segment_id=r.segment_id
join trpg_hq.hq_missions m on m.mission_id=s.mission_id
left join trpg_cards.drafts d on d.campaign_id=r.campaign_id
  and d.player_id=r.player_id and d.event_key=r.event_key
where m.team_id=p_team_id
$hq$;

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
