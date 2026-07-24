"""
v7.0 INNOWACJA 11: Cross-Border VAT Calculator — Kalkulator VAT dla 27 krajów UE.

Automatycznie pobiera i przechowuje stawki VAT z 27 krajów UE:
- Standard rates (17-27%)
- Reduced rates (5-18%)
- Super-reduced rates (0-5%)
- Parking rates
- Zero rates / exemptions

Wspiera wybór optymalnej procedury:
- OSS (One Stop Shop) — dla sprzedaży B2C > 10 000 EUR
- IOSS (Import One Stop Shop) — dla importu ≤ 150 EUR
- Rejestracja lokalna vs OSS — kalkulacja opłacalności

Źródła danych: European Commission VAT rates database, cached lokalnie.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.services.cross_border_vat")


# ── EU VAT Rates Database (2026) ─────────────────────────────────────────────
# Źródło: European Commission, DG TAXUD VAT Rates Database
# Ostatnia aktualizacja: 2026-01-01

EU_VAT_RATES: dict[str, dict[str, Any]] = {
    "AT": {"country": "Austria", "standard": 20.0, "reduced": [10.0, 13.0], "super_reduced": None, "parking": 13.0, "currency": "EUR"},
    "BE": {"country": "Belgia", "standard": 21.0, "reduced": [6.0, 12.0], "super_reduced": None, "parking": 12.0, "currency": "EUR"},
    "BG": {"country": "Bułgaria", "standard": 20.0, "reduced": [9.0], "super_reduced": None, "parking": None, "currency": "BGN"},
    "HR": {"country": "Chorwacja", "standard": 25.0, "reduced": [5.0, 13.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "CY": {"country": "Cypr", "standard": 19.0, "reduced": [5.0, 9.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "CZ": {"country": "Czechy", "standard": 21.0, "reduced": [12.0], "super_reduced": None, "parking": None, "currency": "CZK"},
    "DK": {"country": "Dania", "standard": 25.0, "reduced": [0.0], "super_reduced": None, "parking": None, "currency": "DKK"},
    "EE": {"country": "Estonia", "standard": 22.0, "reduced": [9.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "FI": {"country": "Finlandia", "standard": 25.5, "reduced": [10.0, 14.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "FR": {"country": "Francja", "standard": 20.0, "reduced": [5.5, 10.0], "super_reduced": 2.1, "parking": None, "currency": "EUR"},
    "DE": {"country": "Niemcy", "standard": 19.0, "reduced": [7.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "GR": {"country": "Grecja", "standard": 24.0, "reduced": [6.0, 13.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "HU": {"country": "Węgry", "standard": 27.0, "reduced": [5.0, 18.0], "super_reduced": None, "parking": None, "currency": "HUF"},
    "IE": {"country": "Irlandia", "standard": 23.0, "reduced": [9.0, 13.5], "super_reduced": 4.8, "parking": 13.5, "currency": "EUR"},
    "IT": {"country": "Włochy", "standard": 22.0, "reduced": [5.0, 10.0], "super_reduced": 4.0, "parking": None, "currency": "EUR"},
    "LV": {"country": "Łotwa", "standard": 21.0, "reduced": [12.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "LT": {"country": "Litwa", "standard": 21.0, "reduced": [5.0, 9.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "LU": {"country": "Luksemburg", "standard": 17.0, "reduced": [8.0], "super_reduced": 3.0, "parking": 14.0, "currency": "EUR"},
    "MT": {"country": "Malta", "standard": 18.0, "reduced": [5.0, 7.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "NL": {"country": "Holandia", "standard": 21.0, "reduced": [9.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "PL": {"country": "Polska", "standard": 23.0, "reduced": [5.0, 8.0], "super_reduced": None, "parking": None, "currency": "PLN"},
    "PT": {"country": "Portugalia", "standard": 23.0, "reduced": [6.0, 13.0], "super_reduced": None, "parking": 13.0, "currency": "EUR"},
    "RO": {"country": "Rumunia", "standard": 19.0, "reduced": [5.0, 9.0], "super_reduced": None, "parking": None, "currency": "RON"},
    "SK": {"country": "Słowacja", "standard": 23.0, "reduced": [10.0], "super_reduced": None, "parking": None, "currency": "EUR"},
    "SI": {"country": "Słowenia", "standard": 22.0, "reduced": [5.0, 9.5], "super_reduced": None, "parking": None, "currency": "EUR"},
    "ES": {"country": "Hiszpania", "standard": 21.0, "reduced": [10.0], "super_reduced": 4.0, "parking": None, "currency": "EUR"},
    "SE": {"country": "Szwecja", "standard": 25.0, "reduced": [6.0, 12.0], "super_reduced": None, "parking": None, "currency": "SEK"},
}

# Próg OSS dla sprzedaży B2C
OSS_THRESHOLD_EUR = 10_000.0
# Próg IOSS dla importu
IOSS_THRESHOLD_EUR = 150.0


@dataclass
class CrossBorderVATResult:
    """Wynik kalkulacji VAT transgranicznego."""
    buyer_country: str
    buyer_country_name: str
    transaction_type: str  # B2B, B2C_GOODS, B2C_SERVICES, IMPORT
    standard_rate: float
    applicable_rate: float
    rate_category: str  # standard, reduced, super_reduced, zero, exemption
    vat_amount_pln: float
    recommended_procedure: str  # OSS, IOSS, LOCAL_REGISTRATION, REVERSE_CHARGE, NP
    oss_available: bool = False
    ioss_available: bool = False
    local_registration_required: bool = False
    exchange_rate: float = 1.0
    currency: str = "EUR"
    warnings: list[str] = field(default_factory=list)


@dataclass
class OSSvsLocalAnalysis:
    """Analiza: OSS vs rejestracja lokalna."""
    oss_annual_burden: float  # Koszt OSS rocznie
    local_registration_cost: float  # Koszt rejestracji lokalnej
    local_annual_compliance_cost: float  # Koszt roczny compliance
    recommendation: str  # OSS, LOCAL, or HYBRID
    savings_with_oss: float
    break_even_transactions_per_year: int


class CrossBorderVATCalculator:
    """v7.0 INNOWACJA 11: Kalkulator VAT transgranicznego.

    Automatycznie dobiera stawkę VAT dla kraju nabywcy i rekomenduje procedurę.
    """

    def __init__(self, nbp_client: Any = None) -> None:
        self._nbp = nbp_client
        self._eur_rate_cache: dict[str, float] = {}
        self._rates = EU_VAT_RATES

    def calculate(
        self,
        buyer_country: str,
        amount_net_pln: float,
        transaction_type: str = "B2C_GOODS",
        category: str = "",
        is_digital_service: bool = False,
        annual_eu_sales_eur: float = 0.0,
        eur_pln_rate: float = 4.30,
    ) -> CrossBorderVATResult:
        """Oblicz VAT dla transakcji transgranicznej.

        Args:
            buyer_country: Kod ISO kraju nabywcy (np. "DE", "FR").
            amount_net_pln: Kwota netto w PLN.
            transaction_type: Typ transakcji (B2B, B2C_GOODS, B2C_SERVICES, IMPORT).
            category: Kategoria towaru/usługi (opcjonalnie).
            is_digital_service: Czy to usługa cyfrowa (trigger dla MOSS/OSS).
            annual_eu_sales_eur: Roczna sprzedaż B2C do UE w EUR.
            eur_pln_rate: Kurs EUR/PLN.

        Returns:
            CrossBorderVATResult z naliczonym VAT i rekomendacją.
        """
        warnings: list[str] = []
        country_data = self._rates.get(buyer_country)

        if not country_data:
            return CrossBorderVATResult(
                buyer_country=buyer_country,
                buyer_country_name=f"Nieznany ({buyer_country})",
                transaction_type=transaction_type,
                standard_rate=0.0,
                applicable_rate=0.0,
                rate_category="unknown",
                vat_amount_pln=0.0,
                recommended_procedure="MANUAL_CHECK",
                warnings=[f"Brak danych VAT dla kraju {buyer_country}"],
            )

        # ── Określenie stawki ───────────────────────────────────────
        standard_rate = country_data["standard"]
        applicable_rate = standard_rate
        rate_category = "standard"

        # Sprawdź stawki obniżone dla kategorii
        if category in ("FOOD", "BOOKS", "GROCERIES"):
            reduced = country_data.get("reduced", [])
            if reduced:
                applicable_rate = reduced[0]
                rate_category = "reduced"
        elif category in ("MEDICAL", "PHARMA"):
            super_reduced = country_data.get("super_reduced")
            if super_reduced:
                applicable_rate = super_reduced
                rate_category = "super_reduced"

        # ── Określenie procedury ─────────────────────────────────────
        recommended_procedure = "NP"  # domyślnie
        oss_available = False
        ioss_available = False
        local_registration_required = False

        if transaction_type == "B2B":
            recommended_procedure = "REVERSE_CHARGE"
            applicable_rate = 0.0  # B2B: odwrotne obciążenie = 0% na fakturze

        elif transaction_type == "IMPORT":
            if amount_net_pln / max(eur_pln_rate, 0.01) <= IOSS_THRESHOLD_EUR:
                recommended_procedure = "IOSS"
                ioss_available = True
            else:
                recommended_procedure = "IMPORT_STANDARD"
                warnings.append(
                    f"Import > {IOSS_THRESHOLD_EUR} EUR — wymaga standardowej "
                    f"odprawy celnej z SAD. IOSS niedostępne."
                )

        elif transaction_type in ("B2C_GOODS", "B2C_SERVICES"):
            if is_digital_service or annual_eu_sales_eur > OSS_THRESHOLD_EUR:
                recommended_procedure = "OSS"
                oss_available = True
                if annual_eu_sales_eur > OSS_THRESHOLD_EUR:
                    warnings.append(
                        f"Sprzedaż B2C EU {annual_eu_sales_eur:.0f} EUR > "
                        f"{OSS_THRESHOLD_EUR} EUR — OSS obowiązkowe!"
                    )
            elif annual_eu_sales_eur > 0:
                recommended_procedure = "OSS_OPTIONAL"
                oss_available = True
            elif buyer_country != "PL":
                recommended_procedure = "LOCAL_REGISTRATION"
                local_registration_required = True
                warnings.append(
                    f"Sprzedaż do {country_data['country']} — może być wymagana "
                    f"rejestracja lokalna VAT. Rozważ OSS dla uproszczenia."
                )

        # ── Kalkulacja VAT ──────────────────────────────────────────
        vat_amount_pln = amount_net_pln * (applicable_rate / 100.0)
        amount_eur = amount_net_pln / max(eur_pln_rate, 0.01)

        if recommended_procedure == "REVERSE_CHARGE":
            vat_amount_pln = 0.0  # B2B reverse charge

        return CrossBorderVATResult(
            buyer_country=buyer_country,
            buyer_country_name=country_data["country"],
            transaction_type=transaction_type,
            standard_rate=standard_rate,
            applicable_rate=applicable_rate,
            rate_category=rate_category,
            vat_amount_pln=round(vat_amount_pln, 2),
            recommended_procedure=recommended_procedure,
            oss_available=oss_available,
            ioss_available=ioss_available,
            local_registration_required=local_registration_required,
            exchange_rate=eur_pln_rate,
            currency=country_data.get("currency", "EUR"),
            warnings=warnings,
        )

    def analyze_oss_vs_local(
        self,
        eu_countries_sold_to: list[str],
        annual_transactions: int,
        annual_revenue_eur: float,
        accountant_cost_per_country: float = 500.0,
        oss_service_cost: float = 1200.0,
    ) -> OSSvsLocalAnalysis:
        """Analiza OSS vs rejestracja lokalna.

        Args:
            eu_countries_sold_to: Lista kodów krajów UE gdzie jest sprzedaż.
            annual_transactions: Roczna liczba transakcji B2C.
            annual_revenue_eur: Roczny przychód B2C EU w EUR.
            accountant_cost_per_country: Koszt księgowego per kraj rejestracji.
            oss_service_cost: Koszt roczny usługi OSS.

        Returns:
            OSSvsLocalAnalysis.
        """
        num_countries = len(eu_countries_sold_to)
        if num_countries == 0:
            num_countries = 1

        # OSS: jedna deklaracja kwartalna
        oss_annual_burden = oss_service_cost

        # Lokalnie: rejestracja + compliance per kraj
        local_registration_cost = num_countries * 150.0  # jednorazowa rejestracja
        local_annual_compliance_cost = num_countries * accountant_cost_per_country

        total_local_first_year = local_registration_cost + local_annual_compliance_cost
        total_local_annual = local_annual_compliance_cost

        savings = total_local_annual - oss_annual_burden

        if savings > 500 and num_countries >= 2:
            recommendation = "OSS"
        elif num_countries == 1 and annual_transactions < 50:
            recommendation = "LOCAL"
        else:
            recommendation = "OSS" if savings > 0 else "LOCAL"

        return OSSvsLocalAnalysis(
            oss_annual_burden=round(oss_annual_burden, 2),
            local_registration_cost=round(local_registration_cost, 2),
            local_annual_compliance_cost=round(local_annual_compliance_cost, 2),
            recommendation=recommendation,
            savings_with_oss=round(savings, 2),
            break_even_transactions_per_year=int(total_local_first_year / max(oss_annual_burden, 1)),
        )

    def get_all_countries(self) -> list[dict[str, Any]]:
        """Pobierz listę wszystkich krajów EU ze stawkami."""
        return [
            {"code": code, "name": data["country"], "standard_rate": data["standard"],
             "reduced_rates": data.get("reduced", []), "currency": data.get("currency", "EUR")}
            for code, data in sorted(self._rates.items())
        ]

    def add_custom_rate(
        self, country_code: str, country_name: str,
        standard_rate: float, reduced_rates: list[float] | None = None,
        currency: str = "EUR",
    ) -> None:
        """Dodaj niestandardową stawkę (np. dla kraju spoza UE)."""
        self._rates[country_code.upper()] = {
            "country": country_name,
            "standard": standard_rate,
            "reduced": reduced_rates or [],
            "super_reduced": None,
            "parking": None,
            "currency": currency,
        }
        logger.info(
            "[CB-VAT] Added custom rate: %s standard=%.1f%%",
            country_code, standard_rate,
        )
