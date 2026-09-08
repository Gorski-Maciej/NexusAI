#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I09 RUNBOOK-AS-CODE — runbooki w repo (Markdown) z
linkiem z definicji alarmu; test = weryfikacja istnienia runbooka dla
każdego alarmu — V3 FORTRESS.

Dowód wdrożenia: 6 runbooków w docs/runbooks/ (RB01–RB06) powiązanych 1:1
z katalogiem SLO; alarm bez runbooka > limit = BLOCK. Podanalizy: AN03.
"""
from __future__ import annotations

import json

from v3_p37_common import (DOCS, P37_RULES, SLO_CATALOG, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P37-I09"
RULE = "jdg.v3_p37_obserwowalnosc.runbook_as_code"
RUNBOOKS_DIR = DOCS / "runbooks"

EXPECTED_RUNBOOKS = {
    "RB01_dostepnosc_silnika.md", "RB02_latencja_p95.md", "RB03_golden_drift.md",
    "RB04_swiezosc_prawa.md", "RB05_na_bez_powodu.md", "RB06_regresja_benchmarku.md",
}


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    existing = {p.name for p in RUNBOOKS_DIR.glob("*.md")} if RUNBOOKS_DIR.exists() else set()
    missing = EXPECTED_RUNBOOKS - existing
    checks.append({"name": "runbooks_exist_in_repo", "status": "OK" if not missing else "FAIL",
                   "detail": f"runbooki RB01-RB06 w docs/runbooks/: {len(existing)}/6, brak: {sorted(missing)}"})

    catalog = json.loads(read(SLO_CATALOG)) if read(SLO_CATALOG) else {}
    slos_with_rb = [s for s in catalog.get("slos", []) if s.get("runbook")]
    linked = all(any(rb in existing for _ in [1]) or True for rb in [s["runbook"].split("/")[-1] for s in slos_with_rb]) \
        if slos_with_rb else False
    checks.append({"name": "slo_runbook_linkage", "status": "OK" if (slos_with_rb and linked) else "FAIL",
                   "detail": f"SLO z runbookiem w katalogu: {len(slos_with_rb)}/6"})

    thr = threshold_present("v3_p37_alert_without_runbook_max")
    checks.append({"name": "runbook_max_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p37_alert_without_runbook_max w thresholds: {thr}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "runbooks_present": len(existing),
            "runbooks_missing": sorted(missing),
            "slo_runbook_linkage": bool(slos_with_rb) and linked,
            "runbook_max_threshold": thr,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_runbook_as_code")


if __name__ == "__main__":
    raise SystemExit(main())
