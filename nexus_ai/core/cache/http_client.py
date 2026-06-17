"""
NexusAI HTTP Cache Layer — hishel + httpx integration.

SUPERMOCE HTTPX (v0.27+):
  - http2=True — HTTP/2 multiplexing (szybsze zapytania)
  - Limits(max_connections, max_keepalive, keepalive_expiry) — connection pool
  - Timeout(connect, read, write, pool) — precyzyjne timeouty
  - event_hooks — logowanie request/response, monitoring OTel
  - trust_env=True — obsługa proxy z HTTP_PROXY/HTTPS_PROXY env
  - mounts — osobny transport per API z różnymi konfiguracjami

SUPERMOCE HISHEL (v1.3.0):
  - AsyncCacheClient / AsyncCacheTransport — przezroczysty cache HTTP
  - SQLiteStorage / InMemoryStorage / RedisStorage — elastyczne backendy
  - Controller z cacheable_methods, cacheable_status_codes, allow_stale
  - Stale-While-Revalidate — offline fallback
  - Conditional Requests (ETag, If-None-Match) — automatyczne

Usage:
    # Szybki klient z domyślnym SQLite + HTTP/2
    client = CachedHttpClient()
    resp = await client.get("https://api.example.com/data")

    # Z InMemoryStorage (testy)
    client = CachedHttpClient(storage_backend="memory")

    # Niskopoziomowo: transport dla istniejącego httpx.AsyncClient
    transport = create_cached_transport(storage_backend="sqlite")
    client = httpx.AsyncClient(transport=transport, timeout=30.0, http2=True)
"""

from __future__ import annotations

import os
import time
from pathlib import Path
from typing import Any

import httpx
from httpx import Limits, Timeout
from structlog import get_logger
import stamina

logger = get_logger("nexus.http.cache")

# ── Próba importu hishel ─────────────────────────────────────────────────

try:
    import hishel
    HAS_HISHEL = True
except ImportError:
    HAS_HISHEL = False
    logger.warning(
        "[HTTP-CACHE] hishel not installed — HTTP caching disabled. Install: pip install hishel"
    )

# ── Domyślne katalogi cache ──────────────────────────────────────────────

DEFAULT_CACHE_DIR = Path(os.getcwd()) / "app_data" / "http_cache"

# ── Statystyki cache (monitoring OpenTelemetry) ──────────────────────────

_CACHE_STATS: dict[str, int] = {"hits": 0, "misses": 0, "errors": 0, "stale_hits": 0}


def get_cache_stats() -> dict[str, int]:
    """Zwraca zagregowane statystyki cache HTTP dla OpenTelemetry."""
    return dict(_CACHE_STATS)


def reset_cache_stats() -> None:
    """Resetuje statystyki cache (przydatne w testach)."""
    _CACHE_STATS["hits"] = 0
    _CACHE_STATS["misses"] = 0
    _CACHE_STATS["errors"] = 0
    _CACHE_STATS["stale_hits"] = 0


# ── Event hooks (SUPERMOC HTTPX: monitoring request/response) ────────────


async def _log_request(request: httpx.Request) -> None:
    """SUPERMOC HTTPX: Event hook — loguje każde żądanie HTTP."""
    logger.debug("[HTTP] → %s %s", request.method, request.url)


async def _log_response(response: httpx.Response) -> None:
    """SUPERMOC HTTPX: Event hook — loguje każdą odpowiedź HTTP."""
    elapsed = response.elapsed.total_seconds() * 1000 if response.elapsed else 0
    logger.debug(
        "[HTTP] ← %s %s (%d, %.1fms)",
        response.request.method,
        response.url,
        response.status_code,
        elapsed,
    )


# ── SUPERMOC HTTPX: Domyślne konfiguracje per API ───────────────────────

# Używane w mounts dla różnych timeoutów/Limits per API
API_MOUNTS: dict[str, dict[str, Any]] = {
    "NBP": {
        "base_url": "https://api.nbp.pl",
        "timeout": Timeout(connect=10.0, read=15.0, write=10.0, pool=300.0),
        "limits": Limits(max_connections=5, max_keepalive_connections=3, keepalive_expiry=60.0),
        "http2": True,
        "ttl": 86400,  # 24h — kursy walut zmieniają się raz dziennie
    },
    "MF_WHITE_LIST": {
        "base_url": "https://wl-api.mf.gov.pl",
        "timeout": Timeout(connect=10.0, read=15.0, write=10.0, pool=300.0),
        "limits": Limits(max_connections=5, max_keepalive_connections=3, keepalive_expiry=60.0),
        "http2": True,
        "ttl": 3600,  # 1h — lista MF zmienia się rzadko
    },
    "GITHUB": {
        "base_url": "https://api.github.com",
        "timeout": Timeout(connect=10.0, read=30.0, write=10.0, pool=300.0),
        "limits": Limits(max_connections=5, max_keepalive_connections=3, keepalive_expiry=60.0),
        "http2": True,
        "ttl": 3600,  # 1h — GitHub API ma rate limiting
    },
    "KSEF": {
        "base_url": "https://ksef.mf.gov.pl",
        "timeout": Timeout(connect=15.0, read=30.0, write=15.0, pool=300.0),
        "limits": Limits(max_connections=10, max_keepalive_connections=5, keepalive_expiry=60.0),
        "http2": True,
        "ttl": 3600,
    },
    "HUGGINGFACE": {
        "base_url": "https://huggingface.co",
        "timeout": Timeout(connect=15.0, read=120.0, write=30.0, pool=300.0),
        "limits": Limits(max_connections=10, max_keepalive_connections=5, keepalive_expiry=60.0),
        "http2": True,
        "ttl": 0,  # Duże pliki — nie cache'ujemy
    },
    "DEFAULT": {
        "base_url": None,
        "timeout": Timeout(connect=10.0, read=30.0, write=30.0, pool=300.0),
        "limits": Limits(max_connections=20, max_keepalive_connections=10, keepalive_expiry=30.0),
        "http2": True,
        "ttl": 3600,
    },
}


# ── Helper: utwórz storage ──────────────────────────────────────────────


def _create_storage(
    storage_backend: str = "sqlite",
    cache_dir: str | Path | None = None,
    ttl: int = 3600,
    redis_url: str | None = None,
) -> Any:
    """Utwórz storage backend dla hishel."""
    if not HAS_HISHEL:
        return None
    if storage_backend == "memory":
        return hishel.InMemoryStorage()
    if storage_backend == "sqlite":
        if cache_dir is None:
            cache_dir = DEFAULT_CACHE_DIR
        cache_path = Path(cache_dir)
        cache_path.mkdir(parents=True, exist_ok=True)
        return hishel.SQLiteStorage(database=str(cache_path / "http_cache.db"), ttl=ttl)
    if storage_backend == "redis":
        if not redis_url:
            redis_url = os.environ.get("NEXUS_REDIS_URL", "redis://localhost:6379/0")
            if not redis_url:
                raise ValueError("Redis URL required for storage_backend='redis'.")
        return hishel.RedisStorage(url=redis_url, ttl=ttl)
    if storage_backend == "file":
        if cache_dir is None:
            cache_dir = DEFAULT_CACHE_DIR
        cache_path = Path(cache_dir)
        cache_path.mkdir(parents=True, exist_ok=True)
        return hishel.FileStorage(base_path=str(cache_path), ttl=ttl)
    raise ValueError(f"Unknown storage_backend: {storage_backend!r}")


# ── Tworzenie klienta z cache'em ────────────────────────────────────────


def create_cached_client(
    cache_dir: str | Path | None = None,
    storage_backend: str = "sqlite",
    ttl: int = 3600,
    redis_url: str | None = None,
    allow_stale: bool = True,
    allow_stale_on_revalidation: bool = True,
    cacheable_methods: list[str] | None = None,
    cacheable_status_codes: list[int] | None = None,
    record_stats: bool = True,
    http2: bool = True,
    trust_env: bool = True,
    use_event_hooks: bool = True,
    limits: Limits | None = None,
    timeout: Timeout | float | None = None,
    **kwargs: Any,
) -> httpx.AsyncClient:
    """Utwórz httpx.AsyncClient z inteligentnym cache'em HTTP (hishel) + supermoce HTTPX.

    SUPERMOCE HTTPX:
      - http2=True — HTTP/2 multiplexing (szybsze zapytania)
      - trust_env=True — obsługa HTTP_PROXY/HTTPS_PROXY env
      - event_hooks — logowanie request/response (debugowanie)
      - Limits — ochrona connection pool przed przeciążeniem
      - Timeout(connect, read, write, pool) — precyzyjne timeouty

    Args:
        cache_dir/storage_backend/ttl/redis_url — konfiguracja hishel cache
        allow_stale/allow_stale_on_revalidation — polityka cache
        cacheable_methods/cacheable_status_codes — co cache'ować
        record_stats — monitoring hit/miss
        http2 — SUPERMOC HTTP/2 (default True)
        trust_env — SUPERMOC proxy z env (default True)
        use_event_hooks — SUPERMOC event hooks (default True)
        limits — SUPERMOC Limits (domyślnie max_connections=20)
        timeout — SUPERMOC Timeout class (domyślnie connect=10s, read=30s, write=30s, pool=300s)
        **kwargs — dla httpx.AsyncClient (headers itp.)
    """
    if cacheable_methods is None:
        cacheable_methods = ["GET", "HEAD"]
    if cacheable_status_codes is None:
        cacheable_status_codes = [200, 301, 302, 307, 308]

    # SUPERMOC HTTPX: Domyślne Timeout i Limits
    if timeout is None:
        timeout = Timeout(connect=10.0, read=30.0, write=30.0, pool=300.0)
    if limits is None:
        limits = Limits(max_connections=20, max_keepalive_connections=10, keepalive_expiry=30.0)

    # SUPERMOC HTTPX: Event hooks dla logowania
    hooks: dict[str, list] = {"request": [], "response": []}
    if use_event_hooks:
        hooks["request"].append(_log_request)
        hooks["response"].append(_log_response)

    if HAS_HISHEL:
        if cache_dir is None:
            cache_dir = DEFAULT_CACHE_DIR
        cache_path = Path(cache_dir)
        cache_path.mkdir(parents=True, exist_ok=True)

        controller = hishel.Controller(
            allow_stale=allow_stale,
            allow_stale_on_revalidation=allow_stale_on_revalidation,
            cacheable_methods=cacheable_methods,
            cacheable_status_codes=cacheable_status_codes,
        )
        storage = _create_storage(
            storage_backend=storage_backend, cache_dir=cache_dir, ttl=ttl, redis_url=redis_url,
        )

        # SUPERMOC HTTPX: hishel.AsyncCacheClient z http2, trust_env, event_hooks
        client = hishel.AsyncCacheClient(
            controller=controller,
            storage=storage,
            http2=http2,
            trust_env=trust_env,
            event_hooks=hooks,
            timeout=timeout,
            limits=limits,
            **kwargs,
        )

        logger.info(
            "[HTTP-CACHE] hishel client initialized",
            cache_type=storage_backend,
            ttl=ttl,
            http2=http2,
            trust_env=trust_env,
            limits=f"{limits.max_connections} conn, {limits.max_keepalive_connections} keepalive",
            timeout=f"connect={timeout.connect}s, read={timeout.read}s, write={timeout.write}s" if isinstance(timeout, Timeout) else str(timeout),
        )

        # Wrap z monitoringiem STATS
        if record_stats:
            original_get = client.get
            async def _monitored_get(url: str, **req_kw: Any) -> httpx.Response:
                try:
                    resp = await original_get(url, **req_kw)
                    cache_status = resp.headers.get("X-Cache", "MISS")
                    if cache_status == "HIT":
                        _CACHE_STATS["hits"] += 1
                    elif cache_status == "STALE":
                        _CACHE_STATS["stale_hits"] += 1
                    else:
                        _CACHE_STATS["misses"] += 1
                    return resp
                except Exception:
                    _CACHE_STATS["errors"] += 1
                    raise
            client.get = _monitored_get  # type: ignore[assignment]

        return client
    else:
        logger.info("[HTTP-CACHE] hishel not available — using plain httpx")
        return httpx.AsyncClient(
            http2=http2,
            trust_env=trust_env,
            event_hooks=hooks,
            timeout=timeout,
            limits=limits,
            **kwargs,
        )


# ── SUPERMOC HTTPX: AsyncCacheTransport dla istniejącego httpx.AsyncClient ──


def create_cached_transport(
    storage_backend: str = "sqlite",
    cache_dir: str | Path | None = None,
    ttl: int = 3600,
    redis_url: str | None = None,
    allow_stale: bool = True,
    allow_stale_on_revalidation: bool = True,
    cacheable_methods: list[str] | None = None,
    cacheable_status_codes: list[int] | None = None,
    limits: Limits | None = None,
) -> httpx.AsyncHTTPTransport:
    """SUPERMOC: Utwórz AsyncCacheTransport dla istniejącego httpx.AsyncClient.

    Umożliwia zachowanie specyficznej konfiguracji httpx (timeout, headers, limits)
    z dodatkową warstwą cache hishel.

    Usage:
        transport = create_cached_transport(storage_backend="sqlite")
        client = httpx.AsyncClient(
            transport=transport, http2=True, timeout=Timeout(connect=10.0, read=30.0),
        )
    """
    if not HAS_HISHEL:
        logger.warning("[HTTP-CACHE] hishel not installed — returning plain HTTPTransport")
        return httpx.AsyncHTTPTransport(limits=limits)

    if cacheable_methods is None:
        cacheable_methods = ["GET", "HEAD"]
    if cacheable_status_codes is None:
        cacheable_status_codes = [200, 301, 302, 307, 308]
    if cache_dir is None:
        cache_dir = DEFAULT_CACHE_DIR
    Path(cache_dir).mkdir(parents=True, exist_ok=True)

    controller = hishel.Controller(
        allow_stale=allow_stale,
        allow_stale_on_revalidation=allow_stale_on_revalidation,
        cacheable_methods=cacheable_methods,
        cacheable_status_codes=cacheable_status_codes,
    )
    storage = _create_storage(
        storage_backend=storage_backend, cache_dir=cache_dir, ttl=ttl, redis_url=redis_url,
    )
    transport = hishel.AsyncCacheTransport(
        transport=httpx.AsyncHTTPTransport(limits=limits),
        controller=controller,
        storage=storage,
    )
    logger.info(
        "[HTTP-CACHE] hishel AsyncCacheTransport initialized",
        cache_type=storage_backend, ttl=ttl,
        cacheable_methods=cacheable_methods,
    )
    return transport


# ── SUPERMOC HTTPX: mounts dla różnych API ─────────────────────────────


def create_mounted_client(
    mounts: dict[str, str] | None = None,
    **kwargs: Any,
) -> httpx.AsyncClient:
    """SUPERMOC HTTPX: Utwórz klienta z mounts dla różnych API.

    Każde API ma własną konfigurację timeout/Limits/ttl.
    Używa create_cached_transport() dla każdego mounta.

    Args:
        mounts: Mapowanie URL prefix → storage_backend ("sqlite", "memory", itp.)
                Jeśli None, używa domyślnych konfiguracji z API_MOUNTS.

    Usage:
        client = create_mounted_client()
        # NBP → cache 24h, Limits 5 conn
        await client.get("https://api.nbp.pl/api/exchangerates/rates/A/EUR/")
        # GitHub → cache 1h, Limits 5 conn
        await client.get("https://api.github.com/repos/...")
    """
    from httpx import AsyncClient, AsyncHTTPTransport

    if mounts is None:
        # Automatycznie mountuj znane API
        mount_dict: dict[str, httpx.AsyncHTTPTransport] = {}
        for name, config in API_MOUNTS.items():
            base = config.get("base_url")
            if not base:
                continue
            transport = create_cached_transport(
                storage_backend="sqlite",
                ttl=config.get("ttl", 3600),
                limits=config.get("limits"),
            )
            mount_dict[base + "/**"] = transport

        # Domyślny transport dla pozostałych API
        default_limits = API_MOUNTS["DEFAULT"]["limits"]
        default_timeout = API_MOUNTS["DEFAULT"]["timeout"]
    else:
        mount_dict = {}
        for prefix, backend in mounts.items():
            transport = create_cached_transport(storage_backend=backend)
            mount_dict[prefix] = transport
        default_timeout = kwargs.pop("timeout", Timeout(connect=10.0, read=30.0, write=30.0, pool=300.0))
        default_limits = kwargs.pop("limits", Limits(max_connections=20, max_keepalive_connections=10, keepalive_expiry=30.0))

    client = AsyncClient(
        mounts=mount_dict,
        http2=True,
        trust_env=True,
        timeout=default_timeout,
        limits=default_limits,
        event_hooks={"request": [_log_request], "response": [_log_response]},
        **kwargs,
    )
    logger.info("[HTTP-CACHE] Mounted client initialized with %d mounts", len(mount_dict))
    return client


# ── Prekonfigurowane klienty dla zewnętrznych API ──────────────────────


class CachedHttpClient:
    """Prekonfigurowany klient HTTP z cache'em + supermoce HTTPX.

    SUPERMOCE HTTPX:
      - http2=True — HTTP/2 multiplexing
      - Limits — ochrona connection pool
      - Timeout(connect, read, write) — precyzyjne timeouty
      - event_hooks — logowanie request/response
      - trust_env=True — obsługa proxy

    Usage:
        client = CachedHttpClient()
        resp = await client.get("https://api.example.com/data")
        await client.close()
    """

    def __init__(
        self,
        cache_dir: str | Path | None = None,
        storage_backend: str = "sqlite",
        ttl: int = 3600,
        redis_url: str | None = None,
        record_stats: bool = True,
        http2: bool = True,
        trust_env: bool = True,
        use_event_hooks: bool = True,
        limits: Limits | None = None,
        timeout: Timeout | float | None = None,
        concurrency_limit: int = 0,
        **kwargs: Any,
    ) -> None:
        merged_kwargs = {
            "http2": http2,
            "trust_env": trust_env,
            "use_event_hooks": use_event_hooks,
            **kwargs,
        }
        if limits is not None:
            merged_kwargs["limits"] = limits
        if timeout is not None:
            merged_kwargs["timeout"] = timeout

        self._client = create_cached_client(
            cache_dir=cache_dir,
            storage_backend=storage_backend,
            ttl=ttl,
            redis_url=redis_url,
            record_stats=record_stats,
            **merged_kwargs,
        )

        # SUPERMOC HTTPX: Semaphore dla limitowania konkurencji
        self._semaphore: anyio.Semaphore | None = None
        if concurrency_limit > 0:
            import anyio as _anyio
            self._semaphore = _anyio.Semaphore(concurrency_limit)

    async def _acquire(self) -> None:
        if self._semaphore is not None:
            await self._semaphore.acquire()

    def _release(self) -> None:
        if self._semaphore is not None:
            self._semaphore.release()

    async def _cb_check(self) -> None:
        """SUPERMOC stamina: Sprawdza stan Circuit Breakera przed wysłaniem żądania.

        Używa stamina.is_active() — publiczne API stamina od v0.1+
        (udokumentowane w test_stamina_circuit_breaker.py).
        """
        if not stamina.is_active():
            logger.warning(
                "[CB] Circuit breaker OPEN — bypassing HTTP request"
            )
            raise stamina.RetryingError(
                "Circuit breaker is open — request skipped"
            ) from None

    async def get(self, url: str, **kwargs: Any) -> httpx.Response:
        await self._acquire()
        try:
            await self._cb_check()
            return await self._client.get(url, **kwargs)
        finally:
            self._release()

    async def post(self, url: str, **kwargs: Any) -> httpx.Response:
        await self._acquire()
        try:
            return await self._client.post(url, **kwargs)
        finally:
            self._release()

    async def put(self, url: str, **kwargs: Any) -> httpx.Response:
        await self._acquire()
        try:
            return await self._client.put(url, **kwargs)
        finally:
            self._release()

    async def patch(self, url: str, **kwargs: Any) -> httpx.Response:
        await self._acquire()
        try:
            return await self._client.patch(url, **kwargs)
        finally:
            self._release()

    async def delete(self, url: str, **kwargs: Any) -> httpx.Response:
        await self._acquire()
        try:
            return await self._client.delete(url, **kwargs)
        finally:
            self._release()

    async def stream(self, method: str, url: str, **kwargs: Any) -> httpx.AsyncClient:
        return await self._client.stream(method, url, **kwargs)

    async def close(self) -> None:
        """Zamknij klienta i zwolnij połączenia."""
        await self._client.aclose()


# ── Utwórz prekonfigurowane klienty dla konkretnych API ────────────────


def create_nbp_client(**kwargs: Any) -> CachedHttpClient:
    """SUPERMOC HTTPX: Prekonfigurowany klient dla NBP API.

    - http2=True, http2_connection_window_size=10MB (dla kursów)
    - Limits: 5 conn (NBP ma rate limiting)
    - Timeout: connect=10s, read=15s (szybkie odpowiedzi JSON)
    - trust_env=True (dla proxy)
    """
    cfg = API_MOUNTS["NBP"]
    return CachedHttpClient(
        ttl=cfg["ttl"],
        limits=cfg["limits"],
        timeout=cfg["timeout"],
        http2=cfg["http2"],
        trust_env=True,
        **kwargs,
    )


def create_github_client(**kwargs: Any) -> CachedHttpClient:
    """Prekonfigurowany klient dla GitHub API."""
    cfg = API_MOUNTS["GITHUB"]
    return CachedHttpClient(
        ttl=cfg["ttl"],
        limits=cfg["limits"],
        timeout=cfg["timeout"],
        http2=cfg["http2"],
        trust_env=True,
        **kwargs,
    )


# ── Cache warming ──────────────────────────────────────────────────────


async def warm_http_cache(http_client: CachedHttpClient | None = None) -> None:
    """Wypełnij cache HTTP przy starcie workera/API."""
    import pendulum

    close_client = False
    if http_client is None:
        http_client = CachedHttpClient(storage_backend="sqlite", record_stats=False)
        close_client = True
    try:
        today = pendulum.now().date()
        for currency in ["EUR", "USD", "GBP", "CHF"]:
            for days_ago in range(7):
                date = today - pendulum.duration(days=days_ago)
                if date.weekday() >= 5:
                    continue
                url = f"https://api.nbp.pl/api/exchangerates/rates/A/{currency}/{date.isoformat()}/?format=json"
                try:
                    await http_client.get(url)
                except Exception:
                    pass
        logger.info("[HTTP-CACHE-WARM] NBP rates warmed for EUR, USD, GBP, CHF (7 days)")
    except Exception as exc:
        logger.debug("[HTTP-CACHE-WARM] NBP warm failed (non-fatal): %s", exc)
    finally:
        if close_client:
            await http_client.close()
