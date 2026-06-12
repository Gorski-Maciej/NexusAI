"""Central runtime configuration and startup validation.

Zastępuje: .env + python-dotenv → msgspec TOML (ultraszybki, mniejszy narzut)
Zgodnie z aa3fvcx.txt:
- msgspec ma wbudowany parser TOML — nie potrzebuje python-dotenv
- Konfiguracja w czystym TOML zamiast .env
"""
from __future__ import annotations

import base64
import binascii
import importlib.util
import os
import time
from collections.abc import Callable
from pathlib import Path
from typing import Any

from msgspec import Struct, toml

from nexus_ai.core.logger import get_logger

logger = get_logger(__name__)

ENV_CONFIG_DIR: Path = Path(__file__).resolve().parent.parent / "config"
"""Directory containing environment-specific TOML config files (nexus_ai/config/).

Zgodnie z aa3fvcx.txt: konfiguracja w czystym TOML, parsowana przez msgspec.
Katalog config/ znajduje się wewnątrz pakietu nexus_ai/ (nexus_ai/config/),
zawiera {env}.toml, protocols.toml, models_manifest.json, version.json.
"""


# ── ConfigLoader — mtime-based auto-reload dla TOML config ────────────────

class ConfigLoader:
    """Automatyczny loader config TOML z mtime-based auto-reload.

    Śledzi zmiany w config/{env}.toml (lub niestandardowym pliku) na podstawie
    st_mtime. Po wykryciu zmiany:
      1. Ponownie parsuje plik TOML
      2. Aktualizuje os.environ (nadpisuje istniejące wartości)
      3. Wywołuje zarejestrowane callbacki

    Args:
        path: Ścieżka do pliku TOML. Domyślnie config/{NEXUS_ENV}.toml.
        auto_reload: Jak często sprawdzać mtime.
                     False (domyślnie) — nigdy, tylko przy pierwszym dostępie.
                     True — co 5 sekund.
                     int > 0 — custom poll interval w sekundach.
    """

    def __init__(
        self,
        path: str | Path | None = None,
        auto_reload: bool | int = False,
    ) -> None:
        if path is not None:
            self._path = Path(path)
        else:
            env = os.getenv("NEXUS_ENV", "dev").lower().strip()
            self._path = ENV_CONFIG_DIR / f"{env}.toml"

        self._data: dict[str, Any] | None = None
        self._last_mtime: float = 0.0
        self._last_checked: float = 0.0
        self._on_change_callbacks: list[Callable[[], None]] = []

        # Wyznacz poll_interval z auto_reload
        self._auto_reload_enabled: bool = False
        self._poll_interval: float = 0.0
        if auto_reload is True:
            self._poll_interval = 5.0
            self._auto_reload_enabled = True
        elif isinstance(auto_reload, (int, float)) and auto_reload > 0:
            self._poll_interval = float(auto_reload)
            self._auto_reload_enabled = True

    # ── Public API ──────────────────────────────────────────────────────

    def load(self) -> dict[str, Any]:
        """Zwraca aktualne dane konfiguracyjne (lazy load + auto-reload)."""
        return self._load()

    def get_config(self) -> dict[str, Any]:
        """Alias dla load() — zwraca sparsowane dane TOML."""
        data = self._load()
        return dict(data) if data else {}

    def reload(self) -> None:
        """Wymuś przeładowanie pliku TOML."""
        self._data = None
        self._last_mtime = 0.0
        self._last_checked = 0.0
        self._load()

    def on_change(self, callback: Callable[[], None]) -> Callable[[], None]:
        """Zarejestruj callback wywoływany przy zmianie pliku.

        Args:
            callback: Funkcja bezargumentowa.

        Returns:
            Funkcja do wyrejestrowania (unsubscribe).
        """
        self._on_change_callbacks.append(callback)

        def unsubscribe() -> None:
            if callback in self._on_change_callbacks:
                self._on_change_callbacks.remove(callback)

        return unsubscribe

    # ── Wewnętrzne ──────────────────────────────────────────────────────

    def _load(self) -> dict[str, Any]:
        now = time.time()

        if not self._auto_reload_enabled:
            if self._data is not None:
                return self._data
            return self._read_file()

        # Rate-limiting
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

        logger.info("[ConfigLoader] File changed: %s — reloading config", self._path.name)
        return self._read_file()

    def _read_file(self) -> dict[str, Any]:
        if not self._path.exists():
            self._data = {}
            self._last_mtime = 0.0
            return self._data

        try:
            with open(self._path, "rb") as f:
                raw = toml.decode(f.read())
            self._data = raw if isinstance(raw, dict) else {}
            self._last_mtime = self._path.stat().st_mtime

            # Aktualizuj os.environ nowymi wartościami
            self._apply_to_environ(self._data)

            logger.info(
                "[ConfigLoader] Loaded %d sections from %s (mtime=%s)",
                len(self._data),
                self._path.name,
                self._last_mtime,
            )

            # Powiadom callbacki o zmianie
            self._fire_on_change_callbacks()

        except Exception as exc:
            logger.error("[ConfigLoader] Failed to load %s: %s", self._path, exc)
            if self._data is None:
                self._data = {}
            self._last_mtime = 0.0

        return self._data if self._data is not None else {}

    def _apply_to_environ(self, data: dict[str, Any]) -> None:
        """Zastosuj dane TOML do os.environ.

        UWAGA: Nie nadpisuje istniejących zmiennych środowiskowych — env vars
        mają wyższy priorytet niż TOML. Pozwala to Docker/Helm/K8s na
        wstrzykiwanie runtime overrides (np. NEXUS_JWT_SECRET).

        Mapowanie: TOML {"core": {"debug": true}} → NEXUS_DEBUG=1
        """
        count = 0
        for _section, section_data in data.items():
            if isinstance(section_data, dict):
                for key, value in section_data.items():
                    env_key = key.upper()
                    if not env_key.startswith("NEXUS_"):
                        env_key = f"NEXUS_{env_key}"
                    # Nie nadpisuj istniejących env vars — env > TOML
                    if env_key not in os.environ:
                        if isinstance(value, bool):
                            os.environ[env_key] = "1" if value else "0"
                        else:
                            os.environ[env_key] = str(value)
                        count += 1

        if count > 0:
            logger.debug("[ConfigLoader] Set %d env vars from %s", count, self._path.name)

    def _fire_on_change_callbacks(self) -> None:
        """Wywołaj wszystkie zarejestrowane callbacki (z izolacją błędów)."""
        for callback in self._on_change_callbacks:
            try:
                callback()
            except Exception as exc:
                logger.error("[ConfigLoader] on_change callback failed: %s", exc)

    def __getitem__(self, key: str) -> Any:
        """Bezpośredni dostęp do kluczy konfiguracji."""
        data = self._load()
        return data.get(key, {})


# ── Global singleton ──────────────────────────────────────────────────────

_default_config_loader: ConfigLoader | None = None


def get_config_loader(
    path: str | Path | None = None,
    auto_reload: bool | int = False,
) -> ConfigLoader:
    """Zwraca globalną instancję ConfigLoader (singleton).

    Args:
        path: Opcjonalna ścieżka do config TOML (pierwsze wywołanie).
        auto_reload: Czy i jak często sprawdzać zmiany.

    Returns:
        Globalna instancja ConfigLoader.
    """
    global _default_config_loader
    if _default_config_loader is None:
        _default_config_loader = ConfigLoader(path=path, auto_reload=auto_reload)
    return _default_config_loader


# ── Legacyjne funkcje ładowania (kompatybilność wsteczna) ────────────────

def _load_toml_profile(environment: str) -> None:
    """Load environment-specific config from config/{env}.toml.

    .. deprecated::
       Użyj ConfigLoader.load() lub get_config_loader().load() zamiast tej funkcji.
       Ta funkcja jest zachowana dla kompatybilności wstecznej — ładuje config
       tylko raz przy imporcie, bez auto-reload.

    Ustawia zmienne w os.environ (kompatybilność wsteczna z kodem używającym os.getenv).
    Mapowanie: TOML {"core": {"debug": true}} → NEXUS_DEBUG=1
    """
    profile_path = ENV_CONFIG_DIR / f"{environment}.toml"
    if not profile_path.exists():
        legacy_path = ENV_CONFIG_DIR / f"{environment}.env"
        if legacy_path.exists():
            _load_legacy_env(legacy_path)
        return

    try:
        with open(profile_path, "rb") as f:
            data: dict[str, Any] = toml.decode(f.read())

        loaded = 0
        for _section, section_data in data.items():
            if isinstance(section_data, dict):
                for key, value in section_data.items():
                    env_key = key.upper()
                    if not env_key.startswith("NEXUS_"):
                        env_key = f"NEXUS_{env_key}"
                    if env_key not in os.environ:
                        if isinstance(value, bool):
                            os.environ[env_key] = "1" if value else "0"
                        else:
                            os.environ[env_key] = str(value)
                        loaded += 1

        if loaded > 0:
            print(f"[Config] Loaded {loaded} settings from {profile_path.name}")
    except Exception as exc:
        print(f"[Config] Warning: Failed to load {profile_path.name}: {exc}")


def _load_legacy_env(env_path: Path) -> None:
    """Legacy .env loader for backward compatibility."""
    loaded = 0
    with open(env_path, encoding="utf-8") as f:
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
        print(f"[Config] Loaded {loaded} settings from {env_path.name} (legacy .env format)")


# ── Load environment profile at import time ────────────────────────────────
_env = os.getenv("NEXUS_ENV", "dev").lower().strip()
_load_toml_profile(_env)


def _load_secrets_symbols():
    try:
        spec = importlib.util.find_spec("nexus_ai.core.secrets")
    except ModuleNotFoundError:
        spec = None
    if spec is not None:
        from nexus_ai.core.secrets import LocalSecretsCache, OfflineFirstSecretResolver
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
    Wczytuje wartości BEZPOŚREDNIO z pliku TOML (przez msgspec.toml.decode),
    a nie przez os.environ. Zmienne środowiskowe mają wyższy priorytet niż TOML,
    co pozwala Docker/K8s na runtime overrides.

    Uwaga: msgspec.Struct nie wywołuje automatycznie ``__post_init__``.
    Użyj ``AppConfig.create()`` która woła walidację po inicjalizacji.
    """

    # ── Core ──
    environment: str = "dev"
    base_dir: str = "."

    # ── JWT configuration ──
    jwt_expiration_seconds: int = 900
    refresh_token_days: int = 30
    jwt_issuer: str = "nexus-ai"
    jwt_audience: str = "nexus-api"

    # ── CSRF ──
    csrf_enabled: bool = True

    # ── Connection pool limits ──
    db_pool_size: int = 5
    db_pool_overflow: int = 10
    nats_max_reconnect: int = 10
    nats_reconnect_delay_seconds: int = 2

    # ── Retry policy defaults (stamina) ──
    max_task_retries: int = 3
    retry_backoff_base_seconds: float = 1.0
    retry_backoff_max_seconds: float = 60.0

    # ── Database ──
    sqlite_file_name: str = "app_data/databases/nexus_oltp.db"
    duckdb_file_name: str = "app_data/databases/nexus_olap.duckdb"
    storage_dir_name: str = "app_data/uploads"
    idempotency_db_name: str = "app_data/databases/idempotency.sqlite"
    debug: bool = False
    sqlcipher_key_env: str = "NEXUS_SQLCIPHER_KEY"

    jwt_secret: str = ""
    encryption_key: str = ""

    duckdb_memory_limit: str = "512MB"
    duckdb_threads: int = 2
    cors_origins_raw: str = "*"
    max_invoice_upload_mb: int = 50
    max_attachment_upload_mb: int = 500
    dpo_alert_webhook: str = ""
    outbox_replay_limit: int = 100
    migration_baseline_name: str = "migration_rowcount_baseline.json"
    migration_checksum_baseline_name: str = "migration_checksum_baseline.json"

    # ── Decision thresholds ──
    autopilot_auto_post_threshold: float = 0.92
    autopilot_suggest_threshold: float = 0.75
    autopilot_ask_threshold: float = 0.50

    # ── Adaptation ──
    autopilot_adaptation_enabled: bool = True
    autopilot_adaptation_learning_rate: float = 0.05
    autopilot_low_amount_threshold: float = 500.0

    # ── Rules ──
    rules_max_invoice_amount: float = 100000.0
    rules_require_nip_validation: bool = True
    analytics_anomaly_threshold: float = 2.0

    # ── NATS ──
    nats_url: str = "nats://localhost:4222"

    # ── Timeouts ──
    decision_timeout_seconds: int = 60

    # ── Computed properties (as methods for Struct compatibility) ──

    @property
    def autopilot_vendor_alpha_proximity_min(self) -> int:
        return int(os.getenv("NEXUS_AUTOPILOT_VENDOR_ALPHA_MIN", "3"))

    # ── TOML ↔ env var mapping ──

    _ENV_MAP: dict[str, str] = {
        "environment": "NEXUS_ENV",
        "base_dir": "NEXUS_BASE_DIR",
        "jwt_expiration_seconds": "NEXUS_JWT_EXPIRATION_SECONDS",
        "refresh_token_days": "NEXUS_REFRESH_TOKEN_DAYS",
        "jwt_issuer": "NEXUS_JWT_ISSUER",
        "jwt_audience": "NEXUS_JWT_AUDIENCE",
        "csrf_enabled": "NEXUS_CSRF_ENABLED",
        "db_pool_size": "NEXUS_DB_POOL_SIZE",
        "db_pool_overflow": "NEXUS_DB_POOL_OVERFLOW",
        "nats_max_reconnect": "NEXUS_NATS_MAX_RECONNECT",
        "nats_reconnect_delay_seconds": "NEXUS_NATS_RECONNECT_DELAY",
        "max_task_retries": "NEXUS_MAX_TASK_RETRIES",
        "retry_backoff_base_seconds": "NEXUS_RETRY_BACKOFF_BASE",
        "retry_backoff_max_seconds": "NEXUS_RETRY_BACKOFF_MAX",
        "sqlite_file_name": "NEXUS_SQLITE_FILE",
        "duckdb_file_name": "NEXUS_DUCKDB_FILE",
        "storage_dir_name": "NEXUS_STORAGE_DIR",
        "idempotency_db_name": "NEXUS_IDEMPOTENCY_DB",
        "debug": "NEXUS_DEBUG",
        "sqlcipher_key_env": "NEXUS_SQLCIPHER_KEY_ENV",
        "jwt_secret": "NEXUS_JWT_SECRET",
        "encryption_key": "NEXUS_ENCRYPTION_KEY",
        "duckdb_memory_limit": "NEXUS_DUCKDB_MEMORY_LIMIT",
        "duckdb_threads": "NEXUS_DUCKDB_THREADS",
        "cors_origins_raw": "NEXUS_CORS_ORIGINS",
        "max_invoice_upload_mb": "NEXUS_MAX_INVOICE_UPLOAD_MB",
        "max_attachment_upload_mb": "NEXUS_MAX_ATTACHMENT_UPLOAD_MB",
        "dpo_alert_webhook": "NEXUS_DPO_ALERT_WEBHOOK",
        "outbox_replay_limit": "NEXUS_OUTBOX_REPLAY_LIMIT",
        "migration_baseline_name": "NEXUS_MIGRATION_BASELINE_FILE",
        "migration_checksum_baseline_name": "NEXUS_MIGRATION_CHECKSUM_BASELINE_FILE",
        "autopilot_auto_post_threshold": "NEXUS_AUTOPILOT_AUTO_POST",
        "autopilot_suggest_threshold": "NEXUS_AUTOPILOT_SUGGEST",
        "autopilot_ask_threshold": "NEXUS_AUTOPILOT_ASK",
        "autopilot_adaptation_enabled": "NEXUS_AUTOPILOT_ADAPTATION",
        "autopilot_adaptation_learning_rate": "NEXUS_AUTOPILOT_LEARNING_RATE",
        "autopilot_low_amount_threshold": "NEXUS_AUTOPILOT_LOW_AMOUNT",
        "rules_max_invoice_amount": "NEXUS_RULES_MAX_AMOUNT",
        "rules_require_nip_validation": "NEXUS_RULES_REQUIRE_NIP",
        "analytics_anomaly_threshold": "NEXUS_ANALYTICS_ANOMALY_THRESHOLD",
        "nats_url": "NEXUS_NATS_URL",
        "decision_timeout_seconds": "NEXUS_DECISION_TIMEOUT",
    }

    # ── TOML field → section.key mapping ──
    # Mapuje nazwy pól AppConfig na ścieżki w strukturze TOML
    _TOML_MAP: dict[str, str] = {
        "environment": "app.environment",
        "base_dir": "app.base_dir",
        "jwt_expiration_seconds": "app.jwt_expiration_seconds",
        "refresh_token_days": "app.refresh_token_days",
        "jwt_issuer": "app.jwt_issuer",
        "jwt_audience": "app.jwt_audience",
        "csrf_enabled": "app.csrf_enabled",
        "db_pool_size": "app.db_pool_size",
        "db_pool_overflow": "app.db_pool_overflow",
        "nats_max_reconnect": "app.nats_max_reconnect",
        "nats_reconnect_delay_seconds": "app.nats_reconnect_delay_seconds",
        "max_task_retries": "app.max_task_retries",
        "retry_backoff_base_seconds": "app.retry_backoff_base_seconds",
        "retry_backoff_max_seconds": "app.retry_backoff_max_seconds",
        "sqlite_file_name": "app.sqlite_file",
        "duckdb_file_name": "app.duckdb_file",
        "storage_dir_name": "app.storage_dir",
        "idempotency_db_name": "app.idempotency_db",
        "debug": "app.debug",
        "sqlcipher_key_env": "app.sqlcipher_key_env",
        "duckdb_memory_limit": "app.duckdb_memory_limit",
        "duckdb_threads": "app.duckdb_threads",
        "cors_origins_raw": "app.cors_origins",
        "max_invoice_upload_mb": "app.max_invoice_upload_mb",
        "max_attachment_upload_mb": "app.max_attachment_upload_mb",
        "dpo_alert_webhook": "integrations.dpo_alert_webhook",
        "outbox_replay_limit": "app.outbox_replay_limit",
        "migration_baseline_name": "app.migration_baseline_file",
        "migration_checksum_baseline_name": "app.migration_checksum_baseline_file",
        "autopilot_auto_post_threshold": "app.autopilot_auto_post_threshold",
        "autopilot_suggest_threshold": "app.autopilot_suggest_threshold",
        "autopilot_ask_threshold": "app.autopilot_ask_threshold",
        "autopilot_adaptation_enabled": "app.autopilot_adaptation_enabled",
        "autopilot_adaptation_learning_rate": "app.autopilot_adaptation_learning_rate",
        "autopilot_low_amount_threshold": "app.autopilot_low_amount_threshold",
        "rules_max_invoice_amount": "app.rules_max_invoice_amount",
        "rules_require_nip_validation": "app.rules_require_nip_validation",
        "analytics_anomaly_threshold": "app.analytics_anomaly_threshold",
        "nats_url": "nats.url",
        "decision_timeout_seconds": "app.decision_timeout_seconds",
    }

    @classmethod
    def _load_toml_file(cls, env: str | None = None) -> dict[str, Any]:
        """Wczytaj plik TOML dla danego środowiska.

        Args:
            env: Nazwa środowiska ("dev", "stage", "prod").
                 Domyślnie z NEXUS_ENV lub "dev".

        Returns:
            Sparsowany słownik TOML.
        """
        if env is None:
            env = os.getenv("NEXUS_ENV", "dev").lower().strip()
        toml_path = ENV_CONFIG_DIR / f"{env}.toml"
        if not toml_path.exists():
            logger.warning("[Config] TOML file not found: %s — using defaults", toml_path)
            return {}
        try:
            with open(toml_path, "rb") as f:
                data: dict[str, Any] = toml.decode(f.read())
            logger.info("[Config] Loaded TOML: %s (%d sections)", toml_path.name, len(data))
            return data
        except Exception as exc:
            logger.warning("[Config] Failed to load %s: %s — using defaults", toml_path, exc)
            return {}

    @classmethod
    def _resolve_field_value(
        cls,
        field_name: str,
        toml_data: dict[str, Any],
    ) -> Any | None:
        """Rozwiąż wartość pola: env var > TOML > None (użyj defaultu Structu).

        Args:
            field_name: Nazwa pola w AppConfig.
            toml_data: Sparsowany słownik TOML.

        Returns:
            Wartość lub None (oznacza "użyj defaultu z klasy").
        """
        # 1. Sprawdź zmienną środowiskową
        env_key = cls._ENV_MAP.get(field_name)
        if env_key and env_key in os.environ:
            raw = os.environ[env_key]
            field_type = cls._get_field_type(field_name)
            return cls._cast(raw, field_type)

        # 2. Sprawdź TOML
        toml_path = cls._TOML_MAP.get(field_name)
        if toml_path and toml_data:
            parts = toml_path.split(".")
            val: Any = toml_data
            for part in parts:
                if isinstance(val, dict):
                    val = val.get(part)
                else:
                    val = None
                    break
            if val is not None:
                return val

        # 3. Ani env, ani TOML — użyj defaultu zdefiniowanego w klasie
        return None

    @classmethod
    def _get_field_type(cls, field_name: str) -> type:
        """Pobierz typ pola Struct po nazwie.

        msgspec.Struct.__struct_fields__ to krotka ``msgspec.inspect.Field``,
        indeksowana pozycyjnie — używamy pętli zamiast ``__struct_fields__[name]``.

        Args:
            field_name: Nazwa pola.

        Returns:
            Typ pola (domyślnie ``str`` jeśli nie znaleziono).
        """
        for f in cls.__struct_fields__:
            if f.name == field_name:
                return f.type
        return str

    @staticmethod
    def _cast(raw: str, target_type: type) -> Any:
        """Rzutuj string na docelowy typ.

        Obsługuje: bool, int, float, Path, str (domyślnie).
        """
        if target_type is bool:
            return raw.lower() in ("1", "true", "yes")
        if target_type is int:
            return int(raw)
        if target_type is float:
            return float(raw)
        if target_type is str:
            return raw
        if target_type is Path:
            return Path(raw)
        return raw

    @classmethod
    def from_toml(cls, env: str | None = None) -> AppConfig:
        """Utwórz AppConfig z bezpośrednim parsowaniem TOML.

        Priority: env var > TOML value > hardcoded Struct default.

        Args:
            env: Nazwa środowiska ("dev", "stage", "prod").

        Returns:
            Zwalidowana instancja AppConfig.
        """
        if env is None:
            env = os.getenv("NEXUS_ENV", "dev").lower().strip()

        toml_data = cls._load_toml_file(env)
        kwargs: dict[str, Any] = {}

        for field_name in cls.__struct_fields__:
            value = cls._resolve_field_value(field_name, toml_data)
            if value is not None:
                kwargs[field_name] = value

        # env i base_dir wymagają specjalnego traktowania
        if "environment" not in kwargs:
            kwargs["environment"] = env

        instance = cls(**kwargs)
        instance.validate()
        return instance

    @classmethod
    def create(cls) -> AppConfig:
        """Create AppConfig instance and run post-init validation.

        Od Fazy 2: używa ``from_toml()`` zamiast ``os.environ``.
        Zachowane dla kompatybilności wstecznej.
        """
        return cls.from_toml()

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


