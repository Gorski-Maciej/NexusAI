"""
AsyncEventStore — append-only event store backed by sqlite3.

Przechowuje zdarzenia w tabeli ``event_stream`` jako append-only log.
Python 3.13t (free-threaded): używamy natywnego sqlite3 + asyncio.to_thread.

Zgodnie z decyzją architektoniczną: rezygnujemy z aiosqlite na rzecz
natywnego sqlite3 + asyncio.to_thread (free-threaded Python 3.13t).

Wspiera:
  - Zapis wielu eventów w jednej transakcji (batch append)
  - Optimistic concurrency (expected_version)
  - Odczyty strumienia dla konkretnego agregatu
  - Snapshoty dla szybkiego odbudowy stanu
  - Checkpointy dla projekcji CQRS
"""

from __future__ import annotations

import asyncio
import json
import os
import sqlite3
from pathlib import Path
from typing import Any

from structlog import get_logger

from nexus_ai.db.async_db_pool import get_async_db_pool
from nexus_ai.events.domain_events import (
    DomainEvent,
    decode_event,
    encode_event,
)

logger = get_logger("nexus.events.store")


class AsyncEventStore:
    """Append-only event store backed by sqlite3 (sync + asyncio.to_thread).

    Python 3.13t (free-threaded): wszystkie operacje sqlite3 wykonujemy
    w wątku przez ``asyncio.to_thread()``.

    Używa AsyncDBPool dla współdzielonego połączenia.

    Args:
        db_path: Ścieżka do pliku SQLite.
    """

    def __init__(self, db_path: str | Path) -> None:
        self._db_path = Path(db_path)
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._pool = get_async_db_pool()
        self._conn: sqlite3.Connection | None = None

    async def _get_conn(self) -> sqlite3.Connection:
        """Pobierz sync połączenie przez AsyncDBPool (w wątku).

        SQLCipher PRAGMA key ustawiane przy pierwszym połączeniu.
        """
        if self._conn is None:
            key = os.environ.get("NEXUS_EVENT_STORE_KEY", "") or os.environ.get(
                "NEXUS_SQLCIPHER_KEY", ""
            )
            sqlcipher_key = key if key else None

            self._conn = await asyncio.to_thread(
                self._pool.get_conn,
                str(self._db_path),
                row_factory=sqlite3.Row,
                sqlcipher_key=sqlcipher_key,
            )
            await self._ensure_schema()
        return self._conn

    async def _ensure_schema(self) -> None:
        """Utwórz schemat EventStore (w wątku)."""
        conn = await self._get_conn()

        def _sync() -> None:
            conn.executescript(
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
            conn.commit()

        await asyncio.to_thread(_sync)

    async def close(self) -> None:
        """Zamknij połączenie."""
        if self._conn is not None:
            try:
                def _optimize() -> None:
                    try:
                        self._conn.execute("PRAGMA optimize;")
                    except Exception:
                        pass
                await asyncio.to_thread(_optimize)
            except Exception:
                pass
            await asyncio.to_thread(self._pool.close_conn, str(self._db_path))
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
        """Zapisz eventy do strumienia w jednej transakcji (async, w wątku).

        Args:
            aggregate_type: Typ agregatu (np. "invoice", "decision").
            aggregate_id: ID agregatu.
            events: Lista eventów do zapisania.
            expected_version: Oczekiwana wersja agregatu (optimistic concurrency).

        Returns:
            Lista ID zapisanych eventów.

        Raises:
            ValueError: Gdy expected_version nie zgadza się z aktualną wersją.
        """
        conn = await self._get_conn()

        def _sync_append() -> list[str]:
            event_ids: list[str] = []

            conn.execute("SAVEPOINT event_append;")
            try:
                if expected_version is not None:
                    cursor = conn.execute(
                        "SELECT COALESCE(MAX(version), 0) FROM event_stream "
                        "WHERE aggregate_type = ? AND aggregate_id = ?",
                        (aggregate_type, aggregate_id),
                    )
                    row = cursor.fetchone()
                    current = int(row[0]) if row else 0
                    if current != expected_version:
                        conn.execute("ROLLBACK TO SAVEPOINT event_append;")
                        raise ValueError(
                            f"Optimistic concurrency violation: "
                            f"expected version {expected_version}, "
                            f"current version {current} "
                            f"(aggregate={aggregate_type}:{aggregate_id})"
                        )

                for event in events:
                    event_data = encode_event(event)
                    metadata_json = json.dumps(event.metadata)
                    cursor = conn.execute(
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
                    row = cursor.fetchone()
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

                conn.execute("RELEASE SAVEPOINT event_append;")
            except Exception:
                conn.execute("ROLLBACK TO SAVEPOINT event_append;")
                raise

            return event_ids

        return await asyncio.to_thread(_sync_append)

    # ── Read operations ────────────────────────────────────────────────

    async def read_events(
        self,
        aggregate_type: str,
        aggregate_id: str,
        from_version: int = 0,
        to_version: int | None = None,
        limit: int = 1000,
    ) -> list[DomainEvent]:
        """Odczytaj eventy dla konkretnego agregatu (async, w wątku)."""
        conn = await self._get_conn()

        def _sync() -> list[DomainEvent]:
            if to_version is not None:
                cursor = conn.execute(
                    """SELECT data FROM event_stream
                       WHERE aggregate_type = ? AND aggregate_id = ?
                         AND version >= ? AND version <= ?
                       ORDER BY version ASC LIMIT ?""",
                    (aggregate_type, aggregate_id, from_version, to_version, limit),
                )
            else:
                cursor = conn.execute(
                    """SELECT data FROM event_stream
                       WHERE aggregate_type = ? AND aggregate_id = ?
                         AND version >= ?
                       ORDER BY version ASC LIMIT ?""",
                    (aggregate_type, aggregate_id, from_version, limit),
                )
            rows = cursor.fetchall()
            # SUPERMOC: msgspec.msgpack.decode z Tagged Unions zamiast json.loads + domain_event_from_dict
            return [decode_event(row[0]) for row in rows]

        return await asyncio.to_thread(_sync)

    async def read_events_by_type(
        self,
        event_type: str | None = None,
        since: str | None = None,
        limit: int = 100,
    ) -> list[DomainEvent]:
        """Odczytaj eventy po typie (dla projekcji, async, w wątku)."""
        conn = await self._get_conn()

        def _sync() -> list[DomainEvent]:
            if event_type and since:
                cursor = conn.execute(
                    """SELECT data FROM event_stream
                       WHERE event_type = ? AND timestamp >= ?
                       ORDER BY timestamp ASC LIMIT ?""",
                    (event_type, since, limit),
                )
            elif event_type:
                cursor = conn.execute(
                    """SELECT data FROM event_stream
                       WHERE event_type = ?
                       ORDER BY timestamp ASC LIMIT ?""",
                    (event_type, limit),
                )
            elif since:
                cursor = conn.execute(
                    """SELECT data FROM event_stream
                       WHERE timestamp >= ?
                       ORDER BY timestamp ASC LIMIT ?""",
                    (since, limit),
                )
            else:
                cursor = conn.execute(
                    """SELECT data FROM event_stream
                       ORDER BY timestamp ASC LIMIT ?""",
                    (limit,),
                )
            rows = cursor.fetchall()
            # SUPERMOC: msgspec.msgpack.decode z Tagged Unions
            return [decode_event(row[0]) for row in rows]

        return await asyncio.to_thread(_sync)

    async def read_stream(
        self,
        aggregate_type: str,
        aggregate_id: str,
    ) -> list[DomainEvent]:
        """Odczytaj pełny strumień eventów dla agregatu (async)."""
        return await self.read_events(aggregate_type, aggregate_id, from_version=0)

    async def get_version(self, aggregate_type: str, aggregate_id: str) -> int:
        """Pobierz aktualną wersję agregatu (async, w wątku)."""
        conn = await self._get_conn()

        def _sync() -> int:
            cursor = conn.execute(
                "SELECT COALESCE(MAX(version), 0) FROM event_stream "
                "WHERE aggregate_type = ? AND aggregate_id = ?",
                (aggregate_type, aggregate_id),
            )
            row = cursor.fetchone()
            return int(row[0]) if row else 0

        return await asyncio.to_thread(_sync)

    async def read_events_since_version(
        self,
        aggregate_type: str,
        from_version: int = 0,
        limit: int = 500,
    ) -> list[DomainEvent]:
        """Odczytaj eventy dla danego typu agregatu od wersji (async, w wątku)."""
        conn = await self._get_conn()

        def _sync() -> list[DomainEvent]:
            cursor = conn.execute(
                """SELECT data FROM event_stream
                   WHERE aggregate_type = ? AND version >= ?
                   ORDER BY version ASC LIMIT ?""",
                (aggregate_type, from_version, limit),
            )
            rows = cursor.fetchall()
            # SUPERMOC: msgspec.msgpack.decode z Tagged Unions
            return [decode_event(row[0]) for row in rows]

        return await asyncio.to_thread(_sync)

    async def count_events(
        self,
        aggregate_type: str | None = None,
        event_type: str | None = None,
    ) -> int:
        """Policz eventy (async, w wątku)."""
        conn = await self._get_conn()

        def _sync() -> int:
            if aggregate_type and event_type:
                cursor = conn.execute(
                    "SELECT COUNT(*) FROM event_stream WHERE aggregate_type = ? AND event_type = ?",
                    (aggregate_type, event_type),
                )
            elif aggregate_type:
                cursor = conn.execute(
                    "SELECT COUNT(*) FROM event_stream WHERE aggregate_type = ?",
                    (aggregate_type,),
                )
            elif event_type:
                cursor = conn.execute(
                    "SELECT COUNT(*) FROM event_stream WHERE event_type = ?",
                    (event_type,),
                )
            else:
                cursor = conn.execute("SELECT COUNT(*) FROM event_stream")
            row = cursor.fetchone()
            return int(row[0]) if row else 0

        return await asyncio.to_thread(_sync)

    # ── Snapshots ──────────────────────────────────────────────────────

    async def save_snapshot(
        self,
        aggregate_type: str,
        aggregate_id: str,
        version: int,
        state: dict[str, Any],
    ) -> None:
        """Zapisz snapshot stanu agregatu (async, w wątku).

        SUPERMOC: UPSERT (INSERT ... ON CONFLICT DO UPDATE).
        """
        conn = await self._get_conn()

        def _sync() -> None:
            conn.execute(
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
            conn.commit()

        await asyncio.to_thread(_sync)
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
        """Wczytaj snapshot stanu agregatu (async, w wątku)."""
        conn = await self._get_conn()

        def _sync() -> tuple[int, dict[str, Any]] | None:
            cursor = conn.execute(
                "SELECT version, state_json FROM snapshots "
                "WHERE aggregate_id = ? AND aggregate_type = ?",
                (aggregate_id, aggregate_type),
            )
            row = cursor.fetchone()
            if row is None:
                return None
            # SUPERMOC: msgspec.json.decode zamiast json.loads dla snapshotów
            return int(row[0]), msgspec.json.decode(row[1])

        return await asyncio.to_thread(_sync)

    # ── Projection checkpoints ─────────────────────────────────────────

    async def get_checkpoint(self, projection_name: str) -> int:
        """Pobierz ostatni wersję checkpoint dla projekcji (async, w wątku)."""
        conn = await self._get_conn()

        def _sync() -> int:
            cursor = conn.execute(
                "SELECT last_version FROM projection_checkpoints WHERE projection_name = ?",
                (projection_name,),
            )
            row = cursor.fetchone()
            return int(row[0]) if row else 0

        return await asyncio.to_thread(_sync)

    async def update_checkpoint(
        self,
        projection_name: str,
        last_event_id: str,
        last_version: int,
    ) -> None:
        """Zaktualizuj checkpoint dla projekcji (async, w wątku)."""
        conn = await self._get_conn()

        def _sync() -> None:
            conn.execute(
                """INSERT INTO projection_checkpoints
                   (projection_name, last_event_id, last_version, updated_at)
                   VALUES (?, ?, ?, ?)
                   ON CONFLICT(projection_name) DO UPDATE SET
                       last_event_id = EXCLUDED.last_event_id,
                       last_version = EXCLUDED.last_version,
                       updated_at = EXCLUDED.updated_at""",
                (projection_name, last_event_id, last_version, pendulum_now()),
            )
            conn.commit()

        await asyncio.to_thread(_sync)

    async def list_projections(self) -> list[dict[str, Any]]:
        """Zwróć listę wszystkich projekcji z checkpointami (async, w wątku)."""
        conn = await self._get_conn()

        def _sync() -> list[dict[str, Any]]:
            cursor = conn.execute(
                "SELECT projection_name, last_event_id, last_version, updated_at "
                "FROM projection_checkpoints ORDER BY projection_name"
            )
            rows = cursor.fetchall()
            return [
                {
                    "projection_name": r[0],
                    "last_event_id": r[1],
                    "last_version": int(r[2]),
                    "updated_at": r[3],
                }
                for r in rows
            ]

        return await asyncio.to_thread(_sync)

    # ── Stats ──────────────────────────────────────────────────────────

    async def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki EventStore (async, w wątku)."""
        conn = await self._get_conn()

        def _sync() -> dict[str, Any]:
            cursor = conn.execute("SELECT COUNT(*) FROM event_stream")
            total_events = int(cursor.fetchone()[0]) if cursor.fetchone() else 0

            cursor = conn.execute("SELECT COUNT(*) FROM snapshots")
            total_snapshots = int(cursor.fetchone()[0]) if cursor.fetchone() else 0

            cursor = conn.execute("SELECT COUNT(*) FROM projection_checkpoints")
            total_projections = int(cursor.fetchone()[0]) if cursor.fetchone() else 0

            cursor = conn.execute(
                "SELECT aggregate_type, COUNT(DISTINCT aggregate_id) as cnt "
                "FROM event_stream GROUP BY aggregate_type"
            )
            rows = cursor.fetchall()
            aggregates = {str(r[0]): int(r[1]) for r in rows}

            return {
                "total_events": total_events,
                "total_snapshots": total_snapshots,
                "total_projections": total_projections,
                "aggregates": aggregates,
            }

        return await asyncio.to_thread(_sync)


# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
EventStore = AsyncEventStore


# ── Helper ────────────────────────────────────────────────────────────────


def pendulum_now() -> str:
    """Zwróć aktualny timestamp ISO 8601."""
    import pendulum

    return pendulum.now("UTC").isoformat()
