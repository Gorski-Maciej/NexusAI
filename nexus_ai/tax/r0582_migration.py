"""
R0582 Migration Engine (Phase 5, P0) — Historical DRA Audit & Correction.
==========================================================================

Część planu Phase 5: Legal Hardening Sprint (Kategoria 8: Czarne Łabędzie).
Problem: Jeśli w przeszłości system błędnie nie naliczał składki zdrowotnej
podczas zawieszenia JDG (luka P914 sprzed poprawki), klienci mają zaległości
w ZUS i brak prawa do świadczeń NFZ.

Ta reguła wykonuje audyt historyczny i generuje korekty DRA.

UWAGA: Obecna implementacja P914 w business.rego jest już POPRAWNA
(zus_health_due:true w zawieszeniu). Ten moduł służy jako:
1. Narzędzie audytu historycznego dla okresu przed poprawką
2. Mechanizm walidacji poprawności bieżących DRA
3. Generator notyfikacji o konieczności korekty

Usage:
    engine = R0582MigrationEngine()
    corrections = await engine.audit_historical_dra("jdg_12345")
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Any

logger = logging.getLogger(__name__)


@dataclass
class DraCorrection:
    """Pojedyncza korekta DRA dla okresu zawieszenia."""
    period: str  # YYYY-MM
    entrepreneur_id: str
    was_suspended: bool
    health_contribution_due: float
    health_contribution_paid: float
    shortfall: float  # >0 oznacza niedopłatę
    requires_correction: bool

    @property
    def is_critical(self) -> bool:
        """Czy korekta jest krytyczna (brak składki > 3 miesiące)?"""
        return self.shortfall > 0 and self.shortfall > 3 * self.health_contribution_due


@dataclass
class MigrationReport:
    """Raport z audytu historycznego DRA."""
    entrepreneur_id: str
    periods_checked: int
    corrections_needed: list[DraCorrection] = field(default_factory=list)
    total_shortfall: float = 0.0
    critical_count: int = 0
    notification_sent: bool = False
    generated_at: str = ""

    @property
    def summary(self) -> str:
        return (
            f"Audyt DRA dla {self.entrepreneur_id}: "
            f"sprawdzono {self.periods_checked} okresów, "
            f"znaleziono {len(self.corrections_needed)} korekt, "
            f"łączna niedopłata: {self.total_shortfall:.2f} PLN, "
            f"krytycznych: {self.critical_count}"
        )


class R0582MigrationEngine:
    """Silnik audytu i korekty historycznych DRA po poprawce R0582.

    Reguła R0582 (poprawka P914):
    Art. 36a ust. 4 ustawy o SUS — w trakcie zawieszenia JDG:
    - składki SPOŁECZNE: 0 (zwolnione)
    - składka ZDROWOTNA: NADAL NALEŻNA (minimalna podstawa)
    """

    # Minimalna podstawa składki zdrowotnej (2024-2026)
    HEALTH_MINIMAL_BASE: dict[str, float] = {
        "2024": 4666.00,
        "2025": 5200.00,
        "2026": 5500.00,
    }

    HEALTH_RATE_SCALE = 0.09  # 9% dla skali/karty
    HEALTH_RATE_LINEAR_LUMP = 0.049  # 4.9% dla liniowego/ryczałtu

    def __init__(self) -> None:
        pass

    async def audit_historical_dra(
        self,
        entrepreneur_id: str,
        start_period: str = "2024-01",
        end_period: str | None = None,
    ) -> MigrationReport:
        """Przeprowadza audyt historycznych DRA dla JDG.

        Sprawdza wszystkie okresy od start_period, identyfikując miesiące
        zawieszenia, gdzie składka zdrowotna mogła nie zostać naliczona.

        Args:
            entrepreneur_id: Identyfikator JDG.
            start_period: Początkowy okres audytu (domyślnie 2024-01,
                          od kiedy obowiązuje Polski Ład 3.0).
            end_period: Końcowy okres (domyślnie bieżący miesiąc).

        Returns:
            MigrationReport z listą potrzebnych korekt.
        """
        if end_period is None:
            today = date.today()
            end_period = f"{today.year}-{today.month:02d}"

        # Pobierz historię statusów JDG (w produkcji: z DuckDB)
        suspension_periods = await self._get_suspension_periods(
            entrepreneur_id, start_period, end_period,
        )

        # Pobierz historyczne DRA
        dra_records = await self._get_dra_records(
            entrepreneur_id, start_period, end_period,
        )

        report = MigrationReport(
            entrepreneur_id=entrepreneur_id,
            periods_checked=len(dra_records),
            generated_at=datetime.now().isoformat(),
        )

        for period in suspension_periods:
            correction = self._check_period(period, dra_records, entrepreneur_id)
            if correction.requires_correction:
                report.corrections_needed.append(correction)
                report.total_shortfall += correction.shortfall
                if correction.is_critical:
                    report.critical_count += 1

        logger.info(f"[R0582] {report.summary}")
        return report

    async def _get_suspension_periods(
        self,
        entrepreneur_id: str,
        start: str,
        end: str,
    ) -> list[str]:
        """Pobiera okresy zawieszenia JDG z bazy danych.

        W produkcji: zapytanie DuckDB.
        """
        # Symulacja — w produkcji:
        # SELECT period FROM jdg_status_history
        # WHERE entrepreneur_id = ? AND status = 'SUSPENDED'
        # AND period BETWEEN ? AND ?
        return []  # Placeholder

    async def _get_dra_records(
        self,
        entrepreneur_id: str,
        start: str,
        end: str,
    ) -> dict[str, dict[str, Any]]:
        """Pobiera historyczne deklaracje DRA."""
        # Symulacja
        return {}  # Placeholder

    def _check_period(
        self,
        period: str,
        dra_records: dict[str, dict[str, Any]],
        entrepreneur_id: str,
    ) -> DraCorrection:
        """Sprawdza pojedynczy okres pod kątem brakującej składki zdrowotnej."""
        year = period[:4]
        health_base = self.HEALTH_MINIMAL_BASE.get(
            year, self.HEALTH_MINIMAL_BASE["2026"],
        )

        # Oblicz należną składkę zdrowotną
        # (uproszczenie: dla skali 9% od minimalnej podstawy)
        health_due = round(health_base * self.HEALTH_RATE_SCALE, 2)

        dra = dra_records.get(period, {})
        health_paid = float(dra.get("health_contribution", 0))
        shortfall = max(0, health_due - health_paid)

        return DraCorrection(
            period=period,
            entrepreneur_id=entrepreneur_id,
            was_suspended=True,
            health_contribution_due=health_due,
            health_contribution_paid=health_paid,
            shortfall=shortfall,
            requires_correction=shortfall > 0.01,
        )

    async def generate_correction_dra(
        self,
        correction: DraCorrection,
        tax_form: str = "PIT_SCALE",
    ) -> dict[str, Any]:
        """Generuje skorygowaną deklarację DRA."""
        return {
            "period": correction.period,
            "entrepreneur_id": correction.entrepreneur_id,
            "correction_type": "R0582_HEALTH_CONTRIBUTION",
            "original_health_paid": correction.health_contribution_paid,
            "corrected_health_due": correction.health_contribution_due,
            "shortfall": correction.shortfall,
            "legal_basis": "Art. 36a ust. 4 SUS (Polski Ład 3.0, od 2024-01-01)",
            "tax_form": tax_form,
        }

    async def notify_entrepreneur(
        self,
        report: MigrationReport,
    ) -> str:
        """Generuje treść powiadomienia dla przedsiębiorcy.

        UWAGA: Ta notyfikacja powinna być wysłana PROAKTYWNIE
        przed wdrożeniem poprawki, aby uniknąć masowego revoltu.
        """
        if not report.corrections_needed:
            return ""

        critical_warning = ""
        if report.critical_count > 0:
            critical_warning = (
                f"\n⚠️ UWAGA: {report.critical_count} okresów ma zaległości "
                f"powyżej 3 miesięcy — może to skutkować brakiem prawa "
                f"do świadczeń NFZ!"
            )

        return f"""
📋 **Ważna informacja o Twoich składkach ZUS**

W wyniku audytu technicznego system wykrył, że w okresach zawieszenia
Twojej działalności składka zdrowotna mogła nie zostać naliczona.

**Podsumowanie:**
- Sprawdzono okresów: {report.periods_checked}
- Okresy wymagające korekty: {len(report.corrections_needed)}
- Łączna niedopłata: {report.total_shortfall:.2f} PLN
{critical_warning}

**Podstawa prawna:**
Art. 36a ust. 4 ustawy o systemie ubezpieczeń społecznych —
składka zdrowotna NADAL NALEŻNA w okresie zawieszenia JDG
(w brzmieniu obowiązującym od 1 stycznia 2024 r.).

**Co zrobić:**
1. System automatycznie wygeneruje korekty DRA za wskazane okresy
2. Składki można rozłożyć na raty w ZUS (wniosek online)
3. Po opłaceniu zaległości prawo do świadczeń NFZ zostanie przywrócone

**Kontakt:**
W razie pytań skontaktuj się z naszym zespołem wsparcia.
"""
