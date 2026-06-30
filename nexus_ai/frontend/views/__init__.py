"""NexusAI Flet views."""

from nexus_ai.frontend.views.daily_briefing import DailyBriefingView
from nexus_ai.frontend.views.dashboard import DashboardView
from nexus_ai.frontend.views.invoice_detail_view import InvoiceDetailView
from nexus_ai.frontend.views.invoice_list_view import InvoiceListView
from nexus_ai.frontend.views.partner_hub import PartnerHubView
from nexus_ai.frontend.views.task_monitor import TaskMonitorView
from nexus_ai.frontend.views.ui_triage import UITriageView

__all__ = [
    "DashboardView",
    "InvoiceListView",
    "InvoiceDetailView",
    "TaskMonitorView",
    "DailyBriefingView",
    "PartnerHubView",
    "UITriageView",
]
