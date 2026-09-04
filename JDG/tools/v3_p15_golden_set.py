#!/usr/bin/env python3
"""NexusAI JDG — V3-P15-I08 CROSS-BORDER GOLDEN SET (Golden Oracle P10).

Golden set decyzji transgranicznych granicznych: D-1 kursy, 183 dni rezydencji,
progi TP 2M/10M — w oracle nienaruszalności przeszłości. Dowód: reguła
crossborder_golden_set + parametr golden_set_min_verdicts.
"""
from __future__ import annotations

from v3_p15_common import P15_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P15-I08"


def main() -> int:
    hay = read(P15_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p15_crossborder.crossborder_golden_set", hay)
    has_boundaries = all(b in hay for b in ("fx_d1", "residency_183", "tp_goods", "pos_b2b"))
    has_triage = "TRIAGE_QUEUE" in hay and "golden_set_coverage" in hay
    has_min = not thresholds_missing(["golden_set_min_verdicts"])

    checks.append({"name": "golden_set_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła crossborder_golden_set: {has_rule}"})
    checks.append({"name": "boundary_decisions", "status": "OK" if has_boundaries else "FAIL",
                   "detail": "pokrycie decyzjami granicznymi (D-1, 183 dni, TP, place of supply)"})
    checks.append({"name": "triage_incomplete", "status": "OK" if has_triage else "FAIL",
                   "detail": "niekompletny golden set → TRIAGE_QUEUE"})
    checks.append({"name": "min_verdicts_param", "status": "OK" if has_min else "FAIL",
                   "detail": "parametr golden_set_min_verdicts (ADR-002)"})

    if not has_boundaries:
        findings.append({"id": "V3-P15-L09", "severity": "P2",
                         "evidence": "golden set bez decyzji granicznych cross-border",
                         "fix": "I08: dodaj decyzje graniczne (D-1 kursy, 183 dni, progi TP) do oracle"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"golden_set_rule": has_rule, "boundaries": has_boundaries,
                    "triage": has_triage, "min_param": has_min},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P10 (Golden Oracle), P44",
                     "rule": "golden set cross-border pokrywa decyzje graniczne; replay na nowych wersjach reguł"}}
    return emit(bundle, "v3_p15_golden_set")


if __name__ == "__main__":
    raise SystemExit(main())