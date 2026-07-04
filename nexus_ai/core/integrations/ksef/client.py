"""
KSeF Client -- HTTP client for KSeF API.
"""

from __future__ import annotations

from nexus_ai.core.cache.http_client import CachedHttpClient


class KsefClient:
    """Klient API KSeF."""
    __slots__ = ('_http', 'base_url', 'headers')

    def __init__(self, session_token: str, base_url: str) -> None:
        self.headers = {"SessionToken": session_token, "Accept": "application/json"}
        self.base_url = base_url
        self._http = CachedHttpClient()

    async def fetch_invoice(self, ksef_reference: str) -> bytes:
        """Pobiera fakturę XML (format FA_VAT)."""
        url = f"{self.base_url}Invoice/Get/{ksef_reference}"
        resp = await self._http.get(url)
        return resp.content

    async def close(self) -> None:
        await self._http.close()
