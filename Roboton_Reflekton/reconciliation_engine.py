from __future__ import annotations

import asyncio
import json
import uuid
from collections.abc import AsyncIterator
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any

import nats
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .ledger_client import TigerBeetleClient
from .models import CompanyProfile, LedgerTransfer, TransferStatus


@dataclass(slots=True)
class MissingInvoiceAlert:
    company_id: uuid.UUID
    contractor_nip: str
    amount_minor: int
    transaction_id: str
    bank_posted_at: datetime
    reason: str = "No pending transfer match after 15 days"

    def to_sse_event(self) -> dict[str, Any]:
        return {
            "type": "MissingInvoiceAlert",
            "company_id": str(self.company_id),
            "contractor_nip": self.contractor_nip,
            "amount_minor": self.amount_minor,
            "transaction_id": self.transaction_id,
            "bank_posted_at": self.bank_posted_at.isoformat(),
            "reason": self.reason,
        }


@dataclass
class AlertHub:
    _subscribers: set[asyncio.Queue[dict[str, Any]]] = field(default_factory=set)

    async def publish(self, event: dict[str, Any]) -> None:
        for queue in list(self._subscribers):
            await queue.put(event)

    async def subscribe(self) -> AsyncIterator[dict[str, Any]]:
        queue: asyncio.Queue[dict[str, Any]] = asyncio.Queue()
        self._subscribers.add(queue)
        try:
            while True:
                yield await queue.get()
        finally:
            self._subscribers.discard(queue)


class ReconciliationEngine:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        tb_client: TigerBeetleClient,
        alert_hub: AlertHub,
        nats_url: str = "nats://127.0.0.1:4222",
        subject: str = "bank.transactions.raw",
    ) -> None:
        self.session_factory = session_factory
        self.tb_client = tb_client
        self.alert_hub = alert_hub
        self.nats_url = nats_url
        self.subject = subject
        self._nc = None

    async def start(self) -> None:
        self._nc = await nats.connect(self.nats_url)
        await self._nc.subscribe(self.subject, cb=self._on_nats_message)

    async def stop(self) -> None:
        if self._nc is not None:
            await self._nc.close()
            self._nc = None

    async def _on_nats_message(self, msg: Any) -> None:
        payload = json.loads(msg.data.decode("utf-8"))
        await self.process_bank_transaction(payload)

    async def process_bank_transaction(self, payload: dict[str, Any]) -> bool:
        company_id = uuid.UUID(payload["company_id"])
        amount_minor = int(payload["amount_minor"])
        contractor_nip = str(payload["contractor_nip"])
        posted_at = datetime.fromisoformat(payload["posted_at"])
        transaction_id = str(payload.get("transaction_id", ""))

        async with self.session_factory() as session:
            company = await session.scalar(select(CompanyProfile).where(CompanyProfile.id == company_id))
            if company is None:
                return False

            pending_transfers = (
                (
                    await session.execute(
                        select(LedgerTransfer).where(
                            LedgerTransfer.company_id == company_id,
                            LedgerTransfer.status == TransferStatus.PENDING,
                            LedgerTransfer.amount_minor == amount_minor,
                        )
                    )
                )
                .scalars()
                .all()
            )

            matched_transfer: LedgerTransfer | None = None
            for transfer in pending_transfers:
                transfer_nip = str(transfer.meta.get("classification", {}).get("contractor_nip", ""))
                if transfer_nip == contractor_nip:
                    credits_posted = await self.tb_client.get_account_credits_posted(transfer.target_account)
                    if credits_posted >= amount_minor:
                        matched_transfer = transfer
                        break

            if matched_transfer is not None:
                pending_id = int(matched_transfer.meta.get("tb_pending_id"))
                approved = await self.tb_client.post_pending_transfer(pending_id)
                if approved:
                    matched_transfer.status = TransferStatus.POSTED
                    matched_transfer.meta = {
                        **matched_transfer.meta,
                        "reconciliation": {
                            "status": "auto-confirmed",
                            "bank_transaction_id": transaction_id,
                            "matched_at": datetime.now(timezone.utc).isoformat(),
                        },
                    }
                    await session.commit()
                return approved

            if posted_at <= datetime.now(posted_at.tzinfo or timezone.utc) - timedelta(days=15):
                alert = MissingInvoiceAlert(
                    company_id=company_id,
                    contractor_nip=contractor_nip,
                    amount_minor=amount_minor,
                    transaction_id=transaction_id,
                    bank_posted_at=posted_at,
                )
                await self.alert_hub.publish(alert.to_sse_event())
            return False
