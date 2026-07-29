# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Edge Cases: VAT, PIT, ZUS, Sankcje, Terminy
# Doc 28a: R0546-R0680 — Grupy A-I (114 reguł)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Edge Cases Package — VAT, PIT, ZUS Edge Cases + Sanctions + Deadlines
# description: |
#   Implementacja Doc 28a ENTERPRISE v1.0 edge cases. First-Match-Wins else-chain.
#   Grupa A: VAT Edge Cases (R0546-R0559, 14 reguł)
#   Grupa B: PIT Edge Cases (R0560-R0573, 14 reguł)
#   Grupa C: ZUS Edge Cases (R0574-R0585, 12 reguł)
#   Grupa D: VAT Zwolnienie 200k (R0586-R0594, 9 reguł)
#   Grupa E: PIT Edge Extended (R0595-R0601, 7 reguł)
#   Grupa G: Sankcje (R0646-R0655, 10 reguł)
#   Grupa H: Terminy / Deadlines (R0656-R0672, 17 reguł)
#   Grupa I: Cross-border/TP/CFC (R0673-R0680, 8 reguł)
# legal_basis: Art. 113, 19a, 31a, 86a, 106d, 106e VAT; Art. 9, 23, 24, 26e,
#              27g, 30ca PIT; Art. 18a, 18c, 36a SUS; Art. 44, 45, 47, 48-52,
#              54, 56, 60, 62, 76, 77-79, 83 KKS; Art. 96b, 108a, 109, 106na,
#              106nq VAT; Art. 22p, 26h, 26eb, 26ec PIT; Art. 70, 78, 81 OrdPU
# package: jdg.edge_cases
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.edge_cases

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.edge_cases.no_match",
    "package": "jdg.edge_cases", "priority": 999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA A: R0546-R0559 — VAT EDGE CASES (14 reguł)                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# R0546: vat_breach_mid_year — Przekroczenie limitu zwolnienia 200k w trakcie roku
decide := {
    "matched": true, "rule_id": "jdg.edge_cases.vat_breach_mid_year",
    "package": "jdg.edge_cases", "priority": 546,
    "vat_rate": "0.23", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_status_change": "EXEMPT→ACTIVE", "vat_registration_obligation": true,
    "vat_applies_from": breach_date,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Przekroczenie limitu VAT 200k — obowiązek rejestracji",
    "_legal_basis": "Art. 113 ust. 1 i 5 VAT",
    "_warnings": [sprintf("PRZEKROCZENIE LIMITU VAT — sprzedaż YTD %.2f PLN przekracza 200 000 PLN. VAT należny od transakcji z %s. Złóż VAT-R w ciągu 7 dni!", [ytd_sales, breach_date])]
} {
    input.jdg_entrepreneur.vat_status == "EXEMPT_SUBJECT"
    ytd_sales := object.get(input.jdg_entrepreneur, "sales_ytd_vat_exempt", 0)
    limit := object.get(object.get(data.thresholds, "jdg", {}), "vat_subject_exemption_limit", 200000)
    ytd_sales >= limit
    breach_date := object.get(input.invoice, "transaction_date", "")
}

# ═══════════════════════════════════════════════════════════════════════════════
# R0546b: vat_exemption_breach_forecast — Prognoza przekroczenia limitu 200k (QF-6 v7.0)
# Automatycznie oblicza kiedy JDG przekroczy limit 200 000 PLN przy obecnym tempie
# sprzedaży i generuje alert z wyprzedzeniem.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.edge_cases.vat_breach_forecast",
    "package": "jdg.edge_cases", "priority": 546,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_breach_forecast": true,
    "vat_breach_forecast_date": forecast_date,
    "vat_breach_days_remaining": days_remaining,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Prognoza: limit VAT 200k przekroczony ~%s (za %d dni)", [forecast_date, days_remaining]),
    "_legal_basis": "Art. 113 ust. 1 i 5 VAT",
    "_warnings": [sprintf("PROGNOZA: Przy obecnym tempie sprzedaży (średnio %.2f PLN/dzień), limit VAT 200 000 PLN przekroczysz około %s (za %d dni). Zarejestruj VAT-R z wyprzedzeniem! Aktualny YTD: %.2f PLN, pozostało: %.2f PLN.", [daily_avg, forecast_date, days_remaining, ytd_sales, remaining])]
} {
    input.jdg_entrepreneur.vat_status == "EXEMPT_SUBJECT"
    ytd_sales := object.get(input.jdg_entrepreneur, "sales_ytd_vat_exempt", 0)
    days_elapsed := object.get(input.jdg_entrepreneur, "days_elapsed_this_year", 182)
    days_elapsed > 0
    ytd_sales > 0
    limit := object.get(object.get(data.thresholds, "jdg", {}), "vat_subject_exemption_limit", 200000)
    ytd_sales >= limit * 0.50  # Prognozuj gdy > 50% limitu
    ytd_sales < limit  # Jeszcze nie przekroczono
    daily_avg := ytd_sales / days_elapsed
    remaining := limit - ytd_sales
    days_remaining := floor(remaining / daily_avg)
    # Oblicz datę prognozowanego przekroczenia
    # v7.0: forecast_date pobierana z PreOPAPipeline (Python bridge)
    # Jeśli bridge nie dostarczył daty, oblicz przybliżenie w Rego
    current_date := object.get(input.invoice, "transaction_date", "2026-07-01")
    forecast_from_bridge := object.get(input.jdg_entrepreneur, "vat_breach_forecast_date", "")
    forecast_date := forecast_from_bridge { forecast_from_bridge != "" }
    forecast_date := concat("", [substring(current_date, 0, 4), "-", format_month(month_forecast), "-", format_day(day_forecast)]) { forecast_from_bridge == "" }
    month_num := to_number(substring(current_date, 5, 2))
    months_to_add := floor(days_remaining / 30)
    month_forecast := month_num + months_to_add { month_num + months_to_add <= 12 }
    month_forecast := month_num + months_to_add - 12 { month_num + months_to_add > 12 }
    day_forecast := 15  # mid-month approximation
    format_month(m) = sprintf("%02d", [m])
    format_day(d) = sprintf("%02d", [d])
}

# R0547: vat_breach_proportion_new_jdg — Limit proporcjonalny dla nowej JDG
else := {
    "matched": true, "rule_id": "jdg.edge_cases.vat_breach_proportion_new_jdg",
    "package": "jdg.edge_cases", "priority": 547,
    "vat_rate": "0.23", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_status_change": "EXEMPT→ACTIVE", "proportion_limit": proportion_limit,
    "days_remaining": days_remaining,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Nowa JDG — proporcjonalny limit VAT",
    "_legal_basis": "Art. 113 ust. 9 VAT",
    "_warnings": [sprintf("NOWA JDG — limit proporcjonalny %.2f PLN (%d dni do końca roku). Przekroczenie: VAT od nadwyżki.", [proportion_limit, days_remaining])]
} {
    input.jdg_entrepreneur.vat_status == "EXEMPT_SUBJECT"
    days_remaining := object.get(input.jdg_entrepreneur, "vat_proportion_days_remaining", 0)
    days_remaining > 0
    full_limit := object.get(object.get(data.thresholds, "jdg", {}), "vat_subject_exemption_limit", 200000)
    proportion_limit := floor(full_limit * days_remaining / 365)
}

# R0548: vat_first_invoice_tax_point — Moment powstania obowiązku po rejestracji
else := {
    "matched": true, "rule_id": "jdg.edge_cases.vat_first_invoice_tax_point",
    "package": "jdg.edge_cases", "priority": 548,
    "vat_rate": "0.23", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_tax_point": tax_point, "first_vat_declaration_due": "25th_next_month",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 19a ust. 1 VAT",
    "_warnings": [sprintf("PIERWSZA FAKTURA VAT — obowiązek podatkowy: %s. Pierwszy JPK_VAT do 25. dnia następnego miesiąca.", [tax_point])]
} {
    input.jdg_entrepreneur.vat_status == "ACTIVE"
    input.invoice.is_first_vat_invoice == true
    tax_point := object.get(input.invoice, "transaction_date", "")
    tax_point != ""
}

# R0549-R0555: Stuby VAT edge
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_last_invoice_before_deregister", "package": "jdg.edge_cases", "priority": 549, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "vat_final_settlement": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Wyrejestrowanie VAT — remanent likwidacyjny", "_legal_basis": "Art. 14 ust. 1 i 4 VAT", "_warnings": ["WYREJESTROWANIE VAT — VAT od remanentu likwidacyjnego 23% wartości rynkowej"] } { input.jdg_entrepreneur.vat_deregistration_in_progress == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_exempt_breach_notification_7days", "package": "jdg.edge_cases", "priority": 550, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "vat_r_deadline_days": 7, "_routing": "TRIAGE_QUEUE", "_routing_reason": "7 dni na VAT-R po przekroczeniu limitu", "_legal_basis": "Art. 96 ust. 1 i 5 VAT", "_warnings": ["VAT-R: 7 dni na zgłoszenie rejestracyjne po przekroczeniu limitu!"] } { object.get(input.jdg_entrepreneur, "vat_breach_detected", false) == true; object.get(input.jdg_entrepreneur, "vat_r_submitted", true) == false }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_exempt_breach_retroactive", "package": "jdg.edge_cases", "priority": 551, "vat_rate": "0.23", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "vat_retroactive": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "VAT wstecz od transakcji powodującej przekroczenie", "_legal_basis": "Art. 113 ust. 5 VAT", "_warnings": ["VAT należny od nadwyżki ponad limit — faktura wymaga korekty lub VAT w stu"] } { object.get(input.invoice, "caused_vat_breach", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_prepayment_full_vat", "package": "jdg.edge_cases", "priority": 552, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "vat_tax_point_override": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 19a ust. 8 VAT", "_warnings": ["Zaliczka 100% — obowiązek VAT w dacie otrzymania zaliczki, nie wykonania usługi"] } { object.get(input.invoice, "prepayment_received", false) == true; object.get(input.invoice, "prepayment_rate", 0) == 1.0 }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_mixed_sale_exempt_taxable", "package": "jdg.edge_cases", "priority": 553, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "mixed_activity": true, "proportion_required": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 90 ust. 1-2 VAT", "_warnings": ["Sprzedaż mieszana — wymagana proporcja VAT. Proporcja <2% → odliczenie 0%, >98% → 100%"] } { object.get(input.jdg_entrepreneur, "has_mixed_vat_activity", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_correction_chain_reaction", "package": "jdg.edge_cases", "priority": 554, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "chain_reaction": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Korekta VAT → efekt domina dla proporcji", "_legal_basis": "Art. 91 ust. 1 i 3 VAT", "_warnings": ["Korekta sprzedaży wpływa na proporcję VAT — sprawdź czy trzeba skorygować odliczenia"] } { object.get(input.invoice, "correction_affects_proportion", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_currency_conversion_date", "package": "jdg.edge_cases", "priority": 555, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "fx_rate_required": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 31a ust. 1 VAT", "_warnings": ["Faktura walutowa — przelicz wg kursu NBP z dnia poprzedzającego obowiązek podatkowy"] } { input.invoice.currency != "PLN"; input.invoice.vat_tax_point_date != "" }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_self_invoice_obligation", "package": "jdg.edge_cases", "priority": 556, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "self_invoice_obligation": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Obowiązek samofakturowania", "_legal_basis": "Art. 106d ust. 1-2 VAT", "_warnings": ["Dostawca nie wystawił faktury — obowiązek samofakturowania w 7 dni od dostawy"] } { object.get(input.invoice, "self_invoice_required", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_non_deductible_pro_rata", "package": "jdg.edge_cases", "priority": 557, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "pro_rata_temporalis": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 90 ust. 2-10, Art. 91 ust. 2-7 VAT", "_warnings": ["Zmiana proporcji VAT >2pp — wymagana korekta odliczeń za poprzednie miesiące"] } { object.get(input.jdg_entrepreneur, "proportion_change_gt_2pp", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_construction_acceptance_partial", "package": "jdg.edge_cases", "priority": 558, "vat_rate": "0.23", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "partial_acceptance": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 19a ust. 2 VAT", "_warnings": ["Odbiór częściowy robót budowlanych — obowiązek VAT proporcjonalnie do odebranej części"] } { object.get(input.invoice, "partial_acceptance", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_sale_and_leaseback", "package": "jdg.edge_cases", "priority": 559, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sale_leaseback": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 5 ust. 1 pkt 1, Art. 19a, Art. 41 VAT", "_warnings": ["Sale-and-leaseback — DWIE transakcje VAT: sprzedaż ŚT + leasing zwrotny"] } { object.get(input.invoice, "transaction_type", "") == "SALE_AND_LEASEBACK" }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA B: R0560-R0573 — PIT EDGE CASES (14 reguł)                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_first_year_lump_sum_loss", "package": "jdg.edge_cases", "priority": 560, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Ryczałt: podatek od przychodu mimo straty", "_legal_basis": "Art. 6 ust. 1 ustawy o ryczałcie", "_warnings": ["UWAGA: Ryczałt — podatek od PRZYCHODU. Strata nie obniża podatku!"] } { input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.jdg_entrepreneur, "is_first_year", false) == true; object.get(input.jdg_entrepreneur, "has_net_loss", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_last_year_before_closure", "package": "jdg.edge_cases", "priority": 561, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "remnant_tax_due": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zamknięcie JDG — 10% podatek od remanentu", "_legal_basis": "Art. 24 ust. 3 i 3a PIT", "_warnings": ["10% zryczałtowany podatek od remanentu likwidacyjnego — zapłać przed zamknięciem!"] } { object.get(input.jdg_entrepreneur, "business_closure_in_progress", false) == true; object.get(input.jdg_entrepreneur, "inventory_remnant_value", 0) > 0 }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_double_taxation_abroad", "package": "jdg.edge_cases", "priority": 562, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "double_tax_method_required": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Dochód zagraniczny — metoda unikania podwójnego opodatkowania", "_legal_basis": "Art. 27 ust. 8-9 PIT + UPO", "_warnings": ["Dochód zagraniczny — sprawdź umowę UPO. Metoda: proporcjonalne odliczenie lub wyłączenie z progresją"] } { object.get(input.jdg_entrepreneur, "foreign_income", 0) > 0; object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL" }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_linear_health_underpayment", "package": "jdg.edge_cases", "priority": 563, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "LINEAR", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "TRIAGE_QUEUE", "_routing_reason": sprintf("Liniowy: odliczenie zdrowotnej max %.0f PLN", [thresholds.zus.health_linear_deduction_limit]), "_legal_basis": "Art. 30c ust. 2 PIT", "_warnings": [sprintf("Podatek liniowy — max odliczenie składki zdrowotnej %.0f PLN rocznie", [thresholds.zus.health_linear_deduction_limit])] } { input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "zus_health_paid_ytd", 0) > thresholds.zus.health_linear_deduction_limit }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_lump_sum_health_progressive", "package": "jdg.edge_cases", "priority": 564, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "health_tier_change": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 81 ust. 2e ustawy o świadczeniach zdrowotnych", "_warnings": ["Ryczałt: przekroczenie progu przychodu — zmiana składki zdrowotnej. Roczne rozliczenie do 22 maja"] } { object.get(input.jdg_entrepreneur, "lump_sum_revenue_tier_changed", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_loss_multiple_years", "package": "jdg.edge_cases", "priority": 565, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "loss_carry_fifo": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 9 ust. 3 PIT", "_warnings": ["Straty z wielu lat — rozliczaj FIFO. Max 50% straty z danego roku w jednym roku. 5 lat na rozliczenie"] } { object.get(input.jdg_entrepreneur, "has_multiple_year_losses", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_inventory_valuation_method", "package": "jdg.edge_cases", "priority": 566, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 24 ust. 2 PIT", "_warnings": ["Remanent: wycena wg NIŻSZEJ z cen: zakupu lub rynkowej na dzień remanentu"] } { object.get(input.jdg_entrepreneur, "inventory_valuation_required", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_spouse_contract_under_authority", "package": "jdg.edge_cases", "priority": 567, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "NKUP", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Małżonek podwładny → NKUP", "_legal_basis": "Art. 23 ust. 1 pkt 10 PIT", "_warnings": ["Wynagrodzenie małżonka pozostającego w podległości służbowej → NKUP"] } { object.get(input.jdg_entrepreneur, "spouse_under_authority", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_child_labor_under_18", "package": "jdg.edge_cases", "priority": 568, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "NKUP", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Dziecko <18 lat bez dokumentacji → NKUP", "_legal_basis": "Art. 23 ust. 1 pkt 10 PIT", "_warnings": ["Praca dziecka <18 lat — wymagana pełna dokumentacja + zgoda rodziców"] } { object.get(input.jdg_entrepreneur, "child_labor_undocumented", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_abroad_relief_abolition", "package": "jdg.edge_cases", "priority": 569, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 27g PIT", "_warnings": ["Ulga abolicyjna — limit zależny od roku podatkowego. Tylko przy metodzie proporcjonalnego odliczenia"] } { object.get(input.jdg_entrepreneur, "abolition_relief_available", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_rental_income_jdg_vs_private", "package": "jdg.edge_cases", "priority": 570, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 10 ust. 1 pkt 3 i 6 PIT", "_warnings": ["Najem: JDG (skala/liniowy) ≠ prywatny (ryczałt 8.5%/12.5%). Klasyfikuj osobno"] } { object.get(input.jdg_entrepreneur, "rental_classification_needed", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_foreign_currency_loan_fx", "package": "jdg.edge_cases", "priority": 571, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 14c PIT, Art. 22 ust. 1 PIT", "_warnings": ["Pożyczka walutowa FX — różnice kursowe: dodatnie=przychód, ujemne=KUP"] } { input.invoice.currency != "PLN"; object.get(input.invoice, "is_loan_repayment", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_donation_excess_loss", "package": "jdg.edge_cases", "priority": 572, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "donation_excess_lost": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 26 ust. 1 pkt 9 PIT", "_warnings": ["Nadwyżka darowizny ponad 6% dochodu PRZEPADA — nie przechodzi na kolejne lata!"] } { object.get(input.jdg_entrepreneur, "donation_excess_not_carried", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_health_contrib_scale_9pct_no_deduction", "package": "jdg.edge_cases", "priority": 573, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "0.09", "business_status": "", "ceidg_registration_required": false, "health_non_deductible": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 81 ust. 2 ustawy o świadczeniach (Polski Ład 2022)", "_warnings": ["Polski Ład 2022+: Składka zdrowotna 9% NIE podlega odliczeniu od PIT na skali!"] } { input.jdg_entrepreneur.tax_form == "SCALE"; object.get(input.jdg_entrepreneur, "tax_year", 2026) >= 2022; object.get(input.jdg_entrepreneur, "zus_health_paid_ytd", 0) > 0 }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA C: R0574-R0585 — ZUS EDGE CASES (12 reguł)                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_start_relief_transition_preferential", "package": "jdg.edge_cases", "priority": 574, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "PREFERENTIAL", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "zus_relief_change": "START→PREFERENTIAL", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 18a ust. 1-2 SUS", "_warnings": ["Koniec ulgi na start — automatyczne przejście na preferencyjny ZUS (30% min. podstawy, 24 mies.)"] } { object.get(input.jdg_entrepreneur, "zus_start_relief_ending", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_maly_plus_36_months_exhaustion", "package": "jdg.edge_cases", "priority": 575, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "STANDARD", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "zus_relief_change": "MAŁY_ZUS+→STANDARD", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Koniec Małego ZUS+ po 36 mies.", "_legal_basis": "Art. 18c ust. 1 i 4 SUS", "_warnings": ["Koniec Małego ZUS+ — przejście na standardowy ZUS. Przygotuj się na wzrost składek!"] } { object.get(input.jdg_entrepreneur, "maly_zus_plus_exhausted", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_preferential_24_months_exhaustion", "package": "jdg.edge_cases", "priority": 576, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "STANDARD", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "zus_relief_change": "PREFERENTIAL→STANDARD", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Koniec preferencyjnego ZUS po 24 mies.", "_legal_basis": "Art. 18a ust. 2 SUS", "_warnings": ["Koniec preferencyjnego ZUS — składki wzrosną do 60% przeciętnego wynagrodzenia!"] } { object.get(input.jdg_entrepreneur, "preferential_zus_exhausted", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_concurrent_jdg_and_mandate", "package": "jdg.edge_cases", "priority": 577, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "MANDATE", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 9 ust. 2a SUS", "_warnings": ["JDG + zlecenie — jeśli zlecenie ≥min. płaca, społeczne ze zlecenia, zdrowotna z JDG"] } { object.get(input.jdg_entrepreneur, "has_concurrent_mandate", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_sickness_benefit_waiting_90days", "package": "jdg.edge_cases", "priority": 578, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sickness_benefit_blocked": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 4 ust. 1 pkt 2 ustawy zasiłkowej", "_warnings": ["Zasiłek chorobowy dopiero po 90 dniach nieprzerwanego ubezpieczenia — trwa okres wyczekiwania"] } { object.get(input.jdg_entrepreneur, "sickness_claim_in_waiting_period", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_maternity_benefit_no_health_exemption", "package": "jdg.edge_cases", "priority": 579, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "health_still_due": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych", "_warnings": ["Macierzyński NIE zwalnia ze składki zdrowotnej — opłać do 10. dnia miesiąca!"] } { object.get(input.jdg_entrepreneur, "maternity_benefit_active", false) == true; object.get(input.jdg_entrepreneur, "zus_health_paid_current_month", true) == false }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_health_annual_overpayment_refund", "package": "jdg.edge_cases", "priority": 580, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "overpayment_refund_needed": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 81 ust. 2d i 2f ustawy o świadczeniach", "_warnings": ["Nadpłata składki zdrowotnej — złóż wniosek o zwrot do ZUS (ZUS nie zwraca automatycznie)"] } { object.get(input.jdg_entrepreneur, "zus_health_overpayment", 0) > 0; object.get(input.jdg_entrepreneur, "zus_health_refund_requested", true) == false }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_health_annual_underpayment_deadline_may22", "package": "jdg.edge_cases", "priority": 581, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "underpayment_deadline": "MAY_22", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niedopłata zdrowotnej — termin 22 maja", "_legal_basis": "Art. 81 ust. 2f ustawy o świadczeniach", "_warnings": ["Niedopłata składki zdrowotnej — ureguluj do 22 maja! Po terminie odsetki."] } { object.get(input.jdg_entrepreneur, "zus_health_underpayment", 0) > 0; object.get(input.jdg_entrepreneur, "zus_health_underpayment_paid", true) == false }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_declaration_zero_on_suspension", "package": "jdg.edge_cases", "priority": 582, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "ZERO", "zus_health_rate": "", "business_status": "SUSPENDED", "ceidg_registration_required": false, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 36a SUS", "_warnings": ["Zawieszenie JDG → ZUS społeczny = 0, ale ZDROWOTNA NADAL NALEŻNA!"] } { object.get(input.jdg_entrepreneur, "business_suspended", false) == true; object.get(input.jdg_entrepreneur, "has_employees", true) == false }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_multiple_titles_concurrent", "package": "jdg.edge_cases", "priority": 583, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 9 ust. 2, 2a, 2b SUS", "_warnings": ["Wiele tytułów ubezpieczenia — etat > JDG > zlecenie. Społeczne z jednego, zdrowotna z każdego"] } { object.get(input.jdg_entrepreneur, "has_multiple_insurance_titles", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_retirement_while_jdg", "package": "jdg.edge_cases", "priority": 584, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "EXEMPT", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 9 ust. 4b SUS", "_warnings": ["Emeryt + JDG → tylko składka zdrowotna. Społeczne są z emerytury."] } { object.get(input.jdg_entrepreneur, "receives_retirement_pension", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.zus_student_under_26_jdg", "package": "jdg.edge_cases", "priority": 585, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "VOLUNTARY", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 6 ust. 4, Art. 9 ust. 2c SUS", "_warnings": ["Student <26 lat + JDG → tylko zdrowotna obowiązkowa. Społeczne dobrowolne."] } { object.get(input.jdg_entrepreneur, "is_student_under_26", false) == true }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA D: R0586-R0594 — VAT ZWOLNIENIE PODMIOTOWE ROZSZERZENIE (9 reguł) ║
# ║  Art. 113 ust. 2, 5, 11, 13, 19 VAT — KRYTYCZNE luki                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# R0586: vat_exemption_exclusions_art113_13 — Wyłączenia ze zwolnienia (V.52)
else := {
    "matched": true, "rule_id": "jdg.edge_cases.vat_exemption_exclusions",
    "package": "jdg.edge_cases", "priority": 586,
    "vat_rate": "0.23", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_exemption": "DENIED", "vat_exclusion_reason": exclusion_reason,
    "vat_mandatory_registration": true,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Wyłączenie ze zwolnienia VAT — Art. 113 ust. 13",
    "_legal_basis": "Art. 113 ust. 13 VAT",
    "_warnings": [sprintf("WYŁĄCZENIE ZE ZWOLNIENIA VAT — %s. Art. 113 ust. 13: NIE możesz korzystać ze zwolnienia podmiotowego. Obowiązkowa rejestracja VAT-R przed pierwszą transakcją!", [exclusion_reason])]
} {
    input.jdg_entrepreneur.vat_status == "EXEMPT_SUBJECT"
    excluded := input.jdg_entrepreneur.vat_exclusion_category
    excluded in {"LAWYER", "TAX_ADVISOR", "JEWELER", "COMMISSION_SHOP", "REAL_ESTATE_BROKER", "NOTARY"}
    exclusion_reason := excluded
}

# R0587: vat_exemption_loss_of_right_art113_2 — Utrata prawa po przekroczeniu (V.50 rozszerzenie)
else := {
    "matched": true, "rule_id": "jdg.edge_cases.vat_exemption_lost",
    "package": "jdg.edge_cases", "priority": 587,
    "vat_rate": "0.23", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_status_change": "EXEMPT→ACTIVE", "vat_loss_date": loss_date,
    "vat_r_deadline_days": 7,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Utrata prawa do zwolnienia — przekroczenie 200k",
    "_legal_basis": "Art. 113 ust. 2 i 5 VAT",
    "_warnings": [sprintf("UTRATA PRAWA DO ZWOLNIENIA VAT — przekroczenie limitu 200k w dniu %s. VAT należny od nadwyżki. Złóż VAT-R w ciągu 7 dni. Nie czekaj na koniec roku!", [loss_date])]
} {
    input.jdg_entrepreneur.vat_status == "EXEMPT_SUBJECT"
    ytd_sales := object.get(input.jdg_entrepreneur, "sales_ytd_vat_exempt", 0)
    limit := object.get(object.get(data.thresholds, "jdg", {}), "vat_subject_exemption_limit", 200000)
    ytd_sales >= limit
    loss_date := object.get(input.invoice, "transaction_date", "")
    loss_date != ""
}

# R0588: vat_exemption_reacquisition_art113_11 — Ponowne nabycie prawa po 12m (V.53)
else := {
    "matched": true, "rule_id": "jdg.edge_cases.vat_exemption_reacquire",
    "package": "jdg.edge_cases", "priority": 588,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_reacquisition_possible": true, "vat_reacquisition_date": reacq_date,
    "months_since_loss": months_since,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 113 ust. 11 VAT",
    "_warnings": [sprintf("PONOWNE NABYCIE ZWOLNIENIA VAT — upłynęło %d miesięcy od utraty (wymagane 12). Możesz wrócić do zwolnienia od %s jeśli sprzedaż < 200k.", [months_since, reacq_date])]
} {
    input.jdg_entrepreneur.vat_status == "ACTIVE"
    months_since := object.get(input.jdg_entrepreneur, "months_since_vat_exemption_loss", 0)
    months_since >= 12
    annual_turnover := object.get(input.jdg_entrepreneur, "annual_turnover_net", 0)
    annual_turnover < 200000
    reacq_date := "następny miesiąc"
}

# R0589: vat_exemption_pro_rata_new_jdg_full — Dokładne wyliczenie pro-rata (V.50 szczegółowe)
else := {
    "matched": true, "rule_id": "jdg.edge_cases.vat_pro_rata_detailed",
    "package": "jdg.edge_cases", "priority": 589,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pro_rata_limit": pro_rata, "ceidg_days_active": days_active,
    "vat_exemption_limit_pln": pro_rata,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 113 ust. 9 VAT",
    "_warnings": [sprintf("NOWA JDG PRO-RATA: %d dni aktywności → limit %.2f PLN. Dni do końca roku: %d. Pełny limit 200k od następnego roku.", [days_active, pro_rata, 365 - days_active])]
} {
    input.jdg_entrepreneur.vat_status == "EXEMPT_SUBJECT"
    ceidg_date := object.get(input.jdg_entrepreneur, "ceidg_entry_date", "")
    ceidg_date != ""
    entry_ns := time.parse_ns("2006-01-02", ceidg_date)
    year_start_ns := time.parse_ns("2006-01-02", sprintf("%d-01-01", [time.now_ns() / (365 * 24 * 60 * 60 * 1000000000) + 1970]))
    days_active := floor((time.now_ns() - entry_ns) / (24 * 60 * 60 * 1000000000))
    days_active > 0
    full_limit := object.get(object.get(data.thresholds, "jdg", {}), "vat_subject_exemption_limit", 200000)
    pro_rata := floor(full_limit * days_active / 365)
}

# R0590-R0594: Stuby VAT-UE korekta i ViDA (V.27-V.29 rozszerzenie)
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_ue_correction_value", "package": "jdg.edge_cases", "priority": 590, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "vat_ue_correction_required": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Korekta VAT-UE po zmianie wartości WNT/WDT", "_legal_basis": "Art. 103 ust. 1-3 VAT", "_warnings": ["KOREKTA VAT-UE — zmiana wartości WNT/WDT. Skoryguj informację podsumowującą w ciągu 14 dni od uzyskania faktury korygującej"] } { object.get(input.invoice, "vat_ue_value_changed", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_ue_deadline_15th", "package": "jdg.edge_cases", "priority": 591, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "15th", "deadline_type": "VAT_UE", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 103 ust. 1 VAT", "_warnings": ["VAT-UE — termin 15. dnia miesiąca po transakcji WNT/WDT. Za każdy dzień opóźnienia grozi grzywna"] } { object.get(input.jdg_entrepreneur, "vat_ue_due", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_vida_transaction_reporting", "package": "jdg.edge_cases", "priority": 592, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "vida_reporting": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "ViDA — raportowanie transakcji transgranicznych", "_legal_basis": "Dyrektywa ViDA 2025 (DAC8)", "_warnings": ["ViDA — transakcje transgraniczne > 2 000 EUR przez platformy cyfrowe podlegają raportowaniu DAC8. Termin: 31 stycznia następnego roku"] } { object.get(input.jdg_entrepreneur, "vida_reportable", false) == true }

# R0593a: ksef_foreign_nip_exclusion — Wykluczenie KSeF dla zagranicznego NIP (T8.4 Phase 5)
# Podstawa: Art. 106na ust. 7 VAT — KSeF nie dotyczy faktur dla podmiotów
# nieposiadających polskiego NIP (kontrahenci zagraniczni).
# Ta reguła działa jako PRE-PROCESOR — wyprzedza P593 (ksef_mandatory).
# Priorytet 5925 = konwencja "592.5" (między P592 a P593). W else-chain
# kolejność w pliku decyduje o first-match-wins, nie pole priority.
else := {
    "matched": true, "rule_id": "jdg.edge_cases.ksef_foreign_nip_exclusion",
    "package": "jdg.edge_cases", "priority": 5925,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_required": false, "ksef_exclusion": "FOREIGN_BUYER_NIP",
    "_routing": "", "_routing_reason": "KSeF wyłączony — kontrahent zagraniczny (brak PL NIP)",
    "_legal_basis": "Art. 106na ust. 7 VAT",
    "_warnings": [sprintf("KSeF WYŁĄCZENIE — kontrahent z %s nie posiada PL NIP. KSeF dotyczy wyłącznie podmiotów z polskim NIP (Art. 106na ust. 7 VAT). Faktura NIE wymaga KSeF.", [vendor_country])]
} {
    object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026) >= 2026
    input.invoice.document_type == "INVOICE"
    input.invoice.direction == "SALE"
    vendor_country := object.get(input.vendor, "country", "PL")
    vendor_country != "PL"
    vendor_nip := object.get(input.vendor, "nip", "")
    not startswith(vendor_nip, "PL")
}

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_ksef_mandatory_from_2026", "package": "jdg.edge_cases", "priority": 593, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "ksef_mandatory": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "KSeF obowiązkowy — faktura poza KSeF = sankcja 100% VAT", "_legal_basis": "Art. 106na VAT", "_warnings": ["KSeF OBOWIĄZKOWY — od 01.02.2026 wszystkie faktury B2B przez KSeF. Ta faktura NIE przeszła przez KSeF. Ryzyko: sankcja 100%% VAT (max 500k PLN)!"] } { object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026) >= 2026; input.invoice.document_type == "INVOICE"; object.get(input.invoice, "ksef_sent", true) == false; input.invoice.direction == "SALE" }

else := { "matched": true, "rule_id": "jdg.edge_cases.vat_cross_border_oss_ioss", "package": "jdg.edge_cases", "priority": 594, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "oss_ioss_applicable": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "OSS/IOSS — sprzedaż B2C do innych krajów UE", "_legal_basis": "Art. 130a-130d VAT (OSS), Art. 138a-138j VAT (IOSS)", "_warnings": ["OSS/IOSS — sprzedaż B2C do UE > 10 000 EUR. Zarejestruj w OSS aby rozliczać VAT w PL zamiast w każdym kraju UE osobno"] } { object.get(input.jdg_entrepreneur, "b2c_eu_sales_above_10k_eur", false) == true }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA E: R0595-R0612 — PIT EDGE CASES ROZSZERZONE (18 reguł)            ║
# ║  Likwidacja JDG, zmiana formy, IP Box, wynajem, ulgi                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_closure_loss_carry", "package": "jdg.edge_cases", "priority": 595, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "loss_on_closure": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Strata przy likwidacji JDG — NIE przechodzi na następcę", "_legal_basis": "Art. 9 ust. 3 i 5 PIT", "_warnings": ["LIKWIDACJA JDG — nierozliczona strata PRZEPADA. Nie przechodzi na następcę prawnego ani na działalność prywatną. Rozlicz max w zeznaniu końcowym!"] } { object.get(input.jdg_entrepreneur, "business_closure_in_progress", false) == true; object.get(input.jdg_entrepreneur, "has_unresolved_losses", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_tax_form_change_midyear", "package": "jdg.edge_cases", "priority": 596, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "tax_form_change_blocked": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zmiana formy opodatkowania NIEMOŻLIWA w trakcie roku", "_legal_basis": "Art. 9a ust. 2-3 PIT, Art. 30c ust. 1 PIT", "_warnings": ["ZMIANA FORMY OPODATKOWANIA — NIEMOŻLIWA w trakcie roku. Wyboru na kolejny rok dokonaj do 20 lutego (PIT), 20 stycznia (liniowy). Do 20. dnia miesiąca następującego po pierwszym przychodzie (ryczałt)"] } { object.get(input.jdg_entrepreneur, "tax_form_change_requested_midyear", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_rental_jdg_vs_private", "package": "jdg.edge_cases", "priority": 597, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "rental_misclassification_risk": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Wynajem — rozdziel JDG vs prywatny", "_legal_basis": "Art. 10 ust. 1 pkt 3 i 6 PIT", "_warnings": ["WYNAJEM — JDG: skala/liniowy + składki ZUS. Najem prywatny: ryczałt 8.5%% / 12.5%%, bez ZUS (od dochodu). Konieczność rozdzielenia dla US!"] } { object.get(input.jdg_entrepreneur, "rental_misclassification_risk", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_bad_debt_art26a", "package": "jdg.edge_cases", "priority": 598, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "pit_bad_debt_eligible": true, "bad_debt_days_due": days_overdue, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Ulga na złe długi PIT — Art. 26a", "_legal_basis": "Art. 26a PIT", "_warnings": [sprintf("ULGA NA ZŁE DŁUGI PIT — wierzytelność nieściągalna, %d dni po terminie. Warunki: (1) uprawdopodobnienie nieściągalności, (2) min. 120 dni, (3) nieprzedawniona. Odliczenie od dochodu w zeznaniu rocznym", [days_overdue])] } { input.invoice.direction == "SALE"; input.invoice.is_paid == false; days_overdue := object.get(input.invoice, "days_overdue", 0); days_overdue >= 120; object.get(input.invoice, "bad_debt_documented", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_ip_box_loss", "package": "jdg.edge_cases", "priority": 599, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "ip_box_loss_impact": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "IP Box — strata z kwalifikowanych IP", "_legal_basis": "Art. 30ca ust. 6-7 PIT", "_warnings": ["IP BOX — strata z kwalifikowanych praw własności intelektualnej. Strata obniża dochód z IP Box w kolejnych 5 latach (FIFO). Tylko w ramach IP Box. NIE obniża innych dochodów JDG!"] } { object.get(input.jdg_entrepreneur, "ip_box_eligible", false) == true; object.get(input.jdg_entrepreneur, "ip_box_annual_loss", 0) > 0 }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_foreign_tax_credit_limit", "package": "jdg.edge_cases", "priority": 600, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "foreign_tax_credit_capped": true, "ftc_limit": ftc_limit, "foreign_tax_paid": ft_paid, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 27 ust. 8-9 PIT", "_warnings": [sprintf("ULGA ZAGRANICZNA — limit %.2f PLN. Zapłacony podatek za granicą: %.2f PLN. Odliczenie max do limitu. Nadwyżka NIE przechodzi na kolejne lata.", [ftc_limit, ft_paid])] } { ft_paid := object.get(input.jdg_entrepreneur, "foreign_tax_paid_pln", 0); ft_paid > 0; pl_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0); foreign_income := object.get(input.jdg_entrepreneur, "foreign_income", 0); total_income := pl_income + foreign_income; total_income > 0; ftc_limit := floor(pl_income * ft_paid / total_income * 100) / 100 }

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_health_lump_sum_tier", "package": "jdg.edge_cases", "priority": 601, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "health_tier_calculated": true, "health_monthly_amount": health_amount, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 81 ust. 2e ustawy o świadczeniach", "_warnings": [sprintf("RYCZAŁT — składka zdrowotna: %.2f PLN/mies. Przychód %.2f PLN = próg %.0f PLN. Roczne rozliczenie do 22 maja.", [health_amount, annual_rev, health_tier])] } { input.jdg_entrepreneur.tax_form == "LUMP_SUM"; annual_rev := object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0); annual_rev > 0; health_amount = 419.46 { annual_rev <= 60000 }; health_amount = 699.11 { annual_rev > 60000; annual_rev <= 300000 }; health_amount = 1258.39 { annual_rev > 300000 }; health_tier = 60000 { annual_rev <= 60000 }; health_tier = 300000 { annual_rev > 60000; annual_rev <= 300000 }; health_tier = 0 { annual_rev > 300000 } }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA D2: R0602-R0612 — KONFLIKTY & INTERAKCJE (11 reguł)                ║
# ║  Zawieszenie, dział. nieewidencj., zdrowotna, ZUS, leasing, home office   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# R0602: suspension_vs_income_generation — Zawieszenie ≠ przychody
else := { "matched": true, "rule_id": "jdg.edge_cases.suspension_vs_income_generation", "package": "jdg.edge_cases", "priority": 602, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "suspension_violation": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zawieszenie JDG — nie można wystawiać faktur sprzedażowych", "_legal_basis": "Art. 22-25 Prawa przedsiębiorców", "_warnings": ["ZAWIESZENIE JDG — NIE można wystawiać faktur sprzedażowych! Naruszenie = wykreślenie zawieszenia z mocą wsteczną."] } { object.get(input.jdg_entrepreneur, "business_suspended", false) == true; input.invoice.direction == "SALE" }

# R0603: unregistered_vs_vat_deduction — Działalność nieewidencjonowana ≠ VAT
else := { "matched": true, "rule_id": "jdg.edge_cases.unregistered_vs_vat_deduction", "package": "jdg.edge_cases", "priority": 603, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "unregistered_vat_blocked": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Działalność nieewidencjonowana — NIE wystawiaj faktur VAT", "_legal_basis": "Art. 5 Prawa przedsiębiorców, Art. 113 VAT", "_warnings": ["DZIAŁALNOŚĆ NIEEWIDENCJONOWANA — zwolniona z VAT. Nie wystawiaj faktur VAT! Przychód < 50% minimalnego wynagrodzenia."] } { object.get(input.jdg_entrepreneur, "activity_type", "") == "UNREGISTERED"; input.invoice.vat_rate != "" }

# R0604: health_scale_loss_year — Strata → minimalna zdrowotna
else := { "matched": true, "rule_id": "jdg.edge_cases.health_scale_loss_year", "package": "jdg.edge_cases", "priority": 604, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "0.09", "business_status": "", "ceidg_registration_required": false, "health_from_minimum_base": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych", "_warnings": ["STRATA → składka zdrowotna od MINIMALNEJ podstawy, nie od dochodu. 9% od 75% przeciętnego wynagrodzenia."] } { input.jdg_entrepreneur.tax_form == "SCALE"; annual_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 999999); annual_income <= 0 }

# R0605: zus_start_vs_preferential — Start i preferencyjny NIE jednocześnie
else := { "matched": true, "rule_id": "jdg.edge_cases.zus_start_vs_preferential", "package": "jdg.edge_cases", "priority": 605, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "dual_relief_blocked": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Ulga na start + preferencyjny — NIE jednocześnie", "_legal_basis": "Art. 18a ust. 1 SUS", "_warnings": ["Ulga na start i preferencyjny ZUS NIE mogą być stosowane jednocześnie! Kolejność: start (6m) → preferencyjny (24m)."] } { object.get(input.jdg_entrepreneur, "zus_start_relief_active", false) == true; object.get(input.jdg_entrepreneur, "zus_preferential_active", false) == true }

# R0606: zus_maly_plus_vs_preferential — Mały ZUS+ dopiero PO preferencyjnym
else := { "matched": true, "rule_id": "jdg.edge_cases.zus_maly_plus_vs_preferential", "package": "jdg.edge_cases", "priority": 606, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "dual_relief_blocked": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Mały ZUS+ + preferencyjny — NIE jednocześnie", "_legal_basis": "Art. 18a i 18c SUS", "_warnings": ["Mały ZUS+ dopiero PO preferencyjnym. Nie można łączyć! Max 60 mies. obniżonych składek: 24 prefer. + 36 mały+."] } { object.get(input.jdg_entrepreneur, "zus_maly_plus_active", false) == true; object.get(input.jdg_entrepreneur, "zus_preferential_active", false) == true }

# R0607: car_leasing_vs_buy_kup_limit — Limit 150k dla auta (leasing = zakup)
else := { "matched": true, "rule_id": "jdg.edge_cases.car_leasing_vs_buy_kup_limit", "package": "jdg.edge_cases", "priority": 607, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "car_kup_limit_applies": true, "car_value": car_value, "car_kup_limit": car_limit, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Auto >150k — nadwyżka NKUP (leasing = zakup)", "_legal_basis": "Art. 23 ust. 1 pkt 47a i 47b PIT", "_warnings": [sprintf("AUTO %.0f PLN > limit KUP %.0f PLN — nadwyżka NKUP. Dotyczy zarówno zakupu jak i leasingu!", [car_value, car_limit]) ] } { car_value := object.get(input.jdg_entrepreneur, "car_acquisition_value", 0); car_value > 0; is_ev := object.get(input.jdg_entrepreneur, "car_is_electric", false); car_limit = 225000 { is_ev == true }; car_limit = 150000 { is_ev == false }; car_value > car_limit; input.invoice.expense_type in {"CAR_LEASE", "CAR_DEPRECIATION"} }

# R0608: home_office_vs_exclusive_business — Home office ≠ 100% KUP
else := { "matched": true, "rule_id": "jdg.edge_cases.home_office_vs_exclusive_business", "package": "jdg.edge_cases", "priority": 608, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "PROPORTIONAL", "kus_percent": kup_pct, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "home_office_proportional": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Home office mieszane — KUP proporcjonalny", "_legal_basis": "Art. 22 ust. 1 PIT", "_warnings": [sprintf("HOME OFFICE MIESZANE — KUP %.0f%% (powierzchnia biurowa / całkowita). Nie 100%%!", [kup_pct]) ] } { input.invoice.expense_type == "HOME_OFFICE"; office_sqm := object.get(input.jdg_entrepreneur, "home_office_sqm", 0); total_sqm := object.get(input.jdg_entrepreneur, "home_total_sqm", 1); total_sqm > 0; kup_pct := floor(office_sqm * 100 / total_sqm); kup_pct < 100; object.get(input.jdg_entrepreneur, "home_office_exclusive", false) == false }

# R0609: bad_debt_90_days — Złe długi po 90 dniach (VAT i PIT zharmonizowane SLIM VAT 3/2023)
else := { "matched": true, "rule_id": "jdg.edge_cases.bad_debt_90_days", "package": "jdg.edge_cases", "priority": 609, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "bad_debt_timeline": true, "days_overdue": days_overdue, "pit_action": "KOREKTA KUP", "vat_action": "ULGA — korekta VAT", "debtor_action": "KOREKTA VAT OBOWIĄZKOWA!", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Złe długi — korekta VAT i PIT po 90 dniach", "_legal_basis": "Art. 89a-89b VAT, Art. 26i PIT (SLIM VAT 3/2023)", "_warnings": [sprintf("ZŁE DŁUGI %d dni — PIT: korekta KUP | VAT wierzyciel: ulga | VAT dłużnik: obowiązek korekty", [days_overdue]) ] } { input.invoice.is_paid == false; days_overdue := object.get(input.invoice, "days_overdue", 0); days_overdue >= 90 }

# R0609a: cash_method_receivable_buffer_guard — Metoda kasowa C3 anti-bankruptcy (T8.3 Phase 5)
# Cel: Przy metodzie kasowej przychód rozpoznawany jest dopiero w dacie zapłaty.
# Jeśli zbyt wiele faktur pozostaje nieopłaconych, JDG ma wydatki ale brak
# rozpoznanego przychodu → ryzyko utraty płynności i bankructwa.
# Ta reguła monitoruje bufor nieopłaconych należności i alarmuje, gdy
# przekracza on bezpieczny próg (50% rocznego przychodu).
# Powiązanie: P184 (obowiązek korekty dłużnika) + Art. 89a-89b VAT.
# Priorytet 6095 = konwencja "609.5" (między R0609 a R0610).
else := {
    "matched": true, "rule_id": "jdg.edge_cases.cash_method_receivable_buffer_guard",
    "package": "jdg.edge_cases", "priority": 6095,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cash_method_buffer_exceeded": true,
    "unpaid_receivables_pln": unpaid_total,
    "unpaid_receivables_pct": buffer_pct,
    "cash_method_active": true,
    "related_rule_p184": "jdg.vat.deductions.bad_debt_debtor_mandatory",
    "_routing": routing_flag,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 21 VAT (metoda kasowa), Art. 89a-89b VAT (złe długi), Art. 21 Prawa upadłościowego",
    "_warnings": [sprintf("METODA KASOWA — BUFOR NALEŻNOŚCI PRZEKROCZONY! Nieopłacone faktury: %.2f PLN (%.0f%% rocznego przychodu). Ryzyko utraty płynności! Przy metodzie kasowej przychód rozpoznawany dopiero przy zapłacie. Ogranicz wystawianie faktur z odroczonym terminem. Powiązane: P184 — obowiązek korekty VAT dłużnika po 90 dniach.", [unpaid_total, buffer_pct])]
} {
    object.get(input.jdg_entrepreneur, "vat_cash_accounting", false) == true
    unpaid_total := object.get(input.jdg_entrepreneur, "unpaid_receivables_total", 0)
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)
    annual_revenue > 0
    buffer_pct := floor(unpaid_total * 100 / annual_revenue)
    buffer_pct >= 50
    routing_flag = "TRIAGE_QUEUE" { buffer_pct < 80 }
    routing_flag = "BLOCK_AND_ALERT" { buffer_pct >= 80 }
    routing_reason = "Metoda kasowa — bufor >50%: ryzyko płynności" { buffer_pct < 80 }
    routing_reason = "Metoda kasowa — bufor >80%: KRYTYCZNE ryzyko bankructwa!" { buffer_pct >= 80 }
}

# R0610: fx_method_podatkowa_vs_bilansowa — Mieszanie metod FX
else := { "matched": true, "rule_id": "jdg.edge_cases.fx_method_podatkowa_vs_bilansowa", "package": "jdg.edge_cases", "priority": 610, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "fx_method_conflict": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Mieszanie metod FX — podatkowa vs bilansowa", "_legal_basis": "Art. 14c PIT, Art. 30 UoR", "_warnings": ["MIESZANIE METOD FX w jednym roku — wybierz PODATKOWĄ (Art. 14c PIT) lub BILANSOWĄ (Art. 30 UoR) na cały rok!"] } { object.get(input.jdg_entrepreneur, "fx_method_podatkowa_used", false) == true; object.get(input.jdg_entrepreneur, "fx_method_bilansowa_used", false) == true }

# R0611: inventory_fifo_vs_weighted_average — Podatkowo tylko FIFO
else := { "matched": true, "rule_id": "jdg.edge_cases.inventory_fifo_vs_weighted_average", "package": "jdg.edge_cases", "priority": 611, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "fifo_required": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Do celów podatkowych wymagana metoda FIFO", "_legal_basis": "Art. 24 ust. 2 PIT", "_warnings": ["Do celów podatkowych WYMAGANA metoda FIFO przy rozchodzie towarów. Średnia ważona tylko bilansowo!"] } { object.get(input.jdg_entrepreneur, "inventory_method", "") == "WEIGHTED_AVERAGE"; object.get(input.jdg_entrepreneur, "inventory_for_tax_purposes", false) == true }

# R0612: donation_limit_6pct_aggregate — Łączny limit darowizn
else := { "matched": true, "rule_id": "jdg.edge_cases.donation_limit_6pct_aggregate", "package": "jdg.edge_cases", "priority": 612, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "donation_aggregate_limit": agg_limit, "donation_total": agg_total, "donation_excess": agg_total - agg_limit, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 26 ust. 1 pkt 9 PIT", "_warnings": [sprintf("ŁĄCZNY LIMIT DAROWIZN 6%% dochodu: %.2f PLN. Suma OPP+kościół+krew: %.2f PLN. Nadwyżka %.2f PLN PRZEPADA!", [agg_limit, agg_total, agg_total - agg_limit]) ] } { income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0); income > 0; agg_limit := floor(income * 0.06 * 100) / 100; opp := object.get(input.jdg_entrepreneur, "donation_opp_amount", 0); church := object.get(input.jdg_entrepreneur, "donation_church_amount", 0); blood := object.get(input.jdg_entrepreneur, "donation_blood_value", 0); agg_total := opp + church + blood; agg_total > agg_limit }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA E: R0613-R0622 — WALIDACJE DANYCH (10 reguł)                       ║
# ║  NIP, IBAN, REGON, daty, kwoty, stawki, numeracja                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# R0613: nip_checksum_pl — Suma kontrolna NIP
else := { "matched": true, "rule_id": "jdg.edge_cases.nip_checksum_pl", "package": "jdg.edge_cases", "priority": 613, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "nip_invalid_checksum": true, "nip_entered": nip_raw, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "NIP — błędna suma kontrolna", "_legal_basis": "Art. 96b VAT, Rozp. MF ws. NIP", "_warnings": [sprintf("NIP %s — BŁĘDNA suma kontrolna! Wagi 6,5,7,2,3,4,5,6,7, mod 11. Jeśli wynik=10 → NIP NIEWAŻNY.", [nip_raw]) ] } { nip_raw := object.get(input.vendor, "nip", ""); nip_raw != ""; nip_len := count(nip_raw); nip_len == 10; nip_num := to_number(nip_raw); nip_num > 0; d1 := to_number(substring(nip_raw, 0, 1)); d2 := to_number(substring(nip_raw, 1, 1)); d3 := to_number(substring(nip_raw, 2, 1)); d4 := to_number(substring(nip_raw, 3, 1)); d5 := to_number(substring(nip_raw, 4, 1)); d6 := to_number(substring(nip_raw, 5, 1)); d7 := to_number(substring(nip_raw, 6, 1)); d8 := to_number(substring(nip_raw, 7, 1)); d9 := to_number(substring(nip_raw, 8, 1)); d10 := to_number(substring(nip_raw, 9, 1)); checksum := (6*d1 + 5*d2 + 7*d3 + 2*d4 + 3*d5 + 4*d6 + 5*d7 + 6*d8 + 7*d9) % 11; checksum != d10 }

# R0614: iban_checksum_pl — Walidacja IBAN PL
else := { "matched": true, "rule_id": "jdg.edge_cases.iban_checksum_pl", "package": "jdg.edge_cases", "priority": 614, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "iban_invalid": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "IBAN — nieprawidłowy format lub suma kontrolna", "_legal_basis": "Regulacja UE 260/2012 (SEPA)", "_warnings": ["IBAN — nieprawidłowy format. IBAN PL musi mieć 28 znaków: PL + 26 cyfr. Suma kontrolna mod 97 = 1."] } { iban := object.get(input.vendor, "iban", ""); iban != ""; not startswith(iban, "PL"); count(iban) != 28  # uproszczona walidacja: prefix PL + 28 znaków (pełny mod 97 wymaga big-int) }

# R0615: regon_9digit — Walidacja REGON
else := { "matched": true, "rule_id": "jdg.edge_cases.regon_9digit", "package": "jdg.edge_cases", "priority": 615, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "regon_invalid": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "REGON — błędna suma kontrolna", "_legal_basis": "Rozp. GUS ws. REGON", "_warnings": ["REGON — błędna suma kontrolna. Wagi: 8,9,2,3,4,5,6,7, mod 11."] } { regon := object.get(input.vendor, "regon", ""); count(regon) == 9; regon_num := to_number(regon); d1 := to_number(substring(regon, 0, 1)); d2 := to_number(substring(regon, 1, 1)); d3 := to_number(substring(regon, 2, 1)); d4 := to_number(substring(regon, 3, 1)); d5 := to_number(substring(regon, 4, 1)); d6 := to_number(substring(regon, 5, 1)); d7 := to_number(substring(regon, 6, 1)); d8 := to_number(substring(regon, 7, 1)); d9 := to_number(substring(regon, 8, 1)); cs := (8*d1 + 9*d2 + 2*d3 + 3*d4 + 4*d5 + 5*d6 + 6*d7 + 7*d8) % 11; expected_d9 = 0 { cs == 10 }; expected_d9 = cs { cs != 10 }; expected_d9 != d9 }

# R0616: invoice_date_consistency — Data faktury ≥ data sprzedaży
else := { "matched": true, "rule_id": "jdg.edge_cases.invoice_date_consistency", "package": "jdg.edge_cases", "priority": 616, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "date_inconsistent": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Data faktury wcześniejsza niż data sprzedaży", "_legal_basis": "Art. 106e VAT", "_warnings": ["DATA NIESPÓJNA — data wystawienia faktury przed datą sprzedaży. Chyba że faktura zaliczkowa."] } { issue_date := object.get(input.invoice, "issue_date", ""); sale_date := object.get(input.invoice, "sale_date", ""); issue_date != ""; sale_date != ""; issue_date < sale_date; object.get(input.invoice, "prepayment_received", false) == false }

# R0617: date_not_future — Data nie może być w przyszłości
else := { "matched": true, "rule_id": "jdg.edge_cases.date_not_future", "package": "jdg.edge_cases", "priority": 617, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "future_date_detected": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Data faktury w przyszłości", "_legal_basis": "Art. 106e VAT", "_warnings": ["DATA W PRZYSZŁOŚCI — data faktury nie może być późniejsza niż dzisiaj!"] } { inv_date := object.get(input.invoice, "issue_date", ""); inv_date != ""; now_ns := time.now_ns(); inv_ns := time.parse_ns("2006-01-02", inv_date); inv_ns > now_ns }

# R0618: date_after_1990 — Data nie może być sprzed 1990
else := { "matched": true, "rule_id": "jdg.edge_cases.date_after_1990", "package": "jdg.edge_cases", "priority": 618, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "suspicious_date": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Data sprzed 1990 — prawdopodobny błąd OCR", "_legal_basis": "Art. 106e VAT", "_warnings": ["PODEJRZANA DATA — sprzed 1990 roku. Prawdopodobny błąd OCR (rok 1926 zamiast 2026)."] } { inv_date := object.get(input.invoice, "issue_date", ""); inv_date != ""; inv_date < "1990-01-01" }

# R0619: amount_non_negative — Kwoty nieujemne (chyba że korekta)
else := { "matched": true, "rule_id": "jdg.edge_cases.amount_non_negative", "package": "jdg.edge_cases", "priority": 619, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "negative_amount_invalid": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Kwota ujemna na zwykłej fakturze", "_legal_basis": "Art. 106e VAT", "_warnings": ["KWOTA UJEMNA — zwykła faktura nie może mieć ujemnych kwot. Użyj faktury korygującej!"] } { object.get(input.invoice, "amount_net", 0) < 0; input.invoice.document_type != "CORRECTION_INVOICE" }

# R0620: vat_rate_valid — Walidacja stawki VAT
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_rate_valid", "package": "jdg.edge_cases", "priority": 620, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "invalid_vat_rate": true, "vat_rate_used": vat_rate_val, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Nieprawidłowa stawka VAT", "_legal_basis": "Art. 41 VAT", "_warnings": [sprintf("NIEPRAWIDŁOWA STAWKA VAT: %s. Dozwolone: ZW, 0%%, 5%%, 8%%, 23%%.", [vat_rate_val]) ] } { vat_rate_val := object.get(input.invoice, "vat_rate", ""); vat_rate_val != ""; not vat_rate_val in {"0.00", "0.05", "0.08", "0.23", "ZW"} }

# R0621: pkpir_column_consistency — Spójność kolumn PKPiR
else := { "matched": true, "rule_id": "jdg.edge_cases.pkpir_column_consistency", "package": "jdg.edge_cases", "priority": 621, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "pkpir_inconsistent": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Niespójność kolumn PKPiR", "_legal_basis": "Rozp. MF ws. PKPiR", "_warnings": ["PKPiR NIESPÓJNY — suma kolumn 7+8+9 ≠ 10+11+12+13. Sprawdź ewidencję!"] } { k7 := object.get(input.invoice, "pkpir_kol7", 0); k8 := object.get(input.invoice, "pkpir_kol8", 0); k9 := object.get(input.invoice, "pkpir_kol9", 0); k10 := object.get(input.invoice, "pkpir_kol10", 0); k11 := object.get(input.invoice, "pkpir_kol11", 0); k12 := object.get(input.invoice, "pkpir_kol12", 0); k13 := object.get(input.invoice, "pkpir_kol13", 0); (k7 + k8 + k9) != (k10 + k11 + k12 + k13) }

# R0622: invoice_numbering_continuity — Ciągłość numeracji faktur
else := { "matched": true, "rule_id": "jdg.edge_cases.invoice_numbering_continuity", "package": "jdg.edge_cases", "priority": 622, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "numbering_gap_detected": true, "gap_size": gap, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Luka w numeracji faktur", "_legal_basis": "Art. 106e VAT", "_warnings": [sprintf("LUKA W NUMERACJI — brak %d numerów między fakturami. Może wskazywać na ukryte faktury.", [gap]) ] } { curr_num := object.get(input.invoice, "invoice_number", 0); prev_num := object.get(input.jdg_entrepreneur, "last_invoice_number", 0); prev_num > 0; curr_num > prev_num; gap := curr_num - prev_num; gap > 1 }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA G: R0646-R0655 — SANKCJE (10 reguł)                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

else := { "matched": true, "rule_id": "jdg.edge_cases.sanction_jpk_error_500", "package": "jdg.edge_cases", "priority": 646, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sanction_amount": 500, "sanction_type": "JPK_VAT_ERROR", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Błąd JPK_VAT — sankcja 500 PLN", "_legal_basis": "Art. 109 VAT", "_warnings": ["SANKCJA 500 PLN — błąd w JPK_VAT uniemożliwiający weryfikację"] } { object.get(input.jdg_entrepreneur, "jpk_vat_contains_errors", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.sanction_ksef_missing_100pct", "package": "jdg.edge_cases", "priority": 647, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sanction_type": "KSEF_MISSING", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak KSeF — sankcja 100% VAT", "_legal_basis": "Art. 106nq VAT", "_warnings": ["SANKCJA 100% VAT (max 500k) — brak faktury w KSeF mimo obowiązku!"] } { object.get(input.jdg_entrepreneur, "ksef_missing_mandatory", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.sanction_late_filing_vat_500_5000", "package": "jdg.edge_cases", "priority": 648, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sanction_type": "LATE_FILING", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Spóźniona deklaracja — grzywna 500-5000 PLN", "_legal_basis": "Art. 77-79 KKS", "_warnings": ["Spóźniona deklaracja podatkowa — grzywna 500-5 000 PLN"] } { object.get(input.jdg_entrepreneur, "late_filing_detected", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.sanction_unregistered_activity", "package": "jdg.edge_cases", "priority": 649, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sanction_type": "UNREGISTERED", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Działalność bez CEIDG", "_legal_basis": "Art. 60¹ KKS", "_warnings": ["Działalność gospodarcza bez rejestracji CEIDG — wykroczenie skarbowe + grzywna!"] } { object.get(input.jdg_entrepreneur, "activity_without_ceidg", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.sanction_mpp_violation_30pct", "package": "jdg.edge_cases", "priority": 650, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sanction_type": "MPP_VIOLATION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak MPP — sankcja 30% VAT", "_legal_basis": "Art. 108a VAT", "_warnings": ["SANKCJA 30% VAT + solidarna odpowiedzialność — brak split payment przy obowiązku!"] } { object.get(input.invoice, "mpp_violation_detected", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.sanction_whitelist_transfer", "package": "jdg.edge_cases", "priority": 651, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sanction_type": "WHITELIST_VIOLATION", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Przelew poza Białą Listą", "_legal_basis": "Art. 117ba OrdPU", "_warnings": ["Solidarna odpowiedzialność za VAT — przelew na rachunek spoza Białej Listy!"] } { object.get(input.invoice, "whitelist_violation", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.sanction_bad_debt_debtor_30pct", "package": "jdg.edge_cases", "priority": 652, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sanction_type": "BAD_DEBT_DEBTOR", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak korekty złych długów — sankcja 30%", "_legal_basis": "Art. 89b VAT", "_warnings": ["SANKCJA 30% VAT — dłużnik nie skorygował VAT po 90 dniach od terminu płatności!"] } { object.get(input.invoice, "bad_debt_debtor_violation", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.sanction_cash_over_15k_kup_loss", "package": "jdg.edge_cases", "priority": 653, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "NKUP", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sanction_type": "CASH_LIMIT", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Gotówka >15k PLN — NKUP", "_legal_basis": "Art. 22p PIT", "_warnings": ["Płatność gotówką >15 000 PLN → NKUP! Dodatkowo 20% sankcji."] } { object.get(input.invoice, "cash_over_15k_violation", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.sanction_dac7_non_reporting_1m", "package": "jdg.edge_cases", "priority": 654, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sanction_type": "DAC7", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak DAC7 — kara do 1M PLN", "_legal_basis": "Art. 39q OrdPU", "_warnings": ["Brak raportu DAC7 — kara do 1 000 000 PLN!"] } { object.get(input.jdg_entrepreneur, "dac7_not_filed", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.sanction_mdr_non_reporting", "package": "jdg.edge_cases", "priority": 655, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "sanction_type": "MDR", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak MDR — kara do 720 stawek KKS", "_legal_basis": "Art. 86f OrdPU", "_warnings": ["Brak zgłoszenia MDR — kara do 720 stawek dziennych KKS!"] } { object.get(input.jdg_entrepreneur, "mdr_not_reported", false) == true }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA H: R0656-R0672 — TERMINY / DEADLINES (17 reguł)                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_vat_declaration_25th", "package": "jdg.edge_cases", "priority": 656, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "25th", "deadline_type": "VAT_MONTHLY", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 99 VAT", "_warnings": ["VAT-7/JPK_V7 — termin 25. dnia miesiąca"] } { object.get(input.jdg_entrepreneur, "vat_monthly_filer", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_vat_quarterly_25th", "package": "jdg.edge_cases", "priority": 657, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "25th_after_quarter", "deadline_type": "VAT_QUARTERLY", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 99 VAT", "_warnings": ["VAT kwartalny — termin 25. dnia po zakończeniu kwartału"] } { object.get(input.jdg_entrepreneur, "vat_quarterly_filer", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_pit_advance_20th", "package": "jdg.edge_cases", "priority": 658, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "20th", "deadline_type": "PIT_ADVANCE", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 44 PIT", "_warnings": ["Zaliczka PIT — termin 20. dnia miesiąca"] } { object.get(input.jdg_entrepreneur, "pit_monthly_advance_due", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_pit_annual_april30", "package": "jdg.edge_cases", "priority": 659, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "APRIL_30", "deadline_type": "PIT_ANNUAL", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 45 PIT", "_warnings": ["PIT-36/PIT-36L — termin 30 kwietnia"] } { object.get(input.jdg_entrepreneur, "pit_annual_due", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_pit28_february28", "package": "jdg.edge_cases", "priority": 660, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT28", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "FEBRUARY_28", "deadline_type": "PIT28", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 21 ustawy o ryczałcie", "_warnings": ["PIT-28 (ryczałt) — termin 28 lutego"] } { object.get(input.jdg_entrepreneur, "pit28_due", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_zus_payment_10th", "package": "jdg.edge_cases", "priority": 661, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "10th", "deadline_type": "ZUS_STANDARD", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 47 SUS", "_warnings": ["ZUS standard — termin 10. dnia miesiąca"] } { object.get(input.jdg_entrepreneur, "zus_payment_due", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_zus_payment_15th", "package": "jdg.edge_cases", "priority": 662, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "15th", "deadline_type": "ZUS_UNITS", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 47 SUS", "_warnings": ["ZUS jednostki budżetowe — termin 15. dnia miesiąca"] } { object.get(input.jdg_entrepreneur, "zus_payment_15th_due", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_whitelist_verification_30days", "package": "jdg.edge_cases", "priority": 663, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "30_DAYS", "deadline_type": "WHITELIST_VERIFY", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 96b VAT", "_warnings": ["Biała Lista — weryfikuj rachunek co 30 dni + 3 dni buforu na przelew"] } { object.get(input.jdg_entrepreneur, "whitelist_verification_needed", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_correction_vat_3_months", "package": "jdg.edge_cases", "priority": 665, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "3_MONTHS", "deadline_type": "VAT_CORRECTION", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 86 VAT", "_warnings": ["Korekta VAT — 3 miesiące na korektę odliczenia. Po terminie → tylko w zeznaniu rocznym"] } { object.get(input.jdg_entrepreneur, "vat_correction_window_open", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_ksef_offline_7_days", "package": "jdg.edge_cases", "priority": 666, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "7_DAYS", "deadline_type": "KSEF_OFFLINE", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 106ne VAT", "_warnings": ["Awaria KSeF — 7 dni na przesłanie faktur poza KSeF"] } { object.get(input.jdg_entrepreneur, "ksef_offline_mode", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_tax_audit_14days_correct", "package": "jdg.edge_cases", "priority": 667, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "14_DAYS", "deadline_type": "AUDIT_CORRECTION", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 81 OrdPU", "_warnings": ["14 dni na korektę deklaracji po protokole kontroli"] } { object.get(input.jdg_entrepreneur, "audit_correction_window", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_overpayment_refund_45days", "package": "jdg.edge_cases", "priority": 668, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "45_DAYS", "deadline_type": "OVERPAYMENT_REFUND", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 78 OrdPU", "_warnings": ["Zwrot nadpłaty — US ma 45 dni. Po terminie → odsetki od US!"] } { object.get(input.jdg_entrepreneur, "overpayment_refund_pending", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_vat_r_registration_before_first", "package": "jdg.edge_cases", "priority": 671, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "BEFORE_FIRST", "deadline_type": "VAT_R", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 96 VAT", "_warnings": ["VAT-R — złóż PRZED pierwszą czynnością opodatkowaną"] } { object.get(input.jdg_entrepreneur, "vat_r_due_before_first_activity", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_whitelist_3day_buffer", "package": "jdg.edge_cases", "priority": 664, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "3_DAYS", "deadline_type": "WHITELIST_BUFFER", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 96b ust. 4a VAT", "_warnings": ["Biała Lista — 3 dni buforu na przelew od dnia weryfikacji. Po terminie → ponowna weryfikacja"] } { object.get(input.jdg_entrepreneur, "whitelist_buffer_expiring", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_annual_health_may22", "package": "jdg.edge_cases", "priority": 669, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "MAY_22", "deadline_type": "ANNUAL_HEALTH", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 81 ust. 2f ustawy o świadczeniach", "_warnings": ["Roczne rozliczenie składki zdrowotnej — termin 22 maja. Niedopłata → odsetki!"] } { object.get(input.jdg_entrepreneur, "annual_health_reconciliation_due", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_pit11_employee_feb28", "package": "jdg.edge_cases", "priority": 670, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "FEBRUARY_28", "deadline_type": "PIT11", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 39 PIT", "_warnings": ["PIT-11 dla pracowników — termin 28 lutego. Obowiązek płatnika!"] } { object.get(input.jdg_entrepreneur, "pit11_due", false) == true }

else := { "matched": true, "rule_id": "jdg.edge_cases.deadline_statute_limitations_5yr", "package": "jdg.edge_cases", "priority": 672, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "deadline": "5_YEARS", "deadline_type": "STATUTE_LIMITATIONS", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 70 OrdPU", "_warnings": ["Przedawnienie zobowiązań — 5 lat od końca roku kalendarzowego. Sprawdź terminy!"] } { object.get(input.jdg_entrepreneur, "statute_limitations_approaching", false) == true }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA I: R0673-R0690 — CROSS-BORDER / TP / CFC / ViDA (18 reguł)        ║
# ║  Ceny transferowe JDG-rodzina, CFC, ViDA, WHT, zagraniczne zakłady       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# R0673: tp_family_jdg_art23o — Ceny transferowe JDG z rodziną
else := { "matched": true, "rule_id": "jdg.edge_cases.tp_family_jdg", "package": "jdg.edge_cases", "priority": 673, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "tp_family_triggered": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Ceny transferowe — transakcja z podmiotem powiązanym (rodzina)", "_legal_basis": "Art. 23o-23zf PIT", "_warnings": ["CENY TRANSFEROWE — transakcja z podmiotem powiązanym (rodzina). Obowiązek dokumentacji TP jeśli wartość > próg. JDG + małżonek/dziecko jako kontrahent = ryzyko szacowania dochodu przez US!"] } { object.get(input.jdg_entrepreneur, "related_party_transaction", false) == true; object.get(input.invoice, "transaction_value", 0) > 50000 }

# R0674: tp_documentation_threshold — Próg dokumentacji TP dla JDG
else := { "matched": true, "rule_id": "jdg.edge_cases.tp_documentation_threshold", "package": "jdg.edge_cases", "priority": 674, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "tp_documentation_required": true, "tp_threshold_exceeded": tp_value, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Próg dokumentacji TP przekroczony", "_legal_basis": "Art. 23zf PIT", "_warnings": [sprintf("DOKUMENTACJA TP — transakcja %.2f PLN z podmiotem powiązanym. Obowiązek: Local File + TPR-C do 11. miesiąca po roku. Brak = kara do 720 stawek dziennych KKS!", [tp_value])] } { tp_value := object.get(input.jdg_entrepreneur, "related_party_transaction_total", 0); tp_value > 500000 }

# R0675: cfc_jdg_foreign_company — CFC — zagraniczna spółka kontrolowana przez JDG
else := { "matched": true, "rule_id": "jdg.edge_cases.cfc_foreign_company", "package": "jdg.edge_cases", "priority": 675, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "cfc_triggered": true, "cfc_country": cfc_country, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "CFC — zagraniczna spółka kontrolowana", "_legal_basis": "Art. 30f PIT", "_warnings": [sprintf("CFC — posiadasz >50%% udziałów w spółce w %s. Dochód CFC opodatkowany 19%% w PL (art. 30f PIT). Obowiązek: zeznanie PIT-CFC + załącznik do PIT-36 do 30 września!", [cfc_country])] } { object.get(input.jdg_entrepreneur, "cfc_controlled_entity", false) == true; cfc_country := object.get(input.jdg_entrepreneur, "cfc_country", "NON_EU") }

# R0676: cfc_passive_income_test — CFC test dochodu pasywnego
else := { "matched": true, "rule_id": "jdg.edge_cases.cfc_passive_income_test", "package": "jdg.edge_cases", "priority": 676, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "cfc_passive_test_passed": true, "cfc_passive_pct": passive_pct, "_routing": "TRIAGE_QUEUE", "_routing_reason": "CFC — test dochodu pasywnego", "_legal_basis": "Art. 30f ust. 3 PIT", "_warnings": [sprintf("CFC TEST PASYWNY — %.1f%% dochodów pasywnych. >33%% + CIT<14.25%% za granicą = CFC. Dochód pasywny: odsetki, należności licencyjne, dywidendy, najem", [passive_pct])] } { passive_pct := object.get(input.jdg_entrepreneur, "cfc_passive_income_pct", 0); passive_pct > 33; object.get(input.jdg_entrepreneur, "cfc_foreign_tax_rate", 25) < 14.25 }

# R0677: wht_jdg_foreign_service — Podatek u źródła od usług zagranicznych
else := { "matched": true, "rule_id": "jdg.edge_cases.wht_foreign_service", "package": "jdg.edge_cases", "priority": 677, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false,    "wht_required": true, "wht_rate": wht_rate_pct,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Podatek u źródła (WHT) od usług zagranicznych",
    "_legal_basis": "Art. 29 PIT w zw. z UPO",
    "_warnings": [sprintf("WHT — podatek u źródła %.0f%% od płatności %.2f PLN do %s. Obowiązek: IFT-2R + wpłata do US do 7. dnia następnego miesiąca. Sprawdź UPO — może być zwolnienie lub obniżona stawka", [wht_rate_pct, amount_net, vendor_country])]
} {
    input.invoice.direction == "PURCHASE"; vendor_country := object.get(input.vendor, "country", "PL"); vendor_country != "PL"; input.invoice.expense_type in {"SERVICE", "CONSULTING", "ROYALTY", "LICENSE_FEE"}; amount_net := object.get(input.invoice, "amount_net", 0); amount_net > 0; wht_rate_pct = 20 { vendor_country == "NON_EU" }; wht_rate_pct = 0 { vendor_country in eu_edge_countries } }

# R0678: wht_foreign_dividend_interest — WHT od dywidend i odsetek
else := { "matched": true, "rule_id": "jdg.edge_cases.wht_dividend_interest", "package": "jdg.edge_cases", "priority": 678, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "wht_required": true, "wht_rate": 19, "_routing": "TRIAGE_QUEUE", "_routing_reason": "WHT 19% od dywidend/odsetek z zagranicy", "_legal_basis": "Art. 30a PIT", "_warnings": ["WHT — dochody kapitałowe z zagranicy (dywidendy, odsetki, należności licencyjne). Stawka 19%% w PL. Odliczenie podatku zapłaconego za granicą wg UPO"] } { object.get(input.jdg_entrepreneur, "foreign_capital_income", 0) > 0 }

# R0679: cross_border_establishment_pe — Zagraniczny zakład JDG (PE)
else := { "matched": true, "rule_id": "jdg.edge_cases.cross_border_pe", "package": "jdg.edge_cases", "priority": 679, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "pe_established": true, "pe_country": pe_country, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Zagraniczny zakład — alokacja dochodu", "_legal_basis": "Art. 4a pkt 11 PIT w zw. z UPO", "_warnings": [sprintf("ZAGRANICZNY ZAKŁAD (PE) — działalność w %s może tworzyć zakład wg UPO. Dochód PE opodatkowany za granicą. W PL: metoda unikania podwójnego opodatkowania", [pe_country])] } { object.get(input.jdg_entrepreneur, "has_foreign_establishment", false) == true; pe_country := object.get(input.jdg_entrepreneur, "foreign_pe_country", "") }

# R0680: cross_border_worker_posted — Pracownik delegowany za granicę
else := { "matched": true, "rule_id": "jdg.edge_cases.cross_border_posted_worker", "package": "jdg.edge_cases", "priority": 680, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "posted_worker_a1_required": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Pracownik delegowany — A1 + zgłoszenie", "_legal_basis": "Art. 12-16 Rozporządzenia 883/2004", "_warnings": ["PRACOWNIK DELEGOWANY ZA GRANICĘ — obowiązek: formularz A1 z ZUS + zgłoszenie delegowania do Państwowej Inspekcji Pracy + przestrzeganie prawa kraju przyjmującego (płaca minimalna, czas pracy)"] } { object.get(input.jdg_entrepreneur, "has_posted_workers", false) == true }

# ╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

# R0682: vat_reverse_charge_construction_extended — Odwrotne obciążenie budowlane rozszerzone
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_reverse_charge_construction_ext", "package": "jdg.edge_cases", "priority": 682, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "reverse_charge_construction": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Odwrotne obciążenie — usługi budowlane Art. 17 ust. 1 pkt 8", "_legal_basis": "Art. 17 ust. 1 pkt 8 VAT, Załącznik nr 14", "_warnings": ["ODWROTNE OBCIĄŻENIE BUDOWLANE — nabywca rozlicza VAT. Sprzedawca: faktura bez VAT z adnotacją 'odwrotne obciążenie'. Dotyczy usług z Załącznika nr 14!"] } { input.invoice.service_type == "CONSTRUCTION"; input.vendor.is_company == true; input.invoice.reverse_charge_applies == true }

# R0683: vat_wnt_intracommunity_acquisition_detailed — WNT szczegółowa walidacja
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_wnt_acquisition_detailed", "package": "jdg.edge_cases", "priority": 683, "vat_rate": "0.23", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "wnt_acquisition": true, "wnt_triangulation": triangulation, "_routing": "TRIAGE_QUEUE", "_routing_reason": "WNT — wewnątrzwspólnotowe nabycie towarów", "_legal_basis": "Art. 9-12 VAT", "_warnings": [sprintf("WNT — nabycie towarów z UE. %s. VAT należny i naliczony w tej samej deklaracji (Netto=0). Obowiązek VAT-UE do 15. dnia następnego miesiąca.", [triangulation_info])] } { input.invoice.procedure == "WNT"; has_triangulation := object.get(input.invoice, "wnt_is_triangulation", false); triangulation = "TRANSAKCJA TRÓJSTRONNA" { has_triangulation == true }; triangulation = "WNT standardowe" { has_triangulation == false }; triangulation_info = "Transakcja trójstronna — uproszczona procedura" { has_triangulation == true }; triangulation_info = "WNT standardowe — rozlicz VAT-23 + VAT-UE" { has_triangulation == false } }

# R0684: vat_export_0pct_documentation — Dokumentacja eksportu 0% VAT
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_export_0pct_documentation", "package": "jdg.edge_cases", "priority": 684, "vat_rate": "0.00", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "export_vat_0pct": true, "export_proof_required": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Eksport 0% VAT — wymagany dowód wywozu", "_legal_basis": "Art. 41 ust. 4-11 VAT", "_warnings": ["EKSPORT 0% VAT — wymagany dokument celny (IE-599 / komunikat IE-529) potwierdzający wywóz poza UE. Bez dokumentu: stawka krajowa 23%! Termin na uzyskanie: do upływu terminu złożenia deklaracji."] } { input.invoice.procedure == "EXPORT"; input.invoice.direction == "SALE"; input.vendor.country != "PL" }

# R0685: vat_import_deferral — Import VAT — odroczenie
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_import_deferral", "package": "jdg.edge_cases", "priority": 685, "vat_rate": "0.23", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "import_vat_deferral": true, "deferral_procedure": "ART_33a", "_routing": "TRIAGE_QUEUE", "_routing_reason": "Import — odroczenie VAT wg Art. 33a", "_legal_basis": "Art. 33a VAT", "_warnings": ["IMPORT VAT — odroczenie wg Art. 33a. VAT od importu rozliczany w deklaracji JPK_V7 (nie przy odprawie celnej). Warunek: złożenie zgłoszenia celnego + posiadanie pozwolenia."] } { input.invoice.procedure == "IMPORT"; object.get(input.jdg_entrepreneur, "has_art33a_permit", false) == true }

# R0686: vat_distance_selling_threshold — Sprzedaż wysyłkowa B2C — próg 10 000 EUR
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_distance_selling_threshold", "package": "jdg.edge_cases", "priority": 686, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "distance_selling": true, "b2c_eu_threshold": 10000, "b2c_eu_ytd": ytd_eur, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Sprzedaż wysyłkowa B2C — monitoring progu 10k EUR", "_legal_basis": "Art. 23a-23b VAT", "_warnings": [sprintf("SPRZEDAŻ WYSYŁKOWA B2C — %.2f EUR / 10 000 EUR. Po przekroczeniu: VAT w kraju konsumenta (OSS) lub rejestracja lokalna. OSS upraszcza — jeden raport kwartalny w PL.", [ytd_eur])] } { input.invoice.procedure == "DISTANCE_SELLING"; ytd_eur := object.get(input.jdg_entrepreneur, "b2c_eu_sales_ytd_eur", 0); ytd_eur > 5000 }

# R0687: vat_call_off_stock — Magazyn typu call-off stock
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_call_off_stock", "package": "jdg.edge_cases", "priority": 687, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "call_off_stock": true, "call_off_deadline_months": 12, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 13a VAT (Dyrektywa 2018/1910)", "_warnings": ["CALL-OFF STOCK — towary wysłane do magazynu w innym kraju UE. Max 12 miesięcy na pobranie przez odbiorcę. Po terminie: fikcyjna dostawa WDT. Ewidencja w JPK_V7 + VAT-UE."] } { input.invoice.procedure == "CALL_OFF_STOCK"; object.get(input.jdg_entrepreneur, "has_call_off_stock_arrangement", false) == true }

# R0688: vat_chain_transaction_simplification — Transakcja łańcuchowa — uproszczenie
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_chain_transaction", "package": "jdg.edge_cases", "priority": 688, "vat_rate": "0.00", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "chain_transaction": true, "chain_middleman": middleman_role, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Transakcja łańcuchowa — ustalenie dostawy ruchomej", "_legal_basis": "Art. 7 ust. 8 VAT, Art. 22 ust. 2-3 VAT", "_warnings": [sprintf("TRANSAKCJA ŁAŃCUCHOWA — rola: %s. Tylko JEDNA dostawa jest 'ruchoma' (transgraniczna) z VAT 0%%. Pozostałe to dostawy krajowe. Ustal transport organizowany przez środkowego.", [middleman_role])] } { input.invoice.procedure == "CHAIN_TRANSACTION"; middleman_role := object.get(input.invoice, "chain_transaction_role", "INTERMEDIARY"); middleman_role in {"FIRST_SUPPLIER", "INTERMEDIARY", "FINAL_BUYER"} }

# R0689: vat_correction_invoice_mandatory_note — Faktura korygująca — obowiązkowe elementy
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_correction_invoice_mandatory", "package": "jdg.edge_cases", "priority": 689, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "correction_mandatory": true, "correction_reason": correction_reason_required, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Faktura korygująca — brak przyczyny korekty", "_legal_basis": "Art. 106j ust. 1 pkt 5 VAT", "_warnings": ["FAKTURA KORYGUJĄCA — OBOWIĄZKOWA przyczyna korekty! Art. 106j ust. 1 pkt 5: każda faktura korygująca musi zawierać przyczynę. Brak = faktura wadliwa."] } { input.invoice.document_type == "CORRECTION_INVOICE"; correction_reason := object.get(input.invoice, "correction_reason", ""); correction_reason == "" }

# R0690: vat_split_payment_mpp_nuances — Split payment — niuanse
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_split_payment_nuances", "package": "jdg.edge_cases", "priority": 690, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "mpp_nuances": true, "mpp_voluntary_benefit": voluntary_benefit, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 108a-108f VAT", "_warnings": [sprintf("SPLIT PAYMENT — %s. Uwaga: MPP obowiązkowy tylko przy B2B >15k PLN brutto + towary z Załącznika 15. Dobrowolny MPP: brak sankcji, szybszy zwrot VAT (25 dni).", [voluntary_benefit])] } { input.invoice.payment_method == "SPLIT_PAYMENT"; is_voluntary := object.get(input.invoice, "mpp_is_voluntary", false); voluntary_benefit = "DOBROWOLNY — zwrot VAT w 25 dni zamiast 60" { is_voluntary == true }; voluntary_benefit = "OBOWIĄZKOWY — brak = sankcja 30% VAT" { is_voluntary == false } }

# R0691: vat_bad_debt_creditor_90d_winddown — Złe długi — wygaszanie po 90 dniach
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_bad_debt_creditor_90d", "package": "jdg.edge_cases", "priority": 691, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "bad_debt_creditor": true, "bad_debt_deadline_days": 90, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Ulga na złe długi — wierzyciel, 90 dni (SLIM VAT 3)", "_legal_basis": "Art. 89a VAT (SLIM VAT 3)", "_warnings": [sprintf("ULGA NA ZŁE DŁUGI WIERZYCIELA — %d dni po terminie. SLIM VAT 3 skrócił z 150 do 90 dni! Warunki: (1) dłużnik nie w trakcie restrukturyzacji/upadłości, (2) min. 90 dni, (3) wierzytelność nie została zbyta.", [days_overdue])] } { input.invoice.direction == "SALE"; input.invoice.is_paid == false; days_overdue := object.get(input.invoice, "days_overdue", 0); days_overdue >= 90; days_overdue < 150; object.get(input.invoice, "bad_debt_documented", false) == true }

# R0692: vat_fiscal_representative — Przedstawiciel podatkowy VAT
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_fiscal_representative", "package": "jdg.edge_cases", "priority": 692, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "fiscal_representative_required": true, "fiscal_rep_country": rep_country, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Przedstawiciel podatkowy — wymagany dla firm spoza UE", "_legal_basis": "Art. 18a-18d VAT", "_warnings": [sprintf("PRZEDSTAWICIEL PODATKOWY VAT — wymagany dla kontrahenta z %s (spoza UE). Przedstawiciel odpowiada solidarnie za zobowiązania VAT. Rejestracja przez VAT-R + umowa.", [rep_country])] } { input.invoice.direction == "PURCHASE"; input.vendor.country != "PL"; vendor_eu := object.get(input.vendor, "is_eu", false); vendor_eu == false; rep_country := object.get(input.vendor, "country", "NON_EU") }

# R0693: vat_prepayment_partial — Zaliczka częściowa — VAT proporcjonalny
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_prepayment_partial", "package": "jdg.edge_cases", "priority": 693, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "prepayment_partial_vat": true, "prepayment_vat_amount": floor(amount_net * prepayment_pct * vat_std_rate * 100) / 100, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 19a ust. 8 VAT", "_warnings": [sprintf("ZALICZKA CZĘŚCIOWA — %.0f%% wartości = %.2f PLN netto. VAT: %.2f PLN należny w dacie otrzymania zaliczki. Reszta VAT w dacie wykonania usługi.", [prepayment_pct * 100, amount_net, floor(amount_net * prepayment_pct * vat_std_rate * 100) / 100])] } { input.invoice.prepayment_received == true; prepayment_pct := object.get(input.invoice, "prepayment_rate", 0); prepayment_pct > 0; prepayment_pct < 1.0; amount_net := object.get(input.invoice, "amount_net", 0); amount_net > 0; vat_std_rate := object.get(object.get(object.get(data.thresholds, "jdg", {}), "rates", {}), "vat_standard", 0.23) }

# R0694: vat_incorrect_rate_correction — Korekta błędnej stawki VAT
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_incorrect_rate_correction", "package": "jdg.edge_cases", "priority": 694, "vat_rate": "0.23", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "incorrect_rate_correction": true, "original_rate": original_rate, "correct_rate": correct_rate, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Błędna stawka VAT — wymagana korekta", "_legal_basis": "Art. 106j VAT", "_warnings": [sprintf("BŁĘDNA STAWKA VAT — zastosowano %s, powinno być %s. Wystaw fakturę korygującą! Różnica %.2f PLN. Sankcja za błędną stawkę: 30%% VAT (Art. 108a).", [original_rate, correct_rate, diff_amount])] } { input.invoice.vat_rate_error_detected == true; original_rate := object.get(input.invoice, "vat_rate_applied", "0.23"); correct_rate := object.get(input.invoice, "vat_rate_correct", "0.08"); original_rate != correct_rate; diff_amount := object.get(input.invoice, "vat_difference_pln", 0) }

# R0695: vat_group_consolidation — Grupa VAT — konsolidacja rozliczeń
else := { "matched": true, "rule_id": "jdg.edge_cases.vat_group_consolidation", "package": "jdg.edge_cases", "priority": 695, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "vat_group_member": true, "vat_group_representative": group_rep, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Grupa VAT — wspólne rozliczenia od 2025", "_legal_basis": "Art. 15a VAT, Rozdział 1a (Grupy VAT od 2025)", "_warnings": [sprintf("GRUPA VAT — członek grupy VAT. Reprezentant: %s. Transakcje wewnątrz grupy = poza VAT. Jeden JPK_V7 dla całej grupy. Odpowiedzialność solidarna!", [group_rep])] } { object.get(input.jdg_entrepreneur, "vat_group_member", false) == true; group_rep := object.get(input.jdg_entrepreneur, "vat_group_representative", "") }

# ── EU countries list (for cross-border WHT rules) ──────────────────────────
eu_edge_countries := {
    "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
    "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
    "PL", "PT", "RO", "SK", "SI", "ES", "SE"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA F: R0623-R0645 — LIMITY I PROGI KWOTOWE (23 reguły)                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# R0623: limit_vat_exemption_200k — Limit zwolnienia podmiotowego VAT 200 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_vat_exemption_200k",
    "package": "jdg.edge_cases", "priority": 623,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "VAT_EXEMPTION", "limit_value": 200000, "limit_currency": "PLN",
    "current_ytd": ytd_sales, "remaining_headroom": 200000 - ytd_sales,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 113 ust. 1 VAT",
    "_warnings": [sprintf("Limit VAT 200k: YTD %.2f PLN, pozostało %.2f PLN. Przekroczenie = obowiązek rejestracji VAT + VAT od nadwyżki", [ytd_sales, 200000 - ytd_sales])]
} {
    input.jdg_entrepreneur.vat_status == "EXEMPT_SUBJECT"
    ytd_sales := object.get(input.jdg_entrepreneur, "sales_ytd_vat_exempt", 0)
    ytd_sales > 100000
}

# R0624: limit_lump_sum_2m_eur — Limit ryczałtu 2 000 000 EUR
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_lump_sum_2m_eur",
    "package": "jdg.edge_cases", "priority": 624,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "LUMP_SUM_THRESHOLD", "limit_value": 2000000, "limit_currency": "EUR",
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Przekroczenie limitu ryczałtu 2M EUR — utrata prawa",
    "_legal_basis": "Art. 6 ust. 1 ustawy o ryczałcie",
    "_warnings": [sprintf("RYCZAŁT: przychód %.2f EUR zbliża się do limitu 2 000 000 EUR. Po przekroczeniu = utrata prawa od następnego miesiąca, przejście na skalę PIT", [revenue_eur])]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    revenue_eur := object.get(input.jdg_entrepreneur, "annual_revenue_eur", 0)
    revenue_eur > 1500000
}

# R0625: limit_small_taxpayer_2m_eur — Mały podatnik 2 000 000 EUR
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_small_taxpayer_2m_eur",
    "package": "jdg.edge_cases", "priority": 625,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "SMALL_TAXPAYER", "limit_value": 2000000, "limit_currency": "EUR",
    "is_small_taxpayer": revenue_eur <= 2000000,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 2 pkt 25 VAT",
    "_warnings": [sprintf("Mały podatnik: %.2f EUR / 2 000 000 EUR. Status: %s", [revenue_eur, ("TAK" | "NIE")])]
} {
    revenue_eur := object.get(input.jdg_entrepreneur, "annual_revenue_eur", 0)
    revenue_eur > 1000000
}

# R0626: limit_full_accounting_2m_eur — Próg pełnej księgowości
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_full_accounting_2m_eur",
    "package": "jdg.edge_cases", "priority": 626,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "FULL_ACCOUNTING", "limit_value": 2000000, "limit_currency": "EUR",
    "full_accounting_required": revenue_eur > 2000000,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Przekroczenie progu pełnej księgowości — obowiązek ksiąg rachunkowych",
    "_legal_basis": "Art. 24a PIT",
    "_warnings": [sprintf("PRÓG PEŁNEJ KSIĘGOWOŚCI: %.2f EUR > 2 000 000 EUR. Obowiązek prowadzenia ksiąg rachunkowych (UoR) od następnego roku!", [revenue_eur])]
} {
    revenue_eur := object.get(input.jdg_entrepreneur, "annual_revenue_eur", 0)
    revenue_eur > 2000000
}

# R0627: limit_cash_transaction_15k — Limit gotówki B2B 15 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_cash_transaction_15k",
    "package": "jdg.edge_cases", "priority": 627,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "CASH_TRANSACTION", "limit_value": 15000,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Gotówka B2B >15k PLN — NKUP + sankcja 20%",
    "_legal_basis": "Art. 22p PIT",
    "_warnings": ["PŁATNOŚĆ GOTÓWKĄ >15 000 PLN B2B — cała kwota NKUP! Dodatkowo sankcja 20%. Używaj przelewu."]
} {
    input.invoice.payment_method == "CASH"
    input.invoice.direction == "PURCHASE"
    input.invoice.amount_gross > 15000
    input.vendor.is_company == true
}

# R0628: limit_mpp_15k — MPP obowiązkowy >15 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_mpp_15k",
    "package": "jdg.edge_cases", "priority": 628,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "MPP_MANDATORY", "limit_value": 15000,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Brak MPP przy transakcji >15k PLN — sankcja 30% VAT",
    "_legal_basis": "Art. 108a VAT",
    "_warnings": [sprintf("MPP WYMAGANY — faktura %.2f PLN > 15 000 PLN. Użyj komunikatu przelewu MPP. Brak = solidarna odpowiedzialność + 30%% VAT!", [amount_gross])]
} {
    input.invoice.mpp_required == true
    input.invoice.mpp_used == false
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross > 15000
}

# R0629: limit_tax_free_amount_30k — Kwota wolna od podatku 30 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_tax_free_30k",
    "package": "jdg.edge_cases", "priority": 629,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "TAX_FREE_AMOUNT", "limit_value": 30000,
    "tax_free_applied": annual_income <= 30000,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 27 ust. 1 PIT",
    "_warnings": [sprintf("Kwota wolna 30 000 PLN — dochód %.2f PLN. Podatek tylko od nadwyżki ponad 30k", [annual_income])]
} {
    input.jdg_entrepreneur.tax_form == "SCALE"
    annual_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)
    annual_income > 0
}

# R0630: limit_pit_scale_threshold_120k — Próg skali PIT 120 000 PLN (12%→32%)
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_pit_scale_120k",
    "package": "jdg.edge_cases", "priority": 630,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "32%", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "PIT_SCALE_THRESHOLD", "limit_value": 120000,
    "bracket_exceeded": annual_income > 120000,
    "tax_first_bracket": 120000 * 0.12 - 30000,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 27 ust. 1 PIT",
    "_warnings": [sprintf("PRÓG SKALI PIT 120k: dochód %.2f PLN → nadwyżka opodatkowana 32%%. Podatek: 10 800 PLN (I próg) + 32%% × %.2f PLN", [annual_income, annual_income - 120000])]
} {
    input.jdg_entrepreneur.tax_form == "SCALE"
    annual_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)
    annual_income > 120000
}

# R0631: limit_car_depreciation_150k — Limit KUP auto spalinowe 150 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_car_depreciation_150k",
    "package": "jdg.edge_cases", "priority": 631,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "partial", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "CAR_KUP_SPALINOWE", "limit_value": 150000,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Auto spalinowe >150k — nadwyżka NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 47a PIT",
    "_warnings": [sprintf("AUTO SPALINOWE: wartość %.2f PLN > limit 150 000 PLN. Nadwyżka %.2f PLN = NKUP. Amortyzacja tylko od 150k.", [car_value, car_value - 150000])]
} {
    car_value := object.get(input.invoice, "car_value_pln", 0)
    car_value > 150000
    object.get(input.invoice, "car_type", "") == "COMBUSTION"
}

# R0632: limit_car_electric_225k — Limit KUP auto EV 225 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_car_electric_225k",
    "package": "jdg.edge_cases", "priority": 632,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "partial", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "CAR_KUP_EV", "limit_value": 225000,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Auto EV >225k — nadwyżka NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 47b PIT",
    "_warnings": [sprintf("AUTO ELEKTRYCZNE: wartość %.2f PLN > limit 225 000 PLN. Nadwyżka %.2f PLN = NKUP.", [car_value, car_value - 225000])]
} {
    car_value := object.get(input.invoice, "car_value_pln", 0)
    car_value > 225000
    object.get(input.invoice, "car_type", "") == "ELECTRIC"
}

# R0633: limit_health_linear_deduction — Max odliczenie zdrowotnej liniowy (2026=14100)
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_health_linear",
    "package": "jdg.edge_cases", "priority": 633,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LINEAR", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "HEALTH_DEDUCTION_LINEAR", "limit_value": data.jdg.thresholds.limits.health_linear_deduction_limit,
    "health_paid": health_paid, "deductible": deduct,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 30c ust. 2 PIT",
    "_warnings": [sprintf("Liniowy: zapłacona zdrowotna %.2f PLN, max odliczenie %.0f PLN. Odliczasz %.2f PLN", [health_paid, data.jdg.thresholds.limits.health_linear_deduction_limit, deduct])]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
    health_paid := object.get(input.jdg_entrepreneur, "zus_health_paid_ytd", 0)
    health_paid > 10000
    deduct = health_paid { health_paid <= data.jdg.thresholds.limits.health_linear_deduction_limit }
    deduct = data.jdg.thresholds.limits.health_linear_deduction_limit { health_paid > data.jdg.thresholds.limits.health_linear_deduction_limit }
}

# R0634: limit_rd_relief_capped — Ulga B+R max 100% dochodu
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_rd_relief_capped",
    "package": "jdg.edge_cases", "priority": 634,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "RD_RELIEF_CAP", "limit_value_pct": 100,
    "rd_costs": rd_costs, "taxable_income": income,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26e ust. 7 PIT",
    "_warnings": [sprintf("Ulga B+R: koszty %.2f PLN, dochód %.2f PLN. Max odliczenie = dochód. Nadwyżka przechodzi na 6 lat.", [rd_costs, income])]
} {
    rd_costs := object.get(input.jdg_entrepreneur, "rd_costs_annual", 0)
    income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)
    rd_costs > 0
    income > 0
}

# R0635: limit_donation_6pct — Darowizny max 6% dochodu
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_donation_6pct",
    "package": "jdg.edge_cases", "priority": 635,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "DONATION_LIMIT", "limit_value_pct": 6,
    "donation_limit_pln": floor(income * 0.06 * 100) / 100,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1 pkt 9 PIT",
    "_warnings": [sprintf("Darowizny: limit 6%% dochodu = %.2f PLN. Nadwyżka PRZEPADA — nie przechodzi na kolejne lata.", [floor(income * 0.06 * 100) / 100])]
} {
    income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)
    donation_total := object.get(input.jdg_entrepreneur, "donation_total_annual", 0)
    donation_total > income * 0.06
}

# R0636: limit_thermo_53k — Ulga termomodernizacyjna max 53 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_thermo_53k",
    "package": "jdg.edge_cases", "priority": 636,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "THERMO_RELIEF", "limit_value": 53000,
    "thermo_costs": thermo_costs,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26h PIT",
    "_warnings": [sprintf("Termomodernizacja: wydatki %.2f PLN, max ulga 53 000 PLN. Limit dotyczy wszystkich budynków łącznie.", [thermo_costs])]
} {
    thermo_costs := object.get(input.jdg_entrepreneur, "thermo_costs_annual", 0)
    thermo_costs > 40000
}

# R0637: limit_prototype_300k — Ulga na prototyp max 300 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_prototype_300k",
    "package": "jdg.edge_cases", "priority": 637,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "PROTOTYPE_RELIEF", "limit_value": 300000,
    "prototype_costs": proto_costs,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26eb PIT",
    "_warnings": [sprintf("Prototyp: koszty %.2f PLN, max ulga 300 000 PLN rocznie. Nadwyżka nie przechodzi na kolejne lata.", [proto_costs])]
} {
    proto_costs := object.get(input.jdg_entrepreneur, "prototype_costs_annual", 0)
    proto_costs > 200000
}

# R0638: limit_expansion_1m — Ulga na ekspansję max 1 000 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_expansion_1m",
    "package": "jdg.edge_cases", "priority": 638,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "EXPANSION_RELIEF", "limit_value": 1000000,
    "expansion_costs": expansion_costs,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26ec PIT",
    "_warnings": [sprintf("Ekspansja: koszty %.2f PLN, max ulga 1 000 000 PLN. Dotyczy nowych rynków zbytu.", [expansion_costs])]
} {
    expansion_costs := object.get(input.jdg_entrepreneur, "expansion_costs_annual", 0)
    expansion_costs > 500000
}

# R0639: limit_pit0_combined — PIT-0 łączny limit (2026=85528)
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_pit0_combined",
    "package": "jdg.edge_cases", "priority": 639,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "PIT0_COMBINED", "limit_value": data.jdg.thresholds.pit.pit_relief_shared_limit,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Łączny limit PIT-0 przekroczony",
    "_legal_basis": "Art. 21 ust. 1 pkt 148-154 PIT",
    "_warnings": [sprintf("PIT-0: łączna kwota zwolnień %.2f PLN przekracza limit %.0f PLN. Nadwyżka opodatkowana.", [pit0_total, data.jdg.thresholds.pit.pit_relief_shared_limit])]
} {
    pit0_total := object.get(input.jdg_entrepreneur, "pit0_total_exempt", 0)
    pit0_total > data.jdg.thresholds.pit.pit_relief_shared_limit
}

# R0640: limit_loss_50pct_annual — Strata max 50% rocznie
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_loss_50pct_annual",
    "package": "jdg.edge_cases", "priority": 640,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "LOSS_CARRY_50PCT", "limit_value_pct": 50,
    "max_loss_deduction": floor(loss_amount * 0.5 * 100) / 100,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 9 ust. 3 PIT",
    "_warnings": [sprintf("Strata %.2f PLN — max 50%% (%.2f PLN) do odliczenia w jednym roku. Reszta w kolejnych latach (FIFO, max 5 lat).", [loss_amount, floor(loss_amount * 0.5 * 100) / 100])]
} {
    loss_amount := object.get(input.jdg_entrepreneur, "loss_carry_amount", 0)
    current_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)
    loss_amount > 0
    current_income > 0
}

# R0641: limit_loss_one_time_5m — Jednorazowe odliczenie straty 5 000 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_loss_one_time_5m",
    "package": "jdg.edge_cases", "priority": 641,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "LOSS_ONE_TIME_5M", "limit_value": 5000000,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 9 ust. 3a-3b PIT (COVID-19 special)",
    "_warnings": [sprintf("Jednorazowe odliczenie straty: %.2f PLN (max 5 000 000 PLN). Specjalny mechanizm COVID — dotyczy strat za 2020-2022.", [one_time_loss])]
} {
    one_time_loss := object.get(input.jdg_entrepreneur, "loss_one_time_deduction", 0)
    one_time_loss > 1000000
}

# R0642: limit_cash_register_exemption_20k — Kasa fiskalna zwolnienie 20 000 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_cash_register_20k",
    "package": "jdg.edge_cases", "priority": 642,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "CASH_REGISTER_EXEMPTION", "limit_value": 20000,
    "b2c_revenue": b2c_rev, "cash_register_required": b2c_rev > 20000,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Przekroczenie limitu zwolnienia z kasy fiskalnej",
    "_legal_basis": "Rozporządzenie MF ws. zwolnień z kasy fiskalnej",
    "_warnings": [sprintf("KASA FISKALNA: sprzedaż B2C %.2f PLN > 20 000 PLN. Obowiązek instalacji kasy fiskalnej w ciągu 2 miesięcy!", [b2c_rev])]
} {
    b2c_rev := object.get(input.jdg_entrepreneur, "b2c_revenue_ytd", 0)
    b2c_rev > 20000
    object.get(input.jdg_entrepreneur, "has_cash_register", false) == false
}

# R0643: limit_unregistered_activity_50pct — Działalność nieewidencjonowana
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_unregistered_50pct",
    "package": "jdg.edge_cases", "priority": 643,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "UNREGISTERED_ACTIVITY", "limit_value_pct": 50,
    "monthly_limit": floor(min_wage * 0.5 * 100) / 100,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Przekroczenie limitu działalności nieewidencjonowanej",
    "_legal_basis": "Art. 5 Prawa przedsiębiorców",
    "_warnings": [sprintf("Działalność nieewidencjonowana: przychód %.2f PLN > 50%% min. wynagrodzenia (%.2f PLN). Obowiązek rejestracji CEIDG!", [monthly_rev, floor(min_wage * 0.5 * 100) / 100])]
} {
    monthly_rev := object.get(input.jdg_entrepreneur, "monthly_revenue", 0)
    min_wage := object.get(object.get(data.thresholds, "jdg", {}), "minimum_wage_gross", 4300)
    monthly_rev > min_wage * 0.5
    input.jdg_entrepreneur.ceidg_registered == false
}

# R0644: limit_giif_reporting_15k_eur — Raport GIIF >15 000 EUR
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_giif_15k_eur",
    "package": "jdg.edge_cases", "priority": 644,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "GIIF_REPORTING", "limit_value": 15000, "limit_currency": "EUR",
    "giif_report_required": true,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Transakcja >15k EUR — obowiązek raportu GIIF",
    "_legal_basis": "Art. 72 ustawy AML",
    "_warnings": [sprintf("AML: transakcja %.2f EUR > 15 000 EUR. Obowiązek zgłoszenia do GIIF w ciągu 7 dni. Brak = kara do 1 000 000 PLN!", [amount_eur])]
} {
    input.invoice.currency == "EUR"
    amount_eur := object.get(input.invoice, "amount_gross", 0)
    amount_eur > 15000
}

# R0645: limit_cesop_reporting_25k_eur — Raport CESOP >25 000 EUR
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_cesop_25k_eur",
    "package": "jdg.edge_cases", "priority": 645,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "CESOP_REPORTING", "limit_value": 25000, "limit_currency": "EUR",
    "cesop_report_required": true,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Płatności transgraniczne >25k EUR — obowiązek CESOP",
    "_legal_basis": "Rozporządzenie 2020/284 (CESOP)",
    "_warnings": [sprintf("CESOP: kwartalne płatności transgraniczne %.2f EUR > 25 000 EUR. Obowiązek raportu CESOP do KAS.", [cross_border_total])]
} {
    input.invoice.is_cross_border_payment == true
    cross_border_total := object.get(input.jdg_entrepreneur, "cross_border_payments_quarterly_eur", 0)
    cross_border_total > 25000
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA J: R0693-R0695 — AUDIT TRAIL (Doc 35 P970-P974)                    ║
# ║  Immutability log, decision timestamp, operator identity                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P970: audit_immutability_log — Hash werdyktu + timestamp + operator_id
else := { "matched": true, "rule_id": "jdg.edge_cases.audit_immutability_log", "package": "jdg.edge_cases", "priority": 970, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "audit_immutability_required": true, "audit_hash_algo": "SHA-256", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 22 UoR, Art. 6 RODO", "_warnings": ["ŚCIEŻKA AUDYTU — każdy werdykt musi być hashowany (SHA-256) z kompletnego outputu + timestamp + operator_id. Immutable log."] } { object.get(input.jdg_entrepreneur, "enterprise_audit_mode", false) == true }

# P972: audit_decision_timestamp — Znacznik czasu decyzji (ISO 8601)
else := { "matched": true, "rule_id": "jdg.edge_cases.audit_decision_timestamp", "package": "jdg.edge_cases", "priority": 972, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "audit_timestamp_required": true, "audit_timestamp_format": "ISO8601_MS", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 22 UoR", "_warnings": ["ZNACZNIK CZASU — każdy werdykt musi zawierać ISO 8601 timestamp z milisekundami. Wymagane w enterprise audit trail."] } { object.get(input.jdg_entrepreneur, "enterprise_audit_mode", false) == true }

# P974: audit_operator_identity — Identyfikacja operatora/automatu
else := { "matched": true, "rule_id": "jdg.edge_cases.audit_operator_identity", "package": "jdg.edge_cases", "priority": 974, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "audit_operator_required": true, "audit_operator_source": "input.operator_id OR system_opa_auto", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 22 UoR", "_warnings": ["IDENTYFIKACJA OPERATORA — każdy werdykt musi mieć operator_id (człowiek) lub system_opa_auto (automat). Ślad rewizyjny."] } { object.get(input.jdg_entrepreneur, "enterprise_audit_mode", false) == true }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA K: R0696-R0710 — DOC 36: DOKUMENTACJA & RETENCJA (Doc 36 §6)      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P370: doc_invoice_numbering_continuity — Ciągłość numeracji faktur
else := { "matched": true, "rule_id": "jdg.edge_cases.invoice_numbering_continuity_fail", "package": "jdg.edge_cases", "priority": 696, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "numbering_gap": true, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Luka w numeracji faktur — alert", "_legal_basis": "Art. 106e VAT", "_warnings": ["CIĄGŁOŚĆ NUMERACJI — luka w numeracji faktur. Może wskazywać na ukryte/brakujące faktury. Sprawdź JPK_V7!"] } { object.get(input.jdg_entrepreneur, "invoice_numbering_gap_detected", false) == true }

# P371: doc_payment_confirmation_required — Potwierdzenia przelewów
else := { "matched": true, "rule_id": "jdg.edge_cases.payment_confirmation_required", "package": "jdg.edge_cases", "priority": 697, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "payment_proof_required": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 86 ust. 1 VAT", "_warnings": ["Przechowuj potwierdzenia przelewów jako dowody zapłaty. Wymagane do odliczenia VAT i kontroli skarbowej."] } { object.get(input.jdg_entrepreneur, "payment_confirmation_missing", false) == true }

# P372: doc_contract_retention_5yr — Przechowywanie umów 5 lat
else := { "matched": true, "rule_id": "jdg.edge_cases.contract_retention_5yr", "package": "jdg.edge_cases", "priority": 698, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "contract_retention_years": 5, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 74 KC", "_warnings": ["Umowy handlowe — przechowuj 5 lat od zakończenia współpracy. Wymagane do ewentualnej kontroli!"] } { object.get(input.jdg_entrepreneur, "contract_retention_expiring", false) == true }

# P373: doc_hr_records_10yr — Akta osobowe 10 lat
else := { "matched": true, "rule_id": "jdg.edge_cases.hr_records_10yr", "package": "jdg.edge_cases", "priority": 699, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "hr_retention_years": 10, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 51u SUS", "_warnings": ["Akta osobowe — przechowuj 10 lat od 2019 (po raportach ZUS OSW). Dotyczy wszystkich byłych pracowników."] } { object.get(input.employment, "has_employees", false) == true }

# P374: doc_destruction_procedure — Procedura niszczenia dokumentów
else := { "matched": true, "rule_id": "jdg.edge_cases.document_destruction_procedure", "package": "jdg.edge_cases", "priority": 700, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "destruction_protocol_required": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 6 RODO", "_warnings": ["Niszczenie dokumentów po upływie retencji — sporządź PROTOKÓŁ ZNISZCZENIA z datą i listą dokumentów. Wymóg RODO!"] } { object.get(input.jdg_entrepreneur, "document_destruction_pending", false) == true }

# P375: doc_electronic_signature_validity — Ważność podpisu elektronicznego
else := { "matched": true, "rule_id": "jdg.edge_cases.electronic_signature_validity", "package": "jdg.edge_cases", "priority": 701, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "esignature_valid": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Rozp. eIDAS 910/2014", "_warnings": ["Podpis elektroniczny — musi być kwalifikowany (eIDAS). Profil zaufany = ważny 3 lata. Pamiętaj o odnowieniu certyfikatu!"] } { object.get(input.jdg_entrepreneur, "esignature_expiring", false) == true }

# P376: doc_ksef_schema_validation — Walidacja schematu KSeF
else := { "matched": true, "rule_id": "jdg.edge_cases.ksef_schema_validation", "package": "jdg.edge_cases", "priority": 702, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "ksef_schema": "FA(2)", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "KSeF — struktura FA(2) niezgodna ze schemą", "_legal_basis": "Rozp. KSeF", "_warnings": ["KSeF — struktura XML musi być zgodna ze schemą FA(2). W przeciwnym razie faktura zostanie ODRZUCONA przez KSeF!"] } { input.invoice.ksef_sent == true; object.get(input.invoice, "ksef_schema_valid", true) == false }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA L: R0703-R0708 — DOC 36 §19: DZIAŁALNOŚĆ SEZONOWA               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P500: seasonal_suspension_trigger — Zawieszenie sezonowe
else := { "matched": true, "rule_id": "jdg.edge_cases.seasonal_suspension", "package": "jdg.edge_cases", "priority": 703, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "SEASONAL_SUSPENDED", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 22 Prawa przedsiębiorców", "_warnings": ["Zawieszenie sezonowe — możesz zawiesić JDG na czas poza sezonem bezterminowo. Pamiętaj o zerowych deklaracjach VAT i braku składek ZUS społecznych (zdrowotna NADAL należna!)."] } { object.get(input.jdg_entrepreneur, "seasonal_suspension_active", false) == true }

# P501: seasonal_pit_advance_proportion — Zaliczki proporcjonalne
else := { "matched": true, "rule_id": "jdg.edge_cases.seasonal_pit_advance", "package": "jdg.edge_cases", "priority": 704, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "seasonal_pit_proportion": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 44 PIT", "_warnings": ["Zaliczki PIT w sezonie — obliczaj proporcjonalnie do miesięcy aktywnych. PIT roczny: sumuj dochód z miesięcy aktywnych."] } { object.get(input.jdg_entrepreneur, "is_seasonal_jdg", false) == true; object.get(input.jdg_entrepreneur, "active_months_ytd", 0) > 0 }

# P502: seasonal_vat_zero_returns — Zerowe deklaracje VAT w sezonie
else := { "matched": true, "rule_id": "jdg.edge_cases.seasonal_vat_zero", "package": "jdg.edge_cases", "priority": 705, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "seasonal_vat_zero": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 99 VAT", "_warnings": ["Zerowe deklaracje VAT-7 w okresie sezonowego zawieszenia. Wyjątek: jeśli masz WNT, złóż deklarację z WNT."] } { object.get(input.jdg_entrepreneur, "seasonal_suspension_active", false) == true; object.get(input.jdg_entrepreneur, "has_wnt_transactions", false) == false }

# P503: seasonal_zus_exemption — ZUS tylko za miesiące aktywne
else := { "matched": true, "rule_id": "jdg.edge_cases.seasonal_zus_exemption", "package": "jdg.edge_cases", "priority": 706, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "PROPORTIONAL", "zus_health_rate": "", "business_status": "", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 36a SUS", "_warnings": ["ZUS sezonowo — składki społeczne tylko za miesiące aktywne. Zdrowotna za każdy miesiąc prowadzenia (NADAL należna w zawieszeniu!)."] } { object.get(input.jdg_entrepreneur, "is_seasonal_jdg", false) == true; object.get(input.jdg_entrepreneur, "active_months_ytd", 0) > 0 }

# P504: seasonal_annual_pkpir — PKPiR z miesięcy aktywnych
else := { "matched": true, "rule_id": "jdg.edge_cases.seasonal_pkpir", "package": "jdg.edge_cases", "priority": 707, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 24a PIT", "_warnings": ["PKPiR sezonowo — dochód tylko z miesięcy aktywnych. Koszty uzyskania przychodu z miesięcy aktywnych."] } { object.get(input.jdg_entrepreneur, "is_seasonal_jdg", false) == true }

# P505: seasonal_different_forms — Różne formy w sezonie vs poza sezonem NIEDOZWOLONE
else := { "matched": true, "rule_id": "jdg.edge_cases.seasonal_different_forms_blocked", "package": "jdg.edge_cases", "priority": 708, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Różne formy opodatkowania w sezonie — NIEDOZWOLONE", "_legal_basis": "Art. 9a ust. 2 PIT", "_warnings": ["NIE MOŻESZ mieć różnych form opodatkowania w sezonie i poza sezonem. Jedna forma na cały rok podatkowy!"] } { object.get(input.jdg_entrepreneur, "seasonal_form_mismatch", false) == true }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA M: R0709-R0713 — DOC 36 §25: SIŁA WYŻSZA (FORCE MAJEURE)         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P560: force_majeure_tax_deadline_extension — Przedłużenie terminów
else := { "matched": true, "rule_id": "jdg.edge_cases.force_majeure_tax_deadline", "package": "jdg.edge_cases", "priority": 709, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "force_majeure_deadline_extended": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 48-50 Ordynacji podatkowej", "_warnings": ["SIŁA WYŻSZA — terminy podatkowe mogą zostać przedłużone. Udokumentuj zdarzenie i złóż wniosek do US o przedłużenie terminu."] } { object.get(input.jdg_entrepreneur, "force_majeure_active", false) == true }

# P561: force_majeure_zus_suspension — Zawieszenie ZUS (tarcza)
else := { "matched": true, "rule_id": "jdg.edge_cases.force_majeure_zus_suspension", "package": "jdg.edge_cases", "priority": 710, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "SUSPENDED_FM", "zus_health_rate": "", "business_status": "", "_routing": "", "_routing_reason": "", "_legal_basis": "Ustawa COVID-19 (archiwalna — tarcza antykryzysowa)", "_warnings": ["Siła wyższa — możliwe zawieszenie składek ZUS (tarcza antykryzysowa). Wniosek do ZUS + dokumentacja zdarzenia. Mechanizm analogiczny do tarcz COVID-19."] } { object.get(input.jdg_entrepreneur, "force_majeure_zus_suspended", false) == true }

# P562: force_majeure_tax_exemption — Zwolnienie z podatku od zniszczonej nieruchomości
else := { "matched": true, "rule_id": "jdg.edge_cases.force_majeure_tax_exemption", "package": "jdg.edge_cases", "priority": 711, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "tax_exemption_applies": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 48-49 Ordynacji podatkowej", "_warnings": ["Klęska żywiołowa — zniszczona nieruchomość może być zwolniona z podatku od nieruchomości. Złóż wniosek do gminy + dokumentacja strat."] } { object.get(input.jdg_entrepreneur, "property_destroyed_force_majeure", false) == true }

# P563: force_majeure_insurance_compensation — Odszkodowanie = przychód
else := { "matched": true, "rule_id": "jdg.edge_cases.force_majeure_insurance_tax", "package": "jdg.edge_cases", "priority": 712, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "insurance_compensation_taxable": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 14 PIT", "_warnings": ["Odszkodowanie ubezpieczeniowe — przychód podatkowy w roku otrzymania. Wyjątek: odszkodowanie za zniszczony środek trwały — dochód = odszkodowanie - wartość netto ŚT."] } { object.get(input.jdg_entrepreneur, "received_force_majeure_insurance", false) == true }

# P564: force_majeure_loss_documentation — Dokumentacja strat
else := { "matched": true, "rule_id": "jdg.edge_cases.force_majeure_loss_documentation", "package": "jdg.edge_cases", "priority": 713, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "loss_documentation_required": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 14 ust. 2 PIT", "_warnings": ["Udokumentuj straty dla US — inwentaryzacja zniszczonego majątku + protokół szkód + zdjęcia + zgłoszenie na policję. Wymagane do odliczenia straty!"] } { object.get(input.jdg_entrepreneur, "force_majeure_loss_undocumented", false) == true }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA N: R0714-R0721 — DOC 36 §26: KASA FISKALNA SZCZEGÓŁY             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P570: cash_register_mandatory — Obowiązek kasy fiskalnej
else := { "matched": true, "rule_id": "jdg.edge_cases.cash_register_mandatory", "package": "jdg.edge_cases", "priority": 714, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "cash_register_mandatory": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Obowiązek kasy fiskalnej — sprzedaż B2C + limit przekroczony", "_legal_basis": "Art. 111 VAT", "_warnings": [sprintf("KASA FISKALNA OBOWIĄZKOWA — sprzedaż B2C %.2f PLN > limit 20 000 PLN. Zainstaluj kasę w ciągu 2 miesięcy! Ulga 700 PLN.", [b2c_rev])] } { b2c_rev := object.get(input.jdg_entrepreneur, "b2c_revenue_annual", 0); b2c_rev > 20000; object.get(input.jdg_entrepreneur, "cash_register_installed", true) == false }

# P573: cash_register_online_vs_virtual — Kasa online vs wirtualna
else := { "matched": true, "rule_id": "jdg.edge_cases.cash_register_online_required", "package": "jdg.edge_cases", "priority": 715, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "cash_register_type": "ONLINE", "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Wymagana kasa ONLINE dla tej branży", "_legal_basis": "Art. 111 ust. 6a VAT", "_warnings": ["KASA ONLINE — Twoja branża wymaga kasy online (gastronomia, paliwa, motoryzacja, fryzjerstwo). Nie można używać kasy wirtualnej!"] } { object.get(input.jdg_entrepreneur, "cash_register_branch_online_required", false) == true }

# P574: cash_register_ulga_700 — Ulga na zakup kasy 700 PLN
else := { "matched": true, "rule_id": "jdg.edge_cases.cash_register_tax_relief_700", "package": "jdg.edge_cases", "priority": 716, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "cash_register_relief_pln": 700, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 111 ust. 4 VAT", "_warnings": ["ULGA NA KASĘ — 700 PLN (online) lub 90% ceny max 700 PLN. Odliczasz od podatku VAT w deklaracji za okres zakupu."] } { object.get(input.jdg_entrepreneur, "cash_register_installed", false) == true; object.get(input.jdg_entrepreneur, "cash_register_relief_claimed", true) == false }

# P575: cash_register_breach_mid_year — Przekroczenie limitu 20k w trakcie roku
else := { "matched": true, "rule_id": "jdg.edge_cases.cash_register_breach_mid_year", "package": "jdg.edge_cases", "priority": 717, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "cash_register_deadline_months": 2, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Przekroczenie 20k B2C — kasa w 2 miesiące", "_legal_basis": "Rozp. MF § 3 ust. 1", "_warnings": ["PRZEKROCZENIE LIMITU 20k B2C — zainstaluj kasę fiskalną w ciągu 2 miesięcy od przekroczenia! Brak kasy = sankcja."] } { object.get(input.jdg_entrepreneur, "b2c_limit_breached_this_month", false) == true }

# P576: cash_register_daily_report — Raport dobowy + archiwizacja
else := { "matched": true, "rule_id": "jdg.edge_cases.cash_register_daily_report", "package": "jdg.edge_cases", "priority": 718, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "daily_report_required": true, "archive_years": 5, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 111 ust. 3a VAT", "_warnings": ["RAPORT DOBOWY — obowiązek codziennego raportu fiskalnego + miesięcznego. Archiwizacja 5 lat. Brak raportu = ryzyko kontroli!"] } { object.get(input.jdg_entrepreneur, "cash_register_installed", false) == true }

# P577: cash_register_service_review_2yr — Przegląd techniczny co 2 lata
else := { "matched": true, "rule_id": "jdg.edge_cases.cash_register_service_review", "package": "jdg.edge_cases", "priority": 719, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "service_review_due": true, "review_interval_months": 24, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Przegląd techniczny kasy fiskalnej wymagany", "_legal_basis": "Rozp. MF ws. kas rejestrujących", "_warnings": ["PRZEGLĄD KASY — wymagany co 2 lata przez autoryzowany serwis. Brak przeglądu = kasa nieważna! Umów serwisanta."] } { object.get(input.jdg_entrepreneur, "cash_register_service_overdue", false) == true }

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  GRUPA O: R0720-R0727 — DOC 36 §8+§7: GOTÓWKA + AUDYT                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# P390: cash_limit_single_day_15k — Limit dzienny gotówki
else := { "matched": true, "rule_id": "jdg.edge_cases.cash_daily_aggregate_15k", "package": "jdg.edge_cases", "priority": 720, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "NKUP", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "cash_daily_limit_exceeded": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Łączny limit gotówki 15k PLN dziennie", "_legal_basis": "Art. 22p PIT", "_warnings": ["GOTÓWKA — łączny limit 15 000 PLN dziennie dla jednego kontrahenta. Agregacja wszystkich faktur!"] } { object.get(input.invoice, "cash_daily_total_exceeds_15k", false) == true }

# P393: cash_sanction_kup_loss — Utrata KUP + sankcja 20%
else := { "matched": true, "rule_id": "jdg.edge_cases.cash_sanction_kup_loss_20pct", "package": "jdg.edge_cases", "priority": 721, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "NKUP", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "cash_sanction_pct": 20, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Gotówka >15k — NKUP + sankcja 20%", "_legal_basis": "Art. 22p PIT", "_warnings": ["SANKCJA GOTÓWKOWA — NKUP + 20% sankcji od kwoty transakcji za płatność gotówką >15 000 PLN!"] } { object.get(input.invoice, "cash_over_15k_violation", false) == true }

# P380: audit_inspection_notice_7days — Obowiązek udostępnienia dokumentów
else := { "matched": true, "rule_id": "jdg.edge_cases.audit_inspection_notice", "package": "jdg.edge_cases", "priority": 722, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "audit_document_deadline_days": 7, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Kontrola — udostępnij dokumenty w 7 dni", "_legal_basis": "Art. 287 Ordynacji podatkowej", "_warnings": ["KONTROLA SKARBOWA — obowiązek udostępnienia dokumentów w ciągu 7 dni od wezwania. Możesz wnioskować o przedłużenie terminu."] } { object.get(input.jdg_entrepreneur, "tax_audit_in_progress", false) == true; object.get(input.jdg_entrepreneur, "documents_requested", false) == true }

# P382: audit_protocol_obligation — Obowiązek podpisania protokołu
else := { "matched": true, "rule_id": "jdg.edge_cases.audit_protocol_obligation", "package": "jdg.edge_cases", "priority": 723, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "protocol_objections_days": 7, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 291 Ordynacji podatkowej", "_warnings": ["PROTOKÓŁ KONTROLI — masz 7 dni na zgłoszenie zastrzeżeń do protokołu. Po tym terminie protokół uznaje się za przyjęty."] } { object.get(input.jdg_entrepreneur, "audit_protocol_delivered", false) == true }

# P383: audit_statute_suspension — Zawieszenie przedawnienia
else := { "matched": true, "rule_id": "jdg.edge_cases.audit_statute_suspension", "package": "jdg.edge_cases", "priority": 724, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "statute_suspended_in_audit": true, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 70 § 6 Ordynacji podatkowej", "_warnings": ["ZAWIESZENIE PRZEDAWNIENIA — w trakcie kontroli skarbowej bieg przedawnienia jest ZAWIESZONY. Nie licz na przedawnienie!"] } { object.get(input.jdg_entrepreneur, "tax_audit_in_progress", false) == true }

# P510: tax_audit_notification_7days — Zawiadomienie o kontroli
else := { "matched": true, "rule_id": "jdg.edge_cases.tax_audit_notification_7days", "package": "jdg.edge_cases", "priority": 725, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "audit_notification_days": 7, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 282b Ordynacji podatkowej", "_warnings": ["Zawiadomienie o kontroli — 7 dni przed rozpoczęciem. Skorzystaj z czynnego żalu jeśli masz zaległości przed rozpoczęciem kontroli!"] } { object.get(input.jdg_entrepreneur, "audit_notification_received", false) == true }

# P511: tax_audit_right_to_correct_14days — Prawo do korekty po protokole
else := { "matched": true, "rule_id": "jdg.edge_cases.tax_audit_right_to_correct", "package": "jdg.edge_cases", "priority": 726, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "correction_window_days": 14, "_routing": "", "_routing_reason": "", "_legal_basis": "Art. 81 Ordynacji podatkowej", "_warnings": ["PRAWO DO KOREKTY — masz 14 dni od doręczenia protokołu kontroli na złożenie korekty deklaracji. Po tym terminie: tylko odwołanie!"] } { object.get(input.jdg_entrepreneur, "audit_protocol_delivered", false) == true; object.get(input.jdg_entrepreneur, "correction_submitted", true) == false }

# P516: tax_audit_vat_refund_suspension — Wstrzymanie zwrotu VAT
else := { "matched": true, "rule_id": "jdg.edge_cases.tax_audit_vat_refund_suspension", "package": "jdg.edge_cases", "priority": 727, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "vat_refund_suspended": true, "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Zwrot VAT wstrzymany — trwa kontrola", "_legal_basis": "Art. 87 ust. 2 VAT", "_warnings": ["ZWROT VAT WSTRZYMANY — w trakcie kontroli US może wstrzymać zwrot VAT do czasu zakończenia kontroli. Po kontroli: zwrot + odsetki."] } { object.get(input.jdg_entrepreneur, "tax_audit_in_progress", false) == true; object.get(input.jdg_entrepreneur, "vat_refund_pending", false) == true }
