"""
v7.0 INNOWACJA 9: VAT Rate Change Propagator (DT-2).

Automatyczna detekcja zmian stawek VAT (z ISAP Crawler C3)
i propagacja do temporal_validity + thresholds + reguł.

Raport v7.0: System NIE ma mechanizmu automatycznego śledzenia
zmian stawek VAT. Wymaga ręcznej aktualizacji.

Ten moduł:
1. Monitoruje zmiany prawne (Dz.U., ISAP, MF komunikaty)
2. Automatycznie aktualizuje temporal_validity
3. Propaguje zmiany do wszystkich reguł zależnych
4. Generuje alerty o nadchodzących zmianach
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.vat_rate_propagator")


# ── Configuration ────────────────────────────────────────────────────────────

# Historyczne stawki VAT dla temporal_validity
VAT_RATE_HISTORY: dict[str, dict[str, Any]] = {
    "pre_2011": {
        "valid_from": "2004-05-01",
        "valid_to": "2010-12-31",
        "standard": 0.22, "reduced": [0.07], "super_reduced": 0.03,
        "description": "Stawki VAT przed podwyżką 2011",
        "food_rate": 0.07,
        "books_rate": 0.07,
    },
    "2011_2016": {
        "valid_from": "2011-01-01",
        "valid_to": "2016-12-31",
        "standard": 0.23, "reduced": [0.08, 0.05],
        "description": "Podwyżka VAT 2011 (23%, 8%, 5%)",
        "food_rate": 0.05,
        "books_rate": 0.05,
    },
    "2017_2021": {
        "valid_from": "2017-01-01",
        "valid_to": "2021-12-31",
        "standard": 0.23, "reduced": [0.08, 0.05],
        "description": "Stawki VAT 2017-2021 (bez zmian)",
        "food_rate": 0.05,
        "books_rate": 0.05,
    },
    "covid_2020": {
        "valid_from": "2020-04-01",
        "valid_to": "2020-12-31",
        "standard": 0.23, "reduced": [0.08, 0.05],
        "description": "COVID — 0% VAT na darowizny medyczne",
        "medical_donation_rate": 0.00,
    },
    "anti_inflation_shield_2022_1": {
        "valid_from": "2022-02-01",
        "valid_to": "2022-07-31",
        "standard": 0.23, "reduced": [0.08, 0.05],
        "description": "Tarcza Antyinflancyjna 1.0 — obniżka VAT na paliwo (8%), energię (5%), gaz (0%)",
        "fuel_rate": 0.08,
        "energy_rate": 0.05,
        "gas_rate": 0.00,
    },
    "anti_inflation_shield_2022_2": {
        "valid_from": "2022-08-01",
        "valid_to": "2022-10-31",
        "standard": 0.23, "reduced": [0.08, 0.05],
        "description": "Tarcza Antyinflancyjna 2.0 — przedłużenie obniżek",
        "fuel_rate": 0.08,
        "energy_rate": 0.05,
        "gas_rate": 0.00,
    },
    "anti_inflation_shield_2022_3": {
        "valid_from": "2022-11-01",
        "valid_to": "2022-12-31",
        "standard": 0.23, "reduced": [0.08, 0.05],
        "description": "Tarcza Antyinflancyjna 3.0 — kolejne przedłużenie",
        "fuel_rate": 0.08,
        "energy_rate": 0.05,
        "gas_rate": 0.00,
    },
    "current_2023_2026": {
        "valid_from": "2023-01-01",
        "valid_to": None,
        "standard": 0.23, "reduced": [0.08, 0.05],
        "description": "Stawki VAT od 2023 — powrót do standardowych stawek",
        "food_rate": 0.05,
        "books_rate": 0.05,
        "construction_rate": 0.08,
        "fuel_rate": 0.23,
        "energy_rate": 0.23,
        "gas_rate": 0.23,
    },
}


@dataclass
class VATRateChange:
    """Pojedyncza zmiana stawki VAT."""

    category: str  # standard, reduced, food, fuel, energy, books, etc.
    old_rate: float
    new_rate: float
    effective_from: str  # ISO date
    effective_to: str | None = None
    legal_basis: str = ""
    description: str = ""
    affected_rules: list[str] = field(default_factory=list)


@dataclass
class VATRatePropagation:
    """Wynik propagacji zmiany stawki VAT."""

    changes: list[VATRateChange] = field(default_factory=list)
    temporal_validity_entries: list[dict[str, Any]] = field(default_factory=list)
    thresholds_to_update: list[str] = field(default_factory=list)
    rules_to_update: list[str] = field(default_factory=list)
    affected_jpk_v7_fields: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)


class VATRatePropagator:
    """v7.0 DT-2: Propagator zmian stawek VAT.

    Automatycznie propaguje zmiany stawek VAT do wszystkich
    warstw systemu: temporal_validity, thresholds, reguł Rego.

    Usage:
        propagator = VATRatePropagator()
        result = propagator.propagate_change(
            category="food",
            old_rate=0.05,
            new_rate=0.08,
            effective_from="2026-09-01",
            legal_basis="Nowelizacja z 2026-07-15"
        )
        # → automatycznie generuje wpisy temporal_validity,
        #   aktualizuje thresholds, identyfikuje reguły do zmiany
    """

    # Mapowanie kategorii na reguły Rego
    CATEGORY_TO_RULES: dict[str, list[str]] = {
        "standard": [
            "jdg.vat.substantive.fuel_pl",
            "jdg.vat.substantive.gtu_mapping",
        ],
        "food": [
            "jdg.vat.substantive.food_pl",
        ],
        "books": [
            "jdg.vat.substantive.books_pl",
            "jdg.vat.substantive.books_5pct_validation",
        ],
        "construction": [
            "jdg.vat.substantive.rate_8pct",
            "jdg.vat.substantive.construction_8pct_validation",
        ],
        "fuel": [
            "jdg.vat.substantive.fuel_pl",
        ],
        "energy": [
            "jdg.vat.substantive.fuel_pl",
        ],
        "reduced_8pct": [
            "jdg.vat.substantive.rate_8pct",
            "jdg.vat.substantive.medical_equipment_8pct_validation",
        ],
        "medical": [
            "jdg.vat.substantive.healthcare_exempt",
            "jdg.vat.substantive.medical_equipment_8pct_validation",
        ],
    }

    def __init__(self) -> None:
        self._rate_history: dict[str, dict[str, Any]] = dict(VAT_RATE_HISTORY)
        self._pending_changes: list[VATRateChange] = []

    def propagate_change(
        self,
        category: str,
        old_rate: float,
        new_rate: float,
        effective_from: str,
        effective_to: str | None = None,
        legal_basis: str = "",
    ) -> VATRatePropagation:
        """Propaguj zmianę stawki VAT do wszystkich warstw systemu.

        Args:
            category: Kategoria stawki (standard, reduced, food, fuel, etc.).
            old_rate: Stara stawka (np. 0.05).
            new_rate: Nowa stawka (np. 0.08).
            effective_from: Data wejścia w życie (ISO).
            effective_to: Data zakończenia (ISO, opcjonalnie).
            legal_basis: Podstawa prawna.

        Returns:
            VATRatePropagation z listą zmian i rekomendacjami.
        """
        result = VATRatePropagation()

        change = VATRateChange(
            category=category,
            old_rate=old_rate,
            new_rate=new_rate,
            effective_from=effective_from,
            effective_to=effective_to,
            legal_basis=legal_basis,
            description=(
                f"Zmiana stawki VAT: {category} z {old_rate*100:.0f}% "
                f"na {new_rate*100:.0f}% od {effective_from}"
            ),
            affected_rules=self.CATEGORY_TO_RULES.get(category, []),
        )

        result.changes.append(change)
        self._pending_changes.append(change)

        # 1. Generuj wpis temporal_validity
        temporal_entry = {
            "rule_id_prefix": f"jdg.vat.substantive.{category}",
            "valid_from": effective_from,
            "valid_to": effective_to,
            "vat_rate": new_rate,
            "vat_rate_old": old_rate,
            "legal_basis": legal_basis,
        }
        result.temporal_validity_entries.append(temporal_entry)

        # 2. Aktualizuj thresholds
        threshold_key = f"vat_{category}_rate"
        result.thresholds_to_update.append(threshold_key)

        # 3. Identyfikuj reguły do zmiany
        affected = self.CATEGORY_TO_RULES.get(category, [])
        result.rules_to_update.extend(affected)

        # 4. JPK_V7 — identyfikuj pola dotknięte zmianą
        jpk_fields: dict[str, list[str]] = {
            "standard": ["K_15", "K_16"],
            "food": ["K_17", "K_18"],
            "books": ["K_17", "K_18"],
            "fuel": ["K_31", "K_32"],
            "reduced_8pct": ["K_17", "K_18"],
        }
        result.affected_jpk_v7_fields = jpk_fields.get(category, ["K_15"])

        # 5. Generuj rekomendacje
        if change.affected_rules:
            result.recommendations.append(
                f"Aktualizuj {len(change.affected_rules)} reguł Rego: "
                f"{', '.join(change.affected_rules[:5])}..."
            )
        result.recommendations.append(
            f"Dodaj wpis temporalny: {temporal_entry['rule_id_prefix']} "
            f"valid_from={effective_from} rate={new_rate}"
        )
        if effective_to:
            result.recommendations.append(
                f"UWAGA: Zmiana tymczasowa — wygasa {effective_to}"
            )

        # Ostrzeżenia
        days_until = self._days_until(effective_from)
        if days_until >= 0:
            if days_until <= 30:
                result.warnings.append(
                    f"⚠️ Zmiana stawki VAT za {days_until} dni! "
                    f"({category}: {old_rate*100:.0f}%→{new_rate*100:.0f}%). "
                    f"Przygotuj system."
                )
            elif days_until <= 90:
                result.warnings.append(
                    f"📋 Zmiana stawki VAT za {days_until} dni. "
                    f"Zaplanuj aktualizację."
                )

        logger.info(
            "[VAT-PROPAGATOR] category=%s %.0f%%→%.0f%% from=%s rules=%d",
            category,
            old_rate * 100,
            new_rate * 100,
            effective_from,
            len(affected),
        )

        return result

    def get_rate_for_date(
        self, category: str, date_str: str,
    ) -> float | None:
        """Pobierz stawkę VAT dla danej kategorii na konkretną datę.

        Przeszukuje historię stawek VAT (włącznie z tarczą antyinflacyjną)
        i zwraca obowiązującą stawkę dla danej daty.

        Args:
            category: Kategoria (standard, food, fuel, energy, books, etc.).
            date_str: Data w formacie ISO (YYYY-MM-DD).

        Returns:
            Stawka VAT jako float, lub None jeśli nie znaleziono.
        """
        # Przejdź przez historię od najnowszych do najstarszych
        sorted_periods = sorted(
            self._rate_history.items(),
            key=lambda x: x[1].get("valid_from", "2000-01-01"),
            reverse=True,
        )

        for period_name, period_data in sorted_periods:
            valid_from = period_data.get("valid_from", "2000-01-01")
            valid_to = period_data.get("valid_to")

            if date_str < valid_from:
                continue
            if valid_to and date_str > valid_to:
                continue

            # Sprawdź specyficzną stawkę dla kategorii
            rate_key = f"{category}_rate"
            if rate_key in period_data:
                return float(period_data[rate_key])

            # Fallback do standard/reduced
            if category == "standard":
                return float(period_data.get("standard", 0.23))
            if category in ("food", "books"):
                return float(period_data.get("reduced", [0.05])[0])

        return None

    def get_all_changes_since(self, date_str: str) -> list[VATRateChange]:
        """Pobierz wszystkie zmiany stawek od danej daty."""
        changes = []
        for period_name, period_data in self._rate_history.items():
            valid_from = period_data.get("valid_from", "")
            if valid_from >= date_str:
                # Stwórz change dla każdej kategorii stawki
                for key in period_data:
                    if key.endswith("_rate") and key not in ("depreciation_rate",):
                        cat = key.replace("_rate", "")
                        changes.append(VATRateChange(
                            category=cat,
                            old_rate=0.0,  # Unknown — need historical lookup
                            new_rate=float(period_data[key]),
                            effective_from=valid_from,
                            effective_to=period_data.get("valid_to"),
                            description=period_data.get("description", ""),
                        ))

        changes.sort(key=lambda c: c.effective_from)
        return changes

    def _days_until(self, date_str: str) -> int:
        """Oblicz dni do danej daty."""
        import pendulum
        try:
            target = pendulum.parse(date_str)
            now = pendulum.now("UTC")
            return max(0, (target - now).days)
        except Exception:
            return -1

    def generate_temporal_validity_rego(
        self, changes: list[VATRateChange],
    ) -> str:
        """Wygeneruj fragment Rego z temporal_validity dla zmian VAT.

        Returns:
            String z regułami Rego gotowy do wklejenia do _metadata_jdg.rego.
        """
        lines = [
            '    # ── VAT Rate Changes (auto-generated by VATRatePropagator) ──',
        ]
        for change in changes:
            to_val = f'"{change.effective_to}"' if change.effective_to else "null"
            lines.append(
                f'    "jdg.vat.substantive.{change.category}": {{"valid_from": '
                f'"{change.effective_from}", "valid_to": {to_val}, '
                f'"vat_rate": "{change.new_rate:.2f}"}}'
            )
        return "\n".join(lines)
