# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P14 COMPLIANCE + RODO + AML + BDO INNOVATIONS v9.0 (FULL)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.p14_innovations
# Report:      RAPORT_P14_JDG_COMPLIANCE_RODO_AML_BDO_v7.0
# Status:      ALL 12 INNOVATIONS — REAL COMPUTATIONAL LOGIC
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p14_innovations

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.p14_innovations.no_match",
    "package": "jdg.p14_innovations",
    "priority": 999999
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN01: GDPR AUTO-COMPLIANCE ENGINE
# Automatyczna zgodność RODO — 7 obowiązków + kalkulacja ryzyka kar
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.jdg_entrepreneur, "processes_personal_data", false) == true

    # 7 obligations check
    has_processing_register := object.get(input.jdg_entrepreneur, "rodo_register_maintained", false)
    has_marketing_consents := object.get(input.jdg_entrepreneur, "has_marketing_consents", false)
    has_erasure_procedure := object.get(input.jdg_entrepreneur, "rodo_erasure_procedure", false)
    has_breach_procedure := object.get(input.jdg_entrepreneur, "rodo_breach_procedure", false)
    has_dpo := object.get(input.jdg_entrepreneur, "rodo_dpo_appointed", false)
    has_processor_agreements := object.get(input.jdg_entrepreneur, "rodo_processor_agreements", false)
    has_privacy_by_design := object.get(input.jdg_entrepreneur, "rodo_privacy_by_design", false)
    has_dpia := object.get(input.jdg_entrepreneur, "rodo_dpia_completed", false)

    obligations := {
        "Art30_Register": has_processing_register,
        "Art7_Consents": has_marketing_consents,
        "Art17_Erasure": has_erasure_procedure,
        "Art33_Breach": has_breach_procedure,
        "Art37_DPO": has_dpo,
        "Art28_Processor": has_processor_agreements,
        "Art25_PrivacyDesign": has_privacy_by_design,
        "Art35_DPIA": has_dpia
    }

    obligations_met := count({k | obligations[k] == true})
    obligations_total := count(obligations)
    compliance_pct := floor((obligations_met / obligations_total) * 10000) / 100

    # Risk of GDPR fines
    missing_obligations := [k | obligations[k] == false]
    missing_count := count(missing_obligations)

    fine_tier := "TIER_1_10M_EUR_2PCT" { missing_count <= 2 and compliance_pct >= 75 }
    fine_tier := "TIER_2_20M_EUR_4PCT" { missing_count >= 3 or compliance_pct < 75 }
    fine_tier := "NONE" { missing_count == 0 }

    max_fine_pln := 20000000 * 4.5 { fine_tier == "TIER_1_10M_EUR_2PCT" }
    max_fine_pln := 40000000 * 4.5 { fine_tier == "TIER_2_20M_EUR_4PCT" }
    max_fine_pln := 0 { fine_tier == "NONE" }

    routing := "BLOCK_AND_ALERT" { fine_tier == "TIER_2_20M_EUR_4PCT" }
    routing := "TRIAGE_QUEUE" { fine_tier == "TIER_1_10M_EUR_2PCT" }
    routing := "" { fine_tier == "NONE" }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.gdpr_auto_compliance",
        "_legal_basis": "RODO (GDPR) — Rozporządzenie 2016/679; Art. 83 (kary)",
        "package": "jdg.p14_innovations",
        "priority": 14001,
        "p14_inn01_obligations_met": obligations_met,
        "p14_inn01_obligations_total": obligations_total,
        "p14_inn01_compliance_pct": compliance_pct,
        "p14_inn01_missing_obligations": missing_obligations,
        "p14_inn01_fine_tier": fine_tier,
        "p14_inn01_max_fine_pln": max_fine_pln,
        "p14_inn01_next_action": "All GDPR obligations met — maintain compliance" { missing_count == 0 },
        "p14_inn01_next_action": sprintf("Fix %d missing obligations: %s", [missing_count, concat(", ", missing_obligations)]) { missing_count > 0 },
        "_routing": routing,
        "_routing_reason": sprintf("GDPR Compliance: %.0f%% (%d/%d). Missing: %d. Fine risk: %s — up to %.0fM PLN", [compliance_pct, obligations_met, obligations_total, missing_count, fine_tier, max_fine_pln / 1000000]),
        "_legal_basis": "RODO (GDPR) — Rozporządzenie 2016/679; Art. 83 (kary)",
        "_description": "INN01: GDPR Auto-Compliance Engine — 8 obligations check + fine tier calculator"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN02: AML RISK SCORING MATRIX
# Punktowy scoring ryzyka AML per kontrahent z auto-detekcją
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.invoice, "aml_check_required", false) == true

    payment_method := object.get(input.invoice, "payment_method", "TRANSFER")
    is_cash := payment_method == "CASH"
    amount_eur := object.get(input.invoice, "amount_eur", 0)
    vendor_country := object.get(input.vendor, "country", "PL")
    is_pep := object.get(input.vendor, "is_pep", false)
    is_new_client := object.get(input.vendor, "is_new_counterparty", false)
    high_risk_countries := {"AF","BY","CU","IR","KP","LY","MM","RU","SD","SY","VE","YE","ZW"}

    risk_score := 0
    risk_score := risk_score + 3 { is_cash }
    risk_score := risk_score + 2 { vendor_country != "PL" }
    risk_score := risk_score + 5 { is_pep }
    risk_score := risk_score + 4 { vendor_country in high_risk_countries }
    risk_score := risk_score + 2 { amount_eur >= 50000 }
    risk_score := risk_score + 3 { amount_eur >= 15000 }
    risk_score := risk_score + 2 { is_new_client and amount_eur >= 10000 }

    cd_type := "SDD" { risk_score <= 2 }
    cd_type := "CDD" { risk_score >= 3; risk_score <= 6 }
    cd_type := "EDD" { risk_score >= 7; risk_score <= 9 }
    cd_type := "EDD_PLUS" { risk_score >= 10 }

    risk_level := "LOW" { risk_score <= 2 }
    risk_level := "MEDIUM" { risk_score >= 3; risk_score <= 6 }
    risk_level := "HIGH" { risk_score >= 7; risk_score <= 9 }
    risk_level := "CRITICAL" { risk_score >= 10 }

    cash_threshold_eur := 10000
    str_required := risk_score >= 7 or (amount_eur >= 15000 and vendor_country in high_risk_countries)
    str_deadline_hours := 48
    gif_report_to := "Generalny Inspektor Informacji Finansowej (GIIF)"

    routing := "BLOCK_AND_ALERT" { risk_level == "CRITICAL" }
    routing := "BLOCK_AND_ALERT" { str_required }
    routing := "TRIAGE_QUEUE" { risk_level == "HIGH" }
    routing := "WARNING" { risk_level == "MEDIUM" }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.aml_risk_matrix",
        "_legal_basis": "RODO (GDPR) — Rozporządzenie 2016/679; Art. 83 (kary)",
        "package": "jdg.p14_innovations",
        "priority": 14002,
        "p14_inn02_risk_score": risk_score,
        "p14_inn02_risk_level": risk_level,
        "p14_inn02_cd_type": cd_type,
        "p14_inn02_is_pep": is_pep,
        "p14_inn02_is_cash": is_cash,
        "p14_inn02_amount_eur": amount_eur,
        "p14_inn02_cash_threshold_eur": cash_threshold_eur,
        "p14_inn02_str_required": str_required,
        "p14_inn02_str_deadline_hours": str_deadline_hours,
        "p14_inn02_risk_factors": {"cash": is_cash, "cross_border": vendor_country != "PL", "pep": is_pep, "high_risk_country": vendor_country in high_risk_countries, "high_amount": amount_eur >= 15000, "new_client": is_new_client},
        "_routing": routing,
        "_routing_reason": sprintf("AML Risk: %d pts — %s → %s. %s", [risk_score, risk_level, cd_type, "STR to GIIF REQUIRED!" { str_required } else ""]),
        "_legal_basis": "Ustawa AML (Art. 33-43); Art. 83-86 (STR/GIF)",
        "_description": "INN02: AML Risk Scoring Matrix — 6-factor point-based CDD/EDD auto-classifier"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN03: BDO WASTE AUTO-CLASSIFIER
# Automatyczna klasyfikacja odpadów EWC z detekcją niebezpiecznych
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "generates_waste", false) == true

    waste_type := object.get(input.jdg_entrepreneur, "waste_type", "MIXED")
    waste_weight_kg := object.get(input.jdg_entrepreneur, "waste_weight_kg", 0)

    ewc_mapping := {
        "PAPER": {"ewc": "20 01 01", "name": "Papier i tektura", "category": "MUNICIPAL", "hazardous": false},
        "PLASTIC": {"ewc": "20 01 39", "name": "Tworzywa sztuczne", "category": "MUNICIPAL", "hazardous": false},
        "METAL": {"ewc": "20 01 40", "name": "Metale", "category": "MUNICIPAL", "hazardous": false},
        "GLASS": {"ewc": "20 01 02", "name": "Szkło", "category": "MUNICIPAL", "hazardous": false},
        "ELECTRONICS": {"ewc": "20 01 35*", "name": "Zużyty sprzęt elektryczny (niebezpieczny)", "category": "WEEE", "hazardous": true},
        "BATTERIES": {"ewc": "20 01 33*", "name": "Baterie i akumulatory", "category": "HAZARDOUS", "hazardous": true},
        "CONSTRUCTION": {"ewc": "17 01 07", "name": "Odpady budowlane", "category": "CONSTRUCTION", "hazardous": false},
        "HAZARDOUS": {"ewc": "20 01 27*", "name": "Farby, tusze, kleje (niebezpieczne)", "category": "HAZARDOUS", "hazardous": true},
        "ORGANIC": {"ewc": "20 01 08", "name": "Odpady kuchenne ulegające biodegradacji", "category": "ORGANIC", "hazardous": false},
        "MIXED": {"ewc": "20 03 01", "name": "Niesegregowane odpady komunalne", "category": "MIXED", "hazardous": false},
        "MEDICAL": {"ewc": "18 01 03*", "name": "Odpady medyczne (niebezpieczne)", "category": "MEDICAL", "hazardous": true},
        "PACKAGING": {"ewc": "15 01 01", "name": "Opakowania z papieru i tektury", "category": "PACKAGING", "hazardous": false}
    }

    waste_info := object.get(ewc_mapping, waste_type, ewc_mapping["MIXED"])
    is_hazardous := waste_info.hazardous
    ewc_code := waste_info.ewc

    # BDO registration fee
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    bdo_fee_pln := 100 { not has_employees }
    bdo_fee_pln := 300 { has_employees }

    # Hazardous waste: special requirements
    needs_adr := is_hazardous
    needs_permit := waste_type in {"ELECTRONICS", "BATTERIES", "HAZARDOUS", "MEDICAL"}
    needs_kpo_electronic := true
    reporting_deadline := "Q: 30 kwietnia / 31 lipca / 31 października / 31 stycznia"

    max_fine_pln := 1000000 { not is_hazardous }
    max_fine_pln := 1000000 { is_hazardous }

    routing := "BLOCK_AND_ALERT" { is_hazardous and not object.get(input.jdg_entrepreneur, "bdo_registered", false) }
    routing := "TRIAGE_QUEUE" { not object.get(input.jdg_entrepreneur, "bdo_registered", false) }
    routing := "WARNING" { is_hazardous }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.bdo_waste_classifier",
        "package": "jdg.p14_innovations",
        "priority": 14003,
        "p14_inn03_waste_type": waste_type,
        "p14_inn03_ewc_code": ewc_code,
        "p14_inn03_waste_name": waste_info.name,
        "p14_inn03_is_hazardous": is_hazardous,
        "p14_inn03_weight_kg": waste_weight_kg,
        "p14_inn03_bdo_fee_pln": bdo_fee_pln,
        "p14_inn03_needs_adr": needs_adr,
        "p14_inn03_needs_permit": needs_permit,
        "p14_inn03_needs_kpo": needs_kpo_electronic,
        "p14_inn03_reporting_deadline": reporting_deadline,
        "p14_inn03_max_fine_pln": max_fine_pln,
        "_routing": routing,
        "_routing_reason": sprintf("BDO: %s → EWC %s (%s). Hazardous: %s. Fee: %d PLN. Permit: %s", [waste_type, ewc_code, waste_info.name, is_hazardous, bdo_fee_pln, needs_permit]),
        "_legal_basis": "Ustawa o odpadach; Rozporządzenie EWC; BDO",
        "_description": "INN03: BDO Waste Auto-Classifier — 12 EWC categories + hazardous detection + ADR/permit check"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN04: DATA SUBJECT REQUEST AUTO-PROCESSOR
# Automatyczna obsługa żądań RODO z trackowaniem terminów
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "rodo_dsar_received", false) == true

    dsar_type := object.get(input.jdg_entrepreneur, "dsar_type", "ACCESS")
    dsar_date_days_ago := object.get(input.jdg_entrepreneur, "dsar_days_elapsed", 0)
    dsar_complexity := object.get(input.jdg_entrepreneur, "dsar_complexity", "STANDARD")

    standard_deadline := 30
    extended_deadline := 60

    deadline_days := standard_deadline { dsar_complexity == "STANDARD" }
    deadline_days := extended_deadline { dsar_complexity == "COMPLEX" }
    deadline_days := standard_deadline { true }

    days_remaining := deadline_days - dsar_date_days_ago

    dsar_actions := {
        "ACCESS": {"obligation": "Provide copy of all personal data", "format": "JSON/CSV/PDF", "fee": 0},
        "ERASURE": {"obligation": "Delete all personal data from all systems", "format": "Confirmation of deletion", "fee": 0, "exceptions": ["accounting_data_5yr"]},
        "RECTIFICATION": {"obligation": "Correct inaccurate personal data", "format": "Updated records", "fee": 0},
        "PORTABILITY": {"obligation": "Export data in machine-readable format", "format": "JSON/CSV", "fee": 0},
        "RESTRICTION": {"obligation": "Restrict processing temporarily", "format": "Processing freeze note", "fee": 0},
        "OBJECTION": {"obligation": "Stop processing for specific purpose", "format": "Processing stop confirmation", "fee": 0}
    }

    dsar_info := object.get(dsar_actions, dsar_type, dsar_actions["ACCESS"])
    dsar_fee_pln := 0

    escalation := "OK" { days_remaining > 20 }
    escalation := "MONITOR" { days_remaining <= 20; days_remaining > 10 }
    escalation := "WARNING" { days_remaining <= 10; days_remaining > 3 }
    escalation := "URGENT" { days_remaining <= 3; days_remaining > 0 }
    escalation := "OVERDUE" { days_remaining <= 0 }

    routing := "BLOCK_AND_ALERT" { escalation == "OVERDUE" }
    routing := "BLOCK_AND_ALERT" { escalation == "URGENT" }
    routing := "TRIAGE_QUEUE" { escalation == "WARNING" }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.dsar_auto_processor",
        "package": "jdg.p14_innovations",
        "priority": 14004,
        "p14_inn04_dsar_type": dsar_type,
        "p14_inn04_days_elapsed": dsar_date_days_ago,
        "p14_inn04_deadline_days": deadline_days,
        "p14_inn04_days_remaining": days_remaining,
        "p14_inn04_escalation": escalation,
        "p14_inn04_obligation": dsar_info.obligation,
        "p14_inn04_format": dsar_info.format,
        "p14_inn04_fee_pln": dsar_fee_pln,
        "p14_inn04_next_action": sprintf("DSAR %s — %d days remaining. %s", [dsar_type, days_remaining, dsar_info.obligation]),
        "_routing": routing,
        "_routing_reason": sprintf("DSAR: %s — %d/%d days (%s)", [dsar_type, days_remaining, deadline_days, escalation]),
        "_legal_basis": "Art. 15-22 RODO; Art. 12 ust. 3 RODO (30 dni)",
        "_description": "INN04: Data Subject Request Auto-Processor — 6 DSAR types + deadline tracking with escalation"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN05: SUSPICIOUS TRANSACTION PATTERN DETECTOR
# AI-based pattern detection dla AML/CFT
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.invoice, "aml_check_required", false) == true

    tx_amount := object.get(input.invoice, "amount_eur", 0)
    payment_method := object.get(input.invoice, "payment_method", "TRANSFER")
    vendor_country := object.get(input.vendor, "country", "PL")
    vendor_name := object.get(input.vendor, "name", "Unknown")
    tx_frequency_30days := object.get(input.jdg_entrepreneur, "tx_frequency_30days", 1)

    patterns_detected := []
    pattern_score := 0

    # Pattern 1: Cash over 10k EUR
    pattern_detected := payment_method == "CASH" and tx_amount >= 10000
    patterns_detected := array.concat(patterns_detected, ["CASH_OVER_10K_EUR"]) { pattern_detected }
    pattern_score := pattern_score + 3 { pattern_detected }

    # Pattern 2: Structuring — multiple smaller transactions
    pattern_detected := tx_frequency_30days >= 5 and tx_amount * tx_frequency_30days >= 50000
    patterns_detected := array.concat(patterns_detected, ["STRUCTURING"]) { pattern_detected }
    pattern_score := pattern_score + 5 { pattern_detected }

    # Pattern 3: High-risk jurisdiction
    high_risk := {"AF","BY","CU","IR","KP","LY","MM","RU","SD","SY","VE","YE","ZW"}
    pattern_detected := vendor_country in high_risk and tx_amount >= 10000
    patterns_detected := array.concat(patterns_detected, ["HIGH_RISK_JURISDICTION"]) { pattern_detected }
    pattern_score := pattern_score + 4 { pattern_detected }

    # Pattern 4: Round-trip / circular
    is_round_trip := object.get(input.invoice, "circular_flow", false)
    patterns_detected := array.concat(patterns_detected, ["CIRCULAR_TRANSACTION"]) { is_round_trip }
    pattern_score := pattern_score + 5 { is_round_trip }

    # Pattern 5: Unusual frequency
    pattern_detected := tx_frequency_30days >= 10
    patterns_detected := array.concat(patterns_detected, ["UNUSUAL_FREQUENCY"]) { pattern_detected }
    pattern_score := pattern_score + 2 { pattern_detected }

    # Pattern 6: Layering
    pattern_detected := payment_method == "TRANSFER" and tx_amount < 1000 and tx_frequency_30days >= 3
    patterns_detected := array.concat(patterns_detected, ["POTENTIAL_LAYERING"]) { pattern_detected }
    pattern_score := pattern_score + 3 { pattern_detected }

    patterns_count := count(patterns_detected)
    str_required := pattern_score >= 5

    routing := "BLOCK_AND_ALERT" { str_required and pattern_score >= 8 }
    routing := "TRIAGE_QUEUE" { str_required }
    routing := "WARNING" { patterns_count > 0 and not str_required }
    routing := "" { patterns_count == 0 }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.suspicious_tx_detector",
        "_legal_basis": "RODO (GDPR) — Rozporządzenie 2016/679; Art. 83 (kary)",
        "package": "jdg.p14_innovations",
        "priority": 14005,
        "p14_inn05_patterns_detected": patterns_detected,
        "p14_inn05_pattern_score": pattern_score,
        "p14_inn05_patterns_count": patterns_count,
        "p14_inn05_str_required": str_required,
        "p14_inn05_str_deadline_hours": 48,
        "p14_inn05_report_to": "GIIF (Generalny Inspektor Informacji Finansowej)",
        "p14_inn05_penalty_pln": 5000000,
        "p14_inn05_next_action": sprintf("FILE STR to GIIF within 48h! Penalty: up to 5M PLN!") { str_required },
        "p14_inn05_next_action": "Monitor — suspicious patterns detected below STR threshold" { patterns_count > 0 and not str_required },
        "p14_inn05_next_action": "" { patterns_count == 0 },
        "_routing": routing,
        "_routing_reason": sprintf("AML Patterns: %d detected (score: %d). %s", [patterns_count, pattern_score, "STR to GIIF!" { str_required } else ""]),
        "_legal_basis": "Art. 83-86 Ustawy AML; Dyrektywa AMLD6",
        "_description": "INN05: Suspicious Transaction Pattern Detector — 6 patterns + point-based STR trigger"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN06: PRIVACY-BY-DESIGN RULE ENFORCER
# Egzekwowanie 6 zasad Privacy-by-Design dla nowych systemów
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "new_system_feature", false) == true

    system_name := object.get(input.jdg_entrepreneur, "system_name", "New System")
    processes_personal_data := object.get(input.jdg_entrepreneur, "system_processes_data", true)
    uses_encryption := object.get(input.jdg_entrepreneur, "system_encryption", false)
    uses_pseudonymization := object.get(input.jdg_entrepreneur, "system_pseudonymization", false)
    has_retention_policy := object.get(input.jdg_entrepreneur, "system_retention_policy", false)
    has_purpose_defined := object.get(input.jdg_entrepreneur, "system_purpose_defined", false)
    has_audit_logging := object.get(input.jdg_entrepreneur, "system_audit_logging", false)
    has_dpia_completed := object.get(input.jdg_entrepreneur, "system_dpia_completed", false)

    principles := {
        "Data_Minimization": processes_personal_data,
        "Purpose_Limitation": has_purpose_defined,
        "Storage_Limitation": has_retention_policy,
        "Integrity_Confidentiality": uses_encryption,
        "Accountability": has_audit_logging,
        "Privacy_by_Default": uses_pseudonymization
    }

    principles_met := count({k | principles[k] == true})
    principles_total := count(principles)
    pbdd_score := floor((principles_met / principles_total) * 10000) / 100

    dpia_required := processes_personal_data and not has_dpia_completed
    blocked := dpia_required

    routing := "BLOCK_AND_ALERT" { blocked }
    routing := "TRIAGE_QUEUE" { pbdd_score < 67 and not blocked }
    routing := "WARNING" { pbdd_score < 100 and not blocked }
    routing := "" { pbdd_score == 100 }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.privacy_by_design",
        "_legal_basis": "RODO (GDPR) — Rozporządzenie 2016/679; Art. 83 (kary)",
        "package": "jdg.p14_innovations",
        "priority": 14006,
        "p14_inn06_system_name": system_name,
        "p14_inn06_pbdd_score": pbdd_score,
        "p14_inn06_principles_met": principles_met,
        "p14_inn06_principles_total": principles_total,
        "p14_inn06_principles": principles,
        "p14_inn06_dpia_required": dpia_required,
        "p14_inn06_blocked": blocked,
        "p14_inn06_next_action": "System ready — all PbD principles met" { pbdd_score == 100 },
        "p14_inn06_next_action": sprintf("Fix %d missing principles before launch", [principles_total - principles_met]) { pbdd_score < 100 },
        "_routing": routing,
        "_routing_reason": sprintf("PbD: %s — %.0f%% principles met. DPIA: %s", [system_name, pbdd_score, "REQUIRED!" { dpia_required } else "OK"]),
        "_legal_basis": "Art. 25 RODO (Privacy by Design & Default); Art. 35 RODO (DPIA)",
        "_description": "INN06: Privacy-by-Design Rule Enforcer — 6 principles + DPIA gate"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN07: CROSS-BORDER DATA TRANSFER BLOCKER
# Blokada nieautoryzowanych transferów danych poza EOG
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "processes_personal_data", false) == true
    transfer_country := object.get(input.jdg_entrepreneur, "data_transfer_country", "PL")

    eog_countries := {"AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IS","IE","IT","LV","LI","LT","LU","MT","NL","NO","PL","PT","RO","SK","SI","ES","SE","CH"}
    is_eog := transfer_country in eog_countries

    has_adequacy := object.get(input.jdg_entrepreneur, "rodo_adequacy_decision", false)
    has_scc := object.get(input.jdg_entrepreneur, "rodo_scc_documented", false)
    has_bcr := object.get(input.jdg_entrepreneur, "rodo_bcr_approved", false)
    has_dpia := object.get(input.jdg_entrepreneur, "rodo_tia_completed", false)
    has_schrems_ii := has_scc and has_dpia

    has_safeguard := has_adequacy or has_scc or has_bcr
    transfer_allowed := is_eog or (not is_eog and has_safeguard and has_schrems_ii)
    blocked := not is_eog and not transfer_allowed

    # Adequacy decisions (current as of 2026)
    adequacy_countries := {"AD","AR","CA","FO","GG","IL","IM","JP","JE","KR","NZ","UK","UY"}
    has_adequacy_decision := transfer_country in adequacy_countries

    required_safeguards := []
    required_safeguards := array.concat(required_safeguards, ["SCC (Standard Contractual Clauses)"]) { not has_scc; not is_eog }
    required_safeguards := array.concat(required_safeguards, ["TIA (Transfer Impact Assessment — Schrems II)"]) { not has_dpia; not is_eog }
    required_safeguards := array.concat(required_safeguards, ["DPIA"]) { not has_dpia; not is_eog }

    routing := "BLOCK_AND_ALERT" { blocked }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.cross_border_blocker",
        "_legal_basis": "RODO (GDPR) — Rozporządzenie 2016/679; Art. 83 (kary)",
        "package": "jdg.p14_innovations",
        "priority": 14007,
        "p14_inn07_transfer_country": transfer_country,
        "p14_inn07_is_eog": is_eog,
        "p14_inn07_has_adequacy": has_adequacy,
        "p14_inn07_has_scc": has_scc,
        "p14_inn07_has_bcr": has_bcr,
        "p14_inn07_has_tia": has_dpia,
        "p14_inn07_schrems_ii_compliant": has_schrems_ii,
        "p14_inn07_transfer_allowed": transfer_allowed,
        "p14_inn07_blocked": blocked,
        "p14_inn07_required_safeguards": required_safeguards,
        "p14_inn07_max_fine_eur": 20000000,
        "_routing": routing,
        "_routing_reason": sprintf("Data Transfer: %s → %s. EOG: %s. Safeguards: %s. Status: %s", ["PL", transfer_country, is_eog, "OK" { has_safeguard } else "NONE", "BLOCKED!" { blocked } else "ALLOWED"]),
        "_legal_basis": "Art. 44-49 RODO; Wyrok Schrems II (C-311/18)",
        "_description": "INN07: Cross-Border Data Transfer Blocker — EOG check + SCC/BCR/Adequacy + Schrems II"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN08: AML/KYC AUTO-ONBOARDING
# Automatyczne KYC dla kontrahentów — 6 kroków weryfikacji
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.vendor, "is_new_counterparty", false) == true

    # 6-step KYC check
    has_id_document := object.get(input.vendor, "kyc_id_verified", false)
    crbr_checked := object.get(input.vendor, "crbr_checked", false)
    whitelist_checked := object.get(input.vendor, "vat_whitelist_checked", false)
    sanctions_checked := object.get(input.vendor, "sanctions_list_checked", false)
    pep_checked := object.get(input.vendor, "pep_screening_done", false)
    risk_assessed := object.get(input.vendor, "aml_risk_assessed", false)

    kyc_steps := {
        "1_ID_Verification": has_id_document,
        "2_CRBR_BeneficialOwner": crbr_checked,
        "3_VAT_WhiteList": whitelist_checked,
        "4_Sanctions_Screening": sanctions_checked,
        "5_PEP_Check": pep_checked,
        "6_Risk_Assessment": risk_assessed
    }

    steps_completed := count({k | kyc_steps[k] == true})
    steps_total := count(kyc_steps)
    kyc_pct := floor((steps_completed / steps_total) * 10000) / 100

    missing_steps := [k | kyc_steps[k] == false]
    can_onboard := steps_completed >= 4 and has_id_document

    onboarding_status := "READY" { steps_completed == 6 }
    onboarding_status := sprintf("PENDING: %d steps remaining", [steps_total - steps_completed]) { steps_completed >= 4 and steps_completed < 6 }
    onboarding_status := "BLOCKED" { steps_completed < 4 }

    routing := "BLOCK_AND_ALERT" { onboarding_status == "BLOCKED" }
    routing := "TRIAGE_QUEUE" { not can_onboard }
    routing := "" { can_onboard }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.aml_kyc_onboarding",
        "package": "jdg.p14_innovations",
        "priority": 14008,
        "p14_inn08_kyc_pct": kyc_pct,
        "p14_inn08_steps_completed": steps_completed,
        "p14_inn08_steps_total": steps_total,
        "p14_inn08_missing_steps": missing_steps,
        "p14_inn08_can_onboard": can_onboard,
        "p14_inn08_onboarding_status": onboarding_status,
        "p14_inn08_kyc_steps": kyc_steps,
        "p14_inn08_crbr_url": "https://crbr.podatki.gov.pl",
        "_routing": routing,
        "_routing_reason": sprintf("KYC Onboarding: %.0f%% (%d/%d steps). Status: %s", [kyc_pct, steps_completed, steps_total, onboarding_status]),
        "_legal_basis": "Art. 34-43 Ustawy AML; Art. 58-79 CBDD",
        "_description": "INN08: AML/KYC Auto-Onboarding — 6-step verification with partial progress tolerance"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN09: CONSENT LIFECYCLE MANAGER
# Zarządzanie cyklem życia zgód RODO z auto-przeterminowaniem
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "has_marketing_consents", false) == true

    consent_age_days := object.get(input.jdg_entrepreneur, "consent_age_days", 0)
    consent_type := object.get(input.jdg_entrepreneur, "consent_type", "MARKETING")
    is_double_optin := object.get(input.jdg_entrepreneur, "consent_double_optin", false)
    has_withdrawal_mechanism := object.get(input.jdg_entrepreneur, "consent_withdrawal_available", false)
    consent_granular := object.get(input.jdg_entrepreneur, "consent_granular", false)

    expiry_days := 365
    days_remaining := expiry_days - consent_age_days
    is_expired := days_remaining <= 0
    nearing_expiry := days_remaining <= 30 and days_remaining > 0

    consent_valid := not is_expired and is_double_optin and has_withdrawal_mechanism and consent_granular
    consent_issues := []
    consent_issues := array.concat(consent_issues, ["EXPIRED — re-consent required!"]) { is_expired }
    consent_issues := array.concat(consent_issues, ["Expiring in " + sprintf("%d", [days_remaining]) + " days"]) { nearing_expiry }
    consent_issues := array.concat(consent_issues, ["Missing double opt-in — consent may be invalid (Art. 7 RODO)"]) { not is_double_optin }
    consent_issues := array.concat(consent_issues, ["No withdrawal mechanism — consent not freely given"]) { not has_withdrawal_mechanism }
    consent_issues := array.concat(consent_issues, ["Not granular — bundling prohibited under Art. 7(2)"]) { not consent_granular }

    action := "DELETE_DATA" { is_expired }
    action := "PREPARE_RE_CONSENT" { nearing_expiry }
    action := "MONITOR" { days_remaining <= 90 and days_remaining > 30 }
    action := "OK" { true }

    routing := "BLOCK_AND_ALERT" { is_expired }
    routing := "TRIAGE_QUEUE" { nearing_expiry or not consent_valid }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.consent_lifecycle",
        "package": "jdg.p14_innovations",
        "priority": 14009,
        "p14_inn09_consent_type": consent_type,
        "p14_inn09_consent_age_days": consent_age_days,
        "p14_inn09_days_remaining": days_remaining,
        "p14_inn09_is_expired": is_expired,
        "p14_inn09_consent_valid": consent_valid,
        "p14_inn09_consent_issues": consent_issues,
        "p14_inn09_required_action": action,
        "p14_inn09_expiry_period_days": expiry_days,
        "_routing": routing,
        "_routing_reason": sprintf("Consent: %s — %d days old. Valid: %s. Action: %s", [consent_type, consent_age_days, consent_valid, action]),
        "_legal_basis": "Art. 7 RODO (warunki zgody); Art. 17 RODO (usunięcie)",
        "_description": "INN09: Consent Lifecycle Manager — 5 validity checks + expiry tracking + auto-action"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN10: BREACH NOTIFICATION AUTO-DRAFTER
# Automatyczne przygotowanie zgłoszenia naruszenia RODO do UODO
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "rodo_data_breach", false) == true

    breach_type := object.get(input.jdg_entrepreneur, "breach_type", "UNKNOWN")
    breach_date := object.get(input.jdg_entrepreneur, "breach_detection_date", "unknown")
    hours_since_detection := object.get(input.jdg_entrepreneur, "breach_hours_since_detection", 0)
    affected_subjects := object.get(input.jdg_entrepreneur, "breach_affected_subjects", 0)
    affected_records := object.get(input.jdg_entrepreneur, "breach_affected_records", 0)

    deadline_hours := 72
    hours_remaining := deadline_hours - hours_since_detection
    is_overdue := hours_remaining <= 0

    breach_types := {
        "CONFIDENTIALITY": {"risk": "HIGH", "notification_subjects": true, "description": "Unauthorized access to personal data"},
        "INTEGRITY": {"risk": "MEDIUM", "notification_subjects": false, "description": "Unauthorized alteration of data"},
        "AVAILABILITY": {"risk": "MEDIUM", "notification_subjects": false, "description": "Loss of access to personal data"},
        "RANSOMWARE": {"risk": "CRITICAL", "notification_subjects": true, "description": "Ransomware encryption of personal data"},
        "ACCIDENTAL_DISCLOSURE": {"risk": "LOW", "notification_subjects": false, "description": "Accidental sending to wrong recipient"},
        "THEFT": {"risk": "HIGH", "notification_subjects": true, "description": "Physical theft of data carriers"}
    }

    breach_info := object.get(breach_types, breach_type, breach_types["CONFIDENTIALITY"])
    notify_subjects := breach_info.notification_subjects or affected_subjects >= 100
    risk_level := breach_info.risk
    max_fine_eur := 20000000 { risk_level in {"CRITICAL", "HIGH"} }
    max_fine_eur := 10000000 { risk_level in {"MEDIUM", "LOW"} }

    notification_template := {
        "to": "UODO (Urząd Ochrony Danych Osobowych)",
        "deadline": "72 hours",
        "hours_remaining": hours_remaining,
        "breach_type": breach_type,
        "breach_description": breach_info.description,
        "affected_subjects": affected_subjects,
        "affected_records": affected_records,
        "risk_level": risk_level,
        "notify_data_subjects": notify_subjects,
        "consequences": breach_info.description,
        "measures_taken": "Identify, contain, assess, notify, remediate",
        "contact": "IOD / Data Protection Officer",
        "register_in_breach_log": true
    }

    routing := "BLOCK_AND_ALERT" { is_overdue }
    routing := "BLOCK_AND_ALERT" { hours_remaining <= 24 }
    routing := "TRIAGE_QUEUE" { hours_remaining <= 48 }
    routing := "WARNING" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.breach_auto_drafter",
        "_legal_basis": "RODO (GDPR) — Rozporządzenie 2016/679; Art. 83 (kary)",
        "package": "jdg.p14_innovations",
        "priority": 14010,
        "p14_inn10_breach_type": breach_type,
        "p14_inn10_hours_since_detection": hours_since_detection,
        "p14_inn10_hours_remaining": hours_remaining,
        "p14_inn10_is_overdue": is_overdue,
        "p14_inn10_risk_level": risk_level,
        "p14_inn10_max_fine_eur": max_fine_eur,
        "p14_inn10_notify_subjects": notify_subjects,
        "p14_inn10_notification_template": notification_template,
        "p14_inn10_affected_subjects": affected_subjects,
        "_routing": routing,
        "_routing_reason": sprintf("RODO Breach: %s (%s risk) — %d/%d hours. %s", [breach_type, risk_level, hours_remaining, deadline_hours, "OVERDUE!" { is_overdue } else "REPORT NOW!"]),
        "_legal_basis": "Art. 33-34 RODO; Art. 83 RODO (kary)",
        "_description": "INN10: Breach Notification Auto-Drafter — 72h deadline tracker + 6 breach types + UODO template"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN11: ENVIRONMENTAL FEE CALCULATOR
# Kalkulator opłat środowiskowych — BDO, KOBiZE, SUP, WEEE
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "generates_waste", false) == true

    waste_type := object.get(input.jdg_entrepreneur, "waste_type", "MIXED")
    waste_weight_kg := object.get(input.jdg_entrepreneur, "waste_weight_kg", 0)
    uses_single_use_plastics := object.get(input.jdg_entrepreneur, "uses_sup", false)
    sup_units := object.get(input.jdg_entrepreneur, "sup_units_sold", 0)

    # BDO fee by company size
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    bdo_registration_fee := 100 { not has_employees }
    bdo_registration_fee := 300 { has_employees }

    # EWC-based waste fee estimation
    waste_fee_per_kg := 0.10 { waste_type in {"PAPER","PLASTIC","METAL","GLASS","ORGANIC","MIXED"} }
    waste_fee_per_kg := 0.50 { waste_type in {"CONSTRUCTION"} }
    waste_fee_per_kg := 2.00 { waste_type in {"ELECTRONICS","BATTERIES","HAZARDOUS"} }
    waste_fee_per_kg := 3.00 { waste_type in {"MEDICAL"} }
    waste_fee_per_kg := 0.15 { true }

    waste_disposal_fee_pln := floor(waste_weight_kg * waste_fee_per_kg * 100) / 100

    # SUP fee: 0.25 PLN per unit
    sup_fee_per_unit := 0.25
    sup_total_fee_pln := floor(sup_units * sup_fee_per_unit * 100) / 100 { uses_single_use_plastics }
    sup_total_fee_pln := 0 { not uses_single_use_plastics }

    # KOBiZE reporting threshold
    kobize_threshold_tonnes := 1.0
    kobize_required := waste_weight_kg / 1000 >= kobize_threshold_tonnes

    total_env_fees_pln := floor((bdo_registration_fee + waste_disposal_fee_pln + sup_total_fee_pln) * 100) / 100

    routing := "WARNING" { total_env_fees_pln > 1000 }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.env_fee_calculator",
        "package": "jdg.p14_innovations",
        "priority": 14011,
        "p14_inn11_bdo_registration_fee": bdo_registration_fee,
        "p14_inn11_waste_disposal_fee_pln": waste_disposal_fee_pln,
        "p14_inn11_sup_fee_total_pln": sup_total_fee_pln,
        "p14_inn11_total_env_fees_pln": total_env_fees_pln,
        "p14_inn11_waste_type": waste_type,
        "p14_inn11_waste_weight_kg": waste_weight_kg,
        "p14_inn11_waste_fee_per_kg": waste_fee_per_kg,
        "p14_inn11_sup_units": sup_units,
        "p14_inn11_kobize_required": kobize_required,
        "p14_inn11_kobize_threshold_tonnes": kobize_threshold_tonnes,
        "p14_inn11_reporting_deadlines": ["BDO: quarterly", "SUP: quarterly", "KOBiZE: annually by 28 Feb"],
        "_routing": routing,
        "_routing_reason": sprintf("Env Fees: BDO %d PLN + Waste %.0f PLN + SUP %.0f PLN = %.0f PLN total", [bdo_registration_fee, waste_disposal_fee_pln, sup_total_fee_pln, total_env_fees_pln]),
        "_legal_basis": "Ustawa o odpadach (BDO); Ustawa SUP; KOBiZE",
        "_description": "INN11: Environmental Fee Calculator — BDO + waste disposal + SUP + KOBiZE"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN12: REGULATORY CHANGE IMPACT ANALYZER
# Analiza wpływu zmian regulacyjnych na JDG
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    monitored_regulations := [
        {"name": "RODO/GDPR", "effective": "2018-05-25", "next_revision": "2027", "risk": "HIGH", "max_penalty_pln": 180000000},
        {"name": "AML Act", "effective": "2018-10-13", "next_revision": "2026", "risk": "HIGH", "max_penalty_pln": 5000000},
        {"name": "BDO / Waste Act", "effective": "2019-01-01", "next_revision": "2026", "risk": "MEDIUM", "max_penalty_pln": 1000000},
        {"name": "Whistleblower Act", "effective": "2024-12-25", "next_revision": "2026", "risk": "LOW", "max_penalty_pln": 30000},
        {"name": "NIS2 Directive", "effective": "2024-10-17", "next_revision": "2027", "risk": "MEDIUM", "max_penalty_pln": 10000000},
        {"name": "Data Governance Act", "effective": "2023-09-24", "next_revision": "2026", "risk": "LOW", "max_penalty_pln": 10000000},
        {"name": "EU AI Act", "effective": "2025-06-01", "next_revision": "2027", "risk": "HIGH", "max_penalty_pln": 35000000}
    ]

    # Check which regulations apply to this JDG
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    processes_data := object.get(input.jdg_entrepreneur, "processes_personal_data", false)
    uses_ai := object.get(input.jdg_entrepreneur, "uses_ai_systems", false)
    has_cyber := object.get(input.jdg_entrepreneur, "has_it_infrastructure", false)
    is_aml_obliged := object.get(input.jdg_entrepreneur, "is_aml_obliged", false)

    applicable_regulations := []
    high_risk_regulations := []

    # RODO: applies if processes personal data
    applicable_regulations := array.concat(applicable_regulations, ["RODO/GDPR"]) { processes_data }
    high_risk_regulations := array.concat(high_risk_regulations, ["RODO/GDPR"]) { processes_data }

    # AML: applies if in obliged PKD
    applicable_regulations := array.concat(applicable_regulations, ["AML_Act"]) { is_aml_obliged }
    high_risk_regulations := array.concat(high_risk_regulations, ["AML_Act"]) { is_aml_obliged }

    # Whistleblower: applies if ≥50 employees
    applicable_regulations := array.concat(applicable_regulations, ["Whistleblower"]) { has_employees }

    # NIS2: applies if has IT infrastructure
    applicable_regulations := array.concat(applicable_regulations, ["NIS2"]) { has_cyber }

    # AI Act: applies if uses AI systems
    applicable_regulations := array.concat(applicable_regulations, ["AI_Act"]) { uses_ai }
    high_risk_regulations := array.concat(high_risk_regulations, ["AI_Act"]) { uses_ai }

    # BDO: always applicable
    applicable_regulations := array.concat(applicable_regulations, ["BDO"])

    applicable_count := count(applicable_regulations)
    high_risk_count := count(high_risk_regulations)

    total_max_penalty := 0
    total_max_penalty := total_max_penalty + 180000000 { processes_data }
    total_max_penalty := total_max_penalty + 5000000 { is_aml_obliged }
    total_max_penalty := total_max_penalty + 1000000 { true }
    total_max_penalty := total_max_penalty + 30000 { has_employees }
    total_max_penalty := total_max_penalty + 10000000 { has_cyber }
    total_max_penalty := total_max_penalty + 35000000 { uses_ai }

    impact_score := 0
    impact_score := impact_score + 30 { processes_data }
    impact_score := impact_score + 25 { is_aml_obliged }
    impact_score := impact_score + 20 { uses_ai }
    impact_score := impact_score + 15 { has_cyber }
    impact_score := impact_score + 10 { has_employees }

    impact_level := "LOW" { impact_score < 30 }
    impact_level := "MEDIUM" { impact_score >= 30; impact_score < 60 }
    impact_level := "HIGH" { impact_score >= 60 }

    routing := "TRIAGE_QUEUE" { impact_level == "HIGH" }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.p14_innovations.regulatory_change_analyzer",
        "package": "jdg.p14_innovations",
        "priority": 14012,
        "p14_inn12_applicable_count": applicable_count,
        "p14_inn12_applicable_regulations": applicable_regulations,
        "p14_inn12_high_risk_regulations": high_risk_regulations,
        "p14_inn12_impact_score": impact_score,
        "p14_inn12_impact_level": impact_level,
        "p14_inn12_total_max_penalty_pln": total_max_penalty,
        "p14_inn12_monitored_total": count(monitored_regulations),
        "p14_inn12_next_review": "Quarterly regulatory scan recommended",
        "_routing": routing,
        "_routing_reason": sprintf("Regulatory Impact: %d regulations apply (%d high-risk). Impact: %s (%d/100). Max exposure: %.0fM PLN", [applicable_count, high_risk_count, impact_level, impact_score, total_max_penalty / 1000000]),
        "_legal_basis": "RODO, AML, BDO, Whistleblower, NIS2, DGA, AI Act",
        "_description": "INN12: Regulatory Change Impact Analyzer — 7 regulations monitored + personalized impact scoring"
    }
}
