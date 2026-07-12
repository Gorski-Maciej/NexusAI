# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Edge Cases: VAT, PIT, ZUS, Sankcje, Terminy
# Doc 28a: R0546-R0672 — Grupy A-C, G-H (67+27=94 reguł)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Edge Cases Package — VAT, PIT, ZUS Edge Cases + Sanctions + Deadlines
# description: |
#   Implementacja Doc 28a ENTERPRISE v1.0 edge cases. First-Match-Wins else-chain.
#   Grupa A: VAT Edge Cases (R0546-R0559, 14 reguł)
#   Grupa B: PIT Edge Cases (R0560-R0573, 14 reguł)
#   Grupa C: ZUS Edge Cases (R0574-R0585, 12 reguł)
#   Grupa G: Sankcje (R0646-R0655, 10 reguł)
#   Grupa H: Terminy / Deadlines (R0656-R0672, 17 reguł)
# legal_basis: Art. 113, 19a, 31a, 86a, 106d, 106e VAT; Art. 9, 23, 24, 26e,
#              27g, 30ca PIT; Art. 18a, 18c, 36a SUS; Art. 44, 45, 47, 48-52,
#              54, 56, 60, 62, 76, 77-79, 83 KKS; Art. 96b, 108a, 109, 106na,
#              106nq VAT; Art. 22p, 26h, 26eb, 26ec PIT; Art. 70, 78, 81 OrdPU
# package: jdg.edge_cases
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.edge_cases

import data.jdg.helpers

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

else := { "matched": true, "rule_id": "jdg.edge_cases.pit_linear_health_underpayment", "package": "jdg.edge_cases", "priority": 563, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "LINEAR", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "ceidg_registration_required": false, "_routing": "TRIAGE_QUEUE", "_routing_reason": "Liniowy: odliczenie zdrowotnej max 12 900 PLN", "_legal_basis": "Art. 30c ust. 2 PIT", "_warnings": ["Podatek liniowy — max odliczenie składki zdrowotnej 12 900 PLN rocznie"] } { input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "zus_health_paid_ytd", 0) > 12900 }

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

# R0633: limit_health_linear_deduction_12900 — Max odliczenie zdrowotnej liniowy
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_health_linear_12900",
    "package": "jdg.edge_cases", "priority": 633,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LINEAR", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "HEALTH_DEDUCTION_LINEAR", "limit_value": 12900,
    "health_paid": health_paid, "deductible": deduct,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 30c ust. 2 PIT",
    "_warnings": [sprintf("Liniowy: zapłacona zdrowotna %.2f PLN, max odliczenie 12 900 PLN. Odliczasz %.2f PLN", [health_paid, deduct])]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
    health_paid := object.get(input.jdg_entrepreneur, "zus_health_paid_ytd", 0)
    health_paid > 10000
    deduct = health_paid { health_paid <= 12900 }
    deduct = 12900 { health_paid > 12900 }
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

# R0639: limit_pit0_combined_85528 — PIT-0 łączny limit 85 528 PLN
else := {
    "matched": true, "rule_id": "jdg.edge_cases.limit_pit0_combined_85528",
    "package": "jdg.edge_cases", "priority": 639,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "limit_name": "PIT0_COMBINED", "limit_value": 85528,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Łączny limit PIT-0 przekroczony",
    "_legal_basis": "Art. 21 ust. 1 pkt 148-154 PIT",
    "_warnings": [sprintf("PIT-0: łączna kwota zwolnień %.2f PLN przekracza limit 85 528 PLN. Nadwyżka opodatkowana.", [pit0_total])]
} {
    pit0_total := object.get(input.jdg_entrepreneur, "pit0_total_exempt", 0)
    pit0_total > 85528
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
