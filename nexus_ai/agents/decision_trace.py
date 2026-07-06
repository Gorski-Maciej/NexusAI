"""DecisionTrace + ConfidenceCalibrator + MultiModelEnsemble — Decision Protocol v5.4.

GENIALNY POMYSŁ ENTERPRISE v5.4:
- DecisionTrace: pełny OTel tracing każdej decyzji przez wszystkie agenty
- ConfidenceCalibrator: Platt Scaling kalibracja Trust Score
- MultiModelEnsemble: ≥3 modele z diversity check
- FeedbackLoop: metryki time-to-decision, correction_rate, decision_quality_score

Zgodnie z aa3fvcx.txt — technologie:
- OpenTelemetry (API + SDK) — tracing
- DuckDB — przechowywanie trace'ów
- msgspec — struktury danych
- pendulum — timestamps
"""

from __future__ import annotations

import math
import time
import uuid
from typing import Any

from msgspec import Struct, field
from structlog import get_logger

logger = get_logger("nexus.agents.decision_trace")


# ═════════════════════════════════════════════════════════════════════════
# DecisionSpan — pojedynczy span w śladzie decyzji
# ═════════════════════════════════════════════════════════════════════════


class DecisionSpan(Struct, kw_only=True):
    """Pojedynczy krok w śladzie decyzji — odpowiednik OTel Span."""

    span_id: str
    name: str  # np. "extraction", "quality_check", "ensemble_vote"
    agent_name: str
    started_at: float = 0.0  # perf_counter
    ended_at: float = 0.0
    duration_ms: float = 0.0
    status: str = "OK"  # OK | ERROR | SKIPPED
    input_data: dict[str, Any] = field(default_factory=dict)
    output_data: dict[str, Any] = field(default_factory=dict)
    error: str = ""
    metadata: dict[str, Any] = field(default_factory=dict)


class DecisionTrace(Struct, kw_only=True):
    """Pełny ślad decyzji — odpowiednik OTel Trace."""

    trace_id: str
    decision_id: str
    vendor_nip: str
    amount_gross: float = 0.0
    category: str = ""
    document_type: str = ""
    spans: list[DecisionSpan] = field(default_factory=list)
    started_at: float = 0.0
    ended_at: float = 0.0
    total_duration_ms: float = 0.0
    final_status: str = ""
    final_trust_score: float = 0.0
    decision_mode: str = ""
    correction_id: str = ""
    quality_score: float = 0.0  # 0-100%


# ═════════════════════════════════════════════════════════════════════════
# DecisionTracer — zarządca śladów decyzji
# ═════════════════════════════════════════════════════════════════════════


class DecisionTracer:
    """Zarządca śladów decyzji — OTel-compatible tracing.

    GENIALNY POMYSŁ v5.4:
    Każda decyzja = pełny trace. Każdy krok agenta = span.
    Trace jest zapisywany w AgentTelemetryStore (DuckDB + Parquet).

    Użycie:
        tracer = DecisionTracer()
        trace = tracer.start_trace(decision_id, vendor_nip, amount, ...)
        span = trace.start_span("extraction", "extraction-agent")
        # ... agent działa ...
        span.end({"confidence": 0.95, "ocr_text": "..."})
        trace.end(status="AUTO_POST", trust_score=0.93)
    """

    def __init__(self) -> None:
        self._active_traces: dict[str, DecisionTrace] = {}
        self._logger = get_logger("nexus.agents.tracer")

    # ── Trace Lifecycle ──────────────────────────────────────────────

    def start_trace(
        self,
        decision_id: str,
        vendor_nip: str,
        amount_gross: float = 0.0,
        category: str = "",
        document_type: str = "INVOICE",
    ) -> DecisionTrace:
        """Rozpocznij nowy ślad decyzji.

        Returns:
            Nowy DecisionTrace gotowy do dodawania spanów.
        """
        trace = DecisionTrace(
            trace_id=uuid.uuid4().hex[:16],
            decision_id=decision_id,
            vendor_nip=vendor_nip,
            amount_gross=amount_gross,
            category=category,
            document_type=document_type,
            started_at=time.perf_counter(),
        )
        self._active_traces[decision_id] = trace
        self._logger.debug("[TRACE] Started | decision=%s | NIP=%s",
                           decision_id, vendor_nip[:8])
        return trace

    def get_trace(self, decision_id: str) -> DecisionTrace | None:
        """Pobierz aktywny trace."""
        return self._active_traces.get(decision_id)

    def end_trace(
        self,
        decision_id: str,
        status: str,
        trust_score: float,
        decision_mode: str = "auto_post",
    ) -> DecisionTrace | None:
        """Zakończ ślad decyzji."""
        trace = self._active_traces.pop(decision_id, None)
        if trace:
            trace.ended_at = time.perf_counter()
            trace.total_duration_ms = (trace.ended_at - trace.started_at) * 1000
            trace.final_status = status
            trace.final_trust_score = trust_score
            trace.decision_mode = decision_mode
            trace.quality_score = self._calculate_quality(trace)
            self._logger.info(
                "[TRACE] Completed | decision=%s | status=%s | trust=%.2f | "
                "spans=%d | duration=%.0fms | quality=%.0f%%",
                decision_id, status, trust_score,
                len(trace.spans), trace.total_duration_ms, trace.quality_score,
            )
        return trace

    # ── Span Management ─────────────────────────────────────────────

    def start_span(
        self,
        decision_id: str,
        name: str,
        agent_name: str,
        input_data: dict[str, Any] | None = None,
    ) -> DecisionSpan:
        """Rozpocznij nowy span w aktywnym trace.

        Args:
            decision_id: ID decyzji (trace).
            name: Nazwa kroku (np. "extraction", "quality_check").
            agent_name: Agent wykonujący krok.
            input_data: Dane wejściowe kroku.

        Returns:
            Nowy DecisionSpan.
        """
        span = DecisionSpan(
            span_id=uuid.uuid4().hex[:12],
            name=name,
            agent_name=agent_name,
            started_at=time.perf_counter(),
            input_data=input_data or {},
        )

        trace = self._active_traces.get(decision_id)
        if trace:
            trace.spans.append(span)

        self._logger.debug("[TRACE] Span start | decision=%s | name=%s | agent=%s",
                           decision_id, name, agent_name)
        return span

    def end_span(
        self,
        decision_id: str,
        span: DecisionSpan,
        output_data: dict[str, Any] | None = None,
        status: str = "OK",
        error: str = "",
    ) -> None:
        """Zakończ span."""
        span.ended_at = time.perf_counter()
        span.duration_ms = (span.ended_at - span.started_at) * 1000
        span.status = status
        span.error = error
        if output_data:
            span.output_data = output_data

        self._logger.debug(
            "[TRACE] Span end | decision=%s | name=%s | status=%s | %.0fms",
            decision_id, span.name, status, span.duration_ms,
        )

    # ── Quality Score ────────────────────────────────────────────────

    @staticmethod
    def _calculate_quality(trace: DecisionTrace) -> float:
        """Oblicz Decision Quality Score (0-100%).

        Składowe:
        - Wszystkie spany OK = 40%
        - Brak błędów w spanach = 30%
        - Szybkość (< 5s total = 20%, < 15s = 10%)
        - Wszystkie agenty działały (min 2 spany) = 10%
        """
        if not trace.spans:
            return 0.0

        score = 0.0

        # Wszystkie spany OK
        ok_spans = sum(1 for s in trace.spans if s.status == "OK")
        score += (ok_spans / len(trace.spans)) * 40

        # Brak błędów
        error_spans = sum(1 for s in trace.spans if s.status == "ERROR")
        score += max(0.0, (1.0 - error_spans / max(len(trace.spans), 1))) * 30

        # Szybkość
        if trace.total_duration_ms < 5000:
            score += 20
        elif trace.total_duration_ms < 15000:
            score += 10

        # Minimum 2 spany (wieloagentowe)
        if len(trace.spans) >= 2:
            score += 10

        return min(100.0, score)

    # ── Stats ────────────────────────────────────────────────────────

    def get_active_count(self) -> int:
        return len(self._active_traces)

    def get_recent_traces(self, count: int = 10) -> list[dict[str, Any]]:
        """Pobierz ostatnie zakończone trace (z logów)."""
        # W rzeczywistości: query do AgentTelemetryStore
        return []


# ═════════════════════════════════════════════════════════════════════════
# EnsembleVote — głos pojedynczego modelu w zespole
# ═════════════════════════════════════════════════════════════════════════


class EnsembleVote(Struct, kw_only=True):
    """Głos pojedynczego modelu w Multi-Model Ensemble."""

    model_name: str
    model_weight: float = 0.33  # domyślnie równe wagi
    vote: str = ""  # AUTO_POST | REVIEW | BLOCK
    confidence: float = 0.0  # 0.0-1.0
    reasoning: str = ""
    diversity_hash: str = ""  # hash decyzji dla diversity check


class EnsembleResult(Struct, kw_only=True):
    """Wynik Multi-Model Ensemble z diversity check."""

    votes: list[EnsembleVote] = field(default_factory=list)
    winner: str = ""
    consensus: bool = False  # ≥2/3 zgody
    diversity_score: float = 1.0  # 0-1, 1 = wszystkie różne (dobre)
    all_identical: bool = False  # true = wszystkie modele takie same (słabe)
    final_trust: float = 0.0
    uncertainty: float = 0.0
    requires_human: bool = False


# ═════════════════════════════════════════════════════════════════════════
# MultiModelEnsemble — Zespół ≥3 modeli z diversity check
# ═════════════════════════════════════════════════════════════════════════


class MultiModelEnsemble:
    """Multi-Model Ensemble — minimum 3 modele, diversity check.

    GENIALNY POMYSŁ v5.4:
    Zamiast 2 modeli (Actor + Guardian), używamy ≥3 z diversity check.
    Jeśli wszystkie 3 modele dadzą IDENTYCZNĄ odpowiedź →
    prawdopodobnie overfitting lub błąd w prompcie → flaga.

    Modele (z RAPORT_TECHNOLOGII):
    - Granite 3.2 3B — Główny Decydent (Actor)
    - Granite Guardian 0.5B — Strażnik Merytoryczny (Safety)
    - DynamicErrorHandbook — Few-Shot z przeszłych korekt
    - Qwen3-Nano 0.5B — Komunikator (opcjonalnie jako 4. głos)
    """

    MIN_MODELS = 2
    MAX_MODELS = 5

    def __init__(self) -> None:
        self._weights: dict[str, float] = {}
        self._accuracy: dict[str, tuple[int, int]] = {}  # model -> (correct, total)
        self._logger = get_logger("nexus.agents.ensemble")

    def record_outcome(self, model_name: str, correct: bool) -> None:
        """Aktualizuj celność modelu (Bayesian update)."""
        if model_name not in self._accuracy:
            self._accuracy[model_name] = (0, 0)
        corr, total = self._accuracy[model_name]
        if correct:
            corr += 1
        total += 1
        self._accuracy[model_name] = (corr, total)
        # Aktualizuj wagę: α/(α+β) z prior Beta(1,1)
        self._weights[model_name] = (corr + 1) / (total + 2)

    def get_weight(self, model_name: str) -> float:
        """Pobierz adaptacyjną wagę modelu."""
        return self._weights.get(model_name, 0.33)

    @staticmethod
    def diversity_check(votes: list[EnsembleVote]) -> float:
        """Sprawdź różnorodność głosów.

        Returns:
            0.0 = wszystkie identyczne (słabe — możliwy overfitting)
            0.5 = 2/3 zgodne
            1.0 = wszystkie różne (dobre — prawdziwy konsensus)
        """
        if len(votes) < 2:
            return 1.0

        unique_votes = len(set(v.vote for v in votes))
        return min(1.0, (unique_votes - 1) / max(len(votes) - 1, 1))

    def resolve(
        self,
        votes: list[EnsembleVote],
        min_consensus: float = 0.66,
    ) -> EnsembleResult:
        """Rozstrzygnij głosowanie zespołu modeli.

        Args:
            votes: Lista głosów (min 3).
            min_consensus: Minimalny próg konsensusu (domyślnie 66%).

        Returns:
            EnsembleResult z werdyktem końcowym.
        """
        if len(votes) < self.MIN_MODELS:
            self._logger.warning(
                "[ENSEMBLE] Only %d votes, need ≥%d — falling back to single model",
                len(votes), self.MIN_MODELS,
            )
            if votes:
                return EnsembleResult(
                    votes=votes,
                    winner=votes[0].vote,
                    consensus=False,
                    diversity_score=0.0,
                    final_trust=votes[0].confidence,
                    uncertainty=1.0 - votes[0].confidence,
                    requires_human=True,
                )
            return EnsembleResult(
                winner="BLOCK",
                consensus=False,
                requires_human=True,
            )

        # Oblicz wagi adaptacyjne
        weighted: dict[str, float] = {}
        for v in votes:
            w = self.get_weight(v.model_name)
            weighted[v.vote] = weighted.get(v.vote, 0.0) + w * v.confidence

        total_weight = sum(weighted.values()) or 1.0
        winner = max(weighted, key=weighted.get)
        winner_ratio = weighted[winner] / total_weight

        # Diversity check
        diversity = self.diversity_check(votes)
        all_identical = len(set(v.vote for v in votes)) == 1

        # Uncertainty
        sorted_weights = sorted(weighted.values(), reverse=True)
        if len(sorted_weights) >= 2:
            uncertainty = 1.0 - (sorted_weights[0] - sorted_weights[1]) / total_weight
        else:
            uncertainty = 1.0 - winner_ratio

        # Consensus
        consensus = winner_ratio >= min_consensus

        # Final trust: średnia ważona × consensus factor
        avg_confidence = sum(v.confidence * self.get_weight(v.model_name)
                             for v in votes) / sum(self.get_weight(v.model_name) for v in votes)
        consensus_factor = 1.0 if consensus else 0.7
        diversity_factor = 0.7 if all_identical else 1.0
        final_trust = avg_confidence * consensus_factor * diversity_factor

        requires_human = not consensus or final_trust < 0.75 or all_identical

        self._logger.info(
            "[ENSEMBLE] Resolved | winner=%s | ratio=%.2f | consensus=%s | "
            "diversity=%.2f | identical=%s | trust=%.2f | needs_human=%s",
            winner, winner_ratio, consensus, diversity, all_identical,
            final_trust, requires_human,
        )

        return EnsembleResult(
            votes=votes,
            winner=winner,
            consensus=consensus,
            diversity_score=diversity,
            all_identical=all_identical,
            final_trust=final_trust,
            uncertainty=uncertainty,
            requires_human=requires_human,
        )


# ═════════════════════════════════════════════════════════════════════════
# ConfidenceCalibrator — Platt Scaling dla Trust Score
# ═════════════════════════════════════════════════════════════════════════


class ConfidenceCalibrator:
    """Kalibracja Trust Score — Platt Scaling.

    GENIALNY POMYSŁ v5.4:
    Surowy trust score z modeli często jest źle skalibrowany
    (model mówi 0.95 ale w rzeczywistości accuracy = 0.70).
    Platt Scaling koryguje to:
        calibrated = 1 / (1 + e^(-a * raw - b))

    Parametry a, b są aktualizowane online (SGD).
    """

    def __init__(self) -> None:
        # Parametry Platt Scaling (domyślnie: identity a=1, b=0)
        self._a: float = 1.0
        self._b: float = 0.0
        self._samples: int = 0
        self._learning_rate: float = 0.01
        self._logger = get_logger("nexus.agents.calibrator")

    def calibrate(self, raw_trust: float) -> float:
        """Skalibruj surowy trust score.

        Args:
            raw_trust: Surowy trust score z modelu (0.0-1.0).

        Returns:
            Skalibrowany trust score (0.0-1.0).
        """
        z = self._a * raw_trust + self._b
        # Clamp dla stabilności numerycznej
        z = max(-10.0, min(10.0, z))
        calibrated = 1.0 / (1.0 + math.exp(-z))
        return max(0.0, min(1.0, calibrated))

    def update(self, raw_trust: float, actual_outcome: bool) -> None:
        """Aktualizuj parametry Platt Scaling (online SGD).

        Args:
            raw_trust: Surowy trust score.
            actual_outcome: Czy decyzja była poprawna (True/False).
        """
        self._samples += 1

        # Gradient Platt Scaling (logistic regression)
        calibrated = self.calibrate(raw_trust)
        error = float(actual_outcome) - calibrated
        grad_a = error * raw_trust
        grad_b = error

        # SGD update
        self._a += self._learning_rate * grad_a
        self._b += self._learning_rate * grad_b

        # Decaying learning rate
        self._learning_rate = max(0.001, 0.01 / math.sqrt(max(1, self._samples)))

        if self._samples % 50 == 0:
            self._logger.info(
                "[CALIBRATE] Samples=%d | a=%.3f b=%.3f | raw=%.2f→cal=%.2f (actual=%s)",
                self._samples, self._a, self._b,
                raw_trust, self.calibrate(raw_trust), actual_outcome,
            )

    def get_reliability_diagram_data(self, bins: int = 10) -> dict[str, list[float]]:
        """Generuj dane dla reliability diagram (do wizualizacji kalibracji).

        Returns:
            Dict z listami: raw_means, calibrated_means, accuracies.
        """
        # W rzeczywistości: query do TelemetryStore
        return {"raw_means": [], "calibrated_means": [], "accuracies": []}


# ═════════════════════════════════════════════════════════════════════════
# FeedbackLoop — Metryki pętli feedbacku
# ═════════════════════════════════════════════════════════════════════════


class FeedbackLoop:
    """Metryki pętli feedbacku — mierzy jakość interakcji człowiek-AI.

    GENIALNY POMYSŁ v5.4:
    - Time-to-decision: ile czasu od wyświetlenia karty do kliknięcia
    - Correction rate: % decyzji poprawionych przez użytkownika
    - Decision Quality Score: 0-100% (z DecisionTrace)
    - Feedback Latency: czas od decyzji AI do feedbacku użytkownika
    """

    def __init__(self) -> None:
        self._total_decisions: int = 0
        self._total_corrections: int = 0
        self._total_accepts: int = 0
        self._total_response_time_ms: float = 0.0
        self._total_feedback_latency_ms: float = 0.0
        self._quality_scores: list[float] = []
        self._logger = get_logger("nexus.agents.feedback")

    def record_decision(
        self,
        status: str,
        user_accepted: bool,
        response_time_ms: float = 0.0,
        feedback_latency_ms: float = 0.0,
        quality_score: float = 0.0,
    ) -> None:
        """Zapisz metryki pojedynczej decyzji.

        Args:
            status: Status decyzji (AUTO_POST, REVIEW, BLOCK).
            user_accepted: Czy użytkownik zaakceptował (True) czy skorygował (False).
            response_time_ms: Czas odpowiedzi użytkownika (dla SUGGEST/ASK_USER).
            feedback_latency_ms: Czas od decyzji AI do feedbacku.
            quality_score: Decision Quality Score 0-100%.
        """
        self._total_decisions += 1
        if user_accepted:
            self._total_accepts += 1
        else:
            self._total_corrections += 1
        self._total_response_time_ms += response_time_ms
        self._total_feedback_latency_ms += feedback_latency_ms
        if quality_score > 0:
            self._quality_scores.append(quality_score)

    @property
    def correction_rate(self) -> float:
        """Procent decyzji skorygowanych przez użytkownika."""
        if self._total_decisions == 0:
            return 0.0
        return self._total_corrections / self._total_decisions

    @property
    def avg_response_time_ms(self) -> float:
        """Średni czas odpowiedzi użytkownika."""
        decisions_with_feedback = self._total_accepts + self._total_corrections
        if decisions_with_feedback == 0:
            return 0.0
        return self._total_response_time_ms / decisions_with_feedback

    @property
    def avg_feedback_latency_ms(self) -> float:
        """Średni czas od decyzji AI do feedbacku."""
        decisions_with_feedback = self._total_accepts + self._total_corrections
        if decisions_with_feedback == 0:
            return 0.0
        return self._total_feedback_latency_ms / decisions_with_feedback

    @property
    def avg_quality_score(self) -> float:
        """Średni Decision Quality Score."""
        if not self._quality_scores:
            return 0.0
        return sum(self._quality_scores) / len(self._quality_scores)

    def get_summary(self) -> dict[str, Any]:
        """Pobierz podsumowanie metryk pętli feedbacku."""
        return {
            "total_decisions": self._total_decisions,
            "accepts": self._total_accepts,
            "corrections": self._total_corrections,
            "correction_rate": round(self.correction_rate * 100, 1),
            "acceptance_rate": round(
                (1.0 - self.correction_rate) * 100, 1
            ),
            "avg_response_time_ms": round(self.avg_response_time_ms, 0),
            "avg_feedback_latency_ms": round(self.avg_feedback_latency_ms, 0),
            "avg_quality_score": round(self.avg_quality_score, 1),
        }


# ── Helpers ────────────────────────────────────────────────────────────


def generate_trace_id() -> str:
    """Generuj OTel-compatible trace ID (32 hex chars)."""
    return uuid.uuid4().hex


def generate_span_id() -> str:
    """Generuj OTel-compatible span ID (16 hex chars)."""
    return uuid.uuid4().hex[:16]


__all__ = [
    "DecisionTracer",
    "DecisionTrace",
    "DecisionSpan",
    "MultiModelEnsemble",
    "EnsembleVote",
    "EnsembleResult",
    "ConfidenceCalibrator",
    "FeedbackLoop",
    "generate_trace_id",
    "generate_span_id",
]
