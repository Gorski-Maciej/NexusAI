# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P50 DEAD CODE I DUPLIKATY — UNIKALNOŚĆ RULE_ID,
# JEDNO ŹRÓDŁO PRAWDY PER ZASADA (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa tożsamości reguł ENTERPRISE — 12 innowacji (I01–I12; minimum z
# promptu P50 Sekcja 10):
#   I01 Semantic duplicate detector (hash warunków + porównanie skutków;
#       pary z identyczną semantyką → rejestr konsolidacji, niezależnie od
#       nazw),
#   I02 Contradiction check (duplikaty dające RÓŻNE wyniki na tym samym input
#       = najwyższy priorytet — decyzja losowa = ryzyko prawne; pojedynczy
#       = BLOCK),
#   I03 Global rule_id uniqueness gate (canonical + mirror + rejestry;
#       pojedyncza kolizja = BLOCK — identyfikator = tożsamość reguły),
#   I04 Single-source-of-truth register (zasada prawna → pakiet źródłowy →
#       rule_id → warianty jawne z powodem; zapytywalny),
#   I05 Dead tool archive (narzędzie martwe → archiwizacja z README powodu →
#       usunięcie po N cyklach bez sprzeciwu; twarde delete = BLOCK),
#   I06 Orphan data sweeper (klucze data.* nieodczytywane przez reguły →
#       rejestr: usunąć/podpiąć/dokumentować; ponad próg = TRIAGE),
#   I07 Ghost doc detector (dokumenty odwołujące się do nieistniejących
#       plików/reguł → rejestr z korektą P41),
#   I08 Duplication prevention in generators (P36: przed dodaniem reguły hash
#       semantyczny — duplikat = fail-fast z linkiem do istniejącej),
#   I09 Consolidation ledger (co scalono, gdzie migrowały odwołania, wynik
#       golden replay — pełna historia konsolidacji),
#   I10 Intentful variants (celowe warianty temporalne/domenowe jako
#       zadeklarowane overlaye P48 — przestają być duplikatami),
#   I11 Rule reachability map (routing → reguły osiągalne → ścieżki wywołania;
#       zero reguł bez punktu wejścia),
#   I12 Duplicate burden metric (% reguł będących duplikatami; cel 0%;
#       trend → P37).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p50 — ADR-002 (P06), okno
#     temporalne valid_from (P05). ZERO hardcode progów.
#   * Fail-closed (V1 zasada 6): brak snapshotu progów, sprzeczne duplikaty,
#     kolizja rule_id = BLOCK — nigdy dwie interpretacje prawa na tę samą
#     datę zdarzenia (art. 24b OP [NIEZWERYFIKOWANE — ISAP]).
#   * Honesty: liczniki z narzędzi i bundli (nie deklaracje); duplikaty
#     mierzone hashem semantycznym warunków (skaner v3_p50_duplicate_
#     detector.py), baseline raportowany uczciwie jako backlog.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     [NIEZWERYFIKOWANE — ISAP] do czasu stempla 4-eyes (protokół 04;
#     konwencja P47/P48/P49).
#   * Aktywacja: input.jdg_entrepreneur.v3_p50_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p50_dead_code.<reguła>.
#   * Kontrakty: P00 (kanon artefaktów), P02/P29 (routing + bramki), P36
#     (generatory), P41 (dokumentacja), P43 (DR), P47 (kanon cytowań),
#     P48 (mapa dryfu canonical↔mirror = wspólny rejestr), P49 (fail-closed),
#     P68 (certyfikacja finalna).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p50_dead_code
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p50_dead_code

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p50_check", false) == true
_ctx := object.get(input, "v3_p50", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p50_snapshot := data.jdg.thresholds.v3_p50

_snapshot_ok = true {
    count(_p50_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p50_snapshot) > 0
    value := object.get(_p50_snapshot, key, null)
    value != null
} else = fallback

_has_flag(key) = result {
    result := object.get(_ctx, key, false) == true
} else = false {
    true
}

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p50_dead_code.thresholds_missing",
    "package": "jdg.v3_p50_dead_code",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "DEAD-CODE V3-P50: brak snapshotu data.jdg.thresholds.v3_p50.",
    "_legal_basis": "ADR-002; V1 zasada 6 (fail-closed); ustawa o rachunkowości art. 4 ust. 1 (sprawdzalność) [NIEZWERYFIKOWANE — ISAP]",
    "_warnings": ["[V3-P50] Brak snapshotu progów tożsamości reguł — kontrole ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p50_dead_code",
        "priority": priority,
        "threshold_version": object.get(_p50_snapshot, "v3_p50_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p50_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p50_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I01: SEMANTIC DUPLICATE DETECTOR — hash warunków (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_dup := object.get(_ctx, "semantic_duplicates", {})
_dup_pairs := object.get(_dup, "duplicate_pairs", 0)
_dup_contra := object.get(_dup, "contradictory_pairs", 0)
_dup_burden := object.get(_dup, "burden_pct", 0)
_dup_max := _th("v3_p50_semantic_dup_max", 0)

routing_sd01 = "BLOCK_AND_ALERT" {
    _has_flag("dedup_bypassed")
} else = "BLOCK_AND_ALERT" {
    _dup_contra > 0
} else = "TRIAGE_QUEUE" {
    _dup_pairs > _dup_max
} else = "AUTO_FILE" {
    true
}

semantic_duplicates_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "semantic_duplicates"
    routing_sd01 == "AUTO_FILE"
    cert := _certificate(450001, {
        "rule_id": "jdg.v3_p50_dead_code.semantic_duplicates",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sd01,
        "_routing_reason": "DEAD-CODE: zero duplikatów semantycznych — jedno źródło prawdy per zasada.",
        "_legal_basis": "P50-I01; AP04; Ordynacja art. 24b (jedna interpretacja na datę zdarzenia) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "duplicate_pairs": _dup_pairs,
        "burden_pct": _dup_burden,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "semantic_duplicates"
    routing_sd01 == "TRIAGE_QUEUE"
    cert := _certificate(450001, {
        "rule_id": "jdg.v3_p50_dead_code.semantic_duplicates",
        "decision_mode": "TRIAGE",
        "_routing": routing_sd01,
        "_routing_reason": "DEAD-CODE: duplikaty semantyczne w rejestrze — konsolidacja wg decyzji per para.",
        "_legal_basis": "P50-I01; AP04; PIT art. 22-30 (jedna zasada kosztu) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P50] Duplikaty semantyczne — plan konsolidacji per para (I04/I09)."],
        "duplicate_pairs": _dup_pairs,
        "dup_max": _dup_max,
        "burden_pct": _dup_burden,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "semantic_duplicates"
    routing_sd01 == "BLOCK_AND_ALERT"
    cert := _certificate(450001, {
        "rule_id": "jdg.v3_p50_dead_code.semantic_duplicates",
        "decision_mode": "BLOCK",
        "_routing": routing_sd01,
        "_routing_reason": "DEAD-CODE: sprzeczne duplikaty / bypass — dwie interpretacje prawa = decyzja losowa.",
        "_legal_basis": "P50-I02; Ordynacja art. 24b; VAT art. 41/43 (jedna stawka) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P50] Sprzeczne duplikaty — ZABLOKOWANE do rozstrzygnięcia."],
        "contradictory_pairs": _dup_contra,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I02: CONTRADICTION CHECK — różne wyniki na tym samym input (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_con := object.get(_ctx, "contradictions", {})
_con_total := object.get(_con, "contradictory_pairs", 0)
_con_unresolved := object.get(_con, "unresolved", 0)
_con_max := _th("v3_p50_contradiction_max", 0)

routing_cc02 = "BLOCK_AND_ALERT" {
    _has_flag("contradiction_bypassed")
} else = "BLOCK_AND_ALERT" {
    _con_total > _con_max
} else = "TRIAGE_QUEUE" {
    _con_unresolved > 0
} else = "AUTO_FILE" {
    true
}

contradictions_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "contradictions"
    routing_cc02 == "AUTO_FILE"
    cert := _certificate(450002, {
        "rule_id": "jdg.v3_p50_dead_code.contradictions",
        "decision_mode": "AUTO_POST",
        "_routing": routing_cc02,
        "_routing_reason": "DEAD-CODE: zero sprzeczności między regułami — determinizm decyzji.",
        "_legal_basis": "P50-I02; ZUS art. 18a (jedna podstawa wymiaru) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "contradictory_pairs": _con_total,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "contradictions"
    routing_cc02 == "TRIAGE_QUEUE"
    cert := _certificate(450002, {
        "rule_id": "jdg.v3_p50_dead_code.contradictions",
        "decision_mode": "TRIAGE",
        "_routing": routing_cc02,
        "_routing_reason": "DEAD-CODE: sprzeczności w rejestrze rozstrzygnięć — dokończyć per para.",
        "_legal_basis": "P50-I02; KKS art. 56 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P50] Sprzeczności nieprzypisane do rozstrzygnięcia."],
        "unresolved": _con_unresolved,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "contradictions"
    routing_cc02 == "BLOCK_AND_ALERT"
    cert := _certificate(450002, {
        "rule_id": "jdg.v3_p50_dead_code.contradictions",
        "decision_mode": "BLOCK",
        "_routing": routing_cc02,
        "_routing_reason": "DEAD-CODE: sprzeczne duplikaty aktywne — najgroźniejsza klasa (decyzja losowa).",
        "_legal_basis": "P50-I02; Ordynacja art. 24b; UoR art. 4 ust. 1 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P50] Reguły dają różne wyniki na tym samym input — BLOCK."],
        "contradictory_pairs": _con_total,
        "max": _con_max,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I03: GLOBAL RULE_ID UNIQUENESS GATE — kolizja = BLOCK (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_uniq := object.get(_ctx, "ruleid_uniqueness", {})
_collisions := object.get(_uniq, "rule_id_collisions", 0)
_scanned_files := object.get(_uniq, "files_scanned", 0)
_collision_max := _th("v3_p50_ruleid_collision_max", 0)

routing_ru03 = "BLOCK_AND_ALERT" {
    _has_flag("uniqueness_bypassed")
} else = "BLOCK_AND_ALERT" {
    _collisions > _collision_max
} else = "TRIAGE_QUEUE" {
    _scanned_files == 0
} else = "AUTO_FILE" {
    true
}

ruleid_uniqueness_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "ruleid_uniqueness"
    routing_ru03 == "AUTO_FILE"
    cert := _certificate(450003, {
        "rule_id": "jdg.v3_p50_dead_code.ruleid_uniqueness",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ru03,
        "_routing_reason": "DEAD-CODE: rule_id globalnie unikalny (canonical + mirror + rejestry).",
        "_legal_basis": "P50-I03; P00 (tożsamość reguły); UoR art. 4 ust. 1 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "files_scanned": _scanned_files,
        "rule_id_collisions": _collisions,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "ruleid_uniqueness"
    routing_ru03 == "TRIAGE_QUEUE"
    cert := _certificate(450003, {
        "rule_id": "jdg.v3_p50_dead_code.ruleid_uniqueness",
        "decision_mode": "TRIAGE",
        "_routing": routing_ru03,
        "_routing_reason": "DEAD-CODE: brak dowodu skanu unikalności — bramka nieuruchomiona.",
        "_legal_basis": "P50-I03; P29 bramki CI",
        "_warnings": ["[V3-P50] Uruchom bramkę unikalności rule_id."],
        "files_scanned": _scanned_files,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "ruleid_uniqueness"
    routing_ru03 == "BLOCK_AND_ALERT"
    cert := _certificate(450003, {
        "rule_id": "jdg.v3_p50_dead_code.ruleid_uniqueness",
        "decision_mode": "BLOCK",
        "_routing": routing_ru03,
        "_routing_reason": "DEAD-CODE: kolizja rule_id — dwie reguły jedną tożsamością = cicha podmiana.",
        "_legal_basis": "P50-I03; AP04; P00 kanon [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P50] Kolizje rule_id — ZABLOKOWANE do rozdzielenia identyfikatorów."],
        "rule_id_collisions": _collisions,
        "max": _collision_max,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I04: SINGLE-SOURCE-OF-TRUTH REGISTER — zasada → źródło (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_sst := object.get(_ctx, "single_source_register", {})
_principles_total := object.get(_sst, "principles_total", 0)
_principles_single := object.get(_sst, "principles_single_source", 0)
_principles_declared := object.get(_sst, "principles_declared_variants", 0)

routing_ss04 = "BLOCK_AND_ALERT" {
    _has_flag("sst_bypassed")
} else = "TRIAGE_QUEUE" {
    _principles_total == 0
} else = "TRIAGE_QUEUE" {
    _principles_single + _principles_declared < _principles_total
} else = "AUTO_FILE" {
    true
}

single_source_register_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "single_source_register"
    routing_ss04 == "AUTO_FILE"
    cert := _certificate(450004, {
        "rule_id": "jdg.v3_p50_dead_code.single_source_register",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ss04,
        "_routing_reason": "DEAD-CODE: każda zasada prawna ma źródło prawdy albo zadeklarowane warianty.",
        "_legal_basis": "P50-I04; P00 jedno źródło prawdy; Ordynacja art. 199a-199c (stabilność) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "principles_total": _principles_total,
        "principles_single_source": _principles_single,
        "principles_declared_variants": _principles_declared,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "single_source_register"
    routing_ss04 == "TRIAGE_QUEUE"
    cert := _certificate(450004, {
        "rule_id": "jdg.v3_p50_dead_code.single_source_register",
        "decision_mode": "TRIAGE",
        "_routing": routing_ss04,
        "_routing_reason": "DEAD-CODE: zasady bez zarejestrowanego źródła prawdy — rejestr do uzupełnienia.",
        "_legal_basis": "P50-I04; P00; AP04",
        "_warnings": ["[V3-P50] Zasady bez źródła prawdy — uzupełnij rejestr I04."],
        "principles_total": _principles_total,
        "principles_single_source": _principles_single,
        "principles_declared_variants": _principles_declared,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I05: DEAD TOOL ARCHIVE — archiwizacja zamiast twardego delete (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_dta := object.get(_ctx, "dead_tool_archive", {})
_dead_tools := object.get(_dta, "dead_tools", 0)
_archived := object.get(_dta, "archived", 0)
_hard_deletes := object.get(_dta, "hard_deletes", 0)

routing_dt05 = "BLOCK_AND_ALERT" {
    _has_flag("archive_bypassed")
} else = "BLOCK_AND_ALERT" {
    _hard_deletes > 0
} else = "TRIAGE_QUEUE" {
    _dead_tools > _archived
} else = "AUTO_FILE" {
    true
}

dead_tool_archive_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "dead_tool_archive"
    routing_dt05 == "AUTO_FILE"
    cert := _certificate(450005, {
        "rule_id": "jdg.v3_p50_dead_code.dead_tool_archive",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dt05,
        "_routing_reason": "DEAD-CODE: martwe narzędzia archiwizowane z README powodu (rollback gotowy).",
        "_legal_basis": "P50-I05; P43 DR (archiwum); RODO art. 5 ust. 1c (minimalizacja) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "dead_tools": _dead_tools,
        "archived": _archived,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "dead_tool_archive"
    routing_dt05 == "TRIAGE_QUEUE"
    cert := _certificate(450005, {
        "rule_id": "jdg.v3_p50_dead_code.dead_tool_archive",
        "decision_mode": "TRIAGE",
        "_routing": routing_dt05,
        "_routing_reason": "DEAD-CODE: martwe narzędzia bez archiwizacji — procedura I05.",
        "_legal_basis": "P50-I05; P41; P43",
        "_warnings": ["[V3-P50] Archiwizuj martwe narzędzia (archive/ + README powodu)."],
        "dead_tools": _dead_tools,
        "archived": _archived,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "dead_tool_archive"
    routing_dt05 == "BLOCK_AND_ALERT"
    cert := _certificate(450005, {
        "rule_id": "jdg.v3_p50_dead_code.dead_tool_archive",
        "decision_mode": "BLOCK",
        "_routing": routing_dt05,
        "_routing_reason": "DEAD-CODE: twarde usunięcie narzędzia — naruszenie procedury archiwizacji.",
        "_legal_basis": "P50-I05; P43 (DR: rollback) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P50] Twarde delete = BLOCK — użyj archiwum."],
        "hard_deletes": _hard_deletes,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I06: ORPHAN DATA SWEEPER — klucze data.* nieodczytywane (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_ods := object.get(_ctx, "orphan_data", {})
_orphan_keys := object.get(_ods, "orphan_keys", 0)
_orphan_decided := object.get(_ods, "decided", 0)
_orphan_max := _th("v3_p50_orphan_data_max", 50)

routing_od06 = "BLOCK_AND_ALERT" {
    _has_flag("orphan_bypassed")
} else = "TRIAGE_QUEUE" {
    _orphan_keys > _orphan_max
} else = "TRIAGE_QUEUE" {
    _orphan_keys > 0
    _orphan_decided < _orphan_keys
} else = "AUTO_FILE" {
    true
}

orphan_data_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "orphan_data"
    routing_od06 == "AUTO_FILE"
    cert := _certificate(450006, {
        "rule_id": "jdg.v3_p50_dead_code.orphan_data",
        "decision_mode": "AUTO_POST",
        "_routing": routing_od06,
        "_routing_reason": "DEAD-CODE: zero martwych danych / wszystkie z decyzją (usunąć/podpiąć/dokumentować).",
        "_legal_basis": "P50-I06; RODO art. 5 ust. 1c (minimalizacja) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "orphan_keys": _orphan_keys,
        "decided": _orphan_decided,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "orphan_data"
    routing_od06 == "TRIAGE_QUEUE"
    cert := _certificate(450006, {
        "rule_id": "jdg.v3_p50_dead_code.orphan_data",
        "decision_mode": "TRIAGE",
        "_routing": routing_od06,
        "_routing_reason": "DEAD-CODE: martwe dane data.* — rejestr decyzji per klucz.",
        "_legal_basis": "P50-I06; RODO art. 5 ust. 1c; AP12",
        "_warnings": ["[V3-P50] Klucze data.* bez odczytu — przypisz decyzję."],
        "orphan_keys": _orphan_keys,
        "orphan_max": _orphan_max,
        "decided": _orphan_decided,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I07: GHOST DOC DETECTOR — dokumenty-widma (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_gdd := object.get(_ctx, "ghost_docs", {})
_ghost_refs := object.get(_gdd, "ghost_references", 0)
_ghost_corrected := object.get(_gdd, "corrected", 0)
_ghost_max := _th("v3_p50_ghost_doc_max", 10)

routing_gd07 = "BLOCK_AND_ALERT" {
    _has_flag("ghost_bypassed")
} else = "TRIAGE_QUEUE" {
    _ghost_refs > _ghost_max
} else = "TRIAGE_QUEUE" {
    _ghost_refs > 0
    _ghost_corrected < _ghost_refs
} else = "AUTO_FILE" {
    true
}

ghost_docs_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "ghost_docs"
    routing_gd07 == "AUTO_FILE"
    cert := _certificate(450007, {
        "rule_id": "jdg.v3_p50_dead_code.ghost_docs",
        "decision_mode": "AUTO_POST",
        "_routing": routing_gd07,
        "_routing_reason": "DEAD-CODE: dokumentacja spójna z repo — zero dokumentów-widm.",
        "_legal_basis": "P50-I07; P41 (dokumentacja jako kod) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "ghost_references": _ghost_refs,
        "corrected": _ghost_corrected,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "ghost_docs"
    routing_gd07 == "TRIAGE_QUEUE"
    cert := _certificate(450007, {
        "rule_id": "jdg.v3_p50_dead_code.ghost_docs",
        "decision_mode": "TRIAGE",
        "_routing": routing_gd07,
        "_routing_reason": "DEAD-CODE: dokumenty odwołują się do nieistniejących elementów — korekta P41.",
        "_legal_basis": "P50-I07; P41",
        "_warnings": ["[V3-P50] Dokumenty-widma — popraw odwołania."],
        "ghost_references": _ghost_refs,
        "ghost_max": _ghost_max,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I08: DUPLICATION PREVENTION IN GENERATORS — fail-fast (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_dpg := object.get(_ctx, "generator_prevention", {})
_gen_guarded := object.get(_dpg, "generators_guarded", 0)
_gen_total := object.get(_dpg, "generators_total", 0)
_gen_blocked := object.get(_dpg, "duplicates_blocked", 0)

routing_gp08 = "BLOCK_AND_ALERT" {
    _has_flag("generator_bypassed")
} else = "TRIAGE_QUEUE" {
    _gen_total > 0
    _gen_guarded < _gen_total
} else = "AUTO_FILE" {
    true
}

generator_prevention_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "generator_prevention"
    routing_gp08 == "AUTO_FILE"
    cert := _certificate(450008, {
        "rule_id": "jdg.v3_p50_dead_code.generator_prevention",
        "decision_mode": "AUTO_POST",
        "_routing": routing_gp08,
        "_routing_reason": "DEAD-CODE: generatory z fail-fast na duplikat (hash semantyczny przed dodaniem).",
        "_legal_basis": "P50-I08; P36 (generatory); AP04 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "generators_total": _gen_total,
        "generators_guarded": _gen_guarded,
        "duplicates_blocked": _gen_blocked,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "generator_prevention"
    routing_gp08 == "TRIAGE_QUEUE"
    cert := _certificate(450008, {
        "rule_id": "jdg.v3_p50_dead_code.generator_prevention",
        "decision_mode": "TRIAGE",
        "_routing": routing_gp08,
        "_routing_reason": "DEAD-CODE: generatory bez zabezpieczenia duplikatów — podłączyć hash check.",
        "_legal_basis": "P50-I08; P36; AP04",
        "_warnings": ["[V3-P50] Dodaj fail-fast do generatorów (I08)."],
        "generators_total": _gen_total,
        "generators_guarded": _gen_guarded,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I09: CONSOLIDATION LEDGER — pełna historia scalania (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_led := object.get(_ctx, "consolidation_ledger", {})
_led_entries := object.get(_led, "entries_total", 0)
_led_replayed := object.get(_led, "golden_replay_ok", 0)
_led_missing_proof := object.get(_led, "entries_missing_replay", 0)

routing_cl09 = "BLOCK_AND_ALERT" {
    _has_flag("ledger_bypassed")
} else = "TRIAGE_QUEUE" {
    _led_entries > 0
    _led_missing_proof > 0
} else = "AUTO_FILE" {
    true
}

consolidation_ledger_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "consolidation_ledger"
    routing_cl09 == "AUTO_FILE"
    cert := _certificate(450009, {
        "rule_id": "jdg.v3_p50_dead_code.consolidation_ledger",
        "decision_mode": "AUTO_POST",
        "_routing": routing_cl09,
        "_routing_reason": "DEAD-CODE: każda konsolidacja z dowodem golden replay (historia pełna).",
        "_legal_basis": "P50-I09; P10 Golden Oracle; K05 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "entries_total": _led_entries,
        "golden_replay_ok": _led_replayed,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "consolidation_ledger"
    routing_cl09 == "TRIAGE_QUEUE"
    cert := _certificate(450009, {
        "rule_id": "jdg.v3_p50_dead_code.consolidation_ledger",
        "decision_mode": "TRIAGE",
        "_routing": routing_cl09,
        "_routing_reason": "DEAD-CODE: konsolidacje bez replay — brak dowodu zachowania decyzji.",
        "_legal_basis": "P50-I09; P10; AP06",
        "_warnings": ["[V3-P50] Uruchom golden replay dla scalonych reguł."],
        "entries_missing_replay": _led_missing_proof,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I10: INTENTFUL VARIANTS — celowe warianty jako overlaye (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_iv := object.get(_ctx, "intentful_variants", {})
_variants_undeclared := object.get(_iv, "undeclared_variants", 0)
_variants_declared := object.get(_iv, "declared_variants", 0)

routing_iv10 = "BLOCK_AND_ALERT" {
    _has_flag("variants_bypassed")
} else = "TRIAGE_QUEUE" {
    _variants_undeclared > 0
} else = "AUTO_FILE" {
    true
}

intentful_variants_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "intentful_variants"
    routing_iv10 == "AUTO_FILE"
    cert := _certificate(450010, {
        "rule_id": "jdg.v3_p50_dead_code.intentful_variants",
        "decision_mode": "AUTO_POST",
        "_routing": routing_iv10,
        "_routing_reason": "DEAD-CODE: warianty celowe zadeklarowane (overlay P48 z powodem i terminem).",
        "_legal_basis": "P50-I10; P48-I05 overlay; P05 temporalność [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "declared_variants": _variants_declared,
        "undeclared_variants": _variants_undeclared,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "intentful_variants"
    routing_iv10 == "TRIAGE_QUEUE"
    cert := _certificate(450010, {
        "rule_id": "jdg.v3_p50_dead_code.intentful_variants",
        "decision_mode": "TRIAGE",
        "_routing": routing_iv10,
        "_routing_reason": "DEAD-CODE: warianty bez deklaracji — zadeklarować albo skonsolidować.",
        "_legal_basis": "P50-I10; P48-I05; AP04",
        "_warnings": ["[V3-P50] Warianty niejawne — overlay albo konsolidacja."],
        "undeclared_variants": _variants_undeclared,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I11: RULE REACHABILITY MAP — zero reguł bez punktu wejścia (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_rrm := object.get(_ctx, "reachability", {})
_rules_total_rrm := object.get(_rrm, "rules_total", 0)
_rules_reachable := object.get(_rrm, "rules_reachable", 0)
_unreachable := object.get(_rrm, "rules_unreachable", 0)
_unreachable_max := _th("v3_p50_unreachable_rules_max", 100)

routing_rm11 = "BLOCK_AND_ALERT" {
    _has_flag("reachability_bypassed")
} else = "TRIAGE_QUEUE" {
    _unreachable > _unreachable_max
} else = "TRIAGE_QUEUE" {
    _rules_total_rrm == 0
} else = "AUTO_FILE" {
    true
}

reachability_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "reachability"
    routing_rm11 == "AUTO_FILE"
    cert := _certificate(450011, {
        "rule_id": "jdg.v3_p50_dead_code.reachability",
        "decision_mode": "AUTO_POST",
        "_routing": routing_rm11,
        "_routing_reason": "DEAD-CODE: wszystkie reguły osiągalne z routingu — zero kodu bez punktu wejścia.",
        "_legal_basis": "P50-I11; P02 routing; dead_rule_detector [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "rules_total": _rules_total_rrm,
        "rules_reachable": _rules_reachable,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "reachability"
    routing_rm11 == "TRIAGE_QUEUE"
    cert := _certificate(450011, {
        "rule_id": "jdg.v3_p50_dead_code.reachability",
        "decision_mode": "TRIAGE",
        "_routing": routing_rm11,
        "_routing_reason": "DEAD-CODE: reguły nieosiągalne z orkiestratora — podpiąć albo zarchiwizować.",
        "_legal_basis": "P50-I11; P02; AP03",
        "_warnings": ["[V3-P50] Reguły martwe (nieosiągalne) — plan per reguła."],
        "rules_unreachable": _unreachable,
        "unreachable_max": _unreachable_max,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50-I12: DUPLICATE BURDEN METRIC — % reguł duplikatów, cel 0% (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_dbm := object.get(_ctx, "duplicate_burden", {})
_rules_all := object.get(_dbm, "rules_total", 0)
_dup_rules := object.get(_dbm, "duplicate_rules", 0)
_burden_pct := 0 {
    _rules_all > 0
    _burden_pct := _dup_rules * 100 / _rules_all
} else := 0 {
    true
}
_burden_target := _th("v3_p50_duplicate_burden_target_pct", 0)

routing_db12 = "BLOCK_AND_ALERT" {
    _has_flag("burden_bypassed")
} else = "TRIAGE_QUEUE" {
    _rules_all == 0
} else = "TRIAGE_QUEUE" {
    _burden_pct > _burden_target
} else = "AUTO_FILE" {
    true
}

duplicate_burden_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "duplicate_burden"
    routing_db12 == "AUTO_FILE"
    cert := _certificate(450012, {
        "rule_id": "jdg.v3_p50_dead_code.duplicate_burden",
        "decision_mode": "AUTO_POST",
        "_routing": routing_db12,
        "_routing_reason": "DEAD-CODE: burden 0% — zero reguł-duplikatów.",
        "_legal_basis": "P50-I12; P37 trend; AP04 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "rules_total": _rules_all,
        "duplicate_rules": _dup_rules,
        "burden_pct": _burden_pct,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "duplicate_burden"
    routing_db12 == "TRIAGE_QUEUE"
    cert := _certificate(450012, {
        "rule_id": "jdg.v3_p50_dead_code.duplicate_burden",
        "decision_mode": "TRIAGE",
        "_routing": routing_db12,
        "_routing_reason": "DEAD-CODE: burden > 0% — trend w P37, redukcja wg planu I04/I09.",
        "_legal_basis": "P50-I12; P37; AP04",
        "_warnings": ["[V3-P50] Burden duplikatów ponad cel — konsolidacja."],
        "rules_total": _rules_all,
        "duplicate_rules": _dup_rules,
        "burden_pct": _burden_pct,
        "target_pct": _burden_target,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny, fail-closed)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := semantic_duplicates_decision {
    semantic_duplicates_decision.rule_id != ""
} else := contradictions_decision {
    contradictions_decision.rule_id != ""
} else := ruleid_uniqueness_decision {
    ruleid_uniqueness_decision.rule_id != ""
} else := single_source_register_decision {
    single_source_register_decision.rule_id != ""
} else := dead_tool_archive_decision {
    dead_tool_archive_decision.rule_id != ""
} else := orphan_data_decision {
    orphan_data_decision.rule_id != ""
} else := ghost_docs_decision {
    ghost_docs_decision.rule_id != ""
} else := generator_prevention_decision {
    generator_prevention_decision.rule_id != ""
} else := consolidation_ledger_decision {
    consolidation_ledger_decision.rule_id != ""
} else := intentful_variants_decision {
    intentful_variants_decision.rule_id != ""
} else := reachability_decision {
    reachability_decision.rule_id != ""
} else := duplicate_burden_decision {
    duplicate_burden_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p50_dead_code.no_match",
    "package": "jdg.v3_p50_dead_code",
    "priority": 999999,
}
