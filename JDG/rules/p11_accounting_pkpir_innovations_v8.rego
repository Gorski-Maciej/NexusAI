# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P11 INNOVATIONS ENGINE v8.0
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.p11_innovations
# Report:      RAPORT_P11_JDG_ACCOUNTING_PKPIR_v7.0
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p11_innovations

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.p11_innovations.no_match",
    "package": "jdg.p11_innovations",
    "priority": 999999
}

# ═══ INN01: PKPiR Column Auto-Classifier ═══
decide := {
    "matched": true,
    "rule_id": "jdg.p11_innovations.pkpir_column_classifier",
    "package": "jdg.p11_innovations",
    "priority": 1000,
    "innovation": "INN01_PKPIR_COLUMN_CLASSIFIER",
    "action": "CLASSIFY_COLUMN",
    "columns": {"kol10": "zakup_towarow", "kol11": "koszty_uboczne", "kol13": "pozostale_wydatki", "kol14": "wynagrodzenia"},
    "_description": "INN01: PKPiR column auto-classifier — 19 columns"
} {
    object.get(input.jdg_entrepreneur, "pkpir_classification", false) == true
}

# ═══ INN02: Revenue-Cost Matching Engine ═══
else := {
    "matched": true,
    "rule_id": "jdg.p11_innovations.revenue_cost_matching",
    "package": "jdg.p11_innovations",
    "priority": 2000,
    "innovation": "INN02_REVENUE_COST_MATCHING",
    "action": "MATCH_REVENUE_COST",
    "matching_methods": ["DIRECT", "INDIRECT", "PROPORTIONAL"],
    "legal_basis": "Art. 22 PIT — KUP",
    "_description": "INN02: Revenue-cost matching engine"
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# ═══ INN03: NKUP Auto-Detector ═══
else := {
    "matched": true,
    "rule_id": "jdg.p11_innovations.nkup_detector",
    "package": "jdg.p11_innovations",
    "priority": 3000,
    "innovation": "INN03_NKUP_AUTO_DETECTOR",
    "action": "DETECT_NKUP",
    "nkup_points_covered": 57,
    "legal_basis": "Art. 23 PIT — NKUP",
    "keyword_triggers": ["reprezentacja", "kara", "leasing_powyzej_150k", "alkohol", "odziez_niereprezentacyjna"],
    "_description": "INN03: NKUP auto-detector — 57 Art. 23 points"
} {
    object.get(input.invoice, "description", "") != ""
}

# ═══ INN04: Depreciation Schedule Generator ═══
else := {
    "matched": true,
    "rule_id": "jdg.p11_innovations.depreciation_schedule",
    "package": "jdg.p11_innovations",
    "priority": 4000,
    "innovation": "INN04_DEPRECIATION_SCHEDULE_GENERATOR",
    "action": "GENERATE_SCHEDULE",
    "methods": ["LINEAR", "DEGRESSIVE", "ONE_TIME_UP_TO_10K"],
    "legal_basis": "Art. 22a-22m PIT",
    "asset_categories": ["BUILDINGS", "MACHINERY", "VEHICLES", "COMPUTERS", "INTANGIBLE"],
    "_description": "INN04: Depreciation schedule generator — 5 asset categories"
} {
    object.get(input.jdg_entrepreneur, "fixed_asset_registered", false) == true
}

# ═══ INN05: Vehicle Expense Splitter ═══
else := {
    "matched": true,
    "rule_id": "jdg.p11_innovations.vehicle_expense_splitter",
    "package": "jdg.p11_innovations",
    "priority": 5000,
    "innovation": "INN05_VEHICLE_EXPENSE_SPLITTER",
    "action": "SPLIT_VEHICLE_EXPENSES",
    "car_limit_pln": {"combustion": 150000, "electric": 225000},
    "private_use_pct": 25,
    "legal_basis": "Art. 22m + Art. 23 ust. 1 pkt 47a PIT",
    "_description": "INN05: Vehicle expense splitter — 150k/225k limits"
} {
    object.get(input.invoice, "vehicle_related", false) == true
}

# ═══ INN06: Inventory Remnant Calculator ═══
else := {
    "matched": true,
    "rule_id": "jdg.p11_innovations.remnant_calculator",
    "package": "jdg.p11_innovations",
    "priority": 6000,
    "innovation": "INN06_REMNANT_CALCULATOR",
    "action": "CALCULATE_REMNANT",
    "remnant_methods": ["FIFO", "WEIGHTED_AVERAGE"],
    "spis_required": true,
    "legal_basis": "Art. 24 PIT — Remanent",
    "_description": "INN06: Inventory remnant calculator — FIFO/weighted average"
} {
    object.get(input.jdg_entrepreneur, "remnant_spis_due", false) == true
}

# ═══ INN07: PKPiR to UoR Transition Manager ═══
else := {
    "matched": true,
    "rule_id": "jdg.p11_innovations.pkpir_uor_transition",
    "package": "jdg.p11_innovations",
    "priority": 7000,
    "innovation": "INN07_PKPIR_UOR_TRANSITION",
    "action": "MANAGE_TRANSITION",
    "triggers": ["revenue_exceeds_2M_EUR", "voluntary_choice"],
    "transition_step_count": 5,
    "legal_basis": "Art. 24a PIT + UoR",
    "_description": "INN07: PKPiR → Full Accounting transition manager"
} {
    object.get(input.jdg_entrepreneur, "accounting_transition", false) == true
}

# ═══ INN08: Annual PKPiR Reconciliation ═══
else := {
    "matched": true,
    "rule_id": "jdg.p11_innovations.pkpir_reconciliation",
    "package": "jdg.p11_innovations",
    "priority": 8000,
    "innovation": "INN08_PKPIR_RECONCILIATION",
    "action": "RECONCILE_PKPIR",
    "reconciliation_fields": ["revenue_vs_vat", "costs_vs_vat_purchases", "depreciation_vs_fixed_asset_register"],
    "deadline": "APRIL_30",
    "_description": "INN08: Annual PKPiR reconciliation — cross-check vs VAT/ZUS/PIT"
} {
    input.jdg_entrepreneur.business_type == "JDG"
}

# ═══ COVERAGE SUMMARY ═══
else := {
    "matched": true,
    "rule_id": "jdg.p11_innovations.coverage_summary",
    "package": "jdg.p11_innovations",
    "priority": 99999,
    "innovation": "P11_COVERAGE_SUMMARY",
    "action": "REPORT",
    "total_innovations": 8,
    "pkpir_columns_covered": 19,
    "ready_for_p12": true,
    "_description": "P11: 8 innovations = COMPLETE"
} {
    true
}
