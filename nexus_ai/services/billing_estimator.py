"""
BillingEstimator — estymator kosztów i czasu przetwarzania.

Zgodny z wzorcem DecisionEngine — reguły first-match-wins w tabeli
billing_rules (DuckDB) zamiast w kodzie, temporalne (valid_from/valid_to).

Logika przechowywana w tabeli billing_rules (nie w kodzie).
First-match-wins według typu dokumentu i formy opodatkowania.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Any

import duckdb
import pendulum

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

# ── Schema ───────────────────────────────────────────────────────────────────

BILLING_RULES_SCHEMA = """
CREATE TABLE IF NOT EXISTS billing_rules (
    rule_id       VARCHAR PRIMARY KEY,
    condition_json VARCHAR NOT NULL,
    price_json    VARCHAR NOT NULL,
    valid_from    DATE NOT NULL,
    valid_to      DATE,
    priority      INTEGER NOT NULL DEFAULT 100,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_billing_rules_valid
    ON billing_rules(valid_from, valid_to, priority);
"""

DEFAULT_BILLING_RULES: list[dict[str, Any]] = [
    {
        "condition_json": {"document_type": "invoice_national", "tax_form": "CIT_STANDARD"},
        "price_json": {"price_pln": 1.50, "processing_time_hours": 0.5, "description": "Faktura krajowa CIT"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    {
        "condition_json": {"document_type": "invoice_national", "tax_form": "LUMP_SUM"},
        "price_json": {"price_pln": 1.20, "processing_time_hours": 0.3, "description": "Faktura krajowa ryczałt"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    {
        "condition_json": {"document_type": "invoice_national", "tax_form": "LINEAR"},
        "price_json": {"price_pln": 1.50, "processing_time_hours": 0.5, "description": "Faktura krajowa liniowy"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    {
        "condition_json": {"document_type": "invoice_foreign"},
        "price_json": {"price_pln": 3.00, "processing_time_hours": 1.0, "description": "Faktura zagraniczna"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    {
        "condition_json": {"document_type": "invoice_national", "additional_service": "ksef"},
        "price_json": {"price_pln": 0.50, "processing_time_hours": 0.1, "description": "Eksport KSeF"},
        "valid_from": "2024-01-01",
        "priority": 20,
    },
    {
        "condition_json": {"document_type": "invoice_national", "additional_service": "semantic_guard"},
        "price_json": {"price_pln": 0.30, "processing_time_hours": 0.05, "description": "Weryfikacja semantyczna AI"},
        "valid_from": "2024-01-01",
        "priority": 20,
    },
    {
        "condition_json": {},
        "price_json": {"price_pln": 0.50, "processing_time_hours": 0.2, "description": "Faktura podstawowa"},
        "valid_from": "2024-01-01",
        "priority": 999,
    },
]


@dataclass
class BillingEstimate:
    """Estymacja kosztu i czasu przetwarzania."""
    total_price_pln: float = 0.0
    total_time_hours: float = 0.0
    breakdown: list[dict[str, Any]] | None = None


def ensure_schema(conn: duckdb.DuckDBPyConnection) -> None:
    """Create billing_rules table if not present."""
    conn.execute(BILLING_RULES_SCHEMA)


def seed_default_billing_rules(conn: duckdb.DuckDBPyConnection) -> None:
    """Insert default billing rules if table is empty."""
    count = conn.execute("SELECT COUNT(1) FROM billing_rules").fetchone()[0]
    if count > 0:
        return
    for rule in DEFAULT_BILLING_RULES:
        conn.execute(
            """INSERT INTO billing_rules
               (rule_id, condition_json, price_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (
                str(uuid.uuid4()),
                msgspec_dumps(rule["condition_json"], ensure_ascii=False),
                msgspec_dumps(rule["price_json"], ensure_ascii=False),
                rule["valid_from"],
                rule.get("valid_to"),
                rule["priority"],
            ),
        )


class BillingEstimator:
    """Estymator kosztów przetwarzania dokumentów.

    Args:
        conn: DuckDB connection z tabelą billing_rules.
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        ensure_schema(conn)

    def estimate(
        self,
        document_type: str = "invoice_national",
        tax_form: str = "CIT_STANDARD",
        additional_services: list[str] | None = None,
    ) -> BillingEstimate:
        """Oblicz estymację kosztu i czasu dla danego typu dokumentu.

        Args:
            document_type: Typ dokumentu (invoice_national, invoice_foreign).
            tax_form: Forma opodatkowania.
            additional_services: Lista dodatkowych usług.

        Returns:
            BillingEstimate z podziałem kosztów.
        """
        rules = self._conn.execute(
            """SELECT condition_json, price_json, priority
               FROM billing_rules
               WHERE valid_from <= CURRENT_DATE
                 AND (valid_to IS NULL OR valid_to >= CURRENT_DATE)
               ORDER BY priority ASC""",
        ).fetchall()

        matched: list[dict[str, Any]] = []
        used_rules: set[int] = set()

        for idx, (cond_json, price_json, priority) in enumerate(rules):
            condition = msgspec_loads(cond_json) if isinstance(cond_json, str) else cond_json
            price = msgspec_loads(price_json) if isinstance(price_json, str) else price_json

            if self._matches(condition, document_type, tax_form, additional_services):
                matched.append({
                    "description": price.get("description", ""),
                    "price_pln": float(price.get("price_pln", 0)),
                    "time_hours": float(price.get("processing_time_hours", 0)),
                })
                used_rules.add(idx)

        total_price = sum(m["price_pln"] for m in matched)
        total_time = sum(m["time_hours"] for m in matched)

        return BillingEstimate(
            total_price_pln=total_price,
            total_time_hours=total_time,
            breakdown=matched if matched else None,
        )

    # ── CRUD methods ───────────────────────────────────────────────────

    def add_rule(
        self,
        condition: dict[str, Any],
        price: dict[str, Any],
        valid_from: str = "2024-01-01",
        valid_to: str | None = None,
        priority: int = 100,
    ) -> str:
        """Add a new billing rule (append-only)."""
        rule_id = str(uuid.uuid4())
        self._conn.execute(
            """INSERT INTO billing_rules
               (rule_id, condition_json, price_json, valid_from, valid_to, priority)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (
                rule_id,
                msgspec_dumps(condition, ensure_ascii=False, sort_keys=True),
                msgspec_dumps(price, ensure_ascii=False, sort_keys=True),
                valid_from,
                valid_to,
                priority,
            ),
        )
        return rule_id

    def deprecate_rule(self, rule_id: str) -> bool:
        """Deactivate a billing rule by setting valid_to = today."""
        today = pendulum.now().date().isoformat()
        result = self._conn.execute(
            "UPDATE billing_rules SET valid_to = ? WHERE rule_id = ? AND valid_to IS NULL",
            (today, rule_id),
        )
        return result.rowcount > 0

    def list_rules(self, active_only: bool = True) -> list[dict[str, Any]]:
        """List billing rules."""
        if active_only:
            rows = self._conn.execute(
                """SELECT rule_id, condition_json, price_json, valid_from, valid_to, priority, created_at
                   FROM billing_rules
                   WHERE valid_from <= CURRENT_DATE
                     AND (valid_to IS NULL OR valid_to >= CURRENT_DATE)
                   ORDER BY priority ASC, valid_from DESC"""
            ).fetchall()
        else:
            rows = self._conn.execute(
                """SELECT rule_id, condition_json, price_json, valid_from, valid_to, priority, created_at
                   FROM billing_rules
                   ORDER BY priority ASC, valid_from DESC"""
            ).fetchall()
        return [
            {
                "rule_id": str(r[0]),
                "condition": msgspec_loads(r[1]) if r[1] else {},
                "price": msgspec_loads(r[2]) if r[2] else {},
                "valid_from": str(r[3]),
                "valid_to": str(r[4]) if r[4] else None,
                "priority": int(r[5]),
                "created_at": str(r[6]),
            }
            for r in rows
        ]

    @staticmethod
    def _matches(
        condition: dict[str, Any],
        document_type: str,
        tax_form: str,
        additional_services: list[str] | None,
    ) -> bool:
        """Sprawdź czy warunek reguły pasuje do kontekstu."""
        if not condition:
            return True  # Fallback rule

        # Check document_type
        cond_doc = condition.get("document_type")
        if cond_doc and cond_doc != document_type:
            return False

        # Check tax_form
        cond_tax = condition.get("tax_form")
        if cond_tax and cond_tax != tax_form:
            return False

        # Check additional_service
        cond_service = condition.get("additional_service")
        if cond_service:
            if not additional_services or cond_service not in additional_services:
                return False

        return True
