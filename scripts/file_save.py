#!/usr/bin/env python3
"""FILE_SAVE_V1 development reference; no network or automatic game integration.

Checks format/integrity, not completeness of fictional facts. The keeper must
also perform STATE_INTEGRITY against actual current state and canon references.
"""
import hashlib
import json
import re
from pathlib import Path


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True,
                      separators=(",", ":"), allow_nan=False).encode("utf-8")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def require(ok, message):
    if not ok:
        raise ValueError(message)


def _pairs(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "duplicate JSON key")
        result[key] = value
    return result


def _constant(value):
    raise ValueError("non-finite JSON number: " + value)


def parse(raw):
    value = json.loads(raw.decode("utf-8"), object_pairs_hook=_pairs,
                       parse_constant=_constant)
    # Also rejects overflow such as 1e999 and invalid UTF-8 surrogate strings.
    canonical(value)
    return value


def _identifier(value):
    return isinstance(value, str) and re.fullmatch(r"[A-Za-z0-9_-]+", value)


def _sha(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value)


def validate_payload(payload):
    require(isinstance(payload, dict), "payload must be an object")
    required = {"format", "campaign_id", "session_id", "branch_id", "save_seq",
                "ruleset", "parent", "canon_files", "state"}
    require(required <= payload.keys(), "missing payload fields")
    require(payload["format"] == "FILE_SAVE_V1", "unsupported format")
    for key in ("campaign_id", "session_id", "branch_id"):
        require(_identifier(payload[key]), "invalid " + key)
    seq = payload["save_seq"]
    require(type(seq) is int and seq > 0, "invalid save_seq")
    require(isinstance(payload["ruleset"], str) and payload["ruleset"].strip(),
            "missing ruleset")
    parent = payload["parent"]
    if parent is None:
        require(seq == 1, "non-initial save needs parent")
    else:
        require(isinstance(parent, dict), "invalid parent")
        require({"branch_id", "save_seq", "payload_sha256"} <= parent.keys(),
                "missing parent fields")
        require(_identifier(parent["branch_id"]) and
                type(parent["save_seq"]) is int and parent["save_seq"] > 0 and
                _sha(parent["payload_sha256"]), "invalid parent identity")
        if parent["branch_id"] == payload["branch_id"]:
            require(seq == parent["save_seq"] + 1, "invalid branch sequence")
        else:
            require(seq == 1, "new branch must start at 1")
    state = payload["state"]
    require(isinstance(state, dict) and bool(state), "missing current state")
    for key, expected in (("campaign_id", payload["campaign_id"]),
                          ("session_id", payload["session_id"]),
                          ("rules_version", payload["ruleset"])):
        require(state.get(key) == expected, "state identity mismatch: " + key)
    require(isinstance(state.get("phase"), str) and bool(state["phase"]),
            "missing phase")
    require(type(state.get("scene_turn")) is int and state["scene_turn"] >= 0,
            "invalid scene_turn")
    require(isinstance(state.get("critical_state_registry"), (dict, list)) and
            bool(state["critical_state_registry"]), "missing critical registry")
    files = payload["canon_files"]
    require(isinstance(files, list) and bool(files), "missing canon")
    identities, filenames = set(), set()
    for item in files:
        require(isinstance(item, dict) and
                {"canon_id", "revision", "filename", "text", "sha256"} <= item.keys(),
                "missing canon fields")
        require(_identifier(item["canon_id"]), "invalid canon_id")
        require((type(item["revision"]) is int and item["revision"] > 0) or
                (isinstance(item["revision"], str) and bool(item["revision"].strip())),
                "invalid canon revision")
        name = item["filename"]
        require(isinstance(name, str) and name not in ("", ".", "..") and
                not any(c in name for c in ("/", "\\", "\x00")), "unsafe filename")
        require(isinstance(item["text"], str) and bool(item["text"].strip()),
                "empty canon text")
        require(_sha(item["sha256"]) and
                digest(item["text"].encode("utf-8")) == item["sha256"],
                "canon hash mismatch")
        identity = (item["canon_id"], str(item["revision"]))
        require(identity not in identities and name not in filenames,
                "duplicate canon identity or filename")
        identities.add(identity)
        filenames.add(name)
    canonical(payload)


def encode(payload):
    validate_payload(payload)
    return canonical({"payload": payload, "payload_sha256": digest(canonical(payload))}) + b"\n"


def decode(raw):
    envelope = parse(raw)
    require(isinstance(envelope, dict) and
            set(envelope) == {"payload", "payload_sha256"}, "invalid envelope")
    payload = envelope["payload"]
    require(_sha(envelope["payload_sha256"]) and
            digest(canonical(payload)) == envelope["payload_sha256"], "payload hash mismatch")
    validate_payload(payload)
    return envelope


def write_verified(path, payload):
    """Freeze once, refuse different bytes at an existing path, reread in full.

    Does not imply download delivery or durable storage on the user's device.
    """
    path = Path(path)
    raw = encode(payload)
    try:
        with path.open("xb") as stream:
            stream.write(raw)
    except FileExistsError:
        require(path.read_bytes() == raw, "refuse overwrite of different save")
    readback = path.read_bytes()
    require(readback == raw, "read-back differs from frozen snapshot")
    return decode(readback)
