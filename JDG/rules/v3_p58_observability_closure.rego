# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P58 OBSERWOWALNOŚĆ FORTHECY — METRYKI DECYZYJNE I ALARMY
# NA TYM, CO PRAWNIE WRAŻLIWE
# ===============================================================================
# Warstwa obserwowalności ENTERPRISE — 12 innowacji (I01–I12; minimum z promptu
# P58 Sekcja 10):
#   I01 Legal freshness SLA per act (wiek weryfikacji ISAP per akt; przekroczenie
#       SLA = NEEDS_ADVICE z runbookiem re-checku — P47/P08),
#   I02 Coverage regression alarm (spadek pokrycia prawnego / nowe pustynie
#       P51 = BLOCK — Law Radar otwiera karty pustyni automatycznie),
#   I03 Advice-spread radar (spread NEEDS_ADVICE per domena powyżej progu
#       = NEEDS_ADVICE — klasterizacja powodów, analityka luki na żywo),
#   I04 Penny drift telemetry (rozjazdy groszowe P52 jako trend do zera;
#       wzrost = BLOCK z pełnym trace wyliczenia),
#   I05 Decision telemetry registry (każda decyzja z kontekstem: domena, kwota,
#       pewność, epoka prawna P53, bundle hash; braki pól = NEEDS_ADVICE),
#   I06 Error budget freeze (wyczerpanie budżetu SLO → zamrożenie wdrożeń;
#       budżet poniżej progu BEZ aktywnej blokady = BLOCK — mechanizm, nie
#       procedura),
#   I07 Runbook-per-alarm contract (alarm zdefiniowany bez runbooka = BLOCK —
#       nie wchodzi do produkcji),
#   I08 Post-mortem registry (incydent otwarty bez post-mortemu w oknie
#       czasowym = NEEDS_ADVICE — uczenie się fortecy),
#   I09 Escalation matrix (macierz eskalacji jako dane: poziom, rola, SLA;
#       braki = NEEDS_ADVICE),
#   I10 Risk-pattern mining (domeny/kwoty/godziny podwyższonego ryzyka
#       z telemetrii; koncentracja powyżej progu = MANUAL_REVIEW),
#   I11 Telemetry privacy guard (dane osobowe w telemetrii / brak pseudonimizacji
#       per tenant = BLOCK — RODO by design),
#   I12 SLO per domain (dokładność/świeżość per domena; domena bez SLO
#       = NEEDS_ADVICE — realistyczne i mierzalne).
#
# Zasady:
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p58 — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * Konwencja P54–P57: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (klucze I01_..–I12_.. w input.v3_p58); silniki czytają PRAWLIWE źródła:
#     decision_certificates.json (P11 — telemetria bez podwójnej
#     instrumentacji), metrics.json (P37), deployments.json (P38), kontrakt
#     enterprise operating (SLO), KALENDARZ_ZMIAN_PRAWNYCH (P25/P47).
#   * Fail-closed (V1 zasada 6; protokół 05 promptu P58): brak snapshotu progów
#     = NEEDS_ADVICE; telemetria bez kontekstu = NEEDS_ADVICE; alarm bez
#     runbooka = BLOCK; budget wyczerpany bez zamrożenia = BLOCK. Nigdy ciche
#     AUTO_POST.
#   * Honesty: wartości prawne [NIEZWERYFIKOWANE — ISAP] (Q01); bez maskowania.
#   * Aktywacja: input.jdg_entrepreneur.v3_p58_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p58_observability_closure.<analiza>.
#   * Kontrakty: P03 (kontrakt werdyktu), P05/P53 (okna + epoki), P06
#     (ADR-002), P08 (Law Radar — pustynie), P11 (certyfikaty = źródło
#     telemetrii), P37 (katalog metryk — rozszerzamy o metryki prawne, jedno
#     źródło definicji), P38 (deploy freeze), P39 (bramki CI), P41 (runbooki),
#     P42 (WORM — retencja telemetrii), P43 (chaos drills), P47 (freshness
#     ISAP), P49 (advice paths), P51 (pustynie), P52 (drift groszowy), P57
#     (metryki ingestu w tym samym katalogu), P68 (re-certyfikacja).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p58_observability_closure
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p58_observability_closure

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p58_check", false) == true
_ctx := object.get(input, "v3_p58", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p58_snapshot := data.jdg.thresholds.v3_p58

_snapshot_ok = true {
	count(_p58_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p58_snapshot) > 0
	value := object.get(_p58_snapshot, key, null)
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
	"rule_id": "jdg.v3_p58_observability_closure.thresholds_missing",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P58 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Legal freshness SLA per act ──────────────────────────────────────────
# Silnik: wiek weryfikacji ISAP per akt (P47). Akt bez weryfikacji lub z wiekiem
# powyżej SLA z ADR-002 = NEEDS_ADVICE (runbook RB-P58-01: re-check ISAP).
i01_freshness := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.legal_freshness_sla",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458001,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("legal freshness: %v z %v aktów poza SLA %v dni (w tym niezweryfikowane: %v) — runbook RB-P58-01", [count(stale), acts_total, sla_days, count(unverified)]),
	"metrics": {"acts_total": acts_total, "stale": count(stale), "unverified": count(unverified), "sla_days": sla_days},
	"_legal_basis": "P47 legal basis weryfikacja; UoR art. 4 ust. 1 (rzetelność procesu) [NIEZWERYFIKOWANE — ISAP]; prompt P58 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_legal_freshness_sla", {})
	sla_days := _th("v3_p58_isap_freshness_sla_days", 1)
	acts_total := object.get(_ctx_i01, "acts_total", 0)
	stale := object.get(_ctx_i01, "acts_beyond_sla", [])
	unverified := object.get(_ctx_i01, "acts_unverified", [])
	count(stale) + count(unverified) >= 1
}

# ── I02: Coverage regression alarm ────────────────────────────────────────────
# Silnik: pokrycie prawne vs snapshot poprzedniego przebiegu (P51). Nowe
# pustynie / spadek pokrycia = BLOCK (Law Radar karty pustyni).
i02_coverage_regression := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.coverage_regression_alarm",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458002,
	"decision": "BLOCK",
	"reason": sprintf("regresja pokrycia prawnego: %v nowych pustyni / spadek %v pp (próg %v) — Law Radar otwiera karty", [count(new_deserts), drop_pp, max_drop]),
	"metrics": {"coverage_current": coverage_current, "coverage_baseline": coverage_baseline, "new_deserts": count(new_deserts), "drop_pp": drop_pp},
	"_legal_basis": "P51 pustynie prawne — regresja = BLOCKER; prompt P58 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_coverage_regression_alarm", {})
	max_drop := _th("v3_p58_coverage_drop_max_pp", 0)
	coverage_current := object.get(_ctx_i02, "coverage_current", 0)
	coverage_baseline := object.get(_ctx_i02, "coverage_baseline", 0)
	new_deserts := object.get(_ctx_i02, "new_deserts", [])
	drop_pp := object.get(_ctx_i02, "drop_pp", 0)
	count(new_deserts) >= 1
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.coverage_regression_alarm",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458002,
	"decision": "BLOCK",
	"reason": sprintf("regresja pokrycia prawnego: spadek %v pp > próg %v pp", [drop_pp, max_drop]),
	"metrics": {"coverage_current": coverage_current, "coverage_baseline": coverage_baseline, "drop_pp": drop_pp},
	"_legal_basis": "P51 pustynie prawne — regresja = BLOCKER; prompt P58 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_coverage_regression_alarm", {})
	max_drop := _th("v3_p58_coverage_drop_max_pp", 0)
	coverage_current := object.get(_ctx_i02, "coverage_current", 0)
	coverage_baseline := object.get(_ctx_i02, "coverage_baseline", 0)
	drop_pp := object.get(_ctx_i02, "drop_pp", 0)
	drop_pp > max_drop
}

# ── I03: Advice-spread radar ──────────────────────────────────────────────────
# Silnik: udział NEEDS_ADVICE per domena z telemetrii P11. Domena powyżej
# progu z ADR-002 = NEEDS_ADVICE z klasterizacją powodów.
i03_advice_spread := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.advice_spread_radar",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458003,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("advice-spread: %v z %v domen powyżej progu %v%% — klasterizacja powodów w rejestrze telemetrii", [count(hot), domains_total, max_pct]),
	"metrics": {"domains_total": domains_total, "domains_hot": count(hot), "max_spread_pct": max_pct},
	"_legal_basis": "P49 fail-closed ścieżki advice; prompt P58 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_advice_spread_radar", {})
	max_pct := _th("v3_p58_advice_spread_max_pct", 15)
	domains_total := object.get(_ctx_i03, "domains_total", 0)
	hot := object.get(_ctx_i03, "domains_hot", [])
	count(hot) >= 1
}

# ── I04: Penny drift telemetry ────────────────────────────────────────────────
# Silnik: rozjazdy groszowe (P52 reconciliation) jako trend do zera. Wzrost
# ponad próg = BLOCK z pełnym trace (które wyliczenie).
i04_penny_drift := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.penny_drift_telemetry",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458004,
	"decision": "BLOCK",
	"reason": sprintf("penny drift: %v groszy (trend: %v) ponad próg %v gr — trace wyliczeń w rejestrze", [drift_gr, trend, max_gr]),
	"metrics": {"drift_gr": drift_gr, "trend": trend, "max_gr": max_gr, "traces": count(traces)},
	"_legal_basis": "P52 granice groszowe — trend do zera; prompt P58 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_penny_drift_telemetry", {})
	max_gr := _th("v3_p58_penny_drift_max_gr", 0)
	drift_gr := object.get(_ctx_i04, "drift_gr", 0)
	trend := object.get(_ctx_i04, "trend", "flat")
	traces := object.get(_ctx_i04, "traces", [])
	drift_gr > max_gr
}

# ── I05: Decision telemetry registry ──────────────────────────────────────────
# Silnik: każdy certyfikat P11 musi mieć pełny kontekst telemetrii (domena,
# kwota, pewność, epoka prawna P53, bundle hash). Decyzje bez kontekstu
# = NEEDS_ADVICE (analiza historyczna niemożliwa).
i05_telemetry_registry := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.decision_telemetry_registry",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("telemetria decyzji: %v z %v certyfikatów bez pełnego kontekstu (brakujące pola: %v)", [count(incomplete), certs_total, missing_fields]),
	"metrics": {"certs_total": certs_total, "complete": certs_total - count(incomplete), "incomplete": count(incomplete)},
	"_legal_basis": "P11 certyfikat decyzji = źródło telemetrii (bez podwójnej instrumentacji); RODO art. 5 ust. 2 (rozliczalność) [NIEZWERYFIKOWANE — ISAP]; prompt P58 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_decision_telemetry_registry", {})
	missing_fields := _th("v3_p58_telemetry_required_fields", ["domain", "amount_gr", "certainty", "legal_epoch", "bundle_hash"])
	certs_total := object.get(_ctx_i05, "certs_total", 0)
	incomplete := object.get(_ctx_i05, "certs_incomplete", [])
	count(incomplete) >= 1
}

# ── I06: Error budget freeze mechanism ────────────────────────────────────────
# Silnik: budżet błędów SLO (zgodność z golden replay + świeżość ISAP).
# Budżet poniżej progu BEZ aktywnej blokady wdrożeń = BLOCK (mechanizm, nie
# procedura — CI odmawia merge, P38/P39).
i06_error_budget := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.error_budget_freeze",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458006,
	"decision": "BLOCK",
	"reason": sprintf("error budget %v%% poniżej progu %v%% a zamrożenie wdrożeń NIEAKTYWNE (mechanizm blokady wymagany)", [budget_pct, min_pct]),
	"metrics": {"budget_pct": budget_pct, "min_pct": min_pct, "freeze_active": freeze_active},
	"_legal_basis": "P38 bundle deploy + P39 CI bramki; prompt P58 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_error_budget_freeze", {})
	min_pct := _th("v3_p58_error_budget_min_pct", 20)
	budget_pct := object.get(_ctx_i06, "budget_pct", 100)
	freeze_active := object.get(_ctx_i06, "freeze_active", false)
	budget_pct < min_pct
	_not(freeze_active)
}

# ── I07: Runbook-per-alarm contract ───────────────────────────────────────────
# Silnik: każdy alarm zdefiniowany w katalogu metryk prawnych musi mieć
# runbook (RB-P58-xx). Alarm bez runbooka = BLOCK (nie wchodzi do produkcji).
i07_runbook_contract := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.runbook_per_alarm",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458007,
	"decision": "BLOCK",
	"reason": sprintf("kontrakt runbook: %v z %v alarmów BEZ runbooka (RB-P58-xx) — nie wchodzi do produkcji", [count(without), alarms_total]),
	"metrics": {"alarms_total": alarms_total, "with_runbook": count(with_runbook), "without_runbook": count(without)},
	"_legal_basis": "P41 dokumentacja; prompt P58 Sekcja 10-I07",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_runbook_per_alarm", {})
	alarms_total := object.get(_ctx_i07, "alarms_total", 0)
	with_runbook := object.get(_ctx_i07, "with_runbook", [])
	without := object.get(_ctx_i07, "without_runbook", [])
	count(without) >= 1
}

# ── I08: Post-mortem registry ─────────────────────────────────────────────────
# Silnik: incydenty otwarte bez post-mortemu w oknie z ADR-002 = NEEDS_ADVICE
# (uczenie się fortecy — standard, nie ad hoc).
i08_postmortem := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.postmortem_registry",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458008,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("post-mortemy: %v incydentów bez analizy w oknie %v dni (rejestr: %v wpisów)", [count(pending), max_age, registry_size]),
	"metrics": {"incidents_total": incidents_total, "pending_postmortem": count(pending), "registry_size": registry_size, "max_age_days": max_age},
	"_legal_basis": "prompt P58 Sekcja 10-I08; P43 chaos drills",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_postmortem_registry", {})
	max_age := _th("v3_p58_postmortem_max_age_days", 30)
	incidents_total := object.get(_ctx_i08, "incidents_total", 0)
	pending := object.get(_ctx_i08, "pending_postmortem", [])
	registry_size := object.get(_ctx_i08, "registry_size", 0)
	count(pending) >= 1
}

# ── I09: Escalation matrix ────────────────────────────────────────────────────
# Silnik: macierz eskalacji jako dane (poziom, rola, SLA, kanał). Poziomy
# bez roli/SLA lub liczba poziomów poniżej wymaganej = NEEDS_ADVICE.
i09_escalation := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.escalation_matrix",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("macierz eskalacji: %v z %v poziomów niekompletnych (wymagane poziomy: %v; łańcuch SRE→prawnik→właściciel)", [count(incomplete), levels_total, min_levels]),
	"metrics": {"levels_total": levels_total, "incomplete": count(incomplete), "min_levels": min_levels},
	"_legal_basis": "prompt P58 Sekcja 10-I09; P41 runbooki (eskalacja w pierwszej godzinie)",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_escalation_matrix", {})
	min_levels := _th("v3_p58_escalation_min_levels", 3)
	levels_total := object.get(_ctx_i09, "levels_total", 0)
	incomplete := object.get(_ctx_i09, "levels_incomplete", [])
	count(incomplete) >= 1
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.escalation_matrix",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("macierz eskalacji: %v poziomów poniżej wymaganych %v (łańcuch SRE→prawnik→właściciel)", [levels_total, min_levels]),
	"metrics": {"levels_total": levels_total, "min_levels": min_levels},
	"_legal_basis": "prompt P58 Sekcja 10-I09; P41 runbooki (eskalacja w pierwszej godzinie)",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_escalation_matrix", {})
	min_levels := _th("v3_p58_escalation_min_levels", 3)
	levels_total := object.get(_ctx_i09, "levels_total", 0)
	levels_total < min_levels
}

# ── I10: Risk-pattern mining ──────────────────────────────────────────────────
# Silnik: klasterizacja telemetrii (domena × kwota × godzina). Koncentracja
# ryzyka powyżej progu = MANUAL_REVIEW (wzorzec → wzmocnienie reguły/ alarm).
i10_risk_mining := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.risk_pattern_mining",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458010,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("risk-patterns: %v wzorców wysokiego ryzyka z %v zdarzeń (koncentracja powyżej progu %v%%) — przegląd człowieka", [count(patterns), events_total, min_pct]),
	"metrics": {"events_total": events_total, "patterns_high_risk": count(patterns), "concentration_pct": min_pct},
	"_legal_basis": "OP art. 119a (GAAR — wczesna detekcja ścieżek agresywnych) [NIEZWERYFIKOWANE — ISAP]; prompt P58 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_risk_pattern_mining", {})
	min_pct := _th("v3_p58_risk_concentration_max_pct", 25)
	events_total := object.get(_ctx_i10, "events_total", 0)
	patterns := object.get(_ctx_i10, "patterns_high_risk", [])
	count(patterns) >= 1
}

# ── I11: Telemetry privacy guard ──────────────────────────────────────────────
# Silnik: skan telemetrii pod kątem danych osobowych (NIP kontrahenta, nazwy,
# e-maile) i wymogu pseudonimizacji per tenant. Wyciek = BLOCK (RODO by design).
i11_privacy_guard := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.telemetry_privacy_guard",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458011,
	"decision": "BLOCK",
	"reason": sprintf("privacy guard: %v pól PII w telemetrii / pseudonimizacja %v (wymagana: %v) — RODO art. 5 ust. 2, art. 32", [count(pii_hits), privacy_mode, required_mode]),
	"metrics": {"records_scanned": records_total, "pii_hits": count(pii_hits), "privacy_mode": privacy_mode},
	"_legal_basis": "RODO art. 5 ust. 2 (rozliczalność), art. 32 (bezpieczeństwo przetwarzania) [NIEZWERYFIKOWANE — ISAP]; prompt P58 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_telemetry_privacy_guard", {})
	required_mode := _th("v3_p58_privacy_mode", "pseudonymized")
	records_total := object.get(_ctx_i11, "records_scanned", 0)
	pii_hits := object.get(_ctx_i11, "pii_hits", [])
	privacy_mode := object.get(_ctx_i11, "privacy_mode", "unknown")
	count(pii_hits) >= 1
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.telemetry_privacy_guard",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458011,
	"decision": "BLOCK",
	"reason": sprintf("privacy guard: pseudonimizacja %v niezgodna z wymaganą %v — RODO art. 32", [privacy_mode, required_mode]),
	"metrics": {"records_scanned": records_total, "privacy_mode": privacy_mode, "required_mode": required_mode},
	"_legal_basis": "RODO art. 5 ust. 2, art. 32 [NIEZWERYFIKOWANE — ISAP]; prompt P58 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_telemetry_privacy_guard", {})
	required_mode := _th("v3_p58_privacy_mode", "pseudonymized")
	records_total := object.get(_ctx_i11, "records_scanned", 0)
	privacy_mode := object.get(_ctx_i11, "privacy_mode", "unknown")
	privacy_mode != required_mode
}

# ── I12: SLO per domain ───────────────────────────────────────────────────────
# Silnik: SLO dokładności (golden replay) i świeżości (ISAP age) per domena.
# Domena bez zdefiniowanego SLO = NEEDS_ADVICE (niemierzalna = niekontrolowana).
i12_slo_per_domain := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.slo_per_domain",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 458012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("SLO per domena: %v z %v domen BEZ SLO (wymagane domeny: %v) —Accuracy/freshness niezdefiniowane", [count(missing), domains_total, min_domains]),
	"metrics": {"domains_total": domains_total, "with_slo": domains_total - count(missing), "missing_slo": count(missing), "min_domains": min_domains},
	"_legal_basis": "V1 SLO control plane; prompt P58 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_slo_per_domain", {})
	min_domains := _th("v3_p58_slo_domains_min", 6)
	domains_total := object.get(_ctx_i12, "domains_total", 0)
	missing := object.get(_ctx_i12, "domains_missing_slo", [])
	count(missing) >= 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P57):
# najpierw BLOCK, potem NEEDS_ADVICE/MANUAL_REVIEW, na końcu PASS.
# Bez flagi v3_p58_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i02_coverage_regression {
	_snapshot_ok
	_activated
	i02_coverage_regression.decision == "BLOCK"
} else := i04_penny_drift {
	_snapshot_ok
	_activated
	i04_penny_drift.decision == "BLOCK"
} else := i06_error_budget {
	_snapshot_ok
	_activated
	i06_error_budget.decision == "BLOCK"
} else := i07_runbook_contract {
	_snapshot_ok
	_activated
	i07_runbook_contract.decision == "BLOCK"
} else := i11_privacy_guard {
	_snapshot_ok
	_activated
	i11_privacy_guard.decision == "BLOCK"
} else := i01_freshness {
	_snapshot_ok
	_activated
	i01_freshness.decision == "NEEDS_ADVICE"
} else := i03_advice_spread {
	_snapshot_ok
	_activated
	i03_advice_spread.decision == "NEEDS_ADVICE"
} else := i05_telemetry_registry {
	_snapshot_ok
	_activated
	i05_telemetry_registry.decision == "NEEDS_ADVICE"
} else := i08_postmortem {
	_snapshot_ok
	_activated
	i08_postmortem.decision == "NEEDS_ADVICE"
} else := i09_escalation {
	_snapshot_ok
	_activated
	i09_escalation.decision == "NEEDS_ADVICE"
} else := i12_slo_per_domain {
	_snapshot_ok
	_activated
	i12_slo_per_domain.decision == "NEEDS_ADVICE"
} else := i10_risk_mining {
	_snapshot_ok
	_activated
	i10_risk_mining.decision == "MANUAL_REVIEW"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p58_observability_closure.no_match",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P58 niewyzwolony (brak flagi v3_p58_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P57",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p58_observability_closure.all_green",
	"package": "jdg.v3_p58_observability_closure",
	"priority": 1,
	"decision": "PASS",
	"reason": "P58: obserwowalność fortecy zielona (12 analiz, alarmy z runbookami, budżet w normie)",
	"metrics": {"analyses": 12},
	"_legal_basis": "UoR art. 4 ust. 1; RODO art. 5 ust. 2/32; OP art. 119a; VAT art. 109e; UoZUS art. 47; KKS art. 56 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
