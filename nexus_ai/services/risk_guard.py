"""
Dynamiczny Strażnik Ryzyka (RiskGuard) — dynamiczne progi pewności AI.

SUPERMOCE:
- Dynamiczne progi w zależności od formy opodatkowania i typu wydatku
- First-match-wins przez reguły w DuckDB (risk_thresholds table)
- Hot-reload przez NATS (risk.thresholds.updated)
- Fallback: domyślny próg 0.85 (bezpieczny konserwatyzm)

Zgodnie z docs/tfgxzd.txt — Dynamiczny Strażnik Ryzyka dla PLEEngine.
"""

from __future__ import annotations

import json
import uuid
from enum import StrEnum
from typing import Any

import duckdb
import pendulum
from structlog import get_logger

logger = get_logger("nexus.services.risk_guard")


class RiskAction(StrEnum):
    """Akcja podejmowana gdy pewność AI jest poniżej progu."""

    BLOCK_AND_ALERT = "BLOCK_AND_ALERT"
    TRIAGE_QUEUE = "TRIAGE_QUEUE"
    ALLOW = "ALLOW"


class RiskThreshold:
    """Próg ryzyka dla kombinacji tax_form + expense_type."""

    def __init__(
        self,
        required_ml_confidence: float = 0.85,
        action_if_below: str = "TRIAGE_QUEUE",
        rule_id: str = "default",
    ) -> None:
        self.required_ml_confidence = required_ml_confidence
        self.action_if_below = action_if_below
        self.rule_id = rule_id


class RiskGuard:
    """Dynamiczny strażnik ryzyka z regułami w DuckDB.

    Zgodnie z tfgxzd.txt:
    - Dla LUMP_SUM: niższy próg (0.60) = więcej AUTO_POST
    - Dla CIT_STANDARD: wyższy próg (0.98) = bezpieczeństwo
    - Dla CIT_ESTONIAN: średni próg (0.95)
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        """Utwórz tabelę risk_thresholds jeśli nie istnieje."""
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS risk_thresholds (
                rule_id              VARCHAR PRIMARY KEY,
                condition_json       VARCHAR NOT NULL,
                output_json          VARCHAR NOT NULL,
                valid_from           DATE NOT NULL,
                valid_to             DATE,
                priority             INTEGER NOT NULL DEFAULT 100,
                created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                created_by           VARCHAR NOT NULL DEFAULT 'system'
            )
        """)
        self._conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_risk_thresholds_valid
            ON risk_thresholds(valid_from, valid_to, priority)
        """)

        # Seed default rules if table is empty
        count = self._conn.execute("SELECT COUNT(*) FROM risk_thresholds").fetchone()[0]
        if count == 0:
            self._seed_defaults()

    def _seed_defaults(self) -> None:
        """Wstaw domyślne progi ryzyka."""
        defaults = [
            # LUMP_SUM — niski próg, dużo AUTO_POST (błędy nie wpływają na podatek)
            {
                "condition": '{"tax_form": "LUMP_SUM", "expense_type": "koszt_operacyjny"}',
                "output": '{"required_ml_confidence": 0.60, "action_if_below": "TRIAGE_QUEUE"}',
                "priority": 10,
            },
            {
                "condition": '{"tax_form": "LUMP_SUM", "expense_type": "reprezentacja"}',
                "output": '{"required_ml_confidence": 0.80, "action_if_below": "TRIAGE_QUEUE"}',
                "priority": 10,
            },
            {
                "condition": '{"tax_form": "LUMP_SUM", "expense_type": "inne"}',
                "output": '{"required_ml_confidence": 0.70, "action_if_below": "TRIAGE_QUEUE"}',
                "priority": 100,
            },
            # CIT_STANDARD — wysoki próg, bezpieczeństwo
            {
                "condition": '{"tax_form": "CIT_STANDARD", "expense_type": "koszt_operacyjny"}',
                "output": '{"required_ml_confidence": 0.98, "action_if_below": "BLOCK_AND_ALERT"}',
                "priority": 10,
            },
            {
                "condition": '{"tax_form": "CIT_STANDARD", "expense_type": "reprezentacja"}',
                "output": '{"required_ml_confidence": 0.99, "action_if_below": "BLOCK_AND_ALERT"}',
                "priority": 10,
            },
            {
                "condition": '{"tax_form": "CIT_STANDARD", "expense_type": "inne"}',
                "output": '{"required_ml_confidence": 0.95, "action_if_below": "TRIAGE_QUEUE"}',
                "priority": 100,
            },
            # CIT_ESTONIAN — średni próg
            {
                "condition": '{"tax_form": "CIT_ESTONIAN", "expense_type": "koszt_operacyjny"}',
                "output": '{"required_ml_confidence": 0.95, "action_if_below": "BLOCK_AND_ALERT"}',
                "priority": 10,
            },
            {
                "condition": '{"tax_form": "CIT_ESTONIAN", "expense_type": "inne"}',
                "output": '{"required_ml_confidence": 0.90, "action_if_below": "TRIAGE_QUEUE"}',
                "priority": 100,
            },
            # LINEAR
            {
                "condition": '{"tax_form": "LINEAR", "expense_type": "koszt_operacyjny"}',
                "output": '{"required_ml_confidence": 0.85, "action_if_below": "TRIAGE_QUEUE"}',
                "priority": 10,
            },
            {
                "condition": '{"tax_form": "LINEAR", "expense_type": "inne"}',
                "output": '{"required_ml_confidence": 0.80, "action_if_below": "TRIAGE_QUEUE"}',
                "priority": 100,
            },
        ]

        for rule in defaults:
            self._conn.execute(
                """INSERT INTO risk_thresholds
                   (rule_id, condition_json, output_json, valid_from, priority, created_by)
                   VALUES (?, ?, ?, '2024-01-01', ?, 'system')""",
                (uuid.uuid4().hex, rule["condition"], rule["output"], rule["priority"]),
            )

        logger.info("[RISK-GUARD] Seeded %d default risk thresholds", len(defaults))

    def get_threshold(
        self,
        tax_form: str,
        expense_type: str = "inne",
        vendor_trust: str = "medium",
    ) -> RiskThreshold:
        """SUPERMOC: Pobierz próg ryzyka dla combo tax_form + expense_type.

        First-match-wins przez DuckDB json_extract_string + ORDER BY priority.
        """
        now_str = pendulum.now("UTC").date().isoformat()

        rows = self._conn.execute(
            """SELECT output_json, rule_id FROM risk_thresholds
               WHERE CAST(? AS DATE) BETWEEN valid_from
                 AND COALESCE(valid_to, '9999-12-31')
                 AND (
                     json_extract_string(condition_json, '$.tax_form') = ?
                     OR json_extract_string(condition_json, '$.tax_form') IS NULL
                 )
                 AND (
                     json_extract_string(condition_json, '$.expense_type') = ?
                     OR json_extract_string(condition_json, '$.expense_type') IS NULL
                 )
               ORDER BY priority ASC, valid_from DESC
               LIMIT 1""",
            (now_str, tax_form, expense_type),
        ).fetchall()

        if rows:
            output = json.loads(str(rows[0][0]))
            return RiskThreshold(
                required_ml_confidence=float(output.get("required_ml_confidence", 0.85)),
                action_if_below=output.get("action_if_below", "TRIAGE_QUEUE"),
                rule_id=str(rows[0][1]),
            )

        return RiskThreshold(
            required_ml_confidence=0.85,
            action_if_below="TRIAGE_QUEUE",
            rule_id="fallback",
        )

    def evaluate(
        self,
        tax_form: str,
        expense_type: str,
        ai_confidence: float,
        vendor_trust: str = "medium",
    ) -> dict[str, Any]:
        """SUPERMOC: Oceń ryzyko i zwróć decyzję.

        Args:
            tax_form: Forma opodatkowania.
            expense_type: Typ wydatku.
            ai_confidence: Pewność AI (0.0-1.0).
            vendor_trust: Zaufanie do kontrahenta.

        Returns:
            Dict z decyzją: action, required_confidence, ai_confidence, reason.
        """
        threshold = self.get_threshold(tax_form, expense_type, vendor_trust)

        if ai_confidence >= threshold.required_ml_confidence:
            return {
                "action": RiskAction.ALLOW,
                "required_confidence": threshold.required_ml_confidence,
                "ai_confidence": ai_confidence,
                "rule_id": threshold.rule_id,
                "reason": f"AI confidence {ai_confidence:.2f} >= required {threshold.required_ml_confidence:.2f}",
            }

        return {
            "action": RiskAction(threshold.action_if_below),
            "required_confidence": threshold.required_ml_confidence,
            "ai_confidence": ai_confidence,
            "rule_id": threshold.rule_id,
            "reason": f"AI confidence {ai_confidence:.2f} < required {threshold.required_ml_confidence:.2f} for {tax_form}/{expense_type}",
        }
