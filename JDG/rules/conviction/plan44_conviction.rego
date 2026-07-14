# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.conviction (Doc 44: P1960-P1965)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 6
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.conviction
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.conviction.no_match","package":"jdg.conviction","priority":99999}

# jdg.conviction.professional_consequences — P1960: Skazanie KKS — zakaz działalności, utrata licencji
decide :=   {"matched":true,"rule_id":"jdg.conviction.professional_consequences","package":"jdg.conviction","priority":1960,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Skazanie KKS — zakaz prowadzenia działalności, wykluczenie z PZP, utrata licencji","_legal_basis":"Art. 41 KK, Art. 108 PZP","_warnings":["Skazanie za KKS — zakaz prowadzenia działalności, wykluczenie z zamówień publicznych!"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}

# jdg.conviction.banking_access — P1961: Wpływ skazania na bankowość — AML/CFT, wypowiedzenie umowy
else :=   {"matched":true,"rule_id":"jdg.conviction.banking_access","package":"jdg.conviction","priority":1961,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Skazanie KKS — banki mogą wypowiedzieć umowę (AML), trudności z kredytem","_legal_basis":"Ustawa o AML/CFT","_warnings":["Skazanie za KKS — ryzyko wypowiedzenia umowy rachunku przez bank (AML/CFT)"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}

# jdg.conviction.tax_office_relations — P1962: Zaostrzony nadzór US — lista ostrzeżeń, częstsze kontrole
else :=   {"matched":true,"rule_id":"jdg.conviction.tax_office_relations","package":"jdg.conviction","priority":1962,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zaostrzony nadzór US — wpis na listę ostrzeżeń, częstsze kontrole, monitoring","_legal_basis":"Art. 119b Ordynacji podatkowej","_warnings":["Po skazaniu KKS — zaostrzony nadzór US, wpis na listę ostrzeżeń publicznych"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}

# jdg.conviction.business_partner_impact — P1963: Wpływ na kontrahentów — solidarna odp. za VAT
else :=   {"matched":true,"rule_id":"jdg.conviction.business_partner_impact","package":"jdg.conviction","priority":1963,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Skazanie KKS — utrata zaufania kontrahentów, odpowiedzialność solidarna za VAT","_legal_basis":"Art. 105a VAT","_warnings":["Skazanie KKS — kontrahenci mogą ponosić solidarną odpowiedzialność za Twój VAT"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}

# jdg.conviction.rehabilitation — P1964: Zatarcie skazania — 3 lata (wykroczenia) / 5 lat (przestępstwa)
else :=   {"matched":true,"rule_id":"jdg.conviction.rehabilitation","package":"jdg.conviction","priority":1964,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zatarcie skazania — 3 lata dla wykroczeń, 5 lat dla przestępstw skarbowych","_legal_basis":"Art. 19 KKS","_warnings":["Skazanie KKS — zatarcie po 3 latach (wykroczenia) / 5 latach (przestępstwa) od wykonania kary"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}

# jdg.conviction.tax_arrears_enforcement — P1965: Egzekucja zaległości — cały majątek
else :=   {"matched":true,"rule_id":"jdg.conviction.tax_arrears_enforcement","package":"jdg.conviction","priority":1965,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Egzekucja zaległości — odpowiedzialność całym majątkiem, zakaz ukrywania","_legal_basis":"Art. 36 Ordynacji podatkowej","_warnings":["Po skazaniu KKS — egzekucja zaległości z całego majątku, zakaz ukrywania!"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
