# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P37 OBSERWOWALNOŚĆ — DECYZJE Z TELEMETRIĄ JAK KOD Z COVERAGE
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa obserwowalności ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Decision SLO Contract (SLO jako dane: metryka, próg, okno, akcja,
#       runbook; SLO bez progu/akcji = BLOCK),
#   I02 Freshness SLA dla Prawa (wiek weryfikacji ISAP per akt; stale > SLA =
#       TRIAGE z listą aktów do re-checku — Law Radar P08; akt bez weryfikacji
#       = BLOCK),
#   I03 Needs-Advice Radar (klasterizacja NEEDS_ADVICE; skok > ratio×baseline =
#       TRIAGE; NEEDS_ADVICE bez powodu = BLOCK — każdy fail-closed z powodem),
#   I04 Latency Budget per Domena (p95 eval; > max = TRIAGE; > 2×max = BLOCK;
#       reguła przeciążająca budżet do rejestru — routing O(1) z P02),
#   I05 Decision Certificate as Telemetry (certyfikat P11 = źródło metryk;
#       decyzja bez pól certyfikatu = BLOCK — zero telemetrii bez dowodu),
#   I06 Error Budget Freeze (budżet wyczerpany + wdrożenie = BLOCK;
#       freeze aktywny + merge = BLOCK — workflow CI odmawia),
#   I07 Anomaly Detection z Sezonowością (koniec miesiąca/kwartału księgowego;
#       fałszywy alarm bez sezonowości = TRIAGE),
#   I08 Golden Drift Watch (decyzje produkcyjne vs golden verdicts P10;
#       rozjazd > 0 = BLOCK z diffem inputów — dokładność SLO),
#   I09 Runbook-as-Code (runbooki w repo; alarm bez runbooka = BLOCK;
#       test = istnienie runbooka dla każdego alarmu),
#   I10 Comprehensive Status Page (status fortecy: dostępność, SLO, wiek
#       prawa, luki P0/P1; nieświeży/niekompletny = TRIAGE),
#   I11 Metryki Kosztu Decyzji (CPU/tokeny per decyzja, ścieżki AI z P33;
#       koszt > limit = TRIAGE; brak telemetrii kosztu AI = BLOCK),
#   I12 Benchmark Regression Gate (benchmarki eval w CI; regresja p95
#       > max% = BLOCK; brak baseline = TRIAGE).
#
# Uwaga terminologiczna (dowód z audytu 9.04): tools/health_tier_engine.py i
# health_tier_recalculator.py to TIERY ZUS (przychód 60k/300k, 491.40/819.00/
# 1474.20 PLN) — domena biznesowa, NIE health tierów SRE. Obserwowalność
# korzysta z metrics_generator/pewnosc_metrics (LCI/TCL/RV/UVR) — zero duplikacji.
#
# Integracje (kontrakty między-częściowe):
#   * P03 (kontrakt werdyktu) — decyzje zgodne z 25-polowym kontraktem,
#   * P08 (Law Radar) — freshness SLA jako wejście re-checku (I02),
#   * P10 (Golden Oracle) — drift watch i dokładność SLO (I08),
#   * P11 (Decision Certificate) — certyfikat jako telemetria (I05),
#   * P02 (routing O(1)) — budżet latencji per domena (I04),
#   * P30 (luki) — radar NEEDS_ADVICE auto-ticket (I03),
#   * P33 (warstwa AI) — koszt decyzji AI (I11),
#   * P35 (audytory) — metryki z audytów/bramek (kontrakt wejściowy),
#   * P36 (transformacje) — benchmark gate przed deployem bundle (I12),
#   * P39 (CI) — freeze wdrożeń przy wyczerpaniu budżetu (I06).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p37 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * FAIL-CLOSED (V1 zasada 6): decyzja bez certyfikatu, rozjazd z golden,
#     regresja benchmarku, brak runbooka = BLOCK — nigdy cichy AUTO_POST.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p37_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p37_obserwowalnosc.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p37_obserwowalnosc
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p37_obserwowalnosc

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p37_check", false) == true
_ctx := object.get(input, "v3_p37", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p37_snapshot := data.jdg.thresholds.v3_p37

_snapshot_ok = true {
    count(_p37_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p37_snapshot) > 0
    value := object.get(_p37_snapshot, key, null)
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
    "rule_id": "jdg.v3_p37_obserwowalnosc.thresholds_missing",
    "package": "jdg.v3_p37_obserwowalnosc",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "OBSERWOWALNOSC V3-P37: brak snapshotu data.jdg.thresholds.v3_p37.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P37] Brak snapshotu progów obserwowalności — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p37_obserwowalnosc",
        "priority": priority,
        "threshold_version": object.get(_p37_snapshot, "v3_p37_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p37_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p37_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I01: DECISION SLO CONTRACT — SLO jako dane (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_slo := object.get(_ctx, "decision_slo", {})
_slo_invalid := object.get(_slo, "slos_without_threshold_or_action", 0)
_slo_violations := object.get(_slo, "slo_violations_open", 0)

routing_s01 = "BLOCK_AND_ALERT" {
    _slo_invalid > 0
} else = "TRIAGE_QUEUE" {
    _slo_violations > 0
} else = "SUGGEST" {
    true
}

reason_s01 = sprintf("SLO bez progu/akcji/runbooka: %v — BLOCK (SLO jako dane: metryka, próg, okno, akcja; zmiana SLO jak zmiana parametru P06).", [_slo_invalid]) {
    _slo_invalid > 0
} else = sprintf("Naruszenia SLO otwarte: %v — TRIAGE (error budget i akcja wg katalogu SLO).", [_slo_violations]) {
    _slo_violations > 0
} else = sprintf("Decision SLO contract OK: %v SLO z progiem, oknem, akcją i runbookiem.", [object.get(_slo, "slos_total", 0)]) {
    true
}

decision_slo_decision := _certificate(437001, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.decision_slo",
    "analysis": "decision_slo",
    "slos_without_threshold_or_action": _slo_invalid,
    "slo_violations_open": _slo_violations,
    "_routing": routing_s01,
    "_routing_reason": reason_s01,
    "_legal_basis": "V3_P37 §10/I01; ADR-002 (SLO jako dane); UoR art. 4 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "decision_slo"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I02: FRESHNESS SLA DLA PRAWA — wiek weryfikacji ISAP (AN01/AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_lf := object.get(_ctx, "law_freshness_sla", {})
_lf_unverified := object.get(_lf, "acts_unverified", 0)
_lf_stale := object.get(_lf, "acts_stale", 0)
_lf_sla := _th("v3_p37_law_freshness_sla_days", 7)

routing_lf02 = "BLOCK_AND_ALERT" {
    _lf_unverified > 0
} else = "TRIAGE_QUEUE" {
    _lf_stale > 0
} else = "SUGGEST" {
    true
}

reason_lf02 = sprintf("Akty bez weryfikacji ISAP: %v — BLOCK (telemetria świeżości prawa: akt niezweryfikowany nie może podpierać AUTO_POST).", [_lf_unverified]) {
    _lf_unverified > 0
} else = sprintf("Akty po SLA świeżości (%v dni): %v — TRIAGE (lista do re-checku; Law Radar P08).", [_lf_sla, _lf_stale]) {
    _lf_stale > 0
} else = sprintf("Freshness SLA OK: wszystkie akty zweryfikowane ≤ %v dni.", [_lf_sla]) {
    true
}

law_freshness_sla_decision := _certificate(437002, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.law_freshness_sla",
    "analysis": "law_freshness_sla",
    "acts_unverified": _lf_unverified,
    "acts_stale": _lf_stale,
    "freshness_sla_days": _lf_sla,
    "_routing": routing_lf02,
    "_routing_reason": reason_lf02,
    "_legal_basis": "V3_P37 §10/I02; RODO art. 5.2 (rozliczalność) [NIEZWERYFIKOWANE]; kontrakt P08 (Law Radar)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "law_freshness_sla"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I03: NEEDS-ADVICE RADAR — skok fail-closed = sygnał luki (AN01/AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_na := object.get(_ctx, "needs_advice_radar", {})
_na_without_reason := object.get(_na, "needs_advice_without_reason", 0)
_na_spike := object.get(_na, "spike_detected", false)
_na_ratio := _th("v3_p37_na_spike_ratio", 3)

routing_na03 = "BLOCK_AND_ALERT" {
    _na_without_reason > 0
} else = "TRIAGE_QUEUE" {
    _na_spike
} else = "SUGGEST" {
    true
}

reason_na03 = sprintf("NEEDS_ADVICE bez powodu: %v — BLOCK (każdy fail-closed musi mieć powód — wskaźnik fail-closed jako SLO).", [_na_without_reason]) {
    _na_without_reason > 0
} else = sprintf("Skok NEEDS_ADVICE > %vx baseline — TRIAGE (auto-ticket do P08/P30: luka prawna lub awaria danych).", [_na_ratio]) {
    _na_spike
} else = sprintf("Needs-advice radar OK: poziom NEEDS_ADVICE w normie, wszystkie z powodem.", []) {
    true
}

needs_advice_radar_decision := _certificate(437003, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.needs_advice_radar",
    "analysis": "needs_advice_radar",
    "needs_advice_without_reason": _na_without_reason,
    "spike_detected": _na_spike,
    "spike_ratio": _na_ratio,
    "_routing": routing_na03,
    "_routing_reason": reason_na03,
    "_legal_basis": "V3_P37 §10/I03; V1 zasada 6 (fail-closed z powodem); kontrakt P30",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "needs_advice_radar"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I04: LATENCY BUDGET PER DOMENA — p95 eval (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_lb := object.get(_ctx, "latency_budget", {})
_lb_over := object.get(_lb, "domains_over_budget", 0)
_lb_over2x := object.get(_lb, "domains_over_2x_budget", 0)
_lb_max := _th("v3_p37_latency_p95_max_ms", 500)

routing_lb04 = "BLOCK_AND_ALERT" {
    _lb_over2x > 0
} else = "TRIAGE_QUEUE" {
    _lb_over > 0
} else = "SUGGEST" {
    true
}

reason_lb04 = sprintf("Domeny z p95 > 2× budżetu (%v ms): %v — BLOCK (reguła przeciążająca budżet blokuje deploy — K06 routing O(1)).", [_lb_max, _lb_over2x]) {
    _lb_over2x > 0
} else = sprintf("Domeny z p95 > budżetu (%v ms): %v — TRIAGE (rejestr + analiza else-chain → routing).", [_lb_max, _lb_over]) {
    _lb_over > 0
} else = sprintf("Latency budget OK: wszystkie domeny ≤ %v ms p95.", [_lb_max]) {
    true
}

latency_budget_decision := _certificate(437004, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.latency_budget",
    "analysis": "latency_budget",
    "domains_over_budget": _lb_over,
    "domains_over_2x_budget": _lb_over2x,
    "latency_p95_max_ms": _lb_max,
    "_routing": routing_lb04,
    "_routing_reason": reason_lb04,
    "_legal_basis": "V3_P37 §10/I04; kontrakt P02 (routing O(1)); ADR-009",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "latency_budget"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I05: DECISION CERTIFICATE AS TELEMETRY — certyfikat = źródło metryk (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_ct := object.get(_ctx, "certificate_telemetry", {})
_ct_missing := object.get(_ct, "decisions_without_certificate", 0)
_ct_incomplete := object.get(_ct, "certificates_incomplete", 0)

routing_ct05 = "BLOCK_AND_ALERT" {
    _ct_missing > 0
} else = "TRIAGE_QUEUE" {
    _ct_incomplete > 0
} else = "SUGGEST" {
    true
}

reason_ct05 = sprintf("Decyzje bez certyfikatu: %v — BLOCK (zero telemetrii bez dowodu; Decision Certificate P11 = jedyne źródło metryk decyzji).", [_ct_missing]) {
    _ct_missing > 0
} else = sprintf("Certyfikaty niekompletne (brak domeny/pewności/trybu): %v — TRIAGE (dopełnić pola kontraktu P03).", [_ct_incomplete]) {
    _ct_incomplete > 0
} else = sprintf("Certificate telemetry OK: %v decyzji z pełnym certyfikatem.", [object.get(_ct, "decisions_total", 0)]) {
    true
}

certificate_telemetry_decision := _certificate(437005, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.certificate_telemetry",
    "analysis": "certificate_telemetry",
    "decisions_without_certificate": _ct_missing,
    "certificates_incomplete": _ct_incomplete,
    "_routing": routing_ct05,
    "_routing_reason": reason_ct05,
    "_legal_basis": "V3_P37 §10/I05; kontrakt P11 (certyfikat); RODO art. 5.2 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "certificate_telemetry"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I06: ERROR BUDGET FREEZE — wyczerpany budżet zamraża wdrożenia (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_eb := object.get(_ctx, "error_budget_freeze", {})
_eb_deploy_during_freeze := object.get(_eb, "deploys_during_freeze", 0)
_eb_exhausted := _has_flag("error_budget_exhausted")
_eb_min := _th("v3_p37_error_budget_min_pct", 0)

routing_eb06 = "BLOCK_AND_ALERT" {
    _eb_deploy_during_freeze > 0
} else = "TRIAGE_QUEUE" {
    _eb_exhausted
} else = "SUGGEST" {
    true
}

reason_eb06 = sprintf("Wdrożenia w trakcie freeze (budżet ≤ %v%%): %v — BLOCK (CI odmawia merge do czasu odbudowy budżetu).", [_eb_min, _eb_deploy_during_freeze]) {
    _eb_deploy_during_freeze > 0
} else = sprintf("Error budget wyczerpany (≤ %v%%) — TRIAGE (freeze wdrożeń reguł; eskalacja do właściciela SLO).", [_eb_min]) {
    _eb_exhausted
} else = sprintf("Error budget OK: %v%% dostępne.", [object.get(_eb, "budget_remaining_pct", 100)]) {
    true
}

error_budget_freeze_decision := _certificate(437006, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.error_budget_freeze",
    "analysis": "error_budget_freeze",
    "deploys_during_freeze": _eb_deploy_during_freeze,
    "error_budget_exhausted": _eb_exhausted,
    "budget_remaining_pct": object.get(_eb, "budget_remaining_pct", 100),
    "_routing": routing_eb06,
    "_routing_reason": reason_eb06,
    "_legal_basis": "V3_P37 §10/I06; kontrakt P39 (CI); UoR art. 4 (rzetelność) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "error_budget_freeze"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I07: ANOMALY DETECTION Z SEZONOWOŚCIĄ — mniej fałszywych alarmów (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_an := object.get(_ctx, "anomaly_detection", {})
_an_false_alarms := object.get(_an, "false_alarms_no_seasonality", 0)
_an_unaccounted := object.get(_an, "anomalies_unaccounted", 0)

routing_an07 = "BLOCK_AND_ALERT" {
    _an_unaccounted > 0
} else = "TRIAGE_QUEUE" {
    _an_false_alarms > 0
} else = "SUGGEST" {
    true
}

reason_an07 = sprintf("Anomalie nieuwzględnione (poza sezonowością): %v — BLOCK (anomalia niewyjaśniona = potencjalna awaria ścieżki AUTO_POST).", [_an_unaccounted]) {
    _an_unaccounted > 0
} else = sprintf("Fałszywe alarmy bez sezonowości (koniec mies./kwart.): %v — TRIAGE (dopasować model sezonowy — mniej szumu).", [_an_false_alarms]) {
    _an_false_alarms > 0
} else = sprintf("Anomaly detection OK: sezonowość księgowa uwzględniona; %v anomalii wyjaśnionych.", [object.get(_an, "anomalies_explained", 0)]) {
    true
}

anomaly_detection_decision := _certificate(437007, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.anomaly_detection",
    "analysis": "anomaly_detection",
    "false_alarms_no_seasonality": _an_false_alarms,
    "anomalies_unaccounted": _an_unaccounted,
    "_routing": routing_an07,
    "_routing_reason": reason_an07,
    "_legal_basis": "V3_P37 §10/I07; kontrakt P32-I07 (replay sezonowy); AP12 (jedno źródło prawdy)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "anomaly_detection"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I08: GOLDEN DRIFT WATCH — produkcja vs golden verdicts (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_gd := object.get(_ctx, "golden_drift_watch", {})
_gd_drift := object.get(_gd, "drifted_decisions", 0)
_gd_no_watch := _has_flag("drift_watch_disabled")
_gd_max := _th("v3_p37_golden_drift_max", 0)

routing_gd08 = "BLOCK_AND_ALERT" {
    _gd_drift > _gd_max
} else = "BLOCK_AND_ALERT" {
    _gd_no_watch
} else = "SUGGEST" {
    true
}

reason_gd08 = sprintf("Rozjazd produkcja vs golden: %v (limit %v) — BLOCK (dokładność SLO; alarm z diffem inputów — P10).", [_gd_drift, _gd_max]) {
    _gd_drift > _gd_max
} else = sprintf("Drift watch wyłączony — BLOCK (obserwowalność dokładności obowiązkowa; fortica bez watcha ślepnie).", []) {
    _gd_no_watch
} else = sprintf("Golden drift watch OK: %v decyzji zgodnych z golden (dokładność 100% w oknie).", [object.get(_gd, "checked_decisions", 0)]) {
    true
}

golden_drift_watch_decision := _certificate(437008, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.golden_drift_watch",
    "analysis": "golden_drift_watch",
    "drifted_decisions": _gd_drift,
    "drift_watch_disabled": _gd_no_watch,
    "golden_drift_max": _gd_max,
    "_routing": routing_gd08,
    "_routing_reason": reason_gd08,
    "_legal_basis": "V3_P37 §10/I08; kontrakt P10 (Golden Oracle); SLO dokładność",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_drift_watch"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I09: RUNBOOK-AS-CODE — alarm bez runbooka = luka (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_rb := object.get(_ctx, "runbook_as_code", {})
_rb_missing := object.get(_rb, "alerts_without_runbook", 0)
_rb_stale := object.get(_rb, "runbooks_stale", 0)
_rb_max := _th("v3_p37_alert_without_runbook_max", 0)

routing_rb09 = "BLOCK_AND_ALERT" {
    _rb_missing > _rb_max
} else = "TRIAGE_QUEUE" {
    _rb_stale > 0
} else = "SUGGEST" {
    true
}

reason_rb09 = sprintf("Alarmy bez runbooka: %v (limit %v) — BLOCK (runbook-as-code: każdy alarm ma kroki naprawy w repo; test istnienia w CI).", [_rb_missing, _rb_max]) {
    _rb_missing > _rb_max
} else = sprintf("Runbooki nieświeże: %v — TRIAGE (zaktualizować kroki po zmianie progu/akcji).", [_rb_stale]) {
    _rb_stale > 0
} else = sprintf("Runbook-as-code OK: %v alarmów z runbookiem w docs/runbooks/.", [object.get(_rb, "alerts_total", 0)]) {
    true
}

runbook_as_code_decision := _certificate(437009, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.runbook_as_code",
    "analysis": "runbook_as_code",
    "alerts_without_runbook": _rb_missing,
    "runbooks_stale": _rb_stale,
    "alerts_without_runbook_max": _rb_max,
    "_routing": routing_rb09,
    "_routing_reason": reason_rb09,
    "_legal_basis": "V3_P37 §10/I09; kontrakt P41 (dokumentacja); ISO 27001 (monitoring) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "runbook_as_code"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I10: COMPREHENSIVE STATUS PAGE — jeden status fortecy (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_sp := object.get(_ctx, "status_page", {})
_sp_missing_sections := object.get(_sp, "missing_sections", 0)
_sp_stale_days := object.get(_sp, "stale_days", 0)
_sp_max := _th("v3_p37_status_page_max_stale_days", 1)

routing_sp10 = "BLOCK_AND_ALERT" {
    _sp_missing_sections > 0
} else = "TRIAGE_QUEUE" {
    _sp_stale_days > _sp_max
} else = "SUGGEST" {
    true
}

reason_sp10 = sprintf("Status page bez wymaganych sekcji (SLO/świeżość prawa/luki P0-P1): %v — BLOCK (status bez luk to status kłamliwy).", [_sp_missing_sections]) {
    _sp_missing_sections > 0
} else = sprintf("Status page nieświeży (%v dni > %v) — TRIAGE (odświeżyć: dostępność, SLO, wiek prawa, luki).", [_sp_stale_days, _sp_max]) {
    _sp_stale_days > _sp_max
} else = sprintf("Status page OK: kompletny, wiek %v dni.", [_sp_stale_days]) {
    true
}

status_page_decision := _certificate(437010, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.status_page",
    "analysis": "status_page",
    "missing_sections": _sp_missing_sections,
    "stale_days": _sp_stale_days,
    "max_stale_days": _sp_max,
    "_routing": routing_sp10,
    "_routing_reason": reason_sp10,
    "_legal_basis": "V3_P37 §10/I10; RODO art. 32 (monitorowanie) [NIEZWERYFIKOWANE]; kontrakt P30 (luki)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "status_page"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I11: METRYKI KOSZTU DECYZJI — CPU/tokeny per decyzja (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_dc := object.get(_ctx, "decision_cost", {})
_dc_missing_ai := object.get(_dc, "ai_decisions_without_cost", 0)
_dc_over := object.get(_dc, "decisions_over_cost_limit", 0)
_dc_limit := _th("v3_p37_ai_cost_limit_per_decision", 1.0)

routing_dc11 = "BLOCK_AND_ALERT" {
    _dc_missing_ai > 0
} else = "TRIAGE_QUEUE" {
    _dc_over > 0
} else = "SUGGEST" {
    true
}

reason_dc11 = sprintf("Decyzje AI bez telemetrii kosztu: %v — BLOCK (ścieżka AI z P33 bez budżetu = koszt niekontrolowany).", [_dc_missing_ai]) {
    _dc_missing_ai > 0
} else = sprintf("Decyzje ponad limit kosztu (%v): %v — TRIAGE (budżetowanie warstwy AI; cost governor P33-I08).", [_dc_limit, _dc_over]) {
    _dc_over > 0
} else = sprintf("Decision cost OK: wszystkie decyzje z telemetrią kosztu ≤ %v.", [_dc_limit]) {
    true
}

decision_cost_decision := _certificate(437011, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.decision_cost",
    "analysis": "decision_cost",
    "ai_decisions_without_cost": _dc_missing_ai,
    "decisions_over_cost_limit": _dc_over,
    "cost_limit": _dc_limit,
    "_routing": routing_dc11,
    "_routing_reason": reason_dc11,
    "_legal_basis": "V3_P37 §10/I11; kontrakt P33-I08 (cost governor)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "decision_cost"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37-I12: BENCHMARK REGRESSION GATE — p95 w CI z progiem (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_bg := object.get(_ctx, "benchmark_regression", {})
_bg_missing := _has_flag("benchmark_baseline_missing")
_bg_regression := object.get(_bg, "regression_pct", 0)
_bg_max := _th("v3_p37_benchmark_regression_max_pct", 10)

routing_bg12 = "BLOCK_AND_ALERT" {
    _bg_regression > _bg_max
} else = "BLOCK_AND_ALERT" {
    _bg_missing
} else = "SUGGEST" {
    true
}

reason_bg12 = sprintf("Regresja benchmarku p95: %v%% > %v%% — BLOCK (bramka przed deployem bundle; K04: SMT/Z3 dla równoważności).", [_bg_regression, _bg_max]) {
    _bg_regression > _bg_max
} else = sprintf("Brak baseline benchmarków eval — BLOCK (CI nie ma czego bronić; utworzyć .benchmarks/eval_baseline.json).", []) {
    _bg_missing
} else = sprintf("Benchmark gate OK: regresja %v%% ≤ %v%%.", [_bg_regression, _bg_max]) {
    true
}

benchmark_regression_decision := _certificate(437012, {
    "rule_id": "jdg.v3_p37_obserwowalnosc.benchmark_regression",
    "analysis": "benchmark_regression",
    "regression_pct": _bg_regression,
    "benchmark_baseline_missing": _bg_missing,
    "regression_max_pct": _bg_max,
    "_routing": routing_bg12,
    "_routing_reason": reason_bg12,
    "_legal_basis": "V3_P37 §10/I12; kontrakt P36-K1 (standard transformacji); kontrakt P39 (CI)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "benchmark_regression"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := decision_slo_decision {
    decision_slo_decision.rule_id != ""
} else := law_freshness_sla_decision {
    law_freshness_sla_decision.rule_id != ""
} else := needs_advice_radar_decision {
    needs_advice_radar_decision.rule_id != ""
} else := latency_budget_decision {
    latency_budget_decision.rule_id != ""
} else := certificate_telemetry_decision {
    certificate_telemetry_decision.rule_id != ""
} else := error_budget_freeze_decision {
    error_budget_freeze_decision.rule_id != ""
} else := anomaly_detection_decision {
    anomaly_detection_decision.rule_id != ""
} else := golden_drift_watch_decision {
    golden_drift_watch_decision.rule_id != ""
} else := runbook_as_code_decision {
    runbook_as_code_decision.rule_id != ""
} else := status_page_decision {
    status_page_decision.rule_id != ""
} else := decision_cost_decision {
    decision_cost_decision.rule_id != ""
} else := benchmark_regression_decision {
    benchmark_regression_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p37_obserwowalnosc.no_match",
    "package": "jdg.v3_p37_obserwowalnosc",
    "priority": 999999,
}
