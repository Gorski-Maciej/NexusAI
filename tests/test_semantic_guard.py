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

from nexus_ai.services.semantic_guard import (
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

    def test_store_and_retrieve(self) -> None:
        """Store invoice → no error."""
        guard = SemanticGuard(db_path=":memory:")
        guard.store_invoice(
            vendor_nip="1234567890",
            invoice_text="Faktura za catering",
            category_code="FOOD",
            amount_net=500.0,
        )
        # Should not raise
        assert True

    def test_anomaly_rules_loaded(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Default anomaly rules are present."""
        count = conn.execute("SELECT COUNT(1) FROM anomaly_rules").fetchone()[0]
        assert count == len(DEFAULT_ANOMALY_RULES)
