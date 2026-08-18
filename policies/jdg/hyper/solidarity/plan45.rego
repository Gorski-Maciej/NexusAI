# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 11

package jdg.hyper.solidarity

default decide := {"matched":false,"rule_id":"jdg.hyper.solidarity.no_match","package":"jdg.hyper.solidarity","priority":99999}

# jdg.hyper.solidarity.solidarity.levy.income.ip_box — Źródło
decide :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.income.ip_box","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.), Art. 30ca ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Dochód z IP Box (5%) wlicza się do podstawy daniny"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.income.capital_gains — Źródło
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.income.capital_gains","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Dochody kapitałowe (19%) wlicza się do podstawy daniny"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.income.foreign — Źródło
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.income.foreign","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.), Art. 27 ust. 8 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Dochody zagraniczne wlicza się do podstawy daniny"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.zus.social.exclusion — Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.zus.social.exclusion","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Składki ZUS społeczne pomniejszają dochód dla celów daniny"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.zus.health.no_exclusion — Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.zus.health.no_exclusion","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.exemption.metoda_wylaczenia — Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.exemption.metoda_wylaczenia","_legal_basis":"Art. 30h ust. 3 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Dochody zwolnione metodą wyłączenia z progresją nie wlicza się"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.exemption.foreign_tax_credit — Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.exemption.foreign_tax_credit","_legal_basis":"Art. 30h ust. 3 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Dochody zwolnione metodą wyłączenia z progresją nie wlicza się"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.spouse.individual_calculation — Indywidualnie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.spouse.individual_calculation","_legal_basis":"Art. 30h ust. 5 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Każdy małżonek oblicza daninę osobno"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.spouse.no_income_transfer — Indywidualnie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.spouse.no_income_transfer","_legal_basis":"Art. 30h ust. 5 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Każdy małżonek oblicza daninę osobno"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.payment.deadline.april30 — Termin
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.payment.deadline.april30","_legal_basis":"Art. 30h ust. 6 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Zapłata daniny do 30 kwietnia następnego roku"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.payment.no_advances — Termin
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.payment.no_advances","_legal_basis":"Art. 30h ust. 6 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
