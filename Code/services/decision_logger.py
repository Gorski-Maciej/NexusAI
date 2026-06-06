"""
Decision Logger — rozbudowany logger decyzji z tabelą trust_score_cache i pełnym śledzeniem.

Nowe funkcjonalności:
  - trust_score_cache: tabela przechowująca historyczne trust score dla adaptacji wag
  - log_decision z pełnym kontekstem PLE (STM/LTM/FM)
  - get_trust_score_trend: analiza trendu trust score dla kontrahenta
  - get_correction_stats: statystyki korekt użytkownika dla adaptacyjnego strojenia
"""

from __future__ import annotations

import asyncio
import json
import uuid
from datetime import UTC, datetime
from typing import Any

from core.logger import get_logger
from core.msgspec_utils import msgspec_dumps, msgspec_loads
from db.analytics import DuckDBManager

logger = get_logger(__name__)


class DecisionLogger:
    """
    Logs council decisions to DuckDB z pełnym kontekstem PLE.
    Automatycznie tworzy tabele:
      - council_decisions (główna tabela decyzji)
      - trust_score_cache (cache trust score dla adaptacji wag)
      - council_decisions_meta (metadane i korekty użytkownika)
    """

    def __init__(self, duckdb: DuckDBManager) -> None:
        self._duckdb = duckdb
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        """Create all required tables and indexes."""

        # Główna tabela decyzji
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
                user_correction VARCHAR,
                decision_level VARCHAR,
                council_pattern VARCHAR,
                ple_stm_snapshot JSON,
                ple_ltm_profile JSON
            )
            """
        )

        # Trust Score Cache — do adaptacyjnego strojenia wag
        self._duckdb.execute(
            """
            CREATE TABLE IF NOT EXISTS trust_score_cache (
                id VARCHAR PRIMARY KEY,
                contractor_nip VARCHAR,
                category VARCHAR,
                trust_score DOUBLE,
                ai_confidence DOUBLE,
                vendor_reliability DOUBLE,
                data_consistency DOUBLE,
                context_trust DOUBLE,
                final_decision VARCHAR,
                user_correction VARCHAR,
                timestamp TIMESTAMP
            )
            """
        )

        # Metadane decyzji
        self._duckdb.execute(
            """
            CREATE TABLE IF NOT EXISTS council_decisions_meta (
                decision_id VARCHAR PRIMARY KEY,
                invoice_id VARCHAR,
                deliberation_duration_ms INTEGER,
                levels_used JSON,
                model_swap_count INTEGER,
                timestamp TIMESTAMP
            )
            """
        )

        # Indeksy
        for table, col in [
            ("council_decisions", "invoice_id"),
            ("council_decisions", "timestamp"),
            ("council_decisions", "final_decision"),
            ("trust_score_cache", "contractor_nip"),
            ("trust_score_cache", "timestamp"),
            ("council_decisions_meta", "invoice_id"),
        ]:
            idx_name = f"idx_{table}_{col}"
            self._duckdb.execute(
                f"CREATE INDEX IF NOT EXISTS {idx_name} ON {table}({col})"
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
        decision_level: str = "",
        council_pattern: str = "",
        ple_stm_snapshot: dict[str, Any] | None = None,
        ple_ltm_profile: dict[str, Any] | None = None,
    ) -> None:
        """Persist a council decision with full PLE context."""
        decision_id = str(uuid.uuid4())
        try:
            await asyncio.to_thread(
                self._duckdb.execute,
                """
                INSERT INTO council_decisions
                (id, invoice_id, alpha_vote, beta_vote, gamma_vote,
                 final_decision, trust_score, trust_components, context,
                 timestamp, user_correction, decision_level, council_pattern,
                 ple_stm_snapshot, ple_ltm_profile)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    decision_id,
                    invoice_id,
                    msgspec_dumps(alpha_verdict, ensure_ascii=False),
                    msgspec_dumps(beta_verdict, ensure_ascii=False),
                    msgspec_dumps(gamma_verdict, ensure_ascii=False),
                    final_decision,
                    float(trust_score),
                    msgspec_dumps(trust_components, ensure_ascii=False),
                    msgspec_dumps(context, ensure_ascii=False),
                    datetime.now(UTC),
                    None,  # user_correction — populated later
                    decision_level,
                    council_pattern,
                    msgspec_dumps(ple_stm_snapshot, ensure_ascii=False) if ple_stm_snapshot else None,
                    msgspec_dumps(ple_ltm_profile, ensure_ascii=False) if ple_ltm_profile else None,
                ),
            )

            # Równolegle zapisz do trust_score_cache
            await asyncio.to_thread(
                self._cache_trust_score,
                contractor_nip=str(context.get("contractor_nip", "unknown")),
                category=str(context.get("category", "unknown")),
                trust_score=trust_score,
                trust_components=trust_components,
                final_decision=final_decision,
            )

            logger.debug(
                "[DecisionLogger] logged decision_id=%s invoice_id=%s decision=%s level=%s",
                decision_id, invoice_id, final_decision, decision_level,
            )
        except Exception as exc:
            logger.error("[DecisionLogger] failed to log invoice_id=%s: %s", invoice_id, exc)

    def _cache_trust_score(
        self,
        contractor_nip: str,
        category: str,
        trust_score: float,
        trust_components: dict[str, float],
        final_decision: str,
    ) -> None:
        """Zapisz trust score do cache (synchronicznie, wołane z executa)."""
        cache_id = str(uuid.uuid4())
        self._duckdb.execute(
            """
            INSERT INTO trust_score_cache
            (id, contractor_nip, category, trust_score,
             ai_confidence, vendor_reliability, data_consistency, context_trust,
             final_decision, user_correction, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                cache_id,
                contractor_nip,
                category,
                float(trust_score),
                float(trust_components.get("ai_confidence", 0.0)),
                float(trust_components.get("vendor_reliability", 0.0)),
                float(trust_components.get("data_consistency", 0.0)),
                float(trust_components.get("context_trust", 0.0)),
                final_decision,
                None,  # user_correction
                datetime.now(UTC),
            ),
        )

    async def record_user_correction(
        self,
        invoice_id: str,
        correction: str,
    ) -> None:
        """Record a user correction for a previously logged decision."""
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
            # Równolegle zaktualizuj trust_score_cache
            await asyncio.to_thread(
                self._duckdb.execute,
                """
                UPDATE trust_score_cache
                SET user_correction = ?
                WHERE contractor_nip = (
                    SELECT context->>'contractor_nip'
                    FROM council_decisions
                    WHERE invoice_id = ?
                    LIMIT 1
                ) AND user_correction IS NULL
                """,
                (correction, invoice_id),
            )
            logger.info(
                "[DecisionLogger] recorded user correction invoice_id=%s correction=%s",
                invoice_id, correction,
            )
        except Exception as exc:
            logger.error("[DecisionLogger] failed to record correction for invoice_id=%s: %s", invoice_id, exc)

    def get_trust_score_trend(
        self,
        contractor_nip: str,
        days: int = 30,
    ) -> dict[str, Any]:
        """Analiza trendu trust score dla danego kontrahenta."""
        try:
            rows = self._duckdb.execute(
                """
                SELECT trust_score, ai_confidence, vendor_reliability,
                       data_consistency, context_trust, final_decision, timestamp
                FROM trust_score_cache
                WHERE contractor_nip = ?
                  AND timestamp >= CURRENT_TIMESTAMP - INTERVAL ? DAY
                ORDER BY timestamp DESC
                """,
                (contractor_nip, days),
            )
            if not rows:
                return {"known": False, "records": 0, "avg_trust": 0.0}

            scores = [float(r[0]) for r in rows]
            decisions = [str(r[5]) for r in rows]

            return {
                "known": True,
                "records": len(rows),
                "avg_trust": round(sum(scores) / len(scores), 4),
                "min_trust": round(min(scores), 4),
                "max_trust": round(max(scores), 4),
                "trend": self._compute_trend(scores),
                "decisions_breakdown": {
                    d: decisions.count(d) for d in set(decisions)
                },
                "component_averages": {
                    "ai_confidence": round(sum(float(r[1]) for r in rows) / len(rows), 4) if rows else 0.0,
                    "vendor_reliability": round(sum(float(r[2]) for r in rows) / len(rows), 4) if rows else 0.0,
                    "data_consistency": round(sum(float(r[3]) for r in rows) / len(rows), 4) if rows else 0.0,
                    "context_trust": round(sum(float(r[4]) for r in rows) / len(rows), 4) if rows else 0.0,
                },
            }
        except Exception as exc:
            logger.error("[DecisionLogger] failed to get trust score trend: %s", exc)
            return {"known": False, "records": 0, "avg_trust": 0.0}

    def get_user_correction_stats(
        self,
        invoice_id: str | None = None,
    ) -> dict[str, Any]:
        """Aggregate correction statistics for adaptive weight tuning."""
        try:
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

            # Statystyki według poziomów decyzyjnych
            level_breakdown = self._duckdb.execute(
                """
                SELECT decision_level, COUNT(*) as cnt
                FROM council_decisions
                WHERE decision_level IS NOT NULL AND decision_level != ''
                GROUP BY decision_level
                """
            )

            component_stats = self._compute_component_correction_rates()

            return {
                "total_decisions": int(total),
                "total_corrected": int(corrected),
                "correction_rate": round(corrected / max(total, 1), 4),
                "decision_breakdown": {
                    str(row[0]): int(row[1]) for row in decision_breakdown
                },
                "level_breakdown": {
                    str(row[0]): int(row[1]) for row in level_breakdown
                } if level_breakdown else {},
                "correction_breakdown": [
                    {"from": str(r[0]), "to": str(r[1]), "count": int(r[2])}
                    for r in correction_breakdown
                ],
                **component_stats,
            }
        except Exception as exc:
            logger.error("[DecisionLogger] failed to get correction stats: %s", exc)
            return {
                "total_decisions": 0, "total_corrected": 0, "correction_rate": 0.0,
                "decision_breakdown": {}, "level_breakdown": {}, "correction_breakdown": [],
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
                       timestamp, user_correction, decision_level, council_pattern
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
                    "alpha_vote": msgspec_loads(r[2]) if isinstance(r[2], str) else r[2],
                    "beta_vote": msgspec_loads(r[3]) if isinstance(r[3], str) else r[3],
                    "gamma_vote": msgspec_loads(r[4]) if isinstance(r[4], str) else r[4],
                    "final_decision": r[5],
                    "trust_score": r[6],
                    "trust_components": msgspec_loads(r[7]) if isinstance(r[7], str) else r[7],
                    "context": msgspec_loads(r[8]) if isinstance(r[8], str) else r[8],
                    "timestamp": r[9],
                    "user_correction": r[10],
                    "decision_level": r[11],
                    "council_pattern": r[12],
                }
                for r in rows
            ]
        except Exception as exc:
            logger.error(
                "[DecisionLogger] failed to get decisions for invoice_id=%s: %s",
                invoice_id, exc,
            )
            return []

    def get_decision_summary(
        self,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        """Pobierz podsumowanie ostatnich decyzji."""
        try:
            rows = self._duckdb.execute(
                """
                SELECT invoice_id, final_decision, trust_score,
                       decision_level, council_pattern, timestamp
                FROM council_decisions
                ORDER BY timestamp DESC
                LIMIT ?
                """,
                (limit,),
            )
            return [
                {
                    "invoice_id": str(r[0]),
                    "decision": str(r[1]),
                    "trust_score": float(r[2]) if r[2] else 0.0,
                    "level": str(r[3]) if r[3] else "",
                    "pattern": str(r[4]) if r[4] else "",
                    "timestamp": str(r[5]) if r[5] else "",
                }
                for r in rows
            ]
        except Exception as exc:
            logger.error("[DecisionLogger] failed to get decision summary: %s", exc)
            return []

    def _compute_component_correction_rates(self) -> dict[str, float]:
        """Estimate per-component correction rates."""
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
                        components = msgspec_loads(components_raw)
                    except (json.JSONDecodeError, TypeError):
                        continue
                elif isinstance(components_raw, dict):
                    components = components_raw
                else:
                    continue

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

    @staticmethod
    def _compute_trend(scores: list[float]) -> str:
        """Określ trend trust score."""
        if len(scores) < 3:
            return "stable"
        recent = sum(scores[:3]) / 3
        older = sum(scores[-3:]) / 3 if len(scores) >= 6 else sum(scores) / len(scores)
        diff = recent - older
        if diff > 0.05:
            return "up"
        if diff < -0.05:
            return "down"
        return "stable"
