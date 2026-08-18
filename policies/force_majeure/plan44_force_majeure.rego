# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.force_majeure (Doc 44: P1850-P1857)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 8
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.force_majeure
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.force_majeure.no_match","package":"jdg.force_majeure","priority":99999}

# jdg.force_majeure.tax_relief — Ulgi podatkowe w przypadku siły wyższej
decide :=   {"matched":true,"rule_id":"jdg.force_majeure.tax_relief","package":"jdg.force_majeure","priority":1850,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulgi podatkowe w przypadku siły wyższej","_legal_basis":"Art. 67a-67e Ordynacji podatkowej","_warnings":["Siła wyższa — sprawdź dostępne ulgi podatkowe"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.force_majeure.zus_relief — P1851: Ulgi ZUS (niepodatkowe)
else :=   {"matched":true,"rule_id":"jdg.force_majeure.zus_relief","package":"jdg.force_majeure","priority":1851,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulgi ZUS w przypadku siły wyższej","_legal_basis":"Art. 28-29 SUS","_warnings":["Siła wyższa — możliwe odroczenie/umorzenie składek ZUS"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
    object.get(input.jdg_entrepreneur, "tax_relief_applied", true) == false
}

# jdg.force_majeure.documentation_loss — P1852: Utrata dokumentacji — procedura odtworzenia
else :=   {"matched":true,"rule_id":"jdg.force_majeure.documentation_loss","package":"jdg.force_majeure","priority":1852,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Utrata dokumentacji przez siłę wyższą — procedura odtworzenia","_legal_basis":"Art. 86 § 2 Ordynacji podatkowej","_warnings":["Utrata dokumentów — zgłoś do US w 7 dni!"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
    object.get(input.jdg_entrepreneur, "documentation_lost", false) == true
}

# jdg.force_majeure.insurance_cover — P1853: Ubezpieczenie od siły wyższej — KUP, odszkodowanie
else :=   {"matched":true,"rule_id":"jdg.force_majeure.insurance_cover","package":"jdg.force_majeure","priority":1853,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ubezpieczenie business interruption — składka KUP, odszkodowanie przychodem","_legal_basis":"Art. 22 PIT, Art. 14 PIT","_warnings":["Składka ubezpieczeniowa KUP. Odszkodowanie = przychód podatkowy"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
    object.get(input.jdg_entrepreneur, "insurance_cover_active", false) == true
}

# jdg.force_majeure.business_suspension_auto — P1854: Zawieszenie (po ubezpieczeniu)
else :=   {"matched":true,"rule_id":"jdg.force_majeure.business_suspension_auto","package":"jdg.force_majeure","priority":1854,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"SUSPENDED_FORCE_MAJEURE","_routing":"TRIAGE_QUEUE","_routing_reason":"Automatyczne zawieszenie — skutki podatkowe i ZUS","_legal_basis":"Art. 25 PP","_warnings":["Zawieszenie z powodu siły wyższej — brak składek ZUS (zdrowotna nadal)"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
    object.get(input.jdg_entrepreneur, "insurance_checked", false) == true
}

# jdg.force_majeure.tax_loss_carry_back — P1855: Rozliczenie straty w latach wstecz (spec-regulacje)
else :=   {"matched":true,"rule_id":"jdg.force_majeure.tax_loss_carry_back","package":"jdg.force_majeure","priority":1855,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Strata z siły wyższej — możliwość odliczenia w latach wstecz","_legal_basis":"Spec-regulacje MF (np. COVID-19)","_warnings":["Strata z siły wyższej — sprawdź czy możliwe odliczenie od dochodu lat poprzednich"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
    object.get(input.jdg_entrepreneur, "tax_loss_carry_back_checked", false) == false
}

# jdg.force_majeure.emergency_deadlines — P1856: Specjalne przedłużenia terminów przez MF
else :=   {"matched":true,"rule_id":"jdg.force_majeure.emergency_deadlines","package":"jdg.force_majeure","priority":1856,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Specjalne przedłużenia terminów ogłaszane przez MF","_legal_basis":"Rozporządzenia MF","_warnings":["Siła wyższa — sprawdź komunikaty MF o przedłużeniu terminów"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
    object.get(input.jdg_entrepreneur, "emergency_deadlines_checked", false) == false
}

# jdg.force_majeure.documentation_preservation — P1857: Zabezpieczenie dokumentacji przed siłą wyższą
else :=   {"matched":true,"rule_id":"jdg.force_majeure.documentation_preservation","package":"jdg.force_majeure","priority":1857,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zabezpieczenie dokumentacji — backupy cyfrowe, kopie off-site","_legal_basis":"Art. 86 Ordynacji podatkowej","_warnings":["Zabezpiecz dokumentację — backupy cyfrowe, kopie off-site na wypadek siły wyższej"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
    object.get(input.jdg_entrepreneur, "documentation_preserved", false) == false
}
