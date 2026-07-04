"""Notifications domain -- powiadomienia, daily briefing, mail fetcher.

Re-exports from flat service files for backward compatibility.
"""

from nexus_ai.services.daily_briefing import DailyBriefingService  # noqa: F401
from nexus_ai.services.mail_fetcher import MailIngestionService  # noqa: F401
from nexus_ai.services.notification_manager import NotificationManager  # noqa: F401
from nexus_ai.services.notification_service import (  # noqa: F401
    DailyBriefingGenerator,
    NotificationService,
)
