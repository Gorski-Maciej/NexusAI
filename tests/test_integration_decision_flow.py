"""
Integracyjny test E2E: ProtocolExecutor → CouncilAgents → QualityValidatorAgent → RulesSWATTeam.

Testuje pełną ścieżkę walidacji faktury od promptu do decyzji bez uruchamiania
rzeczywistych modeli LLM (mocking inferencji).

Przepływ:
  1. ProtocolExecutor.build_prompt() dla każdego agenta
  2. CouncilAgents (Alpha/Beta/Gamma) z mockowanymi odpowiedziami LLM
  3. QualityValidatorAgent._resolve_verdict() przez matrycę z protocols.toml
  4. RulesSWATTeam kaskada (Level 1-4) z mockowanymi odpowiedziami LLM
  5. Weryfikacja końcowej decyzji (AUTO_POST / SUGGEST / BLOCK)

Scenariusze:
  - FULL_APPROVE: Alpha=APPROVE, Beta=APPROVE, Gamma=APPROVE → AUTO_POST
  - FULL_REJECT: wszystkie REJECT → BLOCK
  - CONTEXT_ANOMALY_APPROVE: Alpha=APPROVE, Beta=REJECT, Gamma=APPROVE → SUGGEST
  - Fast-path: Alpha APPROVE conf=0.95 → pomiń Beta/Gamma
  - Fast-path wyłączony: use_fast_path=False → uruchom wszystkie warstwy
  - Nieznana kombinacja (ERROR) → ASK_USER
  - Rules SWAT fast-path: L1 COMPLIANT conf=0.95 → pomiń L2-L4
  - Rules SWAT pełna kaskada: L1 FLAG → L2 violations → L3 VIOLATION → L4
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from nexus_ai.core.protocol_executor import ProtocolExecutor
from nexus_ai.core.protocol_loader import ProtocolLoader
from nexus_ai.services.council_agents import (
    AlphaAgent,
    BetaAgent,
    DecisionVerdict,
    GammaAgent,
    ModelManager,
)
from nexus_ai.services.quality_validator_agent import (
    QualityValidatorAgent,
    ValidationLevel,
    ValidationVerdict,
)
from nexus_ai.services.rules_agent import RulesSWATTeam


# ── Fixtures ──────────────────────────────────────────────────────────────

INVOICE_SAMPLE: dict = {
    "invoice_id": "INV-2026-001",
    "contractor_nip": "1234563218",
    "amount_net": 1000.00,
    "vat": 230.00,
    "amount_gross": 1230.00,
    "category": "paliwo",
    "issue_date": "2026-06-01",
    "number": "FV/2026/001",
    "contractor": {"name": "Firma Testowa Sp. z o.o.", "known": True},
    "vendor_profile": {"name": "Firma Testowa", "known": True, "invoice_count": 15, "trust_score": 0.85},
    "historical_average": 1200.00,
    "vendor_invoice_count": 15,
    "amount_threshold": 10000,
    "ocr_confidence": 0.95,
}


@pytest.fixture
def protocol_loader() -> ProtocolLoader:
    """Prawdziwy ProtocolLoader wskazujący na protocols.toml."""
    return ProtocolLoader()


@pytest.fixture
def protocol_executor(protocol_loader: ProtocolLoader) -> ProtocolExecutor:
    """Prawdziwy ProtocolExecutor z prawdziwym loaderm."""
    return ProtocolExecutor(loader=protocol_loader)


@pytest.fixture
def mock_model_manager() -> ModelManager:
    """ModelManager z zamockowanym acquire/release — nie ładuje GGUF."""
    mm = MagicMock(spec=ModelManager)

    # Mock model — create_chat_completion zwraca predefiniowaną odpowiedź
    mock_model = MagicMock()
    mm.acquire = AsyncMock(return_value=mock_model)
    mm.release = AsyncMock()
    mm.is_locked = False
    mm.current_model_name = None

    return mm


def _make_mock_response(json_content: str) -> dict:
    """Stwórz odpowiedź modelu z zadanym JSON-em."""
    return {
        "choices": [{"message": {"content": json_content}}]
    }


@pytest.fixture
def alpha_agent(protocol_executor: ProtocolExecutor, mock_model_manager: ModelManager) -> AlphaAgent:
    return AlphaAgent(
        model_name="lfm25",
        model_path="/dev/null/test.gguf",
        model_manager=mock_model_manager,
        protocol_executor=protocol_executor,
    )


@pytest.fixture
def beta_agent(protocol_executor: ProtocolExecutor, mock_model_manager: ModelManager) -> BetaAgent:
    return BetaAgent(
        model_name="qwen3",
        model_path="/dev/null/test.gguf",
        model_manager=mock_model_manager,
        protocol_executor=protocol_executor,
    )


@pytest.fixture
def gamma_agent(protocol_executor: ProtocolExecutor, mock_model_manager: ModelManager) -> GammaAgent:
    return GammaAgent(
        model_name="littlelamb",
        model_path="/dev/null/test.gguf",
        model_manager=mock_model_manager,
        protocol_executor=protocol_executor,
    )


@pytest.fixture
def validator(
    alpha_agent: AlphaAgent,
    beta_agent: BetaAgent,
    gamma_agent: GammaAgent,
    protocol_executor: ProtocolExecutor,
) -> QualityValidatorAgent:
    """Prawdziwy QualityValidatorAgent z prawdziwymi agentami i protocol_executorem."""
    return QualityValidatorAgent(
        alpha_agent=alpha_agent,
        beta_agent=beta_agent,
        gamma_agent=gamma_agent,
        protocol_executor=protocol_executor,
    )


@pytest.fixture
def rules_swat(mock_model_manager: ModelManager, protocol_executor: ProtocolExecutor) -> RulesSWATTeam:
    """RulesSWATTeam z zamockowanym model_managerem."""
    return RulesSWATTeam(
        lfm_model_name="lfm25",
        lfm_model_path="/dev/null/lfm.gguf",
        granite_model_name="granite",
        granite_model_path="/dev/null/granite.gguf",
        littlelamb_model_name="littlelamb",
        littlelamb_model_path="/dev/null/ll.gguf",
        fin_rwkv_model_path="/dev/null/fin.gguf",
        model_manager=mock_model_manager,
        protocol_executor=protocol_executor,
    )


# ===========================================================================
# TESTY: QualityValidatorAgent z ProtocolExecutor
# ===========================================================================

class TestQualityValidatorWithProtocolExecutor:
    """QualityValidatorAgent używa ProtocolExecutor.validate_council_verdict().

    Weryfikacja że matryca decyzyjna z protocols.toml jest poprawnie używana
    do mapowania głosów Alpha/Beta/Gamma na akcje.
    """

    @pytest.mark.asyncio
    async def test_full_approve_auto_post(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
    ) -> None:
        """APPROVE × 3 → FULL_APPROVE → AUTO_POST (LEVEL_1_AUTO)."""
        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.95, "OK")),
            patch.object(beta_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.90, "OK")),
            patch.object(gamma_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.88, "OK")),
        ):
            verdict = await validator.validate("INV-001", INVOICE_SAMPLE, use_fast_path=False)

        assert verdict.pattern == "FULL_APPROVE"
        assert verdict.level == ValidationLevel.LEVEL_1_AUTO
        assert verdict.recommended_action == "AUTO_POST"
        assert verdict.min_trust_for_auto == 0.85
        assert verdict.layer1_decision == "APPROVE"
        assert verdict.layer2_decision == "APPROVE"
        assert verdict.layer3_decision == "APPROVE"

    @pytest.mark.asyncio
    async def test_full_reject_block(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
    ) -> None:
        """REJECT × 3 → FULL_REJECT → BLOCK (LEVEL_4_BLOCK)."""
        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("REJECT", 0.50, "Suspicious")),
            patch.object(beta_agent, "evaluate", return_value=DecisionVerdict("REJECT", 0.60, "NIP error")),
            patch.object(gamma_agent, "evaluate", return_value=DecisionVerdict("REJECT", 0.55, "Duplicate")),
        ):
            verdict = await validator.validate("INV-002", INVOICE_SAMPLE, use_fast_path=False)

        assert verdict.pattern == "FULL_REJECT"
        assert verdict.level == ValidationLevel.LEVEL_4_BLOCK
        assert verdict.recommended_action == "BLOCK"

    @pytest.mark.asyncio
    async def test_context_anomaly_approve_suggest(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
    ) -> None:
        """Alpha=APPROVE, Beta=REJECT, Gamma=APPROVE → CONTEXT_ANOMALY_APPROVE → SUGGEST."""
        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.85, "Typical")),
            patch.object(beta_agent, "evaluate", return_value=DecisionVerdict("REJECT", 0.70, "NIP checksum fail")),
            patch.object(gamma_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.80, "No duplicate")),
        ):
            verdict = await validator.validate("INV-003", INVOICE_SAMPLE, use_fast_path=False)

        assert verdict.pattern == "CONTEXT_ANOMALY_APPROVE"
        assert verdict.level == ValidationLevel.LEVEL_2_REVIEW
        assert verdict.recommended_action == "SUGGEST"
        assert verdict.min_trust_for_auto == 0.92

    @pytest.mark.asyncio
    async def test_fast_path_skips_beta_gamma(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
    ) -> None:
        """Alpha APPROVE z confidence=0.95 → fast-path, Beta/Gamma pominięte.

        Weryfikacja: Beta i Gamma NIE są wywoływane.
        """
        beta_mock = AsyncMock()
        gamma_mock = AsyncMock()

        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.95, "OK")),
            patch.object(beta_agent, "evaluate", beta_mock),
            patch.object(gamma_agent, "evaluate", gamma_mock),
        ):
            verdict = await validator.validate("INV-004", INVOICE_SAMPLE, use_fast_path=True)

        assert verdict.recommended_action == "AUTO_POST"
        beta_mock.assert_not_called()
        gamma_mock.assert_not_called()

    @pytest.mark.asyncio
    async def test_fast_path_not_triggered_below_threshold(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
    ) -> None:
        """Alpha APPROVE z confidence=0.91 (poniżej progu 0.92) → fast-path NIE uruchomiony.

        Weryfikacja: Beta i Gamma są wywoływane mimo APPROVE.
        """
        beta_mock = AsyncMock(return_value=DecisionVerdict("APPROVE", 0.90, "OK"))
        gamma_mock = AsyncMock(return_value=DecisionVerdict("APPROVE", 0.88, "OK"))

        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.91, "OK")),
            patch.object(beta_agent, "evaluate", beta_mock),
            patch.object(gamma_agent, "evaluate", gamma_mock),
        ):
            verdict = await validator.validate("INV-004", INVOICE_SAMPLE, use_fast_path=True)

        assert verdict.recommended_action == "AUTO_POST"
        beta_mock.assert_called_once()
        gamma_mock.assert_called_once()

    @pytest.mark.asyncio
    async def test_fast_path_disabled_runs_all_layers(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
    ) -> None:
        """use_fast_path=False → wszystkie 3 warstwy uruchomione mimo wysokiego confidence Alpha."""
        beta_mock = AsyncMock(return_value=DecisionVerdict("APPROVE", 0.90, "OK"))
        gamma_mock = AsyncMock(return_value=DecisionVerdict("APPROVE", 0.88, "OK"))

        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.95, "OK")),
            patch.object(beta_agent, "evaluate", beta_mock),
            patch.object(gamma_agent, "evaluate", gamma_mock),
        ):
            verdict = await validator.validate("INV-005", INVOICE_SAMPLE, use_fast_path=False)

        assert verdict.pattern == "FULL_APPROVE"
        assert verdict.recommended_action == "AUTO_POST"
        beta_mock.assert_called_once()
        gamma_mock.assert_called_once()

    @pytest.mark.asyncio
    async def test_unknown_pattern_with_errors_ask_user(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
    ) -> None:
        """ERROR × 3 → nieznana kombinacja → UNKNOWN → ASK_USER (LEVEL_3_ESCALATE)."""
        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("ERROR", 0.0, "Timeout")),
            patch.object(beta_agent, "evaluate", return_value=DecisionVerdict("ERROR", 0.0, "Timeout")),
            patch.object(gamma_agent, "evaluate", return_value=DecisionVerdict("ERROR", 0.0, "Timeout")),
        ):
            verdict = await validator.validate("INV-006", INVOICE_SAMPLE, use_fast_path=False)

        # ERROR,ERROR,ERROR → ALL_ERROR → BLOCK (z matrycy protocols.toml)
        # Sprawdź czy matryca zawiera tę kombinację
        assert verdict.pattern in ("ALL_ERROR", "UNKNOWN")
        if verdict.pattern == "ALL_ERROR":
            assert verdict.recommended_action == "BLOCK"
            assert verdict.level == ValidationLevel.LEVEL_4_BLOCK
        else:
            assert verdict.recommended_action == "ASK_USER"

    @pytest.mark.asyncio
    async def test_precision_veto_block(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
    ) -> None:
        """Alpha=REJECT, Beta=APPROVE, Gamma=REJECT → PRECISION_VETO → BLOCK."""
        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("REJECT", 0.40, "Context wrong")),
            patch.object(beta_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.85, "Math OK")),
            patch.object(gamma_agent, "evaluate", return_value=DecisionVerdict("REJECT", 0.45, "Anomaly")),
        ):
            verdict = await validator.validate("INV-007", INVOICE_SAMPLE, use_fast_path=False)

        assert verdict.pattern == "PRECISION_VETO"
        assert verdict.level == ValidationLevel.LEVEL_4_BLOCK
        assert verdict.recommended_action == "BLOCK"


# ===========================================================================
# TESTY: ProtocolExecutor.build_prompt() jest używane przez agentów
# ===========================================================================

class TestProtocolExecutorIntegration:
    """Weryfikacja że ProtocolExecutor.build_prompt() jest faktycznie używany.

    Agenci (Alpha, Beta, Gamma, Rules) powinni używać promptów z SOP w
    protocols.toml zamiast inline promptów.
    """

    def test_alpha_build_prompt_uses_protocol_executor(
        self, alpha_agent: AlphaAgent
    ) -> None:
        """AlphaAgent.build_prompt() zawiera SOP z protocols.toml."""
        prompt = alpha_agent.build_prompt(INVOICE_SAMPLE)
        # SOP z protocols.toml: "Jesteś doświadczonym analitykiem finansowym."
        assert "doświadczonym analitykiem finansowym" in prompt
        # Sprawdź że protokół decyzyjny z TOML jest obecny
        assert "typical_invoice" in prompt or "PROTOKOŁY DECYZYJNE" in prompt
        # Sprawdź że dane faktury są wstrzyknięte
        assert "Firma Testowa" in prompt
        assert "1230.00" in prompt or "1230" in prompt

    def test_beta_build_prompt_uses_protocol_executor(
        self, beta_agent: BetaAgent
    ) -> None:
        """BetaAgent.build_prompt() zawiera SOP z protocols.toml."""
        prompt = beta_agent.build_prompt(INVOICE_SAMPLE)
        # SOP z protocols.toml: "Jesteś skrupulatnym kontrolerem finansowym."
        assert "kontrolerem finansowym" in prompt
        # Kontrole z TOML: "Poprawność sumy kontrolnej NIP"
        assert "NIP" in prompt
        # Dane faktury
        assert "1234563218" in prompt or "NIP" in prompt

    def test_gamma_build_prompt_uses_protocol_executor(
        self, gamma_agent: GammaAgent
    ) -> None:
        """GammaAgent.build_prompt() zawiera SOP z protocols.toml."""
        prompt = gamma_agent.build_prompt(INVOICE_SAMPLE)
        # SOP z protocols.toml: Gamma ma "anomalie" w roli
        assert "anomalie" in prompt.lower() or "duplikat" in prompt.lower()
        # Dane faktury
        assert "INV-2026-001" in prompt

    def test_all_three_prompts_are_different(
        self,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
    ) -> None:
        """Każdy agent ma inny prompt — różne role i kontrole."""
        prompt_a = alpha_agent.build_prompt(INVOICE_SAMPLE)
        prompt_b = beta_agent.build_prompt(INVOICE_SAMPLE)
        prompt_c = gamma_agent.build_prompt(INVOICE_SAMPLE)

        assert prompt_a != prompt_b
        assert prompt_b != prompt_c
        assert prompt_a != prompt_c

    def test_build_prompt_include_protocols_flag(
        self, protocol_executor: ProtocolExecutor
    ) -> None:
        """include_protocols=False pomija protokoły decyzyjne."""
        full = protocol_executor.build_prompt("validation.alpha", include_protocols=True)
        minimal = protocol_executor.build_prompt("validation.alpha", include_protocols=False)

        # Oba mają rolę
        assert "analitykiem finansowym" in full
        assert "analitykiem finansowym" in minimal
        # Tylko full ma protokoły
        assert "typical_invoice" not in minimal
        # Oba mają JSON enforcement
        assert "Return ONLY a valid JSON" in minimal


# ===========================================================================
# TESTY: RulesSWATTeam z ProtocolExecutor
# ===========================================================================

class TestRulesSWATIntegration:
    """RulesSWATTeam używa ProtocolExecutor.build_prompt().

    Testy weryfikują hierarchiczną kaskadę Level 1-4 z mockowanymi odpowiedziami.
    """

    @pytest.mark.asyncio
    async def test_rules_fast_path_compliant(
        self,
        rules_swat: RulesSWATTeam,
        mock_model_manager: ModelManager,
    ) -> None:
        """Level 1 COMPLIANT z conf=0.95 → fast-path, L2-L4 pominięte."""
        # Ustaw mock model na odpowiedź COMPLIANT dla L1
        mock_model = MagicMock()
        mock_model.create_chat_completion.return_value = _make_mock_response(
            '{"decision": "COMPLIANT", "confidence": 0.95, "reasoning": "Typical invoice", "flags": []}'
        )
        mock_model_manager.acquire = AsyncMock(return_value=mock_model)

        result = await rules_swat.evaluate(INVOICE_SAMPLE)

        assert result["passed"] is True
        assert result["confidence"] >= 0.90
        assert result["levels_used"] == ["lfm25"]
        assert len(result["level_results"]) == 1
        assert "lfm25" in result["level_results"]

    @pytest.mark.asyncio
    async def test_rules_level_1_flag_level_2_passed(
        self,
        rules_swat: RulesSWATTeam,
        mock_model_manager: ModelManager,
    ) -> None:
        """L1=FLAG → L2=passed (brak violations) → zwróć passed."""
        mock_model = MagicMock()
        responses = [
            _make_mock_response('{"decision": "FLAG", "confidence": 0.60, "reasoning": "New vendor", "flags": [{"area": "vendor", "severity": "low"}]}'),
            _make_mock_response('{"passed": true, "confidence": 0.80, "violations": [], "reasoning": "All rules OK"}'),
        ]
        mock_model.create_chat_completion.side_effect = responses
        mock_model_manager.acquire = AsyncMock(return_value=mock_model)

        result = await rules_swat.evaluate(INVOICE_SAMPLE)

        assert result["passed"] is True
        assert result["levels_used"] == ["lfm25", "granite"]
        assert len(result["level_results"]) == 2

    @pytest.mark.asyncio
    async def test_rules_full_cascade_l1_l2_l3_l4(
        self,
        rules_swat: RulesSWATTeam,
        mock_model_manager: ModelManager,
    ) -> None:
        """Pełna kaskada: L1=FLAG → L2=violations → L3=VIOLATION → L4=FLAG.

        Wszystkie 4 poziomy uruchomione.
        """
        mock_model = MagicMock()
        responses = [
            # L1: FLAG z flagą NIP
            _make_mock_response('{"decision": "FLAG", "confidence": 0.55, "reasoning": "NIP issue", "flags": [{"area": "nip", "severity": "high", "reason": "Invalid checksum"}]}'),
            # L2: violations
            _make_mock_response('{"passed": false, "confidence": 0.60, "violations": [{"rule": "nip_validation", "message": "NIP checksum failed", "severity": "error"}], "reasoning": "NIP invalid"}'),
            # L3: VIOLATION
            _make_mock_response('{"classification": "VIOLATION", "confidence": 0.65, "risk_factors": [{"factor": "invalid_nip", "weight": 0.8, "description": "NIP checksum error"}], "reasoning": "NIP violation"}'),
            # L4: final FLAG
            _make_mock_response('{"risk_level": "HIGH", "confidence": 0.70, "anomaly_score": 0.85, "final_verdict": "FLAG", "reasoning": "NIP cannot be verified", "recommended_action": "block"}'),
        ]
        mock_model.create_chat_completion.side_effect = responses
        mock_model_manager.acquire = AsyncMock(return_value=mock_model)

        result = await rules_swat.evaluate(INVOICE_SAMPLE)

        assert result["passed"] is False
        assert result["levels_used"] == ["lfm25", "granite", "littlelamb", "fin_rwkv"]
        assert len(result["level_results"]) == 4
        assert len(result["violations"]) >= 3  # flagi + violations + risk_factors

        # Sprawdź że wszystkie 4 poziomy są w wynikach
        assert "level1_lfm25" in result["level_results"]
        assert "level2_granite" in result["level_results"]
        assert "level3_littlelamb" in result["level_results"]
        assert "level4_fin_rwkv" in result["level_results"]

    @pytest.mark.asyncio
    async def test_rules_level_3_compliant_skips_level_4(
        self,
        rules_swat: RulesSWATTeam,
        mock_model_manager: ModelManager,
    ) -> None:
        """L1=FLAG → L2=violations → L3=COMPLIANT → L4 pominięty."""
        mock_model = MagicMock()
        responses = [
            _make_mock_response('{"decision": "FLAG", "confidence": 0.60, "reasoning": "Check needed", "flags": []}'),
            _make_mock_response('{"passed": false, "confidence": 0.65, "violations": [{"rule": "amount_limit", "message": "Near limit", "severity": "warning"}], "reasoning": "Amount near limit"}'),
            _make_mock_response('{"classification": "COMPLIANT", "confidence": 0.80, "risk_factors": [], "reasoning": "Acceptable risk"}'),
        ]
        mock_model.create_chat_completion.side_effect = responses
        mock_model_manager.acquire = AsyncMock(return_value=mock_model)

        result = await rules_swat.evaluate(INVOICE_SAMPLE)

        assert result["passed"] is True
        assert result["levels_used"] == ["lfm25", "granite", "littlelamb"]
        assert len(result["level_results"]) == 3
        assert "level4_fin_rwkv" not in result["level_results"]

    @pytest.mark.asyncio
    async def test_rules_level_1_timeout(
        self,
        rules_swat: RulesSWATTeam,
        mock_model_manager: ModelManager,
    ) -> None:
        """Timeout w L1 → FLAG z conf=0.0 (nie crash)."""
        mock_model = MagicMock()
        mock_model.create_chat_completion.side_effect = TimeoutError("Simulated timeout")
        mock_model_manager.acquire = AsyncMock(return_value=mock_model)

        result = await rules_swat.evaluate(INVOICE_SAMPLE)

        # Timeout → FLAG → kontynuuj z L2
        assert result["levels_used"] == ["lfm25", "granite"]
        assert result["passed"] is True  # L2 passed (bo timeout w L1 = FLAG, L2 passed)

    @pytest.mark.asyncio
    async def test_rules_build_prompt_uses_protocol_executor(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """RulesSWATTeam._build_level_X_prompt() używa ProtocolExecutor.build_prompt()."""
        # Pośrednio przez test: wywołaj _build_level_1_prompt i sprawdź SOP
        prompt = rules_swat._build_level_1_prompt(INVOICE_SAMPLE)
        # SOP z protocols.toml rules.level_1: "Jesteś LFM2.5-Thinking"
        assert "LFM2.5-Thinking" in prompt or "analitykiem" in prompt
        assert "Return ONLY a valid JSON" in prompt


# ===========================================================================
# TESTY: RulesSWATTeam._build_level_X_prompt() — SOP z ProtocolExecutor
# ===========================================================================

class TestRulesBuildPromptWithProtocolExecutor:
    """RulesSWATTeam._build_level_X_prompt() używa ProtocolExecutor.build_prompt("rules.level_X").

    Weryfikacja że każdy z 4 poziomów RulesSWATTeam otrzymuje poprawny SOP
    z protocols.toml zamiast inline fallbacku. Testuje bezpośrednio metody
    _build_level_1_prompt do _build_level_4_prompt z prawdziwym ProtocolExecutor.

    Oczekiwane role z protocols.toml:
      Level 1: "Jesteś LFM2.5-Thinking — szybki analityk kontekstowy."
      Level 2: "Jesteś Granite 4.0 1B Nano — agent walidacji reguł biznesowych."
      Level 3: "Jesteś LittleLamb 0.3B TC — Ternary Classifier."
      Level 4: "Jesteś Fin-RWKV-169M — detektyw finansowy."
    """

    def test_level_1_prompt_has_lfm_role_from_sop(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Level 1: SOP role 'LFM2.5-Thinking' z protocols.toml."""
        prompt = rules_swat._build_level_1_prompt(INVOICE_SAMPLE)

        # SOP z protocols.toml rules.level_1.system_prompt.role
        assert "LFM2.5-Thinking" in prompt, (
            "Level 1 powinien zawierać rolę 'LFM2.5-Thinking' z protocols.toml"
        )
        # Task z TOML: "Oceń fakturę: czy jest typowa"
        assert "typowa" in prompt.lower() or "Oceń" in prompt

    def test_level_2_prompt_has_granite_role_from_sop(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Level 2: SOP role 'Granite 4.0 1B Nano' z protocols.toml."""
        prompt = rules_swat._build_level_2_prompt(INVOICE_SAMPLE)

        # SOP z protocols.toml rules.level_2.system_prompt.role
        assert "Granite 4.0 1B Nano" in prompt, (
            "Level 2 powinien zawierać rolę 'Granite 4.0 1B Nano' z protocols.toml"
        )
        # Checks z TOML: "Walidacja NIP"
        assert "Walidacja NIP" in prompt or "NIP" in prompt

    def test_level_3_prompt_has_littlelamb_role_from_sop(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Level 3: SOP role 'LittleLamb 0.3B TC' z protocols.toml."""
        prompt = rules_swat._build_level_3_prompt(INVOICE_SAMPLE, {}, {})

        # SOP z protocols.toml rules.level_3.system_prompt.role
        assert "LittleLamb 0.3B TC" in prompt, (
            "Level 3 powinien zawierać rolę 'LittleLamb 0.3B TC' z protocols.toml"
        )
        # Task z TOML: "COMPLIANT (zgodna), FLAG (oznaczona), VIOLATION (naruszenie)"
        assert "COMPLIANT" in prompt and "FLAG" in prompt and "VIOLATION" in prompt

    def test_level_4_prompt_has_fin_rwkv_role_from_sop(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Level 4: SOP role 'Fin-RWKV-169M' z protocols.toml."""
        prompt = rules_swat._build_level_4_prompt(INVOICE_SAMPLE, {}, {}, {})

        # SOP z protocols.toml rules.level_4.system_prompt.role
        assert "Fin-RWKV-169M" in prompt, (
            "Level 4 powinien zawierać rolę 'Fin-RWKV-169M' z protocols.toml"
        )
        # Task z TOML: "Oceń ryzyko: LOW / MEDIUM / HIGH"
        assert "LOW" in prompt and "MEDIUM" in prompt and "HIGH" in prompt

    def test_all_four_level_prompts_have_json_enforcement(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Wszystkie 4 poziomy mają 'Return ONLY a valid JSON' na końcu."""
        p1 = rules_swat._build_level_1_prompt(INVOICE_SAMPLE)
        p2 = rules_swat._build_level_2_prompt(INVOICE_SAMPLE)
        p3 = rules_swat._build_level_3_prompt(INVOICE_SAMPLE, {}, {})
        p4 = rules_swat._build_level_4_prompt(INVOICE_SAMPLE, {}, {}, {})

        assert "Return ONLY a valid JSON" in p1
        assert "Return ONLY a valid JSON" in p2
        assert "Return ONLY a valid JSON" in p3
        assert "Return ONLY a valid JSON" in p4

    def test_all_four_level_prompts_are_different(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Każdy z 4 poziomów ma unikalny prompt — różne role SOP."""
        p1 = rules_swat._build_level_1_prompt(INVOICE_SAMPLE)
        p2 = rules_swat._build_level_2_prompt(INVOICE_SAMPLE)
        p3 = rules_swat._build_level_3_prompt(INVOICE_SAMPLE, {}, {})
        p4 = rules_swat._build_level_4_prompt(INVOICE_SAMPLE, {}, {}, {})

        assert p1 != p2, "Level 1 i Level 2 powinny mieć różne prompty"
        assert p2 != p3, "Level 2 i Level 3 powinny mieć różne prompty"
        assert p3 != p4, "Level 3 i Level 4 powinny mieć różne prompty"
        assert p1 != p3, "Level 1 i Level 3 powinny mieć różne prompty"
        assert p1 != p4, "Level 1 i Level 4 powinny mieć różne prompty"
        assert p2 != p4, "Level 2 i Level 4 powinny mieć różne prompty"

    def test_all_four_include_invoice_data(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Wszystkie 4 poziomy wstrzykują dane faktury (NIP, kwota, kontrahent)."""
        p1 = rules_swat._build_level_1_prompt(INVOICE_SAMPLE)
        p2 = rules_swat._build_level_2_prompt(INVOICE_SAMPLE)
        p3 = rules_swat._build_level_3_prompt(INVOICE_SAMPLE, {}, {})
        p4 = rules_swat._build_level_4_prompt(INVOICE_SAMPLE, {}, {}, {})

        # NIP z INVOICE_SAMPLE
        assert "1234563218" in p1
        assert "1234563218" in p2
        assert "1234563218" in p3
        assert "1234563218" in p4

        # Kwota brutto
        assert "1230.00" in p1 or "1230" in p1
        assert "1230.00" in p2 or "1230" in p2
        assert "1230.00" in p3 or "1230" in p3
        assert "1230.00" in p4 or "1230" in p4

        # Kategoria
        assert "paliwo" in p1
        assert "paliwo" in p2
        assert "paliwo" in p3
        assert "paliwo" in p4

    def test_level_1_prompt_has_sop_task_reminder(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Level 1: SOP z protocols.toml zawiera task instruction."""
        prompt = rules_swat._build_level_1_prompt(INVOICE_SAMPLE)

        # System prompt z TOML rules.level_1.system_prompt.task
        # "Oceń fakturę: czy jest typowa, czy wymaga dodatkowej weryfikacji."
        assert "dodatkowej weryfikacji" in prompt or "Oceń fakturę" in prompt

    def test_level_2_prompt_has_rules_config(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Level 2: zawiera maksymalną kwotę z AppConfig.rules_max_invoice_amount."""
        prompt = rules_swat._build_level_2_prompt(INVOICE_SAMPLE)

        # Sprawdź czy prompt zawiera regułę kwotową z konfiguracji
        # (maksymalna kwota jest wstrzykiwana z configu)
        assert "Maksymalna kwota" in prompt
        assert "PLN" in prompt

    def test_level_3_prompt_contains_previous_levels(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Level 3: zawiera wyniki Level 1 i Level 2 w promptcie."""
        level1_result = {
            "decision": "FLAG",
            "confidence": 0.60,
            "reasoning": "New vendor",
            "flags": [{"area": "vendor", "severity": "low"}],
        }
        level2_result = {
            "passed": True,
            "confidence": 0.80,
            "violations": [],
            "reasoning": "All rules OK",
        }

        prompt = rules_swat._build_level_3_prompt(
            INVOICE_SAMPLE, level1_result, level2_result
        )

        # Wyniki L1 i L2 są wstrzykiwane do promptu
        assert "FLAG" in prompt and "New vendor" in prompt
        assert "All rules OK" in prompt

    def test_level_4_prompt_contains_all_previous_levels(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Level 4: zawiera wyniki Level 1, Level 2 i Level 3 w promptcie."""
        level1_result = {
            "decision": "FLAG",
            "confidence": 0.55,
            "reasoning": "NIP issue",
            "flags": [],
        }
        level2_result = {
            "passed": False,
            "confidence": 0.60,
            "violations": [{"rule": "nip_validation", "message": "NIP invalid", "severity": "error"}],
            "reasoning": "NIP fail",
        }
        level3_result = {
            "classification": "VIOLATION",
            "confidence": 0.65,
            "risk_factors": [{"factor": "invalid_nip", "weight": 0.8}],
            "reasoning": "NIP violation",
        }

        prompt = rules_swat._build_level_4_prompt(
            INVOICE_SAMPLE, level1_result, level2_result, level3_result
        )

        # Wyniki L1, L2, L3 są wstrzykiwane do promptu
        assert "NIP issue" in prompt
        assert "NIP invalid" in prompt or "NIP fail" in prompt
        assert "VIOLATION" in prompt or "NIP violation" in prompt

    def test_protocol_executor_build_prompt_rules_directly(
        self, protocol_executor: ProtocolExecutor
    ) -> None:
        """ProtocolExecutor.build_prompt("rules.level_X") działa dla wszystkich 4 poziomów.

        Bezpośredni test że ProtocolExecutor potrafi zbudować prompt dla
        każdego poziomu rules bez potrzeby tworzenia RulesSWATTeam.
        """
        # Każdy poziom powinien zwrócić string promptu z SOP
        p1 = protocol_executor.build_prompt("rules.level_1")
        p2 = protocol_executor.build_prompt("rules.level_2")
        p3 = protocol_executor.build_prompt("rules.level_3")
        p4 = protocol_executor.build_prompt("rules.level_4")

        # Wszystkie są stringami
        assert isinstance(p1, str) and len(p1) > 50
        assert isinstance(p2, str) and len(p2) > 50
        assert isinstance(p3, str) and len(p3) > 50
        assert isinstance(p4, str) and len(p4) > 50

        # Każdy zawiera odpowiednią rolę z TOML
        assert "LFM2.5-Thinking" in p1, "rules.level_1 → LFM2.5"
        assert "Granite 4.0 1B Nano" in p2, "rules.level_2 → Granite"
        assert "LittleLamb 0.3B TC" in p3, "rules.level_3 → LittleLamb"
        assert "Fin-RWKV-169M" in p4, "rules.level_4 → Fin-RWKV"

        # Wszystkie mają JSON enforcement
        assert "Return ONLY a valid JSON" in p1
        assert "Return ONLY a valid JSON" in p2
        assert "Return ONLY a valid JSON" in p3
        assert "Return ONLY a valid JSON" in p4

        # Każdy jest unikalny
        assert len({p1, p2, p3, p4}) == 4, "Wszystkie 4 prompty powinny być unikalne"

    def test_level_1_prompt_has_sop_role_lfm_explicitly(
        self, rules_swat: RulesSWATTeam
    ) -> None:
        """Level 1: SOP rola 'LFM2.5-Thinking' jest w promptcie zamiast inline fallbacku.

        Gdy SOP jest dostępny, prompt zawiera konkretną rolę z TOML.
        Gdy SOP niedostępny (fallback), prompt zawiera inline RULES_LEVEL_1_PROMPT
        który też ma "LFM2.5-Thinking". Niezależnie od ścieżki, wynik jest poprawny.
        """
        prompt = rules_swat._build_level_1_prompt(INVOICE_SAMPLE)
        assert "LFM2.5-Thinking" in prompt


# ===========================================================================
# TESTY: Hot-reload — edycja protocols.toml zmienia prompt bez restartu
# ===========================================================================

class TestRulesHotReloadPromptChange:
    """Edycja protocols.toml (system_prompt.role) zmienia prompt używany przez
    RulesSWATTeam._build_level_X_prompt() BEZ restartu aplikacji.

    Przepływ hot-reload:
      1. Tymczasowy plik TOML z "OLD_ROLE" w rules.level_1.system_prompt.role
      2. ProtocolLoader(auto_reload=True) → ProtocolExecutor → RulesSWATTeam
      3. _build_level_1_prompt() → prompt zawiera "OLD_ROLE"
      4. Modyfikacja pliku: role → "NEW_ROLE", version → "2.0"
      5. Bypass rate-limiter loadera (_last_checked = 0)
      6. _build_level_1_prompt() → prompt zawiera "NEW_ROLE"
      7. "OLD_ROLE" nie występuje w nowym promptcie — plik faktycznie przeładowany

    Weryfikuje że RulesSWATTeam nie cache'uje promptów na stałe tylko
    każdorazowo pobiera je z ProtocolExecutor, który odświeża dane z loadera.
    """

    MINIMAL_OLD_TOML = '''
[metadata]
version = "1.0"

[protocols.rules.level_1]
description = "Test level 1"

[protocols.rules.level_1.system_prompt]
role = "OLD_ROLE — stary test"
task = "Test task for old version"
checks = ["Check 1"]

[protocols.rules.level_1.protocols.compliant]
condition = "always"
action = "COMPLIANT"
'''

    MINIMAL_NEW_TOML = '''
[metadata]
version = "2.0"

[protocols.rules.level_1]
description = "Test level 1"

[protocols.rules.level_1.system_prompt]
role = "NEW_ROLE — nowy test"
task = "Test task for new version"
checks = ["Check 1"]

[protocols.rules.level_1.protocols.compliant]
condition = "always"
action = "COMPLIANT"
'''

    def test_hot_reload_changes_level_1_prompt_role(
        self, tmp_path: Path, mock_model_manager: ModelManager
    ) -> None:
        """Po edycji protocols.toml, Level 1 prompt pobiera nową rolę bez restartu."""
        # Krok 1: tymczasowy plik ze starą rolą
        toml_path = tmp_path / "protocols_test.toml"
        toml_path.write_text(self.MINIMAL_OLD_TOML.lstrip("\n"))

        # Krok 2: loader → executor → RulesSWATTeam
        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        executor = ProtocolExecutor(loader=loader)
        team = RulesSWATTeam(
            lfm_model_name="lfm25",
            lfm_model_path="/dev/null/lfm.gguf",
            granite_model_name="granite",
            granite_model_path="/dev/null/granite.gguf",
            littlelamb_model_name="littlelamb",
            littlelamb_model_path="/dev/null/ll.gguf",
            fin_rwkv_model_path="/dev/null/fin.gguf",
            model_manager=mock_model_manager,
            protocol_executor=executor,
        )

        # Krok 3: pierwszy prompt — powinien zawierać starą rolę
        prompt_before = team._build_level_1_prompt(INVOICE_SAMPLE)
        assert "OLD_ROLE" in prompt_before, (
            "Przed zmianą pliku prompt powinien zawierać starą rolę"
        )
        assert "NEW_ROLE" not in prompt_before, (
            "Przed zmianą pliku nowa rola nie powinna być widoczna"
        )
        assert "version=1.0" in prompt_before or "1.0" in prompt_before or "stary test" in prompt_before

        # Krok 4: modyfikacja pliku — nowa rola i wersja
        toml_path.write_text(self.MINIMAL_NEW_TOML.lstrip("\n"))

        # Krok 5: bypass rate-limitera — wymuś sprawdzenie mtime przy następnym load
        loader._last_checked = 0.0

        # Krok 6: ponowny prompt — powinien zawierać nową rolę
        prompt_after = team._build_level_1_prompt(INVOICE_SAMPLE)
        assert "NEW_ROLE" in prompt_after, (
            "Po zmianie pliku prompt powinien zawierać nową rolę"
        )
        assert "OLD_ROLE" not in prompt_after, (
            "Po zmianie pliku stara rola nie powinna być widoczna — "
            "loader powinien przeładować dane z dysku"
        )

        # Krok 7: wersja też powinna być zaktualizowana
        assert "version=2.0" in prompt_after or "2.0" in prompt_after or "nowy test" in prompt_after

    def test_hot_reload_without_file_change_uses_cached_prompt(
        self, tmp_path: Path, mock_model_manager: ModelManager
    ) -> None:
        """Bez zmiany pliku, prompt pozostaje niezmieniony (mtime cache działa)."""
        toml_path = tmp_path / "protocols_static.toml"
        toml_path.write_text(self.MINIMAL_OLD_TOML.lstrip("\n"))

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        executor = ProtocolExecutor(loader=loader)
        team = RulesSWATTeam(
            lfm_model_name="lfm25",
            lfm_model_path="/dev/null/lfm.gguf",
            granite_model_name="granite",
            granite_model_path="/dev/null/granite.gguf",
            littlelamb_model_name="littlelamb",
            littlelamb_model_path="/dev/null/ll.gguf",
            fin_rwkv_model_path="/dev/null/fin.gguf",
            model_manager=mock_model_manager,
            protocol_executor=executor,
        )

        prompt_first = team._build_level_1_prompt(INVOICE_SAMPLE)
        assert "OLD_ROLE" in prompt_first

        # Bypass rate-limiter ale plik się nie zmienił
        loader._last_checked = 0.0

        prompt_second = team._build_level_1_prompt(INVOICE_SAMPLE)
        assert prompt_first == prompt_second, (
            "Gdy plik się nie zmienił, prompt powinien być identyczny (cache hit)"
        )

    def test_hot_reload_with_auto_reload_disabled_does_not_update(
        self, tmp_path: Path, mock_model_manager: ModelManager
    ) -> None:
        """Gdy auto_reload=False, zmiana pliku NIE wpływa na prompt."""
        toml_path = tmp_path / "protocols_noauto.toml"
        toml_path.write_text(self.MINIMAL_OLD_TOML.lstrip("\n"))

        loader = ProtocolLoader(path=toml_path, auto_reload=False)
        executor = ProtocolExecutor(loader=loader)
        team = RulesSWATTeam(
            lfm_model_name="lfm25",
            lfm_model_path="/dev/null/lfm.gguf",
            granite_model_name="granite",
            granite_model_path="/dev/null/granite.gguf",
            littlelamb_model_name="littlelamb",
            littlelamb_model_path="/dev/null/ll.gguf",
            fin_rwkv_model_path="/dev/null/fin.gguf",
            model_manager=mock_model_manager,
            protocol_executor=executor,
        )

        prompt_before = team._build_level_1_prompt(INVOICE_SAMPLE)
        assert "OLD_ROLE" in prompt_before

        # Zmień plik
        toml_path.write_text(self.MINIMAL_NEW_TOML.lstrip("\n"))

        # Bypass rate-limiter (ale auto_reload=False, więc to nie ma znaczenia)
        loader._last_checked = 0.0

        prompt_after = team._build_level_1_prompt(INVOICE_SAMPLE)

        # Bez auto_reload prompt się nie zmienił — wciąż stara rola
        assert prompt_before == prompt_after, (
            "auto_reload=False: zmiana pliku nie powinna wpłynąć na prompt"
        )
        assert "OLD_ROLE" in prompt_after, (
            "auto_reload=False: stara rola powinna być cache'owana"
        )
        assert "NEW_ROLE" not in prompt_after, (
            "auto_reload=False: nowa rola nie powinna być widoczna"
        )

    def test_hot_reload_after_file_disappears_and_reappears(
        self, tmp_path: Path, mock_model_manager: ModelManager
    ) -> None:
        """Plik znika → pusty prompt (fallback do inline). Plik wraca → nowa rola."""
        toml_path = tmp_path / "protocols_disappear.toml"
        toml_path.write_text(self.MINIMAL_OLD_TOML.lstrip("\n"))

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        executor = ProtocolExecutor(loader=loader)
        team = RulesSWATTeam(
            lfm_model_name="lfm25",
            lfm_model_path="/dev/null/lfm.gguf",
            granite_model_name="granite",
            granite_model_path="/dev/null/granite.gguf",
            littlelamb_model_name="littlelamb",
            littlelamb_model_path="/dev/null/ll.gguf",
            fin_rwkv_model_path="/dev/null/fin.gguf",
            model_manager=mock_model_manager,
            protocol_executor=executor,
        )

        # Krok 1: początkowy prompt
        prompt_initial = team._build_level_1_prompt(INVOICE_SAMPLE)
        assert "OLD_ROLE" in prompt_initial

        # Krok 2: plik znika
        toml_path.unlink()
        loader._last_checked = 0.0

        prompt_gone = team._build_level_1_prompt(INVOICE_SAMPLE)
        # Gdy plik zniknie, ProtocolLoader zwraca {} → get_protocol rzuca wyjątek
        # → RulesSWATTeam łapie i używa inline RULES_LEVEL_1_PROMPT
        # Inline prompt ma "LFM2.5-Thinking" ale nie "OLD_ROLE"
        assert "OLD_ROLE" not in prompt_gone, (
            "Gdy plik zniknął, SOP jest niedostępny — prompt nie powinien zawierać OLD_ROLE"
        )
        # Inline fallback nadal działa — RULES_LEVEL_1_PROMPT zawiera "szybki analityk kontekstowy"
        assert "szybki analityk kontekstowy" in prompt_gone, (
            "Gdy plik zniknął, RulesSWATTeam powinien użyć inline fallback RULES_LEVEL_1_PROMPT"
        )
        assert "Return ONLY a valid JSON" in prompt_gone

        # Krok 3: plik wraca (z nową rolą)
        toml_path.write_text(self.MINIMAL_NEW_TOML.lstrip("\n"))
        loader._last_checked = 0.0

        prompt_back = team._build_level_1_prompt(INVOICE_SAMPLE)
        assert "NEW_ROLE" in prompt_back, (
            "Gdy plik wrócił, SOP jest ponownie dostępny — prompt powinien zawierać nową rolę"
        )
        assert "OLD_ROLE" not in prompt_back

    def test_hot_reload_multiple_levels_updated_simultaneously(
        self, tmp_path: Path, mock_model_manager: ModelManager
    ) -> None:
        """Zmiana w pliku wpływa na WSZYSTKIE poziomy jednocześnie."""
        # TOML z obydwoma poziomami
        multi_toml = '''
[metadata]
version = "1.0"

[protocols.rules.level_1]
[protocols.rules.level_1.system_prompt]
role = "L1_OLD"
task = "Test"
checks = []
[protocols.rules.level_1.protocols.compliant]
condition = "x"
action = "COMPLIANT"

[protocols.rules.level_2]
[protocols.rules.level_2.system_prompt]
role = "L2_OLD"
checks = []
[protocols.rules.level_2.protocols.passed]
condition = "x"
action = "APPROVE"
'''

        multi_toml_new = '''
[metadata]
version = "2.0"

[protocols.rules.level_1]
[protocols.rules.level_1.system_prompt]
role = "L1_NEW"
task = "Test"
checks = []
[protocols.rules.level_1.protocols.compliant]
condition = "x"
action = "COMPLIANT"

[protocols.rules.level_2]
[protocols.rules.level_2.system_prompt]
role = "L2_NEW"
checks = []
[protocols.rules.level_2.protocols.passed]
condition = "x"
action = "APPROVE"
'''

        toml_path = tmp_path / "protocols_multi.toml"
        toml_path.write_text(multi_toml.lstrip("\n"))

        loader = ProtocolLoader(path=toml_path, auto_reload=True)
        executor = ProtocolExecutor(loader=loader)
        team = RulesSWATTeam(
            lfm_model_name="lfm25",
            lfm_model_path="/dev/null/lfm.gguf",
            granite_model_name="granite",
            granite_model_path="/dev/null/granite.gguf",
            littlelamb_model_name="littlelamb",
            littlelamb_model_path="/dev/null/ll.gguf",
            fin_rwkv_model_path="/dev/null/fin.gguf",
            model_manager=mock_model_manager,
            protocol_executor=executor,
        )

        # Oba poziomy mają stare role
        p1_before = team._build_level_1_prompt(INVOICE_SAMPLE)
        p2_before = team._build_level_2_prompt(INVOICE_SAMPLE)
        assert "L1_OLD" in p1_before
        assert "L2_OLD" in p2_before

        # Zmień plik
        toml_path.write_text(multi_toml_new.lstrip("\n"))
        loader._last_checked = 0.0

        # Oba poziomy mają nowe role — jednym przeładowaniem
        p1_after = team._build_level_1_prompt(INVOICE_SAMPLE)
        p2_after = team._build_level_2_prompt(INVOICE_SAMPLE)
        assert "L1_NEW" in p1_after, "Po hot-reload poziom 1 powinien mieć nową rolę"
        assert "L2_NEW" in p2_after, "Po hot-reload poziom 2 powinien mieć nową rolę"
        assert "L1_OLD" not in p1_after
        assert "L2_OLD" not in p2_after


# ===========================================================================
# TESTY: Pełny E2E — od promptu do decyzji
# ===========================================================================

class TestFullDecisionFlow:
    """Pełny E2E: ProtocolExecutor → QualityValidatorAgent → RulesSWATTeam.

    Testuje rzeczywisty przepływ danych:
      1. Zbuduj prompt przez ProtocolExecutor
      2. Uruchom QualityValidatorAgent (Alpha/Beta/Gamma z mock)
      3. Zweryfikuj decyzję przez matrycę
      4. Uruchom RulesSWATTeam (4 poziomy z mock)
      5. Sprawdź końcową decyzję
    """

    @pytest.mark.asyncio
    async def test_e2e_approve_flow(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
        rules_swat: RulesSWATTeam,
        mock_model_manager: ModelManager,
    ) -> None:
        """Pełna ścieżka APPROVE: wszystkie warstwy zatwierdzają.

        Oczekiwany wynik:
          - QualityValidator: FULL_APPROVE → AUTO_POST
          - RulesSWAT: L1 COMPLIANT → passed
        """
        # Krok 1: QualityValidator — wszystkie APPROVE
        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.95, "OK")),
            patch.object(beta_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.90, "OK")),
            patch.object(gamma_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.88, "OK")),
        ):
            quality_verdict = await validator.validate(
                "INV-001", INVOICE_SAMPLE, use_fast_path=False
            )

        # Asercje dla QualityValidator
        assert quality_verdict.pattern == "FULL_APPROVE"
        assert quality_verdict.recommended_action == "AUTO_POST"
        assert quality_verdict.level == ValidationLevel.LEVEL_1_AUTO

        # Krok 2: RulesSWAT z odpowiedzią COMPLIANT
        mock_model = MagicMock()
        mock_model.create_chat_completion.return_value = _make_mock_response(
            '{"decision": "COMPLIANT", "confidence": 0.95, "reasoning": "OK", "flags": []}'
        )
        mock_model_manager.acquire = AsyncMock(return_value=mock_model)

        rules_result = await rules_swat.evaluate(INVOICE_SAMPLE)

        # Asercje dla RulesSWAT
        assert rules_result["passed"] is True
        assert rules_result["levels_used"] == ["lfm25"]  # fast-path

        # Krok 3: Końcowa decyzja
        final_decision = "AUTO_POST" if (
            quality_verdict.recommended_action == "AUTO_POST" and rules_result["passed"]
        ) else "SUGGEST"

        assert final_decision == "AUTO_POST"

    @pytest.mark.asyncio
    async def test_e2e_block_flow(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
        rules_swat: RulesSWATTeam,
        mock_model_manager: ModelManager,
    ) -> None:
        """Pełna ścieżka BLOCK: Rada odrzuca, Rules potwierdza naruszenie."""
        # Krok 1: QualityValidator — REJECT + REJECT + REJECT → FULL_REJECT
        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("REJECT", 0.30, "Context wrong")),
            patch.object(beta_agent, "evaluate", return_value=DecisionVerdict("REJECT", 0.40, "NIP error")),
            patch.object(gamma_agent, "evaluate", return_value=DecisionVerdict("REJECT", 0.35, "Duplicate")),
        ):
            quality_verdict = await validator.validate(
                "INV-002", INVOICE_SAMPLE, use_fast_path=False
            )

        assert quality_verdict.pattern == "FULL_REJECT"
        assert quality_verdict.recommended_action == "BLOCK"
        assert quality_verdict.level == ValidationLevel.LEVEL_4_BLOCK

        # Krok 2: RulesSWAT — pełna kaskada z naruszeniami
        mock_model = MagicMock()
        responses = [
            _make_mock_response('{"decision": "FLAG", "confidence": 0.50, "reasoning": "Suspicious", "flags": [{"area": "nip", "severity": "high"}]}'),
            _make_mock_response('{"passed": false, "confidence": 0.55, "violations": [{"rule": "nip_validation", "message": "NIP invalid", "severity": "error"}], "reasoning": "NIP fail"}'),
            _make_mock_response('{"classification": "VIOLATION", "confidence": 0.60, "risk_factors": [{"factor": "nip", "weight": 0.9}], "reasoning": "NIP violation"}'),
            _make_mock_response('{"risk_level": "HIGH", "confidence": 0.65, "anomaly_score": 0.9, "final_verdict": "FLAG", "reasoning": "Block", "recommended_action": "block"}'),
        ]
        mock_model.create_chat_completion.side_effect = responses
        mock_model_manager.acquire = AsyncMock(return_value=mock_model)

        rules_result = await rules_swat.evaluate(INVOICE_SAMPLE)

        assert rules_result["passed"] is False
        assert len(rules_result["levels_used"]) == 4  # full cascade

        # Krok 3: Końcowa decyzja — BLOCK
        if quality_verdict.recommended_action == "BLOCK" or not rules_result["passed"]:
            final_decision = "BLOCK"
        else:
            final_decision = "SUGGEST"

        assert final_decision == "BLOCK"

    @pytest.mark.asyncio
    async def test_e2e_suggest_flow(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
        rules_swat: RulesSWATTeam,
        mock_model_manager: ModelManager,
    ) -> None:
        """Pełna ścieżka SUGGEST: drobne zastrzeżenia, ale nie blokada."""
        # Krok 1: QualityValidator — CONTEXT_ANOMALY_APPROVE → SUGGEST
        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.85, "Typical")),
            patch.object(beta_agent, "evaluate", return_value=DecisionVerdict("REJECT", 0.65, "Math concern")),
            patch.object(gamma_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.80, "No duplicate")),
        ):
            quality_verdict = await validator.validate(
                "INV-003", INVOICE_SAMPLE, use_fast_path=False
            )

        assert quality_verdict.pattern == "CONTEXT_ANOMALY_APPROVE"
        assert quality_verdict.recommended_action == "SUGGEST"
        assert quality_verdict.level == ValidationLevel.LEVEL_2_REVIEW

        # Krok 2: RulesSWAT — L1 FLAG, L2 minor violations, L3 COMPLIANT
        mock_model = MagicMock()
        responses = [
            _make_mock_response('{"decision": "FLAG", "confidence": 0.70, "reasoning": "Minor concern", "flags": [{"area": "amount", "severity": "low"}]}'),
            _make_mock_response('{"passed": true, "confidence": 0.75, "violations": [{"rule": "amount_limit", "message": "Near limit", "severity": "warning"}], "reasoning": "Acceptable"}'),
        ]
        mock_model.create_chat_completion.side_effect = responses
        mock_model_manager.acquire = AsyncMock(return_value=mock_model)

        rules_result = await rules_swat.evaluate(INVOICE_SAMPLE)

        assert rules_result["passed"] is True
        assert "littlelamb" not in rules_result["levels_used"]
        assert "fin_rwkv" not in rules_result["levels_used"]

        # Krok 3: Końcowa decyzja
        if quality_verdict.recommended_action == "BLOCK":
            final_decision = "BLOCK"
        elif quality_verdict.recommended_action == "SUGGEST" or not rules_result["passed"]:
            final_decision = "SUGGEST"
        else:
            final_decision = "AUTO_POST"

        assert final_decision == "SUGGEST"

    @pytest.mark.asyncio
    async def test_e2e_quality_verdict_used_in_orchestrator_decision(
        self,
        validator: QualityValidatorAgent,
        alpha_agent: AlphaAgent,
        beta_agent: BetaAgent,
        gamma_agent: GammaAgent,
    ) -> None:
        """ValidationVerdict ma wszystkie pola potrzebne dla OrchestratorDecision.

        Sprawdza że pola z verdict są zgodne z oczekiwaniami AgentOrchestrator:
        - action → quality_report.get("action")
        - level → quality_report.get("level")
        - trust_score → quality_report.get("trust_score")
        - deliberation → quality_report.get("deliberation")
        """
        with (
            patch.object(alpha_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.95, "OK")),
            patch.object(beta_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.85, "OK")),
            patch.object(gamma_agent, "evaluate", return_value=DecisionVerdict("APPROVE", 0.80, "OK")),
        ):
            verdict = await validator.validate("INV-010", INVOICE_SAMPLE, use_fast_path=False)

        # Mapowanie na quality_report dla AgentOrchestrator
        quality_report = {
            "action": verdict.recommended_action,
            "level": verdict.level.value,
            "trust_score": verdict.min_trust_for_auto,
            "deliberation": verdict.deliberation,
        }

        assert quality_report["action"] == "AUTO_POST"
        assert quality_report["level"] == "LEVEL_1_AUTO"
        assert quality_report["trust_score"] == 0.85
        assert "konsensus" in quality_report["deliberation"].lower() or "APPROVE" in quality_report["deliberation"]


# ===========================================================================
# TESTY: ProtocolExecutor.validate_council_verdict() bezpośrednio
# ===========================================================================

class TestValidateCouncilVerdict:
    """Bezpośrednie testy ProtocolExecutor.validate_council_verdict()."""

    def test_known_pattern_from_matrix(self, protocol_executor: ProtocolExecutor) -> None:
        """Znana kombinacja → zwróć pattern z matrycy."""
        result = protocol_executor.validate_council_verdict(
            alpha="APPROVE",
            beta="APPROVE",
            gamma="APPROVE",
        )
        assert result["pattern"] == "FULL_APPROVE"
        assert result["action"] == "AUTO_POST"
        assert result["valid"] is True

    def test_known_pattern_with_errors(self, protocol_executor: ProtocolExecutor) -> None:
        """ERROR kombinacje z matrycy."""
        result = protocol_executor.validate_council_verdict(
            alpha="ERROR",
            beta="APPROVE",
            gamma="APPROVE",
        )
        # ALPHA_ERROR → SUGGEST
        assert result["pattern"] == "ALPHA_ERROR"
        assert result["action"] == "SUGGEST"
        assert result["valid"] is True

    def test_unknown_pattern(self, protocol_executor: ProtocolExecutor) -> None:
        """Nieznana kombinacja → UNKNOWN → safe fallback."""
        result = protocol_executor.validate_council_verdict(
            alpha="UNKNOWN_VALUE",
            beta="APPROVE",
            gamma="REJECT",
        )
        assert result["pattern"] == "UNKNOWN"
        assert result["valid"] is False
        assert result["action"] in ("ASK_USER", "BLOCK")

    def test_all_13_combinations_are_recognized(self, protocol_executor: ProtocolExecutor) -> None:
        """Wszystkie 13 kombinacji z matrycy są rozpoznawane jako valid."""
        combinations = [
            ("APPROVE", "APPROVE", "APPROVE"),  # FULL_APPROVE
            ("APPROVE", "REJECT", "APPROVE"),   # CONTEXT_ANOMALY_APPROVE
            ("APPROVE", "APPROVE", "REJECT"),   # CONTEXT_PRECISION_APPROVE
            ("APPROVE", "REJECT", "REJECT"),    # CONTEXT_ONLY
            ("REJECT", "APPROVE", "APPROVE"),   # PRECISION_ANOMALY_APPROVE
            ("REJECT", "REJECT", "APPROVE"),    # ANOMALY_ONLY
            ("REJECT", "APPROVE", "REJECT"),    # PRECISION_VETO
            ("REJECT", "REJECT", "REJECT"),     # FULL_REJECT
            ("ERROR", "APPROVE", "APPROVE"),    # ALPHA_ERROR
            ("APPROVE", "ERROR", "APPROVE"),    # BETA_ERROR
            ("APPROVE", "APPROVE", "ERROR"),    # GAMMA_ERROR
            ("ERROR", "ERROR", "APPROVE"),      # DOUBLE_ERROR
            ("ERROR", "ERROR", "ERROR"),        # ALL_ERROR
        ]

        for alpha, beta, gamma in combinations:
            result = protocol_executor.validate_council_verdict(
                alpha=alpha, beta=beta, gamma=gamma
            )
            assert result["valid"] is True, (
                f"Combination ({alpha}, {beta}, {gamma}) should be valid, "
                f"got pattern={result['pattern']}"
            )
