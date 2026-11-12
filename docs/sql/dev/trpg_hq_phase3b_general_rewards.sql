-- DEV ONLY: official Martin approval -> Dominic card draft -> actual settlement.
-- No new cards, probabilities, ranks, or special chronicle completion rewards.
-- Only for verified/returned HQ segment with Martin's completed qualitative evaluation.
-- Expects external keeper to draw offers with Python SystemRandom and original 09-cards weights.

create table trpg_hq.hq_reward_grants (
  segment_id uuid not null references trpg_hq.hq_mission_segments(segment_id) on delete restrict,
  player_id uuid not null references trpg_hq.hq_agents(agent_id) on delete restrict,
  campaign_id text not null,
  event_key text not null check (char_length(event_key) between 1 and 120),
  source_event_id text not null check (char_length(source_event_id) between 1 and 255),
  status text not null default 'approved'
    check (status in ('approved','offered','resolved','exhausted')),
  approval_reason text not null check (char_length(approval_reason) between 1 and 3000),
  offers jsonb check (offers is null or jsonb_typeof(offers)='object'),
  chosen_slot smallint check (chosen_slot between 1 and 4),
  outcome jsonb,
  approved_at timestamptz not null default now(),
  offered_at timestamptz,
  resolved_at timestamptz,
  primary key(segment_id,player_id),
  unique(campaign_id,event_key,player_id),
  foreign key (campaign_id,player_id)
    references trpg_cards.campaign_members(campaign_id,player_id) on delete restrict,
  constraint hq_reward_issued_shape check
    ((status='approved' and offers is null and chosen_slot is null and outcome is null)
      or (status='offered' and offers is not null and chosen_slot is null and outcome is null)
      or (status='exhausted' and offers is not null and chosen_slot is null and outcome is not null)
      or (status='resolved' and offers is not null and chosen_slot is not null and outcome is not null))
);
create index hq_reward_lookup_by_campaign
 on trpg_hq.hq_reward_grants(campaign_id,player_id,event_key);
alter table trpg_hq.hq_reward_grants enable row level security;
revoke all on table trpg_hq.hq_reward_grants from public,anon,authenticated;

create or replace function trpg_hq.approve_general_reward(
  p_segment_id uuid, p_player_id uuid,
  p_expected_revision bigint, p_approval_reason text
)
returns jsonb language plpgsql
set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_segment trpg_hq.hq_mission_segments%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_grant trpg_hq.hq_reward_grants%rowtype;
  v_key text;
  v_data jsonb;
begin
  if p_approval_reason is null or char_length(btrim(p_approval_reason)) not between 1 and 3000 then
    raise exception 'hq_reward_approval_reason_required';
  end if;
  select m.* into v_mission from trpg_hq.hq_missions m
    join trpg_hq.hq_mission_segments s on s.mission_id=m.mission_id
    where s.segment_id=p_segment_id;
  if not found then raise exception 'hq_segment_not_found'; end if;
  select * into v_team from trpg_hq.hq_teams where team_id=v_mission.team_id for update;
  select * into v_segment from trpg_hq.hq_mission_segments
    where segment_id=p_segment_id for update;
  if v_segment.status<>'returned' or v_segment.evaluation is null
    or v_segment.terminal_verified_at is null
    or v_segment.terminal_event_id is null then
    raise exception 'hq_reward_requires_return_and_martin_evaluation';
  end if;
  if not exists(select 1 from trpg_cards.campaign_members cm
     join trpg_hq.hq_team_members tm on tm.agent_id=cm.player_id
     where cm.campaign_id=v_mission.campaign_id and cm.player_id=p_player_id
       and tm.team_id=v_mission.team_id) then
    raise exception 'hq_reward_player_not_enrolled_in_dispatched_team';
  end if;
  -- Payout eligibility belongs to the permanent player UUID, not surviving local PC.
  v_key:=case when v_mission.mission_scale='major' then 'final'
    else v_segment.segment_key end;
  if v_mission.mission_scale='chronicle'
    and (v_key not like 'chapter:%' or char_length(v_key)<=8) then
    raise exception 'hq_chronicle_reward_segment_key_invalid';
  end if;
  if char_length(v_key)>120 then raise exception 'hq_reward_event_key_too_long'; end if;

  select * into v_grant from trpg_hq.hq_reward_grants
     where segment_id=p_segment_id and player_id=p_player_id for update;
  if found then
    if v_grant.approval_reason is distinct from p_approval_reason
      or v_grant.campaign_id is distinct from v_mission.campaign_id
      or v_grant.event_key is distinct from v_key
      or v_grant.source_event_id is distinct from v_segment.terminal_event_id then
      raise exception 'hq_reward_approval_replay_conflict';
    end if;
    return jsonb_build_object('applied',false,'status',v_grant.status,
      'event_key',v_grant.event_key,'player_id',p_player_id,
      'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;

  insert into trpg_hq.hq_reward_grants(segment_id,player_id,campaign_id,
    event_key,source_event_id,approval_reason)
  values(p_segment_id,p_player_id,v_mission.campaign_id,v_key,
    v_segment.terminal_event_id,p_approval_reason);
  v_data:=jsonb_build_object('segment_id',p_segment_id,'player_id',p_player_id,
    'campaign_id',v_mission.campaign_id,'event_key',v_key,
    'source_event_id',v_segment.terminal_event_id,
    'evaluation_grade',v_segment.evaluation->>'grade',
    'approval_reason',p_approval_reason);
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,
    actor_key,listened_by,audience,summary,event_data,request_sha256)
  values(v_team.team_id,'reward:'||p_segment_id::text||':'||p_player_id::text||':approved',
    'reward_approved',v_team.hq_elapsed_minutes,'npc:martin',
    to_jsonb(array[p_player_id::text]),to_jsonb(array[p_player_id::text]),
    '마틴의 공식 일반 보상 승인',v_data,
    encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=v_team.team_id;
  return jsonb_build_object('applied',true,'status','approved',
    'event_key',v_key,'player_id',p_player_id,'current_revision',v_team.revision+1);
end $hq$;

create or replace function trpg_hq.offer_general_reward(
  p_segment_id uuid, p_player_id uuid,
  p_expected_revision bigint, p_offers jsonb
)
returns jsonb language plpgsql
set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_grant trpg_hq.hq_reward_grants%rowtype;
  v_draft trpg_cards.drafts%rowtype;
  v_issue jsonb;
  v_data jsonb;
begin
  select m.* into v_mission from trpg_hq.hq_missions m
    join trpg_hq.hq_mission_segments s on s.mission_id=m.mission_id
    where s.segment_id=p_segment_id;
  if not found then raise exception 'hq_segment_not_found'; end if;
  select * into v_team from trpg_hq.hq_teams where team_id=v_mission.team_id for update;
  select * into v_grant from trpg_hq.hq_reward_grants
    where segment_id=p_segment_id and player_id=p_player_id for update;
  if not found then raise exception 'hq_reward_not_approved'; end if;
  if v_grant.status<>'approved' then
    if v_grant.offers is distinct from p_offers then
      raise exception 'hq_reward_offer_already_fixed';
    end if;
    return jsonb_build_object('applied',false,'status',v_grant.status,
      'offers',v_grant.offers,'outcome',v_grant.outcome,
      'current_revision',v_team.revision);
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;

  -- Actual card catalog, availability, exhaustion and global open-draft guard
  -- remain enforced by the original card function in the same DB transaction.
  v_issue:=trpg_cards.issue_draft(v_grant.campaign_id,p_player_id,
    v_grant.event_key,v_grant.source_event_id,p_offers);
  select * into v_draft from trpg_cards.drafts
    where campaign_id=v_grant.campaign_id and player_id=p_player_id
      and event_key=v_grant.event_key for update;
  if not found or v_draft.source_event_id is distinct from v_grant.source_event_id
    or v_draft.offers is distinct from p_offers
    or v_draft.status not in ('offered','exhausted') then
    raise exception 'hq_card_draft_source_or_offer_conflict';
  end if;
  update trpg_hq.hq_reward_grants set status=v_draft.status,
     offers=v_draft.offers,outcome=v_draft.outcome,
     offered_at=now() where segment_id=p_segment_id and player_id=p_player_id;
  v_data:=jsonb_build_object('segment_id',p_segment_id,'player_id',p_player_id,
    'campaign_id',v_grant.campaign_id,'event_key',v_grant.event_key,
    'source_event_id',v_grant.source_event_id,'offers',v_draft.offers,
    'status',v_draft.status);
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,
    actor_key,listened_by,audience,summary,event_data,request_sha256)
  values(v_team.team_id,'reward:'||p_segment_id::text||':'||p_player_id::text||':offered',
    'reward_offered',v_team.hq_elapsed_minutes,'npc:dominic',
    to_jsonb(array[p_player_id::text]),to_jsonb(array[p_player_id::text]),
    '도미닉의 실제 카드·성장 드래프트 제시',v_data,
    encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=v_team.team_id;
  return jsonb_build_object('applied',true,'status',v_draft.status,
    'offers',v_draft.offers,'outcome',v_draft.outcome,
    'current_revision',v_team.revision+1);
end $hq$;

create or replace function trpg_hq.resolve_general_reward(
  p_segment_id uuid, p_player_id uuid,
  p_expected_revision bigint, p_choice smallint,
  p_python_roll integer default null
)
returns jsonb language plpgsql
set search_path to 'pg_catalog'
as $hq$
declare
  v_team trpg_hq.hq_teams%rowtype;
  v_mission trpg_hq.hq_missions%rowtype;
  v_grant trpg_hq.hq_reward_grants%rowtype;
  v_draft trpg_cards.drafts%rowtype;
  v_outcome jsonb;
  v_data jsonb;
begin
  select m.* into v_mission from trpg_hq.hq_missions m
    join trpg_hq.hq_mission_segments s on s.mission_id=m.mission_id
    where s.segment_id=p_segment_id;
  if not found then raise exception 'hq_segment_not_found'; end if;
  select * into v_team from trpg_hq.hq_teams where team_id=v_mission.team_id for update;
  select * into v_grant from trpg_hq.hq_reward_grants
    where segment_id=p_segment_id and player_id=p_player_id for update;
  if not found then raise exception 'hq_reward_not_approved'; end if;
  if v_grant.status='resolved' then
    if v_grant.chosen_slot is distinct from p_choice then
      raise exception 'hq_reward_already_resolved_with_other_choice';
    end if;
    return jsonb_build_object('applied',false,'status','resolved',
      'outcome',v_grant.outcome,'current_revision',v_team.revision);
  end if;
  if v_grant.status<>'offered' then
    raise exception 'hq_reward_not_offered_or_exhausted';
  end if;
  if p_expected_revision is distinct from v_team.revision then
    raise exception 'hq_revision_conflict_expected_%_actual_%',p_expected_revision,v_team.revision;
  end if;
  select * into v_draft from trpg_cards.drafts
    where campaign_id=v_grant.campaign_id and player_id=p_player_id
      and event_key=v_grant.event_key for update;
  if not found or v_draft.source_event_id is distinct from v_grant.source_event_id
    or v_draft.offers is distinct from v_grant.offers
    or v_draft.status not in ('offered','resolved') then
    raise exception 'hq_draft_state_mismatch';
  end if;
  v_outcome:=trpg_cards.resolve_draft(v_grant.campaign_id,
    p_player_id,v_grant.event_key,p_choice,p_python_roll);
  select * into v_draft from trpg_cards.drafts
    where campaign_id=v_grant.campaign_id and player_id=p_player_id
      and event_key=v_grant.event_key;
  if v_draft.status<>'resolved' or v_draft.chosen_slot is distinct from p_choice
    or v_draft.outcome is distinct from v_outcome then
    raise exception 'hq_card_reward_settlement_mismatch';
  end if;
  update trpg_hq.hq_reward_grants set status='resolved',
    chosen_slot=p_choice,outcome=v_outcome,resolved_at=now()
    where segment_id=p_segment_id and player_id=p_player_id;
  v_data:=jsonb_build_object('segment_id',p_segment_id,
    'player_id',p_player_id,'campaign_id',v_grant.campaign_id,
    'event_key',v_grant.event_key,'choice',p_choice,
    'outcome',v_outcome);
  insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,
    actor_key,listened_by,audience,summary,event_data,request_sha256)
  values(v_team.team_id,'reward:'||p_segment_id::text||':'||p_player_id::text||':resolved',
    'reward_resolved',v_team.hq_elapsed_minutes,'npc:dominic',
    to_jsonb(array[p_player_id::text]),to_jsonb(array[p_player_id::text]),
    '도미닉의 영구 보상 지급 결과 검증',v_data,
    encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
  update trpg_hq.hq_teams set revision=revision+1 where team_id=v_team.team_id;
  return jsonb_build_object('applied',true,'status','resolved',
    'outcome',v_outcome,'current_revision',v_team.revision+1);
end $hq$;

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
alter default privileges in schema trpg_hq revoke execute on functions from public;
