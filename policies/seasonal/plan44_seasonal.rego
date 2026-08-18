# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.seasonal (Doc 44: P1950-P1956)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 7
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.seasonal
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.seasonal.no_match","package":"jdg.seasonal","priority":99999}

# jdg.seasonal.identification — P1950: Identyfikacja działalności sezonowej — przychody ≤9 mies.
decide :=   {"matched":true,"rule_id":"jdg.seasonal.identification","package":"jdg.seasonal","priority":1950,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"SEASONAL","_routing":"","_routing_reason":"Identyfikacja sezonowa — przychody w ≤9 miesiącach, wzorzec powtarzalny","_legal_basis":"Ogólne","_warnings":["Działalność sezonowa — rozważ strategię zawieszenia poza sezonem"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}

# jdg.seasonal.suspension_vs_closure — P1951: Zawieszenie sezonowe vs zamknięcie
else :=   {"matched":true,"rule_id":"jdg.seasonal.suspension_vs_closure","package":"jdg.seasonal","priority":1951,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"SUSPENDED_SEASONAL","_routing":"WARNING","_routing_reason":"Zawieszenie sezonowe zachowuje NIP, zamknięcie wymaga ponownej rejestracji","_legal_basis":"Art. 25 PP","_warnings":["Zawieś JDG sezonowo — zachowasz NIP. Zamknięcie = ponowna rejestracja CEIDG"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}

# jdg.seasonal.zus_strategy — P1952: Strategia ZUS sezonowa — zawieszenie vs kontynuacja
else :=   {"matched":true,"rule_id":"jdg.seasonal.zus_strategy","package":"jdg.seasonal","priority":1952,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"ZUS sezonowy — zawieszenie=brak składek (zdrowotna nadal)","_legal_basis":"Art. 36a SUS","_warnings":["Zawieszenie sezonowe — brak składek społecznych, zdrowotna nadal wymagana"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}

# jdg.seasonal.pit_advances — P1953: Zaliczki uproszczone — optymalna strategia dla sezonowej
else :=   {"matched":true,"rule_id":"jdg.seasonal.pit_advances","package":"jdg.seasonal","priority":1953,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaliczki uproszczone — stała kwota miesięczna, roczne rozliczenie","_legal_basis":"Art. 44 ust. 6b PIT","_warnings":["JDG sezonowa — rozważ zaliczki uproszczone dla stałej miesięcznej wpłaty"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}

# jdg.seasonal.vat_consequences — P1954: VAT sezonowy — deklaracje zerowe w zawieszeniu
else :=   {"matched":true,"rule_id":"jdg.seasonal.vat_consequences","package":"jdg.seasonal","priority":1954,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"VAT w sezonie martwym — deklaracje zerowe, zwrot VAT kosztów stałych","_legal_basis":"Art. 99 VAT","_warnings":["W zawieszeniu sezonowym składaj deklaracje zerowe VAT — zwrot VAT od kosztów stałych"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}

# jdg.seasonal.loss_carry_forward — P1955: Rozliczenie straty — 5 lat
else :=   {"matched":true,"rule_id":"jdg.seasonal.loss_carry_forward","package":"jdg.seasonal","priority":1955,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Strata sezonowa — odliczenie w ciągu 5 kolejnych lat","_legal_basis":"Art. 9 ust. 3 PIT","_warnings":["Strata z sezonu — możesz odliczyć od dochodu w ciągu 5 kolejnych lat"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}

# jdg.seasonal.annual_reconciliation — P1956: Roczne rozliczenie — dochód za okres aktywny
else :=   {"matched":true,"rule_id":"jdg.seasonal.annual_reconciliation","package":"jdg.seasonal","priority":1956,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rozliczenie roczne — dochód za okres aktywny, składki za miesiące aktywne","_legal_basis":"Art. 45 PIT","_warnings":["Rozliczenie roczne — dochód tylko za okres aktywny, składki proporcjonalnie"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}
