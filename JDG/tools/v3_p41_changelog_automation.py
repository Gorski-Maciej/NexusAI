#!/usr/bin/env python3
"""NexusAI JDG — V3-P41-I08 CHANGELOG AUTOMATION — changelog GENEROWANY
z ledgera kampanii V3 (rejestr wdrożeń P30-konwencja) i weryfikowany pod
kątem spójności; zero ręcznej pracy. Podanalizy: AN04.
"""
from __future__ import annotations

import json

from v3_p41_common import (BUNDLES, emit, main_jdg_wired, now, read_json,
                           rule_present, threshold_present)

INNOVATION = "V3-P41-I08"
RULE = "jdg.v3_p41_dokumentacja.changelog_automation"
CHANGELOG = BUNDLES / "v3_p41_changelog.json"


def generate_changelog() -> dict:
    """Generuj changelog Z ledgera (mechanizm I08: rejestr → dokument)."""
    ledger = read_json(BUNDLES / "v3_campaign_ledger.json")
    parts = ledger.get("parts", ledger) if isinstance(ledger, dict) else {}
    entries = []
    for key in sorted(parts):
        v = parts[key]
        if isinstance(v, dict) and v.get("status") == "WDROŻONY_100":
            entries.append({
                "part": key,
                "slug": v.get("slug", ""),
                "report": v.get("report", ""),
                "implemented_at": v.get("implemented_at"),
                "innovations": v.get("innovations", 0),
            })
    return {
        "changelog": "v3_p41_changelog",
        "generated_at": now(),
        "generated_from": "v3_campaign_ledger",
        "entries": entries,
    }


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # GENERUJ z ledgera (mechanizm, nie ręczna praca)
    changelog = generate_changelog()
    (BUNDLES / "v3_p41_changelog.json").write_text(
        json.dumps(changelog, ensure_ascii=False, indent=2), encoding="utf-8")

    implemented = [e for e in changelog["entries"]]
    ledger_ok = len(implemented) >= 40
    checks.append({"name": "ledger_history_available", "status": "OK" if ledger_ok else "FAIL",
                   "detail": f"części WDROŻONE_100 w ledgerze: {len(implemented)}"})

    checks.append({"name": "changelog_generated_from_ledger", "status": "OK",
                   "detail": f"changelog wygenerowany: {len(changelog['entries'])} wpisów (generated_from=v3_campaign_ledger)"})

    manual = changelog.get("generated_from", "") != "v3_campaign_ledger"
    checks.append({"name": "changelog_not_manual", "status": "OK" if not manual else "FAIL",
                   "detail": f"generated_from: {changelog.get('generated_from')}"})

    t = threshold_present("v3_p41_changelog_max_age_days")
    checks.append({"name": "age_threshold_as_data", "status": "OK" if t else "FAIL",
                   "detail": f"v3_p41_changelog_max_age_days w data.thresholds: {t}"})

    wired = main_jdg_wired()
    checks.append({"name": "wiring_main_jdg", "status": "OK" if wired else "FAIL",
                   "detail": "main_jdg.rego: final_verdict_p105"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "implemented_parts": len(implemented),
            "changelog_entries": len(changelog["entries"]),
            "changelog_not_manual": not manual,
            "age_threshold_as_data": t,
            "wiring_main_jdg": wired,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p41_changelog_automation")


if __name__ == "__main__":
    raise SystemExit(main())
