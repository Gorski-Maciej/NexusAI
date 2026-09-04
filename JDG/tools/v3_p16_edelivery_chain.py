#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I10 E-DELIVERY CHAIN (wysyłka→status→UPO→archiwum).

Dowód wdrożenia: reguła edelivery_chain + parametry timeout statusu 24h;
łańcuch e-Doręczeń z zero ciszy (każde ogniwo monitorowane) — e-Doręczenia
obowiązkowe od 2026-01-01 (edelivery_mandatory_from).
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, now, read, rule_present, thresholds_missing, emit

INNOVATION = "V3-P16-I10"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.edelivery_chain", hay)
    has_chain = "missing_status" in hay and "missing_upo" in hay and "missing_archive" in hay
    has_broken = "chain_broken" in hay
    has_timeout = "status_timeout_hours" in hay
    missing = thresholds_missing(["v3_p16_edelivery_status_timeout_hours", "edelivery_mandatory_from"])

    checks.append({"name": "edelivery_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła edelivery_chain: {has_rule}"})
    checks.append({"name": "chain_stages", "status": "OK" if has_chain else "FAIL",
                   "detail": "status → UPO → archiwum (każde ogniwo)"})
    checks.append({"name": "zero_silence", "status": "OK" if has_broken else "FAIL",
                   "detail": "przerwany łańcuch → BLOCK_AND_ALERT (zero ciszy)"})
    checks.append({"name": "timeout", "status": "OK" if has_timeout else "FAIL",
                   "detail": "timeout statusu 24h"})
    checks.append({"name": "params_adr002", "status": "OK" if not missing else "FAIL",
                   "detail": f"brak parametrów: {missing or 'BRAK'}"})

    if not has_chain:
        findings.append({"id": "V3-P16-L10", "severity": "P1",
                         "evidence": "łańcuch e-Doręczeń bez pełnych ogniw",
                         "fix": "I10: wysyłka → status → UPO → archiwum (zero ciszy)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "chain": has_chain, "broken": has_broken,
                    "timeout": has_timeout, "missing_params": missing},
        "checks": checks, "findings": findings,
        "contract": {"binding": "ustawa o doręczeniach elektronicznych (2026-01-01), P11 (UPO)",
                     "rule": "e-Doręczenia: pełny łańcuch z zero ciszy"}}
    return emit(bundle, "v3_p16_edelivery_chain")


if __name__ == "__main__":
    raise SystemExit(main())
