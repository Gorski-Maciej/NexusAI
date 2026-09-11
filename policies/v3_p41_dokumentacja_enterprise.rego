# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P41 DOKUMENTACJA ENTERPRISE — JEDNO ŹRÓDŁO PRAWDY, SPÓJNOŚĆ
# Z KODEM (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa dokumentacji ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Doc-Code Binding (każdy dokument ma front-matter z listą artefaktów;
#       zmiana kodu bez dokumentacji = BLOCK na bramce docs P29; brak bindowania
#       = BLOCK),
#   I02 Single Source of Truth Numbers (liczby reguł/plików generowane z repo —
#       zero ręcznych liczb; ręczna liczba sprzeczna z MANIFEST = BLOCK; P34
#       doc_consistency_validator jako silnik),
#   I03 Role-Based Doc Maps (mapy czytania per rola: developer/operator/audytor/
#       przedsiębiorca; rola bez mapy = TRIAGE),
#   I04 Semantic Diff PL/EN (ARCHITEKTURA.md vs ARCHITECTURE.md — dryf
#       semantyczny = TRIAGE; narzędzie diff = wymóg; brak narzędzia = BLOCK),
#   I05 Glossary Enforcement (termin z glosariusza użyty inaczej = BLOCKER;
#       naruszenia > próg = BLOCK; SLOWNIK_REFERENCJI_PRAWNYCH jako źródło),
#   I06 Audit Export Pack (jedno polecenie: dokumenty + rejestry + checksumy +
#       pieczęć; eksport bez checksumy = BLOCK; UoR art. 4, Ordynacja 193a),
#   I07 Runbook Coverage (każdy alarm P37 ma runbook; pokrycie < 100% = TRIAGE;
#       alarm bez runbooka na produkcji = BLOCK),
#   I08 Changelog Automation (changelog generowany z rejestru wdrożeń P30/ledger
#       V3; ręczny changelog = TRIAGE; changelog starszy niż próg = TRIAGE),
#   I09 Doc Freshness Stamps („ostatnia weryfikacja" per dokument; wiek > próg =
#       TRIAGE; brak stempla = TRIAGE),
#   I10 Documentation Testing (przykłady curl/rego w dokumentach testowane w CI
#       — example-as-test; przykład zepsuty = BLOCK; brak mechanizmu = TRIAGE),
#   I11 Auditor Mode (widok audytora: pełne ścieżki dowodowe per domena; brak
#       ścieżki dla domeny = TRIAGE),
#   I12 Legacy Doc Retirement (statusy CURRENT/ARCHIVED/SUPERSEDED w
#       front-matter; dokument bez statusu = TRIAGE; dwa CURRENT dla tej samej
#       roli/artefaktu = BLOCK — kanibalizm wersji).
#
# Podanalizy (prompt P41 Sekcja 5):
#   AN01 dokument = prawda weryfikowalna → I01, I02, I04, I09
#   AN02 warstwy i role → I03, I07, I11
#   AN03 glosariusz i rejestry → I05
#   AN04 dokumentacja jako dowód → I06, I08, I10, I12
#
# Integracje (kontrakty między-częściowe):
#   * P00 — mapa kanoniczna artefaktów: dokumentacja opisuje realny stan,
#   * P29 — bramka docs w CI (jakość): docs-as-code wymuszony,
#   * P34 — doc_consistency_validator: silnik detekcji dryfu liczba↔repo,
#   * P37 — katalog SLO/alamów: runbook coverage (I07), dashboardy,
#   * P30/P36 — rejestry wdrożeń i generatory: changelog automation (I08),
#   * P40 — API docs: struktura dokumentacji wiąże dokumentację API,
#   * P43 — WORM: archiwizacja dokumentacji (I06 eksport z checksumą),
#   * P44 — certyfikacja finalna: eksport audytowy jako dowód.
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p41 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * FAIL-CLOSED (V1 zasada 6): dokument bez bindowania, eksport bez checksumy,
#     dwa CURRENT = BLOCK — nigdy cicha dokumentacja-kobiałka.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p41_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p41_dokumentacja.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p41_dokumentacja
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p41_dokumentacja

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p41_check", false) == true
_ctx := object.get(input, "v3_p41", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p41_snapshot := data.jdg.thresholds.v3_p41

_snapshot_ok = true {
    count(_p41_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p41_snapshot) > 0
    value := object.get(_p41_snapshot, key, null)
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
    "rule_id": "jdg.v3_p41_dokumentacja.thresholds_missing",
    "package": "jdg.v3_p41_dokumentacja",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "DOKUMENTACJA V3-P41: brak snapshotu data.jdg.thresholds.v3_p41.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P41] Brak snapshotu progów dokumentacji — bramki docs ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p41_dokumentacja",
        "priority": priority,
        "threshold_version": object.get(_p41_snapshot, "v3_p41_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p41_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p41_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I01: DOC-CODE BINDING — dokument ↔ artefakty (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_db := object.get(_ctx, "doc_code_binding", {})
_db_missing := _has_flag("doc_binding_missing")
_db_stale := object.get(_db, "stale_bindings", 0)
_db_gate := _has_flag("docs_gate_in_ci")

routing_db01 = "BLOCK_AND_ALERT" {
    _db_missing
} else = "BLOCK_AND_ALERT" {
    not _db_gate
} else = "TRIAGE_QUEUE" {
    _db_stale > 0
} else = "SUGGEST" {
    true
}

reason_db01 = sprintf("Brak bindowania dokument↔artefakt (front-matter) — BLOCK (zmiana kodu bez docs przechodzi cicho; P29 bramka docs).", []) {
    _db_missing
} else = sprintf("Bramka docs nieobecna w CI — BLOCK (docs-as-code niewymuszony; P29).", []) {
    not _db_gate
} else = sprintf("Przestarzałe bindowania (git diff wykrył dryf): %v — TRIAGE (bramka docs bloka merge).", [_db_stale]) {
    _db_stale > 0
} else = sprintf("Doc-code binding OK: front-matter + bramka CI aktywne.", []) {
    true
}

doc_code_binding_decision := _certificate(441001, {
    "rule_id": "jdg.v3_p41_dokumentacja.doc_code_binding",
    "analysis": "doc_code_binding",
    "doc_binding_missing": _db_missing,
    "docs_gate_in_ci": _db_gate,
    "stale_bindings": _db_stale,
    "_routing": routing_db01,
    "_routing_reason": reason_db01,
    "_legal_basis": "V3_P41 §10/I01; UoR art. 4 ust. 1-3 (sprawdzalność) [NIEZWERYFIKOWANE]; kontrakt P29 (bramka docs), P00 (mapa kanoniczna)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "doc_code_binding"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I02: SSOT NUMBERS — liczby generowane z repo (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_sn := object.get(_ctx, "ssot_numbers", {})
_sn_drift := object.get(_sn, "handwritten_numbers_in_drift", 0)
_sn_no_validator := _has_flag("consistency_validator_missing")

routing_sn02 = "BLOCK_AND_ALERT" {
    _sn_no_validator
} else = "TRIAGE_QUEUE" {
    _sn_drift > 0
} else = "SUGGEST" {
    true
}

reason_sn02 = sprintf("Brak walidatora spójności dokument↔repo — BLOCK (P34 doc_consistency_validator jako silnik SSOT).", []) {
    _sn_no_validator
} else = sprintf("Ręczne liczby w dryfie (dokument → liczba → rzeczywistość): %v — TRIAGE (liczby generowane z repo do snippetów; KATALOG_REGUL vs MANIFEST).", [_sn_drift]) {
    _sn_drift > 0
} else = sprintf("SSOT numbers OK: liczby w dokumentach generowane z repo (zero ręcznych).", []) {
    true
}

ssot_numbers_decision := _certificate(441002, {
    "rule_id": "jdg.v3_p41_dokumentacja.ssot_numbers",
    "analysis": "ssot_numbers",
    "handwritten_numbers_in_drift": _sn_drift,
    "consistency_validator_missing": _sn_no_validator,
    "_routing": routing_sn02,
    "_routing_reason": reason_sn02,
    "_legal_basis": "V3_P41 §10/I02; kontrakt P34 (walidator), P00 (kanon artefaktów)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "ssot_numbers"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I03: ROLE-BASED DOC MAPS — mapy czytania per rola (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_rm := object.get(_ctx, "role_doc_maps", {})
_rm_missing := object.get(_rm, "roles_without_map", 0)
_rm_roles := object.get(_rm, "roles", [])

_expected_role(r) {
    r == "developer"
}
_expected_role(r) {
    r == "operator"
}
_expected_role(r) {
    r == "auditor"
}
_expected_role(r) {
    r == "entrepreneur"
}

routing_rm03 = "TRIAGE_QUEUE" {
    _rm_missing > 0
} else = "SUGGEST" {
    true
}

reason_rm03 = sprintf("Role bez mapy czytania: %v — TRIAGE (developer/operator/audytor/przedsiębiorca; onboarding w minuty).", [_rm_missing]) {
    _rm_missing > 0
} else = sprintf("Role doc maps OK: mapy dla %v.", [_rm_roles]) {
    true
}

role_doc_maps_decision := _certificate(441003, {
    "rule_id": "jdg.v3_p41_dokumentacja.role_doc_maps",
    "analysis": "role_doc_maps",
    "roles_without_map": _rm_missing,
    "roles": _rm_roles,
    "_routing": routing_rm03,
    "_routing_reason": reason_rm03,
    "_legal_basis": "V3_P41 §10/I03; kontrakt P40 (UI decyzji), P37 (dashboardy operatora)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "role_doc_maps"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I04: SEMANTIC DIFF PL/EN — ARCHITEKTURA vs ARCHITECTURE (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_sd := object.get(_ctx, "semantic_diff_pl_en", {})
_sd_findings := object.get(_sd, "drift_findings", 0)
_sd_no_tool := _has_flag("semantic_diff_tool_missing")
_sd_max := _th("v3_p41_plen_diff_max_findings", 0)

routing_sd04 = "BLOCK_AND_ALERT" {
    _sd_no_tool
} else = "TRIAGE_QUEUE" {
    _sd_findings > _sd_max
} else = "SUGGEST" {
    true
}

reason_sd04 = sprintf("Brak narzędzia diff semantycznego PL/EN — BLOCK (ARCHITEKTURA.md vs ARCHITECTURE.md bez detekcji = cichy rozjazd).", []) {
    _sd_no_tool
} else = sprintf("Dryf semantyczny PL/EN: %v > %v — TRIAGE (przekład semantyczny, nie słowo w słowo; drift = alarm).", [_sd_findings, _sd_max]) {
    _sd_findings > _sd_max
} else = sprintf("Semantic diff PL/EN OK: bez dryfu (%v findings ≤ %v).", [_sd_findings, _sd_max]) {
    true
}

semantic_diff_pl_en_decision := _certificate(441004, {
    "rule_id": "jdg.v3_p41_dokumentacja.semantic_diff_pl_en",
    "analysis": "semantic_diff_pl_en",
    "drift_findings": _sd_findings,
    "semantic_diff_tool_missing": _sd_no_tool,
    "plen_diff_max_findings": _sd_max,
    "_routing": routing_sd04,
    "_routing_reason": reason_sd04,
    "_legal_basis": "V3_P41 §10/I04; kontrakt P34 (spójność), mirror EN/PL (4.3)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "semantic_diff_pl_en"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I05: GLOSSARY ENFORCEMENT — konsekwencja językowa (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_ge := object.get(_ctx, "glossary_enforcement", {})
_ge_violations := object.get(_ge, "glossary_violations", 0)
_ge_no_source := _has_flag("glossary_source_missing")
_ge_max := _th("v3_p41_glossary_violations_max", 0)

routing_ge05 = "BLOCK_AND_ALERT" {
    _ge_no_source
} else = "BLOCK_AND_ALERT" {
    _ge_violations > _ge_max
} else = "SUGGEST" {
    true
}

reason_ge05 = sprintf("Brak źródła terminów (SLOWNIK_REFERENCJI_PRAWNYCH) — BLOCK (definicje lokalne duplikują się; AP12).", []) {
    _ge_no_source
} else = sprintf("Naruszenia glosariusza: %v > %v — BLOCK (termin użyty inaczej niż zdefiniowany; konsekwencja językowa).", [_ge_violations, _ge_max]) {
    _ge_violations > _ge_max
} else = sprintf("Glossary enforcement OK: %v naruszeń ≤ %v.", [_ge_violations, _ge_max]) {
    true
}

glossary_enforcement_decision := _certificate(441005, {
    "rule_id": "jdg.v3_p41_dokumentacja.glossary_enforcement",
    "analysis": "glossary_enforcement",
    "glossary_violations": _ge_violations,
    "glossary_source_missing": _ge_no_source,
    "glossary_violations_max": _ge_max,
    "_routing": routing_ge05,
    "_routing_reason": reason_ge05,
    "_legal_basis": "V3_P41 §10/I05; kontrakt P00 (glosariusz minimalny), P34 (lint)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "glossary_enforcement"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I06: AUDIT EXPORT PACK — pakiet dla kontroli (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_ae := object.get(_ctx, "audit_export_pack", {})
_ae_no_checksum := object.get(_ae, "exports_without_checksum", 0)
_ae_missing := _has_flag("audit_export_missing")

routing_ae06 = "BLOCK_AND_ALERT" {
    _ae_no_checksum > 0
} else = "TRIAGE_QUEUE" {
    _ae_missing
} else = "SUGGEST" {
    true
}

reason_ae06 = sprintf("Eksporty audytowe bez checksumy: %v — BLOCK (pakiet podważalny; UoR art. 4, Ordynacja art. 193a [NIEZWERYFIKOWANE]).", [_ae_no_checksum]) {
    _ae_no_checksum > 0
} else = sprintf("Brak mechanizmu eksportu audytowego — TRIAGE (dokumenty + rejestry + checksumy + pieczęć jednym poleceniem; P43/P44).", []) {
    _ae_missing
} else = sprintf("Audit export pack OK: pakiet gotowy w minuty z checksumami.", []) {
    true
}

audit_export_pack_decision := _certificate(441006, {
    "rule_id": "jdg.v3_p41_dokumentacja.audit_export_pack",
    "analysis": "audit_export_pack",
    "exports_without_checksum": _ae_no_checksum,
    "audit_export_missing": _ae_missing,
    "_routing": routing_ae06,
    "_routing_reason": reason_ae06,
    "_legal_basis": "V3_P41 §10/I06; UoR art. 4; Ordynacja art. 193a; eIDAS (pieczęć) [NIEZWERYFIKOWANE]; kontrakt P43 (WORM), P44 (certyfikacja)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "audit_export_pack"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I07: RUNBOOK COVERAGE — każdy alarm ma runbook (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_rc := object.get(_ctx, "runbook_coverage", {})
_rc_uncovered := object.get(_rc, "alerts_without_runbook", 0)
_rc_min := _th("v3_p41_runbook_coverage_min_pct", 100)

routing_rc07 = "BLOCK_AND_ALERT" {
    _rc_uncovered > 0
} else = "SUGGEST" {
    true
}

reason_rc07 = sprintf("Alerty bez runbooka: %v — BLOCK (każdy alarm P37 musi mieć procedurę; dokumentacja ↔ obserwowalność spięte kontraktem).", [_rc_uncovered]) {
    _rc_uncovered > 0
} else = sprintf("Runbook coverage OK: 100%% alertów P37 pokrytych (próg %v%%).", [_rc_min]) {
    true
}

runbook_coverage_decision := _certificate(441007, {
    "rule_id": "jdg.v3_p41_dokumentacja.runbook_coverage",
    "analysis": "runbook_coverage",
    "alerts_without_runbook": _rc_uncovered,
    "runbook_coverage_min_pct": _rc_min,
    "_routing": routing_rc07,
    "_routing_reason": reason_rc07,
    "_legal_basis": "V3_P41 §10/I07; kontrakt P37 (katalog SLO/alamów), P38 (rollback)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "runbook_coverage"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I08: CHANGELOG AUTOMATION — generowany z rejestrów (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_ca := object.get(_ctx, "changelog_automation", {})
_ca_manual := _has_flag("changelog_manual")
_ca_age := object.get(_ca, "changelog_age_days", 0)
_ca_max := _th("v3_p41_changelog_max_age_days", 14)

routing_ca08 = "TRIAGE_QUEUE" {
    _ca_manual
} else = "TRIAGE_QUEUE" {
    _ca_age > _ca_max
} else = "SUGGEST" {
    true
}

reason_ca08 = sprintf("Changelog ręczny — TRIAGE (generowany z rejestru wdrożeń P30 i ledger V3; ręczny = dryf).", []) {
    _ca_manual
} else = sprintf("Changelog nieświeży: %v dni > %v — TRIAGE (automatyczne odświeżanie z rejestrów).", [_ca_age, _ca_max]) {
    _ca_age > _ca_max
} else = sprintf("Changelog automation OK: generowany z rejestrów (wiek %v dni ≤ %v).", [_ca_age, _ca_max]) {
    true
}

changelog_automation_decision := _certificate(441008, {
    "rule_id": "jdg.v3_p41_dokumentacja.changelog_automation",
    "analysis": "changelog_automation",
    "changelog_manual": _ca_manual,
    "changelog_age_days": _ca_age,
    "changelog_max_age_days": _ca_max,
    "_routing": routing_ca08,
    "_routing_reason": reason_ca08,
    "_legal_basis": "V3_P41 §10/I08; kontrakt P30 (rejestr wdrożeń), P36 (generatory)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "changelog_automation"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I09: DOC FRESHNESS STAMPS — wiek dokumentów (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_fs := object.get(_ctx, "freshness_stamps", {})
_fs_missing := object.get(_fs, "docs_without_stamp", 0)
_fs_stale := object.get(_fs, "docs_stale", 0)
_fs_max := _th("v3_p41_doc_freshness_max_days", 90)

routing_fs09 = "TRIAGE_QUEUE" {
    _fs_stale > 0
} else = "TRIAGE_QUEUE" {
    _fs_missing > 0
} else = "SUGGEST" {
    true
}

reason_fs09 = sprintf("Dokumenty przeterminowane (> %v dni): %v — TRIAGE (odświeżenie po walidacji P34; przejrzystość wieku informacji).", [_fs_max, _fs_stale]) {
    _fs_stale > 0
} else = sprintf("Dokumenty bez stempla świeżości: %v — TRIAGE (każdy dokument ma pole ostatnia-weryfikacja).", [_fs_missing]) {
    _fs_missing > 0
} else = sprintf("Freshness stamps OK: wszystkie dokumenty ze stemplem ≤ %v dni.", [_fs_max]) {
    true
}

freshness_stamps_decision := _certificate(441009, {
    "rule_id": "jdg.v3_p41_dokumentacja.freshness_stamps",
    "analysis": "freshness_stamps",
    "docs_without_stamp": _fs_missing,
    "docs_stale": _fs_stale,
    "doc_freshness_max_days": _fs_max,
    "_routing": routing_fs09,
    "_routing_reason": reason_fs09,
    "_legal_basis": "V3_P41 §10/I09; kontrakt P34 (walidacja), P37 (SLA świeżości)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "freshness_stamps"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I10: DOCUMENTATION TESTING — example-as-test (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_dt := object.get(_ctx, "doc_testing", {})
_dt_broken := object.get(_dt, "broken_examples", 0)
_dt_no_mechanism := _has_flag("example_testing_missing")

routing_dt10 = "BLOCK_AND_ALERT" {
    _dt_broken > 0
} else = "TRIAGE_QUEUE" {
    _dt_no_mechanism
} else = "SUGGEST" {
    true
}

reason_dt10 = sprintf("Zepsute przykłady w dokumentacji: %v — BLOCK (curl/rego z docs muszą działać; example-as-test w CI).", [_dt_broken]) {
    _dt_broken > 0
} else = sprintf("Brak mechanizmu testowania przykładów — TRIAGE (przykłady w CI; zero zepsutych snippetów).", []) {
    _dt_no_mechanism
} else = sprintf("Documentation testing OK: przykłady testowane w CI.", []) {
    true
}

doc_testing_decision := _certificate(441010, {
    "rule_id": "jdg.v3_p41_dokumentacja.doc_testing",
    "analysis": "doc_testing",
    "broken_examples": _dt_broken,
    "example_testing_missing": _dt_no_mechanism,
    "_routing": routing_dt10,
    "_routing_reason": reason_dt10,
    "_legal_basis": "V3_P41 §10/I10; kontrakt P29 (jakość), P39 (piramida testów)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "doc_testing"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I11: AUDITOR MODE — ścieżki dowodowe (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_am := object.get(_ctx, "auditor_mode", {})
_am_missing := object.get(_am, "domains_without_evidence_path", 0)
_am_missing_view := _has_flag("auditor_view_missing")

routing_am11 = "TRIAGE_QUEUE" {
    _am_missing_view
} else = "TRIAGE_QUEUE" {
    _am_missing > 0
} else = "SUGGEST" {
    true
}

reason_am11 = sprintf("Brak widoku audytora — TRIAGE (pełne ścieżki dowodowe: jak sprawdzić każdą deklarację).", []) {
    _am_missing_view
} else = sprintf("Domeny bez ścieżki dowodowej: %v — TRIAGE (audyt szybszy; P44 certyfikacja).", [_am_missing]) {
    _am_missing > 0
} else = sprintf("Auditor mode OK: ścieżki dowodowe kompletne.", []) {
    true
}

auditor_mode_decision := _certificate(441011, {
    "rule_id": "jdg.v3_p41_dokumentacja.auditor_mode",
    "analysis": "auditor_mode",
    "domains_without_evidence_path": _am_missing,
    "auditor_view_missing": _am_missing_view,
    "_routing": routing_am11,
    "_routing_reason": reason_am11,
    "_legal_basis": "V3_P41 §10/I11; RODO art. 24 (rozliczalność) [NIEZWERYFIKOWANE]; kontrakt P44",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "auditor_mode"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P41-I12: LEGACY DOC RETIREMENT — statusy lifecycle (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_lr := object.get(_ctx, "legacy_retirement", {})
_lr_no_status := object.get(_lr, "docs_without_status", 0)
_lr_cannibals := object.get(_lr, "duplicate_current_docs", 0)

routing_lr12 = "BLOCK_AND_ALERT" {
    _lr_cannibals > 0
} else = "TRIAGE_QUEUE" {
    _lr_no_status > 0
} else = "SUGGEST" {
    true
}

reason_lr12 = sprintf("Dokumenty bez statusu lifecycle (CURRENT/ARCHIVED/SUPERSEDED): %v — TRIAGE (front-matter obowiązkowy).", [_lr_no_status]) {
    _lr_no_status > 0
} else = sprintf("Kanibalizm wersji (dwa CURRENT dla tej samej roli): %v — BLOCK (zero niejednoznaczności źródła prawdy).", [_lr_cannibals]) {
    _lr_cannibals > 0
} else = sprintf("Legacy retirement OK: statusy kompletne, brak kanibalizmu.", []) {
    true
}

legacy_retirement_decision := _certificate(441012, {
    "rule_id": "jdg.v3_p41_dokumentacja.legacy_retirement",
    "analysis": "legacy_retirement",
    "docs_without_status": _lr_no_status,
    "duplicate_current_docs": _lr_cannibals,
    "_routing": routing_lr12,
    "_routing_reason": reason_lr12,
    "_legal_basis": "V3_P41 §10/I12; kontrakt P00 (kanon), P36 (generatory)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "legacy_retirement"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := doc_code_binding_decision {
    doc_code_binding_decision.rule_id != ""
} else := ssot_numbers_decision {
    ssot_numbers_decision.rule_id != ""
} else := role_doc_maps_decision {
    role_doc_maps_decision.rule_id != ""
} else := semantic_diff_pl_en_decision {
    semantic_diff_pl_en_decision.rule_id != ""
} else := glossary_enforcement_decision {
    glossary_enforcement_decision.rule_id != ""
} else := audit_export_pack_decision {
    audit_export_pack_decision.rule_id != ""
} else := runbook_coverage_decision {
    runbook_coverage_decision.rule_id != ""
} else := changelog_automation_decision {
    changelog_automation_decision.rule_id != ""
} else := freshness_stamps_decision {
    freshness_stamps_decision.rule_id != ""
} else := doc_testing_decision {
    doc_testing_decision.rule_id != ""
} else := auditor_mode_decision {
    auditor_mode_decision.rule_id != ""
} else := legacy_retirement_decision {
    legacy_retirement_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p41_dokumentacja.no_match",
    "package": "jdg.v3_p41_dokumentacja",
    "priority": 999999,
}
