"""EventLog -- historia wszystkich zdarzeń i podjętych decyzji.

Zgodnie z aa3fvcx.txt (Punkt 26): historia wszystkich zdarzeń i podjętych
decyzji, przeszukiwalna dla systemu analitycznego (DuckDB).

Storage: DuckDB dla wydajnych zapytań OLAP.
Fallback: Główna baza (SQLModel, tabele: event_log).

DDL event_log przeniesione do migracji 0003_consolidate_service_tables.
DDL DuckDB (event_log_analytics) pozostaje jako _init_duckdb().
"""

from __future__ import annotations

from typing import Any, final

import pendulum
from sqlalchemy import Engine
from sqlmodel import text
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

logger = get_logger("nexus.services.event_log")


@final
class EventLog:
    """Historia zdarzeń i decyzji, przeszukiwalna dla systemu analitycznego (DuckDB).

    Zapisuje:
      - Decyzje podjęte przez użytkownika (approve/reject)
      - Decyzje podjęte przez system (auto-post, block)
      - Alerty wygenerowane przez system
      - Przypomnienia wysłane przez Scheduler
      - Błędy systemowe
      - Codzienne podsumowania

    Dostępna dla systemu analitycznego (DuckDB) do generowania raportów i trendów.

    Storage:
      - SQLite (główna baza, migracja 0003): event_log -- fallback dla zapytań
      - DuckDB: event_log_analytics -- wydajne zapytania OLAP
    """

    def __init__(
        self,
        engine: Engine,
        duckdb_manager: Any = None,
    ) -> None:
        self._engine = engine
        self._duckdb = duckdb_manager
        # DuckDB schema (analytics) -- pozostaje jako DDL w kodzie
        self._init_duckdb()

    def _init_duckdb(self) -> None:
        """Utwórz widok w DuckDB dla analityki eventów."""
        if not self._duckdb:
            return
        try:
            self._duckdb.execute("""
                CREATE TABLE IF NOT EXISTS event_log_analytics (
                    id INTEGER,
                    event_type VARCHAR,
                    source VARCHAR,
                    description VARCHAR,
                    user_id VARCHAR,
                    agent_name VARCHAR,
                    metadata VARCHAR,
                    severity VARCHAR,
                    created_at TIMESTAMP
                )
            """)
        except Exception as exc:
            logger.debug("[EventLog] DuckDB init skipped: %s", exc)

    def log(
        self,
        event_type: str,
        source: str,
        description: str,
        user_id: str | None = None,
        agent_name: str | None = None,
        metadata: dict[str, Any] | None = None,
        severity: str = "info",
    ) -> int:
        """Dodaj wpis do logu zdarzeń.

        Args:
            event_type: Typ zdarzenia (np. decision.approved, invoice.processed)
            source: Źródło zdarzenia (np. decision_queue, scheduler)
            description: Opis zdarzenia
            user_id: ID użytkownika (opcjonalny)
            agent_name: Nazwa komponentu źródłowego (opcjonalny)
            metadata: Dodatkowe dane w formacie JSON
            severity: Poziom ważności (info, warning, error)

        Returns:
            ID utworzonego wpisu
        """
        now = pendulum.now("UTC").isoformat()
        metadata_json = msgspec_dumps(metadata or {})

        with self._engine.begin() as conn:
            result = conn.execute(
                text(
                    """INSERT INTO event_log
                       (event_type, source, description, user_id, agent_name,
                        metadata, severity, created_at)
                       VALUES (:event_type, :source, :description, :user_id, :agent_name,
                               :metadata, :severity, :created_at)"""
                ),
                {
                    "event_type": event_type,
                    "source": source,
                    "description": description,
                    "user_id": user_id,
                    "agent_name": agent_name,
                    "metadata": metadata_json,
                    "severity": severity,
                    "created_at": now,
                },
            )
            event_id = int(result.lastrowid)

        # Równolegle zapisz do DuckDB jeśli dostępny
        if self._duckdb:
            try:
                self._duckdb.execute(
                    """INSERT INTO event_log_analytics
                       (id, event_type, source, description, user_id,
                        agent_name, metadata, severity, created_at)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?::TIMESTAMP)""",
                    (
                        event_id,
                        event_type,
                        source,
                        description,
                        user_id,
                        agent_name,
                        metadata_json,
                        severity,
                        now,
                    ),
                )
            except Exception as exc:
                logger.debug("[EventLog] DuckDB insert skipped: %s", exc)

        logger.debug(
            "[EventLog] logged id=%d type=%s source=%s severity=%s",
            event_id,
            event_type,
            source,
            severity,
        )
        return event_id

    def query(
        self,
        event_type: str | None = None,
        source: str | None = None,
        user_id: str | None = None,
        severity: str | None = None,
        agent_name: str | None = None,
        limit: int = 100,
        since: str | None = None,
        until: str | None = None,
    ) -> list[dict[str, Any]]:
        """Przeszukaj log zdarzeń z opcjonalnymi filtrami.

        Używa DuckDB jeśli dostępny (szybsze zapytania),
        w przeciwnym razie główna baza SQLAlchemy.
        """
        # Prefer DuckDB dla zapytań analitycznych
        if self._duckdb and (event_type or source or severity):
            return self._query_duckdb(
                event_type=event_type,
                source=source,
                user_id=user_id,
                severity=severity,
                agent_name=agent_name,
                limit=limit,
                since=since,
                until=until,
            )

        return self._query_sql(
            event_type=event_type,
            source=source,
            user_id=user_id,
            severity=severity,
            agent_name=agent_name,
            limit=limit,
            since=since,
            until=until,
        )

    def _query_sql(
        self,
        event_type: str | None,
        source: str | None,
        user_id: str | None,
        severity: str | None,
        agent_name: str | None,
        limit: int,
        since: str | None,
        until: str | None,
    ) -> list[dict[str, Any]]:
        with self._engine.connect() as conn:
            query = "SELECT * FROM event_log WHERE 1=1"
            params: dict[str, Any] = {}

            if event_type:
                query += " AND event_type = :event_type"
                params["event_type"] = event_type
            if source:
                query += " AND source = :source"
                params["source"] = source
            if user_id:
                query += " AND user_id = :user_id"
                params["user_id"] = user_id
            if severity:
                query += " AND severity = :severity"
                params["severity"] = severity
            if agent_name:
                query += " AND agent_name = :agent_name"
                params["agent_name"] = agent_name
            if since:
                query += " AND created_at >= :since"
                params["since"] = since
            if until:
                query += " AND created_at <= :until"
                params["until"] = until

            query += " ORDER BY created_at DESC LIMIT :limit"
            params["limit"] = limit

            rows = conn.execute(text(query), params).mappings().all()
            result = []
            for row in rows:
                row_dict = dict(row)
                if isinstance(row_dict.get("metadata"), str):
                    try:
                        row_dict["metadata"] = msgspec_loads(row_dict["metadata"])
                    except Exception:
                        pass
                result.append(row_dict)
            return result

    def _query_duckdb(
        self,
        event_type: str | None,
        source: str | None,
        user_id: str | None,
        severity: str | None,
        agent_name: str | None,
        limit: int,
        since: str | None,
        until: str | None,
    ) -> list[dict[str, Any]]:
        if not self._duckdb:
            return self._query_sql(
                event_type, source, user_id, severity, agent_name, limit, since, until
            )

        try:
            query = "SELECT * FROM event_log_analytics WHERE 1=1"
            params: list[Any] = []

            if event_type:
                query += " AND event_type = ?"
                params.append(event_type)
            if source:
                query += " AND source = ?"
                params.append(source)
            if user_id:
                query += " AND user_id = ?"
                params.append(user_id)
            if severity:
                query += " AND severity = ?"
                params.append(severity)
            if agent_name:
                query += " AND agent_name = ?"
                params.append(agent_name)
            if since:
                query += " AND created_at >= ?::TIMESTAMP"
                params.append(since)
            if until:
                query += " AND created_at <= ?::TIMESTAMP"
                params.append(until)

            query += " ORDER BY created_at DESC LIMIT ?"
            params.append(limit)

            rows = self._duckdb.execute(query, params)
            if not rows:
                return []

            result = []
            for row in rows:
                row_dict = {
                    "id": row[0],
                    "event_type": str(row[1]) if row[1] else "",
                    "source": str(row[2]) if row[2] else "",
                    "description": str(row[3]) if row[3] else "",
                    "user_id": str(row[4]) if row[4] else None,
                    "agent_name": str(row[5]) if row[5] else None,
                    "metadata": msgspec_loads(str(row[6])) if row[6] else {},
                    "severity": str(row[7]) if row[7] else "info",
                    "created_at": str(row[8]) if row[8] else "",
                }
                result.append(row_dict)
            return result
        except Exception as exc:
            logger.debug("[EventLog] DuckDB query failed, falling back to SQL: %s", exc)
            return self._query_sql(
                event_type, source, user_id, severity, agent_name, limit, since, until
            )

    def get_stats(
        self,
        days: int = 30,
    ) -> dict[str, Any]:
        """Zwróć statystyki zdarzeń z ostatnich N dni.

        - ``execute_arrow()`` + ``pl.from_arrow()" -- zero-copy z DuckDB
        - ``pl.DataFrame.group_by()" zamiast ``GROUP BY`` w SQL
        - ``pl.col().count().sort()" -- czytelniejsze niż ``ORDER BY cnt DESC``
        - ``shrink_dtype()" dla oszczędności RAM
        """
        since = pendulum.now("UTC").subtract(days=days).isoformat()

        if self._duckdb:
            try:
                import polars as pl

                arrow_table = self._duckdb.execute_arrow(
                    "SELECT event_type, source, severity, created_at "
                    "FROM event_log_analytics WHERE created_at >= ?::TIMESTAMP",
                    (since,),
                )

                if arrow_table is None or arrow_table.num_rows == 0:
                    return {
                        "period_days": days,
                        "total": 0,
                        "by_type": {},
                        "by_severity": {},
                        "by_source": {},
                    }

                df = pl.from_arrow(arrow_table)

                total = df.height
                by_type = (
                    df.group_by("event_type")
                    .agg(pl.len().alias("cnt"))
                    .sort("cnt", descending=True)
                )
                by_severity = (
                    df.group_by("severity").agg(pl.len().alias("cnt")).sort("cnt", descending=True)
                )
                by_source = (
                    df.group_by("source").agg(pl.len().alias("cnt")).sort("cnt", descending=True)
                )

                by_type = by_type.shrink_dtype()
                by_severity = by_severity.shrink_dtype()

                return {
                    "period_days": days,
                    "total": total,
                    "by_type": dict(by_type.rows()),
                    "by_severity": dict(by_severity.rows()),
                    "by_source": dict(by_source.rows()),
                }
            except Exception:
                pass

        # Fallback do SQLAlchemy
        with self._engine.connect() as conn:
            total = int(
                conn.execute(
                    text("SELECT COUNT(*) FROM event_log WHERE created_at >= :since"),
                    {"since": since},
                ).scalar()
                or 0
            )

            rows = (
                conn.execute(
                    text(
                        "SELECT event_type, COUNT(*) as cnt FROM event_log "
                        "WHERE created_at >= :since GROUP BY event_type ORDER BY cnt DESC"
                    ),
                    {"since": since},
                )
                .mappings()
                .all()
            )

            return {
                "period_days": days,
                "total": total,
                "by_type": {r["event_type"]: r["cnt"] for r in rows},
            }

    def get_by_reference(self, reference_type: str, reference_id: str) -> list[dict[str, Any]]:
        """Znajdź zdarzenia powiązane z konkretną referencją."""
        return self.query(
            source=reference_type,
            limit=50,
        )

    def clean_old(self, days: int = 90) -> int:
        """Usuń wpisy starsze niż N dni.

        Returns:
            Liczba usuniętych wpisów.
        """
        cutoff = pendulum.now("UTC").subtract(days=days).isoformat()
        with self._engine.begin() as conn:
            result = conn.execute(
                text("DELETE FROM event_log WHERE created_at < :cutoff"),
                {"cutoff": cutoff},
            )
            deleted = result.rowcount
        if deleted:
            logger.info("[EventLog] cleaned %d old entries (>%d days)", deleted, days)
        return deleted
