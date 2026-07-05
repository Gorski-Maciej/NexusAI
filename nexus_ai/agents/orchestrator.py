"""AgentOrchestrator — Centralny Mózg i Wirtualny Dyrektor Finansowy.

Zgodnie z blueprintem aa3fvcx.txt:
- Granite 3.2 3B — Główny Decydent (Actor)
- Granite Guardian 0.5B — Strażnik Merytoryczny
- Qwen3-Nano 0.5B — Komunikator (kontakt z użytkownikiem)

Strefy Decyzyjne:
- Zielona (Trust Score >= 0.92): AUTO_POST
- Żółta (0.75 <= Trust Score < 0.92): REVIEW
- Czerwona (Trust Score < 0.75): BLOCK / ESCALATION

Proces:
1. Odbierz zadanie (council.task.request)
2. Deleguj do AgentDataExtraction (invoice.received)
3. Odbierz wynik (invoice.extracted)
4. Oceń decyzję (Granite 3.2 + Granite Guardian)
5. Wyślij do walidacji (quality.check.request)
6. Odbierz wynik walidacji (quality.check.result)
7. Analiza opcjonalna (analytics.query)
8. Finalna decyzja (council.decision.final)
9. Jeśli potrzeba → eskaluj do użytkownika przez Komunikator
"""

from __future__ import annotations

import uuid
from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.agents.base import BaseAgent
from nexus_ai.agents.models import (
    AgentDecision,
    AnalyticsQuery,
    AnalyticsResult,
    DataExtractionRequest,
    DataExtractionResult,
    DecisionVerdict,
    QualityCheckRequest,
    QualityCheckResult,
    TrustScore,
    make_context,
)
from nexus_ai.agents.topics import AgentTopic
from nexus_ai.core.inference import ModelManager

logger = get_logger("nexus.agents.orchestrator")


# ── Progi decyzyjne ────────────────────────────────────────────────────


class DecisionThreshold:
    """Progi decyzyjne zgodne z blueprintem aa3fvcx.txt."""

    AUTO_POST: float = 0.92
    """Zielona strefa: automatyczne księgowanie."""
    REVIEW: float = 0.75
    """Żółta strefa: wymagana dodatkowa weryfikacja."""
    # Poniżej REVIEW: czerwona strefa → blokada i eskalacja


class AgentOrchestrator(BaseAgent):
    """Agent Orkiestrator — centralny koordynator systemu agentów AI.

    Zarządza przepływem danych między agentami:
    DataExtraction → QualityValidator → Analytics → Final Decision
    """

    def __init__(
        self,
        model_manager: ModelManager | None = None,
        config: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(
            name="orchestrator",
            model_manager=model_manager,
            config=config or {},
        )
        self._models: dict[str, str] = {}
        self._pending_decisions: dict[str, AgentDecision] = {}
        self._sub_agents: dict[str, BaseAgent] = {}

    def register_agent(self, name: str, agent: BaseAgent) -> None:
        """Zarejestruj podległego agenta."""
        self._sub_agents[name] = agent
        logger.info("[ORCH] Registered sub-agent: %s", name)

    async def start(self) -> None:
        """Inicjalizuj modele Orkiestratora."""
        await super().start()
        self._init_models()
        logger.info(
            "[ORCH] Orchestrator ready | models: %s | agents: %s",
            self._models,
            list(self._sub_agents.keys()),
        )

    def _init_models(self) -> None:
        """Inicjalizuj ścieżki modeli z konfiguracji."""
        self._models = {
            "actor": self._config.get("orchestrator_actor_model", ""),
            "guardian": self._config.get("orchestrator_guardian_model", ""),
            "communicator": self._config.get("orchestrator_communicator_model", ""),
        }

    # ── Główny proces decyzyjny ─────────────────────────────────────

    async def process_invoice(self, invoice_data: dict[str, Any]) -> AgentDecision:
        """Przetwórz fakturę przez pełny pipeline agentów.

        Args:
            invoice_data: Dane faktury (może zawierać tylko file_path).

        Returns:
            AgentDecision z ostateczną decyzją.
        """
        decision_id = uuid.uuid4().hex[:16]
        logger.info("[ORCH] Processing invoice %s", decision_id)

        # 1. Ekstrakcja danych (AgentDataExtraction)
        extraction_result = await self._run_extraction(invoice_data, decision_id)
        if not extraction_result.success:
            return self.make_decision(
                decision_id=decision_id,
                status="BLOCK",
                trust_score=0.0,
                reason=f"Ekstrakcja danych nie powiodła się: {extraction_result.error}",
                explanation="Nie udało się wyodrębnić danych z dokumentu. Wymagana ręczna weryfikacja.",
            )

        # 2. Ocena przez Głównego Decydenta (Granite 3.2)
        actor_decision = await self._actor_evaluate(extraction_result)
        trust_score = actor_decision.trust_score

        # 3. Weryfikacja przez Strażnika Merytorycznego (Granite Guardian)
        guardian_decision = await self._guardian_verify(extraction_result, actor_decision)
        if guardian_decision:
            trust_score = self._merge_trust_scores(trust_score, guardian_decision.trust_score)

        # 4. Walidacja przez AgentQualityValidator (jeśli dostępny)
        quality_result = await self._run_quality_check(
            decision_id, actor_decision, extraction_result,
        )

        # 5. Analiza przez AgentAnalytics (opcjonalnie)
        analytics_result = await self._run_analytics(extraction_result)

        # 6. Określenie strefy decyzyjnej
        final_trust_score = trust_score.overall if trust_score else 0.0
        if quality_result:
            final_trust_score *= (1.0 - quality_result.overall_risk_score * 0.3)

        status, reason = self._determine_zone(final_trust_score, quality_result)

        # 7. Zbierz agentów którzy weryfikowali
        verified_by = [self.name]
        if quality_result:
            verified_by.append("quality-validator")

        decision = AgentDecision(
            decision_id=decision_id,
            agent_name=self.name,
            verdict=DecisionVerdict(
                status=status,
                trust_score=final_trust_score,
                reason=reason,
                details={
                    "extraction_confidence": extraction_result.confidence,
                    "extracted_data": extraction_result.extracted_data,
                    "actor_decision": actor_decision.verdict.details if actor_decision.verdict else {},
                    "quality_verdict": quality_result.overall_verdict if quality_result else None,
                    "analytics": analytics_result.data if analytics_result else [],
                },
                verified_by=verified_by,
            ),
            trust_score=trust_score,
            explanation=self._generate_explanation(status, final_trust_score, extraction_result),
            supporting_data={
                "extracted_data": extraction_result.extracted_data,
                "quality_check": quality_result,
            },
            created_at=pendulum.now("UTC").isoformat(),
        )

        # 8. Zachowaj decyzję dla potencjalnej eskalacji
        self._pending_decisions[decision_id] = decision

        logger.info(
            "[ORCH] Decision %s | status=%s | trust=%.2f",
            decision_id, status, final_trust_score,
        )

        return decision

    async def _run_extraction(
        self,
        invoice_data: dict[str, Any],
        decision_id: str,
    ) -> DataExtractionResult:
        """Uruchom AgentDataExtraction do ekstrakcji danych."""
        if "extraction" not in self._sub_agents:
            # Symuluj ekstrakcję jeśli agent nie jest dostępny
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
        """Ocena faktury przez Głównego Decydenta (Granite 3.2)."""
        model_path = self._models.get("actor")
        if not model_path:
            # Fallback: regułowa ocena
            return self._rule_based_evaluate(extraction)

        data = extraction.extracted_data
        prompt = f"""Jesteś głównym decydentem księgowym. Oceń fakturę i podejmij decyzję.

Dane faktury:
- Numer: {data.get('invoice_number', 'N/A')}
- NIP sprzedawcy: {data.get('nip', 'N/A')}
- Kwota brutto: {data.get('amount_gross', 'N/A')} {data.get('currency', 'PLN')}
- Data: {data.get('date', 'N/A')}
- Typ dokumentu: {extraction.document_type}

Pewność ekstrakcji: {extraction.confidence:.2f}
Problemy walidacji: {extraction.validation_issues or 'Brak'}

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

        # Kara za problemy walidacji
        if extraction.validation_issues:
            trust -= 0.1 * len(extraction.validation_issues)
            reasons.extend(extraction.validation_issues)

        # Wysoka kwota → niższe zaufanie
        gross = data.get("amount_gross", 0)
        if isinstance(gross, (int, float)) and gross > 100000:
            trust -= 0.1
            reasons.append(f"Wysoka kwota: {gross}")

        trust = max(0.0, min(1.0, trust))
        status = self._determine_zone(trust, None)[0]

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
        """Uruchom AgentQualityValidator."""
        if "quality-validator" not in self._sub_agents:
            return None

        agent = self._sub_agents["quality-validator"]
        request = QualityCheckRequest(
            decision_id=decision_id,
            proposed_decision={
                "status": decision.verdict.status,
                "trust_score": decision.verdict.trust_score,
            },
            invoice_data=extraction.extracted_data,
            checks=["tax", "fraud", "esg"],
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
            natural_language=f"Sprawdź czy faktura {extraction.extracted_data.get('invoice_number', '')} "
                            f"od NIP {extraction.extracted_data.get('nip', '')} "
                            f"na kwotę {extraction.extracted_data.get('amount_gross', '')} jest typowa",
            context={"invoice_data": extraction.extracted_data},
        )
        return await agent.analyze(query)

    # ── Strefy decyzyjne ────────────────────────────────────────────

    def _determine_zone(
        self,
        trust_score: float,
        quality_result: QualityCheckResult | None,
    ) -> tuple[str, str]:
        """Określ strefę decyzyjną na podstawie Trust Score i walidacji.

        Returns:
            (status, reason)
        """
        # Jeśli QualityValidator zwrócił ERROR → zawsze BLOCK
        if quality_result and quality_result.overall_verdict == "ERROR":
            return ("BLOCK", f"Blokada przez QualityValidator: {quality_result.recommendations}")

        # Strefy decyzyjne
        if trust_score >= DecisionThreshold.AUTO_POST:
            if quality_result and quality_result.overall_verdict == "WARNING":
                return ("REVIEW", f"Wysoki trust score ({trust_score:.2f}) ale ostrzeżenia walidacji")
            return ("AUTO_POST", f"Automatyczne księgowanie (trust={trust_score:.2f})")

        if trust_score >= DecisionThreshold.REVIEW:
            return ("REVIEW", f"Wymagana weryfikacja (trust={trust_score:.2f})")

        return ("BLOCK", f"Blokada — niski trust score ({trust_score:.2f})")

    def _generate_explanation(
        self,
        status: str,
        trust_score: float,
        extraction: DataExtractionResult,
    ) -> str:
        """Generuj wyjaśnienie decyzji w języku naturalnym."""
        data = extraction.extracted_data
        parts = [
            f"Decyzja dla faktury {data.get('invoice_number', 'nieznana')}: {status}.",
            f"Ogólny poziom zaufania: {trust_score:.0%}.",
        ]

        if status == "AUTO_POST":
            parts.append("Faktura została automatycznie zaksięgowana.")
        elif status == "REVIEW":
            parts.append("Wymagana jest dodatkowa weryfikacja przez użytkownika.")
        elif status == "BLOCK":
            parts.append("Faktura została zablokowana.")

        if extraction.validation_issues:
            parts.append(f"Problemy: {'; '.join(extraction.validation_issues)}")

        return " ".join(parts)

    def _parse_trust_score(self, text: str) -> float:
        """Wyciągnij Trust Score z odpowiedzi modelu."""
        import re
        match = re.search(r"TRUST:\s*([0-9.]+)", text, re.IGNORECASE)
        if match:
            try:
                return max(0.0, min(1.0, float(match.group(1))))
            except ValueError:
                pass
        return 0.75  # Domyślny

    def _parse_status(self, text: str) -> str:
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
        """Scal Trust Score z dwóch źródeł."""
        if secondary is None:
            return primary

        # Średnia ważona: primary ma wagę 0.7, secondary 0.3
        return TrustScore(
            ai_confidence=primary.ai_confidence * 0.7 + secondary.ai_confidence * 0.3,
            vendor_reliability=primary.vendor_reliability * 0.7 + secondary.vendor_reliability * 0.3,
            data_consistency=primary.data_consistency * 0.7 + secondary.data_consistency * 0.3,
            context_trust=primary.context_trust * 0.7 + secondary.context_trust * 0.3,
            overall=primary.overall * 0.7 + secondary.overall * 0.3,
        )

    # ── Komunikacja z użytkownikiem ─────────────────────────────────

    async def communicate_with_user(
        self,
        decision: AgentDecision,
        options: list[dict[str, str]] | None = None,
    ) -> str | None:
        """Komunikacja z użytkownikiem przez Qwen3-Nano.

        Args:
            decision: Decyzja wymagająca interwencji użytkownika.
            options: Opcje do wyboru (label, description).

        Returns:
            Wybór użytkownika (lub None).
        """
        model_path = self._models.get("communicator")
        if not model_path:
            return None

        options_text = ""
        if options:
            options_text = "\n".join(
                f"- {opt['label']}: {opt['description']}" for opt in options
            )

        prompt = f"""Jesteś komunikatywnym asystentem księgowym. Przedstaw użytkownikowi decyzję do podjęcia.

Decyzja: {decision.verdict.status}
Trust Score: {decision.verdict.trust_score:.2f}
Wyjaśnienie: {decision.explanation}

Opcje:
{options_text or '- Zatwierdź: Akceptuj proponowaną decyzję\n- Odrzuć: Odrzuć i prześlij do ręcznej weryfikacji'}

Przedstaw to w zwięzły, zrozumiały sposób (2-3 zdania po polsku):"""

        try:
            return await self.infer(model_path, prompt, max_tokens=200, temperature=0.3)
        except Exception as exc:
            logger.warning("[ORCH] Communication failed: %s", exc)
            return None

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
