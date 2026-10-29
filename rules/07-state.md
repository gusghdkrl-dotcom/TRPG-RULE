# 비공개 상태·저장·복원

규칙판: 플레이 개선판 2026-10-29. 규칙 ID는 버전과 독립적으로 유지한다. 필요한 절만 조회한다. 전체 경로는 `00-index.md`를 따른다.

## STATE_AUTHORITY

비공개 GM_STATE는 세계·인물·PC·난수·진행 절차의 작업 상태다. 매 일반 턴 실제 결과를 반영하고, [STATE_CADENCE](07-state.md#state_cadence)의 경계에서 전체 상태를 저장한다.
- 문서에 지정된 운영 대상은 Supabase `trpg-private-state-db` / project ref `mwopllxdhxcykwyxuyrd`, 정본은 `public.gm_checkpoint_history`의 verified 전체 `state_json`이다. `public.gm_sessions`는 최신 미러이며 복원 정본이 아니다.
- 첫 연결 또는 대상·권한·계약이 실제 바뀐 경우 Supabase의 프로젝트·함수 계약을 읽기 전용으로 확인하고 같은 대화에서 재사용한다. 일반 턴의 접근 여부는 STATE_ACCESS_ROUTER를 따른다. 문서의 이름만으로 연결이나 저장 성공을 주장하지 않는다.
- 문서상 함수는 `public.trpg_manual_checkpoint_commit`, `trpg_manual_checkpoint_verify`, `trpg_manual_checkpoint_load_version`, `trpg_manual_checkpoint_load`, `trpg_manual_checkpoint_list`, `trpg_manual_checkpoint_delete`다. 접두사만 같은 다른 함수·스키마로 추측 전송하지 않는다.
- 인증된 기존 커넥터를 사용한다. 비밀 키를 채팅에 출력하지 않는다. 무인증 경로·권한 해제·공개 수첩으로 대체하지 않는다.
- 웹훅·외부 큐·이미지·수첩 저장은 게임 정본을 대신하지 않는다. 보조 전송 실패는 이미 검증된 Checkpoint의 성공을 취소하지 않는다.
- 커넥터가 없거나 정확한 저장 계약을 확인할 수 없으면 `게임 정본 저장 검증 대기`로 표시한다. 현재 확정 상태를 재생성하지 않는다.

## STATE_ACCESS_ROUTER

Supabase는 영속 저장·복구 경계에서 접근한다. **일반 응답의 기본값은 DB 조회 0회**다. 현재 작업 상태를 읽고 실제 결과를 갱신하는 것은 DB 호출이 아니다.

| 실제 조건 | 허용되는 접근 |
|---|---|
| 새 채팅 재개·명시적 로드 | STATE_RESUME으로 해당 session의 verified 전체 상태를 한 번 복원 |
| 현재 작업 상태 일부 유실·출처 충돌·손상 | 필요한 exact version/범위만 확인하고 STATE_INTEGRITY/STATE_RECOVERY 적용 |
| STATE_CADENCE 저장 경계 또는 명시적 저장 | 최신 parent·버전 충돌 확인, commit/verify/exact read-back 등 STATE_COMMIT의 필수 접근 |
| pending/verify/read-back 실패·실제 버전 불일치 | 같은 attempt의 상태 확인과 한정된 복구 |
| 사용자가 DB와의 대조·저장 목록을 명시 요청 | 요청한 session/범위만 읽고 현재 미저장 진행과 구분 |
| 첫 저장 연결 또는 연결 대상/권한/계약의 실제 변경 | 대상·함수 계약을 확인하고 같은 조건에서는 확인 결과 재사용 |

- 이동·대화·자료 재확인·PC 전환·Handoff `A`·HUD·지도 열람만으로 조회하지 않는다. 단순 턴 증가, 같은 경로 재사용, 비공개 세계가 있다는 이유도 조회 조건이 아니다. 문서의 '현재 상태 확인'·'세계 진행 검사'는 먼저 대화에서 유지되는 작업 상태를 뜻한다.
- 같은 대화의 작업 상태는 실제 로드/생성한 정본에 이후 확정 결과를 반영한 것이다. 오래된 verified snapshot으로 미저장 HP·시간·위치·난수를 덮어쓰지 않는다. 정확한 상태가 없으면 추측하거나 새로 생성하지 말고 영향을 받는 변경만 보류해 복구한다.
- 매 응답 latest/list/full load·스키마 탐색·parent 대조를 반복하지 않는다. 부모 검증은 저장 경계에서 수행한다. 같은 응답/attempt의 같은 version·같은 원문을 이미 얻었으면 재사용하고, commit read-back이 exact load 요건을 충족하면 두 번 조회하지 않는다.
- 필요한 여러 필드는 실제 지원되는 한 호출로 묶고 관련 없는 session·과거 전체를 읽지 않는다. DB 호출을 하지 않았다고 미검증 상태를 '저장 완료'로 표시하지 않는다.
- 사용자가 명시한 저장 없는 테스트는 첫 복원 이후 작업 분기만 갱신한다. 위의 실제 복구/대조 조건이 없으면 원본 DB 재조회도 하지 않는다. DB·수첩 쓰기 중지 안내는 테스트 시작/종료·상태 변경/요청 때만 표시하고 매 지문에 반복하지 않는다. 테스트를 임의 시작하거나 테스트 결과를 나중에 원본에 자동 덮어쓰지 않는다.

## STATE_SCHEMA

다음은 full snapshot에 포함해야 할 의미상의 범위다. 실제 필드 경로·허용 스키마 버전은 연결된 저장 계약을 따른다. 이 목록은 임의 DB 테이블이나 새 필수 컬럼을 만드는 지시가 아니다.
| 범위 | 보존할 사실 |
|---|---|
| 식별·순서 | 플레이어 시작 설정 원문·해석값·미응답·질문 대상·설정 단계, session, version/event, 현재 규칙판, phase, active chapter, 종료 상태 |
| 불변 세계 | 원작 특징과 실제 세계 ref의 연결, 중심 위협의 조건부 손실·차단 인과, 시나리오 핵심, 비공개 진실, 세계 법칙, 증거의 원래 배치, 종결 조건, 확정 지도 |
| 변화하는 세계 | 실제 발생/방지/잔존/진행 중인 중대 손실과 그 근거, 현재 시각, 장소/경로 상태, NPC 위치·지식·목적·일정, 위협/환경 결과, 기관 접근, 소유권, 작업, 약속, 되돌릴 수 없는 결과 |
| PC | 확정 참가 인원(1~3명)·실제 참가 슬롯, stable PC identity와 P슬롯 연결, 확정 과거/APP와 반영 외형/직업/전문 분야 및 실제 지위·권한·책임, 특성·기능, HP/SAN/Luck·부상/광기, 현금·소지품·위치, 참여 연결 |
| 지식·조사 | 발견자·시점·출처를 보존한 파티 공통 공개 사실, 증거 ref, 제안자가 있는 플레이어 가설, 검증/모순·시간 순서·결론, 진행/미해결 질문 |
| 난수 | 플레이어가 확정한 핵심 시드/world_seed·시작 시드/start_seed와 실제 적용 방식, gameplay queue 순서·소비 상태·매핑 버전, 생성 named seed와 확정 결과 |
| 진행 대기 | 판정 원값/요청 단계, Luck 선택, 전투/추격 순서, 광기, 중단된 작업, Focus/POV, 현재 Spotlight의 의미 있는 선택·결과 횟수/시작 시각·최근 서비스 순서, 필요한 병렬 시간 구간·수집한 선언, Handoff/Reaction/Visual 대기와 행동 메뉴 |
| 공개 투영 | player_map_state, 실제 전달된 프로필·첫 장면 상태, 이미지 asset ref가 실제 존재할 때의 연결, 수첩 연결·단일 Writer |
| 저장 무결성 | 불변 Canon Anchor, critical registry, manifest, parent/version/hash, cadence와 미완료 attempt |
- 신규 설정은 필수 인원·시드·인지도·규모 입력과 선택 항목의 실제 입력 또는 미입력으로 적용한 `없음`을 구분해 보존한다. 선택 항목의 `없음`은 미응답 대기가 아니다. 같은 의미의 기존 필드를 사용한다. 새 채팅에서 복원할 때 비어 있는 항목을 새 기본값으로 채우거나 새 장르/시드를 뽑지 않는다. 구판 저장에는 해당 판의 호환 원칙을 적용한다.
- 신규 게임은 삭제한 자원·모드의 상태를 생성하지 않는다. 과거 저장의 필드를 조용히 지우지 않는 호환 원칙은 [STATE_COMPATIBILITY](07-state.md#state_compatibility)에 있다.
- 구조화 상태가 계산의 정본이다. 공개 HUD·그림·요약·수첩은 투영이며 상태의 대체본이 아니다. HUD에 표시하지 않았다는 이유로 실제 사실을 삭제하지 않는다.
- 실패/방치 결과는 기존 Threat/Driver/Objective/종결 기록에 보존하고 PC 연결·지식은 해당 정본을 참조한다. 조건부 미래 피해를 확정 사망/파괴와 혼합하지 않는다. 재개 시 이미 발생한 손실을 되돌리거나 같은 손실을 재적용하지 않는다. 새 DB 컬럼이나 별도 공포 게이지를 만들라는 지시가 아니다.
- 이미 있는 상태를 기관 평판 점수·압력 점수·허브 점수 등으로 중복 저장하지 않는다. 관계/권한은 실제 행위·약속·가능 범위를 기록한다.

## STATE_IDENTITY

P1/P2/P3는 참가 슬롯이고 PC identity는 인물 식별자다. 같은 슬롯에 새 PC가 들어오면 새 identity를 만든다. 과거 PC의 개인 과거·시트·이미지 정체성을 새 PC에 자동 상속하지 않는다. 파티에 이미 공개된 사실은 새 PC도 공통 지식으로 참조할 수 있다.
- `investigator_dna_by_pc`는 공개 과거·현재 목적의 정본, character tags는 객관적 인물 태그다. 감정·가설을 키퍼가 추가하지 않는다.
- 공개 사실의 발견자·시점·출처를 보존하며 PC별 열람 차단은 만들지 않는다. 기존 scene_visibility/authorized slots는 과거 전달 이력으로만 남길 수 있다. NPC 지식은 실제 얻은 사실만 기록한다.
- `first_scene_orientation_by_pc`는 실제 첫 장면 설명이 전달된 뒤에만 delivered다. 메타 선택이나 Resume만으로 전달 완료 처리하지 않는다.
- Spotlight의 시작 시각·의도·선언·직접 결과·의미 있는 선택 횟수·분기 대기·최근 서비스 순서와 action_menu_pending의 선택지/소유 PC/장면/공개 사실 ref를 보존한다. PC 전환 전후의 대기 예산은 저장/로드로 초기화하지 않는다. 병렬 정산은 대상 시간 구간과 이미 받은 선언을 보존해 재질문하지 않는다. 숫자 선택은 그 당시 메뉴의 같은 선택으로 해석한다.
- PC 연결은 세계 생성 시의 실제 근거·일상 목적·이해관계·현재 접근 경로, 실제 첫 충돌/접근 기회의 전달 여부와 대응 결과를 보존한다. 기존 thread·PC 지식·scene 기록을 재사용하며 초반 전달 점검용 중복 시계를 만들지 않는다. 비밀 답 자체를 연결 요약에 복제하지 않는다.

## STATE_INTEGRITY

실제 저장 경계에서 현재 full snapshot을 최신 semantic-valid verified parent와 비교한다. 일반 지문마다 DB parent를 조회하는 절차가 아니다. 대화 요약을 parent로 간주하지 않는다.
1. 식별자·버전·현재 단계·PC identity·난수·진행 대기·지도·증거·세계 상태가 재개 가능한가 확인한다. 신규 1~3인 게임은 참가 인원과 실제 슬롯/PC 연결 수가 일치하고 Focus/인계가 존재하는 슬롯을 가리키는지 검사한다.
2. 불변 세계/PC 사실과 Canon Anchor가 설명 없이 변경·누락·null로 회귀하지 않았는지 확인한다. 변화하는 상태는 실제 사건·소비·이동·선택으로 변화 이유가 설명돼야 한다. 발생한 손실·방지한 결과·진행 중인 위험이 혼합되거나 도주/종결 때문에 사라지지 않았는지도 확인한다.
3. `critical_state_registry`에는 실제 생성되어 활성인 핵심 namespace와 경로/ref를 등록한다. `checkpoint_canon_manifest`와 실제 데이터가 일치해야 한다. 빈 이름만 나열한 manifest는 검증이 아니다.
4. 불변 정본이 단순 누락됐다면 동일 scope의 verified parent/ancestor에서 exact 값만 복구할 수 있다. 현재 NPC 목적·세계 진행·위치·난수·진행 대기처럼 변하는 상태를 오래된 값으로 메우지 않는다.
5. full state와 anchor가 충돌하거나 설명할 수 없는 상태 손실이 있으면 `checkpoint_canon_recovery_required`로 멈춘다. 새 진실·동기·단서·과거를 창작해 검사를 통과시키지 않는다.
Canon Anchor:
- `campaign_canon_text`: 캠페인 불변 원작 특징/연대기 틀.
- `chapter_canon_text_by_ref`: 각 확정 Chapter Core 원문. 새 챕터는 새 ref로 추가한다.
- `pc_canon_text_by_identity`: 배부된 최종 프로필 원문. 현재 슬롯의 pointer와 인물 원문을 구분한다.
Anchor는 손실 검출/복구 비교용이며 구조화 상태를 이중 계산하지 않는다. 매 턴 전문을 재출력하지 않는다. 기존 저장에 anchor가 없으면 [STATE_COMPATIBILITY](07-state.md#state_compatibility)를 따른다.

## STATE_CADENCE

자동 저장은 네 종류다. 명시적 수동 저장은 별도다.
| 종류 | 실행 경계 |
|---|---|
| setup_bootstrap | 전원 PC·세계·연결·지도·정본이 완성된 뒤 게임 시작 입력 대기를 열기 전, 첫 verified version 1회 |
| play_start | 게임 시작 선언, phase=play/scene_turn=1, 시작 지도 실제 전달 뒤 첫 장면 전 1회 |
| periodic_scene_turn | Scene Turn 30/60/90… 기준선에 도달하거나 넘긴 뒤 열린 절차가 끝난 첫 안전 경계 |
| terminal_pre_finalization | 전체 캠페인/연대기 종결 결과·event id 확정 뒤 종료를 완결하기 전 1회. 챕터 종료만으로 실행하지 않음 |
| manual | 저장·세이브·채팅 이동 전 저장 등 사용자의 명시적 요청. 자동 주기를 초기화하지 않음 |
- cadence에는 각 최초/종료 저장 status, next_scene_turn, last_verified_version, deferred_reason을 보존한다.
- 하나의 시간 생략으로 여러 기준선을 넘으면 현재 full state를 한 번 저장하고 next_scene_turn을 현재보다 큰 다음 30배수로 옮긴다.
- 자동 저장은 전투·추격·굴림/Luck 선택·광기·Handoff/Reaction/Visual·장기 행동의 열린 절차를 끊지 않는다. 첫 안전 경계로 연기한다. 수동 저장은 열린 단계까지 정확하게 보존해 재개할 수 있어야 한다.
- 전투·피해·단서·장소 이동·회차 종료·이미지·수첩 변경 자체는 추가 자동 저장 조건이 아니다.
- 실패하면 current working state를 유지한다. 초기/시작/종료 검증 완료를 가장하지 않는다. periodic 복구까지 실패하면 다음 독립 플레이 상태 변경 전에 저장 복구를 완료한다.
- 저장은 턴·시간·난수·세계 상태를 진행시키지 않는다.

## STATE_COMMIT

캠페인당 Single Writer를 유지한다. 동일 요청을 다시 받아도 같은 저장 attempt를 완결한다.
1. [STATE_INTEGRITY](07-state.md#state_integrity) 검사를 통과한 exact full GM_STATE를 만든다. 최신 verified+1 version과 `event_id=<session_id>:cp<version>`을 사용한다.
2. 실제 쓰기를 시작하기 전에 session/version/event와 UTF-8 state_json 원문을 고정한다. 이후 attempt가 끝나기 전 다른 상태로 다시 직렬화하거나 새 version을 만들지 않는다.
3. 반영으로 pending을 쓴다. raw 원문과 SHA-256, session/version/event를 읽어 대조한다. 정확한 해시는 실행 도구로 계산한다.
4. 의미·parent·manifest를 다시 검사하고 같은 원문으로 verify한다.
5. 같은 version의 verified 원문을 exact read-back해 원문·hash·식별자·의미를 확인한다. 모두 성공해야 저장 완료다. HTTP 성공이나 SQL 실행 응답만으로 완료 처리하지 않는다.
6. periodic 저장의 같은 version exact load로 working GM_STATE를 재정착한다. 이 읽기는 새 저장·게임 진행이 아니다. read-back 결과가 exact-version load 조건을 모두 충족하면 재사용해 같은 데이터를 중복 조회하지 않는다.
- idempotent_replay는 같은 attempt가 있다는 뜻이다. 검증 상태를 확인하고 남은 verify/read-back으로 이어간다.
- cadence 완료 상태는 검증 성공 후 반영한다. 원문 내부의 pending 상태를 사후 조작해 재해시하지 않는다. Resume은 DB의 검증 결과와 exact snapshot을 함께 확인해 동일 attempt 완료 여부를 정합적으로 판정한다.
- API 계약이 문자열 대신 JSON 객체를 요구하거나 hash 직렬화 규칙이 다르면 서버 계약을 먼저 확인한다. 임의 직렬화로 서로 다른 바이트를 같은 payload라 주장하지 않는다.

## STATE_RECOVERY

pending 쓰기 뒤 verify/read-back이 중단되면 같은 version/event/원문으로 자동 재시도를 최대 1회 한다. 필요하면 같은 tuple로 반영을 replay한다. 실패 때문에 난수·사건·NPC 결과를 다시 계산하지 않는다.
새 채팅의 orphan pending은 다음을 모두 검사한다.
- 최신 verified+1 또는 verified가 없는 session의 version 1.
- event_id 규칙 일치, 저장된 exact 원문과 hash 일치.
- 의미·manifest·parent 연속성 통과.
모두 통과하면 DB에 있는 그 원문으로 verify를 완결할 수 있다. 여러 충돌 pending, version gap, 다른 원문, 손상, 핵심 상태 소실이 있으면 자동 승격·폐기하지 않는다.
- 복구 불가 시 `checkpoint_write_recovery_required`에 session/version/reason을 기록하고 기존 verified pointer와 작업 상태를 보존한다.
- periodic exact load가 실패하면 검증된 저장을 폐기하지 않는다. 같은 version 재로드를 복구한 뒤 다음 독립 플레이 변경으로 간다.
- pending은 verified되기 전 정상 Resume 정본이 아니다.

## STATE_RESUME

1. 실제 연결과 session 소유권/대상을 확인한다. P슬롯 번호나 표시 이름만으로 다른 session을 선택하지 않는다.
2. 종료 상태를 확인한다. 이미 종료된 캠페인은 플레이를 재개하지 않는다. 종료 저장/완결이 중단됐다면 동일 결과의 마무리만 복구한다.
3. history에 최신 verified 다음 버전의 orphan pending이 있으면 [STATE_RECOVERY](07-state.md#state_recovery)로 검사한다.
4. 최신 hash-valid verified 원문을 읽고 [STATE_INTEGRITY](07-state.md#state_integrity)의 의미 연속성까지 검사한다. hash만 맞는 불완전한 snapshot은 정상 복원이 아니다.
5. exact full state를 작업 상태로 복원한다. 열린 판정·선택·전투·PC/POV·지도·난수·시간을 그 단계에서 이어간다. 새 채팅이라는 이유로 생성·굴림·첫 장면을 다시 실행하지 않는다.
6. 실제 검증된 version/Scene Turn으로 공개 수첩을 연결한다. 수첩에서 게임 정본을 역복원하지 않는다.
- 최신 미러가 뒤처져도 verified history가 정본이다. 실제 지원되는 repair 계약이 확인된 경우만 미러를 정합적으로 복구한다.
- 최신 상태가 손실됐으면 정확한 불변 ancestor 복구, 검증 가능한 delta repair 또는 사용자가 선택한 완전한 이전 Checkpoint로의 rollback만 가능하다. 서로 다른 시점의 HP와 세계를 임의 혼합하지 않는다.
- 마지막 검증 저장 뒤 미저장 진행은 복원이 보장되지 않는다. 새 비밀·RNG·NPC 기억으로 빈 구간을 채우지 않는다.

## STATE_COMPATIBILITY

이번 판은 새로운 캠페인의 실행 규칙을 정리한 것이다. 운영 DB 스키마·함수·저장 행을 변경하는 지시가 아니다.
- 현행 공개 공유·조회·Spotlight 규칙을 기존 캠페인에 적용할 때 verified 원문은 유지하고 다음 작업 상태부터 적용한다. PC에게 실제 알려졌던 기존 공개 사실만 stable ref로 합치며 미발견 Evidence·숨은 PC 연결·NPC 비밀은 공개하지 않는다. 기존 인계/판정·병렬 시간 pending의 의미와 이미 발생한 결과는 보존하고, 현재 Spotlight 기록에서 확인 가능한 진행량만 복원한다. 알 수 없는 횟수·과거 대기를 만들어내지 않는다.
- 기존 verified history는 수정·재해시·필드 삭제하지 않는다. 삭제된 모드/자원을 사용하는 기존 캠페인은 그 저장의 규칙판으로 재개하거나 별도 명시적 변환 계획을 검토한다. 이번 판을 조용히 소급 적용하지 않는다.
- 기존 rng_mapping_version이 A13_MOD100_LEGACY이거나 그 규칙판에서 생략됐다면 기존 mod 방식의 소비 연속성을 유지한다. 새 rejection 방식으로 중간 전환하지 않는다.
- 기존 anchor/registry 부재만으로 오류를 단정하지 않는다. 해당 규칙판의 실제 namespace와 parent를 검사하고, 없는 원문을 추측 생성하지 않는다.
- 과거 숫자 입력 Gate가 저장돼 있으면 그 pending 단계까지만 정확히 해석한 뒤 현행 입력 방식으로 전환한다. 저장된 메뉴 의미를 재배정하지 않는다.
- 문서판 번호는 DB state_schema_version과 다르다. 이전 문서의 RC19/A24/A1 허용 설명만으로 새 payload 호환을 단정하지 않는다. 실제 서버 검증 계약이 삭제 필드를 필수로 요구하면 별도의 저장 어댑터 수정이 필요한 것으로 보고한다. 가짜 0/빈 필드로 통과시키지 않는다.
