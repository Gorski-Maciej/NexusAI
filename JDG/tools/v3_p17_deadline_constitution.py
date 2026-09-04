#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I04 PROCEDURAL DEADLINE CONSTITUTION (7/14/30 dni).

Dowód wdrożenia: konstytucja terminów proceduralnych jako dane — stanowisko
7 dni (art. 282b), odwołanie 14 dni (art. 223), skarga do WSA 30 dni (art. 53
PPSA). ZERO CISZY: brak reakcji do terminu = BLOCK_AND_ALERT + eskalacja (48h).
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P17-I04"

RULE = "jdg.v3_p17_ordynacja_obrona.procedural_deadline_constitution"
TH_KEYS = ["v3_p17_deadline_statement_days", "v3_p17_appeal_days",
           "v3_p17_wsa_days", "v3_p17_zero_silence_escalation_days"]


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_days = '"STANOWISKO_7"' in hay and '"ODWOLANIE_14"' in hay and '"SKARGA_WSA_30"' in hay
    has_zero_silence = "ZERO CISZY" in hay and '"breached"' in hay and "eskalacja" in hay.lower()
    has_urgent = '"urgent"' in hay.lower() or "_dc_urgent" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "deadline_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "deadline_types", "status": "OK" if has_days else "FAIL",
                   "detail": "terminy 7 (art. 282b) / 14 (art. 223) / 30 (art. 53 PPSA)"})
    checks.append({"name": "zero_silence", "status": "OK" if has_zero_silence else "FAIL",
                   "detail": "brak reakcji = BLOCK_AND_ALERT + eskalacja 48h"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: terminy i eskalacja z data.thresholds.ord"})

    if not has_zero_silence:
        findings.append({"id": "V3-P17-L04", "severity": "P0",
                         "evidence": "kalendarz proceduralny bez reguły zero-ciszy",
                         "fix": "I04: brak reakcji = alarm + eskalacja (fail-closed)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "types": has_days, "zero_silence": has_zero_silence,
                    "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 223/282b OrdPU; art. 53 PPSA; kontrakt V3_P36 "
                                "(jeden kalendarz proceduralny); V3_P41 (UI spraw)",
                     "rule": "konstytucja terminów 7/14/30 z zero ciszy"}}
    return emit(bundle, "v3_p17_deadline_constitution")


if __name__ == "__main__":
    raise SystemExit(main())
