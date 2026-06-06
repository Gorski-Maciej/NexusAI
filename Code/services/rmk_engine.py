from __future__ import annotations

import calendar
import uuid
from dataclasses import dataclass
from datetime import date
from decimal import ROUND_HALF_UP, Decimal

from db.analytics import DuckDBManager

RMK_ASSET_ACCOUNT_ID = "640"
RMK_LEDGER_ID = 1
RMK_TRANSFER_CODE = 2001


@dataclass(slots=True)
class RMKInvoiceData:
    invoice_id: str
    description: str
    total_net_amount: Decimal
    start_date: date
    end_date: date
    cost_account_id: str


def _month_end(year: int, month: int) -> date:
    return date(year, month, calendar.monthrange(year, month)[1])


def _first_of_next_month(input_date: date) -> date:
    if input_date.month == 12:
        return date(input_date.year + 1, 1, 1)
    return date(input_date.year, input_date.month + 1, 1)


class RMKEngine:
    """Accruals & Deferrals generator (RMK) with day-level pro-rata precision."""

    def __init__(self, duckdb: DuckDBManager) -> None:
        self.duckdb = duckdb

    def create_rmk_schedule(self, invoice_data: RMKInvoiceData) -> str:
        if invoice_data.end_date < invoice_data.start_date:
            raise ValueError("end_date must be >= start_date")

        deferred_id = str(uuid.uuid4())
        total_days = (invoice_data.end_date - invoice_data.start_date).days + 1
        daily_rate = (invoice_data.total_net_amount / Decimal(total_days)).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)

        self.duckdb.execute(
            """
            INSERT INTO deferred_expenses (
                id, invoice_id, description, total_net_amount, start_date, end_date,
                total_days, daily_rate, status, cost_account_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', ?)
            """,
            (
                deferred_id,
                invoice_data.invoice_id,
                invoice_data.description,
                float(invoice_data.total_net_amount),
                invoice_data.start_date,
                invoice_data.end_date,
                total_days,
                float(daily_rate),
                invoice_data.cost_account_id,
            ),
        )

        month_cursor = date(invoice_data.start_date.year, invoice_data.start_date.month, 1)
        last_month_start = date(invoice_data.end_date.year, invoice_data.end_date.month, 1)
        allocations: list[tuple[date, Decimal]] = []

        while month_cursor <= last_month_start:
            month_start = month_cursor
            month_finish = _month_end(month_start.year, month_start.month)
            period_start = max(invoice_data.start_date, month_start)
            period_end = min(invoice_data.end_date, month_finish)

            covered_days = (period_end - period_start).days + 1
            month_amount = (daily_rate * Decimal(covered_days)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
            allocations.append((month_finish, month_amount))
            month_cursor = _first_of_next_month(month_cursor)

        booked = sum((amount for _, amount in allocations), Decimal("0.00"))
        diff = invoice_data.total_net_amount - booked
        if allocations and diff != Decimal("0.00"):
            post_date, amount = allocations[-1]
            allocations[-1] = (post_date, (amount + diff).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))

        for posting_date, amount in allocations:
            self.duckdb.execute(
                """
                INSERT INTO rmk_ledger_entries (
                    id, deferred_id, posting_date, amount, is_posted,
                    ledger_id, transfer_code, rmk_asset_account_id, user_data_128
                ) VALUES (?, ?, ?, ?, FALSE, ?, ?, ?, ?)
                """,
                (
                    str(uuid.uuid4()),
                    deferred_id,
                    posting_date,
                    float(amount),
                    RMK_LEDGER_ID,
                    RMK_TRANSFER_CODE,
                    RMK_ASSET_ACCOUNT_ID,
                    deferred_id,
                ),
            )

        return deferred_id
