# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R03 GLM52 VAT — WARSTWA MICRO — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r03_vat_micro_innovations
# Raport: RAPORT_03_VAT_MICRO.txt (Kampania GLM 5.2 — seria 03/25)
#
# Prompt 03/25 (VAT — WARSTWA MICRO — atomowe reguły per artykuł, plan33/plan34)
# — ulepszenia warstwy atomowej, poziom ENTERPRISE:
#   R03-INN-01 article_coverage_monitor — automatyczna weryfikacja pokrycia
#                                           artykułów (każdy materialny węzeł
#                                           prawa VAT z Bbb → ≥1 reguła micro);
#                                           pustynie raportowane (P05-INN-14)
#   R03-INN-02 micro_macro_binding       — super-inteligentna sieć zależności:
#                                           art. VAT → reguła micro → pakiet
#                                           macro → werdykt (transparentność)
#   R03-INN-03 micro_consistency_check   — łączenie reguł micro z werdyktami
#                                           macro bez konfliktów: wykrywanie
#                                           rozbieżności stawki/GTU (INV-018)
#
# Zgodność: ADR-001..009/017/022, P05 (vat_micro_atomic — pustynie artykułów),
#           vat_micro_inventory.json (coverage), INV-018 (sprzeczne werdykty),
#           u. VAT (Dz.U. 2025 poz. 456).
# package: jdg.r03_vat_micro_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r03_vat_micro_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r03_vat_micro_innovations.no_match", "package": "jdg.r03_vat_micro_innovations", "priority": 999999}

# ── Kluczowe 30 artykułów ustawy o VAT (prompt P05 — weryfikacja priorytetowa) ──
key_articles_30 := ["5", "7", "8", "15", "17", "19a", "20", "21", "28b", "29a",
    "41", "43", "86", "86a", "87", "88", "89a", "89b", "90", "91", "96", "99",
    "103", "106a", "106e", "106i", "106n", "108a", "113", "120"]

# ═══════════════════════════════════════════════════════════════════════════════
# R03-INN-01: ARTICLE COVERAGE MONITOR — automatyczna weryfikacja pokrycia
# ═══════════════════════════════════════════════════════════════════════════════
# Źródło pokrycia: host dostarcza vat_micro_coverage (z vat_micro_inventory.json
# lub na żywo z manifestu). Każdy artykuł kluczowej 30-tki musi mieć status
# COMPLETE; PARTIAL/MISSING = pustynia → sygnał dla operatora (control plane).
article_coverage_status(article) = status {
    coverage := object.get(input, "vat_micro_coverage", {})
    status := object.get(coverage, article, "UNKNOWN")
} else := "MISSING" {
    true
}

article_coverage_monitor := {
    "key_articles_total": count(key_articles_30),
    "covered": count([a | some a in key_articles_30; article_coverage_status(a) == "COMPLETE"]),
    "partial": count([a | some a in key_articles_30; article_coverage_status(a) == "PARTIAL"]),
    "missing": [a | some a in key_articles_30; article_coverage_status(a) == "MISSING"],
    "missing_count": count([a | some a in key_articles_30; article_coverage_status(a) == "MISSING"]),
    "note": "Każdy materialny węzeł prawa VAT (Bbb) → ≥1 reguła micro; pustynie = MISSING/PARTIAL (P05-INN-14)",
    "invariant": "Pokrycie artykułów: COMPLETE = reguła atomowa + podstawa prawna + temporalność",
}

# ═══════════════════════════════════════════════════════════════════════════════
# R03-INN-02: MICRO↔MACRO BINDING — sieć zależności art. → micro → macro
# ═══════════════════════════════════════════════════════════════════════════════
micro_macro_map := {
    "5": "jdg.vat.substantive",
    "7": "jdg.vat.substantive",
    "8": "jdg.vat.substantive",
    "15": "jdg.vat.substantive",
    "17": "jdg.crossborder",
    "19a": "jdg.vat.procedures",
    "20": "jdg.vat.procedures",
    "21": "jdg.vat.procedures",
    "28b": "jdg.vat.place_of_supply",
    "29a": "jdg.vat.place_of_supply",
    "41": "jdg.vat_rates_audit",
    "43": "jdg.vat_rates_audit",
    "86": "jdg.vat_deductions_audit",
    "86a": "jdg.vat_deductions_audit",
    "87": "jdg.vat_deductions_audit",
    "88": "jdg.vat_deductions_audit",
    "89a": "jdg.vat_deductions_audit",
    "89b": "jdg.vat_deductions_audit",
    "90": "jdg.vat_deductions_audit",
    "91": "jdg.vat_deductions_audit",
    "96": "jdg.vat_rates_audit",
    "99": "jdg.vat.procedures",
    "103": "jdg.vat.procedures",
    "106a": "jdg.ksef_jpk",
    "106e": "jdg.ksef_jpk",
    "106i": "jdg.ksef_jpk",
    "106n": "jdg.ksef_jpk",
    "108a": "jdg.vat_mpp_split_payment",
    "113": "jdg.vat_rates_audit",
    "120": "jdg.vat.procedures",
}

micro_macro_binding := {
    "bindings_total": count(micro_macro_map),
    "bindings": {a: micro_macro_map[a] | some a in object.keys(micro_macro_map)},
    "note": "Łańcuch spójności: art. VAT → reguła micro (jdg.micro.vat.r03 / jdg.micro.vat) → pakiet macro → werdykt",
}

# ═══════════════════════════════════════════════════════════════════════════════
# R03-INN-03: MICRO↔MACRO CONSISTENCY CHECK — zero konfliktów (INV-018)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza micro_verdicts (art. → werdykt micro) i macro_verdicts
# (pakiet → werdykt macro). Rozbieżność stawki VAT między micro a macro dla
# tego samego artykułu = konflikt → TRIAGE (nie BLOCK — mikro może być
# szczegółowsza, ale rozjazd stawek wymaga wyjaśnienia).
_micro_verdicts := object.get(input, "micro_verdicts", {})
_macro_verdicts := object.get(input, "macro_verdicts", {})

micro_macro_conflicts := [c |
    some a in object.keys(_micro_verdicts)
    mv := _micro_verdicts[a]
    object.get(mv, "matched", false) == true
    macro_pkg := object.get(micro_macro_map, a, "")
    macro_pkg != ""
    mact := object.get(_macro_verdicts, macro_pkg, {})
    object.get(mact, "matched", false) == true
    mv_rate := object.get(mv, "vat_rate", "")
    mac_rate := object.get(mact, "vat_rate", "")
    mv_rate != ""
    mac_rate != ""
    mv_rate != mac_rate
    c := {"article": a, "micro_vat_rate": mv_rate, "macro_vat_rate": mac_rate, "type": "RATE_MISMATCH", "resolution": "TRIAGE"}
] else := [] {
    true
}

micro_consistency_check := {
    "conflicts": micro_macro_conflicts,
    "conflict_count": count(micro_macro_conflicts),
    "matched_micro_articles": count([a | some a in object.keys(_micro_verdicts); object.get(_micro_verdicts[a], "matched", false) == true]),
    "invariant": "INV-018: brak sprzecznych werdyktów micro↔macro dla tego samego artykułu",
    "note": "Rozbieżność stawek między warstwą atomową a macro = TRIAGE (ręczna weryfikacja, nigdy AUTO_POST)",
}

# ═══════════════════════════════════════════════════════════════════════════════
# GŁÓWNA REGUŁA RAPORTU (aktywowana flagą r03_vat_micro_check)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.r03_vat_micro_innovations.vat_micro_report",
    "package": "jdg.r03_vat_micro_innovations",
    "priority": 280,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "vat_exemption": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "valid_from": "2026-01-01", "valid_to": null,
    "vat_micro": {
        "article_coverage": article_coverage_monitor,
        "micro_macro_binding": micro_macro_binding,
        "micro_consistency": micro_consistency_check,
    },
    "_routing": "REPORT",
    "_routing_reason": "R03 VAT MICRO: pokrycie artykułów, sieć micro↔macro, spójność werdyktów",
    "_legal_basis": "Ustawa o VAT (Dz.U. 2025 poz. 456) Art. 5-173 + P05 (pustynie artykułów)",
    "_warnings": ["Raport VAT MICRO — aktywowany wyłącznie flagą r03_vat_micro_check"],
} {
    object.get(input.jdg_entrepreneur, "r03_vat_micro_check", false) == true
}
