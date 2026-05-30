from datetime import date

import httpx
from core.circuit_breaker import CircuitBreaker
from core.logger import logger


class WhiteListService:
    # Circuit Breaker dla Białej Listy MF (Rozwiązanie 21)
    _cb = CircuitBreaker(failure_threshold=3, recovery_timeout=60, name="white_list_bank_account")

    BASE_URL = "https://wl-api.mf.gov.pl/api/search/nip/"

    @classmethod
    async def _do_verify(cls, nip: str, clean_account: str, target_date: str) -> bool:
        """Wewnętrzna metoda wykonująca rzeczywiste żądanie HTTP."""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{cls.BASE_URL}{nip}?date={target_date}")

            if response.status_code == 200:
                data = response.json()
                accounts = data.get("result", {}).get("subject", {}).get("accountNumbers", [])
                return clean_account in accounts

            return False

    @classmethod
    async def verify_bank_account(cls, nip: str, account_to_check: str) -> bool:
        """Sprawdza czy konto bankowe jest na białej liście MF.
        Używa Circuit Breaker, aby chronić przed kaskadowymi awariami (Rozwiązanie 21).
        """
        target_date = date.today().isoformat()
        clean_account = "".join(filter(str.isdigit, account_to_check))

        try:
            return await cls._cb.call(cls._do_verify, nip, clean_account, target_date)
        except Exception as e:
            logger.error(f"Błąd Białej Listy (Circuit Breaker): {e}")
            return False
