"""
Decision Logger — persists every Council decision to DuckDB for audit & active learning.
"""

from __future__ import annotations

import asyncio
import json
import uuid
from datetime import datetime, timezone
from typing import Any

from core.logger import get_logger
from db.analytics import DuckDBManager

logger = get_logger(__name__)


class DecisionLogger:
    """
    Logs council decisions to DuckDB.
    The table `council_decisions` is created automatically on first use.
    Supports user correction feedback for adaptive weight tuning.
    """

    def __init__(self, duckdb: DuckDBManager) -> None:
        self._duckdb = duckdb
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        """Create the council_decisions table if it doesn't exist."""
        self._duckdb.execute(
            """
            CREATE TABLE IF NOT EXISTS council_decisions (
                id VARCHAR PRIMARY KEY,
                invoice_id VARCHAR,
                alpha_vote JSON,
                beta_vote JSON,
                gamma_vote JSON,
                final_decision VARCHAR,
                trust_score DOUBLE,
                trust_components JSON,
                context JSON,
                timestamp TIMESTAMP,
                user_correction VARCHAR
            )
            """
        )
        self._duckdb.execute(
            "CREATE INDEX IF NOT EXISTS idx_council_decisions_invoice_id "
            "ON council_decisions(invoice_id)"
        )
        self._duckdb.execute(
            "CREATE INDEX IF NOT EXISTS idx_council_decisions_timestamp "
            "ON council_decisions(timestamp)"
        )
        self._duckdb.execute(
            "CREATE INDEX IF NOT EXISTS idx_council_decisions_final "
            "ON council_decisions(final_decision)"
        )

    async def log_decision(
        self,
        invoice_id: str,
        alpha_verdict: dict[str, Any],
        beta_verdict: dict[str, Any],
        gamma_verdict: dict[str, Any],
        final_decision: str,
        trust_score: float,
        trust_components: dict[str, float],
        context: dict[str, Any],
    ) -> None:
        """
        Persist a council decision to DuckDB.
        Runs the DuckDB call in a thread executor to avoid blocking the event loop.
        """
        decision_id = str(uuid.uuid4())
        try:
            await asyncio.to_thread(
                self._duckdb.execute,
                """
                INSERT INTO council_decisions
                (id, invoice_id, alpha_vote, beta_vote, gamma_vote,
                 final_decision, trust_score, trust_components, context,
                 timestamp, user_correction)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    decision_id,
                    invoice_id,
                    json.dumps(alpha_verdict, ensure_ascii=False),
                    json.dumps(beta_verdict, ensure_ascii=False),
                    json.dumps(gamma_verdict, ensure_ascii=False),
                    final_decision,
                    float(trust_score),
                    json.dumps(trust_components, ensure_ascii=False),
                    json.dumps(context, ensure_ascii=False),
                    datetime.now(timezone.utc),
                    None,  # user_correction — populated later
                ),
            )
            logger.debug(
                "[DecisionLogger] logged decision_id=%s invoice_id=%s decision=%s",
                decision_id,
                invoice_id,
                final_decision,
            )
        except Exception as exc:
            logger.error(
                "[DecisionLogger] failed to log invoice_id=%s: %s",
                invoice_id,
                exc,
            )

    async def record_user_correction(
        self,
        invoice_id: str,
        correction: str,
    ) -> None:
        """
        Record a user correction for a previously logged decision.
        correction: what the user actually did (APPROVE, REJECT, etc.)
        This is used by TrustScoreCalculator for adaptive weight tuning.
        """
        try:
            await asyncio.to_thread(
                self._duckdb.execute,
                """
                UPDATE council_decisions
                SET user_correction = ?
                WHERE invoice_id = ? AND user_correction IS NULL
                """,
                (correction, invoice_id),
            )
            logger.info(
                "[DecisionLogger] recorded user correction invoice_id=%s correction=%s",
                invoice_id,
                correction,
            )
        except Exception as exc:
            logger.error(
                "[DecisionLogger] failed to record correction for invoice_id=%s: %s",
                invoice_id,
                exc,
            )

    def get_user_correction_stats(
        self,
        invoice_id: str | None = None,
    ) -> dict[str, Any]:
        """
        Aggregate correction statistics for adaptive weight tuning.
        Returns correction rates per decision component.
        """
        try:
            # Overall stats
            total = self._duckdb.execute(
                "SELECT COUNT(*) FROM council_decisions"
            )[0][0]

            corrected = self._duckdb.execute(
                "SELECT COUNT(*) FROM council_decisions WHERE user_correction IS NOT NULL"
            )[0][0]

            # Decisions by type
            decision_breakdown = self._duckdb.execute(
                """
                SELECT final_decision, COUNT(*) as cnt
                FROM council_decisions
                GROUP BY final_decision
                """
            )

            # Corrections by prior decision type
            correction_breakdown = self._duckdb.execute(
                """
                SELECT final_decision, user_correction, COUNT(*) as cnt
                FROM council_decisions
                WHERE user_correction IS NOT NULL
                GROUP BY final_decision, user_correction
                """
            )

            # Approximate component correction rates based on trust_components
            # We compute the average deviation between trust components and user corrections
            component_stats = self._compute_component_correction_rates()

            return {
                "total_decisions": int(total),
                "total_corrected": int(corrected),
                "correction_rate": round(corrected / max(total, 1), 4),
                "decision_breakdown": {
                    str(row[0]): int(row[1]) for row in decision_breakdown
                },
                "correction_breakdown": [
                    {"from": str(r[0]), "to": str(r[1]), "count": int(r[2])}
                    for r in correction_breakdown
                ],
                **component_stats,
            }
        except Exception as exc:
            logger.error("[DecisionLogger] failed to get correction stats: %s", exc)
            return {
                "total_decisions": 0,
                "total_corrected": 0,
                "correction_rate": 0.0,
                "decision_breakdown": {},
                "correction_breakdown": [],
            }

    def get_decisions_for_invoice(
        self,
        invoice_id: str,
    ) -> list[dict[str, Any]]:
        """Retrieve all council decisions for a specific invoice."""
        try:
            rows = self._duckdb.execute(
                """
                SELECT id, invoice_id, alpha_vote, beta_vote, gamma_vote,
                       final_decision, trust_score, trust_components, context,
                       timestamp, user_correction
                FROM council_decisions
                WHERE invoice_id = ?
                ORDER BY timestamp DESC
                """,
                (invoice_id,),
            )
            return [
                {
                    "id": r[0],
                    "invoice_id": r[1],
                    "alpha_vote": json.loads(r[2]) if isinstance(r[2], str) else r[2],
                    "beta_vote": json.loads(r[3]) if isinstance(r[3], str) else r[3],
                    "gamma_vote": json.loads(r[4]) if isinstance(r[4], str) else r[4],
                    "final_decision": r[5],
                    "trust_score": r[6],
                    "trust_components": json.loads(r[7]) if isinstance(r[7], str) else r[7],
                    "context": json.loads(r[8]) if isinstance(r[8], str) else r[8],
                    "timestamp": r[9],
                    "user_correction": r[10],
                }
                for r in rows
            ]
        except Exception as exc:
            logger.error(
                "[DecisionLogger] failed to get decisions for invoice_id=%s: %s",
                invoice_id,
                exc,
            )
            return []

    def _compute_component_correction_rates(self) -> dict[str, float]:
        """
        Estimate per-component correction rates by analyzing
        how often high-trust decisions get corrected.
        Used for adaptive weight tuning.
        """
        try:
            rows = self._duckdb.execute(
                """
                SELECT trust_components, user_correction
                FROM council_decisions
                WHERE user_correction IS NOT NULL
                """
            )
            if not rows:
                return {
                    "ai_confidence_correction_rate": 0.0,
                    "vendor_reliability_correction_rate": 0.0,
                    "data_consistency_correction_rate": 0.0,
                    "context_trust_correction_rate": 0.0,
                }

            counts = {"ai_confidence": 0, "vendor_reliability": 0, "data_consistency": 0, "context_trust": 0}
            total_corrected = len(rows)

            for row in rows:
                components_raw = row[0]
                if isinstance(components_raw, str):
                    try:
                        components = json.loads(components_raw)
                    except (json.JSONDecodeError, TypeError):
                        continue
                elif isinstance(components_raw, dict):
                    components = components_raw
                else:
                    continue

                # Find the lowest-scoring component — that's the likely cause
                min_comp = min(components, key=lambda k: components.get(k, 1.0))
                if min_comp in counts:
                    counts[min_comp] += 1

            return {
                f"{k}_correction_rate": round(v / max(total_corrected, 1), 4)
                for k, v in counts.items()
            }
        except Exception:
            return {
                "ai_confidence_correction_rate": 0.0,
                "vendor_reliability_correction_rate": 0.0,
                "data_consistency_correction_rate": 0.0,
                "context_trust_correction_rate": 0.0,
            }
