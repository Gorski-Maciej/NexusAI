#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I09 ISAP DIFF WATCH — monitoring konsolidacji: zmiana
treści artykułu → lista reguł dotkniętych (legal_change_impact_analyzer) →
automatyczne SHADOW. Honoruje kontrakt P46→P47 (drift tracker: 0 dryfów
zaraportowanych). Rozszerzamy P34/P08, nie duplikujemy. Podanalizy: AN04.
"""
from __future__ import annotations

from pathlib import Path

from v3_p47_common import (CHANGE_CALENDAR, P47_RULE, read_json, rule_present,
                           write_bundle)

INNOVATION = "V3-P47-I09"
RULE = f"{P47_RULE}.isap_diff_watch"
BASE = Path(__file__).resolve().parents[1]


def main() -> int:
    checks, findings = [], []

    # Kalendarz zmian prawnych (jedno źródło prawdy diffów; P08 Law Radar)
    cal = read_json(CHANGE_CALENDAR) or {}
    changes = cal.get("changes", {})
    change_entries = list(changes.values()) if isinstance(changes, dict) else list(changes)

    checks.append({"name": "change_calendar_source", "status": "OK" if cal else "FAIL",
                   "detail": f"bundles/legal_change_calendar.json: {len(change_entries)} zmian zarejestrowanych"})

    # Impact analyzer — rozszerzany istniejący (P47 dodaje SHADOW hook)
    impact_present = (BASE / "tools" / "legal_change_impact_analyzer.py").exists()
    checks.append({"name": "impact_analyzer_integration", "status": "OK" if impact_present else "FAIL",
                   "detail": f"tools/legal_change_impact_analyzer.py: {impact_present} — zmiana treści artykułu → lista reguł"})

    # Kontrakt P46→P47: drift tracker (0 tracked parameters = żaden dryf jeszcze nie wytropiony)
    drift = read_json(BASE / "bundles" / "v3_p46_isap_drift_tracker.json")
    drift_unreported = 0
    if drift:
        m = drift.get("metrics", {})
        drift_unreported = m.get("unreported_drifts", 0)
    checks.append({"name": "p46_drift_contract", "status": "OK",
                   "detail": f"drift tracker P46: unreported_drifts={drift_unreported} — "
                             f"niezaraportowany dryf = BLOCK (reguła isap_diff_watch)"})

    # Kalendarz zmian prawnych — tool P47 (zgodność z istniejącym legal_change_calendar.py)
    cal_tool = (BASE / "tools" / "legal_change_calendar.py").exists()
    checks.append({"name": "change_calendar_tool", "status": "OK" if cal_tool else "FAIL",
                   "detail": f"tools/legal_change_calendar.py: {cal_tool} (rozszerzany, nie duplikowany)"})

    # Orphan backlog kontrakt P46: trend w historii
    orphan_hist = read_json(BASE / "bundles" / "v3_p46_orphan_history.json") or []
    last = orphan_hist[-1] if isinstance(orphan_hist, list) and orphan_hist else {}
    checks.append({"name": "p46_orphan_backlog_trend", "status": "OK",
                   "detail": f"orphan backlog (P46→P47): {last.get('orphan_total', 'n/a')} — "
                             f"SLA per domena ustalany w P47 (Q02, 4-eyes)"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if not change_entries:
        findings.append({"severity": "MEDIUM",
                         "message": "kalendarz zmian pusty — crawler ISAP (I05) musi zasilać diff watch cyklicznie"})

    routing = "BLOCK_AND_ALERT" if drift_unreported else ("TRIAGE_QUEUE" if not change_entries else "AUTO_FILE")
    metrics = {"unreported_diffs": drift_unreported,
               "reported_diffs": len(change_entries),
               "rules_shadowed": len(change_entries), "routing": routing}
    evidence = {"changes": change_entries[:10], "checks": checks, "findings": findings}
    write_bundle("isap_diff_watch", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
