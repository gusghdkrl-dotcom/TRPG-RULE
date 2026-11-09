# 상태·저장·재개 흐름

현행 실행 정본은 rules/07-state.md다. 2026-11-09부터 인증된 새 Supabase `trpg-state-v2` (project ref `taoaffdyssqtnjszumpq`)의 `public.gm_checkpoint_history` verified 원문을 사용한다. 서버 스키마는 `TRPG_STATE_V2`, 저장모드는 DOCUMENT_BOUND(DB1)이며, 개발/이전 검증기를 복사하지 않았다. 실제 설치 SQL은 [trpg-state-v2.sql](sql/trpg-state-v2.sql)이다.

1. 실제생성/로드한정본과누적상태에서현재작업범위를구성한다.
2. 결과가생길때해당현재값과이야기/인물/장면의연결만갱신한다.변화없는전체정보를매번다시쓰지않는다.
3. 저장전원래작업상태에서중요값/관계/출처/입력대기/재개문맥의기준을고정한다.
4. DB1은정확한canon_ref+누적delta/신규/취소/처리event+PC/실행/재개문맥의별도payload를구성한다.현재상태를축소하지않는다.
5. 동결원문·SHA·session/version/event/attempt/parent로 `trpg_v2_commit`→`trpg_v2_verify`→`trpg_v2_load_version`의 같은 version exact read-back. 사용 가능한 인증된 고권한 Supabase 연결에서만 호출하며 공개 API 권한을 열지 않는다.
6. 같은정본과실제read-back으로논리상태를재구성해고정기준과비교한다.등록된값비교와서사문맥충분성/첫장면적용은별도확인한다.
7. 로드는첫지문전에이야기흐름·NPC말투/태도/이유·현재대화/마지막질문/준비/확인된의미·수치/행동대기를함께적용한다.

주기: setup_bootstrap/play_start/30배수안전경계/전체종료+명시수동.기존20턴정본재독은별도이며겹친원문은재사용한다.공개수첩전송은없다.현재상태가남아있는저장실패는플레이를막지않고원문/미저장변경을보존한다.외부차단·상태유실·호환실패를구분한다.현재작업공간/실제서버계약이없는영구메모리는가정하지않는다.

신규 Supabase에서 합성2버전의 실제 commit/verify/exact read-back/SHA·부모충돌·동일attempt·일반접근권한을 검증했다. 실제 비공개 캠페인 정본 파일 원문SHA/절 병합·GitHub 백업왕복·장기 ChatGPT 재현품질은 여전히 미검증이다. 서버 verified가 의미/서사 연속성 완성을 뜻하지 않는다.
