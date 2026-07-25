"""
tax_relief_engine.py — Enterprise Tax Relief Calculation Engine (v7.0 Audit)

Unified calculation engine for all major tax reliefs:
  - R&D Relief (Art. 26e PIT): 100-200% qualified costs deduction
  - IP Box (Art. 30ca PIT): 5% tax rate on qualified IP income
  - Thermo-modernization Relief (Art. 26h PIT): up to 53,000 PLN deduction
  - Donation Relief (Art. 26 PIT): up to 6% of income
  - Tax Loss Harvesting (Art. 9 PIT): 5-year carry-forward, max 50%/year
  - Cross-Relief Interaction: compatibility matrix + optimal stacking strategy

Enterprise v7.0 — Wypełnia luki CR1-CR4, H4, S5, S8 z Raportu PIT/ZUS/PKPiR v7.0
"""

from __future__ import annotations

from dataclasses import dataclass, field
from decimal import Decimal
from enum import Enum
from typing import Any

import logging

logger = logging.getLogger("nexus.tax_relief_engine")


# ═══════════════════════════════════════════════════════════════════════════════
# Data Types
# ═══════════════════════════════════════════════════════════════════════════════


class ReliefType(str, Enum):
    """Typ ulgi podatkowej."""
    RD = "rd"                        # Ulga B+R
    IP_BOX = "ip_box"               # IP Box 5%
    THERMO = "thermo"               # Termomodernizacyjna
    DONATION = "donation"           # Darowizny
    PROTOTYPE = "prototype"         # Prototyp
    ROBOTIZATION = "robotization"   # Robotyzacja
    EXPANSION = "expansion"         # Ekspansja


class TaxForm(str, Enum):
    """Forma opodatkowania."""
    SCALE = "PIT_SCALE"
    LINEAR = "LINEAR"
    LUMP_SUM = "LUMP_SUM"
    TAX_CARD = "TAX_CARD"
    ESTONIAN_CIT = "ESTONIAN_CIT"


@dataclass
class RDReliefInput:
    """Dane wejściowe dla ulgi B+R."""
    has_rd_activity: bool = False
    is_creative: bool = False
    is_systematic: bool = False
    is_transferable: bool = False
    staff_costs: float = 0.0
    materials_costs: float = 0.0
    expertise_costs: float = 0.0
    depreciation_costs: float = 0.0
    contract_costs: float = 0.0
    rd_income: float = 0.0
    is_rd_center: bool = False
    has_separate_evidence: bool = False


@dataclass
class IPBoxInput:
    """Dane wejściowe dla IP Box."""
    has_qualifying_ip: bool = False
    ip_category: str = ""           # PATENT, SOFTWARE, UTILITY_MODEL, etc.
    ip_income: float = 0.0
    nexus_qualified_costs: float = 0.0
    nexus_total_costs: float = 0.0
    has_separate_evidence: bool = False
    pit_ip_filed: bool = False


@dataclass
class ThermoInput:
    """Dane wejściowe dla ulgi termomodernizacyjnej."""
    owns_property: bool = False
    is_co_owner: bool = False
    windows_doors_costs: float = 0.0
    insulation_costs: float = 0.0
    heating_system_costs: float = 0.0
    solar_pv_costs: float = 0.0
    ventilation_costs: float = 0.0
    government_subsidy: float = 0.0
    first_invoice_date: str = ""    # YYYY-MM-DD
    has_vat_invoices: bool = False
    already_deducted_elsewhere: bool = False


@dataclass
class DonationInput:
    """Dane wejściowe dla ulgi darowizn."""
    opp_donations: float = 0.0
    church_donations: float = 0.0
    blood_liters: float = 0.0
    annual_income: float = 0.0
    has_bank_transfer: bool = False
    has_opp_certificate: bool = False


@dataclass
class ReliefResult:
    """Wynik kalkulacji ulgi."""
    relief_type: ReliefType
    is_eligible: bool = False
    qualified_costs: float = 0.0
    deductible_amount: float = 0.0
    tax_savings: float = 0.0
    effective_rate: float = 0.0
    warnings: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)


@dataclass
class CrossReliefResult:
    """Wynik optymalizacji między-ulgowej."""
    available_reliefs: list[ReliefType] = field(default_factory=list)
    incompatible_pairs: list[str] = field(default_factory=list)
    separate_income_pairs: list[str] = field(default_factory=list)
    optimal_order: list[str] = field(default_factory=list)
    total_estimated_savings: float = 0.0
    best_combination: list[str] = field(default_factory=list)
    strategy_notes: list[str] = field(default_factory=list)


# ═══════════════════════════════════════════════════════════════════════════════
# Compatibility Matrix
# ═══════════════════════════════════════════════════════════════════════════════

RELIEF_COMPATIBILITY = {
    ("RD", "IP_BOX"): "SEPARATE",
    ("RD", "PROTOTYPE"): True,
    ("RD", "ROBOTIZATION"): True,
    ("RD", "EXPANSION"): True,
    ("RD", "THERMO"): True,
    ("RD", "DONATION"): True,
    ("IP_BOX", "PROTOTYPE"): True,
    ("IP_BOX", "ROBOTIZATION"): True,
    ("IP_BOX", "THERMO"): True,
    ("IP_BOX", "DONATION"): True,
}

RELIEF_OPTIMAL_ORDER = [
    "TAX_LOSS", "IP_BOX", "RD", "PROTOTYPE",
    "ROBOTIZATION", "EXPANSION", "THERMO", "DONATION",
]

FORM_RELIEF_AVAILABILITY = {
    TaxForm.SCALE: {ReliefType.RD, ReliefType.IP_BOX, ReliefType.THERMO,
                     ReliefType.DONATION, ReliefType.PROTOTYPE,
                     ReliefType.ROBOTIZATION, ReliefType.EXPANSION},
    TaxForm.LINEAR: {ReliefType.RD, ReliefType.IP_BOX, ReliefType.THERMO,
                      ReliefType.DONATION, ReliefType.PROTOTYPE,
                      ReliefType.ROBOTIZATION, ReliefType.EXPANSION},
    TaxForm.LUMP_SUM: {ReliefType.THERMO, ReliefType.DONATION},
    TaxForm.TAX_CARD: {ReliefType.THERMO, ReliefType.DONATION},
    TaxForm.ESTONIAN_CIT: set(),
}


# ═══════════════════════════════════════════════════════════════════════════════
# Tax Relief Calculation Engine
# ═══════════════════════════════════════════════════════════════════════════════


class TaxReliefEngine:
    """Unified engine for calculating all enterprise tax reliefs.

    Usage:
        engine = TaxReliefEngine()
        rd_result = engine.calculate_rd_relief(rd_input, tax_form=TaxForm.SCALE)
        ipbox_result = engine.calculate_ipbox(ipbox_input, tax_form=TaxForm.LINEAR)
        cross_result = engine.optimize_cross_reliefs(results, annual_income=150000)
    """

    # ── R&D Relief (Art. 26e PIT) ──────────────────────────────────────────────

    def calculate_rd_relief(
        self, inp: RDReliefInput, tax_form: TaxForm
    ) -> ReliefResult:
        """Calculate R&D tax relief (100-200% of qualified costs)."""
        result = ReliefResult(relief_type=ReliefType.RD)

        # Check form eligibility
        if tax_form not in {TaxForm.SCALE, TaxForm.LINEAR}:
            result.warnings.append(
                f"Ulga B+R niedostępna dla formy {tax_form.value} — tylko skala i liniowy"
            )
            return result

        # Check 3 criteria (min 2 required)
        criteria_met = sum([inp.is_creative, inp.is_systematic, inp.is_transferable])
        if criteria_met < 2:
            result.warnings.append(
                f"B+R: tylko {criteria_met}/3 kryteriów spełnionych (wymagane min. 2)"
            )
            return result

        if not inp.has_rd_activity:
            result.warnings.append("B+R: brak zdefiniowanej działalności B+R")
            return result

        # Total qualified costs
        qualified = (
            inp.staff_costs + inp.materials_costs + inp.expertise_costs +
            inp.depreciation_costs + inp.contract_costs
        )

        if qualified <= 0:
            result.warnings.append("B+R: brak kosztów kwalifikowanych")
            return result

        # Multiplier: 100% standard, 200% for R&D center
        multiplier = 2.0 if inp.is_rd_center else 1.0
        deductible_raw = qualified * multiplier

        # Capped by R&D income
        deductible = min(deductible_raw, inp.rd_income)

        # Tax savings (assuming 12% or 19% rate)
        tax_rate = 0.12 if tax_form == TaxForm.SCALE else 0.19
        savings = deductible * tax_rate

        result.is_eligible = True
        result.qualified_costs = qualified
        result.deductible_amount = deductible
        result.tax_savings = savings
        result.effective_rate = tax_rate

        if deductible_raw > inp.rd_income:
            excess = deductible_raw - inp.rd_income
            result.warnings.append(
                f"Nadwyżka {excess:,.2f} PLN przechodzi na kolejne lata (max 6 lat)"
            )

        if not inp.has_separate_evidence:
            result.warnings.append(
                "⚠️ BRAK wyodrębnionej ewidencji B+R — US może zakwestionować ulgę!"
            )

        if inp.is_rd_center:
            result.recommendations.append(
                "✅ Status CBR: odliczasz 200% kosztów kwalifikowanych!"
            )

        if qualified > 5_000_000:
            result.recommendations.append(
                "⚠️ Koszty B+R > 5M PLN — obowiązek zgłoszenia MDR-3!"
            )

        return result

    # ── IP Box (Art. 30ca PIT) ─────────────────────────────────────────────────

    def calculate_ipbox(
        self, inp: IPBoxInput, tax_form: TaxForm
    ) -> ReliefResult:
        """Calculate IP Box relief (5% tax rate on qualified IP income)."""
        result = ReliefResult(relief_type=ReliefType.IP_BOX)

        if tax_form not in {TaxForm.SCALE, TaxForm.LINEAR}:
            result.warnings.append(
                f"IP Box niedostępny dla {tax_form.value} — tylko skala i liniowy"
            )
            return result

        if not inp.has_qualifying_ip:
            result.warnings.append("IP Box: brak kwalifikowanego IP")
            return result

        qualifying_categories = {
            "PATENT", "UTILITY_MODEL", "INDUSTRIAL_DESIGN",
            "TOPOLOGY", "SOFTWARE", "PLANT_VARIETY", "DRUG_REGISTRATION",
        }
        if inp.ip_category not in qualifying_categories:
            result.warnings.append(
                f"IP Box: kategoria '{inp.ip_category}' nie jest kwalifikowanym IP"
            )
            return result

        if inp.ip_income <= 0:
            result.warnings.append("IP Box: zerowy dochód z IP")
            return result

        # Nexus formula: (qualified_costs × 1.3) / total_costs
        if inp.nexus_total_costs > 0:
            nexus_ratio = min((inp.nexus_qualified_costs * 1.3) / inp.nexus_total_costs, 1.0)
        else:
            nexus_ratio = 1.0

        qualifying_income = inp.ip_income * nexus_ratio
        ipbox_tax = qualifying_income * 0.05

        # Savings vs scale (12%) or linear (19%)
        standard_rate = 0.12 if tax_form == TaxForm.SCALE else 0.19
        standard_tax = qualifying_income * standard_rate
        savings = standard_tax - ipbox_tax

        result.is_eligible = True
        result.qualified_costs = inp.nexus_qualified_costs
        result.deductible_amount = qualifying_income
        result.tax_savings = savings
        result.effective_rate = 0.05

        if nexus_ratio < 0.50:
            result.warnings.append(
                f"Niski wskaźnik Nexus ({nexus_ratio:.1%}) — zwiększ koszty kwalifikowane!"
            )

        if not inp.has_separate_evidence:
            result.warnings.append(
                "⚠️ BRAK wyodrębnionej ewidencji IP Box — US odrzuci ulgę!"
            )

        if not inp.pit_ip_filed:
            result.warnings.append(
                "⚠️ Nie złożono PIT-IP — złóż razem z zeznaniem rocznym!"
            )

        return result

    # ── Thermo-modernization Relief (Art. 26h PIT) ─────────────────────────────

    def calculate_thermo_relief(self, inp: ThermoInput) -> ReliefResult:
        """Calculate thermo-modernization relief (up to 53,000 PLN)."""
        result = ReliefResult(relief_type=ReliefType.THERMO)

        if not inp.owns_property and not inp.is_co_owner:
            result.warnings.append(
                "Termomodernizacja: brak własności/współwłasności budynku"
            )
            return result

        if not inp.has_vat_invoices:
            result.warnings.append(
                "Termomodernizacja: wymagane faktury VAT od czynnego podatnika VAT"
            )
            return result

        if inp.already_deducted_elsewhere:
            result.warnings.append(
                "Termomodernizacja: wydatki już odliczone w innym programie (Czyste Powietrze)!"
            )
            return result

        total_costs = (
            inp.windows_doors_costs + inp.insulation_costs +
            inp.heating_system_costs + inp.solar_pv_costs + inp.ventilation_costs
        )

        # Subtract government subsidy
        net_costs = max(total_costs - inp.government_subsidy, 0)

        if net_costs <= 0:
            result.warnings.append("Termomodernizacja: wszystkie koszty pokryte dotacją")
            return result

        MAX_LIMIT = 53_000
        deductible = min(net_costs, MAX_LIMIT)
        savings = deductible * 0.12  # Assuming 12% tax rate

        result.is_eligible = True
        result.qualified_costs = net_costs
        result.deductible_amount = deductible
        result.tax_savings = savings
        result.effective_rate = 0.12

        if net_costs > MAX_LIMIT:
            excess = net_costs - MAX_LIMIT
            result.warnings.append(
                f"Nadwyżka {excess:,.2f} PLN PRZEPADA — nie przechodzi na kolejne lata!"
            )

        result.recommendations.append(
            "Limit 53 000 PLN jest NA PODATNIKA — małżonkowie mogą odliczyć osobno!"
        )

        return result

    # ── Donation Relief (Art. 26 PIT) ──────────────────────────────────────────

    def calculate_donation_relief(self, inp: DonationInput) -> ReliefResult:
        """Calculate donation relief (6% of income for OPP + church, unlimited for blood)."""
        result = ReliefResult(relief_type=ReliefType.DONATION)

        six_pct_limit = inp.annual_income * 0.06
        opp_church_total = inp.opp_donations + inp.church_donations

        # Blood donations: 130 PLN/liter, NO % limit, NO bank transfer required
        blood_value = inp.blood_liters * 130.0

        # OPP + church: require bank transfer + certificate, capped at 6%
        opp_church_deductible = 0.0
        if opp_church_total > 0:
            if not inp.has_bank_transfer:
                result.warnings.append("Darowizny OPP/kościół: wymagany przelew bankowy!")
            elif not inp.has_opp_certificate:
                result.warnings.append("Darowizny OPP/kościół: wymagane zaświadczenie!")
            else:
                opp_church_deductible = min(opp_church_total, six_pct_limit)
                excess = max(opp_church_total - six_pct_limit, 0)
                if excess > 0:
                    result.warnings.append(
                        f"Nadwyżka OPP+kościół {excess:,.2f} PLN PRZEPADA! Rozłóż darowizny na lata."
                    )

        total_deductible = opp_church_deductible + blood_value
        savings = total_deductible * 0.12

        result.is_eligible = total_deductible > 0
        result.qualified_costs = opp_church_total + blood_value
        result.deductible_amount = total_deductible
        result.tax_savings = savings
        result.effective_rate = 0.12

        if inp.blood_liters > 0:
            result.recommendations.append(
                f"Krwiodawstwo: {inp.blood_liters}L × 130 PLN = {blood_value:,.2f} PLN odliczenia BEZ limitu %!"
            )

        return result

    # ── Tax Loss Harvesting (Art. 9 PIT) ───────────────────────────────────────

    def calculate_loss_harvesting(
        self,
        available_losses: dict[int, float],
        current_year: int,
        current_income: float,
    ) -> dict[str, Any]:
        """Calculate optimal tax loss harvesting strategy."""
        max_deduction_this_year = current_income * 0.50
        total_loss = sum(available_losses.values())

        # Find expiring losses (5-year rule)
        expiring = {
            year: amount
            for year, amount in available_losses.items()
            if current_year - year >= 4 and amount > 0
        }

        # Strategy: deduct oldest first, max 50% of income
        recommended = min(total_loss, max_deduction_this_year)

        return {
            "total_available": total_loss,
            "max_this_year": max_deduction_this_year,
            "recommended_deduction": recommended,
            "expiring_losses": expiring,
            "carry_forward": max(total_loss - recommended, 0),
            "strategy": (
                "ODLICZ MAKSYMALNIE — strata niedługo się przedawnia!"
                if expiring else
                "Rozłóż odliczenie na lata z wyższym dochodem"
            ),
        }

    # ── Cross-Relief Optimizer ─────────────────────────────────────────────────

    def optimize_cross_reliefs(
        self,
        relief_results: list[ReliefResult],
        annual_income: float,
        tax_form: TaxForm,
    ) -> CrossReliefResult:
        """Optimize combination of multiple tax reliefs."""
        result = CrossReliefResult()

        # Filter available reliefs for this tax form
        available_set = FORM_RELIEF_AVAILABILITY.get(tax_form, set())
        eligible = [r for r in relief_results if r.is_eligible and r.relief_type in available_set]

        result.available_reliefs = [r.relief_type for r in eligible]

        # Check compatibility
        for i, r1 in enumerate(eligible):
            for r2 in eligible[i + 1:]:
                compat = RELIEF_COMPATIBILITY.get(
                    (r1.relief_type.value.upper(), r2.relief_type.value.upper())
                )
                if compat == "SEPARATE":
                    result.separate_income_pairs.append(
                        f"{r1.relief_type.value} + {r2.relief_type.value}"
                    )
                elif compat is False:
                    result.incompatible_pairs.append(
                        f"{r1.relief_type.value} + {r2.relief_type.value}"
                    )

        # Total savings
        result.total_estimated_savings = sum(r.tax_savings for r in eligible)

        # Optimal order
        result.optimal_order = [
            o for o in RELIEF_OPTIMAL_ORDER
            if any(r.relief_type.value.upper() == o for r in eligible)
        ]

        # Best combination
        result.best_combination = [
            f"{r.relief_type.value} ({r.tax_savings:,.0f} PLN)" for r in eligible
        ]

        # Strategy notes
        if tax_form == TaxForm.SCALE and annual_income > 120_000:
            result.strategy_notes.append(
                "Jesteś w II progu (32%) — maksymalizuj B+R i IP Box!"
            )
        if any(r.relief_type == ReliefType.RD for r in eligible) and \
           any(r.relief_type == ReliefType.IP_BOX for r in eligible):
            result.strategy_notes.append(
                "B+R + IP Box: ROZDZIEL dochody! IP Box (5%) od IP, B+R od non-IP."
            )

        return result
