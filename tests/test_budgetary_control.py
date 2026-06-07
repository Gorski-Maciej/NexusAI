from pathlib import Path
import sys
import asyncio
from datetime import date

sys.path.append(str(Path(__file__).resolve().parents[1]))

from nexus_ai.roboton_reflekton.budgetary_control import BudgetaryControlEngine
from nexus_ai.roboton_reflekton.ledger_client import TigerBeetleClient


class FakeDuckDBManager:
    def __init__(self, rows):
        self.rows = rows

    def execute(self, query, parameters=None):
        if "SELECT limit_amount" in query:
            account_code, period = parameters
            return self.rows.get((account_code, period), [])
        return []


def test_get_budget_status_warn_and_critical() -> None:
    async def run() -> None:
        period = date(2026, 4, 1)
        db = FakeDuckDBManager({("402", period): [(1000.0, 0.85)]})
        tb = TigerBeetleClient()
        tb._account_credits_posted[402001] = 80000

        engine = BudgetaryControlEngine(db, tb, {"402": 402001})

        warn_status = await engine.get_budget_status("402", 100.0, month_period=period)
        assert warn_status.status == "WARN"
        assert round(warn_status.projected_usage_percent, 1) == 90.0

        critical_status = await engine.get_budget_status("402", 250.0, month_period=period)
        assert critical_status.status == "CRITICAL"
        assert round(critical_status.projected_usage_percent, 1) == 105.0

    asyncio.run(run())


def test_get_budget_status_ok_without_definition() -> None:
    async def run() -> None:
        db = FakeDuckDBManager({})
        tb = TigerBeetleClient()
        engine = BudgetaryControlEngine(db, tb, {"401": 401001})

        status = await engine.get_budget_status("401", 50.0, month_period=date(2026, 4, 1))
        assert status.status == "OK"
        assert "No budget configured" in status.message

    asyncio.run(run())
