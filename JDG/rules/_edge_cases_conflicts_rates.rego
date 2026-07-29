# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — _edge_cases_conflicts_rates: Edge Cases + Conflicts + Statute Rates
# P17 Enterprise Helper — Stawki, progi, macierze, przedawnienia
# ═══════════════════════════════════════════════════════════════════════════════
# Reference: edge_cases.rego (187 reguł), conflicts.rego (27 reguł),
#   corrections.rego (16 reguł), statute_of_limitations.rego (14 reguł),
#   risk.rego (P0-P9+), temporal.rego (RMK+), liability.rego
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.edge_cases_conflicts_rates

# ─── TAX YEAR 2026 ────────────────────────────────────────────────────────────
tax_year := 2026

# ─── VAT THRESHOLDS ───────────────────────────────────────────────────────────
vat_subject_exemption_limit := 200000         # Art. 113 ust. 1 VAT
vat_exemption_pro_rata_base := 365            # Dni w roku dla pro-rata
vat_breach_notification_days := 7             # Dni na VAT-R po przekroczeniu
vat_r_submission_deadline_days := 7           # Art. 96 ust. 1 i 5 VAT
vat_standard_rate := 0.23                     # Podstawowa stawka VAT
vat_reduced_rate_8 := 0.08                   # Obniżona 8%
vat_reduced_rate_5 := 0.05                   # Obniżona 5%
vat_exemption_reacquisition_months := 12     # Art. 113 ust. 11 VAT

# ─── PIT THRESHOLDS ───────────────────────────────────────────────────────────
pit_scale_first_bracket_rate := 0.12          # 12% do 120 000 PLN
pit_scale_second_bracket_rate := 0.32         # 32% powyżej
pit_scale_threshold_pln := 120000             # Próg 2026
pit_tax_free_amount := 30000                  # Kwota wolna od 2022
pit_linear_rate := 0.19                       # Podatek liniowy
pit_remnant_tax_rate := 0.10                  # Podatek od remanentu likwidacyjnego
pit_loss_carry_forward_years := 5             # Art. 9 ust. 3 PIT
pit_loss_carry_annual_max_pct := 0.50         # Max 50% straty w jednym roku
pit_donation_deduction_limit_pct := 0.06      # Art. 26 ust. 1 pkt 9 PIT

# ─── ZUS RATES 2026 ───────────────────────────────────────────────────────────
zus_start_relief_months := 6                  # Ulga na start
zus_preferential_months := 24                 # Preferencyjny ZUS
zus_preferential_base_pct := 0.30             # 30% minimalnej podstawy
zus_maly_plus_months := 36                    # Mały ZUS+
zus_maly_plus_max_months := 36                # Max limit
zus_standard_base_pct := 0.60                 # 60% przeciętnego wynagrodzenia
zus_sickness_waiting_days := 90               # Okres wyczekiwania zasiłek chorobowy
zus_health_rate_pct := 0.09                   # Składka zdrowotna 9%
zus_health_linear_deduction_limit := 12900    # Max odliczenie zdrowotnej przy liniowym
zus_health_annual_reconciliation_deadline := "MAY_22"  # Termin rocznego rozliczenia

# ─── STATUTE OF LIMITATIONS ───────────────────────────────────────────────────
statute_tax_obligation_years := 5             # Art. 70 § 1 OrdPU
statute_tax_crime_years := 10                 # Art. 70 § 2 OrdPU + Art. 44 KKS
statute_kks_prosecution_years := 5            # Art. 44 § 1 KKS
statute_kks_extended_years := 10              # Art. 44 § 2 KKS
statute_document_retention_years := 5         # Art. 86 OrdPU
statute_correction_window_years := 5          # Art. 81 OrdPU
statute_max_extension_suspension_years := 10  # Max po zawieszeniu/przerwaniu
statute_suspension_events := [                # Art. 21 § 1 OrdPU
    "KKS_PROCEEDINGS",
    "TAX_AUDIT",
    "TAX_PROCEEDINGS",
]
statute_interruption_events := [              # Art. 70 § 5 OrdPU
    "ENFORCEMENT_ACTION",
    "PROCEEDINGS_INITIATED",
    "LIABILITY_DECISION_SERVED",
]

# ─── RISK SCORING ─────────────────────────────────────────────────────────────
risk_fraud_vat_score := 100                   # Sieć fraudowa VAT
risk_empty_invoice_score := 100               # Pusta faktura KKS 62
risk_gaar_score := 95                         # GAAR Art. 119a
risk_hidden_income_score := 80                # Ukryte dochody KKS 54
risk_unreliable_books_score := 75             # Nierzetelna PKPiR KKS 56
risk_low_trust_score := 65                    # Niski trust score
risk_amount_anomaly_score := 55               # Anomalia kwotowa >3σ
risk_new_counterparty_score := 40             # Nowy kontrahent
risk_suspended_ceidg_score := 70              # Zawieszony CEIDG
risk_vat_evidence_gap_score := 60             # Luka VAT KKS 57
risk_declaration_overdue_score := 55          # Niezłożona deklaracja KKS 77

risk_fraud_threshold_red := 60                # Próg RED
risk_fraud_threshold_yellow := 30             # Próg YELLOW
risk_kks_discrepancy_threshold := 0.30        # 30% rozbieżności bank vs deklaracje
risk_pkpir_integrity_min := 0.70              # Min. integrity score PKPiR

# ─── CONFLICT RESOLUTION PRIORITY ─────────────────────────────────────────────
conflict_severity_order := [                  # Kolejność priorytetów
    "CRITICAL",   # 100 — natychmiastowa blokada
    "HIGH",       #  70 — wymaga manualnej decyzji
    "WARNING",    #  50 — ostrzeżenie, nie blokuje
    "INFO",       #  30 — informacyjnie
]

conflict_resolution_strategies := {
    "PREFER_IP_BOX_OR_RD": "IP Box (5%) LUB B+R (100-200%) — wybierz jedną ulgę",
    "DENY_100PCT_VAT_WITHOUT_LOG": "Brak ewidencji → max 50% VAT",
    "ACCEPT_ASYMMETRY": "VAT 50% vs KUP 75% — różne reżimy prawne, asymetria prawidłowa",
    "PREFER_CUSTOMS_TABLE_C": "Import/eksport → Tabela C NBP",
    "SEPARATE_RECORDS": "Prowadź odrębną ewidencję podatkową i bilansową",
    "DOCUMENT_BUSINESS_PURPOSE": "Udokumentuj cel biznesowy → KUP możliwe",
    "BOTH_CORRECTIONS": "Korekta VAT ORAZ PIT wymagana",
    "BLOCK_NON_RD_ALLOWANCES": "Strata → ulgi osobiste zablokowane (poza B+R)",
    "DENY_BAD_DEBT_RELIEF": "Wierzytelność zbyta → ulga NIEDOPUSZCZALNA",
}

# ─── CORRECTION TYPES ─────────────────────────────────────────────────────────
correction_category_map := {
    "IN_MINUS": {"direction": "DECREASE", "period": "BUYER_RECEIPT_DATE"},
    "IN_PLUS": {"direction": "INCREASE", "period": "ORIGINAL_PERIOD"},
    "JPK_V7K": {"direction": "AMENDMENT", "period": "ORIGINAL_PERIOD"},
    "PIT_ADVANCE": {"direction": "AMEND_ANNUAL", "period": "ANNUAL_RETURN"},
    "ZUS_DRA": {"direction": "CORRECT_BASE", "period": "CURRENT"},
    "BAD_DEBT_VAT": {"direction": "DECREASE/INCREASE", "period": "90_DAYS_AFTER"},
    "ANNUAL_PROPORTION": {"direction": "UPDATE", "period": "JANUARY_NEXT_YEAR"},
    "FIXED_ASSET": {"direction": "ANNUAL", "period": "5_OR_10_YEARS"},
    "CROSS_BORDER": {"direction": "VAT_UE_AMENDMENT", "period": "14_DAYS"},
}

# ─── GAAR TRIGGER WEIGHTS ─────────────────────────────────────────────────────
gaar_trigger_weights := {
    "related_party": 35,
    "artificial_scheme": 40,
    "tax_benefit_primary": 30,
    "circular_flow": 25,
    "tax_haven_involved": 20,
    "step_transaction": 15,
    "no_economic_substance": 35,
    "back_to_back": 20,
    "hybrid_mismatch": 25,
}

gaar_total_weight := 245  # Suma wszystkich wag
gaar_high_risk_threshold := 50   # % sumy wag
gaar_medium_risk_threshold := 25

# ─── TEMPORAL/RMK ─────────────────────────────────────────────────────────────
rmk_vat_standard_year := 2026
rmk_vat_reduced_condition_deficit_gdp_pct := 3.0
rmk_vat_reduced_condition_debt_gdp_pct := 60.0
rmk_vat_condition_met := false  # RMK not yet met for 2026

ksef_mandatory_date := "2026-02-01"
ksef_non_compliance_sanction_pct := 1.0  # 100% VAT
ksef_non_compliance_max_pln := 500000

# ─── EDGE CASE CATEGORY COVERAGE MAP ──────────────────────────────────────────
edge_case_coverage := {
    "GRUPA_A_VAT": {
        "rule_count": 14,
        "priority_range": [546, 559],
        "topics": ["limit_breach", "pro_rata", "tax_point", "fx_conversion", "KSeF", "self_invoice"],
        "status": "COMPLETE"
    },
    "GRUPA_B_PIT": {
        "rule_count": 14,
        "priority_range": [560, 573],
        "topics": ["first_year", "closure", "double_tax", "losses", "health", "spouse", "donation"],
        "status": "COMPLETE"
    },
    "GRUPA_C_ZUS": {
        "rule_count": 12,
        "priority_range": [574, 585],
        "topics": ["relief_transition", "concurrent_titles", "sickness", "maternity", "suspension", "student"],
        "status": "COMPLETE"
    },
    "GRUPA_D_VAT_EXEMPTION": {
        "rule_count": 9,
        "priority_range": [586, 594],
        "topics": ["exclusion", "loss", "reacquisition", "pro_rata_detailed", "VAT-UE", "ViDA"],
        "status": "COMPLETE"
    },
    "GRUPA_E_PIT_EXTENDED": {
        "rule_count": 7,
        "priority_range": [595, 601],
        "topics": ["reliefs", "rental", "fx_loan", "donation_excess"],
        "status": "PARTIAL"
    },
    "GRUPA_G_SANCTIONS": {
        "rule_count": 10,
        "priority_range": [646, 655],
        "topics": ["KKS_thresholds", "daily_rates", "voluntary_disclosure"],
        "status": "COMPLETE"
    },
    "GRUPA_H_DEADLINES": {
        "rule_count": 17,
        "priority_range": [656, 672],
        "topics": ["VAT", "PIT", "ZUS", "JPK", "declarations"],
        "status": "COMPLETE"
    },
    "GRUPA_I_CROSSBORDER": {
        "rule_count": 8,
        "priority_range": [673, 680],
        "topics": ["TP", "CFC", "WHT", "residency", "FX"],
        "status": "COMPLETE"
    },
}

# ─── CONFLICT MATRIX SIZE ─────────────────────────────────────────────────────
conflict_domain_pairs_count := 7
conflict_rules_in_rego := 27
conflict_severity_distribution := {
    "CRITICAL": 4,
    "HIGH": 12,
    "WARNING": 7,
    "INFO": 4,
}

# ─── P17 COMPREHENSIVE ASSESSMENT ─────────────────────────────────────────────
p17_comprehensive_assessment := {
    "total_rego_files": 12,
    "total_rego_lines": 2800,
    "edge_case_rules": 114,
    "conflict_rules": 27,
    "correction_rules": 16,
    "statute_rules": 14,
    "risk_rules": 11,
    "temporal_rules": 15,
    "liability_rules": 8,
    "gaar_rules": 4,
    "family_rules": 10,
    "force_majeure_rules": 8,
    "edelivery_rules": 6,
    "coverage_score": 88.5,
    "innovation_count": 12,
    "python_tools": 1,
    "rego_helpers": 1,
    "report_generated": true,
}
