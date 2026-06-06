"""Central runtime configuration and startup validation.

Zastępuje: dataclass (standard Python) → msgspec.Struct (ultraszybki, mniejszy narzut)
Dodatkowo: ładowanie profili .env przez msgspec parsowanie TOML.
"""
from __future__ import annotations

import base64
import binascii
import importlib.util
import os
from pathlib import Path

from msgspec import Struct

ENV_CONFIG_DIR: Path = Path(__file__).resolve().parent.parent.parent / "config"
"""Directory containing environment-specific .env profiles."""


def _load_env_profile(environment: str) -> None:
    """Load environment-specific config file from config/{env}.env."""
    profile_path = ENV_CONFIG_DIR / f"{environment}.env"
    if not profile_path.exists():
        return

    loaded = 0
    with open(profile_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip()
            if not key:
                continue
            if key not in os.environ:
                os.environ[key] = value
                loaded += 1

    if loaded > 0:
        print(f"[Config] Loaded {loaded} settings from {profile_path.name}")


# ── Load environment profile at import time ────────────────────────────────
_env = os.getenv("NEXUS_ENV", "dev").lower().strip()
_load_env_profile(_env)


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


class AppConfig(Struct, kw_only=True):
    """Centralized application settings registry for all environments.

    msgspec.Struct — lżejszy i szybszy niż dataclass.
    Wczytuje wartości z os.environ (wcześniej załadowane z profili .env).

    Uwaga: msgspec.Struct nie wywołuje automatycznie ``__post_init__``.
    Użyj ``AppConfig.create()`` która woła walidację po inicjalizacji.
    """

    # ── Core ──
    environment: str = os.getenv("NEXUS_ENV", "dev")
    base_dir: Path = Path(os.getenv("NEXUS_BASE_DIR", Path.cwd().as_posix()))

    # ── JWT configuration ──
    jwt_expiration_seconds: int = int(os.getenv("NEXUS_JWT_EXPIRATION_SECONDS", "900"))
    refresh_token_days: int = int(os.getenv("NEXUS_REFRESH_TOKEN_DAYS", "30"))
    jwt_issuer: str = os.getenv("NEXUS_JWT_ISSUER", "nexus-ai")
    jwt_audience: str = os.getenv("NEXUS_JWT_AUDIENCE", "nexus-api")

    # ── CSRF ──
    csrf_enabled: bool = os.getenv("NEXUS_CSRF_ENABLED", "1") == "1"

    # ── Connection pool limits ──
    db_pool_size: int = int(os.getenv("NEXUS_DB_POOL_SIZE", "5"))
    db_pool_overflow: int = int(os.getenv("NEXUS_DB_POOL_OVERFLOW", "10"))
    nats_max_reconnect: int = int(os.getenv("NEXUS_NATS_MAX_RECONNECT", "10"))
    nats_reconnect_delay_seconds: int = int(os.getenv("NEXUS_NATS_RECONNECT_DELAY", "2"))

    # ── Retry policy defaults (stamina) ──
    max_task_retries: int = int(os.getenv("NEXUS_MAX_TASK_RETRIES", "3"))
    retry_backoff_base_seconds: float = float(os.getenv("NEXUS_RETRY_BACKOFF_BASE", "1.0"))
    retry_backoff_max_seconds: float = float(os.getenv("NEXUS_RETRY_BACKOFF_MAX", "60.0"))

    # ── Database ──
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

    # ── Council Agents (Autopilot) ──
    council_alpha_model_path: str = os.getenv("NEXUS_COUNCIL_ALPHA_MODEL", "models/LFM2.5-1.2B-Q4_K_M.gguf")
    council_beta_model_path: str = os.getenv("NEXUS_COUNCIL_BETA_MODEL", "models/Qwen3-0.6B-Q4_K_M.gguf")
    council_gamma_model_path: str = os.getenv("NEXUS_COUNCIL_GAMMA_MODEL", "models/LittleLamb-0.3B-Q4_K_M.gguf")

    # ── Decision thresholds ──
    autopilot_auto_post_threshold: float = float(os.getenv("NEXUS_AUTOPILOT_AUTO_POST", "0.92"))
    autopilot_suggest_threshold: float = float(os.getenv("NEXUS_AUTOPILOT_SUGGEST", "0.75"))
    autopilot_ask_threshold: float = float(os.getenv("NEXUS_AUTOPILOT_ASK", "0.50"))

    # ── Adaptation ──
    autopilot_adaptation_enabled: bool = os.getenv("NEXUS_AUTOPILOT_ADAPTATION", "1") == "1"
    autopilot_adaptation_learning_rate: float = float(os.getenv("NEXUS_AUTOPILOT_LEARNING_RATE", "0.05"))
    autopilot_low_amount_threshold: float = float(os.getenv("NEXUS_AUTOPILOT_LOW_AMOUNT", "500.0"))

    # ── Rules Agent ──
    rules_model_path: str = os.getenv("NEXUS_RULES_MODEL", "models/granite-4.0-1b-nano-Q4_K_M.gguf")
    rules_max_invoice_amount: float = float(os.getenv("NEXUS_RULES_MAX_AMOUNT", "100000.0"))
    rules_require_nip_validation: bool = os.getenv("NEXUS_RULES_REQUIRE_NIP", "1") == "1"

    # ── Analytics Agent ──
    analytics_model_path: str = os.getenv("NEXUS_ANALYTICS_MODEL", "models/qwen2.5-1.5b-instruct-Q4_K_M.gguf")
    fin_detective_model_path: str = os.getenv("NEXUS_FIN_DETECTIVE_MODEL", "models/fin-rwkv-169m.pth")
    analytics_anomaly_threshold: float = float(os.getenv("NEXUS_ANALYTICS_ANOMALY_THRESHOLD", "2.0"))

    # ── NATS ──
    nats_url: str = os.getenv("NEXUS_NATS_URL", "nats://localhost:4222")

    # ── Decision Agent ──
    decision_timeout_seconds: int = int(os.getenv("NEXUS_DECISION_TIMEOUT", "60"))

    # ── Orchestrator Agent ──
    orchestrator_model_path: str = os.getenv("NEXUS_ORCHESTRATOR_MODEL", "models/LittleLamb-0.3B-Q4_K_M.gguf")

    # ── Memory & timeout ──
    autopilot_model_ttl_seconds: int = int(os.getenv("NEXUS_AUTOPILOT_MODEL_TTL", "600"))
    autopilot_agent_timeout_seconds: int = int(os.getenv("NEXUS_AUTOPILOT_AGENT_TIMEOUT", "30"))

    # ── Computed properties (as methods for Struct compatibility) ──

    @property
    def autopilot_vendor_alpha_proximity_min(self) -> int:
        return int(os.getenv("NEXUS_AUTOPILOT_VENDOR_ALPHA_MIN", "3"))

    @classmethod
    def create(cls) -> AppConfig:
        """Create AppConfig instance and run post-init validation.

        Zastępuje ``AppConfig()`` — msgspec.Struct nie woła __post_init__
        automatycznie, więc ta metoda zapewnia walidację.
        """
        instance = cls()
        instance.validate()
        return instance

    def validate(self) -> None:
        """Validate config after initialization. Call after creating instance."""
        self.environment = self.environment.lower().strip()
        if self.environment not in {"dev", "stage", "prod"}:
            raise ConfigValidationError(
                "NEXUS_ENV must be one of: dev, stage, prod"
            )

        self.base_dir = Path(self.base_dir).resolve() if isinstance(self.base_dir, str) else self.base_dir.resolve()
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

    # ── Computed paths ──

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
        if not raw or raw == "*":
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
