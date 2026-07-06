"""AgentTelemetryStore — DuckDB + Parquet hurtownia telemetrii agentów.

GENIALNY POMYSŁ ENTERPRISE v5.4:
Zgodnie z aa3fvcx.txt §11 — wszystkie dane telemetryczne (decyzje, korekty,
rountingi, tracy) przechowywane w DuckDB i eksportowane do Parquet.

Architektura:
- DuckDB: szybkie zapytania analityczne (SQL)
- Parquet: kompaktowe, skompresowane przechowywanie
- DuckDB potrafi bezpośrednio odpytywać pliki Parquet
- Zero dodatkowej infrastruktury — wszystko w procesie

Tabele:
- telemetry_decisions: każda decyzja agenta
- telemetry_corrections: każda korekta użytkownika
- telemetry_routes: każda decyzja routingu (PredictiveTaskRouter)
- telemetry_traces: pełne DecisionTrace
- telemetry_feedback: metryki pętli feedbacku

Zgodnie z RAPORT_TECHNOLOGII_NEXUSAI.txt:
- DuckDB
- Parquet (PyArrow)
- msgspec
- anyio
"""

from __future__ import annotations

import json
import uuid
from typing import Any

import anyio
from structlog import get_logger

logger = get_logger("nexus.agents.telemetry")


# ═════════════════════════════════════════════════════════════════════════
# AgentTelemetryStore
# ═════════════════════════════════════════════════════════════════════════


class AgentTelemetryStore:
    """Hurtownia telemetrii agentów — DuckDB + Parquet.

    GENIALNY POMYSŁ v5.4:
    Każda decyzja, korekta, routing i trace są trwale przechowywane.
    DuckDB pozwala na błyskawiczne zapytania analityczne.
    Parquet zapewnia kompaktowe, skompresowane przechowywanie.
    """

    def __init__(self, db_path: str | None = None) -> None:
        self._db_path = db_path or "/tmp/nexus-telemetry.db"
        self._conn: Any = None
        self._initialized = False

    async def initialize(self) -> None:
        """Inicjalizuj DuckDB i utwórz tabele telemetryczne."""
        if self._initialized:
            return
        try:
            import duckdb
            self._conn = await anyio.to_thread.run_sync(
                lambda: duckdb.connect(self._db_path)
            )

            # Tabela decyzji
            self._conn.execute("""
                CREATE TABLE IF NOT EXISTS telemetry_decisions (
                    decision_id VARCHAR PRIMARY KEY,
                    vendor_nip VARCHAR,
                    amount_gross DOUBLE,
                    category VARCHAR,
                    document_type VARCHAR,
                    agent_name VARCHAR,
                    status VARCHAR,
                    trust_score DOUBLE,
                    decision_mode VARCHAR,
                    trace_id VARCHAR,
                    spans_count INTEGER,
                    total_duration_ms DOUBLE,
                    quality_score DOUBLE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

            # Tabela korekt
            self._conn.execute("""
                CREATE TABLE IF NOT EXISTS telemetry_corrections (
                    correction_id VARCHAR PRIMARY KEY,
                    decision_id VARCHAR,
                    agent_name VARCHAR,
                    ai_decision VARCHAR,
                    user_correction VARCHAR,
                    correction_reason VARCHAR,
                    vendor_nip VARCHAR,
                    category VARCHAR,
                    amount_gross DOUBLE,
                    delta DOUBLE,
                    feedback_type VARCHAR,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

            # Tabela routingu
            self._conn.execute("""
                CREATE TABLE IF NOT EXISTS telemetry_routes (
                    route_id VARCHAR PRIMARY KEY,
                    decision_id VARCHAR,
                    vendor_nip VARCHAR,
                    trust_score DOUBLE,
                    confidence DOUBLE,
                    route VARCHAR,
                    skip_agents VARCHAR,
                    force_agents VARCHAR,
                    circuit_breaker_open BOOLEAN,
                    threshold_adjustments VARCHAR,
                    applied_rules_count INTEGER,
                    estimated_time_ms DOUBLE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

            # Tabela trace'ów (pełne DecisionTrace jako JSON)
            self._conn.execute("""
                CREATE TABLE IF NOT EXISTS telemetry_traces (
                    trace_id VARCHAR PRIMARY KEY,
                    decision_id VARCHAR,
                    vendor_nip VARCHAR,
                    amount_gross DOUBLE,
                    category VARCHAR,
                    document_type VARCHAR,
                    spans_json VARCHAR,
                    total_duration_ms DOUBLE,
                    final_status VARCHAR,
                    final_trust_score DOUBLE,
                    decision_mode VARCHAR,
                    quality_score DOUBLE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

            # Tabela metryk feedbacku
            self._conn.execute("""
                CREATE TABLE IF NOT EXISTS telemetry_feedback (
                    id VARCHAR PRIMARY KEY,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    total_decisions INTEGER,
                    accepts INTEGER,
                    corrections INTEGER,
                    correction_rate DOUBLE,
                    avg_response_time_ms DOUBLE,
                    avg_feedback_latency_ms DOUBLE,
                    avg_quality_score DOUBLE
                )
            """)

            # Indeksy
            for idx_col in [
                "vendor_nip", "agent_name", "status", "decision_mode", "created_at",
            ]:
                try:
                    self._conn.execute(
                        f"CREATE INDEX IF NOT EXISTS idx_td_{idx_col} "
                        f"ON telemetry_decisions({idx_col})"
                    )
                except Exception as exc:
                    logger.debug("[TELEMETRY] Index creation failed for %s: %s", idx_col, exc)

            self._initialized = True
            logger.info(
                "[TELEMETRY] Store initialized | DB: %s | tables: 5",
                self._db_path,
            )
        except Exception as exc:
            logger.warning("[TELEMETRY] Init failed (DuckDB not available?): %s", exc)
            self._initialized = True

    # ── Record Decision ──────────────────────────────────────────────

    async def record_decision(
        self,
        decision_id: str,
        vendor_nip: str,
        amount_gross: float,
        category: str = "",
        document_type: str = "INVOICE",
        agent_name: str = "",
        status: str = "",
        trust_score: float = 0.0,
        decision_mode: str = "",
        trace_id: str = "",
        spans_count: int = 0,
        total_duration_ms: float = 0.0,
        quality_score: float = 0.0,
    ) -> None:
        """Zapisz decyzję w telemetrii."""
        if not self._initialized:
            await self.initialize()
        if not self._conn:
            return

        try:
            await anyio.to_thread.run_sync(
                lambda: self._conn.execute(
                    """INSERT OR REPLACE INTO telemetry_decisions
                       (decision_id, vendor_nip, amount_gross, category, document_type,
                        agent_name, status, trust_score, decision_mode, trace_id,
                        spans_count, total_duration_ms, quality_score)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        decision_id, vendor_nip, amount_gross, category, document_type,
                        agent_name, status, trust_score, decision_mode, trace_id,
                        spans_count, total_duration_ms, quality_score,
                    ),
                )
            )
        except Exception as exc:
            logger.debug("[TELEMETRY] Record decision failed: %s", exc)

    # ── Record Correction ────────────────────────────────────────────

    async def record_correction(
        self,
        correction_id: str,
        decision_id: str,
        agent_name: str,
        ai_decision: str,
        user_correction: str,
        correction_reason: str = "",
        vendor_nip: str = "",
        category: str = "",
        amount_gross: float = 0.0,
        delta: float = 0.0,
        feedback_type: str = "correct",
    ) -> None:
        """Zapisz korektę w telemetrii."""
        if not self._initialized:
            await self.initialize()
        if not self._conn:
            return

        try:
            await anyio.to_thread.run_sync(
                lambda: self._conn.execute(
                    """INSERT OR REPLACE INTO telemetry_corrections
                       (correction_id, decision_id, agent_name, ai_decision,
                        user_correction, correction_reason, vendor_nip, category,
                        amount_gross, delta, feedback_type)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        correction_id, decision_id, agent_name, ai_decision,
                        user_correction, correction_reason, vendor_nip, category,
                        amount_gross, delta, feedback_type,
                    ),
                )
            )
        except Exception as exc:
            logger.debug("[TELEMETRY] Record correction failed: %s", exc)

    # ── Record Route ─────────────────────────────────────────────────

    async def record_route(
        self,
        decision_id: str,
        vendor_nip: str,
        trust_score: float,
        confidence: float,
        route: list[str],
        skip_agents: list[str],
        force_agents: list[str],
        circuit_breaker_open: bool = False,
        threshold_adjustments: dict[str, float] | None = None,
        applied_rules_count: int = 0,
        estimated_time_ms: float = 0.0,
    ) -> None:
        """Zapisz decyzję routingu w telemetrii."""
        if not self._initialized:
            await self.initialize()
        if not self._conn:
            return

        route_id = uuid.uuid4().hex[:16]

        try:
            await anyio.to_thread.run_sync(
                lambda: self._conn.execute(
                    """INSERT INTO telemetry_routes
                       (route_id, decision_id, vendor_nip, trust_score, confidence,
                        route, skip_agents, force_agents, circuit_breaker_open,
                        threshold_adjustments, applied_rules_count, estimated_time_ms)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        route_id, decision_id, vendor_nip, trust_score, confidence,
                        json.dumps(route), json.dumps(skip_agents),
                        json.dumps(force_agents), circuit_breaker_open,
                        json.dumps(threshold_adjustments or {}),
                        applied_rules_count, estimated_time_ms,
                    ),
                )
            )
        except Exception as exc:
            logger.debug("[TELEMETRY] Record route failed: %s", exc)

    # ── Record Trace ─────────────────────────────────────────────────

    async def record_trace(
        self,
        trace_id: str,
        decision_id: str,
        vendor_nip: str,
        amount_gross: float,
        category: str = "",
        document_type: str = "",
        spans_json: str = "[]",
        total_duration_ms: float = 0.0,
        final_status: str = "",
        final_trust_score: float = 0.0,
        decision_mode: str = "",
        quality_score: float = 0.0,
    ) -> None:
        """Zapisz pełny DecisionTrace w telemetrii."""
        if not self._initialized:
            await self.initialize()
        if not self._conn:
            return

        try:
            await anyio.to_thread.run_sync(
                lambda: self._conn.execute(
                    """INSERT OR REPLACE INTO telemetry_traces
                       (trace_id, decision_id, vendor_nip, amount_gross, category,
                        document_type, spans_json, total_duration_ms, final_status,
                        final_trust_score, decision_mode, quality_score)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        trace_id, decision_id, vendor_nip, amount_gross, category,
                        document_type, spans_json, total_duration_ms, final_status,
                        final_trust_score, decision_mode, quality_score,
                    ),
                )
            )
        except Exception as exc:
            logger.debug("[TELEMETRY] Record trace failed: %s", exc)

    # ── Record Feedback Metrics ──────────────────────────────────────

    async def record_feedback_metrics(
        self,
        total_decisions: int,
        accepts: int,
        corrections: int,
        correction_rate: float,
        avg_response_time_ms: float,
        avg_feedback_latency_ms: float,
        avg_quality_score: float,
    ) -> None:
        """Zapisz metryki pętli feedbacku."""
        if not self._initialized:
            await self.initialize()
        if not self._conn:
            return

        metric_id = uuid.uuid4().hex[:16]
        try:
            await anyio.to_thread.run_sync(
                lambda: self._conn.execute(
                    """INSERT INTO telemetry_feedback
                       (id, total_decisions, accepts, corrections, correction_rate,
                        avg_response_time_ms, avg_feedback_latency_ms, avg_quality_score)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        metric_id, total_decisions, accepts, corrections,
                        correction_rate, avg_response_time_ms,
                        avg_feedback_latency_ms, avg_quality_score,
                    ),
                )
            )
        except Exception as exc:
            logger.debug("[TELEMETRY] Record feedback metrics failed: %s", exc)

    # ── Query Analytics ──────────────────────────────────────────────

    async def query_decisions(
        self,
        vendor_nip: str = "",
        status: str = "",
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        """Odpytaj decyzje z telemetrii.

        Args:
            vendor_nip: Filtruj po NIP (opcjonalnie).
            status: Filtruj po statusie (opcjonalnie).
            limit: Maksymalna liczba wyników.

        Returns:
            Lista decyzji jako dict.
        """
        if not self._conn:
            return []

        sql = "SELECT * FROM telemetry_decisions WHERE 1=1"
        params: list[Any] = []

        if vendor_nip:
            sql += " AND vendor_nip = ?"
            params.append(vendor_nip)
        if status:
            sql += " AND status = ?"
            params.append(status)

        sql += " ORDER BY created_at DESC LIMIT ?"
        params.append(limit)

        try:
            rows = await anyio.to_thread.run_sync(
                lambda: self._conn.execute(sql, params).fetchall()
            )
            columns = [desc[0] for desc in self._conn.description]
            return [dict(zip(columns, row, strict=True)) for row in rows]
        except Exception as exc:
            logger.debug("[TELEMETRY] Query failed: %s", exc)
            return []

    async def query_corrections(
        self,
        vendor_nip: str = "",
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        """Odpytaj korekty z telemetrii."""
        if not self._conn:
            return []

        sql = "SELECT * FROM telemetry_corrections WHERE 1=1"
        params: list[Any] = []

        if vendor_nip:
            sql += " AND vendor_nip = ?"
            params.append(vendor_nip)

        sql += " ORDER BY created_at DESC LIMIT ?"
        params.append(limit)

        try:
            rows = await anyio.to_thread.run_sync(
                lambda: self._conn.execute(sql, params).fetchall()
            )
            columns = [desc[0] for desc in self._conn.description]
            return [dict(zip(columns, row, strict=True)) for row in rows]
        except Exception as exc:
            logger.debug("[TELEMETRY] Query corrections failed: %s", exc)
            return []

    async def get_aggregate_stats(
        self,
        days: int = 30,
    ) -> dict[str, Any]:
        """Pobierz zagregowane statystyki z ostatnich N dni."""
        if not self._conn:
            return {"available": False}

        try:
            row = await anyio.to_thread.run_sync(
                lambda: self._conn.execute(
                    """SELECT
                        COUNT(*) as total_decisions,
                        COUNT(CASE WHEN status = 'AUTO_POST' THEN 1 END) as auto_posted,
                        COUNT(CASE WHEN status = 'REVIEW' THEN 1 END) as reviewed,
                        COUNT(CASE WHEN status = 'BLOCK' THEN 1 END) as blocked,
                        AVG(trust_score) as avg_trust,
                        AVG(quality_score) as avg_quality,
                        AVG(total_duration_ms) as avg_duration_ms,
                        COUNT(DISTINCT vendor_nip) as unique_vendors
                    FROM telemetry_decisions
                    WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL ? DAYS""",
                    (days,),
                ).fetchone()
            )
            if row:
                return {
                    "available": True,
                    "total_decisions": int(row[0]) if row[0] else 0,
                    "auto_posted": int(row[1]) if row[1] else 0,
                    "reviewed": int(row[2]) if row[2] else 0,
                    "blocked": int(row[3]) if row[3] else 0,
                    "avg_trust": round(float(row[4]), 3) if row[4] else 0.0,
                    "avg_quality": round(float(row[5]), 1) if row[5] else 0.0,
                    "avg_duration_ms": round(float(row[6]), 0) if row[6] else 0.0,
                    "unique_vendors": int(row[7]) if row[7] else 0,
                }
        except Exception as exc:
            logger.debug("[TELEMETRY] Aggregate query failed: %s", exc)

        return {"available": False}

    async def get_correction_analysis(
        self,
        days: int = 30,
    ) -> dict[str, Any]:
        """Analiza korekt — najczęściej korygowane wzorce."""
        if not self._conn:
            return {"available": False}

        try:
            # Najczęstsze typy korekt
            rows = await anyio.to_thread.run_sync(
                lambda: self._conn.execute(
                    """SELECT
                        vendor_nip,
                        ai_decision,
                        user_correction,
                        COUNT(*) as count,
                        AVG(amount_gross) as avg_amount
                    FROM telemetry_corrections
                    WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL ? DAYS
                    GROUP BY vendor_nip, ai_decision, user_correction
                    ORDER BY count DESC
                    LIMIT 10""",
                    (days,),
                ).fetchall()
            )

            return {
                "available": True,
                "top_corrections": [
                    {
                        "vendor_nip": str(r[0]),
                        "ai_decision": str(r[1]),
                        "user_correction": str(r[2]),
                        "count": int(r[3]),
                        "avg_amount": float(r[4]) if r[4] else 0.0,
                    }
                    for r in rows
                ],
            }
        except Exception as exc:
            logger.debug("[TELEMETRY] Correction analysis failed: %s", exc)

        return {"available": False}

    # ── Export ───────────────────────────────────────────────────────

    async def export_to_parquet(self, table: str, output_path: str) -> bool:
        """Eksportuj tabelę telemetryczną do pliku Parquet.

        Args:
            table: Nazwa tabeli (decisions, corrections, routes, traces, feedback).
            output_path: Ścieżka wyjściowa pliku .parquet.

        Returns:
            True jeśli eksport się powiódł.
        """
        if not self._conn:
            return False

        table_map = {
            "decisions": "telemetry_decisions",
            "corrections": "telemetry_corrections",
            "routes": "telemetry_routes",
            "traces": "telemetry_traces",
            "feedback": "telemetry_feedback",
        }

        full_table = table_map.get(table, f"telemetry_{table}")

        try:
            await anyio.to_thread.run_sync(
                lambda: self._conn.execute(
                    f"COPY {full_table} TO '{output_path}' (FORMAT PARQUET)"
                )
            )
            logger.info("[TELEMETRY] Exported %s → %s", full_table, output_path)
            return True
        except Exception as exc:
            logger.warning("[TELEMETRY] Export failed: %s", exc)
            return False

    # ── Lifecycle ────────────────────────────────────────────────────

    @property
    def count_decisions(self) -> int:
        if self._conn:
            try:
                row = self._conn.execute(
                    "SELECT COUNT(*) FROM telemetry_decisions"
                ).fetchone()
                return int(row[0]) if row else 0
            except Exception as exc:
                logger.debug("[TELEMETRY] Count decisions failed: %s", exc)
        return 0

    @property
    def count_corrections(self) -> int:
        if self._conn:
            try:
                row = self._conn.execute(
                    "SELECT COUNT(*) FROM telemetry_corrections"
                ).fetchone()
                return int(row[0]) if row else 0
            except Exception as exc:
                logger.debug("[TELEMETRY] Count corrections failed: %s", exc)
        return 0

    async def close(self) -> None:
        """Zamknij połączenie DuckDB."""
        if self._conn:
            try:
                await anyio.to_thread.run_sync(self._conn.close)
            except Exception as exc:
                logger.debug("[TELEMETRY] Close failed: %s", exc)
            self._conn = None
            self._initialized = False


__all__ = ["AgentTelemetryStore"]
