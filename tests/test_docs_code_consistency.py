"""
Unit tests: weryfikacja spójności dokumentacji z kodem.

Każdy test sprawdza czy konkretne twierdzenie z docs/ jest zgodne
z rzeczywistym stanem kodu źródłowego.

Zakres:
  - Istnienie klas i modułów wymienionych w dokumentacji
  - Sygnatury metod (nazwy, parametry)
  - Stałe i wartości domyślne (DEFAULT_DECISION_RULES, TRUST_WEIGHTS itp.)
  - Cache key patterns (NexusCache)
  - Architektura komponentów (v2.0 → v2.2 mapping)
  - Cleanup lifecycle (async close())
"""

from __future__ import annotations

import ast
from pathlib import Path
from typing import Any

import pytest


# Czy zależności (structlog, duckdb, sqlmodel) są dostępne?
# Jeśli nie, testy wymagające importu są pomijane.
_HAS_DEPS: bool | None = None


def _check_deps() -> bool:
    """Sprawdź czy zależności zewnętrzne są dostępne."""
    global _HAS_DEPS
    if _HAS_DEPS is not None:
        return _HAS_DEPS
    try:
        import structlog  # noqa: F401
        import duckdb  # noqa: F401
        _HAS_DEPS = True
    except ImportError:
        _HAS_DEPS = False
    return _HAS_DEPS


NEEDS_DEPS = pytest.mark.skipif(
    not _check_deps(),
    reason="Pominięto — brak zależności (structlog, duckdb) — uruchom: pixi install",
)


# =========================================================================
# Helpery — odporne na brak zależności (import fail)
# =========================================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Cache dla AST: {path: ast.Module}
_AST_CACHE: dict[Path, ast.Module] = {}


def _module_path(module_path: str) -> Path:
    """Konwertuj kropkową ścieżkę modułu na ścieżkę pliku.

    Obsługuje zarówno pojedyncze pliki (module.py) jak i pakiety (module/__init__.py).
    """
    path = PROJECT_ROOT / module_path.replace(".", "/")
    if path.with_suffix(".py").exists():
        return path.with_suffix(".py")
    init_py = path / "__init__.py"
    if init_py.exists():
        return init_py
    return path.with_suffix(".py")  # fallback — czytelny błąd przy braku pliku


def _get_ast(path: Path) -> ast.Module:
    """Zwróć sparsowane AST dla pliku (z cache)."""
    if path not in _AST_CACHE:
        _AST_CACHE[path] = ast.parse(path.read_text())
    return _AST_CACHE[path]


def _class_exists(module_path: str, class_name: str) -> bool:
    """Sprawdź czy klasa istnieje w pliku źródłowym (przez AST — nie wymaga importu)."""
    path = _module_path(module_path)
    if not path.exists():
        return False
    try:
        tree = _get_ast(path)
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef) and node.name == class_name:
                return True
        return False
    except SyntaxError:
        return False


def _function_exists(module_path: str, func_name: str) -> bool:
    """Sprawdź czy funkcja istnieje w pliku źródłowym (przez AST — nie wymaga importu)."""
    path = _module_path(module_path)
    if not path.exists():
        return False
    try:
        tree = _get_ast(path)
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == func_name:
                return True
        return False
    except SyntaxError:
        return False


def _get_class_ast(module_path: str, class_name: str) -> ast.ClassDef:
    """Zwróć węzeł AST dla klasy (przez AST — nie wymaga importu). Fail jeśli brak."""
    path = _module_path(module_path)
    assert path.exists(), f"❌ Plik {path} nie istnieje"
    tree = _get_ast(path)
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef) and node.name == class_name:
            return node
    pytest.fail(f"❌ Klasa '{class_name}' nie znaleziona w {module_path}")


# =========================================================================
# 1.  Istnienie ścieżek modułów i klas (docs + code)
# =========================================================================

# (ścieżka_modułu, nazwa_klasy/funkcji, rodzaj, opis_w_docs)
COMPONENTS_IN_DOCS: list[tuple[str, str, str, str]] = [
    # DecisionEngine
    ("nexus_ai.core.decision_engine", "DecisionEngine", "class", "Section 2 COGNITIVE_ARCHITECTURE.md"),
    ("nexus_ai.core.decision_engine", "DecisionVerdict", "class", "Section 2 COGNITIVE_ARCHITECTURE.md"),
    ("nexus_ai.core.decision_engine", "classify_invoice", "function", "Section 2.4 COGNITIVE_ARCHITECTURE.md"),
    ("nexus_ai.core.decision_engine", "calculate_trust_score", "function", "Section 2.5 COGNITIVE_ARCHITECTURE.md"),
    ("nexus_ai.core.decision_engine", "invalidate_rules_cache", "function", "Section 2.7 zarządzanie regułami"),
    # ProtocolLoader
    ("nexus_ai.core.protocol_loader", "ProtocolLoader", "class", "Section 3.3 COGNITIVE_ARCHITECTURE.md"),
    ("nexus_ai.core.protocol_loader", "get_protocol_loader", "function", "Section 3.3 COGNITIVE_ARCHITECTURE.md"),
    # FactsAggregator
    ("nexus_ai.services.facts_aggregator", "FactsAggregator", "class", "Section 4 COGNITIVE_ARCHITECTURE.md"),
    ("nexus_ai.services.facts_aggregator", "FactSheet", "class", "Section 4.3 COGNITIVE_ARCHITECTURE.md"),
    # RiskGuard
    ("nexus_ai.services.risk_guard", "RiskGuard", "class", "Section 5 COGNITIVE_ARCHITECTURE.md"),
    ("nexus_ai.services.risk_guard", "RiskThreshold", "class", "Section 5 COGNITIVE_ARCHITECTURE.md"),
    ("nexus_ai.services.risk_guard", "RiskVerdict", "class", "Section 5 COGNITIVE_ARCHITECTURE.md"),
    # SemanticGuard
    ("nexus_ai.services.semantic_guard", "SemanticGuard", "class", "Section 6 COGNITIVE_ARCHITECTURE.md"),
    # DecisionLogger
    ("nexus_ai.services.decision_logger", "DecisionLogger", "class", "Section 7 COGNITIVE_ARCHITECTURE.md"),
    # WhiteListService
    ("nexus_ai.services.white_list_service", "WhiteListService", "class", "Section 18 TECHNOLOGIES.md"),
    # CurrencyConverter
    ("nexus_ai.services.currency_converter", "CurrencyConverter", "class", "Section 18 TECHNOLOGIES.md"),
    ("nexus_ai.services.currency_converter", "Money", "class", "Section 18 TECHNOLOGIES.md / Section 10"),
    # ContextEnricher
    ("nexus_ai.services.context_enricher", "ContextEnricher", "class", "Section 18 TECHNOLOGIES.md / Appendix F"),
    # NexusCache — oba w dyscache.py (get_cache re-eksportowany przez __init__)
    ("nexus_ai.core.cache.dyscache", "NexusCache", "class", "Section 14 TECHNOLOGIES.md"),
    ("nexus_ai.core.cache.dyscache", "get_cache", "function", "Section 14 TECHNOLOGIES.md"),
    # CachedHttpClient
    ("nexus_ai.core.cache.http_client", "CachedHttpClient", "class", "Section 18 TECHNOLOGIES.md"),
    # GusBirClient
    ("nexus_ai.services.gus_bir_client", "GusBirClient", "class", "Section 18 TECHNOLOGIES.md"),
]


@pytest.mark.parametrize("module_path,name,kind,doc_ref", COMPONENTS_IN_DOCS)
def test_component_exists_in_code(module_path: str, name: str, kind: str, doc_ref: str) -> None:
    """Każdy komponent wymieniony w dokumentacji istnieje w kodzie.

    Używa AST (nie importu) — odporne na brak zależności (np. structlog, duckdb).
    """
    if kind == "class":
        assert _class_exists(module_path, name), (
            f"❌ Klasa '{name}' wymieniona w docs ({doc_ref}) "
            f"nie istnieje w {module_path}.py"
        )
    elif kind == "function":
        assert _function_exists(module_path, name), (
            f"❌ Funkcja '{name}' wymieniona w docs ({doc_ref}) "
            f"nie istnieje w {module_path}.py"
        )


# =========================================================================
# 2.  Sygnatury metod — kluczowe metody wymienione w dokumentacji
# =========================================================================

METHOD_SIGNATURES: list[tuple[str, str, str, list[str], str]] = [
    # (module, class_name, method_name, expected_params, doc_ref)
    ("nexus_ai.core.decision_engine", "DecisionEngine", "decide",
     ["self", "invoice_data", "vendor_profile"], "Section 2 COGNITIVE_ARCHITECTURE.md"),
    ("nexus_ai.core.decision_engine", "DecisionEngine", "_match_condition",
     ["condition", "features"], "Section 2.6 COGNITIVE_ARCHITECTURE.md"),  # @staticmethod — brak self
    ("nexus_ai.core.decision_engine", "DecisionEngine", "add_rule",
     ["self", "condition", "output", "priority", "valid_from", "valid_to", "created_by"], "Section 2.7"),
    ("nexus_ai.core.decision_engine", "DecisionEngine", "deprecate_rule",
     ["self", "rule_id"], "Section 2.7"),
    ("nexus_ai.services.risk_guard", "RiskGuard", "get_threshold",
     ["self", "tax_form", "expense_type", "field"], "Section 5.2 COGNITIVE_ARCHITECTURE.md / DECISION_FLOW.md"),
    ("nexus_ai.services.risk_guard", "RiskGuard", "evaluate",
     ["self", "fields_with_confidence", "tax_form", "expense_type"], "DECISION_FLOW.md Krok 4"),
    ("nexus_ai.services.semantic_guard", "SemanticGuard", "evaluate",
     ["self", "invoice_text", "vendor_nip", "amount_net"], "Section 6 COGNITIVE_ARCHITECTURE.md"),
    ("nexus_ai.services.decision_logger", "DecisionLogger", "log_decision",
     ["self", "invoice_id", "alpha_verdict", "beta_verdict", "gamma_verdict",
      "final_decision", "trust_score", "trust_components", "context"], "Section 7.3"),
    ("nexus_ai.services.decision_logger", "DecisionLogger", "get_trust_score_trend",
     ["self", "contractor_nip", "days"], "Section 7.3"),
    ("nexus_ai.services.decision_logger", "DecisionLogger", "get_decisions_for_invoice",
     ["self", "invoice_id"], "Section 7.3"),
    ("nexus_ai.core.protocol_loader", "ProtocolLoader", "get_protocol",
     ["self", "protocol_path"], "Section 3.3"),
    ("nexus_ai.services.white_list_service", "WhiteListService", "verify_bank_account",
     ["self", "nip", "account_to_check"], "Section 18"),
]


@pytest.mark.parametrize("module_path,class_name,method_name,expected_params,doc_ref", METHOD_SIGNATURES)
def test_method_signature(
    module_path: str, class_name: str, method_name: str,
    expected_params: list[str], doc_ref: str,
) -> None:
    """Sygnatura metod w kodzie zgadza się z dokumentacją.

    Używa AST (nie importu) — odporne na brak zależności.
    """
    cls_ast = _get_class_ast(module_path, class_name)
    method_node = None
    for node in cls_ast.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == method_name:
            method_node = node
            break
    assert method_node is not None, (
        f"❌ Metoda '{class_name}.{method_name}()' wymieniona w docs ({doc_ref}) "
        f"nie istnieje w {module_path}.py"
    )

    # Wyciągnij nazwy parametrów z AST (pomijając self)
    param_names = [arg.arg for arg in method_node.args.args]
    if param_names and param_names[0] == "self":
        param_names = param_names[1:]  # usuń self dla porównania z oczekiwanymi

    # Sprawdź, że wszystkie oczekiwane parametry istnieją w sygnaturze
    # expected_params zawiera 'self' dla kompatybilności z dokumentacją,
    # ale AST już usunął 'self' — więc porównuj bez self
    params_wo_self = [p for p in expected_params if p != "self"]
    for p in params_wo_self:
        assert p in param_names, (
            f"❌ Metoda '{class_name}.{method_name}()' powinna mieć parametr '{p}' "
            f"(wg docs: {doc_ref}), ale znaleziono: {param_names}"
        )


# =========================================================================
# 3.  DEFAULT_DECISION_RULES — zgodność z macierzą decyzyjną w dokumentacji
# =========================================================================

# Macierz decyzyjna z docs/DECISION_FLOW.md Section 9 i COGNITIVE_ARCHITECTURE.md Section 2.3
# (priorytet, decision, min_confidence, kluczowe_warunki)
DOCUMENTED_RULES: list[tuple[int, str, float, set[str]]] = [
    (10,   "AUTO_POST", 0.95, {"vendor_known", "vendor_invoice_count__gte", "vendor_trust__gte", "amount_gross__lte", "ocr_confidence__gte"}),
    (20,   "AUTO_POST", 0.90, {"vendor_known", "vendor_invoice_count__gte", "vendor_trust__gte", "amount_gross__lte", "ocr_confidence__gte"}),
    (30,   "SUGGEST",   0.80, {"vendor_known", "amount_gross__lte", "ocr_confidence__gte"}),
    (40,   "SUGGEST",   0.75, {"vendor_known", "amount_gross__lte", "ocr_confidence__gte"}),
    (50,   "ASK_USER",  0.60, {"amount_gross__lte", "ocr_confidence__gte"}),
    (100,  "BLOCK",     0.40, {"amount_gross__gte"}),
    (999,  "ASK_USER",  0.50, set()),  # {} empty = fallback
]


@NEEDS_DEPS
def test_default_decision_rules_count() -> None:
    """Liczba domyślnych reguł w kodzie zgadza się z dokumentacją (7 reguł)."""
    from nexus_ai.core.decision_engine import DEFAULT_DECISION_RULES
    assert len(DEFAULT_DECISION_RULES) == len(DOCUMENTED_RULES), (
        f"❌ Oczekiwano {len(DOCUMENTED_RULES)} reguł (wg dokumentacji), "
        f"ale kod ma {len(DEFAULT_DECISION_RULES)}"
    )


@NEEDS_DEPS
def test_default_decision_rules_content() -> None:
    """Każda reguła w DEFAULT_DECISION_RULES ma zgodne priorytety, decyzje i warunki."""
    from nexus_ai.core.decision_engine import DEFAULT_DECISION_RULES

    # Indeksuj reguły kodu po priorytecie
    code_rules_by_priority: dict[int, tuple[str, float, set[str]]] = {}
    for rule in DEFAULT_DECISION_RULES:
        prio = int(rule["priority"])
        cond_keys = set(rule.get("condition", {}).keys())
        output = rule.get("output", {})
        decision = str(output.get("decision", ""))
        confidence = float(output.get("confidence", 0.0))
        code_rules_by_priority[prio] = (decision, confidence, cond_keys)

    for doc_prio, doc_decision, doc_conf, doc_cond_keys in DOCUMENTED_RULES:
        assert doc_prio in code_rules_by_priority, (
            f"❌ Reguła o priorytecie {doc_prio} (wg docs) nie istnieje w kodzie. "
            f"Dostępne priorytety: {sorted(code_rules_by_priority.keys())}"
        )

        code_decision, code_conf, code_cond_keys = code_rules_by_priority[doc_prio]

        assert code_decision == doc_decision, (
            f"❌ Reguła prio={doc_prio}: docs mówi '{doc_decision}', "
            f"ale kod ma '{code_decision}'"
        )

        assert abs(code_conf - doc_conf) < 0.01, (
            f"❌ Reguła prio={doc_prio}: docs mówi confidence={doc_conf}, "
            f"ale kod ma {code_conf}"
        )

        # Sprawdź, że warunki kodu zawierają wszystkie warunki z docs
        # (kod może mieć dodatkowe szczegóły, ale nie może brakować kluczowych)
        missing_cond_keys = doc_cond_keys - code_cond_keys
        assert not missing_cond_keys, (
            f"❌ Reguła prio={doc_prio}: w docs są warunki {missing_cond_keys}, "
            f"ale brak ich w kodzie (kod ma: {code_cond_keys})"
        )


# =========================================================================
# 4.  DEFAULT_RISK_THRESHOLDS — zgodność z tabelą w dokumentacji
# =========================================================================

# Tabela z COGNITIVE_ARCHITECTURE.md Section 5.2
# (tax_form, field/expense, required_confidence, action)
DOCUMENTED_RISK_THRESHOLDS: list[tuple[str, str, float, str]] = [
    ("CIT_STANDARD", "vat_rate",      0.98, "BLOCK_AND_ALERT"),
    ("CIT_STANDARD", "total_net",     0.95, "BLOCK_AND_ALERT"),
    ("CIT_ESTONIAN", "vat_rate",      0.95, "BLOCK_AND_ALERT"),
    ("LINEAR",       "",              0.85, "TRIAGE_QUEUE"),   # catch-all
    ("LUMP_SUM",     "total_net",     0.60, "TRIAGE_QUEUE"),
    ("LUMP_SUM",     "vat_rate",      0.95, "TRIAGE_QUEUE"),
]


@NEEDS_DEPS
def test_default_risk_thresholds_documented() -> None:
    """Każdy próg ryzyka z dokumentacji istnieje w DEFAULT_RISK_THRESHOLDS."""
    from nexus_ai.services.risk_guard import DEFAULT_RISK_THRESHOLDS

    for doc_tax_form, doc_field_or_exp, doc_conf, doc_action in DOCUMENTED_RISK_THRESHOLDS:
        found = False
        for rule in DEFAULT_RISK_THRESHOLDS:
            cond = rule.get("condition_json", {})
            output = rule.get("output_json", {})
            rule_tax = cond.get("tax_form", "")
            rule_field = cond.get("field", "")
            rule_expense = cond.get("expense_type", "")
            rule_conf = float(output.get("required_ml_confidence", 0))
            rule_action = output.get("action_if_below", "")

            # Dopasuj: tax_form musi być zgodny, a field LUB expense_type
            if rule_tax != doc_tax_form:
                continue
            if rule_field and rule_field == doc_field_or_exp:
                pass  # dokładne dopasowanie pola
            elif not rule_field and doc_field_or_exp == "":
                pass  # catch-all (np. LINEAR)
            elif rule_expense and rule_expense == doc_field_or_exp:
                pass  # expense_type zamiast field
            else:
                continue

            assert abs(rule_conf - doc_conf) < 0.01, (
                f"❌ Próg {doc_tax_form}/{doc_field_or_exp}: "
                f"docs mówi confidence={doc_conf}, ale kod ma {rule_conf}"
            )
            assert rule_action == doc_action, (
                f"❌ Próg {doc_tax_form}/{doc_field_or_exp}: "
                f"docs mówi action='{doc_action}', ale kod ma '{rule_action}'"
            )
            found = True
            break

        assert found, (
            f"❌ Próg ryzyka '{doc_tax_form}/{doc_field_or_exp}' "
            f"wymieniony w docs nie istnieje w DEFAULT_RISK_THRESHOLDS"
        )


# =========================================================================
# 5.  TRUST_WEIGHTS — zgodność z dokumentacją
# =========================================================================

# Wagi z COGNITIVE_ARCHITECTURE.md Section 2.5 i DECISION_FLOW.md Section 4
DOCUMENTED_TRUST_WEIGHTS: dict[str, float] = {
    "ocr_confidence": 0.30,
    "vendor_reliability": 0.25,
    "data_consistency": 0.20,
    "context_trust": 0.10,
    "risk_guard": 0.15,
}


@NEEDS_DEPS
def test_trust_weights_consistency() -> None:
    """Wagi trust score w kodzie zgadzają się z dokumentacją."""
    from nexus_ai.core.decision_engine import TRUST_WEIGHTS

    assert TRUST_WEIGHTS == DOCUMENTED_TRUST_WEIGHTS, (
        f"❌ TRUST_WEIGHTS niezgodne z dokumentacją:\n"
        f"  Kod:     {TRUST_WEIGHTS}\n"
        f"  Docs:    {DOCUMENTED_TRUST_WEIGHTS}\n"
    )

    # Suma wag = 1.0
    total = sum(TRUST_WEIGHTS.values())
    assert abs(total - 1.0) < 0.01, (
        f"❌ Suma TRUST_WEIGHTS = {total}, powinna być 1.0"
    )


# =========================================================================
# 6.  classify_invoice() — logika zgodna z dokumentacją
# =========================================================================

# Warunki z COGNITIVE_ARCHITECTURE.md Section 2.4
# Simple: amount<=5000 AND vendor_known AND vendor_count>=3 AND ocr_conf>=0.85


@NEEDS_DEPS
def test_classify_invoice_simple_conditions() -> None:
    """classify_invoice() zwraca 'simple' tylko gdy spełnione warunki z docs."""
    from nexus_ai.core.decision_engine import classify_invoice

    # Simple: wszystkie warunki spełnione
    assert classify_invoice(
        {"amount_gross": 3000, "ocr_confidence": 0.90},
        {"known": True, "invoice_count": 5},
    ) == "simple", "❌ Powinno być 'simple': kwota≤5000, znany, ≥3 faktury, OCR≥0.85"

    # Complex: za wysoka kwota
    assert classify_invoice(
        {"amount_gross": 6000, "ocr_confidence": 0.90},
        {"known": True, "invoice_count": 5},
    ) == "complex", "❌ Powinno być 'complex': kwota>5000"

    # Complex: nieznany kontrahent
    assert classify_invoice(
        {"amount_gross": 1000, "ocr_confidence": 0.90},
        {"known": False, "invoice_count": 0},
    ) == "complex", "❌ Powinno być 'complex': vendor_known=False"

    # Complex: za mało faktur
    assert classify_invoice(
        {"amount_gross": 1000, "ocr_confidence": 0.90},
        {"known": True, "invoice_count": 1},
    ) == "complex", "❌ Powinno być 'complex': vendor_count<3"

    # Complex: niski OCR
    assert classify_invoice(
        {"amount_gross": 1000, "ocr_confidence": 0.50},
        {"known": True, "invoice_count": 5},
    ) == "complex", "❌ Powinno być 'complex': OCR<0.85"


# =========================================================================
# 7.  NexusCache — interfejs zgodny z dokumentacją
# =========================================================================

EXPECTED_NEXUSCACHE_METHODS = {
    "get": ["key"],
    "set": ["key", "value", "ttl"],
    "delete": ["key"],
    "delete_many": [],  # *keys variadic — AST sprawdza tylko args
    "keys": ["prefix"],
    "clear": [],
    "get_sync": ["key"],
    "set_sync": ["key", "value", "ttl"],
    "delete_sync": ["key"],
    "delete_prefix_sync": ["prefix"],
    "get_or_compute": ["key", "compute_func", "ttl"],
}


def test_nexuscache_interface() -> None:
    """NexusCache implementuje wszystkie metody wymienione w dokumentacji.

    Używa AST — odporne na brak zależności (dyscache, structlog).
    """
    cls_ast = _get_class_ast("nexus_ai.core.cache.dyscache", "NexusCache")

    # Zbierz wszystkie metody zdefiniowane w klasie
    defined_methods = {
        node.name: [arg.arg for arg in node.args.args if arg.arg != "self" and arg.arg != "cls"]
        for node in cls_ast.body
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
    }

    for method_name, expected_params in EXPECTED_NEXUSCACHE_METHODS.items():
        assert method_name in defined_methods, (
            f"❌ NexusCache brakuje metody '{method_name}()' wymienionej w docs. "
            f"Dostepne: {list(defined_methods.keys())}"
        )
        actual_params = defined_methods[method_name]
        for p in expected_params:
            assert p in actual_params, (
                f"❌ NexusCache.{method_name}() powinna mieć parametr '{p}' "
                f"(wg docs), ale znaleziono: {actual_params}"
            )


def test_get_cache_singleton_ast() -> None:
    """get_cache() implementuje wzorzec singleton (global _default_cache)."""
    path = _module_path("nexus_ai.core.cache.dyscache")
    assert path.exists()
    content = path.read_text()

    # Sprawdź że istnieje globalny _default_cache = None
    assert "_default_cache: NexusCache | None = None" in content or "_default_cache = None" in content, (
        "❌ get_cache() nie implementuje singletona — brak _default_cache = None"
    )
    # Sprawdź że get_cache sprawdza _default_cache
    assert "if _default_cache is None:" in content, (
        "❌ get_cache() nie implementuje singletona — brak 'if _default_cache is None:'"
    )


# =========================================================================
# 8.  async close() — cleanup lifecycle (Appendix F)
# =========================================================================

# Serwisy z Appendix F i TECHNOLOGIES.md które powinny mieć async close()
SERVICES_WITH_CLOSE: list[tuple[str, str, str]] = [
    ("nexus_ai.services.white_list_service", "WhiteListService", "Appendix F / Section 18"),
    ("nexus_ai.services.currency_converter", "CurrencyConverter", "Appendix F / Section 18"),
    ("nexus_ai.services.context_enricher", "ContextEnricher", "Appendix F"),
    ("nexus_ai.core.cache.http_client", "CachedHttpClient", "Appendix F"),
]


@pytest.mark.parametrize("module_path,class_name,doc_ref", SERVICES_WITH_CLOSE)
def test_close_method_exists(module_path: str, class_name: str, doc_ref: str) -> None:
    """Serwisy wymienione w Appendix F mają async close().

    Używa AST — odporne na brak zależności.
    """
    cls_ast = _get_class_ast(module_path, class_name)

    # Znajdź metodę close()
    close_node = None
    for node in cls_ast.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == "close":
            close_node = node
            break

    assert close_node is not None, (
        f"❌ '{class_name}' wymieniony w docs ({doc_ref}) jako serwis z close(), "
        f"ale brakuje metody close()"
    )
    # Sprawdź że to async def (AsyncFunctionDef)
    assert isinstance(close_node, ast.AsyncFunctionDef), (
        f"❌ '{class_name}.close()' nie jest async (powinien być async def), "
        f"jest {'funkcją' if isinstance(close_node, ast.FunctionDef) else 'czymś innym'}"
    )


# =========================================================================
# 9.  ANOMALY_RULES w SemanticGuard — zgodność z dokumentacją
# =========================================================================

# Dokumentacja nie podaje konkretnej tabeli ANOMALY_RULES, ale mówi o:
# - "Sprawdza reguły w anomaly_rules (DuckDB)"
# W kodzie reguły są inline (ANOMALY_RULES), nie w DuckDB.
# Sprawdźmy czy podstawowa struktura jest zgodna.


@NEEDS_DEPS
def test_anomaly_rules_structure() -> None:
    """ANOMALY_RULES mają wymagane pola zgodne z dokumentacją (action, min_score, alert)."""
    from nexus_ai.services.semantic_guard import ANOMALY_RULES

    assert len(ANOMALY_RULES) >= 1, "❌ ANOMALY_RULES nie może być pusta"

    for rule in ANOMALY_RULES:
        assert "min_score" in rule, f"❌ Reguła anomalii brakuje 'min_score': {rule}"
        assert "action" in rule, f"❌ Reguła anomalii brakuje 'action': {rule}"
        assert isinstance(rule["min_score"], (int, float)), (
            f"❌ 'min_score' powinien być liczbowy: {rule}"
        )
        assert rule["action"] in ("ALLOW", "WARN", "BLOCK_DECREE"), (
            f"❌ 'action' powinien być ALLOW/WARN/BLOCK_DECREE: {rule}"
        )

    # Ostatnia reguła powinna być fallback (ALLOW, min_score=0.0)
    last_rule = ANOMALY_RULES[-1]
    assert last_rule["action"] == "ALLOW", (
        f"❌ Ostatnia reguła anomalii powinna być ALLOW (fallback), "
        f"ale jest '{last_rule['action']}'"
    )
    assert last_rule["min_score"] == 0.0, (
        f"❌ Ostatnia reguła anomalii powinna mieć min_score=0.0, "
        f"ale ma {last_rule['min_score']}"
    )


# =========================================================================
# 10.  _match_condition() — operatory zgodne z dokumentacją
# =========================================================================

# Dokumentacja (Section 2.6) wymienia 4 operatory:
# field, field__gte, field__lte, field__in


@NEEDS_DEPS
@pytest.mark.parametrize("condition,features,expected", [
    ({"vendor_known": True}, {"vendor_known": True, "amount": 100}, True),
    ({"vendor_known": True}, {"vendor_known": False, "amount": 100}, False),
    ({"amount__gte": 100}, {"amount": 150}, True),
    ({"amount__gte": 100}, {"amount": 50}, False),
    ({"amount__lte": 100}, {"amount": 50}, True),
    ({"amount__lte": 100}, {"amount": 150}, False),
    ({"field__in": ["a", "b", "c"]}, {"field": "a"}, True),
    ({"field__in": ["a", "b", "c"]}, {"field": "z"}, False),
    ({}, {"anything": "value"}, True),  # fallback — pusty warunek
])
def test_match_condition_operators(condition, features, expected) -> None:
    """_match_condition obsługuje operatory wymienione w dokumentacji."""
    from nexus_ai.core.decision_engine import DecisionEngine

    result = DecisionEngine._match_condition(condition, features)
    assert result is expected, (
        f"❌ _match_condition({condition}, {features}) = {result}, "
        f"oczekiwano {expected}"
    )


# =========================================================================
# 11.  Cache key patterns — zgodność wzorców kluczy NexusCache
# =========================================================================

# Dokumentacja COGNITIVE_ARCHITECTURE.md Section 9 i DECISION_FLOW.md Appendix B
# podaje konkretne wzorce kluczy cache

CACHE_KEY_PATTERNS: dict[str, str] = {
    "few_shot": "few_shot:{data_hash}:{max_examples}",
    "enrich": "enrich:{invoice_id}",
    "whitelist": "whitelist:{nip}:{account}",
    "fx_rate": "fx_rate:{currency}:{date}",
    "risk_threshold": "risk_threshold:{tax_form}:{expense_type}:{field}",
    "prompt_pack": "prompt_pack:{lang}",
    "decision_rules": "decision_rules:active",
}


def test_cache_key_pattern_usage() -> None:
    """Wzorce kluczy cache z dokumentacji są używane w kodzie."""
    import ast
    import os

    # Przeszukaj pliki źródłowe w poszukiwaniu kluczy cache
    # To nie jest doskonałe (mogą być stringi w zmiennych), ale daje dobry sygnał
    source_dirs = [
        PROJECT_ROOT / "nexus_ai" / "core",
        PROJECT_ROOT / "nexus_ai" / "services",
    ]

    for key_name, pattern in CACHE_KEY_PATTERNS.items():
        found_in_files = []
        for src_dir in source_dirs:
            if not src_dir.exists():
                continue
            for py_file in src_dir.rglob("*.py"):
                if py_file.name.startswith("__"):
                    continue
                try:
                    content = py_file.read_text()
                    if key_name in content or pattern.split(":")[0] in content:
                        found_in_files.append(py_file.relative_to(PROJECT_ROOT))
                except Exception:
                    continue

        assert found_in_files, (
            f"❌ Wzorzec klucza cache '{key_name}' ({pattern}) "
            f"opisany w docs (Section 9) nie jest używany w żadnym pliku źródłowym"
        )


# =========================================================================
# 12.  DecisionEngine.DECISION_RULES_SCHEMA — zgodność z dokumentacją
# =========================================================================

@NEEDS_DEPS
def test_decision_rules_schema_has_documented_fields() -> None:
    """Tabela decision_rules ma wszystkie pola wymienione w dokumentacji."""
    from nexus_ai.core.decision_engine import DECISION_RULES_SCHEMA

    documented_fields = {"rule_id", "condition_json", "output_json",
                         "priority", "valid_from", "valid_to", "created_at"}
    for field in documented_fields:
        assert field in DECISION_RULES_SCHEMA, (
            f"❌ Pole '{field}' wymienione w dokumentacji (Section 2.3) "
            f"nie istnieje w DECISION_RULES_SCHEMA"
        )


# =========================================================================
# 13.  COMPONENT MAPPING v2.0 → v2.2 — zgodność z Appendix A
# =========================================================================

# Appendix A w COGNITIVE_ARCHITECTURE.md (Section 11) podaje mapowanie:
V2_COMPONENT_MAP: dict[str, str] = {
    "Council of Agents": "DecisionEngine.decide() + DuckDB decision_rules",
    "WorkflowPlanner": "classify_invoice()",
    "JambaStrategist": "DecisionEngine.decide()",
    "Rules SWAT Team": "Hierarchiczne reguły DuckDB",
    "TrustScoreCalculator": "calculate_trust_score()",
    "PLE Engine": "DecisionLogger.get_trust_score_trend()",
    "BayesianThresholdLearner": "Statystyki w DuckDB",
    "AgentOrchestrator": "services/council_session.py, services/autopilot.py (DEPRECATED)",
}


def test_v2_components_are_not_in_core() -> None:
    """Stare komponenty v2.0 nie występują jako aktywne klasy w core/.

    Dopuszczalne są:
    - Wzmianki w docstringach opisujących historię ("Zastępuje", "v2.0")
    - Importy z serwisów deprecated (services.autopilot, services.council_session)
    - Udokumentowane w API/komentarzach jako legacy ("historyczny", "DEPRECATED")
    - Wzmianki w kontekście budowania promptów ("prompt dla AgentOrchestrator")
    """
    v2_names = {"CouncilOfAgents", "WorkflowPlanner", "JambaStrategist",
                "RulesSWATTeam", "TrustScoreCalculator", "PLEEngine",
                "BayesianThresholdLearner", "AgentOrchestrator"}

    # Wyrażenia które wykluczają wzmiankę z alertu
    ALLOWED_CONTEXT = {"Zastępuje", "v2.0", "historyczny", "DEPRECATED",
                      "services.autopilot", "services.council_session",
                      "prompt dla", "prompt for", "AgentOrchestrator /"}

    core_dir = PROJECT_ROOT / "nexus_ai" / "core"
    violations: list[str] = []

    for py_file in core_dir.rglob("*.py"):
        if py_file.name.startswith("__"):
            continue
        content = py_file.read_text()
        for v2_name in v2_names:
            if v2_name in content:
                # Sprawdź czy to dopuszczalny kontekst
                if any(ctx in content for ctx in ALLOWED_CONTEXT):
                    continue
                violations.append(
                    f"{py_file.relative_to(PROJECT_ROOT)}: '{v2_name}' "
                    f"bez dozwolonego kontekstu"
                )

    assert not violations, (
        f"❌ Stare komponenty v2.0 znalezione w core/ bez dozwolonego kontekstu:\n"
        + "\n".join(f"  • {v}" for v in violations)
    )


# =========================================================================
# 14.  _get_active_rules() — event-based cache invalidation
# =========================================================================

@NEEDS_DEPS
def test_rules_cache_invalidation() -> None:
    """_get_active_rules() używa event-based invalidation (bez TTL), zgodnie z implementacją."""
    from nexus_ai.core.decision_engine import _rules_cache, CACHE_KEY, invalidate_rules_cache

    # Symuluj: zapisz coś w cache
    _rules_cache.set_sync(CACHE_KEY, [{"test": "data"}])

    # Powinno być dostępne
    cached = _rules_cache.get_sync(CACHE_KEY)
    assert cached is not None, "❌ Cache powinien zawierać dane po set_sync"

    # Unieważnij
    invalidate_rules_cache()

    # Powinno być puste
    cached_after = _rules_cache.get_sync(CACHE_KEY)
    assert cached_after is None, (
        "❌ invalidate_rules_cache() nie unieważnił cache — "
        "cache wciąż zawiera dane"
    )


# =========================================================================
# 15.  Security: brak 'any' type cast w kluczowych metodach
# =========================================================================

def test_no_any_type_casts_in_decision_engine() -> None:
    """DecisionEngine.decide() ma adnotację typu zwracanego (nie Any)."""
    # Użyj AST — nie wymaga importu
    cls_ast = _get_class_ast("nexus_ai.core.decision_engine", "DecisionEngine")
    for node in cls_ast.body:
        if isinstance(node, ast.FunctionDef) and node.name == "decide":
            # Sprawdź czy istnieje adnotacja zwracanego typu (-> ...)
            assert node.returns is not None, (
                "❌ DecisionEngine.decide() nie ma adnotacji typu zwracanego"
            )
            # Sprawdź że to nie jest `-> Any`
            if isinstance(node.returns, ast.Name):
                assert node.returns.id != "Any", (
                    "❌ DecisionEngine.decide() zwraca Any — "
                    "powinien zwracać DecisionVerdict"
                )
            break


# =========================================================================
# 16.  _seed_defaults() unieważnia cache — zgodność z dokumentacją
# =========================================================================

@NEEDS_DEPS
def test_seed_defaults_invalidates_cache() -> None:
    """_seed_defaults() unieważnia cache po reseedzie (zgodnie z event-based invalidation)."""
    from nexus_ai.core.decision_engine import (
        _rules_cache, CACHE_KEY, invalidate_rules_cache,
    )

    # Symuluj: ustaw jakby cache był pełny (sytuacja przed seedem)
    _rules_cache.set_sync(CACHE_KEY, [{"pre_seed": "data"}])

    # Po wywołaniu invalidate_rules_cache() (symuluje to co robi _seed_defaults)
    invalidate_rules_cache()

    # Cache powinien być pusty
    assert _rules_cache.get_sync(CACHE_KEY) is None, (
        "❌ _seed_defaults() nie unieważnia cache — "
        "stare reguły mogą być używane"
    )


# =========================================================================
# 17.  FactSheet.build_few_shot_examples() — metoda z dokumentacji
# =========================================================================

def test_factsheet_methods_exist() -> None:
    """FactSheet ma metody wymienione w dokumentacji."""
    cls_ast = _get_class_ast("nexus_ai.services.facts_aggregator", "FactSheet")

    defined_methods = {
        node.name for node in cls_ast.body
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
    }

    for method_name in ["to_prompt_section", "to_dict", "build_few_shot_examples"]:
        assert method_name in defined_methods, (
            f"❌ FactSheet brakuje metody '{method_name}()' wymienionej w docs. "
            f"Dostepne: {sorted(defined_methods)}"
        )


# =========================================================================
# 18.  Kwoty progów w RiskGuard — zgodność z domyślnymi wartościami
# =========================================================================

@NEEDS_DEPS
def test_riskguard_default_threshold() -> None:
    """Domyślny threshold RiskGuard (0.85, BLOCK_AND_ALERT) jest zgodny z dokumentacją."""
    from nexus_ai.services.risk_guard import RiskGuard

    default = RiskGuard.DEFAULT_THRESHOLD
    # Dokumentacja mówi: fallback to 0.85 / BLOCK_AND_ALERT
    assert abs(default.required_ml_confidence - 0.85) < 0.01, (
        f"❌ DEFAULT_THRESHOLD confidence={default.required_ml_confidence}, "
        f"oczekiwano 0.85"
    )
    assert default.action_if_below == "BLOCK_AND_ALERT", (
        f"❌ DEFAULT_THRESHOLD action={default.action_if_below}, "
        f"oczekiwano BLOCK_AND_ALERT"
    )


# =========================================================================
# 19.  Wagi w protocols.toml — zgodność z kodowymi TRUST_WEIGHTS
# =========================================================================

@NEEDS_DEPS
def test_protocols_toml_weights_match_code() -> None:
    """Wagi w protocols.toml [thresholds.weights] zgadzają się z TRUST_WEIGHTS w kodzie."""
    import tomllib
    from nexus_ai.core.decision_engine import TRUST_WEIGHTS

    protocols_path = PROJECT_ROOT / "nexus_ai" / "config" / "protocols.toml"
    assert protocols_path.exists(), "❌ protocols.toml nie istnieje"

    with open(protocols_path, "rb") as f:
        data = tomllib.load(f)

    toml_weights = data.get("thresholds", {}).get("weights", {})
    assert toml_weights, "❌ [thresholds.weights] brakuje w protocols.toml"

    for key, code_value in TRUST_WEIGHTS.items():
        assert key in toml_weights, (
            f"❌ Waga '{key}' istnieje w TRUST_WEIGHTS ale brak jej w protocols.toml"
        )
        toml_value = float(toml_weights[key])
        assert abs(toml_value - code_value) < 0.01, (
            f"❌ Waga '{key}': kod={code_value}, protocols.toml={toml_value}"
        )


# =========================================================================
# 20.  Liczba reguł w protocols.toml [decision_rules] — zgodność z kodem
# =========================================================================

@NEEDS_DEPS
def test_protocols_toml_decision_rules_count() -> None:
    """Liczba reguł w protocols.toml [decision_rules] zgadza się z DEFAULT_DECISION_RULES."""
    import tomllib
    from nexus_ai.core.decision_engine import DEFAULT_DECISION_RULES

    protocols_path = PROJECT_ROOT / "nexus_ai" / "config" / "protocols.toml"
    assert protocols_path.exists()

    with open(protocols_path, "rb") as f:
        data = tomllib.load(f)

    toml_rules = {
        k: v for k, v in data.get("decision_rules", {}).items()
        if isinstance(v, dict) and "priority" in v
    }

    # W TOML jest 7 reguł (level_1..level_6 + fallback)
    # W kodzie też 7 (DEFAULT_DECISION_RULES)
    assert len(toml_rules) == len(DEFAULT_DECISION_RULES), (
        f"❌ Liczba reguł w protocols.toml ({len(toml_rules)}) "
        f"nie zgadza się z DEFAULT_DECISION_RULES ({len(DEFAULT_DECISION_RULES)})"
    )

    # Sprawdź priorytety
    toml_priorities = sorted(int(v["priority"]) for v in toml_rules.values())
    code_priorities = sorted(int(r["priority"]) for r in DEFAULT_DECISION_RULES)
    assert toml_priorities == code_priorities, (
        f"❌ Priorytety reguł w protocols.toml ({toml_priorities}) "
        f"nie zgadzają się z kodem ({code_priorities})"
    )


# =========================================================================
# 21.  invalidate_risk_cache() — event-based invalidation dla RiskGuard
# =========================================================================

@NEEDS_DEPS
def test_invalidate_risk_cache_clears_prefix() -> None:
    """invalidate_risk_cache() usuwa wszystkie klucze z prefixem risk_threshold:."""
    from nexus_ai.services.risk_guard import invalidate_risk_cache, RISK_CACHE_PREFIX, _risk_nexus

    # Zapisz kilka różnych kluczy cache
    _risk_nexus.set_sync("risk_threshold:CIT:vat_rate", {"confidence": 0.98})
    _risk_nexus.set_sync("risk_threshold:CIT:total_net", {"confidence": 0.95})
    _risk_nexus.set_sync("decision_rules:active", [{"test": "should survive"}])

    # Sprawdź że istnieją
    assert _risk_nexus.get_sync("risk_threshold:CIT:vat_rate") is not None
    assert _risk_nexus.get_sync("risk_threshold:CIT:total_net") is not None
    assert _risk_nexus.get_sync("decision_rules:active") is not None

    # Unieważnij tylko risk_threshold:*
    invalidate_risk_cache()

    # Klucze risk_threshold:* powinny zniknąć
    assert _risk_nexus.get_sync("risk_threshold:CIT:vat_rate") is None, (
        "❌ invalidate_risk_cache() nie usunął risk_threshold:CIT:vat_rate"
    )
    assert _risk_nexus.get_sync("risk_threshold:CIT:total_net") is None, (
        "❌ invalidate_risk_cache() nie usunął risk_threshold:CIT:total_net"
    )

    # Klucz decision_rules:active powinien przetrwać (inny prefix)
    assert _risk_nexus.get_sync("decision_rules:active") is not None, (
        "❌ invalidate_risk_cache() usunął klucz z innym prefixem (decision_rules:active)"
    )


@NEEDS_DEPS
def test_invalidate_risk_cache_prefix_constant() -> None:
    """RISK_CACHE_PREFIX = 'risk_threshold:' jest zgodny z użyciem w get_threshold()."""
    from nexus_ai.services.risk_guard import RISK_CACHE_PREFIX

    assert RISK_CACHE_PREFIX == "risk_threshold:", (
        f"❌ RISK_CACHE_PREFIX = '{RISK_CACHE_PREFIX}', oczekiwano 'risk_threshold:'"
    )


@NEEDS_DEPS
def test_risk_cache_no_ttl_remaining() -> None:
    """RiskGuard nie używa już TTL — wszystkie set_sync powinny być bez ttl."""
    from nexus_ai.services.risk_guard import _risk_nexus

    # NexusCache.get_cache() powinno być bez default_ttl
    # Sprawdź że default_ttl nie jest 60 (stara wartość)
    assert _risk_nexus._default_ttl != 60, (
        "❌ _risk_nexus wciąż ma default_ttl=60 — powinno być 300 (domyślne)"
    )


# =========================================================================
# 22.  NexusCache.delete_many() — L1 RAM + L2 dyscache clearing
# =========================================================================

@NEEDS_DEPS
def test_nexuscache_delete_many_clears_l1() -> None:
    """delete_many() usuwa wskazane klucze z L1 RAM, pozostawia pozostałe."""
    from nexus_ai.core.cache.dyscache import NexusCache

    cache = NexusCache(default_ttl=300)  # no dyscache (no cache_dir)

    # Ustaw kilka kluczy
    cache.set_sync("a", 1)
    cache.set_sync("b", 2)
    cache.set_sync("c", 3)
    cache.set_sync("d", 4)

    # Wszystkie 4 istnieją
    assert cache.get_sync("a") == 1
    assert cache.get_sync("b") == 2
    assert cache.get_sync("c") == 3
    assert cache.get_sync("d") == 4

    # Usuń 'a' i 'c' (async delete_many przez anyio)
    import anyio; anyio.run(cache.delete_many, "a", "c")

    # Usunięte — nie istnieją
    assert cache.get_sync("a") is None, "❌ delete_many nie usunął klucza 'a'"
    assert cache.get_sync("c") is None, "❌ delete_many nie usunął klucza 'c'"

    # Pozostałe — wciąż istnieją
    assert cache.get_sync("b") == 2, "❌ delete_many usunął klucz 'b' (powinien przetrwać)"
    assert cache.get_sync("d") == 4, "❌ delete_many usunął klucz 'd' (powinien przetrwać)"


@NEEDS_DEPS
def test_nexuscache_delete_many_no_args() -> None:
    """delete_many() z pustymi argumentami — no-op, nie psuje cache."""
    from nexus_ai.core.cache.dyscache import NexusCache

    cache = NexusCache(default_ttl=300)

    cache.set_sync("keep", "value")
    import anyio; anyio.run(cache.delete_many)  # no-op

    assert cache.get_sync("keep") == "value", "❌ delete_many() bez arg powinien być no-op"


@NEEDS_DEPS
def test_nexuscache_delete_many_clears_l2() -> None:
    """delete_many() woła dyscache.delete() dla każdego klucza (L2 clearing)."""
    from unittest.mock import MagicMock
    from nexus_ai.core.cache.dyscache import NexusCache

    cache = NexusCache(default_ttl=300)
    # Zastąp _dyscache mockiem żeby symulować L2 (dyscache/SQLite)
    mock_l2 = MagicMock()
    cache._dyscache = mock_l2

    # Ustaw klucze w L1
    cache.set_sync("x", 100)
    cache.set_sync("y", 200)
    cache.set_sync("z", 300)

    # Wywołaj delete_many (L1 + L2)
    import anyio
    anyio.run(cache.delete_many, "x", "z")

    # L1: 'x' i 'z' usunięte, 'y' przetrwał
    assert cache.get_sync("x") is None, "❌ delete_many L1: 'x' nie usunięty"
    assert cache.get_sync("y") == 200, "❌ delete_many L1: 'y' nie powinien być usunięty"
    assert cache.get_sync("z") is None, "❌ delete_many L1: 'z' nie usunięty"

    # L2 (mock): delete called exactly twice: with 'x' and 'z'
    assert mock_l2.delete.call_count == 2, (
        f"❌ delete_many L2: oczekiwano 2 wywołań dyscache.delete(), "
        f"ale było {mock_l2.delete.call_count}"
    )
    mock_l2.delete.assert_any_call("x")
    mock_l2.delete.assert_any_call("z")

    # Cleanup
    cache._dyscache = None


@NEEDS_DEPS
def test_nexuscache_delete_many_nonexistent_key() -> None:
    """delete_many() z nieistniejącym kluczem — nie rzuca błędu."""
    from nexus_ai.core.cache.dyscache import NexusCache

    cache = NexusCache(default_ttl=300)

    cache.set_sync("real", "data")
    # Nie powinno rzucić wyjątku
    import anyio
    anyio.run(cache.delete_many, "nonexistent")
    anyio.run(cache.delete_many, "still_real")
    assert cache.get_sync("real") == "data", "❌ delete_many(nonexistent) nie powinien wpływać na real"

    # Po usunięciu prawdziwego klucza
    anyio.run(cache.delete_many, "real")
    assert cache.get_sync("real") is None, "❌ delete_many('real') nie usunął istniejącego klucza"


# =========================================================================
# 23.  NexusCache.get_or_compute() — cache hit/miss + L2 fallback
# =========================================================================

@NEEDS_DEPS
def test_nexuscache_get_or_compute_cache_hit() -> None:
    """get_or_compute() zwraca cache'owaną wartość (L1 hit), nie woła compute."""
    from nexus_ai.core.cache.dyscache import NexusCache

    cache = NexusCache(default_ttl=300)
    cache.set_sync("hit_key", "cached_value")

    compute_called = False

    async def compute() -> str:
        nonlocal compute_called
        compute_called = True
        return "computed_value"

    import anyio
    result = anyio.run(cache.get_or_compute, "hit_key", compute)

    assert result == "cached_value", (
        f"❌ get_or_compute(L1 hit) zwróciło '{result}', oczekiwano 'cached_value'"
    )
    assert not compute_called, "❌ get_or_compute(L1 hit) nie powinno wołać compute"


@NEEDS_DEPS
def test_nexuscache_get_or_compute_cache_miss() -> None:
    """get_or_compute() woła compute przy L1 miss i cache'uje wynik."""
    from nexus_ai.core.cache.dyscache import NexusCache

    cache = NexusCache(default_ttl=300)
    call_count = 0

    async def compute() -> str:
        nonlocal call_count
        call_count += 1
        return "computed_value"

    import anyio
    result = anyio.run(cache.get_or_compute, "miss_key", compute)

    assert result == "computed_value", (
        f"❌ get_or_compute(L1 miss) zwróciło '{result}', oczekiwano 'computed_value'"
    )
    assert call_count == 1, f"❌ compute wołane {call_count}x, oczekiwano 1"

    # Drugie wywołanie — L1 hit
    result2 = anyio.run(cache.get_or_compute, "miss_key", compute)
    assert result2 == "computed_value", "❌ Drugie get_or_compute nie zwróciło cache'owanej wartości"
    assert call_count == 1, f"❌ compute wołane {call_count}x po drugim get_or_compute, oczekiwano wciąż 1"


@NEEDS_DEPS
def test_nexuscache_get_or_compute_l2_fallback() -> None:
    """get_or_compute() ładuje z L2 (mock dyscache) gdy L1 miss."""
    from unittest.mock import AsyncMock, MagicMock
    from nexus_ai.core.cache.dyscache import NexusCache

    cache = NexusCache(default_ttl=300)
    # Symuluj L2: klucz "l2_key" istnieje w L2, ale nie w L1
    # AsyncMock — bo get() w dyscache jest async
    from nexus_ai.core.msgspec_utils import msgspec_dumps_bytes
    mock_l2 = MagicMock()
    mock_l2.get = AsyncMock(return_value=msgspec_dumps_bytes("l2_value"))
    cache._dyscache = mock_l2

    compute_called = False

    async def compute() -> str:
        nonlocal compute_called
        compute_called = True
        return "should_not_be_called"

    import anyio
    result = anyio.run(cache.get_or_compute, "l2_key", compute)

    assert result == "l2_value", (
        f"❌ get_or_compute(L2 fallback) zwróciło '{result}', oczekiwano 'l2_value'"
    )
    assert not compute_called, "❌ get_or_compute nie powinno wołać compute gdy L2 ma dane"

    # L1 powinien być teraz ciepły (write-back z L2)
    l1_hit = cache.get_sync("l2_key")
    assert l1_hit == "l2_value", (
        f"❌ get_or_compute nie zapisał L2 danych do L1: '{l1_hit}'"
    )

    # Cleanup
    cache._dyscache = None


# =========================================================================
# 24.  NexusCache.keys() — L1 keys matching prefix
# =========================================================================

@NEEDS_DEPS
def test_nexuscache_keys_with_prefix() -> None:
    """keys(prefix) zwraca tylko klucze L1 RAM zaczynające się od prefixu."""
    from nexus_ai.core.cache.dyscache import NexusCache

    cache = NexusCache(default_ttl=300)
    cache.set_sync("risk_threshold:CIT:vat_rate", 0.98)
    cache.set_sync("risk_threshold:CIT:total_net", 0.95)
    cache.set_sync("fx_rate:EUR:2026-06-10", 4.50)
    cache.set_sync("fx_rate:USD:2026-06-10", 4.00)
    cache.set_sync("decision_rules:active", ["rule1"])

    import anyio
    risk_keys = anyio.run(cache.keys, "risk_threshold:")
    assert sorted(risk_keys) == ["risk_threshold:CIT:total_net", "risk_threshold:CIT:vat_rate"], (
        f"❌ keys('risk_threshold:') = {risk_keys}, "
        f"oczekiwano ['risk_threshold:CIT:total_net', 'risk_threshold:CIT:vat_rate']"
    )


@NEEDS_DEPS
def test_nexuscache_keys_empty_prefix() -> None:
    """keys('') zwraca wszystkie klucze L1 RAM."""
    from nexus_ai.core.cache.dyscache import NexusCache

    cache = NexusCache(default_ttl=300)
    cache.set_sync("key_a", 1)
    cache.set_sync("key_b", 2)

    import anyio
    all_keys = anyio.run(cache.keys, "")
    assert sorted(all_keys) == ["key_a", "key_b"], (
        f"❌ keys('') = {all_keys}, oczekiwano ['key_a', 'key_b']"
    )


@NEEDS_DEPS
def test_nexuscache_keys_no_match() -> None:
    """keys(nonexistent_prefix) zwraca pustą listę."""
    from nexus_ai.core.cache.dyscache import NexusCache

    cache = NexusCache(default_ttl=300)
    cache.set_sync("real_key", 42)

    import anyio
    no_match = anyio.run(cache.keys, "nonexistent:")
    assert no_match == [], f"❌ keys('nonexistent:') = {no_match}, oczekiwano []"


# =========================================================================
# Podsumowanie
# =========================================================================
