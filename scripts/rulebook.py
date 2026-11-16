#!/usr/bin/env python3
"""Validate the current document set and export only game-facing sources."""
from __future__ import annotations
import argparse, hashlib, json, re, shutil, zipfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / 'rules'

def registry():
    result = {}
    for path in sorted(RULES.glob('*.md')):
        for rid in re.findall(r'^## ([A-Z][A-Z0-9_]+)$', path.read_text(encoding='utf-8'), re.M):
            if rid in result:
                raise ValueError(f'Duplicate rule ID: {rid}')
            result[rid] = path
    return result

def sources():
    return [ROOT/'PROJECT_INSTRUCTIONS.md', ROOT/'START_GAME.md', *sorted(RULES.glob('*.md'))]

def release_identity():
    """Identify exact game source bytes without a self-referential source hash."""
    digests = {
        ('sources/'+p.name if p.parent == RULES else p.name): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in sources()
    }
    encoded = json.dumps(digests, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode('utf-8')
    digest = hashlib.sha256(encoded).hexdigest()
    return {'rules_version': 'TRPG-RULE-2026-11-17+sha256:'+digest,
            'source_sha256': digest, 'source_files': digests,
            'digest_format': 'SHA-256 of UTF-8 JSON source_files; sorted keys; ensure_ascii=false; separators=comma,colon'}

def validate(*, semantic_checks=True):
    errors = []
    ids = registry()
    for path in sources():
        text = path.read_text(encoding='utf-8', errors='strict')
        if '\\n' in text:
            errors.append(f'{path.name}: literal escaped newline')
        if re.search(r'<(?:/?SYSTEM_LOCK|/?SYS_RULE|/?SYS_DIRECTIVE)|\bDOC:\d', text):
            errors.append(f'{path.name}: obsolete routing markup')
        if re.search(r'(?i)\bMP\b|arcana|장착 퍽|프레스티지|환생|survival_state|Survival ON|Survival OFF',text):
            errors.append(f'{path.name}: removed feature in active instructions')
        if re.search(r'붙들고 있는 것|연기 앵커|역할극 참고|Holding Anchor|Roleplay Expression',text):
            errors.append(f'{path.name}: retired profile category in active instructions')
        if text.count('```') % 2:
            errors.append(f'{path.name}: unclosed fenced block')
        for url in re.findall(r'\]\(([^)]+)\)', text):
            if re.match(r'\w+://',url):
                continue
            name, _, anchor = url.partition('#')
            target = (path.parent/name).resolve() if name else path
            if not target.is_relative_to(ROOT) or not target.is_file():
                errors.append(f'{path.name}: missing link {url}')
            elif anchor and anchor not in {rid.lower() for rid,p in ids.items() if p==target}:
                errors.append(f'{path.name}: missing rule anchor {url}')
    instructions = (ROOT/'PROJECT_INSTRUCTIONS.md').read_text()
    start_text = (ROOT/'START_GAME.md').read_text()
    index_text = (ROOT/'rules/00-index.md').read_text()
    if len(instructions)>7800:
        errors.append('Project Instructions exceeds 7,800 Unicode characters')
    if len(start_text)>7800:
        errors.append('Start Game instructions exceeds 7,800 Unicode characters')
    routes=re.findall(r'^\| (\d{2}-[a-z-]+\.md) \| (.+) \|$',instructions,re.M)
    expected_routes={p.name for p in RULES.glob('*.md')}
    if len(routes)!=len(expected_routes) or {name for name,_ in routes}!=expected_routes:
        errors.append('Project Instructions must route every current rulebook file exactly once')
    for name,route in routes:
        for rid in re.findall(r'\b[A-Z][A-Z0-9_]+\b',route.partition(':')[2]):
            if ids.get(rid)!=RULES/name:
                errors.append(f'Project Instructions: routing target {rid} does not belong to {name}')
    migration=json.loads((ROOT/'docs/rule-migration.json').read_text())
    if len(migration)!=403 or len({row['original_id'] for row in migration})!=403:
        errors.append('Original 403-block inventory incomplete or duplicated')
    for row in migration:
        dest=row['destination']
        if dest=='—':continue
        rid=dest.partition('#')[2].upper() if '#' in dest else dest
        if rid not in ids: errors.append(f'Migration target missing: {row["original_id"]} -> {dest}')
    required={'WORLD_PC_INPUT','SCENARIO_BLUEPRINT','FINAL_THREAT_DESIGN','STATE_AUTHORITY','STATE_SCHEMA','STATE_INTEGRITY','STATE_CADENCE','STATE_COMMIT','STATE_RECOVERY','STATE_RESUME','STATE_EXPERIENCE_CONTINUITY','CORE_AGENCY','CORE_VISIBILITY','HOMAGE_DRAFT_SELECTION','PC_DERIVED_STATS','SKILL_IMPROVEMENT','BOTTOM_HUD_CONTRACT','OPTIONAL_POST_CREDITS_VIEWS'}
    if required-ids.keys():errors.append(f'Missing essential rules: {sorted(required-ids.keys())}')
    # The integrated edition accounts for every ID of its 361-rule parent.
    # Removed/merged features cannot silently return through stale routing text.
    reorganization=json.loads((ROOT/'docs/rule-reorganization.json').read_text())
    previous={row['previous_id'] for row in reorganization}
    if len(reorganization)!=361 or len(previous)!=361:
        errors.append('Previous 361-rule reorganization inventory incomplete or duplicated')
    for row in reorganization:
        dest=row['destination']
        if row['action'] not in {'수정','통합','삭제'}:
            errors.append(f'Unknown reorganization action: {row["previous_id"]}')
        if dest!='—' and dest not in ids:
            errors.append(f'Reorganization target missing: {row["previous_id"]} -> {dest}')
        if dest=='—' and row['action']!='삭제':
            errors.append(f'Unexplained rule removal: {row["previous_id"]}')
    retired=previous-ids.keys()
    for path in sources():
        text=path.read_text()
        for rid in sorted(retired):
            if re.search(r'\b'+re.escape(rid)+r'\b',text):
                errors.append(f'{path.name}: retired rule still routed: {rid}')
    if (RULES/'09-notebook.md').exists():
        errors.append('Public notebook source must not be shipped')
    catalog=(ROOT/'docs/RULE_CATALOG.md').read_text()
    if set(re.findall(r'^\| ([A-Z][A-Z0-9_]+) \|',catalog,re.M))!=ids.keys():
        errors.append('Rule catalog does not match active registry')
    # These cross-system dependencies are checked against the current authoritative sections.
    checks = []
    if semantic_checks:
        checks=json.loads((ROOT/'docs/validation-contract.json').read_text())
        for check in checks:
            rid=check['rule']
            if rid not in ids:
                errors.append(f'Contract rule missing: {rid}');continue
            body=ids[rid].read_text().split('## '+rid+'\n',1)[1].split('\n## ',1)[0]
            for fragment in check.get('contains',[]):
                if fragment not in body:errors.append(f'{rid}: missing invariant {fragment}')
            for fragment in check.get('excludes',[]):
                if fragment in body:errors.append(f'{rid}: obsolete/conflicting text {fragment}')
            # Critical play reminders must survive edits to the always-on instructions.
            for fragment in check.get('instruction_contains',[]):
                if fragment not in instructions:errors.append(f'Project Instructions: missing {rid} reminder {fragment}')
            for fragment in check.get('instruction_excludes',[]):
                if fragment in instructions:errors.append(f'Project Instructions: obsolete {rid} reminder {fragment}')
            for fragment in check.get('start_contains',[]):
                if fragment not in start_text:errors.append(f'START_GAME: missing {rid} entrypoint {fragment}')
            for fragment in check.get('start_excludes',[]):
                if fragment in start_text:errors.append(f'START_GAME: conflicting {rid} entrypoint {fragment}')
            for fragment in check.get('index_contains',[]):
                if fragment not in index_text:errors.append(f'00-index: missing {rid} router {fragment}')
            for fragment in check.get('index_excludes',[]):
                if fragment in index_text:errors.append(f'00-index: conflicting {rid} router {fragment}')
            order=check.get('instruction_order',[])
            if order:
                positions=[instructions.find(fragment) for fragment in order]
                if (len(set(order))!=len(order)
                        or any(instructions.count(fragment)!=1 for fragment in order)
                        or positions!=sorted(positions)):
                    errors.append(f'Project Instructions: missing, duplicated or reordered {rid} execution sections')
    if errors:raise SystemExit('\n'.join(errors))
    mode = f'{len(checks)} semantic guard groups' if semantic_checks else 'structural integrity only (semantic checks opt-in)'
    print(f'PASS: {len(ids)} unique rules; {len(migration)} original blocks and {len(reorganization)} parent IDs accounted for; {mode}; UTF-8, links, code fences, retired routing, catalog and instruction length')
    return ids

def check():
    return validate(semantic_checks=False)

def export():
    ids=validate(semantic_checks=False)
    target=ROOT/'build/project-pack'
    if target.exists():shutil.rmtree(target)
    (target/'sources').mkdir(parents=True)
    for path in RULES.glob('*.md'):shutil.copyfile(path,target/'sources'/path.name)
    for name in ['PROJECT_INSTRUCTIONS.md','START_GAME.md']:shutil.copyfile(ROOT/name,target/name)
    identity = release_identity()
    (target/'RULESET.json').write_text(json.dumps(identity,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    # A readable copy helps project-source retrieval when JSON is not indexed.
    # Metadata stays outside the 12 hashed sources, avoiding a self hash cycle.
    (target/'RULESET.md').write_text(
        '# 현재 룰북 배포 식별자\n\n'
        f"rules_version: `{identity['rules_version']}`\n\n"
        '같은 ZIP의 RULESET.json과 동일한 메타데이터입니다. 게임 정본/세이브가 아닙니다.\n'
        '신규 정본과 기존 저장 계약의 rules_version에 이 실제 식별자를 사용합니다.\n'
        '기존 캠페인은 당시 판본으로 재개하고 날짜 표제만으로 구판을 바꾸지 않습니다.\n'
        'SHA256.json으로 실제 소스 일치를 확인하고 혼합 파일/미확인은 검증 완료로 표시하지 않습니다.\n',
        encoding='utf-8')
    # HQ portraits are official fixed assets, not new AI-generated profiles.
    # Verify all eight original PNG bytes before the release archive is constructed.
    npc_manifest = ROOT/'assets/hq-npc/manifest.json'
    if npc_manifest.exists():
        import hashlib
        asset_root = (ROOT/'assets/hq-npc').resolve()
        data = json.loads(npc_manifest.read_text(encoding='utf-8'))
        entries = data.get('assets', [])
        if len(entries) != 8 or len({item['npc_id'] for item in entries}) != 8:
            raise SystemExit('HQ portrait manifest must contain eight unique NPC identities')
        for item in entries:
            source = (ROOT/item['file_path']).resolve()
            if not source.is_relative_to(asset_root) or not source.is_file():
                raise SystemExit(f"HQ portrait missing or outside asset directory: {item['npc_id']}")
            if hashlib.sha256(source.read_bytes()).hexdigest() != item['sha256']:
                raise SystemExit(f"HQ portrait SHA-256 mismatch: {item['npc_id']}")
            destination = target/item['file_path']
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)
        shutil.copyfile(npc_manifest,target/'assets/hq-npc/manifest.json')
    (target/'UPLOAD_GUIDE.txt').write_text('PROJECT_INSTRUCTIONS.md → 프로젝트 지침에 복사\nsources/*.md → 00-index~09-cards의 10개 최신 소스로 교체\nassets/hq-npc/* → 시간본부 NPC 공식 이미지 8장과 manifest.json (ON 전용)\nSTART_GAME.md → 새 게임 준비 때 채팅에 입력\nRULESET.json + RULESET.md → 같은 ZIP에서 함께 프로젝트 소스로 등록; JSON 조회 불가 시 읽기용 Markdown의 실제 식별자를 확인\n신규 저장의 기존 rules_version에 정확한 식별자를 기록\nSHA256.json → 배포 파일 바이트 검증; RULESET.json의 source_files는 실행 소스 12개를 식별\nGitHub main 수정은 이미 업로드된 프로젝트 파일/이전 채팅을 자동 교체하지 않습니다.\n구판 룰북·09-notebook·개발/감사 문서는 게임 소스에서 제외하세요.\n실제 캠페인 비공개 정본과 세이브는 별도 보존하세요. 기존 캠페인은 새 설정 대신 STATE_RESUME으로 복원하고 과거 rules_version을 바꾸지 마세요.\n독립 재시험은 새 campaign/session·새 정본/최초 STATE를 만들고 옛 테스트 세이브를 자동 로드하지 않습니다.\n실제 도구 지원·Supabase 계약/저장 검증은 별도이며 룰북만으로 기능이 생기지는 않습니다.\n')
    manifest={str(p.relative_to(target)):__import__('hashlib').sha256(p.read_bytes()).hexdigest() for p in sorted(target.rglob('*')) if p.is_file()}
    (target/'SHA256.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    archive=ROOT/'dist/TRPG-RULE-project.zip'
    archive.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(target.rglob('*')):
            if p.is_file():
                # Fixed metadata keeps identical sources identical across exports.
                info=zipfile.ZipInfo(p.relative_to(target).as_posix(),date_time=(1980,1,1,0,0,0))
                info.compress_type=zipfile.ZIP_DEFLATED
                info.create_system=3
                info.external_attr=0o100644 << 16
                z.writestr(info,p.read_bytes())
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None:raise SystemExit('Exported ZIP failed integrity check')
        for name,digest in manifest.items():
            if __import__('hashlib').sha256(z.read(name)).hexdigest()!=digest:
                raise SystemExit(f'Exported ZIP hash mismatch: {name}')
    shutil.copyfile(archive,ROOT/'build/TRPG-RULE-project.zip')
    print(f'Exported {archive}; {len(manifest)} files + manifest')

def stats():
    baseline=json.loads((ROOT/'docs/baseline.json').read_text())
    current=sum(len(p.read_text()) for p in sources())
    print(json.dumps({'original_characters':baseline['characters'],'current_game_documents_characters':current,'reduction_percent':round((1-current/baseline['characters'])*100,1),'project_instruction_characters':len((ROOT/'PROJECT_INSTRUCTIONS.md').read_text()),'rules':len(registry())},ensure_ascii=False,indent=2))

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('action',choices=['check','deep-check','export','stats']);a=ap.parse_args()
    {'check':check,'deep-check':validate,'export':export,'stats':stats}[a.action]()
