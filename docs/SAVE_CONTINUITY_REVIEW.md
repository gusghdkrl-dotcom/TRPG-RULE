# 저장 의미와 재개 연속성 검토

2026-11-08. 담당 규칙은 STATE_EXPERIENCE_CONTINUITY다. 저장 대상은 현재 수치와 사건 제목뿐 아니라 이후 올바른 대사·선택·판정을 바꾸는 사실이다. 실제 캠페인 자료는 포함하지 않는다.

## 달라진 검증 경계

1. 실제 결과가 생길 때 기존 소유 상태에 방향·범위·확실성·관측자·근거 event를 반영한다. 모든 대화 전문이나 사소한 몸짓을 다시 적지 않는다.
2. 저장 직전 현재 작업 상태에서 재개 필수 사실 기준을 고정한다. session/시점/정본 판본·입력 대기와 기존 중요 사실을 포함한다. payload를 만든 뒤 그것만 보고 기준을 만들면 누락을 발견할 수 없다.
3. 실제 exact-version read-back과 같은 판본 정본으로 논리적 현재 상태를 재구성한다. 이전 채팅 기억만으로 누락을 채워 검증하지 않는다.
4. 고정 기준과 재구성 결과의 값/확실성/관계 방향/범위·pending을 비교한다. 해시는 바이트 보존, 의미 대조는 내용 보존의 서로 다른 검사다. 서버 verified라도 의미 누락이면 복원 연속성 실패/미검증을 구분해 보고한다.
5. 새 채팅은 첫 지문과 선택 생성 전에 같은 현재 의미를 적용한다. 부분 복구는 알려진 사실을 미확인으로 돌릴 허가가 아니다. 필요한 상태만 복구하며 누락을 창작하지 않는다.

## 개발용 비교 도구

`python3 scripts/check_resume_semantics.py frozen-probes.json reconstructed-state.json`

두 입력 모두 실제 캠페인 자료이면 저장소 밖의 비공개 작업 위치에 보관한다. 이 스크립트는 서버를 호출하거나 DB1/Markdown 정본을 병합하지 않는다. 호출자가 **실제 read-back과 정본으로 재구성한 논리 상태**를 제공해야 한다. 게임용 ZIP에 포함하지 않으며 프로젝트 채팅에서 자동 실행되는 도구가 아니다. 키퍼는 룰북의 같은 비교 절차를 실제 지원 도구 안에서 수행한다.

검증 기준 형식(가상 사례):

```json
{
  "format": "RESUME_PROBES_V1",
  "probes": [
    {"path": "/session", "expected": "SYNTHETIC", "source_ref": "SESSION_CONFIRMED"},
    {"path": "/turn", "expected": 41, "source_ref": "LAST_SETTLED_EVENT"},
    {"path": "/canon_revision", "expected": 2, "source_ref": "CANON_BINDING"},
    {"path": "/entities/ENTITY_A/communication", "expected": {"understands": {"ENTITY_B": {"status": "confirmed", "value": true}}, "speaks": false, "signal_meaning": "unknown"}, "source_ref": "CONFIRMED_INTERACTION"}
  ]
}
```

JSON Pointer는 해당 **논리 상태의 실제 경로**다. 고정/동적 사실의 저장 위치와 투영 후 경로가 다르면 재구성 결과를 기준으로 매핑한다. 위 경로는 운영 서버의 새 필수 schema가 아니다. 존재하는 중요 사실·범주 전체를 기준으로 잡되 적용되지 않는 범주를 가짜 값으로 채우지 않는다. 값이 없는 것과 명시적 null/unknown/false를 구분한다. 객체 내부의 추가·삭제도 변경으로 탐지한다. 출력에는 원래 값·비공개 entity명·사실 본문을 쓰지 않고 실패한 probe 번호만 표시한다.

도구는 지정한 probe만 비교한다. 저장 전에 기록하지 않은 사실, 누락된 probe 자체, 잘못된 근거의 진위를 자동 발견하지 못한다. critical_state_registry/원본 작업 상태와의 coverage 검토가 반드시 별도로 필요하다. 두 JSON을 똑같이 만들었다는 사실은 실제 서비스 저장 성공을 입증하지 않는다.

## 2026-11-15 — 최근 기능의 V2 저장 수납 대조

운영 `trpg-state-v2`를 읽기 전용으로 확인했다. `public.gm_checkpoint_history`는 `TRPG_STATE_V2/DOCUMENT_BOUND/DB1` verified 12건, `trpg_private.gm_canon_documents`는 별도 판본 보관이며 운영 함수 시그니처는 `trpg_v2_commit/verify/load_version` 원문 계약과 일치한다. 기존 verified 1건의 복사된 JSON을 SQL 안에서 합성 변형해 추가한 `story_context.main_track_by_pc`가 V2 검증기에 수용되는지도 읽기 전용으로 확인했다(1/1, 실제 세이브 변경 없음). 실제 checkpoint의 `story_context` 및 `pcs`에는 `current_carrot`, `main_goal_ref`, `active_main_goals` 등 서로 다른 진도 명명 사례가 존재한다. 이는 과거 세이브가 무효라는 뜻이 아니라 **현재 ref/PC별 경험을 한 가지 의미로 복원하는 규칙이 약한 것**이다. 실제 사용자의 원문·ID/비공개 진실은 이 문서에 싣지 않는다.

- 새 체크포인트의 PC별 E 공개 방향·인지/접근/체험·선택 활동은 기존 `story_context.main_track_by_pc` 재개 문맥을 권장 표준으로, E의 세계 발생·부분/완전 해결·실제 남은 원인은 `world_delta.drivers[E-ref]`를 기준으로 한다. 구판 저장의 다른 명칭은 원문 근거와 정본 ref를 확인한 경우에만 연결하고 자동 재작성하지 않는다.
- 화재/침수/적·감염의 실제 물리 경과와 HP0의 다른 PC 구조·이송 조건은 `ongoing_consequences` 및 `pcs/scene_context`에 보존한다. 부분 작업·S 완료·PC1 선행 도착은 E 세계 완료나 PC2 체험 완료를 의미하지 않는다. 플레이 중 정상 해결/회복·사망은 재개 때문에 취소/재발동되지 않는다.
- HP/SAN/Luck·현금·장착/가방별 실물·수량·소모/위치의 원장이 HUD의 출처다. 고정 바텀 HUD와 🟢/🔴 증감은 결과를 투영할 뿐 새로운 재화/소지품 장부나 매턴 저장/이벤트가 아니다. `scene_context`의 실제 마지막 결과/표시 경계만 활용해 이전 턴의 증감을 재상영하지 않는다.
- 저장 전 작업 사실 → 전체 누적 DB1 구성 → 원문 검증 → canon+verified exact read-back → **세계 E/PC별 목표·구조·열린 입력·소지·진행 위험을 포함한 의미 대조**를 한다. V2 SQL은 객체/coverage/PC 슬롯 등 구조를 확인하지만 이 관계들을 의미적으로 모두 검증하는 것은 아니다. 새 필수 테이블/컬럼/DB 쓰기·구판 소급 마이그레이션은 필요하지 않다.
- 이 점검은 **운영 메타데이터·필드명·현재 SQL 구조만** 읽고 실제 개별 캠페인의 플레이 재현·검증 저장/로드 왕복을 실행하지 않았다. 서버 접근 성공과 저장 품질을 혼동하지 않는다.

## 통합판 맥락 보강

현재 저장은 구조화된 값과 story_context / npc_contexts / scene_context / ongoing_consequences를 같은 사실/ref로 연결한다. 이야기의 목표 변화 이유·상대별 말투/태도 이유·마지막 질문과 응답자·진행 중 동작·차단된 원인의 조건을 포함한다. 새 Supabase TRPG_STATE_V2 서버는 이 네 맥락을 최상위 JSON 객체로 수용하고 원문 그대로 보존한다. `pcs`·`runtime`·`world_delta` 등 동적 현재값과 원래 작업 상태의 의미/범위를 대조해야 하며, 단순 JSON 구조 검증만으로 실제 맥락 충실도를 보장하지 않는다.

현재 맥락도 저장 전 기준에 포함하고 실제 read-back+같은 정본으로 재구성한 결과를 대조한다. 값 비교가 통과해도 새 채팅의 표현·말투·장면 적용 품질은 별도 이어쓰기 평가다.

## 실제 수행한 합성 검사

`python3 scripts/test_resume_semantics.py`: 30개 통과. 실제 파일 JSON 왕복·별도 Python 프로세스 CLI와 정상/누락/변경/입력 오류를 실행했다.

- 이해가 confirmed에서 unknown으로 낮아짐, 이해 여부 false 변경, 발화 불가능이 가능으로 바뀜, 이해 대상 방향/상대 변경: 거부.
- 제안이 수락됨, 차단된 길이 열림, 소지자/현재 물건 변경, 입력 대기 삭제, 완료 event 목록 유실: 거부.
- session·현재 진행 시점·정본 판본 변경: 거부.
- null 필드 삭제, false를 숫자 0으로 대체: 거부.
- 중복 JSON 키, 빈/잘못된 manifest, 중복 probe 경로: 거부.
- 정상 값·객체의 파일 왕복, 이스케이프된 JSON Pointer: 통과.
- 이야기 목표 임의 변경, 재개 문맥 전체 삭제, NPC호칭/태도근거 누락, 마지막 질문/응답자/진행동작 변경, 차단위협 재활성화: 추가8건 모두 거부.

## 본문 수동 대조 사례

| 범위 | 유지할 구분 |
|---|---|
| 의사소통 | 상대 말을 이해하지만 같은 언어로 말하지 못함; 몸짓 일부 이해와 목적 미확인 |
| 지식 | 직접 들음/전달받음/추정/검증; 공개된 플레이어 사실과 NPC가 아는 사실 |
| 협상 | 제안/조건부 동의/거절/수락, 현재 답변 대기 |
| 장면 | 문 열림/닫힘·거리가 변함·무기를 준비함/실제 사용함 |
| 물건 | 보여줌/양도함·포장/노출·기계 정지/재가동 가능 조건 |
| 위험 | 노출/감소량 적용·현재 처치·이미 차단/취소한 원인 |
| 관계 | 말투·호칭·약속·실제 협력 범위; 자동 충성 없음 |
| 복구 | 오래된 수치+최신 몇 줄을 완전한 최신 snapshot으로 주장하지 않음 |
| 속도 | 변화한 사실만 작업 상태 갱신, 매 응답 전원/전체 재조회 없음 |
| 구판 | 실제 기록·명시적 사용자 확인에서만 보완, 과거 verified 원문 변경 없음 |

2026-11-09 신규 Supabase V2에서는 합성 체크포인트 2버전의 payload 수용·SHA 확인·commit/verify/exact read-back과 일부 구조 오류·부모 충돌 차단을 실제 검증했다. 현재 미검증: 실제 비공개 캠페인 정본 전체SHA/누적 세계 변경 의미복원, ChatGPT가 기준을 빠짐없이 구성하고 다음 채팅에서 적용하는 준수율·응답 시간. 2026-11-11부터 GitHub 자동 미러/비상 쓰기는 운영 대상이 아니다. 비공개 정본은 Supabase private 테이블에 기록하고 소유자에게 동일 원본 .md를 전달한다. 합성 정본 exact insert/read-back과 SHA 검증은 성공했지만 실제 캠페인 결합은 미검증이다. 실게임 실패 사례의 저장 원문을 확보하지 못했으므로 과거 저장 누락/로드 적용 문제의 원인을 소급 단정하지 않는다. 이 점검은 이미 유실된 실제 캠페인 상태를 복구한 것이 아니다.
