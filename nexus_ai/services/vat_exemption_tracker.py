"""
v7.0 VAT/MPP ORKIESTRATOR — VAT Subject Exemption Tracker (INNOWACJA 2).

Automatyczne śledzenie limitu zwolnienia podmiotowego 200 000 PLN
(Art. 113 ust. 1 VAT) z prognozą przekroczenia i alertami.

Implementuje:
- Śledzenie skumulowanej sprzedaży w roku podatkowym
- Prognozę daty przekroczenia limitu
- Proporcję dla nowych JDG (Art. 113 ust. 9)
- Alert: "przy obecnym tempie, limit przekroczysz 2026-09-15"
- Automatyczne przypomnienie o rejestracji VAT-R
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.services.vat_exemption")


# ── Configuration ────────────────────────────────────────────────────────────

VAT_EXEMPTION_LIMIT = 200_000.0  # PLN
PROPORTION_DAYS_IN_YEAR = 365
VAT_R_REGISTRATION_DEADLINE_DAYS = 1  # Dzień przed przekroczeniem


@dataclass
class ExemptionStatus:
    """Status zwolnienia podmiotowego VAT."""
    is_exempt: bool
    cumulative_sales: float
    limit: float
    remaining: float
    usage_pct: float  # 0-100%
    estimated_exceed_date: str = ""  # YYYY-MM-DD
    days_until_exceed: int = 0
    needs_vat_r: bool = False
    vat_r_deadline: str = ""
    proportion_factor: float = 1.0  # Dla nowych JDG
    alerts: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)


class VATExemptionTracker:
    """v7.0: Tracker limitu zwolnienia podmiotowego VAT.

    Automatycznie śledzi sprzedaż i prognozuje przekroczenie limitu.
    """

    def __init__(self, duckdb: Any = None) -> None:
        self._duckdb = duckdb
        self._limit = VAT_EXEMPTION_LIMIT

    def track(
        self,
        invoices: list[dict[str, Any]],
        tax_year: int | None = None,
        jdg_start_date: str = "",
    ) -> ExemptionStatus:
        """Śledź status zwolnienia podmiotowego.

        Args:
            invoices: Lista faktur sprzedaży w roku podatkowym.
            tax_year: Rok podatkowy (domyślnie bieżący).
            jdg_start_date: Data rozpoczęcia JDG (YYYY-MM-DD) — dla proporcji.

        Returns:
            ExemptionStatus z prognozą.
        """
        if tax_year is None:
            tax_year = pendulum.today("Europe/Warsaw").year

        # Filtruj faktury z bieżącego roku
        year_invoices = [
            inv for inv in invoices
            if (inv.get("transaction_date", inv.get("date", ""))[:4] == str(tax_year))
        ]

        # Sumuj sprzedaż netto — v7.0 FIX: key-based detection
        cumulative = sum(
            self._parse_net_amount(inv) for inv in year_invoices
        )

        # v7.0 FIX: Użyj zmiennej lokalnej zamiast mutować self._limit
        limit = VAT_EXEMPTION_LIMIT
        proportion = 1.0
        if jdg_start_date:
            try:
                start = pendulum.parse(jdg_start_date)
                year_start = pendulum.datetime(tax_year, 1, 1)
                days_active = max(start.diff(year_start).in_days(), 1)
                proportion = min(PROPORTION_DAYS_IN_YEAR / max(days_active, 1), 1.0)
                if proportion < 1.0:
                    limit = VAT_EXEMPTION_LIMIT * proportion
                    logger.debug(
                        "[VAT-EXEMPT] Proportion adjusted limit: %.0f PLN (%.0f%%)",
                        limit, proportion * 100,
                    )
            except Exception:
                pass
        is_exempt = cumulative <= limit
        remaining = limit - cumulative
        usage_pct = (cumulative / max(limit, 0.01)) * 100

        # Prognoza daty przekroczenia
        estimated_date = ""
        days_until = 0
        alerts: list[str] = []
        recommendations: list[str] = []

        if year_invoices and cumulative > 0:
            # Oblicz dzienną średnią sprzedaży
            today = pendulum.today("Europe/Warsaw")
            day_of_year = today.day_of_year
            daily_avg = cumulative / max(day_of_year, 1)

            if daily_avg > 0 and remaining > 0:
                days_until = int(remaining / daily_avg)
                exceed_date = today.add(days=days_until)
                estimated_date = exceed_date.to_date_string()

                # Alerty
                if days_until <= 30:
                    alerts.append(
                        f"UWAGA: Limit zwolnienia podmiotowego zostanie przekroczony "
                        f"około {estimated_date} (za {days_until} dni)!"
                    )
                    recommendations.append(
                        f"Zarejestruj VAT-R przed {exceed_date.subtract(days=1).to_date_string()}"
                    )
                    recommendations.append(
                        "Po przekroczeniu limitu, pierwsza faktura musi zawierać VAT"
                    )
                elif days_until <= 90:
                    alerts.append(
                        f"Monitoruj limit: wykorzystano {usage_pct:.1f}%, "
                        f"pozostało {remaining:,.0f} PLN. "
                        f"Przy obecnym tempie, limit przekroczysz około {estimated_date}."
                    )

            # Sprawdź czy limit już przekroczony
            if cumulative > limit:
                alerts.append(
                    f"KRYTYCZNE: Limit {limit:,.0f} PLN przekroczony! "
                    f"Sprzedaż: {cumulative:,.0f} PLN."
                )
                recommendations.append(
                    "NATYCHMIASTOWA rejestracja VAT-R! "
                    "Od dnia przekroczenia jesteś czynnym podatnikiem VAT."
                )
                recommendations.append(
                    "Wystaw faktury korygujące z VAT dla transakcji "
                    "po dniu przekroczenia limitu."
                )

        return ExemptionStatus(
            is_exempt=is_exempt,
            cumulative_sales=round(cumulative, 2),
            limit=limit,
            remaining=round(remaining, 2),
            usage_pct=round(usage_pct, 1),
            estimated_exceed_date=estimated_date,
            days_until_exceed=days_until,
            needs_vat_r=not is_exempt or days_until <= 30,
            vat_r_deadline=(
                pendulum.parse(estimated_date).subtract(days=1).to_date_string()
                if estimated_date else ""
            ),
            proportion_factor=round(proportion, 2),
            alerts=alerts,
            recommendations=recommendations,
        )

    @staticmethod
    def _parse_net_amount(inv: dict[str, Any]) -> float:
        """v7.0 FIX: Key-based grosze detection."""
        if "amount_net_grosze" in inv and inv["amount_net_grosze"] is not None:
            return float(inv["amount_net_grosze"]) / 100.0
        if "amount_net" in inv and inv["amount_net"] is not None:
            return float(inv["amount_net"])
        return 0.0

    def get_forecast_chart_data(
        self, invoices: list[dict[str, Any]], tax_year: int | None = None,
    ) -> dict[str, list[Any]]:
        """Generuj dane do wykresu prognozy limitu."""
        if tax_year is None:
            tax_year = pendulum.today("Europe/Warsaw").year

        # Grupuj miesięcznie
        monthly: dict[int, float] = {m: 0.0 for m in range(1, 13)}
        for inv in invoices:
            date = inv.get("transaction_date", inv.get("date", ""))
            if not date or date[:4] != str(tax_year):
                continue
            try:
                month = int(date[5:7])
                monthly[month] += self._parse_net_amount(inv)
            except (ValueError, IndexError):
                continue

        # Kumulatywnie
        cumulative = 0.0
        months = []
        values = []
        limit_line = []
        chart_limit = VAT_EXEMPTION_LIMIT  # v7.0 FIX: stały limit

        for m in range(1, 13):
            cumulative += monthly[m]
            months.append(pendulum.datetime(tax_year, m, 1).format("MMM"))
            values.append(round(cumulative, 2))
            limit_line.append(chart_limit)

        return {
            "months": months,
            "cumulative": values,
            "limit": limit_line,
            "limit_value": chart_limit,
        }
