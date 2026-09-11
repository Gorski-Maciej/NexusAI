# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P47 WERYFIKACJA PODSTAW PRAWNYCH — ZERO FIKCJI, KAŻDY CYTAT
# W ISAP (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa weryfikacji legal basis ENTERPRISE — 12 analiz (I01–I12; minimum
# z promptu P47 Sekcja 10):
#   I01 Legal Basis Census (spis: reguły per akt, OK/NIEZWERYFIKOWANE/PODEJRZANE
#       — jedna metryka zdrowia prawnego; spis przeterminowany = TRIAGE),
#   I02 Citation Linter (kanon cytowań na PR; cytowanie poza kanonem = 0
#       dozwolonych — BLOCK; reguła bez _legal_basis = TRIAGE),
#   I03 ISAP Anchor for Every Act (każdy akt w rejestrze z URL ISAP; akt bez
#       anchora = TRIAGE; brak rejestru = BLOCK),
#   I04 Temporal Act Versions (akty jako WERSJE konsolidacji od–do; akt bez okna
#       = BLOCK — time-travel P05 na wersjach prawa),
#   I05 Auto Re-check Scheduler (kadencja: ACTIVE codziennie, CANDIDATE
#       co tydzień; akt STALE ponad świeżość = SHADOW przegląd),
#   I06 Discrepancy Mediation Workflow (rozbieżność reguła↔ISAP = ticket z SLA;
#       blokuje awans CANDIDATE→ACTIVE; po SLA = BLOCK),
#   I07 Fictional Basis Blocker (podstawa BŁĄD_PODSTAWY_PRAWNEJ → reguła SHADOW
#       + RE-EXAMINE; tryb awaryjny = BLOCK AND ALERT),
#   I08 Completeness Score (% reguł z łańcuchem akt→art→ust→pkt; cel 100% dla
#       ACTIVE; poniżej celu = TRIAGE),
#   I09 ISAP Diff Watch (zmiana treści artykułu → impact analyzer → SHADOW;
#       dryf niezaraportowany = BLOCK; zaraportowany = TRIAGE),
#   I10 Human Verification Stamp (pole zweryfikował-człowiek z datą; weryfikacja
#       AI nie zastępuje 4-eyes prawnych; brak stempla = TRIAGE),
#   I11 Acts Coverage Heatmap (akty z pełnym pokryciem vs pustynie; spina z
#       P51; pustynia z regułami ACTIVE = TRIAGE),
#   I12 Citation Style Guide (konwencja cytowań z przykładami — wejście P41;
#       brak przewodnika = TRIAGE).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p47 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * Fail-closed (V1 zasada 6): brak snapshotu, brak rejestru aktów, akt bez
#     okna temporalnego, fikcyjna podstawa, dryf niezaraportowany = BLOCK —
#     nigdy cicha decyzja na niepewnym prawie.
#   * Honesty: liczniki z narzędzi i bundli (nie deklaracje); 11 964 NO_LKG_REF
#     z legal_basis_v2 rejestrowane uczciwie jako trend, nie ukrywane.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     [NIEZWERYFIKOWANE — ISAP] do czasu stempla 4-eyes (protokół 04).
#   * Aktywacja: input.jdg_entrepreneur.v3_p47_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p47_legal_basis_weryfikacja_enterprise.<reguła>.
#   * Kontrakty: P45 (rejestr mediacji 5 wpisów), P46 (drift tracker, orphan
#     backlog), P34 (linter PR/nightly), P08 (Law Radar), P07 (lifecycle).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p47_legal_basis_weryfikacja_enterprise
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p47_legal_basis_weryfikacja_enterprise

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p47_check", false) == true
_ctx := object.get(input, "v3_p47", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p47_snapshot := data.jdg.thresholds.v3_p47
_acts_map := data.jdg.thresholds.v3_p47_acts

_snapshot_ok = true {
    count(_p47_snapshot) > 0
} else = false {
    true
}

_acts_ok = true {
    count(_acts_map) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p47_snapshot) > 0
    value := object.get(_p47_snapshot, key, null)
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
    "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.thresholds_missing",
    "package": "jdg.v3_p47_legal_basis_weryfikacja_enterprise",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "LEGAL-BASIS V3-P47: brak snapshotu data.jdg.thresholds.v3_p47.",
    "_legal_basis": "ADR-002; V1 zasada 6 (fail-closed); protokół 04 (zero fikcyjnych podstaw)",
    "_warnings": ["[V3-P47] Brak snapshotu progów weryfikacji podstaw — kontrole ZABLOKOWANE."],
}

# ── Fail-closed gdy mapa aktów niedostępna (weryfikacja bez aktów = fikcja) ────
acts_missing_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.acts_missing",
    "package": "jdg.v3_p47_legal_basis_weryfikacja_enterprise",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "LEGAL-BASIS V3-P47: brak mapy aktów data.jdg.thresholds.v3_p47_acts.",
    "_legal_basis": "V3-P47-I03; protokół 04 — weryfikacja wymaga rejestru aktów z anchorami ISAP",
    "_warnings": ["[V3-P47] Mapa aktów niedostępna — weryfikacja podstaw ZABLOKOWANA."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p47_legal_basis_weryfikacja_enterprise",
        "priority": priority,
        "threshold_version": object.get(_p47_snapshot, "v3_p47_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p47_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p47_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I01: LEGAL BASIS CENSUS — spis zdrowia prawnego (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_census := object.get(_ctx, "legal_basis_census", {})
_census_rules_total := object.get(_census, "rules_total", 0)
_census_ok := object.get(_census, "ok", 0)
_census_unverified := object.get(_census, "unverified", 0)
_census_suspect := object.get(_census, "suspect", 0)
_census_age_days := object.get(_census, "census_age_days", 999999)
_census_max_age := _th("v3_p47_census_max_age_days", 30)

routing_lc01 = "TRIAGE_QUEUE" {
    _census_rules_total == 0
} else = "TRIAGE_QUEUE" {
    _census_age_days > _census_max_age
} else = "TRIAGE_QUEUE" {
    _census_suspect > 0
} else = "AUTO_FILE" {
    true
}

legal_basis_census_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "legal_basis_census"
    routing_lc01 == "AUTO_FILE"
    cert := _certificate(447001, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.legal_basis_census",
        "decision_mode": "AUTO_POST",
        "_routing": routing_lc01,
        "_routing_reason": "LEGAL-BASIS: spis prawnie zdrowy — trzy listy OK/NIEZWERYFIKOWANE/PODEJRZANE aktualne.",
        "_legal_basis": "P47-I01; konstytucyjny wymóg promulgacji (ISAP jako publikator) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "rules_total": _census_rules_total,
        "ok": _census_ok,
        "unverified": _census_unverified,
        "suspect": _census_suspect,
        "census_age_days": _census_age_days,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "legal_basis_census"
    routing_lc01 == "TRIAGE_QUEUE"
    cert := _certificate(447001, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.legal_basis_census",
        "decision_mode": "TRIAGE",
        "_routing": routing_lc01,
        "_routing_reason": "LEGAL-BASIS: spis podstaw nieaktualny lub zawiera podejrzane cytowania — zdrowie prawne niepewne.",
        "_legal_basis": "P47-I01; protokół 04; P45 rejestr defektów prawnych",
        "_warnings": ["[V3-P47] Spis legal basis przeterminowany / podejrzane podstawy."],
        "rules_total": _census_rules_total,
        "unverified": _census_unverified,
        "suspect": _census_suspect,
        "census_age_days": _census_age_days,
        "max_age_days": _census_max_age,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I02: CITATION LINTER — kanon cytowań na PR (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_linter := object.get(_ctx, "citation_linter", {})
_lint_errors := object.get(_linter, "errors", 0)
_lint_max := _th("v3_p47_lint_errors_max", 0)
_rules_no_basis := object.get(_linter, "rules_without_legal_basis", 0)

routing_cl02 = "TRIAGE_QUEUE" {
    count(_linter) == 0                     # never-silent: brak raportu lintera ≠ czysto (AP07)
} else = "BLOCK_AND_ALERT" {
    _has_flag("citation_bypassed_lint")
} else = "BLOCK_AND_ALERT" {
    _lint_errors > _lint_max
} else = "TRIAGE_QUEUE" {
    _rules_no_basis > 0
} else = "AUTO_FILE" {
    true
}

citation_linter_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "citation_linter"
    routing_cl02 == "AUTO_FILE"
    cert := _certificate(447002, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.citation_linter",
        "decision_mode": "AUTO_POST",
        "_routing": routing_cl02,
        "_routing_reason": "LEGAL-BASIS: wszystkie cytowania zgodne z kanonem — zero nowych podstaw w złym formacie.",
        "_legal_basis": "P47-I02; kontrakt wyjściowy P47 (kanon cytowań → P41/P36)",
        "_warnings": [],
        "lint_errors": _lint_errors,
        "rules_without_legal_basis": _rules_no_basis,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "citation_linter"
    routing_cl02 == "BLOCK_AND_ALERT"
    cert := _certificate(447002, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.citation_linter",
        "decision_mode": "BLOCK",
        "_routing": routing_cl02,
        "_routing_reason": "LEGAL-BASIS: cytowania poza kanonem na PR — linter prawny blokuje merge.",
        "_legal_basis": "P47-I02; konwencja 11.5 (format identyfikatorów); AP05",
        "_warnings": ["[V3-P47] Błędy formatu cytowań przekroczyły próg (0)."],
        "lint_errors": _lint_errors,
        "lint_errors_max": _lint_max,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "citation_linter"
    routing_cl02 == "TRIAGE_QUEUE"
    cert := _certificate(447002, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.citation_linter",
        "decision_mode": "TRIAGE",
        "_routing": routing_cl02,
        "_routing_reason": "LEGAL-BASIS: reguły bez _legal_basis — pokrycie prawne niekompletne.",
        "_legal_basis": "P47-I02; AP01 (stub udający pokrycie); P45 rejestr defektów",
        "_warnings": ["[V3-P47] Reguły bez _legal_basis wykryte."],
        "rules_without_legal_basis": _rules_no_basis,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I03: ISAP ANCHOR FOR EVERY ACT — każdy akt z URL (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_anchors := object.get(_ctx, "isap_anchors", {})
_acts_total := object.get(_anchors, "acts_total", 0)
_acts_without_anchor := object.get(_anchors, "acts_without_anchor", 0)
_acts_min := _th("v3_p47_min_acts_registry", 1)

routing_ia03 = "BLOCK_AND_ALERT" {
    _has_flag("anchors_bypassed")
} else = "BLOCK_AND_ALERT" {
    not _acts_ok
} else = "TRIAGE_QUEUE" {
    _acts_without_anchor > 0
} else = "TRIAGE_QUEUE" {
    _acts_total < _acts_min
} else = "AUTO_FILE" {
    true
}

isap_anchor_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "isap_anchors"
    routing_ia03 == "AUTO_FILE"
    cert := _certificate(447003, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.isap_anchor",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ia03,
        "_routing_reason": "LEGAL-BASIS: każdy akt w rejestrze ma identyfikator ISAP — klik z raportu prosto do konsolidacji.",
        "_legal_basis": "P47-I03; wymóg promulgacji ISAP [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "acts_total": _acts_total,
        "acts_without_anchor": _acts_without_anchor,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "isap_anchors"
    routing_ia03 == "BLOCK_AND_ALERT"
    cert := _certificate(447003, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.isap_anchor",
        "decision_mode": "BLOCK",
        "_routing": routing_ia03,
        "_routing_reason": "LEGAL-BASIS: brak mapy aktów — weryfikacja bez publikatora byłaby fikcją.",
        "_legal_basis": "P47-I03; protokół 04 (ZAKAZ fikcyjnych podstaw)",
        "_warnings": ["[V3-P47] Rejestr aktów pusty lub ominięty."],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "isap_anchors"
    routing_ia03 == "TRIAGE_QUEUE"
    cert := _certificate(447003, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.isap_anchor",
        "decision_mode": "TRIAGE",
        "_routing": routing_ia03,
        "_routing_reason": "LEGAL-BASIS: akty bez anchora ISAP — cytowania bez klikalnego dowodu.",
        "_legal_basis": "P47-I03; AP05 (podstawy bez Dz.U./art.)",
        "_warnings": ["[V3-P47] Akty bez anchora ISAP w rejestrze."],
        "acts_total": _acts_total,
        "acts_without_anchor": _acts_without_anchor,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I04: TEMPORAL ACT VERSIONS — wersje konsolidacji od–do (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_versions := object.get(_ctx, "act_versions", {})
_versions_total := object.get(_versions, "versions_total", 0)
_versions_without_window := object.get(_versions, "versions_without_window", 0)

routing_tv04 = "BLOCK_AND_ALERT" {
    _has_flag("versions_bypassed_window")
} else = "BLOCK_AND_ALERT" {
    _versions_without_window > 0
} else = "TRIAGE_QUEUE" {
    _versions_total == 0
} else = "AUTO_FILE" {
    true
}

temporal_versions_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "act_versions"
    routing_tv04 == "AUTO_FILE"
    cert := _certificate(447004, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.temporal_act_versions",
        "decision_mode": "AUTO_POST",
        "_routing": routing_tv04,
        "_routing_reason": "LEGAL-BASIS: wszystkie wersje aktów mają okna obowiązywania — time-travel działa na wersjach prawa.",
        "_legal_basis": "P47-I04; Ordynacja art. 24b–24e (prawo właściwe w czasie) [NIEZWERYFIKOWANE — ISAP]; P05",
        "_warnings": [],
        "versions_total": _versions_total,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "act_versions"
    routing_tv04 == "BLOCK_AND_ALERT"
    cert := _certificate(447004, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.temporal_act_versions",
        "decision_mode": "BLOCK",
        "_routing": routing_tv04,
        "_routing_reason": "LEGAL-BASIS: wersja aktu bez okna obowiązywania — time-travel na prawie niemożliwy.",
        "_legal_basis": "P47-I04; P05 temporalność; AP10",
        "_warnings": ["[V3-P47] Wersje aktów bez okna valid_from/valid_to."],
        "versions_without_window": _versions_without_window,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "act_versions"
    routing_tv04 == "TRIAGE_QUEUE"
    cert := _certificate(447004, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.temporal_act_versions",
        "decision_mode": "TRIAGE",
        "_routing": routing_tv04,
        "_routing_reason": "LEGAL-BASIS: rejestr wersji aktów pusty — brak time-travel na wersjach prawa.",
        "_legal_basis": "P47-I04; P05",
        "_warnings": ["[V3-P47] Rejestr wersji aktów pusty."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I05: AUTO RE-CHECK SCHEDULER — kadencja crawlera (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_scheduler := object.get(_ctx, "recheck_scheduler", {})
_stale_acts := object.get(_scheduler, "stale_acts", 0)
_days_since_run := object.get(_scheduler, "days_since_last_run", 999999)
_active_recheck := _th("v3_p47_active_recheck_days", 1)
_stale_limit := _th("v3_p47_freshness_stale_days", 92)

routing_rs05 = "BLOCK_AND_ALERT" {
    _has_flag("scheduler_bypassed")
} else = "BLOCK_AND_ALERT" {
    _days_since_run > _active_recheck
} else = "TRIAGE_QUEUE" {
    _stale_acts > 0
} else = "AUTO_FILE" {
    true
}

recheck_scheduler_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "recheck_scheduler"
    routing_rs05 == "AUTO_FILE"
    cert := _certificate(447005, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.recheck_scheduler",
        "decision_mode": "AUTO_POST",
        "_routing": routing_rs05,
        "_routing_reason": "LEGAL-BASIS: harmonogram re-checku aktów wykonał się w kadencji (ACTIVE codziennie).",
        "_legal_basis": "P47-I05; P34 crawler ISAP; P08 Law Radar",
        "_warnings": [],
        "stale_acts": _stale_acts,
        "days_since_last_run": _days_since_run,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "recheck_scheduler"
    routing_rs05 == "BLOCK_AND_ALERT"
    cert := _certificate(447005, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.recheck_scheduler",
        "decision_mode": "BLOCK",
        "_routing": routing_rs05,
        "_routing_reason": "LEGAL-BASIS: re-check aktów przekroczył kadencję — świeżość prawa niezagwarantowana.",
        "_legal_basis": "P47-I05; P34; AP10",
        "_warnings": ["[V3-P47] Crawler ISAP poza kadencją (ACTIVE = codziennie)."],
        "days_since_last_run": _days_since_run,
        "active_recheck_days": _active_recheck,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "recheck_scheduler"
    routing_rs05 == "TRIAGE_QUEUE"
    cert := _certificate(447005, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.recheck_scheduler",
        "decision_mode": "TRIAGE",
        "_routing": routing_rs05,
        "_routing_reason": "LEGAL-BASIS: akty STALE (ponad okno świeżości) — przegląd SHADOW.",
        "_legal_basis": "P47-I05; P47-I09 (diff watch → SHADOW)",
        "_warnings": ["[V3-P47] Akty przeterminowane w re-checku."],
        "stale_acts": _stale_acts,
        "stale_limit_days": _stale_limit,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I06: DISCREPANCY MEDIATION WORKFLOW — SLA rozbieżności (AN01/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_mediation := object.get(_ctx, "mediation_workflow", {})
_open_disputes := object.get(_mediation, "open_disputes", 0)
_overdue_disputes := object.get(_mediation, "overdue_disputes", 0)
_sla_days := _th("v3_p47_mediation_sla_days", 14)

routing_mw06 = "TRIAGE_QUEUE" {
    count(_mediation) == 0                  # never-silent: brak rejestru mediacji ≠ brak sporów
} else = "BLOCK_AND_ALERT" {
    _has_flag("mediation_bypassed_sla")
} else = "BLOCK_AND_ALERT" {
    _overdue_disputes > 0
} else = "TRIAGE_QUEUE" {
    _open_disputes > 0
} else = "AUTO_FILE" {
    true
}

mediation_workflow_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mediation_workflow"
    routing_mw06 == "AUTO_FILE"
    cert := _certificate(447006, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.mediation_workflow",
        "decision_mode": "AUTO_POST",
        "_routing": routing_mw06,
        "_routing_reason": "LEGAL-BASIS: brak otwartych rozbieżności reguła↔ISAP — mediacje spójne.",
        "_legal_basis": "P47-I06; kontrakt wyjściowy P47 (proces mediacji → P08/P07); P45 rejestr mediacji",
        "_warnings": [],
        "open_disputes": _open_disputes,
        "sla_days": _sla_days,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mediation_workflow"
    routing_mw06 == "BLOCK_AND_ALERT"
    cert := _certificate(447006, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.mediation_workflow",
        "decision_mode": "BLOCK",
        "_routing": routing_mw06,
        "_routing_reason": "LEGAL-BASIS: rozbieżności po SLA — blokada awansu CANDIDATE→ACTIVE; decyzje w toku do przeglądu.",
        "_legal_basis": "P47-I06; P07 lifecycle; fail-closed prawny",
        "_warnings": ["[V3-P47] Rozbieżności reguła↔ISAP po terminie SLA."],
        "overdue_disputes": _overdue_disputes,
        "sla_days": _sla_days,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "mediation_workflow"
    routing_mw06 == "TRIAGE_QUEUE"
    cert := _certificate(447006, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.mediation_workflow",
        "decision_mode": "TRIAGE",
        "_routing": routing_mw06,
        "_routing_reason": "LEGAL-BASIS: otwarte rozbieżności reguła↔ISAP — ticket z SLA, awans wstrzymany.",
        "_legal_basis": "P47-I06; P45→P47 rejestr mediacji",
        "_warnings": ["[V3-P47] Otwarte mediacje reguła↔ISAP."],
        "open_disputes": _open_disputes,
        "sla_days": _sla_days,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I07: FICTIONAL BASIS BLOCKER — tryb awaryjny (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_fiction := object.get(_ctx, "fictional_basis", {})
_fictional_detected := object.get(_fiction, "fictional_detected", 0)
_rules_shadowed := object.get(_fiction, "rules_shadowed", 0)
_reexamine_flagged := object.get(_fiction, "decisions_reexamined", 0)

routing_fb07 = "TRIAGE_QUEUE" {
    count(_fiction) == 0                    # never-silent: brak skanu fikcji ≠ zero fikcji
} else = "AUTO_FILE" {
    _fictional_detected == 0
} else = "BLOCK_AND_ALERT" {
    _has_flag("fiction_blocker_bypassed")
} else = "TRIAGE_QUEUE" {
    _rules_shadowed == 0
} else = "TRIAGE_QUEUE" {
    _reexamine_flagged == 0
} else = "TRIAGE_QUEUE" {
    true
}

fictional_basis_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "fictional_basis"
    routing_fb07 == "AUTO_FILE"
    cert := _certificate(447007, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.fictional_basis_blocker",
        "decision_mode": "AUTO_POST",
        "_routing": routing_fb07,
        "_routing_reason": "LEGAL-BASIS: zero podstaw oznaczonych BŁĄD_PODSTAWY_PRAWNEJ — brak fikcji w regułach.",
        "_legal_basis": "P47-I07; protokół 04; KKS (fikcyjna podstawa = ryzyko czynu zabronionego) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "fictional_detected": _fictional_detected,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "fictional_basis"
    routing_fb07 == "BLOCK_AND_ALERT"
    cert := _certificate(447007, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.fictional_basis_blocker",
        "decision_mode": "BLOCK",
        "_routing": routing_fb07,
        "_routing_reason": "LEGAL-BASIS: fikcyjna podstawa wykryta, a tryb awaryjny ominięty — najgorszy defekt fortecy.",
        "_legal_basis": "P47-I07; protokół 04; P45 rejestr defektów prawnych",
        "_warnings": ["[V3-P47] Fikcyjna podstawa + ominięty blocker."],
        "fictional_detected": _fictional_detected,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "fictional_basis"
    routing_fb07 == "TRIAGE_QUEUE"
    cert := _certificate(447007, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.fictional_basis_blocker",
        "decision_mode": "TRIAGE",
        "_routing": routing_fb07,
        "_routing_reason": "LEGAL-BASIS: podstawa BŁĄD_PODSTAWY_PRAWNEJ → reguła SHADOW + decyzje RE-EXAMINE.",
        "_legal_basis": "P47-I07; P07 lifecycle (SHADOW); protokół 04",
        "_warnings": ["[V3-P47] Fikcyjna podstawa — reguły do SHADOW, decyzje do RE-EXAMINE."],
        "fictional_detected": _fictional_detected,
        "rules_shadowed": _rules_shadowed,
        "decisions_reexamined": _reexamine_flagged,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I08: COMPLETENESS SCORE — % łańcuchów akt→art→ust→pkt (AN01/AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_completeness := object.get(_ctx, "completeness_score", {})
_complete_rules := object.get(_completeness, "complete_chains", 0)
_active_rules := object.get(_completeness, "active_rules", 0)
_min_chain := _th("v3_p47_min_chain_depth", 3)
_target_pct := _th("v3_p47_completeness_target_pct", 100)
_below_min_chain := object.get(_completeness, "chains_below_min_depth", 0)

completeness_pct = 100 {
    _active_rules == 0
    _complete_rules == 0
} else = score {
    _active_rules > 0
    score := (_complete_rules * 100) / _active_rules
} else = 0 {
    true
}

routing_cs08 = "TRIAGE_QUEUE" {
    count(_completeness) == 0               # never-silent: brak pomiaru ≠ cel osiągnięty
} else = "BLOCK_AND_ALERT" {
    _has_flag("completeness_bypassed")
} else = "BLOCK_AND_ALERT" {
    _below_min_chain > 0
} else = "TRIAGE_QUEUE" {
    completeness_pct < _target_pct
} else = "AUTO_FILE" {
    true
}

completeness_score_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "completeness_score"
    routing_cs08 == "AUTO_FILE"
    cert := _certificate(447008, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.completeness_score",
        "decision_mode": "AUTO_POST",
        "_routing": routing_cs08,
        "_routing_reason": "LEGAL-BASIS: łańcuchy prawne kompletne — wskaźnik zdrowia prawnego na celu.",
        "_legal_basis": "P47-I08; P37 metryka; AP05",
        "_warnings": [],
        "completeness_pct": completeness_pct,
        "complete_chains": _complete_rules,
        "active_rules": _active_rules,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "completeness_score"
    routing_cs08 == "BLOCK_AND_ALERT"
    cert := _certificate(447008, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.completeness_score",
        "decision_mode": "BLOCK",
        "_routing": routing_cs08,
        "_routing_reason": "LEGAL-BASIS: łańcuchy poniżej minimalnej głęboki (akt→art→ust) — cytowanie niepełne = niezweryfikowalne.",
        "_legal_basis": "P47-I08; AP05",
        "_warnings": ["[V3-P47] Łańcuchy poniżej minimalnej głębokości."],
        "chains_below_min_depth": _below_min_chain,
        "min_chain_depth": _min_chain,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "completeness_score"
    routing_cs08 == "TRIAGE_QUEUE"
    cert := _certificate(447008, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.completeness_score",
        "decision_mode": "TRIAGE",
        "_routing": routing_cs08,
        "_routing_reason": "LEGAL-BASIS: kompletność łańcuchów poniżej celu — trend do P37.",
        "_legal_basis": "P47-I08; P37",
        "_warnings": ["[V3-P47] Kompletność poniżej celu."],
        "completeness_pct": completeness_pct,
        "target_pct": _target_pct,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I09: ISAP DIFF WATCH — zmiana treści artykułu → SHADOW (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_diffwatch := object.get(_ctx, "isap_diff_watch", {})
_unreported_diffs := object.get(_diffwatch, "unreported_diffs", 0)
_reported_diffs := object.get(_diffwatch, "reported_diffs", 0)
_rules_shadowed_diff := object.get(_diffwatch, "rules_shadowed", 0)

routing_dw09 = "TRIAGE_QUEUE" {
    count(_diffwatch) == 0                  # never-silent: brak monitoringu ≠ brak dryfu
} else = "BLOCK_AND_ALERT" {
    _has_flag("diff_watch_bypassed")
} else = "BLOCK_AND_ALERT" {
    _unreported_diffs > 0
} else = "TRIAGE_QUEUE" {
    _reported_diffs > 0
    _rules_shadowed_diff == 0
} else = "AUTO_FILE" {
    true
}

isap_diff_watch_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "isap_diff_watch"
    routing_dw09 == "AUTO_FILE"
    cert := _certificate(447009, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.isap_diff_watch",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dw09,
        "_routing_reason": "LEGAL-BASIS: zero niezaraportowanych zmian konsolidacji — dryf prawo↔kod wytropiony.",
        "_legal_basis": "P47-I09; P46-I09 drift tracker; P08 Law Radar; AP11",
        "_warnings": [],
        "unreported_diffs": _unreported_diffs,
        "reported_diffs": _reported_diffs,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "isap_diff_watch"
    routing_dw09 == "BLOCK_AND_ALERT"
    cert := _certificate(447009, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.isap_diff_watch",
        "decision_mode": "BLOCK",
        "_routing": routing_dw09,
        "_routing_reason": "LEGAL-BASIS: zmiana treści artykułu niezaraportowana — reguły na nieaktualnym prawie.",
        "_legal_basis": "P47-I09; P46 drift tracker (kontrakt → P47)",
        "_warnings": ["[V3-P47] Niezaraportowane diffy konsolidacji."],
        "unreported_diffs": _unreported_diffs,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "isap_diff_watch"
    routing_dw09 == "TRIAGE_QUEUE"
    cert := _certificate(447009, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.isap_diff_watch",
        "decision_mode": "TRIAGE",
        "_routing": routing_dw09,
        "_routing_reason": "LEGAL-BASIS: zmiana zaraportowana, ale reguły dotknięte nie trafiły do SHADOW.",
        "_legal_basis": "P47-I09; P07 lifecycle",
        "_warnings": ["[V3-P47] Dotknięte reguły bez automatycznego SHADOW."],
        "reported_diffs": _reported_diffs,
        "rules_shadowed": _rules_shadowed_diff,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I10: HUMAN VERIFICATION STAMP — 4-eyes prawne (AN01/AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_stamp := object.get(_ctx, "human_verification_stamp", {})
_acts_verified_human := object.get(_stamp, "acts_verified_by_human", 0)
_acts_total_stamp := object.get(_stamp, "acts_total", 0)
_stamp_bypassed := _has_flag("stamp_bypassed")

routing_hs10 = "BLOCK_AND_ALERT" {
    _stamp_bypassed
} else = "TRIAGE_QUEUE" {
    _acts_total_stamp == 0
} else = "TRIAGE_QUEUE" {
    _acts_verified_human < _acts_total_stamp
} else = "AUTO_FILE" {
    true
}

human_stamp_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "human_verification_stamp"
    routing_hs10 == "AUTO_FILE"
    cert := _certificate(447010, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.human_verification_stamp",
        "decision_mode": "AUTO_POST",
        "_routing": routing_hs10,
        "_routing_reason": "LEGAL-BASIS: każdy akt weryfikowany przez człowieka (4-eyes) z datą stempla.",
        "_legal_basis": "P47-I10; AI Act — identyfikowalność źródeł [NIEZWERYFIKOWANE — ISAP]; 4-eyes",
        "_warnings": [],
        "acts_verified_by_human": _acts_verified_human,
        "acts_total": _acts_total_stamp,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "human_verification_stamp"
    routing_hs10 == "BLOCK_AND_ALERT"
    cert := _certificate(447010, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.human_verification_stamp",
        "decision_mode": "BLOCK",
        "_routing": routing_hs10,
        "_routing_reason": "LEGAL-BASIS: ominięcie stempla weryfikacji human — AI nie zastępuje 4-eyes prawnych.",
        "_legal_basis": "P47-I10; wymóg nadrzędny (Enterprise); protokół 04",
        "_warnings": ["[V3-P47] Stempel weryfikacji człowieka ominięty."],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "human_verification_stamp"
    routing_hs10 == "TRIAGE_QUEUE"
    cert := _certificate(447010, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.human_verification_stamp",
        "decision_mode": "TRIAGE",
        "_routing": routing_hs10,
        "_routing_reason": "LEGAL-BASIS: akty bez stempla weryfikacji człowieka — status PENDING_4_EYES.",
        "_legal_basis": "P47-I10; LEGAL_SOURCE_REGISTRY review_state",
        "_warnings": ["[V3-P47] Akty bez weryfikacji 4-eyes."],
        "acts_verified_by_human": _acts_verified_human,
        "acts_total": _acts_total_stamp,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I11: ACTS COVERAGE HEATMAP — pokrycie aktów regułami (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_heatmap := object.get(_ctx, "acts_heatmap", {})
_covered_acts := object.get(_heatmap, "covered_acts", 0)
_desert_acts := object.get(_heatmap, "desert_acts", 0)
_desert_with_active := object.get(_heatmap, "desert_acts_with_active_rules", 0)

routing_ah11 = "TRIAGE_QUEUE" {
    count(_heatmap) == 0                    # never-silent: brak mapy ≠ brak pustyni
} else = "BLOCK_AND_ALERT" {
    _has_flag("heatmap_bypassed")
} else = "TRIAGE_QUEUE" {
    _desert_with_active > 0
} else = "TRIAGE_QUEUE" {
    _desert_acts > 0
} else = "AUTO_FILE" {
    true
}

acts_heatmap_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "acts_heatmap"
    routing_ah11 == "AUTO_FILE"
    cert := _certificate(447011, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.acts_heatmap",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ah11,
        "_routing_reason": "LEGAL-BASIS: mapa cieplna pokrycia aktów bez pustyni z regułami ACTIVE.",
        "_legal_basis": "P47-I11; P51 pustynie prawne; K12",
        "_warnings": [],
        "covered_acts": _covered_acts,
        "desert_acts": _desert_acts,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "acts_heatmap"
    routing_ah11 == "BLOCK_AND_ALERT"
    cert := _certificate(447011, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.acts_heatmap",
        "decision_mode": "BLOCK",
        "_routing": routing_ah11,
        "_routing_reason": "LEGAL-BASIS: mapa cieplna ominięta — pokrycie prawne niemierzalne.",
        "_legal_basis": "P47-I11; K12",
        "_warnings": ["[V3-P47] Mapa pokrycia aktów ominięta."],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "acts_heatmap"
    routing_ah11 == "TRIAGE_QUEUE"
    cert := _certificate(447011, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.acts_heatmap",
        "decision_mode": "TRIAGE",
        "_routing": routing_ah11,
        "_routing_reason": "LEGAL-BASIS: pustynie prawne — akty bez pełnego pokrycia regułami (spina z P51).",
        "_legal_basis": "P47-I11; P51; coverage gaps (20 UNCOVERED punktów)",
        "_warnings": ["[V3-P47] Pustynie prawne w mapie pokrycia."],
        "desert_acts": _desert_acts,
        "desert_acts_with_active_rules": _desert_with_active,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47-I12: CITATION STYLE GUIDE — konwencja cytowań (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_guide := object.get(_ctx, "style_guide", {})
_guide_present := object.get(_guide, "guide_present", false)
_guide_examples_ok := object.get(_guide, "examples_valid", 0)
_guide_examples_bad := object.get(_guide, "examples_invalid", 0)

routing_sg12 = "BLOCK_AND_ALERT" {
    _has_flag("guide_bypassed")
} else = "TRIAGE_QUEUE" {
    not _guide_present
} else = "TRIAGE_QUEUE" {
    _guide_examples_bad > 0
} else = "AUTO_FILE" {
    true
}

style_guide_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "style_guide"
    routing_sg12 == "AUTO_FILE"
    cert := _certificate(447012, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.citation_style_guide",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sg12,
        "_routing_reason": "LEGAL-BASIS: przewodnik cytowań z przykładami poprawnymi/niepoprawnymi — część dokumentacji P41.",
        "_legal_basis": "P47-I12; kontrakt wyjściowy P47 (kanon cytowań → P41/P36)",
        "_warnings": [],
        "examples_valid": _guide_examples_ok,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "style_guide"
    routing_sg12 == "BLOCK_AND_ALERT"
    cert := _certificate(447012, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.citation_style_guide",
        "decision_mode": "BLOCK",
        "_routing": routing_sg12,
        "_routing_reason": "LEGAL-BASIS: przewodnik ominięty — linter bez zdefiniowanego kanonu byłby arbitralny.",
        "_legal_basis": "P47-I12; P47-I02 zależność",
        "_warnings": ["[V3-P47] Przewodnik cytowań ominięty."],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "style_guide"
    routing_sg12 == "TRIAGE_QUEUE"
    cert := _certificate(447012, {
        "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.citation_style_guide",
        "decision_mode": "TRIAGE",
        "_routing": routing_sg12,
        "_routing_reason": "LEGAL-BASIS: przewodnik cytowań nieobecny lub przykłady niezgodne z kanonem.",
        "_legal_basis": "P47-I12; P41",
        "_warnings": ["[V3-P47] Przewodnik cytowań niekompletny."],
        "guide_present": _guide_present,
        "examples_invalid": _guide_examples_bad,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := acts_missing_decision {
    not _acts_ok
} else := legal_basis_census_decision {
    legal_basis_census_decision.rule_id != ""
} else := citation_linter_decision {
    citation_linter_decision.rule_id != ""
} else := isap_anchor_decision {
    isap_anchor_decision.rule_id != ""
} else := temporal_versions_decision {
    temporal_versions_decision.rule_id != ""
} else := recheck_scheduler_decision {
    recheck_scheduler_decision.rule_id != ""
} else := mediation_workflow_decision {
    mediation_workflow_decision.rule_id != ""
} else := fictional_basis_decision {
    fictional_basis_decision.rule_id != ""
} else := completeness_score_decision {
    completeness_score_decision.rule_id != ""
} else := isap_diff_watch_decision {
    isap_diff_watch_decision.rule_id != ""
} else := human_stamp_decision {
    human_stamp_decision.rule_id != ""
} else := acts_heatmap_decision {
    acts_heatmap_decision.rule_id != ""
} else := style_guide_decision {
    style_guide_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p47_legal_basis_weryfikacja_enterprise.no_match",
    "package": "jdg.v3_p47_legal_basis_weryfikacja_enterprise",
    "priority": 999999,
}
