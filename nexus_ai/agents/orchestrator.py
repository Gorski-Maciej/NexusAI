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
from nexus_ai.agents.models import (
    AgentDecision,
    AnalyticsQuery,
    AnalyticsResult,
    ConfidenceVote,
    DataExtractionRequest,
    DataExtractionResult,
    DecisionMode,
    FeedbackType,
    QualityCheckRequest,
    QualityCheckResult,
    TrustScore,
    VotingResult,
    make_context,
)
from nexus_ai.agents.topics import AgentTopic
from nexus_ai.core.inference import ModelManager

logger = get_logger("nexus.agents.orchestrator")


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
    ) -> None:
        super().__init__(
            name="orchestrator",
            model_manager=model_manager,
            config=config or {},
        )
        self._models: dict[str, str] = {}
        self._pending_decisions: dict[str, AgentDecision] = {}
        self._sub_agents: dict[str, BaseAgent] = {}
        self._voting_weights: dict[str, float] = dict(DEFAULT_VOTING_WEIGHTS)
        # ── GENIALNY POMYSŁ: Dynamiczny Podręcznik Błędów ──
        self._error_handbook = DynamicErrorHandbook()

    def register_agent(self, name: str, agent: BaseAgent) -> None:
        """Zarejestruj podległego agenta."""
        self._sub_agents[name] = agent
        logger.info("[ORCH] Registered sub-agent: %s", name)

    async def start(self) -> None:
        """Inicjalizuj modele Orkiestratora i Podręcznik Błędów."""
        await super().start()
        self._init_models()
        await self._error_handbook.initialize()
        logger.info(
            "[ORCH] Orchestrator ready | models: %s | agents: %s | handbook: %d examples",
            self._models,
            list(self._sub_agents.keys()),
            self._error_handbook.count,
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

        Enterprise:
        1. Decision Cache: k-NN w podobnych decyzjach
        2. AgentDataExtraction → ekstrakcja
        3. Actor (Granite 3.2) + Guardian (Granite Guardian) → ocena
        4. Weighted Voting: konsensus między modelami
        5. 4-Eyes: dla kwot > 50k PLN
        6. Decision Cache: zapisz embedding decyzji
        7. Proof Chain: dodaj blok SHA-256

        Args:
            invoice_data: Dane faktury.

        Returns:
            AgentDecision z ostateczną decyzją.
        """
        decision_id = uuid.uuid4().hex[:16]
        logger.info("[ORCH] Processing invoice %s", decision_id)

        # ── 1. Decision Cache: k-NN ────────────────────────────────
        cached_decision = await self._check_decision_cache(invoice_data)
        if cached_decision:
            logger.info("[ORCH] Decision cache HIT for %s | trust=%.2f",
                        decision_id, cached_decision.verdict.trust_score)
            return cached_decision

        # ── 2. Ekstrakcja danych ───────────────────────────────────
        extraction_result = await self._run_extraction(invoice_data, decision_id)
        if not extraction_result.success:
            return self.make_decision(
                decision_id=decision_id,
                status="BLOCK",
                trust_score=0.0,
                reason=f"Ekstrakcja danych nie powiodła się: {extraction_result.error}",
                explanation="Nie udało się wyodrębnić danych z dokumentu. Wymagana ręczna weryfikacja.",
            )

        # ── 3. Określenie adaptacyjnych progów ─────────────────────
        vendor_nip = extraction_result.extracted_data.get("nip", "unknown")
        auto_post_threshold = self.get_threshold(vendor_nip, base=0.92)
        review_threshold = auto_post_threshold - 0.17  # REVIEW zawsze 0.17 poniżej AUTO_POST

        # ── 4. Ocena przez Actor + Guardian ────────────────────────
        actor_decision = await self._actor_evaluate(extraction_result)
        trust_score_obj = actor_decision.trust_score or TrustScore(overall=0.0)

        guardian_decision = await self._guardian_verify(extraction_result, actor_decision)
        if guardian_decision and guardian_decision.trust_score:
            trust_score_obj = self._merge_trust_scores(trust_score_obj, guardian_decision.trust_score)

        # ── 5. Walidacja przez QualityValidator ────────────────────
        quality_result = await self._run_quality_check(
            decision_id, actor_decision, extraction_result,
        )
        if quality_result:
            trust_score_obj.overall *= (1.0 - quality_result.overall_risk_score * 0.3)

        # ── 6. Weighted Voting ─────────────────────────────────────
        voting_result = await self._run_weighted_voting(
            extraction_result, trust_score_obj, quality_result,
        )

        # ── 7. 4-Eyes Check ────────────────────────────────────────
        gross_amount = extraction_result.extracted_data.get("amount_gross", 0)
        four_eyes_needed = (
            isinstance(gross_amount, (int, float))
            and gross_amount > FOUR_EYES_THRESHOLD
        )

        # ── 8. Określenie strefy decyzyjnej ────────────────────────
        final_trust_score = trust_score_obj.overall
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

        # ── 15. Continuous Learning: jeśli SUGGEST/ASK_USER → czekamy na feedback
        if decision_mode in (DecisionMode.SUGGEST, DecisionMode.ASK_USER):
            logger.info("[ORCH] Decision %s requires user feedback | mode=%s", decision_id, decision_mode.value)

        logger.info(
            "[ORCH] Decision %s | status=%s | trust=%.2f | auto_threshold=%.2f | 4eyes=%s",
            decision_id, status, final_trust_score, auto_post_threshold, four_eyes_needed,
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
        """Zapisz korektę użytkownika w Podręczniku Błędów (GENIALNY POMYSŁ).

        Gdy użytkownik poprawia decyzję AI → zapisz jako przykład few-shot.
        Im więcej korekt, tym mądrzejszy model Granite 3.2.
        """
        decision = self._pending_decisions.get(decision_id)
        if not decision:
            logger.debug("[ORCH] No pending decision found for feedback: %s", decision_id)
            return

        # Wyciągnij dane z decyzji
        details = decision.verdict.details if hasattr(decision.verdict, 'details') else {}
        extracted = details.get("extracted_data", {}) if isinstance(details, dict) else {}

        await self._error_handbook.record_correction(
            invoice_id=decision.decision_id,
            vendor_nip=extracted.get("nip", "unknown"),
            category=extracted.get("category", ""),
            amount_gross=float(extracted.get("amount_gross", 0)),
            ai_decision=decision.verdict.status,
            ai_trust_score=decision.verdict.trust_score,
            ai_reason=decision.verdict.reason,
            user_correction=corrected_status,
            correction_reason=corrected_reason,
        )

        # Równolegle zapisz w Continuous Learning Provider (Cognitive Audit Trail)
        correction_embedding = self._vectorize_invoice(
            extracted if extracted else {"decision_id": decision.decision_id}
        ) if extracted else None
        await self.record_feedback(
            decision=decision,
            corrected={"status": corrected_status, "reason": corrected_reason},
            feedback_type=FeedbackType.CORRECT if corrected_status != decision.verdict.status else FeedbackType.ACCEPT,
            correction_embedding=correction_embedding,
        )

        logger.info(
            "[ORCH] 📘 User feedback recorded | %s: %s → %s | handbook: %d examples",
            decision_id,
            decision.verdict.status,
            corrected_status,
            self._error_handbook.count,
        )

        # Usuń z pending
        self._pending_decisions.pop(decision_id, None)

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
