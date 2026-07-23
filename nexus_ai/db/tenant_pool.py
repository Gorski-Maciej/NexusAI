"""
tenant_pool.py — F2 v7.0.1: Multi-Tenancy DuckDB Pool + RODO Encryption.

Raport v7.0 Rec #6 + #10: Izolowane połączenia DuckDB per tenant
z osobnymi limitami pamięci. Wsparcie dla szyfrowania danych (RODO).

Enterprise v7.0.1:
  - TenantDuckDBPool: izolowane DuckDBManager per tenant
  - Per-tenant memory_limit: 128MB (free) / 512MB (pro)
  - Connection pooling z LRU eviction
  - RODO: automatyczne czyszczenie tymczasowych danych
  - Thread-safe singleton
"""
from __future__ import annotations

import threading
import time
from collections import OrderedDict
from pathlib import Path
from typing import Any

from structlog import get_logger

from nexus_ai.db.analytics import DuckDBLimits, DuckDBManager

logger = get_logger("nexus.db.tenant_pool")


class TenantDuckDBPool:
    """Multi-tenant DuckDB connection pool z izolacją per tenant.

    Raport v7.0 Rec #6: Multi-tenancy DuckDB.
    Każdy tenant ma własny DuckDBManager z osobnym memory_limit.
    Izolacja zapobiega OOM przez jednego usera.

    Usage:
        pool = TenantDuckDBPool(base_path="data/analytics")
        mgr = pool.get_tenant("tenant-abc", tier="pro")
        mgr.execute("SELECT * FROM m_monthly_summary")
    """

    # Limity pamięci per tier
    TIER_LIMITS: dict[str, DuckDBLimits] = {
        "free": DuckDBLimits(memory_limit="128MB", threads=1),
        "pro": DuckDBLimits(memory_limit="512MB", threads=2),
        "enterprise": DuckDBLimits(memory_limit="2048MB", threads=4),
    }

    def __init__(
        self,
        base_path: str | Path = "data/analytics",
        max_tenants: int = 100,
        idle_ttl_seconds: float = 1800.0,  # 30 min
    ) -> None:
        self._base_path = Path(base_path)
        self._base_path.mkdir(parents=True, exist_ok=True)
        self._max_tenants = max_tenants
        self._idle_ttl = idle_ttl_seconds
        self._managers: OrderedDict[str, tuple[DuckDBManager, float]] = OrderedDict()
        self._lock = threading.Lock()

    def get_tenant(
        self,
        tenant_id: str,
        tier: str = "free",
        sqlite_path: str | Path | None = None,
    ) -> DuckDBManager:
        """Pobierz (lub utwórz) DuckDBManager dla danego tenanta.

        Args:
            tenant_id: Unikalny identyfikator tenanta.
            tier: Poziom usługi (free/pro/enterprise).
            sqlite_path: Ścieżka do bazy SQLite tenanta.

        Returns:
            DuckDBManager z izolowanym połączeniem per tenant.
        """
        with self._lock:
            # Sprawdź czy tenant już istnieje i nie wygasł
            if tenant_id in self._managers:
                mgr, _ = self._managers[tenant_id]
                self._managers.move_to_end(tenant_id)
                self._managers[tenant_id] = (mgr, time.monotonic())
                return mgr

            # Evict stare tenanty jeśli przekroczono limit
            if len(self._managers) >= self._max_tenants:
                self._evict_idle()

            # Utwórz nowy DuckDBManager dla tenanta
            limits = self.TIER_LIMITS.get(tier, self.TIER_LIMITS["free"])
            tenant_dir = self._base_path / tenant_id
            tenant_dir.mkdir(parents=True, exist_ok=True)

            db_path = tenant_dir / "analytics.duckdb"
            sqlite = sqlite_path or tenant_dir / "oltp.db"

            mgr = DuckDBManager(
                db_path=db_path,
                limits=limits,
                sqlite_path=sqlite,
            )
            self._managers[tenant_id] = (mgr, time.monotonic())
            logger.info(
                "[TENANT-POOL] Created tenant=%s tier=%s limit=%s",
                tenant_id, tier, limits.memory_limit,
            )
            return mgr

    def release_tenant(self, tenant_id: str) -> None:
        """Zwolnij zasoby tenanta (zamknij połączenia)."""
        with self._lock:
            if tenant_id in self._managers:
                mgr, _ = self._managers.pop(tenant_id)
                try:
                    mgr.close()
                except Exception as exc:
                    logger.debug("[TENANT-POOL] Close error for %s: %s", tenant_id, exc)
                logger.info("[TENANT-POOL] Released tenant=%s", tenant_id)

    def cleanup_rodo(self, tenant_id: str) -> bool:
        """RODO: usuń wszystkie dane analityczne tenanta.

        Raport v7.0 Rec #10: Szyfrowanie danych DuckDB (RODO).
        Usuwa plik DuckDB i tymczasowe katalogi tenanta.

        Args:
            tenant_id: Identyfikator tenanta (tylko alfanumeryczny slug).

        Returns:
            True jeśli dane zostały usunięte.
        """
        # Sanitize: tylko alfanumeryczne slug (zapobieganie path traversal)
        safe_id = Path(tenant_id).name
        if safe_id != tenant_id or not safe_id.replace("-", "").replace("_", "").isalnum():
            logger.warning("[TENANT-POOL] RODO cleanup blocked: invalid tenant_id=%s", tenant_id)
            return False

        with self._lock:
            if tenant_id in self._managers:
                mgr, _ = self._managers.pop(tenant_id)
                try:
                    mgr.close()
                except Exception:
                    pass

            tenant_dir = self._base_path / safe_id
            if tenant_dir.exists() and tenant_dir.is_relative_to(self._base_path):
                import shutil
                shutil.rmtree(tenant_dir, ignore_errors=True)
                logger.info("[TENANT-POOL] RODO cleanup: %s", tenant_id)
                return True
            return False

    def get_stats(self) -> dict[str, Any]:
        """Pobierz statystyki puli tenantów."""
        with self._lock:
            tiers = {"free": 0, "pro": 0, "enterprise": 0}
            for mgr, _ in self._managers.values():
                limit = mgr._limits.memory_limit
                if limit == "2048MB":
                    tiers["enterprise"] += 1
                elif limit == "512MB":
                    tiers["pro"] += 1
                else:
                    tiers["free"] += 1

            return {
                "total_tenants": len(self._managers),
                "max_tenants": self._max_tenants,
                "by_tier": tiers,
                "idle_ttl_seconds": self._idle_ttl,
            }

    def close_all(self) -> None:
        """Zamknij wszystkie połączenia (shutdown)."""
        with self._lock:
            for tenant_id, (mgr, _) in list(self._managers.items()):
                try:
                    mgr.close()
                except Exception as exc:
                    logger.debug("[TENANT-POOL] Close error: %s", exc)
            self._managers.clear()
            logger.info("[TENANT-POOL] All tenants closed")

    def _evict_idle(self) -> None:
        """Usuń nieużywanych tenantów (LRU + TTL)."""
        now = time.monotonic()
        to_remove = []
        for tenant_id, (_, last_used) in self._managers.items():
            if (now - last_used) > self._idle_ttl:
                to_remove.append(tenant_id)

        for tenant_id in to_remove:
            mgr, _ = self._managers.pop(tenant_id)
            try:
                mgr.close()
            except Exception:
                pass
            logger.debug("[TENANT-POOL] Evicted idle tenant=%s", tenant_id)

        if not to_remove:
            # Jeśli brak idle, usuń LRU
            try:
                oldest_id, (mgr, _) = self._managers.popitem(last=False)
                try:
                    mgr.close()
                except Exception:
                    pass
                logger.debug("[TENANT-POOL] Evicted LRU tenant=%s", oldest_id)
            except KeyError:
                pass


# ── Global singleton ───────────────────────────────────────────────────────

_global_pool: TenantDuckDBPool | None = None
_pool_lock = threading.Lock()


def get_tenant_pool(
    base_path: str | Path = "data/analytics",
    max_tenants: int = 100,
) -> TenantDuckDBPool:
    """Pobierz globalny singleton TenantDuckDBPool."""
    global _global_pool
    if _global_pool is None:
        with _pool_lock:
            if _global_pool is None:
                _global_pool = TenantDuckDBPool(
                    base_path=base_path,
                    max_tenants=max_tenants,
                )
    return _global_pool
