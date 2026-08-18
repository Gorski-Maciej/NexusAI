# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.wis hyper-granularity (Doc 45: R1071-R1105)
# Atom rules: WIS/WIA/WIT — eligibility, application, validity, monitoring, GTU mapping
# Rules: 35 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.wis.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.wis.hyper.no_match","package":"jdg.wis.hyper","priority":99999}

# ══ Eligibility (R1071-R1078) ══
decide := {"matched":true,"rule_id":"jdg.wis.hyper.eligibility_cn_ambiguous","package":"jdg.wis.hyper","priority":1071,"_routing":"WARNING","_routing_reason":"WIS: kod CN niejednoznaczny","_legal_basis":"Art. 42a VAT","_warnings":["Kod CN niejednoznaczny — 2+ możliwe stawki VAT → zalecenie WIS"]} {
    object.get(input.invoice, "cn_code_ambiguous", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.eligibility_composite_product","package":"jdg.wis.hyper","priority":1072,"_routing":"WARNING","_routing_reason":"WIS: produkt złożony","_legal_basis":"Art. 42a VAT","_warnings":["Produkt złożony (zestaw) → niejednoznaczna klasyfikacja → zalecenie WIS"]} {
    object.get(input.invoice, "composite_product", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.eligibility_new_product","package":"jdg.wis.hyper","priority":1073,"_routing":"WARNING","_routing_reason":"WIS: nowy produkt bez klasyfikacji","_legal_basis":"Art. 42a VAT","_warnings":["Nowy produkt na rynku bez utrwalonej klasyfikacji → zalecenie WIS"]} {
    object.get(input.invoice, "new_product_launch", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.eligibility_first_import","package":"jdg.wis.hyper","priority":1074,"_routing":"WARNING","_routing_reason":"WIS: pierwszy import spoza UE","_legal_basis":"Art. 42a VAT","_warnings":["Pierwszy import towaru spoza UE → zalecenie WIS"]} {
    object.get(input.invoice, "first_import_non_eu", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.eligibility_contradictory_interpretations","package":"jdg.wis.hyper","priority":1075,"_routing":"WARNING","_routing_reason":"WIS: sprzeczne interpretacje","_legal_basis":"Art. 42a VAT","_warnings":["Sprzeczne interpretacje KIS dla podobnych towarów → zalecenie WIS"]} {
    object.get(input.invoice, "contradictory_interpretations", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.eligibility_food_supplement","package":"jdg.wis.hyper","priority":1076,"_routing":"WARNING","_routing_reason":"WIS: suplementy na granicy","_legal_basis":"Art. 42a VAT","_warnings":["Suplementy diety na granicy żywność/farmaceutyk → zalecenie WIS"]} {
    object.get(input.invoice, "food_supplement_borderline", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.eligibility_software_vs_service","package":"jdg.wis.hyper","priority":1077,"_routing":"WARNING","_routing_reason":"WIS: oprogramowanie vs usługa","_legal_basis":"Art. 42a VAT","_warnings":["Oprogramowanie vs usługa — niejednoznaczność → zalecenie WIS"]} {
    object.get(input.invoice, "software_vs_service", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.eligibility_turnover_50k","package":"jdg.wis.hyper","priority":1078,"_routing":"","_routing_reason":"WIS: próg istotności 50k PLN","_legal_basis":"Art. 42a VAT","_warnings":["Roczny obrót towarem >50k PLN → próg istotności dla WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# ══ Application (R1079-R1082) ══
else := {"matched":true,"rule_id":"jdg.wis.hyper.application_cost_40pln","package":"jdg.wis.hyper","priority":1079,"_routing":"","_routing_reason":"WIS: opłata 40 PLN","_legal_basis":"Ustawa o VAT","_warnings":["Wniosek WIS-W — opłata 40 PLN za każdy towar/usługę"]} {
    object.get(input.invoice, "wis_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.application_electronic_only","package":"jdg.wis.hyper","priority":1080,"_routing":"","_routing_reason":"WIS: tylko elektronicznie","_legal_basis":"Art. 42b VAT","_warnings":["Wniosek WIS-W tylko elektronicznie przez e-US"]} {
    object.get(input.invoice, "wis_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.application_required_fields","package":"jdg.wis.hyper","priority":1081,"_routing":"","_routing_reason":"WIS: wymagane pola wniosku","_legal_basis":"Art. 42b VAT","_warnings":["Wniosek WIS: opis towaru, kod CN, proponowana stawka, uzasadnienie"]} {
    object.get(input.invoice, "wis_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.application_sample_required","package":"jdg.wis.hyper","priority":1082,"_routing":"","_routing_reason":"WIS: próbka towaru","_legal_basis":"Art. 42c VAT","_warnings":["Dyrektor KIS może zażądać próbki towaru"]} {
    object.get(input.invoice, "wis_sample_required", false) == true
}

# ══ Validity/Monitoring (R1083-R1088) ══
else := {"matched":true,"rule_id":"jdg.wis.hyper.validity_5_years","package":"jdg.wis.hyper","priority":1083,"_routing":"","_routing_reason":"WIS: ważność 5 lat","_legal_basis":"Art. 42h VAT","_warnings":["WIS ważna 5 lat od daty wydania"]} {
    object.get(input.invoice, "wis_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.early_expiry_regulation_change","package":"jdg.wis.hyper","priority":1084,"_routing":"WARNING","_routing_reason":"WIS: utrata mocy przy zmianie przepisów","_legal_basis":"Art. 42h VAT","_warnings":["Zmiana przepisów → WIS traci moc z dniem zmiany"]} {
    object.get(input.invoice, "vat_regulation_changed", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.early_expiry_cjeu_judgment","package":"jdg.wis.hyper","priority":1085,"_routing":"WARNING","_routing_reason":"WIS: wyrok TSUE","_legal_basis":"Art. 42h VAT","_warnings":["Wyrok TSUE zmieniający klasyfikację → WIS traci moc"]} {
    object.get(input.invoice, "cjeu_judgment_impact", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.expiry_alert_6months","package":"jdg.wis.hyper","priority":1086,"_routing":"WARNING","_routing_reason":"WIS: 6 mies. do wygaśnięcia","_legal_basis":"Art. 42h VAT","_warnings":["WIS wygasa za 6 miesięcy — rozważ odnowienie"]} {
    object.get(input.invoice, "wis_expiry_months", 99) <= 6
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.expiry_alert_3months","package":"jdg.wis.hyper","priority":1087,"_routing":"WARNING","_routing_reason":"WIS: 3 mies. do wygaśnięcia","_legal_basis":"Art. 42h VAT","_warnings":["WIS wygasa za 3 miesiące — złóż wniosek o nową!"]} {
    object.get(input.invoice, "wis_expiry_months", 99) <= 3
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.expiry_alert_1month","package":"jdg.wis.hyper","priority":1088,"_routing":"TRIAGE_QUEUE","_routing_reason":"WIS: 1 mies. do wygaśnięcia","_legal_basis":"Art. 42h VAT","_warnings":["WIS wygasa za miesiąc — NATYCHMIAST złóż wniosek!"]} {
    object.get(input.invoice, "wis_expiry_months", 99) <= 1
}

# ══ Binding effect / GTU / Sanctions (R1089-R1095) ══
else := {"matched":true,"rule_id":"jdg.wis.hyper.binding_dyrektor_kis","package":"jdg.wis.hyper","priority":1089,"_routing":"","_routing_reason":"WIS: wiąże Dyrektora KIS","_legal_basis":"Art. 42d VAT","_warnings":["WIS wiąże Dyrektora KIS i organy podatkowe"]} {
    object.get(input.invoice, "wis_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.binding_not_against_law_change","package":"jdg.wis.hyper","priority":1090,"_routing":"","_routing_reason":"WIS: nie chroni przed zmianą ustawy","_legal_basis":"Art. 42h VAT","_warnings":["WIS NIE chroni przed zmianą przepisów ustawowych"]} {
    object.get(input.invoice, "wis_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.binding_future_transactions","package":"jdg.wis.hyper","priority":1091,"_routing":"","_routing_reason":"WIS: obejmuje przyszłe transakcje","_legal_basis":"Art. 42d VAT","_warnings":["WIS obejmuje transakcje od dnia wydania"]} {
    object.get(input.invoice, "wis_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.gtu_mapping_obligation","package":"jdg.wis.hyper","priority":1092,"_routing":"WARNING","_routing_reason":"WIS→GTU: obowiązek mapowania","_legal_basis":"Art. 42a VAT, Rozp. JPK_V7","_warnings":["WIS determinuje kod GTU w JPK_V7 — zapewnij spójność"]} {
    object.get(input.invoice, "wis_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.sanction_incorrect_rate","package":"jdg.wis.hyper","priority":1093,"_routing":"BLOCK_AND_ALERT","_routing_reason":"WIS: ryzyko KKS bez WIS","_legal_basis":"Art. 64 KKS","_warnings":["Bez WIS przy niejednoznacznym CN → ryzyko KKS Art. 64!"]} {
    object.get(input.invoice, "wis_required", false) == true
    object.get(input.invoice, "wis_obtained", false) == false
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.audit_protection","package":"jdg.wis.hyper","priority":1094,"_routing":"","_routing_reason":"WIS: ochrona przed zakwestionowaniem","_legal_basis":"Art. 42d VAT","_warnings":["Posiadanie WIS = ochrona przed zakwestionowaniem stawki"]} {
    object.get(input.invoice, "wis_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.wis_vs_interpretation_priority","package":"jdg.wis.hyper","priority":1095,"_routing":"","_routing_reason":"WIS > interpretacja indywidualna","_legal_basis":"Art. 42b VAT","_warnings":["WIS ma pierwszeństwo przed interpretacją indywidualną w zakresie CN"]} {
    object.get(input.invoice, "wis_obtained", false) == true
}

# ══ WIT (R1096-R1099) ══
else := {"matched":true,"rule_id":"jdg.wis.hyper.wit_import_non_eu","package":"jdg.wis.hyper","priority":1096,"_routing":"WARNING","_routing_reason":"WIT: import spoza UE","_legal_basis":"Art. 33 UKC","_warnings":["Import spoza UE → zalecenie WIT dla ceł"]} {
    object.get(input.invoice, "import_non_eu_customs", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.wit_validity_3years","package":"jdg.wis.hyper","priority":1097,"_routing":"","_routing_reason":"WIT: ważność 3 lata","_legal_basis":"Art. 33 UKC","_warnings":["WIT ważna 3 lata (krócej niż WIS)"]} {
    object.get(input.invoice, "wit_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.wit_cost_free","package":"jdg.wis.hyper","priority":1098,"_routing":"","_routing_reason":"WIT: bezpłatna","_legal_basis":"UKC","_warnings":["WIT jest bezpłatna (w przeciwieństwie do WIS)"]} {
    object.get(input.invoice, "wit_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.wit_binding_customs","package":"jdg.wis.hyper","priority":1099,"_routing":"","_routing_reason":"WIT: wiąże organy celne UE","_legal_basis":"UKC","_warnings":["WIT wiąże organy celne wszystkich krajów UE"]} {
    object.get(input.invoice, "wit_obtained", false) == true
}

# ══ WIA (R1100-R1102) ══
else := {"matched":true,"rule_id":"jdg.wis.hyper.wia_excise_goods","package":"jdg.wis.hyper","priority":1100,"_routing":"WARNING","_routing_reason":"WIA: wyroby akcyzowe","_legal_basis":"Ustawa o podatku akcyzowym","_warnings":["Handel alkoholem/tytoniem/energią → zalecenie WIA"]} {
    object.get(input.invoice, "excise_goods", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.wia_validity_3years","package":"jdg.wis.hyper","priority":1101,"_routing":"","_routing_reason":"WIA: ważność 3 lata","_legal_basis":"Ustawa o podatku akcyzowym","_warnings":["WIA ważna 3 lata"]} {
    object.get(input.invoice, "wia_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.wia_cost_250pln","package":"jdg.wis.hyper","priority":1102,"_routing":"","_routing_reason":"WIA: opłata 250 PLN","_legal_basis":"Ustawa o podatku akcyzowym","_warnings":["Opłata za WIA: 250 PLN"]} {
    object.get(input.invoice, "wia_requested", false) == true
}

# ══ Strategy/Portfolio (R1103-R1105) ══
else := {"matched":true,"rule_id":"jdg.wis.hyper.cost_benefit_analysis","package":"jdg.wis.hyper","priority":1103,"_routing":"","_routing_reason":"WIS: analiza opłacalności 40 PLN vs ryzyko","_legal_basis":"Art. 42a-42h VAT","_warnings":["Kalkulacja: koszt WIS (40 PLN) vs ryzyko błędnej stawki (KKS + zaległość)"]} {
    object.get(input.invoice, "wis_required", false) == true
    object.get(input.invoice, "wis_obtained", false) == false
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.renewal_strategy","package":"jdg.wis.hyper","priority":1104,"_routing":"","_routing_reason":"WIS/WIT/WIA: strategia odnowienia","_legal_basis":"Art. 42h VAT, UKC","_warnings":["Automatyczna rekomendacja odnowienia przed wygaśnięciem"]} {
    object.get(input.invoice, "wis_expiry_months", 99) <= 12
}
else := {"matched":true,"rule_id":"jdg.wis.hyper.portfolio_management","package":"jdg.wis.hyper","priority":1105,"_routing":"","_routing_reason":"Zarządzanie portfelem WIS/WIT/WIA","_legal_basis":"Art. 42a-42h VAT","_warnings":["Zarządzaj wszystkimi WIS/WIT/WIA w jednym miejscu"]} {
    object.get(input.document, "has_binding_info", false) == true
}
