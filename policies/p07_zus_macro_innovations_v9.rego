# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P07 GENIALNE POMYSŁY ENTERPRISE (ZUS/SUS Macro — warstwa makro)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p07_zus_macro_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG MODUŁ ZUS/SUS MACRO (P07) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: AUDYT SKŁADKI ZDROWOTNEJ (PRIORYTET) — skala 9% od dochodu,
#            liniowy 4,9% (limit roczny odliczenia), ryczałt 4,9% z 3 progami
#            (≤60K → 60% przeciętnego, 60-300K → 100%, >300K → 180%),
#            karta podatkowa 9% od minimalnego, korekta roczna (skala),
#            minimalna składka, zaokrąglenia + kalkulator realtime,
#            predykcja roczna, symulator zmiany formy a zdrowotna
#   Sekcja 2: Audyt składek społecznych — emerytalna 19,52%, rentowa 8%,
#            chorobowa 2,45% (dobrowolna), wypadkowa 1,67%, podstawa 60%
#            przeciętnego, limit 30-krotności, ulga na start (6 mies.),
#            Mały ZUS Plus (36 mies., 30% minimalnego), preferencyjny
#            (24 mies.), terminy 10/15/20 dnia miesiąca
#   Sekcja 3: Audyt zasiłków — chorobowy 80%/100%, okres wyczekiwania,
#            macierzyński, opiekuńczy, rehabilitacyjny
#   Sekcja 4: Audyt PPK/PFRON/fundusz solidarnościowy — obowiązki, progi,
#            terminy
#   Sekcja 5: Audyt zbiegów tytułów i statusów — etat+JDG, emeryt+JDG,
#            student+JDG, urlop wychowawczy+JDG — silnik determinacji
#            obowiązków per zbieg
#   Sekcja 6: OPA jako rozbudowany system — thresholdy ZUS temporalne
#            i auto-aktualizacja (ADR-002, zero hardcode)
#   Sekcja 7: 15+ genialnych pomysłów Enterprise (INN-01..INN-15)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R07)
#
# Zgodność: ustawa SUS (Dz.U. 2025 poz. 345), ustawa o świadczeniach
#           zdrowotnych (Dz.U. 2025 poz. 890), ustawa zasiłkowa, ADR-002
#           (progi z data.jdg.thresholds — zero hardcode), ADR-006
#           (_legal_basis w każdej regule).
# package: jdg.p07_zus_macro_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p07_zus_macro_innovations

import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.p07_zus_macro_innovations.no_match","package":"jdg.p07_zus_macro_innovations","priority":999999}

# ── Źródła danych: progi z data.jdg.thresholds.zus (ADR-002 — zero hardcode) ──
thresholds := object.get(data.jdg, "thresholds", {})
zus_limits := object.get(thresholds, "zus", {
    # Sekcja 1 — składka zdrowotna
    "health_scale_rate": 0.09,                # 9% od dochodu (skala)
    "health_linear_rate": 0.049,              # 4,9% od dochodu (liniowy)
    "health_linear_deduction_limit": 14100,   # PLN/rok max odliczenia (2026)
    "health_lump_tier_1_limit": 60000,        # PLN przychodu — próg 1
    "health_lump_tier_2_limit": 300000,       # PLN przychodu — próg 2
    "health_lump_tier_1_amount": 491.40,      # PLN/mies (60% przeciętnego 2026)
    "health_lump_tier_2_amount": 819.00,      # PLN/mies (100% przeciętnego 2026)
    "health_lump_tier_3_amount": 1474.20,     # PLN/mies (180% przeciętnego 2026)
    "health_tax_card_rate": 0.09,             # 9% od minimalnego (karta)
    # Sekcja 2 — składki społeczne
    "social_emerytalna": 0.1952,              # 19,52%
    "social_rentowa": 0.08,                   # 8%
    "social_chorobowa": 0.0245,               # 2,45% (dobrowolna)
    "social_wypadkowa": 0.0167,               # 1,67%
    "social_base_standard": 5204.40,          # PLN — 60% × 8674 (2026)
    "social_30x_limit": 318600,               # PLN — 30-krotność prognozy 2026
    "ulga_start_months": 6,                   # ulga na start
    "maly_zus_plus_months": 36,               # Mały ZUS Plus
    "maly_zus_plus_base_rate": 0.30,          # 30% minimalnego
    "preferential_months": 24,                # preferencyjny
    "preferential_base_rate": 0.30,           # 30% minimalnego
    "minimum_wage_gross": 4800,               # PLN — minimalne 2026
    # Sekcja 3 — zasiłki
    "sickness_rate_standard": 0.80,           # 80% podstawy
    "sickness_rate_special": 1.00,            # 100% (ciąża, wypadek w drodze)
    "sickness_waiting_months": 3,             # 90 dni wyczekiwania
    "sickness_annual_limit": 85528,           # PLN/rok limit podstawy (2026)
    "maternity_days": 140,                    # 20 tyg. — podstawowy
    # Sekcja 4 — PPK/PFRON/FS
    "ppk_employee_default": 0.02,             # 2% pracownik
    "ppk_employer_min": 0.015,                # 1,5% pracodawca (min)
    "ppk_employer_max": 0.04,                 # 4% pracodawca (max)
    "pfron_employees_threshold": 25,          # etatowy próg 25 pracowników
    "pfron_quota": 0.06,                      # 6% wskaźnik zatrudnienia ON
    "solidarity_rate": 0.0145,                # 1,45% fundusz solidarnościowy
})

# ── Pomocnicze zaokrąglenia groszowe (F1: netto+składka, kontrakt groszowy) ──
round2(x) = r {
    r := round(x * 100) / 100
}

# ── SEKCJA 1: AUDYT SKŁADKI ZDROWOTNEJ (POZIOM ENTERPRISE — PRIORYTET) ──────
health_scale_rate := to_number(object.get(zus_limits, "health_scale_rate", 0.09))
health_linear_rate := to_number(object.get(zus_limits, "health_linear_rate", 0.049))
health_linear_deduction_limit := to_number(object.get(zus_limits, "health_linear_deduction_limit", 14100))
health_lump_tier_1_limit := to_number(object.get(zus_limits, "health_lump_tier_1_limit", 60000))
health_lump_tier_2_limit := to_number(object.get(zus_limits, "health_lump_tier_2_limit", 300000))
health_lump_tier_1_amount := to_number(object.get(zus_limits, "health_lump_tier_1_amount", 491.40))
health_lump_tier_2_amount := to_number(object.get(zus_limits, "health_lump_tier_2_amount", 819.00))
health_lump_tier_3_amount := to_number(object.get(zus_limits, "health_lump_tier_3_amount", 1474.20))
health_tax_card_rate := to_number(object.get(zus_limits, "health_tax_card_rate", 0.09))
minimum_wage_gross := to_number(object.get(zus_limits, "minimum_wage_gross", 4800))

# Matryca forma → stawka/podstawa składki zdrowotnej (Sekcja 1 — rdzeń).
health_form_matrix := {
    "skala": {
        "rate": health_scale_rate,
        "base": "dochód",
        "annual_reconciliation": true,
        "legal_basis": "Art. 81 ust. 2 pkt 1 ustawy o świadczeniach zdrowotnych",
        "note": "Korekta roczna w zeznaniu",
    },
    "liniowy": {
        "rate": health_linear_rate,
        "base": "dochód",
        "annual_reconciliation": false,
        "deduction_limit": health_linear_deduction_limit,
        "legal_basis": "Art. 81 ust. 2 pkt 2 ustawy o świadczeniach zdrowotnych",
        "note": "Składka nie odlicza się od podatku (limit odliczenia dotyczy PIT)",
    },
    "ryczałt": {
        "rate": 0.049,
        "base": "przychód — 3 progi",
        "annual_reconciliation": false,
        "tiers": [
            {"limit": health_lump_tier_1_limit, "amount": health_lump_tier_1_amount, "share": 0.60},
            {"limit": health_lump_tier_2_limit, "amount": health_lump_tier_2_amount, "share": 1.00},
            {"limit": 999999999, "amount": health_lump_tier_3_amount, "share": 1.80},
        ],
        "legal_basis": "Art. 81 ust. 2 pkt 3 ustawy o świadczeniach zdrowotnych",
    },
    "karta": {
        "rate": health_tax_card_rate,
        "base": "minimalne wynagrodzenie",
        "annual_reconciliation": false,
        "legal_basis": "Art. 81 ust. 2za ustawy o świadczeniach zdrowotnych",
    },
}

# Kalkulatory per forma (groszowe, deterministyczne).
health_scale_contribution(income) = amount {
    amount := round2(income * health_scale_rate)
}

health_linear_contribution(income) = amount {
    amount := round2(income * health_linear_rate)
}

health_lump_contribution(revenue) = amount {
    revenue <= health_lump_tier_1_limit
    amount := health_lump_tier_1_amount
} else = amount {
    revenue <= health_lump_tier_2_limit
    amount := health_lump_tier_2_amount
} else = amount {
    amount := health_lump_tier_3_amount
}

health_tax_card_contribution = amount {
    amount := round2(minimum_wage_gross * health_tax_card_rate)
}

# Główny audyt składki zdrowotnej — per forma, z progami i minimalną składką.
health_contribution_audit := {
    "rule_id": "jdg.p07_zus_macro_innovations.health_contribution_audit",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 720,
    "matched": true,
    "form": object.get(input.jdg_entrepreneur, "tax_form", "skala"),
    "matrix": health_form_matrix,
    "scale_9pct": health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
    "linear_4p9pct": health_linear_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
    "lump_tiers": [
        {"revenue": "<= 60000", "amount": health_lump_tier_1_amount},
        {"revenue": "60000-300000", "amount": health_lump_tier_2_amount},
        {"revenue": "> 300000", "amount": health_lump_tier_3_amount},
    ],
    "lump_current": health_lump_contribution(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))),
    "tax_card_9pct_min": health_tax_card_contribution,
    "minimum_monthly": round2(minimum_wage_gross * health_scale_rate),
    "_routing": "",
    "_routing_reason": "Audyt składki zdrowotnej per forma opodatkowania (priorytet P07)",
    "_legal_basis": "Art. 81 ustawy o świadczeniach zdrowotnych (Dz.U. 2025 poz. 890)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# INN-01: Kalkulator optymalnej składki zdrowotnej w czasie rzeczywistym
# (porównanie wszystkich form na bieżącym dochodzie).
health_optimizer_realtime := {
    "rule_id": "jdg.p07_zus_macro_innovations.health_optimizer_realtime",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 721,
    "matched": true,
    "income": to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)),
    "revenue": to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)),
    "comparison": {
        "skala_9pct": health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
        "liniowy_4p9pct": health_linear_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
        "ryczałt": health_lump_contribution(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))),
        "karta": health_tax_card_contribution,
    },
    "cheapest_form": cheapest_health_form(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)), to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))),
    "_routing": "",
    "_routing_reason": "Kalkulator realtime — porównanie składki zdrowotnej per forma",
    "_legal_basis": "Art. 81 ustawy o świadczeniach zdrowotnych",
    "_warnings": [sprintf("Najniższa składka zdrowotna: %s | Skala: %.2f PLN | Liniowy: %.2f PLN | Ryczałt: %.2f PLN", [cheapest_health_form(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)), to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))), health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))), health_linear_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))), health_lump_contribution(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)))])],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

cheapest_health_form(income, revenue) = form {
    candidates := [
        {"form": "skala", "amount": health_scale_contribution(income)},
        {"form": "liniowy", "amount": health_linear_contribution(income)},
        {"form": "ryczałt", "amount": health_lump_contribution(revenue)},
        {"form": "karta", "amount": health_tax_card_contribution},
    ]
    sorted := sort([[c.amount, c.form] | some c in candidates])
    form := sorted[0][1]
}

# INN-02: Predykcja roczna składki zdrowotnej (12 mies. + korekta roczna).
health_annual_prediction := {
    "rule_id": "jdg.p07_zus_macro_innovations.health_annual_prediction",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 722,
    "matched": true,
    "monthly_income": to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)),
    "annual_scale": round2(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)) * 12 * health_scale_rate),
    "annual_linear": round2(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)) * 12 * health_linear_rate),
    "annual_lump": round2(health_lump_contribution(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))) * 12),
    "annual_tax_card": round2(health_tax_card_contribution * 12),
    "deduction_linear_cap": health_linear_deduction_limit,
    "_routing": "",
    "_routing_reason": "Predykcja roczna składki zdrowotnej",
    "_legal_basis": "Art. 81 ustawy o świadczeniach zdrowotnych",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# INN-03: Symulator zmiany formy a składka zdrowotna.
health_form_change_simulator := {
    "rule_id": "jdg.p07_zus_macro_innovations.health_form_change_simulator",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 723,
    "matched": true,
    "from_form": object.get(input.jdg_entrepreneur, "tax_form", "skala"),
    "to_form": object.get(input.jdg_entrepreneur, "simulated_form", "liniowy"),
    "monthly_before": health_form_contribution(object.get(input.jdg_entrepreneur, "tax_form", "skala"), to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)), to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))),
    "monthly_after": health_form_contribution(object.get(input.jdg_entrepreneur, "simulated_form", "liniowy"), to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)), to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))),
    "monthly_delta": round2(health_form_contribution(object.get(input.jdg_entrepreneur, "simulated_form", "liniowy"), to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)), to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))) - health_form_contribution(object.get(input.jdg_entrepreneur, "tax_form", "skala"), to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)), to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)))),
    "annual_delta": round2((health_form_contribution(object.get(input.jdg_entrepreneur, "simulated_form", "liniowy"), to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)), to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))) - health_form_contribution(object.get(input.jdg_entrepreneur, "tax_form", "skala"), to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)), to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)))) * 12),
    "_routing": "",
    "_routing_reason": "Symulator zmiany formy a składka zdrowotna",
    "_legal_basis": "Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych; art. 9a PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

health_form_contribution(form, income, revenue) = amount {
    amount := health_scale_contribution(income)
    form == "skala"
} else = amount {
    amount := health_linear_contribution(income)
    form == "liniowy"
} else = amount {
    amount := health_lump_contribution(revenue)
    form == "ryczałt"
} else = amount {
    amount := health_tax_card_contribution
    form == "karta"
} else = amount {
    amount := 0
}

# Korekta roczna składki zdrowotnej (skala — w zeznaniu rocznym).
health_annual_reconciliation := {
    "rule_id": "jdg.p07_zus_macro_innovations.health_annual_reconciliation",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 724,
    "matched": true,
    "annual_income": to_number(object.get(input.jdg_entrepreneur, "annual_income", 0)),
    "advances_paid": to_number(object.get(input.jdg_entrepreneur, "health_advances_paid", 0)),
    "due": round2(to_number(object.get(input.jdg_entrepreneur, "annual_income", 0)) * health_scale_rate),
    "difference": round2(to_number(object.get(input.jdg_entrepreneur, "annual_income", 0)) * health_scale_rate - to_number(object.get(input.jdg_entrepreneur, "health_advances_paid", 0))),
    "_routing": "",
    "_routing_reason": "Korekta roczna składki zdrowotnej (tylko skala)",
    "_legal_basis": "Art. 81 ust. 2 pkt 1 ustawy o świadczeniach zdrowotnych; art. 45 PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# ── SEKCJA 2: AUDYT SKŁADEK SPOŁECZNYCH (zaawansowany Enterprise) ────────────
social_emerytalna := to_number(object.get(zus_limits, "social_emerytalna", 0.1952))
social_rentowa := to_number(object.get(zus_limits, "social_rentowa", 0.08))
social_chorobowa := to_number(object.get(zus_limits, "social_chorobowa", 0.0245))
social_wypadkowa := to_number(object.get(zus_limits, "social_wypadkowa", 0.0167))
social_base_standard := to_number(object.get(zus_limits, "social_base_standard", 5204.40))
social_30x_limit := to_number(object.get(zus_limits, "social_30x_limit", 318600))
ulga_start_months := to_number(object.get(zus_limits, "ulga_start_months", 6))
maly_zus_plus_months := to_number(object.get(zus_limits, "maly_zus_plus_months", 36))
maly_zus_plus_base_rate := to_number(object.get(zus_limits, "maly_zus_plus_base_rate", 0.30))
preferential_months := to_number(object.get(zus_limits, "preferential_months", 24))
preferential_base_rate := to_number(object.get(zus_limits, "preferential_base_rate", 0.30))

# Rozbicie składek społecznych na fundusze (art. 22 SUS).
social_contribution_calculator(base) = result {
    result := {
        "emerytalna": round2(base * social_emerytalna),
        "rentowa": round2(base * social_rentowa),
        "chorobowa": round2(base * social_chorobowa),
        "wypadkowa": round2(base * social_wypadkowa),
        "total": round2(base * (social_emerytalna + social_rentowa + social_chorobowa + social_wypadkowa)),
        "base": round2(base),
    }
}

social_contribution_audit := {
    "rule_id": "jdg.p07_zus_macro_innovations.social_contribution_audit",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 730,
    "matched": true,
    "standard_base": social_base_standard,
    "rates": {
        "emerytalna": social_emerytalna,
        "rentowa": social_rentowa,
        "chorobowa": social_chorobowa,
        "wypadkowa": social_wypadkowa,
    },
    "standard_monthly": social_contribution_calculator(social_base_standard),
    "preferential_base": round2(minimum_wage_gross * preferential_base_rate),
    "preferential_monthly": social_contribution_calculator(round2(minimum_wage_gross * preferential_base_rate)),
    "maly_zus_base": round2(minimum_wage_gross * maly_zus_plus_base_rate),
    "maly_zus_monthly": social_contribution_calculator(round2(minimum_wage_gross * maly_zus_plus_base_rate)),
    "relief_phase": relief_phase_detector(object.get(input.jdg_entrepreneur, "months_since_start", 0)),
    "deadline": "10/15/20 dzień miesiąca",
    "thirty_x_limit": social_30x_limit,
    "_routing": "",
    "_routing_reason": "Audyt składek społecznych — stopy, podstawy, ulgi, terminy",
    "_legal_basis": "Art. 18 ust. 8, art. 22, art. 47 SUS (Dz.U. 2025 poz. 345)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# Detektor fazy ulgi (ulga na start → preferencyjny → MZP → standard).
relief_phase_detector(months) = phase {
    months <= ulga_start_months
    phase := "ulga_na_start"
} else = phase {
    months <= ulga_start_months + preferential_months
    phase := "preferencyjny"
} else = phase {
    phase := "standard"
}

# INN-04: Monitor limitu 30-krotności — składki od nadwyżek.
thirtyx_limit_monitor := {
    "rule_id": "jdg.p07_zus_macro_innovations.thirtyx_limit_monitor",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 731,
    "matched": true,
    "cumulative_base": to_number(object.get(input.jdg_entrepreneur, "cumulative_zus_base", 0)),
    "limit": social_30x_limit,
    "exceeded": to_number(object.get(input.jdg_entrepreneur, "cumulative_zus_base", 0)) > social_30x_limit,
    "excess": max([to_number(object.get(input.jdg_entrepreneur, "cumulative_zus_base", 0)) - social_30x_limit, 0]),
    "_routing": "WARNING",
    "_routing_reason": "Przekroczenie 30-krotności — brak składek emerytalno-rentowych od nadwyżki",
    "_legal_basis": "Art. 19 ust. 1 SUS",
    "_warnings": ["30-krotność osiągnięta — od nadwyżki nie opłaca się emerytalnej/rentowej"],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
    to_number(object.get(input.jdg_entrepreneur, "cumulative_zus_base", 0)) > social_30x_limit
}

# INN-05: Śledzenie ulgi na start (6 mies. — brak składek społecznych).
ulga_start_tracker := {
    "rule_id": "jdg.p07_zus_macro_innovations.ulga_start_tracker",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 732,
    "matched": true,
    "months_since_start": to_number(object.get(input.jdg_entrepreneur, "months_since_start", 0)),
    "ulga_active": to_number(object.get(input.jdg_entrepreneur, "months_since_start", 0)) <= ulga_start_months,
    "months_left": max([ulga_start_months - to_number(object.get(input.jdg_entrepreneur, "months_since_start", 0)), 0]),
    "note": "W uldze na start brak składek społecznych — obowiązkowa zdrowotna",
    "_routing": "",
    "_routing_reason": "Śledzenie ulgi na start",
    "_legal_basis": "Art. 18 ust. 1 pkt 2a, art. 5a SUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# INN-06: Audyt Mały ZUS Plus (36 mies., podstawa 30% minimalnego, limity).
maly_zus_plus_audit := {
    "rule_id": "jdg.p07_zus_macro_innovations.maly_zus_plus_audit",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 733,
    "matched": true,
    "income_last_year": to_number(object.get(input.jdg_entrepreneur, "income_last_year", 0)),
    "revenue_last_year": to_number(object.get(input.jdg_entrepreneur, "revenue_last_year", 0)),
    "income_within": to_number(object.get(input.jdg_entrepreneur, "income_last_year", 0)) <= to_number(object.get(zus_limits, "maly_zus_plus_income_limit", 60000)),
    "revenue_within": to_number(object.get(input.jdg_entrepreneur, "revenue_last_year", 0)) <= to_number(object.get(zus_limits, "maly_zus_plus_revenue_limit", 120000)),
    "eligible": to_number(object.get(input.jdg_entrepreneur, "income_last_year", 0)) <= to_number(object.get(zus_limits, "maly_zus_plus_income_limit", 60000)) and to_number(object.get(input.jdg_entrepreneur, "revenue_last_year", 0)) <= to_number(object.get(zus_limits, "maly_zus_plus_revenue_limit", 120000)),
    "base": round2(minimum_wage_gross * maly_zus_plus_base_rate),
    "monthly_total": social_contribution_calculator(round2(minimum_wage_gross * maly_zus_plus_base_rate)).total,
    "_routing": "",
    "_routing_reason": "Audyt Mały ZUS Plus — limity przychodu/dochodu i podstawa 30%",
    "_legal_basis": "Art. 18 ust. 9 SUS (Dz.U. 2025 poz. 345)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# INN-07: Preferencyjny ZUS (24 mies. — 30% minimalnego).
preferential_zus_audit := {
    "rule_id": "jdg.p07_zus_macro_innovations.preferential_zus_audit",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 734,
    "matched": true,
    "months_used": to_number(object.get(input.jdg_entrepreneur, "preferential_months_used", 0)),
    "within_limit": to_number(object.get(input.jdg_entrepreneur, "preferential_months_used", 0)) < preferential_months,
    "months_left": max([preferential_months - to_number(object.get(input.jdg_entrepreneur, "preferential_months_used", 0)), 0]),
    "base": round2(minimum_wage_gross * preferential_base_rate),
    "monthly_total": social_contribution_calculator(round2(minimum_wage_gross * preferential_base_rate)).total,
    "_routing": "",
    "_routing_reason": "Audyt preferencyjnego ZUS — 24 mies. od rozpoczęcia",
    "_legal_basis": "Art. 18a SUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# ── SEKCJA 3: AUDYT ZASIŁKÓW (poziom ENTERPRISE) ─────────────────────────────
sickness_rate_standard := to_number(object.get(zus_limits, "sickness_rate_standard", 0.80))
sickness_rate_special := to_number(object.get(zus_limits, "sickness_rate_special", 1.00))
sickness_waiting_months := to_number(object.get(zus_limits, "sickness_waiting_months", 3))
sickness_annual_limit := to_number(object.get(zus_limits, "sickness_annual_limit", 85528))
maternity_days := to_number(object.get(zus_limits, "maternity_days", 140))

# Kalkulator zasiłku chorobowego: 1/30 podstawy × stopa × dni.
sickness_benefit_calculator(base, rate, days) = amount {
    daily := round2(base / 30)
    amount := round2(daily * rate * days)
}

benefits_audit := {
    "rule_id": "jdg.p07_zus_macro_innovations.benefits_audit",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 740,
    "matched": true,
    "sickness_base": to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)),
    "waiting_period_ok": to_number(object.get(input.jdg_entrepreneur, "insured_months", 0)) >= sickness_waiting_months,
    "sickness_80pct_daily": sickness_benefit_calculator(to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)), sickness_rate_standard, 1),
    "sickness_100pct_daily": sickness_benefit_calculator(to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)), sickness_rate_special, 1),
    "maternity_20wks_days": maternity_days,
    "maternity_100pct_daily": round2(to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)) / 30),
    "rehab_90pct_daily": sickness_benefit_calculator(to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)), 0.90, 1),
    "annual_limit": sickness_annual_limit,
    "_routing": "",
    "_routing_reason": "Audyt zasiłków — chorobowy 80/100%, macierzyński, opiekuńczy, rehabilitacyjny",
    "_legal_basis": "Art. 4-54 ustawy zasiłkowej; art. 29-30 ustawy o rehabilitacji",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# INN-08: Detektor okresu wyczekiwania (90 dni — klucz dla JDG).
sickness_waiting_tracker := {
    "rule_id": "jdg.p07_zus_macro_innovations.sickness_waiting_tracker",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 741,
    "matched": true,
    "insured_months": to_number(object.get(input.jdg_entrepreneur, "insured_months", 0)),
    "waiting_months": sickness_waiting_months,
    "eligible": to_number(object.get(input.jdg_entrepreneur, "insured_months", 0)) >= sickness_waiting_months,
    "months_to_go": max([sickness_waiting_months - to_number(object.get(input.jdg_entrepreneur, "insured_months", 0)), 0]),
    "_routing": "",
    "_routing_reason": "Okres wyczekiwania do zasiłku chorobowego",
    "_legal_basis": "Art. 4 ust. 1 ustawy zasiłkowej",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# ── SEKCJA 4: AUDYT PPK/PFRON/SOLIDARNOŚCIOWY ────────────────────────────────
ppk_employee_default := to_number(object.get(zus_limits, "ppk_employee_default", 0.02))
ppk_employer_min := to_number(object.get(zus_limits, "ppk_employer_min", 0.015))
ppk_employer_max := to_number(object.get(zus_limits, "ppk_employer_max", 0.04))
pfron_employees_threshold := to_number(object.get(zus_limits, "pfron_employees_threshold", 25))
pfron_quota := to_number(object.get(zus_limits, "pfron_quota", 0.06))
solidarity_rate := to_number(object.get(zus_limits, "solidarity_rate", 0.0145))

ppk_pfron_solidarity_audit := {
    "rule_id": "jdg.p07_zus_macro_innovations.ppk_pfron_solidarity_audit",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 750,
    "matched": true,
    "ppk": {
        "employee": ppk_employee_default,
        "employer_min": ppk_employer_min,
        "employer_max": ppk_employer_max,
        "obligation": "pracodawca > 0 pracowników (3 mies. od zatrudnienia)",
    },
    "pfron": {
        "threshold_employees": pfron_employees_threshold,
        "quota": pfron_quota,
        "obligation": ">= 25 etatowych pracowników",
    },
    "solidarity": {
        "rate": solidarity_rate,
        "obligation": "pracodawcy — składka na FS",
    },
    "employees": to_number(object.get(input.jdg_entrepreneur, "employees_count", 0)),
    "pfron_obliged": to_number(object.get(input.jdg_entrepreneur, "employees_count", 0)) >= pfron_employees_threshold,
    "_routing": "",
    "_routing_reason": "Audyt PPK/PFRON/funduszu solidarnościowego — obowiązki, progi, terminy",
    "_legal_basis": "Ustawa o PPK; ustawa o rehabilitacji (PFRON); ustawa o FS (art. 5-6)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# ── SEKCJA 5: AUDYT ZBIEGÓW TYTUŁÓW I STATUSÓW (poziom ENTERPRISE) ───────────
# Silnik determinacji obowiązków per zbieg: etat+JDG, emeryt+JDG,
# student+JDG, urlop wychowawczy+JDG.
concurrent_title_matrix := {
    "etat_jdg": {
        "social": false,
        "health": true,
        "note": "Zbieg etat+JDG — z JDG tylko składka zdrowotna",
        "legal_basis": "Art. 9 ust. 1a-2 SUS",
    },
    "emeryt_jdg": {
        "social": false,
        "health": true,
        "note": "Emeryt + JDG — z JDG tylko zdrowotna (do limitów)",
        "legal_basis": "Art. 9 ust. 1, art. 9a SUS",
    },
    "student_jdg": {
        "social": false,
        "health": true,
        "note": "Student <26 lat + JDG — z JDG tylko zdrowotna",
        "legal_basis": "Art. 9 ust. 1 pkt 1-2, art. 6 ust. 1 pkt 4 SUS",
    },
    "urlop_wychowawczy_jdg": {
        "social": false,
        "health": true,
        "note": "Urlop wychowawczy + JDG — z JDG tylko zdrowotna",
        "legal_basis": "Art. 9 ust. 1c SUS",
    },
}

concurrent_title_engine := {
    "rule_id": "jdg.p07_zus_macro_innovations.concurrent_title_engine",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 760,
    "matched": true,
    "concurrent_title": object.get(input.jdg_entrepreneur, "concurrent_title", "none"),
    "matrix": concurrent_title_matrix,
    "obligation": object.get(concurrent_title_matrix, object.get(input.jdg_entrepreneur, "concurrent_title", "none"), {"social": true, "health": true, "note": "Brak zbiegu — pełne składki z JDG"}),
    "_routing": "",
    "_routing_reason": "Silnik determinacji obowiązków per zbieg tytułów",
    "_legal_basis": "Art. 9 SUS (Dz.U. 2025 poz. 345)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# INN-09: Audyt zbieg etat+JDG — tylko zdrowotna z JDG.
etat_jdg_health_only := {
    "rule_id": "jdg.p07_zus_macro_innovations.etat_jdg_health_only",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 761,
    "matched": true,
    "has_employment": object.get(input.jdg_entrepreneur, "has_employment", false) == true,
    "social_skipped": true,
    "health_paid": true,
    "savings_social_monthly": social_contribution_calculator(social_base_standard).total,
    "_routing": "",
    "_routing_reason": "Zbieg etat+JDG — z JDG płacisz tylko składkę zdrowotną",
    "_legal_basis": "Art. 9 ust. 1a-2 SUS",
    "_warnings": ["Oszczędność: brak składek społecznych z JDG przy etacie"],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
    object.get(input.jdg_entrepreneur, "has_employment", false) == true
}

# ── SEKCJA 6: OPA JAKO ROZBUDOWANY SYSTEM — THRESHOLDY TEMPORALNE ────────────
# Stopy i podstawy ZUS zmieniają się co roku — system temporalny
# (ADR-002: dane z data.jdg.thresholds.zus, migawki per rok).
zus_thresholds_snapshot := {
    "rule_id": "jdg.p07_zus_macro_innovations.zus_thresholds_snapshot",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 770,
    "matched": true,
    "year": object.get(input.jdg_entrepreneur, "tax_year", 2026),
    "snapshot": {
        "minimum_wage_gross": minimum_wage_gross,
        "social_base_standard": social_base_standard,
        "health_lump_tier_1": health_lump_tier_1_amount,
        "health_lump_tier_2": health_lump_tier_2_amount,
        "health_lump_tier_3": health_lump_tier_3_amount,
        "health_linear_deduction_limit": health_linear_deduction_limit,
        "social_30x_limit": social_30x_limit,
        "sickness_annual_limit": sickness_annual_limit,
    },
    "drift_vs_2025": {
        "min_wage_delta": round2(minimum_wage_gross - 4666),
        "base_delta": round2(social_base_standard - 5054.40),
        "lump_tier2_delta": round2(health_lump_tier_2_amount - 797.16),
    },
    "auto_update": "hot-reload data.jdg.thresholds.zus (ADR-002)",
    "_routing": "",
    "_routing_reason": "Migawka thresholdów ZUS temporalnych per rok",
    "_legal_basis": "Rozporządzenie RM (minimalne wynagrodzenie); obwieszczenia ZUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# INN-10: Detektor dryfu limitów — zmiany stóp/podstaw między latami.
zus_limit_drift := {
    "rule_id": "jdg.p07_zus_macro_innovations.zus_limit_drift",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 771,
    "matched": true,
    "changes_2026": {
        "min_wage": {"from": 4666, "to": minimum_wage_gross, "pct": round2((minimum_wage_gross - 4666) / 4666 * 100)},
        "social_base": {"from": 5054.40, "to": social_base_standard, "pct": round2((social_base_standard - 5054.40) / 5054.40 * 100)},
    },
    "_routing": "",
    "_routing_reason": "Dryf limitów ZUS między rokiem 2025 a 2026",
    "_legal_basis": "ADR-002 (dane temporalne)",
    "_warnings": [sprintf("Zmiany 2026: minimalne %v PLN (%.2f%%), podstawa %.2f PLN (%.2f%%)", [minimum_wage_gross, round2((minimum_wage_gross - 4666) / 4666 * 100), social_base_standard, round2((social_base_standard - 5054.40) / 5054.40 * 100)])],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# ── SEKCJA 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-15) ───────────────────
# INN-01..03 (health optimizer, prediction, form change) — w Sekcji 1.
# INN-04..07 (30x, ulga start, MZP, preferencyjny) — w Sekcji 2.
# INN-08 (waiting tracker) — w Sekcji 3. INN-09 (etat+JDG) — w Sekcji 5.
# INN-10 (limit drift) — w Sekcji 6.

# INN-11: Kalendarz terminów ZUS (10/15/20 dzień miesiąca) + przypomnienia.
zus_calendar := {
    "rule_id": "jdg.p07_zus_macro_innovations.zus_calendar",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 780,
    "matched": true,
    "deadlines": {
        "osoba_fizyczna": "10 dzień miesiąca",
        "spolka_osobowa": "15 dzień miesiąca",
        "platnik_zatrudniajacy": "20 dzień miesiąca",
    },
    "reminder_days_before": 5,
    "_routing": "",
    "_routing_reason": "Kalendarz terminów ZUS — 10/15/20 dnia miesiąca",
    "_legal_basis": "Art. 47 ust. 1-2 SUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# INN-12: Detektor błędnych podstaw wymiaru (porównanie z minimalną/standardową).
wrong_base_detector := {
    "rule_id": "jdg.p07_zus_macro_innovations.wrong_base_detector",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 781,
    "matched": true,
    "declared_base": to_number(object.get(input.jdg_entrepreneur, "declared_zus_base", 0)),
    "minimum_base": round2(minimum_wage_gross * preferential_base_rate),
    "below_minimum": to_number(object.get(input.jdg_entrepreneur, "declared_zus_base", 0)) < round2(minimum_wage_gross * preferential_base_rate),
    "recommended": round2(max([to_number(object.get(input.jdg_entrepreneur, "declared_zus_base", 0)), minimum_wage_gross * preferential_base_rate])),
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zadeklarowana podstawa poniżej minimalnej — błąd w ZUS DRA",
    "_legal_basis": "Art. 18 ust. 8 SUS",
    "_warnings": [sprintf("Podstawa %v PLN poniżej minimalnej %.2f PLN", [to_number(object.get(input.jdg_entrepreneur, "declared_zus_base", 0)), round2(minimum_wage_gross * preferential_base_rate)])],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
    to_number(object.get(input.jdg_entrepreneur, "declared_zus_base", 0)) > 0
    to_number(object.get(input.jdg_entrepreneur, "declared_zus_base", 0)) < round2(minimum_wage_gross * preferential_base_rate)
}

# INN-13: Symulator ubezpieczeń na 5 lat (prognoza kosztów ZUS).
zus_5y_simulator := {
    "rule_id": "jdg.p07_zus_macro_innovations.zus_5y_simulator",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 782,
    "matched": true,
    "monthly_social": social_contribution_calculator(social_base_standard).total,
    "monthly_health_scale": health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
    "monthly_total": round2(social_contribution_calculator(social_base_standard).total + health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)))),
    "annual_total": round2((social_contribution_calculator(social_base_standard).total + health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)))) * 12),
    "growth_assumption_annual": 0.04,
    "five_year_projection": [
        {"year": 1, "cost": round2((social_contribution_calculator(social_base_standard).total + health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)))) * 12)},
        {"year": 2, "cost": round2((social_contribution_calculator(social_base_standard).total + health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)))) * 12 * 1.04)},
        {"year": 3, "cost": round2((social_contribution_calculator(social_base_standard).total + health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)))) * 12 * 1.04 * 1.04)},
        {"year": 4, "cost": round2((social_contribution_calculator(social_base_standard).total + health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)))) * 12 * 1.04 * 1.04 * 1.04)},
        {"year": 5, "cost": round2((social_contribution_calculator(social_base_standard).total + health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)))) * 12 * 1.04 * 1.04 * 1.04 * 1.04)},
    ],
    "_routing": "",
    "_routing_reason": "Symulator ubezpieczeń ZUS na 5 lat",
    "_legal_basis": "Art. 18, art. 22 SUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# INN-14: Optymalizator deklaracji DRA (wybór podstawy w limicie ustawowym).
dra_optimizer := {
    "rule_id": "jdg.p07_zus_macro_innovations.dra_optimizer",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 783,
    "matched": true,
    "current_base": to_number(object.get(input.jdg_entrepreneur, "declared_zus_base", social_base_standard)),
    "min_base": round2(minimum_wage_gross * preferential_base_rate),
    "max_base": round2(social_base_standard * 2),
    "optimal_for_benefits": social_base_standard,
    "_routing": "",
    "_routing_reason": "Optymalizacja podstawy DRA w limicie ustawowym",
    "_legal_basis": "Art. 18 ust. 8, art. 19 SUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# INN-15: Kompleksowy kalkulator ZUS + zdrowotna (pełny pakiet miesięczny).
zus_health_total_calculator := {
    "rule_id": "jdg.p07_zus_macro_innovations.zus_health_total_calculator",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 784,
    "matched": true,
    "social": social_contribution_calculator(social_base_standard),
    "health_scale": health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
    "total_monthly": round2(social_contribution_calculator(social_base_standard).total + health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)))),
    "annual_total": round2((social_contribution_calculator(social_base_standard).total + health_scale_contribution(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)))) * 12),
    "_routing": "",
    "_routing_reason": "Kompletny kalkulator ZUS + zdrowotna per miesiąc",
    "_legal_basis": "Art. 22 SUS; art. 81 ustawy o świadczeniach zdrowotnych",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}

# ── GŁÓWNY DECIDE (P07) — raport syntetyczny ZUS/SUS Macro ────────────────────
decide := {
    "rule_id": "jdg.p07_zus_macro_innovations.report",
    "package": "jdg.p07_zus_macro_innovations",
    "priority": 737,
    "matched": true,
    "health_contribution": health_contribution_audit,
    "social_contribution": social_contribution_audit,
    "benefits": benefits_audit,
    "ppk_pfron_solidarity": ppk_pfron_solidarity_audit,
    "concurrent_titles": concurrent_title_engine,
    "thresholds_snapshot": zus_thresholds_snapshot,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny ZUS/SUS Macro (P07) — składka zdrowotna, społeczne, zasiłki",
    "_legal_basis": "Ustawa SUS (Dz.U. 2025 poz. 345); ustawa o świadczeniach zdrowotnych (Dz.U. 2025 poz. 890); ustawa zasiłkowa",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p07_zus_macro_check", false) == true
}
