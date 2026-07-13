# Generated from Plan OPA 33 — Micro-rules for health
# 2026-07-13 14:58:41
# Rules: 40 (new, deduplicated)

package jdg.micro.health

default decide := {"matched":false,"rule_id":"jdg.micro.health.no_match","package":"jdg.micro.health","priority":99999}

# jdg.health.annual.r1 — `health_annual_base_total_revenue`: Roczna podstawa = suma przychodow z JDG w roku podatkowym → Obliczenie
decide :=   {"matched":true,"rule_id":"jdg.health.annual.r1","package":"jdg.micro.health","priority":4400,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczna podstawa = suma przychodow z JDG w roku podatkowym","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r10 — `health_annual_underpayment_interest`: Niedoplata -> odsetki od terminu zaplaty → Sankcja
else :=   {"matched":true,"rule_id":"jdg.health.annual.r10","package":"jdg.micro.health","priority":4401,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niedoplata -> odsetki od terminu zaplaty","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r11 — `health_annual_overpayment_refund_or_credit`: Nadplata -> zwrot lub zaliczenie na poczet nastepnych skladek → Zwrot
else :=   {"matched":true,"rule_id":"jdg.health.annual.r11","package":"jdg.micro.health","priority":4402,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadplata -> zwrot lub zaliczenie na poczet nastepnych skladek","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r12 — `health_annual_base_negative_income`: Jesli przychod < 0 (strata) -> podstawa = minimalne wynagrodzenie → Minimum
else :=   {"matched":true,"rule_id":"jdg.health.annual.r12","package":"jdg.micro.health","priority":4403,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Jesli przychod < 0 (strata) -> podstawa = minimalne wynagrodzenie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r13 — `health_annual_business_loss_effect`: Strata -> skladka zdrowotna od minimalnego wynagrodzenia → Minimum
else :=   {"matched":true,"rule_id":"jdg.health.annual.r13","package":"jdg.micro.health","priority":4404,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Strata -> skladka zdrowotna od minimalnego wynagrodzenia","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r14 — `health_annual_base_zero_if_no_business`: Jesli JDG zawieszona i bez przychodu -> 0 podstawy → Zerowa
else :=   {"matched":true,"rule_id":"jdg.health.annual.r14","package":"jdg.micro.health","priority":4405,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Jesli JDG zawieszona i bez przychodu -> 0 podstawy","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r15 — `health_annual_health_insurance_zus_declaration`: Skladka zdrowotna wykazywana w ZUS DRA miesiecznie → Deklaracja ZUS
else :=   {"matched":true,"rule_id":"jdg.health.annual.r15","package":"jdg.micro.health","priority":4406,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladka zdrowotna wykazywana w ZUS DRA miesiecznie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r2 — `health_annual_contribution_9pct`: Skladka roczna = 9% x roczna podstawa (skala/ryczalt/karta) → Obliczenie
else :=   {"matched":true,"rule_id":"jdg.health.annual.r2","package":"jdg.micro.health","priority":4407,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladka roczna = 9% x roczna podstawa (skala/ryczalt/karta)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r3 — `health_annual_contribution_4_9pct`: Skladka roczna = 4.9% x roczna podstawa (liniowy) → Obliczenie
else :=   {"matched":true,"rule_id":"jdg.health.annual.r3","package":"jdg.micro.health","priority":4408,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladka roczna = 4.9% x roczna podstawa (liniowy)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r4 — `health_annual_deduction_scale`: Odliczenie roczne: 7.75% x podstawa (skala) → Odliczenie
else :=   {"matched":true,"rule_id":"jdg.health.annual.r4","package":"jdg.micro.health","priority":4409,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie roczne: 7.75% x podstawa (skala)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r5 — `health_annual_deduction_linear`: Odliczenie roczne: 4.9% x podstawa (liniowy) → Odliczenie
else :=   {"matched":true,"rule_id":"jdg.health.annual.r5","package":"jdg.micro.health","priority":4410,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie roczne: 4.9% x podstawa (liniowy)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r6 — `health_annual_deduction_lump_50pct`: Odliczenie roczne: 50% x zaplacona (ryczalt) → Odliczenie
else :=   {"matched":true,"rule_id":"jdg.health.annual.r6","package":"jdg.micro.health","priority":4411,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie roczne: 50% x zaplacona (ryczalt)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r7 — `health_annual_deduction_limit_health`: Odliczenie ograniczone do wysokosci zaplaconej skladki → Limit
else :=   {"matched":true,"rule_id":"jdg.health.annual.r7","package":"jdg.micro.health","priority":4412,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie ograniczone do wysokosci zaplaconej skladki","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r8 — `health_annual_deduction_no_carry_forward`: Niewykorzystane odliczenie przepada (nie przechodzi na nastepny rok) → Przepadniecie
else :=   {"matched":true,"rule_id":"jdg.health.annual.r8","package":"jdg.micro.health","priority":4413,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niewykorzystane odliczenie przepada (nie przechodzi na nastepny rok)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.annual.r9 — `health_annual_return_PIT_36_or_36L`: Korekta roczna skladki w zeznaniu PIT-36/PIT-36L/PIT-28 → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.health.annual.r9","package":"jdg.micro.health","priority":4414,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta roczna skladki w zeznaniu PIT-36/PIT-36L/PIT-28","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r1 — `health_insurance_obligation_jdg`: Osoba prowadzaca JDG podlega obowiazkowo ubezpieczeniu zdrowotnemu → Obowiazkowe
else :=   {"matched":true,"rule_id":"jdg.health.r1","package":"jdg.micro.health","priority":4415,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osoba prowadzaca JDG podlega obowiazkowo ubezpieczeniu zdrowotnemu","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r10 — `health_insurance_base_no_income_month`: Miesiac bez przychodu -> podstawa minimalna (minimalne wynagrodzenie) → Minimum
else :=   {"matched":true,"rule_id":"jdg.health.r10","package":"jdg.micro.health","priority":4416,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Miesiac bez przychodu -> podstawa minimalna (minimalne wynagrodzenie)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r11 — `health_insurance_base_sickness_absence`: Chorobowe: podstawa = 0 (jesli JDG nie osiaga przychodu z JDG) → Zerowa
else :=   {"matched":true,"rule_id":"jdg.health.r11","package":"jdg.micro.health","priority":4417,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Chorobowe: podstawa = 0 (jesli JDG nie osiaga przychodu z JDG)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r12 — `health_insurance_base_maternity_leave`: Urlopy macierzynskie: podstawa = 0 (jesli JDG nie osiaga przychodu) → Zerowa
else :=   {"matched":true,"rule_id":"jdg.health.r12","package":"jdg.micro.health","priority":4418,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Urlopy macierzynskie: podstawa = 0 (jesli JDG nie osiaga przychodu)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r13 — `health_insurance_base_declared_higher_optional`: JDG moze zadeklarowac wyzsza podstawe (opcjonalnie) → Opcja
else :=   {"matched":true,"rule_id":"jdg.health.r13","package":"jdg.micro.health","priority":4419,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG moze zadeklarowac wyzsza podstawe (opcjonalnie)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r14 — `health_insurance_base_sickness_benefit_addition`: Zasilek chorobowy/macierzynski dolicza sie do przychodu dla podstawy → Doliczenie
else :=   {"matched":true,"rule_id":"jdg.health.r14","package":"jdg.micro.health","priority":4420,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zasilek chorobowy/macierzynski dolicza sie do przychodu dla podstawy","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r15 — `health_insurance_base_annual_reconciliation`: Roczna korekta podstawy skladki zdrowotnej w zeznaniu rocznym → Korekta
else :=   {"matched":true,"rule_id":"jdg.health.r15","package":"jdg.micro.health","priority":4421,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczna korekta podstawy skladki zdrowotnej w zeznaniu rocznym","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r2 — `health_insurance_scope_healthcare`: Ubezpieczenie daje prawo do swiadczen opieki zdrowotnej (NFZ) → Zakres
else :=   {"matched":true,"rule_id":"jdg.health.r2","package":"jdg.micro.health","priority":4422,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ubezpieczenie daje prawo do swiadczen opieki zdrowotnej (NFZ)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r3 — `health_insurance_multiple_titles`: JDG na etacie -> ubezpieczenie z etatu, JDG plci dodatkowa skladke → Wielotytulowosc
else :=   {"matched":true,"rule_id":"jdg.health.r3","package":"jdg.micro.health","priority":4423,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG na etacie -> ubezpieczenie z etatu, JDG plci dodatkowa skladke","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r4 — `health_insurance_base_scale_linear_100pct`: Skala/liniowy: podstawa = 100% przychodu z poprzedniego miesiaca (nie < minimalna) → Podstawa
else :=   {"matched":true,"rule_id":"jdg.health.r4","package":"jdg.micro.health","priority":4424,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skala/liniowy: podstawa = 100% przychodu z poprzedniego miesiaca (nie < minimalna)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r5 — `health_insurance_base_lump_sum_60pct`: Ryczalt: podstawa = 60% przychodu z poprzedniego miesiaca (nie < minimalna) → Podstawa
else :=   {"matched":true,"rule_id":"jdg.health.r5","package":"jdg.micro.health","priority":4425,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczalt: podstawa = 60% przychodu z poprzedniego miesiaca (nie < minimalna)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r6 — `health_insurance_base_minimum`: Minimalna podstawa: minimalne wynagrodzenie (2025: ~4 666 PLN) → Minimum
else :=   {"matched":true,"rule_id":"jdg.health.r6","package":"jdg.micro.health","priority":4426,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Minimalna podstawa: minimalne wynagrodzenie (2025: ~4 666 PLN)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r7 — `health_insurance_base_maximum`: Maksymalna podstawa: brak (od 2022) → Maksimum
else :=   {"matched":true,"rule_id":"jdg.health.r7","package":"jdg.micro.health","priority":4427,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Maksymalna podstawa: brak (od 2022)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r8 — `health_insurance_base_new_business_first_year`: Nowa JDG: podstawa = 75% minimalnego wynagrodzenia przez pierwszy rok → Obnizona
else :=   {"matched":true,"rule_id":"jdg.health.r8","package":"jdg.micro.health","priority":4428,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nowa JDG: podstawa = 75% minimalnego wynagrodzenia przez pierwszy rok","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.r9 — `health_insurance_base_after_suspension`: Wznowienie po zawieszeniu: podstawa = 75% minimalnego wynagrodzenia przez 6 miesiecy → Obnizona
else :=   {"matched":true,"rule_id":"jdg.health.r9","package":"jdg.micro.health","priority":4429,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wznowienie po zawieszeniu: podstawa = 75% minimalnego wynagrodzenia przez 6 miesiecy","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.rate.r1 — `health_rate_scale_9pct`: Skala podatkowa → 9% podstawy
else :=   {"matched":true,"rule_id":"jdg.health.rate.r1","package":"jdg.micro.health","priority":4430,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skala podatkowa","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.rate.r10 — `health_rate_linear_effective_4_9`: Efektywny koszt: 4.9% (liniowy, po zmianach) → Koszt 4.9%
else :=   {"matched":true,"rule_id":"jdg.health.rate.r10","package":"jdg.micro.health","priority":4431,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Efektywny koszt: 4.9% (liniowy, po zmianach)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.rate.r2 — `health_rate_linear_4_9pct`: 4.9% podstawy (odlicza sie od PIT) → 4.9% podstawy
else :=   {"matched":true,"rule_id":"jdg.health.rate.r2","package":"jdg.micro.health","priority":4432,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"4.9% podstawy (odlicza sie od PIT)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.rate.r3 — `health_rate_lump_sum_9pct`: Ryczałt → 9% podstawy
else :=   {"matched":true,"rule_id":"jdg.health.rate.r3","package":"jdg.micro.health","priority":4433,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczałt","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.rate.r4 — `health_rate_tax_card_9pct`: Karta podatkowa → 9% podstawy
else :=   {"matched":true,"rule_id":"jdg.health.rate.r4","package":"jdg.micro.health","priority":4434,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Karta podatkowa","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.rate.r5 — `health_rate_scale_deduction_7_75`: Odliczenie: 7.75% x podstawa (skala) → Obniza podatek
else :=   {"matched":true,"rule_id":"jdg.health.rate.r5","package":"jdg.micro.health","priority":4435,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie: 7.75% x podstawa (skala)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.rate.r6 — `health_rate_linear_deduction_full_4_9`: Odliczenie: 4.9% x podstawa (liniowy) → Obniza podatek
else :=   {"matched":true,"rule_id":"jdg.health.rate.r6","package":"jdg.micro.health","priority":4436,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie: 4.9% x podstawa (liniowy)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.rate.r7 — `health_rate_lump_deduction_50pct`: Odliczenie: 50% x zaplacona (ryczalt) → Obniza podatek
else :=   {"matched":true,"rule_id":"jdg.health.rate.r7","package":"jdg.micro.health","priority":4437,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie: 50% x zaplacona (ryczalt)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.rate.r8 — `health_rate_scale_effective_cost`: Efektywny koszt: 9% - 7.75% = 1.25% podstawy (skala) → Koszt efektywny
else :=   {"matched":true,"rule_id":"jdg.health.rate.r8","package":"jdg.micro.health","priority":4438,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Efektywny koszt: 9% - 7.75% = 1.25% podstawy (skala)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.health.rate.r9 — `health_rate_linear_effective_0pct`: Efektywny koszt: 4.9% - 4.9% = 0% (liniowy, do 2022) → Koszt 0%
else :=   {"matched":true,"rule_id":"jdg.health.rate.r9","package":"jdg.micro.health","priority":4439,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Efektywny koszt: 4.9% - 4.9% = 0% (liniowy, do 2022)","_legal_basis":"","_warnings":[]} {
    true
}
