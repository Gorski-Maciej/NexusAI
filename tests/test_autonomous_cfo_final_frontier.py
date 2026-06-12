from __future__ import annotations

import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))




import anyio
import uuid
from datetime import date, datetime, timezone
from types import SimpleNamespace

from unittest.mock import MagicMock

from nexus_ai.services.tigerbeetle.client import TigerBeetleClient
from nexus_ai.services.tigerbeetle.models import FinancialPeriodStatus
from nexus_ai.services.reconciliation import BankReconciliationConfig, BankReconciliationEngine, OpenInvoice
import nexus_ai.services.ledger_worker as _roboton_worker
from nexus_ai.services.ledger_worker import RobotonWorker, SimpleRuleBasedAgent


# ---------------------------------------------------------------------------
# Monkey-patch: FinancialPeriod used inside _apply_financial_period_lock
# ---------------------------------------------------------------------------
# The conftest.py mocks the entire sqlalchemy package as a _MockModule,
# which causes the real FinancialPeriod model class to inherit from a
# MagicMock (DeclarativeBase).  As a result, class-level attributes like
# company_id end up as spec='str' mocks that raise AttributeError when
# compared in expressions like FinancialPeriod.company_id == company_id.
#
# We replace FinancialPeriod in roboton_worker's module scope with a
# lightweight class whose attributes are plain MagicMock instances that
# support __eq__ / comparison chaining.
# ---------------------------------------------------------------------------
_PatchedFinancialPeriod = type("FinancialPeriod", (), {})
_PatchedFinancialPeriod.company_id = MagicMock()
_PatchedFinancialPeriod.period_id = MagicMock()
_PatchedFinancialPeriod.status = MagicMock()
_roboton_worker.FinancialPeriod = _PatchedFinancialPeriod


class FakeSession:
    """Fake AsyncSession for testing _apply_financial_period_lock.

    Since conftest.py mocks the entire sqlalchemy package as _MockModule,
    real SQLAlchemy queries are never constructed — select() returns a
    MagicMock whose str() does NOT contain SQL strings. Therefore we
    cannot parse query strings; we use a simple call counter instead.
    """

    def __init__(self, period_status: FinancialPeriodStatus, open_period_id: str = "2026-04"):
        self.period_status = period_status
        self.open_period_id = open_period_id
        self._call_count = 0

    async def scalar(self, query):
        self._call_count += 1
        if self._call_count == 1:
            # First call: look up the period by period_id
            return SimpleNamespace(period_id="2026-03", status=self.period_status)
        if self._call_count == 2:
            # Second call: find an OPEN period to shift into
            return SimpleNamespace(period_id=self.open_period_id, status=FinancialPeriodStatus.OPEN)
        return SimpleNamespace(
            id=uuid.uuid4(),
            company_policy={},
            tigerbeetle_ledger_map={"401-01": 40101, "202": 20200},
        )

    def add(self, _item):
        return None

    async def commit(self):
        return None

    async def refresh(self, _item):
        return None


def test_reconcile_bulk_payment_covers_three_invoices_and_posts_sub_10gr_rounding() -> None:
    async def run() -> None:
        tb = TigerBeetleClient()
        engine = BankReconciliationEngine(
            tb_client=tb,
            config=BankReconciliationConfig(
                account_bank_main=131,
                account_receivable=201,
                account_rounding_differences=760,
            ),
        )
        result = await engine.reconcile_bulk_payment(
            vendor_id="V-1",
            payment_amount_minor=12007,
            received_date=datetime.now(timezone.utc),
            open_invoices=[
                OpenInvoice(invoice_id="FV/1", amount_due_minor=5000, due_date=datetime(2026, 3, 1, tzinfo=timezone.utc)),
                OpenInvoice(invoice_id="FV/2", amount_due_minor=5000, due_date=datetime(2026, 3, 2, tzinfo=timezone.utc)),
                OpenInvoice(invoice_id="FV/3", amount_due_minor=2000, due_date=datetime(2026, 3, 3, tzinfo=timezone.utc)),
            ],
        )
        assert len(result["allocations"]) == 3
        assert result["rounding_adjustment_posted"] is True
        assert result["remaining_unallocated_minor"] == 0
        assert [line["invoice_id"] for line in result["allocations"]] == ["FV/1", "FV/2", "FV/3"]
        assert await tb.get_account_credits_posted(760) == 7

    anyio.run(run)


def test_period_lock_mutates_posting_and_tax_point_for_hard_closed_period() -> None:
    async def run() -> None:
        worker = RobotonWorker(session=FakeSession(FinancialPeriodStatus.HARD_CLOSED), tb_client=TigerBeetleClient(), agent=SimpleRuleBasedAgent())
        event = {
            "company_id": uuid.uuid4().hex,
            "date_of_issue": "2026-03-17",
            "tax_point_date": "2026-03-17",
            "amount_minor": 1000,
            "source_document_id": uuid.uuid4().hex,
        }
        mutated = await worker._apply_financial_period_lock(uuid.UUID(event["company_id"]), event)
        assert mutated["posting_date"] == "2026-04-01"
        assert mutated["tax_point_date"] == "2026-04-01"
        assert mutated["metadata"]["late_submission_shifted"] is True

    anyio.run(run)


def test_period_lock_keeps_dates_for_open_period() -> None:
    async def run() -> None:
        worker = RobotonWorker(session=FakeSession(FinancialPeriodStatus.OPEN), tb_client=TigerBeetleClient(), agent=SimpleRuleBasedAgent())
        event = {
            "company_id": uuid.uuid4().hex,
            "date_of_issue": "2026-03-17",
            "tax_point_date": "2026-03-17",
            "amount_minor": 1000,
            "source_document_id": uuid.uuid4().hex,
        }
        mutated = await worker._apply_financial_period_lock(uuid.UUID(event["company_id"]), event)
        assert mutated["posting_date"] == "2026-03-17"
        assert mutated["tax_point_date"] == "2026-03-17"
        assert "metadata" not in mutated or "late_submission_shifted" not in mutated.get("metadata", {})

    anyio.run(run)
