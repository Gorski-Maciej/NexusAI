"""Database layer packages (OLTP and OLAP)."""

import logging as _logging

_log = _logging.getLogger("nexus.db")

# ── Safe imports — non-critical modules may fail in constrained envs ──

def _safe_import(qualname: str, names: list[str]):
    try:
        mod = __import__(qualname, fromlist=names)
        return [getattr(mod, n) for n in names]
    except (ImportError, ModuleNotFoundError, AttributeError) as exc:
        _log.debug("Optional import %s.%s unavailable: %s", qualname, names, exc)
        return [None] * len(names)


Base, create_oltp_engine, create_session_factory, get_session = _safe_import(
    "db.database", ["Base", "create_oltp_engine", "create_session_factory", "get_session"]
)

DuckDBLimits, DuckDBManager = _safe_import(
    "db.analytics", ["DuckDBLimits", "DuckDBManager"]
)

[OutboxManager] = _safe_import("db.outbox", ["OutboxManager"])

[atomic_transaction] = _safe_import("db.transaction", ["atomic_transaction"])

[AnalyticsViewsSetup] = _safe_import("db.views", ["AnalyticsViewsSetup"])

[register_db_hooks] = _safe_import("db.hooks", ["register_db_hooks"])


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
    "register_db_hooks",
]
