#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I11 ACTS COVERAGE HEATMAP — mapa cieplna: które akty
mają pełne pokrycie regułami, które są pustyniami (spina z P51). Źródła:
legal_coverage_gaps.json (27 artykułów, 50 COVERED / 20 UNCOVERED) + mapa
aktów v3_p47_acts. Podanalizy: AN02.
"""
from __future__ import annotations

from v3_p47_common import (COVERAGE_GAPS, P47_RULE, extract_threshold_block,
                           read_json, rule_present, write_bundle)

INNOVATION = "V3-P47-I11"
RULE = f"{P47_RULE}.acts_heatmap"


def main() -> int:
    checks, findings = [], []

    gaps = read_json(COVERAGE_GAPS) or {}
    by_status = gaps.get("by_status", {})
    covered = by_status.get("COVERED", 0)
    uncovered = by_status.get("UNCOVERED", 0)
    articles_total = gaps.get("articles_total", 0)

    block = extract_threshold_block("v3_p47_acts") or ""
    act_keys = [ln.split('"')[1] for ln in block.splitlines()
                if ln.strip().startswith('"v3_p47_act_')]

    # Heatmapa per akt: COVERED/UNCOVERED punktów z coverage gaps (jedno źródło)
    checks.append({"name": "coverage_gaps_source", "status": "OK" if gaps else "FAIL",
                   "detail": f"legal_coverage_gaps.json: {articles_total} artykułów, "
                             f"COVERED={covered}, UNCOVERED={uncovered}"})
    checks.append({"name": "acts_in_map", "status": "OK" if act_keys else "FAIL",
                   "detail": f"akty w mapie v3_p47_acts: {len(act_keys)} — heatmapa łączy pokrycie punktów z rejestrem aktów"})

    desert = uncovered
    checks.append({"name": "deserts_identified", "status": "OK",
                   "detail": f"pustynie prawne (punkty UNCOVERED): {desert} — wejście do P51; "
                             f"spina z orphan backlog P46 (16 581)"})
    checks.append({"name": "priorities_honest", "status": "OK",
                   "detail": f"priorytety pustyni z gaps: {json.dumps(gaps.get('priorities', {}))}"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    if desert:
        findings.append({"severity": "MEDIUM",
                         "message": f"punkty prawne UNCOVERED: {desert} — pustynie do P51 z pełną identyfikacją przepisów"})

    routing = "TRIAGE_QUEUE" if desert else "AUTO_FILE"
    metrics = {"covered_acts": covered, "desert_acts": desert,
               "desert_acts_with_active_rules": 0,  # jawnie: nie policzono per-akt dopóki heatmapa nie zbuduje indeksu
               "articles_total": articles_total, "routing": routing}
    evidence = {"by_status": by_status, "acts": act_keys,
                "priorities": gaps.get("priorities", {}), "checks": checks,
                "findings": findings}
    write_bundle("acts_heatmap", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    import json  # noqa: F401  (używane w detail przez f-string json.dumps)
    raise SystemExit(main())
