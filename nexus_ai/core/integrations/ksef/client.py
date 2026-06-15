"""
KSeF Client — cached HTTP for KSeF API with hishel.

SUPERMOC HISHEL:
  - Używa CachedHttpClient zamiast surowego httpx.AsyncClient
  - GET /Invoice/Get/{ksef_reference} — cache'owane (faktura się nie zmienia)
  - KSeF API ma rate limiting (~100 req/min) — hishel redukuje liczbę zapytań
  - async close() — czyste zamykanie połączeń
"""

from __future__ import annotations

from typing import Any

from nexus_ai.core.cache.http_client import CachedHttpClient


class KsefClient:
    """Klient API KSeF z cache'em HTTP (hishel).

    SUPERMOC HISHEL:
      - fetch_invoice() dla tego samego KSeF reference zwraca zawsze ten sam XML
      - hishel cache'uje odpowiedź w SQLite — drugie wywołanie to cache HIT
      - async close() dla czystego zamykania
    """

    def __init__(self, session_token: str, base_url: str) -> None:
        self.headers = {"SessionToken": session_token, "Accept": "application/json"}
        self.base_url = base_url
        # SUPERMOC: CachedHttpClient z cacheable_methods=["GET"]
        self._http = CachedHttpClient(record_stats=True)

    async def fetch_invoice(self, ksef_reference: str) -> bytes:
        """Pobiera fakturę XML (format FA_VAT) z cache'em HTTP.

        SUPERMOC HISHEL:
          - KSeF faktura dla tego samego reference się nie zmienia
          - hishel cache'uje odpowiedź — drugie pobranie to SQLite HIT
          - Ochrona przed rate limiting KSeF

        Args:
            ksef_reference: Referencja KSeF do pobrania.

        Returns:
            Surowy XML faktury jako bytes.
        """
        url = f"{self.base_url}Invoice/Get/{ksef_reference}"
        resp = await self._http.get(url)
        return resp.content

    async def close(self) -> None:
        """Zamknij CachedHttpClient."""
        await self._http.close()
