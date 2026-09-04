# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P20 KSIĘGOWOŚĆ PKPiR / UoR / AMORTYZACJA / LEASING ENTERPRISE
# (V3 FORTRESS)
# ===============================================================================
# Rdzeń księgowości ENTERPRISE — 12 innowacji (I01–I12):
#   I01 PKPiR Schema Validator (kolumny 1-17 jako dane, typy wpisów, memoriał
#       kasowy 14 dni, zakaz kolizji wpisów),
#   I02 Remanent Chain Engine (art. 24a: koszty = Rk − Rp; invariant łańcucha
#       Rk roku N = Rp roku N+1 z audytem),
#   I03 NKUP Boundary Engine (art. 22/22d/22f: użycie < 1 roku → koszt bieżący;
#       granica 10 000 → koszt jednorazowy vs środek trwały),
#   I04 One-Time Deprecation Sentinel (art. 22k ust. 7: limit 100k, grupy 3-8,
#       auta osobowe wykluczone, alarm 80%),
#   I05 KŚT Rates as Data (tabele grupy→stawki jako dane wersjonowane,
#       modyfikatory art. 22i/22k: degresja 2,0/1,4, indywidualna ≤ 2×),
#   I06 Leasing Split Engine (operacyjny vs finansowy — testy art. 17f 90%/75%,
#       limit aut 150k art. 23 ust. 1 pkt 47a),
#   I07 PKPiR→UoR Transition (przekroczenie progu 2M EUR — przejście ewidencji
#       z procedurą i audytem),
#   I08 Year-End Closing Chain (zamknięcie roku: PKPiR → amortyzacja → PIT (P14)
#       → JPK (P16) — łańcuch spójny),
#   I09 Double-Entry Consistency Gate (UoR: bilans zbalansowany zawsze,
#       tolerancja groszowa 0,01),
#   I10 Bookkeeping Golden Set (golden ewidencje: remanent, amortyzacja, NKUP,
#       leasing w oracle),
#   I11 Bookkeeping Invariants Pack (PKPiR=PIT=JPK, bilans zbalansowany,
#       grosze — kontrakt P04),
#   I12 Document Checklist Generator (checklisty dowodów per typ ewidencji —
#       PKPiR/UoR/amortyzacja/leasing).
#
# Zasady:
#   * WSZYSTKIE stawki/limity/terminy z data.jdg.thresholds.ksiegowosc
#     (sekcja v3_p20_*) — ADR-002 (P06). Limity współdzielone (150k aut,
#     10k NKUP, 100k jednorazowa, stawki KŚT, próg 2M EUR) REUŻYWANE z bloków
#     depreciation/accounting (AP04/AP12 — zero duplikacji wartości).
#   * FAIL-CLOSED: brak danych / konflikt / naruszenie invariantu (P04) =
#     NEEDS_ADVICE lub BLOCK_AND_ALERT — nigdy cichy AUTO_POST (AP07).
#   * Aktywacja: input.jdg_entrepreneur.v3_p20_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p20_ksiegowosc.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p20_ksiegowosc
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p20_ksiegowosc

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p20_check", false) == true
_ctx := object.get(input, "v3_p20", {})

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p20_ksiegowosc.no_match",
    "package": "jdg.v3_p20_ksiegowosc",
    "priority": 999999,
}

# ── Snapshoty progów (ADR-002) ─────────────────────────────────────────────────
_ksiegowosc := data.jdg.thresholds.ksiegowosc
_dep := data.jdg.thresholds.depreciation
_acct := data.jdg.thresholds.accounting
_snapshot_ok := count(_ksiegowosc) > 0

_th(key, fallback) = value {
    _snapshot_ok
    value := object.get(_ksiegowosc, key, null)
    value != null
} else = fallback

_dep_th(key, fallback) = value {
    count(_dep) > 0
    value := object.get(_dep, key, null)
    value != null
} else = fallback

_acct_th(key, fallback) = value {
    count(_acct) > 0
    value := object.get(_acct, key, null)
    value != null
} else = fallback

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p20_ksiegowosc.thresholds_missing",
    "package": "jdg.v3_p20_ksiegowosc",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Księgowość V3-P20: brak snapshotu data.jdg.thresholds.ksiegowosc.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P20] Brak snapshotu progów księgowości — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p20_ksiegowosc",
        "priority": priority,
        "threshold_version": object.get(_ksiegowosc, "v3_p20_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_ksiegowosc, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_ksiegowosc, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

_round2(value) = result {
    scaled := value * 100
    result := floor(scaled + 0.5) / 100
}

_abs(value) = result {
    value >= 0
    result := value
} else = result {
    result := value * -1
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I01: PKPiR SCHEMA VALIDATOR (kolumny 1-17)
# Walidacja wpisów PKPiR względem schematu kolumn (dane: pkpir_columns 17,
# wersja v3_p20_schema_version, memoriał kasowy 14 dni). Typ wpisu nieznany,
# kwota ujemna/brak, kolizja (ten sam dokument w dwóch typach) lub zapis po
# terminie 14 dni = BLOCK; komplet = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_sv_columns := _th("pkpir_columns", 17)
_sv_rows := object.get(_ctx, "rows", [])
_sv_cash_days := _th("v3_p20_pkpir_cash_booking_days", 14)

_known_types := {"PRZYCHOD", "KOSZT", "LIKWIDACJA_SRODKA", "REMANENT", "POZOSTALE"}

_sv_type_known = true {
    count([r | r := _sv_rows[_]; not r.entry_type in _known_types]) == 0
} else = false

_sv_no_bad_amount = true {
    count([r | r := _sv_rows[_]; r.amount_pln <= 0]) == 0
} else = false

_sv_docs := {doc_id | r := _sv_rows[_]; doc_id := r.doc_id}

_sv_no_collision = true {
    count(_sv_docs) == count([r | r := _sv_rows[_]])
} else = false

_sv_late = true {
    count([r | r := _sv_rows[_]; r.days_late > _sv_cash_days]) > 0
} else = false

_sv_data_complete := object.get(_ctx, "data_complete", true)
_sv_ok = true {
    _sv_type_known
    _sv_no_bad_amount
    _sv_no_collision
    not _sv_late
    _sv_data_complete
} else = false

routing_sv = "BLOCK_AND_ALERT" {
    not _sv_type_known
} else = "BLOCK_AND_ALERT" {
    not _sv_no_bad_amount
} else = "BLOCK_AND_ALERT" {
    not _sv_no_collision
} else = "BLOCK_AND_ALERT" {
    _sv_late
} else = "BLOCK_AND_ALERT" {
    not _sv_data_complete
} else = "SUGGEST" {
    true
}

reason_sv = sprintf("PKPiR: wpis z nieznanym typem / kolumną poza schematem %d kolumn (BLOCK).", [_sv_columns]) {
    not _sv_type_known
} else = "PKPiR: wpis z kwotą <= 0 — ewidencja tylko kwot dodatnich (BLOCK)." {
    not _sv_no_bad_amount
} else = "PKPiR: kolizja — ten sam dokument w więcej niż jednym typie wpisu (BLOCK)." {
    not _sv_no_collision
} else = sprintf("PKPiR: zapis po terminie memoriału kasowego (> %d dni) — BLOCK.", [_sv_cash_days]) {
    _sv_late
} else = "PKPiR: brak kompletnych danych wpisu — fail-closed (BLOCK)." {
    not _sv_data_complete
} else = sprintf("PKPiR: %d wpisów zgodnych ze schematem kolumn (wersja %s) — AUTO_POST możliwy.", [count(_sv_rows), _th("v3_p20_schema_version", "pkpir-cols-17-2025.11")]) {
    true
}

warnings_sv = ["[V3-P20-I01] PKPiR: kolizja dokumentu w typach wpisu — BLOCK przed księgowaniem."] {
    not _sv_no_collision
} else = ["[V3-P20-I01] PKPiR: wpis po terminie memoriału kasowego — BLOCK."] {
    _sv_late
} else = []

pkpir_schema_decision := _certificate(386101, {
    "rule_id": "jdg.v3_p20_ksiegowosc.pkpir_schema_validator",
    "analysis": "pkpir_schema_validator",
    "rows_count": count(_sv_rows),
    "columns": _sv_columns,
    "schema_version": _th("v3_p20_schema_version", "pkpir-cols-17-2025.11"),
    "type_known": _sv_type_known,
    "no_collision": _sv_no_collision,
    "late_entries": _sv_late,
    "cash_booking_days": _sv_cash_days,
    "ok": _sv_ok,
    "_routing": routing_sv,
    "_routing_reason": reason_sv,
    "_legal_basis": "rozporządzenie MF z 15.11.2025 (PKPiR — kolumny 1-17); art. 24a ust. 1/2 PIT [NIEZWERYFIKOWANE]",
    "_warnings": warnings_sv,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "pkpir_schema_validator"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I02: REMANENT CHAIN ENGINE (art. 24a ust. 6-7)
# Łańcuch remanentów: koszty = Rk − Rp; invariant Rk roku N = Rp roku N+1.
# Brak poprzedniego remanentu / ujemny wpływ / złamanie łańcucha = BLOCK;
# niepewność (dane częściowe) = TRIAGE.
# ═══════════════════════════════════════════════════════════════════════════════
_rc_year := object.get(_ctx, "year", 0)
_rc_rp := object.get(_ctx, "opening_remanent_pln", 0.0)
_rc_rk := object.get(_ctx, "closing_remanent_pln", 0.0)
_rc_prev_rk := object.get(_ctx, "prev_year_closing_pln", null)
_rc_prev_rk_present := _rc_prev_rk != null
_rc_data_ok = true {
    _rc_year > 0
    _rc_rp >= 0
    _rc_rk >= 0
} else = false

_rc_cost_impact := _round2(_rc_rk - _rc_rp)

_rc_chain_broken = true {
    _rc_data_ok
    _rc_prev_rk_present
    _rc_prev_rk != _rc_rp
} else = false

_rc_negative = true {
    _rc_data_ok
    _rc_rk < _rc_rp
} else = false

_rc_cost_negative = true {
    _rc_data_ok
    not _rc_negative
    _rc_cost_impact < 0
} else = false

routing_rc = "BLOCK_AND_ALERT" {
    not _rc_data_ok
} else = "BLOCK_AND_ALERT" {
    _rc_chain_broken
} else = "TRIAGE_QUEUE" {
    _rc_negative
} else = "TRIAGE_QUEUE" {
    _rc_cost_negative
} else = "SUGGEST" {
    true
}

reason_rc = sprintf("Remanent %d: brak danych (Rp=%.2f, Rk=%.2f) — fail-closed (BLOCK).", [_rc_year, _rc_rp, _rc_rk]) {
    not _rc_data_ok
} else = sprintf("Remanent %d: Rk poprzedniego roku (%.2f) != Rp bieżącego (%.2f) — łańcuch ZERWANY (BLOCK).", [_rc_year, _rc_prev_rk, _rc_rp]) {
    _rc_chain_broken
} else = sprintf("Remanent %d: Rk (%.2f) < Rp (%.2f) — spadek remanentu do weryfikacji (TRIAGE).", [_rc_year, _rc_rk, _rc_rp]) {
    _rc_negative
} else = sprintf("Remanent %d: koszty remanentowe ujemne (%.2f) — do przeglądu (TRIAGE).", [_rc_year, _rc_cost_impact]) {
    _rc_cost_negative
} else = sprintf("Remanent %d: koszty remanentowe = Rk − Rp = %.2f PLN — zgodny z art. 24a.", [_rc_year, _rc_cost_impact]) {
    true
}

warnings_rc = ["[V3-P20-I02] Złamanie invariantu łańcucha remanentów (Rk N = Rp N+1) — BLOCK + audyt."] {
    _rc_chain_broken
} else = []

remanent_chain_decision := _certificate(386102, {
    "rule_id": "jdg.v3_p20_ksiegowosc.remanent_chain_engine",
    "analysis": "remanent_chain",
    "year": _rc_year,
    "opening_remanent_pln": _rc_rp,
    "closing_remanent_pln": _rc_rk,
    "cost_impact_pln": _rc_cost_impact,
    "chain_invariant": _th("v3_p20_remanent_chain_invariant", true),
    "chain_broken": _rc_chain_broken,
    "data_ok": _rc_data_ok,
    "_routing": routing_rc,
    "_routing_reason": reason_rc,
    "_legal_basis": "art. 24a ust. 6-7 PIT (remanent, koszty = Rk − Rp); invariant P04",
    "_warnings": warnings_rc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "remanent_chain"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I03: NKUP BOUNDARY ENGINE (art. 22d/22f + użycie < 1 roku)
# Granica 10 000 zł (niskocenne ŚT) i użycie < 1 roku → koszt bieżący.
# Środek o wartości > 10k i użyciu >= 1 roku księgowany jako koszt = BLOCK
# (musi iść w amortyzację); nieznany okres użycia = TRIAGE.
# ═══════════════════════════════════════════════════════════════════════════════
_nk_item := object.get(_ctx, "item_type", "")
_nk_value := object.get(_ctx, "value_pln", 0.0)
_nk_use_months := object.get(_ctx, "useful_life_months", 0)
_nk_limit := _dep_th("one_off_low_value_limit", 10000.0)
_nk_use_limit := _th("v3_p20_nkup_use_months", 12)
_nk_data_ok = true {
    _nk_value > 0
    _nk_use_months > 0
} else = false

_nk_short_life = true {
    _nk_data_ok
    _nk_use_months < _nk_use_limit
} else = false

_nk_low_value = true {
    _nk_data_ok
    not _nk_short_life
    _nk_value <= _nk_limit
} else = false

_nk_must_depreciate = true {
    _nk_data_ok
    not _nk_short_life
    _nk_value > _nk_limit
} else = false

_nk_booked_as_cost := object.get(_ctx, "booked_as_cost", false)

_nk_wrong_booking = true {
    _nk_must_depreciate
    _nk_booked_as_cost
} else = false

_nk_unknown = true {
    not _nk_data_ok
} else = false

routing_nk = "BLOCK_AND_ALERT" {
    not _nk_data_ok
} else = "BLOCK_AND_ALERT" {
    _nk_wrong_booking
} else = "TRIAGE_QUEUE" {
    _nk_item == ""
} else = "SUGGEST" {
    true
}

reason_nk = sprintf("NKUP: brak danych składnika (wartość %.2f, użycie %d mies.) — fail-closed (BLOCK).", [_nk_value, _nk_use_months]) {
    not _nk_data_ok
} else = sprintf("NKUP: wartość %.2f > limit %.2f i użycie >= %d mies. — składnik MUSI iść w amortyzację, nie w koszty (BLOCK).", [_nk_value, _nk_limit, _nk_use_limit]) {
    _nk_wrong_booking
} else = sprintf("NKUP: wartość %.2f > limit %.2f, użycie >= %d mies. — środek trwały (amortyzacja art. 22a/22d).", [_nk_value, _nk_limit, _nk_use_limit]) {
    _nk_must_depreciate
} else = sprintf("NKUP: wartość %.2f <= limit %.2f, użycie >= %d mies. — jednorazowo w koszty (art. 22d/22f).", [_nk_value, _nk_limit, _nk_use_limit]) {
    _nk_low_value
} else = sprintf("NKUP: użycie %d mies. < %d mies. — koszt bieżący (użycie < 1 roku).", [_nk_use_months, _nk_use_limit]) {
    _nk_short_life
} else = "NKUP: nieznany typ składnika — TRIAGE przed klasyfikacją." {
    true
}

warnings_nk = ["[V3-P20-I03] Środek > 10k zaksięgowany jako koszt — BLOCK (musi iść w amortyzację)."] {
    _nk_wrong_booking
} else = []

nkup_boundary_decision := _certificate(386103, {
    "rule_id": "jdg.v3_p20_ksiegowosc.nkup_boundary_engine",
    "analysis": "nkup_boundary",
    "item_type": _nk_item,
    "value_pln": _nk_value,
    "useful_life_months": _nk_use_months,
    "low_value_limit_pln": _nk_limit,
    "short_life": _nk_short_life,
    "low_value": _nk_low_value,
    "must_depreciate": _nk_must_depreciate,
    "wrong_booking": _nk_wrong_booking,
    "fail_closed": _nk_unknown,
    "_routing": routing_nk,
    "_routing_reason": reason_nk,
    "_legal_basis": "art. 22d ust. 1, art. 22f ust. 3 PIT (niskocenne, jednorazowe); ADR-002",
    "_warnings": warnings_nk,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "nkup_boundary"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I04: ONE-TIME DEPRECIATION SENTINEL (art. 22k ust. 7)
# Monitoring limitu rocznego jednorazowej amortyzacji (100k — reużycie
# depreciation.one_off_annual_limit). Przekroczenie = BLOCK; >= 80% limitu =
# TRIAGE (alarm); auta osobowe poza grupami 3-8 = BLOCK; grupa nieznana = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_od_limit := _dep_th("one_off_annual_limit", 100000.0)
_od_used := object.get(_ctx, "used_this_year_pln", 0.0)
_od_new := object.get(_ctx, "new_asset_value_pln", 0.0)
_od_group := object.get(_ctx, "asset_group", "")
_od_is_car := object.get(_ctx, "is_passenger_car", false)
_od_groups := _th("v3_p20_one_time_groups", ["3", "4", "5", "6", "7", "8"])
_od_alert_pct := _th("v3_p20_one_time_alert_pct", 0.80)

_od_group_ok = true {
    _od_group in _od_groups
} else = false

_od_total := _od_used + _od_new

_od_over = true {
    _od_total > _od_limit
} else = false

_od_near = true {
    not _od_over
    _od_total >= _od_alert_pct * _od_limit
} else = false

_od_car_attempt = true {
    _od_is_car
    not _od_group_ok
} else = false

routing_od = "BLOCK_AND_ALERT" {
    _od_is_car
} else = "BLOCK_AND_ALERT" {
    not _od_group_ok
} else = "BLOCK_AND_ALERT" {
    _od_over
} else = "TRIAGE_QUEUE" {
    _od_near
} else = "SUGGEST" {
    true
}

reason_od = sprintf("Jednorazowa amortyzacja: auta osobowe WYŁĄCZONE (grupy 3-8 minus auta, art. 22k) — BLOCK.", []) {
    _od_is_car
} else = sprintf("Jednorazowa amortyzacja: nieznana grupa KŚT %s (dozwolone %s) — BLOCK.", [_od_group, concat(",", _od_groups)]) {
    not _od_group_ok
} else = sprintf("Jednorazowa amortyzacja: suma %.2f PRZEKRACZA limit roczny %.2f — BLOCK.", [_od_total, _od_limit]) {
    _od_over
} else = sprintf("Jednorazowa amortyzacja: suma %.2f >= 80%% limitu %.2f — alarm przed przekroczeniem (TRIAGE).", [_od_total, _od_limit]) {
    _od_near
} else = sprintf("Jednorazowa amortyzacja: suma %.2f <= limit %.2f (grupa %s) — OK.", [_od_total, _od_limit, _od_group]) {
    true
}

warnings_od = ["[V3-P20-I04] Przekroczenie limitu jednorazowej amortyzacji 100k — BLOCK + plan korekty."] {
    _od_over
} else = ["[V3-P20-I04] Wykorzystanie >= 80% limitu jednorazowej (100k) — zaplanuj zwykłą amortyzację."] {
    _od_near
} else = []

one_time_sentinel_decision := _certificate(386104, {
    "rule_id": "jdg.v3_p20_ksiegowosc.one_time_depreciation_sentinel",
    "analysis": "one_time_depreciation_sentinel",
    "annual_limit_pln": _od_limit,
    "used_this_year_pln": _od_used,
    "new_asset_value_pln": _od_new,
    "total_pln": _od_total,
    "asset_group": _od_group,
    "over_limit": _od_over,
    "near_limit": _od_near,
    "groups_allowed": _od_groups,
    "_routing": routing_od,
    "_routing_reason": reason_od,
    "_legal_basis": "art. 22k ust. 7-12 PIT (jednorazowa, mały podatnik); ADR-002/P06",
    "_warnings": warnings_od,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "one_time_depreciation_sentinel"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I05: KŚT RATES AS DATA (tabele grupy→stawki)
# Stawki KŚT (grupy 0-10) reużywane z depreciation.kst_rates (dane). Grupa
# nieznana / stawka indywidualna > 2× standard / metoda nieznana = BLOCK.
# Degresja: 2,0 dla maszyn (3-6, 8 + transport), 1,4 pozostałe (art. 22k ust. 1-2).
# ═══════════════════════════════════════════════════════════════════════════════
_kt_group := object.get(_ctx, "asset_group", "")
_kt_method := object.get(_ctx, "method", "")
_kt_individual := object.get(_ctx, "individual_rate", 0.0)
_kt_rates := _dep_th("kst_rates", {})

_kt_standard_rate = rate {
    rate := object.get(_kt_rates, _kt_group, -1.0)
} else = -1.0 {
    true
}

_kt_unknown_group = true {
    _kt_standard_rate < 0
} else = false

_kt_max_individual := _dep_th("individual_rate_max_multiplier", 2.0)

_kt_individual_ok = true {
    _kt_individual <= _kt_max_individual * _kt_standard_rate
} else = false

_kt_known_method = true {
    _kt_method in {"LINEARNA", "DEGRESYWNA", "JEDNORAZOWA", "INDYWIDUALNA"}
} else = false

_kt_deg_multiplier = _dep_th("degressive_coeff_machines", 2.0) {
    _kt_group in {"3", "4", "5", "6", "8"}
} else = _dep_th("degressive_coeff_other", 1.4) {
    true
}

routing_kt = "BLOCK_AND_ALERT" {
    _kt_unknown_group
} else = "BLOCK_AND_ALERT" {
    not _kt_known_method
} else = "BLOCK_AND_ALERT" {
    _kt_method == "INDYWIDUALNA"
    not _kt_individual_ok
} else = "SUGGEST" {
    true
}

reason_kt = sprintf("Amortyzacja: nieznana grupa KŚT %s — brak stawki w danych (BLOCK).", [_kt_group]) {
    _kt_unknown_group
} else = sprintf("Amortyzacja: nieznana metoda %s — dozwolone: liniowa/degresywna/jednorazowa/indywidualna (BLOCK).", [_kt_method]) {
    not _kt_known_method
} else = sprintf("Amortyzacja: stawka indywidualna %.4f > %.1f × stawka grupy %.4f — BLOCK (art. 22j/22n).", [_kt_individual, _kt_max_individual, _kt_standard_rate]) {
    _kt_method == "INDYWIDUALNA"
    not _kt_individual_ok
} else = sprintf("Amortyzacja: grupa KŚT %s, stawka %.4f, metoda %s (degresja x%.1f) — OK.", [_kt_group, _kt_standard_rate, _kt_method, _kt_deg_multiplier]) {
    true
}

warnings_kt = ["[V3-P20-I05] Stawka indywidualna ponad 2× standard grupy KŚT — BLOCK (art. 22j/22n)."] {
    _kt_method == "INDYWIDUALNA"
    not _kt_individual_ok
} else = []

kst_rates_decision := _certificate(386105, {
    "rule_id": "jdg.v3_p20_ksiegowosc.kst_rates_as_data",
    "analysis": "kst_rates_as_data",
    "asset_group": _kt_group,
    "method": _kt_method,
    "standard_rate": _kt_standard_rate,
    "deg_multiplier": _kt_deg_multiplier,
    "rate_version": _th("v3_p20_kst_rate_version", "kst-2026.01"),
    "unknown_group": _kt_unknown_group,
    "rates_source": "data.jdg.thresholds.depreciation.kst_rates",
    "fail_closed": _kt_unknown_group,
    "_routing": routing_kt,
    "_routing_reason": reason_kt,
    "_legal_basis": "art. 22j/22n PIT; rozporządzenie MF (stawki KŚT); ADR-002 — stawki z danych",
    "_warnings": warnings_kt,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "kst_rates_as_data"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I06: LEASING SPLIT ENGINE (operacyjny vs finansowy)
# Testy leasingu finansowego (art. 17f: opłaty >= 90% wartości LUB okres >= 75%);
# operacyjny → raty w koszty bieżące (opłata wstępna rozłożona 12M — dane);
# finansowy → amortyzacja + odsetki. Limit aut 150k (art. 23 ust. 1 pkt 47a):
# wartość > 150k bez ujęcia limitu = BLOCK; nieznane dane umowy = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_ls_type := object.get(_ctx, "lease_type", "")
_ls_total := object.get(_ctx, "total_pln", 0.0)
_ls_initial := object.get(_ctx, "initial_fee_pln", 0.0)
_ls_monthly := object.get(_ctx, "monthly_pln", 0.0)
_ls_months := object.get(_ctx, "months", 0)
_ls_car := object.get(_ctx, "car_related", false)
_ls_car_value := object.get(_ctx, "car_value_pln", 0.0)
_ls_value_test := _th("leasing_value_test_pct", 0.90)
_ls_period_test := _th("leasing_period_test_pct", 0.75)
_ls_car_limit := _dep_th("passenger_car_limit_standard", 150000.0)
_ls_spread_months := _th("v3_p20_leasing_op_initial_months", 12)

_ls_known_type = true {
    _ls_type in {"OPERACYJNY", "FINANSOWY"}
} else = false

_ls_data_ok = true {
    _ls_total > 0
    _ls_months > 0
} else = false

_ls_op_total := _ls_initial + _ls_monthly * _ls_months

_ls_financial_by_value = true {
    _ls_op_total >= _ls_value_test * _ls_total
} else = false

_ls_financial_by_period = true {
    _ls_months >= _ls_period_test * 120
} else = false

_ls_classified = "FINANSOWY" {
    _ls_financial_by_value
} else = "FINANSOWY" {
    _ls_financial_by_period
} else = "OPERACYJNY" {
    true
}

_ls_car_over_limit = true {
    _ls_car
    _ls_car_value > _ls_car_limit
} else = false

_ls_car_limit_applied := object.get(_ctx, "car_limit_applied", false)

_ls_car_missing_limit = true {
    _ls_car_over_limit
    not _ls_car_limit_applied
} else = false

routing_ls = "BLOCK_AND_ALERT" {
    not _ls_data_ok
} else = "BLOCK_AND_ALERT" {
    not _ls_known_type
} else = "BLOCK_AND_ALERT" {
    _ls_car_missing_limit
} else = "TRIAGE_QUEUE" {
    _ls_car_over_limit
    _ls_car_limit_applied
} else = "SUGGEST" {
    true
}

reason_ls = "Leasing: brak danych umowy (wartość/okres) — fail-closed (BLOCK)." {
    not _ls_data_ok
} else = sprintf("Leasing: nieznany typ %s (dozwolone OPERACYJNY/FINANSOWY) — BLOCK.", [_ls_type]) {
    not _ls_known_type
} else = sprintf("Leasing auta: wartość %.2f > limit %.2f bez ujęcia limitu (art. 23 ust. 1 pkt 47a) — BLOCK.", [_ls_car_value, _ls_car_limit]) {
    _ls_car_missing_limit
} else = sprintf("Leasing auta: wartość %.2f > limit %.2f z ujęciem limitu — nadwyżka NKUP (TRIAGE).", [_ls_car_value, _ls_car_limit]) {
    _ls_car_over_limit
    _ls_car_limit_applied
} else = sprintf("Leasing %s: suma opłat %.2f/%.2f (%.0f%%), okres %d mies. — klasyfikacja %s (opłata wstępna rozłożona %d mies.).",
    [_ls_type, _ls_op_total, _ls_total, _ls_op_total / _ls_total * 100, _ls_months, _ls_classified, _ls_spread_months]) {
    true
}

warnings_ls = ["[V3-P20-I06] Leasing auta ponad limit 150k bez ujęcia limitu — BLOCK (art. 23 ust. 1 pkt 47a)."] {
    _ls_car_missing_limit
} else = []

leasing_split_decision := _certificate(386106, {
    "rule_id": "jdg.v3_p20_ksiegowosc.leasing_split_engine",
    "analysis": "leasing_split",
    "declared_type": _ls_type,
    "classified": _ls_classified,
    "total_pln": _ls_total,
    "op_fees_total_pln": _ls_op_total,
    "months": _ls_months,
    "financial_value_test": _ls_financial_by_value,
    "financial_period_test": _ls_financial_by_period,
    "car_over_limit": _ls_car_over_limit,
    "car_limit_pln": _ls_car_limit,
    "initial_spread_months": _ls_spread_months,
    "_routing": routing_ls,
    "_routing_reason": reason_ls,
    "_legal_basis": "art. 17f PIT (testy finansowego); art. 23 ust. 1 pkt 47a PIT (limit 150k); ADR-002",
    "_warnings": warnings_ls,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "leasing_split"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I07: PKPiR→UoR TRANSITION (przekroczenie progu 2M EUR)
# Próg pełnej księgowości (reużycie accounting.uor_threshold_eur / ksiegowosc).
# Przekroczenie w roku = obowiązek ksiąg od następnego; przejście w trakcie
# roku = procedura (remanent + zamknięcie) — brak planu = BLOCK; >= 75% progu =
# TRIAGE (wczesne ostrzeżenie); poniżej = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_tr_revenue_eur := object.get(_ctx, "revenue_eur", 0.0)
_tr_prev_revenue_eur := object.get(_ctx, "prev_year_revenue_eur", 0.0)
_tr_threshold := _acct_th("uor_threshold_eur", 2000000.0)
_tr_early_pct := _acct_th("early_warning_pct", 0.75)
_tr_plan := object.get(_ctx, "transition_plan_ready", false)
_tr_midyear := object.get(_ctx, "midyear_crossing", false)
_tr_procedure := _th("v3_p20_uor_transition_procedure", "REMANENT_PLUS_CLOSING")

_tr_crossed = true {
    _tr_revenue_eur > _tr_threshold
} else = true {
    _tr_prev_revenue_eur > _tr_threshold
} else = false

_tr_near = true {
    not _tr_crossed
    _tr_revenue_eur >= _tr_early_pct * _tr_threshold
} else = false

_tr_books := _tr_crossed

_tr_missing_plan = true {
    _tr_crossed
    not _tr_plan
} else = false

routing_tr = "BLOCK_AND_ALERT" {
    _tr_missing_plan
} else = "TRIAGE_QUEUE" {
    _tr_midyear
    _tr_crossed
} else = "TRIAGE_QUEUE" {
    _tr_near
} else = "SUGGEST" {
    true
}

reason_tr = sprintf("UoR: przychody %.2f EUR > próg %.2f EUR i BRAK planu przejścia — BLOCK (księgi od następnego roku).", [_tr_revenue_eur, _tr_threshold]) {
    _tr_missing_plan
} else = sprintf("UoR: przekroczenie progu w TRAKCIE roku — procedura przejścia %s (TRIAGE + audyt).", [_tr_procedure]) {
    _tr_midyear
    _tr_crossed
} else = sprintf("UoR: przychody %.2f EUR >= 75%% progu %.2f EUR — wczesne ostrzeżenie (TRIAGE).", [_tr_revenue_eur, _tr_threshold]) {
    _tr_near
} else = sprintf("UoR: przychody %.2f EUR <= próg %.2f EUR — PKPiR wystarczające (SUGGEST).", [_tr_revenue_eur, _tr_threshold]) {
    true
}

warnings_tr = ["[V3-P20-I07] Przekroczenie progu UoR bez planu przejścia — BLOCK (księgi obowiązkowe)."] {
    _tr_missing_plan
} else = ["[V3-P20-I07] Przekroczenie progu UoR w trakcie roku — procedura remanent + zamknięcie."] {
    _tr_midyear
    _tr_crossed
} else = []

transition_decision := _certificate(386107, {
    "rule_id": "jdg.v3_p20_ksiegowosc.pkpir_to_uor_transition",
    "analysis": "pkpir_to_uor_transition",
    "revenue_eur": _tr_revenue_eur,
    "threshold_eur": _tr_threshold,
    "crossed": _tr_crossed,
    "near_threshold": _tr_near,
    "books_required": _tr_books,
    "transition_plan_ready": _tr_plan,
    "procedure": _tr_procedure,
    "threshold_source": "data.jdg.thresholds.accounting.uor_threshold_eur",
    "_routing": routing_tr,
    "_routing_reason": reason_tr,
    "_legal_basis": "art. 2 ust. 1 pkt 5 UoR; art. 9a CIT (kontekst progu); ADR-002",
    "_warnings": warnings_tr,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "pkpir_to_uor_transition"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I08: YEAR-END CLOSING CHAIN (zamknięcie roku end-to-end)
# Łańcuch: PKPiR remanent → amortyzacje → PIT (P14) → JPK (P16) → zamknięcie.
# Brak któregokolwiek ogniwa = BLOCK (łańcuch niekompletny); rozjazd kwot
# PKPiR↔PIT↔JPK = BLOCK; wszystkie ogniwa = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_cc_year := object.get(_ctx, "year", 0)
_cc_remanent := object.get(_ctx, "remanent_done", false)
_cc_depreciation := object.get(_ctx, "depreciation_done", false)
_cc_pit := object.get(_ctx, "pit_prepared", false)
_cc_jpk := object.get(_ctx, "jpk_prepared", false)
_cc_revenue := object.get(_ctx, "revenue_pln", 0.0)
_cc_pit_revenue := object.get(_ctx, "pit_revenue_pln", 0.0)
_cc_jpk_revenue := object.get(_ctx, "jpk_revenue_pln", 0.0)
_cc_grosz := 0.01

_cc_stage_missing = true {
    not _cc_remanent
} else = true {
    not _cc_depreciation
} else = true {
    not _cc_pit
} else = true {
    not _cc_jpk
} else = false

_cc_revenue_drift = true {
    _cc_revenue > 0
    _abs(_cc_revenue - _cc_pit_revenue) > _cc_grosz
} else = true {
    _cc_revenue > 0
    _abs(_cc_revenue - _cc_jpk_revenue) > _cc_grosz
} else = false

_cc_complete = true {
    not _cc_stage_missing
    not _cc_revenue_drift
} else = false

routing_cc = "BLOCK_AND_ALERT" {
    _cc_stage_missing
} else = "BLOCK_AND_ALERT" {
    _cc_revenue_drift
} else = "SUGGEST" {
    true
}

reason_cc = sprintf("Zamknięcie roku %d: brak ogniwa łańcucha (remanent=%t, amortyzacja=%t, PIT=%t, JPK=%t) — BLOCK.", [_cc_year, _cc_remanent, _cc_depreciation, _cc_pit, _cc_jpk]) {
    _cc_stage_missing
} else = sprintf("Zamknięcie roku %d: rozjazd przychodów PKPiR (%.2f) vs PIT (%.2f) / JPK (%.2f) — BLOCK (kontrakt P14/P16).", [_cc_year, _cc_revenue, _cc_pit_revenue, _cc_jpk_revenue]) {
    _cc_revenue_drift
} else = sprintf("Zamknięcie roku %d: łańcuch kompletny (remanent → amortyzacja → PIT → JPK) — zamknięcie OK.", [_cc_year]) {
    true
}

warnings_cc = ["[V3-P20-I08] Łańcuch zamknięcia roku niekompletny — BLOCK przed zamknięciem ksiąg."] {
    _cc_stage_missing
} else = ["[V3-P20-I08] Rozjazd kwot PKPiR↔PIT↔JPK — naruszenie invariantu (kontrakt P14/P16)."] {
    _cc_revenue_drift
} else = []

closing_chain_decision := _certificate(386108, {
    "rule_id": "jdg.v3_p20_ksiegowosc.year_end_closing_chain",
    "analysis": "year_end_closing_chain",
    "year": _cc_year,
    "remanent_done": _cc_remanent,
    "depreciation_done": _cc_depreciation,
    "pit_prepared": _cc_pit,
    "jpk_prepared": _cc_jpk,
    "stage_missing": _cc_stage_missing,
    "revenue_drift": _cc_revenue_drift,
    "chain_complete": _cc_complete,
    "pit_due": _th("v3_p20_closing_pit_due", "04-30"),
    "_routing": routing_cc,
    "_routing_reason": reason_cc,
    "_legal_basis": "art. 24a PIT (PKPiR); P14/P16 kontrakty (PIT/JPK); invariant P04",
    "_warnings": warnings_cc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "year_end_closing_chain"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I09: DOUBLE-ENTRY CONSISTENCY GATE (UoR — bilans zbalansowany)
# Property gate: suma debetów == suma kredytów (tolerancja groszowa 0,01).
# Rozjazd > 0,01 = BLOCK; brak sum = BLOCK (fail-closed); zgodny = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_de_debits := object.get(_ctx, "debits_sum_pln", null)
_de_credits := object.get(_ctx, "credits_sum_pln", null)
_de_grosz := 0.01

_de_present = true {
    _de_debits != null
    _de_credits != null
} else = false

_de_absent = true {
    not _de_present
} else = false

_de_balanced = true {
    _de_present
    _abs(_de_debits - _de_credits) <= _de_grosz
} else = false

routing_de = "BLOCK_AND_ALERT" {
    not _de_present
} else = "BLOCK_AND_ALERT" {
    not _de_balanced
} else = "SUGGEST" {
    true
}

reason_de = "UoR: brak sum debetów/kredytów — fail-closed (BLOCK)." {
    not _de_present
} else = sprintf("UoR: bilans NIEZbalansowany — debety %.2f vs kredyty %.2f (rozjazd > 0,01) — BLOCK.", [_de_debits, _de_credits]) {
    not _de_balanced
} else = sprintf("UoR: debety %.2f == kredyty %.2f — podwójny zapis spójny (gate aktywny).", [_de_debits, _de_credits]) {
    true
}

warnings_de = ["[V3-P20-I09] Bilans niezbalansowany (rozjazd > 0,01 zł) — BLOCK księgowania (property gate)."] {
    _de_present
    not _de_balanced
} else = []

double_entry_decision := _certificate(386109, {
    "rule_id": "jdg.v3_p20_ksiegowosc.double_entry_consistency_gate",
    "analysis": "double_entry_consistency_gate",
    "debits_sum_pln": _de_debits,
    "credits_sum_pln": _de_credits,
    "tolerance_pln": _de_grosz,
    "balanced": _de_balanced,
    "gate_active": _th("v3_p20_double_entry_invariant", true),
    "fail_closed": _de_absent,
    "_routing": routing_de,
    "_routing_reason": reason_de,
    "_legal_basis": "art. 15/16 UoR (księgi, podwójny zapis); invariant P04",
    "_warnings": warnings_de,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "double_entry_consistency_gate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I10: BOOKKEEPING GOLDEN SET (oracle ewidencji)
# Golden ewidencje (remanent, amortyzacja, NKUP, leasing) w oracle — rozjazd
# z golden = BLOCK; przypadek graniczny (grosze, granice 10k/100k/150k) =
# TRIAGE; zgodny = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_gs_case := object.get(_ctx, "case_id", "")
_gs_in_golden := object.get(_ctx, "in_golden_set", false)
_gs_match := object.get(_ctx, "golden_match", true)
_gs_boundary := object.get(_ctx, "boundary_case", false)
_gs_domain := object.get(_ctx, "domain", "")

_gs_drift = true {
    _gs_in_golden
    not _gs_match
} else = false

_gs_known_domain = true {
    _gs_domain in {"REMANENT", "AMORTYZACJA", "NKUP", "LEASING", "PKPIR"}
} else = false

routing_gs = "BLOCK_AND_ALERT" {
    _gs_drift
} else = "TRIAGE_QUEUE" {
    _gs_boundary
} else = "SUGGEST" {
    true
}

reason_gs = sprintf("Golden set (%s): rozjazd decyzji z golden (case %s) — BLOCK.", [_gs_domain, _gs_case]) {
    _gs_drift
} else = sprintf("Golden set (%s): przypadek graniczny (case %s) — TRIAGE (granice 10k/100k/150k/grosze).", [_gs_domain, _gs_case]) {
    _gs_boundary
} else = sprintf("Golden set (%s): decyzja zgodna z golden (case %s) — SUGGEST.", [_gs_domain, _gs_case]) {
    true
}

warnings_gs = ["[V3-P20-I10] Rozjazd z golden set księgowości — BLOCK + inspekcja reguły."] {
    _gs_drift
} else = ["[V3-P20-I10] Przypadek graniczny golden (grosze/10k/100k/150k) — TRIAGE do człowieka."] {
    _gs_boundary
} else = []

golden_set_decision := _certificate(386110, {
    "rule_id": "jdg.v3_p20_ksiegowosc.bookkeeping_golden_set",
    "analysis": "golden_set",
    "case_id": _gs_case,
    "domain": _gs_domain,
    "in_golden_set": _gs_in_golden,
    "golden_match": _gs_match,
    "boundary_case": _gs_boundary,
    "drift": _gs_drift,
    "golden_version": _th("v3_p20_golden_version", "ksiegowosc-golden-2026.09"),
    "_routing": routing_gs,
    "_routing_reason": reason_gs,
    "_legal_basis": "oracle golden — ADR-002; granice 10k/100k/150k i grosze z danych",
    "_warnings": warnings_gs,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_set"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I11: BOOKKEEPING INVARIANTS PACK (kontrakt P04)
# Invarianty księgowości: PKPiR=PIT (P14), PKPiR=JPK (P16), bilans zbalansowany
# (I09), grosze (zaokrąglenia > 0,01). Naruszenie któregokolwiek = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_iv_pkpir_pit := object.get(_ctx, "pkpir_pit_mismatch", false)
_iv_pkpir_jpk := object.get(_ctx, "pkpir_jpk_mismatch", false)
_iv_books := object.get(_ctx, "unbalanced_books", false)
_iv_rounding := object.get(_ctx, "rounding_error_gt_grosz", false)

_iv_violation = true {
    _iv_pkpir_pit
} else = true {
    _iv_pkpir_jpk
} else = true {
    _iv_books
} else = true {
    _iv_rounding
} else = false

_iv_kbk_inv_001 = true {
    not _iv_pkpir_pit
    not _iv_pkpir_jpk
} else = false

_iv_kbk_inv_002 = true {
    not _iv_books
} else = false

_iv_kbk_inv_003 = true {
    not _iv_rounding
} else = false

routing_iv = "BLOCK_AND_ALERT" {
    _iv_violation
} else = "SUGGEST" {
    true
}

reason_iv = "Invarianty księgowości: naruszenie KBK_INV-001/002/003 — BLOCK (kontrakt P04)." {
    _iv_violation
} else = "Invarianty księgowości: PKPiR=PIT (P14), PKPiR=JPK (P16), bilans zbalansowany, grosze — OK." {
    true
}

warnings_iv = ["[V3-P20-I11] Naruszenie invariantu księgowości — BLOCK + eskalacja (nigdy cichy AUTO_POST)."] {
    _iv_violation
} else = []

invariants_decision := _certificate(386111, {
    "rule_id": "jdg.v3_p20_ksiegowosc.bookkeeping_invariants_pack",
    "analysis": "invariants_pack",
    "pkpir_pit_mismatch": _iv_pkpir_pit,
    "pkpir_jpk_mismatch": _iv_pkpir_jpk,
    "unbalanced_books": _iv_books,
    "rounding_error_gt_grosz": _iv_rounding,
    "inv_kbk_001": _iv_kbk_inv_001,
    "inv_kbk_002": _iv_kbk_inv_002,
    "inv_kbk_003": _iv_kbk_inv_003,
    "violation": _iv_violation,
    "pack_active": _th("v3_p20_invariants_active", true),
    "_routing": routing_iv,
    "_routing_reason": reason_iv,
    "_legal_basis": "kontrakt P04 (invarianty); P14/P16 (PKPiR=PIT=JPK); art. 24a PIT",
    "_warnings": warnings_iv,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "invariants_pack"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I12: DOCUMENT CHECKLIST GENERATOR (dowody księgowe)
# Checklisty dowodów per typ ewidencji (PKPiR/UoR/amortyzacja/leasing).
# Nieznany typ / brak podstawy / niekomplet checklisty = BLOCK (zero
# niekompletnych dowodów); komplet = SUGGEST (PDF do archiwum).
# ═══════════════════════════════════════════════════════════════════════════════
_dc_type := object.get(_ctx, "doc_type", "")
_dc_basis := object.get(_ctx, "legal_basis_present", false)
_dc_complete := object.get(_ctx, "checklist_complete", false)

_dc_known = true {
    _dc_type in {"PKPIR", "UOR", "AMORTYZACJA", "LEASING"}
} else = false

_dc_ok = true {
    _dc_known
    _dc_basis
    _dc_complete
} else = false

_dc_unknown = true {
    not _dc_known
} else = false

routing_dc = "BLOCK_AND_ALERT" {
    not _dc_known
} else = "BLOCK_AND_ALERT" {
    not _dc_basis
} else = "BLOCK_AND_ALERT" {
    not _dc_complete
} else = "SUGGEST" {
    true
}

reason_dc = sprintf("Checklista dowodów: nieznany typ %s (dozwolone PKPIR/UOR/AMORTYZACJA/LEASING) — BLOCK.", [_dc_type]) {
    not _dc_known
} else = sprintf("Checklista dowodów (%s): brak podstawy prawnej dowodu — BLOCK.", [_dc_type]) {
    not _dc_basis
} else = sprintf("Checklista dowodów (%s): dokumentacja NIECOMPLETNA — BLOCK (zero niekompletnych dowodów).", [_dc_type]) {
    not _dc_complete
} else = sprintf("Checklista dowodów (%s): komplet — pakiet do archiwum (PDF, wersja %s).", [_dc_type, _th("v3_p20_checklist_version", "dowody-ksiegowe-2026.01")]) {
    true
}

warnings_dc = ["[V3-P20-I12] Niekompletna dokumentacja dowodowa — BLOCK przed księgowaniem/archiwizacją."] {
    not _dc_complete
} else = []

checklist_decision := _certificate(386112, {
    "rule_id": "jdg.v3_p20_ksiegowosc.doc_checklist_generator",
    "analysis": "doc_checklist",
    "doc_type": _dc_type,
    "legal_basis_present": _dc_basis,
    "checklist_complete": _dc_complete,
    "ok": _dc_ok,
    "checklist_version": _th("v3_p20_checklist_version", "dowody-ksiegowe-2026.01"),
    "fail_closed": _dc_unknown,
    "_routing": routing_dc,
    "_routing_reason": reason_dc,
    "_legal_basis": "art. 24a ust. 1 PIT (dowody PKPiR); art. 74 UoR (retencja); kontrakt księgowej",
    "_warnings": warnings_dc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "doc_checklist"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := pkpir_schema_decision {
    pkpir_schema_decision.rule_id != ""
} else := remanent_chain_decision {
    remanent_chain_decision.rule_id != ""
} else := nkup_boundary_decision {
    nkup_boundary_decision.rule_id != ""
} else := one_time_sentinel_decision {
    one_time_sentinel_decision.rule_id != ""
} else := kst_rates_decision {
    kst_rates_decision.rule_id != ""
} else := leasing_split_decision {
    leasing_split_decision.rule_id != ""
} else := transition_decision {
    transition_decision.rule_id != ""
} else := closing_chain_decision {
    closing_chain_decision.rule_id != ""
} else := double_entry_decision {
    double_entry_decision.rule_id != ""
} else := golden_set_decision {
    golden_set_decision.rule_id != ""
} else := invariants_decision {
    invariants_decision.rule_id != ""
} else := checklist_decision {
    checklist_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p20_ksiegowosc.no_match",
    "package": "jdg.v3_p20_ksiegowosc",
    "priority": 999999,
}
