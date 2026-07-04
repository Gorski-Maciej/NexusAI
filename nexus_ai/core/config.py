"""Central runtime configuration and startup validation.

Zastępuje: .env + python-dotenv -> msgspec TOML (ultraszybki, mniejszy narzut).
Zgodnie z aa3fvcx.txt: msgspec ma wbudowany parser TOML.
Konfiguracja w czystym TOML zamiast .env.

Refactored: ConfigSchema scalony z AppConfig (~560 linii usuniętych).
"""

from __future__ import annotations

import base64
import binascii
import importlib.util
import os
import threading as _threading
from collections.abc import Callable
from pathlib import Path
from typing import Annotated, Any

import pendulum
from msgspec import Meta, Struct, toml

from nexus_ai.core.logger import get_logger

logger = get_logger(__name__)

ENV_CONFIG_DIR: Path = Path(__file__).resolve().parent.parent / "config"
"""Katalog z plikami TOML (nexus_ai/config/)."""


# ── Helpers ──────────────────────────────────────────────────────────────


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> None:
    """Rekurencyjne scalanie słowników -- override nadpisuje base."""
    for key, value in override.items():
        if key in base and isinstance(base[key], dict) and isinstance(value, dict):
            deep_merge(base[key], value)
        else:
            base[key] = value


# ── ConfigLoader -- mtime-based auto-reload ──────────────────────────────


class ConfigLoader:
    """mtime-based auto-reload dla TOML config.

    Ładuje config/base.toml + config/{env}.toml.
    Auto-reload sprawdza mtime co poll_interval sekund.
    """

    def __init__(
        self,
        path: str | Path | None = None,
        auto_reload: bool | int = False,
    ) -> None:
        if path is not None:
            self._path = Path(path)
            self._base_path: Path | None = None
        else:
            env = os.getenv("NEXUS_ENV", "dev").lower().strip()
            self._path = ENV_CONFIG_DIR / f"{env}.toml"
            self._base_path = ENV_CONFIG_DIR / "base.toml"

        self._data: dict[str, Any] | None = None
        self._last_mtime: float = 0.0
        self._last_checked: float = 0.0
        self._on_change_callbacks: list[Callable[[], None]] = []
        self._auto_reload_enabled = False
        self._poll_interval = 0.0

        if auto_reload is True:
            self._poll_interval = 5.0
            self._auto_reload_enabled = True
        elif isinstance(auto_reload, (int, float)) and auto_reload > 0:
            self._poll_interval = float(auto_reload)
            self._auto_reload_enabled = True

    def load(self) -> dict[str, Any]:
        return self._load()

    def get_config(self) -> dict[str, Any]:
        data = self._load()
        return dict(data) if data else {}

    def reload(self) -> None:
        self._data = None
        self._last_mtime = 0.0
        self._last_checked = 0.0
        self._load()

    def on_change(self, callback: Callable[[], None]) -> Callable[[], None]:
        self._on_change_callbacks.append(callback)
        def unsubscribe() -> None:
            if callback in self._on_change_callbacks:
                self._on_change_callbacks.remove(callback)
        return unsubscribe

    def _load(self) -> dict[str, Any]:
        now = pendulum.now().timestamp()
        if not self._auto_reload_enabled:
            if self._data is not None:
                return self._data
            return self._read_file()

        if now - self._last_checked < self._poll_interval and self._data is not None:
            return self._data
        self._last_checked = now
        if not self._path.exists():
            if self._data is not None:
                logger.warning("[ConfigLoader] File disappeared: %s", self._path)
                self._data = None
                self._last_mtime = 0.0
            return {}
        try:
            current_mtime = self._path.stat().st_mtime
        except OSError:
            return self._data if self._data is not None else {}
        if current_mtime <= self._last_mtime and self._data is not None:
            return self._data
        logger.info("[ConfigLoader] File changed: %s", self._path.name)
        return self._read_file()

    def _read_file(self) -> dict[str, Any]:
        if not self._path.exists():
            self._data = {}
            self._last_mtime = 0.0
            return self._data
        try:
            merged: dict[str, Any] = {}
            if self._base_path and self._base_path.exists():
                with open(self._base_path, "rb") as f:
                    base_raw = toml.decode(f.read())
                if isinstance(base_raw, dict):
                    merged = base_raw
            with open(self._path, "rb") as f:
                env_raw = toml.decode(f.read())
            if isinstance(env_raw, dict):
                deep_merge(merged, env_raw)
            self._data = merged
            self._last_mtime = self._path.stat().st_mtime
            self._apply_to_environ(self._data)
            logger.info("[ConfigLoader] Loaded+merged %d sections (%s)", len(self._data), self._path.name)
            self._fire_on_change_callbacks()
        except Exception as exc:
            logger.error("[ConfigLoader] Failed to load %s: %s", self._path, exc)
            if self._data is None:
                self._data = {}
            self._last_mtime = 0.0
        return self._data if self._data is not None else {}

    def _apply_to_environ(self, data: dict[str, Any]) -> None:
        count = 0
        for _, section_data in data.items():
            if isinstance(section_data, dict):
                for key, value in section_data.items():
                    env_key = key.upper()
                    if not env_key.startswith("NEXUS_"):
                        env_key = f"NEXUS_{env_key}"
                    if env_key not in os.environ:
                        os.environ[env_key] = "1" if isinstance(value, bool) and value else str(value) if not isinstance(value, bool) else "0"
                        count += 1
        if count > 0:
            logger.debug("[ConfigLoader] Set %d env vars", count)

    def _fire_on_change_callbacks(self) -> None:
        for callback in self._on_change_callbacks:
            try:
                callback()
            except Exception as exc:
                logger.error("[ConfigLoader] on_change callback failed: %s", exc)

    def __getitem__(self, key: str) -> Any:
        return self._load().get(key, {})


# ── Global singleton ─────────────────────────────────────────────────────

_default_config_loader_lock = _threading.Lock()
_default_config_loader: ConfigLoader | None = None


def get_config_loader(
    path: str | Path | None = None, auto_reload: bool | int = False
) -> ConfigLoader:
    global _default_config_loader
    if _default_config_loader is None:
        with _default_config_loader_lock:
            if _default_config_loader is None:
                _default_config_loader = ConfigLoader(path=path, auto_reload=auto_reload)
    return _default_config_loader


# ══════════════════════════════════════════════════════════════════════════
# AppConfig -- scalony ConfigSchema + AppConfig (redukcja ~560 → ~280 linii)
# ══════════════════════════════════════════════════════════════════════════


class ConfigValidationError(RuntimeError):
    """Raised when startup settings are incomplete or inconsistent."""


# ── Lazy secrets loader ──────────────────────────────────────────────────
_LSC: type | None = None
_OFSR: type | None = None


def _load_secrets_symbols():
    global _LSC, _OFSR
    if _LSC is not None:
        return _LSC, _OFSR
    try:
        spec = importlib.util.find_spec("nexus_ai.core.secrets")
    except ModuleNotFoundError:
        spec = None
    if spec is not None:
        from nexus_ai.core.secrets import LocalSecretsCache, OfflineFirstSecretResolver
        _LSC, _OFSR = LocalSecretsCache, OfflineFirstSecretResolver
        return _LSC, _OFSR
    module_path = Path(__file__).with_name("secrets.py")
    local_spec = importlib.util.spec_from_file_location("core_secrets_local", module_path)
    if not local_spec or not local_spec.loader:
        raise ImportError("Cannot load secrets module from fallback path")
    module = importlib.util.module_from_spec(local_spec)
    local_spec.loader.exec_module(module)
    _LSC = module.LocalSecretsCache
    _OFSR = module.OfflineFirstSecretResolver
    return _LSC, _OFSR


class AppConfig(Struct, kw_only=True):
    """Centralized application settings registry.

    Scalony z ConfigSchema -- wszystkie pola TOML bezpośrednio w AppConfig.
    Env vars overridują TOML (env > TOML).
    """

    # ── Core ──
    environment: str = "dev"
    base_dir: str = "."
    host: str = "0.0.0.0"
    port: Annotated[int, Meta(ge=1, le=65535)] = 8000
    log_level: str = "INFO"
    debug: bool = False
    cors_origins: str = "*"

    # ── JWT ──
    jwt_secret: str = ""
    jwt_expiration_seconds: Annotated[int, Meta(ge=60, le=86400)] = 900
    refresh_token_days: Annotated[int, Meta(ge=1, le=365)] = 30
    jwt_issuer: str = "nexus-ai"
    jwt_audience: str = "nexus-api"
    csrf_enabled: bool = True

    # ── Database ──
    sqlite_file: str = "app_data/databases/nexus_oltp.db"
    duckdb_file: str = "app_data/databases/nexus_olap.duckdb"
    storage_dir: str = "app_data/uploads"
    idempotency_db: str = "app_data/databases/idempotency.sqlite"
    sqlcipher_key_env: str = "NEXUS_SQLCIPHER_KEY"
    duckdb_memory_limit: str = "512MB"
    duckdb_threads: Annotated[int, Meta(ge=1, le=64)] = 2
    db_pool_size: Annotated[int, Meta(ge=1, le=100)] = 5
    db_pool_overflow: Annotated[int, Meta(ge=0, le=200)] = 10

    # ── Encryption ──
    encryption_key: str = ""

    # ── NATS ──
    nats_url: str = "nats://localhost:4222"
    nats_max_reconnect: Annotated[int, Meta(ge=0, le=100)] = 10
    nats_reconnect_delay_seconds: Annotated[float, Meta(ge=0.1, le=60)] = 2.0

    # ── Storage ──
    storage_protocol: str = "file"
    storage_root: str = "app_data/uploads"
    storage_auto_mkdir: bool = True
    storage_cache_size_mb: Annotated[int, Meta(ge=0, le=10240)] = 0
    storage_transactional: bool = False
    storage_chain_enabled: bool = False
    storage_chain_cache_storage: str = "app_data/fsspec_cache"

    # ── Stamina ──
    stamina_retry_attempts: Annotated[int, Meta(ge=1, le=20)] = 3
    stamina_retry_timeout: Annotated[float, Meta(ge=1.0, le=300.0)] = 10.0
    stamina_circuit_breaker_enabled: bool = True
    stamina_circuit_breaker_cooldown: Annotated[float, Meta(ge=5.0, le=600.0)] = 60.0
    retry_backoff_base_seconds: Annotated[float, Meta(ge=0.1, le=30)] = 1.0
    retry_backoff_max_seconds: Annotated[float, Meta(ge=1.0, le=300)] = 60.0
    max_task_retries: Annotated[int, Meta(ge=0, le=20)] = 3

    # ── Security ──
    jwt_exclude_paths: list[str] | None = None
    csrf_exclude_patterns: list[str] | None = None
    rate_limit_auth: Annotated[int, Meta(ge=1, le=100)] = 10
    rate_limit_upload: Annotated[int, Meta(ge=1, le=200)] = 30
    rate_limit_general: Annotated[int, Meta(ge=1, le=1000)] = 60

    # ── Upload ──
    max_invoice_upload_mb: Annotated[int, Meta(ge=1, le=1000)] = 50
    max_attachment_upload_mb: Annotated[int, Meta(ge=1, le=10000)] = 500

    # ── Integrations ──
    dpo_alert_webhook: str = ""

    # ── Tax ──
    default_vat_rate: Annotated[int, Meta(ge=0, le=100)] = 23
    cit_rate: Annotated[float, Meta(ge=0, le=100)] = 19.0
    linear_rate: Annotated[float, Meta(ge=0, le=100)] = 19.0
    lump_sum_rates: list[float] | None = None
    vat_exempt_threshold: Annotated[float, Meta(ge=0)] = 200000.0
    vat_quarterly_threshold: Annotated[float, Meta(ge=0)] = 2000000.0

    # ── AI ──
    council_alpha_model: str = ""
    council_beta_model: str = ""
    council_gamma_model: str = ""
    rules_model: str = ""
    analytics_model: str = ""
    decision_jamba_model: str = ""
    decision_granite_model: str = ""
    orchestrator_model: str = ""
    ocr_model: str = ""
    vision_model: str = ""
    embedding_model: str = ""

    # ── Decision Engine ──
    autopilot_auto_post_threshold: Annotated[float, Meta(ge=0.0, le=1.0)] = 0.92
    autopilot_suggest_threshold: Annotated[float, Meta(ge=0.0, le=1.0)] = 0.75
    autopilot_ask_threshold: Annotated[float, Meta(ge=0.0, le=1.0)] = 0.50
    autopilot_adaptation_enabled: bool = True
    autopilot_adaptation_learning_rate: Annotated[float, Meta(ge=0.0, le=1.0)] = 0.05
    autopilot_low_amount_threshold: Annotated[float, Meta(ge=0.0)] = 500.0
    rules_max_invoice_amount: Annotated[float, Meta(ge=0.0)] = 100000.0
    rules_require_nip_validation: bool = True
    analytics_anomaly_threshold: Annotated[float, Meta(ge=0.0)] = 2.0
    decision_timeout_seconds: Annotated[int, Meta(ge=5, le=600)] = 60
    outbox_replay_limit: Annotated[int, Meta(ge=1, le=10000)] = 100
    migration_baseline: str = "migration_rowcount_baseline.json"
    migration_baseline_file: str = ""
    migration_checksum_baseline: str = "migration_checksum_baseline.json"
    migration_checksum_baseline_file: str = ""

    # ── TigerBeetle ──
    tigerbeetle_cluster_id: int = 0
    tigerbeetle_replica_addresses: str = ""

    # ── OPA ──
    opa_enabled: bool = True
    opa_url: str = "http://localhost:8181"
    opa_timeout_seconds: Annotated[float, Meta(ge=1.0, le=60.0)] = 10.0
    opa_auto_sync_policy: bool = True
    opa_policy_package: str = "tax.rules"
    opa_policy_rule: str = "decide"

    # ── Factory ──

    @classmethod
    def from_toml(cls, env: str | None = None) -> AppConfig:
        """Utwórz AppConfig z pliku TOML + env override dla secrets."""
        if env is None:
            env = os.getenv("NEXUS_ENV", "dev").lower().strip()
        toml_path = ENV_CONFIG_DIR / f"{env}.toml"

        kwargs: dict[str, Any] = {"environment": env}
        if toml_path.exists():
            try:
                with open(toml_path, "rb") as f:
                    raw = toml.decode(f.read())
                if isinstance(raw, dict):
                    for section in raw.values() if isinstance(raw, dict) else []:
                        if isinstance(section, dict):
                            for k, v in section.items():
                                if k in cls.__struct_fields__:
                                    kwargs[k] = v
            except Exception as exc:
                logger.warning("[Config] TOML error in %s: %s", toml_path, exc)

        instance = cls(**kwargs)
        for secret_field in ("jwt_secret", "encryption_key"):
            env_key = f"NEXUS_{secret_field.upper()}"
            if env_key in os.environ:
                setattr(instance, secret_field, os.environ[env_key])
        instance.validate()
        return instance

    @classmethod
    def create(cls) -> AppConfig:
        """Factory: utwórz z TOML (alias dla from_toml)."""
        return cls.from_toml()

    # ── Validation ──

    def validate(self) -> None:
        self.environment = self.environment.lower().strip()
        if self.environment not in {"dev", "stage", "prod"}:
            raise ConfigValidationError("NEXUS_ENV must be one of: dev, stage, prod")

        if isinstance(self.base_dir, str):
            self.base_dir = Path(self.base_dir).resolve()
        else:
            self.base_dir = self.base_dir.resolve()

        LSC, OFSR = _load_secrets_symbols()
        cache = LSC(self.base_dir / "app_data" / "secrets_cache.json", ttl_hours=24)
        resolver = OFSR(cache)
        self.jwt_secret = (
            resolver.resolve("jwt_secret",
                lambda: os.getenv("NEXUS_INFISCAL_JWT_SECRET", "").strip() or self.jwt_secret) or ""
        )
        self.encryption_key = (
            resolver.resolve("encryption_key",
                lambda: os.getenv("NEXUS_INFISCAL_ENCRYPTION_KEY", "").strip() or self.encryption_key) or ""
        )

        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.storage_dir_path.mkdir(parents=True, exist_ok=True)

        if self.environment in {"stage", "prod"}:
            if self.debug:
                raise ConfigValidationError("NEXUS_DEBUG cannot be enabled in stage/prod")
            if self.cors_origins == "*":
                raise ConfigValidationError("NEXUS_CORS_ORIGINS cannot be '*' in stage/prod")
            missing = [k for k, v in {"jwt_secret": self.jwt_secret, "encryption_key": self.encryption_key}.items() if not v]
            if missing:
                raise ConfigValidationError(f"Missing secrets for {self.environment}: {', '.join(missing)}")

        if self.encryption_key:
            try:
                self._validate_encryption_key(self.encryption_key)
            except ConfigValidationError:
                if self.environment in {"stage", "prod"}:
                    raise
                self.encryption_key = ""

        for field, name in [
            (self.max_invoice_upload_mb, "MAX_INVOICE_UPLOAD_MB"),
            (self.max_attachment_upload_mb, "MAX_ATTACHMENT_UPLOAD_MB"),
            (self.outbox_replay_limit, "OUTBOX_REPLAY_LIMIT"),
        ]:
            if field <= 0:
                raise ConfigValidationError(f"NEXUS_{name} must be > 0")
        if self.max_attachment_upload_mb < self.max_invoice_upload_mb:
            raise ConfigValidationError("MAX_ATTACHMENT must be >= MAX_INVOICE")

    # ── Computed paths ──

    @property
    def sqlite_path(self) -> Path:
        return self.base_dir / self.sqlite_file

    @property
    def duckdb_path(self) -> Path:
        return self.base_dir / self.duckdb_file

    @property
    def storage_dir_path(self) -> Path:
        return self.base_dir / self.storage_dir

    @property
    def idempotency_db_path(self) -> Path:
        return self.base_dir / self.idempotency_db

    @property
    def max_invoice_upload_bytes(self) -> int:
        return self.max_invoice_upload_mb * 1024 * 1024

    @property
    def max_attachment_upload_bytes(self) -> int:
        return self.max_attachment_upload_mb * 1024 * 1024

    @property
    def migration_baseline_path(self) -> Path:
        name = self.migration_baseline_file or self.migration_baseline
        return self.base_dir / "app_data" / name

    @property
    def migration_checksum_baseline_path(self) -> Path:
        name = self.migration_checksum_baseline_file or self.migration_checksum_baseline
        return self.base_dir / "app_data" / name

    @property
    def effective_jwt_exclude(self) -> list[str]:
        if self.jwt_exclude_paths:
            return self.jwt_exclude_paths
        return [
            "/api/auth/login", "/api/auth/register", "/api/auth/refresh",
            "/api/auth/csrf-token", "/api/auth/reset-password", "/api/auth/reset-password/confirm",
            "/api/auth/confirm", "/api/v1/health", "/api/v2/health",
            "/schema/openapi.yml", "/schema/swagger",
        ]

    @property
    def cors_origins_list(self) -> list[str]:
        raw = str(self.cors_origins or "*").strip()
        if not raw or raw == "*":
            return ["*"]
        return [o.strip() for o in raw.split(",") if o.strip()]

    @property
    def autopilot_vendor_alpha_proximity_min(self) -> int:
        return int(os.getenv("NEXUS_AUTOPILOT_VENDOR_ALPHA_MIN", "3"))

    @staticmethod
    def _validate_encryption_key(key: str) -> None:
        try:
            raw = base64.urlsafe_b64decode(key.encode("utf-8"))
        except (ValueError, binascii.Error) as exc:
            raise ConfigValidationError("NEXUS_ENCRYPTION_KEY must be valid base64-url") from exc
        if len(raw) != 32:
            raise ConfigValidationError("NEXUS_ENCRYPTION_KEY must decode to exactly 32 bytes")


# ── Backward compat: import-time TOML load ──────────────────────────────
_env = os.getenv("NEXUS_ENV", "dev").lower().strip()
_profile_path = ENV_CONFIG_DIR / f"{_env}.toml"
if _profile_path.exists():
    try:
        _loader = ConfigLoader()
        _loader.load()
    except Exception as exc:
        logger.debug("[Config] Import-time load skipped: %s", exc)

# ── Backward compat alias ────────────────────────────────────────────────
deep_merge_alias = deep_merge
