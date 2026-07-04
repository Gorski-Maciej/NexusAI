from __future__ import annotations

from typing import final

import pendulum

from nexus_ai.core.cache import get_cache
from nexus_ai.core.cache.http_client import CachedHttpClient
from nexus_ai.core.logger import logger


@final
class WhiteListService:
    """Serwis weryfikacji białej listy podatników VAT."""

    BASE_URL = "https://wl-api.mf.gov.pl/api/search/nip/"
    _CACHE_TTL = 3600
    __slots__ = ("_cache", "_http")

    def __init__(self) -> None:
        self._cache = get_cache()
        self._http = CachedHttpClient()

    async def close(self) -> None:
        await self._http.close()

    async def _fetch_nip_data(self, nip: str) -> dict | None:
        """Pobiera dane podmiotu z API MF dla danego NIP (z cache)."""
        cache_key = f"whitelist:nip_data:{nip}"
        cached = await self._cache.get(cache_key)
        if cached is not None:
            return cached if cached else None

        target_date = pendulum.now().date().isoformat()
        try:
            response = await self._http.get(f"{self.BASE_URL}{nip}?date={target_date}")
            if response.status_code == 200:
                data = response.json()
                subject = data.get("result", {}).get("subject", {})
                if subject:
                    await self._cache.set(cache_key, subject, ttl=self._CACHE_TTL)
                    return subject
            await self._cache.set(cache_key, {}, ttl=300)
            return None
        except Exception as e:
            logger.error("[WhiteList] Błąd API MF dla NIP=%s: %s", nip, e)
            return None

    async def check_nip(self, nip: str) -> dict | None:
        """Weryfikuje NIP w Białej Liście MF i zwraca dane podmiotu."""
        return await self._fetch_nip_data(nip)

    async def verify_bank_account(self, nip: str, account_to_check: str) -> bool:
        """Sprawdza czy konto bankowe jest na białej liście MF."""
        clean_account = "".join(filter(str.isdigit, account_to_check))
        cache_key = f"whitelist:{nip}:{clean_account}"

        cached = await self._cache.get(cache_key)
        if cached is not None:
            logger.debug("[WhiteList] Cache HIT for NIP=%s account=%s", nip, clean_account)
            return bool(cached)

        subject = await self._fetch_nip_data(nip)
        if subject is None:
            await self._cache.set(cache_key, False, ttl=300)
            return False

        accounts = subject.get("accountNumbers", [])
        result = clean_account in accounts
        await self._cache.set(cache_key, result, ttl=self._CACHE_TTL)
        return result
