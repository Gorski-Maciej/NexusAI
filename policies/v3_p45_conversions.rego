# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P45 KONWERSJE STUB→REGUŁA WARUNKOWA (wzorzec I03/I04/I12)
# ===============================================================================
# 5 wzorcowych konwersji stubów {true} na reguły warunkowe (prompt P45 Sekcja 13
# pkt 20). Każda konwersja:
#   * ma warunek z input (przesłanki materiałowe),
#   * próg z data.jdg.thresholds.v3_p45_conversions (ADR-002, P06),
#   * jawną gałąź else → NEEDS_ADVICE (fail-closed, V1 zasada 6),
#   * test negatywny w tests/rego/test_v3_p45_conversions.rego (I04),
#   * cytat przepisu w sekcji PARITY_WITH_ISAP (I12) — status [NIEZWERYFIKOWANE].
#
# Status lifecycle: CANDIDATE — awans do ACTIVE wyłącznie po weryfikacji
# merytorycznej człowieka (4-eyes) i potwierdzeniu cytatu w ISAP (P07/P45-I09).
# Rule_id: jdg.v3_p45_conversions.<reguła>; parametry wyłącznie data.thresholds.
# Integracja: final_verdict_p109 (main_jdg.rego) — aktywna tylko z flagą
# input.jdg_entrepreneur.v3_p45_check == true (nieaktywna w produkcji).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p45_conversions

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p45_check", false) == true
_ctx := object.get(input, "v3_p45_conversions", {})

_th := data.jdg.thresholds.v3_p45_conversions

# ── Snapshot progów konwersji (ADR-002) ────────────────────────────────────────
_th_ok = true {
    count(_th) > 0
} else = false {
    true
}

fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p45_conversions.thresholds_missing",
    "package": "jdg.v3_p45_conversions",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "P45-CONV: brak snapshotu data.jdg.thresholds.v3_p45_conversions.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P45-CONV] Brak progów konwersji — decyzje materiałowe ZABLOKOWANE."],
}

# ═══════════════════════════════════════════════════════════════════════════════
# KONWERSJA 1: jdg.uor.obligation.a2.r6 (stub {true}) → próg UoR 2M EUR
# PARITY_WITH_ISAP: UoR art. 2 ust. 1 pkt 5 — obowiązek ksiąg rachunkowych od
#   2 000 000 EUR przychodów [NIEZWERYFIKOWANE — ISAP poza sesją; P47].
# Status: CANDIDATE (4-eyes wymagane)
# ═══════════════════════════════════════════════════════════════════════════════
_sel_uor_a2 := object.get(_ctx, "analysis", "") == "uor_a2"
_sel_uor_a3 := object.get(_ctx, "analysis", "") == "uor_a3"
_sel_mdr := object.get(_ctx, "analysis", "") == "mdr_hallmark"
_sel_pcc := object.get(_ctx, "analysis", "") == "pcc_a1"
_sel_wht := object.get(_ctx, "analysis", "") == "wht_foreign"

uor_a2_threshold := decision {
    _activated
    _th_ok
    _sel_uor_a2
    revenue_eur := object.get(_ctx, "prior_year_revenue_eur", null)
    revenue_eur != null
    threshold_eur := object.get(_th, "v3_p45_conv_uor_threshold_eur", 2000000)
    revenue_eur >= threshold_eur
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.uor_a2_threshold",
        "package": "jdg.v3_p45_conversions",
        "priority": 445101,
        "decision_mode": "MANUAL_REVIEW",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "P45-CONV: przychód ≥ progu UoR — obowiązek pełnych ksiąg (CANDIDATE, wymaga 4-eyes).",
        "_legal_basis": "UoR art. 2 ust. 1 pkt 5 [NIEZWERYFIKOWANE]",
        "_warnings": [],
        "revenue_eur": revenue_eur,
        "threshold_eur": threshold_eur,
    }
} else := decision {
    _activated
    _th_ok
    _sel_uor_a2
    revenue_eur := object.get(_ctx, "prior_year_revenue_eur", null)
    revenue_eur != null
    threshold_eur := object.get(_th, "v3_p45_conv_uor_threshold_eur", 2000000)
    revenue_eur < threshold_eur
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.uor_a2_threshold",
        "decision_mode": "MANUAL_REVIEW",
        "_routing": "AUTO_FILE",
        "_routing_reason": "P45-CONV: przychód < progu UoR — pełne księgi niewymagane (KPiR dopuszczalne).",
        "_legal_basis": "UoR art. 2 ust. 1 pkt 5 [NIEZWERYFIKOWANE]",
        "_warnings": [],
        "revenue_eur": revenue_eur,
        "threshold_eur": threshold_eur,
    }
} else := decision {
    _activated
    _th_ok
    _sel_uor_a2
    object.get(_ctx, "prior_year_revenue_eur", null) == null
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.uor_a2_threshold",
        "decision_mode": "NEEDS_ADVICE",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "P45-CONV: brak danych o przychodzie — fail-closed, nigdy cicha decyzja.",
        "_legal_basis": "UoR art. 2 ust. 1 pkt 5 [NIEZWERYFIKOWANE]; V1 zasada 6",
        "_warnings": ["[V3-P45-CONV] Brak prior_year_revenue_eur — brak przesłanki."],
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KONWERSJA 2: jdg.micro.uor.a3.r8 (stub {true}) → wyłączenia UoR art. 3
# PARITY_WITH_ISAP: UoR art. 3 — osoby fizyczne z ewidencją przychodów/kosztów
#   nie prowadzą ksiąg [NIEZWERYFIKOWANE — ISAP poza sesją; P47].
# Status: CANDIDATE (4-eyes wymagane)
# ═══════════════════════════════════════════════════════════════════════════════
_uor_a3_met {
    object.get(_ctx, "tax_form", "") == "JDG_osoba_fizyczna"
    object.get(_ctx, "keeps_revenue_cost_ledger", false) == true
}

uor_a3_conditions := decision {
    _activated
    _th_ok
    _sel_uor_a3
    _uor_a3_met
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.uor_a3_conditions",
        "package": "jdg.v3_p45_conversions",
        "priority": 445102,
        "decision_mode": "MANUAL_REVIEW",
        "_routing": "AUTO_FILE",
        "_routing_reason": "P45-CONV: JDG os. fiz. z ewidencją przychodów/kosztów — księgi niewymagane (CANDIDATE).",
        "_legal_basis": "UoR art. 3 [NIEZWERYFIKOWANE]",
        "_warnings": [],
    }
} else := decision {
    _activated
    _th_ok
    _sel_uor_a3
    not _uor_a3_met
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.uor_a3_conditions",
        "decision_mode": "NEEDS_ADVICE",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "P45-CONV: przesłanki art. 3 niepełne — wymaga opinii księgowej.",
        "_legal_basis": "UoR art. 3 [NIEZWERYFIKOWANE]",
        "_warnings": ["[V3-P45-CONV] Brak przesłanek wyłączenia (tax_form/ewidencja)."],
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KONWERSJA 3: jdg.mdr.hallmarks.general.r4 (stub {true}) → MDR znacznik ogólny
# PARITY_WITH_ISAP: Ordynacja art. 86a §1 — znacznik ogólny + progi
#   [NIEZWERYFIKOWANE — ISAP poza sesją; P47].
# Status: CANDIDATE (4-eyes wymagane)
# ═══════════════════════════════════════════════════════════════════════════════
_mdr_prerequisites_met {
    object.get(_ctx, "cross_border_arrangement", false) == true
    object.get(_ctx, "main_benefit_test_positive", false) == true
    object.get(_ctx, "arrangement_value_pln", 0) >= object.get(_th, "v3_p45_conv_mdr_main_benefit", 2500000)
}

mdr_hallmark_a := decision {
    _activated
    _th_ok
    _sel_mdr
    object.get(_ctx, "cross_border_arrangement", false) == true
    object.get(_ctx, "main_benefit_test_positive", false) == true
    value_pln := object.get(_ctx, "arrangement_value_pln", 0)
    threshold_pln := object.get(_th, "v3_p45_conv_mdr_main_benefit", 2500000)
    value_pln >= threshold_pln
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.mdr_hallmark_a",
        "package": "jdg.v3_p45_conversions",
        "priority": 445103,
        "decision_mode": "MANUAL_REVIEW",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "P45-CONV: schemat transgraniczny + test głównej korzyści + próg — zgłoszenie MDR (CANDIDATE).",
        "_legal_basis": "Ordynacja art. 86a §1 [NIEZWERYFIKOWANE]",
        "_warnings": [],
        "value_pln": value_pln,
    }
} else := decision {
    _activated
    _th_ok
    _sel_mdr
    not _mdr_prerequisites_met
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.mdr_hallmark_a",
        "decision_mode": "NEEDS_ADVICE",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "P45-CONV: przesłanki MDR niepełne (transgraniczność/korzyść/próg) — opinia doradcy.",
        "_legal_basis": "Ordynacja art. 86a §1 [NIEZWERYFIKOWANE]",
        "_warnings": ["[V3-P45-CONV] Brak pełnych przesłanek znacznika ogólnego."],
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KONWERSJA 4: jdg.pcc.sales_agreements.a1.r15 (stub {true}) → podmiotowość PCC
# PARITY_WITH_ISAP: PCC art. 1 ust. 1 pkt 1 — umowa sprzedaży rzeczy/praw
#   [NIEZWERYFIKOWANE — ISAP poza sesją; P47].
# Status: CANDIDATE (4-eyes wymagane)
# ═══════════════════════════════════════════════════════════════════════════════
_pcc_prerequisites_met {
    object.get(_ctx, "agreement_type", "") == "sprzedaz"
    object.get(_ctx, "made_in_poland", false) == true
    object.get(_ctx, "not_vat_taxed", false) == true
    object.get(_ctx, "agreement_value_pln", 0) >= object.get(_th, "v3_p45_conv_pcc_min_pln", 1000)
}

pcc_a1_condition := decision {
    _activated
    _th_ok
    _sel_pcc
    object.get(_ctx, "agreement_type", "") == "sprzedaz"
    object.get(_ctx, "made_in_poland", false) == true
    object.get(_ctx, "not_vat_taxed", false) == true
    value_pln := object.get(_ctx, "agreement_value_pln", 0)
    min_pln := object.get(_th, "v3_p45_conv_pcc_min_pln", 1000)
    value_pln >= min_pln
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.pcc_a1_condition",
        "package": "jdg.v3_p45_conversions",
        "priority": 445104,
        "decision_mode": "MANUAL_REVIEW",
        "_routing": "AUTO_FILE",
        "_routing_reason": "P45-CONV: umowa sprzedaży nieopodatkowana VAT ≥ progu — PCC (CANDIDATE).",
        "_legal_basis": "PCC art. 1 ust. 1 pkt 1; art. 9 [NIEZWERYFIKOWANE]",
        "_warnings": [],
        "value_pln": value_pln,
    }
} else := decision {
    _activated
    _th_ok
    _sel_pcc
    not _pcc_prerequisites_met
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.pcc_a1_condition",
        "decision_mode": "NEEDS_ADVICE",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "P45-CONV: przesłanki PCC niepełne (typ/lokalizacja/VAT/próg) — weryfikacja.",
        "_legal_basis": "PCC art. 1 ust. 1 pkt 1 [NIEZWERYFIKOWANE]",
        "_warnings": ["[V3-P45-CONV] Brak przesłanek podmiotowości PCC."],
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KONWERSJA 5: jdg.edge_cases.wht_foreign_service (stub {true}) → WHT 20%
# PARITY_WITH_ISAP: UoWHT (CIT) art. 21 ust. 1 pkt 2a — 20% od usług z
#   nie-rezydentem [NIEZWERYFIKOWANE — ISAP poza sesją; P47].
# Status: CANDIDATE (4-eyes wymagane)
# ═══════════════════════════════════════════════════════════════════════════════
_wht_prerequisites_met {
    object.get(_ctx, "service_rendered_in_poland", false) == true
    object.get(_ctx, "buyer_no_pl_residency", false) == true
}

wht_foreign_service := decision {
    _activated
    _th_ok
    _sel_wht
    _wht_prerequisites_met
    rate_pct := object.get(_th, "v3_p45_conv_wht_rate_pct", 20)
    rate_pct > 0
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.wht_foreign_service",
        "package": "jdg.v3_p45_conversions",
        "priority": 445105,
        "decision_mode": "MANUAL_REVIEW",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "P45-CONV: usługa w PL dla nierezydenta — WHT 20% zryczałtowany (CANDIDATE).",
        "_legal_basis": "UoWHT art. 21 ust. 1 pkt 2a [NIEZWERYFIKOWANE]",
        "_warnings": [],
        "rate_pct": rate_pct,
    }
} else := decision {
    _activated
    _th_ok
    _sel_wht
    not _wht_prerequisites_met
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.wht_foreign_service",
        "decision_mode": "NEEDS_ADVICE",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "P45-CONV: przesłanki WHT niepełne (miejsce świadczenia/rezydencja) — opinia.",
        "_legal_basis": "UoWHT art. 21 ust. 1 pkt 2a [NIEZWERYFIKOWANE]",
        "_warnings": ["[V3-P45-CONV] Brak przesłanek poboru WHT."],
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK — deterministyczny (reguła warunkowa, NIE stub {true})
# ═══════════════════════════════════════════════════════════════════════════════
needs_advice := decision {
    _activated
    decision := {
        "matched": true,
        "rule_id": "jdg.v3_p45_conversions.needs_advice",
        "package": "jdg.v3_p45_conversions",
        "priority": 999998,
        "decision_mode": "NEEDS_ADVICE",
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "P45-CONV: brak dopasowania konwersji — jawnie NEEDS_ADVICE (fail-closed, nie warunek zawsze prawdziwy).",
        "_legal_basis": "V1 zasada 6 (fail-closed)",
        "_warnings": [],
    }
}

decide := fail_closed_decision {
    not _th_ok
} else := uor_a2_threshold {
    uor_a2_threshold.rule_id == "jdg.v3_p45_conversions.uor_a2_threshold"
} else := uor_a3_conditions {
    uor_a3_conditions.rule_id == "jdg.v3_p45_conversions.uor_a3_conditions"
} else := mdr_hallmark_a {
    mdr_hallmark_a.rule_id == "jdg.v3_p45_conversions.mdr_hallmark_a"
} else := pcc_a1_condition {
    pcc_a1_condition.rule_id == "jdg.v3_p45_conversions.pcc_a1_condition"
} else := wht_foreign_service {
    wht_foreign_service.rule_id == "jdg.v3_p45_conversions.wht_foreign_service"
} else := needs_advice {
    needs_advice.rule_id == "jdg.v3_p45_conversions.needs_advice"
} else := no_match_decision {
    true
}

no_match_decision := {
    "matched": false,
    "rule_id": "jdg.v3_p45_conversions.no_match",
    "package": "jdg.v3_p45_conversions",
    "priority": 999999,
}
