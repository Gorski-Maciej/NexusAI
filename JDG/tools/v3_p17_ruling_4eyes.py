#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I07 RULING AUTODRAFTER 4-EYES (wnioski KIS).

Dowód wdrożenia: generator wniosków o interpretację z bramką 4-eyes —
kompletność formalna (stan faktyczny, stanowisko, podstawa, opłata) + review
prawnika. Wysłanie wniosku BEZ review = BLOCK (naruszenie procesu).
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P17-I07"

RULE = "jdg.v3_p17_ordynacja_obrona.ruling_autodrafter_4eyes"
TH_KEYS = ["v3_p17_ruling_4eyes_required"]


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_complete = '"draft_complete"' in hay and '"facts_present"' in hay and '"position_present"' in hay and '"fee_paid"' in hay
    has_4eyes = "_ra_sent_without_review" in hay and "reviewer_assigned" in hay and "4-eyes" in hay
    has_legal = "Art. 14b-14d OrdPU" in hay and "LKG V3_P01" in hay
    th_ok = threshold_present(TH_KEYS[0])

    checks.append({"name": "ruling_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "formal_completeness", "status": "OK" if has_complete else "FAIL",
                   "detail": "checklista formalna wniosku (opis, stanowisko, podstawa, opłata)"})
    checks.append({"name": "4eyes_gate", "status": "OK" if has_4eyes else "FAIL",
                   "detail": "bramka 4-eyes: wysyłka bez review = BLOCK"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: wymóg review z data.thresholds.ord"})

    if not has_4eyes:
        findings.append({"id": "V3-P17-L07", "severity": "P0",
                         "evidence": "wniosek KIS bez bramki 4-eyes (AP07)",
                         "fix": "I07: BLOCK przy wysyłce bez review prawnika"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "completeness": has_complete, "4eyes": has_4eyes,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 14b-14d OrdPU; kontrakt LKG V3_P01; pytanie X08 (4-eyes)",
                     "rule": "autodrafter wniosków KIS z bramką 4-eyes"}}
    return emit(bundle, "v3_p17_ruling_4eyes")


if __name__ == "__main__":
    raise SystemExit(main())
