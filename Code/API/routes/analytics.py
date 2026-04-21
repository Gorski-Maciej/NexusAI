from litestar import Controller, get
from db.analytics import DuckDBManager, DuckDBAnalyticsEngine
from api.schemas import DashboardSummaryResponse

class AnalyticsController(Controller):
    path = "/api/v1/analytics"

    @get("/dashboard/summary")
    async def get_dashboard_summary(self, duckdb: DuckDBManager) -> DashboardSummaryResponse:
        """Pobiera agregaty finansowe z DuckDB w czasie poniżej 10ms."""
        query = """
        SELECT
            COALESCE(SUM(total_net), 0) as total_net_sum,
            COALESCE(SUM(total_gross), 0) as total_gross_sum,
            COALESCE(SUM(document_count), 0) as total_docs
        FROM v_monthly_summary
        WHERE period >= strftime('%Y-%m', current_date - interval 30 days)
        """
        result = duckdb.execute(query)
        if not result:
            return DashboardSummaryResponse(total_net=0.0, total_gross=0.0, total_documents=0)

        row = result[0]
        return DashboardSummaryResponse(total_net=row[0], total_gross=row[1], total_documents=row[2])

@get("/analytics/fraud-alerts")
async def get_fraud_alerts(db_engine: DuckDBAnalyticsEngine) -> list:
    detector = FraudDetector(db_engine.conn)
    alerts = detector.detect_round_number_spikes()
    return alerts.to_dict(orient="records")

@get("/analytics/cashflow-forecast")
async def get_forecast(db_engine: DuckDBAnalyticsEngine) -> list:
    predictor = CashflowPredictor(db_engine.conn)
    forecast = predictor.predict_liquidity_gap(days_ahead=30)
    return forecast.to_dict(orient="records")
