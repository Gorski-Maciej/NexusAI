"""
Unit tests: DecisionEngine z NexusCache — mockowanie cache invalidation chain.

Testuje wszystkie interakcje DecisionEngine z NexusCache:
  - _get_active_rules(): cache hit → bypass DuckDB
  - _get_active_rules(): cache miss → load z DuckDB → set_sync
  - invalidate_rules_cache(): usunięcie klucza
  - add_rule(): INSERT + invalidate_rules_cache()
  - deprecate_rule(): UPDATE + invalidate_rules_cache()
  - _seed_defaults(): INSERT + invalidate_rules_cache()
  - decide(): używa _get_active_rules() (z cache lub DuckDB)

Strategia mockowania:
  - decision_engine._rules_cache → MagicMock (rejestruje wywołania)
  - duckdb_execute → MockFakeDuckDBManager (symuluje DuckDB)
  - date/times → pendulum-free przez fixed datetime
"""

from __future__ import annotations

from typing import Any
from unittest.mock import MagicMock, patch

import pytest

from nexus_ai.core.decision_engine import (
    CACHE_KEY,
    DEFAULT_DECISION_RULES,
    DecisionEngine,
    DecisionVerdict,
    invalidate_rules_cache,
)


# =========================================================================
# Fixtures — mocki i helpery
# =========================================================================


@pytest.fixture
def mock_rules_cache() -> MagicMock:
    """Mock NexusCache dla _rules_cache w decision_engine.

    Rejestruje wywołania get_sync, set_sync, delete_sync.
    Domyślnie: get_sync → None (cache miss), set_sync/delete_sync → no-op.
    """
    cache = MagicMock()
    cache.get_sync.return_value = None  # domyślnie cache miss
    return cache


@pytest.fixture
def mock_duckdb_empty() -> MagicMock:
    """Mock DuckDBManager zwracający pustą tabelę decision_rules (COUNT=0).

    Używany do testowania _seed_defaults().
    """
    db = MagicMock()
    # COUNT(1) → 0 (pusta tabela)
    def mock_execute(sql: str, params: tuple | None = None) -> list[tuple[Any, ...]]:
        if "COUNT(1)" in sql and "decision_rules" in sql:
            return [(0,)]
        return []
    db.execute.side_effect = mock_execute
    return db


@pytest.fixture
def mock_duckdb_with_rules() -> MagicMock:
    """Mock DuckDBManager z aktywnymi regułami.

    Zwraca 7 reguł (odpowiednik DEFAULT_DECISION_RULES).
    """
    db = MagicMock()

    def mock_execute(sql: str, params: tuple | None = None) -> list[tuple[Any, ...]]:
        if "COUNT(1)" in sql and "decision_rules" in sql:
            return [(7,)]  # już są reguły — nie seeduj
        if "SELECT condition_json, output_json, rule_id, priority" in sql:
            # Zwróć 7 aktywnych reguł
            return [
                ('{"vendor_known": true, "vendor_invoice_count__gte": 10, "vendor_trust__gte": 0.85, "amount_gross__lte": 5000, "ocr_confidence__gte": 0.92}',
                 '{"decision": "AUTO_POST", "confidence": 0.95, "reasoning": "Zaufany kontrahent, niska kwota, wysoki OCR"}',
                 "rule-001", 10),
                ('{"vendor_known": true, "vendor_invoice_count__gte": 3, "vendor_trust__gte": 0.80, "amount_gross__lte": 3000, "ocr_confidence__gte": 0.90}',
                 '{"decision": "AUTO_POST", "confidence": 0.90, "reasoning": "Znany kontrahent, niska kwota"}',
                 "rule-002", 20),
                ('{"vendor_known": true, "amount_gross__lte": 10000, "ocr_confidence__gte": 0.85}',
                 '{"decision": "SUGGEST", "confidence": 0.80, "reasoning": "Znany kontrahent, średnia kwota"}',
                 "rule-003", 30),
                ('{"vendor_known": false, "amount_gross__lte": 5000, "ocr_confidence__gte": 0.90}',
                 '{"decision": "SUGGEST", "confidence": 0.75, "reasoning": "Nowy kontrahent ale niska kwota i wysoki OCR"}',
                 "rule-004", 40),
                ('{"amount_gross__lte": 50000, "ocr_confidence__gte": 0.80}',
                 '{"decision": "ASK_USER", "confidence": 0.60, "reasoning": "Średnia kwota lub nieznany kontrahent"}',
                 "rule-005", 50),
                ('{"amount_gross__gte": 50000}',
                 '{"decision": "BLOCK", "confidence": 0.40, "reasoning": "Wysoka kwota — wymagana ręczna weryfikacja"}',
                 "rule-006", 100),
                ('{}',
                 '{"decision": "ASK_USER", "confidence": 0.50, "reasoning": "Brak pasującej reguły — eskaluj"}',
                 "rule-007", 999),
            ]
        return []
    db.execute.side_effect = mock_execute
    return db


# =========================================================================
# 1.  invalidate_rules_cache() — podstawowe unieważnienie
# =========================================================================


def test_invalidate_rules_cache_calls_delete_sync(mock_rules_cache: MagicMock) -> None:
    """invalidate_rules_cache() wywołuje _rules_cache.delete_sync(CACHE_KEY)."""
    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        invalidate_rules_cache()

        mock_rules_cache.delete_sync.assert_called_once_with(CACHE_KEY)


# =========================================================================
# 2.  _get_active_rules() — cache hit vs miss
# =========================================================================


def test_get_active_rules_cache_hit(mock_rules_cache: MagicMock) -> None:
    """_get_active_rules(): cache hit → zwraca cached data, nie dotyka DuckDB."""
    cached_rules = [{"condition": {}, "output": {"decision": "AUTO_POST"}, "rule_id": "cached-1", "priority": 1}]
    mock_rules_cache.get_sync.return_value = cached_rules

    with (
        patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache),
    ):
        engine = DecisionEngine(duckdb=None)
        rules = engine._get_active_rules()

        assert rules == cached_rules, (
            f"❌ Oczekiwano danych z cache ({cached_rules}), "
            f"ale otrzymano {rules}"
        )
        mock_rules_cache.get_sync.assert_called_once_with(CACHE_KEY)
        # set_sync NIE powinno być wywołane (bo to hit)
        mock_rules_cache.set_sync.assert_not_called()


def test_get_active_rules_cache_miss_no_db(mock_rules_cache: MagicMock) -> None:
    """_get_active_rules(): cache miss + brak DuckDB → DEFAULT_DECISION_RULES."""
    mock_rules_cache.get_sync.return_value = None  # cache miss

    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=None)
        rules = engine._get_active_rules()

        assert rules == DEFAULT_DECISION_RULES, (
            f"❌ Oczekiwano DEFAULT_DECISION_RULES ({len(DEFAULT_DECISION_RULES)} rules), "
            f"ale otrzymano {len(rules)} rules"
        )
        # Gdy duckdb=None, _get_active_rules() zwraca DEFAULT_DECISION_RULES
        # bez set_sync (bo nie ma sensu cache'ować gdy nie ma DB)
        mock_rules_cache.set_sync.assert_not_called()


def test_get_active_rules_cache_miss_with_db(mock_rules_cache: MagicMock, mock_duckdb_with_rules: MagicMock) -> None:
    """_get_active_rules(): cache miss + DuckDB → ładuje z DB i cache'uje."""
    mock_rules_cache.get_sync.return_value = None  # cache miss

    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=mock_duckdb_with_rules)
        rules = engine._get_active_rules()

        # Powinno być 7 reguł (tyle zwrócił mock_duckdb_with_rules)
        assert len(rules) == 7, f"❌ Oczekiwano 7 reguł z DuckDB, ale otrzymano {len(rules)}"
        # Pierwsza reguła powinna mieć pole decision = AUTO_POST
        assert rules[0]["output"]["decision"] == "AUTO_POST", (
            f"❌ Pierwsza reguła powinna być AUTO_POST, "
            f"ale jest {rules[0]['output']['decision']}"
        )
        # set_sync powinno być wywołane z danymi z DuckDB
        mock_rules_cache.set_sync.assert_called_once()
        args, _ = mock_rules_cache.set_sync.call_args
        assert args[0] == CACHE_KEY


def test_get_active_rules_cache_miss_duckdb_fallback(mock_rules_cache: MagicMock) -> None:
    """_get_active_rules(): cache miss + DuckDB wyjątek → fallback do DEFAULT_DECISION_RULES."""
    mock_rules_cache.get_sync.return_value = None
    broken_db = MagicMock()
    # _ensure_schema() i _seed_defaults() w __init__ — pozwól im działać
    # (DDL, COUNT, INSERT), ale _get_active_rules() niech rzuci wyjątkiem
    call_count: int = 0

    def _side_effect(sql: str, params=None) -> list:
        nonlocal call_count
        call_count += 1
        # call 1: DDL w _ensure_schema()
        # call 2: SELECT COUNT w _seed_defaults() → zwraca [(7,)] (pomija seed)
        # call 3+: SELECT w _get_active_rules() → rzuć wyjątkiem
        if call_count >= 3 and "SELECT" in sql:
            raise RuntimeError("DuckDB connection lost")
        if "COUNT" in sql:
            return [(7,)]  # tabela nie jest pusta — nie seeduj
        return []

    broken_db.execute.side_effect = _side_effect

    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=broken_db)
        rules = engine._get_active_rules()

        # Fallback — DEFAULT_DECISION_RULES (bez cache — DB jest broken)
        assert rules == DEFAULT_DECISION_RULES, (
            "❌ Wyjątek DuckDB powinien skutkować DEFAULT_DECISION_RULES"
        )
        # set_sync NIE wywołane — przy wyjątku DuckDB nie cache'ujemy
        # (to fail-safe: nie cache'uj potencjalnie nieświeżych danych)
        mock_rules_cache.set_sync.assert_not_called()


# =========================================================================
# 3.  add_rule() — CRUD + cache invalidation
# =========================================================================


def test_add_rule_invalidates_cache(mock_rules_cache: MagicMock, mock_duckdb_empty: MagicMock) -> None:
    """add_rule() wywołuje invalidate_rules_cache() po INSERT."""
    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=mock_duckdb_empty)

        # Symuluj: zapisz coś w cache (symuluje stan przed add)
        # A potem dodaj regułę
        rule_id = engine.add_rule(
            condition={"amount_gross__gte": 100000},
            output={"decision": "BLOCK", "confidence": 0.30, "reasoning": "Test"},
            priority=200,
            created_by="test",
        )

        assert rule_id is not None, "❌ add_rule() zwrócił None — spodziewano się rule_id"
        assert len(rule_id) == 36, f"❌ rule_id powinno być UUID (36 znaków), ale jest '{rule_id}'"

        # delete_sync powinno być wywołane (przez invalidate_rules_cache)
        mock_rules_cache.delete_sync.assert_called_with(CACHE_KEY)


def test_add_rule_no_duckdb_returns_none(mock_rules_cache: MagicMock) -> None:
    """add_rule() bez DuckDB → zwraca None i nie unieważnia cache."""
    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=None)

        rule_id = engine.add_rule(
            condition={"amount_gross__gte": 100000},
            output={"decision": "BLOCK", "confidence": 0.30, "reasoning": "Test"},
        )

        assert rule_id is None, "❌ add_rule() bez DuckDB powinien zwrócić None"
        # delete_sync NIE powinno być wywołane
        mock_rules_cache.delete_sync.assert_not_called()


# =========================================================================
# 4.  deprecate_rule() — CRUD + cache invalidation
# =========================================================================


def test_deprecate_rule_invalidates_cache(mock_rules_cache: MagicMock) -> None:
    """deprecate_rule() wywołuje invalidate_rules_cache() po UPDATE."""
    db = MagicMock()
    db.execute.return_value = [(1,)]  # symuluj że UPDATE dotyczył 1 wiersza

    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=db)

        result = engine.deprecate_rule("rule-001")

        assert result is True, "❌ deprecate_rule() powinien zwrócić True"
        # Sprawdź że SQL UPDATE został wykonany
        db.execute.assert_called()
        call_args = db.execute.call_args
        assert call_args is not None
        sql = call_args[0][0]
        assert "UPDATE decision_rules" in sql, (
            f"❌ Oczekiwano UPDATE, ale zapytanie: {sql[:50]}..."
        )
        assert "rule-001" in str(call_args[0][1]), (
            "❌ rule_id powinno być przekazane jako parametr"
        )
        # delete_sync powinno być wywołane
        mock_rules_cache.delete_sync.assert_called_with(CACHE_KEY)


def test_deprecate_rule_no_duckdb_returns_false(mock_rules_cache: MagicMock) -> None:
    """deprecate_rule() bez DuckDB → zwraca False i nie unieważnia cache."""
    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=None)

        result = engine.deprecate_rule("rule-001")

        assert result is False, "❌ deprecate_rule() bez DuckDB powinien zwrócić False"
        mock_rules_cache.delete_sync.assert_not_called()


# =========================================================================
# 5.  _seed_defaults() — cache invalidation po reseedzie
# =========================================================================


def test_seed_defaults_invalidates_cache_on_seed(mock_rules_cache: MagicMock, mock_duckdb_empty: MagicMock) -> None:
    """_seed_defaults() unieważnia cache po INSERT domyślnych reguł.

    Gdy tabela decision_rules jest pusta, seeduje 7 domyślnych reguł
    i wywołuje invalidate_rules_cache().
    """
    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        # _seed_defaults jest wywoływane w __init__ gdy duckdb!=None
        DecisionEngine(duckdb=mock_duckdb_empty)

        # verify INSERT było wywołane 7 razy (dla każdej reguły)
        insert_count = sum(
            1 for call in mock_duckdb_empty.execute.call_args_list
            if "INSERT INTO decision_rules" in str(call[0][0])
        )
        assert insert_count == 7, (
            f"❌ _seed_defaults() powinno INSERTować 7 reguł, "
            f"ale INSERT był {insert_count} razy"
        )

        # delete_sync powinno być wywołane co najmniej raz
        mock_rules_cache.delete_sync.assert_called_with(CACHE_KEY)


def test_seed_defaults_skips_if_rules_exist(mock_rules_cache: MagicMock, mock_duckdb_with_rules: MagicMock) -> None:
    """_seed_defaults() pomija seedowanie gdy tabela nie jest pusta (COUNT>0)."""
    # mock_duckdb_with_rules zwraca COUNT=7
    # Ustaw get_sync na None (cache miss — symuluje pierwsze uruchomienie)
    mock_rules_cache.get_sync.return_value = None

    with (
        patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache),
    ):
        DecisionEngine(duckdb=mock_duckdb_with_rules)

        # verify INSERT nie było wywołane
        insert_calls = [
            call for call in mock_duckdb_with_rules.execute.call_args_list
            if "INSERT INTO decision_rules" in str(call[0][0])
        ]
        assert len(insert_calls) == 0, (
            f"❌ _seed_defaults() nie powinno INSERTować gdy tabela nie jest pusta, "
            f"ale znaleziono {len(insert_calls)} INSERTów"
        )


# =========================================================================
# 6.  decide() — używa _get_active_rules() (cache lub DuckDB)
# =========================================================================


def test_decide_with_cached_rules(mock_rules_cache: MagicMock) -> None:
    """decide() używa cache'owanych reguł do matchowania faktury."""
    # Zapisz w cache tylko jedną regułę: amount_gross__lte 10000 → SUGGEST
    cached_rules = [
        {
            "condition": {"amount_gross__lte": 10000},
            "output": {"decision": "SUGGEST", "confidence": 0.80, "reasoning": "Niska kwota"},
            "rule_id": "cached-rule-1",
            "priority": 10,
        },
    ]
    mock_rules_cache.get_sync.return_value = cached_rules

    invoice = {
        "amount_gross": 5000,
        "amount_net": 4000,
        "ocr_confidence": 0.95,
        "category": "uslugi",
    }

    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=None)
        verdict = engine.decide(invoice)

        assert isinstance(verdict, DecisionVerdict), (
            f"❌ decide() powinien zwrócić DecisionVerdict, ale zwrócił {type(verdict)}"
        )
        assert verdict.decision == "SUGGEST", (
            f"❌ Z cache'owaną regułą amount_gross__lte=10000 dla kwoty 5000, "
            f"oczekiwano SUGGEST, ale otrzymano {verdict.decision}"
        )
        assert verdict.matched_rule == "cached-rule-1", (
            f"❌ matched_rule powinno być 'cached-rule-1', "
            f"ale jest '{verdict.matched_rule}'"
        )


def test_decide_with_no_matching_rule(mock_rules_cache: MagicMock) -> None:
    """decide(): brak pasującej reguły → fallback ASK_USER."""
    # Tylko jedna reguła: kwota > 100000 → BLOCK
    cached_rules = [
        {
            "condition": {"amount_gross__gte": 100000},
            "output": {"decision": "BLOCK", "confidence": 0.40, "reasoning": "Wysoka kwota"},
            "rule_id": "cached-rule-1",
            "priority": 10,
        },
    ]
    mock_rules_cache.get_sync.return_value = cached_rules

    invoice = {"amount_gross": 500}  # poniżej progu

    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=None)
        verdict = engine.decide(invoice)

        assert verdict.decision == "ASK_USER", (
            f"❌ Gdy żadna reguła nie pasuje, oczekiwano ASK_USER (fallback), "
            f"ale otrzymano {verdict.decision}"
        )
        assert verdict.confidence == 0.5, (
            f"❌ Fallback confidence powinno być 0.5, ale jest {verdict.confidence}"
        )


def test_decide_with_vendor_profile(mock_rules_cache: MagicMock) -> None:
    """decide() używa vendor_profile do feature extraction."""
    # Reguła wymagająca vendor_known=True
    cached_rules = [
        {
            "condition": {"vendor_known": True, "amount_gross__lte": 10000},
            "output": {"decision": "AUTO_POST", "confidence": 0.95, "reasoning": "Znany vendor"},
            "rule_id": "cached-rule-1",
            "priority": 10,
        },
    ]
    mock_rules_cache.get_sync.return_value = cached_rules

    invoice = {"amount_gross": 2000, "amount_net": 1800, "ocr_confidence": 0.99}

    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=None)
        verdict = engine.decide(invoice, vendor_profile={"known": True, "invoice_count": 50, "trust_score": 0.95})

        assert verdict.decision == "AUTO_POST", (
            f"❌ Z vendor_known=True i kwotą 2000, oczekiwano AUTO_POST, "
            f"ale otrzymano {verdict.decision}"
        )


def test_decide_cache_miss_loads_from_duckdb(mock_rules_cache: MagicMock, mock_duckdb_with_rules: MagicMock) -> None:
    """decide(): cache miss → ładuje reguły z DuckDB → matche."""
    mock_rules_cache.get_sync.return_value = None  # cache miss

    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=mock_duckdb_with_rules)

        # Faktura 1000 zł, znany kontrahent → AUTO_POST (prio 20)
        verdict = engine.decide(
            {"amount_gross": 1000, "amount_net": 900, "ocr_confidence": 0.95},
            vendor_profile={"known": True, "invoice_count": 5, "trust_score": 0.85},
        )

        assert verdict.decision == "AUTO_POST", (
            f"❌ Kwota 1000 + znany kontrahent → oczekiwano AUTO_POST, "
            f"ale otrzymano {verdict.decision}"
        )
        # set_sync powinno być wywołane (cache miss → załadowano z DuckDB)
        mock_rules_cache.set_sync.assert_called_once()


# =========================================================================
# 7.  CACHE_KEY — stała zgodna z dokumentacją
# =========================================================================


def test_cache_key_constant() -> None:
    """CACHE_KEY = 'decision_rules:active' (zgodny z dokumentacją Section 9)."""
    assert CACHE_KEY == "decision_rules:active", (
        f"❌ CACHE_KEY = '{CACHE_KEY}', oczekiwano 'decision_rules:active'"
    )


def test_cache_key_used_in_invalidation() -> None:
    """invalidate_rules_cache() używa CACHE_KEY — weryfikacja przez spy."""
    from nexus_ai.core.decision_engine import _rules_cache

    original_delete_sync = _rules_cache.delete_sync

    with patch.object(_rules_cache, "delete_sync", wraps=original_delete_sync) as spy_delete:
        invalidate_rules_cache()

        spy_delete.assert_called_once_with(CACHE_KEY)


# =========================================================================
# 8.  Regression: brak side effectów między instancjami DecisionEngine
# =========================================================================


def test_cache_shared_across_instances() -> None:
    """_rules_cache jest modułowym singletonem — współdzielony między instancjami.

    Weryfikuje że get_sync na jednej instancji widzi set_sync z drugiej.
    """
    from nexus_ai.core.decision_engine import _rules_cache

    test_data = [{"test": "shared_data", "priority": 1}]
    _rules_cache.set_sync(CACHE_KEY, test_data)

    engine1 = DecisionEngine(duckdb=None)
    engine2 = DecisionEngine(duckdb=None)

    rules1 = engine1._get_active_rules()
    rules2 = engine2._get_active_rules()

    assert rules1 == test_data, (
        f"❌ engine1 nie widzi danych zapisanych w cache: {rules1}"
    )
    assert rules2 == test_data, (
        f"❌ engine2 nie widzi danych zapisanych w cache: {rules2}"
    )

    # Cleanup — usuń testowe dane
    _rules_cache.delete_sync(CACHE_KEY)


# =========================================================================
# 9.  Edge cases: pusty condition, błędne dane itp.
# =========================================================================


def test_decide_with_empty_invoice_data(mock_rules_cache: MagicMock) -> None:
    """decide() z pustymi danymi faktury → fallback."""
    cached_rules = [
        {
            "condition": {"amount_gross__lte": 10000},
            "output": {"decision": "SUGGEST", "confidence": 0.80, "reasoning": "Niska kwota"},
            "rule_id": "cached-rule-1",
            "priority": 10,
        },
    ]
    mock_rules_cache.get_sync.return_value = cached_rules

    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=None)

        # Puste invoice_data — amount_gross domyślnie 0, więc pasuje do reguły "\u003c= 10000"
        verdict = engine.decide({})

        assert verdict.decision == "SUGGEST", (
            f"❌ Puste invoice_data powinno dać SUGGEST "
            f"(amount_gross=0 pasuje do __lte=10000), ale dostał {verdict.decision}"
        )


def test_decide_invalid_vendor_profile_is_handled(mock_rules_cache: MagicMock) -> None:
    """decide() z None vendor_profile (nie dict) — nie crash."""
    cached_rules = [
        {
            "condition": {},
            "output": {"decision": "ASK_USER", "confidence": 0.50, "reasoning": "Default"},
            "rule_id": "cached-rule-1",
            "priority": 999,
        },
    ]
    mock_rules_cache.get_sync.return_value = cached_rules

    with patch("nexus_ai.core.decision_engine._rules_cache", mock_rules_cache):
        engine = DecisionEngine(duckdb=None)

        # vendor_profile=None (nie dict) — powinien obsłużyć bez crasha
        verdict = engine.decide({"amount_gross": 1000}, vendor_profile=None)

        assert isinstance(verdict, DecisionVerdict), (
            f"❌ decide() z vendor_profile=None powinien zwrócić DecisionVerdict, "
            f"ale dostał {type(verdict)}"
        )


# =========================================================================
# Podsumowanie — 16 testów
# =========================================================================
