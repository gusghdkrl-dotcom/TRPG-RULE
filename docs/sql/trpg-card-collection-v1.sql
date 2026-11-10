-- Mirrors the two applied Supabase migrations on trpg-state-v2 (2026-11-10).
-- DANGER: Initial installation only; do not run on a populated live schema.
-- Isolated private schema: does NOT change public.gm_checkpoint_history.
begin;
create schema if not exists trpg_cards;
revoke all on schema trpg_cards from public, anon, authenticated;
create table trpg_cards.players (
 id uuid primary key default gen_random_uuid(),
 nickname text not null,
 nickname_key text generated always as (lower(btrim(nickname))) stored unique,
 created_at timestamptz not null default now(),
 constraint nickname_clean check (nickname=btrim(nickname) and char_length(nickname) between 2 and 24 and nickname !~ '[[:cntrl:]]')
);
create table trpg_cards.card_catalog (
 card_id text primary key,
 faction text not null check (faction in ('guardian','seeker','rogue','wildcard','survivor','neutral')),
 kind text not null check(kind in ('asset','enhancement')),
 rarity text not null check(rarity in ('common','rare','epic','legendary')),
 title text not null, is_starter boolean not null,
 ordinal smallint not null check(ordinal between 0 and 7),
 unique(faction,kind,ordinal),
 check ((faction='neutral' and rarity='common' and is_starter=(ordinal < 4))
 or (faction<>'neutral' and ordinal<=4 and is_starter=(ordinal=0)
 and rarity=(case when ordinal<=2 then 'rare' when ordinal=3 then 'epic' else 'legendary' end)))
);
insert into trpg_cards.card_catalog(card_id,faction,kind,rarity,title,is_starter,ordinal) values
('GU-A-0','guardian','asset','rare','호위용 차폐구',true,0),
('GU-A-1','guardian','asset','rare','제압용 결속구',false,1),
('GU-A-2','guardian','asset','rare','야전 구호 세트',false,2),
('GU-A-3','guardian','asset','epic','함께 지키는 전우',false,3),
('GU-A-4','guardian','asset','legendary','방어 거점 구축 세트',false,4),
('GU-E-0','guardian','enhancement','rare','내가 막는다',true,0),
('GU-E-1','guardian','enhancement','rare','맹렬한 일격',false,1),
('GU-E-2','guardian','enhancement','rare','승리의 증거',false,2),
('GU-E-3','guardian','enhancement','epic','선두에 서다',false,3),
('GU-E-4','guardian','enhancement','legendary','최후의 방어선',false,4),
('NE-A-0','neutral','asset','common','휴대 광원',true,0),
('NE-A-1','neutral','asset','common','응급 꾸러미',true,1),
('NE-A-2','neutral','asset','common','로프와 고정구',true,2),
('NE-A-3','neutral','asset','common','휴대 신호 도구',true,3),
('NE-A-4','neutral','asset','common','문 고정용 쐐기',false,4),
('NE-A-5','neutral','asset','common','밀폐 운반통',false,5),
('NE-A-6','neutral','asset','common','호흡 보호구',false,6),
('NE-A-7','neutral','asset','common','비상 방수포',false,7),
('NE-E-0','neutral','enhancement','common','손에 잡히는 대로',true,0),
('NE-E-1','neutral','enhancement','common','충격을 흘린다',true,1),
('NE-E-2','neutral','enhancement','common','온전하게 건진다',true,2),
('NE-E-3','neutral','enhancement','common','값을 깎는 요령',true,3),
('NE-E-4','neutral','enhancement','common','손에 익은 응급처치',false,4),
('NE-E-5','neutral','enhancement','common','문은 닫고 간다',false,5),
('NE-E-6','neutral','enhancement','common','여분을 남긴다',false,6),
('NE-E-7','neutral','enhancement','common','비상금',false,7),
('RO-A-0','rogue','asset','rare','우회 공구함',true,0),
('RO-A-1','rogue','asset','rare','은닉 반출 장비',false,1),
('RO-A-2','rogue','asset','rare','경계 횡단 장비',false,2),
('RO-A-3','rogue','asset','epic','역할 위장함',false,3),
('RO-A-4','rogue','asset','legendary','거짓길 공작 세트',false,4),
('RO-E-0','rogue','enhancement','rare','발 빠른 이탈',true,0),
('RO-E-1','rogue','enhancement','rare','흔적 없는 손길',false,1),
('RO-E-2','rogue','enhancement','rare','거래의 기술',false,2),
('RO-E-3','rogue','enhancement','epic','한 수 먼저',false,3),
('RO-E-4','rogue','enhancement','legendary','모두가 속아 넘어간 순간',false,4),
('SE-A-0','seeker','asset','rare','현장 감식함',true,0),
('SE-A-1','seeker','asset','rare','휴대 반응 시험함',false,1),
('SE-A-2','seeker','asset','rare','굴절 관찰기',false,2),
('SE-A-3','seeker','asset','epic','원격 탐사 장치',false,3),
('SE-A-4','seeker','asset','legendary','다지점 현상 관측망',false,4),
('SE-E-0','seeker','enhancement','rare','날카로운 관찰력',true,0),
('SE-E-1','seeker','enhancement','rare','필요한 것은 여기에',false,1),
('SE-E-2','seeker','enhancement','rare','불길한 징후',false,2),
('SE-E-3','seeker','enhancement','epic','계산된 대응',false,3),
('SE-E-4','seeker','enhancement','legendary','모든 조각이 맞아떨어진다',false,4),
('SU-A-0','survivor','asset','rare','기워 입은 가죽 외투',true,0),
('SU-A-1','survivor','asset','rare','잡동사니 보따리',false,1),
('SU-A-2','survivor','asset','rare','녹슨 삽 한 자루',false,2),
('SU-A-3','survivor','asset','epic','끝까지 쓸모 있는 소화기',false,3),
('SU-A-4','survivor','asset','legendary','끝까지 따라온 녀석',false,4),
('SU-E-0','survivor','enhancement','rare','헛수고는 아니야!',true,0),
('SU-E-1','survivor','enhancement','rare','부러졌다고 끝이냐?',false,1),
('SU-E-2','survivor','enhancement','rare','넘어져서 살았다',false,2),
('SU-E-3','survivor','enhancement','epic','아직 움직일 수 있어',false,3),
('SU-E-4','survivor','enhancement','legendary','다 끝난 줄 알았지?',false,4),
('WI-A-0','wildcard','asset','rare','비상 분리 장구',true,0),
('WI-A-1','wildcard','asset','rare','승부사의 담보함',false,1),
('WI-A-2','wildcard','asset','rare','강행 돌파 세트',false,2),
('WI-A-3','wildcard','asset','epic','위험한 미끼 장치',false,3),
('WI-A-4','wildcard','asset','legendary','주머니 속의 공범들',false,4),
('WI-E-0','wildcard','enhancement','rare','아슬아슬한 한 수',true,0),
('WI-E-1','wildcard','enhancement','rare','승리의 배당',false,1),
('WI-E-2','wildcard','enhancement','rare','몸으로 밀어붙인다',false,2),
('WI-E-3','wildcard','enhancement','epic','모든 것을 건 순간',false,3),
('WI-E-4','wildcard','enhancement','legendary','모 아니면 도',false,4);
create table trpg_cards.owned_cards (
 player_id uuid not null references trpg_cards.players(id),
 card_id text not null references trpg_cards.card_catalog(card_id),
 acquired_at timestamptz not null default now(),
 acquisition_event text not null default 'starter',
 primary key(player_id,card_id)
);
create table trpg_cards.growth_levels (
 player_id uuid not null references trpg_cards.players(id),
 stat text not null check(stat in ('STR','CON','SIZ','DEX','APP','INT','POW','EDU')),
 level smallint not null check(level between 1 and 5),
 changed_at timestamptz not null default now(),
 primary key(player_id,stat)
);
create table trpg_cards.campaigns (
 campaign_id text primary key check(char_length(campaign_id) between 1 and 120),
 campaign_mode text not null check(campaign_mode in ('major','chronicle')),
 source_session_id text, created_at timestamptz not null default now()
);
create table trpg_cards.campaign_members (
 campaign_id text not null references trpg_cards.campaigns(campaign_id),
 player_id uuid not null references trpg_cards.players(id),
 class_key text not null check(class_key in ('guardian','seeker','rogue','wildcard','survivor')),
 joined_at timestamptz not null default now(),
 primary key(campaign_id,player_id)
);
create table trpg_cards.character_links (
 campaign_id text not null, player_id uuid not null,
 pc_id text not null check(char_length(pc_id) between 1 and 120),
 base_stats jsonb not null check(jsonb_typeof(base_stats)='object'),
 applied_growth jsonb not null check(jsonb_typeof(applied_growth)='object'),
 applied_stats jsonb not null check(jsonb_typeof(applied_stats)='object'),
 linked_at timestamptz not null default now(),
 primary key(campaign_id,pc_id),
 foreign key(campaign_id,player_id) references trpg_cards.campaign_members(campaign_id,player_id)
);
create index character_links_player_idx on trpg_cards.character_links(player_id,campaign_id);
create table trpg_cards.drafts (
 campaign_id text not null, event_key text not null check(char_length(event_key) between 1 and 120),
 player_id uuid not null, source_event_id text not null check(char_length(source_event_id) between 1 and 255),
 offers jsonb not null check(jsonb_typeof(offers)='object'),
 status text not null check(status in ('offered','resolved','exhausted')),
 chosen_slot smallint check(chosen_slot between 1 and 4), outcome jsonb,
 opened_at timestamptz not null default now(),resolved_at timestamptz,
 primary key(campaign_id,event_key,player_id),
 foreign key(campaign_id,player_id) references trpg_cards.campaign_members(campaign_id,player_id)
);
create unique index drafts_one_open_per_player on trpg_cards.drafts(player_id) where status='offered';
create index drafts_player_history on trpg_cards.drafts(player_id,opened_at desc);
create table trpg_cards.loadouts (
 campaign_id text not null,player_id uuid not null,
 boundary_key text not null check(char_length(boundary_key) between 1 and 120),
 asset_card_id text not null references trpg_cards.card_catalog(card_id),
 enhancement_card_id text not null references trpg_cards.card_catalog(card_id),
 flex_a_card_id text not null references trpg_cards.card_catalog(card_id),
 flex_b_card_id text not null references trpg_cards.card_catalog(card_id),
 created_at timestamptz not null default now(),
 primary key(campaign_id,player_id,boundary_key),
 foreign key(campaign_id,player_id) references trpg_cards.campaign_members(campaign_id,player_id),
 check (asset_card_id<>enhancement_card_id and asset_card_id<>flex_a_card_id and asset_card_id<>flex_b_card_id
 and enhancement_card_id<>flex_a_card_id and enhancement_card_id<>flex_b_card_id
 and flex_a_card_id<>flex_b_card_id)
);
alter table trpg_cards.players enable row level security;
alter table trpg_cards.card_catalog enable row level security;
alter table trpg_cards.owned_cards enable row level security;
alter table trpg_cards.growth_levels enable row level security;
alter table trpg_cards.campaigns enable row level security;
alter table trpg_cards.campaign_members enable row level security;
alter table trpg_cards.character_links enable row level security;
alter table trpg_cards.drafts enable row level security;
alter table trpg_cards.loadouts enable row level security;
revoke all on all tables in schema trpg_cards from public, anon, authenticated;
-- Function definitions are extracted from the deployed schema, not paraphrased.
CREATE OR REPLACE FUNCTION trpg_cards.draft_pool(p_campaign_id text, p_player_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare v_class text; v_current jsonb; v_all jsonb; v_neutral jsonb; v_growth jsonb;
begin
 select class_key into v_class from trpg_cards.campaign_members
 where campaign_id=p_campaign_id and player_id=p_player_id;
 if v_class is null then raise exception 'player_not_enrolled'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',c.card_id,'title',c.title,'rarity',c.rarity)
 order by c.card_id),'[]'::jsonb) into v_current
 from trpg_cards.card_catalog c where not c.is_starter and c.faction=v_class
 and not exists(select 1 from trpg_cards.owned_cards o where o.player_id=p_player_id and o.card_id=c.card_id);
 select coalesce(jsonb_agg(jsonb_build_object('id',c.card_id,'title',c.title,'rarity',c.rarity)
 order by c.card_id),'[]'::jsonb) into v_all
 from trpg_cards.card_catalog c where not c.is_starter and c.faction<>'neutral'
 and not exists(select 1 from trpg_cards.owned_cards o where o.player_id=p_player_id and o.card_id=c.card_id);
 select coalesce(jsonb_agg(jsonb_build_object('id',c.card_id,'title',c.title,'rarity',c.rarity)
 order by c.card_id),'[]'::jsonb) into v_neutral
 from trpg_cards.card_catalog c where not c.is_starter and c.faction='neutral'
 and not exists(select 1 from trpg_cards.owned_cards o where o.player_id=p_player_id and o.card_id=c.card_id);
 select coalesce(jsonb_agg(jsonb_build_object('id',s.stat,'current_level',coalesce(g.level,0))
 order by s.ordinal),'[]'::jsonb) into v_growth
 from unnest(array['STR','CON','SIZ','DEX','APP','INT','POW','EDU']) with ordinality as s(stat,ordinal)
 left join trpg_cards.growth_levels g on g.player_id=p_player_id and g.stat=s.stat
 where coalesce(g.level,0)<5;
 return jsonb_build_object('current',v_current,'all',v_all,'growth',v_growth,'neutral',v_neutral);
end $function$

CREATE OR REPLACE FUNCTION trpg_cards.enroll_player(p_campaign_id text, p_player_id uuid, p_class text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare v_class text;
begin
 if p_class not in ('guardian','seeker','rogue','wildcard','survivor') then
   raise exception 'invalid_class';
 end if;
 insert into trpg_cards.campaign_members(campaign_id,player_id,class_key)
 values(p_campaign_id,p_player_id,p_class) on conflict do nothing;
 select class_key into v_class from trpg_cards.campaign_members
 where campaign_id=p_campaign_id and player_id=p_player_id;
 if v_class is distinct from p_class then raise exception 'class_locked_for_campaign'; end if;
 return jsonb_build_object('campaign_id',p_campaign_id,'player_id',p_player_id,'class',v_class);
end $function$

CREATE OR REPLACE FUNCTION trpg_cards.issue_draft(p_campaign_id text, p_player_id uuid, p_event_key text, p_source_event_id text, p_offers jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare v_d trpg_cards.drafts%rowtype; v_mode text; v_pool jsonb; v_key text;
        v_candidate text; v_count int; v_nonempty int:=0; v_available int;
begin
 select * into v_d from trpg_cards.drafts
 where campaign_id=p_campaign_id and event_key=p_event_key and player_id=p_player_id;
 if found then
   return jsonb_build_object('status',v_d.status,'offers',v_d.offers,'outcome',v_d.outcome,'reused',true);
 end if;
 select campaign_mode into v_mode from trpg_cards.campaigns where campaign_id=p_campaign_id;
 if v_mode is null then raise exception 'unknown_campaign'; end if;
 if (v_mode='major' and p_event_key<>'final') or
    (v_mode='chronicle' and (p_event_key not like 'chapter:%' or char_length(p_event_key)<=8))
 then raise exception 'invalid_reward_boundary'; end if;
 if p_source_event_id is null or char_length(p_source_event_id) not between 1 and 255 then
   raise exception 'missing_verified_ending_event_reference'; end if;
 if exists(select 1 from trpg_cards.drafts where player_id=p_player_id and status='offered')
 then raise exception 'resolve_previous_draft_first'; end if;
 if jsonb_typeof(p_offers)<>'object' or
   (select count(*) from jsonb_object_keys(p_offers))<>4 then raise exception 'invalid_offer_shape'; end if;
 v_pool:=trpg_cards.draft_pool(p_campaign_id,p_player_id);
 foreach v_key in array array['current','all','growth','neutral'] loop
   if not p_offers ? v_key then raise exception 'missing_offer_slot %',v_key; end if;
   if jsonb_typeof(p_offers->v_key) not in ('string','null') then raise exception 'invalid_offer_type %',v_key; end if;
   v_candidate:=p_offers->>v_key;
   select count(*) into v_available from jsonb_array_elements(v_pool->v_key) e
      where v_key<>'all' or e->>'id' is distinct from p_offers->>'current';
   if v_candidate is null then
     if v_available>0 then raise exception 'nonempty_slot_without_offer %',v_key; end if;
   else
     if not exists (select 1 from jsonb_array_elements(v_pool->v_key) e
          where e->>'id'=v_candidate)
     then raise exception 'offer_not_eligible % %',v_key,v_candidate; end if;
     if v_key='all' and v_candidate=p_offers->>'current' then raise exception 'duplicate_class_offer'; end if;
     v_nonempty:=v_nonempty+1;
   end if;
 end loop;
 insert into trpg_cards.drafts(campaign_id,event_key,player_id,source_event_id,offers,status,outcome)
 values(p_campaign_id,p_event_key,p_player_id,p_source_event_id,p_offers,
   case when v_nonempty=0 then 'exhausted' else 'offered' end,
   case when v_nonempty=0 then jsonb_build_object('type','none','reason','all_pools_exhausted')
        else null end);
 return jsonb_build_object('status',case when v_nonempty=0 then 'exhausted' else 'offered' end,
   'offers',p_offers,'source_event_id',p_source_event_id,'reused',false);
end $function$

CREATE OR REPLACE FUNCTION trpg_cards.link_character(p_campaign_id text, p_player_id uuid, p_pc_id text, p_base_stats jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare v_stat text; v_value int; v_level int; v_snap jsonb:='{}'::jsonb;
        v_result jsonb:='{}'::jsonb; v_old trpg_cards.character_links%rowtype;
begin
 if not exists (select 1 from trpg_cards.campaign_members where campaign_id=p_campaign_id and player_id=p_player_id)
 then raise exception 'player_not_enrolled'; end if;
 if p_pc_id is null or char_length(p_pc_id) not between 1 and 120
 or jsonb_typeof(p_base_stats)<>'object' then raise exception 'invalid_character_data'; end if;
 select * into v_old from trpg_cards.character_links
 where campaign_id=p_campaign_id and pc_id=p_pc_id;
 if found then
   if v_old.player_id<>p_player_id or v_old.base_stats<>p_base_stats then raise exception 'character_binding_conflict'; end if;
   return jsonb_build_object('campaign_id',p_campaign_id,'pc_id',p_pc_id,'player_id',p_player_id,
     'applied_growth',v_old.applied_growth,'applied_stats',v_old.applied_stats,'reused',true);
 end if;
 foreach v_stat in array array['STR','CON','SIZ','DEX','APP','INT','POW','EDU'] loop
   if not (p_base_stats ? v_stat) or jsonb_typeof(p_base_stats->v_stat)<>'number'
   or (p_base_stats->>v_stat) !~ '^[0-9]+$' then raise exception 'invalid_character_stat %',v_stat; end if;
   v_value := (p_base_stats->>v_stat)::int;
   if v_value < 0 or v_value > 100 then raise exception 'invalid_character_stat_range %',v_stat; end if;
   select level into v_level from trpg_cards.growth_levels
   where player_id=p_player_id and stat=v_stat;
   v_level := coalesce(v_level,0);
   v_snap := v_snap || jsonb_build_object(v_stat,v_level);
   v_result := v_result || jsonb_build_object(v_stat,v_value+v_level);
 end loop;
 insert into trpg_cards.character_links(campaign_id,player_id,pc_id,base_stats,applied_growth,applied_stats)
 values(p_campaign_id,p_player_id,p_pc_id,p_base_stats,v_snap,v_result);
 return jsonb_build_object('campaign_id',p_campaign_id,'pc_id',p_pc_id,'player_id',p_player_id,
    'applied_growth',v_snap,'applied_stats',v_result,'reused',false);
end $function$

CREATE OR REPLACE FUNCTION trpg_cards.open_campaign(p_campaign_id text, p_mode text, p_session_id text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare v_c trpg_cards.campaigns%rowtype;
begin
 if p_mode not in ('major','chronicle') or char_length(btrim(p_campaign_id)) not between 1 and 120 then
   raise exception 'campaign_invalid';
 end if;
 insert into trpg_cards.campaigns(campaign_id,campaign_mode,source_session_id)
 values(p_campaign_id,p_mode,p_session_id) on conflict do nothing;
 select * into v_c from trpg_cards.campaigns where campaign_id=p_campaign_id;
 if v_c.campaign_mode<>p_mode or (v_c.source_session_id is distinct from p_session_id) then
   raise exception 'campaign_identity_conflict';
 end if;
 return jsonb_build_object('campaign_id',v_c.campaign_id,'mode',v_c.campaign_mode);
end $function$

CREATE OR REPLACE FUNCTION trpg_cards.register_player(p_nickname text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare v_id uuid; v_new boolean := false; v_name text := btrim(p_nickname);
begin
  if v_name is null or char_length(v_name) not between 2 and 24 or v_name ~ '[[:cntrl:]]' then
    raise exception 'nickname_invalid';
  end if;
  insert into trpg_cards.players(nickname) values(v_name)
    on conflict (nickname_key) do nothing returning id into v_id;
  if v_id is null then
    select id into v_id from trpg_cards.players where nickname_key=lower(v_name);
  else
    v_new := true;
  end if;
  if v_id is null then raise exception 'nickname_lookup_failed'; end if;
  insert into trpg_cards.owned_cards(player_id,card_id,acquisition_event)
    select v_id,card_id,'starter' from trpg_cards.card_catalog where is_starter
    on conflict do nothing;
  return jsonb_build_object('player_id',v_id,'nickname',v_name,'newly_registered',v_new,
    'owned_count',(select count(*) from trpg_cards.owned_cards where player_id=v_id));
end $function$

CREATE OR REPLACE FUNCTION trpg_cards.resolve_draft(p_campaign_id text, p_player_id uuid, p_event_key text, p_choice smallint, p_python_roll integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare v_d trpg_cards.drafts%rowtype; v_key text; v_card text; v_level int; v_before int;
        v_chance int; v_success boolean; v_out jsonb; v_rows int;
begin
 select * into v_d from trpg_cards.drafts
 where campaign_id=p_campaign_id and player_id=p_player_id and event_key=p_event_key for update;
 if not found then raise exception 'draft_not_issued'; end if;
 if v_d.status='exhausted' then return v_d.outcome; end if;
 if v_d.status='resolved' then
   if p_choice is distinct from v_d.chosen_slot then raise exception 'draft_already_resolved_with_other_choice'; end if;
   return v_d.outcome;
 end if;
 v_key:=case p_choice when 1 then 'current' when 2 then 'all'
  when 3 then 'growth' when 4 then 'neutral' end;
 if v_key is null then raise exception 'invalid_choice'; end if;
 v_card:=v_d.offers->>v_key;
 if v_card is null then raise exception 'empty_candidate_cannot_be_chosen'; end if;
 if v_key='growth' then
   select level into v_level from trpg_cards.growth_levels
   where player_id=p_player_id and stat=v_card for update;
   v_before:=coalesce(v_level,0);
   if v_before=0 then
     if p_python_roll is not null then raise exception 'first_growth_is_certain_do_not_roll'; end if;
     insert into trpg_cards.growth_levels(player_id,stat,level) values(p_player_id,v_card,1);
     v_success:=true; v_chance:=100;
     v_level:=1;
   else
     v_chance:=case v_before when 1 then 80 when 2 then 50 when 3 then 25 when 4 then 10 else null end;
     if v_chance is null then raise exception 'growth_already_maxed'; end if;
     if p_python_roll is null or p_python_roll not between 1 and 100 then raise exception 'python_roll_required_1_to_100'; end if;
     v_success:=p_python_roll<=v_chance;
     v_level:=v_before + case when v_success then 1 else 0 end;
     if v_success then update trpg_cards.growth_levels set level=v_level,changed_at=now()
       where player_id=p_player_id and stat=v_card; end if;
   end if;
   v_out:=jsonb_build_object('type','growth','stat',v_card,'before',v_before,
       'after',v_level,'chance_percent',v_chance,'roll',p_python_roll,'success',v_success);
 else
   insert into trpg_cards.owned_cards(player_id,card_id,acquisition_event)
   values(p_player_id,v_card,p_campaign_id||':'||p_event_key)
   on conflict do nothing;
   get diagnostics v_rows=row_count;
   if v_rows<>1 then raise exception 'card_already_owned_before_selection'; end if;
   v_out:=jsonb_build_object('type','card','card_id',v_card,'acquired',true);
 end if;
 update trpg_cards.drafts set status='resolved',chosen_slot=p_choice,outcome=v_out,resolved_at=now()
   where campaign_id=p_campaign_id and player_id=p_player_id and event_key=p_event_key;
 return v_out;
end $function$

CREATE OR REPLACE FUNCTION trpg_cards.save_loadout(p_campaign_id text, p_player_id uuid, p_boundary text, p_asset text, p_enhancement text, p_flex_a text, p_flex_b text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
declare v_mode text; v_class text; v_id text; v_kind text; v_faction text;
  v_start trpg_cards.loadouts%rowtype; v_existing trpg_cards.loadouts%rowtype;
  v_flex_start_a text; v_flex_start_b text; v_flex_new_a text; v_flex_new_b text;
begin
 select c.campaign_mode,m.class_key into v_mode,v_class
 from trpg_cards.campaigns c join trpg_cards.campaign_members m using(campaign_id)
 where c.campaign_id=p_campaign_id and m.player_id=p_player_id;
 if v_class is null then raise exception 'player_not_enrolled'; end if;
 if p_boundary<>'start' and (v_mode<>'chronicle' or p_boundary not like 'chapter:%')
 then raise exception 'loadout_change_only_at_chronicle_boundary'; end if;
 if p_asset=p_enhancement or p_asset=p_flex_a or p_asset=p_flex_b or
 p_enhancement=p_flex_a or p_enhancement=p_flex_b or p_flex_a=p_flex_b
 then raise exception 'duplicate_equipped_cards'; end if;
 foreach v_id in array array[p_asset,p_enhancement,p_flex_a,p_flex_b] loop
   select kind,faction into v_kind,v_faction from trpg_cards.card_catalog where card_id=v_id;
   if v_kind is null or v_faction not in (v_class,'neutral') or not exists
    (select 1 from trpg_cards.owned_cards where player_id=p_player_id and card_id=v_id)
   then raise exception 'card_not_owned_or_wrong_class %',v_id; end if;
   if v_id=p_asset and v_kind<>'asset' then raise exception 'asset_slot_requires_asset'; end if;
   if v_id=p_enhancement and v_kind<>'enhancement' then raise exception 'enhancement_slot_requires_enhancement'; end if;
 end loop;
 select * into v_existing from trpg_cards.loadouts
  where campaign_id=p_campaign_id and player_id=p_player_id and boundary_key=p_boundary;
 if found then
   if v_existing.asset_card_id is distinct from p_asset or
   v_existing.enhancement_card_id is distinct from p_enhancement or
   v_existing.flex_a_card_id is distinct from p_flex_a or v_existing.flex_b_card_id is distinct from p_flex_b
   then raise exception 'loadout_boundary_locked'; end if;
   return jsonb_build_object('boundary',p_boundary,'reused',true);
 end if;
 -- New writes: slot 1/2 must belong to current class.
 -- Legacy identical loadout replay remains valid above.
 select faction into v_faction from trpg_cards.card_catalog where card_id=p_asset;
 if v_faction<>v_class then raise exception 'slot1_requires_class_asset'; end if;
 select faction into v_faction from trpg_cards.card_catalog where card_id=p_enhancement;
 if v_faction<>v_class then raise exception 'slot2_requires_class_enhancement'; end if;
 if p_boundary<>'start' then
   select * into v_start from trpg_cards.loadouts
   where campaign_id=p_campaign_id and player_id=p_player_id and boundary_key='start';
   if not found then raise exception 'missing_initial_loadout'; end if;
   select kind into v_flex_start_a from trpg_cards.card_catalog where card_id=v_start.flex_a_card_id;
   select kind into v_flex_start_b from trpg_cards.card_catalog where card_id=v_start.flex_b_card_id;
   select kind into v_flex_new_a from trpg_cards.card_catalog where card_id=p_flex_a;
   select kind into v_flex_new_b from trpg_cards.card_catalog where card_id=p_flex_b;
   if p_asset<>v_start.asset_card_id or
    (v_flex_start_a='asset' and p_flex_a<>v_start.flex_a_card_id) or
    (v_flex_start_b='asset' and p_flex_b<>v_start.flex_b_card_id) or
    v_flex_start_a<>v_flex_new_a or v_flex_start_b<>v_flex_new_b
   then raise exception 'assets_and_flex_slot_types_locked'; end if;
 end if;
 insert into trpg_cards.loadouts(campaign_id,player_id,boundary_key,
   asset_card_id,enhancement_card_id,flex_a_card_id,flex_b_card_id)
 values(p_campaign_id,p_player_id,p_boundary,p_asset,p_enhancement,p_flex_a,p_flex_b);
 return jsonb_build_object('boundary',p_boundary,'asset',p_asset,'enhancement',p_enhancement,
   'flex_a',p_flex_a,'flex_b',p_flex_b,'reused',false);
end $function$
revoke all on all functions in schema trpg_cards from public, anon, authenticated;
alter default privileges in schema trpg_cards revoke execute on functions from public;
commit;
