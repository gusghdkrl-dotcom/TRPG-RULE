# Clara archive — 개발용 호출 계약 v1

> 대상: `dev/time-agent-hq` / Supabase `trpg-time-agent-dev` ONLY. 운영 프로젝트에 적용하지 말 것. 이 문서의 예시는 모두 테스트 데이터이며 실제 현지 원작 정본이 아님. 기획 근거: `TIME_AGENT_CONCEPT_DRAFT.md` §26, §28–29.

## 1. 원본과 책임

- **현지 세계의 진실**: 불변 비공개 정본(`trpg_private.gm_canon_documents`) 및 실제 `verified` 체크포인트(`public.gm_checkpoint_history`). 기존 확정 죽음·피해·구조·철수 결과를 클라라 기록에서 재계산하거나 덮어쓰지 않는다.
- **본부/클라라의 영구 기억**: `trpg_hq.hq_clara_observations`과 `hq_clara_releases` 별도 원장. 이미 확인한 세계/현지 사람의 삶은 원래 출처에 연결된다.
- **NPC 지식**: 클라라가 알 수 있는 자료만 등록. 다른 본부 NPC에게 이 자료가 자동 전달되지 않음. 플레이어에게 공개될 정보와 본부 내부 정보 분리.
- **본부 시간**: 기록/조회/질문 대기는 자동 시간 +0분. 귀환 +4320분은 해당 `return_segment`이 한 번 처리한 값만 사용. 현지 세계의 시각·일수를 본부 경과 분으로 치환하지 않음.

## 2. 소스 구분

| 종류 | 입력 | DB가 확인하는 것 | 플레이어에게 설명하는 방식 |
|---|---|---|---|
| `verified_field` | `source_path`, `source_value`, `segment_id` | 그 구간의 검증 세이브 SHA/버전 및 해당 JSON 경로의 **정확히 동일한 값** | "현지 검증 기록에는 이렇게 남아 있어요" |
| `later_report` | `source_reference`, `source_method`, `source_excerpt` 및 실제 관측 사실 | 출처 표기 존재와 귀환 후 실제 접수 시각 `received_hq_minute`이 본부 시간 이하인지 | "이 시점에 접수된 자료에는 이렇게 기록돼 있어요" |

**제약:** 서버는 `later_report` 문서/기계/관측자의 진위를 독립 확인하지 못한다. 실제 관측 수단·전달 경로·시점·인과가 성립했는지 키퍼가 먼저 확인해야 하며, 존재하지 않는 자료를 만들어 `source_reference`를 채우면 안 된다. 데이터베이스의 `attributed_report`는 '자료가 제시되었다'는 표지이지 절대적 진실 확정 표시가 아니다.

**필드 출처**도 JSON 경로의 정확한 값만 서버 검증한다. `summary`/인과/평가는 SQL이 의미적으로 증명할 수 없으므로 원래 기록을 왜곡해서는 안 된다. 특히 `alive=true`만으로 이후 생업·관계까지 입증된 것이 아니다.

## 3. 저장 구조

- `hq_clara_observations`: `team_id`, `segment_id`, 고유 `record_key`, `subject_kind`(`synchronized_pc`/`field_npc`/`place`/`organization`/`community`/`world`/`threat`), `subject_id`, `subject_label`, `topic`, `world_time_label`, `received_hq_minute`, `finding`, `summary`, 출처 메타와 접근 경계. 기록은 **수정/삭제 금지; 새로운 관측은 새 레코드 추가**.
- `hq_clara_releases`: 플레이어가 실제 질문하여 공개한 원문, 질문자 UUID, 공개 시점과 고유 이벤트. 이미 공개한 동일 기록의 재확인은 별도 새 공개가 아니라 기존 결과.
- `access_level='internal'`: 클라라 내부 자료. 토픽 목록에도 나오지 않으며 직접 공개 함수 호출도 차단.
- `access_level='available'` + `listable=true`: 플레이어에게 '어떤 자료가 있는지' 제목만 제공 가능. 상세 기록은 **실제 질문 후** 공개 이벤트가 있어야 열람 가능.
- `access_level='available'` + `listable=false`: 단순 목록에는 표시되지 않지만, 플레이어가 해당 주제/대상에 접근하여 클라라가 공개하기로 결정한 경우 선택적으로 공유할 수 있는 기록.
- 한 번 플레이어에게 공개된 정보는 해당 파티의 공통 공개 지식. 이것이 다른 본부 직원의 자동 지식 공유를 뜻하지 않음. **현재 활성 팀원**만 목록/열람/공개 가능.

## 4. 실제 호출 순서

1. 임무 실제 종결 및 현지 `trpg_v2_commit → verify → load_version` 확인, `confirm_segment_terminal → return_segment`가 정상 처리되었는지 확인.
2. 클라라에게 진짜로 닿은 출처가 있을 때만 `trpg_hq.clara_record(p_team_id uuid,p_segment_id uuid,p_record_key text,p_expected_revision bigint,p_detail jsonb)` 호출.
3. 플레이어가 클라라의 기록실을 탐방하며 확인을 요청하면 `trpg_hq.clara_catalog(p_team_id uuid,p_player_id uuid)`로 **목록 공개 적격 주제만** 조회.
4. 실제 질문/요청 후 `trpg_hq.clara_release(p_record_id uuid,p_player_id uuid,p_expected_revision bigint,p_question_text text)`를 호출하여 공개를 1회 기록.
5. 공개된 본문은 `trpg_hq.clara_read_shared(p_team_id uuid,p_player_id uuid,p_subject_id text default null)`에서 반환. 같은 기록을 다른 채팅에서 다시 조회해도 기존 출처/내용/시각 유지.
6. 플레이어와 클라라 사이의 새로운 중요한 대화·약속·갈등·연구 후속은 별도 `trpg_hq.record_event`로 실제 참석자/청취자/시간/기억 변경을 기록. 기존 공개한 과거 기록을 뒤집거나 재작성하지 않음.

호출 전 `load_team`에서 현재 `revision`, 현지 임무 연결, 본부 시각을 다시 확인할 것. 같은 `record_key`+동일 입력의 재요청은 재적용하지 않으며, 같은 키+다른 입력은 거부. 본부 변화는 최신 `revision`을 사용해 오래된 스냅샷 덮어쓰기 방지.

### `clara_record` 상세 JSON 예시 (테스트용)

```json
{
  "subject_kind": "synchronized_pc",
  "subject_id": "P1",
  "subject_label": "현지 동기화 인물 P1",
  "topic": "종결 당시 생존 상태",
  "source_kind": "verified_field",
  "world_time_label": "현지 세계의 검증 종료 시점",
  "received_hq_minute": 4365,
  "source_path": ["pcs", "P1", "alive"],
  "source_value": true,
  "finding": true,
  "summary": "검증된 체크포인트에서 P1의 alive=true를 확인",
  "access_level": "available",
  "listable": true
}
```

위 JSON의 `received_hq_minute` 값은 실제 해당 팀의 DB 시간과 종료 귀환 경계가 맞아야만 통과한다. 예제 수치를 실제 캠페인에 복사하지 말 것.

## 5. 테스트 통과 및 제한

개발용 가상 대사건 종료 세이브를 기준으로 다음을 확인했다.

- 실제 `pcs.P1.alive=true`와 동일한 값은 저장 허용; 반대인 `false`를 현지 검증값으로 주장하면 거부.
- 동일 `record_key` 반복은 `applied:false`, 중복 생성·시간 증가 없음.
- 가상 후속 보고는 `attributed_report`로 구분 저장, 미래의 본부 시각으로 접수하려는 기록은 거부.
- 열람 전: 주제 목록은 공개 허용한 것만, 본문 열람은 0건. 내부 기록 직접 공개/다른 팀 참가자의 요청 거부.
- 열람 후: 공개된 3개 레코드만 재조회 가능, 내부 자료 1개는 여전히 비공개. 공개 요청 재시도는 중복 이력 없음.
- 원본 관측 기록 UPDATE / 공개 이력 DELETE 및 내부 자료 직접 INSERT 공개를 DB 트리거에서 거부.
- 팀원을 임시 탈퇴 처리한 상태에서 목록·본문·공개 요청을 거부하고, 테스트 종료 전에 원래 활성 상태로 복구.
- 전체 기록 저장 수·본부 시각은 별도 검증. 공개 질문만으로 시간 경과 없음.
- **아직 실제 원작 세계의 후속 관측 도구나 자동 외부 관측 서버는 없다.** 기록과 정본의 인과적 생성/후속 관측은 룰북 및 실제 플레이로 연결될 때 완성된다. 진짜 NPC의 이후 삶/다섯 후일담, ChatGPT 테스트 프로젝트의 라이브 호출 검증은 미완료.

## 6. 보안

- `trpg_hq`는 일반 `anon`/`authenticated`에서 직접 사용/조회/실행 불가. RLS 활성.
- `hq_events`에는 미공개 자료 원문을 중복 저장하지 않고 내부 기록 ID 등 제한된 메타데이터만 남긴다.
- 정식 플레이어 UI에 권한 있는 서버의 **전체`load_team`/내부 테이블 원문을 무조건 보여주지 말 것**. 실제 질문·시점·공개경계가 확인된 결과만 출력.
- 회원 UUID/팀권한은 실제 연결 계정에 연계하여 별도 검증해야 하며, 입력한 UUID 문자열만으로 사용자를 인증했다고 주장하지 않는다.
- 운영 프로젝트 복제·운영 DB 적용·`main` 병합은 모두 미실행.
