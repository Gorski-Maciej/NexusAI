#!/usr/bin/env python3
"""
NexusAI JDG — MIRROR SYNC GATE (V3-P02-I11)
============================================
CI: mirror policies/jdg/main_jdg.rego musi być bit-do-bit zgodny z canonical
albo wymusza sync. Narzędzie porównuje canonical (JDG/rules/*.rego) z mirror
(policies/jdg/*.rego). Mirror jest w repo na branchu policies — lokalnie może
nie być dostępny; wtedy czyta ostatni raport dryfu (v3_mirror_delta.json z
P00) i klasyfikuje stan. Różnica semantyczna = blokada merge (K6 P00).

Czyta:  rules/*.rego (canonical), policies/jdg/*.rego (jeśli dostępny),
        bundles/v3_mirror_delta.json (ostatni pomiar dryfu)
Pisze:  bundles/v3_p02_mirror_sync_gate.json

Usage:
  python v3_p02_mirror_sync_gate.py [--json] [--write] [--gate]
"""
from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
CANON_FILES = ["main_jdg.rego", "routing.rego", "fallback.rego", "conflicts.rego"]
CANON_DIR = BASE_DIR / "rules"
MIRROR_DIR = BASE_DIR.parent / "policies" / "jdg"  # repo-root policies/jdg
MIRROR_DELTA = BASE_DIR / "bundles" / "v3_mirror_delta.json"
OUT_JSON = BASE_DIR / "bundles" / "v3_p02_mirror_sync_gate.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build() -> dict:
    checks = []
    mirror_available = MIRROR_DIR.exists()
    for fname in CANON_FILES:
        canon = CANON_DIR / fname
        mirror = MIRROR_DIR / fname
        if not canon.exists():
            checks.append({"file": fname, "canonical": "BRAK", "mirror": "-",
                           "state": "CANONICAL_MISSING"})
            continue
        if mirror_available and mirror.exists():
            same = sha256(canon) == sha256(mirror)
            checks.append({"file": fname, "canonical": "OK", "mirror": "OK",
                           "bit_exact": same,
                           "state": "SYNC" if same else "DRYF_BIT_EXACT"})
        else:
            checks.append({"file": fname, "canonical": "OK", "mirror": "NIE_DOSTĘPNY",
                           "state": "NIEZWERYFIKOWANO"})

    # ostatni pomiar z P00
    delta = {}
    if MIRROR_DELTA.exists():
        try:
            delta = json.loads(MIRROR_DELTA.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            delta = {}
    last_delta = {
        "canonical_rego": delta.get("counts", {}).get("canonical_rego"),
        "mirror_rego": delta.get("counts", {}).get("mirror_rego"),
        "files_content_diff": delta.get("counts", {}).get("files_content_diff"),
        "status": delta.get("status"),
        "orchestrator_files_diff": [f for f in ("main_jdg.rego", "routing.rego",
                                                "fallback.rego", "conflicts.rego")
                                    if f in [d.get("file") for d in delta.get("content_diffs", [])]],
    }

    states = {c["state"] for c in checks}
    drifts = [c for c in checks if c["state"] == "DRYF_BIT_EXACT"]
    unverified = [c for c in checks if c["state"] == "NIEZWERYFIKOWANO"]

    gate_pass = mirror_available and len(drifts) == 0
    return {
        "innovation": "V3-P02-I11",
        "name": "Mirror Sync Gate — mirror bit-do-bit zgodny z canonical",
        "generated_at": now(),
        "mirror_available_locally": mirror_available,
        "checks": checks,
        "last_mirror_delta_p00": last_delta,
        "states": sorted(states),
        "drifts": drifts,
        "unverified": unverified,
        "gate": {"pass": gate_pass,
                 "rule": "K6 P00: mirror policies/jdg musi być bit-exact z canonical; "
                         "dryf semantyczny blokuje merge (P39); sync tylko przez bundle.sh "
                         "po zatwierdzeniu diff (I05 P00)"},
        "note": "lokalnie mirror niedostępny (branch policies) → NIEZWERYFIKOWANO z "
                "odwołaniem do ostatniego pomiaru v3_mirror_delta.json (P00): "
                "4 pliki orkiestratora w content_diff — wymagany sync przed P38/P40.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Mirror Sync Gate (V3-P02-I11)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P02-I11 Mirror Sync Gate: mirror_local={data['mirror_available_locally']} "
              f"drifts={len(data['drifts'])} unverified={len(data['unverified'])} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: dryf mirror↔canonical (wymagany sync)")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
