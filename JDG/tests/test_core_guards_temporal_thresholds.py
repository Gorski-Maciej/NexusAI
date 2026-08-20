#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Core Guards Temporal Thresholds Tests (ETAP 06/29)
# ═══════════════════════════════════════════════════════════════════════════════

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.core_guards_temporal_thresholds import (
    FindingsCollector,
    INVARIANT_CATALOG,
    check_invariant_catalog,
    check_runtime_invariants_rego,
    check_hardcoded_values,
    check_temporal_intervals,
    check_validation_rules,
    check_fallback_patterns,
    check_reliability_guarantee,
    check_certainty_propagation,
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
        f.block("INV-001", "test")
        assert f.status == "FAIL"

    def test_warning_stays_pass(self):
        f = FindingsCollector()
        f.warning("INV-001", "test")
        assert f.status == "PASS"


def test_invariant_catalog_has_42():
    assert len(INVARIANT_CATALOG) == 42


def test_invariant_ids_unique():
    ids = [i["id"] for i in INVARIANT_CATALOG]
    assert len(ids) == len(set(ids))


def test_invariant_levels():
    runtime = [i for i in INVARIANT_CATALOG if i["level"] == "RUNTIME"]
    build = [i for i in INVARIANT_CATALOG if i["level"] == "BUILD"]
    statistical = [i for i in INVARIANT_CATALOG if i["level"] == "STATISTICAL"]
    assert len(runtime) >= 15
    assert len(build) >= 10
    assert len(statistical) >= 3


def test_key_invariants_present():
    key_ids = {"INV-001", "INV-003", "INV-005", "INV-018", "INV-030",
               "INV-035", "INV-037", "INV-039", "INV-042"}
    catalog_ids = {i["id"] for i in INVARIANT_CATALOG}
    assert key_ids.issubset(catalog_ids)


def test_check_invariant_catalog():
    f = FindingsCollector()
    check_invariant_catalog(f)
    assert f.checks_run >= 2


def test_check_runtime_invariants():
    f = FindingsCollector()
    check_runtime_invariants_rego(f)
    assert f.checks_run > 0


def test_check_hardcoded():
    f = FindingsCollector()
    check_hardcoded_values(f)
    assert f.checks_run > 0


def test_check_temporal():
    f = FindingsCollector()
    check_temporal_intervals(f)
    assert f.checks_run > 0


def test_check_validation():
    f = FindingsCollector()
    check_validation_rules(f)
    assert f.checks_run > 0


def test_check_fallback():
    f = FindingsCollector()
    check_fallback_patterns(f)
    assert f.checks_run > 0


def test_check_reliability():
    f = FindingsCollector()
    check_reliability_guarantee(f)
    assert f.checks_run > 0


def test_check_certainty():
    f = FindingsCollector()
    check_certainty_propagation(f)
    assert f.checks_run > 0


def test_full_validation():
    f = FindingsCollector()
    check_invariant_catalog(f)
    check_runtime_invariants_rego(f)
    check_hardcoded_values(f)
    check_temporal_intervals(f)
    check_validation_rules(f)
    check_fallback_patterns(f)
    check_reliability_guarantee(f)
    check_certainty_propagation(f)

    bundle = build_bundle(f)
    assert "schema_version" in bundle
    assert "invariant_catalog" in bundle
    assert bundle["invariant_catalog"]["total"] == 42

    blocks = [fi for fi in f.findings if fi["severity"] == "BLOCK"]
    assert len(blocks) == 0, f"BLOCK findings: {[b['message'] for b in blocks]}"


if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-v"])
