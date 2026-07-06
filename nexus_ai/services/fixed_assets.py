from __future__ import annotations

from datetime import date
import uuid
from decimal import ROUND_HALF_UP, Decimal
from typing import final

import pendulum
from msgspec import Struct

from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient, _generate_tb_id

DEFAULT_ASSET_ACCOUNT = 10
DEFAULT_DEPRECIATION_ACCOUNT = 400
DEFAULT_LEDGER_ID = 2
DEFAULT_TRANSFER_CODE = 1001


class FixedAsset(Struct):
    __slots__ = ()
    id: str
    asset_name: str
    initial_value: Decimal
    residual_value: Decimal
    depreciation_rate: float
    purchase_date: pendulum.Date
    last_depreciation_date: pendulum.Date | None


@final
class FixedAssetsService:
    __slots__ = ('duckdb', 'tigerbeetle')

    def __init__(self, duckdb: DuckDBManager, tigerbeetle: TigerBeetleClient) -> None:
        self.duckdb = duckdb
        self.tigerbeetle = tigerbeetle

    def generate_schedule(self, asset_id: str) -> int:
        """Generate/refresh straight-line depreciation schedule starting next month.

        DuckDB generuje cały harmonogram w jednym SQL.
        Eliminacja: ~30 linii pętli Python.
        """
        # Zamiast while loop w Pythonie na 50 lat miesięcznie,
        # DuckDB generuje serie od 1 do 600 miesięcy i oblicza
        # raty amortyzacji w jednym SQL.
        self.duckdb.execute(
            "DELETE FROM depreciation_schedule WHERE asset_id = ? AND is_posted = FALSE",
            (asset_id,),
        )
        self.duckdb.execute(
            """
            INSERT INTO depreciation_schedule (
                asset_id, planned_date, amount, is_posted, status, ledger_id, transfer_code
            )
            SELECT
                fa.id AS asset_id,
                (date_trunc('month', fa.purchase_date)
                    + INTERVAL '1 month' * gn.n
                    + INTERVAL '1 month'
                    - INTERVAL '1 day')::DATE AS planned_date,
                LEAST(
                    ((fa.initial_value - COALESCE(fa.residual_value, 0))
                        * COALESCE(fa.annual_rate, fa.depreciation_rate) / 12),
                    (fa.initial_value - COALESCE(fa.residual_value, 0)
                        - COALESCE((SELECT SUM(amount) FROM depreciation_schedule
                                    WHERE asset_id = fa.id AND is_posted = TRUE), 0)
                    )
                ) AS amount,
                FALSE AS is_posted,
                'PENDING' AS status,
                ? AS ledger_id,
                ? AS transfer_code
            FROM fixed_assets fa
            CROSS JOIN (
                SELECT unnest(generate_series(1, 600)) AS n
            ) AS gn
            WHERE fa.id = ?
              AND fa.status = 'ACTIVE'
              AND UPPER(COALESCE(fa.depreciation_method, 'LINEAR')) = 'LINEAR'
              AND fa.initial_value > COALESCE(fa.residual_value, 0)
              AND gn.n * ((fa.initial_value - COALESCE(fa.residual_value, 0))
                    * COALESCE(fa.annual_rate, fa.depreciation_rate) / 12)
                  < (fa.initial_value - COALESCE(fa.residual_value, 0)
                    - COALESCE((SELECT SUM(amount) FROM depreciation_schedule
                                WHERE asset_id = fa.id AND is_posted = TRUE), 0)
                    )
            """,
            (DEFAULT_LEDGER_ID, DEFAULT_TRANSFER_CODE, asset_id),
        )
        # DuckDB: wykonaj SELECT change_count() dla liczby wstawionych wierszy
        count = self.duckdb.execute("SELECT changes()").fetchone()
        return count[0] if count else 0

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

        # Collect all rows first to enable batching
        rows = list(due_rows)
        if not rows:
            return 0

        # ── Batch create pending transfers (independent, NOT linked) ───
        import tigerbeetle as tb

        pending_transfers: list[tb.Transfer] = []
        pending_meta = []  # (row, asset_id, planned_date, initial_value, residual_value)
        for row in rows:
            asset_id, planned_date, amount, debit, credit, initial_value, residual_value = row
            doc_id = uuid.uuid5(uuid.NAMESPACE_DNS, f"{asset_id}:{planned_date}")
            transfer = tb.Transfer(
                id=_generate_tb_id(),
                debit_account_id=int(debit),
                credit_account_id=int(credit),
                amount=int(Decimal(str(amount)) * 100),
                pending_id=0,
                user_data_128=uuid.UUID(str(asset_id)).int,
                user_data_64=int(pendulum.instance(planned_date).format("YYYYMMDD")),
                user_data_32=0,
                timeout=0,
                ledger=DEFAULT_LEDGER_ID,
                code=DEFAULT_TRANSFER_CODE,
                flags=tb.TransferFlags.PENDING,
                timestamp=0,
            )
            pending_transfers.append(transfer)
            pending_meta.append((row, asset_id, planned_date, initial_value, residual_value))

        pending_results = await self.tigerbeetle.create_transfers_async(pending_transfers)

        # ── Batch post successful pending transfers ────────────────────
        post_transfers = []
        post_meta = []  # (asset_id, planned_date, initial_value, residual_value)
        for i, (result, transfer) in enumerate(zip(pending_results, pending_transfers, strict=True)):
            if result.status != 0:
                continue
            row, asset_id, planned_date, initial_value, residual_value = pending_meta[i]
            post_transfers.append(
                tb.Transfer(
                    id=_generate_tb_id(),
                    debit_account_id=0,
                    credit_account_id=0,
                    amount=tb.AMOUNT_MAX,
                    pending_id=transfer.id,
                    user_data_128=0,
                    user_data_64=0,
                    user_data_32=0,
                    timeout=0,
                    ledger=DEFAULT_LEDGER_ID,
                    code=DEFAULT_TRANSFER_CODE,
                    flags=tb.TransferFlags.POST_PENDING_TRANSFER,
                    timestamp=0,
                )
            )
            post_meta.append((asset_id, planned_date, initial_value, residual_value))

        if not post_transfers:
            return 0

        post_results = await self.tigerbeetle.create_transfers_async(post_transfers)

        # ── Update DuckDB for successfully posted transfers ────────────
        posted = 0
        for (_, asset_id, planned_date, initial_value, residual_value), result in zip(
            post_meta, post_results, strict=True
        ):
            if result.status != 0:
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
