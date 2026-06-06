from datetime import date
from pathlib import Path
import sys
import types

sys.path.append(str(Path(__file__).resolve().parents[1] / "Code"))

db_module = types.ModuleType("db")
analytics_module = types.ModuleType("db.analytics")
analytics_module.DuckDBManager = object
analytics_module.DuckDBLimits = object
db_module.analytics = analytics_module
sys.modules.setdefault("db", db_module)
sys.modules.setdefault("db.analytics", analytics_module)

import importlib.util

views_spec = importlib.util.spec_from_file_location("views_module", Path(__file__).resolve().parents[1] / "Code" / "DB" / "views.py")
views_module = importlib.util.module_from_spec(views_spec)
assert views_spec and views_spec.loader
sys.modules["views_module"] = views_module
views_spec.loader.exec_module(views_module)
AnalyticsViewsSetup = views_module.AnalyticsViewsSetup

cfo_spec = importlib.util.spec_from_file_location("cfo_module", Path(__file__).resolve().parents[1] / "Code" / "services" / "cfo_offline.py")
cfo_module = importlib.util.module_from_spec(cfo_spec)
assert cfo_spec and cfo_spec.loader
sys.modules["cfo_module"] = cfo_module
cfo_spec.loader.exec_module(cfo_module)
CashflowForecastService = cfo_module.CashflowForecastService


class FakeDuckDBManager:
    def __init__(self) -> None:
        self.queries: list[str] = []

    def execute(self, query: str):
        self.queries.append(query)
        return self


class FakeConn:
    def execute(self, query: str, params: tuple[date, date]):
        self.query = query
        self.params = params
        return self

    def fetchall(self):
        start = self.params[0]
        return [
            (start, "INFLOW", 100.0, "INVOICE_INFLOW"),
            (start, "OUTFLOW", 40.0, "INVOICE_OUTFLOW"),
        ]


def test_create_cashflow_projection_view_generates_expected_objects() -> None:
    db = FakeDuckDBManager()

    AnalyticsViewsSetup.create_cashflow_projection_view(db)

    joined = "\n".join(db.queries)
    assert "CREATE TABLE IF NOT EXISTS manual_cashflow_items" in joined
    assert "CREATE OR REPLACE VIEW v_cashflow_projection" in joined
    assert "vendor_scorecards" in joined


def test_get_daily_forecast_returns_running_balance_and_confidence() -> None:
    service = CashflowForecastService(FakeConn())

    result = service.get_daily_forecast(days=0, opening_balance=50.0)

    assert len(result) == 1
    day, balance, confidence = result[0]
    assert isinstance(day, date)
    assert balance == 110.0
    assert 0.8 <= confidence <= 0.9
