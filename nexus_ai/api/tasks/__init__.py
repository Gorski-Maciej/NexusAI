"""
Modular task system -- re-exportuje wszystkie zadania z podmodułów.

FAZA V: Podział api/tasks.py na moduły:
- ocr.py: process_invoice_ocr, process_large_attachment
- decision.py: decision_evaluate, council_decide
- outbox.py: relay_outbox_events, _dispatch_outbox_event
- cron.py: zadania cykliczne (cron/schedule)
- cleanup.py: zadania czyszczenia (cleanup_*)

Wszystkie dekoratory @broker.task są definiowane w podmodułach.
Ten plik re-exportuje + zawiera unikalny kod (sha256, _make_engine, atexit cleanup).
"""

from __future__ import annotations

import atexit
import os
import warnings

from structlog import get_logger

from nexus_ai.core.config import AppConfig
from nexus_ai.db.database import create_oltp_engine

logger = get_logger("nexus.api.tasks")

# ── SHA-256 przez nexus-crypto (Rust+PyO3) ─────────────────────────────────
try:
    from nexus_crypto import sha256 as _sha256
    HAS_NEXUS_CRYPTO = True
except ImportError:
    import hashlib as _hashlib
    HAS_NEXUS_CRYPTO = False

    def _sha256(data: bytes) -> str:
        return _hashlib.sha256(data).hexdigest()


# ── Legacy engine helper ────────────────────────────────────────────────────
def _make_engine(config: AppConfig | None = None):
    """[LEGACY] Utworz SQLAlchemy engine -- do migracji na TaskiqDepends.

    Deprecated: Uzyj TaskiqDepends(get_db_session) zamiast recznego tworzenia engine.
    """
    warnings.warn(
        "_make_engine jest deprecated. Uzyj TaskiqDepends(get_db_session).",
        DeprecationWarning,
        stacklevel=2,
    )
    if config is None:
        config = AppConfig()
    sqlcipher_key = os.getenv(config.sqlcipher_key_env, "").strip()
    return create_oltp_engine(config, sqlcipher_key=sqlcipher_key or None)


# ── Re-exporty z podmodułów ────────────────────────────────────────────────

from nexus_ai.api.tasks.cleanup import (
    cleanup_archived_invoices_task,
    cleanup_expired_refresh_tokens_task,
    cleanup_hard_deleted_invoices_task,
    cleanup_outbox_events_task,
)
from nexus_ai.api.tasks.cron import (
    check_hanging_transactions_task,
    cleanup_duckdb_temp_task,
    cleanup_old_logs_task,
    cleanup_old_reports_task,
    cleanup_temp_upload_files_task,
    daily_briefing_send,
    dead_letter_processor_task,
    finops_hourly_estimate_task,
    flush_otel_fallback_buffer_task,
    log_resilience_states_task,
    migration_integrity_daily_check_task,
    refresh_materialized_cashflow,
    scan_logs_for_pii_task,
    schema_drift_daily_check_task,
    sqlite_weekly_vacuum_task,
    weekly_nip_reverification_task,
)
from nexus_ai.api.tasks.decision import (
    _DECISION_ENGINE,
    _DUCKDB,
    _ensure_decision_engine,
    _escalate_to_human,
    _mark_for_review,
    _post_invoice,
    council_decide,
    decision_evaluate,
)
from nexus_ai.api.tasks.ocr import (
    _build_field_confidence,
    _mark_invoice_blocked,
    _mark_invoice_pending_review,
    _safe_float,
    process_invoice_ocr,
    process_large_attachment,
)
from nexus_ai.api.tasks.outbox import (
    _dispatch_outbox_event,
    relay_outbox_events,
)


def _close_all_components() -> None:
    """Cleanup all singleton components on shutdown."""
    if _DUCKDB is not None:
        try:
            _DUCKDB.close()
        except (ConnectionError, OSError) as exc:
            logger.warning("[TASKS] Error closing DuckDB: %s", exc)
        except Exception as exc:
            logger.error("[TASKS] Unexpected error closing DuckDB: %s", exc)


atexit.register(_close_all_components)


__all__ = [
    "process_invoice_ocr",
    "process_large_attachment",
    "decision_evaluate",
    "council_decide",
    "relay_outbox_events",
    "dead_letter_processor_task",
    "refresh_materialized_cashflow",
    "cleanup_hard_deleted_invoices_task",
    "cleanup_archived_invoices_task",
    "cleanup_outbox_events_task",
    "scan_logs_for_pii_task",
    "finops_hourly_estimate_task",
    "schema_drift_daily_check_task",
    "flush_otel_fallback_buffer_task",
    "migration_integrity_daily_check_task",
    "cleanup_old_logs_task",
    "cleanup_temp_upload_files_task",
    "daily_briefing_send",
    "cleanup_old_reports_task",
    "check_hanging_transactions_task",
    "weekly_nip_reverification_task",
    "sqlite_weekly_vacuum_task",
    "cleanup_duckdb_temp_task",
    "log_resilience_states_task",
    "cleanup_expired_refresh_tokens_task",
    "_ensure_decision_engine",
    "_safe_float",
    "_build_field_confidence",
    "_mark_invoice_blocked",
    "_mark_invoice_pending_review",
    "_post_invoice",
    "_mark_for_review",
    "_escalate_to_human",
    "_dispatch_outbox_event",
    "_DECISION_ENGINE",
    "_DUCKDB",
    "_make_engine",
    "_sha256",
    "HAS_NEXUS_CRYPTO",
]
