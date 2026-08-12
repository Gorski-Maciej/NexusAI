# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PKPiR — §10-12 Struktura kolumn
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-17
# Package: jdg.micro.pkpir_columns
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.pkpir_columns

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pkpir_columns.no_match",
    "package": "jdg.micro.pkpir_columns",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pkpir.p10 — §10-12 Struktura kolumn 1-19 (12 reguł)                     ║
# ║  Legal basis: §10-12 Rozp. MF z 15.11.2025 r. w sprawie PKPiR             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.pkpir_columns.p10.r1: col_structure_eligibility
decide := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r1",
    "package": "jdg.micro.pkpir_columns", "priority": 80101,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§10 rozporządzenia MF z 15.11.2025 r.",
    "_warnings": ["[MICRO] §10 PKPiR: PKPiR musi zawierać 19 kolumn — kol.1-19"]
} { input.jdg_entrepreneur.uses_pkpir == true }

# jdg.micro.pkpir_columns.p10.r2: col_1_lp — kolumna 1: liczba porządkowa
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r2",
    "package": "jdg.micro.pkpir_columns", "priority": 80102,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§10 ust. 1 pkt 1 rozporządzenia MF w sprawie PKPiR",
    "_warnings": ["[MICRO] §10 PKPiR: Kol.1 — LP (liczba porządkowa) — numerowane ciągiem od 1"]
} {
    input.jdg_entrepreneur.uses_pkpir == true
    object.get(input.invoice, "pkpir_entry_number", 0) > 0
}

# jdg.micro.pkpir_columns.p10.r3: col_2_3_dates — kolumny 2-3: data zdarzenia i data wpisu
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r3",
    "package": "jdg.micro.pkpir_columns", "priority": 80103,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§10 ust. 1 pkt 2-3 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §10 PKPiR: Kol.2=%s (data zdarzenia), Kol.3=%s (data wpisu)", [event_date, entry_date])]
} {
    event_date := object.get(input.invoice, "transaction_date", "")
    entry_date := object.get(input.invoice, "pkpir_entry_date", "")
    event_date != ""
}

# jdg.micro.pkpir_columns.p10.r4: col_4_5_doc — kolumny 4-5: nr dowodu i kontrahent
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r4",
    "package": "jdg.micro.pkpir_columns", "priority": 80104,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§10 ust. 1 pkt 4-5 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §10 PKPiR: Kol.4=%s (nr faktury/dowodu), Kol.5=%s (nazwa kontrahenta)", [doc_number, vendor_name])]
} {
    doc_number := object.get(input.invoice, "document_number", "")
    vendor_name := object.get(input.vendor, "name", "")
    doc_number != ""
}

# jdg.micro.pkpir_columns.p10.r5: cols_6_9 — kolumny 6-9: przychody i zakup towarów
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r5",
    "package": "jdg.micro.pkpir_columns", "priority": 80105,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§11 rozporządzenia MF w sprawie PKPiR",
    "_warnings": ["[MICRO] §11 PKPiR: Kol.6 — opis zdarzenia, Kol.7 — sprzedane towary/usługi, Kol.8 — pozostałe przychody, Kol.9 — opis"]
} {
    input.invoice.direction == "SALE"
}

# jdg.micro.pkpir_columns.p10.r6: cols_10_14 — kolumny 10-14: koszty
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r6",
    "package": "jdg.micro.pkpir_columns", "priority": 80106,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§12 rozporządzenia MF w sprawie PKPiR",
    "_warnings": ["[MICRO] §12 PKPiR: Kol.10 — zakup towarów, Kol.11 — koszty uboczne, Kol.12 — wynagrodzenia, Kol.13 — pozostałe, Kol.14 — NKUP"]
} {
    input.invoice.direction == "PURCHASE"
}

# jdg.micro.pkpir_columns.p10.r7: cols_15_16 — kolumny 15-16: amortyzacja i VAT
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r7",
    "package": "jdg.micro.pkpir_columns", "priority": 80107,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§12 ust. 4-5 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §12 PKPiR: Kol.15 — amortyzacja %.2f PLN, Kol.16 — VAT naliczony %.2f PLN", [depr, vat])]
} {
    depr := object.get(input.invoice, "depreciation_monthly", 0)
    vat := object.get(input.invoice, "vat_deductible_amount", 0)
    depr > 0 or vat > 0
}

# jdg.micro.pkpir_columns.p10.r8: col_17_notes — kolumna 17: uwagi
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r8",
    "package": "jdg.micro.pkpir_columns", "priority": 80108,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§12 ust. 6 rozporządzenia MF w sprawie PKPiR",
    "_warnings": [sprintf("[MICRO] §12 PKPiR: Kol.17 — uwagi. Przyczyna korekty: %s", [correction_reason])]
} {
    correction_reason := object.get(input.invoice, "correction_reason", "")
    correction_reason != ""
}

# jdg.micro.pkpir_columns.p10.r9: block_missing_columns — blokada: brak obowiązkowych kolumn
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r9",
    "package": "jdg.micro.pkpir_columns", "priority": 80109,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PKPiR bez wymaganych 19 kolumn — księga nierzetelna (Art. 56 KKS)!",
    "_legal_basis": "§10 rozporządzenia MF w sprawie PKPiR + Art. 56 KKS",
    "_warnings": [sprintf("[MICRO] §10 PKPiR: BLOCK — księga ma %d kolumn zamiast 19. Nierzetelność = KKS Art.56!", [col_count])]
} {
    col_count := object.get(input.jdg_entrepreneur, "pkpir_column_count", 0)
    col_count < 19
    col_count > 0
}

# jdg.micro.pkpir_columns.p10.r10: interaction_with_zus — interakcja PKPiR × ZUS
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r10",
    "package": "jdg.micro.pkpir_columns", "priority": 80110,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§12 w zw. z Art. 46 SUS",
    "_warnings": [sprintf("[MICRO] §12 PKPiR: Interakcja z ZUS DRA — składki ZUS za %.2f PLN muszą być zgodne z DRA", [zus_dra])]
} {
    zus_dra := object.get(input.jdg_entrepreneur, "zus_dra_monthly", 0)
    zus_dra > 0
    object.get(input.jdg_entrepreneur, "zus_dra_pkpir_consistent", true) == false
}

# jdg.micro.pkpir_columns.p10.r11: sanction_unreliable_books — sankcja KKS
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.r11",
    "package": "jdg.micro.pkpir_columns", "priority": 80111,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS", "sanction_severity": "HIGH",
    "sanction_base_amount_pln": 5000,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Sankcja KKS: nierzetelne PKPiR — Art. 56 KKS",
    "_legal_basis": "Art. 56 § 1 KKS",
    "_warnings": ["[MICRO] §10-12 PKPiR: SANKCJA KKS — nierzetelne PKPiR = grzywna do 240 stawek dziennych!"]
} {
    object.get(input.jdg_entrepreneur, "pkpir_integrity_score", 1.0) < 0.70
    object.get(input.jdg_entrepreneur, "pkpir_entry_count", 0) > 0
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.pkpir_columns.p10.fallback",
    "package": "jdg.micro.pkpir_columns", "priority": 80199,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§10-12 rozporządzenia MF w sprawie PKPiR",
    "_warnings": ["[MICRO] PKPiR struktura kolumn — OK"]
} { true }
