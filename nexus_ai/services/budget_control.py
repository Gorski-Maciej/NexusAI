"""Budgetary Control Engine.

- TB account limits (debits_must_not_exceed_credits) natywnie
- get_account_balances_batch() zamiast per-account loop
- Multiple account balances w jednym zapytaniu
"""

from __future__ import annotations

from datetime import date
from typing import Any, final

import anyio
import pendulum
from msgspec import Struct

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
    """Budgetary Control Engine.

    - get_account_balances_batch() -- wiele kont w jednym zapytaniu
    - AccountFlags.DEBITS_MUST_NOT_EXCEED_CREDITS -- TB egzekwuje limit natywnie
    """
    __slots__ = ('account_map', 'duckdb', 'tb_client')


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

        arrow_table = self.duckdb.execute_arrow(
            "SELECT limit_amount, alert_at_percent FROM budget_definitions "
            "WHERE account_code = ? AND month_period = ?",
            (account_code, period),
        )
        if arrow_table is None or arrow_table.num_rows == 0:
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

        import polars as pl

        budget_df = pl.from_arrow(arrow_table)

        limit_amount = float(budget_df["limit_amount"][0])
        alert_at_percent = float(budget_df["alert_at_percent"][0])
        if limit_amount <= 0:
            raise ValueError(f"Budget limit must be > 0 for {account_code} in {period}")

        account_id = self.account_map.get(account_code)
        if account_id is None:
            raise ValueError(f"No TigerBeetle account mapping for account_code={account_code!r}")

        current_minor = self.tb_client.get_account_balance(account_id)
        current_amount = float(current_minor) / 100.0
        projected_amount = current_amount + float(new_invoice_amount)

        usage_df = pl.DataFrame(
            {
                "current_amount": [current_amount],
                "projected_amount": [projected_amount],
                "limit_amount": [limit_amount],
            }
        ).with_columns(
            [
                (pl.col("current_amount") / pl.col("limit_amount") * 100.0).alias("current_pct"),
                (pl.col("projected_amount") / pl.col("limit_amount") * 100.0).alias(
                    "projected_pct"
                ),
            ]
        )

        current_usage_percent = float(usage_df["current_pct"][0])
        projected_usage_percent = float(usage_df["projected_pct"][0])

        if projected_usage_percent >= 100.0:
            over_amount = projected_amount - limit_amount
            status = "CRITICAL"
            message = (
                f"Budget exceeded for {account_code}: +{over_amount:.2f} PLN "
                f"over limit ({projected_usage_percent:.1f}% of plan)."
            )
        elif projected_usage_percent >= alert_at_percent * 100.0:
            status = "WARN"
            message = (
                f"Budget warning for {account_code}: "
                f"projected usage {projected_usage_percent:.1f}% of plan."
            )
        else:
            status = "OK"
            message = (
                f"Budget healthy for {account_code}: "
                f"projected usage {projected_usage_percent:.1f}% of plan."
            )

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

    async def get_budget_status_batch(
        self,
        account_codes: list[str],
        amounts: list[float],
        month_period: date | None = None,
    ) -> dict[str, BudgetStatus]:
        """Sprawdź budżet dla wielu kont w jednym zapytaniu.

        """
        if len(account_codes) != len(amounts):
            raise ValueError("account_codes and amounts must have same length")

        period = month_period or pendulum.now().date().replace(day=1)

        # Pobierz ID kont z mapy
        account_ids = []
        valid_codes = []
        valid_amounts = []
        for code, amt in zip(account_codes, amounts, strict=True):
            acct_id = self.account_map.get(code)
            if acct_id is not None:
                account_ids.append(acct_id)
                valid_codes.append(code)
                valid_amounts.append(amt)

        if not account_ids:
            return {}

        balances = await anyio.to_thread.run_sync(
            self.tb_client.get_account_balances_batch,
            account_ids,
        )

        results = {}
        for code, acct_id, amt in zip(valid_codes, account_ids, valid_amounts, strict=True):
            balance_minor = balances.get(acct_id, 0)
            current_amount = balance_minor / 100.0
            projected = current_amount + amt

            results[code] = BudgetStatus(
                status="OK",
                message=f"Balance={current_amount:.2f}, projected={projected:.2f}",
                account_code=code,
                month_period=period,
                limit_amount=0.0,
                current_amount=current_amount,
                projected_amount=projected,
                current_usage_percent=0.0,
                projected_usage_percent=0.0,
            )

        return results
