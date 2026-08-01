# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.residency hyper-granularity (Doc 45: R1476-R1517)
# Atom rules: residency tests, DTT/UPO, CFR, foreign tax credit, exit tax,
#   dual residency, PE, CFC, digital nomad
# Rules: 42 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.residency.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.residency.hyper.no_match","package":"jdg.residency.hyper","priority":99999}

# ══ R1476-R1480: Residency Tests ══
decide := {"matched":true,"rule_id":"jdg.residency.hyper.test_183_days","package":"jdg.residency.hyper","priority":1476,"_routing":"","_routing_reason":"Rezydencja: test 183 dni w PL","_legal_basis":"Art. 3 ust. 1a PIT","_warnings":["Test 183 dni — pobyt w PL >183 dni w roku = rezydent PL"]} {
    object.get(input.jdg_entrepreneur, "days_in_pl", 0) > 183
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.test_center_of_vital_interests","package":"jdg.residency.hyper","priority":1477,"_routing":"","_routing_reason":"Rezydencja: centrum interesów życiowych","_legal_basis":"Art. 3 ust. 1a PIT","_warnings":["Centrum interesów życiowych w PL — powiązania osobiste i ekonomiczne"]} {
    object.get(input.jdg_entrepreneur, "center_of_life_in_pl", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.test_economic_ties","package":"jdg.residency.hyper","priority":1478,"_routing":"","_routing_reason":"Rezydencja: ośrodek interesów życiowych","_legal_basis":"Art. 3 ust. 1a PIT","_warnings":["Ośrodek interesów życiowych — miejsce gdzie JDG zarządza biznesem i ma główne źródła dochodu"]} {
    object.get(input.jdg_entrepreneur, "economic_center_in_pl", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.test_family_ties","package":"jdg.residency.hyper","priority":1479,"_routing":"","_routing_reason":"Rezydencja: powiązania rodzinne","_legal_basis":"Art. 3 ust. 1a PIT","_warnings":["Powiązania rodzinne — małżonek/dzieci w PL wskazują na rezydencję PL"]} {
    object.get(input.jdg_entrepreneur, "family_in_pl", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.test_habitual_abode_tiebreaker","package":"jdg.residency.hyper","priority":1480,"_routing":"WARNING","_routing_reason":"Rezydencja: miejsce zwykłego pobytu — tie-breaker","_legal_basis":"OECD MTC Art. 4 ust. 2","_warnings":["Miejsce zwykłego pobytu decyduje gdy centrum interesów jest nierozstrzygalne"]} {
    object.get(input.jdg_entrepreneur, "dual_residency_conflict_active", false) == true
}

# ══ R1481-R1485: Double Tax Treaties / UPO ══
else := {"matched":true,"rule_id":"jdg.residency.hyper.dtt_exemption_with_progression","package":"jdg.residency.hyper","priority":1481,"_routing":"","_routing_reason":"UPO: metoda wyłączenia z progresją","_legal_basis":"Umowy bilateralne, Art. 27 ust. 8 PIT","_warnings":["Metoda wyłączenia — dochód zagraniczny zwolniony z PIT, ale wpływa na stawkę od dochodu PL"]} {
    object.get(input.jdg_entrepreneur, "dtt_method", "") == "EXEMPTION_WITH_PROGRESSION"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.dtt_credit_method","package":"jdg.residency.hyper","priority":1482,"_routing":"","_routing_reason":"UPO: metoda odliczenia proporcjonalnego","_legal_basis":"Umowy bilateralne, Art. 27 ust. 9 PIT","_warnings":["Metoda odliczenia — dochód zagraniczny opodatkowany w PL, podatek zagraniczny odliczany do limitu"]} {
    object.get(input.jdg_entrepreneur, "dtt_method", "") == "CREDIT_METHOD"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.dtt_tiebreaker_rules","package":"jdg.residency.hyper","priority":1483,"_routing":"TRIAGE_QUEUE","_routing_reason":"UPO: tie-breaker — stałe mieszkanie → interesy → pobyt → obywatelstwo","_legal_basis":"OECD MTC Art. 4 ust. 2","_warnings":["Konflikt rezydencji — zastosuj tie-breaker: 1) stałe mieszkanie 2) interesy 3) pobyt 4) obywatelstwo"]} {
    object.get(input.jdg_entrepreneur, "dual_residency_conflict_active", false) == true
    object.get(input.jdg_entrepreneur, "dtt_country", "") != ""
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.cfr_validity_12months","package":"jdg.residency.hyper","priority":1484,"_routing":"WARNING","_routing_reason":"CFR: certyfikat rezydencji — ważność 12 miesięcy","_legal_basis":"Art. 26 ust. 1 PIT","_warnings":["Certyfikat rezydencji kontrahenta zagranicznego — ważny 12 miesięcy od wydania"]} {
    object.get(input.vendor, "is_foreign", false) == true
    object.get(input.vendor, "cfr_age_months", 0) > 12
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.cfr_required_for_wht_exemption","package":"jdg.residency.hyper","priority":1485,"_routing":"WARNING","_routing_reason":"CFR: wymagany dla WHT i zwolnień","_legal_basis":"Art. 26 ust. 1 PIT","_warnings":["CFR wymagany do zastosowania preferencyjnego WHT lub zwolnienia z podatku u źródła"]} {
    object.get(input.vendor, "is_foreign", false) == true
    object.get(input.vendor, "cfr_obtained", false) == false
    object.get(input.invoice, "wht_applicable", false) == true
}

# ══ R1486-R1490: Foreign Tax Credit ══
else := {"matched":true,"rule_id":"jdg.residency.hyper.foreign_tax_credit_limit","package":"jdg.residency.hyper","priority":1486,"_routing":"","_routing_reason":"Ulga: limit odliczenia podatku zagranicznego","_legal_basis":"Art. 27 ust. 9 PIT","_warnings":["Maksymalne odliczenie = podatek PL przypadający proporcjonalnie na dochód zagraniczny"]} {
    object.get(input.jdg_entrepreneur, "foreign_tax_paid", 0) > 0
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.foreign_tax_credit_excess_carry","package":"jdg.residency.hyper","priority":1487,"_routing":"","_routing_reason":"Ulga: nadwyżka podatku zagranicznego","_legal_basis":"Art. 27 ust. 9 PIT","_warnings":["Nadwyżka podatku zagranicznego ponad limit — nie podlega zwrotowi ani przeniesieniu"]} {
    object.get(input.jdg_entrepreneur, "foreign_tax_exceeds_limit", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.abolition_relief_applicable","package":"jdg.residency.hyper","priority":1488,"_routing":"","_routing_reason":"Ulga abolicyjna — dostępna","_legal_basis":"Art. 27g PIT","_warnings":["Ulga abolicyjna — odliczenie różnicy między metodą odliczenia a wyłączenia dla wybranych krajów"]} {
    object.get(input.jdg_entrepreneur, "abolition_relief_eligible", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.abolition_relief_calculation","package":"jdg.residency.hyper","priority":1489,"_routing":"","_routing_reason":"Ulga abolicyjna — kalkulacja","_legal_basis":"Art. 27g PIT","_warnings":["Ulga abolicyjna = podatek wg metody odliczenia - podatek wg metody wyłączenia"]} {
    object.get(input.jdg_entrepreneur, "abolition_relief_calculation_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.foreign_tax_documentation","package":"jdg.residency.hyper","priority":1490,"_routing":"","_routing_reason":"Ulga: dokumentacja podatku zagranicznego","_legal_basis":"Art. 27 ust. 9 PIT","_warnings":["Zachowaj zagraniczne deklaracje podatkowe i dowody zapłaty dla celów ulgi"]} {
    object.get(input.jdg_entrepreneur, "foreign_tax_documents_collected", false) == false
}

# ══ R1491-R1495: Exit Tax ══
else := {"matched":true,"rule_id":"jdg.residency.hyper.exit_tax_4m_threshold","package":"jdg.residency.hyper","priority":1491,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Exit tax: próg 4M PLN","_legal_basis":"Art. 30da PIT","_warnings":["Zmiana rezydencji — exit tax od niezrealizowanych zysków >4M PLN!"]} {
    object.get(input.jdg_entrepreneur, "planning_residency_change", false) == true
    object.get(input.jdg_entrepreneur, "unrealized_gains_pln", 0) > 4000000
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.exit_tax_rate_19pct","package":"jdg.residency.hyper","priority":1492,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Exit tax: stawka 19%","_legal_basis":"Art. 30da PIT","_warnings":["Exit tax — stawka 19% od niezrealizowanych zysków"]} {
    object.get(input.jdg_entrepreneur, "planning_residency_change", false) == true
    object.get(input.jdg_entrepreneur, "unrealized_gains_pln", 0) > 4000000
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.exit_tax_installments_5x20pct","package":"jdg.residency.hyper","priority":1493,"_routing":"","_routing_reason":"Exit tax: raty 5×20%","_legal_basis":"Art. 30da ust. 7 PIT","_warnings":["Exit tax — możliwość rozłożenia na 5 rat rocznych po 20%"]} {
    object.get(input.jdg_entrepreneur, "exit_tax_installments_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.exit_tax_deadline_7th_month","package":"jdg.residency.hyper","priority":1494,"_routing":"WARNING","_routing_reason":"Exit tax: termin 7 miesięcy","_legal_basis":"Art. 30da ust. 6 PIT","_warnings":["Exit tax — zapłać do 7. miesiąca po zmianie rezydencji"]} {
    object.get(input.jdg_entrepreneur, "planning_residency_change", false) == true
    object.get(input.jdg_entrepreneur, "exit_tax_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.exit_tax_reporting_obligations","package":"jdg.residency.hyper","priority":1495,"_routing":"TRIAGE_QUEUE","_routing_reason":"Exit tax: obowiązki raportowe","_legal_basis":"Art. 30da ust. 5 PIT","_warnings":["Exit tax — złóż PIT-NZS i PIT-36 z załącznikiem o exit tax"]} {
    object.get(input.jdg_entrepreneur, "exit_tax_reporting_done", false) == false
}

# ══ R1496-R1500: Dual Residency ══
else := {"matched":true,"rule_id":"jdg.residency.hyper.dual_residency_detection","package":"jdg.residency.hyper","priority":1496,"_routing":"WARNING","_routing_reason":"Podwójna rezydencja — wykrycie","_legal_basis":"OECD MTC Art. 4","_warnings":["Podwójna rezydencja — oba kraje uznają Cię za rezydenta. Konieczny tie-breaker"]} {
    object.get(input.jdg_entrepreneur, "dual_residency_conflict_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.dual_residency_permanent_home","package":"jdg.residency.hyper","priority":1497,"_routing":"","_routing_reason":"Podwójna rezydencja: stałe miejsce zamieszkania","_legal_basis":"OECD MTC Art. 4 ust. 2a","_warnings":["Tie-breaker krok 1: gdzie masz stałe miejsce zamieszkania?"]} {
    object.get(input.jdg_entrepreneur, "tiebreaker_step", 0) == 1
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.dual_residency_vital_interests","package":"jdg.residency.hyper","priority":1498,"_routing":"","_routing_reason":"Podwójna rezydencja: ośrodek interesów życiowych","_legal_basis":"OECD MTC Art. 4 ust. 2b","_warnings":["Tie-breaker krok 2: gdzie są Twoje silniejsze powiązania osobiste i gospodarcze?"]} {
    object.get(input.jdg_entrepreneur, "tiebreaker_step", 0) == 2
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.dual_residency_habitual_abode","package":"jdg.residency.hyper","priority":1499,"_routing":"","_routing_reason":"Podwójna rezydencja: miejsce zwykłego pobytu","_legal_basis":"OECD MTC Art. 4 ust. 2c","_warnings":["Tie-breaker krok 3: gdzie przebywasz częściej?"]} {
    object.get(input.jdg_entrepreneur, "tiebreaker_step", 0) == 3
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.dual_residency_citizenship","package":"jdg.residency.hyper","priority":1500,"_routing":"","_routing_reason":"Podwójna rezydencja: obywatelstwo","_legal_basis":"OECD MTC Art. 4 ust. 2d","_warnings":["Tie-breaker krok 4: jakiego kraju jesteś obywatelem?"]} {
    object.get(input.jdg_entrepreneur, "tiebreaker_step", 0) == 4
}

# ══ R1501-R1505: Permanent Establishment (PE) ══
else := {"matched":true,"rule_id":"jdg.residency.hyper.pe_construction_12months","package":"jdg.residency.hyper","priority":1501,"_routing":"WARNING","_routing_reason":"PE: plac budowy >12 miesięcy","_legal_basis":"OECD MTC Art. 5 ust. 3","_warnings":["Plac budowy/montaż za granicą >12 miesięcy = zakład podatkowy"]} {
    object.get(input.jdg_entrepreneur, "construction_project_months", 0) > 12
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.pe_fixed_place_of_business","package":"jdg.residency.hyper","priority":1502,"_routing":"WARNING","_routing_reason":"PE: stałe miejsce prowadzenia działalności","_legal_basis":"OECD MTC Art. 5 ust. 1","_warnings":["Stałe miejsce prowadzenia działalności za granicą = zakład podatkowy"]} {
    object.get(input.jdg_entrepreneur, "fixed_place_abroad", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.pe_dependent_agent","package":"jdg.residency.hyper","priority":1503,"_routing":"WARNING","_routing_reason":"PE: zależny przedstawiciel","_legal_basis":"OECD MTC Art. 5 ust. 5","_warnings":["Zależny przedstawiciel za granicą z uprawnieniem do zawierania umów = PE"]} {
    object.get(input.jdg_entrepreneur, "dependent_agent_abroad", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.pe_digital_server","package":"jdg.residency.hyper","priority":1504,"_routing":"WARNING","_routing_reason":"Digital PE: serwer za granicą","_legal_basis":"OECD BEPS 2.0 Pillar 1","_warnings":["Serwer w obcym kraju + znacząca obecność cyfrowa = ryzyko digital PE"]} {
    object.get(input.jdg_entrepreneur, "has_foreign_server", false) == true
    object.get(input.jdg_entrepreneur, "significant_digital_presence", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.pe_registration_obligation","package":"jdg.residency.hyper","priority":1505,"_routing":"TRIAGE_QUEUE","_routing_reason":"PE: obowiązek rejestracji za granicą","_legal_basis":"Przepisy kraju PE","_warnings":["Zakład podatkowy za granicą — obowiązek rejestracji podatkowej w tym kraju"]} {
    object.get(input.jdg_entrepreneur, "permanent_establishment_risk", false) == true
    object.get(input.jdg_entrepreneur, "pe_registration_done", false) == false
}

# ══ R1506-R1510: CFC ══
else := {"matched":true,"rule_id":"jdg.residency.hyper.cfc_control_50pct","package":"jdg.residency.hyper","priority":1506,"_routing":"TRIAGE_QUEUE","_routing_reason":"CFC: kontrola >50%","_legal_basis":"Art. 30f ust. 1 PIT","_warnings":["CFC — kontrola >50% w podmiocie zagranicznym"]} {
    object.get(input.jdg_entrepreneur, "cfc_ownership_pct", 0) > 50
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.cfc_low_tax_jurisdiction","package":"jdg.residency.hyper","priority":1507,"_routing":"TRIAGE_QUEUE","_routing_reason":"CFC: niskie opodatkowanie <14.25%","_legal_basis":"Art. 30f ust. 3 PIT","_warnings":["CFC — podatek w kraju CFC <14.25% (lub <75% stawki PL)"]} {
    object.get(input.jdg_entrepreneur, "cfc_tax_rate_effective", 0) < 14.25
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.cfc_passive_income_50pct","package":"jdg.residency.hyper","priority":1508,"_routing":"TRIAGE_QUEUE","_routing_reason":"CFC: dochody pasywne >50%","_legal_basis":"Art. 30f ust. 4 PIT","_warnings":["CFC — dochody pasywne (odsetki, należności licencyjne, dywidendy) >50%"]} {
    object.get(input.jdg_entrepreneur, "cfc_passive_income_pct", 0) > 50
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.cfc_de_minimis_250k_eur","package":"jdg.residency.hyper","priority":1509,"_routing":"","_routing_reason":"CFC: de minimis 250k EUR","_legal_basis":"Art. 30f ust. 5 PIT","_warnings":["CFC — wyłączenie de minimis: przychody CFC <250k EUR rocznie"]} {
    object.get(input.jdg_entrepreneur, "cfc_revenue_eur", 0) < 250000
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.cfc_reporting_obligation","package":"jdg.residency.hyper","priority":1510,"_routing":"TRIAGE_QUEUE","_routing_reason":"CFC: obowiązek raportowania","_legal_basis":"Art. 30f ust. 6 PIT","_warnings":["CFC — złóż PIT-CFC i opodatkuj dochody CFC w PL (stawka 19%)"]} {
    object.get(input.jdg_entrepreneur, "cfc_reporting_done", false) == false
    object.get(input.jdg_entrepreneur, "cfc_applicable", false) == true
}

# ══ R1511-R1515: Digital Nomad ══
else := {"matched":true,"rule_id":"jdg.residency.hyper.nomad_center_of_life_test","package":"jdg.residency.hyper","priority":1511,"_routing":"WARNING","_routing_reason":"Digital nomad: test centrum życiowego","_legal_basis":"Art. 3 PIT","_warnings":["Digital nomad — ustal gdzie jest Twoje centrum interesów życiowych"]} {
    object.get(input.jdg_entrepreneur, "digital_nomad", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.nomad_tax_residence_while_traveling","package":"jdg.residency.hyper","priority":1512,"_routing":"TRIAGE_QUEUE","_routing_reason":"Digital nomad: rezydencja w podróży","_legal_basis":"Art. 3 PIT","_warnings":["Digital nomad — jeśli <183 dni w żadnym kraju, rezydencja PL (jeśli tu centrum życia)"]} {
    object.get(input.jdg_entrepreneur, "digital_nomad", false) == true
    object.get(input.jdg_entrepreneur, "days_in_pl", 0) < 183
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.nomad_income_sourcing","package":"jdg.residency.hyper","priority":1513,"_routing":"","_routing_reason":"Digital nomad: źródło dochodów","_legal_basis":"Art. 3 PIT","_warnings":["Digital nomad — dochody z pracy zdalnej opodatkowane w kraju rezydencji"]} {
    object.get(input.jdg_entrepreneur, "digital_nomad", false) == true
    object.get(input.jdg_entrepreneur, "income_source_unclear", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.nomad_zus_obligations","package":"jdg.residency.hyper","priority":1514,"_routing":"WARNING","_routing_reason":"Digital nomad: ZUS","_legal_basis":"Art. 6 SUS","_warnings":["Digital nomad — sprawdź czy podlegasz polskiemu ZUS (legislacja właściwa wg miejsca pracy)"]} {
    object.get(input.jdg_entrepreneur, "digital_nomad", false) == true
    object.get(input.jdg_entrepreneur, "zus_status_unclear", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.nomad_health_insurance_gap","package":"jdg.residency.hyper","priority":1515,"_routing":"WARNING","_routing_reason":"Digital nomad: ubezpieczenie zdrowotne","_legal_basis":"Ustawa o ubezpieczeniach zdrowotnych","_warnings":["Digital nomad — ryzyko luki w ubezpieczeniu zdrowotnym"]} {
    object.get(input.jdg_entrepreneur, "digital_nomad", false) == true
    object.get(input.jdg_entrepreneur, "health_insurance_coverage", "") == "NONE"
}

# ══ R1516-R1517: Aggregate ══
else := {"matched":true,"rule_id":"jdg.residency.hyper.aggregate_risk_map","package":"jdg.residency.hyper","priority":1516,"_routing":"TRIAGE_QUEUE","_routing_reason":"Mapa ryzyka rezydencji","_legal_basis":"Art. 3 PIT","_warnings":["Mapa ryzyka rezydencji — sprawdź: PE, CFC, exit tax, podwójna rezydencja"]} {
    object.get(input.jdg_entrepreneur, "residency_risk_assessment_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.aggregate_recommendations","package":"jdg.residency.hyper","priority":1517,"_routing":"","_routing_reason":"Rekomendacje rezydencji","_legal_basis":"Art. 3 PIT","_warnings":["Rekomendacje: 1) sprawdź CFR kontrahentów 2) udokumentuj dni pobytu 3) sprawdź UPO"]} {
    object.get(input.jdg_entrepreneur, "residency_risk_assessment_needed", false) == true
}

# ══ R1518-R1523: Residency Self-Assessment (P1) + UPO Without Progression (P1) ══
else := {"matched":true,"rule_id":"jdg.residency.hyper.residency_self_assessment","package":"jdg.residency.hyper","priority":1518,"_routing":"TRIAGE_QUEUE","_routing_reason":"Samoocena rezydencji — lista kontrolna","_legal_basis":"Art. 3 ust. 1a PIT","_warnings":["SAMOOCENA REZYDENCJI: (1) Ile dni w PL w roku? (2) Gdzie centrum interesów życiowych? (3) Gdzie rodzina? (4) Gdzie główne źródła dochodu? (5) Czy jest UPO z drugim krajem? Odpowiedzi decydują o rezydencji!"]} {
    object.get(input.jdg_entrepreneur, "residency_self_assessment_done", false) == false
    object.get(input.jdg_entrepreneur, "has_foreign_income", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.residency_travel_calendar","package":"jdg.residency.hyper","priority":1519,"_routing":"","_routing_reason":"Kalendarz pobytów — dowód rezydencji","_legal_basis":"Art. 3 ust. 1a PIT","_warnings":["Prowadź kalendarz pobytów (bilety, rezerwacje, paszport) jako dowód dla US. Każdy dzień w PL się liczy — nawet częściowy! Przekroczenie 183 dni = rezydent PL."]} {
    object.get(input.jdg_entrepreneur, "travel_calendar_maintained", false) == false
    object.get(input.jdg_entrepreneur, "days_in_pl", 0) > 90
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.dtt_exemption_without_progression","package":"jdg.residency.hyper","priority":1520,"_routing":"TRIAGE_QUEUE","_routing_reason":"UPO: metoda wyłączenia BEZ progresji (kraje spoza EOG)","_legal_basis":"Umowy bilateralne (np. ZEA, Katar, Arabia Saudyjska)","_warnings":["Metoda wyłączenia BEZ progresji — dochód zagraniczny całkowicie zwolniony i NIE wpływa na stawkę PIT od dochodów PL. Dotyczy krajów spoza EOG (np. ZEA, Katar). Sprawdź treść konkretnej UPO!"]} {
    object.get(input.jdg_entrepreneur, "dtt_method", "") == "EXEMPTION_WITHOUT_PROGRESSION"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.residency_sis_integration_placeholder","package":"jdg.residency.hyper","priority":1521,"_routing":"","_routing_reason":"Integracja z SIS — placeholder (API niepubliczne)","_legal_basis":"—","_warnings":["Integracja z Systemem Informacyjnym Schengen (SIS) nie jest dostępna dla podmiotów prywatnych. Prowadź własny rejestr pobytów. W razie kontroli US może wystąpić do Straży Granicznej o dane."]} {
    object.get(input.jdg_entrepreneur, "sis_integration_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.cfr_tracker_auto_renewal","package":"jdg.residency.hyper","priority":1522,"_routing":"WARNING","_routing_reason":"CFR tracker: monitoruj ważność certyfikatów","_legal_basis":"Art. 26 ust. 1 PIT","_warnings":["CFR kontrahenta traci ważność za <30 dni! Wyślij prośbę o nowy certyfikat. Bez ważnego CFR: brak preferencji WHT, ryzyko 20% podatku u źródła."]} {
    object.get(input.vendor, "cfr_age_months", 0) >= 11
    object.get(input.vendor, "cfr_expiry_days", 100) <= 30
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.exit_tax_proactive_monitor","package":"jdg.residency.hyper","priority":1523,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Exit tax: monitor progu 4M PLN — alert przy 80%","_legal_basis":"Art. 30da PIT","_warnings":["UWAGA: wartość niezrealizowanych zysków zbliża się do progu 4M PLN (osiągnięto 80%). Przy zmianie rezydencji powyżej progu = exit tax 19%! Rozważ strategię wyjścia."]} {
    object.get(input.jdg_entrepreneur, "unrealized_gains_pln", 0) >= 3200000
    object.get(input.jdg_entrepreneur, "unrealized_gains_pln", 0) < 4000000
}
