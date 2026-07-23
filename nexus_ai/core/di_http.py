"""
v7.0 INTEGRACJE ZEWNĘTRZNE — Shared CachedHttpClient singleton (LUKA 12).

Problem: Każdy serwis tworzy własną instancję CachedHttpClient.
Przy 10+ serwisach = 10+ osobnych pul połączeń HTTP.

Rozwiązanie: Singleton przez DI pattern — jeden współdzielony klient
dla wszystkich integracji zewnętrznych.

Usage:
    from nexus_ai.core.di_http import get_shared_http_client

    client = get_shared_http_client()
    resp = await client.get("https://api.example.com/data")

    # Po zakończeniu aplikacji:
    await close_shared_http_client()
"""

from __future__ import annotations

import threading
from typing import Any

import httpx
from httpx import Limits, Timeout
from structlog import get_logger

from nexus_ai.core.cache.http_client import CachedHttpClient

logger = get_logger("nexus.di.http")

# ── Singleton state ─────────────────────────────────────────────────────────

_shared_client: CachedHttpClient | None = None
_lock = threading.Lock()

# v7.0: Per-integracja timeouty (LUKA 13)
INTEGRATION_TIMEOUTS: dict[str, Timeout] = {
    "white_list": Timeout(connect=3.0, read=5.0, write=3.0, pool=5.0),
    "gus_bir": Timeout(connect=5.0, read=20.0, write=5.0, pool=10.0),
    "ksef": Timeout(connect=5.0, read=15.0, write=5.0, pool=10.0),
    "nbp": Timeout(connect=3.0, read=10.0, write=3.0, pool=5.0),
    "ecb": Timeout(connect=5.0, read=15.0, write=5.0, pool=10.0),
    "default": Timeout(connect=5.0, read=15.0, write=5.0, pool=30.0),
}


def get_shared_http_client(
    http2: bool = True,
    trust_env: bool = True,
    max_connections: int = 50,
) -> CachedHttpClient:
    """v7.0: Zwraca współdzielony singleton CachedHttpClient.

    Pierwsze wywołanie tworzy klienta, kolejne zwracają tę samą instancję.
    Thread-safe przez threading.Lock.

    Args:
        http2: HTTP/2 multiplexing (default True).
        trust_env: Proxy z env (default True).
        max_connections: Max liczba połączeń w puli (default 50).

    Returns:
        Współdzielony CachedHttpClient.
    """
    global _shared_client
    if _shared_client is None:
        with _lock:
            if _shared_client is None:  # Double-check
                limits = Limits(
                    max_connections=max_connections,
                    max_keepalive_connections=20,
                    keepalive_expiry=60.0,
                )
                _shared_client = CachedHttpClient(
                    http2=http2,
                    trust_env=trust_env,
                    limits=limits,
                    timeout=INTEGRATION_TIMEOUTS["default"],
                )
                logger.info(
                    "[DI-HTTP] Shared client created: max_conn=%d http2=%s",
                    max_connections, http2,
                )
    return _shared_client


def get_integration_timeout(integration: str) -> Timeout:
    """v7.0: Zwraca timeout dla konkretnej integracji (LUKA 13).

    Różne API mają różne czasy odpowiedzi:
    - Biała Lista MF: ~2-3s → timeout 5s
    - GUS BIR SOAP: ~5-10s → timeout 20s
    - KSeF: ~5-8s → timeout 15s
    - NBP: ~1-3s → timeout 10s
    """
    return INTEGRATION_TIMEOUTS.get(integration, INTEGRATION_TIMEOUTS["default"])


async def close_shared_http_client() -> None:
    """Zamknij współdzielony klient HTTP."""
    global _shared_client
    if _shared_client is not None:
        with _lock:
            if _shared_client is not None:
                await _shared_client.close()
                _shared_client = None
                logger.info("[DI-HTTP] Shared client closed")


def reset_shared_http_client() -> None:
    """Resetuj singleton (głównie dla testów)."""
    global _shared_client
    with _lock:
        _shared_client = None
