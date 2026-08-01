# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.taxfree hyper-granularity (Doc 45: R1403-R1430)
# Atom rules: scale 30k, linear exclusion, multi-source, joint filing, optimization
# Rules: 28 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.taxfree.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.taxfree.hyper.no_match","package":"jdg.taxfree.hyper","priority":99999}

# ══ R1403-R1407: Tax Scale — 30k Free Amount ══
decide := {"matched":true,"rule_id":"jdg.taxfree.hyper.scale_30k_amount","package":"jdg.taxfree.hyper","priority":1403,"_routing":"","_routing_reason":"Skala: 30k kwota wolna","_legal_basis":"Art. 27 ust. 1 PIT","_warnings":["Skala PIT — kwota wolna 30 000 PLN (redukcja podatku o 3 600 PLN)"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.scale_reduction_3600","package":"jdg.taxfree.hyper","priority":1404,"_routing":"","_routing_reason":"Skala: redukcja 3600 PLN","_legal_basis":"Art. 27 ust. 1 PIT","_warnings":["Kwota zmniejszająca podatek = 3 600 PLN (12 × 300 PLN)"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
    object.get(input.jdg_entrepreneur, "annual_income", 0) <= 30000
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.scale_decreasing_amount","package":"jdg.taxfree.hyper","priority":1405,"_routing":"","_routing_reason":"Skala: kwota malejąca 30-127k","_legal_basis":"Art. 27 ust. 1 PIT","_warnings":["Kwota wolna maleje między 30 000 a 127 000 PLN dochodu"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 30000
    object.get(input.jdg_entrepreneur, "annual_income", 0) <= 127000
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.scale_no_free_amount_127k","package":"jdg.taxfree.hyper","priority":1406,"_routing":"","_routing_reason":"Skala: brak kwoty wolnej >127k","_legal_basis":"Art. 27 ust. 1 PIT","_warnings":["Dochód >127 000 PLN — kwota wolna wynosi 0 PLN"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 127000
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.scale_employer_250_monthly","package":"jdg.taxfree.hyper","priority":1407,"_routing":"","_routing_reason":"Etat: 250 PLN/mies.","_legal_basis":"Art. 32 ust. 3 PIT","_warnings":["Pracodawca stosuje 1/12 kwoty wolnej (250 PLN/mies.) przy obliczaniu zaliczek"]} {
    object.get(input.jdg_entrepreneur, "has_employment_income", false) == true
}

# ══ R1408-R1412: Linear Tax Exclusion ══
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.linear_no_free_amount","package":"jdg.taxfree.hyper","priority":1408,"_routing":"","_routing_reason":"Liniowy: brak kwoty wolnej","_legal_basis":"Art. 30c PIT","_warnings":["Podatek liniowy 19% — NIE obowiązuje kwota wolna 30 000 PLN"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LINEAR"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.linear_no_deduction_reminder","package":"jdg.taxfree.hyper","priority":1409,"_routing":"","_routing_reason":"Liniowy: brak odliczenia","_legal_basis":"Art. 30c PIT","_warnings":["Podatek liniowy — nie stosujesz kwoty zmniejszającej podatek"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LINEAR"
    object.get(input.jdg_entrepreneur, "taxfree_incorrectly_applied", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.linear_vs_scale_comparison","package":"jdg.taxfree.hyper","priority":1410,"_routing":"","_routing_reason":"Liniowy vs Skala — punkt opłacalności","_legal_basis":"Art. 27 vs 30c PIT","_warnings":["Porównaj: skala (kwota wolna 30k + 12% do 120k) vs liniowy 19%. Punkt opłacalności ~120k"]} {
    object.get(input.jdg_entrepreneur, "tax_form_comparison_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.linear_communication","package":"jdg.taxfree.hyper","priority":1411,"_routing":"","_routing_reason":"Komunikat: brak kwoty wolnej","_legal_basis":"Art. 30c PIT","_warnings":["Wybrałeś podatek liniowy — nie przysługuje Ci kwota wolna 30k"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LINEAR"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.linear_breakeven_point","package":"jdg.taxfree.hyper","priority":1412,"_routing":"","_routing_reason":"Punkt opłacalności liniowy","_legal_basis":"Art. 27 vs 30c PIT","_warnings":["Liniowy opłacalny przy dochodzie >~120k PLN/rok (przy standardowych odliczeniach)"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 120000
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}

# ══ R1413-R1417: Multi-Source Income ══
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.multi_source_jdg_employment","package":"jdg.taxfree.hyper","priority":1413,"_routing":"","_routing_reason":"JDG + etat: limit łączny","_legal_basis":"Art. 27 PIT","_warnings":["JDG + etat — kwota wolna stosowana łącznie (1 × 30k, nie 2 × 30k!)"]} {
    object.get(input.jdg_entrepreneur, "has_employment_income", false) == true
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.multi_source_jdg_rental","package":"jdg.taxfree.hyper","priority":1414,"_routing":"","_routing_reason":"JDG + najem: jeden limit","_legal_basis":"Art. 27 PIT","_warnings":["JDG + najem prywatny — kwota wolna liczona od łącznego dochodu"]} {
    object.get(input.jdg_entrepreneur, "has_rental_income", false) == true
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.multi_source_jdg_capital","package":"jdg.taxfree.hyper","priority":1415,"_routing":"","_routing_reason":"JDG + kapitały","_legal_basis":"Art. 27 PIT","_warnings":["Dochody kapitałowe (19% ryczałt) — osobno, NIE łączą się z dochodem JDG dla kwoty wolnej"]} {
    object.get(input.jdg_entrepreneur, "has_capital_income", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.multi_source_jdg_foreign","package":"jdg.taxfree.hyper","priority":1416,"_routing":"","_routing_reason":"JDG + dochód zagraniczny","_legal_basis":"Art. 27 ust. 8 PIT","_warnings":["Dochody zagraniczne zwolnione z progresją — wpływają na stawkę, ale NIE na kwotę wolną"]} {
    object.get(input.jdg_entrepreneur, "has_foreign_income", false) == true
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.multi_source_combined_limit","package":"jdg.taxfree.hyper","priority":1417,"_routing":"WARNING","_routing_reason":"Wieloźródłowość: ryzyko zdublowania","_legal_basis":"Art. 27 PIT","_warnings":["Uwaga — kwota wolna 30k jest JEDNA na podatnika, niezależnie od liczby źródeł dochodu!"]} {
    object.get(input.jdg_entrepreneur, "income_sources_count", 0) > 1
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}

# ══ R1418-R1422: Employment Interaction ══
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.employer_applies_taxfree","package":"jdg.taxfree.hyper","priority":1418,"_routing":"","_routing_reason":"Płatnik etatu stosuje 1/12","_legal_basis":"Art. 32 ust. 3 PIT","_warnings":["Pracodawca stosuje 250 PLN/mies. kwoty wolnej — JDG NIE stosuje dodatkowej"]} {
    object.get(input.jdg_entrepreneur, "has_employment_income", false) == true
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.jdg_no_taxfree_in_advances","package":"jdg.taxfree.hyper","priority":1419,"_routing":"","_routing_reason":"JDG nie stosuje kwoty w zaliczkach","_legal_basis":"Art. 44 ust. 3 PIT","_warnings":["JDG na skali — NIE stosuj kwoty wolnej w zaliczkach miesięcznych (robi to tylko płatnik etatu)"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
    object.get(input.jdg_entrepreneur, "has_employment_income", false) == false
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.annual_reconciliation_taxfree","package":"jdg.taxfree.hyper","priority":1420,"_routing":"","_routing_reason":"Rozliczenie roczne kwoty wolnej","_legal_basis":"Art. 45 PIT","_warnings":["W zeznaniu rocznym kwota wolna jest rozliczana od łącznego dochodu"]} {
    object.get(input.jdg_entrepreneur, "annual_return_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.overpayment_from_taxfree","package":"jdg.taxfree.hyper","priority":1421,"_routing":"","_routing_reason":"Nadpłata z kwoty wolnej","_legal_basis":"Art. 45 PIT","_warnings":["Jeśli zaliczki nie uwzględniały kwoty wolnej — możliwa nadpłata w zeznaniu rocznym"]} {
    object.get(input.jdg_entrepreneur, "taxfree_overpayment_expected", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.underpayment_taxfree_warning","package":"jdg.taxfree.hyper","priority":1422,"_routing":"WARNING","_routing_reason":"Niedopłata — kwota wolna","_legal_basis":"Art. 45 PIT","_warnings":["Uwaga — dochód >127k w zeznaniu rocznym powoduje utratę kwoty wolnej → niedopłata!"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 127000
}

# ══ R1423-R1427: Joint Filing ══
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.joint_filing_60k","package":"jdg.taxfree.hyper","priority":1423,"_routing":"","_routing_reason":"Wspólne: podwójna kwota 60k","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Wspólne rozliczenie małżonków — 60 000 PLN łącznej kwoty wolnej"]} {
    object.get(input.jdg_entrepreneur, "joint_filing", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.joint_filing_conditions","package":"jdg.taxfree.hyper","priority":1424,"_routing":"","_routing_reason":"Wspólne: warunki","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Warunki: małżeństwo cały rok, wspólność majątkowa, oboje na skali"]} {
    object.get(input.jdg_entrepreneur, "joint_filing_eligible", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.joint_filing_pit36","package":"jdg.taxfree.hyper","priority":1425,"_routing":"WARNING","_routing_reason":"PIT-36 ze wskazaniem wspólnego","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Złóż PIT-36 z zaznaczeniem wspólnego rozliczenia do 30 kwietnia"]} {
    object.get(input.jdg_entrepreneur, "joint_filing", false) == true
    object.get(input.jdg_entrepreneur, "pit36_filed", false) == false
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.joint_filing_benefit","package":"jdg.taxfree.hyper","priority":1426,"_routing":"","_routing_reason":"Korzyść: podwójny próg 240k","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Wspólne rozliczenie — podwójny próg 240k (zamiast 120k) przed 32%"]} {
    object.get(input.jdg_entrepreneur, "joint_filing", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.joint_vs_individual_comparison","package":"jdg.taxfree.hyper","priority":1427,"_routing":"","_routing_reason":"Wspólne vs indywidualne","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Porównaj: indywidualnie (30k kwoty, 120k próg) vs wspólnie (60k kwoty, 240k próg)"]} {
    object.get(input.jdg_entrepreneur, "tax_form_comparison_requested", false) == true
}

# ══ R1428-R1430: Optimization ══
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.optimize_individual_vs_joint","package":"jdg.taxfree.hyper","priority":1428,"_routing":"","_routing_reason":"Optymalizacja: indywidualne vs wspólne","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Gdy jeden małżonek zarabia dużo a drugi mało — wspólne rozliczenie daje dużą oszczędność"]} {
    object.get(input.jdg_entrepreneur, "optimization_scenario", "") == "JOINT_VS_INDIVIDUAL"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.optimize_simulation","package":"jdg.taxfree.hyper","priority":1429,"_routing":"","_routing_reason":"Symulacja podatkowa","_legal_basis":"Art. 27 PIT","_warnings":["Symulacja: podatek indywidualnie vs wspólnie — różnica X PLN"]} {
    object.get(input.jdg_entrepreneur, "tax_simulation_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.optimize_recommendation","package":"jdg.taxfree.hyper","priority":1430,"_routing":"","_routing_reason":"Rekomendacja optymalizacyjna","_legal_basis":"Art. 27 PIT","_warnings":["Rekomendacja: rozważ wspólne rozliczenie — oszczędność do X PLN"]} {
    object.get(input.jdg_entrepreneur, "optimization_recommendation_ready", false) == true
}

# ══ R1431-R1440: TAX FREE Tourist System (L-TF-1 Fix) — Art. 126-130 VAT ══
# NOTE: R1431 (sub-200) must fire before R1432 (detection) so sub-200 sales see the minimum warning
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.tourist_taxfree_min_200_pln_net","package":"jdg.taxfree.hyper","priority":1431,"_routing":"WARNING","_routing_reason":"TAX FREE — min. 200 PLN netto na paragonie","_legal_basis":"Art. 128 ust. 1 VAT","_warnings":["TAX FREE — minimalna wartość zakupu: 200 PLN netto (brutto: 246 PLN przy 23% VAT) na jednym paragonie dla turysty. Sprzedaż poniżej 200 PLN netto NIE kwalifikuje się do TAX FREE"]} {
    object.get(input.invoice, "total_net_value", 0) < 200
    object.get(input.invoice, "buyer_non_eu_resident", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.tourist_taxfree_detection_non_eu","package":"jdg.taxfree.hyper","priority":1432,"_routing":"TRIAGE_QUEUE","_routing_reason":"TAX FREE — detekcja turysty spoza UE","_legal_basis":"Art. 126-130 VAT","_warnings":["TAX FREE dla turystów — sprzedaż detaliczna turystom spoza UE (≥200 PLN netto). Sprawdź paszport / dokument pobytowy kupującego. Wystaw dokument TAX FREE (oryginał + 2 kopie)"]} {
    object.get(input.invoice, "buyer_non_eu_resident", false) == true
    object.get(input.invoice, "sale_type", "") == "RETAIL_B2C"
    object.get(input.invoice, "total_net_value", 0) >= 200
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.tourist_taxfree_document_generation","package":"jdg.taxfree.hyper","priority":1433,"_routing":"WARNING","_routing_reason":"TAX FREE — generuj dokument","_legal_basis":"Art. 128 VAT","_warnings":["TAX FREE — wystaw dokument TAX FREE (oryginał + 2 kopie). Potrzebne: dane paszportowe, kraj zamieszkania, data wywozu (max 3 mies. od zakupu)"]} {
    object.get(input.invoice, "buyer_non_eu_resident", false) == true
    object.get(input.invoice, "total_net_value", 0) >= 200
    object.get(input.invoice, "taxfree_document_generated", false) == false
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.tourist_taxfree_export_deadline_3months","package":"jdg.taxfree.hyper","priority":1434,"_routing":"BLOCK_AND_ALERT","_routing_reason":"TAX FREE — 3 mies. na wywóz","_legal_basis":"Art. 128 ust. 4 VAT","_warnings":["TAX FREE — turysta ma 3 miesiące od daty zakupu na wywóz towaru poza UE i potwierdzenie dokumentu przez celnika. Po terminie: ZWROTU NIE MA!"]} {
    object.get(input.invoice, "taxfree_generated_date", "") != ""
    object.get(input.invoice, "export_deadline_passed", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.tourist_taxfree_vat_refund_calculation","package":"jdg.taxfree.hyper","priority":1435,"_routing":"","_routing_reason":"TAX FREE — kalkulacja zwrotu VAT","_legal_basis":"Art. 129 VAT","_warnings":["TAX FREE — zwrot VAT wg stawek: 23%→18.7%, 8%→6.5%, 5%→4.1% (zwrot pomniejszony o prowizję). Wypłata gotówkowa lub na konto w ciągu 7 dni"]} {
    object.get(input.invoice, "taxfree_confirmed_by_customs", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.tourist_taxfree_cash_register_integration","package":"jdg.taxfree.hyper","priority":1436,"_routing":"","_routing_reason":"TAX FREE — kasa fiskalna","_legal_basis":"Art. 111 VAT","_warnings":["TAX FREE — wymagana kasa fiskalna online. Paragon z adnotacją 'TAX FREE' + NIP sprzedawcy. Ewidencja w JPK_V7 z oznaczeniem 'TF'"]} {
    object.get(input.jdg_entrepreneur, "has_online_cash_register", false) == false
    object.get(input.invoice, "buyer_non_eu_resident", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.tourist_taxfree_monthly_report","package":"jdg.taxfree.hyper","priority":1437,"_routing":"WARNING","_routing_reason":"TAX FREE — raport miesięczny","_legal_basis":"Art. 129 ust. 3 VAT","_warnings":["TAX FREE — prowadź ewidencję dokumentów TAX FREE: data, kwota netto, VAT, kraj turysty. Miesięczny raport do US"]} {
    object.get(input.jdg_entrepreneur, "month_end", false) == true
    object.get(input.invoice, "taxfree_transactions_this_month", 0) > 0
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.tourist_taxfree_jpk_v7_marking","package":"jdg.taxfree.hyper","priority":1438,"_routing":"WARNING","_routing_reason":"TAX FREE — JPK_V7 oznaczenie TF","_legal_basis":"Art. 99 VAT + rozporządzenie JPK_V7","_warnings":["TAX FREE — w JPK_V7 oznacz sprzedaż TAX FREE kodem 'TF' (dostawa towarów poza terytorium kraju dla podróżnych)"]} {
    object.get(input.invoice, "taxfree_transactions_this_month", 0) > 0
    object.get(input.jdg_entrepreneur, "jpk_v7_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.tourist_taxfree_vat_deduction_input","package":"jdg.taxfree.hyper","priority":1439,"_routing":"","_routing_reason":"TAX FREE — VAT naliczony od zakupów","_legal_basis":"Art. 86 VAT","_warnings":["TAX FREE — sprzedaż TAX FREE traktowana jak eksport (stawka 0%). VAT naliczony od towarów sprzedanych turystom — pełne prawo do odliczenia"]} {
    object.get(input.invoice, "taxfree_export_treated", false) == true
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.tourist_taxfree_aggregate_dashboard","package":"jdg.taxfree.hyper","priority":1440,"_routing":"","_routing_reason":"TAX FREE — agregacja roczna","_legal_basis":"Art. 126-130 VAT","_warnings":["TAX FREE — podsumowanie roczne: liczba transakcji, łączny VAT zwrócony, kraje turystów, % sprzedaży detalicznej objętej TAX FREE"]} {
    object.get(input.jdg_entrepreneur, "year_end", false) == true
    object.get(input.invoice, "taxfree_transactions_annual", 0) > 0
}
