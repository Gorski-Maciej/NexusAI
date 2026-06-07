"""
Tests for Fallback Handler (Element 2).

Covers:
  - Handling a no-matching-rule event
  - Resolving an event
  - Ignoring an event
  - Listing events with status filter
  - Counting pending events
  - Convenience handle_no_matching_rule()
"""

from __future__ import annotations

import duckdb
import pytest

from nexus_ai.services.fallback_handler import FallbackHandler, ensure_schema, FALLBACK_EVENTS_SCHEMA
from nexus_ai.tax.exceptions import NoMatchingRuleError


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    c = duckdb.connect(":memory:")
    ensure_schema(c)
    return c


@pytest.fixture
def handler(conn: duckdb.DuckDBPyConnection) -> FallbackHandler:
    return FallbackHandler(conn)


class TestFallbackHandler:
    def test_handle_creates_event(self, handler: FallbackHandler) -> None:
        """handle() creates a PENDING event."""
        event_id = handler.handle(
            transaction_id="tx-001",
            context={"category_code": "UNKNOWN", "vendor_country": "PL"},
            error_details="No rule for UNKNOWN category",
        )
        assert event_id is not None
        assert len(event_id) == 36  # UUID

        # Verify in DB
        row = handler._conn.execute(
            "SELECT status, error_type FROM fallback_events WHERE event_id = ?",
            (event_id,),
        ).fetchone()
        assert str(row[0]) == "PENDING"
        assert str(row[1]) == "NO_MATCHING_RULE"

    def test_handle_without_details_builds_auto(self, handler: FallbackHandler) -> None:
        """When error_details is empty, auto-build from context."""
        event_id = handler.handle(
            transaction_id="tx-002",
            context={"category_code": "UNKNOWN", "vendor_country": "PL", "company_tax_form": "CIT"},
        )
        row = handler._conn.execute(
            "SELECT error_details FROM fallback_events WHERE event_id = ?",
            (event_id,),
        ).fetchone()
        details = str(row[0])
        assert "UNKNOWN" in details
        assert "CIT" in details

    def test_resolve_event(self, handler: FallbackHandler) -> None:
        """resolve() changes status to RESOLVED."""
        event_id = handler.handle(transaction_id="tx-003", context={"cat": "X"})
        ok = handler.resolve(event_id, resolution_note="Added new rule for category X")
        assert ok

        row = handler._conn.execute(
            "SELECT status, resolution_note FROM fallback_events WHERE event_id = ?",
            (event_id,),
        ).fetchone()
        assert str(row[0]) == "RESOLVED"
        assert "Added new rule" in str(row[1])

    def test_resolve_already_resolved(self, handler: FallbackHandler) -> None:
        """Resolving an already-resolved event returns False."""
        event_id = handler.handle(transaction_id="tx-004", context={"cat": "X"})
        handler.resolve(event_id)
        ok = handler.resolve(event_id)
        assert not ok

    def test_ignore_event(self, handler: FallbackHandler) -> None:
        """ignore() changes status to IGNORED."""
        event_id = handler.handle(transaction_id="tx-005", context={"cat": "X"})
        ok = handler.ignore(event_id)
        assert ok

        row = handler._conn.execute(
            "SELECT status FROM fallback_events WHERE event_id = ?",
            (event_id,),
        ).fetchone()
        assert str(row[0]) == "IGNORED"

    def test_list_events_empty(self, handler: FallbackHandler) -> None:
        """No events → empty list."""
        events = handler.list_events()
        assert events == []

    def test_list_events_with_data(self, handler: FallbackHandler) -> None:
        """Events are listed in reverse chronological order."""
        handler.handle(transaction_id="tx-001", context={"cat": "A"})
        handler.handle(transaction_id="tx-002", context={"cat": "B"})
        events = handler.list_events()
        assert len(events) == 2

    def test_list_events_filter_by_status(self, handler: FallbackHandler) -> None:
        """Filter by status returns only matching events."""
        e1 = handler.handle(transaction_id="tx-001", context={"cat": "A"})
        e2 = handler.handle(transaction_id="tx-002", context={"cat": "B"})
        handler.resolve(e1)

        pending = handler.list_events(status_filter="PENDING")
        resolved = handler.list_events(status_filter="RESOLVED")
        assert len(pending) == 1
        assert len(resolved) == 1
        assert pending[0]["event_id"] == e2
        assert resolved[0]["event_id"] == e1

    def test_count_pending(self, handler: FallbackHandler) -> None:
        """count_pending returns correct number."""
        assert handler.count_pending() == 0
        handler.handle(transaction_id="tx-001", context={"cat": "A"})
        assert handler.count_pending() == 1
        handler.handle(transaction_id="tx-002", context={"cat": "B"})
        assert handler.count_pending() == 2

    def test_handle_no_matching_rule(self, handler: FallbackHandler) -> None:
        """Convenience method extracts error details from exception."""
        error = NoMatchingRuleError("No rule for category UNKNOWN")
        event_id = handler.handle_no_matching_rule(
            transaction_id="tx-010",
            context={"category_code": "UNKNOWN"},
            error=error,
        )
        row = handler._conn.execute(
            "SELECT error_type, error_details FROM fallback_events WHERE event_id = ?",
            (event_id,),
        ).fetchone()
        assert str(row[0]) == "NO_MATCHING_RULE"
        assert "UNKNOWN" in str(row[1])
