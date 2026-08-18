# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 16

package jdg.hyper.wis

default decide := {"matched":false,"rule_id":"jdg.hyper.wis.no_match","package":"jdg.hyper.wis","priority":99999}

# jdg.hyper.wis.solidarity.levy.aggregate.alert_900k — Agregacja
decide :=   {"matched":true,"rule_id":"jdg.hyper.wis.solidarity.levy.aggregate.alert_900k","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Alert: dochód przekroczył 900k PLN — zbliżasz się do progu 1M dla daniny solidarnościowej 4%"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.cn_code_ambiguous — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.cn_code_ambiguous","_legal_basis":"Art. 42b ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Kod CN niejednoznaczny — zalecenie uzyskania WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.composite_product — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.composite_product","_legal_basis":"Art. 42b ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Produkt złożony — niejednoznaczna klasyfikacja → WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.new_product_launch — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.new_product_launch","_legal_basis":"Art. 42b ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Nowy produkt na rynku bez utrwalonej klasyfikacji → WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.import_first_time — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.import_first_time","_legal_basis":"Art. 42b ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Pierwszy import towaru spoza UE → zalecenie WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.contradictory_interpretations — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.contradictory_interpretations","_legal_basis":"Art. 42b ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Sprzeczne interpretacje KIS → zalecenie WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.food_supplement_borderline — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.food_supplement_borderline","_legal_basis":"Art. 42b ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Suplementy diety na granicy żywność/farmaceutyk → WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.software_vs_service — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.software_vs_service","_legal_basis":"Art. 42b ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Oprogramowanie vs usługa — niejednoznaczność → WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.annual_turnover_50k — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.annual_turnover_50k","_legal_basis":"Art. 42b ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Roczny obrót towarem >50k PLN → próg istotności dla WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.application.cost.40pln — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.application.cost.40pln","_legal_basis":"Art. 42g ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Opłata za wniosek WIS = 40 PLN za każdy towar/usługę"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.application.form.electronic_only — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.application.form.electronic_only","_legal_basis":"Art. 42g ust. 2 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Wniosek WIS-W tylko elektronicznie przez e-US"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.application.required_fields — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.application.required_fields","_legal_basis":"Art. 42g ust. 1-3 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Opis towaru, kod CN, proponowana stawka, uzasadnienie"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.application.sample_may_be_required — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.application.sample_may_be_required","_legal_basis":"Art. 42g ust. 4 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Dyrektor KIS może zażądać próbki towaru"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.validity.5_years_from_issue — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.validity.5_years_from_issue","_legal_basis":"Art. 42h ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["WIS ważna 5 lat od daty wydania"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.validity.early_expiry.regulation_change — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.validity.early_expiry.regulation_change","_legal_basis":"Art. 42h ust. 2 pkt 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Zmiana przepisów → WIS traci moc z dniem zmiany"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.validity.early_expiry.cjeu_judgment — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.validity.early_expiry.cjeu_judgment","_legal_basis":"Art. 42h ust. 2 pkt 2 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Wyrok TSUE zmieniający klasyfikację → WIS traci moc"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# ══ L-WIS-1 Fix: WIA + WIT Rules (P23 P1) — R1086-R1087 ══
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wia.binding_info_akcyzowa_170_210pln","_legal_basis":"Art. 7d ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)","_warnings":["WIA (Wiążąca Informacja Akcyzowa) — opłata: 170 PLN (podstawowa) / 210 PLN (pełna). Skutek wiążący 5 lat. Wniosek do Dyrektora KIS"]} {
    object.get(input.jdg_entrepreneur, "wia_requested", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wit.binding_info_taryfowa_167pln","_legal_basis":"Art. 33 rozporządzenia 952/2013 (UKC)","_warnings":["WIT (Wiążąca Informacja Taryfowa) — opłata: 167 PLN. Skutek wiążący 3 lata. Wniosek do Izby Administracji Skarbowej"]} {
    object.get(input.jdg_entrepreneur, "wit_requested", false) == true
}
