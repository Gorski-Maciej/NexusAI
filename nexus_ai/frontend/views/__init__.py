"""NexusAI Flet views."""

from nexus_ai.frontend.views.daily_briefing import DailyBriefingView
from nexus_ai.frontend.views.dashboard import DashboardView
from nexus_ai.frontend.views.decision_feed import DecisionFeedView
from nexus_ai.frontend.views.invoice_detail_view import InvoiceDetailView
from nexus_ai.frontend.views.invoice_list_view import InvoiceListView
from nexus_ai.frontend.views.partner_hub import PartnerHubView
from nexus_ai.frontend.views.task_monitor import TaskMonitorView
from nexus_ai.frontend.views.ui_triage import UITriageView
from nexus_ai.frontend.views.executive_dashboard import ExecutiveDashboardView, build_demo_dashboard

__all__ = [
    "DashboardView",
    "DecisionFeedView",
    "InvoiceListView",
    "InvoiceDetailView",
    "TaskMonitorView",
    "DailyBriefingView",
    "PartnerHubView",
    "UITriageView",
    # GENIALNY POMYSŁ v6.0: Silent Partner
    "ExecutiveDashboardView",
    "build_demo_dashboard",
]
