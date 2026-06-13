"""
Temporal Manager — zarządzanie temporalnością reguł podatkowych.

Element 2 z dokumentu: zapewnia automatyczne stosowanie historycznych
stawek podatkowych poprzez filtrowanie reguł według daty transakcji.

Każda reguła ma:
  - valid_from (DATE) — data rozpoczęcia obowiązywania (włącznie)
  - valid_to (DATE, NULLABLE) — data zakończenia (włącznie), NULL = bezterminowo

Dzięki temporalności:
  - Faktura z 2021 roku używa stawek z 2021 roku
  - Zmiana przepisów = nowa reguła (nie modyfikacja starej)
  - Stan prawny z dowolnego dnia jest odtwarzalny
"""

from __future__ import annotations

from msgspec import Struct
from typing import Any, final

import duckdb
import pendulum


class TemporalRule(Struct, frozen=True):
    """A single rule with its temporal window.

    Attributes:
        rule_id: UUID reguły.
        condition_sql: SQL WHERE expression.
        action_json: Raw JSON action string.
        priority: Lower = higher priority.
        valid_from: Start date (inclusive).
        valid_to: End date (inclusive), None = active indefinitely.
    """

    rule_id: str
    condition_sql: str
    action_json: str
    priority: int
    valid_from: pendulum.Date
    valid_to: pendulum.Date | None


@final
class TemporalManager:
    """Menedżer Temporalny — filtruje reguły według daty transakcji.

    Używa indeksu na (valid_from, valid_to, priority) dla wydajności.

    Usage:
        manager = TemporalManager(conn)
        rules = manager.get_active_rules(pendulum.Date(2024, 6, 1))
    """

    # SQL template for fetching rules active on a given date
    _ACTIVE_RULES_QUERY = """
        SELECT rule_id, condition_sql, action_json, priority,
               valid_from, valid_to
        FROM tax_rules
        WHERE valid_from <= CAST(? AS DATE)
          AND (valid_to IS NULL OR valid_to >= CAST(? AS DATE))
        ORDER BY priority ASC, valid_from DESC, rule_id ASC
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn

    def get_active_rules(self, transaction_date: pendulum.Date | str) -> list[TemporalRule]:
        """Pobierz reguły aktywne w danej dacie transakcji.

        Filtruje reguły według valid_from / valid_to i sortuje
        według priorytetu (ASC), a dla równego priorytetu — według
        daty rozpoczęcia (DESC, nowsze wygrywają), a dla remisu —
        według rule_id (ASC, stabilne sortowanie).

        Args:
            transaction_date: Data transakcji (date lub YYYY-MM-DD string).

        Returns:
            Lista TemporalRule aktywnych w podanej dacie, posortowana.
        """
        if isinstance(transaction_date, pendulum.Date):
            date_str = transaction_date.isoformat()
        else:
            date_str = transaction_date

        rows = self._conn.execute(
            self._ACTIVE_RULES_QUERY,
            (date_str, date_str),
        ).fetchall()

        return [
            TemporalRule(
                rule_id=str(r[0]),
                condition_sql=str(r[1]),
                action_json=str(r[2]),
                priority=int(r[3]),
                valid_from=pendulum.Date.fromisoformat(str(r[4]))
                if r[4]
                else pendulum.now().date(),
                valid_to=pendulum.Date.fromisoformat(str(r[5])) if r[5] else None,
            )
            for r in rows
        ]

    def is_rule_active_on(
        self,
        rule_id: str,
        transaction_date: pendulum.Date | str,
    ) -> bool:
        """Sprawdź, czy konkretna reguła była aktywna w podanej dacie.

        Args:
            rule_id: UUID reguły.
            transaction_date: Data do sprawdzenia.

        Returns:
            True jeśli reguła była aktywna.
        """
        if isinstance(transaction_date, pendulum.Date):
            date_str = transaction_date.isoformat()
        else:
            date_str = transaction_date

        row = self._conn.execute(
            """SELECT COUNT(1) FROM tax_rules
               WHERE rule_id = ?
                 AND valid_from <= CAST(? AS DATE)
                 AND (valid_to IS NULL OR valid_to >= CAST(? AS DATE))""",
            (rule_id, date_str, date_str),
        ).fetchone()
        return int(row[0]) > 0 if row else False

    def get_validity_window(self, rule_id: str) -> tuple[date, date | None] | None:
        """Pobierz okno ważności reguły.

        Args:
            rule_id: UUID reguły.

        Returns:
            (valid_from, valid_to) lub None jeśli reguła nie istnieje.
        """
        row = self._conn.execute(
            "SELECT valid_from, valid_to FROM tax_rules WHERE rule_id = ?",
            (rule_id,),
        ).fetchone()
        if not row:
            return None
        vf = pendulum.Date.fromisoformat(str(row[0])) if row[0] else None
        vt = pendulum.Date.fromisoformat(str(row[1])) if row[1] else None
        if vf is None:
            return None
        return (vf, vt)

    @staticmethod
    def validate_temporal_overlap(
        rules: list[TemporalRule],
    ) -> list[dict[str, Any]]:
        """Sprawdź, czy reguły o tych samych warunkach nie nachodzą na siebie.

        Wykrywa potencjalne konflikty temporalne dla reguł z tym samym
        condition_sql, które mają nachodzące okna ważności.

        Args:
            rules: Lista reguł do sprawdzenia.

        Returns:
            Lista konfliktów (pusta = brak).
        """
        conflicts: list[dict[str, Any]] = []
        # Group by condition_sql
        by_condition: dict[str, list[TemporalRule]] = {}
        for rule in rules:
            by_condition.setdefault(rule.condition_sql, []).append(rule)

        for condition, group in by_condition.items():
            if len(group) < 2:
                continue
            for i, a in enumerate(group):
                for b in group[i + 1 :]:
                    a_end = a.valid_to or pendulum.Date(9999, 12, 31)
                    b_end = b.valid_to or date.max
                    # Check overlap: a_start <= b_end and b_start <= a_end
                    if a.valid_from <= b_end and b.valid_from <= a_end:
                        conflicts.append(
                            {
                                "condition_sql": condition,
                                "rule_a": a.rule_id,
                                "rule_b": b.rule_id,
                                "window_a": f"{a.valid_from} – {a.valid_to or '∞'}",
                                "window_b": f"{b.valid_from} – {b.valid_to or '∞'}",
                            }
                        )
        return conflicts
