"""Central runtime configuration and startup validation."""
from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


class ConfigValidationError(RuntimeError):
    """Raised when startup settings are incomplete or inconsistent."""


@dataclass(slots=True)
class AppConfig:
    """Centralized application settings registry for all environments."""

    environment: str = os.getenv("NEXUS_ENV", "dev")
    base_dir: Path = Path(os.getenv("NEXUS_BASE_DIR", Path.cwd().as_posix()))
    sqlite_file_name: str = os.getenv("NEXUS_SQLITE_FILE", "nexus_oltp.db")
    duckdb_file_name: str = os.getenv("NEXUS_DUCKDB_FILE", "nexus_olap.duckdb")
    storage_dir_name: str = os.getenv("NEXUS_STORAGE_DIR", "app_data/uploads")
    idempotency_db_name: str = os.getenv("NEXUS_IDEMPOTENCY_DB", "idempotency.sqlite")
    debug: bool = os.getenv("NEXUS_DEBUG", "0") == "1"

    jwt_secret: str = os.getenv("NEXUS_JWT_SECRET", "")
    encryption_key: str = os.getenv("NEXUS_ENCRYPTION_KEY", "")

    duckdb_memory_limit: str = os.getenv("NEXUS_DUCKDB_MEMORY_LIMIT", "2GB")
    duckdb_threads: int = int(os.getenv("NEXUS_DUCKDB_THREADS", "2"))

    def __post_init__(self) -> None:
        self.environment = self.environment.lower().strip()
        if self.environment not in {"dev", "stage", "prod"}:
            raise ConfigValidationError(
                "NEXUS_ENV must be one of: dev, stage, prod"
            )

        self.base_dir = self.base_dir.resolve()
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.storage_dir.mkdir(parents=True, exist_ok=True)

        required_in_stage_prod = {
            "jwt_secret": self.jwt_secret,
            "encryption_key": self.encryption_key,
        }
        if self.environment in {"stage", "prod"}:
            missing = [k for k, v in required_in_stage_prod.items() if not v]
            if missing:
                raise ConfigValidationError(
                    f"Missing required secrets for {self.environment}: {', '.join(missing)}"
                )

    @property
    def sqlite_path(self) -> Path:
        return self.base_dir / self.sqlite_file_name

    @property
    def duckdb_path(self) -> Path:
        return self.base_dir / self.duckdb_file_name

    @property
    def storage_dir(self) -> Path:
        return self.base_dir / self.storage_dir_name

    @property
    def idempotency_db_path(self) -> Path:
        return self.base_dir / self.idempotency_db_name
