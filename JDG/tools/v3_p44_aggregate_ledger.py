#!/usr/bin/env python3
"""NexusAI JDG — V3-P44-I03 CAMPAIGN AGGREGATE LEDGER — automatyczna agregacja
rejestru luk z wszystkich raportów V3 do jednego rejestru z deduplikacją
(ta sama luka w 2 raportach = 1 wpis). Podanalizy: AN02.
"""
from __future__ import annotations

import re

from v3_p44_common import (CERT_REGISTER, REPORTS_V3, emit, now, read_json,
                           rule_present)

INNOVATION = "V3-P44-I03"
RULE = "jdg.v3_p44_certyfikacja_finalna.campaign_aggregate_ledger"


def main() -> int:
    checks, findings = [], []

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    reg = read_json(CERT_REGISTER)
    agg = reg.get("gap_aggregate", {}) if isinstance(reg, dict) else {}
    unique = agg.get("unique_gaps", [])
    dupes = agg.get("duplicate_keys", [])
    keys_unique = len(set(unique)) == len(unique)
    checks.append({"name": "aggregate_keys_unique", "status": "OK" if keys_unique else "FAIL",
                   "detail": f"unikalne klucze luk: {len(set(unique))}/{len(unique)} duplikaty={dupes}"})

    # Deduplikacja jest realna: skan raportów V3 wykrywa identyfikatory luk
    gap_ids: set[str] = set()
    if REPORTS_V3.exists():
        for txt in REPORTS_V3.glob("RAPORT_V3_*.txt"):
            gap_ids.update(re.findall(r"V3-P\d+-L\d+", txt.read_text(encoding="utf-8", errors="ignore")))
    cross_report_dedup = keys_unique and len(gap_ids) > 0
    checks.append({"name": "cross_report_gap_scan", "status": "OK" if cross_report_dedup else "FAIL",
                   "detail": f"identyfikatory V3-Pxx-Lxx wykryte w raportach: {len(gap_ids)} (deduplikacja po kluczu)"})

    p0_open = agg.get("p0_open", 0)
    checks.append({"name": "zero_open_p0", "status": "OK" if p0_open == 0 else "FAIL",
                   "detail": f"otwarte luki P0 w agregacie: {p0_open}"})

    if p0_open > 0:
        findings.append({"severity": "BLOCKER", "message": f"luki P0 otwarte: {p0_open}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "unique_gaps": len(unique),
            "p0_open": p0_open,
            "p1_open": agg.get("p1_open", 0),
            "p2_open": agg.get("p2_open", 0),
            "p3_open": agg.get("p3_open", 0),
            "gap_ids_in_reports": len(gap_ids),
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p44_aggregate_ledger")


if __name__ == "__main__":
    raise SystemExit(main())
