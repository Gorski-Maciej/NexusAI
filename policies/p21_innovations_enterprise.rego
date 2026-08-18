# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P21 Enterprise Innovations v7.0 (12 Innowacji Wyprzedzających)
# Raport: P21 JDG FX + TP + Residency + Payments v7.0, Sekcja 10
# Data: 2026-08-01
# Pakiet: jdg.p21_innovations
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.p21_innovations
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.p21_innovations.no_match","package":"jdg.p21_innovations","priority":99999}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 1: REAL-TIME FX MONITOR + AUTO-CALCULATOR (R2101-R2105)
# Automatyczny monitoring kursów NBP/EBC, kalkulacja różnic kursowych
# FIFO/średnia ważona, generowanie zestawień PKPiR/JPK_V7
# ═══════════════════════════════════════════════════════════════════════════════
decide := {"matched":true,"rule_id":"jdg.p21_innovations.fx_real_time_monitor","package":"jdg.p21_innovations","priority":2101,"_routing":"","_routing_reason":"INN1: FX Real-Time Monitor","_legal_basis":"Art. 14b PIT, Art. 31a VAT","_warnings":["FX Monitor: pobieraj kursy NBP codziennie po 12:00 z api.nbp.pl. Tabele A/B/C. Monitoruj zmiany >2%."]} {
    object.get(input.jdg_entrepreneur, "fx_monitor_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.fx_auto_calculator","package":"jdg.p21_innovations","priority":2102,"_routing":"","_routing_reason":"INN1: FX Auto-Calculator (FIFO + średnia ważona)","_legal_basis":"Art. 14b PIT","_warnings":["Kalkulator FX: automatyczne obliczanie różnic kursowych metodą FIFO i średnią ważoną."]} {
    object.get(input.jdg_entrepreneur, "fx_auto_calculator_enabled", false) == true
    object.get(input.invoice, "currency", "PLN") != "PLN"
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.fx_jpk_v7_integration","package":"jdg.p21_innovations","priority":2103,"_routing":"","_routing_reason":"INN1: FX -> JPK_V7 mapping","_legal_basis":"Art. 109 VAT","_warnings":["Mapowanie różnic kursowych do JPK_V7: dodatnie -> K_19, ujemne -> K_20."]} {
    object.get(input.jdg_entrepreneur, "fx_jpk_integration_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.fx_hedge_simulation","package":"jdg.p21_innovations","priority":2104,"_routing":"","_routing_reason":"INN1: Symulacja hedgingu","_legal_basis":"Art. 14 PIT","_warnings":["Symulator hedgingu: porównaj koszt forward/opcji z potencjalną stratą. Hedge zalecany przy ekspozycji >50k EUR i zmienności >5%."]} {
    object.get(input.jdg_entrepreneur, "fx_hedge_simulator_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.fx_monthly_report","package":"jdg.p21_innovations","priority":2105,"_routing":"","_routing_reason":"INN1: Raport miesięczny FX","_legal_basis":"Art. 24a PIT","_warnings":["Raport miesięczny FX: zestawienie wszystkich transakcji walutowych i różnic kursowych."]} {
    object.get(input.jdg_entrepreneur, "fx_monthly_report_due", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 2: TP DOCUMENTATION AUTO-GENERATOR (R2106-R2110)
# Generator dokumentacji lokalnej TP: analiza funkcjonalna, dobór metody,
# benchmark, wersjonowanie, terminy
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.tp_auto_local_file","package":"jdg.p21_innovations","priority":2106,"_routing":"TRIAGE_QUEUE","_routing_reason":"INN2: Auto-generator Local File TP","_legal_basis":"Art. 23zf PIT","_warnings":["Local File Auto-Generator: zbierz dane transakcyjne i wygeneruj 6 sekcji dokumentacji lokalnej."]} {
    object.get(input.tp, "local_file_required", false) == true
    object.get(input.tp, "auto_generation_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.tp_benchmark_integrator","package":"jdg.p21_innovations","priority":2107,"_routing":"TRIAGE_QUEUE","_routing_reason":"INN2: Integrator benchmarkingu TP","_legal_basis":"Art. 23zf ust. 7 PIT","_warnings":["Benchmark Integrator: pobierz dane z baz Amadeus/Orbis/Bloomberg. Oblicz rozstęp międzykwartylowy."]} {
    object.get(input.tp, "benchmarking_required", false) == true
    object.get(input.tp, "benchmark_api_integrated", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.tp_tpr_auto_filler","package":"jdg.p21_innovations","priority":2108,"_routing":"WARNING","_routing_reason":"INN2: Auto-wypełniacz TPR-C","_legal_basis":"Art. 23zh PIT","_warnings":["TPR-C Auto-Filler: automatycznie wypełnij formularz TPR-C na podstawie Local File."]} {
    object.get(input.tp, "tpr_obligation_exists", false) == true
    object.get(input.tp, "tpr_auto_fill_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.tp_deadline_calendar","package":"jdg.p21_innovations","priority":2109,"_routing":"WARNING","_routing_reason":"INN2: Kalendarz terminów TP","_legal_basis":"Art. 23zf, 23zh PIT","_warnings":["Kalendarz TP: Local File -> 30.04 (PIT) / 10 mies. (CIT). TPR -> 31.10 (PIT) / 30.11 (CIT). Benchmark co 3 lata."]} {
    object.get(input.tp, "tp_deadline_calendar_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.tp_document_versioning","package":"jdg.p21_innovations","priority":2110,"_routing":"","_routing_reason":"INN2: Wersjonowanie dokumentacji TP","_legal_basis":"Art. 86 OP","_warnings":["Wersjonowanie TP: każda aktualizacja Local File -> nowa wersja z datą. Przechowuj 5 lat."]} {
    object.get(input.tp, "tp_documentation_versioned", false) == false
    object.get(input.tp, "local_file_required", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 3: TAX RESIDENCY AUTO-DETERMINATOR (R2111-R2115)
# Samoocena rezydencji na podstawie danych o pobytach, powiązaniach
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.residency_auto_test","package":"jdg.p21_innovations","priority":2111,"_routing":"","_routing_reason":"INN3: Auto-test rezydencji (183 dni + centrum interesów)","_legal_basis":"Art. 3 ust. 1a PIT, OECD MTC Art. 4","_warnings":["Auto-Determinator Rezydencji: (1) Liczba dni w PL (2) Centrum interesów (3) Powiązania rodzinne (4) Źródła dochodu."]} {
    object.get(input.jdg_entrepreneur, "residency_auto_determinator_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.residency_upo_matcher","package":"jdg.p21_innovations","priority":2112,"_routing":"","_routing_reason":"INN3: Matcher UPO","_legal_basis":"Umowy bilateralne, Art. 27 PIT","_warnings":["UPO Matcher: automatycznie określ metodę unikania podwójnego opodatkowania dla danego kraju."]} {
    object.get(input.jdg_entrepreneur, "upo_matcher_enabled", false) == true
    object.get(input.jdg_entrepreneur, "has_foreign_income", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.residency_exit_tax_alert","package":"jdg.p21_innovations","priority":2113,"_routing":"BLOCK_AND_ALERT","_routing_reason":"INN3: Alert exit tax","_legal_basis":"Art. 30da PIT","_warnings":["EXIT TAX ALERT: Planujesz zmianę rezydencji? Próg: 4M PLN. Stawka: 19%. Raty: 5x20%. Termin: 7 miesięcy."]} {
    object.get(input.jdg_entrepreneur, "planning_residency_change", false) == true
    object.get(input.jdg_entrepreneur, "exit_tax_alert_acknowledged", false) == false
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.residency_cfr_tracker","package":"jdg.p21_innovations","priority":2114,"_routing":"WARNING","_routing_reason":"INN3: CFR Tracker","_legal_basis":"Art. 26 ust. 1 PIT","_warnings":["CFR Tracker: monitoruj daty ważności certyfikatów rezydencji kontrahentów. Alert 30 dni przed wygaśnięciem."]} {
    object.get(input.jdg_entrepreneur, "cfr_tracker_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.residency_risk_heatmap","package":"jdg.p21_innovations","priority":2115,"_routing":"TRIAGE_QUEUE","_routing_reason":"INN3: Heatmapa ryzyka rezydencji","_legal_basis":"Art. 3 PIT, OECD MTC","_warnings":["Mapa ryzyka: PE (czerwony), CFC (czerwony), Exit Tax >80% (żółty), CFR wygasający (żółty)."]} {
    object.get(input.jdg_entrepreneur, "residency_risk_heatmap_enabled", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 4: PAYMENT DEADLINE SMART TRACKER (R2116-R2120)
# Monitoring terminów płatności 14/30/60 dni, odsetki ustawowe
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.payment_deadline_monitor","package":"jdg.p21_innovations","priority":2116,"_routing":"","_routing_reason":"INN4: Monitor terminów płatności","_legal_basis":"Ustawa o przeciwdziałaniu nadmiernym opóźnieniom","_warnings":["Payment Tracker: śledź terminy płatności. Alerty: 3 dni przed, w dniu, 7/14/30/60 dni po terminie."]} {
    object.get(input.jdg_entrepreneur, "payment_tracker_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.payment_interest_calculator","package":"jdg.p21_innovations","priority":2117,"_routing":"","_routing_reason":"INN4: Kalkulator odsetek ustawowych","_legal_basis":"Art. 481 KC","_warnings":["Kalkulator odsetek: stopa ref. NBP + 8 p.p. (11.25% w 2025). Automatyczne naliczanie."]} {
    object.get(input.jdg_entrepreneur, "interest_calculator_enabled", false) == true
    object.get(input.invoice, "payment_overdue", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.payment_demand_letter","package":"jdg.p21_innovations","priority":2118,"_routing":"WARNING","_routing_reason":"INN4: Generator wezwań do zapłaty","_legal_basis":"Art. 481 KC","_warnings":["Generator wezwań: automatyczne wezwanie po 7 dniach opóźnienia. Zawiera kwotę główną, odsetki, rekompensatę 40 EUR."]} {
    object.get(input.invoice, "days_overdue", 0) > 7
    object.get(input.invoice, "demand_letter_sent", false) == false
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.payment_aging_report","package":"jdg.p21_innovations","priority":2119,"_routing":"BLOCK_AND_ALERT","_routing_reason":"INN4: Raport przeterminowań","_legal_basis":"-","_warnings":["Aging Report: 0-30 dni (zielony), 31-60 (żółty), 61-90 (pomarańczowy), >90 (czerwony)."]} {
    object.get(input.jdg_entrepreneur, "aging_report_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.payment_ksef_integration","package":"jdg.p21_innovations","priority":2120,"_routing":"","_routing_reason":"INN4: Integracja KSeF","_legal_basis":"Art. 106na VAT","_warnings":["Integracja KSeF: pobieraj faktury z KSeF i automatycznie dodawaj do trackera płatności."]} {
    object.get(input.jdg_entrepreneur, "ksef_payment_integration", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 5: ADVERTISING VS REPRESENTATION AI CLASSIFIER (R2121-R2125)
# NAPRAWA R-ADV-1: usunięcie limitu 0.025%
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.ad_classifier_nlp","package":"jdg.p21_innovations","priority":2121,"_routing":"","_routing_reason":"INN5: Klasyfikator reklama/reprezentacja","_legal_basis":"Art. 22 vs 23 PIT","_warnings":["AI Classifier: analizuj opis faktury. Produkt/usługa -> REKLAMA (KUP 100%). Gastronomia/alkohol/prestiż -> REPREZENTACJA (NKUP 100%)."]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.jdg_entrepreneur, "ad_ai_classifier_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.ad_representation_nkup_100","package":"jdg.p21_innovations","priority":2122,"_routing":"BLOCK_AND_ALERT","_routing_reason":"INN5: NAPRAWA R-ADV-1 - reprezentacja NKUP 100%","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["NAPRAWA R-ADV-1: Reprezentacja = NKUP w 100%! Nie istnieje limit 0.025%. Limit 0.25% został ZNIESIONY w 2018."]} {
    object.get(input.invoice, "expense_type", "") == "REPRESENTATION"
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.ad_gift_limit_tracker","package":"jdg.p21_innovations","priority":2123,"_routing":"WARNING","_routing_reason":"INN5: Tracker limitów prezentów","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT, Art. 88 ust. 1 pkt 5 VAT","_warnings":["Limit prezentów: PIT - 200 PLN z logo. VAT - odliczenie tylko do 100 PLN netto."]} {
    object.get(input.invoice, "expense_subtype", "") == "GIFT"
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.ad_sponsoring_limit_tracker","package":"jdg.p21_innovations","priority":2124,"_routing":"WARNING","_routing_reason":"INN5: Tracker limitu sponsoringu","_legal_basis":"Art. 26 PIT","_warnings":["Sponsoring bez kontrświadczeń = darowizna (limit 6% dochodu rocznie)."]} {
    object.get(input.invoice, "expense_subtype", "") == "SPONSORSHIP"
    object.get(input.invoice, "brand_exposure", false) == false
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.ad_audit_defense_report","package":"jdg.p21_innovations","priority":2125,"_routing":"","_routing_reason":"INN5: Raport dla kontroli","_legal_basis":"Art. 180 OP","_warnings":["Audit Defense: generuj raport z uzasadnieniem klasyfikacji reklama/reprezentacja."]} {
    object.get(input.jdg_entrepreneur, "ad_audit_report_needed", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 6: WHITE LIST AUTO-VERIFIER (R2126-R2128)
# NAPRAWA L-PAY-2: Zgłoszenie US w 3 dni
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.whitelist_api_verifier","package":"jdg.p21_innovations","priority":2126,"_routing":"WARNING","_routing_reason":"INN6: Auto-weryfikator białej listy (API MF)","_legal_basis":"Art. 96b ust. 1 VAT","_warnings":["White List Verifier: automatycznie sprawdź rachunek w API MF przed przelewem >15k PLN."]} {
    object.get(input.invoice, "amount_gross", 0) >= 15000
    object.get(input.vendor, "country", "PL") == "PL"
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.whitelist_us_notification_auto","package":"jdg.p21_innovations","priority":2127,"_routing":"BLOCK_AND_ALERT","_routing_reason":"INN6: Auto-zgłoszenie US (NAPRAWA L-PAY-2)","_legal_basis":"Art. 96b ust. 1 pkt 2 VAT, Art. 22p PIT, Art. 117ba OrdPU","_warnings":["NAPRAWA L-PAY-2: Auto-zgłoszenie do US w 3 dni. Generuj ZAW-NR. NKUP + odp. solidarna!"]} {
    object.get(input.invoice, "whitelist_account_ok", false) == false
    object.get(input.invoice, "whitelist_us_auto_notify", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.whitelist_verification_register","package":"jdg.p21_innovations","priority":2128,"_routing":"","_routing_reason":"INN6: Rejestr weryfikacji","_legal_basis":"Art. 96b VAT","_warnings":["Rejestr weryfikacji: zapisuj każdą weryfikację jako dowód należytej staranności."]} {
    object.get(input.jdg_entrepreneur, "whitelist_verification_log", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 7: PROCUREMENT TAX OPTIMIZER (R2129-R2131)
# NAPRAWA L-PROC-1: Progi PZP unijne/krajowe
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.procurement_pzp_thresholds","package":"jdg.p21_innovations","priority":2129,"_routing":"","_routing_reason":"INN7: Kalkulator progów PZP (NAPRAWA L-PROC-1)","_legal_basis":"Art. 2-3 PZP","_warnings":["NAPRAWA L-PROC-1: Progi PZP 2025 - unijny: dostawy/usługi 209k EUR, roboty 5538k EUR. Krajowy: 130k PLN netto."]} {
    object.get(input.document, "public_procurement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.procurement_rd_relief","package":"jdg.p21_innovations","priority":2130,"_routing":"","_routing_reason":"INN7: Ulga B+R w zamówieniach","_legal_basis":"Art. 26e PIT","_warnings":["Ulga B+R: 100% kosztów kwalifikowanych + dodatkowe odliczenie. Sprawdź czy projekt się kwalifikuje."]} {
    object.get(input.document, "public_procurement_active", false) == true
    object.get(input.document, "contains_rd_activities", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.procurement_offer_optimizer","package":"jdg.p21_innovations","priority":2131,"_routing":"","_routing_reason":"INN7: Optymalizator oferty","_legal_basis":"PZP","_warnings":["Optymalizator oferty: zaświadczenia, wadium, ulgi B+R/IP Box/prototyp, kalkulacja ceny."]} {
    object.get(input.document, "public_procurement_active", false) == true
    object.get(input.document, "offer_optimization_requested", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 8: FX HEDGE STRATEGY ADVISOR (R2132-R2134)
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.hedge_exposure_analyzer","package":"jdg.p21_innovations","priority":2132,"_routing":"WARNING","_routing_reason":"INN8: Analizator ekspozycji walutowej","_legal_basis":"Art. 14 PIT","_warnings":["Hedge Advisor: ekspozycja >50k EUR -> rozważ hedging. >200k EUR -> hedging zalecany."]} {
    object.get(input.jdg_entrepreneur, "hedge_advisor_enabled", false) == true
    object.get(input.jdg_entrepreneur, "total_fx_exposure_eur", 0) > 50000
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.hedge_cost_benefit","package":"jdg.p21_innovations","priority":2133,"_routing":"","_routing_reason":"INN8: Analiza koszt-korzyść","_legal_basis":"Art. 14 PIT","_warnings":["Koszt-Korzyść Hedge: jeśli koszt < 50% potencjalnej straty -> hedge opłacalny."]} {
    object.get(input.jdg_entrepreneur, "hedge_cost_benefit_analysis", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.hedge_documentation_auto","package":"jdg.p21_innovations","priority":2134,"_routing":"","_routing_reason":"INN8: Auto-dokumentacja hedgingu","_legal_basis":"Art. 14 PIT","_warnings":["Dokumentacja Hedge: generuj opis celu hedgingowego automatycznie."]} {
    object.get(input.jdg_entrepreneur, "hedge_documentation_auto", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 9: CROSS-BORDER PAYMENT TAX ANALYZER (R2135-R2137)
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.crossborder_wht_analyzer","package":"jdg.p21_innovations","priority":2135,"_routing":"WARNING","_routing_reason":"INN9: Analizator WHT","_legal_basis":"Art. 26 PIT, UPO","_warnings":["WHT Analyzer: stawka WHT wg UPO, CFR, zwolnienia dla płatności transgranicznych."]} {
    object.get(input.invoice, "cross_border_payment", false) == true
    object.get(input.invoice, "wht_applicable", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.crossborder_giif_tracker","package":"jdg.p21_innovations","priority":2136,"_routing":"TRIAGE_QUEUE","_routing_reason":"INN9: Tracker GIIF >15k EUR","_legal_basis":"Art. 72 AML","_warnings":["GIIF Tracker: przelew >15k EUR -> obowiązek raportu GIIF. Kara: do 20M PLN!"]} {
    object.get(input.invoice, "amount_eur", 0) >= 15000
    object.get(input.vendor, "country", "PL") != "PL"
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.crossborder_cfr_checker","package":"jdg.p21_innovations","priority":2137,"_routing":"WARNING","_routing_reason":"INN9: Weryfikator CFR","_legal_basis":"Art. 26 ust. 1 PIT","_warnings":["CFR Checker: dla preferencji WHT sprawdź ważność CFR kontrahenta (12 miesięcy)."]} {
    object.get(input.invoice, "cross_border_payment", false) == true
    object.get(input.vendor, "cfr_obtained", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 10: AD SPEND VS TAX DEDUCTION MAXIMIZER (R2138-R2140)
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.ad_spend_optimizer","package":"jdg.p21_innovations","priority":2138,"_routing":"","_routing_reason":"INN10: Optymalizator wydatków reklamowych","_legal_basis":"Art. 22 PIT","_warnings":["Ad Spend Optimizer: kieruj budżet na reklamę produktową (KUP 100%) zamiast reprezentacji (NKUP 100%)."]} {
    object.get(input.jdg_entrepreneur, "ad_optimizer_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.ad_structure_simulator","package":"jdg.p21_innovations","priority":2139,"_routing":"","_routing_reason":"INN10: Symulator struktury wydatków","_legal_basis":"Art. 22, 23, 26 PIT","_warnings":["Symulator: Reklama=KUP 100%, Sponsoring z logo=KUP 100%, Sponsoring bez logo=darowizna 6%, Reprezentacja=NKUP 100%."]} {
    object.get(input.jdg_entrepreneur, "ad_structure_simulator", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.ad_annual_tax_report","package":"jdg.p21_innovations","priority":2140,"_routing":"","_routing_reason":"INN10: Raport roczny dla PIT","_legal_basis":"Art. 22-23 PIT","_warnings":["Raport roczny: suma KUP, NKUP, darowizn, prezentów z limitami. Gotowe do PIT-36."]} {
    object.get(input.jdg_entrepreneur, "ad_annual_report_due", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 11: SPLIT PAYMENT GUARDIAN (R2141-R2143)
# NAPRAWA L-PAY-3
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.split_sensitive_goods_db","package":"jdg.p21_innovations","priority":2141,"_routing":"BLOCK_AND_ALERT","_routing_reason":"INN11: Baza towarów wrażliwych (NAPRAWA L-PAY-3)","_legal_basis":"Art. 108b VAT, załącznik 15","_warnings":["NAPRAWA L-PAY-3: Towary wrażliwe >15k PLN brutto -> OBOWIĄZKOWY SPLIT PAYMENT! Paliwa, stal, elektronika, części."]} {
    object.get(input.invoice, "sensitive_goods_annex15", false) == true
    object.get(input.invoice, "amount_gross", 0) >= 15000
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.split_bank_integration","package":"jdg.p21_innovations","priority":2142,"_routing":"","_routing_reason":"INN11: Integracja bankowa MPP","_legal_basis":"Art. 108a ust. 3 VAT","_warnings":["Split Bank Integration: auto-generuj komunikat przelewu z nr faktury, NIP, kwotą VAT."]} {
    object.get(input.invoice, "split_payment_used", false) == true
    object.get(input.jdg_entrepreneur, "split_bank_integrated", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.split_sanction_monitor","package":"jdg.p21_innovations","priority":2143,"_routing":"BLOCK_AND_ALERT","_routing_reason":"INN11: Monitor sankcji MPP","_legal_basis":"Art. 108h VAT, Art. 22p PIT","_warnings":["Split Sanction: alert przy próbie standardowego przelewu dla towarów wrażliwych. Sankcje: 30% VAT + NKUP!"]} {
    object.get(input.invoice, "sensitive_goods_annex15", false) == true
    object.get(input.invoice, "split_payment_skipped", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# INNOWACJA 12: SPECIAL SITUATION DECISION TREE (R2144-R2148)
# ═══════════════════════════════════════════════════════════════════════════════
else := {"matched":true,"rule_id":"jdg.p21_innovations.special_situation_triage","package":"jdg.p21_innovations","priority":2144,"_routing":"TRIAGE_QUEUE","_routing_reason":"INN12: Triage zdarzeń specjalnych","_legal_basis":"PIT, VAT, OrdPU, OECD MTC","_warnings":["SPECIAL SITUATION: Wykryto zdarzenie specjalne. Uruchamiam pełną analizę P21."]} {
    object.get(input.jdg_entrepreneur, "special_situation_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.special_situation_mapper","package":"jdg.p21_innovations","priority":2145,"_routing":"TRIAGE_QUEUE","_routing_reason":"INN12: Mapowanie do reguł P21","_legal_basis":"P21 moduły","_warnings":["Mapa: Exit Tax -> R1491-1495, CFC -> R1506-1510, PE -> R1501-1505, Split -> R1674-1678."]} {
    object.get(input.jdg_entrepreneur, "special_situation_mapping_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.special_situation_aggregator","package":"jdg.p21_innovations","priority":2146,"_routing":"","_routing_reason":"INN12: Agregacja rekomendacji","_legal_basis":"PIT, OP","_warnings":["Agregacja P21: zbierz wszystkie rekomendacje. Priorytety: BLOCK > TRIAGE > WARNING."]} {
    object.get(input.jdg_entrepreneur, "p21_aggregation_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.special_situation_risk_map","package":"jdg.p21_innovations","priority":2147,"_routing":"","_routing_reason":"INN12: Mapa ryzyka","_legal_basis":"PIT, OrdPU","_warnings":["Risk Map: Exit Tax >80% (żółty), CFC (czerwony), Split pominięty (czerwony), NKUP błędnie (czerwony)."]} {
    object.get(input.jdg_entrepreneur, "special_situation_risk_map_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.p21_innovations.special_situation_calendar","package":"jdg.p21_innovations","priority":2148,"_routing":"","_routing_reason":"INN12: Kalendarz obowiązków","_legal_basis":"PIT, VAT, OP, OrdPU","_warnings":["Kalendarz: TPR(31.10), Local File(30.04), Exit Tax(7m), Split(per faktura), Biała Lista(3d), CFR(12m)."]} {
    object.get(input.jdg_entrepreneur, "special_situation_calendar_needed", false) == true
}
