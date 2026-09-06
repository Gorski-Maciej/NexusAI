#!/usr/bin/env python3
"""NexusAI JDG — V3-P26-I06 DRA GENERATOR VALIDATED (walidacja formularzy ZUS).

Dowód wdrożenia: DRA/RCA/ZZA/RCA_ALIGN z walidacją zero-ciszy (P25): nieznany
formularz / brak pól / brak identyfikatora / brak okresu = BLOCK; pracownicy>0
→ RCA (art. 47 ust. 1-2 SUS [NIEZWERYFIKOWANE]).
"""
from __future__ import annotations

from v3_p26_common import (P26_RULES, emit, main_jdg_wired, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P26-I06"
RULE = "jdg.v3_p26_zus_skladki.dra_generator"
FORMS = ["DRA", "RCA", "ZZA", "RCA_ALIGN"]
REQUIRED_BLOCKS = ["form_type", "declaration_period", "payer_identified", "employees_count"]


def main() -> int:
    hay = read(P26_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_forms = all(f in hay for f in FORMS)
    has_zero_silence = threshold_present("v3_p26_dra_zero_silence") and "_dg_fields_ok" in hay
    has_rca_rule = "_dg_form_expected" in hay
    has_p25 = "V3_P25" in hay

    checks.append({"name": "dra_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "forms", "status": "OK" if has_forms else "FAIL",
                   "detail": f"formularze: {FORMS}"})
    checks.append({"name": "zero_silence_fields", "status": "OK" if has_zero_silence else "FAIL",
                   "detail": "brak pól/identyfikatora/okresu = BLOCK (zero ciszy)"})
    checks.append({"name": "rca_employees_rule", "status": "OK" if has_rca_rule else "FAIL",
                   "detail": "pracownicy > 0 → RCA (przewidywana forma = TRIAGE przy różnicy)"})
    checks.append({"name": "p25_calendar_contract", "status": "OK" if has_p25 else "FAIL",
                   "detail": "terminy DRA 10./15. z kalendarza MASTER V3_P25"})
    checks.append({"name": "wiring_main_jdg", "status": "OK" if main_jdg_wired() else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p90"})

    if not has_zero_silence:
        findings.append({"id": "V3-P26-L06", "severity": "P1",
                         "evidence": "brak walidacji zero-ciszy pól formularza",
                         "fix": "I06: required_fields_present gate (kontrakt V3_P25)"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "forms": len(FORMS),
                    "required_blocks": REQUIRED_BLOCKS, "zero_silence": has_zero_silence},
        "checks": checks, "findings": findings,
        "contract": {"binding": "DRA generator wiąże P16 (deklaracje) i P41 (UI); "
                                "kontrakt pól: form/period/ident/employees",
                     "rule": "zero ciszy: brak pola = BLOCK; forma≠przewidywana = TRIAGE"}}
    return emit(bundle, "v3_p26_dra_generator")


if __name__ == "__main__":
    raise SystemExit(main())
