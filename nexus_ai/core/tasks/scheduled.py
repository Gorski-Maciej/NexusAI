"""Scheduled/cron tasks — backup, depreciation, dunning, watchdog."""

from __future__ import annotations

from pathlib import Path

import pendulum
from sqlmodel import Session, select
from taskiq import Kicker, TaskiqDepends, TaskiqEvents

from nexus_ai.core.backup import BackupManager
from nexus_ai.core.broker import broker
from nexus_ai.core.config import AppConfig
from nexus_ai.core.di import get_config, get_db_session, get_duckdb_manager
from nexus_ai.core.logger import get_logger
from nexus_ai.core.tasks.ml import pin_worker_cpu_affinity
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.models import Invoice, InvoiceStatus
from nexus_ai.services.dunning_engine import DunningEngine
from nexus_ai.services.fixed_assets import FixedAssetsService
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

logger = get_logger()


@broker.on_event(TaskiqEvents.WORKER_STARTUP)
async def _startup(_state):
    pin_worker_cpu_affinity(reserve_core0=True)


@broker.task(
    schedule=[{"cron": "0 16 * * *"}],
    labels={"service": "core", "operation": "backup", "criticality": "high", "schedule": "daily"},
    timeout=600.0,
)
async def scheduled_backup_task(
    config: AppConfig = TaskiqDepends(get_config),  # noqa: B008
):
    manager = BackupManager(config)
    path = manager.create_encrypted_zip(config.encryption_key)
    logger.info(f"Backup wykonany pomyślnie: {path}")


@broker.task(
    schedule=[{"cron": "55 23 28-31 * *"}],
    task_name="cron_post_depreciation",
    labels={
        "service": "core",
        "operation": "depreciation",
        "criticality": "high",
        "schedule": "monthly",
    },
    timeout=120.0,
)
async def cron_post_depreciation(
    duckdb: DuckDBManager = TaskiqDepends(get_duckdb_manager),  # noqa: B008
) -> dict[str, int | str]:
    today = pendulum.now("UTC").date()
    if (today + pendulum.duration(days=1)).month == today.month:
        return {"result": "SKIPPED_NOT_MONTH_END", "posted": 0}
    tigerbeetle = TigerBeetleClient()
    service = FixedAssetsService(duckdb=duckdb, tigerbeetle=tigerbeetle)
    posted = await service.execute_monthly_depreciation(as_of=today)
    return {"result": "OK", "posted": posted}


@broker.task(
    schedule=[{"cron": "*/5 * * * *"}],
    labels={
        "service": "core",
        "operation": "watchdog",
        "criticality": "high",
        "schedule": "5min",
    },
    timeout=60.0,
)
async def invoice_reconciliation_loop(
    db: Session = TaskiqDepends(get_db_session),  # noqa: B008
):
    logger.info("[Watchdog] Uruchamianie skanowania spójności...")
    timeout_threshold = pendulum.now("UTC") - pendulum.duration(minutes=10)
    stmt = select(Invoice).where(
        Invoice.status == InvoiceStatus.PROCESSING,
        Invoice.updated_at <= timeout_threshold,
    )
    stuck_invoices = db.execute(stmt).scalars().all()
    if not stuck_invoices:
        logger.debug("[Watchdog] System w pełni spójny.")
        return

    for invoice in stuck_invoices:
        if invoice.retry_count < 3:
            logger.warning(
                "[Watchdog] Faktura %s utknęła. Próba %d/3.",
                invoice.id,
                invoice.retry_count + 1,
            )
            invoice.retry_count += 1
            invoice.updated_at = pendulum.now("UTC")
            await (
                Kicker("process_invoice_task", broker=broker)
                .with_task_id(f"watchdog_recover:{invoice.id}:{invoice.retry_count}")
                .with_labels({"is_retry": "true", "invoice_id": invoice.id})
                .kiq()
            )
        else:
            logger.error("[Watchdog] Faktura %s trwale uszkadza Workera.", invoice.id)
            invoice.status = InvoiceStatus.ERROR_TIMEOUT
            invoice.updated_at = pendulum.now("UTC")


class _DefaultDunningAIAgent:
    __slots__ = ()

    def generate_dunning_text(
        self, invoice_data: dict, vendor_score: float, level: int
    ) -> str:
        tone = "uprzejmy" if vendor_score >= 0.8 else "stanowczy"
        return (
            f"To automatyczne przypomnienie ({tone}, poziom {level}) "
            f"dla faktury {invoice_data['invoice_number']} "
            f"na kwotę {invoice_data['balance_due']:.2f} PLN. "
            f"Zaległość: {invoice_data['days_overdue']} dni."
        )


class _DefaultEmailProvider:
    __slots__ = ()

    def send(self, *, to_email: str, subject: str, body: str) -> bool:
        if not to_email:
            return False
        logger.info("[Dunning] Wysyłka email to=%s subject=%s", to_email, subject)
        return True


@broker.task(
    task_name="run_daily_dunning_check",
    schedule=[{"cron": "0 9 * * *"}],
    labels={
        "service": "core",
        "operation": "dunning",
        "criticality": "medium",
        "schedule": "daily",
    },
    timeout=300.0,
)
async def run_daily_dunning_check() -> dict[str, int]:
    config = AppConfig(base_dir=Path.cwd())
    duckdb = DuckDBManager(config.duckdb_path)
    engine = DunningEngine(
        duckdb_manager=duckdb,
        ai_agent=_DefaultDunningAIAgent(),
        email_provider=_DefaultEmailProvider(),
    )
    return await engine.run_daily_dunning_check()


@broker.task(
    task_name="execute_monthly_depreciation",
    schedule=[{"cron": "0 0 1 * *"}],
    labels={
        "service": "core",
        "operation": "depreciation",
        "criticality": "high",
        "schedule": "monthly",
    },
    timeout=120.0,
)
async def execute_monthly_depreciation_task() -> dict[str, int]:
    duckdb = DuckDBManager(Path("app_data/nexus_olap.duckdb"))
    service = FixedAssetsService(duckdb=duckdb, tigerbeetle=TigerBeetleClient())
    posted = await service.execute_monthly_depreciation()
    logger.info("[FixedAssets] Posted %s depreciation entries", posted)
    return {"posted": posted}
