"""
Taskiq -- consolidated module for NexusAI task queue.

Zastępuje 2 osobne pliki: taskiq_middleware.py, taskiq_result_backend.py.
Zachowuje pełną kompatybilność wsteczną przez shimy.
"""

from __future__ import annotations

import json as _json
import os
import re as _re
import sqlite3
import threading
import time
import uuid
from pathlib import Path
from typing import Any, final

import structlog as _structlog
from structlog import get_logger
from taskiq.abc.middleware import TaskiqMiddleware
from taskiq.message import TaskiqMessage
from taskiq.result import TaskiqResult, TaskiqResultBackend

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.core.msgspec_utils import msgspec_loads as _msgspec_loads

logger = get_logger("nexus.taskiq")

# ── PII patterns ─────────────────────────────────────────────────────
PII_PATTERNS = [
    (_re.compile(rb"\b\d{11}\b", _re.IGNORECASE), "NIP"),
    (_re.compile(rb"\b\d{10}\b", _re.IGNORECASE), "PESEL"),
    (_re.compile(rb"\b\d{9}\b", _re.IGNORECASE), "REGON"),
    (_re.compile(rb"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", _re.IGNORECASE), "EMAIL"),
]

# ═══════════════════════════════════════════════════════════════════════════
# MIDDLEWARE (z taskiq_middleware.py)
# ═══════════════════════════════════════════════════════════════════════════

class TaskMetricsMiddleware(TaskiqMiddleware):
    """Metryki OTel dla każdego zadania."""

    async def pre_execute(self, message: TaskiqMessage) -> None:
        message.labels["_started_at"] = str(time.time())
        message.labels["_trace_id"] = uuid.uuid4().hex[:16]

    async def post_execute(self, message: TaskiqMessage, result: TaskiqResult) -> None:
        if (start := message.labels.get("_started_at")):
            _record_task_metrics(message.task_name, (time.time() - float(start)) * 1000, "SUCCESS" if not result.is_err else "FAILED")

    async def on_error(self, message: TaskiqMessage, result: TaskiqResult) -> None:
        _record_task_metrics(message.task_name, 0, "FAILED")


class PiiScanMiddleware(TaskiqMiddleware):
    """Skanowanie PII w payloadach zadań."""

    def __init__(self, block_on_pii: bool = False) -> None:
        self._block_on_pii = block_on_pii

    async def pre_send(self, message: TaskiqMessage) -> TaskiqMessage:
        findings = [(p, t) for p, t in PII_PATTERNS if p.search(str(message.args) + str(message.kwargs))]
        if findings:
            message.labels["_pii_detected"] = ",".join(set(t for _, t in findings))
            logger.warning("[PII] Detected in %s: %s", message.task_name, message.labels["_pii_detected"])
        return message


class TaskTracingMiddleware(TaskiqMiddleware):
    """OTel tracing dla zadań."""

    async def pre_send(self, message: TaskiqMessage) -> TaskiqMessage:
        try:
            from opentelemetry import baggage

            from nexus_ai.core.otel import get_tracer
            tracer = get_tracer("nexus.taskiq")
            with tracer.start_as_current_span(f"task.{message.task_name}") as span:
                span.set_attribute("task_name", message.task_name)
                trace_id = format(span.get_span_context().trace_id, "032x")
                span_id = format(span.get_span_context().span_id, "016x")
                message.labels.update({"trace_id": trace_id, "span_id": span_id, "environment": os.getenv("NEXUS_ENV", "dev")})
                baggage.set_baggage("task_name", message.task_name)
                _structlog.contextvars.clear_contextvars()
                _structlog.contextvars.bind_contextvars(task_id=trace_id, task_name=message.task_name)
        except Exception:
            message.labels["trace_id"] = uuid.uuid4().hex[:16]
            message.labels["span_id"] = ""
        return message


class SentryTaskMiddleware(TaskiqMiddleware):
    """Sentry scope dla zadań Taskiq."""

    async def pre_execute(self, message: TaskiqMessage) -> None:
        try:
            import sentry_sdk
            sentry_sdk.set_tag("task_name", message.task_name)
            sentry_sdk.set_tag("task_id", message.labels.get("trace_id", ""))
            sentry_sdk.add_breadcrumb(message=f"task.{message.task_name}.started", category="task", level="info")
        except ImportError:
            pass

    async def on_error(self, message: TaskiqMessage, result: TaskiqResult) -> None:
        try:
            import sentry_sdk
            if result.error:
                sentry_sdk.capture_exception(result.error)
        except ImportError:
            pass


def _record_task_metrics(task_name: str, duration_ms: float, status: str) -> None:
    try:
        from nexus_ai.api.telemetry_metrics import record_task_execution
        record_task_execution(task_name=task_name, duration_ms=duration_ms, status=status)
    except Exception:
        pass


# ═══════════════════════════════════════════════════════════════════════════
# RESULT BACKEND (z taskiq_result_backend.py)
# ═══════════════════════════════════════════════════════════════════════════

@final
class SqliteResultBackend(TaskiqResultBackend):
    """Taskiq Result Backend w SQLite."""

    def __init__(self, db_path: str | Path) -> None:
        self._db_path = Path(db_path)
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()
        self._conn: sqlite3.Connection | None = None
        self._ensure_schema()

    def _get_conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(str(self._db_path), check_same_thread=False)
            self._conn.row_factory = sqlite3.Row
        return self._conn

    def _ensure_schema(self) -> None:
        conn = self._get_conn()
        conn.execute("""CREATE TABLE IF NOT EXISTS taskiq_results (
            task_id TEXT PRIMARY KEY, task_name TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'PENDING',
            return_value TEXT, error TEXT, execution_time_ms REAL, started_at TEXT,
            finished_at TEXT, labels_json TEXT, created_at TEXT NOT NULL DEFAULT (datetime('now')))""")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_tq_status ON taskiq_results(status)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_tq_name ON taskiq_results(task_name)")
        conn.commit()

    async def set_result(self, task_id: str, result: TaskiqResult) -> None:
        with self._lock:
            try:
                self._get_conn().execute(
                    "INSERT OR REPLACE INTO taskiq_results VALUES (?,?,?,?,?,?,?,?,?,datetime('now'))",
                    (task_id, result.task_name or "", "SUCCESS" if result.is_err is False else "FAILED" if result.is_err else "UNKNOWN",
                     msgspec_dumps(result.return_value) if result.return_value is not None else None,
                     str(result.error) if result.error else None, result.execution_time,
                     result.started_at.isoformat() if result.started_at else None,
                     result.finished_at.isoformat() if result.finished_at else None,
                     msgspec_dumps(result.labels) if result.labels else None))
                self._get_conn().commit()
            except Exception as exc:
                logger.warning("[RESULT-BACKEND] Save failed %s: %s", task_id, exc)

    async def is_result_exists(self, task_id: str) -> bool:
        with self._lock:
            return self._get_conn().execute("SELECT 1 FROM taskiq_results WHERE task_id = ?", (task_id,)).fetchone() is not None

    async def get_result(self, task_id: str, with_logs: bool = False) -> TaskiqResult | None:
        with self._lock:
            row = self._get_conn().execute("SELECT * FROM taskiq_results WHERE task_id = ?", (task_id,)).fetchone()
        if row is None:
            return None
        return TaskiqResult(task_id=str(row["task_id"]), task_name=str(row["task_name"]),
            is_err=row["status"] == "FAILED",
            return_value=_msgspec_loads(row["return_value"]) if row["return_value"] else None,
            error=Exception(row["error"]) if row["error"] else None,
            execution_time=float(row["execution_time_ms"]) if row["execution_time_ms"] else 0.0,
            labels=_msgspec_loads(row["labels_json"]) if row["labels_json"] else {})

    async def close(self) -> None:
        if self._conn is not None:
            self._conn.close()
            self._conn = None


@final
class HybridResultBackend(TaskiqResultBackend):
    """Hybrid backend: NATS Object Store + SQLite fallback."""

    def __init__(self, sqlite_path: str | Path, nats_servers: list[str] | None = None, bucket_name: str = "nexus-task-results") -> None:
        self._sqlite = SqliteResultBackend(sqlite_path)
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._bucket_name = bucket_name
        self._nc: Any = None
        self._obj_store: Any = None

    async def _ensure_nats(self) -> bool:
        if self._obj_store is not None:
            try:
                await self._nc.ping()
                return True
            except Exception:
                self._obj_store = None
        try:
            import nats
            self._nc = await nats.connect(servers=self._nats_servers, connect_timeout=2.0)
            js = self._nc.jetstream()
            try:
                self._obj_store = await js.create_object_store(bucket=self._bucket_name)
            except Exception:
                self._obj_store = await js.object_store(bucket=self._bucket_name)
            return True
        except Exception:
            return False

    async def set_result(self, task_id: str, result: TaskiqResult) -> None:
        try:
            if await self._ensure_nats():
                data = _json.dumps({"task_id": task_id, "task_name": result.task_name, "is_err": result.is_err, "return_value": result.return_value, "error": str(result.error) if result.error else None, "execution_time": result.execution_time, "labels": result.labels}).encode()
                await self._obj_store.put(task_id, data)
                return
        except Exception:
            pass
        await self._sqlite.set_result(task_id, result)

    async def is_result_exists(self, task_id: str) -> bool:
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
        try:
            if await self._ensure_nats():
                try:
                    entry = await self._obj_store.get(task_id)
                    data = _msgspec_loads(entry.data)
                    return TaskiqResult(task_id=data["task_id"], task_name=data.get("task_name", ""), is_err=data.get("is_err", False), return_value=data.get("return_value"), error=Exception(data["error"]) if data.get("error") else None, execution_time=data.get("execution_time", 0.0), labels=data.get("labels", {}))
                except Exception:
                    pass
        except Exception:
            pass
        return await self._sqlite.get_result(task_id)

    async def close(self) -> None:
        if self._nc is not None:
            try:
                await self._nc.drain()
            except Exception:
                pass
        await self._sqlite.close()
