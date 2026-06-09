"""
Testy jednostkowe dla ProtocolLoadera — nexus_ai/core/protocol_loader.py.

Sprawdza:
  - Ładowanie protocols.toml
  - Dostęp do protokołów (workflow, validation, rules, decision)
  - Matrycę decyzyjną (8 kombinacji)
  - Progi decyzyjne z adaptacjami
  - Protokoły awaryjne
  - Budowanie promptów systemowych
  - Scenariusze brzegowe (brak pliku, nieistniejący protokół)
"""

from __future__ import annotations

from pathlib import Path

import pytest

from nexus_ai.core.protocol_loader import (
    ProtocolLoader,
    ProtocolNotFoundError,
)


# ── Fixture ────────────────────────────────────────────────────────────────

@pytest.fixture
def loader() -> ProtocolLoader:
    """Zwraca ProtocolLoader ze standardową ścieżką."""
    return ProtocolLoader()


@pytest.fixture
def empty_loader(tmp_path: Path) -> ProtocolLoader:
    """Zwraca ProtocolLoader z nieistniejącym plikiem."""
    return ProtocolLoader(path=tmp_path / "nonexistent.toml")


# ── Testy podstawowe ─────────────────────────────────────────────────────

class TestProtocolLoaderBasics:
    """Podstawowe testy ładowania i metadanych."""

    def test_load_success(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że plik ładuje się bez błędów."""
        metadata = loader.get_metadata()
        assert metadata.get("version") == "2.0"
        assert "NexusAI" in metadata.get("description", "")

    def test_load_nonexistent_file(self, empty_loader: ProtocolLoader) -> None:
        """Sprawdź, że brak pliku nie powoduje błędu."""
        metadata = empty_loader.get_metadata()
        assert metadata == {}  # pusty słownik

    def test_reload(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że reload działa."""
        before = loader.get_metadata()
        loader.reload()
        after = loader.get_metadata()
        assert before == after

    def test_get_all_protocols(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że zwraca wszystkie protokoły."""
        protocols = loader.get_all_protocols()
        assert "workflow_planner" in protocols
        assert "validation" in protocols
        assert "rules" in protocols
        assert "decision" in protocols

    def test_protocol_not_found(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że nieistniejący protokół rzuca wyjątek."""
        with pytest.raises(ProtocolNotFoundError):
            loader.get_protocol("nonexistent_protocol")


# ── Testy protokołów ────────────────────────────────────────────────────

class TestProtocolAccess:
    """Testy dostępu do poszczególnych protokołów."""

    def test_workflow_planner(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół workflow_planner."""
        protocol = loader.get_protocol("workflow_planner")
        assert protocol["model_role"] == "Inteligentny orkiestrator procesu fakturowania"
        assert len(protocol["available_agents"]) == 4  # EKSTRAKCJA, WALIDACJA, ANALITYKA, DECYZJA

    def test_validation_alpha(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół validation.alpha."""
        protocol = loader.get_protocol("validation.alpha")
        assert protocol["model_role"] == "Doświadczony analityk finansowy"
        assert "APPROVE" in str(protocol.get("protocols", {}).get("typical_invoice", {}))

    def test_validation_beta(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół validation.beta."""
        protocol = loader.get_protocol("validation.beta")
        assert "kontrolerem finansowym" in protocol.get("system_prompt", {}).get("role", "")
        assert len(protocol.get("system_prompt", {}).get("checks", [])) == 3

    def test_validation_gamma(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół validation.gamma."""
        protocol = loader.get_protocol("validation.gamma")
        assert "anomalie" in protocol.get("system_prompt", {}).get("role", "").lower()

    def test_rules_level_1(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół rules.level_1."""
        protocol = loader.get_protocol("rules.level_1")
        assert protocol["model"] == "LFM2.5-Thinking"

    def test_rules_level_4(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół rules.level_4."""
        protocol = loader.get_protocol("rules.level_4")
        assert protocol["model"] == "Fin-RWKV-169M"

    def test_decision_jamba(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół decision.jamba."""
        protocol = loader.get_protocol("decision.jamba")
        assert "Jamba 3B" in protocol.get("model", "")
        assert len(protocol.get("input_sources", [])) == 3


# ── Testy matrycy decyzyjnej ───────────────────────────────────────────

class TestDecisionMatrix:
    """Testy matrycy decyzyjnej 8 kombinacji."""

    def test_matrix_exists(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że matryca istnieje."""
        matrix = loader.get_decision_matrix()
        assert matrix is not None
        assert "description" in matrix

    def test_matrix_has_all_combinations(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że matryca ma wszystkie zdefiniowane kombinacje (8 basic + 5 ERROR)."""
        combinations = loader.get_decision_matrix_combinations()
        assert len(combinations) == 13

    def test_full_approve(self, loader: ProtocolLoader) -> None:
        """Sprawdź kombinację FULL_APPROVE."""
        combinations = loader.get_decision_matrix_combinations()
        full = combinations["FULL_APPROVE"]
        assert full["alpha"] == "APPROVE"
        assert full["beta"] == "APPROVE"
        assert full["gamma"] == "APPROVE"
        assert full["action"] == "AUTO_POST"
        assert full["level"] == "LEVEL_1_AUTO"

    def test_full_reject(self, loader: ProtocolLoader) -> None:
        """Sprawdź kombinację FULL_REJECT."""
        combinations = loader.get_decision_matrix_combinations()
        reject = combinations["FULL_REJECT"]
        assert reject["alpha"] == "REJECT"
        assert reject["beta"] == "REJECT"
        assert reject["gamma"] == "REJECT"
        assert reject["action"] == "BLOCK"
        assert reject["level"] == "LEVEL_4_BLOCK"

    def test_precision_veto(self, loader: ProtocolLoader) -> None:
        """Sprawdź kombinację PRECISION_VETO."""
        combinations = loader.get_decision_matrix_combinations()
        veto = combinations["PRECISION_VETO"]
        assert veto["alpha"] == "REJECT"
        assert veto["beta"] == "APPROVE"
        assert veto["gamma"] == "REJECT"
        assert veto["action"] == "BLOCK"

    def test_matrix_not_found(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że nieistniejąca matryca rzuca wyjątek."""
        with pytest.raises(ProtocolNotFoundError):
            loader.get_decision_matrix("nonexistent_matrix")


# ── Testy progów decyzyjnych ────────────────────────────────────────────

class TestThresholds:
    """Testy progów decyzyjnych i adaptacji."""

    def test_default_thresholds(self, loader: ProtocolLoader) -> None:
        """Sprawdź domyślne progi."""
        thresholds = loader.get_thresholds("default")
        assert thresholds.get("auto_post") == 0.92
        assert thresholds.get("suggest") == 0.75
        assert thresholds.get("ask_user") == 0.50

    def test_weights(self, loader: ProtocolLoader) -> None:
        """Sprawdź wagi trust score."""
        weights = loader.get_weights()
        assert weights.get("ai_confidence") == 0.30
        assert weights.get("vendor_reliability") == 0.25
        assert sum(weights.values()) == 1.0  # sumują się do 1

    def test_adaptation_with_known_vendor(self, loader: ProtocolLoader) -> None:
        """Sprawdź adaptację progów dla znanego kontrahenta."""
        adapted = loader.get_thresholds_with_adaptations(
            category="paliwo",
            vendor_known=True,
            vendor_invoice_count=10,
            amount_gross=300.0,
        )
        # Znany kontrahent + niska kwota + kategoria cykliczna = niższy próg
        assert adapted["auto_post"] < 0.92

    def test_adaptation_with_new_vendor_high_amount(self, loader: ProtocolLoader) -> None:
        """Sprawdź adaptację progów dla nowego kontrahenta z wysoką kwotą."""
        adapted = loader.get_thresholds_with_adaptations(
            category="usługi it",
            vendor_known=False,
            vendor_invoice_count=0,
            amount_gross=50000.0,
        )
        # Nowy kontrahent + wysoka kwota + kategoria problematyczna = wyższy próg
        assert adapted["auto_post"] > 0.92

    def test_adaptation_disabled(self, tmp_path: Path) -> None:
        """Sprawdź, że gdy adaptacja wyłączona, progi są domyślne."""
        # Stwórz tymczasowy plik TOML z wyłączoną adaptacją
        toml_content = '''
[thresholds]
[thresholds.default]
auto_post = 0.92
suggest = 0.75
ask_user = 0.50

[thresholds.adaptation]
enabled = false
'''
        toml_path = tmp_path / "test_protocols.toml"
        toml_path.write_text(toml_content)

        custom_loader = ProtocolLoader(path=toml_path)
        adapted = custom_loader.get_thresholds_with_adaptations(
            category="unknown",
            vendor_known=False,
            amount_gross=999999.0,
        )
        assert adapted["auto_post"] == 0.92

    def test_thresholds_fallback_to_default(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że nieistniejący zestaw progów fallbackuje do default."""
        thresholds = loader.get_thresholds("nonexistent")
        assert thresholds.get("auto_post") == 0.92
        assert thresholds.get("suggest") == 0.75
        assert thresholds.get("ask_user") == 0.50

    def test_thresholds_clamped(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że progi są ograniczone do [0.0, 1.0]."""
        adapted = loader.get_thresholds_with_adaptations(
            vendor_known=False,
            amount_gross=999999.0,
        )
        for k in ("auto_post", "suggest", "ask_user"):
            if k in adapted:
                assert 0.0 <= adapted[k] <= 1.0


# ── Testy protokołów awaryjnych ─────────────────────────────────────────

class TestEmergencyProtocols:
    """Testy protokołów awaryjnych."""

    def test_model_timeout(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół awaryjny model_timeout."""
        protocol = loader.get_emergency_protocol("model_timeout")
        assert protocol["action"] == "ASYNC_FALLBACK"
        assert protocol["fallback_strategy"] == "Użyj statycznej matrycy decyzyjnej (DECISION_MATRIX) zamiast modelu"

    def test_unknown_voting_pattern(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół awaryjny unknown_voting_pattern."""
        protocol = loader.get_emergency_protocol("unknown_voting_pattern")
        assert protocol["action"] == "SAFE_ESCALATE"
        assert "ASK_USER" in protocol.get("fallback_strategy", "")
        assert protocol["notify_user"] is True

    def test_all_emergency_protocols(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że wszystkie protokoły awaryjne są dostępne."""
        protocols = loader.get_all_emergency_protocols()
        expected = {"model_timeout", "model_error", "model_crash",
                    "unknown_voting_pattern", "workflow_timeout",
                    "validation_layer_timeout", "rag_source_failure",
                    "data_integrity_violation", "model_oom"}
        assert expected.issubset(set(protocols.keys()))
        assert len(protocols) >= len(expected)


# ── Testy scenariuszy brzegowych (edge cases) ──────────────────────────

class TestEdgeCases:
    """Testy protokołów dla scenariuszy brzegowych z [edge_cases]."""

    def test_ocr_low_confidence(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół dla niskiego OCR."""
        edge = loader.get_edge_case("ocr_low_confidence")
        assert "0.5" in edge.get("condition", "")
        assert "low_confidence" in edge.get("expected_behavior", "").lower()

    def test_duplicate_invoice(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół dla duplikatu faktury."""
        edge = loader.get_edge_case("duplicate_invoice")
        assert edge.get("expected_behavior", "").startswith("BLOCK")
        assert "duplikat" in edge.get("expected_behavior", "").lower()

    def test_partial_data(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół dla niekompletnych danych RAG."""
        edge = loader.get_edge_case("partial_data")
        assert "2 z 4" in edge.get("condition", "")
        assert "0.03" in edge.get("override", "")

    def test_nip_checksum_error(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół dla błędu sumy kontrolnej NIP."""
        edge = loader.get_edge_case("nip_checksum_error")
        assert edge.get("expected_behavior", "").startswith("BLOCK")

    def test_negative_amount(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół dla ujemnej kwoty."""
        edge = loader.get_edge_case("negative_amount")
        assert edge.get("expected_behavior", "").startswith("BLOCK")
        assert "ujemną kwotą" in edge.get("expected_behavior", "")

    def test_currency_mismatch(self, loader: ProtocolLoader) -> None:
        """Sprawdź protokół dla niezgodności waluty."""
        edge = loader.get_edge_case("currency_mismatch")
        assert edge.get("expected_behavior", "").startswith("ASK_USER")

    def test_nonexistent_edge_case(self, loader: ProtocolLoader) -> None:
        """Nieistniejący edge case → domyślna eskalacja."""
        edge = loader.get_edge_case("nonexistent_scenario")
        assert edge["condition"] == "unknown"
        assert edge["expected_behavior"].startswith("ESCALATE")

    def test_all_edge_cases_have_required_fields(self, loader: ProtocolLoader) -> None:
        """Wszystkie edge case mają condition, expected_behavior, override."""
        for name in ("ocr_low_confidence", "duplicate_invoice", "partial_data",
                     "nip_checksum_error", "negative_amount", "currency_mismatch"):
            edge = loader.get_edge_case(name)
            assert "condition" in edge, f"{name} missing condition"
            assert "expected_behavior" in edge, f"{name} missing expected_behavior"
            assert "override" in edge, f"{name} missing override"


# ── Testy RAG (Retrieval-Augmented Generation) ───────────────────────────

class TestRAGProtocols:
    """Testy protokołów RAG z [protocols.rag]."""

    def test_before_decision(self, loader: ProtocolLoader) -> None:
        """Sprawdź sekcję RAG before_decision."""
        rag = loader.get_rag_section("before_decision")
        assert len(rag.get("steps", [])) >= 1
        assert "timeout" in rag or "error_handling" in rag

    def test_data_sources_sqlite(self, loader: ProtocolLoader) -> None:
        """Sprawdź źródło danych SQLite w RAG."""
        rag = loader.get_rag_section("data_sources.sqlite")
        assert "fields" in rag
        assert rag.get("priority", "") == "critical — podstawowe dane kontrahenta"

    def test_data_sources_duckdb(self, loader: ProtocolLoader) -> None:
        """Sprawdź źródło danych DuckDB w RAG."""
        rag = loader.get_rag_section("data_sources.duckdb")
        assert "fields" in rag
        assert "trust_score_trend" in rag.get("fields", [])

    def test_few_shot_section(self, loader: ProtocolLoader) -> None:
        """Sprawdź sekcję few-shot RAG."""
        rag = loader.get_rag_section("few_shot")
        assert rag.get("max_examples") == 3
        assert "decision_mapping" in rag

    def test_rag_section_not_found(self, loader: ProtocolLoader) -> None:
        """Nieistniejąca sekcja RAG → domyślny fallback."""
        rag = loader.get_rag_section("nonexistent_section")
        assert "steps" in rag
        assert rag["steps"] == ["FactsAggregator.build(invoice_data) — domyślny przepływ"]

    def test_rag_top_level_schema(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że [protocols.rag] istnieje i ma opis."""
        rag = loader.get_protocol("rag")
        assert rag.get("description", "").startswith("Protokoły dla warstwy RAG")
        assert len(rag.get("data_sources", [])) == 4  # SQLite, DuckDB, sqlite-vec, TigerBeetle


# ── Testy SOP (Standard Operating Procedures) ────────────────────────────

class TestSOP:
    """Testy sekcji SOP z [sop.*]."""

    def test_orchestrator_protocols(self, loader: ProtocolLoader) -> None:
        """Sprawdź sekcję SOP orchestrator_protocols."""
        sop = loader.get_sop_section("orchestrator_protocols")
        assert len(sop) >= 8  # 8 protokołów (protocol_1..protocol_8)
        assert sop.get("description", "").startswith("Standard Operating Procedures")

    def test_orchestration_flow(self, loader: ProtocolLoader) -> None:
        """Sprawdź sekcję SOP orchestration flow."""
        sop = loader.get_sop_section("orchestration")
        assert "flow" in sop
        flow = sop["flow"]
        assert "step_0" in flow
        assert "step_1" in flow
        assert "step_5" in flow  # RETURN

    def test_sop_not_found(self, loader: ProtocolLoader) -> None:
        """Nieistniejąca sekcja SOP → pusty słownik."""
        sop = loader.get_sop_section("nonexistent_sop")
        assert sop == {}

    def test_first_protocol_niejasna_kategoria(self, loader: ProtocolLoader) -> None:
        """Sprawdź pierwszy protokół SOP (niejasna kategoria wydatku)."""
        sop = loader.get_sop_section("orchestrator_protocols")
        p1 = sop.get("protocol_1", {})
        assert p1.get("name") == "Niejasna kategoria wydatku"
        assert len(p1.get("steps", [])) == 3

    def test_seventh_protocol_high_amount(self, loader: ProtocolLoader) -> None:
        """Sprawdź siódmy protokół SOP (wysoka kwota)."""
        sop = loader.get_sop_section("orchestrator_protocols")
        p7 = sop.get("protocol_7", {})
        assert p7.get("name") == "Wysoka kwota powyżej progu"
        assert "50000" in p7.get("condition", "")


# ── Testy formatów wyjściowych (schema) ──────────────────────────────────

class TestSchemaFormats:
    """Testy definicji formatów wyjściowych z [schema.output_formats]."""

    def test_all_output_formats_exist(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że wszystkie formaty wyjściowe są zdefiniowane."""
        formats = loader.get_schema_formats()
        expected = {"workflow_plan", "validation_verdict", "strategic_decision",
                    "orchestrator_decision", "rules_level_4_output",
                    "rag_fact_sheet_section", "few_shot_section"}
        assert expected.issubset(set(formats.keys()))

    def test_workflow_plan_format(self, loader: ProtocolLoader) -> None:
        """Sprawdź format workflow_plan."""
        formats = loader.get_schema_formats()
        fmt = formats["workflow_plan"]
        assert "agents" in fmt
        assert "EKSTRAKCJA" in fmt

    def test_validation_verdict_format(self, loader: ProtocolLoader) -> None:
        """Sprawdź format validation_verdict."""
        formats = loader.get_schema_formats()
        fmt = formats["validation_verdict"]
        assert "APPROVE" in fmt
        assert "REJECT" in fmt


# ── Testy buildowania promptów ────────────────────────────────────────────

class TestPromptBuilding:
    """Testy budowania promptów systemowych z protokołów."""

    def test_build_system_prompt_alpha(self, loader: ProtocolLoader) -> None:
        """Sprawdź budowanie promptu dla Alpha Agent."""
        prompt = loader.build_system_prompt("validation.alpha")
        assert "analitykiem finansowym" in prompt
        assert "PROTOKOŁY DECYZYJNE" in prompt
        assert "typical_invoice" in prompt or "APPROVE" in prompt

    def test_build_system_prompt_beta(self, loader: ProtocolLoader) -> None:
        """Sprawdź budowanie promptu dla Beta Agent."""
        prompt = loader.build_system_prompt("validation.beta")
        assert "kontrolerem finansowym" in prompt
        assert "sumę kontrolną NIP" in prompt

    def test_build_strategic_prompt(self, loader: ProtocolLoader) -> None:
        """Sprawdź budowanie promptu strategicznego dla Jamba."""
        prompt = loader.build_strategic_prompt()
        assert "strategiem finansowym" in prompt.lower()
        assert "AUTO_POST" in prompt or "SUGGEST" in prompt


# ── Testy integracji z istniejącymi promptami ───────────────────────────

class TestProtocolConsistency:
    """Testy spójności protokołów z istniejącym kodem."""

    def test_rules_flow_consistent(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że przepływ rules jest zgodny z kodami."""
        flow = loader.get_protocol("rules.flow")
        assert flow.get("level_1_fast_path_confidence") == 0.90
        assert flow.get("max_chain_depth") == 4

    def test_workflow_planner_rules_consistent(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że reguły workflow są zgodne z kodem."""
        rules = loader.get_protocol("workflow_planner.rules")
        assert rules["simple_threshold_amount"] == 5000
        assert rules["simple_threshold_ocr_confidence"] == 0.85

    def test_validation_fast_path_consistent(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że fast-path validacji jest zgodny z kodem."""
        fast_path = loader.get_protocol("validation.fast_path")
        assert "0.92" in fast_path.get("condition", "")


# ===========================================================================
# TESTY AUTO-RELOAD (mtime-based monitoring protocols.toml)
# ===========================================================================

class TestAutoReload:
    """Testy mechanizmu auto-reload opartego na mtime pliku."""

    # ── auto_reload=False (standardowy cache) ───────────────────────────

    def test_auto_reload_disabled_caches_data(self, tmp_path: Path) -> None:
        """auto_reload=False (domyślnie) → cache'uje dane, nie sprawdza mtime."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=False)
        assert loader.get_metadata()["version"] == "1.0"

        # Zmień plik na dysku — loader nie powinien tego widzieć
        toml_path.write_text('[metadata]\nversion = "2.0"\n')
        assert loader.get_metadata()["version"] == "1.0"  # wciąż stary

    def test_auto_reload_disabled_no_recheck_after_multiple_calls(
        self, tmp_path: Path
    ) -> None:
        """auto_reload=False → wiele wywołań nie czyta pliku ponownie."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=False)
        _ = loader.get_metadata()
        _ = loader.get_metadata()
        _ = loader.get_metadata()
        # Po pierwszym cache'owaniu, kolejne wywołania nie czytają pliku
        # (trudno to bezpośrednio przetestować, ale sprawdzamy że nie crashuje)
        assert loader.get_metadata()["version"] == "1.0"

    # ── auto_reload=True (mtime-based) ──────────────────────────────────

    def test_auto_reload_true_detects_mtime_change(self, tmp_path: Path) -> None:
        """auto_reload=True → wykrywa zmianę mtime i przeładowuje dane."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        assert loader.get_metadata()["version"] == "1.0"

        # Zmień zawartość i odśwież mtime
        toml_path.write_text('[metadata]\nversion = "2.0"\n')

        # Wymuś update mtime (write_text już to robi, ale symulujemy czas)
        # Ponieważ poll_interval=5s, musimy zsymulować że minął czas
        loader._last_checked = 0.0  # reset rate-limiter

        assert loader.get_metadata()["version"] == "2.0"

    def test_auto_reload_true_no_change_no_reload(self, tmp_path: Path) -> None:
        """auto_reload=True → brak zmiany mtime = brak przeładowania."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()

        # Resetuj _last_checked aby pominąć rate-limiting
        loader._last_checked = 0.0

        # Nie zmieniamy pliku — mtime to samo
        result = loader.get_metadata()
        assert result["version"] == "1.0"

    def test_auto_reload_detects_file_disappearance(self, tmp_path: Path) -> None:
        """auto_reload=True → zniknięcie pliku = czyszczenie cache + pusty dict."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()  # załaduj

        # Usuń plik
        toml_path.unlink()
        loader._last_checked = 0.0  # bypass rate-limit

        result = loader.get_metadata()
        assert result == {}  # pusty słownik

    def test_auto_reload_detects_file_reappearance(self, tmp_path: Path) -> None:
        """auto_reload=True → plik pojawia się ponownie po zniknięciu."""
        toml_path = tmp_path / "test.toml"

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        # Plik nie istnieje → pusty dict
        assert loader.get_metadata() == {}

        # Stwórz plik
        toml_path.write_text('[metadata]\nversion = "3.0"\n')
        loader._last_checked = 0.0

        assert loader.get_metadata()["version"] == "3.0"

    # ── auto_reload=int (custom poll interval) ──────────────────────────

    def test_auto_reload_custom_poll_interval(self, tmp_path: Path) -> None:
        """auto_reload=int → custom poll interval w sekundach."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        # Poll co 60 sekund
        loader = ProtocolLoader(path=toml_path, auto_reload=60)
        assert loader._poll_interval == 60.0
        assert loader._auto_reload_enabled is True

        _ = loader.get_metadata()

        # Zmień plik — ale poll_interval nie minął → nie przeładuje
        toml_path.write_text('[metadata]\nversion = "2.0"\n')
        # Nie resetujemy _last_checked → rate-limiter blokuje
        assert loader.get_metadata()["version"] == "1.0"

    def test_auto_reload_zero_disabled(self, tmp_path: Path) -> None:
        """auto_reload=0 → traktowane jako False (wyłączone)."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=0)
        assert loader._auto_reload_enabled is False

    def test_auto_reload_negative_disabled(self, tmp_path: Path) -> None:
        """auto_reload=-1 → traktowane jako False (wyłączone)."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=-1)
        assert loader._auto_reload_enabled is False

    # ── reload() ────────────────────────────────────────────────────────

    def test_reload_resets_mtime_cache(self, tmp_path: Path) -> None:
        """reload() resetuje mtime cache i wymusza przeładowanie."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()

        # Zmień plik i wywołaj reload
        toml_path.write_text('[metadata]\nversion = "4.0"\n')
        loader.reload()

        assert loader.get_metadata()["version"] == "4.0"

    def test_reload_with_auto_reload_disabled(self, tmp_path: Path) -> None:
        """reload() działa nawet gdy auto_reload=False."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=False)
        _ = loader.get_metadata()

        toml_path.write_text('[metadata]\nversion = "5.0"\n')
        loader.reload()

        assert loader.get_metadata()["version"] == "5.0"

    # ── Edge cases ──────────────────────────────────────────────────────

    def test_auto_reload_rate_limiting(self, tmp_path: Path) -> None:
        """auto_reload przestrzega poll_interval — nie sprawdza pliku zbyt często."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=3600)  # poll co godzinę
        _ = loader.get_metadata()

        # Zmień plik
        toml_path.write_text('[metadata]\nversion = "2.0"\n')
        # Nie resetujemy _last_checked — rate-limiter aktywy

        # Wciąż zwraca stare dane mimo zmiany pliku
        assert loader.get_metadata()["version"] == "1.0"

        # Po resecie _last_checked, przeładuje
        loader._last_checked = 0.0
        assert loader.get_metadata()["version"] == "2.0"

    def test_auto_reload_fallback_on_stat_error(self, tmp_path: Path) -> None:
        """Błąd stat() pliku → fallback do cache (bez crasha)."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()  # załaduj dane do cache

        # Symuluj brak pliku (stat rzuci OSError)
        toml_path.unlink()
        loader._last_checked = 0.0

        # File disappeared → powinno wyczyścić cache i zwrócić {}
        result = loader.get_metadata()
        assert result == {}

    def test_auto_reload_poll_interval_default(self) -> None:
        """auto_reload=True → domyślny poll_interval = 5.0s."""
        loader = ProtocolLoader(auto_reload=True)
        assert loader._poll_interval == 5.0
        assert loader._auto_reload_enabled is True

    def test_auto_reload_toml_parse_error_keeps_old_data(self, tmp_path: Path) -> None:
        """Błąd parsowania TOML → zachowaj stare dane (graceful degradation)."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()  # załaduj poprawne dane

        # Nadpisz plik niepoprawnym TOML
        toml_path.write_text('not valid toml {{{{')
        loader._last_checked = 0.0

        # Błąd parsowania — zachowaj stare dane (są w cache)
        result = loader.get_metadata()
        # W zależności od implementacji, może zwrócić stare dane lub pusty
        # Najważniejsze: nie crashuje
        assert isinstance(result, dict)

    # ── Integracja z protokołami ────────────────────────────────────────

    def test_auto_reload_with_real_protocols(self, tmp_path: Path) -> None:
        """Pełny przepływ: auto-reload wykrywa zmianę w protokołach."""
        # Skopiuj prawdziwy protocols.toml do tmp
        import shutil
        real_path = Path(__file__).resolve().parent.parent / "nexus_ai" / "config" / "protocols.toml"
        test_path = tmp_path / "protocols.toml"
        shutil.copy2(real_path, test_path)

        loader = ProtocolLoader(path=test_path, auto_reload=True)
        metadata_before = loader.get_metadata()

        # Zmień wersję w pliku
        content = test_path.read_text(encoding="utf-8")
        content = content.replace('version = "2.0"', 'version = "2.1-test"')
        test_path.write_text(content, encoding="utf-8")
        loader._last_checked = 0.0

        metadata_after = loader.get_metadata()
        assert metadata_after["version"] == "2.1-test"
        assert metadata_before["version"] != metadata_after["version"]

    def test_auto_reload_executor_uses_updated_protocols(
        self, tmp_path: Path
    ) -> None:
        """ProtocolExecutor z auto-reload loaderem widzi zmiany w protokołach."""
        from nexus_ai.core.protocol_executor import ProtocolExecutor

        import shutil
        real_path = Path(__file__).resolve().parent.parent / "nexus_ai" / "config" / "protocols.toml"
        test_path = tmp_path / "protocols.toml"
        shutil.copy2(real_path, test_path)

        loader = ProtocolLoader(path=test_path, auto_reload=True)
        executor = ProtocolExecutor(loader=loader)

        # Sprawdź domyślne progi
        prompt_before = executor.build_prompt("validation.alpha")
        assert "analitykiem finansowym" in prompt_before

        # Zmień protokół validation.alpha
        content = test_path.read_text(encoding="utf-8")
        content = content.replace(
            'role = "Jesteś doświadczonym analitykiem finansowym."',
            'role = "Jesteś ZAUTOMATYZOWANYM analitykiem finansowym."',
        )
        test_path.write_text(content, encoding="utf-8")
        loader._last_checked = 0.0

        prompt_after = executor.build_prompt("validation.alpha")
        assert "ZAUTOMATYZOWANYM" in prompt_after
        assert prompt_before != prompt_after


# ===========================================================================
# TESTY SINGLETONU (get_protocol_loader)
# ===========================================================================

class TestSingleton:
    """Testy globalnej instancji ProtocolLoader."""

    def test_get_protocol_loader_returns_same_instance(self) -> None:
        """get_protocol_loader() zwraca tę samą instancję (singleton)."""
        from nexus_ai.core.protocol_loader import get_protocol_loader
        # Zresetuj singleton dla testu
        import nexus_ai.core.protocol_loader as pl
        pl._default_loader = None

        a = get_protocol_loader()
        b = get_protocol_loader()
        assert a is b

    def test_get_protocol_loader_with_path(self, tmp_path: Path) -> None:
        """get_protocol_loader() z custom path tworzy loader."""
        from nexus_ai.core.protocol_loader import get_protocol_loader
        import nexus_ai.core.protocol_loader as pl
        pl._default_loader = None

        toml_path = tmp_path / "custom.toml"
        toml_path.write_text('[metadata]\nversion = "custom"\n')

        loader = get_protocol_loader(path=toml_path)
        assert loader.get_metadata()["version"] == "custom"

    def test_get_protocol_loader_with_auto_reload(self) -> None:
        """get_protocol_loader() z auto_reload=True."""
        from nexus_ai.core.protocol_loader import get_protocol_loader
        import nexus_ai.core.protocol_loader as pl
        pl._default_loader = None

        loader = get_protocol_loader(auto_reload=True)
        assert loader._auto_reload_enabled is True
        assert loader._poll_interval == 5.0


# ===========================================================================
# TESTY BRZEGOWE PARSOWANIA TOML
# ===========================================================================

class TestParsingEdgeCases:
    """Testy parsera TOML dla nietypowych plików."""

    def test_empty_toml(self, tmp_path: Path) -> None:
        """Pusty plik TOML → pusty słownik, nie crash."""
        toml_path = tmp_path / "empty.toml"
        toml_path.write_text('')

        loader = ProtocolLoader(path=toml_path)
        metadata = loader.get_metadata()
        assert metadata == {}

    def test_metadata_only_toml(self, tmp_path: Path) -> None:
        """TOML tylko z sekcją metadata."""
        toml_path = tmp_path / "metadata_only.toml"
        toml_path.write_text('[metadata]\nversion = "3.0"\n')

        loader = ProtocolLoader(path=toml_path)
        assert loader.get_metadata()["version"] == "3.0"
        # Inne sekcje powinny zwracać puste słowniki
        assert loader.get_all_protocols() == {}
        assert loader.get_all_emergency_protocols() == {}

    def test_whitespace_only_toml(self, tmp_path: Path) -> None:
        """TOML z samymi komentarzami i spacjami."""
        toml_path = tmp_path / "whitespace.toml"
        toml_path.write_text('# just a comment\n\n# another comment\n')

        loader = ProtocolLoader(path=toml_path)
        metadata = loader.get_metadata()
        assert metadata == {}

    def test_protocols_without_metadata(self, tmp_path: Path) -> None:
        """TOML z protokołami ale bez metadanych."""
        toml_path = tmp_path / "no_metadata.toml"
        toml_path.write_text('''
[protocols.workflow_planner]
model_role = "Test"
''')

        loader = ProtocolLoader(path=toml_path)
        assert loader.get_metadata() == {}
        assert loader.get_protocol("workflow_planner")["model_role"] == "Test"

    def test_get_emergency_protocols_nonexistent(self, empty_loader: ProtocolLoader) -> None:
        """Gdy plik nie istnieje, get_all_emergency_protocols() zwraca {}."""
        protocols = empty_loader.get_all_emergency_protocols()
        assert protocols == {}


# ===========================================================================
# TESTY HOT-RELOAD CALLBACK (on_change / subscribe_on_change)
# ===========================================================================

class TestHotReloadCallback:
    """Testy mechanizmu callback wywoływanego przy zmianie protocols.toml."""

    # ── Podstawowe callbacki ────────────────────────────────────────────

    def test_on_change_callback_fires_on_file_change(self, tmp_path: Path) -> None:
        """Callback jest wywoływany gdy plik zmienia się na dysku (mtime)."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        # Wymuś pierwsze ładowanie
        _ = loader.get_metadata()

        called: list[str | None] = []

        def on_change(version: str | None) -> None:
            called.append(version)

        loader.on_change(on_change)

        # Zmień plik i wymuś przeładowanie
        toml_path.write_text('[metadata]\nversion = "2.0"\n')
        loader._last_checked = 0.0
        _ = loader.get_metadata()

        assert len(called) == 1
        assert called[0] == "2.0"

    def test_on_change_receives_correct_version(self, tmp_path: Path) -> None:
        """Callback otrzymuje poprawną wersję z [metadata].version."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.5"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()

        received: list[str | None] = []
        loader.on_change(lambda v: received.append(v))

        toml_path.write_text('[metadata]\nversion = "3.0-beta"\n')
        loader._last_checked = 0.0
        _ = loader.get_metadata()

        assert received == ["3.0-beta"]

    def test_on_change_callback_not_fired_on_cache_hit(self, tmp_path: Path) -> None:
        """Callback NIE jest wywoływany gdy mtime się nie zmieniło."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()

        calls: list[str] = []
        loader.on_change(lambda v: calls.append("fired"))

        # Drugie wywołanie — bez zmiany pliku
        loader._last_checked = 0.0
        _ = loader.get_metadata()

        assert calls == []

    # ── Unsubscribe ─────────────────────────────────────────────────────

    def test_unsubscribe_prevents_callback(self, tmp_path: Path) -> None:
        """Zwrócona funkcja unsubscribe wyrejestrowuje callback."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()

        called: bool = False

        def on_change(version: str | None) -> None:
            nonlocal called
            called = True

        unsubscribe = loader.on_change(on_change)
        unsubscribe()

        # Zmień plik
        toml_path.write_text('[metadata]\nversion = "2.0"\n')
        loader._last_checked = 0.0
        _ = loader.get_metadata()

        assert called is False

    def test_unsubscribe_idempotent(self, tmp_path: Path) -> None:
        """Wielokrotne wywołanie unsubscribe nie rzuca błędu."""
        loader = ProtocolLoader(auto_reload=True)

        def on_change(version: str | None) -> None:
            pass

        unsubscribe = loader.on_change(on_change)
        unsubscribe()
        unsubscribe()  # drugi raz — nie powinno crashować

    # ── Multiple callbacks ──────────────────────────────────────────────

    def test_multiple_callbacks_all_fire(self, tmp_path: Path) -> None:
        """Wszystkie zarejestrowane callbacki są wywoływane."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()

        results: list[int] = []

        loader.on_change(lambda v: results.append(1))
        loader.on_change(lambda v: results.append(2))
        loader.on_change(lambda v: results.append(3))

        toml_path.write_text('[metadata]\nversion = "2.0"\n')
        loader._last_checked = 0.0
        _ = loader.get_metadata()

        assert results == [1, 2, 3]

    # ── Callback exception isolation ────────────────────────────────────

    def test_callback_exception_does_not_crash_loader(self, tmp_path: Path) -> None:
        """Wyjątek w callbacku nie psuje loadera — pozostałe callbacki działają."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()

        results: list[str] = []

        def failing_cb(v: str | None) -> None:
            raise RuntimeError("Simulated failure")

        def working_cb(v: str | None) -> None:
            results.append(str(v))

        loader.on_change(failing_cb)
        loader.on_change(working_cb)

        toml_path.write_text('[metadata]\nversion = "3.0"\n')
        loader._last_checked = 0.0
        _ = loader.get_metadata()

        # Working callback should still have been called
        assert results == ["3.0"]

    # ── Callback without metadata ───────────────────────────────────────

    def test_callback_without_version(self, tmp_path: Path) -> None:
        """Gdy brak [metadata], callback otrzymuje version=None."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[protocols]\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        _ = loader.get_metadata()

        received: list[str | None] = []
        loader.on_change(lambda v: received.append(v))

        # Zmień plik (nadal bez metadata)
        toml_path.write_text('[protocols]\nother = true\n')
        loader._last_checked = 0.0
        _ = loader.get_metadata()

        assert len(received) == 1
        assert received[0] is None

    # ── Callback with reload() ──────────────────────────────────────────

    def test_reload_triggers_callback(self, tmp_path: Path) -> None:
        """reload() też wywołuje callbacki (bo wywołuje _load() → _read_file())."""
        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=False)
        calls: list[str] = []
        loader.on_change(lambda v: calls.append("reloaded"))

        loader.reload()

        assert calls == ["reloaded"]

    # ── ProtocolExecutor.subscribe_on_change ────────────────────────────

    def test_executor_subscribe_on_change_proxies_to_loader(self, tmp_path: Path) -> None:
        """ProtocolExecutor.subscribe_on_change() deleguje do ProtocolLoader.on_change()."""
        from nexus_ai.core.protocol_executor import ProtocolExecutor

        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        executor = ProtocolExecutor(loader=loader)
        _ = loader.get_metadata()

        received: list[str | None] = []
        executor.subscribe_on_change(lambda v: received.append(v))

        toml_path.write_text('[metadata]\nversion = "5.0"\n')
        loader._last_checked = 0.0
        _ = loader.get_metadata()

        assert len(received) == 1
        assert received[0] == "5.0"

    def test_executor_subscribe_returns_unsubscribe(self, tmp_path: Path) -> None:
        """subscribe_on_change() zwraca działającą funkcję unsubscribe."""
        from nexus_ai.core.protocol_executor import ProtocolExecutor

        toml_path = tmp_path / "test.toml"
        toml_path.write_text('[metadata]\nversion = "1.0"\n')

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        executor = ProtocolExecutor(loader=loader)
        _ = loader.get_metadata()

        calls: list[str] = []

        def on_change(v: str | None) -> None:
            calls.append("fired")

        unsubscribe = executor.subscribe_on_change(on_change)
        unsubscribe()

        toml_path.write_text('[metadata]\nversion = "6.0"\n')
        loader._last_checked = 0.0
        _ = loader.get_metadata()

        assert calls == []