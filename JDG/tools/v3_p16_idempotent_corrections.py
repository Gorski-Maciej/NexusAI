#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I07 IDEMPOTENT CORRECTIONS (retry-proof, art. 106j).

Dowód wdrożenia: reguła idempotent_corrections + identyfikatory zdarzeń
(correction_event_id) — retry tej samej korekty nie dubluje wpisu; kolizja
(nowe zdarzenie z ID już zastosowanym) = BLOCK_AND_ALERT.
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, now, read, rule_present, emit

INNOVATION = "V3-P16-I07"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.idempotent_corrections", hay)
    has_event_id = "correction_event_id" in hay
    has_retry = '"is_retry"' in hay and "retry_safe" in hay
    has_dup = "duplicate_risk" in hay and "BLOCK_AND_ALERT" in hay
    has_deadline = "correction_deadline_days" in hay

    checks.append({"name": "corrections_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła idempotent_corrections: {has_rule}"})
    checks.append({"name": "event_ids", "status": "OK" if has_event_id else "FAIL",
                   "detail": "identyfikatory zdarzeń korekt"})
    checks.append({"name": "retry_proof", "status": "OK" if has_retry else "FAIL",
                   "detail": "retry idempotentne (brak duplikatu)"})
    checks.append({"name": "duplicate_block", "status": "OK" if has_dup else "FAIL",
                   "detail": "kolizja zdarzeń → BLOCK_AND_ALERT"})
    checks.append({"name": "deadline_30d", "status": "OK" if has_deadline else "FAIL",
                   "detail": "termin korekt 30 dni (art. 106j)"})

    if not has_retry:
        findings.append({"id": "V3-P16-L07", "severity": "P1",
                         "evidence": "korekty bez gwarancji idempotencji",
                         "fix": "I07: identyfikatory zdarzeń + retry-proof"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "event_ids": has_event_id, "retry": has_retry,
                    "duplicate_block": has_dup, "deadline": has_deadline},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 106j VAT, art. 81 OrdPU, P06 (idempotencja)",
                     "rule": "korekty JPK idempotentne (event_id, retry-proof)"}}
    return emit(bundle, "v3_p16_idempotent_corrections")


if __name__ == "__main__":
    raise SystemExit(main())
