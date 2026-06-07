"""
RiskGuard — dynamiczny strażnik ryzyka oparty o progi ufności.

Część V drugiej połowy szkieletu.

Przechowuje reguły w tabeli risk_thresholds i stosuje first-match-wins
w zależności od formy opodatkowania, typu wydatku i konkretnego pola.

Nowość (per-field): każda reguła może dotyczyć konkretnego pola faktury
(np. vat_rate, total_net, vendor_nip), a wynik jest agregowany przez
wybór najbardziej restrykcyjnego progu spośród wszystkich pól.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
import pendulum
from typing import Any

import duckdb

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

# ── Schema ───────────────────────────────────────────────────────────────────

RISK_THRESHOLDS_SCHEMA = """
CREATE TABLE IF NOT EXISTS risk_thresholds (
    rule_id       VARCHAR PRIMARY KEY,
    condition_json VARCHAR NOT NULL,
    output_json   VARCHAR NOT NULL,
    valid_from    DATE NOT NULL,
    valid_to      DATE,
    priority      INTEGER NOT NULL DEFAULT 100,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by    VARCHAR NOT NULL DEFAULT 'system'
);
CREATE INDEX IF NOT EXISTS idx_risk_thresholds_valid
    ON risk_thresholds(valid_from, valid_to, priority);
"""

# ── Default risk thresholds (per-field) ─────────────────────────────────────

DEFAULT_RISK_THRESHOLDS: list[dict[str, Any]] = [
    # CIT standard — very high bar for VAT rate
    {
        "condition_json": {"tax_form": "CIT_STANDARD", "field": "vat_rate"},
        "output_json": {"required_ml_confidence": 0.98, "action_if_below": "BLOCK_AND_ALERT"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    # CIT standard — high for amount fields
    {
        "condition_json": {"tax_form": "CIT_STANDARD", "field": "total_net"},
        "output_json": {"required_ml_confidence": 0.95, "action_if_below": "BLOCK_AND_ALERT"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    # CIT Estonian — high bar for critical fields
    {
        "condition_json": {"tax_form": "CIT_ESTONIAN", "field": "vat_rate"},
        "output_json": {"required_ml_confidence": 0.95, "action_if_below": "BLOCK_AND_ALERT"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    # Linear tax — moderate
    {
        "condition_json": {"tax_form": "LINEAR"},
        "output_json": {"required_ml_confidence": 0.85, "action_if_below": "TRIAGE_QUEUE"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    # Lump sum — low for net (mistake doesn't affect tax)
    {
        "condition_json": {"tax_form": "LUMP_SUM", "field": "total_net"},
        "output_json": {"required_ml_confidence": 0.60, "action_if_below": "TRIAGE_QUEUE"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    # Lump sum — higher for vat_rate (VAT declaration risk)
    {
        "condition_json": {"tax_form": "LUMP_SUM", "field": "vat_rate"},
        "output_json": {"required_ml_confidence": 0.95, "action_if_below": "TRIAGE_QUEUE"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    # Mixed auto expenses — always high bar
    {
        "condition_json": {"expense_type": "mixed_auto"},
        "output_json": {"required_ml_confidence": 0.90, "action_if_below": "BLOCK_AND_ALERT"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
    # Rep costs — high bar for any field
    {
        "condition_json": {"expense_type": "representation"},
        "output_json": {"required_ml_confidence": 0.95, "action_if_below": "BLOCK_AND_ALERT"},
        "valid_from": "2024-01-01",
        "priority": 10,
    },
]


# ── Data structures ──────────────────────────────────────────────────────────


@dataclass(frozen=True)
class RiskThreshold:
    """Próg ryzyka dla konkretnego kontekstu podatkowego."""
    required_ml_confidence: float
    action_if_below: str  # BLOCK_AND_ALERT | TRIAGE_QUEUE | AUTO_POST


@dataclass(frozen=True)
class RiskVerdict:
    """Wynik ewaluacji RiskGuard — zagregowany dla wszystkich pól faktury.

    Attributes:
        is_safe: True jeśli wszystkie pola spełniają progi.
        action: AUTO_POST | TRIAGE_QUEUE | BLOCK_AND_ALERT (najbardziej restrykcyjna).
        reason: Uzasadnienie — które pole i dlaczego.
        required_for_field: Mapa {field_name: required_confidence} dla audytu.
    """
    is_safe: bool
    action: str
    reason: str = ""
    required_for_field: dict[str, float] = field(default_factory=dict)


_ACTION_PRIORITY = {
    "AUTO_POST": 0,
    "TRIAGE_QUEUE": 1,
    "BLOCK_AND_ALERT": 2,
}
"""Priority order for actions: higher number = more restrictive."""


def ensure_schema(conn: duckdb.DuckDBPyConnection) -> None:
    """Create risk_thresholds table if not present."""
    conn.execute(RISK_THRESHOLDS_SCHEMA)


def seed_default_thresholds(conn: duckdb.DuckDBPyConnection) -> None:
    """Insert default risk thresholds only if table is empty."""
    count = conn.execute("SELECT COUNT(1) FROM risk_thresholds").fetchone()[0]
    if count > 0:
        return
    for rule in DEFAULT_RISK_THRESHOLDS:
        conn.execute(
            """INSERT INTO risk_thresholds
               (rule_id, condition_json, output_json, valid_from, valid_to, priority, created_by)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                str(uuid.uuid4()),
                msgspec_dumps(rule["condition_json"], ensure_ascii=False, sort_keys=True),
                msgspec_dumps(rule["output_json"], ensure_ascii=False, sort_keys=True),
                rule["valid_from"],
                rule.get("valid_to"),
                rule["priority"],
                "system",
            ),
        )


# ── RiskGuard ────────────────────────────────────────────────────────────────


class RiskGuard:
    """Strażnik ryzyka — odczytuje aktywne reguły i zwraca próg ufności.

    Args:
        conn: DuckDB connection z tabelą risk_thresholds.
    """

    DEFAULT_THRESHOLD = RiskThreshold(
        required_ml_confidence=0.85,
        action_if_below="BLOCK_AND_ALERT",
    )

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        ensure_schema(conn)

    def get_threshold(
        self,
        tax_form: str = "",
        expense_type: str = "",
        field: str = "",
    ) -> RiskThreshold:
        """Zwróć próg ryzyka dla danego kontekstu (first-match-wins).

        Args:
            tax_form: Forma opodatkowania.
            expense_type: Typ wydatku.
            field: Konkretne pole faktury (np. vat_rate, total_net, vendor_nip).

        Returns:
            RiskThreshold z wymaganym poziomem ufności i akcją.
        """
        rows = self._conn.execute(
            """SELECT condition_json, output_json, priority
               FROM risk_thresholds
               WHERE valid_from <= CURRENT_DATE
                 AND (valid_to IS NULL OR valid_to >= CURRENT_DATE)
               ORDER BY priority ASC, valid_from DESC""",
        ).fetchall()

        for cond_json_raw, output_json_raw, priority in rows:
            condition = msgspec_loads(cond_json_raw) if isinstance(cond_json_raw, str) else cond_json_raw
            output = msgspec_loads(output_json_raw) if isinstance(output_json_raw, str) else output_json_raw

            rule_tax_form = condition.get("tax_form", "")
            rule_expense = condition.get("expense_type", "")
            rule_field = condition.get("field", "")

            # Match: if rule specifies tax_form, it must match
            if rule_tax_form and rule_tax_form != tax_form:
                continue
            # Match: if rule specifies expense_type, it must match
            if rule_expense and rule_expense != expense_type:
                continue
            # Match: if rule specifies field, it must match
            if rule_field and rule_field != field:
                continue

            return RiskThreshold(
                required_ml_confidence=float(output.get("required_ml_confidence", 0.85)),
                action_if_below=str(output.get("action_if_below", "BLOCK_AND_ALERT")),
            )

        return self.DEFAULT_THRESHOLD

    def evaluate(
        self,
        fields_with_confidence: dict[str, float],
        tax_form: str = "",
        expense_type: str = "",
    ) -> RiskVerdict:
        """Ewaluacja wszystkich pól faktury względem progów ryzyka.

        Dla każdego pola w ``fields_with_confidence``:
          1. Znajdź pasującą regułę (first-match-wins) wg ``tax_form``, ``expense_type``, ``field``.
          2. Jeśli confidence < required → zapamiętaj naruszenie.
          3. Wybierz najbardziej restrykcyjną akcję i najwyższy próg.

        Args:
            fields_with_confidence: Mapa {nazwa_pola: confidence} (np. {"vat_rate": 0.70, "total_net": 0.95}).
            tax_form: Forma opodatkowania.
            expense_type: Typ wydatku.

        Returns:
            RiskVerdict z zagregowaną decyzją.
        """
        if not fields_with_confidence:
            return RiskVerdict(is_safe=True, action="AUTO_POST", reason="Brak pól do weryfikacji")

        max_action = "AUTO_POST"
        max_priority = 0
        worst_reason = ""
        required_map: dict[str, float] = {}

        for field_name, confidence in fields_with_confidence.items():
            threshold = self.get_threshold(
                tax_form=tax_form,
                expense_type=expense_type,
                field=field_name,
            )
            required_confidence = threshold.required_ml_confidence
            required_map[field_name] = required_confidence

            action_priority = _ACTION_PRIORITY.get(threshold.action_if_below, 0)

            if confidence < required_confidence:
                # Violation: this field doesn't meet the threshold
                if action_priority > max_priority:
                    max_priority = action_priority
                    max_action = threshold.action_if_below
                    worst_reason = (
                        f"Field '{field_name}' confidence {confidence:.2f} < required {required_confidence:.2f} "
                        f"for {tax_form or 'any'} / {expense_type or 'any'}"
                    )
            else:
                # Field passes — but the threshold's action might still affect overall
                if action_priority > max_priority:
                    max_priority = action_priority
                    max_action = threshold.action_if_below

        is_safe = max_action == "AUTO_POST"
        return RiskVerdict(
            is_safe=is_safe,
            action=max_action,
            reason=worst_reason or f"All {len(fields_with_confidence)} fields meet thresholds",
            required_for_field=required_map,
        )

    # ── Threshold CRUD ───────────────────────────────────────────────────

    def add_threshold(
        self,
        condition: dict[str, Any],
        output: dict[str, Any],
        valid_from: str | date = "2024-01-01",
        valid_to: str | date | None = None,
        priority: int = 100,
        created_by: str = "admin",
    ) -> str:
        """Dodaj nową regułę progu ryzyka (append-only).

        Używa ``sort_keys=True`` dla deterministycznego JSON.
        """
        rule_id = str(uuid.uuid4())
        vf = valid_from.isoformat() if isinstance(valid_from, date) else valid_from
        vt = valid_to.isoformat() if isinstance(valid_to, date) else valid_to

        self._conn.execute(
            """INSERT INTO risk_thresholds
               (rule_id, condition_json, output_json, valid_from, valid_to, priority, created_by)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                rule_id,
                msgspec_dumps(condition, ensure_ascii=False, sort_keys=True),
                msgspec_dumps(output, ensure_ascii=False, sort_keys=True),
                vf,
                vt,
                priority,
                created_by,
            ),
        )
        return rule_id

    def deprecate_threshold(self, rule_id: str, created_by: str = "admin") -> bool:
        """Dezaktywuj regułę przez ustawienie valid_to = dzisiaj.

        Returns:
            True jeśli reguła znaleziona i zdezaktywowana.
        """
        today = pendulum.now().date().isoformat()
        result = self._conn.execute(
            "UPDATE risk_thresholds SET valid_to = CAST(? AS DATE) "
            "WHERE rule_id = ? AND valid_to IS NULL",
            (today, rule_id),
        )
        return result.rowcount > 0

    def list_thresholds(self) -> list[dict[str, Any]]:
        """Lista wszystkich reguł progów ryzyka (aktywnych i nieaktywnych)."""
        rows = self._conn.execute(
            """SELECT rule_id, condition_json, output_json, valid_from, valid_to, priority, created_at
               FROM risk_thresholds
               ORDER BY priority ASC, valid_from DESC""",
        ).fetchall()
        return [
            {
                "rule_id": str(r[0]),
                "condition": msgspec_loads(r[1]) if r[1] else {},
                "output": msgspec_loads(r[2]) if r[2] else {},
                "valid_from": str(r[3]),
                "valid_to": str(r[4]) if r[4] else None,
                "priority": int(r[5]),
                "created_at": str(r[6]),
            }
            for r in rows
        ]

    def list_thresholds_history(self) -> list[dict[str, Any]]:
        """Historia zmian reguł — wszystkie wersje z datami."""
        return self.list_thresholds()  # Table is append-only, so all entries ARE history
