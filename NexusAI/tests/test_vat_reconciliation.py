from pathlib import Path
import sys
import anyio

sys.path.append(str(Path(__file__).resolve().parents[1]))

from nexus_ai.services.tigerbeetle.client import TigerBeetleClient
from nexus_ai.services.vat_reconciliation import VATReconciliationEngine


class FakeDuckDBManager:
    def __init__(self):
        self.tax_rates = set()

    def execute(self, query, params=None):
        q = " ".join(query.split())
        if "INSERT OR IGNORE INTO tax_rates" in q:
            self.tax_rates.add(params[0])
            return []
        if "FROM invoices_vat" in q:
            return [(23.0, 46.0)]
        if "FROM vat_reconciliation_candidates" in q:
            return [("DUCKDB_ONLY", "inv-a"), ("LEDGER_ONLY", "inv-b")]
        return []


def test_check_vat_integrity_detects_mismatch() -> None:
    engine = VATReconciliationEngine(FakeDuckDBManager(), TigerBeetleClient(), 221001, 222001)

    result = engine.check_vat_integrity(
        "inv-1",
        {
            "total_gross": "123.00",
            "vat_breakdown": [
                {"rate": "23", "net_amount": "100.00", "vat_amount": "22.00", "gross_amount": "122.00"}
            ],
        },
    )
    assert result.status == "FAILED"
    assert "VAT_MISMATCH:23" in result.errors
    assert "MATH_ERROR_TOTAL" in result.errors


def test_reconcile_with_tigerbeetle_returns_alert() -> None:
    async def run() -> None:
        tb = TigerBeetleClient()
        tb._account_credits_posted[221001] = 2300
        tb._account_credits_posted[222001] = 4500

        engine = VATReconciliationEngine(FakeDuckDBManager(), tb, 221001, 222001)
        alert = await engine.reconcile_with_tigerbeetle()

        assert alert.status == "ALERT"
        assert alert.vat_in_ledger == 23
        assert alert.vat_out_ledger == 45
        assert alert.vat_in_register == 23
        assert alert.vat_out_register == 46
        assert alert.missing_in_ledger == ["inv-a"]
        assert alert.missing_in_duckdb == ["inv-b"]

    anyio.run(run)
