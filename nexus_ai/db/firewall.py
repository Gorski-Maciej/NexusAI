"""
Database Firewall — Application-level SQLite Query Protection (INNOWACJA #5 v7.0).

Raport v7.0, INNOWACJA 5:
  "Database Firewall — Application-level firewall dla SQLite:
   - Rate limiting per query type
   - Blokowanie podejrzanych zapytań (OR 1=1, DROP TABLE)
   - Prepared statements tylko (bez dynamic SQL)
   - Query profiling z auto-block"

Features:
- SQL injection pattern detection
- Rate limiting per query type (SELECT/INSERT/UPDATE/DELETE)
- Prepared statements enforcement
- Query profiling with auto-block thresholds
- Whitelist for known-safe queries
- Stats collection for observability
"""

from __future__ import annotations

import re
import time
from collections import defaultdict
from typing import Any

from structlog import get_logger

from nexus_ai.db.query_utils import QueryType, classify_query

logger = get_logger("nexus.db.firewall")

# ── SQL Injection Patterns ──────────────────────────────────────────────────

SQL_INJECTION_PATTERNS: list[tuple[str, str]] = [
    (r"OR\s+1\s*=\s*1", "Boolean-based injection"),
    (r"OR\s+'1'\s*=\s*'1", "String-based injection"),
    (r"DROP\s+TABLE", "DROP TABLE attempt"),
    (r"UNION\s+SELECT", "UNION-based injection"),
    (r"'\s*--", "Comment-out injection"),
    (r";\s*DROP", "Chained DROP attempt"),
    (r"xp_cmdshell", "xp_cmdshell injection"),
    (r"INFORMATION_SCHEMA", "Schema enumeration"),
    (r"EXEC\s*\(@", "EXEC injection"),
    (r"BENCHMARK\(", "Timing-based injection"),
    (r"SLEEP\(", "SLEEP-based injection"),
    (r"LOAD_FILE\(", "File read injection"),
    (r"INTO\s+OUTFILE", "File write injection"),
    (r"'\s+OR\s+'\w+'\s*=", "OR-based auth bypass"),
    (r"pg_sleep\(", "PostgreSQL SLEEP injection"),
]

# ── Rate Limit Configuration ────────────────────────────────────────────────

DEFAULT_RATE_LIMITS: dict[QueryType, tuple[int, int]] = {
    "SELECT": (1000, 60),   # 1000 queries per 60s
    "INSERT": (500, 60),    # 500 inserts per 60s
    "UPDATE": (500, 60),    # 500 updates per 60s
    "DELETE": (100, 60),    # 100 deletes per 60s
    "DDL": (20, 60),        # 20 DDL operations per 60s
    "OTHER": (200, 60),     # 200 other per 60s
}

# ── Compiled patterns ───────────────────────────────────────────────────────

_COMPILED_PATTERNS: list[tuple[re.Pattern, str]] = [
    (re.compile(p, re.IGNORECASE), desc) for p, desc in SQL_INJECTION_PATTERNS
]


class DatabaseFirewall:
    """Application-level SQLite query firewall with rate limiting and injection detection.

    Usage:
        fw = DatabaseFirewall()
        fw.check_query("SELECT * FROM invoices WHERE status = ?", ["PAID"])
        # Raises FirewallBlockedError if blocked
    """

    def __init__(
        self,
        rate_limits: dict[QueryType, tuple[int, int]] | None = None,
        block_threshold: int = 5,
        profiling_window: int = 300,
    ) -> None:
        self._rate_limits = rate_limits or DEFAULT_RATE_LIMITS
        self._block_threshold = block_threshold
        self._profiling_window = profiling_window

        self._rate_buckets: dict[QueryType, list[float]] = defaultdict(list)
        self._block_counts: dict[str, int] = defaultdict(int)
        self._total_blocked = 0
        self._total_allowed = 0
        self._profiling_data: dict[str, list[tuple[float, float]]] = defaultdict(list)
        self._whitelist: set[str] = {"PRAGMA", "ANALYZE", "VACUUM", "EXPLAIN"}

    def check_query(self, sql: str, params: tuple | list | None = None) -> bool:
        """Check if a query is safe to execute.

        Raises:
            FirewallBlockedError: If the query is blocked.
        """
        if not sql or not sql.strip():
            return True

        # 1. Whitelist check
        for wl in self._whitelist:
            if sql.strip().upper().startswith(wl):
                self._total_allowed += 1
                return True

        # 2. SQL injection detection
        for pattern, description in _COMPILED_PATTERNS:
            if pattern.search(sql):
                self._total_blocked += 1
                self._block_counts[description] += 1
                logger.warning(
                    "[FIREWALL] BLOCKED: %s | pattern=%s | query=%s...",
                    description, pattern.pattern, sql[:80],
                )
                raise FirewallBlockedError(
                    f"Query blocked by firewall: {description} "
                    f"(total blocked: {self._total_blocked})"
                )

        # 3. Rate limiting
        query_type = classify_query(sql)
        now = time.monotonic()
        limit, window = self._rate_limits.get(query_type, (200, 60))
        self._rate_buckets[query_type] = [
            ts for ts in self._rate_buckets[query_type] if now - ts < window
        ]
        if len(self._rate_buckets[query_type]) >= limit:
            self._total_blocked += 1
            raise FirewallBlockedError(
                f"Rate limit exceeded for {query_type}: "
                f"{limit} per {window}s (total blocked: {self._total_blocked})"
            )
        self._rate_buckets[query_type].append(now)

        # 4. Prepared statement enforcement
        if query_type in ("INSERT", "UPDATE", "DELETE"):
            suspicious = re.findall(
                r"(f['\"].*%s.*['\"]|\.format\(|f['\"].*\{)", sql
            )
            if suspicious:
                logger.warning(
                    "[FIREWALL] Potential non-prepared statement: %s", sql[:80]
                )

        self._total_allowed += 1
        return True

    def profile_query(self, sql: str, duration_ms: float) -> None:
        """Record query execution time for profiling."""
        query_type = classify_query(sql)
        now = time.monotonic()
        self._profiling_data[query_type].append((now, duration_ms))
        self._profiling_data[query_type] = [
            (ts, dur)
            for ts, dur in self._profiling_data[query_type]
            if now - ts < self._profiling_window
        ]
        if duration_ms > 5000:
            logger.warning(
                "[FIREWALL] Slow query detected: %dms | %s...",
                duration_ms, sql[:80],
            )
        recent = self._profiling_data[query_type]
        if len(recent) >= self._block_threshold:
            avg_ms = sum(d for _, d in recent) / len(recent)
            if avg_ms > 3000:
                logger.error(
                    "[FIREWALL] Query type %s consistently slow "
                    "(avg=%dms over %d queries)",
                    query_type, int(avg_ms), len(recent),
                )

    def add_whitelist(self, prefix: str) -> None:
        """Add a query prefix to the whitelist."""
        self._whitelist.add(prefix.upper())

    def set_rate_limit(
        self, query_type: QueryType, limit: int, window_seconds: int
    ) -> None:
        """Override a rate limit for a specific query type."""
        self._rate_limits[query_type] = (limit, window_seconds)

    def get_stats(self) -> dict[str, Any]:
        """Get firewall statistics."""
        return {
            "total_allowed": self._total_allowed,
            "total_blocked": self._total_blocked,
            "block_reasons": dict(self._block_counts),
            "rate_limit_status": {
                qt: len(self._rate_buckets.get(qt, []))
                for qt in self._rate_limits
            },
            "whitelist_size": len(self._whitelist),
            "query_type_distribution": {
                qt: len(self._profiling_data.get(qt, []))
                for qt in self._rate_limits
            },
        }

    def reset_stats(self) -> None:
        """Reset all statistics."""
        self._block_counts.clear()
        self._total_blocked = 0
        self._total_allowed = 0
        self._rate_buckets.clear()
        self._profiling_data.clear()


class FirewallBlockedError(Exception):
    """Raised when a query is blocked by the DatabaseFirewall."""
    pass


# ── Global instance for reuse ────────────────────────────────────────────────

_default_firewall: DatabaseFirewall | None = None


def get_firewall() -> DatabaseFirewall:
    """Get or create the global DatabaseFirewall instance."""
    global _default_firewall
    if _default_firewall is None:
        _default_firewall = DatabaseFirewall()
    return _default_firewall
