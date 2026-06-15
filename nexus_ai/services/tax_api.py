"""
TaxApiService — DEPRECATED.

ZASTĄPIONY PRZEZ: services.white_list_service.WhiteListService

Powód:
  - WhiteListService używa CachedHttpClient (hishel) zamiast surowego httpx.AsyncClient
  - WhiteListService ma podwójny cache: NexusCache (wynik) + hishel (HTTP response)
  - TaxApiService był duplikatem — ta sama funkcja (weryfikacja NIP), gorsza implementacja

Usage (nowy sposób):
    from nexus_ai.services.white_list_service import WhiteListService
    service = WhiteListService()
    await service.verify_bank_account(nip, account)

Data deprecation: 2026-06-15
Planowane usunięcie: 2026-09-15
"""

from __future__ import annotations

import warnings
from typing import final

import pendulum

from nexus_ai.core.config import AppConfig
from nexus_ai.services.white_list_service import WhiteListService


@final
class TaxApiService:
    """DEPRECATED: Użyj WhiteListService zamiast TaxApiService.

    TaxApiService był pierwszą implementacją klienta Białej Listy MF,
    ale został zastąpiony przez WhiteListService, który:
      - Używa CachedHttpClient (hishel) zamiast httpx.AsyncClient
      - Ma podwójny cache: NexusCache (wynik) + hishel (HTTP Cache-Control/ETag)
      - Implementuje async close() dla czystego zamykania zasobów
    """

    def __init__(self, config: AppConfig):
        warnings.warn(
            "TaxApiService is deprecated. Use WhiteListService instead.",
            DeprecationWarning,
            stacklevel=2,
        )
        self.config = config
        self._white_list = WhiteListService()

    async def verify_nip(self, nip: str) -> dict | None:
        """Sprawdza NIP w bazie Ministerstwa Finansów (Biała Lista).

        Deleguje do WhiteListService.verify_bank_account() z pustym kontem.
        """
        if not nip or len(nip) != 10:
            return None

        try:
            today = pendulum.now().date().isoformat()
            # WhiteListService sprawdza konto — bez konta zwraca informację o NIP
            is_valid = await self._white_list.verify_bank_account(nip, "")
            return {"nip": nip, "valid": is_valid, "date": today}
        except Exception:
            return None

    async def close(self) -> None:
        """Zamknij WhiteListService (CachedHttpClient)."""
        await self._white_list.close()
