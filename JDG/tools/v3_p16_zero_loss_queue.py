#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I02 ZERO-LOSS OFFLINE QUEUE (RPO=0, art. 106na VAT).

Dowód wdrożenia: reguła zero_loss_offline_queue + parametry RPO=0/WAL/okno
offline 168h; fail-closed przy ryzyku utraty (RPO>0).
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, THRESHOLDS, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P16-I02"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.zero_loss_offline_queue", hay)
    has_wal = "wal_required" in hay and "wal_enabled" in hay
    has_rpo = '"rpo_hours"' in hay and "offline_window_hours" in hay
    has_loss = "loss_risk" in hay
    missing = thresholds_missing(["v3_p16_wal_required", "v3_p16_offline_rpo_hours",
                                  "v3_p16_offline_rto_hours", "v3_p16_offline_window_hours"])

    checks.append({"name": "queue_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła zero_loss_offline_queue: {has_rule}"})
    checks.append({"name": "wal", "status": "OK" if has_wal else "FAIL",
                   "detail": "Write-Ahead Log wymagany (RPO=0)"})
    checks.append({"name": "rpo_rto", "status": "OK" if has_rpo else "FAIL",
                   "detail": "parametry RPO/RTO jako dane"})
    checks.append({"name": "fail_closed_loss", "status": "OK" if has_loss else "FAIL",
                   "detail": "ryzyko utraty → BLOCK_AND_ALERT (fail-closed)"})
    checks.append({"name": "params_adr002", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów: {missing or 'BRAK'}"})

    if not has_wal:
        findings.append({"id": "V3-P16-L02", "severity": "P1",
                         "evidence": "offline queue bez WAL → RPO>0",
                         "fix": "I02: WAL + identyfikatory zdarzeń (retry-proof)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "wal": has_wal, "rpo_rto": has_rpo,
                    "loss_risk": has_loss, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P43 (DR/BCP), V1 resilience (RPO=0), ADR-002",
                     "rule": "kolejka offline zero utraty (WAL, klucze idempotencji)"}}
    return emit(bundle, "v3_p16_zero_loss_queue")


if __name__ == "__main__":
    raise SystemExit(main())
