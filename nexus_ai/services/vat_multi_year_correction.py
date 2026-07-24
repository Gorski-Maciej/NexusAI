"""
v7.0 INNOWACJA 3: Multi-Year Correction Automation (MR-6).

Automatyczne wykrywanie i generowanie korekt wieloletnich
dla środków trwałych (Art. 91 VAT).

System śledzi:
- Proporcję VAT w roku nabycia vs rok bieżący
- Zmianę proporcji >10pp → obowiązek korekty
- 5-letni okres dla ruchomości (1/5 rocznie)
- 10-letni okres dla nieruchomości (1/10 rocznie)
- Automatyczne przypomnienia o corocznej korekcie

Raport v7.0 LUKA: P187 w deductions.rego tylko informuje
o obowiązku, nie automatyzuje procesu.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, timedelta
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.multi_year_correction")


# ── Configuration ────────────────────────────────────────────────────────────

PROPORTION_CHANGE_THRESHOLD = 0.10  # 10pp
MOVABLE_ASSETS_CORRECTION_YEARS = 5
REAL_ESTATE_CORRECTION_YEARS = 10
ANNUAL_CORRECTION_FRACTION_MOVABLE = 0.20  # 1/5
ANNUAL_CORRECTION_FRACTION_REAL_ESTATE = 0.10  # 1/10


@dataclass
class AssetCorrectionItem:
    """Pojedynczy środek trwały podlegający korekcie."""

    asset_id: str
    asset_name: str
    asset_type: str  # MOVABLE, REAL_ESTATE
    acquisition_year: int
    acquisition_vat: float
    acquisition_proportion: float  # proporcja w roku nabycia
    current_proportion: float  # proporcja w roku bieżącym
    proportion_change: float  # zmiana w punktach procentowych
    years_remaining: int
    correction_fraction: float  # 1/5 lub 1/10
    annual_correction_vat: float
    correction_direction: str  # IN_PLUS, IN_MINUS
    total_correction_remaining: float


@dataclass
class MultiYearCorrectionResult:
    """Wynik analizy korekt wieloletnich."""

    tax_year: int
    total_correction_in_plus: float = 0.0
    total_correction_in_minus: float = 0.0
    assets_to_correct: list[AssetCorrectionItem] = field(default_factory=list)
    corrections_due_this_year: list[AssetCorrectionItem] = field(default_factory=list)
    missed_corrections: list[AssetCorrectionItem] = field(default_factory=list)
    upcoming_corrections: list[dict[str, Any]] = field(default_factory=list)
    jpk_v7_position: str = "K_45"
    recommendations: list[str] = field(default_factory=list)


class MultiYearCorrectionEngine:
    """v7.0 INNOWACJA 3: Silnik korekt wieloletnich VAT.

    Automatyzuje Art. 91 VAT — korekty odliczeń dla środków trwałych
    przy zmianie proporcji sprzedaży opodatkowanej/zwolnionej.

    Usage:
        engine = MultiYearCorrectionEngine()
        result = engine.analyze(tax_year=2026, assets=assets_list,
                                current_proportion=0.75)
    """

    def __init__(self) -> None:
        self._assets: dict[str, dict[str, Any]] = {}
        self._proportion_history: dict[int, float] = {}

    def register_asset(
        self,
        asset_id: str,
        asset_name: str,
        asset_type: str,  # MOVABLE or REAL_ESTATE
        acquisition_year: int,
        acquisition_vat: float,
        acquisition_proportion: float,
    ) -> None:
        """Zarejestruj środek trwały do śledzenia korekt."""
        self._assets[asset_id] = {
            "asset_name": asset_name,
            "asset_type": asset_type,
            "acquisition_year": acquisition_year,
            "acquisition_vat": acquisition_vat,
            "acquisition_proportion": acquisition_proportion,
            "corrections_made": {},  # year → amount
        }

    def set_proportion(self, tax_year: int, proportion: float) -> None:
        """Ustaw proporcję VAT dla danego roku."""
        self._proportion_history[tax_year] = proportion

    def analyze(
        self,
        tax_year: int,
        current_proportion: float | None = None,
    ) -> MultiYearCorrectionResult:
        """Analizuj korekty wieloletnie dla danego roku podatkowego.

        Args:
            tax_year: Rok podatkowy (np. 2026).
            current_proportion: Bieżąca proporcja (jeśli inna niż zarejestrowana).

        Returns:
            MultiYearCorrectionResult z listą korekt.
        """
        if current_proportion is not None:
            self.set_proportion(tax_year, current_proportion)

        current_prop = self._proportion_history.get(tax_year)
        if current_prop is None:
            current_prop = 1.0

        result = MultiYearCorrectionResult(tax_year=tax_year)
        corrections_due: list[AssetCorrectionItem] = []
        missed: list[AssetCorrectionItem] = []

        for asset_id, asset_data in self._assets.items():
            acq_year = asset_data["acquisition_year"]
            asset_type = asset_data["asset_type"]
            acq_vat = asset_data["acquisition_vat"]
            acq_prop = asset_data["acquisition_proportion"]

            # Określ okres korekty
            correction_years = (
                REAL_ESTATE_CORRECTION_YEARS if asset_type == "REAL_ESTATE"
                else MOVABLE_ASSETS_CORRECTION_YEARS
            )
            correction_fraction = (
                ANNUAL_CORRECTION_FRACTION_REAL_ESTATE if asset_type == "REAL_ESTATE"
                else ANNUAL_CORRECTION_FRACTION_MOVABLE
            )

            # Czy środek nadal podlega korekcie?
            years_since_acq = tax_year - acq_year
            years_remaining = correction_years - years_since_acq

            if years_remaining <= 0:
                continue  # Okres korekty minął

            # Oblicz zmianę proporcji
            proportion_change = current_prop - acq_prop

            # Czy zmiana > 10pp?
            if abs(proportion_change) < PROPORTION_CHANGE_THRESHOLD:
                continue

            # Oblicz korektę
            annual_correction = acq_vat * correction_fraction * proportion_change
            total_remaining = annual_correction * years_remaining

            item = AssetCorrectionItem(
                asset_id=asset_id,
                asset_name=asset_data["asset_name"],
                asset_type=asset_type,
                acquisition_year=acq_year,
                acquisition_vat=acq_vat,
                acquisition_proportion=acq_prop,
                current_proportion=current_prop,
                proportion_change=round(proportion_change, 4),
                years_remaining=years_remaining,
                correction_fraction=correction_fraction,
                annual_correction_vat=round(annual_correction, 2),
                correction_direction="IN_PLUS" if proportion_change > 0 else "IN_MINUS",
                total_correction_remaining=round(total_remaining, 2),
            )

            result.assets_to_correct.append(item)

            # Sprawdź czy korekta za ten rok już była zrobiona
            corrections_made = asset_data.get("corrections_made", {})
            if tax_year not in corrections_made:
                corrections_due.append(item)
                if annual_correction > 0:
                    result.total_correction_in_plus += annual_correction
                else:
                    result.total_correction_in_minus += abs(annual_correction)

            # Sprawdź pominięte korekty za poprzednie lata
            for year in range(acq_year + 1, tax_year):
                if year not in corrections_made:
                    missed_vat = acq_vat * correction_fraction * (
                        self._proportion_history.get(year, acq_prop) - acq_prop
                    )
                    missed.append(AssetCorrectionItem(
                        asset_id=asset_id,
                        asset_name=asset_data["asset_name"],
                        asset_type=asset_type,
                        acquisition_year=acq_year,
                        acquisition_vat=acq_vat,
                        acquisition_proportion=acq_prop,
                        current_proportion=self._proportion_history.get(year, acq_prop),
                        proportion_change=round(
                            self._proportion_history.get(year, acq_prop) - acq_prop, 4,
                        ),
                        years_remaining=correction_years - (year - acq_year),
                        correction_fraction=correction_fraction,
                        annual_correction_vat=round(missed_vat, 2),
                        correction_direction="IN_PLUS" if missed_vat > 0 else "IN_MINUS",
                        total_correction_remaining=round(missed_vat, 2),
                    ))

        result.corrections_due_this_year = corrections_due
        result.missed_corrections = missed

        # Rekomendacje
        if corrections_due:
            result.recommendations.append(
                f"Korekta VAT za {tax_year}: {len(corrections_due)} środków trwałych. "
                f"JPK_V7 pozycja {result.jpk_v7_position}."
            )
        if missed:
            result.recommendations.append(
                f"UWAGA: {len(missed)} pominiętych korekt za poprzednie lata. "
                f"Złóż korekty JPK_V7 wstecz."
            )
        if not corrections_due and not missed:
            result.recommendations.append(
                "Brak wymaganych korekt wieloletnich za ten rok."
            )

        # Nadchodzące korekty (przypomnienia)
        for asset_id, asset_data in self._assets.items():
            acq_year = asset_data["acquisition_year"]
            correction_years = (
                REAL_ESTATE_CORRECTION_YEARS if asset_data["asset_type"] == "REAL_ESTATE"
                else MOVABLE_ASSETS_CORRECTION_YEARS
            )
            last_correction_year = acq_year + correction_years - 1
            if last_correction_year > tax_year:
                result.upcoming_corrections.append({
                    "asset_id": asset_id,
                    "asset_name": asset_data["asset_name"],
                    "final_year": last_correction_year,
                    "years_remaining": last_correction_year - tax_year,
                })

        logger.info(
            "[MULTI-YEAR] year=%d corrections=%d missed=%d",
            tax_year,
            len(corrections_due),
            len(missed),
        )

        return result

    def mark_correction_done(
        self, asset_id: str, tax_year: int, amount: float,
    ) -> None:
        """Oznacz korektę jako wykonaną."""
        if asset_id in self._assets:
            corrections = self._assets[asset_id].setdefault("corrections_made", {})
            corrections[tax_year] = amount
