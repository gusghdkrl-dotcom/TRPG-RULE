#!/usr/bin/env python3
"""FILE_SAVE_V1 development reference; no network or automatic game integration.

Checks declared restoration coverage and frozen state against actual source
objects. Cannot discover facts already absent from both those objects and the
save. The keeper must still perform STATE_INTEGRITY against the actual game.
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


DOMAINS = {"participants", "npcs", "world", "investigation", "progress",
           "timeline", "effects", "randomness", "procedures", "presentation", "assets"}
INPUT_KINDS = {"setup", "action", "roll", "choice", "handoff", "reaction",
               "visual", "resolve", "ended"}


def pointer_parts(path):
    require(isinstance(path, str) and path.startswith("/"), "invalid state pointer")
    parts = path[1:].split("/")
    require(all(not re.search(r"~(?![01])", part) for part in parts), "invalid pointer escape")
    return [part.replace("~1", "/").replace("~0", "~") for part in parts]


def resolve(state, path):
    value = state
    for part in pointer_parts(path):
        if isinstance(value, dict):
            require(part in value, "missing state path: " + path)
            value = value[part]
        elif isinstance(value, list):
            require(bool(re.fullmatch(r"0|[1-9][0-9]*", part)) and int(part) < len(value),
                    "invalid array path: " + path)
            value = value[int(part)]
        else:
            raise ValueError("path crosses scalar: " + path)
    return value


def inventory(value, path=""):
    """Include containers (even empty), lengths, types and scalar hashes."""
    if isinstance(value, dict):
        require(all(isinstance(key, str) for key in value), "JSON keys must be strings")
        result = {path: {"type": "object", "keys": sorted(value)}}
        for key, child in value.items():
            require(isinstance(key, str), "JSON keys must be strings")
            escaped = key.replace("~", "~0").replace("/", "~1")
            result.update(inventory(child, path + "/" + escaped))
        return result
    if isinstance(value, list):
        result = {path: {"type": "array", "length": len(value)}}
        for i, child in enumerate(value):
            result.update(inventory(child, path + "/" + str(i)))
        return result
    require(value is None or type(value) in (str, int, float, bool), "not a JSON value")
    kind = "null" if value is None else {str: "string", int: "integer", float: "number", bool: "boolean"}[type(value)]
    return {path: {"type": kind, "sha256": digest(canonical(value))}}


def _canon_inventory(files):
    return [{key: f[key] for key in ("canon_id", "revision", "filename", "sha256")} for f in files]


def _validate_registry(state, modern):
    registry = state["critical_state_registry"]
    if not modern:
        return  # Legacy inspection reports structural checks only.
    require(isinstance(registry, list) and bool(registry), "registry must be a path list")
    require(all(isinstance(path, str) for path in registry) and
            len(registry) == len(set(registry)), "duplicate or invalid registry path")
    roots = set()
    for path in registry:
        resolve(state, path)
        parts = pointer_parts(path)
        if len(parts) == 1:
            roots.add(parts[0])
    require(set(state) - {"critical_state_registry"} <= roots,
            "registry does not cover every state root")


def validate_continuity(payload):
    state = payload["state"]
    c = payload.get("continuity")
    require(isinstance(c, dict) and c.get("version") == "RESTORE_V1",
            "continuity contract missing; inspect legacy before upgrading")
    require(c.get("state_sha256") == digest(canonical(state)), "frozen state hash mismatch")
    require(canonical(c.get("state_inventory")) == canonical(inventory(state)),
            "state inventory mismatch")
    require(c.get("canon_inventory") == _canon_inventory(payload["canon_files"]),
            "canon inventory mismatch")
    domains = c.get("domains")
    require(isinstance(domains, dict) and set(domains) == DOMAINS, "missing continuity domain")
    for domain, entry in domains.items():
        require(isinstance(entry, dict), "invalid domain entry")
        require(isinstance(entry.get("status"), str) and entry["status"] in {"present", "empty"},
                "unresolved continuity domain: " + domain)
        paths = entry.get("paths")
        require(isinstance(paths, list) and bool(paths) and all(isinstance(p, str) for p in paths)
                and len(paths) == len(set(paths)), "invalid domain paths")
        values = [resolve(state, path) for path in paths]
        if entry["status"] == "empty":
            require(all(isinstance(v, (dict, list)) and not v for v in values),
                    "empty domain contains data")
            require(isinstance(entry.get("reason"), str) and bool(entry["reason"].strip()),
                    "empty domain needs a factual reason")
        else:
            require(all(v is not None and v != {} and v != [] and v != "" for v in values),
                    "present domain is empty")
    if state["phase"] == "play":
        for domain in ("participants", "world", "timeline", "presentation"):
            require(domains[domain]["status"] == "present", "play needs " + domain)
    refs = c.get("references")
    require(isinstance(refs, list), "missing reference registry")
    for ref in refs:
        require(isinstance(ref, dict) and set(ref) == {"source", "target"}, "invalid reference binding")
        source, target = resolve(state, ref["source"]), resolve(state, ref["target"])
        require(isinstance(source, str) and bool(source) and isinstance(target, dict)
                and target.get("id") == source, "dangling or mismatched entity reference")
    resume = c.get("resume")
    require(isinstance(resume, dict) and
            set(resume) == {"scene_ref", "input_ref", "owner_ref", "pending_ref", "last_output_ref"},
            "missing resume boundary")
    scene = resolve(state, resume["scene_ref"])
    current_input = resolve(state, resume["input_ref"])
    output = resolve(state, resume["last_output_ref"])
    require(isinstance(scene, dict) and isinstance(scene.get("id"), str) and bool(scene["id"]),
            "missing scene identity")
    require(isinstance(output, str) and bool(output.strip()), "missing last public output")
    require(isinstance(current_input, dict) and
            {"kind", "owner_id", "pending_id"} <= current_input.keys(), "missing input state")
    kind = current_input["kind"]
    require(isinstance(kind, str) and kind in INPUT_KINDS, "unsupported input boundary")
    require((state["phase"] == "ended") == (kind == "ended"), "ending/input mismatch")
    require(state["phase"] != "play" or kind != "setup", "play/setup mismatch")
    if current_input["owner_id"] is None:
        require(resume["owner_ref"] is None and kind in {"setup", "ended", "resolve"},
                "input owner missing")
    else:
        owner = resolve(state, resume["owner_ref"])
        require(isinstance(owner, dict) and owner.get("id") == current_input["owner_id"],
                "input owner mismatch")
        require(any(resume["owner_ref"] == path or resume["owner_ref"].startswith(path + "/")
                    for path in domains["participants"]["paths"]), "owner is not a participant")
    if current_input["pending_id"] is None:
        require(resume["pending_ref"] is None and kind in {"setup", "action", "ended"},
                "pending input missing")
    else:
        require(kind not in {"setup", "action", "ended"}, "unexpected pending procedure")
        pending = resolve(state, resume["pending_ref"])
        require(isinstance(pending, dict) and pending.get("id") == current_input["pending_id"],
                "pending identity mismatch")
        require(pending.get("owner_id") == current_input["owner_id"], "pending owner mismatch")
        require(isinstance(pending.get("status"), str) and
                pending["status"] in {"awaiting_input", "resolved", "execution_unknown"},
                "completed or invalid pending state")
        require((kind == "resolve") == (pending["status"] != "awaiting_input"),
                "pending stage/input mismatch")
        require(any(resume["pending_ref"] == path or resume["pending_ref"].startswith(path + "/")
                    for path in domains["procedures"]["paths"]), "pending not in procedures")
    _validate_registry(state, modern=True)


def capture_continuity(payload, *, source_state, source_canons, domains, resume, references):
    """Take a witness from the actual pre-save state, never from a lossy summary.

    This does not invent missing domain/actor information. Coverage assignments
    and semantic truth must be reviewed against the actual game by the keeper.
    """
    require(canonical(payload["state"]) == canonical(source_state), "source state mismatch")
    require(canonical(payload["canon_files"]) == canonical(source_canons), "source canon mismatch")
    c = {"version": "RESTORE_V1", "state_sha256": digest(canonical(source_state)),
         "state_inventory": inventory(source_state), "canon_inventory": _canon_inventory(source_canons),
         "domains": domains, "resume": resume, "references": references}
    result = parse(canonical(payload))  # Detached snapshot, including unknown fields.
    result["continuity"] = parse(canonical(c))
    validate_payload(result)
    return result


def validate_payload(payload, *, require_continuity=True):
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
    if require_continuity:
        validate_continuity(payload)


def encode(payload):
    validate_payload(payload)
    return canonical({"payload": payload, "payload_sha256": digest(canonical(payload))}) + b"\n"


def decode(raw, *, require_continuity=True):
    envelope = parse(raw)
    require(isinstance(envelope, dict) and
            set(envelope) == {"payload", "payload_sha256"}, "invalid envelope")
    payload = envelope["payload"]
    require(_sha(envelope["payload_sha256"]) and
            digest(canonical(payload)) == envelope["payload_sha256"], "payload hash mismatch")
    validate_payload(payload, require_continuity=require_continuity)
    return envelope


def inspect_legacy(raw):
    """Read preserved old bytes for review, not a successful gameplay restore."""
    envelope = decode(raw, require_continuity=False)
    return {"status": "legacy_structure_only", "envelope": envelope,
            "warning": "continuity coverage and resume boundary not verified"}


def write_verified(path, payload, *, source_state, source_canons):
    """Freeze once, refuse different bytes at an existing path, reread in full.

    Does not imply download delivery or durable storage on the user's device.
    """
    path = Path(path)
    require(canonical(payload["state"]) == canonical(source_state), "source state mismatch")
    require(canonical(payload["canon_files"]) == canonical(source_canons), "source canon mismatch")
    raw = encode(payload)
    try:
        with path.open("xb") as stream:
            stream.write(raw)
    except FileExistsError:
        require(path.read_bytes() == raw, "refuse overwrite of different save")
    readback = path.read_bytes()
    require(readback == raw, "read-back differs from frozen snapshot")
    return decode(readback)
