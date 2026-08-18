# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.mdr (Doc 44: P1800-P1809)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 10
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.mdr
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.mdr.no_match","package":"jdg.mdr","priority":99999}

# jdg.mdr.reportable_scheme_detection — Wykrywanie schematów podatkowych MDR (DAC6)
decide :=   {"matched":true,"rule_id":"jdg.mdr.reportable_scheme_detection","package":"jdg.mdr","priority":1800,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Wykrywanie schematów podatkowych MDR (DAC6)","_legal_basis":"Art. 86a-86o Ordynacji podatkowej","_warnings":["Transakcja nosi cechy schematu MDR — obowiązek zgłoszenia MDR-3 w 30 dni! Sankcja do 5M PLN!"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.mdr.promoter_vs_user — P1801: Rola MDR: promotor vs korzystający
else :=   {"matched":true,"rule_id":"jdg.mdr.promoter_vs_user","package":"jdg.mdr","priority":1801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Rola MDR: promotor vs korzystający","_legal_basis":"Art. 86a § 1 Ordynacji podatkowej","_warnings":["Ustalono rolę MDR — sprawdź obowiązki raportowania"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.document, "mdr_role_determined", false) == false
}

# jdg.mdr.deadline_tracking — P1802: Śledzenie terminów MDR i kary za brak zgłoszenia
else :=   {"matched":true,"rule_id":"jdg.mdr.deadline_tracking","package":"jdg.mdr","priority":1802,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Śledzenie terminów MDR i kary za brak zgłoszenia","_legal_basis":"Art. 86o Ordynacji podatkowej","_warnings":["MDR-3 niezłożony w terminie 30 dni! Kara administracyjna do 5M PLN + KKS!"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "deadline_tracked", false) == false
}

# jdg.mdr.hallmark_main_benefit_test — P1803: Test głównej korzyści (MBT) dla hallmarks A/B
else :=   {"matched":true,"rule_id":"jdg.mdr.hallmark_main_benefit_test","package":"jdg.mdr","priority":1803,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Test głównej korzyści (MBT) — hallmarks A/B — Art. 86a § 2 OP","_legal_basis":"Art. 86a § 2 Ordynacji podatkowej","_warnings":["Test MBT — sprawdź czy główną korzyścią transakcji jest korzyść podatkowa"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "hallmark_category", "") != ""
    object.get(input.mdr, "mbt_completed", false) == false
}

# jdg.mdr.hallmark_category_c — P1804: Hallmarks kat. C — specyficzne transgraniczne
else :=   {"matched":true,"rule_id":"jdg.mdr.hallmark_category_c","package":"jdg.mdr","priority":1804,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Hallmarks kat. C — nabycie spółki ze stratą, konwersja, okrężne, odliczenia transgraniczne","_legal_basis":"Art. 86d Ordynacji podatkowej","_warnings":["Hallmark C — transgraniczne schematy specyficzne — wymagane zgłoszenie MDR"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "hallmark_c_checked", false) == false
}

# jdg.mdr.hallmark_category_d_tp — P1805: Hallmarks kat. D — TP-specific
else :=   {"matched":true,"rule_id":"jdg.mdr.hallmark_category_d_tp","package":"jdg.mdr","priority":1805,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Hallmarks kat. D — transfer wartości niematerialnych, funkcji, ryzyk","_legal_basis":"Art. 86e Ordynacji podatkowej","_warnings":["Hallmark D — TP-specific — transfer wartości niematerialnych transgranicznie"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "hallmark_d_checked", false) == false
}

# jdg.mdr.hallmark_category_e_exchange — P1806: Hallmarks kat. E — automatyczna wymiana informacji
else :=   {"matched":true,"rule_id":"jdg.mdr.hallmark_category_e_exchange","package":"jdg.mdr","priority":1806,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Hallmarks kat. E — obchodzenie CRS/DAC, ukrywanie beneficial owner","_legal_basis":"Art. 86f Ordynacji podatkowej","_warnings":["Hallmark E — automatyczna wymiana informacji — ryzyko obchodzenia CRS"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "hallmark_e_checked", false) == false
}

# jdg.mdr.quarterly_summary_mdr4 — P1807: Obowiązek MDR-4 — zestawienie kwartalne
else :=   {"matched":true,"rule_id":"jdg.mdr.quarterly_summary_mdr4","package":"jdg.mdr","priority":1807,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"MDR-4 — obowiązek kwartalnego zestawienia zgłoszonych schematów","_legal_basis":"Art. 86k Ordynacji podatkowej","_warnings":["MDR-4 — złóż kwartalne zestawienie do końca miesiąca po kwartale"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "quarterly_report_filed", false) == false
}

# jdg.mdr.statute_of_limitations — P1808: Przedawnienie obowiązku MDR — retencja 6 lat
else :=   {"matched":true,"rule_id":"jdg.mdr.statute_of_limitations","package":"jdg.mdr","priority":1808,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedawnienie MDR — retencja danych 6 lat od zakończenia roku","_legal_basis":"Art. 86m Ordynacji podatkowej","_warnings":["Dane MDR przechowuj przez 6 lat od zakończenia roku, w którym schemat był dostępny"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "retention_checked", false) == false
}

# jdg.mdr.aggregate_risk_jdg — P1809: Agregacja ryzyka MDR dla JDG
else :=   {"matched":true,"rule_id":"jdg.mdr.aggregate_risk_jdg","package":"jdg.mdr","priority":1809,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Agregacja ryzyka MDR — profil, historia zgłoszeń, ekspozycja","_legal_basis":"Art. 86a-86o Ordynacji podatkowej","_warnings":["Profil ryzyka MDR — sprawdź historię zgłoszeń i ekspozycję na sankcje"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.mdr, "risk_aggregated", false) == false
}
