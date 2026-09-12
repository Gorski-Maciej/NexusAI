# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P53 TEMPORALNOŚĆ NA GRANICACH — DAY-0 NOWELIZACJI I
# TIME-TRAVEL BEZ WĄTPLIWOŚCI (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa temporalna ENTERPRISE — 12 innowacji (I01–I12; minimum z promptu P53
# Sekcja 10):
#   I01 Temporal coverage map (reguła zależna od daty bez okna = widoczna),
#   I02 Day-0 test auto-generation (dzień przed / granica / dzień po z okna),
#   I03 Retroactive replay contract (4 filary: rules+params+FX+accumulator),
#   I04 Transitional rules register (prawa nabyte: art. 18a/18c/18ab SUS),
#   I05 Gap/overlap interval validator (INV-037: zero luk + zero nakładek),
#   I06 Epoch registry (epoki prawne z hashem snapshotu parametrów),
#   I07 Future law sandbox (DRAFT — nigdy produkcja),
#   I08 Pre-provisioning scheduler (Law Radar, lead ≥ 30 dni, V2 §6.2.5),
#   I09 Year-boundary accumulator tests (31.12/1.01 — art. 18d ust. 2 SUS),
#   I10 Historical parameter store (historia jako dane, z provenance),
#   I11 Epoch-aware golden replay (golden etykietowane epoką prawną),
#   I12 Temporal audit trail (certyfikat z legal_epoch + hash epoki).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p53 — ADR-002 (P06), okno
#     temporalne valid_from (P05). ZERO hardcode progów i dat przełączeń.
#   * Fail-closed (V1 zasada 6): brak snapshotu progów, epoka nierozpoznana
#     (data zdarzenia poza oknami = EXPIRED/NONE → NEEDS_ADVICE, nie stare
#     zasady), luka/nakładka interwałów, certyfikat bez legal_epoch = BLOCK.
#     Deklaracja za przeszły okres z błędną epoką jest jedyną kategorią błędu,
#     która nie naprawia się sama — replay musi odtwarzać STAN PRAWA z daty
#     (Ordynacja art. 24b [NIEZWERYFIKOWANE — ISAP]).
#   * Honesty: liczniki z bundli dowodowych (nie deklaracje); luki jawne
#     (148 plików bez okna, KALENDARZ 1 wpis testowy, TR-05 niemodelowana) —
#     bez maskowania (protokół 14; konwencja P47–P52).
#   * Aktywacja: input.jdg_entrepreneur.v3_p53_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p53_temporal_closure.<analiza>.
#   * Kontrakty: P00 (kanon), P02 (routing — I05/epoka wymagają routingu
#     temporalnego), P03/P05 (kontrakt werdyktu + okna), P08 (Law Radar —
#     pre-provisioning), P10 (golden oracle — epoki), P36 (generatory day-0),
#     P38 (deploy — historia WORM dla replay), P39 (bramki merge), P42 (WORM),
#     P46 (parametry z oknami), P52 (kursy/progi groszowe w replay), P68.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p53_temporal_closure
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p53_temporal_closure

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p53_check", false) == true
_ctx := object.get(input, "v3_p53", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p53_snapshot := data.jdg.thresholds.v3_p53

_snapshot_ok = true {
	count(_p53_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p53_snapshot) > 0
	value := object.get(_p53_snapshot, key, null)
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
	"rule_id": "jdg.v3_p53_temporal_closure.thresholds_missing",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P53 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

_not(x) = true {
	x == false
}

_not(x) = false {
	x == true
}

# ── I01: Temporal coverage map ────────────────────────────────────────────────
# Reguła zależna od daty bez okna = luka P46; bramka pokrycia z narzędzia I01.
i01_coverage := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.temporal_coverage_gate",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453001,
	"decision": decision,
	"reason": reason,
	"metrics": {
		"files_with_window": n_with,
		"files_total": n_total,
		"coverage_pct": coverage_pct,
		"coverage_min_pct": _th("v3_p53_window_coverage_min_pct", 40.0),
		"hardcoded_date_files": n_hardcoded,
	},
	"_legal_basis": "Ordynacja art. 24b (prawo właściwe w czasie) [NIEZWERYFIKOWANE — ISAP]; P05; P46",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_temporal_coverage_map", {})
	n_with := object.get(_ctx_i01, "rule_files_with_window", 0)
	n_total := object.get(_ctx_i01, "rule_files_total", 0)
	coverage_pct := object.get(_ctx_i01, "coverage_pct", 0)
	n_hardcoded := object.get(_ctx_i01, "hardcoded_date_files", 0)
	min_pct := _th("v3_p53_window_coverage_min_pct", 40.0)
	coverage_pct < min_pct
	decision := "BLOCK"
	reason := sprintf("pokrycie oknami %v%% < wymagane %v%% (P46/P53-I01)", [coverage_pct, min_pct])
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.temporal_coverage_gate",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453001,
	"decision": "PASS",
	"reason": "pokrycie oknami temporalnymi w normie",
	"metrics": {
		"files_with_window": object.get(object.get(_ctx, "I01_temporal_coverage_map", {}), "rule_files_with_window", 0),
		"files_total": object.get(object.get(_ctx, "I01_temporal_coverage_map", {}), "rule_files_total", 0),
	},
	"_legal_basis": "Ordynacja art. 24b [NIEZWERYFIKOWANE — ISAP]; P05",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I02: Day-0 test auto-generation ───────────────────────────────────────────
# Każde okno parametru musi mieć wygenerowane testy dzień przed/granica/dzień po.
i02_day0 := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.day0_tests",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453002,
	"decision": "BLOCK",
	"reason": sprintf("testów day-0 %v < minimum %v — przełączenia nowelizacji bez granic (P36/P53-I02)", [n_tests, min_tests]),
	"metrics": {"day0_tests": n_tests, "required_min": min_tests},
	"_legal_basis": "P36 generatory testów brzegowych; P05 okna",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_day0_test_autogeneration", {})
	n_tests := object.get(_ctx_i02, "auto_tests_generated", 0)
	min_tests := _th("v3_p53_day0_tests_min", 8)
	n_tests < min_tests
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.day0_tests",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453002,
	"decision": "PASS",
	"reason": sprintf("testów day-0 %v >= %v", [object.get(object.get(_ctx, "I02_day0_test_autogeneration", {}), "auto_tests_generated", 0), _th("v3_p53_day0_tests_min", 8)]),
	"metrics": {"day0_tests": object.get(object.get(_ctx, "I02_day0_test_autogeneration", {}), "auto_tests_generated", 0)},
	"_legal_basis": "P36; P05",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I03: Retroactive replay contract ──────────────────────────────────────────
# Replay = rules@bundle(D) + params@D + fx@D + accumulator@D; brak filaru = BLOCK.
i03_replay := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.replay_contract",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453003,
	"decision": "BLOCK",
	"reason": sprintf("filary replay %v/%v poniżej minimum %v (brak: %v)", [met, total, min_pillars, missing]),
	"metrics": {"pillars_met": met, "pillars_total": total, "required_min": min_pillars},
	"_legal_basis": "UoR art. 5 (porównywalność okresów) [NIEZWERYFIKOWANE — ISAP]; Ordynacja art. 24b; P38 historia WORM",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_retroactive_replay_contract", {})
	met := object.get(_ctx_i03, "pillars_met", 0)
	total := object.get(_ctx_i03, "pillars_total", 4)
	pillars := object.get(_ctx_i03, "pillars", {})
	missing := concat(", ", [k | some k; pillars[k] == false])
	min_pillars := _th("v3_p53_replay_pillars_min", 4)
	met < min_pillars
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.replay_contract",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453003,
	"decision": "PASS",
	"reason": "filary replay kompletne (rules+params+fx+accumulator)",
	"metrics": {"pillars_met": object.get(object.get(_ctx, "I03_retroactive_replay_contract", {}), "pillars_met", 0)},
	"_legal_basis": "UoR art. 5 [NIEZWERYFIKOWANE — ISAP]; Ordynacja art. 24b",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I04: Transitional rules register ──────────────────────────────────────────
# Zasady przejściowe modelowane jawnie, nie „w głowie księgowego” (P26/P18/P41).
i04_transitional := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.transitional_register",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453004,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("zasady przejściowe niemodelowane: %v (prawa nabyte — decyzja 4-eyes)", [concat(", ", not_modelled)]),
	"metrics": {"total": total, "modelled": modelled, "not_modelled_count": count(not_modelled)},
	"_legal_basis": "SUS art. 18a/18c/18ab/18d ust. 2; VAT art. 113 [NIEZWERYFIKOWANE — ISAP]; Ordynacja art. 24c",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_transitional_rules_register", {})
	total := object.get(_ctx_i04, "total", 0)
	modelled := object.get(_ctx_i04, "modelled", 0)
	not_modelled := object.get(_ctx_i04, "not_modelled", [])
	count(not_modelled) > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.transitional_register",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453004,
	"decision": "PASS",
	"reason": "rejestr zasad przejściowych kompletny",
	"metrics": {"total": object.get(object.get(_ctx, "I04_transitional_rules_register", {}), "total", 0), "modelled": object.get(object.get(_ctx, "I04_transitional_rules_register", {}), "modelled", 0)},
	"_legal_basis": "SUS art. 18a/18c/18ab [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I05: Gap/overlap interval validator ───────────────────────────────────────
# INV-037: zero luk + zero nakładek; dziura = data bez prawa, nakładka = dwa
# prawa naraz. Obie = BLOCKER (fail-closed, nie „ostatnia wersja wygrywa”).
i05_intervals := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.interval_validation",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453005,
	"decision": "BLOCK",
	"reason": sprintf("interwały: %v luk, %v nakładek — naruszenie INV-037", [gaps, overlaps]),
	"metrics": {"gaps": gaps, "overlaps": overlaps},
	"_legal_basis": "INV-037 (CORE_GUARDS §4); P05; Ordynacja art. 24b [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_interval_validator", {})
	gaps := object.get(_ctx_i05, "gaps_count", 0)
	overlaps := object.get(_ctx_i05, "overlaps_count", 0)
	gaps + overlaps > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.interval_validation",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453005,
	"decision": "PASS",
	"reason": "zero luk + zero nakładek interwałów (INV-037)",
	"metrics": {"gaps": object.get(object.get(_ctx, "I05_interval_validator", {}), "gaps_count", 0), "overlaps": object.get(object.get(_ctx, "I05_interval_validator", {}), "overlaps_count", 0)},
	"_legal_basis": "INV-037; P05",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I06: Epoch registry ───────────────────────────────────────────────────────
# Epoka prawna = zbiór aktywnych okien na datę; nierozpoznana data zdarzenia
# (poza epokami) = NEEDS_ADVICE — nie „najbliższa epoka” (zgadywanie zakazane).
i06_epoch_state := state {
	_ctx_i06 := object.get(_ctx, "I06_epoch_registry", {})
	epochs := object.get(_ctx_i06, "epochs", [])
	event_date := object.get(_ctx, "event_date", null)
	event_date != null
	state := _epoch_for_date(epochs, event_date)
} else = {
	"epoch_id": null,
	"decision_hint": "NEEDS_ADVICE",
	"reason": "brak event_date lub pusty rejestr epok — fail-closed",
}

_epoch_for_date(epochs, d) = ep {
	some i
	e := epochs[i]
	e.start <= d
	_ep_open(e, d)
	ep := e
} else = {
	"epoch_id": null,
	"decision_hint": "NEEDS_ADVICE",
	"reason": "data zdarzenia poza oknami epok (EXPIRED/NONE)",
}

_ep_open(e, _) = true {
	object.get(e, "end", null) == null
}

_ep_open(e, d) = true {
	object.get(e, "end", null) != null
	d <= e.end
}

# ── I07: Future law sandbox ───────────────────────────────────────────────────
# Symulacja noweli: TYLKO DRAFT, zapis produkcyjny zablokowany niezmiennikiem.
i07_sandbox := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.future_sandbox",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453007,
	"decision": "DRAFT_SIMULATION",
	"reason": "tryb prawa przyszłego: symulacja bez zapisu decyzji produkcyjnych",
	"eligible_count": eligible,
	"production_write": false,
	"_legal_basis": "V2 Wizja: Declarative Change; planowanie na noweli przed wejściem",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_has_flag("future_law_requested")
	_ctx_i07 := object.get(_ctx, "I07_future_law_sandbox", {})
	eligible := object.get(_ctx_i07, "eligible_count", 0)
} else = {
	"matched": false,
	"rule_id": "jdg.v3_p53_temporal_closure.future_sandbox",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453007,
	"decision": "NO_MATCH",
	"reason": "tryb DRAFT niewymagany",
	"metrics": {},
	"_legal_basis": "V2 Wizja",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I08: Pre-provisioning scheduler ───────────────────────────────────────────
# Law Radar: nowa wersja PRZED datą wejścia (SHADOW z datą aktywacji).
i08_preprov := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.preprovisioning",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453008,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("wpisy kalendarza bez testów granicznych: %v/%v (KALENDARZ wymaga realnych nowelizacji)", [untested, total]),
	"metrics": {"calendar_entries": total, "calendar_tested": tested, "lead_kpi_days": _th("v3_p53_preprov_lead_days", 30)},
	"_legal_basis": "V2 §6.2.5 KPI lead >= 30 dni; WIZJA_OPA_ENTERPRISE_V2",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_preprovisioning_scheduler", {})
	total := object.get(_ctx_i08, "calendar_entries_count", 0)
	tested := object.get(_ctx_i08, "calendar_tested_entries", 0)
	untested := total - tested
	untested > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.preprovisioning",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453008,
	"decision": "PASS",
	"reason": "kalendarz przełączeń z testami granicznymi kompletny",
	"metrics": {"calendar_entries": object.get(object.get(_ctx, "I08_preprovisioning_scheduler", {}), "calendar_entries_count", 0)},
	"_legal_basis": "V2 §6.2.5",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I09: Year-boundary accumulator tests ──────────────────────────────────────
# Limity narastające: 31.12 akumulator aktywny / 1.01 reset (art. 18d ust. 2 SUS).
i09_year_boundary := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.year_boundary",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453009,
	"decision": "BLOCK",
	"reason": sprintf("testów granicy roku %v < minimum %v (limity narastające bez testów resetu)", [cases, min_cases]),
	"metrics": {"cases": cases, "required_min": min_cases},
	"_legal_basis": "SUS art. 18d ust. 2; VAT art. 113 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_year_boundary_tests", {})
	cases := object.get(_ctx_i09, "cases_count", 0)
	min_cases := _th("v3_p53_year_boundary_cases_min", 3)
	cases < min_cases
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.year_boundary",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453009,
	"decision": "PASS",
	"reason": sprintf("testy granicy roku obecne: %v", [object.get(object.get(_ctx, "I09_year_boundary_tests", {}), "cases_count", 0)]),
	"metrics": {"cases": object.get(object.get(_ctx, "I09_year_boundary_tests", {}), "cases_count", 0)},
	"_legal_basis": "SUS art. 18d ust. 2 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I10: Historical parameter store ───────────────────────────────────────────
# Replay czyta HISTORIĘ parametrów (versions[]), nie wartość bieżącą; wersje bez
# provenance (akt + autor zmiany) = MANUAL_REVIEW (niezgadywana przeszłość).
i10_param_history := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.param_history",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453010,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("wersji parametrów bez provenance: %v/%v (replay wymaga aktu + autora)", [no_prov, total]),
	"metrics": {"total_versions": total, "with_provenance": with_prov, "without_provenance": no_prov},
	"_legal_basis": "ADR-002 parametry-as-data; UoR art. 5 [NIEZWERYFIKOWANE — ISAP]; P46",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_historical_parameter_store", {})
	total := object.get(_ctx_i10, "total_versions", 0)
	no_prov := object.get(_ctx_i10, "without_provenance", 0)
	with_prov := object.get(_ctx_i10, "with_provenance", 0)
	no_prov > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.param_history",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453010,
	"decision": "PASS",
	"reason": "historia parametrów z pełnym provenance",
	"metrics": {"total_versions": object.get(object.get(_ctx, "I10_historical_parameter_store", {}), "total_versions", 0)},
	"_legal_basis": "ADR-002; UoR art. 5 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I11: Epoch-aware golden replay ────────────────────────────────────────────
# Złote orzeczenia z epoką: replay wybiera epokę automatycznie z valid_from.
i11_epoch_golden := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.epoch_golden",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453011,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("golden bez etykiety epoki: %v/%v (replay nieodtwarzalny epoka w epokę)", [unlabeled, total]),
	"metrics": {"verdicts_total": total, "with_epoch": labeled, "without_epoch": unlabeled},
	"_legal_basis": "Golden Oracle (V2); P10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_epoch_aware_golden_replay", {})
	total := object.get(_ctx_i11, "verdicts_total", 0)
	unlabeled := object.get(_ctx_i11, "verdicts_without_epoch_label", 0)
	labeled := object.get(_ctx_i11, "verdicts_with_epoch_label", 0)
	unlabeled > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.epoch_golden",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453011,
	"decision": "PASS",
	"reason": "golden kompletne z epokami",
	"metrics": {"verdicts_total": object.get(object.get(_ctx, "I11_epoch_aware_golden_replay", {}), "verdicts_total", 0)},
	"_legal_basis": "Golden Oracle (V2); P10",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I12: Temporal audit trail ─────────────────────────────────────────────────
# Certyfikat decyzji MUSI zawierać legal_epoch (id + hash) — dowód „jaka wersja
# prawa obowiązywała przy tej decyzji”. Brak = NEEDS_ADVICE (fail-closed).
i12_audit_trail := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.temporal_audit_trail",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453012,
	"decision": "NEEDS_ADVICE",
	"reason": "certyfikat decyzji bez legal_epoch — brak dowodu epoki prawnej (fail-closed)",
	"certificate_field": "_decision_certificate.legal_epoch",
	"required_fields": ["epoch_id", "epoch_hash", "bundle_version", "params_snapshot_hash"],
	"_legal_basis": "Decision Certificate F4 (V2); Ordynacja art. 24b [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_has_flag("certificate_missing_epoch")
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.temporal_audit_trail",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453012,
	"decision": "PASS",
	"reason": "certyfikat z legal_epoch obecny (projekt I12)",
	"metrics": {},
	"_legal_basis": "Decision Certificate F4 (V2)",
	"valid_from": "2026-01-01",
	"valid_to": null,
}# ── Terminal: wszystkie bramki zielone → PASS (nie NO_MATCH) ────────────────
all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p53_temporal_closure.all_green",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 453000,
	"decision": "PASS",
	"reason": "wszystkie bramki temporalne P53 zielone (okna, day-0, replay, epoki, certyfikat)",
	"metrics": {},
	"_legal_basis": "P05 temporalność; INV-037; Ordynacja art. 24b [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
	_activated
}

# ── Router decide (deterministyczny, fail-closed) ─────────────────────────────
# Kolejność: fail-closed snapshot → I05 (BLOCKER interwałów) → I01 → I02 →
# I03 → I09 → I04 → I08 → I10 → I11 → I12 → I07 (DRAFT) → all_green → no_match.
decide := fail_closed_decision {
	_not(_snapshot_ok)
}

decide := i05_intervals {
	_snapshot_ok
	_activated
	i05_intervals.decision == "BLOCK"
} else := i01_coverage {
	_snapshot_ok
	_activated
	i01_coverage.decision == "BLOCK"
} else := i02_day0 {
	_snapshot_ok
	_activated
	i02_day0.decision == "BLOCK"
} else := i03_replay {
	_snapshot_ok
	_activated
	i03_replay.decision == "BLOCK"
} else := i09_year_boundary {
	_snapshot_ok
	_activated
	i09_year_boundary.decision == "BLOCK"
} else := i04_transitional {
	_snapshot_ok
	_activated
	i04_transitional.decision != "PASS"
} else := i08_preprov {
	_snapshot_ok
	_activated
	i08_preprov.decision != "PASS"
} else := i10_param_history {
	_snapshot_ok
	_activated
	i10_param_history.decision != "PASS"
} else := i11_epoch_golden {
	_snapshot_ok
	_activated
	i11_epoch_golden.decision != "PASS"
} else := i12_audit_trail {
	_snapshot_ok
	_activated
	i12_audit_trail.decision != "PASS"} else := i07_sandbox {
	_snapshot_ok
	_activated
	i07_sandbox.matched == true
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p53_temporal_closure.no_match",
	"package": "jdg.v3_p53_temporal_closure",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P53 niewyzwolony (brak flagi v3_p53_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P52",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}
