# ------------------------------------------------------------------------------
# NexusAI JDG Policies — jdg.accounting — Plan 23: Leasing
# Generated from Plan OPA specifications: 2026-07-13 14:05:06, Rules: 5
# ------------------------------------------------------------------------------
package jdg.accounting
import future.keywords.in
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.accounting.plan23.no_match","package":"jdg.accounting","priority":99999}

# jdg.accounting.operating_lease_kup — Leasing operacyjny — cała rata KUP
decide :=   {"matched":true,"rule_id":"jdg.accounting.operating_lease_kup","package":"jdg.accounting","priority":860,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Leasing operacyjny — cała rata KUP","_legal_basis":"Art. 23b PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") in {"OPERATING_LEASE", "FINANCIAL_LEASE"}
}

# jdg.accounting.financial_lease_interest_kup — Leasing finansowy — KUP tylko odsetki
else :=   {"matched":true,"rule_id":"jdg.accounting.financial_lease_interest_kup","package":"jdg.accounting","priority":862,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Leasing finansowy — KUP tylko odsetki","_legal_basis":"Art. 23f PIT","_warnings":["Leasing finansowy — KUP tylko odsetki, kapitał przez amortyzację"]} {
    object.get(input.invoice, "expense_type", "") in {"OPERATING_LEASE", "FINANCIAL_LEASE"}
}

# jdg.accounting.car_lease_limit_150k — Limit 150k PLN dla KUP z leasingu aut osobowych
else :=   {"matched":true,"rule_id":"jdg.accounting.car_lease_limit_150k","package":"jdg.accounting","priority":864,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Limit 150k PLN dla KUP z leasingu aut osobowych","_legal_basis":"Art. 23a pkt 47a PIT","_warnings":["Auto >150k — KUP z rat leasingowych limitowany proporcjonalnie"]} {
    object.get(input.invoice, "expense_type", "") in {"OPERATING_LEASE", "FINANCIAL_LEASE"}
}

# jdg.accounting.consumer_lease_kup — Leasing konsumencki — limit 20% KUP bez kilometrówki
else :=   {"matched":true,"rule_id":"jdg.accounting.consumer_lease_kup","package":"jdg.accounting","priority":866,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Leasing konsumencki — limit 20% KUP bez kilometrówki","_legal_basis":"Art. 23 ust. 1 pkt 46 PIT","_warnings":["Leasing konsumencki — KUP limitowany do 20% bez ewidencji przebiegu"]} {
    object.get(input.invoice, "expense_type", "") in {"OPERATING_LEASE", "FINANCIAL_LEASE"}
}

# jdg.accounting.lease_classification_test — Test klasyfikacji leasingu — 40% normatywnego okresu
else :=   {"matched":true,"rule_id":"jdg.accounting.lease_classification_test","package":"jdg.accounting","priority":868,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Test klasyfikacji leasingu — 40% normatywnego okresu","_legal_basis":"Art. 23b ust. 1 PIT","_warnings":["Umowa <40% okresu — klasyfikuj jako leasing finansowy"]} {
    object.get(input.invoice, "expense_type", "") in {"OPERATING_LEASE", "FINANCIAL_LEASE"}
}
