#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I08 LEGAL BASIS COMPLETENESS SCORE — wskaźnik: % reguł
z pełnym łańcuchem (akt→art→ust→pkt) — cel 100% dla ACTIVE, trend w P37.
Źródło: legal_basis_v2_report (RV metric) + żywy skan głębokości łańcucha.
Podanalizy: AN01/AN03.
"""
from __future__ import annotations

import re

from v3_p47_common import (LB_V2_REPORT, P47_RULE, read_json, rule_present,
                           scan_legal_basis, write_bundle)

INNOVATION = "V3-P47-I08"
RULE = f"{P47_RULE}.completeness_score"

# Głębokość łańcucha: akt + art. + (ust./pkt./§) — minimum 3 jednostki redakcyjne
CHAIN_UNITS = re.compile(r"(ust\.|\bpkt\b|§|\bi\s*nast)", re.IGNORECASE)
ARTICLE = re.compile(r"art\.?\s*\d+", re.IGNORECASE)


def main() -> int:
    checks, findings = [], []

    lb2 = read_json(LB_V2_REPORT) or {}
    rows = lb2.get("rows", [])
    stats = lb2.get("stats", {})

    complete = 0
    below_min = 0
    active_rules = len(rows)
    for r in rows:
        basis = r.get("legal_basis") or ""
        has_act = bool(basis.strip()) and r.get("status") != "MISSING"
        has_article = bool(ARTICLE.search(basis))
        has_unit = bool(CHAIN_UNITS.search(basis))
        depth = sum([has_act, has_article, has_unit])
        if depth >= 3:
            complete += 1
        elif has_act:
            below_min += 1

    scan = scan_legal_basis()

    checks.append({"name": "v2_rows_processed", "status": "OK" if rows else "FAIL",
                   "detail": f"reguł w raporcie v2: {active_rules}"})
    checks.append({"name": "full_chains", "status": "OK" if complete else "TRIAGE",
                   "detail": f"pełne łańcuchy akt→art→ust/pkt: {complete}/{active_rules} "
                             f"({100 * complete / active_rules:.1f}% — cel 100% dla ACTIVE, trend → P37)"})
    checks.append({"name": "chains_below_min_depth", "status": "OK" if not below_min else "TRIAGE",
                   "detail": f"łańcuchy poniżej min. głębokości 3: {below_min} "
                             f"(AP05 — cytowanie niepełne = niezweryfikowalne)"})
    checks.append({"name": "live_basis_occurrences", "status": "OK" if scan["occurrences"] else "FAIL",
                   "detail": f"żywy skan: {scan['occurrences']} wystąpień _legal_basis w {scan['files_with']} plikach"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    pct = round(100 * complete / active_rules, 2) if active_rules else 0.0
    findings.append({"severity": "HIGH",
                     "message": f"kompletność łańcuchów {pct}% poniżej celu 100% — SLA migracji "
                                f"(spina z P46 orphan backlog 16 581 i P51 pustynie)"})

    routing = "BLOCK_AND_ALERT" if below_min and not complete else "TRIAGE_QUEUE"
    metrics = {"complete_chains": complete, "active_rules": active_rules,
               "completeness_pct": pct, "chains_below_min_depth": below_min,
               "routing": routing}
    evidence = {"v2_stats": stats, "checks": checks, "findings": findings}
    write_bundle("completeness_score", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
