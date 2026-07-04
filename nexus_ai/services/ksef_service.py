from __future__ import annotations

from typing import final

import stamina
from httpx import HTTPStatusError, RequestError, TimeoutException
from structlog import get_logger

from nexus_ai.core.cache.http_client import CachedHttpClient

logger = get_logger("nexus.services.ksef")


@final
class KsefService:
    """Obsluga Krajowego Systemu e-Faktur (API Ministerstwa Finansow)."""
    __slots__ = ('_http', 'base_url', 'session_token')

    def __init__(self, is_production: bool = False):
        self.base_url = (
            "https://ksef.mf.gov.pl/api" if is_production else "https://ksef-test.mf.gov.pl/api"
        )
        self.session_token: str | None = None
        self._http = CachedHttpClient()

    async def _init_session(self, nip: str, authorization_token: str) -> bool:
        """Krok 1: Inicjalizacja sesji z KSeF (Authorisation Challenge).

        Wymaga podpisania wyzwania tokenem wygenerowanym w aplikacji KSeF.
        SUPERPOWERS: stamina.retry z circuit breaker dla odpornej komunikacji z API MF.
        """
        for attempt in stamina.retry_context(
            on=(HTTPStatusError, RequestError, TimeoutException, ConnectionError),
            attempts=3,
            timeout=10.0,
            circuit_breaker=True,
        ):
            with attempt:
                try:
                    response = await self._http.post(
                        f"{self.base_url}/online/Session/InitToken",
                        json={"nip": nip, "token": authorization_token},
                    )
                    if response.status_code == 200:
                        data = response.json()
                        self.session_token = data.get("sessionToken")
                        logger.info("[KSeF] Session initialized nip=%s", nip[-4:])
                        return True
                    logger.warning(
                        "[KSeF] Init session failed status=%d nip=%s",
                        response.status_code, nip[-4:],
                    )
                except (HTTPStatusError, RequestError, TimeoutException, ConnectionError) as exc:
                    logger.warning(
                        "[KSeF] Session init attempt failed nip=%s: %s", nip[-4:], exc,
                    )
                    raise  # re-raise dla stamina.retry_context
        logger.error("[KSeF] Session init failed after all retries nip=%s", nip[-4:])
        return False

    async def close(self) -> None:
        """Zamknij CachedHttpClient."""
        await self._http.close()
