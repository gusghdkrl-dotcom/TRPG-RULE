# 본부 NPC 8인 × 요원별 기억·관계 실행 계약 (DEV ONLY)

적용 환경: GitHub `dev/time-agent-hq` / Supabase `trpg-time-agent-dev`. 기존 `main`, `trpg-state-v2`, 기존 게임 세이브에는 적용하지 않음.

근거: `docs/development/TIME_AGENT_CONCEPT_DRAFT.md` §§17,26,28,29,32 및 플레이어의 **클라라 포함 모든 본부 NPC가 요원 A/B에게 별개의 인격적 반응·기억을 가져야 한다**는 확정 요구.

## 저장 소유권

- **NPC 고유 성격·업무 책임·말투**: 원래 본부 세계 정본의 불변 성격. 관계 DB는 고유 성격을 무작위로 교체하지 않음.
- **NPC 공동 생활·일반 상태**: `trpg_hq.hq_actor_states`에 NPC의 위치·공통 작업/시설 정보(개인 요원 기억 제외).
- **클라라의 실제 현지 세계 자료**: `hq_clara_observations`과 공개 이력 `hq_clara_releases`. 팀에 공개한 현지 **사실**은 파티 공통.
- **NPC가 요원 A를 아는 내용/태도**: `hq_npc_agent_relations(team_id,agent_id,npc_key)` 별도 현재값 + `hq_npc_interactions`의 불변 근거.
- **NPC가 요원 B를 아는 내용/태도**: A와 **다른 PK/원장**. 다른 요원의 친밀함·의심·관심사·약속을 자동 복제하지 않음.
- **클라라에게 누가 직접 무엇을 물었는가**: `hq_clara_releases.requested_by/question_text`를 해당 요원 개인 문맥에서만 복원. 동일 공개 기록을 다른 팀원도 읽을 수 있어도 개인 질문·관심·관계는 자동 공유하지 않음.
- NPC↔NPC 개인 관계도 실제 사건/청취 경로로 기록해야 하며 **아직 자동 누적 및 복원 전용 API 미완**.

## 실제 새 개발 테이블/RPC

1. `docs/sql/dev/trpg_hq_phase5_personal_npc_memory.sql`:
   - `hq_npc_agent_relations`: 현재 NPC×요원 관계/지식·변경 근거·수정번호. RLS와 익명 접근 차단.
   - `hq_npc_interactions`: 동일 대화에 참가한 요원, 실제 발화자, 발언별 `heard_by`, 장소, 본부 경과, 각 요원에게 직접 미친 변화와 실제 이유를 보존. 원문 UPDATE/DELETE 금지.
   - `record_npc_interaction(team_id,event_key,expected_revision,payload)`: 사건 키 중복/내용 충돌과 오래된 revision, 팀 미참가 요원·사실상 청취자가 아닌 요원 명시를 검사. 실제 해당 요원에게만 `patch` 반영. 팀 공통 사건 원장에는 개인 발언/관계 원문을 복제하지 않음.
   - `load_npc_agent_context(team_id,npc_key,agent_id)`: 요원별 관계 현재값과 그 요원이 **실제로 들은 발언**만 재구성. `npc:clara`의 경우 개인 `clara_questions`도 함께 제공. **비공개 키퍼 사용용**이며 사용자의 직접 조회 API가 아님.
2. `docs/sql/dev/trpg_hq_phase5b_personal_boundary_guard.sql`:
   - 기존 `record_event`의 NPC 공통 `p_actor_changes`에 `known_facts`·`attitudes`·`relationship` 등 요원별 필드 직접 저장을 거부. 일반 업무 위치 변화는 계속 허용.
   - 신규 `clara_release`에서는 개인 `question_text`와 질문자 ID를 팀 공동 `hq_events.event_data`에 중복 저장하지 않고 개인 공개 원장에만 보관.
   - **기존 개발용 가상 자료에 남은 역사 기록은 소급 삭제/개조하지 않음**. 기존 개인 정보를 담았던 테스트 이벤트는 새 정책의 이전 이력이며 운영 자료와 무관.

### 지원 NPC 키

`npc:martin`, `npc:jayden`, `npc:clara`, `npc:dominic`, `npc:samira`, `npc:leo`, `npc:seorin`, `npc:maya`.

### payload 예시

```json
{
  "npc_key": "npc:clara",
  "present_agents": ["<요원 A 실제 UUID>"],
  "speaker_key": "npc:clara",
  "location": "기록·분석실",
  "summary": "클라라가 A 요원에게 기록의 출처를 설명함",
  "elapsed_minutes": 5,
  "observations": {"source": "실제 대화"},
  "utterances": [
    {
      "speaker": "npc:clara",
      "text": "제가 직접 확인한 기록은 여기까지예요.",
      "heard_by": ["agent:<요원 A 실제 UUID>", "npc:clara"]
    }
  ],
  "changes_by_agent": {
    "<요원 A 실제 UUID>": {
      "basis": "A가 클라라의 설명을 실제로 들음",
      "patch": {
        "known_facts": {
          "archive_limit": "클라라의 현재 관측 자료 한계"
        }
      }
    }
  }
}
```

예제의 A UUID, 발언과 정보는 설명용이며 실제 게임의 발생 사실이 아니다. **NPC 성격·개인적 생각·호감도 변화는 서버가 자동 생성하지 않으며**, 키퍼는 실제 대화·행동·관측 결과로만 `basis`를 작성해야 한다. `changes_by_agent`에 명시하지 않은 다른 요원은 관계 갱신되지 않는다. 단순 입력 대기·PC 교대는 시간 0분.

## 실제 통과한 개발용 실저장/부정 테스트 (2026-11-12)

- 가상 2인 팀을 만들고 같은 클라라 장면에서 A의 현지 인물 안부 질문과 B의 관측법 질문을 각각 저장.
- 두 요원의 클라라 상태가 각각 다른 레코드로 분리됐고 `load_npc_agent_context`에는 **실제 들은 대사만** 각 2개씩 반환됨. 다른 요원 전용 대사는 반환되지 않음.
- A만 참여한 후속 대화에서는 A의 관계 revision 1→2, A의 대화 사건 1→2; **B revision 1, 대화 사건 1, A의 새 개인 관심 null** 그대로 유지.
- 다른 NPC 마틴과 A의 면담 저장 시 `npc:martin × A` 관계만 생성되고 `npc:martin × B`는 revision 0. 추가로 제이든·도미닉·사미라·레오·서린·마야의 1:1 테스트 원장 6건을 실제 생성하여 **8종의 NPC 키** 모두 같은 분리 메커니즘에서 동작.
- 기존 클라라 공개 이력에서 해당 요원의 개인 질문 **3건**을 `load_npc_agent_context(npc:clara)`에 복원하는 것 확인(이후 추가 개인 질문 1건은 별도 검증).
- 동일 event_key 재실행: 중복 변화/시간 없음. 동일 키 다른 payload / 미참석자 관계 변경 / 미참석자 발언 청취 처리 / 오래된 revision / 과거 대화 원문 수정 모두 거부. 팀 시간은 실제 대화 12+3+1=16분, 일상 테스트 0분 대화는 시간 증가 없음.
- 기존 `record_event`의 공통 NPC `known_facts` 주입 거부, 일반 위치 갱신 유지. 새 클라라 질문 공개의 공동 event_data에 `question_text`와 `requested_by`가 없는 것 확인; 질문 원문은 개인 공개 기록에 있음.
- `anon`은 신규 관계 테이블 SELECT와 개인 문맥 함수 EXECUTE 불가.

## 클라라: 이미 공개된 같은 자료에 대한 A/B 각각의 추가 질문

원래 `clara_release(record_id,player_id,revision,question)`는 **자료 1건에 최초 공개 이력 1건만** 기록한다. A에게 먼저 공개된 자료에 B가 다시 질문하거나 A가 다른 이유로 추가 질문한다면, 사실 공개를 다시 발행하지 않더라도 **개인 질문은 별도로 기록해야 한다**.

- `docs/sql/dev/trpg_hq_phase5c_clara_repeat_personal_questions.sql` 추가 마이그레이션으로 `hq_clara_followup_questions`와 `clara_record_followup_question(record_id,requested_by,question_key,expected_revision,question_text)`를 구현.
- 미공개 자료 최초 질문은 기존 `clara_release`로 출처/공개 경계를 확인하고 첫 질문 원문·질문자 UUID 저장. **이미 팀에 공개된 자료에 대한 새로운 실제 질문은 `clara_record_followup_question`**으로 고유 `question_key`를 부여해 기록. 새 질문을 했다는 사실만으로 이전 공개 자료를 다시 제공하거나 보상 지급/시간 증가 없음.
- `load_npc_agent_context(npc:clara,agent_uuid)`의 `clara_personal_questions`은 최초 공개 질문 + 추가 개인 질문을 해당 요원 기준으로만 합친다. 이웃한 다른 요원의 질문은 자동 포함하지 않는다. 같은 질문을 반복 확인한 것이 아니라 **실제 새로운 질문이라면** 새 `question_key`여야 한다.
- 팀 공동 `hq_events`에는 개인 질문 문구와 질문자 UUID를 넣지 않는다. 개인 질문 원문은 원래 `hq_clara_releases`와 새 `hq_clara_followup_questions`에만 보관. 불변/비공개·현재 활성 팀원 제한.
- 실저장 검증: A 요원의 4건 최초 공개 질문+1건 별도 추가 질문=**5건** 개별 문맥 복원. 같은 `question_key` 재요청은 `applied:false`. 임시 B가 동일 기록을 다른 이유로 새 질문하는 시뮬레이션에서는 **B의 개인 이력 1건, A는 여전히 5건**이었고 시험 내역/임시 참가자는 트랜잭션 롤백으로 정리.
- 잘못된 동일 키 다른 질문/다른 팀 소속 요원 접근/과거 추가 질문 원문 UPDATE 모두 거부. 공동 사건의 질문문·질문자 누출 0건, 질문만으로 본부 시간 추가 0분.
- 질문을 보고 클라라의 신뢰/호감이 무조건 오르지 않는다. 실제 대화로 관계가 변했다면 별도 `record_npc_interaction`에 **실제 이유와 청취자**를 기록해야 한다. 같은 장면의 경과 시간을 양쪽 RPC에서 중복 반영하지 않는다.

## **중요한 미완료/이식 차단 항목**

1. **실제 ChatGPT 키퍼와 연결 테스트 미실행**: 새 테스트 프로젝트에서 대화 직전에 `load_npc_agent_context`를 권한 있는 경로로 불러오고 A/B 별 말투·반응을 생성하는 실제 게임 테스트 필요. DB 저장 경로만으로 'NPC가 자동으로 알아서 반응'한다고 주장하면 안 됨.
2. **인증**: 함수 인자 `agent_id`는 기록 식별에 사용되지만 임의 UUID를 호출자가 진짜 소유한다는 인증이 아님. 현재 비공개 서버 실행/익명 접근 차단. 신원·권한 확인을 갖춘 게임 키퍼 도구 흐름 필요.
3. **기존 자유형 공통 사건`record_event`의 `summary`/`event_data` 및 팀`current_state`에 개인 정보가 임의로 기록될 우회 경로**. 특정 관계 필드의 common NPC patch만 차단한 상태이므로 모든 비공개 표현을 서버 차원에서 차단했다고 주장하지 않음. 향후 별도 공개 투영/API와 입력 계약 세분화 필요.
4. **NPC의 실제 지식 경계**: DB가 `basis` 내용의 인과적 진실이나 발언자/청취자의 현장 위치를 독립 검증하지 못한다. 현장 장면·NPC 지식과 사건의 실제 관찰 범위를 키퍼가 검증해야 함.
5. **다인 팀 정보 공개 정책**: 공동 공개된 세계 사실은 파티에 공개 가능하지만, 개인 질문·관계 이유·민감한 대화는 별도. 같은 방에서 들었는지, 사적으로 들었는지 결정할 실제 장면의 정보와 저장 필드를 연결.
6. **아카이브 과거 시험 이벤트**는 5차 이전에 일반 event_data에 질문을 기록해 둔 테스트 데이터가 존재할 수 있으므로 운영 이식 전에 유실/누출 없는 새 데이터로 회귀 시험. 기존 운영 세이브·NPC 자료와 혼합 금지.
7. **NPC ↔ NPC 관계**: 실제 만남/의견 충돌/공동 업무도 같은 근거 기준으로 누적해야 함. 현재 개인 NPC×요원 테이블만 구현.
8. **연대기 특별 완주 공적·훈장/특별 A/B 지급 및 첫 정식 요원 인증**은 다음 작업. 임의 상위 계급 포인트·컷을 도입하지 말 것.
