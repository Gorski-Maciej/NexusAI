# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: BDO — Ewidencja i KPO (P1909-P1911 → 10 reguł)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Package: jdg.micro.bdo_ewidencja
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.bdo_ewidencja

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.bdo_ewidencja.no_match",
    "package": "jdg.micro.bdo_ewidencja",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  BDO Ewidencja/KPO — Kwartalna ewidencja, karty przekazania (10 reguł)   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.bdo_ewidencja.r1: ledger_q1_deadline — termin Q1: 30 kwietnia
decide := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewidencja.r1",
    "package": "jdg.micro.bdo_ewidencja", "priority": 82201,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 66 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO EWIDENCJA: Q1 (styczeń-marzec) — termin: 30 kwietnia. Odpady: %.2f ton, %d KPO.", [tonnes, kpo])]
} {
    input.business.bdo_registered == true
    object.get(input.calendar, "month", 4) == 4
    tonnes := object.get(input.business, "waste_q1_tonnes", 0)
    kpo := object.get(input.business, "kpo_q1_count", 0)
    tonnes > 0
}

# jdg.micro.bdo_ewidencja.r2: ledger_q2_deadline — termin Q2: 31 lipca
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewidencja.r2",
    "package": "jdg.micro.bdo_ewidencja", "priority": 82202,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 66 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO EWIDENCJA: Q2 (kwiecień-czerwiec) — termin: 31 lipca. Odpady: %.2f ton, %d KPO.", [tonnes, kpo])]
} {
    input.business.bdo_registered == true
    object.get(input.calendar, "month", 7) == 7
    tonnes := object.get(input.business, "waste_q2_tonnes", 0)
    kpo := object.get(input.business, "kpo_q2_count", 0)
    tonnes > 0
}

# jdg.micro.bdo_ewidencja.r3: ledger_q3_deadline — termin Q3: 31 października
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewidencja.r3",
    "package": "jdg.micro.bdo_ewidencja", "priority": 82203,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 66 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO EWIDENCJA: Q3 (lipiec-wrzesień) — termin: 31 października. Odpady: %.2f ton, %d KPO.", [tonnes, kpo])]
} {
    input.business.bdo_registered == true
    object.get(input.calendar, "month", 10) == 10
    tonnes := object.get(input.business, "waste_q3_tonnes", 0)
    kpo := object.get(input.business, "kpo_q3_count", 0)
    tonnes > 0
}

# jdg.micro.bdo_ewidencja.r4: ledger_q4_deadline — termin Q4: 31 stycznia
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewidencja.r4",
    "package": "jdg.micro.bdo_ewidencja", "priority": 82204,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 66 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO EWIDENCJA: Q4 (październik-grudzień) — termin: 31 stycznia %d. Odpady: %.2f ton, %d KPO.", [next_year, tonnes, kpo])]
} {
    input.business.bdo_registered == true
    object.get(input.calendar, "month", 1) == 1
    tonnes := object.get(input.business, "waste_q4_tonnes", 0)
    kpo := object.get(input.business, "kpo_q4_count", 0)
    next_year := object.get(input.calendar, "year", 2026)
    tonnes > 0
}

# jdg.micro.bdo_ewidencja.r5: annual_report_deadline — sprawozdanie roczne
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewidencja.r5",
    "package": "jdg.micro.bdo_ewidencja", "priority": 82205,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("BDO — sprawozdanie roczne za %d do 15 marca %d.", [prev_year, year]),
    "_legal_basis": "Art. 75 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO SPRAWOZDANIE ROCZNE za %d — złóż do 15 marca %d. Zawartość: masa odpadów wg EWC, sposób zagospodarowania, poziom recyklingu. Brak = kara!", [prev_year, year])]
} {
    input.business.bdo_registered == true
    month := object.get(input.calendar, "month", 2)
    month == 2
    year := object.get(input.calendar, "year", 2026)
    prev_year := year - 1
    object.get(input.business, "bdo_annual_report_filed", false) == false
}

# jdg.micro.bdo_ewidencja.r6: kpo_electronic_unconfirmed — KPO bez potwierdzenia
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewidencja.r6",
    "package": "jdg.micro.bdo_ewidencja", "priority": 82206,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("%d KPO bez elektronicznego potwierdzenia odbiorcy!", [unconfirmed]),
    "_legal_basis": "Art. 67 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO KPO: %d kart przekazania BEZ POTWIERDZENIA odbiorcy. KPO MUSI być potwierdzona elektronicznie w ciągu 7 dni przez odbiorcę. Podpis: profil zaufany / e-dowód / kwalifikowany.", [unconfirmed])]
} {
    input.business.waste_transported == true
    unconfirmed := object.get(input.business, "bdo_kpo_unconfirmed_count", 0)
    unconfirmed > 0
}

# jdg.micro.bdo_ewidencja.r7: kpo_electronic_ok — KPO potwierdzone
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewidencja.r7",
    "package": "jdg.micro.bdo_ewidencja", "priority": 82207,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 67 Ustawy o odpadach",
    "_warnings": [sprintf("[MICRO] BDO KPO: %d kart przekazania POTWIERDZONYCH elektronicznie — OK.", [confirmed])]
} {
    input.business.waste_transported == true
    confirmed := object.get(input.business, "bdo_kpo_confirmed_count", 0)
    confirmed > 0
}

# jdg.micro.bdo_ewidencja.r8: kpo_retention — przechowywanie KPO 5 lat
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewidencja.r8",
    "package": "jdg.micro.bdo_ewidencja", "priority": 82208,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 69 Ustawy o odpadach",
    "_warnings": ["[MICRO] BDO KPO: Przechowuj karty przekazania odpadów przez 5 lat od końca roku kalendarzowego. Format elektroniczny w systemie BDO + backup lokalny."]
} {
    input.business.bdo_registered == true
    object.get(input.business, "kpo_retention_verified", true) == false
}

# ── Fallback ──────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.micro.bdo_ewidencja.fallback",
    "package": "jdg.micro.bdo_ewidencja", "priority": 82299,
    "micro_rule_active": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)",
    "_warnings": ["[MICRO] BDO ewidencja — poza terminem sprawozdawczym lub brak odpadów w kwartale."]
} { true }
