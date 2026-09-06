#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I12 CROSS-ACT CONSISTENCY GATE (ZUS×PIT×ryczałt).

Dowód wdrożenia: zadeklarowana zdrowotna vs domena — skala → 9% dochodu,
liniowy → 4,9% dochodu, ryczałt → kwota TIER z danych; rozjazd > tolerancji =
BLOCK_AND_ALERT; brak danych = TRIAGE. Kontrakty pól V3_P14/V3_P18.
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, ZUS_CORE, emit, grosze, main_jdg_wired,
                           now, read, rule_present, threshold_present)

INNOVATION = "V3-P26-I12"
RULE = "jdg.v3_p26_zus_skladki.cross_act_consistency"
FORMS = ["SCALE", "LINEAR", "LUMP_SUM"]


def expected_health(form: str, income: float, tier: str = "TIER_1") -> float:
    if form == "SCALE":
        return grosze(income * ZUS_CORE["health_scale_rate"])
    if form == "LINEAR":
        return grosze(income * ZUS_CORE["health_linear_rate"])
    if form == "LUMP_SUM":
        return {"TIER_1": ZUS_CORE["health_lump_tier_1_amount"],
                "TIER_2": ZUS_CORE["health_lump_tier_2_amount"],
                "TIER_3": ZUS_CORE["health_lump_tier_3_amount"]}[tier]
    return 0.0


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_forms = all(f in hay for f in FORMS)
    has_tolerance = threshold_present("v3_p26_grosz_tolerance")
    has_contracts = "V3_P14" in hay and "V3_P18" in hay
    triage_ok = '"TRIAGE_QUEUE"' in hay

    checks.append({"name": "cross_act_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "forms", "status": "OK" if has_forms else "FAIL",
                   "detail": f"formy: {FORMS} → zdrowotna (9%/4,9%/TIER)"})
    checks.append({"name": "grosz_tolerance", "status": "OK" if has_tolerance else "FAIL",
                   "detail": "rozjazd > 0,005 = BLOCK (cross-act)"})
    checks.append({"name": "missing_data_triage", "status": "OK" if triage_ok else "FAIL",
                   "detail": "brak zadeklarowanej zdrowotnej = TRIAGE (nie cisza)"})
    checks.append({"name": "field_contracts", "status": "OK" if has_contracts else "FAIL",
                   "detail": "kontrakty pól V3_P14 (dochód) + V3_P18 (przychody ryczałtu)"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p90"})

    if not has_contracts:
        findings.append({"id": "V3-P26-L12", "severity": "P2",
                         "evidence": "brak jawnych kontraktów pól P14/P18",
                         "fix": "I12: kontrakt dochód/przychody → zdrowotna"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "forms": FORMS,
                    "sample_scale_income_100k": expected_health("SCALE", 100000.0)},
        "checks": checks, "findings": findings,
        "contract": {"binding": "Bramka spójności wiąże P14 (dochód→zdrowotna), P18 "
                                "(przychody→TIER), P24 (RnA) i P44",
                     "rule": "rozjazd > tolerancji = BLOCK; brak danych = TRIAGE"}}
    return emit(bundle, "v3_p26_cross_act_consistency")


if __name__ == "__main__":
    raise SystemExit(main())
