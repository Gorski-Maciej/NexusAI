# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P25 KALENDARZ ZBIORCZY TERMINÓW I OBOWIĄZKÓW — ENTERPRISE
# (V3 FORTRESS) — JEDNO ŹRÓDŁO PRAWDY TERMINÓW DLA WSZYSTKICH DOMEN
# ===============================================================================
# Warstwa kalendarza ENTERPRISE — 12 innowacji (I01–I12):
#   I01 Master Deadline Table (tabela MASTER terminów jako DANE — kontrakt
#       dla P12 VAT, P14 PIT, P16 KSeF/JPK, P19 PCC, P23 CEIDG, P26 ZUS),
#   I02 Weekend Rollover Verified (przeniesienia PER obowiązek — art. 12 § 4/§ 5
#       OrdPU; wyjątek: PCC 14 dni NIE przenosi — art. 4 ust. 3),
#   I03 Zero-Silence Constitution (termin minął + brak wykonania = BLOCK +
#       eskalacja 48h — konstytucja kalendarza, kontrakt V3_P04),
#   I04 Year Rollover Test Rig (wykrywanie brakujących wierszy / niespójności
#       rocznych na wejściu; pełny rig 365 dni w narzędziu v3_p25_year_rollover_rig),
#   I05 Deadline Schema v1 (schemat terminu: baza → przeniesienie → alerty →
#       checklista → akcja → podstawa prawna),
#   I06 Dedup Gate (spójność z kalendarzami domenowymi plan44/45/26 — konsolidacja
#       nie dublowanie; wykrycie sprzecznej daty = TRIAGE),
#   I07 Tenant Calendar Layer (multi-tenant: terminy per JDG per forma
#       opodatkowania; izolacja tenant_id — AP08/AP12),
#   I08 Workload Forecaster (obciążenia horyzontu 14 dni z alertem przeciążenia),
#   I09 Completion Checklists (komplet: deklaracja + zapłata + ewidencja —
#       zero częściowego wykonania),
#   I10 Close-the-Loop Links (kalendarz → wykonanie → potwierdzenie (UPO) →
#       status DONE; brak potwierdzenia po terminie = BLOCK),
#   I11 Compliance Score History (metryka % dotrzymanych terminów + trend),
#   I12 Calendar Golden Set (kluczowe granice: rollover per obowiązek, dzień 0,
#       eskalacja, zero ciszy).
#
# Zasady:
#   * WSZYSTKIE terminy/alerty/escalcje z data.jdg.thresholds.calendar
#     (sekcja v3_p25_* + v3_p25_master_deadline_table) — ADR-002 (P06);
#     okna temporalne (P05). Zero hardcode dat w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak danych / nieznany obowiązek / naruszenie
#     invariantu zero-ciszy (P04) = BLOCK_AND_ALERT lub NEEDS_ADVICE — nigdy
#     cichy AUTO_POST (anty-wzorzec AP07).
#   * Konsolidacja, NIE dublowanie (P00): plan44/plan45 calendar, plan26
#     deadlines i deadline_monitor zostają; ich daty są WERYFIKOWANE względem
#     tabeli MASTER (I06) — przyszła migracja hardcode → kalendarz (I06/P26).
#   * Aktywacja: input.jdg_entrepreneur.v3_p25_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p25_kalendarz_zbiorczy.<reguła>.
#   * _legal_basis: każde twierdzenie z aktem + status [NIEZWERYFIKOWANE]
#     (ISAP/RCL nie wykonano w tej sesji) — protokół prawny 04/07.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p25_kalendarz_zbiorczy
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p25_kalendarz_zbiorczy

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p25_check", false) == true
_ctx := object.get(input, "v3_p25", {})

_no_match_id := "jdg.v3_p25_kalendarz_zbiorczy.no_match"  # kanon P00: jeden literał rule_id na plik (default decide trzyma literał — wymóg OPA)

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.no_match",
    "package": "jdg.v3_p25_kalendarz_zbiorczy",
    "priority": 999999,
}

# ── Snapshot progów kalendarza (ADR-002) ───────────────────────────────────────
_cal_snapshot := data.jdg.thresholds.calendar
_snapshot_ok := count(_cal_snapshot) > 0
_master_table := object.get(_cal_snapshot, "v3_p25_master_deadline_table", [])

_th(key, fallback) = value {
    _snapshot_ok
    value := object.get(_cal_snapshot, key, null)
    value != null
} else = fallback

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.thresholds_missing",
    "package": "jdg.v3_p25_kalendarz_zbiorczy",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Kalendarz V3-P25: brak snapshotu data.jdg.thresholds.calendar.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P25] Brak snapshotu progów kalendarza — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p25_kalendarz_zbiorczy",
        "priority": priority,
        "threshold_version": object.get(_cal_snapshot, "v3_p25_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_cal_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_cal_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

_abs(value) = result {
    value >= 0
    result := value
} else = result {
    result := value * -1
}

# ── Indeks tabeli MASTER: obowiązek → wiersz (O(1) lookup) ────────────────────
_master_row(obligation) = row {
    some i
    row := _master_table[i]
    row.obligation == obligation
}

_master_row(obligation) = {} {
    not _row_exists(obligation)
}

_row_exists(obligation) = true {
    some i
    _master_table[i].obligation == obligation
} else = false {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I01: MASTER DEADLINE TABLE — jedno źródło prawdy terminów
# Odczyt wiersza terminu z tabeli MASTER jako danych; nieznany obowiązek =
# fail-closed BLOCK (pustynia kalendarza → rejestr luk P25-L).
# ═══════════════════════════════════════════════════════════════════════════════
_mdt_obligation := object.get(_ctx, "obligation", "")
_mdt_row := _master_row(_mdt_obligation)
_mdt_known := _row_exists(_mdt_obligation)
_mdt_table_ok := count(_master_table) > 0

routing_mdt1 = "BLOCK_AND_ALERT" {
    not _mdt_table_ok
} else = "BLOCK_AND_ALERT" {
    not _mdt_known
} else = "SUGGEST" {
    true
}

reason_mdt1 = "Tabela MASTER terminów pusta — fail-closed (BLOCK)." {
    not _mdt_table_ok
} else = sprintf("Obowiązek %s nieznany w tabeli MASTER — pustynia kalendarza (BLOCK; luka V3-P25-L).", [_mdt_obligation]) {
    true
} else = sprintf("Obowiązek %s znaleziony w tabeli MASTER (wiersz jako dane).", [_mdt_obligation]) {
    true
}

warnings_mdt1 = ["[V3-P25-I01] Tabela MASTER pusta — BLOCK (fail-closed)."] {
    not _mdt_table_ok
} else = ["[V3-P25-I01] Nieznany obowiązek — dodaj wiersz do v3_p25_master_deadline_table (ADR-002)."] {
    true
} else = []

_mdt_unknown_flag = true {
    not _mdt_known
} else = false {
    true
}

master_deadline_table_decision := _certificate(425101, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.master_deadline_table",
    "analysis": "master_deadline_table",
    "obligation": _mdt_obligation,
    "row": _mdt_row,
    "master_rows": count(_master_table),
    "known_obligation": _mdt_known,
    "fail_closed": _mdt_unknown_flag,
    "_routing": routing_mdt1,
    "_routing_reason": reason_mdt1,
    "_legal_basis": "V3_P25-I01; art. 99/103 VAT, art. 44/45 PIT, art. 47 SUS, art. 4 PCC, art. 6/12 UoPiOL [NIEZWERYFIKOWANE]",
    "_warnings": warnings_mdt1,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "master_deadline_table"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I02: WEEKEND ROLLOVER VERIFIED — przeniesienia PER obowiązek
# NEXT_BUSINESS_DAY (art. 12 § 4 OrdPU — VAT/PIT/PPK), PREV_BUSINESS_DAY
# (art. 47 ust. 3 SUS — ZUS), NONE (art. 4 ust. 3 PCC — termin od dnia
# zawarcia, brak przeniesienia). Sprzeczność przeniesienia z rejestrem =
# TRIAGE; niezgodność obliczonej daty z oczekiwaną = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_wr_obligation := object.get(_ctx, "obligation", "")
_wr_row := _master_row(_wr_obligation)
_wr_registered := object.get(_wr_row, "rollover", "UNKNOWN")
_wr_expected := object.get(_ctx, "expected_rollover", "")
_wr_shifted := object.get(_ctx, "weekend_shift_detected", false)
_wr_known := _row_exists(_wr_obligation)

_wr_rollover_mismatch = true {
    _wr_known
    _wr_expected != ""
    _wr_expected != _wr_registered
} else = false

_wr_unknown = true {
    not _wr_known
} else = false

routing_wr2 = "BLOCK_AND_ALERT" {
    _wr_unknown
} else = "BLOCK_AND_ALERT" {
    _wr_rollover_mismatch
} else = "TRIAGE_QUEUE" {
    _wr_shifted
} else = "SUGGEST" {
    true
}

reason_wr2 = sprintf("Obowiązek %s nieznany — brak wiersza przeniesienia (BLOCK).", [_wr_obligation]) {
    _wr_unknown
} else = sprintf("Obowiązek %s: oczekiwane przeniesienie %s ≠ zarejestrowane %s — sprzeczność daty (BLOCK).",
    [_wr_obligation, _wr_expected, _wr_registered]) {
    _wr_rollover_mismatch
} else = sprintf("Obowiązek %s: termin w weekend/święto → przeniesienie %s (art. 12 § 4 OrdPU; per obowiązek).",
    [_wr_obligation, _wr_registered]) {
    _wr_shifted
} else = sprintf("Obowiązek %s: termin bez przeniesienia (rollover=%s).", [_wr_obligation, _wr_registered]) {
    true
}

warnings_wr2 = ["[V3-P25-I02] Nieznany obowiązek — BLOCK (fail-closed)."] {
    _wr_unknown
} else = ["[V3-P25-I02] Sprzeczność przeniesienia z tabelą MASTER — BLOCK; zweryfikuj w ISAP."] {
    _wr_rollover_mismatch
} else = ["[V3-P25-I02] ZUS (art. 47 ust. 3): weekend/święto → OSTATNI dzień roboczy PRZED terminem."] {
    _wr_shifted
    _wr_registered == "PREV_BUSINESS_DAY"
} else = [] {
    true
}

weekend_rollover_decision := _certificate(425102, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.weekend_rollover",
    "analysis": "weekend_rollover",
    "obligation": _wr_obligation,
    "registered_rollover": _wr_registered,
    "expected_rollover": _wr_expected,
    "weekend_shift_detected": _wr_shifted,
    "rollover_mismatch": _wr_rollover_mismatch,
    "fail_closed": _wr_unknown,
    "_routing": routing_wr2,
    "_routing_reason": reason_wr2,
    "_legal_basis": "Art. 12 § 4 OrdPU; art. 47 ust. 3 SUS; art. 4 ust. 3 PCC (brak przeniesienia) [NIEZWERYFIKOWANE]; V3_P25-I02",
    "_warnings": warnings_wr2,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "weekend_rollover"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I03: ZERO-SILENCE CONSTITUTION — termin minął + brak wykonania = BLOCK
# Konstytucja kalendarza (kontrakt V3_P04): NIGDY cisza. Alerty 7/3/1 (per
# obowiązek override z tabeli MASTER), eskalacja 48h, ścieżki awaryjne
# (odsetki P17 / czynna korekta). Naruszenie (breach bez BLOCK) = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_zs_obligation := object.get(_ctx, "obligation", "")
_zs_days_left := object.get(_ctx, "days_left", 999)
_zs_completed := object.get(_ctx, "completed", false)
_zs_row := _master_row(_zs_obligation)
_zs_alerts := object.get(_zs_row, "alert_override", _th("v3_p25_alert_levels_days", [7, 3, 1]))
_zs_known := _row_exists(_zs_obligation)
_zs_escalation_hours := _th("v3_p25_escalation_hours", 48)

_zs_alert_7 = true {
    _zs_days_left <= _zs_alerts[0]
    _zs_days_left > 0
} else = false

_zs_alert_3 = true {
    _zs_days_left <= _zs_alerts[1]
    _zs_days_left > 0
} else = false

_zs_alert_1 = true {
    _zs_days_left <= _zs_alerts[2]
    _zs_days_left > 0
} else = false

_zs_breached = true {
    _zs_days_left <= 0
    not _zs_completed
} else = false

_zs_constitution_ok = true {
    _zs_breached
    object.get(_ctx, "block_emitted", true) == true
} else = true {
    not _zs_breached
} else = false {
    true
}

routing_zs3 = "BLOCK_AND_ALERT" {
    _zs_breached
} else = "BLOCK_AND_ALERT" {
    not _zs_constitution_ok
} else = "TRIAGE_QUEUE" {
    _zs_alert_1
} else = "TRIAGE_QUEUE" {
    _zs_alert_3
} else = "SUGGEST" {
    _zs_alert_7
} else = "SUGGEST" {
    true
}

reason_zs3 = sprintf("ZERO CISZY: termin %s minął %d dni temu bez wykonania — BLOCK + eskalacja %dh (P04).",
    [_zs_obligation, _abs(_zs_days_left), _zs_escalation_hours]) {
    _zs_breached
} else = "Naruszenie konstytucji zero-ciszy: breach bez ścieżki BLOCK — BLOCK (P04)." {
    not _zs_constitution_ok
} else = sprintf("Termin %s: ZOSTAŁ 1 dzień — eskalacja operacyjna (alerty 7/3/1).", [_zs_obligation]) {
    _zs_alert_1
} else = sprintf("Termin %s: zostały %d dni — alert 3-dniowy.", [_zs_obligation, _zs_days_left]) {
    _zs_alert_3
} else = sprintf("Termin %s: zostało %d dni — alert 7-dniowy (przygotuj pracę).", [_zs_obligation, _zs_days_left]) {
    _zs_alert_7
} else = sprintf("Termin %s: wykonany lub poza horyzontem alertów (%d dni).", [_zs_obligation, _zs_days_left]) {
    true
}

warnings_zs3 = ["[V3-P25-I03] ZERO CISZY: brak wykonania po terminie = BLOCK + eskalacja 48h (księgowa → manager)."] {
    _zs_breached
} else = ["[V3-P25-I03] Naruszenie konstytucji zero-ciszy — host MUSI emitować BLOCK przy breach (P04)."] {
    not _zs_constitution_ok
} else = [] {
    true
}

zero_silence_decision := _certificate(425103, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.zero_silence",
    "analysis": "zero_silence",
    "obligation": _zs_obligation,
    "days_left": _zs_days_left,
    "completed": _zs_completed,
    "alerts": _zs_alerts,
    "alert_7": _zs_alert_7,
    "alert_3": _zs_alert_3,
    "alert_1": _zs_alert_1,
    "breached": _zs_breached,
    "escalation_hours": _zs_escalation_hours,
    "fail_closed": _zs_breached,
    "_routing": routing_zs3,
    "_routing_reason": reason_zs3,
    "_legal_basis": "V3_P04 invarianty (zero-ciszy); art. 56 OrdPU (odsetki); art. 81 OP (korekta czynna) [NIEZWERYFIKOWANE]; V3_P25-I03",
    "_warnings": warnings_zs3,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "zero_silence"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I04: YEAR ROLLOVER TEST RIG — wykrywanie braków rocznych na wejściu
# Rego bramkuje spójność wejścia rig (pełny rok, przeniesienia obliczone,
# zero pominiętych); pełna pętla 365-dniowa w narzędziu
# tools/v3_p25_year_rollover_rig.py (chaos kalendarzowy).
# ═══════════════════════════════════════════════════════════════════════════════
_yr_days := object.get(_ctx, "rig_days_generated", 0)
_yr_missing := object.get(_ctx, "missing_deadlines", 1)
_yr_rollovers := object.get(_ctx, "rollover_count", 0)
_yr_expected_rollovers := object.get(_ctx, "expected_rollover_count", -1)
_yr_complete := object.get(_ctx, "rig_complete", false)

_yr_ok = true {
    _yr_days >= 365
    _yr_missing == 0
    _yr_complete
} else = false

_yr_rollover_mismatch = true {
    _yr_expected_rollovers >= 0
    _yr_rollovers != _yr_expected_rollovers
} else = false

routing_yr4 = "TRIAGE_QUEUE" {
    not _yr_complete
} else = "BLOCK_AND_ALERT" {
    _yr_missing > 0
} else = "BLOCK_AND_ALERT" {
    _yr_rollover_mismatch
} else = "SUGGEST" {
    true
}

reason_yr4 = sprintf("RIG niekompletny (%d dni, complete=%t) — dokończ generowanie roku (TRIAGE).",
    [_yr_days, _yr_complete]) {
    not _yr_complete
} else = sprintf("RIG: %d pominiętych terminów w roku — BLOCK (zero pominięć obowiązkowe).", [_yr_missing]) {
    _yr_missing > 0
} else = sprintf("RIG: niespójność przeniesień (%d obliczonych ≠ %d oczekiwanych) — BLOCK.",
    [_yr_rollovers, _yr_expected_rollovers]) {
    _yr_rollover_mismatch
} else = sprintf("RIG ZALICZONY: %d dni, 0 pominiętych terminów, %d przeniesień — rok kalendarzowy poprawny.",
    [_yr_days, _yr_rollovers]) {
    true
}

warnings_yr4 = ["[V3-P25-I04] Rok wygenerowany bez pominięć — chaos kalendarzowy opanowany."] {
    _yr_ok
} else = ["[V3-P25-I04] Pominięte terminy w roku = BLOCK; uruchom tools/v3_p25_year_rollover_rig.py."] {
    _yr_missing > 0
} else = ["[V3-P25-I04] Niespójność przeniesień — zweryfikuj rig względem tabeli MASTER."] {
    _yr_rollover_mismatch
} else = ["[V3-P25-I04] RIG niekompletny — dokończ generowanie 365 dni."] {
    true
}

year_rollover_rig_decision := _certificate(425104, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.year_rollover_rig",
    "analysis": "year_rollover_rig",
    "rig_days_generated": _yr_days,
    "missing_deadlines": _yr_missing,
    "rollover_count": _yr_rollovers,
    "expected_rollover_count": _yr_expected_rollovers,
    "rig_complete": _yr_complete,
    "fail_closed": _yr_missing > 0,
    "_routing": routing_yr4,
    "_routing_reason": reason_yr4,
    "_legal_basis": "V3_P25-I04; art. 12 § 4-5 OrdPU (przeniesienia) [NIEZWERYFIKOWANE]",
    "_warnings": warnings_yr4,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "year_rollover_rig"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I05: DEADLINE SCHEMA v1 — walidacja schematu terminu
# Pola wymagane: obligation, base (day/date/days/months), frequency, rollover,
# alert_override, checklist, action, legal_basis. Brak pola / nieznana
# częstotliwość / brak podstawy prawnej = BLOCK (fail-closed).
# ═══════════════════════════════════════════════════════════════════════════════
_sc_obligation := object.get(_ctx, "obligation", "")
_sc_row := _master_row(_sc_obligation)
_sc_known := _row_exists(_sc_obligation)
_sc_frequency := object.get(_sc_row, "frequency", "")
_sc_has_base = true {
    object.get(_sc_row, "base_day", 0) > 0
} else = true {
    object.get(_sc_row, "base_date", "") != ""
} else = true {
    object.get(_sc_row, "base_days", 0) > 0
} else = true {
    object.get(_sc_row, "base_months", 0) > 0
} else = false {
    true
}
_sc_has_rollover := object.get(_sc_row, "rollover", "") != ""
_sc_has_alerts := count(object.get(_sc_row, "alert_override", [])) > 0
_sc_has_checklist := count(object.get(_sc_row, "checklist", [])) > 0
_sc_has_action := object.get(_sc_row, "action", "") != ""
_sc_has_legal_basis := object.get(_sc_row, "legal_basis", "") != ""

_sc_freq_ok = true {
    _sc_frequency in {"MONTHLY", "QUARTERLY", "ANNUAL", "EVENT"}
} else = false {
    true
}

_sc_valid = true {
    _sc_known
    _sc_has_base
    _sc_has_rollover
    _sc_has_alerts
    _sc_has_checklist
    _sc_has_action
    _sc_has_legal_basis
    _sc_freq_ok
} else = false {
    true
}

routing_sc5 = "BLOCK_AND_ALERT" {
    not _sc_known
} else = "BLOCK_AND_ALERT" {
    not _sc_valid
} else = "SUGGEST" {
    true
}

reason_sc5 = sprintf("Schemat: obowiązek %s nieznany — BLOCK (dodaj wiersz do tabeli MASTER).", [_sc_obligation]) {
    not _sc_known
} else = sprintf("Schemat v1: obowiązek %s niekompletny (base=%t, rollover=%t, alerty=%t, checklista=%t, akcja=%t, podstawa=%t, freq=%s) — BLOCK.",
    [_sc_obligation, _sc_has_base, _sc_has_rollover, _sc_has_alerts, _sc_has_checklist, _sc_has_action, _sc_has_legal_basis, _sc_frequency]) {
    not _sc_valid
} else = sprintf("Schemat v1: obowiązek %s kompletny (Deadline Schema v1).", [_sc_obligation]) {
    true
}

warnings_sc5 = ["[V3-P25-I05] Nieznany obowiązek — BLOCK (fail-closed)."] {
    not _sc_known
} else = ["[V3-P25-I05] Wiersz schematu niekompletny — uzupełnij pola Deadline Schema v1."] {
    not _sc_valid
} else = []

_sc_unknown_flag = true {
    not _sc_known
} else = false {
    true
}

deadline_schema_decision := _certificate(425105, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.deadline_schema",
    "analysis": "deadline_schema",
    "obligation": _sc_obligation,
    "frequency": _sc_frequency,
    "schema_valid": _sc_valid,
    "fail_closed": _sc_unknown_flag,
    "_routing": routing_sc5,
    "_routing_reason": reason_sc5,
    "_legal_basis": "V3_P25-I05 (Deadline Schema v1); V3_P41 kontrakt UI; ADR-002",
    "_warnings": warnings_sc5,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "deadline_schema"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I06: DEDUP GATE — konsolidacja kalendarzów domenowych (nie dublowanie)
# Wejście: zgłoszona data z plan44/plan45/plan26/deadline_monitor lub domeny
# (P16/P19/P23). Zgłoszenie ≠ tabela MASTER = TRIAGE (kandydat do migracji);
# brak obowiązku w MASTER = BLOCK (pustynia → rejestr luk).
# ═══════════════════════════════════════════════════════════════════════════════
_dd_obligation := object.get(_ctx, "obligation", "")
_dd_source_date := object.get(_ctx, "source_base_day", 0)
_dd_source_date_str := object.get(_ctx, "source_base_date", "")
_dd_row := _master_row(_dd_obligation)
_dd_known := _row_exists(_dd_obligation)
_dd_master_day := object.get(_dd_row, "base_day", 0)
_dd_master_date := object.get(_dd_row, "base_date", "")

_dd_day_conflict = true {
    _dd_known
    _dd_source_date > 0
    _dd_master_day > 0
    _dd_source_date != _dd_master_day
} else = false

_dd_date_conflict = true {
    _dd_known
    _dd_source_date_str != ""
    _dd_master_date != ""
    _dd_source_date_str != _dd_master_date
} else = false

routing_dd6 = "BLOCK_AND_ALERT" {
    not _dd_known
} else = "TRIAGE_QUEUE" {
    _dd_day_conflict
} else = "TRIAGE_QUEUE" {
    _dd_date_conflict
} else = "SUGGEST" {
    true
}

reason_dd6 = sprintf("DEDUP: obowiązek %s nieobecny w tabeli MASTER — pustynia kalendarza (BLOCK; luka V3-P25-L).", [_dd_obligation]) {
    not _dd_known
} else = sprintf("DEDUP: konflikt dnia %s: źródło %d ≠ MASTER %d — konsolidacja wymagana (TRIAGE).",
    [_dd_obligation, _dd_source_date, _dd_master_day]) {
    _dd_day_conflict
} else = sprintf("DEDUP: konflikt daty %s: źródło %s ≠ MASTER %s — konsolidacja wymagana (TRIAGE).",
    [_dd_obligation, _dd_source_date_str, _dd_master_date]) {
    _dd_date_conflict
} else = sprintf("DEDUP: termin %s spójny z tabelą MASTER — jedno źródło prawdy utrzymane.", [_dd_obligation]) {
    true
}

warnings_dd6 = ["[V3-P25-I06] Pustynia kalendarza — zarejestruj obowiązek w tabeli MASTER (ADR-002)."] {
    not _dd_known
} else = ["[V3-P25-I06] Hardcode terminu w regule domenowej — zaplanuj migrację do kalendarza (I06)."] {
    _dd_day_conflict
} else = []

_dd_unknown_flag = true {
    not _dd_known
} else = false {
    true
}

dedup_gate_decision := _certificate(425106, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.dedup_gate",
    "analysis": "dedup_gate",
    "obligation": _dd_obligation,
    "source_base_day": _dd_source_date,
    "source_base_date": _dd_source_date_str,
    "day_conflict": _dd_day_conflict,
    "date_conflict": _dd_date_conflict,
    "fail_closed": _dd_unknown_flag,
    "_routing": routing_dd6,
    "_routing_reason": reason_dd6,
    "_legal_basis": "V3_P25-I06; V3_P00 (zakaz duplikacji); ADR-002",
    "_warnings": warnings_dd6,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "dedup_gate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I07: TENANT CALENDAR LAYER — multi-tenant per forma opodatkowania
# Izolacja tenant_id (AP08/AP12): brak tenant_id przy włączonym trybie
# multi-tenant = BLOCK; forma opodatkowania tenanta determinuje wiersze PIT/ZUS.
# ═══════════════════════════════════════════════════════════════════════════════
_tn_obligation := object.get(_ctx, "obligation", "")
_tn_tenant := object.get(_ctx, "tenant_id", "")
_tn_tenant_form := object.get(_ctx, "tenant_tax_form", "")
_tn_row := _master_row(_tn_obligation)
_tn_known := _row_exists(_tn_obligation)
_tn_tenant_ok := _tn_tenant != ""
_tn_form_ok = true {
    _tn_tenant_form in {"SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD"}
} else = false {
    true
}

routing_tn7 = "BLOCK_AND_ALERT" {
    not _tn_known
} else = "BLOCK_AND_ALERT" {
    not _tn_tenant_ok
} else = "BLOCK_AND_ALERT" {
    not _tn_form_ok
} else = "SUGGEST" {
    true
}

reason_tn7 = sprintf("Tenant: obowiązek %s nieznany — BLOCK.", [_tn_obligation]) {
    not _tn_known
} else = "Tenant: brak tenant_id przy warstwie multi-tenant — BLOCK (izolacja per JDG, AP12)." {
    not _tn_tenant_ok
} else = sprintf("Tenant: forma %s nieznana — BLOCK (SCALE/LINEAR/LUMP_SUM/TAX_CARD).", [_tn_tenant_form]) {
    not _tn_form_ok
} else = sprintf("Tenant %s (%s): termin %s wyznaczony per forma opodatkowania.",
    [_tn_tenant, _tn_tenant_form, _tn_obligation]) {
    true
}

warnings_tn7 = ["[V3-P25-I07] Brak tenant_id — BLOCK (multi-tenant wymaga izolacji kalendarza)."] {
    not _tn_tenant_ok
} else = []

_tn_unknown_flag = true {
    not _tn_known
} else = false {
    true
}

tenant_calendar_decision := _certificate(425107, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.tenant_calendar",
    "analysis": "tenant_calendar",
    "obligation": _tn_obligation,
    "tenant_id": _tn_tenant,
    "tenant_tax_form": _tn_tenant_form,
    "fail_closed": _tn_unknown_flag,
    "_routing": routing_tn7,
    "_routing_reason": reason_tn7,
    "_legal_basis": "V3_P25-I07; V3_P63 (multi-tenant); V3_P23 (formy — art. 9a PIT) [NIEZWERYFIKOWANE]",
    "_warnings": warnings_tn7,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "tenant_calendar"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I08: WORKLOAD FORECASTER — prognoza obciążeń księgowych
# Horyzont 14 dni; obciążenie = liczba terminów w horyzoncie; przekroczenie
# progu przeciążenia = TRIAGE (zaplanuj pracę / dodatkowe zasoby).
# ═══════════════════════════════════════════════════════════════════════════════
_wf_upcoming := object.get(_ctx, "upcoming_deadlines", 0)
_wf_horizon := object.get(_ctx, "horizon_days", _th("v3_p25_workload_forecast_horizon_days", 14))
_wf_overload_pct := object.get(_ctx, "overload_threshold_pct", 80)
_wf_capacity := object.get(_ctx, "capacity_deadlines_per_period", 10)

_wf_load_pct = 0 {
    _wf_capacity <= 0
} else = (_wf_upcoming * 100) / _wf_capacity {
    true
}

_wf_overload = true {
    _wf_load_pct > _wf_overload_pct
} else = false {
    true
}

routing_wf8 = "TRIAGE_QUEUE" {
    _wf_overload
} else = "SUGGEST" {
    true
}

reason_wf8 = sprintf("Obciążenie %d%%: %d terminów w horyzoncie %d dni przy pojemności %d — zaplanuj pracę (TRIAGE).",
    [_wf_load_pct, _wf_upcoming, _wf_horizon, _wf_capacity]) {
    _wf_overload
} else = sprintf("Obciążenie %d%%: %d terminów w horyzoncie %d dni — pojemność zachowana.",
    [_wf_load_pct, _wf_upcoming, _wf_horizon]) {
    true
}

warnings_wf8 = ["[V3-P25-I08] Przeciążenie horyzontu — koniec kwartału/miesiąca: rozłóż pracę księgową."] {
    _wf_overload
} else = []

workload_forecaster_decision := _certificate(425108, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.workload_forecaster",
    "analysis": "workload_forecaster",
    "upcoming_deadlines": _wf_upcoming,
    "horizon_days": _wf_horizon,
    "load_pct": _wf_load_pct,
    "capacity": _wf_capacity,
    "overload": _wf_overload,
    "_routing": routing_wf8,
    "_routing_reason": reason_wf8,
    "_legal_basis": "V3_P25-I08 (planowanie pracy); kalendarz MASTER",
    "_warnings": warnings_wf8,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "workload_forecaster"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I09: COMPLETION CHECKLISTS — zero częściowego wykonania
# Checklista z tabeli MASTER; brak pozycji = TRIAGE; niezgodność checklisty
# z wierszem = BLOCK; pusta checklista w MASTER = BLOCK (pustynia).
# ═══════════════════════════════════════════════════════════════════════════════
_ck_obligation := object.get(_ctx, "obligation", "")
_ck_row := _master_row(_ck_obligation)
_ck_known := _row_exists(_ck_obligation)
_ck_master := object.get(_ck_row, "checklist", [])
_ck_reported := object.get(_ctx, "checklist_items", [])
_ck_missing := [item |
    some item in _ck_master
    not item in _ck_reported
]

_ck_complete = true {
    _ck_known
    count(_ck_missing) == 0
} else = false {
    true
}

routing_ck9 = "BLOCK_AND_ALERT" {
    not _ck_known
} else = "BLOCK_AND_ALERT" {
    _ck_known
    count(_ck_master) == 0
} else = "TRIAGE_QUEUE" {
    not _ck_complete
} else = "SUGGEST" {
    true
}

reason_ck9 = sprintf("Checklista: obowiązek %s nieznany — BLOCK.", [_ck_obligation]) {
    not _ck_known
} else = sprintf("Checklista: obowiązek %s ma pustą checklistę w MASTER — pustynia (BLOCK).", [_ck_obligation]) {
    count(_ck_master) == 0
} else = sprintf("Checklista %s niekompletna: brak [%s] — zero częściowego wykonania (TRIAGE).",
    [_ck_obligation, concat(", ", _ck_missing)]) {
    not _ck_complete
} else = sprintf("Checklista %s kompletna: [%s] — obowiązek domknięty w całości.",
    [_ck_obligation, concat(", ", _ck_reported)]) {
    true
}

warnings_ck9 = ["[V3-P25-I09] Niekompletna checklista = częściowe wykonanie — domknij wszystkie pozycje."] {
    _ck_known
    not _ck_complete
    count(_ck_master) > 0
} else = []

_ck_unknown_flag = true {
    not _ck_known
} else = false {
    true
}

completion_checklist_decision := _certificate(425109, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.completion_checklist",
    "analysis": "completion_checklist",
    "obligation": _ck_obligation,
    "checklist_master": _ck_master,
    "checklist_reported": _ck_reported,
    "missing_items": _ck_missing,
    "complete": _ck_complete,
    "fail_closed": _ck_unknown_flag,
    "_routing": routing_ck9,
    "_routing_reason": reason_ck9,
    "_legal_basis": "V3_P25-I09; V3_P20-I12 (checklisty); tabela MASTER",
    "_warnings": warnings_ck9,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "completion_checklist"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I10: CLOSE-THE-LOOP LINKS — kalendarz → wykonanie → potwierdzenie → DONE
# Stan: PENDING → ACTION_SENT → CONFIRMED(DONE). Termin minął bez CONFIRMED =
# BLOCK (zero ciszy). Brak ścieżki wykonania (action) w MASTER = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_cl_obligation := object.get(_ctx, "obligation", "")
_cl_status := object.get(_ctx, "loop_status", "PENDING")
_cl_days_left := object.get(_ctx, "days_left", 0)
_cl_row := _master_row(_cl_obligation)
_cl_known := _row_exists(_cl_obligation)
_cl_has_action := object.get(_cl_row, "action", "") != ""
_cl_confirmed = true {
    _cl_status == "CONFIRMED"
} else = false {
    true
}

_cl_lapsed_unconfirmed = true {
    _cl_days_left <= 0
    not _cl_confirmed
} else = false {
    true
}

_cl_status_ok = true {
    _cl_status in {"PENDING", "ACTION_SENT", "CONFIRMED"}
} else = false {
    true
}

routing_cl10 = "BLOCK_AND_ALERT" {
    not _cl_known
} else = "BLOCK_AND_ALERT" {
    not _cl_status_ok
} else = "BLOCK_AND_ALERT" {
    not _cl_has_action
} else = "BLOCK_AND_ALERT" {
    _cl_lapsed_unconfirmed
} else = "TRIAGE_QUEUE" {
    _cl_status == "PENDING"
    _cl_days_left <= 3
} else = "SUGGEST" {
    true
}

reason_cl10 = sprintf("Loop: obowiązek %s nieznany — BLOCK.", [_cl_obligation]) {
    not _cl_known
} else = sprintf("Loop: status %s nieznany (PENDING/ACTION_SENT/CONFIRMED) — BLOCK.", [_cl_status]) {
    not _cl_status_ok
} else = sprintf("Loop: obowiązek %s bez ścieżki wykonania (action) w MASTER — BLOCK.", [_cl_obligation]) {
    not _cl_has_action
} else = sprintf("ZERO CISZY: termin %s minął bez potwierdzenia (UPO) — BLOCK + eskalacja.", [_cl_obligation]) {
    _cl_lapsed_unconfirmed
} else = sprintf("Loop: %s za 3 dni bez akcji — wygeneruj (%s).", [_cl_obligation, object.get(_cl_row, "action", "?")]) {
    true
} else = sprintf("Loop: status %s — pętla zamknięta poprawnie.", [_cl_status]) {
    true
}

warnings_cl10 = ["[V3-P25-I10] Brak potwierdzenia UPO po terminie — pętla niedomknięta (BLOCK)."] {
    _cl_lapsed_unconfirmed
} else = []

close_the_loop_decision := _certificate(425110, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.close_the_loop",
    "analysis": "close_the_loop",
    "obligation": _cl_obligation,
    "loop_status": _cl_status,
    "days_left": _cl_days_left,
    "action": object.get(_cl_row, "action", ""),
    "confirmed": _cl_confirmed,
    "lapsed_unconfirmed": _cl_lapsed_unconfirmed,
    "fail_closed": _cl_lapsed_unconfirmed,
    "_routing": routing_cl10,
    "_routing_reason": reason_cl10,
    "_legal_basis": "V3_P25-I10; art. 106na VAT (KSeF UPO) [NIEZWERYFIKOWANE]; tabela MASTER",
    "_warnings": warnings_cl10,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "close_the_loop"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I11: COMPLIANCE SCORE HISTORY — metryka wartości kalendarza
# % dotrzymanych terminów + trend 12M; spadek trendu = TRIAGE; brak danych
# historii = TRIAGE (nigdy cisza — raportuj stan).
# ═══════════════════════════════════════════════════════════════════════════════
_hs_on_time := object.get(_ctx, "deadlines_on_time", 0)
_hs_total := object.get(_ctx, "deadlines_total", 0)
_hs_trend := object.get(_ctx, "score_trend", "FLAT")
_hs_months := object.get(_ctx, "history_months", _th("v3_p25_compliance_score_history_months", 12))

_hs_score = 0 {
    _hs_total <= 0
} else = (_hs_on_time * 100) / _hs_total {
    true
}

_hs_declining = true {
    _hs_trend == "DECLINING"
} else = false {
    true
}

routing_hs11 = "TRIAGE_QUEUE" {
    _hs_total <= 0
} else = "TRIAGE_QUEUE" {
    _hs_declining
} else = "TRIAGE_QUEUE" {
    _hs_score < 90
    _hs_total > 0
} else = "SUGGEST" {
    true
}

reason_hs11 = sprintf("Historia: brak danych (%d/%d) — raportuj dotrzymanie terminów (nigdy cisza).",
    [_hs_on_time, _hs_total]) {
    _hs_total <= 0
} else = sprintf("Historia: trend spadkowy (%d%% dotrzymanych, okno %dM) — TRIAGE.", [_hs_score, _hs_months]) {
    _hs_declining
} else = sprintf("Historia: %d%% dotrzymanych (okno %dM, trend %s) — poniżej celu 90%% (TRIAGE).",
    [_hs_score, _hs_months, _hs_trend]) {
    _hs_score < 90
} else = sprintf("Historia: %d%% dotrzymanych (okno %dM, trend %s) — cel utrzymany.",
    [_hs_score, _hs_months, _hs_trend]) {
    true
}

warnings_hs11 = ["[V3-P25-I11] Spadająca skuteczność terminów — kary uniknione maleją; popraw proces."] {
    _hs_declining
} else = []

compliance_score_decision := _certificate(425111, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.compliance_score",
    "analysis": "compliance_score",
    "deadlines_on_time": _hs_on_time,
    "deadlines_total": _hs_total,
    "score_pct": _hs_score,
    "trend": _hs_trend,
    "history_months": _hs_months,
    "_routing": routing_hs11,
    "_routing_reason": reason_hs11,
    "_legal_basis": "V3_P25-I11 (metryki wartości); V3_P37 (obserwowalność)",
    "_warnings": warnings_hs11,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "compliance_score"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P25-I12: CALENDAR GOLDEN SET — oracle granic kalendarza
# Kluczowe granice: rollover per obowiązek (ZUS wstecz), dzień 0 (breach),
# eskalacja 48h, schema v1 kompletny, zero pominięć w rigu. Złe oczekiwane
# routingi = BLOCK (golden niezgodny); zgodność = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_gs_case := object.get(_ctx, "case_id", "")
_gs_in_set := object.get(_ctx, "in_golden_set", false)
_gs_expected := object.get(_ctx, "expected_routing", "")
_gs_actual := object.get(_ctx, "actual_routing", "")
_gs_golden_version := _th("v3_p25_golden_version", "kalendarz-golden-2026.09")

_gs_match = true {
    _gs_in_set
    _gs_expected != ""
    _gs_expected == _gs_actual
} else = false {
    true
}

_gs_mismatch = true {
    _gs_in_set
    not _gs_match
} else = false {
    true
}

routing_gs12 = "BLOCK_AND_ALERT" {
    _gs_mismatch
} else = "TRIAGE_QUEUE" {
    _gs_in_set
    _gs_expected == ""
} else = "SUGGEST" {
    true
}

reason_gs12 = sprintf("Golden %s: sprzeczność — oczekiwano %s, uzyskano %s (BLOCK).",
    [_gs_case, _gs_expected, _gs_actual]) {
    _gs_mismatch
} else = sprintf("Golden %s: brak oczekiwanego routingu — uzupełnij oczekiwanie (TRIAGE).", [_gs_case]) {
    _gs_in_set
    _gs_expected == ""
} else = sprintf("Golden %s: zgodność potwierdzona (%s, wersja %s).", [_gs_case, _gs_actual, _gs_golden_version]) {
    true
}

warnings_gs12 = ["[V3-P25-I12] Golden niezgodny — zmiana w kalendarzu może być regresją prawną."] {
    _gs_mismatch
} else = []

calendar_golden_set_decision := _certificate(425112, {
    "rule_id": "jdg.v3_p25_kalendarz_zbiorczy.calendar_golden_set",
    "analysis": "calendar_golden_set",
    "case_id": _gs_case,
    "golden_version": _gs_golden_version,
    "expected_routing": _gs_expected,
    "actual_routing": _gs_actual,
    "golden_match": _gs_match,
    "fail_closed": _gs_mismatch,
    "_routing": routing_gs12,
    "_routing_reason": reason_gs12,
    "_legal_basis": "V3_P25-I12; V3_P10 (Golden Oracle); tabela MASTER",
    "_warnings": warnings_gs12,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "calendar_golden_set"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := master_deadline_table_decision {
    master_deadline_table_decision.rule_id != ""
} else := weekend_rollover_decision {
    weekend_rollover_decision.rule_id != ""
} else := zero_silence_decision {
    zero_silence_decision.rule_id != ""
} else := year_rollover_rig_decision {
    year_rollover_rig_decision.rule_id != ""
} else := deadline_schema_decision {
    deadline_schema_decision.rule_id != ""
} else := dedup_gate_decision {
    dedup_gate_decision.rule_id != ""
} else := tenant_calendar_decision {
    tenant_calendar_decision.rule_id != ""
} else := workload_forecaster_decision {
    workload_forecaster_decision.rule_id != ""
} else := completion_checklist_decision {
    completion_checklist_decision.rule_id != ""
} else := close_the_loop_decision {
    close_the_loop_decision.rule_id != ""
} else := compliance_score_decision {
    compliance_score_decision.rule_id != ""
} else := calendar_golden_set_decision {
    calendar_golden_set_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": _no_match_id,
    "package": "jdg.v3_p25_kalendarz_zbiorczy",
    "priority": 999999,
    "_warnings": ["[V3-P25] Brak aktywnej analizy — brak decyzji."],
}
