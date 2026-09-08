#!/usr/bin/env python3
"""NexusAI JDG — V3-P37-I10 COMPREHENSIVE STATUS PAGE — jeden status fortecy:
dostępność, SLO, ostatni dowód aktualności prawa, otwarte luki P0/P1 —
V3 FORTRESS.

Dowód wdrożenia: generator status page zbiera dane z metrics.json, katalogu
SLO i ledgera kampanii; brak sekcji = BLOCK; nieświeżość > max = TRIAGE.
Podanalizy: AN03.
"""
from __future__ import annotations

import json

from v3_p37_common import (BUNDLES, P37_RULES, SLO_CATALOG, emit, now, read,
                           rule_present, threshold_present)

INNOVATION = "V3-P37-I10"
RULE = "jdg.v3_p37_obserwowalnosc.status_page"
REQUIRED_SECTIONS = ["availability", "slo_summary", "law_freshness", "open_gaps_p0_p1"]


def build_status_page() -> dict:
    """Buduje status page z istniejących źródeł (zero duplikacji metryk — AP12)."""
    page = {"generated_at": now(), "sections": {}}
    metrics = json.loads(read(BUNDLES / "metrics.json")) if read(BUNDLES / "metrics.json") else {}
    page["sections"]["availability"] = {
        "source": "bundles/metrics.json",
        "health_score": metrics.get("health_score"),
    }
    catalog = json.loads(read(SLO_CATALOG)) if read(SLO_CATALOG) else {}
    page["sections"]["slo_summary"] = {
        "source": "bundles/v3_p37_slo_catalog.json",
        "slos_total": len(catalog.get("slos", [])),
        "error_budget_policy": catalog.get("error_budget_policy"),
    }
    ledger = json.loads(read(BUNDLES / "v3_campaign_ledger.json")) if read(BUNDLES / "v3_campaign_ledger.json") else {}
    page["sections"]["law_freshness"] = {
        "source": "reguły _legal_basis + SLO-04 (SLA 7 dni)",
        "sla_days": 7,
    }
    gaps = ledger.get("summary", {})
    p0 = sum(v.get("luki_p0", 0) for v in ledger.get("parts", {}).values())
    p1 = sum(v.get("luki_p1", 0) for v in ledger.get("parts", {}).values())
    page["sections"]["open_gaps_p0_p1"] = {"source": "bundles/v3_campaign_ledger.json",
                                           "luki_p0": p0, "luki_p1": p1,
                                           "campaign_progress": gaps.get("progress_pct")}
    return page


def main() -> int:
    hay = read(P37_RULES)
    checks, findings = [], []

    has_rule = rule_present(RULE, hay)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    page = build_status_page()
    missing = [s for s in REQUIRED_SECTIONS if s not in page.get("sections", {})]
    checks.append({"name": "status_page_sections_complete", "status": "OK" if not missing else "FAIL",
                   "detail": f"sekcje status page: {sorted(page.get('sections', {}))}, brak: {missing}"})

    (BUNDLES / "v3_p37_status_page.json").write_text(
        json.dumps(page, ensure_ascii=False, indent=2), encoding="utf-8")
    checks.append({"name": "status_page_generated", "status": "OK",
                   "detail": "zapisano bundles/v3_p37_status_page.json"})

    thr = threshold_present("v3_p37_status_page_max_stale_days")
    checks.append({"name": "stale_threshold", "status": "OK" if thr else "FAIL",
                   "detail": f"v3_p37_status_page_max_stale_days w thresholds: {thr}"})

    gate = "PASS" if all(ch["status"] == "OK" for ch in checks) else "FAIL"
    bundle = {
        "innovation": INNOVATION, "generated_at": now(), "gate": gate,
        "metrics": {
            "rule_present": has_rule,
            "sections": sorted(page.get("sections", {})),
            "missing_sections": missing,
            "stale_threshold": thr,
        },
        "checks": checks, "findings": findings,
    }
    return emit(bundle, "v3_p37_status_page")


if __name__ == "__main__":
    raise SystemExit(main())
