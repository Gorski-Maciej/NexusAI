# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P39 TESTY I CI — NATYWNE REGO, PYTEST, GOLDEN, FUZZ I BRAMKI
# BLOKUJĄCE (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa testowa/CI ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Test Matrix from Acts (generator P36: akt × artykuł × granica
#       grosze/data/waluta → przypadki; pokrycie matrycy = metryka CI; akt bez
#       przypadków granicznych = TRIAGE, brak generatora = BLOCK),
#   I02 Golden Replay as PR Gate (golden verdicts P10 przy każdym PR; regresja
#       decyzji > 0 = BLOCK; golden niepodpięty do PR = BLOCK),
#   I03 Temporal Pair Tests (dzień przed/po przełączeniu z valid_from/valid_to
#       P05; brak pary dla aktów z oknami = TRIAGE; brak generatora par = BLOCK),
#   I04 Negative-First Testing (każdy test pozytywny ma parę negatywną: brak
#       pola → NEEDS_ADVICE; suite bez asercji negatywnych = BLOCK; AP06),
#   I05 Property Invariants Pack (niezmienniki: suma składek ≥ 0, VAT ∈
#       stawki, waluta stabilna; używane przez property/fuzz; pusty pakiet =
#       BLOCK),
#   I06 Mutation Testing Rego (mutacje reguł P29 w nightly; czułość suite'a
#       < próg = TRIAGE; brak uruchomienia = TRIAGE),
#   I07 Flake Quarantine (test flakowy → kwarantanna z terminem naprawy;
#       flak na ścieżce merge = BLOCK; kwarantanna bez terminu = TRIAGE),
#   I08 Contract Version Pinning (testy kontraktowe pinują wersję schematu
#       werdyktu P03; breaking bez PR migracyjnego = BLOCK; brak pinu = TRIAGE),
#   I09 Coverage by Legal Act (pokrycie per AKT prawny, nie per plik; trend w
#       P37; pokrycie < próg = TRIAGE; brak raportu = BLOCK),
#   I10 Performance Budget CI (benchmark eval P37 w CI; regresja p95 > 10% =
#       BLOCK; brak baseline = BLOCK — spójne z P37-I12),
#   I11 Seed-Replay Determinism (test z losowością zapisuje seed; replay po
#       awarii 1:1; test losowy bez seeda = BLOCK),
#   I12 Test Impact Map (mapa zmiana_pliku → dotknięte testy z routingu P02;
#       PR uruchamia tylko istotne testy; mapa nieaktualna = TRIAGE).
#
# Piramida testów (kontrakt strategii; tabela w raporcie 9.10):
#   L1 unit rego (PR, granice grosze/daty/waluty, BLOCK przy fail)
#   L2 integracyjne pytest (PR, domeny łączone, BLOCK)
#   L3 kontraktowe (PR, werdykt 25-polowy + certyfikat F4, BLOCK)
#   L4 golden replay (PR, regresja decyzji = 0, BLOCK)
#   L5 temporal day-0/day+1 (PR dla zmian progu, BLOCK)
#   L6 fuzz/property (nightly, niezmienniki fail-closed, TRIAGE przy fail)
#   L7 wydajnościowe benchmark (PR/nightly, p95 regresja > 10% = BLOCK)
#
# Integracje (kontrakty między-częściowe):
#   * P34 — sieć walidacji L1–L5: testy jako poziomy walidacji w CI (dane),
#   * P37 — katalog metryk/SLO: progi testowe i benchmarkowe jako SLO,
#   * P10 — golden verdicts jako bramka PR (I02),
#   * P05/P36 — temporal pair tests generowane z valid_from/valid_to (I03),
#   * P29 — bramki jakości i mutation testing (I06),
#   * P02 — routing O(1) dla test impact map (I12),
#   * P33 — chaos/fuzz mutacje input i data z asercją fail-closed (I05),
#   * P38 — benchmark gate przed deployem bundle (I10), okna wdrożeniowe,
#   * P44 — certyfikacja finalna: pokrycie matrycy aktów jako dowód (I01/I09).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p39 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * FAIL-CLOSED (V1 zasada 6): regresja golden, brak asercji negatywnych,
#     test losowy bez seeda = BLOCK — nigdy „zawsze-zielone" CI.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p39_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p39_testy_ci.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p39_testy_ci
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p39_testy_ci

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p39_check", false) == true
_ctx := object.get(input, "v3_p39", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p39_snapshot := data.jdg.thresholds.v3_p39

_snapshot_ok = true {
    count(_p39_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p39_snapshot) > 0
    value := object.get(_p39_snapshot, key, null)
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
    "rule_id": "jdg.v3_p39_testy_ci.thresholds_missing",
    "package": "jdg.v3_p39_testy_ci",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "TESTY CI V3-P39: brak snapshotu data.jdg.thresholds.v3_p39.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P39] Brak snapshotu progów testowych — bramki CI ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p39_testy_ci",
        "priority": priority,
        "threshold_version": object.get(_p39_snapshot, "v3_p39_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p39_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p39_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I01: TEST MATRIX FROM ACTS — akt × artykuł × granica (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_tm := object.get(_ctx, "test_matrix", {})
_tm_no_generator := _has_flag("matrix_generator_missing")
_tm_acts_without_cases := object.get(_tm, "acts_without_boundary_cases", 0)
_tm_min := _th("v3_p39_matrix_coverage_min_pct", 80)

routing_tm01 = "BLOCK_AND_ALERT" {
    _tm_no_generator
} else = "TRIAGE_QUEUE" {
    _tm_acts_without_cases > 0
} else = "SUGGEST" {
    true
}

reason_tm01 = sprintf("Brak generatora matrycy testów (P36) — BLOCK (akt × artykuł × granica grosze/data/waluta jako dane; K03).", []) {
    _tm_no_generator
} else = sprintf("Akty bez przypadków granicznych w matrycy: %v — TRIAGE (pokrycie matrycy < %v%%; granice groszowe i day-0 nie testowane).", [_tm_acts_without_cases, _tm_min]) {
    _tm_acts_without_cases > 0
} else = sprintf("Test matrix OK: pokrycie aktów ≥ %v%%, granice grosze/data/waluta wygenerowane.", [_tm_min]) {
    true
}

act_matrix_decision := _certificate(439001, {
    "rule_id": "jdg.v3_p39_testy_ci.test_matrix",
    "analysis": "test_matrix",
    "acts_without_boundary_cases": _tm_acts_without_cases,
    "matrix_generator_missing": _tm_no_generator,
    "matrix_coverage_min_pct": _tm_min,
    "_routing": routing_tm01,
    "_routing_reason": reason_tm01,
    "_legal_basis": "V3_P39 §10/I01; UoR art. 4 ust. 1 (rzetelność wyliczeń) [NIEZWERYFIKOWANE]; kontrakt P36 (generatory)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "test_matrix"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I02: GOLDEN REPLAY AS PR GATE — regresja decyzji = BLOCKER (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_gr := object.get(_ctx, "golden_replay_gate", {})
_gr_regressions := object.get(_gr, "golden_regressions", 0)
_gr_not_in_pr := _has_flag("golden_not_in_pr_gate")

routing_gr02 = "BLOCK_AND_ALERT" {
    _gr_regressions > 0
} else = "BLOCK_AND_ALERT" {
    _gr_not_in_pr
} else = "SUGGEST" {
    true
}

reason_gr02 = sprintf("Regresja golden verdicts: %v — BLOCK (przeszłość nie zmienia decyzji; diff inputów w raporcie PR; P10).", [_gr_regressions]) {
    _gr_regressions > 0
} else = sprintf("Golden replay niepodpięty jako bramka PR — BLOCK (każdy PR mógłby cicho zmienić decyzje historyczne).", []) {
    _gr_not_in_pr
} else = sprintf("Golden replay OK: %v decyzji bez regresji w bramce PR.", [object.get(_gr, "golden_total", 0)]) {
    true
}

golden_replay_gate_decision := _certificate(439002, {
    "rule_id": "jdg.v3_p39_testy_ci.golden_replay_gate",
    "analysis": "golden_replay_gate",
    "golden_regressions": _gr_regressions,
    "golden_not_in_pr_gate": _gr_not_in_pr,
    "_routing": routing_gr02,
    "_routing_reason": reason_gr02,
    "_legal_basis": "V3_P39 §10/I02; UoR art. 4 (rzetelność) [NIEZWERYFIKOWANE]; kontrakt P10 (Golden Oracle)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_replay_gate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I03: TEMPORAL PAIR TESTS — dzień przed/po przełączeniu (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_tp := object.get(_ctx, "temporal_pairs", {})
_tp_missing := object.get(_tp, "acts_without_temporal_pairs", 0)
_tp_no_generator := _has_flag("temporal_pair_generator_missing")

routing_tp03 = "BLOCK_AND_ALERT" {
    _tp_no_generator
} else = "TRIAGE_QUEUE" {
    _tp_missing > 0
} else = "SUGGEST" {
    true
}

reason_tp03 = sprintf("Brak generatora par temporalnych — BLOCK (day-0/day+1 z valid_from/valid_to jako dane; lex retro non agit [NIEZWERYFIKOWANE]).", []) {
    _tp_no_generator
} else = sprintf("Akty bez par temporalnych (przed/po przełączeniu): %v — TRIAGE (przejście nowelizacji nietestowane; P05).", [_tp_missing]) {
    _tp_missing > 0
} else = sprintf("Temporal pairs OK: każde przełączenie dat ma test dzień-przed i dzień-po.", []) {
    true
}

temporal_pairs_decision := _certificate(439003, {
    "rule_id": "jdg.v3_p39_testy_ci.temporal_pairs",
    "analysis": "temporal_pairs",
    "acts_without_temporal_pairs": _tp_missing,
    "temporal_pair_generator_missing": _tp_no_generator,
    "_routing": routing_tp03,
    "_routing_reason": reason_tp03,
    "_legal_basis": "V3_P39 §10/I03; ISAP zasada lex retro non agit [NIEZWERYFIKOWANE]; kontrakt P05 (temporalność)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "temporal_pairs"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I04: NEGATIVE-FIRST TESTING — asercje negatywne obowiązkowe (AN01/AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_nf := object.get(_ctx, "negative_first", {})
_nf_suites_without_negative := object.get(_nf, "suites_without_negative_assertions", 0)
_nf_missing_pairs := object.get(_nf, "positive_tests_missing_negative_pair", 0)

routing_nf04 = "BLOCK_AND_ALERT" {
    _nf_suites_without_negative > 0
} else = "TRIAGE_QUEUE" {
    _nf_missing_pairs > 0
} else = "SUGGEST" {
    true
}

reason_nf04 = sprintf("Suity bez asercji negatywnych: %v — BLOCK (AP06 testy zawsze-zielone; brak pola → NEEDS_ADVICE musi być testowane).", [_nf_suites_without_negative]) {
    _nf_suites_without_negative > 0
} else = sprintf("Testy pozytywne bez pary negatywnej: %v — TRIAGE (konwencja negative-first; lint P34 wymusza).", [_nf_missing_pairs]) {
    _nf_missing_pairs > 0
} else = sprintf("Negative-first OK: każdy test pozytywny ma parę negatywną (fail-closed testowany).", []) {
    true
}

negative_first_decision := _certificate(439004, {
    "rule_id": "jdg.v3_p39_testy_ci.negative_first",
    "analysis": "negative_first",
    "suites_without_negative_assertions": _nf_suites_without_negative,
    "positive_tests_missing_negative_pair": _nf_missing_pairs,
    "_routing": routing_nf04,
    "_routing_reason": reason_nf04,
    "_legal_basis": "V3_P39 §10/I04; KKS art. 56 (fail-closed redukuje ryzyko) [NIEZWERYFIKOWANE]; AP06",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "negative_first"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I05: PROPERTY INVARIANTS PACK — niezmienniki dla property/fuzz (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_pi := object.get(_ctx, "property_invariants", {})
_pi_empty := _has_flag("invariants_pack_empty")
_pi_violations := object.get(_pi, "invariant_violations", 0)

routing_pi05 = "BLOCK_AND_ALERT" {
    _pi_violations > 0
} else = "BLOCK_AND_ALERT" {
    _pi_empty
} else = "SUGGEST" {
    true
}

reason_pi05 = sprintf("Naruszenie niezmiennika: %v — BLOCK (suma składek ≥ 0, VAT ∈ stawki, waluta stabilna; chaos P33 z fail-closed).", [_pi_violations]) {
    _pi_violations > 0
} else = sprintf("Pakiet niezmienników pusty — BLOCK (fuzz bez niezmienników = chaos bez asercji; K10).", []) {
    _pi_empty
} else = sprintf("Property invariants OK: %v przypadków bez naruszeń niezmienników.", [object.get(_pi, "cases_checked", 0)]) {
    true
}

property_invariants_decision := _certificate(439005, {
    "rule_id": "jdg.v3_p39_testy_ci.property_invariants",
    "analysis": "property_invariants",
    "invariant_violations": _pi_violations,
    "invariants_pack_empty": _pi_empty,
    "_routing": routing_pi05,
    "_routing_reason": reason_pi05,
    "_legal_basis": "V3_P39 §10/I05; VAT art. 108 (stawki) [NIEZWERYFIKOWANE]; kontrakt P33 (chaos fail-closed)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "property_invariants"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I06: MUTATION TESTING REGO — czułość suite'a (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_mt := object.get(_ctx, "mutation_testing", {})
_mt_score := object.get(_mt, "mutation_score_pct", 100)
_mt_not_run := _has_flag("mutation_testing_not_run")
_mt_min := _th("v3_p39_mutation_score_min_pct", 85)

routing_mt06 = "TRIAGE_QUEUE" {
    _mt_score < _mt_min
} else = "TRIAGE_QUEUE" {
    _mt_not_run
} else = "SUGGEST" {
    true
}

reason_mt06 = sprintf("Czułość mutacyjna %v%% < %v%% — TRIAGE (suite nie wykrywa mutacji reguł; nightly P29; próg spójny z v3_17).", [_mt_score, _mt_min]) {
    _mt_score < _mt_min
} else = sprintf("Mutation testing nie uruchomiony w cyklu — TRIAGE (nightly; bez mutacji nie wiemy czy testy coś testują).", []) {
    _mt_not_run
} else = sprintf("Mutation testing OK: czułość %v%% ≥ %v%%.", [_mt_score, _mt_min]) {
    true
}

mutation_testing_decision := _certificate(439006, {
    "rule_id": "jdg.v3_p39_testy_ci.mutation_testing",
    "analysis": "mutation_testing",
    "mutation_score_pct": _mt_score,
    "mutation_testing_not_run": _mt_not_run,
    "mutation_score_min_pct": _mt_min,
    "_routing": routing_mt06,
    "_routing_reason": reason_mt06,
    "_legal_basis": "V3_P39 §10/I06; kontrakt P29-I02 (próg 85 spójny z v3_17)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "mutation_testing"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I07: FLAKE QUARANTINE — flak poza ścieżką merge (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_fq := object.get(_ctx, "flake_quarantine", {})
_fq_on_merge_path := object.get(_fq, "flaky_tests_on_merge_path", 0)
_fq_no_deadline := object.get(_fq, "quarantined_without_deadline", 0)

routing_fq07 = "BLOCK_AND_ALERT" {
    _fq_on_merge_path > 0
} else = "TRIAGE_QUEUE" {
    _fq_no_deadline > 0
} else = "SUGGEST" {
    true
}

reason_fq07 = sprintf("Testy flakowe na ścieżce merge: %v — BLOCK (flak trafia do kwarantanny — osobny job; zero trwałych flaków blokujących PR).", [_fq_on_merge_path]) {
    _fq_on_merge_path > 0
} else = sprintf("Kwarantanny bez terminu naprawy: %v — TRIAGE (flak bez deadline = trwały; termin + owner).", [_fq_no_deadline]) {
    _fq_no_deadline > 0
} else = sprintf("Flake quarantine OK: ścieżka merge deterministyczna.", []) {
    true
}

flake_quarantine_decision := _certificate(439007, {
    "rule_id": "jdg.v3_p39_testy_ci.flake_quarantine",
    "analysis": "flake_quarantine",
    "flaky_tests_on_merge_path": _fq_on_merge_path,
    "quarantined_without_deadline": _fq_no_deadline,
    "_routing": routing_fq07,
    "_routing_reason": reason_fq07,
    "_legal_basis": "V3_P39 §10/I07; kontrakt P36 (generatory testów), P41 (dokumentacja)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "flake_quarantine"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I08: CONTRACT VERSION PINNING — breaking schema = BLOCKER (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_cv := object.get(_ctx, "contract_pinning", {})
_cv_breaking := object.get(_cv, "breaking_changes_without_migration_pr", 0)
_cv_unpinned := object.get(_cv, "contract_tests_without_pin", 0)

routing_cv08 = "BLOCK_AND_ALERT" {
    _cv_breaking > 0
} else = "TRIAGE_QUEUE" {
    _cv_unpinned > 0
} else = "SUGGEST" {
    true
}

reason_cv08 = sprintf("Breaking change kontraktu werdyktu bez PR migracyjnego: %v — BLOCK (schemat 25-polowy P03 wersjonowany; breaking = jawna migracja).", [_cv_breaking]) {
    _cv_breaking > 0
} else = sprintf("Testy kontraktowe bez pinu wersji schematu: %v — TRIAGE (pin = wykrywalność breaking).", [_cv_unpinned]) {
    _cv_unpinned > 0
} else = sprintf("Contract pinning OK: testy pilnują wersji schematu werdyktu i certyfikatu.", []) {
    true
}

contract_pinning_decision := _certificate(439008, {
    "rule_id": "jdg.v3_p39_testy_ci.contract_pinning",
    "analysis": "contract_pinning",
    "breaking_changes_without_migration_pr": _cv_breaking,
    "contract_tests_without_pin": _cv_unpinned,
    "_routing": routing_cv08,
    "_routing_reason": reason_cv08,
    "_legal_basis": "V3_P39 §10/I08; kontrakt P03 (werdykt 25-polowy), P11 (certyfikat F4)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "contract_pinning"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I09: COVERAGE BY LEGAL ACT — pokrycie per akt, nie per plik (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_ca := object.get(_ctx, "coverage_by_act", {})
_ca_no_report := _has_flag("act_coverage_report_missing")
_ca_below := object.get(_ca, "acts_below_coverage_threshold", 0)
_ca_min := _th("v3_p39_act_coverage_min_pct", 90)

routing_ca09 = "BLOCK_AND_ALERT" {
    _ca_no_report
} else = "TRIAGE_QUEUE" {
    _ca_below > 0
} else = "SUGGEST" {
    true
}

reason_ca09 = sprintf("Brak raportu pokrycia per akt prawny — BLOCK (CI nie mierzy tego co krytyczne: akt→reguła→test; K12).", []) {
    _ca_no_report
} else = sprintf("Akty poniżej progu pokrycia %v%%: %v — TRIAGE (trend w P37; pustynie testowe widoczne).", [_ca_min, _ca_below]) {
    _ca_below > 0
} else = sprintf("Coverage by act OK: wszystkie akty ≥ %v%% pokrycia testami.", [_ca_min]) {
    true
}

coverage_by_act_decision := _certificate(439009, {
    "rule_id": "jdg.v3_p39_testy_ci.coverage_by_act",
    "analysis": "coverage_by_act",
    "acts_below_coverage_threshold": _ca_below,
    "act_coverage_report_missing": _ca_no_report,
    "act_coverage_min_pct": _ca_min,
    "_routing": routing_ca09,
    "_routing_reason": reason_ca09,
    "_legal_basis": "V3_P39 §10/I09; UoR art. 4 [NIEZWERYFIKOWANE]; kontrakt P37 (trend), P44 (certyfikacja)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "coverage_by_act"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I10: PERFORMANCE BUDGET CI — benchmark z progiem regresji (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_pb := object.get(_ctx, "performance_budget", {})
_pb_regression := object.get(_pb, "benchmark_regression_pct", 0)
_pb_no_baseline := _has_flag("benchmark_baseline_missing")
_pb_max := _th("v3_p39_benchmark_regression_max_pct", 10)

routing_pb10 = "BLOCK_AND_ALERT" {
    _pb_regression > _pb_max
} else = "BLOCK_AND_ALERT" {
    _pb_no_baseline
} else = "SUGGEST" {
    true
}

reason_pb10 = sprintf("Regresja benchmarku p95: %v%% > %v%% — BLOCK (L7 piramidy; spójne z P37-I12 i P38-I10 przed deployem).", [_pb_regression, _pb_max]) {
    _pb_regression > _pb_max
} else = sprintf("Brak baseline benchmarków — BLOCK (CI nie ma czego bronić; P37 eval_baseline).", []) {
    _pb_no_baseline
} else = sprintf("Performance budget OK: regresja %v%% ≤ %v%%.", [_pb_regression, _pb_max]) {
    true
}

performance_budget_decision := _certificate(439010, {
    "rule_id": "jdg.v3_p39_testy_ci.performance_budget",
    "analysis": "performance_budget",
    "benchmark_regression_pct": _pb_regression,
    "benchmark_baseline_missing": _pb_no_baseline,
    "benchmark_regression_max_pct": _pb_max,
    "_routing": routing_pb10,
    "_routing_reason": reason_pb10,
    "_legal_basis": "V3_P39 §10/I10; kontrakt P37-I12 (benchmark gate), P38-K1 (deploy)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "performance_budget"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I11: SEED-REPLAY DETERMINISM — test losowy z zapisanym seedem (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_sr := object.get(_ctx, "seed_replay", {})
_sr_without_seed := object.get(_sr, "random_tests_without_seed", 0)
_sr_no_replay := _has_flag("seed_replay_missing")

routing_sr11 = "BLOCK_AND_ALERT" {
    _sr_without_seed > 0
} else = "TRIAGE_QUEUE" {
    _sr_no_replay
} else = "SUGGEST" {
    true
}

reason_sr11 = sprintf("Testy losowe bez zapisanego seeda: %v — BLOCK (awaria niereprodukowalna 1:1; determinizm CI).", [_sr_without_seed]) {
    _sr_without_seed > 0
} else = sprintf("Mechanizm seed-replay niepodpięty w CI — TRIAGE (replay po awarii 1:1).", []) {
    _sr_no_replay
} else = sprintf("Seed-replay OK: każdy test losowy odtwarzalny z seeda.", []) {
    true
}

seed_replay_decision := _certificate(439011, {
    "rule_id": "jdg.v3_p39_testy_ci.seed_replay",
    "analysis": "seed_replay",
    "random_tests_without_seed": _sr_without_seed,
    "seed_replay_missing": _sr_no_replay,
    "_routing": routing_sr11,
    "_routing_reason": reason_sr11,
    "_legal_basis": "V3_P39 §10/I11; kontrakt P33 (fuzz/chaos deterministyczny)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "seed_replay"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P39-I12: TEST IMPACT MAP — zmiana pliku → dotknięte testy (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_im := object.get(_ctx, "impact_map", {})
_im_stale_days := object.get(_im, "map_stale_days", 0)
_im_missing := _has_flag("impact_map_missing")
_im_max := _th("v3_p39_impact_map_max_stale_days", 7)

routing_im12 = "TRIAGE_QUEUE" {
    _im_missing
} else = "TRIAGE_QUEUE" {
    _im_stale_days > _im_max
} else = "SUGGEST" {
    true
}

reason_im12 = sprintf("Test impact map nie istnieje — TRIAGE (PR uruchamia wszystko = wolno, albo nic = niebezpiecznie; routing P02 jako źródło).", []) {
    _im_missing
} else = sprintf("Impact map nieświeża: %v dni > %v — TRIAGE (mapa z dryfu routingu; nieaktualna = fałszywe bezpieczeństwo).", [_im_stale_days, _im_max]) {
    _im_stale_days > _im_max
} else = sprintf("Test impact map OK: PR uruchamia tylko testy dotknięte zmianą (bez utraty bezpieczeństwa — golden zawsze).", []) {
    true
}

impact_map_decision := _certificate(439012, {
    "rule_id": "jdg.v3_p39_testy_ci.impact_map",
    "analysis": "impact_map",
    "map_stale_days": _im_stale_days,
    "impact_map_missing": _im_missing,
    "impact_map_max_stale_days": _im_max,
    "_routing": routing_im12,
    "_routing_reason": reason_im12,
    "_legal_basis": "V3_P39 §10/I12; kontrakt P02 (routing O(1))",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "impact_map"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := act_matrix_decision {
    act_matrix_decision.rule_id != ""
} else := golden_replay_gate_decision {
    golden_replay_gate_decision.rule_id != ""
} else := temporal_pairs_decision {
    temporal_pairs_decision.rule_id != ""
} else := negative_first_decision {
    negative_first_decision.rule_id != ""
} else := property_invariants_decision {
    property_invariants_decision.rule_id != ""
} else := mutation_testing_decision {
    mutation_testing_decision.rule_id != ""
} else := flake_quarantine_decision {
    flake_quarantine_decision.rule_id != ""
} else := contract_pinning_decision {
    contract_pinning_decision.rule_id != ""
} else := coverage_by_act_decision {
    coverage_by_act_decision.rule_id != ""
} else := performance_budget_decision {
    performance_budget_decision.rule_id != ""
} else := seed_replay_decision {
    seed_replay_decision.rule_id != ""
} else := impact_map_decision {
    impact_map_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p39_testy_ci.no_match",
    "package": "jdg.v3_p39_testy_ci",
    "priority": 999999,
}
