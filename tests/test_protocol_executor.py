"""
Testy jednostkowe dla ProtocolExecutor — nexus_ai/core/protocol_executor.py.

Sprawdza:
  1. Prompt building — build_prompt(), build_orchestrator_prompt(), build_orchestrator_prompt_with_flag()
  2. Matryca decyzyjna — validate_council_verdict() z 14 kombinacjami (8 podstawowych + 6 ERROR)
  3. Protokoły awaryjne — recommend_emergency_action() dla wszystkich scenariuszy
  4. Adaptacyjne progi — get_adapted_thresholds() z różnymi kombinacjami
  5. Scenariusze brzegowe — get_edge_case_protocol()
  6. Walidacja decyzji — validate_decision()
  7. Podsumowanie protokołów — get_protocol_summary()
  8. Protokoły RAG — get_rag_protocol()
  9. Obsługa błędów — ProtocolNotFoundError, graceful fallback
"""

from __future__ import annotations

import pytest

from nexus_ai.core.protocol_executor import (
    ProtocolExecutor,
    ProtocolViolationError,
    get_protocol_executor,
)
from nexus_ai.core.protocol_loader import (
    ProtocolLoader,
    ProtocolNotFoundError,
)


# ── Fixtures ────────────────────────────────────────────────────────────────

@pytest.fixture
def executor() -> ProtocolExecutor:
    """Zwraca ProtocolExecutor z domyślnym ProtocolLoader."""
    return ProtocolExecutor()


@pytest.fixture
def empty_loader(tmp_path) -> ProtocolLoader:
    """Zwraca ProtocolLoader z nieistniejącym plikiem."""
    return ProtocolLoader(path=tmp_path / "nonexistent.toml")


@pytest.fixture
def empty_executor(empty_loader: ProtocolLoader) -> ProtocolExecutor:
    """Zwraca ProtocolExecutor z pustym loaderem."""
    return ProtocolExecutor(loader=empty_loader)


@pytest.fixture
def sample_invoice_data() -> dict:
    """Przykładowe dane faktury do promptów."""
    return {
        "invoice_id": "inv-999",
        "contractor_nip": "1234567890",
        "contractor_name": "Test sp. z o.o.",
        "amount_net": 1000.00,
        "vat": 230.00,
        "amount_gross": 1230.00,
        "category": "usługi IT",
    }


# ===========================================================================
# 1. PROMPT BUILDING
# ===========================================================================

class TestPromptBuilding:
    """Testy budowania promptów z protokołów."""

    def test_build_prompt_validation_alpha(self, executor: ProtocolExecutor) -> None:
        """build_prompt dla validation.alpha powinien zawierać role i format JSON."""
        prompt = executor.build_prompt("validation.alpha")
        assert "analitykiem finansowym" in prompt
        assert "PROTOKOŁY DECYZYJNE" in prompt
        assert "typical_invoice" in prompt
        assert "Return ONLY a valid JSON object" in prompt

    def test_build_prompt_validation_beta(self, executor: ProtocolExecutor) -> None:
        """build_prompt dla validation.beta powinien zawierać kontrole NIP."""
        prompt = executor.build_prompt("validation.beta")
        assert "kontrolerem finansowym" in prompt
        assert "NIP" in prompt
        assert "Return ONLY a valid JSON object" in prompt

    def test_build_prompt_validation_gamma(self, executor: ProtocolExecutor) -> None:
        """build_prompt dla validation.gamma powinien zawierać anomalie."""
        prompt = executor.build_prompt("validation.gamma")
        assert "anomalie" in prompt.lower()
        assert "Return ONLY a valid JSON object" in prompt

    def test_build_prompt_rules_level_1(self, executor: ProtocolExecutor) -> None:
        """build_prompt dla rules.level_1 powinien zawierać LFM2.5."""
        prompt = executor.build_prompt("rules.level_1")
        assert "LFM2.5" in prompt
        assert "analityk" in prompt.lower()
        assert "Return ONLY a valid JSON object" in prompt

    def test_build_prompt_rules_level_2(self, executor: ProtocolExecutor) -> None:
        """build_prompt dla rules.level_2 powinien zawierać Granite."""
        prompt = executor.build_prompt("rules.level_2")
        assert "Granite" in prompt
        assert "NIP" in prompt
        assert "Return ONLY a valid JSON object" in prompt

    def test_build_prompt_rules_level_3(self, executor: ProtocolExecutor) -> None:
        """build_prompt dla rules.level_3 powinien zawierać LittleLamb."""
        prompt = executor.build_prompt("rules.level_3")
        assert "LittleLamb" in prompt or "Ternary" in prompt
        assert "Return ONLY a valid JSON object" in prompt

    def test_build_prompt_rules_level_4(self, executor: ProtocolExecutor) -> None:
        """build_prompt dla rules.level_4 powinien zawierać Fin-RWKV."""
        prompt = executor.build_prompt("rules.level_4")
        assert "Fin-RWKV" in prompt
        assert "Return ONLY a valid JSON object" in prompt

    def test_build_prompt_workflow_planner(self, executor: ProtocolExecutor) -> None:
        """build_prompt dla workflow_planner powinien zawierać agentów."""
        prompt = executor.build_prompt("workflow_planner")
        assert "orkiestratorem" in prompt.lower()
        assert "EKSTRAKCJA" in prompt
        assert "WALIDACJA" in prompt
        assert "Return ONLY a valid JSON object" in prompt

    def test_build_prompt_nonexistent_protocol(self, empty_executor: ProtocolExecutor) -> None:
        """build_prompt dla nieistniejącego protokołu powinien zwrócić podstawowy prompt."""
        prompt = empty_executor.build_prompt("nonexistent")
        assert "Return ONLY a valid JSON object" in prompt
        # Nie powinien zawierać treści z protokołów (bo nie istnieją)
        assert "PROTOKOŁY DECYZYJNE" not in prompt

    def test_build_prompt_with_context(self, executor: ProtocolExecutor) -> None:
        """build_prompt z kontekstem — parametr context jest akceptowany (obecnie no-op).

        UWAGA: Ten test sprawdza obecne zachowanie, gdzie context jest przyjmowany
        ale nie wpływa na prompt. Jeśli implementacja context zostanie dodana,
        ten test będzie wymagał aktualizacji.
        """
        prompt1 = executor.build_prompt("validation.alpha")
        prompt2 = executor.build_prompt("validation.alpha", context={"test": "value"})
        assert prompt1 == prompt2  # context nie jest obecnie używany (no-op)

    def test_build_prompt_output_format_included(self, executor: ProtocolExecutor) -> None:
        """build_prompt powinien dołączyć format wyjściowy jeśli zdefiniowany."""
        prompt = executor.build_prompt("workflow_planner")
        assert "Output format:" in prompt
        assert '"agents"' in prompt  # z output_format workflow_plan

    def test_build_orchestrator_prompt(
        self, executor: ProtocolExecutor, sample_invoice_data: dict
    ) -> None:
        """build_orchestrator_prompt powinien zawierać dane faktury i protokoły."""
        prompt = executor.build_orchestrator_prompt(
            invoice_data=sample_invoice_data,
            fact_sheet_text="=== ARKUSZ FAKTÓW ===\nTest data",
            few_shot_examples="=== PRZYKŁADY ===\nTest examples",
        )
        assert "inv-999" in prompt
        assert "1234567890" in prompt
        assert "1230.00" in prompt
        assert "Dyrektorem Finansowym" in prompt
        assert "PROTOKOŁY DECYZYJNE" in prompt
        assert "ARKUSZ FAKTÓW" in prompt
        assert "PRZYKŁADY" in prompt
        assert "Return ONLY a valid JSON object" in prompt

    def test_build_orchestrator_prompt_with_flag(
        self, executor: ProtocolExecutor, sample_invoice_data: dict
    ) -> None:
        """build_orchestrator_prompt_with_flag powinien zwrócić (prompt, sop_loaded=True)."""
        prompt, sop_loaded = executor.build_orchestrator_prompt_with_flag(
            invoice_data=sample_invoice_data,
        )
        assert sop_loaded is True
        assert "inv-999" in prompt
        assert "Dyrektorem Finansowym" in prompt

    def test_build_orchestrator_prompt_with_flag_empty_loader(
        self, empty_executor: ProtocolExecutor, sample_invoice_data: dict
    ) -> None:
        """build_orchestrator_prompt_with_flag z pustym loaderem → sop_loaded=False."""
        prompt, sop_loaded = empty_executor.build_orchestrator_prompt_with_flag(
            invoice_data=sample_invoice_data,
        )
        assert sop_loaded is False
        assert "inv-999" in prompt
        assert "Dyrektorem Finansowym" not in prompt  # fallback

    def test_build_orchestrator_prompt_without_few_shot(
        self, executor: ProtocolExecutor, sample_invoice_data: dict
    ) -> None:
        """build_orchestrator_prompt bez few_shot — nie powinien zawierać PRZYKŁADY."""
        prompt = executor.build_orchestrator_prompt(
            invoice_data=sample_invoice_data,
        )
        assert "inv-999" in prompt
        assert "PRZYKŁADY" not in prompt

    def test_build_orchestrator_prompt_without_fact_sheet(
        self, executor: ProtocolExecutor, sample_invoice_data: dict
    ) -> None:
        """build_orchestrator_prompt bez fact_sheet — nie powinien zawierać ARKUSZ FAKTÓW."""
        prompt = executor.build_orchestrator_prompt(
            invoice_data=sample_invoice_data,
        )
        assert "inv-999" in prompt
        assert "ARKUSZ FAKTÓW" not in prompt

    def test_build_orchestrator_prompt_empty_loader(
        self, empty_executor: ProtocolExecutor, sample_invoice_data: dict
    ) -> None:
        """build_orchestrator_prompt z pustym loaderem — graceful degradation."""
        prompt = empty_executor.build_orchestrator_prompt(
            invoice_data=sample_invoice_data,
        )
        assert "inv-999" in prompt
        assert "1230.00" in prompt
        # Nie powinien crashować — tylko zwrócić podstawowe dane faktury
        assert isinstance(prompt, str)
        assert len(prompt) > 50

    def test_build_prompt_without_protocols(
        self, executor: ProtocolExecutor
    ) -> None:
        """build_prompt z include_protocols=False → bez protokołów decyzyjnych."""
        prompt_full = executor.build_prompt("validation.alpha", include_protocols=True)
        prompt_minimal = executor.build_prompt("validation.alpha", include_protocols=False)

        # Oba zawierają rolę
        assert "analitykiem finansowym" in prompt_minimal
        assert "analitykiem finansowym" in prompt_full

        # Pełna wersja zawiera protokoły, minimalna nie
        assert "typical_invoice" in prompt_full
        assert "typical_invoice" not in prompt_minimal

    def test_build_prompt_interface_enforces_json(self, executor: ProtocolExecutor) -> None:
        """Każdy build_prompt musi kończyć się 'Return ONLY a valid JSON object'."""
        paths = [
            "validation.alpha",
            "validation.beta",
            "validation.gamma",
            "workflow_planner",
            "rules.level_1",
            "rules.level_2",
            "rules.level_3",
            "rules.level_4",
        ]
        for path in paths:
            prompt = executor.build_prompt(path)
            assert "Return ONLY a valid JSON object" in prompt, (
                f"Prompt for '{path}' missing JSON requirement"
            )


# ===========================================================================
# 2. DECISION MATRIX VALIDATION (14 kombinacji: 8 podstawowych + 6 ERROR)
# ===========================================================================

class TestCouncilVerdictValidation:
    """Testy walidacji głosów Rady Agentów względem matrycy decyzyjnej."""

    # ── 8 podstawowych kombinacji ─────────────────────────────────────

    def test_full_approve(self, executor: ProtocolExecutor) -> None:
        """APPROVE + APPROVE + APPROVE → FULL_APPROVE → AUTO_POST."""
        result = executor.validate_council_verdict("APPROVE", "APPROVE", "APPROVE")
        assert result["valid"] is True
        assert result["pattern"] == "FULL_APPROVE"
        assert result["action"] == "AUTO_POST"
        assert result["level"] == "LEVEL_1_AUTO"
        assert result["min_trust"] == 0.85

    def test_context_anomaly_approve(self, executor: ProtocolExecutor) -> None:
        """APPROVE + REJECT + APPROVE → CONTEXT_ANOMALY_APPROVE → SUGGEST."""
        result = executor.validate_council_verdict("APPROVE", "REJECT", "APPROVE")
        assert result["valid"] is True
        assert result["pattern"] == "CONTEXT_ANOMALY_APPROVE"
        assert result["action"] == "SUGGEST"
        assert result["level"] == "LEVEL_2_REVIEW"

    def test_context_precision_approve(self, executor: ProtocolExecutor) -> None:
        """APPROVE + APPROVE + REJECT → CONTEXT_PRECISION_APPROVE → SUGGEST."""
        result = executor.validate_council_verdict("APPROVE", "APPROVE", "REJECT")
        assert result["valid"] is True
        assert result["pattern"] == "CONTEXT_PRECISION_APPROVE"
        assert result["action"] == "SUGGEST"
        assert result["level"] == "LEVEL_2_REVIEW"

    def test_context_only(self, executor: ProtocolExecutor) -> None:
        """APPROVE + REJECT + REJECT → CONTEXT_ONLY → ASK_USER."""
        result = executor.validate_council_verdict("APPROVE", "REJECT", "REJECT")
        assert result["valid"] is True
        assert result["pattern"] == "CONTEXT_ONLY"
        assert result["action"] == "ASK_USER"
        assert result["level"] == "LEVEL_3_ESCALATE"

    def test_precision_anomaly_approve(self, executor: ProtocolExecutor) -> None:
        """REJECT + APPROVE + APPROVE → PRECISION_ANOMALY_APPROVE → ASK_USER."""
        result = executor.validate_council_verdict("REJECT", "APPROVE", "APPROVE")
        assert result["valid"] is True
        assert result["pattern"] == "PRECISION_ANOMALY_APPROVE"
        assert result["action"] == "ASK_USER"
        assert result["level"] == "LEVEL_3_ESCALATE"

    def test_anomaly_only(self, executor: ProtocolExecutor) -> None:
        """REJECT + REJECT + APPROVE → ANOMALY_ONLY → ASK_USER."""
        result = executor.validate_council_verdict("REJECT", "REJECT", "APPROVE")
        assert result["valid"] is True
        assert result["pattern"] == "ANOMALY_ONLY"
        assert result["action"] == "ASK_USER"
        assert result["level"] == "LEVEL_3_ESCALATE"

    def test_precision_veto(self, executor: ProtocolExecutor) -> None:
        """REJECT + APPROVE + REJECT → PRECISION_VETO → BLOCK."""
        result = executor.validate_council_verdict("REJECT", "APPROVE", "REJECT")
        assert result["valid"] is True
        assert result["pattern"] == "PRECISION_VETO"
        assert result["action"] == "BLOCK"
        assert result["level"] == "LEVEL_4_BLOCK"

    def test_full_reject(self, executor: ProtocolExecutor) -> None:
        """REJECT + REJECT + REJECT → FULL_REJECT → BLOCK."""
        result = executor.validate_council_verdict("REJECT", "REJECT", "REJECT")
        assert result["valid"] is True
        assert result["pattern"] == "FULL_REJECT"
        assert result["action"] == "BLOCK"
        assert result["level"] == "LEVEL_4_BLOCK"

    # ── 6 rozszerzonych kombinacji (ERROR) ────────────────────────────

    def test_alpha_error(self, executor: ProtocolExecutor) -> None:
        """ERROR + APPROVE + APPROVE → ALPHA_ERROR → SUGGEST."""
        result = executor.validate_council_verdict("ERROR", "APPROVE", "APPROVE")
        assert result["valid"] is True
        assert result["pattern"] == "ALPHA_ERROR"
        assert result["action"] == "SUGGEST"
        assert result["level"] == "LEVEL_2_REVIEW"
        assert result["min_trust"] == 0.80

    def test_beta_error(self, executor: ProtocolExecutor) -> None:
        """APPROVE + ERROR + APPROVE → BETA_ERROR → SUGGEST."""
        result = executor.validate_council_verdict("APPROVE", "ERROR", "APPROVE")
        assert result["valid"] is True
        assert result["pattern"] == "BETA_ERROR"
        assert result["action"] == "SUGGEST"
        assert result["level"] == "LEVEL_2_REVIEW"

    def test_gamma_error(self, executor: ProtocolExecutor) -> None:
        """APPROVE + APPROVE + ERROR → GAMMA_ERROR → SUGGEST."""
        result = executor.validate_council_verdict("APPROVE", "APPROVE", "ERROR")
        assert result["valid"] is True
        assert result["pattern"] == "GAMMA_ERROR"
        assert result["action"] == "SUGGEST"
        assert result["level"] == "LEVEL_2_REVIEW"
        assert result["min_trust"] == 0.90

    def test_double_error(self, executor: ProtocolExecutor) -> None:
        """ERROR + ERROR + APPROVE → DOUBLE_ERROR → ASK_USER."""
        result = executor.validate_council_verdict("ERROR", "ERROR", "APPROVE")
        assert result["valid"] is True
        assert result["pattern"] == "DOUBLE_ERROR"
        assert result["action"] == "ASK_USER"
        assert result["level"] == "LEVEL_3_ESCALATE"

    def test_all_error(self, executor: ProtocolExecutor) -> None:
        """ERROR + ERROR + ERROR → ALL_ERROR → BLOCK."""
        result = executor.validate_council_verdict("ERROR", "ERROR", "ERROR")
        assert result["valid"] is True
        assert result["pattern"] == "ALL_ERROR"
        assert result["action"] == "BLOCK"
        assert result["level"] == "LEVEL_4_BLOCK"

    # ── Nieznane kombinacje ──────────────────────────────────────────

    def test_unknown_combination_fallback(self, executor: ProtocolExecutor) -> None:
        """Nieznana kombinacja → UNKNOWN → ASK_USER."""
        result = executor.validate_council_verdict("MAYBE", "MAYBE", "MAYBE")
        assert result["valid"] is False
        assert result["pattern"] == "UNKNOWN"
        assert result["action"] == "ASK_USER"
        assert result["level"] == "LEVEL_3_ESCALATE"

    def test_unknown_combination_partial_fallback(self, executor: ProtocolExecutor) -> None:
        """Częściowo nieznana kombinacja → UNKNOWN → ASK_USER."""
        result = executor.validate_council_verdict("APPROVE", "MAYBE", "REJECT")
        assert result["valid"] is False
        assert result["pattern"] == "UNKNOWN"

    # ── Wszystkie 14 kombinacji ─────────────────────────────────────

    def test_all_14_combinations_have_required_fields(self, executor: ProtocolExecutor) -> None:
        """Każda z 14 kombinacji ma wszystkie wymagane pola."""
        combinations = [
            ("APPROVE", "APPROVE", "APPROVE", "FULL_APPROVE"),
            ("APPROVE", "REJECT", "APPROVE", "CONTEXT_ANOMALY_APPROVE"),
            ("APPROVE", "APPROVE", "REJECT", "CONTEXT_PRECISION_APPROVE"),
            ("APPROVE", "REJECT", "REJECT", "CONTEXT_ONLY"),
            ("REJECT", "APPROVE", "APPROVE", "PRECISION_ANOMALY_APPROVE"),
            ("REJECT", "REJECT", "APPROVE", "ANOMALY_ONLY"),
            ("REJECT", "APPROVE", "REJECT", "PRECISION_VETO"),
            ("REJECT", "REJECT", "REJECT", "FULL_REJECT"),
            ("ERROR", "APPROVE", "APPROVE", "ALPHA_ERROR"),
            ("APPROVE", "ERROR", "APPROVE", "BETA_ERROR"),
            ("APPROVE", "APPROVE", "ERROR", "GAMMA_ERROR"),
            ("ERROR", "ERROR", "APPROVE", "DOUBLE_ERROR"),
            ("ERROR", "APPROVE", "ERROR", "UNKNOWN"),  # 13 znanych + nieznane = 14
            ("ERROR", "ERROR", "ERROR", "ALL_ERROR"),
        ]  # 14 kombinacji: 13 znanych + 1 UNKNOWN
        assert len(combinations) == 14, f"Expected 14 combinations, got {len(combinations)}"
        for alpha, beta, gamma, expected_pattern in combinations:
            result = executor.validate_council_verdict(alpha, beta, gamma)
            assert result["pattern"] == expected_pattern, (
                f"Expected {expected_pattern} for ({alpha}, {beta}, {gamma}), "
                f"got {result['pattern']}"
            )
            assert "action" in result
            assert "level" in result
            assert "deliberation" in result
            assert result["valid"] is (result["pattern"] != "UNKNOWN")

    def test_validate_council_verdict_empty_loader(
        self, empty_executor: ProtocolExecutor
    ) -> None:
        """validate_council_verdict z pustym loaderem → UNKNOWN."""
        result = empty_executor.validate_council_verdict("APPROVE", "APPROVE", "APPROVE")
        assert result["valid"] is False
        assert result["action"] == "BLOCK"
        assert "Matryca decyzyjna niedostępna" in result["deliberation"]


# ===========================================================================
# 3. EMERGENCY PROTOCOLS
# ===========================================================================

class TestEmergencyProtocols:
    """Testy protokołów awaryjnych."""

    def test_model_timeout(self, executor: ProtocolExecutor) -> None:
        """model_timeout → ASYNC_FALLBACK."""
        result = executor.recommend_emergency_action("model_timeout")
        assert result["action"] == "ASYNC_FALLBACK"
        assert "statycznej matrycy" in result["fallback_strategy"]
        assert result["source"] == "emergency_protocol"
        assert result["notify_user"] is False

    def test_model_error(self, executor: ProtocolExecutor) -> None:
        """model_error → PARSE_FALLBACK."""
        result = executor.recommend_emergency_action("model_error")
        assert result["action"] == "PARSE_FALLBACK"
        assert result["max_retries"] == 1
        assert result["notify_user"] is False

    def test_model_crash(self, executor: ProtocolExecutor) -> None:
        """model_crash → SAFE_DEFAULT."""
        result = executor.recommend_emergency_action("model_crash")
        assert result["action"] == "SAFE_DEFAULT"
        assert result["max_retries"] == 0
        assert result["notify_user"] is True

    def test_unknown_voting_pattern(self, executor: ProtocolExecutor) -> None:
        """unknown_voting_pattern → SAFE_ESCALATE."""
        result = executor.recommend_emergency_action("unknown_voting_pattern")
        assert result["action"] == "SAFE_ESCALATE"
        assert "ASK_USER" in result["fallback_strategy"]
        assert result["notify_user"] is True

    def test_workflow_timeout(self, executor: ProtocolExecutor) -> None:
        """workflow_timeout → FULL_WORKFLOW."""
        result = executor.recommend_emergency_action("workflow_timeout")
        assert result["action"] == "FULL_WORKFLOW"
        assert "pełny zestaw agentów" in result["fallback_strategy"]
        assert result["notify_user"] is False

    def test_validation_layer_timeout(self, executor: ProtocolExecutor) -> None:
        """validation_layer_timeout → SKIP_LAYER."""
        result = executor.recommend_emergency_action("validation_layer_timeout")
        assert result["action"] == "SKIP_LAYER"
        assert "Pomiń warstwę" in result["fallback_strategy"]
        assert result["notify_user"] is False

    def test_rag_source_failure(self, executor: ProtocolExecutor) -> None:
        """rag_source_failure → ISOLATE_AND_CONTINUE."""
        result = executor.recommend_emergency_action("rag_source_failure")
        assert result["action"] == "ISOLATE_AND_CONTINUE"
        assert "Pomiń źródło" in result["fallback_strategy"]
        assert result["notify_user"] is False

    def test_data_integrity_violation(self, executor: ProtocolExecutor) -> None:
        """data_integrity_violation → PREFER_SQLITE."""
        result = executor.recommend_emergency_action("data_integrity_violation")
        assert result["action"] == "PREFER_SQLITE"
        assert "Preferuj dane z SQLite" in result["fallback_strategy"]
        assert result["notify_user"] is True

    def test_model_oom(self, executor: ProtocolExecutor) -> None:
        """model_oom → FALLBACK_TO_SMALLER."""
        result = executor.recommend_emergency_action("model_oom")
        assert result["action"] == "FALLBACK_TO_SMALLER"
        assert result["max_retries"] == 0
        assert result["notify_user"] is True

    def test_nonexistent_emergency(self, executor: ProtocolExecutor) -> None:
        """Nieistniejący protokół awaryjny → SAFE_ESCALATE."""
        result = executor.recommend_emergency_action("nonexistent_protocol")
        assert result["action"] == "SAFE_ESCALATE"
        assert "bezpieczna eskalacja (brak protokołu)" in result["fallback_strategy"]
        assert result["source"] == "safe_default"
        assert result["notify_user"] is True

    def test_all_emergency_protocols_have_required_fields(
        self, executor: ProtocolExecutor
    ) -> None:
        """Wszystkie protokoły awaryjne mają wymagane pola."""
        names = [
            "model_timeout",
            "model_error",
            "model_crash",
            "unknown_voting_pattern",
            "workflow_timeout",
            "validation_layer_timeout",
            "rag_source_failure",
            "data_integrity_violation",
            "model_oom",
        ]
        for name in names:
            result = executor.recommend_emergency_action(name)
            assert "action" in result, f"{name} missing 'action'"
            assert "fallback_strategy" in result, f"{name} missing 'fallback_strategy'"
            assert "source" in result, f"{name} missing 'source'"
            assert result["source"] == "emergency_protocol"


# ===========================================================================
# 4. ADAPTIVE THRESHOLDS
# ===========================================================================

class TestAdaptiveThresholds:
    """Testy adaptacyjnych progów decyzyjnych."""

    def test_default_thresholds(self, executor: ProtocolExecutor) -> None:
        """Domyślne progi bez adaptacji."""
        thresholds = executor.get_adapted_thresholds()
        assert thresholds.get("auto_post") == 0.92
        assert thresholds.get("suggest") == 0.75
        assert thresholds.get("ask_user") == 0.50

    def test_known_vendor_recurring_low_amount(self, executor: ProtocolExecutor) -> None:
        """Znany kontrahent + kategoria cykliczna + niska kwota → niższy próg."""
        thresholds = executor.get_adapted_thresholds(
            category="paliwo",
            vendor_known=True,
            vendor_invoice_count=10,
            amount_gross=300.0,
        )
        assert thresholds["auto_post"] < 0.92
        assert thresholds["suggest"] < 0.75

    def test_new_vendor_problematic_high_amount(self, executor: ProtocolExecutor) -> None:
        """Nowy kontrahent + kategoria problematyczna + wysoka kwota → wyższy próg."""
        thresholds = executor.get_adapted_thresholds(
            category="usługi it",
            vendor_known=False,
            vendor_invoice_count=0,
            amount_gross=50000.0,
        )
        assert thresholds["auto_post"] > 0.92
        assert thresholds["suggest"] > 0.75

    def test_unknown_vendor_high_amount(self, executor: ProtocolExecutor) -> None:
        """Nieznany kontrahent + wysoka kwota → bardzo wysoki próg."""
        thresholds = executor.get_adapted_thresholds(
            category="unknown",
            vendor_known=False,
            vendor_invoice_count=0,
            amount_gross=100000.0,
        )
        assert thresholds["auto_post"] > 0.95

    def test_known_vendor_medium_amount(self, executor: ProtocolExecutor) -> None:
        """Znany kontrahent + średnia kwota → umiarkowany próg."""
        thresholds = executor.get_adapted_thresholds(
            category="czynsz",
            vendor_known=True,
            vendor_invoice_count=5,
            amount_gross=3000.0,
        )
        assert 0.80 <= thresholds["auto_post"] <= 0.92

    def test_thresholds_clamped(self, executor: ProtocolExecutor) -> None:
        """Progi są ograniczone do [0.0, 1.0] nawet przy ekstremalnych wartościach."""
        thresholds = executor.get_adapted_thresholds(
            category="usługi it",
            vendor_known=False,
            vendor_invoice_count=0,
            amount_gross=999999.0,
        )
        for key in ("auto_post", "suggest", "ask_user"):
            if key in thresholds:
                assert 0.0 <= thresholds[key] <= 1.0, (
                    f"Threshold {key} = {thresholds[key]} out of range [0.0, 1.0]"
                )


# ===========================================================================
# 5. EDGE CASE PROTOCOLS
# ===========================================================================

class TestEdgeCaseProtocols:
    """Testy scenariuszy brzegowych."""

    def test_ocr_low_confidence(self, executor: ProtocolExecutor) -> None:
        """ocr_low_confidence → BLOCK, wymuś pełną ścieżkę."""
        result = executor.get_edge_case_protocol("ocr_low_confidence")
        assert result["condition"] == "OCR confidence < 0.5"
        assert "Wymuś kompletną ścieżkę" in result["expected_behavior"]
        assert "low_confidence" in result.get("override", "")

    def test_duplicate_invoice(self, executor: ProtocolExecutor) -> None:
        """duplicate_invoice → BLOCK."""
        result = executor.get_edge_case_protocol("duplicate_invoice")
        assert "BLOCK" in result["expected_behavior"]
        assert "duplikatu" in result.get("override", "")

    def test_partial_data(self, executor: ProtocolExecutor) -> None:
        """partial_data → kontynuuj z podniesionym progiem."""
        result = executor.get_edge_case_protocol("partial_data")
        assert "Kontynuuj z dostępnymi danymi" in result["expected_behavior"]
        assert "0.03" in result.get("override", "")

    def test_nip_checksum_error(self, executor: ProtocolExecutor) -> None:
        """nip_checksum_error → BLOCK."""
        result = executor.get_edge_case_protocol("nip_checksum_error")
        assert "BLOCK" in result["expected_behavior"]
        assert "błędnym NIP-em" in result["expected_behavior"]

    def test_negative_amount(self, executor: ProtocolExecutor) -> None:
        """negative_amount → BLOCK."""
        result = executor.get_edge_case_protocol("negative_amount")
        assert "BLOCK" in result["expected_behavior"]
        assert "ujemną kwotą" in result["expected_behavior"]

    def test_currency_mismatch(self, executor: ProtocolExecutor) -> None:
        """currency_mismatch → ASK_USER."""
        result = executor.get_edge_case_protocol("currency_mismatch")
        assert "ASK_USER" in result["expected_behavior"]
        assert "walutę" in result["expected_behavior"]

    def test_nonexistent_edge_case(self, executor: ProtocolExecutor) -> None:
        """Nieistniejący scenariusz brzegowy → ESCALATE."""
        result = executor.get_edge_case_protocol("nonexistent_scenario")
        assert "ESCALATE" in result["expected_behavior"]
        assert "nieznany scenariusz brzegowy" in result["expected_behavior"]


# ===========================================================================
# 6. VALIDATE DECISION
# ===========================================================================

class TestValidateDecision:
    """Testy walidacji decyzji modelu względem protokołów."""

    def test_validate_decision_valid(self, executor: ProtocolExecutor) -> None:
        """Decyzja APPROVE z wysokim confidence → valid."""
        result = executor.validate_decision(
            "validation.alpha",
            decision="APPROVE",
            confidence=0.95,
        )
        assert result["valid"] is True

    def test_validate_decision_without_min_trust_constraint(self, executor: ProtocolExecutor) -> None:
        """Brak min_trust w protokole → zawsze valid (confidence nie ma znaczenia)."""
        result = executor.validate_decision(
            "validation.alpha",
            decision="APPROVE",
            confidence=0.1,
        )
        # validation.alpha nie ma min_trust w protokołach
        # confidence nie jest walidowane gdy brak min_trust
        assert result["valid"] is True
        assert result["violations"] == []

    def test_validate_decision_nonexistent_protocol(self, executor: ProtocolExecutor) -> None:
        """Nieistniejący protokół → valid (brak reguł do sprawdzenia)."""
        result = executor.validate_decision(
            "nonexistent",
            decision="APPROVE",
            confidence=0.5,
        )
        assert result["valid"] is True
        assert result["expected_actions"] == []
        assert result["violations"] == []


# ===========================================================================
# 7. PROTOCOL SUMMARY
# ===========================================================================

class TestProtocolSummary:
    """Testy podsumowania protokołów."""

    def test_get_protocol_summary_contains_categories(self, executor: ProtocolExecutor) -> None:
        """get_protocol_summary powinien zawierać główne kategorie."""
        summary = executor.get_protocol_summary()
        assert "DOSTĘPNE PROTOKOŁY SOP" in summary
        assert "validation" in summary.lower()
        assert "rules" in summary.lower()
        assert "workflow_planner" in summary.lower()

    def test_get_protocol_summary_empty_loader(
        self, empty_executor: ProtocolExecutor
    ) -> None:
        """get_protocol_summary z pustym loaderem → komunikat o braku."""
        summary = empty_executor.get_protocol_summary()
        assert "Brak dostępnych protokołów" in summary

    def test_get_protocol_summary_includes_descriptions(
        self, executor: ProtocolExecutor
    ) -> None:
        """Podsumowanie powinno zawierać opisy protokołów."""
        summary = executor.get_protocol_summary()
        assert "Trójwarstwowa Tarcza Bezpieczeństwa" in summary
        assert "hierarchiczny przepływ" in summary.lower()


# ===========================================================================
# 8. RAG PROTOCOLS
# ===========================================================================

class TestRagProtocols:
    """Testy protokołów RAG."""

    def test_get_rag_protocol_default(self, executor: ProtocolExecutor) -> None:
        """get_rag_protocol() bez parametru → sekcja before_decision."""
        result = executor.get_rag_protocol()
        assert "steps" in result
        assert any("Uruchom wszystkie" in str(s) for s in result.get("steps", []))
        assert "timeout" in result

    def test_get_rag_protocol_sqlite_source(self, executor: ProtocolExecutor) -> None:
        """get_rag_protocol('data_sources.sqlite') → dane kontrahenta."""
        result = executor.get_rag_protocol("data_sources.sqlite")
        assert "description" in result
        assert "contractor" in str(result.get("fields", [])).lower()

    def test_get_rag_protocol_duckdb_source(self, executor: ProtocolExecutor) -> None:
        """get_rag_protocol('data_sources.duckdb') → dane analityczne."""
        result = executor.get_rag_protocol("data_sources.duckdb")
        assert "description" in result
        assert "trust_score_trend" in str(result.get("fields", []))

    def test_get_rag_protocol_nonexistent(self, executor: ProtocolExecutor) -> None:
        """get_rag_protocol z nieistniejącą sekcją → domyślny."""
        result = executor.get_rag_protocol("nonexistent_section")
        assert isinstance(result, dict)
        assert "steps" in result
        assert "FactsAggregator" in result["steps"][0]

    def test_get_rag_protocol_few_shot(self, executor: ProtocolExecutor) -> None:
        """get_rag_protocol('few_shot') → konfiguracja few-shot."""
        result = executor.get_rag_protocol("few_shot")
        assert "max_examples" in result
        assert result["max_examples"] == 3
        assert "priority_order" in result


# ===========================================================================
# 9. ERROR HANDLING & EDGE CASES
# ===========================================================================

class TestErrorHandling:
    """Testy obsługi błędów i przypadków brzegowych."""

    def test_protocol_violation_error_is_exception(self) -> None:
        """ProtocolViolationError dziedziczy po Exception."""
        error = ProtocolViolationError("Test error")
        assert isinstance(error, Exception)
        assert str(error) == "Test error"

    def test_get_protocol_executor_singleton(self) -> None:
        """get_protocol_executor() zwraca ten sam obiekt przy wielokrotnym wywołaniu."""
        exec1 = get_protocol_executor()
        exec2 = get_protocol_executor()
        assert exec1 is exec2

    def test_protocol_executor_init_with_loader(
        self, executor: ProtocolExecutor
    ) -> None:
        """ProtocolExecutor można zainicjalizować z konkretnym loaderem."""
        assert executor._loader is not None
        assert isinstance(executor._loader, ProtocolLoader)

    def test_cross_validate_consistency(self, executor: ProtocolExecutor) -> None:
        """Spójność: pattern FULL_APPROVE powinien zawsze dawać AUTO_POST."""
        result = executor.validate_council_verdict("APPROVE", "APPROVE", "APPROVE")
        assert result["action"] == "AUTO_POST"

        result2 = executor.validate_council_verdict("APPROVE", "APPROVE", "APPROVE")
        assert result == result2  # determinizm

    def test_build_prompt_does_not_mutate_loader(
        self, executor: ProtocolExecutor
    ) -> None:
        """Wielokrotne budowanie promptu nie mutuje loadera."""
        before = executor._loader.get_metadata().get("version")
        executor.build_prompt("validation.alpha")
        executor.build_prompt("validation.beta")
        executor.build_prompt("workflow_planner")
        after = executor._loader.get_metadata().get("version")
        assert before == after

    def test_build_orchestrator_prompt_with_flag_sop_loaded(
        self, executor: ProtocolExecutor, sample_invoice_data: dict
    ) -> None:
        """Flaga sop_loaded jest True gdy protokoły dostępne i poprawnie załadowane."""
        prompt, sop_loaded = executor.build_orchestrator_prompt_with_flag(
            invoice_data=sample_invoice_data,
        )
        assert sop_loaded is True
        # Prompt zawiera SOP
        assert "Niejasna kategoria wydatku" in prompt  # protocol_1 name
        assert "Wykryta anomalia cenowa" in prompt     # protocol_2 name
        assert "Brakujące dane z OCR" in prompt        # protocol_3 name


# ===========================================================================
# 10. INTEGRATION — pełny przepływ walidacji decyzji
# ===========================================================================

class TestFullDecisionValidationFlow:
    """Testy integracyjne — pełny przepływ walidacji decyzji."""

    def test_approve_flow_via_executor(self, executor: ProtocolExecutor) -> None:
        """Pełny flow: głosy Rady → walidacja → prompt."""
        alpha, beta, gamma = "APPROVE", "APPROVE", "APPROVE"

        verdict = executor.validate_council_verdict(alpha, beta, gamma)
        assert verdict["action"] == "AUTO_POST"
        assert verdict["valid"] is True

        prompt = executor.build_prompt("validation.alpha")
        assert "APPROVE" in prompt or "analitykiem" in prompt

    def test_reject_flow_via_executor(self, executor: ProtocolExecutor) -> None:
        """Pełny flow: głosy Rady (REJECT) → walidacja → emergency fallback."""
        alpha, beta, gamma = "REJECT", "REJECT", "REJECT"

        verdict = executor.validate_council_verdict(alpha, beta, gamma)
        assert verdict["action"] == "BLOCK"
        assert verdict["level"] == "LEVEL_4_BLOCK"

    def test_error_flow_via_executor(self, executor: ProtocolExecutor) -> None:
        """Pełny flow: błędy modelu → zmiana matrycy → emergency protocol."""
        alpha, beta, gamma = "ERROR", "APPROVE", "APPROVE"

        verdict = executor.validate_council_verdict(alpha, beta, gamma)
        assert verdict["pattern"] == "ALPHA_ERROR"
        assert verdict["action"] == "SUGGEST"
        assert verdict["min_trust"] == 0.80

        # Emergency dla timeoutu modelu
        emergency = executor.recommend_emergency_action("validation_layer_timeout")
        assert emergency["action"] == "SKIP_LAYER"

    def test_threshold_prompt_consistency(
        self, executor: ProtocolExecutor, sample_invoice_data: dict
    ) -> None:
        """Spójność progów: wyższe ryzyko → wyższy próg → wpływa na prompt."""
        thresholds_safe = executor.get_adapted_thresholds(
            category="paliwo",
            vendor_known=True,
            vendor_invoice_count=10,
            amount_gross=300.0,
        )
        thresholds_risky = executor.get_adapted_thresholds(
            category="usługi it",
            vendor_known=False,
            vendor_invoice_count=0,
            amount_gross=50000.0,
        )
        assert thresholds_safe["auto_post"] < thresholds_risky["auto_post"]
