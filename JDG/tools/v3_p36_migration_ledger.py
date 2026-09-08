#!/usr/bin/env python3
"""NexusAI JDG — V3-P36-I04 MIGRATION LEDGER — globalny dziennik migracji
(które narzędzie, kiedy, jakie pliki) z checksumami — pełna odtwarzalność
historii — V3 FORTRESS.

Dowód wdrożenia: wpis bez checksumy = BLOCK; migracja bez wpisu = BLOCK
(które narzędzie, kiedy, jakie pliki); spójny z WORM (P43) i UoR art. 74-75
(archiwum, [NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano). AN02.
"""
from __future__ import annotations

from v3_p36_common import (P36_RULES, emit, main_jdg_wired, now, read,
                           rule_present)

INNOVATION = "V3-P36-I04"
RULE = "jdg.v3_p36_generatory_migratory.migration_ledger"


def main() -> int:
    hay = read(P36_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    checksum_block = "bez checksumy" in hay and "BLOCK" in hay
    checks.append({"name": "checksum_required", "status": "OK" if checksum_block else "FAIL",
                   "detail": "wpis bez checksumy = BLOCK (odtwarzalność historii): " + str(checksum_block)})

    missing_block = "Migracje bez wpisu w dzienniku" in hay
    checks.append({"name": "no_migration_without_entry", "status": "OK" if missing_block else "FAIL",
                   "detail": "migracja bez wpisu = BLOCK: " + str(missing_block)})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p100"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "checksum_required": checksum_block,
            "no_migration_without_entry": missing_block,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p36_migration_ledger")


if __name__ == "__main__":
    raise SystemExit(main())
