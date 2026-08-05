# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — VAT: Stawki, zwolnienia, GTU (P50-P65)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: VAT Substantive — Rates, Exemptions, GTU Codes
# description: |
#   PAS 4a Multi-Pass. First-Match-Wins else-chain. Stawki VAT wg kategorii:
#   23% standard (P52/P67), 8% obniżona (P64), 5% żywność/książki (P53/P54/P66),
#   0% zwolnienia przedmiotowe: edukacja (P55), medycyna (P56), finanse (P57),
#   podmiotowe 200k (P58/P59), kultura (P61), nieruchomości (P62), poczta (P63).
#   Mapowanie GTU 13 kodów (P65), ulga złe długi VAT (P60).
# architecture: Multi-Pass PAS 4a (ADR-001)
# legal_basis: Art. 41-43, 89a, 113, 120 VAT
# edge_cases:
#   - P58: zwolnienie podmiotowe tylko gdy !is_vat_payer AND turnover < 200k
#   - P60: bad_debt_creditor wymaga >90 dni (SLIM VAT 3/2023) + debtor_notified
#   - P67: standard 23% = catch-all dla PL
# package: jdg.vat.substantive
# deprecated: false
#
#
# Architektura: First-Match-Wins else-chain
# Wzorzec mapowania: category_code → vat_rate + gtu_code
# Podstawa: Doc 34 Sec 4.5 + Doc 33 (dekompozycja art. 41-43 VAT)
#
# package: jdg.vat.substantive
#

package jdg.vat.substantive

import future.keywords.in
import data.jdg.helpers
import data.jdg.thresholds

# ── Default: no matching VAT rate rule ──────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.vat.substantive.no_match",
    "package": "jdg.vat.substantive",
    "priority": 75
}

# ═══════════════════════════════════════════════════════════════════════════════
# V.01: Art. 5 ust. 1 pkt 1 VAT — Dostawa towarów za wynagrodzeniem w PL
# Fundamentalna definicja: dostawa towarów za wynagrodzeniem na terytorium
# kraju → podlega VAT. Używamy category_code (nie expense_type) dla spójności.
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.vat.substantive.goods_delivery_taxable",
    "package": "jdg.vat.substantive", "priority": 5,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "vat_taxable": true, "vat_transaction_type": "GOODS_DELIVERY",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 5 ust. 1 pkt 1 VAT",
    "_warnings": []
} {
    input.invoice.direction == "SALE"
    input.invoice.category_code in {"GOODS", "MERCHANDISE", "PRODUCTS", "RAW_MATERIALS"}
    input.invoice.amount_net > 0
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# V.02: Art. 17 ust. 1 pkt 5 VAT — WNT odwrotne obciążenie dla nabywcy
# WNT: nabywca rozlicza VAT (23% należny + naliczony), faktura od dostawcy BEZ VAT.
# Warunek: PURCHASE, vendor w UE (nie PL), towary, zarejestrowany VAT-UE.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.wnt_reverse_charge_buyer",
    "package": "jdg.vat.substantive", "priority": 7,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "position", "gtu_code": "",
    "procedure": "WNT_REVERSE_CHARGE",
    "vat_exemption": "", "vat_mechanism": "REVERSE_CHARGE",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 5 VAT",
    "_warnings": [sprintf("WNT REVERSE CHARGE — nabycie towarów z %s. VAT rozlicza nabywca (23%% należny + naliczony). Faktura od dostawcy BEZ VAT. JPK_V7: pole K_41.", [vendor_country])]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.country in eu_countries
    input.vendor.country != "PL"
    input.invoice.category_code in {"GOODS", "MERCHANDISE", "RAW_MATERIALS"}
    input.jdg_entrepreneur.is_vat_eu_registered == true
    vendor_country := input.vendor.country
}

# ═══════════════════════════════════════════════════════════════════════════════
# P50: vat_margin_scheme — Procedura VAT-marża
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.margin_scheme",
    "package": "jdg.vat.substantive", "priority": 50,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "total",
    "gtu_code": "", "procedure": "MARGIN",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 120 ustawy o VAT",
    "_warnings": ["Procedura VAT-marża — podstawa = marża, nie cała kwota"]
} {
    input.invoice.procedure == "MARGIN"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P51: vat_exemption_subject_jdg — Zwolnienie podmiotowe JDG (200k limit) ★★★ v7.0 FIX: przed stawkami
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.subject_exemption_jdg",
    "package": "jdg.vat.substantive", "priority": 51,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "SUBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 113 ust. 1 i 9 VAT",
    "_warnings": ["Zwolnienie podmiotowe VAT — limit 200 000 PLN rocznie"]
} {
    input.jdg_entrepreneur.is_vat_payer == false
    # R03 P1: limit z data.thresholds (jedno źródło prawdy, temporalnie — 200 000 PLN od 2017)
    input.jdg_entrepreneur.annual_turnover_net < thresholds.vat.subject_exemption_limit
}

# ═══════════════════════════════════════════════════════════════════════════════
# P51b: subject_exemption_startup_proportion — Proporcja dla nowych JDG
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.startup_proportion",
    "package": "jdg.vat.substantive", "priority": 51,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "SUBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 113 ust. 9 VAT",
    "_warnings": ["Nowa JDG — limit zwolnienia proporcjonalny do okresu prowadzenia dzialalnosci"]
} {
    input.jdg_entrepreneur.is_vat_payer == false
    input.jdg_entrepreneur.ceidg_entry_date != null
    # R03 P1: limit z data.thresholds (art. 113 ust. 9 VAT — proporcja dla nowych JDG)
    input.jdg_entrepreneur.annual_turnover_net < thresholds.vat.subject_exemption_limit
}

# ═══════════════════════════════════════════════════════════════════════════════
# P52: vat_rate_fuel_pl — Paliwo → 23% + GTU_02 (v7.0 ADR-002: thresholds.vat.standard_rate)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.fuel_pl",
    "package": "jdg.vat.substantive", "priority": 52,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "position",
    "gtu_code": "GTU_02", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 1 VAT",
    "_warnings": []
} {
    input.invoice.category_code == "FUEL"
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P53: vat_rate_food_pl — Żywność → 5% + GTU_07
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.food_pl",
    "package": "jdg.vat.substantive", "priority": 53,
    "vat_rate": sprintf("%.2f", [thresholds.vat.reduced_rate_5]), "rounding_level": "position",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2a VAT",
    "_warnings": []
} {
    input.invoice.category_code in {"FOOD", "GROCERIES", "FOOD_BASIC"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P66: vat_np_not_subject — Transakcja nie podlega VAT (NP / out of scope)
# v7.0 FIX P02-Ś9: Wcześniej transakcje NP trafiały do catch-all P67 23% —
# ciche zastosowanie 23% do transakcji niepodlegającej VAT. Teraz jawnie NP.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.np_not_subject",
    "package": "jdg.vat.substantive", "priority": 66,
    "vat_rate": "NP", "rounding_level": "total",
    "gtu_code": "", "procedure": "NP_NOT_SUBJECT",
    "vat_exemption": "OUT_OF_SCOPE", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_not_subject": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Transakcja nie podlega VAT (NP) — out of scope. Zweryfikuj poprawność klasyfikacji.",
    "_legal_basis": "Art. 5-6 VAT (poza zakresem opodatkowania)",
    "_warnings": ["TRANSAKCJA NP — nie podlega VAT. Upewnij się że klasyfikacja NP jest prawidłowa. Błędne oznaczenie NP może skutkować zaległością VAT."]
} {
    input.invoice.vat_rate == "NP"
}

# ══ P67: vat_books_5pct_validation — Książki/e-booki 5% (Doc 42: walidacja CN) ══
else := {
    "matched":true,"rule_id":"jdg.vat.substantive.books_5pct_validation",
    "package":"jdg.vat.substantive","priority":67,    "vat_rate": sprintf("%.2f", [thresholds.vat.reduced_rate_5]), "rounding_level": "position",
    "gtu_code": "GTU_01", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "books_5pct_valid": true, "books_cn_validated": true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Rozp. MF z 4.12.2024 r., Załącznik nr 2 + Art. 41 ust. 2a VAT",
    "_warnings":["Książka/e-book 5% VAT — ISBN/digital ID potwierdzony. Wyłączenia: podręczniki akademickie (0%), treści dla dorosłych (23%)"]
} {
    input.invoice.category_code in {"BOOKS","EBOOKS","AUDIOBOOKS"}
    input.vendor.country == "PL"
    input.invoice.has_isbn_or_digital_id == true
    not input.invoice.is_academic_textbook
    not input.invoice.is_adult_content
}

# ═══════════════════════════════════════════════════════════════════════════════
# P54: vat_rate_books — Książki → 5%
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.books_pl",
    "package": "jdg.vat.substantive", "priority": 54,
    "vat_rate": sprintf("%.2f", [thresholds.vat.reduced_rate_5]), "rounding_level": "position",
    "gtu_code": "GTU_01", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2a VAT",
    "_warnings": []
} {
    input.invoice.category_code in {"BOOKS", "EBOOKS", "AUDIOBOOKS"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P55: vat_exemption_education — Edukacja → zwolniona
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.education_exempt",
    "package": "jdg.vat.substantive", "priority": 55,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 26-29 VAT",
    "_warnings": ["Usługi edukacyjne zwolnione z VAT"]
} {
    input.invoice.category_code in {"EDUCATION", "TRAINING", "TUTORING"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P56: vat_exemption_healthcare — Medycyna → zwolniona
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.healthcare_exempt",
    "package": "jdg.vat.substantive", "priority": 56,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 18-20 VAT",
    "_warnings": ["Usługi medyczne zwolnione z VAT"]
} {
    input.invoice.category_code in {"HEALTHCARE", "MEDICAL", "DENTAL", "PHYSIOTHERAPY"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P57: vat_exemption_financial — Finanse/ubezpieczenia → zwolnione
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.financial_exempt",
    "package": "jdg.vat.substantive", "priority": 57,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 7, 37-38 VAT",
    "_warnings": ["Usługi finansowe/ubezpieczeniowe zwolnione z VAT"]
} {
    input.invoice.category_code in {"FINANCIAL", "INSURANCE", "BANKING", "LOAN"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P58-P59: [v7.0 FIX — przesuniete do P51/P51b przed stawkami]
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# P60: vat_bad_debt_relief — Ulga na złe długi VAT (wierzyciel)
# P60_TEMPORAL_FIX: 150 dni przed SLIM VAT 3 (przed 2023-01-01),
# 90 dni od 2023-01-01 (SLIM VAT 3 zmiana Art. 89a ust. 1a VAT)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.bad_debt_relief_creditor_150d",
    "package": "jdg.vat.substantive", "priority": 60,
    "vat_rate": "", "rounding_level": "",
    "gtu_code": "", "procedure": "BAD_DEBT_RELIEF_CREDITOR_150D",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "temporal_version": "PRE_SLIM_VAT_3", "bad_debt_threshold_days": 150,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 89a VAT (brzmienie przed SLIM VAT 3, obowiązujące do 2022-12-31)",
    "_warnings": [sprintf("Ulga na złe długi VAT (PRZED SLIM VAT 3) — korekta po 150 dniach od terminu płatności. Transakcja: %s", [tx_date])]
} {
    input.invoice.is_paid == false
    tx_date := object.get(input.invoice, "transaction_date", "")
    tx_date < "2023-01-01"
    input.invoice.days_overdue >= 150
    input.invoice.direction == "SALE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P60c: vat_bad_debt_bankruptcy_immediate — Ulga natychmiastowa przy upadłości (MR-4 v7.0)
# Art. 89a ust. 2a VAT: wierzyciel może skorygować VAT natychmiast po
# powzięciu wiadomości o upadłości dłużnika — NIE musi czekać 90/150 dni.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.bad_debt_bankruptcy_immediate",
    "package": "jdg.vat.substantive", "priority": 60,
    "vat_rate": "", "rounding_level": "",
    "gtu_code": "", "procedure": "BAD_DEBT_BANKRUPTCY_IMMEDIATE",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "temporal_version": "BANKRUPTCY_IMMEDIATE", "bad_debt_threshold_days": 0,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 89a ust. 2a VAT — upadłość dłużnika",
    "_warnings": [sprintf("UPADŁOŚĆ DŁUŻNIKA — ulga na złe długi VAT NATYCHMIAST po powzięciu wiadomości. NIE musisz czekać 90/150 dni. Data upadłości: %s. Skoryguj VAT w bieżącym JPK_V7.", [bankruptcy_date])]
} {
    input.invoice.is_paid == false
    input.invoice.direction == "SALE"
    input.invoice.debtor_in_bankruptcy == true
    bankruptcy_date := object.get(input.invoice, "debtor_bankruptcy_date", "")
}

# P60b: vat_bad_debt_relief_90d_post_slim3 — Ulga na złe długi VAT (wierzyciel) PO SLIM VAT 3
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.bad_debt_relief_creditor_90d",
    "package": "jdg.vat.substantive", "priority": 60,
    "vat_rate": "", "rounding_level": "",
    "gtu_code": "", "procedure": "BAD_DEBT_RELIEF_CREDITOR_90D",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "temporal_version": "POST_SLIM_VAT_3", "bad_debt_threshold_days": 90,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 89a ust. 1a VAT (SLIM VAT 3, od 2023-01-01)",
    "_warnings": ["Ulga na złe długi VAT (PO SLIM VAT 3) — korekta po 90 dniach od terminu płatności"]
} {
    input.invoice.is_paid == false
    tx_date := object.get(input.invoice, "transaction_date", "")
    tx_date >= "2023-01-01"
    input.invoice.days_overdue >= 90
    input.invoice.direction == "SALE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P61: vat_exemption_culture — Kultura/sport → zwolnione
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.culture_exempt",
    "package": "jdg.vat.substantive", "priority": 61,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 32-33 VAT",
    "_warnings": ["Usługi kulturalne/sportowe zwolnione z VAT"]
} {
    input.invoice.category_code in {"CULTURE", "SPORT", "MUSEUM", "LIBRARY"}
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P62: vat_exemption_real_estate — Nieruchomości → zwolnione (po pierwszym zasiedleniu)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.real_estate_exempt",
    "package": "jdg.vat.substantive", "priority": 62,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 10 VAT",
    "_warnings": ["Dostawa nieruchomości po pierwszym zasiedleniu — zwolniona z VAT"]
} {
    input.invoice.category_code in {"REAL_ESTATE", "BUILDING_SALE"}
    input.invoice.is_first_occupancy == false
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P63: vat_exemption_postal — Usługi pocztowe → zwolnione
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.postal_exempt",
    "package": "jdg.vat.substantive", "priority": 63,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 pkt 17 VAT",
    "_warnings": []
} {
    input.invoice.category_code == "POSTAL"
    input.vendor.country == "PL"
}

# ══ P68: vat_construction_8pct_validation — Budownictwo mieszkaniowe 8% ══
else := {
    "matched":true,"rule_id":"jdg.vat.substantive.construction_8pct_validation",
    "package":"jdg.vat.substantive","priority":68,    "vat_rate": sprintf("%.2f", [thresholds.vat.reduced_rate_8]), "rounding_level": "position",
    "gtu_code": "GTU_08", "procedure": "",
    "vat_exemption": "","pit_form":"","pit_rate":"",
    "pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "construction_rate_valid":true,"construction_area_exceeded":false,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 41 ust. 12-12c VAT + Rozp. MF z 4.12.2024 r.",
    "_warnings":["Budownictwo mieszkaniowe 8% VAT — domy ≤300 m², mieszkania ≤150 m². Garaże wolnostojące/lokale użytkowe = 23%"]
} {
    input.invoice.category_code == "CONSTRUCTION_RESIDENTIAL"
    input.invoice.building_type in {"RESIDENTIAL_HOUSE","RESIDENTIAL_FLAT","SOCIAL_HOUSING"}
    input.vendor.country == "PL"
    area := object.get(input.invoice,"building_area_m2",0)
    not (input.invoice.building_type == "RESIDENTIAL_HOUSE" and area > 300)
    not (input.invoice.building_type == "RESIDENTIAL_FLAT" and area > 150)
}

# ══ P70: vat_medical_equipment_8pct_validation — Sprzęt medyczny 8% ══
else := {
    "matched":true,"rule_id":"jdg.vat.substantive.medical_equipment_8pct_validation",
    "package":"jdg.vat.substantive","priority":70,    "vat_rate": sprintf("%.2f", [thresholds.vat.reduced_rate_8]), "rounding_level": "position",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "medical_device_valid": true, "medical_ce_marked": true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Rozp. MF z 4.12.2024 r., Załącznik nr 1, poz. 87-105",
    "_warnings":["Sprzęt medyczny 8% VAT — certyfikat CE + zgłoszenie URPL. Wyłączenie: fitness/wellness (23%), używany (procedura marży)"]
} {
    input.invoice.category_code == "MEDICAL_EQUIPMENT"
    input.invoice.is_medical_device == true
    input.invoice.has_ce_marking == true
    input.vendor.country == "PL"
    not input.invoice.is_used_goods
}

# ═══════════════════════════════════════════════════════════════════════════════
# P64: vat_rate_8pct — Stawka obniżona 8% (budownictwo mieszkaniowe, hotele, transport)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.rate_8pct",
    "package": "jdg.vat.substantive", "priority": 64,
    "vat_rate": sprintf("%.2f", [thresholds.vat.reduced_rate_8]), "rounding_level": "position",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2 VAT w zw. z załącznikiem nr 3",
    "_warnings": []
} {
    input.invoice.category_code in {
        "CONSTRUCTION_RESIDENTIAL", "HOTEL", "TRANSPORT_PASSENGER",
        "PHARMACEUTICALS", "MEDICAL_EQUIPMENT", "RESTAURANT_CATERING",
        "WATER_SUPPLY", "WASTE_COLLECTION"
    }
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P65: gtu_mapping_by_category — Mapowanie GTU z Semantic Auto-Assigner (v7.0 MR-3)
# Pierwszeństwo: GTU z bridge'a (gtu_auto_assigner.py) → category_code fallback
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.gtu_mapping",
    "package": "jdg.vat.substantive", "priority": 65,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "position",
    "gtu_code": gtu_code, "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "gtu_method": gtu_method,
    "gtu_confidence": gtu_confidence,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "§ 10 rozporządzenia JPK_VAT",
    "_warnings": []
} {
    input.vendor.country == "PL"
    # v7.0: Pierwszeństwo dla GTU z bridge'a
    bridge_gtu := object.get(input.invoice, "gtu_code", "")
    bridge_confidence := object.get(input.invoice, "gtu_confidence", 0.0)

    gtu_code := bridge_gtu {
        bridge_gtu != ""
        bridge_confidence >= 0.40
    }

    gtu_code := gtu_map[input.invoice.category_code] {
        bridge_gtu == ""
    }

    gtu_code := gtu_map[input.invoice.category_code] {
        bridge_confidence < 0.40
    }

    gtu_code != ""
    gtu_method = "semantic" { bridge_gtu != ""; bridge_confidence >= 0.40 }
    gtu_method = "category" { bridge_gtu == "" }
    gtu_method = "fallback" { bridge_confidence < 0.40 }

    gtu_confidence := bridge_confidence { bridge_confidence > 0 }
    gtu_confidence := 0.65 { bridge_confidence == 0 }

    routing = "" { bridge_confidence >= 0.70 }
    routing = "" { bridge_confidence == 0 }
    routing = "TRIAGE_QUEUE" { bridge_confidence < 0.70; bridge_confidence > 0 }
    routing_reason = "GTU confidence low — manual review recommended" { bridge_confidence < 0.70; bridge_confidence > 0 }
    routing_reason = "" { bridge_confidence >= 0.70 }
    routing_reason = "" { bridge_confidence == 0 }
}

# ── GTU Map (13 kodów JPK_V7M) ────────────────────────────────────────────────
gtu_map := {
    "ALCOHOL": "GTU_01",
    "BEVERAGES_ALCOHOLIC": "GTU_01",
    "TOBACCO": "GTU_04",
    "FUEL": "GTU_02",
    "FUEL_HEATING": "GTU_02",
    "OIL_LUBRICANTS": "GTU_05",
    "MEDICAL_PRODUCTS": "GTU_06",
    "USED_VEHICLES": "GTU_03",
    "USED_TRANSPORT": "GTU_03",
    "WASTE": "GTU_07",
    "ELECTRONICS": "GTU_08",
    "VEHICLES": "GTU_09",
    "STEEL": "GTU_10",
    "PRECIOUS_METALS": "GTU_11",
    "CONSTRUCTION": "GTU_12",
    "TRANSPORT_SERVICES": "GTU_13"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P70-P79: Reverse Charge (odwrotne obciążenie) — Art. 17 VAT
# ═══════════════════════════════════════════════════════════════════════════════

# P70: reverse_charge_domestic_goods — Krajowe odwrotne obciążenie (towary wrażliwe)
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.reverse_charge_domestic_goods",
    "package": "jdg.vat.substantive", "priority": 70,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "REVERSE_CHARGE_DOMESTIC",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 7 VAT",
    "_warnings": [sprintf("ODWROTNE OBCIĄŻENIE — towary wrażliwe (%s). VAT rozlicza nabywca. Faktura BEZ VAT, oznaczenie 'odwrotne obciążenie'.", [goods_desc])]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.country == "PL"
    input.invoice.category_code in {"STEEL", "FUEL", "ELECTRONICS_SCRAP", "GOLD_RAW"}
    input.vendor.is_vat_active == true
    goods_desc := input.invoice.category_code
    input.invoice.reverse_charge_applies == true
}

# P71: reverse_charge_construction — Odwrotne obciążenie — usługi budowlane
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.reverse_charge_construction",
    "package": "jdg.vat.substantive", "priority": 71,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "REVERSE_CHARGE_CONSTRUCTION",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 8 VAT",
    "_warnings": ["ODWROTNE OBCIĄŻENIE — usługi budowlane. VAT rozlicza nabywca (podwykonawca → generalny wykonawca)."]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code == "CONSTRUCTION_SUBCONTRACTING"
    input.vendor.country == "PL"
    input.invoice.reverse_charge_applies == true
}

# P72: reverse_charge_waste — Odwrotne obciążenie — odpady
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.reverse_charge_waste",
    "package": "jdg.vat.substantive", "priority": 72,
    "vat_rate": "", "rounding_level": "", "gtu_code": "GTU_07",
    "procedure": "REVERSE_CHARGE_WASTE",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 7 VAT",
    "_warnings": ["ODWROTNE OBCIĄŻENIE — odpady i surowce wtórne. VAT rozlicza nabywca."]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {"WASTE", "SCRAP_METAL", "RECYCLABLES"}
    input.invoice.amount_net > 20000
}

# P73: reverse_charge_certificates — Odwrotne obciążenie — certyfikaty CO2
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.reverse_charge_certificates",
    "package": "jdg.vat.substantive", "priority": 73,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "REVERSE_CHARGE_CO2",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 7 VAT",
    "_warnings": ["ODWROTNE OBCIĄŻENIE — certyfikaty emisyjne CO2. VAT rozlicza nabywca."]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code in {"CO2_CERTIFICATES", "GREEN_CERTIFICATES"}
}

# P74: reverse_charge_electronics_gold — Odwrotne obciążenie — metale szlachetne i półprodukty
# UWAGA: Od 01.11.2019 elektronika (laptopy, tablety, telefony) NIE podlega już odwrotnemu obciążeniu.
# Obecnie odwrotne obciążenie obejmuje: stal, paliwa, złoto nieobrobione, odpady,
# certyfikaty CO2, usługi budowlane (podwykonawstwo).
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.reverse_charge_precious_metals",
    "package": "jdg.vat.substantive", "priority": 74,
    "vat_rate": "", "rounding_level": "", "gtu_code": "GTU_11",
    "procedure": "REVERSE_CHARGE_METALS",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 17 ust. 1 pkt 7 VAT (załącznik nr 11)",
    "_warnings": ["ODWROTNE OBCIĄŻENIE — metale szlachetne i nieobrobione złoto. VAT rozlicza nabywca."]
} {
    input.invoice.category_code in {"GOLD_RAW", "SILVER_RAW", "PLATINUM_RAW"}
    input.vendor.country == "PL"
    input.vendor.is_vat_active == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P80-P89: WNT — Wewnątrzwspólnotowe Nabycie Towarów (Art. 9-11 VAT)
# ═══════════════════════════════════════════════════════════════════════════════

# P80: wnt_goods_from_eu — WNT z UE (standard)
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.wnt_goods_from_eu",
    "package": "jdg.vat.substantive", "priority": 80,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "position", "gtu_code": "",
    "procedure": "WNT",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 9 ust. 1-2 VAT",
    "_warnings": [sprintf("WNT — nabycie towarów z %s. VAT należny 23%% + VAT naliczony (odliczenie w tym samym okresie). JPK_V7: pole 'K_41'.", [vendor_country])]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.country != "PL"
    input.vendor.country in eu_countries
    input.invoice.procedure in {"WNT", "INTRA_EU_PURCHASE"}
    input.jdg_entrepreneur.is_vat_eu_registered == true
    vendor_country := input.vendor.country
}

# P81: wnt_new_vehicle — WNT nowy środek transportu
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.wnt_new_vehicle",
    "package": "jdg.vat.substantive", "priority": 81,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "position", "gtu_code": "GTU_09",
    "procedure": "WNT_NEW_VEHICLE",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 9 ust. 2 pkt 1 VAT",
    "_warnings": ["WNT NOWY ŚRODEK TRANSPORTU — obowiązek VAT-23 + akcyza (jeśli dotyczy). Rejestracja w wydziale komunikacji dopiero po VAT-25."]
} {
    input.invoice.category_code in {"CAR_NEW", "MOTORCYCLE_NEW", "BOAT_NEW"}
    input.vendor.country in eu_countries
    input.invoice.direction == "PURCHASE"
}

# P82: wnt_excise_goods — WNT wyroby akcyzowe
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.wnt_excise_goods",
    "package": "jdg.vat.substantive", "priority": 82,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "position", "gtu_code": "GTU_01",
    "procedure": "WNT_EXCISE",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 9 ust. 1 VAT, Art. 99 ust. 3 VAT",
    "_warnings": ["WNT WYROBY AKCYZOWE — dodatkowe obowiązki: AKC-4, zabezpieczenie akcyzowe. VAT-UE w terminie."]
} {
    input.invoice.category_code in {"ALCOHOL", "TOBACCO", "FUEL"}
    input.vendor.country in eu_countries
    input.invoice.direction == "PURCHASE"
}

# P83: wnt_triangular_simplification — Transakcja trójstronna uproszczona
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.wnt_triangular_simplification",
    "package": "jdg.vat.substantive", "priority": 83,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "TRIANGULAR_SIMPLIFICATION",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 135-138 VAT",
    "_warnings": ["TRANSAKCJA TRÓJSTRONNA — uproszczenie: drugi podmiot nie rozlicza WNT/WDT. VAT rozlicza ostatni nabywca."]
} {
    input.invoice.procedure == "TRIANGULAR"
    input.invoice.triangular_simplification == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P90-P99: Import usług (Art. 28b VAT) + Import towarów
# ═══════════════════════════════════════════════════════════════════════════════

# P90: import_of_services_b2b — Import usług B2B (Art. 28b VAT)
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.import_of_services_b2b",
    "package": "jdg.vat.substantive", "priority": 90,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "position", "gtu_code": "",
    "procedure": "IMPORT_OF_SERVICES",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28b VAT",
    "_warnings": [sprintf("IMPORT USŁUG — miejsce świadczenia: Polska (Art. 28b). VAT należny 23%% + VAT naliczony w JPK_V7: pola K_43 (import usług z UE) lub K_44 (import usług spoza UE).", [])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.expense_type in {"SERVICE", "CONSULTING", "IT_SERVICES", "SOFTWARE_LICENSE", "SAAS"}
    input.vendor.country != "PL"
    input.invoice.place_of_supply == "PL"
    input.jdg_entrepreneur.is_vat_payer == true
}

# P91: import_of_services_eu — Import usług z UE (JPK_V7 K_43)
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.import_of_services_eu",
    "package": "jdg.vat.substantive", "priority": 91,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "position", "gtu_code": "",
    "procedure": "IMPORT_SERVICES_EU",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_v7_tag": "K_43",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28b VAT",
    "_warnings": ["IMPORT USŁUG Z UE — JPK_V7 pole K_43. Odliczenie VAT naliczonego w tym samym okresie (jeśli związek z czynnościami opodatkowanymi)."]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.country in eu_countries
    input.invoice.place_of_supply == "PL"
    input.invoice.expense_type in {"SERVICE", "CONSULTING", "IT_SERVICES", "SOFTWARE_LICENSE"}
}

# P92: import_of_services_non_eu — Import usług spoza UE (JPK_V7 K_44)
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.import_of_services_non_eu",
    "package": "jdg.vat.substantive", "priority": 92,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "position", "gtu_code": "",
    "procedure": "IMPORT_SERVICES_NON_EU",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_v7_tag": "K_44",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 28b VAT",
    "_warnings": ["IMPORT USŁUG SPOZA UE — JPK_V7 pole K_44. Możliwe dodatkowe obowiązki: podatek u źródła (WHT)."]
} {
    input.invoice.direction == "PURCHASE"
    input.vendor.country == "NON_EU"
    input.invoice.place_of_supply == "PL"
}

# P93: import_goods_customs — Import towarów spoza UE (SAD)
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.import_goods_customs",
    "package": "jdg.vat.substantive", "priority": 93,
    "vat_rate": sprintf("%.2f", [thresholds.vat.standard_rate]), "rounding_level": "position", "gtu_code": "",
    "procedure": "IMPORT_CUSTOMS",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26a VAT, Art. 86 ust. 2 pkt 2 VAT",
    "_warnings": [sprintf("IMPORT TOWARÓW — dokument SAD nr %s. VAT naliczony do odliczenia na podstawie dokumentu celnego. Kurs z Tabeli C NBP.", [sad_number])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.procedure == "IMPORT"
    input.vendor.country == "NON_EU"
    sad_number := object.get(input.invoice, "sad_document_number", "---")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P100-P109: MPP — Mechanizm Podzielonej Płatności / Split Payment
# ═══════════════════════════════════════════════════════════════════════════════

# P100: split_payment_mandatory — Obowiązkowy MPP
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.split_payment_mandatory",
    "package": "jdg.vat.substantive", "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "SPLIT_PAYMENT_MANDATORY",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_v7_mpp": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 108a VAT",
    "_warnings": [sprintf("SPLIT PAYMENT OBOWIĄZKOWY — faktura %.2f PLN brutto, kategoria %s. Płatność TYLKO przez MPP. W przelewie podaj: kwotę netto + kwotę VAT osobno.", [amount_gross, category])]
} {
    input.invoice.direction == "PURCHASE"
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross >= thresholds.misc.mpp_mandatory_threshold
    # v7.0 CN bridge: MPP sensitivity by category OR CN code
    mpp_matched { helpers.jdg_is_mpp_sensitive(input.invoice.category_code) }
    mpp_matched { helpers.jdg_is_mpp_sensitive_by_cn(input.invoice.cn_code) }
    mpp_matched
    category := input.invoice.category_code
}

# P101: split_payment_voluntary — Dobrowolny MPP (bezpieczna opcja)
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.split_payment_voluntary",
    "package": "jdg.vat.substantive", "priority": 101,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "SPLIT_PAYMENT_VOLUNTARY",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_v7_mpp": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 108a ust. 3 VAT",
    "_warnings": ["MPP DOBROWOLNY — faktura poniżej progu 15 000 PLN. Użycie MPP chroni przed solidarną odpowiedzialnością za VAT."]
} {
    input.invoice.direction == "PURCHASE"
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross <= thresholds.misc.mpp_mandatory_threshold
    input.invoice.split_payment_used == true
}

# P102: split_payment_no_sanction — Brak MPP przy obowiązku = sankcje
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.split_payment_sanction",
    "package": "jdg.vat.substantive", "priority": 102,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "SPLIT_PAYMENT_SANCTION",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak MPP przy obowiązku — sankcje: 30% VAT, NKUP PIT/CIT, solidarna odpowiedzialność",
    "_legal_basis": "Art. 108a ust. 5-7 VAT",
    "sanction_amount_30pct": sanction_amount,
    "_warnings": [sprintf("SANKCJA MPP: brak split payment przy obowiązku! Konsekwencje: (1) 30%% dodatkowego zobowiązania VAT = %.2f PLN, (2) NKUP w PIT/CIT od netto = %.2f PLN, (3) solidarna odpowiedzialność za VAT dostawcy. KROKI NAPRAWCZE: (a) wykonaj przelew MPP (netto+VAT osobno), (b) wystaw korektę faktury z MPP, (c) złóż czynny żal.", [sanction_amount, amount_net])]
} {
    input.invoice.direction == "PURCHASE"
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross >= thresholds.misc.mpp_mandatory_threshold
    helpers.jdg_is_mpp_sensitive(input.invoice.category_code)
    input.invoice.split_payment_used == false
    amount_net := object.get(input.invoice, "amount_net", 0)
    mpp_matched { helpers.jdg_is_mpp_sensitive(input.invoice.category_code) }
    mpp_matched { helpers.jdg_is_mpp_sensitive_by_cn(input.invoice.cn_code) }
    mpp_matched
    vat_amount := amount_gross - amount_net
    sanction_amount := vat_amount * thresholds.misc.mpp_sanction_rate
}

# ═══════════════════════════════════════════════════════════════════════════════
# P103: vat_solidarity_liability — Solidarna odpowiedzialność nabywcy (Art. 105a-105c VAT) ★★★ NOWA REGUŁA v7.0
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.solidarity_liability_block",
    "package": "jdg.vat.substantive", "priority": 103,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "SOLIDARITY_LIABILITY",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "solidarity_liability_risk": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Ryzyko solidarnej odpowiedzialności za VAT dostawcy (Art. 105a-105c VAT) — uzyj MPP!",
    "_legal_basis": "Art. 105a-105c VAT",
    "_warnings": [sprintf("SOLIDARNA ODPOWIEDZIALNOSC ZA VAT DOSTAWCY! Kwota %.2f PLN > 15 000 PLN, kategoria %s z Zalacznika 15, brak MPP. JEDYNE BEZPIECZNE ROZWIAZANIE: uzyj Mechanizmu Podzielonej Platnosci (MPP).", [amount_gross, category])]
} {
    input.invoice.direction == "PURCHASE"
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross >= thresholds.misc.mpp_mandatory_threshold
    category := input.invoice.category_code
    mpp_matched { helpers.jdg_is_mpp_sensitive(category) }
    mpp_matched { helpers.jdg_is_mpp_sensitive_by_cn(input.invoice.cn_code) }
    mpp_matched
    input.invoice.split_payment_used == false
    input.invoice.split_payment_mandatory_breached != true
}

# ═══════════════════════════════════════════════════════════════════════════════
# P110-P119: JPK_V7M — Struktura deklaracji i flagi
# ═══════════════════════════════════════════════════════════════════════════════

# P110: jpk_v7_structure_mapping — Mapowanie na JPK_V7M
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.jpk_v7_structure_mapping",
    "package": "jdg.vat.substantive", "priority": 110,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "JPK_V7_STRUCTURE",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_v7_version": "2025", "jpk_v7_structure": "V7M",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§ 10 rozporządzenia JPK_VAT",
    "_warnings": ["JPK_V7M — obowiązek miesięczny dla czynnych podatników VAT (do 25. dnia miesiąca)"]
} {
    input.jdg_entrepreneur.is_vat_payer == true
    input.jdg_entrepreneur.vat_period == "MONTHLY"
}

# P111: jpk_v7_flags_documentation — Flagi JPK_V7: FP, MPP, GTU
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.jpk_v7_flags_documentation",
    "package": "jdg.vat.substantive", "priority": 111,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "JPK_V7_FLAGS",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_v7_fp": fp_flag, "jpk_v7_mpp": mpp_flag, "jpk_v7_gtu": gtu_flag,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "§ 10 rozporządzenia JPK_VAT",
    "_warnings": [sprintf("JPK_V7 FLAGI: FP=%s, MPP=%s, GTU=%s. Sprawdź poprawność przed wysyłką.", [fp_flag, mpp_flag, gtu_flag])]
} {
    input.jdg_entrepreneur.is_vat_payer == true
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    fp_flag = "Faktura zaliczkowa / końcowa" { input.invoice.invoice_type in {"ADVANCE", "FINAL"} }
    fp_flag = "" { input.invoice.invoice_type not in {"ADVANCE", "FINAL"} }
    mpp_flag = "OBOWIĄZKOWY" { input.invoice.split_payment_used == true; amount_gross >= thresholds.misc.mpp_mandatory_threshold }
    mpp_flag = "DOBROWOLNY" { input.invoice.split_payment_used == true; amount_gross <= thresholds.misc.mpp_mandatory_threshold }
    mpp_flag = "" { input.invoice.split_payment_used == false }
    gtu_flag := object.get(input.invoice, "gtu_code", "")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P120-P129: Korekty VAT-ZT (deklaracje korygujące)
# ═══════════════════════════════════════════════════════════════════════════════

# P120: vat_zt_correction_required — Obowiązek złożenia VAT-ZT
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.vat_zt_correction_required",
    "package": "jdg.vat.substantive", "priority": 120,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_ZT_CORRECTION",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_zt_required": true,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Wymagana korekta VAT-ZT — wykryto błędy w poprzednich deklaracjach",
    "_legal_basis": "Art. 81-81c OrdPU, Art. 96 ust. 6 VAT",
    "_warnings": [sprintf("KOREKTA VAT-ZT: wykryto %d błędów w deklaracjach. Złóż korektę przed kontrolą — unikniesz sankcji!", [error_count])]
} {
    error_count := object.get(input.jdg_entrepreneur, "vat_error_count", 0)
    error_count > 0
}

# P121: vat_correction_deadline — Korekta JPK_V7 po błędzie (Art. 81 OrdPU)
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.vat_correction_deadline",
    "package": "jdg.vat.substantive", "priority": 121,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_CORRECTION_DEADLINE",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Korekta deklaracji VAT — złóż przed kontrolą KAS",
    "_legal_basis": "Art. 81-81c OrdPU",
    "_warnings": [sprintf("KOREKTA VAT NIEWNIESIONA — wykryto błąd %d dni temu. Złóż korektę JPK_V7 przed wszczęciem kontroli — unikniesz sankcji KKS!", [days_since_error])]
} {
    input.jdg_entrepreneur.vat_zt_required == true
    input.jdg_entrepreneur.vat_zt_filed == false
    days_since_error := object.get(input.jdg_entrepreneur, "days_since_vat_error_detected", 0)
    days_since_error > 7
}

# P122: vat_zt_carry_forward — Przeniesienie nadwyżki VAT do korekty
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.vat_zt_carry_forward",
    "package": "jdg.vat.substantive", "priority": 122,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_ZT_CARRY_FORWARD",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_carry_forward_amount": carry_amount,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 87 VAT",
    "_warnings": [sprintf("NADWYŻKA VAT: %.2f PLN — przeniesiona na następny okres (lub zwrot w 60/25 dni)", [carry_amount])]
} {
    carry_amount := object.get(input.jdg_entrepreneur, "vat_carry_forward", 0)
    carry_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P130-P139: Procedury specjalne i odpowiedzialność solidarna
# ═══════════════════════════════════════════════════════════════════════════════

# P130: wdt_export_0pct — WDT / Eksport 0% VAT
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.wdt_export_0pct",
    "package": "jdg.vat.substantive", "priority": 130,
    "vat_rate": "0.00", "rounding_level": "total", "gtu_code": "",
    "procedure": "WDT_EXPORT",
    "vat_exemption": "0PCT_WDT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 13 VAT (WDT), Art. 2 pkt 8 VAT (eksport)",
    "_warnings": ["WDT/EKSPORT 0%% VAT — obowiązek posiadania dokumentów potwierdzających wywóz. VAT-UE w terminie!"]
} {
    input.invoice.direction == "SALE"
    input.invoice.procedure in {"WDT", "EXPORT"}
}

# P131: vat_sanction_no_registration — Sankcja za brak rejestracji VAT
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.vat_sanction_no_registration",
    "package": "jdg.vat.substantive", "priority": 131,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_SANCTION",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Brak rejestracji VAT przy obrocie > 200k — ryzyko KKS Art. 54/77",
    "_legal_basis": "Art. 96 ust. 3 VAT, Art. 54 KKS, Art. 77 KKS",
    "_warnings": ["SANKCJA KKS: brak rejestracji VAT przy obrocie > 200 000 PLN. Ryzyko: (1) przestępstwo skarbowe Art. 54 KKS, (2) wykroczenie Art. 77 KKS, (3) solidarna odpowiedzialność. Zarejestruj się natychmiast!"]
} {
    input.jdg_entrepreneur.is_vat_payer == false
    # R03 P1: próg z data.thresholds (art. 113 ust. 1 VAT — 200 000 PLN)
    input.jdg_entrepreneur.annual_turnover_net > thresholds.vat.subject_exemption_limit
}

# ═══════════════════════════════════════════════════════════════════════════════
# P140: vat_receipt_simplified_invoice — Paragon z NIP ≤450 PLN jako faktura uproszczona
# Art. 106e ust. 5 pkt 3 VAT — dokument z NIP nabywcy o wartości ≤450 zł brutto
# (lub 100 EUR) stanowi fakturę uproszczoną i uprawnia do odliczenia VAT.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.receipt_as_invoice",
    "package": "jdg.vat.substantive", "priority": 140,
    "vat_rate": receipt_vat_rate, "rounding_level": "position",
    "gtu_code": "", "procedure": "SIMPLIFIED_INVOICE",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "receipt_as_invoice": true, "receipt_deduction_eligible": deduction_ok,
    "receipt_amount_eur": amount_eur,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 106e ust. 5 pkt 3 VAT (faktura uproszczona do 450 PLN / 100 EUR)",
    "_warnings": [sprintf("PARAGON Z NIP JAKO FAKTURA — %.2f PLN brutto (%.2f EUR). %s. Paragon musi zawierać NIP nabywcy. Przechowuj oryginał!", [amount_gross, amount_eur, deduction_info])]
} {
    input.invoice.document_type == "RECEIPT"
    input.invoice.buyer_nip != ""
    input.invoice.direction == "PURCHASE"
    input.invoice.has_buyer_nip == true

    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross > 0

    eur_rate := object.get(object.get(object.get(data.thresholds, "jdg", {}), "rates", {}), "eur_pln", 4.5)
    amount_eur := amount_gross / eur_rate

    # Art. 106e ust. 5 pkt 3 VAT: ≤450 PLN LUB ≤100 EUR
    qualifies_pln := amount_gross <= 450
    qualifies_eur := amount_eur <= 100
    qualifies := {qualifies_pln; qualifies_eur}
    qualifies == true

    deduction_info = "ODLICZENIE VAT MOŻLIWE (≤450 PLN lub ≤100 EUR)"

    # Stawka VAT z paragonu — domyślnie pusta (oznacza: sprawdź treść paragonu)
    receipt_vat_rate := object.get(input.invoice, "vat_rate", "")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P140: vat_account_usage_restriction — Ograniczenia rachunku VAT (Art. 108a ust. 4) ★★★ v7.0 R13
# Środki z rachunku VAT można wykorzystać tylko na: VAT/PIT/CIT/cło/ZUS.
# Przelew poza te cele = BLOCK_AND_ALERT.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.vat_account_restriction",
    "package": "jdg.vat.substantive", "priority": 140,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_ACCOUNT_RESTRICTION",
    "vat_exemption": "", "vat_account_transfer_restricted": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Środki z rachunku VAT nie mogą być użyte na cel: %s. Dozwolone: VAT, PIT, CIT, cło, ZUS.", [transfer_purpose]),
    "_legal_basis": "Art. 108a ust. 4 VAT",
    "_warnings": [sprintf("OGRANICZENIE RACHUNKU VAT: próba transferu %.2f PLN na cel '%s'. Środki z rachunku VAT można wykorzystać WYŁĄCZNIE na: (1) VAT do US, (2) PIT/CIT do US, (3) cło, (4) ZUS. Inne przelewy są ZABRONIONE!", [transfer_amount, transfer_purpose])]
} {
    input.invoice.category_code == "VAT_ACCOUNT_TRANSFER"
    transfer_purpose := object.get(input.invoice, "transfer_purpose", "")
    allowed_purposes := {"VAT", "PIT", "CIT", "CUSTOMS", "ZUS", "TAX_OFFICE"}
    not transfer_purpose in allowed_purposes
    transfer_amount := object.get(input.invoice, "amount_gross", 0)
    transfer_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P141: vat_exemption_loss_after_2_years — Utrata zwolnienia podmiotowego po 2 latach ★★★ v7.0 R13
# Art. 113 ust. 14 VAT: Jeżeli podatnik utracił prawo do zwolnienia w roku N,
# nie może ponownie skorzystać ze zwolnienia w latach N+1 i N+2.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.exemption_loss_2_years",
    "package": "jdg.vat.substantive", "priority": 141,
    "vat_rate": "0.23", "rounding_level": "position",
    "gtu_code": "", "procedure": "EXEMPTION_LOSS_2Y",
    "vat_exemption": "", "vat_exemption_suspended": true,
    "vat_exemption_suspended_years": 2,
    "vat_exemption_suspended_until": suspended_until_year,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Utrata zwolnienia VAT — nie możesz ponownie skorzystać ze zwolnienia do końca %d", [suspended_until_year]),
    "_legal_basis": "Art. 113 ust. 14 VAT",
    "_warnings": [sprintf("UTRATA ZWOLNIENIA VAT NA 2 LATA: przekroczyłeś limit 200 000 PLN w roku %d. Nie możesz ponownie skorzystać ze zwolnienia podmiotowego do końca %d. Musisz być czynnym podatnikiem VAT przez minimum 2 pełne lata.", [loss_year, suspended_until_year])]
} {
    input.jdg_entrepreneur.is_vat_payer == false
    vat_exemption_loss_year := object.get(input.jdg_entrepreneur, "vat_exemption_loss_year", 0)
    current_year := object.get(input.jdg_entrepreneur, "tax_year_as_int", 2026)
    # Utrata zwolnienia w roku N → nie można do końca N+2
    vat_exemption_loss_year > 0
    current_year <= vat_exemption_loss_year + 2
    loss_year := vat_exemption_loss_year
    suspended_until_year := vat_exemption_loss_year + 2
}

# ═══════════════════════════════════════════════════════════════════════════════
# P142: vat_nkup_mpp_breach — NKUP przy braku MPP (Art. 108a ust. 7 VAT) ★★★ v7.0 R13
# Jeżeli brak MPP przy obowiązku → wydatek netto stanowi NKUP w PIT/CIT.
# Reguła flaguje transakcję jako NKUP-MPP.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.nkup_mpp_breach",
    "package": "jdg.vat.substantive", "priority": 142,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "NKUP_MPP_BREACH",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "nkup_mpp_applies": true,
    "nkup_mpp_amount": amount_net,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("NKUP-MPP: wydatek netto %.2f PLN nie stanowi kosztu uzyskania przychodu — brak MPP przy obowiązku.", [amount_net]),
    "_legal_basis": "Art. 108a ust. 7 VAT w zw. z Art. 22p PIT",
    "_warnings": [sprintf("NKUP-MPP: kwota netto %.2f PLN z faktury bez MPP NIE stanowi kosztu uzyskania przychodu! Konsekwencje: (1) 30%% dodatkowego VAT, (2) NKUP netto w PIT/CIT = %.2f PLN, (3) solidarna odpowiedzialność. Wykonaj przelew MPP + korektę faktury.", [amount_net, amount_net])]
} {
    input.invoice.direction == "PURCHASE"
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross >= thresholds.misc.mpp_mandatory_threshold
    helpers.jdg_is_mpp_sensitive(input.invoice.category_code)
    input.invoice.split_payment_used == false
    amount_net := object.get(input.invoice, "amount_net", 0)
}

# ═══════════════════════════════════════════════════════════════════════════════
# P143: vat_mpp_prepayment_check — MPP a zaliczki ★★★ v7.0 R13
# Zaliczka >15 000 PLN brutto na towar wrażliwy → MPP obowiązkowy również od zaliczki.
# LUKA z raportu P02: substantive.rego P100 nie sprawdzał prepayment.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.mpp_prepayment_check",
    "package": "jdg.vat.substantive", "priority": 143,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "MPP_PREPAYMENT_CHECK",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "jpk_v7_mpp": true,
    "_routing": "",
    "_routing_reason": "MPP obowiązkowy również od zaliczek >15 000 PLN na towary wrażliwe",
    "_legal_basis": "Art. 108a VAT (zaliczka podlega MPP tak samo jak płatność końcowa)",
    "_warnings": [sprintf("MPP OD ZALICZKI: zaliczka %.2f PLN brutto na towary wrażliwe (%s). Każda płatność >15 000 PLN (w tym zaliczki) podlega obowiązkowemu MPP!", [amount_gross, category])]
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.invoice_type == "ADVANCE"
    input.invoice.prepayment_received == true
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    amount_gross >= thresholds.misc.mpp_mandatory_threshold
    helpers.jdg_is_mpp_sensitive(input.invoice.category_code)
    category := input.invoice.category_code
}

# ── EU countries list ──────────────────────────────────────────────────────────
eu_countries := {
    "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
    "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
    "PL", "PT", "RO", "SK", "SI", "ES", "SE"
}

# ══ P72: vat_reduced_rate_cross_check — Cross-check obniżonych stawek (Doc 42) ══
else := {
    "matched":true,"rule_id":"jdg.vat.substantive.reduced_rate_cross_check",
    "package":"jdg.vat.substantive","priority":72,
    "vat_rate":"","rounding_level":"",
    "gtu_code":"","procedure":"",
    "vat_exemption":"","pit_form":"","pit_rate":"",
    "pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_registration_required":false,
    "reduced_rate_audit":true,"reduced_rate_warning":true,
    "reduced_rate_audit_threshold":0.85,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Udział obniżonych stawek >85% sprzedaży — ryzyko Art. 64 KKS",
    "_legal_basis":"Art. 64 KKS (niewłaściwa stawka VAT) + procedury audytowe",
    "_warnings":["CROSS-CHECK STAWEK — udział 8%/5%/0% >85% obrotu. Zweryfikuj CN/PKWiU dla każdej kategorii. Ryzyko błędnej klasyfikacji!"]
} {
    reduced_share := object.get(input.jdg_entrepreneur,"reduced_rate_sales_share",0)
    reduced_share > 0.85
}

# ═══════════════════════════════════════════════════════════════════════════════
# P66: vat_rate_5pct_extended — Stawka 5% rozszerzona
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.rate_5pct_extended",
    "package": "jdg.vat.substantive", "priority": 66,
    "vat_rate": "0.05", "rounding_level": "position",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 2a VAT",
    "_warnings": []
} {
    input.invoice.category_code in {
        "BABY_PRODUCTS", "MEAT_FISH", "AGRICULTURAL_INPUTS",
        "DISPOSABLE_MEDICAL", "NEWSPAPERS", "FOOD_MEAT"
    }
    input.vendor.country == "PL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P67: vat_rate_23_standard — Stawka 23% (pozostałe kategorie PL)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.rate_23_standard_pl",
    "package": "jdg.vat.substantive", "priority": 67,
    "vat_rate": "0.23", "rounding_level": "position",
    "gtu_code": "", "procedure": "",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 1 VAT",
    "_warnings": []
} {
    input.vendor.country == "PL"
    input.invoice.category_code in {
        "CONSULTING", "IT_SERVICES", "MARKETING", "ADVERTISING",
        "SOFTWARE", "HOSTING", "SAAS", "TELECOMMUNICATIONS",
        "RENTAL_COMMERCIAL", "CLEANING", "FURNITURE",
        "ELECTRONICS_CONSUMER", "JEWELRY", "OFFICE_SUPPLIES",
        "LEGAL_SERVICES", "ACCOUNTING_SERVICES", "TRANSPORT_GOODS",
        "CONSTRUCTION_MATERIALS", "MAINTENANCE", "SECURITY"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PLACE OF SUPPLY — Art. 28a-28o VAT (P94-P96)
# Rekomendacja W7 z P02: miejsce świadczenia B2B/B2C/nieruchomości/e-usługi
# ═══════════════════════════════════════════════════════════════════════════════

# ── EU countries set (local copy for place_of_supply rules) ────────────────────
eu_countries := {
    "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
    "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
    "PL", "PT", "RO", "SK", "SI", "ES", "SE"
}

# ══ P94: place_of_supply_B2B — Miejsce świadczenia B2B (Art. 28b VAT) ══
# Zasada ogólna B2B: miejsce = siedziba nabywcy (reverse charge w kraju nabywcy)
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.place_of_supply_b2b",
    "package": "jdg.vat.substantive", "priority": 94,
    "vat_rate": "NP", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "OUT_OF_SCOPE", "place_of_supply": buyer_country,
    "vat_reverse_charge": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": sprintf("Miejsce świadczenia B2B — %s (Art. 28b)", [buyer_country]),
    "_legal_basis": "Art. 28b ust. 1 VAT",
    "_warnings": [sprintf("MIEJSCE ŚWIADCZENIA B2B — usługa dla podatnika z %s. Miejsce opodatkowania = %s (reverse charge). Faktura bez VAT, z adnotacją 'odwrotne obciążenie'.", [buyer_country, buyer_country])]
} {
    input.invoice.direction == "SALE"
    input.vendor.country == "PL"
    input.invoice.is_service == true
    buyer_country := object.get(input.buyer, "country", "PL")
    buyer_country in eu_countries
    buyer_country != "PL"
    input.buyer.is_vat_payer == true
}

# ══ P95: place_of_supply_B2C — Miejsce świadczenia B2C (Art. 28a VAT) ══
# Zasada ogólna B2C: miejsce = siedziba usługodawcy (PL)
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.place_of_supply_b2c",
    "package": "jdg.vat.substantive", "priority": 95,
    "vat_rate": "0.23", "rounding_level": "position", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "place_of_supply": "PL",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "Miejsce świadczenia B2C — PL (Art. 28a)",
    "_legal_basis": "Art. 28a VAT",
    "_warnings": ["MIEJSCE ŚWIADCZENIA B2C — usługa dla konsumenta. Miejsce opodatkowania = PL (siedziba usługodawcy). Obowiązek VAT w PL."]
} {
    input.invoice.direction == "SALE"
    input.vendor.country == "PL"
    input.invoice.is_service == true
    buyer_country := object.get(input.buyer, "country", "PL")
    buyer_country == "PL"
    input.buyer.is_vat_payer == false
}

# ══ P95a: place_of_supply_real_estate — Nieruchomości (Art. 28e VAT) ══
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.place_of_supply_real_estate",
    "package": "jdg.vat.substantive", "priority": 95,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "place_of_supply": property_country,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": sprintf("Miejsce świadczenia — nieruchomość w %s (Art. 28e)", [property_country]),
    "_legal_basis": "Art. 28e VAT",
    "_warnings": [sprintf("NIERUCHOMOŚĆ — miejsce świadczenia = %s (położenie nieruchomości). VAT według przepisów kraju położenia. Skonsultuj z doradcą podatkowym w %s.", [property_country, property_country])]
} {
    input.invoice.category_code in {"REAL_ESTATE", "REAL_ESTATE_SALE", "CONSTRUCTION", "RENOVATION"}
    property_country := object.get(input.invoice, "property_country", "PL")
    property_country != "PL"
}

# ══ P95b: place_of_supply_e_services_B2C — E-usługi B2C (Art. 28k VAT) ══
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.place_of_supply_e_services_b2c",
    "package": "jdg.vat.substantive", "priority": 95,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "OSS",
    "vat_exemption": "", "place_of_supply": consumer_country,
    "vat_oss_recommended": true,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": sprintf("E-usługi B2C — miejsce świadczenia = %s (OSS)", [consumer_country]),
    "_legal_basis": "Art. 28k VAT (e-usługi dla konsumentów UE)",
    "_warnings": [sprintf("E-USŁUGI B2C — konsument z %s. Miejsce opodatkowania = %s. Zarejestruj się w OSS (One Stop Shop) aby rozliczać VAT w PL dla wszystkich krajów UE.", [consumer_country, consumer_country])]
} {
    input.invoice.direction == "SALE"
    input.vendor.country == "PL"
    input.invoice.is_e_service == true
    consumer_country := object.get(input.buyer, "country", "PL")
    consumer_country in eu_countries
    consumer_country != "PL"
    input.buyer.is_vat_payer == false
}

# ══ P95c: place_of_supply_transport — Transport (Art. 29-30 VAT) ══
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.place_of_supply_transport",
    "package": "jdg.vat.substantive", "priority": 95,
    "vat_rate": "0.23", "rounding_level": "position", "gtu_code": "GTU_13", "procedure": "",
    "vat_exemption": "", "place_of_supply": transport_place,
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": sprintf("Transport — miejsce świadczenia: %s", [transport_place]),
    "_legal_basis": "Art. 29-30 VAT (transport towarów i osób)",
    "_warnings": [sprintf("TRANSPORT — miejsce świadczenia = %s. Transport krajowy PL = VAT 23%%. Transport międzynarodowy (poza UE) = 0%%.", [transport_place])]
} {
    input.invoice.category_code in {"TRANSPORT_SERVICES", "TRANSPORT_GOODS", "TRANSPORT_PASSENGERS"}
    input.invoice.direction == "SALE"
    input.vendor.country == "PL"
    route_pl_only := object.get(input.invoice, "transport_route_domestic_only", true)
    transport_place = "PL" { route_pl_only == true }
    transport_place = "INTL_MIXED" { route_pl_only == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# V.04: Art. 15 ust. 1 VAT — Podatnik VAT (JDG prowadząca działalność gosp.)
# Definicja: JDG wykonująca samodzielnie działalność gospodarczą = podatnik VAT.
# Umieszczona ABSOLUTNIE NA KOŃCU else-chain (po P67 catch-all) aby NIE shadowować
# żadnych szczegółowych reguł stawek VAT. Odpala tylko gdy żaden inny warunek
# reguł VAT nie został spełniony, a JDG faktycznie prowadzi działalność.
# UWAGA: `conducts_economic_activity` jest opcjonalnym polem input — jeśli nie
# istnieje w schemie, reguła nie odpali (bezpieczny fail).
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.taxable_person_jdg_v04",
    "package": "jdg.vat.substantive", "priority": 999,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "vat_exemption": "", "vat_taxable_person": true,
    "vat_taxable_basis": "Art. 15 ust. 1 VAT — JDG jako podatnik",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 15 ust. 1 VAT",
    "_warnings": ["PODATNIK VAT (Art. 15 ust. 1) — JDG wykonuje samodzielnie działalność gospodarczą. Transakcja podlega VAT, szczegółowa stawka nie została określona — zweryfikuj."]
} {
    input.jdg_entrepreneur.is_jdg == true
    input.jdg_entrepreneur.conducts_economic_activity == true
    input.invoice.amount_net > 0
    input.vendor.country == "PL"
}
