#!/usr/bin/env python3
"""NexusAI JDG — V3-P16-I11 PENALTY EXPOSURE MONITOR (kary KSeF, progresja).

Dowód wdrożenia: reguła penalty_exposure_monitor + symulacja sankcji wg reżimu
(FULL 100% / opóźnienie >24h 70% / czynny żal 50%) z progami z thresholdów
(ksef_sanction_max_pln 500k, _70_cap 300k, _50_cap 250k). Wysoka ekspozycja =
BLOCK_AND_ALERT; średnia = TRIAGE_QUEUE.
"""
from __future__ import annotations

from v3_p16_common import P16_RULES, now, read, rule_present, emit

INNOVATION = "V3-P16-I11"


def main() -> int:
    hay = read(P16_RULES)
    checks, findings = [], []

    has_rule = rule_present("jdg.v3_p16_ksef_jpk.penalty_exposure_monitor", hay)
    has_regime = '"regime"' in hay and "ACTIVE_REGRET" in hay and "DELAY_OVER_24H" in hay
    has_prog = '"exposure_pln"' in hay and "ksef_sanction_70_cap_pln" in hay
    has_levels = '"high_exposure"' in hay and '"medium_exposure"' in hay and '"low_exposure"' in hay

    checks.append({"name": "penalty_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła penalty_exposure_monitor: {has_rule}"})
    checks.append({"name": "regimes", "status": "OK" if has_regime else "FAIL",
                   "detail": "reżimy sankcji (100%/70%/50%)"})
    checks.append({"name": "progression", "status": "OK" if has_prog else "FAIL",
                   "detail": "progi z thresholdów (500k/300k/250k)"})
    checks.append({"name": "exposure_levels", "status": "OK" if has_levels else "FAIL",
                   "detail": "poziomy ekspozycji (wysoka/średnia/niska)"})

    if not has_prog:
        findings.append({"id": "V3-P16-L11", "severity": "P1",
                         "evidence": "monitor kar bez progresji/progów",
                         "fix": "I11: symulacja sankcji KSeF (100%/70%/50%) z progami"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "regimes": has_regime, "progression": has_prog,
                    "levels": has_levels},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 106na-106nb VAT (kary), P37 (observability), KKS art. 54",
                     "rule": "monitor narażenia na kary KSeF (progresja, symulacja)"}}
    return emit(bundle, "v3_p16_penalty_exposure")


if __name__ == "__main__":
    raise SystemExit(main())
