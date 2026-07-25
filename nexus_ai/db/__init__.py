"""
Database layer packages (OLTP and OLAP).

Skonsolidowane moduły (FAZA 7 + v7.0 Audit Enhancements):
  - firewall.py: Database Firewall (INNOWACJA #5)
  - wal_archiver.py: WAL Archiving + PITR (INNOWACJA #6)
  - index_advisor.py: Intelligent Index Advisor (INNOWACJA #9)
  - tenant_mesh.py: Zero-Trust Database Mesh (INNOWACJA #1)
  - blue_green_migration.py: Blue-Green Schema Migration (INNOWACJA #3)
  - queries.py:  pagination + FTS5 + analytics views
  - transactions.py: outbox + transaction patterns
  - security.py: SQLCipher config + key rotation
  - models.py: SQLModel definitions (v7.0: STRICT audit_logs, tenant_id indexes)
  - hooks.py: DB hooks + walidacja
  - analytics.py: DuckDB manager
  - vector_store.py: sqlite-vec with IVF/HNSW (v7.0: dim=768)
"""

from nexus_ai.core.logger import get_logger as _get_logger

_log = _get_logger("nexus.db")


def _safe_import(qualname: str, names: list[str]):
    """Safe import using importlib.import_module (Enterprise TOP-6 fix)."""
    try:
        import importlib as _il
        mod = _il.import_module(qualname)
        return [getattr(mod, n) for n in names]
    except (ImportError, ModuleNotFoundError, AttributeError) as exc:
        _log.debug("Optional import %s.%s unavailable: %s", qualname, names, exc)
        return [None] * len(names)


# ── Core DB ──────────────────────────────────────────────────────────
(Base, create_oltp_engine, create_session_factory, get_session, SQLCIPHER_AVAILABLE) = _safe_import(
    "nexus_ai.db.database",
    ["Base", "create_oltp_engine", "create_session_factory", "get_session", "SQLCIPHER_AVAILABLE"],
)

# ── Analytics (DuckDB) ──────────────────────────────────────────────
DuckDBLimits, DuckDBManager = _safe_import(
    "nexus_ai.db.analytics", ["DuckDBLimits", "DuckDBManager"]
)

# ── Transactions (dawniej outbox.py + transaction.py) ────────────────
OutboxManager, process_events = _safe_import(
    "nexus_ai.db.transactions", ["OutboxManager", "process_events"]
)

# ── Queries (dawniej pagination.py + fts.py + views.py) ─────────────
CursorPagination, FTSManager, AnalyticsViews = _safe_import(
    "nexus_ai.db.queries",
    ["CursorPagination", "FTSManager", "AnalyticsViews"],
)
# ── Hooks ────────────────────────────────────────────────────────────
[register_db_hooks] = _safe_import("nexus_ai.db.hooks", ["register_db_hooks"])

# ── Security (dawniej sqlcipher_config.py + sqlcipher_key_rotation.py) ─
SQLCipherConfig, KeyRotation = _safe_import(
    "nexus_ai.db.security", ["SQLCipherConfig", "KeyRotation"]
)


def get_fts_manager(db_path=None):
    from nexus_ai.db.queries import FTSManager as _FTSManager

    return _FTSManager(db_path) if db_path else FTSManager


__all__ = [
    "Base",
    "DuckDBLimits",
    "DuckDBManager",
    "create_oltp_engine",
    "create_session_factory",
    "get_session",
    "SQLCIPHER_AVAILABLE",
    "OutboxManager",
    "CursorPagination",
    "FTSManager",
    "AnalyticsViews",
    "register_db_hooks",
    "SQLCipherConfig",
    "KeyRotation",
    "get_fts_manager",
]
