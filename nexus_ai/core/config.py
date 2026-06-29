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
from collections.abc import Callable
from pathlib import Path
from typing import Any, ClassVar

import pendulum

from msgspec import Struct, toml

from nexus_ai.core.logger import get_logger


# ── Helper: deep merge dwóch słowników (base ← env-specific) ───────────────
# env-specific wartości nadpisują base. Sekcje są mergowane rekurencyjnie.


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> None:
    """Rekurencyjne scalanie słowników — override nadpisuje base.

    Args:
        base: Słownik bazowy (modyfikowany in-place).
        override: Słownik nadpisujący.
    """
    for key, value in override.items():
        if key in base and isinstance(base[key], dict) and isinstance(value, dict):
            deep_merge(base[key], value)
        else:
            base[key] = value


logger = get_logger(__name__)

ENV_CONFIG_DIR: Path = Path(__file__).resolve().parent.parent / "config"
"""Directory containing environment-specific TOML config files (nexus_ai/config/).

Zgodnie z aa3fvcx.txt: konfiguracja w czystym TOML, parsowana przez msgspec.
Katalog config/ znajduje się wewnątrz pakietu nexus_ai/ (nexus_ai/config/),
zawiera {env}.toml, protocols.toml, models_manifest.json, version.json.
"""


# ── ConfigLoader — mtime-based auto-reload dla TOML config ────────────────


class ConfigLoader:
    """mtime-based auto-reload dla TOML config.

    Laduje config/base.toml jako baze (wspolne wartosci)
    i nadpisuje config/{env}.toml (srodowiskowe wartosci).

    Args:
        path: Sciezka do pliku TOML. Domyslnie config/{NEXUS_ENV}.toml.
              UWAGA: base.toml jest ladowany automatycznie przed env-specific.
        auto_reload: Jak czesto sprawdzac mtime.
                     False (domyslnie) — nigdy, tylko przy pierwszym dostepie.
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
            self._base_path: Path | None = None
        else:
            env = os.getenv("NEXUS_ENV", "dev").lower().strip()
            self._path = ENV_CONFIG_DIR / f"{env}.toml"
            self._base_path = ENV_CONFIG_DIR / "base.toml"

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
        now = pendulum.now().timestamp()

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
            # 1. Załaduj base.toml (wspólne wartości)
            merged: dict[str, Any] = {}
            if self._base_path and self._base_path.exists():
                with open(self._base_path, "rb") as f:
                    base_raw = toml.decode(f.read())
                if isinstance(base_raw, dict):
                    merged = base_raw

            # 2. Załaduj env-specific config i nadpisz
            with open(self._path, "rb") as f:
                env_raw = toml.decode(f.read())
            if isinstance(env_raw, dict):
                deep_merge(merged, env_raw)

            self._data = merged
            self._last_mtime = self._path.stat().st_mtime

            # Aktualizuj os.environ nowymi wartościami
            self._apply_to_environ(self._data)

            logger.info(
                "[ConfigLoader] Loaded+merged %d sections (base + %s)",
                len(self._data),
                self._path.name,
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
        mają wyższy priorytet niż TOML. Pozwala to na
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


# ── Global singleton (thread-safe dla free-threaded Python) ───────────────

import threading as _threading

default_config_loader_lock = _threading.Lock()
_default_config_loader: ConfigLoader | None = None


def get_config_loader(
    path: str | Path | None = None,
    auto_reload: bool | int = False,
) -> ConfigLoader:
    """Zwraca globalną instancję ConfigLoader (singleton).

    Thread-safe — używa ``threading.Lock`` dla free-threaded Python 3.13t.

    Args:
        path: Opcjonalna ścieżka do config TOML (pierwsze wywołanie).
        auto_reload: Czy i jak często sprawdzać zmiany.

    Returns:
        Globalna instancja ConfigLoader.
    """
    global _default_config_loader
    if _default_config_loader is None:
        with default_config_loader_lock:
            if _default_config_loader is None:
                _default_config_loader = ConfigLoader(path=path, auto_reload=auto_reload)
    return _default_config_loader


# ══════════════════════════════════════════════════════════════════════════
# msgspec.toml typed schema — Fazа 2
# Zgodnie z aa3fvcx.txt (Punkt 2): msgspec.toml.decode z type=... daje
# typowaną walidację TOML z czytelnymi błędami (DecodeError + ValidationError).
# Zastępuje ręczne mapowanie TOML→Struct przez _TOML_MAP i _resolve_field_value.
# ══════════════════════════════════════════════════════════════════════════


from typing import Annotated
from msgspec import Meta


class _AppSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [app] w config/{env}.toml.

    są walidowane przy parsowaniu przez msgspec. Błędy zakresu → logowane,
    aplikacja używa bezpiecznych defaultów z AppConfig.
    """

    # ── Core ──
    environment: str | None = None
    base_dir: str | None = None
    host: str | None = None
    port: Annotated[int | None, Meta(ge=1, le=65535)] = None
    log_level: str | None = None
    debug: bool | None = None

    # ── JWT ──
    jwt_expiration_seconds: Annotated[int | None, Meta(ge=60, le=86400)] = None
    refresh_token_days: Annotated[int | None, Meta(ge=1, le=365)] = None
    jwt_issuer: str | None = None
    jwt_audience: str | None = None
    csrf_enabled: bool | None = None

    # ── Database ──
    sqlite_file: str | None = None
    duckdb_file: str | None = None
    storage_dir: str | None = None
    idempotency_db: str | None = None
    sqlcipher_key_env: str | None = None
    duckdb_memory_limit: str | None = None
    duckdb_threads: Annotated[int | None, Meta(ge=1, le=64)] = None

    # ── CORS ──
    cors_origins: str | None = None

    # ── Connection pools ──
    db_pool_size: Annotated[int | None, Meta(ge=1, le=100)] = None
    db_pool_overflow: Annotated[int | None, Meta(ge=0, le=200)] = None
    nats_max_reconnect: Annotated[int | None, Meta(ge=0, le=100)] = None
    nats_reconnect_delay_seconds: Annotated[float | None, Meta(ge=0.1, le=60)] = None

    # ── Upload limits ──
    max_invoice_upload_mb: Annotated[int | None, Meta(ge=1, le=1000)] = None
    max_attachment_upload_mb: Annotated[int | None, Meta(ge=1, le=10000)] = None

    # ── Retry (stamina) ──
    max_task_retries: Annotated[int | None, Meta(ge=0, le=20)] = None
    retry_backoff_base_seconds: Annotated[float | None, Meta(ge=0.1, le=30)] = None
    retry_backoff_max_seconds: Annotated[float | None, Meta(ge=1.0, le=300)] = None

    # ── Outbox ──
    outbox_replay_limit: Annotated[int | None, Meta(ge=1, le=10000)] = None

    # ── Migration ──
    migration_baseline_file: str | None = None
    migration_checksum_baseline_file: str | None = None

    # ── Decision Engine ──
    autopilot_auto_post_threshold: Annotated[float | None, Meta(ge=0.0, le=1.0)] = None
    autopilot_suggest_threshold: Annotated[float | None, Meta(ge=0.0, le=1.0)] = None
    autopilot_ask_threshold: Annotated[float | None, Meta(ge=0.0, le=1.0)] = None
    autopilot_adaptation_enabled: bool | None = None
    autopilot_adaptation_learning_rate: Annotated[float | None, Meta(ge=0.0, le=1.0)] = None
    autopilot_low_amount_threshold: Annotated[float | None, Meta(ge=0.0)] = None
    rules_max_invoice_amount: Annotated[float | None, Meta(ge=0.0)] = None
    rules_require_nip_validation: bool | None = None
    analytics_anomaly_threshold: Annotated[float | None, Meta(ge=0.0)] = None
    decision_timeout_seconds: Annotated[int | None, Meta(ge=5, le=600)] = None


class _NatsSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [nats]."""

    url: str | None = None
    max_reconnect: int | None = None
    reconnect_delay_seconds: int | None = None


class _StorageSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [storage].

    - protocol: "file", "s3", "sftp", "memory", "zip" — zmiana backendu bez zmiany kodu
    - root: ścieżka bazowa w wybranym protokole
    - auto_mkdir: automatyczne tworzenie katalogów
    - cache_size: rozmiar cache dla CachingFileSystem (w MB, 0 = wyłączony)

    Używane przez: services/storage.py, core/exporters/storage.py, api/services.py,
    api/routes/invoices.py, api/controllers/invoices.py, scripts/backup.py.
    """

    protocol: str | None = None
    root: str | None = None
    auto_mkdir: bool | None = None
    cache_size_mb: Annotated[int | None, Meta(ge=0, le=10240)] = None
    chain_cache_storage: str | None = None  # Ścieżka cache dla chain FS


class _StaminaSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [stamina].

    Globalne stamina settings dla resilience (retry, circuit breaker).
    """

    retry_attempts: Annotated[int | None, Meta(ge=1, le=20)] = None
    retry_timeout: Annotated[float | None, Meta(ge=1.0, le=300.0)] = None
    circuit_breaker_enabled: bool | None = None
    circuit_breaker_cooldown: Annotated[float | None, Meta(ge=5.0, le=600.0)] = None


class _SecuritySection(Struct, kw_only=True):
    """msgspec schema dla sekcji [security].

    - jwt_exclude_paths: ścieżki publiczne (bez JWT auth)
    - csrf_exclude_paths: ścieżki bez CSRF (np. auth endpoints)
    - rate_limit_auth: limit dla /api/auth (brute-force protection)
    - rate_limit_general: limit dla pozostałych endpointów
    """

    jwt_exclude_paths: list[str] | None = None
    csrf_exclude_patterns: list[str] | None = None
    rate_limit_auth: Annotated[int | None, Meta(ge=1, le=100)] = None
    rate_limit_upload: Annotated[int | None, Meta(ge=1, le=200)] = None
    rate_limit_general: Annotated[int | None, Meta(ge=1, le=1000)] = None


class _IntegrationsSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [integrations]."""

    dpo_alert_webhook: str | None = None


# ── NOWE SEKCJE TOML (FAZA 1 AUDYTU) ─────────────────────────────────


class _TaxSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [tax] w config/{env}.toml.

    Sekcja [tax] istnieje w dev.toml i prod.toml, ale była
    wcześniej ignorowana przez typed schema — parsowana tylko jako dict.
    """

    default_vat_rate: Annotated[int | None, Meta(ge=0, le=100)] = None
    cit_rate: Annotated[float | None, Meta(ge=0, le=100)] = None
    linear_rate: Annotated[float | None, Meta(ge=0, le=100)] = None
    lump_sum_rates: list[float] | None = None
    vat_exempt_threshold: Annotated[float | None, Meta(ge=0)] = None
    vat_quarterly_threshold: Annotated[float | None, Meta(ge=0)] = None


class _AiSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [ai] w config/{env}.toml.

    Zgodnie z audytem: ścieżki modeli AI zdefiniowane w TOML zamiast
    w kodzie. Walidacja przez msgspec przy starcie.
    """

    council_alpha_model: str | None = None
    council_beta_model: str | None = None
    council_gamma_model: str | None = None
    rules_model: str | None = None
    analytics_model: str | None = None
    decision_jamba_model: str | None = None
    decision_granite_model: str | None = None
    orchestrator_model: str | None = None
    ocr_model: str | None = None
    vision_model: str | None = None
    embedding_model: str | None = None


class _TigerbeetleSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [tigerbeetle] w config/{env}.toml."""

    cluster_id: int | None = None
    replica_addresses: str | None = None


class _OpaSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [opa] w config/{env}.toml.

    OPA (Open Policy Agent) — deklaratywny silnik reguł (CNCF).
    Działa jako sidecar process (podobnie jak NATS, TigerBeetle).

    Zgodnie z aa3fvcx.txt:
    - OPA jako silnik reguł podatkowych
    - REST API na localhost:8181
    - Rego policies generowane dynamicznie z DuckDB
    """

    enabled: bool | None = None
    url: str | None = None
    timeout_seconds: Annotated[float | None, Meta(ge=1.0, le=60.0)] = None
    auto_sync_policy: bool | None = None
    policy_package: str | None = None
    policy_rule: str | None = None


class _TomlConfigRoot(Struct, kw_only=True):
    """msgspec schema dla całego pliku config/{env}.toml.

    zakresami (Annotated[T, Meta(ge=..., le=...)]) i wartościami
    domyślnymi. Każdy błąd typu → logowany przy starcie.

    Sekcje:
    - app: konfiguracja aplikacji (host, port, JWT, DB, decision engine)
    - nats: NATS JetStream broker
    - stamina: resilience (retry, circuit breaker)
    - storage: fsspec filesystem abstraction
    - security: Litestar security (JWT exclude, CSRF, rate limit)
    - integrations: zewnętrzne API webhooki
    - tax: konfiguracja podatkowa (VAT, CIT, ryczałt)
    - ai: ścieżki modeli AI
    - tigerbeetle: double-entry ledger
    - opa: Open Policy Agent (reguły podatkowe)
    """

    app: _AppSection | None = None
    nats: _NatsSection | None = None
    stamina: _StaminaSection | None = None
    storage: _StorageSection | None = None
    security: _SecuritySection | None = None
    integrations: _IntegrationsSection | None = None
    tax: _TaxSection | None = None
    ai: _AiSection | None = None
    tigerbeetle: _TigerbeetleSection | None = None
    opa: _OpaSection | None = None


# ── Legacyjne funkcje ładowania (kompatybilność wsteczna) ────────────────


def _load_toml_profile(environment: str) -> None:
    """Load environment-specific config from config/{env}.toml.

    .. deprecated::
       Użyj ConfigLoader.load() lub get_config_loader().load() zamiast tej funkcji.
       Ta funkcja jest zachowana dla kompatybilności wstecznej — ładuje config
       tylko raz przy imporcie, bez auto-reload.

    config/{env}.toml.    Wspólne sekcje (tax, ai, tigerbeetle, security)
    są definiowane RAZ w base.toml zamiast duplikować w dev.toml i prod.toml.

    Ustawia zmienne w os.environ (kompatybilność wsteczna z kodem używającym os.getenv).
    Mapowanie: TOML {"core": {"debug": true}} → NEXUS_DEBUG=1
    """
    profile_path = ENV_CONFIG_DIR / f"{environment}.toml"
    base_path = ENV_CONFIG_DIR / "base.toml"

    if not profile_path.exists():
        legacy_path = ENV_CONFIG_DIR / f"{environment}.env"
        if legacy_path.exists():
            _load_legacy_env(legacy_path)
        return

    try:
        # 1. Załaduj base.toml (wspólne wartości dla wszystkich środowisk)
        merged: dict[str, Any] = {}
        if base_path.exists():
            with open(base_path, "rb") as f:
                base_raw = toml.decode(f.read())
            if isinstance(base_raw, dict):
                merged = base_raw

        # 2. Załaduj env-specific i nadpisz
        with open(profile_path, "rb") as f:
            env_raw = toml.decode(f.read())
        if isinstance(env_raw, dict):
            deep_merge(merged, env_raw)

        loaded = 0
        for _section, section_data in merged.items():
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


# ── AutoConfigMeta — generates _ENV_MAP and _TOML_FIELD_MAP from annotations ──
# Eliminates the manual 3-way mapping (TOML section + _TomlConfigRoot + AppConfig + _ENV_MAP + _TOML_FIELD_MAP)

class _AutoConfigMeta(type(Struct)):
    """Metaclass that auto-generates _ENV_MAP from field annotations.

    Convention: ``NEXUS_{UPPER_CASE_FIELD_NAME}`` for env var name.
    Must pass ``**kwargs`` through to ``super().__new__()`` to support
    msgspec kwargs like ``kw_only=True``.
    """
    def __new__(mcs, name, bases, namespace, **kwargs):
        cls = super().__new__(mcs, name, bases, namespace, **kwargs)
        if name == "AppConfig":
            env_map: dict[str, str] = {}
            for field_name in getattr(cls, '__struct_fields__', []):
                env_key = f"NEXUS_{field_name.upper()}"
                env_map[field_name] = env_key
            cls._ENV_MAP = env_map
        return cls


class AppConfig(Struct, kw_only=True, metaclass=_AutoConfigMeta):
    """Centralized application settings registry for all environments.

    msgspec.Struct — lżejszy i szybszy niż dataclass.
    _ENV_MAP is auto-generated by _AutoConfigMeta metaclass.
    _TOML_FIELD_MAP uses standard naming convention for TOML sections.

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

    # ── Globalne stamina settings ──
    stamina_retry_attempts: int = 3
    stamina_retry_timeout: float = 10.0
    stamina_circuit_breaker_enabled: bool = True
    stamina_circuit_breaker_cooldown: float = 60.0

    # ── fsspec — jednolita abstrakcja systemów plików ──
    storage_protocol: str = "file"
    storage_root: str = "app_data/uploads"
    storage_auto_mkdir: bool = True
    storage_cache_size_mb: int = 0
    storage_transactional: bool = False
    storage_chain_enabled: bool = False
    storage_chain_cache_storage: str = "app_data/fsspec_cache"

    # ── Litestar Security — konfigurowalne z TOML ──
    jwt_exclude_paths: list[str] | None = None
    csrf_exclude_patterns: list[str] | None = None
    rate_limit_auth: int = 10
    rate_limit_upload: int = 30
    rate_limit_general: int = 60

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

    # ── OPA (Open Policy Agent) ──
    opa_enabled: bool = True
    opa_url: str = "http://localhost:8181"
    opa_timeout_seconds: float = 10.0
    opa_auto_sync_policy: bool = True
    opa_policy_package: str = "tax.rules"
    opa_policy_rule: str = "decide"

    # ── Computed properties (as methods for Struct compatibility) ──

    @property
    def autopilot_vendor_alpha_proximity_min(self) -> int:
        return int(os.getenv("NEXUS_AUTOPILOT_VENDOR_ALPHA_MIN", "3"))

    # ── TOML ↔ env var mapping (auto-generated by _AutoConfigMeta) ──
    _ENV_MAP: ClassVar[dict[str, str]] = {}

    # ── Rejestr sekcji TOML dla auto-mapowania ──
    _TOML_FIELD_MAP: ClassVar[dict[str, tuple[str, str]]] = {
        "sqlite_file_name": ("app", "sqlite_file"), "duckdb_file_name": ("app", "duckdb_file"),
        "storage_dir_name": ("app", "storage_dir"), "idempotency_db_name": ("app", "idempotency_db"),
        "cors_origins_raw": ("app", "cors_origins"), "migration_baseline_name": ("app", "migration_baseline_file"),
        "migration_checksum_baseline_name": ("app", "migration_checksum_baseline_file"),
        "nats_url": ("nats", "url"), "stamina_retry_attempts": ("stamina", "retry_attempts"),
        "stamina_retry_timeout": ("stamina", "retry_timeout"), "stamina_circuit_breaker_enabled": ("stamina", "circuit_breaker_enabled"),
        "stamina_circuit_breaker_cooldown": ("stamina", "circuit_breaker_cooldown"),
        "storage_protocol": ("storage", "protocol"), "storage_root": ("storage", "root"),
        "storage_auto_mkdir": ("storage", "auto_mkdir"), "storage_cache_size_mb": ("storage", "cache_size_mb"),
        "storage_transactional": ("storage", "transactional"), "storage_chain_enabled": ("storage", "chain_enabled"),
        "storage_chain_cache_storage": ("storage", "chain_cache_storage"),
        "max_invoice_upload_mb": ("app", "max_invoice_upload_mb"), "max_attachment_upload_mb": ("app", "max_attachment_upload_mb"),
        "jwt_expiration_seconds": ("app", "jwt_expiration_seconds"), "refresh_token_days": ("app", "refresh_token_days"),
        "db_pool_size": ("app", "db_pool_size"), "db_pool_overflow": ("app", "db_pool_overflow"),
        "max_task_retries": ("app", "max_task_retries"), "retry_backoff_base_seconds": ("app", "retry_backoff_base_seconds"),
        "retry_backoff_max_seconds": ("app", "retry_backoff_max_seconds"),
        "debug": ("app", "debug"), "environment": ("app", "environment"),
        "csrf_enabled": ("app", "csrf_enabled"), "duckdb_memory_limit": ("app", "duckdb_memory_limit"),
        "duckdb_threads": ("app", "duckdb_threads"),
        "autopilot_auto_post_threshold": ("app", "autopilot_auto_post_threshold"),
        "autopilot_suggest_threshold": ("app", "autopilot_suggest_threshold"),
        "autopilot_ask_threshold": ("app", "autopilot_ask_threshold"),
        "rules_max_invoice_amount": ("app", "rules_max_invoice_amount"),
        "analytics_anomaly_threshold": ("app", "analytics_anomaly_threshold"),
        "decision_timeout_seconds": ("app", "decision_timeout_seconds"),
        "opa_enabled": ("opa", "enabled"), "opa_url": ("opa", "url"),
        "opa_timeout_seconds": ("opa", "timeout_seconds"),
    }

    @classmethod
    def _load_toml_file(cls, env: str | None = None) -> _TomlConfigRoot:
        if env is None:
            env = os.getenv("NEXUS_ENV", "dev").lower().strip()
        toml_path = ENV_CONFIG_DIR / f"{env}.toml"
        if not toml_path.exists():
            return _TomlConfigRoot()
        try:
            with open(toml_path, "rb") as f:
                return toml.decode(f.read(), type=_TomlConfigRoot)
        except Exception as exc:
            logger.warning("[Config] TOML error in %s: %s — using defaults", toml_path, exc)
            return _TomlConfigRoot()

    @classmethod
    def _resolve_field_value(cls, field_name: str, toml_root: _TomlConfigRoot) -> Any | None:
        env_key = cls._ENV_MAP.get(field_name)
        if env_key and env_key in os.environ:
            return cls._cast(os.environ[env_key], cls._get_field_type(field_name))
        mapping = cls._TOML_FIELD_MAP.get(field_name)
        if mapping:
            section = getattr(toml_root, mapping[0], None)
            if section is not None and (value := getattr(section, mapping[1], None)) is not None:
                return value
        return None

    @classmethod
    def from_toml(cls, env: str | None = None) -> AppConfig:
        """Utwórz AppConfig z typowanego TOML — preferuje TOML nad env vars."""
        if env is None:
            env = os.getenv("NEXUS_ENV", "dev").lower().strip()
        toml_root = cls._load_toml_file(env)
        kwargs: dict[str, Any] = {}
        for field_name in cls.__struct_fields__:
            if (value := cls._resolve_field_value(field_name, toml_root)) is not None:
                kwargs[field_name] = value
        kwargs.setdefault("environment", env)
        instance = cls(**kwargs)
        instance.validate()
        return instance

    @classmethod
    def _resolve_field_value(cls, field_name: str, toml_root: _TomlConfigRoot) -> Any | None:
        """Resolve field from typed TOML section. Env vars loaded at import time by _load_toml_profile."""
        mapping = cls._TOML_FIELD_MAP.get(field_name)
        if mapping:
            section = getattr(toml_root, mapping[0], None)
            if section is not None and (value := getattr(section, mapping[1], None)) is not None:
                return value
        return None

    @classmethod
    def create(cls) -> AppConfig:
        return cls.from_toml()

    def validate(self) -> None:
        """Validate config after initialization. Call after creating instance."""
        self.environment = self.environment.lower().strip()
        if self.environment not in {"dev", "stage", "prod"}:
            raise ConfigValidationError("NEXUS_ENV must be one of: dev, stage, prod")

        self.base_dir = (
            Path(self.base_dir).resolve()
            if isinstance(self.base_dir, str)
            else self.base_dir.resolve()
        )
        # Offline-first secret resolution: prefer live env, fallback to encrypted/local cache.
        cache = LocalSecretsCache(self.base_dir / "app_data" / "secrets_cache.json", ttl_hours=24)
        resolver = OfflineFirstSecretResolver(cache)
        self.jwt_secret = (
            resolver.resolve(
                "jwt_secret",
                lambda: os.getenv("NEXUS_INFISCAL_JWT_SECRET", "").strip() or self.jwt_secret,
            )
            or ""
        )
        self.encryption_key = (
            resolver.resolve(
                "encryption_key",
                lambda: (
                    os.getenv("NEXUS_INFISCAL_ENCRYPTION_KEY", "").strip() or self.encryption_key
                ),
            )
            or ""
        )
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
            raise ConfigValidationError(
                "NEXUS_MAX_ATTACHMENT_UPLOAD_MB must be >= NEXUS_MAX_INVOICE_UPLOAD_MB"
            )
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
    def effective_jwt_exclude(self) -> list[str]:
        """Zwraca listę wykluczeń JWT z configu lub domyślne."""
        if self.jwt_exclude_paths:
            return self.jwt_exclude_paths
        return [
            "/api/auth/login",
            "/api/auth/register",
            "/api/auth/refresh",
            "/api/auth/csrf-token",
            "/api/auth/reset-password",
            "/api/auth/reset-password/confirm",
            "/api/auth/confirm",
            "/api/v1/health",
            "/api/v2/health",
            "/schema/openapi.yml",
            "/schema/swagger",
        ]

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
