#!/usr/bin/env python3
"""Synthetic FILE_SAVE_V1 round trips and adversarial input checks."""
import copy
import json
import tempfile
import subprocess
import sys
import unittest
from pathlib import Path
from file_save import (canonical, decode, digest, encode, write_verified,
                       capture_continuity, inspect_legacy, inventory, resolve)


def fixture():
    # Synthetic data only. Does not claim to be a complete playable campaign.
    canon = "# 합성 세계 정본\n문은 수동으로 열린다.\n"
    payload = {
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
    state = payload["state"]
    state["pcs"]["p1"].update(id="p1", san=42, luck=17, inventory={"bandage": 0},
                              skills={"persuade": 60}, location="room")
    state["npcs"]["n1"].update(id="n1", alive=True, relationship="약속을 지킨 PC를 신뢰",
                                memory=[{"event": "door", "source": "직접 목격"}])
    state["npcs"]["n2"] = {"id": "n2", "alive": False, "knowledge": [], "voice": "미확립"}
    state["pending"].update(id="r2", owner_id="p1", status="awaiting_input", target=60,
                             applied_events=[], choice="행운 체크 유지")
    state.update(
        world={"routes": {"bridge": "붕괴"}, "drivers": {"alarm": {"cancelled": True}}},
        investigation={"door": {"text": "문 뒤에서 두 번 두드리는 소리를 들었다.", "known_by": ["p1", "n1"]}},
        progress={"chapter": 2, "objective": "출구 확보", "growth_applied": ["growth1"]},
        effects={"c1": {"owner": "p1", "remaining_game_minutes": 12, "next_tick": 55,
                        "released": False}, "wet": {"released": True, "event": "dry1"}},
        scene={"id": "scene2", "location": "room", "positions": {"p1": "문 옆", "n1": "계단"}},
        current_input={"kind": "roll", "owner_id": "p1", "pending_id": "r2"},
        presentation={"tension_target": "7:3", "roll_lines": 2, "public_facts": ["문이 잠겼다"]},
        last_public_output="문이 잠겼다. 경비가 묻는다. “기다릴까요?” 판정 입력 대기.",
        assets={"map": {"available": False, "layout": "방-계단-출구", "reason": "이미지 원본 없음"}},
    )
    register(state)
    return refresh(payload)


def register(state):
    state["critical_state_registry"] = ["/" + k.replace("~", "~0").replace("/", "~1")
                                         for k in state if k != "critical_state_registry"]


def refresh(payload):
    # Called only when intentionally creating a new legitimate source snapshot.
    domains = {name: {"status": "present", "paths": [path]} for name, path in {
        "participants": "/pcs", "npcs": "/npcs", "world": "/world",
        "investigation": "/investigation", "progress": "/progress", "timeline": "/timeline",
        "effects": "/effects", "randomness": "/rng", "procedures": "/pending",
        "presentation": "/presentation", "assets": "/assets"}.items()}
    resume = {"scene_ref": "/scene", "input_ref": "/current_input", "owner_ref": "/pcs/p1",
              "pending_ref": "/pending", "last_output_ref": "/last_public_output"}
    return capture_continuity(payload, source_state=copy.deepcopy(payload["state"]),
                              source_canons=copy.deepcopy(payload["canon_files"]),
                              domains=domains, resume=resume,
                              references=[{"source": "/effects/c1/owner", "target": "/pcs/p1"}])


def write(path, payload, source=None):
    source = payload if source is None else source
    return write_verified(path, payload, source_state=copy.deepcopy(source["state"]),
                          source_canons=copy.deepcopy(source["canon_files"]))


def unchecked(payload):
    return canonical({"payload": payload, "payload_sha256": digest(canonical(payload))})


class FileSaveTests(unittest.TestCase):
    def test_full_round_trip_and_retry(self):
        payload = fixture()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "save.json"
            result = write(path, payload)
            self.assertEqual(result["payload"], payload)
            raw = path.read_bytes()
            self.assertEqual(write(path, payload), result)
            self.assertEqual(path.read_bytes(), raw)
            # Fresh parse without a parent file/external lookup preserves every field.
            self.assertEqual(decode(raw)["payload"]["state"], payload["state"])
            changed = copy.deepcopy(payload)
            changed["state"]["pcs"]["p1"]["hp"] = 7
            changed = refresh(changed)
            with self.assertRaisesRegex(ValueError, "overwrite"):
                write(path, changed)
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
        payload = refresh(payload)
        self.assertGreater(len(encode(payload)), 100000)
        self.assertEqual(decode(encode(payload))["payload"], payload)
        self.assertEqual(encode(payload), encode(dict(reversed(list(payload.items())))))


    def test_missing_domains_and_details_with_rehashed_envelope(self):
        paths = [("pcs",), ("npcs",), ("pending",), ("rng",), ("timeline",),
                 ("npcs", "n1", "voice"), ("npcs", "n1", "knowledge"),
                 ("pcs", "p1", "inventory"), ("effects", "c1", "next_tick"),
                 ("world", "routes"), ("last_public_output",), ("unknown_extension",)]
        for path in paths:
            with self.subTest(path=path):
                payload = fixture()
                node = payload["state"]
                for key in path[:-1]:
                    node = node[key]
                del node[path[-1]]
                with self.assertRaisesRegex(ValueError, "frozen state hash"):
                    decode(unchecked(payload))
                payload["continuity"]["state_sha256"] = digest(canonical(payload["state"]))
                with self.assertRaisesRegex(ValueError, "inventory"):
                    decode(unchecked(payload))

    def test_coverage_references_and_boundary_conflicts(self):
        changes = [
            lambda p: p["continuity"]["domains"].pop("npcs"),
            lambda p: p["continuity"]["domains"]["npcs"].update(paths=["/missing"]),
            lambda p: p["continuity"]["domains"]["npcs"].update(status="empty", reason="없음"),
            lambda p: p["continuity"]["references"][0].update(target="/npcs/n1"),
            lambda p: p["continuity"]["resume"].update(owner_ref="/npcs/n1"),
            lambda p: p["continuity"]["resume"].update(pending_ref=None),
            lambda p: p["state"]["pending"].update(status="resolved"),
            lambda p: p["state"]["current_input"].update(kind="action"),
            lambda p: p["state"]["current_input"].update(owner_id="p2"),
            lambda p: p["state"]["critical_state_registry"].remove("/unknown_extension"),
        ]
        for i, change in enumerate(changes):
            with self.subTest(case=i):
                payload = fixture()
                change(payload)
                # Even a freshly inventoried state must satisfy declared coverage and input consistency.
                payload["continuity"]["state_sha256"] = digest(canonical(payload["state"]))
                payload["continuity"]["state_inventory"] = inventory(payload["state"])
                with self.assertRaises(ValueError):
                    decode(unchecked(payload))

    def test_source_comparison_before_creation(self):
        original = fixture()
        changed = copy.deepcopy(original)
        changed["state"]["npcs"]["n1"]["voice"] = "달라진 말투"
        changed = refresh(changed)  # Internally valid, but not the actual frozen source.
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "save.json"
            with self.assertRaisesRegex(ValueError, "source state mismatch"):
                write(path, changed, original)
            self.assertFalse(path.exists())
        with self.assertRaisesRegex(ValueError, "source state mismatch"):
            capture_continuity(changed, source_state=original["state"],
                               source_canons=original["canon_files"],
                               domains={}, resume={}, references=[])

    def test_canon_inventory_and_legacy_inspection(self):
        payload = fixture()
        payload["canon_files"][0]["revision"] = 2
        with self.assertRaisesRegex(ValueError, "canon inventory"):
            decode(unchecked(payload))
        old = fixture()
        del old["continuity"]
        old["state"]["critical_state_registry"] = ["pcs", "npcs"]
        raw = unchecked(old)
        with self.assertRaisesRegex(ValueError, "inspect legacy"):
            decode(raw)
        result = inspect_legacy(raw)
        self.assertEqual(result["status"], "legacy_structure_only")
        self.assertEqual(result["envelope"]["payload"], old)

    def test_unknown_fields_types_and_pointer_escaping(self):
        payload = fixture()
        payload["state"]["a/b~c"] = {"empty": [], "zero": 0, "false": False, "none": None}
        register(payload["state"])
        payload = refresh(payload)
        restored = decode(encode(payload))["payload"]["state"]
        self.assertEqual(resolve(restored, "/a~1b~0c/empty"), [])
        self.assertIs(type(resolve(restored, "/a~1b~0c/zero")), int)
        self.assertIs(resolve(restored, "/a~1b~0c/false"), False)
        for pointer in ("/a~2b", "/pending/raw/01", "/pending/raw/-1", "/pending/raw/2"):
            with self.subTest(pointer=pointer), self.assertRaises(ValueError):
                resolve(restored, pointer)

    def test_resume_boundaries_without_advancing_game(self):
        for kind in ("roll", "choice", "handoff", "reaction", "visual", "resolve", "action", "setup", "ended"):
            with self.subTest(kind=kind):
                payload = fixture()
                state, c = payload["state"], payload["continuity"]
                state["current_input"]["kind"] = kind
                if kind == "resolve":
                    state["pending"]["status"] = "execution_unknown"
                if kind in ("action", "setup", "ended"):
                    state["pending"] = {}
                    state["current_input"]["pending_id"] = None
                    c["resume"]["pending_ref"] = None
                    c["domains"]["procedures"] = {"status": "empty", "paths": ["/pending"], "reason": "열린 절차 없음"}
                if kind in ("setup", "ended"):
                    state["phase"] = kind
                    state["current_input"]["owner_id"] = None
                    c["resume"]["owner_ref"] = None
                payload = capture_continuity(payload, source_state=copy.deepcopy(state),
                          source_canons=payload["canon_files"], domains=c["domains"],
                          resume=c["resume"], references=c["references"])
                self.assertEqual(decode(encode(payload))["payload"]["state"], state)

    def test_fresh_process_restores_exact_state_without_parent(self):
        payload = fixture()
        before = copy.deepcopy(payload["state"])
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "save.json"
            write(path, payload)
            code = "from file_save import decode,canonical; from pathlib import Path; import sys; sys.stdout.buffer.write(canonical(decode(Path(sys.argv[1]).read_bytes())['payload']['state']))"
            output = subprocess.check_output([sys.executable, "-c", code, str(path)], cwd=Path(__file__).parent)
        restored = json.loads(output)
        self.assertEqual(canonical(restored), canonical(before))
        self.assertFalse(restored["npcs"]["n2"]["alive"])
        self.assertEqual(restored["npcs"]["n1"]["voice"], "짧은 존댓말")
        self.assertEqual(restored["npcs"]["n2"]["knowledge"], [])
        self.assertEqual(restored["pcs"]["p1"]["inventory"]["bandage"], 0)
        self.assertTrue(restored["effects"]["wet"]["released"])
        self.assertEqual(restored["effects"]["c1"]["remaining_game_minutes"], 12)
        self.assertTrue(restored["rng"]["r1"]["applied"])
        self.assertEqual(restored["pending"]["raw"], [99, 98])
        self.assertEqual(restored["timeline"]["elapsed_minutes"], 43)
        # Data preservation only: no ChatGPT narration or game engine executed.


if __name__ == "__main__":
    unittest.main()
