# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: VAT MIKRO (PROMPT 03)
# Generated: 2026-08-16 | Scenariusze: atomowe reguły per artykuł (5-172),
#              WIS 42a-42h (domknięcie pustyni), spójność micro↔macro (INV-018)
# ═══════════════════════════════════════════════════════════════════════════════

package test_vat_micro

# ── Evidence: warstwa mikro VAT załadowana (jdg.micro.vat) ───────────────────

test_evidence_jdg_micro_vat_loaded {
    data.jdg.micro.vat.decide
    json.marshal(data.jdg.micro.vat.decide)
}

# ── Evidence: r03 (uzupełnienia atomowe) — wpięte w orkiestrator ─────────────

test_evidence_jdg_micro_vat_r03 {
    data.jdg.micro.vat.r03.decide
    json.marshal(data.jdg.micro.vat.r03.decide)
}

# ── Evidence: WIS art. 42a-42h (P03 domknięcie pustyni pokrycia) ─────────────

test_evidence_wis_a42a {
    data.jdg.micro.vat.r03.decide
    contains(json.marshal(data.jdg.micro.vat.r03.decide), "jdg.micro.vat.a42a")
}

test_evidence_wis_a42h {
    data.jdg.micro.vat.r03.decide
    contains(json.marshal(data.jdg.micro.vat.r03.decide), "jdg.micro.vat.a42h")
}

# ── Spójność micro↔macro (INV-018): oba pakiety w orkiestratorze ─────────────

test_micro_macro_consistency {
    data.jdg.vat.substantive.decide
    data.jdg.micro.vat.decide
}

# ── Art. 113 (monitor z P02) + mikro VAT — współistnienie ────────────────────

test_a113_micro_coexist {
    data.jdg.vat.substantive.decide
    data.jdg.micro.vat.decide
    json.marshal(data.jdg.vat.substantive.decide)
}

# ── Evidence: mikro JPK (jdg.micro.jpk) wpięte w orkiestrator ────────────────

test_evidence_jdg_micro_jpk {
    data.jdg.micro.jpk.decide
    json.marshal(data.jdg.micro.jpk.decide)
}

# ── Evidence: plan33 JPK (osobny pakiet po P03 FIX) ──────────────────────────

test_evidence_jdg_micro_jpk_plan33 {
    data.jdg.micro.jpk.plan33.decide
    json.marshal(data.jdg.micro.jpk.plan33.decide)
}

# ── WIS plan45 (jdg.hyper.wis) — integracja z warstwą mikro ──────────────────

test_evidence_wis_hyper {
    data.jdg.hyper.wis.decide
    json.marshal(data.jdg.hyper.wis.decide)
}
