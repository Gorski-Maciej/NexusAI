from __future__ import annotations

from typing import final

from nexus_ai.core.cache.http_client import CachedHttpClient


@final
class KsefService:
    """Obsługa Krajowego Systemu e-Faktur (API Ministerstwa Finansów).

    SUPERMOC HISHEL:
      - Używa CachedHttpClient zamiast surowego httpx.AsyncClient
      - API odpowiedzi KSeF cache'owane przez hishel
      - async close() dla czystego zamykania
    """

    def __init__(self, is_production: bool = False):
        self.base_url = (
            "https://ksef.mf.gov.pl/api" if is_production else "https://ksef-test.mf.gov.pl/api"
        )
        self.session_token: str | None = None
        self._http = CachedHttpClient(record_stats=True)

    async def _init_session(self, nip: str, authorization_token: str) -> bool:
        """Krok 1: Inicjalizacja sesji z KSeF (Authorisation Challenge).

        Wymaga podpisania wyzwania tokenem wygenerowanym w aplikacji KSeF.
        """
        try:
            response = await self._http.post(
                f"{self.base_url}/online/Session/InitToken",
                json={"nip": nip, "token": authorization_token},
            )
            if response.status_code == 200:
                data = response.json()
                self.session_token = data.get("sessionToken")
                return True
        except Exception:
            pass
        return False

    async def close(self) -> None:
        """Zamknij CachedHttpClient."""
        await self._http.close()
