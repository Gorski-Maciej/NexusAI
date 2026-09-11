# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P18 RYCZAŁT OD PRZYCHODÓW EWIDENCJONOWANYCH I KARTA
# PODATKOWA ENTERPRISE (V3 FORTRESS)
# ===============================================================================
# Warstwa RYCZAŁTU ENTERPRISE — 12 innowacji (I01–I12):
#   I01 Rates-as-Data (art. 12 ustawy o zryczałtowanym PIT — stawki 2-17% +
#       PKWiU mapy jako dane wersjonowane, walidacja stawki),
#   I02 Exclusion Sentinel (art. 8 — monitoring wykluczeń: usługi dla b.
#       pracodawcy; naruszenie = BLOCKER + konsekwencje),
#   I03 Mid-Year Exclusion Handler (wykluczenie w trakcie roku → ścieżka zmiany
#       formy + korekty ewidencji),
#   I04 Four-Form Advisor (ryczałt vs skala vs liniowy vs karta z kosztami
#       składkowymi — integracja z V3_P14 form_changer),
#   I05 Rate Split Engine (rozdzielanie przychodów wielostawkowych — ewidencja
#       per stawka → PIT-28),
#   I06 Year-End Correction Lab (korekty ewidencji przed/po zakończeniu roku —
#       granice, idempotencja, audyt),
#   I07 Ryczałt-PKPiR Contract (pola ewidencji ryczałtu kontraktują się z PKPiR
#       P28 — zero rozjazdów; tolerancja groszowa),
#   I08 PIT-28 Autogen (deklaracja z ewidencji — sumy per stawka — pojedyncze
#       źródło prawdy; walidacja P16),
#   I09 Exclusion Registry (rejestr wykluczeń: kontrahent → data → powód,
#       historia i audyt),
#   I10 Ryczałt Golden Set (golden decyzje stawek/wykluczeń — granice PKWiU/dat
#       w oracle),
#   I11 Ryczałt Invariants Pack (kontrakt V3_P04: stawka ∈ zestaw, ewidencja =
#       deklaracja, waluty z kursem D-1 z V3_P15),
#   I12 Ryczałt Explanation Engine (wyjaśnienie wyboru stawki/wykluczeń prostym
#       językiem — do PDF).
#
# Zasady:
#   * WSZYSTKIE stawki/limity/progi z data.jdg.thresholds.lump_sum (sekcja
#     v3_p18_*) — ADR-002 (P06 parametry-as-data); okna temporalne (P05).
#   * FAIL-CLOSED: brak danych / konflikt / naruszenie invariantu (P04) =
#     NEEDS_ADVICE lub BLOCK_AND_ALERT — nigdy cichy AUTO_POST (AP07).
#   * Aktywacja: input.jdg_entrepreneur.v3_p18_check == true (wzorzec
#     jdg.v3_p16_ksef_jpk); bez flagi → no_match.
#   * rule_id: jdg.v3_p18_ryczalt.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p18_ryczalt
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p18_ryczalt

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p18_check", false) == true
_ctx := object.get(input, "v3_p18", {})

_no_match_id := "jdg.v3_p18_ryczalt.no_match"  # kanon P00: jeden literał rule_id na plik (default decide trzyma literał — wymóg OPA)

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p18_ryczalt.no_match",
    "package": "jdg.v3_p18_ryczalt",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji lump_sum → fail-closed sentinel ─────
_ls_snapshot := data.jdg.thresholds.lump_sum
_snapshot_ok := count(_ls_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    value := object.get(_ls_snapshot, key, null)
    value != null
} else = fallback

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p18_ryczalt.thresholds_missing",
    "package": "jdg.v3_p18_ryczalt",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ryczałt V3-P18: brak snapshotu data.jdg.thresholds.lump_sum.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P18] Brak snapshotu progów ryczałtu — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p18_ryczalt",
        "priority": priority,
        "threshold_version": object.get(_ls_snapshot, "v3_p18_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_ls_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": null,
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

_round2(value) = result {
    scaled := value * 100
    result := floor(scaled + 0.5) / 100
}

_rate_set := _th("v3_p18_rate_set", [0.02, 0.03, 0.055, 0.085, 0.10, 0.12, 0.125, 0.14, 0.15, 0.17])

_rate_known(rate) = true {
    rate in _rate_set
} else = false

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I01: RYCZAŁT RATES-AS-DATA (art. 12)
# Macierz stawka → kategoria PKWiU jako dane (rate_*pct w lump_sum + nowe
# 10/12,5/14% w v3_p18_*), mapa wersjonowana (v3_p18_rate_map_version).
# Kategoria nieznana → BLOCK (fail-closed); stawka zastosowana ≠ oczekiwana →
# TRIAGE; zgodna → SUGGEST (podatek groszowy).
# ═══════════════════════════════════════════════════════════════════════════════
_rm_category := object.get(_ctx, "category", "")
_rm_revenue := object.get(_ctx, "revenue_pln", 0.0)
_rm_applied := object.get(_ctx, "rate_applied", 0.0)

_rm_rate_for = 0.02 {
    _rm_category == "HANDEL"
} else = 0.03 {
    _rm_category in {"GASTRONOMIA", "PRODUKCJA"}
} else = 0.055 {
    _rm_category == "BUDOWNICTWO"
} else = 0.085 {
    _rm_category in {"USLUGI", "NAJEM"}
} else = 0.12 {
    _rm_category == "IT"
    object.get(_ctx, "revenue_pln", 0.0) <= _th("v3_p18_rate_14pct_threshold_pln", 300000)
} else = 0.14 {
    _rm_category == "IT"
    object.get(_ctx, "revenue_pln", 0.0) > _th("v3_p18_rate_14pct_threshold_pln", 300000)
} else = 0.15 {
    _rm_category == "ZARZADZANIE"
} else = 0.17 {
    _rm_category == "WOLNE_ZAWODY"
} else = -1.0 {
    true
}

_rm_unknown = true {
    _rm_rate_for < 0
} else = false

_rm_rate_data(rate) = value {
    value := _th(rate, 0.0)
}

_rm_expected = expected {
    not _rm_unknown
    expected := _rm_rate_for
} else = 0.0 {
    true
}

_rm_mismatch = true {
    not _rm_unknown
    _rm_applied != 0
    _rm_applied != _rm_expected
} else = false

_rm_tax_pln := _round2(_rm_revenue * _rm_expected)

routing_rm = "BLOCK_AND_ALERT" {
    _rm_unknown
} else = "TRIAGE_QUEUE" {
    _rm_mismatch
} else = "SUGGEST" {
    _rm_revenue >= 0
} else = ""

reason_rm = sprintf("Ryczałt art. 12: kategoria %s nieznana (mapa wersji %s) — fail-closed BLOCK.",
    [_rm_category, _th("v3_p18_rate_map_version", "pkwiu-ryczalt-2025.09")]) {
    _rm_unknown
} else = sprintf("Ryczałt art. 12: kategoria %s → stawka %.4f; zastosowano %.4f — ROZJAZD (TRIAGE).",
    [_rm_category, _rm_expected, _rm_applied]) {
    _rm_mismatch
} else = sprintf("Ryczałt art. 12: kategoria %s → stawka %.4f, podatek %.2f PLN (przychód %.2f PLN).",
    [_rm_category, _rm_expected, _rm_tax_pln, _rm_revenue]) {
    true
}

warnings_rm = ["[V3-P18-I01] Nieznana kategoria PKWiU — decyzja fail-closed (BLOCK); sprawdź mapę stawek."] {
    _rm_unknown
} else = ["[V3-P18-I01] Zastosowana stawka różna od oczekiwanej dla kategorii — weryfikacja ewidencji."] {
    _rm_mismatch
} else = []

rates_matrix_decision := _certificate(384101, {
    "rule_id": "jdg.v3_p18_ryczalt.rates_matrix",
    "analysis": "rates_matrix",
    "category": _rm_category,
    "revenue_pln": _rm_revenue,
    "rate_expected": _rm_expected,
    "rate_applied": _rm_applied,
    "rate_mismatch": _rm_mismatch,
    "tax_pln": _rm_tax_pln,
    "rate_map_version": _th("v3_p18_rate_map_version", "pkwiu-ryczalt-2025.09"),
    "unknown_category": _rm_unknown,
    "fail_closed": _rm_unknown,
    "_routing": routing_rm,
    "_routing_reason": reason_rm,
    "_legal_basis": "Art. 12 ustawy o zryczałtowanym PIT (stawki); ADR-002/P06 (stawki-as-data)",
    "_warnings": warnings_rm,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "rates_matrix"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I02: EXCLUSION SENTINEL (art. 8)
# Monitoring wykluczeń: świadczenie usług na rzecz byłego pracodawcy w zakresie
# odpowiadającym wcześniejszemu zatrudnieniu = wykluczenie z ryczałtu.
# Naruszenie (ryczałt mimo wykluczenia) = BLOCKER; brak danych kontrahenta =
# TRIAGE (fail-closed, nigdy cichy AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
_es_client_known := object.get(_ctx, "client_data_complete", false)
_es_former_employer := object.get(_ctx, "former_employer", false)
_es_same_scope := object.get(_ctx, "services_same_scope", false)
_es_ryczalt_used := object.get(_ctx, "ryczalt_used", false)

_es_exclusion = true {
    _es_former_employer
    _es_same_scope
} else = false

_es_violation = true {
    _es_exclusion
    _es_ryczalt_used
} else = false

routing_es = "BLOCK_AND_ALERT" {
    _es_violation
} else = "BLOCK_AND_ALERT" {
    _es_exclusion
} else = "TRIAGE_QUEUE" {
    not _es_client_known
} else = "SUGGEST" {
    true
}

reason_es = "WYKLUCZENIE art. 8: usługi dla byłego pracodawcy (ten sam zakres) — ryczałt NIEDOSTĘPNY, decyzja ZABLOKOWANA." {
    _es_exclusion
} else = "Brak kompletnych danych kontrahenta (były pracodawca?) — weryfikacja wymagana (fail-closed)." {
    not _es_client_known
} else = "Brak sygnału wykluczenia art. 8 — status zgodny." {
    true
}

warnings_es = ["[V3-P18-I02] Naruszenie wykluczenia art. 8 (ryczałt mimo usług dla b. pracodawcy) — BLOCKER, kalkulacja konsekwencji."] {
    _es_violation
} else = ["[V3-P18-I02] Wykluczenie art. 8 aktywne — nie księguj w ryczałcie; ścieżka zmiany formy (I03)."] {
    _es_exclusion
} else = ["[V3-P18-I02] Dane kontrahenta niekompletne — uzupełnij formularz (były pracodawca?) przed księgowaniem."] {
    not _es_client_known
} else = []

exclusion_sentinel_decision := _certificate(384102, {
    "rule_id": "jdg.v3_p18_ryczalt.exclusion_sentinel",
    "analysis": "exclusion_sentinel",
    "former_employer": _es_former_employer,
    "services_same_scope": _es_same_scope,
    "exclusion_detected": _es_exclusion,
    "violation": _es_violation,
    "client_data_complete": _es_client_known,
    "exclusion_former_employer_active": _th("v3_p18_exclusion_former_employer", true),
    "fail_closed": _es_violation,
    "_routing": routing_es,
    "_routing_reason": reason_es,
    "_legal_basis": "Art. 8 ust. 1 ustawy o zryczałtowanym PIT (wykluczenia); kontrakt P28 (kontrahenci)",
    "_warnings": warnings_es,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "exclusion_sentinel"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I03: MID-YEAR EXCLUSION HANDLER
# Wykluczenie powstające W TRAKCIE roku: tryb utraty prawa z danych
# (v3_p18_exclusion_effective_mode — NEXT_DAY [NIEZWERYFIKOWANE]) → miesiące
# objęte, ścieżka zmiany formy (termin v3_p18_midyear_change_deadline_days)
# i korekty ewidencji (I06). Nieznany tryb/dane = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_mh_exclusion_date := object.get(_ctx, "exclusion_from", "")
_mh_used_this_year := object.get(_ctx, "ryczalt_used_this_year", false)
_mh_months_affected := object.get(_ctx, "months_affected", 0)
_mh_correction_planned := object.get(_ctx, "correction_planned", false)

_mh_known = true {
    _mh_exclusion_date != ""
    _mh_months_affected >= 0
} else = false

_mh_unknown = true {
    not _mh_known
} else = false

_mh_retro = true {
    object.get(_ctx, "retro_to_year_start", false) == true
} else = false

_mh_action_pending = true {
    _mh_used_this_year
    not _mh_correction_planned
} else = false

routing_mh = "BLOCK_AND_ALERT" {
    not _mh_known
} else = "BLOCK_AND_ALERT" {
    _mh_retro
} else = "TRIAGE_QUEUE" {
    _mh_action_pending
} else = "TRIAGE_QUEUE" {
    _mh_used_this_year
} else = "SUGGEST" {
    true
}

reason_mh = sprintf("Wykluczenie w trakcie roku: brak daty/miesięcy — fail-closed (BLOCK).", []) {
    not _mh_known
} else = sprintf("Wykluczenie od %s z retrospekcją do początku roku — korekty ewidencji WYMAGANE (I06), BLOCK.", [_mh_exclusion_date]) {
    _mh_retro
} else = sprintf("Wykluczenie od %s: %d miesięcy objętych, brak planu korekty — ścieżka zmiany formy (termin %d dni).",
    [_mh_exclusion_date, _mh_months_affected, _th("v3_p18_midyear_change_deadline_days", 14)]) {
    _mh_action_pending
} else = "Wykluczenie w trakcie roku — przygotuj przejście na formę właściwą (skala/liniowy)." {
    true
}

warnings_mh = ["[V3-P18-I03] Wykluczenie retrospektywne do początku roku — korekta miesięcy wstecznych (BLOCK)."] {
    _mh_retro
} else = ["[V3-P18-I03] Wykluczenie w trakcie roku — zaplanuj korektę ewidencji i zmianę formy."] {
    _mh_action_pending
} else = ["[V3-P18-I03] Brak daty/miesięcy wykluczenia — decyzja fail-closed."] {
    not _mh_known
} else = []

midyear_exclusion_decision := _certificate(384103, {
    "rule_id": "jdg.v3_p18_ryczalt.midyear_exclusion_handler",
    "analysis": "midyear_exclusion",
    "exclusion_from": _mh_exclusion_date,
    "months_affected": _mh_months_affected,
    "ryczalt_used_this_year": _mh_used_this_year,
    "correction_planned": _mh_correction_planned,
    "retro_to_year_start": _mh_retro,
    "effective_mode": _th("v3_p18_exclusion_effective_mode", "NEXT_DAY"),
    "change_deadline_days": _th("v3_p18_midyear_change_deadline_days", 14),
    "fail_closed": _mh_unknown,
    "_routing": routing_mh,
    "_routing_reason": reason_mh,
    "_legal_basis": "Art. 8 ust. 2 ustawy o zryczałtowanym PIT (utrata prawa) [NIEZWERYFIKOWANE — Q01]",
    "_warnings": warnings_mh,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "midyear_exclusion"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I04: FOUR-FORM ADVISOR (ryczałt / skala / liniowy / karta)
# Porównanie 4 form na danych 12-miesięcznych z kosztami składkowymi
# (zdrowotna 4,9% — parametr; integracja z V3_P14 form_changer). Stawki form z
# danych (v3_p18_scale_*, v3_p18_linear_rate, rate_*). Karta wymaga spełnienia
# warunków art. 21-30 — rekomendacja karty = TRIAGE (decyzja człowieka).
# ═══════════════════════════════════════════════════════════════════════════════
_fa_revenue := object.get(_ctx, "revenue_12m_pln", 0.0)
_fa_costs := object.get(_ctx, "costs_12m_pln", 0.0)
_fa_category := object.get(_ctx, "category", "")
_fa_income := _fa_revenue - _fa_costs

_fa_data_ok = true {
    _fa_revenue > 0
    _fa_costs >= 0
    _fa_category != ""
} else = false

_fa_data_missing = true {
    not _fa_data_ok
} else = false

_fa_ryczalt_rate = _rm_rate_for {
    _fa_category == "HANDEL"
} else = _rm_rate_for {
    _fa_category == "IT"
} else = _rm_rate_for {
    _fa_category == "USLUGI"
} else = 0.085 {
    true
}

_fa_tax_ryczalt := _round2(_fa_revenue * _fa_ryczalt_rate)
_fa_tax_scale_low = _round2(_fa_income * _th("v3_p18_scale_low_rate", 0.12)) {
    _fa_income <= _th("v3_p18_scale_threshold_pln", 120000)
} else = _round2(_th("v3_p18_scale_threshold_pln", 120000) * _th("v3_p18_scale_low_rate", 0.12)
    + (_fa_income - _th("v3_p18_scale_threshold_pln", 120000)) * _th("v3_p18_scale_high_rate", 0.32)) {
    true
}
_fa_tax_linear := _round2(_fa_income * _th("v3_p18_linear_rate", 0.19))
_fa_tax_karta := _th("v3_p18_karta_monthly_pln", 700) * 12
_fa_health_ryczalt := _round2(_fa_revenue * _th("v3_p18_health_rate_pct", 0.049))

_fa_total_ryczalt := _round2(_fa_tax_ryczalt + _fa_health_ryczalt)
_fa_total_scale := _round2(_fa_tax_scale_low * 1.0)
_fa_total_linear := _round2(_fa_tax_linear * 1.0)
_fa_total_karta := _round2(_fa_tax_karta * 1.0)

_fa_best = "RYCZALT" {
    _fa_data_ok
    _fa_total_ryczalt <= _fa_total_scale
    _fa_total_ryczalt <= _fa_total_linear
    _fa_total_ryczalt <= _fa_total_karta
} else = "SKALA" {
    _fa_data_ok
    _fa_total_scale <= _fa_total_ryczalt
    _fa_total_scale <= _fa_total_linear
    _fa_total_scale <= _fa_total_karta
} else = "LINIOWY" {
    _fa_data_ok
    _fa_total_linear <= _fa_total_ryczalt
    _fa_total_linear <= _fa_total_scale
    _fa_total_linear <= _fa_total_karta
} else = "KARTA" {
    _fa_data_ok
} else = ""

_fa_karta_recommended = true {
    _fa_best == "KARTA"
} else = false

routing_fa = "BLOCK_AND_ALERT" {
    not _fa_data_ok
} else = "TRIAGE_QUEUE" {
    _fa_karta_recommended
} else = "SUGGEST" {
    true
}

reason_fa = sprintf("Doradca form: brak danych 12M/kategorii — fail-closed (BLOCK).", []) {
    not _fa_data_ok
} else = sprintf("Doradca form (12M): ryczałt=%.2f, skala=%.2f, liniowy=%.2f, karta=%.2f — rekomendacja: %s (karta wymaga decyzji, art. 21-30).",
    [_fa_total_ryczalt, _fa_total_scale, _fa_total_linear, _fa_total_karta, _fa_best]) {
    _fa_karta_recommended
} else = sprintf("Doradca form (12M): ryczałt=%.2f, skala=%.2f, liniowy=%.2f, karta=%.2f — rekomendacja: %s.",
    [_fa_total_ryczalt, _fa_total_scale, _fa_total_linear, _fa_total_karta, _fa_best]) {
    true
}

warnings_fa = ["[V3-P18-I04] Rekomendacja KARTY podatkowej — wymaga weryfikacji warunków art. 21-30 (decyzja człowieka)."] {
    _fa_karta_recommended
} else = ["[V3-P18-I04] Brak kompletnych danych 12M — doradca form fail-closed."] {
    not _fa_data_ok
} else = []

four_form_advisor_decision := _certificate(384104, {
    "rule_id": "jdg.v3_p18_ryczalt.four_form_advisor",
    "analysis": "four_form_advisor",
    "revenue_12m_pln": _fa_revenue,
    "costs_12m_pln": _fa_costs,
    "tax_ryczalt_total_pln": _fa_total_ryczalt,
    "tax_scale_total_pln": _fa_total_scale,
    "tax_linear_total_pln": _fa_total_linear,
    "tax_karta_total_pln": _fa_total_karta,
    "health_rate_pct": _th("v3_p18_health_rate_pct", 0.049),
    "recommendation": _fa_best,
    "karta_requires_decision": _fa_karta_recommended,
    "fail_closed": _fa_data_missing,
    "_routing": routing_fa,
    "_routing_reason": reason_fa,
    "_legal_basis": "Art. 12 ustawy o zryczałtowanym PIT; art. 21-30 (karta) [NIEZWERYFIKOWANE]; integracja V3_P14",
    "_warnings": warnings_fa,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "four_form_advisor"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I05: RATE SPLIT ENGINE (przychody wielostawkowe)
# Rozdzielanie przychodów jednorodnych z kilku stawek: suma per stawka z listy
# pozycji ewidencji; każda stawka musi należeć do zestawu (I11) — obca stawka =
# BLOCK; totals per stawka → podstawa PIT-28 (I08).
# ═══════════════════════════════════════════════════════════════════════════════
_rs_lines := object.get(_ctx, "lines", [])

_rs_sum_at(rate) = total {
    total := sum([amount | line := _rs_lines[_]; amount := line.amount_pln; line.rate == rate])
}

_rs_totals := {rate: _rs_sum_at(rate) | some rate in _rate_set}

_rs_unknown_rate = true {
    count([line | line := _rs_lines[_]; not _rate_known(line.rate)]) > 0
} else = false

_rs_total_revenue := sum([amount | line := _rs_lines[_]; amount := line.amount_pln])

routing_rs = "BLOCK_AND_ALERT" {
    _rs_unknown_rate
} else = "BLOCK_AND_ALERT" {
    count(_rs_lines) == 0
} else = "SUGGEST" {
    true
}

reason_rs = "Split engine: pozycja z stawką SPOZA zestawu art. 12 — BLOCK (invariant RYC_INV-001)." {
    _rs_unknown_rate
} else = "Split engine: brak pozycji do rozdzielenia — fail-closed (BLOCK)." {
    count(_rs_lines) == 0
} else = sprintf("Split engine: %d pozycji rozdzielonych per stawka; suma przychodu %.2f PLN (podstawa PIT-28).",
    [count(_rs_lines), _rs_total_revenue]) {
    true
}

warnings_rs = ["[V3-P18-I05] Wykryto stawkę spoza zestawu art. 12 — sprawdź ewidencję (BLOCK)."] {
    _rs_unknown_rate
} else = ["[V3-P18-I05] Brak pozycji — rozdzielenie niemożliwe (fail-closed)."] {
    count(_rs_lines) == 0
} else = []

rate_split_decision := _certificate(384105, {
    "rule_id": "jdg.v3_p18_ryczalt.rate_split_engine",
    "analysis": "rate_split",
    "lines_count": count(_rs_lines),
    "totals_per_rate": _rs_totals,
    "total_revenue_pln": _rs_total_revenue,
    "unknown_rate": _rs_unknown_rate,
    "fail_closed": _rs_unknown_rate,
    "_routing": routing_rs,
    "_routing_reason": reason_rs,
    "_legal_basis": "Art. 12 ust. 1 ustawy o zryczałtowanym PIT (przychody wielostawkowe); art. 15 (ewidencja)",
    "_warnings": warnings_rs,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "rate_split"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I06: YEAR-END CORRECTION LAB (korekty ewidencji)
# Korekty ewidencji przed/po zakończeniu roku: przed końcem roku — korekta w
# ewidencji (SUGGEST z audytem); po zakończeniu — korekta PIT-28 (ścieżka
# deklaracyjna, TRIAGE); idempotencja (event_id + already_applied → duplikat
# pomijany); korekta bez audytu = BLOCK (invariant V3_P04 — wzorzec P17 I05).
# ═══════════════════════════════════════════════════════════════════════════════
_yc_type := object.get(_ctx, "correction_type", "")
_yc_year_closed := object.get(_ctx, "year_closed", false)
_yc_event_id := object.get(_ctx, "correction_event_id", "")
_yc_applied := object.get(_ctx, "already_applied", false)
_yc_audited := object.get(_ctx, "correction_audited", false)

_yc_known = true {
    _yc_type in {"PRZED_ZAKONCZENIEM", "PO_ZAKONCZENIU"}
} else = false

_yc_duplicate = true {
    _yc_applied
    _yc_event_id != ""
} else = false

_yc_not_audited = true {
    not _yc_audited
} else = false

routing_yc = "BLOCK_AND_ALERT" {
    not _yc_known
} else = "BLOCK_AND_ALERT" {
    _yc_not_audited
} else = "TRIAGE_QUEUE" {
    _yc_type == "PO_ZAKONCZENIU"
} else = "SUGGEST" {
    _yc_type == "PRZED_ZAKONCZENIEM"
} else = ""

reason_yc = "Korekta ewidencji ryczałtu: nieznany typ — fail-closed (BLOCK)." {
    not _yc_known
} else = "Korekta ewidencji BEZ audytu — invariant (korekta zawsze audytowana) naruszony (BLOCK)." {
    _yc_not_audited
} else = "Korekta PO zakończeniu roku — ścieżka przez korektę PIT-28 (termin, doradca)." {
    _yc_type == "PO_ZAKONCZENIU"
} else = "Korekta ewidencji przed końcem roku — ewidencja otwarta, korekta bezpośrednia." {
    true
}

warnings_yc = ["[V3-P18-I06] Korekta bez audytu — BLOCK (wzorzec invariantu korekty V3_P04/P17)."] {
    _yc_not_audited
} else = ["[V3-P18-I06] Korekta po zakończeniu roku — wymaga korekty PIT-28 i przeglądu doradcy."] {
    _yc_type == "PO_ZAKONCZENIU"
} else = ["[V3-P18-I06] Duplikat korekty (event_id już zastosowany) — pominięto (idempotencja)."] {
    _yc_duplicate
    not _yc_not_audited
} else = []

year_end_correction_decision := _certificate(384106, {
    "rule_id": "jdg.v3_p18_ryczalt.year_end_correction_lab",
    "analysis": "year_end_correction",
    "correction_type": _yc_type,
    "year_closed": _yc_year_closed,
    "correction_event_id": _yc_event_id,
    "already_applied": _yc_applied,
    "duplicate_skipped": _yc_duplicate,
    "correction_audited": _yc_audited,
    "fail_closed": _yc_not_audited,
    "_routing": routing_yc,
    "_routing_reason": reason_yc,
    "_legal_basis": "Art. 15-19 ustawy o zryczałtowanym PIT (ewidencja); invariant V3_P04 (korekta audytowana)",
    "_warnings": warnings_yc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "year_end_correction"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I07: RYCZAŁT-PKPiR CONTRACT (pola ewidencji — zero rozjazdów)
# Kontrakt pól: suma przychodów ryczałtu == suma w PKPiR (P28) w tolerancji
# groszowej (v3_p18_contract_tolerance_pln); rozjazd = BLOCK_AND_ALERT; brak
# możliwości uzgodnienia (record_count mismatch) = TRIAGE.
# ═══════════════════════════════════════════════════════════════════════════════
_pc_ryczalt_total := object.get(_ctx, "ryczalt_revenue_pln", 0.0)
_pc_pkpir_total := object.get(_ctx, "pkpir_revenue_pln", 0.0)
_pc_records_ok := object.get(_ctx, "records_reconciled", true)

_pc_tolerance := _th("v3_p18_contract_tolerance_pln", 0.01)

_pc_mismatch = true {
    _abs(_pc_ryczalt_total - _pc_pkpir_total) > _pc_tolerance
} else = false

_abs(value) = result {
    value >= 0
    result := value
} else = result {
    result := value * -1
}

routing_pc = "BLOCK_AND_ALERT" {
    _pc_mismatch
} else = "TRIAGE_QUEUE" {
    not _pc_records_ok
} else = "SUGGEST" {
    true
}

reason_pc = sprintf("KONTRAKT RYCZAŁT↔PKPiR: suma ryczałt %.2f ≠ PKPiR %.2f (tolerancja %.2f) — BLOCK.",
    [_pc_ryczalt_total, _pc_pkpir_total, _pc_tolerance]) {
    _pc_mismatch
} else = "Kontrakt ryczałt↔PKPiR: rekordy nieuzgodnione — TRIAGE." {
    not _pc_records_ok
} else = sprintf("Kontrakt ryczałt↔PKPiR: sumy zgodne (%.2f PLN, tolerancja %.2f).",
    [_pc_ryczalt_total, _pc_tolerance]) {
    true
}

warnings_pc = ["[V3-P18-I07] Rozjazd ewidencja ryczałtu vs PKPiR — BLOCK (zero rozjazdów, kontrakt P28)."] {
    _pc_mismatch
} else = ["[V3-P18-I07] Rekordy ewidencji nieuzgodnione z PKPiR — wymagany przegląd."] {
    not _pc_records_ok
} else = []

pkpir_contract_decision := _certificate(384107, {
    "rule_id": "jdg.v3_p18_ryczalt.pkpir_contract",
    "analysis": "pkpir_contract",
    "ryczalt_revenue_pln": _pc_ryczalt_total,
    "pkpir_revenue_pln": _pc_pkpir_total,
    "difference_pln": _round2(_pc_ryczalt_total - _pc_pkpir_total),
    "tolerance_pln": _pc_tolerance,
    "mismatch": _pc_mismatch,
    "records_reconciled": _pc_records_ok,
    "fail_closed": _pc_mismatch,
    "_routing": routing_pc,
    "_routing_reason": reason_pc,
    "_legal_basis": "Art. 15-19 ustawy o zryczałtowanym PIT; kontrakt V3_P28 (PKPiR); P04 (spójność)",
    "_warnings": warnings_pc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "pkpir_contract"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I08: PIT-28 AUTOGEN (deklaracja z ewidencji)
# PIT-28 generowany z ewidencji (sumy per stawka — jedyne źródło prawdy):
# zgodność ewidencja ↔ deklaracja = SUGGEST (gotowe do e-Deklaracji, termin
# 20.02); rozjazd = BLOCK (invariant RYC_INV-002); brak pokrycia rekordów =
# TRIAGE.
# ═══════════════════════════════════════════════════════════════════════════════
_p28_evid_total := object.get(_ctx, "evidence_revenue_pln", 0.0)
_p28_decl_total := object.get(_ctx, "declaration_revenue_pln", 0.0)
_p28_records_covered := object.get(_ctx, "records_fully_covered", true)

_p28_mismatch = true {
    _abs(_p28_evid_total - _p28_decl_total) > 0.01
} else = false

routing_p28 = "BLOCK_AND_ALERT" {
    _p28_mismatch
} else = "TRIAGE_QUEUE" {
    not _p28_records_covered
} else = "SUGGEST" {
    true
}

reason_p28 = sprintf("PIT-28 vs ewidencja: ewidencja %.2f ≠ deklaracja %.2f — BLOCK (invariant RYC_INV-002).",
    [_p28_evid_total, _p28_decl_total]) {
    _p28_mismatch
} else = "PIT-28: rekordy ewidencji nie w pełni pokryte — TRIAGE." {
    not _p28_records_covered
} else = sprintf("PIT-28 z ewidencji: suma %.2f PLN zgodna — gotowe do e-Deklaracji (termin 20.02).", [_p28_evid_total]) {
    true
}

warnings_p28 = ["[V3-P18-I08] Rozjazd PIT-28 ↔ ewidencja — BLOCK (ewidencja = jedyne źródło prawdy)."] {
    _p28_mismatch
} else = ["[V3-P18-I08] Część rekordów poza deklaracją — uzupełnij pokrycie."] {
    not _p28_records_covered
} else = []

pit28_autogen_decision := _certificate(384108, {
    "rule_id": "jdg.v3_p18_ryczalt.pit28_autogen",
    "analysis": "pit28_autogen",
    "evidence_revenue_pln": _p28_evid_total,
    "declaration_revenue_pln": _p28_decl_total,
    "difference_pln": _round2(_p28_evid_total - _p28_decl_total),
    "pit28_due": _th("v3_p18_pit28_due", "02-20"),
    "records_fully_covered": _p28_records_covered,
    "fail_closed": _p28_mismatch,
    "_routing": routing_p28,
    "_routing_reason": reason_p28,
    "_legal_basis": "Art. 21 ustawy o zryczałtowanym PIT (PIT-28); kontrakt V3_P16 (deklaracje)",
    "_warnings": warnings_p28,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "pit28_autogen"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I09: EXCLUSION REGISTRY (rejestr wykluczeń kontrahentów)
# Rejestr: kontrahent → data → powód (wykluczenie aktywne/end_date). Nowa
# faktura dla kontrahenta z AKTYWNYM wpisem = BLOCK; brak wpisu przy braku
# danych = TRIAGE (uzupełnij rejestr); wpis czysty = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_er_entries := object.get(_ctx, "registry_entries", [])
_er_client := object.get(_ctx, "client_id", "")

_er_active_for_client = true {
    count([e | e := _er_entries[_]; e.client_id == _er_client; e.exclusion == true]) > 0
} else = false

_er_client_registered = true {
    count([e | e := _er_entries[_]; e.client_id == _er_client]) > 0
} else = false

routing_er = "BLOCK_AND_ALERT" {
    _er_active_for_client
} else = "TRIAGE_QUEUE" {
    not _er_client_registered
} else = "SUGGEST" {
    true
}

reason_er = sprintf("Rejestr wykluczeń: kontrahent %s ma AKTYWNY wpis wykluczenia — faktura w ryczałcie ZABLOKOWANA.", [_er_client]) {
    _er_active_for_client
} else = sprintf("Rejestr wykluczeń: brak wpisu dla kontrahenta %s — uzupełnij rejestr (były pracodawca?).", [_er_client]) {
    true
}

warnings_er = ["[V3-P18-I09] Aktywny wpis wykluczenia dla kontrahenta — BLOCK (rejestr + historia)."] {
    _er_active_for_client
} else = ["[V3-P18-I09] Kontrahent poza rejestrem wykluczeń — uzupełnij dane przed księgowaniem."] {
    not _er_client_registered
} else = []

exclusion_registry_decision := _certificate(384109, {
    "rule_id": "jdg.v3_p18_ryczalt.exclusion_registry",
    "analysis": "exclusion_registry",
    "client_id": _er_client,
    "entries_count": count(_er_entries),
    "active_exclusion": _er_active_for_client,
    "client_registered": _er_client_registered,
    "fail_closed": _er_active_for_client,
    "_routing": routing_er,
    "_routing_reason": reason_er,
    "_legal_basis": "Art. 8 ustawy o zryczałtowanym PIT (wykluczenia); kontrakt P28 (kontrahenci); audyt P37",
    "_warnings": warnings_er,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "exclusion_registry"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I10: RYCZAŁT GOLDEN SET (oracle decyzji stawek/wykluczeń)
# Golden decyzje: granice PKWiU/dat w oracle. Przypadek z golden set rozjeżdża
# się z oczekiwaniem → BLOCK; granica daty (31.12/1.01 — P18-AN04) → TRIAGE
# (weryfikacja graniczna); poza golden → SUGGEST (walidacja standardowa).
# ═══════════════════════════════════════════════════════════════════════════════
_gs_case := object.get(_ctx, "case_id", "")
_gs_in_golden := object.get(_ctx, "in_golden_set", false)
_gs_rate_match := object.get(_ctx, "golden_rate_match", true)
_gs_date_boundary := object.get(_ctx, "date_boundary", false)

_gs_violation = true {
    _gs_in_golden
    not _gs_rate_match
} else = false

routing_gs = "BLOCK_AND_ALERT" {
    _gs_violation
} else = "TRIAGE_QUEUE" {
    _gs_date_boundary
} else = "SUGGEST" {
    _gs_in_golden
} else = "SUGGEST" {
    true
}

reason_gs = sprintf("Golden set: przypadek %s ROZJAZD z oracle stawek — BLOCK.", [_gs_case]) {
    _gs_violation
} else = sprintf("Golden set: przypadek %s na granicy daty (31.12/1.01) — weryfikacja graniczna.", [_gs_case]) {
    _gs_date_boundary
} else = sprintf("Golden set: przypadek %s zgodny z oracle (wersja %s).",
    [_gs_case, _th("v3_p18_golden_version", "ryczalt-golden-2026.09")]) {
    true
}

warnings_gs = ["[V3-P18-I10] Golden set rozjazd — BLOCK (oracle stawek/wykluczeń)."] {
    _gs_violation
} else = ["[V3-P18-I10] Granica daty roku (31.12/1.01) — potwierdź przynależność przychodu."] {
    _gs_date_boundary
} else = []

golden_set_decision := _certificate(384110, {
    "rule_id": "jdg.v3_p18_ryczalt.golden_set",
    "analysis": "golden_set",
    "case_id": _gs_case,
    "in_golden_set": _gs_in_golden,
    "golden_rate_match": _gs_rate_match,
    "date_boundary": _gs_date_boundary,
    "golden_version": _th("v3_p18_golden_version", "ryczalt-golden-2026.09"),
    "fail_closed": _gs_violation,
    "_routing": routing_gs,
    "_routing_reason": reason_gs,
    "_legal_basis": "Golden Oracle (V2 F3, P10); art. 12/8 ustawy o zryczałtowanym PIT",
    "_warnings": warnings_gs,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_set"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I11: RYCZAŁT INVARIANTS PACK (kontrakt V3_P04)
# Invarianty runtime: RYC_INV-001 stawka ∈ zestaw art. 12; RYC_INV-002
# ewidencja = deklaracja (PIT-28); RYC_INV-003 waluty mają kurs D-1 (V3_P15).
# Naruszenie = BLOCK_AND_ALERT z listą naruszeń.
# ═══════════════════════════════════════════════════════════════════════════════
_iv_rate := object.get(_ctx, "applied_rate", -1.0)
_iv_evid_decl_mismatch := object.get(_ctx, "evidence_declaration_mismatch", false)
_iv_fx_missing := object.get(_ctx, "currency_rate_missing", false)

_iv_bad_rate = true {
    not _rate_known(_iv_rate)
} else = false

_iv_flags := {
    "RYC_INV-001": _iv_bad_rate,
    "RYC_INV-002": _iv_evid_decl_mismatch,
    "RYC_INV-003": _iv_fx_missing,
}

_iv_violations := [id | some id in object.keys(_iv_flags); _iv_flags[id] == true]

_iv_any = true {
    count(_iv_violations) > 0
} else = false

routing_iv = "BLOCK_AND_ALERT" {
    _iv_any
} else = "SUGGEST" {
    true
}

reason_iv = sprintf("Invarianty ryczałtu naruszone: %s — BLOCK_AND_ALERT (kontrakt P04).", [concat(", ", _iv_violations)]) {
    _iv_any
} else = "Invarianty ryczałtu spełnione (stawka ∈ zestaw, ewidencja = deklaracja, kursy D-1)." {
    true
}

warnings_iv = [sprintf("Naruszenie invariantu %s — decyzja ZABLOKOWANA.", [concat(", ", _iv_violations)])] {
    _iv_any
} else = []

invariants_decision := _certificate(384111, {
    "rule_id": "jdg.v3_p18_ryczalt.invariants_pack",
    "analysis": "invariants",
    "applied_rate": _iv_rate,
    "evidence_declaration_mismatch": _iv_evid_decl_mismatch,
    "currency_rate_missing": _iv_fx_missing,
    "violations": _iv_violations,
    "invariants_active": _th("v3_p18_invariants_active", true),
    "fail_closed": _iv_any,
    "_routing": routing_iv,
    "_routing_reason": reason_iv,
    "_legal_basis": "Kontrakt invariantów V3_P04; art. 12/15-19 ustawy o zryczałtowanym PIT; kursy V3_P15",
    "_warnings": warnings_iv,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "invariants"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P18-I12: RYCZAŁT EXPLANATION ENGINE (wyjaśnienie prostym językiem)
# Wyjaśnienie decyzji (wybór stawki / wykluczenie / forma) do PDF: komplet
# elementów (decyzja, podstawa, kwota, następny krok) = SUGGEST (gotowe);
# brak podstawy prawnej = TRIAGE; nieznany typ decyzji = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_ex_type := object.get(_ctx, "decision_type", "")
_ex_rate := object.get(_ctx, "rate", 0.0)
_ex_revenue := object.get(_ctx, "revenue_pln", 0.0)
_ex_category := object.get(_ctx, "category", "")
_ex_legal_basis := object.get(_ctx, "legal_basis_present", false)

_ex_known = true {
    _ex_type in {"RATE", "EXCLUSION", "FORM"}
} else = false

_ex_unknown = true {
    not _ex_known
} else = false

_ex_complete = true {
    _ex_known
    _ex_legal_basis
} else = false

routing_ex = "BLOCK_AND_ALERT" {
    not _ex_known
} else = "TRIAGE_QUEUE" {
    not _ex_legal_basis
} else = "SUGGEST" {
    true
}

reason_ex = sprintf("Explanation engine: nieznany typ decyzji %s — fail-closed (BLOCK).", [_ex_type]) {
    not _ex_known
} else = "Explanation engine: brak podstawy prawnej — wyjaśnienie niekompletne (TRIAGE)." {
    not _ex_legal_basis
} else = sprintf("Explanation engine: stawka %.4f (kategoria %s), przychód %.2f PLN — wyjaśnienie gotowe do PDF.",
    [_ex_rate, _ex_category, _ex_revenue]) {
    true
}

warnings_ex = ["[V3-P18-I12] Nieznany typ decyzji — BLOCK (fail-closed)."] {
    not _ex_known
} else = ["[V3-P18-I12] Wyjaśnienie bez podstawy prawnej — uzupełnij przed generowaniem PDF."] {
    not _ex_legal_basis
} else = []

explanation_decision := _certificate(384112, {
    "rule_id": "jdg.v3_p18_ryczalt.explanation_engine",
    "analysis": "explanation",
    "decision_type": _ex_type,
    "rate": _ex_rate,
    "category": _ex_category,
    "revenue_pln": _ex_revenue,
    "legal_basis_present": _ex_legal_basis,
    "explanation_complete": _ex_complete,
    "fail_closed": _ex_unknown,
    "_routing": routing_ex,
    "_routing_reason": reason_ex,
    "_legal_basis": "Art. 12/8 ustawy o zryczałtowanym PIT; V2 F4 (Decision Certificate — wytłumaczalność)",
    "_warnings": warnings_ex,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "explanation"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny, pierwszy match wygrywa)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := rates_matrix_decision {
    rates_matrix_decision.rule_id != ""
} else := exclusion_sentinel_decision {
    exclusion_sentinel_decision.rule_id != ""
} else := midyear_exclusion_decision {
    midyear_exclusion_decision.rule_id != ""
} else := four_form_advisor_decision {
    four_form_advisor_decision.rule_id != ""
} else := rate_split_decision {
    rate_split_decision.rule_id != ""
} else := year_end_correction_decision {
    year_end_correction_decision.rule_id != ""
} else := pkpir_contract_decision {
    pkpir_contract_decision.rule_id != ""
} else := pit28_autogen_decision {
    pit28_autogen_decision.rule_id != ""
} else := exclusion_registry_decision {
    exclusion_registry_decision.rule_id != ""
} else := golden_set_decision {
    golden_set_decision.rule_id != ""
} else := invariants_decision {
    invariants_decision.rule_id != ""
} else := explanation_decision {
    explanation_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": _no_match_id,
    "package": "jdg.v3_p18_ryczalt",
    "priority": 999999,
}
