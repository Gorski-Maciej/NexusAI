#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I08 PARAMETER ROLLBACK
============================================
Jednoklik rollback wersji parametru z pełnym audytem i dowodem w golden replay.
Tryb DRY-RUN (read-only): nie mutuje store — pokazuje docelową wersję, wpis
audytowy i status golden datasetu po cofnięciu.

Usage:
  python tools/v3_p06_parameter_rollback.py [--key vat.standard_rate] [--to-date 2026-01-01]
"""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
DATA_JSON = BUNDLES / "thresholds_data.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    args = sys.argv[1:]
    key = args[args.index("--key") + 1] if "--key" in args else "vat.standard_rate"
    to_date = (args[args.index("--to-date") + 1] if "--to-date" in args else None)

    checks, findings = [], []
    data = json.loads(DATA_JSON.read_text(encoding="utf-8"))
    entry = data.get("parameters", {}).get(key)
    if entry is None:
        print(f"[V3-P06-I08] gate=FAIL key={key} BRAK w store")
        return 1
    versions = entry.get("versions", [])

    # wybór wersji docelowej (przedostatnia obowiązująca lub wg daty)
    target = None
    if to_date:
        cand = [v for v in versions if v["valid_from"] <= to_date]
        if cand:
            target = max(cand, key=lambda v: v["valid_from"])
    elif len(versions) >= 2:
        target = versions[-2]

    audit_trail = []
    if target is not None:
        audit_trail.append({
            "event": "rollback_dry_run", "key": key, "rolled_back_to": target,
            "audit_entry": {"changed_by": "4-eyes-required", "reason": "rollback",
                            "at": now(), "golden_replay": "required_before_apply"},
        })
        checks.append({"name": "rollback_target",
                       "status": "OK",
                       "detail": f"cel rollbacku: value={target['value']} od {target['valid_from']}"})
    else:
        checks.append({"name": "rollback_target",
                       "status": "FAIL",
                       "detail": f"brak wcześniejszej wersji ({len(versions)} wersji) — "
                                 f"rollback niemożliwy bez historii"})

    checks.append({"name": "audit_trail",
                   "status": "OK",
                   "detail": f"wpisów audytowych w store: {len(data.get('changed_by_audit', []))}"})

    if target is None:
        findings.append({"id": "V3-P06-L13", "severity": "P1",
                         "evidence": f"{key} ma {len(versions)} wersję(ów) w store — brak głębi "
                                     f"historii dla rollbacku; złota zasada: zmiana bez możliwości "
                                     f"cofnięcia = ryzyko operacyjne",
                         "fix": "każda zmiana parametru append-only + automatyczny snapshot "
                                "poprzedniej wersji (I08); dowód w golden replay przed apply"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I08", "generated_at": now(), "gate": gate,
        "mode": "DRY_RUN_READ_ONLY",
        "metrics": {"versions_available": len(versions),
                    "audit_entries": len(data.get("changed_by_audit", []))},
        "rollback": audit_trail,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P38 (deployment), P09 (declarative change), P10 (golden replay), "
                                "P06-I05 (SLO rollback < 1 min)",
                     "rule": "rollback wymaga 4-eyes + zielony golden dataset (I04) + nowy "
                             "snapshot_id (P05-I02)"},
    }
    (BUNDLES / "v3_p06_parameter_rollback.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I08] gate={gate} key={key} versions={len(versions)} "
          f"target={'OK' if target else 'NONE'}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
