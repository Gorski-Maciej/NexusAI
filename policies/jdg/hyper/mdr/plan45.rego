# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 38

package jdg.hyper.mdr

default decide := {"matched":false,"rule_id":"jdg.hyper.mdr.no_match","package":"jdg.hyper.mdr","priority":99999}

# jdg.hyper.mdr.mdr.hallmark.a4.loss_buying — A4
decide :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a4.loss_buying","_legal_basis":"Art. 86a § 1 pkt 4 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR A4 — nabycie spółki ze stratą dla korzyści podatkowej"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a5.conversion_income — A5
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a5.conversion_income","_legal_basis":"Art. 86a § 1 pkt 5 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR A5 — konwersja dochodu do kategorii niżej opodatkowanej"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a6.circular_transactions — A6
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a6.circular_transactions","_legal_basis":"Art. 86a § 1 pkt 6 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR A6 — transakcje okrężne bez treści ekonomicznej"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a7.double_deduction — A7
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a7.double_deduction","_legal_basis":"Art. 86a § 1 pkt 7 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR A7 — ten sam koszt odliczany w dwóch jurysdykcjach"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a8.double_depreciation — A8
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a8.double_depreciation","_legal_basis":"Art. 86a § 1 pkt 8 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR A8 — ten sam składnik amortyzowany w dwóch krajach"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a9.double_tax_relief — A9
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a9.double_tax_relief","_legal_basis":"Art. 86a § 1 pkt 9 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR A9 — podwójne zwolnienie podatkowe dla tego samego dochodu"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a10.main_benefit_test — MBT
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a10.main_benefit_test","_legal_basis":"Art. 86a § 1 pkt 10 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR A10 — Test głównej korzyści: czy głównym celem lub jednym z głównych celów jest korzyść podatkowa?"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b1.loss_utilization_group — B1
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b1.loss_utilization_group","_legal_basis":"Art. 86a § 1 pkt 11 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR B1 — wykorzystanie straty w grupie"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b2.income_conversion_capital — B2
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b2.income_conversion_capital","_legal_basis":"Art. 86a § 1 pkt 12 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR B2 — konwersja dochodu bieżącego w kapitałowy"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b3.deduction_cross_border — B3
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b3.deduction_cross_border","_legal_basis":"Art. 86a § 1 pkt 13 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR B3 — transgraniczne przesunięcie odliczenia"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b4.tax_haven_transfer — B4
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b4.tax_haven_transfer","_legal_basis":"Art. 86a § 1 pkt 14 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR B4 — transfer aktywów do/z raju podatkowego"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b5.non_arm_length_payment — B5
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b5.non_arm_length_payment","_legal_basis":"Art. 86a § 1 pkt 15 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR B5 — płatności nierynkowe"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b6.deductible_cross_border — B6
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b6.deductible_cross_border","_legal_basis":"Art. 86a § 1 pkt 16 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR B6 — odliczenie tej samej płatności w dwóch krajach"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b7.non_taxation_claim — B7
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b7.non_taxation_claim","_legal_basis":"Art. 86a § 1 pkt 17 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR B7 — roszczenie o nieopodatkowanie w żadnej jurysdykcji"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b8.hybrid_mismatch — B8
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b8.hybrid_mismatch","_legal_basis":"Art. 86a § 1 pkt 18 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR B8 — rozbieżność kwalifikacji prawnej (hybryda)"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c1.strategic_acquisition — C1
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c1.strategic_acquisition","_legal_basis":"Art. 86a § 1 pkt 19 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR C1 — nabycie podmiotu ze stratą >50% wartości"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c2.income_reclassification — C2
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c2.income_reclassification","_legal_basis":"Art. 86a § 1 pkt 20 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR C2 — zmiana klasyfikacji dochodu dla niższego WHT"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c3.circular_flow_round_trip — C3
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c3.circular_flow_round_trip","_legal_basis":"Art. 86a § 1 pkt 21 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR C3 — transakcja okrężna z podmiotem pośredniczącym"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c4.cross_border_deduction — C4
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c4.cross_border_deduction","_legal_basis":"Art. 86a § 1 pkt 22 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR C4 — transgraniczne odliczenie z podmiotem powiązanym"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c5.transfer_pricing_gap — C5
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c5.transfer_pricing_gap","_legal_basis":"Art. 86a § 1 pkt 23 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR C5 — wykorzystanie różnic w metodologii TP"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c6.ip_transfer_hard_to_value — C6
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c6.ip_transfer_hard_to_value","_legal_basis":"Art. 86a § 1 pkt 24 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR C6 — transfer trudnych do wyceny wartości niematerialnych"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c7.business_restructuring — C7
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c7.business_restructuring","_legal_basis":"Art. 86a § 1 pkt 25 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR C7 — restrukturyzacja biznesu transgranicznie"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c8.safe_harbour_manipulation — C8
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c8.safe_harbour_manipulation","_legal_basis":"Art. 86a § 1 pkt 26 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR C8 — sztuczne spełnienie warunków safe harbour"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.d1.ip_transfer_cross_border — D1
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.d1.ip_transfer_cross_border","_legal_basis":"Art. 86a § 1 pkt 27 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR D1 — transgraniczny transfer IP bez wynagrodzenia"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.d2.business_transfer — D2
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.d2.business_transfer","_legal_basis":"Art. 86a § 1 pkt 28 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR D2 — transfer funkcji/ryzyk/aktywów >50% EBIT"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.e1.automatic_exchange_bypass — E1
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.e1.automatic_exchange_bypass","_legal_basis":"Art. 86a § 1 pkt 29 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR E1 — obchodzenie automatycznej wymiany informacji"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.e2.ubo_concealment — E2
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.e2.ubo_concealment","_legal_basis":"Art. 86a § 1 pkt 30 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR E2 — ukrywanie rzeczywistego beneficjenta"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.e3.trust_foundation_chain — E3
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.e3.trust_foundation_chain","_legal_basis":"Art. 86a § 1 pkt 31 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR E3 — wykorzystanie trustów/fundacji w jurysdykcjach nieprzejrzystych"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.e4.nominee_director — E4
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.e4.nominee_director","_legal_basis":"Art. 86a § 1 pkt 32 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR E4 — wykorzystanie podstawionych dyrektorów"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.obligation.user_reporting — Obowiązek
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.obligation.user_reporting","_legal_basis":"Art. 86b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Korzystający → MDR-3 w 30 dni od pierwszej czynności"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.obligation.legal_professional_privilege — Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.obligation.legal_professional_privilege","_legal_basis":"Art. 86c Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Adwokat/radca → zwolnienie; obowiązek przeniesiony na korzystającego"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.obligation.quarterly_mdr4_report — Raport
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.obligation.quarterly_mdr4_report","_legal_basis":"Art. 86f Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["MDR-4 — kwartalne zestawienie schematów"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.deadline.30_days_from_scheme_available — Termin
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.deadline.30_days_from_scheme_available","_legal_basis":"Art. 86b § 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["30 dni od udostępnienia schematu"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.deadline.30_days_from_first_implementation — Termin
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.deadline.30_days_from_first_implementation","_legal_basis":"Art. 86b § 2 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["30 dni od pierwszej czynności wykonawczej"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.sanction.administrative_penalty_5m — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.sanction.administrative_penalty_5m","_legal_basis":"Art. 86o Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Kara administracyjna do 5 000 000 PLN za brak MDR"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.sanction.kks_liability — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.sanction.kks_liability","_legal_basis":"Art. 54-56 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Odpowiedzialność KKS za niezgłoszenie schematu MDR"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.retention.scheme_documentation_6_years — Retencja
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.retention.scheme_documentation_6_years","_legal_basis":"Art. 86m Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Przechowywanie dokumentacji MDR przez 6 lat"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.aggregate.annual_risk_score — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.aggregate.annual_risk_score","_legal_basis":"Art. 86a-86o Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Skumulowany wskaźnik ryzyka MDR — wszystkie hallmarki A1-E4 w jednym profilu"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}
