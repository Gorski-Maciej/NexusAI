"""Runtime configuration for the backend."""
from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path

@dataclass(slots=True)
class AppConfig:
    """Centralized application paths and DB engine limits."""
    base_dir: Path = Path.cwd()
    sqlite_file_name: str = "nexus_oltp.db"
    duckdb_file_name: str = "nexus_olap.duckdb"
    duckdb_memory_limit: str = "2GB"
    duckdb_threads: int = 2
    sqlcipher_key_env: str = "NEXUS_SQLCIPHER_KEY"

    @property
    def sqlite_path(self) -> Path:
        """Return absolute path to SQLite file."""
        return self.base_dir / self.sqlite_file_name

    @property
    def duckdb_path(self) -> Path:
        """Return absolute path to DuckDB file."""
        return self.base_dir / self.duckdb_file_name
