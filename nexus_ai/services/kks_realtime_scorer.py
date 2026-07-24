"""
kks_realtime_scorer.py — v7.0 Audit Faza 1: Scoring Ryzyka KKS 0-100 w Czasie Rzeczywistym.

Raport v7.0, Rekomendacja #3:
  "Dodaj scoring ryzyka KKS 0-100 w czasie rzeczywistym"

Raport v7.0, Sekcja 10 (Fraud Detection):
  "Brak dedykowanego scoringu fraud 0-100 w czasie rzeczywistym"

Enterprise v7.0 Audit:
  - Scoring 0-100 per transakcja (natychmiastowy)
  - 7-wymiarowy model: offense_type, kwota, historia, recentywność, kontrahent, dokument, behavioral
  - 3 strefy: ZIELONA (0-30), ŻÓŁTA (31-60), CZERWONA (61-100)
  - Wizualizacja "termometru KKS" dla UI dashboard
  - Rekomendacje akcji: auto-post / triage / block
  - Integracja z OPA verdicts (kks_offense_type, kks_penalty_severity)
  - Historia scoringu per JDG dla trend analysis
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import StrEnum
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.kks.scorer")


# ═══════════════════════════════════════════════════════════════════════════
# Typy
# ═══════════════════════════════════════════════════════════════════════════

class KksRiskZone(StrEnum):
    """Strefa ryzyka KKS."""
    GREEN = "GREEN"     # 0-30: Auto-post
    YELLOW = "YELLOW"   # 31-60: Triage
    RED = "RED"         # 61-100: Block


class KksOffenseWeight:
    """Wagi per typ przestępstwa KKS (zgodne z raportem)."""

    WEIGHTS: dict[str, float] = {
        "EMPTY_INVOICE": 1.0,          # Art. 62
        "TAX_EVASION": 0.9,            # Art. 54
        "VAT_CAROUSEL": 0.95,          # Art. 62 + 300 KK
        "UNRELIABLE_BOOKS": 0.7,       # Art. 56
        "UNRELIABLE_VAT": 0.7,         # Art. 57
        "DESTROYED_DOCUMENTS": 0.8,    # Art. 68
        "OBSTRUCTION": 0.7,            # Art. 69
        "DECLARATION_NOT_FILED": 0.5,  # Art. 77
        "TAX_UNPAID": 0.5,             # Art. 79
        "WRONG_VAT_RATE": 0.4,         # Art. 64
        "PENALTY_CALC": 0.3,           # Art. 23
    }

    SEVERITY_MULTIPLIER: dict[str, float] = {
        "CRITICAL": 1.0,
        "HIGH": 0.75,
        "MEDIUM": 0.5,
        "LOW": 0.25,
    }


@dataclass
class KksScoreBreakdown:
    """Rozbicie scoringu na wymiary."""

    offense_type_score: float = 0.0       # 0-30 pkt
    amount_score: float = 0.0             # 0-20 pkt
    history_score: float = 0.0            # 0-15 pkt
    recency_score: float = 0.0            # 0-10 pkt
    contractor_score: float = 0.0         # 0-10 pkt
    document_score: float = 0.0           # 0-10 pkt
    behavioral_score: float = 0.0         # 0-5 pkt


@dataclass
class KksRealTimeScore:
    """Wynik scoringu KKS w czasie rzeczywistym."""

    total_score: float  # 0-100
    risk_zone: KksRiskZone
    breakdown: KksScoreBreakdown = field(default_factory=KksScoreBreakdown)
    offense_type: str = ""
    severity: str = "LOW"
    max_penalty_pln: float = 0.0
    flags: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)
    requires_action: bool = False
    action_type: str = "ALLOW"  # ALLOW, MONITOR, TRIAGE, BLOCK
    scored_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())
    invoice_id: str = ""
    jdg_id: str = ""


class KksRealtimeScorer:
    """Scoring ryzyka KKS w czasie rzeczywistym (0-100).

    Raport v7.0, Rekomendacja #3 + Sekcja 10 (Fraud Detection).

    Usage:
        scorer = KksRealtimeScorer()
        score = scorer.score_invoice(invoice_data, opa_verdict, jdg_history)
        if score.risk_zone == KksRiskZone.RED:
            logger.critical("BLOCK: KKS score %d — %s", score.total_score, score.flags)
    """

    # Progi (v7.0 Audit: zaostrzone — RED już od 40 dla CRITICAL offenses)
    GREEN_THRESHOLD = 25
    YELLOW_THRESHOLD = 40

    # Maksymalne wagi per wymiar
    MAX_OFFENSE_TYPE = 30
    MAX_AMOUNT = 20
    MAX_HISTORY = 15
    MAX_RECENCY = 10
    MAX_CONTRACTOR = 10
    MAX_DOCUMENT = 10
    MAX_BEHAVIORAL = 5

    # Kwoty progowe
    AMOUNT_HIGH_THRESHOLD = 50_000     # > 50k PLN
    AMOUNT_CRITICAL_THRESHOLD = 500_000  # > 500k PLN

    def __init__(self) -> None:
        # Historia scoringu per JDG
        self._score_history: dict[str, list[KksRealTimeScore]] = {}
        self._total_scored: int = 0

    # ── Główny scoring ─────────────────────────────────────────────────

    def score_invoice(
        self,
        invoice_data: dict[str, Any],
        opa_verdict: dict[str, Any] | None = None,
        jdg_history: dict[str, Any] | None = None,
    ) -> KksRealTimeScore:
        """Oblicz scoring KKS 0-100 dla pojedynczej faktury.

        Args:
            invoice_data: Dane faktury (amount_gross, contractor_nip, date, kks_flag, itd.).
            opa_verdict: Werdykt OPA (rule_id, kks_offense_type, kks_penalty_severity, _routing).
            jdg_history: Historia JDG (poprzednie incydenty KKS, kontrole).

        Returns:
            KksRealTimeScore z pełnym rozbiciem i rekomendacjami.
        """
        breakdown = KksScoreBreakdown()
        flags: list[str] = []
        recommendations: list[str] = []

        verdict = opa_verdict or {}
        history = jdg_history or {}
        invoice_id = str(invoice_data.get("id", invoice_data.get("number", "unknown")))
        jdg_id = str(history.get("jdg_id", "unknown"))

        # 1. Offense Type Score (0-30)
        offense_type = verdict.get("kks_offense_type", "")
        severity = verdict.get("kks_penalty_severity", "LOW")
        weight = KksOffenseWeight.WEIGHTS.get(offense_type, 0.2)
        severity_mult = KksOffenseWeight.SEVERITY_MULTIPLIER.get(severity, 0.25)
        breakdown.offense_type_score = min(self.MAX_OFFENSE_TYPE, 30 * weight * severity_mult)
        if offense_type:
            flags.append(f"KKS: {offense_type} (severity={severity})")

        # 2. Amount Score (0-20)
        amount = float(invoice_data.get("amount_gross", invoice_data.get("amount", 0)))
        if amount > self.AMOUNT_CRITICAL_THRESHOLD:
            breakdown.amount_score = 20
            flags.append(f"Kwota > 500k PLN: {amount:,.2f}")
        elif amount >= self.AMOUNT_HIGH_THRESHOLD:
            breakdown.amount_score = 12
            flags.append(f"Wysoka kwota >= 50k PLN: {amount:,.2f}")
        elif amount > 15_000:
            breakdown.amount_score = 6
        elif amount > 0:
            breakdown.amount_score = 2

        # 3. History Score (0-15)
        prev_incidents = history.get("kks_incidents_60m", history.get("kks_offenses_count", 0))
        prev_controls = history.get("tax_inspections_60m", 0)

        if prev_incidents >= 3:
            breakdown.history_score = 15
            flags.append(f"Recydywa skarbowa: {prev_incidents} incydentów")
        elif prev_incidents >= 1:
            breakdown.history_score = 8
            flags.append(f"Poprzednie incydenty KKS: {prev_incidents}")
        if prev_controls >= 2:
            breakdown.history_score = min(self.MAX_HISTORY, breakdown.history_score + 5)
            flags.append(f"Wiele kontroli w przeszłości: {prev_controls}")

        # 4. Recency Score (0-10)
        last_incident_date = history.get("last_kks_incident_date", "")
        if last_incident_date:
            try:
                last_date = pendulum.parse(last_incident_date)
                days_ago = (pendulum.now("UTC") - last_date).days
                if days_ago <= 30:
                    breakdown.recency_score = 10
                    flags.append(f"Ostatni incydent < 30 dni temu")
                elif days_ago <= 90:
                    breakdown.recency_score = 6
                elif days_ago <= 365:
                    breakdown.recency_score = 3
            except (pendulum.ParserError, ValueError, TypeError):
                pass

        # 5. Contractor Score (0-10)
        contractor_nip = invoice_data.get("contractor_nip", "")
        contractor_country = invoice_data.get("contractor_country", history.get("vendor_country", ""))

        # Kraje wysokiego ryzyka FATF
        fatf_high_risk = {"IR", "KP", "MM", "SY", "VE", "AF", "YE", "SS"}
        if contractor_country.upper() in fatf_high_risk:
            breakdown.contractor_score += 5
            flags.append(f"Kontrahent z kraju FATF: {contractor_country}")

        # Nowy kontrahent (< 3 miesiące)
        is_new = invoice_data.get("is_first_transaction", False)
        if is_new:
            breakdown.contractor_score += 5
            flags.append("Pierwsza transakcja z kontrahentem")

        breakdown.contractor_score = min(self.MAX_CONTRACTOR, breakdown.contractor_score)

        # 6. Document Score (0-10)
        has_ksef = invoice_data.get("ksef_sent", True)
        has_upo = invoice_data.get("ksef_upo", True)
        is_correction = invoice_data.get("is_credit_note", False)

        if not has_ksef:
            breakdown.document_score += 5
            flags.append("Brak KSeF")
        if not has_upo:
            breakdown.document_score += 3
            flags.append("Brak UPO KSeF")
        if is_correction:
            breakdown.document_score += 3
            flags.append("Faktura korygująca")
        breakdown.document_score = min(self.MAX_DOCUMENT, breakdown.document_score)

        # 7. Behavioral Score (0-5)
        timestamp_str = invoice_data.get("created_at", "")
        if timestamp_str:
            try:
                hour = pendulum.parse(timestamp_str).hour
                if hour < 6 or hour >= 22:
                    breakdown.behavioral_score += 3
                    flags.append(f"Nietypowa pora: {hour}:00")
            except (pendulum.ParserError, ValueError, TypeError):
                pass

        # Okrągła kwota
        if amount > 0 and amount % 1000 == 0:
            breakdown.behavioral_score += 2
            flags.append("Okrągła kwota")

        breakdown.behavioral_score = min(self.MAX_BEHAVIORAL, breakdown.behavioral_score)

        # ── Total ──────────────────────────────────────────────────────
        total = sum([
            breakdown.offense_type_score,
            breakdown.amount_score,
            breakdown.history_score,
            breakdown.recency_score,
            breakdown.contractor_score,
            breakdown.document_score,
            breakdown.behavioral_score,
        ])

        # CRITICAL severity bonus — automatycznie podnosi score
        # (Raport v7.0: przestępstwa CRITICAL wymagają natychmiastowej blokady)
        if severity == "CRITICAL" and offense_type:
            total += 15
            flags.append("⚠️ CRITICAL severity — automatyczny bonus +15 pkt")
        total = min(100.0, max(0.0, total))

        # Strefa
        if total <= self.GREEN_THRESHOLD:
            zone = KksRiskZone.GREEN
            action = "ALLOW"
            recommendations.append("Niskie ryzyko KKS — auto-post")
        elif total <= self.YELLOW_THRESHOLD:
            zone = KksRiskZone.YELLOW
            action = "TRIAGE"
            recommendations.append("Średnie ryzyko KKS — triage + monitoring")
            recommendations.append("Rozważ czynny żal jeśli wykryto nieprawidłowości")
        else:
            zone = KksRiskZone.RED
            action = "BLOCK"
            recommendations.append("WYSOKIE RYZYKO KKS — BLOCK!")
            recommendations.append("NATYCHMIAST złóż czynny żal (Art. 16 KKS)")
            recommendations.append("Skontaktuj się z doradcą podatkowym")

        # Oblicz szacunkową karę maksymalną
        max_penalty = self._calculate_max_penalty(verdict, amount)

        score = KksRealTimeScore(
            total_score=round(total, 1),
            risk_zone=zone,
            breakdown=breakdown,
            offense_type=offense_type,
            severity=severity,
            max_penalty_pln=max_penalty,
            flags=flags,
            recommendations=recommendations,
            requires_action=zone != KksRiskZone.GREEN,
            action_type=action,
            invoice_id=invoice_id,
            jdg_id=jdg_id,
        )

        # Zapisz w historii
        if jdg_id not in self._score_history:
            self._score_history[jdg_id] = []
        self._score_history[jdg_id].append(score)
        self._total_scored += 1

        if zone == KksRiskZone.RED:
            logger.warning(
                "[KKS-SCORER] RED ALERT score=%d offense=%s amount=%.2f flags=%d",
                int(total), offense_type, amount, len(flags),
            )

        return score

    # ── Bulk Scoring ───────────────────────────────────────────────────

    def score_batch(
        self,
        invoices: list[dict[str, Any]],
        jdg_history: dict[str, Any] | None = None,
    ) -> list[KksRealTimeScore]:
        """Scoring batchowy dla wielu faktur.

        Returns:
            Lista KksRealTimeScore posortowana po score malejąco.
        """
        results = []
        history = jdg_history or {}
        for inv in invoices:
            score = self.score_invoice(inv, jdg_history=history)
            results.append(score)
        return sorted(results, key=lambda s: s.total_score, reverse=True)

    # ── Trend Analysis ─────────────────────────────────────────────────

    def get_trend(self, jdg_id: str, months: int = 12) -> dict[str, Any]:
        """Analiza trendu scoringu KKS dla JDG.

        Returns:
            Dict z trendem, średnią, maksimum i wykresem punktów.
        """
        history = self._score_history.get(jdg_id, [])
        if not history:
            return {"trend": "unknown", "avg_score": 0, "max_score": 0, "data_points": 0}

        scores = [s.total_score for s in history]
        avg = sum(scores) / len(scores)
        max_score = max(scores)

        # Trend: porównaj pierwszą i drugą połowę
        mid = len(scores) // 2
        first_half_avg = sum(scores[:mid]) / mid if mid > 0 else 0
        second_half_avg = sum(scores[mid:]) / (len(scores) - mid) if len(scores) > mid else first_half_avg

        if second_half_avg > first_half_avg * 1.1:
            trend = "worsening"
        elif second_half_avg < first_half_avg * 0.9:
            trend = "improving"
        else:
            trend = "stable"

        return {
            "trend": trend,
            "avg_score": round(avg, 1),
            "max_score": round(max_score, 1),
            "recent_score": round(scores[-1], 1) if scores else 0,
            "data_points": len(scores),
            "first_half_avg": round(first_half_avg, 1),
            "second_half_avg": round(second_half_avg, 1),
        }

    def get_risk_summary(self, jdg_id: str) -> dict[str, Any]:
        """Podsumowanie ryzyka KKS dla JDG."""
        history = self._score_history.get(jdg_id, [])
        if not history:
            return {"level": "LOW", "total_scored": 0, "red_count": 0, "yellow_count": 0, "green_count": 0}

        red = sum(1 for s in history if s.risk_zone == KksRiskZone.RED)
        yellow = sum(1 for s in history if s.risk_zone == KksRiskZone.YELLOW)
        green = sum(1 for s in history if s.risk_zone == KksRiskZone.GREEN)

        if red > 0:
            level = "HIGH"
        elif yellow / max(len(history), 1) > 0.3:
            level = "MEDIUM"
        else:
            level = "LOW"

        return {
            "level": level,
            "total_scored": len(history),
            "red_count": red,
            "yellow_count": yellow,
            "green_count": green,
            "trend": self.get_trend(jdg_id),
        }

    # ── Max Penalty Calculator ──────────────────────────────────────────

    @staticmethod
    def _calculate_max_penalty(verdict: dict[str, Any], amount: float) -> float:
        """Oblicz szacunkową maksymalną karę na podstawie werdyktu OPA."""
        daily_rates = verdict.get("kks_max_daily_rates", 0)
        offense_type = verdict.get("kks_offense_type", "")

        if offense_type == "EMPTY_INVOICE":
            # Art. 62 — do 25 lat pozbawienia wolności, grzywna do 720 stawek
            return amount * 1.0  # 100% kary = równowartość faktury

        if daily_rates > 0:
            # Stawka dzienna ≈ 1/30 minimalnego wynagrodzenia (4300 PLN / 30 ≈ 143 PLN)
            # Max 400-krotność stawki dziennej
            min_wage_daily = 4300 / 30
            max_daily_rate = min_wage_daily * 400
            return daily_rates * max_daily_rate

        # Domyślnie: 10% kwoty faktury jako szacunkowa maksymalna kara
        return amount * 0.1

    # ── Rego Integration ────────────────────────────────────────────────

    @staticmethod
    def score_to_rego_input(score: KksRealTimeScore) -> dict[str, Any]:
        """Konwertuj scoring do formatu input dla OPA/Rego."""
        return {
            "kks_realtime_score": score.total_score,
            "kks_risk_zone": score.risk_zone.value,
            "kks_offense_type_score": score.breakdown.offense_type_score,
            "kks_amount_score": score.breakdown.amount_score,
            "kks_history_score": score.breakdown.history_score,
            "kks_flags": score.flags,
            "kks_action_required": score.requires_action,
            "kks_action_type": score.action_type,
        }

    # ── Statistics ─────────────────────────────────────────────────────

    @property
    def total_scored(self) -> int:
        return self._total_scored

    def get_global_stats(self) -> dict[str, Any]:
        """Globalne statystyki scoringu."""
        all_scores = [
            s for scores in self._score_history.values()
            for s in scores
        ]
        if not all_scores:
            return {"total": 0, "avg_score": 0, "red_pct": 0}

        red = sum(1 for s in all_scores if s.risk_zone == KksRiskZone.RED)
        return {
            "total_scored": len(all_scores),
            "avg_score": round(sum(s.total_score for s in all_scores) / len(all_scores), 1),
            "red_count": red,
            "red_pct": round(red / len(all_scores) * 100, 1),
            "unique_jdg": len(self._score_history),
        }
