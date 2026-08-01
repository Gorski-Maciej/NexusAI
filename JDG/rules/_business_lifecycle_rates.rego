# ═══════════════════════════════════════════════════════════════════════════════
# _business_lifecycle_rates.rego — P16 Business Lifecycle Rates Helper
# ═══════════════════════════════════════════════════════════════════════════════
#
# Import as: data.jdg.business_lifecycle_rates
# Package: jdg.business_lifecycle_rates
#
# Zawiera:
#   - 5 faz cyklu życia JDG + timeline
#   - ZUS relief timeline (ulga na start, preferencyjny, mały ZUS+, standardowy)
#   - Progi transformacji (VAT 200k, KSeF, pierwszy pracownik)
#   - Porównanie form opodatkowania (skala/liniowy/ryczałt/karta)
#   - Procedura zamknięcia JDG — checklista 10 kroków
#   - Sukcesja — terminy i wymogi
#   - Gig economy — stawki platform
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.business_lifecycle_rates

min_wage_2026 := 4666.00

# ═══════════════════════════════════════════════════════════════════════════════
# Fazy Cyklu Życia JDG
# ═══════════════════════════════════════════════════════════════════════════════

lifecycle_phases := {
    "PRE_START": {
        "months_start": -1, "months_end": 0,
        "zus_status": "NONE",
        "key_actions": ["CEIDG-1", "ZUS ZUA 7d", "rachunek firmowy", "wybór formy PIT"],
        "legal_basis": "Art. 5-7 CEIDG, Art. 43 SUS"
    },
    "STARTUP_RELIEF": {
        "months_start": 0, "months_end": 6,
        "zus_status": "START_RELIEF",
        "zus_social_pct": 0,
        "key_actions": ["Ulga na start 0 PLN ZUS społeczne", "Zdrowotna pełna", "Brak zaliczek PIT przez 1. miesiąc"],
        "legal_basis": "Art. 18a SUS"
    },
    "STARTUP_PREFERENTIAL": {
        "months_start": 6, "months_end": 30,
        "zus_status": "PREFERENTIAL",
        "zus_social_pct": 30,
        "key_actions": ["Preferencyjny ZUS 30% podstawy", "Max 24 mies.", "Po tym: standardowy ZUS"],
        "legal_basis": "Art. 18c SUS"
    },
    "GROWTH": {
        "months_start": 6, "months_end": 60,
        "zus_status": "MALY_ZUS_PLUS lub STANDARD",
        "key_actions": ["Limit VAT 200k → VAT-R", "KSeF od 2026", "Pierwszy pracownik → ZUS ZUA + PIT-4R"],
        "legal_basis": "Art. 113 VAT, Art. 106na VAT"
    },
    "MATURITY": {
        "months_start": 30, "months_end": 999,
        "zus_status": "STANDARD",
        "key_actions": ["Optymalizacja: skala→liniowy", "JDG→Sp. z o.o.", "CIT estoński 0% przy reinwestycji"],
        "legal_basis": "Art. 9a PIT, Art. 19 CIT, Art. 551-584 KSH"
    },
    "SUSPENDED": {
        "months_max": 6,
        "zus_social_due": false,
        "zus_health_due": true,
        "key_actions": ["Max 6 mies. bez pracowników", "ZUS społeczne=0, zdrowotna NADAL", "Brak amortyzacji"],
        "legal_basis": "Art. 22-25 Prawa Przedsiębiorców, Art. 36a SUS"
    },
    "SUCCESSION": {
        "months_max_standard": 24,
        "months_max_extended": 60,
        "key_actions": ["Powołanie zarządcy (akt notarialny)", "Wpis CEIDG 14 dni", "NIP zmarłego + w spadku"],
        "legal_basis": "Art. 7-9, 49 Ustawy o zarządzie sukcesyjnym"
    },
    "CLOSURE": {
        "key_actions": ["Wykreślenie CEIDG", "Remanent likwidacyjny 10%", "VAT-Z + VAT 23%", "ZUS ZWUA 7d", "Zeznanie końcowe PIT"],
        "legal_basis": "Art. 24 PIT, Art. 14 VAT, Art. 31-36 Prawa Przedsiębiorców"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ZUS Relief Timeline
# ═══════════════════════════════════════════════════════════════════════════════

zus_relief_timeline := {
    "START_RELIEF": {"months": 6, "social_base_pln": 0, "health_rate": "wg stawki", "legal": "Art. 18a SUS"},
    "PREFERENTIAL": {"months": 24, "social_base_pct": 30, "min_base_pln": min_wage_2026 * 0.30, "legal": "Art. 18c SUS"},
    "MALY_ZUS_PLUS": {"months": 36, "social_base": "income_based", "max_months": 36, "legal": "Art. 18b SUS"},
    "STANDARD": {"social_base_pct": 60, "min_base_pln": min_wage_2026 * 0.60, "legal": "Art. 18 SUS"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# Tax Form Comparison
# ═══════════════════════════════════════════════════════════════════════════════

tax_form_comparison := {
    "PIT_SCALE": {"rate": "12%/32%", "base": "dochód", "kup_allowed": true, "threshold_32_pct": 120000, "declaration": "PIT-36"},
    "LINEAR": {"rate": "19%", "base": "dochód", "kup_allowed": true, "declaration": "PIT-36L"},
    "LUMP_SUM": {"rate": "2-17%", "base": "przychód", "kup_allowed": false, "declaration": "PIT-28"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# Key Thresholds
# ═══════════════════════════════════════════════════════════════════════════════

key_thresholds := {
    "vat_exemption_limit": 200000,
    "small_taxpayer_cit_limit_pln": 2000000,
    "small_taxpayer_cit_limit_eur": 2000000,
    "unregistered_activity_limit_pct": 50,
    "unregistered_activity_limit_pln": floor(min_wage_2026 * 0.50),
    "ksef_mandatory_date": "2026-02-01",
    "suspension_max_months": 6,
    "succession_max_months_standard": 24,
    "succession_max_months_extended": 60
}

# ═══════════════════════════════════════════════════════════════════════════════
# Exit Checklist (10 steps)
# ═══════════════════════════════════════════════════════════════════════════════

exit_checklist := [
    "1. Wyrejestruj CEIDG (CEIDG-1 — wniosek o wykreślenie)",
    "2. Spisz REMANENT LIKWIDACYJNY (ceny zakupu lub rynkowe — niższa)",
    "3. Zapłać 10% zryczałtowany podatek od remanentu (Art. 24 PIT)",
    "4. Wyrejestruj VAT (VAT-Z) + VAT od remanentu 23% (Art. 14 VAT)",
    "5. ZUS ZWUA — wyrejestrowanie w 7 dni",
    "6. Zeznanie końcowe PIT do 30 kwietnia następnego roku",
    "7. Ostatni JPK_V7M (25. dnia następnego miesiąca)",
    "8. Rozwiąż umowy pracowników (odprawy, PIT-11)",
    "9. Spłać zaległe podatki i ZUS",
    "10. Przechowuj dokumentację 5 lat (Art. 86 OrdPU)"
]

exit_remnant_tax_rate := 0.10
exit_vat_remnant_rate := 0.23

# ═══════════════════════════════════════════════════════════════════════════════
# Gig Economy Platform Rates
# ═══════════════════════════════════════════════════════════════════════════════

gig_platforms := {
    "UBER": {"vat_rate": 0.08, "lump_sum_rate": 0.085, "commission_avg_pct": 25},
    "BOLT": {"vat_rate": 0.08, "lump_sum_rate": 0.085, "commission_avg_pct": 20},
    "GLOVO": {"vat_rate": 0.08, "lump_sum_rate": 0.03, "commission_avg_pct": 30},
    "WOLT": {"vat_rate": 0.08, "lump_sum_rate": 0.03, "commission_avg_pct": 30}
}

# ═══════════════════════════════════════════════════════════════════════════════
# P16 Comprehensive Assessment
# ═══════════════════════════════════════════════════════════════════════════════

p16_comprehensive_assessment := {
    "timestamp": "2026-08-01",
    "version": "P16 v8.0 — FULL LOGIC",
    "innovation_file": "p16_business_lifecycle_innovations_v8.rego",
    "innovation_status": "FULLY IMPLEMENTED (was SKELETONS)",
    "lifecycle_phases": 5,
    "zus_relief_periods": 4,
    "tax_forms": 3,
    "key_thresholds": key_thresholds,
    "exit_checklist_steps": 10,
    "gig_platforms_covered": 4,
    "existing_rego_rules": "lifecycle_manager (4 reguły S24) + business.rego (15 reguł) + gig_economy (5 reguł) + plan26 (5 reguł)",
    "innovation_count": 12,
    "toolkit": "JDG/tools/p16_business_lifecycle_toolkit.py"
}
