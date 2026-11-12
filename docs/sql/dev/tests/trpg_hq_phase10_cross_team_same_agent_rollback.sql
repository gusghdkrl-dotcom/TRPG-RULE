-- PHASE 10 DEV ONLY: same permanent agent UUID on two HQ teams/campaigns.
-- Both completed missions earn distinct honors, but global card/growth
-- inventories remain per UUID. Dual ACTIVE membership is forbidden by the
-- existing unique index; this validates sequential membership change. No same-card duplication; growth max uses
-- canonical trpg_cards row. All created fixtures & awards roll back.
create temporary table hq10_cross_team_reports(
 scenario text not null,result jsonb not null
) on commit drop;

do $t$
declare
  r record;
  agent constant uuid:='e0c56a38-d1c6-4814-9468-2b54c3ca59e8'::uuid;
  teams uuid[];
  missions uuid[];
  camps text[];
  seg uuid;
  teamid uuid;
  missionid uuid;
  campaign text;
  sess text;
  canon_sha text;
  chap int;
  t int;
  rev bigint;
  first_cert uuid;
  initial_medals int;
  initial_cards int;
  initial_growth int;
  state jsonb;
  json_state text;
  pcs jsonb;
  cp_sha text;
  parent_sha text;
  res jsonb;
  approval jsonb;
  report jsonb;
  special_card text;
begin
  for r in select * from (values ('card_dedup'),('growth_serial')) d(scenario)
  loop
    report:=null;
    begin
      teams:='{}'::uuid[];
      missions:='{}'::uuid[];
      camps:='{}'::text[];
      select first_mission_id into first_cert
        from trpg_hq.hq_agent_full_certifications where player_id=agent;
      select count(*) into initial_medals
        from trpg_hq.hq_chronicle_honors where player_id=agent;
      select count(*) into initial_cards
        from trpg_cards.owned_cards where player_id=agent;
      select coalesce((select level from trpg_cards.growth_levels
        where player_id=agent and stat='POW'),0) into initial_growth;
      if first_cert is null or initial_medals<>1
        or (select qualification from trpg_hq.hq_agents where agent_id=agent)<>'full_agent' then
        raise exception 'existing_full_agent_fixture_missing';
      end if;

      for t in 1..2 loop
        if t=2 then
          -- No two active team memberships for one permanent agent.
          -- The existing unique partial index is authoritative: test it.
          begin
            perform trpg_hq.create_team(
              'hq10-'||r.scenario||'-illegal-duplicate',
              array[agent]);
            raise exception 'hq10_duplicate_active_team_was_accepted';
          exception when unique_violation then
            if position('hq_one_active_team_per_agent' in sqlerrm)=0 then
              raise;end if;
          end;
          -- Synthetic prior-team departure AFTER verified return/approval,
          -- never an implicit/real player's consent. Leave old honors intact.
          update trpg_hq.hq_team_members
            set left_at_minutes=(select hq_elapsed_minutes
              from trpg_hq.hq_teams where team_id=teams[1])
            where team_id=teams[1] and agent_id=agent
              and left_at_minutes is null;
          if not found then raise exception 'hq10_fixture_prior_team_not_exited';end if;
        end if;
        teamid:=(trpg_hq.create_team(
          'hq10-'||r.scenario||'-team-'||t,
          array[agent])->>'team_id')::uuid;
        teams:=array_append(teams,teamid);
        campaign:='hq10-'||r.scenario||'-camp-'||t;
        sess:='hq10-'||r.scenario||'-session-'||t;
        camps:=array_append(camps,campaign);
        perform trpg_cards.open_campaign(campaign,'chronicle',sess);
        perform trpg_cards.enroll_player(campaign,agent,'guardian');
        insert into trpg_private.gm_canon_documents(
          campaign_id,canon_id,revision,filename,document_format,
          rules_version,content_md,file_sha256)
        select campaign,'hq10-canon',1,'PRIVATE_CANON_HQ10.md',
          document_format,rules_version,content_md,file_sha256
        from trpg_private.gm_canon_documents
        where campaign_id='hq-dev-chronicle-20261112'
          and canon_id='hq-dev-chronicle-canon' and revision=1;
        select file_sha256 into canon_sha from trpg_private.gm_canon_documents
          where campaign_id=campaign and canon_id='hq10-canon';
        res:=trpg_hq.prepare_mission(teamid,campaign,'chronicle','I',
          '[{"id":"dev10","description":"다중 팀 보상 소유권 격리","importance":"core"}]'::jsonb,
          '{"fixture":true}'::jsonb,'chapter:01',sess,0);
        missionid:=(res->>'mission_id')::uuid;
        missions:=array_append(missions,missionid);
        seg:=(res->>'segment_id')::uuid;
        parent_sha:=null;
        for chap in 1..2 loop
          if chap=2 then
            select revision into rev from trpg_hq.hq_teams where team_id=teamid;
            res:=trpg_hq.prepare_next_chapter(
              missionid,'chapter:02',sess,rev);
            seg:=(res->>'segment_id')::uuid;
          end if;
          select revision into rev from trpg_hq.hq_teams where team_id=teamid;
          perform trpg_hq.start_segment(seg,rev);
          select state_json::jsonb into state from public.gm_checkpoint_history
          where session_id='hq-dev-chronicle-session-20261112'
            and version=chap and status='verified';
          state:=jsonb_set(state,'{campaign_id}',to_jsonb(campaign));
          state:=jsonb_set(state,'{session_id}',to_jsonb(sess));
          state:=jsonb_set(state,'{canon_ref,campaign_id}',to_jsonb(campaign));
          state:=jsonb_set(state,'{canon_ref,canon_id}',to_jsonb('hq10-canon'::text));
          state:=jsonb_set(state,'{canon_ref,filename}',to_jsonb('PRIVATE_CANON_HQ10.md'::text));
          state:=jsonb_set(state,'{canon_ref,file_sha256}',to_jsonb(canon_sha));
          state:=jsonb_set(state,'{runtime,hq,mission_id}',to_jsonb(missionid::text));
          state:=jsonb_set(state,'{runtime,hq,segment_key}',
            to_jsonb('chapter:0'||chap::text));
          state:=jsonb_set(state,'{pcs}',jsonb_build_object('P1',
            jsonb_build_object('player_id',agent::text,'alive',true)));
          state:=jsonb_set(state,'{runtime,ending_state}',
            jsonb_build_object('scope',case when chap=1 then 'CHAPTER_TERMINAL'
                 else 'CHRONICLE_TERMINAL' end,
              'status','completed','returning_agent_ids',
              jsonb_build_array(agent::text),
              'finalization_event_id',campaign||':terminal:'||chap::text));
          state:=jsonb_set(state,'{checkpoint}',jsonb_build_object(
            'version',chap,'event_id',sess||':cp'||chap::text,
            'attempt_id','hq10-attempt-'||chap::text,
            'parent_version',case when chap=1 then null else 1 end,
            'parent_sha256',parent_sha));
          json_state:=state::text;
          if public.trpg_v2_payload_issue(json_state) is not null then
            raise exception 'hq10_payload_issue: %',public.trpg_v2_payload_issue(json_state);
          end if;
          cp_sha:=encode(sha256(convert_to(json_state,'UTF8')),'hex');
          perform public.trpg_v2_commit(
            sess,chap,sess||':cp'||chap::text,'hq10-attempt-'||chap::text,
            case when chap=1 then null else 1 end,
            parent_sha,json_state,cp_sha);
          perform public.trpg_v2_verify(sess,chap,sess||':cp'||chap::text,
            'hq10-attempt-'||chap::text,cp_sha);
          select revision into rev from trpg_hq.hq_teams where team_id=teamid;
          perform trpg_hq.confirm_segment_terminal(seg,chap,cp_sha,rev);
          select revision into rev from trpg_hq.hq_teams where team_id=teamid;
          perform trpg_hq.return_segment(seg,rev);
          select revision into rev from trpg_hq.hq_teams where team_id=teamid;
          perform trpg_hq.evaluate_segment(seg,rev,'B',
            '[{"id":"dev10","result":"achieved","reason":"가상 검증"}]'::jsonb,
            'DEV10 독립 팀 마틴 평가',jsonb_build_object('fixture',true));
          parent_sha:=cp_sha;
        end loop;
        select revision into rev from trpg_hq.hq_teams where team_id=teamid;
        approval:=trpg_hq.approve_chronicle_completion(
          seg,rev,'DEV10 독립 팀의 검증된 연대기 전체 완주');
        if approval->>'applied'<>'true'
          or (approval->>'new_full_certifications')::integer<>0
          or (approval->>'medals')::integer<>1 then
          raise exception 'hq10_invalid_completion: %',approval;end if;
      end loop;

      if (select count(*) from trpg_hq.hq_chronicle_honors
          where mission_id=any(missions))<>2
        or (select count(*) from trpg_hq.hq_agent_full_certifications
          where player_id=agent)<>1
        or (select first_mission_id from trpg_hq.hq_agent_full_certifications
          where player_id=agent) is distinct from first_cert then
        raise exception 'hq10_two_teams_first_certification_or_medals_mismatch';
      end if;

      if r.scenario='card_dedup' then
        if exists(select 1 from trpg_cards.owned_cards
           where player_id=agent and card_id in ('GU-A-1','GU-A-2')) then
          raise exception 'hq10_fixture_cards_already_owned';end if;
        select revision into rev from trpg_hq.hq_teams where team_id=teams[1];
        res:=trpg_hq.resolve_chronicle_special(missions[1],agent,rev,'card','GU-A-1');
        if res->>'applied'<>'true' then raise exception 'hq10_first_team_card_failure';end if;
        -- Team 2 revision DID NOT change after team 1 card write. It still
        -- must re-check shared permanent player inventory.
        select revision into rev from trpg_hq.hq_teams where team_id=teams[2];
        begin
          perform trpg_hq.resolve_chronicle_special(
             missions[2],agent,rev,'card','GU-A-1');
          raise exception 'hq10_duplicate_card_across_teams';
        exception when others then
          if sqlerrm<>'hq_special_card_already_owned' then raise;end if;
        end;
        if not exists(select 1 from trpg_hq.hq_chronicle_honors
          where mission_id=missions[2] and player_id=agent
            and status='awaiting_choice') then
          raise exception 'hq10_rejected_second_team_card_destroyed_choice';end if;
        res:=trpg_hq.resolve_chronicle_special(
          missions[2],agent,rev,'card','GU-A-2');
        if res->>'applied'<>'true' then
          raise exception 'hq10_second_team_alternate_not_received';end if;
        if (select count(*) from trpg_cards.owned_cards
          where player_id=agent and card_id in ('GU-A-1','GU-A-2'))<>2
          or (select count(*) from trpg_cards.owned_cards where player_id=agent)
           <>initial_cards+2 then
          raise exception 'hq10_cards_not_globally_exactly_once';end if;
      else
        for t in 1..2 loop
          select revision into rev from trpg_hq.hq_teams where team_id=teams[t];
          res:=trpg_hq.resolve_chronicle_special(
            missions[t],agent,rev,'growth','POW');
          if res->>'applied'<>'true'
            or (res->'outcome'->>'before_level')::integer<>initial_growth+t-1
            or (res->'outcome'->>'after_level')::integer<>initial_growth+t then
            raise exception 'hq10_cross_team_growth_not_serially_incremented';end if;
        end loop;
        if coalesce((select level from trpg_cards.growth_levels
           where player_id=agent and stat='POW'),0)<>initial_growth+2 then
          raise exception 'hq10_double_growth_count_wrong';end if;
        select revision into rev from trpg_hq.hq_teams where team_id=teams[1];
        res:=trpg_hq.resolve_chronicle_special(
          missions[1],agent,rev,'growth','POW');
        if res->>'applied'<>'false' then
          raise exception 'hq10_repeat_growth_granted';end if;
      end if;
      if exists(select 1 from jsonb_array_elements(
           trpg_hq.load_chronicle_honors(teams[1])) x(value)
            where x.value->>'ledger_consistent'<>'true')
         or exists(select 1 from jsonb_array_elements(
           trpg_hq.load_chronicle_honors(teams[2])) x(value)
            where x.value->>'ledger_consistent'<>'true') then
        raise exception 'hq10_individual_team_medal_ledger_mismatch';end if;
      if (select count(*) from trpg_hq.hq_chronicle_honors
          where player_id=agent)<>initial_medals+2 then
        raise exception 'hq10_not_two_new_honors';end if;
      report:=jsonb_build_object(
        'same_permanent_agent_uuid',true,
        'two_distinct_historical_team_keys',true,
        'two_simultaneously_active_team_memberships_rejected',true,
        'previous_membership_closed_before_next_join',true,
        'two_distinct_verified_chronicles',true,
        'first_formal_certificate_stays_one',true,
        'two_new_honors',2,
        'global_card_or_growth_ledger_consistent',true,
        'cross_team_same_card_rejected_and_alternative_valid',
          case when r.scenario='card_dedup' then true else null end,
        'cross_team_separate_growth_awards_both_applied',
          case when r.scenario='growth_serial' then true else null end,
        'actual_parallel_connections_tested',false,
        'all_synthetic_changes_rolled_back',true);
      raise exception 'HQ10_SUCCESS_ROLLBACK';
    exception when others then
      if sqlerrm<>'HQ10_SUCCESS_ROLLBACK' then
        raise exception 'HQ10 scenario % failed: %',r.scenario,sqlerrm;end if;
    end;
    insert into pg_temp.hq10_cross_team_reports(scenario,result)
      values(r.scenario,report);
  end loop;
end $t$;
select scenario,result from pg_temp.hq10_cross_team_reports order by scenario;