from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads, msgspec_dumps_bytes
"""
Tests for IntegrityVerifier (Element 2 — Weryfikator Integralności).

Covers:
  - verify_all() on intact chain → status='ok'
  - verify_all() on tampered chain → status='violation'
  - handle_violation() persists to integrity_violations
  - system_lock() and is_system_locked()
  - verify_incremental() with checkpoint
  - list_violations() and resolve_violation()
"""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone

import duckdb
import pytest

from nexus_ai.services.integrity_verifier import IntegrityVerifier
from nexus_ai.tax.audit import DecisionTraceLogger, ensure_schema as ensure_audit_schema


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    return c


@pytest.fixture
def logger(conn: duckdb.DuckDBPyConnection) -> DecisionTraceLogger:
    return DecisionTraceLogger(conn)


@pytest.fixture
def verifier(conn: duckdb.DuckDBPyConnection) -> IntegrityVerifier:
    return IntegrityVerifier(conn)


def _log_sample_trace(
    logger: DecisionTraceLogger,
    transaction_id: str | None = None,
    vat_rate: str = "0.23",
) -> str:
    """Helper to log a sample decision trace."""
    return logger.log(
        transaction_id=transaction_id or str(uuid.uuid4()),
        rule_id=str(uuid.uuid4()),
        context={"category_code": "FUEL", "transaction_date": "2024-06-15"},
        verdict={"vat_rate": vat_rate, "rounding_level": "position"},
        decision_trace="Test trace: FUEL 23%",
    )


class TestIntegrityVerifier:
    def test_verify_all_intact(self, conn: duckdb.DuckDBPyConnection, logger: DecisionTraceLogger, verifier: IntegrityVerifier) -> None:
        """Intact chain → status='ok', no violations."""
        _log_sample_trace(logger)
        _log_sample_trace(logger)
        _log_sample_trace(logger)

        report = verifier.verify_all()
        assert report.status == "ok"
        assert report.total_records == 3
        assert report.violations == []

    def test_verify_all_empty(self, verifier: IntegrityVerifier) -> None:
        """Empty table → status='ok'."""
        report = verifier.verify_all()
        assert report.status == "ok"
        assert report.total_records == 0

    def test_verify_all_tampered_verdict(self, conn: duckdb.DuckDBPyConnection, logger: DecisionTraceLogger, verifier: IntegrityVerifier) -> None:
        """Tampered verdict_json → violation detected."""
        tid = str(uuid.uuid4())
        _log_sample_trace(logger, transaction_id=tid, vat_rate="0.23")

        # Tamper: modify the verdict_json for the first entry
        conn.execute(
            "UPDATE decision_traces SET verdict_json = ? WHERE transaction_id = ?",
            (msgspec_dumps({"vat_rate": "0.08", "rounding_level": "position"}), tid),
        )

        report = verifier.verify_all()
        assert report.status == "violation"
        assert len(report.violations) >= 1
        assert report.violations[0]["issue"] in ("current_hash_mismatch", "previous_hash_mismatch")
        assert report.first_inconsistent_trace is not None

    def test_verify_all_tampered_chain_link(self, conn: duckdb.DuckDBPyConnection, logger: DecisionTraceLogger, verifier: IntegrityVerifier) -> None:
        """Broken chain link (previous_hash altered) → violation."""
        _log_sample_trace(logger)
        _log_sample_trace(logger)

        # Tamper: change previous_hash of the second entry
        rows = conn.execute(
            "SELECT trace_id FROM decision_traces ORDER BY timestamp ASC LIMIT 1"
        ).fetchall()
        if rows:
            conn.execute(
                "UPDATE decision_traces SET previous_hash = REPEAT('a', 64) WHERE previous_hash != REPEAT('0', 64) AND trace_id != ?",
                (str(rows[0][0]),),
            )

        report = verifier.verify_all()
        assert report.status == "violation"

    def test_handle_violation_persists(self, conn: duckdb.DuckDBPyConnection, logger: DecisionTraceLogger, verifier: IntegrityVerifier) -> None:
        """handle_violation() saves to integrity_violations table."""
        _log_sample_trace(logger)
        # Tamper
        conn.execute(
            "UPDATE decision_traces SET verdict_json = '{}' WHERE 1=1"
        )

        report = verifier.verify_all()
        assert report.status == "violation"

        violation_id = verifier.handle_violation(report)
        assert violation_id is not None

        # Check it was persisted
        rows = conn.execute(
            "SELECT violation_id, first_inconsistent_trace, expected_hash FROM integrity_violations WHERE violation_id = ?",
            (violation_id,),
        ).fetchall()
        assert len(rows) == 1
        assert str(rows[0][0]) == violation_id

    def test_system_lock(self, verifier: IntegrityVerifier) -> None:
        """system_lock() prevents writes, is_system_locked() reports state."""
        assert not verifier.is_system_locked()

        verifier.system_lock(lock=True)
        assert verifier.is_system_locked()

        verifier.system_lock(lock=False)
        assert not verifier.is_system_locked()

    def test_list_violations(self, conn: duckdb.DuckDBPyConnection, logger: DecisionTraceLogger, verifier: IntegrityVerifier) -> None:
        """list_violations returns all stored violations."""
        _log_sample_trace(logger)
        conn.execute("UPDATE decision_traces SET verdict_json = '{}' WHERE 1=1")
        report = verifier.verify_all()
        verifier.handle_violation(report)

        violations = verifier.list_violations()
        assert len(violations) >= 1
        assert violations[0]["violation_id"] is not None
        assert violations[0]["detected_at"] is not None

    def test_resolve_violation(self, conn: duckdb.DuckDBPyConnection, logger: DecisionTraceLogger, verifier: IntegrityVerifier) -> None:
        """resolve_violation() marks violation as resolved."""
        _log_sample_trace(logger)
        conn.execute("UPDATE decision_traces SET verdict_json = '{}' WHERE 1=1")
        report = verifier.verify_all()
        violation_id = verifier.handle_violation(report)

        resolved = verifier.resolve_violation(violation_id, resolved_by="test")
        assert resolved

        violations = verifier.list_violations(only_open=True)
        assert all(v["resolved_at"] is not None or v["violation_id"] != violation_id for v in violations)

    def test_verify_incremental(self, conn: duckdb.DuckDBPyConnection, logger: DecisionTraceLogger, verifier: IntegrityVerifier) -> None:
        """Incremental verification after checkpoint works."""
        _log_sample_trace(logger)
        _log_sample_trace(logger)

        # First incremental should do full verification and save checkpoint
        report = verifier.verify_incremental()
        assert report.status == "ok"
        assert report.total_records == 2

        # Add more records
        _log_sample_trace(logger)
        _log_sample_trace(logger)

        # Second incremental should only verify new records
        report = verifier.verify_incremental()
        assert report.status == "ok"
        assert report.total_records == 4

    def test_get_latest_checkpoint(self, logger: DecisionTraceLogger, verifier: IntegrityVerifier) -> None:
        """get_latest_checkpoint() returns saved checkpoint."""
        _log_sample_trace(logger)

        verifier.verify_incremental()
        cp = verifier.get_latest_checkpoint()
        assert cp is not None
        assert cp["total_verified"] >= 1
        assert cp["status"] == "ok"

    def test_get_latest_checkpoint_empty(self, verifier: IntegrityVerifier) -> None:
        """No checkpoint → returns None."""
        cp = verifier.get_latest_checkpoint()
        assert cp is None

    def test_violation_handle_requires_violation(self, verifier: IntegrityVerifier) -> None:
        """handle_violation raises on non-violation report."""
        from services.integrity_verifier import IntegrityReport
        report = IntegrityReport(status="ok", total_records=0, violations=[])
        with pytest.raises(ValueError, match="No violations"):
            verifier.handle_violation(report)
