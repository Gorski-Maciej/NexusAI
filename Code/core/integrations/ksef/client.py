# core/integrations/ksef/client.py
import httpx


class KsefClient:
    def __init__(self, session_token: str, base_url: str):
        self.headers = {"SessionToken": session_token, "Accept": "application/json"}
        self.base_url = base_url

    async def fetch_invoice(self, ksef_reference: str):
        """Pobiera fakturę XML (format FA_VAT)."""
        async with httpx.AsyncClient(headers=self.headers) as client:
            url = f"{self.base_url}Invoice/Get/{ksef_reference}"
            resp = await client.get(url)
            return resp.content # Zwraca surowy bajtowo XML faktury
