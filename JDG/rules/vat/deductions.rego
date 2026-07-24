# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — VAT: Odliczenia, korekty, auta, złe długi (P183-P192)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: VAT Deductions — Blocked Categories, Bad Debt, Vehicles, Pre-Proportion
# description: |
#   PAS 4b Multi-Pass. First-Match-Wins else-chain. Odliczenia VAT:
#   kategorie zablokowane (P183), OBOWIĄZEK korekty dłużnika 90 dni (P184),
#   pre-proporcja (P185), auto 50%/100% (P186/P186b), korekta roczna (P187),
#   termin 3m (P188), ulga wierzyciela 150 dni (P189), import (P191),
#   zwroty 60/25 dni (P192).
# architecture: Multi-Pass PAS 4b (ADR-001)
# legal_basis: Art. 86-91, 89a-89b VAT
# edge_cases:
#   - P184: sankcja 30% za brak korekty dłużnika (BLOCK_AND_ALERT)
#   - P185: de minimis <2% → 0% odliczenia
#   - P188: months_since_issue > 3 → termin bezpowrotnie minął
# package: jdg.vat.deductions
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
#
# Architektura: First-Match-Wins else-chain
# Podstawa: Doc 34 Sec 4.5 + Doc 33 (Art. 86-89b VAT)
#
# package: jdg.vat.deductions
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat.deductions

import data.jdg.helpers

# ── Default ────────────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.vat.deductions.no_match",
    "package": "jdg.vat.deductions",
    "priority": 202
}

# ═══════════════════════════════════════════════════════════════════════════════
# P39: vat_r_registration_status — Blokada faktur VAT bez rejestracji VAT-R
# ═══════════════════════════════════════════════════════════════════════════════
# Doc 26 §II: Blokada wystawiania faktur z VAT przez JDG bez VAT-R
# ⚠️ Musi być PRZED P183 — sprawdzenie rejestracji przed odliczeniami
decide := {
    "matched":true,"rule_id":"jdg.vat.deductions.vat_r_registration_block",
    "package":"jdg.vat.deductions","priority":39,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "procedure":"VAT_R_BLOCK","vat_exemption":"",
    "vat_deduction_percent":0,"pit_form":"","pit_rate":"",
    "pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "vat_r_filing_required":true,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Brak rejestracji VAT-R — nie można wystawiać faktur z VAT",
    "_legal_basis":"Art. 96 ust. 1, 4-5 VAT",
    "_warnings":["Brak rejestracji VAT-R — nie możesz wystawiać faktur z VAT. Złóż VAT-R przed pierwszą czynnością opodatkowaną."]
} {
    input.invoice.direction == "SALE"
    input.invoice.vat_taxable == true
    input.jdg_entrepreneur.is_vat_payer == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P183: vat_blocked_categories — Kategorie wyłączone z odliczenia VAT
# Pełna lista wyłączeń Art. 88 VAT (MR-5 v7.0 — rozszerzona z 6 do 20+ pozycji)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.blocked_categories",
    "package": "jdg.vat.deductions", "priority": 183,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_BLOCKED", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": sprintf("VAT blocked category: %s", [input.invoice.category_code]),
    "_legal_basis": "Art. 88 ust. 1 VAT",
    "_warnings": [sprintf("Kategoria %s — VAT NIE podlega odliczeniu (Art. 88 VAT)", [input.invoice.category_code])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {
        # Art. 88 ust. 1 pkt 1: usługi noclegowe i gastronomiczne (z wyjątkami)
        "HOTEL", "RESTAURANT_MEALS", "CATERING",
        # Art. 88 ust. 1 pkt 2: wydatki osobiste i reprezentacja
        "ENTERTAINMENT", "REPRESENTATION", "ALCOHOL", "PERSONAL_EXPENSE",
        # Art. 88 ust. 1 pkt 3: paliwo do samochodów osobowych
        "CAR_FUEL_PASSENGER",
        # Art. 88 ust. 3a pkt 1: faktury od podmiotu niezarejestrowanego VAT
        "UNREGISTERED_VENDOR",
        # Art. 88 ust. 3a pkt 2: transakcje niepotwierdzone
        "UNCONFIRMED_TRANSACTION",
        # Art. 88 ust. 3a pkt 3: faktury poświadczające nieprawdę
        "FALSE_INVOICE",
        # Art. 88 ust. 3a pkt 4: faktury dokumentujące czynności niepodlegające
        "NON_TAXABLE_ACTIVITY",
        # Art. 88 ust. 3a pkt 5: faktury z ceną rażąco zawyżoną
        "GROSSLY_INFLATED_PRICE",
        # Art. 88 ust. 3a pkt 7: faktury od podmiotu nieistniejącego
        "NONEXISTENT_ENTITY",
        # Art. 88 ust. 3a pkt 8: faktury z niezgodnym stanem faktycznym
        "FACTUAL_MISMATCH",
        # Art. 88 ust. 4 pkt 1: usługi gastronomiczne i noclegowe
        "GASTRONOMY_SERVICES",
        # Art. 88 ust. 4 pkt 2: nabycie towarów przez komornika sądowego
        "BAILIFF_PURCHASE",
        # Art. 88 ust. 4 pkt 3: nabycie dzieł sztuki przez podatnika nie-artystę
        "ARTWORK_NON_ARTIST",
        # Art. 88 ust. 5 pkt 1: nabycie złota inwestycyjnego
        "INVESTMENT_GOLD"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P183b: vat_blocked_cn_specific — Specyficzne wyłączenia CN (Art. 88 VAT) v7.0
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.blocked_cn_specific",
    "package": "jdg.vat.deductions", "priority": 183,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_BLOCKED_CN", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "CN code na liście wyłączeń Art. 88 VAT",
    "_legal_basis": "Art. 88 ust. 1 pkt 3, zał. do VAT",
    "_warnings": [sprintf("Kod CN %s na liście wyłączeń Art. 88 VAT — paliwo do samochodów osobowych. Odliczenie niemożliwe.", [cn_code])]
} {
    input.invoice.direction == "PURCHASE"
    cn_code := object.get(input.invoice, "cn_code", "")
    # CN 2710 = oleje ropy naftowej (paliwo) — wyłączone dla osobówek
    cn_code in {"2710", "27101141", "27101145", "27101149", "27101151", "27101159", "27101941", "27101943", "27101945"}
    input.invoice.vehicle_type == "PASSENGER_CAR"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P183c: vat_bad_debt_debtor_exceptions — Wyjątki od obowiązku korekty dłużnika (Art. 89b ust. 2 VAT) v7.0
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.bad_debt_debtor_exception",
    "package": "jdg.vat.deductions", "priority": 183,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_DEBTOR_EXCEPTION", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bad_debt_exception": true,
    "_routing": "", "_routing_reason": "Wyjątek od obowiązku korekty dłużnika",
    "_legal_basis": "Art. 89b ust. 2 VAT",
    "_warnings": [sprintf("Wyjątek od korekty dłużnika: %s. Korekta VAT NIE jest obowiązkowa.", [exception_reason])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.is_paid == false
    input.invoice.days_overdue >= 90
    # Wyjątki (Art. 89b ust. 2 VAT):
    # 1. Dłużnik nie jest podatnikiem VAT (zwolniony podmiotowo)
    input.vendor.is_vat_payer == false
    exception_reason := "dłużnik nie jest podatnikiem VAT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P184: bad_debt_debtor_correction_mandatory — OBOWIĄZEK dłużnika korekty VAT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.bad_debt_debtor_mandatory",
    "package": "jdg.vat.deductions", "priority": 184,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_DEBTOR_CORRECTION", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "OBOWIĄZEK korekty VAT in minus po 90 dniach niezapłacenia",
    "_legal_basis": "Art. 89b VAT",
    "_warnings": ["OBOWIĄZEK dłużnika: korekta VAT in minus po 90 dniach. Sankcja 30% za brak korekty!"],
    "_future_events": [{
        "event_id":"bad_debt_debtor_vat_correction",
        "event_type":"TAX_OBLIGATION",
        "description":"Korekta VAT in minus po 90 dniach — OBOWIĄZEK w deklaracji JPK_V7",
        "due_date_horizon":"+7d",
        "action":"FILE_VAT_CORRECTION_JPK_V7",
        "priority":"CRITICAL"
    }]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.is_paid == false
    input.invoice.is_vat_deducted == true
    input.invoice.days_overdue >= 90
}

# ═══════════════════════════════════════════════════════════════════════════════
# P185: vat_pre_proportion_mixed — Pre-proporcja VAT dla wydatków mieszanych
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.pre_proportion_mixed",
    "package": "jdg.vat.deductions", "priority": 185,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "PRE_PROPORTION", "vat_exemption": "",
    "vat_deduction_percent": vat_deduction_percent, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86 ust. 2a-2h VAT",
    "_warnings": []
} {
    input.invoice.direction == "PURCHASE"
    input.jdg_entrepreneur.vat_proportion < 1.0
    vat_proportion := object.get(input.jdg_entrepreneur, "vat_proportion", 1.0)
    vat_deduction_percent := floor(vat_proportion * 100)

    # De minimis: < 2% → 0%
    vat_proportion >= 0.02
} else := {
    "matched": true, "rule_id": "jdg.vat.deductions.pre_proportion_de_minimis",
    "package": "jdg.vat.deductions", "priority": 185,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "PRE_PROPORTION_DE_MINIMIS", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "Proporcja < 2% — brak odliczenia VAT",
    "_legal_basis": "Art. 86 ust. 2g VAT",
    "_warnings": ["Proporcja VAT < 2% — brak prawa do odliczenia"]
} {
    vat_proportion := object.get(input.jdg_entrepreneur, "vat_proportion", 1.0)
    vat_proportion < 0.02
    vat_proportion > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P186: vehicle_50_vat_deduction — Auto mieszane → 50% VAT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.vehicle_50pct",
    "package": "jdg.vat.deductions", "priority": 186,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VEHICLE_50PCT", "vat_exemption": "",
    "vat_deduction_percent": 50, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86a VAT",
    "_warnings": ["Samochód mieszany — odliczenie 50% VAT"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code == "CAR"
    input.invoice.private_use_percent > 0
    input.invoice.has_mileage_log == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P186b: vehicle_100_vat_deduction — Auto z ewidencją → 100% VAT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.vehicle_100pct",
    "package": "jdg.vat.deductions", "priority": 186,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VEHICLE_100PCT", "vat_exemption": "",
    "vat_deduction_percent": 100, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86a VAT",
    "_warnings": ["Samochód z ewidencją przebiegu — odliczenie 100% VAT"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code == "CAR"
    input.invoice.has_mileage_log == true
    input.invoice.private_use_percent == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P187: annual_vat_correction_assets — Roczna korekta VAT dla środków trwałych
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.annual_correction_assets",
    "package": "jdg.vat.deductions", "priority": 187,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "ANNUAL_CORRECTION", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 91 VAT",
    "_warnings": ["Roczna korekta VAT dla środków trwałych — 1/5 przez 5 lat (ruchomości) lub 1/10 przez 10 lat (nieruchomości)"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type == "FIXED_ASSET"
    input.jdg_entrepreneur.tax_year_end != null
}

# ═══════════════════════════════════════════════════════════════════════════════
# P188: vat_deduction_deadline_3m — Termin odliczenia VAT: 3 miesiące
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.deadline_3m_expired",
    "package": "jdg.vat.deductions", "priority": 188,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "DEADLINE_EXPIRED", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Przekroczony 3-miesięczny termin odliczenia VAT",
    "_legal_basis": "Art. 86 ust. 11 VAT",
    "_warnings": ["Przekroczony termin odliczenia VAT (3 miesiące) — odliczenie NIEMOŻLIWE"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.months_since_issue > 3
    input.invoice.is_vat_deducted == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# P189: bad_debt_relief_creditor — Ulga złe długi VAT (wierzyciel)
# P189_TEMPORAL_FIX: 150 dni dla transakcji sprzed SLIM VAT 3 (przed 2023-01-01),
# 90 dni dla transakcji od 2023-01-01 (SLIM VAT 3 zmiana Art. 89a ust. 1a VAT)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.bad_debt_creditor_150d_pre_slim3",
    "package": "jdg.vat.deductions", "priority": 189,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_CREDITOR_150D", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "temporal_version": "PRE_SLIM_VAT_3", "bad_debt_threshold_days": 150,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 89a VAT (brzmienie przed SLIM VAT 3, obowiązujące do 2022-12-31)",
    "_warnings": [sprintf("Ulga na złe długi (PRZED SLIM VAT 3): wierzyciel może skorygować VAT po 150 dniach. Transakcja z %s, stan prawny sprzed 2023.", [tx_date])]
} {
    input.invoice.direction == "SALE"
    input.invoice.is_paid == false
    tx_date := object.get(input.invoice, "transaction_date", "")
    tx_date < "2023-01-01"
    input.invoice.days_overdue >= 150
    input.invoice.debtor_notified == true
}

# P189b: bad_debt_relief_creditor_90d_post_slim3 — SLIM VAT 3: 90 dni
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.bad_debt_creditor_90d_post_slim3",
    "package": "jdg.vat.deductions", "priority": 189,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_CREDITOR_90D", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "temporal_version": "POST_SLIM_VAT_3", "bad_debt_threshold_days": 90,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 89a ust. 1a VAT (brzmienie po SLIM VAT 3, obowiązujące od 2023-01-01)",
    "_warnings": ["Ulga na złe długi (PO SLIM VAT 3): wierzyciel może skorygować VAT po 90 dniach + zawiadomieniu dłużnika"]
} {
    input.invoice.direction == "SALE"
    input.invoice.is_paid == false
    tx_date := object.get(input.invoice, "transaction_date", "")
    tx_date >= "2023-01-01"
    input.invoice.days_overdue >= 90
    input.invoice.debtor_notified == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P191: import_vat_deduction_timing — Odliczenie VAT od importu wg dokumentu celnego
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.import_timing",
    "package": "jdg.vat.deductions", "priority": 191,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "IMPORT_DEDUCTION", "vat_exemption": "",
    "vat_deduction_percent": 100, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86 ust. 2 pkt 2 VAT",
    "_warnings": ["Import — odliczenie VAT na podstawie dokumentu celnego SAD"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.procedure == "IMPORT"
    input.invoice.has_customs_document == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P192: vat_refund_timing — Zwrot VAT: terminy
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.refund_standard_60d",
    "package": "jdg.vat.deductions", "priority": 192,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_REFUND", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 87 VAT",
    "_warnings": []
} {
    input.invoice.procedure == "VAT_REFUND"
    input.jdg_entrepreneur.is_vat_payer == true
    # Standard return: 60 days
    input.invoice.vat_refund_type == "STANDARD"
} else := {
    "matched": true, "rule_id": "jdg.vat.deductions.refund_accelerated_25d",
    "package": "jdg.vat.deductions", "priority": 192,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_REFUND_ACCELERATED", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 87 ust. 6 VAT",
    "_warnings": ["Zwrot VAT przyśpieszony — 25 dni"]
} {
    input.invoice.procedure == "VAT_REFUND"
    input.invoice.vat_refund_type == "ACCELERATED"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P193-P201: WNT, Import Usług, Reverse Charge — Dedukcje VAT
# ═══════════════════════════════════════════════════════════════════════════════

# P193: wnt_deduction_same_period — WNT: odliczenie w tym samym okresie co VAT należny
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.wnt_same_period",
    "package": "jdg.vat.deductions", "priority": 193,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "WNT_DEDUCTION", "vat_exemption": "",
    "vat_deduction_percent": 100, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86 ust. 2 pkt 4 VAT",
    "_warnings": ["WNT — odliczenie VAT naliczonego w tym samym okresie co VAT należny (Art. 86 ust. 10b pkt 1 VAT). JPK_V7: pole K_41."]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.procedure in {"WNT", "INTRA_EU_PURCHASE"}
    input.invoice.has_vat_invoice == true
}

# P194: wnt_deduction_3months — WNT: odliczenie w ciągu 3 miesięcy
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.wnt_3months",
    "package": "jdg.vat.deductions", "priority": 194,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "WNT_DEDUCTION_3M", "vat_exemption": "",
    "vat_deduction_percent": 100, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "WNT — odliczenie po okresie powstania obowiązku, w ciągu 3 miesięcy",
    "_legal_basis": "Art. 86 ust. 10b pkt 2 VAT",
    "_warnings": ["WNT — odliczenie VAT w ciągu 3 miesięcy od powstania obowiązku podatkowego (korekta JPK_V7 wstecz)"]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.procedure in {"WNT", "INTRA_EU_PURCHASE"}
    input.invoice.months_since_wnt_obligation <= 3
    input.invoice.wnt_deducted_same_period == false
}

# P195: wnt_deduction_expired — WNT: termin odliczenia bezpowrotnie minął
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.wnt_expired",
    "package": "jdg.vat.deductions", "priority": 195,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "WNT_DEDUCTION_EXPIRED", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT", "_routing_reason": "WNT — przekroczony 3-miesięczny termin odliczenia VAT",
    "_legal_basis": "Art. 86 ust. 10b pkt 2 VAT",
    "_warnings": ["WNT — termin odliczenia VAT minął (>3 miesiące). Odliczenie NIEMOŻLIWE. Rozważ czynny żal."]
} {
    input.invoice.procedure in {"WNT", "INTRA_EU_PURCHASE"}
    input.invoice.months_since_wnt_obligation > 3
}

# P196: import_services_deduction — Import usług: odliczenie VAT naliczonego
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.import_services",
    "package": "jdg.vat.deductions", "priority": 196,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "IMPORT_SERVICES_DEDUCTION", "vat_exemption": "",
    "vat_deduction_percent": 100, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86 ust. 2 pkt 4 VAT",
    "_warnings": ["IMPORT USŁUG — odliczenie VAT naliczonego w tym samym okresie. JPK_V7: K_43 (UE) / K_44 (spoza UE)."]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.procedure in {"IMPORT_OF_SERVICES", "IMPORT_SERVICES_EU", "IMPORT_SERVICES_NON_EU"}
    input.invoice.place_of_supply == "PL"
}

# P197: import_goods_deduction — Import towarów: odliczenie VAT z SAD
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.import_goods_sad",
    "package": "jdg.vat.deductions", "priority": 197,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "IMPORT_GOODS_DEDUCTION", "vat_exemption": "",
    "vat_deduction_percent": 100, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86 ust. 2 pkt 2 VAT",
    "_warnings": ["IMPORT TOWARÓW — odliczenie VAT na podstawie dokumentu celnego SAD. Kurs Tabela C NBP."]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.procedure == "IMPORT_CUSTOMS"
    input.invoice.has_customs_document == true
}

# P198: reverse_charge_deduction — Odwrotne obciążenie: VAT należny = VAT naliczony
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.reverse_charge_deduction",
    "package": "jdg.vat.deductions", "priority": 198,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "REVERSE_CHARGE_DEDUCTION", "vat_exemption": "",
    "vat_deduction_percent": 100, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86 ust. 2 pkt 4 VAT",
    "_warnings": ["ODWROTNE OBCIĄŻENIE — VAT należny = VAT naliczony (efekt neutralny). Odliczenie w tym samym okresie."]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.procedure in {"REVERSE_CHARGE_DOMESTIC", "REVERSE_CHARGE_CONSTRUCTION", "REVERSE_CHARGE_WASTE", "REVERSE_CHARGE_METALS", "REVERSE_CHARGE_CO2"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# P199-P204: Rozszerzone Bad Debt + VAT-ZT + Sankcje
# ═══════════════════════════════════════════════════════════════════════════════

# P199: bad_debt_creditor_correction_required — Ulga złe długi: warunki szczegółowe
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.bad_debt_creditor_correction",
    "package": "jdg.vat.deductions", "priority": 199,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_CREDITOR_CORRECTION", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 89a ust. 1-2 VAT",
    "_warnings": [sprintf("ULGA NA ZŁE DŁUGI: %.2f PLN VAT do korekty (wierzyciel). JPK_V7: pozycja K_45. Pamiętaj o zawiadomieniu dłużnika przed korektą!", [vat_to_correct])]
} {
    input.invoice.direction == "SALE"
    input.invoice.is_paid == false
    input.invoice.days_overdue >= 150
    input.invoice.debtor_notified == true
    input.invoice.debtor_is_vat_payer == true
    # Oblicz VAT z faktury (netto × stawka) — vat_amount nie jest ustawiane przez substantive.rego
    amount_net := object.get(input.invoice, "amount_net", 0)
    vat_rate_str := object.get(input.invoice, "vat_rate", "0.23")
    vat_to_correct := amount_net * to_number(vat_rate_str)
    vat_to_correct > 0
}

# P200: bad_debt_reversal_on_payment — Obowiązek odwrócenia ulgi przy zapłacie
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.bad_debt_reversal_on_payment",
    "package": "jdg.vat.deductions", "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_REVERSAL", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Ulga na złe długi — dłużnik zapłacił, OBOWIĄZEK odwrócenia",
    "_legal_basis": "Art. 89a ust. 4 VAT",
    "_warnings": ["ODWRÓCENIE ULGI ZŁE DŁUGI — dłużnik uregulował należność. Zwiększ VAT należny w bieżącym okresie o kwotę wcześniej skorygowaną."]
} {
    input.invoice.direction == "SALE"
    input.invoice.bad_debt_correction_applied == true
    input.invoice.is_paid == true
    input.invoice.payment_date != ""
}

# P201: bad_debt_creditor_bankruptcy — Ulga złe długi: upadłość dłużnika
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.bad_debt_bankruptcy",
    "package": "jdg.vat.deductions", "priority": 201,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_BANKRUPTCY", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 89a ust. 2 pkt 1-3 VAT",
    "_warnings": ["ULGA ZŁE DŁUGI — dłużnik w upadłości/likwidacji. Możliwa korekta VAT bez zawiadomienia dłużnika (Art. 89a ust. 2 pkt 3 VAT)."]
} {
    input.invoice.days_overdue >= 150
    input.invoice.is_paid == false
    input.invoice.debtor_in_bankruptcy == true
}

# P202: vat_zt_deduction_correction — Korekta odliczeń w VAT-ZT
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.vat_zt_deduction_correction",
    "package": "jdg.vat.deductions", "priority": 202,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_ZT_DEDUCTION_CORRECTION", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Korekta VAT-ZT — weryfikacja odliczeń historycznych",
    "_legal_basis": "Art. 86 ust. 10-13 VAT",
    "_warnings": ["KOREKTA VAT-ZT ODLICZEŃ — sprawdź czy odliczenia w okresach historycznych były prawidłowe. Korekta +/- w bieżącej deklaracji."]
} {
    input.jdg_entrepreneur.vat_zt_required == true
    input.invoice.is_vat_deducted == true
}

# P203: vat_sanction_deduction_block — Blokada odliczeń przy sankcji VAT
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.sanction_deduction_block",
    "package": "jdg.vat.deductions", "priority": 203,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_SANCTION_BLOCK", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Blokada odliczeń VAT — podatnik objęty sankcją",
    "_legal_basis": "Art. 108a ust. 5 VAT, Art. 96 ust. 3 VAT",
    "_warnings": ["BLOKADA ODLICZEŃ VAT — sankcja 30%%. Odliczenie NIEMOŻLIWE dla faktur bez MPP przy obowiązku."]
} {
    input.invoice.split_payment_mandatory_breached == true
}

# P204: cross_border_deduction_summary — Podsumowanie odliczeń transgranicznych
else := {
    "matched": true, "rule_id": "jdg.vat.deductions.cross_border_summary",
    "package": "jdg.vat.deductions", "priority": 204,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "CROSS_BORDER_SUMMARY", "vat_exemption": "",
    "vat_deduction_percent": 0, "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_v7_cross_border_wnt": wnt_total,
    "jpk_v7_cross_border_import_services_eu": import_eu_total,
    "jpk_v7_cross_border_import_services_non_eu": import_non_eu_total,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86 ust. 2 pkt 4 VAT",
    "_warnings": [sprintf("PODSUMOWANIE TRANSGRANICZNE: WNT=%.2f PLN, Import usług UE=%.2f PLN, Import usług spoza UE=%.2f PLN. JPK_V7: pola K_41-K_44.", [wnt_total, import_eu_total, import_non_eu_total])]
} {
    input.jdg_entrepreneur.is_vat_payer == true
    is_period_end := object.get(input.invoice, "is_period_end", false)
    is_period_end == true
    wnt_total := object.get(input.invoice, "wnt_total", 0)
    import_eu_total := object.get(input.invoice, "import_services_eu_total", 0)
    import_non_eu_total := object.get(input.invoice, "import_services_non_eu_total", 0)
}
