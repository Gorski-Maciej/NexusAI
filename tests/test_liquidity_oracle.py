from __future__ import annotations

import importlib.util
import sys
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

MODULE_PATH = ROOT / "Code" / "services" / "liquidity_oracle.py"
spec = importlib.util.spec_from_file_location("liquidity_oracle", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules[spec.name] = module
spec.loader.exec_module(module)

calculate_liquidity_timeline = module.calculate_liquidity_timeline
ensure_liquidity_schema = module.ensure_liquidity_schema


class FakeTB:
    def __init__(self):
        self._account_credits_posted = {1001: 1000000}  # 10,000.00
        self._pending_transfers = {}


class FakeDuckDB:
    def __init__(self):
        self.queries = []

    def execute(self, query, parameters=None):
        self.queries.append((query, parameters))
        today = date.today()
        if "FROM invoices_replica i" in query:
            return [("V1", 3000.0, today + timedelta(days=2), 0.0, 1.0, 80)]
        if "type = 'PURCHASE'" in query:
            return [(1500.0, today + timedelta(days=1))]
        if "FROM recurring_commitments" in query:
            return [(1000.0, (today + timedelta(days=1)).day)]
        if "vat_liability" in query:
            return [(200.0,)]
        return []


def test_ensure_liquidity_schema_creates_view_and_table() -> None:
    db = FakeDuckDB()
    ensure_liquidity_schema(db)
    sql = "\n".join(q for q, _ in db.queries)
    assert "CREATE TABLE IF NOT EXISTS recurring_commitments" in sql
    assert "CREATE OR REPLACE VIEW v_payor_reliability_stats" in sql


def test_calculate_liquidity_timeline_returns_daily_projection() -> None:
    db = FakeDuckDB()
    tb = FakeTB()
    timeline = calculate_liquidity_timeline(db, tb, account_bank_id=1001, days_ahead=3)
    assert len(timeline) == 4
    assert timeline[0].optimistic_balance == "10000.00"
    assert float(timeline[-1].likely_balance) >= 0
