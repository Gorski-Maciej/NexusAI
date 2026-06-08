from __future__ import annotations

import asyncio
import uuid
from collections.abc import AsyncIterator
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

import nats
import pendulum
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from nexus_ai.core.msgspec_utils import msgspec_loads

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
        payload = msgspec_loads(msg.data)
        await self.process_bank_transaction(payload)

    async def process_bank_transaction(self, payload: dict[str, Any]) -> bool:
        company_id = uuid.UUID(payload["company_id"])
        amount_minor = int(payload["amount_minor"])
        contractor_nip = str(payload["contractor_nip"])
        posted_at = pendulum.parse(payload["posted_at"])
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
                            "matched_at": pendulum.now("UTC").isoformat(),
                        },
                    }
                    await session.commit()
                return approved

            if posted_at <= datetime.now(posted_at.tzinfo or UTC) - pendulum.duration(days=15):
                alert = MissingInvoiceAlert(
                    company_id=company_id,
                    contractor_nip=contractor_nip,
                    amount_minor=amount_minor,
                    transaction_id=transaction_id,
                    bank_posted_at=posted_at,
                )
                await self.alert_hub.publish(alert.to_sse_event())
            return False


@dataclass(frozen=True, slots=True)
class ClearingAccountsConfig:
    account_bank_main: int
    account_expense_fees: int
    account_receivable: int
    provider_clearing_accounts: dict[str, int]


class ClearingAccountsEngine:
    """Implements provider fee extraction and bank payout reconciliation with idempotency."""

    def __init__(self, tb_client: TigerBeetleClient, config: ClearingAccountsConfig) -> None:
        self.tb_client = tb_client
        self.config = config
        self._processed_operations: set[str] = set()

    def _provider_account(self, provider_id: str) -> int:
        key = provider_id.strip().lower()
        account = self.config.provider_clearing_accounts.get(key)
        if account is None:
            raise ValueError(f"Unknown provider_id={provider_id!r}")
        return account

    async def process_provider_fees(self, *, provider_id: str, fee_amount: int, operation_id: str) -> dict[str, Any]:
        """Step 2: Debit fees expense / Credit provider clearing account."""
        if fee_amount <= 0:
            raise ValueError("fee_amount must be > 0")
        if operation_id in self._processed_operations:
            return {"status": "idempotent-replay", "operation_id": operation_id}

        provider_account = self._provider_account(provider_id)
        pending = await self.tb_client.create_two_phase_transfer(
            debit_account=self.config.account_expense_fees,
            credit_account=provider_account,
            amount_minor=fee_amount,
            source_document_id=uuid.uuid5(uuid.NAMESPACE_URL, f"fees:{provider_id}:{operation_id}"),
        )
        posted = await self.tb_client.post_pending_transfer(pending.pending_id)
        if posted:
            self._processed_operations.add(operation_id)
        return {
            "status": "posted" if posted else "failed",
            "operation_id": operation_id,
            "pending_id": pending.pending_id,
        }

    async def reconcile_bank_payout(self, *, provider_id: str, payout_amount: int, operation_id: str) -> dict[str, Any]:
        """Step 3: Debit main bank / Credit provider clearing account."""
        if payout_amount <= 0:
            raise ValueError("payout_amount must be > 0")
        if operation_id in self._processed_operations:
            return {"status": "idempotent-replay", "operation_id": operation_id}

        provider_account = self._provider_account(provider_id)
        pending = await self.tb_client.create_two_phase_transfer(
            debit_account=self.config.account_bank_main,
            credit_account=provider_account,
            amount_minor=payout_amount,
            source_document_id=uuid.uuid5(uuid.NAMESPACE_URL, f"payout:{provider_id}:{operation_id}"),
        )
        posted = await self.tb_client.post_pending_transfer(pending.pending_id)
        if posted:
            self._processed_operations.add(operation_id)
        clearing_balance = await self.tb_client.get_account_credits_posted(provider_account)
        return {
            "status": "posted" if posted else "failed",
            "operation_id": operation_id,
            "pending_id": pending.pending_id,
            "clearing_credits_posted": clearing_balance,
        }


@dataclass(frozen=True, slots=True)
class OpenInvoice:
    invoice_id: str
    amount_due_minor: int
    due_date: datetime


@dataclass(frozen=True, slots=True)
class BankReconciliationConfig:
    account_bank_main: int
    account_receivable: int
    account_rounding_differences: int
    rounding_threshold_minor: int = 10


class BankReconciliationEngine:
    def __init__(self, tb_client: TigerBeetleClient, config: BankReconciliationConfig) -> None:
        self.tb_client = tb_client
        self.config = config

    async def reconcile_bulk_payment(
        self,
        *,
        vendor_id: str,
        payment_amount_minor: int,
        received_date: datetime,
        open_invoices: list[OpenInvoice],
    ) -> dict[str, Any]:
        if payment_amount_minor <= 0:
            raise ValueError("payment_amount_minor must be > 0")

        remaining = payment_amount_minor
        allocations: list[dict[str, Any]] = []
        sorted_invoices = sorted(open_invoices, key=lambda item: item.due_date)

        for invoice in sorted_invoices:
            if remaining <= 0:
                break
            allocated = min(invoice.amount_due_minor, remaining)
            if allocated <= 0:
                continue
            pending = await self.tb_client.create_two_phase_transfer(
                debit_account=self.config.account_bank_main,
                credit_account=self.config.account_receivable,
                amount_minor=allocated,
                source_document_id=uuid.uuid5(uuid.NAMESPACE_URL, f"bulk:{vendor_id}:{invoice.invoice_id}:{received_date.isoformat()}"),
            )
            posted = await self.tb_client.post_pending_transfer(pending.pending_id)
            allocations.append({"invoice_id": invoice.invoice_id, "amount_minor": allocated, "posted": posted})
            remaining -= allocated

        rounding_adjustment_posted = False
        if 0 < remaining < self.config.rounding_threshold_minor:
            rounding_pending = await self.tb_client.create_two_phase_transfer(
                debit_account=self.config.account_bank_main,
                credit_account=self.config.account_rounding_differences,
                amount_minor=remaining,
                source_document_id=uuid.uuid5(uuid.NAMESPACE_URL, f"rounding:{vendor_id}:{received_date.isoformat()}:{remaining}"),
            )
            rounding_adjustment_posted = await self.tb_client.post_pending_transfer(rounding_pending.pending_id)
            remaining = 0

        return {
            "vendor_id": vendor_id,
            "received_date": received_date.isoformat(),
            "payment_amount_minor": payment_amount_minor,
            "allocations": allocations,
            "rounding_adjustment_posted": rounding_adjustment_posted,
            "remaining_unallocated_minor": remaining,
        }
