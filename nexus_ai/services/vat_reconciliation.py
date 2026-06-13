"""VAT reconciliation — weryfikacja integralności VAT między OCR, DuckDB i TigerBeetle.

Zgodnie z aa3fvcx.txt:
- DuckDB dla OLAP (agregacje VAT)
- TigerBeetle dla bezpiecznych zapisów księgowych
- Decimal dla kalkulacji groszowych
"""

from __future__ import annotations

from msgspec import Struct
from decimal import ROUND_HALF_UP, Decimal
from typing import Any, final

from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

_ALLOWED_RATES = {"23", "8", "5", "0", "np", "zw"}


class VATBreakdown(Struct, frozen=True):
    rate: str
    net_amount: Decimal
    vat_amount: Decimal
    gross_amount: Decimal


class VATIntegrityResult(Struct, frozen=True):
    invoice_id: str
    status: str
    errors: list[str]


class ReconciliationAlert(Struct, frozen=True):
    status: str
    vat_in_ledger: Decimal
    vat_out_ledger: Decimal
    vat_in_register: Decimal
    vat_out_register: Decimal
    missing_in_duckdb: list[str]
    missing_in_ledger: list[str]


@final
class VATReconciliationEngine:
    """Silnik weryfikacji integralności VAT między OCR, DuckDB i TigerBeetle."""

    def __init__(
        self,
        duckdb_manager: Any,
        tb_client: TigerBeetleClient,
        account_vat_in: int,
        account_vat_out: int,
    ) -> None:
        self.duckdb = duckdb_manager
        self.tb_client = tb_client
        self.account_vat_in = account_vat_in
        self.account_vat_out = account_vat_out

    def ensure_tax_rates_schema(self) -> None:
        self.duckdb.execute("CREATE TABLE IF NOT EXISTS tax_rates (rate VARCHAR PRIMARY KEY)")
        for rate in ["23", "8", "5", "0", "np", "zw"]:
            self.duckdb.execute("INSERT OR IGNORE INTO tax_rates(rate) VALUES (?)", (rate,))

    def _to_breakdown(self, row: dict[str, Any]) -> VATBreakdown:
        rate = str(row.get("rate", "")).lower()
        if rate not in _ALLOWED_RATES:
            raise ValueError(f"Unsupported VAT rate: {rate}")
        return VATBreakdown(
            rate=rate,
            net_amount=Decimal(str(row["net_amount"])),
            vat_amount=Decimal(str(row["vat_amount"])),
            gross_amount=Decimal(str(row["gross_amount"])),
        )

    def check_vat_integrity(
        self, invoice_id: str, ocr_results: dict[str, Any]
    ) -> VATIntegrityResult:
        self.ensure_tax_rates_schema()
        errors: list[str] = []
        breakdown_rows = ocr_results.get("vat_breakdown", [])
        breakdown = [self._to_breakdown(row) for row in breakdown_rows]

        total_net = Decimal("0.00")
        total_vat = Decimal("0.00")
        total_gross = Decimal("0.00")
        for item in breakdown:
            rate_decimal = Decimal("0") if item.rate in {"np", "zw"} else Decimal(item.rate)
            expected_vat = (item.net_amount * rate_decimal / Decimal("100")).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            )
            if abs(expected_vat - item.vat_amount) > Decimal("0.01"):
                errors.append(f"VAT_MISMATCH:{item.rate}")
            if abs((item.net_amount + item.vat_amount) - item.gross_amount) > Decimal("0.01"):
                errors.append(f"MATH_ERROR_LINE:{item.rate}")
            total_net += item.net_amount
            total_vat += item.vat_amount
            total_gross += item.gross_amount

        reported_total_gross = Decimal(str(ocr_results.get("total_gross", total_gross)))
        if abs((total_net + total_vat) - reported_total_gross) > Decimal("0.01"):
            errors.append("MATH_ERROR_TOTAL")

        return VATIntegrityResult(
            invoice_id=invoice_id, status="OK" if not errors else "FAILED", errors=errors
        )

    async def reconcile_with_tigerbeetle(self) -> ReconciliationAlert:
        vat_in_ledger = Decimal(
            await self.tb_client.get_account_credits_posted(self.account_vat_in)
        ) / Decimal("100")
        vat_out_ledger = Decimal(
            await self.tb_client.get_account_credits_posted(self.account_vat_out)
        ) / Decimal("100")

        vat_rows = self.duckdb.execute(
            """SELECT COALESCE(SUM(CASE WHEN type = 'PURCHASE' THEN vat_amount ELSE 0 END), 0),
               COALESCE(SUM(CASE WHEN type = 'SALE' THEN vat_amount ELSE 0 END), 0) FROM invoices_vat"""
        )
        vat_in_register = Decimal(str(vat_rows[0][0])) if vat_rows else Decimal("0")
        vat_out_register = Decimal(str(vat_rows[0][1])) if vat_rows else Decimal("0")

        diff_rows = self.duckdb.execute(
            "SELECT source, invoice_id FROM vat_reconciliation_candidates WHERE source IN ('DUCKDB_ONLY', 'LEDGER_ONLY')"
        )
        missing_in_ledger = [
            str(invoice_id) for source, invoice_id in diff_rows if source == "DUCKDB_ONLY"
        ]
        missing_in_duckdb = [
            str(invoice_id) for source, invoice_id in diff_rows if source == "LEDGER_ONLY"
        ]

        status = (
            "OK"
            if (
                vat_in_ledger == vat_in_register
                and vat_out_ledger == vat_out_register
                and not diff_rows
            )
            else "ALERT"
        )
        return ReconciliationAlert(
            status=status,
            vat_in_ledger=vat_in_ledger,
            vat_out_ledger=vat_out_ledger,
            vat_in_register=vat_in_register,
            vat_out_register=vat_out_register,
            missing_in_duckdb=missing_in_duckdb,
            missing_in_ledger=missing_in_ledger,
        )
