from __future__ import annotations

import hashlib  # blake2b for deterministic account IDs (not available in nexus_crypto)
import os
import uuid
from dataclasses import dataclass


@dataclass(slots=True)
class TwoPhaseTransfer:
    pending_id: int
    debit_account: int
    credit_account: int
    amount_minor: int
    source_document_id: uuid.UUID
    user_data_128: int = 0


class TigerBeetleMapper:
    """Converts Polish account symbols (e.g. 401-02) into deterministic uint128-like ints."""

    @staticmethod
    def account_to_uint128(account_symbol: str) -> int:
        digest = hashlib.blake2b(account_symbol.encode("utf-8"), digest_size=16).digest()
        return int.from_bytes(digest, byteorder="big", signed=False)

    def build_map(self, accounts: list[str]) -> dict[str, int]:
        return {acc: self.account_to_uint128(acc) for acc in accounts}


class TigerBeetleClient:
    """Wrapper for TigerBeetle operations (interface-ready, safe stub for local dev)."""

    def __init__(self, cluster_id: int | None = None, replica_addresses: list[str] | None = None) -> None:
        self.cluster_id = cluster_id or int(os.getenv("TB_CLUSTER_ID", "0"))
        self.replica_addresses = replica_addresses or os.getenv("TB_REPLICA_ADDRESSES", "3000").split(",")
        self._pending_transfers: dict[int, TwoPhaseTransfer] = {}
        self._account_credits_posted: dict[int, int] = {}

    async def create_accounts(self, account_ids: list[int]) -> dict[str, int]:
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
        transfer = self._pending_transfers.pop(pending_id, None)
        if transfer is None:
            return False
        self._account_credits_posted[transfer.credit_account] = (
            self._account_credits_posted.get(transfer.credit_account, 0) + transfer.amount_minor
        )
        return True

    async def get_account_credits_posted(self, account_id: int) -> int:
        return self._account_credits_posted.get(account_id, 0)
