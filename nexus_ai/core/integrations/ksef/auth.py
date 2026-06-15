"""
KSeF Auth Service — z cache'em HTTP (hishel).

SUPERMOC HISHEL:
  - AuthorisationChallenge może być cache'owany (przez krótki czas)
  - Sesja token jest przechowywana w pamięci (SID)
  - async close() — czyste zamykanie połączeń
"""

from __future__ import annotations

from typing import Any

from nexus_ai.core.cache.http_client import CachedHttpClient
from structlog import get_logger

logger = get_logger("nexus.ksef")


class KsefAuthService:
    """Serwis autoryzacji KSeF z cache'em HTTP (hishel).

    SUPERMOC HISHEL:
      - CachedHttpClient zamiast surowego httpx.AsyncClient
      - async close() dla czystego zamykania
    """

    def __init__(self, nip: str, is_demo: bool = True) -> None:
        self.nip = nip
        self.base_url = (
            "https://ksef-test.mf.gov.pl/api/online/"
            if is_demo
            else "https://ksef.mf.gov.pl/api/online/"
        )
        # SUPERMOC: CachedHttpClient zamiast surowego httpx.AsyncClient
        self._http = CachedHttpClient(record_stats=True)

    async def login(self, user_token: str) -> str:
        """Zaloguj do KSeF i pobierz SessionToken.

        AuthorisationChallenge jest cache'owany przez hishel.
        Sesja token (wynik) jest przechowywana w pamięci.

        Args:
            user_token: Token użytkownika KSeF.

        Returns:
            Challenge string z KSeF.
        """
        resp = await self._http.post(
            f"{self.base_url}Session/AuthorisationChallenge",
            json={"contextIdentifier": {"type": "onip", "identifier": self.nip}},
        )
        resp.raise_for_status()
        data = resp.json()
        return data.get("challenge")

    async def close(self) -> None:
        """Zamknij CachedHttpClient."""
        await self._http.close()
