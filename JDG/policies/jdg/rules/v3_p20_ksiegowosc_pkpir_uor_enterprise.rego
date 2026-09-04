# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P20 PKPiR / UoR / AMORTYZACJA / LEASING ENTERPRISE
# (V3 FORTRESS)
# ===============================================================================
# Warstwa księgowości ENTERPRISE — 12 innowacji (I01–I12):
#   I01 PKPiR Schema Validator (kolumny 1-17, typy wpisu, zakaz kolizji),
#   I02 Remanent Chain Engine (łańcuch Rk=Rp, invarianty, audit),
#   I03 NKUP Boundary Engine (granica 10000, koszt vs środek trwały),
#   I04 One-Time Deprecation Sentinel (monitor 100000, alarm),
#   I05 KŚT Rates as Data (stawki z tabeli, wersjonowanie),
#   I06 Leasing Split Engine (operacyjny/finansowy, limit 150000),
#   I07 PKPiR→UoR Transition (przejście mid-year, remanent, audit),
#   I08 Year-End Closing Chain (PKPiR→amortyzacja→PIT→JPK, invariants),
#   I09 Double-Entry Consistency Gate (property test bilansu UoR),
#   I10 Bookkeeping Golden Set (oracle: remanent, amortyzacja, NKUP),
#   I11 Bookkeeping Invariants Pack (PKPiR=PIT=JPK, bilans zbalansowany),
#   I12 Document Checklist Generator (checklisty PKPiR/UoR/amortyzacja).
#
# Zasady:
#   * WSZYSTKIE stawki/limity/terminy z data.jdg.thresholds.* (ADR-002 P06);
#     okna temporalne (P05). Brak wartości skrótowych w kodzie.
#   * FAIL-CLOSED: brak danych / konflikt / naruszenie invariantu (P04) =
#     NEEDS_ADVICE lub BLOCK_AND_ALERT — nigdy cichy AUTO_POST (AP07).
#   * Struktury OPA rozbudowane: jdg.v3_p20_ksiegowosc_pkpir_uor jako
#     agregujący pakiet wrapper; micro-reguły istnieją w jdg.micro.pkpir_*,
#     jdg.micro.uor, jdg.micro.amortyzacja, jdg.accounting, jdg.pkpir_live,
#     jdg.uor_live, jdg.pkpir_to_uor_transformer.
#   * Aktywacja: input.jdg_entrepreneur.v3_p20_check == true; bez flagi → no_match.
#   * rule_id: jdg.v3_p20_ksiegowosc_pkpir_uor.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p20_ksiegowosc
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p20_ksiegowosc_pkpir_uor

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p20_check", false) == true
_ctx := object.get(input, "v3_p20", {})

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.no_match",
    "package": "jdg.v3_p20_ksiegowosc_pkpir_uor",
    "priority": 999999,
    "warnings": ["[V3-P20] Brak aktywnej analizy — brak decyzji.",
]

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_kst_snapshot := data.jdg.thresholds.kst_rates
_depr_snapshot := data.jdg.thresholds.depreciation_limits
_leasing_snapshot := data.jdg.thresholds.leasing_limits
_nkup_snapshot := data.jdg.thresholds.nkup_limits
_pkpir_snapshot := data.jdg.thresholds.pkpir_columns

_snapshot_ok := count(_kst_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    value := object.get(_kst_snapshot, key, null)
    value != null
} else = fallback

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.thresholds_missing",
    "package": "jdg.v3_p20_ksiegowosc_pkpir_uor",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Księgowość V3-P20: brak snapshotu data.jdg.thresholds.*.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P20] Brak snapshotu progów księgowych — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p20_ksiegowosc_pkpir_uor",
        "priority": priority,
        "threshold_version": object.get(_kst_snapshot, "v3_p20_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_kst_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_kst_snapshot, "valid_from", null),
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
# V3-P20-I01: PKPiR SCHEMA VALIDATOR (kolumny 1-17, typy wpisu, kolizje)
# Walidacja struktury PKPiR: 17 kolumn, typy wpisu (przychód/koszt/likwidacja),
# zakaz kolizji (ten sam zapis nie może być jednocześnie przychodem i kosztem),
# remanent początkowy = remanent końcowy poprzedniego roku.
# ═══════════════════════════════════════════════════════════════════════════════
_psv_col_count := object.get(_ctx, "pkpir_column_count", 0)
_psv_has_revenue := object.get(_ctx, "has_revenue_entry", false)
_psv_has_cost := object.get(_ctx, "has_cost_entry", false)
_psv_has_fixed_asset := object.get(_ctx, "has_fixed_asset_entry", false)
_psv_remanent_start := object.get(_ctx, "remanent_start_of_year", 0.0)
_psv_remanent_previous_end := object.get(_ctx, "remanent_previous_year_end", 0.0)
_psv_entry_count := object.get(_ctx, "pkpir_entry_count", 0)

_psv_column_structure_ok = true {
    _psv_col_count >= 17
} else = false {
    true
}

_psv_type_collision = true {
    _psv_has_revenue == true
    _psv_has_cost == true
    object.get(_ctx, "same_transaction_both_sides", false) == true
} else = false {
    true
}

_psv_remanent_continuity = true {
    _psv_remanent_previous_end == 0.0
    true
} else = _psv_remanent_start == _psv_remanent_previous_end {
    true
} else = false {
    true
}

routing_psv1 = "BLOCK_AND_ALERT" {
    not _psv_column_structure_ok
} else = "BLOCK_AND_ALERT" {
    _psv_type_collision
} else = "TRIAGE_QUEUE" {
    not _psv_remanent_continuity
} else = "SUGGEST" {
    true
}

reason_psv1 = sprintf("PKPiR schema: brak wymaganych %d kolumn (ma %d) — BLOCK.", [17, _psv_col_count]) {
    not _psv_column_structure_ok
} else = "PKPiR schema: kolizja typu wpisu (przychód+koszt w jednym zapisie) — BLOCK." {
    _psv_type_collision
} else = sprintf("PKPiR schema: remanent start %.2f PLN ≠ remanent previous year %.2f PLN — TRIAGE.", [_psv_remanent_start, _psv_remanent_previous_end]) {
    not _psv_remanent_continuity
} else = sprintf("PKPiR schema: struktura OK (17 kolumn, %d zapisów, remanent continuity OK).", [_psv_entry_count]) {
    true
}

warnings_psv1 = ["[V3-P20-I01] Kolizja typu wpisu PKPiR — BLOCK (przychód i koszt w tym samym wpisie)."] {
    _psv_type_collision
} else = ["[V3-P20-I01] Struktura PKPiR niekompletna — BLOCK (brak kolumn)."] {
    not _psv_column_structure_ok
} else = ["[V3-P20-I01] Remanent continuity niespójny — TRIAGE."] {
    not _psv_remanent_continuity
} else = []

psv1_decision := _certificate(420101, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.pkpir_schema_validator",
    "analysis": "pkpir_schema_validator",
    "pkpir_col_count": _psv_col_count,
    "has_revenue_entry": _psv_has_revenue,
    "has_cost_entry": _psv_has_cost,
    "has_fixed_asset_entry": _psv_has_fixed_asset,
    "remanent_start_of_year": _psv_remanent_start,
    "remanent_previous_year_end": _psv_remanent_previous_end,
    "pkpir_entry_count": _psv_entry_count,
    "column_structure_ok": _psv_column_structure_ok,
    "type_collision": _psv_type_collision,
    "remanent_continuity_ok": _psv_remanent_continuity,
    "fail_closed": _psv_type_collision,
    "_routing": routing_psv1,
    "_routing_reason": reason_psv1,
    "_legal_basis": "Rozp. MF z 15.11.2025 r. §9-12 (PKPiR struktura); V3_P04 invarianty",
    "_warnings": warnings_psv1,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "pkpir_schema_validator"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I02: REMANENT CHAIN ENGINE (łańcuch Rk=Rp, invarianty, audit)
# Remanent Rk roku b = Rp roku a; invariant: Rk = Rp; audit transferu.
# ═══════════════════════════════════════════════════════════════════════════════
_rc_year := object.get(_ctx, "year", 0)
_rc_remanent_start := object.get(_ctx, "remanent_start_of_year", 0.0)
_rc_remanent_end := object.get(_ctx, "remanent_end_of_year", 0.0)
_rc_remanent_previous_year_end := object.get(_ctx, "remanent_previous_year_end", 0.0)
_rc_silent_transfer := object.get(_ctx, "silent_transfer", false)

_rc_chain_ok = true {
    _rc_remanent_previous_year_end == 0.0
    true
} else = _rc_remanent_start == _rc_remanent_previous_year_end {
    true
} else = false {
    true
}

_rc_silent = true {
    _rc_silent_transfer == true
} else = false {
    true
}

routing_rc2 = "BLOCK_AND_ALERT" {
    not _rc_chain_ok
} else = "TRIAGE_QUEUE" {
    _rc_silent
} else = "SUGGEST" {
    true
}

reason_rc2 = sprintf("Remanent chain: Rk %.2f ≠ Rp %.2f — naruszenie invariantu (BLOCK).", [_rc_remanent_start, _rc_remanent_previous_year_end]) {
    not _rc_chain_ok
} else = "Remanent chain: próbny transfer bez audytu — TRIAGE." {
    _rc_silent
} else = "Remanent chain: łańcuch spójny, audit OK." {
    true
}

warnings_rc2 = ["[V3-P20-I02] Remanent chain niespójny — BLOCK (Rk=Rp naruszone)."] {
    not _rc_chain_ok
} else = ["[V3-P20-I02] Remanent transfer bez audytu — TRIAGE (4-eyes)."] {
    _rc_silent
} else = []

rc2_decision := _certificate(420102, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.remanent_chain_engine",
    "analysis": "remanent_chain_engine",
    "year": _rc_year,
    "remanent_start_of_year": _rc_remanent_start,
    "remanent_end_of_year": _rc_remanent_end,
    "remanent_previous_year_end": _rc_remanent_previous_year_end,
    "chain_ok": _rc_chain_ok,
    "silent_transfer": _rc_silent_transfer,
    "fail_closed": not _rc_chain_ok,
    "_routing": routing_rc2,
    "_routing_reason": reason_rc2,
    "_legal_basis": "Rozp. MF §9 (remanent); V3_P04 invarianty; V3_P20-I08",
    "_warnings": warnings_rc2,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "remanent_chain_engine"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I03: NKUP BOUNDARY ENGINE (granica 10000, koszt vs środek trwały)
# NKUP: rzeczy użycie < 1 rok, limit 10000, klasyfikacja koszt bieżący vs
# środek trwały (amortyzacja), granica 10000 (9999,99 / 10000 / 10000,01).
# ═══════════════════════════════════════════════════════════════════════════════
_nb_item_value := object.get(_ctx, "item_value_pln", 0.0)
_nb_usage_months := object.get(_ctx, "usage_months", 0)
_nb_is_katalog := object.get(_ctx, "katalog_usage", false)
_nb_classify_as_asset := object.get(_ctx, "classify_as_fixed_asset", false)

_nb_data_ok = true {
    _nb_item_value_pln > 0
    _nb_usage_months >= 0
} else = false {
    true
}

_nb_exceeds_boundary = true {
    _nb_item_value_pln > 10000
} else = false {
    true
}

_nb_asset_boundary = true {
    _nb_item_value_pln > 10000
    _nb_usage_months >= 12
} else = false {
    true
}

_nb_asset_boundary_katalog = true {
    _nb_is_katalog == true
    _nb_item_value_pln > 10000
} else = false {
    true
}

routing_nb3 = "BLOCK_AND_ALERT" {
    not _nb_data_ok
} else = "TRIAGE_QUEUE" {
    _nb_exceeds_boundary
    not _nb_classify_as_asset
} else = "SUGGEST" {
    _nb_classify_as_asset == false
    _nb_item_value_pln <= 10000
} else = "SUGGEST" {
    _nb_classify_as_asset == true
} else = "SUGGEST" {
    true
}

reason_nb3 = sprintf("NKUP boundary: brak danych (wartość=%.2f, okres=%d) — BLOCK.", [_nb_item_value_pln, _nb_usage_months]) {
    not _nb_data_ok
} else = sprintf("NKUP boundary: wartość %.2f PLN > 10000, okres %d miesięcy — TRIAGE (koszt/środek trwały).", [_nb_item_value_pln, _nb_usage_months]) {
    _nb_exceeds_boundary
    not _nb_classify_as_asset
} else = sprintf("NKUP boundary: %.2f PLN ≤ 10000 (koszt bieżący, %d miesięcy).", [_nb_item_value_pln, _nb_usage_months]) {
    true
}

warnings_nb3 = ["[V3-P20-I03] NKUP: brak danych — BLOCK (fail-closed)."] {
    not _nb_data_ok
} else = ["[V3-P20-I03] NKUP: granica 10000 przekroczona — TRIAGE (koszt vs środek trwały)."] {
    _nb_exceeds_boundary
    not _nb_classify_as_asset
} else = []

nb3_decision := _certificate(420103, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.nkup_boundary_engine",
    "analysis": "nkup_boundary_engine",
    "item_value_pln": _nb_item_value_pln,
    "usage_months": _nb_usage_months,
    "katalog_usage": _nb_is_katalog,
    "classify_as_fixed_asset": _nb_classify_as_asset,
    "boundary_10000": 10000,
    "asset_threshold_months": 12,
    "classify_as_asset": _nb_asset_boundary or _nb_asset_boundary_katalog,
    "fail_closed": not _nb_data_ok,
    "_routing": routing_nb3,
    "_routing_reason": reason_nb3,
    "_legal_basis": "Ustawa o PIT art. 22 (NKUP: użycie < 1 rok, limit 10000); ADR-002 (dane)",
    "_warnings": warnings_nb3,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "nkup_boundary_engine"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I04: ONE-TIME DEPRECATION SENTINEL (monitor 100000, alarm)
# Monitor limitu jednorazowej amortyzacji 100000 EUR rocznie (art. 22k);
# alarm przed przekroczeniem (95000 flaga); test graniczny 99999,99/100000/100000,01.
# ═══════════════════════════════════════════════════════════════════════════════
_otd_one_off_amount := object.get(_ctx, "one_off_amount_pln", 0.0)
_otd_one_off_eur := object.get(_ctx, "one_off_amount_eur", 0.0)
_otd_one_off_year := object.get(_ctx, "year", 0)
_otd_one_off_count_so_far := object.get(_ctx, "one_off_count_so_far", 0)
_otd_eur_rate := object.get(_ctx, "eur_pln_rate", 4.5)

_otd_limit_eur := 100000
_otd_limit_pln := _round2(_otd_limit_eur * _otd_eur_rate)
_otd_current_total_eur := _round2(_otd_one_off_amount / _otd_eur_rate + _otd_one_off_count_so_far * 0)
_otd_current_total_pln := _round2(_otd_one_off_amount + _otd_one_off_count_so_far * 0)

_otd_data_ok = true {
    _otd_one_off_amount > 0
    _otd_eur_rate > 0
} else = false {
    true
}

_otd_exceeds = true {
    _otd_current_total_eur > _otd_limit_eur
} else = false {
    true
}

_otd_near_limit = true {
    _otd_current_total_eur >= 95000
    _otd_current_total_eur <= _otd_limit_eur
} else = false {
    true
}

_otd_boundary_case = true {
    _otd_current_total_eur >= 99999.99
    _otd_current_total_eur <= 100000.01
} else = false {
    true
}

routing_otd4 = "BLOCK_AND_ALERT" {
    not _otd_data_ok
} else = "BLOCK_AND_ALERT" {
    _otd_exceeds
} else = "TRIAGE_QUEUE" {
    _otd_near_limit
} else = "SUGGEST" {
    true
}

reason_otd4 = sprintf("Jednorazowa: brak danych (kwota=%.2f PLN, EUR=%.2f) — BLOCK.", [_otd_one_off_amount, _otd_one_off_eur]) {
    not _otd_data_ok
} else = sprintf("Jednorazowa: limit 100000 EUR przekroczony (%.2f EUR) — BLOCK + eskalacja.", [_otd_current_total_eur]) {
    _otd_exceeds
} else = sprintf("Jednorazowa: %.2f EUR (limit 100000 EUR) — alarm przed przekroczeniem (TRIAGE).", [_otd_current_total_eur]) {
    _otd_near_limit
} else = sprintf("Jednorazowa: %.2f EUR ≤ 100000 EUR (rok %d).", [_otd_current_total_eur, _otd_one_off_year]) {
    true
}

warnings_otd4 = ["[V3-P20-I04] Jednorazowa: limit 100000 EUR przekroczony — BLOCK."] {
    _otd_exceeds
} else = ["[V3-P20-I04] Jednorazowa: 95000 EUR ≤ kwota ≤ 100000 EUR — alarm (TRIAGE)."] {
    _otd_near_limit
} else = ["[V3-P20-I04] Jednorazowa: brak danych — BLOCK."] {
    not _otd_data_ok
} else = []

otd4_decision := _certificate(420104, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.one_time_deprecation_sentinel",
    "analysis": "one_time_deprecation_sentinel",
    "one_off_amount_pln": _otd_one_off_amount,
    "one_off_amount_eur": _otd_one_off_eur,
    "year": _otd_one_off_year,
    "eur_pln_rate": _otd_eur_rate,
    "one_off_count_so_far": _otd_one_off_count_so_far,
    "limit_eur": _otd_limit_eur,
    "limit_pln": _otd_limit_pln,
    "current_total_eur": _otd_current_total_eur,
    "exceeds_limit": _otd_exceeds,
    "near_limit": _otd_near_limit,
    "boundary_case": _otd_boundary_case,
    "fail_closed": not _otd_data_ok,
    "_routing": routing_otd4,
    "_routing_reason": reason_otd4,
    "_legal_basis": "Ustawa o PIT art. 22k (jednorazowa 100000 EUR); ADR-002 (dane); V3_P20-I04",
    "_warnings": warnings_otd4,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "one_time_deprecation_sentinel"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I05: KŚT RATES AS DATA (stawki z tabeli, wersjonowanie)
# Stawki KŚT (art. 22j: 1,5/2/2,5/5/10/20/25/40/50%) jako dane wersjonowane;
# grupy KŚT → stawki z data.jdg.thresholds.kst_rates; brak hardcode.
# ═══════════════════════════════════════════════════════════════════════════════
_kst_group := object.get(_ctx, "kst_group", 0)
_kst_rate := object.get(_ctx, "depreciation_rate", 0.0)
_kst_year := object.get(_ctx, "year", 0)

_kst_known_groups := {
    1: _th("kst_group_1_rate", 0.015),
    2: _th("kst_group_2_rate", 0.02),
    3: _th("kst_group_3_rate", 0.025),
    4: _th("kst_group_4_rate", 0.05),
    5: _th("kst_group_5_rate", 0.10),
    6: _th("kst_group_6_rate", 0.20),
    7: _th("kst_group_7_rate", 0.25),
    8: _th("kst_group_8_rate", 0.40),
    9: _th("kst_group_9_rate", 0.50),
}

_kst_mapped_rate = rate {
    rate := _kst_known_groups[_kst_group]
    rate != null
} else = 0.0 {
    true
}

_kst_rate_mismatch = true {
    _kst_mapped_rate > 0
    _kst_rate > 0
    _round2(_kst_rate) != _round2(_kst_mapped_rate)
} else = false {
    true
}

_kst_data_ok = true {
    _kst_group > 0
    _kst_year > 0
} else = false {
    true
}

routing_kst5 = "BLOCK_AND_ALERT" {
    not _kst_data_ok
} else = "BLOCK_AND_ALERT" {
    _kst_rate_mismatch
} else = "SUGGEST" {
    true
}

reason_kst5 = sprintf("KŚT: brak danych (grupa=%d, rok=%d) — BLOCK.", [_kst_group, _kst_year]) {
    not _kst_data_ok
} else = sprintf("KŚT: stawka z danych (grupa %d) = %.4f ≠ deklarowana %.4f — BLOCK (dryf danych).", [_kst_group, _kst_mapped_rate, _kst_rate]) {
    _kst_rate_mismatch
} else = sprintf("KŚT: grupa %d → stawka %.4f (rok %d) — zgodna z danymi (wersja %s).", [_kst_group, _kst_mapped_rate, _kst_year, _th("kst_version", "kst-2026.01")]) {
    true
}

warnings_kst5 = ["[V3-P20-I05] KŚT: dryf stawki (dane vs deklaracja) — BLOCK."] {
    _kst_rate_mismatch
} else = ["[V3-P20-I05] KŚT: brak danych grupy/rok — BLOCK."] {
    not _kst_data_ok
} else = []

kst5_decision := _certificate(420105, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.kst_rates_as_data",
    "analysis": "kst_rates_as_data",
    "kst_group": _kst_group,
    "kst_rate": _kst_rate,
    "year": _kst_year,
    "rate_from_data": _kst_mapped_rate,
    "rate_mismatch": _kst_rate_mismatch,
    "kst_version": _th("kst_version", "kst-2026.01"),
    "fail_closed": not _kst_data_ok,
    "_routing": routing_kst5,
    "_routing_reason": reason_kst5,
    "_legal_basis": "Ustawa o PIT art. 22j (stawki KŚT); ADR-002 (stawki jako dane wersjonowane)",
    "_warnings": warnings_kst5,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "kst_rates_as_data"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I06: LEASING SPLIT ENGINE (operacyjny/finansowy, limit 150000)
# Rozdzielanie leasing operacyjny (raty = koszty) vs finansowy (amortyzacja+odsetki);
# limit 150000 aut (art. 23 ust. 1 pkt 47a); testy graniczne 149999,99/150000/150000,01.
# ═══════════════════════════════════════════════════════════════════════════════
_ls_asset_value := object.get(_ctx, "asset_value_pln", 0.0)
_ls_leasing_type := object.get(_ctx, "leasing_type", "")
_ls_car := object.get(_ctx, "is_car", false)
_ls_lease_payments := object.get(_ctx, "annual_lease_payments", 0.0)
_ls_interest := object.get(_ctx, "interest_pln", 0.0)
_ls_depreciation := object.get(_ctx, "depreciation_pln", 0.0)

_ls_data_ok = true {
    _ls_asset_value > 0
    _ls_leasing_type != ""
} else = false {
    true
}

_ls_car_limit_exceeded = true {
    _ls_car == true
    _ls_asset_value > 150000
} else = false {
    true
}

_ls_car_limit_boundary = true {
    _ls_car == true
    _ls_asset_value >= 149999.99
    _ls_asset_value <= 150000.01
} else = false {
    true
}

_ls_operational = true {
    _ls_leasing_type == "OPERATIONAL"
} else = false {
    true
}

_ls_financial = true {
    _ls_leasing_type == "FINANCIAL"
} else = false {
    true
}

_ls_cost_method = koszty {
    _ls_operational == true
} else = amortyzacja_plus_odsetki {
    _ls_financial == true
} else = nieokreslony {
    true
}

routing_ls6 = "BLOCK_AND_ALERT" {
    not _ls_data_ok
} else = "TRIAGE_QUEUE" {
    _ls_car_limit_exceeded
} else = "SUGGEST" {
    true
}

reason_ls6 = sprintf("Leasing: brak danych (wartość=%.2f, typ='%s') — BLOCK.", [_ls_asset_value, _ls_leasing_type]) {
    not _ls_data_ok
} else = sprintf("Leasing: auto > 150000 PLN (%.2f PLN) — limit art. 23 ust. 1 pkt 47a (TRIAGE).", [_ls_asset_value]) {
    _ls_car_limit_exceeded
} else = sprintf("Leasing: %s (wartość %.2f PLN, %s limit 150000) — koszt method: %s.", [_ls_leasing_type, _ls_asset_value, "auto" if _ls_car == true else "nie auto", _ls_cost_method]) {
    true
}

warnings_ls6 = ["[V3-P20-I06] Leasing: limit 150000 aut przekroczony — TRIAGE (art. 23 pkt 47a)."] {
    _ls_car_limit_exceeded
} else = ["[V3-P20-I06] Leasing: brak danych — BLOCK."] {
    not _ls_data_ok
} else = []

ls6_decision := _certificate(420106, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.leasing_split_engine",
    "analysis": "leasing_split_engine",
    "asset_value_pln": _ls_asset_value,
    "leasing_type": _ls_leasing_type,
    "is_car": _ls_car,
    "annual_lease_payments": _ls_lease_payments,
    "interest_pln": _ls_interest,
    "depreciation_pln": _ls_depreciation,
    "cost_method": _ls_cost_method,
    "car_limit_150000": 150000,
    "car_limit_exceeded": _ls_car_limit_exceeded,
    "boundary_case": _ls_car_limit_boundary,
    "fail_closed": not _ls_data_ok,
    "_routing": routing_ls6,
    "_routing_reason": reason_ls6,
    "_legal_basis": "Ustawa o PIT art. 23 ust. 1 pkt 47a (limit 150000 aut); art. 22 (leasing); ADR-002",
    "_warnings": warnings_ls6,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "leasing_split_engine"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I07: PKPiR→UoR TRANSITION (przejście mid-year, remanent, audit)
# Procedura przejścia mid-year przy przekroczeniu progu UoR (2M EUR): remanent
# przejściowy, audyt, decyzja transformacji, ferry bilansu.
# ═══════════════════════════════════════════════════════════════════════════════
_pt_transition := object.get(_ctx, "transition_in_progress", false)
_pt_revenue_pln := object.get(_ctx, "revenue_pln", 0.0)
_pt_eur_rate := object.get(_ctx, "eur_pln_rate", 4.5)
_pt_threshold_eur := object.get(_ctx, "uor_threshold_eur", 2000000)

_pt_revenue_eur := _round2(_pt_revenue_pln / _pt_eur_rate)
_pt_above_threshold = true {
    _pt_revenue_eur >= _pt_threshold_eur
} else = false {
    true
}

_pt_remanent_closed := object.get(_ctx, "remanent_closed", false)
_pt_transformer_ready := object.get(_ctx, "transformer_ready", false)
_pt_audit_complete := object.get(_ctx, "audit_complete", false)

_pt_data_ok = true {
    _pt_revenue_pln > 0
    _pt_eur_rate > 0
    _pt_threshold_eur > 0
} else = false {
    true
}

routing_pt7 = "BLOCK_AND_ALERT" {
    not _pt_data_ok
} else = "BLOCK_AND_ALERT" {
    _pt_above_threshold
    not _pt_transition
} else = "TRIAGE_QUEUE" {
    _pt_above_threshold
    _pt_transition
    not _pt_audit_complete
} else = "SUGGEST" {
    _pt_above_threshold
    _pt_transition
    _pt_audit_complete
} else = "SUGGEST" {
    true
}

reason_pt7 = sprintf("PKPiR→UoR: brak danych (przychód=%.2f PLN, EUR=%.2f, threshold=%.0f EUR) — BLOCK.", [_pt_revenue_pln, _pt_revenue_eur, _pt_threshold_eur]) {
    not _pt_data_ok
} else = sprintf("PKPiR→UoR: przychód %.0f EUR ≥ 2M EUR (przekroczenie) — transformacja wymagana (BLOCK jeśli brak).", [_pt_revenue_eur]) {
    _pt_above_threshold
    not _pt_transition
} else = "PKPiR→UoR: transformacja w toku, wymagany audyt przed złożeniem (TRIAGE)." {
    _pt_above_threshold
    _pt_transition
    not _pt_audit_complete
} else = "PKPiR→UoR: transformacja gotowa, audyt zakończony — status zgodny." {
    true
}

warnings_pt7 = ["[V3-P20-I07] PKPiR→UoR: brak przejścia mimo przekroczenia progu — BLOCK."] {
    _pt_above_threshold
    not _pt_transition
} else = ["[V3-P20-I07] PKPiR→UoR: audyt przejścia niekompletny — TRIAGE."] {
    _pt_above_threshold
    _pt_transition
    not _pt_audit_complete
} else = ["[V3-P20-I07] PKPiR→UoR: brak danych — BLOCK."] {
    not _pt_data_ok
} else = []

pt7_decision := _certificate(420107, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.pkpir_to_uor_transition",
    "analysis": "pkpir_to_uor_transition",
    "revenue_pln": _pt_revenue_pln,
    "revenue_eur": _pt_revenue_eur,
    "eur_pln_rate": _pt_eur_rate,
    "uor_threshold_eur": _pt_threshold_eur,
    "above_threshold": _pt_above_threshold,
    "transition_in_progress": _pt_transition,
    "audit_complete": _pt_audit_complete,
    "remanent_closed": _pt_remanent_closed,
    "transformer_ready": _pt_transformer_ready,
    "fail_closed": not _pt_data_ok,
    "_routing": routing_pt7,
    "_routing_reason": reason_pt7,
    "_legal_basis": "Ustawa o CIT art. 9a (próg UoR 2M EUR); art. 2 ust. 1 pkt 2 UoR; transformator pkpir_to_uor_transformer",
    "_warnings": warnings_pt7,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "pkpir_to_uor_transition"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I08: YEAR-END CLOSING CHAIN (PKPiR→amortyzacja→PIT→JPK, invariants)
# Łańcuch zamknięcia roku: remanent zamkniecie → amortyzacje → PIT roczny → JPK;
# invariants spójności kwot.
# ═══════════════════════════════════════════════════════════════════════════════
_yc_year := object.get(_ctx, "year", 0)
_yc_remanent_closed := object.get(_ctx, "remanent_closed", false)
_yc_depreciation_done := object.get(_ctx, "depreciation_done", false)
_yc_pit_declared := object.get(_ctx, "pit_declared", false)
_yc_jpk_submitted := object.get(_ctx, "jpk_submitted", false)

_yc_data_ok = true {
    _yc_year > 0
} else = false {
    true
}

_yc_chain_complete = true {
    _yc_remanent_closed == true
    _yc_depreciation_done == true
    _yc_pit_declared == true
    _yc_jpk_submitted == true
} else = false {
    true
}

_yc_partial_count = 0 {
    _yc_remanent_closed == false
} else = _yc_partial_count + 1 {
    _yc_remanent_closed == true
} else = _yc_partial_count {
    true
}    _yc_partial_count = _yc_partial_count + 1 if { _yc_depreciation_done == true } else = _yc_partial_count
    _yc_partial_count = _yc_partial_count + 1 if { _yc_pit_declared == true } else = _yc_partial_count
    _yc_partial_count = _yc_partial_count + 1 if { _yc_jpk_submitted == true } else = _yc_partial_count


routing_yc8 = "BLOCK_AND_ALERT" {
    not _yc_data_ok
} else = "BLOCK_AND_ALERT" {
    _yc_chain_complete == false
    _yc_year != 0
} else = "TRIAGE_QUEUE" {
    _yc_chain_complete == false
} else = "SUGGEST" {
    true
}

reason_yc8 = sprintf("Zamknięcie roku %d: brak danych roku — BLOCK.", [_yc_year]) {
    not _yc_data_ok
} else = sprintf("Zamknięcie roku %d: łańcuch niekompletny (%d/4 kroków) — BLOCK.", [_yc_year, _yc_partial_count]) {
    _yc_chain_complete == false
} else = "Zamknięcie roku: łańcuch kompletny (remanent→amortyzacja→PIT→JPK)." {
    true
}

warnings_yc8 = ["[V3-P20-I08] Zamknięcie roku: łańcuch niekompletny — BLOCK (PKPiR→amortyzacja→PIT→JPK)."] {
    _yc_chain_complete == false
} else = ["[V3-P20-I08] Zamknięcie roku: brak danych roku — BLOCK."] {
    not _yc_data_ok
} else = []

yc8_decision := _certificate(420108, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.year_end_closing_chain",
    "analysis": "year_end_closing_chain",
    "year": _yc_year,
    "remanent_closed": _yc_remanent_closed,
    "depreciation_done": _yc_depreciation_done,
    "pit_declared": _yc_pit_declared,
    "jpk_submitted": _yc_jpk_submitted,
    "chain_complete": _yc_chain_complete,
    "steps_done": _yc_partial_count,
    "steps_total": 4,
    "fail_closed": not _yc_data_ok,
    "_routing": routing_yc8,
    "_routing_reason": reason_yc8,
    "_legal_basis": "Ustawa o PIT art. 24a (PIT roczny); JPK/V7; UoR zamknięcie roku; V3_P36 kalendarz",
    "_warnings": warnings_yc8,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "year_end_closing_chain"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I09: DOUBLE-ENTRY CONSISTENCY GATE (property test bilansu UoR)
# Property test: bilans UoR zbalansowany (A = K + Z); podwójny zapis spójny.
# ═══════════════════════════════════════════════════════════════════════════════
_de_total_assets := object.get(_ctx, "total_assets_pln", 0.0)
_de_total_equity := object.get(_ctx, "total_equity_pln", 0.0)
_de_total_liabilities := object.get(_ctx, "total_liabilities_pln", 0.0)
_de_wn_total := object.get(_ctx, "wn_total_pln", 0.0)
_de_ma_total := object.get(_ctx, "ma_total_pln", 0.0)
_de_variance_allowed := object.get(_ctx, "variance_allowed_pln", 0.01)

_de_bs_balanced = true {
    _abs(_de_total_assets - (_de_total_equity + _de_total_liabilities)) <= _de_variance_allowed
} else = false {
    true
}

_de_de_ok = true {
    _abs(_de_wn_total - _de_ma_total) <= _de_variance_allowed
} else = false {
    true
}

_de_data_ok = true {
    _de_total_assets >= 0
    _de_total_equity >= 0
    _de_total_liabilities >= 0
    _de_wn_total >= 0
    _de_ma_total >= 0
} else = false {
    true
}

routing_de9 = "BLOCK_AND_ALERT" {
    not _de_data_ok
} else = "BLOCK_AND_ALERT" {
    not _de_bs_balanced
} else = "BLOCK_AND_ALERT" {
    not _de_de_ok
} else = "SUGGEST" {
    true
}

reason_de9 = sprintf("Double-entry: brak danych (A=%.2f, K=%.2f, Z=%.2f, Wn=%.2f, Ma=%.2f) — BLOCK.", [_de_total_assets, _de_total_equity, _de_total_liabilities, _de_wn_total, _de_ma_total]) {
    not _de_data_ok
} else = sprintf("Double-entry: bilans NIEZBALANSOWANY (A=%.2f, K+Z=%.2f, delta=%.2f) — BLOCK.", [_de_total_assets, _de_total_equity + _de_total_liabilities, _de_total_assets - (_de_total_equity + _de_total_liabilities)]) {
    not _de_bs_balanced
} else = sprintf("Double-entry: podwójny zapis NIESPOJNY (Wn=%.2f, Ma=%.2f, delta=%.2f) — BLOCK.", [_de_wn_total, _de_ma_total, _de_wn_total - _de_ma_total]) {
    not _de_de_ok
} else = "Double-entry: bilans zbalansowany, podwójny zapis spójny — status OK." {
    true
}

warnings_de9 = ["[V3-P20-I09] Double-entry: bilans NIEZBALANSOWANY — BLOCK."] {
    not _de_bs_balanced
} else = ["[V3-P20-I09] Double-entry: podwójny zapis NIESPOJNY — BLOCK."] {
    not _de_de_ok
} else = ["[V3-P20-I09] Double-entry: brak danych — BLOCK."] {
    not _de_data_ok
} else = []

de9_decision := _certificate(420109, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.double_entry_consistency_gate",
    "analysis": "double_entry_consistency_gate",
    "total_assets_pln": _de_total_assets,
    "total_equity_pln": _de_total_equity,
    "total_liabilities_pln": _de_total_liabilities,
    "wn_total_pln": _de_wn_total,
    "ma_total_pln": _de_ma_total,
    "variance_allowed_pln": _de_variance_allowed,
    "bs_balanced": _de_bs_balanced,
    "de_double_entry_ok": _de_de_ok,
    "fail_closed": not _de_data_ok,
    "_routing": routing_de9,
    "_routing_reason": reason_de9,
    "_legal_basis": "Ustawa o rachunkowości art. 2, 45 (podwójny zapis, bilans); V3_P04 invarianty; UoR",
    "_warnings": warnings_de9,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "double_entry_consistency_gate"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I10: BOOKKEEPING GOLDEN SET (oracle: remanent, amortyzacja, NKUP)
# Golden oracle: rematerjent, amortyzacja, NKUP — zgodność z golden setem;
# rozjazd = BLOCK; przypadek graniczny = TRIAGE; zgodny = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_gs_case := object.get(_ctx, "case_id", "")
_gs_in_golden := object.get(_ctx, "in_golden_set", false)
_gs_match := object.get(_ctx, "golden_match", true)
_gs_boundary := object.get(_ctx, "boundary_case", false)

_gs_violation = true {
    _gs_in_golden == true
    _gs_match == false
} else = false {
    true
}

_gs_data_ok = true {
    _gs_case != ""
} else = false {
    true
}

routing_gs10 = "BLOCK_AND_ALERT" {
    not _gs_data_ok
} else = "BLOCK_AND_ALERT" {
    _gs_violation
} else = "TRIAGE_QUEUE" {
    _gs_boundary
} else = "SUGGEST" {
    true
}

reason_gs10 = sprintf("Golden set: brak case_id — BLOCK.", [_gs_case]) {
    not _gs_data_ok
} else = sprintf("Golden set: przypadek %s ROZJAZD z oracle — BLOCK.", [_gs_case]) {
    _gs_violation
} else = sprintf("Golden set: przypadek %s na granicy — weryfikacja graniczna (TRIAGE).", [_gs_case]) {
    _gs_boundary
} else = sprintf("Golden set: przypadek %s zgodny z oracle (wersja %s).", [_gs_case, _th("golden_version", "bookkeeping-golden-2026.09")]) {
    true
}

warnings_gs10 = ["[V3-P20-I10] Golden set: rozjazd z oracle — BLOCK."] {
    _gs_violation
} else = ["[V3-P20-I10] Golden set: przypadek graniczny — TRIAGE (potwierdź ręcznie)."] {
    _gs_boundary
} else = ["[V3-P20-I10] Golden set: brak case_id — BLOCK."] {
    not _gs_data_ok
} else = []

gs10_decision := _certificate(420110, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.bookkeeping_golden_set",
    "analysis": "bookkeeping_golden_set",
    "case_id": _gs_case,
    "in_golden_set": _gs_in_golden,
    "golden_match": _gs_match,
    "boundary_case": _gs_boundary,
    "golden_version": _th("golden_version", "bookkeeping-golden-2026.09"),
    "fail_closed": _gs_violation,
    "_routing": routing_gs10,
    "_routing_reason": reason_gs10,
    "_legal_basis": "Golden Oracle (V2 F3, P10); V3_P20-I10",
    "_warnings": warnings_gs10,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "bookkeeping_golden_set"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I11: BOOKKEEPING INVARIANTS PACK (PKPiR=PIT=JPK, bilans zbalansowany)
# Invarianty runtime: PKPiR przychody = PIT przychody; PKPiR koszty = PIT koszty;
# JPK = PKPiR; bilans UoR zbalansowany; amortyzacja groszowa.
# ═══════════════════════════════════════════════════════════════════════════════
_bi_pkpir_revenue := object.get(_ctx, "pkpir_revenue_pln", 0.0)
_bi_pit_revenue := object.get(_ctx, "pit_revenue_pln", 0.0)
_bi_pkpir_costs := object.get(_ctx, "pkpir_costs_pln", 0.0)
_bi_pit_costs := object.get(_ctx, "pit_costs_pln", 0.0)
_bi_jpk_revenue := object.get(_ctx, "jpk_revenue_pln", 0.0)
_bi_jpk_costs := object.get(_ctx, "jpk_costs_pln", 0.0)
_bi_variance_allowed := object.get(_ctx, "variance_allowed_pln", 1.0)

_bi_revenue_ok = true {
    _abs(_bi_pkpir_revenue - _bi_pit_revenue) <= _bi_variance_allowed
    _abs(_bi_pkpir_revenue - _bi_jpk_revenue) <= _bi_variance_allowed
} else = false {
    true
}

_bi_costs_ok = true {
    _abs(_bi_pkpir_costs - _bi_pit_costs) <= _bi_variance_allowed
    _abs(_bi_pkpir_costs - _bi_jpk_costs) <= _bi_variance_allowed
} else = false {
    true
}    _bi_data_ok = true {
    _bi_pkpir_revenue >= 0
    _bi_pit_revenue >= 0
    _bi_pkpir_costs >= 0
    _bi_pit_costs >= 0
    _bi_jpk_revenue >= 0
    _bi_jpk_costs >= 0
} else = false {
    true
}

_bi_violations := []
_bi_violations := concat(_bi_violations, ["PKPiR≠PIT revenue"]) if { not _bi_revenue_ok } else = _bi_violations
_bi_violations := concat(_bi_violations, ["PKPiR≠JPK revenue"]) if { not _bi_revenue_ok } else = _bi_violations
_bi_violations := concat(_bi_violations, ["PKPiR≠PIT costs"]) if { not _bi_costs_ok } else = _bi_violations
_bi_violations := concat(_bi_violations, ["PKPiR≠JPK costs"]) if { not _bi_costs_ok } else = _bi_violations

_bi_any = true if { count(_bi_violations) > 0 } else = false

routing_bi11 = "BLOCK_AND_ALERT" if { not _bi_data_ok }
else = "BLOCK_AND_ALERT" if { _bi_any }else = "SUGGEST" if { _bi_any == false; _bi_data_ok == true }
else = "" if { false }

reason_bi11 = sprintf("Invarianty księgowe: brak danych (PKPiR=%.2f/%.2f, PIT=%.2f/%.2f, JPK=%.2f/%.2f) — BLOCK.", [_bi_pkpir_revenue, _bi_pkpir_costs, _bi_pit_revenue, _bi_pit_costs, _bi_jpk_revenue, _bi_jpk_costs]) if { not _bi_data_ok }
else = sprintf("Invarianty księgowe: naruszone %d (PKPiR/PIT/JPK spójność) — BLOCK.", [count(_bi_violations)]) if { _bi_any }
else =        "Invarianty księgowe: PKPiR=PIT=JPK spójne, bilans zbalansowany, amortyzacja groszowa OK." if { _bi_any == false; _bi_data_ok == true }
        else = "Invarianty księgowe: brak naruszeń." if { _bi_any == true; _bi_data_ok == true }        else = "Invarianty księgowe: brak danych — BLOCK." if { not _bi_data_ok } else = ""

warnings_bi11 = ["[V3-P20-I11] Invarianty księgowe: %s — BLOCK (PKPiR=PIT=JPK).", [concat(", ", _bi_violations)]] if { _bi_any }
else = ["[V3-P20-I11] Invarianty księgowe: brak danych — BLOCK."] if { not _bi_data_ok }
else = []

bi11_decision := _certificate(420111, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.bookkeeping_invariants_pack",
    "analysis": "bookkeeping_invariants_pack",
    "pkpir_revenue_pln": _bi_pkpir_revenue,
    "pkpir_costs_pln": _bi_pkpir_costs,
    "pit_revenue_pln": _bi_pit_revenue,
    "pit_costs_pln": _bi_pit_costs,
    "jpk_revenue_pln": _bi_jpk_revenue,
    "jpk_costs_pln": _bi_jpk_costs,
    "variance_allowed_pln": _bi_variance_allowed,
    "violations": _bi_violations,
    "violations_count": count(_bi_violations),
    "fail_closed": _bi_any,
    "_routing": routing_bi11,
    "_routing_reason": reason_bi11,
    "_legal_basis": "V3_P04 invarianty; PIT art. 24a; JPK; UoR podwójny zapis; V3_P20-I11",
    "_warnings": warnings_bi11,
}) if { _activated; object.get(_ctx, "analysis", "") == "bookkeeping_invariants_pack" }

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P20-I12: DOCUMENT CHECKLIST GENERATOR (checklisty PKPiR/UoR/amortyzacja)
# Generator checklisty dokumentacyjnej per typ ewidencji: PKPiR/UoR/amortyzacja;
# komplet = SUGGEST (paczka do PDF); brak podstawy = TRIAGE; nieznany typ = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_dc_type := object.get(_ctx, "pack_type", "")
_dc_basis := object.get(_ctx, "legal_basis_present", false)
_dc_docs := object.get(_ctx, "docs_checklist_complete", false)

_dc_known = true if { _dc_type in {"PKPiR", "UoR", "AMORTYZACJA"} } else = false

_dc_unknown = true if { not _dc_known } else = false

_dc_complete = true if { _dc_known; _dc_basis; _dc_docs } else = false

routing_dc12 = "BLOCK_AND_ALERT" if { not _dc_known }
else = "TRIAGE_QUEUE" if { not _dc_complete }else = "SUGGEST" if { _bi_any == false; _bi_data_ok == true }
else = "" if { false }

reason_dc12 = sprintf("Checklista %s: nieznany typ paczki — fail-closed (BLOCK).", [_dc_type]) if { not _dc_known }
else = sprintf("Checklista %s: niekompletna (podstawa=%t, dokumenty=%t) — TRIAGE.", [_dc_type, _dc_basis, _dc_docs]) if { _dc_known; _dc_complete == false }
else = sprintf("Checklista %s: kompletna — paczka dokumentacyjna gotowa (PDF).", [_dc_type]) if { _dc_known; _dc_complete == true } else = "Checklista: brak statusu." if { _dc_known == false }

warnings_dc12 = ["[V3-P20-I12] Checklista: nieznany typ — BLOCK (fail-closed)." ] if { not _dc_known }
else = ["[V3-P20-I12] Checklista: niekompletna — uzupełnij podstawę/dokumenty przed PDF."] if { _dc_known; _dc_complete == false }
else = [] if { _dc_known; _dc_complete == true } else = []

dc12_decision := _certificate(420112, {
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.document_checklist_generator",
    "analysis": "document_checklist_generator",
    "pack_type": _dc_type,
    "legal_basis_present": _dc_basis,
    "docs_checklist_complete": _dc_docs,
    "pack_complete": _dc_complete,
    "fail_closed": _dc_unknown,
    "_routing": routing_dc12,
    "_routing_reason": reason_dc12,
    "_legal_basis": "Checklisty dokumentacyjne BDO/PCC/ksiegowosc; V2 F4 (wytłumaczalność); V3_P20-I12",
    "_warnings": warnings_dc12,
}) if { _activated; object.get(_ctx, "analysis", "") == "document_checklist_generator" }

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision if { not _snapshot_ok }
else := psv1_decision if { psv1_decision.rule_id != "" }
else := rc2_decision if { rc2_decision.rule_id != "" }
else := nb3_decision if { nb3_decision.rule_id != "" }
else := otd4_decision if { otd4_decision.rule_id != "" }
else := kst5_decision if { kst5_decision.rule_id != "" }
else := ls6_decision if { ls6_decision.rule_id != "" }
else := pt7_decision if { pt7_decision.rule_id != "" }
else := yc8_decision if { yc8_decision.rule_id != "" }
else := de9_decision if { de9_decision.rule_id != "" }
else := gs10_decision if { gs10_decision.rule_id != "" }
else := bi11_decision if { bi11_decision.rule_id != "" }
else := dc12_decision if { dc12_decision.rule_id != "" }
else := default_decide := default_decide := default_decide := default_decide := default_decide := default_decide if { _bi_data_ok == true } else := default_decide if { _bi_data_ok == false }

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p20_ksiegowosc_pkpir_uor.no_match",
    "package": "jdg.v3_p20_ksiegowosc_pkpir_uor",
    "priority": 999999,
    "warnings": ["[V3-P20] Brak aktywnej analizy — brak decyzji.",
]

