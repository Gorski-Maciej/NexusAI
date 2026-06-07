"""
Tests for Part XI — BillingEstimator.

Covers:
  - Default rules loaded
  - Estimate for national invoice
  - Estimate with additional services
  - Foreign invoice pricing
  - Fallback rule
"""

from __future__ import annotations

import duckdb
import pytest

from nexus_ai.services.billing_estimator import (
    BillingEstimator,
    ensure_schema,
    seed_default_billing_rules,
    DEFAULT_BILLING_RULES,
)


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    ensure_schema(c)
    seed_default_billing_rules(c)
    return c


@pytest.fixture
def estimator(conn: duckdb.DuckDBPyConnection) -> BillingEstimator:
    return BillingEstimator(conn)


class TestBillingEstimator:
    def test_default_rules_loaded(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Default billing rules are seeded."""
        count = conn.execute("SELECT COUNT(1) FROM billing_rules").fetchone()[0]
        assert count == len(DEFAULT_BILLING_RULES)

    def test_estimate_national_cit(self, estimator: BillingEstimator) -> None:
        """National invoice, CIT → base price + CIT-specific."""
        result = estimator.estimate(
            document_type="invoice_national",
            tax_form="CIT_STANDARD",
        )
        assert result.total_price_pln > 0
        assert result.total_time_hours > 0
        assert result.breakdown is not None

    def test_estimate_with_additional_services(self, estimator: BillingEstimator) -> None:
        """With KSeF service → additional charge."""
        result = estimator.estimate(
            document_type="invoice_national",
            tax_form="CIT_STANDARD",
            additional_services=["ksef"],
        )
        # Should include KSeF surcharge
        assert result.total_price_pln > 1.0

    def test_estimate_foreign(self, estimator: BillingEstimator) -> None:
        """Foreign invoice → higher price."""
        result = estimator.estimate(
            document_type="invoice_foreign",
            tax_form="CIT_STANDARD",
        )
        assert result.total_price_pln >= 3.0

    def test_estimate_fallback(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Unknown document type → fallback rule."""
        conn.execute("DELETE FROM billing_rules")
        # Only re-insert fallback
        import json, uuid
        conn.execute(
            """INSERT INTO billing_rules (rule_id, condition_json, price_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (str(uuid.uuid4()), "{}", '{"price_pln": 0.50, "processing_time_hours": 0.2}',
             "2024-01-01", None, 999),
        )
        estimator = BillingEstimator(conn)
        result = estimator.estimate(document_type="unknown", tax_form="UNKNOWN")
        assert result.total_price_pln == 0.50
