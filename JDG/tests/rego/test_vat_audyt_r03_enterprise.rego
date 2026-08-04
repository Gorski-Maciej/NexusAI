# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R03 VAT AUDYT — testy rego
# (raport raporty_audyt_glm52/R03_VAT.txt)
# Uruchom: opa test JDG/rules JDG/tests/rego/test_vat_audyt_r03_enterprise.rego
# ═══════════════════════════════════════════════════════════════════════════════
# Pokrycie R03:
#  - P1: art. 113 — limit 200 000 zł z data.thresholds (temporalnie) + przekroczenie
#        w trakcie roku/kwartału (ust. 5 i 9, SLIM VAT 2 opcja kwartalna) — T1
#  - P1: art. 43 + Rozp. MF 4.12.2024 — mapowanie 1:1 CN→stawka i PKWiU→8% — T2
#  - P1: art. 86-96 — proporcja 2%/98% graniczna (pre-ratio, de minimis) — T1
#  - P2: art. 96b (Biała Lista) × próg 15 000 zł — jedna reguła (z art. 108a MPP)
#  - P2: WDT/WNT — limit 90 dni (art. 42 ust. 12-13 VAT) — T3
#  - T3: temporalność 150→90 dni złych długów (SLIM VAT 3)
#  - T4: faktura bez NIP — odwrotne obciążenie (brak mdlenia silnika)
#  - T8: podstawa z rabatem 0,01 zł (art. 29a)
#  - T9: marża + WNT jednocześnie
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.tests.vat_audyt_r03

import data.jdg.vat.plan26_critical
import data.jdg.vat.substantive
import data.jdg.vat.reduced_rates
import data.jdg.micro.vat.proportion
import data.jdg.micro.vat.wdt_export
import data.jdg.vat_mpp_split_payment
import data.jdg.thresholds

# ── P1/T1: ART. 113 — LIMIT ZWOLNIENIA PODMIOTOWEGO (199 999,99 / 200 000 / 200 000,01) ──

test_r03_t1_art113_limit_199999_99 if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_payer": false,
            "annual_turnover_net": 199999.99
        }
    }
    # Pełny limit roczny (brak ceidg_entry_date) = 200 000 z data.thresholds
    result.rule_id == "jdg.vat.plan26_critical.subject_exemption_proportional"
    result.exemption_proportional_limit == 200000
    result.exemption_exceeded == false
    result._routing == ""
}

test_r03_t1_art113_limit_200000_exact if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_payer": false,
            "annual_turnover_net": 200000.00
        }
    }
    # Równy limit NIE przekracza (warunek: > limit)
    result.exemption_exceeded == false
    result._routing == ""
}

test_r03_t1_art113_limit_200000_01 if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_payer": false,
            "annual_turnover_net": 200000.01
        }
    }
    result.exemption_exceeded == true
    result._routing == "BLOCK_AND_ALERT"
}

# ── P1/T1: ART. 113 UST. 9 — KALKULACJA KWARTALNA (SLIM VAT 2) — CRIT-18 ──────

test_r03_t1_art113_quarterly_2_quarters_ok if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_payer": false,
            "vat_subject_exemption_check": true,
            "annual_turnover_net": 99999.99,
            "remaining_quarters": 2
        }
    }
    result.rule_id == "jdg.vat.plan26_critical.subject_exemption_quarterly_excess"
    result.exemption_limit_annual == 200000
    result.exemption_limit_proportional == 100000
    result.exemption_quarterly_mode == true
    result.exemption_exceeded_mid_quarter == false
    result.vat_registration_required == false
    result._routing == ""
}

test_r03_t1_art113_quarterly_2_quarters_exceeded if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_payer": false,
            "vat_subject_exemption_check": true,
            "annual_turnover_net": 100000.01,
            "remaining_quarters": 2
        }
    }
    # Limit kwartalny: 200 000 × 2/4 = 100 000 → przekroczenie = utrata zwolnienia
    result.exemption_exceeded_mid_quarter == true
    result.vat_registration_required == true
    result._routing == "BLOCK_AND_ALERT"
}

test_r03_t1_art113_quarterly_4_quarters_boundary if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_payer": false,
            "vat_subject_exemption_check": true,
            "annual_turnover_net": 199999.99,
            "remaining_quarters": 4
        }
    }
    # 4 kwartały → limit = pełne 200 000
    result.exemption_limit_proportional == 200000
    result.exemption_exceeded_mid_quarter == false
}

# ── P1/T1: ART. 113 W SUBSTANTIVE (P51) — LIMIT Z DATA.THRESHOLDS ─────────────

test_r03_t1_art113_substantive_exempt_below_limit if {
    result := substantive.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_payer": false,
            "annual_turnover_net": 199999.99
        }
    }
    result.rule_id == "jdg.vat.substantive.subject_exemption_jdg"
    result.vat_exemption == "SUBJECT"
}

test_r03_t1_art113_substantive_not_exempt_over_limit if {
    result := substantive.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_payer": false,
            "annual_turnover_net": 200000.01
        }
    }
    # Powyżej limitu zwolnienie podmiotowe NIE przysługuje
    result.rule_id != "jdg.vat.substantive.subject_exemption_jdg"
    result.rule_id != "jdg.vat.substantive.startup_proportion"
}

test_r03_t1_thresholds_source_of_truth if {
    # Limit musi pochodzić z data.thresholds (weryfikowalnie zewnętrznie)
    thresholds.vat.subject_exemption_limit == 200000
}

# ── P1/T1: ART. 90 — PROPORCJA 2%/98% GRANICZNA (pre-ratio, de minimis) ───────

test_r03_t1_proportion_98_01_full_deduction if {
    result := proportion.decide with input as {
        "jdg_entrepreneur": {"vat_proportion_pct": 98.01}
    }
    # > 98% → pełne odliczenie (PROP-04)
    result.rule_id == "jdg.micro.vat.proportion.prop_04"
    result._routing == ""
}

test_r03_t1_proportion_98_exact_not_full if {
    result := proportion.decide with input as {
        "jdg_entrepreneur": {"vat_proportion_pct": 98.00}
    }
    # Dokładnie 98% NIE jest > 98% → prop_04 nie odpala (proporcja normalna)
    result.rule_id != "jdg.micro.vat.proportion.prop_04"
}

test_r03_t1_proportion_1_99_no_deduction if {
    result := proportion.decide with input as {
        "jdg_entrepreneur": {"vat_proportion_pct": 1.99}
    }
    # < 2% → brak odliczenia (PROP-03, de minimis)
    result.rule_id == "jdg.micro.vat.proportion.prop_03"
    result._routing == "BLOCK_AND_ALERT"
}

test_r03_t1_proportion_2_exact_not_de_minimis if {
    result := proportion.decide with input as {
        "jdg_entrepreneur": {"vat_proportion_pct": 2.00}
    }
    # Dokładnie 2% NIE jest < 2% → prop_03 nie odpala
    result.rule_id != "jdg.micro.vat.proportion.prop_03"
}

test_r03_t1_proportion_thresholds_from_data if {
    # Progi 2%/98% w data.thresholds (externalizacja — brak hardcode w regule)
    thresholds.vat.proportion_min_threshold == 0.02
    thresholds.vat.proportion_max_threshold == 0.98
}

# ── P1/T2: STAWKA 23% NA TOWAR Z LISTY OBNIŻONEJ (CN) — RATE-9 ───────────────

test_r03_t2_cn_8pct_list_23pct_applied if {
    result := reduced_rates.decide with input as {
        "invoice": {"cn_code": "3004", "vat_rate": 0.23}
    }
    # CN 3004 (leki) → 8%; faktura 23% → błąd klasyfikacji → BLOCK
    result.rule_id == "jdg.vat.reduced_rates.cn_23pct_mismatch"
    result.cn_vat_match == "MISMATCH_23PCT"
    result.cn_vat_expected_rate == 0.08
    result._routing == "BLOCK_AND_ALERT"
}

test_r03_t2_cn_5pct_list_23pct_applied if {
    result := reduced_rates.decide with input as {
        "invoice": {"cn_code": "0401", "vat_rate": 0.23}
    }
    # CN 0401 (mleko) → 5%; faktura 23% → błąd klasyfikacji → BLOCK
    result.rule_id == "jdg.vat.reduced_rates.cn_23pct_mismatch"
    result.cn_vat_expected_rate == 0.05
}

test_r03_t2_cn_8pct_ok if {
    result := reduced_rates.decide with input as {
        "invoice": {"cn_code": "3004", "vat_rate": 0.08}
    }
    result.rule_id == "jdg.vat.reduced_rates.cn_8pct_validation"
    result.cn_vat_match == "OK"
}

# ── P1/T2: PKWIU → STAWKA 8% (ZAŁĄCZNIK 3) — RATE-8 ──────────────────────────

test_r03_t2_pkwiu_8pct_ok if {
    result := reduced_rates.decide with input as {
        "invoice": {"pkwiu_code": "95.11.10.0", "vat_rate": 0.08}
    }
    result.rule_id == "jdg.vat.reduced_rates.pkwiu_8pct_validation"
    result.pkwiu_vat_match == "OK"
}

test_r03_t2_pkwiu_8pct_23pct_applied if {
    result := reduced_rates.decide with input as {
        "invoice": {"pkwiu_code": "96.02.10.0", "vat_rate": 0.23}
    }
    # PKWiU 96.02 (fryzjerstwo) → 8%; faktura 23% → błąd → BLOCK
    result.rule_id == "jdg.vat.reduced_rates.pkwiu_rate_mismatch"
    result.pkwiu_vat_match == "MISMATCH"
    result.pkwiu_vat_expected_rate == 0.08
    result._routing == "BLOCK_AND_ALERT"
}

# ── P1: ART. 43 — ZWOLNIENIA PRZEDMIOTOWE (edukacja — P55) ───────────────────

test_r03_p1_art43_education_exempt if {
    result := substantive.decide with input as {
        "invoice": {"direction": "SALE", "category_code": "EDUCATION"},
        "vendor": {"country": "PL"},
        "jdg_entrepreneur": {"is_vat_payer": true}
    }
    result.rule_id == "jdg.vat.substantive.education_exempt"
    result.vat_exemption == "OBJECT"
    result.vat_rate == "0.00"
}

# ── P2/T3: WDT — LIMIT 90 DNI (art. 42 ust. 12-13 VAT) ────────────────────────

test_r03_t3_wdt_90_days_ok if {
    result := wdt_export.decide with input as {
        "invoice": {
            "procedure": "WDT",
            "wdt_docs_complete": true,
            "wdt_docs_missing_days": 90
        }
    }
    # Dokładnie 90 dni NIE > 90 → wdt_03 (stawka krajowa) nie odpala
    result.rule_id != "jdg.micro.vat.wdt_export.wdt_03"
}

test_r03_t3_wdt_91_days_23pct if {
    result := wdt_export.decide with input as {
        "invoice": {
            "procedure": "WDT",
            "wdt_docs_complete": true,
            "wdt_docs_missing_days": 91
        }
    }
    # > 90 dni bez dokumentów → stawka krajowa 23% + BLOCK
    result.rule_id == "jdg.micro.vat.wdt_export.wdt_03"
    result.vat_rate == "23%"
    result._routing == "BLOCK_AND_ALERT"
}

# ── T3: TEMPORALNOŚĆ ZŁYCH DŁUGÓW 150→90 DNI (SLIM VAT 3) ────────────────────

test_r03_t3_bad_debt_pre_slim3_150d if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "is_paid": false,
            "direction": "SALE",
            "transaction_date": "2022-06-01",
            "days_overdue": 140,
            "due_date": "2022-07-01",
            "invoice_number": "FV/R03/001"
        }
    }
    # Przed 2023-01-01: próg 150 dni → 140 dni = ostrzeżenie (nie CRITICAL)
    result.rule_id == "jdg.vat.plan26_critical.bad_debt_auto_tracker"
    result.alert_level == "WARNING"
}

test_r03_t3_bad_debt_post_slim3_90d if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "is_paid": false,
            "direction": "SALE",
            "transaction_date": "2024-01-01",
            "days_overdue": 95,
            "due_date": "2024-02-01",
            "invoice_number": "FV/R03/002"
        }
    }
    # Od 2023-01-01: próg 90 dni → 95 dni = CRITICAL
    result.alert_level == "CRITICAL"
    result._routing == "TRIAGE_QUEUE"
}

# ── T4: FAKTURA BEZ NIP — ODWROTNE OBCIĄŻENIE (brak mdlenia silnika) ─────────

test_r03_t4_invoice_without_nip_wnt if {
    result := wdt_export.decide with input as {
        "invoice": {"procedure": "WNT"}
    }
    # Brak pola NIP/nabywcy w input — silnik zwraca werdykt WNT-01 (bez wyjątku)
    result.rule_id == "jdg.micro.vat.wdt_export.wnt_01"
}

test_r03_t4_wnt_reverse_charge_without_nip if {
    result := substantive.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "category_code": "GOODS"
        },
        "vendor": {"country": "DE"},
        "jdg_entrepreneur": {"is_vat_eu_registered": true}
    }
    # Brak NIP w input — reguła WNT odwrotne obciążenie działa (V.02)
    result.rule_id == "jdg.vat.substantive.wnt_reverse_charge_buyer"
    result.procedure == "WNT_REVERSE_CHARGE"
}

# ── T8: PODSTAWA Z RABATEM 0,01 ZŁ (art. 29a) ─────────────────────────────────

test_r03_t8_tax_base_rebate_0_01 if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "direction": "SALE",
            "amount_net": 1000.00,
            "has_rebate_discount": true,
            "rebate_amount": 0.01
        }
    }
    result.rule_id == "jdg.vat.plan26_critical.tax_base_art29a"
    result.tax_base_rebate_deducted == true
    result.tax_base_adjusted == 999.99
}

# ── T9: MARŻA + WNT JEDNOCZEŚNIE ─────────────────────────────────────────────

test_r03_t9_wnt_priority_over_margin if {
    result := substantive.decide with input as {
        "invoice": {
            "direction": "PURCHASE",
            "procedure": "WNT",
            "category_code": "GOODS"
        },
        "vendor": {"country": "DE"},
        "jdg_entrepreneur": {"is_vat_eu_registered": true}
    }
    # WNT ma priorytet w łańcuchu (V.02 przed P50 marża) → WNT_RO
    result.rule_id == "jdg.vat.substantive.wnt_reverse_charge_buyer"
}

test_r03_t9_margin_scheme if {
    result := substantive.decide with input as {
        "invoice": {"procedure": "MARGIN"}
    }
    result.rule_id == "jdg.vat.substantive.margin_scheme"
    result.vat_rate == "0.23"
}

# ── P2: BIAŁA LISTA × PRÓG 15 000 ZŁ (art. 96b ust. 1a) — JEDNA REGUŁA ───────

test_r03_p2_whitelist_15k_violation if {
    result := vat_mpp_split_payment.whitelist_15k_binding with input as {
        "invoice": {
            "direction": "PURCHASE",
            "amount_gross": 20000.00,
            "whitelist_15k_check": true,
            "payment_to_whitelisted_account": false,
            "split_payment_used": false
        },
        "vendor": {"on_whitelist": true},
        "jdg_entrepreneur": {"is_vat_payer": true}
    }
    result.binding.whitelist_violation == true
    result.binding.sanction_20pct == 4000
    result.binding.kup_denied == true
    result._routing == "BLOCK_AND_ALERT"
}

test_r03_p2_whitelist_15k_ok if {
    result := vat_mpp_split_payment.whitelist_15k_binding with input as {
        "invoice": {
            "direction": "PURCHASE",
            "amount_gross": 16000.00,
            "whitelist_15k_check": true,
            "payment_to_whitelisted_account": true
        },
        "vendor": {"on_whitelist": true}
    }
    result.binding.whitelist_violation == false
    result._routing == ""
}

test_r03_p2_whitelist_below_15k_not_required if {
    # < 15 000 zł — reguła nie dotyczy (art. 96b ust. 1a: „przekracza 15 000 zł")
    not vat_mpp_split_payment.whitelist_15k_binding with input as {
        "invoice": {
            "direction": "PURCHASE",
            "amount_gross": 14999.99,
            "whitelist_15k_check": true
        }
    }
}

# ── T10: ROUTING — próg MPP 15 000 z data.thresholds ─────────────────────────

test_r03_t10_mpp_threshold_from_data if {
    thresholds.misc.mpp_mandatory_threshold == 15000
}
