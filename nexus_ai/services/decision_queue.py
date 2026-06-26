"""
AsyncDecisionQueue — trwała kolejka decyzji (async).

Każda decyzja ma:
  - Priorytet (LOW, NORMAL, HIGH, CRITICAL)
  - Termin ważności (expires_at)
  - Status (pending, approved, rejected, expired)
  - Powiązanie z powiadomieniem (notification_id)

Storage: Główna baza danych (tabela: dq_decisions).
"""

from __future__ import annotations

import enum
from typing import Any, final

import pendulum
from sqlmodel import text
from sqlalchemy.ext.asyncio import AsyncEngine
from structlog import get_logger

from nexus_ai.services.event_log import AsyncEventLog

logger = get_logger("nexus.services.decision_queue")


class DecisionStatus(enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    EXPIRED = "expired"


class DecisionPriority(enum.IntEnum):
    LOW = 0
    NORMAL = 1
    HIGH = 2
    CRITICAL = 3


@final
class AsyncDecisionQueue:
    """Async trwała kolejka decyzji z priorytetami i terminami ważności.

    Wszystkie operacje są async — używa AsyncEngine zamiast sync Engine.
    """

    def __init__(
        self,
        engine: AsyncEngine,
        history_tracker: Any | None = None,
    ) -> None:
        self._engine = engine
        self._tracker = history_tracker

    async def enqueue(
        self,
        user_id: str,
        notification_id: int,
        title: str,
        message: str,
        source_agent: str,
        reference_type: str,
        reference_id: str,
        priority: int = DecisionPriority.NORMAL,
        expires_in_hours: int | None = 48,
    ) -> int:
        """Dodaj decyzję do kolejki (ASYNC)."""
        now = pendulum.now("UTC").isoformat()
        expires_at = None
        if expires_in_hours is not None:
            expires_at = pendulum.now("UTC").add(hours=expires_in_hours).isoformat()

        async with self._engine.begin() as conn:
            result = await conn.execute(
                text(
                    """INSERT INTO dq_decisions
                       (user_id, notification_id, title, message, source_agent,
                        reference_type, reference_id, status, priority,
                        expires_at, created_at)
                       VALUES (:user_id, :notification_id, :title, :message, :source_agent,
                               :reference_type, :reference_id, :status, :priority,
                               :expires_at, :created_at)"""
                ),
                {
                    "user_id": user_id,
                    "notification_id": notification_id,
                    "title": title,
                    "message": message,
                    "source_agent": source_agent,
                    "reference_type": reference_type,
                    "reference_id": reference_id,
                    "status": DecisionStatus.PENDING.value,
                    "priority": priority,
                    "expires_at": expires_at,
                    "created_at": now,
                },
            )
            decision_id = int(result.lastrowid)

        logger.info(
            "[DecisionQueue] enqueued id=%d user=%s agent=%s ref=%s/%s priority=%d",
            decision_id,
            user_id,
            source_agent,
            reference_type,
            reference_id,
            priority,
        )
        return decision_id

    async def get_pending(self, user_id: str, limit: int = 20) -> list[dict[str, Any]]:
        """Pobierz oczekujące decyzje użytkownika (ASYNC)."""
        now = pendulum.now("UTC").isoformat()
        async with self._engine.connect() as conn:
            result = await conn.execute(
                text(
                    """SELECT * FROM dq_decisions
                       WHERE user_id = :user_id AND status = 'pending'
                         AND (expires_at IS NULL OR expires_at > :now)
                       ORDER BY priority DESC, created_at DESC
                       LIMIT :limit"""
                ),
                {"user_id": user_id, "now": now, "limit": limit},
            )
            rows = result.mappings().all()
            return [dict(r) for r in rows]

    async def get_all_pending(self, limit: int = 100) -> list[dict[str, Any]]:
        """Pobierz wszystkie oczekujące decyzje (ASYNC)."""
        now = pendulum.now("UTC").isoformat()
        async with self._engine.connect() as conn:
            result = await conn.execute(
                text(
                    """SELECT * FROM dq_decisions
                       WHERE status = 'pending'
                         AND (expires_at IS NULL OR expires_at > :now)
                       ORDER BY priority DESC, created_at DESC
                       LIMIT :limit"""
                ),
                {"now": now, "limit": limit},
            )
            rows = result.mappings().all()
            return [dict(r) for r in rows]

    async def resolve(
        self,
        decision_id: int,
        resolution: str,
        status: str = DecisionStatus.APPROVED.value,
        contractor_nip: str | None = None,
        category: str = "__global__",
        amount_gross: float = 0.0,
    ) -> bool:
        """Rozstrzygnij decyzję (approve/reject) i zapisz do historii (ASYNC)."""
        async with self._engine.begin() as conn:
            now = pendulum.now("UTC").isoformat()
            result = await conn.execute(
                text(
                    """UPDATE dq_decisions
                       SET status = :status, resolved_at = :now, resolution = :resolution
                       WHERE id = :decision_id AND status = 'pending'"""
                ),
                {
                    "status": status,
                    "now": now,
                    "resolution": resolution,
                    "decision_id": decision_id,
                },
            )
            updated = result.rowcount > 0

        if updated:
            logger.info(
                "[DecisionQueue] resolved id=%d status=%s resolution=%s",
                decision_id,
                status,
                resolution,
            )

            # Zaloguj do EventLog (async)
            try:
                el = AsyncEventLog(engine=self._engine)
                await el.log(
                    event_type=f"decision.{status}",
                    source="decision_queue",
                    description=f"Decision #{decision_id}: {resolution}",
                    metadata={
                        "decision_id": decision_id,
                        "resolution": resolution,
                        "status": status,
                    },
                )
            except Exception as exc:
                logger.warning("[DecisionQueue] Failed to log to EventLog: %s", exc)

            # Zapisz decyzję do historii
            if self._tracker is not None and contractor_nip:
                try:
                    self._tracker.record_decision(
                        contractor_nip=contractor_nip,
                        category=category,
                        decision=status,
                        amount_gross=amount_gross,
                    )
                    logger.debug(
                        "[DecisionQueue] history updated nip=%s status=%s",
                        contractor_nip,
                        status,
                    )
                except Exception as exc:
                    logger.warning("[DecisionQueue] history record failed: %s", exc)

        return updated

    async def expire_old(self) -> int:
        """Oznacz wygasłe decyzje jako expired (ASYNC)."""
        now = pendulum.now("UTC").isoformat()
        async with self._engine.begin() as conn:
            result = await conn.execute(
                text(
                    """UPDATE dq_decisions
                       SET status = 'expired', resolved_at = :now, resolution = 'auto-expired'
                       WHERE status = 'pending' AND expires_at IS NOT NULL AND expires_at < :now"""
                ),
                {"now": now},
            )
            expired = result.rowcount
        if expired:
            logger.info("[DecisionQueue] expired %d old decisions", expired)
        return expired

    async def get_stats(self, user_id: str | None = None) -> dict[str, Any]:
        """Zwróć statystyki kolejki decyzji (ASYNC)."""
        async with self._engine.connect() as conn:
            base = "FROM dq_decisions"
            params: dict[str, Any] = {}
            if user_id:
                base += " WHERE user_id = :user_id"
                params["user_id"] = user_id

            result = await conn.execute(text(f"SELECT COUNT(*) {base}"), params)
            total = int(result.scalar() or 0)

            pending_where = (
                f"{base} AND status = 'pending'"
                if user_id
                else "FROM dq_decisions WHERE status = 'pending'"
            )
            pending_params = dict(params) if user_id else {}
            result = await conn.execute(text(f"SELECT COUNT(*) {pending_where}"), pending_params)
            pending = int(result.scalar() or 0)

            today = pendulum.now().date().isoformat()
            resolved_params: dict[str, Any] = {
                "start": f"{today}T00:00:00",
                "end": f"{today}T23:59:59",
            }
            resolved_where = (
                "FROM dq_decisions WHERE resolved_at >= :start AND resolved_at < :end"
            )
            if user_id:
                resolved_where += " AND user_id = :user_id"
                resolved_params["user_id"] = user_id
            result = await conn.execute(
                text(f"SELECT COUNT(*) {resolved_where}"), resolved_params
            )
            resolved_today = int(result.scalar() or 0)

            return {
                "total": total,
                "pending": pending,
                "resolved_today": resolved_today,
            }


# ── Alias dla kompatybilności wstecznej ─────────────────────────────────
DecisionQueue = AsyncDecisionQueue
