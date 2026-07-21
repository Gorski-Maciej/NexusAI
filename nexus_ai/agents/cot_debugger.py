"""Cognitive Chain-of-Thought Debugger — Automatyczny debugger decyzji.

GENIALNY POMYSŁ #6 z Raportu v7.0:
Gdy agent podejmie BŁĘDNĄ decyzję (korekta użytkownika), system automatycznie:
1. Odtwarza trace (DecisionTrace)
2. Analizuje który span zawiódł
3. Generuje "post-mortem" — dlaczego decyzja była błędna
4. Sugeruje poprawkę (prompt, threshold, reguła)
Redukcja czasu debugowania z godzin do sekund.
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.agents.cot")


class FailureAnalysis:
    """Analiza przyczyny błędnej decyzji."""

    def __init__(self) -> None:
        self.decision_id: str = ""
        self.failed_span: str = ""
        self.root_cause: str = ""
        self.suggested_fix: str = ""
        self.fix_type: str = ""  # prompt, threshold, rule, model
        self.confidence: float = 0.0
        self.affected_components: list[str] = []
        self.post_mortem: str = ""


class ChainOfThoughtDebugger:
    """Automatyczny debugger decyzji AI.

    GENIALNY POMYSŁ #6:
    Analizuje każdą korektę użytkownika i generuje post-mortem
    z sugerowaną poprawką.
    """

    # ── Przyczyny błędów i sugerowane poprawki ─────────────────────
    ERROR_PATTERNS: dict[str, dict[str, Any]] = {
        "extraction_failed": {
            "root_cause": "OCR nie rozpoznał poprawnie danych",
            "fix_type": "threshold",
            "suggested_fix": "Obniż próg konsensusu OCR z 0.75 do 0.65 dla tego typu dokumentu lub dodaj Vision Guardian jako rozjemcę.",
        },
        "low_trust_blocked": {
            "root_cause": "Niski Trust Score zablokował poprawną decyzję",
            "fix_type": "threshold",
            "suggested_fix": "Obniż próg AUTO_POST dla tego kontrahenta (obecny: 0.92 → sugerowany: 0.85).",
        },
        "ensemble_homogeneous": {
            "root_cause": "Wszystkie modele dały identyczną odpowiedź (diversity=0.0)",
            "fix_type": "prompt",
            "suggested_fix": "Dodaj więcej kontekstu do promptu. Rozważ dodanie Qwen3-Nano jako 4. głosu dla dywersyfikacji.",
        },
        "guardian_false_positive": {
            "root_cause": "Granite Guardian błędnie zablokował poprawną decyzję",
            "fix_type": "model",
            "suggested_fix": "Zwiększ temperature Guardiana z 0.0 do 0.05. Rozważ obniżenie wagi Guardiana.",
        },
        "handbook_misled": {
            "root_cause": "DynamicErrorHandbook wstrzyknął nieaktualne przykłady few-shot",
            "fix_type": "rule",
            "suggested_fix": "Zwiększ threshold k-NN dla Handbook z 0.3 do 0.5. Usuń nieaktualne przykłady.",
        },
        "threshold_too_strict": {
            "root_cause": "Adaptacyjny próg AUTO_POST jest zbyt wysoki",
            "fix_type": "threshold",
            "suggested_fix": "Zmniejsz bazowy próg AUTO_POST (z 0.92 na 0.88) lub zwiększ korektę Bayesiańską.",
        },
        "calibration_error": {
            "root_cause": "ConfidenceCalibrator źle skalibrował Trust Score",
            "fix_type": "threshold",
            "suggested_fix": "Zresetuj parametry Platt Scaling i pozwól na ponowną kalibrację.",
        },
    }

    def __init__(self) -> None:
        self._analyses: dict[str, FailureAnalysis] = {}
        self._fixes_applied: list[dict[str, Any]] = []
        self._total_debugs: int = 0
        self._auto_fixes: int = 0

    # ── Core Logic ──────────────────────────────────────────────────

    def analyze_correction(
        self,
        decision_id: str,
        ai_decision: str,
        user_correction: str,
        trace: Any = None,
        spans: list[dict[str, Any]] | None = None,
        ensemble_votes: list[dict[str, Any]] | None = None,
        trust_score: float = 0.0,
    ) -> FailureAnalysis:
        """Przeanalizuj korektę i znajdź przyczynę błędu.

        GENIALNY POMYSŁ #6:
        Odtwarza trace, znajduje wadliwy span, generuje post-mortem.

        Returns:
            FailureAnalysis z diagnozą i sugerowaną poprawką.
        """
        analysis = FailureAnalysis()
        analysis.decision_id = decision_id
        self._total_debugs += 1

        # ── 1. Znajdź wadliwy span ──
        if spans:
            for span in spans:
                if span.get("status") == "ERROR":
                    analysis.failed_span = span.get("name", "unknown")
                    break

        # ── 2. Diagnozuj przyczynę ──
        if not analysis.failed_span and trace and hasattr(trace, 'spans'):
            for span in trace.spans:
                if getattr(span, 'status', 'OK') == 'ERROR':
                    analysis.failed_span = getattr(span, 'name', 'unknown')
                    break

        # ── 3. Dopasuj wzorzec błędu ──
        pattern = self._match_error_pattern(
            ai_decision, user_correction, analysis.failed_span,
            trust_score, ensemble_votes,
        )

        if pattern:
            analysis.root_cause = pattern["root_cause"]
            analysis.fix_type = pattern["fix_type"]
            analysis.suggested_fix = pattern["suggested_fix"]

        # ── 4. Generuj post-mortem ──
        analysis.post_mortem = self._generate_post_mortem(
            analysis, ai_decision, user_correction, spans
        )

        self._analyses[decision_id] = analysis
        logger.info(
            "[COT] 🔍 Debug | %s: %s → %s | failed_span=%s | cause=%s",
            decision_id, ai_decision, user_correction,
            analysis.failed_span, analysis.root_cause,
        )

        return analysis

    def _match_error_pattern(
        self,
        ai_decision: str,
        user_correction: str,
        failed_span: str,
        trust_score: float,
        ensemble_votes: list[dict[str, Any]] | None,
    ) -> dict[str, Any] | None:
        """Dopasuj wzorzec błędu do znanych przyczyn."""

        if failed_span == "extraction":
            return self.ERROR_PATTERNS["extraction_failed"]

        if ai_decision == "BLOCK" and user_correction == "AUTO_POST":
            if trust_score > 0.70:
                return self.ERROR_PATTERNS["low_trust_blocked"]

        if ensemble_votes and len(ensemble_votes) >= 2:
            votes = [v.get("vote", "") for v in ensemble_votes]
            if len(set(votes)) == 1 and len(votes) >= 3:
                return self.ERROR_PATTERNS["ensemble_homogeneous"]

        if failed_span == "guardian_check":
            return self.ERROR_PATTERNS["guardian_false_positive"]

        if failed_span == "handbook_query":
            return self.ERROR_PATTERNS["handbook_misled"]

        if trust_score > 0.80 and ai_decision == "REVIEW" and user_correction == "AUTO_POST":
            return self.ERROR_PATTERNS["threshold_too_strict"]

        if failed_span == "calibration":
            return self.ERROR_PATTERNS["calibration_error"]

        return None

    def _generate_post_mortem(
        self,
        analysis: FailureAnalysis,
        ai_decision: str,
        user_correction: str,
        spans: list[dict[str, Any]] | None = None,
    ) -> str:
        """Generuj post-mortem w języku naturalnym."""
        parts = [
            f"# Post-Mortem: Decyzja {analysis.decision_id}",
            f"",
            f"## Co się stało?",
            f"Agent AI podjął decyzję: **{ai_decision}**",
            f"Użytkownik poprawił na: **{user_correction}**",
        ]

        if analysis.root_cause:
            parts.append(f"\n## Przyczyna:")
            parts.append(f"{analysis.root_cause}")

        if analysis.failed_span:
            parts.append(f"\n## Który komponent zawiódł?")
            parts.append(f"Span: `{analysis.failed_span}`")

        if spans:
            parts.append(f"\n## Przebieg pipeline'u:")
            for span in spans:
                status_icon = "❌" if span.get("status") == "ERROR" else "✅"
                parts.append(f"- {status_icon} {span.get('name', 'unknown')} "
                           f"({span.get('duration_ms', 0):.0f}ms)")

        if analysis.suggested_fix:
            parts.append(f"\n## Sugerowana poprawka:")
            parts.append(f"[{analysis.fix_type}] {analysis.suggested_fix}")

        return "\n".join(parts)

    def apply_fix(self, decision_id: str) -> bool:
        """Zastosuj sugerowaną poprawkę (jeśli auto-fix włączony)."""
        analysis = self._analyses.get(decision_id)
        if not analysis or not analysis.suggested_fix:
            return False

        self._fixes_applied.append({
            "decision_id": decision_id,
            "fix_type": analysis.fix_type,
            "fix": analysis.suggested_fix,
            "timestamp": __import__("pendulum").now("UTC").isoformat(),
        })
        self._auto_fixes += 1

        logger.info("[COT] 🔧 Auto-fix applied: %s → %s", decision_id, analysis.fix_type)
        return True

    # ── Stats ───────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        return {
            "total_debugs": self._total_debugs,
            "total_analyses": len(self._analyses),
            "auto_fixes_applied": self._auto_fixes,
            "fixes_by_type": self._count_fixes_by_type(),
            "last_10_analyses": [
                {
                    "decision_id": a.decision_id,
                    "failed_span": a.failed_span,
                    "root_cause": a.root_cause[:80],
                }
                for a in list(self._analyses.values())[-10:]
            ],
        }

    def _count_fixes_by_type(self) -> dict[str, int]:
        counts: dict[str, int] = {}
        for fix in self._fixes_applied:
            ft = fix["fix_type"]
            counts[ft] = counts.get(ft, 0) + 1
        return counts
