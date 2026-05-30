from datetime import date
from decimal import Decimal, ROUND_HALF_UP

import httpx
from core.circuit_breaker import CircuitBreaker


class AccountingService:
    # Circuit Breaker dla Białej Listy MF (Rozwiązanie 21)
    _nip_cb = CircuitBreaker(failure_threshold=3, recovery_timeout=60, name="white_list_api")

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
            round(net * Decimal("1.05"), 2)
        ]
        return round(gross, 2) in calculated_rates

    @staticmethod
    def calculate_vat(net: Decimal, rate: float = 0.23) -> Decimal:
        vat = net * Decimal(str(rate))
        return vat.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    @staticmethod
    def validate_iban(iban: str) -> bool:
        """
        Walidacja numeru IBAN.
        Sprawdza: długość (15-34 znaki), strukturę (2 litery + 2 cyfry + reszta alfanumeryczna),
        oraz sumę kontrolną modulo 97 (algorytm IBAN).
        """
        if not iban or not isinstance(iban, str):
            return False

        # Usuń białe znaki i zamień na uppercase
        clean_iban = "".join(iban.upper().split())

        # Sprawdź długość (IBAN ma od 15 do 34 znaków)
        if len(clean_iban) < 15 or len(clean_iban) > 34:
            return False

        # Sprawdź strukturę: 2 litery + 2 cyfry + reszta alfanumeryczna
        if not clean_iban[:2].isalpha() or not clean_iban[2:4].isdigit():
            return False
        if not clean_iban[4:].isalnum():
            return False

        # Algorytm sumy kontrolnej IBAN (modulo 97)
        # Przenieś 4 pierwsze znaki na koniec
        rearranged = clean_iban[4:] + clean_iban[:4]

        # Zamień litery na liczby (A=10, B=11, ..., Z=35)
        numeric_string = ""
        for char in rearranged:
            if char.isalpha():
                numeric_string += str(ord(char) - ord("A") + 10)
            else:
                numeric_string += char

        # Oblicz modulo 97
        # Dzielimy na kawałki, by uniknąć przepełnienia dla długich stringów
        remainder = 0
        for i in range(0, len(numeric_string), 9):
            chunk = numeric_string[i:i + 9]
            remainder = int(str(remainder) + chunk) % 97

        return remainder == 1

    async def _do_verify_nip(self, nip: str) -> dict | None:
        """Wewnętrzna metoda wykonująca rzeczywiste żądanie HTTP do Białej Listy."""
        clean_nip = "".join(filter(str.isdigit, nip))
        async with httpx.AsyncClient(timeout=5.0) as client:
            today = date.today().isoformat()
            response = await client.get(f"{self.base_url}{clean_nip}?date={today}")

            if response.status_code == 200:
                data = response.json()
                return data.get("result", {}).get("subject")
            return None

    async def verify_nip(self, nip: str) -> dict | None:
        """Sprawdza NIP w bazie Ministerstwa Finansów (Biała Lista).
        Używa Circuit Breaker, aby chronić przed kaskadowymi awariami (Rozwiązanie 21).
        """
        # Oczyszczanie NIPu ze zbędnych znaków (np. myślników)
        clean_nip = "".join(filter(str.isdigit, nip))
        if not clean_nip or len(clean_nip) != 10:
            return None

        try:
            return await self._nip_cb.call(self._do_verify_nip, clean_nip)
        except Exception as e:
            print(f"[AccountingService] Circuit Breaker OPEN lub błąd weryfikacji NIP: {e}")
            return None
