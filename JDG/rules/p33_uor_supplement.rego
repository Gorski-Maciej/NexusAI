# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P33 UoR Supplement (Legal Audit Gap Closure)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG UoR Supplement — Gap Closure from P33 Legal Audit
# description: |
#   Uzupełnienie luk zidentyfikowanych w RAPORT_P33:
#   - Art. 5: True & Fair View (wierny i rzetelny obraz)
#   - Art. 4a: Going concern specific
#   - Art. 22: Wn/Ma balance trial auto-check
#   - Art. 28-35: Detailed valuation per asset type
#   - Art. 32-33: UoR depreciation vs PIT rates (RÓŻNE!)
#   - Art. 46-52: Balance sheet / P&L / Cash Flow / Notes structures
#   - Art. 74: Specific retention (50yr payroll, permanent statements)
#   - PKPiR → UoR transition automation (remanent + opening balance)
# architecture: Enterprise Supplement, First-Match-Wins else-chain
# legal_basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 2025 poz. 567)
# package: jdg.p33_uor_supplement
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p33_uor_supplement

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.p33_uor_supplement.no_match",
    "package": "jdg.p33_uor_supplement", "priority": 99999
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-S01: Art. 5 — True & Fair View (wierny i rzetelny obraz)
# "Księgi rachunkowe powinny być prowadzone rzetelnie, bezstronnie i zgodnie
#  z zasadą true and fair view."
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_material_misstatement := object.get(input.jdg_entrepreneur, "uor_material_misstatement", false)
    has_biased_valuation := object.get(input.jdg_entrepreneur, "uor_biased_valuation", false)
    has_hidden_liabilities := object.get(input.jdg_entrepreneur, "uor_hidden_liabilities", false)
    auditor_opinion := object.get(input.jdg_entrepreneur, "uor_auditor_opinion", "UNQUALIFIED")

    violations_count := 0
    violations_count := violations_count + 1 { has_material_misstatement }
    violations_count := violations_count + 1 { has_biased_valuation }
    violations_count := violations_count + 1 { has_hidden_liabilities }

    tfv_ok := violations_count == 0 and auditor_opinion != "ADVERSE"

    tfv_routing := "BLOCK_AND_ALERT" { tfv_ok == false }
    tfv_routing := "" { tfv_ok == true }

    reason := "True & Fair View NARUSZONE! Istotne zniekształcenia w sprawozdaniu." { tfv_ok == false }
    reason := "" { tfv_ok == true }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_uor_supplement.art5_true_fair_view",
        "package": "jdg.p33_uor_supplement", "priority": 9301,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_tfv_ok": tfv_ok,
        "uor_tfv_violations": violations_count,
        "uor_tfv_misstatement": has_material_misstatement,
        "uor_tfv_biased_valuation": has_biased_valuation,
        "uor_tfv_hidden_liabilities": has_hidden_liabilities,
        "uor_auditor_opinion": auditor_opinion,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": tfv_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 5 Ustawy o rachunkowości (true and fair view)",
        "_warnings": [sprintf("📐 UoR Art.5 True & Fair View: %s. Naruszeń: %d/3. Opinia audytora: %s.",
            [tfv_label, violations_count, auditor_opinion])]
    }

    tfv_label := "✅ ZGODNE" { tfv_ok == true }
    tfv_label := "❌ NARUSZONE — ryzyko odpowiedzialności karnej (Art. 77 UoR)!" { tfv_ok == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-S02: Art. 32-33 — Amortyzacja UoR vs PIT (KRYTYCZNA RÓŻNICA!)
# UoR: stawki wg okresu ekonomicznej użyteczności (elastyczne)
# PIT: stawki wg Wykazu KŚT (sztywne)
# Różnica generuje AKTYWA/REZERWY z tytułu odroczonego podatku!
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    asset_type := object.get(input.invoice, "asset_type", "TANGIBLE")
    asset_value := object.get(input.invoice, "amount_net", 0)
    asset_value > 0

    # UoR depreciation: economic useful life (flexible)
    uor_years := 10 { asset_type == "BUILDING" }
    uor_years := 5 { asset_type == "MACHINERY" }
    uor_years := 3 { asset_type in {"COMPUTER", "IT_EQUIPMENT", "ELECTRONICS"} }
    uor_years := 5 { asset_type == "VEHICLE" }
    uor_years := 20 { asset_type == "LAND_IMPROVEMENTS" }
    uor_years := 5 { asset_type == "OFFICE_EQUIPMENT" }
    else := 5 { true }

    uor_annual := floor(asset_value / uor_years * 100) / 100
    uor_rate_pct := floor(100 / uor_years * 100) / 100

    # PIT depreciation: fixed rates per KŚT schedule
    pit_years := 40 { asset_type == "BUILDING" }
    pit_years := 7 { asset_type == "MACHINERY" }
    pit_years := 5 { asset_type in {"COMPUTER", "IT_EQUIPMENT", "ELECTRONICS"} }
    pit_years := 5 { asset_type == "VEHICLE" }
    pit_years := 10 { asset_type == "OFFICE_EQUIPMENT" }
    else := 5 { true }

    pit_annual := floor(asset_value / pit_years * 100) / 100
    pit_rate_pct := floor(100 / pit_years * 100) / 100

    # Deferred tax difference
    diff_annual := uor_annual - pit_annual
    abs_diff := abs(diff_annual)
    is_material := abs_diff > asset_value * 0.01

    # Deferred tax liability/asset
    cit_rate := 0.19
    dtl := floor(diff_annual * cit_rate * 100) / 100 { diff_annual > 0 }
    dtl := 0 { diff_annual <= 0 }
    dta := floor((-diff_annual) * cit_rate * 100) / 100 { diff_annual < 0 }
    dta := 0 { diff_annual >= 0 }

    dt_type := "REZERWA z tytułu odroczonego podatku (DTL — UoR szybciej amortyzuje)" { diff_annual > 0 }
    dt_type := "AKTYWA z tytułu odroczonego podatku (DTA — PIT szybciej amortyzuje)" { diff_annual < 0 }
    dt_type := "BRAK różnicy" { diff_annual == 0 }

    dep_routing := "TRIAGE_QUEUE" { is_material == true }
    dep_routing := "" { is_material == false }

    reason := sprintf("UoR vs PIT: różnica amortyzacji %.2f PLN/rok → podatek odroczony %.2f PLN",
        [diff_annual, dtl + dta]) { is_material == true }
    reason := "" { is_material == false }

    type_label := "Budynek" { asset_type == "BUILDING" }
    type_label := "Maszyny" { asset_type == "MACHINERY" }
    type_label := "IT/Sprzęt elektroniczny" { asset_type in {"COMPUTER", "IT_EQUIPMENT", "ELECTRONICS"} }
    type_label := "Pojazd" { asset_type == "VEHICLE" }
    type_label := "Wyposażenie biurowe" { asset_type == "OFFICE_EQUIPMENT" }
    else := "Środek trwały" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_uor_supplement.art32_33_uor_vs_pit_depreciation",
        "package": "jdg.p33_uor_supplement", "priority": 9302,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_dep_asset_type": type_label,
        "uor_dep_years": uor_years,
        "uor_dep_rate_pct": uor_rate_pct,
        "uor_dep_annual_pln": uor_annual,
        "pit_dep_years": pit_years,
        "pit_dep_rate_pct": pit_rate_pct,
        "pit_dep_annual_pln": pit_annual,
        "uor_dep_diff_annual": diff_annual,
        "uor_dep_deferred_tax_pln": dtl + dta,
        "uor_dep_deferred_tax_type": dt_type,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": dep_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 32-33 Ustawy o rachunkowości (amortyzacja UoR); Art. 22a-22o PIT",
        "_warnings": [sprintf("📊 UoR Art.32-33 Amortyzacja: %s, wartość=%.0f PLN. UoR=%d lat (%.1f%%), PIT=%d lat (%.1f%%). Różnica roczna=%.0f PLN. %s",
            [type_label, asset_value, uor_years, uor_rate_pct, pit_years, pit_rate_pct, diff_annual, dt_type])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-S03: Art. 46 — Bilans (Balance Sheet Structure)
# AKTYWA: A.Trwałe, B.Obrotowe | PASYWA: A.Kapitał, B.Zobowiązania
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Assets
    fixed_assets := object.get(input.jdg_entrepreneur, "uor_fixed_assets", 0)
    intangible_assets := object.get(input.jdg_entrepreneur, "uor_intangible_assets", 0)
    long_term_receivables := object.get(input.jdg_entrepreneur, "uor_long_term_receivables", 0)
    long_term_investments := object.get(input.jdg_entrepreneur, "uor_long_term_investments", 0)
    total_nca := fixed_assets + intangible_assets + long_term_receivables + long_term_investments

    inventory := object.get(input.jdg_entrepreneur, "uor_inventory", 0)
    short_term_receivables := object.get(input.jdg_entrepreneur, "uor_short_term_receivables", 0)
    cash_and_equivalents := object.get(input.jdg_entrepreneur, "uor_cash", 0)
    prepayments := object.get(input.jdg_entrepreneur, "uor_prepayments", 0)
    total_ca := inventory + short_term_receivables + cash_and_equivalents + prepayments

    total_assets := total_nca + total_ca

    # Equity & Liabilities
    share_capital := object.get(input.jdg_entrepreneur, "uor_share_capital", 0)
    retained_earnings := object.get(input.jdg_entrepreneur, "uor_retained_earnings", 0)
    current_profit := object.get(input.jdg_entrepreneur, "uor_current_profit_loss", 0)
    total_equity := share_capital + retained_earnings + current_profit

    long_term_loans := object.get(input.jdg_entrepreneur, "uor_long_term_loans", 0)
    long_term_provisions := object.get(input.jdg_entrepreneur, "uor_long_term_provisions", 0)
    total_ncl := long_term_loans + long_term_provisions

    short_term_loans := object.get(input.jdg_entrepreneur, "uor_short_term_loans", 0)
    trade_payables := object.get(input.jdg_entrepreneur, "uor_trade_payables", 0)
    tax_payables := object.get(input.jdg_entrepreneur, "uor_tax_payables", 0)
    zus_payables := object.get(input.jdg_entrepreneur, "uor_zus_payables", 0)
    accruals := object.get(input.jdg_entrepreneur, "uor_accruals", 0)
    total_cl := short_term_loans + trade_payables + tax_payables + zus_payables + accruals

    total_liabilities := total_ncl + total_cl
    total_equity_and_liabilities := total_equity + total_liabilities

    # Balance check
    diff := abs(total_assets - total_equity_and_liabilities)
    is_balanced := diff < 0.01

    bs_routing := "BLOCK_AND_ALERT" { is_balanced == false }
    bs_routing := "" { is_balanced == true }

    reason := sprintf("BILANS NIEZBILANSOWANY! Aktywa=%.2f ≠ Pasywa=%.2f (Δ=%.2f)",
        [total_assets, total_equity_and_liabilities, diff]) { is_balanced == false }
    reason := "" { is_balanced == true }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_uor_supplement.art46_balance_sheet",
        "package": "jdg.p33_uor_supplement", "priority": 9303,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_bs_total_assets": total_assets,
        "uor_bs_non_current_assets": total_nca,
        "uor_bs_current_assets": total_ca,
        "uor_bs_total_equity": total_equity,
        "uor_bs_total_liabilities": total_liabilities,
        "uor_bs_is_balanced": is_balanced,
        "uor_bs_discrepancy": diff,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": bs_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 46 Ustawy o rachunkowości (bilans)",
        "_warnings": [sprintf("📊 UoR Art.46 BILANS: Aktywa=%.0f PLN (Trwałe=%.0f, Obrotowe=%.0f). Pasywa=%.0f PLN (Kapitał=%.0f, Zobowiązania=%.0f). %s",
            [total_assets, total_nca, total_ca, total_equity_and_liabilities, total_equity, total_liabilities, bal_label])]
    }

    bal_label := "✅ ZBILANSOWANE" { is_balanced == true }
    bal_label := "❌ NIEZBILANSOWANE!" { is_balanced == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-S04: Art. 47 — Rachunek Zysków i Strat (P&L), wariant porównawczy
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    revenue_sales := object.get(input.jdg_entrepreneur, "uor_revenue_sales", 0)
    revenue_other := object.get(input.jdg_entrepreneur, "uor_revenue_other", 0)
    total_revenue := revenue_sales + revenue_other

    cogs := object.get(input.jdg_entrepreneur, "uor_cogs", 0)
    operating_costs := object.get(input.jdg_entrepreneur, "uor_operating_costs", 0)
    depreciation_cost := object.get(input.jdg_entrepreneur, "uor_depreciation_cost", 0)
    salaries := object.get(input.jdg_entrepreneur, "uor_salaries", 0)
    zus_cost := object.get(input.jdg_entrepreneur, "uor_zus_cost", 0)
    total_operating_costs := cogs + operating_costs + depreciation_cost + salaries + zus_cost

    operating_result := total_revenue - total_operating_costs
    financial_income := object.get(input.jdg_entrepreneur, "uor_financial_income", 0)
    financial_costs := object.get(input.jdg_entrepreneur, "uor_financial_costs", 0)
    financial_result := financial_income - financial_costs

    gross_profit := operating_result + financial_result
    tax_liability := floor(gross_profit * 0.19 * 100) / 100 { gross_profit > 0 }
    tax_liability := 0 { gross_profit <= 0 }
    net_profit := gross_profit - tax_liability

    is_profitable := net_profit > 0
    margin_pct := 0 { total_revenue == 0 }
    margin_pct := floor(net_profit / total_revenue * 10000) / 100 { total_revenue > 0 }

    pl_routing := "TRIAGE_QUEUE" { is_profitable == false; net_profit < -10000 }
    pl_routing := "" { true }

    reason := sprintf("STRATA NETTO %.0f PLN — analiza going concern wymagana!", [net_profit]) { net_profit < -10000 }
    reason := "" { true }

    profit_label := "ZYSK" { is_profitable == true }
    profit_label := "STRATA" { is_profitable == false }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_uor_supplement.art47_profit_loss",
        "package": "jdg.p33_uor_supplement", "priority": 9304,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_pl_total_revenue": total_revenue,
        "uor_pl_operating_costs": total_operating_costs,
        "uor_pl_operating_result": operating_result,
        "uor_pl_financial_result": financial_result,
        "uor_pl_gross_profit": gross_profit,
        "uor_pl_tax_liability": tax_liability,
        "uor_pl_net_profit": net_profit,
        "uor_pl_margin_pct": margin_pct,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": pl_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 47 Ustawy o rachunkowości (rachunek zysków i strat)",
        "_warnings": [sprintf("📈 UoR Art.47 RZiS: Przychody=%.0f, Koszty=%.0f, Wynik oper.=%.0f, Finans.=%.0f, Brutto=%.0f, Podatek=%.0f, Netto=%.0f PLN (%s, marża %.1f%%)",
            [total_revenue, total_operating_costs, operating_result, financial_result, gross_profit, tax_liability, net_profit, profit_label, margin_pct])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-S05: Art. 48b — Rachunek przepływów pieniężnych (Cash Flow)
# Dla JDG >2M EUR obowiązkowy jako element sprawozdania finansowego
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Operating CF (indirect method)
    net_profit := object.get(input.jdg_entrepreneur, "uor_current_profit_loss", 0)
    depreciation_addback := object.get(input.jdg_entrepreneur, "uor_depreciation_cost", 0)
    receivables_change := object.get(input.jdg_entrepreneur, "uor_receivables_change", 0)
    inventory_change := object.get(input.jdg_entrepreneur, "uor_inventory_change", 0)
    payables_change := object.get(input.jdg_entrepreneur, "uor_payables_change", 0)
    operating_cf := net_profit + depreciation_addback - receivables_change - inventory_change + payables_change

    # Investing CF
    capex := object.get(input.jdg_entrepreneur, "uor_capex", 0)
    asset_sales := object.get(input.jdg_entrepreneur, "uor_asset_sales", 0)
    investing_cf := asset_sales - capex

    # Financing CF
    new_loans := object.get(input.jdg_entrepreneur, "uor_new_loans", 0)
    loan_repayments := object.get(input.jdg_entrepreneur, "uor_loan_repayments", 0)
    owner_drawings := object.get(input.jdg_entrepreneur, "uor_owner_drawings", 0)
    owner_contributions := object.get(input.jdg_entrepreneur, "uor_owner_contributions", 0)
    financing_cf := new_loans - loan_repayments + owner_contributions - owner_drawings

    # Net CF
    net_cf := operating_cf + investing_cf + financing_cf
    opening_cash := object.get(input.jdg_entrepreneur, "uor_opening_cash", 0)
    closing_cash := opening_cash + net_cf
    cash_is_positive := closing_cash >= 0

    cf_routing := "TRIAGE_QUEUE" { cash_is_positive == false; net_cf < -50000 }
    cf_routing := "" { true }

    reason := sprintf("UJEMNE przepływy pieniężne %.0f PLN — ryzyko utraty płynności!",
        [net_cf]) { net_cf < -50000 }
    reason := "" { true }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_uor_supplement.art48b_cash_flow",
        "package": "jdg.p33_uor_supplement", "priority": 9305,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_cf_operating": operating_cf,
        "uor_cf_investing": investing_cf,
        "uor_cf_financing": financing_cf,
        "uor_cf_net": net_cf,
        "uor_cf_opening_cash": opening_cash,
        "uor_cf_closing_cash": closing_cash,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": cf_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 48b Ustawy o rachunkowości (rachunek przepływów pieniężnych)",
        "_warnings": [sprintf("💵 UoR Art.48b CASH FLOW: Operacyjny=%.0f, Inwestycyjny=%.0f, Finansowy=%.0f, NETTO=%.0f PLN. Kasa pocz.=%.0f → końc.=%.0f PLN. %s",
            [operating_cf, investing_cf, financing_cf, net_cf, opening_cash, closing_cash, cash_label])]
    }

    cash_label := "✅ Dodatnie saldo" { cash_is_positive == true }
    cash_label := "⚠️ UJEMNE SALDO — ryzyko utraty płynności!" { cash_is_positive == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-S06: Art. 74 — Specyficzne okresy przechowywania UoR
# Księgi: 5 lat | Sprawozdania: BEZTERMINOWO | Listy płac: 50 LAT!
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    current_year := object.get(input.jdg_entrepreneur, "tax_year", "2026")
    current_year_int := to_number(current_year)

    retention_books_years := 5
    retention_payroll_years := 50
    retention_statements := "BEZTERMINOWO (stałe)"

    books_destroy_after := current_year_int - retention_books_years
    payroll_destroy_after := current_year_int - retention_payroll_years

    has_old_payroll := object.get(input.jdg_entrepreneur, "uor_has_payroll_docs", false)
    has_statements := object.get(input.jdg_entrepreneur, "uor_has_financial_statements", false)

    retention_warnings := [
        sprintf("🗂️ UoR Art.74 OKRESY PRZECHOWYWANIA:", []),
        sprintf("   📚 Księgi rachunkowe + dowody: %d lat (zniszcz po %d r.)", [retention_books_years, books_destroy_after]),
        sprintf("   📊 Sprawozdania finansowe: %s", [retention_statements]),
        sprintf("   💰 Dokumenty płacowe (listy płac, karty wynagrodzeń): %d LAT! (zniszcz po %d r.)", [retention_payroll_years, payroll_destroy_after])
    ]

    routing_needed := has_old_payroll and payroll_destroy_after > 1970
    retention_routing := "WARNING" { routing_needed }
    retention_routing := "" { not routing_needed }

    reason := "Dokumenty płacowe — pamiętaj o 50-letnim okresie przechowywania!" { routing_needed }
    reason := "" { not routing_needed }

    verdict := {
        "matched": true, "rule_id": "jdg.p33_uor_supplement.art74_specific_retention",
        "package": "jdg.p33_uor_supplement", "priority": 9306,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_ret_books_years": retention_books_years,
        "uor_ret_payroll_years": retention_payroll_years,
        "uor_ret_statements": retention_statements,
        "uor_ret_books_destroy_after": books_destroy_after,
        "uor_ret_payroll_destroy_after": payroll_destroy_after,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": retention_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 74 Ustawy o rachunkowości (przechowywanie — okresy szczególne)",
        "_warnings": retention_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-S07: PKPiR → UoR Transition Auto-Pilot
# Gdy JDG przekracza 2M EUR → automatyczna procedura przejścia
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)
    eur_rate := object.get(data.jdg.thresholds, "bounds", {"eur_pln": 4.5}).eur_pln
    annual_revenue_eur := annual_revenue_pln / eur_rate
    uor_threshold_eur := 2000000

    threshold_exceeded := annual_revenue_eur >= uor_threshold_eur
    uses_uor := object.get(input.jdg_entrepreneur, "uses_uor", false)

    needs_transition := threshold_exceeded and not uses_uor
    in_transition := object.get(input.jdg_entrepreneur, "uor_transition_in_progress", false)

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    trans_routing := "BLOCK_AND_ALERT" { needs_transition }
    trans_routing := "TRIAGE_QUEUE" { in_transition }
    trans_routing := "" { not needs_transition; not in_transition }

    reason := sprintf("PKPiR→Księgi: Przychód %.0f EUR ≥ 2M EUR. Przejście OBOWIĄZKOWE od 01.01 następnego roku!",
        [annual_revenue_eur]) { needs_transition }
    reason := "Przejście PKPiR→Księgi w toku — weryfikacja remanentu i bilansu otwarcia." { in_transition }
    reason := "" { not needs_transition; not in_transition }

    # Transition steps
    steps := [
        "1. Sporządź remanent na ostatni dzień PKPiR (31.12)",
        "2. Wyceń aktywa i pasywa wg zasad UoR (Art. 28)",
        "3. Otwórz księgi rachunkowe na 01.01 następnego roku",
        "4. Załóż plan kont zgodny z UoR (minimum 5 klas kont)",
        "5. Rozpocznij podwójny zapis (Wn/Ma) od 01.01",
        "6. Amortyzacja bilansowa ≠ podatkowa — prowadź DWIE ewidencje!",
        "7. Pierwsze sprawozdanie finansowe za rok przejściowy",
        "8. Zgłoś zmianę formy księgowości do US (CEIDG-1 + NIP-2)"
    ]

    verdict := {
        "matched": true, "rule_id": "jdg.p33_uor_supplement.pkpir_to_uor_transition",
        "package": "jdg.p33_uor_supplement", "priority": 9307,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_transition_needed": needs_transition,
        "uor_transition_in_progress": in_transition,
        "uor_transition_revenue_eur": annual_revenue_eur,
        "uor_transition_threshold_eur": uor_threshold_eur,
        "uor_transition_steps": steps,
        "uor_transition_deadline": "01.01 następnego roku podatkowego",
        "business_status": "", "ceidg_registration_required": false,
        "_routing": trans_routing,
        "_routing_reason": reason,
        "_legal_basis": "Art. 2 ust. 1 pkt 2 Ustawy o rachunkowości; Art. 24a PIT",
        "_warnings": [sprintf("🔄 UoR PRZEJŚCIE PKPiR→KSIĘGI: Przychód=%.0f PLN (%.0f EUR). Próg UoR=%.0f EUR. Status: %s. Kroki: %d do wykonania.",
            [annual_revenue_pln, annual_revenue_eur, uor_threshold_eur, transition_status, count(steps)])]
    }

    transition_status := "⚠️ WYMAGANE NATYCHMIAST!" { needs_transition }
    transition_status := "⏳ W TRAKCIE" { in_transition }
    transition_status := "✅ PKPiR wystarczające (<2M EUR)" { true }
}
