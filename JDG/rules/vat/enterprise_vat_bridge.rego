# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise VAT Bridge (Rego ↔ Python) v7.0
# ═══════════════════════════════════════════════════════════════════════════════
#
# Mostek między Rego a Python Enterprise VAT Innovations (tools/enterprise_vat_innovations.py).
# Dane enterprise są wstrzykiwane do OPA jako data.jdg.enterprise przez PreOPAPipeline.
# Reguły w tym pliku czytają te dane i przekształcają je w decyzje OPA.
#
# Package: jdg.vat.enterprise
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat.enterprise

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.vat.enterprise.no_match",
    "package": "jdg.vat.enterprise",
    "priority": 900
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-1: MPP Auto-Detection Bridge — odczyt z Python NLP
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.vat.enterprise.mpp_auto_detection_bridge",
    "package": "jdg.vat.enterprise", "priority": 1,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "MPP_AUTO_DETECT",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpp_auto_detected": mpp_detected,
    "mpp_auto_category": mpp_category,
    "mpp_auto_confidence": mpp_confidence,
    "mpp_auto_requires_review": mpp_review,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 108a VAT (Załącznik 15 — MPP Auto-Detection)",
    "_warnings": [sprintf("MPP AUTO-DETECTION: %s (confidence: %.0f%%) — kategoria %s. %s", [mpp_status, mpp_confidence*100, mpp_category, review_note])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    mpp_data := object.get(ent, "mpp_auto_detect", {})
    mpp_detected := object.get(mpp_data, "mpp_auto_detected", false)
    mpp_category := object.get(mpp_data, "mpp_auto_primary", "NONE")
    mpp_confidence := object.get(mpp_data, "mpp_auto_confidence", 0.0)
    mpp_review := object.get(mpp_data, "mpp_requires_manual_review", false)

    mpp_status = "WYKRYTO OBOWIĄZEK MPP" { mpp_detected == true; mpp_confidence >= 0.60 }
    mpp_status = "POTENCJALNY MPP — wymagana weryfikacja" { mpp_detected == true; mpp_confidence < 0.60 }
    mpp_status = "Nie wykryto obowiązku MPP" { mpp_detected == false }

    review_note = "Wymagana weryfikacja manualna" { mpp_review == true }
    review_note = "" { mpp_review == false }

    routing = "TRIAGE_QUEUE" { mpp_review == true }
    routing = "" { mpp_review == false }
    routing_reason = "MPP auto-detection: low confidence — manual review" { mpp_review == true }
    routing_reason = "" { mpp_review == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-2: VAT Rate Classifier Bridge
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.enterprise.rate_classifier_bridge",
    "package": "jdg.vat.enterprise", "priority": 2,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "VAT_RATE_CLASSIFIER",
    "vat_exemption": "", "vat_rate_ai_suggested": ai_rate,
    "vat_rate_ai_confidence": ai_confidence,
    "vat_rate_ai_requires_triage": ai_triage,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 41 VAT (AI Rate Classifier)",
    "_warnings": [sprintf("AI VAT RATE: %.0f%% (confidence: %.0f%%). %s", [ai_rate*100, ai_confidence*100, ai_note])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    rate_data := object.get(ent, "vat_rate_classify", {})
    ai_rate := object.get(rate_data, "vat_rate_classified", 0.23)
    ai_confidence := object.get(rate_data, "vat_rate_confidence", 0.0)
    ai_triage := object.get(rate_data, "vat_rate_requires_triage", false)
    ai_note := object.get(rate_data, "vat_rate_method", "UNKNOWN")

    routing = "TRIAGE_QUEUE" { ai_triage == true }
    routing = "" { ai_triage == false }
    routing_reason = "AI rate confidence low — manual verification" { ai_triage == true }
    routing_reason = "" { ai_triage == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-3: VAT Limit Tracker Bridge
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.enterprise.limit_tracker_bridge",
    "package": "jdg.vat.enterprise", "priority": 3,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "VAT_LIMIT_TRACKER",
    "vat_exemption": "", "vat_limit_breach_forecast": breach_forecast,
    "vat_limit_days_remaining": days_remaining,
    "vat_limit_status": limit_status,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 113 VAT (Limit Tracker 200k)",
    "_warnings": [sprintf("VAT LIMIT TRACKER: YTD %.2f PLN (%.0f%% limitu 200k). Prognoza przekroczenia: %s. Pozostało %d dni.", [ytd, pct_used, breach_forecast, days_remaining])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    lt := object.get(ent, "vat_limit_tracker", {})
    ytd := object.get(lt, "vat_limit_ytd", 0)
    pct_used := object.get(lt, "vat_limit_used_pct", 0)
    days_remaining := object.get(lt, "vat_limit_days_to_breach", 365)
    breach_forecast := object.get(lt, "vat_limit_breach_forecast_date", "> 12 miesięcy")
    limit_status := object.get(lt, "vat_limit_status", "OK")
    early_warning := object.get(lt, "vat_limit_early_warning", false)

    routing = "TRIAGE_QUEUE" { early_warning == true }
    routing = "BLOCK_AND_ALERT" { limit_status == "BREACHED" }
    routing = "" { limit_status == "OK" }
    routing_reason = "Limit VAT 200k — early warning (80%+)" { early_warning == true }
    routing_reason = "Limit VAT 200k PRZEKROCZONY — obowiązek rejestracji VAT!" { limit_status == "BREACHED" }
    routing_reason = "" { limit_status == "OK" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-4: Cross-Border VAT Compliance Matrix Bridge
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.enterprise.cross_border_matrix_bridge",
    "package": "jdg.vat.enterprise", "priority": 4,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "CROSS_BORDER_MATRIX",
    "vat_exemption": "", "cross_border_place_of_supply": cb_pos,
    "cross_border_rate": cb_rate,
    "cross_border_mechanism": cb_mechanism,
    "cross_border_oss_applicable": cb_oss,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28a-28o VAT (Cross-Border Matrix)",
    "_warnings": [sprintf("CROSS-BORDER: %s → %s (B2B). Miejsce: %s, Mechanizm: %s, Stawka: %.0f%%. %s", [cb_vendor, cb_buyer, cb_pos, cb_mechanism, cb_rate*100, oss_note])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    cb := object.get(ent, "cross_border_vat_matrix", {})
    cb_vendor := object.get(cb, "cross_border_vendor", "PL")
    cb_buyer := object.get(cb, "cross_border_buyer", "PL")
    cb_pos := object.get(cb, "cross_border_place_of_supply", "PL")
    cb_rate := object.get(cb, "cross_border_applicable_rate", 0.23)
    cb_mechanism := object.get(cb, "cross_border_tax_mechanism", "DOMESTIC")
    cb_oss := object.get(cb, "cross_border_oss_applicable", false)

    oss_note = "OSS applicable — rozlicz przez One-Stop-Shop" { cb_oss == true }
    oss_note = "" { cb_oss == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-5: GTU Semantic Auto-Tagger Bridge
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.enterprise.gtu_semantic_tagger_bridge",
    "package": "jdg.vat.enterprise", "priority": 5,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "GTU_SEMANTIC_TAGGER",
    "vat_exemption": "", "gtu_semantic_code": gtu_code,
    "gtu_semantic_confidence": gtu_conf,
    "gtu_semantic_requires_review": gtu_review,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "§ 10 rozporządzenia JPK_VAT (GTU Semantic Tagger)",
    "_warnings": [sprintf("GTU SEMANTIC: %s (confidence: %.0f%%). %s", [gtu_code, gtu_conf*100, gtu_note])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    gt := object.get(ent, "gtu_semantic_tag", {})
    gtu_code := object.get(gt, "gtu_code", "")
    gtu_conf := object.get(gt, "gtu_confidence", 0.0)
    gtu_review := object.get(gt, "gtu_requires_manual_review", false)

    gtu_note = "Manual review recommended" { gtu_review == true }
    gtu_note = "OK" { gtu_review == false }

    routing = "TRIAGE_QUEUE" { gtu_review == true }
    routing = "" { gtu_review == false }
    routing_reason = "GTU semantic confidence low — manual review" { gtu_review == true }
    routing_reason = "" { gtu_review == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-6: KSeF Resilience Firewall Bridge
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.enterprise.ksef_resilience_bridge",
    "package": "jdg.vat.enterprise", "priority": 6,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "KSEF_RESILIENCE",
    "vat_exemption": "", "ksef_resilience_score": resilience_score,
    "ksef_recommended_action": action,
    "ksef_offline_hours": offline_hours,
    "ksef_invoices_pending": pending,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 106na-106ne VAT (KSeF Resilience)",
    "_warnings": [sprintf("KSeF RESILIENCE: status=%s, score=%.0f%%, offline=%dh, pending=%d. Action: %s", [ksef_status, resilience_score*100, offline_hours, pending, action])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    kr := object.get(ent, "ksef_resilience", {})
    ksef_status := object.get(kr, "ksef_status", "UNKNOWN")
    resilience_score := object.get(kr, "ksef_resilience_score", 0.0)
    action := object.get(kr, "ksef_recommended_action", "UNKNOWN")
    offline_hours := object.get(kr, "ksef_offline_hours", 0)
    pending := object.get(kr, "ksef_invoices_pending", 0)

    routing = "BLOCK_AND_ALERT" { resilience_score == 0.0 }
    routing = "TRIAGE_QUEUE" { resilience_score < 0.5; resilience_score > 0 }
    routing = "" { resilience_score >= 0.5 }
    routing_reason = "KSeF offline deadline exceeded — URGENT sync!" { resilience_score == 0.0 }
    routing_reason = "KSeF degraded — consider offline mode" { resilience_score < 0.5; resilience_score > 0 }
    routing_reason = "" { resilience_score >= 0.5 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-7: Split Payment Optimizer Bridge
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.enterprise.split_payment_optimizer_bridge",
    "package": "jdg.vat.enterprise", "priority": 7,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "SPLIT_PAYMENT_OPT",
    "vat_exemption": "", "mpp_safe_harbor_benefit": safe_harbor,
    "mpp_voluntary_recommended": voluntary_count,
    "mpp_mandatory_count": mandatory_count,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 108a VAT (Split Payment Optimizer)",
    "_warnings": [sprintf("MPP OPTIMIZER: %d obowiązkowych, %d rekomendowanych (safe harbor benefit: %.2f PLN).", [mandatory_count, voluntary_count, safe_harbor])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    sp := object.get(ent, "split_payment_optimize", {})
    safe_harbor := object.get(sp, "mpp_total_safe_harbor_benefit", 0.0)
    voluntary_count := object.get(sp, "mpp_voluntary_recommended_count", 0)
    mandatory_count := object.get(sp, "mpp_mandatory_count", 0)

    routing = "BLOCK_AND_ALERT" { mandatory_count > 0 }
    routing = "TRIAGE_QUEUE" { voluntary_count > 3 }
    routing = "" { mandatory_count == 0; voluntary_count <= 3 }
    routing_reason = sprintf("MPP mandatory breach: %d faktur", [mandatory_count]) { mandatory_count > 0 }
    routing_reason = sprintf("MPP optimization: %d faktur rekomendowanych do safe harbor", [voluntary_count]) { voluntary_count > 3; mandatory_count == 0 }
    routing_reason = "" { mandatory_count == 0; voluntary_count <= 3 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-8: VAT Cash-Flow Predictor Bridge
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.enterprise.cashflow_predictor_bridge",
    "package": "jdg.vat.enterprise", "priority": 8,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "VAT_CASHFLOW_PREDICT",
    "vat_exemption": "", "vat_cashflow_liquidity_warning": liquidity_warning,
    "vat_cashflow_forecast_1m": forecast_1m,
    "vat_cashflow_confidence": cf_confidence,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 103 VAT (VAT Cash-Flow Predictor)",
    "_warnings": [sprintf("VAT CASH-FLOW: bieżący %.2f PLN, prognoza +1m: %.2f PLN. %s", [cf_current, forecast_1m, cf_warning])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    cf := object.get(ent, "vat_cashflow_predict", {})
    cf_current := object.get(cf, "vat_cashflow_current_month", 0)
    liquidity_warning := object.get(cf, "vat_cashflow_liquidity_warning", false)
    cf_confidence := object.get(cf, "vat_cashflow_confidence", 0.0)

    forecast := object.get(cf, "vat_cashflow_forecast", [])
    forecast_1m := object.get(object.get(forecast, 0, {}), "vat_predicted", cf_current)

    cf_warning = "WARNING: płynność zagrożona!" { liquidity_warning == true }
    cf_warning = "OK" { liquidity_warning == false }

    routing = "TRIAGE_QUEUE" { liquidity_warning == true }
    routing = "" { liquidity_warning == false }
    routing_reason = "VAT liquidity warning — current month above average" { liquidity_warning == true }
    routing_reason = "" { liquidity_warning == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-9: Proportional Deduction Optimizer Bridge
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.enterprise.proportion_optimizer_bridge",
    "package": "jdg.vat.enterprise", "priority": 9,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "PROPORTION_OPTIMIZER",
    "vat_exemption": "", "proportion_current": proportion,
    "proportion_de_minimis": de_minimis,
    "proportion_correction_needed": correction_needed,
    "proportion_recommendation_count": rec_count,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 90-91 VAT (Proportional Deduction Optimizer)",
    "_warnings": [sprintf("PROPORCJA VAT: %.2f%% — %s. %s", [proportion*100, prop_status, prop_action])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    po := object.get(ent, "proportion_optimize", {})
    proportion := object.get(po, "proportion_current", 1.0)
    de_minimis := object.get(po, "proportion_de_minimis", false)
    correction_needed := object.get(po, "proportion_annual_correction_needed", false)
    rec_count := count(object.get(po, "proportion_recommendations", []))

    prop_status = "de minimis < 2% — brak odliczenia" { de_minimis == true }
    prop_status = "wymagana korekta roczna" { correction_needed == true; de_minimis == false }
    prop_status = "OK" { correction_needed == false; de_minimis == false }

    prop_action = "Brak prawa do odliczenia VAT" { de_minimis == true }
    prop_action = sprintf("Zalecenia: %d", [rec_count]) { rec_count > 0 }
    prop_action = "" { rec_count == 0 }

    routing = "TRIAGE_QUEUE" { correction_needed == true }
    routing = "" { correction_needed == false }
    routing_reason = sprintf("Proporcja %.2f%% — wymagana korekta roczna Art. 91 VAT", [proportion*100]) { correction_needed == true }
    routing_reason = "" { correction_needed == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-10: Merkle Audit Trail Verifier
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.enterprise.merkle_audit_trail",
    "package": "jdg.vat.enterprise", "priority": 10,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "MERKLE_AUDIT",
    "vat_exemption": "", "merkle_root_exists": merkle_exists,
    "merkle_leaf_count": leaf_count,
    "merkle_timestamp": merkle_ts,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 86-89b VAT (Merkle Audit Trail Immutability)",
    "_warnings": [sprintf("MERKLE AUDIT: %d faktur w drzewie. Korzeń: %s. Znacznik: %s. Dowód integralności okresu rozliczeniowego.", [leaf_count, merkle_root_short, merkle_ts])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    mt := object.get(ent, "merkle_tree", {})
    merkle_root := object.get(mt, "merkle_root", "")
    merkle_exists := merkle_root != ""
    leaf_count := object.get(mt, "merkle_leaf_count", 0)
    merkle_ts := object.get(mt, "merkle_timestamp", "")
    merkle_root_short := substring(merkle_root, 0, 8) { merkle_exists == true }
    merkle_root_short = "N/A" { merkle_exists == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENT-11: Tax Authority Interaction Engine Bridge
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.enterprise.tax_authority_interaction",
    "package": "jdg.vat.enterprise", "priority": 11,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "TAX_AUTHORITY_INTERACTION",
    "vat_exemption": "", "tax_authority_strategy": strategy,
    "tax_authority_success_rate": success_rate,
    "tax_authority_recommendation": recommendation,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 16 KKS, Art. 81 OrdPU (Tax Authority AI Engine)",
    "_warnings": [sprintf("TAX AUTHORITY AI: %s — success rate: %.0f%%. %s", [strategy, success_rate*100, recommendation])]
} {
    ent := object.get(data.jdg, "enterprise", {})
    tai := object.get(ent, "tax_authority_interaction", {})
    strategy := object.get(tai, "interaction_type", "UNKNOWN")
    success_rate := object.get(tai, "ai_success_rate", 0.50)
    recommendation := object.get(tai, "ai_recommendation", "")
    has_proceedings := object.get(tai, "has_active_proceedings", false)

    routing = "BLOCK_AND_ALERT" { has_proceedings == true; success_rate < 0.10 }
    routing = "TRIAGE_QUEUE" { success_rate < 0.50 }
    routing = "" { success_rate >= 0.50 }
    routing_reason = "Active proceedings — voluntary disclosure ineffective" { has_proceedings == true; success_rate < 0.10 }
    routing_reason = "Low success rate — consult tax advisor" { success_rate < 0.50; has_proceedings == false }
    routing_reason = "" { success_rate >= 0.50 }
}
