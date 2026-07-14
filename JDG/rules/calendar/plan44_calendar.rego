# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.calendar (Doc 44: P1910-P1915)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 6
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.calendar
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.calendar.no_match","package":"jdg.calendar","priority":99999}

# jdg.calendar.master_payment — P1910: Główny kalendarz płatności — VAT, PIT, ZUS, PCC, danina
decide :=   {"matched":true,"rule_id":"jdg.calendar.master_payment","package":"jdg.calendar","priority":1910,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Główny kalendarz — VAT 25., PIT zaliczka 20., ZUS 10/15/20., PCC 14.","_legal_basis":"Art. 103 VAT, Art. 44 PIT, SUS, PCC","_warnings":["Kalendarz płatności: VAT do 25., PIT do 20., ZUS do 10/15/20. — sprawdź terminy!"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}

# jdg.calendar.by_tax_form — P1911: Kalendarz dynamiczny wg formy opodatkowania
else :=   {"matched":true,"rule_id":"jdg.calendar.by_tax_form","package":"jdg.calendar","priority":1911,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Kalendarz dynamiczny — skala (mies.), liniowy (mies.), ryczałt (mies./kwart.)","_legal_basis":"Art. 44 PIT","_warnings":["Terminy zależą od formy opodatkowania — ryczałt: możliwe rozliczenie kwartalne"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}

# jdg.calendar.weekend_shift — P1912: Automatyczne przesuwanie terminów z weekendów i świąt
else :=   {"matched":true,"rule_id":"jdg.calendar.weekend_shift","package":"jdg.calendar","priority":1912,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przesuwanie terminów — weekendy/święta → następny dzień roboczy","_legal_basis":"Art. 12 § 5 Ordynacji podatkowej","_warnings":["Termin w weekend/święto — przesunięty na następny dzień roboczy"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}

# jdg.calendar.overdue_alerts — P1913: Alerty przed terminem — 7 dni, 3 dni, 1 dzień
else :=   {"matched":true,"rule_id":"jdg.calendar.overdue_alerts","package":"jdg.calendar","priority":1913,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Alerty: 7 dni, 3 dni, 1 dzień przed terminem — eskalacja po terminie","_legal_basis":"Art. 12 Ordynacji podatkowej","_warnings":["Nadchodzi termin płatności — 7 dni / 3 dni / 1 dzień. Po terminie: odsetki!"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}

# jdg.calendar.annual_forecast — P1914: Prognoza rocznych płatności — planowanie finansowe
else :=   {"matched":true,"rule_id":"jdg.calendar.annual_forecast","package":"jdg.calendar","priority":1914,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prognoza roczna — na podstawie danych historycznych","_legal_basis":"Ogólne","_warnings":["Prognoza płatności podatkowych i ZUS na podstawie danych historycznych"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}

# jdg.calendar.zus_deadlines — P1915: Kalendarz terminów ZUS — 10./15./20. wg liczby pracowników
else :=   {"matched":true,"rule_id":"jdg.calendar.zus_deadlines","package":"jdg.calendar","priority":1915,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"ZUS: 10. (JDG bez pracowników), 15. (do 5 prac.), 20. (5+ prac.)","_legal_basis":"Art. 47 SUS","_warnings":["Termin ZUS zależy od liczby pracowników: 10./15./20. dnia miesiąca"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}
