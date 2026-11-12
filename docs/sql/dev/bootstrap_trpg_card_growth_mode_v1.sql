-- DEVELOPMENT-ONLY migration bootstrap derived from docs/sql/trpg-card-permanent-growth-mode-v1.sql
-- Source blob SHA: 6922fec3ef3e56fa2c0b05b2bce97d05db6d5f44
-- Correct 2 missing function terminator semicolon(s), remove wrapper BEGIN/COMMIT.
-- Only on a standalone empty/new test database; not suitable for live repair.
-- 2026-11-11 additive migration; original card_link_pc and historical character snapshots unchanged.
-- Legacy false parameter supports existing compatibility flows only; new-session OFF skips all card RPCs, classes, loadouts, growth bonuses, and rewards.
CREATE OR REPLACE FUNCTION trpg_cards.link_character_with_growth_mode(p_campaign_id text, p_player_id uuid, p_pc_id text, p_base_stats jsonb, p_permanent_growth boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare
 v_stat text; v_value int;
 v_snap jsonb:='{}'::jsonb; v_result jsonb:='{}'::jsonb;
 v_old trpg_cards.character_links%rowtype;
begin
 if p_permanent_growth is null then raise exception 'permanent_growth_mode_required'; end if;
 if p_permanent_growth then
   return trpg_cards.link_character(p_campaign_id,p_player_id,p_pc_id,p_base_stats)
      || jsonb_build_object('permanent_growth_enabled',true);
 end if;
 if not exists (select 1 from trpg_cards.campaign_members
  where campaign_id=p_campaign_id and player_id=p_player_id)
 then raise exception 'player_not_enrolled'; end if;
 if p_pc_id is null or char_length(p_pc_id) not between 1 and 120
  or jsonb_typeof(p_base_stats)<>'object'
 then raise exception 'invalid_character_data'; end if;
 select * into v_old from trpg_cards.character_links
  where campaign_id=p_campaign_id and pc_id=p_pc_id;
 if found then
   if v_old.player_id<>p_player_id or v_old.base_stats<>p_base_stats
   then raise exception 'character_binding_conflict'; end if;
   if v_old.applied_stats<>v_old.base_stats
   then raise exception 'character_growth_mode_conflict'; end if;
   return jsonb_build_object('campaign_id',p_campaign_id,'pc_id',p_pc_id,'player_id',p_player_id,
     'applied_growth',v_old.applied_growth,'applied_stats',v_old.applied_stats,
     'permanent_growth_enabled',false,'reused',true);
 end if;
 foreach v_stat in array array['STR','CON','SIZ','DEX','APP','INT','POW','EDU'] loop
   if not (p_base_stats ? v_stat) or jsonb_typeof(p_base_stats->v_stat)<>'number'
     or (p_base_stats->>v_stat) !~ '^[0-9]+$'
   then raise exception 'invalid_character_stat %',v_stat; end if;
   v_value:=(p_base_stats->>v_stat)::int;
   if v_value<0 or v_value>100 then raise exception 'invalid_character_stat_range %',v_stat; end if;
   v_snap:=v_snap||jsonb_build_object(v_stat,0);
   v_result:=v_result||jsonb_build_object(v_stat,v_value);
 end loop;
 insert into trpg_cards.character_links(campaign_id,player_id,pc_id,base_stats,applied_growth,applied_stats)
 values (p_campaign_id,p_player_id,p_pc_id,p_base_stats,v_snap,v_result);
 return jsonb_build_object('campaign_id',p_campaign_id,'pc_id',p_pc_id,'player_id',p_player_id,
   'applied_growth',v_snap,'applied_stats',v_result,
   'permanent_growth_enabled',false,'reused',false);
end $function$;
;
CREATE OR REPLACE FUNCTION public.card_link_pc_with_growth_mode(p_nickname text, p_campaign_id text, p_pc_id text, p_base_stats jsonb, p_permanent_growth boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare v_uuid uuid;
begin
 select id into v_uuid from trpg_cards.players where nickname_key=lower(btrim(p_nickname));
 if v_uuid is null then raise exception 'nickname_not_registered'; end if;
 return trpg_cards.link_character_with_growth_mode(
   p_campaign_id,v_uuid,p_pc_id,p_base_stats,p_permanent_growth);
end $function$;
;
revoke execute on function trpg_cards.link_character_with_growth_mode(text,uuid,text,jsonb,boolean) from public,anon,authenticated;
revoke execute on function public.card_link_pc_with_growth_mode(text,text,text,jsonb,boolean) from public,anon,authenticated;
grant execute on function public.card_link_pc_with_growth_mode(text,text,text,jsonb,boolean) to anon,authenticated;
notify pgrst,'reload schema';
