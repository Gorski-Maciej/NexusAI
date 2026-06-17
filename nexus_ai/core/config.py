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
# SUPERMOC TOML: Łączy config/base.toml z config/{env}.toml.
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
    """SUPERMOC TOML: Zaawansowany loader config z merge base.toml + {env}.toml.

    SUPERMOC TOML:
    - Ładuje config/base.toml jako bazę (wspólne wartości)
    - Nadpisuje config/{env}.toml (środowiskowe wartości)
    - mtime-based auto-reload dla obu plików
    - Aktualizuje os.environ po każdej zmianie

    Args:
        path: Ścieżka do pliku TOML. Domyślnie config/{NEXUS_ENV}.toml.
              UWAGA: base.toml jest ładowany automatycznie przed env-specific.
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

    SUPERMOC TOML: Wszystkie pola z ``Annotated[T, Meta(ge=..., le=...)]``
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

    SUPERMOC fsspec: Jednolita abstrakcja systemów plików.
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


class _StaminaSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [stamina].

    SUPERMOC: Globalne ustawienia stamina dla całego projektu.
    Używane przez resilience.py, currency_converter.py, forex_engine.py, api/tasks.py.
    """

    retry_attempts: Annotated[int | None, Meta(ge=1, le=20)] = None
    retry_timeout: Annotated[float | None, Meta(ge=1.0, le=300.0)] = None
    circuit_breaker_enabled: bool | None = None
    circuit_breaker_cooldown: Annotated[float | None, Meta(ge=5.0, le=600.0)] = None


class _SecuritySection(Struct, kw_only=True):
    """msgspec schema dla sekcji [security].

    Litestar SUPERMOC:
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

    SUPERMOC: Walidacja typów i zakresów przez msgspec.
    Sekcja [tax] istnieje w dev.toml i prod.toml, ale była
    wcześniej ignorowana przez typed schema — parsowana tylko jako dict.
    """
    default_vat_rate: Annotated[int | None, Meta(ge=0, le=100)] = None
    cit_rate: Annotated[float | None, Meta(ge=0, le=100)] = None
    linear_rate: Annotated[float | None, Meta(ge=0, le=100)] = None
    lump_sum_rates: list[float] | None = None
    vat_exempt_threshold: Annotated[float | None, Meta(ge=0)] = None
    vat_quarterly_threshold: Annotated[float | None, Meta(ge=0)] = None


class _ForexSection(Struct, kw_only=True):
    """msgspec schema dla sekcji [forex] w config/{env}.toml."""
    enabled: bool | None = None
    nbp_api_url: str | None = None
    max_lookback_days: Annotated[int | None, Meta(ge=1, le=365)] = None
    http_timeout_sec: Annotated[float | None, Meta(ge=1, le=60)] = None
    rate_cache_maxsize: Annotated[int | None, Meta(ge=1, le=10000)] = None
    refresh_interval_hours: Annotated[int | None, Meta(ge=1, le=168)] = None
    default_currencies: str | None = None
    missing_date_ttl_days: Annotated[int | None, Meta(ge=1, le=365)] = None


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


class _TomlConfigRoot(Struct, kw_only=True):
    """msgspec schema dla całego pliku config/{env}.toml.

    SUPERMOC TOML: 10 sekcji z typowaną walidacją (msgspec.Struct),
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
    - forex: kursy walut NBP
    - ai: ścieżki modeli AI
    - tigerbeetle: double-entry ledger
    """

    app: _AppSection | None = None
    nats: _NatsSection | None = None
    stamina: _StaminaSection | None = None
    storage: _StorageSection | None = None
    security: _SecuritySection | None = None
    integrations: _IntegrationsSection | None = None
    tax: _TaxSection | None = None
    forex: _ForexSection | None = None
    ai: _AiSection | None = None
    tigerbeetle: _TigerbeetleSection | None = None


# ── Legacyjne funkcje ładowania (kompatybilność wsteczna) ────────────────


def _load_toml_profile(environment: str) -> None:
    """Load environment-specific config from config/{env}.toml.

    .. deprecated::
       Użyj ConfigLoader.load() lub get_config_loader().load() zamiast tej funkcji.
       Ta funkcja jest zachowana dla kompatybilności wstecznej — ładuje config
       tylko raz przy imporcie, bez auto-reload.

    SUPERMOC TOML: Ładuje config/base.toml jako bazę, potem nadpisuje
    config/{env}.toml. Wspólne sekcje (tax, forex, ai, tigerbeetle, security)
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

    # ── SUPERMOC: Globalne stamina settings ──
    # ── SUPERMOC: Globalne stamina settings ──
    stamina_retry_attempts: int = 3
    stamina_retry_timeout: float = 10.0
    stamina_circuit_breaker_enabled: bool = True
    stamina_circuit_breaker_cooldown: float = 60.0

    # ── SUPERMOC: fsspec — jednolita abstrakcja systemów plików ──
    storage_protocol: str = "file"
    storage_root: str = "app_data/uploads"
    storage_auto_mkdir: bool = True
    storage_cache_size_mb: int = 0

    # ── SUPERMOC: Litestar Security — konfigurowalne z TOML ──
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

    # ── Computed properties (as methods for Struct compatibility) ──

    @property
    def autopilot_vendor_alpha_proximity_min(self) -> int:
        return int(os.getenv("NEXUS_AUTOPILOT_VENDOR_ALPHA_MIN", "3"))

    # ── TOML ↔ env var mapping ──

    _ENV_MAP: ClassVar[dict[str, str]] = {
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

    # ── Rejestr sekcji TOML dla auto-mapowania ──
    # SUPERMOC: Zastępuje ręczny _TOML_FIELD_MAP (34 linie) auto-mapowaniem
    # przez msgspec.inspect. Każda nowa sekcja → dodajesz tylko wpis tutaj.
    # Klucz: nazwa sekcji w TOML, Wartość: klasa Struct + prefix env var.
    _TOML_SECTIONS: ClassVar[dict[str, tuple[type[Struct], str]]] = {
        "app": (_AppSection, "NEXUS_"),
        "nats": (_NatsSection, "NEXUS_NATS_"),
        "stamina": (_StaminaSection, "NEXUS_STAMINA_"),
        "storage": (_StorageSection, "NEXUS_STORAGE_"),
        "security": (_SecuritySection, "NEXUS_SECURITY_"),
        "integrations": (_IntegrationsSection, "NEXUS_INTEGRATIONS_"),
        "tax": (_TaxSection, "NEXUS_TAX_"),
        "forex": (_ForexSection, "NEXUS_FOREX_"),
        "ai": (_AiSection, "NEXUS_AI_"),
        "tigerbeetle": (_TigerbeetleSection, "NEXUS_TB_"),
    }

    # ── Auto-generowane mapowanie Struct field → (toml_section, toml_field) ──
    # SUPERMOC: Wygenerowane z _TOML_SECTIONS przez _build_field_map().
    # Zastępuje ręczny _TOML_FIELD_MAP (34+ linii) auto-mapowaniem.
    # Każda nowa sekcja w TOML → dodaj do _TOML_SECTIONS → reszta auto.
    _TOML_FIELD_MAP: ClassVar[dict[str, tuple[str, str]]] = {}

    # Manualne nadpisania dla pól gdzie AppConfig nazwa ≠ TOML Struct nazwa
    # SUPERMOC: Auto-map generuje wpisy z _TOML_SECTIONS, ten dict nadpisuje
    # tylko te pola, gdzie nazwy się różnią (np. sqlite_file_name → sqlite_file).
    _TOML_OVERRIDES: ClassVar[dict[str, tuple[str, str]]] = {
        "sqlite_file_name": ("app", "sqlite_file"),
        "duckdb_file_name": ("app", "duckdb_file"),
        "storage_dir_name": ("app", "storage_dir"),
        "idempotency_db_name": ("app", "idempotency_db"),
        "cors_origins_raw": ("app", "cors_origins"),
        "migration_baseline_name": ("app", "migration_baseline_file"),
        "migration_checksum_baseline_name": ("app", "migration_checksum_baseline_file"),
        "nats_url": ("nats", "url"),
        "stamina_retry_attempts": ("stamina", "retry_attempts"),
        "stamina_retry_timeout": ("stamina", "retry_timeout"),
        "stamina_circuit_breaker_enabled": ("stamina", "circuit_breaker_enabled"),
        "stamina_circuit_breaker_cooldown": ("stamina", "circuit_breaker_cooldown"),
        "storage_protocol": ("storage", "protocol"),
        "storage_root": ("storage", "root"),
        "storage_auto_mkdir": ("storage", "auto_mkdir"),
        "storage_cache_size_mb": ("storage", "cache_size_mb"),
    }

    @classmethod
    def _build_field_map(cls) -> dict[str, tuple[str, str]]:
        """SUPERMOC TOML: Auto-generuj mapowanie Struct→TOML z __struct_fields__.

        Zamiast ręcznego _TOML_FIELD_MAP (34 linii), przeglądamy wszystkie
        zarejestrowane sekcje i ich pola Struct, generując mapowanie
        (field_name → (section_name, field_name)).

        Returns:
            Słownik {field_name: (section_name, field_name)}.
        """
        result: dict[str, tuple[str, str]] = {}
        for section_name, (section_cls, _) in cls._TOML_SECTIONS.items():
            try:
                for field in msgspec.inspect(section_cls).fields:
                    result[field.name] = (section_name, field.name)
            except Exception:
                continue
        return result

    @classmethod
    def _load_toml_file(cls, env: str | None = None) -> _TomlConfigRoot:
        """Wczytaj plik TOML dla danego środowiska z typowaną walidacją (msgspec schema).

        Fazа 2: Używa ``msgspec.toml.decode(..., type=_TomlConfigRoot)`` do
        typowanej walidacji całego pliku TOML. Błędy walidacji (DecodeError,
        ValidationError) są logowane i nie przerywają startu — aplikacja używa
        defaultów z AppConfig.

        Args:
            env: Nazwa środowiska ("dev", "stage", "prod").
                 Domyślnie z NEXUS_ENV lub "dev".

        Returns:
            Ztypowany obiekt _TomlConfigRoot z danymi TOML (puste sekcje = None).
        """
        if env is None:
            env = os.getenv("NEXUS_ENV", "dev").lower().strip()
        toml_path = ENV_CONFIG_DIR / f"{env}.toml"
        if not toml_path.exists():
            logger.warning("[Config] TOML file not found: %s — using defaults", toml_path)
            return _TomlConfigRoot()
        try:
            with open(toml_path, "rb") as f:
                config_root = toml.decode(f.read(), type=_TomlConfigRoot)
            logger.info(
                "[Config] Loaded + validated TOML: %s (app=%s, nats=%s, integrations=%s)",
                toml_path.name,
                "present" if config_root.app else "defaults",
                "present" if config_root.nats else "defaults",
                "present" if config_root.integrations else "defaults",
            )
            return config_root
        except msgspec.DecodeError as exc:
            logger.warning("[Config] TOML decode error in %s: %s — using defaults", toml_path, exc)
            return _TomlConfigRoot()
        except msgspec.ValidationError as exc:
            logger.warning(
                "[Config] TOML validation error in %s: %s — using defaults", toml_path, exc
            )
            return _TomlConfigRoot()
        except Exception as exc:
            logger.warning("[Config] Failed to load %s: %s — using defaults", toml_path, exc)
            return _TomlConfigRoot()

    @classmethod
    def _resolve_field_value(
        cls,
        field_name: str,
        toml_root: _TomlConfigRoot,
    ) -> Any | None:
        """Rozwiąż wartość pola: env var > TOML (msgspec schema) > None (użyj defaultu).

        Fazа 2: TOML jest sparsowany przez ``msgspec.toml.decode(..., type=_TomlConfigRoot)``,
        więc wartości mają już poprawne typy (int, float, bool, str).
        Nie potrzebujemy już ``_cast()`` ani ``_get_field_type()``.

        Args:
            field_name: Nazwa pola w AppConfig.
            toml_root: Ztypowany obiekt _TomlConfigRoot.

        Returns:
            Wartość lub None (oznacza "użyj defaultu z klasy").
        """
        # 1. Sprawdź zmienną środowiskową (env var > TOML)
        env_key = cls._ENV_MAP.get(field_name)
        if env_key and env_key in os.environ:
            raw = os.environ[env_key]
            # Rzutowanie typów dla env vars (string → właściwy typ)
            field_type = cls._get_field_type(field_name)
            return cls._cast(raw, field_type)

        # 2. Sprawdź TOML przez msgspec schema (używa cls._TOML_FIELD_MAP — stała klasowa)
        mapping = cls._TOML_FIELD_MAP.get(field_name)
        if mapping:
            section_name, field_in_section = mapping
            section = getattr(toml_root, section_name, None)
            if section is not None:
                value = getattr(section, field_in_section, None)
                if value is not None:
                    return value

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
        """Utwórz AppConfig z bezpośrednim parsowaniem TOML (msgspec schema).

        Fazа 2: Używa ``msgspec.toml.decode(..., type=_TomlConfigRoot)`` do
        typowanej walidacji całego pliku TOML. Błędy walidacji (DecodeError,
        ValidationError) są logowane i nie przerywają startu.

        Priority: env var > TOML value (msgspec schema) > hardcoded Struct default.

        Args:
            env: Nazwa środowiska ("dev", "stage", "prod").

        Returns:
            Zwalidowana instancja AppConfig.
        """
        if env is None:
            env = os.getenv("NEXUS_ENV", "dev").lower().strip()

        toml_root = cls._load_toml_file(env)
        # Auto-generuj _TOML_FIELD_MAP jeśli pusty (pierwsze wywołanie)
        if not cls._TOML_FIELD_MAP:
            cls._TOML_FIELD_MAP.update(cls._build_field_map())
            # Nadpisz manualnymi override'ami (pola z różnymi nazwami)
            cls._TOML_FIELD_MAP.update(cls._TOML_OVERRIDES)

        kwargs: dict[str, Any] = {}

        for field_name in cls.__struct_fields__:
            value = cls._resolve_field_value(field_name, toml_root)
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
            "/api/auth/login", "/api/auth/register", "/api/auth/refresh",
            "/api/auth/csrf-token", "/api/auth/reset-password",
            "/api/auth/reset-password/confirm", "/api/auth/confirm",
            "/api/v1/health", "/api/v2/health",
            "/schema/openapi.yml", "/schema/swagger",
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
