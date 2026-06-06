"""
ConfigValidator — environment variable validation for NexusAI.

Zastępuje: pydantic-settings + Pydantic (ciężki, wiele zależności)
Nowy:     msgspec.Struct (ultraszybki, zero dodatkowych zależności)

Wczytywanie konfiguracji z NEXUS_* zmiennych środowiskowych.
Walidacja typów, zakresów i spójności między polami.

Usage::
    from core.config_validator import NexusSettings, validate_config
    settings = NexusSettings.from_env()
    errors = validate_config()
"""

from __future__ import annotations

import base64
import os
import re
import sys
from typing import Any

from msgspec import Struct

# ═══════════════════════════════════════════════════════════════════════════════
# msgspec.Struct model — ultralekka alternatywa dla pydantic-settings
# ═══════════════════════════════════════════════════════════════════════════════


class NexusSettings(Struct, kw_only=True):
    """All NexusAI configuration as msgspec.Struct.

    Użyj ``NexusSettings.from_env()`` aby wczytać z NEXUS_* zmiennych środowiskowych.
    Walidacja typów i zakresów przy instantacji.

    Usage::
        settings = NexusSettings.from_env()
        print(settings.env, settings.duckdb_memory_limit)
    """

    # ── Core ──
    env: str = "dev"
    debug: bool = False
    host: str = "127.0.0.1"
    port: int = 8000
    base_dir: str = "."
    log_level: str = "info"

    # ── Security ──
    jwt_secret: str = ""
    jwt_expiration_seconds: int = 900
    admin_username: str = "admin"
    admin_password: str = "admin"
    encryption_key: str = ""
    sqlcipher_key: str = ""

    # ── Database ──
    sqlite_file: str = "nexus_oltp.db"
    duckdb_file: str = "nexus_olap.duckdb"
    duckdb_memory_limit: str = "512MB"
    duckdb_threads: int = 2

    # ── NATS ──
    nats_url: str = "nats://localhost:4222"
    max_parallel_ocr: int = 1
    ocr_timeout_sec: int = 300
    model_cache_ttl_sec: int = 600
    outbox_replay_limit: int = 100

    # ── Storage ──
    storage_dir: str = "app_data/uploads"
    max_invoice_upload_mb: int = 50
    max_attachment_upload_mb: int = 500

    # ── CORS ──
    cors_origins: str = "*"

    # ── AI Models ──
    council_alpha_model: str = "models/LFM2.5-1.2B-Q4_K_M.gguf"
    council_beta_model: str = "models/Qwen3-0.6B-Q4_K_M.gguf"
    council_gamma_model: str = "models/LittleLamb-0.3B-Q4_K_M.gguf"
    rules_model: str = "models/granite-4.0-1b-nano-Q4_K_M.gguf"
    analytics_model: str = "models/qwen2.5-1.5b-instruct-Q4_K_M.gguf"
    fin_detective_model: str = "models/fin-rwkv-169m.pth"

    # ── Decision Thresholds ──
    autopilot_auto_post: float = 0.92
    autopilot_suggest: float = 0.75
    autopilot_model_ttl: int = 600
    autopilot_agent_timeout: int = 30

    # ── Analytics ──
    analytics_anomaly_threshold: float = 2.0
    decision_timeout: int = 60

    # ── TigerBeetle ──
    tb_cluster_id: int = 0
    tb_replica_addresses: str = "3000"

    # ── Monitoring ──
    sentry_dsn: str = ""
    dpo_alert_webhook: str = ""
    otel_buffer_max_records: int = 50000

    @classmethod
    def from_env(cls) -> NexusSettings:
        """Load settings from NEXUS_* environment variables."""
        return cls(
            env=_env_str("NEXUS_ENV", "dev"),
            debug=_env_bool("NEXUS_DEBUG", False),
            host=_env_str("NEXUS_HOST", "127.0.0.1"),
            port=_env_int("NEXUS_PORT", 8000, ge=1, le=65535),
            base_dir=_env_str("NEXUS_BASE_DIR", "."),
            log_level=_env_str("NEXUS_LOG_LEVEL", "info"),
            jwt_secret=_env_str("NEXUS_JWT_SECRET", ""),
            jwt_expiration_seconds=_env_int("NEXUS_JWT_EXPIRATION_SECONDS", 900, ge=60, le=86400),
            admin_username=_env_str("NEXUS_ADMIN_USERNAME", "admin"),
            admin_password=_env_str("NEXUS_ADMIN_PASSWORD", "admin"),
            encryption_key=_env_str("NEXUS_ENCRYPTION_KEY", ""),
            sqlcipher_key=_env_str("NEXUS_SQLCIPHER_KEY", ""),
            sqlite_file=_env_str("NEXUS_SQLITE_FILE", "nexus_oltp.db"),
            duckdb_file=_env_str("NEXUS_DUCKDB_FILE", "nexus_olap.duckdb"),
            duckdb_memory_limit=_env_str("NEXUS_DUCKDB_MEMORY_LIMIT", "512MB"),
            duckdb_threads=_env_int("NEXUS_DUCKDB_THREADS", 2, ge=1, le=64),
            nats_url=_env_str("NEXUS_NATS_URL", "nats://localhost:4222"),
            max_parallel_ocr=_env_int("NEXUS_MAX_PARALLEL_OCR", 1, ge=1, le=16),
            ocr_timeout_sec=_env_int("NEXUS_OCR_TIMEOUT_SEC", 300, ge=10, le=3600),
            model_cache_ttl_sec=_env_int("NEXUS_MODEL_CACHE_TTL_SEC", 600, ge=10, le=86400),
            outbox_replay_limit=_env_int("NEXUS_OUTBOX_REPLAY_LIMIT", 100, ge=1, le=10000),
            storage_dir=_env_str("NEXUS_STORAGE_DIR", "app_data/uploads"),
            max_invoice_upload_mb=_env_int("NEXUS_MAX_INVOICE_UPLOAD_MB", 50, ge=1, le=500),
            max_attachment_upload_mb=_env_int("NEXUS_MAX_ATTACHMENT_UPLOAD_MB", 500, ge=1, le=2000),
            cors_origins=_env_str("NEXUS_CORS_ORIGINS", "*"),
            council_alpha_model=_env_str("NEXUS_COUNCIL_ALPHA_MODEL", "models/LFM2.5-1.2B-Q4_K_M.gguf"),
            council_beta_model=_env_str("NEXUS_COUNCIL_BETA_MODEL", "models/Qwen3-0.6B-Q4_K_M.gguf"),
            council_gamma_model=_env_str("NEXUS_COUNCIL_GAMMA_MODEL", "models/LittleLamb-0.3B-Q4_K_M.gguf"),
            rules_model=_env_str("NEXUS_RULES_MODEL", "models/granite-4.0-1b-nano-Q4_K_M.gguf"),
            analytics_model=_env_str("NEXUS_ANALYTICS_MODEL", "models/qwen2.5-1.5b-instruct-Q4_K_M.gguf"),
            fin_detective_model=_env_str("NEXUS_FIN_DETECTIVE_MODEL", "models/fin-rwkv-169m.pth"),
            autopilot_auto_post=_env_float("NEXUS_AUTOPILOT_AUTO_POST", 0.92, ge=0.0, le=1.0),
            autopilot_suggest=_env_float("NEXUS_AUTOPILOT_SUGGEST", 0.75, ge=0.0, le=1.0),
            autopilot_model_ttl=_env_int("NEXUS_AUTOPILOT_MODEL_TTL", 600, ge=10, le=86400),
            autopilot_agent_timeout=_env_int("NEXUS_AUTOPILOT_AGENT_TIMEOUT", 30, ge=5, le=300),
            analytics_anomaly_threshold=_env_float("NEXUS_ANALYTICS_ANOMALY_THRESHOLD", 2.0, ge=0.0, le=10.0),
            decision_timeout=_env_int("NEXUS_DECISION_TIMEOUT", 60, ge=5, le=600),
            tb_cluster_id=_env_int("TB_CLUSTER_ID", 0, ge=0, le=255),
            tb_replica_addresses=_env_str("TB_REPLICA_ADDRESSES", "3000"),
            sentry_dsn=_env_str("NEXUS_SENTRY_DSN", ""),
            dpo_alert_webhook=_env_str("NEXUS_DPO_ALERT_WEBHOOK", ""),
            otel_buffer_max_records=_env_int("NEXUS_OTEL_BUFFER_MAX_RECORDS", 50000, ge=100, le=1_000_000),
        )

    def validate(self) -> list[str]:
        """Validate cross-field consistency. Returns list of error messages."""
        errors: list[str] = []

        # Validate env
        if self.env.lower() not in ("dev", "stage", "prod"):
            errors.append(f"NEXUS_ENV='{self.env}' must be one of: dev, stage, prod")

        # Validate log level
        if self.log_level.upper() not in ("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"):
            errors.append(f"NEXUS_LOG_LEVEL='{self.log_level}' invalid")

        # Validate NATS URL
        if self.nats_url and not self.nats_url.startswith("nats://"):
            errors.append(f"NEXUS_NATS_URL='{self.nats_url}' must start with nats://")

        # Validate memory limit format
        if not re.match(r"^\d+(MB|GB)$", self.duckdb_memory_limit.strip().upper()):
            errors.append(f"NEXUS_DUCKDB_MEMORY_LIMIT='{self.duckdb_memory_limit}' must be e.g. 512MB, 2GB")

        # Validate encryption key
        if self.encryption_key:
            try:
                raw = base64.urlsafe_b64decode(self.encryption_key.encode("utf-8"))
                if len(raw) != 32:
                    errors.append(f"Encryption key must decode to exactly 32 bytes (got {len(raw)})")
            except Exception as exc:
                errors.append(f"Invalid encryption key: {exc}")

        # Cross-field: stage/prod requirements
        if self.env in ("stage", "prod"):
            if self.debug:
                errors.append("NEXUS_DEBUG=True is not allowed in stage/prod")
            if self.cors_origins == "*":
                errors.append("NEXUS_CORS_ORIGINS='*' is not allowed in stage/prod")
            if not self.jwt_secret:
                errors.append("NEXUS_JWT_SECRET is REQUIRED in stage/prod")
            if not self.encryption_key:
                errors.append("NEXUS_ENCRYPTION_KEY is REQUIRED in stage/prod")

        # Cross-field: attachment >= invoice
        if self.max_attachment_upload_mb < self.max_invoice_upload_mb:
            errors.append(
                f"NEXUS_MAX_ATTACHMENT_UPLOAD_MB ({self.max_attachment_upload_mb}) must be >= "
                f"NEXUS_MAX_INVOICE_UPLOAD_MB ({self.max_invoice_upload_mb})"
            )

        return errors


# ═══════════════════════════════════════════════════════════════════════════════
# Helper functions
# ═══════════════════════════════════════════════════════════════════════════════


def _env_str(key: str, default: str) -> str:
    return os.getenv(key, default).strip()


def _env_int(key: str, default: int, ge: int | None = None, le: int | None = None) -> int:
    raw = os.getenv(key, str(default)).strip()
    try:
        val = int(raw)
    except (ValueError, TypeError):
        val = default
    if ge is not None and val < ge:
        val = ge
    if le is not None and val > le:
        val = le
    return val


def _env_float(key: str, default: float, ge: float | None = None, le: float | None = None) -> float:
    raw = os.getenv(key, str(default)).strip()
    try:
        val = float(raw)
    except (ValueError, TypeError):
        val = default
    if ge is not None and val < ge:
        val = ge
    if le is not None and val > le:
        val = le
    return val


def _env_bool(key: str, default: bool) -> bool:
    raw = os.getenv(key, "").strip().lower()
    if not raw:
        return default
    return raw in ("1", "true", "yes", "on")


# ═══════════════════════════════════════════════════════════════════════════════
# Backward-compatible API
# ═══════════════════════════════════════════════════════════════════════════════


class ConfigVar:
    """Backward-compatible ConfigVar wrapping NexusSettings field metadata."""

    def __init__(
        self,
        name: str,
        default: str = "",
        description: str = "",
        validator: Any = None,
        secret: bool = False,
        required_in: list[str] | None = None,
        group: str = "Core",
    ) -> None:
        self.name = name
        self.default = default
        self.description = description
        self.secret = secret
        self.required_in = required_in or []
        self.group = group

    def validate(self, _value: str, _environment: str = "dev") -> str | None:
        return None


def _build_config_registry() -> list[ConfigVar]:
    _ENV_MAP = {  # noqa: N806
        "NEXUS_ENV": ("env", "dev"),
        "NEXUS_DEBUG": ("debug", "0"),
        "NEXUS_HOST": ("host", "127.0.0.1"),
        "NEXUS_PORT": ("port", "8000"),
        "NEXUS_LOG_LEVEL": ("log_level", "info"),
        "NEXUS_JWT_SECRET": ("jwt_secret", ""),
        "NEXUS_ENCRYPTION_KEY": ("encryption_key", ""),
        "NEXUS_SQLITE_FILE": ("sqlite_file", "nexus_oltp.db"),
        "NEXUS_DUCKDB_FILE": ("duckdb_file", "nexus_olap.duckdb"),
        "NEXUS_DUCKDB_MEMORY_LIMIT": ("duckdb_memory_limit", "512MB"),
        "NEXUS_NATS_URL": ("nats_url", "nats://localhost:4222"),
        "NEXUS_CORS_ORIGINS": ("cors_origins", "*"),
        "NEXUS_STORAGE_DIR": ("storage_dir", "app_data/uploads"),
    }
    registry: list[ConfigVar] = []
    for env_name, (_field, default) in _ENV_MAP.items():
        registry.append(
            ConfigVar(
                name=env_name,
                default=default,
                description="",
                group="Settings",
            )
        )
    return registry


CONFIG_REGISTRY: list[ConfigVar] = _build_config_registry()


def validate_config(environment: str | None = None, env_prefix: str = "NEXUS_") -> list[str]:
    """Validate all configuration using NexusSettings.

    Returns:
        List of error messages. Empty list means all checks passed.
    """
    try:
        settings = NexusSettings.from_env()
        return settings.validate()
    except Exception as exc:
        return [str(exc)]


def validate_and_exit() -> None:
    """Validate config and exit with error message if any checks fail."""
    errors = validate_config()
    if errors:
        print("=" * 70)
        print("  NEXUSAI CONFIGURATION ERRORS")
        print("=" * 70)
        print()
        for err in errors:
            print(f"  • {err}")
        print()
        print("  To fix:")
        print("    1. Check your .env or environment variables")
        print("    2. Restart the application")
        print()
        print("=" * 70)
        sys.exit(1)


def print_config_summary() -> None:
    """Print a summary of all active configuration values."""
    settings = NexusSettings.from_env()
    print()
    print("=" * 70)
    print("  NEXUSAI CONFIGURATION SUMMARY (msgspec.Struct)")
    print("=" * 70)
    for field_name in settings.__struct_fields__:
        value = getattr(settings, field_name)
        display = str(value)
        # Mask secrets
        secret_keys = {"jwt_secret", "encryption_key", "sqlcipher_key", "admin_password", "sentry_dsn"}
        if field_name in secret_keys and value:
            display = "****"
        print(f"    NEXUS_{field_name.upper():40s} = {display}")
    print()
    print("=" * 70)
    print()


def check_config_consistency() -> list[str]:
    """Check cross-field consistency rules (backward compat)."""
    try:
        settings = NexusSettings.from_env()
        return settings.validate()
    except Exception as exc:
        return [str(exc)]
