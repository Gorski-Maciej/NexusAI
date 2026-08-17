#!/usr/bin/env python3
"""
Auto-Tests für P00 (RAPORT_00 P0-2) Legal Coverage Closure
==========================================================
Kontakty weryfikujące:
  1. 6 reguł GAP (Art. 17/90/113/30c/Art. 9/Art. 117ba) istnieje
     w rules/ z niepustą _legal_basis i matched:true.
  2. Narzędzia fix_p00_* wykonały się (raporty artefaktowe istnieją).
  3. legal_coverage_gaps.json (po regeneracji) wykazuje 0 GAP / 0 PARTIAL
     = 27/27 artykułów COMPLETE.

Uruchomienie: pytest tests/auto/test_p00_legal_coverage_closure.py -v
"""

import json
import re
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parent.parent.parent
RULES_DIR = JDG_ROOT / "rules"
BUNDLES = JDG_ROOT / "bundles"

# 6 reguł GAP zamkniętych w pliku p00_legal_coverage_closure.rego
# + 6 deklarowanych w LEGAL_COVERAGE.md
GAP_RULE_IDS = [
    "jdg.vat.a17.r5",
    "jdg.vat.a90.r1",
    "jdg.vat.a113.r1",
    "jdg.pit.a30c.r1",
    "jdg.pit.advances_returns.loss_carry_forward",
    "jdg.ord.a117ba.r1",
]

RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
BASIS_RE = re.compile(r'"_legal_basis"\s*:\s*"([^"]*)"')


def _scan_rule(rule_id: str) -> list[dict]:
    results = []
    for p in RULES_DIR.rglob("*.rego"):
        if ".bak" in p.name or "backup" in p.name.lower():
            continue
        txt = p.read_text(encoding="utf-8", errors="ignore")
        for m in RULE_ID_RE.finditer(txt):
            if m.group(1) == rule_id:
                # okno w obie strony: "matched": true bywa PRZED rule_id w tym
                # samym literale (np. ostatnia reguła pliku — brak następnego
                # bloku w oknie forward-only)
                ctx = txt[max(0, m.start() - 200):m.start() + 4000]
                bm = BASIS_RE.search(ctx)
                basis = bm.group(1) if bm else ""
                has_matched_true = '"matched": true' in ctx or '"matched":true' in ctx
                results.append({
                    "file": str(p.relative_to(JDG_ROOT)),
                    "legal_basis": basis,
                    "matched_true": has_matched_true,
                })
    return results


class TestP00GAPRulesExist:
    """Reguły GAP muszą istnieć w rules/ z niepustą podstawą i matched:true."""

    @pytest.mark.parametrize("rule_id", GAP_RULE_IDS)
    def test_rule_exists_with_basis(self, rule_id):
        hits = _scan_rule(rule_id)
        assert hits, f"Rule {rule_id} NOT FOUND in rules/"
        assert any(h["legal_basis"].strip() for h in hits), \
            f"Rule {rule_id} exists but _legal_basis is empty in all files"
        assert any(h["matched_true"] for h in hits), \
            f"Rule {rule_id} exists but matched is not true in any block"


class TestP00ToolsArtifacts:
    """Raporty artefaktowe narzędzi P00 istnieją po uruchomieniu."""

    def test_legal_basis_changes_exist(self):
        p = BUNDLES / "p00_legal_basis_changes.json"
        assert p.exists(), "p00_legal_basis_changes.json — brak (uruchom fix_p00_legal_basis_closure.py)"

    def test_duplicate_changes_exist(self):
        p = BUNDLES / "p00_duplicate_changes.json"
        assert p.exists(), "p00_duplicate_changes.json — brak (uruchom fix_p00_duplicates.py)"

    def test_legal_basis_changes_nonempty(self):
        p = BUNDLES / "p00_legal_basis_changes.json"
        data = json.loads(p.read_text(encoding="utf-8"))
        assert data.get("stats", {}).get("changes", 0) > 0


class TestP00LegalCoverageGapsClosed:
    """legal_coverage_gaps.json musi wykazywać 0 GAP / 0 PARTIAL
    (wszystkie 27 artykułów P1-critical COMPLETE)
    po regeneracji przez legal_coverage_gap_report.py."""

    def test_all_articles_complete(self):
        p = BUNDLES / "legal_coverage_gaps.json"
        assert p.exists(), "Brak legal_coverage_gaps.json — uruchom legal_coverage_gap_report.py"
        data = json.loads(p.read_text(encoding="utf-8"))
        by_status = data.get("by_status", {})
        assert by_status.get("GAP", 0) == 0, f"Oczekiwano 0 GAP, jest {by_status.get('GAP')}"
        assert by_status.get("PARTIAL", 0) == 0, f"Oczekiwano 0 PARTIAL, jest {by_status.get('PARTIAL')}"
        total = sum(by_status.values())
        complete = by_status.get("COMPLETE", 0)
        assert total > 0, "Brak artykułów w gaps report"
        assert complete == total, f"COMPLETE={complete} != total={total}"
