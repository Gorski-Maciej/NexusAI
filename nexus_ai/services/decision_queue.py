"""DecisionQueue — trwała kolejka decyzji oczekujących na użytkownika.

Zgodnie z aa3fvcx.txt (Punkt 26): trwała kolejka decyzji oczekujących
na odpowiedź użytkownika, z priorytetami i terminami ważności.

Każda decyzja ma:
  - Priorytet (LOW, NORMAL, HIGH, CRITICAL)
  - Termin ważności (expires_at)
  - Status (pending, approved, rejected, expired)
  - Powiązanie z powiadomieniem (notification_id)
"""

from __future__ import annotations

import enum
import sqlite3
from pathlib import Path
from typing import Any

import pendulum
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
    """Trwała kolejka decyzji (SQLite) z priorytetami i terminami ważności.

    Obsługuje:
      - Kolejkowanie decyzji od agentów
      - Priorytety (krytyczne → normalne)
      - Terminy ważności (auto-expire)
      - Rozwiązywanie decyzji (approve/reject)
      - Zapytania o decyzje oczekujące

    Integracja:
      - NotificationManager: wysyła powiadomienie + dodaje do kolejki
      - Scheduler: czyści wygasłe decyzje
      - EventLog: loguje rozstrzygnięte decyzje
      - BayesianThresholdLearner: uczy się na decyzjach użytkownika
    """

    def __init__(
        self,
        db_path: Path | str | None = None,
        bayesian_learner: Any | None = None,
    ) -> None:
        self._db_path = Path(db_path) if db_path else Path("app_data/decisions.db")
        self._db_path.parent.mkdir(parents=True, exist_ok=True)
        self._bayesian = bayesian_learner
        self._init_schema()

    def _init_schema(self) -> None:
        """Inicjalizuj schemat bazy danych."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS decisions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    notification_id INTEGER NOT NULL DEFAULT 0,
                    title TEXT NOT NULL,
                    message TEXT NOT NULL,
                    source_agent TEXT NOT NULL DEFAULT '',
                    reference_type TEXT NOT NULL DEFAULT '',
                    reference_id TEXT NOT NULL DEFAULT '',
                    status TEXT NOT NULL DEFAULT 'pending',
                    priority INTEGER NOT NULL DEFAULT 1,
                    expires_at TEXT,
                    resolved_at TEXT,
                    resolution TEXT,
                    created_at TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS idx_decisions_user_pending
                    ON decisions(user_id, status, priority DESC, created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_decisions_expires
                    ON decisions(expires_at)
                    WHERE status = 'pending' AND expires_at IS NOT NULL;
                CREATE INDEX IF NOT EXISTS idx_decisions_reference
                    ON decisions(reference_type, reference_id);
            """)
            conn.commit()
        finally:
            conn.close()

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
            source_agent: Nazwa agenta źródłowego
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

        conn = sqlite3.connect(str(self._db_path))
        try:
            cursor = conn.execute(
                """INSERT INTO decisions
                   (user_id, notification_id, title, message, source_agent,
                    reference_type, reference_id, status, priority,
                    expires_at, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    user_id, notification_id, title, message, source_agent,
                    reference_type, reference_id, DecisionStatus.PENDING.value,
                    priority, expires_at, now,
                ),
            )
            conn.commit()
            decision_id = int(cursor.lastrowid)

            logger.info(
                "[DecisionQueue] enqueued id=%d user=%s agent=%s ref=%s/%s priority=%d",
                decision_id, user_id, source_agent, reference_type, reference_id, priority,
            )
            return decision_id
        finally:
            conn.close()

    def get_pending(self, user_id: str, limit: int = 20) -> list[dict[str, Any]]:
        """Pobierz oczekujące decyzje użytkownika.

        Zwraca decyzje posortowane według priorytetu (od najwyższego)
        i daty utworzenia (od najnowszych).
        """
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.row_factory = sqlite3.Row
            rows = conn.execute(
                """SELECT * FROM decisions
                   WHERE user_id = ? AND status = 'pending'
                     AND (expires_at IS NULL OR expires_at > ?)
                   ORDER BY priority DESC, created_at DESC
                   LIMIT ?""",
                (user_id, pendulum.now("UTC").isoformat(), limit),
            ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def get_all_pending(self, limit: int = 100) -> list[dict[str, Any]]:
        """Pobierz wszystkie oczekujące decyzje (dla administratora)."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            conn.row_factory = sqlite3.Row
            rows = conn.execute(
                """SELECT * FROM decisions
                   WHERE status = 'pending'
                     AND (expires_at IS NULL OR expires_at > ?)
                   ORDER BY priority DESC, created_at DESC
                   LIMIT ?""",
                (pendulum.now("UTC").isoformat(), limit),
            ).fetchall()
            return [dict(r) for r in rows]
        finally:
            conn.close()

    def resolve(
        self,
        decision_id: int,
        resolution: str,
        status: str = DecisionStatus.APPROVED.value,
        contractor_nip: str | None = None,
        category: str = "__global__",
        amount_gross: float = 0.0,
    ) -> bool:
        """Rozstrzygnij decyzję (approve/reject) i zapisz do Bayesa.

        Args:
            decision_id: ID decyzji
            resolution: Odpowiedź użytkownika (tekst lub 'approved'/'rejected')
            status: Nowy status (approved, rejected)
            contractor_nip: NIP kontrahenta (dla Bayesa)
            category: Kategoria wydatku (dla Bayesa)
            amount_gross: Kwota brutto (dla Bayesa)

        Returns:
            True jeśli znaleziono i zaktualizowano, False jeśli nie znaleziono.
        """
        conn = sqlite3.connect(str(self._db_path))
        try:
            now = pendulum.now("UTC").isoformat()
            cursor = conn.execute(
                """UPDATE decisions
                   SET status = ?, resolved_at = ?, resolution = ?
                   WHERE id = ? AND status = 'pending'""",
                (status, now, resolution, decision_id),
            )
            conn.commit()
            updated = cursor.rowcount > 0

            if updated:
                logger.info(
                    "[DecisionQueue] resolved id=%d status=%s resolution=%s",
                    decision_id, status, resolution,
                )

                # Zaloguj do EventLog
                try:
                    el = EventLog()
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

                # Zapisz decyzję do BayesianThresholdLearner
                if self._bayesian is not None and contractor_nip:
                    try:
                        approved = status == DecisionStatus.APPROVED.value
                        self._bayesian.record_decision(
                            contractor_nip=contractor_nip,
                            category=category,
                            approved=approved,
                            amount_gross=amount_gross,
                        )
                        logger.debug(
                            "[DecisionQueue] bayesian updated nip=%s approved=%s",
                            contractor_nip, approved,
                        )
                    except Exception as exc:
                        logger.warning(
                            "[DecisionQueue] Bayesian record failed: %s", exc
                        )

            return updated
        finally:
            conn.close()

    def expire_old(self) -> int:
        """Oznacz wygasłe decyzje jako expired.

        Returns:
            Liczba oznaczonych jako wygasłe.
        """
        now = pendulum.now("UTC").isoformat()
        conn = sqlite3.connect(str(self._db_path))
        try:
            cursor = conn.execute(
                """UPDATE decisions
                   SET status = 'expired', resolved_at = ?, resolution = 'auto-expired'
                   WHERE status = 'pending' AND expires_at IS NOT NULL AND expires_at < ?""",
                (now, now),
            )
            conn.commit()
            expired = cursor.rowcount
            if expired:
                logger.info("[DecisionQueue] expired %d old decisions", expired)
            return expired
        finally:
            conn.close()

    def get_stats(self, user_id: str | None = None) -> dict[str, Any]:
        """Zwróć statystyki kolejki decyzji."""
        conn = sqlite3.connect(str(self._db_path))
        try:
            base_query = "FROM decisions"
            params: list[Any] = []
            if user_id:
                base_query += " WHERE user_id = ?"
                params.append(user_id)

            total = conn.execute(f"SELECT COUNT(*) {base_query}", params).fetchone()[0]
            pending = conn.execute(
                f"SELECT COUNT(*) {base_query} AND status = 'pending'" if user_id
                else "SELECT COUNT(*) FROM decisions WHERE status = 'pending'",
                params if user_id else [],
            ).fetchone()[0]

            # Decyzje rozstrzygnięte dzisiaj
            today = pendulum.now().date().isoformat()
            resolved_today = conn.execute(
                "SELECT COUNT(*) FROM decisions WHERE resolved_at >= ? AND resolved_at < ?"
                if not user_id else
                f"SELECT COUNT(*) FROM decisions WHERE user_id = ? AND resolved_at >= ? AND resolved_at < ?",
                params + [f"{today}T00:00:00", f"{today}T23:59:59"] if user_id
                else [f"{today}T00:00:00", f"{today}T23:59:59"],
            ).fetchone()[0]

            return {
                "total": total,
                "pending": pending,
                "resolved_today": resolved_today,
            }
        finally:
            conn.close()
