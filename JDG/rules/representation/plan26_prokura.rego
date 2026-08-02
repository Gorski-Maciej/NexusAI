# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.representation
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Updated: 2026-08-02 (P26 R8 — przebudowa triggery prokury)
# Rules: 4
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.representation
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.representation.no_match","package":"jdg.representation","priority":99999}

# jdg.representation.prokura_self_employed — Prokura samoistna — pełnomocnik działa samodzielnie
decide := {
    "matched":true,"rule_id":"jdg.representation.prokura_self_employed",
    "package":"jdg.representation","priority":1205,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","prokura_type":"SELF_EMPLOYED",
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason":"Prokura samoistna — pełnomocnik działa samodzielnie",
    "_legal_basis":"Art. 109¹-109⁸ KC",
    "_warnings":["Prokura samoistna — jeden prokurent może działać samodzielnie. Wymagany wpis w CEIDG (jeśli JDG) lub KRS."]
} {
    object.get(input.jdg_entrepreneur, "prokura_type", "") == "SELF_EMPLOYED"
    object.get(input.jdg_entrepreneur, "prokura_registered", false) == true
}

# jdg.representation.prokura_joint — Prokura łączna — współdziałanie 2+ prokurentów
else := {
    "matched":true,"rule_id":"jdg.representation.prokura_joint",
    "package":"jdg.representation","priority":1206,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","prokura_type":"JOINT",
    "_routing":"",
    "_routing_reason":"Prokura łączna — wymaga współdziałania prokurentów",
    "_legal_basis":"Art. 109⁴ KC",
    "_warnings":["Prokura łączna — wymaga współdziałania co najmniej 2 prokurentów. Sprawdź czy wszyscy są ujawnieni w rejestrze."]
} {
    object.get(input.jdg_entrepreneur, "prokura_type", "") == "JOINT"
    object.get(input.jdg_entrepreneur, "prokura_registered", false) == true
}

# jdg.representation.prokura_branch — Prokura oddziałowa — ograniczona do oddziału
else := {
    "matched":true,"rule_id":"jdg.representation.prokura_branch",
    "package":"jdg.representation","priority":1207,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","prokura_type":"BRANCH",
    "_routing":"WARNING",
    "_routing_reason":"Prokura oddziałowa — ograniczona do oddziału przedsiębiorstwa",
    "_legal_basis":"Art. 109⁵ KC",
    "_warnings":["Prokura oddziałowa — ograniczona do jednego oddziału. Prokurent nie może reprezentować w sprawach poza oddziałem."]
} {
    object.get(input.jdg_entrepreneur, "prokura_type", "") == "BRANCH"
    object.get(input.jdg_entrepreneur, "prokura_registered", false) == true
}

# jdg.representation.prokura_unregistered — Prokura niezarejestrowana — nieskuteczna!
else := {
    "matched":true,"rule_id":"jdg.representation.prokura_unregistered",
    "package":"jdg.representation","priority":1208,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","prokura_registered":false,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Prokura niezarejestrowana — nieskuteczna wobec osób trzecich",
    "_legal_basis":"Art. 109¹-109⁸ KC",
    "_warnings":["Prokura niewpisana w CEIDG/KRS — nieskuteczna! Prokurent nie może reprezentować przedsiębiorcy. Wpisz niezwłocznie."]
} {
    object.get(input.jdg_entrepreneur, "prokura_requested", false) == true
    object.get(input.jdg_entrepreneur, "prokura_registered", false) == false
}
