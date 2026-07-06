"""
KSeF Auth Service.

SUPERPOWERY: stamina.retry z circuit breaker dla odpornej komunikacji
z API autoryzacji KSeF (Ministerstwo Finansów).
"""

from __future__ import annotations

import stamina
from httpx import HTTPStatusError, RequestError, TimeoutException
from structlog import get_logger

from nexus_ai.core.cache.http_client import CachedHttpClient

logger = get_logger("nexus.ksef.auth")


class KsefAuthService:
    """Serwis autoryzacji KSeF."""
    __slots__ = ('_http', 'base_url', 'nip')

    def __init__(self, nip: str, is_demo: bool = True) -> None:
        self.nip = nip
        self.base_url = (
            "https://ksef-test.mf.gov.pl/api/online/"
            if is_demo
            else "https://ksef.mf.gov.pl/api/online/"
        )
        self._http = CachedHttpClient()

    async def login(self, user_token: str) -> str:
        """Zaloguj do KSeF i pobierz SessionToken.

        SUPERPOWERY: stamina.retry z circuit breaker — 3 próby, timeout 10s.
        """
        for attempt in stamina.retry_context(
            on=(HTTPStatusError, RequestError, TimeoutException, ConnectionError),
            attempts=3,
            timeout=10.0,
            circuit_breaker=True,
        ):
            with attempt:
                try:
                    resp = await self._http.post(
                        f"{self.base_url}Session/AuthorisationChallenge",
                        json={"contextIdentifier": {"type": "onip", "identifier": self.nip}},
                    )
                    resp.raise_for_status()
                    data = resp.json()
                    return data.get("challenge")
                except (HTTPStatusError, RequestError, TimeoutException, ConnectionError) as exc:
                    logger.warning("[KSeF-Auth] Login attempt failed nip=%s: %s", self.nip[-4:], exc)
                    raise  # re-raise dla stamina.retry_context
        raise ConnectionError(f"KSeF login failed after all retries for NIP {self.nip[-4:]}")

    async def close(self) -> None:
        await self._http.close()
