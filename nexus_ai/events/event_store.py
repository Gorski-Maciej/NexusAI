"""
AsyncEventStore — append-only event store backed by aiosqlite.

Przechowuje zdarzenia w tabeli ``event_stream`` jako append-only log.
ASYNCHRONICZNY — używa aiosqlite zamiast synchronicznego sqlite3.

SUPERMOCE aiosqlite:
- await conn.execute() — async zapytania
- await conn.executescript() — async multi-zapytania
- await cursor.fetchall() — async fetch
- async context manager — async with

Zgodnie z docs/AIOSQLITE_AUDIT.md:
- FAZA 1: Konwersja EventStore z sync sqlite3 na async aiosqlite
- Obsługa SQLCipher przez sync bridge (PRAGMA key)
- Współdzielenie połączenia przez AsyncDBPool

Wspiera:
  - Zapis wielu eventów w jednej transakcji (batch append)
  - Optimistic concurrency (expected_version)
  - Odczyty strumienia dla konkretnego agregatu
  - Snapshoty dla szybkiego odbudowy stanu
  - Checkpointy dla projekcji CQRS
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

import aiosqlite
from structlog import get_logger

from nexus_ai.db.async_db_pool import get_async_db_pool
from nexus_ai.events.domain_events import (
    DomainEvent,
    domain_event_from_dict,
    encode_event,
)

logger = get_logger("nexus.events.store")


class AsyncEventStore:
    """Append-only event store backed by aiosqlite.

    ASYNCHRONICZNY — wszystkie operacje są awaitable.
    Używa AsyncDBPool dla współdzielonego połączenia.

    Args:
        db_path: Ścieżka do pliku SQLite.
    """

    def __init__(self, db_path: str | Path) -> None:
        self._db_path = Path(db_path)
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._pool = get_async_db_pool()
        self._conn: aiosqlite.Connection | None = None

    async def _get_conn(self) -> aiosqlite.Connection:
        """Pobierz async połączenie przez AsyncDBPool z SQLCipher.

        SUPERMOC: Połączenie jest współdzielone między serwisami.
        SQLCipher PRAGMA key ustawiane przy pierwszym połączeniu.
        """
        if self._conn is None or self._conn.is_closed():
            # SUPERMOC: SQLCipher przez sync bridge
            key = os.environ.get("NEXUS_EVENT_STORE_KEY", "") or os.environ.get(
                "NEXUS_SQLCIPHER_KEY", ""
            )
            sqlcipher_key = key if key else None

            self._conn = await self._pool.get_conn(
                str(self._db_path),
                row_factory=aiosqlite.Row,
                sqlcipher_key=sqlcipher_key,
            )
            await self._ensure_schema()
        return self._conn

    async def _ensure_schema(self) -> None:
        """Utwórz schemat EventStore (async)."""
        conn = await self._get_conn()
        await conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS event_stream (
                event_id         TEXT PRIMARY KEY,
                aggregate_type   TEXT NOT NULL,
                aggregate_id     TEXT NOT NULL,
                event_type       TEXT NOT NULL,
                version          INTEGER NOT NULL,
                timestamp        TEXT NOT NULL,
                data             BLOB NOT NULL,
                metadata_json    TEXT NOT NULL DEFAULT '{}',
                created_at       TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE INDEX IF NOT EXISTS idx_events_aggregate
                ON event_stream(aggregate_type, aggregate_id, version);

            CREATE INDEX IF NOT EXISTS idx_events_type
                ON event_stream(event_type, timestamp);

            CREATE INDEX IF NOT EXISTS idx_events_timestamp
                ON event_stream(timestamp);

            CREATE TABLE IF NOT EXISTS snapshots (
                aggregate_id     TEXT NOT NULL,
                aggregate_type   TEXT NOT NULL,
                version          INTEGER NOT NULL,
                state_json       TEXT NOT NULL,
                timestamp        TEXT NOT NULL,
                PRIMARY KEY (aggregate_id, aggregate_type)
            );

            CREATE TABLE IF NOT EXISTS projection_checkpoints (
                projection_name  TEXT PRIMARY KEY,
                last_event_id    TEXT,
                last_version     INTEGER NOT NULL DEFAULT 0,
                updated_at       TEXT NOT NULL
            );
        """
        )
        await conn.commit()

    async def close(self) -> None:
        """Zamknij połączenie."""
        if self._conn is not None:
            try:
                await self._conn.execute("PRAGMA optimize;")
            except Exception:
                pass
            await self._pool.close_conn(str(self._db_path))
            self._conn = None

    # ── Write operations ───────────────────────────────────────────────

    @staticmethod
    def _dbg_trace(
        method: str, aggregate_type: str, aggregate_id: str, version: int | None = None
    ) -> None:
        """Emit OTel span dla operacji EventStore."""
        from nexus_ai.core.otel_tracing import buffer_span

        buffer_span(
            trace_id=aggregate_id,
            name=f"event_store.{method}",
            duration_ms=0,
            attributes={
                "aggregate_type": aggregate_type,
                "aggregate_id": aggregate_id,
                "version": version if version is not None else 0,
            },
        )

    async def append_events(
        self,
        aggregate_type: str,
        aggregate_id: str,
        events: list[DomainEvent],
        expected_version: int | None = None,
    ) -> list[str]:
        """Zapisz eventy do strumienia w jednej transakcji (async).

        Args:
            aggregate_type: Typ agregatu (np. "invoice", "decision").
            aggregate_id: ID agregatu.
            events: Lista eventów do zapisania.
            expected_version: Oczekiwana wersja agregatu (optimistic concurrency).
                              None = pomiń walidację wersji.

        Returns:
            Lista ID zapisanych eventów.

        Raises:
            ValueError: Gdy expected_version nie zgadza się z aktualną wersją.
        """
        conn = await self._get_conn()
        event_ids: list[str] = []

        # SUPERMOC: SAVEPOINT dla zagnieżdżonych transakcji (async)
        await conn.execute("SAVEPOINT event_append;")
        try:
            # Sprawdź optimistic concurrency
            if expected_version is not None:
                cursor = await conn.execute(
                    "SELECT COALESCE(MAX(version), 0) FROM event_stream "
                    "WHERE aggregate_type = ? AND aggregate_id = ?",
                    (aggregate_type, aggregate_id),
                )
                row = await cursor.fetchone()
                current = int(row[0]) if row else 0
                if current != expected_version:
                    await conn.execute("ROLLBACK TO SAVEPOINT event_append;")
                    raise ValueError(
                        f"Optimistic concurrency violation: "
                        f"expected version {expected_version}, "
                        f"current version {current} "
                        f"(aggregate={aggregate_type}:{aggregate_id})"
                    )

            for event in events:
                event_data = encode_event(event)
                metadata_json = json.dumps(event.metadata)
                # SUPERMOC: RETURNING clause (async)
                cursor = await conn.execute(
                    """INSERT INTO event_stream
                       (event_id, aggregate_type, aggregate_id, event_type,
                        version, timestamp, data, metadata_json)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                       RETURNING event_id""",
                    (
                        event.event_id,
                        aggregate_type,
                        aggregate_id,
                        event.event_type,
                        event.version,
                        event.timestamp,
                        event_data,
                        metadata_json,
                    ),
                )
                row = await cursor.fetchone()
                returned_id = str(row[0]) if row else event.event_id
                event_ids.append(returned_id)

            if event_ids:
                logger.info(
                    "[EVENT-STORE] Appended %d events to %s:%s (version=%d)",
                    len(events),
                    aggregate_type,
                    aggregate_id,
                    events[-1].version,
                )

            # SUPERMOC: Release SAVEPOINT (async commit)
            await conn.execute("RELEASE SAVEPOINT event_append;")
        except Exception:
            await conn.execute("ROLLBACK TO SAVEPOINT event_append;")
            raise

        return event_ids

    # ── Read operations ────────────────────────────────────────────────

    async def read_events(
        self,
        aggregate_type: str,
        aggregate_id: str,
        from_version: int = 0,
        to_version: int | None = None,
        limit: int = 1000,
    ) -> list[DomainEvent]:
        """Odczytaj eventy dla konkretnego agregatu (async).

        Args:
            aggregate_type: Typ agregatu.
            aggregate_id: ID agregatu.
            from_version: Minimalna wersja (inkluzywnie).
            to_version: Maksymalna wersja (inkluzywnie). None = bez limitu.
            limit: Maksymalna liczba eventów.

        Returns:
            Lista eventów posortowanych po wersji rosnąco.
        """
        conn = await self._get_conn()
        if to_version is not None:
            cursor = await conn.execute(
                """SELECT data FROM event_stream
                   WHERE aggregate_type = ? AND aggregate_id = ?
                     AND version >= ? AND version <= ?
                   ORDER BY version ASC LIMIT ?""",
                (aggregate_type, aggregate_id, from_version, to_version, limit),
            )
        else:
            cursor = await conn.execute(
                """SELECT data FROM event_stream
                   WHERE aggregate_type = ? AND aggregate_id = ?
                     AND version >= ?
                   ORDER BY version ASC LIMIT ?""",
                (aggregate_type, aggregate_id, from_version, limit),
            )
        rows = await cursor.fetchall()
        return [domain_event_from_dict(json.loads(row[0])) for row in rows]

    async def read_events_by_type(
        self,
        event_type: str,
        since: str | None = None,
        limit: int = 100,
    ) -> list[DomainEvent]:
        """Odczytaj eventy po typie (dla projekcji, async)."""
        conn = await self._get_conn()
        if event_type and since:
            cursor = await conn.execute(
                """SELECT data FROM event_stream
                   WHERE event_type = ? AND timestamp >= ?
                   ORDER BY timestamp ASC LIMIT ?""",
                (event_type, since, limit),
            )
        elif event_type:
            cursor = await conn.execute(
                """SELECT data FROM event_stream
                   WHERE event_type = ?
                   ORDER BY timestamp ASC LIMIT ?""",
                (event_type, limit),
            )
        elif since:
            cursor = await conn.execute(
                """SELECT data FROM event_stream
                   WHERE timestamp >= ?
                   ORDER BY timestamp ASC LIMIT ?""",
                (since, limit),
            )
        else:
            cursor = await conn.execute(
                """SELECT data FROM event_stream
                   ORDER BY timestamp ASC LIMIT ?""",
                (limit,),
            )
        rows = await cursor.fetchall()
        return [domain_event_from_dict(json.loads(row[0])) for row in rows]

    async def read_stream(
        self,
        aggregate_type: str,
        aggregate_id: str,
    ) -> list[DomainEvent]:
        """Odczytaj pełny strumień eventów dla agregatu (async)."""
        return await self.read_events(aggregate_type, aggregate_id, from_version=0)

    async def get_version(self, aggregate_type: str, aggregate_id: str) -> int:
        """Pobierz aktualną wersję agregatu (async)."""
        conn = await self._get_conn()
        cursor = await conn.execute(
            "SELECT COALESCE(MAX(version), 0) FROM event_stream "
            "WHERE aggregate_type = ? AND aggregate_id = ?",
            (aggregate_type, aggregate_id),
        )
        row = await cursor.fetchone()
        return int(row[0]) if row else 0

    async def read_events_since_version(
        self,
        aggregate_type: str,
        from_version: int = 0,
        limit: int = 500,
    ) -> list[DomainEvent]:
        """Odczytaj eventy dla danego typu agregatu od określonej wersji (async).

        Używane przez projekcje CQRS do czytania wszystkich eventów
        danego typu (np. wszystkie invoice.* eventy) od ostatniego
        checkpointu.
        """
        conn = await self._get_conn()
        cursor = await conn.execute(
            """SELECT data FROM event_stream
               WHERE aggregate_type = ? AND version >= ?
               ORDER BY version ASC LIMIT ?""",
            (aggregate_type, from_version, limit),
        )
        rows = await cursor.fetchall()
        return [domain_event_from_dict(json.loads(row[0])) for row in rows]

    async def count_events(
        self,
        aggregate_type: str | None = None,
        event_type: str | None = None,
    ) -> int:
        """Policz eventy (async, opcjonalnie filtrowane)."""
        conn = await self._get_conn()
        if aggregate_type and event_type:
            cursor = await conn.execute(
                "SELECT COUNT(*) FROM event_stream WHERE aggregate_type = ? AND event_type = ?",
                (aggregate_type, event_type),
            )
        elif aggregate_type:
            cursor = await conn.execute(
                "SELECT COUNT(*) FROM event_stream WHERE aggregate_type = ?",
                (aggregate_type,),
            )
        elif event_type:
            cursor = await conn.execute(
                "SELECT COUNT(*) FROM event_stream WHERE event_type = ?",
                (event_type,),
            )
        else:
            cursor = await conn.execute("SELECT COUNT(*) FROM event_stream")
        row = await cursor.fetchone()
        return int(row[0]) if row else 0

    # ── Snapshots ──────────────────────────────────────────────────────

    async def save_snapshot(
        self,
        aggregate_type: str,
        aggregate_id: str,
        version: int,
        state: dict[str, Any],
    ) -> None:
        """Zapisz snapshot stanu agregatu (async).

        SUPERMOC: UPSERT (INSERT ... ON CONFLICT DO UPDATE) przez aiosqlite.
        """
        conn = await self._get_conn()
        await conn.execute(
            """INSERT INTO snapshots
               (aggregate_id, aggregate_type, version, state_json, timestamp)
               VALUES (?, ?, ?, ?, ?)
               ON CONFLICT(aggregate_id, aggregate_type) DO UPDATE SET
                   version = EXCLUDED.version,
                   state_json = EXCLUDED.state_json,
                   timestamp = EXCLUDED.timestamp""",
            (
                aggregate_id,
                aggregate_type,
                version,
                json.dumps(state),
                pendulum_now(),
            ),
        )
        await conn.commit()
        logger.debug(
            "[EVENT-STORE] Snapshot saved for %s:%s (version=%d)",
            aggregate_type,
            aggregate_id,
            version,
        )

    async def load_snapshot(
        self,
        aggregate_type: str,
        aggregate_id: str,
    ) -> tuple[int, dict[str, Any]] | None:
        """Wczytaj snapshot stanu agregatu (async)."""
        conn = await self._get_conn()
        cursor = await conn.execute(
            "SELECT version, state_json FROM snapshots "
            "WHERE aggregate_id = ? AND aggregate_type = ?",
            (aggregate_id, aggregate_type),
        )
        row = await cursor.fetchone()
        if row is None:
            return None
        return int(row[0]), json.loads(row[1])

    # ── Projection checkpoints ─────────────────────────────────────────

    async def get_checkpoint(self, projection_name: str) -> int:
        """Pobierz ostatni wersję checkpoint dla projekcji (async)."""
        conn = await self._get_conn()
        cursor = await conn.execute(
            "SELECT last_version FROM projection_checkpoints WHERE projection_name = ?",
            (projection_name,),
        )
        row = await cursor.fetchone()
        return int(row[0]) if row else 0

    async def update_checkpoint(
        self,
        projection_name: str,
        last_event_id: str,
        last_version: int,
    ) -> None:
        """Zaktualizuj checkpoint dla projekcji (async).

        SUPERMOC: UPSERT przez aiosqlite.
        """
        conn = await self._get_conn()
        await conn.execute(
            """INSERT INTO projection_checkpoints
               (projection_name, last_event_id, last_version, updated_at)
               VALUES (?, ?, ?, ?)
               ON CONFLICT(projection_name) DO UPDATE SET
                   last_event_id = EXCLUDED.last_event_id,
                   last_version = EXCLUDED.last_version,
                   updated_at = EXCLUDED.updated_at""",
            (projection_name, last_event_id, last_version, pendulum_now()),
        )
        await conn.commit()

    async def list_projections(self) -> list[dict[str, Any]]:
        """Zwróć listę wszystkich projekcji z ich checkpointami (async)."""
        conn = await self._get_conn()
        cursor = await conn.execute(
            "SELECT projection_name, last_event_id, last_version, updated_at "
            "FROM projection_checkpoints ORDER BY projection_name"
        )
        rows = await cursor.fetchall()
        return [
            {
                "projection_name": r[0],
                "last_event_id": r[1],
                "last_version": int(r[2]),
                "updated_at": r[3],
            }
            for r in rows
        ]

    # ── Stats ──────────────────────────────────────────────────────────

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki EventStore (async).

        Returns:
            Słownik z liczbą eventów, snapshotów i projekcji.
        """
        conn = await self._get_conn()

        cursor = await conn.execute("SELECT COUNT(*) FROM event_stream")
        row = await cursor.fetchone()
        total_events = int(row[0]) if row else 0

        cursor = await conn.execute("SELECT COUNT(*) FROM snapshots")
        row = await cursor.fetchone()
        total_snapshots = int(row[0]) if row else 0

        cursor = await conn.execute("SELECT COUNT(*) FROM projection_checkpoints")
        row = await cursor.fetchone()
        total_projections = int(row[0]) if row else 0

        cursor = await conn.execute(
            "SELECT aggregate_type, COUNT(DISTINCT aggregate_id) as cnt "
            "FROM event_stream GROUP BY aggregate_type"
        )
        rows = await cursor.fetchall()
        aggregates = {str(r[0]): int(r[1]) for r in rows}

        return {
            "total_events": total_events,
            "total_snapshots": total_snapshots,
            "total_projections": total_projections,
            "aggregates": aggregates,
        }

# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
# Stary EventStore jest teraz AsyncEventStore
# UWAGA: Wszystkie metody są async — callery muszą używać await
EventStore = AsyncEventStore


# ── Helper ────────────────────────────────────────────────────────────────


def pendulum_now() -> str:
    """Zwróć aktualny timestamp ISO 8601."""
    import pendulum

    return pendulum.now("UTC").isoformat()
