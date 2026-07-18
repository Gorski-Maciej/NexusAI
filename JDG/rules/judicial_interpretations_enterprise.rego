# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE JUDICIAL RULINGS & INTERPRETATIONS ENGINE (S3)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
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
} {
    input.judicial_rulings_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "expense_type", "GENERAL")
    expense_description := object.get(input.invoice, "description", "")
    amount_net := object.get(input.invoice, "amount_net", 0)
    uses_company_car := object.get(input.jdg_entrepreneur, "vehicle_used_for_business", false)
    has_mileage_log := object.get(input.jdg_entrepreneur, "vehicle_mileage_log_maintained", false)

    applicable_rulings := []
    risk_level := "LOW"

    # NSA II FSK 2345/17: Reprezentacja vs Reklama — KLUCZOWY wyrok
    is_event := expense_type == "EVENT" or expense_type == "ENTERTAINMENT"
    is_advertising := object.get(input.invoice, "has_advertising_purpose", false)
    is_representation_risk := is_event and not is_advertising
    applicable_rulings := array.concat(applicable_rulings, ["NSA_II_FSK_2345_17_REPRESENTATION_VS_ADVERTISING"]) { is_representation_risk }
    kus_qual := "depends_on_ruling" { is_representation_risk; not is_advertising }

    # NSA II FSK 1319/18: Auto firmowe — pełne odliczenie przy ewidencji
    uses_company_car_and_log := uses_company_car and has_mileage_log
    applicable_rulings := array.concat(applicable_rulings, ["NSA_II_FSK_1319_18_CAR_FULL_DEDUCTION"]) { uses_company_car_and_log }
    kus_qual := "deductible_full" { uses_company_car_and_log }

    # NSA II FSK 1023/19: Koszty szkoleń — KUP nawet bez bezpośredniego związku
    is_training := expense_type == "TRAINING" or expense_type == "EDUCATION"
    applicable_rulings := array.concat(applicable_rulings, ["NSA_II_FSK_1023_19_TRAINING_KUP"]) { is_training }
    kus_qual := "deductible_full" { is_training }

    # NSA II FSK 670/20: Wydatki na integrację pracowników — KUP
    is_integration := contains(expense_description, "integracja") or contains(expense_description, "team building")
    applicable_rulings := array.concat(applicable_rulings, ["NSA_II_FSK_670_20_INTEGRATION_KUP"]) { is_integration }

    # NSA II FSK 1434/21: Strata na sprzedaży środka trwałego — KUP
    is_asset_loss := expense_type == "ASSET_LOSS" or contains(expense_description, "strata sprzedaż")
    applicable_rulings := array.concat(applicable_rulings, ["NSA_II_FSK_1434_21_ASSET_LOSS_KUP"]) { is_asset_loss }

    # NSA II FSK 2156/22: Wydatki na ubrania firmowe — KUP (musi być logo)
    is_clothing := expense_type == "CLOTHING" and contains(expense_description, "logo")
    applicable_rulings := array.concat(applicable_rulings, ["NSA_II_FSK_2156_22_CLOTHING_KUP"]) { is_clothing }

    # NSA II FSK 388/23: Wydatki na catering dla pracowników — KUP
    is_catering := expense_type == "CATERING" or (contains(expense_description, "catering") or contains(expense_description, "posiłki"))
    applicable_rulings := array.concat(applicable_rulings, ["NSA_II_FSK_388_23_CATERING_KUP"]) { is_catering }

    kus_qual := "deductible_full" { count(applicable_rulings) > 0 }
    kus_pct := 100 { kus_qual == "deductible_full" }
    kus_pct := 75 { not has_mileage_log; uses_company_car }
    kus_pct := 0 { kus_qual == "non_deductible" }

    # Risk assessment based on ruling lines
    favorable_count := count(applicable_rulings)
    unfavorable_count := 0
    unfavorable_count := 1 { is_representation_risk; not is_advertising }

    risk_level := "LOW" { favorable_count >= 2; unfavorable_count <= 0 }
    risk_level := "MEDIUM" { favorable_count >= 1; unfavorable_count <= 1 }
    risk_level := "HIGH" { unfavorable_count > 1 }
    risk_level := "MEDIUM" { is_representation_risk; not is_advertising }

    judicial_routing := "" { risk_level == "LOW" }
    judicial_routing := "TRIAGE_QUEUE" { risk_level == "MEDIUM" }
    judicial_routing := "BLOCK_AND_ALERT" { risk_level == "HIGH" }
    judicial_reason := "" { risk_level == "LOW" }
    judicial_reason := "Wydatek w 'szarej strefie' — sprawdź linię orzeczniczą" { risk_level == "MEDIUM" }
    judicial_reason := sprintf("Niekorzystna linia orzecznicza dla: %s", [concat(", ", applicable_rulings)]) { risk_level == "HIGH" }
}

build_judicial_warnings(rulings, risk) = warnings {
    risk == "LOW"
    count(rulings) > 0
    ruling_list := concat(" + ", rulings)
    warnings := [
        sprintf("⚖️ LINIA ORZECZNICZA: %s", [ruling_list]),
        "✅ Pozytywne orzecznictwo NSA wspiera uznanie tego wydatku za KUP.",
        "📋 Zachowaj dokumentację (faktura + opis celu biznesowego) na wypadek kontroli."
    ]
}

build_judicial_warnings(rulings, risk) = warnings {
    risk == "MEDIUM"
    warnings := [
        sprintf("⚠️ SZARA STREFA ORZECZNICZA — %s", [concat(", ", rulings)]),
        "⚖️ Linia orzecznicza NIEJEDNOLITA — US może zakwestionować!",
        "🛡️ ZABEZPIECZENIE: Dokumentuj CEL BIZNESOWY wydatku. Zbierz dowody (zdjęcia, lista gości, agenda).",
        "💡 Rozważ uzyskanie INTERPRETACJI INDYWIDUALNEJ KIS (koszt 40 PLN, chroni przed negatywną decyzją US!)."
    ]
}

build_judicial_warnings(rulings, risk) = warnings {
    risk == "HIGH"
    warnings := [
        sprintf("🔴 NIEKORZYSTNA LINIA ORZECZNICZA: %s", [concat(", ", rulings)]),
        "🚫 Wyroki NSA wskazują, że ten wydatek NIE stanowi KUP!",
        "⚠️ Kontrola skarbowa prawdopodobnie zakwestionuje ten wydatek.",
        "💡 Rozważ alternatywną klasyfikację wydatku lub uzyskanie interpretacji indywidualnej.",
        "📋 Procedura: złóż wniosek o interpretację indywidualną (KIS) — chroni przed sankcjami KKS."
    ]
}

build_judicial_warnings(rulings, risk) = ["ℹ️ Brak istotnych wyroków NSA dla tego typu wydatku. Stosuj ogólne zasady KUP (Art. 22 PIT)."] {
    count(rulings) <= 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# S3-310: KIS INTERPRETATION PRECEDENT — Interpretacje KIS jako precedensy
# ═══════════════════════════════════════════════════════════════════════════════

else := {
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
} {
    input.judicial_rulings_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "expense_type", "GENERAL")
    amount_net := object.get(input.invoice, "amount_net", 0)

    # Scenariusze wymagające interpretacji indywidualnej
    needs_interpretation := true {
        expense_type == "BUSINESS_TRANSFORMATION"  # Przekształcenie działalności
    }

    needs_interpretation := true {
        expense_type == "INTANGIBLE_ASSET_TRANSFER"  # Transfer wartości niematerialnych
        amount_net > 50000
    }

    needs_interpretation := true {
        expense_type == "CROSS_BORDER_SERVICES"  # Usługi transgraniczne
        amount_net > 100000
    }

    needs_interpretation := true {
        expense_type == "IP_TRANSFER_JDG_TO_COMPANY"  # Transfer IP z JDG do spółki
    }

    needs_interpretation := false { true }

    # KIS interpretation logic
    has_all_conditions := true { false }  # domyślnie brak ryzyka

    needs_interpretation := true {
        expense_type == "HOMEOFFICE_EQUIPMENT"
        amount_net > 10000
    }

    kis_recommendation := "ZALECANA INTERPRETACJA INDYWIDUALNA — wydatek > 10 000 PLN w niejednoznacznej kategorii. Interpretacja chroni przed negatywną decyzją US (Art. 14k-14m OrdPU)." { needs_interpretation }
    kis_recommendation := sprintf("NIEPOTRZEBNA interpretacja dla %s. Istnieje ugruntowana linia orzecznicza i interpretacyjna.", [expense_type]) { not needs_interpretation }

    kus_qual := "deductible_requires_interpretation" { needs_interpretation }
    kus_qual := "deductible_full" { not needs_interpretation }
    kus_pct := 100 { not needs_interpretation }
    kus_pct := 0 { needs_interpretation }  # Ostrożnie: bez interpretacji brak KUP

    kis_routing := "TRIAGE_QUEUE" { needs_interpretation }
    kis_routing := "" { not needs_interpretation }
    kis_reason := sprintf("Wydatek %.2f PLN w kategorii %s — zalecana interpretacja indywidualna KIS", [amount_net, expense_type]) { needs_interpretation }
    kis_reason := "" { not needs_interpretation }

    interpretation_advice := sprintf("Złóż wniosek o interpretację indywidualną (KIS, 40 PLN). Czas oczekiwania: ~3 miesiące. Interpretacja WIĄŻE US w Twojej sprawie (Art. 14k § 1 OrdPU). Chroni przed sankcjami KKS (Art. 10 § 4 KKS).") { needs_interpretation }
    interpretation_advice := "Nie wymaga interpretacji." { not needs_interpretation }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S3-320: WIS / WIA BINDING INFORMATION — Wiążące Informacje Stawkowo/Akcyzowe
# ═══════════════════════════════════════════════════════════════════════════════

else := {
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
} {
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
    binding_vat_rate := "" { needs_wis }
    binding_vat_rate := "0.00" { not needs_wis }
    gtu_code := "" { not needs_wis }

    wis_routing := "TRIAGE_QUEUE" { needs_wis; amount_net > 10000 }
    wis_routing := "" { true }
    wis_reason := sprintf("Produkt %s — niejednoznaczna stawka VAT. WIS zalecana przy kwocie > 10k PLN.", [product_type]) { needs_wis; amount_net > 10000 }
    wis_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S3-330: MF GENERAL INTERPRETATIONS — Interpretacje ogólne Ministra Finansów
# ═══════════════════════════════════════════════════════════════════════════════

else := {
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
} {
    input.judicial_mf_interpretation_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expense_type := object.get(input.invoice, "expense_type", "GENERAL")
    is_business_meal := expense_type == "RESTAURANT" or expense_type == "MEETING"
    is_luxury := object.get(input.invoice, "is_luxury_venue", false)
    has_business_purpose_doc := object.get(input.invoice, "has_business_purpose_documentation", false)

    mf_kus_qual := "depends_on_context" { is_business_meal }
    mf_kus_qual := "deductible_full" { is_business_meal; has_business_purpose_doc; not is_luxury }
    mf_kus_qual := "non_deductible" { is_business_meal; is_luxury; not has_business_purpose_doc }
    mf_kus_pct := 100 { mf_kus_qual == "deductible_full" }
    mf_kus_pct := 0 { mf_kus_qual == "non_deductible" }
    mf_kus_pct := 50 { mf_kus_qual == "depends_on_context" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S3-340: TSUE PRELIMINARY RULINGS — Wyroki TSUE wpływające na polski VAT/PIT
# ═══════════════════════════════════════════════════════════════════════════════

else := {
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
    "_warnings": build_tsue_warnings()
} {
    input.judicial_tsue_check == true
    is_cross_border := object.get(input.invoice, "is_cross_border", false)
    has_reverse_charge := object.get(input.invoice, "vat_reverse_charge", false)
    is_platform_economy := object.get(input.jdg_entrepreneur, "operates_on_platforms", false)
    uses_oss := object.get(input.jdg_entrepreneur, "uses_oss_ioss", false)

    tsue_impact := "BRAK"
    tsue_routing := ""
    tsue_reason := ""

    tsue_impact := sprintf("TSUE C-695/20 (VAT platformy cyfrowe): Jako sprzedawca na platformie, możesz być zobowiązany do VAT w kraju kupującego. %s", [platform_note]) {
        is_platform_economy
        is_cross_border
    }

    tsue_impact := sprintf("TSUE C-276/22 (Reverse charge): Reverse charge obowiązuje nawet gdy kontrahent nie wystawił faktury z adnotacją. Odpowiadasz solidarnie za VAT.", []) { has_reverse_charge }

    tsue_impact := sprintf("TSUE C-298/22 (OSS procedura): %s", [oss_note]) { uses_oss }

    tsue_routing := "TRIAGE_QUEUE" { tsue_impact != "BRAK" }
    tsue_reason := "Wyrok TSUE ma zastosowanie do tej transakcji — zweryfikuj zgodność." { tsue_impact != "BRAK" }

    platform_note := "Platforma (Allegro, Amazon, eBay) może być uznana za podatnika VAT od Twojej sprzedaży."
    oss_note := "OSS upraszcza rozliczenie VAT w UE — jeden formularz dla wszystkich krajów."
}

build_tsue_warnings() = tsue_impact_str { tsue_impact != "BRAK" }
build_tsue_warnings() = ["ℹ️ Brak istotnych wyroków TSUE dla tej transakcji."] { tsue_impact == "BRAK" }

tsue_impact := ""  # Default
