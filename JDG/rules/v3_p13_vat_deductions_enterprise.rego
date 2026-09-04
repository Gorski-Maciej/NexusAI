# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P13 VAT DEDUCTIONS / MPP / FRAUD ENTERPRISE (kampania V3 FORTRESS)
# ===============================================================================
# Warstwa odliczeń VAT ENTERPRISE: prawo do odliczenia i moment (art. 86-87 VAT),
# ograniczenia (art. 88 VAT — auta 50%, kategorie zablokowane), proporcja (art. 90),
# korekty wieloletnie (art. 91), złe długi (art. 89a/89b — 90 dni), MPP/split payment
# (art. 108a-108d — zał. 15, próg 15 000 zł brutto, sankcje 30%/100%), Biała Lista
# (art. 96b — weryfikacja > 15k), fraud detection (art. 105a-105c — sygnały z human
# review, nigdy automatyczna wina) i invarianty VAT (P04).
#
# Zasady:
#   * WSZYSTKIE progi/stawki/limity z data.jdg.thresholds.vat (ADR-002, P06
#     parametry-as-data); MPP threshold z data.jdg.thresholds.misc
#     (mpp_mandatory_threshold — kontrakt ADR-002 z raportu P13 5.3); zero hardcode.
#   * Okna temporalne (valid_from/valid_to) honorowane z snapshotu (P05).
#   * Fail-closed: brak danych / nieznany CN / offline Biała Lista / naruszenie
#     invariantu = NEEDS_ADVICE lub BLOCK_AND_ALERT — nigdy cichy AUTO_POST.
#   * Fraud: SYGNAŁ z human review (nigdy automatyczna wina) — scoring wpływa na
#     certainty_class (kontrakt V3-P03), nie na winę.
#   * Aktywacja: input.jdg_entrepreneur.v3_p13_check == true (wzorzec
#     jdg.v3_p15_crossborder); bez flagi → no_match.
#   * rule_id: jdg.v3_p13_vat_deductions.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p13_vat_deductions
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p13_vat_deductions

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p13_check", false) == true
_ctx := object.get(input, "v3_p13", {})

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p13_vat_deductions.no_match",
    "package": "jdg.v3_p13_vat_deductions",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji vat → fail-closed sentinel ──────────
_vat_snapshot := data.jdg.thresholds.vat
_misc_snapshot := data.jdg.thresholds.misc
_snapshot_ok := count(_vat_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    value := object.get(_vat_snapshot, key, null)
    value != null
} else = fallback

# MPP próg i sankcja: kanoniczne źródło w data.jdg.thresholds.misc (kontrakt P13 5.3)
_mpp_threshold = object.get(_misc_snapshot, "mpp_mandatory_threshold", 15000)
_mpp_sanction = object.get(_misc_snapshot, "mpp_sanction_rate", 0.30)

_round3(value) = floor(value * 1000) / 1000

_round_half_up(value) = result {
    scaled := value * 100
    result := (floor(scaled + 0.5)) / 100
}

_bool_str(flag) = "TAK" {
    flag
}
_bool_str(flag) = "NIE" {
    flag == false
}

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p13_vat_deductions.thresholds_missing",
    "package": "jdg.v3_p13_vat_deductions",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "VAT deductions V3-P13: brak snapshotu data.jdg.thresholds.vat.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P13] Brak snapshotu progów VAT — decyzje odliczeniowe ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p13_vat_deductions",
        "priority": priority,
        "threshold_version": object.get(_vat_snapshot, "threshold_version", "MISSING"),
        "legal_basis_version": object.get(_vat_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_vat_snapshot, "valid_from", null),
        "valid_to": object.get(_vat_snapshot, "valid_to", null),
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I01: DEDUCTION RIGHTS ENGINE (art. 86-88 VAT)
# Prawo do odliczenia: związek z czynnościami opodatkowanymi + moment odliczenia
# (art. 86b: miesiąc/3 miesiące, prefinansowanie) + ograniczenia (art. 88: kategorie
# zablokowane, auta 50%/0%/użycie mieszane). Brak dokumentu / nieznana kategoria =
# NEEDS_ADVICE. Progi jako dane (data.jdg.thresholds.vat).
# ═══════════════════════════════════════════════════════════════════════════════
_blocked_deduction(category) = true {
    category in object.get(_vat_snapshot, "blocked_deduction_categories", ["NKUP", "paliwo_osobowe", "noclegi", "gastronomia", "bez_dokumentu"])
} else = false

_moment_within_window(received_month, invoice_month, window) = true {
    received_month > 0
    (received_month - invoice_month) <= window
    (received_month - invoice_month) >= 0
} else = false

_deduction_moment = result {
    _activated
    received_month := object.get(_ctx, "invoice_received_month", 0)
    invoice_month := object.get(_ctx, "invoice_month", 0)
    window := _th("deduction_moment_months", 3)
    prefinancing := object.get(_ctx, "invoice_before_supply", false)
    result := {"month": received_month, "invoice_month": invoice_month,
               "window_months": window,
               "within_window": _moment_within_window(received_month, invoice_month, window),
               "prefinancing": prefinancing,
               "prefinancing_months": _th("deduction_prefinancing_months", 3)}
}

# Auta art. 88 ust. 2 VAT: 50% bez ewidencji (użycie mieszane), 100% z ewidencją
_car_ratio_value = full_ratio {
    car := object.get(_ctx, "is_passenger_car", false)
    car == true
    object.get(_ctx, "car_mixed_use", false) == false
    full_ratio := object.get(_vat_snapshot, "car_vat_deduction_with_log", 1.0)
} else = mixed_ratio {
    car := object.get(_ctx, "is_passenger_car", false)
    car == true
    object.get(_ctx, "car_mixed_use", false) == true
    mixed_ratio := object.get(_vat_snapshot, "car_vat_deduction_no_log", 0.5)
} else = 1.0

_car_ratio = result {
    _activated
    result := {"is_car": object.get(_ctx, "is_passenger_car", false),
               "mixed_use": object.get(_ctx, "car_mixed_use", false),
               "ratio": _car_ratio_value,
               "rule": "art. 88 ust. 2 VAT — 50%/100%"}
}

_deduction_ratio = car.ratio {
    car := _car_ratio
    car.is_car == true
} else = 1.0

_right_to_deduct = true {
    object.get(_ctx, "has_invoice_document", false) == true
    object.get(_ctx, "taxable_activity_link", false) == true
    not _blocked_deduction(object.get(_ctx, "deduction_category", ""))
} else = false

deduction_rights = result {
    _activated
    category := object.get(_ctx, "deduction_category", "")
    result := {"right_to_deduct": _right_to_deduct,
               "blocked_category": _blocked_deduction(category),
               "category": category,
               "has_document": object.get(_ctx, "has_invoice_document", false),
               "taxable_link": object.get(_ctx, "taxable_activity_link", false),
               "moment": _deduction_moment, "car": _car_ratio,
               "deduction_ratio": _deduction_ratio,
               "document_checklist": ["faktura/rachunek", "dowód zapłaty", "związek z czynnością opodatkowaną"]}
}

deduction_rights_decision := _certificate(380101, {
    "rule_id": "jdg.v3_p13_vat_deductions.deduction_rights_engine",
    "analysis": "deduction_rights",
    "deduction_rights": deduction_rights,
    "fail_closed": deduction_fail_closed,
    "_routing": routing_dr,
    "_routing_reason": reason_dr,
    "_legal_basis": "Art. 86-88 ustawy o VAT [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_dr,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "deduction_rights"
}

deduction_fail_closed = true {
    not deduction_rights.right_to_deduct
} else = false

routing_dr = "BLOCK_AND_ALERT" {
    deduction_rights.blocked_category
} else = "NEEDS_ADVICE" {
    deduction_rights.right_to_deduct == false
} else = ""

reason_dr = "Kategoria odliczenia zablokowana (art. 88 VAT) — odliczenie NKUP + sankcja." {
    deduction_rights.blocked_category
} else = "Brak pełnego łańcucha dowodów odliczenia (dokument/związek/moment) — wymagana analiza człowieka." {
    deduction_rights.right_to_deduct == false
} else = ""

warnings_dr = ["[V3-P13-I01] Kategoria zablokowana art. 88 VAT — wydatek NKUP."] {
    deduction_rights.blocked_category
} else = ["[V3-P13-I01] Odliczenie VAT wymaga uzupełnienia dowodów (dokument, związek z działalnością, moment art. 86b)."] {
    deduction_rights.right_to_deduct == false
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I02: MULTI-YEAR CORRECTION PLANNER (art. 91 VAT)
# Harmonogram korekt wieloletnich: nieruchomości 10 lat, inne środki trwałe 5 lat,
# < 15 000 zł — 1 rok; automatyczne korekty roczne (IN_PLUS/IN_MINUS) + testy
# krańcowe lat 5/10. Rok korekty poza zakresem = NEEDS_ADVICE.
# ═══════════════════════════════════════════════════════════════════════════════
_years_for(asset_kind) = years {
    asset_kind == "real_estate"
    years := _th("multi_year_years_real_estate", 10)
} else = years {
    asset_kind == "low_value"
    years := _th("multi_year_years_low_value", 1)
} else = _th("multi_year_years_other", 5)

_effective_years(acquisition, threshold, kind) = 1 {
    acquisition < threshold
} else = _years_for(kind)

_within_schedule(correction_year, years) = true {
    correction_year >= 1
    correction_year <= years
} else = false

multi_year_plan = result {
    _activated
    kind := object.get(_ctx, "asset_kind", "other")
    acquisition := object.get(_ctx, "acquisition_value_pln", 0)
    threshold := _th("asset_correction_threshold", 15000)
    years := _effective_years(acquisition, threshold, kind)
    correction_year := object.get(_ctx, "correction_year", 1)
    annual_pct := _round3(100.0 / years)
    result := {"asset_kind": kind, "acquisition_value_pln": acquisition,
               "low_value": acquisition < threshold, "years": years,
               "annual_correction_pct": annual_pct, "correction_year": correction_year,
               "within_schedule": _within_schedule(correction_year, years),
               "schedule_years": years,
               "adjustment_direction": object.get(_ctx, "adjustment_direction", "NONE")}
}

multi_year_decision := _certificate(380102, {
    "rule_id": "jdg.v3_p13_vat_deductions.multi_year_correction_planner",
    "analysis": "multi_year",
    "multi_year": multi_year_plan,
    "fail_closed": multi_year_outside,
    "_routing": routing_my,
    "_routing_reason": reason_my,
    "_legal_basis": "Art. 91 ustawy o VAT [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_my,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "multi_year"
}

multi_year_outside = true {
    not multi_year_plan.within_schedule
} else = false

routing_my = "NEEDS_ADVICE" {
    multi_year_outside
} else = ""

reason_my = sprintf("Rok korekty %d poza harmonogramem korekt wieloletnich (%d lat) — wymagana analiza człowieka.",
    [multi_year_plan.correction_year, multi_year_plan.schedule_years]) {
    multi_year_outside
} else = ""

warnings_my = ["[V3-P13-I02] Korekta wieloletnia poza harmonogramem art. 91 VAT — zweryfikuj rok korekty."] {
    multi_year_outside
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I03: BAD DEBT RADAR (art. 89a/89b VAT) — monitoring 90 dni
# Monitoring 90 dni od terminu płatności: alert + automatyczna korekta in minus
# (bad_debt_creditor_correction: days_overdue >= 90 + debtor_notified).
# Brak potwierdzenia zawiadomienia dłużnika = NEEDS_ADVICE (fail-closed).
# ═══════════════════════════════════════════════════════════════════════════════
_bad_debt_auto = true {
    object.get(_ctx, "days_overdue", 0) >= _th("bad_debt_days", 90)
    object.get(_ctx, "debtor_notified", false) == true
} else = false

_bad_debt_next = "AUTO_CORRECTION_IN_MINUS" {
    _bad_debt_auto
} else = "MONITOR"

bad_debt_status = result {
    _activated
    days := object.get(_ctx, "days_overdue", 0)
    result := {"days_overdue": days, "threshold_days": _th("bad_debt_days", 90),
               "matured": days >= _th("bad_debt_days", 90),
               "debtor_notified": object.get(_ctx, "debtor_notified", false),
               "auto_in_minus_correction": _bad_debt_auto,
               "monitoring_active": true,
               "next_action": _bad_debt_next}
}

bad_debt_decision := _certificate(380103, {
    "rule_id": "jdg.v3_p13_vat_deductions.bad_debt_radar",
    "analysis": "bad_debt",
    "bad_debt": bad_debt_status,
    "fail_closed": bad_debt_missing_notice,
    "_routing": routing_bd,
    "_routing_reason": reason_bd,
    "_legal_basis": "Art. 89a/89b ustawy o VAT [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_bd,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "bad_debt"
}

bad_debt_missing_notice = true {
    bad_debt_status.matured
    bad_debt_status.debtor_notified == false
} else = false

routing_bd = "NEEDS_ADVICE" {
    bad_debt_missing_notice
} else = "TRIAGE_QUEUE" {
    bad_debt_status.auto_in_minus_correction
} else = ""

reason_bd = "Należność przeterminowana ≥ 90 dni bez potwierdzonego zawiadomienia dłużnika — korekta in minus wymaga dowodu." {
    bad_debt_missing_notice
} else = "Automatyczna korekta in minus (ulga na złe długi) — wymagany wpis w JPK." {
    bad_debt_status.auto_in_minus_correction
} else = ""

warnings_bd = ["[V3-P13-I03] Zawiadomienie dłużnika (art. 89a ust. 2) wymagane przed korektą in minus."] {
    bad_debt_missing_notice
} else = ["[V3-P13-I03] Ulga na złe długi: korekta in minus naliczona — ujęcie w JPK_V7."] {
    bad_debt_status.auto_in_minus_correction
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I04: MPP OBLIGATION DETECTOR (art. 108a-108d VAT)
# Auto-detekcja MPP end-to-end: faktura (CN z zał. 15 + kwota brutto ≥ 15 000 zł)
# → obowiązek rachunku VAT → brak MPP = sankcja 30% + NKUP + solidarna
# odpowiedzialność. Walidacja brutto (próg 15k liczy się od kwoty BRUTTO).
# ═══════════════════════════════════════════════════════════════════════════════
_mpp_obligatory = true {
    object.get(_ctx, "invoice_brutto_pln", 0) >= _mpp_threshold
    object.get(_ctx, "annex15_cn_match", false) == true
} else = false

_mpp_violation = true {
    _mpp_obligatory
    object.get(_ctx, "split_payment_used", false) == false
} else = false

mpp_obligation = result {
    _activated
    brutto := object.get(_ctx, "invoice_brutto_pln", 0)
    violation := _mpp_violation
    result := {"invoice_brutto_pln": brutto,
               "invoice_netto_pln": object.get(_ctx, "invoice_netto_pln", 0),
               "annex15_cn_match": object.get(_ctx, "annex15_cn_match", false),
               "threshold_brutto_pln": _mpp_threshold,
               "obligatory": _mpp_obligatory,
               "split_payment_used": object.get(_ctx, "split_payment_used", false),
               "violation": violation,
               "sanction_30pct": violation,
               "nkup": violation,
               "solidary_liability": violation,
               "gross_basis": brutto >= _mpp_threshold}
}

mpp_decision := _certificate(380104, {
    "rule_id": "jdg.v3_p13_vat_deductions.mpp_obligation_detector",
    "analysis": "mpp",
    "mpp": mpp_obligation,
    "fail_closed": mpp_obligation.violation,
    "_routing": routing_mpp,
    "_routing_reason": reason_mpp,
    "_legal_basis": "Art. 108a-108d ustawy o VAT [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_mpp,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "mpp"
}

routing_mpp = "BLOCK_AND_ALERT" {
    mpp_obligation.violation
} else = ""

reason_mpp = "Obowiązek MPP (art. 108a VAT) bez podzielonej płatności — sankcja 30% + NKUP + solidarna odpowiedzialność." {
    mpp_obligation.violation
} else = ""

warnings_mpp = ["[V3-P13-I04] Faktura objęta MPP (zał. 15 + ≥ 15 000 zł brutto) — wymagany rachunek VAT; sankcja 30% + NKUP."] {
    mpp_obligation.violation
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I05: ANNEX 15 AS VERSIONED DATA (zał. 15 VAT)
# Lista towarów/usług MPP (CN ~150 pozycji) jako DANE wersjonowane
# (data.jdg.thresholds.vat.annex15_cn_codes) z walidacją PKWiU/CN i historią zmian.
# Nieznany CN / brak danych = NEEDS_ADVICE (nigdy automatyczne wyłączenie).
# ═══════════════════════════════════════════════════════════════════════════════
_cn_prefix_match(code, prefix) = true {
    startswith(code, prefix)
}

_annex15_unknown = true {
    count(object.get(_vat_snapshot, "annex15_cn_codes", [])) == 0
} else = true {
    object.get(_ctx, "cn_code", "") != ""
    count(_annex15_matched) == 0
} else = false

_annex15_matched = [p | p := object.get(_vat_snapshot, "annex15_cn_codes", [])[_]; _cn_prefix_match(object.get(_ctx, "cn_code", ""), p)]

annex15_status = result {
    _activated
    result := {"cn_code": object.get(_ctx, "cn_code", ""),
               "annex15_matched": count(_annex15_matched) > 0,
               "matched_prefixes": _annex15_matched,
               "data_version": object.get(_vat_snapshot, "annex15_data_version", "MISSING"),
               "data_complete": count(object.get(_vat_snapshot, "annex15_cn_codes", [])) > 0,
               "valid_from": object.get(_vat_snapshot, "annex15_valid_from", "MISSING")}
}

annex15_decision := _certificate(380105, {
    "rule_id": "jdg.v3_p13_vat_deductions.annex15_as_versioned_data",
    "analysis": "annex15",
    "annex15": annex15_status,
    "fail_closed": _annex15_unknown,
    "_routing": routing_a15,
    "_routing_reason": reason_a15,
    "_legal_basis": "Załącznik 15 ustawy o VAT (MPP) [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_a15,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "annex15"
}

routing_a15 = "NEEDS_ADVICE" {
    _annex15_unknown
} else = ""

reason_a15 = "Nieznany/wymagający weryfikacji kod CN względem zał. 15 VAT (dane wersjonowane) — analiza człowieka." {
    _annex15_unknown
} else = ""

warnings_a15 = [sprintf("[V3-P13-I05] Kod CN poza danymi zał. 15 (wersja %s) — nie przesądzaj o MPP bez weryfikacji.", [annex15_status.data_version])] {
    _annex15_unknown
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I06: WHITE LIST GATE (art. 96b VAT) — Biała Lista
# Weryfikacja przed przelewem > 15 000 zł: status na Białej Liście + cache TTL +
# fallback offline (NEEDS_ADVICE) + audit weryfikacji. Nie na liście = BLOCK
# (sankcja 20% + NKUP + solidarna odpowiedzialność).
# ═══════════════════════════════════════════════════════════════════════════════
_whitelist_required = true {
    object.get(_ctx, "payment_amount_pln", 0) >= _th("whitelist_check_threshold_pln", 15000)
} else = false

_whitelist_violation = true {
    _whitelist_required
    object.get(_ctx, "counterparty_on_whitelist", null) == false
} else = false

_whitelist_offline = true {
    _whitelist_required
    object.get(_ctx, "counterparty_on_whitelist", null) == null
} else = false

whitelist_status = result {
    _activated
    required := _whitelist_required
    on_list := object.get(_ctx, "counterparty_on_whitelist", null)
    violation := _whitelist_violation
    result := {"payment_amount_pln": object.get(_ctx, "payment_amount_pln", 0),
               "threshold_pln": _th("whitelist_check_threshold_pln", 15000),
               "verification_required": required,
               "whitelist_checked": object.get(_ctx, "whitelist_checked", false),
               "counterparty_on_whitelist": on_list, "violation": violation,
               "cache_ttl_hours": _th("whitelist_cache_ttl_hours", 24),
               "fallback_mode": _th("whitelist_fallback_mode", "NEEDS_ADVICE"),
               "sanction_20pct": violation,
               "audit_entry": required}
}

whitelist_decision := _certificate(380106, {
    "rule_id": "jdg.v3_p13_vat_deductions.white_list_gate",
    "analysis": "whitelist",
    "whitelist": whitelist_status,
    "fail_closed": whitelist_fail_closed,
    "_routing": routing_wl,
    "_routing_reason": reason_wl,
    "_legal_basis": "Art. 96b ustawy o VAT [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_wl,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "whitelist"
}

whitelist_fail_closed = true {
    _whitelist_offline
} else = true {
    _whitelist_violation
} else = false

routing_wl = "BLOCK_AND_ALERT" {
    _whitelist_violation
} else = "NEEDS_ADVICE" {
    _whitelist_offline
} else = ""

reason_wl = "Kontrahent nie figuruje na Białej Liście przy płatności > 15 000 zł — sankcja 20% + NKUP + solidarna odpowiedzialność." {
    _whitelist_violation
} else = "Brak statusu Białej Listy (offline/niezweryfikowano) — decyzja płatnicza wymaga człowieka." {
    _whitelist_offline
} else = ""

warnings_wl = ["[V3-P13-I06] Płatność do kontrahenta spoza Białej Listy (art. 96b VAT) — sankcja 20% + NKUP."] {
    _whitelist_violation
} else = ["[V3-P13-I06] Biała Lista offline/niezweryfikowana — płatność wymaga decyzji człowieka (fallback NEEDS_ADVICE)."] {
    _whitelist_offline
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I07: FRAUD SIGNAL FRAMEWORK (art. 105a-105c VAT)
# Graf transakcji → sygnały (puste faktury, karuzele, shell company, MTIC) →
# human review WYMUSZONY (nigdy automatyczna wina). Scoring 0-100 wpływa na
# certainty_class (kontrakt V3-P03); wysokie ryzyko = MANUAL_REVIEW, nie kara.
# ═══════════════════════════════════════════════════════════════════════════════
_fraud_risk(score, high, medium) = "HIGH" {
    score >= high
} else = "MEDIUM" {
    score >= medium
} else = "LOW"

_fraud_mode(risk) = "MANUAL_REVIEW" {
    risk == "HIGH"
} else = "NEEDS_ADVICE" {
    risk == "MEDIUM"
} else = "AUTO_POST_ALLOWED"

_fraud_review = true {
    _fraud_risk(object.get(_ctx, "counterparty_risk_score", 0),
                object.get(_vat_snapshot, "fraud_score_high", 60),
                object.get(_vat_snapshot, "fraud_score_medium", 30)) == "HIGH"
} else = true {
    _fraud_risk(object.get(_ctx, "counterparty_risk_score", 0),
                object.get(_vat_snapshot, "fraud_score_high", 60),
                object.get(_vat_snapshot, "fraud_score_medium", 30)) == "MEDIUM"
} else = false

fraud_signals = result {
    _activated
    score := object.get(_ctx, "counterparty_risk_score", 0)
    risk := _fraud_risk(score, object.get(_vat_snapshot, "fraud_score_high", 60),
                        object.get(_vat_snapshot, "fraud_score_medium", 30))
    result := {"signals": object.get(_ctx, "fraud_signals", []),
               "is_fraud_graph_match": object.get(_ctx, "is_fraud_graph_match", false),
               "empty_invoice_signal": object.get(_ctx, "empty_invoice_signal", false),
               "carousel_signal": object.get(_ctx, "carousel_signal", false),
               "counterparty_risk_score": score, "risk_level": risk,
               "human_review_required": _th("fraud_human_review_required", true),
               "never_auto_conviction": true,
               "decision_mode": _fraud_mode(risk)}
}

fraud_decision := _certificate(380107, {
    "rule_id": "jdg.v3_p13_vat_deductions.fraud_signal_framework",
    "analysis": "fraud",
    "fraud": fraud_signals,
    "fail_closed": _fraud_review,
    "_routing": routing_fr,
    "_routing_reason": reason_fr,
    "_legal_basis": "Art. 105a-105c ustawy o VAT [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_fr,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "fraud"
}

routing_fr = "MANUAL_REVIEW" {
    fraud_signals.risk_level == "HIGH"
} else = "NEEDS_ADVICE" {
    fraud_signals.risk_level == "MEDIUM"
} else = ""

reason_fr = "Wysokie ryzyko fraudu (scoring ≥ 60) — SYGNAŁ do human review; nigdy automatyczna wina." {
    fraud_signals.risk_level == "HIGH"
} else = "Podwyższone ryzyko fraudu (scoring ≥ 30) — wymagana weryfikacja człowieka." {
    fraud_signals.risk_level == "MEDIUM"
} else = ""

warnings_fr = ["[V3-P13-I07] Sygnał fraudu — human review obowiązkowy (kontrakt V3-P03: scoring wpływa na pewność, nie na winę)."] {
    _fraud_review
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I08: PROPORTION PRECISION ENGINE (art. 90 VAT)
# Proporcja z groszówką: factor = obrót opodatkowany / obrót ogółem, zaokrąglenie
# do 0,001; granice 2%/98% (poniżej = 0%, powyżej = 100%); test graniczny 1%
# (98% vs 100%); pre-proporcja nowego podatnika (art. 90 ust. 8-10) z obrotami
# planowanymi i korektą wstępną.
# ═══════════════════════════════════════════════════════════════════════════════
_proportion_ratio(factor, min_pct, max_pct) = 0.0 {
    factor < min_pct
} else = 1.0 {
    factor > max_pct
} else = factor

_pre_proportion(planned, planned_exempt) = _round3(planned / (planned + planned_exempt)) {
    planned > 0
}

_pre_proportion_for_new_taxpayer(planned, planned_exempt, new_taxpayer) = value {
    new_taxpayer == true
    planned > 0
    value := _pre_proportion(planned, planned_exempt)
} else = null

_proportion_factor = _round3(object.get(_ctx, "taxable_turnover_pln", 0) / object.get(_ctx, "total_turnover_pln", 0)) {
    object.get(_ctx, "total_turnover_pln", 0) > 0
} else = 0

_boundary_1pct_test(factor) = true {
    abs(factor - 1.0) <= 0.01
} else = true {
    factor >= 0.98
} else = false

proportion = result {
    _activated
    new_taxpayer := object.get(_ctx, "is_new_taxpayer", false)
    planned := object.get(_ctx, "planned_turnover_pln", 0)
    factor := _proportion_factor
    pre_proportion := _pre_proportion_for_new_taxpayer(planned, object.get(_ctx, "planned_exempt_pln", 0), new_taxpayer)
    result := {"taxable_turnover_pln": object.get(_ctx, "taxable_turnover_pln", 0),
               "total_turnover_pln": object.get(_ctx, "total_turnover_pln", 0),
               "factor_rounded": factor,
               "deduction_ratio": _proportion_ratio(factor,
                                                    _th("proportion_min_threshold", 0.02),
                                                    _th("proportion_max_threshold", 0.98)),
               "min_pct": _th("proportion_min_threshold", 0.02),
               "max_pct": _th("proportion_max_threshold", 0.98),
               "boundary_1pct_test": _boundary_1pct_test(factor),
               "is_new_taxpayer": new_taxpayer, "pre_proportion": pre_proportion,
               "preliminary_correction": pre_proportion != null,
               "rounding_scale": "0.001"}
}

proportion_decision := _certificate(380108, {
    "rule_id": "jdg.v3_p13_vat_deductions.proportion_precision_engine",
    "analysis": "proportion",
    "proportion": proportion,
    "fail_closed": proportion_no_data,
    "_routing": routing_pp,
    "_routing_reason": reason_pp,
    "_legal_basis": "Art. 90 ustawy o VAT [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_pp,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "proportion"
}

proportion_no_data = true {
    proportion.total_turnover_pln == 0
} else = false

routing_pp = "NEEDS_ADVICE" {
    proportion_no_data
} else = ""

reason_pp = "Brak obrotu ogółem — proporcja art. 90 niewyliczalna; wymagana analiza człowieka." {
    proportion_no_data
} else = ""

warnings_pp = ["[V3-P13-I08] Brak danych obrotów — proporcja art. 90 VAT wymaga uzupełnienia."] {
    proportion_no_data
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I09: VAT BALANCE INVARIANTS (art. 86, 89a/89b, 106e VAT) → P04
# Invarianty runtime: (1) odliczenia ≤ należny, (2) symetria korekt
# in_minus = in_plus (art. 89a/89b), (3) spójność JPK_V7 (art. 106e).
# Naruszenie = BLOCK_AND_ALERT (P04; nigdy cichy AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
_all_invariants_ok = true {
    object.get(_ctx, "input_vat_pln", 0) <= object.get(_ctx, "output_vat_pln", 0)
    object.get(_ctx, "corrections_in_minus_pln", 0) == object.get(_ctx, "corrections_in_plus_pln", 0)
    object.get(_ctx, "jpk_v7_coherent", true) == true
} else = false

vat_invariants = result {
    _activated
    result := {"input_vat_pln": object.get(_ctx, "input_vat_pln", 0),
               "output_vat_pln": object.get(_ctx, "output_vat_pln", 0),
               "deduction_le_due_ok": object.get(_ctx, "input_vat_pln", 0) <= object.get(_ctx, "output_vat_pln", 0),
               "correction_symmetry_ok": object.get(_ctx, "corrections_in_minus_pln", 0) == object.get(_ctx, "corrections_in_plus_pln", 0),
               "jpk_v7_coherent": object.get(_ctx, "jpk_v7_coherent", true),
               "all_ok": _all_invariants_ok}
}

vat_balance_decision := _certificate(380109, {
    "rule_id": "jdg.v3_p13_vat_deductions.vat_balance_invariants",
    "analysis": "vat_balance",
    "vat_invariants": vat_invariants,
    "fail_closed": vat_invariants_fail,
    "_routing": routing_vb,
    "_routing_reason": reason_vb,
    "_legal_basis": "Art. 86, 89a/89b, 106e ustawy o VAT; P04 invarianty runtime [NIEZWERYFIKOWANE]",
    "_warnings": warnings_vb,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "vat_balance"
}

vat_invariants_fail = true {
    not vat_invariants.all_ok
} else = false

routing_vb = "BLOCK_AND_ALERT" {
    vat_invariants_fail
} else = ""

reason_vb = "Naruszenie invariantu VAT (odliczenia > należny / asymetria korekt / niespójność JPK) — decyzja zablokowana." {
    vat_invariants_fail
} else = ""

warnings_vb = ["[V3-P13-I09] Invariant VAT naruszony (P04) — blokada do czasu usunięcia niezgodności."] {
    vat_invariants_fail
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I10: VAT STRESS LAB — scenariusze obciążeniowe
# Scenariusze stress (1000 faktur MPP jednocześnie, korekta wieloletnia masowa,
# fraud łańcuchowy) z testami wydajności/poprawności i metrykami P37
# (latency, throughput, error rate). Wynik = raport, nigdy zmiana decyzji.
# ═══════════════════════════════════════════════════════════════════════════════
_scenario_known = true {
    object.get(_ctx, "scenario_type", "") in {"mpp_burst", "correction_burst", "fraud_chain"}
} else = false

_stress_over_target = true {
    _scenario_known
    object.get(_ctx, "scenario_volume", 0) > _th("stress_scenario_size", 1000)
} else = false

stress_report = result {
    _activated
    result := {"scenario_type": object.get(_ctx, "scenario_type", ""),
               "scenario_volume": object.get(_ctx, "scenario_volume", 0),
               "scenario_known": _scenario_known,
               "target_volume": _th("stress_scenario_size", 1000),
               "latency_budget_ms": _th("stress_latency_budget_ms", 1000),
               "throughput_target": _th("stress_throughput_target", 100),
               "mode": "REPORT_ONLY", "no_decision_change": true}
}

stress_decision := _certificate(380110, {
    "rule_id": "jdg.v3_p13_vat_deductions.vat_stress_lab",
    "analysis": "stress",
    "stress": stress_report,
    "fail_closed": stress_unknown,
    "_routing": routing_st,
    "_routing_reason": reason_st,
    "_legal_basis": "P37 obserwowalność; P39 bramki CI [NIEZWERYFIKOWANE]",
    "_warnings": warnings_st,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "stress"
}

stress_unknown = true {
    not _scenario_known
} else = false

routing_st = "NEEDS_ADVICE" {
    stress_unknown
} else = "SUGGEST" {
    _stress_over_target
} else = ""

reason_st = "Nieznany scenariusz stress VAT — brak definicji; wymagana analiza człowieka." {
    stress_unknown
} else = "Scenariusz stress przekracza wolumen docelowy — zaplanuj skalowanie (metryki P37)." {
    _stress_over_target
} else = ""

warnings_st = ["[V3-P13-I10] Scenariusz stress nieznany — dodaj definicję do VAT Stress Lab."] {
    stress_unknown
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I11: CORRECTION SYMMETRY GUARD (art. 89a/89b VAT)
# Gate CI na korekty art. 89a/89b (90 dni) + symetria korekt: korekta in minus
# zawsze odpowiada korekcie in plus (ta sama faktura/zdarzenie); audytowalność.
# ═══════════════════════════════════════════════════════════════════════════════
_correction_all_ok = true {
    object.get(_ctx, "correction_in_minus_pln", 0) == object.get(_ctx, "correction_in_plus_pln", 0)
    object.get(_ctx, "correction_event_id", "") != ""
    _gate_90_ok
} else = false

_gate_90_ok = true {
    object.get(_ctx, "days_overdue", 0) >= _th("bad_debt_days", 90)
} else = true {
    object.get(_ctx, "days_overdue", 0) == 0
} else = false

correction_symmetry = result {
    _activated
    result := {"event_id": object.get(_ctx, "correction_event_id", ""),
               "in_minus_pln": object.get(_ctx, "correction_in_minus_pln", 0),
               "in_plus_pln": object.get(_ctx, "correction_in_plus_pln", 0),
               "symmetric": object.get(_ctx, "correction_in_minus_pln", 0) == object.get(_ctx, "correction_in_plus_pln", 0),
               "gate_90_days_ok": _gate_90_ok,
               "auditable": object.get(_ctx, "correction_event_id", "") != "",
               "all_ok": _correction_all_ok}
}

correction_symmetry_decision := _certificate(380111, {
    "rule_id": "jdg.v3_p13_vat_deductions.correction_symmetry_guard",
    "analysis": "correction_symmetry",
    "correction_symmetry": correction_symmetry,
    "fail_closed": correction_symmetry_fail,
    "_routing": routing_cs,
    "_routing_reason": reason_cs,
    "_legal_basis": "Art. 89a/89b ustawy o VAT [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_cs,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "correction_symmetry"
}

correction_symmetry_fail = true {
    not correction_symmetry.all_ok
} else = false

routing_cs = "BLOCK_AND_ALERT" {
    correction_symmetry_fail
} else = ""

reason_cs = "Asymetria korekt (in_minus ≠ in_plus) / brak event_id / bramka 90 dni — korekta zablokowana." {
    correction_symmetry_fail
} else = ""

warnings_cs = ["[V3-P13-I11] Korekta niesymetryczna lub bez identyfikatora zdarzenia — blokada do audytu."] {
    correction_symmetry_fail
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P13-I12: PAYMENT SAFE-PAY ADVISOR (art. 96b/108a VAT)
# Doradca płatności: kontrahent (counterparty_risk_score) + MPP (obowiązek + użycie)
# + Biała Lista (status) → „bezpiecznie zapłać tak” (SUGGEST) lub NEEDS_ADVICE.
# Nigdy automatyczny nakaz płatności — rekomendacja z pełnym łańcuchem dowodów.
# ═══════════════════════════════════════════════════════════════════════════════
_safe_pay_verdict(safe) = "BEZPIECZNIE_ZAPŁAĆ_TAK" {
    safe == true
} else = "NEEDS_ADVICE"

_safe_to_pay = true {
    object.get(_ctx, "counterparty_risk_score", 0) < object.get(_vat_snapshot, "fraud_score_high", 60)
    object.get(_ctx, "counterparty_on_whitelist", null) == true
    _mpp_ok
} else = false

_mpp_ok = true {
    object.get(_ctx, "mpp_required", false) == false
} else = true {
    object.get(_ctx, "mpp_required", false) == true
    object.get(_ctx, "mpp_used", false) == true
} else = false

safe_pay = result {
    _activated
    safe := _safe_to_pay
    result := {"payment_amount_pln": object.get(_ctx, "payment_amount_pln", 0),
               "counterparty_risk_score": object.get(_ctx, "counterparty_risk_score", 0),
               "counterparty_ok": object.get(_ctx, "counterparty_risk_score", 0) < object.get(_vat_snapshot, "fraud_score_high", 60),
               "whitelist_ok": object.get(_ctx, "counterparty_on_whitelist", null) == true,
               "mpp_ok": _mpp_ok, "safe_to_pay": safe,
               "verdict": _safe_pay_verdict(safe)}
}

safe_pay_decision := _certificate(380112, {
    "rule_id": "jdg.v3_p13_vat_deductions.payment_safe_pay_advisor",
    "analysis": "safe_pay",
    "safe_pay": safe_pay,
    "fail_closed": safe_pay_fail_closed,
    "_routing": routing_sp,
    "_routing_reason": reason_sp,
    "_legal_basis": "Art. 96b, 108a ustawy o VAT [NIEZWERYFIKOWANE: ISAP w CI]",
    "_warnings": warnings_sp,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "safe_pay"
}

safe_pay_fail_closed = true {
    safe_pay.safe_to_pay == false
} else = false

routing_sp = "SUGGEST" {
    safe_pay.safe_to_pay
} else = "NEEDS_ADVICE" {
    not safe_pay.safe_to_pay
} else = ""

reason_sp = "Kontrahent + MPP + Biała Lista — pełny łańcuch dowodów: bezpiecznie zapłać (decyzja człowieka)." {
    safe_pay.safe_to_pay
} else = "Brak pełnego łańcucha bezpieczeństwa płatności (kontrahent/MPP/Biała Lista) — NEEDS_ADVICE." {
    not safe_pay.safe_to_pay
} else = ""

warnings_sp = ["[V3-P13-I12] Płatność bezpieczna wg kryteriów (kontrahent, MPP, Biała Lista) — rekomendacja SUGGEST."] {
    safe_pay.safe_to_pay
} else = ["[V3-P13-I12] Płatność wymaga decyzji człowieka — brak pełnego łańcucha bezpieczeństwa."] {
    not safe_pay.safe_to_pay
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny, pierwszy match wygrywa)
# ═══════════════════════════════════════════════════════════════════════════════
default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p13_vat_deductions.no_match",
    "package": "jdg.v3_p13_vat_deductions",
    "priority": 999999,
}

decide := fail_closed_decision {
    not _snapshot_ok
} else := deduction_rights_decision {
    deduction_rights_decision.rule_id != ""
} else := multi_year_decision {
    multi_year_decision.rule_id != ""
} else := bad_debt_decision {
    bad_debt_decision.rule_id != ""
} else := mpp_decision {
    mpp_decision.rule_id != ""
} else := annex15_decision {
    annex15_decision.rule_id != ""
} else := whitelist_decision {
    whitelist_decision.rule_id != ""
} else := fraud_decision {
    fraud_decision.rule_id != ""
} else := proportion_decision {
    proportion_decision.rule_id != ""
} else := vat_balance_decision {
    vat_balance_decision.rule_id != ""
} else := stress_decision {
    stress_decision.rule_id != ""
} else := correction_symmetry_decision {
    correction_symmetry_decision.rule_id != ""
} else := safe_pay_decision {
    safe_pay_decision.rule_id != ""
} else := default_decide {
    true
}