from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads, msgspec_dumps_bytes
"""
Testy dla Council Agents — ModelManager, DecisionVerdict, BaseCouncilAgent.

Sprawdza:
  - DecisionVerdict tworzenie, serializacja, from_json z różnymi formatami
  - ModelManager (mockowany, bo wymaga llama_cpp)
  - Agent configuration (Alpha, Beta, Gamma prompt building)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from nexus_ai.services.council_agents import (
    DecisionVerdict,
    AlphaAgent,
    BetaAgent,
    GammaAgent,
    ALPHA_SYSTEM_PROMPT,
    BETA_SYSTEM_PROMPT,
    GAMMA_SYSTEM_PROMPT,
)


# ---------------------------------------------------------------------------
# DecisionVerdict Tests
# ---------------------------------------------------------------------------

class TestDecisionVerdict:
    """Testy dla DecisionVerdict — konstrukcja, serializacja, parsowanie."""

    def test_create_approve_verdict(self) -> None:
        v = DecisionVerdict(
            decision="APPROVE",
            confidence=0.95,
            reasoning="All looks good",
            suggested_action="auto_post",
        )
        assert v.decision == "APPROVE"
        assert v.confidence == 0.95
        assert v.reasoning == "All looks good"
        assert v.suggested_action == "auto_post"

    def test_create_reject_verdict(self) -> None:
        v = DecisionVerdict(
            decision="REJECT",
            confidence=0.4,
            reasoning="Amount anomaly detected",
        )
        assert v.decision == "REJECT"
        assert v.confidence == 0.4
        assert v.suggested_action == ""

    def test_error_verdict(self) -> None:
        v = DecisionVerdict.error("Model crashed")
        assert v.decision == "ERROR"
        assert v.confidence == 0.0
        assert v.reasoning == "Model crashed"

    def test_error_verdict_default_reason(self) -> None:
        v = DecisionVerdict.error()
        assert v.decision == "ERROR"
        assert v.reasoning == "Agent error"

    def test_to_dict(self) -> None:
        v = DecisionVerdict("APPROVE", 0.9, "Test", "auto_post")
        d = v.to_dict()
        assert d["decision"] == "APPROVE"
        assert d["confidence"] == 0.9
        assert d["reasoning"] == "Test"
        assert d["suggested_action"] == "auto_post"

    def test_from_json_valid(self) -> None:
        raw = msgspec_dumps({
            "decision": "APPROVE",
            "confidence": 0.88,
            "reasoning": "Standard invoice",
            "suggested_action": "auto_post",
        })
        v = DecisionVerdict.from_json(raw)
        assert v.decision == "APPROVE"
        assert v.confidence == 0.88
        assert v.reasoning == "Standard invoice"
        assert v.suggested_action == "auto_post"

    def test_from_json_with_extra_fields(self) -> None:
        """Extra fields w JSON nie powinny powodować błędów."""
        raw = msgspec_dumps({
            "decision": "REJECT",
            "confidence": 0.3,
            "reasoning": "VAT mismatch",
            "errors": ["VAT 23% expected, got 8%"],
        })
        v = DecisionVerdict.from_json(raw)
        assert v.decision == "REJECT"
        assert v.confidence == 0.3

    def test_from_json_missing_fields(self) -> None:
        """Brakujące pola powinny mieć bezpieczne domyślne wartości."""
        raw = msgspec_dumps({"decision": "APPROVE"})
        v = DecisionVerdict.from_json(raw)
        assert v.decision == "APPROVE"
        assert v.confidence == 0.0
        assert v.reasoning == ""

    def test_from_json_within_code_block(self) -> None:
        """JSON może być opakowany w ```json ... ```."""
        raw = "```json\n{\"decision\": \"APPROVE\", \"confidence\": 0.95, \"reasoning\": \"OK\"}\n```"
        v = DecisionVerdict.from_json(raw)
        assert v.decision == "APPROVE"
        assert v.confidence == 0.95

    def test_from_json_invalid_returns_error(self) -> None:
        """Nieprawidłowy JSON → ERROR."""
        v = DecisionVerdict.from_json("not json at all")
        assert v.decision == "ERROR"
        assert v.confidence == 0.0

    def test_from_json_partial_extraction(self) -> None:
        """JSON osadzony w tekście powinien być ekstrahowany."""
        raw = "Here is my analysis: {\"decision\": \"REJECT\", \"confidence\": 0.5, \"reasoning\": \"Sus\"} END"
        v = DecisionVerdict.from_json(raw)
        assert v.decision == "REJECT"
        assert v.confidence == 0.5

    def test_slots_defined(self) -> None:
        """DecisionVerdict używa __slots__ dla oszczędności pamięci."""
        v = DecisionVerdict("APPROVE", 0.9, "OK")
        assert hasattr(v, "decision")
        assert hasattr(v, "confidence")
        assert hasattr(v, "reasoning")
        assert hasattr(v, "suggested_action")
        with pytest.raises(AttributeError):
            v.non_existent_attr  # type: ignore[attr-defined]


# ---------------------------------------------------------------------------
# Agent Prompt Tests
# ---------------------------------------------------------------------------

class TestAgentPrompts:
    """Testy dla build_prompt w każdym agencie."""

    @pytest.fixture
    def sample_invoice(self) -> dict:
        return {
            "invoice_id": "inv-001",
            "contractor_nip": "1234567890",
            "amount_net": 1000.0,
            "vat": 230.0,
            "amount_gross": 1230.0,
            "issue_date": "2025-01-15",
            "number": "FV/2025/001",
            "contractor": {"name": "Test sp. z o.o.", "known": True},
            "category": "usługi",
            "amount_threshold": 10000,
            "historical_average": 950.0,
            "vendor_invoice_count": 15,
        }

    def test_alpha_prompt_contains_required_fields(self, sample_invoice: dict) -> None:
        """Prompt Alpha zawiera wszystkie wymagane pola faktury."""
        from services.council_agents import ModelManager

        mm = ModelManager()
        agent = AlphaAgent("alpha-test", "/fake/path", mm)
        prompt = agent.build_prompt(sample_invoice)

        assert ALPHA_SYSTEM_PROMPT in prompt
        assert "1234567890" in prompt  # NIP
        assert "1000" in prompt  # amount_net
        assert "1230" in prompt  # amount_gross
        assert "FV/2025/001" in prompt  # invoice number
        assert "Test sp. z o.o." in prompt  # contractor name
        assert "usługi" in prompt  # category

    def test_beta_prompt_contains_validation_fields(self, sample_invoice: dict) -> None:
        """Prompt Beta zawiera dane do walidacji."""
        from services.council_agents import ModelManager

        mm = ModelManager()
        agent = BetaAgent("beta-test", "/fake/path", mm)
        prompt = agent.build_prompt(sample_invoice)

        assert BETA_SYSTEM_PROMPT in prompt
        assert "1234567890" in prompt  # NIP
        assert "1000" in prompt  # netto
        assert "230" in prompt  # VAT
        assert "1230" in prompt  # brutto
        assert "10000" in prompt  # threshold

    def test_gamma_prompt_contains_anomaly_fields(self, sample_invoice: dict) -> None:
        """Prompt Gamma zawiera dane do analizy anomalii."""
        from services.council_agents import ModelManager

        mm = ModelManager()
        agent = GammaAgent("gamma-test", "/fake/path", mm)
        prompt = agent.build_prompt(sample_invoice)

        assert GAMMA_SYSTEM_PROMPT in prompt
        assert "inv-001" in prompt  # invoice_id
        assert "1230" in prompt  # amount_gross
        assert "950" in prompt  # historical_average
        assert "15" in prompt  # vendor_invoice_count

    def test_alpha_prompt_with_unknown_contractor(self) -> None:
        """Alpha prompt z nieznanym kontrahentem."""
        from services.council_agents import ModelManager

        mm = ModelManager()
        agent = AlphaAgent("alpha-test", "/fake/path", mm)
        invoice = {
            "contractor_nip": "9999999999",
            "amount_net": 50000.0,
            "amount_gross": 61500.0,
            "vat": 11500.0,
            "issue_date": "2025-06-01",
            "number": "FV/999",
            "contractor": {"name": "Unknown Corp", "known": False},
            "category": "doradztwo",
        }
        prompt = agent.build_prompt(invoice)
        assert "nie" in prompt  # "czy kontrahent znany: nie"
        assert "Unknown Corp" in prompt
        assert "doradztwo" in prompt


# ---------------------------------------------------------------------------
# ModelManager Tests (mocked — no real llama_cpp)
# ---------------------------------------------------------------------------

class TestModelManager:
    """Testy dla ModelManager — lifecycle, TTL, locking."""

    def test_initial_state(self) -> None:
        from services.council_agents import ModelManager

        mm = ModelManager()
        assert mm.current_model_name is None
        assert not mm.is_locked

    def test_acquire_release_lifecycle(self) -> None:
        """ModelManager.acquire/release z mockowanym Llama."""
        import asyncio
        from unittest.mock import patch, AsyncMock
        from services.council_agents import ModelManager

        mm = ModelManager()

        async def run():
            # Pierwsze acquire — powinno załadować model
            mock_llama = AsyncMock()
            mock_llama.create_chat_completion.return_value = {
                "choices": [{"message": {"content": '{"decision": "APPROVE", "confidence": 0.9, "reasoning": "OK"}'}}]
            }

            with patch.object(mm, "_load_model", return_value=mock_llama):
                model = await mm.acquire("test-model", "/fake/path.gguf")
                assert model is mock_llama
                assert mm.current_model_name == "test-model"

                # Release
                await mm.release()
                assert mm.current_model_name is None

        asyncio.run(run())

    def test_ttl_reuse(self) -> None:
        """Model powinien być reuse'owany w ramach TTL."""
        import asyncio
        from unittest.mock import patch
        from services.council_agents import ModelManager

        mm = ModelManager()

        async def run():
            mock_llama = object()
            load_count = 0

            def _load(path: str):
                nonlocal load_count
                load_count += 1
                return mock_llama

            with patch.object(mm, "_load_model", side_effect=_load):
                # Pierwsze acquire
                m1 = await mm.acquire("test-model", "/fake/path.gguf")
                assert m1 is mock_llama
                assert load_count == 1

                # Drugie acquire — w ramach TTL powinno reuse'ować
                m2 = await mm.acquire("test-model", "/fake/path.gguf")
                assert m2 is mock_llama
                assert load_count == 1  # nie załadowało ponownie

        asyncio.run(run())

    def test_different_model_triggers_reload(self) -> None:
        """Inny model_name powinien wymusić przeładowanie."""
        import asyncio
        from unittest.mock import patch
        from services.council_agents import ModelManager

        mm = ModelManager()

        async def run():
            load_count = 0

            def _load(path: str):
                nonlocal load_count
                load_count += 1
                return object()

            with patch.object(mm, "_load_model", side_effect=_load):
                await mm.acquire("model-a", "/path/a.gguf")
                assert load_count == 1

                await mm.acquire("model-b", "/path/b.gguf")
                assert load_count == 2  # przeładowane

        asyncio.run(run())
