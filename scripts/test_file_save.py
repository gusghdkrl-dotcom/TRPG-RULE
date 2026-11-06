#!/usr/bin/env python3
"""Synthetic FILE_SAVE_V1 round trips and adversarial input checks."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from file_save import canonical, decode, digest, encode, write_verified


def fixture():
    # Synthetic data only. Does not claim to be a complete playable campaign.
    canon = "# 합성 세계 정본\n문은 수동으로 열린다.\n"
    return {
        "format": "FILE_SAVE_V1", "campaign_id": "synthetic", "session_id": "test",
        "branch_id": "main", "save_seq": 1, "parent": None, "ruleset": "test-rules",
        "canon_files": [{"canon_id": "canon", "revision": 1, "filename": "canon.md",
                         "text": canon, "sha256": digest(canon.encode())}],
        "state": {
            "campaign_id": "synthetic", "session_id": "test", "rules_version": "test-rules",
            "phase": "play", "scene_turn": 30,
            "critical_state_registry": ["npcs", "pcs", "pending", "rng", "timeline"],
            "npcs": {"n1": {"voice": "짧은 존댓말", "address": "선생님",
                             "knowledge": ["door"], "unanswered": "기다릴까요?"}},
            "pcs": {"p1": {"hp": 8, "conditions": [{"id": "c1", "cause": "e1",
                              "effect": "달리기 패널티1", "release": "적절한 처치",
                              "applied": ["damage-e1"]}]}},
            "pending": {"roll": "r2", "raw": [99, 98], "candidates": [99, 99],
                        "resolved": False, "luck_checked": True},
            "rng": {"r1": {"raw": 88, "applied": True}},
            "timeline": {"elapsed_minutes": 43}, "unknown_extension": {"keep": [1, "값"]}
        }
    }


class FileSaveTests(unittest.TestCase):
    def test_full_round_trip_and_retry(self):
        payload = fixture()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "save.json"
            result = write_verified(path, payload)
            self.assertEqual(result["payload"], payload)
            raw = path.read_bytes()
            self.assertEqual(write_verified(path, payload), result)
            self.assertEqual(path.read_bytes(), raw)
            # Fresh parse without a parent file/external lookup preserves every field.
            self.assertEqual(decode(raw)["payload"]["state"], payload["state"])
            changed = copy.deepcopy(payload)
            changed["state"]["pcs"]["p1"]["hp"] = 7
            with self.assertRaisesRegex(ValueError, "overwrite"):
                write_verified(path, changed)
            self.assertEqual(path.read_bytes(), raw)

    def test_parent_is_not_a_file_dependency_and_fork_is_distinct(self):
        first = fixture()
        child = copy.deepcopy(first)
        child["parent"] = {"branch_id": "main", "save_seq": 1,
                           "payload_sha256": digest(canonical(first))}
        child["save_seq"] = 2
        self.assertEqual(decode(encode(child))["payload"], child)
        child["branch_id"], child["save_seq"] = "fork", 1
        self.assertEqual(decode(encode(child))["payload"], child)
        child["save_seq"] = 2
        with self.assertRaises(ValueError):
            encode(child)

    def test_tampered_truncated_and_duplicate_json(self):
        raw = encode(fixture())
        with self.assertRaises(ValueError):
            decode(raw[:-5])
        env = json.loads(raw)
        env["payload"]["state"]["pcs"]["p1"]["hp"] = 0
        with self.assertRaisesRegex(ValueError, "payload hash"):
            decode(canonical(env))
        # Recomputed outer checksum must not hide a stale canon checksum.
        payload = fixture()
        payload["canon_files"][0]["text"] += "변조"
        env = {"payload": payload, "payload_sha256": digest(canonical(payload))}
        with self.assertRaisesRegex(ValueError, "canon hash"):
            decode(canonical(env))
        with self.assertRaisesRegex(ValueError, "duplicate"):
            decode(raw.replace(b'"scene_turn":30', b'"scene_turn":30,"scene_turn":0'))

    def test_missing_invalid_and_conflicting_values(self):
        changes = [
            lambda p: p.pop("parent"),
            lambda p: p.update(save_seq=True),
            lambda p: p.update(save_seq=3),
            lambda p: p.update(branch_id="../escape"),
            lambda p: p.update(canon_files=[]),
            lambda p: p.update(state={}),
            lambda p: p["state"].update(session_id="different"),
            lambda p: p["state"].update(critical_state_registry=[]),
            lambda p: p["state"].update(scene_turn=True),
            lambda p: p["state"].update(bad=float("nan")),
            lambda p: p["canon_files"].append(copy.deepcopy(p["canon_files"][0])),
            lambda p: p["canon_files"][0].update(filename="../canon.md"),
        ]
        for change in changes:
            with self.subTest(change=change):
                payload = fixture()
                change(payload)
                with self.assertRaises(ValueError):
                    encode(payload)
        for token in (b"NaN", b"Infinity", b"1e999"):
            with self.subTest(token=token), self.assertRaises(ValueError):
                decode(encode(fixture()).replace(b'"scene_turn":30', b'"scene_turn":' + token))

    def test_korean_large_text_and_order_independent_hash(self):
        payload = fixture()
        payload["canon_files"][0]["text"] = "가상 자료 내용\n" * 10000
        payload["canon_files"][0]["sha256"] = digest(payload["canon_files"][0]["text"].encode())
        self.assertGreater(len(encode(payload)), 100000)
        self.assertEqual(decode(encode(payload))["payload"], payload)
        self.assertEqual(encode(payload), encode(dict(reversed(list(payload.items())))))


if __name__ == "__main__":
    unittest.main()
