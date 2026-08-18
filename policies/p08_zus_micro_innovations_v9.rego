# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P08 GENIALNE POMYSŁY ENTERPRISE (ZUS/SUS Micro — warstwa mikro)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p08_zus_micro_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG MODUŁ ZUS/SUS MICRO (P08) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: Mapa pokrycia artykułów SUS/zdrowotna/zasilkowa (atomowe per
#            artykuł: a6-a47 SUS, a79-a82 zdrowotna, a19-a33 zasiłkowa —
#            status COMPLETE/PARTIAL/MISSING z data.jdg.zus_micro_audit)
#   Sekcja 2: AUDYT ZDROWOTNEJ MIKRO (PRIORYTET) — progi ryczałtowe 60K/300K
#            (60%/100%/180% przeciętnego), stawki 9%/4,9%/9%, minimalne,
#            korekta roczna, składka od nadwyżki + silnik progu ryczałtowego
#            z auto-przeliczeniem (INN-01)
#   Sekcja 3: Audyt zasiłków mikro — okresy wyczekiwania (90 dni), stawki
#            80%/100%, limity, zbieg z pracą, terminy wypłaty
#   Sekcja 4: Audyt duplikatów i martwych reguł — rule_id z
#            data.jdg.zus_micro_audit (duplikaty, stuby, deduplikator,
#            detektor dead-code)
#   Sekcja 5: Audyt spójności micro ↔ macro (P07) — decyzje macro ZUS mają
#            wsparcie atomowe? Priorytety spójne?
#   Sekcja 6: OPA jako rozbudowany system — thresholdy ZUS temporalne
#            i pipeline auto-aktualizacji (ADR-002, zero hardcode)
#   Sekcja 7: 14+ genialnych pomysłów Enterprise (INN-01..INN-14)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R08)
#
# Zgodność: ustawa SUS (Dz.U. 2025 poz. 345), ustawa o świadczeniach
#           zdrowotnych (Dz.U. 2025 poz. 890), ustawa zasiłkowa, ADR-002
#           (progi z data.jdg.thresholds — zero hardcode), ADR-006
#           (_legal_basis w każdej regule).
# package: jdg.p08_zus_micro_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p08_zus_micro_innovations

import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.p08_zus_micro_innovations.no_match","package":"jdg.p08_zus_micro_innovations","priority":999999}

# ── Źródła danych: progi z data.jdg.thresholds.zus (ADR-002 — zero hardcode) ──
thresholds := object.get(data.jdg, "thresholds", {})
zus_limits := object.get(thresholds, "zus", {
    "health_scale_rate": 0.09,                # 9% od dochodu (skala)
    "health_linear_rate": 0.049,              # 4,9% od dochodu (liniowy)
    "health_linear_deduction_limit": 14100,   # PLN/rok max odliczenia (2026)
    "health_lump_tier_1_limit": 60000,        # PLN przychodu — próg 1
    "health_lump_tier_2_limit": 300000,       # PLN przychodu — próg 2
    "health_lump_tier_1_amount": 491.40,      # PLN/mies (60% przeciętnego 2026)
    "health_lump_tier_2_amount": 819.00,      # PLN/mies (100% przeciętnego 2026)
    "health_lump_tier_3_amount": 1474.20,     # PLN/mies (180% przeciętnego 2026)
    "health_tax_card_rate": 0.09,             # 9% od minimalnego (karta)
    "minimum_wage_gross": 4800,               # PLN — minimalne 2026
    "sickness_rate_standard": 0.80,           # 80% podstawy
    "sickness_rate_special": 1.00,            # 100% (ciąża, wypadek w drodze)
    "sickness_waiting_months": 3,             # 90 dni wyczekiwania
    "sickness_annual_limit": 85528,           # PLN/rok limit podstawy (2026)
    "maternity_days": 140,                    # 20 tyg. — podstawowy
})

# ── Pomocnicze zaokrąglenia groszowe (kontrakt groszowy) ──────────────────────
round2(x) = r {
    r := round(x * 100) / 100
}

# ── SEKCJA 1: MAPA POKRYCIA ARTYKUŁÓW ZUS (atomowe per artykuł) ───────────────
# Priorytetowe artykuły: SUS (Dz.U. 2025 poz. 345), zdrowotna (poz. 890),
# zasiłkowa. Status wstrzykiwany przez narzędzie jako data.jdg.zus_micro_audit.
priority_articles_zus := [
    # SUS — podleganie, zbiegi, podstawy, stopy, terminy, obowiązki
    "sus_a6", "sus_a6b", "sus_a9", "sus_a11", "sus_a13", "sus_a14",
    "sus_a18", "sus_a18a", "sus_a18c", "sus_a19", "sus_a22", "sus_a24",
    "sus_a36", "sus_a40", "sus_a47",
    # Zdrowotna — składka 9%/4,9%/ryczałt/karta
    "h_a79", "h_a81", "h_a81b", "h_a81c", "h_a81d", "h_a82",
    # Zasilkowa — okresy, stawki, limity
    "z_a19", "z_a29", "z_a32", "z_a33",
]

zus_micro_article_status(art) = status {
    audit := object.get(data.jdg, "zus_micro_audit", {})
    arts := object.get(audit, "articles", {})
    entry := object.get(arts, art, {})
    entry != {}
    status := object.get(entry, "status", "MISSING")
} else = "MISSING" {
    true
}

zus_micro_coverage_summary := {
    "total": count(priority_articles_zus),
    "complete": count([a | some a in priority_articles_zus; zus_micro_article_status(a) == "COMPLETE"]),
    "partial": count([a | some a in priority_articles_zus; zus_micro_article_status(a) == "PARTIAL"]),
    "missing": count([a | some a in priority_articles_zus; zus_micro_article_status(a) == "MISSING"]),
    "gap_pct": round((count([a | some a in priority_articles_zus; zus_micro_article_status(a) == "MISSING"]) / count(priority_articles_zus)) * 1000) / 10,
}

zus_coverage_report := {
    "rule_id": "jdg.p08_zus_micro_innovations.zus_coverage_report",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 710,
    "matched": true,
    "articles": [{"article": a, "status": zus_micro_article_status(a)} |
        some a in priority_articles_zus
    ],
    "summary": zus_micro_coverage_summary,
    "gaps": [a | some a in priority_articles_zus; zus_micro_article_status(a) == "MISSING"],
    "_routing": "",
    "_routing_reason": "Mapa pokrycia artykułów ZUS mikro (SUS/zdrowotna/zasilkowa)",
    "_legal_basis": "Ustawa SUS (Dz.U. 2025 poz. 345); ustawa o świadczeniach zdrowotnych (Dz.U. 2025 poz. 890); ustawa zasiłkowa",
    "_warnings": [sprintf("Pokrycie ZUS micro: %v%% | COMPLETE %d, PARTIAL %d, MISSING %d", [zus_micro_coverage_summary.gap_pct, zus_micro_coverage_summary.complete, zus_micro_coverage_summary.partial, zus_micro_coverage_summary.missing])],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# ── SEKCJA 2: AUDYT ZDROWOTNEJ MIKRO (POZIOM ENTERPRISE — PRIORYTET) ─────────
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

# Atomowe kalkulatory per forma (groszowe).
zus_health_scale(income) = amount {
    amount := round2(income * health_scale_rate)
}

zus_health_linear(income) = amount {
    amount := round2(income * health_linear_rate)
}

zus_health_lump(revenue) = amount {
    revenue <= health_lump_tier_1_limit
    amount := health_lump_tier_1_amount
} else = amount {
    revenue <= health_lump_tier_2_limit
    amount := health_lump_tier_2_amount
} else = amount {
    amount := health_lump_tier_3_amount
}

zus_health_tax_card = amount {
    amount := round2(minimum_wage_gross * health_tax_card_rate)
}

# Główny audyt zdrowotnej mikro — progi, stawki, minimalne, korekta roczna.
health_micro_audit := {
    "rule_id": "jdg.p08_zus_micro_innovations.health_micro_audit",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 720,
    "matched": true,
    "form": object.get(input.jdg_entrepreneur, "tax_form", "skala"),
    "rates": {
        "skala_9pct": health_scale_rate,
        "liniowy_4p9pct": health_linear_rate,
        "ryczałt_4p9pct": 0.049,
        "karta_9pct_min": health_tax_card_rate,
    },
    "lump_tiers": [
        {"revenue_limit": health_lump_tier_1_limit, "amount": health_lump_tier_1_amount, "share": 0.60},
        {"revenue_limit": health_lump_tier_2_limit, "amount": health_lump_tier_2_amount, "share": 1.00},
        {"revenue_limit": 999999999, "amount": health_lump_tier_3_amount, "share": 1.80},
    ],
    "monthly": {
        "scale": zus_health_scale(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
        "linear": zus_health_linear(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
        "lump": zus_health_lump(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))),
        "tax_card": zus_health_tax_card,
    },
    "minimum_monthly": round2(minimum_wage_gross * health_scale_rate),
    "annual_reconciliation": {
        "annual_income": to_number(object.get(input.jdg_entrepreneur, "annual_income", 0)),
        "due_scale": round2(to_number(object.get(input.jdg_entrepreneur, "annual_income", 0)) * health_scale_rate),
        "advances_paid": to_number(object.get(input.jdg_entrepreneur, "health_advances_paid", 0)),
        "difference": round2(to_number(object.get(input.jdg_entrepreneur, "annual_income", 0)) * health_scale_rate - to_number(object.get(input.jdg_entrepreneur, "health_advances_paid", 0))),
    },
    "excess_contribution": {
        "declared_income": to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)),
        "minimum_base": round2(minimum_wage_gross * health_scale_rate),
        "excess": max([to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)) - round2(minimum_wage_gross * health_scale_rate), 0]),
    },
    "_routing": "",
    "_routing_reason": "Audyt zdrowotnej mikro — progi ryczałtowe, stawki, korekta roczna, składka od nadwyżki (priorytet P08)",
    "_legal_basis": "Art. 79-82 ustawy o świadczeniach zdrowotnych (Dz.U. 2025 poz. 890)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# INN-01: Silnik progu ryczałtowego z auto-przeliczeniem — wykrywa
# przekroczenie progu 60K/300K na podstawie przychodu narastająco i sugeruje
# przełączenie na wyższy próg.
lump_tier_auto_recalc := {
    "rule_id": "jdg.p08_zus_micro_innovations.lump_tier_auto_recalc",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 721,
    "matched": true,
    "projected_revenue": to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)),
    "current_tier": zus_health_lump(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))),
    "next_tier_threshold": health_lump_tier_1_limit,
    "next_tier_amount": health_lump_tier_2_amount,
    "tier_switch_needed": to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) > health_lump_tier_1_limit and to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) <= health_lump_tier_2_limit,
    "annual_impact": round2(health_lump_tier_2_amount * 12 - health_lump_tier_1_amount * 12),
    "_routing": "",
    "_routing_reason": "Auto-przeliczenie progu ryczałtowego składki zdrowotnej",
    "_legal_basis": "Art. 81 ust. 2 pkt 3 ustawy o świadczeniach zdrowotnych",
    "_warnings": [sprintf("Przekroczenie progu 60K — nowa składka: %.2f PLN/mies (delta roczna %.2f PLN)", [health_lump_tier_2_amount, round2(health_lump_tier_2_amount * 12 - health_lump_tier_1_amount * 12)])],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
    to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) > health_lump_tier_1_limit
}

# INN-02: Detektor składki od nadwyżki (nad minimalną).
health_excess_detector := {
    "rule_id": "jdg.p08_zus_micro_innovations.health_excess_detector",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 722,
    "matched": true,
    "monthly_income": to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)),
    "minimum_health": round2(minimum_wage_gross * health_scale_rate),
    "scale_paid": zus_health_scale(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
    "excess_over_min": max([zus_health_scale(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))) - round2(minimum_wage_gross * health_scale_rate), 0]),
    "_routing": "",
    "_routing_reason": "Składka zdrowotna od nadwyżki ponad minimalną",
    "_legal_basis": "Art. 81 ust. 2 pkt 1 ustawy o świadczeniach zdrowotnych",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# ── SEKCJA 3: AUDYT ZASIŁKÓW MIKRO (poziom ENTERPRISE) ───────────────────────
sickness_rate_standard := to_number(object.get(zus_limits, "sickness_rate_standard", 0.80))
sickness_rate_special := to_number(object.get(zus_limits, "sickness_rate_special", 1.00))
sickness_waiting_months := to_number(object.get(zus_limits, "sickness_waiting_months", 3))
sickness_annual_limit := to_number(object.get(zus_limits, "sickness_annual_limit", 85528))
maternity_days := to_number(object.get(zus_limits, "maternity_days", 140))

# Kalkulator zasiłku: podstawa/30 × stawka × dni (podwójne zaokrąglanie wg ZUS).
zus_sickness_benefit(base, rate, days) = amount {
    daily := round2(base / 30)
    amount := round2(daily * rate * days)
}

benefits_micro_audit := {
    "rule_id": "jdg.p08_zus_micro_innovations.benefits_micro_audit",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 740,
    "matched": true,
    "benefit_base": to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)),
    "waiting": {
        "months_required": sickness_waiting_months,
        "insured_months": to_number(object.get(input.jdg_entrepreneur, "insured_months", 0)),
        "eligible": to_number(object.get(input.jdg_entrepreneur, "insured_months", 0)) >= sickness_waiting_months,
        "months_to_go": max([sickness_waiting_months - to_number(object.get(input.jdg_entrepreneur, "insured_months", 0)), 0]),
    },
    "rates": {
        "sickness_80pct": sickness_rate_standard,
        "sickness_100pct": sickness_rate_special,
        "maternity_100pct": 1.00,
        "care_80pct": 0.80,
        "rehab_90pct": 0.90,
    },
    "daily": {
        "sickness_80pct": zus_sickness_benefit(to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)), sickness_rate_standard, 1),
        "sickness_100pct": zus_sickness_benefit(to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)), sickness_rate_special, 1),
        "maternity_100pct": round2(to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)) / 30),
        "rehab_90pct": zus_sickness_benefit(to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)), 0.90, 1),
    },
    "limits": {
        "maternity_days_20wks": maternity_days,
        "sickness_annual_limit": sickness_annual_limit,
        "payment_deadline": "termin wypłaty: 30 dni od złożenia wniosku",
    },
    "_routing": "",
    "_routing_reason": "Audyt zasiłków mikro — okresy wyczekiwania, stawki, limity, terminy wypłaty",
    "_legal_basis": "Ustawa zasiłkowa (art. 4-54)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# INN-03: Kalkulator okresów wyczekiwania (90 dni — klucz dla JDG).
waiting_period_calculator := {
    "rule_id": "jdg.p08_zus_micro_innovations.waiting_period_calculator",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 741,
    "matched": true,
    "insured_months": to_number(object.get(input.jdg_entrepreneur, "insured_months", 0)),
    "required_months": sickness_waiting_months,
    "eligible": to_number(object.get(input.jdg_entrepreneur, "insured_months", 0)) >= sickness_waiting_months,
    "remaining_months": max([sickness_waiting_months - to_number(object.get(input.jdg_entrepreneur, "insured_months", 0)), 0]),
    "_routing": "",
    "_routing_reason": "Kalkulator okresów wyczekiwania do zasiłków",
    "_legal_basis": "Art. 4 ust. 1 ustawy zasiłkowej",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# ── SEKCJA 4: AUDYT DUPLIKATÓW I MARTWYCH REGUŁ (poziom ENTERPRISE) ──────────
# Dane z narzędzia zus_micro_auditor.py wstrzykiwane jako data.jdg.zus_micro_audit.
zus_stub_duplicate_report := {
    "rule_id": "jdg.p08_zus_micro_innovations.zus_stub_duplicate_report",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 750,
    "matched": true,
    "total_rule_ids": object.get(audit_data, "total_rule_ids", 0),
    "unique_rule_ids": object.get(audit_data, "unique_count", 0),
    "duplicates": object.get(audit_data, "duplicates", []),
    "duplicate_count": object.get(audit_data, "duplicate_count", 0),
    "stubs": object.get(audit_data, "stubs", []),
    "stub_count": object.get(audit_data, "stub_count", 0),
    "deduplication_plan": "MERGE_INTO_HIGHEST_PRIORITY (stub → aktywna reguła)",
    "dead_code_detector": "reguły nieosiągalne w else-chain → raportowane do TRIAGE_QUEUE",
    "_routing": "",
    "_routing_reason": "Audyt duplikatów i martwych reguł ZUS mikro (rule_id z MANIFEST)",
    "_legal_basis": "Ustawa SUS (Dz.U. 2025 poz. 345); ADR-006 (rule_id immutable)",
    "_warnings": [sprintf("ZUS micro: reguł %d, unikalnych %d, duplikatów %d, stubów %d", [object.get(audit_data, "total_rule_ids", 0), object.get(audit_data, "unique_count", 0), object.get(audit_data, "duplicate_count", 0), object.get(audit_data, "stub_count", 0)])],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

audit_data := object.get(data.jdg, "zus_micro_audit", {})

# ── SEKCJA 5: AUDYT SPÓJNOŚCI MICRO ↔ MACRO (P07) ────────────────────────────
# Czy decyzje macro ZUS (P07) mają wsparcie atomowe w warstwie micro?
zus_micro_macro_report := {
    "rule_id": "jdg.p08_zus_micro_innovations.zus_micro_macro_report",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 760,
    "matched": true,
    "macro_packages": ["jdg.zus", "jdg.zus.sickness_benefits", "jdg.zus.health_contribution", "jdg.p07_zus_macro_innovations"],
    "micro_coverage": {
        "sus_articles": count([a | some a in ["sus_a6", "sus_a6b", "sus_a9", "sus_a11", "sus_a13", "sus_a14", "sus_a18", "sus_a18a", "sus_a18c", "sus_a19", "sus_a22", "sus_a24", "sus_a36", "sus_a40", "sus_a47"]; zus_micro_article_status(a) != "MISSING"]),
        "health_articles": count([a | some a in ["h_a79", "h_a81", "h_a81b", "h_a81c", "h_a81d", "h_a82"]; zus_micro_article_status(a) != "MISSING"]),
        "benefit_articles": count([a | some a in ["z_a19", "z_a29", "z_a32", "z_a33"]; zus_micro_article_status(a) != "MISSING"]),
    },
    "macro_decisions": {
        "health_contribution": "P720 (P07) — wsparcie atomowe: a79-a82",
        "social_contributions": "P730 (P07) — wsparcie atomowe: a18-a24",
        "benefits": "P740 (P07) — wsparcie atomowe: zasilkowa a19-a33",
        "concurrent_titles": "P760 (P07) — wsparcie atomowe: a6, a9",
    },
    "priority_consistency": "makro P720-P770 ⊃ mikro a6-a47 (decyzje macro mają atomowe wsparcie)",
    "_routing": "",
    "_routing_reason": "Spójność decyzji macro ZUS (P07) ze wsparciem atomowym micro",
    "_legal_basis": "Ustawa SUS (Dz.U. 2025 poz. 345); ustawa o świadczeniach zdrowotnych (Dz.U. 2025 poz. 890)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# INN-04: Atomowy silnik zbiegów tytułów (a6, a9 — podleganie, zbiegi).
atomic_concurrent_title_engine := {
    "rule_id": "jdg.p08_zus_micro_innovations.atomic_concurrent_title_engine",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 761,
    "matched": true,
    "concurrent_title": object.get(input.jdg_entrepreneur, "concurrent_title", "none"),
    "obligation": {
        "social": social_obligation_for(object.get(input.jdg_entrepreneur, "concurrent_title", "none")),
        "health": true,
    },
    "legal_atom": {
        "a6": "podleganie ubezpieczeniom (art. 6 ust. 1 pkt 1-2)",
        "a9": "zbiegi tytułów (art. 9 ust. 1a-2)",
    },
    "_routing": "",
    "_routing_reason": "Atomowy silnik zbiegów tytułów — a6/a9 SUS",
    "_legal_basis": "Art. 6, art. 9 SUS (Dz.U. 2025 poz. 345)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# ── SEKCJA 6: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE TEMPORALNY ──────────────
# Roczne zmiany podstaw i progów — thresholdy ZUS temporalne + auto-aktualizacja
# (ADR-002: dane z data.jdg.thresholds.zus, hot-reload).
zus_micro_pipeline_snapshot := {
    "rule_id": "jdg.p08_zus_micro_innovations.zus_micro_pipeline_snapshot",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 770,
    "matched": true,
    "year": object.get(input.jdg_entrepreneur, "tax_year", 2026),
    "snapshot": {
        "minimum_wage_gross": minimum_wage_gross,
        "health_lump_tier_1_amount": health_lump_tier_1_amount,
        "health_lump_tier_2_amount": health_lump_tier_2_amount,
        "health_lump_tier_3_amount": health_lump_tier_3_amount,
        "health_linear_deduction_limit": health_linear_deduction_limit,
    },
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.zus (ADR-002)",
        "step_2_generate": "reguły atomowe a6-a82 (sus/zdrowotna/zasilkowa)",
        "step_3_verify": "zus_micro_auditor.py — pokrycie, duplikaty, stuby",
        "step_4_emit": "hot-reload pakietów jdg.micro.zus / jdg.micro.health",
    },
    "auto_update": "pipeline auto-aktualizacji przy zmianie rozporządzenia RM (minimalne)",
    "_routing": "",
    "_routing_reason": "Migawka temporalna ZUS micro + pipeline auto-aktualizacji",
    "_legal_basis": "Rozporządzenie RM (minimalne wynagrodzenie); obwieszczenia ZUS; ADR-002",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# Helper: determinacja obowiązku społecznego per zbieg (a6/a9 SUS).
social_obligation_for(title) = false {
    title in ["etat_jdg", "emeryt_jdg", "student_jdg", "urlop_wychowawczy_jdg"]
} else = true {
    true
}

# ── SEKCJA 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-14) ───────────────────
# INN-01: lump_tier_auto_recalc (Sekcja 2) | INN-02: health_excess_detector (Sekcja 2)
# INN-03: waiting_period_calculator (Sekcja 3) | INN-04: atomic_concurrent_title_engine (Sekcja 5)

# INN-05: Temporalny tracker podstaw wymiaru (per miesiąc, 12-mies. projekcja).
temporal_base_tracker := {
    "rule_id": "jdg.p08_zus_micro_innovations.temporal_base_tracker",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 780,
    "matched": true,
    "standard_base": round2(minimum_wage_gross * 2 * 0.60),
    "preferential_base": round2(minimum_wage_gross * 0.30),
    "projection_12m": [
        {"month": m, "base": round2(minimum_wage_gross * 0.30)} |
        some m in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    ],
    "_routing": "",
    "_routing_reason": "Temporalny tracker podstaw wymiaru składek (12 mies.)",
    "_legal_basis": "Art. 18-18c SUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# INN-06: Symulator zdrowotnej per forma (porównanie 4 form atomowo).
health_micro_simulator := {
    "rule_id": "jdg.p08_zus_micro_innovations.health_micro_simulator",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 781,
    "matched": true,
    "income": to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)),
    "revenue": to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)),
    "comparison": {
        "skala": zus_health_scale(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
        "liniowy": zus_health_linear(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))),
        "ryczałt": zus_health_lump(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))),
        "karta": zus_health_tax_card,
    },
    "cheapest": cheapest_micro_form(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)), to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))),
    "_routing": "",
    "_routing_reason": "Symulator składki zdrowotnej per forma (atomowo)",
    "_legal_basis": "Art. 81 ustawy o świadczeniach zdrowotnych",
    "_warnings": [sprintf("Najniższa składka: %s | Skala %.2f | Liniowy %.2f | Ryczałt %.2f | Karta %.2f", [cheapest_micro_form(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0)), to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))), zus_health_scale(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))), zus_health_linear(to_number(object.get(input.jdg_entrepreneur, "monthly_income", 0))), zus_health_lump(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0))), zus_health_tax_card])],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

cheapest_micro_form(income, revenue) = form {
    candidates := [
        {"form": "skala", "amount": zus_health_scale(income)},
        {"form": "liniowy", "amount": zus_health_linear(income)},
        {"form": "ryczałt", "amount": zus_health_lump(revenue)},
        {"form": "karta", "amount": zus_health_tax_card},
    ]
    sorted := sort([[c.amount, c.form] | some c in candidates])
    form := sorted[0][1]
}

# INN-07: Detektor niekonsekwencji rule_id (jdg.zus.* vs jdg.micro.zus.*).
rule_id_inconsistency_detector := {
    "rule_id": "jdg.p08_zus_micro_innovations.rule_id_inconsistency_detector",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 782,
    "matched": true,
    "plan33_uses": object.get(audit_data, "plan33_rule_id_prefix", "jdg.zus"),
    "sus_dir_uses": "jdg.micro.sus",
    "consistent": object.get(audit_data, "plan33_rule_id_prefix", "jdg.zus") == "jdg.micro.zus",
    "note": "plan33_zus.rego używa jdg.zus.a{N} (bez .micro.) — niekonsekwencja vs katalogi sus/zdrowotna/zasilkowa",
    "_routing": "WARNING",
    "_routing_reason": "Niekonsekwentne prefiksy rule_id w warstwie mikro ZUS",
    "_legal_basis": "ADR-006 (rule_id immutable — spójny format)",
    "_warnings": ["plan33_zus.rego: jdg.zus.a{N} vs sus/: jdg.micro.sus.a{N}.r{M} — ujednolić prefiks"],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# INN-08: Automatyczny deduplikator stubów (plan: merge stub → aktywna reguła).
stub_deduplicator := {
    "rule_id": "jdg.p08_zus_micro_innovations.stub_deduplicator",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 783,
    "matched": true,
    "stub_count": object.get(audit_data, "stub_count", 0),
    "duplicate_count": object.get(audit_data, "duplicate_count", 0),
    "plan": "MERGE_INTO_HIGHEST_PRIORITY — stub { true } → aktywna reguła; duplikaty → keep highest priority",
    "_routing": "",
    "_routing_reason": "Automatyczny deduplikator i detektor dead-code ZUS micro",
    "_legal_basis": "ADR-006 (rule_id immutable)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# INN-09: Detektor martwych reguł (else-chain nieosiągalność).
dead_code_detector := {
    "rule_id": "jdg.p08_zus_micro_innovations.dead_code_detector",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 784,
    "matched": true,
    "dead_rules": object.get(audit_data, "dead_rules", []),
    "dead_count": count(object.get(audit_data, "dead_rules", [])),
    "note": "reguły nieosiągalne w else-chain (np. gałąź po else catch-all)",
    "_routing": "",
    "_routing_reason": "Detektor martwych reguł w else-chain ZUS micro",
    "_legal_basis": "ADR-006",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# INN-10: Monitor limitu rocznego podstawy zasiłku (85 528).
benefit_annual_limit_monitor := {
    "rule_id": "jdg.p08_zus_micro_innovations.benefit_annual_limit_monitor",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 785,
    "matched": true,
    "annual_base": to_number(object.get(input.jdg_entrepreneur, "benefit_annual_base", 0)),
    "limit": sickness_annual_limit,
    "exceeded": to_number(object.get(input.jdg_entrepreneur, "benefit_annual_base", 0)) > sickness_annual_limit,
    "excess": max([to_number(object.get(input.jdg_entrepreneur, "benefit_annual_base", 0)) - sickness_annual_limit, 0]),
    "_routing": "WARNING",
    "_routing_reason": "Przekroczenie rocznego limitu podstawy wymiaru zasiłku",
    "_legal_basis": "Art. 36 ustawy zasiłkowej",
    "_warnings": ["Limit roczny podstawy zasiłku przekroczony — nadwyżka nie uwzględniana"],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
    to_number(object.get(input.jdg_entrepreneur, "benefit_annual_base", 0)) > sickness_annual_limit
}

# INN-11: Kalkulator macierzyńskiego per tydzień urlopu (a32 zasiłkowa).
maternity_weeks_calculator := {
    "rule_id": "jdg.p08_zus_micro_innovations.maternity_weeks_calculator",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 786,
    "matched": true,
    "base": to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)),
    "weeks": to_number(object.get(input.jdg_entrepreneur, "maternity_weeks", 20)),
    "days": to_number(object.get(input.jdg_entrepreneur, "maternity_weeks", 20)) * 7,
    "daily": round2(to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)) / 30),
    "total": round2(to_number(object.get(input.jdg_entrepreneur, "benefit_base", 0)) / 30 * to_number(object.get(input.jdg_entrepreneur, "maternity_weeks", 20)) * 7),
    "_routing": "",
    "_routing_reason": "Kalkulator zasiłku macierzyńskiego per tydzień urlopu",
    "_legal_basis": "Art. 32 ustawy zasiłkowej",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# INN-12: Zbieg zasiłku z pracą (a29 zasiłkowa) — zawieszenie przy dochodach.
benefit_work_conflict := {
    "rule_id": "jdg.p08_zus_micro_innovations.benefit_work_conflict",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 787,
    "matched": true,
    "works_during_illness": object.get(input.jdg_entrepreneur, "works_during_illness", false) == true,
    "suspension": object.get(input.jdg_entrepreneur, "works_during_illness", false) == true,
    "note": "Praca zarobkowa w okresie orzeczonej niezdolności zawiesza zasiłek (art. 29 zasiłkowa)",
    "_routing": "WARNING",
    "_routing_reason": "Konflikt zasiłku z pracą zarobkową — zawieszenie",
    "_legal_basis": "Art. 29 ustawy zasiłkowej",
    "_warnings": ["Praca w okresie zwolnienia lekarskiego — zasiłek zawieszony"],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
    object.get(input.jdg_entrepreneur, "works_during_illness", false) == true
}

# INN-13: Terminy wypłaty zasiłków (a33 zasiłkowa — 30 dni od wniosku).
benefit_payment_deadline := {
    "rule_id": "jdg.p08_zus_micro_innovations.benefit_payment_deadline",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 788,
    "matched": true,
    "deadline_days": 30,
    "note": "Zasiłek wypłacany w terminie 30 dni od wyjaśnienia okoliczności (art. 33 zasiłkowa)",
    "_routing": "",
    "_routing_reason": "Terminy wypłaty zasiłków (art. 33 zasiłkowa)",
    "_legal_basis": "Art. 33 ustawy zasiłkowej",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# INN-14: Auto-aktualizacja thresholdów (pipeline temporalny — hook hot-reload).
temporal_pipeline_hook := {
    "rule_id": "jdg.p08_zus_micro_innovations.temporal_pipeline_hook",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 789,
    "matched": true,
    "source": "data.jdg.thresholds.zus (ADR-002)",
    "trigger": "zmiana rozporządzenia RM / obwieszczenia ZUS",
    "steps": ["ingest", "generate", "verify", "emit"],
    "hot_reload": true,
    "_routing": "",
    "_routing_reason": "Hook auto-aktualizacji thresholdów ZUS temporalnych",
    "_legal_basis": "ADR-002 (dane temporalne); rozporządzenie RM",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}

# ── GŁÓWNY DECIDE (P08) — raport syntetyczny ZUS/SUS Micro ────────────────────
decide := {
    "rule_id": "jdg.p08_zus_micro_innovations.report",
    "package": "jdg.p08_zus_micro_innovations",
    "priority": 737,
    "matched": true,
    "coverage": zus_coverage_report,
    "health_micro": health_micro_audit,
    "benefits_micro": benefits_micro_audit,
    "stub_duplicates": zus_stub_duplicate_report,
    "micro_macro": zus_micro_macro_report,
    "pipeline": zus_micro_pipeline_snapshot,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny ZUS/SUS Micro (P08) — pokrycie, zdrowotna mikro, zasiłki",
    "_legal_basis": "Ustawa SUS (Dz.U. 2025 poz. 345); ustawa o świadczeniach zdrowotnych (Dz.U. 2025 poz. 890); ustawa zasiłkowa",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p08_zus_micro_check", false) == true
}
