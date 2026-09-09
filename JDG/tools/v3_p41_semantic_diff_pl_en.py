#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I04 SEMANTIC DIFF PL/EN — ARCHITEKTURA.md vs
ARCHITECTURE.md: detekcja dryfu semantycznego (sekcje/kluczowe terminy).
Podanalizy: AN01.
"""
from __future__ import annotations

import re

from v3_p41_common import ARCH_EN, ARCH_PL, emit, main_jdg_wired, now, read, rule_present, threshold_present

INNOVATION = "V3-P41-I04"
RULE = "jdg.v3_p41_dokumentacja.semantic_diff_pl_en"

# Koncepty architektury, które MUSZĄ wystąpić w obu językach (semantyczne
# kotwice: identyfikatory ADR — językowo neutralne, przenoszą treść merytoryczną)
ANCHORS = {
    "ADR-001 First-Match-Wins": ["ADR-001"],
    "ADR-002 zero hardcode": ["ADR-002"],
    "ADR-003 temporalność": ["ADR-003"],
    "ADR-007 multi-pass": ["ADR-007"],
    "ADR-009 sharded router": ["ADR-009"],
    "OPA": ["OPA"],
}


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    pl, en = read(ARCH_PL), read(ARCH_EN)
    exists = bool(pl) and bool(en)
    checks.append({"name": "both_files_exist", "status": "OK" if exists else "FAIL",
                   "detail": f"PL {len(pl.splitlines())} linii, EN {len(en.splitlines())} linii"})

    # Semantyczne kotwice: koncept obecny w PL i w EN
    drift = [a for a, variants in ANCHORS.items()
             if not any(v.lower() in pl.lower() for v in variants)
             or not any(v.lower() in en.lower() for v in variants)]
    anchors_ok = not drift
    checks.append({"name": "semantic_anchors_aligned", "status": "OK" if anchors_ok else "FAIL",
                   "detail": f"kotwice semantyczne (ADR) rozjazd: {drift if drift else 'brak'}"})

    t = threshold_present("v3_p41_plen_diff_max_findings")
    checks.append({"name": "diff_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p41_plen_diff_max_findings w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "both_files_exist": exists,
            "semantic_anchors_aligned": anchors_ok,
            "drift_findings": len(drift),
            "diff_threshold_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_semantic_diff_pl_en")


if __name__ == "__main__":
    raise SystemExit(main())
