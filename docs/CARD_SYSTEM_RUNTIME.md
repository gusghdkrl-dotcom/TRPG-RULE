# 영구 플레이어 ID·컬렉션·드래프트 Supabase 운영 계약 (2026-11-10)

> **실제로 설치된 백엔드**: Supabase 프로젝트 `trpg-state-v2` (ref `taoaffdyssqtnjszumpq`)의 **비공개 스키마 `trpg_cards`**. 기존 `public.gm_checkpoint_history`와 저장 RPC/실제 세계 상태는 수정하지 않는다. 설치 SQL 사본: [trpg-card-collection-v1.sql](sql/trpg-card-collection-v1.sql). 실제 연결 없는 임의 가상 값·성공 신고 금지.
>
> **인증 경계**: 닉네임은 플레이어 UUID를 조회하는 표시 이름이지 본인 인증 증명이 아니다. 현재는 키퍼의 **권한 있는 Supabase 연결만** 사용할 수 있고, `anon`/`authenticated` 역할은 `trpg_cards`의 사용·조회·RPC 실행 권한이 없다. 외부 사용자에게 닉네임만으로 접근하는 공개 API를 열지 않는다. 다중 사용자 대외 서비스에서는 신원 검증(예: 인증 계정/별도 소유 확인)을 추가하기 전까지 외부 자가 로그인을 제공하지 않는다.

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

키퍼는 사용자로부터 닉네임을 받아 권한 있는 Supabase 연결로 조회/등록한다. 닉네임은 2~24자, 양끝 공백 제거, 중복 불가. **기존 닉네임 사용은 같은 UUID를 재사용**한다. 단 외부인의 닉네임 사칭을 막는 인증 수단은 별도다.

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

- `trpg_cards`는 API 공개 스키마가 아니고 모든 테이블에 RLS 적용. `anon`, `authenticated`에 스키마 사용, 테이블 조회, 관련 함수 실행 권한 없음.
- 기존 게임 저장 테이블 `public.gm_checkpoint_history`나 `trpg_v2_*` 함수를 수정하지 않음.
- DB 트랜잭션 롤백 테스트: 닉네임 재연결, 기본18장, 4슬롯 장착, 신규PC 성장 적용, 기존 PC 비소급, 드래프트 최초 발행/선택 재시도, 성장 80% 성공/실패, 전체 소진 보상 없음 **통과**.
- 테스트 데이터는 **ROLLBACK** 처리했으므로 영구 플레이어/드래프트 기록을 남기지 않음.
- 현재 운영상 **선행 종결 검증과 Python RNG·후보 전달은 키퍼가 수행**해야 함. 함수가 미래의 경기 종결 이벤트를 알아서 감지하거나 자동 체크하는 백그라운드 서버는 아님.
- **검증이 추가로 필요한 영역**: 실전 신규 캠페인 엔드투엔드 시뮬레이션, 실제 Supabase 사용 연결이 끊겼을 때의 상태 복구, 동시 플레이어의 동일 닉네임 사칭 방지, 캠페인/챕터별 종결의 서버 자동 증명, 새 카드 추가 시 마이그레이션. 공개 서비스 전 별도 Auth/소유권 검증 필수.

## 6. 카드 규칙의 현재 확정 변경

- **일반 보너스 주사위와 강화 특수 보너스 주사위를 같은 판정에서 혼용할 수 없다.** 혼합 공식 미필요. 각자의 별도 처리 규칙은 기존 설계 유지.
- 카드는 원작 시대·세계관에 맞는 실물·훈련 동물로 구현. **새 무게·하중 규칙을 만들지 않는다.**
- 인간 인맥 자산 후보 「연구 협력자」·「뒷세계 연결책」은 **정식 카드 66장에 미포함**, 사용자 후속 결정까지 후보 보존.
