# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE EXIT TAX + MDR (Strategic Initiative S16)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Exit Tax + MDR/DAC6 + CFC Complete Coverage
# description: |
#   ENTERPRISE v6.0 — Pełne pokrycie Klasy C dla JDG:
#   - Exit Tax (Art. 30da PIT) — przeniesienie aktywów za granicę
#   - CFC (Art. 30f PIT) — zagraniczna spółka kontrolowana
#   - MDR/DAC6 (Art. 86a-86o OrdPU) — raportowanie schematów podatkowych
#   - Transfer Pricing (Art. 23zf PIT) — ceny transferowe dla JDG
#   - Estoński CIT vs PIT — analiza dla JDG rozważających Sp. z o.o.
#   
#   KLUCZOWA INNOWACJA: Wszystkie reguły transgraniczne w jednym pakiecie
#   z automatyczną detekcją obowiązków raportowych.
# architecture: Enterprise Cross-Border Engine, First-Match-Wins else-chain
# legal_basis: Art. 30da, 30f PIT; Art. 86a-86o OrdPU (MDR); Dyrektywa DAC6
# package: jdg.exit_tax_mdr
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.exit_tax_mdr

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.exit_tax_mdr.no_match",
    "package": "jdg.exit_tax_mdr", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ET-001: EXIT TAX DETECTION — Przeniesienie aktywów JDG za granicę
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.exit_tax.asset_transfer_abroad_detected",
    "package": "jdg.exit_tax_mdr",
    "priority": 1,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "0.19", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "exit_tax_applies": true,
    "exit_tax_rate": "19% (3% od podstawy opodatkowania dla wartości < 4M PLN)",
    "exit_tax_asset_value": asset_fmv,
    "exit_tax_asset_tax_basis": asset_tax_basis,
    "exit_tax_unrealized_gain": unrealized_gain,
    "exit_tax_estimated_pln": exit_tax_amount,
    "exit_tax_deferral_possible": deferral_available,
    "exit_tax_destination_country": destination,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("EXIT TAX — przeniesienie aktywów %.0f PLN do %s. Podatek: %.0f PLN",
        [asset_fmv, destination, exit_tax_amount]),
    "_legal_basis": "Art. 30da PIT; Art. 30dh PIT (exit tax deferral)",
    "_warnings": [
        sprintf("🚨 EXIT TAX (Art. 30da PIT): Przenosisz %s (FMV: %.0f PLN) do %s.", [asset_name, asset_fmv, destination]),
        sprintf("💰 Niezrealizowany zysk: %.0f PLN. Podatek 19%%: %.0f PLN (lub 3%% od FMV jeśli < 4M PLN).",
            [unrealized_gain, exit_tax_amount]),
        sprintf("⏰ Termin: do 7. dnia miesiąca po miesiącu przeniesienia. Deklaracja: PIT-NZ."),
        deferral_msg
    ]
} {
    input.exit_tax_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    asset_name := object.get(input.invoice, "description", "aktywa")
    asset_fmv := object.get(input.invoice, "asset_fair_market_value", 0)
    asset_tax_basis := object.get(input.invoice, "asset_tax_basis_pl", 0)
    destination := object.get(input.vendor, "country", "N/A")
    
    is_transfer_abroad := object.get(input.invoice, "is_transfer_abroad", false)
    is_transfer_abroad == true
    asset_fmv > 0
    
    unrealized_gain := asset_fmv - asset_tax_basis
    exit_tax_amount := unrealized_gain * 0.19 { unrealized_gain > 0 }
    exit_tax_amount := 0 { unrealized_gain <= 0 }
    
    # Deferral: possible if transfer to EU/EEA country
    eu_eea_countries := {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IS","IE","IT","LV",
                         "LI","LT","LU","MT","NL","NO","PL","PT","RO","SK","SI","ES","SE","CH"}
    deferral_available := destination in eu_eea_countries
    
    deferral_msg := "✅ ODLICZENIE RATALNE: Transfer do UE/EOG → podatek w 5 ratach rocznych." { deferral_available }
    deferral_msg := "⚠️ BRAK odroczenia: transfer poza UE/EOG → podatek płatny jednorazowo." { not deferral_available }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CFC-001: FOREIGN CONTROLLED COMPANY — CFC dla JDG
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax.cfc_foreign_company_detected",
    "package": "jdg.exit_tax_mdr",
    "priority": 10,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "0.19", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cfc_detected": true,
    "cfc_company_name": cfc_company,
    "cfc_country": cfc_country,
    "cfc_control_percentage": control_pct,
    "cfc_passive_income_pct": passive_pct,
    "cfc_estimated_cfc_income_pln": cfc_income_attributed,
    "cfc_reporting_obligation": "PIT-CFC do 30 września następnego roku",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("CFC wykryta: %s (%s) — %.0f%% kontroli, %.0f%% dochodu pasywnego",
        [cfc_company, cfc_country, control_pct * 100, passive_pct * 100]),
    "_legal_basis": "Art. 30f PIT; Art. 45 ust. 1aa PIT (PIT-CFC)",
    "_warnings": [
        sprintf("🏢 CFC (Art. 30f PIT): Kontrolujesz %s w %s.", [cfc_company, cfc_country]),
        sprintf("📊 Udział: %.0f%%, dochód pasywny: %.0f%% (próg: 33%%).", [control_pct * 100, passive_pct * 100]),
        sprintf("💰 Dochód CFC do opodatkowania w PL: %.0f PLN (19%% ≡ %.0f PLN podatku).",
            [cfc_income_attributed, cfc_income_attributed * 0.19]),
        sprintf("📋 OBOWIĄZEK: PIT-CFC + zapłać 19%% podatku od dochodu CFC. Termin: 30 września."),
        "⚠️ Kara za niezgłoszenie CFC: do 720 stawek dziennych KKS!"
    ]
} {
    input.cfc_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    cfc_company := object.get(input.jdg_entrepreneur, "cfc_company_name", "Spółka zagraniczna")
    cfc_country := object.get(input.jdg_entrepreneur, "cfc_country", "N/A")
    control_pct := object.get(input.jdg_entrepreneur, "cfc_ownership_pct", 0)
    passive_pct := object.get(input.jdg_entrepreneur, "cfc_passive_income_pct", 0)
    cfc_total_income := object.get(input.jdg_entrepreneur, "cfc_total_income_pln", 0)
    
    # CFC trigger: >50% ownership AND >33% passive income
    control_pct > 0.50
    passive_pct > 0.33
    
    cfc_income_attributed := cfc_total_income * control_pct
}

# ═══════════════════════════════════════════════════════════════════════════════
# MDR-001: MANDATORY DISCLOSURE RULES (DAC6) — Schematy podatkowe
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax.mdr_scheme_detected",
    "package": "jdg.exit_tax_mdr",
    "priority": 20,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "mdr_reportable": true,
    "mdr_hallmark_category": hallmark,
    "mdr_scheme_description": scheme_desc,
    "mdr_reporting_deadline": "30 dni od udostępnienia schematu",
    "mdr_form": "MDR-1 (lub MDR-3 dla korzystającego)",
    "mdr_potential_penalty_pln": "do 21 000 000 PLN (Art. 86o OrdPU)",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("MDR/DAC6: schemat podatkowy kat. %s — obowiązek raportowania", [hallmark]),
    "_legal_basis": "Art. 86a-86o OrdPU; Dyrektywa DAC6 (2018/822); Rozporządzenie MF ws. MDR",
    "_warnings": [
        sprintf("🚨 MDR/DAC6 (Art. 86a OrdPU): Wykryto schemat podatkowy kategorii '%s'!", [hallmark]),
        sprintf("📋 %s", [scheme_desc]),
        sprintf("⏰ TERMIN: Zgłoś MDR-1 w ciągu 30 dni od udostępnienia schematu!"),
        sprintf("💰 Kara za brak zgłoszenia: DO 21 000 000 PLN (Art. 86o § 1 OrdPU)!"),
        "📝 Formularz: MDR-1 (promotor) / MDR-3 (korzystający) przez e-US."
    ]
} {
    input.mdr_check == true
    hallmark := object.get(input.invoice, "mdr_hallmark", "")
    hallmark in {"A_GENERIC", "B_SPECIFIC", "C_CROSS_BORDER", "D_EXCHANGE", "E_TRANSFER_PRICING"}
    scheme_desc := object.get(input.invoice, "mdr_scheme_description", "")
    scheme_desc != ""
    # MDR triggers automatically when hallmark detected
}

# ═══════════════════════════════════════════════════════════════════════════════
# TP-001: TRANSFER PRICING — Transakcje z podmiotami powiązanymi
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax.transfer_pricing_obligation",
    "package": "jdg.exit_tax_mdr",
    "priority": 30,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tp_obligation": true,
    "tp_related_party": related_party,
    "tp_transaction_value": tx_value,
    "tp_documentation_required": tp_doc_required,
    "tp_method": recommended_method,
    "tp_form": "TP-R (do 31 grudnia następnego roku)",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": tp_routing,
    "_routing_reason": tp_reason,
    "_legal_basis": "Art. 23zf PIT; Art. 11a-11q CIT (przez analogię); Rozporządzenie MF ws. TP",
    "_warnings": tp_warnings
} {
    input.tp_check == true
    related_party := object.get(input.vendor, "name", "Podmiot powiązany")
    tx_value := object.get(input.invoice, "amount_net", 0)
    is_related := object.get(input.vendor, "is_related_party", false)
    is_related == true
    tx_value > 0
    
    # TP documentation thresholds for JDG (from thresholds or fallback)
    tp_doc_threshold := object.get(object.get(data.thresholds, "tp", {}), "documentation_threshold_pln", 2000000)
    tp_doc_required := tx_value > tp_doc_threshold
    
    recommended_method := "CUP (porównywalnej ceny niekontrolowanej)" { tx_value < 100000 }
    recommended_method := "TNMM (marży transakcyjnej netto)" { tx_value >= 100000 }
    
    tp_routing := "BLOCK_AND_ALERT" { tp_doc_required }
    tp_routing := "TRIAGE_QUEUE" { tx_value > 500000; not tp_doc_required }
    tp_routing := "" { tx_value <= 500000; not tp_doc_required }
    
    tp_reason := sprintf("TP: transakcja %.0f PLN z podmiotem powiązanym — dokumentacja wymagana", [tx_value]) { tp_doc_required }
    tp_reason := sprintf("TP: transakcja %.0f PLN — rozważ dokumentację uproszczoną", [tx_value]) { tx_value > 500000; not tp_doc_required }
    tp_reason := "" { tx_value <= 500000; not tp_doc_required }
    
    tp_warnings := [
        sprintf("🔗 CENY TRANSFEROWE: Transakcja %.0f PLN z '%s' (podmiot powiązany).", [tx_value, related_party]),
        sprintf("📋 %s", [tp_doc_msg]),
        sprintf("💡 Rekomendowana metoda: %s.", [recommended_method]),
        "📝 Formularz: TP-R do 31 grudnia następnego roku."
    ]
    
    tp_doc_msg := "DOKUMENTACJA TP WYMAGANA — lokalna + grupowa (master file) jeśli > 20M PLN." { tp_doc_required }
    tp_doc_msg := "Dokumentacja uproszczona zalecana (transakcja < 2M PLN)." { not tp_doc_required; tx_value > 500000 }
    tp_doc_msg := "Transakcja poniżej progu — dokumentacja nieobowiązkowa." { tx_value <= 500000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CIT-EST: ESTOŃSKI CIT — Analiza opłacalności dla JDG rozważających Sp. z o.o.
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax.estonian_cit_vs_pit_analysis",
    "package": "jdg.exit_tax_mdr",
    "priority": 40,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "estonian_cit_available": est_available,
    "estonian_cit_effective_tax_rate": sprintf("%.1f%%", [est_tax_rate * 100]),
    "estonian_cit_annual_savings_vs_jdg": annual_savings,
    "estonian_cit_recommendation": recommendation,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Estoński CIT: oszczędność %.0f PLN/rok vs obecna forma JDG", [annual_savings]),
    "_legal_basis": "Art. 28c-28t CIT (estoński CIT); Art. 30c PIT (liniowy 19%)",
    "_warnings": [
        sprintf("🏢 ESTOŃSKI CIT: Analiza opłacalności przejścia z JDG na Sp. z o.o. z CIT estońskim."),
        sprintf("💰 JDG (PIT %s): %.0f PLN podatku. Estoński CIT 9%%: %.0f PLN (przy reinwestycji: 0 PLN!).",
            [pit_form, pit_tax, est_tax]),
        sprintf("📊 Roczna oszczędność: %.0f PLN (%.0f%%).", [annual_savings, savings_pct]),
        sprintf("💡 %s", [recommendation]),
        "⚠️ Warunki: brak udziałowców niebędących osobami fizycznymi, zatrudnienie min. 3 os. (lub wydatki inwestycyjne)."
    ]
} {
    input.estonian_cit_analysis == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_actual", 120000)
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 300000)
    reinvests_profits := object.get(input.jdg_entrepreneur, "reinvests_profits", false)
    has_3_employees := object.get(input.jdg_entrepreneur, "employee_count", 0) >= 3
    # 2M EUR threshold for small taxpayer (use threshold data)
    eur_pln_rate := object.get(object.get(data.thresholds, "bounds", {}), "eur_pln", 4.5)
    small_taxpayer_limit_eur := 2000000
    small_taxpayer_limit_pln := small_taxpayer_limit_eur * eur_pln_rate
    is_small_taxpayer := annual_revenue < small_taxpayer_limit_pln
    
    est_available := is_small_taxpayer and (has_3_employees or reinvests_profits)
    
    # PIT tax calculation
    pit_tax := annual_profit * 0.19 { pit_form == "LINEAR" }
    pit_tax := annual_profit * 0.12 { pit_form == "PIT_SCALE"; annual_profit <= 120000 }
    pit_tax := 14400 + (annual_profit - 120000) * 0.32 { pit_form == "PIT_SCALE"; annual_profit > 120000 }
    
    # Estoński CIT: 9% of distributed profit (0% if reinvested)
    est_tax_rate := 0.09 { is_small_taxpayer }
    est_tax_rate := 0.15 { not is_small_taxpayer }
    est_tax := annual_profit * est_tax_rate { not reinvests_profits }
    est_tax := 0 { reinvests_profits }
    
    annual_savings := pit_tax - est_tax
    savings_pct := annual_savings / max([pit_tax, 1]) * 100
    
    recommendation := "✅ PRZEJDŹ NA CIT ESTOŃSKI — znacząca oszczędność i odroczenie podatku." { annual_savings > 20000 }
    recommendation := "⚠️ ROZWAŻ CIT ESTOŃSKI — wymaga analizy kosztów administracyjnych (ZUS, księgowość)." { annual_savings > 5000; annual_savings <= 20000 }
    recommendation := "❌ POZOSTAŃ NA JDG — zmiana nieopłacalna przy obecnych dochodach." { annual_savings <= 5000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INT-001: INTERNATIONAL TAX TREATY ANALYZER — Analiza UPO
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax.double_tax_treaty_analyzer",
    "package": "jdg.exit_tax_mdr",
    "priority": 50,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_treaty_applies": true,
    "tax_treaty_country": foreign_country,
    "tax_treaty_method": treaty_method,
    "tax_treaty_foreign_tax_paid": foreign_tax_paid,
    "tax_treaty_polish_tax_before_relief": pl_tax_before,
    "tax_treaty_polish_tax_after_relief": pl_tax_after,
    "tax_treaty_relief_amount": tax_relief,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 27 ust. 8-9 PIT; Umowy o unikaniu podwójnego opodatkowania (UPO)",
    "_warnings": [
        sprintf("🌍 UPO: Dochód z %s — metoda %s.", [foreign_country, treaty_method]),
        sprintf("💰 Podatek za granicą: %.0f PLN. Podatek w PL przed ulgą: %.0f PLN.", [foreign_tax_paid, pl_tax_before]),
        sprintf("📊 Po zastosowaniu UPO: %.0f PLN podatku w PL. Ulga: %.0f PLN.", [pl_tax_after, tax_relief]),
        "📋 PIT-36 + PIT-ZG — wykaż dochód zagraniczny i podatek zapłacony za granicą."
    ]
} {
    input.international_tax_treaty_check == true
    foreign_country := object.get(input.jdg_entrepreneur, "foreign_income_country", "N/A")
    foreign_income := object.get(input.jdg_entrepreneur, "foreign_income_pln", 0)
    foreign_tax_paid := object.get(input.jdg_entrepreneur, "foreign_tax_paid_pln", 0)
    foreign_income > 0
    
    # Treaty method determination
    # Proportional deduction: most common for Polish UPOs
    treaty_method := "proporcjonalne odliczenie (Art. 27 ust. 9 PIT)"
    
    # Polish tax before relief
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pl_tax_rate := 0.19 { pit_form == "LINEAR" }
    pl_tax_rate := 0.12 { pit_form == "PIT_SCALE" }
    pl_tax_before := foreign_income * pl_tax_rate
    
    # Relief: lower of foreign tax paid and Polish tax on foreign income
    tax_relief := min([foreign_tax_paid, pl_tax_before])
    pl_tax_after := pl_tax_before - tax_relief
}

# ═══════════════════════════════════════════════════════════════════════════════
# AGGREGATE: CROSS-BORDER RISK SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax.cross_border_risk_summary",
    "package": "jdg.exit_tax_mdr",
    "priority": 999,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_border_active_flags": active_flags,
    "cross_border_total_risk_score": total_risk,
    "cross_border_next_filing_deadline": next_deadline,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": cb_routing,
    "_routing_reason": cb_reason,
    "_legal_basis": "Art. 30da, 30f PIT; Art. 86a-86o OrdPU; Dyrektywa DAC6; UPO",
    "_warnings": cb_warnings
} {
    input.cross_border_risk_summary == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    
    active_flags := []
    active_flags := array.concat(active_flags, ["EXIT_TAX"]) { object.get(input.jdg_entrepreneur, "exit_tax_active", false) }
    active_flags := array.concat(active_flags, ["CFC"]) { object.get(input.jdg_entrepreneur, "cfc_active", false) }
    active_flags := array.concat(active_flags, ["MDR"]) { object.get(input.jdg_entrepreneur, "mdr_active", false) }
    active_flags := array.concat(active_flags, ["TP"]) { object.get(input.jdg_entrepreneur, "tp_active", false) }
    active_flags := array.concat(active_flags, ["UPO"]) { object.get(input.jdg_entrepreneur, "tax_treaty_applies", false) }
    
    total_risk := count(active_flags) * 20
    next_deadline := "Sprawdź indywidualne terminy" { count(active_flags) > 0 }
    next_deadline := "Brak" { count(active_flags) == 0 }
    
    cb_routing := "BLOCK_AND_ALERT" { count(active_flags) >= 3 }
    cb_routing := "TRIAGE_QUEUE" { count(active_flags) > 0; count(active_flags) < 3 }
    cb_routing := "" { count(active_flags) == 0 }
    
    cb_reason := sprintf("%d aktywnych obowiązków transgranicznych", [count(active_flags)]) { count(active_flags) > 0 }
    cb_reason := "" { count(active_flags) == 0 }
    
    cb_warnings := [sprintf("🌍 CROSS-BORDER RISK: %d aktywnych flag: %s. Łączne ryzyko: %d/100.",
        [count(active_flags), concat(", ", active_flags), total_risk])]
}
