"""
ConfigValidator — environment variable validation for NexusAI.

Ensures all required environment variables are present and valid at startup.
Provides clear error messages for misconfiguration.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path
from typing import Any, Callable, Protocol


class ConfigError(RuntimeError):
    """Raised when a configuration validation fails."""
    pass


class Validator(Protocol):
    def __call__(self, name: str, value: str) -> str | None: ...


# ── Built-in validators ──────────────────────────────────────────────────────

def _required(name: str, value: str) -> str | None:
    if not value.strip():
        return f"{name} is REQUIRED but was empty or not set."
    return None


def _optional(_name: str, _value: str) -> str | None:
    return None


def _port(name: str, value: str) -> str | None:
    if not value.strip():
        return None
    try:
        port = int(value)
        if port < 1 or port > 65535:
            return f"{name}={value} must be between 1 and 65535."
    except ValueError:
        return f"{name}={value} is not a valid integer port number."
    return None


def _integer(name: str, value: str, minimum: int | None = None, maximum: int | None = None) -> str | None:
    if not value.strip():
        return None
    try:
        v = int(value)
        if minimum is not None and v < minimum:
            return f"{name}={value} must be >= {minimum}."
        if maximum is not None and v > maximum:
            return f"{name}={value} must be <= {maximum}."
    except ValueError:
        return f"{name}={value} is not a valid integer."
    return None


def _float_range(name: str, value: str, minimum: float = 0.0, maximum: float = 1.0) -> str | None:
    if not value.strip():
        return None
    try:
        v = float(value)
        if v < minimum or v > maximum:
            return f"{name}={value} must be between {minimum} and {maximum}."
    except ValueError:
        return f"{name}={value} is not a valid float."
    return None


def _nats_url(name: str, value: str) -> str | None:
    if not value.strip():
        return None
    pattern = r"^nats://[a-zA-Z0-9.\-]+:\d+$"
    if not re.match(pattern, value.strip()):
        return f"{name}={value} must be a valid NATS URL (e.g. nats://localhost:4222)."
    return None


def _memory_limit(name: str, value: str) -> str | None:
    if not value.strip():
        return None
    pattern = r"^\d+(MB|GB)$"
    if not re.match(pattern, value.strip().upper()):
        return f"{name}={value} must be a valid memory limit (e.g. 512MB, 2GB)."
    return None


def _base64_key(name: str, value: str) -> str | None:
    if not value.strip():
        return None
    try:
        import base64
        raw = base64.urlsafe_b64decode(value.encode("utf-8"))
        if len(raw) != 32:
            return f"{name} must decode to exactly 32 bytes (got {len(raw)})."
    except Exception:
        return f"{name}={value[:20]}... is not valid base64-url encoded data."
    return None


def _choice(name: str, value: str, choices: list[str]) -> str | None:
    if not value.strip():
        return None
    if value.strip().lower() not in choices:
        return f"{name}={value} must be one of: {', '.join(choices)}."
    return None


def _one_of_zero_one(name: str, value: str) -> str | None:
    if value.strip() not in ("0", "1"):
        return f"{name}={value} must be 0 or 1."
    return None


def _file_path(name: str, value: str) -> str | None:
    if not value.strip():
        return None
    path = Path(value)
    if path.exists() and not path.is_file():
        return f"{name}={value} exists but is not a file."
    return None


def _url(name: str, value: str) -> str | None:
    if not value.strip():
        return None
    if not value.startswith(("http://", "https://", "nats://")):
        return f"{name}={value} must be a valid URL."
    return None


# ── Config variable definitions ─────────────────────────────────────────────

class ConfigVar:
    """Definition of a single configuration variable."""

    def __init__(
        self,
        name: str,
        default: str = "",
        description: str = "",
        validator: Validator = _optional,
        secret: bool = False,
        required_in: list[str] | None = None,
        group: str = "Core",
    ) -> None:
        self.name = name
        self.default = default
        self.description = description
        self.validator = validator
        self.secret = secret
        self.required_in = required_in or []
        self.group = group

    def validate(self, value: str, environment: str = "dev") -> str | None:
        """Validate a value for this config variable. Returns error message or None."""
        if not value.strip() and self.default:
            return None  # Will use default
        if environment in self.required_in:
            return self.validator(self.name, value or "")
        if not value.strip():
            return None  # Optional, empty is OK
        return self.validator(self.name, value)


# ── Complete config registry ─────────────────────────────────────────────────

CONFIG_REGISTRY: list[ConfigVar] = [
    # ── Core ──
    ConfigVar("NEXUS_ENV", "dev", "Environment: dev, stage, or prod",
              lambda n, v: _choice(n, v, ["dev", "stage", "prod"]),
              group="Core"),
    ConfigVar("NEXUS_DEBUG", "0", "Enable debug mode (1 or 0)", _one_of_zero_one, group="Core"),
    ConfigVar("NEXUS_HOST", "127.0.0.1", "API server bind address", group="Core"),
    ConfigVar("NEXUS_PORT", "8000", "API server port", lambda n, v: _port(n, v), group="Core"),
    ConfigVar("NEXUS_BASE_DIR", ".", "Base directory for data storage", group="Core"),
    ConfigVar("NEXUS_LOG_LEVEL", "info", "Logging level",
              lambda n, v: _choice(n, v, ["debug", "info", "warning", "error", "critical"]),
              group="Core"),

    # ── Security ──
    ConfigVar("NEXUS_JWT_SECRET", "", "JWT signing secret", _required,
              secret=True, required_in=["stage", "prod"], group="Security"),
    ConfigVar("NEXUS_JWT_EXPIRATION_SECONDS", "900", "JWT token expiry in seconds",
              lambda n, v: _integer(n, v, 60, 86400), group="Security"),
    ConfigVar("NEXUS_ADMIN_USERNAME", "admin", "Default admin username", group="Security"),
    ConfigVar("NEXUS_ADMIN_PASSWORD", "admin", "Default admin password",
              secret=True, group="Security"),
    ConfigVar("NEXUS_ENCRYPTION_KEY", "", "32-byte base64-url encryption key",
              _base64_key, secret=True, required_in=["stage", "prod"], group="Security"),
    ConfigVar("NEXUS_SQLCIPHER_KEY", "", "SQLCipher database encryption key",
              secret=True, group="Security"),

    # ── Database ──
    ConfigVar("NEXUS_SQLITE_FILE", "nexus_oltp.db", "SQLite OLTP database filename", group="Database"),
    ConfigVar("NEXUS_DUCKDB_FILE", "nexus_olap.duckdb", "DuckDB OLAP database filename", group="Database"),
    ConfigVar("NEXUS_DUCKDB_MEMORY_LIMIT", "512MB", "DuckDB memory limit",
              _memory_limit, group="Database"),
    ConfigVar("NEXUS_DUCKDB_THREADS", "2", "DuckDB thread count",
              lambda n, v: _integer(n, v, 1, 64), group="Database"),

    # ── NATS ──
    ConfigVar("NEXUS_NATS_URL", "nats://localhost:4222", "NATS server URL",
              _nats_url, group="NATS"),
    ConfigVar("NEXUS_MAX_PARALLEL_OCR", "1", "Max concurrent OCR tasks",
              lambda n, v: _integer(n, v, 1, 16), group="NATS"),
    ConfigVar("NEXUS_OCR_TIMEOUT_SEC", "300", "OCR task timeout in seconds",
              lambda n, v: _integer(n, v, 10, 3600), group="NATS"),
    ConfigVar("NEXUS_MODEL_CACHE_TTL_SEC", "600", "ML model cache TTL",
              lambda n, v: _integer(n, v, 10, 86400), group="NATS"),
    ConfigVar("NEXUS_OUTBOX_REPLAY_LIMIT", "100", "Max outbox replay per cycle",
              lambda n, v: _integer(n, v, 1, 10000), group="NATS"),

    # ── Storage ──
    ConfigVar("NEXUS_STORAGE_DIR", "app_data/uploads", "File upload storage directory", group="Storage"),
    ConfigVar("NEXUS_MAX_INVOICE_UPLOAD_MB", "50", "Max invoice upload size (MB)",
              lambda n, v: _integer(n, v, 1, 500), group="Storage"),
    ConfigVar("NEXUS_MAX_ATTACHMENT_UPLOAD_MB", "500", "Max attachment upload size (MB)",
              lambda n, v: _integer(n, v, 1, 2000), group="Storage"),

    # ── CORS ──
    ConfigVar("NEXUS_CORS_ORIGINS", "*", "Allowed CORS origins", group="CORS"),

    # ── AI Model Paths ──
    ConfigVar("NEXUS_COUNCIL_ALPHA_MODEL", "models/LFM2.5-1.2B-Q4_K_M.gguf",
              "Alpha agent model path", group="AI Models"),
    ConfigVar("NEXUS_COUNCIL_BETA_MODEL", "models/Qwen3-0.6B-Q4_K_M.gguf",
              "Beta agent model path", group="AI Models"),
    ConfigVar("NEXUS_COUNCIL_GAMMA_MODEL", "models/LittleLamb-0.3B-Q4_K_M.gguf",
              "Gamma agent model path", group="AI Models"),
    ConfigVar("NEXUS_RULES_MODEL", "models/granite-4.0-1b-nano-Q4_K_M.gguf",
              "Rules agent model path", group="AI Models"),
    ConfigVar("NEXUS_ANALYTICS_MODEL", "models/qwen2.5-1.5b-instruct-Q4_K_M.gguf",
              "Analytics agent model path", group="AI Models"),
    ConfigVar("NEXUS_DECISION_JAMBA_MODEL", "models/Jamba-Reasoning-3B-Q4_K_M.gguf",
              "Decision agent (Jamba) path", group="AI Models"),
    ConfigVar("NEXUS_DECISION_GRANITE_MODEL", "models/granite-4.0-1b-nano-Q4_K_M.gguf",
              "Decision agent (Granite) path", group="AI Models"),
    ConfigVar("NEXUS_ORCHESTRATOR_MODEL", "models/LittleLamb-0.3B-Q4_K_M.gguf",
              "Orchestrator agent path", group="AI Models"),
    ConfigVar("NEXUS_FIN_DETECTIVE_MODEL", "models/fin-rwkv-169m.pth",
              "Financial detective model path", group="AI Models"),

    # ── Decision Thresholds ──
    ConfigVar("NEXUS_AUTOPILOT_AUTO_POST", "0.92", "Auto-post confidence threshold",
              lambda n, v: _float_range(n, v, 0.0, 1.0), group="Decision Thresholds"),
    ConfigVar("NEXUS_AUTOPILOT_SUGGEST", "0.75", "Suggest confidence threshold",
              lambda n, v: _float_range(n, v, 0.0, 1.0), group="Decision Thresholds"),
    ConfigVar("NEXUS_AUTOPILOT_MODEL_TTL", "600", "Model cache TTL in seconds",
              lambda n, v: _integer(n, v, 10, 86400), group="Decision Thresholds"),
    ConfigVar("NEXUS_AUTOPILOT_AGENT_TIMEOUT", "30", "Agent timeout in seconds",
              lambda n, v: _integer(n, v, 5, 300), group="Decision Thresholds"),

    # ── Analytics ──
    ConfigVar("NEXUS_ANALYTICS_ANOMALY_THRESHOLD", "2.0", "Anomaly detection Z-score threshold",
              lambda n, v: _float_range(n, v, 0.0, 10.0), group="Analytics"),
    ConfigVar("NEXUS_DECISION_TIMEOUT", "60", "Decision agent timeout in seconds",
              lambda n, v: _integer(n, v, 5, 600), group="Analytics"),

    # ── TigerBeetle ──
    ConfigVar("TB_CLUSTER_ID", "0", "TigerBeetle cluster ID",
              lambda n, v: _integer(n, v, 0, 255), group="TigerBeetle"),
    ConfigVar("TB_REPLICA_ADDRESSES", "3000", "TigerBeetle replica addresses", group="TigerBeetle"),

    # ── Monitoring ──
    ConfigVar("NEXUS_SENTRY_DSN", "", "Sentry DSN for error tracking", _url, group="Monitoring"),
    ConfigVar("NEXUS_DPO_ALERT_WEBHOOK", "", "DPO alert webhook URL", _url, group="Monitoring"),
    ConfigVar("NEXUS_OTEL_BUFFER_MAX_RECORDS", "50000", "OTEL buffer max records",
              lambda n, v: _integer(n, v, 100, 1000000), group="Monitoring"),

    # ── Infiscal ──
    ConfigVar("NEXUS_INFISCAL_JWT_SECRET", "", "Infiscal fallback for JWT secret",
              secret=True, group="Infiscal"),
    ConfigVar("NEXUS_INFISCAL_ENCRYPTION_KEY", "", "Infiscal fallback for encryption key",
              secret=True, group="Infiscal"),
]


# ── Validation runner ────────────────────────────────────────────────────────

def validate_config(environment: str | None = None, env_prefix: str = "NEXUS_") -> list[str]:
    """
    Validate all configuration variables.

    Args:
        environment: Current environment (dev/stage/prod). If None, reads from NEXUS_ENV.
        env_prefix: Prefix for environment variables to check.

    Returns:
        List of error messages. Empty list means all checks passed.
    """
    env = environment or os.getenv("NEXUS_ENV", "dev")
    errors: list[str] = []

    for var in CONFIG_REGISTRY:
        value = os.getenv(var.name, var.default)
        error = var.validate(value, env)
        if error:
            errors.append(error)
        elif var.secret and value and var.name not in os.environ:
            # Warn about secrets that come from defaults only
            pass  # Secret with default is OK as long as it's non-empty

    return errors


def validate_and_exit() -> None:
    """
    Validate config and exit with error message if any checks fail.
    Called at application startup.
    """
    errors = validate_config()
    if not errors:
        return

    print("=" * 70)
    print("  NEXUSAI CONFIGURATION ERRORS")
    print("=" * 70)
    print()
    print("  The following configuration issues were found:")
    print()
    for i, error in enumerate(errors, 1):
        print(f"    {i}. {error}")
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
    print()
    print("=" * 70)
    print("  NEXUSAI CONFIGURATION SUMMARY")
    print("=" * 70)
    current_group = ""
    for var in CONFIG_REGISTRY:
        if var.group != current_group:
            current_group = var.group
            print(f"\n  [{current_group}]")
        value = os.getenv(var.name, var.default)
        display = "****" if var.secret and value else (value or "(not set)")
        print(f"    {var.name:45s} = {display}")
    print()
    print("=" * 70)
    print()


# ── Config consistency checks ────────────────────────────────────────────────

def check_config_consistency() -> list[str]:
    """
    Check cross-field consistency rules.
    E.g. attachment size >= invoice size, debug not in prod, etc.
    """
    warnings: list[str] = []
    env = os.getenv("NEXUS_ENV", "dev")

    if env in ("stage", "prod"):
        debug = os.getenv("NEXUS_DEBUG", "0")
        if debug == "1":
            warnings.append("NEXUS_DEBUG=1 is not allowed in stage/prod environment.")
        cors = os.getenv("NEXUS_CORS_ORIGINS", "*")
        if cors == "*":
            warnings.append("NEXUS_CORS_ORIGINS=* is not allowed in stage/prod environment.")

    try:
        inv_mb = int(os.getenv("NEXUS_MAX_INVOICE_UPLOAD_MB", "50"))
        att_mb = int(os.getenv("NEXUS_MAX_ATTACHMENT_UPLOAD_MB", "500"))
        if att_mb < inv_mb:
            warnings.append(
                f"NEXUS_MAX_ATTACHMENT_UPLOAD_MB ({att_mb}) must be >= "
                f"NEXUS_MAX_INVOICE_UPLOAD_MB ({inv_mb})."
            )
    except ValueError:
        pass

    return warnings
