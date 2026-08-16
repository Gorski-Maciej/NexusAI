# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: ART. 113 LIMIT TRACKER (PROMPT 02)
# Generated: 2026-08-16 | Scenariusze: zwolnienie podmiotowe 200 000 PLN,
#              proporcja art. 113 ust. 9 (nowe JDG), alert 95% limitu
# ═══════════════════════════════════════════════════════════════════════════════

package test_vat_a113_tracker

# ── Evidence: reguła monitora limitu 113 (jdg.vat.substantive.a113_limit_monitor) ──

test_evidence_jdg_vat_a113_monitor {
    data.vat_substantive.decide
    json.marshal(data.vat_substantive.decide)
}

# ── Evidence: reguła zwolnienia podmiotowego (jdg.vat.a113.r1) ───────────────

test_evidence_jdg_vat_a113_exemption {
    data.vat_substantive.decide
    json.marshal(data.vat_substantive.decide)
}

# ── Limit zwolnienia (art. 113 ust. 1) — externalizacja thresholds ───────────

test_a113_limit_externalized {
    data.jdg.thresholds.vat.subject_exemption_limit >= 200000
}

# ── Próg alertu 95% (innowacja P02) ──────────────────────────────────────────

test_a113_alert_ratio_externalized {
    data.jdg.thresholds.vat.a113_alert_ratio == 0.95
}

# ── Bridge limit tracker (jdg.vat.enterprise.limit_tracker_bridge) załadowany ──

test_a113_bridge_loaded {
    data.vat_enterprise_bridge.decide
    json.marshal(data.vat_enterprise_bridge.decide)
}

# ── Cross-validation: zwolnienie 113 + breah mid-year (edge_cases) ───────────

test_a113_cross_edge_cases_loaded {
    data.vat_substantive.decide
    data.edge_cases.decide
}
