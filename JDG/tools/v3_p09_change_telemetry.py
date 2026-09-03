#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I10 CHANGE TELEMETRY
==========================================
SLO procesu deklaracji: czas deklaracja→produkcja, liczba odrzuceń z powodami,
obciążenie ról (declared_by/reviewers), rozkład typów zmian. Metryki dla P37.

Usage:
  python tools/v3_p09_change_telemetry.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"

SLO = {"decl_to_prod_days": 14, "rejection_rate_max_pct": 20,
       "reviewer_pool_min": 2}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    changes_path = BASE / "bundles" / "declarative_changes.json"
    history = {"changes": []}
    if changes_path.exists():
        try:
            history = json.loads(changes_path.read_text(encoding="utf-8"))
        except Exception:
            history = {"changes": []}
    changes = history.get("changes", [])

    checks.append({"name": "slo_defined", "status": "OK",
                   "detail": f"SLO: decl→prod ≤ {SLO['decl_to_prod_days']} dni, odrzucenia "
                             f"≤ {SLO['rejection_rate_max_pct']}%"})
    checks.append({"name": "telemetry_recorded", "status": "FAIL" if not changes else "OK",
                   "detail": f"zapisane deklaracje: {len(changes)} — brak danych do pomiaru "
                             "SLO (czas/odrzucenia/role)"})

    findings.append({"id": "V3-P09-L10", "severity": "P2",
                     "evidence": "bundles/declarative_changes.json nie zawiera wykonanych "
                                 "deklaracji; brak pól timestamps (declared_at/approved_at/"
                                 "executed_at), rejection_reason i ról — SLO deklaracja→"
                                 "produkcja i wskaźnik odrzuceń niemierzalne",
                     "fix": "I10 Change Telemetry: każda deklaracja z timestamps roli i "
                            "statusu; raport SLO (czas, odrzucenia z powodami, obciążenie "
                            "ról) do P37"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I10", "generated_at": now(), "gate": gate,
        "metrics": {"slo": SLO, "recorded_declarations": len(changes)},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P37 (metryki), P41 (UI), P43 (role)",
                     "rule": "każda deklaracja rejestruje declared_at/approved_at/"
                             "executed_at + rejection_reason; SLO decl→prod ≤ 14 dni"}}
    (BUNDLES / "v3_p09_change_telemetry.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I10] gate={gate} recorded={len(changes)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
