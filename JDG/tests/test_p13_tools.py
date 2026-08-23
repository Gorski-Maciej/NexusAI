from __future__ import annotations

from datetime import date

import pytest

from JDG.tools.ceidg_deadline_tracker import track_deadline
from JDG.tools.lifecycle_decision_certificate import create_certificate, verify_certificate
from JDG.tools.p13_thresholds import LEGAL_RATES, load_thresholds
from JDG.tools.ryczalt_rate_validator import validate_rates
from JDG.tools.ryczalt_zus_health_harmonizer import harmonize
from JDG.tools.tax_form_whatif_simulator import compare_forms
from JDG.tools.unregistered_activity_assistant import assess


def test_p13_thresholds_are_loaded_from_rego_source() -> None:
    thresholds = load_thresholds()
    assert thresholds.limit_eur == 2_000_000
    assert thresholds.eur_pln == 4.5
    assert thresholds.limit_pln == 9_000_000
    assert thresholds.unregistered_pct == 50
    assert thresholds.source_sha256


def test_rate_validator_covers_all_registered_rates() -> None:
    result = validate_rates()
    assert result["status"] == "PASS", result["errors"]
    assert result["rates_checked"] == len(LEGAL_RATES)


def test_what_if_calculator_accounts_for_costs_and_kwota_wolna() -> None:
    result = compare_forms(300_000, 60_000, zus_base=10_000, ryczalt_rate=8.5)
    assert result["taxable_profit"] == 230_000
    assert result["taxes"]["ryczalt"] == 25_500
    assert result["best_form"] in {"ryczalt", "skala", "liniowy"}


def test_harmonizer_reports_health_tier_boundary() -> None:
    result = harmonize(60_000, ryczalt_rate=8.5, zus_monthly_pln=1_000, health_monthly_pln=300)
    assert result["health_tier"] == "TIER_1"
    assert result["total_burden_pln"] == 20_700


def test_ceidg_tracker_has_calendar_day_boundary() -> None:
    result = track_deadline(date(2026, 1, 1), date(2026, 1, 5), "DATA_CHANGE")
    assert result["due_date"] == "2026-01-08"
    assert result["days_remaining"] == 3
    assert result["status"] == "WARNING"


def test_unregistered_activity_requires_registration_only_above_limit() -> None:
    allowed = assess(2_400, 4_800, date(2026, 1, 1))
    exceeded = assess(2_400.01, 4_800, date(2026, 1, 1))
    assert allowed["status"] == "ALLOWED"
    assert exceeded["status"] == "REGISTRATION_REQUIRED"
    assert exceeded["registration_deadline"] == "2026-01-08"


def test_decision_certificate_hash_is_verifiable_and_tamper_evident() -> None:
    certificate = create_certificate(
        "SUSPENSION",
        {"months": 3},
        "bundle-13",
        legal_basis=["Prawo przedsiębiorców art. 22-25"],
        decision_id="00000000-0000-0000-0000-000000000013",
        timestamp="2026-08-23T00:00:00+00:00",
    )
    assert verify_certificate(certificate)
    certificate["business_data"]["months"] = 4
    assert not verify_certificate(certificate)


def test_invalid_inputs_are_rejected() -> None:
    with pytest.raises(ValueError):
        compare_forms(-1, 0)
    with pytest.raises(ValueError):
        harmonize(100, zus_relief_type="UNKNOWN")
    with pytest.raises(ValueError):
        assess(1, 0)
