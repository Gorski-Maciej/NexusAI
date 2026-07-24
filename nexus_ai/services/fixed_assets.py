from __future__ import annotations

from datetime import date
import uuid
from decimal import ROUND_HALF_UP, Decimal
from enum import StrEnum
from typing import final

import pendulum
from msgspec import Struct

from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient, _generate_tb_id

DEFAULT_ASSET_ACCOUNT = 10
DEFAULT_DEPRECIATION_ACCOUNT = 400
DEFAULT_LEDGER_ID = 2
DEFAULT_TRANSFER_CODE = 1001


class DepreciationMethod(StrEnum):
    """v7.0 AUDIT: Rozszerzone metody amortyzacji (Raport 4.1)."""
    LINEAR = "linear"
    DEGRESSIVE = "degressive"  # Metoda malejącego salda (v7.0 NOWOŚĆ)
    MIDM = "midm"  # Metoda indywidualna dla używanych środków (v7.0 NOWOŚĆ)
    ONE_TIME = "one_time"  # Jednorazowa (do 100k EUR dla małych podatników)


class FixedAsset(Struct):
    __slots__ = ()
    id: str
    asset_name: str
    initial_value: Decimal
    residual_value: Decimal
    depreciation_rate: float
    depreciation_method: str = "LINEAR"  # v7.0: LINEAR, DEGRESSIVE, MIDM, ONE_TIME
    annual_rate: float = 0.0  # v7.0: roczna stawka amortyzacji
    degressive_coefficient: float = 2.0  # v7.0: współczynnik dla metody degresywnej
    purchase_date: pendulum.Date
    last_depreciation_date: pendulum.Date | None
    status: str = "ACTIVE"  # ACTIVE, FULLY_DEPRECIATED, DISPOSED, UPGRADED
    upgrade_value: Decimal = Decimal("0")  # v7.0: wartość ulepszeń
    upgrade_date: pendulum.Date | None = None  # v7.0: data ulepszenia
    disposal_date: pendulum.Date | None = None  # v7.0: data likwidacji
    disposal_value: Decimal = Decimal("0")  # v7.0: wartość likwidacyjna


@final
class FixedAssetsService:
    __slots__ = ('duckdb', 'tigerbeetle')

    def __init__(self, duckdb: DuckDBManager, tigerbeetle: TigerBeetleClient) -> None:
        self.duckdb = duckdb
        self.tigerbeetle = tigerbeetle

    def generate_schedule(self, asset_id: str) -> int:
        """Generate/refresh depreciation schedule.

        v7.0 AUDIT: Obsługa LINEAR, DEGRESSIVE, MIDM (Raport 4.1).
        """
        # Sprawdź metodę amortyzacji
        asset_row = self.duckdb.execute(
            "SELECT depreciation_method, initial_value, residual_value, annual_rate, "
            "degressive_coefficient, upgrade_value, status "
            "FROM fixed_assets WHERE id = ?",
            (asset_id,),
        )
        if not asset_row:
            return 0

        method = str(asset_row[0][0] if asset_row else "LINEAR").upper()
        initial = Decimal(str(asset_row[0][1] if asset_row else 0))
        residual = Decimal(str(asset_row[0][2] if asset_row else 0))
        annual_rate = float(asset_row[0][3] if asset_row else 0) or 0.20
        coefficient = float(asset_row[0][4] if asset_row else 2) or 2.0
        upgrade = Decimal(str(asset_row[0][5] if asset_row else 0))
        asset_status = str(asset_row[0][6] if asset_row else "ACTIVE")

        if asset_status not in ("ACTIVE", "UPGRADED"):
            return 0

        base_value = initial + upgrade - residual

        self.duckdb.execute(
            "DELETE FROM depreciation_schedule WHERE asset_id = ? AND is_posted = FALSE",
            (asset_id,),
        )

        if method == "LINEAR":
            return self._generate_linear_schedule(asset_id, base_value, annual_rate, residual)
        elif method == "DEGRESSIVE":
            return self._generate_degressive_schedule(asset_id, base_value, annual_rate, coefficient, residual)
        elif method == "MIDM":
            return self._generate_midm_schedule(asset_id, base_value, annual_rate, residual)
        elif method == "ONE_TIME":
            return self._generate_one_time_schedule(asset_id, base_value, residual)
        else:
            return self._generate_linear_schedule(asset_id, base_value, annual_rate, residual)

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

    # ── v7.0 AUDIT: Metody amortyzacji (Raport 4.1) ────────────────────

    def _generate_linear_schedule(
        self, asset_id: str, base_value: Decimal, annual_rate: float, residual: Decimal
    ) -> int:
        """Generuj harmonogram amortyzacji liniowej."""
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
                    (CAST(? AS DECIMAL) * CAST(? AS DECIMAL) / 12),
                    (CAST(? AS DECIMAL)
                        - COALESCE((SELECT SUM(amount) FROM depreciation_schedule
                                    WHERE asset_id = fa.id AND is_posted = TRUE), 0))
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
              AND fa.status IN ('ACTIVE', 'UPGRADED')
              AND CAST(? AS DECIMAL) > 0
              AND gn.n * (CAST(? AS DECIMAL) * CAST(? AS DECIMAL) / 12)
                  < (CAST(? AS DECIMAL)
                    - COALESCE((SELECT SUM(amount) FROM depreciation_schedule
                                WHERE asset_id = fa.id AND is_posted = TRUE), 0))
            """,
            (
                float(base_value), annual_rate,
                float(base_value),
                DEFAULT_LEDGER_ID, DEFAULT_TRANSFER_CODE, asset_id,
                float(base_value), float(base_value), annual_rate, float(base_value),
            ),
        )
        count = self.duckdb.execute("SELECT changes()").fetchone()
        return count[0] if count else 0

    def _generate_degressive_schedule(
        self, asset_id: str, base_value: Decimal, annual_rate: float,
        coefficient: float, residual: Decimal,
    ) -> int:
        """v7.0: Generuj harmonogram amortyzacji degresywnej (malejące saldo).

        Metoda degresywna: stawka = annual_rate * coefficient (max 2.0).
        Stosowana do wartości netto (wartość początkowa - dotychczasowe umorzenie).
        W momencie gdy rata degresywna < rata liniowa, przechodzimy na liniową.
        """
        degressive_rate = annual_rate * min(coefficient, 2.0)
        linear_monthly = float(base_value) * annual_rate / 12

        self.duckdb.execute(
            """
            INSERT INTO depreciation_schedule (
                asset_id, planned_date, amount, is_posted, status, ledger_id, transfer_code
            )
            SELECT
                ? AS asset_id,
                (date_trunc('month', fa.purchase_date)
                    + INTERVAL '1 month' * gn.n
                    + INTERVAL '1 month'
                    - INTERVAL '1 day')::DATE AS planned_date,
                GREATEST(
                    LEAST(
                        (CAST(? AS DECIMAL)
                            - COALESCE((SELECT SUM(amount) FROM depreciation_schedule
                                        WHERE asset_id = fa.id AND is_posted = TRUE), 0))
                        * CAST(? AS DECIMAL) / 12,
                        CAST(? AS DECIMAL)
                            - COALESCE((SELECT SUM(amount) FROM depreciation_schedule
                                        WHERE asset_id = fa.id AND is_posted = TRUE), 0)
                    ),
                    CAST(? AS DECIMAL)
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
              AND fa.status IN ('ACTIVE', 'UPGRADED')
              AND CAST(? AS DECIMAL) > 0
              AND (CAST(? AS DECIMAL)
                    - COALESCE((SELECT SUM(amount) FROM depreciation_schedule
                                WHERE asset_id = fa.id AND is_posted = TRUE), 0)) > 0
            """,
            (
                asset_id,
                float(base_value), degressive_rate,
                float(base_value),
                linear_monthly,
                DEFAULT_LEDGER_ID, DEFAULT_TRANSFER_CODE, asset_id,
                float(base_value),
                float(base_value),
            ),
        )
        count = self.duckdb.execute("SELECT changes()").fetchone()
        logger.info("[FIXED-ASSETS] Degressive schedule: %d months (rate=%.2f%%, coeff=%.1f)",
                     count[0] if count else 0, degressive_rate * 100, coefficient)
        return count[0] if count else 0

    def _generate_midm_schedule(
        self, asset_id: str, base_value: Decimal,
        annual_rate: float, residual: Decimal,
    ) -> int:
        """v7.0: Generuj harmonogram MIDM (metoda indywidualna).

        Dla używanych środków trwałych — stawka ustalana indywidualnie,
        okres amortyzacji minimum 24 miesiące.
        """
        effective_rate = annual_rate if annual_rate > 0 else 0.20
        min_months = 24

        self.duckdb.execute(
            """
            INSERT INTO depreciation_schedule (
                asset_id, planned_date, amount, is_posted, status, ledger_id, transfer_code
            )
            SELECT
                ? AS asset_id,
                (date_trunc('month', fa.purchase_date)
                    + INTERVAL '1 month' * gn.n
                    + INTERVAL '1 month'
                    - INTERVAL '1 day')::DATE AS planned_date,
                LEAST(
                    CAST(? AS DECIMAL) * CAST(? AS DECIMAL) / 12,
                    CAST(? AS DECIMAL)
                        - COALESCE((SELECT SUM(amount) FROM depreciation_schedule
                                    WHERE asset_id = fa.id AND is_posted = TRUE), 0)
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
              AND fa.status IN ('ACTIVE', 'UPGRADED')
              AND CAST(? AS DECIMAL) > 0
              AND gn.n <= GREATEST(CAST(? AS DECIMAL) * 12, ?)
              AND (CAST(? AS DECIMAL)
                    - COALESCE((SELECT SUM(amount) FROM depreciation_schedule
                                WHERE asset_id = fa.id AND is_posted = TRUE), 0)) > 0
            """,
            (
                asset_id,
                float(base_value), effective_rate, float(base_value),
                DEFAULT_LEDGER_ID, DEFAULT_TRANSFER_CODE, asset_id,
                float(base_value),
                1.0 / max(effective_rate, 0.01), min_months,
                float(base_value),
            ),
        )
        count = self.duckdb.execute("SELECT changes()").fetchone()
        logger.info("[FIXED-ASSETS] MIDM schedule: %d months (rate=%.2f%%)",
                     count[0] if count else 0, effective_rate * 100)
        return count[0] if count else 0

    def _generate_one_time_schedule(
        self, asset_id: str, base_value: Decimal, residual: Decimal,
    ) -> int:
        """v7.0: Jednorazowa amortyzacja (do 100k EUR dla małych podatników)."""
        self.duckdb.execute(
            """
            INSERT INTO depreciation_schedule (
                asset_id, planned_date, amount, is_posted, status, ledger_id, transfer_code
            )
            SELECT
                ? AS asset_id,
                (date_trunc('month', fa.purchase_date)
                    + INTERVAL '1 month'
                    - INTERVAL '1 day')::DATE AS planned_date,
                CAST(? AS DECIMAL) AS amount,
                FALSE AS is_posted,
                'PENDING' AS status,
                ? AS ledger_id,
                ? AS transfer_code
            FROM fixed_assets fa
            WHERE fa.id = ?
              AND fa.status = 'ACTIVE'
              AND CAST(? AS DECIMAL) > 0
            """,
            (
                asset_id, float(base_value),
                DEFAULT_LEDGER_ID, DEFAULT_TRANSFER_CODE, asset_id,
                float(base_value),
            ),
        )
        count = self.duckdb.execute("SELECT changes()").fetchone()
        logger.info("[FIXED-ASSETS] One-time schedule: %d entries", count[0] if count else 0)
        return count[0] if count else 0

    # ── v7.0 AUDIT: Ulepszenia i likwidacja (Raport 4.1) ──────────────

    def upgrade_asset(
        self, asset_id: str, upgrade_value: Decimal, upgrade_date: date | None = None,
    ) -> None:
        """v7.0: Zwiększ wartość początkową środka trwałego (ulepszenie).

        Args:
            asset_id: ID środka trwałego.
            upgrade_value: Wartość ulepszenia.
            upgrade_date: Data ulepszenia (domyślnie dzisiaj).
        """
        today = upgrade_date or pendulum.now().date()

        self.duckdb.execute(
            """UPDATE fixed_assets
               SET upgrade_value = upgrade_value + ?,
                   upgrade_date = ?,
                   status = 'UPGRADED'
               WHERE id = ?""",
            (float(upgrade_value), today, asset_id),
        )

        # Regeneruj harmonogram z nową wartością
        self.generate_schedule(asset_id)

        logger.info(
            "[FIXED-ASSETS] Asset %s upgraded: +%.2f PLN on %s",
            asset_id, upgrade_value, today.isoformat(),
        )

    def dispose_asset(
        self, asset_id: str, disposal_date: date | None = None,
        disposal_value: Decimal = Decimal("0"),
    ) -> None:
        """v7.0: Zlikwiduj środek trwały.

        Args:
            asset_id: ID środka trwałego.
            disposal_date: Data likwidacji (domyślnie dzisiaj).
            disposal_value: Wartość likwidacyjna (np. cena sprzedaży).
        """
        today = disposal_date or pendulum.now().date()

        self.duckdb.execute(
            """UPDATE fixed_assets
               SET status = 'DISPOSED',
                   disposal_date = ?,
                   disposal_value = ?
               WHERE id = ?""",
            (today, float(disposal_value), asset_id),
        )

        # Usuń niezaksięgowane raty amortyzacji
        self.duckdb.execute(
            "DELETE FROM depreciation_schedule WHERE asset_id = ? AND is_posted = FALSE",
            (asset_id,),
        )

        logger.info(
            "[FIXED-ASSETS] Asset %s disposed on %s, value=%.2f PLN",
            asset_id, today.isoformat(), disposal_value,
        )
