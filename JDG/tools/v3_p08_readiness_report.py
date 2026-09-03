#!/usr/bin/env python3
"""
NexusAI JDG — V3-P08-I10 COMPLIANCE READINESS REPORT
=====================================================
Tygodniowy raport: co się zmienia w prawie i czy silnik jest gotowy.
Status per zmiana: GOTOWE (SHADOW+CANDIDATE+ACTIVE) / W_PRZYGOTOWANIU /
NIE_GOTOWE, z listą reguł i datą wejścia.

Usage:
  python tools/v3_p08_readiness_report.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def readiness_of(change: dict) -> str:
    prepared = change.get("rules_prepared") or []
    if not prepared:
        return "NIE_GOTOWE"
    return "W_PRZYGOTOWANIU"


def main() -> int:
    checks, findings = [], []
    radar = json.loads((BUNDLES / "law_radar.json").read_text(encoding="utf-8"))
    cal = json.loads((BUNDLES / "legal_change_calendar.json").read_text(encoding="utf-8"))
    drafts = radar.get("drafts", {})
    changes = cal.get("changes", {})

    states = {}
    for cid, ch in changes.items():
        states[cid] = readiness_of(ch)
    ready = sum(1 for s in states.values() if s == "GOTOWE")

    checks.append({"name": "readiness_per_change", "status": "FAIL" if ready == 0 else "OK",
                   "detail": f"statusy: {states}"})
    checks.append({"name": "weekly_report_artifact", "status": "FAIL",
                   "detail": "brak artefaktu cyklicznego raportu gotowości (weekly)"})

    findings.append({"id": "V3-P08-L10", "severity": "P2",
                     "evidence": f"kalendarz: {len(changes)} zmiana(y), wszystkie "
                                 f"{'NIE_GOTOWE' if ready == 0 else ''} (rules_prepared=[] w "
                                 "DRL-0001); brak tygodniowego raportu gotowości — zespół nie "
                                 "ma jednego miejsca 'co się zmienia i czy silnik jest gotowy'",
                     "fix": "I10 Compliance Readiness Report: generator weekly z macierzy "
                            "(I05) + stanów lifecycle (P07) per zmiana"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P08-I10", "generated_at": now(), "gate": gate,
        "metrics": {"changes": len(changes), "ready": ready,
                    "states": states, "drafts": len(drafts)},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P08-I04 (lead time), P08-I05 (impact), P07 (lifecycle), "
                                "P37 (raport cykliczny)",
                     "rule": "raport tygodniowy: per zmiana status GOTOWE/"
                             "W_PRZYGOTOWANIU/NIE_GOTOWE + reguły + data wejścia"},
    }
    (BUNDLES / "v3_p08_readiness_report.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P08-I10] gate={gate} changes={len(changes)} ready={ready}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
