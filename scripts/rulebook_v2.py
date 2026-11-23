"""Package the MCP v2 edition separately from the legacy rulebook."""
from __future__ import annotations

import hashlib
import json
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT / 'rules-v2'


def sources():
    return sorted(RULES.glob('*.md'))


def check():
    paths = sources()
    required = {'README.md', 'PROJECT_INSTRUCTIONS.md', '00-vision.md',
                '01-source.md', '02-scenario.md', '02a-scenario-example.md',
                '03-characters.md', '04-play.md', '04a-scene-examples.md',
                '05-checks.md', '06-ending.md'}
    missing = required - {p.name for p in paths}
    if missing:
        raise SystemExit(f'Missing v2 files: {sorted(missing)}')
    index = (RULES / 'README.md').read_text(encoding='utf-8')
    for path in paths:
        text = path.read_text(encoding='utf-8', errors='strict')
        if not text.strip() or text.count('```') % 2:
            raise SystemExit(f'Empty v2 file or unclosed code fence: {path.name}')
        if path.name != 'README.md' and f'`{path.name}`' not in index:
            raise SystemExit(f'V2 file missing from index: {path.name}')
        for url in re.findall(r'\]\(([^)]+)\)', text):
            if re.match(r'\w+://', url) or url.startswith('#'):
                continue
            target = (path.parent / url.split('#', 1)[0]).resolve()
            if not target.is_relative_to(ROOT) or not target.is_file():
                raise SystemExit(f'Missing v2 link: {path.name}: {url}')
    length = len((RULES / 'PROJECT_INSTRUCTIONS.md').read_text(encoding='utf-8'))
    if length > 7800:
        raise SystemExit(f'V2 project instructions exceed 7,800 characters: {length}')
    print(f'PASS v2: {len(paths)} UTF-8 documents, index, file links, fences; instructions {length}/7800 characters')


def export():
    check()
    files = {p.relative_to(ROOT).as_posix(): p.read_bytes() for p in sources()}
    digests = {name: hashlib.sha256(data).hexdigest() for name, data in files.items()}
    encoded = json.dumps(digests, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode('utf-8')
    digest = hashlib.sha256(encoded).hexdigest()
    identity = {'edition': 'v2-mcp', 'rules_version': f'TRPG-RULE-v2+sha256:{digest}',
                'source_sha256': digest, 'source_files': digests,
                'digest_format': 'SHA-256 of UTF-8 JSON source_files; sorted keys; ensure_ascii=false; separators=comma,colon'}
    files['RULESET.json'] = (json.dumps(identity, ensure_ascii=False, indent=2) + '\n').encode('utf-8')
    files['RULESET.md'] = (
        '# MCP v2 룰북 배포 식별자\n\n'
        f"rules_version: `{identity['rules_version']}`\n\n"
        '같은 ZIP의 RULESET.json과 같은 배포를 식별합니다. 과거 판본 고정용이 아닙니다.\n'
        '기존 게임의 확정 사실·상태를 유지하고 이후 진행은 최신 v2 소스를 따릅니다.\n'
        '실제 캠페인 정본·세이브·인증정보는 포함하지 않습니다.\n'
    ).encode('utf-8')
    files['UPLOAD_GUIDE.txt'] = (
        'TRPG-RULE MCP v2 사용 방법\n\n'
        '1. rules-v2/PROJECT_INSTRUCTIONS.md 내용을 ChatGPT 프로젝트 지침에 복사합니다.\n'
        '2. rules-v2의 나머지 Markdown과 RULESET.md를 같은 배포의 프로젝트 소스로 등록/교체합니다.\n'
        '3. 구판 rules/, START_GAME.md, 옛 프로젝트 지침·정본 작성 템플릿을 v2 실행 소스로 섞지 않습니다.\n'
        '4. v2의 생성 제출 폼은 연결된 엔진의 도구 스키마와 keeperNext입니다. 이 ZIP은 실제 정본/세이브가 아닙니다.\n'
        '5. TRPG MCP 앱 연결과 도구 사용 가능 여부를 확인합니다. 파일 등록만으로 MCP가 연결되지는 않습니다.\n'
        '6. 기존 게임: 현재 requestId로 이어하기를 요청해 키퍼용 재개 묶음을 읽습니다. 새 게임으로 재생성하지 않습니다.\n'
        '7. 상태·정본·마지막 장면·누적 기록·대기 판정을 확인하고 같은 입력 대기에서 이어갑니다.\n'
        '8. 과거 사건·HP/SAN·소유/소모·지식·난수를 보존합니다. 누락·복원 경고를 지어내거나 재연하지 않습니다.\n'
        '9. 다른 채팅으로 옮기기 전 저장 성공을 확인하고 requestId를 보관합니다. 비공개 자료는 공개 저장소에 올리지 않습니다.\n\n'
        'GitHub 수정은 기존 프로젝트 파일/지침을 자동 교체하지 않습니다.\n'
        'SHA256.json은 이 배포의 파일 바이트 확인용입니다. RULESET은 정확한 출처 식별이며 구판 룰북을 재개 조건으로 요구하지 않습니다.\n'
    ).encode('utf-8')
    manifest = {name: hashlib.sha256(data).hexdigest() for name, data in sorted(files.items())}
    files['SHA256.json'] = (json.dumps(manifest, ensure_ascii=False, indent=2) + '\n').encode('utf-8')
    archive = ROOT / 'dist/TRPG-RULE-v2-project.zip'
    archive.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            z.writestr(info, data)
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None or set(z.namelist()) != set(files):
            raise SystemExit('V2 ZIP integrity or file list mismatch')
        for name, data in files.items():
            if z.read(name) != data:
                raise SystemExit(f'V2 ZIP source mismatch: {name}')
        for name, expected in manifest.items():
            if hashlib.sha256(z.read(name)).hexdigest() != expected:
                raise SystemExit(f'V2 ZIP hash mismatch: {name}')
    print(f'Exported {archive}; {len(files)} files; {identity["rules_version"]}')
