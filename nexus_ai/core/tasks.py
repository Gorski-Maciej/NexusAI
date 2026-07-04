"""Asynchronous workflow tasks -- re-exports from modular task submodules.

Task submodules:
    tasks/invoice.py   -- OCR pipeline, invoice state machine, active learning
    tasks/scheduled.py -- cron tasks (backup, depreciation, dunning, watchdog)
    tasks/ml.py        -- model cache, vector store, CPU affinity helpers

Usage:
    from nexus_ai.core.tasks import process_invoice_task, run_daily_dunning_check
"""

# Re-export all symbols from submodules for backward compatibility
from nexus_ai.core.broker import broker  # noqa: F401
from nexus_ai.core.tasks.invoice import (  # noqa: F401
    InvoiceEventPayload,
    InvoiceProcessingMachine,
    _pick_pending_outbox,
    _StateProxy,
    _update_invoice_status,
    process_invoice_task,
    store_active_learning_feedback,
)
from nexus_ai.core.tasks.ml import (  # noqa: F401
    _MODEL_CACHE,
    OCR_INFERENCE_LIMITER,
    TimedModelCache,
    _get_vector_store,
    _simple_features,
    pin_worker_cpu_affinity,
)
from nexus_ai.core.tasks.scheduled import (  # noqa: F401
    _DefaultDunningAIAgent,
    _DefaultEmailProvider,
    _startup,
    cron_post_depreciation,
    execute_monthly_depreciation_task,
    invoice_reconciliation_loop,
    run_daily_dunning_check,
    scheduled_backup_task,
)
