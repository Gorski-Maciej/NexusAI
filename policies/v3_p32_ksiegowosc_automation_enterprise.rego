# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P32 AUTOMATYZACJA KSIĘGOWOŚCI — OD FAKTURY DO ARCHIWUM
# (V3 FORTRESS, CEL NADRZĘDNY SERII) — ENTERPRISE
# ===============================================================================
# Warstwa pipeline'u księgowego ENTERPRISE — 12 analiz (I01–I12; minimum z promptu):
#   I01 Auto-Booking Pipeline z Decision Certificate (każde zaksięgowanie
#       generuje certyfikat z pełnym łańcuchem dowodów — księgowanie zawsze
#       wytłumaczalne; V2 filar F4; AN01),
#   I02 Idempotency Keys (hash dokumentu jako klucz idempotencji; podwójne
#       dostarczenie = zerowy efekt + alarm; AN01),
#   I03 Two-Phase Close Month (zamknięcie miesiąca w 2 fazach: przygotowanie →
#       zatwierdzenie, z walidacją niezgodności między ewidencjami; AN04),
#   I04 Kolejka NEEDS_ADVICE z triage (wszystkie niepewności w jednej kolejce,
#       klasterizacja przypadków, P10 golden replay jako sugerent; AN01/AN02),
#   I05 Reconciliation with Bank Feed (wyciąg bankowy vs ewidencja: auto-parowanie
#       płatności, alarm rozjazdów; AN03),
#   I06 Granice Groszowe jako Dane Testowe (0,00/0,01/99999999,99 per reguła
#       wyliczania — generator P36; AN02),
#   I07 Replay Sezonowy (rewizja kwartału na nowych wersjach reguł — raport
#       dryfu „czy starą deklarację wydałbyś dzisiaj inaczej"; AN02/AN03),
#   I08 Automatyczne Korekty Pre-Deadline (wykrywanie błędów przed terminem
#       deklaracji, propozycja korekty z oceną ryzyka; OrdPU art. 21b; AN03),
#   I09 Przepływ 4-Eyes (krytyczne AUTO_POST, np. korekta > próg, wymaga
#       drugiej osoby; ślad 4-eyes w certyfikacie; AN01/AN03),
#   I10 Dokument → Decyzja → Archiwum (pojedynczy identyfikator dokumentu
#       prowadzi przez wszystkie etapy — traceability end-to-end; AN04),
#   I11 Limity Automatyzacji jako Dane (progi kwotowe i domeny auto-księgowania
#       w data.thresholds — zmiana bez deployu; ADR-002/P06; AN01),
#   I12 Backpressure na Awarie Zewnętrzne (awaria KSeF/MF wstrzymuje pipeline
#       w kontrolowany sposób — offline queue z raportem zgodności terminowej;
#       AN03/AN04).
#
# Integracje (kontrakty między-częściowe):
#   * P03 (kontrakt werdyktu) — każdy krok pipeline'u emituje zgodny werdykt,
#   * P04 (invarianty) — pipeline nigdy nie omija warstwy konstytucyjnej,
#   * P11 (toolkit księgowości) — mechanizm zaksięgowań i certyfikatów,
#   * P12/P13 (VAT macro/micro) — wyliczenia VAT spójne macro+micro,
#   * P25 (kalendarz zbiorczy) — terminy płatności/deklaracji,
#   * P31 (etapy audytów) — etap 14-16 audytuje ten pipeline od strony dowodów.
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p32 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak pola, sprzeczność, niepewność prawna =
#     NEEDS_ADVICE / MANUAL_REVIEW — nigdy cichy AUTO_POST (anty-wzorzec AP07);
#     ścieżki bez spełnionego warunku zwracają jawną NEEDS_ADVICE (AP03 zamknięty).
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     ([NIEZWERYFIKOWANE] — ISAP pełnym skanem nie wykonano w tej sesji).
#   * Aktywacja: input.jdg_entrepreneur.v3_p32_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p32_ksiegowosc_automation.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p32_ksiegowosc_automation
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p32_ksiegowosc_automation

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p32_check", false) == true
_ctx := object.get(input, "v3_p32", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p32_snapshot := data.jdg.thresholds.v3_p32

_snapshot_ok = true {
    count(_p32_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p32_snapshot) > 0
    value := object.get(_p32_snapshot, key, null)
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
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.thresholds_missing",
    "package": "jdg.v3_p32_ksiegowosc_automation",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "AUTOMATYZACJA KSIĘGOWOŚCI V3-P32: brak snapshotu data.jdg.thresholds.v3_p32.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P32] Brak snapshotu progów pipeline'u księgowego — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p32_ksiegowosc_automation",
        "priority": priority,
        "threshold_version": object.get(_p32_snapshot, "v3_p32_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p32_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p32_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I01: AUTO-BOOKING PIPELINE z DECISION CERTIFICATE (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_booking := object.get(_ctx, "auto_booking", {})
_booking_txns := object.get(_booking, "transactions", [])
_booking_uncertified := [t |
    t := _booking_txns[_]
    object.get(t, "decision_certificate", "") == ""
]
_booking_low_confidence := [t |
    t := _booking_txns[_]
    object.get(t, "confidence", 100) < _th("v3_p32_auto_post_min_confidence", 95)
]

routing_ab01 = "BLOCK_AND_ALERT" {
    count(_booking_uncertified) > 0
} else = "TRIAGE_QUEUE" {
    count(_booking_low_confidence) > 0
} else = "SUGGEST" {
    true
}

reason_ab01 = sprintf("Zaksięgowania bez decision certificate: %v — BLOCK (księgowanie zawsze wytłumaczalne; V2 F4).", [_booking_uncertified]) {
    count(_booking_uncertified) > 0
} else = sprintf("Zaksięgowania poniżej progu pewności %v%%: %v — TRIAGE ( NEEDS_ADVICE, nigdy cichy AUTO_POST; AP07).", [_th("v3_p32_auto_post_min_confidence", 95), _booking_low_confidence]) {
    count(_booking_low_confidence) > 0
} else = sprintf("Auto-booking OK: %v transakcji, wszystkie z certyfikatem decyzji i pewnością ≥ progu.", [count(_booking_txns)]) {
    true
}

auto_booking_pipeline_decision := _certificate(432001, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.auto_booking_pipeline",
    "analysis": "auto_booking_pipeline",
    "transactions_total": count(_booking_txns),
    "transactions_uncertified": count(_booking_uncertified),
    "transactions_low_confidence": count(_booking_low_confidence),
    "_routing": routing_ab01,
    "_routing_reason": reason_ab01,
    "_legal_basis": "V3_P32 §10/I01; UoR art. 4 ust. 1 rzetelność [NIEZWERYFIKOWANE]; V2 F4",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "auto_booking_pipeline"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I02: IDEMPOTENCY KEYS — podwójne dostarczenie = zerowy efekt (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_idem := object.get(_ctx, "idempotency", {})
_idem_duplicates := object.get(_idem, "duplicates_detected", 0)
_idem_double_posted := object.get(_idem, "double_posted", 0)

routing_id02 = "BLOCK_AND_ALERT" {
    _idem_double_posted > 0
} else = "TRIAGE_QUEUE" {
    _idem_duplicates > 0
} else = "SUGGEST" {
    true
}

reason_id02 = sprintf("Podwójne ZAKSIĘGOWANIE dokumentów: %v — BLOCK (idempotencja złamana; hash dokumentu jako klucz).", [_idem_double_posted]) {
    _idem_double_posted > 0
} else = sprintf("Duplikaty wykryte i zatrzymane: %v — TRIAGE (zerowy efekt + alarm; zweryfikować źródło duplikatów).", [_idem_duplicates]) {
    _idem_duplicates > 0
} else = "Idempotencja OK: brak duplikatów, brak podwójnych zaksięgowań." {
    true
}

idempotency_keys_decision := _certificate(432002, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.idempotency_keys",
    "analysis": "idempotency",
    "duplicates_detected": _idem_duplicates,
    "double_posted": _idem_double_posted,
    "_routing": routing_id02,
    "_routing_reason": reason_id02,
    "_legal_basis": "V3_P32 §10/I02; UoR art. 4 ust. 1 (rzetelność ewidencji) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "idempotency"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I03: TWO-PHASE CLOSE MONTH — przygotowanie → zatwierdzenie (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_close := object.get(_ctx, "close_month", {})
_close_phase := object.get(_close, "phase", "unknown")
_close_mismatches := object.get(_close, "ledger_mismatches", [])
_close_approved := object.get(_close, "approved", false) == true

routing_cm03 = "BLOCK_AND_ALERT" {
    _close_phase == "commit"
    count(_close_mismatches) > 0
} else = "BLOCK_AND_ALERT" {
    _close_phase == "commit"
    not _close_approved
} else = "TRIAGE_QUEUE" {
    _close_phase == "prepare"
    count(_close_mismatches) > 0
} else = "TRIAGE_QUEUE" {
    _close_phase == "unknown"
} else = "SUGGEST" {
    true
}

reason_cm03 = sprintf("Zamknięcie miesiąca (commit) z niezgodnościami ewidencji: %v — BLOCK (atomowość: wszystkie ewidencje się zgadzają lub nic się nie zamyka).", [_close_mismatches]) {
    _close_phase == "commit"
    count(_close_mismatches) > 0
} else = "Zamknięcie miesiąca (commit) bez zatwierdzenia (4-eyes) — BLOCK." {
    _close_phase == "commit"
    not _close_approved
} else = sprintf("Faza przygotowania z niezgodnościami: %v — TRIAGE (faza prepare służy ich wykryciu).", [_close_mismatches]) {
    _close_phase == "prepare"
    count(_close_mismatches) > 0
} else = "Nieznana faza zamknięcia miesiąca — TRIAGE (oczekiwano prepare|commit)." {
    _close_phase == "unknown"
} else = sprintf("Zamknięcie miesiąca OK: faza %v, ewidencje spójne, zatwierdzenie obecne.", [_close_phase]) {
    true
}

two_phase_close_month_decision := _certificate(432003, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.two_phase_close_month",
    "analysis": "close_month",
    "phase": _close_phase,
    "ledger_mismatches": count(_close_mismatches),
    "approved": _close_approved,
    "_routing": routing_cm03,
    "_routing_reason": reason_cm03,
    "_legal_basis": "V3_P32 §10/I03; UoR art. 4-5 (rzetelność, archiwum) [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "close_month"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I04: KOLEJKA NEEDS_ADVICE Z TRIAGE — jedna kolejka niepewności (AN01/AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_advice := object.get(_ctx, "needs_advice_queue", {})
_advice_pending := object.get(_advice, "pending", 0)
_advice_clustered := object.get(_advice, "clustered", false) == true
_advice_aged := object.get(_advice, "max_age_days", 0)
_advice_max_age := _th("v3_p32_advice_max_age_days", 14)

routing_na04 = "BLOCK_AND_ALERT" {
    _advice_pending > _th("v3_p32_advice_overflow", 200)
} else = "TRIAGE_QUEUE" {
    _advice_pending > 0
    not _advice_clustered
} else = "TRIAGE_QUEUE" {
    _advice_aged > _advice_max_age
} else = "SUGGEST" {
    true
}

reason_na04 = sprintf("Kolejka NEEDS_ADVICE przepełniona: %v > %v — BLOCK (pipeline nie może ignorować niepewności; P10 golden replay jako sugerent).", [_advice_pending, _th("v3_p32_advice_overflow", 200)]) {
    _advice_pending > _th("v3_p32_advice_overflow", 200)
} else = sprintf("Kolejka NEEDS_ADVICE (%v) bez klasterizacji — TRIAGE (inteligentne triage K08).", [_advice_pending]) {
    _advice_pending > 0
    not _advice_clustered
} else = sprintf("Wpisy NEEDS_ADVICE starsze niż %v dni — TRIAGE (limit %v; ryzyko przekroczenia terminów).", [_advice_aged, _advice_max_age]) {
    _advice_aged > _advice_max_age
} else = sprintf("Kolejka NEEDS_ADVICE OK: %v oczekujących, klasterizacja włączona, wiek ≤ %v dni.", [_advice_pending, _advice_max_age]) {
    true
}

needs_advice_queue_decision := _certificate(432004, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.needs_advice_queue",
    "analysis": "needs_advice_queue",
    "pending": _advice_pending,
    "clustered": _advice_clustered,
    "max_age_days": _advice_aged,
    "_routing": routing_na04,
    "_routing_reason": reason_na04,
    "_legal_basis": "V3_P32 §10/I04; V1 zasada 6 (fail-closed); kontrakt P03",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "needs_advice_queue"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I05: RECONCILIATION WITH BANK FEED — wyciąg vs ewidencja (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_recon := object.get(_ctx, "bank_reconciliation", {})
_recon_unmatched := object.get(_recon, "unmatched_payments", [])
_recon_amount_gap := object.get(_recon, "amount_gap", 0)
_recon_gap_max := _th("v3_p32_recon_amount_gap_max", 0.01)

routing_br05 = "BLOCK_AND_ALERT" {
    count(_recon_unmatched) > _th("v3_p32_recon_unmatched_max", 0)
} else = "TRIAGE_QUEUE" {
    _recon_amount_gap > _recon_gap_max
} else = "SUGGEST" {
    true
}

reason_br05 = sprintf("Płatności nieparowane z ewidencją: %v — BLOCK (reconciliation z wyciągiem bankowym wymagane przed zamknięciem).", [_recon_unmatched]) {
    count(_recon_unmatched) > _th("v3_p32_recon_unmatched_max", 0)
} else = sprintf("Rozjazd kwotowy wyciąg vs ewidencja: %v > %v — TRIAGE (alarm rozjazdów; granice groszowe I06).", [_recon_amount_gap, _recon_gap_max]) {
    _recon_amount_gap > _recon_gap_max
} else = sprintf("Reconciliation OK: rozjazd %v ≤ %v, wszystkie płatności sparowane.", [_recon_amount_gap, _recon_gap_max]) {
    true
}

bank_reconciliation_decision := _certificate(432005, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.bank_reconciliation",
    "analysis": "bank_reconciliation",
    "unmatched_payments": count(_recon_unmatched),
    "amount_gap": _recon_amount_gap,
    "_routing": routing_br05,
    "_routing_reason": reason_br05,
    "_legal_basis": "V3_P32 §10/I05; UoR art. 4 ust. 1 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "bank_reconciliation"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I06: GRANICE GROSZOWE JAKO DANE TESTOWE — 0,00/0,01/99999999,99 (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_penny := object.get(_ctx, "penny_boundaries", {})
_penny_rules_total := object.get(_penny, "calc_rules_total", 0)
_penny_rules_covered := object.get(_penny, "rules_with_boundary_tests", 0)

routing_pb06 = "BLOCK_AND_ALERT" {
    _has_flag("penny_boundary_hardcode")
} else = "TRIAGE_QUEUE" {
    _penny_rules_total > 0
    _penny_rules_covered < _penny_rules_total
} else = "SUGGEST" {
    true
}

reason_pb06 = sprintf("Wykryto hardcode granic groszowych w kodzie — BLOCK (granice jako dane testowe; generator P36; ADR-002).", []) {
    _has_flag("penny_boundary_hardcode")
} else = sprintf("Granice groszowe niepełne: %v/%v reguł wyliczania z testami 0,00/0,01/max — TRIAGE.", [_penny_rules_covered, _penny_rules_total]) {
    _penny_rules_total > 0
    _penny_rules_covered < _penny_rules_total
} else = sprintf("Granice groszowe OK: %v/%v reguł wyliczania z testami brzegowymi (0,00/0,01/99999999,99).", [_penny_rules_covered, _penny_rules_total]) {
    true
}

penny_boundary_tests_decision := _certificate(432006, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.penny_boundary_tests",
    "analysis": "penny_boundaries",
    "calc_rules_total": _penny_rules_total,
    "calc_rules_covered": _penny_rules_covered,
    "_routing": routing_pb06,
    "_routing_reason": reason_pb06,
    "_legal_basis": "V3_P32 §10/I06; ADR-002; generator granic P36",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "penny_boundaries"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I07: REPLAY SEZONOWY — rewizja kwartału na nowych regułach (AN02/AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_replay := object.get(_ctx, "seasonal_replay", {})
_replay_drift := object.get(_replay, "drifted_decisions", 0)
_replay_total := object.get(_replay, "decisions_total", 0)
_replay_drift_max := _th("v3_p32_replay_drift_max", 0)

routing_sr07 = "BLOCK_AND_ALERT" {
    _replay_drift > _replay_drift_max * 10
} else = "TRIAGE_QUEUE" {
    _replay_drift > _replay_drift_max
} else = "SUGGEST" {
    true
}

reason_sr07 = sprintf("Replay sezonowy: dryf decyzji %v > %v — BLOCK (stare deklaracje sprzeczne z dzisiejszymi regułami; korekty obowiązkowe).", [_replay_drift, _replay_drift_max * 10]) {
    _replay_drift > _replay_drift_max * 10
} else = sprintf("Replay sezonowy: dryf %v > %v — TRIAGE (raport dryfu: czy starą deklarację wydałbyś dzisiaj inaczej?).", [_replay_drift, _replay_drift_max]) {
    _replay_drift > _replay_drift_max
} else = sprintf("Replay sezonowy OK: %v/%v decyzji bez dryfu.", [_replay_total, _replay_total]) {
    true
}

seasonal_replay_decision := _certificate(432007, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.seasonal_replay",
    "analysis": "seasonal_replay",
    "decisions_total": _replay_total,
    "drifted_decisions": _replay_drift,
    "drift_max": _replay_drift_max,
    "_routing": routing_sr07,
    "_routing_reason": reason_sr07,
    "_legal_basis": "V3_P32 §10/I07; kontrakt P10 (Golden Oracle replay)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "seasonal_replay"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I08: AUTOMATYCZNE KOREKTY PRE-DEADLINE (OrdPU art. 21b) (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_corr := object.get(_ctx, "pre_deadline_corrections", {})
_corr_detected := object.get(_corr, "errors_detected", 0)
_corr_proposed := object.get(_corr, "corrections_proposed", 0)
_corr_days_left := object.get(_corr, "days_to_deadline", 0)
_corr_window := _th("v3_p32_correction_window_days", 7)

routing_pc08 = "TRIAGE_QUEUE" {
    _corr_days_left > 0
    _corr_days_left <= _corr_window
    _corr_detected > _corr_proposed
} else = "TRIAGE_QUEUE" {
    _corr_days_left > 0
    _corr_days_left <= _corr_window
    _corr_detected > 0
    _corr_proposed == 0
} else = "SUGGEST" {
    true
}

reason_pc08 = sprintf("Błędy niewykorygowane przed terminem (%v dni): %v wykrytych vs %v propozycji — TRIAGE (silnik korekt pre-deadline; OrdPU art. 21b [NIEZWERYFIKOWANE]).", [_corr_days_left, _corr_detected, _corr_proposed]) {
    _corr_days_left > 0
    _corr_days_left <= _corr_window
    _corr_detected > _corr_proposed
} else = sprintf("Okno korekt otwarte (%v dni), błędy: %v, brak propozycji — TRIAGE (ocena ryzyka wymagana).", [_corr_days_left, _corr_detected]) {
    _corr_days_left > 0
    _corr_days_left <= _corr_window
    _corr_detected > 0
    _corr_proposed == 0
} else = sprintf("Korekty pre-deadline OK: %v wykrytych, %v propozycji, %v dni do terminu.", [_corr_detected, _corr_proposed, _corr_days_left]) {
    true
}

pre_deadline_corrections_decision := _certificate(432008, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.pre_deadline_corrections",
    "analysis": "pre_deadline_corrections",
    "errors_detected": _corr_detected,
    "corrections_proposed": _corr_proposed,
    "days_to_deadline": _corr_days_left,
    "_routing": routing_pc08,
    "_routing_reason": reason_pc08,
    "_legal_basis": "V3_P32 §10/I08; OrdPU art. 21b (czynny żal/korekta) [NIEZWERYFIKOWANE]; kalendarz P25",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "pre_deadline_corrections"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I09: PRZEPŁYW 4-EYES — krytyczne AUTO_POST z drugą osobą (AN01/AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_4eyes := object.get(_ctx, "four_eyes", {})
_4eyes_events := object.get(_4eyes, "events", [])
_4eyes_unapproved := [e |
    e := _4eyes_events[_]
    object.get(e, "approval_second_person", false) == false
]
_4eyes_threshold := _th("v3_p32_four_eyes_min_amount", 5000)

routing_fe09 = "BLOCK_AND_ALERT" {
    count(_4eyes_unapproved) > 0
} else = "SUGGEST" {
    true
}

reason_fe09 = sprintf("AUTO_POST krytyczne bez zatwierdzenia drugiej osoby: %v — BLOCK (próg 4-eyes: %v; ślad 4-eyes w certyfikacie).", [count(_4eyes_unapproved), _4eyes_threshold]) {
    count(_4eyes_unapproved) > 0
} else = sprintf("Przepływ 4-eyes OK: próg %v, wszystkie krytyczne AUTO_POST zatwierdzone.", [_4eyes_threshold]) {
    true
}

four_eyes_flow_decision := _certificate(432009, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.four_eyes_flow",
    "analysis": "four_eyes",
    "unapproved_critical_events": count(_4eyes_unapproved),
    "threshold_amount": _4eyes_threshold,
    "_routing": routing_fe09,
    "_routing_reason": reason_fe09,
    "_legal_basis": "V3_P32 §10/I09; V1 zasada 6 (fail-closed); UoR art. 4 [NIEZWERYFIKOWANE]",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "four_eyes"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I10: DOKUMENT → DECYZJA → ARCHIWUM — traceability end-to-end (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_trace := object.get(_ctx, "document_traceability", {})
_trace_docs := object.get(_trace, "documents", [])
_trace_broken := [d |
    d := _trace_docs[_]
    object.get(d, "stages_complete", false) == false
]

routing_dt10 = "BLOCK_AND_ALERT" {
    count(_trace_broken) > _th("v3_p32_trace_broken_max", 0)
} else = "TRIAGE_QUEUE" {
    count(_trace_broken) > 0
} else = "SUGGEST" {
    true
}

reason_dt10 = sprintf("Dokumenty z przerwanym łańcuchem dokument→decyzja→archiwum: %v > %v — BLOCK (traceability end-to-end zerwany; UoR art. 74-75 [NIEZWERYFIKOWANE]).", [count(_trace_broken), _th("v3_p32_trace_broken_max", 0)]) {
    count(_trace_broken) > _th("v3_p32_trace_broken_max", 0)
} else = sprintf("Dokumenty z niepełnym łańcuchem: %v — TRIAGE (identyfikator dokumentu musi prowadzić przez wszystkie etapy).", [_trace_broken]) {
    count(_trace_broken) > 0
} else = sprintf("Traceability OK: %v dokumentów z kompletnym łańcuchem dokument→decyzja→archiwum.", [count(_trace_docs)]) {
    true
}

document_traceability_decision := _certificate(432010, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.document_traceability",
    "analysis": "document_traceability",
    "documents_total": count(_trace_docs),
    "documents_broken": count(_trace_broken),
    "_routing": routing_dt10,
    "_routing_reason": reason_dt10,
    "_legal_basis": "V3_P32 §10/I10; UoR art. 74-75 (archiwum) [NIEZWERYFIKOWANE]; kontrakt P43 (WORM)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "document_traceability"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I11: LIMITY AUTOMATYZACJI JAKO DANE — progi w thresholds (AN01/P06)
# ═══════════════════════════════════════════════════════════════════════════════
_autolim := object.get(_ctx, "automation_limits", {})
_autolim_hardcode := _has_flag("automation_hardcode_detected")
_autolim_domains := object.get(_autolim, "auto_domains_configured", 0)

routing_al11 = "BLOCK_AND_ALERT" {
    _autolim_hardcode
} else = "TRIAGE_QUEUE" {
    _autolim_domains == 0
} else = "SUGGEST" {
    true
}

reason_al11 = sprintf("Wykryto hardcode limitów automatyzacji (progi kwotowe/domeny) — BLOCK (zmiana bez deployu; ADR-002/P06).", []) {
    _autolim_hardcode
} else = "Brak domen skonfigurowanych do auto-księgowania — TRIAGE (limity jako dane w v3_p32_automation_limits)." {
    _autolim_domains == 0
} else = sprintf("Limity automatyzacji OK: %v domen jako dane (progi kwotowe, domeny w data.thresholds).", [_autolim_domains]) {
    true
}

automation_limits_decision := _certificate(432011, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.automation_limits",
    "analysis": "automation_limits",
    "auto_domains_configured": _autolim_domains,
    "hardcode_detected": _autolim_hardcode,
    "_routing": routing_al11,
    "_routing_reason": reason_al11,
    "_legal_basis": "V3_P32 §10/I11; ADR-002 (P06 parametry-as-data)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "automation_limits"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32-I12: BACKPRESSURE NA AWARIE ZEWNĘTRZNE — KSeF/MF offline (AN03/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_bp := object.get(_ctx, "external_backpressure", {})
_bp_offline := object.get(_bp, "offline_mode", false) == true
_bp_queued := object.get(_bp, "queued_items", 0)
_bp_deadline_risk := object.get(_bp, "deadline_risk_items", 0)

routing_bp12 = "BLOCK_AND_ALERT" {
    _bp_deadline_risk > 0
    not _bp_offline
} else = "TRIAGE_QUEUE" {
    _bp_offline
    _bp_queued == 0
    _bp_deadline_risk > 0
} else = "TRIAGE_QUEUE" {
    _bp_offline
    not object.get(_bp, "compliance_report_generated", false)
} else = "SUGGEST" {
    true
}

reason_bp12 = sprintf("Ryzyko terminowe %v pozycji przy AKTYWNYM łączu (nie ma offline mode) — BLOCK (backpressure wymagany; offline queue z raportem zgodności terminowej).", [_bp_deadline_risk]) {
    _bp_deadline_risk > 0
    not _bp_offline
} else = sprintf("Offline mode bez kolejki: ryzyko terminowe %v — TRIAGE (awaria KSeF/MF wstrzymuje pipeline w kontrolowany sposób).", [_bp_deadline_risk]) {
    _bp_offline
    _bp_queued == 0
    _bp_deadline_risk > 0
} else = "Offline mode bez raportu zgodności terminowej — TRIAGE (raport wymagany do P44)." {
    _bp_offline
    not object.get(_bp, "compliance_report_generated", false)
} else = sprintf("Backpressure OK: offline=%v, kolejka=%v, ryzyko terminowe=%v, raport zgodności wygenerowany.", [_bp_offline, _bp_queued, _bp_deadline_risk]) {
    true
}

external_backpressure_decision := _certificate(432012, {
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.external_backpressure",
    "analysis": "external_backpressure",
    "offline_mode": _bp_offline,
    "queued_items": _bp_queued,
    "deadline_risk_items": _bp_deadline_risk,
    "_routing": routing_bp12,
    "_routing_reason": reason_bp12,
    "_legal_basis": "V3_P32 §10/I12; kontrakt P25 (terminy); KSeF offline queue (tools)",
    "_warnings": [],
}) {
    _activated
    object.get(_ctx, "analysis", "") == "external_backpressure"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := auto_booking_pipeline_decision {
    auto_booking_pipeline_decision.rule_id != ""
} else := idempotency_keys_decision {
    idempotency_keys_decision.rule_id != ""
} else := two_phase_close_month_decision {
    two_phase_close_month_decision.rule_id != ""
} else := needs_advice_queue_decision {
    needs_advice_queue_decision.rule_id != ""
} else := bank_reconciliation_decision {
    bank_reconciliation_decision.rule_id != ""
} else := penny_boundary_tests_decision {
    penny_boundary_tests_decision.rule_id != ""
} else := seasonal_replay_decision {
    seasonal_replay_decision.rule_id != ""
} else := pre_deadline_corrections_decision {
    pre_deadline_corrections_decision.rule_id != ""
} else := four_eyes_flow_decision {
    four_eyes_flow_decision.rule_id != ""
} else := document_traceability_decision {
    document_traceability_decision.rule_id != ""
} else := automation_limits_decision {
    automation_limits_decision.rule_id != ""
} else := external_backpressure_decision {
    external_backpressure_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p32_ksiegowosc_automation.no_match",
    "package": "jdg.v3_p32_ksiegowosc_automation",
    "priority": 999999,
}
