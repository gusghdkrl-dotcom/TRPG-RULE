#!/usr/bin/env python3
"""Fictional fixtures only; tests data operations, not ChatGPT latency/behavior."""
import copy
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from file_save import canonical, decode, digest, encode, write_verified
from private_state import (canon_digest, initialize, record, integrate, render_source,
                           verify_source, write_source, validate)
from test_file_save import fixture, refresh


def work(payload):
    return {'format': 'PRIVATE_WORK_V1', 'binding': {
        **{k: payload[k] for k in ('campaign_id', 'session_id', 'branch_id')},
        'canon_sha256': canon_digest(payload['canon_files'])}, 'revision': 0,
        'private_paths': ['/npcs/n1/plan', '/npcs/n1/location'], 'entries': {}, 'events': {}}


def event(eid='hidden1', path='/npcs/n1/plan', op='set', value='자료를 별실로 옮길 계획'):
    change={'path':path,'op':op}
    if op == 'set':change['value']=value
    return {'event_id':eid,'at':'가상 첫날 오후','reason':'실제 도착한 조건에 따른 비공개 변화','changes':[change]}


class PrivateStateTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.path=Path(self.tmp.name)/'private.json'
        self.payload=fixture();self.work=work(self.payload)
        initialize(self.path,self.work)

    def record(self, events, revision=0, **kwargs):
        return record(self.path,binding=self.work['binding'],expected_revision=revision,events=events,**kwargs)

    def test_no_change_no_io(self):
        with patch.object(Path,'read_bytes',side_effect=AssertionError('unexpected read')), patch.object(Path,'stat',side_effect=AssertionError('unexpected stat')):
            self.assertEqual(self.record([]),{'status':'unchanged'})

    def test_batch_one_write_and_replay(self):
        from private_state import _write
        with patch('private_state._write',wraps=_write) as writer:
            result=self.record([event(),event('hidden2','/npcs/n1/location',value='room2')])
            self.assertEqual(writer.call_count,1)
        self.assertEqual(result['revision'],1)
        raw=self.path.read_bytes();stamp=self.path.stat().st_mtime_ns
        self.assertEqual(self.record([event(),event('hidden2','/npcs/n1/location',value='room2')])['status'],'already_applied')
        self.assertEqual(raw,self.path.read_bytes());self.assertEqual(stamp,self.path.stat().st_mtime_ns)
        restored=json.loads(raw)
        self.assertNotIn('pcs',restored);self.assertEqual(len(restored['events']),2)

    def test_conflicts_and_missing_file_do_not_reset(self):
        self.record([event()]);raw=self.path.read_bytes()
        for events,revision in [([event(value='changed')],1),([event('new')],0)]:
            with self.assertRaises(ValueError):self.record(events,revision)
            self.assertEqual(self.path.read_bytes(),raw)
        with self.assertRaises(FileExistsError):initialize(self.path,self.work)
        self.path.unlink()
        with self.assertRaises(FileNotFoundError):self.record([event()])
        self.assertFalse(self.path.exists())

    def test_binding_and_private_scope(self):
        with self.assertRaises(ValueError):self.record([event(path='/pcs/p1/hp',value=0)])
        binding=dict(self.work['binding'],branch_id='other')
        with self.assertRaises(ValueError):record(self.path,binding=binding,expected_revision=0,events=[event()])
        self.record([event('new-fact','/npcs/n1/new_secret',value=False)],new_private_paths=['/npcs/n1/new_secret'])
        w=json.loads(self.path.read_bytes());validate(w)
        with self.assertRaises(ValueError):self.record([event('overlap')],1,new_private_paths=['/npcs/n1'])

    def test_cancel_remove_release_and_public_preservation(self):
        self.payload['state']['npcs']['n1']['location']='public-room-now'
        self.payload['state']['npcs']['n1']['plan']='obsolete'
        self.record([event(),event('move','/npcs/n1/location',value='old-private-room')])
        self.record([event('cancel',op='remove'),event('reveal','/npcs/n1/location',op='release')],1)
        w=json.loads(self.path.read_bytes());state=integrate(self.payload['state'],w)
        self.assertEqual(state['npcs']['n1']['location'],'public-room-now')
        self.assertNotIn('plan',state['npcs']['n1'])
        self.assertEqual(state['pcs'],self.payload['state']['pcs'])
        self.assertEqual(state['unknown_extension'],self.payload['state']['unknown_extension'])
        self.assertEqual(len(w['events']),4)

    def test_failed_replace_preserves_previous_state(self):
        raw=self.path.read_bytes()
        with patch('private_state.os.replace',side_effect=OSError('synthetic failure')):
            with self.assertRaises(OSError):self.record([event()])
        self.assertEqual(self.path.read_bytes(),raw)
        self.assertEqual(list(self.path.parent.glob('.private-*')),[])

    def checkpoint(self):
        self.record([event()])
        payload=copy.deepcopy(self.payload)
        payload['state']=integrate(payload['state'],json.loads(self.path.read_bytes()))
        return refresh(payload)

    def test_save_and_source_pair_fresh_process(self):
        payload=self.checkpoint();root=self.path.parent
        env=write_verified(root/'save.json',payload,source_state=copy.deepcopy(payload['state']),source_canons=payload['canon_files'])
        write_source(root/'source.md',env)
        code="from pathlib import Path; from file_save import decode; from private_state import verify_source; import sys; p=Path(sys.argv[1]); e=decode((p/'save.json').read_bytes()); verify_source((p/'source.md').read_bytes(),e); assert e['payload']['state']['private_work']['revision']==1; print('restored')"
        self.assertEqual(subprocess.check_output([sys.executable,'-c',code,str(root)],cwd=Path(__file__).parent).strip(),b'restored')
        self.assertIn(payload['canon_files'][0]['text'].encode(),(root/'source.md').read_bytes())
        self.assertNotIn('"pcs":',(root/'source.md').read_text())
        self.assertEqual(write_source(root/'source.md',env)['status'],'verified')

    def test_newer_source_and_other_branch_rejected(self):
        payload=self.checkpoint();env=decode(encode(payload));raw=render_source(env)
        newer=copy.deepcopy(payload);newer['parent']={'branch_id':'main','save_seq':1,'payload_sha256':env['payload_sha256']};newer['save_seq']=2
        with self.assertRaisesRegex(ValueError,'source/save mismatch'):verify_source(raw,decode(encode(newer)))
        other=copy.deepcopy(payload);other['branch_id']='other'
        with self.assertRaisesRegex(ValueError,'binding mismatch'):encode(other)
        bad=copy.deepcopy(payload);bad['state']['npcs']['n1']['plan']='wrong'
        with self.assertRaisesRegex(ValueError,'private owner mismatch'):refresh(bad)

    def test_source_failure_preserves_valid_json(self):
        payload=self.checkpoint();root=self.path.parent
        env=write_verified(root/'save.json',payload,source_state=copy.deepcopy(payload['state']),source_canons=payload['canon_files'])
        before=(root/'save.json').read_bytes()
        (root/'source.md').write_bytes(b'different source already exists')
        with self.assertRaisesRegex(ValueError,'refuse source overwrite'):
            write_source(root/'source.md',env)
        self.assertEqual((root/'save.json').read_bytes(),before)
        self.assertEqual(decode(before),env)
        self.assertEqual((root/'source.md').read_bytes(),b'different source already exists')

    def test_older_save_remains_readable(self):
        payload=fixture()
        self.assertEqual(decode(encode(payload))['payload'],payload)
        with self.assertRaisesRegex(ValueError,'missing private work'):render_source(decode(encode(payload)))


if __name__=='__main__':unittest.main()
