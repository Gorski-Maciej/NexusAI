# NEXUSAI JDG — V3-P63 RBAC, MULTI-TENANT I DANE — IZOLACJA I UPRAWNIENIA
# ==============================================================================
# Warstwa dostępu i danych ENTERPRISE — 12 innowacji (I01–I12; minimum
# z promptu P63 Sekcja 10; konwencja P51–P62):
#
#   I01 RBAC as data — 4 role (entrepreneur/accountant/auditor/admin) z
#       mapowaniem rola→pola werdyktu (P40-I04); brak roli = BLOCK.
#   I02 Separation of duties — 4-eyes wymaga różnych osób (P44/P47);
#       brak mechanizmu = NEEDS_ADVICE.
#   I03 Tenant isolation — zero cross-tenant leaks (rozszerzenie P57-I11);
#       leak > próg = BLOCK.
#   I04 Break-glass with review — dostęp awaryjny oznaczony + obowiązkowy
#       review; brak = NEEDS_ADVICE.
#   I05 Access audit analytics — audyt dostępu WORM (P40-I05) + kanały
#       anomalii (noc/masowe eksporty/powtarzalne wzorce); brak = NEEDS_ADVICE.
#   I06 Right-to-be-forgotten — rodo_erasure_automation (art. 17 RODO +
#       wyjątek art. 74 UoR 5 lat); brak ścieżki = BLOCK.
#   I07 Per-tenant quotas — rate governor (P57-I12, limit/h); brak = NEEDS_ADVICE.
#   I08 Data flow map — rejestr RODO art. 30 generowany z kodu; < min
#       kanałów = NEEDS_ADVICE.
#   I09 Pseudonymization by default — privacy_mode=pseudonymized (P58-I11);
#       inny tryb = BLOCK.
#   I10 Multi-tenant schema readiness — tenant_id w migracjach (001) i
#       kolejkach/rejestrach (P57); brak = NEEDS_ADVICE.
#   I11 Permission drift alarm — rozszerzenie uprawnień (diff RBAC) →
#       alarm + review; brak = NEEDS_ADVICE.
#   I12 Role onboarding pack — przydział roli = pakiet (dostępy, ścieżka
#       czytania P60, obowiązki); brak = NEEDS_ADVICE.
#
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p63 — ADR-002 (P06),
#     okno temporalne valid_from (P05); zero hardcode.
#   * Fail-closed (V1 zasada 6; konwencja P51–P62): brak snapshotu progów =
#     NEEDS_ADVICE; bez flagi v3_p63_check = NO_MATCH; nigdy ciche AUTO_POST.
#   * Konwencja P54–P62: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (tools/v3_p63_engines.py czytają PRAWDZIWE źródła: v3_p40_rbac_
#     minimization, v3_p40_api_audit_worm, v3_p57_tenant_isolation,
#     v3_p57_rate_governor, v3_p58_privacy, v3_p42_retention_calculator,
#     v3_p33_federated_privacy_guard, v3_p44_owner_attestation,
#     v3_p47_human_stamps, rules/rodo_extended.rego (art. 17 RODO),
#     migrations/001_jdg_rule_store.sql, tools/rodo_register_generator.py).
#     Klucze w input.v3_p63 (I01_..–I12_..).
#   * Kontrakty: P03 (werdykt), P06 (ADR-002), P16 (RODO/AML), P40 (RBAC
#     minimalizacja + audyt WORM), P42 (retencja), P44/P47 (4-eyes),
#     P57 (izolacja/quoty), P58 (anomalie), P60 (ścieżki czytania ról),
#     P68. Akty: art. 5 ust. 1c/1f, art. 17, art. 19, art. 30, art. 32 RODO;
#     art. 74 UoR (retencja księgowa) — WSZYSTKIE [NIEZWERYFIKOWANE — ISAP].
#   * Aktywacja: input.jdg_entrepreneur.v3_p63_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p63_rbac_multitenant_closure.<analiza>.
#   * Priorytety: 463001–463012 (I01–I12).
#   * Pakiety importujące (main_jdg.rego): data.jdg.v3_p63_rbac_multitenant_
#     closure → final_verdict_p127 = safe_merge(final_verdict_p126, …).
# ==============================================================================

package jdg.v3_p63_rbac_multitenant_closure

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p63_check", false) == true
_ctx := object.get(input, "v3_p63", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p63_snapshot := data.jdg.thresholds.v3_p63

_snapshot_ok = true {
	count(_p63_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p63_snapshot) > 0
	value := object.get(_p63_snapshot, key, null)
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
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.thresholds_missing",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P63 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: RBAC as data ──────────────────────────────────────────────────────────
# Role bez mapowania rola→pola = BLOCK (przedsiębiorca nie może widzieć metryk
# wewnętrznych; minimalizacja na poziomie API, nie tylko UI).
i01_rbac := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.rbac_as_data",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463001,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("RBAC: progi ADR-002 nieokreślone (roles_required=%v) — role muszą być danymi, nie kodem", [count(required_roles)]),
	"metrics": {"required_roles": count(required_roles)},
	"_legal_basis": "art. 5 ust. 1c RODO (minimalizacja) [NIEZWERYFIKOWANE — ISAP]; prompt P63 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_rbac_as_data", {})
	required_roles := _th("v3_p63_roles_required", [])
	count(required_roles) == 0
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.rbac_as_data",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463001,
	"decision": "BLOCK",
	"reason": sprintf("RBAC: %v z %v ról bez mapowania rola→pola — minimalizacja na poziomie API", [count(missing), total]),
	"metrics": {"roles_total": total, "missing_map": count(missing)},
	"_legal_basis": "art. 5 ust. 1c RODO (minimalizacja) [NIEZWERYFIKOWANE — ISAP]; P40-I04 rbac_minimization; prompt P63 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_rbac_as_data", {})
	total := object.get(_ctx_i01, "roles_total", 0)
	missing := object.get(_ctx_i01, "missing_field_map", [])
	count(missing) >= 1
}

# ── I02: Separation of duties ──────────────────────────────────────────────────
# 4-eyes bez rozdzielenia osób = NEEDS_ADVICE (dwa konta jednej osoby to
# nie kontrola).
i02_sod := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.separation_of_duties",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463002,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("separation of duties: wymagane=%v, egzekwowane=%v — 4-eyes musi wymagać różnych osób", [required, enforced]),
	"metrics": {"required": required, "enforced": enforced},
	"_legal_basis": "P44-I11 owner attestation (4-eyes biznesowe); P47-I10 human stamps; prompt P63 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_separation_of_duties", {})
	required := _th("v3_p63_sod_required", true)
	enforced := object.get(_ctx_i02, "enforced", false)
	required
	_not(enforced)
}

# ── I03: Tenant isolation ──────────────────────────────────────────────────────
# Cross-tenant leak ponad próg (0) = BLOCK — dane nie mogą się mieszać
# strukturalnie.
i03_isolation := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.tenant_isolation",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463003,
	"decision": "BLOCK",
	"reason": sprintf("izolacja tenantów: %v leaków (próg %v), brak tenant_id: %v — dane nie mieszają się strukturalnie", [leaks, max_leaks, missing_tenant]),
	"metrics": {"cross_tenant_leaks": leaks, "max": max_leaks, "missing_tenant": count(missing_tenant)},
	"_legal_basis": "art. 5 ust. 1f RODO (integralność i poufność) [NIEZWERYFIKOWANE — ISAP]; P57-I11; prompt P63 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_tenant_isolation", {})
	max_leaks := _th("v3_p63_cross_tenant_leaks_max", 0)
	leaks := object.get(_ctx_i03, "cross_tenant_leaks", 0)
	missing_tenant := object.get(_ctx_i03, "missing_tenant", [])
	leaks > max_leaks
}

# ── I04: Break-glass with review ───────────────────────────────────────────────
# Dostęp awaryjny bez oznaczenia/review = NEEDS_ADVICE (kontrole zamiast
# założeń).
i04_breakglass := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.breakglass_review",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463004,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("break-glass: oznaczenie=%v, obowiązkowy review=%v — dostęp awaryjny pod kontrolą", [flagged, review]),
	"metrics": {"flagged": flagged, "review_required": review},
	"_legal_basis": "P58-I08 eskalacja (runbooki); prompt P63 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_breakglass", {})
	required := _th("v3_p63_breakglass_review_required", true)
	review := object.get(_ctx_i04, "review_required", false)
	required
	_not(review)
}

# ── I05: Access audit analytics ────────────────────────────────────────────────
# Audyt dostępu bez WORM lub bez kanałów anomalii = NEEDS_ADVICE (kto co
# widział musi być dowodem i analizą).
i05_access_audit := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.access_audit_analytics",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("audyt dostępu: WORM=%v, kanały anomalii=%v (wymagane %v)", [worm_gate, count(channels), min_channels]),
	"metrics": {"worm_gate": worm_gate, "anomaly_channels": channels},
	"_legal_basis": "art. 30 RODO (rejestr czynności) [NIEZWERYFIKOWANE — ISAP]; P40-I05 API audit WORM; P58 anomalie; prompt P63 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_access_audit", {})
	worm_gate := object.get(_ctx_i05, "worm_gate", "MISSING")
	worm_gate != "PASS"
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.access_audit_analytics",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("audyt dostępu: kanały anomalii=%v (wymagane %v)", [count(channels), min_channels]),
	"metrics": {"anomaly_channels": channels},
	"_legal_basis": "prompt P63 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_access_audit", {})
	min_channels := count(_th("v3_p63_access_audit_anomalies", []))
	channels := object.get(_ctx_i05, "anomaly_channels", [])
	count(channels) < min_channels
}

# ── I06: Right-to-be-forgotten ─────────────────────────────────────────────────
# Brak ścieżki usunięcia z wyjątkiem retencji księgowej = BLOCK (art. 17 RODO
# z art. 74 UoR — przedsiębiorca musi mieć zautomatyzowaną odpowiedź).
i06_erasure := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.right_to_be_forgotten",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463006,
	"decision": "BLOCK",
	"reason": sprintf("prawo do bycia zapomnianym: erasure path=%v, wyjątek retencji %v lat=%v (art. 17 RODO / art. 74 UoR)", [erasure_path, retention_years, exception]),
	"metrics": {"erasure_path": erasure_path, "retention_years": retention_years, "retention_exception": exception},
	"_legal_basis": "art. 17 i 19 RODO (usunięcie/powiadomienie) [NIEZWERYFIKOWANE — ISAP]; art. 74 UoR (5 lat) [NIEZWERYFIKOWANE — ISAP]; rodo_extended.rego P1640; prompt P63 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_right_to_be_forgotten", {})
	retention_years := _th("v3_p63_erasure_retention_years", 5)
	erasure_path := object.get(_ctx_i06, "erasure_path", false)
	_not(erasure_path)
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.right_to_be_forgotten",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463006,
	"decision": "BLOCK",
	"reason": sprintf("prawo do bycia zapomnianym: brak wyjątku retencji księgowej (retention_exception=%v)", [exception]),
	"metrics": {"retention_exception": exception},
	"_legal_basis": "art. 74 UoR [NIEZWERYFIKOWANE — ISAP]; prompt P63 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_right_to_be_forgotten", {})
	retention_years := _th("v3_p63_erasure_retention_years", 5)
	exception := object.get(_ctx_i06, "retention_exception", false)
	retention_years > 0
	_not(exception)
}

# ── I07: Per-tenant quotas ─────────────────────────────────────────────────────
# Brak limitów per tenant = NEEDS_ADVICE (hałas/atak jednego tenant nie może
# degradować pozostałych).
i07_quotas := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.per_tenant_quotas",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463007,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("quoty per tenant: governor=%v, limit ADR-002=%v/h (fair use — ochrona przed hałasem)", [governor, quota]),
	"metrics": {"governor_gate": governor, "quota_per_hour": quota},
	"_legal_basis": "P57-I12 rate governor (fair use); prompt P63 Sekcja 10-I07",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_per_tenant_quotas", {})
	quota := _th("v3_p63_tenant_quota_events_per_hour", 500)
	governor := object.get(_ctx_i07, "governor_gate", "MISSING")
	governor != "PASS"
}

# ── I08: Data flow map ─────────────────────────────────────────────────────────
# Rejestr RODO art. 30 za mały (kanały przepływu) = NEEDS_ADVICE — mapa
# generowana z kodu, nie pisana ręcznie.
i08_dataflow := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.data_flow_map",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463008,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("mapa przepływów: %v kanałów (min %v), kanały=%v", [count(channels), min_channels, channels]),
	"metrics": {"channels": channels, "min_channels": min_channels},
	"_legal_basis": "art. 30 RODO (rejestr kategorii przetwarzania) [NIEZWERYFIKOWANE — ISAP]; P57 rate governor kanały; prompt P63 Sekcja 10-I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_data_flow_map", {})
	min_channels := _th("v3_p63_dataflow_channels_min", 6)
	channels := object.get(_ctx_i08, "channels", [])
	count(channels) < min_channels
}

# ── I09: Pseudonymization by default ───────────────────────────────────────────
# Telemetria w trybie innym niż pseudonymized = BLOCK (RODO by design —
# minimalizacja mechanizmem, nie deklaracją).
i09_pseudonymization := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.pseudonymization_by_default",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463009,
	"decision": "BLOCK",
	"reason": sprintf("pseudonimizacja: tryb=%v (wymagany %v), pii_hits=%v — RODO by design", [mode, required_mode, pii_hits]),
	"metrics": {"privacy_mode": mode, "required": required_mode, "pii_hits": pii_hits},
	"_legal_basis": "art. 5 ust. 1c i art. 32 RODO [NIEZWERYFIKOWANE — ISAP]; P58-I11 privacy; P33-I10 federated guard; prompt P63 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_pseudonymization", {})
	required_mode := _th("v3_p63_privacy_mode_required", "pseudonymized")
	mode := object.get(_ctx_i09, "privacy_mode", "")
	mode != required_mode
}

# ── I10: Multi-tenant schema readiness ─────────────────────────────────────────
# Brak tenant_id w schemacie (migracje/rejestry) = NEEDS_ADVICE — gotowość
# bez future-proofingu na siłę, ale zero wersji „na razie jedyny tenant”.
i10_schema := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.multitenant_schema_readiness",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463010,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("schemat multi-tenant: %v elementów z tenant_id (min %v) — migracje+rejestry+kolejki", [count(elements), min_elements]),
	"metrics": {"elements": elements, "min_elements": min_elements},
	"_legal_basis": "P57-I11 izolacja (policy required); P25-I07 kalendarz per tenant; prompt P63 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_schema_readiness", {})
	min_elements := _th("v3_p63_multitenant_tables_min", 1)
	elements := object.get(_ctx_i10, "elements_with_tenant_id", [])
	count(elements) < min_elements
}

# ── I11: Permission drift alarm ────────────────────────────────────────────────
# Brak alarmu na rozszerzenie uprawnień = NEEDS_ADVICE (manipulacja
# uprawnieniami musi być wykrywalna).
i11_drift := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.permission_drift_alarm",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463011,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("drift uprawnień: alarm=%v, review po zmianie=%v", [alarm, review]),
	"metrics": {"alarm": alarm, "review_after_change": review},
	"_legal_basis": "P48-I04 anti-drift (wzorzec); prompt P63 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_permission_drift", {})
	required := _th("v3_p63_permission_drift_alarm", true)
	alarm := object.get(_ctx_i11, "alarm_present", false)
	required
	_not(alarm)
}

# ── I12: Role onboarding pack ──────────────────────────────────────────────────
# Rola bez pakietu onboardingu = NEEDS_ADVICE — zero ról bez dokumentu
# i testu (ścieżka czytania P60).
i12_onboarding := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.role_onboarding_pack",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 463012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("onboarding ról: wymagane=%v, role z pakietem=%v z %v", [required, count(packed), count(roles)]),
	"metrics": {"roles": roles, "packed": packed},
	"_legal_basis": "P60-I05/I12 mapy rolowe (ścieżki czytania); prompt P63 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_role_onboarding", {})
	required := _th("v3_p63_role_onboarding_required", true)
	roles := object.get(_ctx_i12, "roles", [])
	packed := object.get(_ctx_i12, "packed_roles", [])
	required
	count(packed) < count(roles)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P62):
# najpierw BLOCK, potem NEEDS_ADVICE, na końcu PASS.
# Bez flagi v3_p63_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i01_rbac {
	_snapshot_ok
	_activated
	i01_rbac.decision == "BLOCK"
} else := i03_isolation {
	_snapshot_ok
	_activated
	i03_isolation.decision == "BLOCK"
} else := i06_erasure {
	_snapshot_ok
	_activated
	i06_erasure.decision == "BLOCK"
} else := i09_pseudonymization {
	_snapshot_ok
	_activated
	i09_pseudonymization.decision == "BLOCK"
} else := i02_sod {
	_snapshot_ok
	_activated
	i02_sod.decision == "NEEDS_ADVICE"
} else := i04_breakglass {
	_snapshot_ok
	_activated
	i04_breakglass.decision == "NEEDS_ADVICE"
} else := i05_access_audit {
	_snapshot_ok
	_activated
	i05_access_audit.decision == "NEEDS_ADVICE"
} else := i07_quotas {
	_snapshot_ok
	_activated
	i07_quotas.decision == "NEEDS_ADVICE"
} else := i08_dataflow {
	_snapshot_ok
	_activated
	i08_dataflow.decision == "NEEDS_ADVICE"
} else := i10_schema {
	_snapshot_ok
	_activated
	i10_schema.decision == "NEEDS_ADVICE"
} else := i11_drift {
	_snapshot_ok
	_activated
	i11_drift.decision == "NEEDS_ADVICE"
} else := i12_onboarding {
	_snapshot_ok
	_activated
	i12_onboarding.decision == "NEEDS_ADVICE"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.no_match",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P63 niewyzwolony (brak flagi v3_p63_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P62",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p63_rbac_multitenant_closure.all_green",
	"package": "jdg.v3_p63_rbac_multitenant_closure",
	"priority": 1,
	"decision": "PASS",
	"reason": "P63: RBAC, multi-tenant i dane domknięte (12 analiz: RBAC as data, SoD, izolacja, break-glass, audyt dostępu, art. 17, quoty, mapa przepływów, pseudonimizacja, schemat, drift alarm, onboarding)",
	"metrics": {"analyses": 12},
	"_legal_basis": "art. 5 ust. 1c/1f, art. 17, 19, 30, 32 RODO; art. 74 UoR [NIEZWERYFIKOWANE — ISAP]; prompt P63 Sekcja 10",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
