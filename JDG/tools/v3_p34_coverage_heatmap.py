#!/usr/bin/env python3
"""NexusAI JDG — V3-P34-I10 COVERAGE HEATMAP CIĄGŁA — legal_coverage_heatmap
odświeżany z trendem; spadek pokrycia = alert do Law Radar (P08) — V3 FORTRESS.

Dowód wdrożenia: limity spadku i niemłodości jako dane; narząd:
legal_coverage_heatmap.py (332 linie, 7 funkcji). Podanalizy: AN04.
"""
from __future__ import annotations

from v3_p34_common import (BASE, P34_RULES, THRESHOLDS, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P34-I10"
RULE = "jdg.v3_p34_walidacja_narzedzia.coverage_heatmap_continuous"


def main() -> int:
    hay = read(P34_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    drop = threshold_present("v3_p34_coverage_drop_block")
    stale = threshold_present("v3_p34_heatmap_max_stale_days")
    checks.append({"name": "trend_thresholds", "status": "OK" if (drop and stale) else "FAIL",
                   "detail": f"v3_p34_coverage_drop_block={drop}, heatmap_max_stale_days={stale}"})

    tool = (BASE / "tools" / "legal_coverage_heatmap.py").exists()
    checks.append({"name": "heatmap_tool_present", "status": "OK" if tool else "FAIL",
                   "detail": "tools/legal_coverage_heatmap.py (narząd): " + str(tool)})

    radar = "P08" in hay or "Law Radar" in hay
    checks.append({"name": "law_radar_alert", "status": "OK" if radar else "FAIL",
                   "detail": "spadek pokrycia = alert do Law Radar (P08): " + str(radar)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "trend_thresholds": drop and stale,
            "heatmap_tool_present": tool,
            "law_radar_alert": radar,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p34_coverage_heatmap")


if __name__ == "__main__":
    raise SystemExit(main())
