"""
DuckDB WASM Memory Guard (Phase 5, P1) — Per-Tenant Memory Limits.
===================================================================

Część planu Phase 5: Legal Hardening Sprint (Kategoria 1: Trudności skalowania).
Problem: DuckDB WASM przy >10 000 faktur może powodować OOM (Out of Memory),
szczególnie przy object.union O(N²) w main_jdg.rego.

Rozwiązanie:
- Limit pamięci 512 MB per tenant (DuckDB memory_limit)
- Limit wątków (threads=4) aby zapobiec CPU exhaustion
- Garbage collection po każdym zapytaniu
- Monitoring: alert przy >80% limitu

Usage:
    guard = WasmMemoryGuard(tenant_id="jdg_12345")
    result = guard.execute("SELECT * FROM invoices WHERE tenant_id = ?", [tenant_id])
"""

from __future__ import annotations

import gc
import logging
import threading
import time
from dataclasses import dataclass
from typing import Any

# TODO(Phase5): Track actual DuckDB memory usage via DuckDB runtime stats
# (e.g., duckdb.query_profile or PRAGMA memory_limit introspection).
# current_usage_mb is currently tracked externally through monitoring;
# the warning/critical thresholds in execute() rely on external updates.

logger = logging.getLogger(__name__)


# ── Configuration ────────────────────────────────────────────────────────────

DEFAULT_MEMORY_LIMIT_MB = 512
DEFAULT_THREAD_LIMIT = 4
MEMORY_WARNING_THRESHOLD = 0.80  # 80% — alert
MEMORY_CRITICAL_THRESHOLD = 0.95  # 95% — reject query


@dataclass
class MemoryStats:
    """Statystyki pamięci per tenant."""
    tenant_id: str
    memory_limit_mb: int
    current_usage_mb: float = 0.0
    peak_usage_mb: float = 0.0
    queries_executed: int = 0
    queries_rejected: int = 0
    last_gc_at: float = 0.0

    @property
    def usage_ratio(self) -> float:
        """Procent wykorzystania limitu."""
        if self.memory_limit_mb == 0:
            return 0.0
        return self.current_usage_mb / self.memory_limit_mb


class WasmMemoryGuard:
    """Guard pamięci dla DuckDB — izolacja per tenant.

    Zapobiega OOM Kill przez:
    1. Ustawienie memory_limit per connection
    2. Limit wątków
    3. Monitoring użycia pamięci
    4. Odrzucanie zapytań gdy >95% limitu
    """

    def __init__(
        self,
        tenant_id: str,
        memory_limit_mb: int = DEFAULT_MEMORY_LIMIT_MB,
        thread_limit: int = DEFAULT_THREAD_LIMIT,
    ) -> None:
        self._tenant_id = tenant_id
        self._memory_limit_mb = memory_limit_mb
        self._thread_limit = thread_limit
        self._stats = MemoryStats(
            tenant_id=tenant_id,
            memory_limit_mb=memory_limit_mb,
        )
        self._lock = threading.Lock()

    def execute(self, query: str, params: list[Any] | None = None) -> list[Any]:
        """Wykonuje zapytanie DuckDB z limitem pamięci per tenant.

        Args:
            query: SQL query do wykonania.
            params: Parametry zapytania (dla prepared statements).

        Returns:
            Lista wyników (fetchall).

        Raises:
            MemoryError: Gdy użycie pamięci >95% limitu.
        """
        import duckdb

        # Sprawdź przed wykonaniem
        if self._stats.usage_ratio > MEMORY_CRITICAL_THRESHOLD:
            self._stats.queries_rejected += 1
            logger.critical(
                f"[WasmGC] TENANT {self._tenant_id}: "
                f"Memory critical ({self._stats.usage_ratio:.0%}) — query REJECTED"
            )
            raise MemoryError(
                f"Tenant {self._tenant_id}: memory usage {self._stats.usage_ratio:.0%} "
                f"exceeds critical threshold {MEMORY_CRITICAL_THRESHOLD:.0%}"
            )

        conn = None
        try:
            conn = duckdb.connect(":memory:")
            conn.execute(f"SET memory_limit='{self._memory_limit_mb}MB'")
            conn.execute(f"SET threads={self._thread_limit}")

            if params:
                result = conn.execute(query, params).fetchall()
            else:
                result = conn.execute(query).fetchall()

            with self._lock:
                self._stats.queries_executed += 1

            # Warning przy >80%
            if self._stats.usage_ratio > MEMORY_WARNING_THRESHOLD:
                logger.warning(
                    f"[WasmGC] TENANT {self._tenant_id}: "
                    f"Memory high ({self._stats.usage_ratio:.0%})"
                )

            return result

        except duckdb.OutOfMemoryException:
            self._stats.queries_rejected += 1
            logger.critical(
                f"[WasmGC] TENANT {self._tenant_id}: OOM — query rejected"
            )
            raise MemoryError(
                f"Tenant {self._tenant_id}: out of memory "
                f"(limit: {self._memory_limit_mb} MB)"
            )
        finally:
            if conn is not None:
                conn.close()
                # Jawna garbage collection
                gc.collect()
                self._stats.last_gc_at = time.time()

    def get_stats(self) -> MemoryStats:
        """Zwraca statystyki pamięci dla tego tenanta."""
        with self._lock:
            return self._stats

    def update_memory_limit(self, new_limit_mb: int) -> None:
        """Aktualizuje limit pamięci (np. dla tenantów premium)."""
        if new_limit_mb < 64:
            raise ValueError(f"Memory limit too low: {new_limit_mb}MB (min 64MB)")
        self._memory_limit_mb = new_limit_mb
        with self._lock:
            self._stats.memory_limit_mb = new_limit_mb
        logger.info(
            f"[WasmGC] TENANT {self._tenant_id}: "
            f"Memory limit updated to {new_limit_mb}MB"
        )


def create_tenant_guard(
    tenant_id: str,
    memory_limit_mb: int = DEFAULT_MEMORY_LIMIT_MB,
) -> WasmMemoryGuard:
    """Factory function dla tworzenia guarda per tenant.

    Usage:
        guard = create_tenant_guard("jdg_12345")
        results = guard.execute("SELECT * FROM invoices")
    """
    return WasmMemoryGuard(
        tenant_id=tenant_id,
        memory_limit_mb=memory_limit_mb,
    )
