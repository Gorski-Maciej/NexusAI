# NEXUSAI JDG — V3-P60 DOKUMENTACJA DOMKNIĘCIE — DOKUMENT MÓWI PRAWDĘ O KODZIE
# ==============================================================================
# Warstwa dokumentacji ENTERPRISE — 12 innowacji (I01–I12; minimum z promptu P60
# Sekcja 10; konwencja P51–P59):
#
#   I01 Doc truth audit            — dokument → liczby → rejestry; rozjazd = BLOCK
#   I02 Registry-generated snippets— liczby z rejestrów, zero ręcznych liczb
#   I03 Front-matter binding gate  — dokument↔artefakt; brak bindingu = BLOCK
#   I04 Ghost document register    — dokumenty-widma (nieistniejące artefakty) = BLOCK
#   I05 Role reading maps          — ścieżki czytania per rola; brak = NEEDS_ADVICE
#   I06 Audit export pack          — pakiet dla kontroli skarbowej; brak = NEEDS_ADVICE
#   I07 Doc freshness automation   — wiek weryfikacji; stary dokument = NEEDS_ADVICE
#   I08 Holy-docs protection       — dokumenty święte pod ochroną; brak = NEEDS_ADVICE
#   I09 Example-as-test            — przykłady testowane w CI; bez testu = BLOCK
#   I10 Glossary enforcement       — spójność terminologiczna; naruszenie = NEEDS_ADVICE
#   I11 PL/EN semantic parity      — dryf tłumaczenia = BLOCK
#   I12 Doc completeness per role  — pokrycie ról 100%; brak ścieżki = BLOCK
#
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p60 — ADR-002 (P06),
#     okno temporalne valid_from (P05); zero hardcode.
#   * Fail-closed (V1 zasada 6; konwencja P51–P59): brak snapshotu progów =
#     NEEDS_ADVICE; wektor bez flagi v3_p60_check = NO_MATCH; nigdy ciche AUTO_POST.
#   * Konwencja P54–P59: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (tools/v3_p60_engines.py czytają PRAWDZIWE źródła: docs/, rule_registry,
#     manifest_v2, ledger, git). Klucze w input.v3_p60 (I01_..–I12_..).
#   * Kontrakty: P03 (kontrakt werdyktu), P06 (ADR-002), P34 (siec walidacji —
#     doc_consistency L4), P36 (generatory), P41 (docs-as-code), P42 (WORM),
#     P47 (konwencja cytowań), P50 (unikalność), P59 (security score), P68.
#   * Aktywacja: input.jdg_entrepreneur.v3_p60_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p60_documentation_closure.<analiza>.
#   * Priorytety: 460001–460012 (I01–I12).
#   * Pakiety importujące (main_jdg.rego): data.jdg.v3_p60_documentation_closure
#     → final_verdict_p124 = safe_merge(final_verdict_p123, …).
# ==============================================================================

package jdg.v3_p60_documentation_closure

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p60_check", false) == true
_ctx := object.get(input, "v3_p60", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p60_snapshot := data.jdg.thresholds.v3_p60

_snapshot_ok = true {
	count(_p60_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p60_snapshot) > 0
	value := object.get(_p60_snapshot, key, null)
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
	"rule_id": "jdg.v3_p60_documentation_closure.thresholds_missing",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P60 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Doc truth audit ───────────────────────────────────────────────────────
# Silnik: porównanie liczb w dokumentach z rejestrami (rule_registry, manifest_v2).
# Rozjazd dokument↔rejestr = BLOCK (dokument nie mówi prawdy o kodzie).
i01_doc_truth := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.doc_truth_audit",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460001,
	"decision": "BLOCK",
	"reason": sprintf("doc truth: %v rozjazdów dokument↔rejestr (zgodność %v%% < %v%%) — korekta dokumentu lub opisu", [count(mismatches), pct, min_pct]),
	"metrics": {"pct": pct, "mismatches": count(mismatches), "min_pct": min_pct},
	"_legal_basis": "UoR art. 4 ust. 4 (dowody rzetelne i kompletne) [NIEZWERYFIKOWANE — ISAP]; P34 siec walidacji L4; prompt P60 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_doc_truth_audit", {})
	min_pct := _th("v3_p60_doc_truth_min_pct", 95)
	pct := object.get(_ctx_i01, "pct", 0)
	mismatches := object.get(_ctx_i01, "mismatches", [])
	pct < min_pct
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.doc_truth_audit",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460001,
	"decision": "BLOCK",
	"reason": sprintf("doc truth: %v rozjazdów dokument↔rejestr (mismatch > 0 = dokument nieprawdziwy)", [count(mismatches)]),
	"metrics": {"pct": pct, "mismatches": count(mismatches)},
	"_legal_basis": "UoR art. 4 ust. 4 [NIEZWERYFIKOWANE — ISAP]; P34 L4; prompt P60 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_doc_truth_audit", {})
	pct := object.get(_ctx_i01, "pct", 0)
	mismatches := object.get(_ctx_i01, "mismatches", [])
	count(mismatches) >= 1
}

# ── I02: Registry-generated snippets ──────────────────────────────────────────
# Silnik: snippety liczbowe generowane z rejestrów (zero ręcznych liczb).
# Liczba snippetów poniżej progu lub niegenerowany snippet = BLOCK.
i02_snippets := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.registry_snippets",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460002,
	"decision": "BLOCK",
	"reason": sprintf("snippety z rejestrów: %v < wymagane %v — brakujące: %v", [snippets_total, min_snippets, missing]),
	"metrics": {"snippets_total": snippets_total, "min_snippets": min_snippets, "missing": count(missing)},
	"_legal_basis": "P36 generatory; P34 wykrywanie ręcznych liczb; prompt P60 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_registry_snippets", {})
	min_snippets := _th("v3_p60_generated_snippets_min", 6)
	snippets_total := object.get(_ctx_i02, "snippets_total", 0)
	missing := object.get(_ctx_i02, "missing_snippets", [])
	snippets_total < min_snippets
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.registry_snippets",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460002,
	"decision": "BLOCK",
	"reason": sprintf("snippety: %v brakujących (katalog reguł musi pochodzić z rejestru)", [count(missing)]),
	"metrics": {"snippets_total": snippets_total, "missing": count(missing)},
	"_legal_basis": "P36 generatory; prompt P60 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_registry_snippets", {})
	snippets_total := object.get(_ctx_i02, "snippets_total", 0)
	missing := object.get(_ctx_i02, "missing_snippets", [])
	count(missing) >= 1
}

# ── I03: Front-matter binding gate ────────────────────────────────────────────
# Silnik: binding dokument↔kod (artefakty, status, owner, verify_cmd).
# Dokument bez bindingu = BLOCK (zmiana kodu bez dokumentacji nie przechodzi).
i03_frontmatter := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.frontmatter_binding",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460003,
	"decision": "BLOCK",
	"reason": sprintf("front-matter: %v dokumentów bez bindingu (wymagane pola: %v)", [count(fm_missing), fields]),
	"metrics": {"docs_with_fm": docs_with_fm, "fm_missing": count(fm_missing), "fields": fields},
	"_legal_basis": "P41-I01 doc-code binding (bramka 6b); prompt P60 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_frontmatter_binding", {})
	fields := _th("v3_p60_frontmatter_required_fields", ["artifacts", "status", "owner", "verify_cmd"])
	docs_with_fm := object.get(_ctx_i03, "docs_with_fm", 0)
	fm_missing := object.get(_ctx_i03, "fm_missing", [])
	count(fm_missing) >= 1
}

# ── I04: Ghost document register ──────────────────────────────────────────────
# Silnik: dokumenty-widma (opisują nieistniejące pliki/reguły/narzędzia).
# Każde widmo = BLOCK (P50: jedno źródło prawdy; opis nieistniejącego = fikcja).
i04_ghosts := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.ghost_documents",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460004,
	"decision": "BLOCK",
	"reason": sprintf("dokumenty-widma: %v (dozwolone %v) — korekta albo SUPERSEDED", [count(ghosts), max_ghosts]),
	"metrics": {"ghosts": count(ghosts), "max_ghosts": max_ghosts},
	"_legal_basis": "P50 unikalność i jedno źródło prawdy; prompt P60 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_ghost_documents", {})
	max_ghosts := _th("v3_p60_ghost_documents_max", 0)
	ghosts := object.get(_ctx_i04, "ghosts", [])
	count(ghosts) > max_ghosts
}

# ── I05: Role reading maps ────────────────────────────────────────────────────
# Silnik: mapy czytania per rola (developer/operator/audytor/przedsiębiorca).
# Brak mapy dla roli = NEEDS_ADVICE (onboarding niekompletny).
i05_role_maps := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.role_reading_maps",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("mapy rolowe: brak dla ról %v (wymagane: %v)", [missing, roles]),
	"metrics": {"maps": count(maps), "missing": count(missing), "roles": roles},
	"_legal_basis": "P41 dokumentacja enterprise; prompt P60 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_role_reading_maps", {})
	roles := _th("v3_p60_roles_required", ["developer", "operator", "auditor", "entrepreneur"])
	maps := object.get(_ctx_i05, "maps", [])
	missing := object.get(_ctx_i05, "missing_roles", [])
	count(missing) >= 1
}

# ── I06: Audit export pack ────────────────────────────────────────────────────
# Silnik: pakiet dla kontroli skarbowej (dokumenty+rejestry+checksumy+WORM).
# Brak eksportu = NEEDS_ADVICE (kontrola skarbowa = droga, musi być gotowa).
i06_audit_export := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.audit_export_pack",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460006,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("eksport audytowy: obecny=%v, retencja=%v dni (wymagane %v dni)", [export_present, retention_days, min_retention]),
	"metrics": {"export_present": export_present, "retention_days": retention_days},
	"_legal_basis": "UoR art. 74 (ochrona przed zniszczeniem) [NIEZWERYFIKOWANE — ISAP]; P42 WORM; prompt P60 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_audit_export_pack", {})
	min_retention := _th("v3_p60_audit_export_retention_days", 1825)
	export_present := object.get(_ctx_i06, "export_present", false)
	retention_days := object.get(_ctx_i06, "retention_days", 0)
	retention_days < min_retention
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.audit_export_pack",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460006,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("eksport audytowy: brak pakietu (export_present=%v)", [export_present]),
	"metrics": {"export_present": export_present},
	"_legal_basis": "UoR art. 74 [NIEZWERYFIKOWANE — ISAP]; P42 WORM; prompt P60 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_audit_export_pack", {})
	export_present := object.get(_ctx_i06, "export_present", false)
	_not(export_present)
}

# ── I07: Doc freshness automation ─────────────────────────────────────────────
# Silnik: wiek weryfikacji dokumentu (git last commit vs próg).
# Dokument starszy niż próg = NEEDS_ADVICE (świeżość widoczna, nie ukrywana).
i07_freshness := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.doc_freshness",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460007,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("świeżość: %v dokumentów starszych niż %v dni — rewizja", [count(stale), max_age]),
	"metrics": {"stale": count(stale), "max_age_days": max_age},
	"_legal_basis": "P37/P58 obserwowalność (świeżość jako metryka); prompt P60 Sekcja 10-I07",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_doc_freshness", {})
	max_age := _th("v3_p60_doc_freshness_max_days", 90)
	stale := object.get(_ctx_i07, "stale_docs", [])
	count(stale) >= 1
}

# ── I08: Holy-docs protection ─────────────────────────────────────────────────
# Silnik: dokumenty święte (V1/V2) pod CODEOWNERS/ADR (zmiana = review prawne).
# Dokument święty bez mechanizmu ochrony = NEEDS_ADVICE.
i08_holy_docs := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.holy_docs_protection",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460008,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("dokumenty święte bez ochrony: %v z %v — CODEOWNERS/ADR wymagane", [count(unprotected), total]),
	"metrics": {"unprotected": count(unprotected), "total": total},
	"_legal_basis": "V1/V2 nadrzędność (dokumenty święte); prompt P60 Sekcja 10-I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_holy_docs_protection", {})
	unprotected := object.get(_ctx_i08, "unprotected", [])
	total := object.get(_ctx_i08, "total", 0)
	count(unprotected) >= 1
}

# ── I09: Example-as-test ──────────────────────────────────────────────────────
# Silnik: przykłady (curl/rego) testowane w CI. Przykład bez testu = BLOCK
# (zepsuty przykład = dokument nieprawdziwy w praktyce).
i09_examples := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.examples_as_test",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460009,
	"decision": "BLOCK",
	"reason": sprintf("przykłady-as-test: %v z %v bez testu (wymagane min. %v testowanych)", [count(untested), examples_total, min_tested]),
	"metrics": {"examples_total": examples_total, "untested": count(untested), "min_tested": min_tested},
	"_legal_basis": "P39 testy/CI; prompt P60 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_examples_as_test", {})
	min_tested := _th("v3_p60_examples_as_test_min", 8)
	examples_total := object.get(_ctx_i09, "examples_total", 0)
	untested := object.get(_ctx_i09, "untested", [])
	examples_total - count(untested) < min_tested
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.examples_as_test",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460009,
	"decision": "BLOCK",
	"reason": sprintf("przykłady-as-test: %v przykładów bez testu w CI", [count(untested)]),
	"metrics": {"examples_total": examples_total, "untested": count(untested)},
	"_legal_basis": "P39 testy/CI; prompt P60 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_examples_as_test", {})
	examples_total := object.get(_ctx_i09, "examples_total", 0)
	untested := object.get(_ctx_i09, "untested", [])
	count(untested) >= 1
}

# ── I10: Glossary enforcement ─────────────────────────────────────────────────
# Silnik: lint terminologiczny (SLOWNIK_REFERENCJI_PRAWNYCH). Naruszenie =
# NEEDS_ADVICE (konsekwencja terminologiczna).
i10_glossary := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.glossary_enforcement",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460010,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("glosariusz: %v naruszeń na %v sprawdzonych terminach", [count(violations), terms_checked]),
	"metrics": {"terms_checked": terms_checked, "violations": count(violations), "min_terms": min_terms},
	"_legal_basis": "P47 konwencja cytowań; glosariusz dokumentów świętych; prompt P60 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_glossary_enforcement", {})
	min_terms := _th("v3_p60_glossary_terms_min", 12)
	terms_checked := object.get(_ctx_i10, "terms_checked", 0)
	violations := object.get(_ctx_i10, "violations", [])
	terms_checked < min_terms
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.glossary_enforcement",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460010,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("glosariusz: %v naruszeń spójności terminologicznej", [count(violations)]),
	"metrics": {"terms_checked": terms_checked, "violations": count(violations)},
	"_legal_basis": "P47 konwencja cytowań; prompt P60 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_glossary_enforcement", {})
	terms_checked := object.get(_ctx_i10, "terms_checked", 0)
	violations := object.get(_ctx_i10, "violations", [])
	count(violations) >= 1
}

# ── I11: PL/EN semantic parity ────────────────────────────────────────────────
# Silnik: ARCHITEKTURA.md vs ARCHITECTURE.md — paroliść kluczowych nagłówków.
# Dryf tłumaczenia poniżej progu = BLOCK (PL/EN sprzeczne = dwa źródła prawdy).
i11_plen_parity := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.plen_semantic_parity",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460011,
	"decision": "BLOCK",
	"reason": sprintf("PL/EN parity: %v%% < %v%% — dryf tłumaczenia (rozjechane: %v)", [parity_pct, min_pct, count(mismatched)]),
	"metrics": {"parity_pct": parity_pct, "min_pct": min_pct, "mismatched": count(mismatched)},
	"_legal_basis": "P41 PL/EN mirror; P48 duch anti-drift; prompt P60 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_plen_parity", {})
	min_pct := _th("v3_p60_plen_parity_min_pct", 80)
	parity_pct := object.get(_ctx_i11, "parity_pct", 0)
	mismatched := object.get(_ctx_i11, "mismatched", [])
	parity_pct < min_pct
}

# ── I12: Doc completeness per role ────────────────────────────────────────────
# Silnik: pokrycie ról mapami czytania (metryka kompletności dokumentacji).
# Pokrycie poniżej 100% = BLOCK (zero ról bez ścieżki czytania).
i12_role_coverage := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.role_coverage",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 460012,
	"decision": "BLOCK",
	"reason": sprintf("pokrycie roli: %v%% < %v%% (role bez ścieżki: %v)", [coverage_pct, min_pct, roles_without]),
	"metrics": {"coverage_pct": coverage_pct, "min_pct": min_pct, "roles_without": roles_without},
	"_legal_basis": "P41 dokumentacja enterprise; prompt P60 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_role_coverage", {})
	min_pct := _th("v3_p60_role_coverage_min_pct", 100)
	coverage_pct := object.get(_ctx_i12, "coverage_pct", 0)
	roles_without := object.get(_ctx_i12, "roles_without_path", [])
	coverage_pct < min_pct
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P59):
# najpierw BLOCK, potem NEEDS_ADVICE/MANUAL_REVIEW, na końcu PASS.
# Bez flagi v3_p60_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i01_doc_truth {
	_snapshot_ok
	_activated
	i01_doc_truth.decision == "BLOCK"
} else := i02_snippets {
	_snapshot_ok
	_activated
	i02_snippets.decision == "BLOCK"
} else := i03_frontmatter {
	_snapshot_ok
	_activated
	i03_frontmatter.decision == "BLOCK"
} else := i04_ghosts {
	_snapshot_ok
	_activated
	i04_ghosts.decision == "BLOCK"
} else := i09_examples {
	_snapshot_ok
	_activated
	i09_examples.decision == "BLOCK"
} else := i11_plen_parity {
	_snapshot_ok
	_activated
	i11_plen_parity.decision == "BLOCK"
} else := i12_role_coverage {
	_snapshot_ok
	_activated
	i12_role_coverage.decision == "BLOCK"
} else := i05_role_maps {
	_snapshot_ok
	_activated
	i05_role_maps.decision == "NEEDS_ADVICE"
} else := i06_audit_export {
	_snapshot_ok
	_activated
	i06_audit_export.decision == "NEEDS_ADVICE"
} else := i07_freshness {
	_snapshot_ok
	_activated
	i07_freshness.decision == "NEEDS_ADVICE"
} else := i08_holy_docs {
	_snapshot_ok
	_activated
	i08_holy_docs.decision == "NEEDS_ADVICE"
} else := i10_glossary {
	_snapshot_ok
	_activated
	i10_glossary.decision == "NEEDS_ADVICE"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p60_documentation_closure.no_match",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P60 niewyzwolony (brak flagi v3_p60_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P59",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p60_documentation_closure.all_green",
	"package": "jdg.v3_p60_documentation_closure",
	"priority": 1,
	"decision": "PASS",
	"reason": "P60: dokumentacja mówi prawdę o kodzie (12 analiz: truth, snippety, binding, widma, mapy rolowe, eksport, świeżość, ochrona, przykłady, glosariusz, PL/EN, pokrycie)",
	"metrics": {"analyses": 12},
	"_legal_basis": "UoR art. 4 ust. 4/74 [NIEZWERYFIKOWANE — ISAP]; P34/P36/P41/P47 kontrakty; prompt P60 Sekcja 10",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
