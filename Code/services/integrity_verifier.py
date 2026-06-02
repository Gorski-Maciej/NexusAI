"""
Integrity Verifier — weryfikator integralności łańcucha hashy (Element 2).

Cyfrowy audytor, który na żądanie lub cyklicznie weryfikuje,
czy łańcuch kryptograficznych skrótów (SHA-256) w tabeli decision_traces
jest nienaruszony. Jeśli ktoś zmodyfikował wpis, weryfikator wykryje to,
zgłosi alarm i może zablokować system.

Funkcjonalności:
  - verify_all() — pełna weryfikacja sekwencyjna
  - verify_incremental() — przyrostowa od ostatniego checkpointu
  - handle_violation() — zapis incydentu + opcjonalna blokada
  - INTEGRITY_VIOLATIONS_SCHEMA — tabela naruszeń
"""

from __future__ import annotations

import json
import logging
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

import duckdb

from tax.audit import (
    _compute_current_hash,
    _GENESIS_HASH,
    ensure_schema as ensure_audit_schema,
    verify_chain_integrity,
)

logger = logging.getLogger("nexus.integrity")

# ── Schema for integrity violations ─────────────────────────────────────

INTEGRITY_VIOLATIONS_SCHEMA = """
CREATE TABLE IF NOT EXISTS integrity_violations (
    violation_id              VARCHAR PRIMARY KEY,
    first_inconsistent_trace  VARCHAR NOT NULL,
    expected_hash             VARCHAR NOT NULL,
    actual_hash               VARCHAR NOT NULL,
    details_json              VARCHAR NOT NULL,
    detected_at               VARCHAR NOT NULL,
    resolved_at               VARCHAR,
    resolved_by               VARCHAR
);
CREATE INDEX IF NOT EXISTS idx_iv_detected
    ON integrity_violations(detected_at);
"""

INTEGRITY_CHECKPOINT_SCHEMA = """
CREATE TABLE IF NOT EXISTS integrity_checkpoints (
    checkpoint_id   VARCHAR PRIMARY KEY,
    last_trace_id   VARCHAR NOT NULL,
    last_timestamp  VARCHAR NOT NULL,
    verified_at     VARCHAR NOT NULL,
    total_verified  INTEGER NOT NULL DEFAULT 0,
    status          VARCHAR NOT NULL DEFAULT 'ok'
);
"""


@dataclass
class IntegrityReport:
    """Raport z weryfikacji integralności.

    Attributes:
        status: 'ok' | 'violation' | 'error'.
        total_records: Liczba sprawdzonych wpisów.
        violations: Lista naruszeń (pusta = brak).
        first_inconsistent_trace: ID pierwszego niespójnego wpisu.
        verified_at: ISO timestamp weryfikacji.
    """
    status: str = "ok"
    total_records: int = 0
    violations: list[dict[str, Any]] = field(default_factory=list)
    first_inconsistent_trace: str | None = None
    verified_at: str = ""


class IntegrityVerifier:
    """Weryfikator Integralności — sprawdza łańcuch hashy decision_traces.

    Usage:
        verifier = IntegrityVerifier(conn)
        report = verifier.verify_all()
        if report.status == 'violation':
            verifier.handle_violation(report)
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        ensure_audit_schema(conn)
        self._ensure_violations_schema()

    # ── Schema ──────────────────────────────────────────────────────

    def _ensure_violations_schema(self) -> None:
        """Create integrity_violations and integrity_checkpoints tables."""
        self._conn.execute(INTEGRITY_VIOLATIONS_SCHEMA)
        self._conn.execute(INTEGRITY_CHECKPOINT_SCHEMA)

    # ── Verify methods ──────────────────────────────────────────────

    def verify_all(self) -> IntegrityReport:
        """Pełna weryfikacja wszystkich wpisów w decision_traces.

        Iteruje przez wszystkie wpisy posortowane według timestamp,
        sprawdza previous_hash linkage i recomputuje current_hash.

        Returns:
            IntegrityReport z listą naruszeń.
        """
        verified_at = datetime.now(timezone.utc).isoformat()

        # Użyj istniejącej funkcji verify_chain_integrity z audit.py
        issues = verify_chain_integrity(self._conn)

        # Policz całkowitą liczbę wpisów
        count_row = self._conn.execute(
            "SELECT COUNT(1) FROM decision_traces"
        ).fetchone()
        total = int(count_row[0]) if count_row else 0

        if not issues:
            return IntegrityReport(
                status="ok",
                total_records=total,
                violations=[],
                verified_at=verified_at,
            )

        return IntegrityReport(
            status="violation",
            total_records=total,
            violations=issues,
            first_inconsistent_trace=issues[0].get("trace_id"),
            verified_at=verified_at,
        )

    def verify_incremental(self) -> IntegrityReport:
        """Przyrostowa weryfikacja od ostatniego checkpointu.

        Sprawdza tylko wpisy dodane po ostatnim zweryfikowanym.
        Uwaga: nie wykrywa manipulacji w starych wpisach —
        do pełnej weryfikacji użyj verify_all().

        Delegates to :func:`verify_chain_integrity` filtered to new entries.

        Returns:
            IntegrityReport z listą naruszeń w nowych wpisach.
        """
        verified_at = datetime.now(timezone.utc).isoformat()

        # Pobierz ostatni checkpoint
        last_cp = self._conn.execute(
            "SELECT last_trace_id, last_timestamp, total_verified "
            "FROM integrity_checkpoints ORDER BY verified_at DESC LIMIT 1"
        ).fetchone()

        if not last_cp:
            # Brak checkpointu — wykonaj pełną weryfikację
            report = self.verify_all()
            self._save_checkpoint(report)
            return report

        last_trace_id = str(last_cp[0])
        last_timestamp = str(last_cp[1])
        total_before = int(last_cp[2])

        # Sprawdź, czy są nowe wpisy po checkpointcie
        count_row = self._conn.execute(
            "SELECT COUNT(1) FROM decision_traces WHERE timestamp > ?",
            (last_timestamp,),
        ).fetchone()
        new_count = int(count_row[0]) if count_row else 0

        if new_count == 0:
            return IntegrityReport(
                status="ok",
                total_records=total_before,
                verified_at=verified_at,
            )

        # Wykonaj pełną weryfikację (obejmie też stare wpisy dla pewności)
        # Dla wydajności można by zoptymalizować, ale na razie pełna jest bezpieczniejsza
        report = self.verify_all()
        self._save_checkpoint(report)
        return report

    # ── Violation handling ──────────────────────────────────────────

    def handle_violation(self, report: IntegrityReport) -> str:
        """Zapisz incydent naruszenia integralności.

        Args:
            report: Raport z verify_all() lub verify_incremental().

        Returns:
            violation_id — UUID zapisanego incydentu.
        """
        if report.status != "violation" or not report.violations:
            raise ValueError("No violations to handle")

        first_violation = report.violations[0]
        violation_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()

        details = {
            "violations_count": len(report.violations),
            "first_issue": first_violation.get("issue"),
            "trace_id": first_violation.get("trace_id"),
            "expected_hash": first_violation.get("expected_current") or first_violation.get("expected_previous"),
            "actual_hash": first_violation.get("stored_current") or first_violation.get("stored_previous"),
            "all_violations": report.violations,
        }

        self._conn.execute(
            """INSERT INTO integrity_violations
               (violation_id, first_inconsistent_trace, expected_hash, actual_hash,
                details_json, detected_at)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (
                violation_id,
                report.first_inconsistent_trace,
                str(details["expected_hash"]),
                str(details["actual_hash"]),
                json.dumps(details, ensure_ascii=False, default=str, sort_keys=True),
                now,
            ),
        )

        logger.critical(
            "[INTEGRITY-VIOLATION] violation_id=%s trace=%s expected=%s actual=%s",
            violation_id,
            report.first_inconsistent_trace,
            details["expected_hash"],
            details["actual_hash"],
        )

        return violation_id

    def is_system_locked(self) -> bool:
        """Sprawdź, czy system jest zablokowany z powodu naruszenia."""
        self._conn.execute(
            """CREATE TABLE IF NOT EXISTS system_flags
               (flag_key VARCHAR PRIMARY KEY, flag_value VARCHAR)"""
        )
        row = self._conn.execute(
            """SELECT COUNT(1) FROM system_flags
               WHERE flag_key = 'integrity_verified' AND flag_value = 'false'"""
        ).fetchone()
        return bool(row and int(row[0]) > 0)

    def system_lock(self, lock: bool = True) -> None:
        """Zablokuj lub odblokuj system z powodu naruszenia integralności.

        Args:
            lock: True = zablokuj (read-only), False = odblokuj.
        """
        self._conn.execute(
            """CREATE TABLE IF NOT EXISTS system_flags
               (flag_key VARCHAR PRIMARY KEY, flag_value VARCHAR)"""
        )
        if lock:
            self._conn.execute(
                "INSERT OR REPLACE INTO system_flags VALUES ('integrity_verified', 'false')"
            )
            logger.critical("[INTEGRITY] System LOCKED — read-only mode activated")
        else:
            self._conn.execute(
                "DELETE FROM system_flags WHERE flag_key = 'integrity_verified'"
            )
            logger.info("[INTEGRITY] System UNLOCKED — write operations resumed")

    def list_violations(
        self,
        limit: int = 50,
        only_open: bool = False,
    ) -> list[dict[str, Any]]:
        """Pobierz listę naruszeń integralności.

        Args:
            limit: Maksymalna liczba wyników.
            only_open: Jeśli True, tylko nierozwiązane.

        Returns:
            Lista słowników z polami violation_id, trace_id, detected_at, resolved_at.
        """
        query = (
            """SELECT violation_id, first_inconsistent_trace, expected_hash,
                      actual_hash, details_json, detected_at, resolved_at, resolved_by
               FROM integrity_violations"""
        )
        if only_open:
            query += " WHERE resolved_at IS NULL"
        query += " ORDER BY detected_at DESC LIMIT ?"

        rows = self._conn.execute(query, (limit,)).fetchall()
        return [
            {
                "violation_id": str(r[0]),
                "first_inconsistent_trace": str(r[1]),
                "expected_hash": str(r[2]),
                "actual_hash": str(r[3]),
                "details": json.loads(r[4]) if r[4] else None,
                "detected_at": str(r[5]),
                "resolved_at": str(r[6]) if r[6] else None,
                "resolved_by": str(r[7]) if r[7] else None,
            }
            for r in rows
        ]

    def resolve_violation(
        self,
        violation_id: str,
        resolved_by: str = "system",
    ) -> bool:
        """Oznacz naruszenie jako rozwiązane.

        Args:
            violation_id: UUID naruszenia.
            resolved_by: Kto rozwiązał.

        Returns:
            True jeśli znaleziono i zaktualizowano.
        """
        now = datetime.now(timezone.utc).isoformat()
        self._conn.execute(
            """UPDATE integrity_violations
               SET resolved_at = ?, resolved_by = ?
               WHERE violation_id = ? AND resolved_at IS NULL""",
            (now, resolved_by, violation_id),
        )
        # DuckDB rowcount is unreliable, check if updated
        check = self._conn.execute(
            "SELECT resolved_at FROM integrity_violations WHERE violation_id = ?",
            (violation_id,),
        ).fetchone()
        return bool(check and check[0] is not None)

    # ── Checkpoint ──────────────────────────────────────────────────

    def _save_checkpoint(self, report: IntegrityReport) -> None:
        """Zapisz checkpoint po weryfikacji."""
        if report.total_records == 0:
            return

        last_row = self._conn.execute(
            "SELECT trace_id, timestamp FROM decision_traces "
            "ORDER BY timestamp DESC LIMIT 1"
        ).fetchone()
        if not last_row:
            return

        cp_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        self._conn.execute(
            """INSERT INTO integrity_checkpoints
               (checkpoint_id, last_trace_id, last_timestamp, verified_at,
                total_verified, status)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (
                cp_id,
                str(last_row[0]),
                str(last_row[1]),
                now,
                report.total_records,
                report.status,
            ),
        )

    def get_latest_checkpoint(self) -> dict[str, Any] | None:
        """Pobierz najnowszy checkpoint.

        Returns:
            Słownik z danymi checkpointu lub None.
        """
        row = self._conn.execute(
            "SELECT last_trace_id, last_timestamp, total_verified, "
            "verified_at, status FROM integrity_checkpoints "
            "ORDER BY verified_at DESC LIMIT 1"
        ).fetchone()
        if not row:
            return None
        return {
            "last_trace_id": str(row[0]),
            "last_timestamp": str(row[1]),
            "total_verified": int(row[2]),
            "verified_at": str(row[3]),
            "status": str(row[4]),
        }
