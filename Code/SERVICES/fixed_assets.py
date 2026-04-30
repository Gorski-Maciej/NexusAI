from __future__ import annotations

import calendar
import uuid
from dataclasses import dataclass
from datetime import date
from decimal import Decimal, ROUND_HALF_UP

from db.analytics import DuckDBManager
from Roboton_Reflekton.ledger_client import TigerBeetleClient


DEFAULT_ASSET_ACCOUNT = 10
DEFAULT_DEPRECIATION_ACCOUNT = 400
DEFAULT_LEDGER_ID = 2
DEFAULT_TRANSFER_CODE = 1001


@dataclass(slots=True)
class FixedAsset:
    id: str
    asset_name: str
    initial_value: Decimal
    depreciation_rate: float
    purchase_date: date


def _month_end(year: int, month: int) -> date:
    return date(year, month, calendar.monthrange(year, month)[1])


def _first_of_next_month(input_date: date) -> date:
    if input_date.month == 12:
        return date(input_date.year + 1, 1, 1)
    return date(input_date.year, input_date.month + 1, 1)


class FixedAssetsService:
    def __init__(self, duckdb: DuckDBManager, tigerbeetle: TigerBeetleClient) -> None:
        self.duckdb = duckdb
        self.tigerbeetle = tigerbeetle

    def generate_schedule(self, asset_id: str) -> int:
        """Generate/refresh straight-line depreciation schedule with pro-rata first month."""
        row = self.duckdb.execute(
            """
            SELECT id, asset_name, initial_value, depreciation_rate, purchase_date,
                   account_id_debit, account_id_credit
            FROM fixed_assets
            WHERE id = ? AND status = 'ACTIVE'
            """,
            (asset_id,),
        )
        if not row:
            return 0

        asset = row[0]
        initial_value = Decimal(str(asset[2])).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        rate = Decimal(str(asset[3]))
        purchase_date = asset[4]
        annual_amount = (initial_value * rate).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        monthly_amount = (annual_amount / Decimal("12")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

        self.duckdb.execute("DELETE FROM depreciation_schedule WHERE asset_id = ? AND is_posted = FALSE", (asset_id,))

        schedule_rows: list[tuple] = []
        month_cursor = purchase_date
        remaining = initial_value

        days_in_month = calendar.monthrange(purchase_date.year, purchase_date.month)[1]
        days_remaining = days_in_month - purchase_date.day + 1
        first_amount = (monthly_amount * Decimal(days_remaining) / Decimal(days_in_month)).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
        if first_amount > remaining:
            first_amount = remaining

        schedule_rows.append((asset_id, _month_end(month_cursor.year, month_cursor.month), float(first_amount), False, DEFAULT_LEDGER_ID, DEFAULT_TRANSFER_CODE))
        remaining -= first_amount
        month_cursor = _first_of_next_month(month_cursor)

        while remaining > Decimal("0.00"):
            installment = monthly_amount if monthly_amount <= remaining else remaining
            schedule_rows.append((asset_id, _month_end(month_cursor.year, month_cursor.month), float(installment), False, DEFAULT_LEDGER_ID, DEFAULT_TRANSFER_CODE))
            remaining -= installment
            month_cursor = _first_of_next_month(month_cursor)

        for row_values in schedule_rows:
            self.duckdb.execute(
                """
                INSERT INTO depreciation_schedule (asset_id, planned_date, amount, is_posted, ledger_id, transfer_code)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                row_values,
            )
        return len(schedule_rows)

    async def execute_monthly_depreciation(self, as_of: date | None = None) -> int:
        today = as_of or date.today()
        due_rows = self.duckdb.execute(
            """
            SELECT ds.asset_id, ds.planned_date, ds.amount, fa.account_id_debit, fa.account_id_credit
            FROM depreciation_schedule ds
            JOIN fixed_assets fa ON ds.asset_id = fa.id
            WHERE ds.planned_date <= ?
              AND ds.is_posted = FALSE
              AND fa.status = 'ACTIVE'
            ORDER BY ds.planned_date ASC
            """,
            (today,),
        )

        posted = 0
        for asset_id, planned_date, amount, debit, credit in due_rows:
            transfer = await self.tigerbeetle.create_two_phase_transfer(
                debit_account=int(debit),
                credit_account=int(credit),
                amount_minor=int(Decimal(str(amount)) * 100),
                source_document_id=uuid.uuid5(uuid.NAMESPACE_DNS, f"{asset_id}:{planned_date}"),
            )
            ok = await self.tigerbeetle.post_pending_transfer(transfer.pending_id)
            if not ok:
                continue

            self.duckdb.execute(
                "UPDATE depreciation_schedule SET is_posted = TRUE, posted_at = now() WHERE asset_id = ? AND planned_date = ?",
                (asset_id, planned_date),
            )
            self.duckdb.execute(
                """
                UPDATE fixed_assets
                SET status = CASE
                    WHEN (
                        SELECT COALESCE(SUM(amount), 0) FROM depreciation_schedule
                        WHERE asset_id = ? AND is_posted = TRUE
                    ) >= initial_value THEN 'FULLY_DEPRECIATED'
                    ELSE status
                END
                WHERE id = ?
                """,
                (asset_id, asset_id),
            )
            posted += 1
        return posted
