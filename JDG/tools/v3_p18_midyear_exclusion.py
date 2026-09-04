#!/usr/bin/env python3
"""NexusAI JDG — V3-P18-I03 MID-YEAR EXCLUSION HANDLER.

Dowód wdrożenia: wykluczenie powstające W TRAKCIE roku — tryb utraty prawa z
danych (v3_p18_exclusion_effective_mode), miesiące objęte, ścieżka zmiany
formy (termin z danych) i korekty ewidencji; retrospekcja = BLOCK.
"""
from __future__ import annotations

from v3_p18_common import P18_RULES, now, read, rule_present, threshold_present, emit

INNOVATION = "V3-P18-I03"

RULE = "jdg.v3_p18_ryczalt.midyear_exclusion_handler"
TH_KEYS = ["v3_p18_exclusion_effective_mode", "v3_p18_midyear_change_deadline_days"]


def main() -> int:
    hay = read(P18_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    has_path = '"months_affected"' in hay and '"exclusion_from"' in hay and "effective_mode" in hay
    has_retro = "_mh_retro" in hay and "retro_to_year_start" in hay
    has_fail = "_mh_unknown" in hay and "fail_closed" in hay
    th_ok = all(threshold_present(k) for k in TH_KEYS)

    checks.append({"name": "midyear_rule", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})
    checks.append({"name": "path", "status": "OK" if has_path else "FAIL",
                   "detail": "ścieżka: data wykluczenia → miesiące → zmiana formy/korekty"})
    checks.append({"name": "retro_block", "status": "OK" if has_retro else "FAIL",
                   "detail": "retrospekcja do początku roku = BLOCK (korekty I06)"})
    checks.append({"name": "fail_closed", "status": "OK" if has_fail else "FAIL",
                   "detail": "brak daty/miesięcy = BLOCK (fail-closed)"})
    checks.append({"name": "thresholds_as_data", "status": "OK" if th_ok else "FAIL",
                   "detail": "ADR-002: tryb utraty i termin z data.thresholds.lump_sum"})

    if not has_path:
        findings.append({"id": "V3-P18-L03", "severity": "P1",
                         "evidence": "brak ścieżki zmiany formy przy wykluczeniu w trakcie roku",
                         "fix": "I03: miesiące objęte + korekta ewidencji + zmiana formy"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {"rule": has_rule, "path": has_path, "retro": has_retro,
                    "fail_closed": has_fail, "thresholds": th_ok},
        "checks": checks, "findings": findings,
        "contract": {"binding": "art. 8 ust. 2 ustawy o zryczałtowanym PIT [NIEZWERYFIKOWANE — Q01]; "
                                "korekty V3_P04",
                     "rule": "handler wykluczenia mid-year ze ścieżką zmiany formy"}}
    return emit(bundle, "v3_p18_midyear_exclusion")


if __name__ == "__main__":
    raise SystemExit(main())
