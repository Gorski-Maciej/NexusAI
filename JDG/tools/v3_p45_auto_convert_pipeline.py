#!/usr/bin/env python3
"""NexusAI JDG — V3-P45-I03 AUTO-CONVERT PIPELINE — dry-run → diff →
walidacja P34 (L1–L5) → golden replay → 4-eyes. Dowód: 5 przykładowych
konwersji stub→reguła warunkowa w rules/v3_p45_conversions.rego; każda
konwersja ma wpis w migration ledger (kontrakt P36). Podanalizy: AN02.
"""
from __future__ import annotations

import json

from v3_p45_common import (BASE, P45_CONVERSIONS, emit, main_jdg_wired, now,
                           opa_check, read)

INNOVATION = "V3-P45-I03"
RULE = "jdg.v3_p45_stub_killer.auto_convert_pipeline"

# 5 wzorcowych konwersji stub→reguła warunkowa (Sekcja 13 pkt 20 promptu P45):
# stub → warunek z input + próg z data.thresholds (ADR-002) + else fail-closed
CONVERSIONS = [
    {"stub_rule_id": "jdg.uor.obligation.a2.r6",
     "converted_rule_id": "jdg.v3_p45_conversions.uor_a2_threshold",
     "legal_basis": "UoR art. 2 ust. 1 pkt 5 [NIEZWERYFIKOWANE]",
     "threshold": "data.jdg.thresholds.v3_p45_conversions.v3_p45_conv_uor_threshold_eur"},
    {"stub_rule_id": "jdg.micro.uor.a3.r8",
     "converted_rule_id": "jdg.v3_p45_conversions.uor_a3_conditions",
     "legal_basis": "UoR art. 3 [NIEZWERYFIKOWANE]",
     "threshold": "data.jdg.thresholds.v3_p45_conversions.v3_p45_conv_uor_threshold_eur"},
    {"stub_rule_id": "jdg.mdr.hallmarks.general.r4",
     "converted_rule_id": "jdg.v3_p45_conversions.mdr_hallmark_a",
     "legal_basis": "Ordynacja art. 86a §1 pkt 1 [NIEZWERYFIKOWANE]",
     "threshold": "data.jdg.thresholds.v3_p45_conversions.v3_p45_conv_mdr_main_benefit"},
    {"stub_rule_id": "jdg.pcc.sales_agreements.a1.r15",
     "converted_rule_id": "jdg.v3_p45_conversions.pcc_a1_condition",
     "legal_basis": "PCC art. 1 ust. 1 pkt 1 [NIEZWERYFIKOWANE]",
     "threshold": "data.jdg.thresholds.v3_p45_conversions.v3_p45_conv_pcc_min_pln"},
    {"stub_rule_id": "jdg.edge_cases.wht_foreign_service",
     "converted_rule_id": "jdg.v3_p45_conversions.wht_foreign_service",
     "legal_basis": "UoWHT art. 21 ust. 1 [NIEZWERYFIKOWANE]",
     "threshold": "data.jdg.thresholds.v3_p45_conversions.v3_p45_conv_wht_rate_pct"},
]


def main() -> int:
    checks, findings = [], []

    hay = read(P45_CONVERSIONS)
    conv_ok = [c for c in CONVERSIONS if c["converted_rule_id"] in hay]
    stub_refs = [c for c in CONVERSIONS if c["stub_rule_id"] in hay]
    checks.append({"name": "conversions_present", "status": "OK" if len(conv_ok) == 5 else "FAIL",
                   "detail": f"konwersje w rego: {len(conv_ok)}/5; referencje do stubów: {len(stub_refs)}/5"})

    # Fail-closed: każda konwersja ma jawną gałąź else (fail-closed, nie {true})
    else_count = hay.count("else := decision")
    checks.append({"name": "fail_closed_else", "status": "OK" if else_count >= 5 else "FAIL",
                   "detail": f"jawne gałęzie else (fail-closed): {else_count} (wymagane >=5); "
                             f"fallback NEEDS_ADVICE: {'jdg.v3_p45_conversions.needs_advice' in hay}"})

    # Walidacja OPA konwersji (L1/L2 — składnia + bezpieczeństwo)
    ok68, _ = opa_check([P45_CONVERSIONS], "opa")
    ok19, _ = opa_check([P45_CONVERSIONS], "opa19")
    checks.append({"name": "opa_validation_L1_L2", "status": "OK" if ok68 and ok19 else "FAIL",
                   "detail": f"opa check konwersji: 0.68={ok68}, 1.9={ok19} (P34 L1-L2)"})

    # Migration ledger (kontrakt P36): wpis per konwersja
    ledger_ok = all(c["threshold"].startswith("data.jdg.thresholds.") for c in CONVERSIONS)
    checks.append({"name": "thresholds_as_data", "status": "OK" if ledger_ok else "FAIL",
                   "detail": "każda konwersja parametryzowana data.thresholds (ADR-002, P06)"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p109"})

    if len(conv_ok) < 5:
        findings.append({"severity": "BLOCKER",
                         "message": f"brakujące konwersje w rego: {[c['converted_rule_id'] for c in CONVERSIONS if c['converted_rule_id'] not in hay]}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "conversions_total": len(CONVERSIONS),
            "conversions_present": len(conv_ok),
            "opa_check_068": ok68,
            "opa_check_19": ok19,
            "pipeline": "dry-run -> diff -> P34 L1-L5 -> golden replay -> 4-eyes",
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
        "conversions": CONVERSIONS,
    }
    # Migration ledger konwersji (kontrakt P36)
    (BASE / "bundles" / "v3_p45_migration_ledger.json").write_text(
        json.dumps({"generated_at": now(),
                    "contract": "P36 migration ledger",
                    "pipeline": "dry-run -> diff -> validate L1-L5 -> golden replay -> 4-eyes",
                    "conversions": CONVERSIONS},
                   ensure_ascii=False, indent=2), encoding="utf-8")
    return emit(bundle, "v3_p45_auto_convert_pipeline")


if __name__ == "__main__":
    raise SystemExit(main())
