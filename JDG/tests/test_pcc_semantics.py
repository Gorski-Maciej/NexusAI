from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from p14_thresholds import load_thresholds  # noqa: E402
from pcc_engine import detect_transaction  # noqa: E402
from pcc_local_excise_auditor import pcc3_generator, pcc3_zero_click, pcc_calculator  # noqa: E402
from p15_pcc_local_excise_toolkit import P15Toolkit  # noqa: E402


def test_p14_threshold_registry_is_shared() -> None:
    thresholds = load_thresholds()
    assert thresholds.pcc_exemption_limit == 1_000
    assert thresholds.pcc3_deadline_days == 14
    assert thresholds.excise_gasoline == 1_566


def test_p14_generators_apply_whole_value_exemption() -> None:
    assert pcc_calculator("SALE_MOVABLE", 1_000)["tax_due"] == 0.0
    assert pcc_calculator("SALE_MOVABLE", 1_000.01)["tax_due"] == 20.0
    assert detect_transaction("sale", 1_000)["tax_due"] == 0.0
    assert detect_transaction("sale", 1_000.01)["tax_due"] == 20.0
    assert pcc3_generator("SALE_MOVABLE", 1_000)["submission_required"] is False
    assert pcc3_generator("SALE_MOVABLE", 1_000.01)["submission_required"] is True


def test_p14_zero_click_does_not_alert_exempt_transaction() -> None:
    result = pcc3_zero_click("SALE_MOVABLE", 1_000, days_elapsed=13)
    assert result["tax_due"] == 0.0
    assert result["urgency_alert"] is False
    assert result["routing"] == ""


def test_p15_toolkit_uses_threshold_as_eligibility_rule() -> None:
    toolkit = P15Toolkit()
    at_limit = toolkit.detect_pcc_obligation(1_000, "SALE_MOVABLE")
    above_limit = toolkit.detect_pcc_obligation(1_000.01, "SALE_MOVABLE")
    assert at_limit["is_exempt"] is True
    assert at_limit["pcc_tax_pln"] == 0
    assert above_limit["is_exempt"] is False
    assert above_limit["pcc_tax_pln"] == 20.0
