from __future__ import annotations

from dataclasses import dataclass
import uuid
from datetime import date, timedelta
from decimal import Decimal, ROUND_HALF_UP
import json
from urllib import request, error
from typing import Any

from .ledger_client import TigerBeetleClient


@dataclass(frozen=True, slots=True)
class FXResult:
    invoice_id: str
    payment_id: str
    currency_code: str
    amount_foreign: Decimal
    historical_rate: Decimal
    settlement_rate: Decimal
    fx_diff_pln: Decimal
    direction: str


class ForexEngine:
    def __init__(self, duckdb_manager: Any, tb_client: TigerBeetleClient, account_receivable: int, account_fx_gain: int, account_fx_loss: int) -> None:
        self.duckdb = duckdb_manager
        self.tb_client = tb_client
        self.account_receivable = account_receivable
        self.account_fx_gain = account_fx_gain
        self.account_fx_loss = account_fx_loss

    def ensure_exchange_rate_schema(self) -> None:
        self.duckdb.execute(
            """
            CREATE TABLE IF NOT EXISTS exchange_rates (
                currency_code VARCHAR,
                rate_date DATE,
                avg_rate DOUBLE,
                table_no VARCHAR,
                PRIMARY KEY (currency_code, rate_date)
            )
            """
        )

    def fetch_nbp_rate(self, target_date: date, currency: str, max_lookback_days: int = 5) -> Decimal:
        self.ensure_exchange_rate_schema()
        currency_code = currency.upper()

        for offset in range(max_lookback_days + 1):
            rate_day = target_date - timedelta(days=offset)
            cached = self.duckdb.execute(
                "SELECT avg_rate FROM exchange_rates WHERE currency_code = ? AND rate_date = ?",
                (currency_code, rate_day),
            )
            if cached:
                return Decimal(str(cached[0][0]))

            url = f"https://api.nbp.pl/api/exchangerates/rates/A/{currency_code}/{rate_day.isoformat()}/?format=json"
            try:
                with request.urlopen(url, timeout=10) as response:
                    payload = json.loads(response.read().decode("utf-8"))
            except (error.HTTPError, error.URLError, TimeoutError):
                payload = None

            if payload is not None:
                avg_rate = Decimal(str(payload["rates"][0]["mid"]))
                table_no = str(payload["rates"][0]["no"])
                self.duckdb.execute(
                    """
                    INSERT OR REPLACE INTO exchange_rates(currency_code, rate_date, avg_rate, table_no)
                    VALUES (?, ?, ?, ?)
                    """,
                    (currency_code, rate_day, float(avg_rate), table_no),
                )
                return avg_rate

        raise ValueError(f"NBP rate not found for {currency_code} within {max_lookback_days} days before {target_date}")

    async def process_fx_settlement(self, invoice_uuid: str, payment_uuid: str) -> FXResult:
        inv_rows = self.duckdb.execute(
            """
            SELECT currency_code, amount_foreign, historical_rate
            FROM invoices_fx
            WHERE invoice_id = ?
            """,
            (invoice_uuid,),
        )
        pay_rows = self.duckdb.execute(
            """
            SELECT settlement_rate
            FROM bank_transactions_fx
            WHERE payment_id = ?
            """,
            (payment_uuid,),
        )
        if not inv_rows or not pay_rows:
            raise ValueError("Missing invoice or payment FX data")

        currency_code, amount_foreign_raw, historical_rate_raw = inv_rows[0]
        settlement_rate_raw = pay_rows[0][0]

        amount_foreign = Decimal(str(amount_foreign_raw))
        historical_rate = Decimal(str(historical_rate_raw))
        settlement_rate = Decimal(str(settlement_rate_raw))

        fx_diff = (amount_foreign * settlement_rate) - (amount_foreign * historical_rate)
        fx_diff = fx_diff.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        minor = int((abs(fx_diff) * 100).to_integral_value(rounding=ROUND_HALF_UP))

        direction = "NONE"
        if minor > 0:
            if fx_diff > 0:
                direction = "GAIN"
                pending = await self.tb_client.create_two_phase_transfer(
                    debit_account=self.account_receivable,
                    credit_account=self.account_fx_gain,
                    amount_minor=minor,
                    source_document_id=uuid.uuid5(uuid.NAMESPACE_URL, f"fx:{invoice_uuid}:{payment_uuid}"),
                )
            else:
                direction = "LOSS"
                pending = await self.tb_client.create_two_phase_transfer(
                    debit_account=self.account_fx_loss,
                    credit_account=self.account_receivable,
                    amount_minor=minor,
                    source_document_id=uuid.uuid5(uuid.NAMESPACE_URL, f"fx:{invoice_uuid}:{payment_uuid}"),
                )
            await self.tb_client.post_pending_transfer(pending.pending_id)

        return FXResult(
            invoice_id=invoice_uuid,
            payment_id=payment_uuid,
            currency_code=str(currency_code),
            amount_foreign=amount_foreign,
            historical_rate=historical_rate,
            settlement_rate=settlement_rate,
            fx_diff_pln=fx_diff,
            direction=direction,
        )
