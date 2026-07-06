"""
KSeF Client -- HTTP client for KSeF API.

SUPERPOWERY: stamina.retry z circuit breaker dla odpornej komunikacji
z API Ministerstwa Finansów (KSeF).
"""

from __future__ import annotations

import stamina
from httpx import HTTPStatusError, RequestError, TimeoutException
from structlog import get_logger

from nexus_ai.core.cache.http_client import CachedHttpClient

logger = get_logger("nexus.ksef.client")


class KsefClient:
    """Klient API KSeF."""
    __slots__ = ('_http', 'base_url', 'headers')

    def __init__(self, session_token: str, base_url: str) -> None:
        self.headers = {"SessionToken": session_token, "Accept": "application/json"}
        self.base_url = base_url
        self._http = CachedHttpClient()

    async def fetch_invoice(self, ksef_reference: str) -> bytes:
        """Pobiera fakturę XML (format FA_VAT).

        SUPERPOWERY: stamina.retry z circuit breaker — 3 próby, timeout 10s.
        """
        url = f"{self.base_url}Invoice/Get/{ksef_reference}"
        for attempt in stamina.retry_context(
            on=(HTTPStatusError, RequestError, TimeoutException, ConnectionError),
            attempts=3,
            timeout=10.0,
            circuit_breaker=True,
        ):
            with attempt:
                try:
                    resp = await self._http.get(url)
                    resp.raise_for_status()
                    return resp.content
                except (HTTPStatusError, RequestError, TimeoutException, ConnectionError) as exc:
                    logger.warning(
                        "[KSeF-Client] fetch_invoice failed ref=%s: %s",
                        ksef_reference[:12], exc,
                    )
                    raise  # re-raise dla stamina.retry_context
        raise ConnectionError(f"KSeF fetch_invoice failed after all retries: {ksef_reference}")

    async def close(self) -> None:
        await self._http.close()
