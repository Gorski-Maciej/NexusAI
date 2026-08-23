# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Micro Layer — Procedura marży VAT (Art. 119-120 VAT)
# Generated: 2026-07-28
# Package: jdg.micro.vat.margin
# Legal coverage: Art. 119 (towary używane, dzieła sztuki, antyki),
#   Art. 120 (szczególne zasady dla dzieł sztuki i antyków)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.vat.margin

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.vat.margin.no_match",
    "package": "jdg.micro.vat.margin",
    "priority": 999999,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 119 — Towary używane — 6 reguł                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# MAR-01: Procedura marży — towary używane
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.margin.mar_01",
    "package": "jdg.micro.vat.margin",
    "priority": 119001,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "MARGIN_USED_GOODS",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Procedura marży — towary używane (VAT od marży)",
    "_legal_basis": "Art. 119 ust. 1 VAT",
    "_warnings": ["[MICRO MARŻA] Towary używane — VAT od marży = cena sprzedaży − cena zakupu"]
} {
    object.get(input.invoice, "procedure", "") == "MARGIN_USED_GOODS"
    object.get(input.invoice, "margin_scheme_applies", false) == true
}

# MAR-02: Marża — nabycie od osoby niebędącej podatnikiem VAT
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.margin.mar_02",
    "package": "jdg.micro.vat.margin",
    "priority": 119002,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "MARGIN_USED_GOODS",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Marża — nabycie od osoby prywatnej (bez VAT)",
    "_legal_basis": "Art. 119 ust. 2 VAT",
    "_warnings": ["[MICRO MARŻA] Nabycie od osoby prywatnej — tylko marża podlega VAT"]
} {
    object.get(input.invoice, "procedure", "") == "MARGIN_USED_GOODS"
    object.get(input.vendor, "is_vat_payer", true) == false
}

# MAR-03: Marża — zakup od podatnika VAT na fakturę VAT-marża
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.margin.mar_03",
    "package": "jdg.micro.vat.margin",
    "priority": 119003,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "MARGIN_USED_GOODS",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Marża — zakup na fakturę VAT-marża od innego podatnika",
    "_legal_basis": "Art. 119 ust. 4 VAT",
    "_warnings": ["[MICRO MARŻA] Faktura VAT-marża — kontynuacja procedury marży"]
} {
    object.get(input.invoice, "procedure", "") == "MARGIN_USED_GOODS"
    object.get(input.invoice, "purchase_invoice_type", "") == "VAT_MARGIN"
}

# MAR-04: Marża ujemna — brak VAT do zapłaty
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.margin.mar_04",
    "package": "jdg.micro.vat.margin",
    "priority": 119004,
    "vat_rate": "0.00",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "MARGIN_NEGATIVE",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Marża ujemna — brak podstawy opodatkowania",
    "_legal_basis": "Art. 119 ust. 1 VAT",
    "_warnings": ["[MICRO MARŻA] Marża ujemna — cena sprzedaży < cena zakupu → VAT = 0"]
} {
    object.get(input.invoice, "procedure", "") == "MARGIN_USED_GOODS"
    object.get(input.invoice, "margin_amount", 0.0) <= 0.0
}

# MAR-05: Marża — globalne rozliczenie miesięczne
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.margin.mar_05",
    "package": "jdg.micro.vat.margin",
    "priority": 119005,
    "vat_rate": "0.23",
    "rounding_level": "total",
    "gtu_code": "",
    "procedure": "MARGIN_GLOBAL",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Marża globalna — rozliczenie miesięczne łączne",
    "_legal_basis": "Art. 119 ust. 5 VAT",
    "_warnings": ["[MICRO MARŻA] Marża globalna — suma marż za miesiąc"]
} {
    object.get(input.invoice, "procedure", "") == "MARGIN_GLOBAL"
    object.get(input.jdg_entrepreneur, "margin_global_method", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 120 — Dzieła sztuki, antyki, przedmioty kolekcjonerskie — 6 reguł  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# MAR-06: Marża — dzieła sztuki (8% VAT)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.margin.mar_06",
    "package": "jdg.micro.vat.margin",
    "priority": 120001,
    "vat_rate": "0.08",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "MARGIN_ART",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Marża — dzieła sztuki (VAT 8% od marży)",
    "_legal_basis": "Art. 120 ust. 1-3 VAT",
    "_warnings": ["[MICRO MARŻA] Dzieła sztuki — VAT 8% od marży"]
} {
    object.get(input.invoice, "procedure", "") == "MARGIN_ART"
    object.get(input.invoice, "margin_scheme_applies", false) == true
}

# MAR-07: Marża — antyki (>100 lat)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.margin.mar_07",
    "package": "jdg.micro.vat.margin",
    "priority": 120002,
    "vat_rate": "0.08",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "MARGIN_ANTIQUES",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Marża — antyki >100 lat",
    "_legal_basis": "Art. 120 ust. 1 VAT",
    "_warnings": ["[MICRO MARŻA] Antyki — VAT 8% od marży"]
} {
    object.get(input.invoice, "procedure", "") == "MARGIN_ANTIQUES"
}

# MAR-08: Marża — przedmioty kolekcjonerskie
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.margin.mar_08",
    "package": "jdg.micro.vat.margin",
    "priority": 120003,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "MARGIN_COLLECTIBLES",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Marża — przedmioty kolekcjonerskie",
    "_legal_basis": "Art. 120 ust. 2 VAT",
    "_warnings": ["[MICRO MARŻA] Kolekcjonerskie — VAT 23% od marży"]
} {
    object.get(input.invoice, "procedure", "") == "MARGIN_COLLECTIBLES"
}

# MAR-09: Marża — biuro podróży (VAT od marży, art. 119)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.margin.mar_09",
    "package": "jdg.micro.vat.margin",
    "priority": 120004,
    "vat_rate": "0.23",
    "rounding_level": "total",
    "gtu_code": "",
    "procedure": "MARGIN_TRAVEL",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Marża — usługi turystyki (VAT od marży)",
    "_legal_basis": "Art. 119 VAT (usługi turystyki)",
    "_warnings": ["[MICRO MARŻA] Biuro podróży — VAT od marży = cena imprezy − koszty własne"]
} {
    object.get(input.invoice, "procedure", "") == "MARGIN_TRAVEL"
    object.get(input.invoice, "margin_scheme_applies", false) == true
}

# MAR-10: Marża — rezygnacja z procedury (opcja VAT ogólny)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.margin.mar_10",
    "package": "jdg.micro.vat.margin",
    "priority": 120005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "procedure": "MARGIN_OPT_OUT",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Rezygnacja z procedury marży — opcja opodatkowania ogólnego",
    "_legal_basis": "Art. 119 ust. 3 VAT, Art. 120 ust. 5-6 VAT",
    "_warnings": ["[MICRO MARŻA] Rezygnacja z marży — VAT na zasadach ogólnych"]
} {
    object.get(input.jdg_entrepreneur, "margin_scheme_opt_out", false) == true
    object.get(input.invoice, "margin_scheme_applies", false) == true
}
