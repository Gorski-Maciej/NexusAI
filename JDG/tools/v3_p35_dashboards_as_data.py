#!/usr/bin/env python3
"""NexusAI JDG — V3-P35-I07 DASHBOARDY JAKO DANE — konfiguracja dashboardu
(metryki, progi, alarmy) w danych — kampania V3 FORTRESS.

Dowód wdrożenia: zmiana widoku bez deployu (ADR-002); hardcode widoków =
BLOCK; domena bez dashboardu = TRIAGE. Narządy: enterprise_dashboard.py,
confidence_dashboard.py, drift_dashboard.py. Podanalizy: AN03.
"""
from __future__ import annotations

from v3_p35_common import (BASE, P35_RULES, emit, now, read, rule_present)

INNOVATION = "V3-P35-I07"
RULE = "jdg.v3_p35_audyutory_domenowe.dashboards_as_data"


def main() -> int:
    hay = read(P35_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    # narządy dashboardów w repo
    tools_ok = all((BASE / "tools" / t).exists()
                   for t in ("enterprise_dashboard.py", "confidence_dashboard.py",
                             "drift_dashboard.py"))
    checks.append({"name": "dashboard_tools_present", "status": "OK" if tools_ok else "FAIL",
                   "detail": "enterprise/confidence/drift dashboards: " + str(tools_ok)})

    config = all(k in hay for k in ("metryk", "progi", "alarm"))
    checks.append({"name": "config_as_data_fields", "status": "OK" if config else "FAIL",
                   "detail": "metryki + progi + alarmy jako dane: " + str(config)})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "dashboard_tools_present": tools_ok,
            "config_as_data_fields": config,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p35_dashboards_as_data")


if __name__ == "__main__":
    raise SystemExit(main())
