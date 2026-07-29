# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P14 COMPLIANCE + RODO + AML + BDO INNOVATIONS v8.0
# ═══════════════════════════════════════════════════════════════════════════════
# 12 Enterprise Innovations for Compliance, RODO, AML, BDO
# Built on: rodo.rego (12 rules), rodo_extended.rego, compliance.rego,
#           _compliance_rates.rego, environmental/bdo_enterprise.rego
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.p14_innovations

import future.keywords.in
import data.jdg.compliance_rates

default decide := {
    "matched": false, "rule_id": "jdg.p14.no_innovation_match",
    "package": "jdg.p14_innovations", "priority": 99999,
    "innovation": "NONE"
}

# ══════ INN01: GDPR Auto-Compliance Engine (priority 1000) ══════
decide := {
    "matched": true,
    "rule_id": "jdg.p14.gdpr_auto_compliance",
    "package": "jdg.p14_innovations", "priority": 1000,
    "innovation": "INN01_GDPR_AUTO_COMPLIANCE",
    "gdpr_obligations_checked": count(compliance_rates.gdpr_obligations),
    "gdpr_max_fine": compliance_rates.gdpr_fines.max_fine,
    "checks": [
        "Art. 30 RODO — Rejestr czynności przetwarzania",
        "Art. 7 RODO — Zgody marketingowe (dobrowolne, odrębne)",
        "Art. 17 RODO — Prawo do usunięcia (30 dni)",
        "Art. 33 RODO — Zgłoszenie naruszenia (72h do UODO)",
        "Art. 37 RODO — IOD gdy duża skala",
        "Art. 28 RODO — Umowy powierzenia",
        "Art. 25 RODO — Privacy by Design & Default",
    ],
    "_legal_basis": "RODO (GDPR) — Rozporządzenie 2016/679",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "processes_personal_data", false) == true
}

# ══════ INN02: AML Risk Scoring Matrix (priority 2000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.aml_risk_matrix",
    "package": "jdg.p14_innovations", "priority": 2000,
    "innovation": "INN02_AML_RISK_MATRIX",
    "aml_risk_factors": compliance_rates.aml_risk_factors,
    "aml_cash_threshold_eur": compliance_rates.aml_thresholds.cash_eur,
    "aml_report_to": compliance_rates.aml_thresholds.report_to,
    "cdd_required": true,
    "edd_required": false,
    "_legal_basis": "AML Act — Art. 9b-9f",
    "_warnings": ["AML Risk Scoring: PEP, high-risk jurisdictions, cash >15k EUR trigger enhanced due diligence"]
} {
    object.get(input.invoice, "aml_check_required", false) == true
}

# ══════ INN03: BDO Waste Auto-Classifier (priority 3000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.bdo_waste_classifier",
    "package": "jdg.p14_innovations", "priority": 3000,
    "innovation": "INN03_BDO_WASTE_CLASSIFIER",
    "ewc_codes_available": count(compliance_rates.ewc_codes),
    "bdo_max_fine_pln": compliance_rates.bdo_max_fine_pln,
    "auto_classify": true,
    "_legal_basis": "Ustawa o odpadach — BDO, Rozporządzenie EWC",
    "_warnings": ["Auto-klasyfikacja odpadów EWC: papier, plastik, metal, szkło, elektronika, baterie, niebezpieczne, zmieszane"]
} {
    object.get(input.jdg_entrepreneur, "generates_waste", false) == true
}

# ══════ INN04: Data Subject Request Auto-Processor (priority 4000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.dsar_auto_processor",
    "package": "jdg.p14_innovations", "priority": 4000,
    "innovation": "INN04_DSAR_AUTO_PROCESSOR",
    "dsar_types": ["ACCESS", "ERASURE", "RECTIFICATION", "PORTABILITY", "RESTRICTION", "OBJECTION"],
    "deadline_days": 30,
    "extendable_days": 30,
    "_legal_basis": "Art. 15-22 RODO",
    "_warnings": ["DSAR: 30 dni na odpowiedź (+30 dni przedłużenie przy skomplikowanych). Odmowa tylko z uzasadnieniem."]
} {
    object.get(input.jdg_entrepreneur, "rodo_dsar_received", false) == true
}

# ══════ INN05: Suspicious Transaction Pattern Detector (priority 5000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.suspicious_tx_detector",
    "package": "jdg.p14_innovations", "priority": 5000,
    "innovation": "INN05_SUSPICIOUS_TX_DETECTOR",
    "patterns": [
        "CASH_OVER_15K_EUR — Gotówka >15k EUR",
        "HIGH_VALUE_TAX_HAVEN — >100k do rajów podatkowych",
        "CIRCULAR_TRANSACTION — Transakcje okrężne",
        "STRUCTURING — Podział na mniejsze kwoty",
        "UNUSUAL_FREQUENCY — Nietypowa częstotliwość",
    ],
    "str_report_to": "GIIF",
    "_legal_basis": "AML Act — Art. 34-43",
    "_warnings": ["Wykryto podejrzane wzorce transakcji — rozważ zgłoszenie STR do GIIF"]
} {
    object.get(input.invoice, "suspicious_pattern_detected", false) == true
}

# ══════ INN06: Privacy-by-Design Rule Enforcer (priority 6000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.privacy_by_design",
    "package": "jdg.p14_innovations", "priority": 6000,
    "innovation": "INN06_PRIVACY_BY_DESIGN",
    "principles": [
        "Data minimization — zbieraj tylko niezbędne dane",
        "Purpose limitation — określ cel przetwarzania",
        "Storage limitation — usuń po okresie retencji",
        "Integrity & confidentiality — szyfrowanie, pseudonimizacja",
        "Accountability — logi, audyt, dokumentacja",
        "Privacy by default — domyślnie max ochrona",
    ],
    "_legal_basis": "Art. 25 RODO",
    "_warnings": ["Privacy-by-Design: każda nowa funkcja musi przejść DPIA i spełniać 6 zasad"]
} {
    object.get(input.jdg_entrepreneur, "new_system_feature", false) == true
}

# ══════ INN07: Cross-Border Data Transfer Blocker (priority 7000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.cross_border_blocker",
    "package": "jdg.p14_innovations", "priority": 7000,
    "innovation": "INN07_CROSS_BORDER_BLOCKER",
    "transfer_check": "EOG ↔ third country",
    "required_safeguards": [
        "Decyzja adekwatności KE (Art. 45)",
        "Standardowe Klauzule Umowne SCC (Art. 46)",
        "Wiążące Reguły Korporacyjne BCR (Art. 47)",
    ],
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Transfer danych poza EOG bez zabezpieczeń",
    "_legal_basis": "Art. 44-49 RODO",
    "_warnings": ["Transfer danych poza EOG ZABLOKOWANY — brak SCC/BCR/decyzji adekwatności"]
} {
    object.get(input.jdg_entrepreneur, "rodo_data_transfer_eog", false) == true
    object.get(input.jdg_entrepreneur, "rodo_scc_documented", false) == false
    object.get(input.jdg_entrepreneur, "rodo_bcr_approved", false) == false
    object.get(input.jdg_entrepreneur, "rodo_adequacy_decision", false) == false
}

# ══════ INN08: AML/KYC Auto-Onboarding (priority 8000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.aml_kyc_onboarding",
    "package": "jdg.p14_innovations", "priority": 8000,
    "innovation": "INN08_AML_KYC_ONBOARDING",
    "kyc_steps": [
        "1. Weryfikacja tożsamości (dowód osobisty/paszport)",
        "2. Sprawdzenie CRBR (beneficjent rzeczywisty)",
        "3. Biała Lista VAT — weryfikacja NIP",
        "4. Sankcje — listy UE/UN/OFAC",
        "5. PEP check — osoby na eksponowanych stanowiskach",
        "6. Ocena ryzyka — LOW/MEDIUM/HIGH",
    ],
    "crbr_check_required": true,
    "_legal_basis": "AML Act — Art. 34-43, CRBR",
    "_warnings": ["AML/KYC: nowy kontrahent wymaga pełnej weryfikacji w 6 krokach"]
} {
    object.get(input.vendor, "is_new_counterparty", false) == true
}

# ══════ INN09: Consent Lifecycle Manager (priority 9000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.consent_lifecycle",
    "package": "jdg.p14_innovations", "priority": 9000,
    "innovation": "INN09_CONSENT_LIFECYCLE",
    "consent_requirements": {
        "dobrowolna": true,
        "konkretna": true,
        "świadoma": true,
        "jednoznaczna": true,
        "odwoływalna": true,
    },
    "refresh_period_days": 365,
    "expired_action": "RE-CONSENT or DELETE",
    "_legal_basis": "Art. 7 RODO",
    "_warnings": ["Zgody starsze niż 365 dni — odśwież lub usuń dane"]
} {
    object.get(input.jdg_entrepreneur, "has_marketing_consents", false) == true
}

# ══════ INN10: Breach Notification Auto-Drafter (priority 10000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.breach_auto_drafter",
    "package": "jdg.p14_innovations", "priority": 10000,
    "innovation": "INN10_BREACH_AUTO_DRAFTER",
    "deadline_hours": 72,
    "report_to": "UODO (Urząd Ochrony Danych Osobowych)",
    "required_info": [
        "Charakter naruszenia",
        "Kategorie i liczba osób",
        "Kategorie i liczba rekordów",
        "Konsekwencje naruszenia",
        "Podjęte środki zaradcze",
    ],
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Naruszenie RODO — obowiązek zgłoszenia w 72h",
    "_legal_basis": "Art. 33-34 RODO",
    "_warnings": ["NARUSZENIE RODO: zgłoś do UODO w ciągu 72h! Max kara: 20M EUR lub 4% obrotu."]
} {
    object.get(input.jdg_entrepreneur, "rodo_data_breach", false) == true
}

# ══════ INN11: Environmental Fee Calculator (priority 11000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.env_fee_calculator",
    "package": "jdg.p14_innovations", "priority": 11000,
    "innovation": "INN11_ENV_FEE_CALCULATOR",
    "fee_categories": count(compliance_rates.environmental_fee_rates),
    "bdo_reportable": true,
    "ewc_classification_auto": true,
    "_legal_basis": "Ustawa o odpadach, BDO, EWC",
    "_warnings": ["Opłaty środowiskowe: automatyczna kalkulacja per typ odpadu (9 kategorii EWC)"]
} {
    object.get(input.jdg_entrepreneur, "generates_waste", false) == true
}

# ══════ INN12: Regulatory Change Impact Analyzer (priority 12000) ══════
else := {
    "matched": true,
    "rule_id": "jdg.p14.regulatory_change_analyzer",
    "package": "jdg.p14_innovations", "priority": 12000,
    "innovation": "INN12_REGULATORY_CHANGE_ANALYZER",
    "monitored_regulations": [
        "RODO/GDPR — Rozporządzenie 2016/679",
        "AML Act — Ustawa z 01.03.2018",
        "BDO — Ustawa o odpadach",
        "Whistleblower — Ustawa z 14.06.2024",
        "NIS2 — Cybersecurity Directive",
        "DGA — Data Governance Act",
        "AI Act — EU AI Regulation",
    ],
    "impact_analysis": "HIGH/MEDIUM/LOW per regulation change",
    "auto_update": true,
    "_legal_basis": "Monitorowanie zmian regulacyjnych UE/PL",
    "_warnings": ["Zmiany regulacyjne — monitoring 7 kluczowych aktów prawnych. Impact analysis automatyczna."]
} {
    true
}
