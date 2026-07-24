"""
cross_jurisdiction_resolver.py — v7.0 Audit Faza 2 M2: Cross-Jurisdiction Tax Conflict Resolver.

Raport v7.0, Rekomendacja #11:
  "Dodaj cross-jurisdiction tax conflict resolver"

Raport v7.0, Genialny Pomysł #5:
  "System cross-jurisdiction tax conflict resolver"

Enterprise v7.0 Audit:
  - Analiza UPO (Umów o Unikaniu Podwójnego Opodatkowania)
  - Rekomendacja metody: wyłączenie z progresją vs proporcjonalne odliczenie
  - PE risk detection (permanent establishment)
  - WHT rate optimization (withholding tax)
  - Konflikt miejsce świadczenia usług B2B
  - Automatyczna rekomendacja rozwiązania z powołaniem na UPO
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.cross_jurisdiction")


# ═══════════════════════════════════════════════════════════════════════════
# Wbudowana baza UPO (Umowy o Unikaniu Podwójnego Opodatkowania)
# Klucz: kod kraju, Wartość: {metoda, WHT_dywidendy, WHT_odsetki, WHT_należności}
# ═══════════════════════════════════════════════════════════════════════════

_UPO_DATABASE: dict[str, dict[str, Any]] = {
    "DE": {"method": "exemption_with_progression", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.05},
    "FR": {"method": "exemption_with_progression", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.05},
    "GB": {"method": "proportional_credit", "wht_dividends": 0.10, "wht_interest": 0.05, "wht_royalties": 0.05},
    "US": {"method": "proportional_credit", "wht_dividends": 0.15, "wht_interest": 0.10, "wht_royalties": 0.10},
    "NL": {"method": "exemption_with_progression", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.05},
    "IT": {"method": "exemption_with_progression", "wht_dividends": 0.10, "wht_interest": 0.10, "wht_royalties": 0.10},
    "ES": {"method": "exemption_with_progression", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.05},
    "CZ": {"method": "exemption_with_progression", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.10},
    "SK": {"method": "exemption_with_progression", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.10},
    "AT": {"method": "exemption_with_progression", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.05},
    "UA": {"method": "proportional_credit", "wht_dividends": 0.10, "wht_interest": 0.10, "wht_royalties": 0.10},
    "CH": {"method": "exemption_with_progression", "wht_dividends": 0.15, "wht_interest": 0.10, "wht_royalties": 0.05},
    "IE": {"method": "exemption_with_progression", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.05},
    "SE": {"method": "exemption_with_progression", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.05},
    "NO": {"method": "proportional_credit", "wht_dividends": 0.15, "wht_interest": 0.05, "wht_royalties": 0.05},
    "CA": {"method": "proportional_credit", "wht_dividends": 0.15, "wht_interest": 0.10, "wht_royalties": 0.10},
    "AU": {"method": "proportional_credit", "wht_dividends": 0.15, "wht_interest": 0.10, "wht_royalties": 0.10},
    "JP": {"method": "proportional_credit", "wht_dividends": 0.10, "wht_interest": 0.10, "wht_royalties": 0.10},
    "KR": {"method": "proportional_credit", "wht_dividends": 0.10, "wht_interest": 0.10, "wht_royalties": 0.10},
    "AE": {"method": "proportional_credit", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.05},
    "SG": {"method": "proportional_credit", "wht_dividends": 0.05, "wht_interest": 0.05, "wht_royalties": 0.05},
    "IN": {"method": "proportional_credit", "wht_dividends": 0.10, "wht_interest": 0.10, "wht_royalties": 0.15},
    "CN": {"method": "proportional_credit", "wht_dividends": 0.10, "wht_interest": 0.10, "wht_royalties": 0.10},
    "BR": {"method": "proportional_credit", "wht_dividends": 0.15, "wht_interest": 0.15, "wht_royalties": 0.15},
    "MX": {"method": "proportional_credit", "wht_dividends": 0.05, "wht_interest": 0.10, "wht_royalties": 0.10},
}

# Kraje BEZ UPO z Polską
COUNTRIES_WITHOUT_UPO: set[str] = {
    "BM", "KY", "VG", "MH", "PA", "SC", "WS",
}

# Polskie stawki WHT bez UPO
STANDARD_WHT_DIVIDENDS = 0.19
STANDARD_WHT_INTEREST = 0.20
STANDARD_WHT_ROYALTIES = 0.20


@dataclass
class PEAnalysis:
    """Analiza ryzyka Permanent Establishment."""

    has_pe_risk: bool = False
    pe_factors: list[str] = field(default_factory=list)
    pe_type: str = ""  # fixed_place, dependent_agent, construction, service
    days_in_country: int = 0
    threshold_days: int = 183
    risk_level: str = "LOW"  # LOW, MEDIUM, HIGH
    recommendation: str = ""


@dataclass
class WHTRecommendation:
    """Rekomendacja WHT."""

    income_type: str  # dividends, interest, royalties, services
    standard_rate: float
    upo_rate: float | None = None
    effective_rate: float = 0.0
    requires_certificate: bool = False
    pay_and_refund_applies: bool = False
    recommendation: str = ""


@dataclass
class CrossJurisdictionResult:
    """Wynik analizy cross-jurisdiction."""

    source_country: str  # PL
    target_country: str
    income_type: str = ""
    amount: float = 0.0
    has_upo: bool = False
    upo_method: str = ""
    wht_recommendations: list[WHTRecommendation] = field(default_factory=list)
    pe_analysis: PEAnalysis | None = None
    double_tax_risk: str = "LOW"
    recommendation: str = ""
    legal_basis: str = ""


class CrossJurisdictionResolver:
    """Resolver konfliktów podatkowych transgranicznych.

    Raport v7.0, Rekomendacja #11 + Pomysł #5.

    Usage:
        resolver = CrossJurisdictionResolver()
        result = resolver.analyze("DE", "dividends", amount=10000)
        print(f"Effective WHT: {result.wht_recommendations[0].effective_rate:.1%}")
    """

    def __init__(self) -> None:
        self._analysis_history: list[CrossJurisdictionResult] = []

    # ── Główna analiza ────────────────────────────────────────────────

    def analyze(
        self,
        target_country: str,
        income_type: str = "services",
        amount: float = 0.0,
        days_in_country: int = 0,
        has_office: bool = False,
        has_dependent_agent: bool = False,
        activity_type: str = "",
    ) -> CrossJurisdictionResult:
        """Analiza transgraniczna między PL a krajem docelowym.

        Args:
            target_country: Kod kraju ISO 3166-1 alpha-2.
            income_type: dividends, interest, royalties, services.
            amount: Kwota transakcji.
            days_in_country: Dni fizycznej obecności w kraju (dla PE).
            has_office: Czy JDG ma biuro w kraju.
            has_dependent_agent: Czy JDG ma zależnego agenta.
            activity_type: Typ działalności dla PE analysis.

        Returns:
            CrossJurisdictionResult.
        """
        code = target_country.upper()
        upo = _UPO_DATABASE.get(code)
        has_upo = upo is not None
        has_no_upo = code in COUNTRIES_WITHOUT_UPO

        # WHT recommendations
        wht_recs = self._analyze_wht(code, income_type, amount, upo)

        # PE analysis
        pe = self._analyze_pe(code, days_in_country, has_office, has_dependent_agent, activity_type)

        # Double tax risk
        risk = self._assess_double_tax_risk(has_upo, has_no_upo, income_type, pe)

        # Recommendation
        recommendation = self._build_recommendation(has_upo, has_no_upo, code, income_type, pe, wht_recs)

        result = CrossJurisdictionResult(
            source_country="PL",
            target_country=code,
            income_type=income_type,
            amount=amount,
            has_upo=has_upo,
            upo_method=upo["method"] if upo else "none",
            wht_recommendations=wht_recs,
            pe_analysis=pe,
            double_tax_risk=risk,
            recommendation=recommendation,
            legal_basis=self._get_legal_basis(code, has_upo),
        )

        self._analysis_history.append(result)

        logger.info(
            "[CROSS-JURIS] %s → %s | income=%s | UPO=%s | risk=%s | PE=%s",
            "PL", code, income_type, "YES" if has_upo else "NO", risk,
            "YES" if pe.has_pe_risk else "NO",
        )

        return result

    # ── WHT Analysis ──────────────────────────────────────────────────

    def _analyze_wht(
        self,
        country: str,
        income_type: str,
        amount: float,
        upo: dict[str, Any] | None,
    ) -> list[WHTRecommendation]:
        """Analiza WHT."""
        recs: list[WHTRecommendation] = []

        if income_type in ("dividends", "all"):
            std = STANDARD_WHT_DIVIDENDS
            upo_rate = upo.get("wht_dividends") if upo else None
            effective = upo_rate if upo_rate is not None else std
            recs.append(WHTRecommendation(
                income_type="dividends",
                standard_rate=std,
                upo_rate=upo_rate,
                effective_rate=effective,
                requires_certificate=upo is not None,
                pay_and_refund_applies=amount > 2_000_000 and upo is not None,
                recommendation=self._wht_recommendation_text("dywidendy", std, upo_rate, country),
            ))

        if income_type in ("interest", "all"):
            std = STANDARD_WHT_INTEREST
            upo_rate = upo.get("wht_interest") if upo else None
            effective = upo_rate if upo_rate is not None else std
            recs.append(WHTRecommendation(
                income_type="interest",
                standard_rate=std,
                upo_rate=upo_rate,
                effective_rate=effective,
                requires_certificate=upo is not None,
                pay_and_refund_applies=amount > 2_000_000 and upo is not None,
                recommendation=self._wht_recommendation_text("odsetki", std, upo_rate, country),
            ))

        if income_type in ("royalties", "all"):
            std = STANDARD_WHT_ROYALTIES
            upo_rate = upo.get("wht_royalties") if upo else None
            effective = upo_rate if upo_rate is not None else std
            recs.append(WHTRecommendation(
                income_type="royalties",
                standard_rate=std,
                upo_rate=upo_rate,
                effective_rate=effective,
                requires_certificate=upo is not None,
                pay_and_refund_applies=amount > 2_000_000 and upo is not None,
                recommendation=self._wht_recommendation_text("należności licencyjne", std, upo_rate, country),
            ))

        if income_type == "services" and not recs:
            recs.append(WHTRecommendation(
                income_type="services",
                standard_rate=0.20,
                upo_rate=upo.get("wht_royalties", 0.05) if upo else None,
                effective_rate=0.0,  # Usługi B2B zwykle reverse charge
                requires_certificate=False,
                recommendation="Usługi B2B: sprawdź reverse charge (Art. 28b VAT). WHT generalnie nie dotyczy.",
            ))

        return recs

    @staticmethod
    def _wht_recommendation_text(
        income_name: str,
        standard: float,
        upo_rate: float | None,
        country: str,
    ) -> str:
        """Tekst rekomendacji WHT."""
        if upo_rate is None:
            return (
                f"Brak UPO z {country} — {income_name}: stawka standardowa "
                f"{standard:.0%} PIT. Rozważ restrukturyzację przez kraj z UPO."
            )
        savings = standard - upo_rate
        return (
            f"UPO z {country}: {income_name} — stawka obniżona do {upo_rate:.0%} "
            f"(oszczędność {savings:.0%}). Wymagany certyfikat rezydencji."
        )

    # ── PE Analysis ────────────────────────────────────────────────────

    def _analyze_pe(
        self,
        country: str,
        days_in_country: int,
        has_office: bool,
        has_dependent_agent: bool,
        activity_type: str,
    ) -> PEAnalysis:
        """Analiza ryzyka Permanent Establishment."""
        pe = PEAnalysis()
        factors: list[str] = []

        # Fixed place of business
        if has_office:
            factors.append(f"Biuro/oddział w {country}")
            pe.pe_type = "fixed_place"

        # Dependent agent
        if has_dependent_agent:
            factors.append(f"Zależny agent w {country}")
            if not pe.pe_type:
                pe.pe_type = "dependent_agent"

        # Construction PE
        if activity_type == "CONSTRUCTION" and days_in_country > 90:
            factors.append(f"Budowa > 90 dni ({days_in_country} dni)")
            pe.pe_type = "construction"

        # Service PE
        if days_in_country > pe.threshold_days:
            factors.append(f"Obecność > 183 dni ({days_in_country} dni)")
            pe.pe_type = "service"

        # Days
        pe.days_in_country = days_in_country

        # Risk level
        if len(factors) >= 2 or (has_office and days_in_country > 90):
            pe.risk_level = "HIGH"
            pe.has_pe_risk = True
        elif len(factors) == 1 or days_in_country > 90:
            pe.risk_level = "MEDIUM"
            pe.has_pe_risk = True
        elif days_in_country > 30:
            pe.risk_level = "LOW"
        else:
            pe.risk_level = "LOW"

        pe.pe_factors = factors

        # Recommendation
        if pe.has_pe_risk:
            pe.recommendation = (
                f"RYZYKO PE w {country}! Rozważ: (1) ograniczenie obecności do < 183 dni, "
                f"(2) unikanie stałego miejsca prowadzenia działalności, "
                f"(3) konsultacja z doradcą międzynarodowym."
            )
        elif pe.risk_level == "MEDIUM":
            pe.recommendation = (
                f"Monitoruj obecność w {country} — zbliżasz się do progu PE."
            )
        else:
            pe.recommendation = f"Brak istotnego ryzyka PE w {country}."

        return pe

    # ── Risk Assessment ────────────────────────────────────────────────

    @staticmethod
    def _assess_double_tax_risk(
        has_upo: bool,
        has_no_upo: bool,
        income_type: str,
        pe: PEAnalysis,
    ) -> str:
        """Oceń ryzyko podwójnego opodatkowania."""
        if has_no_upo:
            return "CRITICAL"
        if not has_upo:
            return "HIGH"
        if pe.has_pe_risk:
            return "HIGH"
        if pe.risk_level == "MEDIUM":
            return "MEDIUM"
        return "LOW"

    @staticmethod
    def _build_recommendation(
        has_upo: bool,
        has_no_upo: bool,
        country: str,
        income_type: str,
        pe: PEAnalysis,
        wht_recs: list[WHTRecommendation],
    ) -> str:
        """Zbuduj kompleksową rekomendację."""
        parts = []

        if has_no_upo:
            parts.append(f"BRAK UPO z {country} — pełne ryzyko podwójnego opodatkowania.")
            parts.append("Rozważ restrukturyzację przez kraj z UPO (np. NL, LU, CY).")
        elif not has_upo:
            method_text = "metoda proporcjonalnego odliczenia (standard)"
            parts.append(f"Brak UPO z {country} — {method_text}.")

        if has_upo:
            upo = _UPO_DATABASE.get(country, {})
            method = upo.get("method", "unknown")
            method_desc = {
                "exemption_with_progression": "wyłączenie z progresją",
                "proportional_credit": "proporcjonalne odliczenie",
            }.get(method, method)
            parts.append(f"UPO z {country}: metoda {method_desc}.")

        if pe.has_pe_risk:
            parts.append(f"UWAGA: ryzyko PE w {country} ({pe.pe_type}).")

        for rec in wht_recs:
            if rec.upo_rate is not None:
                parts.append(
                    f"WHT {rec.income_type}: {rec.effective_rate:.0%} "
                    f"(UPO, oszczędność {rec.standard_rate - rec.effective_rate:.0%})"
                )

        return " ".join(parts)

    @staticmethod
    def _get_legal_basis(country: str, has_upo: bool) -> str:
        """Podaj podstawę prawną."""
        if has_upo:
            return f"UPO PL-{country} + Art. 27 ust. 8 PIT + Art. 22a OrdPU"
        return "Art. 27 ust. 8 PIT (proporcjonalne odliczenie)"

    # ── UPO Database Queries ───────────────────────────────────────────

    def has_upo(self, country_code: str) -> bool:
        """Sprawdź czy istnieje UPO z danym krajem."""
        return country_code.upper() in _UPO_DATABASE

    def get_upo_details(self, country_code: str) -> dict[str, Any] | None:
        """Pobierz szczegóły UPO."""
        return _UPO_DATABASE.get(country_code.upper())

    def get_wht_rate(self, country_code: str, income_type: str) -> float:
        """Pobierz efektywną stawkę WHT."""
        upo = _UPO_DATABASE.get(country_code.upper())
        key = f"wht_{income_type}"
        if upo and key in upo:
            return upo[key]
        standards = {
            "dividends": STANDARD_WHT_DIVIDENDS,
            "interest": STANDARD_WHT_INTEREST,
            "royalties": STANDARD_WHT_ROYALTIES,
        }
        return standards.get(income_type, 0.20)

    def get_all_upo_countries(self) -> list[str]:
        """Lista krajów z UPO."""
        return sorted(_UPO_DATABASE.keys())

    def get_countries_without_upo(self) -> list[str]:
        """Lista krajów BEZ UPO."""
        return sorted(COUNTRIES_WITHOUT_UPO)

    # ── Statistics ─────────────────────────────────────────────────────

    def get_history(self, limit: int = 20) -> list[CrossJurisdictionResult]:
        return self._analysis_history[-limit:]

    def get_risk_summary(self) -> dict[str, Any]:
        """Podsumowanie ryzyk transgranicznych."""
        if not self._analysis_history:
            return {"total_analyses": 0}

        critical = sum(1 for a in self._analysis_history if a.double_tax_risk == "CRITICAL")
        high = sum(1 for a in self._analysis_history if a.double_tax_risk == "HIGH")
        pe = sum(1 for a in self._analysis_history if a.pe_analysis and a.pe_analysis.has_pe_risk)

        return {
            "total_analyses": len(self._analysis_history),
            "critical_risk": critical,
            "high_risk": high,
            "pe_risk_count": pe,
            "without_upo_count": sum(1 for a in self._analysis_history if not a.has_upo),
        }
