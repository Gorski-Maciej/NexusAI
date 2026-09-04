#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I06 MDR HALLMARK SCORER (art. 86a OrdPU / DAC6).

Scoring hallmarks A-E (0-100) z human review WYMUSZONYM i terminem 30 dni.
Nigdy cichy AUTO_POST. Dowód: reguła mdr_hallmark_scorer + parametry
mdr_* w thresholds.
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I06"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.mdr_hallmark_scorer", hay)
    has_human_review = "human_review_required" in hay and "deadline" in hay
    missing = thresholds_missing(["mdr_human_review_required", "mdr_deadline_days"])

    checks.append({"name": "mdr_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła mdr_hallmark_scorer: {has_rule}"})
    checks.append({"name": "human_review_forced", "status": "OK" if has_human_review else "FAIL",
                   "detail": "human review wymuszony + termin 30 dni od zdarzenia"})
    checks.append({"name": "params_as_data", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów mdr_*: {missing or 'BRAK'}"})

    if not has_human_review:
        findings.append({"id": "V3-P15-L07", "severity": "P1",
                         "evidence": "MDR scoring bez wymuszonego human review = ryzyko cichego raportu",
                         "fix": "I06: human review WYMUSZONY; termin 30 dni w kalendarzu"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"mdr_rule": has_rule, "human_review": has_human_review,
                    "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P36 (kalendarz), P44",
                     "rule": "scoring MDR ≥70 = TRIAGE_QUEUE + human review; termin 30 dni; zero AUTO_POST"}}
    return emit(bundle, "v3_p15_mdr_hallmark_scorer")


if __name__ == "__main__":
    raise SystemExit(main())