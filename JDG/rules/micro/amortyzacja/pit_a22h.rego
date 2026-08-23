# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: PIT — Art. 22h Zasady dokonywania odpisów
# amortyzacyjnych — RAPORT_GLM52_P06 (uzupełnienie mapy art. 22a-22o)
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Package: jdg.micro.amort_a22h
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.amort_a22h

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.amort_a22h.no_match",
    "package": "jdg.micro.amort_a22h",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  pit.a22h — Art. 22h Zasady odpisów: KUP, miesięczność, moment rozpoczęcia, ║
# ║  zawieszenie, invariant suma odpisów ≤ wartość początkowa                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.amort_a22h.r1: write_off_is_kup — odpisy amortyzacyjne = KUP (art. 22h ust. 1)
decide := {
    "matched": true, "rule_id": "jdg.micro.amort_a22h.r1",
    "package": "jdg.micro.amort_a22h", "priority": 81601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "depreciation_is_cost": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22h ust. 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22h PIT: Odpis amortyzacyjny %.2f PLN = KUP (miesięcznie, od miesiąca następującego po przyjęciu ŚT).", [monthly_write_off])]
} {
    object.get(input.invoice, "depreciation_write_off_pln", 0) > 0
    monthly_write_off := object.get(input.invoice, "depreciation_monthly_pln", 0)
}

# jdg.micro.amort_a22h.r2: start_after_acceptance — pierwszy odpis po przyjęciu (art. 22h ust. 1 pkt 1)
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22h.r2",
    "package": "jdg.micro.amort_a22h", "priority": 81602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "depreciation_start_month": start_month,
    "depreciation_start_ok": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22h ust. 1 pkt 1 PIT",
    "_warnings": [sprintf("[MICRO] Art.22h PIT: Amortyzacja od %s — pierwszego miesiąca następującego po miesiącu przyjęcia ŚT do używania (%s).", [start_month, acceptance_month])]
} {
    acceptance_month := object.get(input.invoice, "asset_acceptance_month", "")
    start_month := object.get(input.invoice, "first_depreciation_month", "")
    acceptance_month != ""
    start_month != ""
}

# jdg.micro.amort_a22h.r3: blocked_depreciation_before_acceptance — odpis przed przyjęciem = NKUP
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22h.r3",
    "package": "jdg.micro.amort_a22h", "priority": 81603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Odpis przed przyjęciem ŚT do używania = NKUP (art. 22h ust. 1 pkt 1)",
    "_legal_basis": "Art. 22h ust. 1 pkt 1 PIT",
    "_warnings": ["[MICRO] Art.22h PIT: BLOCK — odpis amortyzacyjny NIE może być dokonany przed przyjęciem ŚT do używania. Korekta: przenieś odpis na pierwszy miesiąc po przyjęciu."]
} {
    object.get(input.invoice, "depreciation_write_off_pln", 0) > 0
    object.get(input.invoice, "asset_ready_for_use", false) == false
}

# jdg.micro.amort_a22h.r4: suspension — zawieszenie odpisów (art. 22h ust. 3)
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22h.r4",
    "package": "jdg.micro.amort_a22h", "priority": 81604,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true, "depreciation_suspended": true,
    "suspension_reason": reason,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Zawieszenie amortyzacji: %s — odpisów nie dokonuje się, ale nie tracisz prawa do nich później.", [reason]),
    "_legal_basis": "Art. 22h ust. 3 PIT (zawieszenie odpisów)",
    "_warnings": [sprintf("[MICRO] Art.22h PIT: ZAWIESZENIE odpisów (%s) — nie dokonujesz odpisów w okresie zawieszenia; po wznowieniu amortyzacja trwa dalej.", [reason])]
} {
    object.get(input.invoice, "depreciation_suspended", false) == true
    reason = "brak przychodów z działalności" { object.get(input.invoice, "suspension_reason", "") == "NO_REVENUE" }
    reason = "wyłączenie ŚT z używania" { object.get(input.invoice, "suspension_reason", "") == "NOT_USED" }
    reason = "inna przyczyna" { true }
}

# jdg.micro.amort_a22h.r5: invariant_depreciation_not_exceed_initial — invariant: suma odpisów ≤ wartość początkowa
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22h.r5",
    "package": "jdg.micro.amort_a22h", "priority": 81605,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "KUP_DEDUCTIBLE", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "cumulative_write_offs": cumulative,
    "initial_value": initial_value,
    "write_offs_ok": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 22h ust. 1 PIT (invariant F2: suma odpisów ≤ wartość początkowa)",
    "_warnings": [sprintf("[MICRO] Art.22h PIT: INVARIANT OK — suma odpisów %.2f PLN ≤ wartość początkowa %.2f PLN. Wartość netto: %.2f PLN.", [cumulative, initial_value, net_value])]
} {
    initial_value := object.get(input.invoice, "asset_initial_value", 0)
    cumulative := object.get(input.invoice, "cumulative_depreciation_pln", 0)
    cumulative <= initial_value
    net_value := initial_value - cumulative
}

# jdg.micro.amort_a22h.r6: blocked_write_offs_exceed_initial — BLOCK: przekroczenie wartości początkowej
else := {
    "matched": true, "rule_id": "jdg.micro.amort_a22h.r6",
    "package": "jdg.micro.amort_a22h", "priority": 81606,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Suma odpisów %.2f PLN PRZEKRACZA wartość początkową %.2f PLN — naruszenie invarianta F2!", [cumulative, initial_value]),
    "_legal_basis": "Art. 22h ust. 1 PIT (invariant F2: suma odpisów ≤ wartość początkowa)",
    "_warnings": [sprintf("[MICRO] Art.22h PIT: BLOCK — suma odpisów amortyzacyjnych (%.2f PLN) przekracza wartość początkową (%.2f PLN). Nadwyżka = NKUP!", [cumulative, initial_value])]
} {
    initial_value := object.get(input.invoice, "asset_initial_value", 0)
    cumulative := object.get(input.invoice, "cumulative_depreciation_pln", 0)
    cumulative > initial_value
}

# ── Bez fallbacka catch-all (konwencja micro warstwy: brak dopasowania → default no_match).
