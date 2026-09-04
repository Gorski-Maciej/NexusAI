# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P17 ORDYNACJA PODATKOWA — OBRONA / ODSETKI / PRZEDAWNIENIE
# / GAAR / PROWADZENIE SPRAW ENTERPRISE (V3 FORTRESS)
# ===============================================================================
# Warstwa obronna ORDYNACJI ENTERPRISE — 12 innowacji (I01–I12):
#   I01 Interest Precision Engine (art. 56 OP — odsetki groszowe z kapitalizacją
#       miesięczną, stawki jako dane z valid_from, temporalność retro),
#   I02 Limitation Sentinel (art. 70-72 OP — kalendarz przedawnienia 31.12+5,
#       zawieszenia art. 71, alerty 90/60/30, interwencje),
#   I03 GAAR Shield Framework (art. 119a OP — scoring OCHRONNY: checklista
#       wartości dodanej, MAE 1 mln, ścieżka interpretacji — NIE wina),
#   I04 Procedural Deadline Constitution (terminy 7/14/30 dni — ZERO CISZY:
#       brak reakcji = alarm + eskalacja),
#   I05 Active Correction Advisor (art. 81 OP — korekta czynna przed wszczęciem
#       z benefitami kar; uzupełniająca po wszczęciu z konsekwencjami),
#   I06 AUD Benefit Tracker (art. 30a/30b OP — dobrowolne ujawnienie: benefit
#       redukcji stawki i monitoring naruszeń warunków),
#   I07 Ruling Autodrafter 4-Eyes (wniosek KIS — kompletność formalna + review
#       prawnika; nigdy wysyłka bez 4-eyes),
#   I08 Proceeding Timeline (czynności→postępowanie→odwołanie→WSA z terminami
#       i dowodami — zero ciszy),
#   I09 Defense Packet Generator (paczka obronna: odpowiedź, dokumenty, dowody,
#       review — checklista braków),
#   I10 Interpretation Library (baza interpretacji KIS per przepis — LKG P01;
#       sentinel zmiany prawa = utrata ochrony),
#   I11 ORD Invariants Pack (kontrakt V3_P04: odsetki ≥ 0, przedawnienie nie
#       wcześniej niż koniec 5. roku, korekta zawsze audytowana),
#   I12 Litigation Stress Lab (symulatory: odsetki 10 lat, wielokrotne
#       zawieszenia, apelacja w ostatnim dniu — zawsze fail-closed).
#
# Zasady:
#   * WSZYSTKIE limity/stopy/progi z data.jdg.thresholds.ord (sekcja v3_p17_*)
#     — ADR-002 (P06 parametry-as-data); okna temporalne valid_from (P05).
#   * FAIL-CLOSED: brak danych / konflikt / naruszenie invariantu (P04) =
#     NEEDS_ADVICE lub BLOCK_AND_ALERT — nigdy cichy AUTO_POST (AP07).
#   * GAAR = scoring ochronny (certainty_class P03), NIGDY automatyczna wina.
#   * Aktywacja: input.jdg_entrepreneur.v3_p17_check == true (wzorzec
#     jdg.v3_p16_ksef_jpk); bez flagi → no_match.
#   * rule_id: jdg.v3_p17_ordynacja_obrona.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p17_ordynacja_obrona
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p17_ordynacja_obrona

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p17_check", false) == true
_ctx := object.get(input, "v3_p17", {})

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p17_ordynacja_obrona.no_match",
    "package": "jdg.v3_p17_ordynacja_obrona",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji ord → fail-closed sentinel ──────────
_ord_snapshot := data.jdg.thresholds.ord
_snapshot_ok := count(_ord_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    value := object.get(_ord_snapshot, key, null)
    value != null
} else = fallback

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p17_ordynacja_obrona.thresholds_missing",
    "package": "jdg.v3_p17_ordynacja_obrona",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ordynacja V3-P17: brak snapshotu data.jdg.thresholds.ord.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P17] Brak snapshotu progów Ordynacji — decyzje obronne ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p17_ordynacja_obrona",
        "priority": priority,
        "threshold_version": object.get(_ord_snapshot, "v3_p17_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_ord_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_ord_snapshot, "v3_p17_interest_rates_valid_from", null),
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
# V3-P17-I01: INTEREST PRECISION ENGINE (art. 56 OP)
# Odsetki z groszową precyzją: stawka jako dane (v3_p17_interest_rate_annual z
# valid_from), kapitalizacja miesięczna (ostatni dzień miesiąca — model
# składany), zaokrąglenie half-up do 0,01, temporalność retro (P05): naliczanie
# przed valid_from stawki = sygnał. Naruszenie invariantu (odsetki < 0) = BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_ie_principal := object.get(_ctx, "principal_pln", 0.0)
_ie_days := object.get(_ctx, "days", 0)
_ie_months := object.get(_ctx, "months", 0)
_ie_arrears_since := object.get(_ctx, "arrears_since", "")

_ie_annual_rate = rate {
    override := object.get(_ctx, "rate_override_annual", 0.0)
    override > 0
    rate := override
} else = _th("v3_p17_interest_rate_annual", 0.08)

_ie_compound(principal, rmonthly, months) = result {
    months > 0
    factors := [f | some i in numbers.range(1, months); f := 1 + rmonthly]
    result := principal * product(factors) - principal
} else = 0.0 {
    true
}

_ie_use_compound = true {
    _ie_months > 0
    object.get(_ctx, "capitalization_active", true) == true
} else = false

_ie_interest_raw = raw {
    _ie_use_compound
    raw := _ie_compound(_ie_principal, _ie_annual_rate / 12, _ie_months)
} else = raw2 {
    raw2 := _ie_principal * _ie_annual_rate * _ie_days / 365
}

_ie_interest_rounded := _round2(_ie_interest_raw)

_ie_negative = true {
    _ie_interest_raw < 0
} else = false

_ie_retro = true {
    _ie_arrears_since != ""
    _ie_arrears_since < _th("v3_p17_interest_rates_valid_from", "2023-01-01")
} else = false

_ie_cap_missing = true {
    _ie_months > 0
    object.get(_ctx, "capitalization_active", true) == false
    _th("v3_p17_interest_capitalization", "MONTHLY") == "MONTHLY"
} else = false

_ie_round_diff := _ie_interest_rounded - _ie_interest_raw

_ie_round_ok = true {
    _abs(_ie_round_diff) <= 0.0050001
} else = false

routing_ie = "BLOCK_AND_ALERT" {
    _ie_negative
} else = "BLOCK_AND_ALERT" {
    _ie_retro
} else = "TRIAGE_QUEUE" {
    not _ie_round_ok
} else = "TRIAGE_QUEUE" {
    _ie_cap_missing
} else = "SUGGEST" {
    _ie_interest_raw >= 0
} else = ""

reason_ie = sprintf("Odsetki art. 56: kapitał %.2f PLN, stopa %.4f, %d dni, kapitalizacja miesięczna = %.2f PLN (po zaokrągleniu %.2f PLN).",
    [_ie_principal, _ie_annual_rate, _ie_days, _ie_interest_raw, _ie_interest_rounded]) {
    _ie_interest_raw >= 0
} else = sprintf("Odsetki art. 56: ujemna wartość (%.2f PLN) — naruszenie invariantu ORD_INV-001.", [_ie_interest_raw]) {
    _ie_negative
} else = sprintf("Odsetki art. 56: retroaktywne naliczanie przed valid_from %s — wymagany doradca.",
    [_th("v3_p17_interest_rates_valid_from", "2023-01-01")]) {
    _ie_retro
} else = ""

warnings_ie = ["[V3-P17-I01] Ujemne odsetki — invariant ORD_INV-001 naruszony (BLOCK)."] {
    _ie_negative
} else = ["[V3-P17-I01] Retroaktywne naliczanie odsetek (przed valid_from stawki) — potrzebna decyzja doradcy."] {
    _ie_retro
} else = ["[V3-P17-I01] Kapitalizacja miesięczna wymagana (art. 56) — naliczenie bez kapitalizacji."] {
    _ie_cap_missing
} else = []

interest_engine_decision := _certificate(383101, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.interest_precision_engine",
    "analysis": "interest_precision_engine",
    "principal_pln": _ie_principal,
    "annual_rate": _ie_annual_rate,
    "days": _ie_days,
    "months": _ie_months,
    "capitalization_active": object.get(_ctx, "capitalization_active", true),
    "interest_raw_pln": _ie_interest_raw,
    "interest_rounded_pln": _ie_interest_rounded,
    "round_diff_pln": _ie_round_diff,
    "round_ok": _ie_round_ok,
    "retro_active": _ie_retro,
    "rate_valid_from": _th("v3_p17_interest_rates_valid_from", "2023-01-01"),
    "fail_closed": _ie_negative,
    "_routing": routing_ie,
    "_routing_reason": reason_ie,
    "_legal_basis": "Art. 56 OrdPU (odsetki, kapitalizacja miesięczna); ADR-002; P05 (temporalność)",
    "_warnings": warnings_ie,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "interest_precision_engine"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I02: LIMITATION SENTINEL (art. 70-72 OP)
# Kalendarz przedawnienia: 5 lat, koniec roku kalendarzowego + 5 (31.12);
# zawieszenia (art. 71) przesuwają koniec o okres zawieszenia; alerty 90/60/30
# dni; interwencja przerywająca = nowy termin. Przedawnienie bez ścieżki =
# BLOCK (fail-closed — nigdy ciche „przedawnione").
# ═══════════════════════════════════════════════════════════════════════════════
_ls_assessment_year := object.get(_ctx, "assessment_year", 0)
_ls_suspension_events := object.get(_ctx, "suspension_events", 0)
_ls_suspension_days := object.get(_ctx, "suspension_days", 0)
_ls_days_left := object.get(_ctx, "days_left_to_end", 0)
_ls_interrupted := object.get(_ctx, "interruption_occurred", false)

_ls_statutory_end_year = year {
    _ls_assessment_year > 0
    year := _ls_assessment_year + _th("v3_p17_statute_years", 5)
} else = 0

_ls_unknown = true {
    _ls_assessment_year <= 0
    object.get(_ctx, "days_left_to_end", null) == null
} else = false

_ls_effective_days = result {
    result := _ls_days_left + _ls_suspension_days
}

_ls_expired = true {
    _ls_effective_days < 0
} else = false

_ls_alert_30 = true {
    _ls_effective_days >= 0
    _ls_effective_days <= 30
} else = false

_ls_alert_60 = true {
    _ls_effective_days > 30
    _ls_effective_days <= 60
} else = false

_ls_alert_90 = true {
    _ls_effective_days > 60
    _ls_effective_days <= 90
} else = false

_ls_suspension_cap = true {
    _ls_suspension_events > _th("v3_p17_suspension_max_events", 3)
} else = false

_ls_tier = "EXPIRED" {
    _ls_expired
} else = "30" {
    _ls_alert_30
} else = "60" {
    _ls_alert_60
} else = "90" {
    _ls_alert_90
} else = ">90" {
    true
}

_ls_interrupted_now = true {
    _ls_interrupted
    _ls_assessment_year > 0
} else = false

routing_ls = "BLOCK_AND_ALERT" {
    _ls_unknown
} else = "BLOCK_AND_ALERT" {
    _ls_expired
} else = "BLOCK_AND_ALERT" {
    _ls_alert_30
} else = "TRIAGE_QUEUE" {
    _ls_alert_60
} else = "TRIAGE_QUEUE" {
    _ls_suspension_cap
} else = "SUGGEST" {
    _ls_alert_90
} else = "SUGGEST" {
    _ls_statutory_end_year > 0
} else = ""

reason_ls = sprintf("Przedawnienie art. 70: rok %d → koniec %d (31.12), zawieszenia %d dni, pozostało %d dni (alert 90/60/30).",
    [_ls_assessment_year, _ls_statutory_end_year, _ls_suspension_days, _ls_effective_days]) {
    _ls_statutory_end_year > 0
} else = sprintf("Przedawnienie: pozostało %d dni — BRAK terminu końcowego w danych.", [_ls_effective_days]) {
    not _ls_unknown
} else = "Przedawnienie art. 70: brak roku ani dni — decyzja wymaga doradcy (fail-closed)." {
    _ls_unknown
} else = ""

warnings_ls = ["[V3-P17-I02] Brak danych o roku/terminie przedawnienia — wymagany doradca (fail-closed)."] {
    _ls_unknown
} else = ["[V3-P17-I02] PRZEDAWNIENIE MINĘŁO — zweryfikuj decyzje/tytuły przed uznaniem wygaśnięcia."] {
    _ls_expired
} else = ["[V3-P17-I02] ≤ 30 dni do przedawnienia — pilna interwencja lub potwierdzenie wygaśnięcia."] {
    _ls_alert_30
} else = ["[V3-P17-I02] Przekroczony limit zdarzeń zawieszenia (art. 71) — wymagany przegląd doradcy."] {
    _ls_suspension_cap
} else = []

limitation_sentinel_decision := _certificate(383102, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.limitation_sentinel",
    "analysis": "limitation_sentinel",
    "assessment_year": _ls_assessment_year,
    "statutory_end_year": _ls_statutory_end_year,
    "end_rule": _th("v3_p17_statute_end_rule", "CALENDAR_YEAR_END_PLUS_5"),
    "suspension_events": _ls_suspension_events,
    "suspension_days": _ls_suspension_days,
    "effective_days_left": _ls_effective_days,
    "interruption_occurred": _ls_interrupted_now,
    "suspension_cap_exceeded": _ls_suspension_cap,
    "alert_tier": _ls_tier,
    "limitation_expired": _ls_expired,
    "unknown": _ls_unknown,
    "fail_closed": _ls_unknown,
    "_routing": routing_ls,
    "_routing_reason": reason_ls,
    "_legal_basis": "Art. 70-72 OrdPU (przedawnienie 5 lat, zawieszenie art. 71); kontrakt V3_P36",
    "_warnings": warnings_ls,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "limitation_sentinel"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I03: GAAR SHIELD FRAMEWORK (art. 119a OP)
# Scoring OCHRONNY (NIE wina): ocena ryzyka ustrukturyzowania — checklista
# wartości dodanej/uzasadnienia biznesowego, MAE (korzyść < 1 mln = wyłączenie),
# sztuczne kroki, ukrycie. Sygnał → NEEDS_ADVICE + dokumentacja ochronna;
# ścieżka interpretacji (I07) jako zabezpieczenie. Nigdy automatyczne
# stwierdzenie obejścia.
# ═══════════════════════════════════════════════════════════════════════════════
_ga_benefit := object.get(_ctx, "benefit_pln", 0.0)
_ga_mae_threshold := _th("v3_p17_gaar_mae_threshold_pln", 1000000)

_ga_mae = true {
    _ga_benefit < _ga_mae_threshold
} else = false

_ga_benefit_above = true {
    _ga_benefit >= _ga_mae_threshold
} else = false

_ga_concealment := object.get(_ctx, "concealment", false)
_ga_substance_score := object.get(_ctx, "substance_score", 100)
_ga_artificial_steps := object.get(_ctx, "artificial_steps", 0)

_ga_documented = true {
    object.get(_ctx, "value_added_documented", true) == true
    object.get(_ctx, "business_rationale_documented", true) == true
} else = false

_ga_substance_low = true {
    _ga_substance_score < 40
} else = false

_ga_score = 4 {
    _ga_benefit_above
    _ga_concealment
} else = 3 {
    _ga_benefit_above
    not _ga_documented
} else = 2 {
    _ga_benefit_above
    _ga_substance_low
} else = 1 {
    _ga_benefit_above
    _ga_artificial_steps > 0
} else = 0 {
    true
}

routing_ga = "BLOCK_AND_ALERT" {
    _ga_score >= 4
} else = "TRIAGE_QUEUE" {
    _ga_score >= 2
} else = "TRIAGE_QUEUE" {
    _ga_score == 1
} else = "SUGGEST" {
    true
}

reason_ga = sprintf("GAAR art. 119a: korzyść %.2f PLN, wynik ryzyka %d/4 — sygnał ochronny, wymagany doradca (scoring NIE jest winą).",
    [_ga_benefit, _ga_score]) {
    _ga_score >= 2
} else = sprintf("GAAR art. 119a: korzyść %.2f PLN, wynik %d/4 — niski sygnał; rozważ interpretację (I07).", [_ga_benefit, _ga_score]) {
    _ga_score == 1
} else = sprintf("GAAR art. 119a: korzyść %.2f PLN poniżej MAE (%.2f) lub pełna dokumentacja — brak sygnału.", [_ga_benefit, _ga_mae_threshold]) {
    true
}

warnings_ga = ["[V3-P17-I03] WYSOKI sygnał GAAR (ukrycie + korzyść ≥ 1 mln) — BLOCK do czasu opinii doradcy; dokumentuj wartość dodaną."] {
    _ga_score >= 4
} else = ["[V3-P17-I03] Sygnał GAAR — uzupełnij checklistę ochronną (wartość dodana, uzasadnienie biznesowe) i rozważ wniosek KIS (I07)."] {
    _ga_score >= 2
} else = ["[V3-P17-I03] Korzyść ≥ MAE — rozważ ochronę interpretacją indywidualną (integracja I07)."] {
    _ga_score == 1
} else = []

gaar_shield_decision := _certificate(383103, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.gaar_shield_framework",
    "analysis": "gaar_shield",
    "benefit_pln": _ga_benefit,
    "mae_threshold_pln": _ga_mae_threshold,
    "mae_excluded": _ga_mae,
    "substance_score": _ga_substance_score,
    "artificial_steps": _ga_artificial_steps,
    "documented": _ga_documented,
    "concealment": _ga_concealment,
    "risk_score": _ga_score,
    "protective": true,
    "certainty_impact": "NEEDS_ADVICE",
    "fail_closed": _ga_score >= 4,
    "_routing": routing_ga,
    "_routing_reason": reason_ga,
    "_legal_basis": "Art. 119a OrdPU (GAAR); kontrakt certainty_class V3_P03; interpretacje LKG V3_P01",
    "_warnings": warnings_ga,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "gaar_shield"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I04: PROCEDURAL DEADLINE CONSTITUTION (terminy 7/14/30 — ZERO CISZY)
# Konstytucja terminów proceduralnych jako dane: stanowisko 7 dni (art. 282b),
# odwołanie 14 dni (art. 223), skarga do WSA 30 dni (art. 53 PPSA). ZERO CISZY:
# brak reakcji do terminu = BLOCK_AND_ALERT + eskalacja (48h); ≤ 3 dni =
# TRIAGE; reakcja potwierdzona = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_dc_type := object.get(_ctx, "deadline_type", "")
_dc_days_left := object.get(_ctx, "days_left", 0)
_dc_response_sent := object.get(_ctx, "response_sent", false)

_dc_deadline_days = 7 {
    _dc_type == "STANOWISKO_7"
} else = 14 {
    _dc_type == "ODWOLANIE_14"
} else = 30 {
    _dc_type == "SKARGA_WSA_30"
} else = -1 {
    true
}

_dc_unknown = true {
    _dc_deadline_days < 0
} else = false

_dc_breached = true {
    _dc_days_left <= 0
    not _dc_response_sent
} else = false

_dc_urgent = true {
    _dc_days_left > 0
    _dc_days_left <= 3
    not _dc_response_sent
} else = false

routing_dc = "BLOCK_AND_ALERT" {
    _dc_unknown
} else = "BLOCK_AND_ALERT" {
    _dc_breached
} else = "TRIAGE_QUEUE" {
    _dc_urgent
} else = "SUGGEST" {
    true
}

reason_dc = sprintf("Termin %s (%d dni, art. 223/282b/53 PPSA): brak reakcji, termin MINĄŁ — zero ciszy naruszone, eskalacja.", [_dc_type, _dc_deadline_days]) {
    _dc_breached
} else = sprintf("Termin %s: %d dni do upływu, brak reakcji — wymagana natychmiastowa odpowiedź.", [_dc_type, _dc_days_left]) {
    _dc_urgent
} else = sprintf("Termin %s (%d dni): reakcja potwierdzona — kalendarz zgodny.", [_dc_type, _dc_deadline_days]) {
    _dc_response_sent
} else = sprintf("Termin %s: %d dni do upływu.", [_dc_type, _dc_days_left]) {
    true
}

warnings_dc = ["[V3-P17-I04] Nieznany typ terminu — decyzja fail-closed (BLOCK)."] {
    _dc_unknown
} else = ["[V3-P17-I04] ZERO CISZY: termin minął bez reakcji — eskalacja + natychmiastowa odpowiedź."] {
    _dc_breached
} else = ["[V3-P17-I04] ≤ 3 dni do terminu bez reakcji — priorytet TRIAGE."] {
    _dc_urgent
} else = []

deadline_constitution_decision := _certificate(383104, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.procedural_deadline_constitution",
    "analysis": "deadline_constitution",
    "deadline_type": _dc_type,
    "deadline_days": _dc_deadline_days,
    "days_left": _dc_days_left,
    "response_sent": _dc_response_sent,
    "breached": _dc_breached,
    "escalation_days": _th("v3_p17_zero_silence_escalation_days", 2),
    "unknown": _dc_unknown,
    "fail_closed": _dc_unknown,
    "_routing": routing_dc,
    "_routing_reason": reason_dc,
    "_legal_basis": "Art. 223 OrdPU (odwołanie 14), art. 282b (7), art. 53 PPSA (skarga 30); kontrakt V3_P36",
    "_warnings": warnings_dc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "deadline_constitution"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I05: ACTIVE CORRECTION ADVISOR (art. 81 OP)
# Doradca korekty czynnej: przed wszczęciem postępowania — pełny benefit
# (korekta czynna, art. 81 § 1); po wszczęciu — tylko korekta uzupełniająca
# (art. 81b) z konsekwencjami (potrzebny doradca). INVARIANT (I11): korekta
# zawsze audytowana — bez audytu BLOCK. Nigdy cicha wysyłka korekty.
# ═══════════════════════════════════════════════════════════════════════════════
_ca_proceeding_started := object.get(_ctx, "proceeding_started", false)
_ca_ready := object.get(_ctx, "correction_ready", false)
_ca_filed := object.get(_ctx, "correction_filed", false)
_ca_audited := object.get(_ctx, "correction_audited", false)
_ca_deadline_days := object.get(_ctx, "deadline_days_left", 0)

_ca_not_audited = true {
    _ca_filed
    not _ca_audited
} else = false

_ca_late = true {
    _ca_proceeding_started
    not _ca_filed
} else = false

_ca_ready_to_file = true {
    not _ca_proceeding_started
    _ca_ready
    not _ca_filed
} else = false

_ca_filed_clean = true {
    not _ca_proceeding_started
    _ca_filed
    _ca_audited
} else = false

routing_ca = "BLOCK_AND_ALERT" {
    _ca_not_audited
} else = "TRIAGE_QUEUE" {
    _ca_late
} else = "SUGGEST" {
    _ca_ready_to_file
} else = "SUGGEST" {
    _ca_filed_clean
} else = "TRIAGE_QUEUE" {
    _ca_deadline_days <= 0
} else = ""

reason_ca = "Korekta ZŁOŻONA bez audytu — naruszenie invariantu ORD_INV-003 (BLOCK)." {
    _ca_not_audited
} else = "Postępowanie już wszczęte — korekta czynna (art. 81) niedostępna; tylko uzupełniająca z konsekwencjami — wymagany doradca." {
    _ca_late
} else = "Korekta czynna (art. 81 § 1) gotowa przed wszczęciem — złóż z pełnym audytem; benefit: uniknięcie sankcji." {
    _ca_ready_to_file
} else = "Korekta złożona przed wszczęciem z audytem — status zgodny." {
    _ca_filed_clean
} else = ""

warnings_ca = ["[V3-P17-I05] Korekta bez audytu — invariant ORD_INV-003 (korekta zawsze audytowana) — BLOCK."] {
    _ca_not_audited
} else = ["[V3-P17-I05] Postępowanie wszczęte — korekta czynna niedostępna; konsekwencje uzupełniającej wymagają doradcy."] {
    _ca_late
} else = ["[V3-P17-I05] Przygotuj dokumentację korekty czynnej przed wszczęciem (checklista I09)."] {
    _ca_ready_to_file
} else = []

correction_advisor_decision := _certificate(383105, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.active_correction_advisor",
    "analysis": "correction_advisor",
    "proceeding_started": _ca_proceeding_started,
    "correction_ready": _ca_ready,
    "correction_filed": _ca_filed,
    "correction_audited": _ca_audited,
    "deadline_days_left": _ca_deadline_days,
    "benefit": "KOREKTA_CZYNNA_PRZED_WZSZCZECIEM",
    "fail_closed": _ca_not_audited,
    "_routing": routing_ca,
    "_routing_reason": reason_ca,
    "_legal_basis": "Art. 81 i 81b OrdPU (korekta czynna/uzupełniająca); invariant P04 (korekta audytowana)",
    "_warnings": warnings_ca,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "correction_advisor"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I06: AUD BENEFIT TRACKER (art. 30a/30b OP)
# Śledzenie dobrowolnego ujawnienia: benefity stawki (redukcja do
# v3_p17_aud_reduced_rate_pct po spełnieniu warunków — ujawnienie przed
# wszczęciem + wpłata) i monitoring naruszeń (utrata benefitów = sygnał).
# Stawki parametryzowane (ADR-002); weryfikacja ISAP [NIEZWERYFIKOWANE w raporcie].
# ═══════════════════════════════════════════════════════════════════════════════
_au_disclosure := object.get(_ctx, "disclosure_made", false)
_au_before_proceeding := object.get(_ctx, "before_proceeding_started", false)
_au_paid := object.get(_ctx, "payment_completed", false)
_au_conditions_met := object.get(_ctx, "conditions_met", false)
_au_benefit_claimed := object.get(_ctx, "benefit_claimed", false)
_au_violation := object.get(_ctx, "violation_detected", false)

_au_eligible = true {
    _au_disclosure
    _au_before_proceeding
    _au_paid
    _au_conditions_met
} else = false

_au_unjustified = true {
    _au_benefit_claimed
    not _au_eligible
} else = false

_au_after_proceeding = true {
    _au_disclosure
    not _au_before_proceeding
} else = false

routing_au = "BLOCK_AND_ALERT" {
    _au_unjustified
} else = "TRIAGE_QUEUE" {
    _au_violation
} else = "TRIAGE_QUEUE" {
    _au_after_proceeding
} else = "SUGGEST" {
    _au_eligible
} else = "SUGGEST" {
    not _au_disclosure
} else = ""

reason_au = "Benefit AUD wykorzystany BEZ spełnienia warunków (ujawnienie przed wszczęciem + wpłata) — BLOCK." {
    _au_unjustified
} else = "Monitoring AUD: naruszenie warunków po skorzystaniu z benefitu — ryzyko utraty (doradca)." {
    _au_violation
} else = "Ujawnienie PO wszczęciu postępowania — niższy benefit; wymagana opinia doradcy." {
    _au_after_proceeding
} else = "AUD: warunki spełnione — stawka obniżona (0%%); monitoring aktywny." {
    _au_eligible
} else = "AUD: brak ujawnienia — oceń ścieżkę dobrowolnego ujawnienia przed kontrolą." {
    true
}

warnings_au = ["[V3-P17-I06] NIEZASADNE skorzystanie z benefitu AUD — BLOCK do wyjaśnienia."] {
    _au_unjustified
} else = ["[V3-P17-I06] Naruszenie warunków AUD po skorzystaniu — utrata benefitów możliwa."] {
    _au_violation
} else = ["[V3-P17-I06] Ujawnienie po wszczęciu — obniżony benefit (stawka bazowa)."] {
    _au_after_proceeding
} else = []

aud_tracker_decision := _certificate(383106, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.aud_benefit_tracker",
    "analysis": "aud_tracker",
    "disclosure_made": _au_disclosure,
    "before_proceeding_started": _au_before_proceeding,
    "payment_completed": _au_paid,
    "conditions_met": _au_conditions_met,
    "benefit_claimed": _au_benefit_claimed,
    "violation_detected": _au_violation,
    "reduced_rate_pct": _th("v3_p17_aud_reduced_rate_pct", 0.0),
    "full_rate_pct": _th("v3_p17_aud_full_rate_pct", 0.12),
    "benefit_active": _au_eligible,
    "fail_closed": _au_unjustified,
    "_routing": routing_au,
    "_routing_reason": reason_au,
    "_legal_basis": "Art. 30a/30b OrdPU (AUD) [weryfikacja ISAP — patrz raport P17]; ADR-002",
    "_warnings": warnings_au,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "aud_tracker"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I07: RULING AUTODRAFTER 4-EYES (wnioski KIS)
# Generator wniosków o interpretację z bramką 4-eyes: kompletność formalna
# (opis stanu faktycznego, stanowisko, podstawa, opłata) + review prawnika.
# Wysłanie wniosku BEZ review = BLOCK (naruszenie procesu). Integracja z
# scoringiem GAAR (I03) i biblioteką interpretacji (I10).
# ═══════════════════════════════════════════════════════════════════════════════
_ra_submitted := object.get(_ctx, "submitted", false)
_ra_reviewer := object.get(_ctx, "reviewer_assigned", false)

_ra_complete = true {
    object.get(_ctx, "draft_complete", false) == true
    object.get(_ctx, "legal_basis_present", false) == true
    object.get(_ctx, "facts_present", false) == true
    object.get(_ctx, "position_present", false) == true
    object.get(_ctx, "fee_paid", false) == true
} else = false

_ra_sent_without_review = true {
    _ra_submitted
    not _ra_reviewer
} else = false

_ra_ready = true {
    not _ra_submitted
    _ra_complete
    _ra_reviewer
} else = false

_ra_incomplete = true {
    not _ra_submitted
    not _ra_complete
} else = false

routing_ra = "BLOCK_AND_ALERT" {
    _ra_sent_without_review
} else = "TRIAGE_QUEUE" {
    _ra_incomplete
} else = "TRIAGE_QUEUE" {
    not _ra_submitted
    _ra_complete
    not _ra_reviewer
} else = "SUGGEST" {
    _ra_ready
} else = "SUGGEST" {
    _ra_submitted
    _ra_reviewer
} else = ""

reason_ra = "Wniosek KIS WYSŁANY bez review prawnika — naruszenie bramki 4-eyes (BLOCK)." {
    _ra_sent_without_review
} else = "Wniosek KIS niekompletny formalnie — uzupełnij checklistę (opis, stanowisko, podstawa, opłata)." {
    _ra_incomplete
} else = "Wniosek KIS kompletny — oczekuje na review prawnika (4-eyes)." {
    true
}

warnings_ra = ["[V3-P17-I07] Wysłano wniosek KIS bez 4-eyes — BLOCK, wymagany audyt procesu."] {
    _ra_sent_without_review
} else = ["[V3-P17-I07] Wniosek niekompletny formalnie — checklista: stan faktyczny, stanowisko, podstawa prawna, opłata."] {
    _ra_incomplete
} else = ["[V3-P17-I07] Wniosek kompletny — przypisz recenzenta (4-eyes) przed wysyłką."] {
    not _ra_submitted
    _ra_complete
    not _ra_reviewer
} else = []

ruling_4eyes_decision := _certificate(383107, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.ruling_autodrafter_4eyes",
    "analysis": "ruling_4eyes",
    "draft_complete": object.get(_ctx, "draft_complete", false),
    "legal_basis_present": object.get(_ctx, "legal_basis_present", false),
    "facts_present": object.get(_ctx, "facts_present", false),
    "position_present": object.get(_ctx, "position_present", false),
    "fee_paid": object.get(_ctx, "fee_paid", false),
    "reviewer_assigned": _ra_reviewer,
    "submitted": _ra_submitted,
    "formal_complete": _ra_complete,
    "review_required": _th("v3_p17_ruling_4eyes_required", true),
    "fail_closed": _ra_sent_without_review,
    "_routing": routing_ra,
    "_routing_reason": reason_ra,
    "_legal_basis": "Art. 14b-14d OrdPU (interpretacje KIS); kontrakt LKG V3_P01; bramka 4-eyes (X08)",
    "_warnings": warnings_ra,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "ruling_4eyes"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I08: PROCEEDING TIMELINE (czynności→postępowanie→odwołanie→WSA)
# Timeline sprawy: każdy etap mapowany na następną czynność i termin; ZERO CISZY
# (brak zdarzenia > progu = BLOCK + eskalacja); dowody przy kamieniach
# milowych; termin ≤ 3 dni = TRIAGE. Nieznany etap = fail-closed BLOCK.
# ═══════════════════════════════════════════════════════════════════════════════
_tl_stage := object.get(_ctx, "stage", "")
_tl_days_since := object.get(_ctx, "days_since_last_event", 0)
_tl_next_deadline := object.get(_ctx, "next_deadline_days", 0)
_tl_evidence := object.get(_ctx, "evidence_attached", false)

_tl_stage_known = true {
    _tl_stage in {"CZYNNOSCI_SPRAWDZAJACE", "POSTEPOWANIE", "ODWOLANIE", "SKARGA_WSA", "AUDYT"}
} else = false

_tl_silence = true {
    _tl_days_since > _th("v3_p17_zero_silence_escalation_days", 2)
    object.get(_ctx, "response_sent", false) == false
} else = false

_tl_no_evidence = true {
    _tl_next_deadline <= 3
    not _tl_evidence
} else = false

_tl_unknown = true {
    not _tl_stage_known
} else = false

_tl_next_action = "Odpowiedz na wezwanie / stanowisko (7 dni)" {
    _tl_stage == "CZYNNOSCI_SPRAWDZAJACE"
} else = "Przygotuj odwołanie (14 dni, art. 223)" {
    _tl_stage == "POSTEPOWANIE"
} else = "Przygotuj skargę do WSA (30 dni, art. 53 PPSA)" {
    _tl_stage == "ODWOLANIE"
} else = "Monitoruj termin / wykonaj orzeczenie" {
    _tl_stage == "SKARGA_WSA"
} else = "Ujawnienie / zastrzeżenia do protokołu (14 dni)" {
    _tl_stage == "AUDYT"
} else = ""

routing_tl = "BLOCK_AND_ALERT" {
    not _tl_stage_known
} else = "BLOCK_AND_ALERT" {
    _tl_silence
} else = "TRIAGE_QUEUE" {
    _tl_no_evidence
} else = "TRIAGE_QUEUE" {
    _tl_next_deadline > 0
    _tl_next_deadline <= 3
} else = "SUGGEST" {
    true
}

reason_tl = sprintf("Etap %s: cisza %d dni (> %d) bez reakcji — ZERO CISZY naruszone, eskalacja.", [_tl_stage, _tl_days_since, _th("v3_p17_zero_silence_escalation_days", 2)]) {
    _tl_silence
} else = sprintf("Etap %s: następna czynność: %s (termin %d dni).", [_tl_stage, _tl_next_action, _tl_next_deadline]) {
    _tl_stage_known
} else = sprintf("Nieznany etap sprawy: %s — fail-closed (BLOCK).", [_tl_stage]) {
    true
}

warnings_tl = ["[V3-P17-I08] ZERO CISZY: brak zdarzenia/odpowiedzi w sprawie — eskalacja."] {
    _tl_silence
} else = ["[V3-P17-I08] Termin ≤ 3 dni bez kompletnych dowodów — uzupełnij evidence."] {
    _tl_no_evidence
} else = ["[V3-P17-I08] Nieznany etap — wymagany przegląd (fail-closed)."] {
    not _tl_stage_known
} else = []

proceeding_timeline_decision := _certificate(383108, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.proceeding_timeline",
    "analysis": "proceeding_timeline",
    "stage": _tl_stage,
    "days_since_last_event": _tl_days_since,
    "next_deadline_days": _tl_next_deadline,
    "evidence_attached": _tl_evidence,
    "next_action": _tl_next_action,
    "silence_breach": _tl_silence,
    "stage_known": _tl_stage_known,
    "fail_closed": _tl_unknown,
    "_routing": routing_tl,
    "_routing_reason": reason_tl,
    "_legal_basis": "Art. 187-234 OrdPU (postępowanie); art. 223 (odwołanie); art. 53 PPSA; kontrakt V3_P36",
    "_warnings": warnings_tl,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "proceeding_timeline"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I09: DEFENSE PACKET GENERATOR (paczka obronna)
# Generator paczki obronnej: odpowiedź + dokumenty + indeks dowodów + review
# doradcy. Wysyłka niekompletnej paczki = BLOCK; kompletna = SUGGEST (gotowa do
# złożenia); braki = TRIAGE z checklistą.
# ═══════════════════════════════════════════════════════════════════════════════
_dp_case := object.get(_ctx, "case_type", "")
_dp_response := object.get(_ctx, "response_drafted", false)
_dp_documents := object.get(_ctx, "documents_collected", false)
_dp_evidence := object.get(_ctx, "evidence_indexed", false)
_dp_review := object.get(_ctx, "advisor_reviewed", false)
_dp_filing := object.get(_ctx, "filing_ready", false)

_dp_case_known = true {
    _dp_case in {"APELACJA", "SKARGA_WSA", "ODPOWIEDZ", "ZALECENIA_POKONTROLNE"}
} else = false

_dp_complete = true {
    _dp_response
    _dp_documents
    _dp_evidence
    _dp_review
} else = false

_dp_incomplete_filing = true {
    _dp_filing
    not _dp_complete
} else = false

_dp_ready = true {
    _dp_complete
    not _dp_filing
} else = false

routing_dp = "BLOCK_AND_ALERT" {
    not _dp_case_known
} else = "BLOCK_AND_ALERT" {
    _dp_incomplete_filing
} else = "SUGGEST" {
    _dp_ready
} else = "TRIAGE_QUEUE" {
    not _dp_complete
} else = ""

reason_dp = sprintf("Paczka obronna (%s): WYSYŁKA niekompletna — BLOCK (odpowiedź=%t, dokumenty=%t, dowody=%t, review=%t).",
    [_dp_case, _dp_response, _dp_documents, _dp_evidence, _dp_review]) {
    _dp_incomplete_filing
} else = sprintf("Paczka obronna (%s): kompletna — gotowa do złożenia.", [_dp_case]) {
    _dp_ready
} else = sprintf("Paczka obronna (%s): brakuje elementów checklisty (odpowiedź=%t, dokumenty=%t, dowody=%t, review=%t).",
    [_dp_case, _dp_response, _dp_documents, _dp_evidence, _dp_review]) {
    true
}

warnings_dp = ["[V3-P17-I09] Nieznany typ sprawy — fail-closed (BLOCK)."] {
    not _dp_case_known
} else = ["[V3-P17-I09] Próba wysyłki NIECOMPLETNEJ paczki obronnej — BLOCK do uzupełnienia."] {
    _dp_incomplete_filing
} else = ["[V3-P17-I09] Uzupełnij checklistę paczki: odpowiedź, dokumenty, indeks dowodów, review doradcy."] {
    not _dp_complete
} else = []

defense_packet_decision := _certificate(383109, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.defense_packet_generator",
    "analysis": "defense_packet",
    "case_type": _dp_case,
    "response_drafted": _dp_response,
    "documents_collected": _dp_documents,
    "evidence_indexed": _dp_evidence,
    "advisor_reviewed": _dp_review,
    "filing_ready": _dp_filing,
    "packet_complete": _dp_complete,
    "fail_closed": _dp_incomplete_filing,
    "_routing": routing_dp,
    "_routing_reason": reason_dp,
    "_legal_basis": "Art. 187-234 OrdPU (postępowanie/odwołanie); art. 53 PPSA; kontrakt V3_P41 (UI spraw)",
    "_warnings": warnings_dp,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "defense_packet"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I10: INTERPRETATION LIBRARY (baza interpretacji KIS — LKG P01)
# Baza interpretacji per przepis z datami ważności i sentinelem zmiany prawa:
# zmiana przepisu = utrata ochrony (TRIAGE — nie polegaj na interpretacji);
# brak wpisu = luka dokumentacyjna (→ wniosek I07); wpis ważny = SUGGEST.
# ═══════════════════════════════════════════════════════════════════════════════
_il_provision := object.get(_ctx, "provision", "")
_il_hit := object.get(_ctx, "lookup_hit", false)
_il_valid := object.get(_ctx, "interpretation_valid", false)
_il_law_changed := object.get(_ctx, "law_changed", false)
_il_ruling_id := object.get(_ctx, "ruling_id", "")

_il_protection_ok = true {
    _il_hit
    _il_valid
    not _il_law_changed
} else = false

_il_protection_lost = true {
    _il_hit
    _il_law_changed
} else = false

_il_expired = true {
    _il_hit
    not _il_valid
} else = false

routing_il = "BLOCK_AND_ALERT" {
    _il_provision == ""
} else = "TRIAGE_QUEUE" {
    _il_protection_lost
} else = "TRIAGE_QUEUE" {
    _il_expired
} else = "TRIAGE_QUEUE" {
    not _il_hit
} else = "SUGGEST" {
    _il_protection_ok
} else = ""

reason_il = sprintf("Interpretacja dla %s: brak identyfikatora przepisu — fail-closed (BLOCK).", [_il_provision]) {
    _il_provision == ""
} else = sprintf("Interpretacja %s (%s): ZMIANA PRAWA — ochrona wygasła, nie polegaj (sentinel aktywny).", [_il_provision, _il_ruling_id]) {
    _il_protection_lost
} else = sprintf("Interpretacja %s: brak wpisu w bibliotece (LKG) — luka dokumentacyjna, rozważ wniosek KIS (I07).", [_il_provision]) {
    true
}

warnings_il = ["[V3-P17-I10] Zmiana prawa — interpretacja utraciła ochronę (sentinel V3_P01/LKG)."] {
    _il_protection_lost
} else = ["[V3-P17-I10] Interpretacja nieważna (okres ochrony minął) — nie polegaj."] {
    _il_expired
} else = ["[V3-P17-I10] Brak interpretacji w bibliotece — wygeneruj wniosek KIS (I07)."] {
    not _il_hit
} else = []

interpretation_library_decision := _certificate(383110, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.interpretation_library",
    "analysis": "interpretation_library",
    "provision": _il_provision,
    "lookup_hit": _il_hit,
    "interpretation_valid": _il_valid,
    "law_changed": _il_law_changed,
    "ruling_id": _il_ruling_id,
    "protection_active": _il_protection_ok,
    "law_change_sentinel": _th("v3_p17_interpretation_law_change_sentinel", true),
    "fail_closed": _il_provision == "",
    "_routing": routing_il,
    "_routing_reason": reason_il,
    "_legal_basis": "Art. 14b-14d OrdPU (interpretacje); kontrakt LKG V3_P01; certainty V3_P03",
    "_warnings": warnings_il,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "interpretation_library"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I11: ORD INVARIANTS PACK (kontrakt V3_P04)
# Invarianty runtime warstwy obronnej: ORD_INV-001 odsetki ≥ 0; ORD_INV-002
# przedawnienie nie wcześniej niż koniec 5. roku; ORD_INV-003 korekta zawsze
# audytowana. Jakiekolwiek naruszenie = BLOCK_AND_ALERT (nigdy cichy AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
_iv_interest := object.get(_ctx, "computed_interest_pln", 0.0)
_iv_end_year := object.get(_ctx, "limitation_end_year", 0)
_iv_assessment_year := object.get(_ctx, "assessment_year", 0)
_iv_correction_present := object.get(_ctx, "correction_present", false)
_iv_correction_audited := object.get(_ctx, "correction_audited", false)

_iv_neg_interest = true {
    _iv_interest < 0
} else = false

_iv_early_end = true {
    _iv_end_year != 0
    _iv_assessment_year > 0
    _iv_end_year < _iv_assessment_year + _th("v3_p17_statute_years", 5)
} else = false

_iv_unaudited_correction = true {
    _iv_correction_present
    not _iv_correction_audited
} else = false

_iv_flags := {
    "ORD_INV-001": _iv_neg_interest,
    "ORD_INV-002": _iv_early_end,
    "ORD_INV-003": _iv_unaudited_correction,
}

_iv_violations := [id | some id in object.keys(_iv_flags); _iv_flags[id] == true]

_iv_any_violation = true {
    count(_iv_violations) > 0
} else = false

routing_iv = "BLOCK_AND_ALERT" {
    _iv_any_violation
} else = "SUGGEST" {
    true
}

reason_iv = sprintf("Invarianty ORD naruszone: %s — BLOCK_AND_ALERT (kontrakt P04).", [concat(", ", _iv_violations)]) {
    _iv_any_violation
} else = "Invarianty ORD spełnione (odsetki ≥ 0, przedawnienie ≥ koniec 5. roku, korekta audytowana)." {
    true
}

warnings_iv = [sprintf("Naruszenie invariantu %s — decyzja ZABLOKOWANA (nigdy cichy AUTO_POST).", [concat(", ", _iv_violations)])] {
    _iv_any_violation
} else = []

ord_invariants_decision := _certificate(383111, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.ord_invariants_pack",
    "analysis": "ord_invariants",
    "computed_interest_pln": _iv_interest,
    "limitation_end_year": _iv_end_year,
    "assessment_year": _iv_assessment_year,
    "correction_present": _iv_correction_present,
    "correction_audited": _iv_correction_audited,
    "violations": _iv_violations,
    "invariants_active": _th("v3_p17_invariants_active", true),
    "fail_closed": _iv_any_violation,
    "_routing": routing_iv,
    "_routing_reason": reason_iv,
    "_legal_basis": "Kontrakt invariantów V3_P04; art. 56/70/81 OrdPU",
    "_warnings": warnings_iv,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "ord_invariants"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P17-I12: LITIGATION STRESS LAB (symulatory granic obrony)
# Symulatory warunków skrajnych: odsetki 10 lat (kapitalizacja 120 mies.),
# wielokrotne zawieszenia (art. 71 — przekroczenie limitu), apelacja w ostatnim
# dniu (brak reakcji = BLOCK). Nieznany scenariusz = fail-closed BLOCK. Każdy
# scenariusz kończy się jawną decyzją — nigdy ciszą.
# ═══════════════════════════════════════════════════════════════════════════════
_sl_scenario := object.get(_ctx, "scenario", "")
_sl_scenarios := _th("v3_p17_stress_scenarios", ["interest_10y", "multi_suspension", "last_day_appeal"])

_sl_known = true {
    _sl_scenario in _sl_scenarios
} else = false

_sl_unknown = true {
    not _sl_known
} else = false

_sl_interest_10y = true {
    _sl_scenario == "interest_10y"
    object.get(_ctx, "months", 0) >= 120
    _ie_compound(object.get(_ctx, "principal_pln", 0.0),
        _th("v3_p17_interest_rate_annual", 0.08) / 12, 120) >= 0
} else = false

_sl_multi_suspension = true {
    _sl_scenario == "multi_suspension"
    object.get(_ctx, "suspension_events", 0) > _th("v3_p17_suspension_max_events", 3)
} else = false

_sl_last_day_appeal = true {
    _sl_scenario == "last_day_appeal"
    object.get(_ctx, "days_left", 0) == 0
    object.get(_ctx, "response_sent", false) == false
} else = false

routing_sl = "BLOCK_AND_ALERT" {
    not _sl_known
} else = "BLOCK_AND_ALERT" {
    _sl_last_day_appeal
} else = "TRIAGE_QUEUE" {
    _sl_multi_suspension
} else = "SUGGEST" {
    _sl_interest_10y
} else = "SUGGEST" {
    true
}

reason_sl = sprintf("Stress lab: nieznany scenariusz %s — fail-closed (BLOCK).", [_sl_scenario]) {
    not _sl_known
} else = "Stress lab [last_day_appeal]: apelacja w ostatnim dniu BEZ reakcji — symulacja potwierdza BLOCK (zero ciszy)." {
    _sl_last_day_appeal
} else = "Stress lab [multi_suspension]: przekroczony limit zawieszeń (art. 71) — wymagany przegląd doradcy." {
    _sl_multi_suspension
} else = "Stress lab [interest_10y]: kapitalizacja 120 mies. policzona — odsetki nieujemne, symulacja OK." {
    _sl_interest_10y
} else = sprintf("Stress lab: scenariusz %s zasymulowany — brak sygnału.", [_sl_scenario]) {
    true
}

warnings_sl = ["[V3-P17-I12] Nieznany scenariusz stress — fail-closed (BLOCK)."] {
    not _sl_known
} else = ["[V3-P17-I12] last_day_appeal: brak reakcji w ostatnim dniu — potwierdzony BLOCK (nigdy cisza)."] {
    _sl_last_day_appeal
} else = ["[V3-P17-I12] multi_suspension: przekroczony limit zdarzeń zawieszenia — doradca."] {
    _sl_multi_suspension
} else = []

litigation_stress_lab_decision := _certificate(383112, {
    "rule_id": "jdg.v3_p17_ordynacja_obrona.litigation_stress_lab",
    "analysis": "litigation_stress_lab",
    "scenario": _sl_scenario,
    "scenario_known": _sl_known,
    "interest_10y_ok": _sl_interest_10y,
    "multi_suspension_exceeded": _sl_multi_suspension,
    "last_day_appeal_blocked": _sl_last_day_appeal,
    "scenario_catalog": _sl_scenarios,
    "fail_closed": _sl_unknown,
    "_routing": routing_sl,
    "_routing_reason": reason_sl,
    "_legal_basis": "Art. 56/70-72 OrdPU (symulacje graniczne); kontrakt V3_P04 (fail-closed)",
    "_warnings": warnings_sl,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "litigation_stress_lab"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny, pierwszy match wygrywa)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := interest_engine_decision {
    interest_engine_decision.rule_id != ""
} else := limitation_sentinel_decision {
    limitation_sentinel_decision.rule_id != ""
} else := gaar_shield_decision {
    gaar_shield_decision.rule_id != ""
} else := deadline_constitution_decision {
    deadline_constitution_decision.rule_id != ""
} else := correction_advisor_decision {
    correction_advisor_decision.rule_id != ""
} else := aud_tracker_decision {
    aud_tracker_decision.rule_id != ""
} else := ruling_4eyes_decision {
    ruling_4eyes_decision.rule_id != ""
} else := proceeding_timeline_decision {
    proceeding_timeline_decision.rule_id != ""
} else := defense_packet_decision {
    defense_packet_decision.rule_id != ""
} else := interpretation_library_decision {
    interpretation_library_decision.rule_id != ""
} else := ord_invariants_decision {
    ord_invariants_decision.rule_id != ""
} else := litigation_stress_lab_decision {
    litigation_stress_lab_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p17_ordynacja_obrona.no_match",
    "package": "jdg.v3_p17_ordynacja_obrona",
    "priority": 999999,
}
