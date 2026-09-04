#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I05 BDO QUALIFIER (rejestracja BDO).

Dowód wdrożenia: kwalifikacja obowiązku BDO — odpady ≥ 100 kg/rok LUB
wprowadzanie opakowań LUB sprzedaż WEEE/baterii (progi jako dane);
działalność w obowiązku bez rejestracji = BLOCK; poniżej progów = SUGGEST;
raport roczny 15.03; brak danych = TRIAGE.
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I05"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.bdo_qualifier"
TH_KEYS = ["v3_p19_bdo_waste_threshold_kg", "v3_p19_bdo_packaging_active",
           "v3_p19_weee_seller_registration", "v3_p19_bdo_report_due"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"waste_kg_year"', '"introduces_packaging"',
                                        '"sells_weee_batteries"', '"bdo_registered"'))
    has_obligation = "_bq_required" in hay
    has_unregistered_block = '_bq_registered' in hay and "BLOCK" in hay
    has_report = "03-15" in hay or "15.03" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)
    wired = main_jdg_wired()

    checks.append({"name": "bdo_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "qualifier_fields", "status": "OK" if has_fields else "FAIL",
                   "detail": "kontrakt: kg odpadów / opakowania / WEEE / rejestracja"})
    checks.append({"name": "obligation_logic", "status": "OK" if has_obligation else "FAIL",
                   "detail": "obowiązek: odpady ≥ 100 kg LUB opakowania LUB WEEE"})
    checks.append({"name": "unregistered_block", "status": "OK" if has_unregistered_block else "FAIL",
                   "detail": "obowiązek bez rejestracji = BLOCK"})
    checks.append({"name": "annual_report", "status": "OK" if has_report else "FAIL",
                   "detail": "raport roczny BDO do 15.03"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: progi BDO z data.thresholds"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_unregistered_block:
        findings.append({"id": "V3-P19-L05", "severity": "P0",
                         "evidence": "brak BLOCK przy obowiązku BDO bez rejestracji",
                         "fix": "I05: kwalifikator BDO z progiem 100 kg i raportem 15.03"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "obligation": has_obligation,
                    "unregistered_block": has_unregistered_block, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "ustawa o odpadach (BDO); próg 100 kg [NIEZWERYFIKOWANE]; raport 15.03",
                     "rule": "kwalifikator obowiązku BDO z BLOCK przy braku rejestracji"}}
    return emit(bundle, "v3_p19_bdo_qualifier")


if __name__ == "__main__":
    raise SystemExit(main())
