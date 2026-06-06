"""
Tests for Part VI — SemanticGuard.

Covers:
  - evaluate with no history
  - evaluate with similar history (low anomaly)
  - anomaly_rules integration
  - store_invoice
"""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone

import duckdb
import pytest

from services.semantic_guard import (
    SemanticGuard,
    ANOMALY_RULES_SCHEMA,
    DEFAULT_ANOMALY_RULES,
)


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    c.execute(ANOMALY_RULES_SCHEMA)
    for rule in DEFAULT_ANOMALY_RULES:
        c.execute(
            """INSERT INTO anomaly_rules (rule_id, condition_json, action_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (
                str(uuid.uuid4()),
                rule["condition_json"],
                rule["action_json"],
                rule["valid_from"],
                rule.get("valid_to"),
                rule["priority"],
            ),
        )
    return c


class TestSemanticGuard:
    def test_evaluate_no_history(self) -> None:
        """New vendor → anomaly_score = 0 (ALLOW)."""
        guard = SemanticGuard(db_path=":memory:")
        result = guard.evaluate(
            invoice_text="Faktura VAT za usługi IT",
            vendor_nip="1234567890",
            amount_net=1000.0,
        )
        assert result["action"] == "ALLOW"
        assert result["anomaly_score"] == 0.0

    def test_evaluate_with_rules(self, conn: duckdb.DuckDBPyConnection) -> None:
        """With anomaly_rules, a new vendor gets ALLOW (score = 0)."""
        guard = SemanticGuard(db_path=":memory:", conn=conn)
        result = guard.evaluate(
            invoice_text="Faktura VAT za usługi IT",
            vendor_nip="1234567890",
            amount_net=1000.0,
        )
        # No history → score = 0 → no rule triggers
        assert result["action"] == "ALLOW"

    def test_store_and_retrieve(self, tmp_path) -> None:
        """Store invoice and verify the persisted row can be retrieved."""
        db_path = tmp_path / "semantic_guard.db"
        guard = SemanticGuard(db_path=str(db_path))
        guard.store_invoice(
            vendor_nip="1234567890",
            invoice_text="Faktura za catering",
            category_code="FOOD",
            amount_net=500.0,
            transaction_id="tx-123",
        )

        conn = guard._init_store()._get_conn()
        row = conn.execute(
            """SELECT vendor_nip, invoice_text, category_code, amount_net, transaction_id
               FROM vendor_invoices
               WHERE transaction_id = ?""",
            ("tx-123",),
        ).fetchone()

        assert row is not None
        assert dict(row) == {
            "vendor_nip": "1234567890",
            "invoice_text": "Faktura za catering",
            "category_code": "FOOD",
            "amount_net": 500.0,
            "transaction_id": "tx-123",
        }

    def test_anomaly_rules_loaded(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Default anomaly rules are present."""
        count = conn.execute("SELECT COUNT(1) FROM anomaly_rules").fetchone()[0]
        assert count == len(DEFAULT_ANOMALY_RULES)
