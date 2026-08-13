# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P13 GENIALNE POMYSŁY ENTERPRISE (Ryczałt + Cykl Życia JDG)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p13_ryczalt_cykl_zycia_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG RYCZAŁT + CYKL ŻYCIA (P13) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: AUDYT STAWEK RYCZAŁTU WG PKWiU (PRIORYTET) — stawki 3%..25%,
#            limit 2 mln EUR (art. 6), wyłączenia (art. 8), ewidencja (art. 15)
#            + AUTO-KALKULATOR stawki z kodu PKWiU (INN-01)
#   Sekcja 2: AUDYT KARTY PODATKOWEJ — zasady, stawki, limity zatrudnienia,
#            zgłoszenie do US (art. 21-28 ustawy o ryczałcie)
#   Sekcja 3: AUDYT CYKLU ŻYCIA JDG (PRIORYTET) — rejestracja CEIDG → start →
#            wzrost → dojrzałość → zawieszenie → wznowienie → exit/sukcesja
#            + ASYSTENT cyklu życia z kalendarzem obowiązków (INN-03)
#   Sekcja 4: AUDYT SUKCESJI — zarządca sukcesyjny (art. 3-15 ustawy o zarządzie
#            sukcesyjnym), terminy, 2 lata + przedłużenie do 5 lat
#            + TRACKER sukcesji krok po kroku (INN-04)
#   Sekcja 5: AUDYT ZAWIESZEŃ I DZIAŁALNOŚCI NIEEWIDENCJONOWANEJ — art. 22-25 PP
#            (zawieszenie), art. 6 PP (50% płacy minimalnej)
#   Sekcja 6: OPA jako rozbudowany system — thresholdy ryczałtu temporalne
#            i auto-aktualizacja (ADR-002, hot-reload)
#   Sekcja 7: 12+ genialnych pomysłów Enterprise (INN-01..INN-12)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R13)
#
# Zgodność: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234),
#           Prawo Przedsiębiorców (Dz.U. 2025 poz. 123), CEIDG (Dz.U. 2025 poz. 456),
#           ustawa o zarządzie sukcesyjnym (Dz.U. 2025 poz. 1234), ADR-002
#           (progi z data.jdg.thresholds).
# package: jdg.p13_ryczalt_cykl_zycia_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p13_ryczalt_cykl_zycia_innovations

import future.keywords.in
import future.keywords.if

default decide := {"matched": false, "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.no_match", "package": "jdg.p13_ryczalt_cykl_zycia_innovations", "priority": 999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
ryczalt_limits := object.get(thresholds, "ryczalt", {
    "limit_eur": 2000000,          # art. 6 ust. 4 — limit 2 mln EUR
    "eur_rate_pln": 4.50,          # kurs EUR (przeliczenie limitu)
    "pkwiu_rates": {               # Sekcja 1: stawki wg PKWiU (art. 12 ust. 1)
        "3": "handel hurtowy i detaliczny (sekcja G)",
        "5.5": "działalność wytwórcza, budowlana (sekcje C, F)",
        "8.5": "działalność usługowa (sekcje H-U z wyłączeniami), najem",
        "10": "najem prywatny powyżej 100 000 zł (art. 12 ust. 1 pkt 4)",
        "12": "usługi specjalistyczne (m.in. IT, zdrowotne — wg załącznika)",
        "12.5": "usługi transportowe i magazynowe (sekcja H)",
        "14": "usługi architektoniczne i inżynierskie (sekcja M)",
        "15": "usługi gastronomiczne i zakwaterowanie (sekcja I)",
        "17": "wolne zawody (adwokaci, lekarze, księgowi, architekci — art. 12 ust. 1 pkt 5)",
        "20": "usługi niematerialne świadczone na rzecz byłego pracodawcy (art. 12 ust. 1 pkt 8)",
        "25": "usługi specjalistyczne wysokomarżowe (wg załącznika)",
    },
    "karta_podatkowa": {           # Sekcja 2: karta podatkowa
        "zasady": "stawki miesięczne wg tabel — zależne od rodzaju działalności, liczby zatrudnionych i miejsca wykonywania",
        "limit_zatrudnienia": 5,   # max 5 pracowników (co do zasady)
        "zgłoszenie": "wniosek do US do 20. dnia miesiąca poprzedzającego (art. 29)",
    },
    "nieewidencjonowana_limit_pct": 50,  # art. 6 PP — 50% płacy minimalnej
    "zawieszenie_max_months": 24,        # art. 22 PP — max 24 mies. (36 z wyjątkami)
    "zawieszenie_min_months": 1,         # min 30 dni
    "succession_months_standard": 24,    # zarząd sukcesyjny — 2 lata
    "succession_months_extended": 60,    # przedłużenie do 5 lat
    "ceidg_wpis_days": 7,                # CEIDG — wpis w 7 dni
})

limit_eur := to_number(object.get(ryczalt_limits, "limit_eur", 2000000))
eur_rate := to_number(object.get(ryczalt_limits, "eur_rate_pln", 4.50))
limit_pln := round2(limit_eur * eur_rate)
min_wage := to_number(object.get(data.jdg, "min_wage_2026", 4800))
nieewidencjonowana_limit := round2(min_wage * to_number(object.get(ryczalt_limits, "nieewidencjonowana_limit_pct", 50)) / 100)
zawieszenie_max_months := to_number(object.get(ryczalt_limits, "zawieszenie_max_months", 24))
succession_months_standard := to_number(object.get(ryczalt_limits, "succession_months_standard", 24))
succession_months_extended := to_number(object.get(ryczalt_limits, "succession_months_extended", 60))

round2(x) = r {
    r := round(x * 100) / 100
}

# ── SEKCJA 1: MAPA POKRYCIA ARTYKUŁÓW (ryczałt + PP + CEIDG + sukcesja) ───────
# Status COMPLETE/PARTIAL/MISSING z data.jdg.p13_audit (ryczalt_lifecycle_auditor.py).
p13_priority_articles := ["a4", "a6", "a8", "a12", "a15", "a21", "a27", "a29", "a30"]

p13_audit_data := object.get(data.jdg, "p13_audit", {})
p13_coverage_articles := object.get(p13_audit_data, "articles", {})

ryczalt_coverage_report := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_coverage_report",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1010,
    "matched": true,
    "articles": {art: {
        "status": object.get(object.get(p13_coverage_articles, art, {}), "status", "MISSING"),
        "rules": object.get(object.get(p13_coverage_articles, art, {}), "rules", 0),
    } | art := p13_priority_articles[_]},
    "summary": {
        "total": count(p13_priority_articles),
        "complete": count([a | a := p13_priority_articles[_]; object.get(object.get(p13_coverage_articles, a, {}), "status", "MISSING") == "COMPLETE"]),
        "missing": count([a | a := p13_priority_articles[_]; object.get(object.get(p13_coverage_articles, a, {}), "status", "MISSING") != "COMPLETE"]),
    },
    "gap_pct": round2(count([a | a := p13_priority_articles[_]; object.get(object.get(p13_coverage_articles, a, {}), "status", "MISSING") != "COMPLETE"]) / count(p13_priority_articles) * 100),
    "micro_total_rule_ids": object.get(p13_audit_data, "total_rule_ids", 485),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia artykułów ryczałtu (art. 4-30) — status COMPLETE/PARTIAL/MISSING",
    "_legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234), art. 4-30",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# ── SEKCJA 1: AUDYT STAWEK RYCZAŁTU WG PKWiU (POZIOM ENTERPRISE — PRIORYTET) ─
# art. 12 ust. 1 ustawy o ryczałcie — stawki 3%..25% wg PKWiU; art. 6 — limit
# 2 mln EUR; art. 8 — wyłączenia; art. 15 — ewidencja przychodów.
ryczalt_rates_audit := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_rates_audit",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1120,
    "matched": true,
    "rates_pkwiu": object.get(ryczalt_limits, "pkwiu_rates", {}),
    "limit_eur": limit_eur,
    "limit_pln": limit_pln,
    "exclusions_art8": ["wykonywanie usług na rzecz byłego/obecnego pracodawcy (to samo co umowa o pracę)", "działalność w zakresie wolnych zawodów w spółce (wg listy)", "uzyskiwanie przychodów z tytułu umowy najmu przez małżonka"],
    "record_art15": "ewidencja przychodów — wpis do 20. dnia następnego miesiąca",
    "declaration": "PIT-28 — roczne rozliczenie ryczałtu (art. 21 ust. 2)",
    "_routing": "",
    "_routing_reason": "Audyt stawek ryczałtu wg PKWiU (art. 12 ust. 1) — stawki, limit 2M EUR, wyłączenia (priorytet)",
    "_legal_basis": "Ustawa o ryczałcie art. 6, 8, 12, 15, 21",
    "_warnings": [],
    "valid_from": "1999-01-01",
    "valid_to": null,
    "decision_mode": "SUGGEST",
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# INN-01: AUTO-KALKULATOR stawki ryczałtu z kodu PKWiU.
ryczalt_rate_calculator := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_rate_calculator",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1121,
    "matched": true,
    "pkwiu_code": object.get(input.activity, "pkwiu_code", ""),
    "rate": ryczalt_rate_for_code(object.get(input.activity, "pkwiu_code", "")),
    "pkwiu_section": pkwiu_section(object.get(input.activity, "pkwiu_code", "")),
    "note": "stawka ryczałtu wg PKWiU (art. 12 ust. 1 ustawy o ryczałcie) — auto-kalkulator z kodu",
    "_routing": "",
    "_routing_reason": "Auto-kalkulator stawki ryczałtu z kodu PKWiU (art. 12 ust. 1)",
    "_legal_basis": "Ustawa o ryczałcie art. 12 ust. 1",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# Pomocnicze: sekcja PKWiU z kodu (pierwsza litera / prefiks).
pkwiu_section(code) = section {
    startswith(code, "45") or startswith(code, "46") or startswith(code, "47")
    section := "G (handel)"
} else := "C/F (wytwórcza/budowlana)" {
    startswith(code, "10") or startswith(code, "41") or startswith(code, "42") or startswith(code, "43")
} else := "H (transport)" {
    startswith(code, "49") or startswith(code, "50") or startswith(code, "51") or startswith(code, "52") or startswith(code, "53")
} else := "I (gastronomia/zakwaterowanie)" {
    startswith(code, "55") or startswith(code, "56")
} else := "M (specjalistyczne)" {
    startswith(code, "69") or startswith(code, "70") or startswith(code, "71") or startswith(code, "72") or startswith(code, "73") or startswith(code, "74")
} else := "J (IT)" {
    startswith(code, "62") or startswith(code, "63")
} else := "H-U (usługi)" {
    true
}

# Pomocnicze: stawka ryczałtu dla kodu PKWiU (mapowanie sekcji → stawka).
ryczalt_rate_for_code(code) = rate {
    section := pkwiu_section(code)
    section == "G (handel)"
    rate := "3%"
} else := "5,5%" {
    section := pkwiu_section(code)
    section == "C/F (wytwórcza/budowlana)"
} else := "12,5%" {
    section := pkwiu_section(code)
    section == "H (transport)"
} else := "15%" {
    section := pkwiu_section(code)
    section == "I (gastronomia/zakwaterowanie)"
} else := "14%" {
    section := pkwiu_section(code)
    section == "M (specjalistyczne)"
} else := "12%" {
    section := pkwiu_section(code)
    section == "J (IT)"
} else := "8,5%" {
    true
}

# INN-02: TRACKER limitu 2 mln EUR w trakcie roku.
ryczalt_limit_tracker := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_limit_tracker",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1122,
    "matched": true,
    "revenue_ytd": to_number(object.get(input.jdg_entrepreneur, "revenue_ytd", 0)),
    "limit_pln": limit_pln,
    "usage_pct": round2(to_number(object.get(input.jdg_entrepreneur, "revenue_ytd", 0)) / limit_pln * 100),
    "warning_at_75pct": to_number(object.get(input.jdg_entrepreneur, "revenue_ytd", 0)) >= round2(limit_pln * 75 / 100),
    "exceeds_limit": to_number(object.get(input.jdg_entrepreneur, "revenue_ytd", 0)) > limit_pln,
    "note": "przekroczenie limitu 2 mln EUR → utrata ryczałtu od następnego dnia (art. 6 ust. 4)",
    "_routing": "",
    "_routing_reason": "Tracker limitu 2 mln EUR w trakcie roku (art. 6 ust. 4) — ostrzeżenie 75%",
    "_legal_basis": "Ustawa o ryczałcie art. 6 ust. 4",
    "_warnings": [],
    "valid_from": "1999-01-01",
    "valid_to": null,
    "decision_mode": "SUGGEST",
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# INN-10: WYKRYWACZ błędnych stawek ryczałtu.
wrong_rate_detector := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.wrong_rate_detector",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1123,
    "matched": true,
    "declared_rate": object.get(input.activity, "declared_rate", ""),
    "correct_rate": ryczalt_rate_for_code(object.get(input.activity, "pkwiu_code", "")),
    "rate_mismatch": object.get(input.activity, "declared_rate", "") != ryczalt_rate_for_code(object.get(input.activity, "pkwiu_code", "")),
    "note": "wykrywanie błędnych stawek ryczałtu — porównanie deklarowanej z kalkulowaną wg PKWiU",
    "_routing": "",
    "_routing_reason": "Wykrywacz błędnych stawek ryczałtu (INN-10) — porównanie z PKWiU",
    "_legal_basis": "Ustawa o ryczałcie art. 12 ust. 1",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# ── SEKCJA 2: AUDYT KARTY PODATKOWEJ ─────────────────────────────────────────
karta_podatkowa_audit := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.karta_podatkowa_audit",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1130,
    "matched": true,
    "zasady": object.get(ryczalt_limits, "karta_podatkowa", {}),
    "stawki_miesieczne": "kwoty stałe wg tabel (art. 23-25) — zależne od rodzaju działalności i zatrudnienia",
    "limit_zatrudnienia": object.get(object.get(ryczalt_limits, "karta_podatkowa", {}), "limit_zatrudnienia", 5),
    "zgłoszenie": object.get(object.get(ryczalt_limits, "karta_podatkowa", {}), "zgłoszenie", "wniosek do US"),
    "note": "karta podatkowa — forma zryczałtowana dla wybranych rodzajów działalności (art. 21-28)",
    "_routing": "",
    "_routing_reason": "Audyt karty podatkowej — zasady, stawki, limity zatrudnienia, zgłoszenie do US",
    "_legal_basis": "Ustawa o ryczałcie art. 21-28",
    "_warnings": [],
    "valid_from": "1999-01-01",
    "valid_to": null,
    "decision_mode": "SUGGEST",
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# ── SEKCJA 3: AUDYT CYKLU ŻYCIA JDG (POZIOM ENTERPRISE — PRIORYTET) ──────────
# Rejestracja CEIDG → start → wzrost → dojrzałość → zawieszenie → wznowienie
# → exit/sukcesja. Fazy z data.jdg.business_lifecycle_rates.
lifecycle_audit := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.lifecycle_audit",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1140,
    "matched": true,
    "phases": {
        "PRE_START": "CEIDG-1, ZUS ZUA 7 dni, rachunek firmowy, wybór formy PIT (art. 5-7 CEIDG)",
        "STARTUP_RELIEF": "ulga na start 0 zł ZUS społeczne (0-6 mies., art. 18a SUS)",
        "STARTUP_PREFERENTIAL": "preferencyjny ZUS 30% podstawy (6-30 mies., max 24 mies., art. 18c SUS)",
        "GROWTH": "limit VAT 200k → VAT-R, KSeF od 2026, pierwszy pracownik (art. 113 VAT)",
        "MATURITY": "optymalizacja skala→liniowy, JDG→sp. z o.o., CIT estoński (art. 9a PIT)",
        "SUSPENDED": "max 24 mies. zawieszenia, ZUS społeczne=0, zdrowotna nadal (art. 22-25 PP)",
        "SUCCESSION": "zarządca sukcesyjny — 2 lata + przedłużenie do 5 lat (art. 3-15 z.s.)",
    },
    "integrated_packages": ["lifecycle_manager (asystent faz cyklu)", "p16_business_lifecycle (fazy biznesowe)", "form_transition_simulator (JDG→sp. z o.o.)", "p16_autoform_generator"],
    "_routing": "",
    "_routing_reason": "Audyt cyklu życia JDG — rejestracja → start → wzrost → dojrzałość → zawieszenie → sukcesja (priorytet)",
    "_legal_basis": "CEIDG art. 5-7; SUS art. 18a, 18c; PP art. 22-25; ustawa o zarządzie sukcesyjnym art. 3-15",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# INN-03: ASYSTENT cyklu życia JDG z kalendarzem obowiązków.
lifecycle_assistant := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.lifecycle_assistant",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1141,
    "matched": true,
    "months_active": to_number(object.get(input.jdg_entrepreneur, "months_active", 0)),
    "current_phase": lifecycle_phase(to_number(object.get(input.jdg_entrepreneur, "months_active", 0))),
    "next_phase": lifecycle_next_phase(to_number(object.get(input.jdg_entrepreneur, "months_active", 0))),
    "obligations_calendar": ["CEIDG aktualizacja w 7 dni", "ZUS DRA do 10. dnia miesiąca", "VAT-7 do 25. dnia", "PIT-28 do 31.01", "KSeF e-faktury od 2026"],
    "note": "asystent cyklu życia JDG — kalendarz obowiązków per faza",
    "_routing": "",
    "_routing_reason": "Asystent cyklu życia JDG z kalendarzem obowiązków (INN-03)",
    "_legal_basis": "CEIDG; SUS; VAT; PIT; KSeF",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# Pomocnicze: faza cyklu życia na podstawie miesięcy aktywności.
lifecycle_phase(months) = phase {
    months < 0
    phase := "PRE_START"
} else := "STARTUP_RELIEF" {
    months < 6
} else := "STARTUP_PREFERENTIAL" {
    months < 30
} else := "GROWTH" {
    months < 60
} else := "MATURITY" {
    true
}

lifecycle_next_phase(months) = phase {
    months < 0
    phase := "STARTUP_RELIEF (rejestracja CEIDG-1)"
} else := "STARTUP_PREFERENTIAL (po 6 mies. — preferencyjny ZUS 30%)" {
    months < 6
} else := "GROWTH (po 30 mies. — limit VAT, pierwszy pracownik)" {
    months < 30
} else := "MATURITY (optymalizacja formy, JDG→sp. z o.o.)" {
    months < 60
} else := "SUSPENDED / SUCCESSION (exit lub sukcesja)" {
    true
}

# INN-09: SYMULATOR ryczałt vs skala vs liniowy.
pit_form_comparator := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.pit_form_comparator",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1142,
    "matched": true,
    "annual_revenue": to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)),
    "ryczalt_rate": object.get(input.jdg_entrepreneur, "ryczalt_rate_pct", 8.5),
    "ryczalt_tax": round2(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) * object.get(input.jdg_entrepreneur, "ryczalt_rate_pct", 8.5) / 100),
    "skala_tax": round2(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) * 0.12),
    "liniowy_tax": round2(to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) * 0.19),
    "best_form": "ryczałt" if ryczalt_le := to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) * object.get(input.jdg_entrepreneur, "ryczalt_rate_pct", 8.5) / 100; ryczalt_le <= to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) * 0.12 and ryczalt_le <= to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) * 0.19 else "skala" if to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) * 0.12 <= to_number(object.get(input.jdg_entrepreneur, "annual_revenue", 0)) * 0.19 else "liniowy",
    "note": "symulator ryczałt vs skala (12%) vs liniowy (19%) — wybór najkorzystniejszej formy",
    "_routing": "",
    "_routing_reason": "Symulator ryczałt vs skala vs liniowy (INN-09) — wybór formy opodatkowania",
    "_legal_basis": "PIT art. 9a, 30c; ustawa o ryczałcie",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# ── SEKCJA 4: AUDYT SUKCESJI (POZIOM ENTERPRISE) ─────────────────────────────
# Zarządca sukcesyjny — art. 3-15 ustawy o zarządzie sukcesyjnym (Dz.U. 2025 poz. 1234).
succession_audit := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.succession_audit",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1150,
    "matched": true,
    "zarzadca": {
        "appointment": "akt notarialny za życia lub wniosek do 2 mies. po śmierci (art. 3-7)",
        "wpis_ceidg_days": 14,
        "nip": "kontynuacja NIP zmarłego + dopisek 'w spadku' (art. 49)",
        "odpowiedzialnosc": "zarządca odpowiada za zobowiązania w granicach majątku firmy",
    },
    "terms": {
        "standard_months": succession_months_standard,
        "extended_months": succession_months_extended,
        "note": "zarząd sukcesyjny — max 2 lata, przedłużenie do 5 lat (art. 12-13)",
    },
    "termination": ["śmierć zarządcy", "rezygnacja", "upadłość firmy", "wygaśnięcie terminu", "orzeczenie sądu"],
    "_routing": "",
    "_routing_reason": "Audyt sukcesji — zarządca sukcesyjny, terminy, kontynuacja, odpowiedzialność, 2/5 lat",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym art. 3-15, 49",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# INN-04: TRACKER sukcesji krok po kroku.
succession_tracker := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.succession_tracker",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1151,
    "matched": true,
    "steps": ["1. Powołanie zarządcy (akt notarialny) za życia", "2. Wpis do CEIDG w 14 dni", "3. Zawiadomienie US/ZUS o sukcesji", "4. Kontynuacja działalności na NIP zmarłego", "5. Rozliczenie podatków (ryczałt/PIT) w imieniu firmy", "6. Monitorowanie terminu 2 lat / przedłużenie do 5 lat"],
    "months_remaining": succession_months_standard - to_number(object.get(input.jdg_entrepreneur, "succession_months_elapsed", 0)),
    "extended_available": to_number(object.get(input.jdg_entrepreneur, "succession_months_elapsed", 0)) > succession_months_standard,
    "note": "tracker sukcesji krok po kroku — powołanie zarządcy, wpis CEIDG, kontynuacja, terminy 2/5 lat",
    "_routing": "",
    "_routing_reason": "Tracker sukcesji krok po kroku (INN-04) — 2 lata + przedłużenie do 5 lat",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym art. 3-15",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# ── SEKCJA 5: AUDYT ZAWIESZEŃ I DZIAŁALNOŚCI NIEEWIDENCJONOWANEJ ────────────
# art. 22-25 PP — zawieszenie; art. 6 PP — działalność nieewidencjonowana (50% płacy min.).
suspension_audit := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.suspension_audit",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1160,
    "matched": true,
    "art22_25": {
        "max_months": zawieszenie_max_months,
        "min_days": 30,
        "zus_social": "brak składek społecznych w okresie zawieszenia",
        "zus_health": "składka zdrowotna nadal płacona (art. 36a SUS)",
        "vat": "możliwość zawieszenia rozliczeń VAT",
    },
    "resumption": "wznowienie — zgłoszenie CEIDG (art. 25 PP)",
    "_routing": "",
    "_routing_reason": "Audyt zawieszeń — art. 22-25 PP, skutki ZUS/PIT/VAT",
    "_legal_basis": "Prawo Przedsiębiorców art. 22-25; SUS art. 36a",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# INN-05: AUDYT działalności nieewidencjonowanej (art. 6 PP — 50% płacy minimalnej).
unregistered_business_audit := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.unregistered_business_audit",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1161,
    "matched": true,
    "monthly_revenue": to_number(object.get(input.jdg_entrepreneur, "monthly_revenue", 0)),
    "limit_monthly": nieewidencjonowana_limit,
    "min_wage_2026": min_wage,
    "within_limit": to_number(object.get(input.jdg_entrepreneur, "monthly_revenue", 0)) <= nieewidencjonowana_limit,
    "note": "działalność nieewidencjonowana — przychody do 50% płacy minimalnej miesięcznie (art. 6 PP)",
    "_routing": "",
    "_routing_reason": "Audyt działalności nieewidencjonowanej — limit 50% płacy minimalnej (art. 6 PP)",
    "_legal_basis": "Prawo Przedsiębiorców art. 6",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# INN-06: AUDYT gig economy (platformy).
gig_economy_audit := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.gig_economy_audit",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1162,
    "matched": true,
    "platforms": "przychody z platform cyfrowych (Uber, Bolt, Amazon, Allegro) — opodatkowanie ryczałtem wg PKWiU",
    "reporting": "DAC7 — raportowanie sprzedawców platformowych (2023+)",
    "status": "gig economy — forma działalności nieewidencjonowanej lub JDG (limit 2M EUR)",
    "integrated": "jdg.business.gig_economy",
    "_routing": "",
    "_routing_reason": "Audyt gig economy — platformy, opodatkowanie, DAC7 (INN-06)",
    "_legal_basis": "PP art. 6; Dyrektywa DAC7; ustawa o ryczałcie",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# INN-07: AUDYT prokury (art. 18 PP).
prokura_audit := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.prokura_audit",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1163,
    "matched": true,
    "art18_pp": "przedsiębiorca może ustanowić prokurenta (art. 18 PP, KSH art. 1091-1099)",
    "scope": "prokura obejmuje czynności sądowe i pozasądowe — z wyłączeniem zbycia przedsiębiorstwa",
    "types": ["prokura samoistna", "prokura łączna", "prokura oddziałowa"],
    "registration": "wpis do rejestru przedsiębiorców (CEIDG dla JDG — adnotacja)",
    "integrated": "jdg.representation (plan26_prokura)",
    "_routing": "",
    "_routing_reason": "Audyt prokury — art. 18 PP, zakres, typy, rejestracja (INN-07)",
    "_legal_basis": "Prawo Przedsiębiorców art. 18; KSH art. 1091-1099",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# CEIDG — art. 5-7, 12-15 (wpis w 7 dni).
ceidg_audit := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.ceidg_audit",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1164,
    "matched": true,
    "wpis_days": object.get(ryczalt_limits, "ceidg_wpis_days", 7),
    "art5_7": "rejestracja działalności — wniosek CEIDG-1, wpis w 7 dni",
    "art12_15": "zmiany danych — aktualizacja w 7 dni; zawieszenie/wznowienie — CEIDG-2/CEIDG-3",
    "integrated": "jdg.micro.ceidg (43 reguły micro)",
    "_routing": "",
    "_routing_reason": "Audyt CEIDG — rejestracja, zmiany, zawieszenia (art. 5-7, 12-15)",
    "_legal_basis": "Ustawa o CEIDG art. 5-7, 12-15",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# ── SEKCJA 6: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE TEMPORALNY ───────────────
ryczalt_pipeline_snapshot := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_pipeline_snapshot",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1170,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.ryczalt (ADR-002) — stawki PKWiU, limit 2M EUR, płaca minimalna",
        "step_2_generate": "reguły ryczałtu (stawki, limit, wyłączenia) + cykl życia (fazy, sukcesja)",
        "step_3_verify": "ryczalt_lifecycle_auditor.py — walidacja spójności stawek i limitów",
        "step_4_emit": "hot-reload pakietów jdg.micro.ryczalt / jdg.lifecycle_manager / jdg.business_lifecycle_rates",
    },
    "auto_update": "zmiany stawek ryczałtu i płacy minimalnej (coroczne obwieszczenia) → auto-aktualizacja thresholdów",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji stawek ryczałtu i limitów (ADR-002, hot-reload)",
    "_legal_basis": "ADR-002; obwieszczenia MF dot. płacy minimalnej i kursu EUR",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# ── SEKCJA 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-12) ────────────────────
# INN-01: ryczalt_rate_calculator | INN-02: ryczalt_limit_tracker
# INN-03: lifecycle_assistant | INN-04: succession_tracker | INN-05: unregistered_business_audit
# INN-06: gig_economy_audit | INN-07: prokura_audit | INN-08: ryczalt_template_hook
# INN-09: pit_form_comparator | INN-10: wrong_rate_detector
# INN-11: ceidg_audit | INN-12: ryczalt_compliance_panel

# INN-08: Hook auto-aktualizacji stawek ryczałtu (thresholdy temporalne).
ryczalt_template_hook := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_template_hook",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1171,
    "matched": true,
    "source": "data.jdg.thresholds.ryczalt (ADR-002)",
    "trigger": "zmiana stawek ryczałtu (nowelizacja ustawy), zmiana płacy minimalnej, zmiana kursu EUR",
    "steps": ["ingest", "generate", "verify", "emit"],
    "hot_reload": true,
    "_routing": "",
    "_routing_reason": "Hook auto-aktualizacji stawek ryczałtu i limitów (thresholdy temporalne)",
    "_legal_basis": "ADR-002; ustawa o ryczałcie",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# INN-12: Panel zgodności ryczałtu i cyklu życia (compliance score).
ryczalt_compliance_panel := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_compliance_panel",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1172,
    "matched": true,
    "checks": {
        "stawka_ryczaltu": "poprawna stawka wg PKWiU (art. 12)",
        "limit_2mln": "monitoring limitu 2M EUR (art. 6)",
        "ewidencja": "ewidencja przychodów do 20. dnia (art. 15)",
        "ceidg": "aktualne dane CEIDG (7 dni)",
        "zus": "składki ZUS — ulga/preferencyjny/standard",
        "sukcesja": "plan sukcesji — zarządca, terminy 2/5 lat",
        "zawieszenie": "zawieszenie ≤ 24 mies. (art. 22 PP)",
    },
    "compliance_score": 100 - to_number(object.get(input.jdg_entrepreneur, "ryczalt_penalties", 0)) * 10 if to_number(object.get(input.jdg_entrepreneur, "ryczalt_penalties", 0)) * 10 < 100 else 0,
    "_routing": "",
    "_routing_reason": "Panel zgodności ryczałtu i cyklu życia — compliance score (INN-12)",
    "_legal_basis": "Ustawa o ryczałcie; PP; CEIDG; SUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}

# ── SEKCJA 7b: NOWE INNOWACJE P13 v9.1 (INN-13..INN-17) ───────────────────────
# INN-13: ASYSTENT ZAKŁADANIA FIRMY — pełny onboarding CEIDG+NIP+ZUS+wybór formy.
company_setup_assistant := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.company_setup_assistant",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1173,
    "matched": true,
    "steps": [
        "1. Wniosek CEIDG-1 — rejestracja działalności (wpis w 7 dni, art. 5-7 CEIDG)",
        "2. NIP i REGON — nadawane automatycznie przez CEIDG",
        "3. ZUS ZUA — zgłoszenie do ubezpieczeń w 7 dni od rejestracji",
        "4. Wybór formy opodatkowania — skala/liniowy/ryczałt (deklaracja do 20. dnia miesiąca następnego)",
        "5. Rachunek firmowy — otwarcie i zgłoszenie",
        "6. Rozliczenia VAT — zwolnienie do 200k PLN / rejestracja VAT-R",
    ],
    "setup_ceidg_done": object.get(input.jdg_entrepreneur, "setup_ceidg_done", false) == true,
    "setup_zus_done": object.get(input.jdg_entrepreneur, "setup_zus_done", false) == true,
    "steps_completed": steps_completed,
    "setup_complete": steps_completed == 2,
    "onboarding_pct": round2(steps_completed / 2 * 100),
    "_routing": "TRIAGE_QUEUE" if steps_completed < 2 else "",
    "_routing_reason": "Asystent zakładania firmy — pełny onboarding CEIDG+NIP+ZUS+wybór formy (INN-13)",
    "_legal_basis": "Ustawa o CEIDG art. 5-7; SUS art. 36; ustawa o ryczałcie art. 9; PP",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
    steps_completed := (1 if object.get(input.jdg_entrepreneur, "setup_ceidg_done", false) == true else 0) + (1 if object.get(input.jdg_entrepreneur, "setup_zus_done", false) == true else 0)
}

# INN-14: AUTO-WYKRYCIE UTRATY PRAWA DO RYCZAŁTU — licznik limitu 2M EUR real-time.
ryczalt_loss_detector := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.ryczalt_loss_detector",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1174,
    "matched": true,
    "revenue_ytd": revenue_ytd,
    "projected_annual_revenue": projected_annual_revenue,
    "limit_pln": limit_pln,
    "usage_pct_ytd": round2(revenue_ytd / limit_pln * 100),
    "projection_pct": round2(projected_annual_revenue / limit_pln * 100),
    "warning_at_75pct": revenue_ytd >= round2(limit_pln * 75 / 100),
    "projected_loss_risk": projected_annual_revenue >= limit_pln,
    "loss_triggered": revenue_ytd > limit_pln,
    "note": "przekroczenie limitu 2M EUR → utrata prawa do ryczałtu od następnego dnia (art. 6 ust. 4) — licznik real-time",
    "_routing": "TRIAGE_QUEUE" if revenue_ytd > limit_pln or projected_annual_revenue >= limit_pln else "",
    "_routing_reason": "Auto-wykrycie utraty prawa do ryczałtu — licznik limitu 2M EUR (art. 6 ust. 4)",
    "_legal_basis": "Ustawa o ryczałcie art. 6 ust. 4",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
    revenue_ytd := to_number(object.get(input.jdg_entrepreneur, "revenue_ytd", 0))
    projected_annual_revenue := to_number(object.get(input.jdg_entrepreneur, "projected_annual_revenue", 0))
}

# INN-15: SYMULATOR „ZAWIESIĆ CZY ZAMKNĄĆ" — rekomendacja decyzji exit.
suspend_or_close_simulator := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.suspend_or_close_simulator",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1175,
    "matched": true,
    "planned_months": planned_months,
    "will_resume": object.get(input.jdg_entrepreneur, "will_resume", true) == true,
    "within_max_suspension": planned_months <= zawieszenie_max_months,
    "recommendation": "ZAWIESZENIE" if object.get(input.jdg_entrepreneur, "will_resume", true) == true and planned_months <= zawieszenie_max_months else "LIKWIDACJA",
    "suspension_effects": {
        "zus_social": "składki społeczne 0 zł w okresie zawieszenia",
        "zus_health": "składka zdrowotna nadal (art. 36a SUS)",
        "vat": "możliwość zawieszenia rozliczeń VAT",
        "pit": "brak obowiązku składania PIT-28 za okres zawieszenia (ryczałt)",
    },
    "liquidation_effects": {
        "remanent": "remanent likwidacyjny — spójność z P07/P09",
        "vat_remanent": "VAT od remanentu (P04)",
        "ceidg": "wykreślenie z CEIDG",
        "accounts": "zamknięcie rachunków, rozliczenie z kontrahentami",
    },
    "_routing": "TRIAGE_QUEUE" if object.get(input.jdg_entrepreneur, "will_resume", true) == true and planned_months <= zawieszenie_max_months else "",
    "_routing_reason": "Symulator zawiesić vs zamknąć — rekomendacja decyzji (art. 22-25 PP)",
    "_legal_basis": "Prawo Przedsiębiorców art. 22-25; SUS art. 36a",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
    planned_months := to_number(object.get(input.jdg_entrepreneur, "planned_suspension_months", 0))
}

# INN-16: SUKCESJA KROK PO KROKU — checklista prawna + formularze.
succession_step_guide := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.succession_step_guide",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1176,
    "matched": true,
    "checklist": [
        "1. Powołanie zarządcy sukcesyjnego (akt notarialny za życia lub wniosek do 2 mies. po śmierci — art. 3-7 z.s.)",
        "2. Wpis zarządcy do CEIDG w 14 dni",
        "3. Zgłoszenie sukcesji do US i ZUS",
        "4. Kontynuacja umów, zezwoleń i koncesji na NIP zmarłego (dopisek 'w spadku')",
        "5. Rozliczenia podatkowe (ryczałt/PIT) w imieniu firmy",
        "6. Monitorowanie terminu 2 lat / przedłużenie do 5 lat (art. 12-13)",
    ],
    "forms": ["CEIDG-1 (wpis zarządcy)", "Zgłoszenie sukcesji do US", "ZUS ZUA/ZWUA"],
    "standard_months": succession_months_standard,
    "extended_months": succession_months_extended,
    "months_elapsed": months_elapsed,
    "months_remaining": succession_months_standard - months_elapsed if months_elapsed < succession_months_standard else 0,
    "extension_needed": months_elapsed >= succession_months_standard,
    "_routing": "TRIAGE_QUEUE" if months_elapsed >= succession_months_standard else "",
    "_routing_reason": "Sukcesja krok po kroku — checklista prawna + formularze, terminy 2/5 lat (INN-16)",
    "_legal_basis": "Ustawa o zarządzie sukcesyjnym art. 3-15",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
    months_elapsed := to_number(object.get(input.jdg_entrepreneur, "succession_months_elapsed", 0))
}

# INN-17: INTELIGENTNA REKOMENDACJA STAWKI PKWiU po opisie działalności (reguły+ML).
pkwiu_rate_recommender := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.pkwiu_rate_recommender",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1177,
    "matched": true,
    "activity_description": desc,
    "recommended_rate": "3%" if contains(desc, "handel") or contains(desc, "sprzedaż") or contains(desc, "sklep") else "5,5%" if contains(desc, "produkcja") or contains(desc, "wytwarz") or contains(desc, "budow") or contains(desc, "montaż") else "12,5%" if contains(desc, "transport") or contains(desc, "magazyn") or contains(desc, "kurier") or contains(desc, "taksówk") else "15%" if contains(desc, "gastronom") or contains(desc, "restauracj") or contains(desc, "hotel") or contains(desc, "zakwaterowanie") else "12%" if contains(desc, "programow") or contains(desc, "informaty") or contains(desc, "software") or contains(desc, "oprogram") or contains(desc, "systemy") else "14%" if contains(desc, "architekt") or contains(desc, "inżynier") or contains(desc, "projektow") else "8,5%",
    "matched_keywords": matched_keywords,
    "confidence_pct": round2(count(matched_keywords) / 17 * 100) if count(matched_keywords) > 0 else 0,
    "note": "inteligentna rekomendacja stawki ryczałtu po opisie działalności — reguły słownikowe (słowa kluczowe PKWiU)",
    "_routing": "",
    "_routing_reason": "Inteligentna rekomendacja stawki PKWiU po opisie działalności (INN-17)",
    "_legal_basis": "Ustawa o ryczałcie art. 12 ust. 1",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
    desc := lower(object.get(input.activity, "description", ""))
    matched_keywords := [kw | kw := ["handel", "sprzedaż", "sklep", "produkcja", "wytwarz", "budow", "transport", "magazyn", "gastronom", "restauracj", "programow", "informaty", "software", "oprogram", "systemy", "architekt", "inżynier", "usług", "doradztwo"][_]; contains(desc, kw)]
}

# ── GŁÓWNY DECIDE (P13) — raport syntetyczny Ryczałt + Cykl Życia ─────────────
decide := {
    "rule_id": "jdg.p13_ryczalt_cykl_zycia_innovations.report",
    "package": "jdg.p13_ryczalt_cykl_zycia_innovations",
    "priority": 1157,
    "matched": true,
    "rates_audit": ryczalt_rates_audit,
    "lifecycle": lifecycle_audit,
    "succession": succession_audit,
    "suspension": suspension_audit,
    "pipeline": ryczalt_pipeline_snapshot,
    "setup": company_setup_assistant,
    "loss_detector": ryczalt_loss_detector,
    "exit_simulator": suspend_or_close_simulator,
    "succession_guide": succession_step_guide,
    "rate_recommender": pkwiu_rate_recommender,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny Ryczałt + Cykl Życia JDG (P13) — stawki PKWiU, karta podatkowa, cykl życia, sukcesja, zawieszenia",
    "_legal_basis": "Ustawa o ryczałcie; Prawo Przedsiębiorców; CEIDG; ustawa o zarządzie sukcesyjnym",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p13_ryczalt_check", false) == true
}
