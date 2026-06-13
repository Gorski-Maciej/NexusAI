"""TigerBeetle client — bezpieczny klient dla lokalnego silnika księgowego.

Zgodnie z aa3fvcx.txt:
- TigerBeetle w Zig — podwójny zapis na poziomie protokołu
- komunikacja przez gniazdo UNIX (localhost)
- amount jako int (grosze), bez Decimal
"""

from __future__ import annotations

from typing import final

import os
import uuid
from msgspec import Struct

from nexus_crypto import blake2b as _blake2b


class TwoPhaseTransfer(Struct):
    """Dwufazowy przelew TigerBeetle (pending → post)."""

    pending_id: int
    debit_account: int
    credit_account: int
    amount_minor: int
    source_document_id: uuid.UUID
    user_data_128: int = 0


@final
class TigerBeetleMapper:
    """Konwertuje polskie symbole kont (np. 401-02) na uint128 dla TigerBeetle.

    Używa blake2b (hashlib) do deterministycznego mapowania — zgodnie z aa3fvcx.txt
    hashlib jest używany gdzie nexus_crypto nie wspiera streamingu/algorytmu.
    """

    @staticmethod
    def account_to_uint128(account_symbol: str) -> int:
        digest = _blake2b(account_symbol.encode("utf-8"), digest_size=16)
        return int.from_bytes(digest, byteorder="big", signed=False)

    def build_map(self, accounts: list[str]) -> dict[str, int]:
        return {acc: self.account_to_uint128(acc) for acc in accounts}


@final
class TigerBeetleClient:
    """Wrapper dla TigerBeetle — interface-ready, safe stub dla lokalnego developmentu.

    W produkcji: komunikacja z lokalnym procesem TigerBeetle przez gniazdo UNIX.
    Obecnie: stub z pamięcią (dict) do testów i developmentu.

    Zgodnie z aa3fvcx.txt:
    - amount jako int (grosze) — bezpośrednie mapowanie z Nexus-Money
    - dwufazowe transfery (pending → post)
    - operacje asynchroniczne (anyio/async)
    """

    def __init__(
        self, cluster_id: int | None = None, replica_addresses: list[str] | None = None
    ) -> None:
        self.cluster_id = cluster_id or int(os.getenv("TB_CLUSTER_ID", "0"))
        self.replica_addresses = replica_addresses or os.getenv(
            "TB_REPLICA_ADDRESSES", "3000"
        ).split(",")
        self._pending_transfers: dict[int, TwoPhaseTransfer] = {}
        self._account_credits_posted: dict[int, int] = {}

    async def create_accounts(self, account_ids: list[int]) -> dict[str, int]:
        """Utwórz konta księgowe w TigerBeetle."""
        created = len(set(account_ids))
        return {"created": created, "cluster_id": self.cluster_id}

    async def create_two_phase_transfer(
        self,
        *,
        debit_account: int,
        credit_account: int,
        amount_minor: int,
        source_document_id: uuid.UUID,
        user_data_128: int = 0,
    ) -> TwoPhaseTransfer:
        """Utwórz dwufazowy przelew (pending)."""
        pending_id = uuid.uuid4().int >> 64
        transfer = TwoPhaseTransfer(
            pending_id=pending_id,
            debit_account=debit_account,
            credit_account=credit_account,
            amount_minor=amount_minor,
            source_document_id=source_document_id,
            user_data_128=user_data_128,
        )
        self._pending_transfers[pending_id] = transfer
        return transfer

    async def post_pending_transfer(self, pending_id: int) -> bool:
        """Zatwierdź oczekujący przelew (pending → posted)."""
        transfer = self._pending_transfers.pop(pending_id, None)
        if transfer is None:
            return False
        self._account_credits_posted[transfer.credit_account] = (
            self._account_credits_posted.get(transfer.credit_account, 0) + transfer.amount_minor
        )
        return True

    async def get_account_credits_posted(self, account_id: int) -> int:
        """Pobierz zaksięgowane saldo konta."""
        return self._account_credits_posted.get(account_id, 0)
