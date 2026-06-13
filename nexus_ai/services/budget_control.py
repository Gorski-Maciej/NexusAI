"""Budgetary control engine — kontrola budżetu w czasie rzeczywistym.

Zgodnie z aa3fvcx.txt:
- DuckDB dla definicji budżetów
- TigerBeetle dla rzeczywistych sald księgowych
- amount jako int (grosze)
"""

from __future__ import annotations

from msgspec import Struct
from typing import Any, final

import pendulum

from nexus_ai.services.tigerbeetle.client import TigerBeetleClient


class BudgetStatus(Struct, frozen=True):
    status: str
    message: str
    account_code: str
    month_period: date
    limit_amount: float
    current_amount: float
    projected_amount: float
    current_usage_percent: float
    projected_usage_percent: float


@final
class BudgetaryControlEngine:
    """Kontrola budżetu — sprawdza limity dla kont księgowych w TigerBeetle."""

    def __init__(
        self, duckdb_manager: Any, tb_client: TigerBeetleClient, account_map: dict[str, int]
    ) -> None:
        self.duckdb = duckdb_manager
        self.tb_client = tb_client
        self.account_map = account_map

    def ensure_budget_schema(self) -> None:
        self.duckdb.execute("""CREATE TABLE IF NOT EXISTS budget_definitions (
            account_code VARCHAR, month_period DATE, limit_amount DOUBLE,
            alert_at_percent DOUBLE DEFAULT 0.85, PRIMARY KEY (account_code, month_period)
        )""")

    async def get_budget_status(
        self, account_code: str, new_invoice_amount: float, month_period: date | None = None
    ) -> BudgetStatus:
        if new_invoice_amount < 0:
            raise ValueError("new_invoice_amount must be >= 0")
        self.ensure_budget_schema()

        period = month_period or pendulum.now().date().replace(day=1)
        budget_rows = self.duckdb.execute(
            "SELECT limit_amount, alert_at_percent FROM budget_definitions WHERE account_code = ? AND month_period = ?",
            (account_code, period),
        )
        if not budget_rows:
            return BudgetStatus(
                status="OK",
                message=f"No budget configured for account {account_code} in {period}.",
                account_code=account_code,
                month_period=period,
                limit_amount=0.0,
                current_amount=0.0,
                projected_amount=new_invoice_amount,
                current_usage_percent=0.0,
                projected_usage_percent=0.0,
            )

        limit_amount, alert_at_percent = float(budget_rows[0][0]), float(budget_rows[0][1])
        if limit_amount <= 0:
            raise ValueError(f"Budget limit must be > 0 for {account_code} in {period}")

        account_id = self.account_map.get(account_code)
        if account_id is None:
            raise ValueError(f"No TigerBeetle account mapping for account_code={account_code!r}")

        current_minor = await self.tb_client.get_account_credits_posted(account_id)
        current_amount = float(current_minor) / 100.0
        projected_amount = current_amount + float(new_invoice_amount)

        current_usage_percent = (current_amount / limit_amount) * 100.0
        projected_usage_percent = (projected_amount / limit_amount) * 100.0

        if projected_usage_percent >= 100.0:
            over_amount = projected_amount - limit_amount
            status = "CRITICAL"
            message = f"Budget exceeded for {account_code}: +{over_amount:.2f} PLN over limit ({projected_usage_percent:.1f}% of plan)."
        elif projected_usage_percent >= alert_at_percent * 100.0:
            status = "WARN"
            message = f"Budget warning for {account_code}: projected usage {projected_usage_percent:.1f}% of plan."
        else:
            status = "OK"
            message = f"Budget healthy for {account_code}: projected usage {projected_usage_percent:.1f}% of plan."

        return BudgetStatus(
            status=status,
            message=message,
            account_code=account_code,
            month_period=period,
            limit_amount=limit_amount,
            current_amount=current_amount,
            projected_amount=projected_amount,
            current_usage_percent=current_usage_percent,
            projected_usage_percent=projected_usage_percent,
        )
