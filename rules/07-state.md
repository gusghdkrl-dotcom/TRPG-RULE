# 비공개 상태·저장·복원

규칙판: 통합 연출판 2026-10-30. 규칙 ID는 버전과 독립적으로 유지한다. 필요한 절만 조회한다. 전체 경로는 `00-index.md`를 따른다.

## STATE_AUTHORITY

비공개 GM_STATE는 매 실제 결과 뒤 현재 작업 상태에서 갱신한다. 이 작업 자체는 DB 조회/쓰기가 아니다. Supabase verified history가 영속 정본이다. 자동 저장은 설정 완료·플레이 시작·Scene Turn 30배수의 안전 경계·전체 캠페인 종료 경계이며 수동 저장은 별도다. 저장 절차·복구·재개는 STATE_CADENCE/STATE_COMMIT/STATE_RESUME만 따른다. 실제 verify와 동일 version read-back 없이 저장 완료라 하지 않는다. 실패 때문에 비밀·난수·NPC 결과를 새로 생성하지 않는다.

비공개 GM_STATE는 세계·인물·PC·난수·진행 절차의 작업 상태다. 매 일반 턴 실제 결과를 반영하고, [STATE_CADENCE](07-state.md#state_cadence)의 경계에서 전체 상태를 저장한다.
- 문서에 지정된 운영 대상은 Supabase `trpg-private-state-db` / project ref `mwopllxdhxcykwyxuyrd`, 정본은 `public.gm_checkpoint_history`의 verified 전체 `state_json`이다. `public.gm_sessions`는 최신 미러이며 복원 정본이 아니다.
- 첫 연결 또는 대상·권한·계약이 실제 바뀐 경우 Supabase의 프로젝트·함수 계약을 읽기 전용으로 확인하고 같은 대화에서 재사용한다. 일반 턴의 접근 여부는 STATE_ACCESS_ROUTER를 따른다. 문서의 이름만으로 연결이나 저장 성공을 주장하지 않는다.
- 문서상 함수는 `public.trpg_manual_checkpoint_commit`, `trpg_manual_checkpoint_verify`, `trpg_manual_checkpoint_load_version`, `trpg_manual_checkpoint_load`, `trpg_manual_checkpoint_list`, `trpg_manual_checkpoint_delete`다. 접두사만 같은 다른 함수·스키마로 추측 전송하지 않는다.
- 인증된 기존 커넥터를 사용한다. 비밀 키를 채팅에 출력하지 않는다. 무인증 경로·권한 해제·공개 수첩으로 대체하지 않는다.
- 웹훅·외부 큐·이미지·수첩 저장은 게임 정본을 대신하지 않는다. 보조 전송 실패는 이미 검증된 Checkpoint의 성공을 취소하지 않는다.
- 커넥터가 없거나 정확한 저장 계약을 확인할 수 없으면 `게임 정본 저장 검증 대기`로 표시한다. 현재 확정 상태를 재생성하지 않는다.

## STATE_WORKING_CONTEXT

GM_STATE는 **실제 로드/생성한 게임 데이터와 이후 확정 변경분**이다. Supabase에 저장돼 있다는 사실만으로 AI가 그 내용을 아는 것은 아니다. 현재 모델 문맥에서 확인할 수 있는 데이터 또는 실제 제공된 비공개 실행 저장 공간만 작업 상태로 사용한다. 이 Markdown 규칙은 별도의 영구 메모리·비밀 파일·상시 실행 서버를 만들지 않는다. 추론 과정 자체를 게임 데이터의 저장 장소로 간주하지 않는다.

### 유지할 범위

| 범위 | 현재 작업에서 유지할 내용 |
|---|---|
| 출처·진행 | session, 로드한 verified version, 현재 규칙판, 현재 시각·Scene Turn, Focus/인계/판정 대기, 마지막 저장 뒤 확정 변경분 |
| 참가 PC | 각 PC의 정확한 특성·기능·자원·위치·소지품·선언·공개 지식, Spotlight 진행량 |
| 세계 핵심 | 확정 진실·세계 법칙·인과 제약과 출처 ref, 변경하면 안 되는 사실, 아직 해결되지 않은 위협과 차단 조건 |
| 현재 장면 | 관련 장소·경로·NPC 지식/목적/일정, 접근 가능한 증거와 발견 조건·본문, 실제 실패/시간 비용 |
| 세계 진행 색인 | 현재 장소 밖도 포함한 활성 Driver의 ref·다음 발동 시각/조건·의존 대상·취소 조건·처리 여부, 다음에 확인해야 할 시점 |

- 위 표는 기존 STATE_SCHEMA/namespace에서 필요한 정보를 묶는 작업 관점이다. 새 DB 컬럼·별도 상태 정본을 만들지 않는다. 세계 핵심의 간결한 요약은 탐색용이며 세부 진실·자료 원문을 대체하지 않는다. 원문이 실제 필요하면 같은 ref의 정확한 값을 사용한다.
- 세계 생성/STATE_RESUME 뒤 한 번 구성하고, 매 행동 뒤 실제 변경분만 반영한다. 다음 장면에 필요한 관련 ref를 현재 로드된 상태에서 가져오며 같은 원문이 남아 있으면 재조회하지 않는다. 요약/작업 범위 밖의 원본도 삭제·초기화하지 않는다.
- 시작과 Scene Turn 30/60/90… 저장 경계에는 STATE_CHECKPOINT_RECAP으로 비공개 전체 상태를 복기한다. 일반 턴에는 이번 행동·경과시간에 필요한 부분만 사용하며 전체 복기를 반복하지 않는다.
- 게임 시간이 흐를 때 세계 진행 색인에서 해당 구간의 발동 조건을 확인하고 WORLD_INITIATIVE_EXECUTION으로 결과·취소·후속 조건을 한 번 반영한다. 다른 장소라는 이유로 이미 예정된 사건을 놓치지 않는다. 색인/필수 조건이 유실되면 아무 일도 없다고 가정하지 말고 그 시간 진행에 필요한 상태만 복구한다. 채팅을 기다리는 현실 시간에 자동 실행되는 백그라운드 프로세스가 있다는 뜻은 아니다.
- NPC 대화는 현재 지식·목적·관계가 있으면 DB 없이 처리한다. 숨은 단서 발견도 현재 배치·조건·본문이 있으면 DB 없이 처리한다. 비공개라는 성질이나 장소/PC 전환 자체가 재로드 이유는 아니다.

### 문맥 손실과 영속성

- 대화가 길어지거나 압축되면 도구 결과·세부 상태가 문맥에서 빠질 수 있다. 시스템에 실제 비공개 작업 저장 기능이 있으면 그 지원 계약 안에서 쓰며, 없으면 별도 숨은 메모장을 유지한다고 주장하지 않는다. 공개 답변·HUD·수첩·프로젝트 소스·GitHub에 비밀 요약을 적어 기억을 보강하지 않는다.
- 부재와 무효를 구분한다. `자료 원문 ref는 있지만 본문이 없음`, `다음 사건 목록을 확인할 수 없음`, `해당 PC 기능 값이 없음`처럼 현재 필요한 필드가 실제 없을 때 복구한다. 단지 시간이 지났거나 비밀이 있다는 이유로 전체 최신 저장을 반복 확인하지 않는다.
- 복구는 STATE_ACCESS_ROUTER/STATE_INTEGRITY를 따른다. 현재 미저장 변경분과 출처를 보존하며, 과거 snapshot을 현재 전체 상태로 덮어쓰지 않는다. 누락된 동적 상태의 이후 변화를 검증할 수 없으면 의존하는 결과만 보류한다. 키퍼의 기억이나 공개 장면에서 비공개 정답을 역으로 창작하지 않는다.
- 정상 저장 시에는 작업 범위 밖까지 포함한 full snapshot을 기존 원문과 검증 가능한 변경분에서 구성한다. 간결한 작업 요약만 저장해 세계/NPC를 누락시키지 않는다. STATE_CADENCE의 주기는 유지하며, 미저장 변경분은 문맥 손실 후 복원되지 않을 수 있다. 현재 문서만으로 무손실 실시간 기억이나 캠페인 내내 DB 조회 0회를 보장하지 않는다.

## STATE_ACCESS_ROUTER

- **조회:** 기능 선택·판정 절차는 룰북, PC 수치·단서·NPC 비밀·예정 사건은 현재 작업 상태다. 저장 경계가 아닌 일반 판정은 둘 다 있으면 Supabase 조회 0회다. 비공개 정보라는 이유로 재조회하지 않는다. 필요한 필드가 실제 없을 때만 복구한다.

DB 호출에는 필요한 상태 필드/ref 또는 저장 작업과 허용 사유가 있어야 한다. 연결 계약은 첫 사용/실제 변경 때만 확인한다. 조회는 새 채팅/명시 로드, 필요한 상태 유실·충돌, 저장 경계 parent/verify/read-back, 실패 복구, 명시적 DB 대조에 한정한다. 기능 선정·판정 요청·굴림 결과·PC 전환·A·HUD만으로 latest/list/full load를 하지 않는다. 문서 찾기 판정 전에 발견할 기사 전문까지 미리 조회하지 않는다. 현재 미저장 상태를 과거 저장으로 덮어쓰지 않으며 필수 저장 검증은 유지한다.

Supabase는 영속 저장·복구 경계에서 접근한다. **일반 응답의 기본값은 DB 조회 0회**다. 현재 작업 상태를 읽고 실제 결과를 갱신하는 것은 DB 호출이 아니다.

| 실제 조건 | 허용되는 접근 |
|---|---|
| 새 채팅 재개·명시적 로드 | STATE_RESUME으로 해당 session의 verified 전체 상태를 한 번 복원 |
| 현재 작업 상태 일부 유실·출처 충돌·손상 | 필요한 exact version/범위만 확인하고 STATE_INTEGRITY/STATE_RECOVERY 적용 |
| STATE_CADENCE 저장 경계 또는 명시적 저장 | 최신 parent·버전 충돌 확인, commit/verify/exact read-back 등 STATE_COMMIT의 필수 접근 |
| pending/verify/read-back 실패·실제 버전 불일치 | 같은 attempt의 상태 확인과 한정된 복구 |
| 사용자가 DB와의 대조·저장 목록을 명시 요청 | 요청한 session/범위만 읽고 현재 미저장 진행과 구분 |
| 첫 저장 연결 또는 연결 대상/권한/계약의 실제 변경 | 대상·함수 계약을 확인하고 같은 조건에서는 확인 결과 재사용 |

호출 전 필요한 답을 먼저 식별한다. **현재 필요한 상태 필드/ref 또는 저장 작업과 위 허용 사유가 없으면 DB를 호출하지 않는다.** 이를 매 턴 별도 체크리스트로 출력하거나 점검용 RPC로 실행하지 않는다.

| 필요한 답 | 먼저 참조할 곳 | DB를 읽는 경우 |
|---|---|---|
| 기능 선택·판정 필요성·성공 단계·Spotlight 규칙 | 해당 룰북 본문 | 규칙 확인만으로는 없음 |
| PC의 기능 수치·HP·Luck·위치·현재 메뉴 | STATE_WORKING_CONTEXT의 현재 PC/진행 데이터 | 실제 필요한 값/출처가 없거나 충돌할 때 |
| NPC가 아는 말·비밀 목적·해당 장소 단서·자료 원문 | 현재 작업 상태의 관련 NPC/Evidence ref | 해당 장면에 필요한 확정 데이터가 없을 때 |
| 시간 경과에 도달할 숨은 사건·위협 | 현재 세계 진행 색인과 해당 Driver | 해당 구간의 색인/조건/결과 상태가 없을 때 |
| 저장 여부·정확한 복원본·저장 목록 | 실제 저장 계약 | 위 로드/저장/복구/명시적 대조 조건일 때 |

- 누락 범위는 우선 같은 문맥의 실제 로드 결과와 변경분에서 찾는다. 없으면 필요한 session/version/ref의 관련 데이터를 한 번에 복구한다. 부분 조회가 실제 지원되지 않으면 exact snapshot 한 번에서 필요한 값을 가져와 재사용한다. 존재하지 않는 필드 조회 API를 만들거나 같은 응답에서 ref마다 full load를 반복하지 않는다.
- 규칙 본문만 필요한 경우 룰북의 해당 ID로 간다. 반대로 실제 캠페인의 비밀·PC 수치가 없으면 룰북의 일반 예시로 대신 채우지 않는다. 현재 상태의 값과 룰북의 절차를 구분하며 둘 다 남아 있으면 재검색하지 않는다. 저장 시 전체 복기는 STATE_CHECKPOINT_RECAP에 묶고, 복기 전용 latest/list/추가 full load를 붙이지 않는다.
- `load/load_version/list`는 위 복원·복구·저장 대조에, `commit/verify/read-back`은 저장 경계에만 사용한다. 함수별 인자는 확인된 계약을 따른다. `delete`는 일반 게임 진행·속도 개선·오류 복구 경로가 아니며 별도 명시적 삭제 지시가 없으면 호출하지 않는다.
- 이동·대화·자료 찾기/재확인·기능 선정·판정 요청/굴림 결과·PC 전환·Handoff `A`·HUD·지도 열람만으로 조회하지 않는다. 단순 턴 증가, 같은 경로 재사용, 비공개 세계가 있다는 이유도 조회 조건이 아니다. 문서의 '현재 상태 확인'·'세계 진행 검사'는 먼저 STATE_WORKING_CONTEXT의 작업 상태를 뜻한다. 같은 응답이 저장 경계에 해당하면 필수 저장 접근은 수행한다.
- 같은 대화의 작업 상태는 실제 로드/생성한 정본에 이후 확정 결과를 반영한 것이다. 오래된 verified snapshot으로 미저장 HP·시간·위치·난수를 덮어쓰지 않는다. 정확한 상태가 없으면 추측하거나 새로 생성하지 말고 영향을 받는 변경만 보류해 복구한다.
- 매 응답 latest/list/full load·스키마 탐색·parent 대조를 반복하지 않는다. 부모 검증은 저장 경계에서 수행한다. 같은 응답/attempt의 같은 version·같은 원문을 이미 얻었으면 재사용하고, commit read-back이 exact load 요건을 충족하면 두 번 조회하지 않는다.
- 필요한 여러 필드는 실제 지원되는 한 호출로 묶고 관련 없는 session·과거 전체를 읽지 않는다. DB 호출을 하지 않았다고 미검증 상태를 '저장 완료'로 표시하지 않는다.
- 사용자가 명시한 저장 없는 테스트는 첫 복원 이후 작업 분기만 갱신한다. 위의 실제 복구/대조 조건이 없으면 원본 DB 재조회도 하지 않는다. DB·수첩 쓰기 중지 안내는 테스트 시작/종료·상태 변경/요청 때만 표시하고 매 지문에 반복하지 않는다. 테스트를 임의 시작하거나 테스트 결과를 나중에 원본에 자동 덮어쓰지 않는다.

## STATE_VERIFIED_OWNER_AUDIT_AND_GITHUB_BACKUP

사용자가 저장 전체 대조·시나리오 비공개 원문 공개·백업 검수를 **명시적으로** 요청한 경우는 PLAY가 아닌 읽기 전용 소유자 감사다. 게임 시간·RNG·NPC·공개 수첩·저장 버전은 변하지 않는다. CORE_VISIBILITY의 일반 PLAY 정보 제한을 게임 지문에 우회 적용하지 않되, 감사 답변에는 실제 확인한 원문과 미확인 범위를 구분한다. 인증키·복구키 등 시스템 비밀은 시나리오 스포일러와 구별하고 노출하지 않는다.

- **정식 읽기 경로:** Supabase의 인증된 커넥터로 session/version을 명시해 기존 `public.trpg_manual_checkpoint_load_version(p_session_id text, p_version bigint)`를 우선 호출한다. 반환된 `state_json` 전체 텍스트를 JSON으로 읽고, 같은 행의 version·event_id·state_hash와 verified history를 대조한다. 저장 목록은 확인된 `list` 계약을 따른다. `gm_sessions` latest mirror나 개별 필드 추측을 전체 정본으로 간주하지 않는다.
- 직접 `gm_checkpoint_history.state_json`을 조회하는 임시 SQL은 정식 버전 복원보다 우선하지 않는다. 특정 도구 호출이 차단·절단되면 차단 사유를 단정하거나 데이터를 없다고 선언하지 않는다. 정식 함수도 실패하면 우회 인코딩·권한 완화·무인증 공개 링크를 만들지 않는다.
- **독립 백업:** 사용자가 승인하여 만든 비공개 GitHub `gusghdkrl-dotcom/trpg-private-state`의 `verified-gm-snapshots-2026-10-30` 브랜치에는 당시 검증 완료된 10개 저장의 원문 및 `snapshots/verified/MANIFEST.json`이 있다. 복구가 필요하면 private GitHub 도구로 exact path를 읽어 manifest SHA-256 및 ID/version을 검사한다. 이 기록은 **2026-10-30 시점 백업**이며 자동 최신 미러가 아니다. GitHub가 Supabase보다 최신이라고 가정하거나 미저장 진행을 덮어쓰지 않는다.
- **2026-10-30 사용자 요청으로 향후 검증 세이브의 비공개 GitHub 이중 백업을 활성화했다.** 각 실제 저장 경계에서 Supabase 동일 version의 verified full `state_json` exact read-back을 마친 다음, 연결된 GitHub 도구로 비공개 `gusghdkrl-dotcom/trpg-private-state`의 `gm-checkpoints` 브랜치 `snapshots/verified/<session_id>/vNNNN.json`에 동일 원문을 새 파일로 추가한다. 기존 버전은 덮어쓰거나 삭제하지 않으며 GitHub 재열람 문자열과 Supabase 원문의 일치까지 확인한다. 함께 `snapshots/verified/MANIFEST.json`, `snapshots/INDEX.md`, 캠페인 `REVIEW.md`(숨은 진실·NPC·증거·조건부 사건을 원문 범위에서 파생)를 최신 확인 상태로 갱신하고 재열람한다. 비공개 스포일러는 공개 `TRPG-RULE` 저장소나 공개 수첩에 쓰지 않는다. Supabase는 단일 저장 정본이고 GitHub는 열람·복구용 백업이다. GitHub 실패·연결 단절·시간 한계가 있으면 Supabase의 verified 성공을 취소하지 말고 백업 미완료를 보고하고 다음 허용된 저장/복구 시 누락 버전만 대조한다. 채팅과 무관하게 실행되는 24시간 자동 동기화나 백그라운드 서버가 있다고 주장하지 않는다.
- 비공개 GitHub로 **전체 스냅샷**을 백업하는 작업과, 공개 저장소/수첩/프로젝트 문서에 **비밀 요약**을 적어 작업 기억처럼 사용하는 행위는 다르다. 후자는 여전히 금지한다. 공개 Rules repo에는 절대 실제 비공개 state_json을 넣지 않는다.

## STATE_SCHEMA

다음은 full snapshot에 포함해야 할 의미상의 범위다. 실제 필드 경로·허용 스키마 버전은 연결된 저장 계약을 따른다. 이 목록은 임의 DB 테이블이나 새 필수 컬럼을 만드는 지시가 아니다.
| 범위 | 보존할 사실 |
|---|---|
| 식별·순서 | 플레이어 시작 설정 원문·해석값·미응답·질문 대상·설정 단계, session, version/event, 현재 규칙판, phase, active chapter, 종료 상태 |
| 불변 세계 | 원작 특징과 실제 세계 ref의 연결, 중심 위협의 조건부 손실·차단 인과, 시나리오 핵심, 비공개 진실, 세계 법칙, 증거의 원래 배치, 종결 조건, 확정 지도 |
| 변화하는 세계 | 실제 발생/방지/잔존/진행 중인 중대 손실과 그 근거, 현재 시각, 장소/경로 상태, NPC 위치·지식·목적·일정, 위협/환경 결과, 기관 접근, 소유권, 작업, 약속, 되돌릴 수 없는 결과 |
| PC | 확정 참가 인원(1~3명)·실제 참가 슬롯, stable PC identity와 P슬롯 연결, 확정 과거/APP와 반영 외형/직업/전문 분야 및 실제 지위·권한·책임, 특성·기능, HP/SAN/Luck·부상/광기, 현금·소지품·위치, 참여 연결 |
| 지식·조사 | 발견자·시점·출처를 보존한 파티 공통 공개 사실, 증거 ref와 실제 배부한 자료 본문/발췌·수치·손상 범위, 제안자가 있는 플레이어 가설, 검증/모순·시간 순서·결론, 진행/미해결 질문 |
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
- NPC가 답을 기다리는 질문/제안과 플레이어의 원래 목적·아직 실행하지 않은 선언 범위를 기존 대화/진행 기록에 보존한다. 저장·인계·복기·재개가 PC의 대답이나 수락을 대신하지 않는다.
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

## STATE_CHECKPOINT_RECAP

현재 프로젝트 운영에서 **게임 시작과 Scene Turn 30/60/90… 저장마다 비공개 전체 상태를 다시 검토해 작업 문맥을 정리**한다. 이미 필요한 full snapshot 검증/읽기에 결합하는 절차이며, 새 저장 주기·외부 서버·영구 비밀 메모리를 만들지 않는다.

### 시점과 원본

- setup_bootstrap에서 생성된 전체 정본을 점검하고 play_start 검증 뒤 첫 장면 전에 복기한다. periodic_scene_turn에서는 STATE_CADENCE가 정한 첫 안전 경계의 저장에 결합한다. 열린 굴림·대화 인계 등을 복기를 위해 중단하지 않는다. 한 번에 여러 30배수 기준선을 넘겨도 현재 저장본으로 한 번만 복기한다.
- 저장 전에는 현재 full GM_STATE와 미저장 변경분, 필요한 parent를 STATE_INTEGRITY로 대조해 누락/충돌을 해결한다. 저장 후에는 **같은 version의 verified exact read-back 결과를 그대로 사용**한다. hash/성공 표시만 받았거나 본문이 잘렸다면 전체를 읽었다고 주장하지 않고 기존 저장 검증/복구 절차를 완료한다.
- 같은 원문을 이미 확보했으면 복기를 위해 별도 latest/list/load를 호출하지 않는다. 원문이 큰 경우 실제 지원되는 전달 방식 안에서 같은 version의 누락된 부분만 확보한다. 지원되지 않는 부분 조회 API를 가정하거나 NPC마다 전체 저장본을 다시 읽지 않는다.
- 새 채팅 STATE_RESUME에서도 확보한 verified 전체 상태로 같은 복기를 수행한다. 수동/종결 저장에서는 이미 확인한 전체 상태 검증 결과를 재사용하며 복기만을 위한 추가 저장을 만들지 않는다.

### 전체 범위 점검

STATE_SCHEMA와 해당 저장의 실제 namespace/critical_state_registry를 따라 **현재 장면 밖의 모든 비공개 요소까지** 빠짐없이 대조한다. 요약 목록에 없는 기존 namespace도 버리지 않는다.

| 범위 | 확인할 내용 |
|---|---|
| 불변 정본 | 원작·세계 법칙·중심 진실·흑막/원인·증거 원래 배치·PC 과거·확정 자료 원문·종결 조건 |
| NPC·세계 변화 | 현재 장면 밖과 휴면 상태를 포함한 모든 NPC의 위치·현재 목적·아는 사실·관계·비밀·일정, 장소/경로/소유/권한·증거의 실제 변화 |
| 아직 보이지 않은 진행 | 모든 활성 Threat/Driver·예약 사건·약속·후속 결과, 발동/취소 조건·다음 시각·의존 순서·이미 처리한 결과 |
| 공개와 비공개 경계 | 파티가 발견한 내용·발견자/출처·가설과 아직 미발견인 내용, NPC가 실제로 전달받은 사실 |
| PC·실행 상태 | 전원 수치/자원/소지품/위치, 난수 큐/소비 위치, Scene Turn/시간, 열린 판정·대사/답변 대기·선언·Spotlight/메뉴 |
| 연속성 | 지난 저장 이후 실제 변경 근거, 발생/방지/잔존 손실, 미해결 작업, 이전에 확정된 원문과 현재 값의 연결 |

### 다음 일반 턴으로 이어가기

- 검증한 원문을 바탕으로 STATE_WORKING_CONTEXT의 세계 핵심·현재 장면·다음 발동 조건·미해결 질문을 다시 정리한다. 다음 30턴을 미리 생성하거나 PC 답변·미래 사건 결과를 확정하지 않는다. 원문을 간략한 요약으로 대체 저장하지 않는다.
- 복기는 **읽기와 대조**다. 사건·난수·SAN·피해·시간을 다시 적용하지 않으며 NPC 목적·비밀을 재창작하지 않는다. 저장본 원문의 cadence pending을 수정/재해시하지 않고 검증 메타데이터와 함께 완료 여부를 해석한다.
- 비공개 복기 내용·숨은 단서·예정 사건·난수는 지문/HUD/수첩/프로젝트 소스로 출력하지 않는다. 공개 안내는 실제 저장 성공/실패와 재개에 필요한 최소 정보만 쓴다. 별도의 비밀 메모리가 생성되거나 다음 30턴의 무손실 기억이 보장됐다고 주장하지 않는다. 저장 사이에 필수 상태가 실제 유실되면 STATE_ACCESS_ROUTER의 한정 복구는 유지한다.

## STATE_COMMIT

캠페인당 Single Writer를 유지한다. 동일 요청을 다시 받아도 같은 저장 attempt를 완결한다.
1. [STATE_INTEGRITY](07-state.md#state_integrity) 검사를 통과한 exact full GM_STATE를 만든다. 최신 verified+1 version과 `event_id=<session_id>:cp<version>`을 사용한다.
2. 실제 쓰기를 시작하기 전에 session/version/event와 UTF-8 state_json 원문을 고정한다. 이후 attempt가 끝나기 전 다른 상태로 다시 직렬화하거나 새 version을 만들지 않는다.
3. 반영으로 pending을 쓴다. raw 원문과 SHA-256, session/version/event를 읽어 대조한다. 정확한 해시는 실행 도구로 계산한다.
4. 의미·parent·manifest를 다시 검사하고 같은 원문으로 verify한다.
5. 같은 version의 verified 원문을 exact read-back해 원문·hash·식별자·의미를 확인한다. 모두 성공해야 저장 완료다. HTTP 성공이나 SQL 실행 응답만으로 완료 처리하지 않는다.
6. 시작/periodic 저장의 같은 version exact 상태로 STATE_CHECKPOINT_RECAP을 수행하고 working GM_STATE를 재정착한다. 이 읽기는 새 저장·게임 진행이 아니다. read-back 결과가 exact-version load 조건을 모두 충족하면 재사용해 같은 데이터를 중복 조회하지 않는다.
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
5. exact full state로 STATE_CHECKPOINT_RECAP을 수행하고 STATE_WORKING_CONTEXT의 PC·세계 핵심·현재 장면·세계 진행 색인을 구성한다. 비공개 진실/자료 본문을 공개 요약으로 바꾸거나 원본을 버리지 않는다. 열린 판정·선택·전투·PC/POV·지도·난수·시간을 그 단계에서 이어간다. 새 채팅이라는 이유로 생성·굴림·첫 장면을 다시 실행하지 않는다.
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
