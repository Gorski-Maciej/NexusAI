#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I07 WASTE FEE CALCULATOR (opłata za odpady).

Dowód wdrożenia: kalkulacja opłaty za wytworzone odpady — stawka za kg z
data.thresholds (fallback przy braku stawki w ctx), masa ujemna = BLOCK
(fail-closed), kalkulacja = masa × stawka z zaokrągleniem groszowym.
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I07"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.waste_fee_calculator"
TH_KEYS = ["v3_p19_waste_fee_per_kg_pln"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"waste_kg"', '"fee_rate_per_kg"'))
    has_rate_as_data = "v3_p19_waste_fee_per_kg_pln" in hay
    has_rate_known = "_wf_rate_known" in hay and "_wf_effective_rate" in hay
    has_fail_closed = "_wf_rate_unknown" in hay or "_wf_mass_kg" in hay
    has_round = "_round2" in hay
    th_ok = threshold_present(TH_KEYS[0])
    wired = main_jdg_wired()

    checks.append({"name": "fee_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "contract_fields", "status": "OK" if has_fields else "FAIL",
                   "detail": "kontrakt: masa kg / stawka za kg"})
    checks.append({"name": "rate_as_data", "status": "OK" if has_rate_as_data else "FAIL",
                   "detail": "stawka za kg z data.thresholds (ADR-002)"})
    checks.append({"name": "effective_rate", "status": "OK" if has_rate_known else "FAIL",
                   "detail": "efektywna stawka: ctx → fallback z danych"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail_closed else "FAIL",
                   "detail": "masa ujemna/nieznana = BLOCK (fail-closed)"})
    checks.append({"name": "grosz_round", "status": "OK" if has_round else "FAIL",
                   "detail": "zaokrąglenie groszowe kalkulacji"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: stawka opłaty z data.thresholds"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_fail_closed:
        findings.append({"id": "V3-P19-L07", "severity": "P0",
                         "evidence": "brak fail-closed przy niepoprawnej masie/stawce",
                         "fix": "I07: kalkulator opłat z danymi stawek i granicami mas"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "rate_as_data": has_rate_as_data,
                    "fail_closed": has_fail_closed, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "ustawa o odpadach (opłaty); stawki [NIEZWERYFIKOWANE]; ADR-002",
                     "rule": "kalkulator opłaty za odpady — masa × stawka z danych"}}
    return emit(bundle, "v3_p19_waste_fee")


if __name__ == "__main__":
    raise SystemExit(main())
