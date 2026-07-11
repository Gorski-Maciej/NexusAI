# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — What-If Simulation Engine (ScWhatIf Engine)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Tryb symulacyjny "Co by było gdyby" dla wspólników SC.
# Pozwala na symulowanie alternatywnych scenariuszy podatkowych
# PRZED podjęciem decyzji biznesowych.
#
# WYMAGANA WERSJA OPA: >= v0.44 (dla object.union i json.patch)
#
# Pomysł #1 z 38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md
#
# package: tax.what_if
# rule:     decide, simulation_active, apply_simulation_params
# ═══════════════════════════════════════════════════════════════════════════════

package tax.what_if

import data.tax.helpers

# ── Simulation Mode Detection ─────────────────────────────────────────────────
# Wykrywa czy ewaluacja jest w trybie symulacyjnym

simulation_active {
    input._mode == "SIMULATION"
}

# ── Simulation Scenario Resolution ────────────────────────────────────────────
# Mapuje scenariusz na zestaw parametrów do nadpisania

scenario_params := p {
    simulation_active
    p := object.get(input, "_simulation_params", {})
}

# ── Partner Data Override ─────────────────────────────────────────────────────
# Nadpisuje dane wspólnika dla symulacji

simulated_partners[partner_id] := new_partner {
    simulation_active
    p := scenario_params
    partner_id := p.partner_id
    original := input.partners[_]
    original.id == partner_id
    new_partner := _apply_overrides(original, p)
}

simulated_partners[partner_id] := original {
    not simulation_active
    partner_id := original.id
    original := input.partners[_]
}

_apply_overrides(original, params) := modified {
    modified := object.union(original, {
        "tax_form": object.get(params, "new_tax_form", original.tax_form),
        "share_percent": object.get(params, "new_share_percent", original.share_percent),
        "zus_status": object.get(params, "new_zus_status", original.zus_status),
    })
}

# ── Partnership Data Override ─────────────────────────────────────────────────
# Nadpisuje dane spółki dla symulacji

simulated_partnership := {
    "nip": input.partnership.nip,
    "status": input.partnership.status,
    "is_vat_payer": object.get(scenario_params, "new_vat_status", input.partnership.is_vat_payer),
    "accounting_method": object.get(scenario_params, "new_accounting_method", input.partnership.accounting_method),
    "revenue_annual_net": object.get(scenario_params, "new_annual_revenue", input.partnership.revenue_annual_net),
    "employee_count": input.partnership.employee_count
} {
    simulation_active
}

# ── Thresholds Override ───────────────────────────────────────────────────────
# Pozwala symulować zmiany stawek (np. "co jeśli VAT wzrośnie do 25%?")

simulated_thresholds := modified {
    simulation_active
    p := scenario_params
    original := object.get(input, "thresholds", {})
    rate_overrides := {
        k: object.get(p.rate_overrides, k, v)
        | original.rates[k] := v
    }
    modified := json.patch(original, [{
        "op": "replace",
        "path": "/rates",
        "value": rate_overrides
    }])
} {
    object.get(scenario_params, "rate_overrides", {})
}

simulated_thresholds := input.thresholds {
    not object.get(scenario_params, "rate_overrides", {})
}

# ── Simulation Banner ─────────────────────────────────────────────────────────
# Jawne oznaczenie werdyktu jako symulacyjnego

simulation_banner := {
    "WARNING": "TO JEST SYMULACJA — NIE STANOWI RZECZYWISTEJ DECYZJI PODATKOWEJ",
    "scenario": object.get(scenario_params, "scenario_name", "UNKNOWN"),
    "mode": "SIMULATION",
    "original_values": {
        "tax_form": original_partner.tax_form,
        "share_percent": original_partner.share_percent
    },
    "simulated_values": {
        "tax_form": simulated.tax_form,
        "share_percent": simulated.share_percent
    }
} {
    simulation_active
    scenario_params.partner_id
    original_partner := input.partners[_]
    original_partner.id == scenario_params.partner_id
    simulated := simulated_partners[scenario_params.partner_id]
}

# ── Decision Rule ─────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.what_if.not_simulation",
    "package": "tax.what_if",
    "priority": 3
}

# Tryb symulacyjny — zawsze zwraca banner
decide := {
    "matched": true,
    "rule_id": "tax.what_if.simulation_active",
    "package": "tax.what_if",
    "priority": 3,
    "simulation": simulation_banner,
    "_routing": "OK_SIMULATION",
    "_routing_reason": sprintf("Symulacja: %s", [object.get(scenario_params, "scenario_name", "unnamed")]),
    "_legal_basis": "SYMULACJA — nie stanowi decyzji podatkowej"
} {
    simulation_active
}
