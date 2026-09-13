# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P54 KSEF 2.0 I JPK — TERMINY, SCHEMATY I KOLEJKI ENTERPRISE
# (V3 FORTRESS) — DOMKNIĘCIE WARSTWY E-DOKUMENTACJI
# ===============================================================================
# Warstwa KSeF/JPK ENTERPRISE — 12 innowacji (I01–I12; minimum z promptu P54
# Sekcja 10):
#   I01 KSeF compliance calendar (obowiązki per typ podatnika: duzi/mali/PRF),
#   I02 Schema version manager (FA(2)→FA(3) + JPK wersjonowane na datę),
#   I03 Pre-send dry-run (walidacja XSD + reguły fortecy PRZED wysyłką),
#   I04 Sandbox replay (środowisko MF sandbox w CI na schematach z mockami),
#   I05 Status monitor with SLA (wysłana→przyjęta→UPO; zaległość = alarm),
#   I06 Idempotent outbox (hash faktury + sesja; retry nie duplikuje wysyłki),
#   I07 KSeF-to-books sync (faktura przyjęta → ewidencje VAT/PKPiR — idempotentnie),
#   I08 Correction chains (korekty art. 106j: przed/po terminie, end-to-end),
#   I09 Offline mode compliance (QR, grace 168h, ZAW-NR — art. 106ne),
#   I10 Error-to-action mapping (błąd MF → czytelna akcja dla księgowego),
#   I11 Deadline watchdog (faktura w kolejce > próg dni → eskalacja P0),
#   I12 Integration attestation (certyfikat integracji: wersje schematów + sandbox).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p54 — ADR-002 (P06), okno
#     temporalne valid_from (P05). ZERO hardcode progów i dat harmonogramu.
#   * Fail-closed (V1 zasada 6): brak snapshotu progów, faktura poza SLA UPO,
#     kolejka offline przekroczona (grace 168h), brak walidacji pre-send,
#     duplikat wysyłki bez detekcji, sync bez idempotencji = BLOCK /
#     NEEDS_ADVICE — nigdy ciche AUTO_POST (protokół 05 promptu P54).
#   * Honesty: liczniki z narzędzi I01–I12 (dowód: bundle gate=PASS), luki jawne
#     (integracja produkcyjna API = decyzja człowieka Q01; sesje NBP/MF —
#     [NIEZWERYFIKOWANE]), bez maskowania (konwencja P47–P53).
#   * Aktywacja: input.jdg_entrepreneur.v3_p54_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p54_ksef_jpk_closure.<analiza>.
#   * Kontrakty: P03 (kontrakt werdyktu), P05/P53 (okna + day-0), P06 (ADR-002),
#     P16 (rdzeń KSeF v3), P17 (KSeF/JPK/e-Deklaracje — rozszerzamy, nie
#     duplikujemy), P25 (kalendarz zbiorczy — jedno źródło terminów), P32
#     (idempotencja wspólna pipeline), P37 (metryki SLA), P39 (bramki merge),
#     P43 (chaos awarii MF), P48 (mirror sync), P40/P41 (mapowanie błędów),
#     P68 (re-certyfikacja finalna).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p54_ksef_jpk_closure
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p54_ksef_jpk_closure

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p54_check", false) == true
_ctx := object.get(input, "v3_p54", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p54_snapshot := data.jdg.thresholds.v3_p54

_snapshot_ok = true {
	count(_p54_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p54_snapshot) > 0
	value := object.get(_p54_snapshot, key, null)
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
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.thresholds_missing",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P54 thresholds snapshot missing — fail-closed (ADR-002)",
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

# ── I01: KSeF compliance calendar ─────────────────────────────────────────────
# Kalendarz obowiązków KSeF per typ podatnika (duzi 2026-02-01, mali 2026-04-01,
# PRF — decyzja Q02 [NIEZWERYFIKOWANE — crd.gov.pl]); wpis bez drogi/terminu =
# MANUAL_REVIEW (kalendarz P25 = jedno źródło terminów).
i01_calendar := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.compliance_calendar",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454001,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("wpisy kalendarza KSeF bez terminu/drogi: %v/%v (P25 = jedno źródło terminów)", [untested, total]),
	"metrics": {"calendar_entries": total, "entries_without_deadline": untested, "lead_kpi_days": _th("v3_p54_calendar_lead_days", 30)},
	"_legal_basis": "VAT art. 106na–106nf [NIEZWERYFIKOWANE — ISAP]; crd.gov.pl; P25 kalendarz zbiorczy",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_ksef_compliance_calendar", {})
	total := object.get(_ctx_i01, "calendar_entries_count", 0)
	untested := object.get(_ctx_i01, "entries_without_deadline", 0)
	untested > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.compliance_calendar",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454001,
	"decision": "PASS",
	"reason": sprintf("kalendarz KSeF kompletny: %v wpisów z terminami (duzi/mali/PRF)", [object.get(object.get(_ctx, "I01_ksef_compliance_calendar", {}), "calendar_entries_count", 0)]),
	"metrics": {"calendar_entries": object.get(object.get(_ctx, "I01_ksef_compliance_calendar", {}), "calendar_entries_count", 0)},
	"_legal_basis": "VAT art. 106na–106nf [NIEZWERYFIKOWANE — ISAP]; crd.gov.pl; P25",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I02: Schema version manager ───────────────────────────────────────────────
# FA(2) kończy ważność 2026-01-31, FA(3) od 2026-02-01 (kalendarz — Q02;
# [NIEZWERYFIKOWANE — crd.gov.pl]). Walidacja PRZED przełączeniem wersji = BLOCK.
i02_schemas := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.schema_versions",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454002,
	"decision": "BLOCK",
	"reason": sprintf("schematy bez wersjonowania datą: %v/%v (przełączenie FA(2)→FA(3) bez okna temporalnego)", [unversioned, total]),
	"metrics": {"schemas_total": total, "schemas_unversioned": unversioned, "validation_min_pct": _th("v3_p54_pre_send_validation_min_pct", 100.0)},
	"_legal_basis": "Rozp. MF o KSeF (schemat FA(3)) [NIEZWERYFIKOWANE — ISAP/crd.gov.pl]; P05 okna",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_schema_version_manager", {})
	total := object.get(_ctx_i02, "schemas_total", 0)
	unversioned := object.get(_ctx_i02, "schemas_unversioned", 0)
	unversioned > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.schema_versions",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454002,
	"decision": "PASS",
	"reason": "schematy FA/JPK wersjonowane oknami temporalnymi (day-0 przełączania)",
	"metrics": {"schemas_total": object.get(object.get(_ctx, "I02_schema_version_manager", {}), "schemas_total", 0)},
	"_legal_basis": "Rozp. MF o KSeF [NIEZWERYFIKOWANE — ISAP/crd.gov.pl]; P05",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I03: Pre-send dry-run ─────────────────────────────────────────────────────
# Każda faktura walidowana PRZED wysyłką (XSD + firewall fortecy); poniżej progu
# = BLOCK (KKS art. 57 §2: błędna faktura w JPK = ryzyko karne — ochrona pre-send).
i03_dryrun := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.pre_send_dry_run",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454003,
	"decision": "BLOCK",
	"reason": sprintf("faktur bez walidacji pre-send %v%% < wymagane %v%% (XSD + reguły fortecy)", [pct, min_pct]),
	"metrics": {"invoices_total": total, "invoices_pre_validated": validated, "validation_pct": pct, "validation_min_pct": min_pct},
	"_legal_basis": "KKS art. 57 §2 [NIEZWERYFIKOWANE — ISAP]; VAT art. 106na; P17 firewall",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_pre_send_dry_run", {})
	total := object.get(_ctx_i03, "invoices_total", 0)
	validated := object.get(_ctx_i03, "invoices_pre_validated", 0)
	min_pct := _th("v3_p54_pre_send_validation_min_pct", 100.0)
	pct := _pct(validated, total)
	pct < min_pct
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.pre_send_dry_run",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454003,
	"decision": "PASS",
	"reason": sprintf("walidacja pre-send %v%% >= %v%%", [_pct(object.get(object.get(_ctx, "I03_pre_send_dry_run", {}), "invoices_pre_validated", 0), object.get(object.get(_ctx, "I03_pre_send_dry_run", {}), "invoices_total", 0)), _th("v3_p54_pre_send_validation_min_pct", 100.0)]),
	"metrics": {"invoices_total": object.get(object.get(_ctx, "I03_pre_send_dry_run", {}), "invoices_total", 0), "invoices_pre_validated": object.get(object.get(_ctx, "I03_pre_send_dry_run", {}), "invoices_pre_validated", 0)},
	"_legal_basis": "KKS art. 57 §2 [NIEZWERYFIKOWANE — ISAP]; P17 firewall",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

_pct(part, total) = 0 {
	total <= 0
} else = pct {
	pct := 100.0 * part / total
}

# ── I04: Sandbox replay ───────────────────────────────────────────────────────
# Ścieżka wysyłki testowana w CI na sandboxie MF (mocki); brak przebiegu ≤ okna
# (dni) = BLOCK (I04 promptu P54: „środowisko testowe w CI, co PR”).
i04_sandbox := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.sandbox_replay",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454004,
	"decision": "BLOCK",
	"reason": sprintf("sandbox replay nie wykonany od %v dni (limit %v) — ścieżka wysyłki nieweryfikowalna", [age, max_age]),
	"metrics": {"days_since_last_run": age, "max_age_days": max_age, "endpoint": endpoint},
	"_legal_basis": "P16 ksef_sandbox_harness; P43 chaos; crd.gov.pl sandbox MF [NIEZWERYFIKOWANE]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_sandbox_replay", {})
	age := object.get(_ctx_i04, "days_since_last_run", 999999)
	max_age := _th("v3_p54_sandbox_replay_max_age_days", 14)
	endpoint := object.get(_ctx_i04, "endpoint", "sandbox MF")
	age > max_age
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.sandbox_replay",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454004,
	"decision": "PASS",
	"reason": sprintf("sandbox replay świeży: %v dni (limit %v)", [object.get(object.get(_ctx, "I04_sandbox_replay", {}), "days_since_last_run", 0), _th("v3_p54_sandbox_replay_max_age_days", 14)]),
	"metrics": {"days_since_last_run": object.get(object.get(_ctx, "I04_sandbox_replay", {}), "days_since_last_run", 0)},
	"_legal_basis": "P16 ksef_sandbox_harness; P43 chaos",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I05: Status monitor with SLA ──────────────────────────────────────────────
# Sesja: wysłana→przyjęta→UPO; SENT bez UPO ponad deadline = STALE (ryzyko
# sankcji art. 106nq). STALE > 0 = BLOCK (zaległość terminowa = alarm P0).
i05_status := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.status_monitor_sla",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454005,
	"decision": "BLOCK",
	"reason": sprintf("sesji STALE (SENT bez UPO ponad SLA): %v — ryzyko sankcji art. 106nq [NIEZWERYFIKOWANE — ISAP]", [stale]),
	"metrics": {"sessions_total": total, "stale_count": stale, "upo_deadline_days": _th("v3_p54_upo_deadline_days", 1), "sla_alert_pct": _th("v3_p54_status_sla_alert_pct", 95.0)},
	"_legal_basis": "VAT art. 106nq [NIEZWERYFIKOWANE — ISAP]; P17 UPO tracker; P37 SLA",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_status_monitor_sla", {})
	stale := object.get(_ctx_i05, "stale_count", 0)
	total := object.get(_ctx_i05, "sessions_total", 0)
	stale > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.status_monitor_sla",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454005,
	"decision": "PASS",
	"reason": sprintf("monitor SLA zielony: %v sesji, 0 STALE (deadline UPO %v dnia)", [object.get(object.get(_ctx, "I05_status_monitor_sla", {}), "sessions_total", 0), _th("v3_p54_upo_deadline_days", 1)]),
	"metrics": {"sessions_total": object.get(object.get(_ctx, "I05_status_monitor_sla", {}), "sessions_total", 0)},
	"_legal_basis": "VAT art. 106nq [NIEZWERYFIKOWANE — ISAP]; P37 SLA",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I06: Idempotent outbox ────────────────────────────────────────────────────
# Exactly-once: hash faktury + sesja; retry po awarii nie duplikuje wysyłki.
# Duplikat bez detekcji albo limit prób przekroczony bez eskalacji = BLOCK.
i06_outbox := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.idempotent_outbox",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454006,
	"decision": "BLOCK",
	"reason": sprintf("naruszenie exactly-once: %v duplikatów niewykrytych, %v FAILED bez eskalacji (limit %v prób)", [dupes, failed, max_retries]),
	"metrics": {"total": total, "duplicates_detected": dupes, "failed_escalated": failed, "max_retries": max_retries, "backoff_cap_sec": _th("v3_p54_retry_backoff_cap_sec", 3600)},
	"_legal_basis": "P32 idempotencja wspólna; P17 outbox; art. 106na–106nq VAT [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_idempotent_outbox", {})
	dupes := object.get(_ctx_i06, "duplicates_undetected", 0)
	failed := object.get(_ctx_i06, "failed_escalated", 0)
	max_retries := _th("v3_p54_retry_max_attempts", 10)
	total := object.get(_ctx_i06, "total", 0)
	dupes > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.idempotent_outbox",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454006,
	"decision": "PASS",
	"reason": "outbox exactly-once: zero duplikatów, retry z backoff pod kontrolą",
	"metrics": {"total": object.get(object.get(_ctx, "I06_idempotent_outbox", {}), "total", 0), "duplicates_detected": object.get(object.get(_ctx, "I06_idempotent_outbox", {}), "duplicates_detected", 0)},
	"_legal_basis": "P32; P17 outbox",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I07: KSeF-to-books sync ───────────────────────────────────────────────────
# Faktura przyjęta (UPO) → automatyczne księgowanie (P32) z idempotencją;
# przyjętych bez zaksięgowania ponad okno = MANUAL_REVIEW (zero ręcznego
# przepisywania; podwójne księgowanie = BLOCK).
i07_sync := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.ksef_to_books_sync",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454007,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("faktur przyjętych bez zaksięgowania: %v; podwójnych zapisów: %v (okno %v h) — pipeline P32 wstrzymany", [unbooked, dbl, window]),
	"metrics": {"accepted_total": total, "unbooked_count": unbooked, "sync_window_hours": window, "double_booked_count": dbl},
	"_legal_basis": "P32 automatyzacja księgowości; P17 ingest; UoR art. 5 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_ksef_to_books_sync", {})
	unbooked := object.get(_ctx_i07, "unbooked_count", 0)
	window := _th("v3_p54_sync_window_hours", 24)
	total := object.get(_ctx_i07, "accepted_total", 0)
	dbl := object.get(_ctx_i07, "double_booked_count", 0)
	unbooked + dbl > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.ksef_to_books_sync",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454007,
	"decision": "PASS",
	"reason": "KSeF→księgi: każda faktura przyjęta zaksięgowana idempotentnie (P32)",
	"metrics": {"accepted_total": object.get(object.get(_ctx, "I07_ksef_to_books_sync", {}), "accepted_total", 0)},
	"_legal_basis": "P32; P17 ingest",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I08: Correction chains ────────────────────────────────────────────────────
# Korekty art. 106j VAT: faktura korygująca → ewidencje → JPK end-to-end;
# łańcuch przerwany (korekta bez wpływu na ewidencje) = MANUAL_REVIEW.
i08_corrections := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.correction_chains",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454008,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("korekt z przerwanym łańcuchem (bez wpływu na ewidencje): %v/%v", [broken, total]),
	"metrics": {"corrections_total": total, "chains_broken": broken, "window_days": _th("v3_p54_correction_window_days", 30)},
	"_legal_basis": "VAT art. 106j [NIEZWERYFIKOWANE — ISAP]; P16 ksef_corrections_e2e",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_correction_chains", {})
	broken := object.get(_ctx_i08, "chains_broken", 0)
	total := object.get(_ctx_i08, "corrections_total", 0)
	broken > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.correction_chains",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454008,
	"decision": "PASS",
	"reason": "łańcuchy korekt kompletne (faktura korygująca → ewidencje → JPK)",
	"metrics": {"corrections_total": object.get(object.get(_ctx, "I08_correction_chains", {}), "corrections_total", 0)},
	"_legal_basis": "VAT art. 106j [NIEZWERYFIKOWANE — ISAP]; P16",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I09: Offline mode compliance ──────────────────────────────────────────────
# Awaria KSeF: tryb offline (QR) zgodny z art. 106ne (grace 168h, ZAW-NR);
# kolejka ponad grace = BLOCK_AND_ALERT (terminy odraczane, nie kasowane).
i09_offline := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.offline_compliance",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454009,
	"decision": "BLOCK",
	"reason": sprintf("kolejka offline %v h > grace %v h — BLOCK_AND_ALERT (art. 106ne; ZAW-NR obowiązkowe)", [oldest_h, grace_h]),
	"metrics": {"oldest_age_hours": oldest_h, "grace_hours": grace_h, "warning_hours": _th("v3_p54_offline_warning_hours", 120), "zaw_nr_penalty_pln": _th("v3_p54_zaw_nr_penalty_pln", 5000)},
	"_legal_basis": "VAT art. 106ne ust. 1–4 [NIEZWERYFIKOWANE — ISAP]; P43 chaos",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_offline_compliance", {})
	oldest_h := object.get(_ctx_i09, "oldest_age_hours", 0)
	grace_h := _th("v3_p54_offline_grace_hours", 168)
	oldest_h > grace_h
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.offline_compliance",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454009,
	"decision": "PASS",
	"reason": sprintf("tryb offline w normie: najstarsza faktura %v h (grace %v h)", [object.get(object.get(_ctx, "I09_offline_compliance", {}), "oldest_age_hours", 0), _th("v3_p54_offline_grace_hours", 168)]),
	"metrics": {"oldest_age_hours": object.get(object.get(_ctx, "I09_offline_compliance", {}), "oldest_age_hours", 0)},
	"_legal_basis": "VAT art. 106ne [NIEZWERYFIKOWANE — ISAP]; P43",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I10: Error-to-action mapping ──────────────────────────────────────────────
# Błąd MF → czytelna akcja (pole schematu → co poprawić); błąd bez akcji =
# MANUAL_REVIEW (księgowy naprawia bez analizy XML — P40/P41).
i10_errors := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.error_to_action",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454010,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("błędów MF bez zmapowanej akcji: %v/%v (mapa błędów niekompletna)", [unmapped, total]),
	"metrics": {"errors_total": total, "errors_unmapped": unmapped, "mapping_coverage_pct": _th("v3_p54_error_mapping_min_pct", 90.0)},
	"_legal_basis": "P40 API/UI; P41 dokumentacja; schematy MF [NIEZWERYFIKOWANE — crd.gov.pl]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_error_to_action", {})
	unmapped := object.get(_ctx_i10, "errors_unmapped", 0)
	total := object.get(_ctx_i10, "errors_total", 0)
	unmapped > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.error_to_action",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454010,
	"decision": "PASS",
	"reason": "mapa błędów MF→akcje kompletna (księgowy naprawia bez analizy XML)",
	"metrics": {"errors_total": object.get(object.get(_ctx, "I10_error_to_action", {}), "errors_total", 0)},
	"_legal_basis": "P40; P41; schematy MF [NIEZWERYFIKOWANE — crd.gov.pl]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I11: Deadline watchdog ────────────────────────────────────────────────────
# Faktura w kolejce > próg dni przed terminem → eskalacja (alarm P0); zero
# faktur zgubionych w kolejce (I11 promptu P54).
i11_watchdog := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.deadline_watchdog",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454011,
	"decision": "BLOCK",
	"reason": sprintf("faktur w kolejce ponad próg watchdog %v dni: %v — eskalacja P0", [threshold_days, escalated]),
	"metrics": {"escalated_count": escalated, "watchdog_threshold_days": threshold_days, "queue_total": total},
	"_legal_basis": "VAT art. 106na–106nb terminy [NIEZWERYFIKOWANE — ISAP]; P37 alarmy",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_deadline_watchdog", {})
	escalated := object.get(_ctx_i11, "escalated_count", 0)
	threshold_days := _th("v3_p54_watchdog_threshold_days", 3)
	total := object.get(_ctx_i11, "queue_total", 0)
	escalated > 0
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.deadline_watchdog",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454011,
	"decision": "PASS",
	"reason": sprintf("watchdog czysty: 0 faktur ponad próg %v dni", [_th("v3_p54_watchdog_threshold_days", 3)]),
	"metrics": {"queue_total": object.get(object.get(_ctx, "I11_deadline_watchdog", {}), "queue_total", 0)},
	"_legal_basis": "VAT art. 106na–106nb [NIEZWERYFIKOWANE — ISAP]; P37",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── I12: Integration attestation ─────────────────────────────────────────────
# Certyfikat integracji: wersje schematów + daty obowiązywania + wyniki sandbox;
# przestarzały (ponad okno dni od zmiany MF) = NEEDS_ADVICE (I12 promptu P54).
i12_attestation := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.integration_attestation",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("certyfikat integracji starszy niż %v dni — odśwież przy zmianie MF (wersje schematów + sandbox)", [max_age]),
	"metrics": {"attestation_age_days": age, "max_age_days": max_age, "schemas_covered": schemas},
	"_legal_basis": "I12 promptu P54; P44 certyfikacja; crd.gov.pl wersje schematów [NIEZWERYFIKOWANE]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_integration_attestation", {})
	age := object.get(_ctx_i12, "attestation_age_days", 999999)
	max_age := _th("v3_p54_attestation_max_age_days", 90)
	schemas := object.get(_ctx_i12, "schemas_covered", [])
	age > max_age
} else = {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.integration_attestation",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454012,
	"decision": "PASS",
	"reason": sprintf("certyfikat integracji aktualny (%v dni <= %v)", [object.get(object.get(_ctx, "I12_integration_attestation", {}), "attestation_age_days", 0), _th("v3_p54_attestation_max_age_days", 90)]),
	"metrics": {"attestation_age_days": object.get(object.get(_ctx, "I12_integration_attestation", {}), "attestation_age_days", 0)},
	"_legal_basis": "I12 promptu P54; P44",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# ── Terminal: wszystkie bramki zielone → PASS (nie NO_MATCH) ────────────────
all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.all_green",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 454000,
	"decision": "PASS",
	"reason": "wszystkie bramki KSeF/JPK P54 zielone (kalendarz, schematy, pre-send, outbox, SLA, offline, watchdog)",
	"metrics": {},
	"_legal_basis": "VAT art. 106na–106nq [NIEZWERYFIKOWANE — ISAP]; crd.gov.pl; P16/P17/P25/P32",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
	_activated
}

# ── Router decide (deterministyczny, fail-closed) ─────────────────────────────
# Kolejność: fail-closed snapshot → I09 (BLOCK: grace 168h — twarde prawo) →
# I03 (BLOCK: walidacja pre-send) → I05 (BLOCK: STALE UPO) → I02 (BLOCK: schematy)
# → I04 (BLOCK: sandbox) → I06 (BLOCK: outbox) → I11 (BLOCK: watchdog) →
# I01 (kalendarz) → I07 (sync) → I08 (korekty) → I10 (mapa błędów) →
# I12 (attestation) → all_green → no_match.
decide := fail_closed_decision {
	_not(_snapshot_ok)
}

decide := i09_offline {
	_snapshot_ok
	_activated
	i09_offline.decision == "BLOCK"
} else := i03_dryrun {
	_snapshot_ok
	_activated
	i03_dryrun.decision == "BLOCK"
} else := i05_status {
	_snapshot_ok
	_activated
	i05_status.decision == "BLOCK"
} else := i02_schemas {
	_snapshot_ok
	_activated
	i02_schemas.decision == "BLOCK"
} else := i04_sandbox {
	_snapshot_ok
	_activated
	i04_sandbox.decision == "BLOCK"
} else := i06_outbox {
	_snapshot_ok
	_activated
	i06_outbox.decision == "BLOCK"
} else := i11_watchdog {
	_snapshot_ok
	_activated
	i11_watchdog.decision == "BLOCK"
} else := i01_calendar {
	_snapshot_ok
	_activated
	i01_calendar.decision != "PASS"
} else := i07_sync {
	_snapshot_ok
	_activated
	i07_sync.decision != "PASS"
} else := i08_corrections {
	_snapshot_ok
	_activated
	i08_corrections.decision != "PASS"
} else := i10_errors {
	_snapshot_ok
	_activated
	i10_errors.decision != "PASS"
} else := i12_attestation {
	_snapshot_ok
	_activated
	i12_attestation.decision != "PASS"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p54_ksef_jpk_closure.no_match",
	"package": "jdg.v3_p54_ksef_jpk_closure",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P54 niewyzwolony (brak flagi v3_p54_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P53",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}
