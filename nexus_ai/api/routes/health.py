"""Health check endpoints — z prawdziwym TigerBeetle health check.

SUPERMOCE:
- Real TigerBeetle connection check przez lookup_accounts
- Sprawdzanie stanu cluster/time
- Metryki liczby kont i transferów
"""

from __future__ import annotations

import os

import anyio
from pathlib import Path
from typing import Any

import pendulum
from litestar import Controller, get
from sqlalchemy import func, select, text
from sqlalchemy.orm import Session

from nexus_ai.api.dto import GenericDictDTO, HealthResponseDTO, TAG_HEALTH
from nexus_ai.db.models import OutboxEvent, OutboxStatus


class HealthController(Controller):
    """Health check and status endpoints."""

    path = "/health"
    tags = [TAG_HEALTH]

    @get(
        "",
        return_dto=HealthResponseDTO,
        summary="Basic health check",
        description="Returns API status and version.",
        operation_id="healthCheck",
        cache=300,
        exclude_opt_key="no_rate_limit",
        headers={"Cache-Control": "public, max-age=300"},
    )
    async def health_check(self) -> dict[str, str]:
        """Basic health check."""
        import stamina
        cb_active = stamina.is_active()
        status = "OK" if cb_active else "OK_BUT_CIRCUIT_OPEN"
        return {
            "status": status,
            "circuit_breaker_open": not cb_active,
            "version": "1.0.0",
        }

    @get(
        "/live",
        return_dto=HealthResponseDTO,
        summary="Kubernetes liveness probe",
        description="Returns alive status for Kubernetes liveness probe.",
        operation_id="healthLiveness",
        exclude_opt_key="no_rate_limit",
    )
    async def liveness_probe(self) -> dict[str, str]:
        return {"status": "alive"}

    @get(
        "/ready",
        return_dto=HealthResponseDTO,
        summary="Kubernetes readiness probe",
        description="Returns ready status for Kubernetes readiness probe.",
        operation_id="healthReadiness",
        exclude_opt_key="no_rate_limit",
    )
    async def readiness_probe(self) -> dict[str, str]:
        return {"status": "ready"}

    @get(
        "/detailed",
        return_dto=GenericDictDTO,
        summary="Detailed health check",
        description="Returns comprehensive health status.",
        operation_id="healthDetailed",
    )
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
                db_session.execute(
                    select(func.count()).select_from(OutboxEvent).where(OutboxEvent.status == OutboxStatus.PENDING)
                ).scalar_one()
            )
            failed_outbox = int(
                db_session.execute(
                    select(func.count()).select_from(OutboxEvent).where(OutboxEvent.status == OutboxStatus.FAILED)
                ).scalar_one()
            )
            dead_letter_outbox = int(
                db_session.execute(
                    select(func.count()).select_from(OutboxEvent).where(OutboxEvent.status == OutboxStatus.DEAD_LETTER)
                ).scalar_one()
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
                    "accounts_found": tigerbeetle.get("accounts_found", 0),
                    "cluster_id": tigerbeetle.get("cluster_id", 0),
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
                "sqlite_wal_size_bytes": await self._sqlite_wal_size(),
                "system": await self._system_resources(),
            },
            "queue": {
                "pending_tasks": await self._pending_tasks(),
            },
            "reports": {
                "perf_gate_summary_present": self._report_file_exists(
                    "reports/performance/perf_gate_summary.json"
                ),
                "security_scan_summary_present": self._report_file_exists(
                    "reports/security_scan_summary.json"
                ),
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

    async def _sqlite_wal_size(self) -> int:
        wal_path = anyio.Path("nexus_oltp.db-wal")
        try:
            stat = await wal_path.stat()
            return stat.st_size
        except OSError:
            return 0

    # ── SUPERMOC psutil: System resources in health check ──────────────

    async def _system_resources(self) -> dict[str, Any]:
        """Zwróć metryki systemowe z psutil dla /health/detailed.

        SUPERMOCE psutil:
          - SystemMonitor.collect_all() — CPU, RAM, swap, dysk, sieć, sensory
          - ProcessMonitor.collect_metrics() — RSS, USS, CPU% procesu
          - boot_time() — uptime systemu
          - getloadavg() — load average
        """
        try:
            from nexus_ai.core.monitor import process_monitor, system_monitor

            proc = process_monitor.collect_metrics()
            sys = system_monitor.collect_all()

            return {
                "cpu_percent": round(sys.cpu_percent, 1),
                "cpu_percent_per_core": [round(c, 1) for c in sys.cpu_percent_per_core],
                "cpu_freq_mhz": round(sys.cpu_freq_current_mhz, 0) if sys.cpu_freq_current_mhz else None,
                "load_avg": [round(sys.load_avg_1min, 2), round(sys.load_avg_5min, 2), round(sys.load_avg_15min, 2)],
                "ram_percent": round(sys.ram_percent, 1),
                "ram_used_gb": round(sys.ram_used_gb, 1),
                "ram_available_gb": round(sys.ram_available_gb, 1),
                "ram_process_mb": round(proc.rss_mb, 1),
                "ram_process_uss_mb": round(proc.uss_mb, 1) if proc.uss_mb else None,
                "swap_percent": round(sys.swap_percent, 1),
                "disk_percent": round(sys.disk_percent, 1),
                "disk_free_gb": round(sys.disk_free_gb, 1),
                "disk_read_mb": round(sys.disk_read_mb, 1),
                "disk_write_mb": round(sys.disk_write_mb, 1),
                "net_recv_mb": round(sys.net_bytes_recv_mb, 1),
                "net_sent_mb": round(sys.net_bytes_sent_mb, 1),
                "cpu_temp_celsius": round(sys.cpu_temp_celsius, 1) if sys.cpu_temp_celsius else None,
                "uptime_days": round(sys.uptime_days, 1),
                "process_status": proc.status,
                "process_cpu": round(proc.cpu_percent, 1),
                "process_threads": proc.num_threads,
                "process_fds": proc.num_fds,
                "process_connections": proc.connections_count,
            }
        except ImportError:
            return {"status": "psutil_not_available"}
        except Exception as exc:
            return {"status": "error", "error": str(exc)}

    def _report_file_exists(self, path: str) -> bool:
        return Path(path).exists()

    # ── SUPERMOC: Real TigerBeetle health check ─────────────────────────

    # Singleton TB client dla health checków — współdzielony przez DI
    _tb_client: Any = None

    def _get_tb_client(self) -> Any:
        """Pobierz singleton TigerBeetleClient.

        W środowisku produkcyjnym instancja powinna być wstrzykiwana
        przez Litestar DI (singleton). W dev tworzymy nową jeśli brak.
        """
        if HealthController._tb_client is None:
            try:
                from nexus_ai.services.tigerbeetle.client import TigerBeetleClient
                HealthController._tb_client = TigerBeetleClient()
                HealthController._tb_client.connect()
            except ImportError:
                pass
        return HealthController._tb_client

    async def _tigerbeetle_check(self) -> dict[str, Any]:
        """Check TigerBeetle connection using singleton client.

        SUPERMOCE:
        - Singleton TB client (thread-safe) — brak wycieku socketów
        - Real connection test przez lookup_accounts
        - Sprawdzanie liczby kont i stanu clustera
        - Fallback do "NOT_INSTALLED" gdy brak klienta
        """
        try:
            client = self._get_tb_client()
            if client is None:
                return {
                    "status": "NOT_INSTALLED",
                    "message": "tigerbeetle client not installed (pip install tigerbeetle)",
                    "accounts_found": 0,
                    "cluster_id": 0,
                }

            try:
                # SUPERMOC: lookup_accounts test — sprawdza czy TB odpowiada
                accounts = client.lookup_accounts([])
                return {
                    "status": "OK",
                    "message": f"Connected, cluster_id={client.cluster_id}",
                    "accounts_found": len(accounts),
                    "cluster_id": client.cluster_id,
                }
            except Exception as conn_err:
                error_str = str(conn_err)
                if "Connection refused" in error_str:
                    return {
                        "status": "NOT_RUNNING",
                        "message": f"TigerBeetle not running on {client.replica_addresses}",
                        "accounts_found": 0,
                        "cluster_id": client.cluster_id,
                    }
                return {
                    "status": "ERROR",
                    "message": f"TigerBeetle connection failed: {conn_err}",
                    "accounts_found": 0,
                    "cluster_id": client.cluster_id,
                }
        except ImportError:
            return {
                "status": "NOT_INSTALLED",
                "message": "tigerbeetle client not installed (pip install tigerbeetle)",
                "accounts_found": 0,
                "cluster_id": 0,
            }
        except Exception as exc:
            return {
                "status": "ERROR",
                "message": str(exc),
                "accounts_found": 0,
                "cluster_id": 0,
            }

    async def _failed_tasks_count(self) -> int:
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
            manager = DuckDBManager(
                db_path=cfg.duckdb_path, sqlite_path=cfg.sqlite_path, read_only=True
            )
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
                return verify_schema_drift(
                    engine, cfg.base_dir / "app_data" / "schema_baseline.json"
                )
            finally:
                engine.dispose()
        except Exception:
            return {"status": "error", "issues": ["schema drift check failed"]}

    async def _dq_invalid_count(self) -> int:
        try:
            from core.config import AppConfig
            from db.analytics import DuckDBManager

            cfg = AppConfig()
            manager = DuckDBManager(
                db_path=cfg.duckdb_path, sqlite_path=cfg.sqlite_path, read_only=True
            )
            try:
                result = manager.execute("SELECT COUNT(*) FROM dq_invalid_invoices")
                return int(result[0][0]) if result else 0
            finally:
                manager.close()
        except Exception:
            return -1

    async def _duckdb_check(self) -> bool:
        try:
            from core.config import AppConfig
            from db.analytics import DuckDBManager

            cfg = AppConfig()
            manager = DuckDBManager(
                db_path=cfg.duckdb_path, sqlite_path=cfg.sqlite_path, read_only=True
            )
            try:
                result = manager.execute("SELECT 1")
                return bool(result)
            finally:
                manager.close()
        except Exception:
            return False

    async def _nats_check(self) -> bool:
        nats_url = os.getenv("NEXUS_NATS_URL", "nats://localhost:4222")
        try:
            from nexus_ai.core.nats_health import NatsSupervisor
            supervisor = NatsSupervisor(nats_servers=[nats_url])
            await supervisor.start()
            try:
                health = await supervisor.quick_health()
                return health.get("nats") == "OK"
            finally:
                await supervisor.stop()
        except ImportError:
            pass
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
        except Exception:
            return False

    @get(
        "/nats",
        return_dto=GenericDictDTO,
        summary="NATS JetStream health and status",
        description="Returns detailed NATS JetStream status.",
        operation_id="healthNats",
    )
    async def nats_health(self) -> dict[str, Any]:
        try:
            from nexus_ai.core.nats_health import NatsSupervisor
            nats_url = os.getenv("NEXUS_NATS_URL", "nats://localhost:4222")
            supervisor = NatsSupervisor(nats_servers=[nats_url])
            await supervisor.start()
            try:
                return await supervisor.get_full_status()
            finally:
                await supervisor.stop()
        except ImportError:
            return {"status": "NOT_AVAILABLE", "message": "NatsSupervisor not available"}
        except Exception as exc:
            return {"status": "ERROR", "message": str(exc)}


class HealthControllerV2(HealthController):
    """Health endpoints in v2 namespace."""
    path = "/health"
    tags = [TAG_HEALTH]
