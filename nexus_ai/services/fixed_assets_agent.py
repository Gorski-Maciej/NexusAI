"""
Agent ds. Środków Trwałych — Specjalista od Majątku Firmy

Zgodnie z aa3fvcx.txt:
- Pozycja w systemie: Wykonawczy.
- Odpowiada za klasyfikację, amortyzację i zarządzanie środkami trwałymi.
- Współpracuje z Agentem Orkiestratorem przez kanał assets.classify.

Integruje funkcjonalność z:
- FixedAssetsService (istniejący serwis zarządzania środkami trwałymi)
- TigerBeetle (księgowanie amortyzacji)
- DuckDB (harmonogram amortyzacji)
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from decimal import ROUND_HALF_UP, Decimal
from typing import Any

import pendulum

from nexus_ai.core.config import AppConfig
from nexus_ai.core.logger import get_logger
from nexus_ai.services.fixed_assets import FixedAssetsService

logger = get_logger(__name__)


@dataclass
class AssetClassification:
    """Klasyfikacja środka trwałego."""

    asset_id: str
    asset_name: str
    category: str  # np. "IT", "MASZYNY", "NIERUCHOMOSCI", "POJAZDY", "INNE"
    initial_value: Decimal
    depreciation_method: str  # LINEAR | DEGRESSIVE
    useful_life_years: int
    annual_rate: Decimal
    is_fixed_asset: bool


@dataclass
class AssetActionResult:
    """Wynik działania na środkach trwałych."""

    success: bool
    message: str
    details: dict[str, Any] = field(default_factory=dict)


class FixedAssetsAgent:
    """Agent ds. Środków Trwałych — Specjalista od Majątku Firmy.

    Zgodnie z aa3fvcx.txt:
    - Klasyfikuje wydatki jako środki trwałe vs koszty bieżące
    - Generuje harmonogramy amortyzacji
    - Wykonuje miesięczną amortyzację przez TigerBeetle
    - Współpracuje z Orkiestratorem przez kanał assets.classify
    """

    def __init__(
        self,
        fixed_assets_service: FixedAssetsService,
        config: AppConfig | None = None,
    ) -> None:
        self._service = fixed_assets_service
        self._config = config or AppConfig()

    async def classify_asset(
        self,
        asset_name: str,
        initial_value: Decimal,
        category: str | None = None,
    ) -> AssetClassification:
        """Klasyfikuj wydatek jako środek trwały lub koszt bieżący.

        Zgodnie z polskim prawem (ustawa o rachunkowości):
        - Środek trwały: wartość ≥ 10,000 PLN, okres użycia > 1 rok
        - Niskoceme składniki: < 10,000 PLN → koszt bieżący

        Args:
            asset_name: Nazwa składnika majątku.
            initial_value: Wartość początkowa.
            category: Kategoria (opcjonalnie).

        Returns:
            AssetClassification z decyzją klasyfikacyjną.
        """
        if category:
            cat = category.upper()
        else:
            cat = self._infer_category(asset_name)

        minimal_value = Decimal("10000")
        is_fixed_asset = initial_value >= minimal_value

        useful_life = self._get_useful_life(cat)
        annual_rate = Decimal("1.0") / Decimal(str(useful_life)) if useful_life > 0 else Decimal("0.0")

        logger.info(
            "[FixedAssetsAgent] classified %s: value=%.2f is_fixed=%s category=%s life=%dyrs rate=%.4f",
            asset_name, initial_value, is_fixed_asset, cat, useful_life, annual_rate,
        )

        return AssetClassification(
            asset_id=str(uuid.uuid4()),
            asset_name=asset_name,
            category=cat,
            initial_value=initial_value,
            depreciation_method="LINEAR",
            useful_life_years=useful_life,
            annual_rate=annual_rate,
            is_fixed_asset=is_fixed_asset,
        )

    async def generate_depreciation_schedule(self, asset_id: str) -> AssetActionResult:
        """Generuj harmonogram amortyzacji dla środka trwałego.

        Args:
            asset_id: ID środka trwałego.

        Returns:
            AssetActionResult z liczbą wygenerowanych wpisów.
        """
        try:
            count = self._service.generate_schedule(asset_id)
            if count > 0:
                return AssetActionResult(
                    success=True,
                    message=f"Wygenerowano {count} wpisów harmonogramu amortyzacji",
                    details={"entries_count": count, "asset_id": asset_id},
                )
            return AssetActionResult(
                success=False,
                message=f"Brak wpisów do wygenerowania dla asset_id={asset_id}",
                details={"asset_id": asset_id},
            )
        except Exception as exc:
            logger.error("[FixedAssetsAgent] schedule generation error: %s", exc)
            return AssetActionResult(
                success=False,
                message=f"Błąd: {exc}",
                details={"asset_id": asset_id, "error": str(exc)},
            )

    async def execute_monthly_depreciation(self) -> AssetActionResult:
        """Wykonaj miesięczną amortyzację wszystkich aktywnych środków.

        Returns:
            AssetActionResult z liczbą zaksięgowanych amortyzacji.
        """
        try:
            posted = await self._service.execute_monthly_depreciation()
            return AssetActionResult(
                success=posted > 0,
                message=f"Zaksięgowano {posted} amortyzacji",
                details={"posted_count": posted},
            )
        except Exception as exc:
            logger.error("[FixedAssetsAgent] monthly depreciation error: %s", exc)
            return AssetActionResult(
                success=False,
                message=f"Błąd: {exc}",
                details={"error": str(exc)},
            )

    @staticmethod
    def _infer_category(asset_name: str) -> str:
        """Wywnioskuj kategorię na podstawie nazwy składnika."""
        name_lower = asset_name.lower()
        if any(w in name_lower for w in ("komputer", "laptop", "serwer", "drukarka", "monitor", "telefon")):
            return "IT"
        if any(w in name_lower for w in ("maszyna", "urządzenie", "produkcyjne", "tokarka")):
            return "MASZYNY"
        if any(w in name_lower for w in ("budynek", "lokal", "magazyn", "biuro")):
            return "NIERUCHOMOSCI"
        if any(w in name_lower for w in ("samochód", "pojazd", "wóz", "ciężarówka")):
            return "POJAZDY"
        if any(w in name_lower for w in ("meble", "wyposażenie", "regal", "biurko")):
            return "WYPOSAZENIE"
        return "INNE"

    @staticmethod
    def _get_useful_life(category: str) -> int:
        """Zwróć okres użytkowania w latach dla danej kategorii.

        Zgodnie z polskimi przepisami (Wykaz stawek amortyzacyjnych):
        """
        rates = {
            "IT": 3,          # Komputery i oprogramowanie
            "MASZYNY": 5,     # Maszyny i urządzenia
            "NIERUCHOMOSCI": 20,  # Budynki i lokale
            "POJAZDY": 5,     # Samochody i pojazdy
            "WYPOSAZENIE": 5, # Meble i wyposażenie
            "INNE": 5,        # Pozostałe
        }
        return rates.get(category, 5)
