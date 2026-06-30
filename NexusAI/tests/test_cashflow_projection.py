from datetime import date
from nexus_ai.db.views import AnalyticsViewsSetup
from nexus_ai.services.cfo_offline import CashflowForecastService


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
