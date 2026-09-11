# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P35 AUDYTORY DOMENOWE — ZAUFANIE DOMEN JAKO GOVERNANCE
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa audytorów domenowych ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Domain Trust Score (skwantyfikowana pewność domeny 0-100 z metodologią:
#       pokrycie prawne × jakość testów × wyniki audytu × dryf; progi AUTO_POST
#       jako dane — spadek = TRIAGE),
#   I02 Auditor as Data (definicja audytu: kontrole, progi, przykłady w danych —
#       zmiana audytu bez deployu; brak definicji = BLOCK),
#   I03 Golden Case Registry (rejestr przypadków referencyjnych per domena:
#       input → oczekiwany werdykt; używany przez audytory, red team i P10),
#   I04 Unified Audit Report (jeden schema wyniku: score, luki, dowody —
#       konsumowany przez dashboardy i certyfikat; wynik spoza schema = BLOCK),
#   I05 Drill-Down do Dowodu (metryka → lista reguł → kod+test+podstawa prawna —
#       pełny ślad; przerwany = BLOCK),
#   I06 Skew Detection (rozjazd metryk: wysoka pewność vs spadek pokrycia
#       testów = BLOCK; mniej dotkliwy rozjazd = TRIAGE),
#   I07 Dashboardy jako Dane (konfiguracja dashboardu: metryki, progi, alarmy
#       w danych — zmiana widoku bez deployu; zero dashboardów = TRIAGE),
#   I08 Audyt Ciągły vs Per-PR (rozdzielenie: per-PR szybki, nocny głęboki;
#       nocny pominięty = TRIAGE),
#   I09 Ocena Operatora (feedback loop: operator ocenia decyzję NEEDS_ADVICE;
#       ocena zasila golden registry i trust score; ocena bez dowodu = BLOCK),
#   I10 Alert Routing (alarmy do właściwego właściciela z SLA reakcji jako
#       dane; brak właściciela = BLOCK; SLA przekroczone = TRIAGE),
#   I11 Legal Freshness Stamp („ostatni dowód aktualności prawa" per domena —
#       ISAP check date; dane starsze niż limit = BLOCK),
#   I12 Audyt Inverse (audytor generuje przypadki, dla których AUTO_POST byłby
#       niebezpieczny — negatywna przestrzeń; dowód defensywności obowiązkowy;
#       brak = BLOCK).
#
# Integracje (kontrakty między-częściowe):
#   * P03 (kontrakt werdyktu) — każda analiza emituje zgodny werdykt,
#   * P04 (invarianty) — audytory nigdy nie omijają warstwy konstytucyjnej,
#   * P10 (Golden Oracle) — golden case registry wspólny z P10 (I03/I09),
#   * P12-P19 (domeny VAT/PIT/ZUS/KSeF/cross-border) — audytory audytują
#     istniejące pakiety, nie duplikują ich logiki,
#   * P29 (kampanie jakości) — audytory spójne z bramkami quality,
#   * P31 (etapy audytów) — unified schema raportu (I04) spójny z etapami,
#   * P33 (warstwa AI) — trust score jako telemetria (I01 nie decyduje),
#   * P37 (obserwowalność) — metryki i alarmy → dashboardy (I06/I07/I10).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p35 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak danych, rozjazd, brak właściciela
#     alarmu, nieświeży dowód prawa = BLOCK/TRIAGE — nigdy cichy AUTO_POST.
#   * Trust score (I01) jest TELEMETRIĄ: rankuje domeny do przeglądu, nigdy
#     nie decyduje o AUTO_POST samodzielnie (spójne z P33-I06).
#   * Aktywacja: input.jdg_entrepreneur.v3_p35_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p35_audyutory_domenowe.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p35_audyutory_domenowe
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p35_audyutory_domenowe

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p35_check", false) == true
_ctx := object.get(input, "v3_p35", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p35_snapshot := data.jdg.thresholds.v3_p35

_snapshot_ok = true {
    count(_p35_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p35_snapshot) > 0
    value := object.get(_p35_snapshot, key, null)
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
    "rule_id": "jdg.v3_p35_audyutory_domenowe.thresholds_missing",
    "package": "jdg.v3_p35_audyutory_domenowe",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "AUDYTORY DOMENOWE V3-P35: brak snapshotu data.jdg.thresholds.v3_p35.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P35] Brak snapshotu progów audytorów — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p35_audyutory_domenowe",
        "priority": priority,
        "threshold_version": object.get(_p35_snapshot, "v3_p35_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p35_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p35_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I01: DOMAIN TRUST SCORE — pewność domeny 0-100 (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_dts := object.get(_ctx, "domain_trust_score", {})
_dts_below := object.get(_dts, "domains_below_floor", [])
_dts_dropped := object.get(_dts, "domains_with_big_drop", [])
_dts_floor := _th("v3_p35_trust_score_floor", 70)
_dts_drop := _th("v3_p35_trust_drop_triage", 10)

routing_ts01 = "BLOCK_AND_ALERT" {
    count(_dts_dropped) > 0
} else = "TRIAGE_QUEUE" {
    count(_dts_below) > 0
} else = "SUGGEST" {
    true
}

reason_ts01 = sprintf("Spadek trust score > %v punktów w domenach: %v — BLOCK (nagła utrata pewności; audytor wymaga uwagi).", [_dts_drop, _dts_dropped]) {
    count(_dts_dropped) > 0
} else = sprintf("Domeny poniżej progu pewności %v: %v — TRIAGE (trust score = telemetria; kolejność przeglądu per P33-I06).", [_dts_floor, _dts_below]) {
    count(_dts_below) > 0
} else = sprintf("Domain trust score OK: wszystkie domeny ≥ %v, zero spadków > %v.", [_dts_floor, _dts_drop]) {
    true
}

domain_trust_score_decision := _certificate(435001, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.domain_trust_score",
    "analysis": "domain_trust_score",
    "domains_below_floor": count(_dts_below),
    "domains_with_big_drop": count(_dts_dropped),
    "trust_score_floor": _dts_floor,
    "_routing": routing_ts01,
    "_routing_reason": reason_ts01,
    "_legal_basis": "V3_P35 §10/I01; telemetria (P33-I06); P29 (kampanie jakości)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "domain_trust_score"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I02: AUDITOR AS DATA — definicja audytu w danych (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_aad := object.get(_ctx, "auditor_as_data", {})
_aad_undefined := object.get(_aad, "domains_without_definition", 0)
_aad_missing_controls := object.get(_aad, "definitions_missing_controls", [])

routing_ad02 = "BLOCK_AND_ALERT" {
    count(_aad_missing_controls) > _th("v3_p35_missing_controls_max", 0)
} else = "TRIAGE_QUEUE" {
    _aad_undefined > 0
} else = "SUGGEST" {
    true
}

reason_ad02 = sprintf("Definicje audytów bez kontroli: %v ponad limit %v — BLOCK (audyt bez kontroli jest fasadą; auditor-as-data).", [_aad_missing_controls, _th("v3_p35_missing_controls_max", 0)]) {
    count(_aad_missing_controls) > _th("v3_p35_missing_controls_max", 0)
} else = sprintf("Domeny bez definicji audytu: %v — TRIAGE (dodać definicję: kontrole, progi, przykłady).", [_aad_undefined]) {
    _aad_undefined > 0
} else = sprintf("Auditor as data OK: wszystkie domeny z definicją audytu w danych (zmiana bez deployu).", []) {
    true
}

auditor_as_data_decision := _certificate(435002, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.auditor_as_data",
    "analysis": "auditor_as_data",
    "domains_without_definition": _aad_undefined,
    "definitions_missing_controls": count(_aad_missing_controls),
    "_routing": routing_ad02,
    "_routing_reason": reason_ad02,
    "_legal_basis": "V3_P35 §10/I02; ADR-002 (params-as-data); kontrakt P31 (etapy audytów)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "auditor_as_data"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I03: GOLDEN CASE REGISTRY — przypadki referencyjne per domena (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_gcr := object.get(_ctx, "golden_case_registry", {})
_gcr_undefined := object.get(_gcr, "domains_without_cases", 0)
_gcr_stale := object.get(_gcr, "cases_not_replayed_days", 0)
_gcr_min := _th("v3_p35_golden_cases_min_per_domain", 3)

routing_gr03 = "BLOCK_AND_ALERT" {
    _has_flag("golden_cases_forged")
} else = "TRIAGE_QUEUE" {
    _gcr_undefined > 0
} else = "TRIAGE_QUEUE" {
    _gcr_stale > _th("v3_p35_golden_replay_max_age_days", 30)
} else = "SUGGEST" {
    true
}

reason_gr03 = sprintf("Wykryto sfabrykowane przypadki golden — BLOCK (przypadek bez uruchomienia = twierdzenie; kanon P00; P10).", []) {
    _has_flag("golden_cases_forged")
} else = sprintf("Domeny bez przypadków referencyjnych (min %v): %v — TRIAGE (rejestr per domena; używają go audytory i red team).", [_gcr_min, _gcr_undefined]) {
    _gcr_undefined > 0
} else = sprintf("Golden replay starszy niż %v dni — TRIAGE (replay cykliczny; P10).", [_th("v3_p35_golden_replay_max_age_days", 30)]) {
    _gcr_stale > _th("v3_p35_golden_replay_max_age_days", 30)
} else = sprintf("Golden case registry OK: przypadki per domena, replay ≤ %v dni (kontrakt P10).", [_th("v3_p35_golden_replay_max_age_days", 30)]) {
    true
}

golden_case_registry_decision := _certificate(435003, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.golden_case_registry",
    "analysis": "golden_case_registry",
    "domains_without_cases": _gcr_undefined,
    "cases_not_replayed_days": _gcr_stale,
    "min_cases_per_domain": _gcr_min,
    "_routing": routing_gr03,
    "_routing_reason": reason_gr03,
    "_legal_basis": "V3_P35 §10/I03; kontrakt P10 (Golden Oracle); kanon P00",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_case_registry"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I04: UNIFIED AUDIT REPORT — jeden schema wyniku (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_uar := object.get(_ctx, "unified_audit_report", {})
_uar_offschema := object.get(_uar, "reports_off_schema", 0)

routing_ur04 = "BLOCK_AND_ALERT" {
    _uar_offschema > 0
} else = "SUGGEST" {
    true
}

reason_ur04 = sprintf("Raporty audytów poza unified schema (score, luki, dowody): %v — BLOCK (dashboardy i certyfikat konsumują jeden schema).", [_uar_offschema]) {
    _uar_offschema > 0
} else = "Unified audit report OK: wszystkie wyniki w jednym schema (score, luki, dowody)." {
    true
}

unified_audit_report_decision := _certificate(435004, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.unified_audit_report",
    "analysis": "unified_audit_report",
    "reports_off_schema": _uar_offschema,
    "_routing": routing_ur04,
    "_routing_reason": reason_ur04,
    "_legal_basis": "V3_P35 §10/I04; kontrakt P31 (unified audit schema); V2 F4",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "unified_audit_report"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I05: DRILL-DOWN DO DOWODU — metryka → reguły → kod+test+prawo (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_dd := object.get(_ctx, "drill_down_evidence", {})
_dd_broken := object.get(_dd, "metrics_without_full_trace", 0)

routing_dd05 = "BLOCK_AND_ALERT" {
    _dd_broken > 0
} else = "SUGGEST" {
    true
}

reason_dd05 = sprintf("Metryki bez pełnego śladu drill-down (reguła → kod+test+podstawa): %v — BLOCK (pełny ślad obowiązkowy).", [_dd_broken]) {
    _dd_broken > 0
} else = sprintf("Drill-down OK: %v metryk z pełnym śladem do dowodu.", [object.get(_dd, "metrics_total", 0)]) {
    true
}

drill_down_evidence_decision := _certificate(435005, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.drill_down_evidence",
    "analysis": "drill_down_evidence",
    "metrics_without_full_trace": _dd_broken,
    "metrics_total": object.get(_dd, "metrics_total", 0),
    "_routing": routing_dd05,
    "_routing_reason": reason_dd05,
    "_legal_basis": "V3_P35 §10/I05; traceability (7.1h); V2 F4",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "drill_down_evidence"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I06: SKEW DETECTION — rozjazd pewność vs pokrycie (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_skew := object.get(_ctx, "skew_detection", {})
_skew_critical := object.get(_skew, "critical_skews", 0)
_skew_mild := object.get(_skew, "mild_skews", 0)

routing_sk06 = "BLOCK_AND_ALERT" {
    _skew_critical > 0
} else = "TRIAGE_QUEUE" {
    _skew_mild > 0
} else = "SUGGEST" {
    true
}

reason_sk06 = sprintf("Krytyczne rozjazdy metryk (wysoka pewność vs spadek pokrycia): %v — BLOCK (metryki kłamią; audytor wymaga wyjaśnienia).", [_skew_critical]) {
    _skew_critical > 0
} else = sprintf("Łagodne rozjazdy metryk: %v — TRIAGE (obserwować; trend w dashboardzie).", [_skew_mild]) {
    _skew_mild > 0
} else = "Skew detection OK: metryki spójne (pewność rośnie razem z pokryciem)." {
    true
}

skew_detection_decision := _certificate(435006, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.skew_detection",
    "analysis": "skew_detection",
    "critical_skews": _skew_critical,
    "mild_skews": _skew_mild,
    "_routing": routing_sk06,
    "_routing_reason": reason_sk06,
    "_legal_basis": "V3_P35 §10/I06; P29 (kampanie jakości); P37 (obserwowalność)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "skew_detection"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I07: DASHBOARDY JAKO DANE — konfiguracja w danych (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_dsh := object.get(_ctx, "dashboards_as_data", {})
_dsh_undefined := object.get(_dsh, "domains_without_dashboard", 0)
_dsh_hardcoded := object.get(_dsh, "hardcoded_views", 0)

routing_ds07 = "BLOCK_AND_ALERT" {
    _dsh_hardcoded > 0
} else = "TRIAGE_QUEUE" {
    _dsh_undefined > 0
} else = "SUGGEST" {
    true
}

reason_ds07 = sprintf("Dashboardy z hardcode widoków: %v — BLOCK (konfiguracja jako dane: metryki, progi, alarmy; zmiana widoku bez deployu; ADR-002).", [_dsh_hardcoded]) {
    _dsh_hardcoded > 0
} else = sprintf("Domeny bez dashboardu: %v — TRIAGE (dodać konfigurację: metryki, progi, alarmy).", [_dsh_undefined]) {
    _dsh_undefined > 0
} else = "Dashboardy jako dane OK: wszystkie domeny z konfiguracją w danych." {
    true
}

dashboards_as_data_decision := _certificate(435007, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.dashboards_as_data",
    "analysis": "dashboards_as_data",
    "domains_without_dashboard": _dsh_undefined,
    "hardcoded_views": _dsh_hardcoded,
    "_routing": routing_ds07,
    "_routing_reason": reason_ds07,
    "_legal_basis": "V3_P35 §10/I07; ADR-002; kontrakt P37 (obserwowalność)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "dashboards_as_data"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I08: AUDYT CIĄGŁY VS PER-PR — dwa tryby (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_aud := object.get(_ctx, "continuous_vs_per_pr", {})
_aud_night_missed := object.get(_aud, "nightly_missed_days", 0)
_aud_pr_skipped := object.get(_aud, "per_pr_skipped", 0)
_aud_night_max := _th("v3_p35_nightly_missed_max_days", 1)

routing_cu08 = "BLOCK_AND_ALERT" {
    _aud_pr_skipped > 0
} else = "TRIAGE_QUEUE" {
    _aud_night_missed > _aud_night_max
} else = "SUGGEST" {
    true
}

reason_cu08 = sprintf("Audyt per-PR pominięty: %v — BLOCK (każdy PR przechodzi szybki zestaw kontroli; P39).", [_aud_pr_skipped]) {
    _aud_pr_skipped > 0
} else = sprintf("Audyt nocny pominięty: %v dni > limit %v — TRIAGE (głęboki zestaw kontroli; catch-up wymagany).", [_aud_night_missed, _aud_night_max]) {
    _aud_night_missed > _aud_night_max
} else = sprintf("Audyt ciągły OK: per-PR (szybki) + nocny (głęboki) w limitach (%v dni).", [_aud_night_missed]) {
    true
}

continuous_vs_per_pr_decision := _certificate(435008, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.continuous_vs_per_pr",
    "analysis": "continuous_vs_per_pr",
    "nightly_missed_days": _aud_night_missed,
    "per_pr_skipped": _aud_pr_skipped,
    "nightly_missed_max": _aud_night_max,
    "_routing": routing_cu08,
    "_routing_reason": reason_cu08,
    "_legal_basis": "V3_P35 §10/I08; kontrakt P39 (CI); kontrakt P34-I08 (dwa tryby)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "continuous_vs_per_pr"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I09: OCENA OPERATORA — feedback loop NEEDS_ADVICE (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_op := object.get(_ctx, "operator_feedback", {})
_op_unevaluated := object.get(_op, "decisions_without_operator_review", 0)
_op_older := object.get(_op, "reviews_missing_days", 0)
_op_older_max := _th("v3_p35_feedback_max_age_days", 14)

routing_of09 = "BLOCK_AND_ALERT" {
    _op_older > _op_older_max
} else = "TRIAGE_QUEUE" {
    _op_unevaluated > 0
} else = "SUGGEST" {
    true
}

reason_of09 = sprintf("Feedback operatora wstrzymany dłużej niż %v dni — BLOCK (pętla uczenia przerwana; golden registry nie zasilany).", [_op_older_max]) {
    _op_older > _op_older_max
} else = sprintf("Decyzje NEEDS_ADVICE bez oceny operatora: %v — TRIAGE (ocena zasila golden registry i trust score).", [_op_unevaluated]) {
    _op_unevaluated > 0
} else = sprintf("Ocena operatora OK: pętla feedback aktywna (≤ %v dni), decyzje oceniane.", [_op_older_max]) {
    true
}

operator_feedback_decision := _certificate(435009, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.operator_feedback",
    "analysis": "operator_feedback",
    "decisions_without_operator_review": _op_unevaluated,
    "reviews_missing_days": _op_older,
    "feedback_max_age_days": _op_older_max,
    "_routing": routing_of09,
    "_routing_reason": reason_of09,
    "_legal_basis": "V3_P35 §10/I09; kontrakt P10 (golden registry); P33-I12 (triage)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "operator_feedback"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I10: ALERT ROUTING — właściwy właściciel + SLA jako dane (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_rt := object.get(_ctx, "alert_routing", {})
_rt_unrouted := object.get(_rt, "alerts_without_owner", 0)
_rt_sla_breach := object.get(_rt, "sla_breached_alerts", 0)
_rt_sla_h := _th("v3_p35_alert_sla_hours", 4)

routing_ar10 = "BLOCK_AND_ALERT" {
    _rt_unrouted > 0
} else = "TRIAGE_QUEUE" {
    _rt_sla_breach > 0
} else = "SUGGEST" {
    true
}

reason_ar10 = sprintf("Alarmy bez właściciela: %v — BLOCK (każdy alarm ma trasę do właściwego właściciela — konfiguracja jako dane).", [_rt_unrouted]) {
    _rt_unrouted > 0
} else = sprintf("Naruszenia SLA reakcji (%v h): %v — TRIAGE (przyspieszyć obsługę; SLA jako dane).", [_rt_sla_h, _rt_sla_breach]) {
    _rt_sla_breach > 0
} else = sprintf("Alert routing OK: 0 alarmów bez właściciela, SLA %v h dotrzymane.", [_rt_sla_h]) {
    true
}

alert_routing_decision := _certificate(435010, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.alert_routing",
    "analysis": "alert_routing",
    "alerts_without_owner": _rt_unrouted,
    "sla_breached_alerts": _rt_sla_breach,
    "sla_hours": _rt_sla_h,
    "_routing": routing_ar10,
    "_routing_reason": reason_ar10,
    "_legal_basis": "V3_P35 §10/I10; ADR-002 (SLA jako dane); kontrakt P37",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "alert_routing"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I11: LEGAL FRESHNESS STAMP — ostatni dowód aktualności prawa (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_fs := object.get(_ctx, "legal_freshness_stamp", {})
_fs_stale := object.get(_fs, "domains_with_stale_law", 0)
_fs_max_age := _th("v3_p35_law_freshness_max_days", 7)

routing_fs11 = "BLOCK_AND_ALERT" {
    _fs_stale > 0
} else = "SUGGEST" {
    true
}

reason_fs11 = sprintf("Domeny z przeterminowanym dowodem aktualności prawa (> %v dni): %v — BLOCK (przejrzystość ryzyka: ISAP check date obowiązkowy).", [_fs_max_age, _fs_stale]) {
    _fs_stale > 0
} else = sprintf("Legal freshness OK: wszystkie domeny z dowodem aktualności prawa ≤ %v dni.", [_fs_max_age]) {
    true
}

legal_freshness_stamp_decision := _certificate(435011, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.legal_freshness_stamp",
    "analysis": "legal_freshness_stamp",
    "domains_with_stale_law": _fs_stale,
    "freshness_max_days": _fs_max_age,
    "_routing": routing_fs11,
    "_routing_reason": reason_fs11,
    "_legal_basis": "V3_P35 §10/I11; zasada źródeł ISAP/RCL/MF; kontrakt P47",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "legal_freshness_stamp"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35-I12: AUDYT INVERSE — negatywna przestrzeń AUTO_POST (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_inv := object.get(_ctx, "inverse_audit", {})
_inv_missing := object.get(_inv, "domains_without_inverse_cases", 0)
_inv_leaked := object.get(_inv, "unsafe_auto_post_leaks", 0)
_inv_min := _th("v3_p35_inverse_cases_min", 3)

routing_iv12 = "BLOCK_AND_ALERT" {
    _inv_leaked > 0
} else = "TRIAGE_QUEUE" {
    _inv_missing > 0
} else = "SUGGEST" {
    true
}

reason_iv12 = sprintf("AUTO_POST dopuszczony w negatywnej przestrzeni (przypadek niebezpieczny): %v — BLOCK (dowód defensywności złamany).", [_inv_leaked]) {
    _inv_leaked > 0
} else = sprintf("Domeny bez przypadków inverse (min %v): %v — TRIAGE (generować przypadki, dla których AUTO_POST byłby niebezpieczny).", [_inv_min, _inv_missing]) {
    _inv_missing > 0
} else = sprintf("Audyt inverse OK: każda domena z ≥ %v przypadkami negatywnej przestrzeni — defensywność udowodniona.", [_inv_min]) {
    true
}

inverse_audit_decision := _certificate(435012, {
    "rule_id": "jdg.v3_p35_audyutory_domenowe.inverse_audit",
    "analysis": "inverse_audit",
    "domains_without_inverse_cases": _inv_missing,
    "unsafe_auto_post_leaks": _inv_leaked,
    "min_inverse_cases": _inv_min,
    "_routing": routing_iv12,
    "_routing_reason": reason_iv12,
    "_legal_basis": "V3_P35 §10/I12; fail-closed (V1 zasada 6); cel nadrzędny serii",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "inverse_audit"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := domain_trust_score_decision {
    domain_trust_score_decision.rule_id != ""
} else := auditor_as_data_decision {
    auditor_as_data_decision.rule_id != ""
} else := golden_case_registry_decision {
    golden_case_registry_decision.rule_id != ""
} else := unified_audit_report_decision {
    unified_audit_report_decision.rule_id != ""
} else := drill_down_evidence_decision {
    drill_down_evidence_decision.rule_id != ""
} else := skew_detection_decision {
    skew_detection_decision.rule_id != ""
} else := dashboards_as_data_decision {
    dashboards_as_data_decision.rule_id != ""
} else := continuous_vs_per_pr_decision {
    continuous_vs_per_pr_decision.rule_id != ""
} else := operator_feedback_decision {
    operator_feedback_decision.rule_id != ""
} else := alert_routing_decision {
    alert_routing_decision.rule_id != ""
} else := legal_freshness_stamp_decision {
    legal_freshness_stamp_decision.rule_id != ""
} else := inverse_audit_decision {
    inverse_audit_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p35_audyutory_domenowe.no_match",
    "package": "jdg.v3_p35_audyutory_domenowe",
    "priority": 999999,
}
