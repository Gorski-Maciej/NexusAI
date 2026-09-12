# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P52 GRANICE GROSZOWE, WALUTY I ZAOKRĄGLENI — PRECYZJA
# WYPOWIEDZI FINANSOWEJ (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa arytmetyki finansowej ENTERPRISE — 12 innowacji (I01–I12; minimum
# z promptu P52 Sekcja 10):
#   I01 Arithmetic standards register (operacja → standard zaokrąglenia →
#       przepis: art. 107 OP / art. 63 PIT [NIEZWERYFIKOWANE — ISAP] → testy),
#   I02 Penny boundary test matrix (próg, próg±0.01, próg±1% z reżimem),
#   I03 Currency rate provenance (kurs = wartość + tabela NBP-A + data +
#       checksuma; replay odtwarza kurs historyczny),
#   I04 Weekend/holiday rate path (brak tabeli → ostatni dzień roboczy /
#       NEEDS_ADVICE — nigdy kurs „z pamięci"),
#   I05 Sum invariants suite (suma pozycji = suma total; netto+VAT=brutto),
#   I06 Determinism hash (dwa wyliczenia = ten sam hash; rozjazd = BLOCKER),
#   I07 Rounding interaction tests (netto→VAT→brutto→sumy→JPK bez rozjazdów),
#   I08 Negative amount paths (korekty/nadpłaty tymi samymi ścieżkami),
#   I09 Threshold calendar audit (kwoty narastające vs limity roczne),
#   I10 Penny drift telemetry (rozjazdy groszowe → trend do 0; alarm),
#   I11 Currency fuzz (property-based inwarianty walutowe),
#   I12 Arithmetic doomsday suite (skrajne wartości → fail-closed, bez crashu).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p52 — ADR-002 (P06), okno
#     temporalne valid_from (P05). ZERO hardcode progów.
#   * Fail-closed (V1 zasada 6): brak snapshotu progów, dryf determinizmu,
#     rozjazd groszowy ponad próg, bypass bramki = BLOCK — kwota bez
#     reprodukowalności grosz po groszu nie jest kwotą do AUTO_POST
#     (art. 107 OP: kwoty zaokrąglane do pełnych groszy [NIEZWERYFIKOWANE — ISAP]).
#   * Honesty: liczniki z narzędzi i bundli (nie deklaracje); baseline rozjazdów
#     jawny (trend do zera), bez maskowania (protokół 14 P52).
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     [NIEZWERYFIKOWANE — ISAP] do czasu stempla 4-eyes (protokół 04;
#     konwencja P47–P51).
#   * Aktywacja: input.jdg_entrepreneur.v3_p52_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p52_penny_granularity.<analiza>.
#   * Kontrakty: P00 (kanon artefaktów), P03/P05 (kontrakt werdyktu +
#     temporalność), P06/P46 (parametry-as-data z jednostkami), P08 (Law
#     Radar — nowy kurs/limit = pustynia brzegowa), P10/P11 (golden +
#     certyfikat: determinism hash), P36 (generatory testów brzegowych),
#     P37 (telemetria driftu), P39 (bramki merge), P41 (rejestr standardów
#     w dokumentacji), P49 (fail-closed), P51 (rejestr pustyni: brak testów
#     brzegowych = pustynia testowa), P53+ (kontrakt standardów), P68.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p52_penny_granularity
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p52_penny_granularity

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p52_check", false) == true
_ctx := object.get(input, "v3_p52", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p52_snapshot := data.jdg.thresholds.v3_p52

_snapshot_ok = true {
    count(_p52_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p52_snapshot) > 0
    value := object.get(_p52_snapshot, key, null)
    value != null
} else = fallback

_has_flag(key) = result {
    result := object.get(_ctx, key, false) == true
} else = false {
    true
}

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p52_penny_granularity.thresholds_missing",
    "package": "jdg.v3_p52_penny_granularity",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PENNY V3-P52: brak snapshotu data.jdg.thresholds.v3_p52.",
    "_legal_basis": "ADR-002; V1 zasada 6 (fail-closed); OP art. 107 (pełne grosze) [NIEZWERYFIKOWANE — ISAP]",
    "_warnings": ["[V3-P52] Brak snapshotu progów arytmetycznych — kontrole ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p52_penny_granularity",
        "priority": priority,
        "threshold_version": object.get(_p52_snapshot, "v3_p52_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p52_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p52_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I01: ARITHMETIC STANDARDS REGISTER — jeden standard per kontekst (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_sr := object.get(_ctx, "standards_register", {})
_tools_total := object.get(_sr, "tools_total", 0)
_tools_noncompliant := object.get(_sr, "tools_noncompliant", -1)
_rego_dupes := object.get(_sr, "rego_round2_duplicates", 0)
_std_noncompliant_max := _th("v3_p52_noncompliant_tools_max", 0)

routing_sr01 = "BLOCK_AND_ALERT" {
    _has_flag("standards_bypassed")
} else = "BLOCK_AND_ALERT" {
    _tools_noncompliant > _std_noncompliant_max
} else = "TRIAGE_QUEUE" {
    _tools_total == 0
} else = "AUTO_FILE" {
    true
}

standards_register_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "standards_register"
    routing_sr01 == "AUTO_FILE"
    cert := _certificate(452001, {
        "rule_id": "jdg.v3_p52_penny_granularity.standards_register",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sr01,
        "_routing_reason": "PENNY: wszystkie operacje arytmetyczne na standardzie HALF_UP (art. 107 OP).",
        "_legal_basis": "P52-I01; OP art. 107; PIT art. 63 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "tools_total": _tools_total,
        "tools_noncompliant": _tools_noncompliant,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "standards_register"
    routing_sr01 == "TRIAGE_QUEUE"
    cert := _certificate(452001, {
        "rule_id": "jdg.v3_p52_penny_granularity.standards_register",
        "decision_mode": "TRIAGE",
        "_routing": routing_sr01,
        "_routing_reason": "PENNY: rejestr standardów pusty lub częściowo zgodny — audyt zaokrągleń.",
        "_legal_basis": "P52-I01; OP art. 107 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Standard zaokrągleń niespójny — jeden standard per kontekst."],
        "tools_total": _tools_total,
        "rego_round2_duplicates": _rego_dupes,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "standards_register"
    routing_sr01 == "BLOCK_AND_ALERT"
    cert := _certificate(452001, {
        "rule_id": "jdg.v3_p52_penny_granularity.standards_register",
        "decision_mode": "BLOCK",
        "_routing": routing_sr01,
        "_routing_reason": "PENNY: operacje poza standardem ustawowym (banker's/truncation) — kwoty niereprodukowalne.",
        "_legal_basis": "P52-I01; OP art. 107; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Kalkulatory poza standardem HALF_UP — ZABLOKOWANE do naprawy."],
        "tools_noncompliant": _tools_noncompliant,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I02: PENNY BOUNDARY TEST MATRIX — próg±0.01 decyduje (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_pb := object.get(_ctx, "penny_boundary_matrix", {})
_cases := object.get(_pb, "cases_total", 0)
_thr_covered := object.get(_pb, "thresholds_covered", 0)
_thr_required := _th("v3_p52_boundary_thresholds_min", 4)

routing_pb02 = "BLOCK_AND_ALERT" {
    _has_flag("boundary_bypassed")
} else = "TRIAGE_QUEUE" {
    _cases == 0
} else = "TRIAGE_QUEUE" {
    _thr_covered < _thr_required
} else = "AUTO_FILE" {
    true
}

penny_boundary_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "penny_boundary_matrix"
    routing_pb02 == "AUTO_FILE"
    cert := _certificate(452002, {
        "rule_id": "jdg.v3_p52_penny_granularity.penny_boundary_matrix",
        "decision_mode": "AUTO_POST",
        "_routing": routing_pb02,
        "_routing_reason": "PENNY: każdy próg kwotowy z testami granicznymi (próg±0.01).",
        "_legal_basis": "P52-I02; VAT art. 119 (granica 'przekracza'); art. 113 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "cases_total": _cases,
        "thresholds_covered": _thr_covered,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "penny_boundary_matrix"
    routing_pb02 == "TRIAGE_QUEUE"
    cert := _certificate(452002, {
        "rule_id": "jdg.v3_p52_penny_granularity.penny_boundary_matrix",
        "decision_mode": "TRIAGE",
        "_routing": routing_pb02,
        "_routing_reason": "PENNY: progi bez testów granicznych groszowych — generator I02 domyka.",
        "_legal_basis": "P52-I02; VAT art. 119/113 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Testy brzegowe progów niekompletne."],
        "cases_total": _cases,
        "thresholds_covered": _thr_covered,
        "thresholds_required": _thr_required,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "penny_boundary_matrix"
    routing_pb02 == "BLOCK_AND_ALERT"
    cert := _certificate(452002, {
        "rule_id": "jdg.v3_p52_penny_granularity.penny_boundary_matrix",
        "decision_mode": "BLOCK",
        "_routing": routing_pb02,
        "_routing_reason": "PENNY: bypass matrycy brzegowej — BLOCK.",
        "_legal_basis": "P52-I02; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Bypass penny boundary — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I03: CURRENCY RATE PROVENANCE — kurs z datą/źródłem/checksumą (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_rp := object.get(_ctx, "rate_provenance", {})
_fx_tools := object.get(_rp, "tools_with_fx", 0)
_fx_prov := object.get(_rp, "tools_with_provenance", 0)
_rego_prov := object.get(_rp, "rego_provenance_required", false)

routing_rp03 = "BLOCK_AND_ALERT" {
    _has_flag("provenance_bypassed")
} else = "TRIAGE_QUEUE" {
    _fx_tools > _fx_prov
} else = "TRIAGE_QUEUE" {
    not _rego_prov
} else = "AUTO_FILE" {
    true
}

rate_provenance_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "rate_provenance"
    routing_rp03 == "AUTO_FILE"
    cert := _certificate(452003, {
        "rule_id": "jdg.v3_p52_penny_granularity.rate_provenance",
        "decision_mode": "AUTO_POST",
        "_routing": routing_rp03,
        "_routing_reason": "PENNY: każdy kurs z provenance (tabela, data, checksuma) — replay odtwarza historyczny.",
        "_legal_basis": "P52-I03; VAT art. 31a (kurs z dnia poprzedzającego); PIT art. 11a [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "tools_with_fx": _fx_tools,
        "tools_with_provenance": _fx_prov,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "rate_provenance"
    routing_rp03 == "TRIAGE_QUEUE"
    cert := _certificate(452003, {
        "rule_id": "jdg.v3_p52_penny_granularity.rate_provenance",
        "decision_mode": "TRIAGE",
        "_routing": routing_rp03,
        "_routing_reason": "PENNY: kursy bez provenance (AP09) — dopiąć datę tabeli/źródło/checksumę.",
        "_legal_basis": "P52-I03; VAT art. 31a; AP09 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Kursy bez provenance — przeliczenia niereprodukowalne."],
        "tools_with_fx": _fx_tools,
        "tools_with_provenance": _fx_prov,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "rate_provenance"
    routing_rp03 == "BLOCK_AND_ALERT"
    cert := _certificate(452003, {
        "rule_id": "jdg.v3_p52_penny_granularity.rate_provenance",
        "decision_mode": "BLOCK",
        "_routing": routing_rp03,
        "_routing_reason": "PENNY: bypass provenance kursów — BLOCK.",
        "_legal_basis": "P52-I03; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Bypass rate provenance — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I04: WEEKEND/HOLIDAY RATE PATH — brak tabeli → fail-closed (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_we := object.get(_ctx, "weekend_rate_path", {})
_cases_we := object.get(_we, "cases_total", 0)
_no_table := object.get(_we, "no_table_days", 0)
_holidays := object.get(_we, "holidays_registered", 0)
_holidays_min := _th("v3_p52_holidays_registered_min", 20)

routing_we04 = "BLOCK_AND_ALERT" {
    _has_flag("weekend_bypassed")
} else = "TRIAGE_QUEUE" {
    _cases_we == 0
} else = "TRIAGE_QUEUE" {
    _holidays < _holidays_min
} else = "AUTO_FILE" {
    true
}

weekend_rate_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "weekend_rate_path"
    routing_we04 == "AUTO_FILE"
    cert := _certificate(452004, {
        "rule_id": "jdg.v3_p52_penny_granularity.weekend_rate_path",
        "decision_mode": "AUTO_POST",
        "_routing": routing_we04,
        "_routing_reason": "PENNY: daty bez tabeli NBP mają jawną ścieżkę (ostatni dzień roboczy z provenance).",
        "_legal_basis": "P52-I04; VAT art. 31a; kalendarz świąt 2026–2027 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "cases_total": _cases_we,
        "holidays_registered": _holidays,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "weekend_rate_path"
    routing_we04 == "TRIAGE_QUEUE"
    cert := _certificate(452004, {
        "rule_id": "jdg.v3_p52_penny_granularity.weekend_rate_path",
        "decision_mode": "TRIAGE",
        "_routing": routing_we04,
        "_routing_reason": "PENNY: ścieżka weekend/święto nieprzetestowana lub kalendarz świąt niekompletny.",
        "_legal_basis": "P52-I04; VAT art. 31a [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Daty bez tabeli NBP bez testowanej ścieżki."],
        "cases_total": _cases_we,
        "no_table_days": _no_table,
        "holidays_registered": _holidays,
        "holidays_min": _holidays_min,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "weekend_rate_path"
    routing_we04 == "BLOCK_AND_ALERT"
    cert := _certificate(452004, {
        "rule_id": "jdg.v3_p52_penny_granularity.weekend_rate_path",
        "decision_mode": "BLOCK",
        "_routing": routing_we04,
        "_routing_reason": "PENNY: bypass ścieżki kursów świątecznych — BLOCK.",
        "_legal_basis": "P52-I04; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Bypass weekend rate path — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I05: SUM INVARIANTS SUITE — suma pozycji = suma total (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_si := object.get(_ctx, "sum_invariants", {})
_checks := object.get(_si, "checks_run", 0)
_si_viol := object.get(_si, "violations", 0)
_si_checks_min := _th("v3_p52_sum_checks_min", 100)

routing_si05 = "BLOCK_AND_ALERT" {
    _has_flag("invariants_bypassed")
} else = "TRIAGE_QUEUE" {
    _checks < _si_checks_min
} else = "TRIAGE_QUEUE" {
    _si_viol > 0
} else = "AUTO_FILE" {
    true
}

sum_invariants_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "sum_invariants"
    routing_si05 == "AUTO_FILE"
    cert := _certificate(452005, {
        "rule_id": "jdg.v3_p52_penny_granularity.sum_invariants",
        "decision_mode": "AUTO_POST",
        "_routing": routing_si05,
        "_routing_reason": "PENNY: invariants sum (pozycje=total, netto+VAT=brutto) bez naruszeń.",
        "_legal_basis": "P52-I05; UoR art. 4 ust. 1 (sprawdzalność) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "checks_run": _checks,
        "violations": _si_viol,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "sum_invariants"
    routing_si05 == "TRIAGE_QUEUE"
    cert := _certificate(452005, {
        "rule_id": "jdg.v3_p52_penny_granularity.sum_invariants",
        "decision_mode": "TRIAGE",
        "_routing": routing_si05,
        "_routing_reason": "PENNY: naruszenia invariants sum — rozjazd groszowy JPK/deklaracja.",
        "_legal_basis": "P52-I05; UoR art. 4 ust. 1 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Rozjazd groszowy sum — pełny trace do P37."],
        "checks_run": _checks,
        "violations": _si_viol,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "sum_invariants"
    routing_si05 == "BLOCK_AND_ALERT"
    cert := _certificate(452005, {
        "rule_id": "jdg.v3_p52_penny_granularity.sum_invariants",
        "decision_mode": "BLOCK",
        "_routing": routing_si05,
        "_routing_reason": "PENNY: bypass invariants sum — BLOCK.",
        "_legal_basis": "P52-I05; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Bypass sum invariants — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I06: DETERMINISM HASH — dwa wyliczenia = ten sam hash (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_dh := object.get(_ctx, "determinism_hash", {})
_trials := object.get(_dh, "trials", 0)
_det_fail := object.get(_dh, "determinism_failures", 0)
_tools_hash := object.get(_dh, "tools_with_hash", 0)

routing_dh06 = "BLOCK_AND_ALERT" {
    _has_flag("determinism_bypassed")
} else = "BLOCK_AND_ALERT" {
    _det_fail > 0
} else = "TRIAGE_QUEUE" {
    _tools_hash == 0
} else = "AUTO_FILE" {
    true
}

determinism_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "determinism_hash"
    routing_dh06 == "AUTO_FILE"
    cert := _certificate(452006, {
        "rule_id": "jdg.v3_p52_penny_granularity.determinism_hash",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dh06,
        "_routing_reason": "PENNY: wyliczenia deterministyczne (hash spójny) — deklaracja reprodukowalna.",
        "_legal_basis": "P52-I06; UoR art. 4 ust. 1; P11 certificate [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "trials": _trials,
        "tools_with_hash": _tools_hash,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "determinism_hash"
    routing_dh06 == "TRIAGE_QUEUE"
    cert := _certificate(452006, {
        "rule_id": "jdg.v3_p52_penny_granularity.determinism_hash",
        "decision_mode": "TRIAGE",
        "_routing": routing_dh06,
        "_routing_reason": "PENNY: narzędzia bez hasha determinizmu — dopiąć I06 (hash w certyfikacie).",
        "_legal_basis": "P52-I06; P11 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Brak hasha determinizmu w narzędziach."],
        "trials": _trials,
        "tools_with_hash": _tools_hash,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "determinism_hash"
    routing_dh06 == "BLOCK_AND_ALERT"
    cert := _certificate(452006, {
        "rule_id": "jdg.v3_p52_penny_granularity.determinism_hash",
        "decision_mode": "BLOCK",
        "_routing": routing_dh06,
        "_routing_reason": "PENNY: dryf determinizmu (dwa wyniki na ten sam input) — deklaracja niereprodukowalna = BLOCKER.",
        "_legal_basis": "P52-I06; V1 zasada 6; P10 golden [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Determinism drift — ZABLOKOWANE (BLOCKER)."],
        "determinism_failures": _det_fail,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I07: ROUNDING INTERACTION TESTS — łańcuchy bez rozjazdów (AN01/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_ri := object.get(_ctx, "rounding_interactions", {})
_ri_trials := object.get(_ri, "trials", 0)
_ri_drifts := object.get(_ri, "path_drifts", 0)
_ri_drifts_max := _th("v3_p52_path_drifts_max", 0)

routing_ri07 = "BLOCK_AND_ALERT" {
    _has_flag("rounding_bypassed")
} else = "TRIAGE_QUEUE" {
    _ri_trials == 0
} else = "TRIAGE_QUEUE" {
    _ri_drifts > _ri_drifts_max
} else = "AUTO_FILE" {
    true
}

rounding_interactions_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "rounding_interactions"
    routing_ri07 == "AUTO_FILE"
    cert := _certificate(452007, {
        "rule_id": "jdg.v3_p52_penny_granularity.rounding_interactions",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ri07,
        "_routing_reason": "PENNY: łańcuchy netto→VAT→brutto→sumy bez rozjazdów zaokrągleń.",
        "_legal_basis": "P52-I07; OP art. 107; rozp. PKPiR [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "trials": _ri_trials,
        "path_drifts": _ri_drifts,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "rounding_interactions"
    routing_ri07 == "TRIAGE_QUEUE"
    cert := _certificate(452007, {
        "rule_id": "jdg.v3_p52_penny_granularity.rounding_interactions",
        "decision_mode": "TRIAGE",
        "_routing": routing_ri07,
        "_routing_reason": "PENNY: rozjazdy ścieżek zaokrągleń (VAT per pozycja vs suma pełna) — standard do decyzji.",
        "_legal_basis": "P52-I07; OP art. 107 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Rozjazdy groszowe łańcuchów — rejestr jawny (I10)."],
        "trials": _ri_trials,
        "path_drifts": _ri_drifts,
        "drifts_max": _ri_drifts_max,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "rounding_interactions"
    routing_ri07 == "BLOCK_AND_ALERT"
    cert := _certificate(452007, {
        "rule_id": "jdg.v3_p52_penny_granularity.rounding_interactions",
        "decision_mode": "BLOCK",
        "_routing": routing_ri07,
        "_routing_reason": "PENNY: bypass testów interakcji zaokrągleń — BLOCK.",
        "_legal_basis": "P52-I07; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Bypass rounding interactions — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I08: NEGATIVE AMOUNT PATHS — korekty tymi samymi ścieżkami (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_np := object.get(_ctx, "negative_paths", {})
_np_cases := object.get(_np, "cases_total", 0)
_np_mismatch := object.get(_np, "naive_vs_symmetric_mismatch", 0)
_tools_neg := object.get(_np, "tools_with_negative_paths", 0)
_np_tools := object.get(_np, "tools_total", 1)

routing_np08 = "BLOCK_AND_ALERT" {
    _has_flag("negative_bypassed")
} else = "TRIAGE_QUEUE" {
    _np_cases == 0
} else = "TRIAGE_QUEUE" {
    _np_mismatch > 0
} else = "TRIAGE_QUEUE" {
    _tools_neg < _np_tools
} else = "AUTO_FILE" {
    true
}

negative_paths_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "negative_paths"
    routing_np08 == "AUTO_FILE"
    cert := _certificate(452008, {
        "rule_id": "jdg.v3_p52_penny_granularity.negative_paths",
        "decision_mode": "AUTO_POST",
        "_routing": routing_np08,
        "_routing_reason": "PENNY: ujemne kwoty (korekty/nadpłaty) przez symetryczne ścieżki half-up.",
        "_legal_basis": "P52-I08; OP art. 107 (symetria); art. 74a OP [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "cases_total": _np_cases,
        "tools_with_negative_paths": _tools_neg,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "negative_paths"
    routing_np08 == "TRIAGE_QUEUE"
    cert := _certificate(452008, {
        "rule_id": "jdg.v3_p52_penny_granularity.negative_paths",
        "decision_mode": "TRIAGE",
        "_routing": routing_np08,
        "_routing_reason": "PENNY: ścieżki ujemne niesymetryczne (floor+0.5 = half-DOWN) lub nieobjęte testami.",
        "_legal_basis": "P52-I08; OP art. 107 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Asymetria zaokrągleń ujemnych — korekty z dryfem."],
        "cases_total": _np_cases,
        "naive_vs_symmetric_mismatch": _np_mismatch,
        "tools_with_negative_paths": _tools_neg,
        "tools_total": _np_tools,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "negative_paths"
    routing_np08 == "BLOCK_AND_ALERT"
    cert := _certificate(452008, {
        "rule_id": "jdg.v3_p52_penny_granularity.negative_paths",
        "decision_mode": "BLOCK",
        "_routing": routing_np08,
        "_routing_reason": "PENNY: bypass ścieżek ujemnych — BLOCK.",
        "_legal_basis": "P52-I08; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Bypass negative paths — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I09: THRESHOLD CALENDAR AUDIT — kwoty narastające vs limity (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_tc := object.get(_ctx, "threshold_calendar", {})
_tc_params := object.get(_tc, "thresholds_params_total", 0)
_tc_candidates := object.get(_tc, "calendar_candidates", 0)
_annual_rules := object.get(_tc, "annual_rules_detected", 0)
_annual_min := _th("v3_p52_annual_rules_min", 3)

routing_tc09 = "BLOCK_AND_ALERT" {
    _has_flag("calendar_bypassed")
} else = "TRIAGE_QUEUE" {
    _tc_params == 0
} else = "TRIAGE_QUEUE" {
    _annual_rules < _annual_min
} else = "AUTO_FILE" {
    true
}

threshold_calendar_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "threshold_calendar"
    routing_tc09 == "AUTO_FILE"
    cert := _certificate(452009, {
        "rule_id": "jdg.v3_p52_penny_granularity.threshold_calendar",
        "decision_mode": "AUTO_POST",
        "_routing": routing_tc09,
        "_routing_reason": "PENNY: audyt roczny kwot narastających (zwolnienie, 30-krotność) z korektami w locie.",
        "_legal_basis": "P52-I09; VAT art. 113; ZUS art. 18d [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "thresholds_params_total": _tc_params,
        "annual_rules_detected": _annual_rules,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "threshold_calendar"
    routing_tc09 == "TRIAGE_QUEUE"
    cert := _certificate(452009, {
        "rule_id": "jdg.v3_p52_penny_granularity.threshold_calendar",
        "decision_mode": "TRIAGE",
        "_routing": routing_tc09,
        "_routing_reason": "PENNY: limity roczne bez audytu kalendarza narastania (z korektami w locie).",
        "_legal_basis": "P52-I09; VAT art. 113; ZUS art. 18d [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Kwoty narastające bez audytu granic rocznych."],
        "calendar_candidates": _tc_candidates,
        "annual_rules_detected": _annual_rules,
        "annual_min": _annual_min,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "threshold_calendar"
    routing_tc09 == "BLOCK_AND_ALERT"
    cert := _certificate(452009, {
        "rule_id": "jdg.v3_p52_penny_granularity.threshold_calendar",
        "decision_mode": "BLOCK",
        "_routing": routing_tc09,
        "_routing_reason": "PENNY: bypass audytu kalendarza progów — BLOCK.",
        "_legal_basis": "P52-I09; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Bypass threshold calendar — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I10: PENNY DRIFT TELEMETRY — rozjazdy → trend do zera (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_dt := object.get(_ctx, "drift_telemetry", {})
_drift_total := object.get(_dt, "penny_drift_total", -1)
_drift_target := _th("v3_p52_penny_drift_target", 0)

routing_dt10 = "BLOCK_AND_ALERT" {
    _has_flag("drift_bypassed")
} else = "TRIAGE_QUEUE" {
    _drift_total < 0
} else = "TRIAGE_QUEUE" {
    _drift_total > _drift_target
} else = "AUTO_FILE" {
    true
}

drift_telemetry_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "drift_telemetry"
    routing_dt10 == "AUTO_FILE"
    cert := _certificate(452010, {
        "rule_id": "jdg.v3_p52_penny_granularity.drift_telemetry",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dt10,
        "_routing_reason": "PENNY: zero rozjazdów groszowych (drift=0) — trend utrzymany.",
        "_legal_basis": "P52-I10; P37 telemetria [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "penny_drift_total": _drift_total,
        "target": _drift_target,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "drift_telemetry"
    routing_dt10 == "TRIAGE_QUEUE"
    cert := _certificate(452010, {
        "rule_id": "jdg.v3_p52_penny_granularity.drift_telemetry",
        "decision_mode": "TRIAGE",
        "_routing": routing_dt10,
        "_routing_reason": "PENNY: rozjazdy groszowe ponad cel (0) — alarm z full trace do P37.",
        "_legal_basis": "P52-I10; P37; AP12 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Drift groszowy — trend do zera, rejestr jawny."],
        "penny_drift_total": _drift_total,
        "target": _drift_target,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "drift_telemetry"
    routing_dt10 == "BLOCK_AND_ALERT"
    cert := _certificate(452010, {
        "rule_id": "jdg.v3_p52_penny_granularity.drift_telemetry",
        "decision_mode": "BLOCK",
        "_routing": routing_dt10,
        "_routing_reason": "PENNY: bypass telemetrii driftu — BLOCK.",
        "_legal_basis": "P52-I10; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Bypass drift telemetry — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I11: CURRENCY FUZZ — property-based inwarianty walutowe (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_cf := object.get(_ctx, "currency_fuzz", {})
_cf_trials := object.get(_cf, "trials", 0)
_cf_viol := object.get(_cf, "violations", 0)
_cf_trials_min := _th("v3_p52_fuzz_trials_min", 100)

routing_cf11 = "BLOCK_AND_ALERT" {
    _has_flag("fuzz_bypassed")
} else = "TRIAGE_QUEUE" {
    _cf_trials < _cf_trials_min
} else = "TRIAGE_QUEUE" {
    _cf_viol > 0
} else = "AUTO_FILE" {
    true
}

currency_fuzz_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "currency_fuzz"
    routing_cf11 == "AUTO_FILE"
    cert := _certificate(452011, {
        "rule_id": "jdg.v3_p52_penny_granularity.currency_fuzz",
        "decision_mode": "AUTO_POST",
        "_routing": routing_cf11,
        "_routing_reason": "PENNY: fuzz walutowy bez naruszeń invariants (kwota, kurs, data — dowolna kombinacja).",
        "_legal_basis": "P52-I11; VAT art. 31a; PIT art. 11a [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "trials": _cf_trials,
        "violations": _cf_viol,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "currency_fuzz"
    routing_cf11 == "TRIAGE_QUEUE"
    cert := _certificate(452011, {
        "rule_id": "jdg.v3_p52_penny_granularity.currency_fuzz",
        "decision_mode": "TRIAGE",
        "_routing": routing_cf11,
        "_routing_reason": "PENNY: fuzz za mało prób lub naruszenia invariants walutowych.",
        "_legal_basis": "P52-I11; P34-I04 (fuzz min 1000) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Invariants walutowe naruszone w fuzz."],
        "trials": _cf_trials,
        "violations": _cf_viol,
        "trials_min": _cf_trials_min,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "currency_fuzz"
    routing_cf11 == "BLOCK_AND_ALERT"
    cert := _certificate(452011, {
        "rule_id": "jdg.v3_p52_penny_granularity.currency_fuzz",
        "decision_mode": "BLOCK",
        "_routing": routing_cf11,
        "_routing_reason": "PENNY: bypass fuzzu walutowego — BLOCK.",
        "_legal_basis": "P52-I11; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Bypass currency fuzz — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P52-I12: ARITHMETIC DOOMSDAY SUITE — skrajne wartości fail-closed (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_dd := object.get(_ctx, "doomsday", {})
_dd_cases := object.get(_dd, "cases_total", 0)
_dd_fail := object.get(_dd, "failures", 0)
_dd_zero := object.get(_dd, "div_zero_path", "MISSING")

routing_dd12 = "BLOCK_AND_ALERT" {
    _has_flag("doomsday_bypassed")
} else = "BLOCK_AND_ALERT" {
    _dd_fail > 0
} else = "BLOCK_AND_ALERT" {
    _dd_zero == "MISSING"
} else = "TRIAGE_QUEUE" {
    _dd_cases == 0
} else = "AUTO_FILE" {
    true
}

doomsday_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "doomsday"
    routing_dd12 == "AUTO_FILE"
    cert := _certificate(452012, {
        "rule_id": "jdg.v3_p52_penny_granularity.doomsday",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dd12,
        "_routing_reason": "PENNY: skrajne wartości (max/min long, overflow, dzielenie przez 0) w ścieżce fail-closed.",
        "_legal_basis": "P52-I12; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "cases_total": _dd_cases,
        "div_zero_path": _dd_zero,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "doomsday"
    routing_dd12 == "TRIAGE_QUEUE"
    cert := _certificate(452012, {
        "rule_id": "jdg.v3_p52_penny_granularity.doomsday",
        "decision_mode": "TRIAGE",
        "_routing": routing_dd12,
        "_routing_reason": "PENNY: suite doomsday pusty — uzupełnić przypadki skrajne.",
        "_legal_basis": "P52-I12 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Brak testów skrajnych wartości."],
        "cases_total": _dd_cases,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "doomsday"
    routing_dd12 == "BLOCK_AND_ALERT"
    cert := _certificate(452012, {
        "rule_id": "jdg.v3_p52_penny_granularity.doomsday",
        "decision_mode": "BLOCK",
        "_routing": routing_dd12,
        "_routing_reason": "PENNY: silnik wysypał się na arytmetyce lub bypass — BLOCK.",
        "_legal_basis": "P52-I12; V1 zasada 6 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P52] Arytmetyka poza kontrolą fail-closed — ZABLOKOWANE."],
        "failures": _dd_fail,
        "div_zero_path": _dd_zero,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny, fail-closed)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := standards_register_decision {
    standards_register_decision.rule_id != ""
} else := penny_boundary_decision {
    penny_boundary_decision.rule_id != ""
} else := rate_provenance_decision {
    rate_provenance_decision.rule_id != ""
} else := weekend_rate_decision {
    weekend_rate_decision.rule_id != ""
} else := sum_invariants_decision {
    sum_invariants_decision.rule_id != ""
} else := determinism_decision {
    determinism_decision.rule_id != ""
} else := rounding_interactions_decision {
    rounding_interactions_decision.rule_id != ""
} else := negative_paths_decision {
    negative_paths_decision.rule_id != ""
} else := threshold_calendar_decision {
    threshold_calendar_decision.rule_id != ""
} else := drift_telemetry_decision {
    drift_telemetry_decision.rule_id != ""
} else := currency_fuzz_decision {
    currency_fuzz_decision.rule_id != ""
} else := doomsday_decision {
    doomsday_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p52_penny_granularity.no_match",
    "package": "jdg.v3_p52_penny_granularity",
    "priority": 999999,
}
