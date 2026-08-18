# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: AML CBDD Register (P1939-P1942 → 7 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.aml_cbdd

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.micro.aml_cbdd.no_match",
    "package": "jdg.micro.aml_cbdd", "priority": 999999
}

decide := {
    "matched": true, "rule_id": "jdg.micro.aml_cbdd.r1",
    "package": "jdg.micro.aml_cbdd", "priority": 83301,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("CBDD — spółka %s bez zgłoszenia BR do CRBR!", [company_type]),
    "_legal_basis": "Art. 58-79 Ustawy o CBDD",
    "_warnings": [sprintf("[MICRO] AML CBDD: %s NIEZAREJESTROWANA w CRBR! Termin: 7 dni od wpisu do KRS/CEIDG. Kara: do 1 000 000 PLN.", [company_type])]
} {
    object.get(input.jdg_entrepreneur, "cbdd_registered", false) == false
    company_type := object.get(input.jdg_entrepreneur, "company_type", ""); company_type in {"SP_ZOO", "SA", "SP_KOMANDYTOWA", "SP_JAWNA"}
}

else := {
    "matched": true, "rule_id": "jdg.micro.aml_cbdd.r2",
    "package": "jdg.micro.aml_cbdd", "priority": 83302,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 60 Ustawy o CBDD",
    "_warnings": [sprintf("[MICRO] AML CBDD: JDG (%s) — jako osoba fizyczna NIE podlega obowiązkowi CRBR. Beneficjentem rzeczywistym jesteś Ty.", [pkd])]
} {
    object.get(input.jdg_entrepreneur, "company_type", "") == "JDG"
    pkd := object.get(input.jdg_entrepreneur, "pkd_main", "")
}

else := {
    "matched": true, "rule_id": "jdg.micro.aml_cbdd.r3",
    "package": "jdg.micro.aml_cbdd", "priority": 83303,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("CBDD aktualizacja — %s. 7 dni!", [change]),
    "_legal_basis": "Art. 63 Ustawy o CBDD",
    "_warnings": [sprintf("[MICRO] AML CBDD: aktualizacja w CRBR — %s. Termin: 7 dni od zmiany. Brak = kara do 50 000 PLN.", [change])]
} {
    input.jdg_entrepreneur.cbdd_registered == true; object.get(input.jdg_entrepreneur, "cbdd_data_changed", false) == true
    change := object.get(input.jdg_entrepreneur, "cbdd_change_reason", "zmiana BR")
}

else := {
    "matched": true, "rule_id": "jdg.micro.aml_cbdd.r4",
    "package": "jdg.micro.aml_cbdd", "priority": 83304,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("CBDD kontrahenta: %s — %s", [vendor, cbdd_status]),
    "_legal_basis": "Art. 61-66 Ustawy o CBDD",
    "_warnings": [sprintf("[MICRO] AML CBDD: kontrahent %s (NIP: %s) — %s. %s", [vendor, nip, cbdd_status, action])]
} {
    object.get(input.jdg_entrepreneur, "is_aml_obliged", false) == true
    input.invoice.amount_gross >= 15000
    vendor := object.get(input.vendor, "name", "kontrahent"); nip := object.get(input.vendor, "nip", "")
    reg := object.get(input.vendor, "cbdd_registered", false)
    cbdd_status = "ZWERYFIKOWANY" { reg }; cbdd_status = "BRAK W CRBR — RYZYKO!" { not reg }
    action = "Transakcja OK" { reg }; action = "EDD + zgoda kierownictwa!" { not reg }
}

else := {
    "matched": true, "rule_id": "jdg.micro.aml_cbdd.r5",
    "package": "jdg.micro.aml_cbdd", "priority": 83305,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CBDD — rozbieżność! Dane w CRBR ≠ stan faktyczny.",
    "_legal_basis": "Art. 68 Ustawy o CBDD, Art. 153 AML",
    "_warnings": ["[MICRO] AML CBDD: ROZBIEŻNOŚĆ między CRBR a stanem faktycznym! Natychmiastowa aktualizacja. Sankcja KNF: do 1 000 000 PLN za nieprawdziwe dane."]
} {
    object.get(input.jdg_entrepreneur, "cbdd_discrepancy_detected", false) == true
}

