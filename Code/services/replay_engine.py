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

import json
import logging
from dataclasses import dataclass, field
from datetime import date, datetime, timezone
from typing import Any

import duckdb

from tax.audit import DecisionTraceLogger
from tax.exceptions import NoMatchingRuleError
from tax.rules import ContextInterpreter, RuleEngine, ensure_tax_schemas, seed_default_rules

logger = logging.getLogger("nexus.replay")


# ── Data structures ──────────────────────────────────────────────────────────


@dataclass
class ReplayResult:
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

        # 2. Wyodrębnij datę transakcji
        txn_date = original_context.get("transaction_date", "")
        try:
            txn_date_obj = date.fromisoformat(txn_date) if txn_date else date.today()
        except (ValueError, TypeError):
            txn_date_obj = date.today()

        # 3. Pobierz reguły aktywne na datę transakcji (historyczne)
        rules = self._conn.execute(
            """SELECT rule_id, condition_sql, action_json, priority
               FROM tax_rules
               WHERE valid_from <= ?
                 AND (valid_to IS NULL OR valid_to >= ?)
               ORDER BY priority ASC, valid_from DESC""",
            (txn_date_obj.isoformat(), txn_date_obj.isoformat()),
        ).fetchall()

        if not rules:
            return ReplayResult(
                transaction_id=transaction_id,
                match=False,
                original_verdict=original_verdict,
                error=f"No rules active on {txn_date_obj.isoformat()}",
            )

        # 4. Przygotuj kontekst i uruchom silnik reguł (read-only)
        try:
            engine = RuleEngine(self._conn)
            # Prepare context table without mutating the original
            engine._prepare_context_table(original_context)

            replayed_verdict = None
            replayed_rule_id = None
            for rule_id, condition_sql, action_json_raw, priority in rules:
                result = self._conn.execute(
                    f"SELECT COUNT(1) FROM _tax_ctx WHERE {condition_sql}"
                ).fetchone()
                if result and result[0] > 0:
                    replayed_verdict = json.loads(action_json_raw)
                    replayed_rule_id = rule_id
                    replayed_verdict["_rule_id"] = rule_id
                    replayed_verdict["_priority"] = priority
                    break

            if replayed_verdict is None:
                return ReplayResult(
                    transaction_id=transaction_id,
                    match=False,
                    original_verdict=original_verdict,
                    error=f"No matching rule for context on {txn_date}",
                )

        finally:
            # Clean up temp table
            self._conn.execute("DROP TABLE IF EXISTS _tax_ctx")

        # 5. Porównaj werdykty
        differences = _compare_verdicts(original_verdict, replayed_verdict)
        match = len(differences) == 0

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
        period_start: date,
        period_end: date,
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
        trace_logger = DecisionTraceLogger(self._conn)
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
            period_start.isoformat(), period_end.isoformat(),
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

    Returns:
        List of {"field": str, "original": Any, "replayed": Any} dicts.
    """
    differences: list[dict[str, Any]] = []

    for field in _COMPARISON_FIELDS:
        orig_val = original.get(field)
        replay_val = replayed.get(field)

        # Normalize None vs null
        if orig_val is None and replay_val is None:
            continue
        if orig_val is None or replay_val is None or str(orig_val) != str(replay_val):
            differences.append({
                "field": field,
                "original": orig_val,
                "replayed": replay_val,
            })

    return differences
