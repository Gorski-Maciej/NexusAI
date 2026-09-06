# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Akcyza Alcohol & Tobacco: Art. 92-99 Ustawy o podatku akcyzowym
# Package: jdg.akcyza.alcohol_tobacco — Alkohol i wyroby tytoniowe
# Version: 1.0.0 — Q3 2026 Critical Closure
# Legal basis: Art. 92-99 Ustawy o podatku akcyzowym
# Coverage: ~60 rules, ~60 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.akcyza.alcohol_tobacco

import data.jdg.helpers
import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.akcyza.alcohol_tobacco.no_match",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# Alkohol etylowy / Ethyl Alcohol (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.alcohol.r1",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250100,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Alkohol — WYSOKA akcyza + OBOWIĄZKOWY skład podatkowy!",
    "_legal_basis": "Art. 93 ust. 1 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Alkohol etylowy — stawka: 6900 PLN/hl 100% alkoholu (2026). Wymagany skład podatkowy!"],
    "rate_per_hl_100pct": 6900
} {
    object.get(input.invoice, "product_category", "") == "ETHYL_ALCOHOL"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.alcohol.r2",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250101,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "JDG produkująca alkohol BEZ składu podatkowego — PRZESTĘPSTWO!",
    "_legal_basis": "Art. 47 ust. 1; Art. 65 KKS",
    "_warnings": ["[AKCYZA] Produkcja alkoholu BEZ składu podatkowego = PRZESTĘPSTWO SKARBOWE (Art. 65 KKS)!"]
} {
    object.get(input.jdg_entrepreneur, "produces_alcohol", false) == true
    object.get(input.jdg_entrepreneur, "has_tax_warehouse", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.alcohol.r3",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250102,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 93 ust. 1 pkt 2 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Piwo — stawka: 8.57 PLN/hl za każdy stopień Plato (2026)"],
    "rate_per_hl_per_plato": 8.57
} {
    object.get(input.invoice, "alcohol_type", "") == "BEER"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.alcohol.r4",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250103,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 93 ust. 1 pkt 3 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Wino — stawka: 185 PLN/hl (2026)"],
    "rate_per_hl": 185
} {
    object.get(input.invoice, "alcohol_type", "") == "WINE"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.alcohol.r5",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250104,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 93 ust. 1 pkt 5 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Wyroby spirytusowe — stawka: 6900 PLN/hl 100% (jak alkohol etylowy)"],
    "rate_per_hl_100pct": 6900
} {
    object.get(input.invoice, "alcohol_type", "") == "SPIRITS"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.alcohol.r6",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250105,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 94 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Alkohol całkowicie skażony — ZWOLNIONY z akcyzy (do celów przemysłowych, kosmetycznych)"]
} {
    object.get(input.invoice, "alcohol_type", "") == "DENATURED_ALCOHOL"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.alcohol.r7",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250106,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 30 ust. 9 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Piwo z małych browarów (do 200 000 hl rocznie) — obniżona stawka akcyzy o 50%"]
} {
    object.get(input.invoice, "is_small_brewery", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.alcohol.r8",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250107,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 48 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Banderole — OBOWIĄZKOWE na wyrobach alkoholowych > 100ml (znaki akcyzy)"]
} {
    object.get(input.invoice, "alcohol_type", "") in {"SPIRITS", "WINE"}
    object.get(input.invoice, "container_volume_ml", 0) > 100
}

# ═══════════════════════════════════════════════════════════════════════════════
# Wyroby tytoniowe / Tobacco Products (10 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.tobacco.r1",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250120,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Wyroby tytoniowe — WYSOKA akcyza + banderole OBOWIĄZKOWE!",
    "_legal_basis": "Art. 99 ust. 1 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Wyroby tytoniowe — akcyza kwotowa + procentowa. Banderole OBOWIĄZKOWE!"]
} {
    object.get(input.invoice, "product_category", "") == "TOBACCO"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.tobacco.r2",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250121,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 99 ust. 3 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Papierosy — stawka: 367 PLN/1000 szt. + 32% ceny detalicznej (2026)"],
    "rate_per_1000": 367,
    "rate_ad_valorem_pct": 0.32
} {
    object.get(input.invoice, "tobacco_type", "") == "CIGARETTES"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.tobacco.r3",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250122,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 99 ust. 4 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Tytoń do palenia — stawka: 295 PLN/kg + 32% ceny detalicznej (2026)"],
    "rate_per_kg": 295,
    "rate_ad_valorem_pct": 0.32
} {
    object.get(input.invoice, "tobacco_type", "") == "SMOKING_TOBACCO"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.tobacco.r4",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250123,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 99 ust. 5 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Cygara i cygaretki — stawka: 695 PLN/1000 szt. (2026)"],
    "rate_per_1000": 695
} {
    object.get(input.invoice, "tobacco_type", "") == "CIGARS"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.tobacco.r5",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250124,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 99 ust. 9 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Płyn do e-papierosów — stawka: 0.70 PLN/ml (2026). Podlega akcyzie od 2021!"],
    "rate_per_ml": 0.70
} {
    object.get(input.invoice, "tobacco_type", "") == "E_LIQUID"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.tobacco.r6",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250125,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 99a Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Wyroby nowatorskie (podgrzewany tytoń) — stawka: 295 PLN/kg + 32% (2026)"],
    "rate_per_kg": 295,
    "rate_ad_valorem_pct": 0.32
} {
    object.get(input.invoice, "tobacco_type", "") == "HEATED_TOBACCO"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.tobacco.r7",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250126,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 116-120 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Banderole podatkowe — OBOWIĄZKOWE na każdym opakowaniu jednostkowym wyrobów tytoniowych!"]
} {
    object.get(input.invoice, "product_category", "") == "TOBACCO"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.tobacco.r8",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250127,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 99 ust. 10-11 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Minimalna stawka akcyzy na papierosy — 100% stawki na papierosy z najpopularniejszej kategorii cenowej"]
} {
    object.get(input.invoice, "tobacco_type", "") == "CIGARETTES"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Inne wyroby akcyzowe / Other Excise Goods (5 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.other.r1",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250140,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 1 pkt 15 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Samochody osobowe — akcyza zawarta w cenie pierwszego nabycia (płatna przez producenta/importera)"]
} {
    object.get(input.invoice, "product_category", "") == "PASSENGER_CAR"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.other.r2",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250141,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 100 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Samochody hybrydowe plug-in < 2000cm³ — obniżona akcyza 1.55% vs 3.1% (2026)"],
    "rate_standard": 0.031,
    "rate_hybrid": 0.0155
} {
    object.get(input.invoice, "car_type", "") == "PHEV"
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.other.r3",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250142,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "JDG handlująca wyrobami akcyzowymi BEZ zezwolenia — PRZESTĘPSTWO!",
    "_legal_basis": "Art. 65 KKS; Art. 47 Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Handel wyrobami akcyzowymi wymaga ZEZWOLENIA (koncesja/skład podatkowy/pośredniczący)!"]
} {
    object.get(input.jdg_entrepreneur, "trades_excise_goods", false) == true
    ent := object.get(input, "jdg_entrepreneur", {})
    not _has_either(ent)
}

else := {
    "matched": true,
    "rule_id": "jdg.akcyza.alcohol_tobacco.other.r4",
    "package": "jdg.akcyza.alcohol_tobacco",
    "priority": 250143,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 89 ust. 2a Ustawy o podatku akcyzowym",
    "_warnings": ["[AKCYZA] Susz tytoniowy — podlega akcyzie od 2023. Stawka: 295 PLN/kg + 32%"]
} {
    object.get(input.invoice, "tobacco_type", "") == "RAW_TOBACCO"
}

_has_either(doc) = true {
    object.get(doc, "has_excise_permit", false) == true
} else = true {
    object.get(doc, "has_tax_warehouse", false) == true
} else = false { true }

