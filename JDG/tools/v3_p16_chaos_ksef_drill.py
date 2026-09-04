#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I09 CHAOS KSeF DRILL (KSeF down 72h → zero utraty).

Dowód wdrożenia: reguła chaos_ksef_drill + parametry drill 72h / RPO=0 / RTO;
awaria ≥72h bez drillu = NEEDS_ADVICE; utrata faktur / RPO>0 = BLOCK_AND_ALERT.
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P16-I09"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.chaos_ksef_drill", hay)
    has_72h = "drill_required_hours" in hay and "ksef_outage_hours" in hay
    has_rpo = '"measured_rpo_hours"' in hay and "rpo_violated" in hay
    has_loss = "lost_invoices" in hay and "loss_detected" in hay
    has_drill = "drill_completed" in hay and "drill_overdue" in hay
    missing = thresholds_missing(["v3_p16_chaos_drill_hours", "v3_p16_offline_rpo_hours"])

    checks.append({"name": "chaos_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła chaos_ksef_drill: {has_rule}"})
    checks.append({"name": "drill_72h", "status": "OK" if has_72h else "FAIL",
                   "detail": "scenariusz KSeF down 72h"})
    checks.append({"name": "rpo_rto_measure", "status": "OK" if has_rpo else "FAIL",
                   "detail": "pomiar RPO/RTO (zero utraty)"})
    checks.append({"name": "loss_block", "status": "OK" if has_loss else "FAIL",
                   "detail": "utrata faktur → BLOCK_AND_ALERT"})
    checks.append({"name": "drill_gate", "status": "OK" if has_drill else "FAIL",
                   "detail": "awaria bez drillu → NEEDS_ADVICE"})
    checks.append({"name": "params_adr002", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów: {missing or 'BRAK'}"})

    if not has_rpo:
        findings.append({"id": "V3-P16-L09", "severity": "P1",
                         "evidence": "chaos drill bez pomiaru RPO/RTO",
                         "fix": "I09: tabletop KSeF down 72h z pomiarem RPO/RTO"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "drill_72h": has_72h, "rpo_rto": has_rpo,
                    "loss": has_loss, "drill_gate": has_drill, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P43 (DR/BCP), V1 resilience (RPO/RTO), P16-AN12",
                     "rule": "chaos drill: KSeF down 72h → zero utraty (RPO/RTO)"}}
    return emit(bundle, "v3_p16_chaos_ksef_drill")


if __name__ == "__main__":
    raise SystemExit(main())
