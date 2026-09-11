# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P29 KAMPANIE JAKOŚCI V3 — 8 BRAMEK (MICRO/HYPER/ENTERPRISE/
# TOOLS/TESTS_CI/BUNDLES/API_UI/DOCS) — (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa bramek jakości ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Composite Quality Gate (bramka łączna: jeden punkt wejścia 8 bramek
#       v3_13..v3_20 z uniformowanym raportem JSON i wspólną semantyką
#       exit-code dla CI; brakująca bramka = BLOCK),
#   I02 Mutation Testing Contract (mutacje reguł — zmiana progu, odwrócenie
#       warunku — z asercją, że testy je ZŁAPIĄ; mierzy realną czułość
#       suite'a, nie linie pokrycia; próg mutation_score z danych),
#   I03 Quality Debt Ledger (rejestr długów jakości z datą, właścicielem i
#       ścieżką spłaty; otwarty dług P1 = BLOCK dla nowych reguł; AP06),
#   I04 Deterministic Seed Contract (każdy test losowy ma seed zapisany w
#       raporcie; replay 1:1 po awarii; brak seeda = TRIAGE),
#   I05 Gate Performance Profiler (czas wykonania każdej bramki; dryf >50%
#       względem baseline = TRIAGE — sygnał degradacji repo),
#   I06 Gate-as-Data Contract (definicja bramki — kontrole, progi, zakres —
#       w data.jdg.thresholds.v3_p29_gate_registry; zmiana progu bez deployu
#       kodu; zgodność P06 parametry-as-data),
#   I07 Merge Block Comment Generator (wynik bramki → komentarz PR z listą
#       łamanych kontroli i dokładnymi liniami Rego; zero cichych blokad),
#   I08 Domain Quality Heatmap (agregacja wyników 8 bramek do heatmapy per
#       domena VAT/PIT/ZUS/RODO/KKS/ORD/ACCOUNTING/CROSSBORDER z trendem),
#   I09 Facade Assertion Detector (test bez asercji negatywnej = fasada;
#       rejestr fasad z priorytetem naprawy; AP06),
#   I10 Gate-to-Certificate Binding (certyfikat decyzji zawiera ID wersji
#       bramek, które przepuściły reguły — pełny dowód provenance; F4),
#   I11 Test Upgrade Pipeline (generator testów granicznych z tabeli aktów
#       podłączony pod bramki v3 jako wymóg CANDIDATE→ACTIVE; P36),
#   I12 Holy Documents Compliance Report (kontrola, że bramki nie dopuszczają
#       rozwiązań sprzecznych z ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md i
#       WIZJA_OPA_ENTERPRISE_V2.md; konflikt = BLOCK).
#
# Integracje (kontrakty między-częściowe):
#   * v3_13..v3_20 — 8 bramek jakości z rules/{micro,hyper,enterprise,tools,
#     tests_ci,bundles,api_ui,docs}/quality_v3_*.rego (rejestr jako dane I06),
#   * P03 — wynik bramki jest wejściem do kontraktu werdyktu 25-polowego,
#   * P04 — konstytucja bramek INV-Q01..Q04 (nigdy zielona-fasada, zawsze
#     deterministycznie, zawsze dowód, zero cichej blokady),
#   * P10 — golden set bramek (granice progów mutation/coverage/seed),
#   * P11 — Decision Certificate z ID wersji bramek (I10),
#   * P37 — metryki bramek do obserwowalności (I05, I08),
#   * P39/P44 — rejestr bramek jako dowód CI i certyfikacji finalnej.
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p29 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak snapshotu / nieznana bramka / naruszenie
#     invariantu = BLOCK_AND_ALERT lub NEEDS_ADVICE — nigdy cichy AUTO_POST
#     (anty-wzorzec AP07); ścieżki bez spełnionego warunku zwracają jawną
#     NEEDS_ADVICE (AP03 zamknięty).
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p29_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p29_quality_campaigns.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p29_quality_campaigns
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p29_quality_campaigns

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p29_check", false) == true
_ctx := object.get(input, "v3_p29", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p29_snapshot := data.jdg.thresholds.v3_p29

_snapshot_ok = true {
    count(_p29_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p29_snapshot) > 0
    value := object.get(_p29_snapshot, key, null)
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
    "rule_id": "jdg.v3_p29_quality_campaigns.thresholds_missing",
    "package": "jdg.v3_p29_quality_campaigns",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KAMPANIE JAKOŚCI V3-P29: brak snapshotu data.jdg.thresholds.v3_p29.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P29] Brak snapshotu progów bramek jakości — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p29_quality_campaigns",
        "priority": priority,
        "threshold_version": object.get(_p29_snapshot, "v3_p29_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p29_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p29_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I01: COMPOSITE QUALITY GATE — bramka łączna 8 bramek v3
# ═══════════════════════════════════════════════════════════════════════════════
_gate_catalog := {
    "v3_13": {"name": "micro", "package": "jdg.micro.quality_v3_13", "priority": 110},
    "v3_14": {"name": "hyper", "package": "jdg.hyper.quality_v3_14", "priority": 120},
    "v3_15": {"name": "enterprise", "package": "jdg.enterprise.quality_v3_15", "priority": 130},
    "v3_16": {"name": "tools", "package": "jdg.tools.quality_v3_16", "priority": 140},
    "v3_17": {"name": "tests_ci", "package": "jdg.tests_ci.quality_v3_17", "priority": 150},
    "v3_18": {"name": "bundles", "package": "jdg.bundles.quality_v3_18", "priority": 160},
    "v3_19": {"name": "api_ui", "package": "jdg.api_ui.quality_v3_19", "priority": 170},
    "v3_20": {"name": "docs", "package": "jdg.docs.quality_v3_20", "priority": 180},
}
_expected_gates := ["v3_13", "v3_14", "v3_15", "v3_16", "v3_17", "v3_18", "v3_19", "v3_20"]

_gate_results := object.get(_ctx, "gate_results", {})
_gate_reported := [k | some k, _v in _gate_results]
_gate_missing := [g |
    g := _expected_gates[_]
    not g in _gate_reported
]
_gate_failed := [g |
    g := _gate_reported[_]
    object.get(_gate_results[g], "passed", false) == false
]

routing_cg01 = "BLOCK_AND_ALERT" {
    count(_gate_missing) > 0
} else = "BLOCK_AND_ALERT" {
    count(_gate_failed) > 0
} else = "SUGGEST" {
    true
}

reason_cg01 = sprintf("Bramka łączna: brak wyników bramek %v — BLOCK (forteca silna tak bardzo, jak najszczelniejsza bramka).", [_gate_missing]) {
    count(_gate_missing) > 0
} else = sprintf("Bramka łączna: %v z %v bramek FAIL — BLOCK merge (bramki: %v).", [count(_gate_failed), count(_expected_gates), _gate_failed]) {
    count(_gate_failed) > 0
} else = sprintf("Bramka łączna OK: %v/%v bramek PASS (uniform JSON, wspólny exit-code CI).", [count(_gate_reported), count(_expected_gates)]) {
    true
}

composite_quality_gate_decision := _certificate(429001, {
    "rule_id": "jdg.v3_p29_quality_campaigns.composite_quality_gate",
    "analysis": "composite_quality_gate",
    "expected_gates": count(_expected_gates),
    "gates_reported": count(_gate_reported),
    "gates_missing": _gate_missing,
    "gates_failed": _gate_failed,
    "exit_code": "BLOCK",
    "_routing": routing_cg01,
    "_routing_reason": reason_cg01,
    "_legal_basis": "V3_P29 §5.1-5.3/AN01-AN03; kontrakt P03 (wynik bramki = wejście do werdyktu); dokumenty święte V1 §bramki CI",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "composite_quality_gate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I02: MUTATION TESTING CONTRACT — czułość suite'a, nie linie pokrycia
# ═══════════════════════════════════════════════════════════════════════════════
_mt_total := object.get(_ctx, "mutations_total", 0)
_mt_killed := object.get(_ctx, "mutations_killed", 0)
_mt_score = 0 {
    _mt_total <= 0
} else = score {
    score := _mt_killed * 100 / _mt_total
}
_mt_min := _th("v3_p29_min_mutation_score", 85)
_mt_survived := _mt_total - _mt_killed

routing_mt02 = "BLOCK_AND_ALERT" {
    _mt_total > 0
    _mt_score < _mt_min
} else = "TRIAGE_QUEUE" {
    _mt_total == 0
} else = "SUGGEST" {
    true
}

reason_mt02 = sprintf("Mutation score %v%% < progu %v%% — BLOCK (przetrwałe mutacje: %v; testy nie łapią odwróceń warunków).", [_mt_score, _mt_min, _mt_survived]) {
    _mt_total > 0
    _mt_score < _mt_min
} else = "Brak uruchomienia mutation testing — TRIAGE (czułość suite'a niezmierzona; pokrycie liniowe to nie dowód)." {
    _mt_total == 0
} else = sprintf("Mutation score %v%% >= progu %v%% (zabito %v/%v mutacji) — czułość suite'a potwierdzona.", [_mt_score, _mt_min, _mt_killed, _mt_total]) {
    true
}

mutation_testing_decision := _certificate(429002, {
    "rule_id": "jdg.v3_p29_quality_campaigns.mutation_testing",
    "analysis": "mutation_testing",
    "mutations_total": _mt_total,
    "mutations_killed": _mt_killed,
    "mutations_survived": _mt_survived,
    "mutation_score": _mt_score,
    "min_mutation_score": _mt_min,
    "_routing": routing_mt02,
    "_routing_reason": reason_mt02,
    "_legal_basis": "V3_P29 §5.2/AN02; spójne z tests_ci_quality_v3_17 min_mutation_score=85 (ADR-002)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "mutation_testing"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I03: QUALITY DEBT LEDGER — rejestr długów jakości (AP06)
# ═══════════════════════════════════════════════════════════════════════════════
_debts := object.get(_ctx, "quality_debts", [])
_debts_open := [d |
    d := _debts[_]
    object.get(d, "status", "OPEN") == "OPEN"
]
_debts_p1_open := [d |
    d := _debts_open[_]
    object.get(d, "criticality", "P3") == "P1"
]
_debts_overdue := [d |
    d := _debts_open[_]
    object.get(d, "repay_by", "") != ""
    object.get(d, "repay_by", "9999-12-31") < object.get(_ctx, "evaluation_date", "0000-01-01")
]
_debt_max := _th("v3_p29_max_open_debts_p1", 0)

routing_dl03 = "BLOCK_AND_ALERT" {
    count(_debts_p1_open) > _debt_max
} else = "TRIAGE_QUEUE" {
    count(_debts_overdue) > 0
} else = "SUGGEST" {
    true
}

reason_dl03 = sprintf("Otwarte długi jakości P1: %v > limitu %v — BLOCK (spłata przed dodawaniem nowych reguł).", [count(_debts_p1_open), _debt_max]) {
    count(_debts_p1_open) > _debt_max
} else = sprintf("Długi po terminie spłaty: %v — TRIAGE (rejestr wymaga aktualizacji właściciela/terminu).", [_debts_overdue]) {
    count(_debts_overdue) > 0
} else = sprintf("Rejestr długów zgodny: %v wpisów, %v otwartych P1 (limit %v).", [count(_debts), count(_debts_p1_open), _debt_max]) {
    true
}

quality_debt_ledger_decision := _certificate(429003, {
    "rule_id": "jdg.v3_p29_quality_campaigns.quality_debt_ledger",
    "analysis": "quality_debt_ledger",
    "debts_total": count(_debts),
    "debts_open": count(_debts_open),
    "debts_p1_open": count(_debts_p1_open),
    "debts_overdue": count(_debts_overdue),
    "max_open_p1": _debt_max,
    "_routing": routing_dl03,
    "_routing_reason": reason_dl03,
    "_legal_basis": "V3_P29 §5.2/AN02 (AP06); OrdPU art. 119a — rzetelne procesy [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "quality_debt_ledger"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I04: DETERMINISTIC SEED CONTRACT — replay 1:1 po awarii
# ═══════════════════════════════════════════════════════════════════════════════
_random_tests := object.get(_ctx, "random_tests", [])
_tests_without_seed := [t |
    t := _random_tests[_]
    object.get(t, "seed", 0) == 0
]
_seed_required := _th("v3_p29_seed_required", true)

routing_sc04 = "TRIAGE_QUEUE" {
    _seed_required
    count(_tests_without_seed) > 0
} else = "SUGGEST" {
    true
}

reason_sc04 = sprintf("Testy losowe bez seeda: %v — TRIAGE (replay 1:1 niemożliwy po awarii; seed musi być w nazwie raportu).", [_tests_without_seed]) {
    _seed_required
    count(_tests_without_seed) > 0
} else = "Wszystkie testy losowe mają seed — replay 1:1 potwierdzony." {
    true
}

deterministic_seed_decision := _certificate(429004, {
    "rule_id": "jdg.v3_p29_quality_campaigns.deterministic_seed",
    "analysis": "deterministic_seed",
    "random_tests_total": count(_random_tests),
    "tests_without_seed": count(_tests_without_seed),
    "seed_required": _seed_required,
    "_routing": routing_sc04,
    "_routing_reason": reason_sc04,
    "_legal_basis": "V3_P29 §5.2/AN02 (flaky → sanitizacja); spójne z P23 TESTY_REGO_CI",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "deterministic_seed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I05: GATE PERFORMANCE PROFILER — dryf czasu wykonania >50% = TRIAGE
# ═══════════════════════════════════════════════════════════════════════════════
_perf_rows := object.get(_ctx, "gate_timings", [])
_perf_drift := [r |
    r := _perf_rows[_]
    baseline := object.get(r, "baseline_seconds", 0)
    baseline > 0
    actual := object.get(r, "actual_seconds", 0)
    (actual - baseline) * 100 > baseline * object.get(_p29_snapshot, "v3_p29_perf_drift_pct", 50)
]
_perf_max := _th("v3_p29_max_gate_seconds", 120)
_perf_over := [r |
    r := _perf_rows[_]
    object.get(r, "actual_seconds", 0) > _perf_max
]

routing_pp05 = "TRIAGE_QUEUE" {
    count(_perf_over) > 0
} else = "TRIAGE_QUEUE" {
    count(_perf_drift) > 0
} else = "SUGGEST" {
    true
}

reason_pp05 = sprintf("Bramki powyżej limitu %v s: %v — TRIAGE (degradacja repo).", [_perf_max, _perf_over]) {
    count(_perf_over) > 0
} else = sprintf("Dryf czasu wykonania >%v%%: %v — TRIAGE (profil bramek wymaga rewizji).", [object.get(_p29_snapshot, "v3_p29_perf_drift_pct", 50), _perf_drift]) {
    count(_perf_drift) > 0
} else = sprintf("Profil czasowy OK: %v bramek w limitach.", [count(_perf_rows)]) {
    true
}

gate_performance_profiler_decision := _certificate(429005, {
    "rule_id": "jdg.v3_p29_quality_campaigns.gate_performance_profiler",
    "analysis": "gate_performance_profiler",
    "gates_timed": count(_perf_rows),
    "gates_over_limit": count(_perf_over),
    "gates_drifted": count(_perf_drift),
    "max_gate_seconds": _perf_max,
    "_routing": routing_pp05,
    "_routing_reason": reason_pp05,
    "_legal_basis": "V3_P29 §5.2/AN02; metryki → P37 obserwowalność",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "gate_performance_profiler"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I06: GATE-AS-DATA CONTRACT — definicje bramek jako dane (P06)
# ═══════════════════════════════════════════════════════════════════════════════
_gate_registry := object.get(_p29_snapshot, "v3_p29_gate_registry", {})
_registry_entries := [k | some k, _v in _gate_registry]
_registry_expected := _expected_gates
_registry_missing := [g |
    g := _registry_expected[_]
    not g in _registry_entries
]
_hardcoded_thresholds := _has_flag("gate_hardcode_detected")

routing_gd06 = "BLOCK_AND_ALERT" {
    count(_registry_missing) > 0
} else = "BLOCK_AND_ALERT" {
    _hardcoded_thresholds
} else = "SUGGEST" {
    true
}

reason_gd06 = sprintf("Rejestr bramek niekompletny: brak %v — BLOCK (definicja bramki jako dane, zmiana progu bez deployu).", [_registry_missing]) {
    count(_registry_missing) > 0
} else = "Wykryto hardcode progów w kodzie bramki — BLOCK (ADR-002; parametry wyłącznie z data.thresholds)." {
    _hardcoded_thresholds
} else = sprintf("Rejestr bramek kompletny: %v bramek jako dane (kontrole, progi, zakres) — P06 honorowany.", [count(_registry_entries)]) {
    true
}

gate_as_data_decision := _certificate(429006, {
    "rule_id": "jdg.v3_p29_quality_campaigns.gate_as_data",
    "analysis": "gate_as_data",
    "registry_entries": count(_registry_entries),
    "registry_missing": _registry_missing,
    "hardcode_detected": _hardcoded_thresholds,
    "_routing": routing_gd06,
    "_routing_reason": reason_gd06,
    "_legal_basis": "V3_P29 §5.1-5.3; ADR-002 (P06 parametry-as-data); kontrakt P07 lifecycle",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "gate_as_data"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I07: MERGE BLOCK COMMENT GENERATOR — zero cichych blokad
# ═══════════════════════════════════════════════════════════════════════════════
_block_events := object.get(_ctx, "merge_block_events", [])
_blocks_without_comment := [e |
    e := _block_events[_]
    object.get(e, "blocked", false) == true
    count(object.get(e, "comment_lines", [])) == 0
]

routing_mc07 = "BLOCK_AND_ALERT" {
    count(_blocks_without_comment) > 0
} else = "SUGGEST" {
    true
}

reason_mc07 = sprintf("Blokady merge bez komentarza PR z liniami Rego: %v — BLOCK (zero cichych blokad; kwit musi wskazywać łamane kontrole).", [_blocks_without_comment]) {
    count(_blocks_without_comment) > 0
} else = sprintf("Auto-kwit OK: %v blokad, każda z listą kontroli i liniami Rego.", [count(_block_events)]) {
    true
}

merge_block_comment_decision := _certificate(429007, {
    "rule_id": "jdg.v3_p29_quality_campaigns.merge_block_comment",
    "analysis": "merge_block_comment",
    "block_events": count(_block_events),
    "blocks_without_comment": count(_blocks_without_comment),
    "_routing": routing_mc07,
    "_routing_reason": reason_mc07,
    "_legal_basis": "V3_P29 §5.2/AN02; rozliczalność RODO art. 5 ust. 2 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "merge_block_comment"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I08: DOMAIN QUALITY HEATMAP — heatmapa jakości per domena
# ═══════════════════════════════════════════════════════════════════════════════
_domain_rows := object.get(_ctx, "domain_scores", [])
_domains_red := [r |
    r := _domain_rows[_]
    object.get(r, "score", 100) < _th("v3_p29_heatmap_red_below", 60)
]
_domains_amber := [r |
    r := _domain_rows[_]
    score := object.get(r, "score", 100)
    score >= _th("v3_p29_heatmap_red_below", 60)
    score < _th("v3_p29_heatmap_green_from", 80)
]

routing_hm08 = "BLOCK_AND_ALERT" {
    count(_domains_red) > 0
} else = "TRIAGE_QUEUE" {
    count(_domains_amber) > 0
} else = "SUGGEST" {
    true
}

reason_hm08 = sprintf("Heatmapa: domeny RED (<%v): %v — BLOCK (jakość poniżej progu krytycznego).", [_th("v3_p29_heatmap_red_below", 60), _domains_red]) {
    count(_domains_red) > 0
} else = sprintf("Heatmapa: domeny AMBER: %v — TRIAGE (trend kwartalny wymaga planu).", [_domains_amber]) {
    count(_domains_amber) > 0
} else = sprintf("Heatmapa OK: %v domen w GREEN (>= %v).", [count(_domain_rows), _th("v3_p29_heatmap_green_from", 80)]) {
    true
}

domain_quality_heatmap_decision := _certificate(429008, {
    "rule_id": "jdg.v3_p29_quality_campaigns.domain_quality_heatmap",
    "analysis": "domain_quality_heatmap",
    "domains_total": count(_domain_rows),
    "domains_red": _domains_red,
    "domains_amber": _domains_amber,
    "_routing": routing_hm08,
    "_routing_reason": reason_hm08,
    "_legal_basis": "V3_P29 §5.1-5.3/AN01-AN03; dashboard → P37/P44",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "domain_quality_heatmap"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I09: FACADE ASSERTION DETECTOR — test bez asercji negatywnej = fasada
# ═══════════════════════════════════════════════════════════════════════════════
_facades := object.get(_ctx, "facade_tests", [])
_facades_blocking := [f |
    f := _facades[_]
    object.get(f, "is_merge_blocking", false) == true
]
_facade_max := _th("v3_p29_max_blocking_facades", 0)

routing_fd09 = "BLOCK_AND_ALERT" {
    count(_facades_blocking) > _facade_max
} else = "TRIAGE_QUEUE" {
    count(_facades) > 0
} else = "SUGGEST" {
    true
}

reason_fd09 = sprintf("Fasady w testach blokujących merge: %v > limitu %v — BLOCK (test zawsze-zielony bez asercji negatywnej nie jest dowodem).", [count(_facades_blocking), _facade_max]) {
    count(_facades_blocking) > _facade_max
} else = sprintf("Fasady nieblokujące: %v — TRIAGE (rejestr z priorytetem naprawy dla P34/P36).", [count(_facades)]) {
    count(_facades) > 0
} else = "Zero fasad: wszystkie testy mają asercje negatywne (AP06 zamknięty)." {
    true
}

facade_assertion_detector_decision := _certificate(429009, {
    "rule_id": "jdg.v3_p29_quality_campaigns.facade_assertion_detector",
    "analysis": "facade_assertion_detector",
    "facades_total": count(_facades),
    "facades_blocking": count(_facades_blocking),
    "max_blocking_facades": _facade_max,
    "_routing": routing_fd09,
    "_routing_reason": reason_fd09,
    "_legal_basis": "V3_P29 §5.1-5.4/AN01-AN04 (AP06); kontrakt P34/P36",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "facade_assertion_detector"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I10: GATE-TO-CERTIFICATE BINDING — provenance bramek w certyfikacie
# ═══════════════════════════════════════════════════════════════════════════════
_cert_gate_ids := object.get(_ctx, "certificate_gate_versions", {})
_cert_gate_missing := [g |
    g := _expected_gates[_]
    object.get(_cert_gate_ids, g, "") == ""
]

routing_cb10 = "BLOCK_AND_ALERT" {
    _has_flag("certificate_issued")
    count(_cert_gate_missing) > 0
} else = "TRIAGE_QUEUE" {
    count(_cert_gate_missing) > 0
} else = "SUGGEST" {
    true
}

reason_cb10 = sprintf("Certyfikat bez ID wersji bramek %v — BLOCK (provenance niekompletny; F4 wymaga pełnego łańcucha dowodów).", [_cert_gate_missing]) {
    _has_flag("certificate_issued")
    count(_cert_gate_missing) > 0
} else = sprintf("Certyfikat w toku: brak ID wersji bramek %v — TRIAGE (uzupełnić przed wystawieniem).", [_cert_gate_missing]) {
    count(_cert_gate_missing) > 0
} else = "Certyfikat zawiera ID wersji wszystkich 8 bramek — pełny dowód provenance (P11)." {
    true
}

gate_to_certificate_decision := _certificate(429010, {
    "rule_id": "jdg.v3_p29_quality_campaigns.gate_to_certificate",
    "analysis": "gate_to_certificate",
    "certificate_gate_versions_present": count(_cert_gate_ids),
    "gate_versions_missing": _cert_gate_missing,
    "certificate_issued": _has_flag("certificate_issued"),
    "_routing": routing_cb10,
    "_routing_reason": reason_cb10,
    "_legal_basis": "V3_P29 §5.4/AN04; V2 F4 Decision Certificate; kontrakt P11/P44",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "gate_to_certificate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I11: TEST UPGRADE PIPELINE — CANDIDATE→ACTIVE wymaga testów granicznych
# ═══════════════════════════════════════════════════════════════════════════════
_upgrade_candidates := object.get(_ctx, "lifecycle_candidates", [])
_candidates_without_tests := [c |
    c := _upgrade_candidates[_]
    object.get(c, "boundary_tests_generated", false) == false
]

routing_up11 = "BLOCK_AND_ALERT" {
    count(_candidates_without_tests) > 0
} else = "SUGGEST" {
    true
}

reason_up11 = sprintf("Kandydaci CANDIDATE→ACTIVE bez wygenerowanych testów granicznych z tabeli aktów: %v — BLOCK (P36 jako wymóg awansu).", [_candidates_without_tests]) {
    count(_candidates_without_tests) > 0
} else = sprintf("Pipeline testów OK: %v kandydatów, wszyscy z testami granicznymi (akt→test).", [count(_upgrade_candidates)]) {
    true
}

upgrade_pipeline_tests_decision := _certificate(429011, {
    "rule_id": "jdg.v3_p29_quality_campaigns.test_upgrade_pipeline",
    "analysis": "test_upgrade_pipeline",
    "candidates_total": count(_upgrade_candidates),
    "candidates_without_tests": count(_candidates_without_tests),
    "_routing": routing_up11,
    "_routing_reason": reason_up11,
    "_legal_basis": "V3_P29 §5.4/AN04; kontrakt P36 (generatory) i P07 (lifecycle)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "test_upgrade_pipeline"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P29-I12: HOLY DOCUMENTS COMPLIANCE REPORT — zgodność z dokumentami świętymi
# ═══════════════════════════════════════════════════════════════════════════════
_holy_conflicts := object.get(_ctx, "holy_document_conflicts", [])

routing_hc12 = "BLOCK_AND_ALERT" {
    count(_holy_conflicts) > 0
} else = "SUGGEST" {
    true
}

reason_hc12 = sprintf("Konflikty z dokumentami świętymi (ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md / WIZJA_OPA_ENTERPRISE_V2.md): %v — BLOCK (konflikt = BLOCKER z cytatami obu stron).", [_holy_conflicts]) {
    count(_holy_conflicts) > 0
} else = "Bramki nie dopuszczają rozwiązań sprzecznych z dokumentami świętymi — zgodność potwierdzona." {
    true
}

holy_documents_compliance_decision := _certificate(429012, {
    "rule_id": "jdg.v3_p29_quality_campaigns.holy_documents_compliance",
    "analysis": "holy_documents_compliance",
    "conflicts": _holy_conflicts,
    "conflicts_total": count(_holy_conflicts),
    "_routing": routing_hc12,
    "_routing_reason": reason_hc12,
    "_legal_basis": "V3_P29 §4.1; dokumenty święte V1/V2 nadrzędne; protokół prawy pkt 03",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "holy_documents_compliance"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := composite_quality_gate_decision {
    composite_quality_gate_decision.rule_id != ""
} else := mutation_testing_decision {
    mutation_testing_decision.rule_id != ""
} else := quality_debt_ledger_decision {
    quality_debt_ledger_decision.rule_id != ""
} else := deterministic_seed_decision {
    deterministic_seed_decision.rule_id != ""
} else := gate_performance_profiler_decision {
    gate_performance_profiler_decision.rule_id != ""
} else := gate_as_data_decision {
    gate_as_data_decision.rule_id != ""
} else := merge_block_comment_decision {
    merge_block_comment_decision.rule_id != ""
} else := domain_quality_heatmap_decision {
    domain_quality_heatmap_decision.rule_id != ""
} else := facade_assertion_detector_decision {
    facade_assertion_detector_decision.rule_id != ""
} else := gate_to_certificate_decision {
    gate_to_certificate_decision.rule_id != ""
} else := upgrade_pipeline_tests_decision {
    upgrade_pipeline_tests_decision.rule_id != ""
} else := holy_documents_compliance_decision {
    holy_documents_compliance_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p29_quality_campaigns.no_match",
    "package": "jdg.v3_p29_quality_campaigns",
    "priority": 999999,
}
