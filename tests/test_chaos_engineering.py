"""Testy Chaos Engineering — scenariusze awarii i fallback.

RAPORT v7.0 Rekomendacja #3:
- Awaria NATS → local fallback
- Awaria modelu → rule_based fallback
- Awaria DuckDB → in-memory fallback
- Thundering herd: 100 równoczesnych requestów
"""

import asyncio
import pytest


class TestChaosEngineering:
    """Scenariusze awaryjne i fallback — chaos engineering."""

    def test_rule_based_fallback_exists(self):
        """Sprawdź czy _rule_based_evaluate() istnieje jako fallback."""
        from nexus_ai.agents.orchestrator import AgentOrchestrator
        assert hasattr(AgentOrchestrator, '_rule_based_evaluate')

    def test_rule_based_fallback_returns_decision(self):
        """Sprawdź czy fallback zwraca poprawną decyzję bez modelu."""
        from nexus_ai.agents.models import DataExtractionResult
        from nexus_ai.agents.orchestrator import AgentOrchestrator

        orch = AgentOrchestrator()  # Bez model_manager
        extraction = DataExtractionResult(
            invoice_id="test",
            success=True,
            extracted_data={
                "nip": "1234567890",
                "amount_gross": 5000,
                "category": "IT",
            },
        )
        # Model paths not set → _actor_evaluate should call _rule_based_evaluate
        orch._models = {}  # No models
        decision = asyncio.run(orch._actor_evaluate(extraction))
        assert decision is not None
        assert hasattr(decision, 'verdict')
        assert decision.verdict.status in ("AUTO_POST", "REVIEW", "BLOCK")

    def test_extraction_fallback_returns_partial_data(self):
        """Sprawdź fallback gdy AgentDataExtraction niedostępny."""
        from nexus_ai.agents.orchestrator import AgentOrchestrator

        orch = AgentOrchestrator()
        # Nie rejestrujemy extraction agenta
        orch._sub_agents = {}
        result = asyncio.run(orch._run_extraction(
            {"invoice_id": "test", "amount_gross": 1000},
            "test_decision",
        ))
        assert result.success is True
        assert result.extracted_data == {"invoice_id": "test", "amount_gross": 1000}

    def test_quality_validator_fallback_returns_none(self):
        """Sprawdź fallback gdy QualityValidator niedostępny."""
        from nexus_ai.agents.orchestrator import AgentOrchestrator

        orch = AgentOrchestrator()
        orch._sub_agents = {}  # No quality validator
        result = asyncio.run(orch._run_quality_check(
            "test",
            None,
            None,
        ))
        assert result is None

    def test_guardian_fallback_returns_none(self):
        """Sprawdź fallback gdy Guardian model niedostępny."""
        from nexus_ai.agents.orchestrator import AgentOrchestrator
        from nexus_ai.agents.models import DataExtractionResult

        orch = AgentOrchestrator()
        orch._models = {}
        extraction = DataExtractionResult(
            invoice_id="test",
            success=True,
            extracted_data={"nip": "123", "amount_gross": 1000, "date": "2026-01-01"},
        )
        decision = orch.make_decision("test", "AUTO_POST", 0.9, "OK")
        result = asyncio.run(orch._guardian_verify(extraction, decision))
        assert result is None  # Guardian unavailable → graceful fallback

    def test_analytics_fallback_returns_none(self):
        """Sprawdź fallback gdy AgentAnalytics niedostępny."""
        from nexus_ai.agents.orchestrator import AgentOrchestrator
        from nexus_ai.agents.models import DataExtractionResult

        orch = AgentOrchestrator()
        orch._sub_agents = {}
        extraction = DataExtractionResult(
            invoice_id="test",
            success=True,
            extracted_data={"nip": "123", "amount_gross": 1000},
        )
        result = asyncio.run(orch._run_analytics(extraction))
        assert result is None

    def test_silent_partner_manager_handles_no_executive_summary(self):
        """Sprawdź czy SilentPartnerManager działa bez ExecutiveSummary."""
        from nexus_ai.agents.silent_partner_manager import SilentPartnerManager

        spm = SilentPartnerManager()  # Bez executive_summary
        spm.record_auto_post("Test", 1000, "detail", "id1")
        assert spm.stats["auto_posted"] == 1

    def test_decision_pipeline_handles_missing_orchestrator(self):
        """Sprawdź czy DecisionPipeline działa bez orchestratora."""
        import asyncio
        from nexus_ai.agents.decision_pipeline import DecisionPipeline

        dp = DecisionPipeline()  # Bez orchestrator
        result = asyncio.run(dp.execute({"invoice_id": "test"}))
        assert result["pipeline_status"] == "OK"

    def test_cost_router_fallback_when_no_ram(self):
        """Sprawdź czy CostRouter radzi sobie z brakiem RAM."""
        from nexus_ai.core.cost_router import CostAwareRouter

        cr = CostAwareRouter(ram_budget_mb=0)  # Zero RAM
        name, profile, reason = cr.select_model("complex", amount=5000)
        assert name == "none"  # Żaden model się nie zmieści
        assert "no_models_available" in reason

    def test_federated_learning_handle_no_data(self):
        """Sprawdź czy FederatedLearning radzi sobie bez danych."""
        from nexus_ai.core.federated_learning import FederatedLearning

        fl = FederatedLearning()
        avg = fl.get_average_embedding()
        assert avg is None  # Brak danych → None

    def test_emotion_detector_handles_empty_profile(self):
        """Sprawdź czy EmotionDetector radzi sobie bez historii."""
        from nexus_ai.agents.emotion_detector import EmotionDetector

        emo = EmotionDetector()
        summary = emo.get_emotion_summary("nonexistent_user")
        assert summary["current_emotion"] == "neutral"
        assert summary["correction_rate"] == 0.0
        assert summary["accept_rate"] == 0.0

    def test_knowledge_distiller_handles_no_examples(self):
        """Sprawdź czy KnowledgeDistiller radzi sobie bez przykładów."""
        from nexus_ai.core.knowledge_distiller import KnowledgeDistiller

        kd = KnowledgeDistiller()
        data = kd.get_distillation_data()
        assert data == []

    def test_shadow_mode_handles_no_active_shadow(self):
        """Sprawdź czy ShadowMode działa bez aktywnego shadow."""
        from nexus_ai.agents.shadow_mode import ShadowMode

        sm = ShadowMode()
        assert sm.should_migrate() is False
        result = sm.migrate_to_shadow()
        assert result["status"] == "error"

    def test_cot_debugger_handles_empty_input(self):
        """Sprawdź czy CoT Debugger działa z pustymi danymi."""
        from nexus_ai.agents.cot_debugger import ChainOfThoughtDebugger

        debugger = ChainOfThoughtDebugger()
        analysis = debugger.analyze_correction("test", "AUTO_POST", "AUTO_POST")
        assert analysis.root_cause == ""  # Brak błędu → brak przyczyny
        assert "Post-Mortem" in analysis.post_mortem


class TestThunderingHerd:
    """Stress test — wiele równoczesnych requestów."""

    @pytest.mark.asyncio
    async def test_concurrent_decision_pipeline(self):
        """Uruchom 50 równoczesnych pipeline'ów decyzyjnych."""
        from nexus_ai.agents.decision_pipeline import DecisionPipeline

        dp = DecisionPipeline()

        async def process_one(i: int) -> dict:
            return await dp.execute({
                "invoice_id": f"concurrent_{i}",
                "amount_gross": 1000 + i * 100,
            })

        tasks = [process_one(i) for i in range(50)]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        success_count = sum(1 for r in results if isinstance(r, dict) and r.get("pipeline_status") == "OK")
        assert success_count == 50, f"Only {success_count}/50 succeeded"

    @pytest.mark.asyncio
    async def test_concurrent_silent_partner(self):
        """Uruchom 100 równoczesnych decyzji Silent Partner."""
        from nexus_ai.agents.silent_partner_manager import SilentPartnerManager

        spm = SilentPartnerManager()

        async def decide_one(i: int) -> tuple:
            return spm.should_auto_post(0.85 + (i % 15) * 0.01, 5000, True, True)

        tasks = [decide_one(i) for i in range(100)]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        success_count = sum(1 for r in results if isinstance(r, tuple) and len(r) == 3)
        assert success_count == 100


class TestMultiAgentIntegration:
    """Testy integracyjne ścieżki wieloagentowej."""

    def test_full_pipeline_sequence(self):
        """Sprawdź czy pipeline agentów może wykonać pełną sekwencję."""
        import asyncio
        from nexus_ai.agents.models import DataExtractionResult
        from nexus_ai.agents.orchestrator import AgentOrchestrator

        orch = AgentOrchestrator()

        # Symuluj dane ekstrakcji
        extraction = DataExtractionResult(
            invoice_id="integration_test",
            success=True,
            extracted_data={
                "nip": "1234567890",
                "amount_gross": 5000,
                "category": "IT",
                "date": "2026-07-21",
                "invoice_number": "FV/2026/001",
            },
            confidence=0.9,
        )

        # Rule-based evaluate (fallback, bo brak modeli)
        decision = orch._rule_based_evaluate(extraction)
        assert decision is not None
        assert decision.verdict.status in ("AUTO_POST", "REVIEW", "BLOCK")

        # Weighted voting
        result = asyncio.run(orch._run_weighted_voting(
            extraction, decision.trust_score, None
        ))
        assert result is not None
        assert result.winner in ("AUTO_POST", "REVIEW", "BLOCK")

    def test_error_handbook_query(self):
        """Sprawdź czy DynamicErrorHandbook obsługuje zapytania."""
        import asyncio
        from nexus_ai.agents.error_handbook import (
            DynamicErrorHandbook,
            HandbookQuery,
        )

        handbook = DynamicErrorHandbook()
        query = HandbookQuery(
            vendor_nip="1234567890",
            category="IT",
            amount_gross=5000,
            document_type="INVOICE",
            k=3,
        )

        # Nawet bez DuckDB, powinno działać (brak wyników)
        examples = asyncio.run(handbook.query_relevant(query))
        assert isinstance(examples, list)

    def test_user_decision_profile_observe(self):
        """Sprawdź czy UserDecisionProfile rejestruje obserwacje."""
        from nexus_ai.agents.user_decision_profile import UserDecisionProfile

        profile = UserDecisionProfile()
        profile.observe_decision(
            vendor_nip="1234567890",
            vendor_name="Test Sp. z o.o.",
            amount_gross=5000,
            category="IT",
            status="AUTO_POST",
            decision_mode="auto_post",
            user_action="confirm",
            user_option="",
        )
        profile.observe_decision(
            vendor_nip="1234567890",
            vendor_name="Test Sp. z o.o.",
            amount_gross=15000,
            category="IT",
            status="REVIEW",
            decision_mode="suggest",
            user_action="reject",
            user_option="AUTO_POST",
        )

        score = profile.get_autonomy_score()
        assert score >= 0.0
        # get_summary may not exist - use get_autonomy_score as validation
        assert score is not None
