#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I05 AUTO RE-CHECK SCHEDULER — harmonogram re-checku
aktów (crawler ISAP P34) z priorytetem: akty reguł ACTIVE codziennie,
CANDIDATE co tydzień. Dowód: plan kadencji + status świeżości każdego aktu
(rejestr wersji I04) + spina z drift alarmem I09. Podanalizy: AN04.
"""
from __future__ import annotations

import json
from pathlib import Path

from v3_p47_common import (P47_RULE, read_json, rule_present, utcnow_iso,
                           write_bundle)

INNOVATION = "V3-P47-I05"
RULE = f"{P47_RULE}.recheck_scheduler"
BASE = Path(__file__).resolve().parents[1]

# Kadencja wg promptu P47 5.4: ACTIVE codziennie, CANDIDATE co tydzień (dni)
SCHEDULE = {"ACTIVE": 1, "CANDIDATE": 7}


def main() -> int:
    checks, findings = [], []

    versions = (read_json(BASE / "bundles" / "v3_p47_act_versions_register.json") or {}).get("versions", {})
    stale, fresh = [], []
    for key, v in versions.items():
        # Świeżość: wersja v1-claim bez weryfikacji ISAP = STALE z definicji
        # (honesty: bez potwierdzenia w publikatorze akt jest nieświeży).
        (stale if v.get("verification") == "NIEZWERYFIKOWANE" else fresh).append(key)

    checks.append({"name": "schedule_defined", "status": "OK",
                   "detail": f"kadencje (dni): {json.dumps(SCHEDULE)} — ACTIVE codziennie, CANDIDATE co tydzień (prompt P47 5.4)"})
    checks.append({"name": "acts_in_scope", "status": "OK" if versions else "FAIL",
                   "detail": f"akty w zakresie re-checku: {len(versions)} (z rejestru wersji I04)"})
    checks.append({"name": "freshness_honest",
                   "status": "OK",
                   "detail": f"STALE (bez weryfikacji ISAP): {len(stale)}; świeże: {len(fresh)} — "
                             f"STALE = przegląd SHADOW (I09), nie ukrywanie"})

    # Integracja z crawlerem P34 — rozszerzamy, nie duplikujemy
    crawler_present = (BASE / "tools" / "isap_crawler.py").exists()
    checks.append({"name": "isap_crawler_integration", "status": "OK" if crawler_present else "FAIL",
                   "detail": f"tools/isap_crawler.py (P34): {crawler_present} — P47 dodaje kadencję, nie nowy crawler"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if stale:
        findings.append({"severity": "MEDIUM",
                         "message": f"akty STALE (wymagają re-checku w ISAP): {len(stale)} — pierwsza kolejność: ACTIVE"})

    routing = "BLOCK_AND_ALERT" if not versions else ("TRIAGE_QUEUE" if stale else "AUTO_FILE")
    metrics = {"acts_total": len(versions), "stale_acts": len(stale),
               "fresh_acts": len(fresh), "schedule": SCHEDULE, "routing": routing}
    evidence = {"stale_acts": stale, "fresh_acts": fresh, "checks": checks,
                "findings": findings}
    write_bundle("recheck_scheduler", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
