# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Micro Layer — Proporcja VAT (Art. 90-90c VAT)
# Generated: 2026-07-28
# Package: jdg.micro.vat.proportion
# Legal coverage: Art. 90 (proporcja roczna), Art. 90a (proporcja wstępna),
#   Art. 90b (korekta roczna), Art. 90c (środki trwałe)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.vat.proportion

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.vat.proportion.no_match",
    "package": "jdg.micro.vat.proportion",
    "priority": 999999,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 90 — Proporcja roczna VAT — 6 reguł                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# PROP-01: Obowiązek proporcji — sprzedaż mieszana (opodatkowana + zwolniona)
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.proportion.prop_01",
    "package": "jdg.micro.vat.proportion",
    "priority": 90001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Proporcja VAT — sprzedaż mieszana → obowiązek kalkulacji",
    "_legal_basis": "Art. 90 ust. 1-2 VAT",
    "_warnings": ["[MICRO PROP] Proporcja VAT — sprzedaż opodatkowana + zwolniona = proporcja"]
} {
    object.get(input.jdg_entrepreneur, "vat_mixed_sales", false) == true
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# PROP-02: Wzór proporcji — sprzedaż opodatkowana / sprzedaż całkowita
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.proportion.prop_02",
    "package": "jdg.micro.vat.proportion",
    "priority": 90002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Wzór proporcji = (sprzedaż_opodatkowana / sprzedaż_całkowita) × 100%",
    "_legal_basis": "Art. 90 ust. 2-3 VAT",
    "_warnings": ["[MICRO PROP] Proporcja = obrót opodatkowany / obrót całkowity × 100%"]
} {
    object.get(input.jdg_entrepreneur, "vat_mixed_sales", false) == true
}

# PROP-03: Proporcja < 2% → brak odliczenia
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.proportion.prop_03",
    "package": "jdg.micro.vat.proportion",
    "priority": 90003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Proporcja < 2% — brak prawa do odliczenia",
    "_legal_basis": "Art. 90 ust. 5 VAT",
    "_warnings": ["[MICRO PROP] Proporcja < 2% — NIE ODLICZASZ VAT naliczonego"]
} {
    object.get(input.jdg_entrepreneur, "vat_proportion_pct", 100.0) < 2.0
}

# PROP-04: Proporcja > 98% → pełne odliczenie
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.proportion.prop_04",
    "package": "jdg.micro.vat.proportion",
    "priority": 90004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Proporcja > 98% — pełne odliczenie VAT",
    "_legal_basis": "Art. 90 ust. 4 VAT",
    "_warnings": ["[MICRO PROP] Proporcja > 98% — pełne prawo do odliczenia VAT"]
} {
    object.get(input.jdg_entrepreneur, "vat_proportion_pct", 0.0) > 98.0
}

# PROP-05: Proporcja wstępna — na podstawie roku poprzedniego
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.proportion.prop_05",
    "package": "jdg.micro.vat.proportion",
    "priority": 90005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Proporcja wstępna = proporcja z poprzedniego roku",
    "_legal_basis": "Art. 90a ust. 1 VAT",
    "_warnings": ["[MICRO PROP] Proporcja wstępna — wg ubiegłorocznej proporcji"]
} {
    object.get(input.jdg_entrepreneur, "vat_mixed_sales", false) == true
    object.get(input.jdg_entrepreneur, "vat_first_year", false) == false
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 90a — Proporcja wstępna dla nowych podatników — 3 reguły           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# PROP-06: Nowy podatnik — proporcja szacunkowa z US
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.proportion.prop_06",
    "package": "jdg.micro.vat.proportion",
    "priority": 90006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "VERIFICATION_QUEUE",
    "_routing_reason": "Pierwszy rok — proporcja szacunkowa (uzgodniona z US)",
    "_legal_basis": "Art. 90a ust. 2-3 VAT",
    "_warnings": ["[MICRO PROP] Nowy podatnik — złóż szacunek proporcji do US"]
} {
    object.get(input.jdg_entrepreneur, "vat_mixed_sales", false) == true
    object.get(input.jdg_entrepreneur, "vat_first_year", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 90b — Korekta roczna — 3 reguły                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# PROP-07: Korekta roczna — po zakończeniu roku
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.proportion.prop_07",
    "package": "jdg.micro.vat.proportion",
    "priority": 90007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Korekta roczna proporcji — w deklaracji za styczeń",
    "_legal_basis": "Art. 90b ust. 1 VAT",
    "_warnings": ["[MICRO PROP] Korekta roczna — w JPK_V7 za I kwartał"]
} {
    object.get(input.jdg_entrepreneur, "vat_mixed_sales", false) == true
    object.get(input.invoice, "period", "") == "ANNUAL_ADJUSTMENT"
}

# PROP-08: Korekta roczna — różnica > 2 p.p. → obowiązek korekty
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.proportion.prop_08",
    "package": "jdg.micro.vat.proportion",
    "priority": 90008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Różnica proporcji > 2 p.p. — obowiązkowa korekta",
    "_legal_basis": "Art. 90b ust. 2 VAT",
    "_warnings": ["[MICRO PROP] Korekta OBOWIĄZKOWA — różnica > 2 p.p. od proporcji wstępnej"]
} {
    obj := input.jdg_entrepreneur
    provisional := object.get(obj, "vat_proportion_provisional", 100.0)
    actual := object.get(obj, "vat_proportion_actual", 100.0)
    abs(provisional - actual) > 2.0
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 90c — Środki trwałe — korekta wieloletnia — 2 reguły              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# PROP-09: Środki trwałe — okres korekty 5/10 lat
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.proportion.prop_09",
    "package": "jdg.micro.vat.proportion",
    "priority": 90009,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_09",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Środki trwałe — korekta wieloletnia (5 lat ruchome / 10 lat nieruchomości)",
    "_legal_basis": "Art. 90c ust. 1 VAT",
    "_warnings": ["[MICRO PROP] Środek trwały — korekta przez 5/10 lat od nabycia"]
} {
    object.get(input.jdg_entrepreneur, "vat_mixed_sales", false) == true
    object.get(input.invoice, "is_fixed_asset", false) == true
    object.get(input.invoice, "vat_deducted_proportionally", false) == true
}

# PROP-10: Środki trwałe — nieruchomości 10 lat
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.proportion.prop_10",
    "package": "jdg.micro.vat.proportion",
    "priority": 90010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "GTU_09",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "VERIFICATION_QUEUE",
    "_routing_reason": "Nieruchomość — korekta 10-letnia",
    "_legal_basis": "Art. 90c ust. 2 VAT",
    "_warnings": ["[MICRO PROP] Nieruchomość — korekta 10 lat, 1/10 rocznie"]
} {
    object.get(input.jdg_entrepreneur, "vat_mixed_sales", false) == true
    object.get(input.invoice, "is_fixed_asset", false) == true
    object.get(input.invoice, "category_code", "") == "REAL_ESTATE"
}
