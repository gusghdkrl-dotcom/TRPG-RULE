-- DEV ONLY 11C: Existing player choice always comes before generic
-- training certificate or next mission prompts. Other loop gates unchanged.
create or replace function trpg_hq.hq_full_loop_next(p_team_id uuid)
returns jsonb language plpgsql stable set search_path to 'pg_catalog'
as $hq$
declare
 snapshot jsonb;
 next text;
 seg uuid;
 pf jsonb;
 unapproved int;
 training_pending int;
 formal_pending int;
begin
 snapshot:=trpg_hq.hq_loop_status(p_team_id);
 next:=snapshot->>'next_checkpoint';
 if next='complete_briefing_and_choose_departure' then
   seg:=(snapshot->'field_segment'->>'segment_id')::uuid;
   pf:=trpg_hq.hq_field_preflight(seg);
   next:=case
     when pf->>'formal_briefing_recorded'<>'true'
        then 'world_pc_equipment_and_martin_briefing'
     when pf->>'ready_for_explicit_departure'='true'
        then 'jayden_departure_on_player_choice'
     else 'world_preflight_needs_correction' end;
 elsif next='hq_free_play_or_plan_mission' then
   select count(*) into unapproved
    from trpg_hq.hq_mission_segments s
    join trpg_hq.hq_missions m on m.mission_id=s.mission_id
    where m.team_id=p_team_id and s.status='returned'
      and s.evaluation is not null and s.terminal_status='completed'
      and not exists(select 1 from trpg_hq.hq_reward_grants g
       where g.segment_id=s.segment_id);
   select count(*) into training_pending
    from trpg_hq.hq_mission_segments s
    join trpg_hq.hq_missions m on m.mission_id=s.mission_id
    join trpg_cards.campaign_members cm on cm.campaign_id=m.campaign_id
    join trpg_hq.hq_agents a on a.agent_id=cm.player_id
    where m.team_id=p_team_id and m.mission_scale='major'
      and m.status='completed' and s.status='returned'
      and s.terminal_status='completed' and s.evaluation is not null
      and cm.player_id=any(s.returning_agent_ids)
      and a.training_completed=false;
   select count(*) into formal_pending
    from trpg_hq.hq_missions m
    where m.team_id=p_team_id and m.mission_scale='chronicle'
      and m.status='completed'
      and not exists(select 1 from trpg_hq.hq_chronicle_completions c
       where c.mission_id=m.mission_id);
   if unapproved>0 then next:='martin_reward_eligibility_review';
   elsif formal_pending>0 then next:='martin_chronicle_completion_review';
   elsif training_pending>0 then next:='martin_training_certification';
   end if;
 end if;
 return snapshot||jsonb_build_object(
   'next_checkpoint',next,
   'npc_interaction_is_optional_when_not_related_to_actual_action',true,
   'no_auto_player_speech_or_reward_choice',true,
   'field_to_hq_only_after_verified_terminal',true);
end $hq$;
revoke all on all functions in schema trpg_hq from public,anon,authenticated;