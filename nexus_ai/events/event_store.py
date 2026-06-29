"""AsyncEventStore — append-only event store (sqlite3 + Parquet archiving)."""

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
from nexus_ai.events.domain_events import DomainEvent, decode_event, encode_event

logger = get_logger("nexus.events.store")
_otel_record_append = None


def _get_record_append():
    global _otel_record_append
    if _otel_record_append is None:
        try:
            from nexus_ai.api.telemetry_metrics import record_event_store_append
            _otel_record_append = record_event_store_append
        except Exception:
            _otel_record_append = lambda **kw: None
    return _otel_record_append


class AsyncEventStore:
    """Append-only event store — sqlite3 via anyio.to_thread.run_sync."""

    def __init__(self, db_path: str | Path) -> None:
        self._db_path = Path(db_path)
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._pool = get_async_db_pool()
        self._conn: sqlite3.Connection | None = None

    async def _run_sync(self, fn, *args, **kwargs):
        return await anyio.to_thread.run_sync(fn, *args, **kwargs)

    async def _get_conn(self) -> sqlite3.Connection:
        if self._conn is None:
            key = os.environ.get("NEXUS_EVENT_STORE_KEY", "") or os.environ.get("NEXUS_SQLCIPHER_KEY", "")
            self._conn = await self._run_sync(self._pool.get_conn, str(self._db_path),
                row_factory=sqlite3.Row, sqlcipher_key=key or None)
            await self._ensure_schema()
        return self._conn

    async def _ensure_schema(self) -> None:
        conn = await self._get_conn()
        def _sync():
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS event_stream (
                    event_id TEXT PRIMARY KEY, aggregate_type TEXT NOT NULL,
                    aggregate_id TEXT NOT NULL, event_type TEXT NOT NULL,
                    version INTEGER NOT NULL, timestamp TEXT NOT NULL,
                    data BLOB NOT NULL, metadata_json TEXT NOT NULL DEFAULT '{}',
                    created_at TEXT NOT NULL DEFAULT (datetime('now')));
                CREATE INDEX IF NOT EXISTS idx_events_aggregate ON event_stream(aggregate_type, aggregate_id, version);
                CREATE INDEX IF NOT EXISTS idx_events_type ON event_stream(event_type, timestamp);
                CREATE INDEX IF NOT EXISTS idx_events_timestamp ON event_stream(timestamp);
                CREATE TABLE IF NOT EXISTS snapshots (aggregate_id TEXT NOT NULL, aggregate_type TEXT NOT NULL,
                    version INTEGER NOT NULL, state_json TEXT NOT NULL, timestamp TEXT NOT NULL,
                    PRIMARY KEY (aggregate_id, aggregate_type));
                CREATE TABLE IF NOT EXISTS projection_checkpoints (
                    projection_name TEXT PRIMARY KEY, last_event_id TEXT,
                    last_version INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL);""")
            conn.commit()
        await self._run_sync(_sync)

    async def close(self) -> None:
        if self._conn is not None:
            try:
                await self._run_sync(lambda: self._conn.execute("PRAGMA optimize;"))
            except Exception as exc:
                logger.warning("[STORE] PRAGMA optimize failed: %s", exc)
            await self._run_sync(lambda: self._pool.close_conn(str(self._db_path)))
            self._conn = None

    def _get_tracer(self):
        from nexus_ai.core.otel import get_tracer
        return get_tracer("nexus.event_store")

    async def append_events(self, aggregate_type: str, aggregate_id: str,
                            events: list[DomainEvent], expected_version: int | None = None) -> list[str]:
        import time as _time
        conn = await self._get_conn()
        def _sync_append() -> list[str]:
            event_ids: list[str] = []
            conn.execute("SAVEPOINT event_append;")
            try:
                if expected_version is not None:
                    cursor = conn.execute("SELECT COALESCE(MAX(version), 0) FROM event_stream "
                        "WHERE aggregate_type = ? AND aggregate_id = ?", (aggregate_type, aggregate_id))
                    current = int(cursor.fetchone()[0]) if cursor.fetchone() else 0
                    if current != expected_version:
                        conn.execute("ROLLBACK TO SAVEPOINT event_append;")
                        raise ValueError(f"OC violation: expected {expected_version}, current {current}")
                for event in events:
                    cursor = conn.execute(
                        """INSERT INTO event_stream (event_id, aggregate_type, aggregate_id, event_type,
                        version, timestamp, data, metadata_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING event_id""",
                        (event.event_id, aggregate_type, aggregate_id, event.event_type,
                         event.version, event.timestamp, encode_event(event), msgspec_dumps(event.metadata)))
                    row = cursor.fetchone()
                    event_ids.append(str(row[0]) if row else event.event_id)
                conn.execute("RELEASE SAVEPOINT event_append;")
                if event_ids:
                    logger.info("[STORE] Appended %d events to %s:%s v=%d", len(events), aggregate_type, aggregate_id, events[-1].version)
            except Exception:
                conn.execute("ROLLBACK TO SAVEPOINT event_append;")
                raise
            return event_ids
        t0 = _time.perf_counter()
        result = await self._run_sync(_sync_append)
        _get_record_append()(aggregate_type=aggregate_type, event_count=len(events), duration_seconds=_time.perf_counter() - t0)
        return result

    async def read_events(self, aggregate_type: str, aggregate_id: str,
                          from_version: int = 0, to_version: int | None = None, limit: int = 1000) -> list[DomainEvent]:
        conn = await self._get_conn()
        def _sync():
            if to_version:
                cursor = conn.execute("SELECT data FROM event_stream WHERE aggregate_type=? AND aggregate_id=? AND version>=? AND version<=? ORDER BY version ASC LIMIT ?",
                    (aggregate_type, aggregate_id, from_version, to_version, limit))
            else:
                cursor = conn.execute("SELECT data FROM event_stream WHERE aggregate_type=? AND aggregate_id=? AND version>=? ORDER BY version ASC LIMIT ?",
                    (aggregate_type, aggregate_id, from_version, limit))
            return [decode_event(row[0]) for row in cursor.fetchall()]
        return await self._run_sync(_sync)

    async def read_events_by_type(self, event_type: str | None = None, since: str | None = None, limit: int = 100) -> list[DomainEvent]:
        conn = await self._get_conn()
        def _sync():
            match (event_type, since):
                case (str() as et, str() as s):
                    cursor = conn.execute("SELECT data FROM event_stream WHERE event_type=? AND timestamp>=? ORDER BY timestamp ASC LIMIT ?", (et, s, limit))
                case (str() as et, None):
                    cursor = conn.execute("SELECT data FROM event_stream WHERE event_type=? ORDER BY timestamp ASC LIMIT ?", (et, limit))
                case (None, str() as s):
                    cursor = conn.execute("SELECT data FROM event_stream WHERE timestamp>=? ORDER BY timestamp ASC LIMIT ?", (s, limit))
                case _:
                    cursor = conn.execute("SELECT data FROM event_stream ORDER BY timestamp ASC LIMIT ?", (limit,))
            return [decode_event(row[0]) for row in cursor.fetchall()]
        return await self._run_sync(_sync)

    async def read_stream(self, aggregate_type: str, aggregate_id: str) -> list[DomainEvent]:
        return await self.read_events(aggregate_type, aggregate_id, from_version=0)

    async def get_version(self, aggregate_type: str, aggregate_id: str) -> int:
        conn = await self._get_conn()
        def _sync():
            cursor = conn.execute("SELECT COALESCE(MAX(version), 0) FROM event_stream WHERE aggregate_type=? AND aggregate_id=?", (aggregate_type, aggregate_id))
            return int(cursor.fetchone()[0]) if cursor.fetchone() else 0
        return await self._run_sync(_sync)

    async def read_events_since_version(self, aggregate_type: str, from_version: int = 0, limit: int = 500) -> list[DomainEvent]:
        conn = await self._get_conn()
        def _sync():
            cursor = conn.execute("SELECT data FROM event_stream WHERE aggregate_type=? AND version>=? ORDER BY version ASC LIMIT ?", (aggregate_type, from_version, limit))
            return [decode_event(row[0]) for row in cursor.fetchall()]
        return await self._run_sync(_sync)

    async def count_events(self, aggregate_type: str | None = None, event_type: str | None = None) -> int:
        conn = await self._get_conn()
        def _sync():
            match (aggregate_type, event_type):
                case (str() as at, str() as et):
                    cursor = conn.execute("SELECT COUNT(*) FROM event_stream WHERE aggregate_type=? AND event_type=?", (at, et))
                case (str() as at, None):
                    cursor = conn.execute("SELECT COUNT(*) FROM event_stream WHERE aggregate_type=?", (at,))
                case (None, str() as et):
                    cursor = conn.execute("SELECT COUNT(*) FROM event_stream WHERE event_type=?", (et,))
                case _:
                    cursor = conn.execute("SELECT COUNT(*) FROM event_stream")
            return int(cursor.fetchone()[0]) if cursor.fetchone() else 0
        return await self._run_sync(_sync)

    async def save_snapshot(self, aggregate_type: str, aggregate_id: str, version: int, state: dict[str, Any]) -> None:
        conn = await self._get_conn()
        def _sync():
            conn.execute("""INSERT INTO snapshots (aggregate_id, aggregate_type, version, state_json, timestamp)
                VALUES (?, ?, ?, ?, ?) ON CONFLICT(aggregate_id, aggregate_type) DO UPDATE SET
                version=EXCLUDED.version, state_json=EXCLUDED.state_json, timestamp=EXCLUDED.timestamp""",
                (aggregate_id, aggregate_type, version, msgspec_dumps(state), pendulum_now()))
            conn.commit()
        await self._run_sync(_sync)

    async def load_snapshot(self, aggregate_type: str, aggregate_id: str) -> tuple[int, dict[str, Any]] | None:
        conn = await self._get_conn()
        def _sync():
            cursor = conn.execute("SELECT version, state_json FROM snapshots WHERE aggregate_id=? AND aggregate_type=?", (aggregate_id, aggregate_type))
            if (row := cursor.fetchone()) is not None:
                return int(row[0]), _msgspec_loads(row[1])
            return None
        return await self._run_sync(_sync)

    async def get_checkpoint(self, projection_name: str) -> int:
        conn = await self._get_conn()
        def _sync():
            cursor = conn.execute("SELECT last_version FROM projection_checkpoints WHERE projection_name=?", (projection_name,))
            return int(cursor.fetchone()[0]) if cursor.fetchone() else 0
        return await self._run_sync(_sync)

    async def update_checkpoint(self, projection_name: str, last_event_id: str, last_version: int) -> None:
        conn = await self._get_conn()
        def _sync():
            conn.execute("INSERT INTO projection_checkpoints (projection_name, last_event_id, last_version, updated_at) VALUES (?, ?, ?, ?) "
                "ON CONFLICT(projection_name) DO UPDATE SET last_event_id=EXCLUDED.last_event_id, last_version=EXCLUDED.last_version, updated_at=EXCLUDED.updated_at",
                (projection_name, last_event_id, last_version, pendulum_now()))
            conn.commit()
        await self._run_sync(_sync)

    async def list_projections(self) -> list[dict[str, Any]]:
        conn = await self._get_conn()
        def _sync():
            cursor = conn.execute("SELECT projection_name, last_event_id, last_version, updated_at FROM projection_checkpoints ORDER BY projection_name")
            return [{"projection_name": r[0], "last_event_id": r[1], "last_version": int(r[2]), "updated_at": r[3]} for r in cursor.fetchall()]
        return await self._run_sync(_sync)

    def _get_parquet_archive_dir(self) -> Path:
        archive_dir = self._db_path.parent / "event_archive_parquet"
        archive_dir.mkdir(parents=True, exist_ok=True)
        return archive_dir

    async def archive_events_to_parquet(self, before_days: int = 30, aggregate_type: str | None = None, batch_size: int = 10000) -> int:
        import pyarrow as pa, pyarrow.parquet as pq
        conn = await self._get_conn()
        archive_dir = self._get_parquet_archive_dir()
        cutoff = pendulum.now().subtract(days=before_days).isoformat()
        total = 0
        while True:
            def _archive_batch() -> int:
                cursor = conn.execute(
                    "SELECT event_id, aggregate_type, aggregate_id, event_type, version, timestamp, data, metadata_json "
                    "FROM event_stream WHERE timestamp < ?" + (" AND aggregate_type = ?" if aggregate_type else "") + " ORDER BY timestamp ASC LIMIT ?",
                    (cutoff, aggregate_type, batch_size) if aggregate_type else (cutoff, batch_size))
                rows = cursor.fetchall()
                if not rows:
                    return 0
                by_date: dict[str, list[dict]] = {}
                ids = []
                for r in rows:
                    ts = pendulum.parse(r[5])
                    dk = f"year={ts.year}/month={ts.month:02d}/day={ts.day:02d}"
                    by_date.setdefault(dk, []).append({"event_id": r[0], "aggregate_type": r[1], "aggregate_id": r[2],
                        "event_type": r[3], "version": int(r[4]), "timestamp": r[5], "data": r[6], "metadata_json": r[7]})
                    ids.append(r[0])
                for dk, recs in by_date.items():
                    af = archive_dir / dk / f"events_{pendulum.now().format('YYYYMMDD_HHmmss')}.parquet"
                    af.parent.mkdir(parents=True, exist_ok=True)
                    pq.write_table(pa.Table.from_pylist(recs), str(af), compression="ZSTD", compression_level=7)
                conn.execute(f"DELETE FROM event_stream WHERE event_id IN ({','.join('?' for _ in ids)})", ids)
                conn.commit()
                logger.info("[STORE] Archived %d events", len(ids))
                return len(ids)
            archived = await self._run_sync(_archive_batch)
            if not archived:
                break
            total += archived
        return total

    async def query_archived_events(self, *, aggregate_type: str | None = None, event_type: str | None = None,
                                     since: str | None = None, limit: int = 1000) -> list[dict[str, Any]]:
        archive_dir = self._get_parquet_archive_dir()
        if not list(archive_dir.rglob("*.parquet")):
            return []
        try:
            import duckdb
            conn = duckdb.connect()
            try:
                cond = " AND ".join(filter(None, [f"aggregate_type='{aggregate_type}'" if aggregate_type else "",
                    f"event_type='{event_type}'" if event_type else "", f"timestamp>='{since}'" if since else ""]))
                result = conn.execute(f"SELECT * FROM read_parquet('{archive_dir}/**/*.parquet'){" WHERE " + cond if cond else ""} ORDER BY timestamp DESC LIMIT {limit}").fetchdf()
                return [] if result is None or result.empty else result.to_dict(orient="records")
            finally:
                conn.close()
        except Exception as exc:
            logger.warning("[STORE] Failed to query archived Parquet: %s", exc)
            return []

    async def get_stats(self) -> dict[str, Any]:
        conn = await self._get_conn()
        def _sync():
            te = int(conn.execute("SELECT COUNT(*) FROM event_stream").fetchone()[0])
            ts = int(conn.execute("SELECT COUNT(*) FROM snapshots").fetchone()[0])
            tp = int(conn.execute("SELECT COUNT(*) FROM projection_checkpoints").fetchone()[0])
            cursor = conn.execute("SELECT aggregate_type, COUNT(DISTINCT aggregate_id) FROM event_stream GROUP BY aggregate_type")
            agg = {str(r[0]): int(r[1]) for r in cursor.fetchall()}
            af = list(self._get_parquet_archive_dir().rglob("*.parquet"))
            return {"total_events": te, "total_snapshots": ts, "total_projections": tp,
                "aggregates": agg, "archived_parquet_files": len(af),
                "archived_size_bytes": sum(f.stat().st_size for f in af)}
        return await self._run_sync(_sync)


# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
EventStore = AsyncEventStore


# ── Helper ────────────────────────────────────────────────────────────────


def pendulum_now() -> str:
    """Zwróć aktualny timestamp ISO 8601."""
    import pendulum

    return pendulum.now("UTC").isoformat()
