# 대표 상황의 규칙 대조

검토일: 2026-10-29. 아래는 현재 문서의 절차·수치·참조를 읽고 대조한 결과다. AI 플레이 세션이나 외부 서버 실행 결과가 아니다. 자동 검사는 rulebook.py check가 수행하는 정적 검증과 validation-contract.json의 핵심 조건이다.

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 시작 설정 전체 유효, 원작 미지정 | 실제 작품 후보 A~F만 제시, PC/사건 생성은 선택 뒤 | START_SETTINGS_GATE / HOMAGE_DRAFT_SELECTION | 일치 |
| 2인 중 P1 생성만 끝남 | P2를 먼저 완료한 뒤 세계 생성 | SEQUENTIAL_PROFILE_GENERATION | 일치 |
| 원작에 자연스러운 PC의 과거 연결 | 세계 확정 전 선택적으로 반영, 다른 PC의 참여 경로도 확인 | WORLD_PC_INPUT | 일치 |
| PC가 사건을 추리한 뒤 정답 변경 | 확정 진실을 바꾸지 않고 실제 증거로 검증 | HIDDEN_TRUTH_ENGINE | 일치 |
| 세계 법칙 1개만 생성 | 최소 2개 요건 미달, 원작 테마에 맞는 별도 법칙 필요 | WORLD_RULE_HOMAGE_DNA | 일치 |
| 특성 [30,35,40,45,50,60,65,75], Luck 23 | 특성 합계400·범위·5단위 충족, Luck 별도. 다른 Draft와 같은 배열인지 추가 확인 | STAT_DRAFT_GENERATION | 일치 |
| DEX60이고 회피가 전문 기능 아님 | 회피30, MOV8 | PC_SKILL_START_VALUES / PC_DERIVED_STATS | 일치 |
| STR80+SIZ80 | DB +1d4, Build1 | DAMAGE_BONUS_AND_BUILD | 일치 |
| 기능55, 굴림11/27/28 | 각각 Extreme/Hard/Regular. 숨은 수치 없이 결과를 장면으로 출력 | SUCCESS_LEVELS | 일치 |
| 기능45, Hard 판정에서96 | 원래 수치50미만이므로 Fumble. 난이도에 따라 펌블 범위를 바꾸지 않음 | SUCCESS_LEVELS | 일치 |
| 보너스2·패널티1, 기본78·추가21 | 순수 보너스1, 동일 1의 자리8로 78/28 중28 | BONUS_PENALTY_DICE | 일치 |
| AI d6 큐가97,6으로 시작 | 97은 L96 초과로 소비·거부, 다음6을 써 결과6 | AI_DIE_MAPPING_VERSION | 일치 |
| PC 판정값 없이 성공 장면 요구 | 굴림을 요청하고 대기, AI 큐로 대신 굴리지 않음 | PLAYER_D100 / CORE_WORKFLOW | 일치 |
| HP11에서 단일6 피해 | 중상 조건 충족. 이후 의식/HP0 처리는 해당 조건에 따름 | HP_AND_DEATH / WOUNDS | 일치 |
| 중상 없는 PC의 HP0 | 즉사로 단정하지 않고 의식불명 | HP_AND_DEATH | 일치 |
| 단일 SAN5 손실 | 모든 PC가 일시적 광기 INT 검사 대상. 이름/직업으로4점 예외를 생성하지 않음 | INSANITY_CONDITIONS | 일치 |
| 한 PC가 독립 행동을 끝냈고 다른 PC가 대기 | 공정성 규칙으로 다음 PC 선정, 같은 응답에 새 PC 장면 선행 출력 금지 | SPOTLIGHT_FAIRNESS_COMMIT_GATE / NORMAL_HANDOFF_GATE | 일치 |
| Handoff A·이미지 B | 시간·Scene Turn·난수 정지, 저장된 대기 단계만 처리 | PLAYER_INPUT_NAMESPACE_ROUTER / VISUAL_CHOICE_GATE | 일치 |
| P1 단서를 P2가 아직 전달받지 않음 | 자동 공유하지 않음. 같은 채팅의 실제 접근 제어 한계도 명시 | CORE_VISIBILITY / PLAYER_SCENE_VISIBILITY | 일치 |
| Scene Turn30이 전투 진행 도중 도달 | 열린 절차 종료 후 첫 안전 경계에 periodic 저장 | STATE_CADENCE | 일치 |
| Turn29 수동 저장 후30 도달 | 다음 자동 주기는 밀리지 않음 | STATE_CADENCE | 일치 |
| 시간 생략으로30·60 기준선 모두 통과 | 같은 snapshot을 중복 저장하지 않고1회, 다음 기준선은 현재보다 큰30배수 | STATE_CADENCE | 일치 |
| pending 성공 뒤 verify 응답 유실 | 같은 version/event/exact 원문으로 최대1회 자동 재시도 | STATE_RECOVERY | 일치 |
| hash는 맞지만 NPC/증거 상태가 누락 | 의미 검증 실패로 복구 대기, 오래된 변화 상태로 임의 채우지 않음 | STATE_INTEGRITY / STATE_RESUME | 일치 |
| 새 채팅에서 수첩만 남아 있음 | 수첩으로 비공개 정본 복원 불가, verified history가 필요 | STATE_RESUME | 일치 |
| 연대기 챕터만 종료 | 전체 게임 종료/terminal 저장을 강제하지 않고 확정 결과로 다음 챕터 생성 | ENDING_FINALIZATION_GATE / STORY_SCALE | 일치 |
| 감시기 소유 P슬롯의 채팅 이동 | Keeper가 자동 쓰기로 복귀하지 않고 같은 수첩 재연결 확인 | NOTEBOOK_WATCHER_RUNTIME_SINGLE_WRITER | 일치 |
| 기존 DB가 삭제 필드를 필수로 요구 | 임의 값으로 우회하지 않고 실제 어댑터 호환 문제로 보고 | STATE_COMPATIBILITY | 일치 |

## 플레이 개선판 추가 대조

아래는 제공된 로그의 실패 유형과 새 규칙을 대조한 문서 검토다. 실제 모델의 게임 플레이나 20초 응답 성능 시험은 아니다.

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 인원 미정으로 시작 | 다른 누락 시작 설정과 함께 1~3명을 묻고 대기, 원작/PC/난수 생성 전 | START_SETTINGS_GATE / PARTICIPANT_COUNT_SETUP | 일치 |
| 0명·4명·소수 인원 입력 | 유효한 1/2/3 선택을 요청, 기본 2명으로 대체하지 않음 | PARTICIPANT_COUNT_SETUP | 일치 |
| 시작 설정 전체와 원작 확정, 1명 | P1만 생성, 빈 동료나 PC 인계 대기 없음 | PARTICIPANT_COUNT_SETUP | 일치 |
| 시작 설정 전체와 원작 확정, 3명 | P1/P2/P3 모두 생성 후 세계 생성, 실제 세 슬롯의 참여·정보·행동권 유지 | PARTICIPANT_COUNT_SETUP / CAMPAIGN_SETUP_PIPELINE | 일치 |
| 3인 저장을 새 채팅에서 로드 | 저장된 세 슬롯과 Focus를 복원, 인원 선택/세계를 새로 만들지 않음 | STATE_IDENTITY / STATE_RESUME | 일치 |
| 광고 납품·보수 수령 완료 | 첫 목적 완료 경계에서 실제 사건 접점과 다음 접근을 제시 | SCENE_PACING_GATE | 일치 |
| 30턴에 수상한 건물과 며칠 뒤 약속만 있음 | 사건 입구 제공 기준 미달, 구체적 충돌·이해관계·현재 접근이 필요 | SCENE_PACING_GATE | 일치 |
| PC가 사건에 대응할 기회를 알고 귀가 선택 | 감정·수락 강요 없이 기존 세계 결과를 처리, 새 봉쇄로 붙잡지 않음 | PC_INVOLVEMENT_COLLISION_GATE | 일치 |
| 이미 87턴인 기존 캠페인에 개선 적용 | 과거·진실을 바꾸지 않고 다음 안전 경계에서 현재 접점 복구 | SCENE_PACING_GATE | 일치 |
| 수리를 마친다고 선언, 새 위험/비용 없음 | 통상 공정을 묶고 한 목적의 결과·시간·합의된 정산을 한 번 적용 | CINEMATIC_ELLIPSIS | 일치 |
| 덮개만 연다고 명시 | 그 범위만 짧게 처리, 자동 수리/유료 부품 교체 없음 | CINEMATIC_ELLIPSIS | 일치 |
| 수리 중 새 비용 또는 위험 발견 | 해당 지점에서 멈춰 선택/판정을 돌림 | CINEMATIC_ELLIPSIS | 일치 |
| 장시간 수리 도중 세계 사건 도달 | 다른 PC의 동시간 선택과 가장 이른 중단 사건을 먼저 처리 | LONG_ACTION_EARLIEST_INTERRUPTION / PARALLEL_TIMELINE_SYNC | 일치 |
| NPC에게 새 정보가 생겨 먼저 연락할 이유·수단이 있음 | 초기 시각표에 없던 행동도 기존 목적·현재 조건으로 실행하고 기록 | WORLD_INITIATIVE_EXECUTION | 일치 |
| 최근 두 장면이 같은 무변화 확인만 반복 | 다음 안전 경계에 정체 점검, 자동 공격/새 정답 생성은 없음 | SCENE_PACING_GATE | 일치 |
| 동일 규칙 본문이 현재 대화에서 확인 가능 | 재조회 생략 가능, 컨텍스트 유실 시 원문 재조회 | TURN_RESPONSE_BUDGET | 일치 |
| 20초 목표와 필수 저장 검증이 충돌 | 검증을 끝내며 저장 턴의 시간은 별도로 측정 | TURN_RESPONSE_BUDGET / STATE_COMMIT | 일치 |
| 새 텍스트·이미지 프로필 생성 | 붙들고 있는 것·연기 참고 없음, 배우 외형과 태그는 유지 | FINAL_INVESTIGATOR_PROFILE_OUTPUT_CONTRACT / GOLD_START_PROFILE_REFERENCE | 일치 |

## 원작 체험·실패 대가 추가 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 작품명·복장만 다르고 사건의 작동·대응이 같음 | 원작 구현 실패, 확정 전에 실제 세계 ref·상호작용·결과를 다시 연결 | HOMAGE_SIGNATURE_FREEZE | 일치 |
| 원작의 핵심 설정을 확인할 수 없음 | 원작 사실을 꾸며내지 않고 생성 시 확인, 각색과 원작 근거 구분 | FULL_DIVE_CROSS_ANALYSIS | 일치 |
| PC가 실종 의뢰를 받고 조사하러 옴 | 이미 알고 온 사건·의뢰를 처음부터 제공, 생업 장면 강제 없음 | START_BRIEFING_FOG / INVESTIGATOR_INCIDENT_COUPLING | 일치 |
| 실패해도 보수만 못 받는 중심 사건 | 중대한 손실 요건 미달, 세계 확정 전 수정 | CAUSAL_ENDGAME_PRECOMMIT | 일치 |
| 중심 진실이 과거의 무서운 일화로만 끝남 | 현재 위협·피해와 개입 필요성이 없으면 생성 검토 실패 | HIDDEN_TRUTH_HORROR_PAYLOAD_GATE | 일치 |
| 흑막을 알아냈지만 실제 진행은 막지 않음 | 지식 획득과 위협 차단을 분리하고 조건에 따라 피해 진행 | CAUSAL_ENDGAME_PRECOMMIT / SCENARIO_CAUSAL_PROGRESS_MODEL | 일치 |
| 원작상 살해 불가능한 존재에 대응 | 봉쇄·지연·구조·격리·탈출 등 성립하는 대응 허용, 정면전 강제 없음 | CAUSAL_ENDGAME_PRECOMMIT | 일치 |
| PC는 탈출했으나 마을의 위협은 미해결 | 생존과 사건 해결을 분리, 실제 발생 손실과 잔존 위험을 보존 | NO_CLEAN_EXIT_HORROR_ARCHITECTURE | 일치 |
| 일부 주민을 구조하고 철수 | 구조 성과 인정, 미해결 부분의 실제 대가만 정산 | NO_CLEAN_EXIT_HORROR_ARCHITECTURE / ENDING_RESULT_VECTOR | 일치 |
| 모든 피해 원인을 막고 안전하게 떠남 | 무손실 성공 인정, 새로운 추격/납치나 자동 HP/SAN 차감 없음 | NO_CLEAN_EXIT_HORROR_ARCHITECTURE | 일치 |
| P1은 도주하고 P2는 아직 차단 가능 | P2의 유효한 행동을 처리한 뒤 실제 세계 결과로 판단 | ENDING_FINALIZATION_GATE | 일치 |
| 저장 후 재개, 미래 피해 조건은 아직 미충족 | 예정 위험을 확정 사망으로 바꾸지 않고 기존 실제 손실도 재적용하지 않음 | STATE_SCHEMA / STATE_INTEGRITY | 일치 |

## 플레이어 시작 설정 추가 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 새 게임 요청만 입력 | 시작 양식 전체 제시, 필수 입력 대기 중 웹 검색·생성 없음 | START_SETTINGS_GATE | 일치 |
| 인원 질문에 1만 답함 | 1인만 보존, 시드·인지도·규모 누락만 묻고 원작 대기 | START_SETTINGS_GATE / PLAYER_INPUT_NAMESPACE_ROUTER | 일치 |
| 여러 빈칸 양식 뒤 단독 2 | 대상 항목 확인, 여러 필드에 동시에 2를 적용하지 않음 | PLAYER_INPUT_NAMESPACE_ROUTER | 일치 |
| 시드 0/101/소수 또는 미입력 | 오류 항목만 재입력 요청, 키퍼 대체 난수 생성 없음 | START_SETTINGS_GATE | 일치 |
| 시드 두 개가 모두 1 또는 모두 100 | 각각 유효한 별도 입력으로 수용, 임의 중복 회피 없음 | START_SETTINGS_GATE | 일치 |
| 인지도·규모가 비어 있음 | 기본/사건으로 자동 채우지 않고 대기 | HOMAGE_TIER / STORY_SCALE | 일치 |
| 필수 5개만 입력, 선택 항목 생략/빈칸 | 선택 항목은 자동 없음, 추가 확인 없이 시드 기반 A~F 단계, PC는 원작 선택 후 생성, 사전 관계는 서로 모름 | START_SETTINGS_GATE / HOMAGE_DRAFT_SELECTION | 일치 |
| 배제 세계관 미입력/빈칸/없음 | 모두 추가 배제 없음으로 처리하고 추가 질문하지 않음 | START_SETTINGS_GATE | 일치 |
| 핵심 시드 25와 크툴루가 아닌 장르 직접 지정 | 직접 지정 장르 우선, 시드만으로 크툴루 강제 없음 | D100_PARADIGM_GENERATION / CTHULHU_OVERRIDE | 일치 |
| 직접 지정 작품이 배제 세계관과 충돌 | 조건 조정 질문 후 대기, 임의 대체/배제 삭제 없음 | START_SETTINGS_GATE | 일치 |
| 직접 원작은 지정했지만 필수 설정 미완성 | 나머지 입력 대기, 완료 후 후보를 생략하고 원작 확정 | START_SETTINGS_GATE / HOMAGE_DRAFT_SELECTION | 일치 |
| 저장된 캠페인을 새 채팅에서 재개 | 저장 설정·현재 단계를 복원, 새 시드/장르/초기 입력 강제 없음 | STATE_SCHEMA / STATE_RESUME | 일치 |
| 인지도만 보충하는 후속 답변에서 기존 배제 목록 생략 | 이미 지정한 배제는 유지, 생략을 선택 해제로 처리하지 않음 | START_SETTINGS_GATE | 일치 |

## 미실행

- 전체 새 캠페인 생성부터 실제 Supabase 저장·verify·exact load·새 채팅 복원.
- 2인 실제 장시간 플레이 및 모델의 조회 누락률 측정.
- 공개 수첩 API·감시기·이미지 업로드·사용자별 접근 제어.
- 실제 이미지 생성 및 첨부 예시 자산의 시각 일치 확인.

이번 세션에 해당 실행 도구/서버가 연결돼 있지 않으므로 문서 검증을 운영 성공으로 해석하지 않는다.
