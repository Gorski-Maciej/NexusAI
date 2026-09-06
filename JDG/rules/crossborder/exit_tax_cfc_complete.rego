# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Exit Tax + CFC: Art. 30da, 30f PIT
# Package: jdg.exit_tax_cfc — Exit Tax i Controlled Foreign Corporation
# Version: 1.0.0 — Q1 2027 Enterprise Expansion (P28 Grand Finale)
# Legal basis: Art. 30da, 30f PIT; Dyrektywa ATAD (UE) 2016/1164
# Coverage: ~80 rules, ~80 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.exit_tax_cfc

import data.jdg.helpers
import future.keywords.if

decide := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r1",
    "package": "jdg.exit_tax_cfc",
    "priority": 360001,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "EXIT TAX — przeniesienie aktywów za granicę = opodatkowanie 19% niezrealizowanych zysków!",
    "_legal_basis": "Art. 30da ust. 1 PIT",
    "_warnings": ["[EXIT TAX] Przeniesienie aktywów JDG za granicę → 19% od wartości rynkowej pomniejszonej o wartość podatkową!"],
    "rate": 0.19
} {
    object.get(input.jdg_entrepreneur, "transferring_assets_abroad", false) == true
    market_value := object.get(input.invoice, "asset_market_value", 0)
    tax_value := object.get(input.invoice, "asset_tax_value", 0)
    market_value > tax_value
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r2",
    "package": "jdg.exit_tax_cfc",
    "priority": 360002,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30da ust. 2 PIT",
    "_warnings": ["[EXIT TAX] Przeniesienie rezydencji podatkowej za granicę = Exit Tax od wszystkich aktywów!"]
} {
    object.get(input.jdg_entrepreneur, "changing_tax_residence", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r3",
    "package": "jdg.exit_tax_cfc",
    "priority": 360003,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30da ust. 3 PIT (próg wartościowy)",
    "_warnings": ["[EXIT TAX] Exit Tax NIE dotyczy jeśli wartość rynkowa aktywów < 4 000 000 PLN!"],
    "exemption_threshold_pln": 4000000
} {
    market_value := object.get(input.invoice, "total_assets_market_value", 0)
    market_value < 4000000
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r4",
    "package": "jdg.exit_tax_cfc",
    "priority": 360004,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30da ust. 8 PIT (odroczenie)",
    "_warnings": ["[EXIT TAX] Odroczenie Exit Tax — możliwe na 5 lat (rozłożenie na raty) przy przeniesieniu do UE/EOG"]
} {
    object.get(input.invoice, "exit_tax_deferral_requested", false) == true
    object.get(input.invoice, "destination_in_eea", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r5",
    "package": "jdg.exit_tax_cfc",
    "priority": 360005,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30da ust. 5 PIT",
    "_warnings": ["[EXIT TAX] Podstawa opodatkowania = wartość rynkowa − wartość podatkowa (niezamortyzowana)"]
} {
    market_value := object.get(input.invoice, "asset_market_value", 0)
    tax_value := object.get(input.invoice, "asset_tax_value", 0)
    market_value > 0
    tax_value > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r1",
    "package": "jdg.exit_tax_cfc",
    "priority": 360020,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CFC — kontrola >50% w spółce zagranicznej w raju podatkowym (niski CIT <14.25%)!",
    "_legal_basis": "Art. 30f ust. 1-3 PIT",
    "_warnings": ["[CFC] JDG posiada >50% udziałów w zagranicznej spółce z CIT <14.25% → CFC! Opodatkowanie 19%!"],
    "control_threshold": 0.50,
    "low_tax_threshold": 0.1425,
    "rate": 0.19
} {
    stake := object.get(input.jdg_entrepreneur, "foreign_company_stake_pct", 0)
    foreign_tax := object.get(input.jdg_entrepreneur, "foreign_cit_rate", 1.0)
    stake > 50
    foreign_tax < 0.1425
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r2",
    "package": "jdg.exit_tax_cfc",
    "priority": 360021,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30f ust. 3 pkt 1 PIT",
    "_warnings": ["[CFC] CFC — obowiązek raportowania CIT-CFC + opodatkowanie 19% od dochodu CFC proporcjonalnie do udziału"]
} {
    object.get(input.jdg_entrepreneur, "has_cfc", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r3",
    "package": "jdg.exit_tax_cfc",
    "priority": 360022,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30f ust. 4 PIT (próg dochodów pasywnych)",
    "_warnings": ["[CFC] Alternatywnie: CFC jeśli >33% przychodów to dochody pasywne (dywidendy, odsetki, należności licencyjne)"],
    "passive_income_threshold": 0.33
} {
    passive_income_pct := object.get(input.jdg_entrepreneur, "cfc_passive_income_pct", 0)
    passive_income_pct > 33
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r4",
    "package": "jdg.exit_tax_cfc",
    "priority": 360023,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30f ust. 18 PIT (zwolnienie dla rzeczywistej działalności)",
    "_warnings": ["[CFC] ZWOLNIENIE: CFC z rzeczywistą działalnością gospodarczą w UE/EOG — NIE podlega CFC!"]
} {
    object.get(input.jdg_entrepreneur, "cfc_substantial_activity_eea", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.wht.r2",
    "package": "jdg.exit_tax_cfc",
    "priority": 360043,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "WHT >2M PLN BEZ certyfikatu rezydencji — obowiązek 20% lub opinia o stosowaniu preferencji!",
    "_legal_basis": "Art. 26 ust. 2e CIT",
    "_warnings": ["[WHT] Płatność >2M PLN bez certyfikatu rezydencji — pobierz WHT 20% lub złóż WH-OSC!"]
} {
    annual_foreign_payments := object.get(input.jdg_entrepreneur, "annual_foreign_payments_pln", 0)
    has_certificate := object.get(input.jdg_entrepreneur, "has_tax_residence_certificates", false)
    annual_foreign_payments > 2000000
    not has_certificate
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.wht.r1",
    "package": "jdg.exit_tax_cfc",
    "priority": 360040,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1 CIT (WHT — podatek u źródła)",
    "_warnings": ["[WHT] Płatność za granicę > 2M PLN rocznie — OBOWIĄZEK pobrania WHT 20% (lub stawka UPO)!"],
    "threshold_pln": 2000000,
    "standard_rate": 0.20
} {
    annual_foreign_payments := object.get(input.jdg_entrepreneur, "annual_foreign_payments_pln", 0)
    annual_foreign_payments > 2000000
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.pe.r1",
    "package": "jdg.exit_tax_cfc",
    "priority": 360041,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5 UPO (OECD Model); Art. 4a pkt 11 PIT",
    "_warnings": ["[PE] Stała placówka (PE) za granicą — dochody PE opodatkowane w kraju położenia PE (z wyłączeniem w PL)"]
} {
    object.get(input.jdg_entrepreneur, "has_permanent_establishment_abroad", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.treaty.r1",
    "package": "jdg.exit_tax_cfc",
    "priority": 360042,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30a ust. 2 PIT; właściwa UPO",
    "_warnings": ["[UPO] Certyfikat rezydencji kontrahenta — OBOWIĄZKOWY dla zastosowania stawki UPO zamiast 20% WHT!"]
} {
    object.get(input.invoice, "has_tax_residence_certificate", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r5",
    "package": "jdg.exit_tax_cfc",
    "priority": 360024,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30f ust. 5 PIT",
    "_warnings": ["[CFC] Termin: CIT-CFC do końca 9. miesiąca następnego roku podatkowego CFC"]
} {
    object.get(input, "cfc_deadline_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# WHT / PE — Cross-border expansion (5 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.cfc.r6",
    "package": "jdg.exit_tax_cfc",
    "priority": 360044,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30f ust. 2 PIT",
    "_warnings": ["[CFC] CFC — JDG opodatkowuje dochody CFC proporcjonalnie do udziału (19% PIT)"]
} {
    object.get(input.jdg_entrepreneur, "has_cfc", false) == true
}
else := {
    "matched": true,
    "rule_id": "jdg.exit_tax_cfc.exit_tax.r6",
    "package": "jdg.exit_tax_cfc",
    "priority": 360006,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30da ust. 9 PIT",
    "_warnings": ["[EXIT TAX] Deklaracja o wysokości dochodu z Exit Tax — do 7 dnia miesiąca następującego po miesiącu przeniesienia"]
} {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# CFC — Art. 30f PIT (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

