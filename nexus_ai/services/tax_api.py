"""
TaxApiService -- DEPRECATED.

ZASTĄPIONY PRZEZ: services.white_list_service.WhiteListService

Usage:
    from nexus_ai.services.white_list_service import WhiteListService
    service = WhiteListService()
    await service.verify_bank_account(nip, account)
"""

from __future__ import annotations

import warnings
from typing import final

import pendulum

from nexus_ai.core.config import AppConfig
from nexus_ai.services.white_list_service import WhiteListService


@final
class TaxApiService:
    """DEPRECATED: Użyj WhiteListService zamiast TaxApiService."""

    def __init__(self, config: AppConfig):
        warnings.warn(
            "TaxApiService is deprecated. Use WhiteListService instead.",
            DeprecationWarning,
            stacklevel=2,
        )
        self.config = config
        self._white_list = WhiteListService()

    async def verify_nip(self, nip: str) -> dict | None:
        if not nip or len(nip) != 10:
            return None
        try:
            today = pendulum.now().date().isoformat()
            is_valid = await self._white_list.verify_bank_account(nip, "")
            return {"nip": nip, "valid": is_valid, "date": today}
        except Exception:
            return None

    async def close(self) -> None:
        await self._white_list.close()

    __slots__ = ('_white_list', 'config')
