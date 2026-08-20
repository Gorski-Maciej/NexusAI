#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.pit_macro_audit import (
    BUNDLE_PATH,
    REPORT_PATH,
    build_evidence,
    cross_domain_evidence,
    forecast_evidence,
    package_evidence,
    temporal_evidence,
)


ROOT = Path(__file__).resolve().parent.parent
PACKAGE = (ROOT / "rules/pit_macro_etap10_innovations_v1.rego").read_text(encoding="utf-8")


def test_package_structure_and_no_duplicate_rule_ids():
    evidence = package_evidence(PACKAGE)
    assert evidence["package"]
    assert evidence["balanced_braces"]
    assert evidence["duplicate_free"]
    assert evidence["activation"]
    assert evidence["decision_mode_suggest"]
    assert evidence["no_auto_post"]


def test_four_forms_and_scope_markers_are_present():
    for marker in ["PIT_SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD"]:
        assert marker in PACKAGE
    for marker in ["Art. 22-23 PIT", "Art. 44, 45 PIT", "Art. 21 PIT"]:
        assert marker in PACKAGE


def test_temporal_and_legal_source_contract():
    evidence = temporal_evidence(PACKAGE)
    assert evidence["complete"]
    assert "data.jdg.thresholds" in PACKAGE
    assert "Bbb/LKG" in PACKAGE


def test_three_and_five_year_forecast():
    evidence = forecast_evidence(PACKAGE)
    assert evidence["complete"]
    assert "forecast_3y_total" in PACKAGE
    assert "forecast_5y_total" in PACKAGE


def test_cross_domain_gates_fail_closed_to_review():
    evidence = cross_domain_evidence(PACKAGE)
    assert evidence["complete"]
    assert "vat_crosscheck" in PACKAGE
    assert "zus_crosscheck" in PACKAGE
    assert "uor_crosscheck" in PACKAGE
    assert "TRIAGE_QUEUE" in PACKAGE


def test_boundary_cases_are_explicitly_blocked_or_triaged():
    for marker in [
        "former_employer_risk",
        "lump_limit_risk",
        "midyear_change_risk",
        "uncertain_kup",
        "missing_inputs",
        "BLOCK_AND_ALERT",
        "FORM_CHANGE_REVIEW",
    ]:
        assert marker in PACKAGE


def test_built_report_and_bundle_are_full():
    evidence = build_evidence()
    assert REPORT_PATH.exists()
    assert BUNDLE_PATH.exists()
    assert evidence["status"] == "WDROZONY_100"
    assert evidence["gate_summary"]["passed"] == evidence["gate_summary"]["total"]


if __name__ == "__main__":
    import pytest

    pytest.main([__file__, "-v"])
