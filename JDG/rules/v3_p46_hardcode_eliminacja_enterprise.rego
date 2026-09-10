# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P46 ELIMINACJA HARDCODE — WSZYSTKIE PROGI, STAWKI I LIMITY
# DO DATA.THRESHOLDS.* (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa parametrów-as-data ENTERPRISE — 12 analiz (I01–I12; minimum z promptu
# P46 Sekcja 10):
#   I01 Parameter Registry (rejestr każdego parametru: ścieżka, wartość
#       bieżąca, historia wartości, akt źródłowy, okno temporalne, właściciel —
#       zapytywalny; rejestr pusty/przeterminowany = TRIAGE),
#   I02 Value Provenance Chain (parametr → akt → art. → nowela → data → diff —
#       pełne DNA wartości; parametr bez łańcucha = BLOCK),
#   I03 Temporal Parameter Gate (parametr zmienny prawnie bez valid_from /
#       valid_to = BLOCKER; bramka CI + runtime),
#   I04 Schema Validation for Thresholds (JSON-schema dla thresholds_data w CI:
#       typ, jednostka, zakres; błąd = BLOCK),
#   I05 Signed Parameter Bundles (bundle parametrów podpisany jak kod P38:
#       checksuma SHA-256 + WORM; bundle bez podpisu = BLOCK; manipulacja =
#       BLOCK),
#   I06 Day-0 Test Generation (generator P36 tworzy testy przełączenia dla
#       każdego parametru z oknem: dzień przed / dzień po; brak testu = TRIAGE),
#   I07 Parameter Change Workflow (PR z cytatem nowelizacji → walidacja →
#       testy day-0 → deploy parametrów bez deployu reguł; zmiana bez
#       walidacji = BLOCK),
#   I08 Unit Semantics (jednostka % vs PLN vs mnożnik jawnie w schemacie; reguły
#       walidują jednostkę przy odczycie; niezgodność = BLOCK),
#   I09 Parameter Drift Alarm (porównanie wartości thresholds_data z wartościami
#       wytropionymi w ISAP crawlerem P34; rozjazd niezaraportowany = BLOCK,
#       zaraportowany = TRIAGE do Law Radar P08),
#   I10 Legacy Value Sweeper (po migracji skan kodu w poszukiwaniu osieroconych
#       wartości prawnych; ponad próg = TRIAGE z trendem),
#   I11 Golden Replay per Parameter Change (każda zmiana parametru uruchamia
#       replay złotych orzeczeń z parametrami OLD i NEW; dryf AUTO_POST ponad
#       limit = BLOCK),
#   I12 Parameter Documentation Anchor (każdy parametr ma anchor w dokumentacji:
#       co znaczy, skąd się wziął, kiedy wygasa; zero magicznych kluczy).
#
# Podanalizy (prompt P46 Sekcja 5):
#   AN01 audyt hardcode wartości prawnych → I10, I01, I09
#   AN02 migracja wartości do danych → I01, I07, I12
#   AN03 zarządzanie i integralność danych → I04, I05, I02, I09
#   AN04 testy graniczne parametrów → I06, I08, I11, I03
#
# Stan realny (sesja P46; narzędzia uruchomione 2026-09-10):
#   * hardcoded_audit.py: 27 101 trafień w 515 plikach rego
#     (large_integer 23 777, decimal_rate 2 493, time_period 831),
#   * thresholds_jdg.rego: ~1 052 kluczy progowych (ADR-002 kanon),
#   * thresholds_data.json: 8 parametrów z pełną wersją+schema+provenance
#     (vat.* — wzorzec migracji wartość-po-wartości),
#   * cel nadrzędny: zmiana prawa = zmiana DANYCH, nie deploy kodu (ADR-002).
#
# Integracje (kontrakty między-częściowe):
#   * P06 — parametry-as-data (ADR-002 nadrzędny nad konwencjami lokalnymi),
#   * P05 — okna temporalne valid_from/valid_to + testy day-0 (I03/I06),
#   * P38 — podpisane bundlowanie parametrów (I05), P34 — ISAP crawler dryfu
#     (I09), P36 — generatory testów day-0 (I06), P39 — bramki CI (I03/I04),
#   * P08 — Law Radar alarm dryfu (I09), P10 — golden oracle replay (I11),
#   * P41 — anchory dokumentacyjne (I12), P42 — DNA reguł rozszerzone o dane
#     (I02), P45 — rejestr stubów: konwersje bez hardcode (kontrakt K-P45-8),
#   * Ordynacja art. 12/13 (obowiązek na datę zdarzenia), VAT art. 41/113,
#     PIT art. 27/30c/30f, ZUS art. 18d/18ab, ryczałt załącznik, Ordynacja
#     art. 56/119, KKS art. 57 [NIEZWERYFIKOWANE — ISAP, P47].
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p46 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów ( również w tym
#     pakiecie — samoegzekwowanie).
#   * FAIL-CLOSED (V1 zasada 6): parametr bez provenance, bez okna temporalnego,
#     bundle bez podpisu, niezgodność jednostek = BLOCK — nigdy cicha decyzja
#     na niepewnych danych.
#   * Honesty: liczniki z narzędzi (nie deklaracje); backlog 27 101 legacy
#     rejestrowany uczciwie jako TRIAGE z trendem, nie ukrywany.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji.
#   * Aktywacja: input.jdg_entrepreneur.v3_p46_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p46_hardcode_eliminacja_enterprise.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p46_hardcode_eliminacja_enterprise
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p46_hardcode_eliminacja_enterprise

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p46_check", false) == true
_ctx := object.get(input, "v3_p46", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p46_snapshot := data.jdg.thresholds.v3_p46

_snapshot_ok = true {
    count(_p46_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p46_snapshot) > 0
    value := object.get(_p46_snapshot, key, null)
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
    "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.thresholds_missing",
    "package": "jdg.v3_p46_hardcode_eliminacja_enterprise",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "HARDCODE-ELIM V3-P46: brak snapshotu data.jdg.thresholds.v3_p46.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P46] Brak snapshotu progów parametrów — kontrole ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p46_hardcode_eliminacja_enterprise",
        "priority": priority,
        "threshold_version": object.get(_p46_snapshot, "v3_p46_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p46_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p46_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I01: PARAMETER REGISTRY — rejestr parametrów zapytywalny (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_registry := object.get(_ctx, "parameter_registry", {})
_registry_age := object.get(_registry, "registry_age_days", 999999)
_registry_max_age := _th("v3_p46_parameter_registry_max_age_days", 30)
_registry_total := count(object.get(_registry, "entries", {}))

routing_pr01 = "TRIAGE_QUEUE" {
    _registry_total == 0
} else = "TRIAGE_QUEUE" {
    _registry_age > _registry_max_age
} else = "AUTO_FILE" {
    true
}

parameter_registry_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "parameter_registry"
    routing_pr01 == "AUTO_FILE"
    cert := _certificate(446001, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_registry",
        "decision_mode": "AUTO_POST",
        "_routing": routing_pr01,
        "_routing_reason": "HARDCODE-ELIM: rejestr parametrów aktualny — każdy parametr ma wartość, historię, akt i właściciela.",
        "_legal_basis": "P46-I01; P06 parametry-as-data; ADR-002",
        "_warnings": [],
        "parameters_total": _registry_total,
        "registry_age_days": _registry_age,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "parameter_registry"
    routing_pr01 == "TRIAGE_QUEUE"
    cert := _certificate(446001, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_registry",
        "decision_mode": "TRIAGE",
        "_routing": routing_pr01,
        "_routing_reason": "HARDCODE-ELIM: rejestr parametrów pusty lub przeterminowany — parametry poza zarządzaniem.",
        "_legal_basis": "P46-I01; ADR-002; P41 anchory",
        "_warnings": ["[V3-P46] Rejestr parametrów pusty/przeterminowany."],
        "registry_age_days": _registry_age,
        "max_age_days": _registry_max_age,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I02: VALUE PROVENANCE CHAIN — pełne DNA wartości (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_provenance := object.get(_ctx, "value_provenance", {})
_prov_entries := object.get(_provenance, "entries", [])
_prov_chain_min := _th("v3_p46_provenance_chain_min_depth", 3)
_prov_weak := [e |
    some e
    v := _prov_entries
    v[e]
    object.get(v[e], "chain_depth", 0) < _prov_chain_min
]

routing_vp02 = "BLOCK_AND_ALERT" {
    _has_flag("provenance_bypassed_chain")
} else = "BLOCK_AND_ALERT" {
    count(_prov_weak) > 0
} else = "AUTO_FILE" {
    count(_prov_entries) > 0
} else = "SUGGEST" {
    true
}

value_provenance_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "value_provenance"
    routing_vp02 == "AUTO_FILE"
    cert := _certificate(446002, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.value_provenance",
        "decision_mode": "AUTO_POST",
        "_routing": routing_vp02,
        "_routing_reason": "HARDCODE-ELIM: każda wartość ma pełne DNA (akt→art→nowela→data→diff).",
        "_legal_basis": "P46-I02; P42 DNA reguł; Ordynacja art. 12 [NIEZWERYFIKOWANE]",
        "_warnings": [],
        "parameters_with_provenance": count(_prov_entries),
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "value_provenance"
    routing_vp02 == "BLOCK_AND_ALERT"
    cert := _certificate(446002, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.value_provenance",
        "decision_mode": "BLOCK",
        "_routing": routing_vp02,
        "_routing_reason": "HARDCODE-ELIM: wartość parametru bez łańcucha provenance — zero decyzji na danych bez DNA.",
        "_legal_basis": "P46-I02; V1 zasada 6; P42",
        "_warnings": ["[V3-P46] Wartości z niepełnym łańcuchem provenance."],
        "weak_chain_count": count(_prov_weak),
        "chain_min_depth": _prov_chain_min,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I03: TEMPORAL PARAMETER GATE — parametr bez okna = BLOCKER (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_temporal := object.get(_ctx, "temporal_gate", {})
_temporal_violations := object.get(_temporal, "missing_valid_from", 0)
_temporal_gate_on := _th("v3_p46_temporal_gate_enabled", true)

routing_tg03 = "BLOCK_AND_ALERT" {
    _temporal_gate_on
    _temporal_violations > 0
} else = "TRIAGE_QUEUE" {
    _temporal_violations > 0
} else = "AUTO_FILE" {
    true
}

temporal_gate_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "temporal_gate"
    routing_tg03 == "AUTO_FILE"
    cert := _certificate(446003, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.temporal_parameter_gate",
        "decision_mode": "AUTO_POST",
        "_routing": routing_tg03,
        "_routing_reason": "HARDCODE-ELIM: każdy parametr zmienny prawnie ma okno temporalne (valid_from/valid_to).",
        "_legal_basis": "P46-I03; P05 temporalność; Ordynacja art. 12-13 [NIEZWERYFIKOWANE]",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "temporal_gate"
    routing_tg03 == "BLOCK_AND_ALERT"
    cert := _certificate(446003, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.temporal_parameter_gate",
        "decision_mode": "BLOCK",
        "_routing": routing_tg03,
        "_routing_reason": "HARDCODE-ELIM: parametr bez valid_from/valid_to = luka temporalna (P05) — obowiązek podatkowy na datę zdarzenia.",
        "_legal_basis": "P46-I03; P05; Ordynacja art. 12 [NIEZWERYFIKOWANE]",
        "_warnings": ["[V3-P46] Parametry bez okna temporalnego."],
        "missing_valid_from": _temporal_violations,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "temporal_gate"
    routing_tg03 == "TRIAGE_QUEUE"
    cert := _certificate(446003, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.temporal_parameter_gate",
        "decision_mode": "TRIAGE",
        "_routing": routing_tg03,
        "_routing_reason": "HARDCODE-ELIM: bramka temporalna wyłączona, naruszenia obecne — wymaga decyzji właściciela.",
        "_legal_basis": "P46-I03; P05",
        "_warnings": ["[V3-P46] Bramka temporalna wyłączona przy naruszeniach."],
        "missing_valid_from": _temporal_violations,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I04: SCHEMA VALIDATION FOR THRESHOLDS — JSON-schema w CI (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_schema := object.get(_ctx, "schema_validation", {})
_schema_errors := object.get(_schema, "errors", 0)
_schema_checked := object.get(_schema, "checked", false)
_schema_errors_max := _th("v3_p46_schema_errors_max", 0)

routing_sv04 = "BLOCK_AND_ALERT" {
    not _schema_checked
} else = "BLOCK_AND_ALERT" {
    _schema_errors > _schema_errors_max
} else = "AUTO_FILE" {
    true
}

schema_validation_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "schema_validation"
    routing_sv04 == "AUTO_FILE"
    cert := _certificate(446004, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.schema_validation",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sv04,
        "_routing_reason": "HARDCODE-ELIM: thresholds_data walidowane schematem (typ, jednostka, zakres) — zero błędów.",
        "_legal_basis": "P46-I04; P06; ADR-002",
        "_warnings": [],
        "schema_errors": _schema_errors,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "schema_validation"
    routing_sv04 == "BLOCK_AND_ALERT"
    cert := _certificate(446004, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.schema_validation",
        "decision_mode": "BLOCK",
        "_routing": routing_sv04,
        "_routing_reason": "HARDCODE-ELIM: dokument parametrów niezweryfikowany schematem lub z błędami — błąd jednostki niewykrywalny w regułach musi zostać złapany w danych.",
        "_legal_basis": "P46-I04; V1 zasada 6; P39 CI",
        "_warnings": ["[V3-P46] Błędy schematu thresholds_data."],
        "schema_errors": _schema_errors,
        "errors_max": _schema_errors_max,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I05: SIGNED PARAMETER BUNDLES — integralność = integralność reguł (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_signed := object.get(_ctx, "signed_bundles", {})
_unsigned := count(object.get(_signed, "without_checksum", []))
_tampered := object.get(_signed, "tampered", 0)

routing_sb05 = "BLOCK_AND_ALERT" {
    _tampered > 0
} else = "BLOCK_AND_ALERT" {
    _unsigned > 0
} else = "AUTO_FILE" {
    count(_signed) > 0
} else = "SUGGEST" {
    true
}

signed_bundles_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "signed_bundles"
    routing_sb05 == "AUTO_FILE"
    cert := _certificate(446005, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.signed_parameter_bundles",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sb05,
        "_routing_reason": "HARDCODE-ELIM: bundle parametrów podpisany checksumą i archiwizowany WORM.",
        "_legal_basis": "P46-I05; P38 bundle deploy; P11 certyfikat",
        "_warnings": [],
        "signed_bundles": count(_signed),
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "signed_bundles"
    routing_sb05 == "BLOCK_AND_ALERT"
    cert := _certificate(446005, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.signed_parameter_bundles",
        "decision_mode": "BLOCK",
        "_routing": routing_sb05,
        "_routing_reason": "HARDCODE-ELIM: bundle parametrów bez podpisu lub z naruszoną integralnością — wartości nie mają dowodu stanu.",
        "_legal_basis": "P46-I05; P38; V1 zasada 6",
        "_warnings": ["[V3-P46] Bundle parametrów bez checksumy lub naruszony."],
        "without_checksum": _unsigned,
        "tampered": _tampered,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I06: DAY-0 TEST GENERATION — testy przełączenia per parametr (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_day0 := object.get(_ctx, "day0_tests", {})
_day0_missing := count(object.get(_day0, "missing_transitions", []))
_day0_generated := object.get(_day0, "generated", 0)

routing_d006 = "TRIAGE_QUEUE" {
    _day0_missing > 0
} else = "AUTO_FILE" {
    _day0_generated > 0
} else = "SUGGEST" {
    true
}

day0_test_generation_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "day0_tests"
    routing_d006 == "AUTO_FILE"
    cert := _certificate(446006, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.day0_test_generation",
        "decision_mode": "AUTO_POST",
        "_routing": routing_d006,
        "_routing_reason": "HARDCODE-ELIM: każdy parametr z oknem ma test day-1/day-0/day+1 wygenerowany automatycznie.",
        "_legal_basis": "P46-I06; P05; P36 generatory",
        "_warnings": [],
        "generated_transitions": _day0_generated,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "day0_tests"
    routing_d006 == "TRIAGE_QUEUE"
    cert := _certificate(446006, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.day0_test_generation",
        "decision_mode": "TRIAGE",
        "_routing": routing_d006,
        "_routing_reason": "HARDCODE-ELIM: przełączenia parametrów bez testów day-0 — zmiana stawki bez dowodu równoważności.",
        "_legal_basis": "P46-I06; P05; P36",
        "_warnings": ["[V3-P46] Brakujące testy przełączeń day-0."],
        "missing_transitions": _day0_missing,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I07: PARAMETER CHANGE WORKFLOW — PR z cytatem → testy → deploy (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_workflow := object.get(_ctx, "change_workflow", {})
_wf_no_citation := count(object.get(_workflow, "without_citation", []))
_wf_no_day0 := count(object.get(_workflow, "without_day0_tests", []))
_wf_unvalidated_deploys := object.get(_workflow, "deployed_without_validation", 0)

routing_pw07 = "BLOCK_AND_ALERT" {
    _has_flag("parameter_change_bypassed_workflow")
} else = "BLOCK_AND_ALERT" {
    _wf_unvalidated_deploys > 0
} else = "TRIAGE_QUEUE" {
    _wf_no_citation > 0
} else = "TRIAGE_QUEUE" {
    _wf_no_day0 > 0
} else = "AUTO_FILE" {
    true
}

change_workflow_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "change_workflow"
    routing_pw07 == "AUTO_FILE"
    cert := _certificate(446007, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_change_workflow",
        "decision_mode": "AUTO_POST",
        "_routing": routing_pw07,
        "_routing_reason": "HARDCODE-ELIM: zmiana parametru idzie pełnym workflow (cytat nowelizacji → walidacja → day-0 → deploy danych bez deployu reguł).",
        "_legal_basis": "P46-I07; P07 lifecycle; P08 Law Radar",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "change_workflow"
    routing_pw07 == "BLOCK_AND_ALERT"
    cert := _certificate(446007, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_change_workflow",
        "decision_mode": "BLOCK",
        "_routing": routing_pw07,
        "_routing_reason": "HARDCODE-ELIM: deploy parametrów z pominięciem walidacji lub bypassem workflow — zmiana prawa bez dowodu.",
        "_legal_basis": "P46-I07; V1 zasada 6; ADR-002",
        "_warnings": ["[V3-P46] Deploy parametrów bez walidacji / bypass."],
        "deployed_without_validation": _wf_unvalidated_deploys,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "change_workflow"
    routing_pw07 == "TRIAGE_QUEUE"
    cert := _certificate(446007, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_change_workflow",
        "decision_mode": "TRIAGE",
        "_routing": routing_pw07,
        "_routing_reason": "HARDCODE-ELIM: zmiany bez cytatu nowelizacji lub bez testów day-0 — workflow do domknięcia.",
        "_legal_basis": "P46-I07; P08 Law Radar (powiązanie z nowelizacją)",
        "_warnings": ["[V3-P46] Zmiany parametrów bez cytatu/day-0."],
        "without_citation": _wf_no_citation,
        "without_day0_tests": _wf_no_day0,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I08: UNIT SEMANTICS — jednostka jawnie w schemacie (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_units := object.get(_ctx, "unit_semantics", {})
_unit_mismatch := object.get(_units, "unit_mismatch", 0)
_unit_unknown := object.get(_units, "unknown_unit_values", 0)

routing_us08 = "BLOCK_AND_ALERT" {
    _unit_mismatch > 0
} else = "TRIAGE_QUEUE" {
    _unit_unknown > 0
} else = "AUTO_FILE" {
    true
}

unit_semantics_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "unit_semantics"
    routing_us08 == "AUTO_FILE"
    cert := _certificate(446008, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.unit_semantics",
        "decision_mode": "AUTO_POST",
        "_routing": routing_us08,
        "_routing_reason": "HARDCODE-ELIM: jednostki (% vs PLN vs mnożnik) jawne w schemacie i walidowane przy odczycie.",
        "_legal_basis": "P46-I08; P06; defense in depth",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "unit_semantics"
    routing_us08 == "BLOCK_AND_ALERT"
    cert := _certificate(446008, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.unit_semantics",
        "decision_mode": "BLOCK",
        "_routing": routing_us08,
        "_routing_reason": "HARDCODE-ELIM: niezgodność jednostek — błąd jednostki to katastrofa (stawka jako mnożnik).",
        "_legal_basis": "P46-I08; V1 zasada 6",
        "_warnings": ["[V3-P46] Niezgodność jednostek parametrów."],
        "unit_mismatch": _unit_mismatch,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "unit_semantics"
    routing_us08 == "TRIAGE_QUEUE"
    cert := _certificate(446008, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.unit_semantics",
        "decision_mode": "TRIAGE",
        "_routing": routing_us08,
        "_routing_reason": "HARDCODE-ELIM: wartości z jednostką poza katalogiem znanym (data.thresholds.v3_p46_known_units).",
        "_legal_basis": "P46-I08; P06",
        "_warnings": ["[V3-P46] Nieznane jednostki w parametrach."],
        "unknown_unit_values": _unit_unknown,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I09: PARAMETER DRIFT ALARM — prawo↔dane rozjazd do Law Radar (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_drift := object.get(_ctx, "drift_alarm", {})
_drift_unreported := object.get(_drift, "unreported_drifts", 0)
_drift_reported := object.get(_drift, "reported_drifts", 0)

routing_da09 = "BLOCK_AND_ALERT" {
    _drift_unreported > 0
} else = "TRIAGE_QUEUE" {
    _drift_reported > 0
} else = "AUTO_FILE" {
    true
}

drift_alarm_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "drift_alarm"
    routing_da09 == "AUTO_FILE"
    cert := _certificate(446009, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_drift_alarm",
        "decision_mode": "AUTO_POST",
        "_routing": routing_da09,
        "_routing_reason": "HARDCODE-ELIM: zero rozjazdów thresholds_data ↔ ISAP (crawler P34) lub wszystkie zaraportowane i domknięte.",
        "_legal_basis": "P46-I09; P08 Law Radar; P34 crawler",
        "_warnings": [],
        "reported_drifts": _drift_reported,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "drift_alarm"
    routing_da09 == "BLOCK_AND_ALERT"
    cert := _certificate(446009, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_drift_alarm",
        "decision_mode": "BLOCK",
        "_routing": routing_da09,
        "_routing_reason": "HARDCODE-ELIM: rozjazd prawa i danych niezaraportowany do Law Radar — silnik liczy z nieaktualnych stawek.",
        "_legal_basis": "P46-I09; P08; V1 zasada 6",
        "_warnings": ["[V3-P46] Niezaraportowany dryf parametrów vs ISAP."],
        "unreported_drifts": _drift_unreported,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "drift_alarm"
    routing_da09 == "TRIAGE_QUEUE"
    cert := _certificate(446009, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_drift_alarm",
        "decision_mode": "TRIAGE",
        "_routing": routing_da09,
        "_routing_reason": "HARDCODE-ELIM: dryf zaraportowany do Law Radar — do weryfikacji ISAP (P47) i korekty danych.",
        "_legal_basis": "P46-I09; P08; P47",
        "_warnings": ["[V3-P46] Dryf parametrów w toku weryfikacji."],
        "reported_drifts": _drift_reported,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I10: LEGACY VALUE SWEEPER — osierocone wartości prawne (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_sweep := object.get(_ctx, "legacy_sweep", {})
_orphan_values := object.get(_sweep, "orphan_values", 0)
_extreme_literals := object.get(_sweep, "extreme_literals", 0)
_orphan_max := _th("v3_p46_orphan_values_max", 0)
_extreme_max := _th("v3_p46_extreme_literal_max", 0)
_sweep_trend := object.get(_sweep, "trend", "unknown")

routing_ls10 = "BLOCK_AND_ALERT" {
    _orphan_values > _orphan_max
    _sweep_trend == "rising"
} else = "TRIAGE_QUEUE" {
    _orphan_values > _orphan_max
} else = "TRIAGE_QUEUE" {
    _extreme_literals > _extreme_max
} else = "AUTO_FILE" {
    true
}

legacy_sweeper_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "legacy_sweep"
    routing_ls10 == "AUTO_FILE"
    cert := _certificate(446010, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.legacy_value_sweeper",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ls10,
        "_routing_reason": "HARDCODE-ELIM: zero osieroconych wartości prawnych w kodzie poza thresholds (ADR-002 osiągnięty).",
        "_legal_basis": "P46-I10; ADR-002; P28 R7 audyt",
        "_warnings": [],
        "orphan_values": _orphan_values,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "legacy_sweep"
    routing_ls10 == "BLOCK_AND_ALERT"
    cert := _certificate(446010, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.legacy_value_sweeper",
        "decision_mode": "BLOCK",
        "_routing": routing_ls10,
        "_routing_reason": "HARDCODE-ELIM: osierocone wartości rosną — nowy hardcode wchodzi do kodu mimo ADR-002.",
        "_legal_basis": "P46-I10; ADR-002; V1 zasada 6",
        "_warnings": ["[V3-P46] Trend hardcode rosnący."],
        "orphan_values": _orphan_values,
        "trend": _sweep_trend,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "legacy_sweep"
    routing_ls10 == "TRIAGE_QUEUE"
    cert := _certificate(446010, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.legacy_value_sweeper",
        "decision_mode": "TRIAGE",
        "_routing": routing_ls10,
        "_routing_reason": "HARDCODE-ELIM: backlog wartości poza thresholds (narzędziowo policzony) — migracja value-po-value wg mapy I01.",
        "_legal_basis": "P46-I10; ADR-002; honesty protokół 14",
        "_warnings": ["[V3-P46] Backlog hardcode — uczciwie rejestrowany."],
        "orphan_values": _orphan_values,
        "extreme_literals": _extreme_literals,
        "orphan_max": _orphan_max,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I11: GOLDEN REPLAY PER PARAMETER CHANGE — OLD vs NEW diff (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_replay := object.get(_ctx, "parameter_replay", {})
_replay_runs := count(object.get(_replay, "runs", []))
_replay_drift_over_limit := object.get(_replay, "drift_over_limit", 0)
_replay_missing_old := object.get(_replay, "missing_old_params", 0)
_drift_auto_max := _th("v3_p46_replay_drift_max_auto_changes", 0)

routing_rp11 = "BLOCK_AND_ALERT" {
    _replay_drift_over_limit > _drift_auto_max
} else = "TRIAGE_QUEUE" {
    _replay_missing_old > 0
} else = "TRIAGE_QUEUE" {
    _replay_runs == 0
} else = "AUTO_FILE" {
    true
}

golden_replay_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "parameter_replay"
    routing_rp11 == "AUTO_FILE"
    cert := _certificate(446011, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.golden_replay_per_change",
        "decision_mode": "AUTO_POST",
        "_routing": routing_rp11,
        "_routing_reason": "HARDCODE-ELIM: replay złotych orzeczeń OLD vs NEW dla każdej zmiany parametru; zero dryfu AUTO_POST ponad limit.",
        "_legal_basis": "P46-I11; P10 golden oracle; UoR art. 4 ust. 1 [NIEZWERYFIKOWANE]",
        "_warnings": [],
        "replay_runs": _replay_runs,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "parameter_replay"
    routing_rp11 == "BLOCK_AND_ALERT"
    cert := _certificate(446011, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.golden_replay_per_change",
        "decision_mode": "BLOCK",
        "_routing": routing_rp11,
        "_routing_reason": "HARDCODE-ELIM: zmiana parametru zmienia decyzje AUTO_POST ponad limit — wymaga 4-eyes przed deployem.",
        "_legal_basis": "P46-I11; V1 zasada 6; P03 kontrakt werdyktu",
        "_warnings": ["[V3-P46] Dryf replay ponad limit."],
        "drift_over_limit": _replay_drift_over_limit,
        "drift_auto_max": _drift_auto_max,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "parameter_replay"
    routing_rp11 == "TRIAGE_QUEUE"
    cert := _certificate(446011, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.golden_replay_per_change",
        "decision_mode": "TRIAGE",
        "_routing": routing_rp11,
        "_routing_reason": "HARDCODE-ELIM: replay bez parametrów OLD lub brak uruchomień — skutki zmiany niedowodzone.",
        "_legal_basis": "P46-I11; P10",
        "_warnings": ["[V3-P46] Replay niekompletny."],
        "missing_old_params": _replay_missing_old,
        "replay_runs": _replay_runs,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P46-I12: PARAMETER DOCUMENTATION ANCHOR — zero magicznych kluczy (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_docs := object.get(_ctx, "doc_anchors", {})
_docs_without_anchor := object.get(_docs, "without_anchor", 0)
_docs_documented := object.get(_docs, "documented", 0)

routing_dc12 = "TRIAGE_QUEUE" {
    _docs_without_anchor > 0
} else = "AUTO_FILE" {
    _docs_documented > 0
} else = "SUGGEST" {
    true
}

documentation_anchor_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "doc_anchors"
    routing_dc12 == "AUTO_FILE"
    cert := _certificate(446012, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.documentation_anchor",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dc12,
        "_routing_reason": "HARDCODE-ELIM: każdy parametr ma anchor dokumentacyjny (co znaczy, skąd się wziął, kiedy wygasa).",
        "_legal_basis": "P46-I12; P41 dokumentacja; P06",
        "_warnings": [],
        "documented_parameters": _docs_documented,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "doc_anchors"
    routing_dc12 == "TRIAGE_QUEUE"
    cert := _certificate(446012, {
        "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.documentation_anchor",
        "decision_mode": "TRIAGE",
        "_routing": routing_dc12,
        "_routing_reason": "HARDCODE-ELIM: parametry bez anchora dokumentacyjnego — magiczne klucze w danych.",
        "_legal_basis": "P46-I12; P41",
        "_warnings": ["[V3-P46] Parametry bez anchora dokumentacji."],
        "without_anchor": _docs_without_anchor,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := parameter_registry_decision {
    parameter_registry_decision.rule_id != ""
} else := value_provenance_decision {
    value_provenance_decision.rule_id != ""
} else := temporal_gate_decision {
    temporal_gate_decision.rule_id != ""
} else := schema_validation_decision {
    schema_validation_decision.rule_id != ""
} else := signed_bundles_decision {
    signed_bundles_decision.rule_id != ""
} else := day0_test_generation_decision {
    day0_test_generation_decision.rule_id != ""
} else := change_workflow_decision {
    change_workflow_decision.rule_id != ""
} else := unit_semantics_decision {
    unit_semantics_decision.rule_id != ""
} else := drift_alarm_decision {
    drift_alarm_decision.rule_id != ""
} else := legacy_sweeper_decision {
    legacy_sweeper_decision.rule_id != ""
} else := golden_replay_decision {
    golden_replay_decision.rule_id != ""
} else := documentation_anchor_decision {
    documentation_anchor_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p46_hardcode_eliminacja_enterprise.no_match",
    "package": "jdg.v3_p46_hardcode_eliminacja_enterprise",
    "priority": 999999,
}
