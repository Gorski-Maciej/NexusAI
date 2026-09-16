# NEXUSAI JDG — V3-P67 SELF-LEARNING FORTECY (konwencja P51–P66)
# ==============================================================================
# Pętla wiedzy z decyzji i wyjątków — 12 innowacji (I01–I12; prompt P67 Sekcja 10):
#   I01 Advice-to-rule pipeline — klaster NEEDS_ADVICE → draft → SMT/Z3 →
#       golden replay → 4-eyes → SHADOW (wyjątek dziś, reguła jutro).
#   I02 Correction-rate per rule — korekty po AUTO_POST sprzężone z rule_id.
#   I03 Learning telemetry in P58 — metryki uczenia we wspólnym katalogu P58.
#   I04 Suggestion expiry by law epoch — sugestie mają epokę prawną (P53).
#   I05 Guardrails enforcement — sugestia bez SMT/Z3/replay/4-eyes = BLOCK.
#   I06 Learning dashboard — klaster → sugestia → status → efekt.
#   I07 Data readiness register — rejestr danych uczących (status + plan).
#   I08 Human feedback loop — oceny operatorów (P35) jako dane uczące.
#   I09 Learning safety metrics — odrzucenia sugestii przez guardrails.
#   I10 Knowledge base from verdicts — zapytywalna baza orzeczeń (P10/P11).
#   I11 Curriculum for rules — kolejka sugestii po ROI (częstość × wpływ).
#   I12 Post-learning replay — replay historii na nowej regule (P10/P53).
#
#   * Progi wyłącznie z data.jdg.thresholds.v3_p67 — ADR-002 (P06); okno
#     temporalne valid_from (P05); zero hardcode.
#   * Fail-closed (V1 zasada 6; konwencja P51–P66): brak snapshotu progów =
#     NEEDS_ADVICE; bez flagi v3_p67_check = NO_MATCH; nigdy ciche AUTO_POST.
#   * Rego bramkuje PODSUMOWANIA silników (tools/v3_p67_engines.py czytają
#     PRAWDZIWE źródła: rejestr danych uczących, certyfikaty P11, golden
#     verdicts P10, rule_registry P07, feedback operatorów P35-I09, SMT proofs
#     P33/P42, epoki prawne P53, pustynie P51, telemetria P58). Klucze w
#     input.v3_p67 (I01_..–I12_..).
#   * Akty: RODO art. 22 (human-in-the-loop), RODO art. 13 ust. 2 lit. f
#     (przejrzystość logiki), AI Act (nadzór człowieka) [NIEZWERYFIKOWANE —
#     ISAP], OP art. 119a (GAAR — uczenie nie promuje agresywnych ścieżek),
#     UoR art. 4 ust. 1 (rzetelność), VAT art. 108 (sugestie stawek walidowane
#     ISAP — P47), SUS art. 18a (sugestie parametrów przez lifecycle), KKS
#     art. 56 (dowód staranności) — WSZYSTKIE [NIEZWERYFIKOWANE — ISAP].
#   * Aktywacja: input.jdg_entrepreneur.v3_p67_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p67_self_learning.<analiza>.
#   * Priorytety: 467001–467012 (I01–I12).
#   * Wiring (main_jdg.rego): data.jdg.v3_p67_self_learning →
#     final_verdict_p131 = safe_merge(final_verdict_p130, …).
# ==============================================================================

package jdg.v3_p67_self_learning

# ── Kontrakt wejściowy ────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p67_check", false) == true
_ctx := object.get(input, "v3_p67", {})

# ── Snapshot progów (ADR-002) ─────────────────────────────────────────────────
_p67_snapshot := data.jdg.thresholds.v3_p67

_snapshot_ok = true {
	count(_p67_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p67_snapshot) > 0
	value := object.get(_p67_snapshot, key, null)
	value != null
} else = fallback

_not(x) = true {
	x == false
}

_not(x) = false {
	x == true
}

# ── Fail-closed gdy snapshot progów niedostępny ───────────────────────────────
fail_closed_decision := {
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.thresholds_missing",
	"package": "jdg.v3_p67_self_learning",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P67 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Advice-to-rule pipeline ──────────────────────────────────────────────
i01_ctx := object.get(_ctx, "I01_advice_to_rule_pipeline", {})
i01_clusters := object.get(i01_ctx, "clusters", 0)
i01_stages := object.get(i01_ctx, "stages", 0)
i01_missing := object.get(i01_ctx, "missing_validations", [])
i01_target := object.get(i01_ctx, "lifecycle_target", "")

default i01_decision := "NEEDS_ADVICE"

i01_decision := "PASS" {
	i01_clusters >= _th("v3_p67_clusters_min", 3)
	i01_stages >= _th("v3_p67_pipeline_stages_min", 5)
	count(i01_missing) == 0
	i01_target == "SHADOW"
}

i01_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.advice_to_rule_pipeline",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467001,
	"_legal_basis": "RODO art. 22 [NIEZWERYFIKOWANE — ISAP]; prompt P67 I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i01_decision,
	"reason": sprintf("pipeline: klasterów=%v, etapów=%v, brak walidacji=%v, cel lifecycle=%v", [i01_clusters, i01_stages, i01_missing, i01_target]),
	"metrics": {"clusters": i01_clusters, "stages": i01_stages, "missing_validations": i01_missing, "lifecycle_target": i01_target},
})

# ── I02: Correction-rate per rule ─────────────────────────────────────────────
i02_ctx := object.get(_ctx, "I02_correction_rate", {})
i02_total := object.get(i02_ctx, "corrections", 0)
i02_unattributed := object.get(i02_ctx, "unattributed", 0)

default i02_decision := "NEEDS_ADVICE"

i02_decision := "PASS" {
	i02_unattributed == 0
	i02_total >= 1
}

i02_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.correction_rate_per_rule",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467002,
	"_legal_basis": "UoR art. 4 ust. 1 [NIEZWERYFIKOWANE — ISAP]; prompt P67 I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i02_decision,
	"reason": sprintf("korekty AUTO_POST: %v, bez rule_id: %v — wskaźnik słabych reguł", [i02_total, i02_unattributed]),
	"metrics": {"corrections": i02_total, "unattributed": i02_unattributed},
})

# ── I03: Learning telemetry in P58 ────────────────────────────────────────────
i03_ctx := object.get(_ctx, "I03_learning_telemetry", {})
i03_metrics := object.get(i03_ctx, "metrics_defined", 0)
i03_p58 := object.get(i03_ctx, "p58_engines", 0)

default i03_decision := "NEEDS_ADVICE"

i03_decision := "PASS" {
	i03_metrics >= _th("v3_p67_telemetry_metrics_min", 6)
	i03_p58 >= 4
}

i03_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.learning_telemetry_p58",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467003,
	"_legal_basis": "RODO art. 13 ust. 2 lit. f [NIEZWERYFIKOWANE — ISAP]; prompt P67 I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i03_decision,
	"reason": sprintf("metryki uczenia=%v (min=%v); silniki P58=%v", [i03_metrics, _th("v3_p67_telemetry_metrics_min", 6), i03_p58]),
	"metrics": {"metrics_defined": i03_metrics, "p58_engines": i03_p58},
})

# ── I04: Suggestion expiry by law epoch ───────────────────────────────────────
i04_ctx := object.get(_ctx, "I04_suggestion_expiry", {})
i04_total := object.get(i04_ctx, "suggestions", 0)
i04_no_epoch := object.get(i04_ctx, "no_epoch", 0)
i04_epochs := object.get(i04_ctx, "epochs", 0)

default i04_decision := "BLOCK"

i04_decision := "PASS" {
	i04_no_epoch == 0
	i04_epochs >= 1
}

i04_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.suggestion_expiry_by_law_epoch",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467004,
	"_legal_basis": "P05 temporalność; P53 epoki prawne; prompt P67 I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i04_decision,
	"reason": sprintf("sugestie bez epoki prawnej: %v/%v (rejestr P53: %v epok)", [i04_no_epoch, i04_total, i04_epochs]),
	"metrics": {"suggestions": i04_total, "no_epoch": i04_no_epoch, "epochs": i04_epochs},
})

# ── I05: Guardrails enforcement ───────────────────────────────────────────────
i05_ctx := object.get(_ctx, "I05_guardrails", {})
i05_unvalidated := object.get(i05_ctx, "unvalidated", 0)
i05_roles := object.get(i05_ctx, "four_eyes_roles", 0)

default i05_decision := "BLOCK"

i05_decision := "PASS" {
	i05_unvalidated == 0
	i05_roles >= _th("v3_p67_four_eyes_roles_min", 4)
}

i05_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.guardrails_enforcement",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467005,
	"_legal_basis": "AI Act (nadzór człowieka) [NIEZWERYFIKOWANE — ISAP]; prompt P67 I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i05_decision,
	"reason": sprintf("sugestie APPROVED bez walidacji: %v; role 4-eyes: %v", [i05_unvalidated, i05_roles]),
	"metrics": {"unvalidated": i05_unvalidated, "four_eyes_roles": i05_roles},
})

# ── I06: Learning dashboard ───────────────────────────────────────────────────
i06_ctx := object.get(_ctx, "I06_learning_dashboard", {})
i06_rows := object.get(i06_ctx, "rows", 0)

default i06_decision := "NEEDS_ADVICE"

i06_decision := "PASS" {
	i06_rows >= _th("v3_p67_dashboard_rows_min", 4)
}

i06_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.learning_dashboard",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467006,
	"_legal_basis": "prompt P67 I06; P58 obserwowalność",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i06_decision,
	"reason": sprintf("tablica uczenia: wierszy=%v (min=%v)", [i06_rows, _th("v3_p67_dashboard_rows_min", 4)]),
	"metrics": {"rows": i06_rows},
})

# ── I07: Data readiness register ──────────────────────────────────────────────
i07_ctx := object.get(_ctx, "I07_data_readiness", {})
i07_sources := object.get(i07_ctx, "sources", 0)
i07_available := object.get(i07_ctx, "available", 0)
i07_missing := object.get(i07_ctx, "missing", [])

default i07_decision := "NEEDS_ADVICE"

i07_decision := "PASS" {
	i07_sources >= _th("v3_p67_data_sources_min", 6)
	i07_available >= 6
}

i07_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.data_readiness_register",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467007,
	"_legal_basis": "prompt P67 I07; P51 pustynie (plan domknięcia)",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i07_decision,
	"reason": sprintf("źródeł danych uczących=%v, dostępnych=%v, brakujące=%v", [i07_sources, i07_available, i07_missing]),
	"metrics": {"sources": i07_sources, "available": i07_available, "missing": i07_missing},
})

# ── I08: Human feedback loop ──────────────────────────────────────────────────
i08_ctx := object.get(_ctx, "I08_human_feedback", {})
i08_reviews := object.get(i08_ctx, "reviews", 0)
i08_no_cert := object.get(i08_ctx, "no_cert_link", 0)
i08_no_feed := object.get(i08_ctx, "no_feed", 0)

default i08_decision := "BLOCK"

i08_decision := "PASS" {
	i08_reviews >= 1
	i08_no_cert == 0
	i08_no_feed == 0
}

i08_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.human_feedback_loop",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467008,
	"_legal_basis": "RODO art. 22 [NIEZWERYFIKOWANE — ISAP]; prompt P67 I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i08_decision,
	"reason": sprintf("oceny operatorów=%v; bez linku certyfikatu=%v; bez feedu golden/trust=%v", [i08_reviews, i08_no_cert, i08_no_feed]),
	"metrics": {"reviews": i08_reviews, "no_cert_link": i08_no_cert, "no_feed": i08_no_feed},
})

# ── I09: Learning safety metrics ──────────────────────────────────────────────
i09_ctx := object.get(_ctx, "I09_learning_safety", {})
i09_rejections := object.get(i09_ctx, "rejections", 0)

default i09_decision := "NEEDS_ADVICE"

i09_decision := "PASS" {
	i09_rejections >= _th("v3_p67_suggestion_rejections_min", 1)
}

i09_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.learning_safety_metrics",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467009,
	"_legal_basis": "OP art. 119a (GAAR) [NIEZWERYFIKOWANE — ISAP]; prompt P67 I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i09_decision,
	"reason": sprintf("odrzucenia sugestii przez guardrails: %v (min=%v)", [i09_rejections, _th("v3_p67_suggestion_rejections_min", 1)]),
	"metrics": {"rejections": i09_rejections},
})

# ── I10: Knowledge base from verdicts ─────────────────────────────────────────
i10_ctx := object.get(_ctx, "I10_knowledge_base", {})
i10_verdicts := object.get(i10_ctx, "verdicts", 0)

default i10_decision := "NEEDS_ADVICE"

i10_decision := "PASS" {
	i10_verdicts >= _th("v3_p67_knowledge_verdicts_min", 30)
}

i10_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.knowledge_base_from_verdicts",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467010,
	"_legal_basis": "prompt P67 I10; P11 Decision Certificate; P10 golden",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i10_decision,
	"reason": sprintf("orzeczeń w bazie wiedzy=%v (min=%v)", [i10_verdicts, _th("v3_p67_knowledge_verdicts_min", 30)]),
	"metrics": {"verdicts": i10_verdicts},
})

# ── I11: Curriculum for rules (ROI) ───────────────────────────────────────────
i11_ctx := object.get(_ctx, "I11_curriculum", {})
i11_queue := object.get(i11_ctx, "queue_n", 0)
i11_below := object.get(i11_ctx, "below_roi", 0)

default i11_decision := "NEEDS_ADVICE"

i11_decision := "PASS" {
	i11_queue >= 1
	i11_below == 0
}

i11_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.curriculum_for_rules",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467011,
	"_legal_basis": "prompt P67 I11; P51 domykanie pustyni (ROI)",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i11_decision,
	"reason": sprintf("kolejka ROI: n=%v, poniżej progu=%v (min ROI=%v)", [i11_queue, i11_below, _th("v3_p67_curriculum_roi_min", 5)]),
	"metrics": {"queue_n": i11_queue, "below_roi": i11_below},
})

# ── I12: Post-learning replay ─────────────────────────────────────────────────
i12_ctx := object.get(_ctx, "I12_post_learning_replay", {})
i12_replays := object.get(i12_ctx, "replays", 0)

default i12_decision := "NEEDS_ADVICE"

i12_decision := "PASS" {
	i12_replays >= _th("v3_p67_replay_cases_min", 30)
}

i12_pipeline := object.union({
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.post_learning_replay",
	"package": "jdg.v3_p67_self_learning",
	"priority": 467012,
	"_legal_basis": "prompt P67 I12; P10 golden replay; P53 replay contract",
	"valid_from": "2026-01-01",
	"valid_to": null,
}, {
	"decision": i12_decision,
	"reason": sprintf("replay historii na regułach z sugestii: %v (min=%v)", [i12_replays, _th("v3_p67_replay_cases_min", 30)]),
	"metrics": {"replays": i12_replays},
})

# ── Router decide — deterministyczny else-chain (konwencja P51–P66) ───────────
# Kolejność: BLOCK (I04/I05/I08) przed NEEDS_ADVICE (reszta), potem PASS.
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i04_pipeline {
	_snapshot_ok
	_activated
	i04_pipeline.decision == "BLOCK"
} else := i05_pipeline {
	_snapshot_ok
	_activated
	i05_pipeline.decision == "BLOCK"
} else := i08_pipeline {
	_snapshot_ok
	_activated
	i08_pipeline.decision == "BLOCK"
} else := i01_pipeline {
	_snapshot_ok
	_activated
	i01_pipeline.decision == "NEEDS_ADVICE"
} else := i02_pipeline {
	_snapshot_ok
	_activated
	i02_pipeline.decision == "NEEDS_ADVICE"
} else := i03_pipeline {
	_snapshot_ok
	_activated
	i03_pipeline.decision == "NEEDS_ADVICE"
} else := i06_pipeline {
	_snapshot_ok
	_activated
	i06_pipeline.decision == "NEEDS_ADVICE"
} else := i07_pipeline {
	_snapshot_ok
	_activated
	i07_pipeline.decision == "NEEDS_ADVICE"
} else := i09_pipeline {
	_snapshot_ok
	_activated
	i09_pipeline.decision == "NEEDS_ADVICE"
} else := i10_pipeline {
	_snapshot_ok
	_activated
	i10_pipeline.decision == "NEEDS_ADVICE"
} else := i11_pipeline {
	_snapshot_ok
	_activated
	i11_pipeline.decision == "NEEDS_ADVICE"
} else := i12_pipeline {
	_snapshot_ok
	_activated
	i12_pipeline.decision == "NEEDS_ADVICE"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := no_match_row {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p67_self_learning.all_green",
	"package": "jdg.v3_p67_self_learning",
	"priority": 1,
	"decision": "PASS",
	"reason": "P67: pętla samouczenia domknięta (12 analiz: pipeline wyjątek→reguła, korekty sprzężone z regułami, telemetria w P58, epoki prawne unieważniają sugestie, guardrails techniczne, tablica uczenia, rejestr danych uczących, pętla feedback operatorów, metryki bezpieczeństwa uczenia, baza wiedzy z orzeczeń, kolejka ROI, replay po wdrożeniu reguły)",
	"metrics": {"analyses": 12},
	"_legal_basis": "RODO art. 22 i art. 13 ust. 2 lit. f; AI Act (nadzór człowieka); OP art. 119a; UoR art. 4 ust. 1; VAT art. 108; SUS art. 18a; KKS art. 56 [NIEZWERYFIKOWANE — ISAP]; prompt P67 Sekcja 10",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

no_match_row := {
	"matched": false,
	"rule_id": "jdg.v3_p67_self_learning.no_match",
	"package": "jdg.v3_p67_self_learning",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P67 niewyzwolony (brak flagi v3_p67_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P66",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
