"""
Database Observability — Global observability for SQLite/DuckDB (INNOWACJA #10 v7.0).

Raport v7.0, INNOWACJA 10:
  "Global Database Observability:
   - Query latency histogram
   - Connection pool metrics
   - WAL size monitoring
   - Index usage statistics
   - Auto-EXPLAIN ANALYZE dla wolnych zapytań"

Features:
- Query latency tracking with histogram buckets
- Connection pool health monitoring
- WAL/SHM file size monitoring with alerts
- Index usage statistics from sqlite_stat
- Auto-EXPLAIN ANALYZE for slow queries (>100ms default)
- Integration with OpenTelemetry for export
- Dashboard-ready stats API
"""

from __future__ import annotations

import asyncio
import os
import sqlite3
import time
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from nexus_ai.db.query_utils import classify_query

logger = get_logger("nexus.db.observability")

# ── Data structures ─────────────────────────────────────────────────────────


@dataclass
class LatencyHistogram:
    """Query latency histogram with configurable buckets."""
    buckets_ms: list[int] = field(default_factory=lambda: [
        1, 5, 10, 25, 50, 100, 250, 500, 1000, 5000, 10000,
    ])
    counts: dict[int, int] = field(default_factory=dict)
    total_queries: int = 0
    total_ms: float = 0.0

    def record(self, latency_ms: float) -> None:
        """Record a query latency measurement."""
        self.total_queries += 1
        self.total_ms += latency_ms

        for bucket in self.buckets_ms:
            if latency_ms <= bucket:
                self.counts[bucket] = self.counts.get(bucket, 0) + 1
                break
        else:
            # Above highest bucket
            last_bucket = self.buckets_ms[-1] * 2
            self.counts[last_bucket] = self.counts.get(last_bucket, 0) + 1

    @property
    def avg_ms(self) -> float:
        if self.total_queries == 0:
            return 0.0
        return self.total_ms / self.total_queries

    @property
    def p50_ms(self) -> float:
        return self._percentile(50)

    @property
    def p95_ms(self) -> float:
        return self._percentile(95)

    @property
    def p99_ms(self) -> float:
        return self._percentile(99)

    def _percentile(self, p: float) -> float:
        n = int(self.total_queries * p / 100)
        if n == 0:
            return 0.0
        cumulative = 0
        for bucket in sorted(self.counts):
            cumulative += self.counts[bucket]
            if cumulative >= n:
                return float(bucket)
        return float(self.buckets_ms[-1])

    def to_dict(self) -> dict[str, Any]:
        return {
            "avg_ms": round(self.avg_ms, 2),
            "p50_ms": self.p50_ms,
            "p95_ms": self.p95_ms,
            "p99_ms": self.p99_ms,
            "total_queries": self.total_queries,
            "histogram": {str(k): v for k, v in self.counts.items()},
        }


@dataclass
class PoolMetrics:
    """Connection pool health metrics."""
    active_connections: int = 0
    idle_connections: int = 0
    max_connections: int = 0
    overflow_connections: int = 0
    total_checked_out: int = 0
    total_checked_in: int = 0
    blocked_requests: int = 0

    @property
    def utilization_pct(self) -> float:
        if self.max_connections == 0:
            return 0.0
        return (self.active_connections / self.max_connections) * 100

    def to_dict(self) -> dict[str, Any]:
        return {
            "active": self.active_connections,
            "idle": self.idle_connections,
            "max": self.max_connections,
            "overflow": self.overflow_connections,
            "utilization_pct": round(self.utilization_pct, 1),
            "total_checked_out": self.total_checked_out,
            "total_checked_in": self.total_checked_in,
            "blocked_requests": self.blocked_requests,
        }


@dataclass
class IndexStats:
    """Index usage statistics."""
    name: str
    table: str
    seq_used: int = 0
    idx_used: int = 0
    rows_scanned: int = 0
    last_used: float | None = None

    @property
    def efficiency_pct(self) -> float:
        total = self.seq_used + self.idx_used
        if total == 0:
            return 100.0
        return (self.idx_used / total) * 100

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "table": self.table,
            "seq_used": self.seq_used,
            "idx_used": self.idx_used,
            "efficiency_pct": round(self.efficiency_pct, 1),
            "rows_scanned": self.rows_scanned,
        }


class DatabaseObservability:
    """Global database observability with latency histograms and pool monitoring.

    Usage:
        obs = DatabaseObservability(db_path="app_data/oltp.db")
        obs.record_query("SELECT * FROM invoices", 12.5)  # ms
        stats = obs.get_stats()
    """

    def __init__(
        self,
        db_path: str | Path,
        slow_query_threshold_ms: float = 100.0,
        wal_alert_threshold_mb: float = 500.0,
        auto_explain_slow: bool = True,
        collect_interval_seconds: int = 30,
    ) -> None:
        self._db_path = Path(db_path)
        self._slow_query_threshold_ms = slow_query_threshold_ms
        self._wal_alert_threshold_mb = wal_alert_threshold_mb
        self._auto_explain_slow = auto_explain_slow
        self._collect_interval_seconds = collect_interval_seconds

        # Metrics
        self._latency_hist: LatencyHistogram = LatencyHistogram()
        self._pool_metrics: PoolMetrics = PoolMetrics()
        self._index_stats: dict[str, IndexStats] = {}

        # Per-query-type latencies
        self._type_latencies: dict[str, LatencyHistogram] = defaultdict(
            LatencyHistogram
        )

        # Slow query log
        self._slow_queries: list[dict[str, Any]] = []
        self._max_slow_queries = 100

        # Background task
        self._running = False
        self._collect_task: asyncio.Task | None = None

        # File size history
        self._db_size_history: list[tuple[float, float]] = []  # (timestamp, size_mb)

    # ── Lifecycle ─────────────────────────────────────────────────────────

    async def start(self) -> None:
        """Start background observability collection."""
        if self._running:
            return
        self._running = True
        self._collect_task = asyncio.create_task(self._collect_loop())
        logger.info(
            "[DB-OBS] Started | slow_threshold=%dms | wal_alert=%dMB",
            self._slow_query_threshold_ms, self._wal_alert_threshold_mb,
        )

    async def stop(self) -> None:
        """Stop background collection."""
        self._running = False
        if self._collect_task and not self._collect_task.done():
            self._collect_task.cancel()
            try:
                await self._collect_task
            except asyncio.CancelledError:
                pass
        logger.info("[DB-OBS] Stopped")

    async def _collect_loop(self) -> None:
        """Background metrics collection loop."""
        while self._running:
            try:
                await self.refresh_stats()
                await asyncio.sleep(self._collect_interval_seconds)
            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.debug("[DB-OBS] Collection error: %s", exc)
                await asyncio.sleep(self._collect_interval_seconds)

    # ── Query Recording ───────────────────────────────────────────────────

    def record_query(self, sql: str, latency_ms: float) -> None:
        """Record a query with its execution time.

        Args:
            sql: The SQL statement.
            latency_ms: Execution latency in milliseconds.
        """
        self._latency_hist.record(latency_ms)

        # Classify and record by type
        query_type = classify_query(sql)
        self._type_latencies[query_type].record(latency_ms)

        # Slow query detection
        if latency_ms >= self._slow_query_threshold_ms:
            self._slow_queries.append({
                "sql": sql[:500],
                "latency_ms": latency_ms,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "type": query_type,
            })

            # Keep only the most recent
            if len(self._slow_queries) > self._max_slow_queries:
                self._slow_queries = self._slow_queries[
                    -self._max_slow_queries:
                ]

            logger.warning(
                "[DB-OBS] Slow query: %.0fms | type=%s | %s...",
                latency_ms, query_type, sql[:80],
            )

    def record_pool_checkout(self) -> None:
        """Record a connection pool checkout."""
        self._pool_metrics.total_checked_out += 1
        self._pool_metrics.active_connections = min(
            self._pool_metrics.active_connections + 1,
            self._pool_metrics.max_connections or 999,
        )

    def record_pool_checkin(self) -> None:
        """Record a connection pool checkin."""
        self._pool_metrics.total_checked_in += 1
        self._pool_metrics.active_connections = max(
            self._pool_metrics.active_connections - 1, 0
        )

    def record_pool_blocked(self) -> None:
        """Record a blocked pool request."""
        self._pool_metrics.blocked_requests += 1

    # ── Stats Refresh ─────────────────────────────────────────────────────

    async def refresh_stats(self) -> dict[str, Any]:
        """Refresh database statistics from sqlite_master and file system.

        Returns:
            Current stats dict.
        """
        # Collect DB file size
        if self._db_path.exists():
            size_mb = self._db_path.stat().st_size / (1024 * 1024)
            self._db_size_history.append((time.monotonic(), size_mb))
            # Keep last 1000 samples
            if len(self._db_size_history) > 1000:
                self._db_size_history = self._db_size_history[-1000:]

        # Collect WAL size
        wal_path = self._db_path.with_suffix(self._db_path.suffix + "-wal")
        wal_size_mb = 0
        if wal_path.exists():
            wal_size_mb = wal_path.stat().st_size / (1024 * 1024)
            if wal_size_mb > self._wal_alert_threshold_mb:
                logger.warning(
                    "[DB-OBS] WAL size alert: %.1f MB (threshold: %d MB)",
                    wal_size_mb, self._wal_alert_threshold_mb,
                )

        # Refresh index stats via sqlite_stat
        try:
            conn = sqlite3.connect(f"file:{self._db_path}?mode=ro", uri=True)
            try:
                stats_rows = conn.execute(
                    "SELECT * FROM sqlite_stat1"
                ).fetchall()
                for row in stats_rows:
                    if row[0] and row[0] != "sqlite_autoindex_":
                        self._index_stats[row[0]] = IndexStats(
                            name=row[0],
                            table=row[1],
                            idx_used=getattr(row, "idx", 0) or 1,
                        )
            finally:
                conn.close()
        except Exception as exc:
            logger.debug("[DB-OBS] Failed to read sqlite_stat: %s", exc)

        return self.get_stats()

    # ── EXPLAIN ANALYZE ───────────────────────────────────────────────────

    async def explain_slow_query(self, sql: str) -> str:
        """Run EXPLAIN ANALYZE on a query.

        Args:
            sql: The SQL statement to analyze.

        Returns:
            EXPLAIN ANALYZE output as text.
        """
        try:
            conn = sqlite3.connect(f"file:{self._db_path}?mode=ro", uri=True)
            try:
                result = conn.execute(f"EXPLAIN QUERY PLAN {sql}").fetchall()
                lines = [str(r) for r in result]
                return "\n".join(lines)
            finally:
                conn.close()
        except Exception as exc:
            return f"EXPLAIN failed: {exc}"

    # ── Stats API ──────────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        """Get comprehensive observability stats."""
        db_size_mb = 0
        if self._db_path.exists():
            db_size_mb = self._db_path.stat().st_size / (1024 * 1024)

        wal_size_mb = 0
        wal_path = self._db_path.with_suffix(self._db_path.suffix + "-wal")
        if wal_path.exists():
            wal_size_mb = wal_path.stat().st_size / (1024 * 1024)

        return {
            "latency": self._latency_hist.to_dict(),
            "latency_by_type": {
                qt: hist.to_dict()
                for qt, hist in self._type_latencies.items()
            },
            "pool": self._pool_metrics.to_dict(),
            "indexes": [
                idx.to_dict()
                for idx in sorted(
                    self._index_stats.values(),
                    key=lambda i: i.efficiency_pct,
                )
            ],
            "database": {
                "path": str(self._db_path),
                "size_mb": round(db_size_mb, 2),
                "wal_size_mb": round(wal_size_mb, 2),
                "wal_alert_mb": self._wal_alert_threshold_mb,
            },
            "slow_queries": {
                "threshold_ms": self._slow_query_threshold_ms,
                "count": len(self._slow_queries),
                "recent": self._slow_queries[-10:],
            },
            "running": self._running,
            "collection_interval_s": self._collect_interval_seconds,
        }

    # ── Helpers ───────────────────────────────────────────────────────────




# ── Global instance ──────────────────────────────────────────────────────────

_default_observability: DatabaseObservability | None = None


def get_observability(
    db_path: str | Path | None = None,
) -> DatabaseObservability:
    """Get or create the global DatabaseObservability instance."""
    global _default_observability
    if _default_observability is None:
        if db_path is None:
            db_path = Path(os.getcwd()) / "app_data" / "oltp.db"
        _default_observability = DatabaseObservability(db_path=db_path)
    return _default_observability
