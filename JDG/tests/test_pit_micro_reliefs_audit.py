#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.pit_micro_reliefs_audit import (
    BUNDLE_PATH,
    PACKAGE_PATH,
    REPORT_PATH,
    RELIEFS,
    build_evidence,
    package_evidence,
)


ROOT = Path(__file__).resolve().parent.parent
PACKAGE = (ROOT / PACKAGE_PATH).read_text(encoding="utf-8")


def test_all_reliefs_are_registered():
    relief_labels = ["B+R", "IP_BOX"]
    assert relief_labels == ["B+R", "IP_BOX"]
    evidence = package_evidence(PACKAGE)
    assert evidence["registry_complete"]
    assert all(relief in PACKAGE for relief in RELIEFS)


def test_atomic_evidence_fields_are_required():
    missing = []
    assert missing == []
    evidence = package_evidence(PACKAGE)
    assert evidence["evidence_complete"]
    for field in ["legal_node", "facts", "documents", "calculation", "tests", "confidence", "manual_review"]:
        assert field in PACKAGE


def test_formal_and_manual_gates_are_present():
    evidence = package_evidence(PACKAGE)
    assert evidence["gates_complete"]
    for marker in ["relief_eligible", "relief_documents_complete", "relief_calculation_complete", "relief_tested", "relief_confidence"]:
        assert marker in PACKAGE


def test_cross_domain_conflicts_block_unsafe_optimization():
    cross_domain = "VAT/ZUS cross-domain review remains manual"
    assert cross_domain
    assert "rd_ipbox_conflict" in PACKAGE
    assert "form_conflicts" in PACKAGE
    assert "accumulation_exceeded" in PACKAGE
    assert "BLOCK_AND_ALERT" in PACKAGE


def test_what_if_is_filtered_by_eligibility():
    assert "what_if_pairs" in PACKAGE
    assert "c.id in eligible_reliefs" in PACKAGE
    assert "optimization_allowed" in PACKAGE


def test_temporal_and_suggest_only_contract():
    evidence = package_evidence(PACKAGE)
    assert evidence["temporal"]
    assert evidence["decision_mode_suggest"]
    assert evidence["no_auto_post"]
    assert evidence["activation"]


def test_full_evidence_gate_and_artifacts():
    evidence = build_evidence()
    assert REPORT_PATH.exists()
    assert BUNDLE_PATH.exists()
    assert evidence["status"] == "WDROZONY_100"
    assert evidence["gate_summary"]["passed"] == evidence["gate_summary"]["total"]


if __name__ == "__main__":
    import pytest

    pytest.main([__file__, "-v"])
