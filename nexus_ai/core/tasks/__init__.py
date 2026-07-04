"""Tasks package -- split from monolithic core/tasks.py.

Modules:
    invoice.py   — invoice processing + InvoiceProcessingMachine
    scheduled.py — cron/scheduled tasks (backup, depreciation, dunning, watchdog)
    ml.py        — TimedModelCache, vector store, CPU affinity
"""

from nexus_ai.core.tasks.invoice import (
    InvoiceEventPayload,
    InvoiceProcessingMachine,
    OCR_INFERENCE_LIMITER,
    OCR_TASK_TIMEOUT_SEC,
    process_invoice_task,
    store_active_learning_feedback,
)
from nexus_ai.core.tasks.scheduled import (
    scheduled_backup_task,
    cron_post_depreciation,
    invoice_reconciliation_loop,
    run_daily_dunning_check,
    execute_monthly_depreciation_task,
)
from nexus_ai.core.tasks.ml import (
    TimedModelCache,
    pin_worker_cpu_affinity,
    _get_vector_store,
    _simple_features,
    _MODEL_CACHE,
)

__all__ = [
    "InvoiceEventPayload",
    "InvoiceProcessingMachine",
    "OCR_INFERENCE_LIMITER",
    "OCR_TASK_TIMEOUT_SEC",
    "TimedModelCache",
    "_MODEL_CACHE",
    "_get_vector_store",
    "_simple_features",
    "cron_post_depreciation",
    "execute_monthly_depreciation_task",
    "invoice_reconciliation_loop",
    "pin_worker_cpu_affinity",
    "process_invoice_task",
    "run_daily_dunning_check",
    "scheduled_backup_task",
    "store_active_learning_feedback",
]
