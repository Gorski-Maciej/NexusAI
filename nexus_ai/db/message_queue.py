"""
AsyncSQLiteQueue — async SQLite Message Queue via aiosqlite.

SUPERMOC: aiosqlite zamiast synchronicznego sqlite3 dla kolejki komunikatów.
Wszystkie operacje enqueue/dequeue są async — nie blokują pętli zdarzeń.

Zgodnie z docs/AIOSQLITE_AUDIT.md:
- FAZA 2: Konwersja MessageQueue z sync sqlite3 na async aiosqlite

SUPERMOCE:
- Atomiczne enqueue/dequeue w jednej transakcji (async)
- Priorytety (1-10, domyślnie 5)
- Opóźnione wiadomości (delay_until)
- Dead letter queue (automatyczne przenoszenie po max_retries)
- Partial indexes dla dequeue/delayed/DLQ

Usage:
    queue = AsyncSQLiteQueue("path/to/queue.db")
    await queue.enqueue("invoice.process", {"invoice_id": "..."}, priority=5)
    msg = await queue.dequeue()
    if msg:
        await queue.ack(msg["id"])
"""

from __future__ import annotations

import json
import time
import uuid
from pathlib import Path
from typing import Any

from nexus_ai.db.async_base_service import AsyncBaseService


class AsyncSQLiteQueue(AsyncBaseService):
    """Async lekka kolejka komunikatów w SQLite przez aiosqlite.

    SUPERMOCE:
    - Atomiczne enqueue/dequeue w jednej transakcji (async)
    - Priorytety (1-10, domyślnie 5)
    - Opóźnione wiadomości (delay_until)
    - Dead letter queue
    - Partial indexes
    - async — nie blokuje pętli zdarzeń
    """

    def __init__(
        self,
        db_path: str | Path,
        max_retries: int = 3,
        poll_interval: float = 0.1,
    ) -> None:
        super().__init__(db_path)
        self._max_retries = max_retries
        self._poll_interval = poll_interval
        self._schema_checked = False  # Flaga dla _on_connect hook

    async def _ensure_schema(self) -> None:
        """Utwórz schemat kolejki (async)."""
        await self.executescript("""
            CREATE TABLE IF NOT EXISTS mq_messages (
                id TEXT PRIMARY KEY,
                queue TEXT NOT NULL,
                payload TEXT NOT NULL,
                priority INTEGER DEFAULT 5,
                status TEXT DEFAULT 'pending',
                delay_until REAL,
                retry_count INTEGER DEFAULT 0,
                max_retries INTEGER DEFAULT 3,
                created_at REAL,
                updated_at REAL
            );

            CREATE INDEX IF NOT EXISTS idx_mq_dequeue
                ON mq_messages(priority DESC, created_at ASC)
                WHERE status = 'pending';

            CREATE INDEX IF NOT EXISTS idx_mq_delayed
                ON mq_messages(delay_until)
                WHERE status = 'pending' AND delay_until IS NOT NULL;

            CREATE INDEX IF NOT EXISTS idx_mq_dlq
                ON mq_messages(updated_at)
                WHERE status = 'dlq';

            CREATE TABLE IF NOT EXISTS mq_dead_letter (
                id TEXT PRIMARY KEY,
                queue TEXT NOT NULL,
                payload TEXT NOT NULL,
                priority INTEGER DEFAULT 5,
                retry_count INTEGER,
                error TEXT,
                created_at REAL,
                moved_at REAL
            );
        """)
        await self.commit()

    async def _on_connect(self, conn: aiosqlite.Connection) -> None:
        """Hook tworzący schemat kolejki przy pierwszym połączeniu.

        SUPERMOC: Sprawdza raz czy tabela istnieje, tworzy jeśli nie.
        Używa flagi ``_schema_checked`` aby nie sprawdzać przy każdym
        połączeniu (było: schema check na każdym get_conn()).
        """
        if not getattr(self, "_schema_checked", False):
            cursor = await conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='mq_messages'"
            )
            row = await cursor.fetchone()
            if row is None:
                await self._ensure_schema()
            self._schema_checked = True

    # ── Enqueue ──────────────────────────────────────────────────────

    async def enqueue(
        self,
        queue: str,
        payload: dict[str, Any] | str,
        priority: int = 5,
        delay_seconds: float | None = None,
        max_retries: int | None = None,
    ) -> str:
        """Dodaj wiadomość do kolejki (ASYNC)."""
        msg_id = uuid.uuid4().hex
        payload_str = json.dumps(payload) if isinstance(payload, dict) else payload
        now = time.time()
        delay_until = now + delay_seconds if delay_seconds else None
        retries = max_retries or self._max_retries

        await self.execute(
            """INSERT INTO mq_messages
               (id, queue, payload, priority, status, delay_until,
                retry_count, max_retries, created_at, updated_at)
               VALUES (?, ?, ?, ?, 'pending', ?, 0, ?, ?, ?)""",
            (msg_id, queue, payload_str, priority, delay_until, retries, now, now),
        )
        await self.commit()
        return msg_id

    async def enqueue_batch(
        self,
        messages: list[dict[str, Any]],
    ) -> list[str]:
        """Dodaj wiele wiadomości w jednej transakcji (async batch enqueue)."""
        conn = await self.get_conn()
        ids: list[str] = []
        now = time.time()

        await conn.execute("BEGIN")
        try:
            for msg in messages:
                msg_id = uuid.uuid4().hex
                payload = msg.get("payload", {})
                payload_str = json.dumps(payload) if isinstance(payload, dict) else payload
                delay = msg.get("delay_seconds")
                delay_until = now + delay if delay else None

                await conn.execute(
                    """INSERT INTO mq_messages
                       (id, queue, payload, priority, status, delay_until,
                        retry_count, max_retries, created_at, updated_at)
                       VALUES (?, ?, ?, ?, 'pending', ?, 0, ?, ?, ?)""",
                    (
                        msg_id,
                        msg.get("queue", "default"),
                        payload_str,
                        msg.get("priority", 5),
                        delay_until,
                        msg.get("max_retries", self._max_retries),
                        now,
                        now,
                    ),
                )
                ids.append(msg_id)
            await conn.commit()
        except Exception:
            await conn.rollback()
            raise

        return ids

    # ── Dequeue ──────────────────────────────────────────────────────

    async def dequeue(
        self,
        queue: str | None = None,
        batch_size: int = 1,
    ) -> list[dict[str, Any]] | dict[str, Any] | None:
        """Pobierz następną wiadomość z kolejki (atomicznie, ASYNC).

        SUPERMOC: Atomiczny UPDATE z WHERE status='pending' — dwa równoczesne
        dequeue nie dostaną tej samej wiadomości.
        """
        conn = await self.get_conn()
        now = time.time()

        # Krok 1: Znajdź wiadomości do przetworzenia
        if queue:
            cursor = await conn.execute(
                """SELECT id FROM mq_messages
                   WHERE queue = ? AND status = 'pending'
                     AND (delay_until IS NULL OR delay_until <= ?)
                   ORDER BY priority DESC, created_at ASC
                   LIMIT ?""",
                (queue, now, batch_size),
            )
        else:
            cursor = await conn.execute(
                """SELECT id FROM mq_messages
                   WHERE status = 'pending'
                     AND (delay_until IS NULL OR delay_until <= ?)
                   ORDER BY priority DESC, created_at ASC
                   LIMIT ?""",
                (now, batch_size),
            )
        rows = await cursor.fetchall()

        if not rows:
            return None if batch_size == 1 else []

        msg_ids = [str(r[0]) for r in rows]

        # Krok 2: Atomiczny UPDATE
        placeholders = ", ".join("?" * len(msg_ids))
        cursor = await conn.execute(
            f"""UPDATE mq_messages
                SET status = 'processing', updated_at = ?
                WHERE id IN ({placeholders}) AND status = 'pending'""",
            (now, *msg_ids),
        )
        if cursor.rowcount == 0:
            await conn.commit()
            return None if batch_size == 1 else []

        # Krok 3: Pobierz pełne dane
        cursor = await conn.execute(
            f"""SELECT id, queue, payload, priority, status,
                       retry_count, max_retries, created_at
                FROM mq_messages
                WHERE id IN ({placeholders})""",
            (*msg_ids,),
        )
        results = await cursor.fetchall()
        await conn.commit()

        messages = [dict(r) for r in results]

        if batch_size == 1:
            return messages[0] if messages else None
        return messages

    # ── Ack / Nack ───────────────────────────────────────────────────

    async def ack(self, msg_id: str) -> bool:
        """Potwierdź przetworzenie wiadomości (ASYNC)."""
        cursor = await self.execute(
            "DELETE FROM mq_messages WHERE id = ? AND status = 'processing'",
            (msg_id,),
        )
        await self.commit()
        return cursor.rowcount > 0

    async def nack(
        self,
        msg_id: str,
        error: str | None = None,
    ) -> bool:
        """Nie potwierdzaj — zwiększ retry_count lub przenieś do DLQ (ASYNC)."""
        conn = await self.get_conn()
        now = time.time()

        cursor = await conn.execute(
            "SELECT retry_count, max_retries FROM mq_messages WHERE id = ?",
            (msg_id,),
        )
        row = await cursor.fetchone()

        if row is None:
            return False

        retry_count = int(row[0]) + 1
        max_retries = int(row[1])

        if retry_count >= max_retries:
            # Dead Letter Queue
            await conn.execute(
                """INSERT INTO mq_dead_letter
                   (id, queue, payload, priority, retry_count, error, created_at, moved_at)
                   SELECT id, queue, payload, priority, retry_count, ?, created_at, ?
                   FROM mq_messages WHERE id = ?""",
                (error or "max_retries_exceeded", now, msg_id),
            )
            await conn.execute(
                "UPDATE mq_messages SET status = 'dlq', updated_at = ? WHERE id = ?",
                (now, msg_id),
            )
        else:
            await conn.execute(
                """UPDATE mq_messages
                   SET status = 'pending', retry_count = ?, updated_at = ?
                   WHERE id = ?""",
                (retry_count, now, msg_id),
            )

        await conn.commit()
        return True

    # ── Stats ─────────────────────────────────────────────────────────

    async def get_stats(self) -> dict[str, int]:
        """Zwróć statystyki kolejki (ASYNC)."""
        conn = await self.get_conn()
        cursor = await conn.execute(
            "SELECT status, COUNT(*) as cnt FROM mq_messages GROUP BY status"
        )
        rows = await cursor.fetchall()
        dlq_cursor = await conn.execute("SELECT COUNT(*) FROM mq_dead_letter")
        dlq_row = await dlq_cursor.fetchone()

        stats: dict[str, int] = {str(r[0]): int(r[1]) for r in rows}
        stats["dead_letter"] = int(dlq_row[0]) if dlq_row else 0
        return stats

    async def replay_dlq(self) -> int:
        """Przenieś wszystkie wiadomości z DLQ z powrotem do kolejki (ASYNC)."""
        conn = await self.get_conn()
        now = time.time()

        cursor = await conn.execute("SELECT id FROM mq_dead_letter")
        rows = await cursor.fetchall()

        if not rows:
            return 0

        ids = [str(r[0]) for r in rows]

        await conn.execute(
            """INSERT OR IGNORE INTO mq_messages
               (id, queue, payload, priority, status, retry_count, max_retries, created_at, updated_at)
               SELECT id, queue, payload, priority, 'pending', 0, 3, created_at, ?
               FROM mq_dead_letter""",
            (now,),
        )

        placeholders = ", ".join("?" * len(ids))
        await conn.execute(f"DELETE FROM mq_dead_letter WHERE id IN ({placeholders})", ids)
        await conn.commit()

        return len(ids)


# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
SQLiteQueue = AsyncSQLiteQueue
