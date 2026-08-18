# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.mdr hyper-granularity (Doc 45: R1001-R1042)
# Hallmark-specific atom rules — MDR/DAC6 decomposition
# Rules: 42 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.mdr.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.mdr.hyper.no_match","package":"jdg.mdr.hyper","priority":99999}

# ══ Hallmark A: Ogólne cechy rozpoznawcze (R1001-R1010) ══
decide := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_a1_confidentiality","package":"jdg.mdr.hyper","priority":1001,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark A1: klauzula poufności","_legal_basis":"Art. 86a § 1 pkt 1 OP","_warnings":["MDR A1 — klauzula poufności uniemożliwiająca ujawnienie schematu innym doradcom"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
    object.get(input.invoice, "confidentiality_clause", false) == true
    object.get(input.invoice, "cross_border_element", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_a2_success_fee","package":"jdg.mdr.hyper","priority":1002,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark A2: success fee","_legal_basis":"Art. 86a § 1 pkt 2 OP","_warnings":["MDR A2 — wynagrodzenie promotora uzależnione od korzyści podatkowej"]} {
    object.get(input.invoice, "success_fee_structure", false) == true
    object.get(input.invoice, "tax_benefit_amount", 0) > 0
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_a3_standardized","package":"jdg.mdr.hyper","priority":1003,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark A3: schemat z półki","_legal_basis":"Art. 86a § 1 pkt 3 OP","_warnings":["MDR A3 — wystandaryzowany schemat dla wielu klientów"]} {
    object.get(input.invoice, "standardized_documentation", false) == true
    object.get(input.invoice, "scheme_reusable", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_a4_loss_buying","package":"jdg.mdr.hyper","priority":1004,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark A4: nabycie spółki ze stratą","_legal_basis":"Art. 86a OP","_warnings":["MDR A4 — nabycie spółki ze stratą głównie dla korzyści podatkowej"]} {
    object.get(input.invoice, "loss_buying_scheme", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_a5_conversion_income","package":"jdg.mdr.hyper","priority":1005,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark A5: konwersja dochodu","_legal_basis":"Art. 86a OP","_warnings":["MDR A5 — konwersja dochodu do kategorii niżej opodatkowanej"]} {
    object.get(input.invoice, "tax_benefit_type", "") == "CONVERSION"
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_a6_circular","package":"jdg.mdr.hyper","priority":1006,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark A6: transakcje okrężne","_legal_basis":"Art. 86a OP","_warnings":["MDR A6 — transakcje okrężne bez treści ekonomicznej"]} {
    object.get(input.invoice, "circular_flow", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_a7_double_deduction","package":"jdg.mdr.hyper","priority":1007,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark A7: podwójne odliczenie","_legal_basis":"Art. 86a OP","_warnings":["MDR A7 — ten sam koszt odliczany w dwóch jurysdykcjach"]} {
    object.get(input.invoice, "double_deduction_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_a8_double_depreciation","package":"jdg.mdr.hyper","priority":1008,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark A8: podwójna amortyzacja","_legal_basis":"Art. 86a OP","_warnings":["MDR A8 — ten sam składnik amortyzowany w dwóch krajach"]} {
    object.get(input.invoice, "double_depreciation", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_a9_double_tax_relief","package":"jdg.mdr.hyper","priority":1009,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark A9: podwójne zwolnienie","_legal_basis":"Art. 86a OP","_warnings":["MDR A9 — podwójne zwolnienie podatkowe dla tego samego dochodu"]} {
    object.get(input.invoice, "double_tax_relief", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_a10_main_benefit_test","package":"jdg.mdr.hyper","priority":1010,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR MBT — test głównej korzyści","_legal_basis":"Art. 86a § 2 OP","_warnings":["MDR MBT — czy główną korzyścią transakcji jest korzyść podatkowa?"]} {
    object.get(input.invoice, "mbt_required", false) == true
}

# ══ Hallmark B: Specyficzne cechy (R1011-R1018) ══
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_b1_loss_utilization_group","package":"jdg.mdr.hyper","priority":1011,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark B1: wykorzystanie straty w grupie","_legal_basis":"Art. 86b OP","_warnings":["MDR B1 — transfer straty do podmiotu z zyskiem w grupie"]} {
    object.get(input.invoice, "loss_utilization_group", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_b2_income_conversion_capital","package":"jdg.mdr.hyper","priority":1012,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark B2: konwersja dochodu w kapitałowy","_legal_basis":"Art. 86b OP","_warnings":["MDR B2 — konwersja dochodu bieżącego w kapitałowy"]} {
    object.get(input.invoice, "income_converted_to_capital", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_b3_deduction_cross_border","package":"jdg.mdr.hyper","priority":1013,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark B3: przesunięcie odliczenia transgranicznie","_legal_basis":"Art. 86b OP","_warnings":["MDR B3 — transgraniczne przesunięcie odliczenia do jurysdykcji z wyższą stawką"]} {
    object.get(input.invoice, "deduction_cross_border", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_b4_tax_haven","package":"jdg.mdr.hyper","priority":1014,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark B4: transfer do/z raju podatkowego","_legal_basis":"Art. 86b OP","_warnings":["MDR B4 — transfer aktywów do/z raju podatkowego"]} {
    object.get(input.invoice, "tax_haven_involved", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_b5_non_arm_length","package":"jdg.mdr.hyper","priority":1015,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark B5: płatności nierynkowe","_legal_basis":"Art. 86b OP","_warnings":["MDR B5 — płatności nierynkowe wykorzystujące preferencyjny reżim"]} {
    object.get(input.invoice, "non_arm_length_payment", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_b6_deductible_cross_border","package":"jdg.mdr.hyper","priority":1016,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark B6: odliczenie w dwóch krajach","_legal_basis":"Art. 86b OP","_warnings":["MDR B6 — odliczenie tej samej płatności w dwóch krajach"]} {
    object.get(input.invoice, "deductible_in_two_countries", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_b7_non_taxation_claim","package":"jdg.mdr.hyper","priority":1017,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark B7: roszczenie o nieopodatkowanie","_legal_basis":"Art. 86b OP","_warnings":["MDR B7 — roszczenie o nieopodatkowanie w żadnej jurysdykcji"]} {
    object.get(input.invoice, "non_taxation_claim", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_b8_hybrid_mismatch","package":"jdg.mdr.hyper","priority":1018,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR Hallmark B8: rozbieżność hybrydowa","_legal_basis":"Art. 86b OP","_warnings":["MDR B8 — rozbieżność kwalifikacji prawnej między jurysdykcjami"]} {
    object.get(input.invoice, "hybrid_mismatch_detected", false) == true
}

# ══ Hallmark C: Transgraniczne specyficzne (R1019-R1026) ══
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_c1_strategic_acquisition","package":"jdg.mdr.hyper","priority":1019,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR C1: nabycie ze stratą >50%","_legal_basis":"Art. 86d OP","_warnings":["MDR C1 — strategiczne nabycie podmiotu ze stratą"]} {
    object.get(input.invoice, "strategic_acquisition_with_loss", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_c2_income_reclassification","package":"jdg.mdr.hyper","priority":1020,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR C2: zmiana klasyfikacji dochodu","_legal_basis":"Art. 86d OP","_warnings":["MDR C2 — zmiana klasyfikacji dochodu dla niższego WHT"]} {
    object.get(input.invoice, "income_reclassification", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_c3_circular_roundtrip","package":"jdg.mdr.hyper","priority":1021,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR C3: round-trip z podmiotem pośredniczącym","_legal_basis":"Art. 86d OP","_warnings":["MDR C3 — transakcja okrężna z podmiotem bez funkcji ekonomicznej"]} {
    object.get(input.invoice, "round_trip_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_c4_cross_border_deduction","package":"jdg.mdr.hyper","priority":1022,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR C4: odliczenie transgraniczne z podmiotem powiązanym","_legal_basis":"Art. 86d OP","_warnings":["MDR C4 — transgraniczne odliczenie związane z podmiotem w kraju niskopodatkowym"]} {
    object.get(input.invoice, "cross_border_deduction_related", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_c5_tp_gap","package":"jdg.mdr.hyper","priority":1023,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR C5: wykorzystanie różnic TP","_legal_basis":"Art. 86d OP","_warnings":["MDR C5 — różnice w metodologii TP między jurysdykcjami"]} {
    object.get(input.invoice, "tp_methodology_gap", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_c6_ip_hard_to_value","package":"jdg.mdr.hyper","priority":1024,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR C6: IP trudne do wyceny","_legal_basis":"Art. 86d OP","_warnings":["MDR C6 — transfer trudnych do wyceny wartości niematerialnych"]} {
    object.get(input.invoice, "ip_transfer_htvi", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_c7_business_restructuring","package":"jdg.mdr.hyper","priority":1025,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR C7: restrukturyzacja biznesu","_legal_basis":"Art. 86d OP","_warnings":["MDR C7 — restrukturyzacja z przeniesieniem funkcji/ryzyk/aktywów transgranicznie"]} {
    object.get(input.invoice, "business_restructuring_tp", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_c8_safe_harbour_manipulation","package":"jdg.mdr.hyper","priority":1026,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR C8: sztuczne safe harbour","_legal_basis":"Art. 86d OP","_warnings":["MDR C8 — sztuczne spełnienie warunków safe harbour dla uniknięcia TP"]} {
    object.get(input.invoice, "safe_harbour_manipulation", false) == true
}

# ══ Hallmark D (R1027-R1028) ══
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_d1_ip_transfer_cross_border","package":"jdg.mdr.hyper","priority":1027,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR D1: transfer IP transgranicznie","_legal_basis":"Art. 86e OP","_warnings":["MDR D1 — transfer wartości niematerialnych bez odpowiedniego wynagrodzenia"]} {
    object.get(input.invoice, "ip_transfer_no_remuneration", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_d2_business_transfer","package":"jdg.mdr.hyper","priority":1028,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR D2: transfer funkcji zmieniający EBIT","_legal_basis":"Art. 86e OP","_warnings":["MDR D2 — transfer funkcji/ryzyk/aktywów zmieniający EBIT o >50%"]} {
    object.get(input.invoice, "business_transfer_ebit_impact", false) == true
}

# ══ Hallmark E: CRS/DAC (R1029-R1032) ══
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_e1_crs_bypass","package":"jdg.mdr.hyper","priority":1029,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR E1: obchodzenie CRS/DAC","_legal_basis":"Art. 86f OP","_warnings":["MDR E1 — obchodzenie automatycznej wymiany informacji"]} {
    object.get(input.invoice, "crs_bypass_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_e2_ubo_concealment","package":"jdg.mdr.hyper","priority":1030,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR E2: ukrywanie beneficial owner","_legal_basis":"Art. 86f OP","_warnings":["MDR E2 — ukrywanie rzeczywistego beneficjenta przez łańcuch podmiotów"]} {
    object.get(input.invoice, "ubo_concealed", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_e3_trust_foundation","package":"jdg.mdr.hyper","priority":1031,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR E3: trusty/fundacje nieprzejrzyste","_legal_basis":"Art. 86f OP","_warnings":["MDR E3 — wykorzystanie trustów/fundacji w jurysdykcjach nieprzejrzystych"]} {
    object.get(input.invoice, "trust_foundation_opaque", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.hallmark_e4_nominee_director","package":"jdg.mdr.hyper","priority":1032,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR E4: podstawieni dyrektorzy","_legal_basis":"Art. 86f OP","_warnings":["MDR E4 — wykorzystanie podstawionych dyrektorów (nominee directors)"]} {
    object.get(input.invoice, "nominee_director", false) == true
}

# ══ Obowiązki, terminy, sankcje (R1033-R1042) ══
else := {"matched":true,"rule_id":"jdg.mdr.hyper.obligation_promoter_reporting","package":"jdg.mdr.hyper","priority":1033,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR-3: promotor — 30 dni od udostępnienia","_legal_basis":"Art. 86f § 1 OP","_warnings":["Promotor — złóż MDR-3 w 30 dni od udostępnienia schematu!"]} {
    object.get(input.mdr, "role", "") == "PROMOTER"
    object.get(input.mdr, "mdr3_submitted", false) == false
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.obligation_user_reporting","package":"jdg.mdr.hyper","priority":1034,"_routing":"TRIAGE_QUEUE","_routing_reason":"MDR-3: korzystający — 30 dni od pierwszej czynności","_legal_basis":"Art. 86f § 1 OP","_warnings":["Korzystający — złóż MDR-3 w 30 dni od pierwszej czynności!"]} {
    object.get(input.mdr, "role", "") == "USER"
    object.get(input.mdr, "mdr3_submitted", false) == false
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.obligation_legal_privilege","package":"jdg.mdr.hyper","priority":1035,"_routing":"","_routing_reason":"MDR: privilege — adwokat/radca → obowiązek na kliencie","_legal_basis":"Art. 86a OP","_warnings":["Adwokat/radca — privilege; obowiązek MDR przechodzi na korzystającego"]} {
    object.get(input.mdr, "legal_professional_privilege", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.obligation_quarterly_mdr4","package":"jdg.mdr.hyper","priority":1036,"_routing":"WARNING","_routing_reason":"MDR-4: kwartalne zestawienie","_legal_basis":"Art. 86k OP","_warnings":["MDR-4 — złóż kwartalne zestawienie do końca miesiąca po kwartale"]} {
    object.get(input.mdr, "mdr4_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.deadline_30days_scheme_available","package":"jdg.mdr.hyper","priority":1037,"_routing":"WARNING","_routing_reason":"Termin: 30 dni od udostępnienia schematu","_legal_basis":"Art. 86f OP","_warnings":["30 dni od udostępnienia schematu na złożenie MDR-3"]} {
    object.get(input.mdr, "scheme_available_date", 0) > 0
    object.get(input.mdr, "mdr3_submitted", false) == false
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.deadline_30days_first_implementation","package":"jdg.mdr.hyper","priority":1038,"_routing":"WARNING","_routing_reason":"Termin: 30 dni od pierwszej czynności","_legal_basis":"Art. 86f OP","_warnings":["30 dni od pierwszej czynności wykonawczej na złożenie MDR-3"]} {
    object.get(input.mdr, "first_implementation_date", 0) > 0
    object.get(input.mdr, "mdr3_submitted", false) == false
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.sanction_admin_5m","package":"jdg.mdr.hyper","priority":1039,"_routing":"BLOCK_AND_ALERT","_routing_reason":"MDR sankcja: kara do 5M PLN","_legal_basis":"Art. 86o OP","_warnings":["MDR — kara administracyjna do 5 000 000 PLN za brak zgłoszenia!"]} {
    object.get(input.document, "mdr_overdue", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.sanction_kks_art54_56","package":"jdg.mdr.hyper","priority":1040,"_routing":"BLOCK_AND_ALERT","_routing_reason":"MDR sankcja: KKS Art. 54-56","_legal_basis":"Art. 54-56 KKS","_warnings":["MDR — odpowiedzialność karna-skarbowa za niezgłoszenie schematu!"]} {
    object.get(input.document, "mdr_kks_risk", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.retention_6years","package":"jdg.mdr.hyper","priority":1041,"_routing":"","_routing_reason":"MDR retencja: 6 lat","_legal_basis":"Art. 86m OP","_warnings":["MDR — przechowuj dokumentację schematu przez 6 lat"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.mdr.hyper.aggregate_annual_risk","package":"jdg.mdr.hyper","priority":1042,"_routing":"WARNING","_routing_reason":"MDR: roczny wskaźnik ryzyka","_legal_basis":"Art. 86a-86o OP","_warnings":["Agregacja ryzyka MDR — skumulowany wskaźnik dla JDG"]} {
    object.get(input.mdr, "year_end", false) == true
}
