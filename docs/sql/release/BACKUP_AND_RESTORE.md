# 시간요원 본부 출시 전 운영 DB 백업·복원 (작업자 로컬 절차)

> 현재 상태: **명령/검증기 준비 완료, 실제 데이터 백업·복원 미실행.** 여기의 명령은 운영 DB를 수정하지 않고 파일로 내보낸 뒤 **별개의 새 격리 DB에서만** 복원하기 위한 것이다. ChatGPT 연결에는 DB 전체 덤프·복원 기능이 없으므로 현재 이 단계를 완료한 것으로 간주하지 않는다.
> DB 비밀번호·전체 연결 문자열·백업 파일·원문 정본은 **채팅·GitHub·Actions·이슈·PR에 올리지 않는다**. 개인 보안 저장소에만 보관한다.

## A. 운영 원본과 격리 복원 대상 확인

- 원본: Supabase `trpg-state-v2` (`taoaffdyssqtnjszumpq`). 대상은 **새로운 격리 복원 DB/프로젝트**이며 DEV 테스트 DB `trpg-time-agent-dev`와 운영 원본 모두 대상이 아니다.
- 대상 신규 프로젝트는 비용이 발생할 수 있으므로 생성·요금 동의는 소유자가 Supabase 대시보드에서 직접 확인한다. 기존 프로젝트를 빈 DB라고 가정해 재사용하지 않는다.
- [Supabase 공식 Backup and Restore 안내](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore)에 따라 Supabase CLI, Docker Desktop, `psql`을 설치하고 각 명령의 `--help`·버전을 점검한다.
- 작업 시 운영 PC·GitHub에는 패치/운영 쓰기를 하지 않는다. 운영 게임을 사용하는 도중 새 기록이 들어오면 **백업 시점 이후의 변경**은 별도로 정합성 대조한다.

## B. 독립 파일 3종 + 별도 기록 백업

신뢰 가능한 개인 로컬 셸에서 다음처럼 **저장소 밖**의 권한 제한 폴더를 만든다.

```bash
set -euo pipefail
umask 077
BACKUP_DIR="$HOME/trpg-hq-private-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -m 700 "$BACKUP_DIR"
# OLD_DB_URL은 운영 DB 연결 문자열을 보안 환경변수로 설정한다.
# 값/비밀번호를 명령 이력·로그·채팅에 붙이지 않는다.
```

운영 SQL의 기존 자료를 지문으로 보관한다. **지문은 백업 자체가 아니다.**

```bash
psql --dbname "$OLD_DB_URL" -X -v ON_ERROR_STOP=1 -At \
  -f docs/sql/release/hq_readonly_preflight.sql > "$BACKUP_DIR/original-preflight.json"
```

Supabase 공식 방식으로 분리 덤프를 만든다.

```bash
supabase db dump --db-url "$OLD_DB_URL" -f "$BACKUP_DIR/roles.sql" --role-only
supabase db dump --db-url "$OLD_DB_URL" -f "$BACKUP_DIR/schema.sql"
supabase db dump --db-url "$OLD_DB_URL" -f "$BACKUP_DIR/data.sql" --use-copy --data-only \
  -x "storage.buckets_vectors" -x "storage.vector_indexes"
```

기존 CLI 마이그레이션 9건의 이력도 별도 확보한다.

```bash
supabase db dump --db-url "$OLD_DB_URL" -f "$BACKUP_DIR/history_schema.sql" --schema supabase_migrations
supabase db dump --db-url "$OLD_DB_URL" -f "$BACKUP_DIR/history_data.sql" --use-copy --data-only --schema supabase_migrations
```

산출물이 존재하고 비어 있지 않은지 확인하고 SHA-256 목록을 개인 폴더에 만든다.

```bash
test -s "$BACKUP_DIR/roles.sql"
test -s "$BACKUP_DIR/schema.sql"
test -s "$BACKUP_DIR/data.sql"
test -s "$BACKUP_DIR/original-preflight.json"
(cd "$BACKUP_DIR" && sha256sum roles.sql schema.sql data.sql history_schema.sql history_data.sql > SHA256SUMS)
```

운영의 `public.gm_checkpoint_history`, `trpg_private.gm_canon_documents`, `trpg_private.gm_cleanup_archive`, `trpg_cards.card_catalog`가 `schema.sql`과 `data.sql`에 포함됐는지 확인한다. 운영의 현재 레코드는 시점에 따라 바뀌므로 문서의 과거 숫자를 백업 완료 기준으로 사용하지 않는다.

## C. 완전히 격리된 새 DB에서만 복원

운영과 격리 프로젝트의 실제 ref가 서로 다르고, 격리 DB에 아직 TRPG 원본 테이블이 없는지 **대시보드에서 직접** 확인한다. `NEW_DB_URL`은 반드시 **새 격리 DB** 연결 문자열이어야 한다. 원본과 문자열이 같거나 대상 프로젝트를 확신할 수 없으면 멈춘다.

공식 안내의 `psql` 트랜잭션 복원 흐름:

```bash
test "$OLD_DB_URL" != "$NEW_DB_URL"
psql --dbname "$NEW_DB_URL" --single-transaction -v ON_ERROR_STOP=1 \
  --file "$BACKUP_DIR/roles.sql" \
  --file "$BACKUP_DIR/schema.sql" \
  --command 'SET session_replication_role = replica' \
  --file "$BACKUP_DIR/data.sql"
```

Supabase 버전·역할·확장·Vault 암호화가 다르면 복원이 실패할 수 있다. 에러를 임의 무시하지 말고 공식 문서의 권한/확장·암호화 복원 절차에 따라 **격리 대상에서만** 해결한다. 원본 운영 DB에 복원을 재시도하는 것은 금지한다.

복원에 성공하면 같은 읽기 전용 SQL로 보존 자료를 재조회하고 자동 비교한다.

```bash
psql --dbname "$NEW_DB_URL" -X -v ON_ERROR_STOP=1 -At \
  -f docs/sql/release/hq_readonly_preflight.sql > "$BACKUP_DIR/restored-preflight.json"
python3 scripts/compare_hq_db_baselines.py \
  "$BACKUP_DIR/original-preflight.json" "$BACKUP_DIR/restored-preflight.json"
```

**PASS가 아니면 운영 이식 금지.** 비교기는 원본 정보나 해시값을 출력하지 않고, 변경된 테이블/기능 이름만 출력한다. 원본·복원 JSON은 절대 커밋하지 않는다.

## D. 격리 복원 DB에서 HQ 21단계 시험

- 백업과 복원 검사 **PASS 후에만** `docs/sql/release/README.md`의 본부 21단계 원본 SQL을 순서대로 적용한다. 개발 DB 초기화 5개/기본 카드 bootstrap은 실행하지 않는다.
- 본부 설치 후 `hq_readonly_postflight.sql`을 검사하고, 기존 보호 원장 재조회 결과를 다시 저장한다.
- 기존 자료의 불변성 비교는 아래의 `--after-hq`로 수행한다.

```bash
psql --dbname "$NEW_DB_URL" -X -v ON_ERROR_STOP=1 -At \
  -f docs/sql/release/hq_readonly_preflight.sql > "$BACKUP_DIR/after-hq-preflight.json"
python3 scripts/compare_hq_db_baselines.py \
  "$BACKUP_DIR/original-preflight.json" "$BACKUP_DIR/after-hq-preflight.json" --after-hq
```

## E. 출시 승인 조건

- 독립 파일 백업·SHA-256 목록·격리 DB 복원 기록 확보
- 원본 대 복원 및 본부 설치 후 지문 비교 전부 PASS
- 본부 20개 테이블/43개 함수/8개 NPC 서비스 및 RLS/권한 검사 PASS
- 기존 OFF 게임·원작 현지 저장, ON 신규 입단~귀환·보상·재접속 실제 플레이 검사 PASS
- 모든 검증 후에만 운영 DB 배포 및 GitHub PR #6 `main` 병합

**참고:** 이번 프로젝트의 운영 Storage 버킷/객체, Auth 사용자, Edge Function은 마지막 읽기 조회에서 각각 0건이었지만, 출시 직전 재검사가 필요하다. Storage 파일이 생기면 DB 백업만으로 실제 파일 바이트는 복원되지 않으므로 별도 백업한다.
