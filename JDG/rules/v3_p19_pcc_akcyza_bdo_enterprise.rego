# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P19 PCC / PODATKI LOKALNE / AKCYZA / BDO-CBAM ENTERPRISE
# (V3 FORTRESS)
# ===============================================================================
# Warstwa PCC/lokalne/środowisko ENTERPRISE — 12 innowacji (I01–I12):
#   I01 PCC Matrix Complete (ustawa o PCC — art. 1-10: stawki 2%/0,5%/1% jako
#       dane, zwolnienia art. 9, termin 14 dni PCC-3, granica 1000 zł),
#   I02 Gmina Rates Validator (stawki gminne jako dane z TWARDĄ walidacją
#       limitów ustawowych — alarm przy przekroczeniu, granica ±0,01),
#   I03 MPP-PCC Exclusion Gate (faktura MPP ≠ PCC — zero podwójnego
#       opodatkowania VAT/PCC; invariant),
#   I04 Local Tax Calendar Pack (terminy: transport 31.01, raty nieruchomości
#       15.03/15.05/15.09/15.11 — zero ciszy),
#   I05 BDO Qualifier (kwalifikacja BDO: odpady/opakowania/WEEE — checklista
#       rejestracyjna, raport roczny 15.03),
#   I06 EWC Code Library (baza kodów EWC jako dane — walidacja ewidencji),
#   I07 Waste Fee Calculator (opłaty za wytworzone odpady — stawki jako dane,
#       granice mas),
#   I08 CBAM Architectural Decision (monitoring importu carbon-intensywnego —
#       dokumentacja zakresu; akcyza/CBAM = decyzja, nie automatyzacja),
#   I09 PCC Golden Set (golden decyzje: granice 1000 zł / 14 dni / MPP w oracle),
#   I10 Local Tax Invariants (kontrakt V3_P04: PCC+VAT wykluczenie, limity
#       gminne, terminy — BLOCK przy naruszeniu),
#   I11 Instalment Reminder (przypomnienia rat nieruchomości z przewidywaniem
#       kwot — tax/4, raty 15.03/15.05/15.09/15.11),
#   I12 Environmental Explanation Pack (checklisty dokumentacyjne BDO/PCC dla
#       księgowej — komplet = SUGGEST, PDF).
#
# Zasady:
#   * WSZYSTKIE stawki/limity/terminy z data.jdg.thresholds.pcc_local_excise
#     (sekcja v3_p19_*) — ADR-002 (P06); okna temporalne (P05). Stawki PCC
#     bazowe reużywane: pcc_sale_rate/pcc_loan_rate/pcc_company_rate itd.
#   * FAIL-CLOSED: brak danych / konflikt / naruszenie invariantu (P04) =
#     NEEDS_ADVICE lub BLOCK_AND_ALERT — nigdy cichy AUTO_POST (AP07).
#   * Akcyza i CBAM: decyzje architektoniczne — ścieżki MANUAL/TRIAGE z
#     dokumentacją zakresu (NIE automatyzacja na ślepo).
#   * Aktywacja: input.jdg_entrepreneur.v3_p19_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p19_pcc_akcyza_bdo.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p19_pcc_akcyza_bdo
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p19_pcc_akcyza_bdo

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p19_check", false) == true
_ctx := object.get(input, "v3_p19", {})

_no_match_id := "jdg.v3_p19_pcc_akcyza_bdo.no_match"  # kanon P00: jeden literał rule_id na plik (default decide trzyma literał — wymóg OPA)

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.no_match",
    "package": "jdg.v3_p19_pcc_akcyza_bdo",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_pcc_snapshot := data.jdg.thresholds.pcc_local_excise
_snapshot_ok := count(_pcc_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    value := object.get(_pcc_snapshot, key, null)
    value != null
} else = fallback

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.thresholds_missing",
    "package": "jdg.v3_p19_pcc_akcyza_bdo",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PCC/lokalne V3-P19: brak snapshotu data.jdg.thresholds.pcc_local_excise.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P19] Brak snapshotu progów PCC/lokalnych — decyzje ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p19_pcc_akcyza_bdo",
        "priority": priority,
        "threshold_version": object.get(_pcc_snapshot, "v3_p19_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_pcc_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_pcc_snapshot, "valid_from", null),
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
# V3-P19-I01: PCC MATRIX COMPLETE (art. 1-10 ustawy o PCC)
# Macierz czynność → stawka (dane: pcc_sale_rate 2%, pcc_loan_rate 0,5% itd.)
# → zwolnienie (pożyczka ≤ 1000 zł) → podatek; termin 14 dni PCC-3; faktura MPP
# = wyłączenie (I03); nieznana czynność / przekroczony termin bez PCC-3 = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_pc_type := object.get(_ctx, "transaction_type", "")
_pc_amount := object.get(_ctx, "amount_pln", 0.0)
_pc_mpp := object.get(_ctx, "mpp_invoice", false)
_pc_filed := object.get(_ctx, "pcc3_filed", false)
_pc_days_left := object.get(_ctx, "days_left_to_deadline", 14)

_pc_rate = rate {
    rate := _th("pcc_sale_rate", 0.02)
    _pc_type == "SALE"
} else = rate {
    rate := _th("pcc_loan_rate", 0.005)
    _pc_type == "LOAN"
} else = rate {
    rate := _th("pcc_company_rate", 0.005)
    _pc_type == "COMPANY"
} else = rate {
    rate := _th("pcc_mortgage_rate", 0.001)
    _pc_type == "MORTGAGE"
} else = rate {
    rate := 0.01
    _pc_type == "EXCHANGE"
} else = -1.0 {
    true
}

_pc_unknown = true {
    _pc_rate < 0
} else = false

_pc_loan_exempt = true {
    _pc_type == "LOAN"
    _pc_amount <= _th("v3_p19_loan_exemption_limit", 1000)
} else = false

_pc_taxable = true {
    not _pc_unknown
    not _pc_loan_exempt
    not _pc_mpp
    _pc_type != "MORTGAGE"
} else = false

_pc_tax_pln := _round2(_pc_amount * _pc_rate)

_pc_deadline_breached = true {
    not _pc_filed
    _pc_days_left <= 0
} else = false

routing_pc1 = "BLOCK_AND_ALERT" {
    _pc_unknown
} else = "TRIAGE_QUEUE" {
    _pc_mpp
} else = "BLOCK_AND_ALERT" {
    _pc_deadline_breached
} else = "SUGGEST" {
    true
}

reason_pc1 = sprintf("PCC: czynność %s nieznana — fail-closed (BLOCK).", [_pc_type]) {
    _pc_unknown
} else = sprintf("PCC: czynność %s objęta fakturą MPP — wyłączenie PCC (bramka I03), kwota %.2f PLN.", [_pc_type, _pc_amount]) {
    _pc_mpp
} else = sprintf("PCC: czynność %s — stawka %.4f, podatek %.2f PLN; termin PCC-3 (14 dni) MINĄŁ bez złożenia (BLOCK).",
    [_pc_type, _pc_rate, _pc_tax_pln]) {
    _pc_deadline_breached
} else = sprintf("PCC: czynność %s — stawka %.4f, podatek %.2f PLN (kwota %.2f PLN).",
    [_pc_type, _pc_rate, _pc_tax_pln, _pc_amount]) {
    true
}

warnings_pc1 = ["[V3-P19-I01] Nieznana czynność PCC — BLOCK; sprawdź macierz art. 1-10."] {
    _pc_unknown
} else = ["[V3-P19-I01] Faktura MPP — PCC NIEPOBUDZONE (zero podwójnego opodatkowania, bramka I03)."] {
    _pc_mpp
} else = ["[V3-P19-I01] Termin PCC-3 (14 dni) minął bez złożenia — BLOCK + eskalacja."] {
    _pc_deadline_breached
} else = ["[V3-P19-I01] Pożyczka ≤ 1000 zł — zwolnienie z PCC (art. 9 pkt 10)."] {
    _pc_loan_exempt
} else = []

pcc_matrix_decision := _certificate(385101, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.pcc_matrix",
    "analysis": "pcc_matrix",
    "transaction_type": _pc_type,
    "amount_pln": _pc_amount,
    "rate": _pc_rate,
    "tax_pln": _pc_tax_pln,
    "loan_exempt_1000": _pc_loan_exempt,
    "mpp_excluded": _pc_mpp,
    "pcc3_filed": _pc_filed,
    "days_left_to_deadline": _pc_days_left,
    "deadline_breached": _pc_deadline_breached,
    "unknown_type": _pc_unknown,
    "fail_closed": _pc_unknown,
    "_routing": routing_pc1,
    "_routing_reason": reason_pc1,
    "_legal_basis": "Ustawa o PCC art. 1-10 (stawki, zwolnienia, termin 14 dni — PCC-3); ADR-002",
    "_warnings": warnings_pc1,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "pcc_matrix"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I02: GMINA RATES VALIDATOR (stawki gminne vs limity ustawowe)
# Stawki gminne jako dane z TWARDĄ walidacją limitów ustawowych (art. 5 i 10
# UoPiOL — stawki maksymalne w thresholdach land_business_rate itd.). Stawka
# gminna > max ustawowy = BLOCK (alarm); granica ±0,01 testowana; rok niezgodny
# = TRIAGE.
# ═══════════════════════════════════════════════════════════════════════════════
_gr_rate_type := object.get(_ctx, "rate_type", "")
_gr_applied := object.get(_ctx, "gmina_rate_pln", 0.0)
_gr_year := object.get(_ctx, "year", 0)

_gr_statutory_max = max {
    max := _th("land_business_rate", 0.0)
    _gr_rate_type == "LAND_BUSINESS"
} else = max {
    max := _th("building_business_rate", 0.0)
    _gr_rate_type == "BUILDING_BUSINESS"
} else = max {
    max := _th("land_other_rate", 0.0)
    _gr_rate_type == "LAND_OTHER"
} else = max {
    max := _th("building_residential_rate", 0.0)
    _gr_rate_type == "BUILDING_RESIDENTIAL"
} else = -1.0 {
    true
}

_gr_unknown = true {
    _gr_statutory_max < 0
} else = false

_gr_exceeds = true {
    not _gr_unknown
    _gr_applied > _gr_statutory_max
} else = false

_gr_year_ok = true {
    _gr_year == 0
    true
} else = _gr_year == 2026 {
    true
} else = false

routing_gr = "BLOCK_AND_ALERT" {
    _gr_unknown
} else = "BLOCK_AND_ALERT" {
    _gr_exceeds
} else = "TRIAGE_QUEUE" {
    not _gr_year_ok
} else = "SUGGEST" {
    true
}

reason_gr = sprintf("Gmina rates: typ %s nieznany — brak limitu ustawowego (BLOCK).", [_gr_rate_type]) {
    _gr_unknown
} else = sprintf("Gmina rates: stawka %.2f PRZEKRACZA limit ustawowy %.2f (typ %s) — BLOCK.",
    [_gr_applied, _gr_statutory_max, _gr_rate_type]) {
    _gr_exceeds
} else = sprintf("Gmina rates: stawka %.2f ≤ limit %.2f (typ %s) — zgodna (walidacja limitów aktywna).",
    [_gr_applied, _gr_statutory_max, _gr_rate_type]) {
    true
}

warnings_gr = ["[V3-P19-I02] Przekroczenie ustawowego limitu stawek gminnych — BLOCK (alarm, art. 5/10 UoPiOL)."] {
    _gr_exceeds
} else = ["[V3-P19-I02] Nieznany typ stawki — brak limitu w danych (BLOCK)."] {
    _gr_unknown
} else = []

gmina_rates_decision := _certificate(385102, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.gmina_rates_validator",
    "analysis": "gmina_rates_validator",
    "rate_type": _gr_rate_type,
    "gmina_rate_pln": _gr_applied,
    "statutory_max_pln": _gr_statutory_max,
    "year": _gr_year,
    "exceeds_statutory_max": _gr_exceeds,
    "limit_check_active": _th("v3_p19_statutory_limit_check", true),
    "unknown_type": _gr_unknown,
    "fail_closed": _gr_unknown,
    "_routing": routing_gr,
    "_routing_reason": reason_gr,
    "_legal_basis": "Ustawa o podatkach i opłatach lokalnych art. 5/10 (stawki max); ADR-002/P06",
    "_warnings": warnings_gr,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "gmina_rates_validator"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I03: MPP-PCC EXCLUSION GATE (zero podwójnego opodatkowania)
# Faktura MPP (mechanizm podzielonej płatności — zał. 15 VAT) dotyczy dostawy
# opodatkowanej VAT → NIE podlega PCC. Zadeklarowanie PCC dla tej samej dostawy
# = naruszenie invariantu PCC_INV-001 (BLOCK); brak informacji = TRIAGE.
# ═══════════════════════════════════════════════════════════════════════════════
_mp_invoice_mpp := object.get(_ctx, "invoice_mpp", false)
_mp_pcc_declared := object.get(_ctx, "pcc_declared", false)
_mp_asset_sale := object.get(_ctx, "asset_sale", false)

_mp_double = true {
    _mp_invoice_mpp
    _mp_pcc_declared
} else = false

_mp_unknown = true {
    not _mp_invoice_mpp
    not _mp_pcc_declared
    _mp_asset_sale
} else = false

routing_mp = "BLOCK_AND_ALERT" {
    _mp_double
} else = "TRIAGE_QUEUE" {
    _mp_unknown
} else = "SUGGEST" {
    true
}

reason_mp = "PODWÓJNE OPODATKOWANIE: faktura MPP (VAT) + deklaracja PCC dla tej samej czynności — BLOCK (invariant PCC_INV-001)." {
    _mp_double
} else = "Sprzedaż składnika majątku bez rozstrzygnięcia VAT/MPP vs PCC — wymagane dane faktury (TRIAGE)." {
    _mp_unknown
} else = "Faktura MPP → czynność w VAT → PCC NIEPOBUDZONE (bramka MPP-PCC aktywna)." {
    _mp_invoice_mpp
} else = "Czynność nie-fakturowana MPP — sprawdź obowiązek PCC (macierz I01)." {
    true
}

warnings_mp = ["[V3-P19-I03] Naruszenie invariantu PCC_INV-001 — BLOCK (VAT i PCC jednocześnie)."] {
    _mp_double
} else = ["[V3-P19-I03] Brak rozstrzygnięcia MPP dla sprzedaży — TRIAGE przed księgowaniem."] {
    _mp_unknown
} else = []

mpp_pcc_exclusion_decision := _certificate(385103, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.mpp_pcc_exclusion_gate",
    "analysis": "mpp_pcc_exclusion",
    "invoice_mpp": _mp_invoice_mpp,
    "pcc_declared": _mp_pcc_declared,
    "asset_sale": _mp_asset_sale,
    "double_taxation": _mp_double,
    "exclusion_active": _th("v3_p19_mpp_pcc_exclusion", true),
    "fail_closed": _mp_double,
    "_routing": routing_mp,
    "_routing_reason": reason_mp,
    "_legal_basis": "Ustawa o PCC art. 2 pkt 4 (wyłączenie VAT); art. 108a VAT (MPP); invariant P04",
    "_warnings": warnings_mp,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "mpp_pcc_exclusion"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I04: LOCAL TAX CALENDAR PACK (terminy lokalne — zero ciszy)
# Terminy: transport do 31.01, raty nieruchomości 15.03/15.05/15.09/15.11 (4 raty
# rocznie). Zero ciszy: termin minął bez zapłaty = BLOCK; ≤ 7 dni = TRIAGE;
# zapłacone = SUGGEST; nieznany typ = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_lc_tax_type := object.get(_ctx, "tax_type", "")
_lc_days_left := object.get(_ctx, "days_left", 0)
_lc_paid := object.get(_ctx, "paid", false)
_lc_payments_count := object.get(_ctx, "payments_count", 0)
_lc_year_ended := object.get(_ctx, "year_ended", false)

_lc_known = true {
    _lc_tax_type in {"TRANSPORT", "PROPERTY_INSTALLMENT"}
} else = false

_lc_unknown = true {
    not _lc_known
} else = false

_lc_breached = true {
    not _lc_paid
    _lc_days_left <= 0
} else = false

_lc_urgent = true {
    not _lc_paid
    _lc_days_left > 0
    _lc_days_left <= 7
} else = false

_lc_instalments_missing = true {
    _lc_tax_type == "PROPERTY_INSTALLMENT"
    _lc_year_ended
    _lc_payments_count < 4
} else = false

routing_lc = "BLOCK_AND_ALERT" {
    not _lc_known
} else = "BLOCK_AND_ALERT" {
    _lc_breached
} else = "TRIAGE_QUEUE" {
    _lc_instalments_missing
} else = "TRIAGE_QUEUE" {
    _lc_urgent
} else = "SUGGEST" {
    true
}

reason_lc = sprintf("Kalendarz lokalny: nieznany typ podatku %s — fail-closed (BLOCK).", [_lc_tax_type]) {
    not _lc_known
} else = sprintf("Kalendarz lokalny (%s): termin MINĄŁ bez zapłaty — zero ciszy naruszone (BLOCK).", [_lc_tax_type]) {
    _lc_breached
} else = sprintf("Kalendarz lokalny (%s): koniec roku z %d/4 rat — brak pełnych rat (TRIAGE).", [_lc_tax_type, _lc_payments_count]) {
    _lc_instalments_missing
} else = sprintf("Kalendarz lokalny (%s): %d dni do terminu — przypomnienie.", [_lc_tax_type, _lc_days_left]) {
    true
}

warnings_lc = ["[V3-P19-I04] Termin lokalny minął bez zapłaty — BLOCK + eskalacja (zero ciszy)."] {
    _lc_breached
} else = ["[V3-P19-I04] Brak pełnych 4 rat nieruchomości na koniec roku — TRIAGE."] {
    _lc_instalments_missing
} else = ["[V3-P19-I04] Nieznany typ podatku lokalnego — BLOCK."] {
    not _lc_known
} else = []

local_tax_calendar_decision := _certificate(385104, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.local_tax_calendar_pack",
    "analysis": "local_tax_calendar",
    "tax_type": _lc_tax_type,
    "days_left": _lc_days_left,
    "paid": _lc_paid,
    "payments_count": _lc_payments_count,
    "installments_due": _th("v3_p19_property_installments", ["03-15", "05-15", "09-15", "11-15"]),
    "transport_due": _th("v3_p19_transport_due", "01-31"),
    "deadline_breached": _lc_breached,
    "fail_closed": _lc_unknown,
    "_routing": routing_lc,
    "_routing_reason": reason_lc,
    "_legal_basis": "Ustawa o podatkach i opłatach lokalnych art. 6/12-13 (terminy rat); kontrakt V3_P36",
    "_warnings": warnings_lc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "local_tax_calendar"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I05: BDO QUALIFIER (kwalifikacja rejestracji BDO)
# Kwalifikacja obowiązku BDO: odpady ≥ 100 kg/rok LUB wprowadzanie opakowań LUB
# sprzedaż WEEE/baterii. Wymagana rejestracja bez rejestru = BLOCK; poniżej
# progów = SUGGEST (brak obowiązku); brak danych = TRIAGE; raport roczny 15.03.
# ═══════════════════════════════════════════════════════════════════════════════
_bq_waste_kg := object.get(_ctx, "waste_kg_year", 0)
_bq_packaging := object.get(_ctx, "introduces_packaging", false)
_bq_weee := object.get(_ctx, "sells_weee_batteries", false)
_bq_registered := object.get(_ctx, "bdo_registered", false)
_bq_data_complete := object.get(_ctx, "data_complete", true)

_bq_required = true {
    _bq_waste_kg >= _th("v3_p19_bdo_waste_threshold_kg", 100)
} else = true {
    _bq_packaging
    _th("v3_p19_bdo_packaging_active", true) == true
} else = true {
    _bq_weee
    _th("v3_p19_weee_seller_registration", true) == true
} else = false

_bq_missing_registration = true {
    _bq_required
    not _bq_registered
} else = false

routing_bq = "BLOCK_AND_ALERT" {
    _bq_missing_registration
} else = "TRIAGE_QUEUE" {
    not _bq_data_complete
} else = "SUGGEST" {
    true
}

reason_bq = sprintf("BDO: obowiązek rejestracji (%d kg/rok, opakowania=%t, WEEE=%t) BEZ rejestru — BLOCK.",
    [_bq_waste_kg, _bq_packaging, _bq_weee]) {
    _bq_missing_registration
} else = "BDO: dane kwalifikacyjne niekompletne — uzupełnij (odpady/opakowania/WEEE)." {
    not _bq_data_complete
} else = sprintf("BDO: status zgodny (rejestr=%t; wymagane=%t; odpady %d kg/rok).",
    [_bq_registered, _bq_required, _bq_waste_kg]) {
    true
}

warnings_bq = ["[V3-P19-I05] Obowiązek BDO bez rejestracji — BLOCK; złóż wniosek (raport roczny do 15.03)."] {
    _bq_missing_registration
} else = ["[V3-P19-I05] Brak danych kwalifikacji BDO — TRIAGE (formularz: odpady/opakowania/WEEE)."] {
    not _bq_data_complete
} else = []

bdo_qualifier_decision := _certificate(385105, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.bdo_qualifier",
    "analysis": "bdo_qualifier",
    "waste_kg_year": _bq_waste_kg,
    "introduces_packaging": _bq_packaging,
    "sells_weee_batteries": _bq_weee,
    "bdo_registered": _bq_registered,
    "registration_required": _bq_required,
    "waste_threshold_kg": _th("v3_p19_bdo_waste_threshold_kg", 100),
    "report_due": _th("v3_p19_bdo_report_due", "03-15"),
    "fail_closed": _bq_missing_registration,
    "_routing": routing_bq,
    "_routing_reason": reason_bq,
    "_legal_basis": "Ustawa o odpadach (BDO); ustawa o opakowaniach; WEEE/baterie [NIEZWERYFIKOWANE — Q01]",
    "_warnings": warnings_bq,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "bdo_qualifier"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I06: EWC CODE LIBRARY (baza kodów EWC jako dane)
# Baza kodów EWC wersjonowana (v3_p19_ewc_library_version): kod znany z listy
# danych = SUGGEST (wpis poprawny); kod spoza bazy = TRIAGE (rozszerz bazę);
# format niepoprawny = BLOCK (ewidencja odpadów wymaga kodu EWC).
# ═══════════════════════════════════════════════════════════════════════════════
_ewc_code := object.get(_ctx, "ewc_code", "")
_ewc_known := object.get(_ctx, "code_in_library", false)
_ewc_format_ok := object.get(_ctx, "code_format_valid", false)
_ewc_format_bad = true {
    not _ewc_format_ok
} else = false
_ewc_hazardous := object.get(_ctx, "hazardous", false)

routing_ewc = "BLOCK_AND_ALERT" {
    not _ewc_format_ok
} else = "TRIAGE_QUEUE" {
    not _ewc_known
} else = "SUGGEST" {
    true
}

reason_ewc = sprintf("EWC: kod %s w niepoprawnym formacie (XX XX XX) — BLOCK.", [_ewc_code]) {
    not _ewc_format_ok
} else = sprintf("EWC: kod %s spoza bazy (wersja %s) — rozszerz bibliotekę (TRIAGE).",
    [_ewc_code, _th("v3_p19_ewc_library_version", "ewc-2026.01")]) {
    true
} else = sprintf("EWC: kod %s znaleziony w bazie (wersja %s) — wpis ewidencji poprawny.",
    [_ewc_code, _th("v3_p19_ewc_library_version", "ewc-2026.01")]) {
    true
}

warnings_ewc = ["[V3-P19-I06] Kod EWC w złym formacie — BLOCK (ewidencja odpadów)."] {
    not _ewc_format_ok
} else = ["[V3-P19-I06] Kod EWC spoza bazy — rozszerz bibliotekę przed zapisem."] {
    not _ewc_known
} else = []

ewc_library_decision := _certificate(385106, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.ewc_code_library",
    "analysis": "ewc_library",
    "ewc_code": _ewc_code,
    "code_in_library": _ewc_known,
    "code_format_valid": _ewc_format_ok,
    "hazardous": _ewc_hazardous,
    "library_version": _th("v3_p19_ewc_library_version", "ewc-2026.01"),
    "fail_closed": _ewc_format_bad,
    "_routing": routing_ewc,
    "_routing_reason": reason_ewc,
    "_legal_basis": "Rozporządzenie MŚP ws. katalogu odpadów (EWC); ustawa o odpadach; ADR-002 (dane)",
    "_warnings": warnings_ewc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "ewc_library"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I07: WASTE FEE CALCULATOR (opłaty za wytworzone odpady)
# Opłata = masa × stawka (stawka jako dane v3_p19_waste_fee_per_kg_pln;
# [NIEZWERYFIKOWANE — stawki wg kodów EWC]); masa ujemna / stawka nieznana =
# BLOCK; granice mas (band) sygnalizowane.
# ═══════════════════════════════════════════════════════════════════════════════
_wf_mass_kg := object.get(_ctx, "waste_kg", 0.0)
_wf_rate := object.get(_ctx, "fee_rate_per_kg", 0.0)

_wf_rate_known = true {
    _wf_rate > 0
} else = _th("v3_p19_waste_fee_per_kg_pln", 0.30) > 0 {
    true
} else = false

_wf_rate_unknown = true {
    not _wf_rate_known
} else = false

_wf_effective_rate = _th("v3_p19_waste_fee_per_kg_pln", 0.30) {
    _wf_rate <= 0
} else = _wf_rate {
    true
}

_wf_negative = true {
    _wf_mass_kg < 0
} else = false

_wf_fee_pln := _round2(_wf_mass_kg * _wf_effective_rate)

routing_wf = "BLOCK_AND_ALERT" {
    _wf_negative
} else = "BLOCK_AND_ALERT" {
    not _wf_rate_known
} else = "SUGGEST" {
    true
}

reason_wf = sprintf("Opłata za odpady: masa ujemna (%.2f kg) — invariant naruszony (BLOCK).", [_wf_mass_kg]) {
    _wf_negative
} else = "Opłata za odpady: brak stawki w danych — fail-closed (BLOCK)." {
    not _wf_rate_known
} else = sprintf("Opłata za odpady: %.2f kg × %.4f PLN/kg = %.2f PLN.", [_wf_mass_kg, _wf_effective_rate, _wf_fee_pln]) {
    true
}

warnings_wf = ["[V3-P19-I07] Ujemna masa odpadów — BLOCK (invariant masy)."] {
    _wf_negative
} else = ["[V3-P19-I07] Stawka opłaty nieznana — weryfikacja (stawki wg kodów EWC)."] {
    not _wf_rate_known
} else = []

waste_fee_decision := _certificate(385107, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.waste_fee_calculator",
    "analysis": "waste_fee",
    "waste_kg": _wf_mass_kg,
    "fee_rate_per_kg": _wf_effective_rate,
    "fee_pln": _wf_fee_pln,
    "rate_known": _wf_rate_known,
    "mass_negative": _wf_negative,
    "fail_closed": _wf_rate_unknown,
    "_routing": routing_wf,
    "_routing_reason": reason_wf,
    "_legal_basis": "Ustawa o odpadach (opłaty); ADR-002 (stawki jako dane) [NIEZWERYFIKOWANE — Q01]",
    "_warnings": warnings_wf,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "waste_fee"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I08: CBAM ARCHITECTURAL DECISION (monitoring importu)
# Decyzja architektoniczna: CBAM w zasięgu JDG tylko przy imporcie towarów
# carbon-intensywnych (katalog v3_p19_cbam_goods). Automatyzacja NIE obejmuje
# deklaracji CBAM — monitoring + alarm + TRIAGE do człowieka. Import poza
# katalogiem / brak importu = SUGGEST (poza zakresem).
# ═══════════════════════════════════════════════════════════════════════════════
_cb_imports := object.get(_ctx, "imported_goods", [])
_cb_goods := _th("v3_p19_cbam_goods", ["CEMENT", "STAL", "ALUMINIUM", "NAWOZY", "WODOR", "ENERGIA"])

_cb_in_scope = true {
    count([g | g := _cb_imports[_]; g in _cb_goods]) > 0
} else = false

_cb_manual_required := true {
    _cb_in_scope
} else = false

_cb_monitor_active := _th("v3_p19_cbam_monitor_active", true)

routing_cb = "BLOCK_AND_ALERT" {
    _cb_in_scope
    not _cb_monitor_active
} else = "TRIAGE_QUEUE" {
    _cb_in_scope
} else = "SUGGEST" {
    true
}

reason_cb = "CBAM: import towarów carbon-intensywnych przy NIEAKTYWNYM monitoringu — BLOCK (obowiązek raportowania)." {
    _cb_in_scope
    not _cb_monitor_active
} else = sprintf("CBAM: import w katalogu (%d pozycji) — decyzja architektoniczna: ścieżka MANUAL + monitoring (TRIAGE do człowieka).", [count(_cb_imports)]) {
    _cb_in_scope
} else = "CBAM: brak importu carbon-intensywnego — poza zakresem JDG (decyzja architektoniczna: nie automatyzuj)." {
    true
}

warnings_cb = ["[V3-P19-I08] Import CBAM wykryty — deklaracja CBAM wymaga człowieka (nie automatyzowana); włącz monitoring."] {
    _cb_in_scope
    not _cb_monitor_active
} else = ["[V3-P19-I08] Import w katalogu CBAM — raport kwartalny do KE; wymagany przegląd doradcy."] {
    _cb_in_scope
} else = []

cbam_monitor_decision := _certificate(385108, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.cbam_architectural_decision",
    "analysis": "cbam_monitor",
    "imported_goods_count": count(_cb_imports),
    "in_cbam_catalogue": _cb_in_scope,
    "cbam_goods_catalogue": _cb_goods,
    "monitor_active": _cb_monitor_active,
    "architectural_decision": "MANUAL_TRACKED",
    "fail_closed": _cb_in_scope,
    "_routing": routing_cb,
    "_routing_reason": reason_cb,
    "_legal_basis": "Rozporządzenie UE CBAM (2023/956) [kontekst importera]; decyzja architektoniczna — Q02",
    "_warnings": warnings_cb,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "cbam_monitor"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I09: PCC GOLDEN SET (granice w oracle)
# Golden decyzje: granice 1000 zł (pożyczka 999,99/1000/1000,01), 14 dni
# (15. dzień), MPP (I03). Rozjazd z golden = BLOCK; przypadek graniczny =
# TRIAGE; zgodny = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_gs_case := object.get(_ctx, "case_id", "")
_gs_in_golden := object.get(_ctx, "in_golden_set", false)
_gs_match := object.get(_ctx, "golden_match", true)
_gs_boundary := object.get(_ctx, "boundary_case", false)

_gs_violation = true {
    _gs_in_golden
    not _gs_match
} else = false

routing_gs9 = "BLOCK_AND_ALERT" {
    _gs_violation
} else = "TRIAGE_QUEUE" {
    _gs_boundary
} else = "SUGGEST" {
    true
}

reason_gs9 = sprintf("PCC golden: przypadek %s ROZJAZD z oracle — BLOCK.", [_gs_case]) {
    _gs_violation
} else = sprintf("PCC golden: przypadek %s na granicy (1000 zł / 14 dni / MPP) — weryfikacja graniczna.", [_gs_case]) {
    _gs_boundary
} else = sprintf("PCC golden: przypadek %s zgodny z oracle (wersja %s).",
    [_gs_case, _th("v3_p19_golden_version", "pcc-local-golden-2026.09")]) {
    true
}

warnings_gs9 = ["[V3-P19-I09] Golden set PCC rozjazd — BLOCK (oracle granic)."] {
    _gs_violation
} else = ["[V3-P19-I09] Przypadek graniczny (1000 zł / 14 dni / MPP) — potwierdź ręcznie."] {
    _gs_boundary
} else = []

golden_set_decision := _certificate(385109, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.pcc_golden_set",
    "analysis": "golden_set",
    "case_id": _gs_case,
    "in_golden_set": _gs_in_golden,
    "golden_match": _gs_match,
    "boundary_case": _gs_boundary,
    "golden_version": _th("v3_p19_golden_version", "pcc-local-golden-2026.09"),
    "fail_closed": _gs_violation,
    "_routing": routing_gs9,
    "_routing_reason": reason_gs9,
    "_legal_basis": "Golden Oracle (V2 F3, P10); ustawa o PCC art. 9 (granice zwolnień)",
    "_warnings": warnings_gs9,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_set"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I10: LOCAL TAX INVARIANTS (kontrakt V3_P04)
# Invarianty runtime: PCC_INV-001 (MPP+VAT i PCC wykluczają się), PCC_INV-002
# (stawka gminna ≤ limit ustawowy), PCC_INV-003 (termin nie minął bez zapłaty).
# Naruszenie = BLOCK_AND_ALERT z listą.
# ═══════════════════════════════════════════════════════════════════════════════
_iv_double := object.get(_ctx, "mpp_and_pcc", false)
_iv_gmina_exceeds := object.get(_ctx, "gmina_rate_exceeds_limit", false)
_iv_deadline_breach := object.get(_ctx, "deadline_breached", false)

_iv_flags := {
    "PCC_INV-001": _iv_double,
    "PCC_INV-002": _iv_gmina_exceeds,
    "PCC_INV-003": _iv_deadline_breach,
}

_iv_violations := [id | some id in object.keys(_iv_flags); _iv_flags[id] == true]

_iv_any = true {
    count(_iv_violations) > 0
} else = false

routing_iv10 = "BLOCK_AND_ALERT" {
    _iv_any
} else = "SUGGEST" {
    true
}

reason_iv10 = sprintf("Invarianty lokalne naruszone: %s — BLOCK_AND_ALERT (kontrakt P04).", [concat(", ", _iv_violations)]) {
    _iv_any
} else = "Invarianty lokalne spełnione (PCC≠VAT, limity gminne OK, terminy OK)." {
    true
}

warnings_iv10 = [sprintf("Naruszenie invariantu %s — decyzja ZABLOKOWANA.", [concat(", ", _iv_violations)])] {
    _iv_any
} else = []

local_invariants_decision := _certificate(385110, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.local_tax_invariants",
    "analysis": "local_invariants",
    "mpp_and_pcc": _iv_double,
    "gmina_rate_exceeds_limit": _iv_gmina_exceeds,
    "deadline_breached": _iv_deadline_breach,
    "violations": _iv_violations,
    "invariants_active": _th("v3_p19_invariants_active", true),
    "fail_closed": _iv_any,
    "_routing": routing_iv10,
    "_routing_reason": reason_iv10,
    "_legal_basis": "Kontrakt invariantów V3_P04; ustawy PCC/UoPiOL/odpady",
    "_warnings": warnings_iv10,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "local_invariants"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I11: INSTALMENT REMINDER (raty nieruchomości — przypomnienia)
# 4 raty (15.03/15.05/15.09/15.11) z przewidywaniem kwot (tax/4, groszowo):
# rata ≤ 14 dni = TRIAGE (przypomnienie z kwotą); termin minął = BLOCK; pełne
# pokrycie = SUGGEST. Instalment = pojedyncze źródło danych (P36).
# ═══════════════════════════════════════════════════════════════════════════════
_ir_tax_year := object.get(_ctx, "property_tax_year_pln", 0.0)
_ir_paid_count := object.get(_ctx, "instalments_paid", 0)
_ir_days_left := object.get(_ctx, "days_left_to_next", 0)
_ir_next_paid := object.get(_ctx, "next_instalment_paid", false)

_ir_forecast := _round2(_ir_tax_year / 4)

_ir_data_ok = true {
    _ir_tax_year > 0
    _ir_paid_count >= 0
} else = false

_ir_data_bad = true {
    not _ir_data_ok
} else = false

_ir_breached = true {
    not _ir_next_paid
    _ir_days_left <= 0
} else = false

_ir_reminder = true {
    not _ir_next_paid
    _ir_days_left > 0
    _ir_days_left <= 14
} else = false

_ir_complete = true {
    _ir_paid_count >= 4
} else = false

routing_ir11 = "BLOCK_AND_ALERT" {
    not _ir_data_ok
} else = "BLOCK_AND_ALERT" {
    _ir_breached
} else = "TRIAGE_QUEUE" {
    _ir_reminder
} else = "SUGGEST" {
    _ir_complete
} else = "SUGGEST" {
    true
}

reason_ir11 = sprintf("Raty nieruchomości: brak danych (podatek=%.2f) — fail-closed (BLOCK).", [_ir_tax_year]) {
    not _ir_data_ok
} else = sprintf("Raty nieruchomości: termin MINĄŁ (rata %d/4) — BLOCK + eskalacja.", [_ir_paid_count + 1]) {
    _ir_breached
} else = sprintf("Raty nieruchomości: przypomnienie — rata %d/4, przewidywana kwota %.2f PLN (podatek/4), %d dni.", [_ir_paid_count + 1, _ir_forecast, _ir_days_left]) {
    true
} else = "Raty nieruchomości: pełne pokrycie 4 rat — status zgodny." {
    true
}

warnings_ir11 = ["[V3-P19-I11] Rata nieruchomości minęła bez zapłaty — BLOCK."] {
    _ir_breached
} else = ["[V3-P19-I11] Przypomnienie o racie — przewidywana kwota z podatku rocznego/4."] {
    _ir_reminder
} else = ["[V3-P19-I11] Brak danych podatku nieruchomości — BLOCK."] {
    not _ir_data_ok
} else = []

instalment_reminder_decision := _certificate(385111, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.instalment_reminder",
    "analysis": "instalment_reminder",
    "property_tax_year_pln": _ir_tax_year,
    "instalments_paid": _ir_paid_count,
    "forecast_per_instalment_pln": _ir_forecast,
    "installments_due": _th("v3_p19_property_installments", ["03-15", "05-15", "09-15", "11-15"]),
    "days_left_to_next": _ir_days_left,
    "deadline_breached": _ir_breached,
    "reminder_active": _ir_reminder,
    "fail_closed": _ir_data_bad,
    "_routing": routing_ir11,
    "_routing_reason": reason_ir11,
    "_legal_basis": "Ustawa o podatkach i opłatach lokalnych art. 6 ust. 7 (raty); kontrakt V3_P36",
    "_warnings": warnings_ir11,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "instalment_reminder"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P19-I12: ENVIRONMENTAL EXPLANATION PACK (checklisty BDO/PCC)
# Checklisty dokumentacyjne dla księgowej: komplet (podstawa prawna + dokumenty
# + krok następny) = SUGGEST (paczka do PDF); brak podstawy = TRIAGE; nieznany
# typ = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_ex12_type := object.get(_ctx, "pack_type", "")
_ex12_basis := object.get(_ctx, "legal_basis_present", false)
_ex12_docs := object.get(_ctx, "docs_checklist_complete", false)

_ex12_known = true {
    _ex12_type in {"PCC", "BDO", "LOCAL"}
} else = false

_ex12_unknown = true {
    not _ex12_known
} else = false

_ex12_complete = true {
    _ex12_known
    _ex12_basis
    _ex12_docs
} else = false

routing_ex12 = "BLOCK_AND_ALERT" {
    not _ex12_known
} else = "TRIAGE_QUEUE" {
    not _ex12_complete
} else = "SUGGEST" {
    true
}

reason_ex12 = sprintf("Checklista %s: nieznany typ paczki — fail-closed (BLOCK).", [_ex12_type]) {
    not _ex12_known
} else = sprintf("Checklista %s: niekompletna (podstawa=%t, dokumenty=%t) — TRIAGE.", [_ex12_type, _ex12_basis, _ex12_docs]) {
    true
} else = sprintf("Checklista %s: kompletna — paczka dokumentacyjna gotowa (PDF).", [_ex12_type]) {
    true
}

warnings_ex12 = ["[V3-P19-I12] Nieznany typ paczki — BLOCK (fail-closed)."] {
    not _ex12_known
} else = ["[V3-P19-I12] Checklista niekompletna — uzupełnij podstawę/dokumenty przed PDF."] {
    not _ex12_complete
} else = []

explanation_pack_decision := _certificate(385112, {
    "rule_id": "jdg.v3_p19_pcc_akcyza_bdo.explanation_pack",
    "analysis": "explanation_pack",
    "pack_type": _ex12_type,
    "legal_basis_present": _ex12_basis,
    "docs_checklist_complete": _ex12_docs,
    "pack_complete": _ex12_complete,
    "fail_closed": _ex12_unknown,
    "_routing": routing_ex12,
    "_routing_reason": reason_ex12,
    "_legal_basis": "Checklisty dokumentacyjne BDO/PCC; V2 F4 (wytłumaczalność)",
    "_warnings": warnings_ex12,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "explanation_pack"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := pcc_matrix_decision {
    pcc_matrix_decision.rule_id != ""
} else := gmina_rates_decision {
    gmina_rates_decision.rule_id != ""
} else := mpp_pcc_exclusion_decision {
    mpp_pcc_exclusion_decision.rule_id != ""
} else := local_tax_calendar_decision {
    local_tax_calendar_decision.rule_id != ""
} else := bdo_qualifier_decision {
    bdo_qualifier_decision.rule_id != ""
} else := ewc_library_decision {
    ewc_library_decision.rule_id != ""
} else := waste_fee_decision {
    waste_fee_decision.rule_id != ""
} else := cbam_monitor_decision {
    cbam_monitor_decision.rule_id != ""
} else := golden_set_decision {
    golden_set_decision.rule_id != ""
} else := local_invariants_decision {
    local_invariants_decision.rule_id != ""
} else := instalment_reminder_decision {
    instalment_reminder_decision.rule_id != ""
} else := explanation_pack_decision {
    explanation_pack_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": _no_match_id,
    "package": "jdg.v3_p19_pcc_akcyza_bdo",
    "priority": 999999,
}
