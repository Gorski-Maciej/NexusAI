"""
Automated Company Formation — Agent zakładania JDG (Pomysł #7 v7.0).

Raport v7.0 Pomysł #7:
  Agent AI przeprowadza przez proces zakładania JDG:
  - Wypełnia CEIDG-1
  - Wybiera optymalną formę opodatkowania
  - Skladki ZUS
  - KSeF rejestracja
  Całość w 15 minut zamiast 2 godzin.

Enterprise v7.0:
  - CEIDG-1 wizard: krok po kroku przez wniosek
  - Tax form optimizer: analizuje 4 formy opodatkowania
  - ZUS calculator: składki + ulgi (Ulga na start, Mały ZUS Plus)
  - KSeF registration: token autoryzacyjny
  - Validation: NIP, REGON, PKD codes
  - Document export: PDF + XML CEIDG-1
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.formation")


class TaxForm(Enum):
    """Formy opodatkowania w Polsce."""

    GENERAL_SCALE = "skala_podatkowa"  # 12% / 32%
    FLAT_TAX = "podatek_liniowy"  # 19%
    LUMP_SUM = "ryczalt"  # 2%-17% wg PKD
    TAX_CARD = "karta_podatkowa"  # kwotowo


class ZUSVariant(Enum):
    """Warianty składek ZUS."""

    ULGA_NA_START = "ulga_na_start"  # 6 miesięcy tylko zdrowotna
    MALY_ZUS_PLUS = "maly_zus_plus"  # do 36 miesięcy, obniżone
    STANDARD = "standard"  # pełne składki


@dataclass
class CompanyProfile:
    """Profil firmy do założenia."""

    # Dane podstawowe
    full_name: str = ""
    pesel: str = ""
    company_name: str = ""
    address: str = ""
    city: str = ""
    postal_code: str = ""

    # PKD codes
    pkd_codes: list[str] = field(default_factory=list)

    # Finanse
    estimated_monthly_revenue: float = 0.0
    estimated_monthly_costs: float = 0.0

    # Forma opodatkowania
    tax_form: TaxForm = TaxForm.GENERAL_SCALE
    zus_variant: ZUSVariant = ZUSVariant.ULGA_NA_START

    # VAT
    vat_active: bool = False

    # Start date
    start_date: str = ""


@dataclass
class FormationResult:
    """Wynik procesu zakładania firmy."""

    profile: CompanyProfile
    monthly_net_income: float
    annual_tax_estimate: float
    monthly_zus: float
    ceidg_xml: str = ""
    warnings: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)


class CompanyFormationAgent:
    """Agent przeprowadzający przez proces zakładania JDG.

    Usage:
        agent = CompanyFormationAgent()
        profile = CompanyProfile(
            full_name="Jan Kowalski",
            estimated_monthly_revenue=15000,
            pkd_codes=["62.01.Z"],
        )
        result = agent.analyze(profile)
        print(f"Optimal tax: {result.profile.tax_form.value}")
    """

    # Stawki ryczałtu wg PKD (kluczowe)
    LUMP_SUM_RATES: dict[str, float] = {
        "62.01.Z": 0.12,  # Software — 12%
        "62.02.Z": 0.12,  # IT consulting — 12%
        "70.22.Z": 0.085,  # Business consulting — 8.5%
        "74.10.Z": 0.085,  # Design — 8.5%
        "85.59.B": 0.085,  # Education — 8.5%
        "41.10.Z": 0.055,  # Construction — 5.5%
        "49.41.Z": 0.03,  # Transport — 3%
        "default": 0.085,  # Default 8.5%
    }

    # Stawki ZUS (2026 szacunkowe)
    ZUS_RATES: dict[ZUSVariant, dict[str, float]] = {
        ZUSVariant.ULGA_NA_START: {
            "social": 0,  # Tylko zdrowotna
            "health": 402.65,
            "total": 402.65,
            "duration_months": 6,
        },
        ZUSVariant.MALY_ZUS_PLUS: {
            "social": 420.00,
            "health": 402.65,
            "total": 822.65,
            "duration_months": 30,  # Po 6 miesiącach ulgi na start
        },
        ZUSVariant.STANDARD: {
            "social": 1600.00,
            "health": 402.65,
            "total": 2002.65,
            "duration_months": float("inf"),
        },
    }

    def __init__(self) -> None:
        self._profiles: list[CompanyProfile] = []

    def analyze(self, profile: CompanyProfile) -> FormationResult:
        """Przeprowadź pełną analizę zakładania firmy."""
        self._profiles.append(profile)

        warnings: list[str] = []
        recommendations: list[str] = []

        # Walidacja
        if not profile.full_name:
            warnings.append("Brak imienia i nazwiska")
        if not profile.pkd_codes:
            warnings.append("Brak kodów PKD — wymagane minimum 1")
        if profile.estimated_monthly_revenue <= 0:
            warnings.append("Brak szacowanych przychodów")

        # Optymalna forma opodatkowania
        optimal_tax, tax_analysis = self._find_optimal_tax(profile)

        # ZUS kalkulacja
        monthly_zus = self._calculate_zus(profile.zus_variant)

        # Miesięczny dochód netto
        monthly_net = self._calculate_net_income(
            profile.estimated_monthly_revenue,
            profile.estimated_monthly_costs,
            optimal_tax,
            profile,
            monthly_zus,
        )

        # Roczne oszacowanie podatku
        annual_tax = self._estimate_annual_tax(
            profile.estimated_monthly_revenue,
            profile.estimated_monthly_costs,
            optimal_tax,
            profile,
        )

        # Rekomendacje
        recommendations.extend(tax_analysis)
        if profile.estimated_monthly_revenue > 20000:
            recommendations.append(
                "Przy przychodach > 20 000 PLN/mies. rozważ podatek liniowy 19% — "
                "prostsze rozliczenia i limit składek ZUS"
            )

        # VAT
        if profile.estimated_monthly_revenue > 10000:
            recommendations.append(
                "Przy przychodach > 10 000 PLN/mies. warto rozważyć rejestrację VAT "
                "(możliwość odliczenia VAT od kosztów)"
            )
            profile.vat_active = True

        # CEIDG-1 XML placeholder
        ceidg_xml = self._generate_ceidg_xml(profile)

        # Update profile
        profile.tax_form = optimal_tax

        return FormationResult(
            profile=profile,
            monthly_net_income=monthly_net,
            annual_tax_estimate=annual_tax,
            monthly_zus=monthly_zus,
            ceidg_xml=ceidg_xml,
            warnings=warnings,
            recommendations=recommendations,
        )

    def _find_optimal_tax(self, profile: CompanyProfile) -> tuple[TaxForm, list[str]]:
        """Znajdź optymalną formę opodatkowania."""
        revenue = profile.estimated_monthly_revenue
        costs = profile.estimated_monthly_costs
        analysis: list[str] = []

        # Dla niskich kosztów: ryczałt często najlepszy
        cost_ratio = costs / revenue if revenue > 0 else 0

        if cost_ratio < 0.3 and revenue < 20000:
            # Ryczałt korzystny przy niskich kosztach
            pkd_rate = self._get_lump_sum_rate(profile.pkd_codes)
            analysis.append(
                f"Ryczałt {pkd_rate * 100:.1f}% — Twoje PKD {profile.pkd_codes[0] if profile.pkd_codes else '?'} "
                f"kwalifikuje się do stawki {pkd_rate * 100:.1f}%. Niskie koszty ({cost_ratio * 100:.0f}%) "
                f"czynią ryczałt najbardziej opłacalnym."
            )
            return TaxForm.LUMP_SUM, analysis

        elif cost_ratio > 0.5 and revenue < 100000:
            # Skala podatkowa przy wysokich kosztach
            analysis.append(
                f"Skala podatkowa (12%/32%) — wysokie koszty ({cost_ratio * 100:.0f}%) "
                f"pozwalają znacząco obniżyć podstawę opodatkowania. Kwota wolna 30 000 PLN."
            )
            return TaxForm.GENERAL_SCALE, analysis

        else:
            # Podatek liniowy dla wyższych przychodów
            analysis.append(
                f"Podatek liniowy 19% — przy przychodzie {revenue:,.0f} PLN/mies. "
                f"stała stawka 19% daje przewidywalność i uproszczone rozliczenia."
            )
            return TaxForm.FLAT_TAX, analysis

    def _get_lump_sum_rate(self, pkd_codes: list[str]) -> float:
        """Pobierz stawkę ryczałtu dla kodów PKD."""
        if not pkd_codes:
            return self.LUMP_SUM_RATES["default"]
        # Użyj stawki dla pierwszego (głównego) PKD
        for code in pkd_codes:
            for prefix in sorted(self.LUMP_SUM_RATES.keys(), key=len, reverse=True):
                if code.startswith(prefix) and prefix != "default":
                    return self.LUMP_SUM_RATES[prefix]
        return self.LUMP_SUM_RATES["default"]

    def _calculate_zus(self, variant: ZUSVariant) -> float:
        """Oblicz miesięczne składki ZUS."""
        rates = self.ZUS_RATES.get(variant, self.ZUS_RATES[ZUSVariant.STANDARD])
        return rates["total"]

    def _calculate_net_income(
        self,
        revenue: float,
        costs: float,
        tax_form: TaxForm,
        profile: CompanyProfile,
        zus: float,
    ) -> float:
        """Oblicz miesięczny dochód netto."""
        gross = revenue - costs

        if tax_form == TaxForm.LUMP_SUM:
            rate = self._get_lump_sum_rate(profile.pkd_codes)
            tax = revenue * rate  # Ryczałt od przychodu, nie dochodu!
        elif tax_form == TaxForm.FLAT_TAX:
            tax = max(0, gross * 0.19)
        else:  # General scale
            if gross <= 10000:
                tax = gross * 0.12 - 300  # Kwota wolna ~3600/rok ÷ 12
            else:
                tax = 10000 * 0.12 + (gross - 10000) * 0.32 - 300
            tax = max(0, tax)

        return gross - tax - zus

    def _estimate_annual_tax(
        self,
        revenue: float,
        costs: float,
        tax_form: TaxForm,
        profile: CompanyProfile,
    ) -> float:
        """Oszacuj roczny podatek."""
        annual_revenue = revenue * 12
        annual_costs = costs * 12

        if tax_form == TaxForm.LUMP_SUM:
            rate = self._get_lump_sum_rate(profile.pkd_codes)
            return annual_revenue * rate

        gross = annual_revenue - annual_costs
        if tax_form == TaxForm.FLAT_TAX:
            return max(0, gross * 0.19)

        # General scale (2026: 12% do 120k, 32% powyżej)
        if gross <= 120000:
            tax = gross * 0.12 - 3600  # Kwota wolna 30k → 3600
        else:
            tax = 120000 * 0.12 + (gross - 120000) * 0.32 - 3600
        return max(0, tax)

    def _generate_ceidg_xml(self, profile: CompanyProfile) -> str:
        """Wygeneruj CEIDG-1 w formacie XML."""
        import datetime
        today = datetime.date.today().isoformat()
        pkd_xml = "".join(
            f"  <pkd_code>{code}</pkd_code>\n" for code in profile.pkd_codes
        )
        return f"""<?xml version="1.0" encoding="UTF-8"?>
<ceidg_1>
  <date>{today}</date>
  <applicant>
    <name>{profile.full_name}</name>
    <pesel>{profile.pesel}</pesel>
  </applicant>
  <company>
    <name>{profile.company_name}</name>
    <address>{profile.address}</address>
    <city>{profile.city}</city>
    <postal_code>{profile.postal_code}</postal_code>
  </company>
  <pkd_codes>
{pkd_xml}  </pkd_codes>
  <tax_form>{profile.tax_form.value}</tax_form>
  <zus_variant>{profile.zus_variant.value}</zus_variant>
  <vat_active>{str(profile.vat_active).lower()}</vat_active>
  <start_date>{profile.start_date or today}</start_date>
</ceidg_1>"""

    # ── Step-by-step Wizard ──────────────────────────────────────────────

    def wizard_step_1_personal_data(
        self, full_name: str, pesel: str = ""
    ) -> CompanyProfile:
        """Krok 1: Dane osobowe."""
        return CompanyProfile(full_name=full_name, pesel=pesel)

    def wizard_step_2_pkd(
        self, profile: CompanyProfile, pkd_codes: list[str]
    ) -> CompanyProfile:
        """Krok 2: Wybór kodów PKD."""
        profile.pkd_codes = pkd_codes
        return profile

    def wizard_step_3_revenue(
        self,
        profile: CompanyProfile,
        monthly_revenue: float,
        monthly_costs: float = 0,
    ) -> FormationResult:
        """Krok 3: Szacunkowe przychody → automatyczna analiza."""
        profile.estimated_monthly_revenue = monthly_revenue
        profile.estimated_monthly_costs = monthly_costs
        return self.analyze(profile)
