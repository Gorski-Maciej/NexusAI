"""
migrations — Native SQLite migration system (replaces Alembic).

Python 3.13t (free-threaded): sync sqlite3 API is safe for multi-threaded use.
"""

# Import submodule (NOT individual functions) to avoid shadowing
# from X import Y would shadow the submodule X.Y
from migrations import run_migrations as _runner

# Re-export the module for convenient access
run_migrations = _runner.run_migrations
get_current_version = _runner.get_current_version
get_migration_history = _runner.get_migration_history
get_sqlite_conn = _runner.get_sqlite_conn
MIGRATION_FILES = _runner.MIGRATION_FILES
MIGRATIONS_DIR = _runner.MIGRATIONS_DIR

__all__ = [
    "MIGRATION_FILES",
    "MIGRATIONS_DIR",
    "get_current_version",
    "get_migration_history",
    "get_sqlite_conn",
    "run_migrations",
]
