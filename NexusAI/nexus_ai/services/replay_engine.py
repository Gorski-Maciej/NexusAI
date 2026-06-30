"""
Replay Engine — mechanizm odtwarzania decyzji podatkowych.

Element 1 z dokumentu: pozwala ponownie uruchomić silnik reguł na tym
samym kontekście z przeszłości i porównać wynik z zapisanym werdyktem.

Wykorzystuje:
  - DecisionTraceLogger — do odczytu historycznego kontekstu i werdyktu
  - RuleEngine — do ponownej ewaluacji z regułami aktywnymi w dniu transakcji

Zastosowania:
  - Audyt i weryfikacja przed urzędem skarbowym
  - Testowanie regresji po zmianie reguł
  - Weryfikacja integralności historycznych decyzji
"""

from __future__ import annotations

from msgspec import Struct, field
from typing import Any, final

import pendulum

import duckdb
from structlog import get_logger

from nexus_ai.tax.audit import DecisionTraceLogger
from nexus_ai.tax.exceptions import NoMatchingRuleError
from nexus_ai.tax.rules import RuleEngine, ensure_tax_schemas

logger = get_logger("nexus.replay")

# ── Data structures ──────────────────────────────────────────────────────────


class ReplayResult(Struct):
    """Result of a single replay operation.

    Attributes:
        transaction_id: UUID of the replayed transaction.
        match: True if replayed verdict matches the original.
        original_verdict: The verdict stored in decision_traces.
        replayed_verdict: The verdict produced by re-running rules.
        differences: List of field-level differences (if mismatch).
        error: Error message if replay failed (e.g. missing trace).
    """

    transaction_id: str
    match: bool = False
    original_verdict: dict[str, Any] = field(default_factory=dict)
    replayed_verdict: dict[str, Any] = field(default_factory=dict)
    differences: list[dict[str, Any]] = field(default_factory=list)
    error: str = ""

    @property
    def is_match(self) -> bool:
        return self.match and not self.error


# ── Key fields for comparison ────────────────────────────────────────────────
# Fields that must match exactly for a replay to succeed.

_COMPARISON_FIELDS = [
    "vat_rate",
    "rounding_level",
    "income_tax_qualification",
    "gtu_code",
    "procedure",
    "action",
]

# ── Replay Engine ────────────────────────────────────────────────────────────


@final
class ReplayEngine:
    """Odtwarza decyzję podatkową dla historycznej faktury.

    Args:
        conn: DuckDB connection z tabelami tax_rules i decision_traces.
    """

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        ensure_tax_schemas(conn)

    def replay(self, transaction_id: str) -> ReplayResult:
        """Odtwórz decyzję dla pojedynczej faktury.

        Używa prawdziwego ``RuleEngine.decide()`` zamiast bezpośredniego SQL,
        co oznacza, że testuje rzeczywistą logikę silnika reguł (TemporalManager,
        PriorityEngine, ewaluacja warunków SQL).

        Args:
            transaction_id: UUID faktury do odtworzenia.

        Returns:
            ReplayResult z porównaniem oryginalnego i odtworzonego werdyktu.
        """
        # 1. Odczytaj zapisany kontekst i werdykt z decision_traces
        audit_logger = DecisionTraceLogger(self._conn)
        traces = audit_logger.get_trace(transaction_id)

        if not traces:
            return ReplayResult(
                transaction_id=transaction_id,
                match=False,
                error=f"No decision trace found for transaction {transaction_id}",
            )

        # Use the newest trace
        trace = traces[-1]
        original_context = trace.get("context") or {}
        original_verdict = trace.get("verdict") or {}

        if not original_context:
            return ReplayResult(
                transaction_id=transaction_id,
                match=False,
                error=f"Empty context in decision trace for {transaction_id}",
            )

        # 2. Użyj RuleEngine.decide() do odtworzenia decyzji
        #    To testuje rzeczywistą ścieżkę: TemporalManager → PriorityEngine → ewaluacja SQL
        engine = RuleEngine(self._conn)
        try:
            replayed_verdict = engine.decide(original_context)
        except NoMatchingRuleError as exc:
            return ReplayResult(
                transaction_id=transaction_id,
                match=False,
                original_verdict=original_verdict,
                error=str(exc),
            )
        finally:
            # Posprzątaj temp table (jeśli decide() nie została dokończona)
            self._conn.execute("DROP TABLE IF EXISTS _tax_ctx")

        # 3. Porównaj werdykty
        differences = _compare_verdicts(original_verdict, replayed_verdict)
        match = len(differences) == 0

        replayed_rule_id = replayed_verdict.get("_rule_id", "?")

        logger.info(
            "Replay %s: %s (replayed_rule=%s, diff=%d)",
            transaction_id,
            "MATCH" if match else "MISMATCH",
            replayed_rule_id,
            len(differences),
        )

        return ReplayResult(
            transaction_id=transaction_id,
            match=match,
            original_verdict=original_verdict,
            replayed_verdict=replayed_verdict,
            differences=differences,
        )

    def replay_batch(
        self,
        period_start: pendulum.Date,
        period_end: pendulum.Date,
        limit: int = 1000,
    ) -> list[ReplayResult]:
        """Odtwórz decyzje dla wszystkich faktur z danego okresu.

        Args:
            period_start: Początek okresu.
            period_end: Koniec okresu.
            limit: Maksymalna liczba faktur do odtworzenia.

        Returns:
            Lista ReplayResult dla każdej faktury.
        """
        # Find all transactions in the period
        DecisionTraceLogger(self._conn)
        try:
            rows = self._conn.execute(
                """SELECT DISTINCT transaction_id
                   FROM decision_traces
                   WHERE timestamp >= ? AND timestamp <= ?
                   ORDER BY timestamp ASC
                   LIMIT ?""",
                (period_start.isoformat(), period_end.isoformat(), limit),
            ).fetchall()
        except Exception:
            return []

        results: list[ReplayResult] = []
        for (tx_id,) in rows:
            result = self.replay(tx_id)
            results.append(result)

        logger.info(
            "Batch replay %s–%s: %d/%d matched",
            period_start.isoformat(),
            period_end.isoformat(),
            sum(1 for r in results if r.match),
            len(results),
        )
        return results


# ── Verdict comparison ───────────────────────────────────────────────────────


def _compare_verdicts(
    original: dict[str, Any],
    replayed: dict[str, Any],
) -> list[dict[str, Any]]:
    """Compare two verdicts and return field-level differences.

    Only checks fields in _COMPARISON_FIELDS. Metadata fields
    (like _rule_id, _priority) are excluded from comparison
    because rule IDs may differ between versions.

    - ``pl.DataFrame`` zamiast ręcznej pętli ``for comp_field in ...``
    - ``pl.when().then().otherwise()" dla logiki warunkowej
    - ``pl.col().is_not_null()" zamiast ``is None`` check
    - ``pl.col().ne(")".alias()" dla porównania stringów

    Returns:
        List of {"field": str, "original": Any, "replayed": Any} dicts.
    """
    import polars as pl

    # Budujemy DataFrame z polami do porównania i używamy
    # wyrażeń Polars do znajdowania różnic.
    diff_data = []
    for comp_field in _COMPARISON_FIELDS:
        orig_val = original.get(comp_field)
        replay_val = replayed.get(comp_field)
        diff_data.append(
            {
                "field": comp_field,
                "original": str(orig_val) if orig_val is not None else None,
                "replayed": str(replay_val) if replay_val is not None else None,
            }
        )

    df = pl.DataFrame(diff_data)
    mismatches = df.filter(
        ~(pl.col("original").is_null() & pl.col("replayed").is_null())
        & (
            pl.col("original").is_null()
            | pl.col("replayed").is_null()
            | (pl.col("original") != pl.col("replayed"))
        )
    )

    return mismatches.to_dicts()
