# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for R07 GLM52 KKS
# Package: jdg.r07_kks_innovations
# Source: 07_KKS_Kodeks_Karny_Skarbowy.txt (prompty_glm52)
# Generated: 2026-08-14
# ═══════════════════════════════════════════════════════════════════════════════

package test_r07_kks

import future.keywords.in

# ═══ DEFAULT: bez flagi r07_kks_check → no_match ═══

test_default_no_match {
    result := data.jdg.r07_kks_innovations.decide with input as {
        "jdg_entrepreneur": {"r07_kks_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.r07_kks_innovations.no_match"
}

# ═══ R07-INN-01: CZYNNY ŻAL ONE-CLICK ═══

test_disclosure_ready {
    d := data.jdg.r07_kks_innovations.voluntary_disclosure_one_click with input as {
        "jdg_entrepreneur": {"r07_disclosure_check": true},
        "disclosure_pack": {
            "offense_type": "TAX_EVASION",
            "revenue_impact": 15000,
            "documents": ["zawiadomienie_art16", "kalkulacja_uszczuplenia", "dowod_wplaty"],
            "organ_notified": false,
        },
    }
    d.disclosure.ready == true
    d.disclosure.checklist_art16.zawiadomienie_o_przestepstwie == true
    d.disclosure.checklist_art16.wplata_uszczuplenia == true
    count(d.disclosure.missing_documents) == 0
    d.disclosure.deadline_days == 7
}

test_disclosure_missing_docs {
    d := data.jdg.r07_kks_innovations.voluntary_disclosure_one_click with input as {
        "jdg_entrepreneur": {"r07_disclosure_check": true},
        "disclosure_pack": {
            "offense_type": "TAX_EVASION",
            "revenue_impact": 15000,
            "documents": ["zawiadomienie_art16"],
            "organ_notified": false,
        },
    }
    d.disclosure.ready == false
    "kalkulacja_uszczuplenia" in d.disclosure.missing_documents
    "dowod_wplaty" in d.disclosure.missing_documents
}

test_disclosure_organ_notified_not_ready {
    d := data.jdg.r07_kks_innovations.voluntary_disclosure_one_click with input as {
        "jdg_entrepreneur": {"r07_disclosure_check": true},
        "disclosure_pack": {
            "offense_type": "TAX_EVASION",
            "revenue_impact": 15000,
            "documents": ["zawiadomienie_art16", "kalkulacja_uszczuplenia", "dowod_wplaty"],
            "organ_notified": true,
        },
    }
    d.disclosure.ready == false
}

# ═══ R07-INN-02: KALKULATOR KAR Z TEMPORALNOŚCIĄ ═══

test_penalty_calc_standard {
    p := data.jdg.r07_kks_innovations.penalty_calculator_temporal with input as {
        "jdg_entrepreneur": {"r07_penalty_calc_check": true},
        "penalty_calc": {"daily_stakes": 200, "minor_case": false},
    }
    p.penalty.stakes_count == 60
    p.penalty.fine_calculated == 12000
    p.penalty.fine_limit_absolute == 500000
    p.penalty.statute_barred == false
}

test_penalty_calc_minor {
    p := data.jdg.r07_kks_innovations.penalty_calculator_temporal with input as {
        "jdg_entrepreneur": {"r07_penalty_calc_check": true},
        "penalty_calc": {"daily_stakes": 100, "minor_case": true},
    }
    p.penalty.stakes_count == 10
    p.penalty.fine_calculated == 1000
}

test_penalty_calc_capped_at_limit {
    p := data.jdg.r07_kks_innovations.penalty_calculator_temporal with input as {
        "jdg_entrepreneur": {"r07_penalty_calc_check": true},
        "penalty_calc": {"daily_stakes": 500, "minor_case": false},
    }
    p.penalty.fine_calculated == 30000
}

# ═══ R07-INN-03: PREDYKCJA RYZYKA KARNEGO PER TRANSAKCJA ═══

test_txn_risk_low_pass {
    r := data.jdg.r07_kks_innovations.transaction_risk_predictor with input as {
        "jdg_entrepreneur": {"r07_txn_risk_check": true},
        "txn_risk": {"docs_complete": true},
    }
    r.risk.score_0_100 == 10
    r.risk.risk_level == "LOW"
    r.risk.routing == "PASS"
}

test_txn_risk_high_block {
    r := data.jdg.r07_kks_innovations.transaction_risk_predictor with input as {
        "jdg_entrepreneur": {"r07_txn_risk_check": true},
        "txn_risk": {
            "invoice_missing": true,
            "unreal_entity": true,
            "cash_limit_exceeded": false,
            "false_declaration_risk": false,
            "docs_complete": false,
        },
    }
    r.risk.score_0_100 == 95
    r.risk.risk_level == "CRITICAL"
    r.risk.routing == "BLOCK_AND_ALERT"
}

test_txn_risk_medium_warn {
    r := data.jdg.r07_kks_innovations.transaction_risk_predictor with input as {
        "jdg_entrepreneur": {"r07_txn_risk_check": true},
        "txn_risk": {
            "invoice_missing": false,
            "unreal_entity": false,
            "cash_limit_exceeded": true,
            "false_declaration_risk": true,
            "docs_complete": true,
        },
    }
    r.risk.score_0_100 == 50
    r.risk.risk_level == "MEDIUM"
    r.risk.routing == "WARN"
}

# ═══ RAPORT KKS: aktywna flaga ═══

test_kks_report {
    result := data.jdg.r07_kks_innovations.decide with input as {
        "jdg_entrepreneur": {"r07_kks_check": true},
        "disclosure_pack": {
            "offense_type": "TAX_EVASION",
            "revenue_impact": 15000,
            "documents": ["zawiadomienie_art16", "kalkulacja_uszczuplenia", "dowod_wplaty"],
            "organ_notified": false,
        },
        "penalty_calc": {"daily_stakes": 200, "minor_case": false},
        "txn_risk": {"docs_complete": true},
    }
    result.matched == true
    result.rule_id == "jdg.r07_kks_innovations.kks_report"
    result._routing == "REPORT"
    result.kks.voluntary_disclosure.ready == true
    result.kks.penalty_calculator.fine_calculated == 12000
    result.kks.transaction_risk.routing == "PASS"
}
