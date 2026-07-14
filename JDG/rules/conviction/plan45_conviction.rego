# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.conviction hyper-granularity (Doc 45: R1546-R1575)
# Atom rules: KKS conviction impacts, rehabilitation, enforcement
# Rules: 30 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.conviction.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.conviction.hyper.no_match","package":"jdg.conviction.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.conviction.hyper.business_ban_art41kk","package":"jdg.conviction.hyper","priority":1546,"_routing":"BLOCK_AND_ALERT","_routing_reason":"KKS: zakaz prowadzenia działalności","_legal_basis":"Art. 41 KK","_warnings":["Skazanie KKS — zakaz prowadzenia działalności gospodarczej!"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.public_procurement_exclusion","package":"jdg.conviction.hyper","priority":1548,"_routing":"BLOCK_AND_ALERT","_routing_reason":"KKS: wykluczenie z PZP","_legal_basis":"Art. 108 PZP","_warnings":["Skazanie KKS — wykluczenie z zamówień publicznych na 5 lat"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.bank_account_termination","package":"jdg.conviction.hyper","priority":1551,"_routing":"WARNING","_routing_reason":"KKS: bank może wypowiedzieć umowę","_legal_basis":"Art. 56 Prawo bankowe, AML","_warnings":["Skazanie KKS — bank może wypowiedzieć umowę rachunku"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.enhanced_audit_scrutiny","package":"jdg.conviction.hyper","priority":1556,"_routing":"WARNING","_routing_reason":"KKS: zaostrzony nadzór US","_legal_basis":"Art. 119b OP","_warnings":["Skazanie KKS — zaostrzony nadzór US, wpis na listę ostrzeżeń"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.rehabilitation_misdemeanor_3y","package":"jdg.conviction.hyper","priority":1566,"_routing":"","_routing_reason":"Zatarcie: wykroczenie 3 lata","_legal_basis":"Art. 21 KKS","_warnings":["Wykroczenie KKS — zatarcie skazania po 3 latach od wykonania kary"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.rehabilitation_crime_5y","package":"jdg.conviction.hyper","priority":1567,"_routing":"","_routing_reason":"Zatarcie: przestępstwo 5 lat","_legal_basis":"Art. 21 KKS","_warnings":["Przestępstwo KKS — zatarcie skazania po 5 latach od wykonania kary"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.full_asset_enforcement","package":"jdg.conviction.hyper","priority":1571,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Egzekucja: cały majątek","_legal_basis":"Art. 26 OP","_warnings":["Skazanie KKS — egzekucja zaległości z całego majątku!"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
