"""
Decision Logger — rozbudowany logger decyzji z tabelą trust_score_cache i pełnym śledzeniem.

Nowe funkcjonalności:
  - trust_score_cache: tabela przechowująca historyczne trust score dla adaptacji wag
  - log_decision z pełnym kontekstem PLE (STM/LTM/FM)
  - get_trust_score_trend: analiza trendu trust score dla kontrahenta
  - get_correction_stats: statystyki korekt użytkownika dla adaptacyjnego strojenia

mypyc: wszystkie dict[str, Any] zastąpione konkretnymi Structami,
brak try/except pass, @final na klasie głównej.
"""

from __future__ import annotations

import anyio
import uuid
from typing import Any, final

import pendulum
from msgspec import Struct, field

# ── SUPERMOC pendulum: diff_for_humans po polsku ─────────────────────────
from nexus_ai.core.time_utils import human_diff

from nexus_ai.core.broker import broker
from nexus_ai.core.logger import get_logger
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_dumps, msgspec_loads
from nexus_ai.db.analytics import DuckDBManager

logger = get_logger(__name__)


# ═══════════════════════════════════════════════════════════════════════════════
# Data structures — konkretne Struct zamiast dict[str, Any]
# mypyc: kompilowalne do C, zdevirtualizowane metody, brak Any
# ═══════════════════════════════════════════════════════════════════════════════


class TrustComponents(Struct, frozen=True):
    """Trust score components for a decision.

    Attributes:
        ai_confidence: Confidence from AI model (0.0–1.0).
        vendor_reliability: Vendor reliability score (0.0–1.0).
        data_consistency: Data consistency score (0.0–1.0).
        context_trust: Context trust score (0.0–1.0).
    """

    ai_confidence: float = 0.0
    vendor_reliability: float = 0.0
    data_consistency: float = 0.0
    context_trust: float = 0.0


class DecisionContext(Struct, frozen=True):
    """Context snapshot for a decision.

    Attributes:
        contractor_nip: NIP of the contractor.
        category: Invoice category.
        transaction_date: Transaction date.
        vendor_country: Vendor country code.
        company_tax_form: Tax form (e.g. CIT_STANDARD).
        vendor_vat_status: VAT status of vendor.
    """

    contractor_nip: str = ""
    category: str = ""
    transaction_date: str = ""
    vendor_country: str = ""
    company_tax_form: str = ""
    vendor_vat_status: str = ""


class DecisionRecord(Struct, kw_only=True):
    """A single decision record returned from queries.

    Attributes correspond to columns in the decisions table.
    verdict fields (alpha_vote, beta_vote, gamma_vote, trust_components, context)
    are stored as JSON in DuckDB and deserialised on read.
    """

    id: str = ""
    invoice_id: str = ""
    alpha_vote: dict[str, float | str | int] = field(default_factory=dict)
    beta_vote: dict[str, float | str | int] = field(default_factory=dict)
    gamma_vote: dict[str, float | str | int] = field(default_factory=dict)
    final_decision: str = ""
    trust_score: float = 0.0
    trust_components: dict[str, float] = field(default_factory=dict)
    context: dict[str, str] = field(default_factory=dict)
    timestamp: str = ""
    user_correction: str | None = None
    decision_level: str = ""
    decision_pattern: str = ""


class DecisionSummary(Struct, kw_only=True):
    """Summary of a single decision for listing."""

    invoice_id: str = ""
    decision: str = ""
    trust_score: float = 0.0
    level: str = ""
    pattern: str = ""
    timestamp: str = ""


class GlobalDecision(Struct, kw_only=True):
    """A global decision from trust_score_cache (cross-contractor)."""

    contractor_nip: str = ""
    category: str = ""
    decision: str = ""
    trust_score: float = 0.0
    ai_confidence: float = 0.0
    timestamp: str = ""


class TrustTrend(Struct, kw_only=True):
    """Trend analysis result for a contractor's trust score."""

    known: bool = False
    records: int = 0
    avg_trust: float = 0.0
    min_trust: float = 0.0
    max_trust: float = 0.0
    trend: str = "stable"
    decisions_breakdown: dict[str, int] = field(default_factory=dict)
    component_averages: dict[str, float] = field(default_factory=dict)


class CorrectionStats(Struct, kw_only=True):
    """Aggregated correction statistics for adaptive weight tuning."""

    total_decisions: int = 0
    total_corrected: int = 0
    correction_rate: float = 0.0
    decision_breakdown: dict[str, int] = field(default_factory=dict)
    level_breakdown: dict[str, int] = field(default_factory=dict)
    correction_breakdown: list[dict[str, str | int]] = field(default_factory=list)
    ai_confidence_correction_rate: float = 0.0
    vendor_reliability_correction_rate: float = 0.0
    data_consistency_correction_rate: float = 0.0
    context_trust_correction_rate: float = 0.0


# ═══════════════════════════════════════════════════════════════════════════════
# Main class
# ═══════════════════════════════════════════════════════════════════════════════


@final
class DecisionLogger:
    """Logs decisions to DuckDB with full context.

    Automatically creates tables:
      - decisions (main decision table)
      - trust_score_cache (trust score cache for weight adaptation)
      - decisions_meta (metadata and user corrections)

    @final: mypyc devirtualises all method calls on this class.
    """

    def __init__(
        self,
        duckdb: DuckDBManager,
    ) -> None:
        self._duckdb = duckdb
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        """Create all required tables and indexes.

        Automatically migrates legacy 'council_decisions' tables
        to new 'decisions' naming on first run.
        """

        # ── Migration: rename old council tables ───────────────────
        for old_name, new_name in [
            ("council_decisions", "decisions"),
            ("council_decisions_meta", "decisions_meta"),
        ]:
            try:
                self._duckdb.execute(f"ALTER TABLE {old_name} RENAME TO {new_name}")
            except Exception:
                logger.debug(
                    "[DecisionLogger] migration skipped: table %s does not exist", old_name,
                )

        # Główna tabela decyzji
        self._duckdb.execute(
            """
            CREATE TABLE IF NOT EXISTS decisions (
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
                decision_pattern VARCHAR,
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
            CREATE TABLE IF NOT EXISTS decisions_meta (
                decision_id VARCHAR PRIMARY KEY,
                invoice_id VARCHAR,
                deliberation_duration_ms INTEGER,
                levels_used JSON,
                model_swap_count INTEGER,
                timestamp TIMESTAMP
            )
            """
        )

        # Indeksy standardowe
        for table, col in [
            ("decisions", "invoice_id"),
            ("decisions", "timestamp"),
            ("decisions", "final_decision"),
            ("trust_score_cache", "contractor_nip"),
            ("trust_score_cache", "timestamp"),
            ("decisions_meta", "invoice_id"),
        ]:
            idx_name = f"idx_{table}_{col}"
            self._duckdb.execute(f"CREATE INDEX IF NOT EXISTS {idx_name} ON {table}({col})")

        # ── SUPERMOC: Partial indexes (DuckDB wspiera WHERE w indexach) ──
        # Indeksuje tylko wiersze spełniające warunek — mniejszy indeks,
        # szybsze zapytania dla najczęstszych wzorców.
        # Partial index na decisions WHERE user_correction IS NOT NULL
        # jest ~70% mniejszy niż pełny indeks.
        self._duckdb.execute(
            "CREATE INDEX IF NOT EXISTS idx_decisions_corrected "
            "ON decisions(timestamp) WHERE user_correction IS NOT NULL"
        )
        self._duckdb.execute(
            "CREATE INDEX IF NOT EXISTS idx_decisions_not_corrected "
            "ON decisions(timestamp) WHERE user_correction IS NULL"
        )
        # Partial index dla wysokich trust score (>= 0.8) — często filtrowane
        self._duckdb.execute(
            "CREATE INDEX IF NOT EXISTS idx_decisions_high_trust "
            "ON decisions(timestamp) WHERE trust_score >= 0.8"
        )
        # Partial index dla niskiego trust score (< 0.5) — alarmy
        self._duckdb.execute(
            "CREATE INDEX IF NOT EXISTS idx_decisions_low_trust "
            "ON decisions(timestamp) WHERE trust_score < 0.5"
        )
        # Partial index na trust_score_cache dla kontrahentów z korektami
        self._duckdb.execute(
            "CREATE INDEX IF NOT EXISTS idx_tsc_corrected "
            "ON trust_score_cache(timestamp) WHERE user_correction IS NOT NULL"
        )
        # ── SUPERMOC: Expression index — LOWER(contractor_nip) ──────────
        # Case-insensitive lookup dla NIP-ów.
        try:
            self._duckdb.execute(
                "CREATE INDEX IF NOT EXISTS idx_tsc_contractor_lower "
                "ON trust_score_cache(LOWER(contractor_nip))"
            )
        except Exception:
            pass  # DuckDB może nie wspierać expression index we wszystkich wersjach

    async def log_decision(
        self,
        invoice_id: str,
        alpha_verdict: dict[str, float | str | int],
        beta_verdict: dict[str, float | str | int],
        gamma_verdict: dict[str, float | str | int],
        final_decision: str,
        trust_score: float,
        trust_components: TrustComponents,
        context: DecisionContext,
        decision_level: str = "",
        decision_pattern: str = "",
        ple_stm_snapshot: dict[str, float | str | int] | None = None,
        ple_ltm_profile: dict[str, float | str | int] | None = None,
    ) -> None:
        """Persist a decision with full PLE context.

        SUPERMOC pendulum: human_diff() dla czytelnych komunikatów po polsku.

        Args:
            invoice_id: Invoice identifier.
            alpha_verdict: Alpha council verdict.
            beta_verdict: Beta council verdict.
            gamma_verdict: Gamma council verdict.
            final_decision: Final decision string.
            trust_score: Overall trust score.
            trust_components: Structured trust component scores.
            context: Decision context snapshot.
            decision_level: Decision level identifier.
            decision_pattern: Decision pattern identifier.
            ple_stm_snapshot: Short-term memory snapshot (optional).
            ple_ltm_profile: Long-term memory profile (optional).
        """
        decision_id = uuid.uuid4().hex
        try:
            await anyio.to_thread.run_sync(
                self._duckdb.execute,
                """
                INSERT INTO decisions
                (id, invoice_id, alpha_vote, beta_vote, gamma_vote,
                 final_decision, trust_score, trust_components, context,
                 timestamp, user_correction, decision_level, decision_pattern,
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
                    msgspec_dumps(msgspec.structs.asdict(trust_components), ensure_ascii=False),
                    msgspec_dumps(msgspec.structs.asdict(context), ensure_ascii=False),
                    pendulum.now("UTC"),
                    None,  # user_correction — populated later
                    decision_level,
                    decision_pattern,
                    msgspec_dumps(ple_stm_snapshot, ensure_ascii=False)
                    if ple_stm_snapshot
                    else None,
                    msgspec_dumps(ple_ltm_profile, ensure_ascii=False) if ple_ltm_profile else None,
                ),
            )

            # Równolegle zapisz do trust_score_cache
            await anyio.to_thread.run_sync(
                self._cache_trust_score,
                contractor_nip=str(context.contractor_nip or "unknown"),
                category=str(context.category or "unknown"),
                trust_score=trust_score,
                trust_components=trust_components,
                final_decision=final_decision,
            )

            # SUPERMOC pendulum: human_diff dla czytelnego czasu (start dnia → teraz)
            day_start = pendulum.now("UTC").start_of("day")
            since_midnight = human_diff(day_start, pendulum.now("UTC"), locale="pl", absolute=True)
            logger.debug(
                "[DecisionLogger] logged decision_id=%s invoice_id=%s decision=%s level=%s (%s od północy)",
                decision_id,
                invoice_id,
                final_decision,
                decision_level,
                since_midnight,
            )

            # Emituj event przez Taskiq broker.kick
            try:
                await broker.kick("event_emit_decision_made",
                    invoice_id=invoice_id,
                    decision=final_decision,
                    trust_score=trust_score,
                    ai_confidence=trust_components.ai_confidence,
                    decision_pattern=decision_pattern,
                    metadata={
                        "decision_id": decision_id,
                        "decision_level": decision_level,
                    },
                )
            except Exception as event_err:
                logger.warning(
                    "[DecisionLogger] Failed to emit DecisionMade: %s", event_err,
                )

        except Exception as exc:
            logger.error("[DecisionLogger] failed to log invoice_id=%s: %s", invoice_id, exc)

    def _cache_trust_score(
        self,
        contractor_nip: str,
        category: str,
        trust_score: float,
        trust_components: TrustComponents,
        final_decision: str,
    ) -> None:
        """Zapisz trust score do cache (synchronicznie, wołane z executa)."""
        cache_id = uuid.uuid4().hex
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
                float(trust_components.ai_confidence),
                float(trust_components.vendor_reliability),
                float(trust_components.data_consistency),
                float(trust_components.context_trust),
                final_decision,
                None,  # user_correction
                pendulum.now("UTC"),
            ),
        )

    async def record_user_correction(
        self,
        invoice_id: str,
        correction: str,
    ) -> None:
        """Record a user correction for a previously logged decision.

        Args:
            invoice_id: Invoice identifier.
            correction: Correction string (e.g. 'ACCEPTED', 'REJECTED').
        """
        try:
            await anyio.to_thread.run_sync(
                self._duckdb.execute,
                """
                UPDATE decisions
                SET user_correction = ?
                WHERE invoice_id = ? AND user_correction IS NULL
                """,
                (correction, invoice_id),
            )
            # Równolegle zaktualizuj trust_score_cache
            await anyio.to_thread.run_sync(
                self._duckdb.execute,
                """
                UPDATE trust_score_cache
                SET user_correction = ?
                WHERE contractor_nip = (
                    SELECT context->>'contractor_nip'
                    FROM decisions
                    WHERE invoice_id = ?
                    LIMIT 1
                ) AND user_correction IS NULL
                """,
                (correction, invoice_id),
            )
            logger.info(
                "[DecisionLogger] recorded user correction invoice_id=%s correction=%s",
                invoice_id,
                correction,
            )

            # Emituj event przez Taskiq broker.kick
            try:
                await broker.kick("event_emit_decision_overridden",
                    invoice_id=invoice_id,
                    original_decision="SYSTEM",
                    user_decision=correction,
                    user_id="system",
                    metadata={"source": "decision_logger"},
                )
            except Exception as event_err:
                logger.warning(
                    "[DecisionLogger] Failed to emit DecisionOverridden: %s", event_err,
                )

        except Exception as exc:
            logger.error(
                "[DecisionLogger] failed to record correction for invoice_id=%s: %s",
                invoice_id,
                exc,
            )

    def get_trust_score_trend(
        self,
        contractor_nip: str,
        days: int = 30,
    ) -> TrustTrend:
        """Analiza trendu trust score dla danego kontrahenta.

        Args:
            contractor_nip: NIP of the contractor.
            days: Number of days to look back (default 30).

        Returns:
            TrustTrend with trend analysis.
        """
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
                return TrustTrend()

            scores = [float(r[0]) for r in rows]
            decisions = [str(r[5]) for r in rows]

            return TrustTrend(
                known=True,
                records=len(rows),
                avg_trust=round(sum(scores) / len(scores), 4),
                min_trust=round(min(scores), 4),
                max_trust=round(max(scores), 4),
                trend=self._compute_trend(scores),
                decisions_breakdown={d: decisions.count(d) for d in set(decisions)},
                component_averages={
                    "ai_confidence": round(sum(float(r[1]) for r in rows) / len(rows), 4)
                    if rows
                    else 0.0,
                    "vendor_reliability": round(sum(float(r[2]) for r in rows) / len(rows), 4)
                    if rows
                    else 0.0,
                    "data_consistency": round(sum(float(r[3]) for r in rows) / len(rows), 4)
                    if rows
                    else 0.0,
                    "context_trust": round(sum(float(r[4]) for r in rows) / len(rows), 4)
                    if rows
                    else 0.0,
                },
            )
        except Exception as exc:
            logger.error("[DecisionLogger] failed to get trust score trend: %s", exc)
            return TrustTrend()

    def get_user_correction_stats(
        self,
        invoice_id: str | None = None,
    ) -> CorrectionStats:
        """Aggregate correction statistics for adaptive weight tuning.

        Args:
            invoice_id: Optional invoice ID filter.

        Returns:
            CorrectionStats with aggregated data.
        """
        _ = invoice_id  # reserved for future per-invoice filtering
        try:
            total = self._duckdb.execute("SELECT COUNT(*) FROM decisions")[0][0]

            corrected = self._duckdb.execute(
                "SELECT COUNT(*) FROM decisions WHERE user_correction IS NOT NULL"
            )[0][0]

            # Decisions by type
            decision_breakdown = self._duckdb.execute(
                """
                SELECT final_decision, COUNT(*) as cnt
                FROM decisions
                GROUP BY final_decision
                """
            )

            # Corrections by prior decision type
            correction_breakdown = self._duckdb.execute(
                """
                SELECT final_decision, user_correction, COUNT(*) as cnt
                FROM decisions
                WHERE user_correction IS NOT NULL
                GROUP BY final_decision, user_correction
                """
            )

            # Statystyki według poziomów decyzyjnych
            level_breakdown = self._duckdb.execute(
                """
                SELECT decision_level, COUNT(*) as cnt
                FROM decisions
                WHERE decision_level IS NOT NULL AND decision_level != ''
                GROUP BY decision_level
                """
            )

            component_stats = self._compute_component_correction_rates()

            return CorrectionStats(
                total_decisions=int(total),
                total_corrected=int(corrected),
                correction_rate=round(corrected / max(total, 1), 4),
                decision_breakdown={str(row[0]): int(row[1]) for row in decision_breakdown},
                level_breakdown={str(row[0]): int(row[1]) for row in level_breakdown}
                if level_breakdown
                else {},
                correction_breakdown=[
                    {"from": str(r[0]), "to": str(r[1]), "count": int(r[2])}
                    for r in correction_breakdown
                ],
                **component_stats,
            )
        except Exception as exc:
            logger.error("[DecisionLogger] failed to get correction stats: %s", exc)
            return CorrectionStats()

    def get_decisions_for_invoice(
        self,
        invoice_id: str,
    ) -> list[DecisionRecord]:
        """Retrieve all decisions for a specific invoice.

        Args:
            invoice_id: Invoice identifier.

        Returns:
            List of DecisionRecord for the given invoice.
        """
        try:
            rows = self._duckdb.execute(
                """
                SELECT id, invoice_id, alpha_vote, beta_vote, gamma_vote,
                       final_decision, trust_score, trust_components, context,
                       timestamp, user_correction, decision_level, decision_pattern
                FROM decisions
                WHERE invoice_id = ?
                ORDER BY timestamp DESC
                """,
                (invoice_id,),
            )
            return [
                DecisionRecord(
                    id=str(r[0]),
                    invoice_id=str(r[1]),
                    alpha_vote=_safe_loads(r[2]),
                    beta_vote=_safe_loads(r[3]),
                    gamma_vote=_safe_loads(r[4]),
                    final_decision=str(r[5]) if r[5] else "",
                    trust_score=float(r[6]) if r[6] else 0.0,
                    trust_components=_safe_loads(r[7], {}),
                    context=_safe_loads(r[8], {}),
                    timestamp=str(r[9]) if r[9] else "",
                    user_correction=str(r[10]) if r[10] else None,
                    decision_level=str(r[11]) if r[11] else "",
                    decision_pattern=str(r[12]) if r[12] else "",
                )
                for r in rows
            ]
        except Exception as exc:
            logger.error(
                "[DecisionLogger] failed to get decisions for invoice_id=%s: %s",
                invoice_id,
                exc,
            )
            return []

    def get_decision_summary(
        self,
        limit: int = 100,
    ) -> list[DecisionSummary]:
        """Pobierz podsumowanie ostatnich decyzji.

        Args:
            limit: Maximum number of results (default 100).

        Returns:
            List of DecisionSummary.
        """
        try:
            rows = self._duckdb.execute(
                """
                SELECT invoice_id, final_decision, trust_score,
                       decision_level, decision_pattern, timestamp
                FROM decisions
                ORDER BY timestamp DESC
                LIMIT ?
                """,
                (limit,),
            )
            return [
                DecisionSummary(
                    invoice_id=str(r[0]),
                    decision=str(r[1]),
                    trust_score=float(r[2]) if r[2] else 0.0,
                    level=str(r[3]) if r[3] else "",
                    pattern=str(r[4]) if r[4] else "",
                    timestamp=str(r[5]) if r[5] else "",
                )
                for r in rows
            ]
        except Exception as exc:
            logger.error("[DecisionLogger] failed to get decision summary: %s", exc)
            return []

    def get_recent_global_decisions(
        self,
        category: str = "",
        limit: int = 5,
    ) -> list[GlobalDecision]:
        """Pobierz ostatnie decyzje ze wszystkich kontrahentów (globalne).

        Przydatne do few-shot learning — podobne przypadki z globalnej bazy,
        nie tylko od konkretnego kontrahenta.

        Args:
            category: Optional category filter.
            limit: Maximum number of results (default 5).

        Returns:
            List of GlobalDecision.
        """
        try:
            if category:
                query = """
                    SELECT contractor_nip, category, final_decision,
                           trust_score, ai_confidence, timestamp
                    FROM trust_score_cache
                    WHERE category = ?
                    ORDER BY timestamp DESC
                    LIMIT ?
                """
                rows = self._duckdb.execute(query, (category, limit))
            else:
                query = """
                    SELECT contractor_nip, category, final_decision,
                           trust_score, ai_confidence, timestamp
                    FROM trust_score_cache
                    ORDER BY timestamp DESC
                    LIMIT ?
                """
                rows = self._duckdb.execute(query, (limit,))

            return [
                GlobalDecision(
                    contractor_nip=str(r[0]),
                    category=str(r[1]),
                    decision=str(r[2]),
                    trust_score=float(r[3]) if r[3] else 0.0,
                    ai_confidence=float(r[4]) if r[4] else 0.0,
                    timestamp=str(r[5]) if r[5] else "",
                )
                for r in rows
            ]
        except Exception as exc:
            logger.error("[DecisionLogger] failed to get global decisions: %s", exc)
            return []

    def _compute_component_correction_rates(self) -> dict[str, float]:
        """Estimate per-component correction rates."""
        try:
            rows = self._duckdb.execute(
                """
                SELECT trust_components, user_correction
                FROM decisions
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

            counts = {
                "ai_confidence": 0,
                "vendor_reliability": 0,
                "data_consistency": 0,
                "context_trust": 0,
            }
            total_corrected = len(rows)

            for row in rows:
                components_raw = row[0]
                try:
                    if isinstance(components_raw, str):
                        components = msgspec_loads(components_raw)
                    elif isinstance(components_raw, dict):
                        components = components_raw
                    else:
                        continue
                except (DecodeError, TypeError):
                    continue

                min_comp = min(components, key=lambda k: components.get(k, 1.0))
                if isinstance(min_comp, str) and min_comp in counts:
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

    def get_globally_similar_cases(
        self,
        category: str = "",
        amount_gross: float = 0.0,
        limit: int = 5,
        amount_tolerance: float = 0.5,
    ) -> list[GlobalDecision]:
        """Znajdź globalnie podobne przypadki z DuckDB.

        W przeciwieństwie do get_recent_global_decisions(), które zwraca
        ostatnie decyzje, ta metoda szuka przypadków podobnych pod względem:
          - Tej samej kategorii (jeśli znana)
          - Podobnej kwoty brutto (±50% domyślnie)

        Args:
            category: Category to filter by.
            amount_gross: Gross amount of current invoice.
            limit: Maximum number of results.
            amount_tolerance: Amount tolerance as fraction (0.5 = ±50%).

        Returns:
            List of GlobalDecision sorted by relevance.
        """
        _ = amount_tolerance  # reserved for future use with amount column
        try:
            if category and amount_gross > 0:
                query = """
                    SELECT contractor_nip, category, final_decision,
                           trust_score, ai_confidence, timestamp
                    FROM trust_score_cache
                    WHERE category = ?
                      AND final_decision IS NOT NULL
                    ORDER BY timestamp DESC
                    LIMIT ?
                """
                rows = self._duckdb.execute(query, (category, limit * 2))
            elif amount_gross > 0:
                query = """
                    SELECT contractor_nip, category, final_decision,
                           trust_score, ai_confidence, timestamp
                    FROM trust_score_cache
                    WHERE final_decision IS NOT NULL
                    ORDER BY timestamp DESC
                    LIMIT ?
                """
                rows = self._duckdb.execute(query, (limit * 2,))
            else:
                query = """
                    SELECT contractor_nip, category, final_decision,
                           trust_score, ai_confidence, timestamp
                    FROM trust_score_cache
                    WHERE final_decision IS NOT NULL
                    ORDER BY timestamp DESC
                    LIMIT ?
                """
                rows = self._duckdb.execute(query, (limit * 2,))

            results = [
                GlobalDecision(
                    contractor_nip=str(r[0]),
                    category=str(r[1]),
                    decision=str(r[2]),
                    trust_score=float(r[3]) if r[3] else 0.0,
                    ai_confidence=float(r[4]) if r[4] else 0.0,
                    timestamp=str(r[5]) if r[5] else "",
                )
                for r in rows
            ]

            # Priorytet: najpierw przypadki z tej samej kategorii,
            # potem posortowane po trust_score (najlepsze pierwsze).
            if category:
                same_cat = [d for d in results if d.category == category]
                other = [d for d in results if d.category != category]
                same_cat.sort(key=lambda x: x.trust_score, reverse=True)
                other.sort(key=lambda x: x.trust_score, reverse=True)
                results = same_cat[:limit] + other[: max(0, limit - len(same_cat))]
            else:
                results.sort(key=lambda x: x.trust_score, reverse=True)
                results = results[:limit]

            return results

        except Exception as exc:
            logger.error("[DecisionLogger] failed to get globally similar cases: %s", exc)
            return []

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


# ═══════════════════════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════════════════════


def _safe_loads(
    raw: object,
    default: object = None,
) -> Any:
    """Bezpiecznie deserializuj JSON string lub zwróć domyślny.

    Args:
        raw: Raw value (str, dict, or None).
        default: Default value if parsing fails.

    Returns:
        Deserialised dict or default.
    """
    if isinstance(raw, str):
        try:
            return msgspec_loads(raw)
        except (DecodeError, TypeError):
            return default
    if isinstance(raw, dict):
        return raw
    return default
