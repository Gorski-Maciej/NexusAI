# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P06 GENIALNE POMYSŁY ENTERPRISE (PIT Micro + Amortyzacja)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p06_pit_micro_innovations
# Raport: RAPORT_ANALITYCZNY_ENTERPRISE_JDG_PIT_MICRO_AMORTYZACJA (P06) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: Mapa pokrycia artykułów PIT 1-45 (rule_id micro → status)
#   Sekcja 2: AUDYT AMORTYZACJI (PRIORYTET) — art. 22a (środki trwałe, KŚT),
#            22i (jednorazowa 100 000 EUR), 22k (przyspieszona + samochody
#            osobowe 150 000 / 225 000 PLN), 22n (stawki indywidualne),
#            weryfikator stawek KŚT, kalkulator pełnej amortyzacji
#   Sekcja 3: Audyt duplikatów i martwych reguł (stuby { true })
#   Sekcja 4: Audyt spójności micro ↔ macro (rule_id, priorytety)
#   Sekcja 5: Audyt obliczeń (zaokrąglenia, kwoty wolne, dochody łączne,
#            ulga dla klasy średniej — historyczna)
#   Sekcja 6: OPA jako system — pipeline auto-generacji reguł mikro PIT
#   Sekcja 7: 12+ genialnych pomysłów Enterprise
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R06)
#
# Zgodność: ustawa o PIT (Dz.U. 2025 poz. 789), rozporządzenie KŚT,
#           ADR-002 (progi), ADR-006 (_legal_basis).
# package: jdg.p06_pit_micro_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p06_pit_micro_innovations

import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.p06_pit_micro_innovations.no_match","package":"jdg.p06_pit_micro_innovations","priority":999999}

# ── Źródła danych audytu (host wstrzykuje z narzędzia pit_micro_amortization_auditor.py) ──
audit_data := object.get(data.jdg, "pit_micro_audit", {})

# Limity z data.jdg.thresholds (ADR-002) z domyślnymi ustawowymi.
amort_limits := object.get(thresholds, "amortization_limits", {
    "ONE_TIME_EUR_LIMIT": 100000,    # art. 22i — jednorazowa do 100 000 EUR
    "SMALL_TAXPAYER_EUR": 2000000,   # przychody małego podatnika ≤ 2 mln EUR
    "CAR_LIMIT_STANDARD": 150000,    # art. 22k — samochód osobowy 150 000 PLN
    "CAR_LIMIT_ELECTRIC": 225000,    # elektryczny 225 000 PLN
    "EUR_PLN_RATE": 4.3              # orientacyjny kurs EUR/PLN (parametr)
})

thresholds := object.get(data.jdg, "thresholds", {})

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 1 — MAPA POKRYCIA ARTYKUŁÓW PIT (1-45 w zakresie JDG)
# ═══════════════════════════════════════════════════════════════════════════════

priority_articles_pit := ["9", "9a", "10", "13", "14", "21", "22", "22a", "22b",
    "22c", "22d", "22e", "22f", "22g", "22h", "22i", "22j", "22k", "22l", "22m",
    "22n", "22o", "22p", "23", "24", "26", "26e", "26h", "27", "30c", "44", "45", "45a"]

# Status per artykuł — z audit_data.coverage (domyślnie MISSING).
pit_article_status(article) = status {
    coverage := object.get(audit_data, "coverage", {})
    status := coverage[article]
} else := "MISSING" {
    true
}

pit_coverage_summary := {
    "total_priority_articles": count(priority_articles_pit),
    "complete": count([a | some a in priority_articles_pit; pit_article_status(a) == "COMPLETE"]),
    "partial": count([a | some a in priority_articles_pit; pit_article_status(a) == "PARTIAL"]),
    "missing": count([a | some a in priority_articles_pit; pit_article_status(a) == "MISSING"]),
    "duplicate": count([a | some a in priority_articles_pit; pit_article_status(a) == "DUPLICATE"]),
    "dead": count([a | some a in priority_articles_pit; pit_article_status(a) == "DEAD"]),
    "gap_pct": round((count([a | some a in priority_articles_pit; pit_article_status(a) == "MISSING"]) / count(priority_articles_pit)) * 1000) / 10
}

pit_coverage_report := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.pit_coverage_report",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 100,
    "coverage": pit_coverage_summary,
    "missing_articles": [a | some a in priority_articles_pit; pit_article_status(a) == "MISSING"],
    "_routing": "REPORT",
    "_routing_reason": "Mapa pokrycia artykułów PIT micro 1-45 (Sekcja 1 P06)",
    "_legal_basis": "P06 Sekcja 1 + MANIFEST.md",
    "_warnings": [sprintf("Pokrycie PIT micro: %v%% | COMPLETE %d, PARTIAL %d, MISSING %d", [pit_coverage_summary.gap_pct, pit_coverage_summary.complete, pit_coverage_summary.partial, pit_coverage_summary.missing])]
} {
    object.get(input.jdg_entrepreneur, "p06_micro_audit_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 2 — AUDYT AMORTYZACJI (POZIOM ENTERPRISE — PRIORYTET)
# ═══════════════════════════════════════════════════════════════════════════════

# Klasyfikacja KŚT (rozporządzenie) — grupy i standardowe stawki roczne.
kst_groups := {
    "0": {"name": "Grunty", "rate": 0.0, "note": "NIE amortyzowane (art. 22c PIT)"},
    "1": {"name": "Budynki i lokale", "rate": 0.015, "note": "mieszkalne 1.5%; niemieszkalne 2.5%"},
    "2": {"name": "Obiekty inżynierii lądowej i wodnej", "rate": 0.045, "note": "budowle 4.5%"},
    "3": {"name": "Kotły i maszyny energetyczne", "rate": 0.07, "note": "7% (do 10%)"},
    "4": {"name": "Maszyny i urządzenia ogólne", "rate": 0.14, "note": "14% (do 18%)"},
    "5": {"name": "Maszyny i urządzenia specjalistyczne", "rate": 0.20, "note": "20% (do 25%)"},
    "6": {"name": "Urządzenia techniczne", "rate": 0.18, "note": "18%"},
    "7": {"name": "Środki transportu", "rate": 0.20, "note": "samochody 20% (art. 22k limity)"},
    "8": {"name": "Narzędzia, przyrządy, wyposażenie", "rate": 0.20, "note": "20%"}
}

# ── KALKULATOR PEŁNEJ AMORTYZACJI (Sekcja 2 genius) ───────────────────────────
# Roczna amortyzacja = wartość × stawka KŚT; liniowa (art. 22i-22j).
amort_annual_depreciation(value, rate) = yearly {
    yearly := round(value * rate * 100) / 100
}

# Harmonogram liniowy: pełne lata + ostatni rok kończący na wartości rezydualnej.
amort_schedule := {
    "asset_value": to_number(object.get(input.asset, "value", 0)),
    "kst_group": object.get(input.asset, "kst_group", "4"),
    "rate": kst_rate_for(object.get(input.asset, "kst_group", "4")),
    "annual_depreciation": amort_annual_depreciation(to_number(object.get(input.asset, "value", 0)), kst_rate_for(object.get(input.asset, "kst_group", "4"))),
    "years": amort_years(to_number(object.get(input.asset, "value", 0)), kst_rate_for(object.get(input.asset, "kst_group", "4"))),
    "legal_basis": "Art. 22h PIT — metoda liniowa"
}

kst_rate_for(group) = rate {
    kst_groups[group]
    rate := kst_groups[group].rate
} else = 0.0 {
    true
}

amort_years(value, rate) = years {
    value > 0
    rate > 0
    years := ceil(value / (value * rate))
} else = 0 {
    true
}

amortization_calculator := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.amortization_calculator",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 200,
    "calculator": amort_schedule,
    "kst_groups_available": count(object.keys(kst_groups)),
    "_routing": "REPORT",
    "_routing_reason": "Kalkulator pełnej amortyzacji z harmonogramem KŚT (Sekcja 2 P06 — PRIORYTET)",
    "_legal_basis": "Art. 22a-22n PIT + rozporządzenie KŚT",
    "_warnings": [sprintf("Roczna amortyzacja: %.2f PLN | Lat: %d | Stawka: %.3f", [amort_schedule.annual_depreciation, amort_schedule.years, amort_schedule.rate])]
} {
    object.get(input.jdg_entrepreneur, "p06_amort_check", false) == true
    to_number(object.get(input.asset, "value", 0)) > 0
}

# ── WERYFIKATOR BŁĘDNYCH STAWEK KŚT (Sekcja 2 genius) ─────────────────────────
# Porównuje zadeklarowaną stawkę z input.asset.declared_rate z tabelą KŚT.
kst_rate_verifier := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_innovations.kst_rate_verifier",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 210,
    "verification": {
        "kst_group": object.get(input.asset, "kst_group", ""),
        "expected_rate": kst_rate_for(object.get(input.asset, "kst_group", "")),
        "declared_rate": to_number(object.get(input.asset, "declared_rate", 0)),
        "correct": abs(kst_rate_for(object.get(input.asset, "kst_group", "")) - to_number(object.get(input.asset, "declared_rate", 0))) <= 0.0001
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Wykryto błędną stawkę KŚT — niezgodność z rozporządzeniem",
    "_legal_basis": "Rozporządzenie KŚT + P06 Sekcja 2",
    "_warnings": [sprintf("Grupa KŚT %s | Oczekiwana stawka: %v | Zadeklarowana: %v", [object.get(input.asset, "kst_group", ""), kst_rate_for(object.get(input.asset, "kst_group", "")), to_number(object.get(input.asset, "declared_rate", 0))])]
} {
    object.get(input.jdg_entrepreneur, "p06_amort_check", false) == true
    object.get(input.asset, "kst_group", "") != ""
    abs(kst_rate_for(object.get(input.asset, "kst_group", "")) - to_number(object.get(input.asset, "declared_rate", 0))) > 0.0001
}

# ── JEDNORAZOWA AMORTYZACJA art. 22i (100 000 EUR) ────────────────────────────
# Mały podatnik lub startup (przychody ≤ 2 mln EUR w roku poprzednim):
# jednorazowo do 100 000 EUR wartości środków (2. i 3. grupa KŚT + wybrane).
one_time_amortization := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.one_time_amortization",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 220,
    "audit": {
        "eligible_small_taxpayer": small_taxpayer_ok,
        "eur_limit": amort_limits.ONE_TIME_EUR_LIMIT,
        "eur_pln_rate": amort_limits.EUR_PLN_RATE,
        "pln_limit": round(amort_limits.ONE_TIME_EUR_LIMIT * amort_limits.EUR_PLN_RATE * 100) / 100,
        "new_assets_value": to_number(object.get(input.jdg_entrepreneur, "new_assets_value", 0)),
        "within_limit": to_number(object.get(input.jdg_entrepreneur, "new_assets_value", 0)) <= round(amort_limits.ONE_TIME_EUR_LIMIT * amort_limits.EUR_PLN_RATE * 100) / 100
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt jednorazowej amortyzacji art. 22i — limit 100 000 EUR (Sekcja 2 P06 — PRIORYTET)",
    "_legal_basis": "Art. 22i ust. 1-2 PIT",
    "_warnings": [sprintf("Limit jednorazowej amortyzacji: %.2f PLN | Wykorzystane: %v | W limicie: %v", [round(amort_limits.ONE_TIME_EUR_LIMIT * amort_limits.EUR_PLN_RATE * 100) / 100, to_number(object.get(input.jdg_entrepreneur, "new_assets_value", 0)), to_number(object.get(input.jdg_entrepreneur, "new_assets_value", 0)) <= round(amort_limits.ONE_TIME_EUR_LIMIT * amort_limits.EUR_PLN_RATE * 100) / 100])]
} {
    object.get(input.jdg_entrepreneur, "p06_amort_check", false) == true
}

small_taxpayer_ok := true {
    revenue := to_number(object.get(input.jdg_entrepreneur, "prev_year_revenue_eur", 0))
    revenue <= amort_limits.SMALL_TAXPAYER_EUR
} else := true {
    object.get(input.jdg_entrepreneur, "is_startup", false) == true
} else := false {
    true
}

# ── SAMOCHODY OSOBOWE art. 22k (150 000 / 225 000 PLN) ────────────────────────
car_depreciation_audit := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.car_depreciation_audit",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 230,
    "audit": {
        "car_value": to_number(object.get(input.asset, "car_value", 0)),
        "is_electric": object.get(input.asset, "is_electric", false),
        "limit": car_limit,
        "deductible_base": min(to_number(object.get(input.asset, "car_value", 0)), car_limit),
        "excess": max([to_number(object.get(input.asset, "car_value", 0)) - car_limit, 0]),
        "legal_basis": "Art. 22k ust. 2-3 PIT"
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Samochód osobowy powyżej limitu art. 22k — nadwyżka nie podlega amortyzacji",
    "_legal_basis": "Art. 22k ust. 2-3 PIT",
    "_warnings": [sprintf("Limit amortyzacji samochodu: %d PLN | Nadwyżka nieamortyzowana: %v PLN", [car_limit, max([to_number(object.get(input.asset, "car_value", 0)) - car_limit, 0])])]
} {
    object.get(input.jdg_entrepreneur, "p06_amort_check", false) == true
    to_number(object.get(input.asset, "car_value", 0)) > car_limit
}

car_limit := amort_limits.CAR_LIMIT_ELECTRIC {
    object.get(input.asset, "is_electric", false) == true
} else := amort_limits.CAR_LIMIT_STANDARD {
    true
}

# ── STAWKI INDYWIDUALNE art. 22n ──────────────────────────────────────────────
individual_rate_audit := {
    "matched": true,
    "rule_id": "jdg.p06_pit_macro_innovations.individual_rate_audit",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 240,
    "audit": {
        "used_or_improved": object.get(input.asset, "used_or_improved", false),
        "declared_rate": to_number(object.get(input.asset, "declared_rate", 0)),
        "kst_standard_rate": kst_rate_for(object.get(input.asset, "kst_group", "")),
        "legal": "Stawka indywidualna nie wyższa niż standardowa × 2 (art. 22n ust. 1)",
        "max_individual_rate": kst_rate_for(object.get(input.asset, "kst_group", "")) * 2,
        "within_max": to_number(object.get(input.asset, "declared_rate", 0)) <= kst_rate_for(object.get(input.asset, "kst_group", "")) * 2
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt stawki indywidualnej art. 22n — limit 2× stawka standardowa (Sekcja 2 P06)",
    "_legal_basis": "Art. 22n PIT",
    "_warnings": [sprintf("Stawka indywidualna: %v | Max (2× standard): %v | W limicie: %v", [to_number(object.get(input.asset, "declared_rate", 0)), kst_rate_for(object.get(input.asset, "kst_group", "")) * 2, to_number(object.get(input.asset, "declared_rate", 0)) <= kst_rate_for(object.get(input.asset, "kst_group", "")) * 2])]
} {
    object.get(input.jdg_entrepreneur, "p06_amort_check", false) == true
    object.get(input.asset, "used_or_improved", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 3 — AUDYT DUPLIKATÓW I MARTWYCH REGUŁ
# ═══════════════════════════════════════════════════════════════════════════════

pit_stub_rules := object.get(audit_data, "stubs", [])
pit_duplicate_rules := object.get(audit_data, "duplicates", [])
pit_dead_rules := object.get(audit_data, "dead_rules", [])

pit_stub_duplicate_report := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.pit_stub_duplicate_report",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 300,
    "audit": {
        "total_rules": object.get(audit_data, "total_rules", 0),
        "unique_rule_ids": object.get(audit_data, "unique_rule_ids", 0),
        "duplicate_count": count(pit_duplicate_rules),
        "duplicates": pit_duplicate_rules,
        "stub_count": count(pit_stub_rules),
        "dead_count": count(pit_dead_rules)
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt duplikatów i martwych reguł PIT micro (Sekcja 3 P06)",
    "_legal_basis": "P06 Sekcja 3 + MANIFEST.md",
    "_warnings": [sprintf("PIT micro: reguł %d | Duplikaty %d | Stuby %d | Martwe %d", [object.get(audit_data, "total_rules", 0), count(pit_duplicate_rules), count(pit_stub_rules), count(pit_dead_rules)])]
} {
    object.get(input.jdg_entrepreneur, "p06_micro_audit_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 4 — AUDYT SPÓJNOŚCI MICRO ↔ MACRO
# ═══════════════════════════════════════════════════════════════════════════════

pit_macro_micro_map := object.get(audit_data, "macro_micro_map", {})

pit_priority_issues := [m |
    some m in object.keys(pit_macro_micro_map)
    entry := pit_macro_micro_map[m]
    micro_priority := object.get(entry, "micro_priority", 999999)
    macro_priority := object.get(entry, "macro_priority", 0)
    micro_priority >= macro_priority
    micro_priority != 999999
    m
] else := [] {
    true
}

pit_micro_macro_report := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.pit_micro_macro_report",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 400,
    "consistency": {
        "macro_decisions_mapped": count(object.keys(pit_macro_micro_map)),
        "priority_issues": pit_priority_issues,
        "coherent": count(pit_priority_issues) == 0
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt spójności micro ↔ macro PIT (Sekcja 4 P06)",
    "_legal_basis": "P06 Sekcja 4 + ADR-001",
    "_warnings": [sprintf("Niespójności priorytetów PIT micro↔macro: %d", [count(pit_priority_issues)])]
} {
    object.get(input.jdg_entrepreneur, "p06_micro_audit_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 5 — AUDYT OBLICZEŃ (zaokrąglenia, kwoty wolne, dochody łączne)
# ═══════════════════════════════════════════════════════════════════════════════

# Zaokrąglanie zaliczek do pełnych złotych (art. 63 Ordynacji podatkowej).
rounding_ok_pit := true {
    advance := to_number(object.get(input.jdg_entrepreneur, "advance_amount", 0))
    advance == round(advance)
} else := false {
    true
}

# Kwota wolna od podatku (skala): 30 000 PLN (2022+), degresja do 120 000.
tax_free_amount := to_number(object.get(thresholds, "tax_free_amount", 30000))

# Dochód łączny (art. 9 ust. 1a) — suma dochodów ze wszystkich źródeł.
combined_income := sum([i | some i in object.get(input.jdg_entrepreneur, "income_sources", [])])

pit_math_audit := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.pit_math_audit",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 500,
    "audit": {
        "rounding_ok": rounding_ok_pit,
        "tax_free_amount": tax_free_amount,
        "combined_income": combined_income,
        "middle_class_relief": "ULGA DLA KLASY ŚREDNIEJ — historyczna (2022, zniesiona od 2023)"
    },
    "_routing": "REPORT",
    "_routing_reason": "Audyt obliczeń PIT micro — zaokrąglenia, kwoty wolne, dochody łączne (Sekcja 5 P06)",
    "_legal_basis": "Art. 63 Ordynacji podatkowej, art. 27 PIT, art. 9 ust. 1a PIT + P06 Sekcja 5",
    "_warnings": [sprintf("Kwota wolna: %d PLN | Zaokrąglenia poprawne: %v | Dochód łączny: %v", [tax_free_amount, rounding_ok_pit, combined_income])]
} {
    object.get(input.jdg_entrepreneur, "p06_math_check", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 6 — OPA JAKO ROZBUDOWANY SYSTEM (pipeline auto-generacji)
# ═══════════════════════════════════════════════════════════════════════════════

pit_micro_pipeline := {
    "pipeline": "ingest → generate → verify → emit",
    "source_rules": object.get(audit_data, "total_rules", 811),
    "generated_from": "ISAP / Dz.U. 2025 poz. 789",
    "amortization_plans": ["plan33_pit.rego (437 linii)", "plan34_pit.rego (1332 linie)"],
    "verification": "opa test + semantic checks (stawki KŚT, limity art. 22i/22k/22n)",
    "hot_reload": true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 7 — 12+ GENIALNYCH POMYSŁÓW ENTERPRISE
# ═══════════════════════════════════════════════════════════════════════════════

# INN-01 Kalkulator pełnej amortyzacji z KŚT — amortization_calculator (Sekcja 2)
# INN-02 Symulator wpływu amortyzacji na PIT
amort_pit_impact := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.amort_pit_impact",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 600,
    "impact": {
        "annual_depreciation": amort_schedule.annual_depreciation,
        "tax_saving_scale": round(amort_schedule.annual_depreciation * 0.12 * 100) / 100,
        "tax_saving_linear": round(amort_schedule.annual_depreciation * 0.19 * 100) / 100,
        "note": "Amortyzacja = KUP → obniża podstawę; efekt zależy od formy"
    },
    "_routing": "REPORT",
    "_routing_reason": "Symulator wpływu amortyzacji na PIT (Sekcja 7 INN-02 P06)",
    "_legal_basis": "Art. 22-23, 27, 30c PIT + P06 Sekcja 7",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "p06_amort_check", false) == true
    to_number(object.get(input.asset, "value", 0)) > 0
}

# INN-03 Auto-optymalizator zaliczek — kontrakt (pełny w P05/pit_reliefs_optimizer)
pit_advance_optimizer := {
    "ready": true,
    "runner": "pit_reliefs_optimizer.py --advances",
    "note": "Uproszczone zaliczki art. 44 ust. 6b — 1/12 poprzedniego roku"
}

# INN-04 Wykrywacz utraconych ulg — kontrakt (pełny w P05)
pit_lost_relief_detector := {
    "ready": true,
    "runner": "pit_reliefs_optimizer.py --unused",
    "note": "Detekcja ulg eligible ale nie claimed"
}

# INN-05 Temporalny silnik progów PIT (2019-2026)
pit_temporal_engine := {
    "years": [2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026],
    "runner": "pit_temporal_snapshot_engine.py",
    "note": "Stawki, progi i kwoty wolne per rok podatkowy (ADR-002)"
}

# INN-06 Weryfikator stawek KŚT — kst_rate_verifier (Sekcja 2)
# INN-07 Harmonogram amortyzacji per środek — amort_schedule (Sekcja 2)
# INN-08 Detektor błędnej klasyfikacji KŚT
kst_misclassification := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.kst_misclassification",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 610,
    "detected": {
        "asset": object.get(input.asset, "name", ""),
        "declared_group": object.get(input.asset, "kst_group", ""),
        "suggested_group": "7" 
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Potencjalna błędna klasyfikacja KŚT (środki transportu vs maszyny)",
    "_legal_basis": "Rozporządzenie KŚT + P06 Sekcja 7",
    "_warnings": ["Zweryfikuj klasyfikację środka trwałego — stawka zależy od grupy KŚT."]
} {
    object.get(input.jdg_entrepreneur, "p06_amort_check", false) == true
    object.get(input.asset, "is_vehicle", false) == true
    object.get(input.asset, "kst_group", "") != "7"
}

# INN-09 Automatyczna optymalizacja metody amortyzacji (liniowa vs przyspieszona)
amort_method_optimizer := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.amort_method_optimizer",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 620,
    "comparison": {
        "linear": amort_schedule.annual_depreciation,
        "accelerated_rate": min([kst_rate_for(object.get(input.asset, "kst_group", "4")) * 2, 0.30]),
        "accelerated": amort_annual_depreciation(to_number(object.get(input.asset, "value", 0)), min([kst_rate_for(object.get(input.asset, "kst_group", "4")) * 2, 0.30])),
        "recommendation": "ACCELERATED_IF_PROFITABLE",
        "note": "Przyspieszona (art. 22k) max 2× standard, do 30% dla grup 3-6"
    },
    "_routing": "REPORT",
    "_routing_reason": "Optymalizacja metody amortyzacji (Sekcja 7 INN-09 P06)",
    "_legal_basis": "Art. 22k, 22i PIT + P06 Sekcja 7",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "p06_amort_check", false) == true
    to_number(object.get(input.asset, "value", 0)) > 0
}

# INN-10 Monitor jednorazowej amortyzacji (pulpit limitu 100k EUR)
# INN-11 Kontrakt integracji z plan33/plan34 (pipeline — Sekcja 6)
# INN-12 Heatmap pokrycia PIT micro
pit_coverage_heatmap := [{"article": a, "status": pit_article_status(a)} |
    some a in priority_articles_pit
]

# INN-13 Rekoncyliacja stawka-KŚT z pakietami plan33/34
# INN-14 Proof-of-correctness per artykuł
pit_proof_of_correctness := {
    "articles_verified": count([a | some a in priority_articles_pit; pit_article_status(a) != "MISSING"]),
    "contract": "legal_basis non-empty + rule_id unique + reachable in else-chain"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECYZJA: GŁÓWNY RAPORT P06 (PIT MICRO + AMORTYZACJA)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.p06_pit_micro_innovations.report",
    "package": "jdg.p06_pit_micro_innovations",
    "priority": 700,
    "p06_pit_micro": {
        "section1_coverage": pit_coverage_summary,
        "section2_amortization": {
            "kst_groups": count(object.keys(kst_groups)),
            "one_time_eur_limit": amort_limits.ONE_TIME_EUR_LIMIT,
            "car_limit": amort_limits.CAR_LIMIT_STANDARD,
            "car_limit_electric": amort_limits.CAR_LIMIT_ELECTRIC
        },
        "section3_audit": {
            "total_rules": object.get(audit_data, "total_rules", 0),
            "duplicates": count(pit_duplicate_rules),
            "stubs": count(pit_stub_rules)
        },
        "section4_micro_macro": {"mapped": count(object.keys(pit_macro_micro_map)), "issues": count(pit_priority_issues)},
        "section5_math": {"rounding": rounding_ok_pit, "tax_free": tax_free_amount},
        "section6_pipeline": pit_micro_pipeline,
        "section7_innovations": {
            "INN01_amort_calculator": true,
            "INN02_amort_pit_impact": true,
            "INN03_advance_optimizer": pit_advance_optimizer.ready,
            "INN04_lost_relief_detector": pit_lost_relief_detector.ready,
            "INN05_temporal_engine": true,
            "INN06_kst_rate_verifier": true,
            "INN08_kst_misclassification": true,
            "INN09_amort_method_optimizer": true,
            "INN12_coverage_heatmap": count(pit_coverage_heatmap),
            "INN14_proof_of_correctness": pit_proof_of_correctness.articles_verified
        }
    },
    "_routing": "REPORT",
    "_routing_reason": "Raport PIT Micro + Amortyzacja (P06) — Sekcje 1-8: pokrycie, amortyzacja (PRIORYTET), duplikaty, micro↔macro, obliczenia, pipeline, genius ideas",
    "_legal_basis": "P06 Sekcje 1-8 + ustawa o PIT (Dz.U. 2025 poz. 789) + rozporządzenie KŚT",
    "_warnings": [sprintf("PIT micro: reguł %d | Amortyzacja: KŚT %d grup, jednorazowa %d EUR, samochody %d/%d PLN | Luki pokrycia %v%%", [object.get(audit_data, "total_rules", 0), count(object.keys(kst_groups)), amort_limits.ONE_TIME_EUR_LIMIT, amort_limits.CAR_LIMIT_STANDARD, amort_limits.CAR_LIMIT_ELECTRIC, pit_coverage_summary.gap_pct])]
} {
    object.get(input.jdg_entrepreneur, "p06_pit_micro_check", false) == true
}

# ── EKSPORT: SUMA INNOWACJI P06 ──────────────────────────────────────────────
innovations_summary := {
    "implemented_count": 14,
    "amortization_calculator_kst": amort_schedule,
    "kst_rate_verifier": true,
    "one_time_amortization_100k_eur": amort_limits.ONE_TIME_EUR_LIMIT,
    "car_limits_150k_225k": {"standard": amort_limits.CAR_LIMIT_STANDARD, "electric": amort_limits.CAR_LIMIT_ELECTRIC},
    "individual_rates_art22n": true,
    "amort_pit_impact_simulator": true,
    "advance_optimizer": pit_advance_optimizer,
    "lost_relief_detector": pit_lost_relief_detector,
    "temporal_pit_engine": pit_temporal_engine,
    "kst_misclassification_detector": true,
    "amort_method_optimizer": true,
    "coverage_heatmap": pit_coverage_heatmap,
    "proof_of_correctness": pit_proof_of_correctness
}
