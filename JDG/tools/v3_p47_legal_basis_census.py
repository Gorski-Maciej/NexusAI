#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I01 LEGAL BASIS CENSUS — pełny spis podstaw prawnych:
liczba reguł per akt, OK/NIEZWERYFIKOWANE/PODEJRZANE — jedna metryka zdrowia
prawnego fortecy. Źródło: bundles/legal_basis_v2_report.json (12 439 reguł;
251 OK; 416 LKG_OK; 11 964 NO_LKG_REF; rv_metric 2.02) — rozszerzamy, nie
duplikujemy. Podanalizy: AN01.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone

from v3_p47_common import (LB_V2_REPORT, P47_RULE, read_json, rule_present,
                           scan_legal_basis, utcnow_iso, write_bundle)

INNOVATION = "V3-P47-I01"
RULE = f"{P47_RULE}.legal_basis_census"


def main() -> int:
    checks, findings = [], []

    report = read_json(LB_V2_REPORT) or {}
    stats = report.get("stats", {})
    rules_total = report.get("rules_total", 0)

    # Podział na trzy listy na poziomie REGUŁ (partycja — suma = rules_total):
    # kategorie issues w v2 NAKŁADAJĄ SIĘ (reguła może mieć NO_ARTICLE i NO_DZU
    # jednocześnie) — liczenie po issues podwajałoby licznik (test to wyłapał).
    rows = report.get("rows", [])
    ok = 0
    unverified = 0
    missing = 0
    for r in rows:
        if r.get("status") == "MISSING" or not (r.get("legal_basis") or "").strip():
            missing += 1
        elif r.get("issues"):
            unverified += 1
        else:
            ok += 1
    suspect = 0  # PODEJRZANE liczy linter (I02) i blocker (I07); tu jawnie 0

    # Wiek spisu: z generated_at raportu v2 (honesty — realny wiek dowodu)
    generated_at = report.get("generated_at")
    census_age_days = None
    if generated_at:
        try:
            gen = datetime.fromisoformat(generated_at)
            census_age_days = int((datetime.now(timezone.utc) - gen).total_seconds() // 86400)
        except ValueError:
            census_age_days = None

    scan = scan_legal_basis()

    checks.append({"name": "v2_report_present", "status": "OK" if rules_total else "FAIL",
                   "detail": f"legal_basis_v2_report.json: {rules_total} reguł, rv_metric {report.get('rv_metric')}"})
    checks.append({"name": "three_lists_complete",
                   "status": "OK" if (ok + unverified + missing) == rules_total else "FAIL",
                   "detail": f"partycja reguł: OK={ok}, NIEZWERYFIKOWANE={unverified}, MISSING={missing} "
                             f"= suma {ok + unverified + missing} vs rules_total={rules_total} "
                             f"(issues v2 nakładają się — statystyki: {json.dumps(stats, ensure_ascii=False)})"})
    checks.append({"name": "live_scan_consistent",
                   "status": "OK" if scan["occurrences"] > 0 else "FAIL",
                   "detail": f"żywy skan rules/: {scan['occurrences']} wystąpień _legal_basis "
                             f"w {scan['files_with']} plikach"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    census_record = {
        "generated_at": utcnow_iso(),
        "rules_total": rules_total,
        "ok": ok, "unverified": unverified, "suspect": suspect, "missing": missing,
        "rv_metric": report.get("rv_metric"),
        "census_age_days": census_age_days,
        "live_scan_occurrences": scan["occurrences"],
        "live_scan_files": scan["files_with"],
    }

    if unverified > rules_total * 0.9:
        findings.append({"severity": "HIGH",
                         "message": f">90% podstaw bez pełnego łańcucha ({unverified}/{rules_total}) — "
                                    f"konieczny SLA migracji (kontrakt P46→P47 orphan backlog)"})

    routing = "TRIAGE_QUEUE" if (unverified or census_age_days is None) else "AUTO_FILE"
    metrics = {"rules_total": rules_total, "ok": ok, "unverified": unverified,
               "suspect": suspect, "missing": missing, "census_age_days": census_age_days,
               "routing": routing}
    evidence = {"census": census_record, "v2_stats": stats,
                "checks": checks, "findings": findings}
    write_bundle("census", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
