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

    # Art. 89a-89b VAT — ulga na złe długi (SLIM VAT 3/2023)
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

    # P34 FIX (Atak 24): Osobne definicje małego podatnika dla VAT, PIT, UoR
    # VAT: Art. 2 pkt 25 — przychód < 2M EUR z VATem (z podatkiem należnym!)
    # PIT: Art. 5a pkt 20 — przychód < 2M EUR bez VATu (wartość netto)
    # UoR: Art. 3 ust. 1c — przychód < 2M EUR (uproszczenia księgowe)
    "small_taxpayer_threshold_eur": 2000000,     # EUR — próg wspólny
    "small_taxpayer_vat_includes_vat": true,     # VAT: przychód Z VATem
    "small_taxpayer_pit_excludes_vat": true,     # PIT: przychód BEZ VATu
    "small_taxpayer_uor_excludes_vat": true,     # UoR: przychód BEZ VATu
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
    "gift_limit_pln": 200,                      # PLN — limit prezentów (Art. 23 ust. 1 pkt 34)
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

    # Art. 21 ust. 1 pkt 148-154 PIT — wspólny limit ulg PIT-0 (mlodzi, powrót, 4+, senior)
    "pit_relief_shared_limit": 85528,            # PLN — limit łączny ulg PIT-0 (2026)
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
    "health_linear_deduction_limit": 14100,      # PLN/rok max odliczenia (P563) — 2026=14100

    # Ryczałt zdrowotny — progi (P564) — zaktualizowane na 2026 (avg_wage=9100)
    # TIER_1: 60% × 9100 × 9% = 491.40 PLN/mies
    # TIER_2: 100% × 9100 × 9% = 819.00 PLN/mies
    # TIER_3: 180% × 9100 × 9% = 1474.20 PLN/mies
    "health_lump_tier_1_limit": 60000,           # PLN przychodu
    "health_lump_tier_2_limit": 300000,          # PLN przychodu
    "health_lump_tier_1_amount": 491.40,         # PLN/mies (60% przeciętnego 2026)
    "health_lump_tier_2_amount": 819.00,         # PLN/mies (100% przeciętnego 2026)
    "health_lump_tier_3_amount": 1474.20,        # PLN/mies (180% przeciętnego 2026)

    # Zasiłek chorobowy
    "sickness_waiting_days": 90,                 # 90 dni wyczekiwania (P578, ENTERPRISE P745)
    "sickness_benefit_rate": 0.80,               # 80% podstawy
    "sickness_hospital_rate": 0.70,              # 70% w szpitalu
    "sickness_annual_limit": 85528,              # PLN/rok — limit podstawy wymiaru zasiłku (2026)

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
    # Minimalne wynagrodzenie brutto (2026) — wg rozporządzenia RM
    "minimum_wage_gross": 4800,                  # PLN — od 1 stycznia 2026 (prognoza: 4800-4900)

    # Standardowa podstawa wymiaru składek ZUS (60% przeciętnego wynagrodzenia)
    "zus_social_base_standard": 5460.00,        # PLN — 60% × 9100 PLN (prognoza Q1-Q2 2026)

    # Przeciętne miesięczne wynagrodzenie (prognoza 2026 Q1, GUS)
    "avg_monthly_wage": 9100,                    # PLN — do obliczeń ZUS (prognoza 2026)

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
# FC THRESHOLDS — Field Confidence progi dla routingu (Recomendacja 6.4)
# ═══════════════════════════════════════════════════════════════════════════════

fc_thresholds := {
    "nip": 0.80,                                 # NIP confidence threshold
    "vat_rate": 0.95,                            # VAT rate confidence threshold
    "minimum": 0.70,                             # General minimum confidence
    "linear_min": 0.85,                          # Linear tax confidence threshold
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTING CONFIDENCE — Progi ufności dla poszczególnych pól (Recomendacja 6.4)
# ═══════════════════════════════════════════════════════════════════════════════

routing_confidence := {
    "vat_rate_block": 0.95,                      # BLOCK_AND_ALERT poniżej
    "nip_block": 0.80,                           # BLOCK_AND_ALERT poniżej
    "minimum_triage": 0.70,                      # TRIAGE_QUEUE poniżej
    "linear_min_block": 0.85,                    # BLOCK dla liniowego
}

# ═══════════════════════════════════════════════════════════════════════════════
# API FALLBACK — Progi degradacji API (Recomendacja 6.4)
# ═══════════════════════════════════════════════════════════════════════════════

api_fallback := {
    "multi_degraded_threshold": 3,               # Liczba API offline → BLOCK
    "min_operational_pct": 0.50,                 # 50% API musi działać
}

# ═══════════════════════════════════════════════════════════════════════════════
# CHECKSUM WEIGHTS — Wagi dla NIP/REGON (Rekomendacja 6.4)
# Eksternalizacja z validation.rego (wcześniej hardcoded).
# ═══════════════════════════════════════════════════════════════════════════════

checksum_weights := {
    # NIP: modulo 11, wagi [6,5,7,2,3,4,5,6,7]
    "nip": [6, 5, 7, 2, 3, 4, 5, 6, 7],
    # REGON 9-cyfrowy: wagi [8,9,2,3,4,5,6,7], modulo 11
    "regon9": [8, 9, 2, 3, 4, 5, 6, 7],
    # REGON 14-cyfrowy: wagi [2,4,8,5,0,9,7,3,6,1,2,4,8], modulo 11
    "regon14": [2, 4, 8, 5, 0, 9, 7, 3, 6, 1, 2, 4, 8]
}

# ═══════════════════════════════════════════════════════════════════════════════
# AGGREGATED LIMITS — Zagregowane progi dla helperów get_jdg_limit()
# Klucze mapują się na wartości z powyższych sekcji domenowych.
# ═══════════════════════════════════════════════════════════════════════════════

limits := {
    "vat_subject_exemption": vat.subject_exemption_limit,
    "pit_scale_threshold": pit.scale_threshold,
    "pit_tax_free_amount": pit.tax_free_amount,
    "car_value_limit_standard": pit.car_value_limit_standard,
    "car_value_limit_ev": pit.car_value_limit_ev,
    "car_lease_insurance_limit": pit.car_lease_insurance_limit,
    "representation_limit_pct": pit.representation_limit_pct,
    "donation_limit_pct": pit.donation_limit_pct,
    "maly_zus_plus_income_limit": zus.maly_zus_plus_income_limit,
    "maly_zus_plus_revenue_limit": zus.maly_zus_plus_revenue_limit,
    "health_linear_deduction_limit": zus.health_linear_deduction_limit,
    "pit_relief_shared_limit": pit.pit_relief_shared_limit,
    "health_lump_tier_1_limit": zus.health_lump_tier_1_limit,
    "health_lump_tier_2_limit": zus.health_lump_tier_2_limit,
    "sickness_waiting_days": zus.sickness_waiting_days,
    "start_relief_months": zus.start_relief_months,
    "maly_zus_plus_months": zus.maly_zus_plus_months,
    "preferential_months": zus.preferential_months,
    "cash_payment_limit": misc.cash_payment_limit,
    "mpp_mandatory_threshold": misc.mpp_mandatory_threshold,
    "one_off_low_value": depreciation.one_off_low_value_limit,
    "one_off_de_minimis": depreciation.one_off_de_minimis_limit,
    "improvement_threshold": depreciation.improvement_threshold,
    "de_minimis_annual_eur": depreciation.de_minimis_annual_limit_eur,
    "lump_sum_annual_eur": lump_sum.annual_limit_eur,
    "statute_of_limitations_years": ord.statute_of_limitations_years,
    "suspension_max_months": business.suspension_max_months,
    "succession_default_months": business.succession_default_months,
    "succession_extended_months": business.succession_extended_months,
    "succession_remnant_tax_rate": business.succession_remnant_tax_rate,
    "minimum_wage_gross": bounds.minimum_wage_gross,
    "avg_monthly_wage": bounds.avg_monthly_wage,
    "zus_social_base_standard": bounds.zus_social_base_standard,
    "trust_auto_post": 0.92,                     # Próg auto-post dla risk.rego P1
    "pkpir_integrity_min": 0.70,                 # Min integrity score PKPiR
    "kks_discrepancy_threshold": 0.30,           # Próg rozbieżności KKS Art.54
}

# ═══════════════════════════════════════════════════════════════════════════════
# AGGREGATED RATES — Zagregowane stawki dla helperów get_jdg_rate()
# ═══════════════════════════════════════════════════════════════════════════════

rates := {
    "vat_standard": vat.standard_rate,
    "vat_reduced_8": vat.reduced_rate_8,
    "vat_reduced_5": vat.reduced_rate_5,
    "vat_zero": vat.zero_rate,
    "pit_scale_low": pit.scale_low_rate,
    "pit_scale_high": pit.scale_high_rate,
    "pit_linear": pit.linear_rate,
    "pit_ip_box": pit.ip_box_rate,
    "pit_exit_tax": pit.exit_tax_rate,
    "car_vat_deduction_no_log": vat.car_vat_deduction_no_log,
    "car_vat_deduction_with_log": vat.car_vat_deduction_with_log,
    "car_kup_no_log": pit.car_kup_no_log,
    "car_kup_with_log": pit.car_kup_with_log,
    "health_scale": zus.health_scale_rate,
    "health_linear": zus.health_linear_rate,
    "health_lump_tier_1": zus.health_lump_tier_1_amount,
    "health_lump_tier_2": zus.health_lump_tier_2_amount,
    "health_lump_tier_3": zus.health_lump_tier_3_amount,
    "sickness_benefit": zus.sickness_benefit_rate,
    "sickness_hospital": zus.sickness_hospital_rate,
    "pension": zus.pension_rate,
    "disability": zus.disability_rate,
    "sickness_voluntary": zus.sickness_voluntary_rate,
    "accident": zus.accident_rate,
    "labour_fund": zus.labour_fund_rate,
    "eur_pln": bounds.eur_pln,
    "mileage_rate": bounds.mileage_rate_per_km,
    "business_trip_diet": bounds.business_trip_diet,
    "lump_2pct": lump_sum.rate_2pct,
    "lump_3pct": lump_sum.rate_3pct,
    "lump_5_5pct": lump_sum.rate_5_5pct,
    "lump_8_5pct": lump_sum.rate_8_5pct,
    "lump_12pct": lump_sum.rate_12pct,
    "lump_15pct": lump_sum.rate_15pct,
    "lump_17pct": lump_sum.rate_17pct,
    "bad_debt_sanction": vat.bad_debt_sanction_30pct,
    "cash_sanction": misc.cash_sanction_rate,
    "mpp_sanction": misc.mpp_sanction_rate,
    "additional_tax": ord.additional_tax_rate_pct,
    "tax_interest": ord.tax_interest_rate,
    "unregistered_revenue": ord.unregistered_revenue_pct,
}

# ═══════════════════════════════════════════════════════════════════════════════
# EARLY WARNING — Progi ostrzegawcze (80% limitów) — STRATEGIC INITIATIVE S23
# ═══════════════════════════════════════════════════════════════════════════════
# System wczesnego ostrzegania przed przekroczeniem kluczowych limitów.
# Alert przy 80% wykorzystania — proaktywne zarządzanie ryzykiem JDG.
# ═══════════════════════════════════════════════════════════════════════════════

early_warning := {
    # Ryczałt — limit 2M EUR = ~9M PLN przy EUR=4.50
    "lump_sum_eur_80pct": 1600000,               # 80% × 2M EUR → alert

    # PIT-0 — wspólny limit 85 528 PLN
    "pit0_80pct": 68422,                         # 80% × 85 528 PLN

    # Skala PIT — próg 120 000 PLN
    "scale_threshold_80pct": 96000,              # 80% × 120 000 PLN

    # Liniowy — limit odliczenia zdrowotnej 14 100 PLN (2026)
    "health_deduction_80pct": 11280,             # 80% × 14 100 PLN

    # Mały ZUS Plus — limit przychodu 120 000 PLN
    "maly_zus_plus_80pct": 96000,                # 80% × 120 000 PLN

    # Jednorazowa amortyzacja de minimis — 50 000 EUR
    "de_minimis_80pct_eur": 40000,               # 80% × 50 000 EUR

    # Zwolnienie podmiotowe VAT — 200 000 PLN
    "vat_exemption_80pct": 160000,               # 80% × 200 000 PLN

    # Cash payment limit — 15 000 PLN
    "cash_limit_80pct": 12000,                   # 80% × 15 000 PLN
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEMPORAL VERSIONING — Progi zmienne w czasie (A2)
# ═══════════════════════════════════════════════════════════════════════════════
# Dla progów, które zmieniały się na przestrzeni lat.
# Używane przez is_active_for_date() z _metadata_jdg.rego.
# ═══════════════════════════════════════════════════════════════════════════════

temporal_thresholds := {
    # P189 — złe długi: 150 dni → 90 dni (SLIM VAT 3/2023-07-01)
    "bad_debt_days": {
        "valid_from": "2023-01-01",
        "value": 90,
        "previous_value": 150,
        "previous_valid_from": "2020-01-01",
        "reason": "SLIM VAT 3 (2023-01-01) — obniżenie z 150 do 90 dni dla ulgi na złe długi"
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
