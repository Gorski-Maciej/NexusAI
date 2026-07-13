# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Risk: Fraud, anomalie, KKS, GAAR, CEIDG (P0-P9)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Risk Package — Fraud Detection, Sanctions, Pre-Validation
# description: |
#   PAS 0 Multi-Pass. First-Match-Wins else-chain. Blokuje transakcje przed
#   dalszą ewaluacją jeśli wykryje fraud (P0/P0b), GAAR (P9), niski trust (P1),
#   anomalię kwotową (P2), zawieszonego kontrahenta (P8), lub wydatek osobisty (P5).
#   Jeśli _routing = BLOCK_AND_ALERT → main_jdg.rego abortuje dalsze passy.
# architecture: Multi-Pass PAS 0 (ADR-001)
# legal_basis: Art. 86 ust. 1 VAT, Art. 55/62 KKS, Art. 119a Ordynacji, Art. 22 UoR
# edge_cases:
#   - P0b (pusta faktura): fraud_flag AND !delivery_confirmed AND amount>0
#   - P1 (trust): próg auto_post z data.thresholds, routing dynamiczny (BLOCK vs TRIAGE)
#   - P9 (GAAR): related_party AND artificial_scheme — oba warunki muszą być spełnione
# package: jdg.risk
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.risk

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.risk.no_match",
    "package": "jdg.risk", "priority": 19
}

# ═══════════════════════════════════════════════════════════════════════════════
# P0: fraud_graph_match — Kontrahent w sieci fraudowej VAT
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.risk.fraud_graph_match",
    "package": "jdg.risk", "priority": 0,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Kontrahent w sieci fraudowej VAT",
    "_legal_basis": "Art. 86 ust. 1 VAT, Art. 55 KKS",
    "_warnings": ["FRAUD DETECTED — faktura od kontrahenta z sieci fraudowej VAT. Natychmiastowa blokada!"]
} {
    input.vendor.fraud_flag == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P0_b: kks_empty_invoice_fraud — Pusta faktura
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.kks_empty_invoice_fraud",
    "package": "jdg.risk", "priority": 0,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Pusta faktura — przestępstwo skarbowe",
    "_legal_basis": "Art. 62 § 2 KKS",
    "_warnings": ["PUSTA FAKTURA — przestępstwo skarbowe zagrożone karą do 25 lat pozbawienia wolności!"]
} {
    input.vendor.fraud_flag == true
    input.invoice.delivery_confirmed == false
    input.invoice.amount_gross > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P1: counterparty_trust_low — Niski trust score
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.counterparty_trust_low",
    "package": "jdg.risk", "priority": 1,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing, "_routing_reason": routing_reason,
    "_legal_basis": "Art. 22 UoR (zasada ostrożności)",
    "_warnings": [sprintf("Trust score kontrahenta: %.2f — poniżej progu", [trust_score])]
} {
    trust_score := object.get(input.vendor, "trust_score", 0)
    trust_score < 0.92
    trust_score > 0
    trust_auto := object.get(object.get(object.get(data.thresholds, "jdg", {}), "limits", {}), "trust_auto_post", 0.92)
    trust_score < trust_auto

    routing = "BLOCK_AND_ALERT" { trust_score < 0.40 }
    routing_reason = "Trust score krytycznie niski" { trust_score < 0.40 }
    routing = "TRIAGE_QUEUE" { trust_score >= 0.40; trust_score < 0.75 }
    routing_reason = "Trust score poniżej progu bezpieczeństwa" { trust_score >= 0.40; trust_score < 0.75 }
    routing = "TRIAGE_QUEUE" { trust_score >= 0.75 }
    routing_reason = "Trust score poniżej progu auto-post" { trust_score >= 0.75 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P2: anomaly_amount — Anomalia kwotowa >3σ
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.anomaly_amount",
    "package": "jdg.risk", "priority": 2,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Anomalia kwotowa — wartość >3σ od średniej kategorii",
    "_legal_basis": "Art. 22 UoR (zasada ostrożności)",
    "_warnings": ["Anomalia kwotowa — faktura znacząco odbiega od średniej dla tej kategorii"]
} {
    input.invoice.is_amount_anomaly == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P3: new_counterparty_flag — Nowy kontrahent
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.new_counterparty_flag",
    "package": "jdg.risk", "priority": 3,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Nowy kontrahent — wymagana dodatkowa weryfikacja",
    "_legal_basis": "Art. 22 UoR, procedury AML",
    "_warnings": ["Nowy kontrahent — dodatkowa weryfikacja wymagana"]
} {
    input.vendor.is_new == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P5: semantic_guard_disallowed — Wydatek niezwiązany z działalnością
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.semantic_guard_disallowed",
    "package": "jdg.risk", "priority": 5,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Wydatek niezwiązany z działalnością",
    "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT (dla JDG)",
    "_warnings": ["Wydatek niezwiązany z działalnością — NIE stanowi KUP"]
} {
    input.invoice.category_code in {"ALCOHOL", "ENTERTAINMENT", "LUXURY", "PERSONAL_EXPENSE"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# P8: ceidg_vendor_suspended — Kontrahent zawieszony w CEIDG
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.ceidg_vendor_suspended",
    "package": "jdg.risk", "priority": 8,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Kontrahent z zawieszoną działalnością CEIDG",
    "_legal_basis": "Art. 88 VAT, Art. 22-25 Prawa przedsiębiorców",
    "_warnings": ["Kontrahent z zawieszoną działalnością CEIDG — ryzyko braku prawa do odliczenia VAT!"]
} {
    input.vendor.ceidg_status == "SUSPENDED"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P9: gaar_artificial_scheme — Klauzula GAAR
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.gaar_artificial_scheme",
    "package": "jdg.risk", "priority": 9,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "Sztuczna struktura — klauzula GAAR",
    "_legal_basis": "Art. 119a § 1 Ordynacji podatkowej",
    "_warnings": ["GAAR — transakcja może być uznana za sztuczną strukturę unikania opodatkowania!"]
} {
    input.vendor.is_related_party == true
    input.invoice.amount_net > 0
    input.invoice.is_artificial_scheme == true
}
