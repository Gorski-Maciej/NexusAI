from litestar import Controller, get
from litestar.exceptions import ClientException

from nexus_ai.api.dto import TAG_ANALYTICS, AnalyticsFXResponseDTO, DashboardSummaryDTO
from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.api.schemas import DashboardSummaryResponse
from nexus_ai.db.analytics import DuckDBManager


class AnalyticsController(Controller):
    """Analityka i raportowanie danych księgowych."""

    path = "/analytics"
    guards = [owner_only_guard]
    tags = [TAG_ANALYTICS]

    @get(
        "/dashboard/summary",
        return_dto=DashboardSummaryDTO,
        summary="Get dashboard summary",
        description="Returns aggregated financial summary including total net, gross, and document count for the last 30 days.",
        operation_id="getAnalyticsDashboardSummary",
        # Wbudowane cachowanie Litestar (ResponseCacheConfig) -- zastępuje @ttl_cache(seconds=60)
        cache=60,
    )
    async def get_dashboard_summary(self, duckdb: DuckDBManager) -> DashboardSummaryResponse:
        query = """
        WITH invoice_base AS (
            SELECT
                issue_date::DATE AS issue_day,
                amount_net,
                amount_gross,
                status
            FROM oltp.invoices
            WHERE status IN ('APPROVED', 'PAID')
        ), rolling AS (
            SELECT
                issue_day,
                amount_net,
                amount_gross,
                SUM(amount_gross) OVER (ORDER BY issue_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_gross
            FROM invoice_base
        )
        SELECT
            COALESCE(SUM(amount_net), 0) as total_net_sum,
            COALESCE(SUM(amount_gross), 0) as total_gross_sum,
            COALESCE(COUNT(*), 0) as total_docs
        FROM rolling
        WHERE issue_day >= current_date - interval 30 days
        """
        result = duckdb.execute(query)
        if not result:
            return DashboardSummaryResponse(total_net=0.0, total_gross=0.0, total_documents=0)

        row = result[0]
        return DashboardSummaryResponse(
            total_net=float(row[0]), total_gross=float(row[1]), total_documents=int(row[2])
        )

    @get(
        "/fx/asof",
        return_dto=AnalyticsFXResponseDTO,
        summary="Get FX AS-OF join sample",
        description="Returns historical FX valuation using AS-OF join for the specified currency.",
        operation_id="getFxAsOfSample",
        cache=60,
    )
    async def get_fx_asof_sample(
        self, duckdb: DuckDBManager, currency: str = "EUR"
    ) -> list[dict[str, object]]:
        """AS OF JOIN sample for historical FX valuation."""
        query = """
        SELECT
            i.id,
            i.issue_date,
            i.currency,
            i.amount_gross,
            r.rate,
            i.amount_gross * r.rate AS amount_in_pln
        FROM oltp.invoices i
        AS OF JOIN exchange_rates r
             ON i.currency = r.currency_code
            AND i.issue_date >= r.rate_date
        WHERE i.currency = ?
        ORDER BY i.issue_date DESC
        LIMIT 100
        """
        try:
            rows = duckdb.execute(query, [currency])
        except Exception as exc:
            raise ClientException(
                status_code=503,
                detail=f"FX historical rates unavailable: {exc}",
            ) from exc

        return [
            {
                "id": str(r[0]),
                "issue_date": str(r[1]),
                "currency": str(r[2]),
                "amount_gross": float(r[3]),
                "rate": float(r[4]),
                "amount_in_pln": float(r[5]),
            }
            for r in rows
        ]
