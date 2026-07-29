# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Cross-Border + MDR + Exit Tax Rates (P13 Report Implementation)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.crossborder_rates
# Purpose:     Cross-border VAT rules, MDR hallmarks, Exit Tax thresholds
# Import in:   crossborder.rego, mdr_enterprise.rego, mdr_dac6_enterprise.rego
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.crossborder_rates

import future.keywords.in

# ═══ CROSS-BORDER VAT RULES ═══
wnt_rules := {
    "conditions": [
        "Nabywca jest podatnikiem VAT",
        "Sprzedawca jest podatnikiem VAT w kraju UE",
        "Towar jest transportowany z kraju UE do Polski",
    ],
    "vat_rate": 0.23,
    "deductible": true,
    "legal_basis": "Art. 9-11 Ustawy o VAT",
}

wdt_rules := {
    "conditions": [
        "Nabywca jest podatnikiem VAT w kraju UE",
        "Towar jest transportowany z Polski do kraju UE",
        "Dokumentacja: faktura + dowód wywozu w ciągu 30 dni",
    ],
    "rate": "0%",
    "documentation_required": true,
    "deadline_days": 30,
    "legal_basis": "Art. 13 Ustawy o VAT",
}

# ═══ MDR/DAC6 HALLMARKS ═══
mdr_hallmarks := {
    "A": {"name": "Korzyść podatkowa jako główny cel", "indicators": ["tax_saving_primary", "standardized_scheme", "confidentiality_clause"]},
    "B": {"name": "Transakcje bez ekonomicznej substancji", "indicators": ["loss_acquisition", "circular", "no_substance"]},
    "C": {"name": "Transgraniczne między podmiotami powiązanymi", "indicators": ["cross_border_related", "tax_haven", "no_jurisdiction"]},
    "D": {"name": "Obejście automatycznej wymiany informacji", "indicators": ["crs_avoidance", "fatca_bypass", "non_reporting"]},
    "E": {"name": "Ceny transferowe", "indicators": ["tp_risk", "profit_allocation", "hard_to_value"]},
}

mdr_report_deadline_days := 30
mdr_report_to := "Szef Krajowej Administracji Skarbowej (formularz MDR-1)"

# ═══ EXIT TAX THRESHOLDS ═══
exit_tax := {
    "threshold_pln": 4000000,
    "rate_pct": 19,
    "trigger": "Zmiana rezydencji podatkowej lub transfer aktywów za granicę",
    "installments": {"allowed": true, "max_years": 5, "interest": "odsetki od zaległości podatkowych"},
    "legal_basis": "Art. 30da-30db PIT",
}

# ═══ CFC RULES ═══
cfc_thresholds := {
    "ownership_min_pct": 50,
    "passive_income_threshold_pct": 33,
    "tax_rate_threshold_pct": 14.25,
    "legal_basis": "Art. 30f PIT — CFC",
}

# ═══ TRANSFER PRICING ═══
tp_thresholds := {
    "local_file_pln": 500000,
    "master_file_pln": 200000000,
    "deadline": "10 miesięcy po zakończeniu roku podatkowego",
    "legal_basis": "Art. 23zf PIT (od 2024)",
}

# ═══ BREXIT ═══
brexit_rules := {
    "effective_date": "2021-01-01",
    "uk_status": "Państwo trzecie (poza UE)",
    "vat_treatment": "Import/Export (procedura celna)",
    "customs_required": true,
    "eori_required": true,
    "tariff": "TCA — zerowe cła na towary pochodzące z UK/UE",
    "legal_basis": "EU-UK Trade and Cooperation Agreement 2021",
}

# ═══ COMPREHENSIVE ═══
default p13_comprehensive_assessment := {}

p13_comprehensive_assessment := {
    "version": "P13_CROSSBORDER_IMPLEMENTATION_v8.0",
    "mdr_hallmarks": count(mdr_hallmarks),
    "exit_tax_threshold_pln": exit_tax.threshold_pln,
    "cfc_ownership_min": cfc_thresholds.ownership_min_pct,
    "tp_local_file_threshold": tp_thresholds.local_file_pln,
    "brexit_effective": brexit_rules.effective_date,
    "fixes_applied": [
        "ADDED: Complete WNT/WDT rules",
        "ADDED: All 5 MDR/DAC6 hallmarks (A-E)",
        "ADDED: Exit Tax thresholds and installment rules",
        "ADDED: CFC rules (50% ownership, 33% passive income)",
        "ADDED: Transfer pricing documentation thresholds",
        "ADDED: Brexit trade rules (UK as third country)",
    ],
}
