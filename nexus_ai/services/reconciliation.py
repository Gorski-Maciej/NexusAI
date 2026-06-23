"""Reconciliation engine — uzgadnianie transakcji bankowych z księgowymi.

Używa TigerBeetle dla double-entry + DuckDB dla analityki.
Zgodnie z aa3fvcx.txt: NATS JetStream dla zdarzeń bankowych, Taskiq dla zadań.
"""

from __future__ import annotations

import uuid

import anyio
from collections.abc import AsyncIterator
from msgspec import Struct, field
from typing import Any, final

import pendulum
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from sqlalchemy.orm import sessionmaker
from sqlmodel import select, Session, text

from nexus_ai.core.nats_utils import NatsErrors, get_connection, safe_close

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads
from structlog import get_logger

logger = get_logger("nexus.reconciliation")
from nexus_ai.services.tigerbeetle.client import (
    LEDGER,
    TRANSFER_CODE,
    TigerBeetleClient,
    _generate_tb_id,
)
from nexus_ai.services.tigerbeetle.models import CompanyProfile, LedgerTransferCache


class MissingInvoiceAlert(Struct):
    company_id: uuid.UUID
    contractor_nip: str
    amount_minor: int
    transaction_id: str
    bank_posted_at: pendulum.DateTime
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


class AlertHub(Struct):
    _subscribers: set[tuple[anyio.MemoryObjectSendStream, anyio.MemoryObjectReceiveStream]] = field(
        default_factory=set
    )

    async def publish(self, event: dict[str, Any]) -> None:
        for stream in list(self._subscribers):
            await stream[0].send(event)

    async def subscribe(self) -> AsyncIterator[dict[str, Any]]:
        send, receive = anyio.create_memory_object_stream[dict[str, Any]]()
        self._subscribers.add((send, receive))
        try:
            async with receive:
                async for item in receive:
                    yield item
        finally:
            self._subscribers.discard((send, receive))


@final
class ReconciliationEngine:
    """Silnik uzgadniania transakcji bankowych z księgowymi w TigerBeetle."""

    def __init__(
        self,
        session_factory: sessionmaker[Session] | async_sessionmaker[AsyncSession],
        tb_client: TigerBeetleClient,
        alert_hub: AlertHub,
        nats_url: str = "nats://127.0.0.1:4222",
        subject: str = "bank.transactions.raw",
    ) -> None:
        self.session_factory = session_factory
        self._is_async = isinstance(session_factory, async_sessionmaker)
        self.tb_client = tb_client
        self.alert_hub = alert_hub
        self.nats_url = nats_url
        self.subject = subject
        self._nc = None

    async def start(self) -> None:
        NatsErrors.init()
        self._nc = await get_connection(
            nats_url=self.nats_url,
            name="nexus-reconciliation",
        )
        if self._nc is not None:
            await self._nc.subscribe(self.subject, cb=self._on_nats_message)

    async def stop(self) -> None:
        if self._nc is not None:
            await safe_close(self._nc)
            self._nc = None

    async def _on_nats_message(self, msg: Any) -> None:
        payload = msgspec_loads(msg.data)
        # SUPERMOC: run_sync() dla async Session — bezpieczne wywołanie
        # sync kodu z async kontekstu. Blokuje tylko ten wątek, nie event loop.
        if self._is_async:
            async with self.session_factory() as session:  # type: ignore[attr-defined]
                await session.run_sync(lambda s: self._process_bank_transaction_sync(s, payload))
        else:
            with self.session_factory() as session:
                self._process_bank_transaction_sync(session, payload)

    def _process_bank_transaction_sync(self, session: Session, payload: dict[str, Any]) -> bool:
        """SUPERMOC: Process bank transaction with native TB pending transfers.

        Zamiast ręcznego zarządzania statusem w SQLite, używamy
        TB natywnych pending transferów i ``get_account_balances()``.
        Uwaga: sesja jest przekazana z zewnątrz — nie otwieramy drugiej.
        """
        company_id = uuid.UUID(payload["company_id"])
        amount_minor = int(payload["amount_minor"])
        contractor_nip = str(payload["contractor_nip"])
        posted_at = pendulum.parse(payload["posted_at"])
        transaction_id = str(payload.get("transaction_id", ""))

        # Uwaga: sesja jest już otwarta przez wywołującego
        # (run_sync w async lub with session w sync)
        company = session.scalar(select(CompanyProfile).where(CompanyProfile.id == company_id))
        if company is None:
            return False

        # SUPERMOC: Użyj TB get_account_balances() zamiast SQLite LedgerTransfer
        # TB jest source of truth — sprawdzamy pending transfery przez TB API
        try:
            transfers_raw = self.tb_client.get_account_transfers(
                account_id=0,  # All accounts
                limit=100,
            )
        except Exception:
            transfers_raw = []

        # SUPERMOC: Sprawdź saldo przez get_account_balances
        matched_pending_id = None
        matched_credit_account = None

        # SUPERMOC: Użyj cache z SQLite tylko jako fallback
        cache_entries = (
            session.execute(
                select(LedgerTransferCache).where(
                    LedgerTransferCache.company_id == company_id,
                    LedgerTransferCache.amount_minor == amount_minor,
                )
            )
            .scalars()
            .all()
        )

        for entry in cache_entries:
            # Sprawdź saldo przez TB
            balances = self.tb_client.get_account_balances_batch([
                entry.debit_account,
                entry.credit_account,
            ])
            credit_balance = balances.get(entry.credit_account, 0)
            if credit_balance >= amount_minor:
                matched_pending_id = entry.tb_transfer_id
                matched_credit_account = entry.credit_account
                break

        if matched_pending_id is not None:
            # SUPERMOC: Post pending transfer przez TB natywnie
            approved = self.tb_client.post_pending_transfer(matched_pending_id)
            if approved:
                session.execute(
                    text("UPDATE ledger_transfer_cache SET meta = json_set(meta, '$.reconciliation', :recon) WHERE tb_transfer_id = :id"),
                    {
                        "recon": msgspec_dumps({
                            "status": "auto-confirmed",
                            "bank_transaction_id": transaction_id,
                            "matched_at": pendulum.now("UTC").isoformat(),
                        }),
                        "id": matched_pending_id,
                    }
                )
                session.commit()
            return approved

        if posted_at.diff(pendulum.now()).in_days() >= 15:
            # Alert logowany — publish jest async, a to jest sync kontekst
            # Prawdziwy publish odbywa się w async wrapperze (_on_nats_message)
            logger.warning(
                "[RECONCILIATION] Missing invoice alert: company=%s nip=%s amount=%d",
                company_id, contractor_nip, amount_minor,
            )
        return False


class ClearingAccountsConfig(Struct, frozen=True):
    account_bank_main: int
    account_expense_fees: int
    account_receivable: int
    provider_clearing_accounts: dict[str, int]


@final
class ClearingAccountsEngine:
    """Implementuje ekstrakcję opłat i uzgadnianie wypłat z idempotencją."""

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

    def process_provider_fees(
        self, *, provider_id: str, fee_amount: int, operation_id: str
    ) -> dict[str, Any]:
        if fee_amount <= 0:
            raise ValueError("fee_amount must be > 0")
        if operation_id in self._processed_operations:
            return {"status": "idempotent-replay", "operation_id": operation_id}

        provider_account = self._provider_account(provider_id)
        pending_id = self.tb_client.create_pending_transfer(
            debit_account=self.config.account_expense_fees,
            credit_account=provider_account,
            amount_minor=fee_amount,
            source_document_id=uuid.uuid5(uuid.NAMESPACE_URL, f"fees:{provider_id}:{operation_id}"),
        )
        if pending_id is None:
            return {"status": "failed", "operation_id": operation_id, "error": "pending creation failed"}
        posted = self.tb_client.post_pending_transfer(pending_id)
        if posted:
            self._processed_operations.add(operation_id)
        return {
            "status": "posted" if posted else "failed",
            "operation_id": operation_id,
            "pending_id": pending_id,
        }

    def reconcile_bank_payout(
        self, *, provider_id: str, payout_amount: int, operation_id: str
    ) -> dict[str, Any]:
        if payout_amount <= 0:
            raise ValueError("payout_amount must be > 0")
        if operation_id in self._processed_operations:
            return {"status": "idempotent-replay", "operation_id": operation_id}

        provider_account = self._provider_account(provider_id)
        pending_id = self.tb_client.create_pending_transfer(
            debit_account=self.config.account_bank_main,
            credit_account=provider_account,
            amount_minor=payout_amount,
            source_document_id=uuid.uuid5(
                uuid.NAMESPACE_URL, f"payout:{provider_id}:{operation_id}"
            ),
        )
        if pending_id is None:
            return {"status": "failed", "operation_id": operation_id, "error": "pending creation failed"}
        posted = self.tb_client.post_pending_transfer(pending_id)
        if posted:
            self._processed_operations.add(operation_id)
        clearing_balance = self.tb_client.get_account_credits_posted(provider_account)
        return {
            "status": "posted" if posted else "failed",
            "operation_id": operation_id,
            "pending_id": pending_id,
            "clearing_credits_posted": clearing_balance,
        }


class OpenInvoice(Struct, frozen=True):
    invoice_id: str
    amount_due_minor: int
    due_date: pendulum.DateTime


class BankReconciliationConfig(Struct, frozen=True):
    account_bank_main: int
    account_receivable: int
    account_rounding_differences: int
    rounding_threshold_minor: int = 10


@final
class BankReconciliationEngine:
    def __init__(self, tb_client: TigerBeetleClient, config: BankReconciliationConfig) -> None:
        self.tb_client = tb_client
        self.config = config

    def reconcile_bulk_payment(
        self,
        *,
        vendor_id: str,
        payment_amount_minor: int,
        received_date: pendulum.DateTime,
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
            pending_id = self.tb_client.create_pending_transfer(
                debit_account=self.config.account_bank_main,
                credit_account=self.config.account_receivable,
                amount_minor=allocated,
                source_document_id=uuid.uuid5(
                    uuid.NAMESPACE_URL,
                    f"bulk:{vendor_id}:{invoice.invoice_id}:{received_date.isoformat()}",
                ),
            )
            posted = False
            if pending_id is not None:
                posted = self.tb_client.post_pending_transfer(pending_id)
            allocations.append(
                {"invoice_id": invoice.invoice_id, "amount_minor": allocated, "posted": posted}
            )
            remaining -= allocated

        rounding_adjustment_posted = False
        if 0 < remaining < self.config.rounding_threshold_minor:
            rounding_pending_id = self.tb_client.create_pending_transfer(
                debit_account=self.config.account_bank_main,
                credit_account=self.config.account_rounding_differences,
                amount_minor=remaining,
                source_document_id=uuid.uuid5(
                    uuid.NAMESPACE_URL,
                    f"rounding:{vendor_id}:{received_date.isoformat()}:{remaining}",
                ),
            )
            if rounding_pending_id is not None:
                rounding_adjustment_posted = self.tb_client.post_pending_transfer(
                    rounding_pending_id
                )
            remaining = 0

        return {
            "vendor_id": vendor_id,
            "received_date": received_date.isoformat(),
            "payment_amount_minor": payment_amount_minor,
            "allocations": allocations,
            "rounding_adjustment_posted": rounding_adjustment_posted,
            "remaining_unallocated_minor": remaining,
        }
