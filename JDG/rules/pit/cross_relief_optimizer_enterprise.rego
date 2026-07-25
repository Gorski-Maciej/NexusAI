# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE CROSS-RELIEF INTERACTION OPTIMIZER
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Cross-Relief Optimizer — Synergia Ulg Podatkowych
# description: |
#   ENTERPRISE v7.0 — Inicjatywa S5: Automatyczna optymalizacja kombinacji ulg.
#   Analizuje interakcje między wszystkimi ulgami JDG i rekomenduje
#   najlepszą kombinację. C150-C169.
#   - C150: Macierz kompatybilności ulg (co z czym można łączyć)
#   - C151: Optymalna kolejność stosowania ulg
#   - C152: Kalkulator łącznej oszczędności
#   - C153: Wykrywanie konfliktów (B+R+IP Box na tym samym dochodzie)
#   - C154: Rekomendacja najlepszej kombinacji
#   - C155: Alert o wykluczających się ulgach
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Art. 26-30cb PIT
# package: jdg.pit.cross_relief
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.cross_relief

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.cross_relief.no_match",
    "package": "jdg.pit.cross_relief", "priority": 999
}

# ── Macierz kompatybilności ulg — używana przez C150 ────────────────────────
# True = MOŻNA ŁĄCZYĆ, False = NIE MOŻNA, "SEPARATE" = można ale na różnych dochodach
compatibility := {
    "RD_IPBOX": "SEPARATE",        # B+R + IP Box: tak, ale na różnych dochodach
    "RD_PROTOTYPE": true,           # B+R + prototyp: TAK — można łączyć
    "RD_ROBOTIZATION": true,        # B+R + robotyzacja: TAK
    "RD_EXPANSION": true,           # B+R + ekspansja: TAK
    "IPBOX_PROTOTYPE": true,        # IP Box + prototyp: TAK
    "IPBOX_ROBOTIZATION": true,     # IP Box + robotyzacja: TAK
    "IPBOX_THERMO": true,           # IP Box + termomodernizacja: TAK
    "IPBOX_DONATION": true,         # IP Box + darowizny: TAK
    "IPBOX_ESTONIAN": false,        # IP Box + estoński CIT: NIE
    "RD_ESTONIAN": false,           # B+R + estoński CIT: NIE
    "LUMP_IPBOX": false,            # Ryczałt + IP Box: NIE
    "LUMP_RD": false,               # Ryczałt + B+R: NIE
    "LINEAR_IPBOX": true,           # Liniowy + IP Box: TAK
    "LINEAR_RD": true,              # Liniowy + B+R: TAK
    "SCALE_CHILD_IPBOX": false,     # Skala+dziecko+IP Box: dziecko tylko przy skali
}

# ═══════════════════════════════════════════════════════════════════════════════
# C150: cross_relief_compatibility_matrix — Które ulgi można łączyć
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.pit.cross_relief.compatibility",
    "package": "jdg.pit.cross_relief",
    "priority": 150,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cross_relief_available": available_reliefs,
    "cross_relief_compatible_pairs": compatible_pairs,
    "cross_relief_conflicts": conflicts,
    "cross_relief_separate_income_pairs": separate_pairs,
    "_routing": cross_rt,
    "_routing_reason": sprintf("Cross-relief: %d ulg dostępnych, %d par kompatybilnych, %d konfliktów",
        [count(available_reliefs), count(compatible_pairs), count(conflicts)]),
    "_legal_basis": "Art. 26-30cb PIT (łączenie ulg podatkowych)",
    "_warnings": build_cross_relief_warnings(available_reliefs, compatible_pairs, conflicts, separate_pairs)
} {
    input.cross_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    has_rd := object.get(input.jdg_entrepreneur, "has_rd_costs", false)
    has_ipbox := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    has_proto := object.get(input.jdg_entrepreneur, "has_prototype_costs", false)
    has_robot := object.get(input.jdg_entrepreneur, "has_robotization_costs", false)
    has_exp := object.get(input.jdg_entrepreneur, "has_foreign_expansion_costs", false)
    has_thermo := object.get(input.jdg_entrepreneur, "has_thermo_costs", false)
    has_donation := object.get(input.jdg_entrepreneur, "donations_opp_total", 0) > 0

    available_reliefs := []
    available_reliefs := array.concat(available_reliefs, ["B+R"]) { has_rd }
    available_reliefs := array.concat(available_reliefs, ["IP_BOX"]) { has_ipbox }
    available_reliefs := array.concat(available_reliefs, ["PROTOTYPE"]) { has_proto }
    available_reliefs := array.concat(available_reliefs, ["ROBOTIZATION"]) { has_robot }
    available_reliefs := array.concat(available_reliefs, ["EXPANSION"]) { has_exp }
    available_reliefs := array.concat(available_reliefs, ["THERMO"]) { has_thermo }
    available_reliefs := array.concat(available_reliefs, ["DONATION"]) { has_donation }

    compatible_pairs := []
    conflicts := []
    separate_pairs := []

    # B+R + IP Box = SEPARATE income
    separate_pairs := array.concat(separate_pairs, ["B+R + IP Box — MUSISZ rozdzielić dochody!"]) { has_rd; has_ipbox }

    # Ryczałt wyklucza B+R i IP Box
    conflicts := array.concat(conflicts, ["Ryczałt NIE pozwala na B+R ani IP Box!"]) { pit_form == "LUMP_SUM"; (has_rd or has_ipbox) }

    # Kompatybilne pary
    compatible_pairs := array.concat(compatible_pairs, ["B+R + PROTOTYP — OK, pełna synergia"]) { has_rd; has_proto }
    compatible_pairs := array.concat(compatible_pairs, ["B+R + ROBOTYZACJA — OK"]) { has_rd; has_robot }
    compatible_pairs := array.concat(compatible_pairs, ["B+R + EKSPANSJA — OK"]) { has_rd; has_exp }
    compatible_pairs := array.concat(compatible_pairs, ["IP Box + TERMO — OK"]) { has_ipbox; has_thermo }
    compatible_pairs := array.concat(compatible_pairs, ["IP Box + DAROWIZNY — OK"]) { has_ipbox; has_donation }
    compatible_pairs := array.concat(compatible_pairs, ["PROTOTYP + ROBOTYZACJA — OK"]) { has_proto; has_robot }

    cross_rt = "TRIAGE_QUEUE" { count(conflicts) > 0 }
    cross_rt = "" { true }
}

build_cross_relief_warnings(available, compatible, conflicts, separate) = warnings {
    lines := ["🔗 CROSS-RELIEF INTERACTION OPTIMIZER"]
    lines := array.concat(lines, [sprintf("   Dostępne ulgi (%d): %s", [count(available), concat(", ", available)])])
    lines := array.concat(lines, [sprintf("   Pary kompatybilne: %s", [concat("; ", compatible)])]) { count(compatible) > 0 }
    lines := array.concat(lines, ["   ⚠️ WYMAGA ROZDZIELENIA DOCHODÓW:"]) { count(separate) > 0 }
    lines := array.concat(lines, separate) { count(separate) > 0 }
    lines := array.concat(lines, ["   🚫 KONFLIKTY:"]) { count(conflicts) > 0 }
    lines := array.concat(lines, conflicts) { count(conflicts) > 0 }
    lines := array.concat(lines, ["", "💡 REKOMENDACJA: stosuj ulgi w kolejności: strata → IP Box → B+R → prototyp → robotyzacja → ekspansja → termo → darowizny"])
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# C151: cross_relief_optimal_order — Optymalna kolejność stosowania ulg
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.cross_relief.optimal_order",
    "package": "jdg.pit.cross_relief",
    "priority": 151,
    "pit_form": pit_form,
    "cross_relief_order": [
        "1. STRATA z lat ubiegłych (50% rocznie, max 5 lat)",
        "2. IP BOX (5% — wydziel dochód z IP!)",
        "3. B+R (100-200% kosztów kwalifikowanych)",
        "4. PROTOTYP (30% kosztów)",
        "5. ROBOTYZACJA (50% kosztów)",
        "6. EKSPANSJA (do 1M PLN)",
        "7. TERMOMODERNIZACJA (do 53k PLN)",
        "8. DAROWIZNY (6% dochodu)",
        "9. IKZE (indywidualne konto zabezpieczenia emerytalnego)"
    ],
    "_routing": "",
    "_routing_reason": "Kolejność stosowania ulg: strata → IP Box → B+R → ... → IKZE",
    "_legal_basis": "Art. 26-30cb PIT (kolejność odliczeń)",
    "_warnings": ["KOLEJNOŚĆ ULG: 1. Strata → 2. IP Box (5%, wydziel) → 3. B+R → 4. Prototyp → 5. Robotyzacja → 6. Ekspansja → 7. Termo → 8. Darowizny → 9. IKZE. Stosuj w tej kolejności, bo każda ulga pomniejsza dochód dla KOLEJNYCH ulg!"]
} {
    input.cross_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# C152: cross_relief_combined_savings — Kalkulator łącznej oszczędności
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.cross_relief.combined_savings",
    "package": "jdg.pit.cross_relief",
    "priority": 152,
    "pit_form": pit_form,
    "cross_relief_total_savings": total_savings,
    "cross_relief_effective_tax_rate": effective_rate,
    "cross_relief_without_reliefs_tax": without_reliefs,
    "_routing": "",
    "_routing_reason": sprintf("Łączna oszczędność z ulg: %.2f PLN. Efektywna stawka: %.1f%% zamiast nominalnej.",
        [total_savings, effective_rate]),
    "_legal_basis": "Art. 26-30cb PIT",
    "_warnings": [sprintf("ŁĄCZNA OSZCZĘDNOŚĆ Z ULG: %.2f PLN/rok. Bez ulg zapłaciłbyś: %.2f PLN. Z ulgami: %.2f PLN. Efektywna stawka podatkowa: %.1f%%. To tak jakbyś miał NIŻSZĄ stawkę PIT dzięki optymalizacji!",
        [total_savings, without_reliefs, without_reliefs - total_savings, effective_rate])]
} {
    input.cross_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 150000)

    # Zsumuj wszystkie oszczędności
    rd_savings := object.get(input.jdg_entrepreneur, "rd_savings_estimated", 0)
    ipbox_savings := object.get(input.jdg_entrepreneur, "ipbox_savings_estimated", 0)
    proto_savings := object.get(input.jdg_entrepreneur, "prototype_savings_estimated", 0)
    robot_savings := object.get(input.jdg_entrepreneur, "robotization_savings_estimated", 0)
    expansion_savings := object.get(input.jdg_entrepreneur, "expansion_savings_estimated", 0)
    thermo_savings := object.get(input.jdg_entrepreneur, "thermo_savings_estimated", 0)
    donation_savings := object.get(input.jdg_entrepreneur, "donation_savings_estimated", 0)

    total_savings := rd_savings + ipbox_savings + proto_savings + robot_savings + expansion_savings + thermo_savings + donation_savings
    without_reliefs := income * 0.12  # Default scale rate
    without_reliefs := income * 0.19 { pit_form == "LINEAR" }
    effective_rate := floor((without_reliefs - total_savings) / income * 1000) / 10
}

# ═══════════════════════════════════════════════════════════════════════════════
# C153: cross_relief_conflict_detector — Wykrywanie konfliktów między ulgami
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.cross_relief.conflict_detector",
    "package": "jdg.pit.cross_relief",
    "priority": 153,
    "pit_form": pit_form,
    "cross_relief_critical_conflict": critical_conflict,
    "cross_relief_conflict_description": conflict_desc,
    "_routing": conflict_rt,
    "_routing_reason": conflict_desc,
    "_legal_basis": "Art. 26-30cb PIT",
    "_warnings": [sprintf("🚨 KONFLIKT ULG! %s. NIE możesz zastosować obu ulg na tym samym dochodzie. ROZWIĄZANIE: %s",
        [conflict_desc, solution])]
} {
    input.cross_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_rd := object.get(input.jdg_entrepreneur, "has_rd_costs", false)
    has_ipbox := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    ip_income := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 0)
    rd_costs := object.get(input.jdg_entrepreneur, "rd_total_qualified_costs", 0)
    total_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 150000)

    # Główny konflikt: B+R i IP Box na tym samym dochodzie
    critical_conflict := has_rd and has_ipbox and (ip_income + rd_costs > total_income)
    conflict_desc = "B+R i IP Box NACHODZĄ na ten sam dochód! Nie możesz odliczyć B+R od dochodu, który już jest opodatkowany IP Box (5%)." { critical_conflict }
    conflict_desc = "" { not critical_conflict }
    solution = "Rozdziel: IP Box → dochód z IP (%.2f PLN @ 5%%), B+R → pozostały dochód (%.2f PLN)." { critical_conflict }
    solution = "" { not critical_conflict }

    conflict_rt = "BLOCK_AND_ALERT" { critical_conflict }
    conflict_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# C154: cross_relief_best_combination — Rekomendacja najlepszej kombinacji
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.cross_relief.best_combination",
    "package": "jdg.pit.cross_relief",
    "priority": 154,
    "pit_form": pit_form,
    "cross_relief_recommended_combo": best_combo,
    "cross_relief_estimated_savings": best_savings,
    "cross_relief_priority_message": "Zastosuj tę kombinację w zeznaniu rocznym!",
    "_routing": "",
    "_routing_reason": sprintf("Rekomendowana kombinacja: %s — oszczędność ~%.2f PLN/rok", [concat(" + ", best_combo), best_savings]),
    "_legal_basis": "Art. 26-30cb PIT",
    "_warnings": [sprintf("🏆 NAJLEPSZA KOMBINACJA ULG: %s. Szacowana oszczędność: %.2f PLN/rok. Wskazówka: %s",
        [concat(" + ", best_combo), best_savings, priority_tip])]
} {
    input.cross_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    has_rd := object.get(input.jdg_entrepreneur, "has_rd_costs", false)
    has_ipbox := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    has_proto := object.get(input.jdg_entrepreneur, "has_prototype_costs", false)
    has_robot := object.get(input.jdg_entrepreneur, "has_robotization_costs", false)
    has_exp := object.get(input.jdg_entrepreneur, "has_foreign_expansion_costs", false)
    has_thermo := object.get(input.jdg_entrepreneur, "has_thermo_costs", false)

    best_combo := []
    best_savings := 0.0
    priority_tip := ""

    # IP Box NAJPIERW (najniższa stawka)
    best_combo := array.concat(best_combo, ["IP Box (5%)"]) { has_ipbox }
    best_savings := best_savings + 0.07 { has_ipbox }

    # Potem B+R
    best_combo := array.concat(best_combo, ["B+R (100-200%)"]) { has_rd }
    best_savings := best_savings + 0.12 { has_rd }

    # Kolejne
    best_combo := array.concat(best_combo, ["Prototyp (30%)"]) { has_proto }
    best_savings := best_savings + 0.036 { has_proto }
    best_combo := array.concat(best_combo, ["Robotyzacja (50%)"]) { has_robot }
    best_savings := best_savings + 0.095 { has_robot }
    best_combo := array.concat(best_combo, ["Ekspansja (1M PLN)"]) { has_exp }
    best_combo := array.concat(best_combo, ["Termomodernizacja (53k)"]) { has_thermo }

    priority_tip = "W zeznaniu rocznym zastosuj ulgi DOKŁADNIE w tej kolejności" { count(best_combo) > 0 }
    priority_tip = "Nie wykryto dostępnych ulg — rozważ inwestycje w B+R" { count(best_combo) == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.cross_relief.fallback",
    "package": "jdg.pit.cross_relief",
    "priority": 999,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26-30cb PIT",
    "_warnings": ["Cross-Relief Optimizer — sprawdź dostępne ulgi i ich kompatybilność. Pamiętaj: B+R i IP Box NIE na tym samym dochodzie!"]
} {
    true
}
