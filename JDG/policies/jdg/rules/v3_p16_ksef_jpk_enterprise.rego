# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P16 KSeF / JPK / DEKLARACJE / E-DORĘCZENIA ENTERPRISE (V3 FORTRESS)
# ===============================================================================
# Warstwa KSeF/JPK ENTERPRISE: kompletny cykl raportowania fiskalnego —
#   I01 KSeF Session Orchestrator (art. 106ka-106m VAT; sesje online/batch/
#       offline, idempotencja, retry),
#   I02 Zero-Loss Offline Queue (RPO=0 — identyfikatory zdarzeń, WAL, okno
#       offline 168h, art. 106na VAT),
#   I03 UPO Sentinel (timeout 24h → alarm → retry → eskalacja 48h — zero ciszy),
#   I04 Pre-Send Firewall (walidacja XSD P_1..P_8 + semantyka GTU/MPP przed
#       wysyłką — zero śmieci do MF),
#   I05 Deadline Constitution (terminy VAT 25./JPK 25./PIT 30.04/ZUS 20. jako
#       konstytucja z invariantem: brak deklaracji = alarm; przeniesienia
#       weekendowe/świąteczne),
#   I06 JPK Field Contract (pola JPK_V7 jako kontrakt z P12/P13 — GTU z
#       gtu_dictionary, MPP spójny z progiem; walidacja krzyżowa przed generacją),
#   I07 Idempotent Corrections (korekty JPK idempotentne — identyfikatory
#       zdarzeń, retry-proof, art. 106j VAT),
#   I08 Sandbox CI Rig (cotygodniowy test na sandboxie MF z raportem i trendem),
#   I09 Chaos KSeF Drill (tabletop: KSeF down 72h → zero utraty, pomiar RPO/RTO),
#   I10 E-Delivery Chain (wysyłka → status → UPO → archiwum — zero ciszy,
#       e-Doręczenia od 2026-01-01),
#   I11 Penalty Exposure Monitor (narażenie na kary KSeF — progresywność
#       100%/70%/50% z progami sankcji jako symulacja),
#   I12 KSeF/JPK Golden Set (golden faktury/JPK z walidacją schematową — oracle).
#
# Zasady:
#   * WSZYSTKIE limity/stopy/progi z data.jdg.thresholds.ksef_jpk_edeklaracje
#     (ADR-002, P06 parametry-as-data); sekcja v3_p16_* w bloku thresholdów.
#   * Okna temporalne honorowane (P05); FAIL-CLOSED: brak danych / konflikt /
#     naruszenie invariantu (faktura ≠ wysłana bez UPO; JPK ≠ złożony bez
#     potwierdzenia) = NEEDS_ADVICE lub BLOCK_AND_ALERT — nigdy cichy AUTO_POST
#     (AP07; P16-AN11; kontrakt V3_P04).
#   * Aktywacja: input.jdg_entrepreneur.v3_p16_check == true (wzorzec
#     jdg.v3_p14_pit_reliefs); bez flagi → no_match.
#   * rule_id: jdg.v3_p16_ksef_jpk.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p16_ksef_jpk
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p16_ksef_jpk

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p16_check", false) == true
_ctx := object.get(input, "v3_p16", {})

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p16_ksef_jpk.no_match",
    "package": "jdg.v3_p16_ksef_jpk",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji → fail-closed sentinel ─────────────
_ksef_snapshot := data.jdg.thresholds.ksef_jpk_edeklaracje
_snapshot_ok := count(_ksef_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    value := object.get(_ksef_snapshot, key, null)
    value != null
} else = fallback

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p16_ksef_jpk.thresholds_missing",
    "package": "jdg.v3_p16_ksef_jpk",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KSeF/JPK V3-P16: brak snapshotu data.jdg.thresholds.ksef_jpk_edeklaracje.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P16] Brak snapshotu progów KSeF/JPK — decyzje fiskalne ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p16_ksef_jpk",
        "priority": priority,
        "threshold_version": object.get(_ksef_snapshot, "threshold_version", "MISSING"),
        "legal_basis_version": object.get(_ksef_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_ksef_snapshot, "ksef_mandatory_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

_round2(value) = result {
    scaled := value * 100
    result := floor(scaled + 0.5) / 100
}

_min(a, b) = a {
    a <= b
} else = b

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I01: KSeF SESSION ORCHESTRATOR (art. 106ka-106m VAT)
# Pełny orchestrator sesji KSeF: online/batch/offline z idempotencją i retry.
# Faktura wystawiona po ksef_mandatory_from musi mieć numer KSeF; sesja ONLINE
# przy niedostępnym KSeF → przełączenie na OFFLINE (okno 168h); przekroczenie
# max_retries → eskalacja (BLOCK_AND_ALERT), nigdy cicha utrata.
# ═══════════════════════════════════════════════════════════════════════════════
_so_retry_exhausted = true {
    object.get(_ctx, "retries_used", 0) >= _th("v3_p16_session_max_retries", 3)
    object.get(_ctx, "ksef_available", true) == false
} else = false

_so_switch_offline = true {
    object.get(_ctx, "ksef_available", true) == false
    object.get(_ctx, "session_mode", "ONLINE") == "ONLINE"
    object.get(_ctx, "pending_invoices", 0) > 0
} else = false

_so_session_ok = true {
    object.get(_ctx, "ksef_available", true) == true
} else = true {
    object.get(_ctx, "ksef_available", true) == false
    object.get(_ctx, "retries_used", 0) < _th("v3_p16_session_max_retries", 3)
} else = false

_so_missing_ksef_number = true {
    object.get(_ctx, "invoice_issued_after", "2026-01-01") >= _th("ksef_mandatory_from", "2026-02-01")
    object.get(_ctx, "ksef_number_present", true) == false
    object.get(_ctx, "pending_invoices", 0) > 0
} else = false

session_orchestrator_decision := _certificate(382101, {
    "rule_id": "jdg.v3_p16_ksef_jpk.ksef_session_orchestrator",
    "analysis": "session_orchestrator",
    "pending_invoices": object.get(_ctx, "pending_invoices", 0),
    "session_mode": object.get(_ctx, "session_mode", "ONLINE"),
    "ksef_available": object.get(_ctx, "ksef_available", true),
    "retries_used": object.get(_ctx, "retries_used", 0),
    "mandatory_from": _th("ksef_mandatory_from", "2026-02-01"),
    "offline_window_hours": _th("v3_p16_offline_window_hours", 168),
    "max_retries": _th("v3_p16_session_max_retries", 3),
    "retry_exhausted": _so_retry_exhausted,
    "should_switch_offline": _so_switch_offline,
    "session_ok": _so_session_ok,
    "fail_closed": _so_fail_closed,
    "_routing": routing_so,
    "_routing_reason": reason_so,
    "_legal_basis": "Art. 106ka-106m VAT (KSeF: obowiązek, sesje); art. 106na (offline 2026)",
    "_warnings": warnings_so,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "session_orchestrator"
}

_so_fail_closed = true {
    _so_retry_exhausted
} else = true {
    _so_missing_ksef_number
} else = false

routing_so = "BLOCK_AND_ALERT" {
    _so_fail_closed
} else = "TRIAGE_QUEUE" {
    _so_switch_offline
} else = "SUGGEST" {
    _so_session_ok
} else = ""

reason_so = sprintf("KSeF sesja %s: retry wyczerpane (%d/%d) — sesja NIEZAKOŃCZONA.",
    [object.get(_ctx, "session_mode", "ONLINE"), object.get(_ctx, "retries_used", 0),
     _th("v3_p16_session_max_retries", 3)]) {
    _so_retry_exhausted
} else = sprintf("Faktura po %s bez numeru KSeF — obowiązek KSeF 2.0.",
    [_th("ksef_mandatory_from", "2026-02-01")]) {
    _so_missing_ksef_number
} else = "KSeF niedostępny — przełącz na sesję OFFLINE (kolejka 168h, RPO=0)." {
    _so_switch_offline
} else = sprintf("KSeF sesja OK: %d faktur w kolejce.", [object.get(_ctx, "pending_invoices", 0)]) {
    _so_session_ok
} else = ""

warnings_so = ["[V3-P16-I01] Retry wyczerpane — sesja KSeF NIEZAKOŃCZONA. Eskalacja ręczna (zero ciszy)."] {
    _so_retry_exhausted
} else = ["[V3-P16-I01] Faktura po terminie obowiązku KSeF bez numeru KSeF — blokada wysyłki."] {
    _so_missing_ksef_number
} else = ["[V3-P16-I01] KSeF niedostępny — kolejka OFFLINE aktywna (okno 168h)."] {
    _so_switch_offline
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I02: ZERO-LOSS OFFLINE QUEUE (RPO=0 — identyfikatory, WAL)
# Kolejka offline z gwarancją braku utraty faktury: każda faktura wystawiona w
# oknie offline musi mieć wpis WAL (Write-Ahead Log) i identyfikator zdarzenia.
# Brak WAL / faktura poza kolejką = ryzyko utraty → BLOCK_AND_ALERT (RPO>0).
# ═══════════════════════════════════════════════════════════════════════════════
_zl_loss_risk = true {
    object.get(_ctx, "wal_enabled", true) == false
} else = true {
    object.get(_ctx, "offline_pending_invoices", 0) > 0
    object.get(_ctx, "invoice_in_queue", true) == false
} else = true {
    object.get(_ctx, "idempotency_keys_ok", true) == false
} else = false

zero_loss_queue_decision := _certificate(382102, {
    "rule_id": "jdg.v3_p16_ksef_jpk.zero_loss_offline_queue",
    "analysis": "zero_loss_queue",
    "offline_pending_invoices": object.get(_ctx, "offline_pending_invoices", 0),
    "wal_required": _th("v3_p16_wal_required", true),
    "wal_enabled": object.get(_ctx, "wal_enabled", true),
    "idempotency_keys_ok": object.get(_ctx, "idempotency_keys_ok", true),
    "invoice_in_queue": object.get(_ctx, "invoice_in_queue", true),
    "offline_window_hours": _th("v3_p16_offline_window_hours", 168),
    "rpo_hours": _th("v3_p16_offline_rpo_hours", 0),
    "rto_hours": _th("v3_p16_offline_rto_hours", 4),
    "fail_closed": _zl_loss_risk,
    "_routing": routing_zl,
    "_routing_reason": reason_zl,
    "_legal_basis": "Art. 106na VAT (KSeF offline 2026); RPO=0 zasada V1/V2 (zero utraty)",
    "_warnings": warnings_zl,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "zero_loss_queue"
}

routing_zl = "BLOCK_AND_ALERT" {
    _zl_loss_risk
} else = "SUGGEST" {
    not _zl_loss_risk
} else = ""

reason_zl = "Offline queue: brak WAL — RPO>0, ryzyko utraty faktury." {
    object.get(_ctx, "wal_enabled", true) == false
} else = "Offline queue: faktura poza kolejką przy RPO=0 — ryzyko utraty." {
    _zl_loss_risk
} else = sprintf("Offline queue OK: %d faktur w kolejce, WAL aktywny, RPO=0 h.",
    [object.get(_ctx, "offline_pending_invoices", 0)]) {
    not _zl_loss_risk
} else = ""

warnings_zl = ["[V3-P16-I02] WAL wyłączony — NIEBIEZPIECZEŃSTWO UTRATY FAKTUR (RPO>0). Włącz Write-Ahead Log."] {
    object.get(_ctx, "wal_enabled", true) == false
} else = ["[V3-P16-I02] Faktura offline poza kolejką / brak kluczy idempotencji — naruszenie RPO=0. Eskalacja."] {
    _zl_loss_risk
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I03: UPO SENTINEL (timeout → alarm → retry → eskalacja)
# Monitor potwierdzeń UPO: faktura wysłana bez UPO po upływie terminu
# (ksef_upo_deadline_days=1 / timeout 24h) = alarm; po eskalacji 48h =
# BLOCK_AND_ALERT. Zero ciszy (P16-AN03, P16-AN11).
# ═══════════════════════════════════════════════════════════════════════════════
_upo_missing = object.get(_ctx, "sent_invoices", 0) - object.get(_ctx, "upo_received", 0)

_upo_timeout = true {
    _upo_missing > 0
    object.get(_ctx, "oldest_waiting_hours", 0) >= _th("v3_p16_upo_timeout_hours", 24)
} else = false

_upo_escalation = true {
    _upo_missing > 0
    object.get(_ctx, "oldest_waiting_hours", 0) >= _th("v3_p16_upo_escalation_hours", 48)
} else = false

upo_sentinel_decision := _certificate(382103, {
    "rule_id": "jdg.v3_p16_ksef_jpk.upo_sentinel",
    "analysis": "upo_sentinel",
    "sent_invoices": object.get(_ctx, "sent_invoices", 0),
    "upo_received": object.get(_ctx, "upo_received", 0),
    "missing_upo": _upo_missing,
    "oldest_waiting_hours": object.get(_ctx, "oldest_waiting_hours", 0),
    "timeout_hours": _th("v3_p16_upo_timeout_hours", 24),
    "escalation_hours": _th("v3_p16_upo_escalation_hours", 48),
    "timeout_reached": _upo_timeout,
    "escalation_reached": _upo_escalation,
    "fail_closed": _upo_escalation,
    "_routing": routing_upo,
    "_routing_reason": reason_upo,
    "_legal_basis": "Art. 106na VAT (UPO); rozporządzenie MF ws. KSeF; V3_P04 invariant zero-ciszy",
    "_warnings": warnings_upo,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "upo_sentinel"
}

routing_upo = "BLOCK_AND_ALERT" {
    _upo_escalation
} else = "TRIAGE_QUEUE" {
    _upo_timeout
} else = "SUGGEST" {
    not _upo_timeout
} else = ""

reason_upo = sprintf("UPO eskalacja (%dh) — %d faktur bez potwierdzenia, najstarsza czeka %dh.",
    [_th("v3_p16_upo_escalation_hours", 48), _upo_missing, object.get(_ctx, "oldest_waiting_hours", 0)]) {
    _upo_escalation
} else = sprintf("UPO timeout (%dh) — %d faktur bez UPO. Retry + alarm.",
    [_th("v3_p16_upo_timeout_hours", 24), _upo_missing]) {
    _upo_timeout
} else = "UPO kompletne — zero ciszy." {
    not _upo_timeout
} else = ""

warnings_upo = ["[V3-P16-I03] ESKALACJA UPO — faktury wysłane bez potwierdzenia. Ryzyko sankcji KSeF."] {
    _upo_escalation
} else = ["[V3-P16-I03] Brak UPO po terminie — retry + alarm (zero ciszy)."] {
    _upo_timeout
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I04: PRE-SEND FIREWALL (walidacja XSD + semantyka — zero śmieci do MF)
# Walidacja przed wysyłką: wymagane pola XSD (P_1..P_8), GTU ze słownika 13
# kodów, MPP zgodny z progiem (kontrakt P12/P13). Błędna faktura NIGDY nie
# trafia do MF — BLOCK_AND_ALERT (P16-AN05).
# ═══════════════════════════════════════════════════════════════════════════════
_fw_required := object.get(object.get(_ksef_snapshot, "xsd_offline_ci", {}), "required_fields",
                           ["P_1", "P_2", "P_3", "P_4", "P_5", "P_6", "P_7", "P_8"])

_fw_missing = [f | f := _fw_required[_]; not f in object.get(_ctx, "fields_present", [])]

_fw_gtu_unknown = true {
    object.get(_ctx, "gtu_code", "") != ""
    not object.get(_ctx, "gtu_code", "") in [g | g := object.get(_ksef_snapshot, "gtu_codes", [])[_]]
} else = false

_fw_gtu_known = true {
    not _fw_gtu_unknown
} else = false

_fw_mpp_gap = true {
    object.get(_ctx, "mpp_required", false) == true
    object.get(_ctx, "mpp_marked", true) == false
} else = false

_fw_blocked = true {
    count(_fw_missing) > 0
} else = true {
    _fw_gtu_unknown
} else = true {
    _fw_mpp_gap
} else = false

pre_send_firewall_decision := _certificate(382104, {
    "rule_id": "jdg.v3_p16_ksef_jpk.pre_send_firewall",
    "analysis": "pre_send_firewall",
    "required_fields": _fw_required,
    "missing_fields": _fw_missing,
    "gtu_code": object.get(_ctx, "gtu_code", ""),
    "gtu_known": _fw_gtu_known,
    "mpp_required": object.get(_ctx, "mpp_required", false),
    "mpp_marked": object.get(_ctx, "mpp_marked", true),
    "net_positive": object.get(_ctx, "amount_net", 1) > 0,
    "fail_closed": _fw_blocked,
    "_routing": routing_fw,
    "_routing_reason": reason_fw,
    "_legal_basis": "Art. 106ka-106m VAT; rozporządzenie MF ws. struktury FA; GTU art. 99 ust. 2a VAT",
    "_warnings": warnings_fw,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "pre_send_firewall"
}

routing_fw = "BLOCK_AND_ALERT" {
    _fw_blocked
} else = "SUGGEST" {
    not _fw_blocked
} else = ""

reason_fw = sprintf("Firewall: brak pól XSD: %v.", [_fw_missing]) {
    count(_fw_missing) > 0
} else = "Firewall: GTU poza słownikiem 13 kodów — blokada wysyłki." {
    _fw_gtu_unknown
} else = "Firewall: MPP wymagany (próg przekroczony) a nieoznaczony — blokada." {
    _fw_mpp_gap
} else = "Firewall: faktura przechodzi walidację XSD + semantykę — można wysłać." {
    not _fw_blocked
} else = ""

warnings_fw = ["[V3-P16-I04] Pre-Send Firewall BLOKUJE fakturę — brak wymaganych pól XSD (zero śmieci do MF)."] {
    count(_fw_missing) > 0
} else = ["[V3-P16-I04] GTU nieznany — popraw kod przed wysyłką."] {
    _fw_gtu_unknown
} else = ["[V3-P16-I04] MPP wymagane — oznacz przed wysyłką (kontrakt P12/P13)."] {
    _fw_mpp_gap
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I05: DEADLINE CONSTITUTION (terminy jako konstytucja + invarianty)
# Kalendarz terminów fiskalnych jako DANE: VAT-7 25. dzień, JPK_V7 25. dzień,
# PIT-36 30.04, JPK_PKPIR 20. dzień, ZUS DRA 20. dzień. Invariant: termin
# minął i brak deklaracji = ALARM (nigdy cisza). Przeniesienia weekendowe/
# świąteczne honorowane przez pole shifted_to (P16-AN04, P16-AN07).
# ═══════════════════════════════════════════════════════════════════════════════
_dc_filing := object.get(_ctx, "filing", {})
_dc_shifted := object.get(_dc_filing, "shifted_to", object.get(_dc_filing, "due_date", ""))
_dc_overdue = true {
    object.get(_dc_filing, "today", "") != ""
    _dc_shifted != ""
    object.get(_dc_filing, "today", "") > _dc_shifted
    object.get(_dc_filing, "filed", false) == false
} else = false

_dc_due_soon = true {
    object.get(_dc_filing, "today", "") != ""
    _dc_shifted != ""
    object.get(_dc_filing, "filed", false) == false
    _days_until(object.get(_dc_filing, "today", ""), _dc_shifted) <= object.get(_dc_deadlines, "alert_days_before", 7)
} else = false

_dc_deadlines := _th("v3_p16_deadlines", {})

_days_until(today, target) = diff {
    today_parts := split(today, "-")
    target_parts := split(target, "-")
    t_y := to_number(today_parts[0])
    t_m := to_number(today_parts[1])
    t_d := to_number(today_parts[2])
    g_y := to_number(target_parts[0])
    g_m := to_number(target_parts[1])
    g_d := to_number(target_parts[2])
    diff := (g_y - t_y) * 365 + (g_m - t_m) * 30 + (g_d - t_d)
}

deadline_constitution_decision := _certificate(382105, {
    "rule_id": "jdg.v3_p16_ksef_jpk.deadline_constitution",
    "analysis": "deadline_constitution",
    "filing_type": object.get(_dc_filing, "type", ""),
    "due_date": object.get(_dc_filing, "due_date", ""),
    "shifted_to": _dc_shifted,
    "weekend_shift": object.get(_dc_filing, "weekend_shift", false),
    "filed": object.get(_dc_filing, "filed", false),
    "today": object.get(_dc_filing, "today", ""),
    "overdue": _dc_overdue,
    "due_soon": _dc_due_soon,
    "constitution": _dc_deadlines,
    "fail_closed": _dc_overdue,
    "_routing": routing_dc,
    "_routing_reason": reason_dc,
    "_legal_basis": "Art. 99 VAT (JPK 25.); art. 45 PIT (30.04); art. 109 VAT (ewidencja); e-Doręczenia 2026",
    "_warnings": warnings_dc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "deadline_constitution"
}

routing_dc = "BLOCK_AND_ALERT" {
    _dc_overdue
} else = "TRIAGE_QUEUE" {
    _dc_due_soon
} else = "SUGGEST" {
    object.get(_dc_filing, "filed", false) == true
} else = ""

reason_dc = sprintf("%s: termin %s minął (%s) — deklaracja NIEZŁOŻONA. ALARM.",
    [object.get(_dc_filing, "type", ""), _dc_shifted, object.get(_dc_filing, "today", "")]) {
    _dc_overdue
} else = sprintf("%s: termin %s zbliża się — przygotuj deklarację.",
    [object.get(_dc_filing, "type", ""), _dc_shifted]) {
    _dc_due_soon
} else = sprintf("%s: deklaracja złożona (termin %s).",
    [object.get(_dc_filing, "type", ""), _dc_shifted]) {
    object.get(_dc_filing, "filed", false) == true
} else = ""

warnings_dc = ["[V3-P16-I05] TERMIN MINĄŁ I BRAK DEKLARACJI — invariant naruszony (zero ciszy)."] {
    _dc_overdue
} else = ["[V3-P16-I05] Termin w oknie alertu — złóż deklarację przed terminem."] {
    _dc_due_soon
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I06: JPK FIELD CONTRACT (pola JPK_V7 jako kontrakt z P12/P13)
# Walidacja krzyżowa przed generacją JPK_V7: GTU ze słownika (13 kodów), MPP
# zgodny z progiem (kontrakt V3_P12/P13), WDT/WNT spójne z ewidencją.
# Niezgodność pola = blokada generacji (P16-AN06/AN05).
# ═══════════════════════════════════════════════════════════════════════════════
_known_gtu_list = [g | g := object.get(_ksef_snapshot, "gtu_codes", [])[_]]
_jfc_rows := object.get(_ctx, "rows", [])
_jfc_bad_gtu = [r | r := _jfc_rows[_]; not object.get(r, "gtu", "") in _known_gtu_list]
_jfc_mpp_rows = [r | r := _jfc_rows[_]; object.get(r, "mpp_required", false) == true]
_jfc_mpp_unmarked = [r | r := _jfc_mpp_rows[_]; object.get(r, "mpp_marked", true) == false]
_jfc_ok = true {
    count(_jfc_bad_gtu) == 0
    count(_jfc_mpp_unmarked) == 0
} else = false

_jfc_fail_closed = true {
    not _jfc_ok
} else = false

jpk_field_contract_decision := _certificate(382106, {
    "rule_id": "jdg.v3_p16_ksef_jpk.jpk_field_contract",
    "analysis": "jpk_field_contract",
    "row_count": count(_jfc_rows),
    "gtu_violations": _jfc_bad_gtu,
    "mpp_rows_count": count(_jfc_mpp_rows),
    "mpp_unmarked_rows": count(_jfc_mpp_unmarked),
    "mpp_threshold_pln": _th("mpp_mandatory_threshold", 15000),
    "contract_ok": _jfc_ok,
    "fail_closed": _jfc_fail_closed,
    "_routing": routing_jfc,
    "_routing_reason": reason_jfc,
    "_legal_basis": "Art. 99 ust. 2a VAT (GTU); art. 109 VAT (ewidencja); kontrakt V3_P12/P13 (MPP/GTU)",
    "_warnings": warnings_jfc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "jpk_field_contract"
}

routing_jfc = "BLOCK_AND_ALERT" {
    not _jfc_ok
} else = "SUGGEST" {
    _jfc_ok
} else = ""

reason_jfc = sprintf("JPK: %d wierszy z GTU poza słownikiem; %d wierszy MPP bez oznaczenia.",
    [count(_jfc_bad_gtu), count(_jfc_mpp_unmarked)]) {
    not _jfc_ok
} else = sprintf("JPK: kontrakt pól OK (%d wierszy).", [count(_jfc_rows)]) {
    _jfc_ok
} else = ""

warnings_jfc = ["[V3-P16-I06] Niezgodność kontraktu pól JPK (GTU/MPP) — popraw przed generacją JPK_V7."] {
    not _jfc_ok
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I07: IDEMPOTENT CORRECTIONS (korekty JPK idempotentne, retry-proof)
# Korekta JPK z identyfikatorem zdarzenia: ponowne wysłanie tej samej korekty
# (retry) NIE dubluje wpisu. Zdarzenie już zastosowane + retry = OK (brak
# duplikatu); nowe zdarzenie z tym samym ID co zastosowane = BLOCK (kolizja).
# (P16-AN06; art. 106j VAT; P06)
# ═══════════════════════════════════════════════════════════════════════════════
_ic_duplicate_risk = true {
    object.get(_ctx, "already_applied", false) == true
    object.get(_ctx, "is_retry", false) == false
} else = false

idempotent_corrections_decision := _certificate(382107, {
    "rule_id": "jdg.v3_p16_ksef_jpk.idempotent_corrections",
    "analysis": "idempotent_corrections",
    "correction_event_id": object.get(_ctx, "correction_event_id", ""),
    "already_applied": object.get(_ctx, "already_applied", false),
    "is_retry": object.get(_ctx, "is_retry", false),
    "duplicate_risk": _ic_duplicate_risk,
    "retry_safe": _ic_retry_safe,
    "correction_deadline_days": object.get(object.get(_ksef_snapshot, "ksef_corrections", {}), "correction_deadline_days", 30),
    "fail_closed": _ic_duplicate_risk,
    "_routing": routing_ic,
    "_routing_reason": reason_ic,
    "_legal_basis": "Art. 106j VAT (korekty); art. 81 OrdPU (korekta deklaracji)",
    "_warnings": warnings_ic,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "idempotent_corrections"
}

_ic_retry_safe = true {
    object.get(_ctx, "already_applied", false) == true
    object.get(_ctx, "is_retry", false) == true
} else = false

routing_ic = "BLOCK_AND_ALERT" {
    _ic_duplicate_risk
} else = "SUGGEST" {
    _ic_retry_safe
} else = "SUGGEST" {
    object.get(_ctx, "already_applied", false) == false
} else = ""

reason_ic = sprintf("Korekta %s JUŻ ZASTOSOWANA i nie jest retry — ryzyko duplikatu. Blokada.",
    [object.get(_ctx, "correction_event_id", "")]) {
    _ic_duplicate_risk
} else = sprintf("Korekta %s: retry idempotentne — brak duplikatu (event_id zgodny).",
    [object.get(_ctx, "correction_event_id", "")]) {
    _ic_retry_safe
} else = sprintf("Korekta %s: nowe zdarzenie — do zastosowania.",
    [object.get(_ctx, "correction_event_id", "")]) {
    object.get(_ctx, "already_applied", false) == false
} else = ""

warnings_ic = ["[V3-P16-I07] Korekta już zastosowana — potwierdź, czy to nie duplikat (retry-proof)."] {
    _ic_duplicate_risk
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I08: SANDBOX CI RIG (cotygodniowy test na sandboxie MF)
# Test na sandboxie KSeF MF w cyklu cotygodniowym (v3_p16_sandbox_cadence_days=7)
# z raportem i trendem awaryjności. Brak testu w cyklu = TRIAGE_QUEUE (P16-AN09).
# ═══════════════════════════════════════════════════════════════════════════════
_sc_overdue = true {
    object.get(_ctx, "days_since_last_test", 99) > _th("v3_p16_sandbox_cadence_days", 7)
} else = false

sandbox_ci_rig_decision := _certificate(382108, {
    "rule_id": "jdg.v3_p16_ksef_jpk.sandbox_ci_rig",
    "analysis": "sandbox_ci_rig",
    "cadence_days": _th("v3_p16_sandbox_cadence_days", 7),
    "days_since_last_test": object.get(_ctx, "days_since_last_test", 99),
    "failure_trend_pct": object.get(_ctx, "failure_trend_pct", 0.0),
    "last_result": object.get(_ctx, "last_result", "BRAK_RAPORTU"),
    "overdue": _sc_overdue,
    "fail_closed": _sc_overdue,
    "_routing": routing_sc,
    "_routing_reason": reason_sc,
    "_legal_basis": "P16-AN09 (sandbox pipeline CI); ksef_sandbox_harness (MF sandbox)",
    "_warnings": warnings_sc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "sandbox_ci_rig"
}

routing_sc = "TRIAGE_QUEUE" {
    _sc_overdue
} else = "SUGGEST" {
    not _sc_overdue
} else = ""

reason_sc = sprintf("Sandbox CI: ostatni test %d dni temu (> cykl %d dni). Uruchom test na sandboxie MF.",
    [object.get(_ctx, "days_since_last_test", 99), _th("v3_p16_sandbox_cadence_days", 7)]) {
    _sc_overdue
} else = sprintf("Sandbox CI: test w cyklu (%d dni), trend awaryjności %.1f%%.",
    [object.get(_ctx, "days_since_last_test", 99), object.get(_ctx, "failure_trend_pct", 0.0)]) {
    not _sc_overdue
} else = ""

warnings_sc = ["[V3-P16-I08] Test sandboxa MF poza cyklem — uruchom cotygodniowy sandbox CI rig."] {
    _sc_overdue
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I09: CHAOS KSeF DRILL (tabletop: KSeF down 72h → zero utraty)
# Test tabletop awarii KSeF na 72h: kolejka offline musi dać zero utraty,
# pomiar RPO/RTO. Awaria wystąpiła a drill nieprzeprowadzony = NEEDS_ADVICE;
# zmierzone RPO>0 / utrata faktur = BLOCK_AND_ALERT (P16-AN12).
# ═══════════════════════════════════════════════════════════════════════════════
_ch_loss = true {
    object.get(_ctx, "lost_invoices", 0) > 0
} else = false

_ch_rpo_violated = true {
    object.get(_ctx, "measured_rpo_hours", 0) > _th("v3_p16_offline_rpo_hours", 0)
} else = false

_ch_overdue = true {
    object.get(_ctx, "ksef_outage_hours", 0) >= _th("v3_p16_chaos_drill_hours", 72)
    object.get(_ctx, "drill_completed", false) == false
} else = false

chaos_ksef_drill_decision := _certificate(382109, {
    "rule_id": "jdg.v3_p16_ksef_jpk.chaos_ksef_drill",
    "analysis": "chaos_ksef_drill",
    "ksef_outage_hours": object.get(_ctx, "ksef_outage_hours", 0),
    "drill_required_hours": _th("v3_p16_chaos_drill_hours", 72),
    "drill_completed": object.get(_ctx, "drill_completed", false),
    "measured_rpo_hours": object.get(_ctx, "measured_rpo_hours", 0),
    "measured_rto_hours": object.get(_ctx, "measured_rto_hours", 0),
    "lost_invoices": object.get(_ctx, "lost_invoices", 0),
    "rpo_violated": _ch_rpo_violated,
    "loss_detected": _ch_loss,
    "drill_overdue": _ch_overdue,
    "fail_closed": _ch_fail_closed,
    "_routing": routing_ch,
    "_routing_reason": reason_ch,
    "_legal_basis": "P16-AN12 (chaos drill 72h); RPO/RTO (V1 resilience, P43 DR/BCP)",
    "_warnings": warnings_ch,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "chaos_ksef_drill"
}

_ch_fail_closed = true {
    _ch_loss
} else = true {
    _ch_rpo_violated
} else = false

routing_ch = "BLOCK_AND_ALERT" {
    _ch_loss
} else = "BLOCK_AND_ALERT" {
    _ch_rpo_violated
} else = "TRIAGE_QUEUE" {
    _ch_overdue
} else = "SUGGEST" {
    object.get(_ctx, "drill_completed", false) == true
} else = ""

reason_ch = sprintf("Chaos drill: UTRATA %d faktur podczas awarii KSeF %dh — RPO=0 naruszone!",
    [object.get(_ctx, "lost_invoices", 0), object.get(_ctx, "ksef_outage_hours", 0)]) {
    _ch_loss
} else = sprintf("Chaos drill: zmierzone RPO=%dh (>0) — naruszenie gwarancji zero utraty.",
    [object.get(_ctx, "measured_rpo_hours", 0)]) {
    _ch_rpo_violated
} else = sprintf("Chaos drill: awaria %dh, drill NIE przeprowadzony — wykonaj test tabletop.",
    [object.get(_ctx, "ksef_outage_hours", 0)]) {
    _ch_overdue
} else = sprintf("Chaos drill OK: %dh, RPO=%dh, RTO=%dh, utrata=0.",
    [object.get(_ctx, "ksef_outage_hours", 0), object.get(_ctx, "measured_rpo_hours", 0),
     object.get(_ctx, "measured_rto_hours", 0)]) {
    object.get(_ctx, "drill_completed", false) == true
} else = ""

warnings_ch = ["[V3-P16-I09] UTRATA FAKTUR podczas awarii KSeF — naruszenie RPO=0. Natychmiastowa eskalacja!"] {
    _ch_loss
} else = ["[V3-P16-I09] RPO>0 zmierzone — kolejka offline nie gwarantuje zero utraty."] {
    _ch_rpo_violated
} else = ["[V3-P16-I09] Awaria ≥72h bez drillu — przeprowadź chaos drill (tabletop)."] {
    _ch_overdue
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I10: E-DELIVERY CHAIN (wysyłka → status → UPO → archiwum — zero ciszy)
# Pełny łańcuch e-Doręczeń: wysyłka → status → UPO → archiwum. Każde ogniwo ma
# timeout; brak statusu/UPO po terminie = alarm (P16-AN03; kontrakt P11 UPO jako
# dowód archiwalny). e-Doręczenia obowiązkowe od edelivery_mandatory_from.
# ═══════════════════════════════════════════════════════════════════════════════
_ec_sent := object.get(_ctx, "sent_count", 0)
_ec_status := object.get(_ctx, "status_received", 0)
_ec_upo := object.get(_ctx, "upo_received", 0)
_ec_archived := object.get(_ctx, "archived", 0)
_ec_chain_broken = true {
    (_ec_status - _ec_upo) > 0
    object.get(_ctx, "oldest_waiting_hours", 0) >= _th("v3_p16_edelivery_status_timeout_hours", 24)
} else = false

_ec_chain_ok = true {
    _ec_sent > 0
    _ec_sent == _ec_archived
    _ec_upo == _ec_archived
} else = false

edelivery_chain_decision := _certificate(382110, {
    "rule_id": "jdg.v3_p16_ksef_jpk.edelivery_chain",
    "analysis": "edelivery_chain",
    "sent_count": _ec_sent,
    "status_received": _ec_status,
    "upo_received": _ec_upo,
    "archived": _ec_archived,
    "missing_status": _ec_sent - _ec_status,
    "missing_upo": _ec_status - _ec_upo,
    "missing_archive": _ec_upo - _ec_archived,
    "status_timeout_hours": _th("v3_p16_edelivery_status_timeout_hours", 24),
    "oldest_waiting_hours": object.get(_ctx, "oldest_waiting_hours", 0),
    "chain_broken": _ec_chain_broken,
    "chain_ok": _ec_chain_ok,
    "mandatory_from": _th("edelivery_mandatory_from", "2026-01-01"),
    "fail_closed": _ec_chain_broken,
    "_routing": routing_ec,
    "_routing_reason": reason_ec,
    "_legal_basis": "Ustawa o doręczeniach elektronicznych (2021, e-Doręczenia od 2026-01-01); P11 (UPO jako dowód)",
    "_warnings": warnings_ec,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "edelivery_chain"
}

routing_ec = "BLOCK_AND_ALERT" {
    _ec_chain_broken
} else = "SUGGEST" {
    _ec_chain_ok
} else = "TRIAGE_QUEUE" {
    _ec_sent > 0
} else = ""

reason_ec = sprintf("E-Doręczenia: %d przesyłek bez UPO po %dh — łańcuch PRZERWANY.",
    [_ec_status - _ec_upo, _th("v3_p16_edelivery_status_timeout_hours", 24)]) {
    _ec_chain_broken
} else = sprintf("E-Doręczenia: łańcuch kompletny (%d wysłano = %d zarchiwizowano).", [_ec_sent, _ec_archived]) {
    _ec_chain_ok
} else = sprintf("E-Doręczenia: %d wysłano, %d status, %d UPO, %d archiwum.",
    [_ec_sent, _ec_status, _ec_upo, _ec_archived]) {
    _ec_sent > 0
} else = ""

warnings_ec = ["[V3-P16-I10] Łańcuch e-Doręczeń PRZERWANY — przesyłki bez UPO/statusu (zero ciszy)."] {
    _ec_chain_broken
} else = ["[V3-P16-I10] Niekompletny łańcuch e-Doręczeń — dokończ status → UPO → archiwum."] {
    _ec_sent > 0
    not _ec_chain_ok
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I11: PENALTY EXPOSURE MONITOR (kary KSeF — progresywność, symulacja)
# Monitor narażenia na kary KSeF: symulacja sankcji wg reżimu (pełna 100% VAT /
# opóźnienie >24h 70% / czynny żal 50%) z progami z thresholdów
# (ksef_sanction_max_pln 500k, _70_cap 300k, _50_cap 250k). Wysoka ekspozycja =
# BLOCK_AND_ALERT (kontrakt P37 observability).
# ═══════════════════════════════════════════════════════════════════════════════
_pe_base = object.get(_ctx, "vat_amount_late_pln", 0.0) * _regime_pct(object.get(_ctx, "regime", "FULL"))
_pe_exposure = _min(_pe_base, _th("ksef_sanction_max_pln", 500000))
_pe_high = true {
    object.get(_ctx, "late_invoices", 0) > 0
    _pe_exposure > _th("ksef_sanction_70_cap_pln", 300000)
} else = false

_pe_medium = true {
    object.get(_ctx, "late_invoices", 0) > 0
    _pe_exposure <= _th("ksef_sanction_70_cap_pln", 300000)
    _pe_exposure > _th("ksef_sanction_50_cap_pln", 250000)
} else = false

_pe_low = true {
    object.get(_ctx, "late_invoices", 0) == 0
} else = true {
    _pe_exposure <= _th("ksef_sanction_50_cap_pln", 250000)
} else = false

_regime_pct(regime) = 1.0 {
    regime == "FULL"
} else = 0.7 {
    regime == "DELAY_OVER_24H"
} else = 0.5 {
    regime == "ACTIVE_REGRET"
} else = 0.0

penalty_exposure_decision := _certificate(382111, {
    "rule_id": "jdg.v3_p16_ksef_jpk.penalty_exposure_monitor",
    "analysis": "penalty_exposure",
    "late_invoices": object.get(_ctx, "late_invoices", 0),
    "vat_amount_late_pln": object.get(_ctx, "vat_amount_late_pln", 0.0),
    "regime": object.get(_ctx, "regime", "FULL"),
    "exposure_pln": _round2(_pe_exposure),
    "sanction_max_pln": _th("ksef_sanction_max_pln", 500000),
    "sanction_70_cap_pln": _th("ksef_sanction_70_cap_pln", 300000),
    "sanction_50_cap_pln": _th("ksef_sanction_50_cap_pln", 250000),
    "high_exposure": _pe_high,
    "medium_exposure": _pe_medium,
    "low_exposure": _pe_low,
    "fail_closed": _pe_high,
    "_routing": routing_pe,
    "_routing_reason": reason_pe,
    "_legal_basis": "Art. 106na-106nb VAT (kary KSeF 2026, progresja); KKS art. 54",
    "_warnings": warnings_pe,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "penalty_exposure"
}

routing_pe = "BLOCK_AND_ALERT" {
    _pe_high
} else = "TRIAGE_QUEUE" {
    _pe_medium
} else = "SUGGEST" {
    _pe_low
} else = ""

reason_pe = sprintf("Ekspozycja na kary KSeF: %d faktur, reżim %s, narażenie %.2f PLN (próg wysoki %d PLN).",
    [object.get(_ctx, "late_invoices", 0), object.get(_ctx, "regime", "FULL"), _pe_exposure,
     _th("ksef_sanction_70_cap_pln", 300000)]) {
    _pe_high
} else = sprintf("Ekspozycja na kary KSeF: %.2f PLN (reżim %s).", [_pe_exposure, object.get(_ctx, "regime", "FULL")]) {
    _pe_medium
} else = sprintf("Ekspozycja na kary KSeF: %.2f PLN (reżim %s).", [_pe_exposure, object.get(_ctx, "regime", "FULL")]) {
    _pe_low
} else = ""

warnings_pe = ["[V3-P16-I11] WYSOKA ekspozycja na kary KSeF — rozważ czynny żal (50%) przed kontrolą."] {
    _pe_high
} else = ["[V3-P16-I11] Średnia ekspozycja na kary KSeF — monitoruj i wyślij zaległe faktury."] {
    _pe_medium
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P16-I12: KSeF/JPK GOLDEN SET (golden faktury/JPK — oracle, walidacja XSD)
# Golden set faktur/JPK z walidacją schematową (oracle, Golden Oracle P10):
# porównanie wystawionej faktury z wzorcem golden (numer KSeF, pola XSD, GTU).
# Rozjazd z golden = BLOCK_AND_ALERT; zgodność = SUGGEST (P16-AN10, kontrakt P10).
# ═══════════════════════════════════════════════════════════════════════════════
_gs_violation = true {
    object.get(_ctx, "in_golden_set", false) == true
    object.get(_ctx, "schema_valid", true) == false
} else = true {
    object.get(_ctx, "in_golden_set", false) == true
    object.get(_ctx, "golden_fields_match", true) == false
} else = false

_gs_ok = true {
    object.get(_ctx, "in_golden_set", false) == true
    object.get(_ctx, "schema_valid", true) == true
    object.get(_ctx, "golden_fields_match", true) == true
} else = false

golden_set_decision := _certificate(382112, {
    "rule_id": "jdg.v3_p16_ksef_jpk.ksef_jpk_golden_set",
    "analysis": "golden_set",
    "invoice_number": object.get(_ctx, "invoice_number", ""),
    "in_golden_set": object.get(_ctx, "in_golden_set", false),
    "schema_valid": object.get(_ctx, "schema_valid", true),
    "golden_fields_match": object.get(_ctx, "golden_fields_match", true),
    "golden_version": _th("v3_p16_golden_set_version", "ksef-jpk-golden-2026.09"),
    "oracle_ok": _gs_ok,
    "oracle_violation": _gs_violation,
    "outside_golden": object.get(_ctx, "in_golden_set", false) == false,
    "fail_closed": _gs_violation,
    "_routing": routing_gs,
    "_routing_reason": reason_gs,
    "_legal_basis": "Golden Oracle (V2 F3, P10); walidacja XSD FA (rozporządzenie MF ws. KSeF)",
    "_warnings": warnings_gs,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_set"
}

routing_gs = "BLOCK_AND_ALERT" {
    _gs_violation
} else = "SUGGEST" {
    _gs_ok
} else = "TRIAGE_QUEUE" {
    object.get(_ctx, "in_golden_set", false) == false
} else = ""

reason_gs = sprintf("Golden set: faktura %s ROZJAZD z oracle (schema_valid=%t, fields_match=%t).",
    [object.get(_ctx, "invoice_number", ""), object.get(_ctx, "schema_valid", true),
     object.get(_ctx, "golden_fields_match", true)]) {
    _gs_violation
} else = sprintf("Golden set: faktura %s zgodna z oracle (wersja %s).",
    [object.get(_ctx, "invoice_number", ""), _th("v3_p16_golden_set_version", "ksef-jpk-golden-2026.09")]) {
    _gs_ok
} else = sprintf("Golden set: faktura %s poza zbiorem golden — walidacja standardowa.",
    [object.get(_ctx, "invoice_number", "")]) {
    object.get(_ctx, "in_golden_set", false) == false
} else = ""

warnings_gs = ["[V3-P16-I12] Faktura z golden set ROZJAZD z oracle — blokada (walidacja schematowa)."] {
    _gs_violation
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny, pierwszy match wygrywa)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := session_orchestrator_decision {
    session_orchestrator_decision.rule_id != ""
} else := zero_loss_queue_decision {
    zero_loss_queue_decision.rule_id != ""
} else := upo_sentinel_decision {
    upo_sentinel_decision.rule_id != ""
} else := pre_send_firewall_decision {
    pre_send_firewall_decision.rule_id != ""
} else := deadline_constitution_decision {
    deadline_constitution_decision.rule_id != ""
} else := jpk_field_contract_decision {
    jpk_field_contract_decision.rule_id != ""
} else := idempotent_corrections_decision {
    idempotent_corrections_decision.rule_id != ""
} else := sandbox_ci_rig_decision {
    sandbox_ci_rig_decision.rule_id != ""
} else := chaos_ksef_drill_decision {
    chaos_ksef_drill_decision.rule_id != ""
} else := edelivery_chain_decision {
    edelivery_chain_decision.rule_id != ""
} else := penalty_exposure_decision {
    penalty_exposure_decision.rule_id != ""
} else := golden_set_decision {
    golden_set_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p16_ksef_jpk.no_match",
    "package": "jdg.v3_p16_ksef_jpk",
    "priority": 999999,
}
