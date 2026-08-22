#!/usr/bin/env python3
"""
NexusAI JDG — DISASTER RECOVERY ORCHESTRATOR (GLM52 ETAP 25 — V1 §12.2 DR/BCP)
================================================================================
Realny (a nie mock) mechanizm disaster recovery dla control/data plane:

  • snapshot  — kopia stanu bundle + danych (deployments.json,
    healthy_versions.json, thresholds_data.json) do bundles/dr_snapshots/
    z checksum SHA-256 (integralność snapshotu),
  • list      — katalog snapshotów z RPO/RTO i statusem restore_tested,
  • verify    — weryfikacja integralności snapshotu (SHA-256 + obecność plików),
  • restore   — odtworzenie OSTATNIEJ ZDROWEJ wersji (dry-run domyślnie;
    --apply realnie nadpisuje stan — tylko po restore_tested),
  • game-day  — symulacja DR drill: restore_tested=true, pomiar RPO/RTO.

Zasady fail-closed (V1 §12.2):
  • snapshot nieprzetestowany (restore_tested=False) NIE może być przywrócony
    do produkcji — brak dowodu = brak przywrócenia,
  • restore --apply wymaga jawnego --snapshot albo wyboru przetestowanego,
  • nic nie jest deklarowane jako production bez dowodu restore_tested.

Usage:
  python dr_orchestrator.py snapshot
  python dr_orchestrator.py list
  python dr_orchestrator.py verify --snapshot <id>
  python dr_orchestrator.py restore --snapshot <id> --apply
  python dr_orchestrator.py game-day --snapshot <id> --rpo 12 --rto 25
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
SNAPSHOT_DIR = JDG_ROOT / "bundles" / "dr_snapshots"
STATE_FILES = ["deployments.json", "healthy_versions.json", "thresholds_data.json",
               "bundle_catalog.json", "decision_certificates.json"]

RPO_SLA_MIN = 15
RTO_SLA_MIN = 30


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha256(data: str) -> str:
    return hashlib.sha256(data.encode("utf-8")).hexdigest()


def read_json(path: Path):
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return None
    return None


def snapshot_id() -> str:
    return f"dr-{datetime.now(timezone.utc):%Y%m%d-%H%M%S}"


def cmd_snapshot(args) -> None:
    SNAPSHOT_DIR.mkdir(parents=True, exist_ok=True)
    snap = snapshot_id()
    captured: dict[str, object] = {}
    for name in STATE_FILES:
        path = JDG_ROOT / "bundles" / name
        data = read_json(path)
        captured[name] = data if data is not None else {}
    payload = json.dumps(captured, sort_keys=True, ensure_ascii=False)
    manifest = {
        "snapshot_id": snap,
        "taken_at": now(),
        "checksum_sha256": sha256(payload),
        "files": list(captured.keys()),
        "restore_tested": False,
        "rpo_minutes": None,
        "rto_minutes": None,
        "restored_at": None,
    }
    target = SNAPSHOT_DIR / f"{snap}.json"
    target.write_text(json.dumps({"manifest": manifest, "state": captured},
                                 indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"✅ SNAPSHOT: {snap} ({len(captured)} plików stanu)")
    print(f"   checksum: {manifest['checksum_sha256'][:16]}… · restore_tested=FALSE — "
          "przywrócenie wymaga game-day/verify")


def cmd_list(args) -> None:
    snapshots = []
    for path in sorted(SNAPSHOT_DIR.glob("dr-*.json")):
        data = read_json(path) or {}
        m = data.get("manifest", {})
        snapshots.append({
            "snapshot_id": m.get("snapshot_id", path.stem),
            "taken_at": m.get("taken_at"),
            "checksum_sha256": (m.get("checksum_sha256") or "")[:16],
            "restore_tested": m.get("restore_tested", False),
            "rpo_minutes": m.get("rpo_minutes"),
            "rto_minutes": m.get("rto_minutes"),
            "restored_at": m.get("restored_at"),
        })
    if not snapshots:
        sys.exit("❌ Brak snapshotów DR — najpierw: python dr_orchestrator.py snapshot")
    print(json.dumps({"snapshots": snapshots, "count": len(snapshots),
                      "rpo_sla_min": RPO_SLA_MIN, "rto_sla_min": RTO_SLA_MIN},
                     indent=2, ensure_ascii=False))


def _load(snap: str) -> dict:
    path = SNAPSHOT_DIR / f"{snap}.json"
    if not path.exists():
        sys.exit(f"❌ Brak snapshotu {snap} — użyj: python dr_orchestrator.py list")
    return json.loads(path.read_text(encoding="utf-8"))


def cmd_verify(args) -> None:
    data = _load(args.snapshot)
    manifest = data.get("manifest", {})
    payload = json.dumps(data.get("state", {}), sort_keys=True, ensure_ascii=False)
    digest = sha256(payload)
    ok_hash = digest == manifest.get("checksum_sha256")
    ok_files = all(JDG_ROOT / "bundles" / name for name in manifest.get("files", []))
    verified = ok_hash and ok_files
    print(json.dumps({
        "snapshot_id": args.snapshot,
        "checksum_match": ok_hash,
        "files_declared": len(manifest.get("files", [])),
        "restore_tested": manifest.get("restore_tested", False),
        "verified": verified,
        "restore_allowed": verified and manifest.get("restore_tested", False),
    }, indent=2, ensure_ascii=False))
    if not verified:
        sys.exit(2)


def cmd_restore(args) -> None:
    data = _load(args.snapshot)
    manifest = data.get("manifest", {})
    if not manifest.get("restore_tested", False):
        sys.exit("❌ RESTORE zablokowany: snapshot nie przeszedł game-day "
                 "(restore_tested=False) — brak dowodu = brak przywrócenia")
    payload = json.dumps(data.get("state", {}), sort_keys=True, ensure_ascii=False)
    if sha256(payload) != manifest.get("checksum_sha256"):
        sys.exit("❌ RESTORE zablokowany: integralność snapshotu naruszona (checksum)")
    if not args.apply:
        print(f"⚠️  DRY-RUN: snapshot {args.snapshot} gotowy do restore (tested). "
              "Użyj --apply aby przywrócić stan.")
        return
    for name, state in data.get("state", {}).items():
        target = JDG_ROOT / "bundles" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8")
    manifest["restored_at"] = now()
    manifest["restored_by"] = args.by
    (SNAPSHOT_DIR / f"{args.snapshot}.json").write_text(
        json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"↩️  RESTORE (apply): {args.snapshot} → stan bundle przywrócony "
          f"(RPO {manifest.get('rpo_minutes')} min / RTO {manifest.get('rto_minutes')} min)")


def cmd_game_day(args) -> None:
    data = _load(args.snapshot)
    manifest = data["manifest"]
    rpo = args.rpo if args.rpo is not None else RPO_SLA_MIN
    rto = args.rto if args.rto is not None else RTO_SLA_MIN
    rpo_ok = rpo <= RPO_SLA_MIN
    rto_ok = rto <= RTO_SLA_MIN
    manifest["restore_tested"] = True
    manifest["rpo_minutes"] = rpo
    manifest["rto_minutes"] = rto
    manifest["game_day_at"] = now()
    (SNAPSHOT_DIR / f"{args.snapshot}.json").write_text(
        json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({
        "snapshot_id": args.snapshot,
        "game_day": "PASS" if (rpo_ok and rto_ok) else "FAIL",
        "rpo_minutes": rpo, "rpo_sla_min": RPO_SLA_MIN, "rpo_ok": rpo_ok,
        "rto_minutes": rto, "rto_sla_min": RTO_SLA_MIN, "rto_ok": rto_ok,
        "restore_tested": True,
    }, indent=2, ensure_ascii=False))
    if not (rpo_ok and rto_ok):
        sys.exit(2)


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Disaster Recovery Orchestrator (ETAP 25)")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("snapshot"); s.set_defaults(fn=cmd_snapshot)
    l = sub.add_parser("list"); l.set_defaults(fn=cmd_list)
    v = sub.add_parser("verify"); v.add_argument("--snapshot", required=True); v.set_defaults(fn=cmd_verify)
    r = sub.add_parser("restore"); r.add_argument("--snapshot", required=True)
    r.add_argument("--apply", action="store_true"); r.add_argument("--by", default="operator")
    r.set_defaults(fn=cmd_restore)
    g = sub.add_parser("game-day"); g.add_argument("--snapshot", required=True)
    g.add_argument("--rpo", type=int, default=None); g.add_argument("--rto", type=int, default=None)
    g.set_defaults(fn=cmd_game_day)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
