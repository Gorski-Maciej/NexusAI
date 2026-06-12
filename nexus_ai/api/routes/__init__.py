"""API routes package for NexusAI backend."""

from __future__ import annotations

from .analytics import AnalyticsController
from .dashboard import DashboardController
from .dlq import DLQController
from .exports import ExportController
from .health import HealthController
from .invoices import InvoiceController
from .partner import PartnerController
from .tasks import TaskController
from .triage import TriageController
from .ws import progress_sse

__all__ = [
    "AnalyticsController",
    "DashboardController",
    "PartnerController",
    "InvoiceController",
    "TaskController",
    "ExportController",
    "HealthController",
    "TriageController",
    "DLQController",
    "progress_sse",
]
