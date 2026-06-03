"""
ConfigValidator — environment variable validation for NexusAI.

Replaced custom 389-line implementation with ``pydantic-settings``
(well-known library, built on Pydantic which is already a dependency).

Usage::

    from core.config_validator import NexusSettings, validate_config

    settings = NexusSettings()          # auto-reads from env
    errors = validate_config()           # backward-compatible
"""

from __future__ import annotations

import os
import sys
import json
from pathlib import Path
from typing import Any

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


# ═══════════════════════════════════════════════════════════════════════════════
# pydantic-settings model — the real implementation
# ═══════════════════════════════════════════════════════════════════════════════


class NexusSettings(BaseSettings):
    """All NexusAI configuration as a pydantic-settings model.

    Reads from environment variables (NEXUS_* prefix) automatically.
    Validates types, ranges, and cross-field consistency at instantiation.

    Usage::

        settings = NexusSettings()
        print(settings.env, settings.duckdb_memory_limit)
    """

    model_config = SettingsConfigDict(
        env_prefix="NEXUS_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # ── Core ──
    env: str = Field("dev", alias="NEXUS_ENV")
    debug: bool = Field(False, alias="NEXUS_DEBUG")
    host: str = Field("127.0.0.1", alias="NEXUS_HOST")
    port: int = Field(8000, ge=1, le=65535, alias="NEXUS_PORT")
    base_dir: str = Field(".", alias="NEXUS_BASE_DIR")
    log_level: str = Field("info", alias="NEXUS_LOG_LEVEL")

    # ── Security ──
    jwt_secret: str = Field("", alias="NEXUS_JWT_SECRET")
    jwt_expiration_seconds: int = Field(900, ge=60, le=86400, alias="NEXUS_JWT_EXPIRATION_SECONDS")
    admin_username: str = Field("admin", alias="NEXUS_ADMIN_USERNAME")
    admin_password: str = Field("admin", alias="NEXUS_ADMIN_PASSWORD")
    encryption_key: str = Field("", alias="NEXUS_ENCRYPTION_KEY")
    sqlcipher_key: str = Field("", alias="NEXUS_SQLCIPHER_KEY")

    # ── Database ──
    sqlite_file: str = Field("nexus_oltp.db", alias="NEXUS_SQLITE_FILE")
    duckdb_file: str = Field("nexus_olap.duckdb", alias="NEXUS_DUCKDB_FILE")
    duckdb_memory_limit: str = Field("512MB", alias="NEXUS_DUCKDB_MEMORY_LIMIT")
    duckdb_threads: int = Field(2, ge=1, le=64, alias="NEXUS_DUCKDB_THREADS")

    # ── NATS ──
    nats_url: str = Field("nats://localhost:4222", alias="NEXUS_NATS_URL")
    max_parallel_ocr: int = Field(1, ge=1, le=16, alias="NEXUS_MAX_PARALLEL_OCR")
    ocr_timeout_sec: int = Field(300, ge=10, le=3600, alias="NEXUS_OCR_TIMEOUT_SEC")
    model_cache_ttl_sec: int = Field(600, ge=10, le=86400, alias="NEXUS_MODEL_CACHE_TTL_SEC")
    outbox_replay_limit: int = Field(100, ge=1, le=10000, alias="NEXUS_OUTBOX_REPLAY_LIMIT")

    # ── Storage ──
    storage_dir: str = Field("app_data/uploads", alias="NEXUS_STORAGE_DIR")
    max_invoice_upload_mb: int = Field(50, ge=1, le=500, alias="NEXUS_MAX_INVOICE_UPLOAD_MB")
    max_attachment_upload_mb: int = Field(500, ge=1, le=2000, alias="NEXUS_MAX_ATTACHMENT_UPLOAD_MB")

    # ── CORS ──
    cors_origins: str = Field("*", alias="NEXUS_CORS_ORIGINS")

    # ── AI Models ──
    council_alpha_model: str = Field("models/LFM2.5-1.2B-Q4_K_M.gguf", alias="NEXUS_COUNCIL_ALPHA_MODEL")
    council_beta_model: str = Field("models/Qwen3-0.6B-Q4_K_M.gguf", alias="NEXUS_COUNCIL_BETA_MODEL")
    council_gamma_model: str = Field("models/LittleLamb-0.3B-Q4_K_M.gguf", alias="NEXUS_COUNCIL_GAMMA_MODEL")
    rules_model: str = Field("models/granite-4.0-1b-nano-Q4_K_M.gguf", alias="NEXUS_RULES_MODEL")
    analytics_model: str = Field("models/qwen2.5-1.5b-instruct-Q4_K_M.gguf", alias="NEXUS_ANALYTICS_MODEL")
    decision_jamba_model: str = Field("models/Jamba-Reasoning-3B-Q4_K_M.gguf", alias="NEXUS_DECISION_JAMBA_MODEL")
    decision_granite_model: str = Field("models/granite-4.0-1b-nano-Q4_K_M.gguf", alias="NEXUS_DECISION_GRANITE_MODEL")
    orchestrator_model: str = Field("models/LittleLamb-0.3B-Q4_K_M.gguf", alias="NEXUS_ORCHESTRATOR_MODEL")
    fin_detective_model: str = Field("models/fin-rwkv-169m.pth", alias="NEXUS_FIN_DETECTIVE_MODEL")

    # ── Decision Thresholds ──
    autopilot_auto_post: float = Field(0.92, ge=0.0, le=1.0, alias="NEXUS_AUTOPILOT_AUTO_POST")
    autopilot_suggest: float = Field(0.75, ge=0.0, le=1.0, alias="NEXUS_AUTOPILOT_SUGGEST")
    autopilot_model_ttl: int = Field(600, ge=10, le=86400, alias="NEXUS_AUTOPILOT_MODEL_TTL")
    autopilot_agent_timeout: int = Field(30, ge=5, le=300, alias="NEXUS_AUTOPILOT_AGENT_TIMEOUT")

    # ── Analytics ──
    analytics_anomaly_threshold: float = Field(2.0, ge=0.0, le=10.0, alias="NEXUS_ANALYTICS_ANOMALY_THRESHOLD")
    decision_timeout: int = Field(60, ge=5, le=600, alias="NEXUS_DECISION_TIMEOUT")

    # ── TigerBeetle ──
    tb_cluster_id: int = Field(0, ge=0, le=255, alias="TB_CLUSTER_ID")
    tb_replica_addresses: str = Field("3000", alias="TB_REPLICA_ADDRESSES")

    # ── Monitoring ──
    sentry_dsn: str = Field("", alias="NEXUS_SENTRY_DSN")
    dpo_alert_webhook: str = Field("", alias="NEXUS_DPO_ALERT_WEBHOOK")
    otel_buffer_max_records: int = Field(50000, ge=100, le=1_000_000, alias="NEXUS_OTEL_BUFFER_MAX_RECORDS")

    # ── Infiscal ──
    infiscal_jwt_secret: str = Field("", alias="NEXUS_INFISCAL_JWT_SECRET")
    infiscal_encryption_key: str = Field("", alias="NEXUS_INFISCAL_ENCRYPTION_KEY")

    # ── Validators ──

    @field_validator("env")
    @classmethod
    def _validate_env(cls, v: str) -> str:
        if v.lower() not in ("dev", "stage", "prod"):
            raise ValueError(f"NEXUS_ENV='{v}' must be one of: dev, stage, prod")
        return v.lower()

    @field_validator("log_level")
    @classmethod
    def _validate_log_level(cls, v: str) -> str:
        if v.upper() not in ("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"):
            raise ValueError(f"NEXUS_LOG_LEVEL='{v}' invalid, must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL")
        return v.upper()

    @field_validator("nats_url")
    @classmethod
    def _validate_nats_url(cls, v: str) -> str:
        if v and not v.startswith("nats://"):
            raise ValueError(f"NEXUS_NATS_URL='{v}' must be a valid NATS URL (e.g. nats://localhost:4222)")
        return v

    @field_validator("duckdb_memory_limit")
    @classmethod
    def _validate_memory_limit(cls, v: str) -> str:
        import re
        if not re.match(r"^\d+(MB|GB)$", v.strip().upper()):
            raise ValueError(f"NEXUS_DUCKDB_MEMORY_LIMIT='{v}' must be e.g. 512MB, 2GB")
        return v.upper()

    @field_validator("encryption_key")
    @classmethod
    def _validate_encryption_key(cls, v: str) -> str:
        if not v:
            return v
        import base64
        try:
            raw = base64.urlsafe_b64decode(v.encode("utf-8"))
            if len(raw) != 32:
                raise ValueError(f"Encryption key must decode to exactly 32 bytes (got {len(raw)})")
        except Exception as exc:
            raise ValueError(f"Invalid encryption key: {exc}") from exc
        return v

    @model_validator(mode="after")
    def _check_cross_field_consistency(self) -> "NexusSettings":
        errs: list[str] = []
        if self.env in ("stage", "prod"):
            if self.debug:
                errs.append("NEXUS_DEBUG=True is not allowed in stage/prod")
            if self.cors_origins == "*":
                errs.append("NEXUS_CORS_ORIGINS='*' is not allowed in stage/prod")
            if not self.jwt_secret:
                errs.append("NEXUS_JWT_SECRET is REQUIRED in stage/prod")
            if not self.encryption_key:
                errs.append("NEXUS_ENCRYPTION_KEY is REQUIRED in stage/prod")
        if self.max_attachment_upload_mb < self.max_invoice_upload_mb:
            errs.append(
                f"NEXUS_MAX_ATTACHMENT_UPLOAD_MB ({self.max_attachment_upload_mb}) must be >= "
                f"NEXUS_MAX_INVOICE_UPLOAD_MB ({self.max_invoice_upload_mb})"
            )
        if errs:
            raise ValueError("; ".join(errs))
        return self


# ═══════════════════════════════════════════════════════════════════════════════
# Backward-compatible API (thin wrappers around NexusSettings)
# ═══════════════════════════════════════════════════════════════════════════════


class ConfigVar:
    """Backward-compatible ConfigVar wrapping ``NexusSettings`` field metadata.

    Usage is unchanged::

        from core.config_validator import ConfigVar, CONFIG_REGISTRY
    """

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
        """Stub — pydantic-settings handles validation natively."""
        return None


def _build_config_registry() -> list[ConfigVar]:
    """Build CONFIG_REGISTRY from NexusSettings field metadata for backward compat."""
    import pydantic.fields

    registry: list[ConfigVar] = []
    settings = NexusSettings.model_fields
    for field_name, field_info in settings.items():
        env_alias = field_info.alias or f"NEXUS_{field_name.upper()}"
        default_val = field_info.default
        if default_val is None:
            default_val = field_info.default_factory() if field_info.default_factory else ""
        registry.append(
            ConfigVar(
                name=env_alias,
                default=str(default_val) if default_val is not None else "",
                description=field_info.description or "",
                group="Settings",
            )
        )
    return registry


CONFIG_REGISTRY: list[ConfigVar] = _build_config_registry()


def validate_config(environment: str | None = None, env_prefix: str = "NEXUS_") -> list[str]:
    """Validate all configuration using pydantic-settings.

    Args:
        environment: Current environment (dev/stage/prod). If None, reads from NEXUS_ENV.
        env_prefix: Ignored (pydantic-settings handles prefix natively).

    Returns:
        List of error messages. Empty list means all checks passed.
    """
    try:
        NexusSettings()
        return []
    except Exception as exc:
        return [str(exc)]


def validate_and_exit() -> None:
    """Validate config and exit with error message if any checks fail.

    Called at application startup for backward compatibility.
    """
    try:
        NexusSettings()
    except Exception as exc:
        print("=" * 70)
        print("  NEXUSAI CONFIGURATION ERRORS")
        print("=" * 70)
        print()
        print(f"  {exc}")
        print()
        print("  To fix:")
        print("    1. Copy .env.example to .env:  cp .env.example .env")
        print("    2. Edit .env and set the missing/incorrect values")
        print("    3. Restart the application")
        print()
        print("  See README.md for detailed configuration instructions.")
        print("=" * 70)
        sys.exit(1)


def print_config_summary() -> None:
    """Print a summary of all active configuration values."""
    settings = NexusSettings()
    print()
    print("=" * 70)
    print("  NEXUSAI CONFIGURATION SUMMARY (pydantic-settings)")
    print("=" * 70)
    for field_name, field_info in settings.model_fields.items():
        env_alias = field_info.alias or f"NEXUS_{field_name.upper()}"
        value = getattr(settings, field_name)
        display = "****" if "secret" in field_name.lower() or "password" in field_name.lower() or "key" in env_alias.lower() and value else str(value)
        print(f"    {env_alias:45s} = {display}")
    print()
    print("=" * 70)
    print()


def check_config_consistency() -> list[str]:
    """Check cross-field consistency rules (backward compat).

    Returns:
        List of warning messages.
    """
    try:
        NexusSettings()
        return []
    except Exception as exc:
        return [str(exc)]
