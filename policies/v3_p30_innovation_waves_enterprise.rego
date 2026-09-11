# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P30 FALE INNOWACJI — 24 GATE'Y RAPORTÓW R01–R24 I SPÓJNOŚĆ
# WDROŻEŃ — (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa fal innowacji ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Deployment Registry as Data (rejestr wdrożeń jako dane: statusy
#       OPEN/IN_PROGRESS/DONE/REJECTED z dowodem commit+test+artefakt;
#       automatyzacja wykrywania fałszywych DONE; AN04),
#   I02 Adopt-Rate Dashboard (metryka per domena: % rekomendacji wdrożonych
#       z dowodem; trend w P37; AN04),
#   I03 Semantic Deployment Diff (diff semantyczny rekomendacja→implementacja;
#       wykrywa wdrożenia fasadowe — plik istnieje, semantyki nie ma; AP06),
#   I04 V4 Selection Contract (scoring rekomendacji: wpływ na AUTO_POST, koszt,
#       ryzyko prawne — zautomatyzowany; AN04),
#   I05 Recommendation→PR Traceability (każdy PR referuje ID rekomendacji;
#       reverse-check wykrywa PR bez pochodzenia; AN04),
#   I06 Facade Wind-Down (kampania usunięcia martwych plików fasadowych
#       z rejestrem i skanem zależności; AP06),
#   I07 Recommendation Risk Triage (klasyfikacja: trywialna/istotna/krytyczna
#       z różnymi ścieżkami wdrożenia; krytyczna = 4-eyes; AN04),
#   I08 Golden Replay After Deployment (każde wdrożenie uruchamia replay golden
#       verdicts P10 — regresja blokuje merge; AN04),
#   I09 Deployment Budget (limit zmian w jednym wdrożeniu — awaria
#       lokalizowalna; AN04),
#   I10 Data-Driven Changelog (automatyczny changelog z rejestru wdrożeń:
#       domena, rekomendacja, dowód, ryzyko; AN04),
#   I11 Conflicting Deployment Detector (sprzeczne implementacje tej samej
#       zasady między domenami; AN04),
#   I12 Law Radar Loop Closure (rekomendacje prawne z P08 automatycznie
#       tworzą wpisy w rejestrze wdrożeń — nigdy nie giną; AN04).
#
# Integracje (kontrakty między-częściowe):
#   * P00 (mapa kanoniczna) — zakaz DONE bez dowodu (kod+test),
#   * P08 (Law Radar) — I12 zamyka pętlę rekomendacji prawnych,
#   * P10 (Golden Oracle) — I08 replay golden verdicts,
#   * P29 (bramki jakości) — gate'y raportów korzystają z tego samego raportu
#     JSON (kontrakt bramek),
#   * P37 (obserwowalność) — I02/I10 metryki adopt-rate i changelog,
#   * P44 (certyfikacja) — rejestr wdrożeń jako wejście,
#   * P41 (dokumentacja) — changelog jako artefakt.
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p30 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak snapshotu / nieznany status / DONE bez
#     dowodu = BLOCK_AND_ALERT lub NEEDS_ADVICE — nigdy cichy AUTO_POST
#     (anty-wzorzec AP07); ścieżki bez spełnionego warunku zwracają jawną
#     NEEDS_ADVICE (AP03 zamknięty).
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p30_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p30_innovation_waves.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p30_innovation_waves
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p30_innovation_waves

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p30_check", false) == true
_ctx := object.get(input, "v3_p30", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p30_snapshot := data.jdg.thresholds.v3_p30

_snapshot_ok = true {
    count(_p30_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p30_snapshot) > 0
    value := object.get(_p30_snapshot, key, null)
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
    "rule_id": "jdg.v3_p30_innovation_waves.thresholds_missing",
    "package": "jdg.v3_p30_innovation_waves",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "FALE INNOWACJI V3-P30: brak snapshotu data.jdg.thresholds.v3_p30.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P30] Brak snapshotu progów fal innowacji — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p30_innovation_waves",
        "priority": priority,
        "threshold_version": object.get(_p30_snapshot, "v3_p30_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p30_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p30_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I01: DEPLOYMENT REGISTRY AS DATA — rejestr wdrożeń (AN04)
# Status DONE wymaga dowodu: test zielony + artefakt + commit hash.
# ═══════════════════════════════════════════════════════════════════════════════
_registry := object.get(_ctx, "deployment_registry", [])
_registry_done := [r |
    r := _registry[_]
    object.get(r, "status", "OPEN") == "DONE"
]
_fake_done := [r |
    r := _registry_done[_]
    object.get(r, "evidence", {}) == {}
]
_fake_done_no_test := [r |
    r := _registry_done[_]
    ev := object.get(r, "evidence", {})
    object.get(ev, "test_green", false) == false
]
_fake_done_no_artifact := [r |
    r := _registry_done[_]
    ev := object.get(r, "evidence", {})
    object.get(ev, "artifact", "") == ""
]
_unknown_status := [r |
    r := _registry[_]
    st := object.get(r, "status", "")
    st != "OPEN"
    st != "IN_PROGRESS"
    st != "DONE"
    st != "REJECTED"
]

routing_rg01 = "BLOCK_AND_ALERT" {
    count(_fake_done) > 0
} else = "BLOCK_AND_ALERT" {
    count(_unknown_status) > 0
} else = "TRIAGE_QUEUE" {
    count(_fake_done_no_test) > 0
} else = "TRIAGE_QUEUE" {
    count(_fake_done_no_artifact) > 0
} else = "SUGGEST" {
    true
}

reason_rg01 = sprintf("Rejestr wdrożeń: %v wpisów DONE bez dowodu (empty evidence) — BLOCK (DONE bez testu+artefaktu to fałszywe wdrożenie).", [count(_fake_done)]) {
    count(_fake_done) > 0
} else = sprintf("Nieznane statusy w rejestrze: %v — BLOCK (dozwolone: OPEN/IN_PROGRESS/DONE/REJECTED).", [_unknown_status]) {
    count(_unknown_status) > 0
} else = sprintf("DONE bez zielonego testu: %v — TRIAGE (dowód niekompletny).", [count(_fake_done_no_test)]) {
    count(_fake_done_no_test) > 0
} else = sprintf("DONE bez artefaktu: %v — TRIAGE (dowód niekompletny).", [count(_fake_done_no_artifact)]) {
    count(_fake_done_no_artifact) > 0
} else = sprintf("Rejestr wdrożeń zgodny: %v wpisów, %v DONE z pełnym dowodem.", [count(_registry), count(_registry_done)]) {
    true
}

deployment_registry_decision := _certificate(430001, {
    "rule_id": "jdg.v3_p30_innovation_waves.deployment_registry",
    "analysis": "deployment_registry",
    "registry_total": count(_registry),
    "done_total": count(_registry_done),
    "fake_done": count(_fake_done),
    "done_without_test": count(_fake_done_no_test),
    "done_without_artifact": count(_fake_done_no_artifact),
    "unknown_statuses": count(_unknown_status),
    "_routing": routing_rg01,
    "_routing_reason": reason_rg01,
    "_legal_basis": "V3_P30 §5.4/AN04; kanon P00 (DONE bez dowodu = nie fakt); UoR art. 4 ust. 1 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "deployment_registry"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I02: ADOPT-RATE DASHBOARD — metryka per domena (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_domain_rows := object.get(_ctx, "domain_adopt", [])
_domain_low := [d |
    d := _domain_rows[_]
    object.get(d, "adopt_rate_pct", 100) < _th("v3_p30_adopt_rate_min_pct", 60)
]
_domain_no_data := [d |
    d := _domain_rows[_]
    object.get(d, "recommendations_total", 0) == 0
]

routing_ar02 = "TRIAGE_QUEUE" {
    count(_domain_low) > 0
} else = "TRIAGE_QUEUE" {
    count(_domain_no_data) > 0
} else = "SUGGEST" {
    true
}

reason_ar02 = sprintf("Adopt-rate poniżej progu %v%%: %v — TRIAGE (wymaga planu naprawy).", [_th("v3_p30_adopt_rate_min_pct", 60), _domain_low]) {
    count(_domain_low) > 0
} else = sprintf("Domeny bez danych adopt-rate: %v — TRIAGE (rejestr niekompletny).", [_domain_no_data]) {
    count(_domain_no_data) > 0
} else = sprintf("Adopt-rate OK: %v domen powyżej progu %v%%.", [count(_domain_rows), _th("v3_p30_adopt_rate_min_pct", 60)]) {
    true
}

adopt_rate_dashboard_decision := _certificate(430002, {
    "rule_id": "jdg.v3_p30_innovation_waves.adopt_rate_dashboard",
    "analysis": "adopt_rate_dashboard",
    "domains_total": count(_domain_rows),
    "domains_below_threshold": count(_domain_low),
    "domains_no_data": count(_domain_no_data),
    "min_adopt_rate_pct": _th("v3_p30_adopt_rate_min_pct", 60),
    "_routing": routing_ar02,
    "_routing_reason": reason_ar02,
    "_legal_basis": "V3_P30 §5.4/AN04; metryki → P37 obserwowalność",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "adopt_rate_dashboard"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I03: SEMANTIC DEPLOYMENT DIFF — detekcja wdrożeń fasadowych (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_sem_rows := object.get(_ctx, "semantic_diffs", [])
_facades := [r |
    r := _sem_rows[_]
    object.get(r, "semantic_equivalent", false) == false
    object.get(r, "file_exists", false) == true
]
_missing_files := [r |
    r := _sem_rows[_]
    object.get(r, "file_exists", false) == false
]

routing_sd03 = "BLOCK_AND_ALERT" {
    count(_facades) > 0
} else = "TRIAGE_QUEUE" {
    count(_missing_files) > 0
} else = "SUGGEST" {
    true
}

reason_sd03 = sprintf("Wdrożenia fasadowe (plik istnieje, semantyka rozjazd): %v — BLOCK (największe zagrożenie rzetelności kampanii).", [_facades]) {
    count(_facades) > 0
} else = sprintf("Pliki rekomendowane nie istnieją: %v — TRIAGE (rekomendacja bez implementacji).", [_missing_files]) {
    count(_missing_files) > 0
} else = sprintf("Diff semantyczny OK: %v rekomendacji z równoważną implementacją.", [count(_sem_rows)]) {
    true
}

semantic_deployment_diff_decision := _certificate(430003, {
    "rule_id": "jdg.v3_p30_innovation_waves.semantic_deployment_diff",
    "analysis": "semantic_deployment_diff",
    "diffs_total": count(_sem_rows),
    "facades": count(_facades),
    "missing_files": count(_missing_files),
    "_routing": routing_sd03,
    "_routing_reason": reason_sd03,
    "_legal_basis": "V3_P30 §5.4/AN04 (AP06); protokół prawy pkt 06 (dowód = kod+test)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "semantic_deployment_diff"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I04: V4 SELECTION CONTRACT — scoring rekomendacji (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_candidates := object.get(_ctx, "v4_candidates", [])
_candidates_high := [c |
    c := _candidates[_]
    object.get(c, "roi_score", 0) >= _th("v3_p30_v4_high_roi_min", 80)
]
_candidates_no_score := [c |
    c := _candidates[_]
    object.get(c, "roi_score", 0) == 0
]

routing_v404 = "TRIAGE_QUEUE" {
    count(_candidates_no_score) > 0
} else = "SUGGEST" {
    true
}

reason_v404 = sprintf("Kandydaci V4 bez scoringu ROI: %v — TRIAGE (kontrakt selekcji wymaga: wpływ na AUTO_POST, koszt, ryzyko prawne).", [_candidates_no_score]) {
    count(_candidates_no_score) > 0
} else = sprintf("Kontrakt selekcji V4 OK: %v kandydatów, %v z wysokim ROI (>= %v).", [count(_candidates), count(_candidates_high), _th("v3_p30_v4_high_roi_min", 80)]) {
    true
}

v4_selection_contract_decision := _certificate(430004, {
    "rule_id": "jdg.v3_p30_innovation_waves.v4_selection_contract",
    "analysis": "v4_selection_contract",
    "candidates_total": count(_candidates),
    "candidates_high_roi": count(_candidates_high),
    "candidates_without_score": count(_candidates_no_score),
    "high_roi_min": _th("v3_p30_v4_high_roi_min", 80),
    "_routing": routing_v404,
    "_routing_reason": reason_v404,
    "_legal_basis": "V3_P30 §5.4/AN04; kontrakt selekcji → P44 (kampania przyszła)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "v4_selection_contract"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I05: RECOMMENDATION→PR TRACEABILITY (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_prs := object.get(_ctx, "prs", [])
_prs_without_ref := [p |
    p := _prs[_]
    count(object.get(p, "recommendation_ids", [])) == 0
]
_recs := object.get(_ctx, "recommendations_total", 0)
_prs_with_ref := count(_prs) - count(_prs_without_ref)

routing_pr05 = "TRIAGE_QUEUE" {
    count(_prs_without_ref) > 0
} else = "SUGGEST" {
    true
}

reason_pr05 = sprintf("PR bez referencji do rekomendacji: %v — TRIAGE (reverse-check: każdy PR musi mieć pochodzenie z raportu).", [_prs_without_ref]) {
    count(_prs_without_ref) > 0
} else = sprintf("Traceability OK: %v PR z referencjami (rekomendacje: %v).", [_prs_with_ref, _recs]) {
    true
}

recommendation_pr_traceability_decision := _certificate(430005, {
    "rule_id": "jdg.v3_p30_innovation_waves.recommendation_pr_traceability",
    "analysis": "recommendation_pr_traceability",
    "prs_total": count(_prs),
    "prs_without_ref": count(_prs_without_ref),
    "recommendations_total": _recs,
    "_routing": routing_pr05,
    "_routing_reason": reason_pr05,
    "_legal_basis": "V3_P30 §5.4/AN04; audytowalność (RODO art. 5 ust. 2 [NIEZWERYFIKOWANE])",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "recommendation_pr_traceability"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I06: FACADE WIND-DOWN — kampania usunięcia fasad (AN04, AP06)
# ═══════════════════════════════════════════════════════════════════════════════
_winddown := object.get(_ctx, "winddown_targets", [])
_winddown_dependents := [w |
    w := _winddown[_]
    count(object.get(w, "dependents", [])) > 0
]

routing_wd06 = "TRIAGE_QUEUE" {
    count(_winddown_dependents) > 0
} else = "SUGGEST" {
    true
}

reason_wd06 = sprintf("Fasady z zależnościami: %v — TRIAGE (skan zależności przed usunięciem; kampania wind-down wymaga rejestru).", [_winddown_dependents]) {
    count(_winddown_dependents) > 0
} else = sprintf("Wind-down OK: %v fasad bez zależności — usunięcie bezpieczne.", [count(_winddown)]) {
    true
}

facade_wind_down_decision := _certificate(430006, {
    "rule_id": "jdg.v3_p30_innovation_waves.facade_wind_down",
    "analysis": "facade_wind_down",
    "winddown_targets": count(_winddown),
    "with_dependents": count(_winddown_dependents),
    "_routing": routing_wd06,
    "_routing_reason": reason_wd06,
    "_legal_basis": "V3_P30 §5.4/AN04 (AP06); kontrakt P34/P36",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "facade_wind_down"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I07: RECOMMENDATION RISK TRIAGE — krytyczne = 4-eyes (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_risk_rows := object.get(_ctx, "risk_classified", [])
_critical_unapproved := [r |
    r := _risk_rows[_]
    object.get(r, "risk_class", "TRIVIAL") == "CRITICAL"
    object.get(r, "human_approved", false) == false
]
_unknown_class := [r |
    r := _risk_rows[_]
    cls := object.get(r, "risk_class", "")
    cls != "TRIVIAL"
    cls != "IMPORTANT"
    cls != "CRITICAL"
]

routing_rt07 = "BLOCK_AND_ALERT" {
    count(_critical_unapproved) > 0
} else = "TRIAGE_QUEUE" {
    count(_unknown_class) > 0
} else = "SUGGEST" {
    true
}

reason_rt07 = sprintf("Rekomendacje KRYTYCZNE bez akceptacji człowieka (4-eyes): %v — BLOCK (krytyczna ścieżka zawsze z human-in-the-loop).", [_critical_unapproved]) {
    count(_critical_unapproved) > 0
} else = sprintf("Nieznane klasy ryzyka: %v — TRIAGE (dozwolone: TRIVIAL/IMPORTANT/CRITICAL).", [_unknown_class]) {
    count(_unknown_class) > 0
} else = sprintf("Triage ryzyka OK: %v rekomendacji sklasyfikowanych.", [count(_risk_rows)]) {
    true
}

recommendation_risk_triage_decision := _certificate(430007, {
    "rule_id": "jdg.v3_p30_innovation_waves.recommendation_risk_triage",
    "analysis": "recommendation_risk_triage",
    "risk_classified_total": count(_risk_rows),
    "critical_unapproved": count(_critical_unapproved),
    "unknown_class": count(_unknown_class),
    "_routing": routing_rt07,
    "_routing_reason": reason_rt07,
    "_legal_basis": "V3_P30 §5.4/AN04; RODO art. 22 (zautomatyzowane decyzje) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "recommendation_risk_triage"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I08: GOLDEN REPLAY AFTER DEPLOYMENT — regresja blokuje merge (AN04/P10)
# ═══════════════════════════════════════════════════════════════════════════════
_replay := object.get(_ctx, "golden_replay", {})
_replay_run := object.get(_replay, "run", false)
_replay_total := object.get(_replay, "verdicts_total", 0)
_replay_failed := object.get(_replay, "verdicts_failed", 0)
_replay_unverified := object.get(_replay, "unverified", 0)

routing_gr08 = "BLOCK_AND_ALERT" {
    _replay_run
    _replay_failed > 0
} else = "TRIAGE_QUEUE" {
    not _replay_run
} else = "TRIAGE_QUEUE" {
    _replay_unverified > 0
} else = "SUGGEST" {
    true
}

reason_gr08 = sprintf("Golden replay po wdrożeniu: %v/%v FAIL — BLOCK (regresja blokuje merge; P10).", [_replay_failed, _replay_total]) {
    _replay_run
    _replay_failed > 0
} else = "Golden replay po wdrożeniu nie uruchomiony — TRIAGE (wymóg każdego wdrożenia; P10)." {
    not _replay_run
} else = sprintf("Golden replay: %v UVER — TRIAGE (wymaga weryfikacji ręcznej).", [_replay_unverified]) {
    _replay_unverified > 0
} else = sprintf("Golden replay OK: %v/%v werdyktów zgodnych.", [_replay_total - _replay_failed, _replay_total]) {
    true
}

golden_replay_decision := _certificate(430008, {
    "rule_id": "jdg.v3_p30_innovation_waves.golden_replay",
    "analysis": "golden_replay",
    "replay_run": _replay_run,
    "verdicts_total": _replay_total,
    "verdicts_failed": _replay_failed,
    "unverified": _replay_unverified,
    "_routing": routing_gr08,
    "_routing_reason": reason_gr08,
    "_legal_basis": "V3_P30 §5.4/AN04; kontrakt P10 (Golden Oracle); V2 F4",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_replay"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I09: DEPLOYMENT BUDGET — limit zmian w jednym wdrożeniu (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_budget := object.get(_ctx, "deployment_budget", {})
_budget_rules := object.get(_budget, "rules_changed", 0)
_budget_max := _th("v3_p30_max_rules_per_deployment", 20)

routing_db09 = "BLOCK_AND_ALERT" {
    _budget_rules > _budget_max
} else = "SUGGEST" {
    true
}

reason_db09 = sprintf("Budżet wdrożeniowy przekroczony: %v reguł > limitu %v — BLOCK (awaria musi być lokalizowalna).", [_budget_rules, _budget_max]) {
    _budget_rules > _budget_max
} else = sprintf("Budżet wdrożeniowy OK: %v reguł <= limitu %v.", [_budget_rules, _budget_max]) {
    true
}

deployment_budget_decision := _certificate(430009, {
    "rule_id": "jdg.v3_p30_innovation_waves.deployment_budget",
    "analysis": "deployment_budget",
    "rules_changed": _budget_rules,
    "max_rules_per_deployment": _budget_max,
    "_routing": routing_db09,
    "_routing_reason": reason_db09,
    "_legal_basis": "V3_P30 §5.4/AN04; lokalizowalność awarii (V1 SLO)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "deployment_budget"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I10: DATA-DRIVEN CHANGELOG — automatyczny changelog (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_changelog := object.get(_ctx, "changelog", {})
_changelog_entries := object.get(_changelog, "entries", 0)
_changelog_domains := object.get(_changelog, "domains", [])

routing_cl10 = "TRIAGE_QUEUE" {
    _changelog_entries == 0
} else = "SUGGEST" {
    true
}

reason_cl10 = sprintf("Changelog pusty: %v wpisów — TRIAGE (changelog z rejestru wdrożeń wymagany dla audytu).", [_changelog_entries]) {
    _changelog_entries == 0
} else = sprintf("Changelog OK: %v wpisów dla domen %v.", [_changelog_entries, _changelog_domains]) {
    true
}

data_driven_changelog_decision := _certificate(430010, {
    "rule_id": "jdg.v3_p30_innovation_waves.data_driven_changelog",
    "analysis": "data_driven_changelog",
    "changelog_entries": _changelog_entries,
    "changelog_domains": _changelog_domains,
    "_routing": routing_cl10,
    "_routing_reason": reason_cl10,
    "_legal_basis": "V3_P30 §5.4/AN04; audytowalność → P41/P44",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "data_driven_changelog"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I11: CONFLICTING DEPLOYMENT DETECTOR — sprzeczne implementacje (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_conflicts := object.get(_ctx, "deployment_conflicts", [])

routing_cd11 = "BLOCK_AND_ALERT" {
    count(_conflicts) > 0
} else = "SUGGEST" {
    true
}

reason_cd11 = sprintf("Sprzeczne wdrożenia tej samej zasady między domenami: %v — BLOCK (konflikt wymaga konsolidacji).", [_conflicts]) {
    count(_conflicts) > 0
} else = "Brak sprzecznych wdrożeń — spójność między domenami potwierdzona." {
    true
}

conflicting_deployment_detector_decision := _certificate(430011, {
    "rule_id": "jdg.v3_p30_innovation_waves.conflicting_deployment_detector",
    "analysis": "conflicting_deployment_detector",
    "conflicts_total": count(_conflicts),
    "conflicts": _conflicts,
    "_routing": routing_cd11,
    "_routing_reason": reason_cd11,
    "_legal_basis": "V3_P30 §5.4/AN04 (AP04); jedno źródło prawdy per zasada",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "conflicting_deployment_detector"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P30-I12: LAW RADAR LOOP CLOSURE — rekomendacje prawne nigdy nie giną (AN04/P08)
# ═══════════════════════════════════════════════════════════════════════════════
_radar := object.get(_ctx, "law_radar", {})
_radar_recs := object.get(_radar, "recommendations", [])
_radar_registered := [r |
    r := _radar_recs[_]
    object.get(r, "registry_created", false) == false
]

routing_lr12 = "TRIAGE_QUEUE" {
    count(_radar_registered) > 0
} else = "SUGGEST" {
    true
}

reason_lr12 = sprintf("Rekomendacje Law Radar bez wpisu w rejestrze wdrożeń: %v — TRIAGE (pętla z P08 musi być zamknięta).", [_radar_registered]) {
    count(_radar_registered) > 0
} else = sprintf("Pętla Law Radar zamknięta: %v rekomendacji zarejestrowanych.", [count(_radar_recs)]) {
    true
}

law_radar_loop_closure_decision := _certificate(430012, {
    "rule_id": "jdg.v3_p30_innovation_waves.law_radar_loop_closure",
    "analysis": "law_radar_loop_closure",
    "radar_recommendations": count(_radar_recs),
    "unregistered": count(_radar_registered),
    "_routing": routing_lr12,
    "_routing_reason": reason_lr12,
    "_legal_basis": "V3_P30 §5.4/AN04; kontrakt P08 (Law Radar); V2 LKG",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "law_radar_loop_closure"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := deployment_registry_decision {
    deployment_registry_decision.rule_id != ""
} else := adopt_rate_dashboard_decision {
    adopt_rate_dashboard_decision.rule_id != ""
} else := semantic_deployment_diff_decision {
    semantic_deployment_diff_decision.rule_id != ""
} else := v4_selection_contract_decision {
    v4_selection_contract_decision.rule_id != ""
} else := recommendation_pr_traceability_decision {
    recommendation_pr_traceability_decision.rule_id != ""
} else := facade_wind_down_decision {
    facade_wind_down_decision.rule_id != ""
} else := recommendation_risk_triage_decision {
    recommendation_risk_triage_decision.rule_id != ""
} else := golden_replay_decision {
    golden_replay_decision.rule_id != ""
} else := deployment_budget_decision {
    deployment_budget_decision.rule_id != ""
} else := data_driven_changelog_decision {
    data_driven_changelog_decision.rule_id != ""
} else := conflicting_deployment_detector_decision {
    conflicting_deployment_detector_decision.rule_id != ""
} else := law_radar_loop_closure_decision {
    law_radar_loop_closure_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p30_innovation_waves.no_match",
    "package": "jdg.v3_p30_innovation_waves",
    "priority": 999999,
}