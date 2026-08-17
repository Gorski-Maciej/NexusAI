# ═══════════════════════════════════════════════════════════════════════════════
# _pcc_local_excise_rates.rego — P15 PCC + Local Taxes + Excise Rates Helper
# ═══════════════════════════════════════════════════════════════════════════════
#
# Import as: data.jdg.pcc_local_excise_rates
# Package: jdg.pcc_local_excise_rates
#
# Zawiera:
#   - Stawki PCC (0.5%, 1%, 2%) + progi zwolnień
#   - Stawki podatku od nieruchomości 2026
#   - Stawki transportowe (DT-1) per DMC
#   - Stawki akcyzowe (paliwa, alkohol, tytoń, energia)
#   - Kalendarz podatkowy (wszystkie terminy)
#   - Progi zwolnień i wyłączeń
#   - Mapa pokrycia artykułów
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pcc_local_excise_rates

# ── 2026 Minimum Wage ──
min_wage_2026 := 4800.00

# ═══════════════════════════════════════════════════════════════════════════════
# PCC Rates (Ustawa o podatku od czynności cywilnoprawnych)
# ═══════════════════════════════════════════════════════════════════════════════

pcc_rates := {
    "SALE_MOVABLE": 2.0,
    "SALE_REAL_ESTATE": 2.0,
    "SALE_VEHICLE_PRIVATE": 2.0,
    "LOAN": 0.5,
    "SHARE_PURCHASE": 1.0,
    "COMPANY_FORMATION": 0.5,
    "EXCHANGE_REAL_ESTATE": 2.0,
    "EXCHANGE_OTHER": 1.0,
    "MORTGAGE": 0.1,
    "SURETY": 0.5,
    "INSTALLMENT_SALE": 2.0,
    "INHERITANCE_DIVISION": 1.0
}

# PCC Exemption thresholds
pcc_threshold_small := 1000.00  # Art. 9 pkt 1 — kwoty ≤ 1000 PLN zwolnione
pcc_family_loan_limit := 36120.00  # Pożyczka rodzinna zwolniona do tego limitu

# PCC VAT exclusion (Art. 2 pkt 4)
pcc_vat_exclusion := "Transakcje objęte VAT są wyłączone z PCC"

# PCC Contract withdrawal / deposit (wadium) handling
# Art. 1 ust. 1 — wadium nie podlega PCC (zwrotny depozyt)
# Art. 3 ust. 1 pkt 4 — rezygnacja z umowy: PCC zwracany jeśli odstąpienie w ciągu 14 dni
pcc_wadium_not_taxable := "Wadium/kaucja zwrotna NIE podlega PCC"
pcc_contract_withdrawal_refund_days := 14
pcc_contract_withdrawal_rate_pct := 0  # Pełny zwrot PCC przy odstąpieniu

# PCC-3 declaration deadline
pcc3_deadline_days := 14

# ═══════════════════════════════════════════════════════════════════════════════
# Real Estate Tax Rates 2026 (UoPiOL + obwieszczenie MF)
# ═══════════════════════════════════════════════════════════════════════════════

real_estate_rates := {
    "land_business": 1.43,
    "land_other": 0.71,
    "building_business": 33.10,
    "building_residential": 1.15,
    "construction_pct_value": 2.0
}

# Rate comparison warning
real_estate_business_vs_residential_multiplier := floor(33.10 / 1.15 * 10) / 10  # ~28.8×

# DN-1 deadlines
dn1_initial_deadline_days := 14  # Od nabycia/zmiany
dn1_payment_schedule := ["MARCH_15", "MAY_15", "SEPTEMBER_15", "NOVEMBER_15"]

# Agricultural tax
agricultural_rye_quintals_per_ha := 2.5
agricultural_rye_price_per_quintal := 89.63  # 2026

# Forestry tax
forestry_wood_m3_per_ha := 0.22
forestry_wood_price_per_m3 := 350.00

# ═══════════════════════════════════════════════════════════════════════════════
# Transport Tax Rates 2026 (DT-1)
# ═══════════════════════════════════════════════════════════════════════════════

transport_tax_rates := {
    "TRUCK_3_5_5_5": 800,
    "TRUCK_5_5_9": 1000,
    "TRUCK_9_12": 1400,
    "TRUCK_OVER_12": 2000,
    "TRACTOR_UNIT": 2300,
    "BUS_UNDER_22": 1600,
    "BUS_OVER_22": 2400,
    "TRAILER_LIGHT": 800,
    "TRAILER_MEDIUM": 1200,
    "TRAILER_HEAVY_2AX": 1800,
    "TRAILER_HEAVY_3AX": 2400
}

# DT-1 deadline
dt1_deadline := "FEBRUARY_15"
dt1_payment_schedule := ["FEBRUARY_15", "SEPTEMBER_15"]

# Transport tax exemptions
transport_tax_exemptions := {
    "ELECTRIC": "Pojazd elektryczny",
    "HYBRID": "Hybryda plug-in (częściowe)",
    "HISTORIC": "Pojazd zabytkowy",
    "EMERGENCY": "Pojazd ratowniczy"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Excise Rates 2026 (ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220))
# ═══════════════════════════════════════════════════════════════════════════════

excise_fuel := {
    "GASOLINE_UNLEADED_per_1000l": 1659,
    "GASOLINE_LEADED_per_1000l": 1859,
    "DIESEL_per_1000l": 1319,
    "LPG_per_1000kg": 700,
    "CNG_per_1000kg": 449,
    "HEATING_OIL_LIGHT_per_1000l": 64,
    "HEATING_OIL_HEAVY_per_1000l": 64
}

excise_alcohol := {
    "SPIRITS_per_hl_100pct": 8700,
    "BEER_per_hl_per_plato": 9.29,
    "WINE_per_hl": 216,
    "CIDER_per_hl": 108,
    "MEAD_per_hl": 108
}

excise_tobacco := {
    "CIGARETTES_ad_valorem_pct": 32,
    "CIGARETTES_specific_per_1000": 105.00,
    "CIGARETTES_minimum_pct_retail": 70,
    "CIGARS_per_1000": 595,
    "SMOKING_TOBACCO_per_kg": 300
}

# Mapa drogowa akcyzy tytoniowej 2027 (wzrost z 32%+105 PLN → 40%+140 PLN)
excise_tobacco_2027_roadmap := {
    "CIGARETTES_ad_valorem_pct_2027": 40,
    "CIGARETTES_specific_per_1000_2027": 140.00,
    "CIGARETTES_minimum_pct_retail_2027": 70,
    "effective_date": "2027-01-01",
    "legal_basis": "Mapa drogowa akcyzy tytoniowej 2025-2027 (Dz.U. 2025 poz. 420)",
    "increase_note": "Wzrost o +8 p.p. ad valorem i +35 PLN/1000szt"
}

# Agricultural diesel refund limits (zwrot akcyzy dla rolników)
excise_diesel_agriculture_refund_per_liter := 1.20  # PLN/L
# Art. 5 ustawy o zwrocie akcyzy rolnikom: limit 100 L/ha rocznie
excise_diesel_agriculture_limit_per_ha := 100  # litrów na hektar

# Alkohol etylowy laboratoryjny/medyczny — zwolnienie
# Art. 30 ust. 7 pkt 2 — alkohol do celów medycznych ZWOLNIONY
excise_alcohol_lab_exempt_categories := ["MEDICAL", "LABORATORY", "PHARMACEUTICAL", "SCIENTIFIC"]
excise_alcohol_lab_rate := 0  # Stawka 0% dla celów medycznych/laboratoryjnych

excise_energy := {
    "ELECTRICITY_business_per_mwh": 5.00,
    "ELECTRICITY_residential": 0
}

# Excise declarations
excise_declaration := "AKC-4"
excise_declaration_deadline := "25th of following month"

# Excise warehouse requirements
excise_warehouse_required_categories := ["ALCOHOL", "TOBACCO", "MOTOR_FUEL"]

# Excise suspension procedure (procedura zawieszenia akcyzy)
excise_suspension_tiers := {
    "tier1": "skład podatkowy — zezwolenie naczelnika UC",
    "tier2": "zabezpieczenie akcyzowe — gwarancja bankowa/kaucja",
    "tier3": "e-DD/SENT/EMCS — dokumentacja przemieszczania"
}

# Cross-border excise — EMCS countries (27 EU)
excise_emcs_eu_countries := ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"]

# Agricultural fuel exemption limit
# Art. 32 ust. 1 pkt 3-4 — paliwo rolnicze zwolnione w limicie 100 L/ha
excise_agriculture_fuel_limit_liters_per_ha := 100

# Coal excise rate
excise_coal_rate_per_tonne := 13.50  # PLN/tona (2026)

# ═══════════════════════════════════════════════════════════════════════════════
# Multi-Tax Calendar (all deadlines)
# ═══════════════════════════════════════════════════════════════════════════════

tax_calendar := [
    {"month": 1, "day": 31, "tax": "DN-1 — deklaracja na podatek od nieruchomości", "form": "DN-1"},
    {"month": 2, "day": 15, "tax": "DT-1 — I rata", "form": "DT-1"},
    {"month": 3, "day": 15, "tax": "DN-1 — I rata + BDO raport roczny", "form": "DN-1/BDO"},
    {"month": 4, "day": 30, "tax": "PIT-36/PIT-36L — zeznanie roczne", "form": "PIT"},
    {"month": 5, "day": 15, "tax": "DN-1 — II rata", "form": "DN-1"},
    {"month": 9, "day": 15, "tax": "DT-1 — II rata + DN-1 — III rata", "form": "DT-1/DN-1"},
    {"month": 11, "day": 15, "tax": "DN-1 — IV rata", "form": "DN-1"},
    {"month": 0, "day": 14, "tax": "PCC-3 — 14 dni od transakcji (ciągły)", "form": "PCC-3"},
    {"month": 0, "day": 25, "tax": "AKC-4 — akcyza miesięcznie", "form": "AKC-4"},
    {"month": 0, "day": 25, "tax": "VAT-7 / JPK_V7 — VAT miesięcznie", "form": "JPK_V7"}
]

# ═══════════════════════════════════════════════════════════════════════════════
# Coverage Map — Existing Rego Rules
# ═══════════════════════════════════════════════════════════════════════════════

existing_coverage := {
    "pcc": {
        "macro_rules": 5,
        "enterprise_rules": 30,
        "micro_rules": 24,
        "total": 59,
        "articles_covered": ["Art. 1", "Art. 2 pkt 4", "Art. 6-7", "Art. 9", "Art. 10"],
        "declarations": ["PCC-3"]
    },
    "real_estate": {
        "macro_rules": 3,
        "enterprise_rules": 12,
        "total": 15,
        "declarations": ["DN-1"],
        "rates": "33.10 PLN/m² (firmowa) vs 1.15 PLN/m² (mieszkalna)"
    },
    "transport": {
        "macro_rules": 4,
        "enterprise_rules": 10,
        "total": 14,
        "declarations": ["DT-1"],
        "vehicle_types": ["TRUCK", "TRACTOR", "BUS", "TRAILER", "SPECIAL"]
    },
    "excise": {
        "macro_rules": 5,
        "enterprise_rules": 15,
        "micro_rules": 10,
        "total": 30,
        "declarations": ["AKC-4"],
        "categories": ["MOTOR_FUEL", "HEATING_FUEL", "ALCOHOL", "TOBACCO", "ENERGY"]
    },
    "local_fees": {
        "macro_rules": 5,
        "enterprise_rules": 6,
        "total": 11,
        "types": ["MARKET_FEE", "RESORT_FEE", "SPA_FEE", "ADVERTISING", "DOG_FEE"]
    },
    "bdo_environmental": {
        "macro_rules": 5,
        "total": 5,
        "types": ["BDO", "KOBIZE", "SUP", "ENVIRONMENTAL", "MINING"]
    }
}

total_rules := sum([v | v := existing_coverage[_]; v.total])

# ═══════════════════════════════════════════════════════════════════════════════
# P15 Comprehensive Assessment
# ═══════════════════════════════════════════════════════════════════════════════

p15_comprehensive_assessment := {
    "timestamp": "2026-08-01",
    "version": "P15 v8.0 — FULL LOGIC",
    "innovation_file": "p15_pcc_local_excise_innovations_v8.rego",
    "innovation_status": "FULLY IMPLEMENTED (was SKELETONS)",
    "total_rego_rules": total_rules,
    "pcc_coverage": existing_coverage.pcc,
    "real_estate_coverage": existing_coverage.real_estate,
    "transport_coverage": existing_coverage.transport,
    "excise_coverage": existing_coverage.excise,
    "local_fees_coverage": existing_coverage.local_fees,
    "bdo_coverage": existing_coverage.bdo_environmental,
    "rates_basis": "Obwieszczenie MF 2026 + Uchwały Rad Gmin",
    "innovation_count": 12,
    "toolkit": "JDG/tools/p15_pcc_local_excise_toolkit.py"
}
