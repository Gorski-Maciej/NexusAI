from datetime import date

import httpx
from core.config import AppConfig


class TaxApiService:
    def __init__(self, config: AppConfig):
        self.config = config
        self.base_url = "https://wl-api.mf.gov.pl/api/search/nip/"  # Oficjalne API MF

    async def verify_nip(self, nip: str) -> dict | None:
        """Sprawdza NIP w bazie Ministerstwa Finansów (Biała Lista)."""
        if not nip or len(nip) != 10:
            return None

        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                # Wymagane przez MF: data sprawdzenia
                today = date.today().isoformat()
                response = await client.get(f"{self.base_url}{nip}?date={today}")

                if response.status_code == 200:
                    data = response.json()
                    return data.get("result", {}).get("subject")
        except Exception as e:
            print(f"Błąd połączenia z Białą Listą: {e}")
            return None

        return None
