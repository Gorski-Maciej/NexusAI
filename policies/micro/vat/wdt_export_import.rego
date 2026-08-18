# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Micro Layer — WDT / Export / Import (Art. 9-13 VAT)
# Generated: 2026-07-28
# Package: jdg.micro.vat.wdt_export
# Legal coverage: Art. 9 (WDT), Art. 11 (WNT), Art. 12 (Import), Art. 13 (Export)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.vat.wdt_export

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.vat.wdt_export.no_match",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 999999,
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 9 — Wewnątrzwspólnotowa Dostawa Towarów (WDT) — 8 reguł             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# WDT-01: WDT eligibility — nabywca z UE z VAT-EU
decide := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.wdt_01",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 90001,
    "vat_rate": "0%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "WDT",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "WDT — dostawa do UE z VAT-EU nabywcy",
    "_legal_basis": "Art. 13 ust. 1-2 VAT",
    "_warnings": ["[MICRO WDT] WDT 0% — wymagany VAT-EU nabywcy i dokumenty wywozu"]
} {
    object.get(input.invoice, "procedure", "") == "WDT"
    object.get(input.vendor, "vat_eu_active", false) == true
    object.get(input.invoice, "buyer_country", "") != "PL"
}

# WDT-02: WDT documentation — wymagane dokumenty potwierdzające wywóz
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.wdt_02",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 90002,
    "vat_rate": "0%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "WDT",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "VERIFICATION_QUEUE",
    "_routing_reason": "WDT — sprawdź dokumentację wywozu (CMR, specyfikacja)",
    "_legal_basis": "Art. 42 ust. 1-3 VAT",
    "_warnings": ["[MICRO WDT] Dokumenty WDT: CMR, specyfikacja towarów, potwierdzenie odbioru"]
} {
    object.get(input.invoice, "procedure", "") == "WDT"
    object.get(input.invoice, "wdt_docs_complete", false) == false
}

# WDT-03: WDT — brak dokumentów w 3 miesiące → stawka krajowa
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.wdt_03",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 90003,
    "vat_rate": "23%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "WDT_FAILED",
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "WDT — brak dokumentów >3 miesiące → stawka krajowa",
    "_legal_basis": "Art. 42 ust. 12-13 VAT",
    "_warnings": ["[MICRO WDT] BRAK DOKUMENTÓW WDT >3 MIES. — zastosuj stawkę krajową"]
} {
    object.get(input.invoice, "procedure", "") == "WDT"
    object.get(input.invoice, "wdt_docs_missing_days", 0) > 90
}

# WDT-04: WDT — nowy środek transportu do UE
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.wdt_04",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 90004,
    "vat_rate": "0%",
    "rounding_level": "position",
    "gtu_code": "GTU_05",
    "procedure": "WDT_TRANSPORT",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "WDT — nowy środek transportu do UE",
    "_legal_basis": "Art. 13 ust. 2 pkt 2 VAT",
    "_warnings": ["[MICRO WDT] Nowy środek transportu WDT — 0% bez względu na status nabywcy"]
} {
    object.get(input.invoice, "procedure", "") == "WDT"
    object.get(input.invoice, "category_code", "") == "CAR"
    object.get(input.invoice, "is_new_vehicle", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 11 — Wewnątrzwspólnotowe Nabycie Towarów (WNT) — 6 reguł            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# WNT-01: WNT eligibility — nabycie z UE
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.wnt_01",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 91001,
    "vat_rate": "23%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "WNT",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "WNT — nabycie towarów z UE",
    "_legal_basis": "Art. 9 ust. 1-2 VAT",
    "_warnings": ["[MICRO WNT] WNT — obowiązek podatkowy: 15. dzień miesiąca po dostawie"]
} {
    object.get(input.invoice, "procedure", "") == "WNT"
    object.get(input.invoice, "direction", "") == "PURCHASE"
    object.get(input.vendor, "country", "") != "PL"
}

# WNT-02: WNT — reverse charge mechanizm
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.wnt_02",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 91002,
    "vat_rate": "23%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "WNT_REVERSE_CHARGE",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "WNT — VAT należny + VAT naliczony (reverse charge)",
    "_legal_basis": "Art. 17 ust. 1 pkt 3 VAT",
    "_warnings": ["[MICRO WNT] Reverse charge WNT: VAT należny = VAT naliczony"]
} {
    object.get(input.invoice, "procedure", "") == "WNT"
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# WNT-03: WNT — nowy środek transportu
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.wnt_03",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 91003,
    "vat_rate": "23%",
    "rounding_level": "position",
    "gtu_code": "GTU_05",
    "procedure": "WNT_TRANSPORT",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "WNT — nowy środek transportu z UE → VAT zawsze należny",
    "_legal_basis": "Art. 9 ust. 2 pkt 2 VAT",
    "_warnings": ["[MICRO WNT] Nowy środek transportu WNT — VAT należny bez względu na status"]
} {
    object.get(input.invoice, "procedure", "") == "WNT"
    object.get(input.invoice, "category_code", "") == "CAR"
    object.get(input.invoice, "is_new_vehicle", false) == true
}

# WNT-04: WNT — wyroby akcyzowe
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.wnt_04",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 91004,
    "vat_rate": "23%",
    "rounding_level": "position",
    "gtu_code": "GTU_01",
    "procedure": "WNT_EXCISE",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "WNT — wyroby akcyzowe → VAT zawsze należny",
    "_legal_basis": "Art. 9 ust. 2 pkt 3 VAT",
    "_warnings": ["[MICRO WNT] Wyroby akcyzowe WNT — VAT należny + obowiązek akcyzowy"]
} {
    object.get(input.invoice, "procedure", "") == "WNT"
    object.get(input.invoice, "is_excise_goods", false) == true
}

# WNT-05: WNT — mały podatnik zwolniony (limit 50 000 PLN)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.wnt_05",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 91005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "procedure": "WNT_EXEMPT",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "WNT — zwolnienie dla małego podatnika <50k PLN",
    "_legal_basis": "Art. 10 ust. 1 pkt 2 VAT",
    "_warnings": ["[MICRO WNT] Zwolnienie WNT — limit 50 000 PLN rocznie"]
} {
    object.get(input.invoice, "procedure", "") == "WNT"
    object.get(input.jdg_entrepreneur, "vat_status", "") != "ACTIVE"
    object.get(input.jdg_entrepreneur, "wnt_annual_total", 0) <= 50000
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 12 — Import towarów — 4 reguły                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# IMP-01: Import — VAT w imporcie
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.imp_01",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 92001,
    "vat_rate": "23%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "IMPORT",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Import — VAT należny od wartości celnej",
    "_legal_basis": "Art. 12 VAT w zw. z Art. 29a VAT",
    "_warnings": ["[MICRO IMPORT] Import spoza UE — VAT od wartości celnej + cło"]
} {
    object.get(input.invoice, "procedure", "") == "IMPORT"
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# IMP-02: Import — uproszczona procedura celna
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.imp_02",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 92002,
    "vat_rate": "23%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "IMPORT_SIMPLIFIED",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Import — procedura uproszczona (art. 33a)",
    "_legal_basis": "Art. 33a ust. 1 VAT",
    "_warnings": ["[MICRO IMPORT] Import uproszczony — VAT w deklaracji, nie w cle"]
} {
    object.get(input.invoice, "procedure", "") == "IMPORT"
    object.get(input.invoice, "import_simplified", false) == true
}

# IMP-03: Import — mała przesyłka do 150 EUR (IOSS)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.imp_03",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 92003,
    "vat_rate": "23%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "IMPORT_IOSS",
    "micro_rule_active": true,
    "valid_from": "2021-07-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Import IOSS — mała przesyłka ≤150 EUR",
    "_legal_basis": "Art. 33b-33c VAT (IOSS)",
    "_warnings": ["[MICRO IMPORT] IOSS — import ≤150 EUR, VAT rozliczany przez sprzedawcę"]
} {
    object.get(input.invoice, "procedure", "") == "IMPORT"
    object.get(input.invoice, "amount_total_eur", 999999.0) <= 150.0
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Art. 13 — Eksport towarów — 5 reguł                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# EXP-01: Eksport bezpośredni — 0% VAT
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.exp_01",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 93001,
    "vat_rate": "0%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "EXPORT_DIRECT",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Eksport bezpośredni — 0% VAT z dokumentem celnym IE-599",
    "_legal_basis": "Art. 13 ust. 1 VAT w zw. z Art. 41 ust. 4-11 VAT",
    "_warnings": ["[MICRO EXPORT] Eksport bezpośredni 0% — wymagany IE-599"]
} {
    object.get(input.invoice, "procedure", "") == "EXPORT"
    object.get(input.invoice, "export_type", "") == "DIRECT"
}

# EXP-02: Eksport pośredni — 0% VAT (przez agencję celną)
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.exp_02",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 93002,
    "vat_rate": "0%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "EXPORT_INDIRECT",
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "VERIFICATION_QUEUE",
    "_routing_reason": "Eksport pośredni — 0% po otrzymaniu potwierdzenia wywozu",
    "_legal_basis": "Art. 41 ust. 7-8 VAT",
    "_warnings": ["[MICRO EXPORT] Eksport pośredni — 0% po IE-599, max 10 mies."]
} {
    object.get(input.invoice, "procedure", "") == "EXPORT"
    object.get(input.invoice, "export_type", "") == "INDIRECT"
}

# EXP-03: Eksport — brak dokumentu celnego → stawka krajowa
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.exp_03",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 93003,
    "vat_rate": "23%",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "EXPORT_FAILED",
    "micro_rule_active": true,
    "valid_from": "2014-01-01",
    "valid_to": null,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Eksport — brak IE-599 → stawka krajowa 23%",
    "_legal_basis": "Art. 41 ust. 9a-11 VAT",
    "_warnings": ["[MICRO EXPORT] BRAK IE-599 — zastosuj stawkę krajową 23% + odsetki"]
} {
    object.get(input.invoice, "procedure", "") == "EXPORT"
    object.get(input.invoice, "export_doc_received", false) == false
    object.get(input.invoice, "export_days_since_shipment", 0) > 300
}

# EXP-04: Eksport — usługi pomocnicze 0%
else := {
    "matched": true,
    "rule_id": "jdg.micro.vat.wdt_export.exp_04",
    "package": "jdg.micro.vat.wdt_export",
    "priority": 93004,
    "vat_rate": "0%",
    "rounding_level": "position",
    "gtu_code": "GTU_10",
    "procedure": "EXPORT_SERVICES",
    "micro_rule_active": true,
    "valid_from": "2004-05-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Usługi pomocnicze do eksportu — 0% VAT",
    "_legal_basis": "Art. 83 ust. 1 pkt 19-23 VAT",
    "_warnings": ["[MICRO EXPORT] Usługi transportowe/spedycyjne do eksportu — stawka 0%"]
} {
    object.get(input.invoice, "type", "") == "SERVICE"
    object.get(input.invoice, "export_related_service", false) == true
}
