# NEXUSAI JDG — V3-P64 SWEEP LUK REZYDUALNYCH — PRZEGLĄD CAŁOŚCIOWY
# ==============================================================================
# Warstwa przeglądu resztkowego ENTERPRISE — 12 innowacji (I01–I12; minimum
# z promptu P64 Sekcja 10; konwencja P51–P63):
#
#   I01 Sweep register with SLA — rejestr rezydualny: element→klasa→priorytet→
#       plan→deadline; trend spadkowy (do zera przed P68); brak rejestru =
#       NEEDS_ADVICE.
#   I02 Seven cross-checks suite — 7 kontrol krzyżowych (rule→test, test→rule,
#       tool→test, integration→contract, fail-closed, okno parametru,
#       podstawa prawna) jako bramki CI z licznikami; niekompletny zestaw =
#       BLOCK.
#   I03 Blind-spot taxonomy — taksonomia ślepych plam (hotfix bez testu,
#       copy-paste bez review, deklaracja bez dowodu) z kontrolami
#       strukturalnymi; < min klas = NEEDS_ADVICE.
#   I04 Ownerless artifact detector — pliki bez odwołania z kodu/dokumentów
#       (orphan); > próg = BLOCK.
#   I05 Second-pass stability check — drugi przebieg sweep po naprawach;
#       zero nowych pozycji = dowód kompletności; brak potwierdzenia =
#       NEEDS_ADVICE.
#   I06 Declaration-vs-evidence register — rejestr deklaracji bez dowodu
#       (P00–P67); deklaracja bez dowodu = NEEDS_ADVICE.
#   I07 Residual risk score — skalarne ryzyko rezydualne (luki × wagi klas);
#       > próg certyfikacji = BLOCK.
#   I08 Cross-check dashboard — 7 kontrol jako dane (liczniki, trend) do
#       obserwowalności (P37/P58); brak kanałów = NEEDS_ADVICE.
#   I09 Sweep automation — sweep jako narzędzie uruchamiane cyklicznie
#       (CI weekly) z rejestrem przyrostowym; brak automatu = NEEDS_ADVICE.
#   I10 Handover to V4 — rejestr rezydualny z kontraktami (dziedziczenie
#       standardów); brak kontraktów = NEEDS_ADVICE.
#   I11 Sweep of sweeps — meta-kontrola: czy sweep objął wszystkie katalogi;
#       < min katalogów = NEEDS_ADVICE.
#   I12 Residual report format — standard raportu rezydualnego (klasy,
#       priorytety, plany) wielokrotnego użytku; brak sekcji = NEEDS_ADVICE.
#
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p64 — ADR-002 (P06),
#     okno temporalne valid_from (P05); zero hardcode.
#   * Fail-closed (V1 zasada 6; konwencja P51–P63): brak snapshotu progów =
#     NEEDS_ADVICE; bez flagi v3_p64_check = NO_MATCH; nigdy ciche AUTO_POST.
#   * Konwencja P54–P63: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (tools/v3_p64_engines.py czytają PRAWDZIWE źródła: ledger kampanii
#     bundles/v3_campaign_ledger.json (luki per część), rejestry luk raportów
#     JDG/raporty_glm52_v3/RAPORT_V3_P*_*.txt (sekcja REJESTR LUK),
#     tools/dead_rule_detector.py, tools/cross_package_conflict_detector.py,
#     tools/migration_impact_analyzer.py, tools/v3_repo_hygiene.py,
#     docs/COVERAGE/INWENTARYZACJA, rules/main_jdg.rego (ścieżka decyzyjna),
#     rules/thresholds_jdg.rego (okna parametrów), bundles/v3_p47_mediation_
#     workflow.json [NIEZWERYFIKOWANE], COVERAGE_REPORT.md).
#     Klucze w input.v3_p64 (I01_..–I12_..).
#   * Kontrakty: P03 (werdykt), P06 (ADR-002), P29 (bramki), P30 (rejestr
#     deklaracji), P31 (audyty), P37 (obserwowalność), P39 (CI), P47
#     (mediacje P0/P1), P58 (metryki/trend), P60 (dokumentacja), P61
#     (kontrakty integracji), P65–P68 (handover + re-certyfikacja). Akty:
#     art. 193a OP (staranność procesu), art. 4 ust. 1 UoR (sprawdzalność),
#     art. 5 ust. 1d RODO (prawidłowość), art. 32 RODO (przegląd okresowy),
#     art. 109e VAT (kompletność ewidencji), art. 56 KKS (redukcja ryzyka),
#     art. 47 ustawy o ZUS (spójność deklaracji) — WSZYSTKIE
#     [NIEZWERYFIKOWANE — ISAP].
#   * Aktywacja: input.jdg_entrepreneur.v3_p64_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p64_luka_sweep.<analiza>.
#   * Priorytety: 464001–464012 (I01–I12).
#   * Pakiety importujące (main_jdg.rego): data.jdg.v3_p64_luka_sweep →
#     final_verdict_p128 = safe_merge(final_verdict_p127, …).
# ==============================================================================

package jdg.v3_p64_luka_sweep

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p64_check", false) == true
_ctx := object.get(input, "v3_p64", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p64_snapshot := data.jdg.thresholds.v3_p64

_snapshot_ok = true {
	count(_p64_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p64_snapshot) > 0
	value := object.get(_p64_snapshot, key, null)
	value != null
} else = fallback

_not(x) = true {
	x == false
}

_not(x) = false {
	x == true
}

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.thresholds_missing",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P64 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Sweep register with SLA ───────────────────────────────────────────────
# Rejestr rezydualny ponad limit = BLOCK — element bez właściciela i planu
# narusza sprawdzalność (art. 4 ust. 1 UoR) i prawidłowość (art. 5 ust. 1d RODO).
i01_register := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.sweep_register_sla",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464001,
	"decision": "BLOCK",
	"reason": sprintf("rejestr rezydualny: %v pozycji (limit %v) — element bez właściciela i planu = luka sprawdzalności", [count(items), max_items]),
	"metrics": {"items": count(items), "max": max_items},
	"_legal_basis": "art. 4 ust. 1 UoR (sprawdzalność) [NIEZWERYFIKOWANE — ISAP]; art. 5 ust. 1d RODO (prawidłowość) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_sweep_register", {})
	max_items := _th("v3_p64_residual_register_max", 0)
	items := object.get(_ctx_i01, "open_items", [])
	sla := object.get(_ctx_i01, "sla_plan_registered", false)
	count(items) > max_items
	_not(sla)
}

# ── I02: Seven cross-checks suite ──────────────────────────────────────────────
# Niekompletny zestaw 7 kontrol krzyżowych = BLOCK — sweep bez pełnej macierzy
# kontrol przechodzi obok klas luk, które przechodziły przez wszystkie fale.
i02_cross_checks := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.seven_cross_checks",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464002,
	"decision": "BLOCK",
	"reason": sprintf("cross-checks: %v z %v wymaganych kontroli obecnych (brakuje: %v)", [count(present), count(required), missing]),
	"metrics": {"present": present, "required": count(required), "missing": missing},
	"_legal_basis": "art. 193a OP (staranność weryfikacji) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_cross_checks", {})
	required := _th("v3_p64_cross_checks_required", [])
	present := object.get(_ctx_i02, "checks_present", [])
	missing := [c | c := required[_]; not present[c] = true]
	count(missing) >= 1
}

# ── I03: Blind-spot taxonomy ───────────────────────────────────────────────────
# Taksonomia ślepych plam poniżej minimum = NEEDS_ADVICE — klasy luk przechodzące
# przez fale muszą mieć nazwę i kontrolę strukturalną, inaczej wracają.
i03_blindspots := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.blindspot_taxonomy",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464003,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("taksonomia ślepych plam: %v klas (min %v) — klasy bez kontroli strukturalnej wracają", [count(classes), min_classes]),
	"metrics": {"classes": classes, "min_classes": min_classes},
	"_legal_basis": "art. 32 RODO (przegląd okresowy systemu) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_blindspots", {})
	min_classes := _th("v3_p64_blindspot_classes_min", 5)
	classes := object.get(_ctx_i03, "classes", [])
	count(classes) < min_classes
}

# ── I04: Ownerless artifact detector ───────────────────────────────────────────
# Artefakty bez właściciela ponad próg = BLOCK — zero elementów bez ścieżki
# (orphan w rules/tools/tests/migrations/docs).
i04_ownerless := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.ownerless_artifacts",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464004,
	"decision": "BLOCK",
	"reason": sprintf("artefakty bez właściciela: %v (limit %v) — plik bez odwołania z kodu/dokumentów", [count(orphans), max_ownerless]),
	"metrics": {"orphans": orphans, "max_ownerless": max_ownerless},
	"_legal_basis": "art. 5 ust. 1d RODO (prawidłowość — dane/reguły bez właściciela) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_ownerless", {})
	max_ownerless := _th("v3_p64_ownerless_max", 0)
	orphans := object.get(_ctx_i04, "orphans", [])
	registered := object.get(_ctx_i04, "decisions_registered", false)
	count(orphans) > max_ownerless
	_not(registered)
}

# ── I05: Second-pass stability check ───────────────────────────────────────────
# Brak potwierdzenia stabilności drugiego przebiegu = NEEDS_ADVICE — sweep bez
# drugiego przebiegu nie jest dowodem kompletności.
i05_second_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.second_pass_stability",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("drugi przebieg sweep: wymagany=%v, wykonany=%v, nowe pozycje=%v — stabilny rejestr = dowód kompletności", [required, executed, new_items]),
	"metrics": {"executed": executed, "new_items": new_items},
	"_legal_basis": "art. 193a OP (kompletność procesu weryfikacji) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_second_pass", {})
	required := _th("v3_p64_second_pass_required", true)
	executed := object.get(_ctx_i05, "executed", false)
	new_items := object.get(_ctx_i05, "new_items", 0)
	required
	_not(executed)
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.second_pass_stability",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("drugi przebieg sweep: wykonany=%v, nowe pozycje=%v — nowe pozycje wymagają domknięcia przed certyfikacją", [executed, new_items]),
	"metrics": {"executed": executed, "new_items": new_items},
	"_legal_basis": "prompt P64 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_second_pass", {})
	executed := object.get(_ctx_i05, "executed", false)
	new_items := object.get(_ctx_i05, "new_items", 0)
	executed
	new_items > 0
}

# ── I06: Declaration-vs-evidence register ──────────────────────────────────────
# Deklaracje bez dowodu ponad próg = NEEDS_ADVICE — „OK" bez dowodu (P30) nie
# jest dowodem (zasada 12 protokołu: dowodem jest kod, test, wynik uruchomienia).
i06_declarations := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.declaration_vs_evidence",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464006,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("deklaracje bez dowodu: %v (limit %v) — rejestr deklaracji P00–P67 wymaga dowodów", [count(claims), max_claims]),
	"metrics": {"claims": count(claims), "max": max_claims},
	"_legal_basis": "art. 4 ust. 1 UoR (sprawdzalność) [NIEZWERYFIKOWANE — ISAP]; P30 rejestr deklaracji; prompt P64 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_declarations", {})
	max_claims := _th("v3_p64_undocumented_claims_max", 0)
	claims := object.get(_ctx_i06, "undocumented_claims", [])
	plan := object.get(_ctx_i06, "evidence_plan_registered", false)
	count(claims) > max_claims
	_not(plan)
}

# ── I07: Residual risk score ───────────────────────────────────────────────────
# Ryzyko rezydualne ponad próg certyfikacji = BLOCK — skalar (luki × wagi klas)
# z trendem do P68.
i07_risk := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.residual_risk_score",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464007,
	"decision": "BLOCK",
	"reason": sprintf("ryzyko rezydualne: %v (próg %v) — luki × wagi klas powyżej progu certyfikacji", [risk, max_risk]),
	"metrics": {"risk": risk, "max": max_risk},
	"_legal_basis": "art. 56 KKS (redukcja ryzyka) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I07",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_risk", {})
	max_risk := _th("v3_p64_residual_risk_max", 25)
	risk := object.get(_ctx_i07, "risk_score", 0)
	plan := object.get(_ctx_i07, "reduction_plan_registered", false)
	risk > max_risk
	_not(plan)
}

# ── I08: Cross-check dashboard ─────────────────────────────────────────────────
# Brak kanałów dashboardu 7 kontrol = NEEDS_ADVICE — stan kompletności musi być
# widoczny codziennie (P37/P58 obserwowalność).
i08_dashboard := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.cross_check_dashboard",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464008,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("dashboard cross-checks: %v z %v wymaganych kanałów obecnych", [count(channels), count(required)]),
	"metrics": {"channels": channels, "required": count(required)},
	"_legal_basis": "P37 obserwowalność; P58 metryki/trend; prompt P64 Sekcja 10-I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_dashboard", {})
	required := _th("v3_p64_dashboard_channels", [])
	channels := object.get(_ctx_i08, "channels_present", [])
	missing := [c | c := required[_]; not channels[c] = true]
	count(missing) >= 1
}

# ── I09: Sweep automation ──────────────────────────────────────────────────────
# Sweep jednorazowy bez automatu = NEEDS_ADVICE — bez cyklu CI rejestry gniją
# w ciągu tygodnia.
i09_automation := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.sweep_automation",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("automat sweep: wymagany=%v, obecny=%v (cykl weekly) — sweep jako narzędzie, nie jednorazowa analiza", [required, automated]),
	"metrics": {"automated": automated},
	"_legal_basis": "art. 32 RODO (przegląd okresowy) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_automation", {})
	required := _th("v3_p64_cyclic_sweep_required", true)
	automated := object.get(_ctx_i09, "cyclic_sweep_present", false)
	required
	_not(automated)
}

# ── I10: Handover to V4 ────────────────────────────────────────────────────────
# Rejestr bez kontraktów V4 = NEEDS_ADVICE — zero utraty wiedzy między
# kampaniami (P65–P68 dziedziczą standardy).
i10_handover := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.handover_v4",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464010,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("handover V4: wymagany=%v, kontraktów=%v — rejestr rezydualny przechodzi z kontraktami", [required, count(contracts)]),
	"metrics": {"contracts": contracts},
	"_legal_basis": "prompt P64 Sekcja 11.2 (kontrakt wyjściowy); prompt P64 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_handover", {})
	required := _th("v3_p64_v4_handover_required", true)
	contracts := object.get(_ctx_i10, "handover_contracts", [])
	required
	count(contracts) == 0
}

# ── I11: Sweep of sweeps ───────────────────────────────────────────────────────
# Meta-kontrola: katalogi nieobjęte sweep = NEEDS_ADVICE — zero katalogów
# pominiętych (rules/tools/bundles/migrations/tests/docs/policies/mirrory).
i11_meta := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.sweep_of_sweeps",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464011,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("sweep of sweeps: %v z %v wymaganych katalogów przejrzanych (nieobjęte: %v)", [count(swept), min_dirs, unswept]),
	"metrics": {"swept": swept, "min_dirs": min_dirs, "unswept": unswept},
	"_legal_basis": "art. 109e VAT (kompletność ewidencji) [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_meta", {})
	min_dirs := _th("v3_p64_sweep_of_sweeps_min", 8)
	swept := object.get(_ctx_i11, "swept_dirs", [])
	unswept := object.get(_ctx_i11, "unswept_dirs", [])
	count(swept) < min_dirs
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.sweep_of_sweeps",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464011,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("sweep of sweeps: katalogi nieobjęte=%v — zero katalogów pominiętych", [unswept]),
	"metrics": {"unswept": unswept},
	"_legal_basis": "prompt P64 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_meta", {})
	unswept := object.get(_ctx_i11, "unswept_dirs", [])
	count(unswept) >= 1
}

# ── I12: Residual report format ────────────────────────────────────────────────
# Brak sekcji standardu raportu rezydualnego = NEEDS_ADVICE — format wielokrotnego
# użytku (V4, kampanie przyszłe).
i12_report := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.residual_report_format",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 464012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("standard raportu rezydualnego: %v z %v wymaganych sekcji (brakuje: %v)", [count(present), count(required), missing]),
	"metrics": {"present": present, "required": count(required), "missing": missing},
	"_legal_basis": "prompt P64 Sekcja 9.16 (T1–T12); prompt P64 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_report", {})
	required := _th("v3_p64_residual_report_sections", [])
	present := object.get(_ctx_i12, "sections_present", [])
	missing := [c | c := required[_]; not present[c] = true]
	count(missing) >= 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P63):
# najpierw BLOCK, potem NEEDS_ADVICE, na końcu PASS.
# Bez flagi v3_p64_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i01_register {
	_snapshot_ok
	_activated
	i01_register.decision == "BLOCK"
} else := i02_cross_checks {
	_snapshot_ok
	_activated
	i02_cross_checks.decision == "BLOCK"
} else := i04_ownerless {
	_snapshot_ok
	_activated
	i04_ownerless.decision == "BLOCK"
} else := i07_risk {
	_snapshot_ok
	_activated
	i07_risk.decision == "BLOCK"
} else := i03_blindspots {
	_snapshot_ok
	_activated
	i03_blindspots.decision == "NEEDS_ADVICE"
} else := i05_second_pass {
	_snapshot_ok
	_activated
	i05_second_pass.decision == "NEEDS_ADVICE"
} else := i06_declarations {
	_snapshot_ok
	_activated
	i06_declarations.decision == "NEEDS_ADVICE"
} else := i08_dashboard {
	_snapshot_ok
	_activated
	i08_dashboard.decision == "NEEDS_ADVICE"
} else := i09_automation {
	_snapshot_ok
	_activated
	i09_automation.decision == "NEEDS_ADVICE"
} else := i10_handover {
	_snapshot_ok
	_activated
	i10_handover.decision == "NEEDS_ADVICE"
} else := i11_meta {
	_snapshot_ok
	_activated
	i11_meta.decision == "NEEDS_ADVICE"
} else := i12_report {
	_snapshot_ok
	_activated
	i12_report.decision == "NEEDS_ADVICE"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p64_luka_sweep.no_match",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P64 niewyzwolony (brak flagi v3_p64_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P63",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p64_luka_sweep.all_green",
	"package": "jdg.v3_p64_luka_sweep",
	"priority": 1,
	"decision": "PASS",
	"reason": "P64: sweep luk rezydualnych domknięty (12 analiz: rejestr rezydualny, 7 kontrol krzyżowych, taksonomia ślepych plam, detektor osieroconych, drugi przebieg, deklaracje-vs-dowody, ryzyko rezydualne, dashboard, automat sweep, handover V4, sweep of sweeps, standard raportu)",
	"metrics": {"analyses": 12},
	"_legal_basis": "art. 193a OP; art. 4 ust. 1 UoR; art. 5 ust. 1d RODO; art. 32 RODO; art. 109e VAT; art. 56 KKS; art. 47 ustawy o ZUS [NIEZWERYFIKOWANE — ISAP]; prompt P64 Sekcja 10",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
