# NEXUSAI JDG — V3-P66 CHAOS I ODPORNOŚĆ (konwencja P51–P65)
# ==============================================================================
# Program chaos engineering ENTERPRISE — 12 innowacji (I01–I12; minimum z
# promptu P66 Sekcja 10):
#
#   I01 Steady state hypothesis pack — norma jako dane (metryki P58 + progi
#       ADR-002); hipoteza niekompletna = NEEDS_ADVICE.
#   I02 Experiment card standard — karta bez asercji no_silent_auto_post /
#       rollback / blast radius = BLOCK (najważniejsza asercja chaos).
#   I03 Dependency chaos matrix — zależność (MF/NBP/bank/ISAP) × tryb awarii;
#       kombinacji poniżej minimum = NEEDS_ADVICE.
#   I04 Kill switch for experiments — eksperyment ciężki (nie-CI) bez
#       wyłącznika = BLOCK; przerwanie < 1 s (P07 hot-reload).
#   I05 Chaos day calendar — harmonogram cykliczny; brak = NEEDS_ADVICE.
#   I06 Auto-rollback experiments — asercja złamana bez ścieżki rollback =
#       BLOCK (P38 healthy versions, MTTR SLA).
#   I07 Chaos maturity ladder — poziom dojrzałości niezdefiniowany =
#       NEEDS_ADVICE.
#   I08 Failure injection as data — eksperymenty jako dane (I02/I08); brak =
#       NEEDS_ADVICE.
#   I09 Chaos findings→repair register — przełamania fail-closed > 0 lub brak
#       feedu do rejestru napraw (P64) = NEEDS_ADVICE.
#   I10 Resilience trend metric — wskaźnik odporności poniżej progu = BLOCK
#       (trend kwartalny do P68).
#   I11 Peak-time chaos — szczyt deklaracji niesymulowany = NEEDS_ADVICE.
#   I12 Game day scenario pack — brak scenariusza złożonego (MF+NBP+bank) =
#       NEEDS_ADVICE.
#
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p66 — ADR-002 (P06),
#     okno temporalne valid_from (P05); zero hardcode.
#   * Fail-closed (V1 zasada 6; konwencja P51–P65): brak snapshotu progów =
#     NEEDS_ADVICE; bez flagi v3_p66_check = NO_MATCH; nigdy ciche AUTO_POST.
#   * Konwencja P54–P65: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (tools/v3_p66_engines.py czytają PRAWDZIWE źródła: karty eksperymentów
#     tools/v3_p66_experiment_cards.json, chaos_runner P18, chaos_engineering,
#     drille P43/P16, P57 chaos 8/8, P49 chaos suite, P65-I09/I08, P07 kill
#     switch SLA, deployments.json auto_rollback_armed, healthy_versions P38,
#     P58 error budget/advice spread/escalation, P64 sweep register, self-
#     healing 4-eyes, ksef offline queue/outbox, dr_orchestrator, health tiers,
#     rule_impact_simulator, digital_twin P33). Klucze w input.v3_p66
#     (I01_..–I12_..).
#   * Kontrakty: P03 (werdykt), P06 (ADR-002), P29 (raport JSON), P37/P58
#     (obserwowalność/metryki przed-po), P39 (CI), P43 (DR/chaos drill),
#     P47 (mediacje prawne), P49 (chaos input suite), P54/P57 (kolejki
#     exactly-once/rekonsylacja), P61 (integracje), P62 (playbook płatności),
#     P64 (rejestr napraw K1), P65 (narzędzia fortecy; kontrakt C2: natywne
#     testy OPA). Akty: RODO art. 32 ust. 1 pkt d (regularne testowanie
#     skuteczności środków technicznych), UoR art. 4 ust. 1 (rzetelność
#     wyliczeń w warunkach awarii), VAT art. 109e (kompletność ewidencji
#     w warunkach awaryjnych), SUS art. 47 (terminy nienaruszalne), OP art. 56
#     (odsetki — awaria nie zwalnia), KKS art. 56 (chaos jako dowód staranności)
#     — WSZYSTKIE [NIEZWERYFIKOWANE — ISAP].
#   * Aktywacja: input.jdg_entrepreneur.v3_p66_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p66_chaos_resilience.<analiza>.
#   * Priorytety: 466001–466012 (I01–I12).
#   * Pakiety importujące (main_jdg.rego): data.jdg.v3_p66_chaos_resilience →
#     final_verdict_p130 = safe_merge(final_verdict_p129, …).
# ==============================================================================

package jdg.v3_p66_chaos_resilience

# ── Kontrakt wejściowy ────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p66_check", false) == true
_ctx := object.get(input, "v3_p66", {})

# ── Snapshot progów (ADR-002) ─────────────────────────────────────────────────
_p66_snapshot := data.jdg.thresholds.v3_p66

_snapshot_ok = true {
	count(_p66_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p66_snapshot) > 0
	value := object.get(_p66_snapshot, key, null)
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
	"rule_id": "jdg.v3_p66_chaos_resilience.thresholds_missing",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P66 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Steady state hypothesis pack ─────────────────────────────────────────
# Hipoteza normy bez metryk bazowych ze zweryfikowanymi źródłami = NEEDS_ADVICE
# — eksperyment bez mierzalnej normy nie dowodzi odporności (RODO art. 32:
# regularne testowanie skuteczności).
i01_steady_state := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.steady_state_hypothesis",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466001,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("steady state: hipoteza=%v, metryk bazowych=%v, brakujące źródła=%v — norma musi być mierzalna przed/po eksperymentem", [hypothesis, metrics, missing]),
	"metrics": {"hypothesis": hypothesis, "baseline_metrics": metrics, "missing_sources": missing},
	"_legal_basis": "RODO art. 32 ust. 1 pkt d [NIEZWERYFIKOWANE — ISAP]; P58 metryki; prompt P66 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_steady_state", {})
	hypothesis := object.get(_ctx_i01, "hypothesis_present", false)
	metrics := object.get(_ctx_i01, "baseline_metrics", 0)
	missing := object.get(_ctx_i01, "baseline_sources_missing", [])
	min_metrics := _th("v3_p66_steady_state_metrics_min", 4)
	_not(hypothesis)
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.steady_state_hypothesis",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466001,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("steady state: metryk bazowych=%v (min %v), brakujące źródła=%v — norma bez źródeł jest deklaratywna", [metrics, min_metrics, missing]),
	"metrics": {"baseline_metrics": metrics, "min": min_metrics, "missing_sources": missing},
	"_legal_basis": "P58 metryki przed/po; prompt P66 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_steady_state", {})
	min_metrics := _th("v3_p66_steady_state_metrics_min", 4)
	metrics := object.get(_ctx_i01, "baseline_metrics", 0)
	missing := object.get(_ctx_i01, "baseline_sources_missing", [])
	metrics < min_metrics
}

# ── I02: Experiment card standard ─────────────────────────────────────────────
# Karta eksperymentu bez asercji no_silent_auto_post / rollback / blast radius
# = BLOCK — eksperyment bez asercji i wycofania jest eksperymentem na fortency
# bez siatki bezpieczeństwa (najważniejsza asercja: AP07 zero cichych AUTO_POST).
i02_experiment_cards := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.experiment_card_standard",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466002,
	"decision": "BLOCK",
	"reason": sprintf("karty eksperymentów: %v niekompletnych z %v (braki: %v) — każda karta: hipoteza, asercje (zero cichych AUTO_POST), rollback, blast radius", [incomplete_n, cards_n, incomplete_ids]),
	"metrics": {"cards": cards_n, "incomplete": incomplete_n, "ids": incomplete_ids},
	"_legal_basis": "UoR art. 4 ust. 1 (rzetelność w warunkach awarii) [NIEZWERYFIKOWANE — ISAP]; AP07; prompt P66 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_experiment_cards", {})
	required_sections := _th("v3_p66_card_sections_required", ["hypothesis", "assertions", "rollback"])
	cards_n := object.get(_ctx_i02, "cards_total", 0)
	incomplete_n := object.get(_ctx_i02, "cards_incomplete_count", 0)
	incomplete_list := object.get(_ctx_i02, "cards_incomplete", [])
	incomplete_ids := [c.id | some i; c := incomplete_list[i]]
	count(required_sections) >= 3
	incomplete_n > 0
}

# ── I03: Dependency chaos matrix ──────────────────────────────────────────────
# Kombinacji zależność×tryb poniżej minimum = NEEDS_ADVICE — macierz MF/NBP/
# bank/ISAP musi pokrywać timeout/error/halt (P61 integracje).
i03_dependency_matrix := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.dependency_chaos_matrix",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466003,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("macierz zależności: %v kombinacji (min %v), tryby awarii=%v — MF/NBP/bank/ISAP × timeout/error/halt", [combos, min_combos, modes]),
	"metrics": {"combinations": combos, "min": min_combos, "modes": modes},
	"_legal_basis": "P61 integracje; SUS art. 47 (terminy) [NIEZWERYFIKOWANE — ISAP]; prompt P66 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_dependency_matrix", {})
	min_combos := _th("v3_p66_dependency_combinations_min", 12)
	modes := _th("v3_p66_dependency_failure_modes", ["timeout", "error", "halt"])
	combos := object.get(_ctx_i03, "combinations_tested", 0)
	count(modes) >= 3
	combos < min_combos
}

# ── I04: Kill switch for experiments ──────────────────────────────────────────
# Eksperyment ciężki (poza CI) bez wyłącznika = BLOCK — blast radius bez kill
# switcha to eksperyment na produkcji bez siatki (P07: pauza < 1 s).
i04_kill_switch := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.kill_switch_experiments",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466004,
	"decision": "BLOCK",
	"reason": sprintf("kill switch: ciężkie eksperymenty=%v, wyłącznik zdefiniowany=%v, narzędzie P07=%v — eksperyment poza CI wymaga przerwania < 1 s", [heavy, defined, tool]),
	"metrics": {"heavy_experiments": heavy, "kill_switch_defined": defined, "p07_tool": tool},
	"_legal_basis": "P07 kill-switch SLA (hot-reload < 1 s); prompt P66 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_kill_switch", {})
	heavy := count(object.get(_ctx_i04, "heavy_experiments", []))
	defined := object.get(_ctx_i04, "experiment_kill_switch_defined", false)
	tool := object.get(_ctx_i04, "kill_switch_tool_present", false)
	heavy > 0
	_not(defined)
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.kill_switch_experiments",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466004,
	"decision": "BLOCK",
	"reason": sprintf("kill switch: narzędzie P07 obecne=%v, ciężkie eksperymenty=%v — wyłącznik eksperymentów bez narzędzia to deklaracja", [tool, heavy]),
	"metrics": {"p07_tool": tool, "heavy_experiments": heavy},
	"_legal_basis": "P07 kill-switch SLA; prompt P66 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_kill_switch", {})
	heavy := count(object.get(_ctx_i04, "heavy_experiments", []))
	tool := object.get(_ctx_i04, "kill_switch_tool_present", false)
	heavy > 0
	_not(tool)
}

# ── I05: Chaos day calendar ───────────────────────────────────────────────────
# Harmonogram cykliczny chaos = NEEDS_ADVICE gdy brak — odporność ćwiczona,
# nie deklarowana (program ciągły, nie jednorazowy).
i05_chaos_day := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.chaos_day_calendar",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("chaos day: harmonogram=%v, cykl=%v — eksperymenty jednorazowe nie utrzymują odporności", [scheduled, cadence]),
	"metrics": {"scheduled": scheduled, "cadence": cadence},
	"_legal_basis": "P39 CI; prompt P66 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_chaos_day", {})
	scheduled := object.get(_ctx_i05, "chaos_day_scheduled", false)
	cadence := _th("v3_p66_chaos_day_cadence", "monthly")
	_not(scheduled)
}

# ── I06: Auto-rollback experiments ────────────────────────────────────────────
# Karta bez rollbacku przy złamanej asercji = BLOCK — zero eksperymentów
# pozostawionych w złym stanie (P38 healthy versions, auto_rollback_armed).
i06_auto_rollback := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.auto_rollback_experiments",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466006,
	"decision": "BLOCK",
	"reason": sprintf("auto-rollback: kart z rollbackiem=%v z %v — asercja złamana bez ścieżki cofnięcia = eksperyment w złym stanie (SLA %v min)", [with_rb, cards_n, sla_min]),
	"metrics": {"with_rollback": with_rb, "cards": cards_n, "sla_min": sla_min},
	"_legal_basis": "P38 bundle deploy (auto-rollback); UoR art. 4 ust. 1 [NIEZWERYFIKOWANE — ISAP]; prompt P66 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_auto_rollback", {})
	cards_n := object.get(_ctx_i06, "cards_total", 0)
	with_rb := object.get(_ctx_i06, "cards_with_rollback", 0)
	sla_min := _th("v3_p66_auto_rollback_sla_min", 5)
	with_rb < cards_n
}

# ── I07: Chaos maturity ladder ────────────────────────────────────────────────
# Poziom dojrzałości niezdefiniowany = NEEDS_ADVICE — ścieżka rozwoju odporności
# musi być mierzalna (L1 CI → L5 produkcja z kill switchem).
i07_maturity := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.chaos_maturity_ladder",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466007,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("maturity ladder: poziomy zdefiniowane=%v, bieżący=%v — ścieżka dojrzałości musi być jawna", [levels, current]),
	"metrics": {"levels": levels, "current": current},
	"_legal_basis": "prompt P66 Sekcja 10-I07",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_maturity", {})
	ladder := _th("v3_p66_maturity_levels", [])
	levels := count(object.get(_ctx_i07, "ladder_levels", ladder))
	current := object.get(_ctx_i07, "current_level", "")
	count(ladder) >= 3
	levels < 3
}

# ── I08: Failure injection as data ────────────────────────────────────────────
# Eksperymenty nie jako dane = NEEDS_ADVICE — nowe scenariusze bez kodu
# (ADR-002 zastosowany do awarii; I02/I08 kontrakt kart).
i08_injection_data := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.failure_injection_as_data",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466008,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("injection as data: karty=%v, nowe bez kodu=%v — definicje awarii jako dane (JSON), nie tylko w kodzie runnera", [cards, new]),
	"metrics": {"cards": cards, "new_without_code": new},
	"_legal_basis": "ADR-002 parametry-as-data; prompt P66 Sekcja 10-I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_injection_as_data", {})
	cards := object.get(_ctx_i08, "cards_total", 0)
	new := object.get(_ctx_i08, "new_scenarios_without_code", 0)
	as_data := object.get(_ctx_i08, "experiments_as_data", false)
	_not(as_data)
}

# ── I09: Chaos findings → repair register ─────────────────────────────────────
# Przełamanie fail-closed wykryte chaosem albo brak feedu do rejestru napraw =
# NEEDS_ADVICE — chaos karmi proces naprawczy (P64 rejestr z SLA).
i09_findings := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.chaos_findings_to_repairs",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("findings→repairs: przełamania fail-closed=%v, feed do rejestru=%v — każda luka chaos wchodzi do rejestru napraw z SLA (P64)", [violations, feed]),
	"metrics": {"violations": violations, "feed_present": feed},
	"_legal_basis": "AP07 cichy AUTO_POST; P64 rejestr rezydualny; prompt P66 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_findings", {})
	violations := object.get(_ctx_i09, "fail_closed_violations_total", 0)
	feed := object.get(_ctx_i09, "feed_to_repair_register", false)
	violations > 0
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.chaos_findings_to_repairs",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("findings→repairs: feed do rejestru napraw=%v — wykryte luki bez ścieżki naprawy giną po sesji", [feed]),
	"metrics": {"feed_present": feed},
	"_legal_basis": "P64 kontrakt K1 (rejestr z SLA); prompt P66 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_findings", {})
	feed := object.get(_ctx_i09, "feed_to_repair_register", false)
	_not(feed)
}

# ── I10: Resilience trend metric ──────────────────────────────────────────────
# Wskaźnik odporności poniżej progu = BLOCK — trend kwartalny do re-certyfikacji
# P68 (eksperymenty zaliczone / wszystkie, waga asercji rdzeniowej).
i10_resilience := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.resilience_trend",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466010,
	"decision": "BLOCK",
	"reason": sprintf("wskaźnik odporności: %v%% (próg %v%%) — trend kwartalny do P68; blokada aż do progu", [pct, min_pct]),
	"metrics": {"resilience_pct": pct, "min_pct": min_pct},
	"_legal_basis": "P58 metryki; RODO art. 32 (skuteczność środków) [NIEZWERYFIKOWANE — ISAP]; prompt P66 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_resilience_trend", {})
	min_pct := _th("v3_p66_resilience_min_pct", 80)
	pct := object.get(_ctx_i10, "resilience_pct", 0)
	pct < min_pct
}

# ── I11: Peak-time chaos ──────────────────────────────────────────────────────
# Szczyt deklaracji niesymulowany = NEEDS_ADVICE — najgorszy moment (prawdo-
# podobieństwo × koszt masowych błędnych deklaracji) testowany świadomie.
i11_peak_time := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.peak_time_chaos",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466011,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("peak-time chaos: eksperyment szczytowy=%v, środowisko=%v — MF w szczycie = najwyższy koszt (masowe błędne deklaracje)", [present, env]),
	"metrics": {"peak_present": present, "environment": env},
	"_legal_basis": "VAT art. 109e (kompletność w warunkach awaryjnych) [NIEZWERYFIKOWANE — ISAP]; prompt P66 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_peak_time", {})
	present := object.get(_ctx_i11, "peak_experiment_present", false)
	env := object.get(_ctx_i11, "simulation_env", "")
	_not(present)
}

# ── I12: Game day scenario pack ───────────────────────────────────────────────
# Brak scenariusza awarii złożonej = NEEDS_ADVICE — trening zespołu (MF+NBP+
# bank jednocześnie), nie tylko systemu (KKS art. 56: dowód staranności).
i12_game_day := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.game_day_pack",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 466012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("game day: scenariusz złożony=%v, zależności=%v — awaria wielodomenowa testowana z zespołem (kill switch obowiązkowy)", [present, deps]),
	"metrics": {"game_day_present": present, "compound_dependencies": deps},
	"_legal_basis": "KKS art. 56 (staranność) [NIEZWERYFIKOWANE — ISAP]; prompt P66 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_game_day", {})
	present := object.get(_ctx_i12, "game_day_present", false)
	deps := object.get(_ctx_i12, "compound_dependencies", [])
	_not(present)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P65):
# najpierw BLOCK, potem NEEDS_ADVICE, na końcu PASS.
# Bez flagi v3_p66_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i02_experiment_cards {
	_snapshot_ok
	_activated
	i02_experiment_cards.decision == "BLOCK"
} else := i04_kill_switch {
	_snapshot_ok
	_activated
	i04_kill_switch.decision == "BLOCK"
} else := i06_auto_rollback {
	_snapshot_ok
	_activated
	i06_auto_rollback.decision == "BLOCK"
} else := i10_resilience {
	_snapshot_ok
	_activated
	i10_resilience.decision == "BLOCK"
} else := i01_steady_state {
	_snapshot_ok
	_activated
	i01_steady_state.decision == "NEEDS_ADVICE"
} else := i03_dependency_matrix {
	_snapshot_ok
	_activated
	i03_dependency_matrix.decision == "NEEDS_ADVICE"
} else := i05_chaos_day {
	_snapshot_ok
	_activated
	i05_chaos_day.decision == "NEEDS_ADVICE"
} else := i07_maturity {
	_snapshot_ok
	_activated
	i07_maturity.decision == "NEEDS_ADVICE"
} else := i08_injection_data {
	_snapshot_ok
	_activated
	i08_injection_data.decision == "NEEDS_ADVICE"
} else := i09_findings {
	_snapshot_ok
	_activated
	i09_findings.decision == "NEEDS_ADVICE"
} else := i11_peak_time {
	_snapshot_ok
	_activated
	i11_peak_time.decision == "NEEDS_ADVICE"
} else := i12_game_day {
	_snapshot_ok
	_activated
	i12_game_day.decision == "NEEDS_ADVICE"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p66_chaos_resilience.no_match",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P66 niewyzwolony (brak flagi v3_p66_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P65",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p66_chaos_resilience.all_green",
	"package": "jdg.v3_p66_chaos_resilience",
	"priority": 1,
	"decision": "PASS",
	"reason": "P66: program chaos i odporności domknięty (12 analiz: steady state jako dane, standard kart eksperymentów z asercją zero cichych AUTO_POST, macierz zależności MF/NBP/bank/ISAP, kill switch eksperymentów, kalendarz chaos day, auto-rollback, drabina dojrzałości, awarie jako dane, luki chaos→rejestr napraw, wskaźnik odporności, chaos w szczycie, game day złożony)",
	"metrics": {"analyses": 12},
	"_legal_basis": "RODO art. 32 ust. 1 pkt d; UoR art. 4 ust. 1; VAT art. 109e; SUS art. 47; OP art. 56; KKS art. 56 [NIEZWERYFIKOWANE — ISAP]; prompt P66 Sekcja 10",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
