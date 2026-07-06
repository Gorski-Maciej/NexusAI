"""AgentOrchestrator — Centralny Mózg i Wirtualny Dyrektor Finansowy.

Zgodnie z aa3fvcx.txt (5 agentów, JEDEN poziom automatyzacji):
- Granite 3.2 3B — Główny Decydent (Actor)
- Granite Guardian 0.5B — Strażnik Merytoryczny
- Qwen3-Nano 0.5B — Komunikator (kontakt z użytkownikiem)

JEDEN poziom automatyzacji:
- AUTO_POST (>=0.92): Agent księguje, użytkownik informowany.
- SUGGEST  (>=0.75): Agent proponuje, użytkownik zatwierdza.
- ASK_USER (<0.75): Agent pyta użytkownika.

Enterprise features:
- Cognitive Audit Trail: samouzdrawiający się łańcuch dowodowy
- Dynamiczny Podręcznik Błędów: few-shot learning z DuckDB
- Adaptive Thresholds: Bayesian per-vendor
- Decision Cache: diskcache + sqlite-vec k-NN
- 4-Eyes Principle: obowiązkowy dla kwot > 50k PLN
- Weighted Voting: konsensus między agentami
- Proof Chain: SHA-256 każda decyzja
- Continuous Learning: pętla korekta → nauka
"""

from __future__ import annotations

import json
import uuid
from typing import Any

import pendulum
from msgspec import json as msgspec_json
from structlog import get_logger

from nexus_ai.agents.base import BaseAgent, DecisionCache
from nexus_ai.agents.error_handbook import DynamicErrorHandbook, HandbookQuery
from nexus_ai.agents.knowledge_mesh import KnowledgeMesh
from nexus_ai.agents.models import RouteDecision
from nexus_ai.agents.decision_trace import (
    ConfidenceCalibrator,
    DecisionTracer,
    EnsembleVote,
    FeedbackLoop,
    MultiModelEnsemble,
)
from nexus_ai.agents.telemetry_store import AgentTelemetryStore
from nexus_ai.agents.models import (
    ActionCardFeed,
    ActionCardResponse,
    AgentDecision,
    AnalyticsQuery,
    AnalyticsResult,
    ConfidenceVote,
    ContextDimension,
    DashboardState,
    DataExtractionRequest,
    DataExtractionResult,
    DecisionMode,
    ExecutiveSummary,
    FeedbackType,
    QualityCheckRequest,
    QualityCheckResult,
    StrategicMode,
    TrustScore,
    VotingResult,
    make_context,
)
from nexus_ai.agents.proactive_workflow import (
    ActionCardGenerator,
    ProactiveWorkflowScheduler,
    WorkflowType,
)
from nexus_ai.agents.user_decision_profile import (
    UserDecisionProfile,
    WeeklyAutonomyReport,
)
from nexus_ai.agents.topics import AgentTopic
from nexus_ai.core.inference import ModelManager

logger = get_logger("nexus.agents.orchestrator")


# ── GENIALNY POMYSŁ v6.0: Silent Partner ──────────────────────────

SILENT_PARTNER_ENABLED: bool = True
"""Czy Silent Partner v6.0 jest włączony. Gdy True, wszystkie workflow → AUTO_POST."""

SILENT_PARTNER_VERSION: str = "6.0.0-draft"
"""Wersja konceptu Silent Partner."""


# ── Wagi głosowania (Bayesian, aktualizowane) ──────────────────────────


DEFAULT_VOTING_WEIGHTS: dict[str, float] = {
    "orchestrator": 0.40,
    "quality_validator": 0.60,  # Niezależny audytor — najwyższa waga
}

FOUR_EYES_THRESHOLD: float = 50_000.0  # PLN
"""Kwota powyżej której wymagana jest 4-Eyes weryfikacja."""

MAX_AUTO_POST_AMOUNT: float = 100_000.0  # PLN
"""Maksymalna kwota dla AUTO_POST."""


class AgentOrchestrator(BaseAgent):
    """Agent Orkiestrator — centralny koordynator systemu agentów AI.

    Zarządza przepływem danych między agentami:
    DataExtraction → QualityValidator → Analytics → Final Decision

    Enterprise:
    - Adaptive thresholds per vendor
    - Decision cache (diskcache + sqlite-vec)
    - Dynamiczny Podręcznik Błędów (few-shot learning)
    - 4-Eyes principle
    - Weighted voting
    - Escalation matrix
    """

    def __init__(
        self,
        model_manager: ModelManager | None = None,
        config: dict[str, Any] | None = None,
        knowledge_mesh: KnowledgeMesh | None = None,
    ) -> None:
        super().__init__(
            name="orchestrator",
            model_manager=model_manager,
            config=config or {},
            knowledge_mesh=knowledge_mesh,
        )
        self._models: dict[str, str] = {}
        self._pending_decisions: dict[str, AgentDecision] = {}
        self._sub_agents: dict[str, BaseAgent] = {}
        self._voting_weights: dict[str, float] = dict(DEFAULT_VOTING_WEIGHTS)
        # ── GENIALNY POMYSŁ: Dynamiczny Podręcznik Błędów ──
        self._error_handbook = DynamicErrorHandbook()
        # ── GENIALNY POMYSŁ v5.0: Proaktywny Silnik Workflow ──
        self._proactive_scheduler = ProactiveWorkflowScheduler(
            orchestrator=self,
            config=self._config,
        )
        # ── GENIALNY POMYSŁ v5.1: ActionCardGenerator ("1-Click CFO") ──
        self._card_generator = ActionCardGenerator(orchestrator=self)
        # ── GENIALNY POMYSŁ v5.2: Progressive Autonomy Engine ──
        self._decision_profile = UserDecisionProfile()
        # ── GENIALNY POMYSŁ v5.3: Agent Knowledge Mesh (współdzielony) ──
        self._mesh_last_route: RouteDecision | None = None
        # ── GENIALNY POMYSŁ v5.4: Decision Protocol ──
        self._tracer = DecisionTracer()
        self._ensemble = MultiModelEnsemble()
        self._calibrator = ConfidenceCalibrator()
        self._feedback = FeedbackLoop()
        self._telemetry = AgentTelemetryStore()
        # ── GENIALNY POMYSŁ v6.0: Silent Partner ──
        from nexus_ai.agents.strategy_engine import StrategyEngine
        from nexus_ai.agents.executive_summary import ExecutiveSummaryGenerator
        self._strategy_engine = StrategyEngine(config=config)
        self._executive_summary = ExecutiveSummaryGenerator(orchestrator=self)
        self._silent_mode = config.get("silent_mode", True) if config else True
        self._silent_stats: dict[str, Any] = {
            "total_decisions": 0,
            "auto_posted": 0,
            "accept_all_count": 0,
            "time_saved_total_minutes": 0.0,
        }

    def register_agent(self, name: str, agent: BaseAgent) -> None:
        """Zarejestruj podległego agenta i propaguj KnowledgeMesh."""
        self._sub_agents[name] = agent
        # Propagate KnowledgeMesh (v5.4) — all agents share the mesh
        if self._knowledge_mesh and hasattr(agent, 'set_mesh'):
            agent.set_mesh(self._knowledge_mesh)
        logger.info("[ORCH] Registered sub-agent: %s (mesh=%s)",
                    name, bool(agent.mesh))

    async def start(self) -> None:
        """Inicjalizuj modele Orkiestratora, Podręcznik Błędów, KnowledgeMesh i ProactiveWorkflowScheduler."""
        await super().start()
        self._init_models()
        await self._error_handbook.initialize()
        # ── GENIALNY POMYSŁ v5.3: Knowledge Mesh ──
        if self._knowledge_mesh and not self._knowledge_mesh.is_initialized:
            await self._knowledge_mesh.initialize()
        await self._telemetry.initialize()
        await self._proactive_scheduler.start()
        mesh_stats = self._knowledge_mesh.get_stats() if self._knowledge_mesh else {"initialized": False}
        logger.info(
            "[ORCH] Orchestrator ready | models: %s | agents: %s | handbook: %d examples | mesh: %s | proactive workflows: %d | silent_mode=%s",
            self._models,
            list(self._sub_agents.keys()),
            self._error_handbook.count,
            mesh_stats,
            len(self._proactive_scheduler.WORKFLOW_SCHEDULE),
            self._silent_mode,
        )

    async def stop(self) -> None:
        """Zatrzymaj Orchestrator — zatrzymaj ProactiveWorkflowScheduler, KnowledgeMesh i zwolnij zasoby."""
        await self._proactive_scheduler.stop()
        if self._knowledge_mesh:
            await self._knowledge_mesh.close()
        await self._telemetry.close()
        await super().stop()
        logger.info("[ORCH] Orchestrator stopped")

    def _init_models(self) -> None:
        """Inicjalizuj ścieżki modeli z konfiguracji."""
        self._models = {
            "actor": self._config.get("orchestrator_actor_model", ""),
            "guardian": self._config.get("orchestrator_guardian_model", ""),
            "communicator": self._config.get("orchestrator_communicator_model", ""),
        }

    # ── GENIALNY POMYSŁ v5.4: Decision Protocol Properties ─────

    @property
    def tracer(self) -> DecisionTracer:
        return self._tracer

    @property
    def ensemble(self) -> MultiModelEnsemble:
        return self._ensemble

    @property
    def calibrator(self) -> ConfidenceCalibrator:
        return self._calibrator

    @property
    def feedback(self) -> FeedbackLoop:
        return self._feedback

    @property
    def telemetry(self) -> AgentTelemetryStore:
        return self._telemetry

    # ── GENIALNY POMYSŁ v6.0: Silent Partner Properties ─────

    @property
    def strategy_engine(self):
        """Continuous Strategy Engine v6.0."""
        return self._strategy_engine

    @property
    def executive_summary(self):
        """Executive Summary Generator v6.0."""
        return self._executive_summary

    @property
    def silent_mode(self) -> bool:
        """Czy Silent Partner v6.0 jest aktywny."""
        return self._silent_mode

    @silent_mode.setter
    def silent_mode(self, value: bool) -> None:
        """Włącz/wyłącz Silent Partner v6.0."""
        self._silent_mode = value
        logger.info("[ORCH] Silent Partner: %s", "ON" if value else "OFF")

    @property
    def silent_stats(self) -> dict[str, Any]:
        """Statystyki Silent Partner."""
        return dict(self._silent_stats)

    def get_feedback_summary(self) -> dict[str, Any]:
        """Pobierz podsumowanie pętli feedbacku."""
        return self._feedback.get_summary()

    async def get_telemetry_stats(self, days: int = 30) -> dict[str, Any]:
        """Pobierz statystyki telemetryczne."""
        return await self._telemetry.get_aggregate_stats(days)

    # ── GENIALNY POMYSŁ v5.2: Progressive Autonomy Engine ──────────

    @property
    def decision_profile(self) -> UserDecisionProfile:
        """Profil decyzyjny przedsiębiorcy — Progressive Autonomy Engine.

        GENIALNY POMYSŁ v5.2:
        Agent obserwuje wzorce decyzyjne i stopniowo przejmuje
        rutynowe decyzje. Cel: Decision Autonomy Score ≥ 90%.
        """
        return self._decision_profile

    def get_autonomy_score(self) -> float:
        """Pobierz aktualny Decision Autonomy Score (0-100%).

        AUTO_POST / (AUTO_POST + ASK_USER) × 100%
        """
        return self._decision_profile.get_autonomy_score()

    def get_silent_rate(self) -> float:
        """Pobierz aktualny Silent Rate v6.0 (cel: ≥95%).

        Silent Rate = auto_posted / total × 100%
        """
        stats = self._silent_stats
        total = stats.get("total_decisions", 0)
        if total == 0:
            return 100.0
        return (stats.get("auto_posted", 0) / total) * 100.0

    def get_decision_profile_summary(self) -> dict[str, Any]:
        """Pobierz podsumowanie profilu decyzyjnego."""
        return self._decision_profile.get_summary()

    def generate_weekly_autonomy_report(self) -> WeeklyAutonomyReport:
        """Generuj cotygodniowy raport autonomii.

        GENIALNY POMYSŁ v5.2:
        Przedsiębiorca widzi: "Przejąłem 73% decyzji, zaoszczędziłem 45 kliknięć"
        """
        return self._decision_profile.generate_weekly_report()

    # ── Główny proces decyzyjny ─────────────────────────────────────

    async def process_invoice(self, invoice_data: dict[str, Any]) -> AgentDecision:
        """Przetwórz fakturę przez pełny pipeline agentów.

        GENIALNY POMYSŁ v6.0 Silent Partner — Strategic Pipeline:
        - W trybie Silent: wszystkie decyzje AUTO_POST
        - Tylko wyjątki (niski trust, wysoka kwota) trafiają do SUGGEST
        - Każda decyzja dodawana do ExecutiveSummary

        Enterprise v5.4:
        1. DecisionTrace — OTel tracing całej decyzji
        2. KnowledgeMesh Predictive Routing
        3. AgentDataExtraction
        4. MultiModelEnsemble (≥3 modele + diversity check)
        5. ConfidenceCalibrator (Platt Scaling)
        6. QualityValidator (4-Eyes + Analytics)
        7. FeedbackLoop metryki
        8. AgentTelemetryStore
        """
        decision_id = uuid.uuid4().hex[:16]
        logger.info("[ORCH] Processing invoice %s | silent=%s | mode=%s",
                    decision_id, self._silent_mode,
                    self._strategy_engine.current_mode.value)

        # ── Decision Trace (v5.4) ────────────────────────────────
        vendor_nip_raw = invoice_data.get("nip", "unknown")
        gross_raw = invoice_data.get("amount_gross", 0)
        amount_raw = gross_raw if isinstance(gross_raw, (int, float)) else 0.0
        trace = self._tracer.start_trace(
            decision_id=decision_id,
            vendor_nip=vendor_nip_raw,
            amount_gross=amount_raw,
            category=invoice_data.get("category", ""),
            document_type=invoice_data.get("document_type", "INVOICE"),
        )
        trace_span = self._tracer.start_span(decision_id, "orchestrator.pipeline", self.name)

        # ── 1. Decision Cache: k-NN ────────────────────────────────
        cached_decision = await self._check_decision_cache(invoice_data)
        if cached_decision:
            logger.info("[ORCH] Decision cache HIT for %s | trust=%.2f",
                        decision_id, cached_decision.verdict.trust_score)
            self._tracer.end_span(decision_id, trace_span, {"cache": "HIT"})
            self._tracer.end_trace(decision_id, cached_decision.verdict.status,
                                    cached_decision.verdict.trust_score,
                                    cached_decision.decision_mode.value if cached_decision.decision_mode else "auto_post")
            return cached_decision

        # ── 1a. GENIALNY POMYSŁ v5.3: Predictive Task Routing ────
        vendor_nip = invoice_data.get("nip", "")
        gross_amount = invoice_data.get("amount_gross", 0)
        gross_amount_num = gross_amount if isinstance(gross_amount, (int, float)) else 0.0
        mesh_route = None
        if self._knowledge_mesh and self._knowledge_mesh.is_initialized:
            mesh_span = self._tracer.start_span(decision_id, "mesh.route", "knowledge-mesh")
            mesh_route = await self._knowledge_mesh.route(
                vendor_nip=vendor_nip or "unknown",
                amount=gross_amount_num,
                category=invoice_data.get("category", ""),
            )
            self._mesh_last_route = mesh_route
            self._tracer.end_span(decision_id, mesh_span,
                                   {"route": mesh_route.route, "trust": mesh_route.trust_score})
            # Record route telemetry
            await self._telemetry.record_route(
                decision_id=decision_id,
                vendor_nip=vendor_nip or "unknown",
                trust_score=mesh_route.trust_score,
                confidence=mesh_route.confidence,
                route=mesh_route.route,
                skip_agents=mesh_route.skip_agents,
                force_agents=mesh_route.force_agents,
                circuit_breaker_open=mesh_route.circuit_breaker_open,
                threshold_adjustments=mesh_route.threshold_adjustments,
                applied_rules_count=len(mesh_route.applied_rules),
                estimated_time_ms=mesh_route.estimated_time_ms,
            )
            logger.info(
                "[MESH] Route decided | NIP=%s | trust=%.2f | route=%s | skip=%s | cb=%s | est=%.0fms",
                (vendor_nip or "?" )[:8], mesh_route.trust_score,
                mesh_route.route, mesh_route.skip_agents,
                mesh_route.circuit_breaker_open, mesh_route.estimated_time_ms,
            )
            if mesh_route.circuit_breaker_open:
                self._tracer.end_span(decision_id, trace_span, {"circuit_breaker": "OPEN"})
                self._tracer.end_trace(decision_id, "BLOCK", mesh_route.trust_score, "ask_user")
                return self.make_decision(
                    decision_id=decision_id,
                    status="BLOCK",
                    trust_score=mesh_route.trust_score,
                    reason=f"Circuit Breaker otwarty dla NIP {vendor_nip} (trust={mesh_route.trust_score:.2f})",
                    explanation="Automatyczne księgowanie zablokowane — niski Trust Score dla tego kontrahenta.",
                    decision_mode=DecisionMode.ASK_USER,
                )

        # ── 2. Ekstrakcja danych ───────────────────────────────────
        extract_span = self._tracer.start_span(decision_id, "extraction", "extraction")
        extraction_result = await self._run_extraction(invoice_data, decision_id)
        self._tracer.end_span(decision_id, extract_span,
                               {"confidence": extraction_result.confidence},
                               "OK" if extraction_result.success else "ERROR",
                               extraction_result.error)
        if not extraction_result.success:
            self._tracer.end_span(decision_id, trace_span, {"error": "extraction_failed"})
            self._tracer.end_trace(decision_id, "BLOCK", 0.0, "ask_user")
            return self.make_decision(
                decision_id=decision_id,
                status="BLOCK",
                trust_score=0.0,
                reason=f"Ekstrakcja danych nie powiodła się: {extraction_result.error}",
                explanation="Nie udało się wyodrębnić danych z dokumentu. Wymagana ręczna weryfikacja.",
            )

        # ── 3. Określenie adaptacyjnych progów ─────────────────────
        vendor_nip = extraction_result.extracted_data.get("nip", "unknown")

        # GENIALNY POMYSŁ v5.3: Użyj routingu z KnowledgeMesh (jeśli nie było wcześniej)
        if mesh_route is None and self._knowledge_mesh and self._knowledge_mesh.is_initialized:
            mesh_route = await self._knowledge_mesh.route(
                vendor_nip=vendor_nip,
                amount=gross_amount,
                category=extraction_result.extracted_data.get("category", ""),
            )
            self._mesh_last_route = mesh_route

        # GENIALNY POMYSŁ v5.2: Progressive Autonomy — blend Bayesian + Profile
        # Bayesian: uczy się z poprawności AI. Profile: uczy się z preferencji usera.
        profile_threshold = self._decision_profile.get_adaptive_threshold(vendor_nip)
        auto_post_threshold = self.get_threshold(vendor_nip, base=profile_threshold)
        review_threshold = auto_post_threshold - 0.17  # REVIEW zawsze 0.17 poniżej AUTO_POST

        # ── 4. MultiModelEnsemble (v5.4) — ≥3 modele + diversity ──
        ensemble_span = self._tracer.start_span(decision_id, "ensemble", self.name)

        ensemble_votes = []

        # Głos 1: Actor (Granite 3.2)
        actor_decision = await self._actor_evaluate(extraction_result)
        trust_score_obj = actor_decision.trust_score or TrustScore(overall=0.0)
        raw_trust = trust_score_obj.overall
        ensemble_votes.append(EnsembleVote(
            model_name="granite-3.2-3b",
            model_weight=0.33,
            vote=actor_decision.verdict.status,
            confidence=raw_trust,
            reasoning=actor_decision.verdict.reason[:100],
        ))

        # Głos 2: Guardian (Granite Guardian)
        guardian_decision = await self._guardian_verify(extraction_result, actor_decision)
        if guardian_decision and guardian_decision.trust_score:
            trust_score_obj = self._merge_trust_scores(trust_score_obj, guardian_decision.trust_score)
            ensemble_votes.append(EnsembleVote(
                model_name="granite-guardian-0.5b",
                model_weight=0.33,
                vote=guardian_decision.verdict.status,
                confidence=guardian_decision.verdict.trust_score,
                reasoning=guardian_decision.verdict.reason[:100],
            ))

        # Głos 3: DynamicErrorHandbook (few-shot) — opcjonalny
        handbook_query = HandbookQuery(
            vendor_nip=extraction_result.extracted_data.get("nip", ""),
            category=extraction_result.extracted_data.get("category", ""),
            amount_gross=float(extraction_result.extracted_data.get("amount_gross", 0)),
            document_type=extraction_result.document_type,
            k=2,
        )
        handbook_examples = await self._error_handbook.query_relevant(handbook_query)
        if handbook_examples:
            handbook_vote = "BLOCK" if any("BLOCK" in ex.user_correction for ex in handbook_examples) else "REVIEW"
            ensemble_votes.append(EnsembleVote(
                model_name="handbook-few-shot",
                model_weight=0.20,
                vote=handbook_vote,
                confidence=0.6,
                reasoning=f"{len(handbook_examples)} similar past corrections",
            ))

        # Rozstrzygnij ensemble
        ensemble_result = self._ensemble.resolve(ensemble_votes)
        self._tracer.end_span(decision_id, ensemble_span, {
            "winner": ensemble_result.winner,
            "consensus": ensemble_result.consensus,
            "diversity": ensemble_result.diversity_score,
            "trust": ensemble_result.final_trust,
        })

        # ── 5. Walidacja przez QualityValidator ────────────────────
        quality_result = await self._run_quality_check(
            decision_id, actor_decision, extraction_result,
        )
        if quality_result:
            trust_score_obj.overall *= (1.0 - quality_result.overall_risk_score * 0.3)

        # ── 5a. GENIALNY POMYSŁ v5.3: Pomijanie agentów według Mesh ──
        # Jeśli Trust ≥ 0.92 → pomiń QualityValidator + Analytics
        if mesh_route and "quality-validator" in mesh_route.skip_agents:
            quality_result = None  # pomiń QualityValidator
            logger.info("[MESH] Skipping QualityValidator for NIP %s (trust=%.2f)",
                        vendor_nip[:8], mesh_route.trust_score)
        if mesh_route and "analytics" in mesh_route.skip_agents:
            logger.info("[MESH] Skipping Analytics for NIP %s (trust=%.2f)",
                        vendor_nip[:8], mesh_route.trust_score)
        # Jeśli mesh każe wymusić agentów
        if mesh_route and "analytics" in mesh_route.force_agents and "analytics" not in self._sub_agents:
            logger.info("[MESH] Analytics forced but not registered")

        # ── 6. Weighted Voting ─────────────────────────────────────
        voting_result = await self._run_weighted_voting(
            extraction_result, trust_score_obj, quality_result,
        )

        # ── 7. 4-Eyes Check ────────────────────────────────────────
        gross_amount = extraction_result.extracted_data.get("amount_gross", 0)
        # Recompute gross_amount_num from extraction result (not raw invoice_data)
        gross_amount_num = gross_amount if isinstance(gross_amount, (int, float)) else 0.0
        four_eyes_needed = (
            isinstance(gross_amount, (int, float))
            and gross_amount > FOUR_EYES_THRESHOLD
        )

        # ── 8. Skalibruj Trust Score (v5.4) ──────────────────────
        final_trust_score = trust_score_obj.overall
        calibrated_cs = self._calibrator.calibrate(final_trust_score)
        logger.info("[CALIBRATE] trust=%.2f → calibrated=%.2f",
                    final_trust_score, calibrated_cs)
        # Użyj skalibrowanego trustu do decyzji
        final_trust_score = calibrated_cs

        # ── GENIALNY POMYSŁ v6.0: Strategiczna decyzja w Silent Mode ──
        if self._silent_mode:
            should_auto, strategic_mode, strategy_reason = self._strategy_engine.should_auto_post(
                trust_score=final_trust_score,
                amount=gross_amount_num,
                is_routine=(gross_amount_num < 50000),
                vendor_is_trusted=(extraction_result.confidence > 0.85),
            )
            if should_auto:
                status = "AUTO_POST"
                reason = f"Silent Partner: {strategy_reason}"
            else:
                status = "REVIEW" if strategic_mode.value != "ask_user" else "BLOCK"
                reason = f"Silent Partner: {strategy_reason}"
        else:
            status, reason = self._determine_zone(
                final_trust_score,
                quality_result,
                four_eyes_needed,
                gross_amount,
            )

        # ── 8a. Mapuj strefę na DecisionMode ─────────────────────────
        zone_to_mode = {
            "AUTO_POST": DecisionMode.AUTO_POST,
            "REVIEW": DecisionMode.SUGGEST,
            "BLOCK": DecisionMode.ASK_USER,
            "ESCALATED": DecisionMode.ASK_USER,
            "4EYES_REQUIRED": DecisionMode.SUGGEST,
        }
        decision_mode = zone_to_mode.get(status, DecisionMode.ASK_USER)

        # ── 9. Zbierz weryfikatorów ───────────────────────────────
        verified_by = [self.name]
        if quality_result:
            verified_by.append("quality-validator")
        if four_eyes_needed:
            verified_by.append("4-eyes-check")

        # ── 10. Utwórz decyzję z Proof Chain ──────────────────────
        decision = self.make_decision(
            decision_mode=decision_mode,
            decision_id=decision_id,
            status=status,
            trust_score=final_trust_score,
            reason=reason,
            explanation=self._generate_explanation(
                status, final_trust_score, extraction_result, four_eyes_needed,
            ),
            details={
                "extraction_confidence": extraction_result.confidence,
                "extracted_data": extraction_result.extracted_data,
                "voting_result": msgspec_json.decode(msgspec_json.encode(voting_result)) if voting_result else None,
                "quality_verdict": quality_result.overall_verdict if quality_result else None,
                "four_eyes": four_eyes_needed,
                "thresholds": {
                    "auto_post": auto_post_threshold,
                    "review": review_threshold,
                    "used": final_trust_score,
                },
            },
            supporting_data={
                "extracted_data": extraction_result.extracted_data,
                "quality_check": quality_result,
            },
            voting_result=voting_result,
        )

        # ── 11. Decision Cache: zapisz embedding ───────────────────
        await self._cache_decision(decision, invoice_data, vendor_nip)

        # ── 12. Zachowaj dla eskalacji ─────────────────────────────
        self._pending_decisions[decision_id] = decision

        # ── 16. GENIALNY POMYSŁ v6.0: Executive Summary ──
        # Dodaj każdą decyzję do Executive Summary (zbieranie dla dashboardu)
        vendor_name = extraction_result.extracted_data.get("vendor_name", "")
        gross_amount_num = gross_amount if isinstance(gross_amount, (int, float)) else 0.0

        if status == "AUTO_POST":
            self._executive_summary.add_auto_posted(
                title=f"Faktura od {vendor_name or vendor_nip}",
                amount=gross_amount_num,
                detail=f"{extraction_result.extracted_data.get('invoice_number', 'N/A')} — {gross_amount_num:,.2f} PLN",
                decision_id=decision_id,
            )
            self._silent_stats["auto_posted"] += 1
            self._silent_stats["time_saved_total_minutes"] += 2.5  # 2.5 min na decyzję
        else:
            self._executive_summary.add_verified(
                title=f"Faktura od {vendor_name or vendor_nip}",
                amount=gross_amount_num,
                detail=f"Wymagana weryfikacja — {extraction_result.extracted_data.get('invoice_number', 'N/A')}",
                decision_id=decision_id,
            )

        # ── v6.0: Jeśli wysoka kwota, dodaj też do items_to_review ──
        if isinstance(gross_amount, (int, float)) and gross_amount > 50000:
            self._executive_summary.add_item_to_review(
                title=f"🔍 Wysoka kwota: {vendor_name or vendor_nip}",
                detail=f"{gross_amount:,.2f} PLN — warto przejrzeć",
                decision_id=decision_id,
                amount=gross_amount,
                status="pending",
            )

        self._silent_stats["total_decisions"] += 1

        # ── 15. GENIALNY POMYSŁ v5.2: Obserwuj decyzję — Progressive Autonomy ──
        # AUTO_POST: od razu uczymy się (brak interakcji użytkownika)
        # SUGGEST/ASK_USER: uczymy się dopiero po odpowiedzi w handle_user_card_response
        vendor_name = extraction_result.extracted_data.get("vendor_name", "")
        gross_amount_num = gross_amount if isinstance(gross_amount, (int, float)) else 0.0
        category = extraction_result.extracted_data.get("category", "")

        if status == "AUTO_POST":
            self._decision_profile.observe_decision(
                vendor_nip=vendor_nip,
                vendor_name=vendor_name,
                amount_gross=gross_amount_num,
                category=category,
                status=status,
                decision_mode=decision_mode.value,
                user_action="confirm",
                user_option="",
            )

        # ── 16. GENIALNY POMYSŁ v5.3: Aktualizuj Knowledge Mesh ──
        if self._knowledge_mesh and self._knowledge_mesh.is_initialized:
            correct = (status == "AUTO_POST")
            await self._knowledge_mesh.update_trust(
                vendor_nip=vendor_nip,
                correct=correct,
                agent_name=self.name,
                category=extraction_result.extracted_data.get("category", ""),
                amount=gross_amount_num,
            )
            if not correct and mesh_route:
                await self._knowledge_mesh.share_experience(
                    event_type="orchestrator.decision_corrected",
                    source_agent=self.name,
                    vendor_nip=vendor_nip,
                    category=extraction_result.extracted_data.get("category", ""),
                    amount=gross_amount_num,
                )

        # ── 16a. GENIALNY POMYSŁ v5.4: Record Telemetry ──
        self._tracer.end_span(decision_id, trace_span, {
            "status": status, "trust": final_trust_score, "mode": decision_mode.value,
        })
        self._tracer.end_trace(decision_id, status, final_trust_score, decision_mode.value)
        await self._telemetry.record_decision(
            decision_id=decision_id,
            vendor_nip=vendor_nip,
            amount_gross=gross_amount_num,
            category=extraction_result.extracted_data.get("category", ""),
            document_type=extraction_result.document_type,
            agent_name=self.name,
            status=status,
            trust_score=final_trust_score,
            decision_mode=decision_mode.value,
            trace_id=trace.trace_id if trace else "",
            spans_count=len(trace.spans) if trace else 0,
            total_duration_ms=trace.total_duration_ms if trace else 0.0,
            quality_score=trace.quality_score if trace else 0.0,
        )
        # Kalibracja: jeśli AUTO_POST → feedback pozytywny (na razie)
        self._calibrator.update(raw_trust, correct=(status == "AUTO_POST"))

        # ── 17. Continuous Learning: jeśli SUGGEST/ASK_USER → czekamy na feedback
        if decision_mode in (DecisionMode.SUGGEST, DecisionMode.ASK_USER):
            logger.info("[ORCH] Decision %s requires user feedback | mode=%s | autonomy=%.1f%%",
                        decision_id, decision_mode.value, self._decision_profile.get_autonomy_score())

        logger.info(
            "[ORCH] Decision %s | status=%s | trust=%.2f | adaptive_threshold=%.2f | 4eyes=%s | autonomy=%.1f%% | mesh=%s",
            decision_id, status, final_trust_score, auto_post_threshold, four_eyes_needed,
            self._decision_profile.get_autonomy_score(),
            f"{mesh_route.route if mesh_route else 'default'}",
        )

        return decision

    # ── Decision Cache ──────────────────────────────────────────────

    async def _check_decision_cache(self, invoice_data: dict[str, Any]) -> AgentDecision | None:
        """Sprawdź czy istnieje podobna decyzja w cache.

        Używa sqlite-vec k-NN (k=5, distance < 0.1).
        """
        try:
            # Wektoryzacja danych faktury (symulacja)
            embedding = self._vectorize_invoice(invoice_data)
            similar = await self._decision_cache.find_similar(
                embedding, k=5, threshold=0.1,
            )
            if similar:
                best = similar[0]
                return msgspec_json.decode(
                    json.dumps(best).encode(),
                    type=AgentDecision,
                )
        except Exception as exc:
            logger.debug("[ORCH] Cache check failed: %s", exc)
        return None

    async def _cache_decision(
        self,
        decision: AgentDecision,
        invoice_data: dict[str, Any],
        vendor_nip: str,
    ) -> None:
        """Zapisz decyzję w cache z embeddingiem."""
        try:
            embedding = self._vectorize_invoice(invoice_data)
            decision_json = msgspec_json.encode(decision).decode()
            await self._decision_cache.store_embedding(
                embedding, decision.decision_id, decision_json,
            )
            # Dodaj też do diskcache (TTL 24h)
            await self._decision_cache.set(
                f"decision:{decision.decision_id}",
                decision_json,
                expire=86400,
            )
        except Exception as exc:
            logger.debug("[ORCH] Cache store failed: %s", exc)

    @staticmethod
    def _vectorize_invoice(invoice_data: dict[str, Any]) -> list[float]:
        """Wektoryzacja danych faktury do 768-wymiarowego wektora.

        W rzeczywistości używa modelu embeddding.
        Symulacja: prosta transformacja pól na wektor.
        """
        # Symulacja embeddingu — w produkcji używa sqlite-vec lub modelu
        import hashlib
        text = json.dumps(invoice_data, sort_keys=True)
        hash_bytes = hashlib.sha256(text.encode()).digest()
        # Rozszerz do 768 wymiarów przez interpolację
        vector = []
        for i in range(768):
            vector.append(float(hash_bytes[i % 32]) / 255.0)
        return vector

    # ── Weighted Voting ────────────────────────────────────────────

    async def _run_weighted_voting(
        self,
        extraction: DataExtractionResult,
        trust_score: TrustScore,
        quality: QualityCheckResult | None,
    ) -> VotingResult:
        """Przeprowadź ważone głosowanie między modelami.

        Wagi: Orchestrator=0.40, QualityValidator=0.60 (niezależny audytor)
        """
        votes: list[ConfidenceVote] = []
        trust_val = trust_score.overall

        # Głos Orkiestratora
        votes.append(ConfidenceVote(
            model_name="granite-3.2-3b",
            model_weight=self._voting_weights.get("orchestrator", 0.40),
            vote="AUTO_POST" if trust_val >= 0.92 else "REVIEW" if trust_val >= 0.75 else "BLOCK",
            confidence=trust_val,
            weighted_vote=trust_val * self._voting_weights.get("orchestrator", 0.40),
        ))

        # Głos Walidatora
        if quality:
            quality_confidence = 1.0 - quality.overall_risk_score
            votes.append(ConfidenceVote(
                model_name="quality-validator",
                model_weight=self._voting_weights.get("quality_validator", 0.60),
                vote="BLOCK" if quality.overall_verdict == "ERROR" else
                     "REVIEW" if quality.overall_verdict == "WARNING" else "AUTO_POST",
                confidence=quality_confidence,
                weighted_vote=quality_confidence * self._voting_weights.get("quality_validator", 0.60),
            ))

        # Oblicz wynik
        total_weight = sum(v.model_weight for v in votes)
        vote_counts: dict[str, float] = {}
        for v in votes:
            vote_counts[v.vote] = vote_counts.get(v.vote, 0) + v.model_weight

        winner = max(vote_counts, key=vote_counts.get)
        winner_weight = vote_counts[winner]
        consensus = winner_weight / total_weight > 0.66

        return VotingResult(
            votes=votes,
            total_weight=total_weight,
            winner=winner,
            consensus=consensus,
            uncertainty=1.0 - (winner_weight / total_weight),
        )

    # ── 4-Eyes Principle ───────────────────────────────────────────

    async def _check_four_eyes(
        self,
        decision: AgentDecision,
        invoice_data: dict[str, Any],
    ) -> dict[str, Any]:
        """Weryfikacja 4-Eyes Principle dla kwot > 50k PLN.

        Dwie niezależne weryfikacje:
        - Pierwsza: Granite Guardian (kontrola podatkowa)
        - Druga: regułowa (kwota, kontrahent, split payment)

        Returns:
            Dict z werdyktem 4-Eyes.
        """
        gross = invoice_data.get("amount_gross", 0)
        if not isinstance(gross, (int, float)) or gross <= FOUR_EYES_THRESHOLD:
            return {"required": False, "verdict": "OK"}

        result = {
            "required": True,
            "threshold": FOUR_EYES_THRESHOLD,
            "amount": gross,
            "verdict": "OK",
            "checks": [],
        }

        # Check 1: Granite Guardian
        guardian_model = self._models.get("guardian")
        if guardian_model:
            prompt = (
                f"Zweryfikuj decyzję dla faktury na kwotę {gross:.2f} PLN.\n"
                f"Status: {decision.verdict.status}, Trust: {decision.verdict.trust_score:.2f}\n"
                f"Czy ta decyzja jest bezpieczna? Odpowiedz TAK lub NIE."
            )
            try:
                guardian_result = await self.infer(guardian_model, prompt, max_tokens=50, temperature=0.0)
                is_safe = "TAK" in guardian_result.upper() and "NIE" not in guardian_result.upper()[:5]
                result["checks"].append({
                    "name": "guardian",
                    "passed": is_safe,
                    "detail": guardian_result.strip(),
                })
            except Exception as exc:
                logger.warning("[4EYES] Guardian check failed: %s", exc)

        # Check 2: Regułowa
        is_safe_regul = gross <= MAX_AUTO_POST_AMOUNT * 2
        result["checks"].append({
            "name": "regulatory",
            "passed": is_safe_regul,
            "detail": f"Kwota {gross:.2f} {'w' if is_safe_regul else 'poza'} limitem",
        })

        # Overall verdict
        all_passed = all(c["passed"] for c in result["checks"])
        result["verdict"] = "OK" if all_passed else "WARNING"

        return result

    # ── Sub-agent execution ────────────────────────────────────────

    async def _run_extraction(
        self,
        invoice_data: dict[str, Any],
        decision_id: str,
    ) -> DataExtractionResult:
        """Uruchom AgentDataExtraction do ekstrakcji danych."""
        if "extraction" not in self._sub_agents:
            return DataExtractionResult(
                invoice_id=invoice_data.get("invoice_id", decision_id),
                success=True,
                extracted_data=invoice_data,
                ocr_text=invoice_data.get("ocr_text", ""),
                confidence=0.8,
                document_type="INVOICE",
            )

        agent = self._sub_agents["extraction"]
        request = DataExtractionRequest(
            invoice_id=invoice_data.get("invoice_id", decision_id),
            file_path=invoice_data.get("file_path", ""),
            file_type=invoice_data.get("file_type", ""),
            options=self._config.get("ocr", {}),
        )
        return await agent.extract(request)

    async def _actor_evaluate(
        self,
        extraction: DataExtractionResult,
    ) -> AgentDecision:
        """Ocena faktury przez Głównego Decydenta (Granite 3.2).

        GENIALNY POMYSŁ: Dynamiczny Podręcznik Błędów —
        wstrzykiwanie przykładów few-shot z przeszłych korekt do promptu.
        """
        model_path = self._models.get("actor")
        if not model_path:
            return self._rule_based_evaluate(extraction)

        data = extraction.extracted_data

        # ── GENIALNY POMYSŁ: Pobierz przykłady few-shot z Podręcznika Błędów ──
        handbook_query = HandbookQuery(
            vendor_nip=data.get("nip", ""),
            category=data.get("category", ""),
            amount_gross=float(data.get("amount_gross", 0)),
            document_type=extraction.document_type,
            k=3,
        )
        few_shot_section = await self._error_handbook.build_few_shot_prompt(
            handbook_query
        )

        prompt = f"""Jesteś głównym decydentem księgowym. Oceń fakturę i podejmij decyzję.

Dane faktury:
- Numer: {data.get('invoice_number', 'N/A')}
- NIP sprzedawcy: {data.get('nip', 'N/A')}
- Kwota brutto: {data.get('amount_gross', 'N/A')} {data.get('currency', 'PLN')}
- Data: {data.get('date', 'N/A')}
- Typ dokumentu: {extraction.document_type}

Pewność ekstrakcji: {extraction.confidence:.2f}
Problemy walidacji: {extraction.validation_issues or 'Brak'}
{few_shot_section}
Oceń zaufanie do tej faktury (0.0-1.0) i uzasadnij.
Format: TRUST: X.XX, STATUS: AUTO_POST|REVIEW|BLOCK, REASON: ..."""

        try:
            result = await self.infer(model_path, prompt, max_tokens=150, temperature=0.1)
            trust = self._parse_trust_score(result)
            status = self._parse_status(result)
            return self.make_decision(
                decision_id=extraction.invoice_id,
                status=status,
                trust_score=trust,
                reason=result.strip(),
                explanation=result.strip(),
                ai_confidence=trust,
            )
        except Exception as exc:
            logger.warning("[ORCH] Actor evaluation failed: %s", exc)
            return self._rule_based_evaluate(extraction)

    def _rule_based_evaluate(self, extraction: DataExtractionResult) -> AgentDecision:
        """Regułowa ocena (fallback gdy model niedostępny)."""
        data = extraction.extracted_data
        trust = extraction.confidence * 0.8
        reasons = []

        if extraction.validation_issues:
            trust -= 0.1 * len(extraction.validation_issues)
            reasons.extend(extraction.validation_issues)

        gross = data.get("amount_gross", 0)
        if isinstance(gross, (int, float)) and gross > 100000:
            trust -= 0.1
            reasons.append(f"Wysoka kwota: {gross}")

        trust = max(0.0, min(1.0, trust))
        status, _ = self._determine_zone(trust, None, False, gross)

        return self.make_decision(
            decision_id=extraction.invoice_id,
            status=status,
            trust_score=trust,
            reason="; ".join(reasons) if reasons else "Regułowa ocena OK",
            explanation=f"Trust score: {trust:.2f}. {'; '.join(reasons) if reasons else 'Standardowa ocena.'}",
            ai_confidence=trust,
        )

    async def _guardian_verify(
        self,
        extraction: DataExtractionResult,
        actor_decision: AgentDecision,
    ) -> AgentDecision | None:
        """Weryfikacja przez Strażnika Merytorycznego (Granite Guardian)."""
        model_path = self._models.get("guardian")
        if not model_path:
            return None

        data = extraction.extracted_data
        prompt = f"""Jesteś strażnikiem merytorycznym. Zweryfikuj poprawność decyzji.

Dane faktury:
- NIP: {data.get('nip', 'N/A')}
- Kwota: {data.get('amount_gross', 'N/A')}
- Data: {data.get('date', 'N/A')}

Proponowana decyzja: {actor_decision.verdict.status}
Trust Score: {actor_decision.verdict.trust_score:.2f}

Czy ta decyzja jest poprawna? Odpowiedz TAK lub NIE i uzasadnij."""

        try:
            result = await self.infer(model_path, prompt, max_tokens=100, temperature=0.0)
            is_ok = "TAK" in result.upper() and "NIE" not in result.upper()[:5]
            if not is_ok:
                trust = actor_decision.trust_score.overall * 0.7 if actor_decision.trust_score else 0.5
                return self.make_decision(
                    decision_id=extraction.invoice_id,
                    status="REVIEW",
                    trust_score=trust,
                    reason=f"Strażnik odrzucił decyzję: {result.strip()}",
                )
        except Exception as exc:
            logger.warning("[ORCH] Guardian verification failed: %s", exc)

        return None

    async def _run_quality_check(
        self,
        decision_id: str,
        decision: AgentDecision,
        extraction: DataExtractionResult,
    ) -> QualityCheckResult | None:
        """Uruchom AgentQualityValidator z 4-Eyes jeśli potrzeba."""
        if "quality-validator" not in self._sub_agents:
            return None

        agent = self._sub_agents["quality-validator"]
        gross = extraction.extracted_data.get("amount_gross", 0)
        four_eyes = isinstance(gross, (int, float)) and gross > FOUR_EYES_THRESHOLD

        request = QualityCheckRequest(
            decision_id=decision_id,
            proposed_decision={
                "status": decision.verdict.status,
                "trust_score": decision.verdict.trust_score,
            },
            invoice_data=extraction.extracted_data,
            checks=["tax", "fraud", "esg"] + (["four_eyes"] if four_eyes else []),
            four_eyes_required=four_eyes,
            liquidity_stress_test=isinstance(gross, (int, float)) and gross > 10000,
        )
        return await agent.validate(request)

    async def _run_analytics(
        self,
        extraction: DataExtractionResult,
    ) -> AnalyticsResult | None:
        """Uruchom AgentAnalytics (opcjonalnie)."""
        if "analytics" not in self._sub_agents or not extraction.extracted_data:
            return None

        agent = self._sub_agents["analytics"]
        query = AnalyticsQuery(
            query_id=extraction.invoice_id,
            query_type="anomaly",
            natural_language=(
                f"Sprawdź czy faktura {extraction.extracted_data.get('invoice_number', '')} "
                f"od NIP {extraction.extracted_data.get('nip', '')} "
                f"na kwotę {extraction.extracted_data.get('amount_gross', '')} jest typowa"
            ),
            context={"invoice_data": extraction.extracted_data},
        )
        return await agent.analyze(query)

    # ── Strefy decyzyjne (adaptive) ────────────────────────────────

    def _determine_zone(
        self,
        trust_score: float,
        quality_result: QualityCheckResult | None,
        four_eyes_needed: bool,
        gross_amount: float | str | None,
    ) -> tuple[str, str]:
        """Określ strefę decyzyjną z uwzględnieniem Enterprise factors."""
        # QualityValidator ERROR → zawsze BLOCK
        if quality_result and quality_result.overall_verdict == "ERROR":
            return ("BLOCK", f"Blokada przez QualityValidator: {quality_result.recommendations}")

        # 4-Eyes Required + BLOCK
        if four_eyes_needed and trust_score < 0.75:
            return ("BLOCK", f"Blokada — niski trust ({trust_score:.2f}) i kwota > {FOUR_EYES_THRESHOLD:.0f} PLN")

        # Limity kwotowe
        amt = gross_amount if isinstance(gross_amount, (int, float)) else 0
        if amt > MAX_AUTO_POST_AMOUNT:
            return ("REVIEW", f"Kwota {amt:.2f} PLN przekracza limit AUTO_POST ({MAX_AUTO_POST_AMOUNT:.0f} PLN)")

        # Strefy decyzyjne (adaptive)
        auto_post_threshold = self.get_threshold("vendor", base=0.92)

        if trust_score >= auto_post_threshold:
            if quality_result and quality_result.overall_verdict == "WARNING":
                return ("REVIEW", f"Wysoki trust ({trust_score:.2f}) ale ostrzeżenia walidacji")
            return ("AUTO_POST", f"Automatyczne księgowanie (trust={trust_score:.2f}, próg={auto_post_threshold:.2f})")

        review_threshold = auto_post_threshold - 0.17
        if trust_score >= review_threshold:
            return ("REVIEW", f"Wymagana weryfikacja (trust={trust_score:.2f})")

        return ("BLOCK", f"Blokada — niski trust score ({trust_score:.2f})")

    def _generate_explanation(
        self,
        status: str,
        trust_score: float,
        extraction: DataExtractionResult,
        four_eyes: bool = False,
    ) -> str:
        """Generuj wyjaśnienie decyzji w języku naturalnym."""
        data = extraction.extracted_data
        parts = [
            f"Decyzja dla faktury {data.get('invoice_number', 'nieznana')}: {status}.",
            f"Ogólny poziom zaufania: {trust_score:.0%}.",
        ]

        if four_eyes:
            parts.append("Wymagana weryfikacja 4-Eyes (kwota > 50,000 PLN).")

        if status == "AUTO_POST":
            parts.append("Faktura została automatycznie zaksięgowana.")
        elif status == "REVIEW":
            parts.append("Wymagana jest dodatkowa weryfikacja przez użytkownika.")
        elif status == "BLOCK":
            parts.append("Faktura została zablokowana.")

        if extraction.validation_issues:
            parts.append(f"Problemy: {'; '.join(extraction.validation_issues)}")

        return " ".join(parts)

    # ── Parsowanie odpowiedzi modeli ──────────────────────────────

    @staticmethod
    def _parse_trust_score(text: str) -> float:
        """Wyciągnij Trust Score z odpowiedzi modelu."""
        import re
        match = re.search(r"TRUST:\s*([0-9.]+)", text, re.IGNORECASE)
        if match:
            try:
                return max(0.0, min(1.0, float(match.group(1))))
            except ValueError:
                pass
        return 0.75

    @staticmethod
    def _parse_status(text: str) -> str:
        """Wyciągnij status z odpowiedzi modelu."""
        import re
        match = re.search(r"STATUS:\s*(\w+)", text, re.IGNORECASE)
        if match:
            status = match.group(1).upper()
            if status in ("AUTO_POST", "REVIEW", "BLOCK"):
                return status
        return "REVIEW"

    @staticmethod
    def _merge_trust_scores(
        primary: TrustScore,
        secondary: TrustScore | None,
    ) -> TrustScore:
        """Scal Trust Score z dwóch źródeł (primary 0.7, secondary 0.3)."""
        if secondary is None:
            return primary
        return TrustScore(
            ai_confidence=primary.ai_confidence * 0.7 + secondary.ai_confidence * 0.3,
            vendor_reliability=primary.vendor_reliability * 0.7 + secondary.vendor_reliability * 0.3,
            data_consistency=primary.data_consistency * 0.7 + secondary.data_consistency * 0.3,
            context_trust=primary.context_trust * 0.7 + secondary.context_trust * 0.3,
            overall=primary.overall * 0.7 + secondary.overall * 0.3,
        )

    # ── Komunikacja z użytkownikiem ─────────────────────────────────

    async def record_user_feedback(
        self,
        decision_id: str,
        corrected_status: str,
        corrected_reason: str = "",
    ) -> None:
        """Zapisz korektę użytkownika — GENIALNY POMYSŁ v5.4 Unified Learning Protocol.

        KASKADA 5 systemów uczenia po każdej korekcie:
        1. DynamicErrorHandbook → few-shot example
        2. ContinuousLearningProvider → Cognitive Proof Block
        3. KnowledgeMesh → Bayesian Field + Cross-Agent Rules
        4. UserDecisionProfile → Progressive Autonomy
        5. AgentTelemetryStore → korekta w DuckDB
        """
        decision = self._pending_decisions.get(decision_id)
        if not decision:
            logger.debug("[ORCH] No pending decision found for feedback: %s", decision_id)
            return

        details = decision.verdict.details if hasattr(decision.verdict, 'details') else {}
        extracted = details.get("extracted_data", {}) if isinstance(details, dict) else {}
        vendor_nip = extracted.get("nip", "unknown")
        category = extracted.get("category", "")
        amount = float(extracted.get("amount_gross", 0))
        was_corrected = corrected_status != decision.verdict.status

        # ── 1. DynamicErrorHandbook ──
        await self._error_handbook.record_correction(
            invoice_id=decision.decision_id,
            vendor_nip=vendor_nip,
            category=category,
            amount_gross=amount,
            ai_decision=decision.verdict.status,
            ai_trust_score=decision.verdict.trust_score,
            ai_reason=decision.verdict.reason,
            user_correction=corrected_status,
            correction_reason=corrected_reason,
        )

        # ── 2. ContinuousLearningProvider ──
        correction_embedding = self._vectorize_invoice(
            extracted if extracted else {"decision_id": decision.decision_id}
        ) if extracted else None
        await self.record_feedback(
            decision=decision,
            corrected={"status": corrected_status, "reason": corrected_reason},
            feedback_type=FeedbackType.CORRECT if was_corrected else FeedbackType.ACCEPT,
            correction_embedding=correction_embedding,
        )

        # ── 3. KnowledgeMesh — update Bayesian Field + Cross-Agent Rules ──
        if self._knowledge_mesh and self._knowledge_mesh.is_initialized:
            await self._knowledge_mesh.update_trust(
                vendor_nip=vendor_nip,
                correct=not was_corrected,
                agent_name=self.name,
                category=category,
                amount=amount,
            )
            if was_corrected:
                await self._knowledge_mesh.share_experience(
                    event_type="orchestrator.decision_corrected",
                    source_agent=self.name,
                    vendor_nip=vendor_nip,
                    category=category,
                    amount=amount,
                )

        # ── 4. UserDecisionProfile — Progressive Autonomy ──
        self._decision_profile.observe_decision(
            vendor_nip=vendor_nip,
            vendor_name=extracted.get("vendor_name", ""),
            amount_gross=amount,
            category=category,
            status=corrected_status,
            decision_mode=decision.decision_mode.value if decision.decision_mode else "ask_user",
            user_action="reject" if was_corrected else "confirm",
            user_option=corrected_status,
        )

        # ── 5. AgentTelemetryStore — record correction ──
        await self._telemetry.record_correction(
            correction_id=uuid.uuid4().hex[:16],
            decision_id=decision_id,
            agent_name=self.name,
            ai_decision=decision.verdict.status,
            user_correction=corrected_status,
            correction_reason=corrected_reason,
            vendor_nip=vendor_nip,
            category=category,
            amount_gross=amount,
            delta=1.0 if was_corrected else 0.0,
            feedback_type="correct" if was_corrected else "accept",
        )

        # ── 6. ConfidenceCalibrator — update Platt Scaling ──
        self._calibrator.update(decision.verdict.trust_score, not was_corrected)

        # ── 7. FeedbackLoop — record metrics ──
        self._feedback.record_decision(
            status=decision.verdict.status,
            user_accepted=not was_corrected,
        )

        logger.info(
            "[ORCH] 📘 Unified Learning Protocol | %s: %s → %s | handbook: %d | mesh | profile | telemetry | calibrator",
            decision_id, decision.verdict.status, corrected_status,
            self._error_handbook.count,
        )

        self._pending_decisions.pop(decision_id, None)

    # ── GENIALNY POMYSŁ v5.0: Proactive Workflow Engine ──────────

    @property
    def proactive_scheduler(self) -> ProactiveWorkflowScheduler:
        """Dostęp do ProactiveWorkflowScheduler."""
        return self._proactive_scheduler

    async def execute_proactive_workflow(self, workflow_type: str) -> dict[str, Any]:
        """Wykonaj proaktywny workflow.

        GENIALNY POMYSŁ v5.0:
        Agenci sami inicjują zadania — nie czekają na użytkownika.

        Args:
            workflow_type: Typ workflow (WorkflowType).

        Returns:
            Wynik wykonania.
        """
        execution = await self._proactive_scheduler.execute_workflow(workflow_type)
        return {
            "workflow_id": execution.workflow_id,
            "type": execution.workflow_type,
            "status": execution.status,
            "duration_ms": execution.duration_ms,
            "result": execution.result,
            "error": execution.error,
        }

    def get_proactive_schedule(self) -> list[dict[str, Any]]:
        """Pobierz harmonogram proaktywnych workflow."""
        return self._proactive_scheduler.get_schedule_summary()

    def get_proactive_stats(self) -> dict[str, Any]:
        """Pobierz statystyki proaktywnego silnika."""
        return self._proactive_scheduler.get_stats()

    # ── GENIALNY POMYSŁ v5.1: "Zasada 1-Click CFO" — Action Cards ──

    @property
    def card_generator(self) -> ActionCardGenerator:
        """Dostęp do generatora kart decyzyjnych."""
        return self._card_generator

    async def generate_action_card(
        self,
        decision: AgentDecision,
        document_type: str = "INVOICE",
    ) -> Any:
        """Generuj kartę decyzyjną z AgentDecision.

        GENIALNY POMYSŁ v5.1:
        Tłumaczy techniczną decyzję na 2-4 proste przyciski.
        Przedsiębiorca NIE widzi stawek VAT, kont, reguł OPA.

        Args:
            decision: Pełna decyzja agenta.
            document_type: Typ dokumentu (INVOICE, ASSET, TAX_ALERT, PAYMENT).

        Returns:
            ActionCard z prostymi opcjami.
        """
        return await self._card_generator.generate_card_from_decision(decision)

    async def build_daily_decision_feed(self) -> ActionCardFeed:
        """Zbuduj codzienny feed kart decyzyjnych.

        GENIALNY POMYSŁ v5.1:
        Przedsiębiorca po zalogowaniu widzi "skrzynkę decyzyjną"
        z kartami. Zero tabel, zero formularzy.

        Publikuje ActionCardFeed na ui.feed.pending.

        Returns:
            ActionCardFeed gotowy do konsumpcji przez UI.
        """
        pending = [
            d for d in self._pending_decisions.values()
            if d.decision_mode in (DecisionMode.SUGGEST, DecisionMode.ASK_USER)
        ]
        feed = self._card_generator.build_daily_feed(pending)

        # Publikuj na NATS dla UI
        ctx = make_context(
            task_id=f"feed-{uuid.uuid4().hex[:8]}",
            source=self.name,
            target="ui",
            priority=3,
        )
        await self.publish(AgentTopic.UI_FEED_PENDING, feed, ctx)

        logger.info(
            "[ORCH] Decision feed published | %d cards (%d urgent)",
            feed.total_pending, feed.urgent_count,
        )
        return feed

    async def handle_user_card_response(
        self,
        card_id: str,
        decision_id: str,
        selected_option_id: str,
        selected_label: str = "",
        action_type: str = "confirm",
        user_comment: str = "",
    ) -> dict[str, Any]:
        """Obsłuż odpowiedź użytkownika na kartę decyzyjną.

        GENIALNY POMYSŁ v5.1:
        Przedsiębiorca kliknął 1 przycisk → wykonaj ukryty payload.
        Agent robi resztę: księgowanie, KSeF, TigerBeetle, OPA.

        Args:
            card_id: ID karty.
            decision_id: ID decyzji.
            selected_option_id: Którą opcję wybrał użytkownik.
            selected_label: Etykieta wybranej opcji.
            action_type: Typ akcji (confirm, alternative, reject, escalate)
                         przekazany bezpośrednio z ActionCardOption.
            user_comment: Opcjonalny komentarz.

        Returns:
            Wynik wykonania.
        """
        decision = self._pending_decisions.get(decision_id)
        if not decision:
            logger.warning("[ORCH] Card response for unknown decision: %s", decision_id)
            return {"status": "error", "message": "Decision not found"}

        # Zbuduj odpowiedź
        response = ActionCardResponse(
            card_id=card_id,
            decision_id=decision_id,
            selected_option_id=selected_option_id,
            selected_label=selected_label,
            user_comment=user_comment,
            responded_at=pendulum.now("UTC").isoformat(),
        )

        # Publikuj odpowiedź
        ctx = make_context(
            task_id=f"card-response-{uuid.uuid4().hex[:8]}",
            source="ui",
            target=self.name,
            priority=2,
        )
        await self.publish(AgentTopic.UI_FEED_ACTION, response, ctx)

        # Określ typ akcji (przekazany bezpośrednio z ActionCardOption.action_type)
        # NIE inferujemy z labela — frontend ma dostęp do pełnego ActionCardOption

        # Zapisz feedback do Continuous Learning + Progressive Autonomy
        # GENIALNY POMYSŁ v5.2: Każda odpowiedź użytkownika to punkt danych
        details = decision.verdict.details if hasattr(decision.verdict, 'details') else {}
        extracted = details.get("extracted_data", {}) if isinstance(details, dict) else {}
        vendor_nip = extracted.get("nip", "unknown")
        vendor_name = extracted.get("vendor_name", "")
        gross_amount = float(extracted.get("amount_gross", 0)) if extracted.get("amount_gross") else 0.0
        category = extracted.get("category", "")

        if action_type == "confirm":
            await self.record_user_feedback(
                decision_id=decision_id,
                corrected_status=decision.verdict.status,
                corrected_reason=f"User accepted via ActionCard: {selected_label}",
            )
            self._decision_profile.observe_decision(
                vendor_nip=vendor_nip,
                vendor_name=vendor_name,
                amount_gross=gross_amount,
                category=category,
                status=decision.verdict.status,
                decision_mode=decision.decision_mode.value if decision.decision_mode else "ask_user",
                user_action="confirm",
                user_option=selected_label,
            )
        elif action_type == "reject":
            await self.record_user_feedback(
                decision_id=decision_id,
                corrected_status="BLOCK",
                corrected_reason=f"User rejected via ActionCard: {selected_label}",
            )
            self._decision_profile.observe_decision(
                vendor_nip=vendor_nip,
                vendor_name=vendor_name,
                amount_gross=gross_amount,
                category=category,
                status="BLOCK",
                decision_mode=decision.decision_mode.value if decision.decision_mode else "ask_user",
                user_action="reject",
                user_option=selected_label,
            )
        else:
            # alternative/escalate: nie usuwaj z pending — użytkownik może wrócić
            logger.info(
                "[ORCH] Card response deferred | card=%s action=%s",
                card_id, action_type,
            )
            return {
                "status": "ok",
                "action": action_type,
                "decision_id": decision_id,
                "card_id": card_id,
                "message": "Decision deferred — card remains pending",
            }

        # Usuń z pending
        self._pending_decisions.pop(decision_id, None)

        logger.info(
            "[ORCH] Card response processed | card=%s decision=%s action=%s",
            card_id, decision_id, action_type,
        )

        return {
            "status": "ok",
            "action": action_type,
            "decision_id": decision_id,
            "card_id": card_id,
        }

    async def communicate_with_user(
        self,
        decision: AgentDecision,
        options: list[dict[str, str]] | None = None,
    ) -> str | None:
        """Komunikacja z użytkownikiem przez Qwen3-Nano.

        Zawsze pyta użytkownika przy SUGGEST i ASK_USER.
        Przy AUTO_POST — tylko informuje (opcjonalnie).
        """
        # Przy AUTO_POST nie przeszkadzamy użytkownikowi
        if decision.decision_mode == DecisionMode.AUTO_POST:
            return None

        model_path = self._models.get("communicator")
        if not model_path:
            return None

        opts = options or [
            {"label": "Zatwierdź", "description": "Akceptuj proponowaną decyzję"},
            {"label": "Koryguj", "description": "Popraw dane i zatwierdź"},
            {"label": "Odrzuć", "description": "Odrzuć i prześlij do ręcznej weryfikacji"},
        ]

        options_text = "\n".join(f"- {o['label']}: {o['description']}" for o in opts)

        prompt = f"""Jesteś komunikatywnym asystentem księgowym. Przedstaw użytkownikowi decyzję do podjęcia.

Decyzja: {decision.verdict.status}
Trust Score: {decision.verdict.trust_score:.2f}
Wyjaśnienie: {decision.explanation}

Opcje:
{options_text}

Przedstaw to w zwięzły, zrozumiały sposób (2-3 zdania po polsku):"""

        try:
            return await self.infer(model_path, prompt, max_tokens=200, temperature=0.3)
        except Exception as exc:
            logger.warning("[ORCH] Communication failed: %s", exc)
            return None

    # ── GENIALNY POMYSŁ v6.0: Silent Partner — Executive Summary & Accept-All ──

    async def build_executive_summary(
        self,
        greeting_name: str = "",
    ) -> ExecutiveSummary:
        """Zbuduj Executive Summary dla przedsiębiorcy.

        GENIALNY POMYSŁ v6.0:
        Agent prezentuje efekt swojej pracy w formie Executive Summary.
        Przedsiębiorca może zaakceptować wszystko jednym kliknięciem.

        Returns:
            ExecutiveSummary gotowe do konsumpcji przez ExecutiveDashboard.
        """
        # Analizuj kontekst strategiczny
        self._strategy_engine.analyze_context(
            cash_balance=self._executive_summary._auto_posted_amount,
            pending_receivables=0.0,
            pending_payables=0.0,
        )

        # Generuj rekomendacje strategiczne
        silent_rate = self.get_silent_rate()
        recommendations = self._strategy_engine.generate_strategic_recommendations(
            cash_balance=self._executive_summary._auto_posted_amount,
            recent_auto_post_count=self._silent_stats.get("auto_posted", 0),
            correction_rate=1.0 - (silent_rate / 100.0) if silent_rate < 100 else 0.0,
        )

        # Zbuduj summary
        summary = self._executive_summary.build_summary(
            strategic_recommendations=recommendations,
            greeting_name=greeting_name,
        )

        # Publikuj na NATS dla UI
        ctx = make_context(
            task_id=f"exec-summary-{uuid.uuid4().hex[:8]}",
            source=self.name,
            target="ui",
            priority=3,
            strategic_mode=self._strategy_engine.current_mode,
            silent_mode=self._silent_mode,
        )
        await self.publish(AgentTopic.UI_EXECUTIVE_SUMMARY, summary, ctx)

        logger.info(
            "[ORCH] 📊 Executive Summary published | %d auto + %d verified | "
            "silent_rate=%.1f%% | saved=%.0f min | state=%s",
            summary.auto_posted_count,
            summary.verified_count,
            summary.silent_rate,
            summary.time_saved_minutes,
            summary.dashboard_state.value,
        )

        return summary

    async def accept_all(self) -> dict[str, Any]:
        """Akceptuj wszystkie decyzje — GENIALNY POMYSŁ v6.0.

        Przedsiębiorca klika 1 przycisk → wszystkie decyzje zatwierdzone.
        To jest DOMYŚLNA ścieżka (80% przypadków).

        Returns:
            Wynik akceptacji.
        """
        now = pendulum.now("UTC")
        self._silent_stats["accept_all_count"] += 1

        # Zatwierdź wszystkie pending decyzje
        accepted_count = 0
        for decision_id in list(self._pending_decisions.keys()):
            try:
                await self.record_user_feedback(
                    decision_id=decision_id,
                    corrected_status="AUTO_POST",
                    corrected_reason="Accept-All (Silent Partner v6.0)",
                )
                accepted_count += 1
            except Exception as exc:
                logger.warning("[ORCH] Accept-all failed for %s: %s", decision_id, exc)

        # Zresetuj Executive Summary na następny dzień
        self._executive_summary.reset()

        logger.info(
            "[ORCH] ✅ Accept-All | %d decisions confirmed | #%d accept-all",
            accepted_count, self._silent_stats["accept_all_count"],
        )

        return {
            "status": "ok",
            "accepted_count": accepted_count,
            "accept_all_count": self._silent_stats["accept_all_count"],
            "timestamp": now.isoformat(),
            "silent_rate": self.get_silent_rate(),
        }

    def set_strategic_mode(self, mode: StrategicMode) -> dict[str, Any]:
        """Ustaw tryb strategiczny — GENIALNY POMYSŁ v6.0.

        Agent pyta o STRATEGIĘ, nie o taktykę.

        Args:
            mode: Nowy tryb strategiczny.

        Returns:
            Podsumowanie zmiany.
        """
        old_mode = self._strategy_engine.current_mode
        self._strategy_engine.set_user_strategic_mode(mode)

        logger.info(
            "[ORCH] Strategic mode changed | %s → %s",
            old_mode.value, mode.value,
        )

        return {
            "status": "ok",
            "previous_mode": old_mode.value,
            "new_mode": mode.value,
            "thresholds": self._strategy_engine.mode_thresholds,
            "context": self._strategy_engine.current_context.summary,
        }

    def toggle_silent_mode(self) -> dict[str, Any]:
        """Przełącz Silent Partner v6.0 ON/OFF."""
        self._silent_mode = not self._silent_mode
        return {
            "status": "ok",
            "silent_mode": self._silent_mode,
            "message": f"Silent Partner: {'WŁĄCZONY' if self._silent_mode else 'WYŁĄCZONY'}",
        }

    def get_strategy_summary(self) -> dict[str, Any]:
        """Pobierz podsumowanie strategii Silent Partner."""
        strategy = self._strategy_engine.get_strategy_summary()
        return {
            **strategy,
            "silent_mode": self._silent_mode,
            "silent_rate": self.get_silent_rate(),
            "silent_stats": dict(self._silent_stats),
        }

    async def process_task(self, task_data: dict[str, Any]) -> None:
        """Przetwórz zadanie z kolejki.

        Taskiq task: agent_orchestrator.process_task
        """
        logger.info("[ORCH] Processing task: %s", task_data.get("type"))
        decision = await self.process_invoice(task_data.get("invoice_data", {}))
        ctx = make_context(
            task_id=decision.decision_id,
            source=self.name,
            target="system",
        )
        await self.publish(AgentTopic.COUNCIL_DECISION_FINAL, decision, ctx)
