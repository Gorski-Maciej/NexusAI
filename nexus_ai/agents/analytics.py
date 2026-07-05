"""AgentAnalytics — Miniaturowy Sztab Analityczny.

Zgodnie z blueprintem aa3fvcx.txt:
- Hrida-T2SQL-128k ~3.8B — zamiana języka naturalnego na SQL (DuckDB)
- Granite 3.2 3B — Główny Analityk (interpretacja wyników)
- Fin-RWKV-169M — Detektyw Finansowy (anomalie, stała usługa w tle)
- Tryb pasywny: na żądanie Orkiestratora (analytics.query)
- Tryb proaktywny: harmonogram (dzienny/tygodniowy/miesięczny)
- Komunikacja przez NATS JetStream

Modele zarządzane pamięcią:
- Hrida-T2SQL: lazy load, explicit unload po zapytaniu (~1.0 GB RAM)
- Granite 3.2: lazy load, współdzielony z Orkiestratorem (~2.4 GB RAM)
- Fin-RWKV: stała usługa w tle (~100 MB RAM)
"""

from __future__ import annotations

from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.agents.base import BaseAgent
from nexus_ai.agents.models import AnalyticsQuery, AnalyticsResult, make_context
from nexus_ai.agents.topics import AgentTopic
from nexus_ai.core.inference import ModelManager

logger = get_logger("nexus.agents.analytics")


class AgentAnalytics(BaseAgent):
    """Agent Analityczny — analityka finansowa przez DuckDB.

    Używa istniejących serwisów:
    - DuckDBManager dla zapytań SQL
    - CFOOrchestrator dla prognoz i detekcji anomalii
    - FactsAggregator dla agregacji danych

    Dodaje:
    - Hrida-T2SQL — zamiana NL na SQL
    - Fin-RWKV — wykrywanie anomalii w tle
    - Harmonogram zadań proaktywnych
    """

    def __init__(
        self,
        model_manager: ModelManager | None = None,
        config: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(
            name="analytics",
            model_manager=model_manager,
            config=config or {},
        )
        self._duckdb: Any = None
        self._facts_aggregator: Any = None
        self._forecast_service: Any = None
        self._scheduler_task: Any = None
        self._models: dict[str, str] = {}
        self._anomaly_detector: Any = None

    async def start(self) -> None:
        """Inicjalizuj połączenie z DuckDB i uruchom harmonogram."""
        await super().start()
        await self._init_services()
        self._start_scheduler()
        logger.info("[AGENT] Analytics ready | models: %s", self._models)

    async def _init_services(self) -> None:
        """Inicjalizuj serwisy analityczne."""
        # DuckDB
        try:
            from nexus_ai.db.analytics import DuckDBManager
            from nexus_ai.core.config import AppConfig
            config = AppConfig()
            self._duckdb = DuckDBManager(str(config.duckdb_path))
            logger.info("[ANALYTICS] DuckDB connected: %s", config.duckdb_path)
        except Exception as exc:
            logger.warning("[ANALYTICS] DuckDB init failed: %s", exc)

        # FactsAggregator
        try:
            from nexus_ai.services.facts_aggregator import FactsAggregator
            from nexus_ai.db.database import get_session
            self._facts_aggregator = FactsAggregator(get_session().__next__())
            logger.info("[ANALYTICS] FactsAggregator initialized")
        except Exception as exc:
            logger.warning("[ANALYTICS] FactsAggregator init failed: %s", exc)

        # Forecast service (z CFO)
        try:
            if self._duckdb:
                from nexus_ai.services.cfo_offline import CashflowForecastService
                self._forecast_service = CashflowForecastService(self._duckdb._conn)
                logger.info("[ANALYTICS] Forecast service initialized")
        except Exception as exc:
            logger.warning("[ANALYTICS] Forecast init failed: %s", exc)

        # Anomaly detector (Fin-RWKV symulacja)
        try:
            from nexus_ai.services.anomaly_detector import SmartAnomalyDetector
            self._anomaly_detector = SmartAnomalyDetector()
            logger.info("[ANALYTICS] Anomaly detector initialized")
        except Exception as exc:
            logger.warning("[ANALYTICS] Anomaly detector init failed: %s", exc)

        # Ustaw ścieżki modeli z konfiguracji
        self._models = {
            "sql_model": self._config.get("analytics_sql_model", ""),
            "analyst_model": self._config.get("analytics_analyst_model", ""),
            "anomaly_model": self._config.get("anomaly_model", ""),
        }

    def _start_scheduler(self) -> None:
        """Uruchom harmonogram zdań proaktywnych."""
        import anyio
        self._scheduler_task = anyio.create_task(self._proactive_loop())

    async def _proactive_loop(self) -> None:
        """Pętla zadań proaktywnych: dzienne, tygodniowe, miesięczne."""
        while self._running:
            try:
                now = pendulum.now("UTC")
                # Dzienne zadania (o 6:00 UTC)
                if now.hour == 6 and now.minute == 0:
                    await self._daily_reconciliation()

                # Tygodniowe zadania (poniedziałek 7:00)
                if now.weekday() == 0 and now.hour == 7 and now.minute == 0:
                    await self._weekly_report()

                # Miesięczne zadania (1. dzień miesiąca 8:00)
                if now.day == 1 and now.hour == 8 and now.minute == 0:
                    await self._monthly_report()

                await anyio.sleep(60)  # Sprawdzaj co minutę
        # TODO: Use Taskiq Scheduler for precise cron scheduling instead of polling
            except Exception as exc:
                logger.warning("[ANALYTICS] Proactive loop error: %s", exc)
                await anyio.sleep(60)

    async def analyze(self, query: AnalyticsQuery) -> AnalyticsResult:
        """Główna metoda analizy — przetwarza zapytanie i zwraca wynik.

        Proces:
        1. Jeśli podano natural_language → Hrida-T2SQL → SQL
        2. Wykonaj SQL na DuckDB
        3. Granite 3.2 → interpretacja wyników
        4. Fin-RWKV → wykrywanie anomalii
        5. Zwróć AnalyticsResult
        """
        logger.info("[ANALYTICS] Processing query %s (type=%s)", query.query_id, query.query_type)

        # 1. Konwersja NL → SQL przez Hrida-T2SQL
        sql = query.sql_query
        if not sql and query.natural_language and self._models["sql_model"]:
            sql = await self._nl_to_sql(query.natural_language)
            logger.info("[ANALYTICS] NL→SQL: %s", sql)

        if not sql:
            return AnalyticsResult(
                query_id=query.query_id,
                success=False,
                error="No SQL query provided and NL→SQL conversion failed",
            )

        # 2. Wykonaj SQL na DuckDB
        if not self._duckdb:
            return AnalyticsResult(
                query_id=query.query_id,
                success=False,
                error="DuckDB not available",
            )

        try:
            result_data = await self._execute_query(sql, query.params)
        except Exception as exc:
            return AnalyticsResult(
                query_id=query.query_id,
                success=False,
                error=f"Query execution failed: {exc}",
                sql_executed=sql,
            )

        # 3. Interpretacja wyników przez Granite 3.2
        summary = ""
        if result_data and self._models["analyst_model"]:
            summary = await self._interpret_results(result_data, query)

        # 4. Wykrywanie anomalii przez Fin-RWKV
        anomalies = await self._detect_anomalies(result_data)

        return AnalyticsResult(
            query_id=query.query_id,
            success=True,
            summary=summary,
            data=result_data,
            anomalies=anomalies,
            sql_executed=sql,
            model_used=self._models["sql_model"] or "direct-sql",
        )

    async def _nl_to_sql(self, nl_query: str) -> str:
        """Konwersja języka naturalnego na SQL przez Hrida-T2SQL."""
        model_path = self._models["sql_model"]
        if not model_path:
            return ""

        # Pobierz schemat bazy dla kontekstu
        schema_context = ""
        if self._duckdb:
            try:
                tables = self._duckdb.execute(
                    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'main'"
                ).fetchall()
                schema_parts = []
                for (tname,) in tables[:10]:
                    cols = self._duckdb.execute(
                        f"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{tname}'"
                    ).fetchall()
                    col_str = ", ".join(f"{c[0]} {c[1]}" for c in cols[:20])
                    schema_parts.append(f"{tname}({col_str})")
                schema_context = "Schemat bazy:\n" + "\n".join(schema_parts)
            except Exception:
                pass

        prompt = f"""Jesteś ekspertem SQL. Na podstawie schematu bazy danych i pytania w języku naturalnym, wygeneruj zapytanie SQL.

{schema_context}

Pytanie: {nl_query}

Zwróć WYŁĄCZNIE zapytanie SQL, bez komentarzy i objaśnień."""

        try:
            result = await self.infer(
                model_path,
                prompt,
                max_tokens=256,
                temperature=0.05,
            )
            return result.strip()
        except Exception as exc:
            logger.warning("[ANALYTICS] NL→SQL failed: %s", exc)
            return ""

    async def _execute_query(
        self,
        sql: str,
        params: dict[str, Any] | None = None,
    ) -> list[dict[str, Any]]:
        """Wykonaj zapytanie SQL na DuckDB."""
        if not self._duckdb:
            return []

        def _sync_query() -> list[dict[str, Any]]:
            if params:
                result = self._duckdb.execute(sql, params)
            else:
                result = self._duckdb.execute(sql)
            columns = [desc[0] for desc in result.description] if result.description else []
            rows = result.fetchall()
            return [dict(zip(columns, row)) for row in rows]

        import anyio
        return await anyio.to_thread.run_sync(_sync_query)

    async def _interpret_results(
        self,
        data: list[dict[str, Any]],
        query: AnalyticsQuery,
    ) -> str:
        """Interpretacja wyników przez Granite 3.2."""
        model_path = self._models["analyst_model"]
        if not model_path or not data:
            return ""

        data_str = str(data[:10])  # Tylko pierwsze 10 wierszy
        prompt = f"""Jesteś głównym analitykiem finansowym. Na podstawie danych i pytania użytkownika, przygotuj zwięzłe podsumowanie biznesowe (po polsku).

Dane:
{data_str}

Pytanie: {query.natural_language or query.query_type}

Podsumowanie (2-3 zdania):"""

        try:
            return await self.infer(
                model_path,
                prompt,
                max_tokens=200,
                temperature=0.1,
            )
        except Exception as exc:
            logger.warning("[ANALYTICS] Interpretation failed: %s", exc)
            return ""

    async def _detect_anomalies(self, data: list[dict[str, Any]]) -> list[dict[str, Any]]:
        """Wykrywanie anomalii przez Fin-RWKV."""
        anomalies = []
        if not data or not self._anomaly_detector:
            return anomalies

        try:
            for row in data:
                # Użyj istniejącego detektora anomalii
                if hasattr(self._anomaly_detector, 'detect'):
                    result = self._anomaly_detector.detect(row)
                    if result.get("is_anomaly"):
                        anomalies.append({
                            "type": "statistical",
                            "severity": result.get("severity", "medium"),
                            "description": result.get("reason", "Statistical anomaly detected"),
                            "row": row,
                        })
        except Exception as exc:
            logger.warning("[ANALYTICS] Anomaly detection failed: %s", exc)

        return anomalies

    # ── Zadania proaktywne ───────────────────────────────────────────

    async def _daily_reconciliation(self) -> None:
        """Dzienne uzgadnianie sald."""
        logger.info("[ANALYTICS] Running daily reconciliation")
        try:
            if self._forecast_service:
                forecast = self._forecast_service.forecast(horizon_days=30)
                if forecast.get("alerts"):
                    ctx = make_context(
                        task_id=f"daily-recon-{pendulum.now('UTC').to_date_string()}",
                        source=self.name,
                        target="orchestrator",
                    )
                    await self.publish(
                        AgentTopic.ANALYTICS_ALERT,
                        {
                            "type": "daily_reconciliation",
                            "alerts": forecast["alerts"],
                            "date": pendulum.now("UTC").to_date_string(),
                        },
                        ctx,
                    )
        except Exception as exc:
            logger.warning("[ANALYTICS] Daily reconciliation failed: %s", exc)

    async def _weekly_report(self) -> None:
        """Tygodniowy raport finansowy."""
        logger.info("[ANALYTICS] Running weekly report")
        query = AnalyticsQuery(
            query_id=f"weekly-{pendulum.now('UTC').isoformat()}",
            query_type="sql",
            sql_query="""
                SELECT DATE_TRUNC('week', created_at) AS week,
                       COUNT(*) AS invoice_count,
                       SUM(amount_gross) AS total_amount,
                       AVG(amount_gross) AS avg_amount
                FROM invoice_read_model
                WHERE created_at >= CURRENT_DATE - INTERVAL '7' DAY
                GROUP BY 1
                ORDER BY 1
            """,
        )
        result = await self.analyze(query)
        if result.success and result.summary:
            ctx = make_context(
                task_id=query.query_id,
                source=self.name,
                target="orchestrator",
            )
            await self.publish(AgentTopic.ANALYTICS_RESULT, result, ctx)

    async def _monthly_report(self) -> None:
        """Miesięczny raport finansowy."""
        logger.info("[ANALYTICS] Running monthly report")
        # Podobna struktura do weekly, ale dla zakresu miesięcznego
        query = AnalyticsQuery(
            query_id=f"monthly-{pendulum.now('UTC').isoformat()}",
            query_type="sql",
            sql_query="""
                SELECT DATE_TRUNC('month', created_at) AS month,
                       COUNT(*) AS invoice_count,
                       SUM(amount_gross) AS total_revenue,
                       COUNT(DISTINCT contractor_id) AS unique_contractors,
                       SUM(CASE WHEN status = 'OVERDUE' THEN amount_gross ELSE 0 END) AS overdue_amount
                FROM invoice_read_model
                WHERE created_at >= CURRENT_DATE - INTERVAL '30' DAY
                GROUP BY 1
                ORDER BY 1
            """,
            context={"report_type": "monthly"},
        )
        result = await self.analyze(query)
        if result.success:
            ctx = make_context(
                task_id=query.query_id,
                source=self.name,
                target="orchestrator",
            )
            await self.publish(AgentTopic.ANALYTICS_RESULT, result, ctx)

    async def process_query(self, query: AnalyticsQuery) -> None:
        """Przetwórz zapytanie analityczne i wyślij wynik.

        Taskiq task: agent_analytics.process_query
        """
        result = await self.analyze(query)
        ctx = make_context(
            task_id=query.query_id,
            source=self.name,
            target="orchestrator",
        )
        await self.publish(AgentTopic.ANALYTICS_RESULT, result, ctx)
        logger.info(
            "[AGENT] Analytics result for %s | success=%s | rows=%d",
            query.query_id,
            result.success,
            len(result.data),
        )
