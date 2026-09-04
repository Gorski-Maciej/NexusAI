#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I03 UPO SENTINEL (timeout→alarm→retry→eskalacja).

Dowód wdrożenia: reguła upo_sentinel + parametry timeout 24h / eskalacja 48h;
invariant zero-ciszy (faktura ≠ wysłana bez UPO) z kontraktu V3_P04.
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P16-I03"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.upo_sentinel", hay)
    has_timeout = "timeout_reached" in hay and "oldest_waiting_hours" in hay
    has_escalation = "escalation_reached" in hay
    has_zero_silence = "missing_upo" in hay and "oldest_waiting_hours" in hay
    missing = thresholds_missing(["v3_p16_upo_timeout_hours", "v3_p16_upo_escalation_hours"])

    checks.append({"name": "upo_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła upo_sentinel: {has_rule}"})
    checks.append({"name": "timeout_alarm", "status": "OK" if has_timeout else "FAIL",
                   "detail": "timeout → alarm (24h)"})
    checks.append({"name": "escalation", "status": "OK" if has_escalation else "FAIL",
                   "detail": "eskalacja (48h) → BLOCK_AND_ALERT"})
    checks.append({"name": "zero_silence", "status": "OK" if has_zero_silence else "FAIL",
                   "detail": "zero ciszy (P04 invariant)"})
    checks.append({"name": "params_adr002", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów: {missing or 'BRAK'}"})

    if not has_escalation:
        findings.append({"id": "V3-P16-L03", "severity": "P1",
                         "evidence": "UPO sentinel bez eskalacji",
                         "fix": "I03: timeout→alarm→retry→eskalacja (zero ciszy)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "timeout": has_timeout, "escalation": has_escalation,
                    "zero_silence": has_zero_silence, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "V3_P04 (zero ciszy), P11 (UPO jako dowód), P37 (observability)",
                     "rule": "monitor UPO: timeout→alarm→retry→eskalacja"}}
    return emit(bundle, "v3_p16_upo_sentinel")


if __name__ == "__main__":
    raise SystemExit(main())
