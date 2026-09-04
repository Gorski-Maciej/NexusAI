#!/usr/bin/env python3
"""NexusAI JDG — V3-P17-I08 PROCEEDING TIMELINE (sprawy z terminami).

Dowód wdrożenia: timeline sprawy — czynności sprawdzające → postępowanie →
odwołanie → WSA → audyt; każdy etap mapowany na następną czynność i termin;
ZERO CISZY (brak zdarzenia > progu = BLOCK + eskalacja); nieznany etap =
fail-closed BLOCK.
"""
from __future__ import annotations

from v3_p17_common import P17_RULES, now, read, rule_present, emit

INNOVATION = "V3-P17-I08"

RULE = "jdg.v3_p17_ordynacja_obrona.proceeding_timeline"


def main() -> int:
    hay = read(P17_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_stages = '"CZYNNOSCI_SPRAWDZAJACE"' in hay and '"ODWOLANIE"' in hay and '"SKARGA_WSA"' in hay and '"AUDYT"' in hay
    has_next = '"_tl_next_action"' in hay or "next_action" in hay
    has_zero_silence = "_tl_silence" in hay and "eskalacja" in hay.lower()
    has_fail = "_tl_unknown" in hay and "fail_closed" in hay

    checks.append({"name": "timeline_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "stages", "status": "OK" if has_stages else "FAIL",
                   "detail": "etapy: czynności/postępowanie/odwołanie/WSA/audyt"})
    checks.append({"name": "next_action", "status": "OK" if has_next else "FAIL",
                   "detail": "mapowanie etap → następna czynność + termin"})
    checks.append({"name": "zero_silence", "status": "OK" if has_zero_silence else "FAIL",
                   "detail": "cisza > progu = BLOCK + eskalacja"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail else "FAIL",
                   "detail": "nieznany etap = BLOCK (fail-closed)"})

    if not has_zero_silence:
        findings.append({"id": "V3-P17-L08", "severity": "P0",
                         "evidence": "timeline spraw bez reguły zero-ciszy",
                         "fix": "I08: cisza = alarm + eskalacja"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "stages": has_stages, "next": has_next,
                    "zero_silence": has_zero_silence, "fail_closed": has_fail},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 187-234 OrdPU; art. 223; art. 53 PPSA; kontrakt V3_P36",
                     "rule": "timeline spraw z zero ciszy i dowodami"}}
    return emit(bundle, "v3_p17_proceeding_timeline")


if __name__ == "__main__":
    raise SystemExit(main())
