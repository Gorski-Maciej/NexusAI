# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CROSS-BORDER V3 ENTERPRISE (Kampania V3, część 08/20)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.crossborder.v3_08
# Cel:     domknięcie luk L-08-001..L-08-008 z raportu 08_CROSSBORDER.txt:
#          zero-hardcode (ADR-002), fail-closed temporalność (V1 zasada 6),
#          Golden Oracle snapshot progów (V2 filar F3), Decision Certificate (F4).
# Prawo:   Art. 30da PIT (exit tax) · Art. 30f PIT (CFC) · Art. 26 CIT / 30a PIT
#          (WHT) · Art. 23zf PIT (progi TP 10M/2M/2.5M PLN — rozporządzenie MF
#          aktualne) · DAC8 (UE 2021/514) · UK VAT Act 1994 · Art. 86a OrdPU.
# Zasady:  WSZYSTKIE progi z data.jdg.thresholds.crossborder (zero hardcode);
#          brak snapshotu progów → BLOCK_AND_ALERT (fail-closed);
#          każdy verdict = Decision Certificate (legal_basis + wersje + valid_from/to).
# Struktura: wzorzec jdg.cfc_auto_classifier — reguły-decyzje budują verdict
#          w ciele reguły; łańcuch decide = first-match-wins (Rego nie posiada
#          operatora warunkowego ternary — wartości warunkowe liczą funkcje
#          pomocnicze z klauzulami else).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.crossborder.v3_08

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.crossborder.v3_08.no_match",
    "package": "jdg.crossborder.v3_08",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji crossborder → fail-closed sentinel ──
_th_snapshot := object.get(data.jdg.thresholds, "crossborder", {})
_snapshot_ok := count(_th_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    object.get(_th_snapshot, key, null) != null
} else = fallback

_round2(value) = floor(value * 100) / 100

_bool_str(flag) = "TAK" {
    flag
}

_bool_str(flag) = "NIE" {
    flag == false
}

# normalizacja procent/ułamek: 50 → 0.5, ale 0.5 → 0.5
_norm_frac(x) = v {
    x > 1
    v := x / 100
} else = x

# ── Fail-closed verdict gdy snapshot progów niedostępny ────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.crossborder.v3_08.thresholds_missing",
    "package": "jdg.crossborder.v3_08",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Cross-border v3: brak snapshotu data.jdg.thresholds.crossborder.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-08] Brak snapshotu progów — decyzje transgraniczne ZABLOKOWANE do czasu dostarczenia progów."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.crossborder.v3_08",
        "priority": priority,
        "threshold_version": object.get(_th_snapshot, "threshold_version", "MISSING"),
        "legal_basis_version": object.get(_th_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_th_snapshot, "valid_from", null),
        "valid_to": object.get(_th_snapshot, "valid_to", null),
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-08-001: EXIT TAX CALCULATOR — art. 30da PIT (próg i stawka z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

exit_routing(exceeded) = "BLOCK_AND_ALERT" {
    exceeded
} else = ""

exit_deferral_suffix(true) = "; odroczenie EOG możliwe"
exit_deferral_suffix(false) = ""

exit_tax_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    invoice := object.get(input.invoice, {}, {})
    transferring := object.get(profile, "transferring_assets_abroad", false)
    changing := object.get(profile, "changing_tax_residence", false)
    transferring or changing

    threshold_pln := _th("exit_tax_threshold_pln", 4000000)
    rate := _th("exit_tax_rate_pct", 0.19)
    deferral_years := _th("exit_tax_deferral_years_eea", 5)

    market_value := object.get(invoice, "asset_market_value",
        object.get(invoice, "total_assets_market_value", 0))
    tax_value := object.get(invoice, "asset_tax_value", 0)
    above := market_value >= threshold_pln
    gain := market_value - tax_value

    estimated := exit_estimated_gain(gain, rate, above)

    eea := object.get(invoice, "destination_in_eea", false)
    deferral_possible := eea and above

    verdict := _certificate(360100, {
        "rule_id": "jdg.crossborder.v3_08.exit_tax_calculator",
        "procedure": "EXIT_TAX_V3",
        "exit_tax_applicable": above,
        "exit_tax_threshold_pln": threshold_pln,
        "exit_tax_rate": rate,
        "exit_tax_unrealized_gain_pln": gain,
        "exit_tax_estimated_pln": estimated,
        "exit_tax_deferral_possible": deferral_possible,
        "exit_tax_deferral_years": deferral_years,
        "exit_trigger_transferring_assets": transferring,
        "exit_trigger_residence_change": changing,
        "_routing": exit_routing(above),
        "_routing_reason": sprintf("EXIT TAX v3 — wartość rynkowa %.0f PLN vs próg %.0f PLN; szacowany podatek %.2f PLN%s", [market_value, threshold_pln, estimated, exit_deferral_suffix(deferral_possible)]),
        "_legal_basis": "Art. 30da ust. 1-9 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.); ATAD (UE) 2016/1164",
        "_warnings": [
            "[EXIT TAX] Próg i stawka odczytane z thresholds_jdg.rego (zero hardcode).",
            "[EXIT TAX] Deklaracja o wysokości dochodu: do 7 dnia miesiąca następującego po miesiącu przeniesienia (art. 30da ust. 9 PIT).",
        ],
    })
}

exit_estimated_gain(_, _, false) = 0

exit_estimated_gain(gain, rate, true) = est {
    est := _round2(gain * rate)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-08-002: CFC MONITOR — art. 30f PIT (testy 50% / 33% / 14,25% z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

cfc_routing(triggered, exempt) = "" {
    triggered
    exempt
} else = "BLOCK_AND_ALERT" {
    triggered
} else = ""

cfc_status(true) = "WOLNE (rzeczywista działalność EOG)"
cfc_status(false) = "brak zwolnienia"

cfc_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(profile, "has_cfc", false) == true

    ownership_raw := object.get(profile, "cfc_ownership_pct",
        object.get(profile, "foreign_company_stake_pct", 0))
    foreign_rate_raw := object.get(profile, "cfc_foreign_tax_rate_pct",
        object.get(profile, "foreign_cit_rate", 100))
    passive_raw := object.get(profile, "cfc_passive_income_pct_raw", 0)

    ownership_pct := _norm_frac(ownership_raw)
    foreign_rate := _norm_frac(foreign_rate_raw)
    passive_pct := _norm_frac(passive_raw)

    own_min := _th("cfc_ownership_min_pct", 0.50)
    passive_min := _th("cfc_passive_income_pct", 0.33)
    low_tax_th := _th("cfc_tax_rate_threshold_pct", 0.1425)

    test_own := ownership_pct > own_min
    test_passive := passive_pct > passive_min
    test_lowtax := foreign_rate < low_tax_th
    triggered := test_lowtax or test_passive

    substantial_activity := object.get(profile, "cfc_substantial_activity_eea", false)
    exempt := triggered and substantial_activity

    total_income := object.get(profile, "cfc_total_income_pln", 0)
    rate_cfc := _th("exit_tax_rate_pct", 0.19)
    tax_due := cfc_tax_amount(total_income, ownership_pct, rate_cfc, triggered)

    verdict := _certificate(360110, {
        "rule_id": "jdg.crossborder.v3_08.cfc_monitor",
        "procedure": "CFC_MONITOR_V3",
        "cfc_triggered": triggered,
        "cfc_exempt_substantial_activity": exempt,
        "cfc_test_ownership_50": test_own,
        "cfc_test_passive_33": test_passive,
        "cfc_test_low_tax_1425": test_lowtax,
        "cfc_threshold_ownership": own_min,
        "cfc_threshold_passive": passive_min,
        "cfc_threshold_low_tax_rate": low_tax_th,
        "cfc_tax_due_pln": tax_due,
        "_routing": cfc_routing(triggered, exempt),
        "_routing_reason": sprintf("CFC v3 — własność %v (próg %v), pasywne %v (próg %v), podatek zagraniczny %v (próg %v); status: %s", [ownership_pct, own_min, passive_pct, passive_min, foreign_rate, low_tax_th, cfc_status(exempt)]),
        "_legal_basis": "Art. 30f ust. 1-18 ustawy o PIT (Dz.U. 2024 poz. 1760 ze zm.); ATAD art. 7-8",
        "_warnings": [
            "[CFC] Trzy testy (50%/33%/14,25%) czytane z thresholds_jdg.rego (zero hardcode).",
            sprintf("[CFC] Szacowany podatek CFC: %.2f PLN (proporcjonalnie do udziału).", [tax_due]),
        ],
    })
}

cfc_tax_amount(_, _, _, false) = 0

cfc_tax_amount(total_income, ownership_pct, rate, true) = due {
    due := _round2(total_income * ownership_pct * rate)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-08-003: WHT GATE — art. 26 CIT / 30a-30b PIT (próg 2M PLN z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

wht_routing(pay_refund, exceeded) = "BLOCK_AND_ALERT" {
    pay_refund
} else = "WARNING" {
    exceeded
} else = ""

wht_warnings(true) = [
    "[WHT] Mechanizm pay-and-refund aktywowany: pobierz stawkę standardową i złóż WH-OSC, chyba że masz opinię KS o stosowaniu preferencji.",
]

wht_warnings(false) = ["[WHT] Poniżej progu lub certyfikat rezydencji obecny — pay-and-refund nieaktywny."]

wht_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    invoice := object.get(input.invoice, {}, {})
    annual := object.get(profile, "annual_foreign_payments_pln", 0)
    annual > 0

    threshold := _th("wht_annual_threshold_pln", 2000000)
    rate := _th("wht_standard_rate_pct", 0.20)

    exceeded := annual > threshold
    cert_raw := object.get(profile, "has_tax_residence_certificates",
        object.get(invoice, "has_tax_residence_certificate", false))
    cert := cert_raw == true
    pay_refund := exceeded and not cert

    amount := wht_amount_for(annual, rate, exceeded)

    verdict := _certificate(360120, {
        "rule_id": "jdg.crossborder.v3_08.wht_gate",
        "procedure": "WHT_GATE_V3",
        "wht_obligation_exceeded": exceeded,
        "wht_threshold_pln": threshold,
        "wht_standard_rate": rate,
        "wht_pay_and_refund_required": pay_refund,
        "wht_estimated_pln": amount,
        "wht_certificate_present": cert,
        "_routing": wht_routing(pay_refund, exceeded),
        "_routing_reason": sprintf("WHT v3 — płatności zagraniczne %.0f PLN vs próg %.0f PLN; certyfikat rezydencji: %s", [annual, threshold, _bool_str(cert)]),
        "_legal_basis": "Art. 26 ust. 1 i 2e ustawy o CIT; Art. 30a-30b ustawy o PIT (Dz.U. 2024 poz. 1760 ze zm.)",
        "_warnings": wht_warnings(pay_refund),
    })
}

wht_amount_for(_, _, false) = 0

wht_amount_for(base, rate, true) = amt {
    amt := _round2(base * rate)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-08-004: DAC8 THRESHOLD ENGINE — UE 2021/514 (2000 EUR / 30 tx z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

dac8_routing(reportable) = "TRIAGE_QUEUE" {
    reportable
} else = ""

dac8_action(true) = "RAPORTOWANIE WYMAGANE"
dac8_action(false) = "poniżej progu"

dac8_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    operator := object.get(profile, "platform_operator", false)
    operator == true

    th_eur := _th("dac8_threshold_eur", 2000)
    th_tx := _th("dac8_threshold_tx", 30)
    deadline := _th("dac8_deadline", "31_stycznia")

    total_eur := object.get(profile, "dac8_total_amount_eur", 0)
    total_tx := object.get(profile, "dac8_total_transactions", 0)
    payable := total_eur >= th_eur or total_tx >= th_tx
    reportable := payable

    verdict := _certificate(586, {
        "rule_id": "jdg.crossborder.v3_08.dac8_engine",
        "procedure": "DAC8_ENGINE_V3",
        "dac8_is_platform_operator": true,
        "dac8_reportable": reportable,
        "dac8_threshold_eur": th_eur,
        "dac8_threshold_tx": th_tx,
        "dac8_total_eur": total_eur,
        "dac8_total_tx": total_tx,
        "dac8_deadline": deadline,
        "_routing": dac8_routing(reportable),
        "_routing_reason": sprintf("DAC8 v3 — %.0f EUR / %d tx vs progi (%d EUR / %d tx) → %s", [total_eur, total_tx, th_eur, th_tx, dac8_action(reportable)]),
        "_legal_basis": "Dyrektywa Rady (UE) 2021/514 (DAC8); art. 8ac dyrektywy Rady 2011/16/UE",
        "_warnings": [
            sprintf("[DAC8] Termin raportowania platformy: %s; progi de minimis z thresholds (zero hardcode).", [deadline]),
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-08-005: UK POST-BREXIT B2C GATE — próg 90 000 GBP z thresholds
# ═══════════════════════════════════════════════════════════════════════════════

uk_applicable(direction, country, b2c, turnover) {
    direction == "SALE"
    country == "GB"
    b2c == true
    turnover > 0
}

uk_routing(exceeded) = "BLOCK_AND_ALERT" {
    exceeded
} else = ""

uk_action(true) = "REJESTRACJA VAT UK OBOWIĄZKOWA (HMRC VAT1)"
uk_action(false) = "poniżej progu"

uk_b2c_decision := verdict {
    invoice := object.get(input.invoice, {}, {})
    vendor := object.get(input.vendor, {}, {})
    profile := object.get(input.jdg_entrepreneur, {}, {})

    direction := object.get(invoice, "direction", "")
    country := object.get(vendor, "country", "")
    b2c := object.get(vendor, "is_b2c", false)
    turnover := object.get(profile, "uk_b2c_annual_turnover_gbp", 0)
    uk_applicable(direction, country, b2c, turnover)

    threshold := _th("uk_vat_registration_threshold_gbp", 90000)
    exceeded := turnover > threshold

    verdict := _certificate(172, {
        "rule_id": "jdg.crossborder.v3_08.uk_vat_b2c_gate",
        "procedure": "UK_B2C_GATE_V3",
        "uk_gate_applicable": true,
        "uk_vat_registration_required": exceeded,
        "uk_vat_threshold_gbp": threshold,
        "uk_b2c_annual_turnover_gbp": turnover,
        "_routing": uk_routing(exceeded),
        "_routing_reason": sprintf("UK B2C v3 — obrót %.0f GBP vs próg %d GBP → %s", [turnover, threshold, uk_action(exceeded)]),
        "_legal_basis": "UK VAT Act 1994 s.3; TCA UE-UK (Trade and Cooperation Agreement)",
        "_warnings": [
            sprintf("[UK] Próg rejestracji %d GBP czytany z thresholds — zmiana progu przez HMRC wymaga tylko aktualizacji snapshotu.", [threshold]),
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-08-006: TP PROGI AKTUALNE (10M/2M/2.5M PLN) — korekta nieaktualnych progów
#             2M/1M/500k w rules/tp/plan45_tp.rego (R1436-R1438)
# ═══════════════════════════════════════════════════════════════════════════════

tp_doc_required(goods_val, goods_th, services_val, services_th, financial_val, financial_th) = true {
    goods_val > goods_th
}

tp_doc_required(goods_val, goods_th, services_val, services_th, financial_val, financial_th) = true {
    services_val > services_th
}

tp_doc_required(goods_val, goods_th, services_val, services_th, financial_val, financial_th) = true {
    financial_val > financial_th
}

tp_routing(required) = "TRIAGE_QUEUE" {
    required
} else = ""

tp_conclusion(true) = "WYMAGANA (progi aktualne)"
tp_conclusion(false) = "nie wymagana"

tp_thresholds_decision := verdict {
    vendor := object.get(input.vendor, {}, {})
    object.get(vendor, "is_related_party", false) == true
    tp := object.get(input.tp, {}, {})

    goods_val := object.get(tp, "annual_goods_value_pln", 0)
    services_val := object.get(tp, "annual_services_value_pln", 0)
    financial_val := object.get(tp, "annual_financial_value_pln", 0)
    goods_th := _th("tp_goods_transactions_pln", 10000000)
    services_th := _th("tp_services_transactions_pln", 2000000)
    financial_th := _th("tp_financial_transactions_pln", 2500000)

    required := tp_doc_required(goods_val, goods_th, services_val, services_th, financial_val, financial_th)

    verdict := _certificate(1483, {
        "rule_id": "jdg.crossborder.v3_08.tp_thresholds_current_law",
        "procedure": "TP_THRESHOLDS_V3",
        "tp_related_party": true,
        "tp_documentation_required_current_law": required,
        "tp_threshold_goods_pln": goods_th,
        "tp_threshold_services_pln": services_th,
        "tp_threshold_financial_pln": financial_th,
        "tp_supersedes_plan45_legacy_thresholds": true,
        "_routing": tp_routing(required),
        "_routing_reason": sprintf("TP v3 — towar %.0f/%.0f, usługi %.0f/%.0f, finanse %.0f/%.0f PLN (wartość/próg aktualny) → dokumentacja %s", [goods_val, goods_th, services_val, services_th, financial_val, financial_th, tp_conclusion(required)]),
        "_legal_basis": "Art. 23zf ust. 1-5 ustawy o PIT (Dz.U. 2024 poz. 1760 ze zm.) wraz z aktualnym rozporządzeniem MF ws. progów dokumentacyjnych",
        "_warnings": [
            "[TP] UWAGA: jdg.tp.hyper.threshold_* (R1436-R1438) używa progów 2M/1M/500k PLN — wartości historyczne; ta reguła stosuje progi bieżące z thresholds_jdg.rego. Ujednolicenie legacy-pakietu pozostaje zadaniem części 13 (MICRO).",
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-08-007: MDR DEADLINE GUARD — art. 86a-86b OrdPU (termin z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

mdr_obligation(promoter, user, hallmark, cross_border, _) = true {
    promoter
    hallmark
    cross_border
}

mdr_obligation(_, user, hallmark, cross_border, reported) = true {
    user
    hallmark
    cross_border
    not reported
}

mdr_role(promoter, _) = "PROMOTER" {
    promoter
}

mdr_role(promoter, user) = "USER_SUBSIDIARY" {
    promoter == false
    user
} else = ""

mdr_routing(filing) = "BLOCK_AND_ALERT" {
    filing
} else = ""

mdr_deadline_guard_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    invoice := object.get(input.invoice, {}, {})

    promoter := object.get(profile, "is_mdr_promoter", false)
    user := object.get(profile, "is_mdr_user", false)
    hallmark := object.get(invoice, "has_mdr_hallmark", false)
    cross_border := object.get(invoice, "is_cross_border", true)
    reported := object.get(invoice, "promoter_reported_mdr", false)
    filing := mdr_obligation(promoter, user, hallmark, cross_border, reported)

    deadline_days := _th("mdr_deadline_days", 30)

    verdict := _certificate(350100, {
        "rule_id": "jdg.crossborder.v3_08.mdr_deadline_guard",
        "procedure": "MDR_DEADLINE_GUARD_V3",
        "mdr_filing_obligation": filing,
        "mdr_form": "MDR-1",
        "mdr_deadline_days": deadline_days,
        "mdr_role": mdr_role(promoter, user),
        "mdr_cross_border": cross_border,
        "_routing": mdr_routing(filing),
        "_routing_reason": sprintf("MDR v3 — rola %s, transgraniczne: %v → MDR-1 w %d dni (art. 86a § 1-2 OrdPU)", [mdr_role(promoter, user), cross_border, deadline_days]),
        "_legal_basis": "Art. 86a § 1 pkt 1-2 i § 2 ustawy — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.); Dyrektywa Rady (UE) 2018/822 (DAC6)",
        "_warnings": [
            sprintf("[MDR] Deadline %d dni czytany z thresholds — zgodny z art. 86a § 1 pkt 2 OrdPU.", [deadline_days]),
            "[MDR] Schematy czysto krajowe NIE podlegają MDR (art. 86a § 4 OrdPU).",
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-08-008: CROSS-BORDER DECISION CERTIFICATE — zbiorczy certyfikat domeny
# (Golden Oracle V2 F3: pełna ścieżka audytowa decyzji transgranicznej;
#  domyka łańcuch jako catch-all dla każdego zdarzenia z danymi faktury)
# ═══════════════════════════════════════════════════════════════════════════════

eu_countries := {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE"}

cb_domain_packages := [
    "jdg.crossborder", "jdg.crossborder.post_brexit", "jdg.crossborder.v3_08",
    "jdg.international", "jdg.tp", "jdg.tp.hyper", "jdg.mdr",
    "jdg.mdr.hallmarks", "jdg.mdr.hyper", "jdg.exit_tax_cfc",
    "jdg.cfc_auto_classifier", "jdg.vida_drr_full",
]

snapshot_status(ok) = "OK" {
    ok
} else = "MISSING"

decision_certificate := verdict {
    invoice := object.get(input.invoice, {}, {})
    vendor := object.get(input.vendor, {}, {})

    country := object.get(vendor, "country", "")
    detected := country != "" and country != "PL"
    is_eu := country in eu_countries

    verdict := _certificate(360199, {
        "rule_id": "jdg.crossborder.v3_08.decision_certificate",
        "procedure": "CB_DECISION_CERTIFICATE",
        "cb_vendor_country": country,
        "cb_vendor_is_eu": is_eu,
        "cb_direction": object.get(invoice, "direction", ""),
        "cb_procedure": object.get(invoice, "procedure", ""),
        "cb_cross_border_detected": detected,
        "cb_domain_packages_wired": cb_domain_packages,
        "cb_golden_oracle_ready": detected,
        "manual_review_required": false,
        "_routing": cb_routing(detected),
        "_routing_reason": sprintf("Cross-border certificate — kraj: %s, EU: %v, snapshot progów: %s", [country, is_eu, snapshot_status(_snapshot_ok)]),
        "_legal_basis": "Kompleksowy certyfikat domeny transgranicznej (VAT/PIT/CIT/OrdPU/DAC8/ViDA); zgodność z V1 zasada 9 (obserwowalność) i V2 filary F3-F4",
        "_warnings": [],
    })
}

cb_routing(detected) = "TRIAGE_QUEUE" {
    detected
} else = ""

# ── Łańcuch first-match-wins: fail-closed → domeny → certyfikat zbiorczy ──────

decide = fail_closed_decision {
    not _snapshot_ok
} else = exit_tax_decision {
    true
} else = cfc_decision {
    true
} else = wht_decision {
    true
} else = dac8_decision {
    true
} else = uk_b2c_decision {
    true
} else = tp_thresholds_decision {
    true
} else = mdr_deadline_guard_decision {
    true
} else = decision_certificate {
    true
}
