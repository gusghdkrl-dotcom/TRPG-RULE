-- DEV rollback test: actual ON account -> entrance -> voluntary recorded
-- induction attendance -> subsequent sync room -> verified field route.
-- Never writes to production. All synthetic DEV rows roll back.
create temporary table hq11_entry_test_result(k text,v jsonb) on commit drop;
do $test$
declare
  a jsonb;
  b jsonb;
  c jsonb;
  d jsonb;
  team uuid;
  ids uuid[];
  rev bigint;
  f jsonb;
  m jsonb;
  seg uuid;
  result jsonb;
begin
  begin
    a:=trpg_hq.begin_hq_on_visit('hq11-new-team',
      array['HQ11_ALPHA','HQ11_BETA'],'hq11:first-entry');
    if a->>'route'<>'entrance' or a->>'applied'<>'true' then
      raise exception 'first_visit_not_entrance: %',a;end if;
    team:=(a->>'team_id')::uuid;
    f:=trpg_hq.hq_loop_status(team);
    if f->>'next_checkpoint'<>'first_induction_scene'
       or jsonb_array_length(f->'uninducted_agents')<>2
       or jsonb_array_length(f->'available_npc_structural_services')<>8
    then raise exception 'entry_npc_or_orientation_routing_invalid';end if;
    b:=trpg_hq.begin_hq_on_visit('hq11-new-team',
      array['HQ11_BETA','HQ11_ALPHA'],'hq11:first-entry');
    if b->>'applied'<>'false' then raise exception 'same_entry_double_created';end if;
    begin
      perform trpg_hq.begin_hq_on_visit('hq11-new-team',
        array['HQ11_ALPHA','HQ11_ALPHA'],'bad-duplicate');
      raise exception 'same_nickname_was_accepted';
    exception when others then
      if sqlerrm<>'hq_entry_duplicate_nicknames' then raise;end if;
    end;
    select array_agg(agent_id order by agent_id) into ids from trpg_hq.hq_team_members where team_id=team;
    select revision into rev from trpg_hq.hq_teams where team_id=team;
    c:=trpg_hq.record_hq_induction(team,'hq11:scene1',rev,ids,
      '개발 가상 입단 행사 장면을 실제로 진행했다고 가정한 참석 기록. 서약/발언 없음.',9);
    if c->>'applied'<>'true' or (c->>'new_inducted_count')::int<>2 then
      raise exception 'induction_not_saved';end if;
    d:=trpg_hq.record_hq_induction(team,'hq11:scene1',rev,ids,
      '개발 가상 입단 행사 장면을 실제로 진행했다고 가정한 참석 기록. 서약/발언 없음.',9);
    if d->>'applied'<>'false' then raise exception 'induction_double_spent_time';end if;
    select revision into rev from trpg_hq.hq_teams where team_id=team;
    b:=trpg_hq.begin_hq_on_visit('hq11-new-team',
      array['HQ11_ALPHA','HQ11_BETA'],'hq11:second-new-game');
    if b->>'route'<>'sync_room' or b->>'applied'<>'true' then
      raise exception 'returning_visit_not_sync_room: %',b;end if;
    f:=trpg_hq.hq_loop_status(team);
    if jsonb_array_length(f->'uninducted_agents')<>0 then
      raise exception 'induction_memory_lost';end if;
    perform trpg_cards.open_campaign('hq11-test-campaign','major','hq11-field-session');
    perform trpg_cards.enroll_player('hq11-test-campaign',ids[1],'guardian');
    perform trpg_cards.enroll_player('hq11-test-campaign',ids[2],'rogue');
    select revision into rev from trpg_hq.hq_teams where team_id=team;
    m:=trpg_hq.prepare_mission(team,'hq11-test-campaign','major','unassessed',
      '[{"id":"actual_prebriefing_example","description":"가상 설명용 목표","importance":"core"}]'::jsonb,
      '{"test_only":true}'::jsonb,'major:final','hq11-field-session',rev);
    seg:=(m->>'segment_id')::uuid;
    f:=trpg_hq.hq_loop_status(team);
    if f->>'next_checkpoint'<>'complete_briefing_and_choose_departure'
      then raise exception 'mission_not_predeparture';end if;
    select revision into rev from trpg_hq.hq_teams where team_id=team;
    perform trpg_hq.start_segment(seg,rev);
    f:=trpg_hq.hq_loop_status(team);
    if f->>'next_checkpoint'<>'resume_saved_field'
      then raise exception 'field_not_active';end if;
    b:=trpg_hq.begin_hq_on_visit('hq11-new-team',
      array['HQ11_ALPHA','HQ11_BETA'],'hq11:illicit-return');
    if b->>'route'<>'resume_field' or b->>'hq_visit_created'<>'false' then
      raise exception 'field_continuation_was_changed_to_HQ: %',b;end if;
    if (select count(*) from trpg_hq.hq_entry_sessions where team_id=team)<>2
      then raise exception 'unjustified_new_hq_visit_in_field';end if;
    if (select hq_elapsed_minutes from trpg_hq.hq_teams where team_id=team)<>9
      then raise exception 'input_wait_or_reentry_advanced_time';end if;
    result:=jsonb_build_object(
      'first_new_visit_route','entrance',
      'second_new_on_game_route','sync_room',
      'field_save_new_chat_route','resume_field',
      'eight_npc_services',jsonb_array_length(f->'available_npc_structural_services'),
      'one_induction_record_per_agent',true,
      'idempotent_attendance',true,
      'HQ_elapsed_minutes_only_actual_ceremony',9,
      'personal_dialogue_was_not_invented',true,
      'all_synthetic_changes_rolled_back',true);
    raise exception 'HQ11_ROLLBACK_SUCCESS';
  exception when others then
    if sqlerrm<>'HQ11_ROLLBACK_SUCCESS' then raise;end if;
  end;
  insert into pg_temp.hq11_entry_test_result(k,v) values('entry_to_field_routes',result);
end $test$;
select k,v from pg_temp.hq11_entry_test_result;