"""Central runtime configuration and startup validation."""
from __future__ import annotations

import os
import base64
import binascii
from dataclasses import dataclass
from pathlib import Path

import importlib.util


def _load_secrets_symbols():
    try:
        spec = importlib.util.find_spec("core.secrets")
    except ModuleNotFoundError:
        spec = None
    if spec is not None:
        from core.secrets import LocalSecretsCache, OfflineFirstSecretResolver
        return LocalSecretsCache, OfflineFirstSecretResolver
    module_path = Path(__file__).with_name("secrets.py")
    local_spec = importlib.util.spec_from_file_location("core_secrets_local", module_path)
    module = importlib.util.module_from_spec(local_spec)
    assert local_spec and local_spec.loader
    local_spec.loader.exec_module(module)
    return module.LocalSecretsCache, module.OfflineFirstSecretResolver


LocalSecretsCache, OfflineFirstSecretResolver = _load_secrets_symbols()


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
    sqlcipher_key_env: str = os.getenv("NEXUS_SQLCIPHER_KEY_ENV", "NEXUS_SQLCIPHER_KEY")

    jwt_secret: str = os.getenv("NEXUS_JWT_SECRET", "")
    encryption_key: str = os.getenv("NEXUS_ENCRYPTION_KEY", "")

    duckdb_memory_limit: str = os.getenv("NEXUS_DUCKDB_MEMORY_LIMIT", "512MB")
    duckdb_threads: int = int(os.getenv("NEXUS_DUCKDB_THREADS", "2"))
    cors_origins_raw: str = os.getenv("NEXUS_CORS_ORIGINS", "*")
    max_invoice_upload_mb: int = int(os.getenv("NEXUS_MAX_INVOICE_UPLOAD_MB", "50"))
    max_attachment_upload_mb: int = int(os.getenv("NEXUS_MAX_ATTACHMENT_UPLOAD_MB", "500"))
    dpo_alert_webhook: str = os.getenv("NEXUS_DPO_ALERT_WEBHOOK", "").strip()
    outbox_replay_limit: int = int(os.getenv("NEXUS_OUTBOX_REPLAY_LIMIT", "100"))
    migration_baseline_name: str = os.getenv("NEXUS_MIGRATION_BASELINE_FILE", "migration_rowcount_baseline.json")
    migration_checksum_baseline_name: str = os.getenv("NEXUS_MIGRATION_CHECKSUM_BASELINE_FILE", "migration_checksum_baseline.json")

    def __post_init__(self) -> None:
        self.environment = self.environment.lower().strip()
        if self.environment not in {"dev", "stage", "prod"}:
            raise ConfigValidationError(
                "NEXUS_ENV must be one of: dev, stage, prod"
            )

        self.base_dir = self.base_dir.resolve()
        # Offline-first secret resolution: prefer live env, fallback to encrypted/local cache.
        cache = LocalSecretsCache(self.base_dir / "app_data" / "secrets_cache.json", ttl_hours=24)
        resolver = OfflineFirstSecretResolver(cache)
        self.jwt_secret = resolver.resolve("jwt_secret", lambda: os.getenv("NEXUS_INFISCAL_JWT_SECRET", "").strip() or self.jwt_secret) or ""
        self.encryption_key = resolver.resolve("encryption_key", lambda: os.getenv("NEXUS_INFISCAL_ENCRYPTION_KEY", "").strip() or self.encryption_key) or ""
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.storage_dir.mkdir(parents=True, exist_ok=True)

        required_in_stage_prod = {
            "jwt_secret": self.jwt_secret,
            "encryption_key": self.encryption_key,
        }
        if self.environment in {"stage", "prod"}:
            if self.debug:
                raise ConfigValidationError("NEXUS_DEBUG cannot be enabled in stage/prod")
            if self.cors_origins == ["*"]:
                raise ConfigValidationError("NEXUS_CORS_ORIGINS cannot be '*' in stage/prod")
            missing = [k for k, v in required_in_stage_prod.items() if not v]
            if missing:
                raise ConfigValidationError(
                    f"Missing required secrets for {self.environment}: {', '.join(missing)}"
                )

        if self.encryption_key:
            try:
                self._validate_encryption_key(self.encryption_key)
            except ConfigValidationError:
                if self.environment in {"stage", "prod"}:
                    raise
                self.encryption_key = ""
        if self.max_invoice_upload_mb <= 0:
            raise ConfigValidationError("NEXUS_MAX_INVOICE_UPLOAD_MB must be > 0")
        if self.max_attachment_upload_mb <= 0:
            raise ConfigValidationError("NEXUS_MAX_ATTACHMENT_UPLOAD_MB must be > 0")
        if self.max_attachment_upload_mb < self.max_invoice_upload_mb:
            raise ConfigValidationError("NEXUS_MAX_ATTACHMENT_UPLOAD_MB must be >= NEXUS_MAX_INVOICE_UPLOAD_MB")
        if self.outbox_replay_limit <= 0:
            raise ConfigValidationError("NEXUS_OUTBOX_REPLAY_LIMIT must be > 0")

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

    @property
    def max_invoice_upload_bytes(self) -> int:
        return self.max_invoice_upload_mb * 1024 * 1024

    @property
    def max_attachment_upload_bytes(self) -> int:
        return self.max_attachment_upload_mb * 1024 * 1024

    @property
    def migration_baseline_path(self) -> Path:
        return self.base_dir / "app_data" / self.migration_baseline_name

    @property
    def migration_checksum_baseline_path(self) -> Path:
        return self.base_dir / "app_data" / self.migration_checksum_baseline_name

    @property
    def cors_origins(self) -> list[str]:
        raw = self.cors_origins_raw.strip()
        if not raw:
            return ["*"]
        if raw == "*":
            return ["*"]
        return [origin.strip() for origin in raw.split(",") if origin.strip()]

    @staticmethod
    def _validate_encryption_key(key: str) -> None:
        try:
            raw = base64.urlsafe_b64decode(key.encode("utf-8"))
        except (ValueError, binascii.Error) as exc:
            raise ConfigValidationError("NEXUS_ENCRYPTION_KEY must be valid base64-url") from exc
        if len(raw) != 32:
            raise ConfigValidationError("NEXUS_ENCRYPTION_KEY must decode to exactly 32 bytes")
