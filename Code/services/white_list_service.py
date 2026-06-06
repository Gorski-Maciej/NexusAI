from datetime import date

import httpx

from core.logger import logger


class WhiteListService:
    BASE_URL = "https://wl-api.mf.gov.pl/api/search/nip/"

    @classmethod
    async def verify_bank_account(cls, nip: str, account_to_check: str) -> bool:
        """Sprawdza czy konto bankowe jest na białej liście MF."""
        target_date = date.today().isoformat()
        clean_account = "".join(filter(str.isdigit, account_to_check))

        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(f"{cls.BASE_URL}{nip}?date={target_date}")

                if response.status_code == 200:
                    data = response.json()
                    accounts = data.get("result", {}).get("subject", {}).get("accountNumbers", [])
                    return clean_account in accounts

                return False
            except Exception as e:
                logger.error(f"Błąd Białej Listy: {e}")
                return False
