# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Plan 23 PIT: Exemptions Layer (P30 L6 Full Expansion)
# ═══════════════════════════════════════════════════════════════════════════════
# Rozszerzony z 1 reguły → 6 reguł (P30 L6 fix)
# Pokrywa: PIT-0 shared limit 85 528 PLN, young relief, return relief,
# 4+ family relief, working senior relief, cross-relief interactions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.pit
import data.jdg.helpers
import data.jdg.thresholds

default decide := {"matched":false,"rule_id":"jdg.pit.no_match","package":"jdg.pit","priority":99999}

# ── EX-1: Shared Limit 85 528 PLN — Wspólny limit ulg PIT-0 ────────────────
decide := {"matched":true,"rule_id":"jdg.pit.exemption_interactions_shared_limit","package":"jdg.pit","priority":588,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "pit0_shared_limit":pit0_limit,"pit0_total_used":total_used,"pit0_remaining":remaining,
    "_routing":routing,"_routing_reason":routing_reason,
    "_legal_basis":"Art. 21 ust. 1 pkt 148,152,153,154 PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.has_pit0_reliefs == true
    pit0_limit := thresholds.pit.pit_relief_shared_limit
    total_used := object.get(input.jdg_entrepreneur, "pit0_total_used", 0)
    remaining = pit0_limit - total_used { total_used <= pit0_limit }
    remaining = 0 { total_used > pit0_limit }

    routing = "BLOCK_AND_ALERT" { remaining == 0; total_used > 0 }
    routing = "TRIAGE_QUEUE" { remaining < 10000; remaining > 0 }
    routing = "" { remaining >= 10000 }
    routing_reason = sprintf("PIT-0 LIMIT WYCZERPANY — %.0f/%.0f PLN", [total_used, pit0_limit]) { remaining == 0 }
    routing_reason = sprintf("PIT-0 — pozostało %.0f PLN z limitu %.0f PLN", [remaining, pit0_limit]) { remaining < 10000; remaining > 0 }
    routing_reason = "" { remaining >= 10000 }

    warnings = [sprintf("ULGI PIT-0 — wspólny limit 85 528 PLN. Wykorzystano: %.0f PLN, pozostało: %.0f PLN", [total_used, remaining])]
}

# ── EX-2: Young Relief (Art. 21 ust. 1 pkt 148) — Ulga dla młodych do 26 lat ─
else := {"matched":true,"rule_id":"jdg.pit.exemption_young_under_26","package":"jdg.pit","priority":590,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "pit0_young_applicable":true,"pit0_young_age":age,"pit0_young_limit":pit0_limit,
    "_routing":routing,"_routing_reason":routing_reason,
    "_legal_basis":"Art. 21 ust. 1 pkt 148 PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.taxpayer_age <= 26
    input.jdg_entrepreneur.employment_income > 0
    pit0_limit := thresholds.pit.pit_relief_shared_limit
    age := input.jdg_entrepreneur.taxpayer_age

    routing = "TRIAGE_QUEUE" { age == 26 }
    routing = "" { age < 26 }
    routing_reason = "ULGA MŁODYCH — ostatni rok (26 lat). Sprawdź dochód do dnia urodzin." { age == 26 }
    routing_reason = "" { age < 26 }

    warnings = [sprintf("ULGA DLA MŁODYCH (Art. 21 ust. 1 pkt 148) — wiek %d lat, limit wspólny %.0f PLN", [age, pit0_limit])]
}

# ── EX-3: Return Relief (Art. 21 ust. 1 pkt 152) — Ulga na powrót ──────────
else := {"matched":true,"rule_id":"jdg.pit.exemption_return_from_abroad","package":"jdg.pit","priority":591,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "pit0_return_applicable":true,"pit0_return_years":years_abroad,"pit0_return_limit":pit0_limit,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 21 ust. 1 pkt 152 PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.has_returned_from_abroad == true
    years_abroad := object.get(input.jdg_entrepreneur, "years_abroad_before_return", 0)
    years_abroad >= 3
    pit0_limit := thresholds.pit.pit_relief_shared_limit

    warnings = [sprintf("ULGA NA POWRÓT (Art. 21 ust. 1 pkt 152) — %d lat za granicą, limit %.0f PLN przez 4 lata", [years_abroad, pit0_limit])]
}

# ── EX-4: Family 4+ Relief (Art. 21 ust. 1 pkt 153) — Ulga dla rodzin 4+ ───
else := {"matched":true,"rule_id":"jdg.pit.exemption_family_4plus","package":"jdg.pit","priority":592,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "pit0_family_4plus_applicable":true,"pit0_family_children":children,"pit0_family_limit":pit0_limit,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 21 ust. 1 pkt 153 PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.children_count >= 4
    input.jdg_entrepreneur.tax_form in {"PIT_SCALE","LINEAR"}
    children := input.jdg_entrepreneur.children_count
    pit0_limit := thresholds.pit.pit_relief_shared_limit

    warnings = [sprintf("ULGA 4+ (Art. 21 ust. 1 pkt 153) — %d dzieci, limit %.0f PLN", [children, pit0_limit])]
}

# ── EX-5: Working Senior Relief (Art. 21 ust. 1 pkt 154) — Pracujący senior ─
else := {"matched":true,"rule_id":"jdg.pit.exemption_working_senior","package":"jdg.pit","priority":593,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "pit0_senior_applicable":true,"pit0_senior_age":age,"pit0_senior_limit":pit0_limit,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 21 ust. 1 pkt 154 PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.taxpayer_age >= 60
    input.jdg_entrepreneur.not_receiving_pension == true
    input.jdg_entrepreneur.employment_income > 0
    pit0_limit := thresholds.pit.pit_relief_shared_limit
    age := input.jdg_entrepreneur.taxpayer_age

    warnings = [sprintf("ULGA PRACUJĄCY SENIOR (Art. 21 ust. 1 pkt 154) — wiek %d lat, limit %.0f PLN", [age, pit0_limit])]
}

# ── EX-6: Cross-Relief Conflict Detector — Detekcja konfliktów ulg ──────────
else := {"matched":true,"rule_id":"jdg.pit.exemption_cross_relief_conflict","package":"jdg.pit","priority":595,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "cross_relief_active_count":active_count,"cross_relief_exceeds_limit":exceeds_limit,
    "_routing":routing,"_routing_reason":routing_reason,
    "_legal_basis":"Art. 21 ust. 1 pkt 148,152,153,154 PIT","_warnings":warnings}
{
    pit0_reliefs := object.get(input.jdg_entrepreneur, "pit0_active_reliefs", [])
    active_count := count(pit0_reliefs)
    active_count > 0

    pit0_limit := thresholds.pit.pit_relief_shared_limit
    total_used := object.get(input.jdg_entrepreneur, "pit0_total_used", 0)
    exceeds_limit = true { total_used > pit0_limit }
    exceeds_limit = false

    routing = "BLOCK_AND_ALERT" { exceeds_limit }
    routing = "" { not exceeds_limit }
    routing_reason = sprintf("LIMIT PIT-0 PRZEKROCZONY — %d aktywnych ulg, %.0f/%.0f PLN", [active_count, total_used, pit0_limit]) { exceeds_limit }
    routing_reason = sprintf("Ulgi PIT-0 — %d aktywnych, %.0f/%.0f PLN", [active_count, total_used, pit0_limit]) { not exceeds_limit }

    warnings = [sprintf("PIT-0 CROSS-RELIEF — %d ulg aktywnych. Limit wspólny: %.0f PLN. Suma: %.0f PLN. %s", [active_count, pit0_limit, total_used, "PRZEKROCZENIE!"])] { exceeds_limit }
    warnings = [sprintf("PIT-0 CROSS-RELIEF — %d ulg aktywnych. Limit wspólny: %.0f PLN. Suma: %.0f PLN ✓", [active_count, pit0_limit, total_used])] { not exceeds_limit }
}
