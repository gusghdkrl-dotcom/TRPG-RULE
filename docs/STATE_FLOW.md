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
7. 로드는첫지문전에이야기흐름·NPC말투/태도/이유·현재대화/마지막질문/준비/확인된의미·수치/행동대기를함께적용한다.

신규 rules_version은 배포 RULESET.json의 정확한 식별자를 기록한다. ON 종결의 runtime.hq/ending_state·pcs.player_id/alive 계약은 rules/07-state.md의 STATE_CANON_SAVE_BINDING을 따른다. 기존 저장은 변경하지 않는다.

주기: setup_bootstrap/play_start/40배수안전경계/전체종료·본부ON챕터종료+명시수동.기존20턴정본재독은별도이며겹친원문은재사용한다.공개수첩전송은없다.현재상태가남아있는저장실패는플레이를막지않고원문/미저장변경을보존한다.외부차단·상태유실·호환실패를구분한다.현재작업공간/실제서버계약이없는영구메모리는가정하지않는다.

신규 Supabase에서 합성2버전의 실제 commit/verify/exact read-back/SHA·부모충돌·동일attempt·일반접근권한을 검증했다. 실제 비공개 캠페인 정본 파일 원문SHA/절 병합·GitHub 백업왕복·장기 ChatGPT 재현품질은 여전히 미검증이다. 서버 verified가 의미/서사 연속성 완성을 뜻하지 않는다.
