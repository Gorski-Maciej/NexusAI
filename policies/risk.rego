# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Risk: Fraud, anomalie, KKS, GAAR, CEIDG (P0-P9)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Risk Package — Fraud Detection, Sanctions, Pre-Validation
# description: |
#   PAS 0 Multi-Pass. First-Match-Wins else-chain. Blokuje transakcje przed
#   dalszą ewaluacją jeśli wykryje fraud (P0/P0b), ukryte dochody KKS 54 (P4),
#   GAAR (P9), niski trust (P1), anomalię kwotową (P2),
#   nierzetelną PKPiR KKS 56 (P6), zawieszonego kontrahenta (P8),
#   lub wydatek osobisty (P5).
#   Jeśli _routing = BLOCK_AND_ALERT → main_jdg.rego abortuje dalsze passy.
# architecture: Multi-Pass PAS 0 (ADR-001)
# legal_basis: Art. 86 ust. 1 VAT, Art. 54-56/62 KKS, Art. 119a Ordynacji, Art. 22 UoR
# edge_cases:
#   - P0b (pusta faktura): fraud_flag AND !delivery_confirmed AND amount>0
#   - P1 (trust): próg auto_post z data.thresholds, routing dynamiczny (BLOCK vs TRIAGE)
#   - P4 (ukryte dochody): bank_deposits_ytd vs declared_revenue_ytd, >30% rozbieżności
#   - P6 (nierzetelna PKPiR): integrity_score < 0.70, entry_count > 0
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
# P4: kks_hidden_income_flag — Ukryte dochody (Art. 54 KKS)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.kks_hidden_income_flag",
    "package": "jdg.risk", "priority": 4,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_risk": "Art.54",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Rozbieżność %.0f%% — ryzyko ukrytych dochodów KKS Art. 54", [floor(discrepancy_pct * 100)]),
    "_legal_basis": "Art. 54 § 1 KKS",
    "_warnings": [sprintf("Rozbieżność %.0f%% między wpływami (%.0f PLN) a deklarowanymi przychodami (%.0f PLN) — ryzyko ukrytych dochodów KKS Art. 54!", [floor(discrepancy_pct * 100), deposits, declared])]
} {
    deposits := object.get(input.jdg_entrepreneur, "bank_deposits_ytd", 0)
    declared := object.get(input.jdg_entrepreneur, "declared_revenue_ytd", 0)
    deposits > 0
    declared > 0
    deposits > declared
    discrepancy_threshold := object.get(object.get(object.get(data.thresholds, "jdg", {}), "limits", {}), "kks_discrepancy_threshold", 0.30)
    discrepancy_pct := (deposits - declared) / declared
    discrepancy_pct > discrepancy_threshold
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
# P6: kks_unreliable_books — Nierzetelna PKPiR (Art. 56 KKS)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.kks_unreliable_books",
    "package": "jdg.risk", "priority": 6,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "kks_risk": "Art.56",
    "pkpir_integrity_score": integrity_score,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("PKPiR integrity score %.0f%% < %.0f%% — ryzyko nierzetelnych ksiąg", [floor(integrity_score * 100), floor(integrity_min * 100)]),
    "_legal_basis": "Art. 56 § 1-2 KKS, Art. 24a PIT",
    "_warnings": [sprintf("Nierzetelna PKPiR — integrity score %.0f%% < %.0f%%. Ryzyko KKS Art. 56 (grzywna do 720 stawek dziennych). Skoryguj ewidencję!", [floor(integrity_score * 100), floor(integrity_min * 100)])]
} {
    uses_pkpir := object.get(input.jdg_entrepreneur, "uses_pkpir", false)
    uses_pkpir == true
    entry_count := object.get(input.jdg_entrepreneur, "pkpir_entry_count", 0)
    entry_count > 0
    integrity_min := object.get(object.get(object.get(data.thresholds, "jdg", {}), "limits", {}), "pkpir_integrity_min", 0.70)
    integrity_score := object.get(input.jdg_entrepreneur, "pkpir_integrity_score", 1.0)
    integrity_score < integrity_min
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

# ═══════════════════════════════════════════════════════════════════════════════
# P0c: heuristic_empty_invoice_detection — Heurystyczna detekcja pustych faktur (QF-2 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.heuristic_empty_invoice",
    "package": "jdg.risk", "priority": 0,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "heuristic_empty_invoice": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Heurystyczna detekcja potencjalnie pustej faktury",
    "_legal_basis": "Art. 62 § 2 KKS (heurystyka)",
    "_warnings": ["HEURYSTYKA: Potencjalnie pusta faktura — okrągła kwota >10k + nowy kontrahent. Wymagana weryfikacja manualna."]
} {
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross > object.get(data.thresholds.jdg.automatyzacja_ksiegowosci, "high_value_tx_threshold", 15000)
    amount_gross % 1000 == 0
    input.vendor.is_new == true
    input.invoice.delivery_confirmed == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P10: vat_fraud_risk_score — 5-wymiarowy scoring ryzyka fraudu VAT (QF-1 v7.0)
# Używa danych wstrzykniętych przez PreOPAFraudChecker przed ewaluacją OPA
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.vat_fraud_risk_score",
    "package": "jdg.risk", "priority": 10,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_fraud_score": fraud_score,
    "vat_fraud_level": fraud_level,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 86 ust. 1 VAT, Art. 55/62 KKS, procedury AML",
    "_warnings": warnings
} {
    fraud_score := object.get(object.get(input, "risk", {}), "fraud_score", 0)
    fraud_level := object.get(object.get(input, "risk", {}), "fraud_risk_level", "GREEN")
    fraud_score > 0

    routing = "BLOCK_AND_ALERT" { fraud_score > 60 }
    routing_reason = "VAT Fraud Score RED — wysokie ryzyko oszustwa" { fraud_score > 60 }
    routing = "TRIAGE_QUEUE" { fraud_score > 30; fraud_score <= 60 }
    routing_reason = "VAT Fraud Score YELLOW — podwyższone ryzyko" { fraud_score > 30; fraud_score <= 60 }
    routing = "" { fraud_score <= 30 }
    routing_reason = "" { fraud_score <= 30 }

    warnings = [sprintf("VAT FRAUD SCORE: %.0f/100 (%s). %d flag ostrzegawczych.", [fraud_score, fraud_level, flag_count])] {
        flag_count := count(object.get(object.get(input, "risk", {}), "fraud_flags", []))
    }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  F200-F203: PIT FRAUD DETECTION — Strategiczna Inicjatywa S15 (v7.0 Audit)  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── F200: pit_cost_anomaly — Anomalia kosztowa >3x średnia branżowa ──
else := {
    "matched": true, "rule_id": "jdg.risk.pit_cost_anomaly",
    "package": "jdg.risk", "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pit_fraud_flag": "COST_ANOMALY",
    "pit_cost_ratio": cost_ratio,
    "pit_industry_avg_ratio": industry_avg,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Anomalia kosztowa PIT: stosunek kosztów/przychodów %.1fx > średnia branżowa %.1fx (3x przekroczenie)", [cost_ratio, industry_avg]),
    "_legal_basis": "Art. 22-23 PIT, Art. 56 KKS (nierzetelne księgi)",
    "_warnings": [sprintf("F200 — ANOMALIA KOSZTOWA PIT: Twoje koszty (%.0f PLN) stanowią %.0f%% przychodów (%.0f PLN). Średnia dla branży '%s': %.0f%%. PRZEKROCZENIE %.1fx! Sprawdź poprawność dokumentacji kosztowej — ryzyko kontroli US.", [annual_costs, cost_ratio * 100, annual_revenue, industry, industry_avg * 100, cost_ratio / industry_avg])]
} {
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs_pln", 0)
    industry := object.get(input.jdg_entrepreneur, "industry", "SERVICES")
    annual_revenue > 0
    annual_costs > 0
    cost_ratio := annual_costs / annual_revenue
    # Średnie branżowe (KAS benchmark data)
    industry_benchmarks := {
        "IT": 0.15, "SERVICES": 0.25, "CONSTRUCTION": 0.60,
        "TRADING": 0.75, "MANUFACTURING": 0.55, "TRANSPORT": 0.50,
        "CONSULTING": 0.20, "HEALTHCARE": 0.30, "EDUCATION": 0.25
    }
    industry_avg := object.get(industry_benchmarks, industry, 0.30)
    cost_ratio > industry_avg * 3
}

# ── F201: pit_counterparty_ghost — Kontrahent bez NIP/PESEL w CEIDG ──
else := {
    "matched": true, "rule_id": "jdg.risk.pit_counterparty_ghost",
    "package": "jdg.risk", "priority": 201,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pit_fraud_flag": "COUNTERPARTY_GHOST",
    "ghost_nip": vendor_nip,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Kontrahent-widmo PIT: NIP %s nie figuruje w CEIDG/VAT — faktura może być fikcyjna!", [vendor_nip]),
    "_legal_basis": "Art. 62 § 2 KKS (fikcyjne faktury), Art. 55 KKS, Art. 22 PIT",
    "_warnings": [sprintf("F201 — KONTRAHENT-WIDMO: NIP %s nie figuruje w rejestrze CEIDG/VAT. Faktura na kwotę %.2f PLN może być FIKCYJNA. NIE księguj jako KUP do czasu weryfikacji! Sprawdź w CEIDG i na Białej Liście VAT.", [vendor_nip, invoice_amount])]
} {
    input.invoice.direction == "PURCHASE"
    vendor_nip := object.get(input.vendor, "nip", "")
    vendor_nip != ""
    ceidg_verified := object.get(input.vendor, "ceidg_verified", true)
    whitelist_verified := object.get(input.vendor, "whitelist_verified", true)
    ceidg_verified == false
    whitelist_verified == false
    invoice_amount := object.get(input.invoice, "amount_net", 0)
    invoice_amount > 0
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ── F202: pit_round_amounts_fraud — Okrągłe kwoty faktur (>10 takich samych) ──
else := {
    "matched": true, "rule_id": "jdg.risk.pit_round_amounts_fraud",
    "package": "jdg.risk", "priority": 202,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pit_fraud_flag": "ROUND_AMOUNTS",
    "round_amount_count": round_count,
    "round_amount_value": round_value,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Sygnał fraudu: %d faktur na identyczną, okrągłą kwotę %.2f PLN od kontrahenta %s", [round_count, round_value, vendor_name]),
    "_legal_basis": "Art. 62 KKS, Art. 22 PIT (fikcyjne faktury)",
    "_warnings": [sprintf("F202 — OKRĄGŁE KWOTY: %d faktur od kontrahenta '%s' na identyczną kwotę %.2f PLN. Wzorzec typowy dla faktur fikcyjnych. Wymagana weryfikacja: czy istniała rzeczywista dostawa towaru/usługi?", [round_count, vendor_name, round_value])]
} {
    round_count := object.get(input.vendor, "same_amount_invoice_count", 0)
    round_count > 10
    round_value := object.get(input.vendor, "same_amount_value", 0)
    round_value > 0
    round_value == floor(round_value / 1000) * 1000
    vendor_name := object.get(input.vendor, "name", "NIEZNANY")
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ── F203: pit_revenue_drop_anomaly — Gwałtowny spadek przychodów przy stałych kosztach ──
else := {
    "matched": true, "rule_id": "jdg.risk.pit_revenue_drop_anomaly",
    "package": "jdg.risk", "priority": 203,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "pit_fraud_flag": "REVENUE_DROP_ANOMALY",
    "revenue_change_pct": revenue_change_pct,
    "cost_change_pct": cost_change_pct,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Anomalia PIT: spadek przychodów o %.0f%% przy spadku kosztów tylko o %.0f%% — możliwe ukrywanie przychodów", [revenue_change_pct * 100, cost_change_pct * 100]),
    "_legal_basis": "Art. 54 KKS (ukrywanie przychodów), Art. 14 PIT",
    "_warnings": [sprintf("F203 — SPADEK PRZYCHODÓW: Przychody spadły o %.0f%% (z %.0f PLN na %.0f PLN), podczas gdy koszty spadły tylko o %.0f%% (z %.0f PLN na %.0f PLN). Nietypowa rozbieżność — możliwe ukrywanie przychodów poza ewidencją. Sprawdź czy wszystkie wpływy na konto bankowe są fakturowane.", [revenue_change_pct * 100, prev_revenue, curr_revenue, cost_change_pct * 100, prev_costs, curr_costs])]
} {
    prev_revenue := object.get(input.jdg_entrepreneur, "prev_period_revenue", 0)
    curr_revenue := object.get(input.jdg_entrepreneur, "current_period_revenue", 0)
    prev_costs := object.get(input.jdg_entrepreneur, "prev_period_costs", 0)
    curr_costs := object.get(input.jdg_entrepreneur, "current_period_costs", 0)
    prev_revenue > object.get(data.thresholds.jdg.automatyzacja_ksiegowosci, "high_value_tx_threshold", 15000)
    revenue_change_pct := (prev_revenue - curr_revenue) / prev_revenue
    cost_change_pct := abs(prev_costs - curr_costs) / max([prev_costs, 1])
    # Spadek przychodów >50% przy spadku kosztów <15%
    revenue_change_pct > 0.50
    cost_change_pct < 0.15
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P11: vat_carousel_detection — Wykrywanie karuzel VAT (MR-2 v7.0)
# Używa danych wstrzykniętych przez PreOPACarouselChecker przed ewaluacją OPA
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.risk.vat_carousel_detected",
    "package": "jdg.risk", "priority": 11,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_carousel_detected": true,
    "vat_carousel_type": carousel_type,
    "vat_carousel_entities": carousel_entities,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("VAT CAROUSEL DETECTED — %s: %d podmiotów", [carousel_type, entity_count]),
    "_legal_basis": "Art. 55 KKS, Art. 86 ust. 1 VAT, Art. 105a-105c VAT",
    "_warnings": [sprintf("KARUZELA VAT WYKRYTA! Typ: %s. Podmioty: %s. Natychmiastowa blokada + zgłoszenie MDR do KAS.", [carousel_type, concat(", ", carousel_entities)])]
} {
    carousel_detected := object.get(object.get(input, "risk", {}), "carousel_detected", false)
    carousel_detected == true
    carousel_type := object.get(object.get(input, "risk", {}), "carousel_type", "UNKNOWN")
    carousel_entities := object.get(object.get(input, "risk", {}), "carousel_entities", [])
    entity_count := count(carousel_entities)
}
