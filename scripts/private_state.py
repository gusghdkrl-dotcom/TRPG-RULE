#!/usr/bin/env python3
"""Local single-writer reference for private changes; not a ChatGPT-installed app.

Caller decides visibility from actual game facts. No-op turns need no tool call.
Only synthetic data belongs in repository tests.
"""
import copy
import os
import tempfile
from pathlib import Path
from file_save import canonical, digest, parse, require, pointer_parts, resolve


def canon_digest(files):
    return digest(canonical(files))


def _path(path):
    parts = pointer_parts(path)
    require(len(parts) >= 2 and parts[0] not in {'private_work', 'critical_state_registry'},
            'private path must target an owning field, not a state root')
    return parts


def validate(work):
    require(isinstance(work, dict) and work.get('format') == 'PRIVATE_WORK_V1', 'invalid private work')
    binding = work.get('binding')
    require(isinstance(binding, dict) and set(binding) == {'campaign_id', 'session_id', 'branch_id', 'canon_sha256'},
            'invalid binding')
    require(all(isinstance(v, str) and v for v in binding.values()), 'empty binding')
    require(type(work.get('revision')) is int and work['revision'] >= 0, 'invalid revision')
    paths = work.get('private_paths')
    require(isinstance(paths, list) and all(isinstance(p, str) for p in paths)
            and len(paths) == len(set(paths)), 'invalid private paths')
    for p in paths:
        _path(p)
        require(not any(q != p and p.startswith(q + '/') for q in paths), 'overlapping paths')
    entries, events = work.get('entries'), work.get('events')
    require(isinstance(entries, dict) and set(entries) <= set(paths), 'unregistered private path')
    require(isinstance(events, dict), 'invalid event history')
    for path, item in entries.items():
        require(isinstance(item, dict), 'invalid private entry')
        _change(dict(item, path=path), paths)
    for eid, event in events.items():
        require(isinstance(eid, str) and eid and isinstance(event, dict) and event.get('event_id') == eid, 'invalid event identity')
        _event(event, paths)
    canonical(work)


def _change(change, paths):
    require(isinstance(change, dict) and change.get('path') in paths, 'unregistered private path')
    op = change.get('op')
    require(isinstance(op, str) and op in {'set', 'remove', 'release'}, 'invalid operation')
    require(set(change) == ({'path', 'op', 'value'} if op == 'set' else {'path', 'op'}), 'invalid change fields')
    canonical(change)


def _event(event, paths):
    require(isinstance(event, dict) and isinstance(event.get('event_id'), str) and event['event_id'], 'missing event id')
    require(isinstance(event.get('reason'), str) and event['reason'].strip(), 'missing causal reason')
    require(isinstance(event.get('at'), str) and event['at'].strip(), 'missing game boundary')
    changes = event.get('changes')
    require(isinstance(changes, list) and changes, 'empty event')
    for change in changes:
        _change(change, paths)
    require(len({c['path'] for c in changes}) == len(changes), 'duplicate field within event')


def _write(path, work):
    validate(work)
    raw = canonical(work) + b'\n'
    fd, name = tempfile.mkstemp(prefix='.private-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(raw)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)
    require(path.read_bytes() == raw, 'private readback mismatch')
    return work


def initialize(path, work):
    """Only at setup/verified load; missing-file recovery must be explicit."""
    validate(work)
    path = Path(path)
    # Never reset an existing local working state from an older checkpoint.
    with path.open('xb') as stream:
        stream.write(canonical(work) + b'\n')
    require(canonical(parse(path.read_bytes())) == canonical(work), 'initial readback mismatch')
    return work


def record(path, *, binding, expected_revision, events, new_private_paths=()):
    """One read / batched changes / atomic replacement / one readback.

    Visibility classification is a semantic responsibility, not inferred from keys.
    All writers must be serialized. This is not a concurrent database transaction.
    """
    if not events:
        require(not new_private_paths, 'no scope-only write on an unchanged turn')
        return {'status': 'unchanged'}  # No file read, stat, hash or write.
    path = Path(path)
    work = parse(path.read_bytes())  # Missing file fails; never recreate here.
    validate(work)
    require(work['binding'] == binding, 'binding mismatch')
    candidate = copy.deepcopy(work)
    candidate['private_paths'] = sorted(set(work['private_paths']) | set(new_private_paths))
    validate(candidate)
    pending = []
    seen = {}
    for event in events:
        _event(event, candidate['private_paths'])
        eid = event['event_id']
        previous = seen.get(eid, work['events'].get(eid))
        if previous is not None:
            require(canonical(previous) == canonical(event), 'event identity conflict')
        else:
            pending.append(event)
        seen[eid] = event
    if not pending:
        require(set(new_private_paths) <= set(work['private_paths']), 'scope differs on retry')
        return {'status': 'already_applied', 'revision': work['revision']}
    require(type(expected_revision) is int and expected_revision == work['revision'], 'stale private revision')
    for event in pending:
        for change in event['changes']:
            candidate['entries'][change['path']] = {k: v for k, v in change.items() if k != 'path'}
        candidate['events'][event['event_id']] = copy.deepcopy(event)
    candidate['revision'] += 1
    _write(path, candidate)
    return {'status': 'written', 'revision': candidate['revision'], 'event_ids': [e['event_id'] for e in pending]}


def integrate(state, work):
    """Checkpoint only: combine current public state and private owning fields.

    release stops an old private overlay from overwriting newer public state.
    Keep unrelated/unknown fields. Parents must actually exist; do not invent them.
    """
    validate(work)
    result = copy.deepcopy(state)
    for path, entry in work['entries'].items():
        if entry['op'] == 'release':
            continue
        parts = _path(path)
        parent = result
        for part in parts[:-1]:
            require(isinstance(parent, dict) and part in parent, 'missing owner parent')
            parent = parent[part]
        require(isinstance(parent, dict), 'target parent must be an object')
        if entry['op'] == 'set':
            parent[parts[-1]] = copy.deepcopy(entry['value'])
        else:
            parent.pop(parts[-1], None)
    result['private_work'] = copy.deepcopy(work)
    registry = result.get('critical_state_registry')
    require(isinstance(registry, list), 'registry must be a path list')
    if '/private_work' not in registry:
        registry.append('/private_work')
    return result


def verify_save_work(payload):
    work = payload['state'].get('private_work')
    if work is None:
        return  # Preserved older FILE_SAVE_V1, reviewed before runtime initialization.
    validate(work)
    require(work['binding'] == {**{k: payload[k] for k in ('campaign_id', 'session_id', 'branch_id')},
                               'canon_sha256': canon_digest(payload['canon_files'])}, 'save/private binding mismatch')
    for path, entry in work['entries'].items():
        if entry['op'] == 'set':
            require(canonical(resolve(payload['state'], path)) == canonical(entry['value']), 'private owner mismatch')
        elif entry['op'] == 'remove':
            parts = _path(path)
            parent_path = '/' + '/'.join(p.replace('~', '~0').replace('/', '~1') for p in parts[:-1])
            parent = resolve(payload['state'], parent_path)
            require(isinstance(parent, dict) and parts[-1] not in parent, 'removed private value remains')


def render_source(envelope):
    """Derive source from one already-validated frozen save; no circular hashes."""
    from file_save import validate_payload
    payload = envelope['payload']
    require(envelope['payload_sha256'] == digest(canonical(payload)), 'save hash mismatch')
    validate_payload(payload)
    require('private_work' in payload['state'], 'missing private work for source')
    header = {'format': 'PRIVATE_SOURCE_V1', 'campaign_id': payload['campaign_id'],
              'session_id': payload['session_id'], 'branch_id': payload['branch_id'],
              'save_seq': payload['save_seq'], 'payload_sha256': envelope['payload_sha256'],
              'private_work': payload['state']['private_work']}
    text = '# 비공개 소스 — 고정 정본과 저장 시점 상태\n\n'
    text += '기준선은 아래 정본 전문이다. 현재 변경은 private_work.entries를 적용한다.\n'
    text += 'release는 이후 공개 상태를 따른다. 같은 분기·저장 번호·해시의 세이브와 결합한다.\n'
    text += '```json\n' + __import__('json').dumps(header, ensure_ascii=False, indent=2) + '\n```\n'
    for f in payload['canon_files']:
        text += '\n## 정본: ' + f['canon_id'] + ' / ' + str(f['revision']) + '\n\n' + f['text'] + '\n'
    return text.encode('utf-8')


def write_source(path, envelope):
    raw = render_source(envelope)
    path = Path(path)
    try:
        with path.open('xb') as stream:
            stream.write(raw)
    except FileExistsError:
        require(path.read_bytes() == raw, 'refuse source overwrite')
    require(path.read_bytes() == raw, 'source readback mismatch')
    return {'status': 'verified', 'sha256': digest(raw)}


def verify_source(raw, envelope):
    require(raw == render_source(envelope), 'source/save mismatch')
