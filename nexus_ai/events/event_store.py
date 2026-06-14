"""
EventStore — append-only event store backed by SQLite.

Przechowuje zdarzenia w tabeli ``event_stream`` jako append-only log.
Wspiera:
  - Zapis wielu eventów w jednej transakcji (batch append)
  - Optimistic concurrency (expected_version)
  - Odczyty strumienia dla konkretnego agregatu
  - Snapshoty dla szybkiego odbudowy stanu
  - Checkpointy dla projekcji CQRS
"""

from __future__ import annotations

import json
import sqlite3
import time
from pathlib import Path
from typing import Any

from structlog import get_logger

from nexus_ai.events.domain_events import (
    DomainEvent,
    domain_event_from_dict,
    encode_event,
)

logger = get_logger("nexus.events.store")


class EventStore:
    """Append-only event store backed by SQLite.

    Args:
        db_path: Ścieżka do pliku SQLite.
    """

    def __init__(self, db_path: str | Path) -> None:
        self._db_path = Path(db_path)
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._conn: sqlite3.Connection | None = None
        self._ensure_schema()

    # ── Schema ─────────────────────────────────────────────────────────

    def _ensure_schema(self) -> None:
        conn = self._get_conn()
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS event_stream (
                event_id         TEXT PRIMARY KEY,
                aggregate_type   TEXT NOT NULL,
                aggregate_id     TEXT NOT NULL,
                event_type       TEXT NOT NULL,
                version          INTEGER NOT NULL,
                timestamp        TEXT NOT NULL,
                data             BLOB NOT NULL,
                metadata_json    TEXT NOT NULL DEFAULT '{}',
                created_at       TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE INDEX IF NOT EXISTS idx_events_aggregate
                ON event_stream(aggregate_type, aggregate_id, version);

            CREATE INDEX IF NOT EXISTS idx_events_type
                ON event_stream(event_type, timestamp);

            CREATE INDEX IF NOT EXISTS idx_events_timestamp
                ON event_stream(timestamp);

            CREATE TABLE IF NOT EXISTS snapshots (
                aggregate_id     TEXT NOT NULL,
                aggregate_type   TEXT NOT NULL,
                version          INTEGER NOT NULL,
                state_json       TEXT NOT NULL,
                timestamp        TEXT NOT NULL,
                PRIMARY KEY (aggregate_id, aggregate_type)
            );

            CREATE TABLE IF NOT EXISTS projection_checkpoints (
                projection_name  TEXT PRIMARY KEY,
                last_event_id    TEXT,
                last_version     INTEGER NOT NULL DEFAULT 0,
                updated_at       TEXT NOT NULL
            );
        """)
        conn.commit()

    # ── Connection management ──────────────────────────────────────────

    def _get_conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(str(self._db_path))
            self._conn.row_factory = sqlite3.Row
            self._conn.execute("PRAGMA journal_mode=WAL")
            self._conn.execute("PRAGMA synchronous=NORMAL")
            self._conn.execute("PRAGMA cache_size = -51200")    # 200MB cache
            self._conn.execute("PRAGMA temp_store = MEMORY")    # Temp tables w RAM
            self._conn.execute("PRAGMA mmap_size = 4294967296") # 4GB mmap I/O
            self._conn.execute("PRAGMA foreign_keys = ON")      # Wymuś FK
            self._conn.execute("PRAGMA application_id = 1313827925")  # NEXU
        return self._conn

    def close(self) -> None:
        if self._conn is not None:
            self._conn.close()
            self._conn = None

    # ── Write operations ───────────────────────────────────────────────

    @staticmethod
    def _dbg_trace(
        method: str, aggregate_type: str, aggregate_id: str, version: int | None = None
    ) -> None:
        """Emit OTel span dla operacji EventStore."""
        from nexus_ai.core.otel_tracing import buffer_span

        buffer_span(
            trace_id=aggregate_id,
            name=f"event_store.{method}",
            duration_ms=0,
            attributes={
                "aggregate_type": aggregate_type,
                "aggregate_id": aggregate_id,
                "version": version if version is not None else 0,
            },
        )

    def append_events(
        self,
        aggregate_type: str,
        aggregate_id: str,
        events: list[DomainEvent],
        expected_version: int | None = None,
    ) -> list[str]:
        """Zapisz eventy do strumienia w jednej transakcji.

        Args:
            aggregate_type: Typ agregatu (np. "invoice", "decision").
            aggregate_id: ID agregatu.
            events: Lista eventów do zapisania.
            expected_version: Oczekiwana wersja agregatu (optimistic concurrency).
                              ``None`` = pomiń walidację wersji.

        Returns:
            Lista ID zapisanych eventów.

        Raises:
            ValueError: Gdy expected_version nie zgadza się z aktualną wersją.
        """
        conn = self._get_conn()
        event_ids: list[str] = []

        with conn:  # transactional
            # Sprawdź optimistic concurrency
            if expected_version is not None:
                current = conn.execute(
                    "SELECT COALESCE(MAX(version), 0) FROM event_stream "
                    "WHERE aggregate_type = ? AND aggregate_id = ?",
                    (aggregate_type, aggregate_id),
                ).fetchone()[0]
                if current != expected_version:
                    raise ValueError(
                        f"Optimistic concurrency violation: "
                        f"expected version {expected_version}, "
                        f"current version {current} "
                        f"(aggregate={aggregate_type}:{aggregate_id})"
                    )

            for event in events:
                event_data = encode_event(event)
                metadata_json = json.dumps(event.metadata)
                conn.execute(
                    """INSERT INTO event_stream
                       (event_id, aggregate_type, aggregate_id, event_type,
                        version, timestamp, data, metadata_json)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        event.event_id,
                        aggregate_type,
                        aggregate_id,
                        event.event_type,
                        event.version,
                        event.timestamp,
                        event_data,
                        metadata_json,
                    ),
                )
                event_ids.append(event.event_id)

            if event_ids:
                logger.info(
                    "[EVENT-STORE] Appended %d events to %s:%s (version=%d)",
                    len(events),
                    aggregate_type,
                    aggregate_id,
                    events[-1].version,
                )

        return event_ids

    # ── Read operations ────────────────────────────────────────────────

    def read_events(
        self,
        aggregate_type: str,
        aggregate_id: str,
        from_version: int = 0,
        to_version: int | None = None,
        limit: int = 1000,
    ) -> list[DomainEvent]:
        """Odczytaj eventy dla konkretnego agregatu.

        Args:
            aggregate_type: Typ agregatu.
            aggregate_id: ID agregatu.
            from_version: Minimalna wersja (inkluzywnie).
            to_version: Maksymalna wersja (inkluzywnie). ``None`` = bez limitu.
            limit: Maksymalna liczba eventów.

        Returns:
            Lista eventów posortowanych po wersji rosnąco.
        """
        conn = self._get_conn()
        if to_version is not None:
            rows = conn.execute(
                """SELECT data FROM event_stream
                   WHERE aggregate_type = ? AND aggregate_id = ?
                     AND version >= ? AND version <= ?
                   ORDER BY version ASC LIMIT ?""",
                (aggregate_type, aggregate_id, from_version, to_version, limit),
            ).fetchall()
        else:
            rows = conn.execute(
                """SELECT data FROM event_stream
                   WHERE aggregate_type = ? AND aggregate_id = ?
                     AND version >= ?
                   ORDER BY version ASC LIMIT ?""",
                (aggregate_type, aggregate_id, from_version, limit),
            ).fetchall()

        return [domain_event_from_dict(json.loads(row["data"])) for row in rows]

    def read_events_by_type(
        self,
        event_type: str,
        since: str | None = None,
        limit: int = 100,
    ) -> list[DomainEvent]:
        """Odczytaj eventy po typie (dla projekcji).

        Args:
            event_type: Typ eventu (np. "invoice.created").
                       Pusty string = wszystkie typy.
            since: Timestamp ISO 8601 — tylko eventy po tej dacie.
            limit: Maksymalna liczba eventów.

        Returns:
            Lista eventów.
        """
        conn = self._get_conn()
        if event_type and since:
            rows = conn.execute(
                """SELECT data FROM event_stream
                   WHERE event_type = ? AND timestamp >= ?
                   ORDER BY timestamp ASC LIMIT ?""",
                (event_type, since, limit),
            ).fetchall()
        elif event_type:
            rows = conn.execute(
                """SELECT data FROM event_stream
                   WHERE event_type = ?
                   ORDER BY timestamp ASC LIMIT ?""",
                (event_type, limit),
            ).fetchall()
        elif since:
            rows = conn.execute(
                """SELECT data FROM event_stream
                   WHERE timestamp >= ?
                   ORDER BY timestamp ASC LIMIT ?""",
                (since, limit),
            ).fetchall()
        else:
            rows = conn.execute(
                """SELECT data FROM event_stream
                   ORDER BY timestamp ASC LIMIT ?""",
                (limit,),
            ).fetchall()

        return [domain_event_from_dict(json.loads(row["data"])) for row in rows]

    def read_stream(
        self,
        aggregate_type: str,
        aggregate_id: str,
    ) -> list[DomainEvent]:
        """Odczytaj pełny strumień eventów dla agregatu.

        Args:
            aggregate_type: Typ agregatu.
            aggregate_id: ID agregatu.

        Returns:
            Pełna historia eventów.
        """
        return self.read_events(aggregate_type, aggregate_id, from_version=0)

    def get_version(self, aggregate_type: str, aggregate_id: str) -> int:
        """Pobierz aktualną wersję agregatu.

        Args:
            aggregate_type: Typ agregatu.
            aggregate_id: ID agregatu.

        Returns:
            Numer wersji (0 = agregat nie istnieje).
        """
        conn = self._get_conn()
        result = conn.execute(
            "SELECT COALESCE(MAX(version), 0) FROM event_stream "
            "WHERE aggregate_type = ? AND aggregate_id = ?",
            (aggregate_type, aggregate_id),
        ).fetchone()[0]
        return int(result)

    def read_events_since_version(
        self,
        aggregate_type: str,
        from_version: int = 0,
        limit: int = 500,
    ) -> list[DomainEvent]:
        """Odczytaj eventy dla danego typu agregatu od określonej wersji.

        Używane przez projekcje CQRS do czytania wszystkich eventów
        danego typu (np. wszystkie invoice.* eventy) od ostatniego
        checkpointu.

        Args:
            aggregate_type: Typ agregatu (np. "invoice", "decision").
            from_version: Minimalna wersja (inkluzywnie).
            limit: Maksymalna liczba eventów.

        Returns:
            Lista eventów posortowanych po wersji.
        """
        conn = self._get_conn()
        rows = conn.execute(
            """SELECT data FROM event_stream
               WHERE aggregate_type = ? AND version >= ?
               ORDER BY version ASC LIMIT ?""",
            (aggregate_type, from_version, limit),
        ).fetchall()

        return [domain_event_from_dict(json.loads(row["data"])) for row in rows]

    def count_events(
        self,
        aggregate_type: str | None = None,
        event_type: str | None = None,
    ) -> int:
        """Policz eventy (opcjonalnie filtrowane).

        Args:
            aggregate_type: Opcjonalny filtr po typie agregatu.
            event_type: Opcjonalny filtr po typie eventu.

        Returns:
            Liczba eventów.
        """
        conn = self._get_conn()
        if aggregate_type and event_type:
            result = conn.execute(
                "SELECT COUNT(*) FROM event_stream WHERE aggregate_type = ? AND event_type = ?",
                (aggregate_type, event_type),
            ).fetchone()[0]
        elif aggregate_type:
            result = conn.execute(
                "SELECT COUNT(*) FROM event_stream WHERE aggregate_type = ?",
                (aggregate_type,),
            ).fetchone()[0]
        elif event_type:
            result = conn.execute(
                "SELECT COUNT(*) FROM event_stream WHERE event_type = ?",
                (event_type,),
            ).fetchone()[0]
        else:
            result = conn.execute("SELECT COUNT(*) FROM event_stream").fetchone()[0]
        return int(result)

    # ── Snapshots ──────────────────────────────────────────────────────

    def save_snapshot(
        self,
        aggregate_type: str,
        aggregate_id: str,
        version: int,
        state: dict[str, Any],
    ) -> None:
        """Zapisz snapshot stanu agregatu.

        Snapshoty pozwalają szybko odbudować stan agregatu bez replayu
        wszystkich eventów od początku.

        Args:
            aggregate_type: Typ agregatu.
            aggregate_id: ID agregatu.
            version: Wersja agregatu (musi zgadzać się z ostatnim eventem).
            state: Stan agregatu (JSON-serializowalny).
        """
        conn = self._get_conn()
        conn.execute(
            """INSERT OR REPLACE INTO snapshots
               (aggregate_id, aggregate_type, version, state_json, timestamp)
               VALUES (?, ?, ?, ?, ?)""",
            (
                aggregate_id,
                aggregate_type,
                version,
                json.dumps(state),
                pendulum_now(),
            ),
        )
        conn.commit()
        logger.debug(
            "[EVENT-STORE] Snapshot saved for %s:%s (version=%d)",
            aggregate_type,
            aggregate_id,
            version,
        )

    def load_snapshot(
        self,
        aggregate_type: str,
        aggregate_id: str,
    ) -> tuple[int, dict[str, Any]] | None:
        """Wczytaj snapshot stanu agregatu.

        Args:
            aggregate_type: Typ agregatu.
            aggregate_id: ID agregatu.

        Returns:
            ``(version, state_dict)`` lub ``None`` jeśli snapshot nie istnieje.
        """
        conn = self._get_conn()
        row = conn.execute(
            "SELECT version, state_json FROM snapshots "
            "WHERE aggregate_id = ? AND aggregate_type = ?",
            (aggregate_id, aggregate_type),
        ).fetchone()
        if row is None:
            return None
        return int(row["version"]), json.loads(row["state_json"])

    # ── Projection checkpoints ─────────────────────────────────────────

    def get_checkpoint(self, projection_name: str) -> int:
        """Pobierz ostatni wersję checkpoint dla projekcji.

        Args:
            projection_name: Nazwa projekcji.

        Returns:
            Ostatnia przetworzona wersja (0 = brak checkpointu).
        """
        conn = self._get_conn()
        row = conn.execute(
            "SELECT last_version FROM projection_checkpoints WHERE projection_name = ?",
            (projection_name,),
        ).fetchone()
        return int(row["last_version"]) if row else 0

    def update_checkpoint(
        self,
        projection_name: str,
        last_event_id: str,
        last_version: int,
    ) -> None:
        """Zaktualizuj checkpoint dla projekcji.

        Args:
            projection_name: Nazwa projekcji.
            last_event_id: ID ostatniego przetworzonego eventu.
            last_version: Numer wersji ostatniego przetworzonego eventu.
        """
        conn = self._get_conn()
        conn.execute(
            """INSERT OR REPLACE INTO projection_checkpoints
               (projection_name, last_event_id, last_version, updated_at)
               VALUES (?, ?, ?, ?)""",
            (projection_name, last_event_id, last_version, pendulum_now()),
        )
        conn.commit()

    def list_projections(self) -> list[dict[str, Any]]:
        """Zwróć listę wszystkich projekcji z ich checkpointami.

        Returns:
            Lista słowników: projection_name, last_event_id, last_version, updated_at.
        """
        conn = self._get_conn()
        rows = conn.execute(
            "SELECT projection_name, last_event_id, last_version, updated_at "
            "FROM projection_checkpoints ORDER BY projection_name"
        ).fetchall()
        return [dict(r) for r in rows]

    # ── Stats ──────────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        """Zwróć statystyki EventStore.

        Returns:
            Słownik z liczbą eventów, snapshotów i projekcji.
        """
        conn = self._get_conn()
        total_events = conn.execute("SELECT COUNT(*) FROM event_stream").fetchone()[0]
        total_snapshots = conn.execute("SELECT COUNT(*) FROM snapshots").fetchone()[0]
        total_projections = conn.execute("SELECT COUNT(*) FROM projection_checkpoints").fetchone()[
            0
        ]
        aggregates = conn.execute(
            "SELECT aggregate_type, COUNT(DISTINCT aggregate_id) as cnt "
            "FROM event_stream GROUP BY aggregate_type"
        ).fetchall()

        return {
            "total_events": int(total_events),
            "total_snapshots": int(total_snapshots),
            "total_projections": int(total_projections),
            "aggregates": {r["aggregate_type"]: int(r["cnt"]) for r in aggregates},
        }


# ── Helper ────────────────────────────────────────────────────────────────


def pendulum_now() -> str:
    """Zwróć aktualny timestamp ISO 8601."""
    import pendulum

    return pendulum.now("UTC").isoformat()
