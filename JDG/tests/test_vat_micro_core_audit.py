#!/usr/bin/env python3
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.vat_micro_core_audit import (
    FindingsCollector, KEY_ARTICLES,
    check_vat_micro_structure, check_duplicates,
    check_priority_collisions, check_article_coverage,
    check_binding_registry, build_bundle,
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


def test_key_articles_count():
    assert len(KEY_ARTICLES) >= 28


def test_check_structure():
    f = FindingsCollector()
    results, ids, articles = check_vat_micro_structure(f)
    assert f.checks_run > 0
    assert len(results) > 0


def test_check_duplicates():
    f = FindingsCollector()
    _, ids, _ = check_vat_micro_structure(FindingsCollector())
    check_duplicates(f, ids)
    assert f.checks_run > 0


def test_check_article_coverage():
    f = FindingsCollector()
    _, _, articles = check_vat_micro_structure(FindingsCollector())
    check_article_coverage(f, articles)
    assert f.checks_run > 0


def test_check_binding():
    f = FindingsCollector()
    check_binding_registry(f, [])
    assert f.checks_run > 0


def test_full_validation():
    f = FindingsCollector()
    results, ids, articles = check_vat_micro_structure(f)
    check_duplicates(f, ids)
    check_priority_collisions(f, results)
    check_article_coverage(f, articles)
    check_binding_registry(f, results)

    bundle = build_bundle(f, results, articles)
    assert "schema_version" in bundle
    assert bundle["schema_version"] == "1.0.0"

    blocks = [fi for fi in f.findings if fi["severity"] == "BLOCK"]
    assert len(blocks) == 0, f"BLOCK findings: {[b['message'] for b in blocks]}"


if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-v"])
