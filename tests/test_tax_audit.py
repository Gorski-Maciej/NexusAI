"""
Tests for Part III — Audit and Decision Trace Chain.

Covers:
  - DecisionTraceLogger basic logging
  - Hash chain integrity (previous_hash linking)
  - Hash recomputation verification
  - verify_chain_integrity on intact vs tampered data
  - get_trace retrieval
"""

from __future__ import annotations

import hashlib
import json

import duckdb
import pytest

from nexus_ai.tax.audit import (
    DecisionTraceLogger,
    ensure_schema,
    verify_chain_integrity,
    _compute_current_hash,
    _GENESIS_HASH,
)


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    ensure_schema(c)
    return c


@pytest.fixture
def logger(conn: duckdb.DuckDBPyConnection) -> DecisionTraceLogger:
    return DecisionTraceLogger(conn)


# ── Basic logging ────────────────────────────────────────────────────────────


class TestDecisionTraceLogger:
    def test_log_basic(self, logger: DecisionTraceLogger) -> None:
        """Basic log creates a trace entry."""
        trace_id = logger.log(
            transaction_id="tx-001",
            context={"category_code": "FUEL"},
            verdict={"vat_rate": "0.23"},
        )
        assert trace_id is not None
        assert len(trace_id) == 36  # UUID

    def test_log_sets_correct_previous_hash(self, logger: DecisionTraceLogger) -> None:
        """First entry has genesis hash, second links to first."""
        t1 = logger.log(
            transaction_id="tx-001",
            context={"a": "1"},
        )
        # Read back t1's current_hash
        row1 = logger._conn.execute(
            "SELECT current_hash FROM decision_traces WHERE trace_id = ?",
            (t1,)
        ).fetchone()
        hash1 = str(row1[0])

        # Second entry
        t2 = logger.log(
            transaction_id="tx-002",
            context={"b": "2"},
        )
        row2 = logger._conn.execute(
            "SELECT previous_hash FROM decision_traces WHERE trace_id = ?",
            (t2,)
        ).fetchone()
        assert str(row2[0]) == hash1, "Second entry must link to first entry's hash"

    def test_log_with_all_fields(self, logger: DecisionTraceLogger) -> None:
        """Log with all optional fields including risk_verdict."""
        trace_id = logger.log(
            transaction_id="tx-full",
            rule_id="rule-abc",
            context={"cat": "FUEL", "date": "2025-06-01"},
            verdict={"vat_rate": "0.23", "rounding_level": "position"},
            calculation_input='{"net": 10000}',
            calculation_output='{"vat": 2300, "brutto": 12300}',
            invariants_result='{"is_valid": true}',
            risk_verdict='{"action": "BLOCK_AND_ALERT", "field": "vat_rate", "required_confidence": 0.98}',
        )
        assert trace_id is not None

        # Verify all data stored including risk_verdict
        row = logger._conn.execute(
            "SELECT transaction_id, rule_id, context_json, verdict_json, "
            "calculation_input, calculation_output, invariants_result, risk_verdict "
            "FROM decision_traces WHERE trace_id = ?",
            (trace_id,),
        ).fetchone()
        assert str(row[0]) == "tx-full"
        assert str(row[1]) == "rule-abc"
        assert "FUEL" in str(row[2])
        assert "0.23" in str(row[3])
        assert "BLOCK_AND_ALERT" in str(row[7])

    def test_genesis_hash(self, logger: DecisionTraceLogger) -> None:
        """First entry's previous_hash must be the genesis constant."""
        trace_id = logger.log(
            transaction_id="tx-first",
            context={"msg": "hello"},
        )
        row = logger._conn.execute(
            "SELECT previous_hash FROM decision_traces WHERE trace_id = ?",
            (trace_id,),
        ).fetchone()
        assert str(row[0]) == _GENESIS_HASH

    def test_latest_hash_empty(self, logger: DecisionTraceLogger) -> None:
        """latest_hash returns genesis on empty table."""
        assert logger.latest_hash() == _GENESIS_HASH

    def test_latest_hash_after_log(self, logger: DecisionTraceLogger) -> None:
        """latest_hash returns the most recent entry's hash."""
        logger.log(transaction_id="tx-1")
        h1 = logger.latest_hash()
        assert h1 != _GENESIS_HASH
        assert len(h1) == 64  # SHA-256 hex

        logger.log(transaction_id="tx-2")
        h2 = logger.latest_hash()
        assert h2 != h1  # Different hash for different content


# ── Hash computation ─────────────────────────────────────────────────────────


class TestHashComputation:
    def test_compute_current_hash_deterministic(self) -> None:
        """Same inputs produce same hash."""
        h1 = _compute_current_hash(
            previous_hash=_GENESIS_HASH,
            trace_id="t1",
            transaction_id="tx1",
            context_json='{"a": "1"}',
            verdict_json='{"v": "0.23"}',
            timestamp_iso="2025-06-01T12:00:00+00:00",
        )
        h2 = _compute_current_hash(
            previous_hash=_GENESIS_HASH,
            trace_id="t1",
            transaction_id="tx1",
            context_json='{"a": "1"}',
            verdict_json='{"v": "0.23"}',
            timestamp_iso="2025-06-01T12:00:00+00:00",
        )
        assert h1 == h2
        assert len(h1) == 64

    def test_hash_changes_with_input(self) -> None:
        """Different inputs produce different hashes."""
        h1 = _compute_current_hash(
            previous_hash=_GENESIS_HASH,
            trace_id="t1",
            transaction_id="tx1",
            context_json="{}",
            verdict_json="{}",
            timestamp_iso="2025-06-01T12:00:00+00:00",
        )
        h2 = _compute_current_hash(
            previous_hash=_GENESIS_HASH,
            trace_id="t2",  # Different
            transaction_id="tx1",
            context_json="{}",
            verdict_json="{}",
            timestamp_iso="2025-06-01T12:00:00+00:00",
        )
        assert h1 != h2


# ── Chain integrity verification ─────────────────────────────────────────────


class TestChainIntegrity:
    def test_empty_chain_is_intact(self, conn: duckdb.DuckDBPyConnection) -> None:
        """Empty chain has no issues."""
        issues = verify_chain_integrity(conn)
        assert issues == []

    def test_single_entry_chain_is_intact(self, logger: DecisionTraceLogger) -> None:
        """Single entry chain passes verification."""
        logger.log(transaction_id="tx-1")
        issues = verify_chain_integrity(logger._conn)
        assert issues == []

    def test_multi_entry_chain_is_intact(self, logger: DecisionTraceLogger) -> None:
        """Chain with multiple entries passes verification."""
        for i in range(5):
            logger.log(
                transaction_id=f"tx-{i}",
                context={"index": i},
                verdict={"rate": "0.23"},
            )
        issues = verify_chain_integrity(logger._conn)
        assert issues == []

    def test_tampered_hash_detected(self, logger: DecisionTraceLogger) -> None:
        """Manual modification of a hash is detected."""
        logger.log(transaction_id="tx-1", context={"a": "1"})
        logger.log(transaction_id="tx-2", context={"b": "2"})

        # Tamper with the first entry's current_hash
        logger._conn.execute(
            "UPDATE decision_traces SET current_hash = 'tampered' "
            "WHERE transaction_id = 'tx-1'"
        )

        issues = verify_chain_integrity(logger._conn)
        assert len(issues) >= 1
        assert any(i["issue"] == "current_hash_mismatch" for i in issues)

    def test_tampered_previous_hash_detected(self, logger: DecisionTraceLogger) -> None:
        """Breaking the hash chain linkage is detected."""
        logger.log(transaction_id="tx-1")
        logger.log(transaction_id="tx-2")

        # Change the second entry's previous_hash
        logger._conn.execute(
            "UPDATE decision_traces SET previous_hash = 'bad' "
            "WHERE transaction_id = 'tx-2'"
        )

        issues = verify_chain_integrity(logger._conn)
        assert len(issues) >= 1
        assert any(i["issue"] == "previous_hash_mismatch" for i in issues)

    def test_tampered_context_detected(self, logger: DecisionTraceLogger) -> None:
        """Changing context data breaks the hash."""
        logger.log(transaction_id="tx-1", context={"amount": "100"})

        # Change the stored context
        logger._conn.execute(
            "UPDATE decision_traces SET context_json = '{\"amount\": \"999\"}' "
            "WHERE transaction_id = 'tx-1'"
        )

        issues = verify_chain_integrity(logger._conn)
        assert len(issues) == 1
        assert issues[0]["issue"] == "current_hash_mismatch"


# ── Trace retrieval ──────────────────────────────────────────────────────────


class TestTraceRetrieval:
    def test_get_trace_returns_logged_data(self, logger: DecisionTraceLogger) -> None:
        """get_trace returns the correct data structure."""
        logger.log(
            transaction_id="tx-get",
            rule_id="rule-1",
            context={"cat": "FUEL"},
            verdict={"vat_rate": "0.23"},
        )
        traces = logger.get_trace("tx-get")
        assert len(traces) == 1
        trace = traces[0]
        assert trace["transaction_id"] == "tx-get"
        assert trace["rule_id"] == "rule-1"
        assert trace["context"]["cat"] == "FUEL"
        assert trace["verdict"]["vat_rate"] == "0.23"
        assert len(trace["current_hash"]) == 64

    def test_get_trace_empty(self, logger: DecisionTraceLogger) -> None:
        """get_trace for unknown transaction returns empty list."""
        traces = logger.get_trace("nonexistent")
        assert traces == []

    def test_get_trace_multiple_entries(self, logger: DecisionTraceLogger) -> None:
        """Multiple traces for same transaction returned in order."""
        logger.log(transaction_id="tx-multi", context={"step": 1})
        logger.log(transaction_id="tx-multi", context={"step": 2})
        logger.log(transaction_id="tx-multi", context={"step": 3})

        traces = logger.get_trace("tx-multi")
        assert len(traces) == 3
        # Ordered by timestamp ASC
        assert traces[0]["context"]["step"] == 1
        assert traces[1]["context"]["step"] == 2
        assert traces[2]["context"]["step"] == 3
