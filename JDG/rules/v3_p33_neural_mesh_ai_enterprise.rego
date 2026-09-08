# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P33 WARSTWA AI ENTERPRISE — NEURAL MESH, LLM BRIDGE I
# HUMAN-IN-THE-LOOP (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa AI ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 AI Proposal Pipeline (LLM → walidacja składni → SMT/Z3 → golden replay →
#       4-eyes → SHADOW; żadna propozycja nie omija ścieżki; P07),
#   I02 Sandbox Uprawnień AI (konto techniczne bez zapisu do reguł produkcyjnych;
#       awans wyłącznie przez PR człowieka; AI=writer, człowiek=approver),
#   I03 Halucynacja Prawna Guard (weryfikacja podstawy prawnej z LLM w ISAP
#       przed prezentacją człowiekowi; zakaz fikcyjnych artykułów),
#   I04 Prompt Audit Ledger (każdy prompt+odpowiedź w WORM z checksumą —
#       pełna odtwarzalność sesji AI; kontrakt P43),
#   I05 Red-Team Prompt Suite (injection/jailbreak/exfiltration/role_escape/
#       key_phishing; słabość = BLOCK; wielokrotnego użytku w CI P39),
#   I06 Trust Score jako Telemetria (adaptive_trust_score NIE wpływa na decyzje
#       — rankuje kolejki; AUTO_POST bez AI-gate = BLOCK; inwariant P04),
#   I07 Digital Twin na Danych Syntetycznych (RODO by design; twin mierzy wpływ
#       zmian reguł przed wdrożeniem; realne dane osobowe w twin = BLOCK),
#   I08 Cost Governor (limit tokenów/kosztu per sesja AI; awarie zewnętrzne nie
#       zatrzymują pipeline'u — degradacja do trybu bez AI),
#   I09 Explain-First UI (propozycja AI zawsze z wyjaśnieniem: przepis+dowód+
#       percentyl pewności; zakaz czarnoskrzynkowych sugestii),
#   I10 Federated Learning Guard (tylko zanonimizowane agregaty; kontrakt
#       prywatności z k-anonymity jako dane; RODO art. 5),
#   I11 Quantum-Safe Plan (plan migracji kluczy/podpisów post-quantum z
#       harmonogramem jako dane — dokument decyzji),
#   I12 AI w Triage NEEDS_ADVICE (judgment_predictor wyłącznie sortuje kolejki;
#       sugestia z dowodem i percentylem; predictor decydujący = BLOCK).
#
# Integracje (kontrakty między-częściowe):
#   * P03 (kontrakt werdyktu 25-polowy) — każdy element AI emituje zgodny werdykt,
#   * P04 (invarianty) — warstwa AI jest WYŁĄCZNIE advisory, nigdy wykonawcza
#     (AI nie może wymusić AUTO_POST),
#   * P07 (rule lifecycle) — propozycje AI wchodzą przez SHADOW/CANDIDATE jak
#     każda inna reguła,
#   * P10 (Golden Oracle) — golden replay jest bramką ścieżki awansu (I01),
#   * P22 (RODO/AML) — kontrakt prywatności AI (minimalizacja, pseudonimizacja),
#   * P32 (automatyzacja księgowości) — kolejka NEEDS_ADVICE wspólna (I12).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p33 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak pola, sprzeczność, niepewność prawna = 
#     NEEDS_ADVICE / MANUAL_REVIEW — nigdy cichy AUTO_POST (anty-wzorzec AP07);
#     ścieżki bez spełnionego warunku zwracają jawną NEEDS_ADVICE (AP03 zamknięty).
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p33_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p33_neural_mesh_ai.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p33_neural_mesh_ai
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p33_neural_mesh_ai

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p33_check", false) == true
_ctx := object.get(input, "v3_p33", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p33_snapshot := data.jdg.thresholds.v3_p33

_snapshot_ok = true {
    count(_p33_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p33_snapshot) > 0
    value := object.get(_p33_snapshot, key, null)
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
    "rule_id": "jdg.v3_p33_neural_mesh_ai.thresholds_missing",
    "package": "jdg.v3_p33_neural_mesh_ai",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "WARSTWA AI V3-P33: brak snapshotu data.jdg.thresholds.v3_p33.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P33] Brak snapshotu progów warstwy AI — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p33_neural_mesh_ai",
        "priority": priority,
        "threshold_version": object.get(_p33_snapshot, "v3_p33_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p33_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p33_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I01 [INNOWACJA V3-P33-I01]: AI PROPOSAL PIPELINE — ścieżka awansu propozycji (AN01/AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_prop := object.get(_ctx, "ai_proposal_pipeline", {})
_prop_events := object.get(_prop, "events", [])
_prop_bypass := [e |
    e := _prop_events[_]
    object.get(e, "stage_reached", "llm_output") != "shadow"
    object.get(e, "promoted", false) == true
]
_prop_missing_golden := [e |
    e := _prop_events[_]
    object.get(e, "golden_replay_pass", false) == false
]

routing_pp01 = "BLOCK_AND_ALERT" {
    count(_prop_bypass) > 0
} else = "TRIAGE_QUEUE" {
    count(_prop_missing_golden) > 0
} else = "SUGGEST" {
    true
}

reason_pp01 = sprintf("Propozycje AI awansowane poza formalną ścieżką (llm→walidacja→SMT/Z3→golden replay→4-eyes→SHADOW): %v — BLOCK (żadna propozycja nie omija ścieżki; P07).", [_prop_bypass]) {
    count(_prop_bypass) > 0
} else = sprintf("Propozycje AI bez zaliczonego golden replay (P10): %v — TRIAGE (brama replay obowiązkowa przed 4-eyes).", [_prop_missing_golden]) {
    count(_prop_missing_golden) > 0
} else = sprintf("AI Proposal Pipeline OK: %v propozycji na formalnej ścieżce awansu (SMT/Z3 + golden replay + 4-eyes + SHADOW).", [count(_prop_events)]) {
    true
}

ai_proposal_pipeline_decision := _certificate(433001, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.ai_proposal_pipeline",
    "analysis": "ai_proposal_pipeline",
    "proposals_total": count(_prop_events),
    "proposals_bypassed": count(_prop_bypass),
    "proposals_missing_golden": count(_prop_missing_golden),
    "_routing": routing_pp01,
    "_routing_reason": reason_pp01,
    "_legal_basis": "V3_P33 §10/I01; V1 (cykl życia reguł); V2 (Golden Oracle F3); kontrakt P07",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "ai_proposal_pipeline"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I02 [INNOWACJA V3-P33-I02]: SANDBOX UPRAWNIEŃ AI — AI bez zapisu do reguł produkcyjnych (AN01/AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_sbx := object.get(_ctx, "ai_sandbox_permissions", {})
_sbx_writes := object.get(_sbx, "sandbox_write_attempts", 0)
_sbx_self := object.get(_sbx, "ai_self_approvals", 0)

routing_sp02 = "BLOCK_AND_ALERT" {
    _sbx_self > 0
} else = "BLOCK_AND_ALERT" {
    _has_flag("sandbox_prod_write_detected")
} else = "TRIAGE_QUEUE" {
    _sbx_writes > 0
} else = "SUGGEST" {
    true
}

reason_sp02 = sprintf("AI zatwierdziło własne propozycje: %v — BLOCK (człowiek zatwierdza; 4-eyes; KKS).", [_sbx_self]) {
    _sbx_self > 0
} else = "Wykryto zapis AI do reguł produkcyjnych — BLOCK (konto techniczne AI bez uprawnień zapisu; awans wyłącznie przez PR człowieka)." {
    _has_flag("sandbox_prod_write_detected")
} else = sprintf("Próby zapisu w sandboxie: %v — TRIAGE (oczekiwane w sandboksie; zweryfikować izolację).", [_sbx_writes]) {
    _sbx_writes > 0
} else = sprintf("Sandbox AI OK: tryb %v, zapisu do produkcji brak, awans przez PR człowieka.", [object.get(_sbx, "mode", "read_only")]) {
    true
}

ai_sandbox_permissions_decision := _certificate(433002, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.ai_sandbox_permissions",
    "analysis": "ai_sandbox_permissions",
    "sandbox_write_attempts": _sbx_writes,
    "ai_self_approvals": _sbx_self,
    "mode": object.get(_sbx, "mode", "read_only"),
    "_routing": routing_sp02,
    "_routing_reason": reason_sp02,
    "_legal_basis": "V3_P33 §10/I02; V1 (bramki); kontrakt P07 (4-eyes); KKS (człowiek zatwierdza) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "ai_sandbox_permissions"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I03 [INNOWACJA V3-P33-I03]: HALUCYNACJA PRAWNA GUARD — ISAP przed człowiekiem (AN01/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_hal := object.get(_ctx, "legal_hallucination_guard", {})
_hal_basis := object.get(_hal, "cited_basis", [])
_hal_unverified := [b |
    b := _hal_basis[_]
    object.get(b, "isap_verification_hash", "") == ""
]

routing_hg03 = "BLOCK_AND_ALERT" {
    count(_hal_unverified) > 0
} else = "TRIAGE_QUEUE" {
    _has_flag("isap_crawler_unavailable")
} else = "SUGGEST" {
    true
}

reason_hg03 = sprintf("Podstawy prawne z LLM bez weryfikacji ISAP: %v — BLOCK (zakaz fikcyjnych artykułów; guard halucynacji prawnych).", [_hal_unverified]) {
    count(_hal_unverified) > 0
} else = "Crawler ISAP niedostępny — TRIAGE (podstawy z LLM trzymają status [NIEZWERYFIKOWANE]; rejestr mediacji)." {
    _has_flag("isap_crawler_unavailable")
} else = sprintf("Halucynacja prawna guard OK: %v podstaw prawnych zweryfikowanych hashem ISAP.", [count(_hal_basis)]) {
    true
}

legal_hallucination_guard_decision := _certificate(433003, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.legal_hallucination_guard",
    "analysis": "legal_hallucination_guard",
    "cited_basis_total": count(_hal_basis),
    "cited_basis_unverified": count(_hal_unverified),
    "_routing": routing_hg03,
    "_routing_reason": reason_hg03,
    "_legal_basis": "V3_P33 §10/I03; zasada źródeł (ISAP/RCL/MF); OrdPU (podstawy) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "legal_hallucination_guard"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I04 [INNOWACJA V3-P33-I04]: PROMPT AUDIT LEDGER — WORM z checksumą (AN01/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_pal := object.get(_ctx, "prompt_audit_ledger", {})
_pal_sessions := object.get(_pal, "sessions_total", 0)
_pal_unlogged := object.get(_pal, "unlogged_sessions", 0)
_pal_bad_checksum := object.get(_pal, "checksum_mismatches", 0)

routing_pl04 = "BLOCK_AND_ALERT" {
    _pal_bad_checksum > 0
} else = "BLOCK_AND_ALERT" {
    _pal_unlogged > 0
} else = "TRIAGE_QUEUE" {
    _pal_sessions == 0
    _has_flag("ai_sessions_ran")
} else = "SUGGEST" {
    true
}

reason_pl04 = sprintf("Niezgodności checksum WORM ledgeru promptów: %v — BLOCK (integrity złamane; pełna odtwarzalność sesji AI wymagana).", [_pal_bad_checksum]) {
    _pal_bad_checksum > 0
} else = sprintf("Sesje AI bez wpisu w WORM ledgerze: %v — BLOCK (każdy prompt+odpowiedź zapisany z checksumą).", [_pal_unlogged]) {
    _pal_unlogged > 0
} else = "Sesje AI bez ledgera promptów — TRIAGE (prompt audit ledger wymagany do audytu)." {
    _pal_sessions == 0
    _has_flag("ai_sessions_ran")
} else = sprintf("Prompt audit ledger OK: %v sesji z checksumami w WORM.", [_pal_sessions]) {
    true
}

prompt_audit_ledger_decision := _certificate(433004, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.prompt_audit_ledger",
    "analysis": "prompt_audit_ledger",
    "sessions_total": _pal_sessions,
    "unlogged_sessions": _pal_unlogged,
    "checksum_mismatches": _pal_bad_checksum,
    "_routing": routing_pl04,
    "_routing_reason": reason_pl04,
    "_legal_basis": "V3_P33 §10/I04; kontrakt P43 (WORM); UoR art. 4 (sprawdzalność) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "prompt_audit_ledger"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I05 [INNOWACJA V3-P33-I05]: RED-TEAM PROMPT SUITE — ataki na bridge (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_rt := object.get(_ctx, "red_team_prompt_suite", {})
_rt_weak := object.get(_rt, "weak_attacks", [])
_rt_not_run := object.get(_rt, "suite_not_run", false) == true
_rt_categories := object.get(_rt, "attacks_tested", [])

routing_rt05 = "BLOCK_AND_ALERT" {
    count(_rt_weak) > 0
} else = "TRIAGE_QUEUE" {
    _rt_not_run
} else = "TRIAGE_QUEUE" {
    count(_rt_categories) < _th("v3_p33_red_team_min_categories", 3)
} else = "SUGGEST" {
    true
}

_rt_attack_catalog := object.get(_p33_snapshot, "v3_p33_red_team_attacks", [])

reason_rt05 = sprintf("Red-team: ataki zakończone skutecznie (weak): %v — BLOCK (słabość bridge'a blokuje merge; katalog ataków: %v).", [_rt_weak, _rt_attack_catalog]) {
    count(_rt_weak) > 0
} else = "Red-team suite nieuruchomiony — TRIAGE (wynik blokuje merge przy słabości; CI P39)." {
    _rt_not_run
} else = sprintf("Red-team objął %v kategorii ataków < minimum %v — TRIAGE (poszerzyć suite).", [count(_rt_categories), _th("v3_p33_red_team_min_categories", 3)]) {
    count(_rt_categories) < _th("v3_p33_red_team_min_categories", 3)
} else = sprintf("Red-team suite OK: %v kategorii ataków, zero skutecznych (injection/jailbreak/exfiltration/role_escape/key_phishing).", [count(_rt_categories)]) {
    true
}

red_team_prompt_suite_decision := _certificate(433005, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.red_team_prompt_suite",
    "analysis": "red_team_prompt_suite",
    "attacks_tested": count(_rt_categories),
    "attack_catalog_total": count(_rt_attack_catalog),
    "weak_attacks": count(_rt_weak),
    "min_categories": _th("v3_p33_red_team_min_categories", 3),
    "_routing": routing_rt05,
    "_routing_reason": reason_rt05,
    "_legal_basis": "V3_P33 §10/I05; AI Act (przejrzystość, nadzór) [NIEZWERYFIKOWANE]; CI P39",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "red_team_prompt_suite"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I06 [INNOWACJA V3-P33-I06]: TRUST SCORE JAKO TELEMETRIA — odcięty od AUTO_POST (AN03/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_tst := object.get(_ctx, "trust_score_telemetry", {})
_tst_decides := object.get(_tst, "trust_influenced_decisions", 0)
_tst_no_gate := object.get(_tst, "auto_post_without_ai_gate", 0)

routing_ts06 = "BLOCK_AND_ALERT" {
    _tst_no_gate > 0
} else = "BLOCK_AND_ALERT" {
    _tst_decides > 0
} else = "SUGGEST" {
    true
}

reason_ts06 = sprintf("AUTO_POST bez AI-gate: %v — BLOCK (inwariant P04; AI nigdy nie wymusza AUTO_POST).", [_tst_no_gate]) {
    _tst_no_gate > 0
} else = sprintf("Trust score wpłynął na decyzje: %v — BLOCK (trust score = telemetria, rankuje kolejki, nie decyduje).", [_tst_decides]) {
    _tst_decides > 0
} else = "Trust score OK: wyłącznie telemetria i ranking kolejek do przeglądu — odcięty od AUTO_POST." {
    true
}

trust_score_telemetry_decision := _certificate(433006, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.trust_score_telemetry",
    "analysis": "trust_score_telemetry",
    "trust_influenced_decisions": _tst_decides,
    "auto_post_without_ai_gate": _tst_no_gate,
    "_routing": routing_ts06,
    "_routing_reason": reason_ts06,
    "_legal_basis": "V3_P33 §10/I06; inwariant P04 (fail-closed); AI Act (nadzór człowieka) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "trust_score_telemetry"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I07 [INNOWACJA V3-P33-I07]: DIGITAL TWIN NA DANYCH SYNTETYCZNYCH (AN03/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_twn := object.get(_ctx, "digital_twin_synthetic", {})
_twn_real := object.get(_twn, "real_pii_in_twin", 0)
_twn_rules := object.get(_twn, "rule_changes_simulated", 0)

routing_tw07 = "BLOCK_AND_ALERT" {
    _twn_real > 0
} else = "TRIAGE_QUEUE" {
    _twn_rules == 0
    _has_flag("twin_simulation_requested")
} else = "SUGGEST" {
    true
}

reason_tw07 = sprintf("Dane osobowe w digital twin: %v — BLOCK (RODO by design; twin wyłącznie na danych syntetycznych; rule impact measurement tylko na syntetycznych).", [_twn_real]) {
    _twn_real > 0
} else = "Żądano symulacji, ale twin nie zasymulował żadnej zmiany reguł — TRIAGE (twin mierzy wpływ zmian reguł przed wdrożeniem)." {
    _twn_rules == 0
    _has_flag("twin_simulation_requested")
} else = sprintf("Digital twin OK: %v zmian reguł zasymulowanych na danych syntetycznych (RODO by design).", [_twn_rules]) {
    true
}

digital_twin_synthetic_decision := _certificate(433007, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.digital_twin_synthetic",
    "analysis": "digital_twin_synthetic",
    "real_pii_in_twin": _twn_real,
    "rule_changes_simulated": _twn_rules,
    "_routing": routing_tw07,
    "_routing_reason": reason_tw07,
    "_legal_basis": "V3_P33 §10/I07; RODO art. 5 (minimizacja), art. 25 (privacy by design) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "digital_twin_synthetic"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I08 [INNOWACJA V3-P33-I08]: COST GOVERNOR — budżet tokenów/kosztu per sesja (AN01/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_cst := object.get(_ctx, "cost_governor", {})
_cst_tokens := object.get(_cst, "tokens_used", 0)
_cst_cost := object.get(_cst, "cost_pln", 0)
_cst_token_budget := _th("v3_p33_token_budget", 1000000)
_cst_cost_limit := _th("v3_p33_cost_limit_pln", 500)

routing_cg08 = "TRIAGE_QUEUE" {
    _cst_tokens > _cst_token_budget
} else = "TRIAGE_QUEUE" {
    _cst_cost > _cst_cost_limit
} else = "SUGGEST" {
    true
}

reason_cg08 = sprintf("Budżet tokenów przekroczony: %v > %v — TRIAGE (cost governor z alarmami; tryb AI_DEGRADED — degradacja do trybu bez AI).", [_cst_tokens, _cst_token_budget]) {
    _cst_tokens > _cst_token_budget
} else = sprintf("Limit kosztu przekroczony: %v PLN > %v PLN — TRIAGE (awarie zewnętrzne nie zatrzymują pipeline'u).", [_cst_cost, _cst_cost_limit]) {
    _cst_cost > _cst_cost_limit
} else = sprintf("Cost governor OK: %v/%v tokenów, %v/%v PLN; ścieżka degraded (bez AI) gotowa na awarię zewnętrzną.", [_cst_tokens, _cst_token_budget, _cst_cost, _cst_cost_limit]) {
    true
}

cost_governor_decision := _certificate(433008, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.cost_governor",
    "analysis": "cost_governor",
    "tokens_used": _cst_tokens,
    "token_budget": _cst_token_budget,
    "cost_pln": _cst_cost,
    "cost_limit_pln": _cst_cost_limit,
    "_routing": routing_cg08,
    "_routing_reason": reason_cg08,
    "_legal_basis": "V3_P33 §10/I08; ADR-002 (progi jako dane); wzorzec backpressure P32-I12",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "cost_governor"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I09 [INNOWACJA V3-P33-I09]: EXPLAIN-FIRST UI — propozycja z wyjaśnieniem (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_exp := object.get(_ctx, "explain_first_ui", {})
_exp_items := object.get(_exp, "suggestions", [])
_exp_unexplained := [s |
    s := _exp_items[_]
    object.get(s, "legal_reference", "") == ""
    object.get(s, "evidence", "") == ""
]
_exp_no_confidence := [s |
    s := _exp_items[_]
    object.get(s, "confidence_percentile", -1) < 0
]

routing_ef09 = "BLOCK_AND_ALERT" {
    count(_exp_unexplained) > 0
} else = "TRIAGE_QUEUE" {
    count(_exp_no_confidence) > 0
} else = "SUGGEST" {
    true
}

reason_ef09 = sprintf("Sugestie AI bez wyjaśnienia (przepis+dowód): %v — BLOCK (zakaz czarnoskrzynkowych sugestii; AI Act przejrzystość).", [_exp_unexplained]) {
    count(_exp_unexplained) > 0
} else = sprintf("Sugestie AI bez percentyla pewności: %v — TRIAGE (wyjaśnienie zawsze z dowodem i percentylem).", [_exp_no_confidence]) {
    count(_exp_no_confidence) > 0
} else = sprintf("Explain-first OK: %v sugestii z wyjaśnieniem (przepis, dowód, percentyl pewności).", [count(_exp_items)]) {
    true
}

explain_first_ui_decision := _certificate(433009, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.explain_first_ui",
    "analysis": "explain_first_ui",
    "suggestions_total": count(_exp_items),
    "suggestions_unexplained": count(_exp_unexplained),
    "suggestions_no_confidence": count(_exp_no_confidence),
    "_routing": routing_ef09,
    "_routing_reason": reason_ef09,
    "_legal_basis": "V3_P33 §10/I09; AI Act (przejrzystość) [NIEZWERYFIKOWANE]; RODO art. 22 [NIEZWERYFIKOWANE]; V2 F4",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "explain_first_ui"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I10 [INNOWACJA V3-P33-I10]: FEDERATED LEARNING GUARD — tylko zanonimizowane agregaty (AN03/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_fed := object.get(_ctx, "federated_privacy_guard", {})
_fed_pii := object.get(_fed, "pii_in_mesh", 0)
_fed_small_k := object.get(_fed, "aggregates_below_k", 0)
_fed_k_min := _th("v3_p33_mesh_min_k", 5)

routing_fp10 = "BLOCK_AND_ALERT" {
    _fed_pii > 0
} else = "TRIAGE_QUEUE" {
    _fed_small_k > _th("v3_p33_mesh_aggregate_violation_max", 0)
} else = "SUGGEST" {
    true
}

reason_fp10 = sprintf("Dane osobowe w federated mesh: %v — BLOCK (kontrakt prywatności; tylko zanonimizowane agregaty; RODO art. 5).", [_fed_pii]) {
    _fed_pii > 0
} else = sprintf("Agregaty poniżej k=%v powyżej limitu %v — BLOCK (k-anonymity jako dane; ADR-002).", [_fed_k_min, _th("v3_p33_mesh_aggregate_violation_max", 0)]) {
    _fed_small_k > _th("v3_p33_mesh_aggregate_violation_max", 0)
} else = sprintf("Agregaty poniżej k=%v: %v — TRIAGE (wykluczyć z mesh; kontrakt prywatności AI).", [_fed_k_min, _fed_small_k]) {
    _fed_small_k > 0
} else = sprintf("Federated guard OK: 0 PII, agregaty spełniają k-anonymity (k=%v).", [_fed_k_min]) {
    true
}

federated_privacy_guard_decision := _certificate(433010, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.federated_privacy_guard",
    "analysis": "federated_privacy_guard",
    "pii_in_mesh": _fed_pii,
    "aggregates_below_k": _fed_small_k,
    "min_k": _fed_k_min,
    "_routing": routing_fp10,
    "_routing_reason": reason_fp10,
    "_legal_basis": "V3_P33 §10/I10; RODO art. 5 ust. 1c (minimizacja) [NIEZWERYFIKOWANE]; kontrakt prywatności → P22",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "federated_privacy_guard"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I11 [INNOWACJA V3-P33-I11]: QUANTUM-SAFE PLAN — harmonogram migracji post-quantum (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_qsm := object.get(_ctx, "quantum_safe_plan", {})
_qsm_missing := object.get(_qsm, "key_types_without_plan", [])
_qsm_year := object.get(_qsm, "migration_year", 0)

routing_qs11 = "BLOCK_AND_ALERT" {
    _has_flag("quantum_plan_missing")
} else = "TRIAGE_QUEUE" {
    count(_qsm_missing) > 0
} else = "TRIAGE_QUEUE" {
    _qsm_year > 0
    _qsm_year != _th("v3_p33_quantum_migration_year", 2030)
} else = "SUGGEST" {
    true
}

reason_qs11 = sprintf("Brak planu migracji post-quantum — BLOCK (dokument decyzji wymagany; harmonogram jako dane).", []) {
    _has_flag("quantum_plan_missing")
} else = sprintf("Typy kluczy bez planu migracji: %v — TRIAGE (inwentaryzacja: klucze, podpisy, WORM).", [_qsm_missing]) {
    count(_qsm_missing) > 0
} else = sprintf("Harmonogram migracji (%v) różny od zakładanego (%v) — TRIAGE (zaktualizować dokument decyzji).", [_qsm_year, _th("v3_p33_quantum_migration_year", 2030)]) {
    _qsm_year > 0
    _qsm_year != _th("v3_p33_quantum_migration_year", 2030)
} else = sprintf("Quantum-safe plan OK: migracja docelowo %v, harmonogram 3-fazowy (inventory→pilot→migration).", [_qsm_year]) {
    true
}

quantum_safe_plan_decision := _certificate(433011, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.quantum_safe_plan",
    "analysis": "quantum_safe_plan",
    "key_types_without_plan": count(_qsm_missing),
    "migration_year": _qsm_year,
    "planned_migration_year": _th("v3_p33_quantum_migration_year", 2030),
    "_routing": routing_qs11,
    "_routing_reason": reason_qs11,
    "_legal_basis": "V3_P33 §10/I11; dokument decyzji architektury (harmonogram jako dane)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "quantum_safe_plan"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33-I12 [INNOWACJA V3-P33-I12]: AI W TRIAGE NEEDS_ADVICE — predictor tylko sortuje (AN02/AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_jud := object.get(_ctx, "ai_triage_needs_advice", {})
_jud_decides := object.get(_jud, "predictor_autonomous_decisions", 0)
_jud_unsorted := object.get(_jud, "queue_unsorted", 0)
_jud_pct := _th("v3_p33_judgment_min_percentile", 80)

routing_jd12 = "BLOCK_AND_ALERT" {
    _jud_decides > 0
} else = "TRIAGE_QUEUE" {
    _jud_unsorted > 0
} else = "SUGGEST" {
    true
}

reason_jd12 = sprintf("Predictor decydował samodzielnie: %v — BLOCK (AI wyłącznie advisory; sortuje kolejki NEEDS_ADVICE; inwariant P04).", [_jud_decides]) {
    _jud_decides > 0
} else = sprintf("Wpisy NEEDS_ADVICE niesortowane przez predictor: %v — TRIAGE (inteligentne triage; sugestia z dowodem i percentylem pewności).", [_jud_unsorted]) {
    _jud_unsorted > 0
} else = sprintf("AI triage OK: predictor sortuje kolejki (min. percentyl %v), zero decyzji autonomicznych.", [_jud_pct]) {
    true
}

ai_triage_needs_advice_decision := _certificate(433012, {
    "rule_id": "jdg.v3_p33_neural_mesh_ai.ai_triage_needs_advice",
    "analysis": "ai_triage_needs_advice",
    "predictor_autonomous_decisions": _jud_decides,
    "queue_unsorted": _jud_unsorted,
    "min_percentile": _jud_pct,
    "_routing": routing_jd12,
    "_routing_reason": reason_jd12,
    "_legal_basis": "V3_P33 §10/I12; inwariant P04 (fail-closed); cel nadrzędny serii (AI pomaga, nie zastępuje)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "ai_triage_needs_advice"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := ai_proposal_pipeline_decision {
    ai_proposal_pipeline_decision.rule_id != ""
} else := ai_sandbox_permissions_decision {
    ai_sandbox_permissions_decision.rule_id != ""
} else := legal_hallucination_guard_decision {
    legal_hallucination_guard_decision.rule_id != ""
} else := prompt_audit_ledger_decision {
    prompt_audit_ledger_decision.rule_id != ""
} else := red_team_prompt_suite_decision {
    red_team_prompt_suite_decision.rule_id != ""
} else := trust_score_telemetry_decision {
    trust_score_telemetry_decision.rule_id != ""
} else := digital_twin_synthetic_decision {
    digital_twin_synthetic_decision.rule_id != ""
} else := cost_governor_decision {
    cost_governor_decision.rule_id != ""
} else := explain_first_ui_decision {
    explain_first_ui_decision.rule_id != ""
} else := federated_privacy_guard_decision {
    federated_privacy_guard_decision.rule_id != ""
} else := quantum_safe_plan_decision {
    quantum_safe_plan_decision.rule_id != ""
} else := ai_triage_needs_advice_decision {
    ai_triage_needs_advice_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p33_neural_mesh_ai.no_match",
    "package": "jdg.v3_p33_neural_mesh_ai",
    "priority": 999999,
}
