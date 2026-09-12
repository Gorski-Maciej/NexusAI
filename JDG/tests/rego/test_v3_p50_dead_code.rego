# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P50 DEAD CODE I DUPLIKATY (konwencja
# P39/P45–P49: negative-first, granice progów, fail-closed, never-silent
# AUTO_POST, bypass → BLOCK, determinizm else-chain).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p50_dead_code_test

import future.keywords.every
import data.jdg.v3_p50_dead_code as p50

# ── Helper ─────────────────────────────────────────────────────────────────────
p50_input(analysis, ctx) = {"jdg_entrepreneur": {"v3_p50_check": true},
                            "v3_p50": object.union({"analysis": analysis}, ctx)}

# ═══════════════════════════════════════════════════════════════════════════════
# Determinizm łańcucha / aktywacja
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_no_activation_no_match {
    r := p50.decide with input as {}
    r.rule_id == "jdg.v3_p50_dead_code.no_match"
    r.matched == false
}

test_p50_no_selector_no_match {
    r := p50.decide with input as p50_input("brak_takiej_analizy", {})
    r.rule_id == "jdg.v3_p50_dead_code.no_match"
}

test_p50_null_analysis_no_match {
    r := p50.decide with input as {"jdg_entrepreneur": {"v3_p50_check": true},
                                   "v3_p50": {"analysis": null}}
    r.rule_id == "jdg.v3_p50_dead_code.no_match"
}

test_p50_thresholds_missing_fail_closed {
    # default-deny: brak snapshotu progów = BLOCK, nigdy cicha decyzja (AP07)
    r := p50.decide with input as p50_input("semantic_duplicates", {})
        with data.jdg.thresholds.v3_p50 as {}
    r.rule_id == "jdg.v3_p50_dead_code.thresholds_missing"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.priority == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# I01/I12: semantic duplicates + burden (granice dup_max=0)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i01_zero_duplicates_autos {
    r := p50.decide with input as p50_input("semantic_duplicates", {
        "semantic_duplicates": {"duplicate_pairs": 0, "contradictory_pairs": 0,
                                "burden_pct": 0.0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.duplicate_pairs == 0
}

test_p50_i01_duplicates_triage {
    r := p50.decide with input as p50_input("semantic_duplicates", {
        "semantic_duplicates": {"duplicate_pairs": 3, "contradictory_pairs": 0,
                                "burden_pct": 0.4},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
    r.duplicate_pairs == 3
}

test_p50_i02_contradiction_in_dup_analysis_blocks {
    # sprzeczność widziana już na poziomie analizy I01 → BLOCK
    r := p50.decide with input as p50_input("semantic_duplicates", {
        "semantic_duplicates": {"duplicate_pairs": 0, "contradictory_pairs": 1,
                                "burden_pct": 0.0},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p50_i01_dedup_bypass_blocks {
    r := p50.decide with input as p50_input("semantic_duplicates", {
        "semantic_duplicates": {"duplicate_pairs": 0, "contradictory_pairs": 0},
        "dedup_bypassed": true,
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I02: contradiction check (granice contradiction_max=0)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i02_zero_contradictions_autos {
    r := p50.decide with input as p50_input("contradictions", {
        "contradictions": {"contradictory_pairs": 0, "unresolved": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p50_i02_unresolved_blocks {
    # sprzeczność NIEROZSTRZYGNIĘTA = decyzja losowa = BLOCK (art. 24b OP);
    # payload BLOCK niesie unresolved dla alertu/alertingu P37
    r := p50.decide with input as p50_input("contradictions", {
        "contradictions": {"contradictory_pairs": 2, "unresolved": 1},
    })
    r.decision_mode == "BLOCK"
    r.unresolved == 1
}

test_p50_i02_resolved_over_max_blocks {
    # max=0: nawet rozstrzygnięte pary = BLOCK do czasu FIZYCZNEJ
    # konsolidacji (rejestr I02 dokumentuje decyzję, nie czyści BLOCK)
    r := p50.decide with input as p50_input("contradictions", {
        "contradictions": {"contradictory_pairs": 1, "unresolved": 0},
    })
    r.decision_mode == "BLOCK"
    r.contradictory_pairs == 1
}

test_p50_i02_resolved_within_max_triages {
    # progi jako dane (ADR-002): podniesienie max = jawna decyzja 4-eyes;
    # pary w limicie i rozstrzygnięte → TRIAGE (dokończyć konsolidację)
    r := p50.decide with input as p50_input("contradictions", {
        "contradictions": {"contradictory_pairs": 1, "unresolved": 0},
    }) with data.jdg.thresholds.v3_p50 as {"v3_p50_contradiction_max": 1,
                                           "v3_p50_threshold_version": "test",
                                           "legal_basis_version": "test",
                                           "valid_from": "2026-01-01"}
    r.decision_mode == "TRIAGE"
    r.contradictory_pairs == 1
}

test_p50_i02_contradiction_bypass_blocks {
    r := p50.decide with input as p50_input("contradictions", {
        "contradictions": {"contradictory_pairs": 0, "unresolved": 0},
        "contradiction_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I03: rule_id uniqueness gate (granice collision_max=0)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i03_zero_collisions_autos {
    r := p50.decide with input as p50_input("ruleid_uniqueness", {
        "ruleid_uniqueness": {"rule_id_collisions": 0, "files_scanned": 1129},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.files_scanned == 1129
}

test_p50_i03_collision_blocks {
    r := p50.decide with input as p50_input("ruleid_uniqueness", {
        "ruleid_uniqueness": {"rule_id_collisions": 1, "files_scanned": 1129},
    })
    r.decision_mode == "BLOCK"
    r.rule_id_collisions == 1
}

test_p50_i03_no_scan_triages {
    r := p50.decide with input as p50_input("ruleid_uniqueness", {
        "ruleid_uniqueness": {"rule_id_collisions": 0, "files_scanned": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p50_i03_uniqueness_bypass_blocks {
    r := p50.decide with input as p50_input("ruleid_uniqueness", {
        "ruleid_uniqueness": {"rule_id_collisions": 0, "files_scanned": 100},
        "uniqueness_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I04: single-source-of-truth register
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i04_fully_covered_autos {
    r := p50.decide with input as p50_input("single_source_register", {
        "single_source_register": {"principles_total": 12383,
                                   "principles_single_source": 12383,
                                   "principles_declared_variants": 0},
    })
    r.decision_mode == "AUTO_POST"
}

test_p50_i04_empty_register_triages {
    r := p50.decide with input as p50_input("single_source_register", {
        "single_source_register": {"principles_total": 0,
                                   "principles_single_source": 0,
                                   "principles_declared_variants": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p50_i04_uncovered_principles_triage {
    r := p50.decide with input as p50_input("single_source_register", {
        "single_source_register": {"principles_total": 100,
                                   "principles_single_source": 90,
                                   "principles_declared_variants": 5},
    })
    r.decision_mode == "TRIAGE"
    r.principles_total == 100
}

test_p50_i04_sst_bypass_blocks {
    r := p50.decide with input as p50_input("single_source_register", {
        "single_source_register": {"principles_total": 10,
                                   "principles_single_source": 10},
        "sst_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I05: dead tool archive (twarde delete = BLOCK; brak archiwizacji = TRIAGE)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i05_all_archived_autos {
    r := p50.decide with input as p50_input("dead_tool_archive", {
        "dead_tool_archive": {"dead_tools": 2, "archived": 2, "hard_deletes": 0},
    })
    r.decision_mode == "AUTO_POST"
    r.dead_tools == 2
}

test_p50_i05_unarchived_triages {
    r := p50.decide with input as p50_input("dead_tool_archive", {
        "dead_tool_archive": {"dead_tools": 65, "archived": 0, "hard_deletes": 0},
    })
    r.decision_mode == "TRIAGE"
    r.dead_tools == 65
}

test_p50_i05_hard_delete_blocks {
    r := p50.decide with input as p50_input("dead_tool_archive", {
        "dead_tool_archive": {"dead_tools": 0, "archived": 0, "hard_deletes": 1},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p50_i05_archive_bypass_blocks {
    r := p50.decide with input as p50_input("dead_tool_archive", {
        "dead_tool_archive": {"dead_tools": 0, "archived": 0, "hard_deletes": 0},
        "archive_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I06: orphan data (granice orphan_max=50; decyzje per klucz)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i06_zero_orphans_autos {
    r := p50.decide with input as p50_input("orphan_data", {
        "orphan_data": {"orphan_keys": 0, "decided": 0},
    })
    r.decision_mode == "AUTO_POST"
}

test_p50_i06_orphans_at_max_triages {
    r := p50.decide with input as p50_input("orphan_data", {
        "orphan_data": {"orphan_keys": 50, "decided": 0},
    })
    r.decision_mode == "TRIAGE"
    r.orphan_keys == 50
}

test_p50_i06_orphans_over_max_triages {
    r := p50.decide with input as p50_input("orphan_data", {
        "orphan_data": {"orphan_keys": 51, "decided": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p50_i06_undecided_triages {
    r := p50.decide with input as p50_input("orphan_data", {
        "orphan_data": {"orphan_keys": 3, "decided": 1},
    })
    r.decision_mode == "TRIAGE"
}

test_p50_i06_orphan_bypass_blocks {
    r := p50.decide with input as p50_input("orphan_data", {
        "orphan_data": {"orphan_keys": 0, "decided": 0},
        "orphan_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I07: ghost docs (granice ghost_max=10)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i07_zero_ghosts_autos {
    r := p50.decide with input as p50_input("ghost_docs", {
        "ghost_docs": {"ghost_references": 0, "corrected": 0},
    })
    r.decision_mode == "AUTO_POST"
}

test_p50_i07_ghosts_at_max_triages {
    r := p50.decide with input as p50_input("ghost_docs", {
        "ghost_docs": {"ghost_references": 10, "corrected": 0},
    })
    r.decision_mode == "TRIAGE"
    r.ghost_references == 10
}

test_p50_i07_ghosts_over_max_triages {
    r := p50.decide with input as p50_input("ghost_docs", {
        "ghost_docs": {"ghost_references": 11, "corrected": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p50_i07_all_corrected_autos {
    r := p50.decide with input as p50_input("ghost_docs", {
        "ghost_docs": {"ghost_references": 4, "corrected": 4},
    })
    r.decision_mode == "AUTO_POST"
}

test_p50_i07_ghost_bypass_blocks {
    r := p50.decide with input as p50_input("ghost_docs", {
        "ghost_docs": {"ghost_references": 0, "corrected": 0},
        "ghost_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I08: generator prevention
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i08_all_guarded_autos {
    r := p50.decide with input as p50_input("generator_prevention", {
        "generator_prevention": {"generators_total": 96,
                                 "generators_guarded": 96,
                                 "duplicates_blocked": 0},
    })
    r.decision_mode == "AUTO_POST"
}

test_p50_i08_unguarded_triages {
    r := p50.decide with input as p50_input("generator_prevention", {
        "generator_prevention": {"generators_total": 96,
                                 "generators_guarded": 23,
                                 "duplicates_blocked": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p50_i08_no_generators_triages {
    r := p50.decide with input as p50_input("generator_prevention", {
        "generator_prevention": {"generators_total": 0,
                                 "generators_guarded": 0,
                                 "duplicates_blocked": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p50_i08_generator_bypass_blocks {
    r := p50.decide with input as p50_input("generator_prevention", {
        "generator_prevention": {"generators_total": 5,
                                 "generators_guarded": 5,
                                 "duplicates_blocked": 0},
        "generator_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I09: consolidation ledger (brak dowodu replay = TRIAGE)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i09_no_entries_autos {
    r := p50.decide with input as p50_input("consolidation_ledger", {
        "consolidation_ledger": {"entries_total": 0, "golden_replay_ok": 0,
                                 "entries_missing_replay": 0},
    })
    r.decision_mode == "AUTO_POST"
}

test_p50_i09_missing_replay_triages {
    r := p50.decide with input as p50_input("consolidation_ledger", {
        "consolidation_ledger": {"entries_total": 3, "golden_replay_ok": 1,
                                 "entries_missing_replay": 2},
    })
    r.decision_mode == "TRIAGE"
    r.entries_missing_replay == 2
}

test_p50_i09_ledger_bypass_blocks {
    r := p50.decide with input as p50_input("consolidation_ledger", {
        "consolidation_ledger": {"entries_total": 0, "golden_replay_ok": 0,
                                 "entries_missing_replay": 0},
        "ledger_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I10: intentful variants (undeclared > 0 = TRIAGE)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i10_all_declared_autos {
    r := p50.decide with input as p50_input("intentful_variants", {
        "intentful_variants": {"undeclared_variants": 0,
                               "declared_variants": 7},
    })
    r.decision_mode == "AUTO_POST"
    r.declared_variants == 7
}

test_p50_i10_undeclared_triages {
    r := p50.decide with input as p50_input("intentful_variants", {
        "intentful_variants": {"undeclared_variants": 2,
                               "declared_variants": 0},
    })
    r.decision_mode == "TRIAGE"
    r.undeclared_variants == 2
}

test_p50_i10_variants_bypass_blocks {
    r := p50.decide with input as p50_input("intentful_variants", {
        "intentful_variants": {"undeclared_variants": 0,
                               "declared_variants": 1},
        "variants_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I11: reachability (granice unreachable_max=100)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i11_all_reachable_autos {
    r := p50.decide with input as p50_input("reachability", {
        "reachability": {"rules_total": 12382, "rules_reachable": 12382,
                         "rules_unreachable": 0},
    })
    r.decision_mode == "AUTO_POST"
}

test_p50_i11_unreachable_at_max_triages {
    r := p50.decide with input as p50_input("reachability", {
        "reachability": {"rules_total": 12482, "rules_reachable": 12382,
                         "rules_unreachable": 100},
    })
    r.decision_mode == "TRIAGE"
    r.rules_unreachable == 100
}

test_p50_i11_unreachable_over_max_triages {
    r := p50.decide with input as p50_input("reachability", {
        "reachability": {"rules_total": 12483, "rules_reachable": 12382,
                         "rules_unreachable": 101},
    })
    r.decision_mode == "TRIAGE"
}

test_p50_i11_no_map_triages {
    r := p50.decide with input as p50_input("reachability", {
        "reachability": {"rules_total": 0, "rules_reachable": 0,
                         "rules_unreachable": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p50_i11_reachability_bypass_blocks {
    r := p50.decide with input as p50_input("reachability", {
        "reachability": {"rules_total": 10, "rules_reachable": 10,
                         "rules_unreachable": 0},
        "reachability_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I12: duplicate burden (granica target_pct=0)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_i12_burden_zero_autos {
    r := p50.decide with input as p50_input("duplicate_burden", {
        "duplicate_burden": {"rules_total": 413, "duplicate_rules": 0,
                             "burden_pct": 0.0},
    })
    r.decision_mode == "AUTO_POST"
    r.burden_pct == 0.0
}

test_p50_i12_burden_over_target_triages {
    r := p50.decide with input as p50_input("duplicate_burden", {
        "duplicate_burden": {"rules_total": 413, "duplicate_rules": 2,
                             "burden_pct": 0.48},
    })
    r.decision_mode == "TRIAGE"
    r.burden_pct == 0.48
}

test_p50_i12_no_rules_triages {
    r := p50.decide with input as p50_input("duplicate_burden", {
        "duplicate_burden": {"rules_total": 0, "duplicate_rules": 0,
                             "burden_pct": 0.0},
    })
    r.decision_mode == "TRIAGE"
}

test_p50_i12_burden_bypass_blocks {
    r := p50.decide with input as p50_input("duplicate_burden", {
        "duplicate_burden": {"rules_total": 413, "duplicate_rules": 0,
                             "burden_pct": 0.0},
        "burden_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Kontrakt P03: rule_id w każdej decyzji (brak nadpisań safe_merge)
# ═══════════════════════════════════════════════════════════════════════════════
test_p50_every_verdict_has_rule_id {
    analyses := ["semantic_duplicates", "contradictions", "ruleid_uniqueness",
                 "single_source_register", "dead_tool_archive", "orphan_data",
                 "ghost_docs", "generator_prevention", "consolidation_ledger",
                 "intentful_variants", "reachability", "duplicate_burden"]
    every a in analyses {
        r := p50.decide with input as p50_input(a, {})
        startswith(r.rule_id, "jdg.v3_p50_dead_code.")
    }
}

test_p50_no_silent_auto_post_without_full_evidence {
    # AUTO_POST wymaga AUTO_FILE routing — routing BLOCK/TRIAGE nigdy nie
    # zwraca decision_mode AUTO_POST (fasada fail-closed = niemożliwa)
    r1 := p50.decide with input as p50_input("semantic_duplicates", {
        "semantic_duplicates": {"duplicate_pairs": 9,
                                "contradictory_pairs": 0}})
    r2 := p50.decide with input as p50_input("dead_tool_archive", {
        "dead_tool_archive": {"dead_tools": 10, "archived": 1,
                              "hard_deletes": 0}})
    r1.decision_mode != "AUTO_POST"
    r2.decision_mode != "AUTO_POST"
}
