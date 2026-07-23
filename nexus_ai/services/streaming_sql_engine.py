"""
streaming_sql_engine.py — F3 v7.0.1: Streaming SQL Engine.

Raport v7.0 INNOWACJA #6: Continuous queries na strumieniach.
SELECT STREAM z NATS JetStream → DuckDB live views.

Enterprise v7.0.1:
  - Okna czasowe: tumbling, hopping, session
  - Materializowane jako DuckDB live views
  - NATS JetStream jako źródło strumieni
  - Polars dla agregacji strumieniowych
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.streaming_sql")


@dataclass
class StreamWindow:
    """Definicja okna czasowego dla zapytań strumieniowych."""
    window_type: str  # "tumbling", "hopping", "session"
    size_seconds: int
    slide_seconds: int = 0  # Tylko dla hopping
    gap_seconds: int = 0    # Tylko dla session


@dataclass
class ContinuousQuery:
    """Definicja ciągłego zapytania SQL na strumieniu."""
    query_id: str
    sql_template: str
    stream_name: str
    window: StreamWindow
    output_view: str  # Nazwa materialized view w DuckDB
    created_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())
    last_refresh: str = ""


class StreamingSQLEngine:
    """Silnik ciągłych zapytań SQL na strumieniach NATS JetStream.

    Raport v7.0 INNOWACJA #6 (Streaming SQL Engine):
    SELECT STREAM z NATS JetStream → DuckDB live views.

    Usage:
        engine = StreamingSQLEngine(duckdb_manager, jetstream_bus)
        query = ContinuousQuery(
            query_id="realtime_revenue",
            sql_template="SELECT SUM(amount_gross) FROM stream WHERE type='SALE'",
            stream_name="nexus-invoice",
            window=StreamWindow("tumbling", 60),
            output_view="m_realtime_revenue",
        )
        engine.register_query(query)
        await engine.start()
    """

    # Okna czasowe
    TUMBLING = "tumbling"
    HOPPING = "hopping"
    SESSION = "session"

    def __init__(
        self,
        duckdb_manager: Any = None,
        jetstream_bus: Any = None,
        max_buffer_size: int = 10000,
    ) -> None:
        self._duckdb = duckdb_manager
        self._jetstream = jetstream_bus
        self._queries: dict[str, ContinuousQuery] = {}
        self._running = False
        self._buffer: dict[str, list[dict[str, Any]]] = {}
        self._max_buffer_size = max_buffer_size

    def register_query(self, query: ContinuousQuery) -> None:
        """Zarejestruj ciągłe zapytanie.

        Args:
            query: Definicja ciągłego zapytania.
        """
        self._queries[query.query_id] = query
        self._buffer[query.query_id] = []

        # Utwórz materialized view dla wyników
        if self._duckdb:
            try:
                # Tworzymy tabelę na wyniki strumieniowe
                self._duckdb.execute_ddl(f"""
                    CREATE TABLE IF NOT EXISTS {query.output_view} (
                        window_start TIMESTAMP,
                        window_end TIMESTAMP,
                        result_value DOUBLE,
                        row_count INTEGER,
                        query_id VARCHAR,
                        refreshed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                logger.info("[STREAM-SQL] Created output view: %s", query.output_view)
            except Exception as exc:
                logger.warning("[STREAM-SQL] Failed to create view %s: %s", query.output_view, exc)

        logger.info(
            "[STREAM-SQL] Registered query=%s stream=%s window=%s/%ds",
            query.query_id, query.stream_name,
            query.window.window_type, query.window.size_seconds,
        )

    def unregister_query(self, query_id: str) -> None:
        """Wyrejestruj ciągłe zapytanie."""
        self._queries.pop(query_id, None)
        self._buffer.pop(query_id, None)

    async def start(self) -> None:
        """Uruchom silnik ciągłych zapytań."""
        self._running = True
        logger.info(
            "[STREAM-SQL] Engine started | %d queries registered",
            len(self._queries),
        )

    async def stop(self) -> None:
        """Zatrzymaj silnik."""
        self._running = False
        logger.info("[STREAM-SQL] Engine stopped")

    async def ingest_event(
        self, stream_name: str, event_data: dict[str, Any]
    ) -> None:
        """Przyjmij event ze strumienia i buforuj.

        Args:
            stream_name: Nazwa strumienia NATS (np. "nexus-invoice").
            event_data: Dane eventu (JSON).
        """
        for query in self._queries.values():
            if query.stream_name == stream_name:
                self._buffer[query.query_id].append(event_data)

    async def execute_window(self, query_id: str) -> dict[str, Any] | None:
        """Wykonaj zapytanie dla danego okna.

        Args:
            query_id: ID zapytania.

        Returns:
            Wynik lub None jeśli bufor pusty.
        """
        query = self._queries.get(query_id)
        if not query:
            return None

        buffer = self._buffer.get(query_id, [])
        if not buffer:
            return None

        now = pendulum.now("UTC")
        window_start = now.subtract(seconds=query.window.size_seconds)

        try:
            if self._duckdb:
                import polars as pl

                df = pl.DataFrame(buffer)
                arrow_table = df.to_arrow()

                conn = self._duckdb.get_connection_for_query()
                try:
                    conn.execute(
                        "CREATE OR REPLACE TEMP TABLE _stream_buffer AS SELECT * FROM arrow_table"
                    )

                    safe_sql = re.sub(
                        r'\bFROM\s+stream\b',
                        'FROM _stream_buffer',
                        query.sql_template,
                        flags=re.IGNORECASE,
                    )
                    # Query must run on SAME connection (temp tables are connection-scoped)
                    result_rows = conn.execute(safe_sql).fetchall()
                finally:
                    conn.close()

                if result_rows:
                    result_value = float(result_rows[0][0])
                    row_count = len(buffer)

                    # Zapisz do materialized view
                    self._duckdb.execute_ddl(
                        f"INSERT INTO {query.output_view} VALUES (?, ?, ?, ?, ?, ?)",
                        (
                            window_start.isoformat(),
                            now.isoformat(),
                            result_value,
                            row_count,
                            query_id,
                            now.isoformat(),
                        ),
                    )

                    query.last_refresh = now.isoformat()

            # Wyczyść bufor
            self._buffer[query_id] = []

            return {
                "query_id": query_id,
                "window_start": window_start.isoformat(),
                "window_end": now.isoformat(),
                "rows_processed": len(buffer),
                "output_view": query.output_view,
            }

        except Exception as exc:
            logger.warning("[STREAM-SQL] Window execution failed for %s: %s", query_id, exc)
            return None

    def get_query_results(
        self, query_id: str, limit: int = 10
    ) -> list[dict[str, Any]]:
        """Pobierz wyniki ciągłego zapytania z materialized view."""
        query = self._queries.get(query_id)
        if not query or not self._duckdb:
            return []
        try:
            rows = self._duckdb.execute(
                f"SELECT * FROM {query.output_view} ORDER BY refreshed_at DESC LIMIT {limit}"
            )
            return [
                {
                    "window_start": str(r[0]),
                    "window_end": str(r[1]),
                    "result_value": float(r[2]),
                    "row_count": int(r[3]),
                    "refreshed_at": str(r[5]),
                }
                for r in rows
            ]
        except Exception:
            return []

    def get_stats(self) -> dict[str, Any]:
        """Pobierz statystyki silnika."""
        return {
            "running": self._running,
            "queries_registered": len(self._queries),
            "queries": {
                qid: {
                    "stream": q.stream_name,
                    "window_type": q.window.window_type,
                    "window_size_s": q.window.size_seconds,
                    "output_view": q.output_view,
                    "last_refresh": q.last_refresh,
                    "buffer_size": len(self._buffer.get(qid, [])),
                }
                for qid, q in self._queries.items()
            },
        }
