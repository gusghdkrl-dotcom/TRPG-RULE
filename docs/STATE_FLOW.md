# 상태·저장·재개 흐름

신규/독립 재시험은 실제 최신 룰북·배포 ID와 새 campaign/session으로 설계→정본 초안/최초 STATE→그 작성물의 COMPATIBILITY_GATE→동일 원문 등록/첫 출력·저장 순서를 따른다. 재개는 기존 정본/verified 누적 상태를 보존한다. 룰북 수정으로 이전 캠페인을 자동 재생성하거나 DB 스키마를 바꾸지 않는다. 첫 위치/미실행 행동·NPC 위치/소유는 동일 초기 사실에서 투영하며 적의 추적/경비/배회 현재 위치·마지막 실제 정보·다음 행동/중단은 기존 동적 수납에 잇는다. 로컬 테스트 요약과 운영 checkpoint/서버 verified를 구별한다.


현행 실행 정본은 rules/07-state.md다. 2026-11-09부터 인증된 새 Supabase `trpg-state-v2` (project ref `taoaffdyssqtnjszumpq`)의 `public.gm_checkpoint_history` verified 원문을 사용한다. 서버 스키마는 `TRPG_STATE_V2`, 저장모드는 DOCUMENT_BOUND(DB1)이며, 개발/이전 검증기를 복사하지 않았다. 실제 설치 SQL은 [trpg-state-v2.sql](sql/trpg-state-v2.sql)이다.

1. 실제생성/로드한정본과누적상태에서현재작업범위를구성한다.
   신규 저장도 기존 V2/DB1 JSON 구조를 사용한다. `world_delta.drivers`는 일반 E의 실제 세계 변화, `story_context.main_track_by_pc`는 P슬롯별 E 참조/공개 가능 방향·체험·현재 별도 활동, `ongoing_consequences`는 물리 재난·HP0 구조/이송 과정, `pcs/runtime/scene_context`는 실제 자원/소지/행동권·열린 단계, `processed_event_ids`는 실제 적용 event 중복 방지다. 6개 world_delta의 키는 change_coverage의 changed_entity_ids와 일치시킨다. 새 SQL 컬럼/RPC가 아니라 기존 JSON 수납 의미의 일관된 사용이다.
2. 결과가생길때해당현재값과이야기/인물/장면의연결만갱신한다.변화없는전체정보를매번다시쓰지않는다.
3. 저장전원래작업상태에서중요값/관계/출처/입력대기/재개문맥의기준을고정한다.
4. DB1은정확한canon_ref+누적delta/신규/취소/처리event+PC/실행/재개문맥의별도payload를구성한다.현재상태를축소하지않는다.
5. 동결원문·SHA·session/version/event/attempt/parent로 `trpg_v2_commit`→`trpg_v2_verify`→`trpg_v2_load_version`의 같은 version exact read-back. 사용 가능한 인증된 고권한 Supabase 연결에서만 호출하며 공개 API 권한을 열지 않는다.
6. 같은정본과실제read-back으로논리상태를재구성해고정기준과비교한다.등록된값비교와서사문맥충분성/첫장면적용은별도확인한다.
7. 이동표/사용자가 지정한 session/version/SHA가 있으면 exact version을 우선하고 지정이 없을 때만 최신 verified를 읽는다. 파일 인계는 전체 현재 STATE+같은 SHA 정본+저장 출처/검증 정보가 필요하며 과거 룰북 파일을 요구하지 않는다. 진행은 현재 소스의 최신 룰북을 쓰고 로컬 검증과 서버 verified를 구별한다.
8. 로드는첫지문전에이야기흐름·NPC말투/태도/이유·현재대화/마지막질문/준비/확인된의미·수치/행동대기를함께적용한다.

신규 rules_version은 배포 RULESET.json의 정확한 식별자를 기록한다. ON 종결의 runtime.hq/ending_state·pcs.player_id/alive 계약은 rules/07-state.md의 STATE_CANON_SAVE_BINDING을 따른다. 기존 저장은 변경하지 않는다.

주기: setup_bootstrap/play_start/40배수안전경계/전체종료·본부ON챕터종료+명시수동.기존20턴정본재독은별도이며겹친원문은재사용한다.공개수첩전송은없다.현재상태가남아있는저장실패는플레이를막지않고원문/미저장변경을보존한다.외부차단·상태유실·호환실패를구분한다.현재작업공간/실제서버계약이없는영구메모리는가정하지않는다.

신규 Supabase에서 합성2버전의 실제 commit/verify/exact read-back/SHA·부모충돌·동일attempt·일반접근권한을 검증했다. 실제 비공개 캠페인 정본 파일 원문SHA/절 병합·GitHub 백업왕복·장기 ChatGPT 재현품질은 여전히 미검증이다. 서버 verified가 의미/서사 연속성 완성을 뜻하지 않는다.

## 기존 게임에서 최신 규칙으로 새 저장

1. 프로젝트 지침/룰북 소스를 최신 묶음으로 교체한다. GitHub 갱신만으로 업로드된 파일이 바뀌지는 않는다. 기존 게임의 현재 정본·작업 상태는 그대로 둔다.
2. 같은 게임 채팅에서 다음처럼 요청한다.

   > 현재 진행·수치·소지품·인물 기억·마지막 질문/판정 대기를 유지하고, 소스에 있는 최신 룰북을 적용해 새 세이브를 만들어 줘. 과거 저장은 보존하고 새 버전으로 검증한 뒤 이동표를 줘. 다른 채팅으로 옮길 수 있게 전체 STATE JSON과 비공개 정본 파일도 내보내 줘.

3. 현재 상태가 있으면 과거 세이브 재로드·새 게임 설정/생성을 하지 않는다. 미처리 단계부터 최신 규칙을 적용하고 이미 산출/적용한 값·비용·결과를 중복 처리하지 않는다. 이전 정보가 이미 유실됐으면 실제 원문/기록에서만 복구한다.
4. 같은 session/campaign의 실제 최신 verified parent 다음 새 저장을 만든다. 최신 적용 rules_version과 전환 이력은 새 저장에 기록하고, 과거 checkpoint·정본 원문/해시는 고치지 않는다. 생성 당시 정본의 규칙판과 진행 규칙판은 달라도 된다. 이미 제출한 attempt는 동결 원문으로 복구하고 최신 진행은 다음 저장에 담는다.
5. 저장 성공은 commit→verify→동일 버전 read-back·내용 대조로 확인한다. 파일 내보내기만 한 것/서버 verified·저장 실패와 미저장 범위를 구별한다. 구판 룰북을 갖고 있어야 저장·재개할 수 있는 구조가 아니다.

## 다른 채팅으로 옮기는 방법

1. 이전 채팅에 `다른 채팅으로 옮길 테니 지금 입력 대기 지점 그대로 저장하고, 검증 결과와 이동표를 줘. 가능하면 비공개 전체 파일 묶음도 내보내 줘.`라고 요청한다. 장면/판정을 강제로 마치지 않는다.
2. 실제 검증된 session/campaign·version/SHA·정본 ID/판본/파일/SHA·rules_version의 이동표를 보관한다. 파일 방식이라면 전체 현재 STATE JSON과 정확한 정본 Markdown·저장 출처/검증 정보가 필요하다. 과거 룰북 파일은 필요하지 않다. 생성 로그/공개 프로필은 전체 세이브가 아니다. 비밀 내용은 공개 저장소에 올리지 않는다.
3. 새 채팅에서 최신 프로젝트 소스와 실제 도구/파일 접근을 준비하고 이동표/파일을 제공한다. `STATE_RESUME으로 이 출처·session·지정 version/SHA의 상태/정본을 복원하고, 현재 소스의 최신 룰북으로 마지막 질문/판정 대기에서 이어 줘. 누락은 지어내지 말고 알려 줘.`라고 요청한다.
4. 첫 응답에서 실제 장소/행동권·마지막 질문/메뉴·수치/실물·말투와 합의가 이어지는지 확인한다. 로드 자체로 시간 경과·재굴림·자원 재소모·보상 재지급을 하지 않는다. 작은 기억까지 보존하는 범위/소유 위치는 [STATE_EXPERIENCE_CONTINUITY](../rules/07-state.md#state_experience_continuity), 쓰기/인계는 [STATE_COMMIT](../rules/07-state.md#state_commit)/[STATE_RESUME](../rules/07-state.md#state_resume)이 담당한다.
5. 서버 저장 실패면 마지막 실제 verified 시점과 이후 미저장 범위를 확인한다. 지원되는 완전한 로컬 파일을 따로 보존하며 로컬 원문 확인을 서버 verified로 표시하지 않는다. 현재 남은 진행을 과거 저장으로 덮지 않는다.

JSON 구조/해시와 의미 비교는 이미 담긴 사실을 확인한다. 이전 채팅에서 기록되지 않았거나 유실된 기억, 새 AI의 말투/서술 적용까지 자동 보장하지 않는다. 내부 추론 대신 실제 발언·확인된 결론/행동·출처/인지자를 저장한다.
