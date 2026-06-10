from __future__ import annotations

import uuid
from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal

import pendulum

from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

DEFAULT_ASSET_ACCOUNT = 10
DEFAULT_DEPRECIATION_ACCOUNT = 400
DEFAULT_LEDGER_ID = 2
DEFAULT_TRANSFER_CODE = 1001


@dataclass(slots=True)
class FixedAsset:
    id: str
    asset_name: str
    initial_value: Decimal
    residual_value: Decimal
    depreciation_rate: float
    purchase_date: pendulum.Date
    last_depreciation_date: pendulum.Date | None


class FixedAssetsService:
    def __init__(self, duckdb: DuckDBManager, tigerbeetle: TigerBeetleClient) -> None:
        self.duckdb = duckdb
        self.tigerbeetle = tigerbeetle

    def generate_schedule(self, asset_id: str) -> int:
        """Generate/refresh straight-line depreciation schedule starting next month."""
        row = self.duckdb.execute(
            """
            SELECT id, asset_name, initial_value, COALESCE(salvage_value, residual_value, 0), depreciation_method,
                   COALESCE(annual_rate, depreciation_rate), COALESCE(start_date, purchase_date), last_depreciation_date,
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
        residual_value = Decimal(str(asset[3])).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        depreciation_method = str(asset[4] or "LINEAR").upper()
        rate = Decimal(str(asset[5]))
        purchase_date = asset[6]
        if depreciation_method != "LINEAR":
            return 0
        if initial_value <= residual_value:
            return 0
        annual_amount = ((initial_value - residual_value) * rate).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        monthly_amount = (annual_amount / Decimal("12")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        if monthly_amount <= Decimal("0.00"):
            return 0

        self.duckdb.execute("DELETE FROM depreciation_schedule WHERE asset_id = ? AND is_posted = FALSE", (asset_id,))

        schedule_rows: list[tuple] = []
        month_cursor = pendulum.Date(purchase_date.year, purchase_date.month, 1).add(months=1)
        posted_sum_rows = self.duckdb.execute(
            "SELECT COALESCE(SUM(amount), 0) FROM depreciation_schedule WHERE asset_id = ? AND is_posted = TRUE",
            (asset_id,),
        )
        posted_sum = Decimal(str(posted_sum_rows[0][0])).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        remaining = (initial_value - residual_value - posted_sum).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        if remaining <= Decimal("0.00"):
            return 0

        while remaining > Decimal("0.00"):
            installment = monthly_amount if monthly_amount <= remaining else remaining
            installment = installment.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
            schedule_rows.append((asset_id, month_cursor.end_of("month"), float(installment), False, "PENDING", DEFAULT_LEDGER_ID, DEFAULT_TRANSFER_CODE))
            remaining = (remaining - installment).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
            month_cursor = month_cursor.add(months=1)

        for row_values in schedule_rows:
            self.duckdb.execute(
                """
                INSERT INTO depreciation_schedule (asset_id, planned_date, amount, is_posted, status, ledger_id, transfer_code)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                row_values,
            )
        return len(schedule_rows)

    async def execute_monthly_depreciation(self, as_of: date | None = None) -> int:
        today = as_of or pendulum.now().date()
        due_rows = self.duckdb.execute(
            """
            SELECT ds.asset_id, ds.planned_date, ds.amount, fa.account_id_debit, fa.account_id_credit, fa.initial_value, COALESCE(fa.salvage_value, fa.residual_value)
            FROM depreciation_schedule ds
            JOIN fixed_assets fa ON ds.asset_id = fa.id
            WHERE ds.planned_date <= ?
              AND ds.is_posted = FALSE
              AND ds.status = 'PENDING'
              AND fa.status = 'ACTIVE'
            ORDER BY ds.planned_date ASC
            """,
            (today,),
        )

        posted = 0
        for asset_id, planned_date, amount, debit, credit, initial_value, residual_value in due_rows:
            transfer = await self.tigerbeetle.create_two_phase_transfer(
                debit_account=int(debit),
                credit_account=int(credit),
                amount_minor=int(Decimal(str(amount)) * 100),
                source_document_id=uuid.uuid5(uuid.NAMESPACE_DNS, f"{asset_id}:{planned_date}"),
                user_data_128=uuid.UUID(str(asset_id)).int,
            )
            ok = await self.tigerbeetle.post_pending_transfer(transfer.pending_id)
            if not ok:
                continue

            self.duckdb.execute(
                "UPDATE depreciation_schedule SET is_posted = TRUE, status = 'POSTED', posted_at = now() WHERE asset_id = ? AND planned_date = ?",
                (asset_id, planned_date),
            )
            self.duckdb.execute(
                "UPDATE fixed_assets SET last_depreciation_date = ? WHERE id = ?",
                (planned_date, asset_id),
            )
            target_total = (Decimal(str(initial_value)) - Decimal(str(residual_value))).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            )
            self.duckdb.execute(
                """
                UPDATE fixed_assets
                SET status = CASE
                    WHEN (
                        SELECT COALESCE(SUM(amount), 0) FROM depreciation_schedule
                        WHERE asset_id = ? AND is_posted = TRUE
                    ) >= ? THEN 'FULLY_DEPRECIATED'
                    ELSE status
                END
                WHERE id = ?
                """,
                (asset_id, float(target_total), asset_id),
            )
            posted += 1
        return posted
