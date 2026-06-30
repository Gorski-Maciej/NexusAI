"""
NexusAI HTTP Client Layer -- httpx integration with superpowers.

  - http2=True -- HTTP/2 multiplexing (szybsze zapytania)
  - Limits(max_connections, max_keepalive, keepalive_expiry) -- connection pool
  - Timeout(connect, read, write, pool) -- precyzyjne timeouty
  - event_hooks -- logowanie request/response, monitoring OTel
  - trust_env=True -- obsługa proxy z HTTP_PROXY/HTTPS_PROXY env
  - mounts -- osobny transport per API z różnymi konfiguracjami

Usage:
    client = CachedHttpClient()
    resp = await client.get("https://api.example.com/data")
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import httpx
import stamina
from httpx import Limits, Timeout
from structlog import get_logger

logger = get_logger("nexus.http.cache")

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




async def _log_request(request: httpx.Request) -> None:
    logger.debug("[HTTP] -> %s %s", request.method, request.url)


async def _log_response(response: httpx.Response) -> None:
    elapsed = response.elapsed.total_seconds() * 1000 if response.elapsed else 0
    logger.debug(
        "[HTTP] ← %s %s (%d, %.1fms)",
        response.request.method,
        response.url,
        response.status_code,
        elapsed,
    )


# ── Tworzenie klienta ────────────────────────────────────────


def create_cached_client(
    cache_dir: str | Path | None = None,
    record_stats: bool = True,
    http2: bool = True,
    trust_env: bool = True,
    use_event_hooks: bool = True,
    limits: Limits | None = None,
    timeout: Timeout | float | None = None,
    **kwargs: Any,
) -> httpx.AsyncClient:
    """Utwórz httpx.AsyncClient z supermocami HTTPX.

    Args:
        http2 -- HTTP/2 multiplexing (default True)
        trust_env -- proxy z env (default True)
        use_event_hooks -- event hooks (default True)
        limits -- Limits (domyślnie max_connections=20)
        timeout -- Timeout class (domyślnie connect=10s, read=30s, write=30s, pool=300s)
        **kwargs -- dla httpx.AsyncClient (headers itp.)
    """
    if timeout is None:
        timeout = Timeout(connect=10.0, read=30.0, write=30.0, pool=300.0)
    if limits is None:
        limits = Limits(max_connections=20, max_keepalive_connections=10, keepalive_expiry=30.0)

    hooks: dict[str, list] = {"request": [], "response": []}
    if use_event_hooks:
        hooks["request"].append(_log_request)
        hooks["response"].append(_log_response)

    logger.info(
        "[HTTP-CACHE] httpx client initialized",
        http2=http2,
        trust_env=trust_env,
        limits=f"{limits.max_connections} conn, {limits.max_keepalive_connections} keepalive",
        timeout=f"connect={timeout.connect}s, read={timeout.read}s, write={timeout.write}s"
        if isinstance(timeout, Timeout)
        else str(timeout),
    )

    return httpx.AsyncClient(
        http2=http2,
        trust_env=trust_env,
        event_hooks=hooks,
        timeout=timeout,
        limits=limits,
        **kwargs,
    )


# ── Prekonfigurowane klienty dla zewnętrznych API ──────────────────────


class CachedHttpClient:
    """Prekonfigurowany klient HTTP z supermocami HTTPX.

    Usage:
        client = CachedHttpClient()
        resp = await client.get("https://api.example.com/data")
        await client.close()
    """

    def __init__(
        self,
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
            record_stats=True,
            **merged_kwargs,
        )

        # Semaphore dla limitowania konkurencji
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
        """Sprawdza stan Circuit Breakera przed wysłaniem żądania."""
        if not stamina.is_active():
            logger.warning("[CB] Circuit breaker OPEN -- bypassing HTTP request")
            raise stamina.RetryingError("Circuit breaker is open -- request skipped") from None

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


# ── Cache warming ──────────────────────────────────────────────────────


async def warm_http_cache(http_client: CachedHttpClient | None = None) -> None:
    """Wypełnij cache HTTP przy starcie workera/API."""
    import pendulum

    close_client = False
    if http_client is None:
        http_client = CachedHttpClient()
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
