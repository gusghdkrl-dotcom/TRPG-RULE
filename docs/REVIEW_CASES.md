# 대표 상황의 규칙 대조

검토일: 2026-10-30. 아래는 현재 문서의 절차·수치·참조를 읽고 대조한 결과다. AI 플레이 세션이나 외부 서버 실행 결과가 아니다. 자동 검사는 rulebook.py check가 수행하는 정적 검증과 validation-contract.json의 핵심 조건이다.

## 통합 연출·서사 지침 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 극적인 장면을 위해 이미 성공한 회피를 실패로 바꾸려 함 | 키퍼의 실제 결과를 보존하고 연출/서술만 조정 | DIRECTOR_WRITER_KEEPER_CONVERGENCE 1·9 | 일치 |
| 의미 있는 평온한 교류·안전한 휴식 | 독립 장면 가치 인정, 사건/단서/공포 부채 강제 없음 | 통합 지침 2·4 / SAFE_INTERLUDE_AND_ENRICHMENT | 일치 |
| 현재 PC가 볼 수 없는 곳의 비밀 사건 | 세계에서는 진행하고 공개 경로 전 전지적 컷 삽입 없음 | 통합 지침 3 / CORE_VISIBILITY | 일치 |
| 클로즈업할 대상이 아직 열지 않은 서랍 안에 있음 | 자동 개봉/발견 성공 없이 실제 접근·판정 규칙 우선 | 통합 지침 현행 실행 연결 | 일치 |
| 소리로 긴장을 만들고 싶으나 실제 발생 원인이 없음 | 원인 없는 소리/움직임을 만들지 않음 | 통합 지침 3·4·5 | 일치 |
| 불안·서스펜스·충격·여파를 배치 | 실제 장면에 맞게 선택, 고정 순서/비율 없음 | 통합 지침 4 | 일치 |
| 풍부한 공포 묘사 중 실제 SAN 노출 발생 | 서술만으로 넘어가지 않고 해당 SAN 규칙 적용 | 통합 지침 4 / SAN_EXPOSURE_GATE | 일치 |
| 감각 묘사를 추가하는 일반 장면 | 적합한 1~2가지에 집중, 오감 체크리스트 나열 없음 | 통합 지침 5 / CINEMATIC_MISE_EN_SCENE | 일치 |
| 안전한 생활 장면을 묘사 | 채광·손때·생활 소음 등 실제 질감으로 표현, 보고서/억지 공포 방지 | 통합 지침 5 Positive Anchor | 일치 |
| 탐사·일상 대화·위기 장면이 이어짐 | 관찰 인과/자연스러운 대사/짧고 즉각적인 리듬을 구별 | 통합 지침 5 | 일치 |
| 같은 질문을 서로 다른 NPC에게 함 | 지식·직업·관계·목적에 따른 답변과 발화 이유, 고정 몸짓 반복 없음 | 통합 지침 6 / NPC_INTERACTION_VOICE_COMPACT | 일치 |
| PC가 질문을 선언했고 NPC가 새 제안을 함 | PC 질문은 직접 대사, 새 수락은 플레이어에게 반환 | 통합 지침 6 / NPC_REPLY_AGENCY_GATE | 일치 |
| 감정이나 자발적 뒷걸음질을 서술하고 싶음 | 미선언 내면/행동 대필 금지, 외부 자극·실제 물리 결과까지만 | 통합 지침 6 / CORE_AGENCY | 일치 |
| 같은 방에서 직접 대화가 계속됨 | 이전 변화에서 이어 쓰고 공간 도입을 매번 반복하지 않음 | 통합 지침 7 | 일치 |
| 긴장감 있는 컷 뒤 다음 PC로 전환 | 3/5회·안전 경계와 기존 A 인계 유지, 독립 두 장면 합성 없음 | 통합 지침 8 / NORMAL_HANDOFF_GATE | 일치 |
| 다른 PC가 공개한 단서와 실제 전력 차단 | 공통 지식/실제 인과 반영, 원격 직접 경험이나 PC별 FOG 생성 없음 | 통합 지침 8 / CORE_VISIBILITY | 일치 |
| 예상 밖 해결·실패·우회가 기존 세계에 영향 | 실제 결과 인정, 기존 namespace 보존, 나중 영향은 현재 물리 변화로 표현 | 통합 지침 9 | 일치 |
| 첫 발견과 소진 자료 재확인의 분량 | 전자는 확장 후자는 필요한 변화만, 900~1,600자 강제 채우기 없음 | 통합 지침 10 / TURN_RESPONSE_BUDGET | 일치 |
| 정상 행동권과 열린 판정 입력 | 마지막 선택 표면 정착, 정상 메뉴/자유행동과 전용 입력 계약 구분 | 통합 지침 11 / GUIDED_ACTION_RETURN | 일치 |
| 작성 품질을 확인 | 8개 기준을 한 응답의 작성 제약으로 사용, 추가 도구·점수·공개 평가 없음 | 통합 지침 12 / CORE_WORKFLOW | 일치 |
| 보정 예시를 읽었으나 실제 세계에 황동 열쇠/관리인이 없음 | 서술 방식만 참고, 예시 사물·손상·인물을 실제 정본에 추가하지 않음 | 통합 지침 13·현행 실행 연결 | 일치 |
| 기존 시작·외형·저장 상세가 인스트럭션에서 이동 | 해당 룰북의 원문과 라우팅으로 실행, 삭제/새 스키마/과거 결과 변경 없음 | instruction-relocation-2026-10-30.json | 일치 |

## 저장 경계 복기·NPC 응답 주도권 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 게임 시작 저장 시도 뒤 첫 장면 직전 | 성공 시 같은 verified 원문 재사용, 실패 시 현재 작업 상태 복기 후 첫 장면 진행 | STATE_CHECKPOINT_RECAP | 일치 |
| Scene Turn 30 도달, 판정이 아직 열림 | 기존 첫 안전 경계로 저장/복기 연기, 굴림을 중단하거나 대신 실행하지 않음 | STATE_CADENCE / STATE_CHECKPOINT_RECAP | 일치 |
| 30/60 기준선을 한 번에 넘긴 시간 생략 | 현재 전체 상태로 저장/복기 1회, 과거 턴별 스냅샷 생성 없음 | STATE_CHECKPOINT_RECAP | 일치 |
| 현재 장면 밖 NPC의 비밀·미발견 증거가 존재 | 전체 namespace/registry 대조에 포함, 현재 장면 요약만으로 대체하지 않음 | STATE_CHECKPOINT_RECAP | 일치 |
| 저장 verify와 read-back으로 전체 같은 version 원문 확보 | 같은 응답 재사용, 복기용 latest/list/full load 추가 없음 | STATE_COMMIT / STATE_CHECKPOINT_RECAP | 일치 |
| 읽기 응답은 성공이나 state 본문이 잘림 | 전체 복기 성공을 주장하지 않고 기존 검증/복구 경로로 누락 해소 | STATE_CHECKPOINT_RECAP | 일치 |
| 이미 처리한 숨은 사건·난수·SAN 결과가 복기 대상 | 읽고 대조만 함, 시간/난수/피해 재실행 없음 | STATE_CHECKPOINT_RECAP | 일치 |
| full snapshot을 복기하며 다음 조건 정리 | 미래 30턴 사건·PC 답변 선행 확정 없음, 원문 유지 | STATE_CHECKPOINT_RECAP | 일치 |
| 비공개 복기를 마친 공개 응답 | 비밀/예정 사건/난수 미출력, 실제 저장 성공/실패만 최소 안내 | STATE_CHECKPOINT_RECAP | 일치 |
| 일반 31~59턴, 필요한 규칙/작업 상태가 남음 | 관련 범위만 재사용, 전체 복기와 DB 조회 반복 없음 | STATE_WORKING_CONTEXT / STATE_ACCESS_ROUTER | 일치 |
| 저장 사이 필수 동적 상태가 유실됨 | 60턴까지 무조건 기다리거나 창작하지 않고 한정 복구 | STATE_CHECKPOINT_RECAP / STATE_ACCESS_ROUTER | 일치 |
| 새 채팅에서 verified 원문 복원 | 확보한 원문으로 같은 복기, 추가 저장/새 장면 재생성 없음 | STATE_RESUME | 일치 |
| 이동만 선언, 도착 후 NPC가 방문 목적을 물음 | 질문까지 묘사 후 PC 선택 반환, 자동 설명·절차 문의 없음 | NPC_REPLY_AGENCY_GATE | 일치 |
| 큰 목표는 일감 찾기, NPC가 점검 수락을 요구 | 큰 목표로 수락을 추정하지 않고 응답 대기 | NPC_REPLY_AGENCY_GATE | 일치 |
| 플레이어가 질문 문장을 직접 입력 | 실제 PC 직접 대사와 NPC 반응 재현, 간접 요약만 출력하지 않음 | CINEMATIC_ACTION_CONTINUITY | 일치 |
| 수리 의뢰가 있는지 묻는다고만 선언 | 선언한 문의를 직접 대사로 표현, 새 가격/능력 확약 없음 | CINEMATIC_ACTION_CONTINUITY | 일치 |
| 여러 집의 단순 거절 뒤 의미 있는 새 제안 | 반복 거절은 압축, 실제 PC 문의를 들려주고 새 제안에서 멈춤 | NPC_REPLY_AGENCY_GATE / CINEMATIC_ELLIPSIS | 일치 |
| 구체 질문/답변을 이미 선언했는데 NPC 인사 단계가 추가됨 | 이미 선언한 발화를 다시 입력받는 빈 절차 없이 재현, 새 질문만 대기 | NPC_REPLY_AGENCY_GATE | 일치 |
| 이동/침묵만 선언하고 별도 발화 없음 | PC 대사를 넣으려고 새 말/의도를 창작하지 않음 | CINEMATIC_ACTION_CONTINUITY | 일치 |
| NPC 질문 대기 중 저장·복기·다른 PC 인계 | 질문/원래 목적/미실행 범위 보존, 저장 성공이 수락이 되지 않음 | STATE_IDENTITY / NPC_REPLY_AGENCY_GATE | 일치 |

## 판정 조회·비공개 작업 상태 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 신문 합본에서 기록 탐색, 규칙/PC 시트/탐색 조건 모두 있음 | DB 조회 0회, 실제 난관이면 자료조사 요청 | INVESTIGATION_SKILL_ROUTING | 일치 |
| PC 시트/조건은 있지만 판정 규칙 본문만 없음 | 해당 룰북 절만 조회, DB로 규칙을 찾지 않음 | ACTIVE_PLAY_ROUTING_FIREWALL | 일치 |
| 과거 제도의 의미를 전문적으로 해석 | 역사 적용 검토, 단지 오래된 종이라는 이유로 기능 선택하지 않음 | INVESTIGATION_SKILL_ROUTING | 일치 |
| 찾은 읽을 수 있는 공고를 다시 읽음 | 찾기/역사 판정을 자동 추가하지 않고 같은 원문 제공 | INVESTIGATION_SKILL_ROUTING / IN_WORLD_DOCUMENT_HANDOUT | 일치 |
| 허락은 받았지만 관련 기록 탐색에 실제 난관 존재 | 접근과 탐색 분리, 시간만 충분하다고 무조건 성공 처리하지 않음 | FICTION_FIRST_ROLL_TRIGGER_GATE / INVESTIGATION_SKILL_ROUTING | 일치 |
| 자료조사 값 유실, 역사 값만 있음 | 역사 값을 복사하거나 유리한 기능으로 대체하지 않고 필요한 시트 값 복구 | INVESTIGATION_SKILL_ROUTING / STATE_ACCESS_ROUTER | 일치 |
| 판정 요청에 필요한 조건은 있고 성공 후 읽을 전문만 현재 없음 | 전문 복구를 선행 조건으로 만들지 않고 굴림 요청, 실제 읽을 때 복구 | INVESTIGATION_SKILL_ROUTING | 일치 |
| 판정 조건/실패 결과 자체를 결정할 핵심 상태가 없음 | 해당 범위부터 복구하고 의존하는 판정은 보류 | INVESTIGATION_SKILL_ROUTING | 일치 |
| 현재 NPC 목적·지식·관계가 이미 로드됨 | 비공개라는 이유로 DB 재조회하지 않고 인물답게 반응 | STATE_WORKING_CONTEXT | 일치 |
| 미발견 증거의 배치·발견 조건·원문이 이미 로드됨 | DB 없이 실제 발견 조건 처리, 발견 전 원문 공개 없음 | STATE_WORKING_CONTEXT | 일치 |
| 다른 장소의 Driver가 시간 경과 구간에 발동 | 현재 색인/상태로 결과 1회 반영, 현재 PC가 못 보면 비공개 유지 | WORLD_INITIATIVE_EXECUTION | 일치 |
| 세계 진행 색인이나 필요한 조건이 유실됨 | 사건 없음으로 간주하지 않고 필요한 범위 복구 | STATE_WORKING_CONTEXT | 일치 |
| Supabase에 저장됐지만 현재 모델 문맥에는 없는 사실 | 자동 인지를 주장하지 않고 현재 의존하는 값만 복구 | STATE_WORKING_CONTEXT | 일치 |
| 부분 조회 API는 없고 exact snapshot 로드만 지원 | 같은 snapshot 한 번에서 여러 필요한 값을 가져와 재사용 | STATE_ACCESS_ROUTER | 일치 |
| 저장본 이후 미저장 HP/시간/NPC 변경이 있음 | 오래된 snapshot으로 덮어쓰지 않음, 검증 불가능한 동적 누락은 보류 | STATE_WORKING_CONTEXT / STATE_INTEGRITY | 일치 |
| 현재 장면 요약만 남았는데 full checkpoint 저장 시점 | 원문+검증 가능한 변경분에서 전체 구성, 원격 세계/NPC 누락 금지 | STATE_WORKING_CONTEXT / STATE_COMMIT | 일치 |
| 판정 결과 처리와 30턴 저장 경계가 겹침 | 안전 경계에서 정상 저장 검증, 무조건 DB 0회로 생략하지 않음 | STATE_ACCESS_ROUTER / STATE_CADENCE | 일치 |
| 실제 비공개 실행 저장 공간이 없는 클라이언트 | 영구 비밀 메모리 보장을 하지 않고 공개 본문/수첩에 비밀 기록 금지 | STATE_WORKING_CONTEXT | 일치 |
| 사용자가 실시간으로 한 시간 채팅을 멈춤 | 현실 시간만으로 별도 세계 실행 스레드가 있다고 주장하지 않음 | STATE_WORKING_CONTEXT | 일치 |
| 오류 복구/속도 개선 명목의 checkpoint delete | 명시적 삭제 지시가 없으면 호출하지 않음 | STATE_ACCESS_ROUTER | 일치 |

## 기존 기능 대조

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
| 한 PC의 Spotlight 종료 조건이 성립하고 다른 PC가 대기 | 3회 목표·5회 상한과 실제 종료/긴급 조건으로 다음 PC 선정, 새 PC 장면 선행 출력 금지 | SPOTLIGHT_FAIRNESS_COMMIT_GATE / NORMAL_HANDOFF_GATE | 일치 |
| Handoff A·이미지 B | 시간·Scene Turn·난수 정지, 저장된 대기 단계만 처리 | PLAYER_INPUT_NAMESPACE_ROUTER / VISUAL_CHOICE_GATE | 일치 |
| P1 장면에서 단서 공개, P2는 다른 장소 | P2도 공통 지식으로 사용 가능, 전달 행동 불필요, 위치·물품은 별개 | CORE_VISIBILITY / PLAYER_SCENE_VISIBILITY | 일치 |
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
| 장시간 수리 도중 세계 사건 도달 | 실제 동기화 조건일 때만 동시간 선택 수집, 가장 이른 중단 사건 처리 | LONG_ACTION_EARLIEST_INTERRUPTION / PARALLEL_TIMELINE_SYNC | 일치 |
| NPC에게 새 정보가 생겨 먼저 연락할 이유·수단이 있음 | 초기 시각표에 없던 행동도 기존 목적·현재 조건으로 실행하고 기록 | WORLD_INITIATIVE_EXECUTION | 일치 |
| 최근 두 장면이 같은 무변화 확인만 반복 | 다음 안전 경계에 정체 점검, 자동 공격/새 정답 생성은 없음 | SCENE_PACING_GATE | 일치 |
| 동일 규칙 본문이 현재 대화에서 확인 가능 | 재조회 생략 가능, 컨텍스트 유실 시 원문 재조회 | TURN_RESPONSE_BUDGET | 일치 |
| 20초 목표와 필수 저장 검증이 충돌 | 저장 성공 판단의 검증은 유지하되 실패 시 플레이 계속, 저장 지연은 별도 측정 | TURN_RESPONSE_BUDGET / STATE_COMMIT | 일치 |
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

## APP·웹 참고·직업 대비 추가 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 기본정보 입력 완료, 특성 Draft 미선택 | 지정 외형만 보존하고 자동 배우/최종 얼굴은 APP 확정 뒤 완성 | BASIC_INFO_ACTOR_COMMIT | 일치 |
| 같은 생성 조건에서 APP35와 APP80 | 각 수치의 시각적 차이를 묘사하며 판정 보너스·강제 부상은 추가하지 않음 | PC_APPEARANCE_FROM_APP | 일치 |
| 플레이어가 배우·나이·얼굴 특징 지정 | 지정 요소 보존, 미정 세부에 APP 반영, 수치 재굴림 없음 | PC_APPEARANCE_FROM_APP | 일치 |
| 같은 PC의 프로필·장면·엔딩·새 채팅 그림 | APP를 반영한 동일 외형을 재사용하고 실제 부상/복장 변화만 반영 | CHARACTER_VISUAL_CANON | 일치 |
| 구판 PC의 배우·외형이 이미 확정됨 | 패치만으로 소급 미화/재선정하지 않음 | BASIC_INFO_ACTOR_COMMIT | 일치 |
| 낯선 직업·풍경·상황을 처음 설명 | 적합한 웹 자료를 출처·참고 표시와 함께 활용, 매 턴 검색하지 않음 | WEB_VISUAL_REFERENCE | 일치 |
| 참고 풍경 사진에 게임에 없는 문이 있음 | 실제 출입구/단서로 등록하지 않고 게임 정본을 유지 | WEB_VISUAL_REFERENCE / VISUALIZATION_CANON_BOUNDARY | 일치 |
| 검색/이미지 표시 도구가 없거나 적합한 결과 없음 | 텍스트를 이어가고 실제 확인된 링크만 안내, 이미지 제공 성공 가장 없음 | WEB_VISUAL_REFERENCE | 일치 |
| 정확한 PC 초상·현재 지도 요청 | 다른 인물 사진·일반 지도로 대체 완료하지 않음 | WEB_VISUAL_REFERENCE | 일치 |
| 기존 공개 직업 Draft/선택 PC에 패치 적용 | 조용히 재추첨하거나 직업을 변경하지 않음 | PROFESSION_SIX_CHOICE | 일치 |

## 사건 진행 상시 지침·HUD 문단 분리 대조

| 상황 | 기대 처리 | 담당 | 문서 대조 |
|---|---|---|---|
| 새 연출 지침 적용 후 첫 생활 목표를 마침 | 기존 인과의 사건 접점과 현재 접근 경로를 안전 경계에서 제시 | PROJECT_INSTRUCTIONS / SCENE_PACING_GATE | 일치 |
| 3인 캠페인 초반 30턴 도달 | 전체 Scene Turn 기준으로 이상·대응 이유·접근 경로 제공 여부 점검, PC별 30턴 아님 | SCENE_PACING_GATE | 일치 |
| 완결 장면 2개 연속 진전 없음 또는 할 일이 없다는 입력 | 다음 안전 경계에서 기존 NPC 목적·세계 결과로 정체 해소, 새 비밀/공격 발명 없음 | PROJECT_INSTRUCTIONS / SCENE_PACING_GATE | 일치 |
| 새 교류가 있는 평온한 장면 | 유효한 장면으로 유지, 불길한 사건을 기계적으로 추가하지 않음 | DIRECTOR_WRITER_KEEPER_CONVERGENCE / SCENE_PACING_GATE | 일치 |
| 17턴 이동 중 다른 장소의 예정 사건 시각 도달 | 해당 구간의 작업 상태로 결과 1회 처리, 30턴 저장까지 보류/매번 DB 조회 없음 | CORE_WORKFLOW / WORLD_INITIATIVE_EXECUTION | 일치 |
| PC가 위협의 실제 원인을 차단 | 갱신한 조건에 따라 취소·지연·재경로화, 기존 예정표만 보고 피해 강행 없음 | WORLD_INITIATIVE_EXECUTION | 일치 |
| 화면 밖 결과가 아직 파티에 도달하지 않음 | 비공개 상태만 갱신하고 지문·HUD에 누설하지 않음 | WORLD_INITIATIVE_EXECUTION / CORE_VISIBILITY | 일치 |
| 저장 복기·메타 입력·HUD 재표시 | 이미 처리한 사건·시간 재실행 없음, 현재 상태만 사용 | CORE_WORKFLOW / STATE_CHECKPOINT_RECAP | 일치 |
| 시각·위치·현금·상태 값이 모두 짧음 | 각각 고정 아이콘과 빈 줄을 가진 독립 문단 4개, 현금·상태 합치기 없음 | PROJECT_INSTRUCTIONS / HUD_VISUAL_STYLE | 일치 |
| 긴 메인 아이템과 짧은 파우치 | 같은 분류 내부만 구분점 사용, 메인/파우치는 아이콘을 가진 별도 문단 | HUD_VISUAL_STYLE | 일치 |
| 실제 직업품·키템이 있거나 없음 | 있으면 각각 독립 문단, 없으면 선택 행 생략, 예시 물품 생성 없음 | HUD_VISUAL_STYLE | 일치 |
| 표 미지원·좁은 화면·인계 대기 | 자원 3줄 및 모든 정보/가방 문단 분리 유지, 예약 PC 공개 값만 표시 | HUD_VISUAL_STYLE / BOTTOM_HUD_CONTRACT | 일치 |

## HUD 표시 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 일반 턴의 HUD 출력 | 응답 마지막에 현재 PC 하나, 이름/턴·자원표·시각/위치·현금/상태·소지품 표시 | BOTTOM_HUD_CONTRACT / HUD_VISUAL_STYLE | 일치 |
| 좁은 화면 또는 표 미지원 | HP/SAN/Luck을 라벨·정확한 수치와 함께 세 줄로 표시 | HUD_VISUAL_STYLE | 일치 |
| Luck35, 별도 최대치 없음 | 35만 표시, 가짜 분모·진척 막대 없음 | BOTTOM_HUD_CONTRACT / HUD_VISUAL_STYLE | 일치 |
| 실제 HP2 손실과 부상 확정 | 해당 PC 값에만 ↓2 가능, 실제 부상 표시, 자동 위험 등급 추가 없음 | HUD_VISUAL_STYLE | 일치 |
| 다른 PC로 인계 대기 또는 저장 로드 | 이전 PC 수치와의 차이를 변화량으로 쓰지 않고 예약·공개 범위 보존 | BOTTOM_HUD_CONTRACT / HUD_VISUAL_STYLE | 일치 |
| 메인 슬롯 일부 비었고 별도 키템 없음 | 실제 점유량·주요 도구만 표시, 빈 칸·키템 행 채우기 없음 | BOTTOM_HUD_CONTRACT / HUD_VISUAL_STYLE | 일치 |
| 시간·현금 등 필수 값 미확인 | 확인 필요 표시 후 기존 상태/복구 절차 적용, 예시 값 대입 없음 | HUD_VISUAL_STYLE | 일치 |
| HUD 외형 개선만 필요 | 기존 공개 상태로 서식 출력, 장식용 이미지·검색·DB 조회·새 저장 없음 | HUD_VISUAL_STYLE | 일치 |

## 조회·공통 지식·Spotlight 정정 대조

아래 시간·경로는 임의의 검토 조건이다. 실제 캠페인의 상태나 도구 실행 결과가 아니다.

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 같은 대화에 현재 상태·규칙 본문 있음, 독립적인 12분 이동, 저장 경계 아님 | 규칙/DB 재조회 없이 출발~도착 한 응답, 위치·시간·Turn 한 번 반영 | ROUTINE_MOVEMENT_FAST_PATH / STATE_ACCESS_ROUTER | 일치 |
| Spotlight 첫 이동으로 목적지 도착 | 같은 PC에게 문 두드리기 등 첫 상호작용 기회, 자동 인계 없음 | SPOTLIGHT_FAIRNESS_COMMIT_GATE | 일치 |
| 이미 본 문서·공개 지도·HUD 재표시 | 작업 상태 재사용, DB 조회/장식용 검색 없음, 재표시만으로 시간 진행 없음 | STATE_ACCESS_ROUTER / TURN_INCREMENT | 일치 |
| 새로운 판정의 예외 본문만 유실 | 필요한 규칙 ID만 조회, 게임 상태가 남아 있으면 DB load 불필요 | ACTIVE_PLAY_ROUTING_FIREWALL | 일치 |
| working 상태는 최신인데 verified 저장은 이전 위치 | 일반 조회로 과거 저장을 덮어쓰지 않음, 미저장 결과 유지 | STATE_ACCESS_ROUTER | 일치 |
| 새 채팅 또는 실제 현재 상태 유실 | verified 복원/복구 허용, 빈 상태를 추측 생성하지 않음 | STATE_ACCESS_ROUTER / STATE_RESUME | 일치 |
| 짧은 이동 결과 Scene Turn30 안전 경계 도달 | 일반 이동이어도 필수 저장·verify/read-back 실행 | STATE_ACCESS_ROUTER / STATE_CADENCE | 일치 |
| 저장 read-back이 exact-version load 조건 충족 | 같은 원문 재사용, 별도 동일 load 반복 없음 | STATE_COMMIT / STATE_ACCESS_ROUTER | 일치 |
| 저장 없는 테스트에서 연속 평범한 행동 | 원본 DB·수첩 쓰기 및 이유 없는 DB 대조 없음, 안내 반복 없음 | STATE_ACCESS_ROUTER | 일치 |
| P1이 공개한 단서, P2는 다른 장소 | P2도 판단에 사용, 전달·전화·합류 요구 없음 | CORE_VISIBILITY | 일치 |
| 공유된 단서는 미검증 전언·가설 | 출처/제안자와 불확실성 유지, 검증 결론으로 승격 없음 | PLAYER_SCENE_VISIBILITY | 일치 |
| 누구도 발견하지 않은 증거·NPC 비밀 | 파티 합집합에 포함하지 않음, 미발견 세계는 비공개 | CORE_VISIBILITY / EVIDENCE_NAMESPACE_CONSOLIDATION | 일치 |
| P1에게 있는 열쇠가 공통 지식이 됨 | P2 인벤토리에 생기지 않고 원격 사용도 불가 | CORE_VISIBILITY | 일치 |
| P1 직접 목격형 SAN 노출 | 원격 P2에게 목격 손실 복사 없음, 정보 노출은 실제 해당 조건일 때 별도 처리 | CORE_VISIBILITY | 일치 |
| 파티가 안 사실을 NPC가 듣지 못함 | NPC의 전지적 지식 갱신 없음 | DURABLE_STORY_CONTINUITY / CORE_VISIBILITY | 일치 |
| 같은 맥락에서 의미 있는 선택·결과 1~2회 | 현재 PC 계속 가능, 장소 변경/새 선택만으로 인계하지 않음 | SPOTLIGHT_FAIRNESS_COMMIT_GATE | 일치 |
| 3회 완료, 자연스러운 직접 결과 종료, 다른 PC 대기 | 가장 오래 기다린 eligible PC로 인계 | SPOTLIGHT_FAIRNESS_COMMIT_GATE | 일치 |
| 세 번째 결과가 이동 도착뿐 | 5회 상한 내에서 목적지 첫 상호작용 기회 뒤 인계 가능 | SPOTLIGHT_FAIRNESS_COMMIT_GATE | 일치 |
| 5회째 선언의 굴림/피해 처리 중 | 직접 결과까지 완료 후 인계, 여섯 번째 새 Normal 열지 않음 | SPOTLIGHT_FAIRNESS_COMMIT_GATE | 일치 |
| 굴림 입력 2개·메타·A 확인이 추가됨 | 같은 선언은 1회, 메타/A는 0회, 새 Turn도 중복 증가 없음 | SPOTLIGHT_FAIRNESS_COMMIT_GATE / TURN_INCREMENT | 일치 |
| 1회 만에 방문 목적 종료 또는 명시 패스 | 공허한 선택으로 3회 채우지 않고 일찍 인계 | SPOTLIGHT_FAIRNESS_COMMIT_GATE | 일치 |
| 3인 모두 대기 가능, 방금 P1 서비스 완료 | 오래 기다린 P2/P3부터 순서 배정, 의사 미제출만으로 제외하지 않음 | SPOTLIGHT_FAIRNESS_COMMIT_GATE | 일치 |
| 12분 이동인데 다른 PC의 대응이 4분 시점에 필요 | 짧아도 실제 동기화/중단 우선, 12분 전체 확정 금지 | PARALLEL_TIMELINE_SYNC / LONG_ACTION_EARLIEST_INTERRUPTION | 일치 |
| 통상 이동 15분/16분/25분, 다른 충돌 없음 | 시간 수치만으로 병렬 선언을 요구하지 않고 이동 완료, 다른 PC 행동 자동 실행 없음 | PARALLEL_TIMELINE_SYNC | 일치 |
| 같은 시간에 5분 작업·12분 이동을 이미 선언 | 첫 5분 뒤 이동 5/12분, 잔여7분만 처리, 총17분으로 합산하지 않음 | PARALLEL_TIMELINE_SYNC | 일치 |
| 대기 PC가 아무 작업도 선언하지 않은 짧은 독립 구간 | 세계 시간만 경과, 미선언 조사 성과·휴식 회복·소모 없음 | STANDBY_PC_NO_AUTOPILOT | 일치 |
| 저장/재개 시 Spotlight 4회 및 열린 판정 보존 | 횟수 초기화나 결과 재실행 없이 해당 단계로 재개 | STATE_IDENTITY / SPOTLIGHT_FAIRNESS_COMMIT_GATE | 일치 |
| 기존 개인 장면 기록이 있는 캠페인에 현행 패치 적용 | 실제 공개 사실만 공통 지식으로 사용, verified 원문/과거 결과 유지 | STATE_COMPATIBILITY | 일치 |

## 서술·자료·선택 UI·이동 연속성 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 첫 장소·중요 대화·공포 발견 | 충분한 감각·동작·대사로 장면화, 짧은 상태 보고로 대체하지 않음 | PLAYABLE_NARRATIVE_RENDERING / TURN_RESPONSE_BUDGET | 일치 |
| 플레이어가 직접 대사를 입력 | 의미·말투를 보존한 직접화법과 NPC의 실제 반응을 본문에 포함 | CINEMATIC_ACTION_CONTINUITY | 일치 |
| 승인 현황을 묻는다고 선언 | 해당 질문만 직접화법 가능, 추가 협박·약속·비밀 공개 없음 | CINEMATIC_ACTION_CONTINUITY | 일치 |
| 공장으로 돌아간다는 이동만 선언 | 도착과 현재 상황까지, 감독관에게 설명/질문한 것으로 처리하지 않음 | ROUTINE_MOVEMENT_FAST_PATH | 일치 |
| 정상 행동권을 돌려줌 | 번호·아이콘·대상 — 할 일 행과 4번 직접 행동 표시 | GUIDED_ACTION_RETURN | 일치 |
| 가능한 접근이 2개뿐 | 1/2와 4번만 표시 가능, 빈 선택을 새 사실로 채우지 않음 | GUIDED_ACTION_RETURN | 일치 |
| 열려 있는 d100 판정·A/B Gate | 전용 입력 우선, 일반 행동 메뉴를 동시에 붙이지 않음 | GUIDED_ACTION_RETURN / PLAYER_INPUT_NAMESPACE_ROUTER | 일치 |
| 승인 절차 알아보기 선택 | 표시한 문의 범위만 시도, 계약/결제/성공 자동 확정 없음 | GUIDED_ACTION_RETURN | 일치 |
| 두 기록의 인원 불일치 발견 | 각 본문에 실제 인원·대상·날짜/단위를 제시, 차이 요약만 하지 않음 | IN_WORLD_DOCUMENT_HANDOUT | 일치 |
| 짧은 공고 또는 접수증 읽기 | 실제 읽을 수 있는 전문 우선, 매체에 맞는 문체 사용 | IN_WORLD_DOCUMENT_HANDOUT | 일치 |
| 장부 일부만 읽었고 뒷면은 미확인 | 읽은 범위 발췌만 제공, 숨은 부분/손상 문자 창작 없음 | IN_WORLD_DOCUMENT_HANDOUT | 일치 |
| 같은 자료 재열람·새 채팅 복원 | 기존 evidence ref의 동일 원문·숫자·손상 범위 사용 | IN_WORLD_DOCUMENT_HANDOUT / STATE_SCHEMA | 일치 |
| 의미 조건만 고정되고 최초 문장은 미정 | 기존 의미·수량 관계 안에서 구체화 후 고정, 새 정답/사건 추가 없음 | IN_WORLD_DOCUMENT_HANDOUT | 일치 |
| 이미 정한 핵심 숫자가 현재 유실 | 새 숫자로 채우지 않고 필요한 상태 복구 | IN_WORLD_DOCUMENT_HANDOUT / STATE_ACCESS_ROUTER | 일치 |
| NPC에게 과거 사건을 질문 | 인물의 실제 경험·목적에 맞게 답변, 검증 안내/면책 논평 없음 | NPC_INTERACTION_VOICE_COMPACT | 일치 |
| NPC가 실제로 모르는 질문 | 짧고 자연스러운 무지 표현 가능, 모르는 사실 창작/자동 해설 없음 | NPC_INTERACTION_VOICE_COMPACT | 일치 |
| 플레이어가 근거·확정 여부를 메타로 질문 | 공개 근거 안에서 사실/가설/결론 구분 가능, 비공개 정답 대조 없음 | PLAYER_HYPOTHESIS_NARRATIVE_BOUNDARY | 일치 |
| 25분 통상 이동, 다른 선택과 실제 충돌 없음 | 이동 한 응답, 대기 PC에게 자료 재조사 강제/자동 실행 없음 | PARALLEL_TIMELINE_SYNC / STANDBY_PC_NO_AUTOPILOT | 일치 |
| 공유 차량 사용 순서 충돌 또는 다음 날까지 생략이 다른 PC 선택을 지움 | 실제 충돌 이유와 해당 선택만 수집, 시간 분 수가 단독 Trigger가 되지 않음 | PARALLEL_TIMELINE_SYNC | 일치 |
| 동시 선언을 실제로 받았고 두 PC 결과가 존재 | 시간은 중복 없이 추적, 한 본문에 다른 장소의 조사/이동 정산 장면을 섞지 않음 | PARALLEL_TIMELINE_SYNC / ACTIVE_POV | 일치 |
| 승인 미접수 사실을 이미 아는 상태로 같은 문의 반복 | 완료된 확인을 압축, 승인 조작 없이 실제 가능한 다른 접근/목적 제공 | CINEMATIC_ELLIPSIS | 일치 |
| 일반 채팅에 실제 클릭 버튼 기능 없음 | 번호 행 표시, 가짜 HTML/링크/클릭 성공 주장 없음 | GUIDED_ACTION_RETURN | 일치 |

## 미실행

- 전체 새 캠페인 생성부터 실제 Supabase 저장·verify·exact load·새 채팅 복원.
- 2인 실제 장시간 플레이 및 모델의 조회 누락률 측정.
- 공개 수첩 API·감시기·이미지 업로드·사용자별 접근 제어.
- 실제 이미지 생성 및 첨부 예시 자산의 시각 일치 확인.

이번 세션에 해당 실행 도구/서버가 연결돼 있지 않으므로 문서 검증을 운영 성공으로 해석하지 않는다.

## 직업 특별 배치 철회 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| A/B 모두 평범한 생업, C/D 모두 테마에 맞는 실무직 | 특별 역할 할당 없이 각 분류·업무 다양성으로 검증 | PROFESSION_SIX_CHOICE | 일치 |
| C/D가 원작 테마와 무관한 반대 직업 | 특별 배치 철회와 별개로 테마 연결 조건은 유지 | PROFESSION_MULTILAYER_GENERATOR | 일치 |
| 이미 공개된 왕/CEO 직업 또는 기존 PC | 패치 때문에 직업·권한을 소급 재생성하지 않음 | PROFESSION_SIX_CHOICE | 일치 |

## 생성 UI 고정 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 시작 설정 일부만 제출 | 실제 입력 UI에 기존 값을 보존하고 필수 누락만 요청 | SETUP_UI_FIXED_CONTRACT | 일치 |
| 원작 드래프트를 자유 산문으로 축약 | 같은 후보로 고정 A~F 두 줄 카드 재출력 | HOMAGE_DRAFT_PUBLIC_FORMAT | 일치 |
| 특성 표에 Luck 또는 EDU가 빠짐 | 같은 수치로 8특성·합계·Luck 표 복구, 재굴림 없음 | SETUP_UI_FIXED_CONTRACT | 일치 |
| 직업 화면에서 기능 점수 공개 | 기능명 7개만 남기고 확정값 자체는 보존 | PC_SKILL_START_VALUES | 일치 |
| 전문 분야 A와 중복 취미 제출 | A 보존, 취미만 재요청, 다음 PC로 넘어가지 않음 | SETUP_UI_FIXED_CONTRACT | 일치 |
| P2 생성 중 설명 질문·잘못된 문자·새 채팅 복귀 | 같은 P2 단계·후보·문자로 복귀, 다른 Gate의 A로 해석하지 않음 | SETUP_UI_FIXED_CONTRACT | 일치 |
| 세계 브리핑에 숨은 법칙 수·정답 표시 | 공개 배경 양식만 채우고 숨은 정보 제외 | START_BRIEFING_FOG / SETUP_UI_FIXED_CONTRACT | 일치 |
| 최종 카드 배부 | 필수 항목 한 코드 블록 후 기존 프로필 A/B만 표시, 첫 장면 미진행 | SETUP_UI_FIXED_CONTRACT | 일치 |
| Gold 참조 이미지가 현재 없음 | 명시된 블록 배치로 렌더링 명세 작성, 다른 카드 형식으로 대체 금지 | GOLD_START_PROFILE_REFERENCE | 일치 |
| P2의 직업·얼굴·초상 구도가 P1과 다름 | 콘텐츠·초상 구도만 변경하고 페이지 블록 배치는 유지 | GOLD_START_PROFILE_REFERENCE | 일치 |
| 생성 이미지에 수치 오류·필수 블록 누락 | 완료로 표시하지 않고 텍스트 정본 유지, 명시 요청 때만 재생성 | GOLD_START_PROFILE_REFERENCE | 일치 |

위 대조는 문서 계약 검토이며 실제 AI 응답·이미지 생성 준수율 측정이 아니다.

## 실제 입력 UI와 텍스트 양식 구분

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 실제 입력 UI 도구가 있는 환경 | 도구를 호출해 입력/선택 제출을 받음, 코드 블록 출력으로 대체하지 않음 | SETUP_UI_FIXED_CONTRACT | 일치 |
| 일반 ChatGPT 프로젝트에 입력 UI 도구가 제공되지 않음 | 미지원을 알리고 대기, 사용자 선택/직접 채팅 입력이 있으면 같은 검증으로 진행 | SETUP_UI_FIXED_CONTRACT | 일치 |
| 시작 설정 위젯의 기본 선택만 보이고 미제출 | 입력 완료로 취급하지 않으며 생성하지 않음 | SETUP_UI_FIXED_CONTRACT | 일치 |
| 도구 질문/선택지 수 제한 | 지원 스키마 안에서 같은 Gate의 항목 수집, A~F는 지원 자유 입력으로 유지 | SETUP_UI_FIXED_CONTRACT | 일치 |
| 이전 직업 선택 폼의 지연 제출이 전문 분야 단계에 도착 | 이전 Gate의 답으로 식별하고 현재 단계에 적용하지 않음 | SETUP_UI_FIXED_CONTRACT | 일치 |
| 입력 UI 지원 여부가 다른 채팅에서 확인됨 | 현재 게임 프로젝트에서도 제공된다고 추정하지 않음 | SETUP_UI_FIXED_CONTRACT | 일치 |

대상 일반 ChatGPT 프로젝트에서 실제 폼 렌더링·제출은 이 저장소의 문서 검사로 검증할 수 없다.

## 비공개 정본 조회·진행 세이브 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 신규 세계 생성 완료 | 정본 파일 제공 → 소스 업로드 후 실제 조회 → 지원 모드로 설정 저장 검증 | PRIVATE_CANON_DOCUMENT / CAMPAIGN_SETUP_PIPELINE | 일치 |
| NPC 비밀 목적이 문맥에서 누락 | 정확한 판본 NPC 절을 읽고 현재 목적·지식·생사를 적용 | PRIVATE_CANON_ACCESS_ROUTER | 일치 |
| 정본 NPC는 생존, 현재 세이브는 사망 | 사망 유지, 문서 재조회로 부활시키지 않음 | STATE_CANON_SAVE_BINDING | 일치 |
| 현재 사망 여부를 포함한 변경 맵 자체가 유실 | 변경 없음으로 간주하지 않고 동적 상태 복구 | STATE_CANON_SAVE_BINDING | 일치 |
| 단서가 원래 장소에서 이동·소모됨 | 원래 의미·본문은 문서, 현재 위치/존재는 세이브 변화 적용 | PRIVATE_CANON_ACCESS_ROUTER | 일치 |
| 발견 전 단서 조건/본문이 필요함 | 필요한 접근/발견 조건만 읽고 성공/공개 범위에 맞춰 본문 전달 | PRIVATE_CANON_ACCESS_ROUTER | 일치 |
| 플레이어 가설이 정본 진실과 다름 | 가설은 가설로 보존, 진실 재작성·답안 유출 없음 | PRIVATE_CANON_ACCESS_ROUTER | 일치 |
| 세계 법칙의 예외가 문맥에서 없음 | WORLD_RULES의 관련 절을 확인하고 현재 조건으로 적용 | PRIVATE_CANON_ACCESS_ROUTER | 일치 |
| 다른 장소 Driver의 발동 시각 도달 | 전체 활성 색인과 필요한 정본 조건을 대조, 취소/처리 event는 재실행하지 않음 | PRIVATE_CANON_ACCESS_ROUTER | 일치 |
| 새 NPC/자료 원문이 플레이 중 확정 | 세이브 추가 사실에 보존, 다음 문서 개정까지 누락하지 않음 | STATE_CANON_SAVE_BINDING | 일치 |
| 이전 저장에서 사망, 이번 저장에서 새 변화 없음 | 누적 변경 상태에 사망을 계속 보존, 직전 delta만 저장하지 않음 | STATE_CANON_SAVE_BINDING | 일치 |
| 새 채팅에 r2만 있는데 세이브는 r1 참조 | r1 요청, r2로 임의 대체/정본 재생성 금지 | STATE_RESUME | 일치 |
| 문서 파일명만 확인되고 본문 접근 실패 | 조회 완료 아님, 필요한 정확한 파일 조회 대기 | PRIVATE_CANON_DOCUMENT | 일치 |
| 같은 판본 ID에 다른 본문 | 충돌 보류, 최신 파일명/기억으로 덮어쓰기 금지 | PRIVATE_CANON_DOCUMENT | 일치 |
| 새 정본 r2 업로드 후 참조 세이브 검증 실패 | 기존 r1 참조·추가 사실·구판 파일 보존 | PRIVATE_CANON_DOCUMENT | 일치 |
| 서버가 정본 참조/축소 payload 미지원 | 신규 DB1은 저장 미완료로 진행, 전체 payload 자동 재전송/빈 anchor 검증 우회 없음 | STATE_CANON_SAVE_BINDING | 일치 |
| 기존 full 세이브 재개 | 소급 이관 없이 원래 계약으로 재개 | STATE_CANON_SAVE_BINDING | 일치 |
| 30턴 저장 복기 | 모드별 전체 범위 검사, 같은 정본/verified 진행 재사용, 불변 전문 자동 재조회 없음 | STATE_CHECKPOINT_RECAP | 일치 |
| GitHub 문서 결합 checkpoint만 복구됨 | 정확한 정본도 필요, 독립 전체 복원 성공으로 표시하지 않음 | STATE_CANON_SAVE_BINDING | 일치 |
| 정본 조회만 수행 | 시간·난수·저장·발견 상태 불변, 비공개 본문을 지문에 복사하지 않음 | PRIVATE_CANON_ACCESS_ROUTER | 일치 |

문서상 경로 대조이며 실제 Supabase 축소 저장/로드와 게임 프로젝트 소스 검색 성공을 뜻하지 않는다.

## 저장 실패 후 진행 대조

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| 신규 설정 완료, Supabase 연결 없음 | 저장 미완료 표시 후 게임 시작 입력 대기, 재개 승인 질문 없음 | CAMPAIGN_SETUP_PIPELINE / STATE_SAVE_FAILURE_CONTINUE | 일치 |
| play_start verify 실패, 현재 상태와 지도 있음 | 첫 장면 진행, 저장 성공 가장 없음 | STATE_SAVE_FAILURE_CONTINUE | 일치 |
| 30턴 저장과 GitHub 비상 저장 모두 실패 | 현재 상태로 계속, 다음 자동 시도 60턴, last_verified는 유지 | STATE_SAVE_FAILURE_CONTINUE | 일치 |
| 같은 장애가 31~59턴 지속 | 매 턴 재시도·실패 수락 질문·반복 경고 없음 | STATE_SAVE_FAILURE_CONTINUE | 일치 |
| 30턴 pending 후 40턴까지 진행, 이전 attempt 검증 성공 | 30턴 저장만 성공으로 기록, 40턴 현재 상태는 별도 저장, 되감기 없음 | STATE_SAVE_FAILURE_CONTINUE / STATE_COMMIT | 일치 |
| 저장된 pending 원문과 현재 상태가 달라짐 | 기존 version/event/hash는 동결하고 최신 상태와 구분 | STATE_SAVE_FAILURE_CONTINUE | 일치 |
| 서버의 다른 Writer/버전과 충돌 | 원격 덮어쓰기·자동 병합만 보류, 알려진 현재 작업 분기 플레이 계속 | STATE_SAVE_FAILURE_CONTINUE | 일치 |
| 수동 저장 실패 | 실패 결과 표시 후 원래 열린 선택/판정으로 복귀, 자동 주기 유지 | STATE_SAVE_FAILURE_CONTINUE | 일치 |
| terminal 저장 실패 | 후일담·종료 완결, 나중 재시도에서 보상/결과 재실행 없음 | ENDING_FINALIZATION_GATE | 일치 |
| 저장 read-back 일부 잘림, 최신 현재 상태는 있음 | 저장 검증 미완료, 현재 작업 상태로 복기·진행 | STATE_CHECKPOINT_RECAP | 일치 |
| 저장 실패 후 같은 채팅에 현재 데이터 있음 | 실패만으로 Resume/과거 저장 강제 로드 없음 | STATE_RESUME | 일치 |
| 새 채팅에서 미저장 HP/RNG/진행을 알 수 없음 | 값을 창작하지 않고 실제 복구 자료 확인, 미저장 복원 성공 가장 없음 | STATE_RESUME / STATE_SAVE_FAILURE_CONTINUE | 일치 |

문서 계약 대조이며 실제 서버 장애 주입 테스트는 아니다.

## 20턴 정본 실제 재독

| 상황 | 현재 규칙의 결과 | 확인 위치 | 대조 |
|---|---|---|---|
| Scene Turn 20, 열린 절차 없음 | 사용자 재독 요청 없이 활성 정본 전체 실제 조회·대조 | PRIVATE_CANON_PERIODIC_REVIEW | 일치 |
| Scene Turn 20에 굴림/Luck 대기 | 재독 예정 보존, 입력 해결 후 첫 안전 경계에 실행 | PRIVATE_CANON_PERIODIC_REVIEW | 일치 |
| 19턴에서 한 번에 45턴으로 이동 | 현재 시점 1회 재독, 다음 기준 60턴 | PRIVATE_CANON_PERIODIC_REVIEW | 일치 |
| 20턴 재독 완료, 저장 경계 아님 | Supabase commit/verify/full load를 추가하지 않음 | PRIVATE_CANON_PERIODIC_REVIEW | 일치 |
| 60턴 재독과 30배수 저장 복기 동시 도래 | 정본 읽기 1회 재사용, 저장 성공/재독 완료는 별도 판정 | PRIVATE_CANON_PERIODIC_REVIEW | 일치 |
| 60턴에 Supabase 저장 실패 | 소스 재독/작업 상태 대조 수행, 현재 플레이 계속 | PRIVATE_CANON_PERIODIC_REVIEW / STATE_SAVE_FAILURE_CONTINUE | 일치 |
| 정본 검색이 상위 3개 발췌만 반환 | 전체 완료 아님, manifest의 빠진 절/본문을 추가 조회 | PRIVATE_CANON_PERIODIC_REVIEW | 일치 |
| 일부 본문 잘림·파일 조회 실패 | 미완료와 누락 범위 유지, 다음 재시도 경계와 성공 상태 구분 | PRIVATE_CANON_PERIODIC_REVIEW | 일치 |
| 정본에 살아 있는 NPC가 현재 사망/단서가 이동함 | 현재 누적 변경 적용, 부활/원위치 복원/사건 재실행 없음 | PRIVATE_CANON_PERIODIC_REVIEW | 일치 |
| 새 채팅 37턴 로드·재독 기록 없음 | 활성 정본 전체 1회 읽기, 다음 40턴, 열린 단계 유지 | PRIVATE_CANON_PERIODIC_REVIEW / STATE_RESUME | 일치 |
| 같은 판본 요약은 있으나 40턴 정기 경계 도래 | 기억/요약만으로 생략하지 않고 새 소스 재독 | PRIVATE_CANON_PERIODIC_REVIEW | 일치 |
| 13턴에 당장 필요한 비밀 사실이 문맥에서 없음 | 20턴까지 기다리지 않고 관련 절 즉시 조회 | PRIVATE_CANON_ACCESS_ROUTER | 일치 |
| 기존 LEGACY_FULL 세이브에 별도 정본 파일 없음 | 실제 확보한 불변 원문 복기, 파일 소스 재독 성공 가장 없음 | PRIVATE_CANON_PERIODIC_REVIEW | 일치 |

이는 문서 계약의 경계 사례 대조다. 실제 게임에서 검색 도구가 본문 전체를 반환하는지나 장기 기억 유지율은 측정하지 않았다.


## 물리 정본+DB1 컴팩트 세이브 대표 사례

| 조건 | 기대 결과 |
|---|---|
| 정본 전체 SHA·필수 절·coverage와 실제 DB1 서버 분기 확인 | 최초 불변 원문 제외, canon_ref + 누적 동적 상태 저장·verify·exact read-back |
| DB1에 scenario_core·campaign_canon_text를 중복 포함 | DB semantic validator 거부 |
| DB1의 change_coverage.changed_entity_ids와 world_delta 키 불일치 | DB semantic validator 거부 |
| 정본 파일 누락/해시 불일치 | DB 원문이 정상이라도 복원 보류, 사실 생성/초기화 금지 |
| legacy verified 기존 세션 | 기존 검증·복원 유지, 원문·hash·history 불변 |
| 기존 세션 이관 요청 | 전체 원문/정본 비교 후 새 버전만 DB1 저장, 미확정이면 이관 보류 |
| DB1 서버 미지원·차단 | 저장 미완료 표시, 무단 LEGACY_FULL 재전송 없이 현재 채팅 계속 |

## 이번 씬 요약·결과

| 사례 | 기대 동작 | 담당 규칙 | 검토 |
|---|---|---|---|
| 첫 장면·일반 이동·대화 후 정상 메뉴 | 묘사 뒤 요약/결과 각 1~2문장, 행동 선택 바로 위 1회, HUD 마지막 | SCENE_SUMMARY_AND_RESULT | 일치 |
| 여러 턴 이어지는 장면 | 이번 응답 부분만 요약, Scene 종료/턴 증가/새 저장 이벤트 없음 | SCENE_SUMMARY_AND_RESULT | 일치 |
| NPC가 의뢰 수락이나 방문 목적을 질문 | 질문을 들은 결과와 답변 대기만 표시, PC의 수락/이동/지출 미확정 | SCENE_SUMMARY_AND_RESULT / NPC_REPLY_AGENCY_GATE | 일치 |
| NPC 전언·비공개 진실이 따로 존재 | 발언 출처 유지, 숨은 정답/속마음/미발견 사건/추리 결론 노출 없음 | SCENE_SUMMARY_AND_RESULT | 일치 |
| 변화 없는 재확인 또는 자원 변화 | 결과 창작 없음, 핵심 변화만 표시, 수치/가방 전체는 HUD | SCENE_SUMMARY_AND_RESULT | 일치 |
| 판정·전투·인계·화면 Gate 또는 메타 요청 | 기존 전용 입력 우선, 일반 메뉴 강제 추가 없음 | SCENE_SUMMARY_AND_RESULT / GUIDED_ACTION_RETURN | 일치 |
| Supabase 장애 중 일반 대화 | 현재 공개 상태로 요약, 추가 DB 호출/정본 재독/저장 의존 없음 | SCENE_SUMMARY_AND_RESULT | 일치 |
