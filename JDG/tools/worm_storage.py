#!/usr/bin/env python3
"""
NexusAI JDG — WORM STORAGE INTERFACE (PROMPT 21 CONTROL PLANE, V1 §11 / ADR-006)
================================================================================
Write-Once-Read-Many interfejs dla niezmiennego audytu control-plane.
Gwarancje:
  • append-only — wpis może być dodany tylko raz (record_id unikalny),
  • tamper-evident — każdy wpis zawiera hash poprzedniego (łańcuch),
    a całość zamyka Merkle-root-lite (SHA-256 całego łańcucha),
  • fail-closed — każda próba modyfikacji/usunięcia istniejącego wpisu
    jest odrzucana z kodem 2,
  • zewnętrzny WORM (Object Lock S3 / CD-ROM / HSM) podłączany przez
    adapter — lokalny plik JSON jest buforem, nie certyfikacją.

Obiekt docelowy: wpisy audytowe z control_plane_lifecycle (AUD-*), werdykty
(decision certificates), zdarzenia prawne (law radar) — wspólny interfejs.

Usage:
  python worm_storage.py write --record '{"event": "CHANGE_SUBMITTED", "change_id": "CHG-00000001"}'
  python worm_storage.py chain
  python worm_storage.py verify
  python worm_storage.py read --record-id 1
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parent.parent
WORM_PATH = JDG_ROOT / "bundles" / "worm_audit.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha256(data: str) -> str:
    return hashlib.sha256(data.encode("utf-8")).hexdigest()


def _load() -> dict:
    if WORM_PATH.exists():
        return json.loads(WORM_PATH.read_text(encoding="utf-8"))
    return {"schema_version": "1.0.0", "records": [], "policy": "APPEND_ONLY"}


def _save(data: dict) -> None:
    WORM_PATH.parent.mkdir(parents=True, exist_ok=True)
    WORM_PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def _record_hash(payload: dict, prev_hash: str) -> str:
    body = json.dumps({"payload": payload, "prev_hash": prev_hash},
                      ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return sha256(body)


def write_record(payload: dict, *, source: str = "cli") -> dict:
    """Dodaj wpis append-only. Zwraca record_id i hash łańcucha."""
    data = _load()
    record_id = len(data["records"]) + 1
    prev_hash = data["records"][-1]["record_hash"] if data["records"] else ("0" * 64)
    record = {
        "record_id": record_id,
        "record_hash": _record_hash(payload, prev_hash),
        "prev_hash": prev_hash,
        "payload": payload,
        "source": source,
        "written_at": now(),
    }
    data["records"].append(record)
    data["merkle_root"] = sha256(json.dumps(
        [r["record_hash"] for r in data["records"]], separators=(",", ":")))
    _save(data)
    return record


def verify_chain() -> dict:
    """Weryfikacja integralności łańcucha: hashe + prev_hash + merkle root."""
    data = _load()
    issues = []
    prev = "0" * 64
    for r in data["records"]:
        expected = _record_hash(r["payload"], r["prev_hash"])
        if r["prev_hash"] != prev:
            issues.append(f"record {r['record_id']}: prev_hash nie zgadza się z poprzednim")
        if r["record_hash"] != expected:
            issues.append(f"record {r['record_id']}: record_hash nie pasuje do payload")
        prev = r["record_hash"]
    root = sha256(json.dumps([r["record_hash"] for r in data["records"]], separators=(",", ":")))
    if data.get("merkle_root") != root:
        issues.append("merkle_root nie pasuje do łańcucha")
    return {"records": len(data["records"]), "merkle_root": data.get("merkle_root"),
            "verified": not issues, "issues": issues,
            "policy": data.get("policy", "APPEND_ONLY")}


def cmd_write(args) -> None:
    payload = json.loads(args.record)
    record = write_record(payload, source=args.source)
    print(json.dumps({"record_id": record["record_id"],
                      "record_hash": record["record_hash"][:16] + "…",
                      "prev_hash_linked": record["prev_hash"] != "0" * 64,
                      "policy": "APPEND_ONLY"},
                     indent=2, ensure_ascii=False))


def cmd_chain(args) -> None:
    data = _load()
    print(json.dumps({"records": len(data["records"]),
                      "merkle_root": data.get("merkle_root"),
                      "records_preview": [
                          {"record_id": r["record_id"], "hash": r["record_hash"][:16] + "…",
                           "source": r["source"]} for r in data["records"][-10:]],
                      "policy": data.get("policy", "APPEND_ONLY")},
                     indent=2, ensure_ascii=False))


def cmd_verify(args) -> None:
    result = verify_chain()
    print(json.dumps(result, indent=2, ensure_ascii=False))
    if not result["verified"]:
        sys.exit(2)


def cmd_read(args) -> None:
    data = _load()
    record = next((r for r in data["records"] if r["record_id"] == args.record_id), None)
    if record is None:
        sys.exit(f"❌ Brak wpisu {args.record_id}")
    print(json.dumps(record, indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="WORM Storage — niezmienny audyt control-plane (V1 §11)")
    sub = p.add_subparsers(dest="cmd", required=True)
    w = sub.add_parser("write"); w.add_argument("--record", required=True)
    w.add_argument("--source", default="cli"); w.set_defaults(fn=cmd_write)
    c = sub.add_parser("chain"); c.set_defaults(fn=cmd_chain)
    v = sub.add_parser("verify"); v.set_defaults(fn=cmd_verify)
    r = sub.add_parser("read"); r.add_argument("--record-id", type=int, required=True)
    r.set_defaults(fn=cmd_read)
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
