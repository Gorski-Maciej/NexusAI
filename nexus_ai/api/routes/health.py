"""Health check endpoints."""
from __future__ import annotations

import os

import anyio
from pathlib import Path
from typing import Any

import pendulum
from litestar import Controller, get
from sqlalchemy import text
from sqlalchemy.orm import Session


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
    async def detailed_health(self, db_session: Session) -> dict[str, Any]:
        """Detailed health status with all component checks."""
        db_ok = True
        pending_outbox = 0
        failed_outbox = 0
        dead_letter_outbox = 0
        users_count = 0

        try:
            users_count = int(db_session.execute(text("SELECT COUNT(*) FROM users")).scalar_one())
            pending_outbox = int(
                db_session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status = 'PENDING'")).scalar_one()
            )
            failed_outbox = int(
                db_session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status = 'FAILED'")).scalar_one()
            )
            dead_letter_outbox = int(
                db_session.execute(text("SELECT COUNT(*) FROM outbox_events WHERE status = 'DEAD_LETTER'")).scalar_one()
            )
        except Exception:
            db_ok = False

        duckdb_ok = await self._duckdb_check()
        nats_ok = await self._nats_check()
        tigerbeetle = await self._tigerbeetle_check()
        audit_chain_ok = await self._audit_chain_check()
        dq_invalid_count = await self._dq_invalid_count()
        schema_drift = await self._schema_drift_status()
        failed_tasks_count = await self._failed_tasks_count()

        # Determine overall status
        critical = [("database", db_ok), ("duckdb", duckdb_ok)]
        all_ok = all(ok for _, ok in critical)

        return {
            "api": "OK" if all_ok else "DEGRADED",
            "version": "1.0.0",
            "timestamp": pendulum.now("UTC").isoformat(),
            "components": {
                "database": {
                    "status": "OK" if db_ok else "ERROR",
                    "details": {
                        "users_count": users_count,
                        "pending_outbox_events": pending_outbox,
                        "failed_outbox_events": failed_outbox,
                        "dead_letter_outbox_events": dead_letter_outbox,
                    },
                },
                "duckdb": {
                    "status": "OK" if duckdb_ok else "ERROR",
                },
                "nats": {
                    "status": "OK" if nats_ok else "ERROR",
                    "url": os.getenv("NEXUS_NATS_URL", "nats://localhost:4222"),
                },
                "tigerbeetle": {
                    "status": tigerbeetle.get("status", "UNKNOWN"),
                    "message": tigerbeetle.get("message", ""),
                },
                "audit_chain": {
                    "status": "OK" if audit_chain_ok else "ERROR",
                },
                "dlq_status": {
                    "failed_tasks_unresolved": failed_tasks_count,
                    "dq_invalid_invoices": dq_invalid_count,
                },
            },
            "schema_drift": {
                "status": schema_drift.get("status", "unknown"),
                "issues": schema_drift.get("issues", []),
            },
            "resources": {
                "sqlite_wal_size_bytes": self._sqlite_wal_size(),
            },
            "queue": {
                "pending_tasks": await self._pending_tasks(),
            },
            "reports": {
                "perf_gate_summary_present": self._report_file_exists("reports/performance/perf_gate_summary.json"),
                "security_scan_summary_present": self._report_file_exists("reports/security_scan_summary.json"),
            },
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
    def _sqlite_wal_size(self) -> int:
        wal_path = "nexus_oltp.db-wal"
        return os.path.getsize(wal_path) if os.path.exists(wal_path) else 0

    def _report_file_exists(self, path: str) -> bool:
        return Path(path).exists()

    async def _tigerbeetle_check(self) -> dict[str, Any]:
        """Check TigerBeetle connection."""
        try:
            from nexus_ai.services.tigerbeetle.client import TigerBeetleClient
            client = TigerBeetleClient()
            try:
                accounts = client.lookup_accounts([])
                return {
                    "status": "OK" if accounts is not None else "ERROR",
                    "message": f"Connected, accounts_found={len(accounts) if accounts else 0}" if accounts is not None else "No response",
                }
            except Exception as exc:
                return {"status": "ERROR", "message": str(exc)}
            finally:
                try:
                    client.close()
                except Exception:
                    pass
        except ImportError:
            return {"status": "NOT_INSTALLED", "message": "TigerBeetle client not available"}
        except Exception as exc:
            return {"status": "ERROR", "message": str(exc)}
    async def _failed_tasks_count(self) -> int:
        """Count unresolved failed tasks in DLQ."""
        try:
            from core.config import AppConfig
            from db.database import create_oltp_engine

            cfg = AppConfig()
            engine = create_oltp_engine(cfg)
            try:
                with engine.connect() as conn:
                    result = conn.execute(
                        text("SELECT COUNT(*) FROM failed_tasks WHERE resolved = 0")
                    )
                    return int(result.scalar() or 0)
            finally:
                engine.dispose()
        except Exception:
            return -1

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
                return verify_schema_drift(engine, cfg.base_dir / "app_data" / "schema_baseline.json")
            finally:
                engine.dispose()
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

    async def _duckdb_check(self) -> bool:
        """Check DuckDB (OLAP) availability."""
        try:
            from core.config import AppConfig
            from db.analytics import DuckDBManager
            cfg = AppConfig()
            manager = DuckDBManager(db_path=cfg.duckdb_path, sqlite_path=cfg.sqlite_path, read_only=True)
            try:
                result = manager.execute("SELECT 1")
                return bool(result)
            finally:
                manager.close()
        except Exception:
            return False

    async def _nats_check(self) -> bool:
        """Check NATS connection."""
        nats_url = os.getenv("NEXUS_NATS_URL", "nats://localhost:4222")
        try:
            from nats.aio.client import Client as NatsClient
            nc = NatsClient()
            try:
                with anyio.fail_after(5):
                    await nc.connect(nats_url, connect_timeout=3)
                await nc.close()
                return True
            except Exception:
                return False
        except ImportError:
            return False
        except Exception:
            return False



class HealthControllerV2(HealthController):
    """Health endpoints in v2 namespace."""

    path = "/api/v2/health"
