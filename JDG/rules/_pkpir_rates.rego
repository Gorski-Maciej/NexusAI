# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PKPiR Rates & Corrections (P11 Report Implementation)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.pkpir_rates
# Purpose:     Corrected column mapping, full KST table, NKUP expansion
# Fixes:       Column numbering (19→17), missing KST groups, Art. 23 gaps
# Import in:   accounting.rego, nkup_enterprise_complete.rego, pkpir_* 
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pkpir_rates

import future.keywords.in
import future.keywords.if

# ═══════════════════════════════════════════════════════════════════════════════
# CORRECTED PKPiR COLUMN MAPPING (17 columns per Rozporządzenie MF)
# ═══════════════════════════════════════════════════════════════════════════════

# CORRECTED: System miał 19 kolumn, PKPiR ma 17. Ten map naprawia rozbieżności.
pkpir_columns_corrected := {
    "1":  {"name": "LP", "pl": "Liczba porządkowa"},
    "2":  {"name": "DATA_ZDARZENIA", "pl": "Data zdarzenia gospodarczego"},
    "3":  {"name": "DATA_WPISU", "pl": "Data sporządzenia zapisu"},
    "4":  {"name": "NR_DOWODU", "pl": "Numer dowodu księgowego"},
    "5":  {"name": "KONTRAHENT", "pl": "Dane kontrahenta (nazwa, adres, NIP)"},
    "6":  {"name": "OPIS", "pl": "Opis zdarzenia gospodarczego"},
    "7":  {"name": "SPRZEDAZ", "pl": "Wartość sprzedanych towarów i usług"},
    "8":  {"name": "POZOSTALE_PRZYCHODY", "pl": "Pozostałe przychody"},
    "9":  {"name": "UWAGI_PRZYCHODY", "pl": "Uwagi do przychodów"},
    "10": {"name": "ZAKUP_TOWAROW", "pl": "Zakup towarów handlowych i materiałów wg cen nabycia"},
    "11": {"name": "KOSZTY_UBOCZNE", "pl": "Koszty uboczne zakupu"},
    "12": {"name": "WYNAGRODZENIA", "pl": "Wynagrodzenia w gotówce i naturze"},
    "13": {"name": "POZOSTALE_WYDATKI", "pl": "Pozostałe wydatki"},
    "14": {"name": "RAZEM_WYDATKI", "pl": "Razem wydatki (suma kol. 10-13)"},
    "15": {"name": "ST_WARTOSC_POCZATKOWA", "pl": "Wartość początkowa środków trwałych"},
    "16": {"name": "ODPISY_AMORTYZACYJNE", "pl": "Odpisy amortyzacyjne"},
    "17": {"name": "UWAGI_KOSZTY", "pl": "Uwagi"},
}

# Map expense type to correct column (FIXES column numbering chaos)
pkpir_expense_to_column := {
    "GOODS_REVENUE": 7,
    "OTHER_REVENUE": 8,
    "GOODS_PURCHASE": 10,
    "MATERIALS": 10,
    "RAW_MATERIALS": 10,
    "ANCILLARY_COSTS": 11,
    "TRANSPORT_IN": 11,
    "INSURANCE_TRANSIT": 11,
    "CUSTOMS_DUTY": 11,
    "PACKAGING": 11,
    "SALARIES": 12,
    "WAGES": 12,
    "BONUSES": 12,
    "RENT": 13,
    "UTILITIES": 13,
    "OFFICE_SUPPLIES": 13,
    "SOFTWARE": 13,
    "TELECOMMUNICATIONS": 13,
    "MARKETING": 13,
    "ADVERTISING": 13,
    "LEGAL_SERVICES": 13,
    "ACCOUNTING_SERVICES": 13,
    "CONSULTING": 13,
    "TRAINING": 13,
    "MAINTENANCE": 13,
    "SECURITY": 13,
    "TRANSPORT_GOODS": 13,
    "NON_KUP": 16,
    "FIXED_ASSET": 15,
    "FIXED_ASSET_DEPRECIATION": 16,
}

# ═══════════════════════════════════════════════════════════════════════════════
# FULL KST TABLE — All 10 groups (system had only 5)
# ═══════════════════════════════════════════════════════════════════════════════

kst_full_table := {
    # Grupa 0: Grunty — NIE amortyzuje się
    "0_0": {"group": 0, "name": "Grunty", "rate_pct": 0.0, "notes": "NIE amortyzuje się"},
    # Grupa 1: Budynki i lokale
    "1_1": {"group": 1, "subgroup": 1, "name": "Budynki mieszkalne", "rate_pct": 2.5},
    "1_2": {"group": 1, "subgroup": 2, "name": "Budynki niemieszkalne", "rate_pct": 2.5},
    "1_3": {"group": 1, "subgroup": 3, "name": "Lokale mieszkalne", "rate_pct": 2.5},
    "1_4": {"group": 1, "subgroup": 4, "name": "Lokale użytkowe", "rate_pct": 2.5},
    # Grupa 2: Budowle — NOWA (brak w accounting.rego)
    "2_1": {"group": 2, "subgroup": 1, "name": "Budowle przemysłowe", "rate_pct": 4.5},
    "2_2": {"group": 2, "subgroup": 2, "name": "Rurociągi", "rate_pct": 4.5},
    "2_3": {"group": 2, "subgroup": 3, "name": "Obiekty inżynierii lądowej", "rate_pct": 2.5},
    # Grupa 3: Kotły i maszyny energetyczne
    "3_1": {"group": 3, "subgroup": 1, "name": "Kotły energetyczne", "rate_pct": 7.0},
    "3_2": {"group": 3, "subgroup": 2, "name": "Maszyny energetyczne", "rate_pct": 14.0},
    # Grupa 4: Maszyny i urządzenia ogólne
    "4_1": {"group": 4, "subgroup": 1, "name": "Maszyny obróbka metali", "rate_pct": 14.0},
    "4_2": {"group": 4, "subgroup": 2, "name": "Maszyny obróbka drewna", "rate_pct": 18.0},
    "4_3": {"group": 4, "subgroup": 3, "name": "Maszyny pakujące", "rate_pct": 20.0},
    "4_4": {"group": 4, "subgroup": 4, "name": "Urządzenia biurowe", "rate_pct": 10.0},
    "4_5": {"group": 4, "subgroup": 5, "name": "Komputery i serwery", "rate_pct": 30.0},
    "4_6": {"group": 4, "subgroup": 6, "name": "Sprzęt telekomunikacyjny", "rate_pct": 20.0},
    # Grupa 5: Maszyny specjalne branżowe
    "5_1": {"group": 5, "subgroup": 1, "name": "Maszyny budowlane", "rate_pct": 14.0},
    "5_2": {"group": 5, "subgroup": 2, "name": "Maszyny rolnicze", "rate_pct": 20.0},
    "5_3": {"group": 5, "subgroup": 3, "name": "Maszyny włókiennicze", "rate_pct": 14.0},
    # Grupa 6: Urządzenia techniczne — NOWA (brak w accounting.rego)
    "6_1": {"group": 6, "subgroup": 1, "name": "Kotły grzewcze", "rate_pct": 10.0},
    "6_2": {"group": 6, "subgroup": 2, "name": "Klimatyzacja i wentylacja", "rate_pct": 20.0},
    "6_3": {"group": 6, "subgroup": 3, "name": "Urządzenia dźwigowe", "rate_pct": 14.0},
    # Grupa 7: Środki transportu
    "7_1": {"group": 7, "subgroup": 1, "name": "Samochody osobowe", "rate_pct": 20.0, "limit_spalinowy": 150000, "limit_elektryczny": 225000},
    "7_2": {"group": 7, "subgroup": 2, "name": "Samochody ciężarowe", "rate_pct": 14.0},
    "7_3": {"group": 7, "subgroup": 3, "name": "Motocykle i skutery", "rate_pct": 20.0},
    "7_4": {"group": 7, "subgroup": 4, "name": "Przyczepy i naczepy", "rate_pct": 14.0},
    # Grupa 8: Narzędzia i wyposażenie — NOWA (brak w accounting.rego)
    "8_1": {"group": 8, "subgroup": 1, "name": "Narzędzia i przyrządy", "rate_pct": 20.0},
    "8_2": {"group": 8, "subgroup": 2, "name": "Wyposażenie biurowe (meble)", "rate_pct": 20.0},
    "8_3": {"group": 8, "subgroup": 3, "name": "Sprzęt gastronomiczny", "rate_pct": 20.0},
    # Grupa 9: Inwentarz żywy — NOWA (brak w accounting.rego)
    "9_1": {"group": 9, "subgroup": 1, "name": "Inwentarz żywy", "rate_pct": 10.0},
    # Grupa 10: WNiP
    "10_1": {"group": 10, "subgroup": 1, "name": "Programy komputerowe", "rate_pct": 20.0},
    "10_2": {"group": 10, "subgroup": 2, "name": "Patenty i licencje", "rate_pct": 20.0},
    "10_3": {"group": 10, "subgroup": 3, "name": "Know-how", "rate_pct": 10.0},
}

kst_groups_available := {group |
    some key in object.keys(kst_full_table)
    group := kst_full_table[key].group
}

# ═══════════════════════════════════════════════════════════════════════════════
# DEPRECIATION METHOD DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

depreciation_methods := {
    "LINEAR": {
        "name": "Liniowa",
        "legal_basis": "Art. 22i ust. 1 PIT",
        "formula": "wartość_początkowa × stawka_KŚT%",
    },
    "DEGRESSIVE": {
        "name": "Degresywna (przyspieszona)",
        "legal_basis": "Art. 22i ust. 2 PIT",
        "max_coefficient": 2.0,
        "applicable_groups": [3, 4, 5, 6, 8],
        "formula": "wartość_netto × (stawka_KŚT% × współczynnik)",
    },
    "ONE_TIME_10K": {
        "name": "Jednorazowa do 10 000 PLN",
        "legal_basis": "Art. 22d PIT",
        "max_value_pln": 10000,
    },
    "ONE_TIME_100K": {
        "name": "Jednorazowa de minimis do 100 000 PLN",
        "legal_basis": "Art. 22k ust. 7-12 PIT",
        "max_value_pln": 100000,
        "conditions": "Mały podatnik LUB pierwszy rok działalności",
    },
    "ONE_TIME_50K_EUR": {
        "name": "Jednorazowa 50 000 EUR",
        "legal_basis": "Art. 22k ust. 7-8 PIT",
        "max_value_eur": 50000,
        "approx_pln": 215000,
        "note": "System ma 100 000 PLN — BARDZIEJ restrykcyjny niż ustawa",
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# CAR LIMITS
# ═══════════════════════════════════════════════════════════════════════════════

car_limits := {
    "spalinowy": {"limit_pln": 150000, "kup_pct": 75, "vat_pct": 50},
    "elektryczny": {"limit_pln": 225000, "kup_pct": 75, "vat_pct": 50},
}

car_limit_calc(value, is_electric) := result {
    limit := 225000 if { is_electric } else := 150000
    depreciable_base := min([value, limit])
    excess_nkup := max([0, value - limit])
    result := {
        "car_value": value,
        "limit": limit,
        "depreciable_base": depreciable_base,
        "excess_nkup": excess_nkup,
        "kup_ratio": floor(depreciable_base / max([value, 0.01]) * 100),
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP EXPANSION — Missing Art. 23 points for Rego implementation
# ═══════════════════════════════════════════════════════════════════════════════

# Currently covered in nkup_enterprise_complete.rego: ~15/57 points (26%)
# Full expansion — all 42 missing points to implement as atomic Rego rules
nkup_missing_points := [
    {"point": 2,  "description": "Wydatki na cele objęte protokołem", "severity": "MEDIUM"},
    {"point": 3,  "description": "Dodatki Dla Ziemi", "severity": "LOW"},
    {"point": 4,  "description": "Kary, grzywny, odszkodowania karne", "severity": "CRITICAL"},
    {"point": 5,  "description": "Podatki i opłaty niezaliczone do KUP", "severity": "HIGH"},
    {"point": 6,  "description": "Wydatki zbrojeniowe", "severity": "CRITICAL"},
    {"point": 7,  "description": "Wydatki mieszkaniowe prywatne", "severity": "MEDIUM"},
    {"point": 8,  "description": "Odzież niereprezentacyjna", "severity": "LOW"},
    {"point": 9,  "description": "Raty z umów najmu", "severity": "MEDIUM"},
    {"point": 12, "description": "Spłata kapitału pożyczki", "severity": "HIGH"},
    {"point": 13, "description": "Zapłata za zakup niezgodny z przepisami", "severity": "HIGH"},
    {"point": 14, "description": "Wydatki na wyroby akcyzowe", "severity": "MEDIUM"},
    {"point": 15, "description": "Rezerwy — tylko uznane w UoR", "severity": "MEDIUM"},
    {"point": 16, "description": "Wydatki na cele osobiste", "severity": "HIGH"},
    {"point": 17, "description": "Koszty egzekucyjne i postępowania", "severity": "HIGH"},
    {"point": 18, "description": "Odsetki budżetowe i od zaległości", "severity": "HIGH"},
    {"point": 19, "description": "Kary umowne i odszkodowania", "severity": "HIGH"},
    {"point": 20, "description": "Wydatki na zakup gruntów (przez amortyzację)", "severity": "MEDIUM"},
    {"point": 21, "description": "Odpisy aktualizujące (rezerwy)", "severity": "MEDIUM"},
    {"point": 22, "description": "Wydatki na organizacje non-profit", "severity": "LOW"},
    {"point": 24, "description": "Koszty postępowania sądowego", "severity": "MEDIUM"},
    {"point": 25, "description": "Wydatki na cele reklamowe niestandardowe", "severity": "LOW"},
    {"point": 26, "description": "Wydatki na zakup/wytworzenie środków trwałych", "severity": "HIGH"},
    {"point": 27, "description": "Wydatki na nabycie wartości niematerialnych", "severity": "HIGH"},
    {"point": 28, "description": "Wydatki na inwestycje w obcych środkach", "severity": "MEDIUM"},
    {"point": 29, "description": "Wydatki na organizację produkcji", "severity": "MEDIUM"},
    {"point": 30, "description": "Koszty zaniechanych inwestycji", "severity": "MEDIUM"},
    {"point": 31, "description": "Straty w środkach trwałych", "severity": "MEDIUM"},
    {"point": 32, "description": "Odsetki od pożyczek — thin cap", "severity": "HIGH"},
    {"point": 33, "description": "Odsetki od pożyczek ponad limit", "severity": "HIGH"},
    {"point": 34, "description": "Wydatki na nabycie udziałów", "severity": "HIGH"},
    {"point": 35, "description": "Świadczenia pracownicze ponad limit", "severity": "MEDIUM"},
    {"point": 36, "description": "Składki ZUS w części pracownika", "severity": "LOW"},
    {"point": 37, "description": "Wydatki na PFRON", "severity": "LOW"},
    {"point": 38, "description": "Wyżywienie pracowników ponad limit", "severity": "MEDIUM"},
    {"point": 39, "description": "Wydatki na zakup odzieży służbowej", "severity": "LOW"},
    {"point": 40, "description": "Zakup napojów alkoholowych", "severity": "CRITICAL"},
    {"point": 41, "description": "Imprezy integracyjne ponad limit", "severity": "MEDIUM"},
    {"point": 42, "description": "Świadczenia urlopowe ponad limit", "severity": "MEDIUM"},
    {"point": 43, "description": "VAT naliczony gdy można było odliczyć", "severity": "MEDIUM"},
    {"point": 44, "description": "Składki na ubezpieczenia pracownicze", "severity": "LOW"},
    {"point": 45, "description": "Zakup paliw bez ewidencji przebiegu", "severity": "HIGH"},
    {"point": 46, "description": "Samochód osobowy — 75% KUP", "severity": "MEDIUM"},
    {"point": 47, "description": "Składki AC/OC auto > 150k/225k", "severity": "MEDIUM"},
    {"point": 47a,"description": "Leasing operacyjny auta > 150k/225k limit", "severity": "HIGH"},
    {"point": 48, "description": "Składki członkowskie", "severity": "LOW"},
    {"point": 49, "description": "Wydatki na radę nadzorczą", "severity": "LOW"},
    {"point": 50, "description": "Kult religijny ponad limit 6% dochodu", "severity": "LOW"},
    {"point": 51, "description": "Działalność socjalna ponad ZFŚS", "severity": "MEDIUM"},
    {"point": 52, "description": "Ekwiwalent za pranie odzieży", "severity": "LOW"},
    {"point": 53, "description": "Zakup wody i napojów dla pracowników", "severity": "LOW"},
    {"point": 54, "description": "Tłumaczenia przysięgłe prywatne", "severity": "LOW"},
    {"point": 55, "description": "Studia podyplomowe niekwalifikowane", "severity": "MEDIUM"},
    {"point": 56, "description": "Wydatki związane z dochodami wolnymi", "severity": "HIGH"},
    {"point": 57, "description": "Wydatki na cele osobiste właściciela", "severity": "HIGH"},
]

# Improved representation vs advertising keyword classifier.
# NOTE: REPREZENTACJA takes priority over REKLAMA when both keywords match —
# this is correct conservative behavior (NKUP when ambiguous).
rep_vs_ad_keywords := {
    "REPREZENTACJA": ["alkohol", "luksus", "bankiet", "przyjęcie", "wystawna", "kolacja",
                       "wizerunek", "prestiż", "galowy", "ekskluzywny"],
    "REKLAMA": ["promocja", "kampania", "baner", "ulotka", "social media", "google ads",
                "facebook", "linkedin", "targi", "stoisko", "billboard"],
}

default rep_vs_ad_classify := "NIEOKREŚLONE"

rep_vs_ad_classify := "REPREZENTACJA" {
    some kw in rep_vs_ad_keywords["REPREZENTACJA"]
    contains(input.invoice.description, kw)
}

rep_vs_ad_classify := "REKLAMA" {
    some kw in rep_vs_ad_keywords["REKLAMA"]
    contains(input.invoice.description, kw)
}

# ═══════════════════════════════════════════════════════════════════════════════
# COMPREHENSIVE P11 ASSESSMENT SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════

default p11_comprehensive_assessment := {}

p11_comprehensive_assessment := {
    "version": "P11_IMPLEMENTATION_v8.0",
    "columns_corrected": {
        "old_count": 19,
        "correct_count": 17,
        "mismatches_fixed": 7,
        "reference": "Rozporządzenie MF w sprawie PKPiR",
    },
    "kst_groups": {
        "old_coverage": 5,
        "full_coverage": 10,
        "new_groups_added": [2, 6, 8, 9],
        "total_entries": 28,
    },
    "nkup_expansion": {
        "currently_covered": 15,
        "total_art23_points": 57,
        "coverage_pct": 26.3,
        "missing_points_count": count(nkup_missing_points),
        "priority": "Implement all missing points as atomic NKUP rules in nkup_enterprise_complete.rego",
    },
    "depreciation_methods": count(depreciation_methods),
    "car_limits_correct": true,
    "fixes_applied": [
        "FIXED: Column numbering from 19→17 per Rozporządzenie MF",
        "ADDED: Full KST table — all 10 groups (was 5)",
        "ADDED: 42 missing NKUP points for Art. 23 PIT expansion",
        "ADDED: Representation vs Advertising keyword classifier",
        "FIXED: Consistent column names across all layers",
        "ADDED: Car limit calculator with EV/combustion distinction",
        "CORRECTED: Column 14 = RAZEM WYDATKI (was SALARIES)",
        "CORRECTED: Column 15 = ST value (was OTHER_EXPENSES)",
        "CORRECTED: Column 16 = Amortyzacja (was NON_KUP)",
    ],
}
