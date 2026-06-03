"""
Integration tests for RiskGuard — pełny przepływ CRUD na prawdziwym DuckDB.

Symuluje wywołania POST → GET → DELETE z ``Code/api/routes/risk.py``,
ale testuje bezpośrednio klasę RiskGuard z realną bazą ``:memory:``.

Przepływ:
  1. add_threshold    (POST   /admin/risk-thresholds)
  2. list_thresholds  (GET    /admin/risk-thresholds)   — reguła widoczna
  3. get_threshold    (GET    /admin/risk-thresholds/evaluate) — pasuje
  4. evaluate         (GET    /admin/risk-thresholds/evaluate-batch) — batch OK
  5. deprecate_threshold (DELETE /admin/risk-thresholds/{id}) — dezaktywacja
  6. list_thresholds  (GET    /admin/risk-thresholds)   — wciąż w liście
  7. get_threshold    (GET    /admin/risk-thresholds/evaluate) — już nie pasuje → fallback
"""

from __future__ import annotations

import json
from datetime import date, timedelta
from decimal import Decimal

import duckdb
import pytest

from services.risk_guard import (
    RiskGuard,
    ensure_schema,
    seed_default_thresholds,
    RiskThreshold,
    RiskVerdict,
)


# ==============================================================================
# Fixtures
# ==============================================================================


@pytest.fixture
def conn() -> duckdb.DuckDBPyConnection:
    """Czysta :memory: DuckDB z schematem risk_thresholds."""
    c = duckdb.connect(":memory:")
    ensure_schema(c)
    return c


@pytest.fixture
def guard(conn: duckdb.DuckDBPyConnection) -> RiskGuard:
    """RiskGuard na czystej bazie (bez seedowanych reguł)."""
    return RiskGuard(conn)


# ==============================================================================
# Helper — assertions
# ==============================================================================


def _assert_rule_matches(
    rule: dict,
    *,
    expected_condition: dict,
    expected_output: dict,
    expected_priority: int,
    expect_valid_to_none: bool = True,
) -> None:
    """Sprawdza, czy reguła z list_thresholds zawiera oczekiwane pola."""
    assert rule["condition"] == expected_condition, (
        f"Condition mismatch: {rule['condition']} != {expected_condition}"
    )
    assert rule["output"] == expected_output, (
        f"Output mismatch: {rule['output']} != {expected_output}"
    )
    assert rule["priority"] == expected_priority
    if expect_valid_to_none:
        assert rule["valid_to"] is None, (
            f"Expected valid_to=None for active rule, got {rule['valid_to']}"
        )
    else:
        assert rule["valid_to"] is not None, (
            "Expected valid_to to be set for deprecated rule"
        )
    assert isinstance(rule["rule_id"], str) and rule["rule_id"]
    assert isinstance(rule["valid_from"], str)
    assert isinstance(rule["created_at"], str)


# ==============================================================================
# CRUD — add → list → evaluate → deprecate → verify
# ==============================================================================


class TestCrudFlow:
    """Integration test: pełny cykl życia reguły progu ryzyka."""

    CONDITION = {"tax_form": "CIT_STANDARD", "field": "vat_rate"}
    OUTPUT = {"required_ml_confidence": 0.98, "action_if_below": "BLOCK_AND_ALERT"}
    PRIORITY = 15

    def test_full_crud_flow(self, guard: RiskGuard, conn: duckdb.DuckDBPyConnection) -> None:
        """Główny scenariusz: POST → GET → DELETE → GET."""

        # ── Step 1: POST — dodaj nową regułę ──────────────────────────────
        rule_id = guard.add_threshold(
            condition=self.CONDITION,
            output=self.OUTPUT,
            valid_from="2025-01-01",
            priority=self.PRIORITY,
            created_by="integration-test",
        )
        assert rule_id, "add_threshold powinno zwrócić niepusty rule_id"
        assert isinstance(rule_id, str)

        # ── Step 2: GET /list — reguła widoczna na liście ────────────────
        rules = guard.list_thresholds()
        assert len(rules) == 1, f"Oczekiwano 1 reguły, znaleziono {len(rules)}"

        rule = rules[0]
        assert rule["rule_id"] == rule_id
        _assert_rule_matches(
            rule,
            expected_condition=self.CONDITION,
            expected_output=self.OUTPUT,
            expected_priority=self.PRIORITY,
            expect_valid_to_none=True,
        )

        # ── Step 3: GET /evaluate — reguła pasuje do kontekstu ───────────
        threshold = guard.get_threshold(
            tax_form="CIT_STANDARD",
            field="vat_rate",
        )
        assert isinstance(threshold, RiskThreshold)
        assert threshold.required_ml_confidence == 0.98
        assert threshold.action_if_below == "BLOCK_AND_ALERT"

        # Inny kontekst (bez matcha) → fallback DEFAULT_THRESHOLD
        fallback = guard.get_threshold(
            tax_form="UNKNOWN_FORM",
            field="vat_rate",
        )
        assert fallback.required_ml_confidence == 0.85  # DEFAULT_THRESHOLD
        assert fallback.action_if_below == "BLOCK_AND_ALERT"

        # ── Step 4: GET /evaluate-batch — batch evaluation ───────────────
        verdict = guard.evaluate(
            fields_with_confidence={"vat_rate": 0.70, "total_net": 0.95},
            tax_form="CIT_STANDARD",
        )
        assert isinstance(verdict, RiskVerdict)
        assert not verdict.is_safe  # vat_rate=0.70 < 0.98
        assert verdict.action == "BLOCK_AND_ALERT"
        assert "vat_rate" in verdict.reason
        assert verdict.required_for_field["vat_rate"] == 0.98
        assert verdict.required_for_field["total_net"] == 0.85  # fallback dla total_net

        # ── Step 5: DELETE — dezaktywacja ────────────────────────────────
        deprecated = guard.deprecate_threshold(rule_id)
        assert deprecated is True, "deprecate_threshold powinno zwrócić True"

        # Ponowna próba dezaktywacji → False (już nieaktywna)
        deprecated_again = guard.deprecate_threshold(rule_id)
        assert deprecated_again is False, "Druga dezaktywacja powinna zwrócić False"

        # ── Step 6: GET /list — reguła wciąż na liście (append-only!) ───
        rules_after = guard.list_thresholds()
        assert len(rules_after) == 1, "Append-only: wciąż 1 reguła"

        rule_after = rules_after[0]
        assert rule_after["rule_id"] == rule_id
        _assert_rule_matches(
            rule_after,
            expected_condition=self.CONDITION,
            expected_output=self.OUTPUT,
            expected_priority=self.PRIORITY,
            expect_valid_to_none=False,
        )
        # valid_to powinno być ustawione na dzisiaj
        assert rule_after["valid_to"] == date.today().isoformat()

        # ── Step 7: GET /evaluate — reguła już nie pasuje (nieaktywna) ──
        threshold_after = guard.get_threshold(
            tax_form="CIT_STANDARD",
            field="vat_rate",
        )
        assert threshold_after.required_ml_confidence == 0.85  # fallback
        assert threshold_after.action_if_below == "BLOCK_AND_ALERT"

    def test_multiple_rules_and_priority_ordering(
        self, guard: RiskGuard
    ) -> None:
        """Dodanie wielu reguł — lista posortowana po priority ASC."""
        # Dodaj regułę z wysokim priorytetem (niższy priorytet = pierwsza w liście)
        guard.add_threshold(
            condition={"tax_form": "LINEAR"},
            output={"required_ml_confidence": 0.85, "action_if_below": "TRIAGE_QUEUE"},
            priority=50,
        )
        guard.add_threshold(
            condition={"tax_form": "CIT_STANDARD"},
            output={"required_ml_confidence": 0.98, "action_if_below": "BLOCK_AND_ALERT"},
            priority=10,
        )

        rules = guard.list_thresholds()
        assert len(rules) == 2

        # Priority ASC → pierwsza reguła ma niższy priorytet (wyższy first-match)
        assert rules[0]["priority"] == 10
        assert rules[1]["priority"] == 50

        # First-match-wins: CIT_STANDARD matchuje regułę z priority=10
        threshold = guard.get_threshold(tax_form="CIT_STANDARD")
        assert threshold.required_ml_confidence == 0.98

        # LINEAR matchuje regułę z priority=50 (bo CIT_STANDARD nie pasuje)
        threshold_linear = guard.get_threshold(tax_form="LINEAR")
        assert threshold_linear.required_ml_confidence == 0.85

    def test_deprecate_nonexistent_rule_returns_false(
        self, guard: RiskGuard
    ) -> None:
        """Próba dezaktywacji nieistniejącej reguły → False, nie błąd."""
        result = guard.deprecate_threshold("non-existent-id")
        assert result is False

    def test_empty_list_returns_empty(
        self, guard: RiskGuard
    ) -> None:
        """Brak reguł → pusta lista."""
        rules = guard.list_thresholds()
        assert rules == []

    def test_default_threshold_when_no_rules_match(
        self, guard: RiskGuard
    ) -> None:
        """Brak pasujących reguł → DEFAULT_THRESHOLD."""
        # Dodaj regułę tylko dla CIT_STANDARD
        guard.add_threshold(
            condition={"tax_form": "CIT_STANDARD"},
            output={"required_ml_confidence": 0.95, "action_if_below": "BLOCK_AND_ALERT"},
        )

        # Zapytanie dla nieznanej formy → fallback
        threshold = guard.get_threshold(tax_form="UNKNOWN")
        assert threshold == RiskGuard.DEFAULT_THRESHOLD

    def test_field_specific_matching(
        self, guard: RiskGuard
    ) -> None:
        """Reguła z konkretnym polem pasuje TYLKO gdy field się zgadza."""
        guard.add_threshold(
            condition={"tax_form": "CIT_STANDARD", "field": "vat_rate"},
            output={"required_ml_confidence": 0.99, "action_if_below": "BLOCK_AND_ALERT"},
        )

        # Zapytanie z polem vat_rate → match
        t1 = guard.get_threshold(tax_form="CIT_STANDARD", field="vat_rate")
        assert t1.required_ml_confidence == 0.99

        # Zapytanie z polem total_net → brak matcha (field się nie zgadza) → fallback
        t2 = guard.get_threshold(tax_form="CIT_STANDARD", field="total_net")
        assert t2 == RiskGuard.DEFAULT_THRESHOLD

    def test_expense_type_matching(
        self, guard: RiskGuard
    ) -> None:
        """Reguła z expense_type pasuje tylko gdy expense_type się zgadza."""
        guard.add_threshold(
            condition={"expense_type": "representation"},
            output={"required_ml_confidence": 0.95, "action_if_below": "BLOCK_AND_ALERT"},
        )

        t1 = guard.get_threshold(expense_type="representation")
        assert t1.required_ml_confidence == 0.95

        t2 = guard.get_threshold(expense_type="mixed_auto")
        assert t2 == RiskGuard.DEFAULT_THRESHOLD


# ==============================================================================
# Seed defaults
# ==============================================================================


class TestSeedDefaults:
    """Test wypełniania domyślnych progów ryzyka."""

    def test_seed_defaults_on_empty_db(
        self, conn: duckdb.DuckDBPyConnection
    ) -> None:
        """seed_default_thresholds wypełnia tabelę danymi domyślnymi."""
        seed_default_thresholds(conn)

        count = conn.execute(
            "SELECT COUNT(1) FROM risk_thresholds"
        ).fetchone()[0]
        assert count > 0

        # Sprawdź, że konkretne reguły istnieją
        rows = conn.execute(
            "SELECT condition_json, output_json FROM risk_thresholds WHERE condition_json LIKE '%CIT_STANDARD%'"
        ).fetchall()
        assert len(rows) >= 1  # Co najmniej jedna reguła dla CIT_STANDARD

    def test_seed_defaults_is_idempotent(
        self, conn: duckdb.DuckDBPyConnection
    ) -> None:
        """seed_default_thresholds jest idempotentne — drugie wołanie nie duplikuje."""
        seed_default_thresholds(conn)
        count1 = conn.execute(
            "SELECT COUNT(1) FROM risk_thresholds"
        ).fetchone()[0]

        seed_default_thresholds(conn)
        count2 = conn.execute(
            "SELECT COUNT(1) FROM risk_thresholds"
        ).fetchone()[0]

        assert count1 == count2, "Seed nie powinien duplikować danych"

    def test_seed_does_not_overwrite_manual_rules(
        self, conn: duckdb.DuckDBPyConnection
    ) -> None:
        """Jeśli tabela zawiera już reguły, seed nie dodaje nowych."""
        # Najpierw dodaj ręczną regułę
        guard = RiskGuard(conn)
        guard.add_threshold(
            condition={"tax_form": "MANUAL"},
            output={"required_ml_confidence": 0.50, "action_if_below": "AUTO_POST"},
        )

        # Potem seed — nie powinien dodać nic, bo tabela nie jest pusta
        conn.execute("DELETE FROM risk_thresholds WHERE condition_json LIKE '%CIT_STANDARD%'")
        seed_default_thresholds(conn)

        # W tym momencie tabela nie jest pusta (jest reguła MANUAL),
        # więc seed nie doda domyślnych reguł
        manual_count = conn.execute(
            "SELECT COUNT(1) FROM risk_thresholds WHERE condition_json LIKE '%MANUAL%'"
        ).fetchone()[0]
        assert manual_count >= 1

        # Ale może też dodać defaulty, jeśli usunęliśmy wszystko
        # (w tym MANUAL). W każdym razie — bez duplikatów.
        total = conn.execute(
            "SELECT COUNT(1) FROM risk_thresholds"
        ).fetchone()[0]
        # Powinna być 1 reguła (MANUAL) — seed nie dodał defaultów
        assert total == 1, f"Oczekiwano 1 reguły (MANUAL), znaleziono {total}"


# ==============================================================================
# Evaluate — batch edge cases
# ==============================================================================


class TestEvaluate:
    """Testy szczegółowe dla metody evaluate()."""

    def test_empty_fields_returns_safe(
        self, guard: RiskGuard
    ) -> None:
        """Pusta mapa pól → AUTO_POST, is_safe=True."""
        verdict = guard.evaluate({})
        assert verdict.is_safe
        assert verdict.action == "AUTO_POST"
        assert "Brak pól" in verdict.reason

    def test_all_fields_pass_returns_safe(
        self, guard: RiskGuard
    ) -> None:
        """Wszystkie pola powyżej progu → AUTO_POST."""
        guard.add_threshold(
            condition={"field": "vat_rate"},
            output={"required_ml_confidence": 0.80, "action_if_below": "TRIAGE_QUEUE"},
        )

        verdict = guard.evaluate(
            {"vat_rate": 0.95, "total_net": 0.99},
            tax_form="CIT_STANDARD",
        )
        assert verdict.is_safe
        assert verdict.action == "AUTO_POST"  # oba pola mają confidence >= próg

    def test_single_field_below_threshold_triggers_action(
        self, guard: RiskGuard
    ) -> None:
        """Jedno pole poniżej progu → akcja z reguły."""
        guard.add_threshold(
            condition={"field": "vat_rate", "tax_form": "CIT_STANDARD"},
            output={"required_ml_confidence": 0.90, "action_if_below": "BLOCK_AND_ALERT"},
        )

        verdict = guard.evaluate(
            {"vat_rate": 0.70, "total_net": 0.99},
            tax_form="CIT_STANDARD",
        )
        assert not verdict.is_safe
        assert verdict.action == "BLOCK_AND_ALERT"
        assert "vat_rate" in verdict.reason

    def test_most_restrictive_action_wins(
        self, guard: RiskGuard
    ) -> None:
        """Gdy dwa pola naruszają różne progi, wygrywa bardziej restrykcyjna akcja."""
        # vat_rate → TRIAGE_QUEUE (confidence 0.70 < 0.80)
        guard.add_threshold(
            condition={"field": "vat_rate"},
            output={"required_ml_confidence": 0.80, "action_if_below": "TRIAGE_QUEUE"},
        )
        # total_net → BLOCK_AND_ALERT (confidence 0.50 < 0.90)
        guard.add_threshold(
            condition={"field": "total_net"},
            output={"required_ml_confidence": 0.90, "action_if_below": "BLOCK_AND_ALERT"},
        )

        verdict = guard.evaluate(
            {"vat_rate": 0.70, "total_net": 0.50},
        )
        assert not verdict.is_safe
        assert verdict.action == "BLOCK_AND_ALERT"  # bardziej restrykcyjna

    def test_required_for_field_map_includes_all_fields(
        self, guard: RiskGuard
    ) -> None:
        """required_for_field zawiera próg dla każdego ocenianego pola."""
        guard.add_threshold(
            condition={"field": "vat_rate"},
            output={"required_ml_confidence": 0.95, "action_if_below": "BLOCK_AND_ALERT"},
        )

        verdict = guard.evaluate(
            {"vat_rate": 0.99, "total_net": 0.99, "vendor_nip": 0.99},
        )
        assert "vat_rate" in verdict.required_for_field
        assert "total_net" in verdict.required_for_field
        assert "vendor_nip" in verdict.required_for_field


# ==============================================================================
# Edge cases — daty i ważność
# ==============================================================================


class TestDateValidity:
    """Reguły z valid_from/valid_to są poprawnie filtrowane."""

    def test_future_rule_not_active(
        self, conn: duckdb.DuckDBPyConnection
    ) -> None:
        """Reguła z valid_from w przyszłości → nie aktywna → fallback."""
        future = (date.today() + timedelta(days=30)).isoformat()
        guard = RiskGuard(conn)
        guard.add_threshold(
            condition={"tax_form": "CIT_STANDARD"},
            output={"required_ml_confidence": 0.99, "action_if_below": "BLOCK_AND_ALERT"},
            valid_from=future,
        )

        threshold = guard.get_threshold(tax_form="CIT_STANDARD")
        assert threshold == RiskGuard.DEFAULT_THRESHOLD, (
            "Reguła z valid_from w przyszłości nie powinna być aktywna"
        )

    def test_expired_rule_not_active(
        self, conn: duckdb.DuckDBPyConnection
    ) -> None:
        """Reguła z valid_to w przeszłości → nie aktywna → fallback."""
        past = (date.today() - timedelta(days=1)).isoformat()
        guard = RiskGuard(conn)
        guard.add_threshold(
            condition={"tax_form": "CIT_STANDARD"},
            output={"required_ml_confidence": 0.99, "action_if_below": "BLOCK_AND_ALERT"},
            valid_from="2024-01-01",
            valid_to=past,
        )

        threshold = guard.get_threshold(tax_form="CIT_STANDARD")
        assert threshold == RiskGuard.DEFAULT_THRESHOLD

    def test_mixed_active_and_expired(
        self, conn: duckdb.DuckDBPyConnection
    ) -> None:
        """Aktywna reguła jest używana, nawet jeśli istnieją wygasłe."""
        guard = RiskGuard(conn)
        past = (date.today() - timedelta(days=1)).isoformat()

        # Wygasła reguła (niższy priorytet)
        guard.add_threshold(
            condition={"tax_form": "CIT_STANDARD"},
            output={"required_ml_confidence": 0.50, "action_if_below": "AUTO_POST"},
            valid_from="2024-01-01",
            valid_to=past,
            priority=5,
        )
        # Aktywna reguła (wyższy priorytet)
        guard.add_threshold(
            condition={"tax_form": "CIT_STANDARD"},
            output={"required_ml_confidence": 0.95, "action_if_below": "BLOCK_AND_ALERT"},
            valid_from="2024-01-01",
            priority=10,
        )

        threshold = guard.get_threshold(tax_form="CIT_STANDARD")
        # Powinna matchować aktywna reguła z priority=10 (a nie wygasła z priority=5)
        assert threshold.required_ml_confidence == 0.95
        assert threshold.action_if_below == "BLOCK_AND_ALERT"
