"""API routes package for NexusAI backend.

This module exports all route controllers used in the Litestar application.
Each controller is registered in app.py within the appropriate versioned router.
"""

from __future__ import annotations

from nexus_ai.api.pdf_endpoints import PDFController
from nexus_ai.api.routes.admin import AdminController
from nexus_ai.api.routes.analytics import AnalyticsController
from nexus_ai.api.routes.auth import AuthController
from nexus_ai.api.routes.autopilot import AutopilotController
from nexus_ai.api.routes.billing import BillingController
from nexus_ai.api.routes.system_ops import CircuitBreakerController
from nexus_ai.api.routes.dashboard import DashboardController
from nexus_ai.api.routes.dlq import DLQController
from nexus_ai.api.routes.exports import ExportController
from nexus_ai.api.routes.files import FileController
from nexus_ai.api.routes.system_ops import FinOpsController
from nexus_ai.api.routes.health import HealthController
from nexus_ai.api.routes.system_ops import I18nOpsController
from nexus_ai.api.routes.invoices import InvoiceController
from nexus_ai.api.routes.system_ops import KoreAuditController
from nexus_ai.api.routes.kore_closure import KoreClosureController
from nexus_ai.api.routes.ksef import KsefController
from nexus_ai.api.routes.live_preview import LivePreviewController
from nexus_ai.api.routes.outbox_ops import OutboxOpsController
from nexus_ai.api.routes.partner import PartnerController
from nexus_ai.api.routes.performance_ops import PerformanceOpsController
from nexus_ai.api.routes.system_ops import PrivacyController
from nexus_ai.api.routes.risk import RiskController
from nexus_ai.api.routes.system_ops import SecurityPostureController
from nexus_ai.api.routes.stats import StatsController
from nexus_ai.api.routes.system_integrity import SystemIntegrityController
from nexus_ai.api.routes.tasks import TaskController
from nexus_ai.api.routes.tax_math import TaxMathController
from nexus_ai.api.routes.tax_policy import TaxPolicyController
from nexus_ai.api.routes.system_ops import TelemetryOpsController
from nexus_ai.api.routes.triage import TriageController
from nexus_ai.api.routes.ui_state import UIStateController
from nexus_ai.api.routes.system_ops import VersionController
from nexus_ai.api.routes.workers import WorkerStatusController
from nexus_ai.api.routes.ws import progress_sse

__all__ = [
    "AdminController",
    "AnalyticsController",
    "AuthController",
    "AutopilotController",
    "BillingController",
    "CircuitBreakerController",
    "DashboardController",
    "DLQController",
    "ExportController",
    "FileController",
    "FinOpsController",
    "HealthController",
    "I18nOpsController",
    "InvoiceController",
    "KoreAuditController",
    "KoreClosureController",
    "KsefController",
    "LivePreviewController",
    "OutboxOpsController",
    "PDFController",
    "PartnerController",
    "PerformanceOpsController",
    "PrivacyController",
    "RiskController",
    "SecurityPostureController",
    "StatsController",
    "SystemIntegrityController",
    "TaskController",
    "TaxMathController",
    "TaxPolicyController",
    "TelemetryOpsController",
    "TriageController",
    "UIStateController",
    "VersionController",
    "WorkerStatusController",
    "progress_sse",
]
