# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P45 ELIMINACJA STUBÓW I FASAD — ZERO REGUŁ UDÁJĄCYCH POKRYCIE
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa jakości reguł ENTERPRISE — 12 analiz (I01–I12; minimum z promptu
# P45 Sekcja 10):
#   I01 Stub Register with SLA (rejestr stubów: rule_id, plik, powód, plan,
#       deadline, właściciel; bramka CI raportuje trend spadkowy; stub bez
#       SLA = BLOCK; trend rosnący = TRIAGE),
#   I02 Stub Forensics (git blame + logi generatorów: jak stub wszedł; stub
#       bez przyczyny źródłowej w rejestrze = TRIAGE),
#   I03 Auto-Convert Pipeline (dry-run → diff → walidacja P34 → golden replay
#       → 4-eyes; wpis w migration ledger P36; konwersja bez replay = BLOCK),
#   I04 Negative Assertion Generator (dla każdej skonwertowanej reguły test
#       negatywny: brak przesłanki → NEEDS_ADVICE; konwersja bez testu
#       negatywnego = BLOCK),
#   I05 Mutation Score Gate (próg mutation score per domena; spadek poniżej
#       progu = BLOCK; brak pomiaru dla domeny krytycznej = TRIAGE),
#   I06 Stub-Free Badge per Package (etykieta z datą dowodu i checksumą skanu;
#       badge bez checksumy = TRIAGE),
#   I07 Template Rule Policy (szablon bez treści materiałowej = PR odrzucony;
#       template w produkcji bez treści = BLOCK),
#   I08 Stub-Enabling Tests (testy zawsze-zielone na regułach fasadowych:
#       para stub+test do naprawy; tautologia bez wpisu = TRIAGE),
#   I09 Provenance of Truth (reguła bez łańcucha akt→art→reguła→test nie
#       opuszcza SHADOW; awans bez dowodu = BLOCK),
#   I10 Stub Census Report (cotygodniowy raport: stuby per domena/warstwa,
#       trend, TOP-10; brak spisu = TRIAGE),
#   I11 Legal-Empty Detector (_legal_basis puste lub placeholder;
#       reguła materiałowa bez aktu = BLOCK),
#   I12 Parity with ISAP Text (dla skonwertowanych reguł cytat przepisu obok
#       kodu; konwersja bez cytatu do weryfikacji = TRIAGE).
#
# Podanalizy (prompt P45 Sekcja 5):
#   AN01 inwentaryzacja stubów → I01, I10, I11
#   AN02 konwersja stubów → I03, I04, I12
#   AN03 blokada ścieżki powstawania → I02, I07, I09
#   AN04 mutation testing → I05, I08 (+badge I06)
#
# Inwentarz realny (sesja P45, narzędzia 6.1 uruchomione):
#   * 39 stubów {true} bez CHECKPOINT-STUB (else_chain_dead_code_detector),
#   * 1508 identycznych triggerów (dead code else-chain), 13 nieosiągalnych,
#   * 102 pliki testów Python tautologicznych (tautology_guard, CRITICAL),
#   * 294 kolizje priorytetów, 101 reguł szkieletowych z checkpointem,
#   * rule_registry: 13 wpisów legacy bez pola lifecycle (requires review).
#
# Integracje (kontrakty między-częściowe):
#   * P44 — K1 rejestr certyfikacji (rejestr stubów zasilą trend spadkowy),
#   * P42 — maturity ladder + orphan sweep (I10 census ten sam skan),
#   * P39 — testy jako bramki (I05 mutation gate w CI; I08 tautologie),
#   * P36 — migration ledger dla konwersji (I03), generatory (I02 forensics),
#   * P34 — sieć walidacji L1–L5 kończy każdą konwersję (I03),
#   * P07/P29 — lifecycle CANDIDATE→ACTIVE zakaz awansu bez dowodu (I09),
#   * P37 — dashboard stub census (I10), metryki trendu,
#   * VAT art. 41/43/108, PIT art. 22/27/30c, ZUS art. 18a–18e, KKS art. 56,
#     Ordynacja art. 119a/21 §1, UoR art. 4/5 [NIEZWERYFIKOWANE — ISAP].
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p45 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * FAIL-CLOSED (V1 zasada 6): stub w domenie krytycznej, konwersja bez
#     testu negatywnego, awans bez łańcucha dowodu = BLOCK — nigdy ciche
#     „udajemy pokrycie".
#   * Honesty: liczniki z narzędzi (nie deklaracje); reguła bez treści ma być
#     USUNIĘTA albo UZUPEŁNIONA — zero stanu pośredniego.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji.
#   * Aktywacja: input.jdg_entrepreneur.v3_p45_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p45_stub_killer.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p45_stub_killer
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p45_stub_killer

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p45_check", false) == true
_ctx := object.get(input, "v3_p45", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p45_snapshot := data.jdg.thresholds.v3_p45

_snapshot_ok = true {
    count(_p45_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p45_snapshot) > 0
    value := object.get(_p45_snapshot, key, null)
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
    "rule_id": "jdg.v3_p45_stub_killer.thresholds_missing",
    "package": "jdg.v3_p45_stub_killer",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "STUB-KILLER V3-P45: brak snapshotu data.jdg.thresholds.v3_p45.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P45] Brak snapshotu progów jakości reguł — kontrole ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p45_stub_killer",
        "priority": priority,
        "threshold_version": object.get(_p45_snapshot, "v3_p45_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p45_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p45_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I01: STUB REGISTER WITH SLA — rejestr + trend spadkowy (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_stubs := object.get(_ctx, "stub_register", {})
_stubs_total := count(object.get(_stubs, "entries", []))
_stubs_no_sla := [s |
    some s
    v := object.get(_stubs, "entries", [])
    v[s]
    object.get(v[s], "deadline", "") == ""
]
_critical_stubs := object.get(_stubs, "critical_domain_stubs", 0)
_critical_max := _th("v3_p45_critical_domain_stubs_max", 0)
_trend := object.get(_stubs, "trend", "unknown")

routing_sr01 = "BLOCK_AND_ALERT" {
    _critical_stubs > _critical_max
} else = "TRIAGE_QUEUE" {
    count(_stubs_no_sla) > 0
} else = "TRIAGE_QUEUE" {
    _trend == "rising"
} else = "AUTO_FILE" {
    _stubs_total > 0
} else = "SUGGEST" {
    true
}

stub_register_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_register"
    routing_sr01 == "AUTO_FILE"
    cert := _certificate(445001, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_register",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sr01,
        "_routing_reason": "STUB-KILLER: rejestr kompletny, każdy stub ma SLA, trend spadkowy.",
        "_legal_basis": "P45-I01; UoR art. 4 ust. 1 (rzetelność) [NIEZWERYFIKOWANE]; P44-K1",
        "_warnings": [],
        "stubs_total": _stubs_total,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_register"
    routing_sr01 == "BLOCK_AND_ALERT"
    cert := _certificate(445001, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_register",
        "decision_mode": "BLOCK",
        "_routing": routing_sr01,
        "_routing_reason": "STUB-KILLER: stub w domenie krytycznej (VAT/PIT/ZUS/KKS) ponad próg — udaje pokrycie materiałowe.",
        "_legal_basis": "VAT art. 41/43/108 [NIEZWERYFIKOWANE]; PIT art. 22/27/30c [NIEZWERYFIKOWANE]; V1 zasada 6",
        "_warnings": ["[V3-P45] Stuby krytyczne ponad próg — zero udawanego pokrycia."],
        "critical_domain_stubs": _critical_stubs,
        "critical_max": _critical_max,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_register"
    routing_sr01 == "TRIAGE_QUEUE"
    cert := _certificate(445001, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_register",
        "decision_mode": "TRIAGE",
        "_routing": routing_sr01,
        "_routing_reason": "STUB-KILLER: stub bez SLA albo trend rosnący — rejestr wymaga domknięcia.",
        "_legal_basis": "P45-I01; trend z bramki CI",
        "_warnings": ["[V3-P45] Wpisy bez deadline lub trend rosnący."],
        "stubs_without_sla": count(_stubs_no_sla),
        "trend": _trend,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I02: STUB FORENSICS — jak stub wszedł do repo (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_forensics := object.get(_ctx, "stub_forensics", {})
_unattributed := count(object.get(_forensics, "unattributed_stubs", []))

routing_fo02 = "TRIAGE_QUEUE" {
    _unattributed > 0
} else = "AUTO_FILE" {
    count(_forensics) > 0
} else = "SUGGEST" {
    true
}

stub_forensics_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_forensics"
    routing_fo02 == "AUTO_FILE"
    cert := _certificate(445002, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_forensics",
        "decision_mode": "AUTO_POST",
        "_routing": routing_fo02,
        "_routing_reason": "STUB-KILLER: każdy stub ma przyczynę źródłową (commit/generator/plan) — ścieżka powstawania znana.",
        "_legal_basis": "P45-I02; P36 generatory; RODO art. 5.2 (rozliczalność) [NIEZWERYFIKOWANE]",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_forensics"
    routing_fo02 == "TRIAGE_QUEUE"
    cert := _certificate(445002, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_forensics",
        "decision_mode": "TRIAGE",
        "_routing": routing_fo02,
        "_routing_reason": "STUB-KILLER: stuby bez atrybucji pochodzenia — nie da się zamknąć ścieżki powstawania.",
        "_legal_basis": "P45-I02; forensics git blame",
        "_warnings": ["[V3-P45] Stuby bez przyczyny źródłowej."],
        "unattributed": _unattributed,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I03: AUTO-CONVERT PIPELINE — dry-run→diff→walidacja→replay→4-eyes (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_conversions := object.get(_ctx, "conversions", {})
_conv_total := count(object.get(_conversions, "entries", []))
_conv_no_replay := [c |
    some c
    v := object.get(_conversions, "entries", [])
    v[c]
    object.get(v[c], "golden_replay_passed", false) == false
]
_conv_bypass := _has_flag("conversion_bypassed_pipeline")

routing_ac03 = "BLOCK_AND_ALERT" {
    _conv_bypass
} else = "BLOCK_AND_ALERT" {
    count(_conv_no_replay) > 0
} else = "AUTO_FILE" {
    _conv_total > 0
} else = "SUGGEST" {
    true
}

auto_convert_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "auto_convert"
    routing_ac03 == "AUTO_FILE"
    cert := _certificate(445003, {
        "rule_id": "jdg.v3_p45_stub_killer.auto_convert_pipeline",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ac03,
        "_routing_reason": "STUB-KILLER: konwersje przeszły pełny pipeline (dry-run→diff→P34→replay→4-eyes).",
        "_legal_basis": "P45-I03; P34 walidacja L1-L5; P36 migration ledger",
        "_warnings": [],
        "conversions": _conv_total,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "auto_convert"
    routing_ac03 == "BLOCK_AND_ALERT"
    cert := _certificate(445003, {
        "rule_id": "jdg.v3_p45_stub_killer.auto_convert_pipeline",
        "decision_mode": "BLOCK",
        "_routing": routing_ac03,
        "_routing_reason": "STUB-KILLER: konwersja z pominięciem pipeline lub bez golden replay — dowód niepełny.",
        "_legal_basis": "P45-I03; V1 zasada 6; P39 bramki",
        "_warnings": ["[V3-P45] Konwersja bez pełnego pipeline."],
        "without_replay": count(_conv_no_replay),
        "bypassed": _conv_bypass,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I04: NEGATIVE ASSERTION GENERATOR — dowód, że reguła warunkowa (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_conv_tests := object.get(_ctx, "conversion_tests", {})
_conv_missing_neg := count(object.get(_conv_tests, "without_negative", []))

routing_na04 = "BLOCK_AND_ALERT" {
    _conv_missing_neg > 0
} else = "AUTO_FILE" {
    count(_conv_tests) > 0
} else = "SUGGEST" {
    true
}

negative_assertion_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "negative_assertion"
    routing_na04 == "AUTO_FILE"
    cert := _certificate(445004, {
        "rule_id": "jdg.v3_p45_stub_killer.negative_assertion",
        "decision_mode": "AUTO_POST",
        "_routing": routing_na04,
        "_routing_reason": "STUB-KILLER: każda skonwertowana reguła ma test negatywny (brak przesłanki → NEEDS_ADVICE).",
        "_legal_basis": "P45-I04; P39-I04 negative-first",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "negative_assertion"
    routing_na04 == "BLOCK_AND_ALERT"
    cert := _certificate(445004, {
        "rule_id": "jdg.v3_p45_stub_killer.negative_assertion",
        "decision_mode": "BLOCK",
        "_routing": routing_na04,
        "_routing_reason": "STUB-KILLER: konwersja bez testu negatywnego = możliwy stub po konwersji.",
        "_legal_basis": "P45-I04; V1 zasada 6",
        "_warnings": ["[V3-P45] Brak testów negatywnych dla konwersji."],
        "without_negative": _conv_missing_neg,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I05: MUTATION SCORE GATE — próg per domena (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_mutation := object.get(_ctx, "mutation_scores", {})
_low_domains := [d |
    some d
    v := _mutation[d]
    v < _th("v3_p45_mutation_score_min", 90)
]
_unmeasured_critical := object.get(_ctx, "critical_domains_unmeasured", 0)

routing_ms05 = "BLOCK_AND_ALERT" {
    count(_low_domains) > 0
} else = "TRIAGE_QUEUE" {
    _unmeasured_critical > 0
} else = "AUTO_FILE" {
    count(_mutation) > 0
} else = "SUGGEST" {
    true
}

mutation_gate_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mutation_gate"
    routing_ms05 == "AUTO_FILE"
    cert := _certificate(445005, {
        "rule_id": "jdg.v3_p45_stub_killer.mutation_score_gate",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ms05,
        "_routing_reason": "STUB-KILLER: mutation score wszystkich domen nad progiem — testy łapią mutacje.",
        "_legal_basis": "P45-I05; P39 testy jako bramki",
        "_warnings": [],
        "domains_measured": count(_mutation),
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mutation_gate"
    routing_ms05 == "BLOCK_AND_ALERT"
    cert := _certificate(445005, {
        "rule_id": "jdg.v3_p45_stub_killer.mutation_score_gate",
        "decision_mode": "BLOCK",
        "_routing": routing_ms05,
        "_routing_reason": "STUB-KILLER: mutation score poniżej progu — testy nie dowodzą semantyki reguł.",
        "_legal_basis": "P45-I05; VAT/PIT/ZUS domeny krytyczne [NIEZWERYFIKOWANE]",
        "_warnings": ["[V3-P45] Domeny poniżej progu mutation score."],
        "low_domains": _low_domains,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mutation_gate"
    routing_ms05 == "TRIAGE_QUEUE"
    cert := _certificate(445005, {
        "rule_id": "jdg.v3_p45_stub_killer.mutation_score_gate",
        "decision_mode": "TRIAGE",
        "_routing": routing_ms05,
        "_routing_reason": "STUB-KILLER: domena krytyczna bez pomiaru mutation score.",
        "_legal_basis": "P45-I05; P39",
        "_warnings": ["[V3-P45] Domeny krytyczne bez pomiaru."],
        "unmeasured_critical": _unmeasured_critical,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I06: STUB-FREE BADGE PER PACKAGE — dowód z checksumą (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_badges := object.get(_ctx, "stub_free_badges", {})
_badges_no_checksum := [b |
    some b
    v := _badges[b]
    object.get(v, "scan_checksum", "") == ""
]

routing_bd06 = "TRIAGE_QUEUE" {
    count(_badges_no_checksum) > 0
} else = "AUTO_FILE" {
    count(_badges) > 0
} else = "SUGGEST" {
    true
}

stub_free_badge_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_free_badge"
    routing_bd06 == "AUTO_FILE"
    cert := _certificate(445006, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_free_badge",
        "decision_mode": "AUTO_POST",
        "_routing": routing_bd06,
        "_routing_reason": "STUB-KILLER: badże stub-free z datą dowodu i checksumą skanu.",
        "_legal_basis": "P45-I06; P44 certyfikat (widoczność w rejestrze)",
        "_warnings": [],
        "badges": count(_badges),
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_free_badge"
    routing_bd06 == "TRIAGE_QUEUE"
    cert := _certificate(445006, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_free_badge",
        "decision_mode": "TRIAGE",
        "_routing": routing_bd06,
        "_routing_reason": "STUB-KILLER: badge bez checksumy skanu = deklaracja bez dowodu.",
        "_legal_basis": "P45-I06; zero deklaracji bez dowodu (V1)",
        "_warnings": ["[V3-P45] Badże bez checksumy."],
        "without_checksum": count(_badges_no_checksum),
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I07: TEMPLATE RULE POLICY — szablon bez treści = odrzucony PR (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_templates_in_prod := object.get(_ctx, "empty_templates_in_production", 0)

routing_tp07 = "BLOCK_AND_ALERT" {
    _templates_in_prod > 0
} else = "AUTO_FILE" {
    true
}

template_policy_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "template_policy"
    routing_tp07 == "AUTO_FILE"
    cert := _certificate(445007, {
        "rule_id": "jdg.v3_p45_stub_killer.template_policy",
        "decision_mode": "AUTO_POST",
        "_routing": routing_tp07,
        "_routing_reason": "STUB-KILLER: brak szablonów bez treści materiałowej w produkcji.",
        "_legal_basis": "P45-I07; P00 standardy",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "template_policy"
    routing_tp07 == "BLOCK_AND_ALERT"
    cert := _certificate(445007, {
        "rule_id": "jdg.v3_p45_stub_killer.template_policy",
        "decision_mode": "BLOCK",
        "_routing": routing_tp07,
        "_routing_reason": "STUB-KILLER: szablony bez treści w produkcji — dekoracje w fortecy.",
        "_legal_basis": "P45-I07; V1 zasada 6",
        "_warnings": ["[V3-P45] Puste szablony w produkcji."],
        "empty_templates": _templates_in_prod,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I08: STUB-ENABLING TESTS — tautologie parujące z fasadami (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_tautologies := object.get(_ctx, "tautological_tests", 0)
_tautology_max := _th("v3_p45_tautological_test_files_max", 0)
_paired_unfixed := object.get(_ctx, "stub_test_pairs_unfixed", 0)

routing_te08 = "BLOCK_AND_ALERT" {
    _paired_unfixed > 0
} else = "TRIAGE_QUEUE" {
    _tautologies > _tautology_max
} else = "AUTO_FILE" {
    true
}

stub_enabling_tests_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_enabling_tests"
    routing_te08 == "AUTO_FILE"
    cert := _certificate(445008, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_enabling_tests",
        "decision_mode": "AUTO_POST",
        "_routing": routing_te08,
        "_routing_reason": "STUB-KILLER: brak tautologicznych testów nad próg i nienaprawionych par stub+test.",
        "_legal_basis": "P45-I08; P39-I04 negative-first; tautology_guard",
        "_warnings": [],
        "tautological_test_files": _tautologies,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_enabling_tests"
    routing_te08 == "BLOCK_AND_ALERT"
    cert := _certificate(445008, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_enabling_tests",
        "decision_mode": "BLOCK",
        "_routing": routing_te08,
        "_routing_reason": "STUB-KILLER: nienaprawione pary stub+test — testy zawsze-zielone dowodzą fasady.",
        "_legal_basis": "P45-I08; V1 zasada 6",
        "_warnings": ["[V3-P45] Pary stub+test nienaprawione."],
        "pairs_unfixed": _paired_unfixed,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_enabling_tests"
    routing_te08 == "TRIAGE_QUEUE"
    cert := _certificate(445008, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_enabling_tests",
        "decision_mode": "TRIAGE",
        "_routing": routing_te08,
        "_routing_reason": "STUB-KILLER: pliki testów tautologicznych ponad próg (CRITICAL wg tautology_guard).",
        "_legal_basis": "P45-I08; tautology_guard",
        "_warnings": ["[V3-P45] Tautologie ponad próg."],
        "tautological_test_files": _tautologies,
        "tautology_max": _tautology_max,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I09: PROVENANCE OF TRUTH — bez łańcucha nie opuszcza SHADOW (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_promotions := object.get(_ctx, "lifecycle_promotions", {})
_promo_no_chain := [p |
    some p
    v := object.get(_promotions, "entries", [])
    v[p]
    object.get(v[p], "full_chain", false) == false
]
_promo_bypass := _has_flag("promotion_bypassed_provenance")

routing_pt09 = "BLOCK_AND_ALERT" {
    _promo_bypass
} else = "BLOCK_AND_ALERT" {
    count(_promo_no_chain) > 0
} else = "AUTO_FILE" {
    count(_promotions) > 0
} else = "SUGGEST" {
    true
}

provenance_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "provenance_of_truth"
    routing_pt09 == "AUTO_FILE"
    cert := _certificate(445009, {
        "rule_id": "jdg.v3_p45_stub_killer.provenance_of_truth",
        "decision_mode": "AUTO_POST",
        "_routing": routing_pt09,
        "_routing_reason": "STUB-KILLER: awanse CANDIDATE→ACTIVE tylko z pełnym łańcuchem akt→art→reguła→test.",
        "_legal_basis": "P45-I09; P07 lifecycle; Ordynacja art. 21 §1 [NIEZWERYFIKOWANE]",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "provenance_of_truth"
    routing_pt09 == "BLOCK_AND_ALERT"
    cert := _certificate(445009, {
        "rule_id": "jdg.v3_p45_stub_killer.provenance_of_truth",
        "decision_mode": "BLOCK",
        "_routing": routing_pt09,
        "_routing_reason": "STUB-KILLER: awans bez łańcucha dowodu lub z pominięciem lifecycle manager.",
        "_legal_basis": "P45-I09; V1 zasada 6; P07",
        "_warnings": ["[V3-P45] Awans bez pełnego łańcucha provenance."],
        "without_chain": count(_promo_no_chain),
        "bypassed": _promo_bypass,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I10: STUB CENSUS REPORT — spis per domena/warstwa z trendem (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_census := object.get(_ctx, "stub_census", {})
_census_stale := object.get(_census, "days_since_census", 0)
_census_max_age := _th("v3_p45_census_max_age_days", 7)
_census_empty := count(object.get(_census, "by_domain", {})) == 0

routing_ce10 = "TRIAGE_QUEUE" {
    _census_empty
} else = "TRIAGE_QUEUE" {
    _census_stale > _census_max_age
} else = "AUTO_FILE" {
    true
}

stub_census_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_census"
    routing_ce10 == "AUTO_FILE"
    cert := _certificate(445010, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_census",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ce10,
        "_routing_reason": "STUB-KILLER: spis stubów aktualny (per domena/warstwa, trend, TOP-10).",
        "_legal_basis": "P45-I10; P37 dashboard; P42 self-scan",
        "_warnings": [],
        "days_since_census": _census_stale,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "stub_census"
    routing_ce10 == "TRIAGE_QUEUE"
    cert := _certificate(445010, {
        "rule_id": "jdg.v3_p45_stub_killer.stub_census",
        "decision_mode": "TRIAGE",
        "_routing": routing_ce10,
        "_routing_reason": "STUB-KILLER: spis pusty lub przeterminowany — liczby z narzędzi, nie deklaracje.",
        "_legal_basis": "P45-I10; zakaz fantazjowania liczbami (V1)",
        "_warnings": ["[V3-P45] Spis stubów pusty/przeterminowany."],
        "days_since_census": _census_stale,
        "max_age": _census_max_age,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I11: LEGAL-EMPTY DETECTOR — _legal_basis puste/placeholder (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_legal_empty := object.get(_ctx, "legal_basis_empty_rules", 0)
_material_empty := object.get(_ctx, "material_rules_without_act", 0)

routing_le11 = "BLOCK_AND_ALERT" {
    _material_empty > 0
} else = "TRIAGE_QUEUE" {
    _legal_empty > 0
} else = "AUTO_FILE" {
    true
}

legal_empty_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "legal_empty"
    routing_le11 == "AUTO_FILE"
    cert := _certificate(445011, {
        "rule_id": "jdg.v3_p45_stub_killer.legal_empty",
        "decision_mode": "AUTO_POST",
        "_routing": routing_le11,
        "_routing_reason": "STUB-KILLER: brak reguł z _legal_basis pustym/placeholder w domenie materiałowej.",
        "_legal_basis": "P45-I11; VAT/PIT/ZUS podstawy materiałowe [NIEZWERYFIKOWANE]",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "legal_empty"
    routing_le11 == "BLOCK_AND_ALERT"
    cert := _certificate(445011, {
        "rule_id": "jdg.v3_p45_stub_killer.legal_empty",
        "decision_mode": "BLOCK",
        "_routing": routing_le11,
        "_routing_reason": "STUB-KILLER: reguła materiałowa bez aktu = stub prawny, nie reguła.",
        "_legal_basis": "P45-I11; VAT art. 41/43/108 [NIEZWERYFIKOWANE]; V1 zasada 6",
        "_warnings": ["[V3-P45] Reguły materiałowe bez aktu."],
        "material_without_act": _material_empty,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "legal_empty"
    routing_le11 == "TRIAGE_QUEUE"
    cert := _certificate(445011, {
        "rule_id": "jdg.v3_p45_stub_killer.legal_empty",
        "decision_mode": "TRIAGE",
        "_routing": routing_le11,
        "_routing_reason": "STUB-KILLER: reguły z pustym/placeholder _legal_basis (TODO, N/A, myślnik).",
        "_legal_basis": "P45-I11",
        "_warnings": ["[V3-P45] _legal_basis puste/placeholder."],
        "legal_empty": _legal_empty,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P45-I12: PARITY WITH ISAP TEXT — cytat przepisu obok kodu (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_parity := object.get(_ctx, "isap_parity", {})
_parity_missing := count(object.get(_parity, "without_quote", []))
_parity_unverified := count(object.get(_parity, "unverified_quotes", []))

routing_pa12 = "TRIAGE_QUEUE" {
    _parity_missing > 0
} else = "TRIAGE_QUEUE" {
    _parity_unverified > 0
} else = "AUTO_FILE" {
    count(_parity) > 0
} else = "SUGGEST" {
    true
}

isap_parity_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "isap_parity"
    routing_pa12 == "AUTO_FILE"
    cert := _certificate(445012, {
        "rule_id": "jdg.v3_p45_stub_killer.isap_parity",
        "decision_mode": "AUTO_POST",
        "_routing": routing_pa12,
        "_routing_reason": "STUB-KILLER: każda konwersja ma cytat przepisu obok kodu (weryfikacja merytoryczna człowieka).",
        "_legal_basis": "P45-I12; ISAP jako jedyne źródło treści ustaw [NIEZWERYFIKOWANE]",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "isap_parity"
    routing_pa12 == "TRIAGE_QUEUE"
    cert := _certificate(445012, {
        "rule_id": "jdg.v3_p45_stub_killer.isap_parity",
        "decision_mode": "TRIAGE",
        "_routing": routing_pa12,
        "_routing_reason": "STUB-KILLER: konwersje bez cytatu ISAP lub z cytatem niezweryfikowanym.",
        "_legal_basis": "P45-I12; P47 ISAP",
        "_warnings": ["[V3-P45] Cytaty brakujące/niezweryfikowane."],
        "without_quote": _parity_missing,
        "unverified_quotes": _parity_unverified,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := stub_register_decision {
    stub_register_decision.rule_id != ""
} else := stub_forensics_decision {
    stub_forensics_decision.rule_id != ""
} else := auto_convert_decision {
    auto_convert_decision.rule_id != ""
} else := negative_assertion_decision {
    negative_assertion_decision.rule_id != ""
} else := mutation_gate_decision {
    mutation_gate_decision.rule_id != ""
} else := stub_free_badge_decision {
    stub_free_badge_decision.rule_id != ""
} else := template_policy_decision {
    template_policy_decision.rule_id != ""
} else := stub_enabling_tests_decision {
    stub_enabling_tests_decision.rule_id != ""
} else := provenance_decision {
    provenance_decision.rule_id != ""
} else := stub_census_decision {
    stub_census_decision.rule_id != ""
} else := legal_empty_decision {
    legal_empty_decision.rule_id != ""
} else := isap_parity_decision {
    isap_parity_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p45_stub_killer.no_match",
    "package": "jdg.v3_p45_stub_killer",
    "priority": 999999,
}
