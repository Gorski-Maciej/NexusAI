#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Orchestrator Data Contract Tests (ETAP 05/29)
# ═══════════════════════════════════════════════════════════════════════════════

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.orchestrator_data_contract import (
    FindingsCollector,
    check_main_jdg_structure,
    check_provenance_naming,
    check_pass_0_8_early_abort,
    check_safe_merge_integrity,
    check_conflicts_post_merge,
    check_decision_composer,
    check_schema_versioning,
    check_degradation_patterns,
    check_api_contract_consistency,
    build_bundle,
    build_report,
    VERDICT_FIELDS,
    RESPONSE_FIELDS,
    PASS_DEFINITIONS,
    IMMUTABLE_ALLOWLIST,
    INVARIANTS,
    SCHEMA_VERSION,
)


class TestFindingsCollector:
    """Test findings collector."""

    def test_empty_findings(self):
        f = FindingsCollector()
        assert f.status == "PASS"
        assert f.checks_run == 0

    def test_block_makes_fail(self):
        f = FindingsCollector()
        f.block("INV-018", "test block")
        assert f.status == "FAIL"
        assert f.has_blocks is True
        assert f.checks_failed == 1

    def test_warning_stays_pass(self):
        f = FindingsCollector()
        f.warning("INV-018", "test warning")
        assert f.status == "PASS"
        assert f.has_blocks is False

    def test_info_stays_pass(self):
        f = FindingsCollector()
        f.info("INV-030", "test info")
        assert f.status == "PASS"

    def test_mixed_findings(self):
        f = FindingsCollector()
        f.info("G01", "ok")
        f.warning("G02", "warn")
        f.block("G03", "fail")
        assert f.status == "FAIL"
        assert f.checks_run == 3
        assert f.checks_failed == 1
        assert f.checks_passed == 2


def test_verdict_contract_fields():
    """25-field verdict contract is defined."""
    from tools.orchestrator_data_contract import VERDICT_FIELDS
    assert "matched" in VERDICT_FIELDS
    assert "rule_id" in VERDICT_FIELDS
    assert "_routing" in VERDICT_FIELDS
    assert "_legal_basis" in VERDICT_FIELDS
    assert "vat_rate" in VERDICT_FIELDS
    assert len(VERDICT_FIELDS) >= 20


def test_response_contract_fields():
    """Response contract includes provenance + certificate."""
    from tools.orchestrator_data_contract import RESPONSE_FIELDS
    assert "_provenance_tree" in RESPONSE_FIELDS
    assert "_certainty_class" in RESPONSE_FIELDS
    assert "_certainty_guard" in RESPONSE_FIELDS
    assert "_routing_context" in RESPONSE_FIELDS


def test_pass_definitions():
    """PASS 0-8 are defined."""
    from tools.orchestrator_data_contract import PASS_DEFINITIONS
    assert len(PASS_DEFINITIONS) == 9
    assert PASS_DEFINITIONS[0]["name"] == "RISK"
    assert PASS_DEFINITIONS[8]["name"] == "ZUS_BUSINESS_MISC"
    for p in PASS_DEFINITIONS:
        assert "id" in p
        assert "name" in p
        assert "packages" in p
        assert "abort_on" in p


def test_immutable_allowlist():
    """Immutable verdict allowlist matches Rego."""
    from tools.orchestrator_data_contract import IMMUTABLE_ALLOWLIST
    assert "jdg.zus" in IMMUTABLE_ALLOWLIST
    assert "jdg.business" in IMMUTABLE_ALLOWLIST
    assert "jdg.security.fortress" in IMMUTABLE_ALLOWLIST


def test_invariants_defined():
    """Key invariants are registered."""
    from tools.orchestrator_data_contract import INVARIANTS
    assert "INV-018" in INVARIANTS
    assert "INV-020" in INVARIANTS
    assert "INV-030" in INVARIANTS
    assert "INV-035" in INVARIANTS
    assert "INV-042" in INVARIANTS


def test_certainty_classes():
    """Certainty classes are defined."""
    from tools.orchestrator_data_contract import CERTAINTY_CLASSES, CERTAINTY_GUARDS
    assert "CERTAIN" in CERTAINTY_CLASSES
    assert "NEEDS_ADVICE" in CERTAINTY_CLASSES
    assert "CERTAINTY_BLOCKED" in CERTAINTY_GUARDS
    assert "AUTO_POST_ALLOWED" in CERTAINTY_GUARDS


def test_check_main_jdg_structure():
    """Main check runs without error."""
    f = FindingsCollector()
    check_main_jdg_structure(f)
    assert f.checks_run > 0
    # main_jdg.rego should exist and pass most checks
    assert any("jdg.main" in fi["message"] for fi in f.findings)


def test_check_provenance_naming():
    """Provenance naming check runs."""
    f = FindingsCollector()
    check_provenance_naming(f)
    assert f.checks_run > 0


def test_check_pass_0_8():
    """PASS 0-8 check runs."""
    f = FindingsCollector()
    check_pass_0_8_early_abort(f)
    assert f.checks_run >= 9  # at least one per PASS


def test_check_safe_merge():
    """Safe merge integrity check runs."""
    f = FindingsCollector()
    check_safe_merge_integrity(f)
    assert f.checks_run > 0


def test_check_conflicts():
    """Conflicts post-merge check runs."""
    f = FindingsCollector()
    check_conflicts_post_merge(f)
    assert f.checks_run > 0


def test_check_decision_composer():
    """Decision composer check runs."""
    f = FindingsCollector()
    check_decision_composer(f)
    assert f.checks_run > 0


def test_check_degradation():
    """Degradation patterns check runs."""
    f = FindingsCollector()
    check_degradation_patterns(f)
    assert f.checks_run > 0


def test_check_api_contract():
    """API contract consistency check runs."""
    f = FindingsCollector()
    check_api_contract_consistency(f)
    assert f.checks_run > 0


def test_full_validation():
    """Full validation pipeline runs and produces a result."""
    f = FindingsCollector()
    check_main_jdg_structure(f)
    check_provenance_naming(f)
    check_pass_0_8_early_abort(f)
    check_safe_merge_integrity(f)
    check_conflicts_post_merge(f)
    check_decision_composer(f)
    check_schema_versioning(f)
    check_degradation_patterns(f)
    check_api_contract_consistency(f)

    from tools.orchestrator_data_contract import build_bundle
    bundle = build_bundle(f)

    assert "schema_version" in bundle
    assert "verdict_contract" in bundle
    assert "response_contract" in bundle
    assert "pass_definitions" in bundle
    assert "safe_merge" in bundle
    assert "provenance" in bundle
    assert "certainty_class" in bundle
    assert "validation" in bundle
    assert bundle["schema_version"] == "1.0.0"

    # No BLOCK findings for full PASS
    blocks = [fi for fi in f.findings if fi["severity"] == "BLOCK"]
    assert len(blocks) == 0, f"BLOCK findings: {[b['message'] for b in blocks]}"


if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-v"])
