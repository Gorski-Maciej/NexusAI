from typing import Any

from litestar import Controller, get, post
from structlog import get_logger

from nexus_ai.api.schemas import AnalyticsQuery
from nexus_ai.db.analytics import DuckDBManager

logger = get_logger("nexus.api.analytics")

# Dozwolone wartości dla dimension (walidacja białej listy - Rozwiązanie 20)
ALLOWED_DIMENSIONS = frozenset({"day", "month", "quarter", "year"})


def _validate_dimension(dimension: str) -> str:
    """Walidacja parametru dimension przed użyciem w zapytaniu SQL.
    Rozwiązanie 20: Odrzuca wartości spoza białej listy.
    """
    if dimension not in ALLOWED_DIMENSIONS:
        logger.warning(
            "[SQL-INJECTION] Invalid dimension '%s' blocked, using default 'month'", dimension
        )
        return "month"
    return dimension


def _validate_currency(currency: str) -> str:
    """Walidacja kodu waluty (3 litery, wielkie litery).
    Rozwiązanie 20: Odrzuca nieprawidłowe kody ISO.
    """
    if not currency or len(currency) != 3 or not currency.isalpha():
        logger.warning(
            "[SQL-INJECTION] Invalid currency '%s' blocked, using default 'PLN'", currency
        )
        return "PLN"
    return currency.upper()


class AnalyticsController(Controller):
    path = "/api/analytics"

    @post("/cashflow", cache=60)
    async def get_cashflow_report(self, data: AnalyticsQuery) -> dict:
        """Pobiera raport cashflow z kumulacją i opcjonalną konwersją walut (ASOF JOIN).
        Rozwiązanie 20: Walidacja parametrów dimension i report_currency na białej liście.
        """
        manager = DuckDBManager(
            db_path="nexus_olap.duckdb", sqlite_path="app_data/nexus_oltp.db", read_only=True
        )

        # Walidacja parametrów na białej liście (Rozwiązanie 20)
        safe_dimension = _validate_dimension(getattr(data, "dimension", "month"))
        safe_currency = _validate_currency(getattr(data, "report_currency", "PLN"))

        has_fx_rates = bool(
            manager.execute(
                """
                SELECT COUNT(*)
                FROM information_schema.tables
                WHERE lower(table_name) = 'fx_rates'
                """
            )[0][0]
        )

        if has_fx_rates:
            query = f"""
            WITH converted AS (
                SELECT
                    date_trunc('{safe_dimension}', i.issue_date) AS period,
                    i.amount_gross * COALESCE(r.rate_to_pln, 1) /
                        CASE WHEN upper('{safe_currency}') = 'PLN' THEN 1 ELSE COALESCE(r_target.rate_to_pln, 1) END
                        AS amount_converted
                FROM oltp.invoices i
                ASOF LEFT JOIN oltp.fx_rates r
                    ON upper(i.currency) = upper(r.currency)
                   AND r.effective_at <= i.issue_date
                ASOF LEFT JOIN oltp.fx_rates r_target
                    ON upper(r_target.currency) = upper('{safe_currency}')
                   AND r_target.effective_at <= i.issue_date
                WHERE i.issue_date BETWEEN ? AND ?
            ),
            base AS (
                SELECT period, SUM(amount_converted) AS total_gross
                FROM converted
                GROUP BY period
            )
            SELECT
                period,
                total_gross,
                SUM(total_gross) OVER (ORDER BY period ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_gross
            FROM base
            ORDER BY period
            """
        else:
            query = f"""
            WITH base AS (
                SELECT
                    date_trunc('{safe_dimension}', issue_date) AS period,
                    SUM(amount_gross) AS total_gross
                FROM oltp.invoices
                WHERE issue_date BETWEEN ? AND ?
                GROUP BY period
            )
            SELECT
                period,
                total_gross,
                SUM(total_gross) OVER (ORDER BY period ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_gross
            FROM base
            ORDER BY period
            """
        try:
            results = manager.execute(query, (data.start_date, data.end_date))
            if not results:
                return {
                    "rows": [],
                    "total_gross": 0.0,
                    "cumulative_gross": 0.0,
                    "report_currency": safe_currency,
                }
            rows = [
                {
                    "period": str(r[0]),
                    "total_gross": float(r[1] or 0.0),
                    "cumulative_gross": float(r[2] or 0.0),
                }
                for r in results
            ]
            return {
                "rows": rows,
                "total_gross": sum(x["total_gross"] for x in rows),
                "cumulative_gross": rows[-1]["cumulative_gross"],
                "report_currency": safe_currency,
            }
        except Exception as e:
            return {"error": str(e), "rows": [], "total_gross": 0.0}
        finally:
            manager.close()

    @get("/monthly-trend", cache=60)
    async def get_monthly_trend(self, state: Any) -> list[dict[str, Any]]:
        manager: DuckDBManager = state.olap_manager
        # Optymalizacja: wybieramy tylko potrzebne kolumny, filtrujemy NULL-e dla indeksu
        query = """
        SELECT
            strftime(issue_date, '%Y-%m') as month,
            SUM(amount_gross) as total
        FROM oltp.invoices
        WHERE issue_date IS NOT NULL
          AND status IN ('PAID', 'APPROVED')
        GROUP BY 1
        ORDER BY 1 DESC
        """
        results = manager.execute(query)
        return [{"month": str(row[0]), "total": float(row[1] or 0.0)} for row in results]
