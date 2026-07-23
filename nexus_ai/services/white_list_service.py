from __future__ import annotations

from typing import final

import pendulum
import stamina
from httpx import HTTPStatusError, RequestError, TimeoutException

from nexus_ai.core.cache import get_cache
from nexus_ai.core.cache.http_client import CachedHttpClient
from nexus_ai.core.logger import logger


@final
class WhiteListService:
    """Serwis weryfikacji białej listy podatników VAT — v7.0.

    v7.0: Shared CachedHttpClient przez DI (LUKA 12).
    """

    BASE_URL = "https://wl-api.mf.gov.pl/api/search/nip/"
    _CACHE_TTL = 3600
    __slots__ = ("_cache", "_http", "_owns_http")

    def __init__(self, http_client: CachedHttpClient | None = None) -> None:
        self._cache = get_cache()
        if http_client is not None:
            self._http = http_client
            self._owns_http = False
        else:
            self._http = CachedHttpClient()
            self._owns_http = True

    async def close(self) -> None:
        if self._owns_http:
            await self._http.close()

    async def _fetch_nip_data(self, nip: str) -> dict | None:
        """Pobiera dane podmiotu z API MF dla danego NIP (z cache).

        SUPERPOWERY: stamina.retry z circuit breaker — 3 próby, timeout 10s.
        Automatyczny wykładniczy backoff + jitter po każdej nieudanej próbie.
        """
        cache_key = f"whitelist:nip_data:{nip}"
        cached = await self._cache.get(cache_key)
        if cached is not None:
            return cached if cached else None

        target_date = pendulum.now().date().isoformat()
        try:
            for attempt in stamina.retry_context(
                on=(HTTPStatusError, RequestError, TimeoutException, ConnectionError),
                attempts=3,
                timeout=10.0,
                circuit_breaker=True,
            ):
                with attempt:
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
                    except (HTTPStatusError, RequestError, TimeoutException, ConnectionError) as exc:
                        logger.warning("[WhiteList] API MF attempt failed NIP=%s: %s", nip, exc)
                        raise  # re-raise dla stamina.retry_context
        except stamina.RetryingError:
            logger.warning("[WhiteList] Circuit breaker OPEN for NIP=%s — graceful degradation", nip)
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
