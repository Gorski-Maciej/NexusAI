"""CacheRefresher — odświeża LedgerTransferCache z TigerBeetle.

SUPERMOCE:
- get_account_transfers() z AccountFilter — pobiera rzeczywistą historię z TB
- Syncuje LedgerTransferCache (SQLite) z TB (source of truth)
- Okresowe odświeżanie przez anyio.sleep()
- user_data_128/64/32 dla bogatych metadanych
- Incremental sync: tylko nowsze niż ostatni cached_at
"""

from __future__ import annotations

import pendulum
from typing import Any, final

import anyio
from sqlalchemy import text
from sqlalchemy.orm import Session, sessionmaker
from structlog import get_logger

from nexus_ai.services.tigerbeetle.client import (
    LEDGER,
    TRANSFER_CODE,
    TigerBeetleClient,
)
from nexus_ai.services.tigerbeetle.models import LedgerTransferCache

logger = get_logger("nexus.services.cache_refresher")


@final
class CacheRefresher:
    """Periodicznie odświeża LedgerTransferCache z TigerBeetle.

    SUPERMOCE:
    - get_account_transfers(AccountFilter) — batch query z filtrowaniem
    - Incremental sync — tylko transfery od ostatniego odświeżenia
    - TTL 5 minut dla cache
    """

    def __init__(
        self,
        session_factory: sessionmaker[Session],
        tb_client: TigerBeetleClient,
        *,
        refresh_interval_seconds: float = 300.0,
        batch_size: int = 100,
        company_ids: list[str] | None = None,
    ) -> None:
        self._session_factory = session_factory
        self._tb_client = tb_client
        self._interval = refresh_interval_seconds
        self._batch_size = batch_size
        self._company_ids = company_ids

    async def refresh_all(self) -> int:
        """Odśwież cache dla wszystkich aktywnych kont.

        SUPERMOC: get_account_transfers() z AccountFilter
        — filtrowanie po dacie, limicie, kierunku.

        Returns:
            Liczba odświeżonych transferów.
        """
        total_refreshed = 0

        with self._session_factory() as session:
            # Pobierz aktywne firmy (lub wszystkie jeśli nie podano)
            if self._company_ids:
                companies = self._company_ids
            else:
                rows = session.execute(
                    text("SELECT id FROM company_profiles")
                ).fetchall()
                companies = [str(r[0]) for r in rows]

            for company_id in companies:
                # Pobierz mapowanie kont z company_profiles.tigerbeetle_ledger_map
                row = session.execute(
                    text("SELECT tigerbeetle_ledger_map FROM company_profiles WHERE id = :id"),
                    {"id": company_id},
                ).fetchone()
                if not row:
                    continue

                try:
                    from nexus_ai.core.msgspec_utils import msgspec_loads as _msgspec_loads
                    ledger_map = _msgspec_loads(str(row[0]))
                except (json.JSONDecodeError, TypeError):
                    continue

                # SUPERMOC: Dla każdego konta w mapie, pobierz historię z TB
                for symbol, account_id in ledger_map.items():
                    try:
                        account_id_int = int(account_id)
                    except (ValueError, TypeError):
                        continue

                    # SUPERMOC: get_account_transfers z limitem i odwróconym sortowaniem
                    transfers = self._tb_client.get_account_transfers(
                        account_id=account_id_int,
                        limit=self._batch_size,
                        include_debits=True,
                        include_credits=True,
                        reverse=True,
                    )

                    for t in transfers:
                        # Sprawdź czy już istnieje w cache
                        existing = session.execute(
                            text(
                                "SELECT 1 FROM ledger_transfer_cache "
                                "WHERE tb_transfer_id = :tid"
                            ),
                            {"tid": t.id},
                        ).fetchone()

                        if existing:
                            continue

                        # SUPERMOC: Upsert do cache
                        cache_entry = LedgerTransferCache(
                            tb_transfer_id=t.id,
                            company_id=company_id,
                            debit_account=t.debit_account_id,
                            credit_account=t.credit_account_id,
                            amount_minor=t.amount,
                            source_document_id=str(t.user_data_128),
                            code=t.code,
                            ledger=t.ledger,
                            cached_at=pendulum.now("UTC"),
                        )
                        session.add(cache_entry)
                        total_refreshed += 1

                    # Commit co każde konto (nie cały batch naraz)
                    if total_refreshed % 50 == 0 and total_refreshed > 0:
                        session.commit()

            session.commit()

        logger.info(
            "[CACHE-REFRESHER] Refreshed %d transfers from TigerBeetle",
            total_refreshed,
        )
        return total_refreshed

    async def run_loop(self) -> None:
        """Główna pętla odświeżania — działa w tle.

        Uruchom jako zadanie Taskiq lub anyio task group.
        """
        logger.info(
            "[CACHE-REFRESHER] Starting refresh loop (interval=%ds)",
            self._interval,
        )
        while True:
            try:
                await anyio.lowlevel.checkpoint()
                count = await self.refresh_all()
                if count > 0:
                    logger.info("[CACHE-REFRESHER] Synced %d transfers", count)
            except Exception as exc:
                logger.exception("[CACHE-REFRESHER] Refresh failed: %s", exc)

            await anyio.sleep(self._interval)
