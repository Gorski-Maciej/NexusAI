"""Health check endpoints."""
from __future__ import annotations

from typing import Any
import os
from pathlib import Path
from litestar import Controller, get
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class HealthController(Controller):
    """Health check and status endpoints."""
    path = "/api/v1/health"

    @get("")
    async def health_check(self) -> dict[str, str]:
        """Basic health check."""
        return {"status": "OK", "version": "1.0.0"}

    @get("/live")
    async def liveness_probe(self) -> dict[str, str]:
        """Kubernetes liveness probe."""
        return {"status": "alive"}

    @get("/ready")
    async def readiness_probe(self) -> dict[str, str]:
        """Kubernetes readiness probe."""
        return {"status": "ready"}

    @get("/detailed")
    async def detailed_health(self, db_session: AsyncSession) -> dict[str, Any]:
        """Detailed health status."""
        db_ok = True
        pending_outbox = 0
        failed_outbox = 0
        dead_letter_outbox = 0
        users_count = 0

        try:
            users_count = int((await db_session.execute(text("SELECT COUNT(*) FROM users"))).scalar_one())
            pending_outbox = int(
                (await db_session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status = 'PENDING'"))).scalar_one()
            )
            failed_outbox = int(
                (await db_session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status = 'FAILED'"))).scalar_one()
            )
            dead_letter_outbox = int(
                (await db_session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status = 'DEAD_LETTER'"))).scalar_one()
            )
        except Exception:
            db_ok = False

        duckdb_ok = await self._duckdb_check()
        nats_ok = await self._nats_check()
        audit_chain_ok = await self._audit_chain_check()
        dq_invalid_count = await self._dq_invalid_count()
        schema_drift = await self._schema_drift_status()

        return {
            "api": "OK" if (db_ok and duckdb_ok) else "DEGRADED",
            "version": "1.0.0",
            "database": "OK" if db_ok else "ERROR",
            "duckdb": "OK" if duckdb_ok else "ERROR",
            "nats": "OK" if nats_ok else "ERROR",
            "audit_chain": "OK" if audit_chain_ok else "ERROR",
            "users_count": users_count,
            "pending_outbox_events": pending_outbox,
            "failed_outbox_events": failed_outbox,
            "dead_letter_outbox_events": dead_letter_outbox,
            "dq_invalid_invoices": dq_invalid_count,
            "schema_drift_status": schema_drift.get("status", "unknown"),
            "schema_drift_issues": schema_drift.get("issues", []),
            "gpu_available": self._gpu_available(),
            "vram_free_mb": self._vram_free_mb(),
            "sqlite_wal_size": self._sqlite_wal_size(),
            "pending_tasks": await self._pending_tasks(),
            "perf_gate_summary_present": self._report_file_exists("reports/performance/perf_gate_summary.json"),
            "security_scan_summary_present": self._report_file_exists("reports/security_scan_summary.json"),
        }

    async def _pending_tasks(self) -> int | None:
        try:
            from api.tasks import broker

            queue_size = getattr(broker, "queue_size", None)
            if queue_size is None:
                return None
            result = queue_size()
            if hasattr(result, "__await__"):
                result = await result
            return int(result)
        except Exception:
            return None

    def _gpu_available(self) -> bool:
        try:
            import torch

            return bool(torch.cuda.is_available())
        except Exception:
            return False

    def _vram_free_mb(self) -> float:
        try:
            import torch

            if not torch.cuda.is_available():
                return 0.0
            free_bytes, _ = torch.cuda.mem_get_info()
            return round(float(free_bytes) / (1024**2), 2)
        except Exception:
            return 0.0

    def _sqlite_wal_size(self) -> int:
        wal_path = "nexus_oltp.db-wal"
        return os.path.getsize(wal_path) if os.path.exists(wal_path) else 0

    def _report_file_exists(self, path: str) -> bool:
        return Path(path).exists()


    async def _audit_chain_check(self) -> bool:
        try:
            from core.config import AppConfig
            from db.analytics import DuckDBManager
            from services.audit_logger import AuditLogger

            cfg = AppConfig()
            manager = DuckDBManager(db_path=cfg.duckdb_path, sqlite_path=cfg.sqlite_path, read_only=True)
            try:
                valid, _ = AuditLogger(manager).verify_chain()
                return bool(valid)
            finally:
                manager.close()
        except Exception:
            return False

    async def _schema_drift_status(self) -> dict[str, Any]:
        try:
            from core.config import AppConfig
            from db.database import create_oltp_engine
            from services.migration_sanity import verify_schema_drift

            cfg = AppConfig()
            engine = create_oltp_engine(cfg)
            try:
                return await verify_schema_drift(engine, cfg.base_dir / "app_data" / "schema_baseline.json")
            finally:
                await engine.dispose()
        except Exception:
            return {"status": "error", "issues": ["schema drift check failed"]}

    async def _dq_invalid_count(self) -> int:
        try:
            from core.config import AppConfig
            from db.analytics import DuckDBManager

            cfg = AppConfig()
            manager = DuckDBManager(db_path=cfg.duckdb_path, sqlite_path=cfg.sqlite_path, read_only=True)
            try:
                result = manager.execute("SELECT COUNT(*) FROM dq_invalid_invoices")
                return int(result[0][0]) if result else 0
            finally:
                manager.close()
        except Exception:
            return -1



class HealthControllerV2(HealthController):
    """Health endpoints in v2 namespace."""

    path = "/api/v2/health"
