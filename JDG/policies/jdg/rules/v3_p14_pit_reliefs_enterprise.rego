# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P14 PIT RELIEFS / FORMS / OPTIMIZATION ENTERPRISE (V3 FORTRESS)
# ===============================================================================
# Warstwa PIT ENTERPRISE: komplet ulg (art. 26e/26eb/26gb/26h/26ec PIT, IP Box
# art. 30ca, zwolnienia art. 21 ust. 1 pkt 148/152/153/154, rehabilitacyjna
# art. 26 ust. 1 pkt 6, darowizny art. 26, e-learning), formy opodatkowania
# (skala art. 27 — 12%/32% + kwota wolna 30 000; liniowy art. 30c — 19%;
# przejścia art. 9 ust. 2 — do 20 lutego), zaliczki (art. 44 — 20. dzień
# miesiąca/kwartału, metoda uproszczona), strata (art. 9 ust. 3 — 50%/5 lat),
# optymalizacja między ulgami (invariant P04: suma odliczeń ≤ dochód).
#
# Zasady:
#   * WSZYSTKIE limity/stopy/progi z data.jdg.thresholds.pit (ADR-002, P06
#     parametry-as-data); limity roczne ulg jako DANE wersjonowane
#     (data.jdg.thresholds.pit.v3_p14_relief_limits z valid_from) — I02.
#   * Okna temporalne honorowane (P05); FAIL-CLOSED: brak danych / nieznana
#     ulga / brak dokumentacji / naruszenie invariantu = NEEDS_ADVICE lub
#     BLOCK_AND_ALERT — nigdy cichy AUTO_POST (AP07).
#   * Optymalizacja agresywna (IP Box bez dokumentacji) = niższa klasa
#     pewności + checklist (kontrakt V3-P03 certainty_class).
#   * Aktywacja: input.jdg_entrepreneur.v3_p14_check == true (wzorzec
#     jdg.v3_p13_vat_deductions); bez flagi → no_match.
#   * rule_id: jdg.v3_p14_pit_reliefs.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p14_pit_reliefs
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p14_pit_reliefs

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p14_check", false) == true
_ctx := object.get(input, "v3_p14", {})

default decide := {
    "matched": false,
    "rule_id": "jdg.v3_p14_pit_reliefs.no_match",
    "package": "jdg.v3_p14_pit_reliefs",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji pit → fail-closed sentinel ─────────
_pit_snapshot := data.jdg.thresholds.pit
_snapshot_ok := count(_pit_snapshot) > 0

_p(key, fallback) = value {
    _snapshot_ok
    value := object.get(_pit_snapshot, key, null)
    value != null
} else = fallback

_pit_limits := object.get(_pit_snapshot, "v3_p14_relief_limits", {})

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p14_pit_reliefs.thresholds_missing",
    "package": "jdg.v3_p14_pit_reliefs",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PIT reliefs V3-P14: brak snapshotu data.jdg.thresholds.pit.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P14] Brak snapshotu progów PIT — decyzje ulgowe ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p14_pit_reliefs",
        "priority": priority,
        "threshold_version": object.get(_pit_snapshot, "threshold_version", "MISSING"),
        "legal_basis_version": object.get(_pit_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_pit_snapshot, "valid_from", null),
        "valid_to": object.get(_pit_snapshot, "valid_to", null),
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

_max(a, b) = a {
    a >= b
} else = b

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I01: RELIEFS MATRIX COMPLETE (art. 26, 26e-26ec, 26h, 30ca, 21 ust. 1)
# Pełna macierz ulg PIT: ulga → przepis → warunki → limit → reguła → test →
# status. Katalog wszystkich ulg części P14 + ocena zgłoszonych roszczeń.
# Limit z data.thresholds.pit.v3_p14_relief_limits (I02); nieznana ulga /
# brak danych do oceny = NEEDS_ADVICE.
# ═══════════════════════════════════════════════════════════════════════════════
# Statyczny katalog: relief_id → podstawa prawna (1:1 z macierzą 9.05 raportu)
_relief_legal_basis(id) = basis {
    id in {"young", "return_work", "family_4plus", "senior"}
    basis := "Art. 21 ust. 1 pkt 148/152/153/154 PIT (PIT-0)"
} else = basis {
    id == "thermo"
    basis := "Art. 26h PIT (termomodernizacja, 53 000 zł)"
} else = basis {
    id == "rehab_car"
    basis := "Art. 26 ust. 1 pkt 6 PIT (rehabilitacyjna, 2 280 zł auto)"
} else = basis {
    id == "rehab_other"
    basis := "Art. 26 ust. 7 PIT (wydatki rehabilitacyjne pozostałe)"
} else = basis {
    id == "internet"
    basis := "Art. 26 ust. 1 pkt 6a PIT (internet, 760 zł)"
} else = basis {
    id == "rd_relief"
    basis := "Art. 26e PIT (B+R: 100% kosztów, 200% osobowe)"
} else = basis {
    id == "prototype"
    basis := "Art. 26eb PIT (prototyp: 30%)"
} else = basis {
    id == "robotization"
    basis := "Art. 26gb PIT (robotyzacja: 50%)"
} else = basis {
    id == "expansion"
    basis := "Art. 26ec PIT (ekspansja: 20%)"
} else = basis {
    id == "ip_box"
    basis := "Art. 30ca PIT (IP Box: 5%, nexus ratio)"
} else = basis {
    id == "donation"
    basis := "Art. 26 ust. 1 pkt 9 PIT (darowizny: 6% dochodu)"
} else = "nieznana podstawa"

_relief_type(id) = "EXEMPTION" {
    id in {"young", "return_work", "family_4plus", "senior"}
} else = "DEDUCTION" {
    id in {"thermo", "rehab_car", "rehab_other", "internet", "rd_relief", "prototype", "robotization", "expansion", "donation"}
} else = "PREFERENTIAL_RATE" {
    id == "ip_box"
} else = "UNKNOWN"

# Katalog wspieranych ulg P14 (macierz)
reliefs_catalog = [row |
    id := ["young", "return_work", "family_4plus", "senior", "thermo", "rehab_car",
           "rehab_other", "internet", "rd_relief", "prototype", "robotization",
           "expansion", "ip_box", "donation"][_]
    row := {"relief_id": id, "legal_basis": _relief_legal_basis(id),
            "type": _relief_type(id)}
]

# Ocena pojedynczego roszczenia (claims: [{relief_id, amount_pln, ...facts}])
_claim_row(claim) = row {
    relief_id := object.get(claim, "relief_id", "")
    row := {"relief_id": relief_id,
            "recognized": relief_id in {"young", "return_work", "family_4plus", "senior", "thermo",
                                        "rehab_car", "rehab_other", "internet", "rd_relief", "prototype",
                                        "robotization", "expansion", "ip_box", "donation"},
            "legal_basis": _relief_legal_basis(relief_id),
            "type": _relief_type(relief_id),
            "amount_pln": object.get(claim, "amount_pln", 0),
            "conditions_met": _conditions_met(claim),
            "limit_pln": _relief_limit(relief_id),
            "rate": _relief_rate(relief_id),
            "status": "OK"}
}

_conditions_met(claim) = false {
    not object.get(claim, "relief_id", "") in {"young", "return_work", "family_4plus", "senior",
                                               "thermo", "rehab_car", "rehab_other", "internet",
                                               "rd_relief", "prototype", "robotization", "expansion",
                                               "ip_box", "donation"}
} else = true {
    object.get(claim, "conditions_met", false) == true
} else = true {
    object.get(claim, "relief_id", "") == "rd_relief"
    object.get(claim, "rd_documented", false) == true
} else = true {
    object.get(claim, "relief_id", "") == "ip_box"
    object.get(claim, "ip_documented", false) == true
} else = false

_limit_for(rid) = limit {
    limit := object.get(object.get(_pit_limits, rid, {}), "limit_pln", 0)
    limit > 0
} else = 0

_relief_limit(rid) = _limit_for(rid) {
    _limit_for(rid) > 0
} else = 0

_rate_for(rid) = rate {
    rid == "ip_box"
    rate := _p("ip_box_rate", 0.05)
} else = rate {
    rid == "rd_relief"
    rate := 1.0
} else = rate {
    rid == "prototype"
    rate := _p("prototype_relief_rate", 0.30)
} else = rate {
    rid == "robotization"
    rate := _p("robotization_relief_rate", 0.50)
} else = rate {
    rid == "expansion"
    rate := 0.20
} else = 0.0

_relief_rate(rid) = _rate_for(rid) {
    _rate_for(rid) > 0
} else = 0.0

reliefs_matrix = result {
    _activated
    claims := object.get(_ctx, "claims", [])
    result := {"catalog_size": count(reliefs_catalog),
               "catalog": reliefs_catalog,
               "claims_checked": count(claims),
               "claims": [row | row := _claim_row(claims[_])],
               "unknown_claims": [rid | rid := object.get(claims[_], "relief_id", ""); not rid in {"young", "return_work", "family_4plus", "senior", "thermo", "rehab_car", "rehab_other", "internet", "rd_relief", "prototype", "robotization", "expansion", "ip_box", "donation"}]}
}

reliefs_matrix_decision := _certificate(381101, {
    "rule_id": "jdg.v3_p14_pit_reliefs.reliefs_matrix_complete",
    "analysis": "reliefs_matrix",
    "reliefs_matrix": reliefs_matrix,
    "fail_closed": reliefs_matrix_unknown,
    "_routing": routing_rm,
    "_routing_reason": reason_rm,
    "_legal_basis": "Art. 26/26e/26eb/26gb/26h/26ec/30ca/21 ust. 1 pkt 148-154 PIT",
    "_warnings": warnings_rm,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "reliefs_matrix"
}

reliefs_matrix_unknown = true {
    count(reliefs_matrix.unknown_claims) > 0
} else = false

routing_rm = "NEEDS_ADVICE" {
    reliefs_matrix_unknown
} else = ""

reason_rm = "Macierz ulg P14: zgłoszono ulgę spoza katalogu części P14 — weryfikacja człowieka." {
    reliefs_matrix_unknown
} else = ""

warnings_rm = ["[V3-P14-I01] Nieznana ulga w roszczeniu — poza katalogiem części P14 (macierz 9.05)."] {
    reliefs_matrix_unknown
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I02: LIMIT-AS-DATA ENGINE
# Limity roczne ulg (53 000 termo, 85 528 PIT-0, 2 280 auto rehab, 760 internet)
# jako DANE wersjonowane (data.jdg.thresholds.pit.v3_p14_relief_limits) z
# valid_from + walidacją: każdy limit > 0, klucze wymagane obecne, spójność
# young/return/family/senior = 85 528. Brak danych = NEEDS_ADVICE.
# ═══════════════════════════════════════════════════════════════════════════════
_required_limit_ids := ["young", "return_work", "family_4plus", "senior", "thermo", "rehab_car", "internet"]

_limits_missing = [rid | rid := _required_limit_ids[_]; count(object.get(_pit_limits, rid, {})) == 0]

_limits_positive = [rid | rid := _required_limit_ids[_]; object.get(object.get(_pit_limits, rid, {}), "limit_pln", 0) <= 0]

_limits_with_valid_from = [rid | rid := _required_limit_ids[_]; object.get(object.get(_pit_limits, rid, {}), "valid_from", "") == ""]

_young_consistent = object.get(object.get(_pit_limits, "young", {}), "limit_pln", 0) == _p("pit_relief_shared_limit", 85528)

_limits_valid = true {
    count(_limits_missing) == 0
    count(_limits_positive) == 0
    count(_limits_with_valid_from) == 0
    _young_consistent
} else = false

limits_as_data = result {
    _activated
    result := {"relief_limits": _pit_limits,
               "required_ids": _required_limit_ids,
               "missing": _limits_missing,
               "non_positive": _limits_positive,
               "without_valid_from": _limits_with_valid_from,
               "young_matches_shared_limit": _young_consistent,
               "data_version": _p("v3_p14_threshold_version", "MISSING"),
               "valid": _limits_valid}
}

limits_as_data_decision := _certificate(381102, {
    "rule_id": "jdg.v3_p14_pit_reliefs.limit_as_data_engine",
    "analysis": "limits_as_data",
    "limits_as_data": limits_as_data,
    "fail_closed": limits_invalid,
    "_routing": routing_ld,
    "_routing_reason": reason_ld,
    "_legal_basis": "ADR-002 parametry-as-data (P06); roczne limity z valid_from (P05)",
    "_warnings": warnings_ld,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "limits_as_data"
}

limits_invalid = true {
    limits_as_data.valid == false
} else = false

routing_ld = "NEEDS_ADVICE" {
    limits_invalid
} else = ""

reason_ld = "Dane limitów rocznych ulg (I02) niekompletne/niezgodne — wymagana aktualizacja data.thresholds.pit." {
    limits_invalid
} else = ""

warnings_ld = ["[V3-P14-I02] Walidacja limitów-as-data wykryła brak/nieprawidłowość — patrz limits_as_data.missing/non_positive."] {
    limits_invalid
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I03: NEXUS RATIO AUDITOR (art. 30ca PIT — IP Box 5%)
# Nexus ratio = (koszty kwalifikowane × 1.3) / koszty całkowite (cap 100%).
#   ≥ 50%  → FULL premium (5% od pełnego dochodu kwalifikowanego)
#   ≥ 25%  → partial discount (5% od dochodu × ratio)
#   < 25%  → LOW (ryzyko zakwestionowania przez US)
# Brak dokumentacji produktowej / ewidencji IP = NEEDS_ADVICE (fail-closed,
# kontrakt V3-P03: agresywna optymalizacja → niższa klasa pewności).
# ═══════════════════════════════════════════════════════════════════════════════
_nexus_raw = result {
    qc := object.get(_ctx, "ip_qualifying_costs_pln", 0)
    tc := object.get(_ctx, "ip_total_costs_pln", 0)
    tc > 0
    result := _min((qc * 1.3) / tc, 1.0)
} else = 0.0

_nexus_tier(ratio) = "FULL" {
    ratio >= _p("ip_box_nexus_full_ratio", 0.50)
} else = "PARTIAL" {
    ratio >= _p("ip_box_nexus_partial_ratio", 0.25)
} else = "LOW"

_qualified_income = _round2(object.get(_ctx, "ip_income_pln", 0) * _nexus_raw)

_ipbox_tax_due = _round2(_qualified_income * _p("ip_box_rate", 0.05))

nexus_ratio = result {
    _activated
    ratio := _nexus_raw
    tier := _nexus_tier(ratio)
    result := {"qualifying_costs_pln": object.get(_ctx, "ip_qualifying_costs_pln", 0),
               "total_costs_pln": object.get(_ctx, "ip_total_costs_pln", 0),
               "nexus_raw": ratio,
               "nexus_uplift": 1.3,
               "nexus_tier": tier,
               "full_ratio_threshold": _p("ip_box_nexus_full_ratio", 0.50),
               "partial_ratio_threshold": _p("ip_box_nexus_partial_ratio", 0.25),
               "qualified_income_pln": _qualified_income,
               "ipbox_tax_due_pln": _ipbox_tax_due,
               "ip_income_pln": object.get(_ctx, "ip_income_pln", 0),
               "has_evidence": object.get(_ctx, "ip_evidence_kept", false),
               "has_documentation": object.get(_ctx, "ip_documented", false),
               "checklist": ["wyodrębniona ewidencja IP (art. 30cb)", "kalkulacja nexus (art. 30ca ust. 4)",
                             "dokumentacja B+R per produkt", "rejestr kosztów kwalifikowanych"]}
}

nexus_ratio_decision := _certificate(381103, {
    "rule_id": "jdg.v3_p14_pit_reliefs.nexus_ratio_auditor",
    "analysis": "nexus_ratio",
    "nexus_ratio": nexus_ratio,
    "fail_closed": nexus_doc_gap,
    "_routing": routing_nr,
    "_routing_reason": reason_nr,
    "_legal_basis": "Art. 30ca ust. 1/4 PIT (5%, wzór nexus); art. 30cb (ewidencja)",
    "_warnings": warnings_nr,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "nexus_ratio"
}

nexus_doc_gap = true {
    object.get(_ctx, "ip_income_pln", 0) > 0
    object.get(_ctx, "ip_documented", false) == false
} else = true {
    object.get(_ctx, "ip_income_pln", 0) > 0
    object.get(_ctx, "ip_evidence_kept", false) == false
} else = false

routing_nr = "NEEDS_ADVICE" {
    nexus_doc_gap
} else = "TRIAGE_QUEUE" {
    nexus_ratio.nexus_tier == "LOW"
} else = ""

reason_nr = "IP Box bez kompletnej dokumentacji (checklist art. 30cb/30ca ust. 4) — wymagana analiza człowieka." {
    nexus_doc_gap
} else = "Niski wskaźnik nexus (< 25%) — ryzyko zakwestionowania preferencji IP Box przez US." {
    nexus_ratio.nexus_tier == "LOW"
} else = ""

warnings_nr = ["[V3-P14-I03] Brak dokumentacji produktowej/ewidencji IP Box — optymalizacja agresywna, niższa klasa pewności (V3-P03)."] {
    nexus_doc_gap
} else = ["[V3-P14-I03] Nexus ratio < 25% — rozważ zasadność IP Box; wymagany przegląd dokumentacji."] {
    nexus_ratio.nexus_tier == "LOW"
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I04: RELIEF ORDER OPTIMIZER
# Optymalna kolejność odliczeń pod invariant P04 „suma odliczeń ≤ dochód”.
# Kolejność kanoniczna: PIT-0 (zwolnienia) → darowizna (6%) → ulgi od dochodu →
# IP Box. Każda ulga ograniczona własnym limitem; nadwyżka ponad dochód →
# BLOCK_AND_ALERT (nigdy cichy nadmierny odliczenie).
# ═══════════════════════════════════════════════════════════════════════════════
_canonical_order := ["young", "return_work", "family_4plus", "senior", "donation",
                     "thermo", "rehab_car", "rehab_other", "internet", "rd_relief",
                     "prototype", "robotization", "expansion", "ip_box"]

_order_index_map := {rid: idx | idx := numbers.range(0, count(_canonical_order) - 1)[_]; rid := _canonical_order[idx]}

_index_of(rid) = idx {
    idx := _order_index_map[rid]
} else = 999

# dochód po zwolnieniach PIT-0 (sekwencyjnie)
_after_exemptions(income, claims) = income - _exemptions_sum(claims) {
    income >= _exemptions_sum(claims)
} else = 0

_exemptions_sum(claims) = sum([amt | amt := object.get(claims[_], "amount_pln", 0); object.get(claims[_], "relief_id", "") in {"young", "return_work", "family_4plus", "senior"}])

_donation_cap(income) = _round2(income * _p("donation_limit_pct", 0.06))

_relief_claims_total(claims) = sum([amt | amt := object.get(claims[_], "amount_pln", 0)])

# Indywidualny limit roszczenia: limit roczny (I02) lub 6% dochodu (darowizna)
_cap_for(rid, claimed, income) = _min(claimed, _relief_limit(rid)) {
    rid != "donation"
    _relief_limit(rid) > 0
} else = cap {
    rid == "donation"
    cap := _min(claimed, _donation_cap(income))
} else = claimed

_order_row(claim, income) = row {
    rid := object.get(claim, "relief_id", "")
    claimed := object.get(claim, "amount_pln", 0)
    capped := _cap_for(rid, claimed, income)
    row := {"relief_id": rid, "claimed_pln": claimed, "cap_pln": capped,
            "applied_pln": _min(capped, income), "order_index": _index_of(rid)}
}

_within_invariant(after_exempt, income, claims) = true {
    after_exempt >= 0
    _relief_claims_total(claims) <= income
} else = false

_optimized(income, claims) = optimized {
    after_exempt := _after_exemptions(income, claims)
    optimized := {"income_pln": income,
                  "total_claimed_pln": _relief_claims_total(claims),
                  "exemptions_pln": _exemptions_sum(claims),
                  "income_after_exemptions_pln": after_exempt,
                  "donation_cap_pln": _donation_cap(after_exempt),
                  "within_invariant": _within_invariant(after_exempt, income, claims),
                  "rows": [row | row := _order_row(claims[_], after_exempt)]}
}

relief_order = result {
    _activated
    income := object.get(_ctx, "annual_income_pln", 0)
    claims := object.get(_ctx, "claims", [])
    result := _optimized(income, claims)
}

relief_order_decision := _certificate(381104, {
    "rule_id": "jdg.v3_p14_pit_reliefs.relief_order_optimizer",
    "analysis": "relief_order",
    "relief_order": relief_order,
    "fail_closed": relief_order_violation,
    "_routing": routing_ro,
    "_routing_reason": reason_ro,
    "_legal_basis": "Art. 26/27 PIT; invariant P04 (suma odliczeń ≤ dochód)",
    "_warnings": warnings_ro,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "relief_order"
}

relief_order_violation = true {
    relief_order.total_claimed_pln > relief_order.income_pln
} else = false

routing_ro = "BLOCK_AND_ALERT" {
    relief_order_violation
} else = ""

reason_ro = "Suma odliczeń przekracza dochód — naruszenie invariantu P04; nadwyżka zablokowana." {
    relief_order_violation
} else = ""

warnings_ro = ["[V3-P14-I04] Invariant P04 naruszony: suma odliczeń > dochód — wymagana korekta deklaracji."] {
    relief_order_violation
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I05: FORM CHANGER PROACTIVE (art. 9 ust. 2 PIT — do 20 lutego)
# Doradca zmiany formy: zmiana skala↔liniowy na NOWY rok podatkowy do 20 lutego
# (art. 9 ust. 2). Po terminie → NEEDS_ADVICE (zmiana tylko w szczególnych
# przypadkach). Alert proaktywny przed terminem + porównanie podatku.
# ═══════════════════════════════════════════════════════════════════════════════
_allowed_forms := {"PIT_SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD"}

_known_form(form) = true {
    form in _allowed_forms
} else = false

# decision_date "YYYY-MM-DD" — porównanie MM-DD z terminem 02-20
_mmdd(iso) = substring(iso, 5, 5)

_form_deadline := "02-20"

_before_deadline(iso) = true {
    _mmdd(iso) <= _form_deadline
} else = false

_scale_tax(income) = tax {
    income <= _p("scale_threshold", 120000)
    tax := _round2(_max(income - _p("tax_free_amount", 30000), 0) * _p("scale_low_rate", 0.12))
} else = tax {
    low := _round2((_p("scale_threshold", 120000) - _p("tax_free_amount", 30000)) * _p("scale_low_rate", 0.12))
    tax := _round2(low + (income - _p("scale_threshold", 120000)) * _p("scale_high_rate", 0.32))
}

_linear_tax(income) = _round2(income * _p("linear_rate", 0.19))

_recommended_form(income) = "LINEAR" {
    _linear_tax(income) < _scale_tax(income)
} else = "PIT_SCALE"

_target_known = true {
    _known_form(object.get(_ctx, "target_form", ""))
} else = true {
    object.get(_ctx, "target_form", "") == ""
} else = false

_change_allowed = true {
    _before_deadline(object.get(_ctx, "decision_date", "2026-02-01"))
    _known_form(object.get(_ctx, "current_form", "PIT_SCALE"))
    _target_known
} else = false

form_changer = result {
    _activated
    income := object.get(_ctx, "projected_income_pln", 0)
    decision_date := object.get(_ctx, "decision_date", "2026-02-01")
    current_form := object.get(_ctx, "current_form", "PIT_SCALE")
    target_form := object.get(_ctx, "target_form", "")
    in_time := _before_deadline(decision_date)
    result := {"current_form": current_form,
               "target_form": target_form,
               "decision_date": decision_date,
               "deadline": _form_deadline,
               "within_deadline": in_time,
               "current_form_known": _known_form(current_form),
               "target_form_known": _target_known,
               "projected_income_pln": income,
               "scale_tax_pln": _scale_tax(income),
               "linear_tax_pln": _linear_tax(income),
               "recommended_form": _recommended_form(income),
               "change_allowed": _change_allowed}
}

form_changer_decision := _certificate(381105, {
    "rule_id": "jdg.v3_p14_pit_reliefs.form_changer_proactive",
    "analysis": "form_changer",
    "form_changer": form_changer,
    "fail_closed": form_change_late,
    "_routing": routing_fc,
    "_routing_reason": reason_fc,
    "_legal_basis": "Art. 9 ust. 2 PIT (wybór formy do 20 lutego); art. 27/30c PIT",
    "_warnings": warnings_fc,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "form_changer"
}

form_change_late = true {
    form_changer.within_deadline == false
    object.get(_ctx, "target_form", "") != ""
    object.get(_ctx, "target_form", "") != form_changer.current_form
} else = false

routing_fc = "NEEDS_ADVICE" {
    form_change_late
} else = "SUGGEST" {
    form_changer.recommended_form != form_changer.current_form
    form_changer.recommended_form != ""
} else = ""

reason_fc = "Zmiana formy po 20 lutego (art. 9 ust. 2 PIT) — wymagana analiza człowieka (wyjątki ustawowe)." {
    form_change_late
} else = "Doradca formy sugeruje zmianę (skala vs liniowy) — decyzja człowieka przed 20.02." {
    form_changer.recommended_form != form_changer.current_form
} else = ""

warnings_fc = ["[V3-P14-I05] Termin zmiany formy (20.02) minął — zmiana na bieżący rok wymaga analizy."] {
    form_change_late
} else = ["[V3-P14-I05] Proaktywny doradca: porównanie skala vs liniowy — rozważ zmianę do 20 lutego."] {
    form_changer.recommended_form != form_changer.current_form
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I06: 12-MONTH SIMULATOR
# Symulator form na danych historycznych 12 miesięcy z założeniami przyszłości
# (wzrost %). Porównanie: skala (12%/32% + kwota wolna) vs liniowy (19%) vs
# ryczałt (stawka wg przychodu — tu: wskaźnik ogólny z thresholds, kontrakt
# P18/P14 nie obejmuje stawek PKWiU). Wynik: raport porównawczy + rekomendacja.
# Baza: przychód 12M, KUP, składki ZUS (społeczne jako KUP — P08), zdrowotna
# (nieodliczalna — P720).
# ═══════════════════════════════════════════════════════════════════════════════
_months_revenue_sum = sum(object.get(_ctx, "monthly_revenues_pln", []))

_kup_annual = object.get(_ctx, "annual_kup_pln", 0)

_zus_social_annual = object.get(_ctx, "annual_zus_social_pln", 0)

_deduction_base = _max(_months_revenue_sum - _kup_annual - _zus_social_annual, 0)

_projected_base = _round2(_deduction_base * (1 + object.get(_ctx, "projected_growth_pct", 0.0) / 100.0))

_scale_12m = _scale_tax(_projected_base)

_linear_12m = _linear_tax(_projected_base)

_lump_12m = _round2(_projected_base * _p("lump_sum_generic_rate", 0.10))

_compare_winner = "LINEAR" {
    _linear_12m < _scale_12m
    _linear_12m <= _lump_12m
} else = "LUMP_SUM" {
    _lump_12m < _scale_12m
    _lump_12m < _linear_12m
} else = "PIT_SCALE"

form_simulator = result {
    _activated
    monthly := object.get(_ctx, "monthly_revenues_pln", [])
    result := {"months_data": count(monthly),
               "monthly_complete": count(monthly) == 12,
               "revenue_12m_pln": _months_revenue_sum,
               "kup_pln": _kup_annual,
               "zus_social_pln": _zus_social_annual,
               "deduction_base_pln": _deduction_base,
               "projected_growth_pct": object.get(_ctx, "projected_growth_pct", 0.0),
               "projected_base_pln": _projected_base,
               "scale_tax_pln": _scale_12m,
               "linear_tax_pln": _linear_12m,
               "lump_tax_pln": _lump_12m,
               "recommended_form": _compare_winner,
               "savings_vs_scale_pln": _round2(_scale_12m - _min(_linear_12m, _lump_12m))}
}

_fs_suggests_change = true {
    form_simulator.recommended_form == "LINEAR"
} else = true {
    form_simulator.recommended_form == "LUMP_SUM"
} else = false

form_simulator_decision := _certificate(381106, {
    "rule_id": "jdg.v3_p14_pit_reliefs.form_simulator_12m",
    "analysis": "form_simulator",
    "form_simulator": form_simulator,
    "fail_closed": simulator_data_gap,
    "_routing": routing_fs,
    "_routing_reason": reason_fs,
    "_legal_basis": "Art. 27/30c PIT; art. 44 (zaliczki); kontrakt P18 (ryczałt — stawki PKWiU poza zakresem)",
    "_warnings": warnings_fs,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "form_simulator"
}

simulator_data_gap = true {
    count(object.get(_ctx, "monthly_revenues_pln", [])) < 12
} else = false

routing_fs = "NEEDS_ADVICE" {
    simulator_data_gap
} else = "SUGGEST" {
    _fs_suggests_change
} else = ""

reason_fs = "Symulator 12-miesięczny: brak pełnych 12 miesięcy danych — wynik niewiarygodny." {
    simulator_data_gap
} else = "Symulator wskazuje formę korzystniejszą niż skala — decyzja człowieka przed 20.02." {
    _fs_suggests_change
} else = ""

warnings_fs = ["[V3-P14-I06] Dane 12-miesięczne niekompletne — symulacja form nieważna."] {
    simulator_data_gap
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I07: LOSS HARVESTING PLANNER (art. 9 ust. 3 PIT — 50%/5 lat)
# Plan wykorzystania straty: max 50% straty rocznie, 5 lat od roku straty.
# Harmonogram 5-letni + monitoring okien (rok straty → rok+5); podwójne
# odliczenie straty = BLOCKER. Brak dochodu w roku → okno przepada.
# ═══════════════════════════════════════════════════════════════════════════════
_loss_window_years = _p("loss_carry_forward_years", 5)

_loss_annual_pct = _p("loss_carry_forward_max_pct", 0.50)

_loss_schedule = [y |
    loss_year := object.get(_ctx, "loss_year", 0)
    offset := [1, 2, 3, 4, 5][_]
    y := loss_year + offset
]

loss_harvesting = result {
    _activated
    loss := object.get(_ctx, "loss_amount_pln", 0)
    loss_year := object.get(_ctx, "loss_year", 0)
    income_this_year := object.get(_ctx, "current_year_income_pln", 0)
    annual_cap := _round2(loss * _loss_annual_pct)
    result := {"loss_amount_pln": loss,
               "loss_year": loss_year,
               "window_years": _loss_window_years,
               "annual_cap_pct": _loss_annual_pct,
               "annual_cap_pln": annual_cap,
               "current_year_income_pln": income_this_year,
               "usable_this_year_pln": _min(annual_cap, income_this_year),
               "remaining_after_this_year_pln": _round2(loss - _min(annual_cap, income_this_year)),
               "last_usable_year": loss_year + _loss_window_years,
               "schedule": _loss_schedule,
               "double_counting_risk": object.get(_ctx, "loss_already_used_elsewhere", false),
               "note": "50% straty rocznie; okno 5 lat od roku straty (art. 9 ust. 3 PIT)"}
}

loss_harvesting_decision := _certificate(381107, {
    "rule_id": "jdg.v3_p14_pit_reliefs.loss_harvesting_planner",
    "analysis": "loss_harvesting",
    "loss_harvesting": loss_harvesting,
    "fail_closed": loss_double_count,
    "_routing": routing_lh,
    "_routing_reason": reason_lh,
    "_legal_basis": "Art. 9 ust. 3 PIT (strata: 50%/rok, 5 lat)",
    "_warnings": warnings_lh,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "loss_harvesting"
}

loss_double_count = true {
    loss_harvesting.double_counting_risk
} else = false

routing_lh = "BLOCK_AND_ALERT" {
    loss_double_count
} else = "TRIAGE_QUEUE" {
    loss_harvesting.remaining_after_this_year_pln > 0
} else = ""

reason_lh = "Strata już wykorzystana gdzie indziej (podwójne odliczenie) — BLOCKER (art. 9 ust. 3)." {
    loss_double_count
} else = "Niewykorzystana część straty przenosi się na kolejne lata okna 5-letniego (monitoring)." {
    loss_harvesting.remaining_after_this_year_pln > 0
} else = ""

warnings_lh = ["[V3-P14-I07] Podwójne odliczenie straty — blokada do wyjaśnienia."] {
    loss_double_count
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I08: RELIEF DOCUMENTATION PACK (dowody dla KAS)
# Generator checklist dokumentacyjnych per ulga — wymagane dokumenty jako dane
# (data.thresholds.pit.v3_p14_relief_docs). Brak dokumentów przy roszczeniu =
# NEEDS_ADVICE (fail-closed, AP07 — nigdy cichy AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
_docs_catalog := {
    "thermo": ["faktura VAT", "dokumentacja techniczna przedsięwzięcia", "dowód własności budynku"],
    "rd_relief": ["ewidencja czasu pracy B+R", "dokumentacja projektu B+R", "kalkulacja kosztów kwalifikowanych"],
    "ip_box": ["wyodrębniona ewidencja IP", "kalkulacja nexus", "dokumentacja B+R per produkt"],
    "rehab_car": ["faktura/rachunek", "orzeczenie o niepełnosprawności", "zaświadczenie lekarskie"],
    "young": ["umowa o pracę/zlecenie", "dowód wieku"],
    "return_work": ["umowa o pracę", "dowód powrotu z przerwy"],
    "family_4plus": ["dokumenty dzieci (4+)", "dowód zatrudnienia"],
    "senior": ["dowód emerytury i zatrudnienia"],
    "donation": ["potwierdzenie przelewu", "umowa darowizny", "oświadczenie OPP"],
    "internet": ["faktury za internet"],
    "prototype": ["dokumentacja prototypu", "kalkulacja kosztów", "faktury"],
    "robotization": ["dokumentacja robota", "faktury", "kalkulacja kosztów"],
    "expansion": ["dokumentacja wydatków ekspansyjnych", "faktury"],
}

_docs_required(rid) = docs {
    docs := object.get(_docs_catalog, rid, [])
} else = []

doc_pack = result {
    _activated
    rid := object.get(_ctx, "relief_id", "")
    required := _docs_required(rid)
    provided := object.get(_ctx, "provided_docs", [])
    missing := [d | d := required[_]; not d in provided]
    result := {"relief_id": rid,
               "recognized": count(required) > 0,
               "required_docs": required,
               "provided_docs": provided,
               "missing_docs": missing,
               "complete": count(missing) == 0,
               "amount_claimed_pln": object.get(_ctx, "amount_claimed_pln", 0)}
}

doc_pack_decision := _certificate(381108, {
    "rule_id": "jdg.v3_p14_pit_reliefs.relief_documentation_pack",
    "analysis": "doc_pack",
    "doc_pack": doc_pack,
    "fail_closed": doc_pack_gap,
    "_routing": routing_dp,
    "_routing_reason": reason_dp,
    "_legal_basis": "Art. 26/26e/26h PIT — obowiązek dokumentacyjny (dowody dla KAS)",
    "_warnings": warnings_dp,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "doc_pack"
}

doc_pack_gap = true {
    count(doc_pack.missing_docs) > 0
    object.get(_ctx, "amount_claimed_pln", 0) > 0
} else = true {
    count(doc_pack.required_docs) == 0
} else = false

routing_dp = "NEEDS_ADVICE" {
    doc_pack_gap
} else = ""

reason_dp = "Brak wymaganych dokumentów ulgi (checklist I08) przy zgłoszonym roszczeniu — wstrzymaj księgowanie." {
    count(doc_pack.missing_docs) > 0
    object.get(_ctx, "amount_claimed_pln", 0) > 0
} else = "Nieznana ulga w generatorze checklist — uzupełnij katalog dokumentów." {
    count(doc_pack.required_docs) == 0
} else = ""

warnings_dp = [concat("", ["[V3-P14-I08] Brak dokumentów: ", concat(", ", doc_pack.missing_docs), " — roszczenie wstrzymane."])] {
    count(doc_pack.missing_docs) > 0
    object.get(_ctx, "amount_claimed_pln", 0) > 0
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I09: RELIEF EXPIRY SENTINEL
# Alarmy wygasania ulg czasowych: PIT-0 (powrót do pracy — 4 lata; wiek 26 lat),
# robotyzacja (okno inwestycyjne do 2026 — art. 26gb), e-learning/pozostałe
# okna czasowe. Alert z wyprzedzeniem (miesiące) + monitoring.
# ═══════════════════════════════════════════════════════════════════════════════
_years_since_return = object.get(_ctx, "years_since_return_to_work", 0)

_age_now = object.get(_ctx, "taxpayer_age", 0)

_robotization_year = object.get(_ctx, "robotization_investment_year", 0)

_robotization_window_alert = true {
    _robotization_year >= 2024
    _robotization_year <= _p("robotization_relief_last_year", 2026)
} else = false

expiry_sentinel = result {
    _activated
    result := {"taxpayer_age": _age_now,
               "young_relief_active": _age_now <= _p("young_relief_max_age", 26),
               "young_relief_months_left": _max((_p("young_relief_max_age", 26) - _age_now) * 12, 0),
               "return_work_years_used": _years_since_return,
               "return_work_window_years": _p("return_work_relief_years", 4),
               "return_work_active": _years_since_return <= _p("return_work_relief_years", 4),
               "return_work_months_left": _max((_p("return_work_relief_years", 4) - _years_since_return) * 12, 0),
               "robotization_year": _robotization_year,
               "robotization_window_alert": _robotization_window_alert,
               "robotization_last_year": _p("robotization_relief_last_year", 2026),
               "alert_window_months": _p("relief_expiry_alert_months", 3)}
}

expiry_sentinel_decision := _certificate(381109, {
    "rule_id": "jdg.v3_p14_pit_reliefs.relief_expiry_sentinel",
    "analysis": "expiry_sentinel",
    "expiry_sentinel": expiry_sentinel,
    "fail_closed": false,
    "_routing": routing_es,
    "_routing_reason": reason_es,
    "_legal_basis": "Art. 21 ust. 1 pkt 148/152 PIT (okresy); art. 26gb PIT (okno inwestycyjne)",
    "_warnings": warnings_es,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "expiry_sentinel"
}

routing_es = "TRIAGE_QUEUE" {
    expiry_sentinel.young_relief_months_left > 0
    expiry_sentinel.young_relief_months_left <= expiry_sentinel.alert_window_months
} else = "TRIAGE_QUEUE" {
    expiry_sentinel.return_work_active
    expiry_sentinel.return_work_months_left <= expiry_sentinel.alert_window_months
} else = "TRIAGE_QUEUE" {
    expiry_sentinel.robotization_window_alert
} else = ""

reason_es = "Uwaga: kończy się okno ulgi (PIT-0/powrót do pracy) — monitoruj granice." {
    routing_es == "TRIAGE_QUEUE"
} else = ""

warnings_es = ["[V3-P14-I09] Sentinel wygasania: ulga czasowa w oknie końcowym — sprawdź granice (wiek 26, 4 lata powrotu, robotyzacja)."] {
    routing_es == "TRIAGE_QUEUE"
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I10: RELIEF GOLDEN SET
# Golden decyzje ulgowe z granicami limitów i wieku — zbiór wzorcowy
# (P10 golden oracle) dla testów regresji i bramek CI (P39): granica kwoty
# wolnej 30 000, wiek 25/26, termo 53 000, PIT-0 85 528.
# ═══════════════════════════════════════════════════════════════════════════════
_golden_case(case_id, income, age) = verdict {
    case_id == "tax_free_boundary"
    verdict := {"income_pln": income, "threshold_pln": _p("tax_free_amount", 30000),
                "expected": income <= _p("tax_free_amount", 30000)}
} else = verdict {
    case_id == "young_age_boundary"
    verdict := {"age": age, "max_age": _p("young_relief_max_age", 26),
                "expected": age <= _p("young_relief_max_age", 26)}
} else = verdict {
    case_id == "pit0_income_boundary"
    verdict := {"income_pln": income, "threshold_pln": _p("pit_relief_shared_limit", 85528),
                "expected": income <= _p("pit_relief_shared_limit", 85528)}
} else = verdict {
    case_id == "thermo_limit_boundary"
    verdict := {"amount_pln": income, "limit_pln": _p("pit_thermo_limit", 53000),
                "expected": income <= _p("pit_thermo_limit", 53000)}
} else = verdict {
    verdict := {"case_id": case_id, "recognized": false, "expected": false}
}

golden_set = result {
    _activated
    case_id := object.get(_ctx, "golden_case", "")
    result := {"case_id": case_id,
               "verdict": _golden_case(case_id, object.get(_ctx, "probe_pln", 0), object.get(_ctx, "probe_age", 0))}
}

golden_set_decision := _certificate(381110, {
    "rule_id": "jdg.v3_p14_pit_reliefs.relief_golden_set",
    "analysis": "golden_set",
    "golden_set": golden_set,
    "fail_closed": golden_unknown_case,
    "_routing": routing_gs,
    "_routing_reason": reason_gs,
    "_legal_basis": "P10 golden oracle; P39 bramki CI (granice limitów/wieku)",
    "_warnings": warnings_gs,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "golden_set"
}

golden_unknown_case = true {
    golden_set.verdict.recognized == false
} else = false

routing_gs = "NEEDS_ADVICE" {
    golden_unknown_case
} else = ""

reason_gs = "Golden case spoza zbioru P14 (tax_free/young/pit0/thermo) — rozszerz zbiór wzorcowy." {
    golden_unknown_case
} else = ""

warnings_gs = ["[V3-P14-I10] Nieznany golden case — dodaj do Relief Golden Set."] {
    golden_unknown_case
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I11: MULTI-RELIEF CONFLICT DETECTOR
# Wykrywanie kolizji ulg: te same koszty odliczone w dwóch ulgach (np. koszty
# B+R w rd_relief i te same w robotization/ip_box) — podwójne odliczenie =
# BLOCKER. Sygnał: wspólny identyfikator kosztu w dwóch roszczeniach.
# ═══════════════════════════════════════════════════════════════════════════════
_conflict_pairs := [["rd_relief", "robotization"], ["rd_relief", "ip_box"], ["robotization", "rd_relief"], ["ip_box", "rd_relief"]]

_claim_cost_ids(claim) = ids {
    ids := object.get(claim, "cost_ids", [])
}

_shared_cost_ids(a, b) = ids {
    ids := [c | c := _claim_cost_ids(a)[_]; c in _claim_cost_ids(b)]
}

_conflicts_list = [found |
    claims := object.get(_ctx, "claims", [])
    idxs := [x | x := numbers.range(0, count(claims) - 1)[_]]
    a := idxs[_]
    b := idxs[_]
    a < b
    count(_shared_cost_ids(claims[a], claims[b])) > 0
    found := {"relief_a": object.get(claims[a], "relief_id", ""),
              "relief_b": object.get(claims[b], "relief_id", ""),
              "shared_cost_ids": _shared_cost_ids(claims[a], claims[b])}
]

conflict_detector = result {
    _activated
    claims := object.get(_ctx, "claims", [])
    result := {"claims_checked": count(claims),
               "conflicts": _conflicts_list,
               "conflict_count": count(_conflicts_list),
               "forbidden_pairs": _conflict_pairs}
}

conflict_detector_decision := _certificate(381111, {
    "rule_id": "jdg.v3_p14_pit_reliefs.multi_relief_conflict_detector",
    "analysis": "conflict_detector",
    "conflict_detector": conflict_detector,
    "fail_closed": conflict_detected,
    "_routing": routing_cd,
    "_routing_reason": reason_cd,
    "_legal_basis": "Art. 26/26e PIT — zakaz podwójnego odliczenia tych samych kosztów; P04 invariants",
    "_warnings": warnings_cd,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "conflict_detector"
}

conflict_detected = true {
    conflict_detector.conflict_count > 0
} else = false

routing_cd = "BLOCK_AND_ALERT" {
    conflict_detected
} else = ""

reason_cd = "Wykryto kolizję ulg: te same koszty w dwóch ulgach (podwójne odliczenie) — BLOCKER." {
    conflict_detected
} else = ""

warnings_cd = ["[V3-P14-I11] Kolizja ulg (multi-relief conflict) — rozdziel koszty między ulgi lub zrezygnuj z jednej."] {
    conflict_detected
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P14-I12: RELIEF EXPLANATION ENGINE
# Wyjaśnienie decyzji ulgowej prostym językiem (PL) — do Decision Certificate
# (V2 F4) i raportu P11. Buduje narrację: co policzono, jaka podstawa prawna,
# jaki routing, jakie dokumenty wymagane.
# ═══════════════════════════════════════════════════════════════════════════════
_explanation_lines = lines {
    rid := object.get(_ctx, "relief_id", "")
    claimed := object.get(_ctx, "amount_claimed_pln", 0)
    lines := [sprintf("Ulga: %s (%s).", [rid, _relief_legal_basis(rid)]),
              sprintf("Kwota roszczenia: %d PLN.", [claimed]),
              sprintf("Limit (dane roczne I02): %d PLN.", [_relief_limit(rid)]),
              "Routing: NEEDS_ADVICE przy braku dokumentów lub niepewności — nigdy cichy AUTO_POST."]
}

explanation = result {
    _activated
    result := {"relief_id": object.get(_ctx, "relief_id", ""),
               "legal_basis": _relief_legal_basis(object.get(_ctx, "relief_id", "")),
               "explanation_pl": _explanation_lines,
               "certificate_ready": true}
}

explanation_decision := _certificate(381112, {
    "rule_id": "jdg.v3_p14_pit_reliefs.relief_explanation_engine",
    "analysis": "explanation",
    "explanation": explanation,
    "fail_closed": explanation_unknown,
    "_routing": routing_ex,
    "_routing_reason": reason_ex,
    "_legal_basis": "V2 filar F4 (Decision Certificate); P11",
    "_warnings": warnings_ex,
}) {
    _activated
    object.get(_ctx, "analysis", "") == "explanation"
}

explanation_unknown = true {
    explanation.legal_basis == "nieznana podstawa"
} else = false

routing_ex = "NEEDS_ADVICE" {
    explanation_unknown
} else = ""

reason_ex = "Ulga poza katalogiem P14 — brak podstawy do wyjaśnienia." {
    explanation_unknown
} else = ""

warnings_ex = ["[V3-P14-I12] Nie można wyjaśnić decyzji — ulga nieznana w katalogu."] {
    explanation_unknown
} else = []

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny, pierwszy match wygrywa)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := reliefs_matrix_decision {
    reliefs_matrix_decision.rule_id != ""
} else := limits_as_data_decision {
    limits_as_data_decision.rule_id != ""
} else := nexus_ratio_decision {
    nexus_ratio_decision.rule_id != ""
} else := relief_order_decision {
    relief_order_decision.rule_id != ""
} else := form_changer_decision {
    form_changer_decision.rule_id != ""
} else := form_simulator_decision {
    form_simulator_decision.rule_id != ""
} else := loss_harvesting_decision {
    loss_harvesting_decision.rule_id != ""
} else := doc_pack_decision {
    doc_pack_decision.rule_id != ""
} else := expiry_sentinel_decision {
    expiry_sentinel_decision.rule_id != ""
} else := golden_set_decision {
    golden_set_decision.rule_id != ""
} else := conflict_detector_decision {
    conflict_detector_decision.rule_id != ""
} else := explanation_decision {
    explanation_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p14_pit_reliefs.no_match",
    "package": "jdg.v3_p14_pit_reliefs",
    "priority": 999999,
}
