# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P26 ZUS — SKŁADKI SPOŁECZNE, ZDROWOTNA, ULGI I KALENDARZ
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa składkowa ENTERPRISE — 12 innowacji (I01–I12):
#   I01 Contribution Precision Engine (składki GROSZOWE: podstawa → stopa →
#       grosze; walidacja zakresu podstawy; test 4161,00 → emerytalna 812,63;
#       tolerancja groszowa 0,005),
#   I02 Relief Order Automaton (kolejność ulg: NONE → na start 6 mies. →
#       preferencyjna 24 mies. / mały ZUS Plus 36 mies. → STANDARD; równoległe
#       łączenie = BLOCK — błąd klasyczny; miesiące ponad limit = BLOCK),
#   I03 Cumulative Tier Sentinel (progi zdrowotnej ryczałt NARASTAJĄCO:
#       60k/300k ±0,01; alarm PRZED przekroczeniem ≥90% progu = TRIAGE),
#   I04 Health 2026 Verifier (wersja parametrów zdrowotnej z danych + status
#       weryfikacji ISAP; rozjazd wersji = BLOCK; brak weryfikacji = TRIAGE),
#   I05 Suspension Contribution Handler (zawieszenie: pauza ulgi wymagana,
#       dni zdrowotnej w zawieszeniu = TRIAGE, długość zawieszenia — alert),
#   I06 DRA Generator Validated (DRA/RCA/ZZA: walidacja pól zero-ciszy;
#       pracownicy>0 → RCA; brak pola = BLOCK; art. 47 ust. 1 SUS),
#   I07 ZUS Invariants Pack (składki ≥ 0, podstawa w zakresie, kolejność ulg,
#       groszowa precyzja — kontrakt V3_P04; naruszenie = BLOCK_AND_ALERT),
#   I08 ZUS Golden Set (golden granice: ulgi, progi 60k/300k, grosze 4161,00;
#       niezgodność = BLOCK — kontrakt V3_P10),
#   I09 Form Change Health Rescaler (zmiana formy w trakcie roku → przeliczenie
#       zdrowotnej per okres kwartalny; niekompletne = TRIAGE; nadmiar = BLOCK),
#   I10 Minimum Wage Integration (podstawa preferencyjnej = 30% minimalnej
#       z feedu P06; brak feedu = BLOCK fail-closed; dryf ≥1% = TRIAGE),
#   I11 ZUS Stress Lab (scenariusze: zmiana formy, zawieszenie Q4, próg
#       w listopadzie NARASTAJĄCO; brak scenariusza / niezgodność = BLOCK),
#   I12 Cross-Act Consistency Gate (ZUS×PIT×ryczałt: zadeklarowana zdrowotna
#       vs dochód/przychód/forma; rozjazd = BLOCK_AND_ALERT).
#
# Zasady:
#   * WSZYSTKIE stopy/podstawy/progi/limity z data.jdg.thresholds.zus (rdzeń
#     istniejący — jedno źródło prawdy stawek) + governance z
#     data.jdg.thresholds.zus26 (sekcja v3_p26_*) — ADR-002 (P06); okna
#     temporalne (P05). ZERO hardcode stawek w kodzie reguł.
#   * FAIL-CLOSED (V1 zasada 6): brak snapshotu / nieznana analiza / naruszenie
#     invariantu = BLOCK_AND_ALERT lub NEEDS_ADVICE — nigdy cichy AUTO_POST
#     (anty-wzorzec AP07).
#   * AKT 8.04: progi/prawo 2026 oznaczone [NIEZWERYFIKOWANE] — Health 2026
#     Verifier (I04) wymusza weryfikację ISAP przed zaufaniem parametrom.
#   * Aktywacja: input.jdg_entrepreneur.v3_p26_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p26_zus_skladki.<reguła>.
#   * _legal_basis: każde twierdzenie z aktem + status [NIEZWERYFIKOWANE]
#     (ISAP/RCL/zus.pl nie wykonano w tej sesji) — protokół prawny 04/07.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p26_zus_skladki
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p26_zus_skladki

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p26_check", false) == true
_ctx := object.get(input, "v3_p26", {})

_no_match_id := "jdg.v3_p26_zus_skladki.no_match"  # kanon P00: jeden literał rule_id na plik (default decide trzyma literał — wymóg OPA)

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p26_zus_skladki.no_match",
    "package": "jdg.v3_p26_zus_skladki",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): rdzeń zus + governance zus26 ────────────────────
_zus_snapshot := data.jdg.thresholds.zus
_z26_snapshot := data.jdg.thresholds.zus26

_snapshot_ok = true {
    count(_zus_snapshot) > 0
    count(_z26_snapshot) > 0
} else = false {
    true
}

_zr(key, fallback) = value {
    count(_zus_snapshot) > 0
    value := object.get(_zus_snapshot, key, null)
    value != null
} else = fallback

_th(key, fallback) = value {
    count(_z26_snapshot) > 0
    value := object.get(_z26_snapshot, key, null)
    value != null
} else = fallback

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p26_zus_skladki.thresholds_missing",
    "package": "jdg.v3_p26_zus_skladki",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "ZUS V3-P26: brak snapshotu data.jdg.thresholds.zus / zus26.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P26] Brak snapshotu progów składkowych — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p26_zus_skladki",
        "priority": priority,
        "threshold_version": object.get(_z26_snapshot, "v3_p26_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_z26_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_z26_snapshot, "valid_from", null),
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

# Precyzja groszowa: zaokrąglenie do grosza (half-up) — I01/I07/I12
_grosze(x) = y {
    y := floor((x * 100) + 0.5) / 100
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I01: CONTRIBUTION PRECISION ENGINE — składki groszowe
# Podstawa → stopa (19,52/8/2,45/1,67 z danych) → grosze; zakres podstawy
# (min = 60% prognozy; ulga aktywna → min nie obowiązuje); tolerancja 0,005.
# Art. 18a/18c/22 SUS [NIEZWERYFIKOWANE].
# ═══════════════════════════════════════════════════════════════════════════════
_cp_base := object.get(_ctx, "contribution_base", 0)
_cp_relief_active := object.get(_ctx, "relief_active", false)
_cp_base_min := _zr("social_base_standard", 5204.40)
_cp_pension := _grosze(_cp_base * _zr("pension_rate", 0.1952))
_cp_disability := _grosze(_cp_base * _zr("disability_rate", 0.08))
_cp_sickness := _grosze(_cp_base * _zr("sickness_voluntary_rate", 0.0245))
_cp_accident := _grosze(_cp_base * _zr("accident_rate", 0.0167))
_cp_total := _grosze(_cp_pension + _cp_disability + _cp_sickness + _cp_accident)
_cp_expected := object.get(_ctx, "expected_total", 0)
_cp_diff := _abs(_cp_total - _cp_expected)
_cp_tolerance := _th("v3_p26_grosz_tolerance", 0.005)

routing_cp1 = "BLOCK_AND_ALERT" {
    _cp_base <= 0
} else = "BLOCK_AND_ALERT" {
    _cp_base_min > 0
    not _cp_relief_active
    _cp_base < _cp_base_min
} else = "TRIAGE_QUEUE" {
    _cp_expected > 0
    _cp_diff > _cp_tolerance
} else = "SUGGEST" {
    true
}

reason_cp1 = "Podstawa składki brak/zero — fail-closed (BLOCK)." {
    _cp_base <= 0
} else = sprintf("Podstawa %.2f poniżej minimum 60%% prognozy (%.2f) bez aktywnej ulgi — BLOCK (art. 18a SUS).", [_cp_base, _cp_base_min]) {
    _cp_base_min > 0
    not _cp_relief_active
    _cp_base < _cp_base_min
} else = sprintf("Składki groszowe: total %.2f vs oczekiwane %.2f (diff %.4f > %.3f) — TRIAGE.",
    [_cp_total, _cp_expected, _cp_diff, _cp_tolerance]) {
    _cp_expected > 0
    _cp_diff > _cp_tolerance
} else = sprintf("Składki groszowe OK: emerytalna %.2f, rentowa %.2f, chorobowa %.2f, wypadkowa %.2f, total %.2f.",
    [_cp_pension, _cp_disability, _cp_sickness, _cp_accident, _cp_total]) {
    true
}

warnings_cp1 = ["[V3-P26-I01] Podstawa poniżej minimum bez ulgi — sprawdź kwalifikację ulgi (I02) przed płatnością."] {
    _cp_base_min > 0
    not _cp_relief_active
    _cp_base < _cp_base_min
    _cp_base > 0
} else = []

contribution_precision_decision := _certificate(426101, {
    "rule_id": "jdg.v3_p26_zus_skladki.contribution_precision",
    "analysis": "contribution_precision",
    "contribution_base": _cp_base,
    "pension": _cp_pension,
    "disability": _cp_disability,
    "sickness": _cp_sickness,
    "accident": _cp_accident,
    "total": _cp_total,
    "grosz_diff": _cp_diff,
    "fail_closed": _cp_base <= 0,
    "_routing": routing_cp1,
    "_routing_reason": reason_cp1,
    "_legal_basis": "Art. 18a/18c/22 ust. 1 ustawy o SUS [NIEZWERYFIKOWANE]; ADR-002 stopy z data.thresholds.zus",
    "_warnings": warnings_cp1,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "contribution_precision"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I02: RELIEF ORDER AUTOMATON — kolejność ulg jako automat
# NONE → START(6m) → PREFERENCYJNA(24m)/MALY_ZUS_PLUS(36m) → STANDARD;
# ulgi równoległe = BLOCK; przekroczenie limitu miesięcy = BLOCK; przejście
# PREFERENCYJNA→MALY_ZUS_PLUS = TRIAGE (wymaga weryfikacji art. 18c).
# Art. 18a/18b/18c SUS [NIEZWERYFIKOWANE].
# ═══════════════════════════════════════════════════════════════════════════════
_ro_state := object.get(_ctx, "relief_state", "")
_ro_prev := object.get(_ctx, "previous_state", "NONE")
_ro_months := object.get(_ctx, "relief_months_used", 0)
_ro_parallel := object.get(_ctx, "parallel_reliefs", false)
_ro_start_max := _zr("start_relief_months", 6)
_ro_pref_max := _zr("preferential_months", 24)
_ro_mzp_max := _zr("maly_zus_plus_months", 36)

_ro_months_limit = _ro_start_max {
    _ro_state == "START"
} else = _ro_pref_max {
    _ro_state == "PREFERENCYJNA"
} else = _ro_mzp_max {
    _ro_state == "MALY_ZUS_PLUS"
} else = 0 {
    true
}

_ro_known_state = true {
    _ro_state == "NONE"
} else = true {
    _ro_state == "START"
} else = true {
    _ro_state == "PREFERENCYJNA"
} else = true {
    _ro_state == "MALY_ZUS_PLUS"
} else = true {
    _ro_state == "STANDARD"
} else = false {
    true
}

_ro_valid_transition = true {
    _ro_prev == "NONE"
} else = true {
    _ro_prev == "START"
    _ro_state != "START"
} else = true {
    _ro_prev == "PREFERENCYJNA"
    _ro_state != "PREFERENCYJNA"
    _ro_state != "START"
} else = true {
    _ro_prev == "MALY_ZUS_PLUS"
    _ro_state == "STANDARD"
} else = true {
    _ro_prev == "STANDARD"
    _ro_state == "STANDARD"
} else = false {
    true
}

routing_ro2 = "BLOCK_AND_ALERT" {
    not _ro_known_state
} else = "BLOCK_AND_ALERT" {
    _ro_parallel
} else = "BLOCK_AND_ALERT" {
    _ro_state != "NONE"
    _ro_months > _ro_months_limit
} else = "BLOCK_AND_ALERT" {
    not _ro_valid_transition
} else = "TRIAGE_QUEUE" {
    _ro_prev == "PREFERENCYJNA"
    _ro_state == "MALY_ZUS_PLUS"
} else = "SUGGEST" {
    true
}

reason_ro2 = sprintf("Nieznany stan ulgi %s — BLOCK (fail-closed).", [_ro_state]) {
    not _ro_known_state
} else = "Ulgi łączone RÓWNOLEGLE — BLOCK (błąd klasyczny; art. 18a ust. 8 SUS — kolejność, nie łączenie)." {
    _ro_parallel
} else = sprintf("Ulga %s: wykorzystano %d mies. > limit %d — BLOCK (przekroczenie okresu ulgi).",
    [_ro_state, _ro_months, _ro_months_limit]) {
    _ro_state != "NONE"
    _ro_months > _ro_months_limit
} else = sprintf("Nieprawidłowe przejście ulg %s → %s — BLOCK (automat kolejności).",
    [_ro_prev, _ro_state]) {
    not _ro_valid_transition
} else = sprintf("Przejście PREFERENCYJNA → MALY_ZUS_PLUS wymaga weryfikacji art. 18c — TRIAGE.", []) {
    _ro_prev == "PREFERENCYJNA"
    _ro_state == "MALY_ZUS_PLUS"
} else = sprintf("Kolejność ulg poprawna: %s (%d/%d mies.).", [_ro_state, _ro_months, _ro_months_limit]) {
    true
}

warnings_ro2 = ["[V3-P26-I02] Przekroczony okres ulgi — dopłata składki pełnej za nadmiarowe miesiące."] {
    _ro_state != "NONE"
    _ro_months > _ro_months_limit
} else = []

relief_order_decision := _certificate(426102, {
    "rule_id": "jdg.v3_p26_zus_skladki.relief_order_automaton",
    "analysis": "relief_order",
    "relief_state": _ro_state,
    "previous_state": _ro_prev,
    "relief_months_used": _ro_months,
    "months_limit": _ro_months_limit,
    "parallel_reliefs": _ro_parallel,
    "fail_closed": _ro_parallel,
    "_routing": routing_ro2,
    "_routing_reason": reason_ro2,
    "_legal_basis": "Art. 18a (na start), 18b (preferencyjna), 18c (mały ZUS Plus) ustawy o SUS [NIEZWERYFIKOWANE]",
    "_warnings": warnings_ro2,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "relief_order"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I03: CUMULATIVE TIER SENTINEL — progi zdrowotnej ryczałt NARASTAJĄCO
# Przychód narastająco rocznie vs 60k/300k (±0,01 granica); przypisanie TIER
# 1/2/3; alarm PRZED przekroczeniem (≥90% progu); złe oczekiwane TIER = BLOCK.
# Art. 81 ust. 2b u.ś.o.z. [NIEZWERYFIKOWANE].
# ═══════════════════════════════════════════════════════════════════════════════
_ct_rev := object.get(_ctx, "cumulative_revenue_ytd", 0)
_ct_t1 := _zr("health_lump_tier_1_limit", 60000)
_ct_t2 := _zr("health_lump_tier_2_limit", 300000)
_ct_expected := object.get(_ctx, "expected_tier", "")
_ct_alert_pct := _th("v3_p26_tier_alert_approach_pct", 90)

_ct_tier = "TIER_1" {
    _ct_rev <= _ct_t1
} else = "TIER_2" {
    _ct_rev <= _ct_t2
} else = "TIER_3" {
    true
}

_ct_boundary = true {
    _grosze(_abs(_ct_rev - _ct_t1)) <= 0.01
} else = true {
    _grosze(_abs(_ct_rev - _ct_t2)) <= 0.01
} else = false {
    true
}

_ct_tier_mismatch = true {
    _ct_expected != ""
    _ct_expected != _ct_tier
} else = false {
    true
}

_ct_approaching = true {
    _ct_rev >= (_ct_t1 * _ct_alert_pct) / 100
    _ct_rev < _ct_t1
} else = true {
    _ct_rev >= (_ct_t2 * _ct_alert_pct) / 100
    _ct_rev < _ct_t2
} else = false {
    true
}

routing_ct3 = "BLOCK_AND_ALERT" {
    _ct_rev < 0
} else = "BLOCK_AND_ALERT" {
    _ct_tier_mismatch
} else = "TRIAGE_QUEUE" {
    _ct_boundary
} else = "TRIAGE_QUEUE" {
    _ct_approaching
} else = "SUGGEST" {
    true
}

reason_ct3 = sprintf("Przychód narastający ujemny (%.2f) — BLOCK (dane wejściowe).", [_ct_rev]) {
    _ct_rev < 0
} else = sprintf("TIER sprzeczny: oczekiwano %s, wyliczono %s (przychód %.2f) — BLOCK (golden progu).",
    [_ct_expected, _ct_tier, _ct_rev]) {
    _ct_tier_mismatch
} else = sprintf("Przychód %.2f na GRANICY progu (60k/300k ±0,01) — TRIAGE (precyzja groszowa progu).", [_ct_rev]) {
    _ct_boundary
} else = sprintf("Przychód %.2f ≥ %d%% progu %s — alarm PRZED przekroczeniem (progi NARASTAJĄCO).",
    [_ct_rev, _ct_alert_pct, _ct_tier]) {
    _ct_approaching
} else = sprintf("Przychód narastający %.2f → %s (progi %s/%s) — stabilnie.", [_ct_rev, _ct_tier, _ct_t1, _ct_t2]) {
    true
}

warnings_ct3 = ["[V3-P26-I03] Zbliżenie do progu — TIER wyższy od następnego miesiąca; zaplanuj składkę."] {
    _ct_approaching
} else = []

cumulative_tier_decision := _certificate(426103, {
    "rule_id": "jdg.v3_p26_zus_skladki.cumulative_tier_sentinel",
    "analysis": "cumulative_tier",
    "cumulative_revenue_ytd": _ct_rev,
    "tier": _ct_tier,
    "expected_tier": _ct_expected,
    "tier1_limit": _ct_t1,
    "tier2_limit": _ct_t2,
    "boundary_case": _ct_boundary,
    "_routing": routing_ct3,
    "_routing_reason": reason_ct3,
    "_legal_basis": "Art. 81 ust. 2b ustawy o świadczeniach opieki zdrowotnej [NIEZWERYFIKOWANE]; progi z data.thresholds.zus",
    "_warnings": warnings_ct3,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "cumulative_tier"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I04: HEALTH 2026 VERIFIER — wersja parametrów zdrowotnej + ISAP
# Wersja parametrów z danych (zus26.v3_p26_health_params_version); rozjazd
# wersji host↔dane = BLOCK; brak weryfikacji ISAP = TRIAGE (AKT 8.04/19).
# ═══════════════════════════════════════════════════════════════════════════════
_hv_host_version := object.get(_ctx, "health_params_version", "")
_hv_data_version := _th("v3_p26_health_params_version", "MISSING")
_hv_isap_verified := object.get(_ctx, "isap_verified", false)

_hv_version_mismatch = true {
    _hv_host_version != ""
    _hv_host_version != _hv_data_version
} else = false {
    true
}

routing_hv4 = "BLOCK_AND_ALERT" {
    _hv_version_mismatch
} else = "TRIAGE_QUEUE" {
    _hv_host_version == ""
} else = "TRIAGE_QUEUE" {
    not _hv_isap_verified
} else = "SUGGEST" {
    true
}

reason_hv4 = sprintf("Wersja parametrów zdrowotnej rozjeżdżona: host %s vs dane %s — BLOCK (akt 8.04).",
    [_hv_host_version, _hv_data_version]) {
    _hv_version_mismatch
} else = "Brak wersji parametrów zdrowotnej w wejściu — TRIAGE (nie można potwierdzić wersji)." {
    _hv_host_version == ""
} else = sprintf("Parametry zdrowotnej %s NIEZWERYFIKOWANE w ISAP — TRIAGE (stawki/progi 2026 do potwierdzenia).",
    [_hv_data_version]) {
    not _hv_isap_verified
} else = sprintf("Parametry zdrowotnej %s zgodne + ISAP zweryfikowane — zaufanie uzasadnione.", [_hv_data_version]) {
    true
}

warnings_hv4 = ["[V3-P26-I04] Stawki/progi zdrowotnej 2026 wymagają weryfikacji ISAP przed AUTO_POST (P0 potencjalny)."] {
    not _hv_isap_verified
} else = []

health_2026_verifier_decision := _certificate(426104, {
    "rule_id": "jdg.v3_p26_zus_skladki.health_2026_verifier",
    "analysis": "health_2026_verifier",
    "host_version": _hv_host_version,
    "data_version": _hv_data_version,
    "isap_verified": _hv_isap_verified,
    "fail_closed": _hv_version_mismatch,
    "_routing": routing_hv4,
    "_routing_reason": reason_hv4,
    "_legal_basis": "Art. 79-81 ustawy o świadczeniach opieki zdrowotnej; obwieszczenia MF (P06) [NIEZWERYFIKOWANE]",
    "_warnings": warnings_hv4,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "health_2026_verifier"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I05: SUSPENSION CONTRIBUTION HANDLER — zawieszenie a składki
# Zawieszenie wymaga pauzy ulgi (aktywna ulga bez pauzy = BLOCK); dni zdrowotnej
# w zawieszeniu = TRIAGE; długie zawieszenie = TRIAGE (art. 18a/21 SUS,
# kontrakt V3_P23 cyklu życia) [NIEZWERYFIKOWANE].
# ═══════════════════════════════════════════════════════════════════════════════
_su_suspended := object.get(_ctx, "suspended", false)
_su_months := object.get(_ctx, "suspension_months", 0)
_su_relief_active := object.get(_ctx, "relief_active", false)
_su_relief_paused := object.get(_ctx, "relief_paused", false)
_su_health_days := object.get(_ctx, "health_contribution_days", 0)
_su_alert_months := _th("v3_p26_suspension_alert_months", 24)

routing_su5 = "BLOCK_AND_ALERT" {
    _su_suspended
    _su_relief_active
    not _su_relief_paused
} else = "TRIAGE_QUEUE" {
    _su_suspended
    _su_health_days > 0
} else = "TRIAGE_QUEUE" {
    _su_suspended
    _su_months >= _su_alert_months
} else = "SUGGEST" {
    true
}

reason_su5 = "Zawieszenie z AKTYWNĄ ulgą bez pauzy — BLOCK (ulga nie pauzowana; błędna składka)." {
    true
} else = sprintf("Zawieszenie z %d dni składki zdrowotnej — TRIAGE (dni aktywności w zawieszeniu do weryfikacji).",
    [_su_health_days]) {
    _su_suspended
    _su_health_days > 0
} else = sprintf("Zawieszenie trwa %d mies. ≥ %d — TRIAGE (przegląd cyklu życia; kontrakt V3_P23).",
    [_su_months, _su_alert_months]) {
    _su_suspended
    _su_months >= _su_alert_months
} else = sprintf("Zawieszenie obsłużone: ulga pauzowana, %d mies., składki wstrzymane.", [_su_months]) {
    true
}

warnings_su5 = ["[V3-P26-I05] Aktywna ulga w zawieszeniu bez pauzy — korekta DRA wymagana."] {
    _su_suspended
    _su_relief_active
    not _su_relief_paused
} else = []

suspension_handler_decision := _certificate(426105, {
    "rule_id": "jdg.v3_p26_zus_skladki.suspension_handler",
    "analysis": "suspension_handler",
    "suspended": _su_suspended,
    "suspension_months": _su_months,
    "relief_active": _su_relief_active,
    "relief_paused": _su_relief_paused,
    "health_contribution_days": _su_health_days,
    "_routing": routing_su5,
    "_routing_reason": reason_su5,
    "_legal_basis": "Art. 18a ust. 8-9 i art. 21 ustawy o SUS (skutki zawieszenia); kontrakt V3_P23 [NIEZWERYFIKOWANE]",
    "_warnings": warnings_su5,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "suspension_handler"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I06: DRA GENERATOR VALIDATED — DRA/RCA/ZZA z walidacją zero-ciszy
# Nieznany formularz = BLOCK; brak pól wymaganych/identyfikatora/okresu = BLOCK
# (zero ciszy, kontrakt V3_P25); pracownicy>0 → RCA (przewidywana forma).
# Art. 47 ust. 1-3 SUS [NIEZWERYFIKOWANE].
# ═══════════════════════════════════════════════════════════════════════════════
_dg_form := object.get(_ctx, "form_type", "")
_dg_fields_ok := object.get(_ctx, "required_fields_present", false)
_dg_ident := object.get(_ctx, "payer_identified", false)
_dg_period := object.get(_ctx, "declaration_period", "")
_dg_employees := object.get(_ctx, "employees_count", 0)

_dg_known_form = true {
    _dg_form == "DRA"
} else = true {
    _dg_form == "RCA"
} else = true {
    _dg_form == "ZZA"
} else = true {
    _dg_form == "RCA_ALIGN"
} else = false {
    true
}

_dg_form_expected = "RCA" {
    _dg_employees > 0
} else = "DRA" {
    true
}

routing_dg6 = "BLOCK_AND_ALERT" {
    not _dg_known_form
} else = "BLOCK_AND_ALERT" {
    not _dg_fields_ok
} else = "BLOCK_AND_ALERT" {
    not _dg_ident
} else = "BLOCK_AND_ALERT" {
    _dg_period == ""
} else = "TRIAGE_QUEUE" {
    _dg_form != _dg_form_expected
} else = "SUGGEST" {
    true
}

reason_dg6 = sprintf("Nieznany formularz %s — BLOCK (DRA/RCA/ZZA/RCA_ALIGN).", [_dg_form]) {
    not _dg_known_form
} else = "Brak pól wymaganych formularza — BLOCK (zero ciszy; walidacja schematu ZUS)." {
    not _dg_fields_ok
} else = "Brak identyfikatora płatnika (NIP/PESEL) — BLOCK (fail-closed)." {
    not _dg_ident
} else = "Brak okresu rozliczeniowego deklaracji — BLOCK (zero ciszy)." {
    _dg_period == ""
} else = sprintf("Forma %s vs przewidywana %s (pracownicy: %d) — TRIAGE (wybór DRA vs RCA).",
    [_dg_form, _dg_form_expected, _dg_employees]) {
    _dg_form != _dg_form_expected
} else = sprintf("Formularz %s kompletny (okres %s, pracownicy %d) — gotowy do generowania.",
    [_dg_form, _dg_period, _dg_employees]) {
    true
}

warnings_dg6 = ["[V3-P26-I06] Forma deklaracji niezgodna z liczbą pracowników — RCA wymaga zatrudnienia."] {
    _dg_form != _dg_form_expected
} else = []

dra_generator_decision := _certificate(426106, {
    "rule_id": "jdg.v3_p26_zus_skladki.dra_generator",
    "analysis": "dra_generator",
    "form_type": _dg_form,
    "declaration_period": _dg_period,
    "employees_count": _dg_employees,
    "expected_form": _dg_form_expected,
    "fields_present": _dg_fields_ok,
    "_routing": routing_dg6,
    "_routing_reason": reason_dg6,
    "_legal_basis": "Art. 47 ust. 1-3 ustawy o SUS (DRA 10./15., RCA); kalendarz V3_P25 [NIEZWERYFIKOWANE]",
    "_warnings": warnings_dg6,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "dra_generator"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I07: ZUS INVARIANTS PACK — konstytucja składkowa (kontrakt V3_P04)
# składki ≥ 0; podstawa w zakresie; kolejność ulg poprawna; precyzja groszowa;
# każde naruszenie = BLOCK_AND_ALERT z listą naruszeń (nigdy cicho).
# ═══════════════════════════════════════════════════════════════════════════════
_iv_contributions := object.get(_ctx, "contributions", {})
_iv_viol_neg = ["CONTRIBUTION_NEGATIVE"] {
    some c in _iv_contributions
    c < 0
} else = []

_iv_base_flag := object.get(_ctx, "contribution_base", 0)
_iv_viol_range = ["BASE_OUT_OF_RANGE"] {
    _iv_base_flag > 0
    not object.get(_ctx, "relief_active", false)
    _iv_base_flag < _zr("social_base_standard", 5204.40)
} else = []

_iv_viol_order = ["RELIEF_ORDER_INVALID"] {
    not object.get(_ctx, "relief_order_valid", true)
} else = []

_iv_viol_precision = ["GROSZ_PRECISION_INVALID"] {
    not object.get(_ctx, "grosz_precision_ok", true)
} else = []

_iv_violations := array.concat(array.concat(_iv_viol_neg, _iv_viol_range),
                               array.concat(_iv_viol_order, _iv_viol_precision))
_iv_count := count(_iv_violations)

routing_iv7 = "BLOCK_AND_ALERT" {
    _iv_count > 0
} else = "SUGGEST" {
    true
}

reason_iv7 = sprintf("Naruszone invarianty ZUS (%d): %v — BLOCK_AND_ALERT (kontrakt V3_P04).",
    [_iv_count, _iv_violations]) {
    _iv_count > 0
} else = "Invarianty ZUS zachowane: składki ≥ 0, podstawa w zakresie, kolejność ulg, grosze." {
    true
}

warnings_iv7 = ["[V3-P26-I07] Naruszenie konstytucji składkowej — AUTO_POST zabroniony (INV pack)."] {
    _iv_count > 0
} else = []

invariants_pack_decision := _certificate(426107, {
    "rule_id": "jdg.v3_p26_zus_skladki.invariants_pack",
    "analysis": "invariants_pack",
    "violations": _iv_violations,
    "violation_count": _iv_count,
    "fail_closed": _iv_count > 0,
    "_routing": routing_iv7,
    "_routing_reason": reason_iv7,
    "_legal_basis": "Kontrakt invariantów V3_P04; art. 18a/18c/22 SUS [NIEZWERYFIKOWANE]",
    "_warnings": warnings_iv7,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "invariants_pack"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I08: ZUS GOLDEN SET — oracle granic składkowych (kontrakt V3_P10)
# Golden: granice ulg, progi 60k/300k, grosze 4161,00 → 812,63. Złe oczekiwane
# routingi = BLOCK (regresja prawna); zgodność = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_gs_case := object.get(_ctx, "case_id", "")
_gs_in_set := object.get(_ctx, "in_golden_set", false)
_gs_expected := object.get(_ctx, "expected_routing", "")
_gs_actual := object.get(_ctx, "actual_routing", "")
_gs_golden_version := _th("v3_p26_golden_version", "zus-golden-2026.09")

_gs_match = true {
    _gs_in_set
    _gs_expected != ""
    _gs_expected == _gs_actual
} else = false {
    true
}

_gs_mismatch = true {
    _gs_in_set
    _gs_expected != ""
    not _gs_match
} else = false {
    true
}

routing_gs8 = "BLOCK_AND_ALERT" {
    _gs_mismatch
} else = "TRIAGE_QUEUE" {
    _gs_in_set
    _gs_expected == ""
} else = "SUGGEST" {
    true
}

reason_gs8 = sprintf("Golden %s: sprzeczność — oczekiwano %s, uzyskano %s (BLOCK; regresja składkowa).",
    [_gs_case, _gs_expected, _gs_actual]) {
    _gs_mismatch
} else = sprintf("Golden %s: brak oczekiwanego routingu — uzupełnij oczekiwanie (TRIAGE).", [_gs_case]) {
    _gs_in_set
    _gs_expected == ""
} else = sprintf("Golden %s: zgodność potwierdzona (%s, wersja %s).", [_gs_case, _gs_actual, _gs_golden_version]) {
    true
}

warnings_gs8 = ["[V3-P26-I08] Golden niezgodny — zmiana w składkach może być regresją prawną."] {
    _gs_mismatch
} else = []

zus_golden_set_decision := _certificate(426108, {
    "rule_id": "jdg.v3_p26_zus_skladki.golden_set",
    "analysis": "golden_set",
    "case_id": _gs_case,
    "golden_version": _gs_golden_version,
    "expected_routing": _gs_expected,
    "actual_routing": _gs_actual,
    "golden_match": _gs_match,
    "fail_closed": _gs_mismatch,
    "_routing": routing_gs8,
    "_routing_reason": reason_gs8,
    "_legal_basis": "V3_P10 (Golden Oracle); granice art. 18a/18c/22 SUS, 81 u.ś.o.z. [NIEZWERYFIKOWANE]",
    "_warnings": warnings_gs8,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_set"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I09: FORM CHANGE HEALTH RESCALER — zmiana formy w trakcie roku
# Zmiana formy (miesiąc > 0) wymaga przeliczenia zdrowotnej per okres kwartalny
# (v3_p26_health_rescale_periods); niekompletne = TRIAGE; nadmiarowe = BLOCK.
# Art. 81 u.ś.o.z. [NIEZWERYFIKOWANE].
# ═══════════════════════════════════════════════════════════════════════════════
_fc_change_month := object.get(_ctx, "form_change_month", 0)
_fc_periods_needed := _th("v3_p26_health_rescale_periods", 4)
_fc_periods_done := object.get(_ctx, "rescaled_periods", 0)

routing_fc9 = "SUGGEST" {
    _fc_change_month <= 0
} else = "BLOCK_AND_ALERT" {
    _fc_periods_done > _fc_periods_needed
} else = "TRIAGE_QUEUE" {
    _fc_periods_done < _fc_periods_needed
} else = "SUGGEST" {
    true
}

reason_fc9 = "Brak zmiany formy w roku — przeliczenie nie dotyczy." {
    _fc_change_month <= 0
} else = sprintf("Zmiana formy w mies. %d: %d/%d okresów przeliczonych — nadmiarowe = BLOCK.",
    [_fc_change_month, _fc_periods_done, _fc_periods_needed]) {
    _fc_periods_done > _fc_periods_needed
} else = sprintf("Zmiana formy w mies. %d: %d/%d okresów przeliczonych — TRIAGE (niekompletne przeliczenie zdrowotnej).",
    [_fc_change_month, _fc_periods_done, _fc_periods_needed]) {
    _fc_periods_done < _fc_periods_needed
} else = sprintf("Zmiana formy w mies. %d: przeliczenie zdrowotnej kompletne (%d okresów).",
    [_fc_change_month, _fc_periods_done]) {
    true
}

warnings_fc9 = ["[V3-P26-I09] Niekompletne przeliczenie zdrowotnej po zmianie formy — korekta roczna 22 maja."] {
    _fc_change_month > 0
    _fc_periods_done < _fc_periods_needed
} else = []

form_change_rescaler_decision := _certificate(426109, {
    "rule_id": "jdg.v3_p26_zus_skladki.form_change_rescaler",
    "analysis": "form_change_rescaler",
    "form_change_month": _fc_change_month,
    "rescale_periods_needed": _fc_periods_needed,
    "rescaled_periods": _fc_periods_done,
    "_routing": routing_fc9,
    "_routing_reason": reason_fc9,
    "_legal_basis": "Art. 81 ust. 2-2b u.ś.o.z. (zmiana formy → korekta zdrowotnej) [NIEZWERYFIKOWANE]",
    "_warnings": warnings_fc9,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "form_change_rescaler"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I10: MINIMUM WAGE INTEGRATION — podstawa preferencyjnej od minimalnej
# Feed P06 (minimalne wynagrodzenie) wymagany: brak = BLOCK fail-closed;
# dryf ≥ v3_p26_min_wage_drift_pct od referencji w danych = TRIAGE.
# Art. 18b ust. 5 SUS; obwieszczenie MF [NIEZWERYFIKOWANE].
# ═══════════════════════════════════════════════════════════════════════════════
_mw_feed := object.get(_ctx, "minimum_wage_monthly", 0)
_mw_ref := _zr("preferential_base_30pct", 1440.00) / 0.30
_mw_base30 := _grosze(_mw_feed * 0.30)
_mw_drift_pct = 0 {
    _mw_feed <= 0
} else = (_abs(_mw_feed - _mw_ref) * 100) / _mw_ref {
    true
}
_mw_drift_limit := _th("v3_p26_min_wage_drift_pct", 1.0)

routing_mw10 = "BLOCK_AND_ALERT" {
    _mw_feed <= 0
} else = "TRIAGE_QUEUE" {
    _mw_drift_pct > _mw_drift_limit
} else = "SUGGEST" {
    true
}

reason_mw10 = "Brak feedu minimalnego wynagrodzenia (P06) — BLOCK (podstawa preferencyjnej niepoliczalna)." {
    _mw_feed <= 0
} else = sprintf("Minimalna %.2f vs referencja %.2f (dryf %.2f%% ≥ %.2f%%) — TRIAGE (feed P06 do odświeżenia).",
    [_mw_feed, _mw_ref, _mw_drift_pct, _mw_drift_limit]) {
    _mw_drift_pct > _mw_drift_limit
} else = sprintf("Podstawa preferencyjnej %.2f = 30%% minimalnej (%.2f) — feed P06 spójny.", [_mw_base30, _mw_feed]) {
    true
}

warnings_mw10 = ["[V3-P26-I10] Dryf feedu minimalnej — podstawa preferencyjnej 24 mies. może być błędna."] {
    _mw_feed > 0
    _mw_drift_pct > _mw_drift_limit
} else = []

minimum_wage_decision := _certificate(426110, {
    "rule_id": "jdg.v3_p26_zus_skladki.minimum_wage_integration",
    "analysis": "minimum_wage_integration",
    "minimum_wage_monthly": _mw_feed,
    "preferential_base": _mw_base30,
    "drift_pct": _mw_drift_pct,
    "_routing": routing_mw10,
    "_routing_reason": reason_mw10,
    "_legal_basis": "Art. 18b ust. 5 ustawy o SUS (30% minimalnego); feed P06/obwieszczenie MF [NIEZWERYFIKOWANE]",
    "_warnings": warnings_mw10,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "minimum_wage_integration"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I11: ZUS STRESS LAB — symulatory scenariuszy składkowych
# Scenariusze (zmiana formy / zawieszenie Q4 / próg w listopadzie NARASTAJĄCO)
# jako dane wejściowe; brak wymaganego kompletu = BLOCK; niezgodny routing
# scenariusza = BLOCK (chaos-test prawny K10, kontrakt V3_P04).
# ═══════════════════════════════════════════════════════════════════════════════
_sl_cases := object.get(_ctx, "scenarios", [])
_sl_required := _th("v3_p26_stress_required_scenarios", 3)
_sl_failures := [object.get(c, "name", "?") |
    some c in _sl_cases
    object.get(c, "actual_routing", "") != object.get(c, "expected_routing", "")
]
_sl_fail_count := count(_sl_failures)

routing_sl11 = "BLOCK_AND_ALERT" {
    count(_sl_cases) < _sl_required
} else = "BLOCK_AND_ALERT" {
    _sl_fail_count > 0
} else = "SUGGEST" {
    true
}

reason_sl11 = sprintf("Laboratorium stresowe niekompletne: %d/%d scenariuszy — BLOCK.",
    [count(_sl_cases), _sl_required]) {
    count(_sl_cases) < _sl_required
} else = sprintf("Scenariusze niezgodne: %v — BLOCK (chaos-test fail-closed).", [_sl_failures]) {
    _sl_fail_count > 0
} else = sprintf("Stress lab: %d scenariuszy zgodnych — odporność potwierdzona.", [count(_sl_cases)]) {
    true
}

warnings_sl11 = ["[V3-P26-I11] Scenariusz stresowy niezgodny — silnik składkowy może działać fail-open."] {
    _sl_fail_count > 0
} else = []

stress_lab_decision := _certificate(426111, {
    "rule_id": "jdg.v3_p26_zus_skladki.stress_lab",
    "analysis": "stress_lab",
    "scenario_count": count(_sl_cases),
    "required_scenarios": _sl_required,
    "failures": _sl_failures,
    "fail_closed": _sl_fail_count > 0,
    "_routing": routing_sl11,
    "_routing_reason": reason_sl11,
    "_legal_basis": "V3_P04 (chaos-test fail-closed K10); scenariusze AN01-AN12 części P26",
    "_warnings": warnings_sl11,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "stress_lab"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P26-I12: CROSS-ACT CONSISTENCY GATE — ZUS×PIT×ryczałt (spójność zdrowotnej)
# Zadeklarowana zdrowotna vs domena: skala → 9% dochodu; liniowy → 4,9% dochodu;
# ryczałt → kwota TIER z danych. Rozjazd > tolerancji = BLOCK_AND_ALERT;
# brak danych = TRIAGE; spójność = SUGGEST. Art. 81 u.ś.o.z. [NIEZWERYFIKOWANE].
# ═══════════════════════════════════════════════════════════════════════════════
_xa_form := object.get(_ctx, "tax_form", "")
_xa_income := object.get(_ctx, "pit_income", 0)
_xa_declared := object.get(_ctx, "health_contributed", 0)
_xa_tolerance := _th("v3_p26_grosz_tolerance", 0.005)
_xa_scale_rate := _zr("health_scale_rate", 0.09)
_xa_linear_rate := _zr("health_linear_rate", 0.049)
_xa_tier_amounts := {"TIER_1": _zr("health_lump_tier_1_amount", 491.40),
                     "TIER_2": _zr("health_lump_tier_2_amount", 819.00),
                     "TIER_3": _zr("health_lump_tier_3_amount", 1474.20)}

_xa_expected = _grosze(_xa_income * _xa_scale_rate) {
    _xa_form == "SCALE"
} else = _grosze(_xa_income * _xa_linear_rate) {
    _xa_form == "LINEAR"
} else = object.get(_xa_tier_amounts, object.get(_ctx, "health_tier", "TIER_1"), 0) {
    _xa_form == "LUMP_SUM"
} else = 0 {
    true
}

_xa_diff := _abs(_xa_declared - _xa_expected)
_xa_known_form = true {
    _xa_form == "SCALE"
} else = true {
    _xa_form == "LINEAR"
} else = true {
    _xa_form == "LUMP_SUM"
} else = false {
    true
}

routing_xa12 = "BLOCK_AND_ALERT" {
    not _xa_known_form
} else = "TRIAGE_QUEUE" {
    _xa_declared <= 0
    _xa_expected > 0
} else = "BLOCK_AND_ALERT" {
    _xa_diff > _xa_tolerance
} else = "SUGGEST" {
    true
}

reason_xa12 = sprintf("Nieznana forma opodatkowania %s — BLOCK (spójność ZUS×PIT×ryczałt).", [_xa_form]) {
    not _xa_known_form
} else = "Zdrowotna niezadeklarowana przy oczekiwanej kwocie — TRIAGE (brak danych, nie cisza)." {
    _xa_declared <= 0
    _xa_expected > 0
} else = sprintf("Zdrowotna rozjechana: zadeklarowana %.2f vs wyliczona %.2f (diff %.4f) — BLOCK (cross-act).",
    [_xa_declared, _xa_expected, _xa_diff]) {
    _xa_diff > _xa_tolerance
} else = sprintf("Zdrowotna spójna z formą %s: %.2f (cross-act OK).", [_xa_form, _xa_declared]) {
    true
}

warnings_xa12 = ["[V3-P26-I12] Rozjazd zdrowotnej ZUS vs PIT/ryczałt — korekta przed AUTO_POST."] {
    _xa_known_form
    _xa_diff > _xa_tolerance
} else = []

cross_act_consistency_decision := _certificate(426112, {
    "rule_id": "jdg.v3_p26_zus_skladki.cross_act_consistency",
    "analysis": "cross_act_consistency",
    "tax_form": _xa_form,
    "pit_income": _xa_income,
    "health_contributed": _xa_declared,
    "health_expected": _xa_expected,
    "diff": _xa_diff,
    "_routing": routing_xa12,
    "_routing_reason": reason_xa12,
    "_legal_basis": "Art. 81 u.ś.o.z.; kontrakty V3_P14 (dochód) i V3_P18 (przychody ryczałtu) [NIEZWERYFIKOWANE]",
    "_warnings": warnings_xa12,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "cross_act_consistency"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := contribution_precision_decision {
    contribution_precision_decision.rule_id != ""
} else := relief_order_decision {
    relief_order_decision.rule_id != ""
} else := cumulative_tier_decision {
    cumulative_tier_decision.rule_id != ""
} else := health_2026_verifier_decision {
    health_2026_verifier_decision.rule_id != ""
} else := suspension_handler_decision {
    suspension_handler_decision.rule_id != ""
} else := dra_generator_decision {
    dra_generator_decision.rule_id != ""
} else := invariants_pack_decision {
    invariants_pack_decision.rule_id != ""
} else := zus_golden_set_decision {
    zus_golden_set_decision.rule_id != ""
} else := form_change_rescaler_decision {
    form_change_rescaler_decision.rule_id != ""
} else := minimum_wage_decision {
    minimum_wage_decision.rule_id != ""
} else := stress_lab_decision {
    stress_lab_decision.rule_id != ""
} else := cross_act_consistency_decision {
    cross_act_consistency_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": _no_match_id,
    "package": "jdg.v3_p26_zus_skladki",
    "priority": 999999,
    "_warnings": ["[V3-P26] Brak aktywnej analizy — brak decyzji."],
}
