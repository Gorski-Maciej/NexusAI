"""
Tests for PreLedgerValidator — warstwa walidacyjna przed TigerBeetle.

Sprawdza:
  1. Poprawną transakcję (EXPENSE: 40100/22100 → 20200)
  2. Błędną parę kont (np. przychodowe konto jako debet w EXPENSE)
  3. Błędny znak kwoty (NEGATIVE zamiast POSITIVE)
  4. Limit kwoty (MAX_INVOICE_AMOUNT_GROSZE)
  5. Zarządzanie regułami (add_rule, list_rules, delete_rule)
  6. Delegację do validate_invariants
"""

from __future__ import annotations

import os
import tempfile
from decimal import Decimal

import duckdb
import pytest

from services.pre_ledger_validator import (
    PreLedgerValidator,
    TransferSpec,
    LedgerValidationError,
)
from tax.math_engine import ValidationResult, InvoicePositions, InvoiceSummary


@pytest.fixture
def conn():
    """In-memory DuckDB connection with PreLedgerValidator schema."""
    c = duckdb.connect(":memory:")
    # Also create the tax_rules table for invariant guard if needed
    c.execute(
        "CREATE TABLE IF NOT EXISTS tax_rules (rule_id VARCHAR PRIMARY KEY, priority INTEGER)"
    )
    yield c
    c.close()


@pytest.fixture
def validator(conn):
    """PreLedgerValidator with default rules seeded."""
    v = PreLedgerValidator(conn)
    v.ensure_default_rules()
    return v


# ── Helper: standard expense transfers ───────────────────────────────────


def _expense_transfers(net: int = 10000, vat: int = 2300) -> list[TransferSpec]:
    return [
        TransferSpec(40100, 20200, net, "expense"),
        TransferSpec(22100, 20200, vat, "vat_input"),
    ]


# ── Test 1: Poprawna transakcja kosztowa ─────────────────────────────────


class TestValidTransaction:
    def test_expense_passes_all_checks(self, validator):
        """Standard expense: net 100 PLN, VAT 23 PLN → should pass."""
        transfers = _expense_transfers(10000, 2300)
        positions = [
            InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23")),
        ]
        summary = InvoiceSummary(netto_grosze=10000, vat_grosze=2300, brutto_grosze=12300)

        result = validator.validate(transfers, "EXPENSE", positions=positions, summary=summary)
        assert result.is_valid, f"Expected valid, got: {result.error_message}"

    def test_expense_without_positions(self, validator):
        """Should still validate account pairs without positions."""
        transfers = _expense_transfers(10000, 2300)
        result = validator.validate(transfers, "EXPENSE")
        assert result.is_valid

    def test_revenue_transaction(self, validator):
        """Revenue: 20200 → 70000."""
        transfers = [
            TransferSpec(20200, 70000, 50000, "revenue"),
        ]
        result = validator.validate(transfers, "REVENUE")
        assert result.is_valid


# ── Test 2: Błędne pary kont ────────────────────────────────────────────


class TestInvalidAccountPairs:
    def test_wrong_debit_account(self, validator):
        """Using a revenue account as debit in EXPENSE should fail."""
        transfers = [
            TransferSpec(70000, 20200, 10000, "expense"),  # 70000 is revenue!
        ]
        result = validator.validate(transfers, "EXPENSE")
        assert not result.is_valid
        assert "ACCOUNT_PAIR" in result.error_message

    def test_wrong_credit_account(self, validator):
        """Using an expense account as credit in EXPENSE should fail."""
        transfers = [
            TransferSpec(40100, 70000, 10000, "expense"),  # 70000 is revenue as credit!
        ]
        result = validator.validate(transfers, "EXPENSE")
        assert not result.is_valid
        assert "ACCOUNT_PAIR" in result.error_message

    def test_unknown_transaction_type(self, validator):
        """No rules for an unknown transaction type."""
        transfers = [
            TransferSpec(100, 200, 1000, "unknown"),
        ]
        result = validator.validate(transfers, "UNKNOWN_TYPE")
        assert not result.is_valid


# ── Test 3: Znak kwoty ──────────────────────────────────────────────────


class TestAmountSign:
    def test_negative_amount_on_expense_fails(self, validator):
        """EXPENSE expects POSITIVE, negative amount should fail."""
        transfers = [
            TransferSpec(40100, 20200, -10000, "expense"),  # negative!
        ]
        result = validator.validate(transfers, "EXPENSE")
        assert not result.is_valid
        assert "AMOUNT_SIGN" in result.error_message

    def test_negative_amount_on_correction_passes(self, validator):
        """CORRECTION allows ANY sign."""
        transfers = [
            TransferSpec(20200, 40100, -5000, "correction"),
        ]
        result = validator.validate(transfers, "CORRECTION")
        assert result.is_valid, f"Expected valid, got: {result.error_message}"

    def test_zero_amount_passes(self, validator):
        """Zero amount is POSITIVE (non-negative)."""
        transfers = [
            TransferSpec(40100, 20200, 0, "expense"),
        ]
        result = validator.validate(transfers, "EXPENSE")
        assert result.is_valid


# ── Test 4: Limity kwot ─────────────────────────────────────────────────


class TestAmountLimits:
    def test_exceeds_max_limit(self, validator):
        """Amount above 10M PLN should fail."""
        transfers = _expense_transfers(1_000_000_001, 0)  # > 10M PLN
        result = validator.validate(transfers, "EXPENSE")
        assert not result.is_valid
        assert "LIMIT" in result.error_message

    def test_at_max_limit(self, validator):
        """Amount at exactly 10M PLN should pass."""
        transfers = _expense_transfers(1_000_000_000, 0)  # exactly 10M PLN
        result = validator.validate(transfers, "EXPENSE")
        assert result.is_valid, f"Expected valid, got: {result.error_message}"


# ── Test 5: Zarządzanie regułami ────────────────────────────────────────


class TestRuleManagement:
    def test_add_rule(self, validator):
        """Add a new validation rule."""
        rule_id = validator.add_rule(
            transaction_type="EXPENSE",
            debit_account_id=999,
            credit_account_id=888,
            amount_sign="POSITIVE",
            priority=50,
        )
        assert rule_id.startswith("ledger_")

        # Verify it appears in list
        rules = validator.list_rules()
        ids = [r["rule_id"] for r in rules]
        assert rule_id in ids

    def test_count_rules(self, validator):
        """Count validation rules."""
        count = validator.count_rules(active_only=False)
        assert count >= 5  # at least the 5 default rules

    def test_custom_rule_works(self, validator):
        """Custom rule should allow the specified pair."""
        validator.add_rule("EXPENSE", 100, 200, amount_sign="ANY")
        transfers = [TransferSpec(100, 200, -500, "custom")]
        result = validator.validate(transfers, "EXPENSE")
        assert result.is_valid


# ── Test 6: Delegacja do invariant guard ────────────────────────────────


class TestInvariantDelegation:
    def test_invariant_failure_reported(self, validator):
        """If positions/summary don't match, validation should fail."""
        transfers = _expense_transfers(10000, 2300)
        positions = [
            InvoicePositions(net_grosze=10000, vat_rate=Decimal("0.23")),
        ]
        summary = InvoiceSummary(
            netto_grosze=10000,
            vat_grosze=9999,  # wrong! should be 2300
            brutto_grosze=19999,
        )
        result = validator.validate(transfers, "EXPENSE", positions=positions, summary=summary)
        assert not result.is_valid
        assert "INVARIANTS" in result.error_message

    def test_no_positions_skips_invariants(self, validator):
        """Without positions/summary, invariant check is skipped."""
        transfers = _expense_transfers(10000, 2300)
        result = validator.validate(transfers, "EXPENSE")
        assert result.is_valid  # should pass without invariant check
