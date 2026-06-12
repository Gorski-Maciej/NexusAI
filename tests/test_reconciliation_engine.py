from __future__ import annotations

import anyio
import sys
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path
from types import SimpleNamespace

sys.path.append(str(Path(__file__).resolve().parents[1]))

from unittest.mock import MagicMock

from nexus_ai.services.tigerbeetle.client import TigerBeetleClient
from nexus_ai.services.tigerbeetle.models import TransferStatus
from nexus_ai.services.reconciliation import AlertHub, ClearingAccountsConfig, ClearingAccountsEngine, ReconciliationEngine


# Monkey-patch SQLAlchemy model classes used by reconciliation.py
# to avoid AttributeError on mocked DeclarativeBase models.
import nexus_ai.services.reconciliation as _recon_mod

for _model_name in ("CompanyProfile", "LedgerTransfer"):
    _patched = type(_model_name, (), {})
    _patched.id = MagicMock()
    _patched.company_id = MagicMock()
    _patched.status = MagicMock()
    _patched.amount_minor = MagicMock()
    _patched.target_account = MagicMock()
    setattr(_recon_mod, _model_name, _patched)


class FakeResult:
    def __init__(self, rows):
        self._rows = rows

    def scalars(self):
        return self

    def all(self):
        return self._rows


class FakeSession:
    def __init__(self, company, transfers):
        self.company = company
        self.transfers = transfers
        self.committed = False

    async def scalar(self, _query):
        return self.company

    async def execute(self, _query):
        return FakeResult(self.transfers)

    async def commit(self):
        self.committed = True


class FakeSessionFactory:
    def __init__(self, session):
        self.session = session

    def __call__(self):
        return self

    async def __aenter__(self):
        return self.session

    async def __aexit__(self, exc_type, exc, tb):
        return False


def test_engine_uses_bank_transactions_subject_by_default() -> None:
    engine = ReconciliationEngine(session_factory=FakeSessionFactory(FakeSession(None, [])), tb_client=TigerBeetleClient(), alert_hub=AlertHub())
    assert engine.subject == "bank.transactions.raw"


def test_matching_transaction_auto_confirms_pending_transfer() -> None:
    async def run() -> None:
        company_id = uuid.uuid4()
        tb_client = TigerBeetleClient()
        pending = await tb_client.create_two_phase_transfer(
            debit_account=101,
            credit_account=202,
            amount_minor=12000,
            source_document_id=uuid.uuid4(),
        )
        await tb_client.post_pending_transfer(pending.pending_id)
        pending = await tb_client.create_two_phase_transfer(
            debit_account=101,
            credit_account=202,
            amount_minor=12000,
            source_document_id=uuid.uuid4(),
        )

        transfer = SimpleNamespace(
            target_account=202,
            amount_minor=12000,
            status=TransferStatus.PENDING,
            meta={"tb_pending_id": pending.pending_id, "classification": {"contractor_nip": "1234567890"}},
        )
        session = FakeSession(company=SimpleNamespace(id=company_id), transfers=[transfer])
        engine = ReconciliationEngine(
            session_factory=FakeSessionFactory(session),
            tb_client=tb_client,
            alert_hub=AlertHub(),
        )

        matched = await engine.process_bank_transaction(
            {
                "company_id": str(company_id),
                "amount_minor": 12000,
                "contractor_nip": "1234567890",
                "transaction_id": "tx-001",
                "posted_at": datetime.now(timezone.utc).isoformat(),
            }
        )

        assert matched is True
        assert transfer.status == TransferStatus.POSTED
        assert transfer.meta["reconciliation"]["status"] == "auto-confirmed"
        assert session.committed is True

    anyio.run(run)


def test_old_unmatched_transaction_emits_missing_invoice_alert() -> None:
    async def run() -> None:
        company_id = uuid.uuid4()
        alert_hub = AlertHub()
        session = FakeSession(company=SimpleNamespace(id=company_id), transfers=[])
        engine = ReconciliationEngine(
            session_factory=FakeSessionFactory(session),
            tb_client=TigerBeetleClient(),
            alert_hub=alert_hub,
        )

        async def next_alert() -> dict:
            async for event in alert_hub.subscribe():
                return event
            raise RuntimeError("stream closed")

        waiter = anyio.ensure_backend().create_task(next_alert())
        await anyio.sleep(0)

        matched = await engine.process_bank_transaction(
            {
                "company_id": str(company_id),
                "amount_minor": 9999,
                "contractor_nip": "9999999999",
                "transaction_id": "tx-404",
                "posted_at": (datetime.now(timezone.utc) - timedelta(days=16)).isoformat(),
            }
        )

        async with anyio.fail_after(2):
            event = await waiter

        assert matched is False
        assert event["type"] == "MissingInvoiceAlert"
        assert event["transaction_id"] == "tx-404"

    anyio.run(run)


def test_clearing_engine_processes_fees_with_idempotency() -> None:
    async def run() -> None:
        tb_client = TigerBeetleClient()
        engine = ClearingAccountsEngine(
            tb_client=tb_client,
            config=ClearingAccountsConfig(
                account_bank_main=100,
                account_expense_fees=402,
                account_receivable=201,
                provider_clearing_accounts={"stripe": 139001},
            ),
        )

        first = await engine.process_provider_fees(provider_id="stripe", fee_amount=200, operation_id="fee-1")
        second = await engine.process_provider_fees(provider_id="stripe", fee_amount=200, operation_id="fee-1")

        assert first["status"] == "posted"
        assert second["status"] == "idempotent-replay"
        assert await tb_client.get_account_credits_posted(139001) == 200

    anyio.run(run)


def test_clearing_engine_reconciles_payout_with_idempotency() -> None:
    async def run() -> None:
        tb_client = TigerBeetleClient()
        engine = ClearingAccountsEngine(
            tb_client=tb_client,
            config=ClearingAccountsConfig(
                account_bank_main=131,
                account_expense_fees=402,
                account_receivable=201,
                provider_clearing_accounts={"terminal": 139002},
            ),
        )

        first = await engine.reconcile_bank_payout(provider_id="terminal", payout_amount=9800, operation_id="pay-1")
        second = await engine.reconcile_bank_payout(provider_id="terminal", payout_amount=9800, operation_id="pay-1")

        assert first["status"] == "posted"
        assert first["clearing_credits_posted"] == 9800
        assert second["status"] == "idempotent-replay"
        assert await tb_client.get_account_credits_posted(139002) == 9800

    anyio.run(run)
