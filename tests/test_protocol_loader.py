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
        assert metadata.get("version") == "1.0"
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

    def test_matrix_has_8_combinations(self, loader: ProtocolLoader) -> None:
        """Sprawdź, że matryca ma dokładnie 8 kombinacji."""
        combinations = loader.get_decision_matrix_combinations()
        assert len(combinations) == 8

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
                    "validation_layer_timeout"}
        assert expected.issubset(set(protocols.keys()))
        assert len(protocols) == len(expected)  # nie ma nadmiarowych


# ── Testy budowania promptów ────────────────────────────────────────────

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
