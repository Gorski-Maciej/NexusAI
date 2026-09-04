#!/usr/bin/env python3
"""NexusAI JDG — V3-P19-I12 ENVIRONMENTAL EXPLANATION PACK (dla księgowej).

Dowód wdrożenia: checklisty dokumentacyjne BDO/PCC/lokalne — znany typ
paczki + podstawa prawna + komplet checklisty = SUGGEST (PDF do wysyłki),
nieznany typ / brak podstawy / niekomplet = BLOCK (fail-closed, zero
niekompletnych paczek do księgowej).
"""
from __future__ import annotations

from v3_p19_common import P19_RULES, now, read, rule_present, threshold_present, main_jdg_wired, emit

INNOVATION = "V3-P19-I12"

RULE = "jdg.v3_p19_pcc_akcyza_bdo.explanation_pack"
TH_KEYS = ["v3_p19_bdo_report_due"]


def main() -> int:
    hay = read(P19_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_fields = all(f in hay for f in ('"pack_type"', '"legal_basis_present"',
                                        '"docs_checklist_complete"'))
    has_known_types = all(f in hay for f in ('"BDO"', '"PCC"', '"LOCAL"'))
    has_complete = "_ex12_complete" in hay
    has_fail_closed = "_ex12_unknown" in hay
    th_ok = threshold_present(TH_KEYS[0])
    wired = main_jdg_wired()

    checks.append({"name": "explanation_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "pack_contract", "status": "OK" if has_fields else "FAIL",
                   "detail": "kontrakt: typ paczki / podstawa / komplet checklisty"})
    checks.append({"name": "pack_types", "status": "OK" if has_known_types else "FAIL",
                   "detail": "typy paczek: BDO / PCC / lokalne"})
    checks.append({"name": "completeness", "status": "OK" if has_complete else "FAIL",
                   "detail": "komplet = SUGGEST (PDF do księgowej)"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail_closed else "FAIL",
                   "detail": "nieznany typ / niekomplet = BLOCK (fail-closed)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: terminy w paczkach z data.thresholds"})
    checks.append({"name": "main_jdg_wiring", "status": "OK" if wired else "FAIL",
                   "detail": "import + rejestr + final_verdict_p87"})

    if not has_fail_closed:
        findings.append({"id": "V3-P19-L12", "severity": "P0",
                         "evidence": "brak BLOCK przy niekompletnej paczce dokumentacyjnej",
                         "fix": "I12: checklisty BDO/PCC/lokalne — komplet = SUGGEST"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "types": has_known_types,
                    "complete": has_complete, "fail_closed": has_fail_closed,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "checklisty BDO (raport 15.03) / PCC / lokalne — kontrakt księgowej",
                     "rule": "paczki wyjaśnień — komplet = SUGGEST, niekomplet = BLOCK"}}
    return emit(bundle, "v3_p19_explanation_pack")


if __name__ == "__main__":
    raise SystemExit(main())
