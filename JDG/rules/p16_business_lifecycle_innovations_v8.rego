# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P16 BUSINESS LIFECYCLE INNOVATIONS v8.0
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.p16_innovations
# Report:      RAPORT_P16_BUSINESS_LIFECYCLE_TOOLKIT_v1.0
# Innovations: 12 — Lifecycle, ZUS reliefs, succession, exit strategies
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p16_innovations

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.p16_innovations.no_match",
    "package": "jdg.p16_innovations",
    "priority": 999999
}

# ═══ INN01: JDG Lifecycle AI Navigator ═══
decide := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.lifecycle_navigator",
    "package": "jdg.p16_innovations",
    "priority": 1000,
    "innovation": "INN01_LIFECYCLE_NAVIGATOR",
    "action": "NAVIGATE_LIFECYCLE",
    "phases": ["PRE_START", "STARTUP_RELIEF", "STARTUP_PREFERENTIAL", "EARLY_GROWTH", "GROWTH", "MATURITY", "SUSPENDED", "SUCCESSION", "CLOSURE"],
    "zus_relief_timeline": {"START_RELIEF": 6, "PREFERENTIAL": 24, "MALY_ZUS_PLUS": 36},
    "legal_basis": "Prawo Przedsiębiorców, SUS, CEIDG",
    "_description": "INN01: Navigate JDG through 9 lifecycle phases with ZUS relief timeline"
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# ═══ INN02: Business Form Auto-Selector ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.tax_form_selector",
    "package": "jdg.p16_innovations",
    "priority": 2000,
    "innovation": "INN02_TAX_FORM_SELECTOR",
    "action": "SELECT_TAX_FORM",
    "forms_compared": ["PIT_SCALE (12%/32%)", "LINEAR (19%)", "LUMP_SUM (2-17%)"],
    "optimization_criteria": ["annual_profit", "cost_structure", "industry_type"],
    "legal_basis": "Art. 9a, 27, 30c PIT",
    "_description": "INN02: Auto-select optimal tax form — scale vs linear vs lump sum"
} {
    object.get(input.jdg_entrepreneur, "tax_form_optimization", false) == true
}

# ═══ INN03: Suspension Impact Simulator ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.suspension_simulator",
    "package": "jdg.p16_innovations",
    "priority": 3000,
    "innovation": "INN03_SUSPENSION_SIMULATOR",
    "action": "SIMULATE_SUSPENSION",
    "max_months": 6,
    "health_insurance_due": true,
    "employee_blocker": true,
    "legal_basis": "Art. 22-25 Prawa Przedsiębiorców, Art. 36a SUS",
    "_description": "INN03: Simulate suspension impact — financial, ZUS, health insurance"
} {
    object.get(input.jdg_entrepreneur, "suspension_planned", false) == true
}

# ═══ INN04: Succession Readiness Score ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.succession_readiness",
    "package": "jdg.p16_innovations",
    "priority": 4000,
    "innovation": "INN04_SUCCESSION_READINESS",
    "action": "SCORE_SUCCESSION",
    "score_factors": ["zarządca powołany", "zgoda zarządcy", "wpis CEIDG", "plan sukcesyjny", "czas pozostały"],
    "max_score": 100,
    "readiness_threshold": 70,
    "legal_basis": "Art. 3-15, 49 Ustawy o zarządzie sukcesyjnym",
    "_description": "INN04: Score succession readiness — 5 factors, 70/100 threshold"
} {
    object.get(input.jdg_entrepreneur, "succession_planning", false) == true
}

# ═══ INN05: Gig Economy Tax Optimizer ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.gig_economy_optimizer",
    "package": "jdg.p16_innovations",
    "priority": 5000,
    "innovation": "INN05_GIG_ECONOMY_OPTIMIZER",
    "action": "OPTIMIZE_GIG_TAXES",
    "platforms_supported": ["UBER", "BOLT", "GLOVO", "WOLT"],
    "tax_forms": {"TRANSPORT": "8.5% ryczałt", "DELIVERY": "3% ryczałt"},
    "mileage_log_boost": "+25% KUP, +50% VAT",
    "legal_basis": "Art. 12-14 PIT (ryczałt), Art. 86a VAT (pojazdy)",
    "_description": "INN05: Optimize gig economy taxes — platform-specific rates + mileage log booster"
} {
    object.get(input.jdg_entrepreneur, "gig_economy_worker", false) == true
}

# ═══ INN06: Banking Multi-API Aggregator ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.banking_api_aggregator",
    "package": "jdg.p16_innovations",
    "priority": 6000,
    "innovation": "INN06_BANKING_API_AGGREGATOR",
    "action": "AGGREGATE_BANKING",
    "supported_banks": ["mBank", "ING", "PKO BP", "PEKAO", "Santander"],
    "api_standard": "PolishAPI v3.x",
    "psd2_services": ["AIS", "PIS"],
    "legal_basis": "PSD2 (EU 2015/2366), PolishAPI, eIDAS",
    "_description": "INN06: Multi-bank API aggregator — PSD2/PolishAPI for 5 major Polish banks"
} {
    object.get(input.jdg_entrepreneur, "bank_integration_required", false) == true
}

# ═══ INN07: CEIDG Auto-File Engine ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.ceidg_auto_file",
    "package": "jdg.p16_innovations",
    "priority": 7000,
    "innovation": "INN07_CEIDG_AUTO_FILE",
    "action": "FILE_CEIDG",
    "form": "CEIDG-1",
    "zus_deadline_days": 7,
    "required_fields": ["first_name", "last_name", "pesel", "pkd_main", "tax_form"],
    "legal_basis": "Art. 5-7 Ustawy o CEIDG, Prawo Przedsiębiorców",
    "_description": "INN07: Auto-fill CEIDG-1 registration — PKD, tax form, ZUS ZUA"
} {
    object.get(input.jdg_entrepreneur, "ceidg_registration", false) == true
}

# ═══ INN08: Business Health 360 Dashboard ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.health_dashboard",
    "package": "jdg.p16_innovations",
    "priority": 8000,
    "innovation": "INN08_HEALTH_360_DASHBOARD",
    "action": "ASSESS_HEALTH",
    "metrics": ["compliance_score", "financial_liquidity", "emergency_fund", "profitability", "risk_flags"],
    "health_tiers": ["CRITICAL", "WARNING", "GOOD", "EXCELLENT"],
    "legal_basis": "UoR, Prawo Przedsiębiorców, CEIDG",
    "_description": "INN08: 360° business health dashboard — 5 metrics, 4 tiers"
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# ═══ INN09: Exit Strategy Multi-Scenario Simulator ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.exit_strategy_simulator",
    "package": "jdg.p16_innovations",
    "priority": 9000,
    "innovation": "INN09_EXIT_STRATEGY_SIMULATOR",
    "action": "SIMULATE_EXIT",
    "scenarios": ["VOLUNTARY_CLOSURE (10 steps)", "SUCCESSION (13 steps)", "BUSINESS_SALE (8 steps)", "TRANSFORMATION (12 steps)"],
    "tax_implications": {"remnant_tax": "10%", "vat_on_inventory": "23%", "transformation": "0% (aport)"},
    "legal_basis": "Art. 24 PIT (remanent), Ustawa o zarządzie sukcesyjnym, KSH (przekształcenie)",
    "_description": "INN09: Simulate 4 exit strategy scenarios — closure, succession, sale, transformation"
} {
    object.get(input.jdg_entrepreneur, "exit_planning", false) == true
}

# ═══ INN10: Growth Phase Revenue Predictor ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.revenue_predictor",
    "package": "jdg.p16_innovations",
    "priority": 10000,
    "innovation": "INN10_REVENUE_PREDICTOR",
    "action": "PREDICT_REVENUE",
    "model_factors": ["historical_trend", "seasonality", "industry_growth", "vat_registration_impact"],
    "vat_threshold_warning": true,
    "zus_threshold_warning": true,
    "legal_basis": "Art. 113 Ustawy o VAT, Art. 27 PIT, Art. 18a SUS",
    "_description": "INN10: Predict revenue growth — VAT/ZUS threshold warnings"
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# ═══ INN11: Employee Hiring Auto-Procedure ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.employee_hiring_procedure",
    "package": "jdg.p16_innovations",
    "priority": 11000,
    "innovation": "INN11_EMPLOYEE_HIRING",
    "action": "HIRE_EMPLOYEE",
    "steps": ["umowa o pracę", "ZUS ZUA (7 dni)", "szkolenie BHP", "badania lekarskie", "PPK (opcjonalnie)"],
    "employer_costs_pct": 20.5,
    "ppk_employer_pct": 1.5,
    "legal_basis": "Kodeks Pracy, SUS, PPK",
    "_description": "INN11: Employee hiring auto-procedure — 5 steps, employer cost calculator"
} {
    object.get(input.jdg_entrepreneur, "hiring_employee", false) == true
}

# ═══ INN12: Company Transformation Engine (JDG→Sp. z o.o.→SA) ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.company_transformation",
    "package": "jdg.p16_innovations",
    "priority": 12000,
    "innovation": "INN12_COMPANY_TRANSFORMATION",
    "action": "TRANSFORM_COMPANY",
    "transformations": ["JDG→Sp. z o.o. (aport)", "Sp. z o.o.→SA", "CIT estoński opcja"],
    "tax_benefits": {"aport": "0% PIT przy przekształceniu", "cit_estonski": "odroczony do wypłaty dywidendy"},
    "legal_basis": "KSH, Kodeks Cywilny, PIT, CIT",
    "_description": "INN12: JDG→Sp. z o.o.→SA transformation engine — tax-neutral aport + CIT estoński"
} {
    object.get(input.jdg_entrepreneur, "company_transformation_planned", false) == true
}

# ═══ COVERAGE SUMMARY ═══
else := {
    "matched": true,
    "rule_id": "jdg.p16_innovations.coverage_summary",
    "package": "jdg.p16_innovations",
    "priority": 99999,
    "innovation": "P16_COVERAGE_SUMMARY",
    "action": "REPORT",
    "total_innovations": 12,
    "domains_covered": ["lifecycle", "tax_form_optimization", "suspension", "succession", "gig_economy", "banking", "ceidg", "health", "exit", "growth", "hiring", "transformation"],
    "ready_for_p17": true,
    "_description": "P16: 12 innovations = COMPLETE — Full business lifecycle coverage"
} {
    true
}
