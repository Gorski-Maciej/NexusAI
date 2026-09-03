#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I11 EMERGENCY RUNBOOK DSL
==============================================
Deklaratywne runbooki awaryjne: scenariusz → kroki → weryfikacja, z testami
tabletop. Definiuje wymagane runbooki (kill-switch, auto-rollback, freeze P04,
degradacja, przywrócenie healthy) i sprawdza ich obecność w repo.

Usage:
  python tools/v3_p07_emergency_runbook.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"

REQUIRED_RUNBOOKS = [
    {"id": "RB-01", "scenario": "kill-switch reguły (suspend < 1 s)",
     "steps": ["identyfikacja reguły", "cmd_suspend", "weryfikacja NEEDS_ADVICE",
               "alert + audyt"], "verify": "status SUSPENDED + brak wpływu na werdykty"},
    {"id": "RB-02", "scenario": "auto-rollback wersji (error_rate > próg)",
     "steps": ["detekcja przekroczenia", "rollback do supersedes",
               "golden replay (P10)"], "verify": "status ROLLED_BACK + golden zielony"},
    {"id": "RB-03", "scenario": "freeze domeny (2× BLOCK/24h — P04)",
     "steps": ["eskalacja P04", "FREEZE", "4-eyes odblokowanie"],
     "verify": "domena FROZEN + zielony test negatywny"},
    {"id": "RB-04", "scenario": "przywrócenie healthy_versions",
     "steps": ["wybór wersji zdrowej", "deployment", "soak + delta ≤ 2%"],
     "verify": "active_version ∈ healthy_versions"},
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    # szukamy DEDYKOWANYCH artefaktów runbooków (nazwa pliku/docs zawiera 'runbook')
    docs_dir = BASE / "docs"
    runbook_artifacts = [p for p in docs_dir.rglob("*") if "runbook" in p.name.lower()]
    found_runbooks = []
    if runbook_artifacts:
        blob = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                          for p in runbook_artifacts).lower()
        for rb in REQUIRED_RUNBOOKS:
            if rb["scenario"].split(" ")[0].lower() in blob or rb["id"].lower() in blob:
                found_runbooks.append(rb["id"])

    missing = [rb["id"] for rb in REQUIRED_RUNBOOKS if rb["id"] not in found_runbooks]

    checks.append({"name": "runbook_artifacts",
                   "status": "FAIL" if not runbook_artifacts else "OK",
                   "detail": f"dedykowane artefakty runbook w docs/: "
                              f"{[p.name for p in runbook_artifacts] or 'BRAK'}"})
    checks.append({"name": "runbook_coverage",
                   "status": "OK" if not missing else "FAIL",
                   "detail": f"pokrycie scenariuszy: {len(found_runbooks)}/{len(REQUIRED_RUNBOOKS)}; "
                             f"brak: {missing}"})
    checks.append({"name": "tabletop_tests",
                   "status": "FAIL",
                   "detail": "testy tabletop (odgrywanie scenariusza na staging) nie istnieją "
                             "jako artefakt"})

    if missing:
        findings.append({"id": "V3-P07-L17", "severity": "P2",
                         "evidence": f"brak deklaratywnych runbooków awaryjnych: {missing} — "
                                     f"reakcja na incydent zależna od wiedzy operatora",
                         "fix": "Emergency Runbook DSL (I11): scenariusze w repo + testy "
                                "tabletop w CI (P43)"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I11", "generated_at": now(), "gate": gate,
        "metrics": {"required": len(REQUIRED_RUNBOOKS), "found": len(found_runbooks),
                    "missing": len(missing)},
        "runbooks": REQUIRED_RUNBOOKS,
        "missing": missing,
        "checks": checks, "findings": findings,
        "dsl": {"scenario": "id + opis", "steps": "kroki operacyjne",
                "verify": "warunek sukcesu (fail-closed)", "owner": "rola 4-eyes (I05)"},
        "contract": {"binding": "P43 (security/DR), P39 (tabletop w CI), P04 (freeze), "
                                "P07-I04 (kill-switch), P07-I06 (rollback)",
                     "rule": "incydent bez runbooka = eskalacja 4-eyes; runbook bez testu "
                             "tabletop = P2"},
    }
    (BUNDLES / "v3_p07_emergency_runbook.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I11] gate={gate} runbooks_found={len(found_runbooks)}/"
          f"{len(REQUIRED_RUNBOOKS)} missing={missing}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
