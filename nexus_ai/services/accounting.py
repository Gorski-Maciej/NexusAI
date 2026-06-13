from __future__ import annotations

from typing import final

from decimal import ROUND_HALF_UP, Decimal

import httpx
import pendulum


@final
class AccountingService:
    def __init__(self):
        self.base_url = "https://wl-api.mf.gov.pl/api/search/nip/"

    @staticmethod
    def validate_amounts(net: Decimal, gross: Decimal) -> bool:
        """Sprawdza, czy kwoty są matematycznie poprawne pod kątem stawek VAT.
        Zakłada, że VAT musi być jedną ze standardowych stawek (23%, 8%, 5%, 0%)."""
        if net <= 0 or gross <= 0 or gross < net:
            return False

        vat_amount = gross - net
        if vat_amount == 0:
            return True  # Faktura zwolniona lub 0%

        # Obliczamy efektywną stawkę VAT
        effective_rate = (vat_amount / net).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        valid_rates = [Decimal("0.23"), Decimal("0.08"), Decimal("0.05"), Decimal("0.00")]

        if effective_rate in valid_rates:
            return True

        # Sprawdzanie najpopularniejszych stawek VAT w przypadku drobnych różnic
        calculated_rates = [
            round(net * Decimal("1.23"), 2),
            round(net * Decimal("1.08"), 2),
            round(net * Decimal("1.05"), 2),
        ]
        return round(gross, 2) in calculated_rates

    @staticmethod
    def calculate_vat(net: Decimal, rate: float = 0.23) -> Decimal:
        vat = net * Decimal(str(rate))
        return vat.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    async def verify_nip(self, nip: str) -> dict | None:
        """Sprawdza NIP w bazie Ministerstwa Finansów (Biała Lista)."""
        # Oczyszczanie NIPu ze zbędnych znaków (np. myślników)
        clean_nip = "".join(filter(str.isdigit, nip))
        if not clean_nip or len(clean_nip) != 10:
            return None

        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                today = pendulum.now().date().isoformat()
                response = await client.get(f"{self.base_url}{clean_nip}?date={today}")

                if response.status_code == 200:
                    data = response.json()
                    return data.get("result", {}).get("subject")
                return None
        except httpx.RequestError as e:
            print(f"[AccountingService] Błąd połączenia z Białą Listą: {e}")
            return None
        except Exception as e:
            print(f"[AccountingService] Nieznany błąd weryfikacji NIP: {e}")
            return None
