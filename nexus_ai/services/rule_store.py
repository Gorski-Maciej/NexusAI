"""
Rule Store — fizyczne repozytorium reguł podatkowych (Element 1).

Magazyn reguł w DuckDB z:
  - Append-only — reguły nigdy nie są modyfikowane, tylko dodawane nowe wersje
  - Temporalnością — valid_from / valid_to dla historycznych stawek
  - Priorytetami — first-match-wins
  - Indeksami dla wydajności
  - Pełnym audytem (created_at, created_by)
  - Automatycznym zamykaniem reguł (close_rule)

Usage:
    store = RuleStore(conn)
    store.ensure_schema()
    rule_id = store.add_rule(
        condition_sql="category_code = 'FUEL'",
        action={"vat_rate": "0.23"},
    )
    rules = store.get_active_rules(date(2024, 6, 1))
"""

from __future__ import annotations

import uuid
from datetime import date
from typing import Any

import duckdb
import pendulum

from nexus_ai.core.msgspec_utils import msgspec_dumps

# ── Full schema with all indexes ───────────────────────────────────────

TAX_RULES_SCHEMA = """
CREATE TABLE IF NOT EXISTS tax_rules (
    rule_id              VARCHAR PRIMARY KEY,
    condition_sql        VARCHAR NOT NULL,
    action_json          VARCHAR NOT NULL,
    valid_from           DATE NOT NULL,
    valid_to             DATE,
    priority             INTEGER NOT NULL DEFAULT 100,
    description_template VARCHAR,
    rule_set_id          VARCHAR NOT NULL DEFAULT '',
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by           VARCHAR NOT NULL DEFAULT 'system'
);

-- Composite index for temporal queries (most common access pattern)
CREATE INDEX IF NOT EXISTS idx_tax_rules_temporal
    ON tax_rules(valid_from, valid_to, priority, rule_set_id);

-- Individual indexes for partial queries
CREATE INDEX IF NOT EXISTS idx_tax_rules_valid_from
    ON tax_rules(valid_from);

CREATE INDEX IF NOT EXISTS idx_tax_rules_valid_to
    ON tax_rules(valid_to);

CREATE INDEX IF NOT EXISTS idx_tax_rules_priority
    ON tax_rules(priority);

CREATE INDEX IF NOT EXISTS idx_tax_rules_set
    ON tax_rules(rule_set_id);

CREATE INDEX IF NOT EXISTS idx_tax_rules_created
    ON tax_rules(created_at DESC);
"""

# ── Audit log for rule changes ─────────────────────────────────────────

RULE_CHANGE_LOG_SCHEMA = """
CREATE TABLE IF NOT EXISTS rule_change_log (
    change_id    VARCHAR PRIMARY KEY,
    rule_id      VARCHAR NOT NULL,
    change_type  VARCHAR NOT NULL,  -- 'created' | 'closed'
    old_value    VARCHAR,
    new_value    VARCHAR,
    changed_by   VARCHAR NOT NULL,
    changed_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_rcl_rule
    ON rule_change_log(rule_id);
CREATE INDEX IF NOT EXISTS idx_rcl_changed
    ON rule_change_log(changed_at);
"""


class RuleStore:
    """Magazyn Reguł — repozytorium reguł podatkowych.

    Zapewnia:
      - Append-only lifecycle (add_rule, close_rule)
      - Temporal query (get_active_rules)
      - Pełną historię zmian
      - Indeksy dla wydajności

    Usage:
        store = RuleStore(conn)
        store.ensure_schema()
        rules = store.get_active_rules(txn_date)
        for rule in rules:
            print(rule.rule_id, rule.condition_sql)
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn

    # ── Schema management ──────────────────────────────────────────

    def ensure_schema(self) -> None:
        """Create tax_rules table and indexes if not present."""
        self._conn.execute(TAX_RULES_SCHEMA)
        self._conn.execute(RULE_CHANGE_LOG_SCHEMA)
        # Backward-compatible migration for new columns
        for col, col_type in [("description_template", "VARCHAR"), ("rule_set_id", "VARCHAR NOT NULL DEFAULT ''")]:
            try:
                self._conn.execute(
                    f"ALTER TABLE tax_rules ADD COLUMN IF NOT EXISTS {col} {col_type}"
                )
            except Exception:
                pass

    # ── CRUD: append-only lifecycle ─────────────────────────────────

    def add_rule(
        self,
        condition_sql: str,
        action: dict[str, Any],
        valid_from: str | date = "2024-01-01",
        valid_to: str | date | None = None,
        priority: int = 100,
        description_template: str | None = None,
        rule_set_id: str = "",
        created_by: str = "system",
    ) -> str:
        """Dodaj nową regułę (append-only — nigdy nie aktualizuje istniejących).

        Args:
            condition_sql: Warunek SQL (np. ``category_code = 'FUEL'``).
            action: Słownik werdyktu (np. ``{"vat_rate": "0.23"}``).
            valid_from: Data rozpoczęcia obowiązywania.
            valid_to: Data zakończenia (None = bezterminowo).
            priority: Niższa = wyższy priorytet (0 = najwyższy).
            description_template: Opcjonalny szablon opisu.
            rule_set_id: Identyfikator zestawu reguł (np. "CIT_STANDARD", "LUMP_SUM").
                Pusty string oznacza domyślny zestaw reguł.
            created_by: Identyfikator twórcy reguły.

        Returns:
            UUID nowej reguły.
        """
        rule_id = str(uuid.uuid4())
        vf = valid_from.isoformat() if isinstance(valid_from, date) else valid_from
        vt = valid_to.isoformat() if isinstance(valid_to, date) else valid_to
        now = pendulum.now("UTC").isoformat()

        self._conn.execute(
            """INSERT INTO tax_rules
               (rule_id, condition_sql, action_json, valid_from, valid_to,
                priority, description_template, rule_set_id, created_at, created_by)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                rule_id,
                condition_sql,
                msgspec_dumps(action, ensure_ascii=False),
                vf,
                vt,
                priority,
                description_template,
                rule_set_id,
                now,
                created_by,
            ),
        )

        # Log the change
        self._conn.execute(
            """INSERT INTO rule_change_log
               (change_id, rule_id, change_type, new_value, changed_by, changed_at)
               VALUES (?, ?, 'created', ?, ?, ?)""",
            (str(uuid.uuid4()), rule_id, msgspec_dumps(action, ensure_ascii=False), created_by, now),
        )

        return rule_id

    def close_rule(
        self,
        rule_id: str,
        valid_to: str | date | None = None,
        closed_by: str = "system",
    ) -> bool:
        """Zamknij regułę — ustaw valid_to na podaną datę (lub dzisiaj).

        To jedyna dozwolona mutacja istniejącej reguły.
        Zamknięta reguła nie będzie już aktywna dla dat po valid_to.

        Args:
            rule_id: UUID reguły do zamknięcia.
            valid_to: Data zamknięcia (domyślnie dzisiaj).
            closed_by: Kto zamyka regułę.

        Returns:
            True jeśli reguła została zamknięta, False jeśli nie znaleziono
            lub już była zamknięta.
        """
        if valid_to is None:
            valid_to = pendulum.now().date()
        vt = valid_to.isoformat() if isinstance(valid_to, date) else valid_to
        now = pendulum.now("UTC").isoformat()

        # Sprawdź czy reguła istnieje i jest otwarta
        row = self._conn.execute(
            "SELECT rule_id, valid_to FROM tax_rules WHERE rule_id = ? AND valid_to IS NULL",
            (rule_id,),
        ).fetchone()

        if not row:
            return False

        self._conn.execute(
            "UPDATE tax_rules SET valid_to = ? WHERE rule_id = ? AND valid_to IS NULL",
            (vt, rule_id),
        )

        # Log the change
        self._conn.execute(
            """INSERT INTO rule_change_log
               (change_id, rule_id, change_type, old_value, new_value, changed_by, changed_at)
               VALUES (?, ?, 'closed', ?, ?, ?, ?)""",
            (str(uuid.uuid4()), rule_id, None, vt, closed_by, now),
        )

        return True

    # ── Query methods ──────────────────────────────────────────────

    def get_active_rules(
        self,
        transaction_date: str | date,
        rule_set_id: str | None = None,
    ) -> list[dict[str, Any]]:
        """Pobierz reguły aktywne w danej dacie.

        Filtruje po valid_from / valid_to i sortuje po priority ASC.
        Opcjonalnie filtruje po rule_set_id.

        Args:
            transaction_date: Data transakcji (ISO string lub date).
            rule_set_id: Opcjonalny filtr zestawu reguł (None = wszystkie).

        Returns:
            Lista słowników reguł, posortowana według priorytetu.
        """
        if isinstance(transaction_date, date):
            date_str = transaction_date.isoformat()
        else:
            date_str = transaction_date

        if rule_set_id is not None:
            rows = self._conn.execute(
                """SELECT rule_id, condition_sql, action_json, priority,
                          valid_from, valid_to, description_template,
                          rule_set_id, created_at, created_by
                   FROM tax_rules
                   WHERE rule_set_id = ?
                     AND valid_from <= CAST(? AS DATE)
                     AND (valid_to IS NULL OR valid_to >= CAST(? AS DATE))
                   ORDER BY priority ASC, valid_from DESC, rule_id ASC""",
                (rule_set_id, date_str, date_str),
            ).fetchall()
        else:
            rows = self._conn.execute(
                """SELECT rule_id, condition_sql, action_json, priority,
                          valid_from, valid_to, description_template,
                          rule_set_id, created_at, created_by
                   FROM tax_rules
                   WHERE valid_from <= CAST(? AS DATE)
                     AND (valid_to IS NULL OR valid_to >= CAST(? AS DATE))
                   ORDER BY priority ASC, valid_from DESC, rule_id ASC""",
                (date_str, date_str),
            ).fetchall()

        return [
            {
                "rule_id": str(r[0]),
                "condition_sql": str(r[1]),
                "action_json": str(r[2]),
                "priority": int(r[3]),
                "valid_from": str(r[4]),
                "valid_to": str(r[5]) if r[5] else None,
                "description_template": str(r[6]) if r[6] else None,
                "rule_set_id": str(r[7]) if r[7] else "",
                "created_at": str(r[8]) if r[8] else None,
                "created_by": str(r[9]) if r[9] else None,
            }
            for r in rows
        ]

    def get_rule_sets(self) -> list[str]:
        """Zwróć listę wszystkich unikalnych rule_set_id."""
        rows = self._conn.execute(
            "SELECT DISTINCT rule_set_id FROM tax_rules WHERE rule_set_id != '' ORDER BY rule_set_id"
        ).fetchall()
        return [str(r[0]) for r in rows]

    def delete_rule_set(self, rule_set_id: str) -> int:
        """Usuń wszystkie reguły o podanym rule_set_id (dla resetowania zestawów symulacyjnych)."""
        # Najpierw policz ile zostanie usuniętych
        count_row = self._conn.execute(
            "SELECT COUNT(*) FROM tax_rules WHERE rule_set_id = ?", (rule_set_id,)
        ).fetchone()
        count = int(count_row[0]) if count_row else 0
        # Wykonaj DELETE
        self._conn.execute("DELETE FROM tax_rules WHERE rule_set_id = ?", (rule_set_id,))
        return count

    def get_rule(self, rule_id: str) -> dict[str, Any] | None:
        """Pobierz pojedynczą regułę po ID.

        Args:
            rule_id: UUID reguły.

        Returns:
            Słownik reguły lub None.
        """
        row = self._conn.execute(
            """SELECT rule_id, condition_sql, action_json, priority,
                      valid_from, valid_to, description_template, rule_set_id,
                      created_at, created_by
               FROM tax_rules WHERE rule_id = ?""",
            (rule_id,),
        ).fetchone()
        if not row:
            return None
        return {
            "rule_id": str(row[0]),
            "condition_sql": str(row[1]),
            "action_json": str(row[2]),
            "priority": int(row[3]),
            "valid_from": str(row[4]),
            "valid_to": str(row[5]) if row[5] else None,
            "description_template": str(row[6]) if row[6] else None,
            "rule_set_id": str(row[7]) if row[7] else "",
            "created_at": str(row[8]) if row[8] else None,
            "created_by": str(row[9]) if row[9] else None,
        }

    def list_rules(
        self,
        active_only: bool = False,
        limit: int = 100,
        offset: int = 0,
        date_filter: str | None = None,
    ) -> list[dict[str, Any]]:
        """Listuj reguły z opcjonalnym filtrowaniem.

        Args:
            active_only: Jeśli True, tylko reguły aktywne (valid_to IS NULL).
            limit: Maksymalna liczba wyników.
            offset: Przesunięcie.
            date_filter: Jeśli podana, reguły aktywne na tę datę.

        Returns:
            Lista słowników reguł.
        """
        where = []
        params: list[Any] = []

        if active_only:
            where.append("valid_to IS NULL")
        if date_filter:
            where.append("valid_from <= CAST(? AS DATE) AND (valid_to IS NULL OR valid_to >= CAST(? AS DATE))")
            params.extend([date_filter, date_filter])

        where_clause = " AND ".join(where) if where else "1=1"

        rows = self._conn.execute(
            f"""SELECT rule_id, condition_sql, action_json, priority,
                       valid_from, valid_to, description_template,
                       rule_set_id, created_at, created_by
                FROM tax_rules
                WHERE {where_clause}
                ORDER BY priority ASC, valid_from DESC
                LIMIT ? OFFSET ?""",
            (*params, limit, offset),
        ).fetchall()

        return [
            {
                "rule_id": str(r[0]),
                "condition_sql": str(r[1]),
                "action_json": str(r[2]),
                "priority": int(r[3]),
                "valid_from": str(r[4]),
                "valid_to": str(r[5]) if r[5] else None,
                "description_template": str(r[6]) if r[6] else None,
                "rule_set_id": str(r[7]) if r[7] else "",
                "created_at": str(r[8]) if r[8] else None,
                "created_by": str(r[9]) if r[9] else None,
            }
            for r in rows
        ]

    def count_rules(self, active_only: bool = False) -> int:
        """Policz reguły.

        Args:
            active_only: Jeśli True, tylko aktywne.

        Returns:
            Liczba reguł.
        """
        if active_only:
            row = self._conn.execute(
                "SELECT COUNT(1) FROM tax_rules WHERE valid_to IS NULL"
            ).fetchone()
        else:
            row = self._conn.execute("SELECT COUNT(1) FROM tax_rules").fetchone()
        return int(row[0]) if row else 0

    def get_change_log(self, rule_id: str | None = None, limit: int = 50) -> list[dict[str, Any]]:
        """Pobierz historię zmian reguł.

        Args:
            rule_id: Opcjonalnie filtruj po regule.
            limit: Maksymalna liczba wpisów.

        Returns:
            Lista słowników zmian.
        """
        if rule_id:
            rows = self._conn.execute(
                """SELECT change_id, rule_id, change_type, old_value, new_value,
                          changed_by, changed_at
                   FROM rule_change_log
                   WHERE rule_id = ?
                   ORDER BY changed_at DESC
                   LIMIT ?""",
                (rule_id, limit),
            ).fetchall()
        else:
            rows = self._conn.execute(
                """SELECT change_id, rule_id, change_type, old_value, new_value,
                          changed_by, changed_at
                   FROM rule_change_log
                   ORDER BY changed_at DESC
                   LIMIT ?""",
                (limit,),
            ).fetchall()

        return [
            {
                "change_id": str(r[0]),
                "rule_id": str(r[1]),
                "change_type": str(r[2]),
                "old_value": str(r[3]) if r[3] else None,
                "new_value": str(r[4]) if r[4] else None,
                "changed_by": str(r[5]),
                "changed_at": str(r[6]),
            }
            for r in rows
        ]

    # ── Seed data ──────────────────────────────────────────────────

    def seed_default_rules(self) -> None:
        """Wstaw domyślne reguły podatkowe jeśli tabela jest pusta (idempotentne)."""
        count = self._conn.execute("SELECT COUNT(1) FROM tax_rules").fetchone()
        if count and int(count[0]) > 0:
            return

        from tax.rules import DEFAULT_TAX_RULES
        for rule in DEFAULT_TAX_RULES:
            self.add_rule(
                condition_sql=rule["condition_sql"],
                action=rule["action_json"],
                valid_from=rule["valid_from"],
                valid_to=rule["valid_to"],
                priority=rule["priority"],
                description_template=rule.get("description_template"),
                created_by=rule["created_by"],
            )
