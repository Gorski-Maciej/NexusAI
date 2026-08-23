# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Micro Layer: zdrowotna_a79.rego (PROMPT 07 — ZUS MICRO)
# Package: jdg.micro.zdrowotna
# Art. 79 u.ś.o.z. — Składka na ubezpieczenie zdrowotne (9% dochodu, skala)
# (Dz.U. 2025 poz. 890)
# Zero hardcode: health_scale_rate z data.jdg.thresholds.zus
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.zdrowotna

import future.keywords.if
import future.keywords.in
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.zdrowotna.a79.no_match",
    "package": "jdg.micro.zdrowotna",
    "priority": 999999
}

# ── a79.r1: Składka zdrowotna skala — obliczenie 9% od dochodu ────────────────
# Art. 79 ust. 1 u.ś.o.z.: składka wynosi 9% podstawy wymiaru.
# Art. 81 ust. 1: podstawą wymiaru jest dochód z działalności (skala PIT).
# Składka NIE podlega odliczeniu od podatku PIT na skali (Polski Ład 2022).

decide := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.scale_calculation",
    "package": "jdg.micro.zdrowotna",
    "priority": 97901,
    "vat_rate": "", "rounding_level": "GROSZE", "gtu_code": "",
    "pit_form": "PIT_SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "0.09",
    "zus_health_base": "INCOME",
    "zus_health_base_min_pln": min_wage,
    "zus_health_monthly_pln": contribution,
    "zus_health_deductible_from_tax": false,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Składka zdrowotna 9% od dochodu — skala PIT (NIE odliczalna)",
    "_legal_basis": "Art. 79 ust. 1 w zw. z art. 81 ust. 1 ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "_warnings": [sprintf("[MICRO A79] Składka zdrowotna 9%%: %.2f PLN/mies (od dochodu %.2f PLN). NIE odliczasz od PIT na skali.", [contribution, income])]
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
    income := object.get(input.jdg_entrepreneur, "monthly_income_pln", 0)
    min_wage := object.get(object.get(thresholds, "zus", {}), "health_min_base_standard", 4800.00)
    effective_income := max([income, min_wage])
    rate := object.get(object.get(thresholds, "zus", {}), "health_scale_rate", 0.09)
    contribution := floor(effective_income * rate * 100) / 100
}

# ── a79.r2: Roczna korekta składki zdrowotnej skala ───────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a79.annual_settlement_scale",
    "package": "jdg.micro.zdrowotna",
    "priority": 97902,
    "vat_rate": "", "rounding_level": "GROSZE", "gtu_code": "",
    "pit_form": "PIT_SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "0.09",
    "zus_health_annual_due_pln": due,
    "zus_health_annual_paid_pln": paid,
    "zus_health_annual_diff_pln": diff,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Korekta roczna składki zdrowotnej — skala PIT",
    "_legal_basis": "Art. 79 ust. 1, art. 81 ust. 1 ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "_warnings": [sprintf("[MICRO A79] Roczne rozliczenie: należne %.2f PLN, wpłacone %.2f PLN. %s", [due, paid, action])]
} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_pln", 0)
    paid := object.get(input.jdg_entrepreneur, "health_contributions_paid_pln", 0)
    rate := object.get(object.get(thresholds, "zus", {}), "health_scale_rate", 0.09)
    due := floor(annual_income * rate * 100) / 100
    diff := due - paid
    action = sprintf("Dopłać %.2f PLN", [abs(diff)]) { diff > 0 }
    action = sprintf("Nadpłata %.2f PLN — ZUS zwróci", [abs(diff)]) { diff < 0 }
    action = "Rozliczenie zgodne" { diff == 0 }
    abs(diff) > 0.01
}