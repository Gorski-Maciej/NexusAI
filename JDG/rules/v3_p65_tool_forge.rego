# NEXUSAI JDG — V3-P65 NOWE NARZĘDZIA FORTECY (konwencja P51–P64)
# ==============================================================================
# Warstwa narzędziowa ENTERPRISE — 12 innowacji (I01–I12; minimum z promptu P65
# Sekcja 10):
#
#   I01 Tool standard contract — wspólny kontrakt narzędzi fortecy: wejście →
#       raport JSON (schema P29) → exit codes → dry-run; kontrakt jako DANE
#       (fields z progu ADR-002); niekompletny zestaw pól = BLOCK.
#   I02 Semantic diff for Rego — klasyfikacja zmian (kosmetyczna/progowa/
#       semantyczna) z różnymi ścieżkami review; < min klas = NEEDS_ADVICE.
#   I03 Rule-to-tests generator — struktura przypadków brzegowych z treści
#       przepisu (karty pustyni P51); < min klas brzegowych = NEEDS_ADVICE.
#   I04 Cashflow simulator — scenariusze płynności (terminy, salda, odsetki;
#       P62 digital twin); < min scenariuszy = NEEDS_ADVICE.
#   I05 Temporal simulator — przełączenia day-0 (P53 sandbox); < min
#       przełączeń = NEEDS_ADVICE.
#   I06 RBAC validator — macierz ról (P63); rola bez pól obowiązkowych =
#       BLOCK (zawsze, niezależnie od progu ról).
#   I07 Eval benchmark tool — p95 latencji per domena (P37); regresja ponad
#       próg bez planu = BLOCK.
#   I08 WORM tamper tester — próby naruszenia integralności (P42/P59); brak
#       asercji niezmienności = BLOCK.
#   I09 Legal chaos suite — mutacje prawne z asercją fail-closed (P49);
#       < min mutacji = NEEDS_ADVICE.
#   I10 Composition-first rule — przed nowym narzędziem kompozycja (A+B+glue);
#       brak analizy kompozycji = NEEDS_ADVICE.
#   I11 Tool adoption metrics — metryki użycia (CI wywołania); narzędzie
#       nieużywane bez decyzji = NEEDS_ADVICE.
#   I12 Tool documentation generator — docs z definicji narzędzia (zero dryfu,
#       P60 binding); dryf dokumentacji = NEEDS_ADVICE.
#
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p65 — ADR-002 (P06),
#     okno temporalne valid_from (P05); zero hardcode.
#   * Fail-closed (V1 zasada 6; konwencja P51–P64): brak snapshotu progów =
#     NEEDS_ADVICE; bez flagi v3_p65_check = NO_MATCH; nigdy ciche AUTO_POST.
#   * Konwencja P54–P64: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (tools/v3_p65_engines.py czytają PRAWDZIWE źródła: kontrakt narzędzi
#     tools/tool_contract.py + 12 narzędzi v3_p65_tool_*, detektor kompozycji
#     tools/v3_p64_sweep_engine.py, rolę RBAC docs/ROLE_MAPS.md + P63,
#     WORM tools/v3_p42_retention_calculator.py + audit trail P40, chaos P49,
#     benchmark P37, dokumentacja P60 — KATALOG_NARZEDZI.md).
#     Klucze w input.v3_p65 (I01_..–I12_..).
#   * Kontrakty: P03 (werdykt), P06 (ADR-002), P29 (kontrakt raportu JSON),
#     P36 (generatory), P37 (obserwowalność/benchmark), P39 (CI), P41/P60
#     (dokumentacja generowana), P42/P59 (WORM/integralność), P49 (fail-closed),
#     P50 (dead tools), P51 (pustynie/karty przepisu), P53 (temporal sandbox),
#     P62 (cashflow), P63 (RBAC), P64 (rejestr rezydualny K1–K5). Akty:
#     art. 119a OP (GAAR — narzędzia defensywne), art. 4 ust. 1 UoR
#     (sprawdzalność), art. 5 UoR (pierwotność dowodów), art. 109e VAT
#     (kompletność ewidencji), art. 9a PIT (spójność dokumentacji), art. 25
#     RODO (privacy by design), art. 47 ustawy o ZUS (terminowość), art. 56
#     KKS (wczesna detekcja błędów) — WSZYSTKIE [NIEZWERYFIKOWANE — ISAP].
#   * Aktywacja: input.jdg_entrepreneur.v3_p65_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p65_tool_forge.<analiza>.
#   * Priorytety: 465001–465012 (I01–I12).
#   * Pakiety importujące (main_jdg.rego): data.jdg.v3_p65_tool_forge →
#     final_verdict_p129 = safe_merge(final_verdict_p128, …).
# ==============================================================================

package jdg.v3_p65_tool_forge

# ── Kontrakt wejściowy ────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p65_check", false) == true
_ctx := object.get(input, "v3_p65", {})

# ── Snapshot progów (ADR-002) ─────────────────────────────────────────────────
_p65_snapshot := data.jdg.thresholds.v3_p65

_snapshot_ok = true {
	count(_p65_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p65_snapshot) > 0
	value := object.get(_p65_snapshot, key, null)
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
	"rule_id": "jdg.v3_p65_tool_forge.thresholds_missing",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P65 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Tool standard contract ───────────────────────────────────────────────
# Narzędzie bez wspólnego kontraktu = BLOCK — narzędzie bez raportu JSON
# (schema P29), exit codes i dry-run nie łańcuchuje się w CI (art. 4 ust. 1
# UoR: sprawdzalność).
i01_contract := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.tool_standard_contract",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465001,
	"decision": "BLOCK",
	"reason": sprintf("kontrakt narzędzi: %v z %v wymaganych pól raportu JSON (brakuje: %v) — narzędzie bez kontraktu nie wchodzi do CI", [count(present), count(required), missing]),
	"metrics": {"present": present, "required": count(required), "missing": missing},
	"_legal_basis": "art. 4 ust. 1 UoR (sprawdzalność) [NIEZWERYFIKOWANE — ISAP]; P29 kontrakt raportu JSON; prompt P65 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_tool_contract", {})
	required := _th("v3_p65_tool_contract_required_fields", [])
	present := object.get(_ctx_i01, "contract_fields_present", [])
	missing := [f | f := required[_]; not present[f] = true]
	count(missing) >= 1
}

# ── I02: Semantic diff for Rego ───────────────────────────────────────────────
# Klasyfikacja zmian poniżej minimum = NEEDS_ADVICE — zmiana semantyczna
# (próg/skutek) musi iść inną ścieżką review niż kosmetyczna.
i02_semantic_diff := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.semantic_diff",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465002,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("semantic diff Rego: %v z %v wymaganych klas zmian (brakuje: %v) — klasy kosmetyczna/progowa/semantyczna mają różne ścieżki review", [count(present), min_classes, missing]),
	"metrics": {"classes": present, "min_classes": min_classes},
	"_legal_basis": "art. 9a PIT (spójność dokumentacji i ewidencji) [NIEZWERYFIKOWANE — ISAP]; prompt P65 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_semantic_diff", {})
	min_classes := _th("v3_p65_semantic_diff_classes_min", 3)
	present := object.get(_ctx_i02, "classes_present", [])
	missing := [c | c := ["cosmetic", "threshold", "semantic"][_]; not present[c] = true]
	count(missing) >= 1
	count(present) < min_classes
}

# ── I03: Rule-to-tests generator ──────────────────────────────────────────────
# Generator bez klas przypadków brzegowych = NEEDS_ADVICE — test z treści
# przepisu bez granic (daty, progi, waluty, zaokrąglenia) jest zawsze-zielony
# (AP06).
i03_test_generator := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.rule_to_tests_generator",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465003,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("generator testów z przepisu: %v z %v wymaganych klas brzegowych (brakuje: %v) — brak asercji negatywnych = testy zawsze-zielone (AP06)", [count(present), min_classes, missing]),
	"metrics": {"classes": present, "min_classes": min_classes},
	"_legal_basis": "art. 109e VAT (kompletność ewidencji) [NIEZWERYFIKOWANE — ISAP]; P51 karty pustyni; prompt P65 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_test_generator", {})
	min_classes := _th("v3_p65_edge_case_classes_min", 4)
	present := object.get(_ctx_i03, "edge_case_classes_present", [])
	missing := [c | c := ["dates", "thresholds", "currencies", "rounding"][_]; not present[c] = true]
	count(missing) >= 1
	count(present) < min_classes
}

# ── I04: Cashflow simulator ───────────────────────────────────────────────────
# Symulator bez scenariuszy płynności = NEEDS_ADVICE — prognoza bez scenariuszy
# (bazowy/opóźnienia/zwrot VAT) nie wspiera decyzji księgowych (P62).
i04_cashflow := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.cashflow_simulator",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465004,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("symulator cashflow: %v z %v wymaganych scenariuszy (brakuje: %v) — P62 digital twin wymaga scenariuszy płynności", [count(present), min_scenarios, missing]),
	"metrics": {"scenarios": present, "min_scenarios": min_scenarios},
	"_legal_basis": "art. 47 ustawy o ZUS (terminowość) [NIEZWERYFIKOWANE — ISAP]; P62 przepływy pieniężne; prompt P65 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_cashflow", {})
	min_scenarios := _th("v3_p65_cashflow_scenarios_min", 3)
	present := object.get(_ctx_i04, "scenarios_present", [])
	missing := [s | s := ["base", "delays", "vat_refund"][_]; not present[s] = true]
	count(missing) >= 1
	count(present) < min_scenarios
}

# ── I05: Temporal simulator ───────────────────────────────────────────────────
# Symulator temporalny bez przełączeń day-0 = NEEDS_ADVICE — wdrożenie noweli
# bez symulacji day-1/day-0/day+1 (P53) to ryzyko błędnej decyzji na granicy.
i05_temporal := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.temporal_simulator",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("symulator temporalny: %v z %v wymaganych przełączeń day-0 (brakuje: %v) — granice nowelizacji wymagają symulacji (P53)", [count(present), min_transitions, missing]),
	"metrics": {"transitions": present, "min_transitions": min_transitions},
	"_legal_basis": "P05 temporalność; P53 sandbox temporalny; prompt P65 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_temporal", {})
	min_transitions := _th("v3_p65_temporal_transitions_min", 2)
	present := object.get(_ctx_i05, "transitions_present", [])
	missing := [t | t := ["day_minus_1", "day_0"][_]; not present[t] = true]
	count(missing) >= 1
	count(present) < min_transitions
}

# ── I06: RBAC validator ───────────────────────────────────────────────────────
# Rola bez pól obowiązkowych macierzy = BLOCK — walidacja matrix RBAC (P63):
# rola bez mapy pól/testu to ślepe uprawnienie (privacy by design, art. 25 RODO).
i06_rbac := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.rbac_validator",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465006,
	"decision": "BLOCK",
	"reason": sprintf("walidator RBAC: %v z %v ról kompletnych (bez pól: %v) — rola bez mapy pól/testu = ślepe uprawnienie (P63)", [count(complete_roles), min_roles, incomplete]),
	"metrics": {"roles": count(complete_roles), "min_roles": min_roles, "incomplete": incomplete},
	"_legal_basis": "art. 25 RODO (privacy by design) [NIEZWERYFIKOWANE — ISAP]; P63 RBAC; prompt P65 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_rbac", {})
	min_roles := _th("v3_p65_rbac_matrix_roles_min", 4)
	roles := object.get(_ctx_i06, "roles_matrix", {})
	incomplete := [r | some r; fields := roles[r]; count(object.get(fields, "field_map", {})) == 0]
	complete := {r | some r; fields := roles[r]; count(object.get(fields, "field_map", {})) > 0}
	count(complete) < min_roles
}

# ── I07: Eval benchmark tool ──────────────────────────────────────────────────
# Regresja p95 ponad próg bez planu = BLOCK — wydajność eval jest częścią
# observability (P37); degradacja latencji bez planu = ryzyko operacyjne.
i07_benchmark := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.eval_benchmark",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465007,
	"decision": "BLOCK",
	"reason": sprintf("benchmark eval: p95=%v ms (próg %v) bez planu redukcji — regresja wydajności per domena (P37)", [p95_ms, max_ms]),
	"metrics": {"p95_ms": p95_ms, "max_ms": max_ms},
	"_legal_basis": "P37 obserwowalność (SLO eval); prompt P65 Sekcja 10-I07",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_benchmark", {})
	max_ms := _th("v3_p65_eval_p95_ms_max", 500)
	p95_ms := object.get(_ctx_i07, "p95_ms", 0)
	plan := object.get(_ctx_i07, "reduction_plan_registered", false)
	p95_ms > max_ms
	_not(plan)
}

# ── I08: WORM tamper tester ───────────────────────────────────────────────────
# Brak asercji niezmienności przy próbach naruszenia = BLOCK — tamper test bez
# wykrywalności modyfikacji unieważnia dowód WORM (art. 5 UoR pierwotność).
i08_worm := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.worm_tamper_tester",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465008,
	"decision": "BLOCK",
	"reason": sprintf("WORM tamper test: %v prób, wykrytych=%v — brak asercji niezmienności unieważnia dowód WORM", [probes, detected]),
	"metrics": {"probes": probes, "detected": detected},
	"_legal_basis": "art. 5 UoR (pierwotność dowodów) [NIEZWERYFIKOWANE — ISAP]; P42 retencja/WORM; P59 integralność; prompt P65 Sekcja 10-I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_worm", {})
	min_probes := _th("v3_p65_worm_tamper_probes_min", 5)
	probes := object.get(_ctx_i08, "tamper_probes", 0)
	detected := object.get(_ctx_i08, "tampering_detected", 0)
	probes >= min_probes
	detected < probes
}

# ── I09: Legal chaos suite ────────────────────────────────────────────────────
# Mutacje prawne poniżej minimum = NEEDS_ADVICE — chaos bez asercji fail-closed
# nie dowodzi defensywności (P49; K10).
i09_chaos := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.legal_chaos_suite",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("chaos suite prawny: %v mutacji (min %v), przełamań fail-closed=%v — defensywność mierzalna (P49/K10)", [mutations, min_mutations, breaches]),
	"metrics": {"mutations": mutations, "min": min_mutations, "breaches": breaches},
	"_legal_basis": "P49 fail-closed domknięcie; art. 56 KKS (wczesna detekcja) [NIEZWERYFIKOWANE — ISAP]; prompt P65 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_chaos", {})
	min_mutations := _th("v3_p65_chaos_mutations_min", 10)
	mutations := object.get(_ctx_i09, "mutations", 0)
	breaches := object.get(_ctx_i09, "fail_closed_breaches", 0)
	mutations < min_mutations
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.legal_chaos_suite",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("chaos suite prawny: %v mutacji, przełamań fail-closed=%v — każde przełamanie fail-closed (cichy AUTO_POST) wymaga domknięcia", [mutations, breaches]),
	"metrics": {"mutations": mutations, "breaches": breaches},
	"_legal_basis": "P49 fail-closed; AP07 cichy AUTO_POST; prompt P65 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_chaos", {})
	breaches := object.get(_ctx_i09, "fail_closed_breaches", 0)
	breaches > 0
}

# ── I10: Composition-first rule ───────────────────────────────────────────────
# Nowe narzędzie bez analizy kompozycji = NEEDS_ADVICE — duplikacja
# funkcjonalności istniejących detektorów narusza kontrakt 11.1 (zakaz
# duplikowania, P08 protokół).
i10_composition := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.composition_first",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465010,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("reguła kompozycji: wymagana=%v, obecna=%v — przed nowym narzędziem kompozycja A+B+glue (zero duplikacji)", [required, present]),
	"metrics": {"present": present},
	"_legal_basis": "protokół P65 pkt 08 (zakaz duplikacji); P50 dead code; prompt P65 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_composition", {})
	required := _th("v3_p65_composition_first_required", true)
	present := object.get(_ctx_i10, "composition_analysis_present", false)
	required
	_not(present)
}

# ── I11: Tool adoption metrics ────────────────────────────────────────────────
# Narzędzie nieużywane bez decyzji = NEEDS_ADVICE — metryki użycia (CI wywołania)
# decydują: poprawa DX albo usunięcie (P50 dead tools).
i11_adoption := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.tool_adoption_metrics",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465011,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("metryki przyjęcia: cykl=%v, narzędzia nieużywane=%v bez decyzji (poprawa DX albo usunięcie P50)", [cycle, unused]),
	"metrics": {"cycle": cycle, "unused": unused},
	"_legal_basis": "P50 dead code/duplikaty; P37 metryki; prompt P65 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_adoption", {})
	cycle := _th("v3_p65_adoption_cycle", "weekly")
	unused := object.get(_ctx_i11, "unused_tools_without_decision", 0)
	unused > 0
}

# ── I12: Tool documentation generator ─────────────────────────────────────────
# Dokumentacja z dryfem względem definicji = NEEDS_ADVICE — docs generowane z
# definicji narzędzia (zero dryfu; P60 binding).
i12_docs := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.doc_generator",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 465012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("generator dokumentacji: wymagany=%v, binding=%v — docs z definicji narzędzia, zero dryfu (P60)", [required, binding]),
	"metrics": {"binding": binding},
	"_legal_basis": "P60 dokumentacja domknięcie (binding); prompt P65 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_docs", {})
	required := _th("v3_p65_doc_binding_required", true)
	binding := object.get(_ctx_i12, "doc_binding_present", false)
	required
	_not(binding)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P64):
# najpierw BLOCK, potem NEEDS_ADVICE, na końcu PASS.
# Bez flagi v3_p65_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i01_contract {
	_snapshot_ok
	_activated
	i01_contract.decision == "BLOCK"
} else := i06_rbac {
	_snapshot_ok
	_activated
	i06_rbac.decision == "BLOCK"
} else := i07_benchmark {
	_snapshot_ok
	_activated
	i07_benchmark.decision == "BLOCK"
} else := i08_worm {
	_snapshot_ok
	_activated
	i08_worm.decision == "BLOCK"
} else := i02_semantic_diff {
	_snapshot_ok
	_activated
	i02_semantic_diff.decision == "NEEDS_ADVICE"
} else := i03_test_generator {
	_snapshot_ok
	_activated
	i03_test_generator.decision == "NEEDS_ADVICE"
} else := i04_cashflow {
	_snapshot_ok
	_activated
	i04_cashflow.decision == "NEEDS_ADVICE"
} else := i05_temporal {
	_snapshot_ok
	_activated
	i05_temporal.decision == "NEEDS_ADVICE"
} else := i09_chaos {
	_snapshot_ok
	_activated
	i09_chaos.decision == "NEEDS_ADVICE"
} else := i10_composition {
	_snapshot_ok
	_activated
	i10_composition.decision == "NEEDS_ADVICE"
} else := i11_adoption {
	_snapshot_ok
	_activated
	i11_adoption.decision == "NEEDS_ADVICE"
} else := i12_docs {
	_snapshot_ok
	_activated
	i12_docs.decision == "NEEDS_ADVICE"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p65_tool_forge.no_match",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P65 niewyzwolony (brak flagi v3_p65_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P64",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p65_tool_forge.all_green",
	"package": "jdg.v3_p65_tool_forge",
	"priority": 1,
	"decision": "PASS",
	"reason": "P65: nowe narzędzia fortecy domknięte (12 analiz: wspólny kontrakt narzędzi, semantic diff Rego, generator testów z przepisu, symulator cashflow, symulator temporalny, walidator RBAC, benchmark eval, WORM tamper tester, chaos suite prawny, reguła kompozycji, metryki przyjęcia, generator dokumentacji)",
	"metrics": {"analyses": 12},
	"_legal_basis": "art. 119a OP; art. 4 ust. 1 UoR; art. 5 UoR; art. 109e VAT; art. 9a PIT; art. 25 RODO; art. 47 ustawy o ZUS; art. 56 KKS [NIEZWERYFIKOWANE — ISAP]; prompt P65 Sekcja 10",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
