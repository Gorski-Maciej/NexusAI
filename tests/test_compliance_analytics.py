from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

MODULE_PATH = ROOT / "Code" / "services" / "compliance_analytics.py"
spec = importlib.util.spec_from_file_location("compliance_analytics", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = module
spec.loader.exec_module(module)

infer_ledger_entries = module.infer_ledger_entries
ensure_compliance_analytics_schema = module.ensure_compliance_analytics_schema


class FakeDuckDBManager:
    def __init__(self):
        self.queries = []

    def execute(self, query, parameters=None):
        self.queries.append((query, parameters))
        if "FROM transaction_rules" in query:
            return [("1100", "4100", "VAT_OUTPUT")]
        return []


def test_infer_ledger_entries_maps_rulebook_to_packet() -> None:
    db = FakeDuckDBManager()
    packet = infer_ledger_entries(
        db,
        {
            "transaction_type": "INVOICE_SALE",
            "amount": "120.50",
            "currency": "pln",
            "metadata_tags": {"project": "X"},
        },
    )

    assert packet.transaction_type == "INVOICE_SALE"
    assert packet.debit_account_code == "1100"
    assert packet.credit_account_code == "4100"
    assert packet.tax_impact_code == "VAT_OUTPUT"
    assert packet.amount_minor == 12050
    assert packet.currency == "PLN"


def test_ensure_schema_executes_view_and_rulebook_setup() -> None:
    db = FakeDuckDBManager()
    ensure_compliance_analytics_schema(db)
    merged_sql = "\n".join(q for q, _ in db.queries)
    assert "CREATE TABLE IF NOT EXISTS gl_accounts" in merged_sql
    assert "CREATE TABLE IF NOT EXISTS transaction_rules" in merged_sql
    assert "CREATE OR REPLACE VIEW v_account_balances" in merged_sql
