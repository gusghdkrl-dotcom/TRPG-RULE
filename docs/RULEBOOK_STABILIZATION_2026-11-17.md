# 룰북 재점검·안정화 처리 기록 — 2026-11-17

사용자가 지정한 A/B 결정을 우선하고, 미언급 항목은 앞서 제안한 정리 방향으로 적용했다. B09/B15/B16/B18 및 A01의 다인 범위는 추가 답변까지 반영했다. 실행 규칙은 루트 지침·START_GAME·rules 10개가 정본이며 이 문서는 검토 이력이다.

작업 기준은 `main` f07399ff2eba4bf13e6e86542c60ee509a724f6f이다. 이 커밋의 실행 소스는 2447e73482eb4a160cfcc22f4ec6508e25d75cd8과 같고, `docs/rulebook-summary`는 당시 읽기 전용 요약이다. 기존 로컬 구판 작업 브랜치를 덮지 않고 최신 main 기반 별도 작업 트리에서 수정했다.

## A — 충돌 확정

| 항목 | 처리한 기준 | 담당 본문 |
|---|---|---|
| A01 | 원격 기여는 E 체험/완료로 인정하지 않음. 참가 PC 전원이 각 E 현장에서 직접 체험. 실제 통신/조작의 물리 효과는 사실대로 보존 | 04 PC_REACHED_EVENT_CONTRACT |
| A02 | 모든 E의 전원 현장 체험 뒤 최종 국면. 조기 성공 종결 없음. 최종 국면에서 E가 남으면 생성 실패 | 04 SCENARIO_BLUEPRINT, 06 ENDING_FINALIZATION_GATE |
| A03 | 플레이어에게 공개된 사실과 각 PC가 실제 아는 극중 지식을 구별 | 01 CORE_VISIBILITY, 05/07 연결부 |
| A04 | 장착 실물도 소지 칸 점유. HUD 두 표시는 같은 실물이며 수량/총 점유 이중 합산 금지 | 05 INVENTORY, 06 BOTTOM_HUD_CONTRACT |
| A05 | 직업 필수 시작품 1개와 장착 자산의 시작 1회 실물 지급을 구별 | 04 FINAL_INVESTIGATOR_PROFILE_OUTPUT_CONTRACT, 09 CARD_EQUIP_AND_ASSET |
| A06 | 희귀 초록·전설 주황. 클래스색과 희귀도색은 서로 다른 표시 | 04 SETUP_UI_FIXED_CONTRACT, 09 CARD_REWARD_DRAFT |
| A07 | 대사건 현지 PC의 영구 기능/특성 성장 없음과 플레이어 계정의 종결 영구 성장은 별개 | 02 SKILL_IMPROVEMENT, 09 CARD_PERMANENT_GROWTH |
| A08 | 본부 ON은 챕터 종료에도 기존 terminal_pre_finalization 저장 경계 사용. OFF 챕터만 종료와 구별 | 06 ENDING_FINALIZATION_GATE, 07 STATE_CADENCE |
| A09 | 전멸 실패에는 누구에게도 새 일반/특별 카드·성장 보상 없음. 이미 확정된 과거 보상은 유지 | 05 DEATH_AND_INHERITANCE, 09 CARD_REWARD_DRAFT |
| A10 | 본부 보상은 offer_general_reward/resolve_general_reward로 카드·HQ 원장을 함께 처리 | 09 CARD_PLAYER_STORAGE |
| A11 | 정의 없는 Focus 행동권 호출 제거. 도달한 위해/다인 교대의 실제 규칙으로 연결 | 03 COMBAT_ORDER, 05/06 담당 절 |

## B — 불명확한 경계

| 항목 | 처리한 기준 | 담당 본문 |
|---|---|---|
| B01 | 모든 비PC는 HP0 즉사. 의식불명/빈사 없음. HP가 있는 초자연 적도 동일하며 HP 없는 현상 억제와 구별 | 02 HP_AND_DEATH, 03 THREAT_TIERS |
| B02 | SAN0 순간 정신 붕괴·게임 오버. 사망과 같은 플레이 종료, 발작 2행동/회복으로 복귀 불가. 육체 사망을 날조하지 않음 | 03 SAN_CORE/BOUTS_OF_MADNESS |
| B03 | 01/100 특별 효과는 상황별 서술 재량. 고정 추가/최대 피해·자동 파손 없음 | 02 SUCCESS_LEVELS, 03 DAMAGE |
| B04 | 근접 대항 양측 실패는 명중/반격/기동 성취 없이 우스꽝스러운 장면. 동점 우세보다 먼저 적용. 비전투 일반 대항과 구별 | 03 MELEE_OPPOSED |
| B05 | 발사 작동 별도 판정 없이 정상 사격·명중 판정/탄약 소모. 재장전은 자기 차례 소모 | 03 FIREARMS |
| B06 | Dive for Cover는 성공/실패와 무관하게 다음 자기 차례 전체를 잃음. 다른 능동 행동으로 대체 불가 | 03 FIREARMS |
| B07 | 특수 보너스도 실제 패널티와 1:1 상쇄. 남은 modifier로 필요한 굴림 수/판정값 결정 | 09 CARD_ENHANCEMENT_TRIGGER |
| B08 | 특수 보너스 여러 장 동시 사용 금지. 일반 보너스와 특수 보너스 혼용도 기존대로 금지 | 09 CARD_ENHANCEMENT_TRIGGER |
| B09 | 적격 추가 피해 합산 → 실제 방호/경감 → 적격 HP1 생존 → 최종 피해 기준 중상/일격 즉사/HP0. 구체 수치 예시 포함 | 09 CARD_ENHANCEMENT_TRIGGER, 02/03 호출부 |
| B10 | 시작 현금·통화/최소 단위 반올림은 세계 재량으로 미리 확정해 일관 적용 | 04 CAMPAIGN_SETUP_PIPELINE, 09 카드 현금 안내 |
| B11 | 신규 예외 추가 안 함. 기존 훈련 자격 게이트 유지: 미인증자는 대사건 훈련, 전원 인증 팀만 연대기 준비 | 04 HQ_ON_CAMPAIGN_ROUTER, 기존 phase3c SQL |
| B12 | NPC 인계와 본부 재투입은 같은 1회 기능. 별도 부활/미정 연대기 치명 특성 생성 안 함 | 05 DEATH_AND_INHERITANCE |
| B13 | 경력/신입 혼합팀 가능. 실제 입단자만 절차 수행, 나머지는 휴게 대기. 청취·반응 자동 공유 없음 | 04 START_SETTINGS_GATE/HQ_ON_CAMPAIGN_ROUTER |
| B14 | 실제 최종 대응자의 진실 이해/실행이면 인정. 동료 전원 같은 지식·추리 발언 요구 안 함 | 04 FINAL_THREAT_DESIGN, 06 ENDING_FINALIZATION_GATE |
| B15 | 기존 runtime.hq 임무/구간·ending_state 귀환자·pcs.player_id/alive 및 최신 verified 참조를 안내. DB 스키마 변경 없음 | 07 STATE_CANON_SAVE_BINDING |
| B16 | 새 저장부터 기존 rules_version에 RULESET.json의 정확한 소스 SHA 배포 식별자 기록. 구판 문자열/원문/해시 그대로 보존 | 07 STATE_IDENTITY, scripts/rulebook.py export |
| B17 | 설정 시작·play_start·첫 재난 관측은 별개 시점. G의 불가역 발발과 PC 관측도 구별 | 04 CAMPAIGN_SETUP_PIPELINE, START_GAME, 06/07 연결부 |
| B18 | 모든 E 위기 발생 자체는 반드시 보장. 시작 정본의 독립 원인/예비 실행자로 준비하고 공격·피해 0 및 실제 사살/포획은 보존. 사후 발명 금지 | 04 SCENARIO_BLUEPRINT, 05 WORLD_INITIATIVE_EXECUTION |

특수 보너스를 실제 판정 전에 선택해 사용한 1회 권리는 상쇄되어도 소비하며, 후보가 하나면 같은 값으로 본 행동/연동 강화를 판정한다. 별도 카드 d100·재추첨은 없다. 이는 B07/B08을 실제 판정 순서로 풀어 쓴 운영 기준이다.

신규 PC 인계는 실제 살아 있고 접근 가능한 동행 NPC와 플레이어 선택으로만 성립한다. 인계 뒤 현재 PC identity/상태를 잇고 전 인물의 과거 종료·경험을 보존한다. 새 인물에게 과거 E 체험/지식을 복제하거나 이미 처리한 E를 재연하지 않는다.

## C — 중복의 단일 담당 정리

| 항목 | 통합 방식 |
|---|---|
| C01 | 세계 설계 본문은 04 SCENARIO_BLUEPRINT. START_GAME은 실제 시작 입력과 호출 순서, 07 PRIVATE_CANON_DOCUMENT는 기록 위치/원문 검증만 담당 |
| C02 | 생성 요구와 COMPATIBILITY_GATE의 실패 반례를 분리. 각 절에 전체 설계 목록을 다시 복사하지 않음 |
| C03 | 첫 폼/외부→입장→제이든의 실제 화면은 START_GAME, 마틴 면담·본부 전체 루프는 04, 현지 엔딩 출력은 06. 입단·귀환·평가·보상 호출 지점을 연결 |
| C04 | HP0·치료 수치는 02, SAN0는 03. 05는 인계/플레이 종료, 06은 행동권/종결, 07은 실제 구조/생사 저장 맥락만 담당 |
| C05 | NPC 준비는 04, 개체/개성은 05 STORY_NPC, 동의/기밀은 NPC_AGENDA_AND_SECRECY, 독립 실행은 NPC_AGENDA_INTERVENTION, 대사/청취는 NPC_INTERACTION_VOICE_COMPACT, 관계의 기억은 RELATIONSHIP_AND_NPC_MEMORY |
| C06 | 정본 수납은 PRIVATE_CANON_DOCUMENT, 동적 JSON 계약은 STATE_CANON_SAVE_BINDING, 전체 보존 범위는 STATE_SCHEMA, 현재 필요한 작업 맥락은 STATE_WORKING_CONTEXT. 같은 거대 목록 반복 축소 |
| C07 | UI/색상·도감은 04, 장착 자격/실물·카드66장/성장8종·발동/보상/원장은 09. START/엔딩의 독자 카드 엔진 지시를 담당 절 참조로 교체 |
| C08 | 신규 생성의 폐기 기능 호출과 정의 없는 참조를 정리. 구판 기록/별칭·비소급 설명은 STATE_COMPATIBILITY에 보존하고 색인/목차의 상충 요약을 현재 담당 참조로 교체 |

규칙 ID 180개와 403개 원본 블록/361개 이전 ID의 기존 이관 연결을 보존했다. 카드 66개 ID와 개별 카드 본문(NE-E-7 화폐 반올림은 B10으로 명확화), 성장8종·확률/상한, 공식 PNG 8장은 별도로 원본 대조했다. 문장 축약만으로 기능 보존을 입증했다고 간주하지 않으며 실제 AI 실행 품질은 실전 검증 대상이다.

## D — 잔존 자료·배포

| 항목 | 처리 |
|---|---|
| D01 | README 현재 판·HP+2·HUD·저장 경계 갱신. 이전 표제/수치 설명은 docs/archive의 명시적 이력으로 분리 |
| D02 | STATE_FLOW 30배수 → 현행 40배수, ON 챕터 terminal 저장/정확한 판본 안내 연결 |
| D03 | HUD_PREVIEW를 실제 고정 행 순서로 갱신. 상시 카드4칸·구판2열·의료품2개 예시 제거 |
| D04 | ZIP에 없는 docs/scripts 필수 실행 참조 제거. 필요한 본부 함수·저장/보상·NPC8명 설정을 게임 소스 안에 수납. 관련 개발 가이드는 작성 당시 이력이라고 표시 |
| D05 | 구판 ZIP을 dist/archive/TRPG-RULE-rules-instructions-start-LEGACY.zip으로 바이트 그대로 이동. 최신 고정 다운로드 URL 유지 |
| D06 | 기존 심층 계약의 부재 START_GAME 앵커 2개를 포함해 변경된 중복/구판 문구 앵커를 담당 절의 현재 의미로 이관 |
| D07 | 기존 mutation 테스트의 이미 없던 대상 3개를 포함한 구판/중복 fixture를 정리하고 신규 확정 규칙의 부정 사례로 대체 |

`docs/rulebook-summary`는 기존 요약 스냅샷으로 보존하고 현재 실행 소스와 혼합하지 않도록 표시했다. 기존 세이브·비공개 정본·운영 SQL·카드 계정·별도 공개 승인 SCREAM 패키지는 수정하지 않았다.

## 실행 문서 분량

12개 실행 문서는 327,882자에서 220,016자로 약 32.9% 줄었다. 프로젝트 지침은 공백/줄바꿈 포함 7,787자로 7,800자 제한 이내다. 이는 중복 축약 수치이며 실전 응답 속도나 기억 품질의 실측이 아니다.

## 검증과 한계

- `rulebook.py check` 및 `deep-check`: 규칙180개·기존 이관403/361·링크/색인·지침 길이·의미 가드180그룹 통과.
- `test_rulebook_contract.py`: 현재 문서 baseline 및 문서 훼손 부정 사례328개 거절로 통과. 구판 중복 mutation 254개를 현재 담당 절 mutation 150개로 대체했으며, 그대로 유효한 기존 fixture는 보존했다. 상세 이전/새 담당은 STABILIZATION_VALIDATION_MIGRATION.json 참조. 텍스트 검사는 AI 플레이 성공 증명이 아니다.
- `test_four_layer_scenarios.py`: 합성 경로29개 허용/38개 거절. 1~3인·ON/OFF·전원 E 현장 체험 전 최종 진입 거절·원격 체험 거절·E 위기 발생과 국지 공격 차단 분리·실제 전달/선택적 생활/재개를 대조했다.
- `test_resume_semantics.py`: 합성 저장 문맥 보존/손실 반례34개 통과. 운영 저장/로드는 호출하지 않았다.
- `check_hq_release_contract.py`: HQ SQL21개 소스의 정적 계약 통과. 운영 설치/API 성공을 재확인한 것이 아니다.
- `rulebook.py export`: 공식 PNG8장의 SHA 확인 후 최신 ZIP 생성. 실행 소스12개·RULESET.json·전체 SHA256.json을 ZIP 바이트와 대조한다. 구판 ZIP은 이동 전후 SHA 동일함을 확인한다.
- 운영 DB 쓰기/SQL 마이그레이션, 실제 비공개 캠페인 생성/플레이·출격/귀환/보상·장기 새 채팅 복원은 **미실행/미검증**이다. 실제 연결에서 기존 계약이 거절되면 성공을 꾸미거나 권한/스키마를 우회하지 않는다.
