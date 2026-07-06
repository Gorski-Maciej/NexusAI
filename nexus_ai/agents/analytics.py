"""AgentAnalytics — Sztab Analityczny.

Zgodnie z AGENT_SYSTEM_ENTERPRISE.txt:
- Hrida-T2SQL-128k — NL → SQL (DuckDB)
- Granite 3.2 3B — Główny Analityk
- Fin-RWKV-169M — Detektyw Finansowy (anomalie)
- Lag-Llama 0.3B — Prognoza szeregów czasowych

Enterprise features:
- Proactive Monitoring 24/7: cash flow, DSO, terminy, VAT, P&L
- Natural Language Insights: codzienny brief generowany
- Anomaly Detection: Z-score, IQR, Mahalanobis, Isolation Forest
- Automatyczne raporty: dzienne/tygodniowe/miesięczne
- Risk Flags: proaktywne wykrywanie ryzyka
"""

from __future__ import annotations

from typing import Any

import anyio
import pendulum
from structlog import get_logger

from nexus_ai.agents.base import BaseAgent
from nexus_ai.agents.models import AnalyticsQuery, AnalyticsResult
from nexus_ai.agents.topics import AgentTopic
from nexus_ai.core.inference import ModelManager
from nexus_ai.services.mesh_service import MeshService

logger = get_logger("nexus.agents.analytics")

DAILY_BRIEF_LIMIT = 5  # M20: named constant instead of magic number


class AgentAnalytics(BaseAgent):
    """Agent Analityczny — analityka finansowa przez DuckDB."""

    def __init__(
        self,
        model_manager: ModelManager | None = None,
        config: dict[str, Any] | None = None,
        knowledge_mesh=None,
    ) -> None:
        super().__init__(
            name="analytics",
            model_manager=model_manager,
            config=config or {},
            knowledge_mesh=knowledge_mesh,
        )
        self._duckdb: Any = None
        self._facts_aggregator: Any = None
        self._forecast_service: Any = None
        self._scheduler_task: Any = None
        self._models: dict[str, str] = {}
        self._anomaly_detector: Any = None
        self._last_daily_brief_date: str = ""

    async def start(self) -> None:
        await super().start()
        await self._init_services()
        self._start_scheduler()
        logger.info("[AGENT] Analytics ready | models: %s", self._models)

    async def _init_services(self) -> None:
        """Inicjalizuj serwisy analityczne ze współdzielonym DuckDB."""
        from nexus_ai.core.config import AppConfig
        from nexus_ai.db.analytics import DuckDBManager
        config = AppConfig()

        try:
            self._duckdb = DuckDBManager(str(config.duckdb_path))
            logger.info("[ANALYTICS] DuckDB connected")
        except Exception as exc:
            logger.warning("[ANALYTICS] DuckDB init failed: %s", exc)

        try:
            from nexus_ai.services.facts_aggregator import FactsAggregator
            from nexus_ai.db.database import get_session
            self._facts_aggregator = FactsAggregator(get_session().__next__())
            logger.info("[ANALYTICS] FactsAggregator initialized")
        except Exception as exc:
            logger.warning("[ANALYTICS] FactsAggregator init failed: %s", exc)

        try:
            if self._duckdb:
                from nexus_ai.services.cfo_offline import CashflowForecastService
                self._forecast_service = CashflowForecastService(self._duckdb._conn)
                logger.info("[ANALYTICS] Forecast service initialized")
        except Exception as exc:
            logger.warning("[ANALYTICS] Forecast init failed: %s", exc)

        try:
            from nexus_ai.services.anomaly_detector import SmartAnomalyDetector
            self._anomaly_detector = SmartAnomalyDetector()
            logger.info("[ANALYTICS] Anomaly detector initialized")
        except Exception as exc:
            logger.warning("[ANALYTICS] Anomaly detector init failed: %s", exc)

        self._models = {
            "sql_model": self._config.get("analytics_sql_model", ""),
            "analyst_model": self._config.get("analytics_analyst_model", ""),
            "anomaly_model": self._config.get("anomaly_model", ""),
        }

    def _start_scheduler(self) -> None:
        self._scheduler_task = anyio.create_task(self._proactive_loop())

    async def _proactive_loop(self) -> None:
        """Pętla zadań proaktywnych."""
        while self._running:
            try:
                now = pendulum.now("UTC")
                today = now.to_date_string()
                if now.hour == 6 and now.minute == 0 and self._last_daily_brief_date != today:
                    self._last_daily_brief_date = today
                    await self._generate_daily_brief()
                if now.weekday() == 0 and now.hour == 7 and now.minute == 0:
                    await self._scheduled_report("weekly", "7 DAY")  # M9
                if now.day == 1 and now.hour == 8 and now.minute == 0:
                    await self._scheduled_report("monthly", "30 DAY")
                await anyio.sleep(60)
            except Exception:
                await anyio.sleep(60)

    async def analyze(self, query: AnalyticsQuery) -> AnalyticsResult:
        """Przetwórz zapytanie analityczne."""
        logger.info("[ANALYTICS] Processing query %s (type=%s)", query.query_id, query.query_type)
        sql = query.sql_query
        if not sql and query.natural_language and self._models.get("sql_model"):
            sql = await self._nl_to_sql(query.natural_language)
            logger.info("[ANALYTICS] NL→SQL: %s", sql)
        if not sql:
            return AnalyticsResult(query_id=query.query_id, success=False, error="No SQL query provided")
        if not self._duckdb:
            return AnalyticsResult(query_id=query.query_id, success=False, error="DuckDB not available")

        try:
            result_data = await self._execute_query(sql, query.params)
        except Exception as exc:
            return AnalyticsResult(query_id=query.query_id, success=False, error=f"Query execution failed: {exc}", sql_executed=sql)

        summary = ""
        if result_data and self._models.get("analyst_model"):
            summary = await self._interpret_results(result_data, query)
        anomalies = await self._detect_anomalies(result_data)
        risk_flags = await self._detect_risk_flags(result_data, query)

        await self._publish_mesh_events(query, anomalies, risk_flags, vendor_nip=query.context.get("vendor_nip", "") if query.context else "")

        return AnalyticsResult(
            query_id=query.query_id, success=True, summary=summary, data=result_data,
            anomalies=anomalies, sql_executed=sql, model_used=self._models["sql_model"] or "direct-sql", risk_flags=risk_flags,
        )

    async def _generate_daily_brief(self) -> None:
        """Generuj codzienny brief finansowy."""
        logger.info("[ANALYTICS] Generating daily brief")
        try:
            query = AnalyticsQuery(
                query_id=f"daily-brief-{pendulum.now('UTC').to_date_string()}",
                query_type="daily_brief",
                sql_query="SELECT DATE(created_at) AS day, COUNT(*) AS invoice_count, SUM(amount_gross) AS total_amount FROM invoice_read_model WHERE created_at >= CURRENT_DATE - INTERVAL '1' DAY GROUP BY 1",
            )
            result = await self.analyze(query)
            brief = "Codzienny briefing finansowy — brak danych."
            if result.data:
                data_str = str(result.data[:DAILY_BRIEF_LIMIT])  # M20
                brief = await self._generate_nl_brief(data_str)
            ctx = self._ctx(target="orchestrator")
            await self.publish(AgentTopic.ANALYTICS_RESULT, AnalyticsResult(query_id=query.query_id, success=True, daily_brief=brief, data=result.data), ctx)
            logger.info("[ANALYTICS] Daily brief generated: %s...", brief[:100])
        except Exception as exc:
            logger.warning("[ANALYTICS] Daily brief failed: %s", exc)

    async def _generate_nl_brief(self, data_str: str) -> str:
        model_path = self._models.get("analyst_model")
        if not model_path:
            return f"Dane z ostatniego dnia: {data_str}"
        prompt = f"Jesteś głównym analitykiem finansowym. Na podstawie danych z ostatniego dnia, przygotuj zwięzły codzienny brief finansowy (po polsku, 2-3 zdania).\n\nDane: {data_str}\n\nBrief:"
        try:
            return await self.infer(model_path, prompt, max_tokens=200, temperature=0.2)
        except Exception as exc:
            logger.debug("[ANALYTICS] NL brief failed: %s", exc)
            return f"Dane: {data_str}"

    async def _detect_anomalies(self, data: list[dict[str, Any]]) -> list[dict[str, Any]]:
        """Wykrywanie anomalii (statystyczne + ML)."""
        if not data:
            return []
        anomalies = []
        try:
            if self._anomaly_detector:
                for row in data:
                    result = getattr(self._anomaly_detector, 'detect', lambda x: {})(row)
                    if isinstance(result, dict) and result.get("is_anomaly"):
                        anomalies.append({"type": result.get("method", "statistical"), "severity": result.get("severity", "medium"), "description": result.get("reason", "Anomaly detected"), "row": row})
        except Exception as exc:
            logger.debug("[ANALYTICS] Anomaly detection failed: %s", exc)

        try:
            numeric_fields = self._find_numeric_fields(data)
            for field in numeric_fields:
                values = [r.get(field, 0) or 0 for r in data if isinstance(r.get(field), (int, float))]
                if len(values) < 2:
                    continue
                mean = sum(values) / len(values)
                var = sum((v - mean) ** 2 for v in values) / len(values)
                std = var ** 0.5
                if std == 0:
                    continue
                for row in data:
                    val = row.get(field, 0)
                    if isinstance(val, (int, float)):
                        z = abs((val - mean) / std)
                        if z > 2.0:
                            anomalies.append({"type": "z_score", "severity": "high" if z > 3.0 else "medium", "description": f"Z={z:.1f} dla {field}={val}", "row": row, "field": field, "z_score": z})
        except Exception as exc:
            logger.debug("[ANALYTICS] Statistical anomaly detection failed: %s", exc)
        return anomalies

    async def _detect_risk_flags(self, data: list[dict[str, Any]], query: AnalyticsQuery) -> list[dict[str, Any]]:
        if not data:
            return []
        flags = []
        for row in data:
            if row.get("status") == "OVERDUE" and row.get("amount_gross", 0):
                flags.append({"type": "overdue", "severity": "high", "description": f"Przeterminowana: {row.get('invoice_number', 'N/A')} na {row.get('amount_gross', 0)} PLN", "row": row})
            gross = row.get("amount_gross", 0)
            if isinstance(gross, (int, float)) and gross > 50000:
                flags.append({"type": "high_amount", "severity": "medium", "description": f"Wysoka kwota: {gross} PLN", "row": row})
        return flags

    # M10: Guard clauses + MeshService (TOP-2)
    async def _publish_mesh_events(self, query: AnalyticsQuery, anomalies: list[dict[str, Any]], risk_flags: list[dict[str, Any]], vendor_nip: str = "") -> None:
        if not self.mesh_ready:
            return
        category = query.context.get("category", "") if query.context else ""
        amount = float(query.context.get("amount_gross", 0)) if query.context else 0.0

        high_anomalies = [a for a in anomalies if a.get("severity") == "high"]
        medium_anomalies = [a for a in anomalies if a.get("severity") == "medium" and a.get("type") == "z_score"]
        high_risk = [f for f in risk_flags if f.get("severity") in ("high", "critical")]

        # High severity → reduce trust
        if high_anomalies:
            fields = list({a.get("field", "?") for a in high_anomalies})
            await MeshService.publish_event(
                mesh=self.mesh, event_type="analytics.anomaly_detected", source_agent=self.name,
                vendor_nip=vendor_nip or "unknown", category=category, amount=amount,
                severity="high", trust_correct=False,
                details={"query_id": query.query_id, "fields": fields, "anomaly_count": len(high_anomalies), "detection_method": "z_score"},
            )
        # Medium anomalies → share experience only, no trust adjustment
        elif medium_anomalies:
            fields = list({a.get("field", "?") for a in medium_anomalies})
            await MeshService.publish_event(
                mesh=self.mesh, event_type="analytics.anomaly_detected", source_agent=self.name,
                vendor_nip=vendor_nip or "unknown", category=category, amount=amount,
                severity="medium", adjust_trust=False,
                details={"query_id": query.query_id, "fields": fields, "anomaly_count": len(medium_anomalies)},
            )
        # High risk flags → reduce trust
        if high_risk:
            await MeshService.reduce_trust(
                mesh=self.mesh, vendor_nip=vendor_nip or "unknown", source_agent=self.name,
                category=category, amount=amount, event_type="analytics.anomaly_detected",
                reason=f"high_risk_flags_{[f.get('type','') for f in high_risk]}",
            )

    async def _nl_to_sql(self, nl_query: str) -> str:
        model_path = self._models.get("sql_model")
        if not model_path:
            return ""
        schema_context = ""
        if self._duckdb:
            try:
                tables = self._duckdb.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'main'").fetchall()
                schema_parts = []
                for (tname,) in tables[:10]:
                    cols = self._duckdb.execute(f"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{tname}'").fetchall()
                    schema_parts.append(f"{tname}({', '.join(f'{c[0]} {c[1]}' for c in cols[:20])})")
                schema_context = "Schemat bazy:\n" + "\n".join(schema_parts)
            except Exception:
                pass
        prompt = f"Jesteś ekspertem SQL. Na podstawie schematu bazy danych i pytania, wygeneruj zapytanie SQL.\n\n{schema_context}\n\nPytanie: {nl_query}\n\nZwróć WYŁĄCZNIE zapytanie SQL, bez komentarzy:"
        try:
            result = await self.infer(model_path, prompt, max_tokens=256, temperature=0.05)
            return result.strip()
        except Exception as exc:
            logger.warning("[ANALYTICS] NL→SQL failed: %s", exc)
            return ""

    async def _execute_query(self, sql: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
        if not self._duckdb:
            return []

        def _sync_query() -> list[dict[str, Any]]:
            result = self._duckdb.execute(sql, params or {})
            columns = [desc[0] for desc in result.description] if result.description else []
            rows = result.fetchall()
            return [dict(zip(columns, row)) for row in rows]

        return await anyio.to_thread.run_sync(_sync_query)

    async def _interpret_results(self, data: list[dict[str, Any]], query: AnalyticsQuery) -> str:
        model_path = self._models.get("analyst_model")
        if not model_path or not data:
            return ""
        data_str = str(data[:10])
        prompt = f"Jesteś głównym analitykiem finansowym. Na podstawie danych i pytania, przygotuj zwięzłe podsumowanie biznesowe (po polsku).\n\nDane: {data_str}\nPytanie: {query.natural_language or query.query_type}\n\nPodsumowanie (2-3 zdania):"
        try:
            return await self.infer(model_path, prompt, max_tokens=200, temperature=0.1)
        except Exception as exc:
            logger.warning("[ANALYTICS] Interpretation failed: %s", exc)
            return ""

    # M9: Consolidated report generator
    async def _scheduled_report(self, period: str, interval: str) -> None:
        logger.info("[ANALYTICS] Running %s report", period)
        query_id = f"{period}-{pendulum.now('UTC').isoformat()}"
        sql_template = f"SELECT DATE_TRUNC('{period}', created_at) AS {period[0]}, COUNT(*) AS invoice_count, SUM(amount_gross) AS total_amount FROM invoice_read_model WHERE created_at >= CURRENT_DATE - INTERVAL '{interval}' GROUP BY 1 ORDER BY 1"
        query = AnalyticsQuery(query_id=query_id, query_type="sql", sql_query=sql_template)
        result = await self.analyze(query)
        if result.success and result.summary:
            ctx = self._ctx(target="orchestrator")
            await self.publish(AgentTopic.ANALYTICS_RESULT, result, ctx)

    @staticmethod
    def _find_numeric_fields(data: list[dict[str, Any]]) -> list[str]:
        numeric = set()
        for row in data:
            for key, value in row.items():
                if isinstance(value, (int, float)):
                    numeric.add(key)
        return list(numeric)

    async def process_query(self, query: AnalyticsQuery) -> None:
        """Przetwórz zapytanie analityczne. Taskiq task."""
        result = await self.analyze(query)
        ctx = self._ctx(target="orchestrator")
        await self.publish(AgentTopic.ANALYTICS_RESULT, result, ctx)
        logger.info("[AGENT] Analytics result for %s | success=%s | rows=%d | anomalies=%d", query.query_id, result.success, len(result.data), len(result.anomalies))
