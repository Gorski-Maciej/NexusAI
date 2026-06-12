"""DecisionQueue — trwała kolejka decyzji oczekujących na użytkownika.

Zgodnie z aa3fvcx.txt (Punkt 26): trwała kolejka decyzji oczekujących
na odpowiedź użytkownika, z priorytetami i terminami ważności.

Każda decyzja ma:
  - Priorytet (LOW, NORMAL, HIGH, CRITICAL)
  - Termin ważności (expires_at)
  - Status (pending, approved, rejected, expired)
  - Powiązanie z powiadomieniem (notification_id)

Storage: Główna baza danych (SQLAlchemy / Alembic).
DDL w migracji 0003_consolidate_service_tables (tabela: dq_decisions).
"""

from __future__ import annotations

import enum
from typing import Any

import pendulum
from sqlalchemy import Engine, text
from structlog import get_logger

from nexus_ai.services.event_log import EventLog

logger = get_logger("nexus.services.decision_queue")


class DecisionStatus(enum.Enum):
    """Status decyzji w kolejce."""

    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    EXPIRED = "expired"


class DecisionPriority(enum.IntEnum):
    """Priorytety decyzji."""

    LOW = 0
    NORMAL = 1
    HIGH = 2
    CRITICAL = 3


class DecisionQueue:
    """Trwała kolejka decyzji (główna baza danych) z priorytetami i terminami ważności.

    Obsługuje:
      - Kolejkowanie decyzji systemowych
      - Priorytety (krytyczne → normalne)
      - Terminy ważności (auto-expire)
      - Rozwiązywanie decyzji (approve/reject)
      - Zapytania o decyzje oczekujące

    Integracja:
      - NotificationManager: wysyła powiadomienie + dodaje do kolejki
      - Scheduler: czyści wygasłe decyzje
      - EventLog: loguje rozstrzygnięte decyzje
      - DecisionHistory: analiza decyzji użytkownika

    Tabela: dq_decisions (migracja 0003).
    """

    def __init__(
        self,
        engine: Engine,
        history_tracker: Any | None = None,
    ) -> None:
        self._engine = engine
        self._tracker = history_tracker

    def enqueue(
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
        """Dodaj decyzję do kolejki.

        Args:
            user_id: ID użytkownika
            notification_id: ID powiązanego powiadomienia
            title: Tytuł decyzji
            message: Treść decyzji/pytania
            source_agent: Nazwa komponentu źródłowego
            reference_type: Typ referencji (invoice, contractor, itp.)
            reference_id: ID referencji
            priority: Priorytet decyzji
            expires_in_hours: Po ilu godzinach wygasa (None = bez terminu)

        Returns:
            ID utworzonej decyzji
        """
        now = pendulum.now("UTC").isoformat()
        expires_at = None
        if expires_in_hours is not None:
            expires_at = pendulum.now("UTC").add(hours=expires_in_hours).isoformat()

        with self._engine.begin() as conn:
            result = conn.execute(
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

    def get_pending(self, user_id: str, limit: int = 20) -> list[dict[str, Any]]:
        """Pobierz oczekujące decyzje użytkownika.

        Zwraca decyzje posortowane według priorytetu (od najwyższego)
        i daty utworzenia (od najnowszych).
        """
        now = pendulum.now("UTC").isoformat()
        with self._engine.connect() as conn:
            rows = (
                conn.execute(
                    text(
                        """SELECT * FROM dq_decisions
                       WHERE user_id = :user_id AND status = 'pending'
                         AND (expires_at IS NULL OR expires_at > :now)
                       ORDER BY priority DESC, created_at DESC
                       LIMIT :limit"""
                    ),
                    {"user_id": user_id, "now": now, "limit": limit},
                )
                .mappings()
                .all()
            )
            return [dict(r) for r in rows]

    def get_all_pending(self, limit: int = 100) -> list[dict[str, Any]]:
        """Pobierz wszystkie oczekujące decyzje (dla administratora)."""
        now = pendulum.now("UTC").isoformat()
        with self._engine.connect() as conn:
            rows = (
                conn.execute(
                    text(
                        """SELECT * FROM dq_decisions
                       WHERE status = 'pending'
                         AND (expires_at IS NULL OR expires_at > :now)
                       ORDER BY priority DESC, created_at DESC
                       LIMIT :limit"""
                    ),
                    {"now": now, "limit": limit},
                )
                .mappings()
                .all()
            )
            return [dict(r) for r in rows]

    def resolve(
        self,
        decision_id: int,
        resolution: str,
        status: str = DecisionStatus.APPROVED.value,
        contractor_nip: str | None = None,
        category: str = "__global__",
        amount_gross: float = 0.0,
    ) -> bool:
        """Rozstrzygnij decyzję (approve/reject) i zapisz do historii.

        Returns:
            True jeśli znaleziono i zaktualizowano, False jeśli nie znaleziono.
        """
        with self._engine.begin() as conn:
            now = pendulum.now("UTC").isoformat()
            result = conn.execute(
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

            # Zaloguj do EventLog
            try:
                el = EventLog(engine=self._engine)
                el.log(
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

    def expire_old(self) -> int:
        """Oznacz wygasłe decyzje jako expired.

        Returns:
            Liczba oznaczonych jako wygasłe.
        """
        now = pendulum.now("UTC").isoformat()
        with self._engine.begin() as conn:
            result = conn.execute(
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

    def get_stats(self, user_id: str | None = None) -> dict[str, Any]:
        """Zwróć statystyki kolejki decyzji."""
        with self._engine.connect() as conn:
            base = "FROM dq_decisions"
            params: dict[str, Any] = {}
            if user_id:
                base += " WHERE user_id = :user_id"
                params["user_id"] = user_id

            total = int(conn.execute(text(f"SELECT COUNT(*) {base}"), params).scalar() or 0)

            pending_params = dict(params)
            pending_where = (
                f"{base} AND status = 'pending'"
                if user_id
                else "FROM dq_decisions WHERE status = 'pending'"
            )
            pending = int(
                conn.execute(text(f"SELECT COUNT(*) {pending_where}"), pending_params).scalar() or 0
            )

            # Decyzje rozstrzygnięte dzisiaj
            today = pendulum.now().date().isoformat()
            resolved_params: dict[str, Any] = {
                "start": f"{today}T00:00:00",
                "end": f"{today}T23:59:59",
            }
            resolved_where = "FROM dq_decisions WHERE resolved_at >= :start AND resolved_at < :end"
            if user_id:
                resolved_where += " AND user_id = :user_id"
                resolved_params["user_id"] = user_id
            resolved_today = int(
                conn.execute(text(f"SELECT COUNT(*) {resolved_where}"), resolved_params).scalar()
                or 0
            )

            return {
                "total": total,
                "pending": pending,
                "resolved_today": resolved_today,
            }
