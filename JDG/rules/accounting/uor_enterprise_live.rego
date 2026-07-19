# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — UoR ENTERPRISE LIVE (Strategic Initiative S18)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG UoR Enterprise Live — Active Accounting Law Validation
# description: |
#   ENTERPRISE v6.0 — "Ożywienie" warstwy Ustawy o Rachunkowości dla JDG.
#   Większość JDG używa PKPiR (uproszczonej), ale JDG przekraczające
#   2M EUR przychodu MUSZĄ prowadzić pełną księgowość wg UoR.
#
#   Ten pakiet weryfikuje zgodność z UoR gdy JDG przekroczy próg:
#   - Art. 2: Zakres podmiotowy (kto musi stosować UoR)
#   - Art. 4: Zasady rachunkowości (memoriał, współmierność, ostrożność)
#   - Art. 20-21: Dowody księgowe (minimum 5 elementów)
#   - Art. 22: Podwójny zapis
#   - Art. 26-27: Inwentaryzacja
#   - Art. 28-34: Wycena aktywów i pasywów
#   - Art. 39: Rozliczenia międzyokresowe (RMK)
#   - Art. 45-52: Sprawozdanie finansowe
#   - Art. 74: Przechowywanie dokumentacji
#
#   SYNTAX v2.0: Wszystkie wartości warunkowe zdefiniowane jako zmienne
#   lokalne w ciele reguły, NIE jako inline conditionals w obiekcie.
# architecture: Enterprise Live Layer, First-Match-Wins else-chain
# legal_basis: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 2025 poz. 567)
# package: jdg.uor_live
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor_live

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.uor_live.no_match",
    "package": "jdg.uor_live", "priority": 99999
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-001: Art. 2 — Kto musi stosować pełną księgowość UoR
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    uses_uor_check := object.get(input.jdg_entrepreneur, "uor_check_requested", false)
    uses_uor_check == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_revenue_pln := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 0)

    eur_rate_raw := object.get(data.jdg.thresholds, "bounds", {})
    eur_rate := object.get(eur_rate_raw, "eur_pln", 4.5)

    annual_revenue_eur := annual_revenue_pln / eur_rate
    uor_threshold_eur := 2000000  # 2M EUR
    uor_required := annual_revenue_eur >= uor_threshold_eur
    uor_compliant := object.get(input.jdg_entrepreneur, "uor_compliant", false)

    uor_routing := "BLOCK_AND_ALERT" { uor_required == true; uor_compliant == false }
    uor_routing := "" { uor_required == false }
    uor_routing := "" { uor_required == true; uor_compliant == true }

    uor_routing_reason := sprintf("UoR Art.2: Przychód %.0f EUR ≥ 2M EUR → PEŁNA KSIĘGOWOŚĆ wymagana!", [annual_revenue_eur]) { uor_required == true }
    uor_routing_reason := sprintf("PKPiR wystarczające — przychód %.0f EUR < 2M EUR", [annual_revenue_eur]) { uor_required == false }

    status_label := "⚠️ PEŁNA KSIĘGOWOŚĆ WYMAGANA! Księgi rachunkowe + sprawozdanie finansowe." { uor_required == true }
    status_label := "✅ PKPiR wystarczające." { uor_required == false }

    uor_warnings := [
        sprintf("📊 UoR Art.2: Przychód roczny = %.0f PLN (%.0f EUR). Próg UoR: %.0f EUR.", [annual_revenue_pln, annual_revenue_eur, uor_threshold_eur]),
        sprintf("Status: %s", [status_label])
    ]

    verdict := {
        "matched": true,
        "rule_id": "jdg.uor_live.full_accounting_obligation_check",
        "package": "jdg.uor_live",
        "priority": 9201,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_full_accounting_required": uor_required,
        "uor_threshold_eur": uor_threshold_eur,
        "uor_annual_revenue_eur": annual_revenue_eur,
        "uor_annual_revenue_pln": annual_revenue_pln,
        "uor_pkpir_sufficient": not uor_required,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": uor_routing,
        "_routing_reason": uor_routing_reason,
        "_legal_basis": "Art. 2 Ustawy o rachunkowości",
        "_warnings": uor_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-004: Art. 4 — Zasady rachunkowości (memoriał, współmierność, ostrożność)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # Memoriał: przychody i koszty w okresie którego dotyczą, nie w dacie zapłaty
    is_cash_basis := object.get(input.jdg_entrepreneur, "uor_uses_cash_method", false)
    accrual_ok := is_cash_basis == false

    # Współmierność: koszty przypisane do przychodów tego samego okresu
    has_mismatched_costs := object.get(input.jdg_entrepreneur, "uor_cost_revenue_mismatch", false)
    matching_ok := has_mismatched_costs == false

    # Ostrożność: rezerwy na znane ryzyka, brak zawyżania aktywów
    has_overstated_assets := object.get(input.jdg_entrepreneur, "uor_assets_overstated", false)
    prudence_ok := has_overstated_assets == false

    # Kontynuacja działalności
    going_concern_ok := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE") == "ACTIVE"

    # Licznik naruszeń — tablica fałszywych zasad (array, nie set!)
    violations := [accrual_ok, matching_ok, prudence_ok, going_concern_ok]
    violation_count := count({x | x := violations[_]; x == false})

    princ_routing := "BLOCK_AND_ALERT" { violation_count >= 2 }
    princ_routing := "TRIAGE_QUEUE" { violation_count == 1 }
    princ_routing := "" { violation_count == 0 }

    princ_routing_reason := sprintf("UoR Art.4: %d zasad(y) naruszone!", [violation_count]) { violation_count > 0 }
    princ_routing_reason := "" { violation_count == 0 }

    # Labels for sprintf
    accr_label := "✅" { accrual_ok == true }
    accr_label := "❌" { accrual_ok == false }
    matc_label := "✅" { matching_ok == true }
    matc_label := "❌" { matching_ok == false }
    prud_label := "✅" { prudence_ok == true }
    prud_label := "❌" { prudence_ok == false }
    conc_label := "✅" { going_concern_ok == true }
    conc_label := "❌" { going_concern_ok == false }

    princ_warnings := [
        sprintf("📐 UoR Art.4 ZASADY: Memoriał=%s, Współmierność=%s, Ostrożność=%s, Kontynuacja=%s.", [accr_label, matc_label, prud_label, conc_label]),
        sprintf("Naruszeń: %d/4", [violation_count])
    ]

    verdict := {
        "matched": true,
        "rule_id": "jdg.uor_live.accounting_principles_check",
        "package": "jdg.uor_live",
        "priority": 9202,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_accrual_principle_ok": accrual_ok,
        "uor_matching_principle_ok": matching_ok,
        "uor_prudence_principle_ok": prudence_ok,
        "uor_going_concern_ok": going_concern_ok,
        "uor_principles_violations": violation_count,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": princ_routing,
        "_routing_reason": princ_routing_reason,
        "_legal_basis": "Art. 4 Ustawy o rachunkowości (zasady rachunkowości)",
        "_warnings": princ_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-020: Art. 20-21 — Dowody księgowe (minimum 5 elementów)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    # 5 obowiązkowych elementów dowodu księgowego
    has_date := object.get(input.invoice, "issue_date", "") != ""
    has_parties := object.get(input.vendor, "name", "") != "" and object.get(input.vendor, "nip", "") != ""
    has_description := object.get(input.invoice, "description", "") != ""
    has_amount := object.get(input.invoice, "amount_net", 0) > 0 or object.get(input.invoice, "amount_gross", 0) > 0
    has_signatures := object.get(input.invoice, "has_signatures", false) or object.get(input.invoice, "is_electronic", false)

    # Build missing elements list
    missing := []
    missing := array.concat(missing, ["data"]) { has_date == false }
    missing := array.concat(missing, ["strony"]) { has_parties == false }
    missing := array.concat(missing, ["opis"]) { has_description == false }
    missing := array.concat(missing, ["kwota"]) { has_amount == false }
    missing := array.concat(missing, ["podpisy"]) { has_signatures == false }
    missing_elements := missing

    is_complete := count(missing) == 0

    doc_routing := "BLOCK_AND_ALERT" { is_complete == false }
    doc_routing := "" { is_complete == true }

    missing_str := concat(", ", missing)

    doc_routing_reason := sprintf("UoR Art.20-21: Brak %d elementów dowodu: %s", [count(missing), missing_str]) { is_complete == false }
    doc_routing_reason := "" { is_complete == true }

    comp_label := "✅ KOMPLETNY" { is_complete == true }
    comp_label := "❌ NIEKOMPLETNY" { is_complete == false }

    missing_display := missing_str { count(missing) > 0 }
    missing_display := "brak" { count(missing) == 0 }

    doc_warnings := [sprintf("📄 UoR Art.20-21: Dowód księgowy — %s. Brakujące elementy: %s", [comp_label, missing_display])]

    verdict := {
        "matched": true,
        "rule_id": "jdg.uor_live.accounting_document_validation",
        "package": "jdg.uor_live",
        "priority": 9203,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_doc_has_date": has_date,
        "uor_doc_has_parties": has_parties,
        "uor_doc_has_description": has_description,
        "uor_doc_has_amount": has_amount,
        "uor_doc_has_signatures": has_signatures,
        "uor_doc_missing_elements": missing_elements,
        "uor_doc_is_complete": is_complete,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": doc_routing,
        "_routing_reason": doc_routing_reason,
        "_legal_basis": "Art. 20-21 Ustawy o rachunkowości (dowody księgowe)",
        "_warnings": doc_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-022: Art. 22 — Zasada podwójnego zapisu
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_period_end", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    debit_total := object.get(input.jdg_entrepreneur, "uor_debit_total", 0)
    credit_total := object.get(input.jdg_entrepreneur, "uor_credit_total", 0)
    balance_diff := abs(debit_total - credit_total)
    is_balanced := balance_diff < 0.01  # Tolerance 1 grosz

    balance_routing := "BLOCK_AND_ALERT" { is_balanced == false; balance_diff > 1000 }
    balance_routing := "TRIAGE_QUEUE" { is_balanced == false; balance_diff > 0.01; balance_diff <= 1000 }
    balance_routing := "" { is_balanced == true }

    balance_routing_reason := sprintf("UoR Art.22: NIEZBILANSOWANE! Wn=%.2f ≠ Ma=%.2f (Δ=%.2f)", [debit_total, credit_total, balance_diff]) { is_balanced == false }
    balance_routing_reason := "" { is_balanced == true }

    bal_label := "✅ ZBILANSOWANE" { is_balanced == true }
    bal_label := "❌ NIEZBILANSOWANE!" { is_balanced == false }

    balance_warnings := [sprintf("⚖️ UoR Art.22 Podwójny zapis: Wn=%.2f PLN, Ma=%.2f PLN. %s", [debit_total, credit_total, bal_label])]

    verdict := {
        "matched": true,
        "rule_id": "jdg.uor_live.double_entry_validation",
        "package": "jdg.uor_live",
        "priority": 9204,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_double_entry_balanced": is_balanced,
        "uor_debit_total": debit_total,
        "uor_credit_total": credit_total,
        "uor_balance_discrepancy": balance_diff,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": balance_routing,
        "_routing_reason": balance_routing_reason,
        "_legal_basis": "Art. 22 Ustawy o rachunkowości (podwójny zapis)",
        "_warnings": balance_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-026: Art. 26-27 — Inwentaryzacja (spis z natury, potwierdzenie sald)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    last_inventory_date := object.get(input.jdg_entrepreneur, "uor_last_inventory_date", "2020-01-01")
    has_physical_count := object.get(input.jdg_entrepreneur, "uor_physical_count_done", false)
    has_confirmation := object.get(input.jdg_entrepreneur, "uor_balance_confirmation_done", false)
    has_verification := object.get(input.jdg_entrepreneur, "uor_document_verification_done", false)

    inventory_required := true
    missing_parts := []
    missing_parts := array.concat(missing_parts, ["spis z natury"]) { has_physical_count == false }
    missing_parts := array.concat(missing_parts, ["potwierdzenie sald"]) { has_confirmation == false }
    missing_parts := array.concat(missing_parts, ["weryfikacja dokumentów"]) { has_verification == false }

    inv_type := "PEŁNA (spis + potwierdzenie + weryfikacja)" { count(missing_parts) == 0 }
    inv_type := sprintf("NIEPEŁNA — brak: %s", [concat(", ", missing_parts)]) { count(missing_parts) > 0 }
    inventory_type := inv_type

    is_overdue := count(missing_parts) > 0

    inv_routing := "BLOCK_AND_ALERT" { is_overdue == true }
    inv_routing := "" { is_overdue == false }

    inv_routing_reason := sprintf("Inwentaryzacja: brak %s", [concat(", ", missing_parts)]) { is_overdue == true }
    inv_routing_reason := "" { is_overdue == false }

    pcount_label := "✅" { has_physical_count == true }
    pcount_label := "❌" { has_physical_count == false }
    conf_label := "✅" { has_confirmation == true }
    conf_label := "❌" { has_confirmation == false }
    verif_label := "✅" { has_verification == true }
    verif_label := "❌" { has_verification == false }

    inv_warnings := [
        sprintf("📋 UoR Art.26-27 Inwentaryzacja: Ostatnia=%s. Status: %s", [last_inventory_date, inventory_type]),
        sprintf("Spis z natury=%s, Potwierdzenie sald=%s, Weryfikacja=%s", [pcount_label, conf_label, verif_label])
    ]

    verdict := {
        "matched": true,
        "rule_id": "jdg.uor_live.inventory_obligation_check",
        "package": "jdg.uor_live",
        "priority": 9205,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_inventory_required": inventory_required,
        "uor_inventory_type": inventory_type,
        "uor_inventory_deadline": "3 miesiące po dniu bilansowym",
        "uor_inventory_last_date": last_inventory_date,
        "uor_inventory_overdue": is_overdue,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": inv_routing,
        "_routing_reason": inv_routing_reason,
        "_legal_basis": "Art. 26-27 Ustawy o rachunkowości (inwentaryzacja)",
        "_warnings": inv_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-028: Art. 28-34 — Wycena aktywów i pasywów
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    input.invoice.expense_type == "FIXED_ASSET"

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    asset_type := object.get(input.invoice, "asset_type", "TANGIBLE")
    asset_value := object.get(input.invoice, "amount_net", 0)
    market_value := object.get(input.invoice, "asset_market_value", asset_value)
    is_impaired := market_value < asset_value * 0.50

    valuation_method := "CENA NABYCIA (Art. 28 ust. 1 pkt 1 UoR)" { asset_type == "TANGIBLE" }
    valuation_method := "WARTOŚĆ GODZIWA (Art. 28 ust. 1 pkt 5 UoR)" { asset_type == "FINANCIAL" }
    valuation_method := "KOSZT WYTWORZENIA (Art. 28 ust. 1 pkt 3 UoR)" { asset_type == "SELF_MANUFACTURED" }
    else := "CENA NABYCIA" { true }

    impairment_needed := is_impaired and market_value > 0

    val_routing := "TRIAGE_QUEUE" { impairment_needed == true }
    val_routing := "" { impairment_needed == false }

    val_routing_reason := sprintf("Utrata wartości: nabycie=%.0f PLN, rynek=%.0f PLN — odpis aktualizujący wymagany!", [asset_value, market_value]) { impairment_needed == true }
    val_routing_reason := "" { impairment_needed == false }

    impair_label := "⚠️ UTRATA WARTOŚCI >50% — wymagany odpis aktualizujący!" { impairment_needed == true }
    impair_label := "✅ OK" { impairment_needed == false }

    val_warnings := [
        sprintf("💰 UoR Art.28-34 Wycena: %s, metoda=%s, wartość=%.0f PLN.", [asset_type, valuation_method, asset_value]),
        sprintf("Wartość rynkowa: %.0f PLN. %s", [market_value, impair_label])
    ]

    verdict := {
        "matched": true,
        "rule_id": "jdg.uor_live.asset_valuation_check",
        "package": "jdg.uor_live",
        "priority": 9206,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_valuation_asset_type": asset_type,
        "uor_valuation_method": valuation_method,
        "uor_valuation_amount": asset_value,
        "uor_valuation_impairment_required": impairment_needed,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": val_routing,
        "_routing_reason": val_routing_reason,
        "_legal_basis": "Art. 28-34 Ustawy o rachunkowości (wycena)",
        "_warnings": val_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-039: Art. 39 — Rozliczenia międzyokresowe kosztów (RMK)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_period_end", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    has_prepaid := object.get(input.jdg_entrepreneur, "uor_has_prepaid_expenses", false)
    has_accrued := object.get(input.jdg_entrepreneur, "uor_has_accrued_expenses", false)
    rmk_amount := object.get(input.jdg_entrepreneur, "uor_rmk_total_pln", 0)
    rmk_periods := object.get(input.jdg_entrepreneur, "uor_rmk_periods_count", 1)

    needs_rmk := has_prepaid or has_accrued
    rmk_handled := object.get(input.jdg_entrepreneur, "uor_rmk_properly_booked", true)

    rmk_routing := "TRIAGE_QUEUE" { needs_rmk == true; rmk_handled == false }
    rmk_routing := "" { needs_rmk == false }
    rmk_routing := "" { needs_rmk == true; rmk_handled == true }

    rmk_routing_reason := sprintf("RMK: %.0f PLN nieprawidłowo rozliczone!", [rmk_amount]) { needs_rmk == true; rmk_handled == false }
    rmk_routing_reason := "" { needs_rmk == false }
    rmk_routing_reason := "" { needs_rmk == true; rmk_handled == true }

    prep_label := "TAK" { has_prepaid == true }
    prep_label := "NIE" { has_prepaid == false }
    accr_label := "TAK" { has_accrued == true }
    accr_label := "NIE" { has_accrued == false }
    rmk_label := "✅ Prawidłowe" { rmk_handled == true }
    rmk_label := "⚠️ Wymaga korekty!" { rmk_handled == false }

    rmk_warnings := [
        sprintf("📅 UoR Art.39 RMK: RMK czynne=%s, RMK bierne=%s, Kwota=%.0f PLN, Okresy=%d.", [prep_label, accr_label, rmk_amount, rmk_periods]),
        sprintf("Rozliczenie: %s", [rmk_label])
    ]

    verdict := {
        "matched": true,
        "rule_id": "jdg.uor_live.accruals_deferrals_check",
        "package": "jdg.uor_live",
        "priority": 9207,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_rmk_prepaid_detected": has_prepaid,
        "uor_rmk_accrued_detected": has_accrued,
        "uor_rmk_amount_pln": rmk_amount,
        "uor_rmk_periods": rmk_periods,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": rmk_routing,
        "_routing_reason": rmk_routing_reason,
        "_legal_basis": "Art. 39 Ustawy o rachunkowości (RMK)",
        "_warnings": rmk_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-045: Art. 45-52 — Sprawozdanie finansowe
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true
    object.get(input.invoice, "is_year_end", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    tax_year := object.get(input.jdg_entrepreneur, "tax_year", "2026")
    tax_year_int := to_number(tax_year)
    next_year_int := tax_year_int + 1

    fs_required := true
    fs_deadline := sprintf("%d-03-31", [next_year_int])
    fs_filed := object.get(input.jdg_entrepreneur, "uor_financial_statement_filed", false)

    fs_routing := "BLOCK_AND_ALERT" { fs_filed == false }
    fs_routing := "" { fs_filed == true }

    fs_routing_reason := sprintf("Sprawozdanie finansowe za %s NIE złożone! Termin: %s", [tax_year, fs_deadline]) { fs_filed == false }
    fs_routing_reason := "" { fs_filed == true }

    filed_label := "✅ ZŁOŻONE" { fs_filed == true }
    filed_label := sprintf("❌ NIEZŁOŻONE — termin: %s!", [fs_deadline]) { fs_filed == false }

    fs_warnings := [
        sprintf("📊 UoR Art.45-52: Sprawozdanie za rok %s — termin: %s.", [tax_year, fs_deadline]),
        "Skład: Bilans, Rachunek Zysków i Strat, Informacja dodatkowa.",
        sprintf("Status: %s", [filed_label])
    ]

    verdict := {
        "matched": true,
        "rule_id": "jdg.uor_live.financial_statement_obligation",
        "package": "jdg.uor_live",
        "priority": 9208,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_financial_statement_required": fs_required,
        "uor_fs_components": ["Bilans", "RZiS", "Informacja dodatkowa"],
        "uor_fs_deadline": fs_deadline,
        "uor_fs_filing": "KRS + US + publikacja w Monitorze Sądowym i Gospodarczym",
        "business_status": "", "ceidg_registration_required": false,
        "_routing": fs_routing,
        "_routing_reason": fs_routing_reason,
        "_legal_basis": "Art. 45-52 Ustawy o rachunkowości (sprawozdanie finansowe)",
        "_warnings": fs_warnings
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UOR-074: Art. 74 — Przechowywanie dokumentacji księgowej (5 lat)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "uses_uor", false) == true

    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    current_year := 2026

    oldest_year_int := current_year - 5
    oldest_year := sprintf("%d", [oldest_year_int])

    # Years safe to destroy: years <= oldest_year, starting from 2020
    safe_years_raw := [sprintf("%d", [yr]) | some yr in [2020, 2021, 2022, 2023, 2024, 2025]; yr <= oldest_year_int]
    safe_destroy_years := safe_years_raw { count(safe_years_raw) > 0 }
    safe_destroy_years := ["brak"] { count(safe_years_raw) == 0 }

    safe_display := concat(", ", safe_years_raw) { count(safe_years_raw) > 0 }
    safe_display := "brak" { count(safe_years_raw) == 0 }

    verdict := {
        "matched": true,
        "rule_id": "jdg.uor_live.document_retention_check",
        "package": "jdg.uor_live",
        "priority": 9209,
        "vat_rate": "", "rounding_level": "", "gtu_code": "",
        "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
        "kus_qualification": "", "kus_percent": 0,
        "zus_social_base_type": "", "zus_health_rate": "",
        "uor_retention_years": 5,
        "uor_retention_years_post_closure": 5,
        "uor_retention_oldest_year_to_keep": oldest_year,
        "uor_retention_years_safe_to_destroy": safe_destroy_years,
        "business_status": "", "ceidg_registration_required": false,
        "_routing": "",
        "_routing_reason": "",
        "_legal_basis": "Art. 74 Ustawy o rachunkowości (przechowywanie)",
        "_warnings": [sprintf("🗂️ UoR Art.74: Dokumenty księgowe przechowuj 5 lat od końca roku obrotowego. Najstarszy rok do zachowania: %s. Można zniszczyć dokumenty za: %s.", [oldest_year, safe_display])]
    }
}
