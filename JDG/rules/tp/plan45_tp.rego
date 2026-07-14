# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.tp hyper-granularity (Doc 45: R1431-R1475)
# Atom rules: related party detection, thresholds, Local/Master File, TPR-C,
#   benchmarking, safe harbor, adjustment, sanctions
# Rules: 45 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tp.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.tp.hyper.no_match","package":"jdg.tp.hyper","priority":99999}

# ══ R1431-R1435: Related Party Detection ══
decide := {"matched":true,"rule_id":"jdg.tp.hyper.related_25pct_ownership","package":"jdg.tp.hyper","priority":1431,"_routing":"WARNING","_routing_reason":"TP: powiązanie przez 25%+ udziałów","_legal_basis":"Art. 23m ust. 1 pkt 1 PIT","_warnings":["Podmiot powiązany — 25%+ udziałów/akcji"]} {
    object.get(input.vendor, "ownership_pct", 0) >= 25
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.related_family_ties","package":"jdg.tp.hyper","priority":1432,"_routing":"WARNING","_routing_reason":"TP: powiązanie rodzinne","_legal_basis":"Art. 23m ust. 1 pkt 2-3 PIT","_warnings":["Podmiot powiązany — powiązania rodzinne z właścicielem JDG"]} {
    object.get(input.vendor, "family_related_to_owner", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.related_management_ties","package":"jdg.tp.hyper","priority":1433,"_routing":"WARNING","_routing_reason":"TP: powiązanie zarządcze","_legal_basis":"Art. 23m ust. 1 pkt 4 PIT","_warnings":["Podmiot powiązany — powiązanie zarządcze/kontrolne"]} {
    object.get(input.vendor, "management_related", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.related_cross_ownership","package":"jdg.tp.hyper","priority":1434,"_routing":"WARNING","_routing_reason":"TP: powiązanie krzyżowe","_legal_basis":"Art. 23m ust. 1 pkt 5 PIT","_warnings":["Podmiot powiązany — powiązanie krzyżowe między podmiotami"]} {
    object.get(input.vendor, "cross_ownership", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.related_indirect_control","package":"jdg.tp.hyper","priority":1435,"_routing":"WARNING","_routing_reason":"TP: powiązanie pośrednie","_legal_basis":"Art. 23m ust. 2 PIT","_warnings":["Podmiot powiązany — kontrola pośrednia przez inny podmiot"]} {
    object.get(input.vendor, "indirect_control", false) == true
}

# ══ R1436-R1440: Documentation Thresholds ══
else := {"matched":true,"rule_id":"jdg.tp.hyper.threshold_2m_goods_annual","package":"jdg.tp.hyper","priority":1436,"_routing":"WARNING","_routing_reason":"TP: próg 2M PLN — transakcje towarowe rocznie","_legal_basis":"Art. 23zf ust. 1 PIT","_warnings":["Transakcje towarowe >2M PLN/rok z podmiotem powiązanym — obowiązek dokumentacji TP"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.tp, "annual_goods_value_pln", 0) > 2000000
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.threshold_1m_financial_annual","package":"jdg.tp.hyper","priority":1437,"_routing":"WARNING","_routing_reason":"TP: próg 1M PLN — transakcje finansowe rocznie","_legal_basis":"Art. 23zf ust. 2 PIT","_warnings":["Transakcje finansowe >1M PLN/rok z podmiotem powiązanym — dokumentacja TP"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.tp, "annual_financial_value_pln", 0) > 1000000
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.threshold_500k_services_annual","package":"jdg.tp.hyper","priority":1438,"_routing":"WARNING","_routing_reason":"TP: próg 0.5M PLN — usługi/niematerialne rocznie","_legal_basis":"Art. 23zf ust. 3 PIT","_warnings":["Usługi/niematerialne >0.5M PLN/rok z podmiotem powiązanym — dokumentacja TP"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.tp, "annual_services_value_pln", 0) > 500000
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.threshold_eur_conversion_nbp","package":"jdg.tp.hyper","priority":1439,"_routing":"","_routing_reason":"TP: przeliczenie EUR/PLN — kurs NBP z dnia poprzedzającego","_legal_basis":"Art. 23zf ust. 4 PIT","_warnings":["Progi TP w EUR — przelicz po kursie NBP z ostatniego dnia roboczego przed transakcją"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.invoice, "currency", "PLN") != "PLN"
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.threshold_aggregation_all_parties","package":"jdg.tp.hyper","priority":1440,"_routing":"WARNING","_routing_reason":"TP: agregacja z wszystkimi podmiotami powiązanymi","_legal_basis":"Art. 23zf ust. 5 PIT","_warnings":["Sumuj transakcje ze wszystkimi podmiotami powiązanymi — progi liczone łącznie"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.tp, "multiple_related_parties", false) == true
}

# ══ R1441-R1445: Local File Requirements ══
else := {"matched":true,"rule_id":"jdg.tp.hyper.local_file_functional_analysis","package":"jdg.tp.hyper","priority":1441,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: Local File — analiza funkcjonalna","_legal_basis":"Art. 23zf ust. 6 PIT","_warnings":["Local File — wymagana analiza funkcjonalna: funkcje, aktywa, ryzyka"]} {
    object.get(input.tp, "local_file_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.local_file_tp_analysis","package":"jdg.tp.hyper","priority":1442,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: Local File — analiza cen transferowych","_legal_basis":"Art. 23zf ust. 6 PIT","_warnings":["Local File — analiza cen transferowych: metoda, uzasadnienie wyboru"]} {
    object.get(input.tp, "local_file_required", false) == true
    object.get(input.tp, "local_file_prepared", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.local_file_comparability_analysis","package":"jdg.tp.hyper","priority":1443,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: Local File — analiza porównywalna","_legal_basis":"Art. 23zf ust. 7 PIT","_warnings":["Local File — analiza porównywalna: benchmark, kryteria wyboru porównywalnych"]} {
    object.get(input.tp, "local_file_required", false) == true
    object.get(input.tp, "benchmarking_completed", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.local_file_financial_data","package":"jdg.tp.hyper","priority":1444,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: Local File — dane finansowe","_legal_basis":"Art. 23zf ust. 6 PIT","_warnings":["Local File — dane finansowe podmiotów powiązanych za ostatni rok"]} {
    object.get(input.tp, "local_file_required", false) == true
    object.get(input.tp, "financial_data_collected", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.local_file_deadline_10months","package":"jdg.tp.hyper","priority":1445,"_routing":"WARNING","_routing_reason":"TP: Local File — termin 10 miesięcy","_legal_basis":"Art. 23zf ust. 8 PIT","_warnings":["Local File — termin: 10 miesięcy po zakończeniu roku podatkowego"]} {
    object.get(input.tp, "local_file_required", false) == true
    object.get(input.tp, "local_file_deadline_approaching", false) == true
}

# ══ R1446-R1450: Master File Requirements ══
else := {"matched":true,"rule_id":"jdg.tp.hyper.master_file_group_revenue_200m","package":"jdg.tp.hyper","priority":1446,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: Master File — grupa >200M PLN","_legal_basis":"Art. 23zf ust. 9 PIT","_warnings":["Master File — grupa o skonsolidowanych przychodach >200M PLN"]} {
    object.get(input.tp, "master_file_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.master_file_group_description","package":"jdg.tp.hyper","priority":1447,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: Master File — opis grupy","_legal_basis":"Art. 23zf ust. 9 PIT","_warnings":["Master File — opis grupy: struktura, działalność, polityka TP"]} {
    object.get(input.tp, "master_file_required", false) == true
    object.get(input.tp, "master_file_prepared", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.master_file_business_model","package":"jdg.tp.hyper","priority":1448,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: Master File — model biznesowy","_legal_basis":"Art. 23zf ust. 9 PIT","_warnings":["Master File — model biznesowy grupy: łańcuch dostaw, kluczowe rynki"]} {
    object.get(input.tp, "master_file_required", false) == true
    object.get(input.tp, "business_model_documented", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.master_file_tp_policy","package":"jdg.tp.hyper","priority":1449,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: Master File — polityka TP grupy","_legal_basis":"Art. 23zf ust. 9 PIT","_warnings":["Master File — polityka cen transferowych grupy: metody, benchmarki"]} {
    object.get(input.tp, "master_file_required", false) == true
    object.get(input.tp, "tp_policy_documented", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.master_file_deadline_12months","package":"jdg.tp.hyper","priority":1450,"_routing":"WARNING","_routing_reason":"TP: Master File — termin 12 miesięcy","_legal_basis":"Art. 23zf ust. 9 PIT","_warnings":["Master File — termin: 12 miesięcy po zakończeniu roku podatkowego"]} {
    object.get(input.tp, "master_file_required", false) == true
    object.get(input.tp, "master_file_deadline_approaching", false) == true
}

# ══ R1451-R1455: TPR-C Form ══
else := {"matched":true,"rule_id":"jdg.tp.hyper.tpr_obligation_check","package":"jdg.tp.hyper","priority":1451,"_routing":"WARNING","_routing_reason":"TP: TPR-C — obowiązek złożenia","_legal_basis":"Art. 23zh PIT","_warnings":["TPR-C — obowiązek dla JDG z transakcjami TP w poprzednim roku"]} {
    object.get(input.tp, "tpr_obligation_exists", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.tpr_deadline_nov30","package":"jdg.tp.hyper","priority":1452,"_routing":"WARNING","_routing_reason":"TP: TPR-C — termin 30 listopada","_legal_basis":"Art. 23zh PIT","_warnings":["TPR-C — złóż do 30 listopada za poprzedni rok!"]} {
    object.get(input.tp, "tpr_obligation_exists", false) == true
    object.get(input.tp, "tpr_filed", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.tpr_data_requirements","package":"jdg.tp.hyper","priority":1453,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: TPR-C — dane do raportu","_legal_basis":"Art. 23zh PIT","_warnings":["TPR-C — przygotuj: dane identyfikacyjne podmiotów powiązanych, wartości transakcji, metody TP"]} {
    object.get(input.tp, "tpr_data_prepared", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.tpr_correction_allowed","package":"jdg.tp.hyper","priority":1454,"_routing":"","_routing_reason":"TP: TPR-C — korekta możliwa","_legal_basis":"Art. 23zh PIT","_warnings":["TPR-C — korekta możliwa w ciągu 14 dni od złożenia"]} {
    object.get(input.tp, "tpr_correction_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.tpr_missing_sanction","package":"jdg.tp.hyper","priority":1455,"_routing":"BLOCK_AND_ALERT","_routing_reason":"TP: TPR-C — sankcja za brak","_legal_basis":"Art. 56 KKS","_warnings":["TPR-C niezłożony po terminie — ryzyko sankcji KKS i kary administracyjnej!"]} {
    object.get(input.tp, "tpr_obligation_exists", false) == true
    object.get(input.tp, "tpr_filed", false) == false
    object.get(input.tp, "tpr_deadline_passed", false) == true
}

# ══ R1456-R1460: Benchmarking Analysis ══
else := {"matched":true,"rule_id":"jdg.tp.hyper.benchmarking_required","package":"jdg.tp.hyper","priority":1456,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: benchmarking — wymagany","_legal_basis":"Art. 23zf ust. 7 PIT","_warnings":["Analiza porównawcza (benchmarking) wymagana dla transakcji z podmiotami powiązanymi"]} {
    object.get(input.tp, "benchmarking_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.benchmarking_databases","package":"jdg.tp.hyper","priority":1457,"_routing":"","_routing_reason":"TP: benchmarking — bazy danych","_legal_basis":"Art. 23zf ust. 7 PIT","_warnings":["Benchmarking — użyj uznanych baz danych (Amadeus, Orbis, Bloomberg)"]} {
    object.get(input.tp, "benchmarking_required", false) == true
    object.get(input.tp, "benchmarking_database_used", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.benchmarking_update_3years","package":"jdg.tp.hyper","priority":1458,"_routing":"WARNING","_routing_reason":"TP: benchmarking — aktualizacja co 3 lata","_legal_basis":"Art. 23zf ust. 7 PIT","_warnings":["Benchmarking — aktualizuj co 3 lata lub przy istotnej zmianie warunków"]} {
    object.get(input.tp, "benchmarking_age_years", 0) > 3
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.benchmarking_margins_analysis","package":"jdg.tp.hyper","priority":1459,"_routing":"","_routing_reason":"TP: benchmarking — analiza marż","_legal_basis":"Art. 23zf ust. 7 PIT","_warnings":["Benchmarking — analiza marż: rozstęp międzykwartylowy, mediana"]} {
    object.get(input.tp, "benchmarking_margins_analyzed", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.benchmarking_documentation_retention","package":"jdg.tp.hyper","priority":1460,"_routing":"","_routing_reason":"TP: benchmarking — retencja dokumentacji","_legal_basis":"Art. 86 OP","_warnings":["Dokumentacja benchmarkingu — przechowuj przez 5 lat"]} {
    object.get(input.tp, "benchmarking_completed", false) == true
}

# ══ R1461-R1465: Safe Harbor ══
else := {"matched":true,"rule_id":"jdg.tp.hyper.safe_harbor_low_value_services","package":"jdg.tp.hyper","priority":1461,"_routing":"","_routing_reason":"TP: safe harbor — usługi niskowartościowe","_legal_basis":"Art. 23zf ust. 10 PIT","_warnings":["Safe harbor — usługi niskowartościowe: marża 5%, pułap 30% kosztów"]} {
    object.get(input.tp, "safe_harbor_applies", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.safe_harbor_5pct_markup","package":"jdg.tp.hyper","priority":1462,"_routing":"","_routing_reason":"TP: safe harbor — narzut 5%","_legal_basis":"Art. 23zf ust. 10 PIT","_warnings":["Safe harbor — narzut 5% na kosztach bezpośrednich i pośrednich"]} {
    object.get(input.tp, "safe_harbor_applies", false) == true
    object.get(input.tp, "safe_harbor_markup_checked", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.safe_harbor_30pct_cost_cap","package":"jdg.tp.hyper","priority":1463,"_routing":"WARNING","_routing_reason":"TP: safe harbor — pułap 30% kosztów","_legal_basis":"Art. 23zf ust. 10 PIT","_warnings":["Safe harbor — usługi niskowartościowe nie mogą przekroczyć 30% całkowitych kosztów"]} {
    object.get(input.tp, "safe_harbor_applies", false) == true
    object.get(input.tp, "safe_harbor_cost_ratio", 0) > 0.30
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.safe_harbor_documentation_light","package":"jdg.tp.hyper","priority":1464,"_routing":"","_routing_reason":"TP: safe harbor — uproszczona dokumentacja","_legal_basis":"Art. 23zf ust. 10 PIT","_warnings":["Safe harbor — uproszczona dokumentacja: opis usług, kalkulacja marży, umowa"]} {
    object.get(input.tp, "safe_harbor_applies", false) == true
    object.get(input.tp, "safe_harbor_documentation_done", false) == false
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.safe_harbor_excluded_services","package":"jdg.tp.hyper","priority":1465,"_routing":"WARNING","_routing_reason":"TP: safe harbor — usługi wyłączone","_legal_basis":"Art. 23zf ust. 10 PIT","_warnings":["Safe harbor NIE dotyczy: usług finansowych, ubezpieczeniowych, IT-core, R&D"]} {
    object.get(input.tp, "service_type", "") == "EXCLUDED_FROM_SAFE_HARBOR"
}

# ══ R1466-R1470: Income Adjustment ══
else := {"matched":true,"rule_id":"jdg.tp.hyper.adjustment_income_reassessment","package":"jdg.tp.hyper","priority":1466,"_routing":"TRIAGE_QUEUE","_routing_reason":"TP: doszacowanie dochodu","_legal_basis":"Art. 58 OP","_warnings":["US może doszacować dochód jeśli ceny nierynkowe"]} {
    object.get(input.tp, "adjustment_risk", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.adjustment_10pct_additional_tax","package":"jdg.tp.hyper","priority":1467,"_routing":"BLOCK_AND_ALERT","_routing_reason":"TP: doszacowanie — 10% dodatkowe","_legal_basis":"Art. 58 OP","_warnings":["Doszacowanie — 10% dodatkowego opodatkowania od różnicy!"]} {
    object.get(input.tp, "adjustment_confirmed", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.adjustment_interest_on_arrears","package":"jdg.tp.hyper","priority":1468,"_routing":"BLOCK_AND_ALERT","_routing_reason":"TP: doszacowanie — odsetki","_legal_basis":"Art. 56 OP","_warnings":["Doszacowanie — odsetki za zwłokę od pierwotnego terminu płatności"]} {
    object.get(input.tp, "adjustment_confirmed", false) == true
    object.get(input.tp, "tax_arrears_exist", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.adjustment_kks_liability","package":"jdg.tp.hyper","priority":1469,"_routing":"BLOCK_AND_ALERT","_routing_reason":"TP: doszacowanie — KKS","_legal_basis":"Art. 56 KKS","_warnings":["Doszacowanie — ryzyko odpowiedzialności karno-skarbowej!"]} {
    object.get(input.tp, "adjustment_confirmed", false) == true
    object.get(input.tp, "intentional_understatement", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.adjustment_appeal_procedure","package":"jdg.tp.hyper","priority":1470,"_routing":"WARNING","_routing_reason":"TP: doszacowanie — odwołanie 14 dni","_legal_basis":"Art. 223 OP","_warnings":["Doszacowanie — odwołanie w ciągu 14 dni od decyzji!"]} {
    object.get(input.tp, "adjustment_confirmed", false) == true
    object.get(input.tp, "appeal_filed", false) == false
}

# ══ R1471-R1475: Sanctions ══
else := {"matched":true,"rule_id":"jdg.tp.hyper.sanction_no_documentation_10pct","package":"jdg.tp.hyper","priority":1471,"_routing":"BLOCK_AND_ALERT","_routing_reason":"TP: brak dokumentacji — 10% sankcja","_legal_basis":"Art. 56 KKS","_warnings":["Brak dokumentacji TP — 10% dodatkowego zobowiązania od doszacowanego dochodu!"]} {
    object.get(input.tp, "documentation_missing", false) == true
    object.get(input.tp, "adjustment_confirmed", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.sanction_late_documentation","package":"jdg.tp.hyper","priority":1472,"_routing":"WARNING","_routing_reason":"TP: dokumentacja po terminie","_legal_basis":"Art. 23zf PIT","_warnings":["Dokumentacja TP złożona po terminie — ryzyko podwyższonej kontroli"]} {
    object.get(input.tp, "documentation_submitted_late", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.sanction_documentation_errors","package":"jdg.tp.hyper","priority":1473,"_routing":"WARNING","_routing_reason":"TP: błędy w dokumentacji","_legal_basis":"Art. 23zf PIT","_warnings":["Dokumentacja TP zawiera błędy/braki — US może ją zakwestionować"]} {
    object.get(input.tp, "documentation_errors_found", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.sanction_kks_for_intentional_evasion","package":"jdg.tp.hyper","priority":1474,"_routing":"BLOCK_AND_ALERT","_routing_reason":"TP: celowe unikanie — KKS","_legal_basis":"Art. 54-56 KKS","_warnings":["Celowe zaniżanie cen transferowych — odpowiedzialność KKS (grzywna do 720 stawek dziennych)!"]} {
    object.get(input.tp, "intentional_tp_evasion", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.sanction_management_board_liability","package":"jdg.tp.hyper","priority":1475,"_routing":"BLOCK_AND_ALERT","_routing_reason":"TP: odpowiedzialność zarządu","_legal_basis":"Art. 116 OP","_warnings":["Odpowiedzialność osobista właściciela JDG za zaległości TP"]} {
    object.get(input.tp, "personal_liability_triggered", false) == true
}
