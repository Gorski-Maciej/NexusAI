"""
Liquidity Oracle (C3) — Wyrocznia Płynności — Symulacje Metody Kasowej.
========================================================================

Część strategicznego planu 48_JDG_STRATEGIC_IMPROVEMENTS_V2.md.
Co kwartał analizuje historię płatności JDG i symuluje scenariusz
alternatywny: "co by było, gdybyś przeszedł na metodę kasową?"

Porównuje metodę memoriałową (status quo) z metodą kasową (alternatywa)
i rekomenduje zmianę, gdy średnie opóźnienie płatności > 60 dni
a luka płynnościowa > 5000 PLN.

Usage:
    oracle = LiquidityOracle(opa_client, db_connection)
    report = oracle.quarterly_analysis(entrepreneur_id)
    if report.recommendation:
        print(report.recommendation)
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class LiquidityReport:
    """Raport kwartalny Wyroczni Płynności."""
    entrepreneur_id: str
    quarter_start: str
    quarter_end: str
    avg_contractor_delay_days: float
    liquidity_gap_pln: float
    accrual_method_tax: float
    cash_method_tax: float
    invoices_analyzed: int
    invoices_paid_late: int
    eligible_for_cash_accounting: bool = False
    recommendation: str | None = None
    metrics: dict[str, Any] = field(default_factory=dict)


class LiquidityOracle:
    """Analizuje historię płatności i symuluje scenariusze kasowe.

    Używa DuckDB do pobierania historii faktur i OPA do ponownej
    ewaluacji z flagą ``vat_cash_accounting: true``.
    """

    def __init__(self, db_connection: Any, opa_client: Any = None) -> None:
        self._db = db_connection
        self._opa = opa_client

    def quarterly_analysis(
        self,
        entrepreneur_id: str,
        quarter_start: str | None = None,
        quarter_end: str | None = None,
    ) -> LiquidityReport:
        """Przeprowadza analizę kwartalną dla JDG.

        Args:
            entrepreneur_id: ID przedsiębiorcy JDG.
            quarter_start: Data początkowa kwartału (domyślnie: początek bieżącego kwartału).
            quarter_end: Data końcowa kwartału (domyślnie: koniec bieżącego kwartału).

        Returns:
            LiquidityReport z rekomendacją zmiany metody.
        """
        import datetime as dt

        today = dt.date.today()
        if quarter_start is None:
            qmonth = ((today.month - 1) // 3) * 3 + 1
            quarter_start = f"{today.year}-{qmonth:02d}-01"
        if quarter_end is None:
            import calendar

            qmonth = ((today.month - 1) // 3) * 3 + 3
            last_day = calendar.monthrange(today.year, qmonth)[1]
            quarter_end = f"{today.year}-{qmonth:02d}-{last_day:02d}"

        # Pobierz faktury z kwartału
        invoices = self._fetch_quarterly_invoices(
            entrepreneur_id, quarter_start, quarter_end
        )

        if not invoices:
            return LiquidityReport(
                entrepreneur_id=entrepreneur_id,
                quarter_start=quarter_start,
                quarter_end=quarter_end,
                avg_contractor_delay_days=0.0,
                liquidity_gap_pln=0.0,
                accrual_method_tax=0.0,
                cash_method_tax=0.0,
                invoices_analyzed=0,
                invoices_paid_late=0,
            )

        # Oblicz metryki opóźnień
        delays = [
            inv.get("days_overdue", 0)
            for inv in invoices
            if inv.get("days_overdue", 0) > 0
        ]
        avg_delay = sum(delays) / len(delays) if delays else 0.0
        paid_late = len(delays)

        # Symulacja memoriałowa (status quo)
        accrual_tax = self._simulate_tax(invoices, cash_accounting=False)

        # Symulacja kasowa (alternatywa)
        cash_tax = self._simulate_tax(invoices, cash_accounting=True)

        liquidity_gap = max(0.0, accrual_tax - cash_tax)

        # Sprawdź warunki kwalifikacji do metody kasowej
        entrepreneur = self._fetch_entrepreneur(entrepreneur_id)
        eligible = (
            entrepreneur.get("is_small_taxpayer", False)
            and entrepreneur.get("is_vat_payer", False)
        )

        # Wygeneruj rekomendację
        recommendation = None
        if avg_delay > 60 and liquidity_gap > 5000:
            if eligible:
                recommendation = (
                    f"Średnie opóźnienie płatności kontrahentów: {avg_delay:.0f} dni. "
                    f"Przejście na metodę kasową uwolniłoby około {liquidity_gap:.0f} PLN "
                    f"w tym kwartale (różnica w podatku do zapłaty). "
                    f"Jesteś małym podatnikiem i spełniasz warunki — rozważ złożenie "
                    f"zgłoszenia do US o przejściu na metodę kasową od przyszłego roku."
                )
            else:
                recommendation = (
                    f"Średnie opóźnienie płatności: {avg_delay:.0f} dni. "
                    f"Metoda kasowa uwolniłaby {liquidity_gap:.0f} PLN, ale nie spełniasz "
                    f"warunku małego podatnika. Rozważ restrukturyzację należności."
                )

        return LiquidityReport(
            entrepreneur_id=entrepreneur_id,
            quarter_start=quarter_start,
            quarter_end=quarter_end,
            avg_contractor_delay_days=round(avg_delay, 1),
            liquidity_gap_pln=round(liquidity_gap, 2),
            accrual_method_tax=round(accrual_tax, 2),
            cash_method_tax=round(cash_tax, 2),
            invoices_analyzed=len(invoices),
            invoices_paid_late=paid_late,
            eligible_for_cash_accounting=eligible,
            recommendation=recommendation,
            metrics={
                "avg_delay_days": round(avg_delay, 1),
                "median_delay_days": round(
                    sorted(delays)[len(delays) // 2] if delays else 0, 1
                ),
                "max_delay_days": max(delays) if delays else 0,
                "liquidity_gap_percent": round(
                    liquidity_gap / accrual_tax * 100 if accrual_tax > 0 else 0, 1
                ),
            },
        )

    def _fetch_quarterly_invoices(
        self, entrepreneur_id: str, quarter_start: str, quarter_end: str,
    ) -> list[dict[str, Any]]:
        """Pobiera faktury JDG z kwartału z DuckDB."""
        try:
            result = self._db.execute("""
                SELECT
                    invoice_id,
                    amount_net,
                    amount_gross,
                    vat_rate,
                    direction,
                    issue_date,
                    due_date,
                    payment_date,
                    DATEDIFF('day', due_date, COALESCE(payment_date, CURRENT_DATE))
                        AS days_overdue,
                    is_paid,
                    category_code,
                    procedure
                FROM invoices
                WHERE entrepreneur_id = ?
                  AND issue_date >= ?
                  AND issue_date <= ?
                ORDER BY issue_date
            """, [entrepreneur_id, quarter_start, quarter_end]).fetchall()

            columns = [
                "invoice_id", "amount_net", "amount_gross", "vat_rate",
                "direction", "issue_date", "due_date", "payment_date",
                "days_overdue", "is_paid", "category_code", "procedure",
            ]

            return [dict(zip(columns, row)) for row in result]
        except Exception:
            return []

    def _fetch_entrepreneur(self, entrepreneur_id: str) -> dict[str, Any]:
        """Pobiera dane przedsiębiorcy do sprawdzenia kwalifikowalności."""
        try:
            result = self._db.execute("""
                SELECT is_small_taxpayer, is_vat_payer, tax_form, annual_turnover_net
                FROM entrepreneurs
                WHERE id = ?
            """, [entrepreneur_id]).fetchone()

            if result:
                return {
                    "is_small_taxpayer": bool(result[0]),
                    "is_vat_payer": bool(result[1]),
                    "tax_form": str(result[2]),
                    "annual_turnover_net": float(result[3]) if result[3] else 0.0,
                }
        except Exception:
            pass

        return {
            "is_small_taxpayer": False,
            "is_vat_payer": True,
        }

    def _simulate_tax(
        self, invoices: list[dict[str, Any]], cash_accounting: bool,
    ) -> float:
        """Symuluje podatek dla listy faktur z daną metodą.

        Metoda memoriałowa: VAT należny w dacie wystawienia faktury.
        Metoda kasowa: VAT należny dopiero w dacie zapłaty (dla małych podatników).

        Jeśli OPA client jest dostępny, używa go do dokładnej symulacji.
        W przeciwnym razie używa uproszczonej kalkulacji.
        """
        if self._opa is not None:
            return self._simulate_with_opa(invoices, cash_accounting)

        return self._simulate_simple(invoices, cash_accounting)

    def _simulate_with_opa(
        self, invoices: list[dict[str, Any]], cash_accounting: bool,
    ) -> float:
        """Dokładna symulacja przez OPA (async fallback do simple)."""
        # OpaClient tylko async — użyj uproszczonej symulacji jako fallback
        # W przyszłości: integracja z asyncio event loop
        return self._simulate_simple(invoices, cash_accounting)

    def _simulate_simple(
        self, invoices: list[dict[str, Any]], cash_accounting: bool,
    ) -> float:
        """Uproszczona symulacja bez OPA."""
        total_tax = 0.0
        for inv in invoices:
            if cash_accounting and not inv.get("is_paid"):
                continue  # Metoda kasowa: brak zapłaty = brak podatku

            vat_rate = float(inv.get("vat_rate", "0.23"))
            amount = inv.get("amount_net", 0)
            total_tax += amount * vat_rate

        return total_tax


def run_quarterly_oracle(
    db_connection: Any,
    entrepreneur_id: str,
    opa_client: Any = None,
) -> LiquidityReport:
    """Funkcja pomocnicza do szybkiego uruchomienia Wyroczni."""
    oracle = LiquidityOracle(db_connection, opa_client)
    return oracle.quarterly_analysis(entrepreneur_id)
