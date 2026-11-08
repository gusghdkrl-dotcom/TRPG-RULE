#!/usr/bin/env python3
"""Offline exact comparison of frozen resume probes against reconstructed state.

This does not load/merge DB1, contact a service or infer facts from conversation.
Keep actual campaign inputs outside this repository and public output.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

class Missing(ValueError):
    pass

def pointer(document, path):
    if not isinstance(path, str) or not path.startswith('/'):
        raise ValueError('probe path must be a non-root JSON pointer')
    current = document
    for raw in path[1:].split('/'):
        if '~' in raw.replace('~0', '').replace('~1', ''):
            raise ValueError('invalid pointer escape')
        key = raw.replace('~1', '/').replace('~0', '~')
        if isinstance(current, dict) and key in current:
            current = current[key]
        elif isinstance(current, list) and key.isascii() and key.isdigit() and (key == '0' or not key.startswith('0')) and int(key) < len(current):
            current = current[int(key)]
        else:
            raise Missing('missing pointer')
    return current

def same(a, b):
    # bool and int must not compare equal; missing is never replaced with null.
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b

def compare(manifest, restored):
    if not isinstance(manifest, dict) or manifest.get('format') != 'RESUME_PROBES_V1':
        raise ValueError('invalid probe manifest')
    probes = manifest.get('probes')
    if not isinstance(probes, list) or not probes:
        raise ValueError('nonempty frozen probes required')
    paths = set()
    errors = []
    for i, probe in enumerate(probes):
        if not isinstance(probe, dict) or not all(k in probe for k in ('path', 'expected', 'source_ref')):
            raise ValueError('invalid probe')
        path = probe['path']
        if not isinstance(path, str) or path in paths or not isinstance(probe['source_ref'], str) or not probe['source_ref'].strip():
            raise ValueError('duplicate path or invalid source')
        paths.add(path)
        try:
            value = pointer(restored, path)
        except Missing:
            errors.append({'probe_index': i, 'reason': 'missing'})
            continue
        if not same(probe['expected'], value):
            errors.append({'probe_index': i, 'reason': 'changed'})
    return {'checked': len(probes), 'passed': not errors, 'errors': errors}

def load(path):
    def reject(value):
        raise ValueError('non-JSON numeric constant')
    def object_pairs(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError('duplicate JSON key')
            result[key] = value
        return result
    return json.loads(Path(path).read_text(encoding='utf-8'), parse_constant=reject, object_pairs_hook=object_pairs)

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('frozen_probes', help='Before serialization: paths, expected values and source refs')
    ap.add_argument('reconstructed_state', help='Logical state reconstructed independently from actual read-back + canon')
    args = ap.parse_args()
    try:
        result = compare(load(args.frozen_probes), load(args.reconstructed_state))
    except (ValueError, TypeError, OSError, RecursionError):
        # No campaign values, entity names, paths or exception payload in output.
        print('FAIL: invalid/unreadable comparison input')
        return 2
    print(json.dumps(result, ensure_ascii=False))
    return 0 if result['passed'] else 1

if __name__ == '__main__':
    raise SystemExit(main())
