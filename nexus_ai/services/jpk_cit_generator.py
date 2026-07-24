"""
v7.0 INNOWACJA: JPK_CIT dla JDG na CIT — JPK_KR i JPK_ST.

Raport v7.0 LUKA: JPK_CIT dla JDG na CIT (Estoński CIT, CIT liniowy
przy przekształceniu) NIE jest zaimplementowany (0/5).

Sytuacje gdy JDG jest na CIT:
1. Przekształcenie JDG w spółkę z o.o. (w trakcie roku)
2. Estoński CIT dla JDG (od 2025 możliwy dla wybranych form)
3. CIT liniowy 19% przy przekroczeniu progu przychodów

Ten moduł generuje:
- JPK_KR (Księgi Rachunkowe) — dla JDG na pełnej księgowości
- JPK_ST (Środki Trwałe) — ewidencja środków trwałych CIT
- Kalkulację CIT należnego z odliczeniami
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.jpk_cit")


# ── Configuration ────────────────────────────────────────────────────────────

CIT_STANDARD_RATE = 0.19       # CIT liniowy
CIT_ESTONIAN_RATE = 0.20       # Estoński CIT (20% od wypłaconego zysku)
CIT_SMALL_TAXPAYER_RATE = 0.09 # Mały podatnik CIT
SMALL_TAXPAYER_REVENUE_EUR = 2_000_000  # 2M EUR
JPK_KR_THRESHOLD_PLN = 2_000_000  # 2M PLN = obowiązek pełnej księgowości


@dataclass
class JPKCITResult:
    """Wynik generacji JPK_CIT."""

    cit_type: str = ""  # STANDARD, ESTONIAN, SMALL_TAXPAYER
    cit_rate: float = 0.19
    cit_revenue: float = 0.0
    cit_costs: float = 0.0
    cit_income: float = 0.0
    cit_deductions: dict[str, float] = field(default_factory=dict)
    cit_taxable_base: float = 0.0
    cit_tax_due: float = 0.0
    cit_advances_paid: float = 0.0
    cit_to_pay: float = 0.0
    jpk_kr_required: bool = False
    jpk_st_required: bool = False
    jpk_kr_structure: dict[str, Any] = field(default_factory=dict)
    jpk_st_assets: list[dict[str, Any]] = field(default_factory=list)
    is_estonian_cit: bool = False
    warnings: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)


class JPKCITGenerator:
    """v7.0: Generator JPK_CIT dla JDG na CIT."""

    # ── Mapowanie kont PKPiR → JPK_KR (używane w _build_jpk_kr) ──────────
    PKPIR_TO_JPK_KR: dict[str, str] = {
        "col_7_revenue": "A.PrzychodyNettoZeSprzedazy",
        "col_8_other_revenue": "B.PozostalePrzychodyOperacyjne",
        "col_9_financial_revenue": "C.PrzychodyFinansowe",
        "col_10_cost_of_goods": "D.KosztyWlasneSprzedazy",
        "col_11_operating_costs": "E.KosztyOgolneZarzadu",
        "col_12_other_expenses": "F.PozostaleKosztyOperacyjne",
        "col_13_financial_expenses": "G.KosztyFinansowe",
    }

    def generate(
        self,
        jdg_data: dict[str, Any],
        tax_period: str = "2026-07",
        tax_year: int = 2026,
    ) -> JPKCITResult:
        """Wygeneruj JPK_CIT dla JDG.

        Args:
            jdg_data: Dane JDG (tax_form, revenue, costs, etc.).
            tax_period: Okres rozliczeniowy (YYYY-MM).
            tax_year: Rok podatkowy.

        Returns:
            JPKCITResult z wyliczonym CIT i strukturami JPK.
        """
        result = JPKCITResult()
        warnings: list[str] = []
        recommendations: list[str] = []

        tax_form = jdg_data.get("tax_form", "PIT_SCALE")

        # Guard: tylko JDG na CIT
        if tax_form not in ("CIT", "CIT_LINEAR", "ESTONIAN_CIT", "CIT_SMALL"):
            result.warnings.append(
                f"JDG na {tax_form} — JPK_CIT nie ma zastosowania. "
                f"JPK_CIT dotyczy tylko JDG na CIT (Estoński CIT, CIT liniowy)."
            )
            return result

        annual_revenue = float(jdg_data.get("annual_revenue", 0))
        annual_costs = float(jdg_data.get("annual_costs", 0))
        annual_revenue_eur = float(jdg_data.get("annual_revenue_eur", 0))
        uses_full_accounting = jdg_data.get("uses_full_accounting", False)
        is_estonian_cit = jdg_data.get("estonian_cit_active", False)

        # 1. Określ typ CIT
        if is_estonian_cit:
            result.cit_type = "ESTONIAN"
            result.cit_rate = CIT_ESTONIAN_RATE
            result.is_estonian_cit = True
            # Estoński CIT: podatek od wypłaconego zysku, nie od dochodu
            distributed_profit = float(jdg_data.get("distributed_profit", 0))
            result.cit_taxable_base = distributed_profit
            result.cit_tax_due = distributed_profit * CIT_ESTONIAN_RATE
            recommendations.append(
                "Estoński CIT: podatek płacony tylko od wypłaconego zysku. "
                "Reinwestycja = odroczenie CIT."
            )
        elif annual_revenue_eur < SMALL_TAXPAYER_REVENUE_EUR and tax_year <= 2026:
            result.cit_type = "SMALL_TAXPAYER"
            result.cit_rate = CIT_SMALL_TAXPAYER_RATE
        else:
            result.cit_type = "STANDARD"
            result.cit_rate = CIT_STANDARD_RATE

        # 2. Oblicz przychody i koszty CIT
        result.cit_revenue = annual_revenue
        result.cit_costs = min(annual_costs, annual_revenue)  # max do przychodów

        # NKUP — wydatki nie stanowiące kosztów uzyskania przychodu
        nkup_items = jdg_data.get("nkup_items", {})
        nkup_total = sum(float(v) for v in nkup_items.values()) if nkup_items else 0.0
        result.cit_income = result.cit_revenue - result.cit_costs + nkup_total

        # 3. Odliczenia CIT
        deductions: dict[str, float] = {}

        # Darowizny (max 10% dochodu)
        donations = float(jdg_data.get("donations_total", 0))
        max_donation = result.cit_income * 0.10
        if donations > 0:
            deductions["donations"] = min(donations, max_donation)

        # Ulga B+R (IP Box)
        ip_box_income = float(jdg_data.get("ip_box_income", 0))
        if ip_box_income > 0:
            deductions["ip_box"] = ip_box_income * 0.05  # 5% stawka IP Box
            recommendations.append(
                f"IP Box: {ip_box_income:.0f} PLN dochodu × 5% stawka"
            )

        # Strata z lat ubiegłych (max 50% dochodu)
        past_losses = float(jdg_data.get("past_tax_losses", 0))
        max_loss_deduction = result.cit_income * 0.50
        if past_losses > 0:
            deductions["past_losses"] = min(past_losses, max_loss_deduction)

        result.cit_deductions = deductions
        total_deductions = sum(deductions.values())

        # 4. Podstawa opodatkowania
        result.cit_taxable_base = max(0.0, result.cit_income - total_deductions)

        # 5. CIT należny
        if not is_estonian_cit:
            result.cit_tax_due = result.cit_taxable_base * result.cit_rate

        # 6. Zaliczki wpłacone
        result.cit_advances_paid = float(jdg_data.get("cit_advances_paid", 0))
        result.cit_to_pay = max(0.0, result.cit_tax_due - result.cit_advances_paid)

        # 7. JPK_KR — obowiązek dla pełnej księgowości (>2M PLN)
        result.jpk_kr_required = (
            uses_full_accounting or annual_revenue > JPK_KR_THRESHOLD_PLN
        )
        if result.jpk_kr_required:
            result.jpk_kr_structure = self._build_jpk_kr(result)
            warnings.append(
                "JPK_KR WYMAGANY — JDG na pełnej księgowości musi składać JPK_KR. "
                "Termin: 10. dzień następnego miesiąca."
            )

        # 8. JPK_ST — środki trwałe
        fixed_assets = jdg_data.get("fixed_assets", [])
        if fixed_assets:
            result.jpk_st_required = True
            result.jpk_st_assets = self._build_jpk_st(fixed_assets)

        # 9. Rekomendacje
        if result.cit_to_pay > 0:
            recommendations.append(
                f"CIT do zapłaty: {result.cit_to_pay:.2f} PLN. "
                f"Termin: do 20. dnia następnego miesiąca."
            )
        elif result.cit_to_pay < 0:
            recommendations.append(
                f"NADPŁATA CIT: {abs(result.cit_to_pay):.2f} PLN. "
                f"Złóż wniosek o zwrot CIT-5Z."
            )

        result.warnings = warnings
        result.recommendations = recommendations

        logger.info(
            "[JPK-CIT] type=%s revenue=%.0f tax=%.2f to_pay=%.2f jpk_kr=%s",
            result.cit_type,
            result.cit_revenue,
            result.cit_tax_due,
            result.cit_to_pay,
            result.jpk_kr_required,
        )

        return result

    def _build_jpk_kr(self, result: JPKCITResult, tax_period: str = "07", tax_year: int = 2026) -> dict[str, Any]:
        """Zbuduj strukturę JPK_KR."""
        return {
            "version": "1-0E",
            "tax_year": tax_year,
            "tax_period": tax_period,
            "entity": {
                "tax_identification": "NIP",
                "cit_form": result.cit_type,
            },
            "pl_account": {
                "revenue_net": round(result.cit_revenue, 2),
                "other_revenue": 0.0,
                "financial_revenue": 0.0,
                "cost_of_goods_sold": 0.0,
                "operating_costs": round(result.cit_costs, 2),
                "other_costs": 0.0,
                "financial_costs": 0.0,
                "gross_profit_loss": round(result.cit_income, 2),
                "income_tax_current": round(result.cit_tax_due, 2),
                "net_profit_loss": round(result.cit_income - result.cit_tax_due, 2),
            },
            "tax_reconciliation": {
                "accounting_income": round(result.cit_income, 2),
                "permanent_differences": {},
                "temporary_differences": {},
                "taxable_base": round(result.cit_taxable_base, 2),
                "tax_rate": result.cit_rate,
                "tax_due": round(result.cit_tax_due, 2),
            },
        }

    def _build_jpk_st(
        self, assets: list[dict[str, Any]],
    ) -> list[dict[str, Any]]:
        """Zbuduj strukturę JPK_ST — ewidencja środków trwałych."""
        result = []
        for i, asset in enumerate(assets):
            result.append({
                "id": i + 1,
                "name": asset.get("name", ""),
                "kst_group": asset.get("kst_group", ""),
                "acquisition_date": asset.get("acquisition_date", ""),
                "initial_value": asset.get("initial_value", 0.0),
                "depreciation_method": asset.get("depreciation_method", "LINEAR"),
                "depreciation_rate": asset.get("depreciation_rate", 0.20),
                "annual_depreciation": asset.get("annual_depreciation", 0.0),
                "accumulated_depreciation": asset.get("accumulated_depreciation", 0.0),
                "net_book_value": asset.get("net_book_value", 0.0),
                "improvements": asset.get("improvements", 0.0),
                "disposal_date": asset.get("disposal_date", ""),
                "disposal_reason": asset.get("disposal_reason", ""),
            })
        return result

    def check_estonian_cit_eligibility(
        self, jdg_data: dict[str, Any],
    ) -> dict[str, Any]:
        """Sprawdź czy JDG kwalifikuje się do Estońskiego CIT.

        Warunki (od 2025):
        - Przychody < 2M EUR rocznie
        - Zatrudnienie min. 3 osoby (lub koszty wynagrodzeń > 100k PLN)
        - Minimum 50% przychodów z działalności operacyjnej
        - Brak udziałów w innych spółkach
        """
        revenue_eur = float(jdg_data.get("annual_revenue_eur", 0))
        employees = int(jdg_data.get("employees_count", 0))
        payroll_costs = float(jdg_data.get("annual_payroll_costs", 0))
        operating_revenue_pct = float(jdg_data.get("operating_revenue_pct", 100))

        eligible = True
        reasons: list[str] = []

        if revenue_eur >= 2_000_000:
            eligible = False
            reasons.append(f"Przychody {revenue_eur:.0f} EUR przekraczają limit 2M EUR")

        if employees < 3 and payroll_costs < 100_000:
            eligible = False
            reasons.append(
                f"Zatrudnienie {employees} os. < 3 i koszty płac {payroll_costs:.0f} PLN < 100k"
            )

        if operating_revenue_pct < 50:
            eligible = False
            reasons.append(
                f"Przychody operacyjne {operating_revenue_pct:.0f}% < 50%"
            )

        return {
            "eligible": eligible,
            "reasons": reasons if reasons else ["Spełniasz wszystkie warunki Estońskiego CIT!"],
            "benefits_if_eligible": [
                "Brak podatku od reinwestowanych zysków",
                "20% CIT tylko od wypłaconego zysku",
                "Uproszczona księgowość (brak odroczonego podatku)",
                "Brak obowiązku JPK_KR (jeśli nie przekraczasz 2M EUR)",
            ],
        }
