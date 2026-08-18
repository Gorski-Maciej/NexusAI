# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Compliance + RODO + AML + BDO Rates (P14 Report Implementation)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.compliance_rates
# Purpose:     GDPR fines, AML thresholds, BDO EWC codes, environmental rates
# Import in:   compliance.rego, rodo.rego, rodo_extended.rego, bdo_enterprise.rego
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.compliance_rates

import future.keywords.in

# ═══ GDPR FINES ═══
gdpr_fines := {
    "tier1": {"max_eur": 10000000, "max_pct_revenue": 2, "articles": ["Art. 8, 11, 25-39, 42, 43 RODO"]},
    "tier2": {"max_eur": 20000000, "max_pct_revenue": 4, "articles": ["Art. 5, 6, 7, 9, 12-22, 44-49 RODO"]},
    "max_fine": "20 000 000 EUR lub 4% rocznego obrotu",
}

gdpr_obligations := {
    "data_inventory": {"article": "Art. 30", "name": "Rejestr czynności przetwarzania"},
    "consent": {"article": "Art. 7", "name": "Zgoda na przetwarzanie"},
    "erasure": {"article": "Art. 17", "name": "Prawo do usunięcia", "deadline_days": 30},
    "breach_notification": {"article": "Art. 33", "name": "Zgłoszenie naruszenia", "deadline_hours": 72},
    "dpo": {"article": "Art. 37", "name": "Inspektor Ochrony Danych"},
    "processor_agreement": {"article": "Art. 28", "name": "Umowa powierzenia"},
    "privacy_by_design": {"article": "Art. 25", "name": "Privacy by Design & Default"},
}

# ═══ AML THRESHOLDS ═══
aml_thresholds := {
    "cash_eur": 15000,
    "str_required": true,
    "cdd_required": true,
    "edd_required": false,
    "report_to": "GIIF (Generalny Inspektor Informacji Finansowej)",
    "legal_basis": "AML Act — Art. 9b-9f, 34-43",
}

aml_risk_factors := [
    {"factor": "high_risk_jurisdiction", "weight": 3},
    {"factor": "pep", "weight": 4},
    {"factor": "cash_over_15k_eur", "weight": 2},
    {"factor": "unusual_pattern", "weight": 3},
    {"factor": "sanctions_list", "weight": 5},
]

# ═══ BDO — EWC CODES ═══
ewc_codes := {
    "paper": {"code": "20 01 01", "name": "Papier i tektura", "hazardous": false},
    "plastic": {"code": "20 01 39", "name": "Tworzywa sztuczne", "hazardous": false},
    "metal": {"code": "20 01 40", "name": "Metale", "hazardous": false},
    "glass": {"code": "20 01 02", "name": "Szkło", "hazardous": false},
    "organic": {"code": "20 01 08", "name": "Odpady biodegradowalne", "hazardous": false},
    "electronic": {"code": "20 01 36", "name": "Zużyte urządzenia elektryczne", "hazardous": false},
    "batteries": {"code": "20 01 34", "name": "Baterie i akumulatory", "hazardous": false},
    "hazardous": {"code": "20 01 27*", "name": "Odpady niebezpieczne", "hazardous": true},
    "mixed": {"code": "20 03 01", "name": "Odpady zmieszane", "hazardous": false},
}

bdo_max_fine_pln := 1000000

# ═══ ENVIRONMENTAL FEES ═══
environmental_fee_rates := {
    "paper": 0.05,
    "plastic": 0.20,
    "metal": 0.10,
    "glass": 0.03,
    "organic": 0.02,
    "electronic": 0.50,
    "batteries": 1.00,
    "hazardous": 5.00,
    "mixed": 0.15,
}

# ═══ WHITELIST VAT ═══
whitelist_threshold_pln := 15000
whitelist_check_required := true

# ═══ COMPREHENSIVE ═══
default p14_comprehensive_assessment := {}

p14_comprehensive_assessment := {
    "version": "P14_COMPLIANCE_IMPLEMENTATION_v8.0",
    "gdpr_obligations": count(gdpr_obligations),
    "gdpr_max_fine": gdpr_fines.max_fine,
    "aml_cash_threshold_eur": aml_thresholds.cash_eur,
    "bdo_ewc_codes": count(ewc_codes),
    "bdo_max_fine_pln": bdo_max_fine_pln,
    "env_fee_categories": count(environmental_fee_rates),
    "whitelist_threshold_pln": whitelist_threshold_pln,
    "fixes_applied": [
        "ADDED: Complete GDPR fines structure (Tier 1 & 2)",
        "ADDED: All 7 GDPR obligations with deadlines",
        "ADDED: AML cash threshold (15k EUR) + risk factors",
        "ADDED: BDO EWC codes (9 categories)",
        "ADDED: Environmental fee rates per waste type",
        "ADDED: VAT Whitelist threshold (15k PLN)",
    ],
}
