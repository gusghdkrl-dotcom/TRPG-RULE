-- Supabase migration exposed nickname-only card portal, 2026-11-10.
-- Player explicitly chose nickname-only access without login for 2-3 trusted people.
-- Any party knowing a nickname may assume that identity; this is NOT account security.
-- Original gm checkpoint tables, RPC, and full game states remain protected.
-- Applies to an existing trpg_cards v1 database; not re-runnable over unrelated schemas.
begin;
CREATE OR REPLACE FUNCTION public.card_equip(p_nickname text, p_campaign_id text, p_boundary text, p_asset text, p_enhancement text, p_flex_a text, p_flex_b text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare v_uuid uuid;
begin
 select id into v_uuid from trpg_cards.players where nickname_key=lower(btrim(p_nickname));
 if v_uuid is null then raise exception 'nickname_not_registered'; end if;
 return trpg_cards.save_loadout(p_campaign_id,v_uuid,p_boundary,p_asset,p_enhancement,p_flex_a,p_flex_b);
end $function$

CREATE OR REPLACE FUNCTION public.card_join(p_nickname text, p_campaign_id text, p_class text, p_mode text, p_session_id text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare v_login jsonb; v_uuid uuid; v_campaign jsonb; v_member jsonb;
begin
 v_login:=trpg_cards.register_player(p_nickname);
 v_uuid:=(v_login->>'player_id')::uuid;
 v_campaign:=trpg_cards.open_campaign(p_campaign_id,p_mode,p_session_id);
 v_member:=trpg_cards.enroll_player(p_campaign_id,v_uuid,p_class);
 return jsonb_build_object('player_id',v_uuid,'nickname',(select nickname from trpg_cards.players where id=v_uuid),
  'campaign',v_campaign,'membership',v_member);
end $function$

CREATE OR REPLACE FUNCTION public.card_link_pc(p_nickname text, p_campaign_id text, p_pc_id text, p_base_stats jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare v_uuid uuid;
begin
 select id into v_uuid from trpg_cards.players where nickname_key=lower(btrim(p_nickname));
 if v_uuid is null then raise exception 'nickname_not_registered'; end if;
 return trpg_cards.link_character(p_campaign_id,v_uuid,p_pc_id,p_base_stats);
end $function$

CREATE OR REPLACE FUNCTION public.card_login(p_nickname text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare v_identity jsonb; v_uuid uuid;
begin
  v_identity:=trpg_cards.register_player(p_nickname);
  v_uuid:=(v_identity->>'player_id')::uuid;
  return jsonb_build_object(
    'player_id',v_uuid,
    'nickname',(select nickname from trpg_cards.players where id=v_uuid),
    'newly_registered',(v_identity->>'newly_registered')::boolean,
    'cards',(select coalesce(jsonb_agg(jsonb_build_object(
        'id',c.card_id,'name',c.title,'faction',c.faction,'type',c.kind,
        'rarity',c.rarity) order by c.card_id),'[]'::jsonb)
      from trpg_cards.owned_cards o join trpg_cards.card_catalog c using(card_id)
      where o.player_id=v_uuid),
    'growth',(select coalesce(jsonb_object_agg(stat,level),'{}'::jsonb)
      from trpg_cards.growth_levels where player_id=v_uuid),
    'campaigns',(select coalesce(jsonb_agg(jsonb_build_object(
      'campaign_id',campaign_id,'class',class_key) order by campaign_id),'[]'::jsonb)
      from trpg_cards.campaign_members where player_id=v_uuid)
  );
end $function$

CREATE OR REPLACE FUNCTION public.card_lookup(p_nickname text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare v_uuid uuid;
begin
 if p_nickname is null or char_length(btrim(p_nickname)) not between 2 and 24
 then return jsonb_build_object('found',false); end if;
 select id into v_uuid from trpg_cards.players where nickname_key=lower(btrim(p_nickname));
 if v_uuid is null then return jsonb_build_object('found',false); end if;
 return jsonb_build_object('found',true,'player',public.card_login(p_nickname));
end $function$

CREATE OR REPLACE FUNCTION public.card_pick_reward(p_nickname text, p_campaign_id text, p_event_key text, p_choice smallint, p_python_roll integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare v_uuid uuid;
begin
 select id into v_uuid from trpg_cards.players where nickname_key=lower(btrim(p_nickname));
 if v_uuid is null then raise exception 'nickname_not_registered'; end if;
 return trpg_cards.resolve_draft(p_campaign_id,v_uuid,p_event_key,p_choice,p_python_roll);
end $function$

CREATE OR REPLACE FUNCTION public.card_rewards(p_nickname text, p_campaign_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
declare v_uuid uuid; v_pool jsonb;
begin
 select id into v_uuid from trpg_cards.players where nickname_key=lower(btrim(p_nickname));
 if v_uuid is null then raise exception 'nickname_not_registered'; end if;
 v_pool:=trpg_cards.draft_pool(p_campaign_id,v_uuid);
 return jsonb_build_object('player_id',v_uuid,'candidate_pool',v_pool,
  'drafts',(select coalesce(jsonb_agg(jsonb_build_object(
    'event_key',event_key,'offers',offers,'status',status,'choice',chosen_slot,
    'outcome',outcome) order by opened_at),'[]'::jsonb)
  from trpg_cards.drafts where player_id=v_uuid and campaign_id=p_campaign_id));
end $function$

-- Do not grant public/anon/authenticated permissions on the private tables or schema.
revoke execute on function public.card_equip(p_nickname text, p_campaign_id text, p_boundary text, p_asset text, p_enhancement text, p_flex_a text, p_flex_b text) from public, anon, authenticated;
grant execute on function public.card_equip(p_nickname text, p_campaign_id text, p_boundary text, p_asset text, p_enhancement text, p_flex_a text, p_flex_b text) to anon, authenticated;
revoke execute on function public.card_join(p_nickname text, p_campaign_id text, p_class text, p_mode text, p_session_id text) from public, anon, authenticated;
grant execute on function public.card_join(p_nickname text, p_campaign_id text, p_class text, p_mode text, p_session_id text) to anon, authenticated;
revoke execute on function public.card_link_pc(p_nickname text, p_campaign_id text, p_pc_id text, p_base_stats jsonb) from public, anon, authenticated;
grant execute on function public.card_link_pc(p_nickname text, p_campaign_id text, p_pc_id text, p_base_stats jsonb) to anon, authenticated;
revoke execute on function public.card_login(p_nickname text) from public, anon, authenticated;
grant execute on function public.card_login(p_nickname text) to anon, authenticated;
revoke execute on function public.card_lookup(p_nickname text) from public, anon, authenticated;
grant execute on function public.card_lookup(p_nickname text) to anon, authenticated;
revoke execute on function public.card_pick_reward(p_nickname text, p_campaign_id text, p_event_key text, p_choice smallint, p_python_roll integer) from public, anon, authenticated;
grant execute on function public.card_pick_reward(p_nickname text, p_campaign_id text, p_event_key text, p_choice smallint, p_python_roll integer) to anon, authenticated;
revoke execute on function public.card_rewards(p_nickname text, p_campaign_id text) from public, anon, authenticated;
grant execute on function public.card_rewards(p_nickname text, p_campaign_id text) to anon, authenticated;
notify pgrst,'reload schema';
commit;
