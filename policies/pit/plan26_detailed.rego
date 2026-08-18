# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Plan 26 PIT: Detailed Layer (P30 L2 Full Expansion)
# ═══════════════════════════════════════════════════════════════════════════════
# Rozszerzony z 1 reguły → 8 reguł (P30 L2 fix)
# Pokrywa: revenue exclusions, scale bracket, exit tax threshold,
# CFC aggregation, tax residency, small taxpayer, loss carry-forward
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.pit
import future.keywords.in
import data.jdg.helpers
import data.jdg.thresholds

default decide := {"matched":false,"rule_id":"jdg.pit.no_match","package":"jdg.pit","priority":99999}

# ── PIT-1: Revenue Exclusions — Wyłączenia z przychodu ──────────────────────
decide := {"matched":true,"rule_id":"jdg.pit.revenue_exclusions_detail","package":"jdg.pit","priority":508,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"",
    "_routing":"","_routing_reason":"Wyłączenia z przychodu — zwrot VAT, nadpłata ZUS, odszkodowania",
    "_legal_basis":"Art. 14 ust. 3 PIT","_warnings":[]}
{ input.invoice.direction == "SALE"; input.invoice.kus_qualification == "NKUP" }

# ── PIT-2: Tax Scale Bracket — Próg 120k z degresją kwoty wolnej ───────────
else := {"matched":true,"rule_id":"jdg.pit.scale_bracket_check","package":"jdg.pit","priority":510,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"PIT_SCALE","pit_rate":"","pit_bracket":bracket,
    "pit_annual_return_type":"PIT_36","pit_tax_free_applied":tax_free,
    "_routing":routing,"_routing_reason":routing_reason,
    "_legal_basis":"Art. 27 PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)
    threshold := thresholds.pit.scale_threshold
    tax_free_amount := thresholds.pit.tax_free_amount
    reducing := thresholds.pit.tax_reducing_amount

    tax_free = true { income <= tax_free_amount }
    tax_free = false { income > tax_free_amount }

    bracket = "LOW_12PCT" { income <= threshold }
    bracket = "HIGH_32PCT" { income > threshold }

    routing = "" { income <= threshold - 1000 }
    routing = "TRIAGE_QUEUE" { income > threshold - 1000; income < threshold + 1000 }
    routing_reason = sprintf("PRÓG SKALI %.2f PLN ≈ %d PLN — weryfikuj", [income, threshold]) { income > threshold - 1000; income < threshold + 1000 }
    routing_reason = "" { income <= threshold - 1000 }

    warnings = [sprintf("SKALA PIT 12/32%% — dochód %.2f PLN, kwota wolna %d PLN, zmniejszająca %d PLN", [income, tax_free_amount, reducing])]
}

# ── PIT-3: Exit Tax 4M Threshold — Próg 4 000 000 PLN ──────────────────────
else := {"matched":true,"rule_id":"jdg.pit.exit_tax_4m_threshold","package":"jdg.pit","priority":520,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "exit_tax_applicable":applicable,"exit_tax_threshold":threshold,"exit_tax_rate":rate,
    "_routing":routing,"_routing_reason":routing_reason,
    "_legal_basis":"Art. 30da PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.has_asset_transfer_abroad == true
    market_value := object.get(input.jdg_entrepreneur, "asset_transfer_market_value", 0)
    threshold := thresholds.pit.exit_tax_threshold
    rate := thresholds.pit.exit_tax_rate

    applicable = true { market_value > threshold }
    applicable = false

    routing = "BLOCK_AND_ALERT" { applicable }
    routing = "" { not applicable }
    routing_reason = sprintf("EXIT TAX — %.2f PLN > %.0f PLN. 19%% od niezrealizowanych zysków!", [market_value, threshold]) { applicable }
    routing_reason = "" { not applicable }

    warnings = [sprintf("EXIT TAX Art. 30da — przeniesienie %.2f PLN powyżej progu %.0f PLN", [market_value, threshold])] { applicable }
    warnings = [] { not applicable }
}

# ── PIT-4: CFC Aggregation — Agregacja spółek zagranicznych ─────────────────
else := {"matched":true,"rule_id":"jdg.pit.cfc_aggregation_check","package":"jdg.pit","priority":530,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "cfc_count":count,"cfc_passive_income":passive,
    "_routing":routing,"_routing_reason":routing_reason,
    "_legal_basis":"Art. 30f ust. 6-7 PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.has_cfc_entities == true
    entities := object.get(input.jdg_entrepreneur, "cfc_entities", [])
    count := count(entities)
    passive := sum([e.passive_income | some e in entities])
    count > 0

    routing = "TRIAGE_QUEUE"
    routing_reason = sprintf("CFC — %d spółek, dochód pasywny %.2f PLN", [count, passive])
    warnings = [sprintf("CFC Art. 30f — %d spółek zagr., %.2f PLN dochodu pasywnego. Sprawdź progi 50%%/33%%/14.25%%.", [count, passive])]
}

# ── PIT-5: Tax Residency 183 Days — Rezydencja podatkowa ───────────────────
else := {"matched":true,"rule_id":"jdg.pit.tax_residency_183_days","package":"jdg.pit","priority":540,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "residency_days":days,"residency_status":status,
    "_routing":routing,"_routing_reason":routing_reason,
    "_legal_basis":"Art. 3 ust. 1a-2a PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.has_foreign_connections == true
    days := object.get(input.jdg_entrepreneur, "days_in_poland_current_year", 0)
    status = "PL_RESIDENT" { days >= 183 }
    status = "NON_RESIDENT" { days < 183 }

    routing = "TRIAGE_QUEUE" { days >= 170; days < 183 }
    routing = "" { days < 170 }
    routing = "" { days >= 183 }
    routing_reason = sprintf("REZYDENCJA — %d/183 dni w PL, blisko progu", [days]) { days >= 170; days < 183 }
    routing_reason = "" { days < 170 }

    warnings = [sprintf("REZYDENCJA PIT Art. 3 — %d dni w PL (próg 183). Status: %s", [days, status])]
}

# ── PIT-6: Small Taxpayer — Mały podatnik PIT ─────────────────────────────
else := {"matched":true,"rule_id":"jdg.pit.small_taxpayer_check","package":"jdg.pit","priority":550,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "small_taxpayer_status":sts,"small_taxpayer_revenue_eur":rev_eur,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 5a pkt 20 PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.tax_form in {"PIT_SCALE","LINEAR"}
    revenue := object.get(input.jdg_entrepreneur, "annual_revenue_net", 0)
    eur := thresholds.bounds.eur_pln
    rev_eur = revenue / eur { eur > 0 }
    rev_eur = revenue / 4.50 { eur == 0 }
    limit := thresholds.pit.small_taxpayer_pit_limit_eur
    sts = "SMALL" { rev_eur <= limit }
    sts = "REGULAR" { rev_eur > limit }

    warnings = [sprintf("MAŁY PODATNIK PIT — %.2f EUR (limit 2M EUR). Status: %s", [rev_eur, sts])]
}

# ── PIT-7: Loss Carry-Forward — Odliczenie strat 5 lat max 50% ──────────
else := {"matched":true,"rule_id":"jdg.pit.loss_carry_forward_limit","package":"jdg.pit","priority":560,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "loss_years":loss_years,"loss_max_pct":loss_pct,"loss_one_off":loss_one_off,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 9 PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.has_tax_losses == true
    loss_years := thresholds.pit.loss_carry_forward_years
    loss_pct := thresholds.pit.loss_carry_forward_max_pct
    loss_one_off := thresholds.pit.loss_carry_forward_one_off_pln

    warnings = [sprintf("STRATA PODATKOWA Art. 9 — %d lat, max %.0f%% rocznie, jednorazowo %.0f PLN", [loss_years, loss_pct*100, loss_one_off])]
}

# ── PIT-8: Family Relief — Ulga prorodzinna 1112.04 PLN/dziecko ──────────
else := {"matched":true,"rule_id":"jdg.pit.family_relief_amount","package":"jdg.pit","priority":570,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"PIT_36",
    "family_children":children,"family_per_child":per_child,"family_total":total,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 27f PIT","_warnings":warnings}
{
    input.jdg_entrepreneur.has_children == true
    children := object.get(input.jdg_entrepreneur, "children_count", 0)
    per_child := thresholds.pit.family_relief_amount_per_child
    total := children * per_child
    children > 0

    warnings = [sprintf("ULGA PRORODZINNA — %d dzieci × %.2f PLN = %.2f PLN", [children, per_child, total])]
}
