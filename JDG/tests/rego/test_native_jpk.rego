# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: JPK (PROMPT 03 — Sekcja 3)
# Generated: 2026-08-16 | Scenariusze: JPK_V7M/V7K, terminy 25. dzień,
#              struktura (deklaracja + sprzedaż + zakupy), GTU, procedury
# ═══════════════════════════════════════════════════════════════════════════════

package test_jpk

# ── Evidence: jdg.jpk (terminy złożenia, art. 99 VAT) ─────────────────────────

test_evidence_jdg_jpk_deadlines {
    data.jdg.jpk.decide
    json.marshal(data.jdg.jpk.decide)
}

# ── Evidence: jdg.micro.jpk (struktura JPK_V7M — ~160 reguł) ─────────────────

test_evidence_jdg_micro_jpk_structure {
    data.jdg.micro.jpk.decide
    json.marshal(data.jdg.micro.jpk.decide)
}

# ── Evidence: plan33_jpk (wydzielony pakiet — P03 FIX konfliktu kompilacji) ──

test_evidence_plan33_jpk {
    data.jdg.micro.jpk.plan33.decide
    json.marshal(data.jdg.micro.jpk.plan33.decide)
}

# ── Evidence: JPK_V7 autogen + korekty (enterprise, P17) ─────────────────────

test_evidence_jpk_v7_autogen {
    data.jdg.jpk_v7_autogen.decide
    json.marshal(data.jdg.jpk_v7_autogen.decide)
}

# ── Evidence: korekty JPK (workflow) ─────────────────────────────────────────

test_evidence_jpk_corrections {
    data.jdg.jpk_corrections_workflow.decide
    json.marshal(data.jdg.jpk_corrections_workflow.decide)
}

# ── Cross-validation: JPK + KSeF + VAT mikro współdziałają ───────────────────

test_jpk_ksef_vatmicro_cross {
    data.jdg.micro.jpk.decide
    data.jdg.micro.vat.decide
    data.jdg.jpk.decide
}
