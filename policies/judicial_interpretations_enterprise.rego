# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE JUDICIAL RULINGS & INTERPRETATIONS ENGINE (S3)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Metadata documentation (kept as ordinary comments; no executable annotation).
# title: JDG Enterprise Judicial Rulings — NSA Wyroki + KIS Interpretacje + WIS
# description: |
#   ENTERPRISE v5.0 — Silnik integrujący wyroki NSA, interpretacje KIS,
#   Wiążące Informacje Stawkowe (WIS), Wiążące Informacje Akcyzowe (WIA),
#   interpretacje ogólne MF i orzecznictwo TSUE. System śledzi linię
#   orzeczniczą i ostrzega przed niekorzystnymi wyrokami.
#   Wypełnia krytyczną lukę: interpretacja "szarej strefy" prawa.
# architecture: Enterprise Judicial Engine, First-Match-Wins else-chain
# legal_basis: Wyroki NSA, Interpretacje KIS, WIS, WIA, TSUE, MF
# package: jdg.judicial_rulings
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.judicial_rulings

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

is_one_of(value, first, second) = true if { value == first } else = true if { value == second } else = false
contains_any(text, first, second) = true if { contains(text, first) } else = true if { contains(text, second) } else = false
asset_loss_value(expense_type, description) = true if { expense_type == "ASSET_LOSS" } else = true if { contains(description, "strata sprzedaż") } else = false
catering_value(expense_type, description) = true if { expense_type == "CATERING" } else = true if { contains_any(description, "catering", "posiłki") } else = false
both_true(first, second) = true if { first; second } else = false
representation_risk_value(event, advertising) = true if { event; not advertising } else = false
clothing_value(expense_type, description) = true if { expense_type == "CLOTHING"; contains(description, "logo") } else = false
nsa_kus_qual_value(ruling_count) = "deductible_full" if { ruling_count > 0 } else = "non_deductible"
nsa_kus_pct_value(qual, has_log, uses_car) = 75 if { uses_car; not has_log } else = 100 if { qual == "deductible_full" } else = 0
nsa_unfavorable_value(rep_risk) = 1 if { rep_risk } else = 0
nsa_risk_value(favorable, unfavorable, rep_risk) = "HIGH" if { unfavorable > 1 } else = "MEDIUM" if { rep_risk } else = "MEDIUM" if { favorable >= 1 } else = "LOW"
judicial_routing_value(risk) = "BLOCK_AND_ALERT" if { risk == "HIGH" } else = "TRIAGE_QUEUE" if { risk == "MEDIUM" } else = ""
judicial_reason_value(risk, rulings) = sprintf("Niekorzystna linia orzecznicza dla: %s", [concat(", ", rulings)]) if { risk == "HIGH" } else = "Wydatek w 'szarej strefie' — sprawdź linię orzeczniczą" if { risk == "MEDIUM" } else = ""

kis_needs_value(expense_type, amount) = true if { expense_type == "BUSINESS_TRANSFORMATION" } else = true if { expense_type == "INTANGIBLE_ASSET_TRANSFER"; amount > 50000 } else = true if { expense_type == "CROSS_BORDER_SERVICES"; amount > 100000 } else = true if { expense_type == "IP_TRANSFER_JDG_TO_COMPANY" } else = true if { expense_type == "HOMEOFFICE_EQUIPMENT"; amount > 10000 } else = false
kis_recommendation_value(needs, expense_type) = "ZALECANA INTERPRETACJA INDYWIDUALNA — wydatek > 10 000 PLN w niejednoznacznej kategorii. Interpretacja chroni przed negatywną decyzją US (Art. 14k-14m OrdPU)." if { needs } else = sprintf("NIEPOTRZEBNA interpretacja dla %s. Istnieje ugruntowana linia orzecznicza i interpretacyjna.", [expense_type])
kis_qual_value(needs) = "deductible_requires_interpretation" if { needs } else = "deductible_full"
kis_pct_value(needs) = 0 if { needs } else = 100
kis_routing_value(needs) = "TRIAGE_QUEUE" if { needs } else = ""
kis_reason_value(needs, amount, expense_type) = sprintf("Wydatek %.2f PLN w kategorii %s — zalecana interpretacja indywidualna KIS", [amount, expense_type]) if { needs } else = ""
kis_advice_value(needs) = "Złóż wniosek o interpretację indywidualną (KIS, 40 PLN). Czas oczekiwania: ~3 miesiące. Interpretacja WIĄŻE US w Twojej sprawie (Art. 14k § 1 OrdPU). Chroni przed sankcjami KKS (Art. 10 § 4 KKS)." if { needs } else = "Nie wymaga interpretacji."

wis_binding_rate_value(needs) = "" if { needs } else = "0.00"
wis_routing_value(needs, amount) = "TRIAGE_QUEUE" if { needs; amount > 10000 } else = ""
wis_reason_value(needs, amount, product_type) = sprintf("Produkt %s — niejednoznaczna stawka VAT. WIS zalecana przy kwocie > 10k PLN.", [product_type]) if { needs; amount > 10000 } else = ""

mf_qual_value(meal, documented, luxury) = "deductible_full" if { meal; documented; not luxury } else = "non_deductible" if { meal; luxury; not documented } else = "depends_on_context" if { meal } else = ""
mf_pct_value(qual) = 100 if { qual == "deductible_full" } else = 0 if { qual == "non_deductible" } else = 50 if { qual == "depends_on_context" } else = 0

tsue_impact_value(platform, cross_border, reverse_charge, oss, platform_note, oss_note) = sprintf("TSUE C-695/20 (VAT platformy cyfrowe): Jako sprzedawca na platformie, możesz być zobowiązany do VAT w kraju kupującego. %s", [platform_note]) if { platform; cross_border } else = "TSUE C-276/22 (Reverse charge): Reverse charge obowiązuje nawet gdy kontrahent nie wystawił faktury z adnotacją. Odpowiadasz solidarnie za VAT." if { reverse_charge } else = sprintf("TSUE C-298/22 (OSS procedura): %s", [oss_note]) if { oss } else = "BRAK"
tsue_routing_value(impact) = "TRIAGE_QUEUE" if { impact != "BRAK" } else = ""
tsue_reason_value(impact) = "Wyrok TSUE ma zastosowanie do tej transakcji — zweryfikuj zgodność." if { impact != "BRAK" } else = ""
default decide := {
    "matched": false, "rule_id": "jdg.judicial.no_match",
    "package": "jdg.judicial_rulings", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# S3-300: NSA RULING IMPACT — Wpływ wyroków NSA na decyzje podatkowe
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.judicial.nsa_ruling_impact",
    "package": "jdg.judicial_rulings",
    "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": kus_qual, "kus_percent": kus_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "judicial_applicable_rulings": applicable_rulings,
    "judicial_favorable_line": favorable_count,
    "judicial_unfavorable_line": unfavorable_count,
    "judicial_risk_level": risk_level,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": judicial_routing,
    "_routing_reason": judicial_reason,
    "_legal_basis": "Art. 14a-14h OrdPU (interpretacje); Art. 42a VAT (WIS); Art. 7d KKS",
    "_warnings": build_judicial_warnings(applicable_rulings, risk_level)
} if {
    input.judicial_rulings_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "expense_type", "GENERAL")
    expense_description := object.get(input.invoice, "description", "")
    amount_net := object.get(input.invoice, "amount_net", 0)
    uses_company_car := object.get(input.jdg_entrepreneur, "vehicle_used_for_business", false)
    has_mileage_log := object.get(input.jdg_entrepreneur, "vehicle_mileage_log_maintained", false)

    # NSA II FSK 2345/17: Reprezentacja vs Reklama — KLUCZOWY wyrok
    is_event := is_one_of(expense_type, "EVENT", "ENTERTAINMENT")
    is_advertising := object.get(input.invoice, "has_advertising_purpose", false)
    is_representation_risk := representation_risk_value(is_event, is_advertising)

    # NSA II FSK 1319/18: Auto firmowe — pełne odliczenie przy ewidencji
    uses_company_car_and_log := both_true(uses_company_car, has_mileage_log)

    # NSA II FSK 1023/19: Koszty szkoleń — KUP nawet bez bezpośredniego związku
    is_training := is_one_of(expense_type, "TRAINING", "EDUCATION")

    # NSA II FSK 670/20: Wydatki na integrację pracowników — KUP
    is_integration := contains_any(expense_description, "integracja", "team building")

    # NSA II FSK 1434/21: Strata na sprzedaży środka trwałego — KUP
    is_asset_loss := asset_loss_value(expense_type, expense_description)

    # NSA II FSK 2156/22: Wydatki na ubrania firmowe — KUP (musi być logo)
    is_clothing := clothing_value(expense_type, expense_description)

    # NSA II FSK 388/23: Wydatki na catering dla pracowników — KUP
    is_catering := catering_value(expense_type, expense_description)

    ruling_candidates := [
        {"id": "NSA_II_FSK_2345_17_REPRESENTATION_VS_ADVERTISING", "enabled": is_representation_risk},
        {"id": "NSA_II_FSK_1319_18_CAR_FULL_DEDUCTION", "enabled": uses_company_car_and_log},
        {"id": "NSA_II_FSK_1023_19_TRAINING_KUP", "enabled": is_training},
        {"id": "NSA_II_FSK_670_20_INTEGRATION_KUP", "enabled": is_integration},
        {"id": "NSA_II_FSK_1434_21_ASSET_LOSS_KUP", "enabled": is_asset_loss},
        {"id": "NSA_II_FSK_2156_22_CLOTHING_KUP", "enabled": is_clothing},
        {"id": "NSA_II_FSK_388_23_CATERING_KUP", "enabled": is_catering}
    ]
    applicable_rulings := [candidate.id | candidate := ruling_candidates[_]; candidate.enabled]
    favorable_count := count(applicable_rulings)
    unfavorable_count := nsa_unfavorable_value(is_representation_risk)
    kus_qual := nsa_kus_qual_value(favorable_count)
    kus_pct := nsa_kus_pct_value(kus_qual, has_mileage_log, uses_company_car)
    risk_level := nsa_risk_value(favorable_count, unfavorable_count, is_representation_risk)
    judicial_routing := judicial_routing_value(risk_level)
    judicial_reason := judicial_reason_value(risk_level, applicable_rulings)
}

build_judicial_warnings(rulings, risk) = [sprintf("🔴 NIEKORZYSTNA LINIA ORZECZNICZA: %s", [concat(", ", rulings)]), "🚫 Wyroki NSA wskazują, że ten wydatek NIE stanowi KUP!"] if { risk == "HIGH" } else = [sprintf("⚠️ SZARA STREFA ORZECZNICZA — %s", [concat(", ", rulings)]), "⚖️ Linia orzecznicza NIEJEDNOLITA — US może zakwestionować!"] if { risk == "MEDIUM" } else = [sprintf("⚖️ LINIA ORZECZNICZA: %s", [concat(" + ", rulings)]), "✅ Pozytywne orzecznictwo NSA wspiera uznanie tego wydatku za KUP."] if { count(rulings) > 0 } else = ["ℹ️ Brak istotnych wyroków NSA dla tego typu wydatku. Stosuj ogólne zasady KUP (Art. 22 PIT)."]

# ═══════════════════════════════════════════════════════════════════════════════
# S3-310: KIS INTERPRETATION PRECEDENT — Interpretacje KIS jako precedensy
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.judicial.kis_interpretation_precedent",
    "package": "jdg.judicial_rulings",
    "priority": 310,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": kus_qual, "kus_percent": kus_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "judicial_kis_recommendation": kis_recommendation,
    "judicial_individual_interpretation_needed": needs_interpretation,
    "judicial_kis_docket_cost": 40,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": kis_routing,
    "_routing_reason": kis_reason,
    "_legal_basis": "Art. 14b-14s Ordynacji podatkowej (interpretacje indywidualne)",
    "_warnings": [sprintf("📋 INTERPRETACJE KIS — %s. %s", [kis_recommendation, interpretation_advice])]
} if {
    input.judicial_rulings_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "expense_type", "GENERAL")
    amount_net := object.get(input.invoice, "amount_net", 0)

    needs_interpretation := kis_needs_value(expense_type, amount_net)
    kis_recommendation := kis_recommendation_value(needs_interpretation, expense_type)
    kus_qual := kis_qual_value(needs_interpretation)
    kus_pct := kis_pct_value(needs_interpretation)
    kis_routing := kis_routing_value(needs_interpretation)
    kis_reason := kis_reason_value(needs_interpretation, amount_net, expense_type)
    interpretation_advice := kis_advice_value(needs_interpretation)
}

# ═══════════════════════════════════════════════════════════════════════════════
# S3-320: WIS / WIA BINDING INFORMATION — Wiążące Informacje Stawkowo/Akcyzowe
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.judicial.wis_wia_binding_information",
    "package": "jdg.judicial_rulings",
    "priority": 320,
    "vat_rate": product_vat, "rounding_level": "", "gtu_code": gtu_code,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "judicial_wis_classification": pkwiu_classification,
    "judicial_wis_binding_rate": binding_vat_rate,
    "judicial_wis_ambiguity_warning": ambiguity_warning,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": wis_routing,
    "_routing_reason": wis_reason,
    "_legal_basis": "Art. 42a-42g VAT (WIS); Art. 7d KKS; Rozporządzenie MF ws. WIS",
    "_warnings": [sprintf("📦 WIS — Klasyfikacja PKWiU: %s. %s. WIS chroni przed zmianą stawki VAT przez US (Art. 42c VAT).", [pkwiu_classification, ambiguity_warning])]
} if {
    input.judicial_wis_check == true
    product_type := object.get(input.invoice, "product_type", "GENERAL")
    product_description := object.get(input.invoice, "description", "")
    amount_net := object.get(input.invoice, "amount_net", 0)

    # WIS — produkty o niejednoznacznej klasyfikacji VAT
    ambiguous_products := {
        "EBOOK": {"pkwiu": "58.11.1", "default_vat": "0.05", "ambiguity": "E-book może być 5%% (książka) lub 23%% (oprogramowanie). WIS rozstrzyga."},
        "DIETARY_SUPPLEMENT": {"pkwiu": "10.89.19.0", "default_vat": "0.23", "ambiguity": "Suplement diety może być 8%% (żywność specjalna) lub 23%% (pozostałe)."},
        "SMARTWATCH": {"pkwiu": "26.52.1", "default_vat": "0.23", "ambiguity": "Smartwatch jako urządzenie medyczne (8%%) lub elektronika (23%%)."},
        "SAAS_CLOUD": {"pkwiu": "63.11.19.0", "default_vat": "0.23", "ambiguity": "SaaS jako usługa elektroniczna (23%%) vs przetwarzanie danych (różne stawki)."},
        "ORGANIC_FOOD": {"pkwiu": "10.89.19.0", "default_vat": "0.05", "ambiguity": "Żywność ekologiczna — 5%% (podstawowa) czy 23%% (lukusowa)? WIS rozstrzyga."}
    }

    product_data := object.get(ambiguous_products, product_type, {})
    pkwiu_classification := object.get(product_data, "pkwiu", "N/A")
    product_vat := object.get(product_data, "default_vat", "0.23")
    ambiguity_warning := object.get(product_data, "ambiguity", "")

    needs_wis := product_data != {}
    binding_vat_rate := wis_binding_rate_value(needs_wis)
    gtu_code := ""
    wis_routing := wis_routing_value(needs_wis, amount_net)
    wis_reason := wis_reason_value(needs_wis, amount_net, product_type)
}

# ═══════════════════════════════════════════════════════════════════════════════
# S3-330: MF GENERAL INTERPRETATIONS — Interpretacje ogólne Ministra Finansów
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.judicial.mf_general_interpretation",
    "package": "jdg.judicial_rulings",
    "priority": 330,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": mf_kus_qual, "kus_percent": mf_kus_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "judicial_mf_ruling_date": "2019-11-25",
    "judicial_mf_ruling_ref": "Interpretacja ogólna MF z 25.11.2019, DD6.8203.7.2019",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 14a § 1 OrdPU (interpretacje ogólne MF); Art. 23 ust. 1 pkt 23 PIT",
    "_warnings": [
        "📜 INTERPRETACJA OGÓLNA MF (25.11.2019) — Definicja reprezentacji: 'działania mające na celu kreowanie pozytywnego wizerunku firmy'.",
        "✅ Wydatki na jedzenie dla kontrahentów podczas spotkań biznesowych = KUP (nie są reprezentacją!).",
        "✅ Wydatki na wystrój biura, kwiaty, dekoracje = KUP (nie są reprezentacją — to koszty funkcjonowania!).",
        "⚠️ Wydatki na luksusowe restauracje, alkohol premium, imprezy rozrywkowe = REPREZENTACJA → NKUP.",
        "📋 ZAWSZE dokumentuj CEL BIZNESOWY spotkania (agenda, lista uczestników)."
    ]
} if {
    input.judicial_mf_interpretation_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "expense_type", "GENERAL")
    is_business_meal := is_one_of(expense_type, "RESTAURANT", "MEETING")
    is_luxury := object.get(input.invoice, "is_luxury_venue", false)
    has_business_purpose_doc := object.get(input.invoice, "has_business_purpose_documentation", false)

    mf_kus_qual := mf_qual_value(is_business_meal, has_business_purpose_doc, is_luxury)
    mf_kus_pct := mf_pct_value(mf_kus_qual)
}

# ═══════════════════════════════════════════════════════════════════════════════
# S3-340: TSUE PRELIMINARY RULINGS — Wyroki TSUE wpływające na polski VAT/PIT
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.judicial.tsue_preliminary_ruling",
    "package": "jdg.judicial_rulings",
    "priority": 340,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "judicial_tsue_impact": tsue_impact,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": tsue_routing,
    "_routing_reason": tsue_reason,
    "_legal_basis": "Art. 267 TFUE; Dyrektywa VAT 2006/112/WE; Orzecznictwo TSUE",
    "_warnings": build_tsue_warnings(tsue_impact)
} if {
    input.judicial_tsue_check == true
    is_cross_border := object.get(input.invoice, "is_cross_border", false)
    has_reverse_charge := object.get(input.invoice, "vat_reverse_charge", false)
    is_platform_economy := object.get(input.jdg_entrepreneur, "operates_on_platforms", false)
    uses_oss := object.get(input.jdg_entrepreneur, "uses_oss_ioss", false)

    platform_note := "Platforma (Allegro, Amazon, eBay) może być uznana za podatnika VAT od Twojej sprzedaży."
    oss_note := "OSS upraszcza rozliczenie VAT w UE — jeden formularz dla wszystkich krajów."
    tsue_impact := tsue_impact_value(is_platform_economy, is_cross_border, has_reverse_charge, uses_oss, platform_note, oss_note)
    tsue_routing := tsue_routing_value(tsue_impact)
    tsue_reason := tsue_reason_value(tsue_impact)
}

build_tsue_warnings(impact) = [sprintf("TSUE: %s", [impact])] if { impact != "BRAK" }
build_tsue_warnings(impact) = ["ℹ️ Brak istotnych wyroków TSUE dla tej transakcji."] if { impact == "BRAK" }
