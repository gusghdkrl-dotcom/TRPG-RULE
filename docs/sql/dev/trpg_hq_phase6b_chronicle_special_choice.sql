-- DEV ONLY PHASE 6B. Exactly ONE direct special reward per verified
-- chronicle completion medal. Unlike normal drafts this does not draw random
-- offers; it never changes a general chapter reward.
-- Completion + medal have already been awarded by phase 6A.
-- If all card/growth routes exhausted, keep awaiting_choice: alternate
-- compensation is NOT agreed and must not be invented.

create or replace function trpg_hq.chronicle_special_options(
 p_mission_id uuid,p_player_id uuid
) returns jsonb language plpgsql stable
set search_path to 'pg_catalog'
as $hq$
declare
 v_honor trpg_hq.hq_chronicle_honors%rowtype;
 v_cards jsonb;
 v_growth jsonb;
begin
 select * into v_honor from trpg_hq.hq_chronicle_honors
   where mission_id=p_mission_id and player_id=p_player_id;
 if not found then raise exception 'hq_chronicle_special_not_approved'; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
   'card_id',c.card_id,'title',c.title,'rarity',c.rarity,
   'faction',c.faction,'kind',c.kind)
   order by c.ordinal,c.card_id),'[]'::jsonb)
 into v_cards
 from trpg_cards.card_catalog c
 where c.rarity in ('common','rare','epic')
   and not exists(select 1 from trpg_cards.owned_cards oc
     where oc.player_id=p_player_id and oc.card_id=c.card_id);
 select coalesce(jsonb_agg(jsonb_build_object('stat',g.stat,
   'current_level',coalesce(l.level,0)) order by g.idx),'[]'::jsonb)
 into v_growth
 from (values ('STR',1),('CON',2),('SIZ',3),('DEX',4),
              ('APP',5),('INT',6),('POW',7),('EDU',8)) g(stat,idx)
 left join trpg_cards.growth_levels l
   on l.player_id=p_player_id and l.stat=g.stat
 where coalesce(l.level,0)<5;
 return jsonb_build_object(
   'mission_id',p_mission_id,'player_id',p_player_id,
   'medal_key',v_honor.medal_key,'status',v_honor.status,
   'selected',case when v_honor.status='resolved' then
     jsonb_build_object('choice_kind',v_honor.choice_kind,
       'choice_id',v_honor.choice_id,'outcome',v_honor.outcome)
     else null end,
   'eligible_direct_cards',v_cards,'eligible_growth',v_growth,
   'all_choices_exhausted',
     (jsonb_array_length(v_cards)=0 and jsonb_array_length(v_growth)=0)
 );
end $hq$;

create or replace function trpg_hq.resolve_chronicle_special(
 p_mission_id uuid,p_player_id uuid,p_expected_revision bigint,
 p_choice_kind text,p_choice_id text
) returns jsonb language plpgsql
set search_path to 'pg_catalog'
as $hq$
declare
 v_team trpg_hq.hq_teams%rowtype;
 v_completion trpg_hq.hq_chronicle_completions%rowtype;
 v_honor trpg_hq.hq_chronicle_honors%rowtype;
 v_card trpg_cards.card_catalog%rowtype;
 v_owned text;
 v_after smallint;
 v_outcome jsonb;
 v_data jsonb;
begin
 if p_choice_kind not in ('card','growth') or p_choice_id is null
   or char_length(btrim(p_choice_id)) not between 1 and 48 then
   raise exception 'hq_special_invalid_choice';
 end if;
 select * into v_completion from trpg_hq.hq_chronicle_completions
   where mission_id=p_mission_id;
 if not found then raise exception 'hq_chronicle_completion_not_approved';end if;
 select * into v_team from trpg_hq.hq_teams
   where team_id=v_completion.team_id for update;
 select * into v_honor from trpg_hq.hq_chronicle_honors
   where mission_id=p_mission_id and player_id=p_player_id for update;
 if not found then raise exception 'hq_chronicle_player_medal_missing';end if;
 if v_honor.status='resolved' then
   if v_honor.choice_kind is distinct from p_choice_kind
     or v_honor.choice_id is distinct from p_choice_id then
     raise exception 'hq_chronicle_special_already_chosen_other_reward';
   end if;
   return jsonb_build_object('applied',false,'status','resolved',
     'outcome',v_honor.outcome,'current_revision',v_team.revision);
 end if;
 if p_expected_revision is distinct from v_team.revision then
   raise exception 'hq_revision_conflict_expected_%_actual_%',
     p_expected_revision,v_team.revision;
 end if;
 if not exists(select 1 from trpg_hq.hq_agents a
   where a.agent_id=p_player_id and a.chronicle_completed=true
     and a.qualification='full_agent') then
   raise exception 'hq_special_requires_full_agent_completion';
 end if;
 if p_choice_kind='card' then
   select * into v_card from trpg_cards.card_catalog where card_id=p_choice_id;
   if not found or v_card.rarity not in ('common','rare','epic') then
     raise exception 'hq_special_card_unavailable_or_legendary';
   end if;
   if exists(select 1 from trpg_cards.owned_cards
     where player_id=p_player_id and card_id=p_choice_id) then
     raise exception 'hq_special_card_already_owned';
   end if;
   insert into trpg_cards.owned_cards(player_id,card_id,acquisition_event)
     values(p_player_id,p_choice_id,v_honor.medal_key||':special')
     on conflict(player_id,card_id) do nothing returning card_id into v_owned;
   if v_owned is null then raise exception 'hq_special_card_concurrent_acquisition';end if;
   v_outcome:=jsonb_build_object('type','direct_card','card_id',p_choice_id,
     'rarity',v_card.rarity,'acquisition_event',v_honor.medal_key||':special');
 else
   if p_choice_id not in ('STR','CON','SIZ','DEX','APP','INT','POW','EDU') then
     raise exception 'hq_special_unknown_growth_stat';
   end if;
   insert into trpg_cards.growth_levels(player_id,stat,level,changed_at)
      values(p_player_id,p_choice_id,1,now())
   on conflict(player_id,stat) do update
     set level=trpg_cards.growth_levels.level+1,changed_at=now()
     where trpg_cards.growth_levels.level<5
   returning level into v_after;
   if v_after is null then raise exception 'hq_special_growth_already_max_level';end if;
   v_outcome:=jsonb_build_object('type','guaranteed_growth',
     'stat',p_choice_id,'before_level',v_after-1,'after_level',v_after,
     'no_random_roll',true,'retroactive_local_pc_change',false);
 end if;
 update trpg_hq.hq_chronicle_honors set
   status='resolved',choice_kind=p_choice_kind,choice_id=p_choice_id,
   outcome=v_outcome,resolved_at=now()
   where mission_id=p_mission_id and player_id=p_player_id;
 v_data:=jsonb_build_object('mission_id',p_mission_id,
   'player_id',p_player_id,'medal_key',v_honor.medal_key,
   'choice_kind',p_choice_kind,'choice_id',p_choice_id,
   'outcome',v_outcome);
 insert into trpg_hq.hq_events(team_id,event_key,event_kind,hq_minute,
    actor_key,listened_by,audience,summary,event_data,request_sha256)
 values(v_team.team_id,
   'chronicle:special:'||p_mission_id::text||':'||p_player_id::text,
   'chronicle_special_resolved',v_team.hq_elapsed_minutes,
   'npc:dominic',to_jsonb(array[p_player_id::text]),
   to_jsonb(array[p_player_id::text]),
   '연대기 완주 특별 보상 1종이 실제 영구 소유/성장 DB에 지급됨',
   v_data,encode(sha256(convert_to(v_data::text,'UTF8')),'hex'));
 update trpg_hq.hq_teams set revision=revision+1
   where team_id=v_team.team_id;
 return jsonb_build_object('applied',true,'status','resolved',
   'choice_kind',p_choice_kind,'choice_id',p_choice_id,
   'outcome',v_outcome,'current_revision',v_team.revision+1);
end $hq$;

revoke all on all functions in schema trpg_hq from public,anon,authenticated;
alter default privileges in schema trpg_hq revoke execute on functions from public;
