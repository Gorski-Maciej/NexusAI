"""
core/taskiq_result_backend.py — SQLite-based Taskiq Result Backend.

SUPERMOC TASKIQ:
  - Przechowuje wyniki wszystkich zadań w SQLite
  - Umożliwia: audit trail, monitorowanie, task.get_result()
  - Zastępuje: ręczne zapisywanie wyników do tabel
  - Integracja z OpenTelemetry dla metryk

Usage:
    from nexus_ai.core.taskiq_result_backend import SqliteResultBackend

    backend = SqliteResultBackend(db_path="app_data/task_results.db")
    broker = PullBasedJetStreamBroker(..., result_backend=backend)
"""

from __future__ import annotations

import json
import sqlite3
import threading
from pathlib import Path
from typing import Any

import pendulum
from taskiq.result import TaskiqResult, TaskiqResultBackend
from structlog import get_logger

logger = get_logger("nexus.taskiq.result_backend")


class SqliteResultBackend(TaskiqResultBackend):
    """Taskiq Result Backend przechowujący wyniki w SQLite.

    SUPERMOC: Każde zadanie ma swój wynik zapisany w SQLite:
      - task_id, task_name, status, return_value, error, execution_time
      - Timestamp rozpoczęcia i zakończenia
      - Możliwość query: SELECT * FROM taskiq_results WHERE status = 'FAILED'

    Thread-safe dla free-threaded Python 3.13t.
    """

    def __init__(self, db_path: str | Path) -> None:
        self._db_path = Path(db_path)
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()
        self._conn: sqlite3.Connection | None = None
        self._ensure_schema()

    def _get_conn(self) -> sqlite3.Connection:
        """Zwróć połączenie SQLite (lazy init, thread-safe)."""
        if self._conn is None:
            self._conn = sqlite3.connect(str(self._db_path), check_same_thread=False)
            self._conn.row_factory = sqlite3.Row
        return self._conn

    def _ensure_schema(self) -> None:
        """Utwórz tabelę wyników jeśli nie istnieje."""
        conn = self._get_conn()
        conn.execute("""
            CREATE TABLE IF NOT EXISTS taskiq_results (
                task_id         TEXT PRIMARY KEY,
                task_name       TEXT NOT NULL,
                status          TEXT NOT NULL DEFAULT 'PENDING',
                return_value    TEXT,
                error           TEXT,
                execution_time_ms REAL,
                started_at      TEXT,
                finished_at     TEXT,
                labels_json     TEXT,
                created_at      TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_taskiq_results_status
            ON taskiq_results(status)
        """)
        conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_taskiq_results_task_name
            ON taskiq_results(task_name)
        """)
        conn.commit()

    async def set_result(
        self,
        task_id: str,
        result: TaskiqResult,
    ) -> None:
        """Zapisz wynik zadania do SQLite.

        SUPERMOC: Taskiq wywołuje to automatycznie po wykonaniu zadania.
        """
        with self._lock:
            conn = self._get_conn()
            try:
                conn.execute(
                    """INSERT OR REPLACE INTO taskiq_results
                       (task_id, task_name, status, return_value, error,
                        execution_time_ms, started_at, finished_at, labels_json)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (
                        task_id,
                        result.task_name or "",
                        "SUCCESS" if result.is_err is False else "FAILED" if result.is_err else "UNKNOWN",
                        json.dumps(result.return_value) if result.return_value is not None else None,
                        str(result.error) if result.error else None,
                        result.execution_time,
                        result.started_at.isoformat() if result.started_at else None,
                        result.finished_at.isoformat() if result.finished_at else None,
                        json.dumps(result.labels) if result.labels else None,
                    ),
                )
                conn.commit()
            except Exception as exc:
                logger.warning(
                    "[RESULT-BACKEND] Failed to save result for task_id=%s: %s",
                    task_id, exc,
                )

    async def is_result_exists(self, task_id: str) -> bool:
        """Sprawdź czy wynik już istnieje."""
        with self._lock:
            conn = self._get_conn()
            row = conn.execute(
                "SELECT 1 FROM taskiq_results WHERE task_id = ?",
                (task_id,),
            ).fetchone()
            return row is not None

    async def get_result(self, task_id: str, with_logs: bool = False) -> TaskiqResult | None:
        """Pobierz wynik zadania z SQLite.

        Args:
            task_id: ID zadania.
            with_logs: Czy dołączyć logi (nieobsługiwane w SQLite).

        Returns:
            TaskiqResult lub None jeśli nie znaleziono.
        """
        with self._lock:
            conn = self._get_conn()
            row = conn.execute(
                """SELECT task_id, task_name, status, return_value, error,
                          execution_time_ms, started_at, finished_at, labels_json
                   FROM taskiq_results
                   WHERE task_id = ?""",
                (task_id,),
            ).fetchone()

        if row is None:
            return None

        return TaskiqResult(
            task_id=str(row["task_id"]),
            task_name=str(row["task_name"]),
            is_err=row["status"] == "FAILED",
            return_value=json.loads(row["return_value"]) if row["return_value"] else None,
            error=Exception(row["error"]) if row["error"] else None,
            execution_time=float(row["execution_time_ms"]) if row["execution_time_ms"] else 0.0,
            labels=json.loads(row["labels_json"]) if row["labels_json"] else {},
        )

    async def get_results_by_status(self, status: str, limit: int = 100) -> list[dict[str, Any]]:
        """Pobierz wyniki zadań według statusu.

        SUPERMOC: Pozwala na monitoring i dashboard bezpośrednio z Taskiq.
        """
        with self._lock:
            conn = self._get_conn()
            rows = conn.execute(
                """SELECT task_id, task_name, status, return_value, error,
                          execution_time_ms, started_at, finished_at, created_at
                   FROM taskiq_results
                   WHERE status = ?
                   ORDER BY created_at DESC
                   LIMIT ?""",
                (status, limit),
            ).fetchall()

        return [dict(row) for row in rows]

    async def close(self) -> None:
        """Zamknij połączenie SQLite."""
        if self._conn is not None:
            try:
                self._conn.close()
            except Exception:
                pass
            self._conn = None
        logger.debug("[RESULT-BACKEND] Closed SQLite connection")

    async def is_healthy(self) -> bool:
        """Sprawdź czy backend jest dostępny."""
        try:
            conn = self._get_conn()
            conn.execute("SELECT 1")
            return True
        except Exception:
            return False


# =========================================================================
# HybridResultBackend — NATSObjectStore + SQLite fallback
# =========================================================================


class HybridResultBackend(TaskiqResultBackend):
    """Hybrid result backend: próbuje NATS Object Store, fallback do SQLite.

    SUPERMOC NATS:
      - Wyniki zadań przechowywane w NATS Object Store (szybsze, rozproszone)
      - Automatyczny fallback do SQLite gdy NATS niedostępny
      - Dla środowisk z NATS: zero dodatkowej konfiguracji
      - Dla środowisk bez NATS: przezroczysty fallback

    Usage:
        from nexus_ai.core.taskiq_result_backend import HybridResultBackend

        backend = HybridResultBackend(
            sqlite_path="app_data/task_results.db",
            nats_servers=["nats://localhost:4222"],
        )
        broker = PullBasedJetStreamBroker(..., result_backend=backend)
    """

    def __init__(
        self,
        sqlite_path: str | Path,
        nats_servers: list[str] | None = None,
        bucket_name: str = "nexus-task-results",
    ) -> None:
        self._sqlite = SqliteResultBackend(sqlite_path)
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._bucket_name = bucket_name
        self._nc: Any = None  # nats connection
        self._js: Any = None  # jetstream context
        self._obj_store: Any = None  # object store

    async def _ensure_nats(self) -> bool:
        """Próbuje połączyć się z NATS Object Store."""
        if self._obj_store is not None:
            try:
                await self._nc.ping()
                return True
            except Exception:
                self._obj_store = None
        try:
            import nats
            self._nc = await nats.connect(servers=self._nats_servers, connect_timeout=2.0)
            self._js = self._nc.jetstream()
            try:
                self._obj_store = await self._js.create_object_store(bucket=self._bucket_name)
            except Exception:
                self._obj_store = await self._js.object_store(bucket=self._bucket_name)
            return True
        except Exception:
            self._obj_store = None
            self._nc = None
            self._js = None
            return False

    async def set_result(self, task_id: str, result: TaskiqResult) -> None:
        """Zapisz wynik — próbuje NATS Object Store, fallback do SQLite."""
        try:
            if await self._ensure_nats():
                data = json.dumps({
                    "task_id": task_id,
                    "task_name": result.task_name or "",
                    "is_err": result.is_err,
                    "return_value": result.return_value,
                    "error": str(result.error) if result.error else None,
                    "execution_time": result.execution_time,
                    "started_at": result.started_at.isoformat() if result.started_at else None,
                    "finished_at": result.finished_at.isoformat() if result.finished_at else None,
                    "labels": result.labels,
                }).encode()
                await self._obj_store.put(task_id, data)
                return
        except Exception:
            pass
        # Fallback do SQLite
        await self._sqlite.set_result(task_id, result)

    async def is_result_exists(self, task_id: str) -> bool:
        """Sprawdź czy wynik istnieje — najpierw NATS, fallback SQLite."""
        try:
            if await self._ensure_nats():
                try:
                    await self._obj_store.get(task_id)
                    return True
                except Exception:
                    pass
        except Exception:
            pass
        return await self._sqlite.is_result_exists(task_id)

    async def get_result(self, task_id: str, with_logs: bool = False) -> TaskiqResult | None:
        """Pobierz wynik — najpierw NATS, fallback SQLite."""
        try:
            if await self._ensure_nats():
                try:
                    entry = await self._obj_store.get(task_id)
                    data = json.loads(entry.data)
                    return TaskiqResult(
                        task_id=data["task_id"],
                        task_name=data.get("task_name", ""),
                        is_err=data.get("is_err", False),
                        return_value=data.get("return_value"),
                        error=Exception(data["error"]) if data.get("error") else None,
                        execution_time=data.get("execution_time", 0.0),
                        labels=data.get("labels", {}),
                    )
                except Exception:
                    pass
        except Exception:
            pass
        return await self._sqlite.get_result(task_id, with_logs=with_logs)

    async def close(self) -> None:
        """Zamknij backend — NATS + SQLite."""
        if self._nc is not None:
            try:
                await self._nc.drain()
                await self._nc.close()
            except Exception:
                pass
            self._nc = None
            self._js = None
            self._obj_store = None
        await self._sqlite.close()
