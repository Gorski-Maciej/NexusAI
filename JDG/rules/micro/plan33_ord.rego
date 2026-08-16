# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Plan33 ORD Stub
# v7.0 FIX (LUKA-U4): plan33_ord.rego created as compatibility shim
# Delegates to plan34_ord.rego (190 rules) for OrdPU strategic plan operations
# Package: jdg.micro.plan33_ord
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.plan33_ord

import data.jdg.micro.plan34_ord

# Default rule — fallback dla niepasujących przypadków
default decide := {
    "matched": false,
    "rule_id": "jdg.micro.plan33_ord.no_match",
    "package": "jdg.micro.plan33_ord",
    "priority": 999999
}

# ─────────────────────────────────────────────────────────────────────────────
# Plan33 OrdPU — Compatibility shim for plan34_ord
# All strategic planning operations for Ordynacja Podatkowa are handled
# by plan34_ord.rego (190 atomic rule templates, priorities 80000-80189).
# This file exists to satisfy the documentation contract (P18/P19 cross-report
# consistency) and provides delegation wrappers.
# ─────────────────────────────────────────────────────────────────────────────

# P33O-80000: Plan33 entry point — delegates to plan34
p33o_resolve(input) = result {
    result := plan34_ord.decide with input as input
}

# P33O-80001: Plan33 strategic override for active remorse (KKS a16 → OrdPU routing)
p33o_a16_override(input) = override {
    is_jdg := object.get(input, "jdg_entrepreneur", {}).business_type == "JDG"
    ord_a16_applicable := object.get(input, "jdg_entrepreneur", {}).ord_a16_applicable == true

    override := {
        "matched": true,
        "rule_id": "jdg.micro.plan33_ord.a16.r1",
        "_routing": "",
        "_legal_basis": "Ordynacja podatkowa (Dz.U. 2024 poz. 1455 ze zm.)",
        "package": "jdg.micro.plan33_ord",
        "priority": 80000,
        "routing": "TRIAGE",
        "routing_reason": "Czynny żal (KKS a16) — przekierowanie do S22 + enterprise correspondence engine",
        "legal_basis": "Kodeks Karny Skarbowy Art. 16 (Dz.U. 1999 nr 83 poz. 930)",
        "note": "v7.0 FIX (LUKA-U4/U3): plan33_ord.rego — created to satisfy cross-report documentation contract",
    } { is_jdg; ord_a16_applicable }

    override := {"matched": false, "rule_id": "jdg.micro.plan33_ord.no_match_override", "priority": 89999} { not is_jdg or not ord_a16_applicable }
}
