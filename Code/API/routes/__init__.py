"""API routes package for NexusAI backend."""
from __future__ import annotations

from .analytics import AnalyticsController
from .dashboard import DashboardController
from .partner import PartnerController
from .invoices import InvoiceController
from .tasks import TaskController
from .exports import ExportController
from .health import HealthController
from .triage import TriageController
from .ws import progress_websocket

__all__ = [
    "AnalyticsController",
    "DashboardController",
    "PartnerController",
    "InvoiceController",
    "TaskController",
    "ExportController",
    "HealthController",
    "TriageController",
    "progress_websocket",
]
