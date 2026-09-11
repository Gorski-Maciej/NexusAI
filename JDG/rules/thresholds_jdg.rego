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
# architecture: Decoupled Data Layer (B2)
# package: jdg.thresholds
# deprecated: false
#

package jdg.thresholds

import future.keywords.in

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
    "car_vat_deduction_limit_standard": 150000,   # PLN — limit wartości auta standard (Art. 86a VAT)
    "car_vat_deduction_limit_ev": 225000,         # PLN — limit wartości auta EV (Art. 86a VAT)

    # Art. 87 VAT — terminy zwrotu
    "vat_refund_standard_days": 60,              # 60 dni standardowo (P587)
    "vat_refund_accelerated_days": 25,           # 25 dni przyśpieszony (P589)

    # Art. 90 VAT — proporcja
    "proportion_min_threshold": 0.02,            # 2% — poniżej = 0% odliczenia (P553)
    "proportion_max_threshold": 0.98,            # 98% — powyżej = 100% odliczenia

    # OSS/IOSS (Art. 28l, 130a-138j VAT) — próg 10 000 EUR B2C
    "oss_threshold_eur": 10000,                  # EUR — próg OSS (P02 P1)
    "oss_alert_eur": 5000,                       # EUR — alert zbliżania się do progu OSS

    # Odwrotne obciążenie — odpady (Art. 17 ust. 1 pkt 7 VAT)
    "reverse_charge_waste_threshold": 20000,     # PLN — próg netto dla odpadów (P73)

    # Monitor limitu art. 113 (P02) — alert przy 95% limitu
    "a113_alert_ratio": 0.95,                    # 95% limitu — alert prewencyjny

    # Alerty cashflow VAT (P02) — progi BLOCK_AND_ALERT
    "cashflow_alert_pay_threshold": 100000,      # PLN — alert kwoty do zapłaty
    "cashflow_alert_net_impact": 50000,          # PLN — alert ujemnego wpływu netto
    "cashflow_mpp_frozen_alert": 100000,         # PLN — alert zamrożonych środków MPP
    "cashflow_bad_debt_reclaim_alert": 5000,     # PLN — alert odzyskiwalnego VAT (złe długi)

    # Fraud detection (P02) — progi scoringu ryzyka
    "fraud_round_amount_min": 1000,              # PLN — okrągła kwota ≥ 1000 = wskaźnik fraudu

    # Art. 91 VAT — korekta wieloletnia środków trwałych
    "asset_correction_threshold": 15000,          # PLN — ≥ 15 000 → korekta 5/10 lat (P02)

    # Art. 120 VAT — marża: alert wysokiej marży (P02)
    "margin_alert_threshold": 50000,              # PLN — alert weryfikacji dokumentacji

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

    # ════════════════════════════════════════════════════════════════════════
    # V3-P13 VAT DEDUCTIONS / MPP / FRAUD ENTERPRISE (kampania V3 FORTRESS)
    # ADR-002 zero hardcode — progi odliczeń, MPP, Biała Listy, fraud.
    # ════════════════════════════════════════════════════════════════════════
    # V3-P13-I01: Deduction Rights Engine (art. 86b VAT — moment odliczenia)
    "deduction_moment_months": 3,                # odliczenie w miesiącu faktury lub 2 następnych
    "deduction_prefinancing_months": 3,          # art. 86b ust. 2 — prefinansowanie (3 miesiące)
    "blocked_deduction_categories": ["NKUP", "paliwo_osobowe", "noclegi", "gastronomia", "bez_dokumentu"],
    # V3-P13-I02: Multi-Year Correction Planner (art. 91 VAT)
    "multi_year_years_real_estate": 10,          # nieruchomości — 10 lat
    "multi_year_years_other": 5,                 # pozostałe środki trwałe — 5 lat
    "multi_year_years_low_value": 1,             # < 15 000 zł — 1 rok
    # V3-P13-I05: Annex 15 as Versioned Data (MPP zał. 15 VAT)
    "annex15_data_version": "2026-09",
    "annex15_valid_from": "2019-11-01",
    "annex15_cn_codes": ["01", "02", "03", "04", "07", "08", "10", "12", "15", "17", "18", "19", "20", "21", "22", "23", "24", "25", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "44", "48", "49", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "78", "79", "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", "93", "94", "95", "96"],
    # V3-P13-I06: White List Gate (art. 96b VAT)
    "whitelist_check_threshold_pln": 15000,      # weryfikacja przed przelewem > 15 000 zł
    "whitelist_cache_ttl_hours": 24,             # cache TTL
    "whitelist_fallback_mode": "NEEDS_ADVICE",  # offline → NEEDS_ADVICE
    # V3-P13-I07: Fraud Signal Framework (art. 105a-105c VAT)
    "fraud_score_high": 60,                      # HIGH ≥ 60
    "fraud_score_medium": 30,                    # MEDIUM ≥ 30
    "fraud_human_review_required": true,         # human review WYMUSZONY (nigdy wina)
    # V3-P13-I10: VAT Stress Lab (P37/P39)
    "stress_scenario_size": 1000,                # 1000 faktur MPP jednocześnie
    "stress_latency_budget_ms": 1000,            # budżet opóźnienia < 1s
    "stress_throughput_target": 100,             # > 100 decyzji/s
    "v3_p13_threshold_version": "vat-deductions-v3p13-2026.09",
    "threshold_version": "vat-deductions-2026.08",
    "legal_basis_version": "isap-lkg-2026.08",
    "valid_from": "2025-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# KSeF + JPK + e-DEKLARACJE — data.jdg.thresholds.ksef_jpk_edeklaracje (P17)
# Dane dla pakietu jdg.p17_ksef_jpk_edeklaracje_innovations (fallback w pakiecie).
#   P0-1: rzeczywista integracja API KSeF (produkcyjna wysyłka + UPO via API)
#   P0-2: pełny walidator XSD offline (Java/xmllint) w CI
#   P1-1: korekty KSeF end-to-end (art. 106j VAT) + anulowanie faktur
#   P1-2: baza GTU z pełnym słownikiem 13 kodów + uczenie z historii
#   P1-3: integracja e-Doręczeń (skrzynka B2B/B2G + potwierdzenia)
#   P2-1: dashboard KSeF (status UPO, kara, rejestry) w UI
#   P2-2: automatyzacja JPK_CIT wg szablonu MF 2026
# ═══════════════════════════════════════════════════════════════════════════════

ksef_jpk_edeklaracje := {
    "threshold_version": "ksef-jpk-2026.08",      # Golden Oracle F3 (kampania V3, część 11)
    "legal_basis_version": "vat-106na-2026-02-01; edor-1598-2026-01-01", # Legal Twin
    "ksef_mandatory_from": "2026-02-01",          # art. 106na-106nb VAT
    "ksef_offline_grace_days": 7,
    "ksef_sanction_max_pln": 500000,
    "ksef_sanction_70_cap_pln": 300000,           # opóźnienie >24h: 70% VAT, max 300k
    "ksef_sanction_50_cap_pln": 250000,           # czynny żal: 50% VAT, max 250k
    "ksef_zaw_nr_penalty_pln": 5000,              # brak ZAW-NR (KKS)
    "ksef_queue_warning_hours": 120,              # alert 5 dni przed końcem okna 168h
    "ksef_outbox_priority_threshold_pln": 50000,  # faktura HIGH w outbox
    "ksef_upo_deadline_days": 1,
    "jpk_v7_deadline_day": 25,
    "jpk_ksef_penalty_per_invoice": 1000,
    "jpk_cit_payment_tier_high_pln": 10000,       # estoński CIT — kwartalny próg płatności
    "jpk_cit_payment_tier_low_pln": 5000,
    "jpk_cit_revenue_eur_limit": 2000000,         # limit 2 mln EUR przychodu (estoński CIT)
    "jpk_kr_threshold_eur": 2000000,              # JPK_KR — próg ksiąg rachunkowych
    "jpk_kr_discrepancy_alert_pln": 10000,        # JPK_KR vs księgi — alert rozbieżności
    "wis_application_fee_pln": 40,                # opłata za WIS (art. 42b VAT)
    "wis_expiry_warning_days": 180,               # WIS ważny 5 lat — alert 6 mies. przed wygaśnięciem
    "wis_expiry_critical_days": 90,               # alert krytyczny 3 mies. przed wygaśnięciem
    "wdt_alert_days": 25,                         # WDT — alert 25 dni przed terminem 30 dni
    "wdt_deadline_days": 30,                      # WDT — termin dostarczenia dokumentów
    "esig_qualified": true,
    "esig_trusted": true,
    "edelivery_mandatory_from": "2026-01-01",
    "wis_response_days": 3,
    "ksef_sandbox": true,
    "gtu_codes": ["GTU_01", "GTU_02", "GTU_03", "GTU_04", "GTU_05", "GTU_06", "GTU_07", "GTU_08", "GTU_09", "GTU_10", "GTU_11", "GTU_12", "GTU_13"],

    # ── P0-1: API KSeF — produkcyjna wysyłka + UPO ──
    "ksef_api": {
        "endpoint_prod": "https://ksef.mf.gov.pl/api",
        "endpoint_sandbox": "https://ksef-test.mf.gov.pl/api",
        "auth": "token KSeF (nabywca/sprzedawca)",
        "ksef_number_required": true,
        "upo_via_api": true,
        "retry_on_failure": true,
        "max_retries": 3,
    },

    # ── P0-2: walidator XSD offline (CI) ──
    "xsd_offline_ci": {
        "validator": "xmllint/Java JAXB (offline)",
        "schemas": ["FA(2)", "FA(2)-korekta", "KSeF 2.0 (plan)"],
        "ci_gate": true,
        "block_on_invalid": true,
        "required_fields": ["P_1", "P_2", "P_3", "P_4", "P_5", "P_6", "P_7", "P_8"],
    },

    # ── P1-1: korekty KSeF end-to-end (art. 106j VAT) ──
    "ksef_corrections": {
        "correction_deadline_days": 30,             # art. 106j VAT
        "cancellation_allowed": true,
        "negative_invoice_allowed": true,
        "legal_basis": "Art. 106j VAT",
        "correction_reasons": ["błąd danych nabywcy", "błąd kwoty", "błąd stawki", "zwrot towaru", "rabat", "anulowanie faktury"],
    },

    # ── P1-2: baza GTU — pełny słownik 13 kodów ──
    "gtu_dictionary": [
        {"code": "GTU_01", "name": "dostawa towarów innych niż wymienione w GTU_02-GTU_13", "hint": "dostawa towarów"},
        {"code": "GTU_02", "name": "wyroby tytoniowe, papierosy, susz tytoniowy", "hint": "napoje alkoholowe / tytoń"},
        {"code": "GTU_03", "name": "napoje alkoholowe i spirytusowe", "hint": "wyroby tytoniowe"},
        {"code": "GTU_04", "name": "paliwa i oleje opałowe", "hint": "paliwa"},
        {"code": "GTU_05", "name": "wyroby wrażliwe (węgiel, kożuchy, elektronika)", "hint": "towary wrażliwe"},
        {"code": "GTU_06", "name": "odpady i złom", "hint": "odpady"},
        {"code": "GTU_07", "name": "usługi transportowe i spedycyjne", "hint": "usługi transportowe"},
        {"code": "GTU_08", "name": "usługi niematerialne (w tym IT)", "hint": "usługi niematerialne"},
        {"code": "GTU_09", "name": "wierzytelności i faktury", "hint": "wierzytelności"},
        {"code": "GTU_10", "name": "nieruchomości", "hint": "nieruchomości"},
        {"code": "GTU_11", "name": "usługi świadczone drogą elektroniczną", "hint": "usługi w internecie"},
        {"code": "GTU_12", "name": "energia elektryczna, gaz, ciepło", "hint": "energia"},
        {"code": "GTU_13", "name": "uprawnienia do emisji gazów cieplarnianych", "hint": "emisje CO2"},
    ],
    "gtu_learning_enabled": true,                  # uczenie z historii transakcji

    # ── P1-3: e-Doręczenia B2B/B2G + potwierdzenia ──
    "edelivery_b2b_b2g": {
        "mailbox_api": "https://edoreczenia.gov.pl/api",
        "b2b_enabled": true,
        "b2g_enabled": true,
        "confirmation_required": true,
        "confirmation_type": "DORECZENIE_POTWIERDZONE",
        "mandatory_from": "2026-01-01",
    },

    # ── P2-1: dashboard KSeF (UI) ──
    "ksef_dashboard": {
        "widgets": ["status_upo", "kara_ryzyko", "rejestry_jpk", "korekty_pending", "gtu_coverage", "x_doręczenia"],
        "refresh": "na żywo (hot-reload ADR-002)",
        "export_formats": ["JSON", "CSV", "PDF"],
    },

    # ── P2-2: JPK_CIT — szablon MF 2026 ──
    "jpk_cit_2026": {
        "template": "Szablon JPK_CIT v2 (MF 2026)",
        "structure_version": "2.0",
        "deadline_day": 31,
        "frequency": "rocznie (I kw.)",
        "sections": ["bilans", "rachunek_zyskow_i_strat", "informacja_dodatkowa", "dane_podatkowe"],
        "entities": ["CIT_OSOBA_PRAWNA", "CIT_OSOBA_FIZYCZNA_JDG"],
    },

    # ── V3-P16 (kampania V3 FORTRESS): KSeF/JPK ENTERPRISE — I01..I12 ──
    # Klucze warstwy enterprise V3-P16 (rozszerzenie — zero duplikacji):
    # sesje KSeF (I01), offline RPO=0/WAL (I02), UPO sentinel (I03),
    # pre-send firewall (I04), kalendarz terminów (I05), kontrakt pól JPK
    # (I06), korekty idempotentne (I07), sandbox CI (I08), chaos drill 72h
    # (I09), e-Doręczenia chain (I10), kary progresywne (I11), golden set (I12).
    "v3_p16_threshold_version": "ksef-jpk-v3p16-2026.09",
    "v3_p16_session_max_retries": 3,              # I01: retry sesji KSeF
    "v3_p16_offline_window_hours": 168,           # I01/I02: okno offline 7 dni (art. 106na)
    "v3_p16_wal_required": true,                  # I02: Write-Ahead Log — RPO=0
    "v3_p16_offline_rpo_hours": 0,                # I02/I09: RPO=0 (zero utraty)
    "v3_p16_offline_rto_hours": 4,                # I02/I09: RTO cel 4h
    "v3_p16_upo_timeout_hours": 24,               # I03: timeout UPO → alarm
    "v3_p16_upo_escalation_hours": 48,            # I03: eskalacja
    "v3_p16_edelivery_status_timeout_hours": 24,  # I10: status e-Doręczeń
    "v3_p16_sandbox_cadence_days": 7,             # I08: cotygodniowy sandbox CI
    "v3_p16_chaos_drill_hours": 72,               # I09: KSeF down 72h
    "v3_p16_golden_set_version": "ksef-jpk-golden-2026.09",  # I12
    "v3_p16_deadlines": {                          # I05: kalendarz terminów (dane)
        "vat7_day": 25,
        "jpk_v7_day": 25,
        "pit36_deadline": "04-30",
        "pit28_deadline": "02-28",
        "jpk_pkpir_day": 20,
        "zus_dra_day": 20,
        "weekend_shift": true,
        "holiday_shift": true,
        "alert_days_before": 7,
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# AUTOMATYZACJA KSIĘGOWOŚCI — data.jdg.thresholds.automatyzacja_ksiegowosci (P18)
# Dane dla pakietu jdg.p18_automatyzacja_ksiegowosci_innovations (fallback w pakiecie).
#   P0-1: realna integracja AIS/PIS (PolishAPI) — token OAuth2, konsent PSD2
#   P0-2: weryfikacja SCA w środowisku produkcyjnym banku (RTS 2018/389)
#   P1-1: pełny silnik auto-fill PIT-36/36L/28 z UoR (sprawozdania finansowe)
#   P1-2: integracja e-Doręczeń B2B/B2G + potwierdzenia doręczenia
#   P1-3: model ML predykcji cashflow (historia płatności)
#   P2-1: dashboard wirtualnego asystenta księgowego w UI
#   P2-2: automatyzacja korekt deklaracji (art. 81 OrdPU) end-to-end
# ═══════════════════════════════════════════════════════════════════════════════

automatyzacja_ksiegowosci := {
    "elixir_cutoff_time": "14:30",
    "express_elixir_cutoff_time": "15:30",
    "sca_exempt_threshold_pln": 100,             # RTS 2018/389 art. 11
    "sca_exempt_max_per_tx": 5,
    "mpp_threshold_pln": 15000,
    "remnant_significance_limit": 50000,       # PLN — próg istotności remanentu (P01 v9.x)
    "cross_check_discrepancy_limit": 5000,      # PLN — próg rozbieżności przychodów (P01 v9.x)
    "mileage_log_recommendation_limit": 50000,  # PLN — auto > 50k bez ewidencji -> TRIAGE (P01 v9.x)
    "health_tier_low": 60000,                   # PLN — próg składki zdrowotnej dolny (P01 v9.x)
    "health_tier_high": 300000,                 # PLN — próg składki zdrowotnej górny (P01 v9.x)
    "pfron_rate": 0.4065,                       # współczynnik PFRON (Art. 21 ustawy o rehabilitacji, P01 v9.x)
    "high_value_tx_threshold": 15000,           # PLN — transakcja wysokiej wartości (adaptive trust, P01 v9.x)
    "revenue_triage_limit": 100000,            # PLN — przychód > 100k -> BLOCK_AND_ALERT (P01 v9.x)
    "cost_triage_limit": 50000,                # PLN — koszt towarów > 50k -> BLOCK_AND_ALERT (P01 v9.x)
    "vat7_deadline_day": 25,
    "zus_dra_deadline_day": 10,
    "pit_deadline_annual": "2026-04-30",
    "pcc3_deadline_days": 14,
    "wis_response_days": 3,
    "overpayment_interest_days": 30,
    "transfer_reconciliation_gap_pln": 0.01,
    "jpk_v7_deadline_day": 25,

    # ── P0-1: AIS/PIS (PolishAPI) — token OAuth2 + konsent PSD2 ──
    "ais_pis_api": {
        "standard": "PolishAPI",
        "endpoint": "https://api.bank.pl/polishapi",
        "auth": "OAuth2 (Authorization Code + PKCE)",
        "ais_scope": "ais (konto) / ais_transactions / ais_balances",
        "pis_scope": "pis (płatności) / pis_creation / pis_cancellation",
        "consent_required": true,                # konsent PSD2 (art. 94)
        "consent_lifetime_days": 90,             # ważność konsentu (co do zasady 90 dni)
        "token_refresh": true,
        "sandbox_available": true,
    },

    # ── P0-2: weryfikacja SCA w środowisku produkcyjnym banku ──
    "sca_production": {
        "verification_required": true,           # test SCA w produkcji banku
        "rts": "RTS 2018/389 art. 11-12",
        "exempt_threshold_pln": 100,
        "exempt_max_per_tx": 5,
        "test_transactions_min": 3,              # min. liczba testów SCA
        "sca_methods": ["biometria", "sms_otp", "app_mobile", "token_hw"],
    },

    # ── P1-1: auto-fill PIT-36/36L/28 z UoR ──
    "pit_uor_autofill": {
        "forms": ["PIT-36", "PIT-36L", "PIT-28"],
        "sources": ["UoR (bilans, RZiS)", "PKPiR", "rejestry VAT", "wyciągi bankowe", "faktury KSeF"],
        "deadline": "2026-04-30",
        "uor_sections": ["bilans", "rachunek_zyskow_i_strat", "informacja_dodatkowa"],
        "required_blocks": ["przychody", "koszty", "dochód", "zaliczki", "składki_zdrowotne"],
    },

    # ── P1-2: e-Doręczenia B2B/B2G + potwierdzenia ──
    "edelivery_b2b_b2g": {
        "mailbox_api": "https://edoreczenia.gov.pl/api",
        "b2b_enabled": true,
        "b2g_enabled": true,
        "confirmation_required": true,
        "confirmation_type": "DORECZENIE_POTWIERDZONE",
        "mandatory_from": "2026-01-01",
    },

    # ── P1-3: model ML predykcji cashflow ──
    "ml_cashflow": {
        "model": "gradient_boosting (historia płatności)",
        "features": ["średnia_płatności_30d", "sezonowość", "zaległości_klientów", "saldo_bank", "zobowiązania_podatkowe"],
        "lookback_months": 12,
        "horizon_days": 30,
        "confidence_min_pct": 70,
    },

    # ── P2-1: dashboard wirtualnego asystenta księgowego ──
    "bookkeeper_dashboard": {
        "widgets": ["ksiegowania", "deklaracje", "terminy", "przepływy", "pisma", "korekty"],
        "refresh": "na żywo (hot-reload ADR-002)",
        "export_formats": ["JSON", "CSV", "PDF"],
    },

    # ── P2-2: korekty deklaracji (art. 81 OrdPU) end-to-end ──
    "declaration_corrections": {
        "legal_basis": "Art. 81 OrdPU (korekta deklaracji)",
        "correction_deadline_days": 30,
        "auto_fill_correction": true,
        "interest_calculation": true,             # odsetki od niedopłaty przy korekcie
        "reasons": ["błąd rachunkowy", "zmiana przepisów", "pomyłka w danych", "dodatkowe dokumenty"],
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# HR I ŚWIADCZENIA — data.jdg.thresholds.hr_swiadczenia (P19)
# Dane dla pakietu jdg.p19_hr_swiadczenia_innovations (fallback w pakiecie).
#   P0-1: pełny moduł płac end-to-end (brutto→netto→ZUS→PIT-4→wypłata)
#   P0-2: integracja z Płatnikiem ZUS (import/eksport list płac)
#   P1-1: panel świadczeń rodzinnych z automatycznymi wnioskami do ZUS/MPiPS
#   P1-2: kalkulator wynagrodzeń z uwzględnieniem kwoty wolnej i ulg (PIT-2)
#   P1-3: tracker PPK z pełną automatyzacją wpłat (2% + 1.5%)
#   P2-1: dashboard HR (urlopy, płace, PFRON) w UI
#   P2-2: e-wnioski pracownicze (urlop, siła wyższa) z auto-akceptacją
# ═══════════════════════════════════════════════════════════════════════════════

hr_swiadczenia := {
    "kup_dojazdy_pln": 300,                        # KUP dojazdów (art. 22 ust. 2 pkt 4 u.PIT)
    "zus_emerytalna_pct": 9.76,
    "zus_rentowa_pct": 1.5,
    "zus_chorobowa_pct": 2.45,
    "zus_zdrowotna_pct": 9.0,
    "pit_advance_pct": 12.0,
    "force_majeure_days_max": 2,                  # art. 148¹ KP
    "force_majeure_pay_pct": 50,
    "family_800_plus_pln": 800,
    "family_zasiłek_pln": 135,
    "ppk_employee_pct": 2.0,
    "ppk_employer_pct": 1.5,
    "pfron_threshold_employees": 25,
    "pfron_fee_per_etat_pln": 40.75,
    "solidarity_donation_pct": 0.5,
    "odprawa_months_max": 3,
    "zamowienia_do_30k_pln": 30000,
    "reklama_limit_pct": 0.25,

    # ── P0-1: pełny moduł płac end-to-end ──
    "payroll_e2e": {
        "steps": ["1. brutto", "2. ZUS pracownika", "3. zdrowotna", "4. PIT-4", "5. wypłata netto", "6. ZUS pracodawcy", "7. FP/FGŚP"],
        "required_steps": 7,
        "deadline_payday": 10,                    # art. 85 KP
        "auto_payroll": true,
    },

    # ── P0-2: integracja z Płatnikiem ZUS ──
    "platnik_zus": {
        "import_payroll": true,
        "export_payroll": true,
        "format": "IMPORT ZUS (XML) / EXPORT lista płac",
        "zua_deadline_days": 7,                    # zgłoszenie do ZUS ZUA w 7 dni
        "legal_basis": "Ustawa o systemie ubezpieczeń społecznych; Płatnik ZUS (PUE)",
    },

    # ── P1-1: panel świadczeń rodzinnych + auto-wnioski ──
    "family_benefits_panel": {
        "benefits": ["800+", "zasiłek rodzinny", "dodatek z tytułu samotnego wychowania", "świadczenie dobry start 300+"],
        "auto_application": true,                  # auto-wniosek do ZUS/MPiPS
        "targets": ["ZUS (e-wniosek)", "MPiPS"],
        "application_deadline": "800+ od 1 lutego",
    },

    # ── P1-2: kalkulator wynagrodzeń z kwotą wolną i ulgami (PIT-2) ──
    "salary_tax_optimized": {
        "pit2_monthly_relief_pln": 300,            # ulga PIT-2 — 300 zł/mies. (art. 31c u.PIT)
        "tax_free_amount_annual_pln": 30000,       # kwota wolna (od 2022)
        "pit2_applicable": true,
        "legal_basis": "Art. 31c u.PIT (PIT-2); art. 27 ust. 1 u.PIT (kwota wolna)",
    },

    # ── P1-3: tracker PPK z pełną automatyzacją wpłat ──
    "ppk_auto": {
        "employee_pct": 2.0,
        "employer_pct": 1.5,
        "auto_contributions": true,                # auto-wpłaty z listy płac
        "deadline_payment_day": 15,                # do 15. dnia następnego miesiąca
        "obligation_after_days": 90,               # obowiązek po 90 dniach zatrudnienia
    },

    # ── P2-1: dashboard HR w UI ──
    "hr_dashboard": {
        "widgets": ["urlopy", "płace", "PFRON", "PPK", "świadczenia", "e-wnioski"],
        "refresh": "na żywo (hot-reload ADR-002)",
        "export_formats": ["JSON", "CSV", "PDF"],
    },

    # ── P2-2: e-wnioski pracownicze z auto-akceptacją ──
    "ewnioski": {
        "types": ["urlop wypoczynkowy", "siła wyższa (art. 148¹ KP)"],
        "auto_approval": true,                     # auto-akceptacja wniosków spełniających kryteria
        "approval_flow": "wniosek → weryfikacja → auto-akceptacja → kalendarz/lista płac",
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# NEURAL MESH + INNOWACJE — data.jdg.thresholds.neural_mesh (P20)
# Dane dla pakietu jdg.p20_neural_mesh_innovations (fallback w pakiecie).
#   P0-1: pełna implementacja strategic_roadmap (mapa 5-letnia, transformacja)
#   P0-2: pełna implementacja judicial_trend + cross_jurisdiction_ruling
#   P1-1: integracja z legislacja.gov.pl (API projektów ustaw) — radar live
#   P1-2: baza orzecznictwa NSA/WSA z parserem sygnatur
#   P1-3: propagacja pewności w pełnym grafie reguł (P01-P20)
#   P2-1: UI panelu SRO (orzecznictwo → zmiany reguł)
#   P2-2: symulator nowelizacji z raportem wpływu na deklaracje
# ═══════════════════════════════════════════════════════════════════════════════

neural_mesh := {
    "conflict_alert_threshold": 0.7,               # alert konfliktu — trust diff ≥ 0.7
    "default_trust_score": 0.8,
    "override_mode": "AUTO_POST",
    "min_confidence_propagate": 0.5,
    "dead_innovation_check_cycles": 12,
    "judicial_impact_threshold": 0.6,
    "legislative_alert_days": 30,

    # ── P0-1: strategic_roadmap — pełna implementacja ──
    "strategic_roadmap": {
        "forms": ["skala", "liniowy", "ryczałt", "IP Box"],
        "horizon_years": 5,
        "projection_growth_default": 0.05,
        "transformation_threshold_pln": 300000,    # JDG → Sp. z o.o. opłacalne powyżej
        "legal_basis": "Art. 27/30c/30ca u.PIT; u.PCC; art. 119a OrdPU (GAAR)",
    },

    # ── P0-2: judicial_trend + cross_jurisdiction_ruling — pełna implementacja ──
    "judicial_trend_rulings": {
        "courts": ["NSA", "WSA", "TK", "TSUE"],
        "precedence_weights": {"WSA": 1, "NSA_3": 3, "NSA_FULL": 8, "TK": 10, "TSUE": 10},
        "unfavorable_trend_threshold_pct": 60,
        "binding_scope": "Art. 14k-14m OrdPU (ochrona KKS)",
    },

    # ── P1-1: integracja z legislacja.gov.pl — radar live ──
    "legislacja_gov_pl": {
        "api": "https://legislacja.gov.pl/api (projekty ustaw)",
        "radar_horizon_days": 30,
        "monitored_areas": ["VAT", "PIT", "ZUS", "KKS", "Ordynacja", "KSeF", "PPK"],
        "auto_alert": true,
    },

    # ── P1-2: baza orzecznictwa NSA/WSA z parserem sygnatur ──
    "nsa_wsa_rulings_db": {
        "signature_parser": "NSA/WSA sygnatury: I FSK 1234/25 (regex)",
        "sources": ["CBOSA", "orzeczenia.nsa.gov.pl"],
        "min_rulings_for_trend": 5,
        "indexed_articles": ["16", "70", "119a"],
    },

    # ── P1-3: propagacja pewności w pełnym grafie reguł (P01-P20) ──
    "full_graph_confidence": {
        "domains": ["VAT", "PIT", "ZUS", "KKS", "ORD", "PKPiR", "KSeF", "RYC", "CB", "HR"],
        "propagation_cutoff": 0.5,
        "max_hops": 3,
        "packages": "p01-p24 + p33-p35",
    },

    # ── P2-1: UI panelu SRO (orzecznictwo → zmiany reguł) ──
    "sro_panel": {
        "widgets": ["trendy orzecznicze", "orzeczenia per artykuł", "zmiany reguł", "alerty wpływu"],
        "auto_rule_update": true,
        "export_formats": ["JSON", "CSV", "PDF"],
    },

    # ── P2-2: symulator nowelizacji z raportem wpływu ──
    "novelization_impact": {
        "impact_levels": ["NISKI", "ŚREDNI", "WYSOKI", "KRYTYCZNY"],
        "declaration_forms": ["VAT-7", "PIT-36", "ZUS DRA", "JPK_V7", "PCC-3"],
        "auto_impact_report": true,
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# R21: OPA JAKO SYSTEM (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════
opa_system := {
    "ttl_fallback_ms": 300000,                # ms — TTL fallbacku (auto-rollback 5 min, P01 v9.x)
    "canary_percent": 5,                         # deploy kanary — 5% ruchu
    "canary_observation_minutes": 30,            # obserwacja kanary — 30 min
    "rollback_quality_threshold": 0.95,          # jakość decyzji ≥ 95% → zatrzymaj kanary
    "rollback_error_threshold": 0.01,            # błąd > 1% decyzji → auto-rollback
    "bundle_max_files": 400,                     # max plików w bundle (obecnie 383)
    "bundle_min_files": 100,                     # min plików w bundle
    "bundle_min_rules": 10000,                   # min reguł w bundle (obecnie 10878)
    "drift_alert_percent": 10,                   # dryf policies vs rules ≥ 10% → alert
    "sync_check_hours": 24,                      # auto-sync co 24 h
    "decision_monitor_days": 30,                 # monitoring jakości decyzji — 30 dni
    "legislative_adapt_hours": 24,               # auto-adaptacja do nowelizacji w 24 h
    "feature_flag_default": "ON",               # default feature-flag dla reguł
    "kill_switch_enabled": true,                 # P01-RAPORT_01: globalny kill-switch; false = abort ALL
    "kill_switch_reason": "",                    # powód aktywacji kill-switcha (logowanie)
    "signature_algorithm": "SHA256",             # weryfikacja podpisu bundle
    "temporal_versions_keep": 5,                 # ile wersji temporalnych przechowujemy
}

# ═══════════════════════════════════════════════════════════════════════════════
# R22: NARZĘDZIA WALIDACJI (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════
narzedzia_walidacji := {
    "manifest_min_rules": 10000,                 # CI-gate: min reguł w manifeście
    "manifest_min_files": 300,                   # CI-gate: min plików
    "duplicate_rule_ids_threshold": 500,         # alert przy > 500 duplikatów rule_id (baza 369)
    "stub_threshold": 10,                        # alert przy > 10 stubów { true } na plik
    "hardcoded_threshold": 10,                   # alert przy > 10 hardcode'ów na plik
    "zero_defect_gates": 7,                      # 7 kryteriów certyfikacji
    "certification_min_score": 100,              # ENTERPRISE-CERTIFIED = 100/100
    "self_healing_max_fixes": 5,                 # max auto-napraw na cykl
    "impact_analyzer_rules": 50,                 # max reguł w impact matrix
    "chaos_scenarios": 8,                        # scenariusze chaos engineering
    "coverage_min_pct": 90,                      # minimalne pokrycie prawne %
    "legal_basis_confidence_min": 0.9,           # pewność weryfikacji podstaw prawnych
}

# ═══════════════════════════════════════════════════════════════════════════════
# R23: TESTY REGO I CI (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════
testy_rego_ci := {
    "coverage_min_pct": 90,                      # min pokrycie testami %
    "else_chain_test_min": 90,                   # min % plików z testem kolejności
    "negative_test_min": 80,                     # min % pakietów z testem no_match
    "fuzz_iterations": 10000,                    # iteracje fuzzingu na paczkę
    "property_tests_min": 5,                     # min testów property per pakiet
    "ci_gates_total": 6,                         # bramki CI: syntax, test, coverage, zero_defect, no_stubs, no_hardcoded
    "mutation_score_min": 70,                    # min wynik mutacji %
    "law_test_min": 3,                           # min testów zmiany prawa per pakiet
    "temporal_test_min": 5,                      # min testów temporalnych per pakiet
    "e2e_scenarios_min": 10,                     # min scenariuszy E2E
}

# ═══════════════════════════════════════════════════════════════════════════════
# R24: AUDYT KOMPLETNY I SYNTEZA (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════
audyt_kompletny := {
    "target_coverage_pct": 100,                  # cel pokrycia prawnego 100%
    "completeness_target": 100,                  # cel Completeness Score 100/100
    "stub_target": 0,                            # cel: zero stubów { true }
    "duplicate_target": 0,                       # cel: zero duplikatów rule_id
    "auto_post_target_pct": 60,                  # cel: 60% decyzji AUTO_POST
    "suggest_target_pct": 30,                    # cel: 30% SUGGEST
    "ask_user_max_pct": 10,                      # cel: max 10% ASK_USER
    "adaptation_hours": 72,                      # adaptacja do zmian prawa ≤ 72h
    "fortress_score_target": 95,                 # cel: wskaźnik fortecy ≥ 95
    "knowledge_graph_nodes": 10509,              # węzły Knowledge Graph (rule_id)
    "proof_of_correctness_min": 100,             # proof-of-correctness 100% decyzji
}

# ═══════════════════════════════════════════════════════════════════════════════
# PIT THRESHOLDS
# ═══════════════════════════════════════════════════════════════════════════════

pit := {
    "cash_payment_limit": 15000,                # PLN — limit płatności gotówkowych (Art. 22p PIT, P01 v9.x)
    "tax_free_2017": 6600,                     # PLN — kwota wolna 2017 (Art. 27 ust. 1 PIT, P01 v9.x)
    "tax_free_2018_2021": 8000,                # PLN — kwota wolna 2018-2021
    "tax_free_2022_plus": 30000,               # PLN — kwota wolna 2022+
    "kup_creative_cap": 120000,                # PLN — roczny limit 50% KUP (Art. 22 ust. 9 pkt 3 PIT)
    "kup_multiple_cap": 4500,                  # PLN — roczny limit KUP wielu stosunków (Art. 22 ust. 9 pkt 4 PIT)
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
    "car_lease_insurance_limit": 150000,        # PLN — limit składek na ubezpieczenie auta (leasing, Art. 23 PIT)

    # Art. 27 PIT — kwota zmniejszająca podatek
    "tax_reducing_amount": 3600,                 # PLN — kwota zmniejszająca (12% × 30k, P30 L9)
    "tax_free_amount_degression_start": 30000,   # PLN — degresja od 30 000
    "tax_free_amount_degression_end": 120000,    # PLN — degresja do 120 000

    # Art. 27f PIT — ulga prorodzinna
    "family_relief_amount_per_child": 1112.04,    # PLN/rok na dziecko (P30 L10)
    "family_relief_amount_third_child": 2000.04,
    "family_relief_amount_fourth_plus": 2700.00,

    # Raport 04 — limity ulg używane przez jdg.pit.missing_reliefs
    "internet_relief_limit": 760,
    "rehab_car_limit": 2280,
    "blood_value_per_liter": 130,

    # P30: Ulgi innowacyjne PIT
    "prototype_relief_rate": 0.30,              # 30% — ulga na prototyp (Art. 26eb, P30 L8)
    "robotization_relief_rate": 0.50,           # 50% — ulga na robotyzację (Art. 26gb, P30 L8)
    "expansion_relief_max_costs": 1000000,       # PLN — max koszty kwalifikowane ekspansji (Art. 26ec)
    "pit_thermo_limit": 53000,                   # PLN — ulga termomodernizacyjna (Art. 26h, limit na podatnika)
    "pit_thermo_carry_years": 3,                 # lata — odliczenie w ciągu 3 lat (Art. 26h ust. 6)

    # P30: Mały podatnik PIT
    "small_taxpayer_pit_limit_eur": 2000000,     # EUR — limit przychodu (Art. 5a pkt 20, P30 L11)

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
    "exit_tax_threshold": 4000000,               # PLN — próg 4 000 000 (Art. 30da ust. 1, P30 L4)

    # Art. 21 ust. 1 pkt 148-154 PIT — wspólny limit ulg PIT-0 (mlodzi, powrót, 4+, senior)
    "pit_relief_shared_limit": 85528,            # PLN — limit łączny ulg PIT-0 (2026)

    # ── PROMPT_04 (2026-08-22) — Danina solidarnościowa (Art. 30h PIT) ──
    "pit_solidarity_threshold": 1000000,         # PLN — nadwyżka ponad 1 000 000 zł (Art. 30h ust. 2)
    "pit_solidarity_rate": 0.04,                 # 4% — danina solidarnościowa (Art. 30h ust. 1)
    "pit_solidarity_due_day": "04-30",           # deklaracja + wpłata do 30 kwietnia (Art. 30h ust. 4)

    # ── PROMPT_04 (2026-08-22) — Ceny transferowe (Art. 23w, 23za, 23zf PIT) ──
    # Art. 23w ust. 2 — progi dokumentacyjne lokalnej dokumentacji TP
    "tp_doc_threshold_goods": 10000000,          # PLN — transakcja towarowa
    "tp_doc_threshold_financial": 10000000,      # PLN — transakcja finansowa
    "tp_doc_threshold_services": 2000000,        # PLN — transakcja usługowa
    "tp_doc_threshold_other": 2000000,           # PLN — inna transakcja
    # Art. 23w ust. 2a / Art. 23za ust. 1 — raje podatkowe (szkodliwa konkurencja)
    "tp_doc_threshold_haven_financial": 2500000, # PLN — transakcja finansowa
    "tp_doc_threshold_haven_other": 500000,      # PLN — transakcja inna niż finansowa
    # Art. 23w ust. 1 — termin sporządzenia dokumentacji lokalnej
    "tp_local_docs_due_month": 10,               # do końca 10. miesiąca po zakończeniu roku podatkowego
    # Art. 23zf ust. 1 — termin złożenia TP-R
    "tp_information_due_month": 11,              # do końca 11. miesiąca po zakończeniu roku podatkowego
    # Art. 23m ust. 2 pkt 1 — próg znaczącego wpływu (powiązania)
    "tp_significant_influence_pct": 0.25,        # >=25% udziałów / praw głosu / zysków

    # ── P05 GLM52 — PIT MAKRO (RAPORT_GLM52_P05_PIT_MAKRO.txt) ──
    # Art. 44 PIT — termin zaliczek (20. dzień miesiąca)
    "advance_due_day": 20,
    # Art. 63 § 1 OrdPU — zaokrąglanie podstaw i zaliczek do pełnych złotych
    "advance_grosz_rounding": true,
    # Art. 44 ust. 3g PIT — terminy zaliczek kwartalnych małego podatnika
    # (20. dzień miesiąca następującego po kwartale: IV, VII, X, I)
    "quarterly_advance_due_months": [4, 7, 10, 1],
    # Art. 45 ust. 1 PIT — termin zeznania PIT-36/36L
    "annual_return_pit36_deadline": "04-30",
    # Art. 21 ust. 1 ustawy o ryczałcie — termin PIT-28 (28 lutego!)
    "annual_return_pit28_deadline": "02-28",
    # Alert 95% łącznego limitu ulg PIT-0 (monitor prewencyjny)
    "exemption_shared_limit_alert_pct": 0.95,
    # Art. 23 ust. 1 pkt 37 PIT — składki ZUS społeczne jako KUP (flaga kontraktu P08)
    "zus_social_as_kup": true,
    # Estimator karty podatkowej w symulacji „co by było gdyby” (P05 INN-06)
    "card_tax_estimation_pct": 0.20,

    # ════════════════════════════════════════════════════════════════════════
    # V3-P14 PIT RELIEFS / FORMS ENTERPRISE (kampania V3 FORTRESS)
    # ADR-002 zero hardcode — limity ulg jako DANE roczne z valid_from
    # (P06 parametry-as-data, P05 temporalność). Innowacje V3-P14-I01..I12.
    # ════════════════════════════════════════════════════════════════════════
    # V3-P14-I02: Limit-as-Data Engine — limity roczne ulg z valid_from
    "v3_p14_relief_limits": {
        "young": {"limit_pln": 85528, "valid_from": "2022-01-01"},        # art. 21 ust. 1 pkt 148 PIT
        "return_work": {"limit_pln": 85528, "valid_from": "2022-01-01"},  # art. 21 ust. 1 pkt 152 PIT
        "family_4plus": {"limit_pln": 85528, "valid_from": "2022-01-01"}, # art. 21 ust. 1 pkt 153 PIT
        "senior": {"limit_pln": 85528, "valid_from": "2022-01-01"},       # art. 21 ust. 1 pkt 154 PIT
        "thermo": {"limit_pln": 53000, "valid_from": "2019-01-01"},       # art. 26h PIT (na podatnika)
        "rehab_car": {"limit_pln": 2280, "valid_from": "2024-01-01"},     # art. 26 ust. 1 pkt 6 PIT (auto)
        "internet": {"limit_pln": 760, "valid_from": "2024-01-01"},       # art. 26 ust. 1 pkt 6a PIT
    },
    "v3_p14_threshold_version": "pit-reliefs-v3p14-2026.09",
    # V3-P14-I01/I09: granice wieku i okien czasowych ulg PIT-0
    "young_relief_max_age": 26,                  # ulga młodych — do 26 lat
    "return_work_relief_years": 4,               # art. 21 ust. 1 pkt 152 — 4 lata
    # V3-P14-I03: Nexus Ratio Auditor (art. 30ca ust. 4 PIT)
    "ip_box_nexus_full_ratio": 0.50,             # ≥ 50% — FULL premium
    "ip_box_nexus_partial_ratio": 0.25,          # ≥ 25% — partial discount
    # V3-P14-I09: okno inwestycyjne robotyzacji (art. 26gb PIT — 2022-2026)
    "robotization_relief_last_year": 2026,
    "relief_expiry_alert_months": 3,             # alert sentinela z 3-mies. wyprzedzeniem
    # V3-P14-I06: symulator — wskaźnik ogólny ryczałtu (stawki PKWiU: kontrakt P18/P14)
    "lump_sum_generic_rate": 0.10,
    # Wersjonowanie snapshotu pit (kontrakt _certificate V3-P14)
    "threshold_version": "pit-reliefs-2026.09",
    "legal_basis_version": "isap-pit-2026.08",
    "valid_from": "2025-01-01",
    "valid_to": null,
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
    "accident_rate": 0.0167,                     # 1.67% — wypadkowa (średnia dla JDG)
    "accident_rate_min": 0.0067,                 # 0.67% — min. stopa wypadkowa (art. 22 ust. 4 pkt 2 SUS)
    "accident_rate_max": 0.0333,                 # 3.33% — max. stopa wypadkowa (art. 22 ust. 4 pkt 1 SUS)
    "labour_fund_rate": 0.0245,                  # 2.45% — Fundusz Pracy

    # Suma składek społecznych płatnika (emerytalna + rentowa + wypadkowa +
    # chorobowa + Fundusz Pracy) = 19.52 + 8 + 1.67 + 2.45 + 2.45 = 34.09%
    "zus_social_total_rate": 0.3409,             # 34.09% — łączna stopa społeczna (P780)

    # Art. 19 SUS — roczny limit podstawy emerytalno-rentowej
    "zus_annual_base_cap_multiplier": 30,        # 30-krotność przeciętnego wynagrodzenia

    # ── GLM52 P09 — ZUS MIKRO (mikro-atomowe reguły sus/zdrowotna/zasilkowa) ──
    # Podstawy wymiaru składek (art. 18/18a/18c SUS, mikro)
    "social_base_standard_60pct": 5460.00,       # PLN — 60% przeciętnego (2026)
    "preferential_base_30pct": 1440.00,          # PLN — 30% minimalnego (preferencyjna, 2026)
    "maly_zus_plus_base_pct": 30,                # % minimalnego — podstawa MZP (art. 18c ust. 4)
    "maly_zus_plus_base_cap_pct": 60,            # % przeciętnego — górny kraniec podstawy MZP
    "maly_zus_plus_months_window": 60,           # mies. okno — max 36 mies. MZP w 60 (art. 18c ust. 11)

    # Składka zdrowotna — podstawy minimalne (mikro, art. 81 ust. 2 u.ś.o.z.)
    "health_min_base_standard": 4800.00,         # PLN — 100% minimalnego (JDG)
    "health_min_base_first_year": 3600.00,       # PLN — 75% minimalnego (pierwszy rok działalności)
    "health_lump_annual_deadline": "05-22",     # korekta roczna ryczałtu — 22 maja
    "health_lump_tier_1_multiplier": 0.60,       # 60% przeciętnego — TIER I (przychód ≤ 60 000)
    "health_lump_tier_2_multiplier": 1.00,       # 100% przeciętnego — TIER II (przychód ≤ 300 000)
    "health_lump_tier_3_multiplier": 1.80,       # 180% przeciętnego — TIER III (> 300 000)

    # Zasiłki (ustawa zasiłkowa, mikro)
    "sickness_waiting_days_employee": 30,        # 30 dni wyczekiwania (pracownik / obowiązkowe chorobowe)
    "sickness_waiting_days_voluntary": 90,       # 90 dni wyczekiwania (dobrowolne chorobowe JDG)
    "sickness_max_days_standard": 182,           # limit 182 dni (art. 8 ustawy zasiłkowej)
    "sickness_max_days_tb": 270,                 # limit 270 dni (gruźlica / szczególne przypadki)
    "sickness_benefit_base_months": 12,          # 12 mies. — podstawa z historii składek
    "sickness_benefit_daily_divisor": 30,        # podstawa dzienna = podstawa / 30

    # Terminy płatności (art. 47 ust. 1 pkt 2 SUS — mikro)
    "payment_deadline_social": 10,               # 10. dzień miesiąca (JDG bez pracowników)
    "payment_deadline_social_employees": 15,     # 15. dzień miesiąca (DRA, pracownicy)
    "payment_deadline_health": 10,               # 10. dzień miesiąca (zdrowotna JDG)

    # Zgłoszenia (art. 36 ust. 4 SUS)
    "reporting_deadline_days": 7,                # 7 dni na ZUA/ZWUA
}

# ═══════════════════════════════════════════════════════════════════════════════
# KSIĘGOWOŚĆ (GLM52 P10 — PKPiR/UoR/amortyzacja księgowa/leasing)
# ═══════════════════════════════════════════════════════════════════════════════

ksiegowosc := {
    # Art. 2 ust. 1 pkt 5 UoR — próg pełnej księgowości (przychody netto)
    "uor_threshold_eur": 2000000,              # 2 000 000 EUR
    "uor_threshold_group_eur": 2500000,        # 2 500 000 EUR — grupy kapitałowe
    "uor_obligation_years": 2,                 # rok obrotowy + 2 kolejne (art. 2 ust. 1)
    "eur_pln_rate_default": 4.50,              # kurs orientacyjny EUR/PLN (2026)

    # Art. 32 UoR — amortyzacja księgowa
    "depreciation_one_time_limit_eur": 100000,  # jednorazowy odpis — limit 100 000 EUR
    "depreciation_degresja_multiplier": 2.0,    # degresywna księgowa — 2× stawka liniowa

    # Art. 26 UoR — inwentaryzacja
    "inventory_cycle_years": 4,                # co 4 lata (droga inwentaryzacja)
    "inventory_rotation_pct": 25,              # 25% pozycji rocznie (ciągła)

    # Art. 17f ust. 1 PIT — testy leasingu finansowego
    "leasing_value_test_pct": 90,              # suma opłat ≥ 90% wartości początkowej
    "leasing_period_test_pct": 75,             # okres ≥ 75% normatywnego okresu amortyzacji
    "leasing_realestate_min_years": 10,        # nieruchomości — okres ≥ 10 lat

    # Limity samochodów osobowych (PIT/VAT — PROMPT 02/06)
    "car_limit_150k": 150000,                  # limit 150 000 zł (samochody < 3,5 t, PIT)
    "car_limit_225k": 225000,                  # limit 225 000 zł (samochody elektryczne)

    # PKPiR — struktura ewidencji
    "pkpir_columns": 17,                       # kolumny 1–17 (rozporządzenie MF 15.11.2025)
    "pkpir_cash_basis_days": 14,               # memoriał kasowy — 14 dni na zapis

    # ── V3-P20 KSIĘGOWOŚĆ PKPiR/UoR/AMORTYZACJA/LEASING (kampania V3 FORTRESS, jdg.v3_p20_ksiegowosc) ──
    # Rdzeń księgowości ENTERPRISE — PKPiR (kolumny, remanent, NKUP, korekty),
    # UoR (księgi, inwentaryzacja, sprawozdania), amortyzacja (art. 22a-22n),
    # leasing (operacyjny/finansowy). Limity współdzielone NIE są duplikowane:
    # 150k aut / 10k NKUP-ulepszenie / 100k jednorazowa / stawki KŚT / próg 2M EUR
    # czytane przez pakiet z bloków depreciation/accounting (ADR-002, AP04/AP12).
    "v3_p20_threshold_version": "ksiegowosc-v3p20-2026.09",
    "v3_p20_schema_version": "pkpir-cols-17-2025.11",  # I01: wersja schematu kolumn (rozp. MF 15.11.2025)
    "v3_p20_pkpir_cash_booking_days": 14,       # I01: memoriał kasowy — 14 dni na zapis
    "v3_p20_remanent_rule": "RK_MINUS_RP",      # I02: koszty = remanent końcowy − początkowy (art. 24a)
    "v3_p20_remanent_chain_invariant": true,     # I02: Rk roku N = Rp roku N+1 (invariant łańcucha)
    "v3_p20_nkup_use_months": 12,                # I03: użycie < 1 roku → koszt bieżący (art. 22d/22f)
    "v3_p20_one_time_alert_pct": 0.80,           # I04: alarm przy 80% limitu jednorazowej 100k
    "v3_p20_one_time_groups": ["3", "4", "5", "6", "7", "8"],  # I04: art. 22k ust. 7 — grupy 3-8 (minus auta)
    "v3_p20_kst_rate_version": "kst-2026.01",    # I05: wersja tabeli stawek KŚT (grupy→stawki)
    "v3_p20_leasing_op_initial_months": 12,      # I06: opłata wstępna operacyjnego — rozłożenie 12M [NIEZWERYFIKOWANE]
    "v3_p20_uor_transition_procedure": "REMANENT_PLUS_CLOSING",  # I07: przejście PKPiR→UoR w trakcie roku
    "v3_p20_uor_transition_months": 3,           # I07: procedura przejścia — okno 3 mies. [NIEZWERYFIKOWANE]
    "v3_p20_closing_pit_due": "04-30",           # I08: PIT roczny do 30.04 (łańcuch zamknięcia roku)
    "v3_p20_closing_jpk_due": "02-20",           # I08: JPK_V7 do 25./20. — kontekst łańcucha [NIEZWERYFIKOWANE]
    "v3_p20_double_entry_invariant": true,        # I09: UoR — bilans zbalansowany (podwójny zapis, P04)
    "v3_p20_golden_version": "ksiegowosc-golden-2026.09",  # I10: wersja golden set księgowości
    "v3_p20_invariants_active": true,             # I11: pakiet invariantów księgowości (kontrakt P04)
    "v3_p20_checklist_version": "dowody-ksiegowe-2026.01",  # I12: wersja checklist dokumentacyjnych
    "kst_version": "kst-2026.01",                       # I05: wersja tabeli KŚT
    "depreciation_limits": {"one_time_eur": 100000},   # I04: limit jednorazowej
    "leasing_limits": {"car_pln": 150000},            # I06: limit aut 150k
    "nkup_limits": {"use_months": 12, "value_limit_pln": 10000},  # I03
    "kst_group_1_rate": 0.015,
    "kst_group_2_rate": 0.02,
    "kst_group_3_rate": 0.025,
    "kst_group_4_rate": 0.05,
    "kst_group_5_rate": 0.10,
    "kst_group_6_rate": 0.20,
    "kst_group_7_rate": 0.25,
    "kst_group_8_rate": 0.40,
    "kst_group_9_rate": 0.50,
    "one_time_depreciation_limit_eur": 100000,
    "car_leasing_limit_150000": 150000,
    "golden_version": "bookkeeping-golden-2026.09",
    "bookkeeping_invariants_active": true,
    "pkpir_column_count_minimum": 17,
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
# V3-P25 KALENDARZ ZBIORCZY — JEDNO ŹRÓDŁO PRAWDY TERMINÓW (kampania V3 FORTRESS)
# Tabela MASTER terminów (I01) jako DANE: obowiązek → termin bazowy →
# przeniesienie PER obowiązek (I02, art. 12 § 4-5 OrdPU) → alerty N-dni (I03,
# zero ciszy P04) → checklista (I09) → link do wykonania (I10).
# WAŻNE: przeniesienia ZWERYFIKOWANE PER OBOWIĄZEK — VAT/ZUS/PIT-zaliczki:
# następny dzień roboczy (art. 12 § 4 OP); PIT roczny 30.04: PRZENOSI (§ 4);
# PCC 14 dni: NIE przenosi (termin odejmuje się od dnia zawarcia, art. 4 ust. 3).
# Status weryfikacji: [NIEZWERYFIKOWANE] — ISAP/RCL nie wykonano w tej sesji.
# ═══════════════════════════════════════════════════════════════════════════════

calendar := {
    "v3_p25_threshold_version": "kalendarz-v3p25-2026.09",
    "v3_p25_calendar_schema": "deadline-v1-2026.09",          # I05: schemat terminu
    "v3_p25_zero_silence_constitution": true,                  # I03: minął termin + brak wykonania = BLOCK (P04)
    "v3_p25_alert_levels_days": [7, 3, 1],                     # I03: alerty N-dni (7/3/1) — per obowiązek override
    "v3_p25_escalation_hours": 48,                             # I03: eskalacja po 48h od BLOCK (kontrakt P19)
    "v3_p25_rollover_rule": "NEXT_BUSINESS_DAY",               # I02: domyślne przeniesienie — art. 12 § 4 OrdPU
    "v3_p25_rollover_exception_rule": "NONE",                  # I02: PCC 14 dni — brak przeniesienia (art. 4 ust. 3)
    "v3_p25_golden_version": "kalendarz-golden-2026.09",       # I12: golden rok kalendarzowy
    "v3_p25_tenant_isolation_invariant": true,                 # I07: multi-tenant — izolacja per JDG
    "v3_p25_workload_forecast_horizon_days": 14,               # I08: prognoza obciążeń księgowych
    "v3_p25_compliance_score_history_months": 12,              # I11: trend dotrzymywania terminów
    "v3_p25_dedup_scanner_active": true,                       # I06: detektor hardcode terminów

    # TABELA MASTER (I01): jeden wiersz na obowiązek — jedno źródło prawdy
    # dla wszystkich domen (P12 VAT, P14 PIT, P16 KSeF/JPK, P19 PCC, P23 CEIDG,
    # P26 ZUS). Konsumenci CZYTAJĄ tę tabelę — nie definiują własnych dat.
    "v3_p25_master_deadline_table": [
        {"obligation": "VAT_JPK_MONTHLY", "base_day": 25, "frequency": "MONTHLY",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [7, 3, 1],
         "checklist": ["JPK_V7", "ZAPLATA"], "action": "generate_jpk_v7",
         "legal_basis": "Art. 99 ust. 1-3 i art. 103 ust. 1 ustawy o VAT [NIEZWERYFIKOWANE]"},
        {"obligation": "VAT_JPK_QUARTERLY", "base_day": 25, "frequency": "QUARTERLY",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [7, 3, 1],
         "checklist": ["JPK_V7K", "ZAPLATA"], "action": "generate_jpk_v7k",
         "legal_basis": "Art. 99 ust. 3 i art. 103 ust. 2 ustawy o VAT [NIEZWERYFIKOWANE]"},
        {"obligation": "PIT_ADVANCE_MONTHLY", "base_day": 20, "frequency": "MONTHLY",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [7, 3, 1],
         "checklist": ["ZALICZKA"], "action": "pay_pit_advance",
         "legal_basis": "Art. 44 ust. 6 ustawy o PIT [NIEZWERYFIKOWANE]"},
        {"obligation": "PIT_LUMP_SUM_MONTHLY", "base_day": 20, "frequency": "MONTHLY",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [7, 3, 1],
         "checklist": ["ZALICZKA_RYCZALT"], "action": "pay_pit_ryczalt",
         "legal_basis": "Art. 8 ust. 1 ustawy o ryczałcie [NIEZWERYFIKOWANE]"},
        {"obligation": "PIT_ANNUAL_RETURN", "base_date": "04-30", "frequency": "ANNUAL",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [30, 7, 1],
         "checklist": ["PIT_36", "PIT_36L", "PIT_28", "ZAPLATA"], "action": "generate_pit_annual",
         "legal_basis": "Art. 45 ust. 1 ustawy o PIT [NIEZWERYFIKOWANE]"},
        {"obligation": "ZUS_DRA_NO_EMPLOYEES", "base_day": 10, "frequency": "MONTHLY",
         "rollover": "PREV_BUSINESS_DAY", "alert_override": [7, 3, 1],
         "checklist": ["DRA", "SKLADKI"], "action": "generate_zus_dra",
         "legal_basis": "Art. 47 ust. 1 pkt 1 ustawy o SUS [NIEZWERYFIKOWANE] — przeniesienie wstecz (ust. 3)"},
        {"obligation": "ZUS_DRA_WITH_EMPLOYEES", "base_day": 15, "frequency": "MONTHLY",
         "rollover": "PREV_BUSINESS_DAY", "alert_override": [7, 3, 1],
         "checklist": ["DRA", "SKLADKI"], "action": "generate_zus_dra",
         "legal_basis": "Art. 47 ust. 1 pkt 2 ustawy o SUS [NIEZWERYFIKOWANE]"},
        {"obligation": "PCC3_14D", "base_days": 14, "frequency": "EVENT",
         "rollover": "NONE", "alert_override": [7, 3, 1],
         "checklist": ["PCC_3", "ZAPLATA"], "action": "generate_pcc3",
         "legal_basis": "Art. 4 ust. 3 ustawy o PCC [NIEZWERYFIKOWANE] — termin NIE przenosi"},
        {"obligation": "CEIDG_CHANGE_7D", "base_days": 7, "frequency": "EVENT",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [3, 1],
         "checklist": ["CEIDG_UPDATE"], "action": "generate_ceidg_change",
         "legal_basis": "Ustawa CEIDG art. 21 ust. 3 [NIEZWERYFIKOWANE]"},
        {"obligation": "SUCCESSION_INVENTORY_2M", "base_months": 2, "frequency": "EVENT",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [14, 7, 1],
         "checklist": ["SPIS_INWENTARZA", "OGLOSZENIE"], "action": "generate_succession_pack",
         "legal_basis": "Art. 10 ustawy o zarządzie sukcesyjnym [NIEZWERYFIKOWANE]"},
        {"obligation": "PPK_CONTRIBUTION", "base_day": 15, "frequency": "MONTHLY",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [7, 3, 1],
         "checklist": ["PPK_WPLATA"], "action": "pay_ppk",
         "legal_basis": "Art. 22 ustawy o PPK [NIEZWERYFIKOWANE]"},
        {"obligation": "PROPERTY_TAX_INSTALLMENT", "base_day": 15, "frequency": "QUARTERLY",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [14, 7, 1],
         "checklist": ["ZAPLATA_RATY"], "action": "pay_property_installment",
         "legal_basis": "Art. 6 ust. 2 ustawy o podatkach i opłatach lokalnych [NIEZWERYFIKOWANE]"},
        {"obligation": "TRANSPORT_TAX", "base_date": "01-31", "frequency": "ANNUAL",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [14, 7, 1],
         "checklist": ["DN_1", "ZAPLATA"], "action": "generate_dn1",
         "legal_basis": "Art. 12 ust. 6 ustawy o podatkach i opłatach lokalnych [NIEZWERYFIKOWANE]"},
        {"obligation": "KSEF_SEND_INVOICE", "base_days": 0, "frequency": "EVENT",
         "rollover": "NONE", "alert_override": [1],
         "checklist": ["KSEF_SESSION", "WYSYLKA"], "action": "send_ksef",
         "legal_basis": "Art. 106na ustawy o VAT [NIEZWERYFIKOWANE]"},
        {"obligation": "BDO_ANNUAL_REPORT", "base_date": "03-15", "frequency": "ANNUAL",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [30, 7, 1],
         "checklist": ["BDOR"], "action": "generate_bdo_report",
         "legal_basis": "Art. 59 ustawy o odpadach [NIEZWERYFIKOWANE]"},
        {"obligation": "APPEAL_14D", "base_days": 14, "frequency": "EVENT",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [3, 1],
         "checklist": ["ODWOLANIE"], "action": "generate_appeal",
         "legal_basis": "Art. 129 § 2 Ordynacji podatkowej [NIEZWERYFIKOWANE]"},
        {"obligation": "COMPLAINT_30D", "base_days": 30, "frequency": "EVENT",
         "rollover": "NEXT_BUSINESS_DAY", "alert_override": [7, 3, 1],
         "checklist": ["SKARGA_WSA"], "action": "generate_wsa_complaint",
         "legal_basis": "Art. 54 § 1 p.p.s.a. [NIEZWERYFIKOWANE]"},
    ],

    # Wykaz świąt PL (stałe) — wejście do Year Rollover Test Rig (I04/I12);
    # ruchome (Wielkanoc/Boże Ciało) liczone algorytmicznie w narzędziu.
    "v3_p25_public_holidays": ["01-01", "01-06", "05-01", "05-03", "08-15",
                               "11-01", "11-11", "12-25", "12-26"],
}

# ═══════════════════════════════════════════════════════════════════════════════
# ZUS26 — V3-P26 GOVERNANCE (kampania V3 FORTRESS)
# Governance warstwy składkowej V3-P26: tolerancje, automat ulg, stress lab,
# wersje golden. Stawki/podstawy/progi zdrowotnej POZOSTAJĄ w bloku zus
# (jedno źródło prawdy stawek). Temporalność (P05): valid_from per rok.
# Status weryfikacji: [NIEZWERYFIKOWANE] — ISAP/RCL/zus.pl nie wykonano.
# ═══════════════════════════════════════════════════════════════════════════════

zus26 := {
    "v3_p26_threshold_version": "zus26-v3p26-2026.09",
    "legal_basis_version": "SUS+USOZ-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    "v3_p26_grosz_tolerance": 0.005,                           # I01: tolerancja groszowa
    "v3_p26_tier_alert_approach_pct": 90,                      # I03: alarm przed progiem
    "v3_p26_health_params_version": "health-2026.09",          # I04: wersja parametrów zdrowotnej
    "v3_p26_suspension_alert_months": 24,                      # I05: przegląd długiego zawieszenia
    "v3_p26_golden_version": "zus-golden-2026.09",             # I08: golden granic składkowych
    "v3_p26_health_rescale_periods": 4,                        # I09: okresy przeliczenia (kwartalne)
    "v3_p26_min_wage_drift_pct": 1.0,                          # I10: dryf feedu minimalnej
    "v3_p26_stress_required_scenarios": 3,                     # I11: komplet scenariuszy
    "v3_p26_invariants_active": true,                          # I07: konstytucja składkowa (P04)
    "v3_p26_dra_zero_silence": true,                           # I06: zero ciszy DRA/RCA (P25)
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

    # ── V3-P18 RYCZAŁT ENTERPRISE (kampania V3 FORTRESS, pakiet jdg.v3_p18_ryczalt) ──
    # Stawki jako dane (ADR-002/P06) — uzupełnione brakujące stawki art. 12
    # (10/12,5/14%) + zestaw stawek + mapy PKWiU wersjonowane + wykluczenia
    # art. 8 + formy/karta. Podstawy do weryfikacji ISAP (art. 21-30 karta —
    # stawki karty [NIEZWERYFIKOWANE], patrz raport P18).
    "v3_p18_threshold_version": "ryczalt-v3p18-2026.09",
    "v3_p18_rate_10pct": 0.10,                   # I01: art. 12 — stawka 10% (uzupełnienie)
    "v3_p18_rate_12_5pct": 0.125,                # I01: art. 12 — stawka 12,5% (uzupełnienie)
    "v3_p18_rate_14pct": 0.14,                   # I01: art. 12 — stawka 14% (IT powyżej progu)
    "v3_p18_rate_set": [0.02, 0.03, 0.055, 0.085, 0.10, 0.12, 0.125, 0.14, 0.15, 0.17],
    "v3_p18_rate_map_version": "pkwiu-ryczalt-2025.09",   # I01/I10: wersja mapy PKWiU→stawka
    "v3_p18_rate_14pct_threshold_pln": 300000,   # I01: próg 300k dla stawki 14%/12,5% IT
    "v3_p18_exclusion_former_employer": true,    # I02: art. 8 — usługi dla b. pracodawcy
    "v3_p18_exclusion_effective_mode": "NEXT_DAY",  # I03: utrata od dnia nast. [NIEZWERYFIKOWANE]
    "v3_p18_midyear_change_deadline_days": 14,   # I03: termin ścieżki zmiany formy
    "v3_p18_health_rate_pct": 0.049,             # I04: zdrowotna 4,9% (kontekst P26)
    "v3_p18_scale_low_rate": 0.12,               # I04: PIT skala — próg dolny 12%
    "v3_p18_scale_high_rate": 0.32,              # I04: PIT skala — próg górny 32%
    "v3_p18_scale_threshold_pln": 120000,        # I04: próg skali
    "v3_p18_linear_rate": 0.19,                  # I04: PIT liniowy 19%
    "v3_p18_karta_monthly_pln": 700,             # I04: karta — stawka mies. [NIEZWERYFIKOWANE]
    "v3_p18_pit28_due": "02-20",                # I08: PIT-28 do 20 lutego
    "v3_p18_contract_tolerance_pln": 0.01,       # I07: tolerancja groszowa ryczałt↔PKPiR
    "v3_p18_golden_version": "ryczalt-golden-2026.09",   # I10: wersja golden set
    "v3_p18_invariants_active": true,            # I11: invarianty ryczałtu (kontrakt P04)
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

    # Art. 5 ust. 1 pkt 1 PP — działalność nieewidencjonowana (R02 P1)
    # Historia: 50% mies. (do 30.06.2023) → 75% mies. (od 01.07.2023) →
    # od 01.01.2026 limit KWARTALNY = 225% płacy min. (ekwiwalent mies. 75%).
    "unregistered_revenue_pct": 0.75,            # 75% min. wynagrodzenia (P930, od 01.07.2023)

    # GLM52 P11 — Ordynacja podatkowa: terminy obrony i korekt
    "correction_deadline_days": 14,              # Art. 81b — korekta deklaracji: 14 dni
    "whitelist_sanction_pct": 0.20,              # Art. 117ba — sankcja 20% przy braku powiadomienia
    "gaar_risk_flag": true,                      # Art. 119a — aktywna klauzula GAAR
    "appeal_deadline_days": 14,                  # Art. 223 — odwołanie od decyzji: 14 dni
    "audit_notification_days": 7,                # Art. 282b — zawiadomienie o kontroli: 7 dni
    "protocol_objection_days": 14,               # Art. 291 — zastrzeżenia do protokołu: 14 dni
    "wsa_appeal_days": 30,                       # Art. 53 PPSA — skarga do WSA: 30 dni
    "statute_limitation_break_reset": true,      # Art. 70 § 4 — przerwanie biegu przedawnienia
    "statute_limitation_suspend_kks": true,      # Art. 70 § 6 — zawieszenie (postęp. karno-skarbowe)
    "overpayment_claim_years": 5,                # Art. 72-80 — prawo do wniosku o nadpłatę: 5 lat
    "interest_lombard_multiplier": 2.0,          # Art. 56 — odsetki: 200% stopy lombardowej
    "instalment_relief_active": true,            # Art. 67a-67e — ulgi w spłacie

    # ── V3-P17 ORDYNACJA OBRONA (kampania V3 FORTRESS, pakiet jdg.v3_p17_ordynacja_obrona) ──
    # Odsetki / przedawnienie / GAAR / procedury obrony — parametry-as-data (ADR-002,
    # P06); temporalność przez valid_from (P05). Podstawy prawne do weryfikacji ISAP
    # (art. 30a/30b — stawki AUD oznaczone [NIEZWERYFIKOWANE] — patrz raport P17).
    "v3_p17_threshold_version": "ordynacja-obrona-v3p17-2026.09",
    "v3_p17_interest_rate_annual": 0.08,          # I01: art. 56 OP — bazowa stopa roczna (dane)
    "v3_p17_interest_rates_valid_from": "2023-01-01",  # I01: okno temporalne stawki (P05)
    "v3_p17_interest_capitalization": "MONTHLY",  # I01: art. 56 — kapitalizacja miesięczna
    "v3_p17_statute_years": 5,                    # I02: art. 70 — 5 lat
    "v3_p17_statute_end_rule": "CALENDAR_YEAR_END_PLUS_5",  # I02: koniec roku kal. + 5
    "v3_p17_limitation_alert_days": [90, 60, 30], # I02: alerty przed przedawnieniem
    "v3_p17_suspension_max_events": 3,            # I02: limit zdarzeń zawieszenia (art. 71)
    "v3_p17_gaar_mae_threshold_pln": 1000000,     # I03: art. 119a — MAE 1 mln zł
    "v3_p17_deadline_statement_days": 7,          # I04: art. 282b — stanowisko 7 dni
    "v3_p17_appeal_days": 14,                     # I04: art. 223 — odwołanie 14 dni
    "v3_p17_wsa_days": 30,                        # I04: art. 53 PPSA — skarga 30 dni
    "v3_p17_zero_silence_escalation_days": 2,     # I04: zero ciszy — eskalacja po 48h
    "v3_p17_aud_reduced_rate_pct": 0.0,           # I06: art. 30a/30b — stawka po ujawnieniu [NIEZWERYFIKOWANE]
    "v3_p17_aud_full_rate_pct": 0.12,             # I06: art. 30a/30b — stawka bazowa [NIEZWERYFIKOWANE]
    "v3_p17_ruling_4eyes_required": true,         # I07: wniosek KIS — wymagany review prawnika
    "v3_p17_interpretation_law_change_sentinel": true,  # I10: zmiana prawa = utrata ochrony
    "v3_p17_invariants_active": true,             # I11: pakiet invariantów (kontrakt P04)
    "v3_p17_stress_scenarios": ["interest_10y", "multi_suspension", "last_day_appeal"],  # I12
}

# ═══════════════════════════════════════════════════════════════════════════════
# KKS / ORDYNACJA PODATKOWA THRESHOLDS — RAPORT_07 (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════
# Wersjonowane dane KKS są jedynym źródłem progów używanych przez pakiety KKS.
# Zmiana prawa aktualizuje dane i valid_from/valid_to, a nie logikę reguł.

kks := {
    "min_wage": 4800.0,
    "daily_rate_denominator": 30,
    "daily_rate_max_multiple": 400,
    "crime_threshold_multiple": 200,
    "mandatory_prison_threshold": 5000000,
    "max_rates_crime": 720,
    "max_rates_misdemeanor": 240,
    "limitation_years_crime": 5,
    "limitation_years_misdemeanor": 3,
    "small_value_multiple": 500,
    "correction_interest_pct": 0.15,

    # GLM52 P11 — gradacja kar KKS (art. 54-83) i ścieżki minimalizacji
    "active_remorse_impact_pct": 0.50,           # Art. 16 — czynny żal: znikoma szkodliwość → umorzenie
    "voluntary_submission_impact_pct": 0.50,     # Art. 17 — dobrowolne poddanie się odpowiedzialności: 50% obniżki
    "small_value_min_pln": 100.0,                # Art. 53 § 6-8 — mała wartość: do 100 zł
    "lesser_weight_max_pln": 5000.0,             # Art. 53 § 9 — wypadek mniejszej wagi
    "daily_rate_min_pln": 77.0,                  # Art. 23 § 2 — stawka dzienna: min 1/720 min. wynagrodzenia
    "daily_rate_max_pln": 1540.0,                # Art. 23 § 2 — stawka dzienna: max 1/30 min. wynagrodzenia (2026)
    "daily_rates_crime_max": 720,                # Art. 27 § 1 — przestępstwo skarbowe: do 720 stawek
    "daily_rates_misdemeanor_max": 240,          # Art. 27 § 1 — wykroczenie skarbowe: do 240 stawek
    "joint_penalty_max_years": 3,                # Art. 39 — grzywna łączna
    "recidivism_days_window": 1825,              # Art. 37 — recydywa: 5 lat
    "statute_limitation_kks_years": 5,           # Art. 44 § 1 — przedawnienie karalności: 5 lat
    "conviction_expungement_years": 3,           # Art. 45 — zatarcie skazania
    "valid_from": "2026-01-01",
    "valid_to": null,
    "source_act": "Kodeks karny skarbowy; Ordynacja podatkowa",
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

    # Art. 22a ust. 4a PIT — limit wartości początkowej samochodów osobowych
    "passenger_car_limit_electric": 225000,       # PLN — auta elektryczne (P01 v9.x)
    "passenger_car_limit_standard": 150000,       # PLN — pozostałe auta osobowe

    # Art. 22k ust. 7 PIT — jednorazowa amortyzacja: limit roczny
    "one_off_annual_limit": 100000,               # PLN (P01 v9.x — z depreciation_enterprise_complete)
    "one_off_annual_limit_pre2018": 10000,        # PLN — limit jednorazowej amortyzacji przed 2018 (P01 v9.x)
    # Art. 22d ust. 2 PIT — pomoc de minimis: limit 3-letni
    "de_minimis_eur_3y": 50000,                   # EUR (P01 v9.x — z depreciation_enterprise_complete)
    "large_asset_triage_limit": 100000,          # PLN — ŚT > 100k -> TRIAGE_QUEUE (P01 v9.x)

    # UoR — progi ksiąg rachunkowych (Art. 2 ust. 1 pkt 5 UoR, P01 v9.x)
    "uor_books_threshold_eur": 2000000,          # EUR — próg obowiązku prowadzenia ksiąg
    "uor_early_warning_eur": 1500000,            # EUR — próg wczesnego ostrzeżenia
    "pkpir_lease_limit_pln": 150000,              # PLN — limit leasingu w PKPiR (Art. 23 PIT)
    "transport_damage_limit": 5000,               # PLN — szkoda transportowa -> TRIAGE

    # Art. 22k PIT — de minimis
    "de_minimis_annual_limit_eur": 50000,        # EUR rocznie

    # ── P06 GLM52 — AMORTYZACJA (RAPORT_GLM52_P06_PIT_MIKRO_AMORTYZACJA.txt) ──
    "one_time_depreciation_eur": 100000,         # EUR — jednorazowa amortyzacja (art. 22i / 22k ust. 7-12)
    "small_taxpayer_revenue_limit_eur": 2000000, # EUR — limit przychodów małego podatnika dla jednorazowej
    "low_value_asset_limit": 10000,              # PLN — niskocenne ŚT (art. 22f ust. 3 / art. 22d ust. 1)
    "degressive_coeff_machines": 2.0,            # art. 22k ust. 1 — maszyny grupy 3-6 i 8 + transport
    "degressive_coeff_other": 1.4,               # art. 22k ust. 2 — pozostałe ŚT
    "individual_rate_max_multiplier": 2.0,       # art. 22j/22n — stawka indywidualna max 2× standard
    "wnip_max_period_years": 5,                  # art. 22b ust. 1 — WNiP amortyzacja ≤ 5 lat
    # Standardowe roczne stawki KŚT (rozporządzenie MF w sprawie amortyzacji,
    # załącznik nr 1 — spójne z kst_groups w p06_pit_micro_innovations_v9.rego)
    "kst_rates": {
        "0": 0.0, "1": 0.015, "2": 0.045, "3": 0.07, "4": 0.14,
        "5": 0.20, "6": 0.18, "7": 0.20, "8": 0.20, "9": 0.20, "10": 0.20
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UoR / PKPiR / KSIĘGOWOŚĆ THRESHOLDS — RAPORT_09 (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

accounting := {
    # Art. 2 ust. 1 pkt 5 UoR — próg pełnej księgowości (2 000 000 EUR)
    "uor_threshold_eur": 2000000,               # 2M EUR
    "eur_pln_reference": 4.5,                   # kurs referencyjny NBP (umowny)
    "early_warning_pct": 75,                    # 75% progu — wczesne ostrzeżenie

    # Art. 22k ust. 7-12 PIT — jednorazowa amortyzacja (mały podatnik)
    "one_time_depreciation_eur": 100000,        # 100k EUR

    # Art. 23a pkt 47a PIT — limity aut osobowych (KUP)
    "car_limit_standard": 150000,               # 150k PLN
    "car_limit_electric": 225000,               # 225k PLN (elektryk)

    # Art. 26 UoR — harmonogram inwentaryzacji
    "inventory_cash_months": 12,                # środki pieniężne — co rok
    "inventory_stock_months": 12,               # zapasy — na koniec roku
    "inventory_fixed_assets_years": 4,          # środki trwałe — co 4 lata

    # Art. 45-49, 52 UoR — terminy sprawozdań finansowych
    "fs_approval_deadline": "03-31",            # zatwierdzenie 31.03
    "fs_filing_deadline": "10-15",              # złożenie 15.10
    "fs_retention_years": 5,                    # art. 74 UoR — 5 lat
    "valid_from": "2025-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# CROSS-BORDER / TP / MDR / CFC / EXIT TAX THRESHOLDS — RAPORT_10 (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

crossborder := {
    # Art. 42 ust. 12 VAT — dowód wywozu WDT (30 dni)
    "wdt_documentation_days": 30,               # 30 dni na zebranie dowodu

    # Art. 86a OrdPU — raportowanie MDR/DAC6 (30 dni)
    "mdr_deadline_days": 30,                    # 30 dni na MDR-1

    # Art. 23o/23zf PIT — dokumentacja cen transferowych
    "tp_local_file_pln": 500000,                # lokalna dokumentacja od 500k
    "tp_master_file_pln": 200000000,            # master file od 200M (grupa)

    # Art. 3 ust. 1a PIT — rezydencja podatkowa
    "residency_days": 183,                      # 183 dni

    # Art. 30f PIT — CFC
    "cfc_ownership_min_pct": 0.50,              # >50% udziałów
    "cfc_passive_income_pct": 0.33,             # >33% dochodu pasywnego
    "cfc_tax_rate_threshold_pct": 0.1425,       # <14.25% podatku zagranicznego

    # Art. 30da PIT — Exit tax
    "exit_tax_threshold_pln": 4000000,          # próg 4 000 000 PLN
    "exit_tax_rate_pct": 0.19,                  # 19%
    "exit_tax_deferral_years_eea": 5,           # art. 30da ust. 8 — odroczenie UE/EOG

    # V3-08 (kampania) — WHT / DAC8 / UK post-Brexit (zero hardcode)
    "wht_annual_threshold_pln": 2000000,        # art. 26 ust. 2e CIT — próg pay-and-refund
    "wht_standard_rate_pct": 0.20,              # art. 26 ust. 1 CIT — stawka standardowa
    "dac8_threshold_eur": 2000,                 # DAC8 Annex V — de minimis EUR/sprzedawcę
    "dac8_threshold_tx": 30,                    # DAC8 Annex V — de minimis liczba transakcji
    "dac8_deadline": "31_stycznia",             # termin raportu operatora platformy
    "uk_vat_registration_threshold_gbp": 90000, # UK VAT Act 1994 s.3 — próg B2C GBP

    # GLM52 P12 — TP progi dokumentacyjne (art. 23zf PIT) — domknięcie pustyni pokrycia
    "tp_goods_transactions_pln": 10000000,      # transakcje towarowe: 10 000 000 zł
    "tp_services_transactions_pln": 2000000,    # transakcje usługowe: 2 000 000 zł
    "tp_financial_transactions_pln": 2500000,   # transakcje finansowe: 2 500 000 zł
    "tp_documentation_months": 6,               # 6 miesięcy na dokumentację (art. 23zf)
    "tp_related_party_share_pct": 0.25,         # art. 23m ust. 1 pkt 4 — powiązania ≥25%
    "tp_market_price_arm_length": true,         # art. 23o — zasada ceny rynkowej
    "tp_adjustment_sanction_pct": 0.10,         # art. 23zb — korekta 10%

    # GLM52 P12 — MDR/DAC6 (art. 86a-86o OrdPU) + CBAM/DAC8/ViDA
    "mdr_mbt_threshold_eur": 250000,            # główna korzyść podatkowa: 250k EUR
    "mdr_hallmark_reportable": true,            # hallmarks A-E → raportowanie
    "mdr_sanction_daily_rates": 720,            # art. 80f-80h KKS: do 720 stawek
    "cbam_registration_threshold_eur": 150,     # CBAM: przesyłki ≤150 EUR wyłączone
    "cbam_quarterly_reports": true,             # CBAM: raporty kwartalne
    "cbam_certificate_required_2026": true,     # CBAM: pełny mechanizm od 2026
    "dac8_crypto_reporting_2026": true,         # DAC8: raportowanie krypto od 2026
    "vida_platform_rules_2030": true,           # ViDA: e-fakturowanie 2030+
    # ETAP 17 — safety/evidence gates (ADR-006/ADR-022)
    "mdr_risk_high_threshold": 70,
    "source_registry": "data.jdg.legal_source_registry",
    "threshold_version": "crossborder-2026.08",
    "legal_basis_version": "isap-lkg-2026.08",
    "valid_from": "2025-01-01",
    "valid_to": null,

    # ═════════════════════════════════════════════════════════════════════════
    # V3-P15 CROSS-BORDER ENTERPRISE (kampania V3 FORTRESS) — ADR-002 zero hardcode
    # ═════════════════════════════════════════════════════════════════════════
    # V3-P15-I01: Place-of-Supply Matrix (art. 28a-28o VAT)
    "pos_b2b_rule": "28b",                        # B2B — miejsce siedziby nabywcy
    "pos_b2c_rule": "28c",                        # B2C — miejsce świadczenia usługi
    "pos_real_estate_rule": "28e",                # nieruchomości — miejsce położenia
    "pos_restaurant_rule": "28f",                 # gastronomia — miejsce wykonania
    "pos_accommodation_rule": "28g",              # krótkoterminowe zakwaterowanie
    "pos_digital_b2c_rule": "28k",                # usługi elektroniczne B2C — miejsce konsumpcji
    # V3-P15-I02: EU VAT Rates Feed (stawki UE jako dane z valid_from)
    "eu_vat_rates_feed_source": "https://taxation-customs.ec.europa.eu/vat-rates_en",
    "eu_vat_rates_version": "2026-07",
    # V3-P15-I04: FX Precision Engine (kursy NBP D-1, groszowe zaokrąglenia)
    "fx_rounding_rule": "round_half_up",          # zaokrąglanie wg art. 22b VAT kontekst
    "fx_rounding_scale": 2,                        # grosz (0,01)
    "fx_use_previous_day_rate": true,              # kurs D-1 dla ewidencji (P28)
    # V3-P15-I05: TP Threshold Sentinel (art. 23o/23zf PIT) — alerty dokumentacyjne
    "tp_monitoring_alert_days": 30,                # alert przed upływem terminu dokumentacji
    # V3-P15-I06: MDR Hallmark Scorer (art. 86a OrdPU / DAC6)
    "mdr_human_review_required": true,             # human review WYMUSZONY
    "mdr_reporting_deadline_days": 30,             # termin MDR-1 od zdarzenia
    # V3-P15-I07: Exit Tax Early Warning (art. 24cg/30da PIT)
    "exit_tax_early_warning_days": 60,             # alert 60 dni przed zdarzeniem
    # V3-P15-I08: Cross-Border Golden Set (Golden Oracle P10)
    "golden_set_min_verdicts": 30,                 # minimalna reprezentatywność golden setu
    # V3-P15-I09: OSS Decision Advisor (art. 28k-28m VAT)
    "oss_distance_selling_threshold_eur": 10000,   # próg sprzedaży wysyłkowej B2C (art. 24)
    "oss_annual_threshold_eur": 100000,            # próg roczny dla rekomendacji OSS
    # V3-P15-I10: Distance Selling Tracker (art. 24/25 VAT)
    "distance_selling_limit_eur": 10000,           # próg per kraj (10k EUR standard UE)
    # V3-P15-I11: Cross-Border Invariants (P04)
    "wdt_invariant_required": true,                # WDT wymaga VAT-UE + VIES nabywcy
    "fx_d1_invariant_required": true,              # kurs D-1 dla ewidencji
    "import_services_rc_required": true,           # import usług — reverse charge obowiązkowy
    # V3-P15-I12: Currency Consistency Gate (kontrakt P28/P16)
    "currency_consistency_required": true,         # te same kursy VAT i PKPiR
    "v3_p15_threshold_version": "crossborder-v3p15-2026.09",
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P27 CROSSBORDER GOVERNANCE (kampania V3 FORTRESS, jdg.v3_p27_cfc_exit_mdr)
# Governance CFC/EXIT/MDR jako dane (ADR-002/P06) + okno temporalne (P05).
# Wartości rdzenia (progi exit tax, MDR 30 dni, CFC, rezydencja) — w bloku
# crossborder powyżej (jedno źródło prawdy); poniżej wyłącznie v3_p27_*.
# Statusy weryfikacji: 2M/4M exit tax i 10M/2.5M EUR MDR [ZWERYFIKOWANO-WEB,
# 2026-09-06]; de minimis CFC 250k EUR [NIEZWERYFIKOWANE] — kaucja I03/I07.
# ═══════════════════════════════════════════════════════════════════════════════

crossborder27 := {
    "v3_p27_threshold_version": "crossborder-v3p27-2026.09",
    "legal_basis_version": "PIT+OrdPU-v3p27-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I02/I03: exit tax — progi/lock/raty (2M art. 24cg ust. 5; 4M rdzeń; lock 5 lat)
    "v3_p27_exit_tax_property_threshold_pln": 2000000,
    "v3_p27_exit_tax_reinvestment_lock_years": 5,
    "v3_p27_exit_tax_installments_eea": 5,
    "v3_p27_exit_tax_signal_deadline": "7th_of_next_month",   # info-rule (art. 30da ust. 9)
    # I03: weryfikator progów (ISAP gate)
    "v3_p27_verifier_version": "v3p27-verify-2026.09",
    "v3_p27_verifier_drift_pln": 0.01,                        # groszowa czułość (golden P26)
    # I04: MDR hallmark scorer v2 (human review)
    "v3_p27_mdr_human_review_score": 70,
    # I05: MDR 30-day gate (kalendarz P25)
    "v3_p27_mdr_warn_days": 7,
    "v3_p27_mdr_weekend_shift": true,
    "v3_p27_mdr_zero_silence": true,
    # I06: MDR funkcja pomocnicza / kryterium kwalifikowanego korzystającego
    "v3_p27_mdr_qualified_beneficiary_eur": 10000000,
    "v3_p27_mdr_arrangement_value_eur": 2500000,
    "v3_p27_mdr_auxiliary_excludes": false,
    # I07: CFC signal detector (sygnały, nie rachunek)
    "v3_p27_cfc_ownership_min_pct": 25,
    "v3_p27_cfc_passive_signal_pct": 50,
    "v3_p27_cfc_de_minimis_eur": 250000,                      # [NIEZWERYFIKOWANE]
    # I09: katalog metod wyceny exit tax
    "v3_p27_valuation_methods": ["MARKET_COMPARABLE", "INCOME_APPROACH", "COST_APPROACH"],
    # I11/I12: golden + stress
    "v3_p27_golden_version": "intl-golden-2026.09",
    "v3_p27_golden_tolerance": 0.01,
    "v3_p27_stress_required_scenarios": 3,
    # I08: konstytucja międzynarodowa (P04)
    "v3_p27_invariants_active": true,
    "v3_p27_mdr_human_only": true,
    "v3_p27_exit_tax_advisor_only": true,
    "v3_p27_cfc_needs_advice_only": true,
}

hyper45 := {
    "v3_p28_threshold_version": "hyper-v3p28-2026.09",
    "legal_basis_version": "OP+VAT+PZP-v3p28-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I03: force majeure — katalog zdarzeń + limit trwania + kalendarz P25
    "v3_p28_force_majeure_max_days": 90,
    "v3_p28_force_majeure_calendar_p25_linked": true,
    "v3_p28_force_majeure_degradation": "NEEDS_ADVICE",
    # I04: sanctions gate — wersje list + human review + AML P22
    "v3_p28_sanctions_list_version": "eu-un-2026.09",
    "v3_p28_sanctions_human_review_required": true,
    "v3_p28_sanctions_aml_p22_linked": true,
    # I05: rejestr domen marginalnych (decyzje jawne)
    "v3_p28_marginal_register_version": "v3p28-md-2026.09",
    # I06: esig — próg podpisu kwalifikowanego + kontrakt kluczy
    "v3_p28_esig_qualified_threshold_pln": 10000,
    "v3_p28_esig_contract_p11_p16": true,
    # I07: crisis drill — komplet scenariuszy (P04 K10)
    "v3_p28_crisis_required_scenarios": 3,
    "v3_p28_crisis_zero_silence": true,
    # I08: network consistency — oczekiwana liczba hiperkontekstów
    "v3_p28_network_expected_contexts": 14,
    "v3_p28_network_gap_blocker": true,
    # I09: konstytucja hiperkontekstów (P04)
    "v3_p28_invariants_active": true,
    "v3_p28_sanctions_human_only": true,
    "v3_p28_fm_calendar_only": true,
    "v3_p28_fx_single_engine": true,
    "v3_p28_hyper_no_silent_auto_post": true,
    # I10: golden set granic (P10)
    "v3_p28_golden_version": "hyper-golden-2026.09",
    "v3_p28_golden_tolerance": 0.01,
    # I11: pustynie testowe domen marginalnych
    "v3_p28_cleanup_max_untested": 3,
    # I01: mapa kontekstów
    "v3_p28_context_map_version": "v3p28-hcm-2026.09",
}

# ═══════════════════════════════════════════════════════════════════════════════
# PCC / PODATKI LOKALNE / AKCYZĄ THRESHOLDS — RAPORT_11 (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

pcc_local_excise := {
    # Ustawa o PCC — art. 6-7 (stawki)
    "pcc_sale_rate": 0.02,                      # sprzedaż 2%
    "pcc_loan_rate": 0.005,                     # pożyczka 0,5%
    "pcc_company_rate": 0.005,                  # spółki 0,5%
    "pcc_mortgage_rate": 0.001,                 # hipoteka 0,1%
    "pcc_exemption_limit": 1000,                # zwolnienie ≤1000 zł (art. 9)
    "pcc_family_loan_limit": 36120,             # pożyczka rodzinna 36 120 zł
    "pcc3_deadline_days": 14,                   # PCC-3 14 dni (art. 10)

    # Podatek od nieruchomości (stawki maksymalne 2026)
    "land_business_rate": 1.43,                 # PLN/m² grunt biznes
    "building_business_rate": 33.10,            # PLN/m² budynek biznes

    # Podatek od środków transportowych + DN-1
    "transport_dn1_deadline_days": 14,          # DN-1 14 dni

    # Akcyza — paliwa (zł/1000l, 2026)
    "excise_gasoline": 1566,                    # benzyna
    "excise_diesel": 1206,                      # olej napędowy
    "excise_lpg": 695,                          # LPG

    # Akcyza — alkohol (zł/hl, 2026)
    "excise_ethanol_per_hl": 6900,              # etanol 100%
    "excise_beer_per_plato": 8.57,              # piwo za °Plato
    "excise_wine_per_hl": 185,                  # wino (stawka do weryfikacji ISAP — P27 fix AP02)
    # V3-10 (kampania) — wersjonowanie snapshotu dla Decision Certificates
    "threshold_version": "pcc-local-2026.08",
    "legal_basis_version": "isap-lkg-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,

    # ── V3-P19 PCC / LOKALNE / BDO ENTERPRISE (kampania V3 FORTRESS, jdg.v3_p19_pcc_akcyza_bdo) ──
    # Stawki PCC/limity gminne/akcyza już w bloku (pcc_sale_rate, land_*_rate itd.) —
    # poniżej tylko BRAKUJĄCE dane P19 (terminy, raty, BDO/EWC/CBAM, invarianty),
    # ADR-002/P05; akcyza/CBAM = decyzje architektoniczne [NIEZWERYFIKOWANE — Q01/Q02].
    "v3_p19_threshold_version": "pcc-lokalne-bdo-v3p19-2026.09",
    "v3_p19_property_installments": ["03-15", "05-15", "09-15", "11-15"],  # I04/I11: raty nieruchomości art. 12-13 UoPiOL
    "v3_p19_transport_due": "01-31",                # I04: podatek transportowy do 31.01
    "v3_p19_zero_silence_escalation_days": 2,        # I04: zero ciszy — eskalacja 48h
    "v3_p19_statutory_limit_check": true,            # I02: walidacja stawek gminnych z limitami ustawowymi
    "v3_p19_mpp_pcc_exclusion": true,                # I03: bramka MPP faktura ≠ PCC (zero podwójnego opodatkowania)
    "v3_p19_loan_exemption_limit": 1000,             # I01/I09: zwolnienie pożyczek do 1000 zł (art. 9 pkt 10)
    "v3_p19_bdo_waste_threshold_kg": 100,            # I05: BDO — próg odpadów do rejestracji [NIEZWERYFIKOWANE]
    "v3_p19_bdo_packaging_active": true,             # I05: BDO — wprowadzający opakowania
    "v3_p19_weee_seller_registration": true,         # I05: WEEE — rejestr sprzedawców [NIEZWERYFIKOWANE]
    "v3_p19_waste_fee_per_kg_pln": 0.30,             # I07: opłata za odpady [NIEZWERYFIKOWANE — stawki wg kodów]
    "v3_p19_ewc_library_version": "ewc-2026.01",    # I06: wersja bazy kodów EWC
    "v3_p19_cbam_monitor_active": true,              # I08: monitoring importu CBAM
    "v3_p19_cbam_goods": ["CEMENT", "STAL", "ALUMINIUM", "NAWOZY", "WODOR", "ENERGIA"],  # I08
    "v3_p19_golden_version": "pcc-local-golden-2026.09",  # I09: wersja golden set
    "v3_p19_invariants_active": true,                # I10: invarianty lokalne (kontrakt P04)
    "v3_p19_bdo_report_due": "03-15",               # I05/I07: raport BDO do 15.03 [NIEZWERYFIKOWANE]
    "v3_p19_pcc3_form": "PCC-3",                    # I01: formularz PCC-3
}

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 19 — PCC / LOKALNE / AKCYZA EVIDENCE REGISTRY (ADR-002)
# Temporalne dane kontraktu; konkretne uchwały gminne przychodzą w evidence input.
# ═══════════════════════════════════════════════════════════════════════════════

local_excise_etap19 := {
    "registry_version": "local-excise-2026.08",
    "source_registry": "data.jdg.legal_source_registry",
    "legal_basis_version": "isap-lkg-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "pcc_rates": {
        "SALE": 0.02,
        "LOAN": 0.005,
        "COMPANY": 0.005,
        "MORTGAGE": 0.001,
        "EXCHANGE": 0.01
    },
    "pcc_exemption_limit": 1000,
    "family_loan_limit": 36120,
    "pcc3_deadline_days": 14,
    "dn1_deadline_days": 14,
    "transport_threshold_t": 3.5,
    "excise_rates": {
        "GASOLINE": 1566,
        "DIESEL": 1206,
        "LPG": 695,
        "ETHANOL": 6900,
        "BEER": 8.57,
        "WINE": 185,
        "CIGARETTES": 105,
        "ELECTRICITY": 5
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 20 — KSeF / JPK / E-DEKLARACJE EVIDENCE REGISTRY (ADR-002)
# Dane kontraktu są zewnętrzne wobec reguły; konkretne dowody pochodzą z inputu.
# ═══════════════════════════════════════════════════════════════════════════════

ksef_jpk_etap20 := {
    "registry_version": "ksef-jpk-etap20-2026.08",
    "source_registry": "data.jdg.legal_source_registry",
    "legal_basis_version": "isap-mf-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "offline_grace_days": 7,
    "max_retries": 3,
    "upo_deadline_days": 1,
    "reconciliation_tolerance_pln": 0.01,
    "required_invoice_fields": ["P_1", "P_2", "P_3", "P_4", "P_5", "P_6", "P_7", "P_8"],
    "schema_registry": ["FA(2)", "FA(2)-KOREKTA", "JPK_V7M", "JPK_V7K", "JPK_KR", "JPK_ST"],
    "declaration_types": ["JPK_V7M", "JPK_V7K", "JPK_KR", "JPK_ST", "E_DEKLARACJA"],
    "gtu_codes": ["GTU_01", "GTU_02", "GTU_03", "GTU_04", "GTU_05", "GTU_06", "GTU_07", "GTU_08", "GTU_09", "GTU_10", "GTU_11", "GTU_12", "GTU_13"],
    "signature_types": ["QUALIFIED", "TRUSTED"],
    "deadline_policy": "JPK_V7 do 25. dnia miesiąca; termin z inputu musi być udowodniony",
    "offline_policy": "kolejka offline, retry i UPO po przywróceniu MF; przekroczenie blokuje",
    "exactly_once_policy": "outbox + idempotency_key + brak duplikatu; brak dowodu nie oznacza wysyłki",
}

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 21 — RODO / AML / BDO / HR EVIDENCE REGISTRY (ADR-002)
# Wartości są danymi konfiguracyjnymi; dowody konkretnej sprawy pochodzą z inputu.
# ═══════════════════════════════════════════════════════════════════════════════

rodo_aml_bdo_hr_etap21 := {
    "threshold_version": "rodo-aml-bdo-2026.08",   # Golden Oracle F3 (kampania V3, część 12)
    "registry_version": "compliance-hr-etap21-2026.08",
    "source_registry": "data.jdg.legal_source_registry",
    "legal_basis_version": "isap-uodo-aml-bdo-kp-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "rodo_breach_deadline_hours": 72,
    "rodo_erasure_deadline_days": 30,
    "aml_transaction_threshold_eur": 15000,
    "ubo_minimum_pct": 25,
    "bdo_kpo_deadline_days": 7,
    "pfron_employee_threshold": 25,
    "privacy_minimization_required": true,
    "manual_approval_required": true,
    "aml_str_requires_reference": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 22 — HYPER ENTERPRISE CONTEXTS META REGISTRY (ADR-002)
# Rejestr kontraktu meta-validatora: kontekst, graf, deadline, limit i safety.
# ═══════════════════════════════════════════════════════════════════════════════

hyper_enterprise_contexts_etap22 := {
    "registry_version": "hyper-etap22-2026.08",
    "source_registry": "data.jdg.legal_source_registry",
    "legal_basis_version": "isap-hyper-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "allowed_priorities": ["P0", "P1", "P2", "P3"],
    "context_catalog": ["GENERAL", "DEADLINES", "LIMITS", "MDR", "SANCTIONS", "FX", "WIS", "EDELIVERY", "SPECIAL"],
    "required_contract_fields": ["input_hash", "evidence_ref", "result", "test_ref", "recipient"],
    "dependency_graph_required": true,
    "conflict_detector_required": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# RODO / AML / BDO THRESHOLDS — RAPORT_15 + RAPORT_14 (ADR-002) — zmergowane
# (GLM52 P15: usunięty duplikat kompletnej reguły rodo_aml_bdo — 2× blok
# w tym samym pakiecie = błąd kompilacji OPA; skonsolidowano klucze RAPORT_14
# i RAPORT_15 w jeden kanoniczny blok).
# ═══════════════════════════════════════════════════════════════════════════════

rodo_aml_bdo := {
    # RODO (UE 2016/679)
    "rodo_erasure_deadline_days": 30,            # art. 17 — usunięcie w 30 dni
    "rodo_breach_deadline_hours": 72,            # art. 33 — zgłoszenie naruszenia 72 h
    "rodo_fine_max_eur": 20000000,               # art. 83 ust. 5 — 20 mln EUR / 4% obrotu
    "rodo_sanction_min_eur": 10000000,           # art. 83 ust. 4 — 10 mln EUR / 2% obrotu
    "rodo_sanction_max_eur": 20000000,           # art. 83 ust. 5 — 20 mln EUR / 4% obrotu
    # AML (ustawa z 1.03.2018, Dz.U. 2025 poz. 213)
    "aml_cash_threshold_eur": 15000,             # art. 34 — transakcje okazjonalne > 15 000 EUR
    "aml_threshold_eur": 15000,                  # art. 34 — transakcje > 15 000 EUR
    "aml_str_deadline_hours": 48,                # art. 74-80 — STR/GIIF 48 h
    "aml_str_deadline_days": 1,                  # art. 74-80 — STR do GIIF (dzień roboczy)
    "aml_sanction_max_pln": 1000000,             # art. 153 u.AML — kara do 1 mln zł
    # BDO / odpady (Dz.U. 2025 poz. 321)
    "bdo_registration_fee_pln": 100,             # art. 17-18 — opłata rejestracyjna 100-500 zł
    "bdo_fee_micro_pln": 100,                    # opłata rejestracyjna mikro
    "bdo_registration_days": 30,                 # termin rejestracji w BDO
    "bdo_kpo_electronic": true,                  # KPO elektroniczna
    "bdo_fine_art194_pln": 5000,                 # art. 194 — kara 5000 zł (brak ewidencji/rejestracji)
    "valid_from": "2026-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# HYPER PLAN45 / KONTEKSTY / KALENDARZ THRESHOLDS — RAPORT_16 (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

hyper := {
    # Kalendarz / terminy (art. 12 § 5 OP — przesunięcia weekendowe/świąteczne)
    "deadline_alert_7": 7,                        # alert żółty — 7 dni przed terminem
    "deadline_alert_3": 3,                        # alert AMBER — 3 dni przed terminem
    "deadline_alert_1": 1,                        # alert RED — 1 dzień przed terminem
    "vat_jpk_deadline_day": 25,                   # JPK_V7 / deklaracja VAT — 25.
    "pit_advance_deadline_day": 20,               # zaliczka PIT — 20.
    "zus_social_deadline_day": 10,                # składki ZUS społeczne — 10.
    "zus_health_deadline_day": 20,                # składka zdrowotna — 20.
    "pit_annual_deadline_month": 4,               # PIT roczne — 30.04
    "pit_annual_deadline_day": 30,
    "pcc3_deadline_days": 14,                     # PCC-3 — 14 dni od czynności
    "mdr_deadline_days": 30,                      # MDR-3 — 30 dni od schematu
    "str_deadline_hours": 48,                     # STR/GIIF — 48 h od podejrzenia
    "bdo_quarterly": true,                        # ewidencja/sprawozdanie BDO — kwartalnie
    "interest_rate_annual_pct": 9.75,             # odsetki za zwłokę — 200% stopy lombardowej NBP
    # Limity (centralny rejestr — jeden punkt prawdy)
    "limit_vat_113_pln": 200000,                  # art. 113 VAT — zwolnienie podmiotowe
    "limit_pit0_young_pln": 85528,                # ulga dla młodych — 85 528 zł
    "limit_tax_scale_threshold_pln": 120000,      # próg podatkowy 12%/32%
    "limit_lump_sum_2m_eur": 2000000,             # limit ryczałtu — 2 mln EUR
    "limit_mpp_pln": 15000,                       # mechanizm podzielonej płatności
    "limit_maly_zus_pln": 120000,                 # Mały ZUS+ — limit przychodu
    "limit_alert_ratio": 0.95,                    # alert 95% progu (limit radar)
    "valid_from": "2026-01-01",
    "valid_to": null,
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
# RYCZAŁT / CEIDG / CYKL ŻYCIA THRESHOLDS — RAPORT_12 (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

business_lifecycle := {
    # Ustawa o ryczałcie art. 6 — limit 2 mln EUR
    "ryczalt_limit_eur": 2000000,               # limit przychodów ryczałtu (art. 6 ust. 1)
    "eur_pln_reference": 4.3,                   # referencyjny kurs EUR/PLN (przeliczenie)
    "ryczalt_warning_pct": 75,                  # próg ostrzeżenia (% limitu)

    # Ustawa o ryczałcie art. 12 — stawki wg PKWiU
    "ryczalt_rate_min": 0.03,                   # minimalna stawka 3%
    "ryczalt_rate_max": 0.25,                   # maksymalna stawka 25%

    # Karta podatkowa (art. 21-28)
    "karta_max_employees": 5,                   # limit zatrudnienia (karta podatkowa)

    # CEIDG (art. 5-15)
    "ceidg_registration_days": 7,               # wpis/zmiana CEIDG (art. 16 ust. 3 PP)

    # Sukcesja (art. 3-15 u.z.s.)
    "succession_ceidg_days": 14,                # wpis zarządcy sukcesyjnego do CEIDG
    "succession_default_months": 24,            # 2 lata standardowo (art. 12)
    "succession_extended_months": 60,           # do 5 lat (art. 13)

    # Działalność nieewidencjonowana (art. 5-6 PP)
    "unregistered_min_wage_pct": 0.5,           # 50% płacy minimalnej
    "min_wage_pln": 4800.0,                     # płaca minimalna (PLN)

    # Zawieszenie (art. 22-25 PP)
    "suspension_max_months": 24,                # max 24 mies. zawieszenia
    "suspension_min_days": 30,                  # min. 30 dni zawieszenia (art. 22 ust. 3 PP)
    "suspension_alert_pct": 90,                 # alert przy 90% limitu 24 mies.

    # Ryczałt — monitor limitu 2M EUR (art. 6 ust. 4: kurs NBP z 1.10)
    "ryczalt_limit_alert_pct": 95,              # alert przy 95% limitu
    "ryczalt_limit_exceeded_penalty_pct": 0.0,  # brak kary — przejście na skalę od 1.01

    # Ryczałt — stawki PKWiU (art. 12 ust. 1 u.z.p.d.)
    "ryczalt_rate_3_pct": 0.03,                 # działalność wytwórcza 3%
    "ryczalt_rate_55_pct": 0.055,               # działalność wytwórcza/roboty budowlane 5,5%
    "ryczalt_rate_85_pct": 0.085,               # usługi 8,5%
    "ryczalt_rate_10_pct": 0.10,                 # wybrane usługi 10%
    "ryczalt_rate_12_pct": 0.12,                 # wybrane usługi 12%
    "ryczalt_rate_125_pct": 0.125,              # wybrane przychody 12,5%
    "ryczalt_rate_14_pct": 0.14,                # wybrane usługi 14%
    "ryczalt_rate_15_pct": 0.15,                # wybrane usługi 15%
    "ryczalt_rate_17_pct": 0.17,                # wolne zawody 17%
    "ryczalt_rate_20_pct": 0.20,                # 20% (przychody z działów specjalnych)
    "ryczalt_rate_25_pct": 0.25,                # 25% (pozostałe usługi, art. 12 ust. 1 pkt 5)

    # Sukcesja (art. 3-15 u.z.s.) — pełny cykl
    "succession_appointment_days": 14,          # powołanie zarządcy → wpis CEIDG 14 dni
    "succession_death_notice_days": 30,         # zgłoszenie śmierci do ZUS 30 dni
    "succession_remnant_deadline_days": 30,     # remanent sukcesyjny 30 dni
    "succession_ext_extension_years": 3,        # przedłużenie do 3 lat (art. 13)

    # Działalność nieewidencjonowana (art. 5-6 PP)
    "unregistered_monitor_monthly": true,       # monitor miesięczny 50% minimalnej

    # Cykl życia JDG — fazy
    "lifecycle_ulga_start_months": 6,           # ulga na start 0-6 mies.
    "lifecycle_pref_zus_months": 24,            # preferencyjny ZUS 6-30 mies.
    "lifecycle_vat_threshold_pln": 200000,      # próg VAT (art. 113 ust. 1)
    "lifecycle_health_scorecard_levels": 5,     # poziomy health scorecard (A-E)

    # ETAP 18 — formalny state machine i legal-source contract
    "state_machine_version": "lifecycle-2026.08",
    "source_registry": "data.jdg.legal_source_registry",
    "legal_basis_version": "isap-lkg-2026.08",
    "rollback_requires_owner_approval": true,
    "effective_date_required": true,
    "growth_transition_days": 7,
    "resume_registration_days": 7,
    "tax_form_change_days": 20,
    "close_notice_days": 7,
    "close_finalize_days": 30,
    "valid_from": "2025-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# HYPER PLAN45 / KONTEKSTY SPECJALNE THRESHOLDS — RAPORT_13 (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

hyper_contexts := {
    # Danina solidarnościowa (art. 30h PIT)
    "solidarity_threshold_pln": 1000000,         # próg 1 mln PLN
    "solidarity_rate": 0.04,                     # 4% od nadwyżki

    # IP Box vs B+R (art. 30ca PIT)
    "ip_box_rate": 0.05,                         # 5% IP Box
    "rd_relief_rate": 0.30,                      # ulga B+R 30% (art. 26e)

    # Prokura (art. 109¹-109⁸ KC)
    "prokura_deadline_days": 7,                  # wpis prokury do CEIDG/KRS

    # Terminy roczne (art. 45 PIT)
    "pit_annual_deadline": "04-30",              # 30 kwietnia

    # Podpis kwalifikowany (eIDAS art. 25-26, art. 126 § 5 OP)
    "qualified_signature_value_threshold": 10000,  # próg wartości dokumentu (PLN)

    "valid_from": "2025-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# KSeF / JPK / e-DEKLARACJE / GTU / WIS THRESHOLDS — RAPORT_15 (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

ksef_jpk := {
    # KSeF (art. 106na-106nb VAT)
    "ksef_mandatory_from": "2026-02-01",         # obowiązek KSeF od 01.02.2026
    "ksef_offline_grace_days": 7,                # tryb awaryjny — 7 dni (art. 106nb)
    "ksef_sanction_max_pln": 500000,             # max sankcja za brak KSeF
    "ksef_upo_deadline_days": 1,                 # termin UPO

    # JPK (art. 82/99 VAT, art. 193a OrdPU)
    "jpk_v7_deadline_day": 25,                   # dzień terminu JPK_V7M (25.)
    "jpk_ksef_penalty_per_invoice": 1000,        # kara per faktura

    # GTU / WIS
    "wis_response_days": 3,                      # termin odpowiedzi WIS (art. 42a)
    "gtu_codes": ["GTU_01", "GTU_02", "GTU_03", "GTU_04", "GTU_05", "GTU_06", "GTU_07", "GTU_08", "GTU_09", "GTU_10", "GTU_11", "GTU_12", "GTU_13"],

    "valid_from": "2025-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# SYSTEM OPA THRESHOLDS — RAPORT_16 (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

system_opa := {
    # Cykl życia reguły / rollout
    "canary_percent": 5,                         # kanarek 5% ruchu
    "rollback_error_threshold": 0.01,            # błąd > 1% → auto-rollback
    "rollback_quality_threshold": 0.95,          # jakość ≥ 95% → zatrzymaj kanary

    # Walidacja / CI
    "mutation_score_min": 70,                    # min wynik mutacji %
    "zero_defect_gates": 7,                      # kryteriów certyfikacji
    "coverage_min_pct": 90,                      # min pokrycie testami %
    "stub_threshold": 10,                        # alert przy > 10 stubów na plik
    "hardcoded_threshold": 10,                   # alert przy > 10 hardcode'ów na plik

    # Pipeline ISAP→produkcja
    "isap_sla_hours": 24,                        # standardowy termin adaptacji
    "isap_p0_hours": 4,                          # priorytet P0
    "hot_reload_minutes": 15,                    # parametr hot-reload ≤ 15 min

    "valid_from": "2025-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENTERPRISE AI THRESHOLDS — RAPORT_17 (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

enterprise_ai := {
    # Adaptive Trust (Trust Score progi — granica decyzyjna V1/V2)
    "trust_auto_post_min": 0.92,                 # ≥0.92 → AUTO_POST
    "trust_suggest_min": 0.75,                   # ≥0.75 → SUGGEST; <0.75 → ASK_USER

    # Neural Rule Mesh (pewność synapse)
    "mesh_confidence_min": 0.5,                  # min pewność propagacji synapse
    "mesh_conflict_penalty": 0.2,                # kara za konflikt między domenami

    # Cashflow & Tax Predictor
    "forecast_horizon_days": 90,                 # horyzont prognozy (art. 44/103/47)
    "liquidity_buffer_pct": 20,                  # min bufor płynności %

    # Bankowość PSD2 / MPP (split payment)
    "split_payment_threshold_pln": 15000,        # art. 108a MPP — próg brutto
    "batch_max_items": 100,                      # max przelewów w batchu miesięcznym

    # Monitor legislacyjny (vacatio legis)
    "vacatio_legis_days": 14,                    # standardowa vacatio legis
    "impact_high_threshold": 70,                 # próg wysokiego wpływu nowelizacji 0-100

    "valid_from": "2025-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 24 TESTS / CI / QUALITY THRESHOLDS (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 25 TOOLS / API / RULESTORE / BUNDLES CONTROL-DATA PLANE THRESHOLDS
# (ADR-002 zero hardcode; V1 §9, V2 §8, V1 §12.2)
# ═══════════════════════════════════════════════════════════════════════════════

tools_api_rulestore_bundles_etap25 := {
    "registry_version": "tools-api-rulestore-bundles-etap25-2026.08",
    "legal_basis_version": "control-data-plane-2026.08",
    "min_canary_pct": 5,
    "max_shadow_delta_pct": 2.0,
    "soak_hours": 24,
    "max_rollback_mttr_min": 5,
    "hot_reload_sla_min": 15,
    "max_rpo_min": 15,
    "max_rto_min": 30,
    "max_openapi_gap_count": 0,
    "sod_four_eyes_required": true,
    "worm_append_only": true,
    "production_status": "NOT_CERTIFIED",
    "required_gates": ["api_schema", "authnz_rbac_sod", "idempotency", "versioning", "migrations_constraints", "bundle_signing_sbom", "node_verification", "healthy_persisted", "progressive_delivery", "hot_reload", "worm_merkle", "disaster_recovery", "production_honesty"],
    "valid_from": "2026-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 26 POLICIES MIRROR / SYNC / OVERLAYS THRESHOLDS (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

policies_mirror_sync_etap26 := {
    "registry_version": "policies-mirror-sync-etap26-2026.08",
    "legal_basis_version": "mirror-sync-2026.08",
    "max_drift_pct": 0.0,
    "min_parity_pct": 100.0,
    "source_of_truth": "JDG/rules/",
    "mirror_role": "OVERLAY",
    "experimental_variants_marked": true,
    "overlays_required": ["v2026", "v2027"],
    "required_gates": ["source_of_truth", "mirror_sync", "hash_parity", "decision_parity", "legal_parity", "overlays_tcl", "no_ghosts", "experimental_marked", "no_silent_change"],
    "valid_from": "2026-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 27 CROSS-DOMAIN RED TEAM / INTEGRATION / RESILIENCE THRESHOLDS (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

cross_domain_red_team_etap27 := {
    "registry_version": "cross-domain-red-team-etap27-2026.08",
    "legal_basis_version": "red-team-resilience-2026.08",
    "min_conflict_pairs": 6,
    "min_attack_scenarios": 12,
    "min_chaos_experiments": 8,
    "max_rto_min": 30,
    "max_fail_closed_errors_silent": 0,
    "auto_post_always_blocked_on_error": true,
    "required_gates": ["conflict_registry", "attack_catalog", "chaos_matrix", "temporal_boundary", "fraud_scenarios", "fail_closed_proof", "auto_post_guard", "contract_tests", "tools_verified"],
    "valid_from": "2026-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 28 FINAL CERTIFICATION / MASTER REPORT THRESHOLDS (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

final_certification_etap28 := {
    "registry_version": "final-certification-etap28-2026.08",
    "total_etapy": 28,
    "min_wdrozone_etapy": 28,
    "max_unproven_reports": 0,
    "min_audit_states": 20,
    "min_domains_certified_or_conditional": 15,
    "max_blocked_domains": 0,
    "production_status": "NOT_CERTIFIED",
    "required_gates": ["reconciliation", "traceability_matrix", "domain_certification", "production_blockers", "slo_sla", "change_control", "what_really_works", "honesty"],
    "valid_from": "2026-01-01",
    "valid_to": null,
}

tests_ci_quality_etap24 := {
    "registry_version": "tests-ci-quality-etap24-2026.08",
    "legal_basis_version": "quality-governance-2026.08",
    "min_coverage_pct": 95,
    "min_critical_coverage_pct": 100,
    "min_mutation_pct": 85,
    "min_fuzz_cases": 10000,
    "min_property_cases": 200,
    "max_flake_count": 0,
    "fail_on_empty": true,
    "opa_fail_on_empty": true,
    "required_gates": ["syntax", "semantic", "contract", "property", "mutation", "fuzz", "boundary", "coverage", "regression", "golden", "chaos", "security", "disaster_recovery"],
    "valid_from": "2026-01-01",
    "valid_to": null,
}

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 23 ENTERPRISE AI / NEURAL GOVERNANCE THRESHOLDS (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════

enterprise_ai_neural_etap23 := {
    "registry_version": "enterprise-ai-neural-etap23-2026.08",
    "legal_basis_version": "ai-governance-isap-2026.08",
    "calibration_min_samples": 100,
    "max_expected_calibration_error": 0.10,
    "max_population_stability_index": 0.20,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "prediction_role": "ADVISORY_ONLY",
    "legal_verdict_authority": "DETERMINISTIC_REGO",
    "required_controls": ["calibration", "drift", "bias", "safety", "explainability", "feedback", "manual_review"],
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
    "reverse_charge_construction_threshold": 500000, # PLN — próg RO dla usług budowlanych (Art. 17 ust. 1 pkt 8 VAT, zał. nr 14)
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
# BDO ENVIRONMENT — Środowisko + BDO + Branża (P15) — data.jdg.thresholds.bdo_environment
# ═══════════════════════════════════════════════════════════════════════════════
# Dane dla pakietu jdg.p15_srodowisko_bdo_innovations (fallback w pakiecie).
# Uzupełnione 2026-08-05 — zamknięcie luk MAPA DROGOWA R15 (P0/P1/P2):
#   P0-1 opłaty produktowe per materiał opakowaniowy
#   P0-2 API systemu BDO (KPO + sprawozdania)
#   P1-1 pełny katalog EWC 6-cyfrowy (20 rozdziałów)
#   P1-2 stawki podatku rolnego per gmina (rejestr)
#   P1-3 tabele zezwoleń transportowych (krajowe/międzynarodowe)
#   P2-1 certyfikaty CBAM 2026 (reżim definitywny)
#   P2-2 rejestracja online w BDO (API/portal)
# ═══════════════════════════════════════════════════════════════════════════════

bdo_environment := {
    # ── istniejące progi P15 (spójne z fallbackiem pakietu rego) ──
    "bdo_rejestracja_opłaty": {"mikro": 100, "mały": 300, "średni": 500},  # opłata rejestracyjna BDO (PLN)
    "bdo_kara_brak_rejestracji": 5000,   # art. 194 UoO — kara do 5000 zł
    "bdo_ewidencja_okres": "kwartalna",
    "bdo_kpo_elektroniczne": true,
    "bdo_weee_baterie": "rejestracja + sprawozdania roczne WEEE/baterie",
    "bdo_opakowania": "opłata produktowa za opakowania (art. 17-18 UoO)",
    "budowlane_pozwolenie": "pozwolenie na budowę lub zgłoszenie (prawo budowlane)",
    "budowlane_nadzor": "nadzór budowlany — zgłoszenie zakończenia budowy",
    "transport_licencja": "licencja wspólnotowa na przewóz drogowy (art. 5 u.t.d.)",
    "transport_tachograf": "tachograf cyfrowy — pojazdy >3,5t",
    "rolnik_ryczałtowy": "rolnik ryczałtowy — zwolnienie z PIT do 150 000 zł (art. 20 pkt 1 PIT)",
    "podatek_rolny": "podatek rolny — przeliczniki ha przeliczeniowych",
    "cbam": "CBAM — import cementu, żelaza, stali, aluminium, nawozów (2023/956)",
    "taxfree_vat_ref": "VAT-REF — zwrot VAT dla podróżnych (procedura tax-free)",
    "packaging_fee_rate": 2.0,             # opłata produktowa za opakowania (zł/kg, orientacyjnie)
    "cbam_price_eur_t": 80.0,              # orientacyjna cena uprawnień EU ETS (EUR/t CO2)
    "agricultural_rye_pln_q": 89.63,       # cena żyta 2026 (zł/q) — podatek rolny

    # ── P0-1: opłaty produktowe per materiał opakowaniowy (zł/kg, orientacyjne 2026) ──
    "packaging_fee_rates_per_material": {
        "papier": 0.50,
        "tworzywa_sztuczne": 2.00,
        "szklo": 0.20,
        "metale": 0.30,
        "drewno": 0.20,
        "wielomaterialowe": 1.00,
    },

    # ── P0-2: API systemu BDO (KPO + sprawozdania roczne) ──
    "bdo_api": {
        "base_url": "https://bdo.mos.gov.pl/api",
        "auth": "OAuth2 / certyfikat",
        "kpo_endpoint": "/kpo",
        "sprawozdania_endpoint": "/sprawozdania",
        "rejestracja_endpoint": "/rejestracja",
        "kpo_elektroniczne_obowiazkowe": true,
    },

    # ── P1-1: pełny katalog EWC 6-cyfrowy (rozdziały 01-20) ──
    # Rozporządzenie ws. katalogu odpadów (Dz.U. 2020 poz. 10). Katalog obejmuje
    # najczęściej stosowane kody 6-cyfrowe we wszystkich 20 rozdziałach;
    # rozszerzalny przez dodanie wpisów (ADR-002 — zero hardcode w regułach).
    "ewc_catalog": [
        {"code": "01 01 01", "name": "odpady z wydobywania kopalin innych niż 01 01 02", "hazardous": false},
        {"code": "01 01 02", "name": "odpady z wydobywania kopalin", "hazardous": false},
        {"code": "01 03 04", "name": "kwaśne odpady skalne z przetwarzania rudy siarczkowej", "hazardous": true},
        {"code": "01 03 05", "name": "inne odpady zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "01 03 06", "name": "odpady inne niż 01 03 04 i 01 03 05", "hazardous": false},
        {"code": "01 04 07", "name": "odpady zawierające substancje niebezpieczne z chemicznego przetwarzania kopalin", "hazardous": true},
        {"code": "01 04 08", "name": "odpady z odwiertów i szlamy", "hazardous": false},
        {"code": "01 05 04", "name": "szlamy i odpady wiertnicze zawierające wodę pitną", "hazardous": false},
        {"code": "01 05 05", "name": "szlamy i odpady wiertnicze zawierające oleje", "hazardous": true},
        {"code": "01 05 07", "name": "szlamy i odpady wiertnicze zawierające baryt", "hazardous": false},
        {"code": "02 01 01", "name": "odpady z mycia i czyszczenia", "hazardous": false},
        {"code": "02 01 02", "name": "odpady tkanki zwierzęcej", "hazardous": false},
        {"code": "02 01 03", "name": "odpadowa tkanka roślinna", "hazardous": false},
        {"code": "02 01 04", "name": "odpady tworzyw sztucznych (bez opakowań)", "hazardous": false},
        {"code": "02 01 06", "name": "odchody zwierzęce", "hazardous": false},
        {"code": "02 01 07", "name": "odpady z gospodarki leśnej", "hazardous": false},
        {"code": "02 01 08", "name": "odpady agrochemiczne zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "02 01 09", "name": "odpady agrochemiczne inne niż 02 01 08", "hazardous": false},
        {"code": "02 02 02", "name": "odpady tkanki zwierzęcej (przetwórstwo mięsa)", "hazardous": false},
        {"code": "02 02 03", "name": "odpady materiałów nadających się do spożycia lub przetworzenia", "hazardous": false},
        {"code": "03 01 01", "name": "odpady z kory i korka", "hazardous": false},
        {"code": "03 01 02", "name": "trociny i wióry", "hazardous": false},
        {"code": "03 01 04", "name": "trociny i wióry zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "03 01 05", "name": "inne odpady zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "03 02 01", "name": "niezawierające halogenów organiczne środki do konserwacji drewna", "hazardous": true},
        {"code": "03 02 02", "name": "chloroorganiczne środki do konserwacji drewna", "hazardous": true},
        {"code": "03 03 01", "name": "odpady z kory i drewna", "hazardous": false},
        {"code": "03 03 02", "name": "osady z ługów zielonych", "hazardous": false},
        {"code": "03 03 07", "name": "mechanicznie wydzielone odrzuty z przeróbki odpadów papierniczych", "hazardous": false},
        {"code": "03 03 08", "name": "odpady z sortowania papieru i tektury przeznaczone do recyklingu", "hazardous": false},
        {"code": "04 01 01", "name": "odpady z mycia i przygotowywania skór", "hazardous": false},
        {"code": "04 01 02", "name": "odpady wapiennicze", "hazardous": false},
        {"code": "04 01 03", "name": "odpady z odtłuszczania zawierające rozpuszczalniki", "hazardous": true},
        {"code": "04 01 04", "name": "odpady z garbowania chemicznego", "hazardous": false},
        {"code": "04 01 05", "name": "odpady z garbowania bez chromu", "hazardous": false},
        {"code": "04 01 06", "name": "odpady zawierające chrom", "hazardous": false},
        {"code": "04 01 07", "name": "odpady z garbowania z chromem", "hazardous": false},
        {"code": "04 01 08", "name": "odpady skór garbowanych", "hazardous": false},
        {"code": "04 02 09", "name": "odpady z materiałów kompozytowych (impregnowane tkaniny)", "hazardous": true},
        {"code": "04 02 10", "name": "odpady organiczne z materiałów naturalnych", "hazardous": false},
        {"code": "05 01 03", "name": "szlamy denne z cystern", "hazardous": true},
        {"code": "05 01 04", "name": "szlamy z kolumn", "hazardous": true},
        {"code": "05 01 05", "name": "rozlany olej", "hazardous": true},
        {"code": "05 01 06", "name": "szlamy olejowe z konserwacji i obsługi urządzeń", "hazardous": true},
        {"code": "05 01 07", "name": "kwaśne smoky", "hazardous": true},
        {"code": "05 01 08", "name": "inne smoky", "hazardous": true},
        {"code": "05 01 09", "name": "szlamy z zakładowych oczyszczalni ścieków", "hazardous": true},
        {"code": "05 01 11", "name": "odpady z czyszczenia paliw z zasadami", "hazardous": true},
        {"code": "05 01 12", "name": "oleje zawierające kwasy", "hazardous": true},
        {"code": "05 01 15", "name": "zużyte ziemie bielące", "hazardous": true},
        {"code": "06 01 01", "name": "kwas siarkowy i kwas siarkawy", "hazardous": true},
        {"code": "06 01 02", "name": "kwas solny", "hazardous": true},
        {"code": "06 01 03", "name": "kwas fluorowodorowy", "hazardous": true},
        {"code": "06 01 04", "name": "kwas fosforowy i fosforawy", "hazardous": true},
        {"code": "06 01 05", "name": "kwas azotowy i kwasy azotawe", "hazardous": true},
        {"code": "06 01 06", "name": "inne kwasy", "hazardous": true},
        {"code": "06 02 01", "name": "wodorotlenek wapnia", "hazardous": true},
        {"code": "06 02 03", "name": "wodorotlenek amonu", "hazardous": true},
        {"code": "06 03 13", "name": "sole stałe zawierające metale ciężkie", "hazardous": true},
        {"code": "06 04 05", "name": "odpady zawierające inne metale ciężkie", "hazardous": true},
        {"code": "07 01 01", "name": "roztwory wodne do mycia i ciecze macierzyste", "hazardous": true},
        {"code": "07 01 03", "name": "rozpuszczalniki organiczne, roztwory i ciecze macierzyste", "hazardous": true},
        {"code": "07 01 04", "name": "inne rozpuszczalniki organiczne", "hazardous": true},
        {"code": "07 01 07", "name": "halogenowane pozostałości z destylacji", "hazardous": true},
        {"code": "07 01 08", "name": "inne pozostałości z destylacji i reakcji", "hazardous": true},
        {"code": "07 01 09", "name": "wytłoki filtracyjne, zużyte sorbenty", "hazardous": true},
        {"code": "07 01 10", "name": "inne wytłoki filtracyjne", "hazardous": true},
        {"code": "07 01 11", "name": "szlamy z zakładowych oczyszczalni ścieków", "hazardous": true},
        {"code": "07 02 01", "name": "roztwory wodne do mycia (tworzywa sztuczne)", "hazardous": true},
        {"code": "07 02 03", "name": "rozpuszczalniki organiczne (tworzywa sztuczne)", "hazardous": true},
        {"code": "08 01 11", "name": "odpady farb i lakierów zawierające rozpuszczalniki organiczne", "hazardous": true},
        {"code": "08 01 12", "name": "odpady farb i lakierów inne niż 08 01 11", "hazardous": false},
        {"code": "08 01 13", "name": "szlamy z farb i lakierów zawierające rozpuszczalniki organiczne", "hazardous": true},
        {"code": "08 01 14", "name": "szlamy z farb i lakierów inne niż 08 01 13", "hazardous": false},
        {"code": "08 01 15", "name": "szlamy wodne zawierające farby i lakiery z rozpuszczalnikami", "hazardous": true},
        {"code": "08 01 16", "name": "szlamy wodne zawierające farby i lakiery inne niż 08 01 15", "hazardous": false},
        {"code": "08 01 17", "name": "odpady z usuwania farb i lakierów zawierające rozpuszczalniki", "hazardous": true},
        {"code": "08 01 18", "name": "odpady z usuwania farb i lakierów inne niż 08 01 17", "hazardous": false},
        {"code": "08 03 12", "name": "odpadowy tusz zawierający substancje niebezpieczne", "hazardous": true},
        {"code": "08 03 13", "name": "odpadowy tusz inny niż 08 03 12", "hazardous": false},
        {"code": "09 01 01", "name": "wodne roztwory wywoływaczy i aktywatorów", "hazardous": true},
        {"code": "09 01 02", "name": "wodne roztwory utrwalaczy", "hazardous": true},
        {"code": "09 01 03", "name": "rozpuszczalnikowe roztwory wywoływaczy", "hazardous": true},
        {"code": "09 01 04", "name": "rozpuszczalnikowe roztwory utrwalaczy", "hazardous": true},
        {"code": "09 01 05", "name": "roztwory bielące i bieląco-utrwalające", "hazardous": true},
        {"code": "09 01 06", "name": "odpady zawierające srebro z przetwarzania fotograficznego", "hazardous": true},
        {"code": "09 01 07", "name": "filmy i papier fotograficzny zawierające srebro", "hazardous": false},
        {"code": "09 01 08", "name": "filmy i papier fotograficzny niezawierające srebra", "hazardous": false},
        {"code": "09 01 10", "name": "aparaty jednorazowego użytku bez baterii", "hazardous": false},
        {"code": "09 01 11", "name": "aparaty jednorazowego użytku zawierające baterie", "hazardous": true},
        {"code": "10 01 01", "name": "żużle denne i szlaki", "hazardous": false},
        {"code": "10 01 02", "name": "popioły lotne z węgla", "hazardous": false},
        {"code": "10 01 03", "name": "popioły lotne z torfu i drewna", "hazardous": false},
        {"code": "10 01 04", "name": "popioły lotne z oleju", "hazardous": true},
        {"code": "10 01 05", "name": "stałe odpady z reakcji wapnia", "hazardous": false},
        {"code": "10 01 07", "name": "odpady z oczyszczania gazów odlotowych typu stałego", "hazardous": false},
        {"code": "10 01 09", "name": "kwas siarkowy", "hazardous": true},
        {"code": "10 01 13", "name": "popioły lotne z emulsji", "hazardous": true},
        {"code": "10 01 14", "name": "popioły denne i żużle ze współspalania zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "10 01 15", "name": "popioły denne i żużle inne niż 10 01 14", "hazardous": false},
        {"code": "11 01 05", "name": "roztwory do trawienia", "hazardous": true},
        {"code": "11 01 06", "name": "kwasy nieokreślone", "hazardous": true},
        {"code": "11 01 07", "name": "zasady nieokreślone", "hazardous": true},
        {"code": "11 01 08", "name": "szlamy fosforanujące", "hazardous": true},
        {"code": "11 01 09", "name": "szlamy i produkty filtracji zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "11 01 10", "name": "szlamy i produkty filtracji inne niż 11 01 09", "hazardous": false},
        {"code": "11 01 11", "name": "roztwory wodne do płukania zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "11 01 12", "name": "roztwory wodne do płukania inne niż 11 01 11", "hazardous": false},
        {"code": "11 01 13", "name": "odpady z odtłuszczania zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "11 01 14", "name": "odpady z odtłuszczania inne niż 11 01 13", "hazardous": false},
        {"code": "12 01 01", "name": "opiłki i wióry żelazne", "hazardous": false},
        {"code": "12 01 02", "name": "pyły i proszki żelazne", "hazardous": false},
        {"code": "12 01 03", "name": "opiłki i wióry metali nieżelaznych", "hazardous": false},
        {"code": "12 01 04", "name": "pyły i proszki metali nieżelaznych zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "12 01 05", "name": "wióry z tworzyw sztucznych", "hazardous": false},
        {"code": "12 01 06", "name": "oleje mineralne obróbkowe niezawierające chlorowców", "hazardous": true},
        {"code": "12 01 08", "name": "emulsje i roztwory obróbkowe zawierające chlorowce", "hazardous": true},
        {"code": "12 01 09", "name": "emulsje i roztwory obróbkowe niezawierające chlorowców", "hazardous": false},
        {"code": "12 01 10", "name": "syntetyczne oleje obróbkowe", "hazardous": true},
        {"code": "13 01 01", "name": "oleje hydrauliczne zawierające PCB", "hazardous": true},
        {"code": "13 01 04", "name": "chlorowane emulsje", "hazardous": true},
        {"code": "13 01 05", "name": "niechlorowane emulsje", "hazardous": true},
        {"code": "13 01 09", "name": "chlorowane oleje hydrauliczne", "hazardous": true},
        {"code": "13 01 10", "name": "niechlorowane oleje hydrauliczne", "hazardous": true},
        {"code": "13 01 11", "name": "syntetyczne oleje hydrauliczne", "hazardous": true},
        {"code": "13 01 13", "name": "inne oleje hydrauliczne", "hazardous": true},
        {"code": "13 02 04", "name": "chlorowane oleje silnikowe, przekładniowe i smarowe", "hazardous": true},
        {"code": "13 02 05", "name": "niechlorowane oleje silnikowe, przekładniowe i smarowe", "hazardous": true},
        {"code": "13 02 08", "name": "inne oleje silnikowe, przekładniowe i smarowe", "hazardous": true},
        {"code": "14 06 01", "name": "chlorofluorowęglowodory, HCFC, HFC", "hazardous": true},
        {"code": "14 06 02", "name": "inne halogenowane rozpuszczalniki i mieszaniny", "hazardous": true},
        {"code": "14 06 03", "name": "inne rozpuszczalniki i mieszaniny rozpuszczalników", "hazardous": true},
        {"code": "14 06 04", "name": "szlamy lub stałe odpady zawierające halogenowane rozpuszczalniki", "hazardous": true},
        {"code": "14 06 05", "name": "szlamy lub stałe odpady zawierające inne rozpuszczalniki", "hazardous": true},
        {"code": "14 06 06", "name": "ciekłe odpady zawierające halogenowane rozpuszczalniki", "hazardous": true},
        {"code": "14 06 07", "name": "ciekłe odpady zawierające inne rozpuszczalniki", "hazardous": true},
        {"code": "14 06 08", "name": "odpady inne niż wymienione w 14 06 01-07", "hazardous": false},
        {"code": "15 01 01", "name": "opakowania z papieru i tektury", "hazardous": false},
        {"code": "15 01 02", "name": "opakowania z tworzyw sztucznych", "hazardous": false},
        {"code": "15 01 03", "name": "opakowania z drewna", "hazardous": false},
        {"code": "15 01 04", "name": "opakowania z metalu", "hazardous": false},
        {"code": "15 01 05", "name": "opakowania ze szkła", "hazardous": false},
        {"code": "15 01 06", "name": "zmieszane odpady opakowaniowe", "hazardous": false},
        {"code": "15 01 09", "name": "opakowania z włókien", "hazardous": false},
        {"code": "15 01 10", "name": "opakowania zawierające pozostałości substancji niebezpiecznych", "hazardous": true},
        {"code": "15 01 11", "name": "opakowania z metalu zawierające niebezpieczne stałe elementy", "hazardous": true},
        {"code": "15 02 02", "name": "sorbenty, materiały filtracyjne, tkaniny zanieczyszczone substancjami niebezpiecznymi", "hazardous": true},
        {"code": "15 02 03", "name": "sorbenty, materiały filtracyjne, tkaniny inne niż 15 02 02", "hazardous": false},
        {"code": "16 01 03", "name": "zużyte opony", "hazardous": false},
        {"code": "16 01 04", "name": "zużyte pojazdy", "hazardous": true},
        {"code": "16 01 06", "name": "zużyte pojazdy nie zawierające cieczy ani innych niebezpiecznych elementów", "hazardous": false},
        {"code": "16 01 07", "name": "filtry olejowe", "hazardous": true},
        {"code": "16 01 08", "name": "elementy zawierające rtęć", "hazardous": true},
        {"code": "16 01 09", "name": "elementy zawierające PCB", "hazardous": true},
        {"code": "16 01 10", "name": "elementy wybuchowe", "hazardous": true},
        {"code": "16 01 13", "name": "płyny hamulcowe", "hazardous": true},
        {"code": "16 01 14", "name": "płyny przeciw zamarzaniu zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "16 01 15", "name": "płyny przeciw zamarzaniu inne niż 16 01 14", "hazardous": false},
        {"code": "16 01 16", "name": "zbiorniki ciekłego gazu", "hazardous": false},
        {"code": "16 01 17", "name": "metale żelazne", "hazardous": false},
        {"code": "16 01 18", "name": "metale nieżelazne", "hazardous": false},
        {"code": "16 01 19", "name": "tworzywa sztuczne", "hazardous": false},
        {"code": "16 01 20", "name": "szkło", "hazardous": false},
        {"code": "16 01 21", "name": "elementy niebezpieczne inne niż 16 01 07-11", "hazardous": true},
        {"code": "16 01 22", "name": "elementy nieokreślone", "hazardous": true},
        {"code": "16 02 13", "name": "zużyte urządzenia zawierające niebezpieczne elementy", "hazardous": true},
        {"code": "16 02 14", "name": "zużyte urządzenia inne niż 16 02 09-13", "hazardous": false},
        {"code": "16 02 15", "name": "niebezpieczne elementy usunięte ze zużytych urządzeń", "hazardous": true},
        {"code": "16 02 16", "name": "elementy usunięte ze zużytych urządzeń inne niż 16 02 15", "hazardous": false},
        {"code": "16 06 01", "name": "baterie ołowiowe", "hazardous": true},
        {"code": "16 06 02", "name": "baterie niklowo-kadmowe", "hazardous": true},
        {"code": "16 06 03", "name": "baterie zawierające rtęć", "hazardous": true},
        {"code": "16 06 04", "name": "baterie alkaliczne", "hazardous": false},
        {"code": "16 06 05", "name": "inne baterie i akumulatory", "hazardous": false},
        {"code": "16 06 06", "name": "elektrolity z baterii", "hazardous": true},
        {"code": "17 01 01", "name": "beton", "hazardous": false},
        {"code": "17 01 02", "name": "gruz ceglany", "hazardous": false},
        {"code": "17 01 03", "name": "odpady innych materiałów ceramicznych i elementów wyposażenia", "hazardous": false},
        {"code": "17 01 06", "name": "zmieszane odpady budowlane zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "17 01 07", "name": "zmieszane odpady budowlane inne niż 17 01 06", "hazardous": false},
        {"code": "17 02 01", "name": "drewno", "hazardous": false},
        {"code": "17 02 02", "name": "szkło", "hazardous": false},
        {"code": "17 02 03", "name": "tworzywa sztuczne", "hazardous": false},
        {"code": "17 02 04", "name": "szkło, tworzywa sztuczne i drewno zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "17 03 01", "name": "mieszanki bitumiczne zawierające smołę", "hazardous": true},
        {"code": "17 03 02", "name": "mieszanki bitumiczne inne niż 17 03 01", "hazardous": false},
        {"code": "17 03 03", "name": "smoła i produkty smołowane", "hazardous": true},
        {"code": "17 04 01", "name": "miedź, brąz, mosiądz", "hazardous": false},
        {"code": "17 04 02", "name": "aluminium", "hazardous": false},
        {"code": "17 04 03", "name": "ołów", "hazardous": false},
        {"code": "17 04 04", "name": "cynk", "hazardous": false},
        {"code": "17 04 05", "name": "żelazo i stal", "hazardous": false},
        {"code": "17 04 06", "name": "cyna", "hazardous": false},
        {"code": "17 04 07", "name": "metale mieszane", "hazardous": false},
        {"code": "17 04 09", "name": "odpady metaliczne zanieczyszczone substancjami niebezpiecznymi", "hazardous": true},
        {"code": "17 04 10", "name": "kable zawierające olej, smołę lub inne substancje niebezpieczne", "hazardous": true},
        {"code": "17 04 11", "name": "kable inne niż 17 04 10", "hazardous": false},
        {"code": "17 05 03", "name": "gleba i ziemia zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "17 05 04", "name": "gleba i ziemia inne niż 17 05 03", "hazardous": false},
        {"code": "17 06 01", "name": "materiały izolacyjne zawierające azbest", "hazardous": true},
        {"code": "17 06 03", "name": "inne materiały izolacyjne zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "17 06 04", "name": "materiały izolacyjne inne niż 17 06 01 i 17 06 03", "hazardous": false},
        {"code": "17 06 05", "name": "materiały konstrukcyjne zawierające azbest", "hazardous": true},
        {"code": "17 08 01", "name": "materiały konstrukcyjne zawierające gips zanieczyszczone substancjami niebezpiecznymi", "hazardous": true},
        {"code": "17 08 02", "name": "materiały konstrukcyjne zawierające gips inne niż 17 08 01", "hazardous": false},
        {"code": "17 09 01", "name": "odpady z budowy i remontów zawierające rtęć", "hazardous": true},
        {"code": "17 09 02", "name": "odpady z budowy i remontów zawierające PCB", "hazardous": false},
        {"code": "17 09 03", "name": "inne odpady z budowy i remontów zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "17 09 04", "name": "zmieszane odpady z budowy i remontów inne niż 17 09 01-03", "hazardous": false},
        {"code": "18 01 01", "name": "ostre narzędzia", "hazardous": false},
        {"code": "18 01 02", "name": "części ciała i organy oraz pojemniki na krew", "hazardous": false},
        {"code": "18 01 03", "name": "odpady, których zbieranie i usuwanie wymaga szczególnych środków", "hazardous": true},
        {"code": "18 01 04", "name": "odpady inne niż 18 01 03", "hazardous": false},
        {"code": "18 01 06", "name": "chemikalia zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "18 01 07", "name": "chemikalia inne niż 18 01 06", "hazardous": false},
        {"code": "18 01 08", "name": "leki cytotoksyczne i cytostatyczne", "hazardous": true},
        {"code": "18 01 09", "name": "leki inne niż 18 01 08", "hazardous": false},
        {"code": "18 01 10", "name": "odpady amalgamatu dentystycznego", "hazardous": true},
        {"code": "18 02 02", "name": "inne odpady, których zbieranie i usuwanie wymaga szczególnych środków", "hazardous": true},
        {"code": "18 02 03", "name": "odpady inne niż 18 02 02", "hazardous": false},
        {"code": "18 02 07", "name": "leki cytotoksyczne i cytostatyczne", "hazardous": true},
        {"code": "19 01 02", "name": "materiały żelazne usunięte z popiołów dennych", "hazardous": false},
        {"code": "19 01 05", "name": "filtrat z zagęszczania", "hazardous": true},
        {"code": "19 01 06", "name": "ciekłe odpady wodne z oczyszczania kotłów", "hazardous": true},
        {"code": "19 01 07", "name": "stałe odpady z oczyszczania gazów odlotowych", "hazardous": true},
        {"code": "19 01 10", "name": "zużyty węgiel aktywny", "hazardous": true},
        {"code": "19 01 11", "name": "popioły denne i żużle zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "19 01 12", "name": "popioły denne i żużle inne niż 19 01 11", "hazardous": false},
        {"code": "19 01 13", "name": "popioły lotne zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "19 01 14", "name": "popioły lotne inne niż 19 01 13", "hazardous": false},
        {"code": "19 02 04", "name": "wstępnie zmieszane odpady zawierające co najmniej jeden odpad niebezpieczny", "hazardous": true},
        {"code": "19 02 05", "name": "szlamy z fizykochemicznego przetwarzania zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "19 02 06", "name": "szlamy z fizykochemicznego przetwarzania inne niż 19 02 05", "hazardous": false},
        {"code": "19 05 03", "name": "kompost nieodpowiadający specyfikacji", "hazardous": false},
        {"code": "19 06 03", "name": "ciecze z beztlenowego przetwarzania odpadów komunalnych", "hazardous": false},
        {"code": "19 06 04", "name": "produkty fermentacji z beztlenowego przetwarzania odpadów komunalnych", "hazardous": false},
        {"code": "19 06 05", "name": "ciecze z beztlenowego przetwarzania odpadów zwierzęcych", "hazardous": false},
        {"code": "19 08 01", "name": "skratki", "hazardous": false},
        {"code": "19 08 02", "name": "odpady z piaskowników", "hazardous": false},
        {"code": "19 08 05", "name": "osady z oczyszczania ścieków komunalnych", "hazardous": false},
        {"code": "19 08 06", "name": "nasycone lub zużyte żywice jonowymienne", "hazardous": true},
        {"code": "19 08 09", "name": "mieszaniny tłuszczów i olejów z separacji oleju/wody", "hazardous": false},
        {"code": "19 08 11", "name": "szlamy zawierające substancje niebezpieczne z biologicznego oczyszczania ścieków przemysłowych", "hazardous": true},
        {"code": "19 08 12", "name": "szlamy z biologicznego oczyszczania ścieków przemysłowych inne niż 19 08 11", "hazardous": false},
        {"code": "19 09 04", "name": "zużyty węgiel aktywny", "hazardous": false},
        {"code": "19 09 05", "name": "nasycone lub zużyte żywice jonowymienne", "hazardous": false},
        {"code": "19 10 01", "name": "odpady żelaza i stali", "hazardous": false},
        {"code": "19 10 02", "name": "odpady metali nieżelaznych", "hazardous": false},
        {"code": "19 10 03", "name": "frakcje lekkie i pyły zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "19 10 04", "name": "frakcje lekkie i pyły inne niż 19 10 03", "hazardous": false},
        {"code": "19 12 01", "name": "papier i tektura", "hazardous": false},
        {"code": "19 12 02", "name": "metale żelazne", "hazardous": false},
        {"code": "19 12 03", "name": "metale nieżelazne", "hazardous": false},
        {"code": "19 12 04", "name": "tworzywa sztuczne i guma", "hazardous": false},
        {"code": "19 12 05", "name": "szkło", "hazardous": false},
        {"code": "19 12 06", "name": "drewno zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "19 12 07", "name": "drewno inne niż 19 12 06", "hazardous": false},
        {"code": "19 12 08", "name": "tekstylia", "hazardous": false},
        {"code": "19 12 09", "name": "minerały", "hazardous": false},
        {"code": "19 12 10", "name": "odpady palne", "hazardous": false},
        {"code": "19 12 11", "name": "inne odpady z mechanicznej obróbki zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "19 12 12", "name": "inne odpady z mechanicznej obróbki inne niż 19 12 11", "hazardous": false},
        {"code": "20 01 01", "name": "papier i tektura", "hazardous": false},
        {"code": "20 01 02", "name": "szkło", "hazardous": false},
        {"code": "20 01 08", "name": "odpady kuchenne ulegające biodegradacji", "hazardous": false},
        {"code": "20 01 10", "name": "odzież", "hazardous": false},
        {"code": "20 01 11", "name": "tekstylia", "hazardous": false},
        {"code": "20 01 13", "name": "rozpuszczalniki", "hazardous": true},
        {"code": "20 01 14", "name": "kwasy", "hazardous": true},
        {"code": "20 01 15", "name": "alkalia", "hazardous": true},
        {"code": "20 01 17", "name": "chemikalia fotograficzne", "hazardous": true},
        {"code": "20 01 19", "name": "pestycydy", "hazardous": true},
        {"code": "20 01 21", "name": "lampy fluorescencyjne i inne odpady zawierające rtęć", "hazardous": true},
        {"code": "20 01 23", "name": "urządzenia zawierające CFC", "hazardous": true},
        {"code": "20 01 25", "name": "oleje i tłuszcze jadalne", "hazardous": true},
        {"code": "20 01 26", "name": "oleje i tłuszcze inne niż 20 01 25", "hazardous": true},
        {"code": "20 01 27", "name": "farby, tusze, kleje zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "20 01 28", "name": "farby, tusze, kleje inne niż 20 01 27", "hazardous": false},
        {"code": "20 01 29", "name": "detergenty zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "20 01 30", "name": "detergenty inne niż 20 01 29", "hazardous": false},
        {"code": "20 01 31", "name": "leki cytotoksyczne i cytostatyczne", "hazardous": true},
        {"code": "20 01 32", "name": "leki inne niż 20 01 31", "hazardous": false},
        {"code": "20 01 33", "name": "baterie i akumulatory niebezpieczne", "hazardous": true},
        {"code": "20 01 34", "name": "baterie i akumulatory inne niż 20 01 33", "hazardous": false},
        {"code": "20 01 35", "name": "zużyte urządzenia elektryczne i elektroniczne zawierające niebezpieczne elementy", "hazardous": true},
        {"code": "20 01 36", "name": "zużyte urządzenia elektryczne i elektroniczne inne niż 20 01 35", "hazardous": false},
        {"code": "20 01 37", "name": "drewno zawierające substancje niebezpieczne", "hazardous": true},
        {"code": "20 01 38", "name": "drewno inne niż 20 01 37", "hazardous": false},
        {"code": "20 01 39", "name": "tworzywa sztuczne", "hazardous": false},
        {"code": "20 01 40", "name": "metale", "hazardous": false},
        {"code": "20 01 41", "name": "odpady z zamiatania ulic", "hazardous": false},
        {"code": "20 02 01", "name": "odpady ulegające biodegradacji", "hazardous": false},
        {"code": "20 02 02", "name": "gleba i ziemia", "hazardous": false},
        {"code": "20 02 03", "name": "inne odpady nieulegające biodegradacji", "hazardous": false},
        {"code": "20 03 01", "name": "niesegregowane odpady komunalne", "hazardous": false},
        {"code": "20 03 02", "name": "odpady z targowisk", "hazardous": false},
        {"code": "20 03 03", "name": "odpady z czyszczenia ulic", "hazardous": false},
        {"code": "20 03 04", "name": "szlamy ze zbiorników bezodpływowych", "hazardous": false},
        {"code": "20 03 06", "name": "odpady z czyszczenia kanalizacji", "hazardous": false},
        {"code": "20 03 07", "name": "odpady wielkogabarytowe", "hazardous": false},
        {"code": "20 03 99", "name": "odpady komunalne nieokreślone", "hazardous": false},
    ],

    # ── P1-2: stawki podatku rolnego per gmina (mnożnik q żyta/ha przeliczeniowego) ──
    # Ustawa o podatku rolnym — gminy mogą obniżyć mnożnik uchwałą (domyślnie 2,5 q).
    "agricultural_tax_multiplier_by_gmina": {
        "default": 2.5,
        "Warszawa": 2.5, "Kraków": 2.5, "Łódź": 2.5, "Wrocław": 2.5,
        "Poznań": 2.5, "Gdańsk": 2.5, "Szczecin": 2.5, "Lublin": 2.5,
        "Katowice": 2.5, "Białystok": 2.5, "Rzeszów": 2.5, "Olsztyn": 2.5,
    },

    # ── P1-3: tabele zezwoleń transportowych (przewozy krajowe / międzynarodowe) ──
    "transport_permits": {
        "krajowy": {"dokument": "licencja na krajowy przewóz drogowy", "wypis_w_pojezdzie": true, "legal_basis": "art. 5 u.t.d."},
        "unijny_ue": {"dokument": "licencja wspólnotowa", "wypis_w_pojezdzie": true, "legal_basis": "art. 7 u.t.d."},
        "poza_ue": {"dokument": "zezwolenia dwustronne / ECMT", "wypis_w_pojezdzie": true, "legal_basis": "art. 8 u.t.d."},
        "tachograf": {"dokument": "tachograf cyfrowy", "prog_t": 3.5, "legal_basis": "rozp. UE 165/2014"},
    },

    # ── P2-1: certyfikaty CBAM 2026 (reżim definitywny — Rozporządzenie UE 2023/956) ──
    "cbam_certificates": {
        "definitive_from": "2026-01-01",
        "price_eur_t": 80.0,
        "validity_years": 2,
        "surrender_deadline": "31.05",
        "quarterly_report_deadline": "koniec miesiąca po kwartale",
        "prepayment_pct": 0.8,
        "penalty_eur_t": 50.0,
    },

    # ── P2-2: rejestracja online w BDO (API/portal) ──
    "bdo_online_registration": {
        "endpoint": "https://bdo.mos.gov.pl/rejestracja",
        "steps": ["konto w BDO", "wniosek elektroniczny", "opłata (100-500 PLN)", "potwierdzenie rejestracji"],
        "update_deadline_days": 30,
        "deregistration_deadline_days": 30,
    },
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
# COMPLIANCE AML + RODO — data.jdg.thresholds.compliance_aml_rodo (P16)
# Dane dla pakietu jdg.p16_rodo_aml_security_innovations (fallback w pakiecie).
#   P0-1: integracja z rejestrem BDO/CRBR (beneficjenci rzeczywiści) via API
#   P0-2: automatyczna wysyłka zgłoszeń STR do GIIF (API) + potwierdzenia
#   P1-1: pełna mapa podprocesorów SaaS (umowy Art. 28 + podpowierzenie)
#   P1-2: kalendarz terminów RODO (przeglądy, DPIA, umowy powierzenia)
#   P1-3: scoring AML z danymi rzeczywistymi (listy sankcyjne UE/ONZ)
#   P2-1: implementacja AMLR (UE 2024/1624) — progi CBDD od 2027
#   P2-2: UI panelu ryzyka AML + dashboard naruszeń RODO 72h
# ═══════════════════════════════════════════════════════════════════════════════

compliance_aml_rodo := {
    # ── RODO — sankcje, terminy, retencja (spójne z pakietem p16) ──
    "rodo_sanction_max_eur": 20000000,            # Art. 83 ust. 5 RODO
    "rodo_sanction_min_eur": 10000000,            # Art. 83 ust. 4 RODO
    "rodo_breach_deadline_hours": 72,             # Art. 33 RODO — zgłoszenie w 72h
    "rodo_erasure_deadline_days": 30,             # Art. 17 RODO
    "rodo_retention_years": 5,                    # Art. 74 ust. 2 UoR

    # ── AML — progi, CBDD, STR, sankcje ──
    "aml_cbdd_required": true,
    "aml_ubo_check": true,
    "aml_threshold_eur": 15000,                   # Art. 34 u.AML — transakcje > 15 000 EUR
    "aml_str_deadline_days": 1,                   # STR do GIIF — 1 dzień roboczy (Art. 74-80)
    "aml_sanction_max_pln": 1000000,              # art. 153 u.AML

    # ── security + audit ──
    "sec_hmac_required": true,
    "sec_immutable_verdicts": true,
    "audit_merkle_required": true,

    # ── P0-1: CRBR — Centralny Rejestr Beneficjentów Rzeczywistych (API) ──
    "crbr_api": {
        "endpoint": "https://crbr.podatki.gov.pl/api/beneficiaries",
        "portal": "https://crbr.podatki.gov.pl",
        "free_search": true,
        "registration_deadline_days": 7,          # od wpisu do CEIDG/KRS
        "update_deadline_days": 7,                # od zmiany danych
        "sanction_max_pln": 1000000,              # Art. 153 u.AML
        "required_fields": ["nip", "krs", "beneficiaries", "shares_pct"],
    },

    # ── P0-2: GIIF — automatyczna wysyłka zgłoszeń STR (API) ──
    "gijf_str_api": {
        "endpoint": "https://gijf.mf.gov.pl/str/api",
        "channel": "ePUAP + API GIIF",
        "deadline_working_days": 1,               # Art. 74-80 u.AML
        "confirmation_required": true,            # urzędowe potwierdzenie odbioru (UPO)
        "confirmation_type": "UPO_GIIF",
        "sanction_max_pln": 1000000,
        "min_threshold_eur": 15000,
    },

    # ── P1-1: mapa podprocesorów SaaS (Art. 28 + podpowierzenie) ──
    "saas_subprocessors": [
        {"category": "HOSTING_CHMURY", "example": "AWS/OvH/Google Cloud", "art28_required": true, "subprocessing_consent": true},
        {"category": "KSIEGOWOSC_CHMURA", "example": "wFirma/Fakturownia/Comarch", "art28_required": true, "subprocessing_consent": true},
        {"category": "EMAIL_MARKETING", "example": "MailerLite/HubSpot/Salestube", "art28_required": true, "subprocessing_consent": true},
        {"category": "CRM", "example": "Pipedrive/Bitrix24/HubSpot CRM", "art28_required": true, "subprocessing_consent": true},
        {"category": "REKRUTACJA_HR", "example": "Element/eRecruiter/Softgarden", "art28_required": true, "subprocessing_consent": true},
        {"category": "ANALITYKA", "example": "Google Analytics/Matomo/Plausible", "art28_required": false, "subprocessing_consent": false},
        {"category": "PODATKI_KSEF", "example": "dostawca KSeF/JPK/e-Deklaracje", "art28_required": true, "subprocessing_consent": true},
        {"category": "REKLAMA_AI", "example": "Meta Ads/Google Ads (profilowanie)", "art28_required": true, "subprocessing_consent": true},
    ],

    # ── P1-2: kalendarz terminów RODO ──
    "rodo_deadline_calendar": [
        {"task": "przegląd rejestru czynności przetwarzania", "frequency": "rocznie", "month": 12, "legal_basis": "Art. 30 RODO"},
        {"task": "przegląd umów powierzenia (Art. 28)", "frequency": "rocznie", "month": 6, "legal_basis": "Art. 28 RODO"},
        {"task": "DPIA przed nowym przetwarzaniem wysokiego ryzyka", "frequency": "przed_startem", "month": 0, "legal_basis": "Art. 35 RODO"},
        {"task": "przegląd zabezpieczeń technicznych/organizacyjnych", "frequency": "kwartalnie", "month": 3, "legal_basis": "Art. 32 RODO"},
        {"task": "retencja danych księgowych (min. 5 lat)", "frequency": "5_lat", "month": 0, "legal_basis": "Art. 74 ust. 2 UoR"},
        {"task": "aktualizacja rejestru po zmianach", "frequency": "na_biezaco", "month": 0, "legal_basis": "Art. 24 RODO"},
    ],

    # ── P1-3: listy sankcyjne UE/ONZ — scoring z danymi rzeczywistymi ──
    "sanctions_lists": {
        "eu_consolidated": {"name": "EU Consolidated Financial Sanctions List", "source": "data.europa.eu/eu-sanctions", "weight": 50},
        "un_sc": {"name": "UN Security Council Consolidated List", "source": "scsanctions.un.org", "weight": 50},
        "ofac_sdn": {"name": "OFAC SDN (USA)", "source": "treasury.gov/ofac", "weight": 40},
        "uk_ofsi": {"name": "UK OFSI Consolidated List", "source": "ofsi.hmt.gov.uk", "weight": 40},
        "pep_national": {"name": "PEP krajowa lista (osoby pełniące funkcje publiczne)", "source": "rejestr krajowy", "weight": 20},
    },
    "sanctions_block_threshold": 50,              # score >= 50 → BLOCK_AND_ALERT
    "sanctions_pep_routing": "TRIAGE_QUEUE",

    # ── P2-1: AMLR (UE 2024/1624) — single rulebook od 2027 ──
    "amlr_2027": {
        "regulation": "UE 2024/1624",
        "application_from": "2027-07-10",
        "cash_threshold_eur": 10000,              # nowy próg gotówkowy (obniżony do 10k EUR)
        "crypto_threshold_eur": 1000,             # usługi krypto — próg CBDD 1000 EUR
        "single_rulebook": true,
        "aml_authority": "AMLA (Frankfurt) — nadzór od 2028",
        "cbdd_enhanced_high_risk": true,
        "football_clubs_scope": true,             # nowy sektor w zakresie AMLR
    },

    # ── P2-2: UI panelu ryzyka AML + dashboard naruszeń RODO 72h ──
    "compliance_dashboard": {
        "aml_panel": {"clients_high_risk": 0, "transactions_flagged": 0, "str_pending": 0},
        "breach_72h": {"deadline_hours": 72, "breaches_open": 0},
        "refresh": "na żywo (hot-reload ADR-002)",
        "export_formats": ["JSON", "CSV", "PDF"],
        "widgets": ["panel_ryzyka_aml", "dashboard_breach_72h", "kalendarz_rodo", "mapa_podprocesorow", "screening_sankcyjny", "status_amlr_2027"],
    },
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

    # ── V3-P46 MIGRACJA HARDCODE (ADR-002) — KKS jako dane [NIEZWERYFIKOWANE — ISAP, P47] ──
    # KKS art. 53 §3: próg przestępstwa — uszczuplenie > 26 000 PLN
    "kks_criminal_threshold": 26000,             # PLN (Dz.U. 2025 poz. 678, ze zm.) [NIEZWERYFIKOWANE]
    # KKW art. 97 §3: maksymalna wysokość mandatu karnego — 200 stawek dziennych
    "kks_mandate_tier3_cap": 26000,              # PLN (200 × 130 PLN) [NIEZWERYFIKOWANE]
    "kks_daily_rate": 130,                       # PLN — stawka dzienna mandatu [NIEZWERYFIKOWANE]
    # KKW art. 97 §1: mandaty niższe — stawki 1–10 (≤5 200) i 11–20 (≤10 400)
    "kks_mandate_tier1_cap": 5200,               # PLN — max mandatu, uszczuplenie ≤ 5 200 [NIEZWERYFIKOWANE]
    "kks_mandate_tier2_cap": 10400,              # PLN — max mandatu, uszczuplenie 5 200–13 000 [NIEZWERYFIKOWANE]
    "kks_mandate_tier1_loss_max": 5200,          # PLN — górna granica uszczuplenia stawek 1–10 [NIEZWERYFIKOWANE]
    "kks_mandate_tier2_loss_max": 13000,         # PLN — górna granica uszczuplenia stawek 11–20 [NIEZWERYFIKOWANE]
    # KKS: orientacyjna stawka odsetek dziennych od zaległości (0.038%/dzień)
    "kks_daily_interest_rate": 0.00038,          # ułamek dzienny [NIEZWERYFIKOWANE — ISAP, P47]
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

    # ── CZĘŚĆ 1 (rdzeń orkiestratora) — ADR-002: progi edge_cases.rego ──
    "vat_exemption_alert": 100000,               # Alert YTD przy 50% limitu 200k (R0589 edge_cases)
    "lump_sum_alert_eur": 1500000,               # Alert 75% limitu 2M EUR (R0624 edge_cases)
    "small_taxpayer_limit_eur": 2000000,         # Art. 2 pkt 25 VAT — mały podatnik (R0625)
    "small_taxpayer_alert_eur": 1000000,         # Alert 50% limitu małego podatnika (R0625)
    "full_accounting_limit_eur": 2000000,        # Art. 24a PIT — próg pełnej księgowości (R0626)
    "health_linear_floor": 10000,                # Próg zapłaconej składki zdrowotnej (R0633)
    "thermo_relief_limit": 53000,                # Ulga termomodernizacyjna — limit (R0648)
    "thermo_relief_min_costs": 40000,            # Ulga termomodernizacyjna — próg wejścia (R0648)
    "proto_relief_limit": 300000,                # Ulga na prototyp — limit (R0651)
    "proto_relief_min_costs": 200000,            # Ulga na prototyp — próg wejścia (R0651)
    "expansion_relief_limit": 1000000,           # Ulga na ekspansję — limit (R0654)
    "expansion_relief_min_costs": 500000,        # Ulga na ekspansję — próg wejścia (R0654)
    "loss_one_time_limit": 5000000,              # Jednorazowe odliczenie straty COVID — max 5M (R0657)
    "loss_one_time_alert": 1000000,              # Jednorazowe odliczenie straty — alert (R0657)
    "cash_register_threshold": 20000,            # Kasa fiskalna — próg B2C (R0662)
    "giif_reporting_eur": 15000,                 # GIIF — próg raportowania EUR (R0664)
    "cesop_reporting_eur": 25000,                # CESOP — próg raportowania EUR (R0665)
    "b2c_eu_threshold_eur": 10000,               # Sprzedaż wysyłkowa B2C — próg 10k EUR (R0686)
}

# ── CZĘŚĆ 1 (rdzeń orkiestratora) — ADR-002: EPOKI CZASOWE (rok jako dana) ──
# Lata przełomowe prawa używane w czasowych guardach temporal.rego — zero
# literałów w logice; aktualizacja epok = zmiana danych, bez rekompilacji.
temporal_epochs := {
    "e2018": 2018,   # próg jednorazowej amortyzacji 100k (Art. 22d PIT)
    "e2019": 2019,   # stawki PIT 17%/32%; dokumenty pracownicze ZUS 10 lat
    "e2020": 2020,   # start COVID-19 legacy (tarcze)
    "e2021": 2021,   # koniec COVID-19 legacy
    "e2022": 2022,   # Polski Ład: 12%/32%, próg 120k, kwota wolna 30k
    "e2023": 2023,   # zniesienie ulgi dla klasy średniej
    "e2025": 2025,   # historyczne stawki PIT 2025
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
    "zus_social_total": zus.zus_social_total_rate,
    "zus_annual_base_cap_multiplier": zus.zus_annual_base_cap_multiplier,
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
    },

    # P930 — limit działalności nieewidencjonowanej: 50% → 75% (01.07.2023)
    "unregistered_revenue_pct": {
        "valid_from": "2023-07-01",
        "value": 0.75,
        "previous_value": 0.50,
        "previous_valid_from": "2018-04-30",
        "reason": "Art. 5 ust. 1 pkt 1 PP — podwyższenie limitu z 50% do 75% płacy minimalnej (nowelizacja obowiązująca od 01.07.2023)"
    },

    # R03 P1 (A03) — art. 113 ust. 1 VAT: limit zwolnienia podmiotowego (200k, od 2017)
    # Limit stały 200 000 PLN od 2017-01-01; art. 113 ust. 9 (SLIM VAT 2) — opcja
    # kwartalna dla nowych podatników od 2021-07-01 (helper subject_exemption_quarterly_mode).
    "subject_exemption_limit": {
        "valid_from": "2017-01-01",
        "value": 200000,
        "reason": "Art. 113 ust. 1 VAT — limit zwolnienia podmiotowego 200 000 zł (stały od 2017; opcja kwartalna ust. 9 od 2021-07-01)"
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

# ═══════════════════════════════════════════════════════════════════════════════
# R02 P1 — DZIAŁALNOŚĆ NIEEWIDENCJONOWANA: LIMIT TEMPORALNY (art. 5 ust. 1 pkt 1 PP)
# ═══════════════════════════════════════════════════════════════════════════════
# Jedno źródło prawdy dla procentu limitu — weryfikowalnie zewnętrzne
# (data.thresholds). Reguły NIE hardkodują kwot ani procentów.
#   - do 2023-06-30:  50% płacy minimalnej miesięcznie
#   - 2023-07-01 → 2025-12-31: 75% płacy minimalnej miesięcznie
#   - od 2026-01-01:  225% płacy minimalnej KWARTALNIE (ekwiwalent mies. 75%)

# Miesięczny ekwiwalent procentu (50% → 75% od 01.07.2023; 2026: 225%/3 = 75%)
unregistered_limit_pct(eval_date) = pct {
    pct := to_number(get_temporal_threshold("unregistered_revenue_pct", eval_date))
} else = 0.75 {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R03 P1 (A03) — ART. 113 UST. 1 VAT: LIMIT ZWOLNIENIA PODMIOTOWEGO (TEMPORALNY)
# ═══════════════════════════════════════════════════════════════════════════════
# Jedno źródło prawdy: limit 200 000 zł czytany temporalnie z temporal_thresholds
# (od 2017-01-01). Reguły (CRIT-5, P51, P51b, P131) NIE hardkodują 200 000.
subject_exemption_limit_for_date(eval_date) = limit {
    limit := to_number(get_temporal_threshold("subject_exemption_limit", eval_date))
} else = 200000 {
    true
}

# ── R03 P1 — ART. 113 UST. 9 VAT: OPCJA KWARTALNA (SLIM VAT 2, od 2021-07-01) ──
# Nowi podatnicy mogą rozliczać limit proporcjonalnie wg kwartałów pozostałych
# do końca roku (SLIM VAT 2 — art. 113 ust. 9 VAT, od 01.07.2021).
subject_exemption_quarterly_mode(eval_date) = true {
    eval_date >= "2021-07-01"
} else = false {
    true
}

# Mnożnik limitu kwartalnego (2026+): 225% płacy minimalnej na kwartał; 0 = brak trybu kwartalnego
unregistered_quarterly_multiplier(eval_date) = 2.25 {
    eval_date >= "2026-01-01"
} else = 0.0 {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-13 — MICRO QUALITY / DECOUPLED BOUNDARY SNAPSHOT (ADR-002)
# Legacy generated micro records are audited without rewriting their semantics.
# Empty optional fields are normalized at the boundary; macro handoff requires
# an explicit binding and golden input evidence.
micro_quality_v3_13 := {
    "threshold_version": "micro-quality-2026.08",
    "legal_basis_version": "micro-quality-contract-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "mode": "DECOUPLED",
    "no_auto_post": true,
    "empty_field_policy": "EMPTY_OPTIONAL_TO_NULL_AT_BOUNDARY",
    "binding_policy": "EXPLICIT_MICRO_RULE_TO_MACRO_RULE",
    "golden_input_required": true,
    "syntax_errors_block": true,
    "duplicate_rule_ids_block": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-14 — HYPER CONTEXTS PLAN44/45 QUALITY SNAPSHOT (ADR-002)
# Registry i progi są wersjonowane oraz konsumowane przez pakiet jakości.
hyper_quality_v3_14 := {
    "threshold_version": "hyper-quality-2026.08",
    "legal_basis_version": "hyper-contexts-legal-2026.08",
    "registry_version": "hyper-registry-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "context_catalog": ["GENERAL", "DEADLINES", "LIMITS", "SANCTIONS", "MDR", "FX", "AUDIT", "EDELIVERY", "FAMILY", "FORCE_MAJEURE", "PROCUREMENT", "SOLIDARITY", "WIS", "RESIDENCY", "TP", "ESIG"],
    "allowed_deadline_statuses": ["OPEN", "DUE", "FILED", "OVERDUE", "SHIFTED", "BLOCKED"],
    "allowed_sanction_maps": ["KKS", "ORD", "VAT", "BDO", "RODO", "AML"],
    "working_day_policy": "NEXT_WORKING_DAY",
    "alert_days": [7, 3, 1],
    "no_auto_post": true,
    "force_manual_review": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-15 — ENTERPRISE INITIATIVES / NEURAL MESH / SCORING SNAPSHOT (ADR-002)
enterprise_quality_v3_15 := {
    "threshold_version": "enterprise-quality-2026.08",
    "registry_version": "enterprise-s1-s24-2026.08",
    "legal_basis_version": "enterprise-legal-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "score_auto_post_min": 92,
    "score_suggest_min": 75,
    "score_abstain_max": 50,
    "calibration_min_samples": 100,
    "calibration_accuracy_min": 0.95,
    "calibration_brier_max": 0.10,
    "max_conflicts_for_suggest": 0,
    "min_mesh_nodes": 13,
    "min_mesh_edges": 12,
    "min_red_team_scenarios": 10,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═════════════════════════════════════════════════════════════════════════
# V3-16 — NARZĘDZIA + BRAMKI JAKOŚCI + GAP REPORTS SNAPSHOT (ADR-002)
tools_quality_v3_16 := {
    "threshold_version": "tools-quality-2026.08",
    "registry_version": "quality-gates-2026.08",
    "legal_basis_version": "quality-gates-legal-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "required_linters": ["lint_rego_rules", "validate_rules", "dead_rule_detector", "tautology_guard", "else_chain_dead_code_detector", "hardcoded_audit_gate"],
    "required_validators": ["validate_legal_basis", "validate_enterprise_contract", "cross_ref_validator", "doc_consistency_validator", "inventory_reconciliation", "test_coverage_gate", "temporal_interval_gate", "manifest_v2", "legal_basis_audit"],
    "required_gap_reports": ["legal_coverage_gap_report", "legal_coverage_heatmap", "traceability_matrix", "coverage_95_plan"],
    "coverage_target_pct": 95,
    "max_tautologies": 0,
    "max_dead_criticals": 0,
    "max_hardcode_findings": 0,
    "manifest_diff_blocking": true,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═════════════════════════════════════════════════════════════════
# V3-17 — TESTY + CI/CD + CHAOS + MUTATION + GOLDEN SNAPSHOT (ADR-002)
# Progi spójne z tests_ci_quality_etap24 (mutation 85, fuzz 10000, property 200).
tests_ci_quality_v3_17 := {
    "threshold_version": "tests-ci-v3-2026.08",
    "registry_version": "tests-ci-campaign-2026.08",
    "legal_basis_version": "tests-ci-legal-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "coverage_target_pct": 95,
    "min_mutation_score": 85,
    "min_fuzz_cases": 10000,
    "min_property_cases": 200,
    "min_chaos_experiments": 5,
    "golden_replay_required": true,
    "required_workflows": ["ci.yml", "opa-ci.yml", "jdg-quality-gates-blocking.yml", "jdg-scheduled-drift.yml"],
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════
# V3-18 — BUNDLES + POLICIES MIRROR + RULESTORE + MIGRACJE + DEPLOY SNAPSHOT (ADR-002)
bundles_quality_v3_18 := {
    "threshold_version": "bundles-v3-2026.08",
    "registry_version": "bundles-campaign-2026.08",
    "legal_basis_version": "bundles-legal-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "min_rulestore_migrations": 13,
    "max_hot_reload_seconds": 60,
    "max_rollback_mttr_min": 5,
    "max_mirror_drift_pct": 0,
    "max_rto_min": 15,
    "max_rpo_min": 15,
    "dr_game_day_max_days": 30,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════
# V3-19 — API + CONTROL PLANE + UI / CENTRUM DECYZJI SNAPSHOT (ADR-002)
# Progi spójne z ETAP 25 (17 ścieżek) i V2 F4 (centrum decyzji).
api_ui_quality_v3_19 := {
    "threshold_version": "api-ui-v3-2026.08",
    "registry_version": "api-ui-campaign-2026.08",
    "legal_basis_version": "api-ui-legal-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "min_api_endpoints": 17,
    "max_documented_only_gaps": 0,
    "min_soak_hours": 24,
    "required_decision_modes": ["AUTO_POST", "SUGGEST", "ASK_USER"],
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════
# V3-20 — DOKUMENTACJA + LEGAL TWIN + HARMONIZACJA SNAPSHOT (ADR-002)
docs_quality_v3_20 := {
    "threshold_version": "docs-v3-2026.08",
    "registry_version": "docs-campaign-2026.08",
    "legal_basis_version": "docs-legal-2026.08",
    "valid_from": "2026-01-01",
    "valid_to": null,
    "campaign_total_parts": 20,
    "min_v3_packages_in_manifest": 7,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-29 — KAMPANIE JAKOŚCI V3 / 8 BRAMEK (MICRO/HYPER/ENTERPRISE/TOOLS/TESTS_CI/
# BUNDLES/API_UI/DOCS) SNAPSHOT (ADR-002)
# Progi spójne z v3_13..v3_20 (mutation 85, coverage 95) i kontraktem P29.
# Rejestr bramek jako dane (I06) — definicje bramek bez deployu kodu (P06).
v3_p29 := {
    "v3_p29_threshold_version": "quality-v3p29-2026.09",
    "legal_basis_version": "quality-gates-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I02: mutation testing — czułość suite'a (nie linie pokrycia)
    "v3_p29_min_mutation_score": 85,
    # I03: quality debt ledger — limit otwartych długów P1
    "v3_p29_max_open_debts_p1": 0,
    # I04: deterministyczny seed — replay 1:1
    "v3_p29_seed_required": true,
    # I05: profil czasowy bramek — limit i dryf
    "v3_p29_max_gate_seconds": 120,
    "v3_p29_perf_drift_pct": 50,
    # I08: heatmapa domen — progi RED/AMBER/GREEN
    "v3_p29_heatmap_red_below": 60,
    "v3_p29_heatmap_green_from": 80,
    # I09: fasady — zero fasad w testach blokujących merge
    "v3_p29_max_blocking_facades": 0,
    # I06: rejestr bramek jako dane (katalog kontraktów v3_13..v3_20)
    "v3_p29_gate_registry": {
        "v3_13": {"name": "micro", "package": "jdg.micro.quality_v3_13", "checks": ["syntax", "duplicates", "stubs", "hardcode"], "blocking": true},
        "v3_14": {"name": "hyper", "package": "jdg.hyper.quality_v3_14", "checks": ["context_catalog", "deadline_statuses", "sanction_maps"], "blocking": true},
        "v3_15": {"name": "enterprise", "package": "jdg.enterprise.quality_v3_15", "checks": ["verdict_25field", "mesh_nodes", "calibration"], "blocking": true},
        "v3_16": {"name": "tools", "package": "jdg.tools.quality_v3_16", "checks": ["linters", "validators", "gap_reports"], "blocking": true},
        "v3_17": {"name": "tests_ci", "package": "jdg.tests_ci.quality_v3_17", "checks": ["coverage", "mutation", "fuzz", "chaos", "golden"], "blocking": true},
        "v3_18": {"name": "bundles", "package": "jdg.bundles.quality_v3_18", "checks": ["manifest_vs_registry", "mirror_drift", "rollback"], "blocking": true},
        "v3_19": {"name": "api_ui", "package": "jdg.api_ui.quality_v3_19", "checks": ["openapi_validation", "breaking_change", "decision_modes"], "blocking": true},
        "v3_20": {"name": "docs", "package": "jdg.docs.quality_v3_20", "checks": ["legal_twin", "docs_rules_gate", "manifest", "certification"], "blocking": true},
    },
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-30 — FALE INNOWACJI / 24 GATE'Y RAPORTÓW R01–R24 SNAPSHOT (ADR-002)
# Progi spójne z kontraktem P30 (rejestr wdrożeń, adopt-rate, golden replay,
# budżet wdrożeniowy) i P29 (bramki jakości).
v3_p30 := {
    "v3_p30_threshold_version": "waves-v3p30-2026.09",
    "legal_basis_version": "waves-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I02: adopt-rate — minimalny próg per domena
    "v3_p30_adopt_rate_min_pct": 60,
    # I04: kontrakt selekcji V4 — próg wysokiego ROI
    "v3_p30_v4_high_roi_min": 80,
    # I09: budżet wdrożeniowy — maks. reguł w jednym wdrożeniu
    "v3_p30_max_rules_per_deployment": 20,
    # I01: dozwolone statusy rejestru wdrożeń
    "v3_p30_registry_statuses": ["OPEN", "IN_PROGRESS", "DONE", "REJECTED"],
    # I07: klasy ryzyka rekomendacji
    "v3_p30_risk_classes": ["TRIVIAL", "IMPORTANT", "CRITICAL"],
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-31 — ETAPY AUDYTÓW 12–28 SNAPSHOT (ADR-002)
# Progi spójne z kontraktem P31 (supersynteza, risk-of-fortress, frontier
# matrix, red team pack) i P29/P30 (wspólny JSON, rejestr wdrożeń).
v3_p31 := {
    "v3_p31_threshold_version": "audit-v3p31-2026.09",
    "legal_basis_version": "audit-stages-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I03: red team pack — minimalna liczba ataków
    "v3_p31_min_red_team_attacks": 10,
    # I04: risk-of-fortress — maksymalny score
    "v3_p31_max_risk_of_fortress": 30,
    # I08: frontier matrix — wiek dowodu (dni)
    "v3_p31_evidence_stale_days": 90,
    # I11: kampania domknięcia — limit etapów bez dowodów
    "v3_p31_max_stages_without_evidence": 0,
    # I05: rejestr etapów jako dane (17 etapów, kontrole i zakres)
    "v3_p31_stage_registry": {
        "etap12": {"domain": "zus_core", "controls": ["rates", "reliefs", "30x_cap"], "blocking": true},
        "etap13": {"domain": "zus_micro", "controls": ["micro_rego", "benefits"], "blocking": true},
        "etap14": {"domain": "pkpir", "controls": ["month_close", "columns"], "blocking": true},
        "etap15": {"domain": "uor", "controls": ["corrections", "pkpir_diff"], "blocking": true},
        "etap16": {"domain": "kks_ord", "controls": ["limitation", "penalty"], "blocking": true},
        "etap17": {"domain": "crossborder", "controls": ["fx", "wdt", "2026"], "blocking": true},
        "etap18": {"domain": "lifecycle", "controls": ["suspension", "succession"], "blocking": true},
        "etap19": {"domain": "local_excise", "controls": ["pcc", "akcyza"], "blocking": true},
        "etap20": {"domain": "ksef_jpk", "controls": ["ksef2", "jpk_v7"], "blocking": true},
        "etap21": {"domain": "rodo_aml_bdo_hr", "controls": ["ppk", "hr_dates"], "blocking": true},
        "etap22": {"domain": "hyper_contexts", "controls": ["plan45_coherence"], "blocking": true},
        "etap23": {"domain": "ai_neural", "controls": ["hitl_auto_post"], "blocking": true},
        "etap24": {"domain": "tests_ci", "controls": ["coverage", "mutation"], "blocking": true},
        "etap25": {"domain": "tools_api_rulestore", "controls": ["rulestore_migrations"], "blocking": true},
        "etap26": {"domain": "mirror_sync", "controls": ["drift_detection"], "blocking": true},
        "etap27": {"domain": "red_team", "controls": ["input_mutations", "fail_closed"], "blocking": true},
        "etap28": {"domain": "final_certification", "controls": ["reconciliation", "slo"], "blocking": true},
    },
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P32 — AUTOMATYZACJA KSIĘGOWOŚCI (pipeline faktura→archiwum) — ADR-002/P05
# ═══════════════════════════════════════════════════════════════════════════════
v3_p32 := {
    "v3_p32_threshold_version": "ksiegowosc-v3p32-2026.09",
    "legal_basis_version": "ksiegowosc-automation-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: minimalna pewność zaksięgowania automatycznego (AUTO_POST)
    "v3_p32_auto_post_min_confidence": 95,
    # I04: kolejka NEEDS_ADVICE — wiek wpisu i przepełnienie
    "v3_p32_advice_max_age_days": 14,
    "v3_p32_advice_overflow": 200,
    # I05: reconciliation z wyciągiem bankowym
    "v3_p32_recon_unmatched_max": 0,
    "v3_p32_recon_amount_gap_max": 0.01,
    # I07: replay sezonowy — maksymalny dryf decyzji
    "v3_p32_replay_drift_max": 0,
    # I08: okno korekt pre-deadline (dni przed terminem deklaracji)
    "v3_p32_correction_window_days": 7,
    # I09: próg kwotowy 4-eyes dla krytycznych AUTO_POST
    "v3_p32_four_eyes_min_amount": 5000,
    # I10: limit dokumentów z zerwanym łańcuchem traceability
    "v3_p32_trace_broken_max": 0,
    # I11: domeny dozwolone do auto-księgowania (limity jako dane)
    "v3_p32_automation_limits": {
        "domeny_auto": ["zakupy_vat23", "zakupy_vat8", "sprzedaz_vat23", "zus_skladki"],
        "max_kwota_auto_post": 5000,
        "wymagany_hash_dokumentu": true,
    },
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P33 — WARSTWA AI ENTERPRISE (neural mesh, LLM bridge, human-in-the-loop)
# ═══════════════════════════════════════════════════════════════════════════════
v3_p33 := {
    "v3_p33_threshold_version": "ai-enterprise-v3p33-2026.09",
    "legal_basis_version": "ai-enterprise-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: formalna ścieżka awansu propozycji AI (kolejność wiążąca)
    "v3_p33_pipeline_stages": ["llm_output", "syntax_validate", "smt_z3_proof",
                               "golden_replay", "four_eyes", "shadow"],
    # I02: tryb sandboxa AI (read_only | write_sandbox)
    "v3_p33_ai_sandbox_mode": "read_only",
    # I03: weryfikacja podstaw prawnych z LLM w ISAP obowiązkowa
    "v3_p33_isap_verification_required": true,
    # I04: ledger promptów w WORM + algorytm checksumy jako dane
    "v3_p33_prompt_ledger_worm": true,
    "v3_p33_prompt_ledger_checksum_alg": "sha256",
    # I05: red-team prompt suite — kategorie ataków jako dane + minimum kategorii
    "v3_p33_red_team_attacks": ["injection", "jailbreak", "exfiltration",
                                "role_escape", "key_phishing"],
    "v3_p33_red_team_min_categories": 3,
    # I06: AUTO_POST zawsze przez AI-gate (trust score odcięty od decyzji)
    "v3_p33_ai_gate_required": true,
    # I07: digital twin wyłącznie na danych syntetycznych (RODO by design)
    "v3_p33_twin_synthetic_only": true,
    # I08: budżet tokenów i kosztu per sesja AI (cost governor)
    "v3_p33_token_budget": 1000000,
    "v3_p33_cost_limit_pln": 500,
    # I09: wyjaśnienie propozycji AI obowiązkowe (explain-first)
    "v3_p33_explanation_required": true,
    # I10: federated mesh — tylko zanonimizowane agregaty (kontrakt prywatności)
    "v3_p33_mesh_aggregates_only": true,
    "v3_p33_mesh_min_k": 5,
    "v3_p33_mesh_aggregate_violation_max": 0,
    # I11: quantum-safe — docelowy rok migracji post-quantum (harmonogram jako dane)
    "v3_p33_quantum_migration_year": 2030,
    # I12: predictor triage — minimalny percentyl pewności sugestii
    "v3_p33_judgment_min_percentile": 80,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P34 — WALIDACJA NARZĘDZI (walidacja jako governance, poziomy DAG L1-L5)
# ═══════════════════════════════════════════════════════════════════════════════
v3_p34 := {
    "v3_p34_threshold_version": "walidacja-v3p34-2026.09",
    "legal_basis_version": "walidacja-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: poziomy DAG walidacji jako dane (kolejność wiążąca)
    "v3_p34_dag_levels": ["L1_syntax", "L2_lint", "L3_tests", "L4_semantic", "L5_legal"],
    # I04: property-based fuzzing — minimalna liczba inputów per reguła
    "v3_p34_fuzz_min_inputs": 1000,
    # I06: mirror parity — limit reguł bez porównania AST
    "v3_p34_mirror_unchecked_max": 0,
    # I07: doc-numbers — limit liczb bez anchora [DEKLARACJA]
    "v3_p34_doc_unanchored_max": 0,
    # I10: heatmapa pokrycia — maksymalna niemłodość i limit spadku punktów
    "v3_p34_heatmap_max_stale_days": 1,
    "v3_p34_coverage_drop_block": 5,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P35 — AUDYTORY DOMENOWE (trust score, auditor-as-data, golden cases, skew)
# ═══════════════════════════════════════════════════════════════════════════════
v3_p35 := {
    "v3_p35_threshold_version": "audytory-v3p35-2026.09",
    "legal_basis_version": "audytory-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: trust score — podłoga pewności domeny i próg spadku (telemetria)
    "v3_p35_trust_score_floor": 70,
    "v3_p35_trust_drop_triage": 10,
    # I02: definicje audytów bez kontroli — limit
    "v3_p35_missing_controls_max": 0,
    # I03: golden cases — minimum per domena i maksymalny wiek replay
    "v3_p35_golden_cases_min_per_domain": 3,
    "v3_p35_golden_replay_max_age_days": 30,
    # I08: audyt nocny — maksymalna liczba pominiętych dni
    "v3_p35_nightly_missed_max_days": 1,
    # I09: pętla feedback operatora — maksymalny wiek
    "v3_p35_feedback_max_age_days": 14,
    # I10: SLA reakcji na alarm (godziny)
    "v3_p35_alert_sla_hours": 4,
    # I11: maksymalny wiek dowodu aktualności prawa (ISAP check)
    "v3_p35_law_freshness_max_days": 7,
    # I12: audyt inverse — minimum przypadków negatywnej przestrzeni per domena
    "v3_p35_inverse_cases_min": 3,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P36 — GENERATORY MIGRATORY (transformacje jako transakcje, zero-orphan)
# ═══════════════════════════════════════════════════════════════════════════════
v3_p36 := {
    "v3_p36_threshold_version": "generatory-v3p36-2026.09",
    "legal_basis_version": "generatory-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I02: certyfikat idempotencji — drugi run = zero diff (bramka P29)
    "v3_p36_idempotency_required": true,
    # I03/I05: generatory produkują reguły+testy jednocześnie; reguła bez testu = BLOCK
    "v3_p36_rule_without_test_max": 0,
    # I05: guard rails — wymagane pola wygenerowanej reguły (legal basis, rule_id, okno, test)
    "v3_p36_generator_required_fields": ["_legal_basis", "rule_id", "valid_from", "test_id"],
    "v3_p36_guard_rail_violations_max": 0,
    # I06: golden replay po migracji — maksymalny dryf werdyktów (P10)
    "v3_p36_replay_drift_max": 0,
    # I07: mirror-aware apply — dryf mirror po aplikacji (sync P39/P48)
    "v3_p36_mirror_divergence_max": 0,
    # I08: generator testów granicznych — minimalne pokrycie reguł wyliczania (%)
    "v3_p36_boundary_rules_min_covered": 100,
    # I12: zero-orphan guarantee — łączny limit orphanów po transformacji
    "v3_p36_orphans_max": 0,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P37 — OBSERWOWALNOŚĆ (SLO, freshness SLA, alerting, benchmark gate)
# ═══════════════════════════════════════════════════════════════════════════════
v3_p37 := {
    "v3_p37_threshold_version": "obserwowalnosc-v3p37-2026.09",
    "legal_basis_version": "obserwowalnosc-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I02: SLA świeżości weryfikacji prawa (ISAP check) per akt
    "v3_p37_law_freshness_sla_days": 7,
    # I03: radar NEEDS_ADVICE — próg skoku względem baseline
    "v3_p37_na_spike_ratio": 3,
    # I04: budżet latencji p95 per domena (ms)
    "v3_p37_latency_p95_max_ms": 500,
    # I06: error budget — freeze wdrożeń poniżej tego poziomu (%)
    "v3_p37_error_budget_min_pct": 0,
    # I08: maksymalny rozjazd produkcja vs golden verdicts (P10)
    "v3_p37_golden_drift_max": 0,
    # I09: runbook-as-code — limit alarmów bez runbooka
    "v3_p37_alert_without_runbook_max": 0,
    # I10: status page — maksymalna niemłodość (dni)
    "v3_p37_status_page_max_stale_days": 1,
    # I11: limit kosztu decyzji AI (jednostki kosztu per decyzja)
    "v3_p37_ai_cost_limit_per_decision": 1.0,
    # I12: benchmark gate — maksymalna regresja p95 (%)
    "v3_p37_benchmark_regression_max_pct": 10,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═════════════════════════════════════════════════════════════════════════
# V3-P39 — TESTY I CI (piramida L1-L7, bramki merge, benchmark, niezmienniki)
# ═════════════════════════════════════════════════════════════════════════
v3_p39 := {
    "v3_p39_threshold_version": "testy-ci-v3p39-2026.09",
    "legal_basis_version": "testy-ci-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: minimalne pokrycie matrycy aktów granicami (grosze/data/waluta) %
    "v3_p39_matrix_coverage_min_pct": 80,
    # I06: minimalna czułość mutacyjna suite'a % (spójne z P29/v3_17)
    "v3_p39_mutation_score_min_pct": 85,
    # I09: minimalne pokrycie testami per akt prawny %
    "v3_p39_act_coverage_min_pct": 90,
    # I10: maksymalna regresja benchmarku p95 % (spójne z P37-I12)
    "v3_p39_benchmark_regression_max_pct": 10,
    # I12: maksymalna nieświeżość test impact map (dni)
    "v3_p39_impact_map_max_stale_days": 7,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════════════════════
# V3-P38 — BUNDLE, DEPLOY I CYKL ŻYCIA WERSJI (canary, rollback, immutabilność)
# ═══════════════════════════════════════════════════════════════════════════
v3_p38 := {
    "v3_p38_threshold_version": "bundle-deploy-v3p38-2026.09",
    "legal_basis_version": "bundle-deploy-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I02: maksymalny rozjazd canary vs produkcja (decyzje na próbce)
    "v3_p38_canary_diff_max": 0,
    # I02: minimalna próbka canary przed awansem
    "v3_p38_canary_sample_min": 100,
    # I03: SLA rollback (V1: powrót do stabilnego w minuty)
    "v3_p38_rollback_mttr_max_min": 5,
    # I05: limit wersji bundle bez archiwum WORM
    "v3_p38_worm_missing_max": 0,
    # I11: minimalny czas shadow evaluation przed canary (godziny)
    "v3_p38_shadow_hours_min": 24,
    # I12: maksymalny wiek changelogu release notes (dni)
    "v3_p38_changelog_max_age_days": 7,
    "no_auto_post": true,
    "manual_review_required": true,
}

# V3-P40 — API, DANE I UI (kontrakt decyzyjny, RBAC, eksplikacja, degradacja)
# ═══════════════════════════════════════════════════════════════════════════
v3_p40 := {
    "v3_p40_threshold_version": "api-dane-ui-v3p40-2026.09",
    "legal_basis_version": "api-dane-ui-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I02: maksymalna liczba węzłów explain chain bez linku do przepisu/ISAP
    "v3_p40_explain_nodes_without_link_max": 0,
    # I06: domyślny limit wywołań API per rola/endpoint (na minutę)
    "v3_p40_rate_limit_default_per_min": 60,
    # I08: maksymalny wiek weryfikacji ISAP dla domeny (dni) — X-Legal-Freshness
    "v3_p40_freshness_sla_max_days": 7,
    "no_auto_post": true,
    "manual_review_required": true,
}

# V3-P41 — DOKUMENTACJA ENTERPRISE (docs-as-code, bramka docs, glosariusz, eksport)
# ═══════════════════════════════════════════════════════════════════════════
v3_p41 := {
    "v3_p41_threshold_version": "dokumentacja-v3p41-2026.09",
    "legal_basis_version": "dokumentacja-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I04: maksymalna liczba dryfów semantycznych PL/EN (ARCHITEKTURA vs ARCHITECTURE)
    "v3_p41_plen_diff_max_findings": 0,
    # I05: maksymalna liczba naruszeń glosariusza (BLOCK przy przekroczeniu)
    "v3_p41_glossary_violations_max": 0,
    # I07: minimalne pokrycie alertów P37 runbookami %
    "v3_p41_runbook_coverage_min_pct": 100,
    # I08: maksymalny wiek changelogu (dni) — generowany z rejestrów
    "v3_p41_changelog_max_age_days": 14,
    # I09: maksymalny wiek dokumentu bez rewizji (dni)
    "v3_p41_doc_freshness_max_days": 90,
    "no_auto_post": true,
    "manual_review_required": true,
}

# V3-P42 — ENTERPRISE RESZTA (health tiers, SMT, WORM, zależności, dojrzałość)
# ═══════════════════════════════════════════════════════════════════════════
v3_p42 := {
    "v3_p42_threshold_version": "enterprise-reszta-v3p42-2026.09",
    "legal_basis_version": "enterprise-reszta-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I02: minimalna liczba dowodów formalnych dla reguł krytycznych
    "v3_p42_smt_min_proofs": 3,
    # I04: retencja artefaktów (lata; 5 lat od końca roku obrotowego)
    "v3_p42_retention_years": 5,
    # I08: maksymalna liczba artefaktów bez właściciela (orfany)
    "v3_p42_orphan_max": 0,
    # I12: maksymalny poziom skali dojrzałości L0–L5
    "v3_p42_maturity_level_max": 5,
    "no_auto_post": true,
    "manual_review_required": true,
}

# V3-P43 — SECURITY I DR (threat model, integralność, ciągłość, naruszenia)
# ═══════════════════════════════════════════════════════════════════════════
v3_p43 := {
    "v3_p43_threshold_version": "security-dr-v3p43-2026.09",
    "legal_basis_version": "security-dr-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: maksymalna liczba kontrol threat modelu bez testu w CI
    "v3_p43_controls_without_test_max": 0,
    # I05: maksymalny wiek chaos legal drill (dni)
    "v3_p43_chaos_drill_max_age_days": 90,
    # I09: maksymalny wiek ćwiczenia ransomware playbook (dni)
    "v3_p43_playbook_exercise_max_days": 90,
    "no_auto_post": true,
    "manual_review_required": true,
}

# V3-P44 — CERTYFIKACJA FINALNA FORTECY (hard gates, WORM+podpis, odnowienie)
# ═══════════════════════════════════════════════════════════════════════════
v3_p44 := {
    "v3_p44_threshold_version": "cert-final-v3p44-2026.09",
    "legal_basis_version": "cert-final-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I07: minimalna retencja certyfikatu finalnego (lata; UoR art. 74-75 [NIEZWERYFIKOWANE])
    "v3_p44_certificate_retention_min_years": 5,
    # I09: maksymalna ważność certyfikatu (dni; odnowienie po nowelizacji/deploy/czasie)
    "v3_p44_cert_validity_max_days": 90,
    # I10: maksymalna liczba otwartych fasad/martwych artefaktów na start V4
    "v3_p44_legacy_facades_max": 0,
    "no_auto_post": true,
    "manual_review_required": true,
}

# V3-P45 — ELIMINACJA STUBÓW I FASAD (stub register, mutation gate, forensics)
# ═══════════════════════════════════════════════════════════════════════════
v3_p45 := {
    "v3_p45_threshold_version": "stub-killer-v3p45-2026.09",
    "legal_basis_version": "stub-killer-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: maksymalna liczba stubów w domenach krytycznych (VAT/PIT/ZUS/KKS)
    "v3_p45_critical_domain_stubs_max": 0,
    # I05: minimalny mutation score per domena (procent)
    "v3_p45_mutation_score_min": 90,
    # I08: maksymalna liczba plików testów tautologicznych (tautology_guard)
    "v3_p45_tautological_test_files_max": 0,
    # I10: maksymalny wiek spisu stubów (dni)
    "v3_p45_census_max_age_days": 7,
    "no_auto_post": true,
    "manual_review_required": true,
}

# V3-P45-CONV — PROGI KONWERSJI STUB→REGUŁA WARUNKOWA (I03; ADR-002, P05)
# ═══════════════════════════════════════════════════════════════════════════
v3_p45_conversions := {
    "v3_p45_conv_threshold_version": "stub-conv-v3p45-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # K1: próg UoR art. 2 ust. 1 pkt 5 (EUR) [NIEZWERYFIKOWANE — ISAP, P47]
    "v3_p45_conv_uor_threshold_eur": 2000000,
    # K3: próg MDR znacznik ogólny (PLN) [NIEZWERYFIKOWANE — ISAP, P47]
    "v3_p45_conv_mdr_main_benefit": 2500000,
    # K4: minimalna podstawa PCC (PLN, art. 9) [NIEZWERYFIKOWANE — ISAP, P47]
    "v3_p45_conv_pcc_min_pln": 1000,
    # K5: stawka WHT 20% (UoWHT art. 21) [NIEZWERYFIKOWANE — ISAP, P47]
    "v3_p45_conv_wht_rate_pct": 20,
    "no_auto_post": true,
    "manual_review_required": true,
}

# P01 SEK. 3 — WERSJONOWANIE THRESHOLDÓW PER OKRES ROZLICZENIOWY (A2+) ENTERPRISE
# ═══════════════════════════════════════════════════════════════════════════════
# System wersjonowania progów: każdy próg może mieć N wersji z oknami
# ważności valid_from/valid_to (per okres rozliczeniowy). Host wstrzykuje
# pełną historię (data.jdg.threshold_versions), a get_threshold_for_period()
# zwraca wartość obowiązującą dla danego okresu — w 100% odtwarzalnie
# (time-travel OPA zgodne z A2 Temporal Causality Chain).
#
# Struktura rekordu:
#   {"key": [{"valid_from": "2022-01-01", "valid_to": "2025-12-31",
#             "value": 120000, "act": "Art. 27 PIT", "reason": "Polski Ład"}, ...]}
# ═══════════════════════════════════════════════════════════════════════════════

# Domyślne wersje per okres (fallback — host może nadpisać data.jdg.threshold_versions)
default_threshold_versions := {
    "pit.scale_threshold": [
        {"valid_from": "2019-01-01", "valid_to": "2021-12-31", "value": 85528, "act": "Art. 27 PIT (przed Polskim Ładem)", "reason": "Próg 85 528 PLN"},
        {"valid_from": "2022-01-01", "valid_to": null, "value": 120000, "act": "Art. 27 PIT", "reason": "Polski Ład 2022 — podwyższenie progu"}
    ],
    "pit.tax_free_amount": [
        {"valid_from": "2019-01-01", "valid_to": "2021-12-31", "value": 8000, "act": "Art. 27 ust. 1 PIT", "reason": "Kwota wolna 8 000 PLN"},
        {"valid_from": "2022-01-01", "valid_to": null, "value": 30000, "act": "Art. 27 ust. 1 PIT", "reason": "Polski Ład 2022 — 30 000 PLN"}
    ],
    "vat.bad_debt_days": [
        {"valid_from": "2020-01-01", "valid_to": "2023-06-30", "value": 150, "act": "Art. 89a VAT (przed SLIM VAT 3)", "reason": "150 dni"},
        {"valid_from": "2023-07-01", "valid_to": null, "value": 90, "act": "Art. 89a VAT", "reason": "SLIM VAT 3 — 90 dni"}
    ],
    "zus.health_linear_deduction": [
        {"valid_from": "2022-01-01", "valid_to": "2025-12-31", "value": 8700, "act": "Art. 26 ust. 1 pkt 2aa PIT", "reason": "Polski Ład 2022"},
        {"valid_from": "2026-01-01", "valid_to": null, "value": 14100, "act": "Art. 26 ust. 1 pkt 2aa PIT", "reason": "Limit 2026"}
    ],
    "pit.lump_sum_annual_limit_eur": [
        {"valid_from": "2019-01-01", "valid_to": "2021-12-31", "value": 250000, "act": "Art. 6 ustawy o ryczałcie", "reason": "250k EUR"},
        {"valid_from": "2022-01-01", "valid_to": null, "value": 2000000, "act": "Art. 6 ustawy o ryczałcie", "reason": "Polski Ład — 2M EUR"}
    ],
    "business.unregistered_revenue_pct": [
        {"valid_from": "2018-04-30", "valid_to": "2023-06-30", "value": 0.50, "act": "Art. 5 ust. 1 pkt 1 PP (brzmienie pierwotne)", "reason": "50% płacy minimalnej miesięcznie"},
        {"valid_from": "2023-07-01", "valid_to": "2025-12-31", "value": 0.75, "act": "Art. 5 ust. 1 pkt 1 PP", "reason": "Podwyższenie do 75% miesięcznie (nowelizacja z 01.07.2023)"},
        {"valid_from": "2026-01-01", "valid_to": null, "value": 2.25, "act": "Art. 5 ust. 1 pkt 1 PP", "reason": "2026: limit kwartalny = 225% płacy minimalnej"}
    ],
    "vat.subject_exemption_limit": [
        {"valid_from": "2017-01-01", "valid_to": null, "value": 200000, "act": "Art. 113 ust. 1 VAT", "reason": "Limit zwolnienia podmiotowego 200 000 zł (opcja kwartalna ust. 9 od 2021-07-01)"}
    ]
}

# Wartość progu dla okresu (data ISO YYYY-MM-DD) — wersjonowanie per okres
# (źródło: default_threshold_versions; host może nadpisać ten blok wprost)
get_threshold_for_period(threshold_key, period) = value {
    versions := object.get(default_threshold_versions, threshold_key, [])
    count(versions) > 0
    # Tylko wersje z valid_from <= period i (valid_to null lub >= period)
    # Rego v0 nie ma operatorów 'and'/'or' — dwie comprehensions połączone concat.
    eligible_open := [v |
        some v in versions
        object.get(v, "valid_from", "0000-01-01") <= period
        vt := object.get(v, "valid_to", null)
        vt == null
    ]
    eligible_dated := [v |
        some v in versions
        object.get(v, "valid_from", "0000-01-01") <= period
        vt := object.get(v, "valid_to", null)
        vt != null
        period <= vt
    ]
    eligible := array.concat(eligible_open, eligible_dated)
    count(eligible) > 0
    # Najnowsza z kwalifikowanych (maks valid_from)
    latest := max([object.get(v, "valid_from", "") | some v in eligible])
    value := object.get([v | some v in eligible; object.get(v, "valid_from", "") == latest][0], "value", 0)
} else = 0 {
    true
}

# Lista okresów, w których zmienił się dany próg (do kalendarza zmian prawa)
threshold_change_periods(threshold_key) = periods {
    versions := object.get(default_threshold_versions, threshold_key, [])
    periods := [{"valid_from": object.get(v, "valid_from", ""), "value": object.get(v, "value", 0), "act": object.get(v, "act", "")} |
        some v in versions
    ]
} else = [] {
    true
}

# V3-P46 — ELIMINACJA HARDCODE: parametry jako podpisany, wersjonowany dokument
# (A2+ ADR-002; P06 parametry-as-data; P05 okna temporalne) — ENTERPRISE
# ═══════════════════════════════════════════════════════════════════════════
v3_p46 := {
    "v3_p46_threshold_version": "hardcode-elim-v3p46-2026.09",
    "legal_basis_version": "hardcode-elim-legal-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: maksymalny wiek rejestru parametrów (dni; odświeżenie po każdej migracji)
    "v3_p46_parameter_registry_max_age_days": 30,
    # I02: minimalna głębokość łańcucha provenance wartości (akt→art→nowela→diff)
    "v3_p46_provenance_chain_min_depth": 3,
    # I03: parametr zmienny prawnie bez valid_from/valid_to = BLOCK (P05)
    "v3_p46_temporal_gate_enabled": true,
    # I04: walidacja JSON-schema thresholds_data w CI (0 błędów dozwolone)
    "v3_p46_schema_errors_max": 0,
    # I08: jednostka parametru jawnie w schemacie; nieznana jednostka = TRIAGE
    "v3_p46_known_units": ["PLN", "PLN_MIN", "EUR", "PERCENT", "RATIO", "MULTIPLIER", "DAYS", "YEARS", "COUNT", "RATE", "M2", "TEXT"],
    # I10: limit „osieroconych" wartości prawnych w kodzie po migracji (audyt P46)
    "v3_p46_orphan_values_max": 0,
    # I10: limit wartości o ekstremalnej wielkości (heurystyka stawek/progów)
    "v3_p46_extreme_literal_max": 0,
    # I11: maksymalny dryf golden replay przy zmianie parametru (liczba zmienionych decyzji AUTO_POST)
    "v3_p46_replay_drift_max_auto_changes": 0,
    # I11: replays z dryfem wymagające 4-eyes ponad ten próg = BLOCK
    "v3_p46_replay_drift_four_eyes_min": 1,
    "no_auto_post": true,
    "manual_review_required": true,
}

# V3-P46-MIGR — MAPA MIGRACJI HARDCODE (kierunkowe cele migracji; wartości = ścieżki
# docelowe w data dokumentach, NIE stawki — stawki trzymają fe:N (I09) [NIEZWERYFIKOWANE — ISAP, P47])
# ═══════════════════════════════════════════════════════════════════════════
v3_p46_migration_map := {
    "v3_p46_mig_threshold_version": "mig-map-v3p46-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: standard nazw parametrów <domena>.<znaczenie>_<jednostka>; zero magicznych kluczy (I12)
    "v3_p46_mig_naming_pattern": "^[a-z][a-z0-9_]*[.][a-z][a-z0-9_]*$",
    # I09: fe:N — stawki ZUS 2026-01→2026-03-31 (zaokrąglenie do grosza) [NIEZWERYFIKOWANE — ISAP/ZUS, P47]
    "v3_p46_mig_zus_2026q1_spotykane": ["fe:N", "fe:N", "fe:N"],
    # I09: fe:N — próg ZUS preferencyjny przychodu 2026 [NIEZWERYFIKOWANE — ISAP/ZUS, P47]
    "v3_p46_mig_zus_preferential_revenue_pln": "fe:N",
    # I09: fe:N — kwota wolna PIT (roczna, PLN) [NIEZWERYFIKOWANE — ISAP/PIT, P47]
    "v3_p46_mig_pit_tax_free_pln": "fe:N",
    # I09: fe:N — drugi próg skali PIT 2026 (PLN) [NIEZWERYFIKOWANE — ISAP/PIT, P47]
    "v3_p46_mig_pit_scale_second_bracket_pln": "fe:N",
    # I09: fe:N — stawka liniowa PIT 19% [NIEZWERYFIKOWANE — ISAP/PIT, P47]
    "v3_p46_mig_pit_linear_rate": "fe:N",
    # I09: fe:N — próg MPP 15 000 PLN [NIEZWERYFIKOWANE — ISAP/VAT, P47]
    "v3_p46_mig_vat_mpp_threshold_pln": "fe:N",
    # I09: fe:N — odsetki za rok podatkowy (Ordynacja art. 56) [NIEZWERYFIKOWANE — ISAP/MF, P47]
    "v3_p46_mig_interest_annual_rate": "fe:N",
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P47 WERYFIKACJA PODSTAW PRAWNYCH — progi (ADR-002 parametry-as-data)
# Zero fikcji: każdy akt z identyfikatorem ISAP, status weryfikacji jawny.
# Honory kontrakty: P45 (rejestr mediacji → P47), P46 (drift tracker, orphan
# backlog 16 581 z SLA ustalanym tutaj), P34 (linter), P08 (Law Radar).
# ═══════════════════════════════════════════════════════════════════════════════
v3_p47 := {
    "v3_p47_threshold_version": "legal-basis-v3p47-2026.09",
    "legal_basis_version": "lb-canon-v3p47-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I02: cytowania niezgodne z kanonem na PR = 0 dozwolonych (linter prawny)
    "v3_p47_lint_errors_max": 0,
    # I08: pełny łańcuch akt→art→ust→pkt; poniżej = BRAK_KOMPLETNOŚCI (TRIAGE)
    "v3_p47_min_chain_depth": 3,
    # I01: maksymalny wiek spisu legal basis (dni; odświeżenie po każdym re-check)
    "v3_p47_census_max_age_days": 30,
    # I03: minimum aktów w rejestrze źródeł (sanity; poniżej = TRIAGE)
    "v3_p47_min_acts_registry": 1,
    # I06: SLA mediacji reguła↔ISAP (dni); po terminie = BLOCK awansu CANDIDATE→ACTIVE
    "v3_p47_mediation_sla_days": 14,
    # I05: świeżość re-checku aktu (dni); powyżej = STALE → SHADOW przegląd
    "v3_p47_freshness_stale_days": 92,
    # I05: kadencja re-checku aktów reguł ACTIVE (dni; codziennie wg promptu)
    "v3_p47_active_recheck_days": 1,
    # I08: cel kompletności łańcuchów dla reguł ACTIVE (%); poniżej = TRIAGE
    "v3_p47_completeness_target_pct": 100,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ── Mapa aktów P47 (Sekcja 8 promptu): identyfikator ISAP + status weryfikacji ──
# TWIERDZENIA, nie dowody (protokół 04): Dz.U./daty do weryfikacji w ISAP/RCL.
# Zakaz fikcyjnych pozycji — wszystkie [NIEZWERYFIKOWANE — ISAP] aż do weryfikacji
# 4-eyes (I10); zero wymyślonych numerów pozycji.
v3_p47_acts := {
    "v3_p47_acts_version": "acts-v3p47-2026.09",
    "valid_from": "2026-01-01",
    "v3_p47_act_ordynacja": {"title": "Ordynacja podatkowa", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU20180002169", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "2019-01-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_vat": {"title": "Ustawa o VAT", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU2004019093", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "2004-05-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_pit": {"title": "Ustawa o PIT", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU19910900193", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "1992-01-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_cit": {"title": "Ustawa o CIT", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU19920110203", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "1992-01-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_zus": {"title": "Ustawa systemowa ZUS", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU19981370887", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "1999-01-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_ksht": {"title": "Ustawa o rachunkowości", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU19940121591", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "1995-01-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_kks": {"title": "Kodeks karny skarbowy", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU19990830930", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "2000-01-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_ksef": {"title": "KSeF (ustawa o VAT art. 106na i nast.)", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU2004019093", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "2026-02-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_pcc": {"title": "Ustawa o PCC", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU20001490843", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "2001-01-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_ryczalt": {"title": "Ustawa o zryczałtowanym podatku dochodowym", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU19981440930", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "1999-01-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_mdr": {"title": "MDR (Ordynacja art. 86a i nast.)", "isap_url": "https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU20180002169", "dz_u": "[NIEZWERYFIKOWANE — ISAP]", "valid_from_claim": "2019-07-01", "verification": "NIEZWERYFIKOWANE"},
    "v3_p47_act_informacja": {"title": "RCL — proces legislacyjny (daty wejścia w życie)", "isap_url": "https://legislacja.gov.pl", "dz_u": "[NIEZWERYFIKOWANE — RCL]", "valid_from_claim": null, "verification": "NIEZWERYFIKOWANE"},
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P48 SYNCHRONIZACJA MIRROR POLICIES — progi (ADR-002 parametry-as-data)
# Zero dryfu canonical↔mirror: mirror jako build output, AST diff gate,
# sync-in-PR, heatmapa dryfu, overlay jawne, parity testów, golden replay,
# własność pakietów, post-deploy checksum, case study, lifecycle alignment,
# one-truth attestation. Honory kontrakty: P00 (jedno źródło prawdy), P36
# (sync w tej samej transakcji), P38 (post-deploy), P10 (golden), P39 (CI),
# P07 (lifecycle), P45/P46/P47 (konwencje fali naprawczej).
# ═══════════════════════════════════════════════════════════════════════════════
v3_p48 := {
    "v3_p48_threshold_version": "mirror-sync-v3p48-2026.09",
    "legal_basis_version": "lb-mirror-v3p48-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: maksymalny wiek synchronizacji mirror (dni; po tym = TRIAGE przegląd)
    "v3_p48_sync_max_age_days": 7,
    # I02: dryf semantyczny AST na PR = 0 dozwolonych (tekstowy — dozwolony)
    "v3_p48_semantic_drift_max": 0,
    # I04: cel: 100% pakietów czystych; próg blokady dryfu najgorszego pakietu (%)
    "v3_p48_heatmap_target_pct": 100,
    "v3_p48_drift_block_pct": 20,
    # I06: minimum przebiegów parity testów na mirror per cykl CI
    "v3_p48_min_parity_runs": 1,
    # I07: maksymalna delta decyzji golden replay mirror vs canonical (0 = zero)
    "v3_p48_replay_delta_max": 0,
    # I08: maksymalny wiek przeglądu własności pakietu mirror (dni)
    "v3_p48_review_max_age_days": 90,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ── Mapa pakietów mirror (I08 własność; I04 heatmapa): właściciel + kadencja ──
# Baseline pomiaru 2026-09-11 (tools/v3_p48_semantic_ast_diff.py): canonical
# 522 plików rego, mirror 580, wspólnych 500 — 472 identycznych, 3 tekstowych,
# 25 semantycznych, 22 brakujących w mirror, 80 osieroconych legacy w mirror.
# Wszystkie statusy weryfikacji: [NIEZWERYFIKOWANE — 4-eyes] do stempla człowieka.
v3_p48_packages := {
    "v3_p48_packages_version": "packages-v3p48-2026.09",
    "valid_from": "2026-01-01",
    "v3_p48_pkg_root": {"path": "policies/", "owner": "P48-campaign", "review_days": 30, "drift_pct": 9.58, "verification": "NIEZWERYFIKOWANE"},
    "v3_p48_pkg_jdg": {"path": "policies/jdg", "owner": "P48-campaign", "review_days": 30, "drift_pct": 100.0, "verification": "NIEZWERYFIKOWANE"},
    "v3_p48_pkg_tax": {"path": "policies/tax", "owner": "P48-campaign", "review_days": 30, "drift_pct": 100.0, "verification": "NIEZWERYFIKOWANE"},
    "v3_p48_pkg_vat": {"path": "policies/tax/vat", "owner": "P48-campaign", "review_days": 30, "drift_pct": 100.0, "verification": "NIEZWERYFIKOWANE"},
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P49 DOMKNIĘCIE FAIL-CLOSED — progi (ADR-002 parametry-as-data)
# Zero cichych AUTO_POST: rejestr ścieżek fail-open (skaner rego), default-deny
# decision core, pack invariantów runtime, generator brakujących pól, chaos
# input, circuit breaker per domena, limit kwotowy AUTO_POST, kompletność
# powodów NEEDS_ADVICE, replay audyt, fail-closed score, canary cichego posta,
# widoczność fail-closed w UI. Honory kontrakty: P03 (kontrakt werdyktu),
# P04 (invarianty runtime), P36/P37 (radar NEEDS_ADVICE, SLA), P40 (UI), P45
# (rejestr), P46 (parametry-as-data), P47 (kanon cytowań), P48 (zero dryfu
# mirror — polityka P49 lustrzana 1:1).
# ═══════════════════════════════════════════════════════════════════════════════
v3_p49 := {
    "v3_p49_threshold_version": "fail-closed-v3p49-2026.09",
    "legal_basis_version": "lb-failclosed-v3p49-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01: minimalna liczba invariantów runtime przed AUTO_POST (fail-closed pack)
    "v3_p49_invariants_min": 4,
    # I02: silent_auto_post_max = 0 — pojedynczy cichy AUTO_POST = BLOCK (AP07)
    "v3_p49_silent_auto_post_max": 0,
    # I03: minimalne pokrycie generatora brakujących pól (% reguł z testem braku)
    "v3_p49_field_coverage_min_pct": 95,
    # I04: minimalna liczba scenariuszy chaos input (mutacje z asercją fail-closed)
    "v3_p49_chaos_cases_min": 10,
    # I05: circuit breaker — próg NEEDS_ADVICE i okno (P37 radar; N w oknie T)
    "v3_p49_breaker_threshold": 20,
    "v3_p49_breaker_window_min": 60,
    # I06: limit kwotowy AUTO_POST (PLN; powyżej = MANUAL_REVIEW — 4-eyes)
    "v3_p49_auto_post_amount_limit": 15000,
    # I07: minimalna długość powodu NEEDS_ADVICE (fasada fail-closed = defekt)
    "v3_p49_min_reason_len": 20,
    # I10: cel jawnie fail-closed ścieżek reguł (%; trend w P37)
    "v3_p49_fail_closed_score_target_pct": 100,
    # I11: interwał canary cichego posta (godziny między probe'ami)
    "v3_p49_canary_interval_hours": 24,
    "no_auto_post": true,
    "manual_review_required": true,
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P50 DEAD CODE I DUPLIKATY — progi (ADR-002 parametry-as-data)
# Unikalność rule_id globalna, jedno źródło prawdy per zasada, detekcja
# duplikatów semantycznych (hash warunków), sprzeczności (BLOCKER), martwe
# narzędzia/dane/dokumenty-widma, mapa osiągalności, konsolidacja z ledgerem,
# celowe warianty jako overlaye, metryka burden. Honory kontrakty: P00 (kanon
# artefaktów), P48 (mapa dryfu = wspólny rejestr canonical↔mirror), P36
# (zapobieganie w generatorach), P02/P29 (routing + bramki), P41 (dokumentacja),
# P43 (DR: archiwum), P47 (kanon cytowań), P49 (fail-closed domknięcie).
# ═══════════════════════════════════════════════════════════════════════════════
v3_p50 := {
    "v3_p50_threshold_version": "dead-code-v3p50-2026.09",
    "legal_basis_version": "lb-deadcode-v3p50-2026.09",
    "valid_from": "2026-01-01",                                # okno temporalne (P05)
    # I01/I02: duplikaty semantyczne — maksimum dopuszczalne (0 = bez backlogu)
    "v3_p50_semantic_dup_max": 0,
    # I02: sprzeczne duplikaty — pojedynczy = BLOCK (decyzja losowa = ryzyko prawne)
    "v3_p50_contradiction_max": 0,
    # I03: kolizje rule_id — pojedyncza kolizja = BLOCK (tożsamość reguły)
    "v3_p50_ruleid_collision_max": 0,
    # I06: martwe dane data.* — maksimum (baseline jawny, trend → P37)
    "v3_p50_orphan_data_max": 50,
    # I07: dokumenty-widma (odwołania do nieistniejących plików) — maksimum
    "v3_p50_ghost_doc_max": 10,
    # I11: reguły nieosiągalne z routingu — maksimum (baseline po spisie)
    "v3_p50_unreachable_rules_max": 100,
    # I12: burden duplikatów (% reguł będących duplikatami) — cel 0%
    "v3_p50_duplicate_burden_target_pct": 0,
    # I05: okres archiwizacji martwych narzędzi (cykle CI bez sprzeciwu)
    "v3_p50_archive_cycles": 2,
    "no_auto_post": true,
    "manual_review_required": true,
}
