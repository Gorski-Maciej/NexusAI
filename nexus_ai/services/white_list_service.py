from __future__ import annotations

from typing import final

import pendulum

from nexus_ai.core.cache import get_cache
from nexus_ai.core.cache.http_client import CachedHttpClient
from nexus_ai.core.logger import logger


@final
class WhiteListService:
    """Serwis weryfikacji białej listy podatników VAT.

    Zgodnie z aa3fvcx.txt:
    - Używa NexusCache (L1 RAM + L2 SQLite) dla wyników weryfikacji NIP.
    - Używa CachedHttpClient (hishel) dla zapytań HTTPS do MF API.
    - Cache TTL: 3600s (1h) — lista MF zmienia się rzadko.
    """

    BASE_URL = "https://wl-api.mf.gov.pl/api/search/nip/"
    _CACHE_TTL = 3600  # 1h — lista MF zmienia się rzadko

    def __init__(self) -> None:
        self._cache = get_cache()
        self._http = CachedHttpClient()

    async def close(self) -> None:
        """Zamknij CachedHttpClient — zwolnij połączenia HTTP i zamknij cache SQLite."""
        await self._http.close()

    async def verify_bank_account(self, nip: str, account_to_check: str) -> bool:
        """Sprawdza czy konto bankowe jest na białej liście MF.

        Wynik jest cache'owany przez 1h w NexusCache (RAM + SQLite).
        Zapytania HTTP są cache'owane przez hishel (Cache-Control, ETag).
        """
        clean_account = "".join(filter(str.isdigit, account_to_check))
        cache_key = f"whitelist:{nip}:{clean_account}"

        # Sprawdź NexusCache
        cached = await self._cache.get(cache_key)
        if cached is not None:
            logger.debug("[WhiteList] Cache HIT for NIP=%s account=%s", nip, clean_account)
            return bool(cached)

        target_date = pendulum.now().date().isoformat()

        try:
            response = await self._http.get(f"{self.BASE_URL}{nip}?date={target_date}")

            if response.status_code == 200:
                data = response.json()
                accounts = data.get("result", {}).get("subject", {}).get("accountNumbers", [])
                result = clean_account in accounts

                # Zapisz w NexusCache
                await self._cache.set(cache_key, result, ttl=self._CACHE_TTL)
                return result

            # Cache'uj negatywny wynik (API niedostępne) krócej — 5 min
            await self._cache.set(cache_key, False, ttl=300)
            return False
        except Exception as e:
            logger.error(f"[WhiteList] Błąd Białej Listy: {e}")
            return False
