"""Database layer packages (OLTP and OLAP)."""

from db.analytics import DuckDBLimits, DuckDBManager
from db.database import Base, create_oltp_engine, create_session_factory, get_session
from db.outbox import OutboxManager
from db.transaction import atomic_transaction
from db.views import AnalyticsViewsSetup
from db.hooks import register_db_hooks

__all__ = [
    "Base",
    "DuckDBLimits",
    "DuckDBManager",
    "create_oltp_engine",
    "create_session_factory",
    "get_session",
    "OutboxManager",
    "atomic_transaction",
    "AnalyticsViewsSetup",
    "register_db_hooks"
]
