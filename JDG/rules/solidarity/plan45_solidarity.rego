# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.solidarity hyper-granularity (Doc 45: R1043-R1070)
# Atom rules: danina solidarnościowa 4% — thresholds, sources, exclusions
# Rules: 28 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.solidarity.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.solidarity.hyper.no_match","package":"jdg.solidarity.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.solidarity.hyper.threshold_1m","package":"jdg.solidarity.hyper","priority":1043,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Danina solidarnościowa: próg 1M PLN","_legal_basis":"Art. 30h ust. 1 PIT","_warnings":["Dochód przekroczył 1M PLN — danina solidarnościowa 4% od nadwyżki!"],"valid_from":"2019-01-01","valid_to":null,"decision_mode":"SUGGEST"} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.base_calculation","package":"jdg.solidarity.hyper","priority":1044,"_routing":"","_routing_reason":"Podstawa = dochód - 1M PLN","_legal_basis":"Art. 30h ust. 1 PIT","_warnings":["Podstawa daniny = suma dochodów - 1 000 000 PLN"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.rate_4pct","package":"jdg.solidarity.hyper","priority":1045,"_routing":"","_routing_reason":"Stawka: 4% od podstawy","_legal_basis":"Art. 30h ust. 1 PIT","_warnings":["Danina solidarnościowa = 4% × (dochód - 1M PLN)"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.minimum_zero","package":"jdg.solidarity.hyper","priority":1046,"_routing":"","_routing_reason":"Minimum: danina nie może być ujemna","_legal_basis":"Art. 30h PIT","_warnings":["Danina ≥ 0 — nie może być ujemna"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.income_scale","package":"jdg.solidarity.hyper","priority":1047,"_routing":"","_routing_reason":"Źródło: skala PIT","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Dochód opodatkowany skalą PIT wlicza się do podstawy daniny"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.income_linear","package":"jdg.solidarity.hyper","priority":1048,"_routing":"","_routing_reason":"Źródło: PIT liniowy 19%","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Dochód opodatkowany liniowo 19% wlicza się do podstawy daniny"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_LINEAR"
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.income_lump_sum","package":"jdg.solidarity.hyper","priority":1049,"_routing":"","_routing_reason":"Źródło: ryczałt","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Przychód z ryczałtu wlicza się do podstawy po odliczeniu składek"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LUMP_SUM"
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.income_ip_box","package":"jdg.solidarity.hyper","priority":1050,"_routing":"","_routing_reason":"Źródło: IP Box 5%","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Dochód z IP Box (5%) wlicza się do podstawy daniny"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "IP_BOX"
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.income_capital_gains","package":"jdg.solidarity.hyper","priority":1051,"_routing":"","_routing_reason":"Źródło: dochody kapitałowe","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Dochody kapitałowe (19%) wlicza się do podstawy daniny"]} {
    object.get(input.jdg_entrepreneur, "has_capital_gains", false) == true
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.income_foreign","package":"jdg.solidarity.hyper","priority":1052,"_routing":"","_routing_reason":"Źródło: dochody zagraniczne","_legal_basis":"Art. 30h ust. 2-3 PIT","_warnings":["Dochody zagraniczne (opodatkowane i zwolnione) wlicza się do podstawy"]} {
    object.get(input.jdg_entrepreneur, "has_foreign_income", false) == true
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.zus_social_exclusion","package":"jdg.solidarity.hyper","priority":1053,"_routing":"","_routing_reason":"ZUS społeczne pomniejszają dochód","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Składki ZUS społeczne (emerytalne + rentowe) pomniejszają podstawę"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.zus_health_no_exclusion","package":"jdg.solidarity.hyper","priority":1054,"_routing":"","_routing_reason":"Zdrowotna NIE pomniejsza","_legal_basis":"Art. 30h PIT","_warnings":["Składka zdrowotna NIE pomniejsza dochodu dla celów daniny"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.exemption_wylaczenie","package":"jdg.solidarity.hyper","priority":1055,"_routing":"","_routing_reason":"Metoda wyłączenia — NIE wlicza się","_legal_basis":"Art. 30h ust. 3 PIT","_warnings":["Dochody z UPO metodą wyłączenia NIE wchodzą do podstawy daniny"]} {
    object.get(input.jdg_entrepreneur, "foreign_method", "") == "EXEMPTION"
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.foreign_tax_credit_correction","package":"jdg.solidarity.hyper","priority":1056,"_routing":"","_routing_reason":"Metoda odliczenia — korekta","_legal_basis":"Art. 30h ust. 3 PIT","_warnings":["Dochody metodą odliczenia — wlicza się, ale z korektą o podatek zagraniczny"]} {
    object.get(input.jdg_entrepreneur, "foreign_method", "") == "CREDIT"
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.spouse_individual","package":"jdg.solidarity.hyper","priority":1057,"_routing":"","_routing_reason":"Każdy małżonek osobno","_legal_basis":"Art. 30h PIT","_warnings":["Każdy małżonek oblicza daninę osobno — nawet przy wspólnym rozliczeniu"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.spouse_no_income_transfer","package":"jdg.solidarity.hyper","priority":1058,"_routing":"","_routing_reason":"Zakaz transferu dochodu na małżonka","_legal_basis":"Art. 30h PIT","_warnings":["Nie można przenieść dochodu na małżonka dla uniknięcia daniny"]} {
    object.get(input.jdg_entrepreneur, "income_transfer_suspected", false) == true
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.payment_deadline_april30","package":"jdg.solidarity.hyper","priority":1059,"_routing":"WARNING","_routing_reason":"Termin: 30 kwietnia","_legal_basis":"Art. 30h ust. 5 PIT","_warnings":["Danina solidarnościowa — zapłać do 30 kwietnia następnego roku!"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.payment_no_advances","package":"jdg.solidarity.hyper","priority":1060,"_routing":"","_routing_reason":"Brak zaliczek — jednorazowa","_legal_basis":"Art. 30h PIT","_warnings":["Danina solidarnościowa — brak zaliczek, jednorazowa płatność roczna"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.payment_mandatory_transfer","package":"jdg.solidarity.hyper","priority":1061,"_routing":"WARNING","_routing_reason":"Przelew na mikrorachunek","_legal_basis":"Art. 30h PIT","_warnings":["Danina — obowiązek przelewu na mikrorachunek podatkowy"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.sanction_late_payment","package":"jdg.solidarity.hyper","priority":1062,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Odsetki za zwłokę","_legal_basis":"Art. 56 OP","_warnings":["Odsetki za zwłokę od niezapłaconej daniny solidarnościowej"]} {
    object.get(input.jdg_entrepreneur, "solidarity_levy_overdue", false) == true
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.sanction_underpayment_kks","package":"jdg.solidarity.hyper","priority":1063,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Sankcja KKS za zaniżenie","_legal_basis":"Art. 56 KKS","_warnings":["Celowe zaniżenie podstawy daniny → ryzyko odpowiedzialności KKS"]} {
    object.get(input.jdg_entrepreneur, "underpayment_suspected", false) == true
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.interaction_pit_free_amount","package":"jdg.solidarity.hyper","priority":1064,"_routing":"","_routing_reason":"Kwota wolna NIE wpływa","_legal_basis":"Art. 30h PIT","_warnings":["Kwota wolna 30k NIE wpływa na obliczenie daniny solidarnościowej"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.interaction_tax_scale","package":"jdg.solidarity.hyper","priority":1065,"_routing":"","_routing_reason":"Danina NIE wpływa na próg 120k","_legal_basis":"Art. 30h PIT","_warnings":["Danina NIE wpływa na próg podatkowy 120k w skali"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.edge_first_year_1m","package":"jdg.solidarity.hyper","priority":1066,"_routing":"","_routing_reason":"Pierwszy rok >1M — pełna danina","_legal_basis":"Art. 30h PIT","_warnings":["Pierwszy rok z dochodem >1M — danina od pełnej nadwyżki"]} {
    object.get(input.jdg_entrepreneur, "first_year_over_1m", false) == true
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.edge_loss_reduction","package":"jdg.solidarity.hyper","priority":1067,"_routing":"","_routing_reason":"Strata pomniejsza","_legal_basis":"Art. 9 ust. 3 PIT","_warnings":["Strata z JDG pomniejsza dochód łączny dla daniny"]} {
    object.get(input.jdg_entrepreneur, "has_business_loss", false) == true
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.edge_one_time_income","package":"jdg.solidarity.hyper","priority":1068,"_routing":"","_routing_reason":"Jednorazowy dochód wlicza się","_legal_basis":"Art. 30h PIT","_warnings":["Jednorazowy dochód (np. sprzedaż nieruchomości firmowej) wlicza się"]} {
    object.get(input.jdg_entrepreneur, "one_time_income", false) == true
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.forecast_annual","package":"jdg.solidarity.hyper","priority":1069,"_routing":"WARNING","_routing_reason":"Prognoza roczna","_legal_basis":"Art. 30h PIT","_warnings":["Prognoza daniny na podstawie dochodów narastających"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 900000
}
else := {"matched":true,"rule_id":"jdg.solidarity.hyper.alert_900k","package":"jdg.solidarity.hyper","priority":1070,"_routing":"WARNING","_routing_reason":"Alert 900k — zbliżanie się do progu","_legal_basis":"Art. 30h PIT","_warnings":["UWAGA: 900k PLN — zbliżasz się do progu daniny solidarnościowej!"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 900000
}
