# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P49 DOMKNIĘCIE FAIL-CLOSED — ZERO CICHYCH AUTO_POST
# KAŻDA NIEPEWNOŚĆ MA ŚCIEŻKĘ (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa konstytucyjna fail-closed ENTERPRISE — 12 innowacji (I01–I12;
# minimum z promptu P49 Sekcja 10):
#   I01 Fail-closed invariant pack (kompletność pól, spójność podpisów,
#       zakresy — uruchamiany przed każdym AUTO_POST; odmowa bez pełnego
#       łańcucha dowodów),
#   I02 Default-deny decision core (decyzja domyślnie NEEDS_ADVICE;
#       AUTO_POST wymaga pozytywnego dowodu WSZYSTKICH przesłanek —
#       whitelist dowodów, nie blacklist braków),
#   I03 Missing-field coverage gate (każda reguła z testem „brak pola X →
#       NEEDS_ADVICE"; pokrycie < progu = TRIAGE; narzędzie I03 generuje),
#   I04 Chaos input suite (mutacje input z asercją NEEDS_ADVICE/
#       MANUAL_REVIEW — property-based fail-closed; brak suite = TRIAGE),
#   I05 Circuit breaker per domain (seria N NEEDS_ADVICE w oknie T → tryb
#       REVIEW domeny z raportem przyczyny; próg z data.thresholds.v3_p49),
#   I06 Amount ceiling as data (limit kwotowy AUTO_POST jako parametr —
#       powyżej = MANUAL_REVIEW 4-eyes, nawet przy pełnym dowodzie),
#   I07 Reason completeness check (NEEDS_ADVICE bez czytelnego powodu =
#       defekt; linter ścieżek NEEDS_ADVICE — fail-closed nie może być
#       fasadą),
#   I08 Emergency export path (ścieżka awaryjna eksportu certyfikatów i
#       stanu — DR P43; dostępna bez pełnej platformy),
#   I09 Decision trail replay audit (replay AUTO_POST z tygodnia na
#       obecnych regułach; decyzje, które dziś byłyby NEEDS_ADVICE →
#       lista rewizji),
#   I10 Fail-closed score (metryka % ścieżek jawnie fail-closed — cel 100%;
#       trend w P37),
#   I11 Silent-post canary (syntetyczne inputy z brakami cyklicznie do
#       produkcji — asercja fail-closed na żywo; cichy post = BLOCK),
#   I12 User-visible safety (UI P40: NEEDS_ADVICE zawsze z akcją
#       „co muszę uzupełnić"; AUTO_POST z dowodem do pobrania).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p49 — ADR-002 (P06), okno
#     temporalne valid_from (P05). ZERO hardcode progów.
#   * Fail-closed (V1 zasada 6): brak snapshotu progów, brak rejestru
#     fail-open, naruszenie AP07 (cichy AUTO_POST) = BLOCK — nigdy cicha
#     decyzja przy wątpliwości. Wątpliwość = człowiek.
#   * Honesty: liczniki z narzędzi i bundli (nie deklaracje); rejestr ścieżek
#     fail-open mierzony na żywo skanerem (v3_p49_fail_open_scanner.py),
#     baseline (pomiar 2026-09-11) raportowany uczciwie jako backlog.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     [NIEZWERYFIKOWANE — ISAP] do czasu stempla 4-eyes (protokół 04;
#     konwencja P47/P48).
#   * Aktywacja: input.jdg_entrepreneur.v3_p49_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p49_fail_closed.<reguła>.
#   * Kontrakty: P03 (kontrakt werdyktu 25-polowy, ADR-004), P04
#     (invarianty runtime), P36/P37 (radar NEEDS_ADVICE, SLA, obserwowalność),
#     P40 (UI decision-first), P43 (DR), P45 (rejestr), P46
#     (parametry-as-data), P47 (kanon cytowań), P48 (zero dryfu mirror),
#     P68 (certyfikacja finalna).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p49_fail_closed
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p49_fail_closed

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p49_check", false) == true
_ctx := object.get(input, "v3_p49", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p49_snapshot := data.jdg.thresholds.v3_p49

_snapshot_ok = true {
    count(_p49_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p49_snapshot) > 0
    value := object.get(_p49_snapshot, key, null)
    value != null
} else = fallback

_has_flag(key) = result {
    result := object.get(_ctx, key, false) == true
} else = false {
    true
}

# ── Fail-closed gdy snapshot progów niedostępny (default-deny I02) ─────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p49_fail_closed.thresholds_missing",
    "package": "jdg.v3_p49_fail_closed",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "FAIL-CLOSED V3-P49: brak snapshotu data.jdg.thresholds.v3_p49 — default-deny.",
    "_legal_basis": "ADR-002; V1 zasada 6 (fail-closed); ustawa o rachunkowości art. 4 ust. 1 (rzetelność) [NIEZWERYFIKOWANE — ISAP]",
    "_warnings": ["[V3-P49] Brak snapshotu progów fail-closed — decyzje ZABLOKOWANE (domyślna odmowa)."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p49_fail_closed",
        "priority": priority,
        "threshold_version": object.get(_p49_snapshot, "v3_p49_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p49_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p49_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I01: FAIL-CLOSED INVARIANT PACK — pack przed każdym AUTO_POST (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_pack := object.get(_ctx, "invariant_pack", {})
_pack_total := object.get(_pack, "invariants_total", 0)
_pack_enabled := object.get(_pack, "invariants_enabled", 0)
_pack_violations := object.get(_pack, "violations", 0)
_pack_block := object.get(_pack, "auto_post_blocked", 0)
_invariants_min := _th("v3_p49_invariants_min", 4)

routing_pk01 = "BLOCK_AND_ALERT" {
    _has_flag("invariants_bypassed")
} else = "BLOCK_AND_ALERT" {
    _pack_violations > 0
} else = "BLOCK_AND_ALERT" {
    _pack_total > 0
    _pack_enabled < _pack_total
} else = "TRIAGE_QUEUE" {
    _pack_total < _invariants_min
} else = "AUTO_FILE" {
    true
}

invariant_pack_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "invariant_pack"
    routing_pk01 == "AUTO_FILE"
    cert := _certificate(449001, {
        "rule_id": "jdg.v3_p49_fail_closed.invariant_pack",
        "decision_mode": "AUTO_POST",
        "_routing": routing_pk01,
        "_routing_reason": "FAIL-CLOSED: pack invariantów kompletny i włączony przed każdym AUTO_POST.",
        "_legal_basis": "P49-I01; P04 invarianty runtime; V2 F2 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "invariants_total": _pack_total,
        "invariants_enabled": _pack_enabled,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "invariant_pack"
    routing_pk01 == "TRIAGE_QUEUE"
    cert := _certificate(449001, {
        "rule_id": "jdg.v3_p49_fail_closed.invariant_pack",
        "decision_mode": "TRIAGE",
        "_routing": routing_pk01,
        "_routing_reason": "FAIL-CLOSED: pack invariantów poniżej minimum — AUTO_POST bez pełnego łańcucha ryzyko.",
        "_legal_basis": "P49-I01; P04; protokół 05 (pełny łańcuch dowodów)",
        "_warnings": ["[V3-P49] Uzupełnij pack invariantów do minimum progowego."],
        "invariants_total": _pack_total,
        "invariants_min": _invariants_min,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "invariant_pack"
    routing_pk01 == "BLOCK_AND_ALERT"
    cert := _certificate(449001, {
        "rule_id": "jdg.v3_p49_fail_closed.invariant_pack",
        "decision_mode": "BLOCK",
        "_routing": routing_pk01,
        "_routing_reason": "FAIL-CLOSED: naruszenie invariantu / wyłączony invariant — AUTO_POST ZABLOKOWANY.",
        "_legal_basis": "P49-I01; AP07; Ordynacja art. 21 §1 (organ stosuje prawo materialne) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P49] Invariant pack naruszony — decyzja wymaga człowieka."],
        "violations": _pack_violations,
        "auto_post_blocked": _pack_block,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I02: DEFAULT-DENY DECISION CORE — whitelist dowodów (AN01/AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_ddc := object.get(_ctx, "default_deny_core", {})
_silent_ap := object.get(_ddc, "silent_auto_posts", 0)
_ap_wo_evidence := object.get(_ddc, "auto_post_without_evidence", 0)
_ap_total := object.get(_ddc, "auto_post_total", 0)
_ap_with_full_chain := object.get(_ddc, "auto_post_full_evidence_chain", 0)
_silent_max := _th("v3_p49_silent_auto_post_max", 0)

routing_dd02 = "BLOCK_AND_ALERT" {
    _has_flag("default_deny_bypassed")
} else = "BLOCK_AND_ALERT" {
    _silent_ap > _silent_max
} else = "BLOCK_AND_ALERT" {
    _ap_wo_evidence > 0
} else = "TRIAGE_QUEUE" {
    not _counters_sane
} else = "TRIAGE_QUEUE" {
    _ap_total > 0
    _ap_with_full_chain < _ap_total
} else = "AUTO_FILE" {
    true
}

# Sanity liczników (chaos CH07: ujemne/śmieciowe wartości nie mogą prowadzić
# do AUTO_POST — default-deny na malformowany input; lekcja chaos suite P49).
_counters_sane {
    _ap_total >= 0
    _ap_with_full_chain >= 0
    _ap_with_full_chain <= _ap_total
    _silent_ap >= 0
    _ap_wo_evidence >= 0
}

default_deny_core_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "default_deny_core"
    routing_dd02 == "AUTO_FILE"
    cert := _certificate(449002, {
        "rule_id": "jdg.v3_p49_fail_closed.default_deny_core",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dd02,
        "_routing_reason": "FAIL-CLOSED: zero cichych AUTO_POST; każda decyzja z pełnym łańcuchem dowodów (whitelist).",
        "_legal_basis": "P49-I02; AP07; V1 zasada 6; RODO art. 22 (nadzór człowieka) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "auto_post_total": _ap_total,
        "auto_post_full_evidence_chain": _ap_with_full_chain,
        "silent_auto_posts": _silent_ap,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "default_deny_core"
    routing_dd02 == "TRIAGE_QUEUE"
    cert := _certificate(449002, {
        "rule_id": "jdg.v3_p49_fail_closed.default_deny_core",
        "decision_mode": "TRIAGE",
        "_routing": routing_dd02,
        "_routing_reason": "FAIL-CLOSED: AUTO_POST z niepełnym łańcuchem dowodów — uzupełnić whitelist przesłanek.",
        "_legal_basis": "P49-I02; P03 kontrakt werdyktu (ADR-004); protokół 05",
        "_warnings": ["[V3-P49] AUTO_POST bez pełnego dowodu — domknąć łańcuch przesłanek."],
        "auto_post_total": _ap_total,
        "auto_post_full_evidence_chain": _ap_with_full_chain,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "default_deny_core"
    routing_dd02 == "BLOCK_AND_ALERT"
    cert := _certificate(449002, {
        "rule_id": "jdg.v3_p49_fail_closed.default_deny_core",
        "decision_mode": "BLOCK",
        "_routing": routing_dd02,
        "_routing_reason": "FAIL-CLOSED: cichy AUTO_POST wykryty — najgroźniejsza klasa defektów fortecy.",
        "_legal_basis": "P49-I02; AP07; ustawa VAT art. 108 (błędna stawka = sankcje) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P49] Silent AUTO_POST — decyzje ZABLOKOWANE do czasu naprawy ścieżki."],
        "silent_auto_posts": _silent_ap,
        "auto_post_without_evidence": _ap_wo_evidence,
        "silent_max": _silent_max,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I03: MISSING-FIELD COVERAGE GATE — każda reguła z testem braku (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_mfg := object.get(_ctx, "missing_field_coverage", {})
_rules_total_mfg := object.get(_mfg, "rules_total", 0)
_rules_covered := object.get(_mfg, "rules_covered", 0)
_generator_run := object.get(_mfg, "generator_run", false)
_coverage_pct := pct {
    _rules_total_mfg > 0
    pct := _rules_covered * 100 / _rules_total_mfg
} else := 0 {
    true
}
_coverage_min := _th("v3_p49_field_coverage_min_pct", 95)

routing_mf03 = "BLOCK_AND_ALERT" {
    _has_flag("missing_field_bypassed")
} else = "TRIAGE_QUEUE" {
    not _generator_run
} else = "TRIAGE_QUEUE" {
    _coverage_pct < _coverage_min
} else = "AUTO_FILE" {
    true
}

missing_field_coverage_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "missing_field_coverage"
    routing_mf03 == "AUTO_FILE"
    cert := _certificate(449003, {
        "rule_id": "jdg.v3_p49_fail_closed.missing_field_coverage",
        "decision_mode": "AUTO_POST",
        "_routing": routing_mf03,
        "_routing_reason": "FAIL-CLOSED: pokrycie testami braku pól osiągnęło cel — generator systematyczny.",
        "_legal_basis": "P49-I03; AP03; P39 bramki testowe [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "rules_total": _rules_total_mfg,
        "rules_covered": _rules_covered,
        "coverage_pct": _coverage_pct,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "missing_field_coverage"
    routing_mf03 == "TRIAGE_QUEUE"
    cert := _certificate(449003, {
        "rule_id": "jdg.v3_p49_fail_closed.missing_field_coverage",
        "decision_mode": "TRIAGE",
        "_routing": routing_mf03,
        "_routing_reason": "FAIL-CLOSED: pokrycie testami braku pól poniżej progu / generator niewykonany.",
        "_legal_basis": "P49-I03; AP03; AP06; kontrakt wyjściowy P49 → P36/P39",
        "_warnings": ["[V3-P49] Uruchom generator brakujących pól i uzupełnij testy negatywne."],
        "rules_total": _rules_total_mfg,
        "rules_covered": _rules_covered,
        "coverage_pct": _coverage_pct,
        "coverage_min_pct": _coverage_min,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I04: CHAOS INPUT SUITE — mutacje z asercją fail-closed (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_chaos := object.get(_ctx, "chaos_input", {})
_chaos_cases := object.get(_chaos, "cases_total", 0)
_chaos_failed := object.get(_chaos, "fail_closed_violations", 0)
_chaos_run := object.get(_chaos, "suite_run", false)
_chaos_min := _th("v3_p49_chaos_cases_min", 10)

routing_ch04 = "BLOCK_AND_ALERT" {
    _has_flag("chaos_bypassed")
} else = "BLOCK_AND_ALERT" {
    _chaos_failed > 0
} else = "TRIAGE_QUEUE" {
    not _chaos_run
} else = "TRIAGE_QUEUE" {
    _chaos_cases < _chaos_min
} else = "AUTO_FILE" {
    true
}

chaos_input_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "chaos_input"
    routing_ch04 == "AUTO_FILE"
    cert := _certificate(449004, {
        "rule_id": "jdg.v3_p49_fail_closed.chaos_input",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ch04,
        "_routing_reason": "FAIL-CLOSED: chaos suite zielony — mutacje input nie generują cichych AUTO_POST.",
        "_legal_basis": "P49-I04; K10 (chaos-testy prawne); AP07 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "cases_total": _chaos_cases,
        "fail_closed_violations": _chaos_failed,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "chaos_input"
    routing_ch04 == "TRIAGE_QUEUE"
    cert := _certificate(449004, {
        "rule_id": "jdg.v3_p49_fail_closed.chaos_input",
        "decision_mode": "TRIAGE",
        "_routing": routing_ch04,
        "_routing_reason": "FAIL-CLOSED: chaos suite niewykonany / poniżej minimum scenariuszy.",
        "_legal_basis": "P49-I04; AP06; kryterium 20 (min. 10 scenariuszy mutacji)",
        "_warnings": ["[V3-P49] Uruchom chaos suite z min. 10 mutacjami input."],
        "cases_total": _chaos_cases,
        "chaos_cases_min": _chaos_min,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "chaos_input"
    routing_ch04 == "BLOCK_AND_ALERT"
    cert := _certificate(449004, {
        "rule_id": "jdg.v3_p49_fail_closed.chaos_input",
        "decision_mode": "BLOCK",
        "_routing": routing_ch04,
        "_routing_reason": "FAIL-CLOSED: mutacja input wygenerowała cichy AUTO_POST — ścieżka fail-open.",
        "_legal_basis": "P49-I04; AP07; KKS art. 56-57 (ryzyko czynu zabronionego) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P49] Chaos wykazał fail-open — napraw przed deploy."],
        "fail_closed_violations": _chaos_failed,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I05: CIRCUIT BREAKER PER DOMAIN — seria N NEEDS_ADVICE (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_cb := object.get(_ctx, "circuit_breaker", {})
_domains_total := object.get(_cb, "domains_total", 0)
_domains_review := object.get(_cb, "domains_in_review", 0)
_na_window := object.get(_cb, "needs_advice_in_window", 0)
_breaker_threshold := _th("v3_p49_breaker_threshold", 20)
_breaker_window := _th("v3_p49_breaker_window_min", 60)

routing_cb05 = "BLOCK_AND_ALERT" {
    _has_flag("breaker_bypassed")
} else = "TRIAGE_QUEUE" {
    _domains_in_review_unexplained
} else = "TRIAGE_QUEUE" {
    _domains_review > 0
} else = "TRIAGE_QUEUE" {
    _na_window > _breaker_threshold
} else = "AUTO_FILE" {
    true
}

_domains_in_review_unexplained {
    _domains_review > 0
    count(object.get(_cb, "review_domains_with_reason", [])) == 0
}

circuit_breaker_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "circuit_breaker"
    routing_cb05 == "AUTO_FILE"
    cert := _certificate(449005, {
        "rule_id": "jdg.v3_p49_fail_closed.circuit_breaker",
        "decision_mode": "AUTO_POST",
        "_routing": routing_cb05,
        "_routing_reason": "FAIL-CLOSED: breaker bez aktywacji — liczba NEEDS_ADVICE w normie.",
        "_legal_basis": "P49-I05; P37 radar NEEDS_ADVICE (I03); K08 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "domains_total": _domains_total,
        "needs_advice_in_window": _na_window,
        "breaker_threshold": _breaker_threshold,
        "breaker_window_min": _breaker_window,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "circuit_breaker"
    routing_cb05 == "TRIAGE_QUEUE"
    cert := _certificate(449005, {
        "rule_id": "jdg.v3_p49_fail_closed.circuit_breaker",
        "decision_mode": "TRIAGE",
        "_routing": routing_cb05,
        "_routing_reason": "FAIL-CLOSED: domena w trybie REVIEW / seria NEEDS_ADVICE — raport przyczyny wymagany.",
        "_legal_basis": "P49-I05; P37 SLA NEEDS_ADVICE; P36 kolejka",
        "_warnings": ["[V3-P49] Domena w trybie REVIEW — wygeneruj raport przyczyny (I05)."],
        "domains_in_review": _domains_review,
        "needs_advice_in_window": _na_window,
        "breaker_threshold": _breaker_threshold,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I06: AMOUNT CEILING AS DATA — limit kwotowy AUTO_POST (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_ceil := object.get(_ctx, "amount_ceiling", {})
_ceiling_amount := object.get(_ceil, "auto_post_amount", 0)
_ceiling_limit_cfg := object.get(_ceil, "limit_configured", false)
_ceiling_breaches := object.get(_ceil, "limit_breaches", 0)
_ceiling_limit := _th("v3_p49_auto_post_amount_limit", 15000)

routing_ac06 = "BLOCK_AND_ALERT" {
    _has_flag("ceiling_bypassed")
} else = "BLOCK_AND_ALERT" {
    _ceiling_breaches > 0
} else = "BLOCK_AND_ALERT" {
    not _ceiling_limit_cfg
} else = "TRIAGE_QUEUE" {
    _ceiling_amount > _ceiling_limit
} else = "AUTO_FILE" {
    true
}

amount_ceiling_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "amount_ceiling"
    routing_ac06 == "AUTO_FILE"
    cert := _certificate(449006, {
        "rule_id": "jdg.v3_p49_fail_closed.amount_ceiling",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ac06,
        "_routing_reason": "FAIL-CLOSED: AUTO_POST w limicie kwotowym; limit jako parametr (P46).",
        "_legal_basis": "P49-I06; P46 parametry-as-data; 4-eyes above limit [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "auto_post_amount": _ceiling_amount,
        "amount_limit": _ceiling_limit,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "amount_ceiling"
    routing_ac06 == "TRIAGE_QUEUE"
    cert := _certificate(449006, {
        "rule_id": "jdg.v3_p49_fail_closed.amount_ceiling",
        "decision_mode": "TRIAGE",
        "_routing": routing_ac06,
        "_routing_reason": "FAIL-CLOSED: kwota AUTO_POST ponad limit — decyzja wielka = 4-eyes (MANUAL_REVIEW).",
        "_legal_basis": "P49-I06; P46; ustawa o rachunkowości art. 4 ust. 1 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P49] Kwota ponad limit — przekazano do MANUAL_REVIEW."],
        "auto_post_amount": _ceiling_amount,
        "amount_limit": _ceiling_limit,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "amount_ceiling"
    routing_ac06 == "BLOCK_AND_ALERT"
    cert := _certificate(449006, {
        "rule_id": "jdg.v3_p49_fail_closed.amount_ceiling",
        "decision_mode": "BLOCK",
        "_routing": routing_ac06,
        "_routing_reason": "FAIL-CLOSED: AUTO_POST ponad limit bez ścieżki 4-eyes — naruszenie.",
        "_legal_basis": "P49-I06; AP07; KKS art. 56-57 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P49] Limit kwotowy naruszony / brak konfiguracji limitu."],
        "limit_breaches": _ceiling_breaches,
        "limit_configured": _ceiling_limit_cfg,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I07: REASON COMPLETENESS CHECK — NEEDS_ADVICE bez powodu = defekt (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_rc := object.get(_ctx, "reason_completeness", {})
_na_total := object.get(_rc, "needs_advice_total", 0)
_na_no_reason := object.get(_rc, "needs_advice_without_reason", 0)
_na_short := object.get(_rc, "needs_advice_short_reason", 0)
_min_reason := _th("v3_p49_min_reason_len", 20)

routing_rc07 = "BLOCK_AND_ALERT" {
    _has_flag("reason_bypassed")
} else = "TRIAGE_QUEUE" {
    _na_no_reason > 0
} else = "TRIAGE_QUEUE" {
    _na_short > 0
} else = "AUTO_FILE" {
    true
}

reason_completeness_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "reason_completeness"
    routing_rc07 == "AUTO_FILE"
    cert := _certificate(449007, {
        "rule_id": "jdg.v3_p49_fail_closed.reason_completeness",
        "decision_mode": "AUTO_POST",
        "_routing": routing_rc07,
        "_routing_reason": "FAIL-CLOSED: każdy NEEDS_ADVICE z czytelnym powodem — brak fasady.",
        "_legal_basis": "P49-I07; P37 no_reason_blocked; K08 (triage NEEDS_ADVICE) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "needs_advice_total": _na_total,
        "needs_advice_without_reason": _na_no_reason,
        "min_reason_len": _min_reason,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "reason_completeness"
    routing_rc07 == "TRIAGE_QUEUE"
    cert := _certificate(449007, {
        "rule_id": "jdg.v3_p49_fail_closed.reason_completeness",
        "decision_mode": "TRIAGE",
        "_routing": routing_rc07,
        "_routing_reason": "FAIL-CLOSED: NEEDS_ADVICE bez powodu / zbyt krótki — fasada fail-closed.",
        "_legal_basis": "P49-I07; AP03; RODO art. 22 (istotne informacje o logice) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P49] NEEDS_ADVICE z pustym/krótkim powodem — linter ścieżek."],
        "needs_advice_without_reason": _na_no_reason,
        "needs_advice_short_reason": _na_short,
        "min_reason_len": _min_reason,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I08: EMERGENCY EXPORT PATH — awaryjny eksport certyfikatów (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_ee := object.get(_ctx, "emergency_export", {})
_export_path_ok := object.get(_ee, "export_path_present", false)
_last_export_hours := object.get(_ee, "hours_since_last_export", 999999)
_export_verified := object.get(_ee, "last_export_verified", false)

routing_ee08 = "BLOCK_AND_ALERT" {
    _has_flag("export_bypassed")
} else = "BLOCK_AND_ALERT" {
    not _export_path_ok
} else = "TRIAGE_QUEUE" {
    not _export_verified
} else = "TRIAGE_QUEUE" {
    _last_export_hours > 168
} else = "AUTO_FILE" {
    true
}

emergency_export_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "emergency_export"
    routing_ee08 == "AUTO_FILE"
    cert := _certificate(449008, {
        "rule_id": "jdg.v3_p49_fail_closed.emergency_export",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ee08,
        "_routing_reason": "FAIL-CLOSED: ścieżka awaryjna eksportu certyfikatów obecna i zweryfikowana (DR P43).",
        "_legal_basis": "P49-I08; P43 DR; V1 §11 (odporność) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "hours_since_last_export": _last_export_hours,
        "last_export_verified": _export_verified,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "emergency_export"
    routing_ee08 == "TRIAGE_QUEUE"
    cert := _certificate(449008, {
        "rule_id": "jdg.v3_p49_fail_closed.emergency_export",
        "decision_mode": "TRIAGE",
        "_routing": routing_ee08,
        "_routing_reason": "FAIL-CLOSED: eksport certyfikatów niezweryfikowany / przeterminowany (> 168h).",
        "_legal_basis": "P49-I08; P43; AP11 (detekcja dryfu)",
        "_warnings": ["[V3-P49] Uruchom i zweryfikuj eksport awaryjny stanu."],
        "hours_since_last_export": _last_export_hours,
        "last_export_verified": _export_verified,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "emergency_export"
    routing_ee08 == "BLOCK_AND_ALERT"
    cert := _certificate(449008, {
        "rule_id": "jdg.v3_p49_fail_closed.emergency_export",
        "decision_mode": "BLOCK",
        "_routing": routing_ee08,
        "_routing_reason": "FAIL-CLOSED: brak ścieżki awaryjnej eksportu — awaria przerwie dostęp do dowodów.",
        "_legal_basis": "P49-I08; P43; ustawa o rachunkowości art. 73 (przechowywanie) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P49] Ścieżka eksportu awaryjnego nieobecna — BLOCK."],
        "export_path_present": _export_path_ok,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I09: DECISION TRAIL REPLAY AUDIT — cotygodniowy replay AUTO_POST (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_rt := object.get(_ctx, "replay_audit", {})
_replay_done_rt := object.get(_rt, "weekly_replay_done", false)
_replay_total_rt := object.get(_rt, "decisions_replayed", 0)
_replay_revise := object.get(_rt, "decisions_to_revise", 0)

routing_rt09 = "BLOCK_AND_ALERT" {
    _has_flag("replay_audit_bypassed")
} else = "TRIAGE_QUEUE" {
    not _replay_done_rt
} else = "TRIAGE_QUEUE" {
    _replay_revise > 0
} else = "AUTO_FILE" {
    true
}

replay_audit_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "replay_audit"
    routing_rt09 == "AUTO_FILE"
    cert := _certificate(449009, {
        "rule_id": "jdg.v3_p49_fail_closed.replay_audit",
        "decision_mode": "AUTO_POST",
        "_routing": routing_rt09,
        "_routing_reason": "FAIL-CLOSED: replay tygodnia zielony — zero decyzji wymagających rewizji.",
        "_legal_basis": "P49-I09; P10 Golden Oracle; K05 (snapshoty replay) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "decisions_replayed": _replay_total_rt,
        "decisions_to_revise": _replay_revise,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "replay_audit"
    routing_rt09 == "TRIAGE_QUEUE"
    cert := _certificate(449009, {
        "rule_id": "jdg.v3_p49_fail_closed.replay_audit",
        "decision_mode": "TRIAGE",
        "_routing": routing_rt09,
        "_routing_reason": "FAIL-CLOSED: replay niewykonany lub decyzje do rewizji — lista rewizji wygenerowana.",
        "_legal_basis": "P49-I09; AP06; V2 F3 (złote orzeczenia)",
        "_warnings": ["[V3-P49] Decyzje AUTO_POST, które dziś byłyby NEEDS_ADVICE — rewizja."],
        "weekly_replay_done": _replay_done_rt,
        "decisions_to_revise": _replay_revise,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I10: FAIL-CLOSED SCORE — % ścieżek jawnie fail-closed (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_fcs := object.get(_ctx, "fail_closed_score", {})
_paths_total := object.get(_fcs, "paths_total", 0)
_paths_explicit := object.get(_fcs, "paths_explicit_else", 0)
_paths_fail_open := object.get(_fcs, "paths_fail_open", 0)
_fcs_target := _th("v3_p49_fail_closed_score_target_pct", 100)
_fcs_score := score {
    _paths_total > 0
    score := _paths_explicit * 100 / _paths_total
} else := 0 {
    true
}

routing_fs10 = "BLOCK_AND_ALERT" {
    _has_flag("score_bypassed")
} else = "BLOCK_AND_ALERT" {
    _paths_fail_open > 0
} else = "TRIAGE_QUEUE" {
    _paths_total == 0
} else = "TRIAGE_QUEUE" {
    _fcs_score < _fcs_target
} else = "AUTO_FILE" {
    true
}

fail_closed_score_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "fail_closed_score"
    routing_fs10 == "AUTO_FILE"
    cert := _certificate(449010, {
        "rule_id": "jdg.v3_p49_fail_closed.fail_closed_score",
        "decision_mode": "AUTO_POST",
        "_routing": routing_fs10,
        "_routing_reason": "FAIL-CLOSED: score 100% — wszystkie ścieżki z jawnym else → NEEDS_ADVICE.",
        "_legal_basis": "P49-I10; AP03; metryka → P37 obserwowalność [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "paths_total": _paths_total,
        "paths_explicit_else": _paths_explicit,
        "fail_closed_score_pct": _fcs_score,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "fail_closed_score"
    routing_fs10 == "TRIAGE_QUEUE"
    cert := _certificate(449010, {
        "rule_id": "jdg.v3_p49_fail_closed.fail_closed_score",
        "decision_mode": "TRIAGE",
        "_routing": routing_fs10,
        "_routing_reason": "FAIL-CLOSED: score poniżej celu — ścieżki bez jawnego else do domknięcia.",
        "_legal_basis": "P49-I10; AP03; rejestr fail-open → P45/P68",
        "_warnings": ["[V3-P49] Fail-closed score poniżej 100% — trend w P37."],
        "paths_total": _paths_total,
        "paths_explicit_else": _paths_explicit,
        "paths_fail_open": _paths_fail_open,
        "fail_closed_score_pct": _fcs_score,
        "target_pct": _fcs_target,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "fail_closed_score"
    routing_fs10 == "BLOCK_AND_ALERT"
    cert := _certificate(449010, {
        "rule_id": "jdg.v3_p49_fail_closed.fail_closed_score",
        "decision_mode": "BLOCK",
        "_routing": routing_fs10,
        "_routing_reason": "FAIL-CLOSED: ścieżka fail-open w rejestrze — cicha droga do AUTO_POST.",
        "_legal_basis": "P49-I10; AP07; rejestr fail-open (kontrakt P49 → P45/P68)",
        "_warnings": ["[V3-P49] Fail-open paths > 0 — domknąć rejestr."],
        "paths_fail_open": _paths_fail_open,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I11: SILENT-POST CANARY — syntetyczne inputy z brakami na żywo (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_cnp := object.get(_ctx, "silent_post_canary", {})
_canary_run := object.get(_cnp, "canary_run", false)
_canary_cases := object.get(_cnp, "probes_total", 0)
_canary_violations := object.get(_cnp, "silent_posts_detected", 0)

routing_sc11 = "BLOCK_AND_ALERT" {
    _has_flag("canary_bypassed")
} else = "BLOCK_AND_ALERT" {
    _canary_violations > 0
} else = "TRIAGE_QUEUE" {
    not _canary_run
} else = "TRIAGE_QUEUE" {
    _canary_cases == 0
} else = "AUTO_FILE" {
    true
}

silent_post_canary_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "silent_post_canary"
    routing_sc11 == "AUTO_FILE"
    cert := _certificate(449011, {
        "rule_id": "jdg.v3_p49_fail_closed.silent_post_canary",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sc11,
        "_routing_reason": "FAIL-CLOSED: canary zielony — produkcyjne ścieżki odrzucają inputy z brakami.",
        "_legal_basis": "P49-I11; K10; AP07 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "probes_total": _canary_cases,
        "silent_posts_detected": _canary_violations,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "silent_post_canary"
    routing_sc11 == "TRIAGE_QUEUE"
    cert := _certificate(449011, {
        "rule_id": "jdg.v3_p49_fail_closed.silent_post_canary",
        "decision_mode": "TRIAGE",
        "_routing": routing_sc11,
        "_routing_reason": "FAIL-CLOSED: canary niewykonany — asercja fail-closed na żywo nieudowodniona.",
        "_legal_basis": "P49-I11; AP06; interwał canary z progów (I11)",
        "_warnings": ["[V3-P49] Zaplanuj canary z interwałem z data.thresholds.v3_p49."],
        "canary_run": _canary_run,
        "probes_total": _canary_cases,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "silent_post_canary"
    routing_sc11 == "BLOCK_AND_ALERT"
    cert := _certificate(449011, {
        "rule_id": "jdg.v3_p49_fail_closed.silent_post_canary",
        "decision_mode": "BLOCK",
        "_routing": routing_sc11,
        "_routing_reason": "FAIL-CLOSED: canary wykrył cichy post NA ŻYWO — produkcja fail-open.",
        "_legal_basis": "P49-I11; AP07; KKS art. 56-57 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P49] Canary wykrył cichy post — incydent fail-closed."],
        "silent_posts_detected": _canary_violations,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49-I12: USER-VISIBLE SAFETY — NEEDS_ADVICE z akcją w UI (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_uvs := object.get(_ctx, "user_visible_safety", {})
_na_visible := object.get(_uvs, "needs_advice_visible", 0)
_na_with_action := object.get(_uvs, "needs_advice_with_action", 0)
_ap_downloadable := object.get(_uvs, "auto_post_evidence_downloadable", false)

routing_uv12 = "BLOCK_AND_ALERT" {
    _has_flag("ui_bypassed")
} else = "TRIAGE_QUEUE" {
    _na_visible > 0
    _na_with_action < _na_visible
} else = "TRIAGE_QUEUE" {
    not _ap_downloadable
} else = "AUTO_FILE" {
    true
}

user_visible_safety_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "user_visible_safety"
    routing_uv12 == "AUTO_FILE"
    cert := _certificate(449012, {
        "rule_id": "jdg.v3_p49_fail_closed.user_visible_safety",
        "decision_mode": "AUTO_POST",
        "_routing": routing_uv12,
        "_routing_reason": "FAIL-CLOSED: fail-closed użyteczny — NEEDS_ADVICE z akcją, AUTO_POST z dowodem.",
        "_legal_basis": "P49-I12; P40 decision-first UI; RODO art. 22 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "needs_advice_visible": _na_visible,
        "needs_advice_with_action": _na_with_action,
        "auto_post_evidence_downloadable": _ap_downloadable,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "user_visible_safety"
    routing_uv12 == "TRIAGE_QUEUE"
    cert := _certificate(449012, {
        "rule_id": "jdg.v3_p49_fail_closed.user_visible_safety",
        "decision_mode": "TRIAGE",
        "_routing": routing_uv12,
        "_routing_reason": "FAIL-CLOSED: NEEDS_ADVICE bez akcji w UI / dowód AUTO_POST niedostępny.",
        "_legal_basis": "P49-I12; P40; bezpieczeństwo = użyteczność (prompt P49 5.4)",
        "_warnings": ["[V3-P49] Dodaj akcję 'co muszę uzupełnić' do NEEDS_ADVICE w UI."],
        "needs_advice_visible": _na_visible,
        "needs_advice_with_action": _na_with_action,
        "auto_post_evidence_downloadable": _ap_downloadable,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny, fail-closed)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := invariant_pack_decision {
    invariant_pack_decision.rule_id != ""
} else := default_deny_core_decision {
    default_deny_core_decision.rule_id != ""
} else := missing_field_coverage_decision {
    missing_field_coverage_decision.rule_id != ""
} else := chaos_input_decision {
    chaos_input_decision.rule_id != ""
} else := circuit_breaker_decision {
    circuit_breaker_decision.rule_id != ""
} else := amount_ceiling_decision {
    amount_ceiling_decision.rule_id != ""
} else := reason_completeness_decision {
    reason_completeness_decision.rule_id != ""
} else := emergency_export_decision {
    emergency_export_decision.rule_id != ""
} else := replay_audit_decision {
    replay_audit_decision.rule_id != ""
} else := fail_closed_score_decision {
    fail_closed_score_decision.rule_id != ""
} else := silent_post_canary_decision {
    silent_post_canary_decision.rule_id != ""
} else := user_visible_safety_decision {
    user_visible_safety_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p49_fail_closed.no_match",
    "package": "jdg.v3_p49_fail_closed",
    "priority": 999999,
}
