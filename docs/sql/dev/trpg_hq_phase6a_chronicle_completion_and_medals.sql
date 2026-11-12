-- DEV ONLY PHASE 6A: verified whole-chronicle completion, first formal agent
-- certification, and unique permanent medal independent of chapter drafts.
-- Source of truth: latest verified field checkpoint + actual returned/evaluated HQ
-- segments + original card-campaign enrollment. No automatic upper rank points.

create table trpg_hq.hq_chronicle_completions (
  mission_id uuid primary key references trpg_hq.hq_missions(mission_id) on delete restrict,
  team_id uuid not null references trpg_hq.hq_teams(team_id) on delete restrict,
  campaign_id text not null unique references trpg_cards.campaigns(campaign_id) on delete restrict,
  final_segment_id uuid not null unique references trpg_hq.hq_mission_segments(segment_id) on delete restrict,
  final_terminal_event_id text not null,
  checkpoint_version bigint not null check(checkpoint_version>=1),
  checkpoint_sha256 text not null check(checkpoint_sha256 ~ '^[0-9a-f]{64}$'),
  completed_players uuid[] not null check(cardinality(completed_players) between 1 and 3),
  martin_assessment text not null check(char_length(martin_assessment) between 1 and 4000),
  completion_event_key text not null unique,
  approved_at timestamptz not null default now()
);

create table trpg_hq.hq_agent_full_certifications (
  player_id uuid primary key references trpg_hq.hq_agents(agent_id) on delete restrict,
  first_mission_id uuid not null references trpg_hq.hq_missions(mission_id) on delete restrict,
  certification_event_key text not null unique,
  granted_at timestamptz not null default now()
);

create table trpg_hq.hq_chronicle_honors (
  mission_id uuid not null references trpg_hq.hq_chronicle_completions(mission_id) on delete restrict,
  player_id uuid not null references trpg_hq.hq_agents(agent_id) on delete restrict,
  medal_key text not null unique,
  status text not null default 'awaiting_choice'
    check(status in ('awaiting_choice','resolved')),
  choice_kind text check(choice_kind in ('card','growth')),
  choice_id text,
  outcome jsonb,
  granted_at timestamptz not null default now(),
  resolved_at timestamptz,
  primary key(mission_id,player_id),
  check(
    (status='awaiting_choice' and choice_kind is null and choice_id is null
      and outcome is null and resolved_at is null)
    or
    (status='resolved' and choice_kind is not null and choice_id is not null
      and jsonb_typeof(outcome)='object' and resolved_at is not null)
  )
);

create index hq_chronicle_honors_by_player
  on trpg_hq.hq_chronicle_honors(player_id,granted_at desc);

alter table trpg_hq.hq_chronicle_completions enable row level security;
alter table trpg_hq.hq_agent_full_certifications enable row level security;
alter table trpg_hq.hq_chronicle_honors enable row level security;
revoke all on trpg_hq.hq_chronicle_completions,
 trpg_hq.hq_agent_full_certifications,trpg_hq.hq_chronicle_honors
 from public,anon,authenticated;

create or replace function trpg_hq.approve_chronicle_completion(
 p_final_segment_id uuid, p_expected_revision bigint,p_martin_assessment text
) returns jsonb language plpgsql
set search_path to 'pg_catalog'
as $hq$
declare
 v_team trpg_hq.hq_teams%rowtype;
 v_mission trpg_hq.hq_missions%rowtype;
 v_final trpg_hq.hq_mission_segments%rowtype;
 v_previous trpg_hq.hq_chronicle_completions%rowtype;
 v_checkpoint public.gm_checkpoint_history%rowtype;
 v_doc jsonb;
 v_enrolled uuid[];
 v_player uuid;
 v_event_key text;
 v_data jsonb;
 v_certified_count integer:=0;
begin
 if p_martin_assessment is null
   or char_length(btrim(p_martin_assessment)) not between 1 and 4000 then
   raise exception 'hq_chronicle_martin_assessment_required';
 end if;
 select m.* into v_mission
   from trpg_hq.hq_missions m
   join trpg_hq.hq_mission_segments s on s.mission_id=m.mission_id
   where s.segment_id=p_final_segment_id;
 if not found then raise exception 'hq_chronicle_segment_not_found';end if;
 select * into v_team from trpg_hq.hq_teams
   where team_id=v_mission.team_id for update;
 select * into v_final from trpg_hq.hq_mission_segments
   where segment_id=p_final_segment_id for update;
 select * into v_previous from trpg_hq.hq_chronicle_completions
   where mission_id=v_mission.mission_id;
 if found then
   if v_previous.final_segment_id is distinct from p_final_segment_id
     or v_previous.martin_assessment is distinct from p_martin_assessment then
     raise exception 'hq_chronicle_completion_replay_conflict';
   end if;
   return jsonb_build_object('applied',false,'mission_id',v_mission.mission_id,
     'medals',cardinality(v_previous.completed_players),
     'completion_event_key',v_previous.completion_event_key,
     'current_revision',v_team.revision);
 end if;
 if p_expected_revision is distinct from v_team.revision then
   raise exception 'hq_revision_conflict_expected_%_actual_%',
     p_expected_revision,v_team.revision;
 end if;
 if v_mission.mission_scale<>'chronicle'
   or v_mission.status<>'completed'
   or v_final.status<>'returned'
   or v_final.terminal_status<>'completed'
   or v_final.terminal_scope<>'CHRONICLE_TERMINAL'
   or v_final.terminal_verified_at is null
   or v_final.returned_at is null
   or v_final.evaluation is null
   or v_final.terminal_event_id is null then
   raise exception 'hq_chronicle_not_verified_completed_and_evaluated';
 end if;
 if exists(select 1 from trpg_hq.hq_mission_segments s
  where s.mission_id=v_mission.mission_id
    and (s.status<>'returned'
      or s.terminal_status<>'completed' or s.evaluation is null
      or s.terminal_verified_at is null
      or s.returned_at is null
      or s.verified_checkpoint_version is null
      or (s.segment_id<>p_final_segment_id and s.terminal_scope<>'CHAPTER_TERMINAL')
      or (s.segment_id=p_final_segment_id and s.terminal_scope<>'CHRONICLE_TERMINAL')
      or s.session_id is distinct from v_final.session_id
      or (s.segment_id<>p_final_segment_id
          and s.verified_checkpoint_version>=v_final.verified_checkpoint_version))) then
   raise exception 'hq_chronicle_unfinished_or_inconsistent_chapters';
 end if;
 if exists(
  select 1 from trpg_hq.hq_mission_segments s
   left join public.gm_checkpoint_history c
     on c.session_id=s.session_id
       and c.version=s.verified_checkpoint_version
       and c.status='verified'
   where s.mission_id=v_mission.mission_id
     and (c.state_sha256 is distinct from s.verified_state_sha256
       or c.state_sha256 is null
       or encode(sha256(convert_to(c.state_json,'UTF8')),'hex')
         is distinct from c.state_sha256
       or c.state_json::jsonb->'runtime'->'ending_state'
         is distinct from s.terminal_result)) then
   raise exception 'hq_chronicle_chapter_checkpoint_mismatch';
 end if;
 select * into v_checkpoint from public.gm_checkpoint_history
   where session_id=v_final.session_id
     and version=v_final.verified_checkpoint_version
     and state_sha256=v_final.verified_state_sha256
     and status='verified';
 if not found
   or exists(select 1 from public.gm_checkpoint_history
     where session_id=v_final.session_id and status='verified'
       and version>v_checkpoint.version) then
   raise exception 'hq_chronicle_latest_verified_checkpoint_required';
 end if;
 v_doc:=v_checkpoint.state_json::jsonb;
 if v_doc->>'campaign_id' is distinct from v_mission.campaign_id
   or v_doc->'runtime'->'hq'->>'mission_id'
      is distinct from v_mission.mission_id::text
   or v_doc->'runtime'->'ending_state' is distinct from v_final.terminal_result
   or v_doc->'runtime'->'ending_state'->>'status'<>'completed'
   or v_doc->'runtime'->'ending_state'->>'scope'<>'CHRONICLE_TERMINAL'
   or jsonb_typeof(v_doc->'pcs') is distinct from 'object' then
   raise exception 'hq_chronicle_final_checkpoint_identity_mismatch';
 end if;
 select array_agg(cm.player_id order by cm.player_id) into v_enrolled
   from trpg_cards.campaign_members cm
   where cm.campaign_id=v_mission.campaign_id;
 if cardinality(v_enrolled) not between 1 and 3
   or v_enrolled is distinct from (
     select array_agg(x order by x) from unnest(v_final.returning_agent_ids) u(x))
   or cardinality(v_enrolled) is distinct from (
     select count(*) from jsonb_each(v_doc->'pcs'))
   or exists(
     select 1 from unnest(v_enrolled) u(id)
     where not exists(
       select 1 from trpg_hq.hq_team_members tm
       where tm.team_id=v_mission.team_id and tm.agent_id=u.id)
       or not exists(
         select 1 from trpg_hq.hq_agents a
         where a.agent_id=u.id and a.training_completed=true
           and a.qualification in ('training_qualified','full_agent'))
       or (select count(*) from jsonb_each(v_doc->'pcs') p(pc_key,val)
            where p.val->>'player_id'=u.id::text
              and p.val->'alive'='true'::jsonb)<>1
   )
   or exists(
     select 1 from trpg_hq.hq_mission_segments s
       where s.mission_id=v_mission.mission_id
         and s.returning_agent_ids is distinct from v_enrolled) then
   raise exception 'hq_chronicle_not_all_qualified_agents_survived_and_returned';
 end if;
 -- Per-campaign, independently verified event. No general draft substituted.
 v_event_key:='chronicle:completion:'||v_mission.mission_id::text;
 insert into trpg_hq.hq_chronicle_completions(
  mission_id,team_id,campaign_id,final_segment_id,final_terminal_event_id,
  checkpoint_version,checkpoint_sha256,completed_players,
  martin_assessment,completion_event_key
 ) values(v_mission.mission_id,v_team.team_id,v_mission.campaign_id,
  p_final_segment_id,v_final.terminal_event_id,v_final.verified_checkpoint_version,
  v_final.verified_state_sha256,v_enrolled,p_martin_assessment,v_event_key);
 foreach v_player in array v_enrolled loop
   insert into trpg_hq.hq_chronicle_honors(
     mission_id,player_id,medal_key
   ) values(v_mission.mission_id,v_player,
     'medal:'||v_mission.mission_id::text||':'||v_player::text);
   -- Only FIRST successful whole-chronicle creates a formal certificate.
   insert into trpg_hq.hq_agent_full_certifications(
     player_id,first_mission_id,certification_event_key
   ) values(v_player,v_mission.mission_id,
     'full-agent:'||v_player::text)
   on conflict(player_id) do nothing;
   if found then v_certified_count:=v_certified_count+1;end if;
   update trpg_hq.hq_agents set qualification='full_agent',
      training_completed=true,chronicle_completed=true
      where agent_id=v_player;
 end loop;
 v_data:=jsonb_build_object(
    'mission_id',v_mission.mission_id,'final_segment_id',p_final_segment_id,
    'campaign_id',v_mission.campaign_id,
    'final_terminal_event_id',v_final.terminal_event_id,
    'checkpoint_version',v_final.verified_checkpoint_version,
    'medal_awarded_player_ids',to_jsonb(v_enrolled),
    'martin_assessment',p_martin_assessment,
    'new_full_certifications',v_certified_count,
    'special_choice','not_yet_selected');
 insert into trpg_hq.hq_events(team_id,event_key,event_kind,
   hq_minute,actor_key,listened_by,audience,summary,event_data,request_sha256)
 values(v_team.team_id,v_event_key,'chronicle_completion_certified',
   v_team.hq_elapsed_minutes,'npc:martin',
   to_jsonb(v_enrolled),to_jsonb(v_enrolled),
   '실제 연대기 전체 완주에 따른 영구 훈장 및 정식 요원 인증',
   v_data,encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
 update trpg_hq.hq_teams set revision=revision+1
   where team_id=v_team.team_id;
 return jsonb_build_object(
   'applied',true,'mission_id',v_mission.mission_id,
   'completion_event_key',v_event_key,'medals',cardinality(v_enrolled),
   'new_full_certifications',v_certified_count,
   'special_choices_pending',cardinality(v_enrolled),
   'current_revision',v_team.revision+1);
end $hq$;

-- Return private trusted-keeper summary, never raw NPC/CANON state to UI.
create or replace function trpg_hq.load_chronicle_honors(p_team_id uuid)
returns jsonb language plpgsql stable set search_path to 'pg_catalog'
as $hq$
begin
 return (select coalesce(jsonb_agg(
   jsonb_build_object(
     'mission_id',c.mission_id,'campaign_id',c.campaign_id,
     'final_segment_id',c.final_segment_id,
     'completion_event_key',c.completion_event_key,
     'player_id',h.player_id,'medal_key',h.medal_key,
     'status',h.status,'choice_kind',h.choice_kind,'choice_id',h.choice_id,
     'outcome',h.outcome,
     'current_card_owned',case when h.choice_kind='card' then exists(
       select 1 from trpg_cards.owned_cards oc
       where oc.player_id=h.player_id and oc.card_id=h.choice_id) else null end,
     'current_growth_level',case when h.choice_kind='growth' then coalesce((
       select level from trpg_cards.growth_levels g
       where g.player_id=h.player_id and g.stat=h.choice_id),0) else null end,
     'ledger_consistent',case
       when h.status='awaiting_choice' then true
       when h.choice_kind='card' then exists(
          select 1 from trpg_cards.owned_cards oc
          where oc.player_id=h.player_id and oc.card_id=h.choice_id
            and oc.acquisition_event=h.medal_key||':special')
       when h.choice_kind='growth' then
         coalesce((select level from trpg_cards.growth_levels g
           where g.player_id=h.player_id and g.stat=h.choice_id),0)
           >=coalesce((h.outcome->>'after_level')::integer,6)
       else false end
   ) order by c.approved_at,h.player_id),'[]'::jsonb)
   from trpg_hq.hq_chronicle_completions c
   join trpg_hq.hq_chronicle_honors h on h.mission_id=c.mission_id
   where c.team_id=p_team_id);
end $hq$;

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
alter default privileges in schema trpg_hq revoke execute on functions from public;
