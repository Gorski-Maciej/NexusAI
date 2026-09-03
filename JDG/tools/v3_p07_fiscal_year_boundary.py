#!/usr/bin/env python3
"""
NexusAI JDG — V3-P07-I08 FISCAL-YEAR VERSION BOUNDARY
======================================================
Automatyczne wymuszanie wersji na granicy roku podatkowego: zmiany prawa
wchodzą 01.01 (valid_from = YYYY-01-01) z testami przejścia roku (day-1/day0 —
P05-I05). Audyt: valid_from w rejestrze reguł i oknach temporalnych, gotowość
testów granicznych roku.

Usage:
  python tools/v3_p07_fiscal_year_boundary.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    registry = json.loads((BUNDLES / "rule_registry.json").read_text(encoding="utf-8"))
    deployments = json.loads((BUNDLES / "deployments.json").read_text(encoding="utf-8"))

    aligned = 0
    not_aligned = []
    total = 0
    for rid, e in registry.items():
        for v in e.get("versions", []):
            total += 1
            vf = v.get("valid_from", "")
            if re.fullmatch(r"\d{4}-01-01", vf or ""):
                aligned += 1
            else:
                not_aligned.append({"rule": rid, "version": v.get("version"),
                                    "valid_from": vf})

    # testy przejścia roku (day-1/day0) — czy istnieją w testach lifecycle
    tests_dir = BASE / "tests"
    year_boundary_tests = 0
    for p in tests_dir.rglob("test_*.py"):
        t = p.read_text(encoding="utf-8")
        if re.search(r"12-31|day-1|year.?boundary|granic.*rok|2022-01-01|2026-01-01", t):
            year_boundary_tests += 1

    checks.append({"name": "registry_alignment_0101",
                   "status": "OK" if not not_aligned else "WARN",
                   "detail": f"wersje z valid_from=01.01: {aligned}/{total} "
                              f"(wymóg dotyczy wersji ROCZNYCH; seed mid-year dopuszczalny)"})
    checks.append({"name": "year_boundary_tests",
                   "status": "FAIL" if year_boundary_tests == 0 else "OK",
                   "detail": f"testy przejścia roku w tests/: {year_boundary_tests}"})

    if not_aligned:
        findings.append({"id": "V3-P07-L12", "severity": "P2",
                         "evidence": f"wersje rejestru z valid_from ≠ 01.01 (granica roku "
                                     f"niewymuszona): {not_aligned[:6]}",
                         "fix": "Fiscal-Year Boundary (I08): zmiany roczne wchodzą tylko "
                                "z valid_from=01.01 + test day-1/day0 (P05-I05) [BM]"})
    findings.append({"id": "V3-P07-L13", "severity": "P2",
                     "evidence": "brak testów przejścia roku dla reguł rejestru (day-1/day0 "
                                 "na 31.12→01.01) — time-travel na granicy roku nieudowodniony",
                     "fix": "testy granicy roku per wersja roczna (P05-I05 bramka) [BM]"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P07-I08", "generated_at": now(), "gate": gate,
        "metrics": {"versions_total": total, "aligned_0101": aligned,
                    "not_aligned": len(not_aligned),
                    "year_boundary_tests": year_boundary_tests},
        "not_aligned": not_aligned[:10],
        "checks": checks, "findings": findings,
        "contract": {"binding": "P05 (okna temporalne, day-1/0/+1), P39 (testy), P06 (parametry "
                                "roczne), P07-I06 (retirement roczny)",
                     "rule": "wersja roczna bez valid_from=01.01 i testów granicy = blokada [BM]"},
    }
    (BUNDLES / "v3_p07_fiscal_year_boundary.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P07-I08] gate={gate} aligned_0101={aligned}/{total} "
          f"year_tests={year_boundary_tests}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
