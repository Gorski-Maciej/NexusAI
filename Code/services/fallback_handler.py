"""
Fallback Handler — obsługa sytuacji, gdy żadna reguła nie pasuje do kontekstu.

Element 2 z dokumentu: bezpieczne zachowanie systemu w sytuacjach
nieprzewidzianych (brak reguły).

Zadania:
  1. Zablokowanie transakcji — faktura nie przechodzi do dalszych etapów.
  2. Zapisanie incydentu — w tabeli fallback_events.
  3. Powiadomienie — alert do księgowego.
  4. Kierowanie do ręcznej kolejki — faktura czeka na ręczną interwencję.
"""

from __future__ import annotations

import logging
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

import duckdb

from core.msgspec_utils import msgspec_dumps, msgspec_loads

logger = logging.getLogger("nexus.fallback")


# ── Schema ───────────────────────────────────────────────────────────────────

FALLBACK_EVENTS_SCHEMA = """
CREATE TABLE IF NOT EXISTS fallback_events (
    event_id         VARCHAR PRIMARY KEY,
    transaction_id   VARCHAR NOT NULL,
    context_snapshot VARCHAR NOT NULL,
    error_type       VARCHAR NOT NULL,
    error_details    VARCHAR,
    status           VARCHAR NOT NULL DEFAULT 'PENDING',
    assigned_to      VARCHAR,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at      TIMESTAMP,
    resolution_note  VARCHAR
);
CREATE INDEX IF NOT EXISTS idx_fallback_status
    ON fallback_events(status);
CREATE INDEX IF NOT EXISTS idx_fallback_tx
    ON fallback_events(transaction_id);
"""


@dataclass
class FallbackEvent:
    """Incydent braku reguły.

    Attributes:
        event_id: UUID zdarzenia.
        transaction_id: UUID faktury.
        context_snapshot: JSON kontekstu, który nie pasował do żadnej reguły.
        error_type: Typ błędu (NO_MATCHING_RULE, SQL_ERROR, TIMEOUT).
        error_details: Szczegóły błędu.
        status: PENDING, RESOLVED, IGNORED.
        assigned_to: Kto zajął się ręcznie.
        created_at: Data wystąpienia.
        resolved_at: Data rozwiązania.
        resolution_note: Notatka o rozwiązaniu.
    """
    event_id: str
    transaction_id: str
    context_snapshot: str
    error_type: str
    error_details: str = ""
    status: str = "PENDING"
    assigned_to: str = ""
    created_at: str = ""
    resolved_at: str = ""
    resolution_note: str = ""


def ensure_schema(conn: duckdb.DuckDBPyConnection) -> None:
    """Create fallback_events table if not present."""
    conn.execute(FALLBACK_EVENTS_SCHEMA)


# ── Fallback Handler ────────────────────────────────────────────────────────


class FallbackHandler:
    """Handler for no-matching-rule situations.

    Args:
        conn: DuckDB connection z tabelą fallback_events.
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        ensure_schema(conn)

    def handle(
        self,
        transaction_id: str,
        context: dict[str, Any],
        error_type: str = "NO_MATCHING_RULE",
        error_details: str = "",
    ) -> str:
        """Handle a fallback event — block transaction and log incident.

        Args:
            transaction_id: UUID faktury.
            context: Kontekst, który nie pasował do żadnej reguły.
            error_type: Typ błędu.
            error_details: Szczegóły błędu.

        Returns:
            event_id utworzonego zdarzenia.
        """
        event_id = str(uuid.uuid4())
        now = datetime.now(UTC).isoformat()

        context_json = msgspec_dumps(context, ensure_ascii=False, sort_keys=True, default=str)

        if not error_details:
            # Build a meaningful error detail from context
            error_details = (
                f"No matching rule for category_code='{context.get('category_code', '?')}', "
                f"vendor_country='{context.get('vendor_country', '?')}', "
                f"company_tax_form='{context.get('company_tax_form', '?')}'"
            )

        self._conn.execute(
            """INSERT INTO fallback_events
               (event_id, transaction_id, context_snapshot, error_type,
                error_details, status, created_at)
               VALUES (?, ?, ?, ?, ?, 'PENDING', ?)""",
            (event_id, transaction_id, context_json, error_type, error_details, now),
        )

        logger.warning(
            "[FALLBACK] event=%s transaction=%s type=%s details=%s",
            event_id, transaction_id, error_type, error_details,
        )

        return event_id

    def resolve(
        self,
        event_id: str,
        resolution_note: str = "",
        assigned_to: str = "system",
    ) -> bool:
        """Mark a fallback event as resolved.

        Args:
            event_id: UUID zdarzenia do rozwiązania.
            resolution_note: Notatka o rozwiązaniu.
            assigned_to: Kto rozwiązał.

        Returns:
            True jeśli znaleziono i rozwiązano.
        """
        # DuckDB rowcount is unreliable for UPDATE, so check first
        row = self._conn.execute(
            "SELECT status FROM fallback_events WHERE event_id = ?",
            (event_id,),
        ).fetchone()
        if not row or str(row[0]) != "PENDING":
            return False

        now = datetime.now(UTC).isoformat()
        self._conn.execute(
            """UPDATE fallback_events
               SET status = 'RESOLVED', resolved_at = ?, resolution_note = ?, assigned_to = ?
               WHERE event_id = ? AND status = 'PENDING'""",
            (now, resolution_note, assigned_to, event_id),
        )
        logger.info("[FALLBACK] Resolved event=%s by=%s", event_id, assigned_to)
        return True

    def ignore(self, event_id: str, assigned_to: str = "system") -> bool:
        """Mark a fallback event as ignored (no action needed)."""
        row = self._conn.execute(
            "SELECT status FROM fallback_events WHERE event_id = ?",
            (event_id,),
        ).fetchone()
        if not row or str(row[0]) != "PENDING":
            return False

        now = datetime.now(UTC).isoformat()
        self._conn.execute(
            """UPDATE fallback_events
               SET status = 'IGNORED', resolved_at = ?, assigned_to = ?
               WHERE event_id = ? AND status = 'PENDING'""",
            (now, assigned_to, event_id),
        )
        return True

    def list_events(
        self,
        status_filter: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> list[dict[str, Any]]:
        """List fallback events with optional status filter.

        Args:
            status_filter: PENDING, RESOLVED, IGNORED, or None for all.
            limit: Max results.
            offset: Pagination offset.

        Returns:
            List of event dicts.
        """
        if status_filter:
            rows = self._conn.execute(
                """SELECT event_id, transaction_id, context_snapshot, error_type,
                          error_details, status, assigned_to, created_at, resolved_at, resolution_note
                   FROM fallback_events
                   WHERE status = ?
                   ORDER BY created_at DESC
                   LIMIT ? OFFSET ?""",
                (status_filter, limit, offset),
            ).fetchall()
        else:
            rows = self._conn.execute(
                """SELECT event_id, transaction_id, context_snapshot, error_type,
                          error_details, status, assigned_to, created_at, resolved_at, resolution_note
                   FROM fallback_events
                   ORDER BY created_at DESC
                   LIMIT ? OFFSET ?""",
                (limit, offset),
            ).fetchall()

        return [
            {
                "event_id": str(r[0]),
                "transaction_id": str(r[1]),
                "context": msgspec_loads(r[2]) if r[2] else {},
                "error_type": str(r[3]),
                "error_details": str(r[4]),
                "status": str(r[5]),
                "assigned_to": str(r[6]) if r[6] else "",
                "created_at": str(r[7]),
                "resolved_at": str(r[8]) if r[8] else None,
                "resolution_note": str(r[9]) if r[9] else "",
            }
            for r in rows
        ]

    def count_pending(self) -> int:
        """Return number of pending (unresolved) fallback events."""
        row = self._conn.execute(
            "SELECT COUNT(1) FROM fallback_events WHERE status = 'PENDING'"
        ).fetchone()
        return int(row[0]) if row else 0

    def handle_no_matching_rule(
        self,
        transaction_id: str,
        context: dict[str, Any],
        error: Exception,
    ) -> str:
        """Convenience method — handle a NoMatchingRuleError.

        Extracts details from the exception and delegates to handle().

        Args:
            transaction_id: UUID faktury.
            context: Kontekst, który nie pasował.
            error: Wyjątek NoMatchingRuleError.

        Returns:
            event_id utworzonego zdarzenia.
        """
        return self.handle(
            transaction_id=transaction_id,
            context=context,
            error_type="NO_MATCHING_RULE",
            error_details=str(error),
        )
