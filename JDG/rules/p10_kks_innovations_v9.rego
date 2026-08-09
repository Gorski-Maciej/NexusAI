# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P10 GENIALNE POMYSŁY ENTERPRISE (KKS — Kodeks Karny Skarbowy)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p10_kks_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG MODUŁ KKS (P10) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: Mapa pokrycia artykułów KKS — art. 16-83 (473 reguły micro)
#            + status COMPLETE/PARTIAL/MISSING z data.jdg.kks_audit
#   Sekcja 2: AUDYT GRADACJI KAR (PRIORYTET) — typy czynów art. 54-83,
#            stawki dzienne (1/30 min. wynagrodzenia), mnożniki 720/240,
#            okoliczności obciążające/łagodzące, recydywa, mała wartość
#            + KALKULATOR KARY z pełnym uzasadnieniem (INN-01)
#            + SILNIK MINIMALIZACJI KARY — 4-ścieżkowy decision tree (INN-02)
#            + symulator ryzyka karno-skarbowego (INN-03)
#   Sekcja 3: Czynny żal (art. 16) i dobrowolne poddanie się (art. 17) +
#            asystent "czy warto złożyć czynny żal" (INN-04)
#   Sekcja 4: Przedawnienie (art. 44) i zatarcie skazania (art. 45) +
#            kalendarz przedawnień + tracker zatarcia (INN-05)
#   Sekcja 5: Spójność micro ↔ macro i duplikaty (MANIFEST 369 duplikatów,
#            stuby { true }, martwe reguły) — INN-07/INN-08/INN-09
#   Sekcja 6: OPA jako rozbudowany system — pipeline auto-aktualizacji
#            sankcji i progów (ADR-002, hot-reload) — INN-11
#   Sekcja 7: 12+ genialnych pomysłów Enterprise (INN-01..INN-12)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R10)
#
# Zgodność: KKS (Dz.U. 2025 poz. 678), art. 16, 17, 19, 37, 44, 45, 53-83,
#           ADR-002 (progi z data.jdg.thresholds — zero hardcode), ADR-006.
# package: jdg.p10_kks_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p10_kks_innovations

import future.keywords.in
import future.keywords.if

default decide := {"matched": false, "rule_id": "jdg.p10_kks_innovations.no_match", "package": "jdg.p10_kks_innovations", "priority": 999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
kks_limits := object.get(thresholds, "kks", {
    "min_wage": 4800.0,                 # minimalne wynagrodzenie 2026 (PLN)
    "daily_rate_denominator": 30,       # stawka dzienna = 1/30 min. wynagrodzenia
    "daily_rate_max_multiple": 400,     # maksymalna stawka dzienna 400×
    "crime_threshold_multiple": 200,    # próg przestępstwo/wykroczenie 200×
    "mandatory_prison_threshold": 5000000,  # >5M → obligatoryjne PW (art. 62 §3)
    "max_rates_crime": 720,             # max stawek dziennych — przestępstwo
    "max_rates_misdemeanor": 240,       # max stawek dziennych — wykroczenie
    "limitation_years_crime": 5,        # przedawnienie przestępstwa (art. 44)
    "limitation_years_misdemeanor": 3,  # przedawnienie wykroczenia (art. 44)
})

kks_min_wage := to_number(object.get(kks_limits, "min_wage", 4800.0))
kks_daily_rate_min := round2(kks_min_wage / to_number(object.get(kks_limits, "daily_rate_denominator", 30)))
kks_daily_rate_max := kks_min_wage * to_number(object.get(kks_limits, "daily_rate_max_multiple", 400))
kks_crime_threshold := kks_min_wage * to_number(object.get(kks_limits, "crime_threshold_multiple", 200))
kks_max_rates_crime := to_number(object.get(kks_limits, "max_rates_crime", 720))
kks_max_rates_misdemeanor := to_number(object.get(kks_limits, "max_rates_misdemeanor", 240))
kks_mandatory_prison := to_number(object.get(kks_limits, "mandatory_prison_threshold", 5000000))

round2(x) = r {
    r := round(x * 100) / 100
}

# ── SEKCJA 1: MAPA POKRYCIA ARTYKUŁÓW KKS ─────────────────────────────────────
# Priorytetowe artykuły: czynny żal (16), recydywa (37), przedawnienie (44),
# zatarcie (45), mała wartość (53), czyny 54-83.
kks_priority_articles := ["a16", "a37", "a44", "a45", "a53", "a54", "a55", "a56", "a57", "a62", "a64", "a77", "a78", "a79", "a80", "a81", "a82", "a83"]

kks_audit_data := object.get(data.jdg, "kks_audit", {})
coverage_articles := object.get(kks_audit_data, "articles", {})

kks_coverage_report := {
    "rule_id": "jdg.p10_kks_innovations.kks_coverage_report",
    "package": "jdg.p10_kks_innovations",
    "priority": 910,
    "matched": true,
    "articles": {art: {
        "status": object.get(object.get(coverage_articles, art, {}), "status", "MISSING"),
        "rules": object.get(object.get(coverage_articles, art, {}), "rules", 0),
    } | art := kks_priority_articles[_]},
    "summary": {
        "total": count(kks_priority_articles),
        "complete": count([a | a := kks_priority_articles[_]; object.get(object.get(coverage_articles, a, {}), "status", "MISSING") == "COMPLETE"]),
        "missing": count([a | a := kks_priority_articles[_]; object.get(object.get(coverage_articles, a, {}), "status", "MISSING") != "COMPLETE"]),
    },
    "gap_pct": round2(count([a | a := kks_priority_articles[_]; object.get(object.get(coverage_articles, a, {}), "status", "MISSING") != "COMPLETE"]) / count(kks_priority_articles) * 100),
    "micro_total_rule_ids": object.get(kks_audit_data, "total_rule_ids", 474),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia artykułów KKS (art. 16-83) — status COMPLETE/PARTIAL/MISSING",
    "_legal_basis": "KKS art. 16, 37, 44, 45, 53-83",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# ── SEKCJA 2: AUDYT GRADACJI KAR (POZIOM ENTERPRISE — PRIORYTET) ──────────────
# Typy czynów karno-skarbowych — matryca kar (stawki dzienne, PW).
kks_offense_matrix := {
    "art54": {"name": "Uchylanie się od opodatkowania", "max_rates": 720, "max_pw_years": 5, "severity": "CRITICAL"},
    "art54_2": {"name": "Uchylanie — duża wartość", "max_rates": 720, "max_pw_years": 10, "severity": "CRITICAL"},
    "art56": {"name": "Nierzetelne księgi/PKPiR", "max_rates": 240, "max_pw_years": 0, "severity": "HIGH"},
    "art56_3": {"name": "Fikcyjne wpisy PKPiR", "max_rates": 720, "max_pw_years": 5, "severity": "CRITICAL"},
    "art57": {"name": "Nierzetelna ewidencja VAT", "max_rates": 360, "max_pw_years": 0, "severity": "HIGH"},
    "art62": {"name": "Puste faktury", "max_rates": 720, "max_pw_years": 8, "severity": "CRITICAL"},
    "art62_3": {"name": "Korzyść >5M → obligatoryjne PW", "max_rates": 1080, "max_pw_years": 15, "severity": "CRITICAL"},
    "art64": {"name": "Niewłaściwa stawka VAT", "max_rates": 180, "max_pw_years": 0, "severity": "MEDIUM"},
    "art77": {"name": "Niezłożenie deklaracji (wykroczenie)", "max_rates": 180, "max_pw_years": 0, "severity": "MEDIUM"},
}

penalty_gradation_audit := {
    "rule_id": "jdg.p10_kks_innovations.penalty_gradation_audit",
    "package": "jdg.p10_kks_innovations",
    "priority": 920,
    "matched": true,
    "daily_rate_min": kks_daily_rate_min,
    "daily_rate_max": kks_daily_rate_max,
    "crime_threshold": kks_crime_threshold,
    "mandatory_prison_threshold": kks_mandatory_prison,
    "max_rates_crime": kks_max_rates_crime,
    "max_rates_misdemeanor": kks_max_rates_misdemeanor,
    "offense_matrix": kks_offense_matrix,
    "aggravating": ["recydywa (art. 37)", "korzyść dużej wartości", "utrudnianie kontroli", "wielość czynów"],
    "mitigating": ["mała wartość (art. 53 §6)", "pierwsze naruszenie", "dobrowolna naprawa szkody", "przyznanie się"],
    "recidivism_note": "recydywa — kara w wysokości do 2× górnej granicy (art. 37 §1 pkt 2 KKS)",
    "small_value_note": "mała wartość — czyn zabroniony o wartości nieprzekraczającej 500× minimalnego wynagrodzenia może być wykroczeniem",
    "_routing": "",
    "_routing_reason": "Audyt gradacji kar — typy czynów, stawki dzienne, mnożniki, okoliczności, recydywa, mała wartość",
    "_legal_basis": "KKS art. 37, 53-64, 77, 83",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-01: KALKULATOR KARY — grzywna w stawkach dziennych z pełnym uzasadnieniem.
penalty_calculator := {
    "rule_id": "jdg.p10_kks_innovations.penalty_calculator",
    "package": "jdg.p10_kks_innovations",
    "priority": 921,
    "matched": true,
    "offense": object.get(input.offense, "type", "art54"),
    "offense_info": object.get(kks_offense_matrix, object.get(input.offense, "type", "art54"), {}),
    "amount": to_number(object.get(input.offense, "amount", 0)),
    "daily_rates": to_number(object.get(input.offense, "daily_rates", 10)),
    "daily_rate_min": kks_daily_rate_min,
    "daily_rate_max": kks_daily_rate_max,
    "fine_min": round2(kks_daily_rate_min * to_number(object.get(input.offense, "daily_rates", 10))),
    "fine_max": round2(kks_daily_rate_max * to_number(object.get(input.offense, "daily_rates", 10))),
    "is_crime": to_number(object.get(input.offense, "amount", 0)) >= kks_crime_threshold,
    "exceeds_mandatory_prison": to_number(object.get(input.offense, "amount", 0)) >= kks_mandatory_prison,
    "justification": [
        sprintf("Grzywna wymierzana w stawkach dziennych: %v stawek", [to_number(object.get(input.offense, "daily_rates", 10))]),
        sprintf("Stawka dzienna: 1/30 min. wynagrodzenia = %v PLN (min) do %v PLN (max)", [kks_daily_rate_min, kks_daily_rate_max]),
        sprintf("Kara: %v × stawka = %v PLN (min) / %v PLN (max)", [to_number(object.get(input.offense, "daily_rates", 10)), round2(kks_daily_rate_min * to_number(object.get(input.offense, "daily_rates", 10))), round2(kks_daily_rate_max * to_number(object.get(input.offense, "daily_rates", 10)))]),
    ],
    "_routing": "",
    "_routing_reason": "Kalkulator kary KKS — grzywna w stawkach dziennych z pełnym uzasadnieniem",
    "_legal_basis": "KKS art. 23 (stawki dzienne), art. 26-28 (grzywna), art. 53-83 (typy czynów)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-02: SILNIK MINIMALIZACJI KARY — 4-ścieżkowy decision tree.
penalty_minimization_engine := {
    "rule_id": "jdg.p10_kks_innovations.penalty_minimization_engine",
    "package": "jdg.p10_kks_innovations",
    "priority": 922,
    "matched": true,
    "amount": to_number(object.get(input.jdg_entrepreneur, "tax_arrears", 0)),
    "paths": {
        "path_1_czynny_zal": {
            "eligible": object.get(input.jdg_entrepreneur, "disclosure_before_detection", false) == true,
            "effect": "art. 16 — zawiadomienie przed wykryciem → brak odpowiedzialności",
        },
        "path_2_dobrowolne_poddanie": {
            "eligible": object.get(input.jdg_entrepreneur, "willing_to_submit", false) == true,
            "effect": "art. 17 — dobrowolne poddanie się odpowiedzialności → kara łagodniejsza",
        },
        "path_3_ugoda_mediacja": {
            "eligible": object.get(input.jdg_entrepreneur, "mediation_open", false) == true,
            "effect": "art. 188-189 — postępowanie mediacyjne / ugoda",
        },
        "path_4_obrona_merytoryczna": {
            "eligible": true,
            "effect": "kwestionowanie podstaw: brak znamion, przedawnienie (art. 44), błąd co do prawa",
        },
    },
    "recommendation": "czynny_zal" if object.get(input.jdg_entrepreneur, "disclosure_before_detection", false) == true else "dobrowolne_poddanie" if object.get(input.jdg_entrepreneur, "willing_to_submit", false) == true else "obrona_merytoryczna",
    "_routing": "",
    "_routing_reason": "Silnik minimalizacji kary — 4-ścieżkowy decision tree (czynny żal / poddanie / ugoda / obrona)",
    "_legal_basis": "KKS art. 16, 17, 19, 44, 188-189",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-03: SYMULATOR RYZYKA KARNO-SKARBOWEGO.
# Score = SUMA składników: nierzetelne księgi +25, puste faktury +35,
# niezłożone deklaracje +10/szt., recydywa +30 → LOW/HIGH/CRITICAL.
risk_indicators_score(input) = score {
    score := (
        (25 if object.get(input.jdg_entrepreneur, "unreliable_books", false) == true else 0)
        + (35 if object.get(input.jdg_entrepreneur, "empty_invoices", false) == true else 0)
        + (10 * to_number(object.get(input.jdg_entrepreneur, "missing_declarations", 0)))
        + (30 if object.get(input.jdg_entrepreneur, "recidivism", false) == true else 0)
    )
}

risk_score_simulator := {
    "rule_id": "jdg.p10_kks_innovations.risk_score_simulator",
    "package": "jdg.p10_kks_innovations",
    "priority": 923,
    "matched": true,
    "unreliable_books": object.get(input.jdg_entrepreneur, "unreliable_books", false),
    "empty_invoices": object.get(input.jdg_entrepreneur, "empty_invoices", false),
    "missing_declarations": object.get(input.jdg_entrepreneur, "missing_declarations", 0),
    "recidivism": object.get(input.jdg_entrepreneur, "recidivism", false),
    "risk_score": risk_indicators_score(input),
    "risk_level": "CRITICAL" if risk_indicators_score(input) >= 30 else "HIGH" if risk_indicators_score(input) >= 10 else "LOW",
    "_routing": "",
    "_routing_reason": "Symulator ryzyka karno-skarbowego — scoring wskaźników (suma składników)",
    "_legal_basis": "KKS art. 54-83 (typy czynów)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# ── SEKCJA 3: CZYNNY ŻAL (ART. 16) I DOBROWOLNE PODDANIE SIĘ (ART. 17) ───────
voluntary_disclosure_audit := {
    "rule_id": "jdg.p10_kks_innovations.voluntary_disclosure_audit",
    "package": "jdg.p10_kks_innovations",
    "priority": 930,
    "matched": true,
    "art16_conditions": [
        "zawiadomienie organu o popełnieniu czynu PRZED wykryciem",
        "ujawnienie wszystkich istotnych okoliczności",
        "zapłata należności (podatek + odsetki) w terminie",
    ],
    "art17_voluntary_submission": "dobrowolne poddanie się odpowiedzialności — wniosek o skazanie bez postępowania sądowego",
    "exclusions": ["czyn zabroniony został ujawniony przez kontrolę", "organ dysponował już informacjami o czynie"],
    "_routing": "",
    "_routing_reason": "Audyt czynnego żalu (art. 16) i dobrowolnego poddania się (art. 17)",
    "_legal_basis": "KKS art. 16, 17",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-04: ASYSTENT "CZY WARTO ZŁOŻYĆ CZYNNY ŻAL".
voluntary_disclosure_assistant := {
    "rule_id": "jdg.p10_kks_innovations.voluntary_disclosure_assistant",
    "package": "jdg.p10_kks_innovations",
    "priority": 931,
    "matched": true,
    "disclosure_before_detection": object.get(input.jdg_entrepreneur, "disclosure_before_detection", false),
    "control_started": object.get(input.jdg_entrepreneur, "control_started", false),
    "worth_filing": object.get(input.jdg_entrepreneur, "disclosure_before_detection", false) == true and object.get(input.jdg_entrepreneur, "control_started", false) == false,
    "effect": "brak odpowiedzialności karnej (art. 16 §1)" if object.get(input.jdg_entrepreneur, "disclosure_before_detection", false) == true and object.get(input.jdg_entrepreneur, "control_started", false) == false else "czynny żal bezskuteczny — kontrola rozpoczęta" if object.get(input.jdg_entrepreneur, "control_started", false) == true else "brak zawiadomienia — czynny żal niewykorzystany",
    "steps": ["1. Zawiadomienie do US/KAS", "2. Ujawnienie okoliczności", "3. Zapłata podatku + odsetek", "4. Dokumentacja"],
    "_routing": "",
    "_routing_reason": "Asystent czynnego żalu — czy warto złożyć (art. 16 KKS)",
    "_legal_basis": "KKS art. 16 §1-3",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# ── SEKCJA 4: PRZEDAWNIENIE (ART. 44) I ZATARCIE SKAZANIA (ART. 45) ───────────
limitation_calendar := {
    "rule_id": "jdg.p10_kks_innovations.limitation_calendar",
    "package": "jdg.p10_kks_innovations",
    "priority": 940,
    "matched": true,
    "crime_years": to_number(object.get(kks_limits, "limitation_years_crime", 5)),
    "misdemeanor_years": to_number(object.get(kks_limits, "limitation_years_misdemeanor", 3)),
    "note": "przedawnienie karalności przestępstwa skarbowego — 5 lat; wykroczenia — 3 lata (art. 44 KKS)",
    "tax_arrears_interaction": "przedawnienie zobowiązania podatkowego (5 lat, art. 70 OrdPU) — przedawnienie karalności nie następuje przed przedawnieniem zobowiązania",
    "_routing": "",
    "_routing_reason": "Kalendarz przedawnień per czyn (art. 44 KKS)",
    "_legal_basis": "KKS art. 44; OrdPU art. 70",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-05: TRACKER ZATARCIA SKAZANIA (art. 45 KKS).
conviction_expungement_tracker := {
    "rule_id": "jdg.p10_kks_innovations.conviction_expungement_tracker",
    "package": "jdg.p10_kks_innovations",
    "priority": 941,
    "matched": true,
    "sentence_date": object.get(input.jdg_entrepreneur, "sentence_date", "2026-01-01"),
    "penalty_type": object.get(input.jdg_entrepreneur, "penalty_type", "grzywna"),
    "expungement_period_years": 1 if object.get(input.jdg_entrepreneur, "penalty_type", "grzywna") == "grzywna" else 3 if object.get(input.jdg_entrepreneur, "penalty_type", "grzywna") == "kara_ograniczenia_wolnosci" else 5,
    "impact_contracts": "zatarcie — brak wpływu na kontrakty i pozwolenia po upływie okresu",
    "tracker_note": "zatarcie z mocy prawa po okresie próby / wykonaniu kary (art. 45 KKS)",
    "_routing": "",
    "_routing_reason": "Tracker zatarcia skazania (art. 45 KKS) — wpływ na kontrakty i pozwolenia",
    "_legal_basis": "KKS art. 45",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# ── SEKCJA 5: SPÓJNOŚĆ MICRO ↔ MACRO I DUPLIKATY ──────────────────────────────
kks_duplicate_report := {
    "rule_id": "jdg.p10_kks_innovations.kks_duplicate_report",
    "package": "jdg.p10_kks_innovations",
    "priority": 950,
    "matched": true,
    "total_rule_ids": object.get(kks_audit_data, "total_rule_ids", 0),
    "unique_count": object.get(kks_audit_data, "unique_count", 0),
    "duplicate_count": object.get(kks_audit_data, "duplicate_count", 0),
    "stub_count": object.get(kks_audit_data, "stub_count", 0),
    "dead_rules": object.get(kks_audit_data, "dead_rules", []),
    "manifest_duplicates_reported": 369,
    "_routing": "",
    "_routing_reason": "Audyt spójności micro↔macro i duplikatów (MANIFEST: 369 duplikatów, stuby, martwe reguły)",
    "_legal_basis": "KKS (struktura reguł); ADR-001",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-06: Detektor martwych reguł i stubów.
kks_dead_rule_detector := {
    "rule_id": "jdg.p10_kks_innovations.kks_dead_rule_detector",
    "package": "jdg.p10_kks_innovations",
    "priority": 951,
    "matched": true,
    "dead_rules": object.get(kks_audit_data, "dead_rules", []),
    "stubs": object.get(kks_audit_data, "stubs", []),
    "note": "reguły z ciałem { true } (stuby) i reguły bez referencji (martwe) — do usunięcia",
    "_routing": "",
    "_routing_reason": "Detektor martwych reguł i stubów KKS",
    "_legal_basis": "ADR-001 (architektura reguł)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# ── SEKCJA 6: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE AUTO-AKTUALIZACJI ────────
kks_pipeline_snapshot := {
    "rule_id": "jdg.p10_kks_innovations.kks_pipeline_snapshot",
    "package": "jdg.p10_kks_innovations",
    "priority": 960,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.kks (ADR-002) — min. wynagrodzenie, mnożniki",
        "step_2_generate": "matryca kar + stawki dzienne + progi (art. 44, 53, 62)",
        "step_3_verify": "kks_penalty_auditor.py — walidacja spójności",
        "step_4_emit": "hot-reload pakietów jdg.kks / jdg.kks.innovations",
    },
    "auto_update": "nowelizacje KKS / zmiana min. wynagrodzenia → pipeline auto-aktualizacji sankcji i progów",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji sankcji i progów KKS (ADR-002)",
    "_legal_basis": "KKS (Dz.U. 2025 poz. 678); ADR-002",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# ── SEKCJA 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-12) ────────────────────
# INN-01: penalty_calculator | INN-02: penalty_minimization_engine
# INN-03: risk_score_simulator | INN-04: voluntary_disclosure_assistant
# INN-05: conviction_expungement_tracker | INN-06: kks_dead_rule_detector

# INN-07: TARCZA PRZECIWKO SANKCJOM — prewencja (checklist compliance).
kks_proactive_shield := {
    "rule_id": "jdg.p10_kks_innovations.kks_proactive_shield",
    "package": "jdg.p10_kks_innovations",
    "priority": 970,
    "matched": true,
    "shield_items": [
        "terminowe składanie deklaracji (art. 77 — unikanie wykroczenia)",
        "rzetelne księgi PKPiR (art. 56 — unikanie przestępstwa)",
        "rzetelna ewidencja VAT (art. 57)",
        "brak pustych faktur (art. 62)",
        "poprawna stawka VAT (art. 64)",
        "kalendarz przedawnień (art. 44) — monitoring",
    ],
    "compliance_score": 100 - 10 * to_number(object.get(input.jdg_entrepreneur, "missing_declarations", 0)),
    "_routing": "",
    "_routing_reason": "Tarcza przeciwko sankcjom — prewencja karno-skarbowa (checklist compliance)",
    "_legal_basis": "KKS art. 56, 57, 62, 64, 77",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-08: Detektor recydywy (art. 37).
recidivism_detector := {
    "rule_id": "jdg.p10_kks_innovations.recidivism_detector",
    "package": "jdg.p10_kks_innovations",
    "priority": 971,
    "matched": true,
    "prior_convictions": to_number(object.get(input.jdg_entrepreneur, "prior_convictions", 0)),
    "recidivism": to_number(object.get(input.jdg_entrepreneur, "prior_convictions", 0)) >= 1,
    "penalty_multiplier": 2 if to_number(object.get(input.jdg_entrepreneur, "prior_convictions", 0)) >= 1 else 1,
    "_routing": "",
    "_routing_reason": "Detektor recydywy — kara do 2× górnej granicy (art. 37 §1 pkt 2)",
    "_legal_basis": "KKS art. 37 §1 pkt 2",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-09: Ocena małej wartości (art. 53 §6).
small_value_assessor := {
    "rule_id": "jdg.p10_kks_innovations.small_value_assessor",
    "package": "jdg.p10_kks_innovations",
    "priority": 972,
    "matched": true,
    "amount": to_number(object.get(input.offense, "amount", 0)),
    "small_value_threshold": round2(kks_min_wage * 500),
    "is_small_value": to_number(object.get(input.offense, "amount", 0)) <= round2(kks_min_wage * 500),
    "effect": "możliwość potraktowania jako wykroczenia (art. 53 §6 KKS)" if to_number(object.get(input.offense, "amount", 0)) <= round2(kks_min_wage * 500) else "wartość nie jest mała",
    "_routing": "",
    "_routing_reason": "Ocena małej wartości (art. 53 §6) — wykroczenie zamiast przestępstwa",
    "_legal_basis": "KKS art. 53 §6",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-10: Panel ryzyka karno-skarbowego per obszar.
kks_risk_panel := {
    "rule_id": "jdg.p10_kks_innovations.kks_risk_panel",
    "package": "jdg.p10_kks_innovations",
    "priority": 973,
    "matched": true,
    "areas": {
        "vat": {"risks": ["puste faktury (art. 62)", "nierzetelna ewidencja (art. 57)", "niewłaściwa stawka (art. 64)"], "mitigation": "wewnętrzna kontrola faktur"},
        "pit": {"risks": ["nierzetelne PKPiR (art. 56)", "ukrywanie przychodu (art. 54)"], "mitigation": "automatyczna księgowość"},
        "zus": {"risks": ["zaniżanie podstawy (art. 54)"], "mitigation": "kalkulator składek"},
        "deklaracje": {"risks": ["niezłożenie w terminie (art. 77)"], "mitigation": "kalendarz terminów"},
    },
    "_routing": "",
    "_routing_reason": "Panel ryzyka karno-skarbowego per obszar (VAT/PIT/ZUS/deklaracje)",
    "_legal_basis": "KKS art. 54-77",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-11: Hook auto-aktualizacji sankcji (nowelizacje KKS / zmiana min. wynagrodzenia).
kks_sanction_auto_updater := {
    "rule_id": "jdg.p10_kks_innovations.kks_sanction_auto_updater",
    "package": "jdg.p10_kks_innovations",
    "priority": 974,
    "matched": true,
    "source": "data.jdg.thresholds.kks (ADR-002)",
    "trigger": "nowelizacja KKS / zmiana minimalnego wynagrodzenia / zmiana mnożników",
    "steps": ["ingest", "generate", "verify", "emit"],
    "hot_reload": true,
    "_routing": "",
    "_routing_reason": "Hook auto-aktualizacji sankcji i progów KKS",
    "_legal_basis": "KKS (Dz.U. 2025 poz. 678); ADR-002",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-12: Generator wniosku o dobrowolne poddanie się odpowiedzialności.
voluntary_submission_generator := {
    "rule_id": "jdg.p10_kks_innovations.voluntary_submission_generator",
    "package": "jdg.p10_kks_innovations",
    "priority": 975,
    "matched": true,
    "template": [
        "Wniosek o dobrowolne poddanie się odpowiedzialności (art. 17 KKS)",
        "Dane podatnika + opis czynu + wysokość uszczuplenia",
        "Propozycja kary: grzywna w stawkach dziennych",
        "Zobowiązanie do zapłaty uszczuplenia + odsetek",
    ],
    "_routing": "",
    "_routing_reason": "Generator wniosku o dobrowolne poddanie się odpowiedzialności (art. 17 KKS)",
    "_legal_basis": "KKS art. 17",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# ── SEKCJA 7b: NOWE INNOWACJE P10 v9.1 (INN-13..INN-16) ────────────────────────
# INN-13: SYMULATOR "CO JEŚLI" — korekta (podatek+odsetki) vs sankcja karno-skarbowa.
penalty_what_if_simulator := {
    "rule_id": "jdg.p10_kks_innovations.penalty_what_if_simulator",
    "package": "jdg.p10_kks_innovations",
    "priority": 976,
    "matched": true,
    "tax_arrears": to_number(object.get(input.jdg_entrepreneur, "tax_arrears", 0)),
    "correction_cost": correction_cost,
    "penalty_estimate": penalty_estimate,
    "correction_cheaper": correction_cheaper,
    "recommendation": "KOREKTA_DEKLARACJI" if correction_cheaper else "DORADCA_PODATKOWY",
    "_routing": "",
    "_routing_reason": "Symulator co-jeśli — korekta deklaracji (podatek+odsetki) vs sankcja karno-skarbowa",
    "_legal_basis": "OrdPU art. 81 (korekta deklaracji); KKS art. 54-56",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
    correction_cost := round2(to_number(object.get(input.jdg_entrepreneur, "tax_arrears", 0)) * to_number(object.get(kks_limits, "correction_interest_pct", 0.15)))
    penalty_estimate := round2(kks_daily_rate_min * to_number(object.get(input.offense, "daily_rates", 10)))
    correction_cheaper := correction_cost < penalty_estimate
}

# INN-14: RAPORT GOTOWOŚCI NA KONTROLĘ SKARBOWĄ (komplet dokumentów, JPK na żądanie).
tax_audit_readiness := {
    "rule_id": "jdg.p10_kks_innovations.tax_audit_readiness",
    "package": "jdg.p10_kks_innovations",
    "priority": 977,
    "matched": true,
    "readiness_items": [
        "Komplet dokumentów księgowych (faktury, PKPiR/UoR) — art. 56 KKS",
        "JPK na żądanie US — 30 dni (art. 193a OrdPU)",
        "Ewidencja VAT kompletna (art. 57 KKS)",
        "Deklaracje złożone w terminie (art. 77 KKS)",
        "Dowody kasowe / potwierdzenia przelewów / wyciągi bankowe",
    ],
    "readiness_score": readiness_score,
    "audit_ready": readiness_score >= 80,
    "_routing": "TRIAGE_QUEUE" if readiness_score < 80 else "",
    "_routing_reason": "Raport gotowości na kontrolę skarbową — komplet dokumentów, JPK na żądanie (art. 193a)",
    "_legal_basis": "KKS art. 56-57; OrdPU art. 193a",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
    readiness_score := 100 - (20 if object.get(input.jdg_entrepreneur, "documents_incomplete", false) == true else 0) - (20 if object.get(input.jdg_entrepreneur, "jpk_not_ready", false) == true else 0) - (20 if object.get(input.jdg_entrepreneur, "vat_records_incomplete", false) == true else 0) - (20 * to_number(object.get(input.jdg_entrepreneur, "missing_declarations", 0)))
}

# INN-15: AUDYT ODPOWIEDZIALNOŚCI POWIĄZANEJ (solidarna, zarządca sukcesyjny, podmiot zbiorowy).
related_liability_audit := {
    "rule_id": "jdg.p10_kks_innovations.related_liability_audit",
    "package": "jdg.p10_kks_innovations",
    "priority": 978,
    "matched": true,
    "solidary_liability": "odpowiedzialność solidarna podatnika (art. 107-108 KKS) — wspólnicy/małżonkowie w zakresie wspólnego majątku",
    "successor_manager": "odpowiedzialność zarządcy sukcesyjnego za zaległości do wartości aktywów (art. 101-102 OrdPU; sukcesja P13)",
    "collective_entity": "odpowiedzialność podmiotu zbiorowego (ustawa o odpowiedzialności podmiotów zbiorowych)",
    "succession_active": object.get(input.jdg_entrepreneur, "succession_active", false) == true,
    "successor_risk_note": "zarządca sukcesyjny odpowiada za zaległości podatkowe do wartości aktywów — aktywny zarząd sukcesyjny" if object.get(input.jdg_entrepreneur, "succession_active", false) == true else "brak zarządu sukcesyjnego — standardowa odpowiedzialność podatnika",
    "_routing": "TRIAGE_QUEUE" if object.get(input.jdg_entrepreneur, "succession_active", false) == true else "",
    "_routing_reason": "Audyt odpowiedzialności powiązanej — solidarna, zarządca sukcesyjny, podmiot zbiorowy",
    "_legal_basis": "KKS art. 107-108; OrdPU art. 101-102; ustawa o odpowiedzialności podmiotów zbiorowych",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# INN-16: PRZEWIDYWACZ WYROKÓW — trend orzecznictwa NSA/WSA dla typu czynu.
judgment_trend_predictor := {
    "rule_id": "jdg.p10_kks_innovations.judgment_trend_predictor",
    "package": "jdg.p10_kks_innovations",
    "priority": 979,
    "matched": true,
    "offense": object.get(input.offense, "type", "art54"),
    "trend_source": "orzecznictwo NSA/WSA — judgment_predictor.py / judicial_interpretations_enterprise.rego",
    "favorable_trend": object.get(input.jdg_entrepreneur, "favorable_jurisprudence_trend", false) == true,
    "unfavorable_trend": object.get(input.jdg_entrepreneur, "unfavorable_jurisprudence_trend", false) == true,
    "prediction": "WYSOKIE_SZANSE_OBRONY" if object.get(input.jdg_entrepreneur, "favorable_jurisprudence_trend", false) == true else "RYZYKO_NIEPOMYSLNEGO_WYROKU" if object.get(input.jdg_entrepreneur, "unfavorable_jurisprudence_trend", false) == true else "NEUTRALNE",
    "_routing": "",
    "_routing_reason": "Przewidywacz wyroków — trend orzecznictwa dla danego typu czynu (NSA/WSA)",
    "_legal_basis": "KKS (orzecznictwo); ADR-011",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}

# ── GŁÓWNY DECIDE (P10) — raport syntetyczny KKS ──────────────────────────────
decide := {
    "rule_id": "jdg.p10_kks_innovations.report",
    "package": "jdg.p10_kks_innovations",
    "priority": 957,
    "matched": true,
    "coverage": kks_coverage_report,
    "penalty_gradation": penalty_gradation_audit,
    "penalty_calculator": penalty_calculator,
    "minimization_engine": penalty_minimization_engine,
    "voluntary_disclosure": voluntary_disclosure_audit,
    "limitations": limitation_calendar,
    "duplicates": kks_duplicate_report,
    "pipeline": kks_pipeline_snapshot,
    "what_if": penalty_what_if_simulator,
    "audit_readiness": tax_audit_readiness,
    "related_liability": related_liability_audit,
    "judgment_trend": judgment_trend_predictor,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny KKS (P10) — pokrycie, gradacja kar, minimalizacja, czynny żal, przedawnienie",
    "_legal_basis": "KKS (Dz.U. 2025 poz. 678): art. 16, 17, 37, 44, 45, 53-83",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p10_kks_check", false) == true
}
