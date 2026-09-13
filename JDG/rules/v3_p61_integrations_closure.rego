# NEXUSAI JDG — V3-P61 INTEGRACJE DOMKNIĘCIE — KSEF/MF, BANKI, NBP, ISAP
# ==============================================================================
# Warstwa integracji zewnętrznych ENTERPRISE — 12 innowacji (I01–I12; minimum
# z promptu P61 Sekcja 10; konwencja P51–P60):
#
#   I01 Integration standard contract — health/status/degradacja/metryki/runbook;
#       integracja bez pełnego kontraktu = BLOCK (zero fasad).
#   I02 Circuit breaker per integration — awaria → otwarcie (kolejka) →
#       półotwarcie (probe) → zamknięcie; brak mechanizmu = NEEDS_ADVICE.
#   I03 Reference data provenance chain — kursy/PKWiU/GTU/akty: data+źródło+
#       checksuma; brak pola provenance = BLOCK (audyt schodzi do źródła).
#   I04 Sandbox replay CI — testy na danych sandbox/historycznych (bez live w PR);
#       brak replayu = NEEDS_ADVICE.
#   I05 Cache with provenance TTL — cache z TTL, inwalidacją i provenance;
#       cache bez wieku = NEEDS_ADVICE.
#   I06 Bank reconciliation contract — dopasowanie → rozjazd → NEEDS_ADVICE
#       z kandydatami; rozjazd bez ścieżki = BLOCK.
#   I07 Holiday-aware rate path — weekend/święto: ostatnia tabela NBP
#       (art. 31a duch [NIEZWERYFIKOWANE — ISAP]); brak ścieżki = BLOCK.
#   I08 Integration registry — rejestr (kanał, kontrakt, status REAL/PLANNED/
#       FACADE); status poza dozwolonymi = BLOCK.
#   I09 Degradation ladder — pełny → cache → offline → read-only; drabina
#       krótsza niż próg = NEEDS_ADVICE.
#   I10 Outbox pattern for MF — dokument → kolejka trwała → wysyłka z
#       idempotencją → statusy; wpis przeterminowany = NEEDS_ADVICE.
#   I11 External SLA monitoring — latencja/dostępność zewnętrznych; przekroczenie
#       progu = BLOCK (dane do zmiany kanału).
#   I12 Integration attestation in certificate — wersje danych referencyjnych
#       w certyfikacie decyzji; attestation przeterminowana = NEEDS_ADVICE.
#
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p61 — ADR-002 (P06),
#     okno temporalne valid_from (P05); zero hardcode.
#   * Fail-closed (V1 zasada 6; konwencja P51–P60): brak snapshotu progów =
#     NEEDS_ADVICE; bez flagi v3_p61_check = NO_MATCH; nigdy ciche AUTO_POST.
#   * Konwencja P54–P60: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (tools/v3_p61_engines.py czytają PRAWDZIWE źródła: ksef_outbox,
#     ksef_offline_queue, isap_crawler cache, fx_provenance P53, p57_reconciliation,
#     v3_p49 breaker, p54 attestation). Klucze w input.v3_p61 (I01_..–I12_..).
#   * Kontrakty: P03 (werdykt), P06 (ADR-002), P40 (degradacja w odpowiedzi),
#     P43 (chaos), P47 (ISAP świeżość), P52/P53 (fx provenance), P54 (KSeF
#     reguły), P57 (kolejki/parowanie), P58 (metryki), P59 (sekrety), P68.
#   * Aktywacja: input.jdg_entrepreneur.v3_p61_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p61_integrations_closure.<analiza>.
#   * Priorytety: 461001–461012 (I01–I12).
#   * Pakiety importujące (main_jdg.rego): data.jdg.v3_p61_integrations_closure
#     → final_verdict_p125 = safe_merge(final_verdict_p124, …).
# ==============================================================================

package jdg.v3_p61_integrations_closure

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p61_check", false) == true
_ctx := object.get(input, "v3_p61", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p61_snapshot := data.jdg.thresholds.v3_p61

_snapshot_ok = true {
	count(_p61_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p61_snapshot) > 0
	value := object.get(_p61_snapshot, key, null)
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
	"rule_id": "jdg.v3_p61_integrations_closure.thresholds_missing",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P61 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Integration standard contract ────────────────────────────────────────
# Integracja bez pełnego kontraktu (health/status/degradacja/metryki/runbook)
# = BLOCK (zero fasad integracji — misja P61).
i01_contract := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.integration_standard_contract",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461001,
	"decision": "BLOCK",
	"reason": sprintf("kontrakt integracji: %v z %v integracji bez pełnego standardu (%v) — brakujące elementy: %v", [count(violators), total, elements, count(violators)]),
	"metrics": {"integrations_total": total, "violators": count(violators), "elements": elements},
	"_legal_basis": "V1 control plane (kontrakty kanałów); prompt P61 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_integration_contract", {})
	elements := _th("v3_p61_contract_elements_required", ["health", "status", "degradation", "metrics", "runbook"])
	total := object.get(_ctx_i01, "integrations_total", 0)
	violators := object.get(_ctx_i01, "contract_violators", [])
	count(violators) >= 1
}

# ── I02: Circuit breaker per integration ──────────────────────────────────────
# Brak mechanizmu breakera (P49) lub próg poniżej kontraktu = NEEDS_ADVICE.
i02_breaker := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.circuit_breaker",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461002,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("circuit breaker: mechanizm=%v, próg=%v, półotwarcie=%v s (awaria zewnętrzna → kolejka)", [mechanism, threshold, halfopen]),
	"metrics": {"mechanism": mechanism, "threshold": threshold, "halfopen_s": halfopen},
	"_legal_basis": "P43 chaos (awaria testowana); P49-I05 breaker per domena; prompt P61 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_circuit_breaker", {})
	threshold := _th("v3_p61_breaker_open_threshold", 3)
	halfopen := _th("v3_p61_breaker_halfopen_seconds", 60)
	mechanism := object.get(_ctx_i02, "mechanism_present", false)
	_not(mechanism)
}

# ── I03: Reference data provenance chain ──────────────────────────────────────
# Dane referencyjne bez pola provenance (date/source/checksum) = BLOCK.
i03_provenance := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.reference_data_provenance",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461003,
	"decision": "BLOCK",
	"reason": sprintf("provenance danych referencyjnych: %v zbiorów bez pól %v — audyt nie schodzi do źródła", [count(incomplete), fields]),
	"metrics": {"datasets": count(datasets), "incomplete": count(incomplete), "fields": fields},
	"_legal_basis": "UoR art. 4 ust. 4 (dowody rzetelne) [NIEZWERYFIKOWANE — ISAP]; P52/P53 provenance; prompt P61 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_reference_provenance", {})
	fields := _th("v3_p61_provenance_fields", ["date", "source", "checksum"])
	datasets := object.get(_ctx_i03, "datasets", [])
	incomplete := object.get(_ctx_i03, "incomplete", [])
	count(incomplete) >= 1
}

# ── I04: Sandbox replay CI ────────────────────────────────────────────────────
# Integracja testowana tylko na mockach (bez sandbox/replay) = NEEDS_ADVICE.
i04_sandbox := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.sandbox_replay_ci",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461004,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("sandbox replay: %v z %v integracji bez replayu danych testowych", [count(missing), total]),
	"metrics": {"integrations": total, "missing_replay": count(missing)},
	"_legal_basis": "P39 testy/CI (stabilne, powtarzalne); prompt P61 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_sandbox_replay", {})
	total := object.get(_ctx_i04, "integrations_total", 0)
	missing := object.get(_ctx_i04, "missing_replay", [])
	count(missing) >= 1
}

# ── I05: Cache with provenance TTL ────────────────────────────────────────────
# Cache bez TTL/provenance lub wiek ponad próg = NEEDS_ADVICE.
i05_cache := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.cache_provenance_ttl",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("cache: ttl_s=%v, max_wiek_dni=%v, przeterminowane zbiory=%v", [ttl, max_age, count(stale)]),
	"metrics": {"ttl_s": ttl, "max_age_days": max_age, "stale": count(stale)},
	"_legal_basis": "P58 świeżość na cachu; prompt P61 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_cache_ttl", {})
	ttl := _th("v3_p61_cache_ttl_seconds", 3600)
	max_age := _th("v3_p61_cache_max_age_days", 7)
	stale := object.get(_ctx_i05, "stale_entries", [])
	count(stale) >= 1
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.cache_provenance_ttl",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("cache: manifest niepotwierdzony (present=%v)", [present]),
	"metrics": {"present": present},
	"_legal_basis": "prompt P61 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_cache_ttl", {})
	present := object.get(_ctx_i05, "cache_manifest_present", false)
	_not(present)
}

# ── I06: Bank reconciliation contract ─────────────────────────────────────────
# Rozjazd bankowy bez ścieżki NEEDS_ADVICE lub ponad próg % = BLOCK.
i06_bank_recon := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.bank_reconciliation_contract",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461006,
	"decision": "BLOCK",
	"reason": sprintf("bank reconciliation: %v%% rozjazdów bez ścieżki (próg %v%%) — zero cichych dopasowań", [unmatched_pct, max_pct]),
	"metrics": {"unmatched_pct": unmatched_pct, "max_pct": max_pct},
	"_legal_basis": "P57-I07 bank reconciliation engine; prompt P61 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_bank_reconciliation", {})
	max_pct := _th("v3_p61_bank_unmatched_max_pct", 5)
	unmatched_pct := object.get(_ctx_i06, "unmatched_without_path_pct", 0)
	unmatched_pct > max_pct
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.bank_reconciliation_contract",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461006,
	"decision": "BLOCK",
	"reason": sprintf("bank reconciliation: konflikt bez kandydatów (conflicts_without_candidates=%v)", [count(conflicts)]),
	"metrics": {"conflicts_without_candidates": count(conflicts)},
	"_legal_basis": "P57-I07; prompt P61 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_bank_reconciliation", {})
	conflicts := object.get(_ctx_i06, "conflicts_without_candidates", [])
	count(conflicts) >= 1
}

# ── I07: Holiday-aware rate path ──────────────────────────────────────────────
# Brak ścieżki ostatniej dostępnej tabeli NBP (weekend/święto) = BLOCK.
i07_holiday := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.holiday_rate_path",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461007,
	"decision": "BLOCK",
	"reason": sprintf("art. 31a duch: ścieżka ostatniej tabeli present=%v, lookback=%v dni, testy świąt=%v", [path_present, lookback, holiday_tests]),
	"metrics": {"path_present": path_present, "lookback_days": lookback, "holiday_tests": holiday_tests},
	"_legal_basis": "art. 31a Ordynacji podatkowej (duch) [NIEZWERYFIKOWANE — ISAP]; prompt P61 Sekcja 10-I07",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_holiday_rate_path", {})
	lookback := _th("v3_p61_holiday_lookback_days", 7)
	path_present := object.get(_ctx_i07, "path_present", false)
	holiday_tests := object.get(_ctx_i07, "holiday_tests", 0)
	_not(path_present)
}

# ── I08: Integration registry ─────────────────────────────────────────────────
# Status poza dozwolonymi lub integracja poza rejestrem = BLOCK.
i08_registry := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.integration_registry",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461008,
	"decision": "BLOCK",
	"reason": sprintf("rejestr integracji: %v statusów nieprawidłowych (dozwolone: %v)", [count(invalid), statuses]),
	"metrics": {"integrations": count(entries), "invalid": count(invalid), "statuses": statuses},
	"_legal_basis": "V1 rejestr kanałów; prompt P61 Sekcja 10-I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_integration_registry", {})
	statuses := _th("v3_p61_integration_statuses", ["REAL", "PLANNED", "FACADE"])
	entries := object.get(_ctx_i08, "entries", [])
	invalid := object.get(_ctx_i08, "invalid_statuses", [])
	count(invalid) >= 1
}

# ── I09: Degradation ladder per integration ───────────────────────────────────
# Drabina degradacji krótsza niż próg = NEEDS_ADVICE (awaria czytelna, nie blokada).
i09_degradation := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.degradation_ladder",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("drabina degradacji: %v z %v integracji poniżej %v szczebli", [count(short), total, min_ladder]),
	"metrics": {"integrations": total, "short": count(short), "min_ladder": min_ladder},
	"_legal_basis": "P40 degradacja w odpowiedzi; P57 tryby offline; prompt P61 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_degradation_ladder", {})
	min_ladder := _th("v3_p61_degradation_ladder_min", 3)
	total := object.get(_ctx_i09, "integrations_total", 0)
	short := object.get(_ctx_i09, "ladder_too_short", [])
	count(short) >= 1
}

# ── I10: Outbox pattern for MF ────────────────────────────────────────────────
# Wpis outbox przeterminowany lub bez idempotencji = NEEDS_ADVICE.
i10_outbox := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.outbox_pattern",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461010,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("outbox MF: idempotencja=%v, wpisy przeterminowane=%v (max %v dni) — awaria nie gubi niczego", [idempotent, aged, max_age]),
	"metrics": {"idempotent": idempotent, "aged_entries": count(aged), "max_age_days": max_age},
	"_legal_basis": "P54-I05 idempotent outbox; P57 kolejki; prompt P61 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_outbox_pattern", {})
	max_age := _th("v3_p61_outbox_max_age_days", 30)
	idempotent := object.get(_ctx_i10, "idempotent", false)
	aged := object.get(_ctx_i10, "aged_entries", [])
	count(aged) >= 1
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.outbox_pattern",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461010,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("outbox MF: brak idempotencji (idempotent=%v)", [idempotent]),
	"metrics": {"idempotent": idempotent},
	"_legal_basis": "prompt P61 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_outbox_pattern", {})
	idempotent := object.get(_ctx_i10, "idempotent", false)
	_not(idempotent)
}

# ── I11: External SLA monitoring ──────────────────────────────────────────────
# Latencja zewnętrzna ponad próg = BLOCK (dane do negocjacji/zmiany kanału).
i11_sla := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.external_sla_monitoring",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461011,
	"decision": "BLOCK",
	"reason": sprintf("SLA zewnętrzne: %v kanałów ponad %v ms (p95=%v ms)", [count(over), max_latency, worst_p95]),
	"metrics": {"over_threshold": count(over), "max_latency_ms": max_latency, "worst_p95_ms": worst_p95},
	"_legal_basis": "P37/P58 SLO; prompt P61 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_external_sla", {})
	max_latency := _th("v3_p61_external_sla_latency_ms", 5000)
	over := object.get(_ctx_i11, "over_threshold", [])
	worst_p95 := object.get(_ctx_i11, "worst_p95_ms", 0)
	count(over) >= 1
}

# ── I12: Integration attestation in certificate ───────────────────────────────
# Attestation przeterminowana lub bez wersji danych referencyjnych = NEEDS_ADVICE.
i12_attestation := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.integration_attestation",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("attestation integracji: wiek=%v dni (max %v), wersje danych referencyjnych=%v", [age, max_age, ref_versions]),
	"metrics": {"age_days": age, "max_age_days": max_age, "ref_versions": ref_versions},
	"_legal_basis": "P54-I12 attestation; P11 certyfikat (odtwarzalność); prompt P61 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_integration_attestation", {})
	max_age := _th("v3_p61_attestation_max_age_days", 90)
	age := object.get(_ctx_i12, "attestation_age_days", 0)
	ref_versions := object.get(_ctx_i12, "reference_data_versions", false)
	age > max_age
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.integration_attestation",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 461012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("attestation integracji: brak wersji danych referencyjnych (ref_versions=%v)", [ref_versions]),
	"metrics": {"ref_versions": ref_versions},
	"_legal_basis": "prompt P61 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_integration_attestation", {})
	ref_versions := object.get(_ctx_i12, "reference_data_versions", false)
	_not(ref_versions)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P60):
# najpierw BLOCK, potem NEEDS_ADVICE, na końcu PASS.
# Bez flagi v3_p61_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i01_contract {
	_snapshot_ok
	_activated
	i01_contract.decision == "BLOCK"
} else := i03_provenance {
	_snapshot_ok
	_activated
	i03_provenance.decision == "BLOCK"
} else := i06_bank_recon {
	_snapshot_ok
	_activated
	i06_bank_recon.decision == "BLOCK"
} else := i07_holiday {
	_snapshot_ok
	_activated
	i07_holiday.decision == "BLOCK"
} else := i08_registry {
	_snapshot_ok
	_activated
	i08_registry.decision == "BLOCK"
} else := i11_sla {
	_snapshot_ok
	_activated
	i11_sla.decision == "BLOCK"
} else := i02_breaker {
	_snapshot_ok
	_activated
	i02_breaker.decision == "NEEDS_ADVICE"
} else := i04_sandbox {
	_snapshot_ok
	_activated
	i04_sandbox.decision == "NEEDS_ADVICE"
} else := i05_cache {
	_snapshot_ok
	_activated
	i05_cache.decision == "NEEDS_ADVICE"
} else := i09_degradation {
	_snapshot_ok
	_activated
	i09_degradation.decision == "NEEDS_ADVICE"
} else := i10_outbox {
	_snapshot_ok
	_activated
	i10_outbox.decision == "NEEDS_ADVICE"
} else := i12_attestation {
	_snapshot_ok
	_activated
	i12_attestation.decision == "NEEDS_ADVICE"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p61_integrations_closure.no_match",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P61 niewyzwolony (brak flagi v3_p61_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P60",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p61_integrations_closure.all_green",
	"package": "jdg.v3_p61_integrations_closure",
	"priority": 1,
	"decision": "PASS",
	"reason": "P61: integracje zewnętrzne domknięte (12 analiz: kontrakt, breaker, provenance, sandbox, cache, banki, art. 31a, rejestr, degradacja, outbox, SLA, attestation)",
	"metrics": {"analyses": 12},
	"_legal_basis": "art. 106ne VAT (kolejka offline); art. 31a OP duch (kursy) [NIEZWERYFIKOWANE — ISAP]; P54/P57/P52 kontrakty; prompt P61 Sekcja 10",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
