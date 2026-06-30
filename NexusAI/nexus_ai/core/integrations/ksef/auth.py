"""
KSeF Auth Service.
"""

from __future__ import annotations


from nexus_ai.core.cache.http_client import CachedHttpClient
from structlog import get_logger

logger = get_logger("nexus.ksef")


class KsefAuthService:
    """Serwis autoryzacji KSeF."""

    def __init__(self, nip: str, is_demo: bool = True) -> None:
        self.nip = nip
        self.base_url = (
            "https://ksef-test.mf.gov.pl/api/online/"
            if is_demo
            else "https://ksef.mf.gov.pl/api/online/"
        )
        self._http = CachedHttpClient()

    async def login(self, user_token: str) -> str:
        """Zaloguj do KSeF i pobierz SessionToken."""
        resp = await self._http.post(
            f"{self.base_url}Session/AuthorisationChallenge",
            json={"contextIdentifier": {"type": "onip", "identifier": self.nip}},
        )
        resp.raise_for_status()
        data = resp.json()
        return data.get("challenge")

    async def close(self) -> None:
        await self._http.close()
