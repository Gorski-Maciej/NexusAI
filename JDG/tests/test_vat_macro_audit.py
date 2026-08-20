#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — VAT Macro Audit Tests (ETAP 07/29)
# ═══════════════════════════════════════════════════════════════════════════════

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.vat_macro_audit import (
    FindingsCollector,
    VAT_ARTICLES,
    check_vat_substantive,
    check_vat_fraud,
    check_vat_mpp,
    check_article_coverage,
    check_duplicates,
    build_bundle,
    build_report,
    SCHEMA_VERSION,
)


class TestFindingsCollector:
    def test_empty(self):
        f = FindingsCollector()
        assert f.status == "PASS"
        assert f.checks_run == 0

    def test_block_makes_fail(self):
        f = FindingsCollector()
        f.block("G03", "test")
        assert f.status == "FAIL"

    def test_warning_stays_pass(self):
        f = FindingsCollector()
        f.warning("G03", "test")
        assert f.status == "PASS"


def test_vat_articles_coverage():
    """VAT article map has key articles."""
    assert "5" in VAT_ARTICLES
    assert "41" in VAT_ARTICLES
    assert "86" in VAT_ARTICLES
    assert "108a" in VAT_ARTICLES
    assert "113" in VAT_ARTICLES
    assert len(VAT_ARTICLES) >= 50


def test_check_substantive():
    f = FindingsCollector()
    check_vat_substantive(f)
    assert f.checks_run > 0


def test_check_fraud():
    f = FindingsCollector()
    check_vat_fraud(f)
    assert f.checks_run > 0


def test_check_mpp():
    f = FindingsCollector()
    check_vat_mpp(f)
    assert f.checks_run > 0


def test_check_article_coverage():
    f = FindingsCollector()
    check_article_coverage(f)
    assert f.checks_run > 0


def test_check_duplicates():
    f = FindingsCollector()
    check_duplicates(f)
    assert f.checks_run > 0


def test_full_validation():
    f = FindingsCollector()
    check_vat_substantive(f)
    check_vat_fraud(f)
    check_vat_mpp(f)
    check_article_coverage(f)
    check_duplicates(f)

    bundle = build_bundle(f)
    assert "schema_version" in bundle
    assert bundle["schema_version"] == "1.0.0"

    blocks = [fi for fi in f.findings if fi["severity"] == "BLOCK"]
    assert len(blocks) == 0, f"BLOCK findings: {[b['message'] for b in blocks]}"


if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-v"])
