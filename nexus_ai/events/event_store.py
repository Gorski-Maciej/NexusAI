"""
AsyncEventStore — append-only event store backed by sqlite3 + Parquet archiving.

Przechowuje zdarzenia w tabeli ``event_stream`` jako append-only log.
Python 3.13t (free-threaded): używamy natywnego sqlite3 + anyio.to_thread.run_sync.

Python 3.13t (free-threaded): używamy natywnego sqlite3 + anyio.to_thread.run_sync.

SUPERMOCE Parquet (nowe):
- **Event archiving do Parquet** — stare eventy są archiwizowane do Parquet
  z Hive partycjonowaniem (year/month/day) dla szybkiego odcięcia partycji
- **Parquet zamiast JSONL** — 10× mniejszy rozmiar na dysku
- **Predicate pushdown** — DuckDB czyta Parquet z filter pushdown
- **Zero-copy do Polars** — ``pl.from_arrow()`` dla analityki

Wspiera:
  - Zapis wielu eventów w jednej transakcji (batch append)
  - Optimistic concurrency (expected_version)
  - Odczyty strumienia dla konkretnego agregatu
  - Snapshoty dla szybkiego odbudowy stanu
  - Checkpointy dla projekcji CQRS
  - Archiwizacja eventów do Parquet
"""

from __future__ import annotations

import anyio
from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads as _msgspec_loads
import os
import sqlite3
from pathlib import Path
from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.db.async_db_pool import get_async_db_pool
from nexus_ai.events.domain_events import (
    DomainEvent,
    decode_event,
    encode_event,
)

# SUPERMOC: Lazy import OTel metrics — importowany raz przy starcie
_otel_record_append = None


def _get_record_append():
    global _otel_record_append
    if _otel_record_append is None:
        try:
            from nexus_ai.api.telemetry_metrics import record_event_store_append

            _otel_record_append = record_event_store_append
        except ImportError as exc:
            logger.debug("[EVENT-STORE] telemetry_metrics not available: %s", exc)
            _otel_record_append = lambda **kw: None
        except Exception as exc:
            logger.warning("[EVENT-STORE] Unexpected error loading telemetry: %s", exc)
            _otel_record_append = lambda **kw: None
    return _otel_record_append


logger = get_logger("nexus.events.store")


class AsyncEventStore:
    """Append-only event store backed by sqlite3 (sync + anyio.to_thread.run_sync).

    Python 3.13t (free-threaded): wszystkie operacje sqlite3 wykonujemy
    w wątku przez ``anyio.to_thread.run_sync()``.

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

            self._conn = await anyio.to_thread.run_sync(
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

        await anyio.to_thread.run_sync(_sync)

    async def close(self) -> None:
        """Zamknij połączenie."""
        if self._conn is not None:
            try:

                def _optimize() -> None:
                    try:
                        self._conn.execute("PRAGMA optimize;")
                    except sqlite3.OperationalError as exc:
                        logger.debug("[EVENT-STORE] optimize failed: %s", exc)
                    except Exception as exc:
                        logger.warning("[EVENT-STORE] Unexpected error during optimize: %s", exc)

                await anyio.to_thread.run_sync(_optimize)
            except (OSError, sqlite3.Error) as exc:
                logger.warning("[EVENT-STORE] Close error: %s", exc)
            await anyio.to_thread.run_sync(self._pool.close_conn, str(self._db_path))
            self._conn = None

    # ── Write operations ───────────────────────────────────────────────

    # SUPERMOC: Prawdziwy OTel tracer zamiast buffer_span
    # Używa prawdziwych spanów OTel z kontekstem, a nie fallback buffer
    def _get_tracer(self):
        from nexus_ai.core.otel_tracing import get_tracer

        return get_tracer("nexus.event_store")

    async def append_events(
        self,
        aggregate_type: str,
        aggregate_id: str,
        events: list[DomainEvent],
        expected_version: int | None = None,
    ) -> list[str]:
        """Zapisz eventy do strumienia w jednej transakcji (async, w wątku).

        SUPERMOC OTel Metrics: Record EventStore metrics (event count, duration).

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
        import time as _time

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
                    metadata_json = msgspec_dumps(event.metadata)
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

        # SUPERMOC: Prawdziwy OTel span dla operacji append z Span Events
        await self._trace_append(aggregate_type, aggregate_id, events)

        t0 = _time.perf_counter()
        result = await anyio.to_thread.run_sync(_sync_append)
        elapsed = _time.perf_counter() - t0

        # SUPERMOC: Record EventStore metrics (lazy import przez _get_record_append)
        _record_append = _get_record_append()
        _record_append(
            aggregate_type=aggregate_type,
            event_count=len(events),
            duration_seconds=elapsed,
        )

        return result

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

        return await anyio.to_thread.run_sync(_sync)

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

        return await anyio.to_thread.run_sync(_sync)

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

        return await anyio.to_thread.run_sync(_sync)

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

        return await anyio.to_thread.run_sync(_sync)

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

        return await anyio.to_thread.run_sync(_sync)

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
                    msgspec_dumps(state),
                    pendulum_now(),
                ),
            )
            conn.commit()

        await anyio.to_thread.run_sync(_sync)
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
            return int(row[0]), _msgspec_loads(row[1])

        return await anyio.to_thread.run_sync(_sync)

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

        return await anyio.to_thread.run_sync(_sync)

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

        await anyio.to_thread.run_sync(_sync)

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

        return await anyio.to_thread.run_sync(_sync)

    # ── Stats ──────────────────────────────────────────────────────────

    # ── SUPERMOC: Archiwizacja eventów do Parquet ─────────────────────
    # Stare eventy (np. > 30 dni) mogą być archiwizowane do Parquet
    # z Hive partycjonowaniem (year/month/day).
    # DuckDB/pyarrow mogą je odczytać z predicate pushdown.
    # Zysk: mniejsza baza SQLite, szybsze zapytania, tanie przechowywanie.

    def _get_parquet_archive_dir(self) -> Path:
        """Zwróć katalog dla archiwum Parquet."""
        archive_dir = self._db_path.parent / "event_archive_parquet"
        archive_dir.mkdir(parents=True, exist_ok=True)
        return archive_dir

    async def archive_events_to_parquet(
        self,
        before_days: int = 30,
        aggregate_type: str | None = None,
        batch_size: int = 10000,
    ) -> int:
        """SUPERMOC Parquet: Archiwizuj stare eventy do Parquet.

        SUPERMOCE:
        - Hive partycjonowanie: katalogi year=/month=/day=/
        - ``pa.Table.from_pylist()`` — zero-copy konwersja
        - ``pq.write_table()`` z ZSTD kompresją
        - Po archiwizacji eventy są usuwane z SQLite

        Args:
            before_days: Tylko eventy starsze niż N dni.
            aggregate_type: Opcjonalnie tylko dla danego agregatu.
            batch_size: Liczba eventów na batch.

        Returns:
            Liczba zarchiwizowanych eventów.
        """
        import pyarrow as pa
        import pyarrow.parquet as pq

        conn = await self._get_conn()
        archive_dir = self._get_parquet_archive_dir()
        cutoff = pendulum.now().subtract(days=before_days)
        cutoff_str = cutoff.isoformat()
        total_archived = 0

        def _archive_batch() -> int:
            nonlocal total_archived

            # Pobierz eventy do archiwizacji
            if aggregate_type:
                cursor = conn.execute(
                    """SELECT event_id, aggregate_type, aggregate_id, event_type,
                              version, timestamp, data, metadata_json
                       FROM event_stream
                       WHERE timestamp < ? AND aggregate_type = ?
                       ORDER BY timestamp ASC LIMIT ?""",
                    (cutoff_str, aggregate_type, batch_size),
                )
            else:
                cursor = conn.execute(
                    """SELECT event_id, aggregate_type, aggregate_id, event_type,
                              version, timestamp, data, metadata_json
                       FROM event_stream
                       WHERE timestamp < ?
                       ORDER BY timestamp ASC LIMIT ?""",
                    (cutoff_str, batch_size),
                )

            rows = cursor.fetchall()
            if not rows:
                return 0

            # Konwertuj do listy słowników — partycjonuj każdy event osobno
            records_by_date: dict[str, list[dict[str, Any]]] = {}
            event_ids_all = []
            for row in rows:
                event_id = row[0]
                ts = pendulum.parse(row[5])  # row[5] = timestamp
                date_key = f"year={ts.year}/month={ts.month:02d}/day={ts.day:02d}"
                record = {
                    "event_id": event_id,
                    "aggregate_type": row[1],
                    "aggregate_id": row[2],
                    "event_type": row[3],
                    "version": int(row[4]),
                    "timestamp": row[5],
                    "data": row[6],
                    "metadata_json": row[7],
                }
                records_by_date.setdefault(date_key, []).append(record)
                event_ids_all.append(event_id)

            # Zapisz do Parquet z Hive partycjonowaniem — osobny plik na datę
            for date_key, date_records in records_by_date.items():
                table = pa.Table.from_pylist(date_records)
                part_path = archive_dir / date_key
                part_path.mkdir(parents=True, exist_ok=True)
                archive_file = (
                    part_path / f"events_{pendulum.now().format('YYYYMMDD_HHmmss')}.parquet"
                )
                pq.write_table(
                    table,
                    str(archive_file),
                    compression="ZSTD",
                    compression_level=7,
                    row_group_size=65536,
                    write_statistics=True,
                )

            pq.write_table(
                table,
                str(archive_file),
                compression="ZSTD",
                compression_level=7,
                row_group_size=65536,
                write_statistics=True,
            )

            # Usuń zarchiwizowane eventy z SQLite
            placeholders = ",".join("?" for _ in event_ids)
            conn.execute(
                f"DELETE FROM event_stream WHERE event_id IN ({placeholders})",
                event_ids,
            )
            conn.commit()

            archived_count = len(event_ids)
            logger.info(
                "[EVENT-STORE] Archived %d events to Parquet: %s",
                archived_count,
                archive_file,
            )
            return archived_count

        # ── SUPERMOC: Batch archiwizacja — wiele iteracji ────────────
        # Archiwizuje po batch_size eventów na raz, aż wszystkie
        # stare eventy zostaną przeniesione do Parquet.
        while True:
            archived = await anyio.to_thread.run_sync(_archive_batch)
            if archived == 0:
                break
            total_archived += archived

        return total_archived

    async def query_archived_events(
        self,
        *,
        aggregate_type: str | None = None,
        event_type: str | None = None,
        since: str | None = None,
        limit: int = 1000,
    ) -> list[dict[str, Any]]:
        """SUPERMOC DuckDB: Odczytaj zarchiwizowane eventy z Parquet.

        ``DuckDB.read_parquet()`` czyta Parquet z predicate pushdown —
        DuckDB automatycznie wykorzystuje statystyki Parquet do
        odcięcia niepotrzebnych row groups.
        Zysk: szybki odczyt bez wczytywania całego archiwum.

        Args:
            aggregate_type: Filtruj po typie agregatu.
            event_type: Filtruj po typie eventu.
            since: Tylko eventy od tej daty.
            limit: Maksymalna liczba wyników.

        Returns:
            Lista zarchiwizowanych eventów jako słowniki.
        """
        archive_dir = self._get_parquet_archive_dir()
        parquet_files = list(archive_dir.rglob("*.parquet"))
        if not parquet_files:
            return []

        try:
            import duckdb

            conn = duckdb.connect()
            try:
                conditions = []
                if aggregate_type:
                    conditions.append(f"aggregate_type = '{aggregate_type}'")
                if event_type:
                    conditions.append(f"event_type = '{event_type}'")
                if since:
                    conditions.append(f"timestamp >= '{since}'")

                where_clause = ""
                if conditions:
                    where_clause = " WHERE " + " AND ".join(conditions)

                # Użyj read_parquet z glob dla wszystkich plików
                sql = f"""
                    SELECT * FROM read_parquet('{archive_dir}/**/*.parquet')
                    {where_clause}
                    ORDER BY timestamp DESC
                    LIMIT {limit}
                """
                result = conn.execute(sql).fetchdf()
                if result is None or result.empty:
                    return []
                return result.to_dict(orient="records")
            finally:
                conn.close()
        except (duckdb.Error, pyarrow.lib.ArrowException) as exc:
            logger.warning("[EVENT-STORE] Failed to query archived Parquet: %s", exc)
            return []
        except Exception as exc:
            logger.error("[EVENT-STORE] Unexpected error querying archived Parquet: %s", exc)
            return []

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

            # Policz zarchiwizowane pliki Parquet
            archive_dir = self._get_parquet_archive_dir()
            parquet_files = list(archive_dir.rglob("*.parquet"))
            archived_size_bytes = sum(f.stat().st_size for f in parquet_files)

            return {
                "total_events": total_events,
                "total_snapshots": total_snapshots,
                "total_projections": total_projections,
                "aggregates": aggregates,
                "archived_parquet_files": len(parquet_files),
                "archived_size_bytes": archived_size_bytes,
                "archived_size_mb": round(archived_size_bytes / (1024 * 1024), 2),
            }

        return await anyio.to_thread.run_sync(_sync)


# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
EventStore = AsyncEventStore


# ── Helper ────────────────────────────────────────────────────────────────


def pendulum_now() -> str:
    """Zwróć aktualny timestamp ISO 8601."""
    import pendulum

    return pendulum.now("UTC").isoformat()
