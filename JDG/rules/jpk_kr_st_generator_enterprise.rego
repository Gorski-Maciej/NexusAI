# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE JPK_KR/ST GENERATOR (Innovation 8.20 / LUKA-C2, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Metadata documentation (kept as ordinary comments; no executable annotation).
# title: JDG Enterprise JPK_KR/ST Generator — Księgi Rachunkowe i Środki Trwałe
# description: |
#   ENTERPRISE v7.0 — Generator JPK_KR (Księgi Rachunkowe) i JPK_ST (Środki Trwałe)
#   dla JDG prowadzącej pełną księgowość (przychody >2 mln EUR rocznie).
#   Wypełnia lukę C2 z raportu P18: wcześniej tylko modele hipotetyczne CIT,
#   teraz pełna obsługa JPK na żądanie wg art. 193a OrdPU.
#
#   KLUCZOWE FUNKCJE:
#   - JPK_KR: struktura ksiąg rachunkowych (dziennik, konta, obroty, salda)
#   - JPK_ST: ewidencja środków trwałych i wartości niematerialnych
#   - Generowanie na żądanie US (termin 14 dni)
#   - Walidacja spójności JPK_KR z JPK_V7 i CIT-8/PIT-36L
#   - Powiązanie z modułem amortyzacji (deprecjacja)
#
#   v7.0 UWARUNKOWANIE (P18): JDG na pełnej księgowości (>2 mln EUR) —
#   realny obowiązek JPK_KR/ST na żądanie. Dla JDG na PKPiR moduł nieaktywny.
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 193a OrdPU; Art. 22d-22n PIT
# package: jdg.jpk_kr_st
# deprecated: false
# priority_range: 2210-2239
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.jpk_kr_st

import data.jdg.helpers
import data.jdg.thresholds
import future.keywords.if
import future.keywords.in

consistency_marker_value(consistent) = "✅" {
    consistent
} else = "⚠️" {
    not consistent
}

kr_applicable_value(full_accounting, revenue_eur, threshold_eur) = true {
    full_accounting
} else = true {
    revenue_eur > threshold_eur
} else = false {
    not full_accounting
    revenue_eur <= threshold_eur
}

eligibility_routing_value(applicable) = "TRIAGE_QUEUE" if { applicable } else = ""
eligibility_reason_value(applicable, revenue_eur) = reason if {
    applicable
    reason := sprintf("JPK_KR: JDG na pełnej księgowości (%.0f EUR przychodu) — JPK_KR/ST na żądanie US.", [revenue_eur])
} else = "JDG na PKPiR — JPK_KR/ST nie dotyczy (wystarczy JPK_PKPIR)."

kr_routing_value(balanced, journal_count) = "BLOCK_AND_ALERT" if { not balanced } else = "TRIAGE_QUEUE" if { balanced; journal_count == 0 } else = ""
kr_reason_value(balanced) = "JPK_KR NIEZBILANSOWANY! Sprawdź obroty i salda — suma debet != kredyt." if { not balanced } else = ""

st_routing_value(assets_count) = "TRIAGE_QUEUE" if { assets_count > 0 } else = ""
st_reason_value(assets_count, net_book_value) = reason if {
    assets_count > 0
    reason := sprintf("JPK_ST: %d środków trwałych — wartość netto %.0f PLN.", [assets_count, net_book_value])
} else = ""

cross_routing_value(consistent, discrepancy) = "BLOCK_AND_ALERT" if { not consistent; discrepancy > object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_kr_discrepancy_alert_pln", 10000) } else = "TRIAGE_QUEUE" if { not consistent; discrepancy <= object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_kr_discrepancy_alert_pln", 10000) } else = ""
cross_reason_value(consistent, discrepancy) = reason if {
    not consistent
    reason := sprintf("ROZBIEŻNOŚĆ JPK_KR vs JPK_V7: %.0f PLN — uzgodnij księgi z deklaracjami VAT!", [discrepancy])
} else = ""

default decide := {
    "matched": false, "rule_id": "jdg.jpk_kr_st.no_match",
    "package": "jdg.jpk_kr_st", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# JKR-2210: JPK_KR ELIGIBILITY — Czy JDG podlega JPK_KR na żądanie?
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.jpk_kr_st.kr_eligibility_check",
    "package": "jdg.jpk_kr_st",
    "priority": 2210,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_kr_applicable": kr_applicable,
    "jpk_kr_full_accounting": full_accounting,
    "jpk_kr_revenue_eur": revenue_eur,
    "jpk_kr_threshold_eur": threshold_eur,
    "_routing": elig_routing,
    "_routing_reason": elig_reason,
    "_legal_basis": "Art. 193a OrdPU; Art. 2 ust. 2 UoR (pełna księgowość >2M EUR)",
    "_warnings": build_eligibility_warnings(kr_applicable, full_accounting, revenue_eur, threshold_eur)
} if {
    input.jpk_kr_eligibility_check == true
    full_accounting := object.get(input.jdg_entrepreneur, "uses_full_accounting", false)
    revenue_eur := object.get(input.jdg_entrepreneur, "annual_revenue_eur", 0)
    threshold_eur := object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "jpk_kr_threshold_eur", 2000000)
    kr_applicable := kr_applicable_value(full_accounting, revenue_eur, threshold_eur)
    elig_routing := eligibility_routing_value(kr_applicable)
    elig_reason := eligibility_reason_value(kr_applicable, revenue_eur)
}

build_eligibility_warnings(applicable, full, eur, threshold) = warnings {
    applicable
    warnings := [
        sprintf("📊 JPK_KR ELIGIBILITY: TAK — pełna księgowość (%.0f EUR > %.0f EUR)", [eur, threshold]),
        "   JPK_KR (Księgi Rachunkowe) — struktura: dziennik, konta księgowe, obroty, salda.",
        "   JPK_ST (Środki Trwałe) — ewidencja amortyzacji, ulepszeń, odpisów.",
        "   ⚠️ OBOWIĄZEK: na żądanie US — termin 14 dni od doręczenia żądania.",
    ]
} else = [
    "📊 JPK_KR ELIGIBILITY: NIE — PKPiR wystarczająca.",
    "   JPK_PKPIR (16 kolumn) zamiast JPK_KR/ST. Moduł nieaktywny.",
]

# ═══════════════════════════════════════════════════════════════════════════════
# JKR-2215: JPK_KR STRUCTURE GENERATOR — Generowanie struktury JPK_KR
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.jpk_kr_st.kr_structure_generator",
    "package": "jdg.jpk_kr_st",
    "priority": 2215,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_kr_period": period,
    "jpk_kr_journal_entries": journal_count,
    "jpk_kr_accounts_count": accounts_count,
    "jpk_kr_opening_balance_total": opening_balance,
    "jpk_kr_closing_balance_total": closing_balance,
    "jpk_kr_turnover_debit": turnover_debit,
    "jpk_kr_turnover_credit": turnover_credit,
    "jpk_kr_balanced": is_balanced,
    "_routing": kr_routing,
    "_routing_reason": kr_reason,
    "_legal_basis": "Art. 193a OrdPU; Art. 13-24 UoR; Rozporządzenie MF JPK_KR",
    "_warnings": build_kr_warnings(period, journal_count, accounts_count, opening_balance, closing_balance, turnover_debit, turnover_credit, is_balanced)
} if {
    input.jpk_kr_generate == true
    period := object.get(input, "jpk_kr_period", "2026-07")
    journal_count := object.get(input, "jpk_kr_journal_entries", 0)
    accounts_count := object.get(input, "jpk_kr_unique_accounts", 0)
    opening_balance := object.get(input, "jpk_kr_opening_balance", 0)
    closing_balance := object.get(input, "jpk_kr_closing_balance", 0)
    turnover_debit := object.get(input, "jpk_kr_turnover_debit_total", 0)
    turnover_credit := object.get(input, "jpk_kr_turnover_credit_total", 0)
    is_balanced := abs(opening_balance + turnover_debit - turnover_credit - closing_balance) < 1

    kr_routing := kr_routing_value(is_balanced, journal_count)
    kr_reason := kr_reason_value(is_balanced)
}

balance_line_value(balanced) = ["   ✅ BILANS ZGODNY"] if { balanced } else = ["   🚨 BILANS NIEZGODNY — sprawdź księgowania!"]

build_kr_warnings(period, journal, accounts, ob, cb, dt, ct, balanced) = warnings {
    lines := [
        sprintf("📊 JPK_KR — OKRES %s", [period]),
        sprintf("   Zapisów w dzienniku: %d | Kont: %d", [journal, accounts]),
        sprintf("   Bilans otwarcia: %.0f PLN | Zamknięcia: %.0f PLN", [ob, cb]),
        sprintf("   Obroty DT: %.0f PLN | CT: %.0f PLN", [dt, ct]),
    ]
    balance_line := balance_line_value(balanced)
    warnings := array.concat(lines, balance_line)
}

# ═══════════════════════════════════════════════════════════════════════════════
# JKR-2220: JPK_ST STRUCTURE GENERATOR — Generowanie struktury JPK_ST
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.jpk_kr_st.st_structure_generator",
    "package": "jdg.jpk_kr_st",
    "priority": 2220,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_st_period": period,
    "jpk_st_assets_count": assets_count,
    "jpk_st_initial_value_total": initial_value,
    "jpk_st_depreciation_total": depreciation_total,
    "jpk_st_improvements_total": improvements_total,
    "jpk_st_net_book_value": net_book_value,
    "jpk_st_new_assets_period": new_assets,
    "jpk_st_disposals_period": disposals,
    "_routing": st_routing,
    "_routing_reason": st_reason,
    "_legal_basis": "Art. 193a OrdPU; Art. 22d-22n PIT; Rozporządzenie MF JPK_ST",
    "_warnings": build_st_warnings(period, assets_count, initial_value, depreciation_total, improvements_total, net_book_value, new_assets, disposals)
} if {
    input.jpk_st_generate == true
    period := object.get(input, "jpk_st_period", "2026-07")
    assets_count := object.get(input, "jpk_st_assets_count", 0)
    initial_value := object.get(input, "jpk_st_initial_value_total", 0)
    depreciation_total := object.get(input, "jpk_st_accumulated_depreciation", 0)
    improvements_total := object.get(input, "jpk_st_improvements_period", 0)
    net_book_value := initial_value + improvements_total - depreciation_total
    new_assets := object.get(input, "jpk_st_new_assets_period", 0)
    disposals := object.get(input, "jpk_st_disposals_period", 0)

    st_routing := st_routing_value(assets_count)
    st_reason := st_reason_value(assets_count, net_book_value)
}

build_st_warnings(period, count, init, depr, impr, nbv, new_ast, disp) = warnings {
    warnings := [
        sprintf("🏗️ JPK_ST — OKRES %s", [period]),
        sprintf("   Środków trwałych: %d (nowe: %d, zbyte: %d)", [count, new_ast, disp]),
        sprintf("   Wartość początkowa: %.0f PLN", [init]),
        sprintf("   Ulepszenia: %.0f PLN | Amortyzacja: %.0f PLN", [impr, depr]),
        sprintf("   Wartość netto: %.0f PLN", [nbv]),
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# JKR-2225: JPK_KR vs JPK_V7 CROSS-VALIDATION — Spójność ksiąg z JPK_VAT
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.jpk_kr_st.kr_vs_v7_cross_validation",
    "package": "jdg.jpk_kr_st",
    "priority": 2225,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_kr_revenue_total": kr_revenue,
    "jpk_v7_sales_net_total": v7_sales,
    "jpk_kr_vs_v7_discrepancy": discrepancy,
    "jpk_kr_vs_v7_consistent": is_consistent,
    "_routing": cross_routing,
    "_routing_reason": cross_reason,
    "_legal_basis": "Art. 109 ust. 3d VAT; Art. 193 OrdPU",
    "_warnings": [
        sprintf("🔗 JPK_KR ↔ JPK_V7 CROSS-VALIDATION", []),
        sprintf("   JPK_KR przychody: %.0f PLN", [kr_revenue]),
        sprintf("   JPK_V7 sprzedaż netto: %.0f PLN", [v7_sales]),
        sprintf("   Rozbieżność: %.0f PLN %s", [discrepancy, consistency_marker_value(is_consistent)]),
    ]
} if {
    input.jpk_kr_v7_cross_validate == true
    kr_revenue := object.get(input, "jpk_kr_revenue_total", 0)
    v7_sales := object.get(input, "jpk_v7_sales_net_total", 0)
    discrepancy := abs(kr_revenue - v7_sales)

    tolerance := max([kr_revenue, v7_sales, 1]) * 0.01
    is_consistent := discrepancy <= tolerance

    cross_routing := cross_routing_value(is_consistent, discrepancy)
    cross_reason := cross_reason_value(is_consistent, discrepancy)
}
