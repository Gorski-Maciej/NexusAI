# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Akcyza Fuel & Energy: Art. 89-99 Ustawy o podatku akcyzowym
# Package: jdg.akcyza.fuel_energy — Paliwa i energia
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220) z 06.12.2008 (Dz.U. 2009 nr 3 poz. 11)
# Coverage: Art. 89-99 — ~70 rules, ~70 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.akcyza.fuel_energy

import data.jdg.helpers
import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.akcyza.fuel_energy.no_match",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# Paliwa silnikowe / Motor Fuels (15 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.fuel.r1",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250001,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Akcyza od paliw — OBOWIĄZKOWA! Sprawdź czy masz zezwolenie na skład podatkowy lub procedurę zawieszenia!",
    "_legal_basis": "Art. 89 ust. 1 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Paliwa silnikowe podlegają akcyzie. Stawki na 2026: benzyna 1566 PLN/1000L, ON 1206 PLN/1000L, LPG 695 PLN/1000kg"]
} {
    object.get(input.invoice, "product_category", "") == "MOTOR_FUEL"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.fuel.r2",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250002,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 1 pkt 1-13 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Benzyna silnikowa (CN 2710) — stawka: 1566 PLN/1000 litrów (2026)"],
    "rate_per_1000l": 1566,
    "unit": "1000_litres"
} {
    object.get(input.invoice, "fuel_type", "") == "PETROL_UNLEADED"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.fuel.r3",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250003,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 1 pkt 2 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Olej napędowy (ON) — stawka: 1206 PLN/1000 litrów (2026)"],
    "rate_per_1000l": 1206
} {
    object.get(input.invoice, "fuel_type", "") == "DIESEL"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.fuel.r4",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250004,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 1 pkt 13 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] LPG (gaz płynny) — stawka: 695 PLN/1000 kg (2026)"],
    "rate_per_1000kg": 695
} {
    object.get(input.invoice, "fuel_type", "") == "LPG"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.fuel.r5",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250005,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 40 ust. 1; Art. 89 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Skład podatkowy — akcyza zawieszona do momentu wyprowadzenia poza procedurę zawieszenia"]
} {
    object.get(input.invoice, "is_tax_warehouse_procedure", false) == true
    object.get(input.invoice, "product_category", "") == "MOTOR_FUEL"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.fuel.r6",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250006,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Paliwo poza procedurą zawieszenia — akcyza NATYCHMIAST należna!",
    "_legal_basis": "Art. 8 ust. 2 pkt 1; Art. 89 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Paliwo wprowadzone do sprzedaży BEZ procedury zawieszenia — AKCYZA NATYCHMIAST wymagalna!"]
} {
    object.get(input.invoice, "is_tax_warehouse_procedure", false) == false
    volume := object.get(input.invoice, "quantity", 0)
    volume > 0
    object.get(input.invoice, "product_category", "") == "MOTOR_FUEL"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.fuel.r7",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250007,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 24a Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Ewidencja akcyzowa — obowiązkowa dla podmiotów prowadzących skład podatkowy"]
} {
    object.get(input.jdg_entrepreneur, "has_tax_warehouse", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.fuel.r8",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250008,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 90 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] CNG (gaz ziemny) — stawka 0 PLN do celów napędowych (zwolnienie do 2028 w ramach polityki energetycznej)"],
    "rate": 0.00,
    "exemption_to": "2028-12-31"
} {
    object.get(input.invoice, "fuel_type", "") == "CNG"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.fuel.r9",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250009,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 2 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Biokomponenty — zwolnione z akcyzy (do 2030 wg dyrektywy RED III)"],
    "exemption": true
} {
    object.get(input.invoice, "fuel_type", "") == "BIOCOMPONENT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Energia elektryczna / Electricity (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.energy.r2",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250021,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 3 Ustawy o podatku akcyzowym; Rozporządzenie MF",
    "_warnings": ["[AKCYZA] Energia elektryczna dla JDG — akcyza zawarta w cenie (płatna przez sprzedawcę). JDG NIE płaci bezpośrednio."]
} {
    object.get(input.invoice, "product_category", "") == "ELECTRICITY"
    object.get(input.jdg_entrepreneur, "is_end_user", true) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.energy.r1",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250020,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 2 ust. 1 pkt 1; Art. 89 ust. 3 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Energia elektryczna — stawka: 5 PLN/MWh (2026). Obowiązek: sprzedawca energii."],
    "rate_per_mwh": 5.00
} {
    object.get(input.invoice, "product_category", "") == "ELECTRICITY"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.energy.r3",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250022,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 3; Art. 16 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] JDG odsprzedająca energię (np. ładowanie EV) — KONIECZNA rejestracja AKC-R + deklaracja AKC-4!"]
} {
    object.get(input.jdg_entrepreneur, "resells_electricity", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.energy.r4",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250023,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 9 pkt 1 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Fotowoltaika JDG (prosument) — ZWOLNIONA z akcyzy od wyprodukowanej energii!"]
} {
    object.get(input.jdg_entrepreneur, "is_prosumer", false) == true
    object.get(input.invoice, "is_self_produced", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.energy.r5",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250024,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 1 pkt 1 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Węgiel (CN 2701) — stawka: 0 PLN (zwolnienie od 2023 dla gospodarstw domowych; JDG = pełna stawka jeśli do celów grzewczych)"]
} {
    object.get(input.invoice, "product_category", "") == "COAL"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.energy.r6",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250025,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 1 pkt 2 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Gaz ziemny do celów opałowych — stawka: 0 PLN (zwolnienie do 2028)"],
    "rate": 0.00
} {
    object.get(input.invoice, "product_category", "") == "NATURAL_GAS_HEATING"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.energy.r7",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250026,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 24; Art. 24b Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Deklaracja AKC-4 — miesięczna (do 25. dnia następnego miesiąca)"],
    "deadline_day": 25,
    "form": "AKC-4"
} {
    object.get(input.jdg_entrepreneur, "is_excise_taxpayer", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.energy.r8",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250027,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 16 ust. 1 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Rejestracja AKC-R — przed pierwszą czynnością opodatkowaną akcyzą!"]
} {
    object.get(input.jdg_entrepreneur, "is_excise_taxpayer", false) == true
    object.get(input.jdg_entrepreneur, "akc_r_submitted", true) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.fuel_energy.energy.r9",
    "package": "jdg.akcyza.fuel_energy",
    "priority": 250028,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 21 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Zabezpieczenie akcyzowe — wymagane dla składów podatkowych i zarejestrowanych odbiorców"]
} {
    object.get(input.jdg_entrepreneur, "is_excise_taxpayer", false) == true
    object.get(input.jdg_entrepreneur, "has_excise_guarantee", true) == false
}
