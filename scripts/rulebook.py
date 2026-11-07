#!/usr/bin/env python3
"""Validate the current document set and export only game-facing sources."""
from __future__ import annotations
import argparse, json, re, shutil, zipfile
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

def validate():
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
    if len(instructions)>7800:
        errors.append('Project Instructions exceeds 7,800 Unicode characters')
    migration=json.loads((ROOT/'docs/rule-migration.json').read_text())
    if len(migration)!=403 or len({row['original_id'] for row in migration})!=403:
        errors.append('Original 403-block inventory incomplete or duplicated')
    for row in migration:
        dest=row['destination']
        if dest=='—':continue
        rid=dest.partition('#')[2].upper() if '#' in dest else dest
        if rid not in ids: errors.append(f'Migration target missing: {row["original_id"]} -> {dest}')
    required={'WORLD_PC_INPUT','STATE_AUTHORITY','STATE_SCHEMA','STATE_INTEGRITY','STATE_CADENCE','STATE_COMMIT','STATE_RECOVERY','STATE_RESUME','CORE_AGENCY','CORE_VISIBILITY','HOMAGE_DRAFT_SELECTION','PC_DERIVED_STATS','SKILL_IMPROVEMENT','CHRONICLE_SPECIALTY_DEVELOPMENT_EXCEPTION','NOTEBOOK_WATCHER_RUNTIME_SINGLE_WRITER'}
    if required-ids.keys():errors.append(f'Missing essential rules: {sorted(required-ids.keys())}')
    # These cross-system dependencies are checked against the current authoritative sections.
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
    if errors:raise SystemExit('\n'.join(errors))
    print(f'PASS: {len(ids)} unique rules; {len(migration)} original blocks accounted for; {len(checks)} semantic guard groups; UTF-8, links, code fences, removed features and instruction length')
    return ids

def export():
    ids=validate()
    target=ROOT/'build/project-pack'
    if target.exists():shutil.rmtree(target)
    (target/'sources').mkdir(parents=True)
    for path in RULES.glob('*.md'):shutil.copyfile(path,target/'sources'/path.name)
    for name in ['PROJECT_INSTRUCTIONS.md','START_GAME.md']:shutil.copyfile(ROOT/name,target/name)
    (target/'UPLOAD_GUIDE.txt').write_text('PROJECT_INSTRUCTIONS.md → 프로젝트 지침\nsources/*.md → 최신 프로젝트 소스\nSTART_GAME.md → 시작할 때 채팅에 입력\n기존 TXT·구판·개발 일지·감사 문서는 소스에서 제외하세요.\nSupabase 커넥터 연결과 실제 저장 검증은 별도입니다.\n')
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
    ap=argparse.ArgumentParser();ap.add_argument('action',choices=['check','export','stats']);a=ap.parse_args()
    {'check':validate,'export':export,'stats':stats}[a.action]()
