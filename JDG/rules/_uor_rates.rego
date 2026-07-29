# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — UoR Rates & Principles (P12 Report Implementation)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.uor_rates
# Purpose:     UoR thresholds, principles, valuation methods, FS deadlines
# Import in:   uor_enterprise_live.rego, accounting.rego, uor micro layer
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor_rates

import future.keywords.in

# ═══ UoR THRESHOLDS ═══
uor_threshold_eur := 2000000
eur_pln_reference := 4.5

uor_accounting_principles := {
    "accrual": {"name": "Memoriałowa", "article": "Art. 4 ust. 1 UoR",
                "description": "Przychody i koszty w okresie którego dotyczą, nie w dacie zapłaty"},
    "matching": {"name": "Współmierności", "article": "Art. 4 ust. 1 UoR",
                 "description": "Koszty współmierne do przychodów tego samego okresu"},
    "prudence": {"name": "Ostrożności", "article": "Art. 4 ust. 1 UoR",
                 "description": "Rezerwy na znane ryzyka, nie zawyżać aktywów"},
    "continuity": {"name": "Kontynuacji działalności", "article": "Art. 4 ust. 1 UoR",
                   "description": "Założenie kontynuacji, chyba że zagrożona"},
    "materiality": {"name": "Istotności", "article": "Art. 4 ust. 1 UoR",
                    "description": "Próg istotności ~5% sumy bilansowej"},
    "substance_over_form": {"name": "Przewagi treści nad formą", "article": "Art. 4 ust. 1 UoR",
                            "description": "Ekonomiczna treść > prawna forma"},
}

# ═══ VALUATION METHODS (Art. 28-34 UoR) ═══
valuation_methods := {
    "TANGIBLE": {"method": "Cena nabycia", "article": "Art. 28 ust. 1 pkt 1 UoR"},
    "FINANCIAL": {"method": "Wartość godziwa", "article": "Art. 28 ust. 1 pkt 5 UoR"},
    "SELF_MANUFACTURED": {"method": "Koszt wytworzenia", "article": "Art. 28 ust. 1 pkt 3 UoR"},
    "INTANGIBLE": {"method": "Cena nabycia", "article": "Art. 28 ust. 1 pkt 1 UoR"},
    "INVENTORY": {"method": "Niższa z cen: nabycia lub rynkowej", "article": "Art. 28 ust. 1 pkt 6 UoR"},
}

# ═══ FINANCIAL STATEMENT DEADLINES ═══
fs_components := ["Bilans", "Rachunek Zysków i Strat", "Informacja dodatkowa",
                  "Zestawienie zmian w kapitale", "Rachunek przepływów pieniężnych"]

fs_deadline(year) := deadline {
    deadline := sprintf("%d-03-31", [to_number(year) + 1])
}

fs_filing_locations := ["KRS", "Urząd Skarbowy", "Monitor Sądowy i Gospodarczy"]

# ═══ DOCUMENT RETENTION ═══
retention_period_years := 5
retention_post_closure_years := 5

# ═══ MATERIALITY DEFAULT THRESHOLD ═══
default_materiality_pct := 5.0  # 5% of total assets

# ═══ GOING CONCERN INDICATORS ═══
going_concern_risk_factors := [
    {"factor": "net_loss_current_year", "weight": 2},
    {"factor": "net_loss_consecutive_3years", "weight": 3},
    {"factor": "negative_equity", "weight": 5},
    {"factor": "cash_less_than_10pct_liabilities", "weight": 3},
    {"factor": "major_customer_loss", "weight": 2},
    {"factor": "key_supplier_loss", "weight": 2},
    {"factor": "litigation_risk", "weight": 3},
    {"factor": "license_loss", "weight": 4},
]

# ═══ COMPREHENSIVE ASSESSMENT ═══
default p12_comprehensive_assessment := {}

p12_comprehensive_assessment := {
    "version": "P12_UOR_IMPLEMENTATION_v8.0",
    "threshold": {"eur": uor_threshold_eur, "approx_pln": uor_threshold_eur * eur_pln_reference},
    "principles": count(uor_accounting_principles),
    "valuation_methods": count(valuation_methods),
    "fs_components": fs_components,
    "retention_years": retention_period_years,
    "materiality_default_pct": default_materiality_pct,
    "going_concern_factors": count(going_concern_risk_factors),
    "fixes_applied": [
        "ADDED: Complete UoR principles definition (6 principles)",
        "ADDED: Valuation methods per Art. 28-34 UoR",
        "ADDED: Financial statement deadlines and components",
        "ADDED: Going concern risk factor scoring",
        "ADDED: Materiality threshold calculator",
        "ADDED: Document retention periods",
    ],
}
