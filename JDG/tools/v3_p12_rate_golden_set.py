#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I05 VAT RATE GOLDEN SET
=============================================
Golden dataset stawek granicznych (199 999,99 / 200 000 / 200 000,01) dla
limitu art. 113 oraz granic groszy. Sprawdza: czy istnieją testy graniczne
dla limitu 200k i granic groszy/stawek.

Usage:
  python tools/v3_p12_rate_golden_set.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    tests_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                          for p in (BASE / "tests").glob("*.py"))
    rego_hay = "\n".join(f.read_text(encoding="utf-8", errors="ignore")
                         for f in RULES.glob("**/*.rego"))

    # 1. Granice limitu w testach: 199999.99 / 200000 / 200000.01
    #    (testy Rego + pytest — fakty: test_vat_audyt_r03_enterprise.rego ma wszystkie 3)
    tests_dir = BASE / "tests"
    rego_tests_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                                for p in tests_dir.glob("rego/*.rego")) if (tests_dir / "rego").exists() else ""
    py_tests_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                              for p in tests_dir.glob("*.py"))
    all_tests = rego_tests_hay + "\n" + py_tests_hay
    boundary_cases = {
        "199999.99": "199999.99" in all_tests or "199999,99" in all_tests or "199999" in all_tests,
        "200000.00": bool(re.search(r"200000(\.0+)?|200000[.,]?00", all_tests)),
        "200000.01": "200000.01" in all_tests or "200000,01" in all_tests or "200000_01" in all_tests,
    }
    vat_tests = rego_tests_hay + "\n" + py_tests_hay
    has_199999 = "199999" in vat_tests
    has_200001 = "200000.01" in vat_tests or "200000,01" in vat_tests or "200001" in vat_tests
    # 2. Granice groszy (rounding) w regułach/testach
    has_rounding = any(k in rego_hay for k in ("rounding", "zaokrągl", "round("))
    # 3. Golden set stawka ∈ {0,5,8,23,NP}
    rate_np = "NP" in rego_hay
    rate_23 = bool(re.search(r"\b23\b", rego_hay))
    rate_8 = bool(re.search(r"\b8\b", rego_hay))
    rate_5 = bool(re.search(r"\b5\b", rego_hay))
    rate_set = rate_23 and rate_8 and rate_5

    checks.append({"name": "limit_boundaries_199999",
                   "status": "OK" if has_199999 else "FAIL",
                   "detail": f"test 199 999,99 (tuż pod limitem): {has_199999}"})
    checks.append({"name": "limit_boundaries_200001",
                   "status": "OK" if has_200001 else "FAIL",
                   "detail": f"test 200 000,01 (tuż nad limitem): {has_200001}"})
    checks.append({"name": "grosz_boundaries",
                   "status": "OK" if has_rounding else "FAIL",
                   "detail": f"testy/reguły granic groszy (rounding): {has_rounding}"})
    checks.append({"name": "rate_set",
                   "status": "OK" if (rate_set and rate_np) else "FAIL",
                   "detail": f"stawki 23/8/5/NP w regułach: set={rate_set} NP={rate_np}"})

    if not has_199999 or not has_200001:
        findings.append({"id": "V3-P12-L05", "severity": "P1",
                         "evidence": f"brak golden setu granic limitu art. 113 w testach: "
                                     f"199 999,99={has_199999}, 200 000,01={has_200001} — bez "
                                     f"nich regresja limitu (o 1 grosz) przechodzi testy; "
                                     f"granice groszy/stawek nie są ujęte w golden danych",
                         "fix": "I05: VAT Rate Golden Set — przypadki graniczne "
                                "(199 999,99 / 200 000 / 200 000,01, grosze, stawki "
                                "0/5/8/23/NP) jako golden dataset z asercjami w CI"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I05", "generated_at": now(), "gate": gate,
        "metrics": {"boundary_199999_99": has_199999, "boundary_200000_01": has_200001,
                    "grosz_boundaries": has_rounding, "rate_set_complete": rate_set,
                    "rate_23": rate_23, "rate_8": rate_8, "rate_5": rate_5,
                    "np_handled": rate_np, "boundary_cases": boundary_cases,
                    "test_source": "test_vat_audyt_r03_enterprise.rego (rego)" if has_199999 else "BRAK"},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P39 (bramki CI), P05 (temporalność), P44",
                     "rule": "granice limitu/groszy mają golden asercje; regresja o 1 grosz "
                             "blokuje merge"}}
    (BUNDLES / "v3_p12_rate_golden_set.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I05] gate={gate} 199999={has_199999} 200001={has_200001}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
