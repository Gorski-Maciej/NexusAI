"""EventLog — historia wszystkich zdarzeń i podjętych decyzji.

Zgodnie z aa3fvcx.txt (Punkt 26): historia wszystkich zdarzeń i podjętych
decyzji, przeszukiwalna dla systemu analitycznego (DuckDB).

Storage: DuckDB dla wydajnych zapytań OLAP.
Fallback: SQLite gdy DuckDB niedostępny.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

logger = get_logger("nexus.services.event_log")


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
    """

    def __init__(
        self,
        db_path: Path | str | None = None,
        duckdb_manager: Any = None,
    ) -> None:
        self._db_path = Path(db_path) if db_path else Path("app_data/event_log.db")
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._duckdb = duckdb_manager
        self._init_schema()

    def _init_schema(self) -> None:
        """Inicjalizuj schemat — SQLite dla trwałości + DuckDB dla analityki."""
        conn = self._sqlite_conn()
        try:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS event_log (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    event_type TEXT NOT NULL,
                    source TEXT NOT NULL DEFAULT '',
                    description TEXT NOT NULL DEFAULT '',
                    user_id TEXT,
                    agent_name TEXT,
                    metadata TEXT NOT NULL DEFAULT '{}',
                    severity TEXT NOT NULL DEFAULT 'info',
                    created_at TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS idx_event_type
                    ON event_log(event_type, created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_event_source
                    ON event_log(source, created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_event_user
                    ON event_log(user_id, created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_event_severity
                    ON event_log(severity, created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_event_created
                    ON event_log(created_at DESC);
            """)
            conn.commit()
        finally:
            conn.close()

        # Inicjalizuj DuckDB jeśli dostępny
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

    def _sqlite_conn(self):
        import sqlite3
        return sqlite3.connect(str(self._db_path))

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

        conn = self._sqlite_conn()
        try:
            cursor = conn.execute(
                """INSERT INTO event_log
                   (event_type, source, description, user_id, agent_name,
                    metadata, severity, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                (event_type, source, description, user_id, agent_name,
                 metadata_json, severity, now),
            )
            conn.commit()
            event_id = int(cursor.lastrowid)

            # Równolegle zapisz do DuckDB jeśli dostępny
            if self._duckdb:
                try:
                    self._duckdb.execute(
                        """INSERT INTO event_log_analytics
                           (id, event_type, source, description, user_id,
                            agent_name, metadata, severity, created_at)
                           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?::TIMESTAMP)""",
                        (event_id, event_type, source, description, user_id,
                         agent_name, metadata_json, severity, now),
                    )
                except Exception as exc:
                    logger.debug("[EventLog] DuckDB insert skipped: %s", exc)

            logger.debug(
                "[EventLog] logged id=%d type=%s source=%s severity=%s",
                event_id, event_type, source, severity,
            )
            return event_id
        finally:
            conn.close()

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
        w przeciwnym razie SQLite.
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

        return self._query_sqlite(
            event_type=event_type,
            source=source,
            user_id=user_id,
            severity=severity,
            agent_name=agent_name,
            limit=limit,
            since=since,
            until=until,
        )

    def _query_sqlite(
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
        import sqlite3
        conn = sqlite3.connect(str(self._db_path))
        conn.row_factory = sqlite3.Row

            query = "SELECT * FROM event_log WHERE 1=1"
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
                query += " AND created_at >= ?"
                params.append(since)
            if until:
                query += " AND created_at <= ?"
                params.append(until)

            query += " ORDER BY created_at DESC LIMIT ?"
            params.append(limit)

            rows = conn.execute(query, params).fetchall()
            result = []
            for row in rows:
                row_dict = dict(row)
                # Parsuj metadata JSON
                if isinstance(row_dict.get("metadata"), str):
                    try:
                        row_dict["metadata"] = msgspec_loads(row_dict["metadata"])
                    except Exception:
                        pass
                result.append(row_dict)
            return result
        finally:
            conn.close()

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
            return self._query_sqlite(
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
            logger.debug("[EventLog] DuckDB query failed, falling back to SQLite: %s", exc)
            return self._query_sqlite(
                event_type, source, user_id, severity, agent_name, limit, since, until
            )

    def get_stats(
        self,
        days: int = 30,
    ) -> dict[str, Any]:
        """Zwróć statystyki zdarzeń z ostatnich N dni."""
        since = pendulum.now("UTC").subtract(days=days).isoformat()

        # Użyj DuckDB dla agregacji jeśli dostępny
        if self._duckdb:
            try:
                total = self._duckdb.execute(
                    "SELECT COUNT(*) FROM event_log_analytics WHERE created_at >= ?::TIMESTAMP",
                    (since,),
                )
                by_type = self._duckdb.execute(
                    "SELECT event_type, COUNT(*) as cnt FROM event_log_analytics "
                    "WHERE created_at >= ?::TIMESTAMP GROUP BY event_type ORDER BY cnt DESC",
                    (since,),
                )
                by_severity = self._duckdb.execute(
                    "SELECT severity, COUNT(*) as cnt FROM event_log_analytics "
                    "WHERE created_at >= ?::TIMESTAMP GROUP BY severity ORDER BY cnt DESC",
                    (since,),
                )
                by_source = self._duckdb.execute(
                    "SELECT source, COUNT(*) as cnt FROM event_log_analytics "
                    "WHERE created_at >= ?::TIMESTAMP GROUP BY source ORDER BY cnt DESC",
                    (since,),
                )

                return {
                    "period_days": days,
                    "total": total[0][0] if total else 0,
                    "by_type": {str(r[0]): int(r[1]) for r in by_type} if by_type else {},
                    "by_severity": {str(r[0]): int(r[1]) for r in by_severity} if by_severity else {},
                    "by_source": {str(r[0]): int(r[1]) for r in by_source} if by_source else {},
                }
            except Exception:
                pass

        # Fallback do SQLite
        conn = self._sqlite_conn()
        try:
            total = conn.execute(
                "SELECT COUNT(*) FROM event_log WHERE created_at >= ?",
                (since,),
            ).fetchone()[0]

            rows_by_type = conn.execute(
                "SELECT event_type, COUNT(*) as cnt FROM event_log "
                "WHERE created_at >= ? GROUP BY event_type ORDER BY cnt DESC",
                (since,),
            ).fetchall()

            return {
                "period_days": days,
                "total": total,
                "by_type": {r[0]: r[1] for r in rows_by_type},
            }
        finally:
            conn.close()

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
        conn = self._sqlite_conn()
        try:
            cursor = conn.execute(
                "DELETE FROM event_log WHERE created_at < ?",
                (cutoff,),
            )
            conn.commit()
            deleted = cursor.rowcount
            if deleted:
                logger.info("[EventLog] cleaned %d old entries (>%d days)", deleted, days)
            return deleted
        finally:
            conn.close()
