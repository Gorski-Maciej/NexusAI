# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Decoupled Threshold Injection Data (B2 Strategic Initiative)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Threshold Data — Externalized Magic Numbers
# description: |
#   B2 z NexusAI_JDG_STRATEGIC_IMPROVEMENTS_7000.txt.
#   Wszystkie progi, stawki, limity i wartości numeryczne JDG w jednym miejscu.
#   Reguły Rego używają wyłącznie data.thresholds.jdg.* — zero hardcoded values.
#   Aktualizacja progów = zmiana tego pliku, bez rekompilacji WASM bundle.
#   Dodano sekcje Environmental/AML/MDR (2026-07-17) z Enterprise packages
#   architecture: Decoupled Data Layer (B2)
#   package: jdg.thresholds
#   deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.thresholds

# ═══════════════════════════════════════════════════════════════════════════════
# VAT THRESHOLDS
# ═══════════════════════════════════════════════════════════════════════════════

vat := {
    # Art. 113 VAT — zwolnienie podmiotowe
    "subject_exemption_limit": 200000,          # PLN rocznie (P58)

    # Art. 41 VAT — stawki podstawowe
    "standard_rate": 0.23,                       # 23% (P541)
    "reduced_rate_8": 0.08,                      # 8% (P542)
    "reduced_rate_5": 0.05,                      # 5% (P543)
    "zero_rate": 0.00,                           # 0% (P544)
    "exempt": "ZW",                              # Zwolnione

    # Art. 89a-89b VAT — ulga na złe długi (SLIM VAT 3/2025)
    "bad_debt_days": 90,                         # 90 dni po terminie (P189, P60b)
    "bad_debt_sanction_30pct": 0.30,             # Sankcja 30% dla dłużnika (P652)

    # Art. 106e VAT — paragon z NIP
    "receipt_nip_limit": 450,                    # PLN — limit paragonu z NIP (P140)

    # Art. 86a VAT — odliczenie VAT od auta
    "car_vat_deduction_no_log": 0.50,            # 50% bez ewidencji przebiegu (P599)
    "car_vat_deduction_with_log": 1.00,          # 100% z ewidencją (P600)

    # Art. 87 VAT — terminy zwrotu
    "vat_refund_standard_days": 60,              # 60 dni standardowo (P587)
    "vat_refund_accelerated_days": 25,           # 25 dni przyśpieszony (P589)

    # Art. 90 VAT — proporcja
    "proportion_min_threshold": 0.02,            # 2% — poniżej = 0% odliczenia (P553)
    "proportion_max_threshold": 0.98,            # 98% — powyżej = 100% odliczenia

    # KSeF (Art. 106na-106nq VAT)
    "ksef_mandatory_from": "2026-02-01",        # Data obowiązku KSeF
    "ksef_offline_grace_days": 7,               # 7 dni na przesłanie po awarii
    "ksef_sanction_max_pln": 500000,            # Max sankcja za brak KSeF
}

# ═══════════════════════════════════════════════════════════════════════════════
# PIT THRESHOLDS
# ═══════════════════════════════════════════════════════════════════════════════

pit := {
    # Art. 27 PIT — skala podatkowa (P500)
    "scale_low_rate": 0.12,                      # 12% — pierwszy próg
    "scale_high_rate": 0.32,                     # 32% — drugi próg
    "scale_threshold": 120000,                   # PLN — próg 12%/32%
    "tax_free_amount": 30000,                    # PLN — kwota wolna od 2022
    "tax_free_reduction": 3600,                  # PLN — 12% × 30k

    # Art. 30c PIT — podatek liniowy (P510)
    "linear_rate": 0.19,                         # 19%

    # Art. 30ca PIT — IP Box (P550)
    "ip_box_rate": 0.05,                         # 5% od kwalifikowanego IP

    # Art. 22 PIT — KUP
    "car_kup_no_log": 0.75,                      # 75% KUP bez ewidencji (P852)
    "car_kup_with_log": 1.00,                    # 100% KUP z ewidencją
    "car_value_limit_standard": 150000,          # PLN — limit wartości auta (P607)
    "car_value_limit_ev": 225000,               # PLN — limit EV

    # Art. 23 PIT — koszty auta
    "car_lease_insurance_limit": 150000,         # PLN — limit leasing/ubezp.
    "representation_limit_pct": 0.0025,          # 0.25% przychodu (P598)

    # Art. 26 PIT — darowizny
    "donation_limit_pct": 0.06,                  # 6% dochodu (P612)

    # Art. 9 PIT — straty
    "loss_carry_forward_years": 5,              # 5 lat na rozliczenie (P615)
    "loss_carry_forward_max_pct": 0.50,          # Max 50% rocznie
    "loss_carry_forward_one_off_pln": 5000000,   # 5M PLN jednorazowo

    # Art. 30f PIT — CFC
    "cfc_control_threshold": 0.50,              # >50% udziałów (P675)
    "cfc_passive_income_threshold": 0.33,        # >33% dochodu pasywnego (P676)
    "cfc_foreign_tax_threshold": 0.1425,         # <14.25% CIT za granicą

    # Art. 30da PIT — Exit Tax
    "exit_tax_rate": 0.19,                      # 19%
}

# ═══════════════════════════════════════════════════════════════════════════════
# ZUS / SUS THRESHOLDS
# ═══════════════════════════════════════════════════════════════════════════════

zus := {
    # Art. 18a SUS — ulga na start (P740)
    "start_relief_months": 6,                    # 6 miesięcy

    # Art. 18c SUS — Mały ZUS Plus (P741)
    "maly_zus_plus_months": 36,                  # 36 miesięcy
    "maly_zus_plus_income_limit": 60000,         # PLN rocznie
    "maly_zus_plus_revenue_limit": 120000,       # PLN rocznie — próg utraty MZP (ENTERPRISE)

    # Art. 18a SUS — preferencyjny (P742)
    "preferential_months": 24,                   # 24 miesiące

    # Standardowa podstawa wymiaru (60% przeciętnego wynagrodzenia)
    "social_base_standard": 5204.40,            # PLN — 60% × 8674 PLN (prognoza 2026)

    # Składka zdrowotna (Polski Ład 2022)
    "health_scale_rate": 0.09,                   # 9% od dochodu (P720) — NIE odlicza się
    "health_linear_rate": 0.049,                 # 4.9% od dochodu (P722)
    "health_linear_deduction_limit": 12900,      # PLN/rok max odliczenia (P563)

    # Ryczałt zdrowotny — progi (P564)
    "health_lump_tier_1_limit": 60000,           # PLN przychodu
    "health_lump_tier_2_limit": 300000,          # PLN przychodu
    "health_lump_tier_1_amount": 419.46,         # PLN/mies
    "health_lump_tier_2_amount": 699.11,         # PLN/mies
    "health_lump_tier_3_amount": 1258.39,        # PLN/mies

    # Zasiłek chorobowy
    "sickness_waiting_days": 90,                 # 90 dni wyczekiwania (P578, ENTERPRISE P745)
    "sickness_benefit_rate": 0.80,               # 80% podstawy
    "sickness_hospital_rate": 0.70,              # 70% w szpitalu

    # Stopy procentowe składek społecznych
    "pension_rate": 0.1952,                      # 19.52% — emerytalna
    "disability_rate": 0.08,                     # 8% — rentowa
    "sickness_voluntary_rate": 0.0245,           # 2.45% — chorobowa (dobrowolna)
    "accident_rate": 0.0167,                     # 1.67% — wypadkowa
    "labour_fund_rate": 0.0245,                  # 2.45% — Fundusz Pracy
}

# ═══════════════════════════════════════════════════════════════════════════════
# BOUNDS — Ogólne wartości referencyjne (płaca minimalna, kursy walut)
# ═══════════════════════════════════════════════════════════════════════════════

bounds := {
    # Minimalne wynagrodzenie brutto (2026)
    "minimum_wage_gross": 4666,                  # PLN — od 1 stycznia 2026

    # Standardowa podstawa wymiaru składek ZUS (60% przeciętnego wynagrodzenia)
    "zus_social_base_standard": 5204.40,        # PLN — 60% × 8674 PLN (prognoza 2026)

    # Przeciętne miesięczne wynagrodzenie (prognoza 2026)
    "avg_monthly_wage": 8674,                    # PLN — do obliczeń ZUS

    # Kurs EUR/PLN (NBP, orientacyjny)
    "eur_pln": 4.50,                             # PLN za 1 EUR

    # Diety i kilometrówka
    "mileage_rate_per_km": 1.15,                 # PLN/km — stawka za 1 km (osobowy)
    "business_trip_diet": 45.00,                 # PLN/dzień — dieta krajowa
}

# ═══════════════════════════════════════════════════════════════════════════════
# RYCZAŁT THRESHOLDS
# ═══════════════════════════════════════════════════════════════════════════════

lump_sum := {
    # Art. 6 ustawy o ryczałcie
    "annual_limit_eur": 2000000,                 # 2M EUR (P523)

    # Art. 12 — stawki ryczałtu per PKWiU
    "rate_2pct": 0.02,                           # Handel
    "rate_3pct": 0.03,                           # Gastronomia, produkcja
    "rate_5_5pct": 0.055,                        # Budownictwo
    "rate_8_5pct": 0.085,                        # Usługi, najem
    "rate_12pct": 0.12,                          # IT, wolne zawody >300k
    "rate_15pct": 0.15,                          # Zarządzanie
    "rate_17pct": 0.17,                          # Wolne zawody
}

# ═══════════════════════════════════════════════════════════════════════════════
# ORDYNACJA PODATKOWA / KKS THRESHOLDS
# ═══════════════════════════════════════════════════════════════════════════════

ord := {
    # Art. 70 OP — przedawnienie (P1150)
    "statute_of_limitations_years": 5,           # 5 lat

    # Art. 78 OP — zwrot nadpłaty
    "overpayment_refund_days": 45,               # 45 dni (P668)

    # Art. 16a OP — dodatkowe zobowiązanie
    "additional_tax_rate_pct": 0.30,             # 30% sankcji

    # Art. 53 OP — odsetki
    "tax_interest_rate": 0.145,                  # 14.5% rocznie

    # Art. 96b VAT — Biała Lista
    "whitelist_verification_days": 30,           # 30 dni (P663)
    "whitelist_buffer_days": 3,                  # 3 dni buforu (P664)

    # Art. 5 PP — działalność nieewidencjonowana
    "unregistered_revenue_pct": 0.50,            # 50% min. wynagrodzenia (P930)
}

# ═══════════════════════════════════════════════════════════════════════════════
# AMORTYZACJA / KŚT THRESHOLDS
# ═══════════════════════════════════════════════════════════════════════════════

depreciation := {
    # Art. 22d PIT — jednorazowa amortyzacja
    "one_off_low_value_limit": 10000,            # PLN (P481, P883)
    "one_off_de_minimis_limit": 100000,          # PLN rocznie (P482, P842)

    # Art. 22g PIT — ulepszenie
    "improvement_threshold": 10000,              # PLN — powyżej podwyższa podstawę (P884)

    # Art. 22k PIT — de minimis
    "de_minimis_annual_limit_eur": 50000,        # EUR rocznie
}

# ═══════════════════════════════════════════════════════════════════════════════
# BUSINESS / CEIDG THRESHOLDS
# ═══════════════════════════════════════════════════════════════════════════════

business := {
    # Art. 22 PP — zawieszenie
    "suspension_max_months": 6,                  # Max 6 mies. (P917)
    "suspension_social_due": false,               # Społeczne = 0 (P914)
    "suspension_health_due": true,                # Zdrowotna NADAL (P914, R0582)

    # Art. 22-25 PP — wznowienie
    "resumption_notice_days": 7,                  # 7 dni na VAT-R po wznowieniu

    # Sukcesja (ustawa o zarządzie sukcesyjnym)
    "succession_default_months": 24,              # 2 lata standardowo (P929d)
    "succession_extended_months": 60,             # 5 lat z sądem
    "succession_remnant_tax_rate": 0.10,          # 10% od remanentu likwidacyjnego (P928)
}

# ═══════════════════════════════════════════════════════════════════════════════
# LOCAL TAXES / OPŁATY LOKALNE (Klasa IX — Blind Spot §1.1 z STRATEGIC_IMPROVEMENTS_7000)
# ═══════════════════════════════════════════════════════════════════════════════
# Stawki 2026 wg obwieszczenia MF. Gminy mogą ustalać niższe stawki uchwałą.
# ═══════════════════════════════════════════════════════════════════════════════

local_taxes := {
    # Art. 5 UoPiOL — podatek od nieruchomości (stawki maksymalne 2026)
    "land_business_rate": 1.43,                  # PLN/m² — grunt związany z działalnością (P1310, P1338)
    "land_other_rate": 0.71,                     # PLN/m² — grunt pozostały (w tym prywatny)
    "building_business_rate": 33.10,             # PLN/m² — budynek firmowy (P1310, P1338)
    "building_residential_rate": 1.15,           # PLN/m² — budynek mieszkalny/prywatny

    # Art. 15-16 UoPiOL — opłata targowa
    "market_fee_max_daily": 800,                 # PLN/dzień — max stawka (P1335)

    # Art. 17 UoPiOL — opłata miejscowa
    "resort_fee_max_daily": 6.00,                # PLN/dzień — max stawka (P1336)

    # Art. 17a UoPiOL — opłata uzdrowiskowa
    "spa_fee_max_daily": 8.00,                   # PLN/dzień — max stawka (P1337)

    # Art. 9-14 UoPiOL — podatek od środków transportowych
    "transport_truck_3_5_5_5": 800,              # PLN/rok — DMC 3.5-5.5t (P1331)
    "transport_truck_5_5_9": 1000,               # PLN/rok — DMC 5.5-9t
    "transport_truck_9_12": 1400,                # PLN/rok — DMC 9-12t
    "transport_truck_12_plus": 2000,             # PLN/rok — DMC >12t
    "transport_trailer_3_5": 1200,               # PLN/rok — przyczepa (P1331)
    "transport_trailer_12_plus_3ax": 1800,       # PLN/rok — przyczepa >12t, 3+ osie
    "transport_tractor_unit_36": 2200,           # PLN/rok — ciągnik siodłowy ≤36t (P1332)
    "transport_tractor_unit_36_plus": 2800,      # PLN/rok — ciągnik siodłowy >36t
    "transport_bus_22": 1600,                    # PLN/rok — autobus <22 miejsc (P1333)
    "transport_bus_22_plus": 2400,               # PLN/rok — autobus ≥22 miejsc
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENVIRONMENTAL / BDO — Środowisko, odpady, WEEE, baterie, SUP
# ═══════════════════════════════════════════════════════════════════════════════
# Dodane 2026-07-17 z pakietów Enterprise BDO/AML/RODO/MDR
# ═══════════════════════════════════════════════════════════════════════════════

environmental := {
    # BDO — opłaty rejestracyjne
    "bdo_fee_micro_pln": 100,                    # PLN — mikroprzedsiębiorca (Art. 49 UoO)
    "bdo_fee_small_pln": 300,                    # PLN — mały przedsiębiorca (Art. 49 UoO)

    # Opakowania — poziomy recyklingu
    "packaging_recycling_target_pct": 60,         # % — cel recyklingu odpadów opakowaniowych

    # Baterie
    "battery_collection_target_pct": 45,          # % — cel zbiórki baterii (wzrasta do 73% w 2030)
    "battery_penalty_per_kg": 12.00,             # PLN/kg — opłata produktowa za nieosiągnięcie celu

    # WEEE (ZSEiE)
    "weee_penalty_per_kg": 15.00,                # PLN/kg — opłata produktowa WEEE

    # SUP (Single-Use Plastics)
    "sup_fee_rate": 0.25,                         # PLN/szt — opłata SUP od plastikowych opakowań
    "sup_epr_rate_per_kg": 0.80,                  # PLN/kg — opłata rozszerzonej odpowiedzialności producenta
}

# ═══════════════════════════════════════════════════════════════════════════════
# AML — Anti-Money Laundering
# ═══════════════════════════════════════════════════════════════════════════════

aml := {
    # Art. 72 Ustawy AML — próg gotówkowy w EUR
    "cash_threshold_eur": 10000,                  # EUR — obowiązek rejestracji transakcji gotówkowej

    # Art. 72 Ustawy AML — próg STR do GIIF
    "str_threshold_eur": 15000,                   # EUR — obowiązek zgłoszenia STR do GIIF
}

# ═══════════════════════════════════════════════════════════════════════════════
# MDR — Mandatory Disclosure Rules (DAC6)
# ═══════════════════════════════════════════════════════════════════════════════

mdr := {
    # Art. 86o OrdPU — kara administracyjna
    "daily_penalty_pln": 5000,                    # PLN/dzień — kara za każdy dzień zwłoki MDR-3
    "sanction_max_pln": 21000000,                 # PLN — maksymalna kara administracyjna (21 mln)

    # Art. 86n OrdPU, Art. 16a KKS — czynny żal
    "voluntary_disclosure_reduction_pct": 50,      # % — redukcja kary przy czynnym żalu
}

misc := {
    # Cash limit (Art. 22p PIT)
    "cash_payment_limit": 15000,                 # PLN (P653)
    "cash_sanction_rate": 0.20,                  # 20% sankcji

    # Split Payment / MPP
    "mpp_mandatory_threshold": 15000,            # PLN brutto (P650)
    "mpp_sanction_rate": 0.30,                   # 30% dodatkowego zobowiązania

    # PKPiR retention
    "pkpir_retention_years": 5,                  # 5 lat (P817)

    # Employment
    "employee_kup_creative_50pct": 0.50,         # 50% KUP dla twórców (P1200e)

    # Reprezentacja
    "poa_fee_pln": 17,                           # PLN — opłata skarbowa (P1200)
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEMPORAL VERSIONING — Progi zmienne w czasie (A2)
# ═══════════════════════════════════════════════════════════════════════════════
# Dla progów, które zmieniały się na przestrzeni lat.
# Używane przez is_active_for_date() z _metadata_jdg.rego.
# ═══════════════════════════════════════════════════════════════════════════════

temporal_thresholds := {
    # P189 — złe długi: 150 dni → 90 dni (SLIM VAT 3/2025-07-01)
    "bad_debt_days": {
        "valid_from": "2025-07-01",
        "value": 90,
        "previous_value": 150,
        "previous_valid_from": "2023-07-01",
        "reason": "SLIM VAT 3/2025 — obniżenie z 150 do 90 dni"
    },

    # P500 — kwota wolna: 30k (Polski Ład 2022)
    "tax_free_amount": {
        "valid_from": "2022-01-01",
        "value": 30000,
        "previous_value": 8000,
        "previous_valid_from": "2019-01-01",
        "reason": "Polski Ład 2022 — podwyższenie kwoty wolnej"
    },

    # P500 — próg skali: 85 528 → 120 000 (Polski Ład 2022)
    "scale_threshold": {
        "valid_from": "2022-01-01",
        "value": 120000,
        "previous_value": 85528,
        "previous_valid_from": "2019-01-01",
        "reason": "Polski Ład 2022 — podwyższenie progu"
    },

    # P523 — limit ryczałtu: 250k EUR → 2M EUR
    "lump_sum_annual_limit_eur": {
        "valid_from": "2022-01-01",
        "value": 2000000,
        "previous_value": 250000,
        "previous_valid_from": "2019-01-01",
        "reason": "Polski Ład 2022 — 8× wzrost limitu"
    },

    # P740 — ulga na start: 6 mies.
    "start_relief_months": {
        "valid_from": "2018-04-01",
        "value": 6,
        "reason": "Wprowadzenie ulgi na start"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS — Pobieranie progów z wersjonowaniem temporalnym
# ═══════════════════════════════════════════════════════════════════════════════

# Pobiera wartość progu aktywną na daną datę (z fallbackiem do wartości domyślnej)
get_temporal_threshold(threshold_key, eval_date) = value {
    t := temporal_thresholds[threshold_key]
    t.valid_from <= eval_date
    value := t.value
} else = value {
    t := temporal_thresholds[threshold_key]
    # Przed wejściem w życie — zwróć poprzednią wartość
    value := object.get(t, "previous_value", t.value)
}
