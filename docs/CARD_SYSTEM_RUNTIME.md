# 영구 플레이어 ID·컬렉션·드래프트 Supabase 운영 계약 (2026-11-10)

> **실제 카드의 능력·수치·발동 원문 정본은 [rules/09-cards.md](../rules/09-cards.md)이다.** 본 문서는 닉네임/UUID·저장·보상 API 호출과 실제 도구/접속 조건만 다룬다.

> **실제로 설치된 백엔드**: Supabase 프로젝트 `trpg-state-v2` (ref `taoaffdyssqtnjszumpq`)의 **비공개 스키마 `trpg_cards`**. 기존 `public.gm_checkpoint_history`와 저장 RPC/실제 세계 상태는 수정하지 않는다. 설치 SQL 사본: [trpg-card-collection-v1.sql](sql/trpg-card-collection-v1.sql). 익명 닉네임 접속용 추가 SQL: [trpg-card-nickname-public-v1.sql](sql/trpg-card-nickname-public-v1.sql). 실제 연결 없는 임의 가상 값·성공 신고 금지.
>
> **닉네임만 사용하는 신뢰 운영 [사용자 명시 승인]**: 2~3명의 소규모 지인용으로 **로그인·비밀번호 없이 닉네임 입력만으로 플레이어 UUID에 접속**한다. `public.card_login` 등 지정한 7개 RPC는 `anon`/`authenticated`에서 호출 가능하다. **닉네임을 아는 누구나 그 사람의 카드 계정을 열람하거나 장착·보상 선택을 대신할 수 있다**는 사칭 위험을 사용자가 수용했다. 대신 원본 `trpg_cards` 테이블의 직접 쓰기·대량 삭제와 **`public.gm_checkpoint_history` 및 원래 게임 세이브 RPC**는 열지 않았다. 익명 카드 API는 의도적인 보안 완화이며 인터넷 공개 인증 서비스가 아니다.

## 닉네임만 사용하는 공개 API (로그인·비밀번호 없음)

기존 카드 시스템과 세계/GM 상태를 구분한다. 별도 사용자 계정 인증은 없으며 **익명 Supabase publishable key를 사용하는 클라이언트**가 다음 `public` RPC를 호출한다. 이 키는 일반 앱 공개 연결용이지 소유자 인증키가 아니다.

| 공개 RPC | 닉네임으로 가능한 동작 |
|---|---|
| `card_login(p_nickname)` | 새 닉네임 UUID 생성·기본18 지급 또는 기존 동일 UUID 조회; 보유 카드·성장·캠페인 반환 |
| `card_lookup(p_nickname)` | 존재 여부·현재 컬렉션 조회, 없으면 새로 만들지 않음 |
| `card_join(p_nickname,p_campaign_id,p_class,p_mode,p_session_id)` | 캠페인 생성/기존 확인·참가·클래스 고정 |
| `card_link_pc(p_nickname,p_campaign_id,p_pc_id,p_base_stats)` | 새 PC 연결 시 누적 성장 적용·스냅샷 고정 |
| `card_equip(p_nickname,p_campaign_id,p_boundary,p_asset,p_enhancement,p_flex_a,p_flex_b)` | 소유·클래스·장착 슬롯·고정 경계 검사 후 장착 |
| `card_rewards(p_nickname,p_campaign_id)` | 미소유 후보 풀 및 이미 발행된 드래프트 조회 |
| `card_pick_reward(p_nickname,p_campaign_id,p_event_key,p_choice,p_python_roll)` | **이미 키퍼가 정당하게 발행한** 보상에 대해 한 옵션만 선택·저장 |

예: `select public.card_login('나의닉네임');`. 실제 앱에서는 POST `/rest/v1/rpc/card_login`에 `{"p_nickname":"나의닉네임"}` 형식으로 요청한다. **테이블 전체 SELECT/UPDATE/DELETE는 익명 권한에 포함되지 않는다.**

**신뢰 모델 주의:** 닉네임을 기억하는 다른 사람이 `card_login`·`card_equip`·`card_pick_reward`를 대신 부를 수 있다. 성장 선택의 `p_python_roll` 값도 퍼블릭 경로에서는 서버가 Python 원본을 재검증하지 못한다. 약속한 소규모 운영 이외의 계정 분리·공정성 보안은 제공하지 않는다는 뜻이다.

## 1. 서버에 생성된 객체

| 종류 | DB 객체 | 의미 |
|---|---|---|
| 플레이어 ID | `trpg_cards.players` | UUID PK, 대소문자·양끝 공백 정규화된 중복 불가 닉네임 |
| 카드 정의 | `trpg_cards.card_catalog` | 확정된 66장: 자산 33 + 강화 33, 기본18/해금48 |
| 영구 소유 | `trpg_cards.owned_cards` | (player_id,card_id) 고유, 신규 등록 시 기본18 자동 소유 |
| 영구 성장 | `trpg_cards.growth_levels` | 8종 각 Lv.1~5 |
| 캠페인 | `trpg_cards.campaigns` | major/chronicle, 캠페인 ID |
| 참여자 | `trpg_cards.campaign_members` | 캠페인별 플레이어 UUID·고정 클래스 |
| PC 연결 | `trpg_cards.character_links` | 영구 플레이어와 PC 식별자를 연결한 순간 성장 스냅샷 및 적용된 8대 특성 |
| 장착 | `trpg_cards.loadouts` | 자산전용 1+강화전용 1+자유 2, 경계별 불변 기록 |
| 보상 | `trpg_cards.drafts` | 캠페인/종결 이벤트/플레이어별 단 한 보상, 4슬롯과 최종 결과 |

동일 소유 카드 재지급은 PK로 차단. 기존 PC 및 정본의 비공개 인물/세계 정보와 별도이며, **PC의 인벤토리·HP·SAN 자체를 이 컬렉션 DB에 중복 저장하지 않는다.**

## 2. 게임 시작: 닉네임 연결 → 클래스 → PC

닉네임은 2~24자, 양끝 공백 제거, 중복 불가. **같은 닉네임을 입력하면 별도 확인 없이 같은 UUID로 접속**한다. 소유자 검증·비밀번호·OTP를 요구하지 않는다. 키퍼는 권한 있는 연결로 기존 비공개 함수도 사용할 수 있지만, 닉네임 사용자 본인은 로그인 없는 아래 공개 RPC로 접속 가능하다.

```sql
-- 신규면 UUID 생성 및 기본 18장 최초 지급, 기존이면 같은 UUID/소유 상태 조회
select trpg_cards.register_player('플레이어닉네임');

-- 캠페인 준비 완료 후 (실제 campaign_id/session_id 사용)
select trpg_cards.open_campaign('campaign-실제ID','major','session-실제ID');
select trpg_cards.enroll_player('campaign-실제ID','실제-플레이어-UUID'::uuid,'guardian');

-- PC 8대 기본 특성 확정 뒤 연결: 현재 플레이어 성장 레벨을 이 PC에 한 번 적용
select trpg_cards.link_character(
 'campaign-실제ID','실제-플레이어-UUID'::uuid,'실제-PC-identity',
 '{"STR":60,"CON":55,"SIZ":50,"DEX":50,"APP":50,"INT":50,"POW":50,"EDU":50}'::jsonb
);
```

위 SQL의 이름·식별자는 **예시**다. 실제로 존재하는 캠페인/PC/UUID만 사용한다. `link_character` 결과의 `applied_stats`를 해당 PC의 생성 시트에 반영하고 **같은 PC 재조회 시 이전 스냅샷을 그대로 반환**한다. 나중에 보상으로 플레이어 성장 레벨이 올라가도 이미 연결된 PC에게 자동 소급 적용하지 않는다. 후임 PC가 새 identity로 연결되면 최신 성장을 반영한다. 캐릭터 간 기억·물건·사적 관계 상속 없음.

## 3. 장착 저장

```sql
select trpg_cards.save_loadout(
 'campaign-실제ID','실제-플레이어-UUID'::uuid,'start',
 'GU-A-0','GU-E-0','NE-A-0','NE-E-0'
);
```

카드 네 장은 모두 본인 소유이며 현재 캠페인 클래스 또는 중립이어야 한다. 자산 전용·강화 전용 슬롯을 확인하며, 중복 장착 금지. **대사건**은 시작 장착 후 변경 불가. **연대기**는 실제 챕터 경계에서만 `boundary_key='chapter:챕터식별자'`로 새 장착을 저장할 수 있고, **자산 및 자유 슬롯의 자산/강화 유형을 고정**하며 강화만 교체한다. 사용자는 언제든 슬롯에 맞는 소유 카드를 선택할 수 있지만, 신규 보상을 얻은 것만으로 캠페인 도중 실물 자산을 자동 지급하지 않는다.

장착의 실물 소지 슬롯·지급·소모·파손·동물 생사는 해당 캠페인의 **기존 게임 상태**에서 처리한다. UUID 영구 소유와 PC 실물은 동일하지 않다.

## 4. 종결 보상: 후보 풀 조회 → Python 추첨 → 기록 → 선택

**필수 선행**: 담당 `06-play` 종결/챕터 조건에 따라 실제 종결 여부 및 해당 플레이어의 보상 권리를 확정하고, 기존 상태 저장의 정확한 `event_id`를 확인한다. `issue_draft`는 전달된 `source_event_id`를 기록하지만 그 참조가 실제 verified 상태의 종결임을 서버가 자동 인증하지는 않는다. **키퍼가 실제 완료·기존 verified 상태와 대조**해야 하며, 임의의 이벤트 키로 무단 보상 생성 금지.

1. **대사건** 종결 식별자는 `final`, **연대기**는 `chapter:<고유 챕터 ID>`. 동일 이벤트에 대한 보상은 player별 정확히 한 번.
2. `select trpg_cards.draft_pool('campaign-실제ID','UUID'::uuid);`로 실시간 미소유 풀 확인. 결과 `current`, `all`, `growth`, `neutral`.
3. 이 JSON을 `python3 scripts/card_draft_rng.py`의 표준 입력에 전달. **Python `secrets.SystemRandom`의 실제 난수**만 사용. 1번·2번은 등급 30:15:5 (정규화 60:30:10), 남은 등급에 따라 재정규화; 2번은 1번의 카드 중복 제외. 3번은 미달 성장 8종에서 균등, 4번은 미보유 중립 8장에서 균등. 결과 `offers`와 RNG 감사 데이터를 현재 작업 상태에 유지.
4. 실제 제공될 네 후보를 DB에 기록한다. 예시:
   ```sql
   select trpg_cards.issue_draft(
      'campaign-실제ID','실제-플레이어-UUID'::uuid,'final','실제-종결-event-id',
      '{"current":"GU-A-1","all":"SE-A-1","growth":"STR","neutral":"NE-A-4"}'::jsonb
   );
   ```
   DB가 **각 슬롯의 소유·클래스·성장 제한/중복 조건**을 검증한다. **풀이 비었다면 해당 옵션은 JSON null**; 남은 카드가 있는데 null로 숨기는 것은 거절. 같은 event 재발행은 최초 후보를 그대로 반환하여 reroll 금지. 미선택 네 후보는 획득되지 않는다.
5. 사용자에게 1~4 중 하나의 선택을 받고 **확정된 선택만** 기록한다:
   ```sql
   -- 카드 선택. 세 번째 인자는 event_key, 네 번째는 선택 슬롯. roll 미사용
   select trpg_cards.resolve_draft('campaign-실제ID','실제-플레이어-UUID'::uuid,'final',1::smallint,null);
   -- 성장 처음 획득: Lv.1 확정. Python roll 불필요
   select trpg_cards.resolve_draft('campaign-실제ID','실제-플레이어-UUID'::uuid,'final',3::smallint,null);
   -- 성장 Lv.1~4: Python --growth-roll로 생성한 실제 정수 1..100을 마지막 인자에 전달
   ```
   **주의:** 위 세 호출은 서로 다른 예시이며 **실제 같은 event에 여러 번 보상을 지급하라는 뜻이 아님**. `resolve_draft`는 첫 정상 선택만 실행하고 같은 선택 재호출은 이미 저장한 결과를 반환하며, 다른 선택으로 변경하려 하면 거절한다.

**성장 확률**: 첫 획득 100%, Lv.1→2 80%, Lv.2→3 50%, Lv.3→4 25%, Lv.4→5 10%. 실패해도 보상은 소모되며 레벨은 그대로다. **성장용 1~100 난수는 PC d100이 아닌 Python 시스템 난수**다.

**풀 소진**: 특정 후보군 소진 시 그 슬롯은 null; 네 후보 전부 없으면 `exhausted` 기록으로 보상 종료. 나중에 카드가 추가돼도 지나간 event의 보상을 소급 지급하지 않는다.

## 5. 보안·운영 테스트 결과

- `trpg_cards` 원본 스키마는 비공개이고 모든 테이블에 RLS 적용. `anon`, `authenticated`가 원본 스키마/테이블 및 비공개 함수에 직접 접근하지는 못한다. 대신 **지정한 `public.card_*` 7개 보안 검증 함수**는 익명 호출 허용.
- 기존 게임 저장 테이블 `public.gm_checkpoint_history`나 `trpg_v2_*` 함수를 수정하지 않음.
- DB 트랜잭션 롤백 테스트: 닉네임 재연결, 기본18장, 4슬롯 장착, 신규PC 성장 적용, 기존 PC 비소급, 드래프트 최초 발행/선택 재시도, 성장 80% 성공/실패, 전체 소진 보상 없음 **통과**.
- 테스트 데이터는 **ROLLBACK** 처리했으므로 영구 플레이어/드래프트 기록을 남기지 않음.
- 현재 운영상 **선행 종결 검증과 Python RNG·후보 발행은 키퍼가 수행**해야 함. 이미 발행한 보상은 익명 닉네임 사용자가 `public.card_pick_reward`로 선택할 수 있다. 성장 Lv.1 이후의 `p_python_roll` 값은 **키퍼가 실제 Python에서 생성해 전달해야 하며**, 사용자가 가짜 숫자를 내면 DB 자체는 구별하지 못한다. 이는 로그인 생략을 허용한 소규모 신뢰 운영의 약점이다. 함수가 미래 경기 종결 이벤트를 자동 감지하지는 않는다.
- **검증이 추가로 필요한 영역**: 실전 신규 캠페인 전체 흐름, HTTP API 클라이언트에서 실제 닉네임 UX, 연결 장애 복구, 캠페인/챕터 종결의 서버 자동 증명, 새 카드 업데이트. **닉네임 사칭 방지는 의도적으로 제외**했으므로 플레이어 2~3명 외에 URL/닉네임이 알려지면 제삼자 접속이 가능하다.

## 6. 카드 규칙의 현재 확정 변경

- Hard/Extreme은 일반 난이도·대항 및 장착한 강화 카드의 명시적 발동 조건으로만 사용한다. 성공 단계만으로 자동 추가 보상·근접 피해를 지급하지 않는다. 카드 66종·소유/성장·실제 DB/RPC는 이번 게임 규칙 패치로 바꾸지 않는다.
- **일반 보너스 주사위와 강화 특수 보너스 주사위를 같은 판정에서 혼용할 수 없다.** 혼합 공식 미필요. 각자의 별도 처리 규칙은 기존 설계 유지.
- 카드는 원작 시대·세계관에 맞는 실물·훈련 동물로 구현. **새 무게·하중 규칙을 만들지 않는다.**
- 인간 인맥 자산 후보 「연구 협력자」·「뒷세계 연결책」은 **정식 카드 66장에 미포함**, 사용자 후속 결정까지 후보 보존.
