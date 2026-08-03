# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rego Tests: P04 VAT MICRO ENTERPRISE v9.0
# Sekcje: 1 (mapa pokrycia artykułów), 2 (duplikaty/stuby), 3 (micro↔macro),
#         4 (gwarancje matematyczne), 5 (pakiety specjalistyczne),
#         6 (pipeline ISAP), 7 (genius ideas)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p04_vat_micro_enterprise_test

import future.keywords.in

# ── SEKCJA 1: MAPA POKRYCIA ARTYKUŁÓW ────────────────────────────────────────

test_coverage_report := {
    result := data.jdg.p04_vat_micro_innovations.coverage_report
    result.matched == true
    result.coverage.total_priority_articles == 52
    result.coverage.complete >= 20
    result.coverage.missing >= 1
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p04_micro_audit_check": true}
} with data.jdg.vat_micro_audit as {
    "coverage": {
        "5": "COMPLETE", "7": "COMPLETE", "8": "COMPLETE", "15": "COMPLETE",
        "17": "COMPLETE", "19a": "COMPLETE", "20": "COMPLETE", "21": "COMPLETE",
        "29a": "COMPLETE", "31": "COMPLETE", "32": "COMPLETE", "41": "COMPLETE",
        "42": "COMPLETE", "43": "COMPLETE", "86": "COMPLETE", "87": "COMPLETE",
        "88": "COMPLETE", "89a": "COMPLETE", "89b": "COMPLETE", "96": "COMPLETE",
        "106a": "COMPLETE", "106f": "COMPLETE", "113": "COMPLETE", "120": "COMPLETE",
        "6": "MISSING", "90": "MISSING", "91": "MISSING", "106b": "MISSING",
        "106n": "MISSING", "30": "MISSING"
    }
}

# ── SEKCJA 2: AUDYT DUPLIKATÓW I MARTWYCH REGUŁ ──────────────────────────────

test_stub_duplicate_report := {
    result := data.jdg.p04_vat_micro_innovations.stub_duplicate_report
    result.audit.duplicate_count >= 0
    result.audit.stub_count >= 0
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p04_micro_audit_check": true}
} with data.jdg.vat_micro_audit as {
    "duplicates": ["jdg.micro.vat.a43.r1"],
    "stubs": [],
    "dead_rules": []
}

test_deduplication_plan := {
    result := data.jdg.p04_vat_micro_innovations.deduplication_plan
    result.plan.duplicate_count == 1
    result.plan.strategy == "MERGE_INTO_HIGHEST_PRIORITY"
} with input as {
    "jdg_entrepreneur": {"p04_dedupe_check": true}
} with data.jdg.vat_micro_audit as {
    "duplicates": ["jdg.micro.vat.a43.r1"]
}

# ── SEKCJA 3: SPÓJNOŚĆ MICRO ↔ MACRO ─────────────────────────────────────────

test_micro_macro_report := {
    result := data.jdg.p04_vat_micro_innovations.micro_macro_report
    result.consistency.coherent == true
    result.consistency.macro_decisions_mapped == 2
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p04_micro_audit_check": true}
} with data.jdg.vat_micro_audit as {
    "macro_micro_map": {
        "art. 43": {"micro_priority": 10, "macro_priority": 500},
        "art. 86": {"micro_priority": 20, "macro_priority": 500}
    }
}

# ── SEKCJA 4: GWARANCJE MATEMATYCZNE (grosze/zaokrąglenia/stawki) ────────────

test_math_guarantee_ok := {
    # Gdy wszystkie gwarancje spełnione, math_guarantee jest NIEzdefiniowany
    # (guard: not all_ok) — brak raportu = brak problemu.
    not data.jdg.p04_vat_micro_innovations.math_guarantee
    data.jdg.p04_vat_micro_innovations.amount_contract_ok == true
    data.jdg.p04_vat_micro_innovations.rounding_ok == true
    data.jdg.p04_vat_micro_innovations.rate_math_ok == true
} with input as {
    "invoice": {"amount_net": 1000, "vat_amount": 230, "amount_gross": 1230,
        "vat_rate": "23.00", "vat_rate_num": "0.23", "rounding_level": "position"},
    "jdg_entrepreneur": {"p04_math_check": true}
}

test_math_guarantee_block := {
    # netto + vat != brutto → TRIAGE_QUEUE (gwarancja groszowa złamana)
    result := data.jdg.p04_vat_micro_innovations.math_guarantee
    result.guarantees.grosz_contract == false
    result.guarantees.all_ok == false
    result._routing == "TRIAGE_QUEUE"
} with input as {
    "invoice": {"amount_net": 1000, "vat_amount": 230, "amount_gross": 1300,
        "vat_rate": "23.00", "vat_rate_num": "0.23", "rounding_level": "position"},
    "jdg_entrepreneur": {"p04_math_check": true}
}

# ── SEKCJA 5: PAKIETY SPECJALISTYCZNE (KSeF, marża, POS, proporcja, WDT/IE) ──

test_specialist_audit_no_gaps := {
    result := data.jdg.p04_vat_micro_innovations.specialist_audit
    result.audit.packages == 5
    result.audit.gap_count == 0
    result.audit.ksef_2026_compliance == true
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p04_specialist_check": true}
} with data.jdg.vat_micro_audit as {
    "specialist_rule_counts": {
        "ksef_micro": 40, "margin_scheme_micro": 15, "place_of_supply_micro": 20,
        "proportion_vat": 12, "wdt_export_import": 25
    },
    "ksef_2026_compliant": true
}

# ── SEKCJA 7: GENIALNE POMYSŁY (INN-04 rate↔description) ─────────────────────

test_rate_description_mismatch := {
    result := data.jdg.p04_vat_micro_innovations.rate_description_mismatch
    result.mismatch.declared_rate == "23.00"
    result.mismatch.expected_rate_by_keyword == "5.00"
    result._routing == "TRIAGE_QUEUE"
} with input as {
    "invoice": {"description": "sprzedaż chleba", "vat_rate": "23.00"},
    "jdg_entrepreneur": {"p04_rate_desc_check": true}
}

test_semantic_rate_verifier_consistent := {
    result := data.jdg.p04_vat_micro_innovations.semantic_rate_verifier
    result.verification.consistent == true
    result.verification.declared_rate == "5.00"
    result._routing == "REPORT"
} with input as {
    "invoice": {"description": "mleko i owoce", "vat_rate": "5.00"},
    "jdg_entrepreneur": {"p04_rate_desc_check": true}
}

# ── GŁÓWNY RAPORT P04 (Sekcje 1-7) ───────────────────────────────────────────

test_p04_main_decide := {
    result := data.jdg.p04_vat_micro_innovations.decide
    result.matched == true
    result.rule_id == "jdg.p04_vat_micro_innovations.report"
    result.p04_vat_micro.section1_coverage.complete >= 20
    result.p04_vat_micro.section7_innovations.INN01_auto_generator == true
    result.p04_vat_micro.section7_innovations.INN11_test_generator == true
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p04_vat_micro_check": true}
} with data.jdg.vat_micro_audit as {
    "coverage": {
        "5": "COMPLETE", "7": "COMPLETE", "8": "COMPLETE", "15": "COMPLETE",
        "17": "COMPLETE", "19a": "COMPLETE", "20": "COMPLETE", "21": "COMPLETE",
        "29a": "COMPLETE", "31": "COMPLETE", "32": "COMPLETE", "41": "COMPLETE",
        "42": "COMPLETE", "43": "COMPLETE", "86": "COMPLETE", "87": "COMPLETE",
        "88": "COMPLETE", "89a": "COMPLETE", "89b": "COMPLETE", "96": "COMPLETE",
        "106a": "COMPLETE", "106f": "COMPLETE", "113": "COMPLETE", "120": "COMPLETE",
        "6": "MISSING", "90": "MISSING", "91": "MISSING", "106b": "MISSING"
    }
}

# ── DOMYŚLNE no_match (normalny ruch bez flag P04) ───────────────────────────

test_p04_default_no_match := {
    data.jdg.p04_vat_micro_innovations.decide.matched == false
    data.jdg.p04_vat_micro_innovations.decide.rule_id == "jdg.p04_vat_micro_innovations.no_match"
} with input as {
    "invoice": {"direction": "SALE", "amount_net": 1000},
    "jdg_entrepreneur": {"tax_form": "SCALE"}
}
