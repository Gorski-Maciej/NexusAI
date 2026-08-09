# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P11 GENIALNE POMYSŁY ENTERPRISE (Ordynacja Podatkowa)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p11_ordynacja_podatkowa_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG ORDYNACJA PODATKOWA (P11) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: Mapa pokrycia artykułów OrdPU — art. 16-193a (424 reguły micro)
#            + status COMPLETE/PARTIAL/MISSING z data.jdg.ordpu_audit
#   Sekcja 2: AUDYT PRZEDAWNIEŃ (PRIORYTET) — art. 70: 5 lat od końca roku,
#            przerwanie (§4), zawieszenie (§6), koniec roku, przedawnienie a
#            korekty + KALENDARZ PRZEDAWNIEŃ per zobowiązanie z alertami (INN-01)
#   Sekcja 3: AUDYT KOREKT I NADPŁAT — art. 81/81b (korekty, limit 5 lat),
#            art. 72-80 (nadpłata, zwrot, oprocentowanie) + silnik auto-korekty
#            z wyliczeniem odsetek (INN-04)
#   Sekcja 4: AUDYT AUTO-KORESPONDENCJI Z URZĘDEM — system pełnej obsługi
#            postępowań od A do Z (pismo → decyzja), integracja z pakietami
#            tax_authority_interaction / proceeding_tracker / poa_manager
#   Sekcja 5: AUDYT GAAR I BIAŁEJ LISTY — art. 119a (GAAR: sztuczność, korzyść),
#            art. 117ba (Biała Lista, 30 dni, sankcja 20%) + monitoring
#   Sekcja 6: OPA jako rozbudowany system — pipeline auto-aktualizacji reguł
#            proceduralnych (ADR-002, hot-reload)
#   Sekcja 7: 15+ genialnych pomysłów Enterprise (INN-01..INN-15)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R11)
#
# Zgodność: OrdPU (Dz.U. 2025 poz. 234): art. 14a-14d, 53-56, 67a-67e, 70,
#           72-81b, 117ba, 119a, 120-129, 138a-138o, 193a; ADR-002 (progi z
#           data.jdg.thresholds — zero hardcode), ADR-006.
# package: jdg.p11_ordynacja_podatkowa_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p11_ordynacja_podatkowa_innovations

import future.keywords.in
import future.keywords.if

default decide := {"matched": false, "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.no_match", "package": "jdg.p11_ordynacja_podatkowa_innovations", "priority": 999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
ord_limits := object.get(thresholds, "ordpu", {
    "limitation_years": 5,              # art. 70 §1 — 5 lat od końca roku
    "correction_years": 5,              # art. 81b — korekta do 5 lat
    "interest_rate_pct": 200,           # art. 56 §1 — 200% lombardu
    "white_list_days": 30,              # art. 117ba — zawiadomienie 30 dni
    "white_list_penalty_pct": 20,       # art. 117ba — sankcja 20%
    "overpayment_refund_months": 3,     # art. 77 — zwrot nadpłaty 3 mies.
    "interpretation_days": 30,          # art. 14d — wydanie interpretacji 30 dni
    "appeal_days": 14,                  # art. 223 — odwołanie 14 dni
    "gaar_artificiality_threshold": 60, # art. 119a — próg sztuczności (0-100)
})

limitation_years := to_number(object.get(ord_limits, "limitation_years", 5))
correction_years := to_number(object.get(ord_limits, "correction_years", 5))
interest_rate_pct := to_number(object.get(ord_limits, "interest_rate_pct", 200))
white_list_days := to_number(object.get(ord_limits, "white_list_days", 30))
white_list_penalty_pct := to_number(object.get(ord_limits, "white_list_penalty_pct", 20))
overpayment_refund_months := to_number(object.get(ord_limits, "overpayment_refund_months", 3))
interpretation_days := to_number(object.get(ord_limits, "interpretation_days", 30))
appeal_days := to_number(object.get(ord_limits, "appeal_days", 14))
gaar_artificiality_threshold := to_number(object.get(ord_limits, "gaar_artificiality_threshold", 60))

round2(x) = r {
    r := round(x * 100) / 100
}

# ── SEKCJA 1: MAPA POKRYCIA ARTYKUŁÓW ORDPU ───────────────────────────────────
# Priorytetowe artykuły: czynny żal (16), odsetki (53-56), ulgi (67a-e),
# przedawnienie (70), nadpłaty (72-80), korekty (81/81b), GAAR (119a),
# Biała Lista (117ba), interpretacje (14a/14d), pełnomocnictwa (138a), JPK (193a).
ordpu_priority_articles := ["a16", "a53", "a56b", "a67a", "a67b", "a67c", "a67d", "a67e", "a70", "a72", "a77", "a78", "a81", "a81b", "a117ba", "a119a", "a138a", "a193a", "a14a", "a14d"]

ordpu_audit_data := object.get(data.jdg, "ordpu_audit", {})
ordpu_coverage_articles := object.get(ordpu_audit_data, "articles", {})

ordpu_coverage_report := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.ordpu_coverage_report",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1010,
    "matched": true,
    "articles": {art: {
        "status": object.get(object.get(ordpu_coverage_articles, art, {}), "status", "MISSING"),
        "rules": object.get(object.get(ordpu_coverage_articles, art, {}), "rules", 0),
    } | art := ordpu_priority_articles[_]},
    "summary": {
        "total": count(ordpu_priority_articles),
        "complete": count([a | a := ordpu_priority_articles[_]; object.get(object.get(ordpu_coverage_articles, a, {}), "status", "MISSING") == "COMPLETE"]),
        "missing": count([a | a := ordpu_priority_articles[_]; object.get(object.get(ordpu_coverage_articles, a, {}), "status", "MISSING") != "COMPLETE"]),
    },
    "gap_pct": round2(count([a | a := ordpu_priority_articles[_]; object.get(object.get(ordpu_coverage_articles, a, {}), "status", "MISSING") != "COMPLETE"]) / count(ordpu_priority_articles) * 100),
    "micro_total_rule_ids": object.get(ordpu_audit_data, "total_rule_ids", 424),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia artykułów OrdPU (art. 16-193a) — status COMPLETE/PARTIAL/MISSING",
    "_legal_basis": "OrdPU art. 14a-14d, 53-56, 67a-67e, 70, 72-81b, 117ba, 119a, 138a, 193a",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# ── SEKCJA 2: AUDYT PRZEDAWNIEŃ (POZIOM ENTERPRISE — PRIORYTET) ───────────────
# art. 70 §1: zobowiązanie przedawnia się z upływem 5 lat od końca roku
# podatkowego. Przerwanie (§4): decyzja/egzekucja. Zawieszenie (§6): np.
# postępowanie karne. Przedawnienie a korekty: brak możliwości po przedawnieniu.
limitation_engine := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.limitation_engine",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1020,
    "matched": true,
    "tax_year": to_number(object.get(input.jdg_entrepreneur, "tax_year", 2026)),
    "limitation_years": limitation_years,
    "deadline_year": to_number(object.get(input.jdg_entrepreneur, "tax_year", 2026)) + to_number(object.get(ord_limits, "limitation_years", 5)),
    "deadline": sprintf("31.12.%v", [to_number(object.get(input.jdg_entrepreneur, "tax_year", 2026)) + to_number(object.get(ord_limits, "limitation_years", 5))]),
    "interruption": {
        "acts": "decyzja ustalająca/określająca, czynność egzekucyjna (art. 70 §4)",
        "effect": "bieg przedawnienia rozpoczyna się na nowo",
    },
    "suspension": {
        "cases": "postępowanie karne (podejrzenie przestępstwa), zawieszenie postępowania (art. 70 §6)",
        "effect": "bieg przedawnienia ulega zawieszeniu",
    },
    "corrections_after_limitation": "po przedawnieniu zobowiązania korekta nie może zwiększyć zobowiązania (art. 70 §1 w zw. z art. 81)",
    "_routing": "",
    "_routing_reason": "Audyt przedawnień — art. 70: 5 lat od końca roku, przerwanie §4, zawieszenie §6, koniec roku",
    "_legal_basis": "OrdPU art. 70 §1, §4, §6",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-01: KALENDARZ PRZEDAWNIEŃ per zobowiązanie z alertami.
limitation_calendar := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.limitation_calendar",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1021,
    "matched": true,
    "liabilities": object.get(input.liabilities, [], []),
    "alerts": [a | a := {
        "tax_type": l.tax_type,
        "tax_year": l.tax_year,
        "deadline": sprintf("31.12.%v", [l.tax_year + limitation_years]),
        "years_left": (l.tax_year + limitation_years) - to_number(object.get(input.jdg_entrepreneur, "current_year", 2026)),
    } | l := object.get(input.liabilities, [], [])[_]],
    "urgent": [a | a := object.get(input.liabilities, [], [])[_]; (a.tax_year + limitation_years) - to_number(object.get(input.jdg_entrepreneur, "current_year", 2026)) <= 1],
    "_routing": "",
    "_routing_reason": "Kalendarz przedawnień per zobowiązanie z alertami (art. 70 OrdPU)",
    "_legal_basis": "OrdPU art. 70 §1",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-02: Kalkulator odsetek za zwłokę (art. 56 — stawka 200% lombardu).
interest_calculator := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.interest_calculator",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1022,
    "matched": true,
    "arrears": to_number(object.get(input.liability, "arrears", 0)),
    "days_overdue": to_number(object.get(input.liability, "days_overdue", 0)),
    "annual_rate_pct": interest_rate_pct,
    "daily_rate": round2(interest_rate_pct / 365),
    "interest_due": round2(to_number(object.get(input.liability, "arrears", 0)) * (interest_rate_pct / 365) / 100 * to_number(object.get(input.liability, "days_overdue", 0))),
    "note": sprintf("stawka podstawowa 200%% lombardu (art. 56 §1) — odsetki: %.2f PLN za %v dni", [round2(to_number(object.get(input.liability, "arrears", 0)) * (interest_rate_pct / 365) / 100 * to_number(object.get(input.liability, "days_overdue", 0))), to_number(object.get(input.liability, "days_overdue", 0))]),
    "_routing": "",
    "_routing_reason": "Kalkulator odsetek za zwłokę — 200% lombardu (art. 56 OrdPU)",
    "_legal_basis": "OrdPU art. 53-56",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# ── SEKCJA 3: AUDYT KOREKT I NADPŁAT ──────────────────────────────────────────
corrections_overpayment_audit := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.corrections_overpayment_audit",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1030,
    "matched": true,
    "correction": {
        "art81": "korekta deklaracji — złożenie skorygowanej deklaracji",
        "art81b": "korekta możliwa do 5 lat od końca roku podatkowego",
        "limit_years": correction_years,
    },
    "overpayment": {
        "art72": "nadpłata — nadpłacony podatek (deklaracja, decyzja, zaliczka)",
        "art77": sprintf("zwrot nadpłaty — do %v miesięcy od złożenia wniosku", [overpayment_refund_months]),
        "art78": "oprocentowanie nadpłaty — od dnia powstania do dnia zwrotu",
    },
    "_routing": "",
    "_routing_reason": "Audyt korekt (art. 81/81b, limit 5 lat) i nadpłat (art. 72-80, zwrot, oprocentowanie)",
    "_legal_basis": "OrdPU art. 72-81b",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-03: Silnik auto-korekty deklaracji z wyliczeniem odsetek.
auto_correction_engine := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.auto_correction_engine",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1031,
    "matched": true,
    "original_tax": to_number(object.get(input.correction, "original_tax", 0)),
    "corrected_tax": to_number(object.get(input.correction, "corrected_tax", 0)),
    "difference": round2(to_number(object.get(input.correction, "corrected_tax", 0)) - to_number(object.get(input.correction, "original_tax", 0))),
    "direction": "nadpłata (zwrot)" if to_number(object.get(input.correction, "corrected_tax", 0)) - to_number(object.get(input.correction, "original_tax", 0)) < 0 else "dopłata (zaległość)" if to_number(object.get(input.correction, "corrected_tax", 0)) - to_number(object.get(input.correction, "original_tax", 0)) > 0 else "bez zmian",
    "within_5y": to_number(object.get(input.correction, "tax_year", 2026)) >= to_number(object.get(input.jdg_entrepreneur, "current_year", 2026)) - correction_years,
    "interest_on_arrears": round2(abs(to_number(object.get(input.correction, "corrected_tax", 0)) - to_number(object.get(input.correction, "original_tax", 0))) * (interest_rate_pct / 365) / 100 * to_number(object.get(input.correction, "days_overdue", 0))) if to_number(object.get(input.correction, "corrected_tax", 0)) - to_number(object.get(input.correction, "original_tax", 0)) > 0 else 0,
    "_routing": "",
    "_routing_reason": "Silnik auto-korekty deklaracji z wyliczeniem odsetek (art. 81/81b OrdPU)",
    "_legal_basis": "OrdPU art. 81, 81b, 56",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# ── SEKCJA 4: AUDYT AUTO-KORESPONDENCJI Z URZĘDEM ─────────────────────────────
# System pełnej obsługi postępowań od A do Z (pismo → decyzja). Integruje
# istniejące pakiety enterprise: tax_authority_interaction, tax_correspondence_engine,
# tax_ruling_autodrafter, overpayment_auto_claimer, proceeding_tracker, poa_manager.
correspondence_audit := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.correspondence_audit",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1040,
    "matched": true,
    "integrated_packages": [
        "tax_authority_interaction (auto-generacja pism do US/KAS/ZUS)",
        "tax_correspondence_engine (silnik korespondencji)",
        "tax_ruling_autodrafter (auto-draft interpretacji)",
        "overpayment_auto_claimer (auto-wnioski o zwrot nadpłaty)",
        "proceeding_tracker (tracker postępowań)",
        "poa_manager (pełnomocnictwa art. 138a-138o)",
    ],
    "proceeding_flow": [
        "1. Pismo do US (wniosek/zawiadomienie)",
        "2. Postępowanie podatkowe (art. 120-129: czynny udział, prawda obiektywna)",
        "3. Decyzja / interpretacja (art. 14d — 30 dni)",
        "4. Odwołanie (14 dni, art. 223)",
        "5. Rozstrzygnięcie II instancji / sąd",
    ],
    "appeal_days": appeal_days,
    "interpretation_days": interpretation_days,
    "_routing": "",
    "_routing_reason": "Audyt auto-korespondencji — system obsługi postępowań od A do Z",
    "_legal_basis": "OrdPU art. 14a-14d, 120-129, 138a-138o, 223",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-04: Tracker postępowania podatkowego — od pisma do decyzji.
proceeding_tracker := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.proceeding_tracker",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1041,
    "matched": true,
    "stage": object.get(input.proceeding, "stage", "wniosek"),
    "stages": ["wniosek", "uzupełnienie", "postępowanie", "decyzja", "odwołanie", "rozstrzygnięcie"],
    "deadline_days": interpretation_days if object.get(input.proceeding, "stage", "wniosek") == "wniosek" else appeal_days if object.get(input.proceeding, "stage", "wniosek") == "odwołanie" else appeal_days if object.get(input.proceeding, "stage", "wniosek") == "decyzja" else 30,
    "next_action": "monitoruj termin wydania interpretacji (30 dni)" if object.get(input.proceeding, "stage", "wniosek") == "wniosek" else "złóż odwołanie w 14 dni" if object.get(input.proceeding, "stage", "wniosek") == "decyzja" else "kontynuuj postępowanie",
    "_routing": "",
    "_routing_reason": "Tracker postępowania podatkowego — od pisma do decyzji",
    "_legal_basis": "OrdPU art. 120-129, 223",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-05: Generator pisma do US (auto-korespondencja).
correspondence_generator := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.correspondence_generator",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1042,
    "matched": true,
    "letter_type": object.get(input.letter, "type", "wniosek_o_interpretacje"),
    "template": {
        "wniosek_o_interpretacje": ["Dane podatnika", "Stan faktyczny", "Pytanie", "Stanowisko podatnika", "OrdPU art. 14b"],
        "odwołanie": ["Decyzja (nr, data)", "Zarzuty", "Uzasadnienie", "Wniosek o uchylenie", "OrdPU art. 223"],
        "wniosek_o_zwrot_nadplaty": ["Dane podatnika", "Kwota nadpłaty", "Rachunek", "OrdPU art. 72-77"],
        "czynny_żal": ["Zawiadomienie o popełnieniu czynu", "Ujawnienie okoliczności", "OrdPU/KKS art. 16"],
    },
    "_routing": "",
    "_routing_reason": "Generator pism do US — auto-korespondencja (interpretacje, odwołania, nadpłaty, czynny żal)",
    "_legal_basis": "OrdPU art. 14b, 72-77, 223",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# ── SEKCJA 5: AUDYT GAAR I BIAŁEJ LISTY ───────────────────────────────────────
gaar_audit := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.gaar_audit",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1050,
    "matched": true,
    "art119a": {
        "conditions": ["korzyść podatkowa", "sprzeczność z celem ustawy", "sztuczność działania"],
        "artificiality_threshold": gaar_artificiality_threshold,
        "effect": "pominięcie skutków czynności sztucznej — domiar podatku",
    },
    "artificiality_score": to_number(object.get(input.jdg_entrepreneur, "artificiality_score", 0)),
    "gaar_risk": "WYSOKIE" if to_number(object.get(input.jdg_entrepreneur, "artificiality_score", 0)) >= gaar_artificiality_threshold else "NISKIE",
    "_routing": "",
    "_routing_reason": "Audyt GAAR — art. 119a: korzyść, sprzeczność z celem, sztuczność",
    "_legal_basis": "OrdPU art. 119a-119l",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-06: Monitor Białej Listy (art. 117ba) — 30 dni, sankcja 20%.
white_list_monitor := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.white_list_monitor",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1051,
    "matched": true,
    "vendor_white_listed": object.get(input.payment, "vendor_white_listed", true),
    "paid_to_listed_account": object.get(input.payment, "paid_to_listed_account", true),
    "notified_within_30d": object.get(input.payment, "notified_within_30d", true),
    "sanction": round2(to_number(object.get(input.payment, "amount", 0)) * white_list_penalty_pct / 100) if object.get(input.payment, "vendor_white_listed", true) == true and object.get(input.payment, "paid_to_listed_account", true) == false and object.get(input.payment, "notified_within_30d", true) == false else 0,
    "sanction_pct": white_list_penalty_pct,
    "note": "płatność na rachunek spoza Białej Listy bez zawiadomienia w 30 dni → sankcja 20% (art. 117ba OrdPU)",
    "_routing": "",
    "_routing_reason": "Monitor Białej Listy — art. 117ba: 30 dni, sankcja 20%",
    "_legal_basis": "OrdPU art. 117ba",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# ── SEKCJA 6: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE TEMPORALNY ───────────────
ordpu_pipeline_snapshot := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.ordpu_pipeline_snapshot",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1060,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.ordpu (ADR-002) — terminy, stawki",
        "step_2_generate": "reguły proceduralne (art. 70, 81, 117ba, 119a)",
        "step_3_verify": "ordpu_auditor.py — walidacja spójności",
        "step_4_emit": "hot-reload pakietów jdg.limitations / jdg.interest_calculator",
    },
    "auto_update": "zmiany Ordynacji (nowe terminy, nowe stawki) → pipeline auto-aktualizacji reguł proceduralnych",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji reguł proceduralnych OrdPU (ADR-002)",
    "_legal_basis": "OrdPU (Dz.U. 2025 poz. 234); ADR-002",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# ── SEKCJA 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-15) ────────────────────
# INN-01: limitation_calendar | INN-02: interest_calculator
# INN-03: auto_correction_engine | INN-04: proceeding_tracker
# INN-05: correspondence_generator | INN-06: white_list_monitor

# INN-07: Silnik ryzyka kontroli skarbowej.
# Score = SUMA składników: gotówka +20, straty 3 lata +25, rozbieżność +30,
# transakcje z podmiotami powiązanymi +15 → NISKIE/ŚREDNIE/WYSOKIE.
inspection_risk_score(input) = score {
    score := (
        (20 if object.get(input.jdg_entrepreneur, "cash_only_operations", false) == true else 0)
        + (25 if to_number(object.get(input.jdg_entrepreneur, "loss_years", 0)) >= 3 else 0)
        + (30 if object.get(input.jdg_entrepreneur, "declared_vs_reported_variance", 0) > 0.20 else 0)
        + (15 if object.get(input.jdg_entrepreneur, "related_party_transactions", false) == true else 0)
    )
}

inspection_risk_engine := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.inspection_risk_engine",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1070,
    "matched": true,
    "risk_indicators": {
        "cash_only": object.get(input.jdg_entrepreneur, "cash_only_operations", false),
        "losses_streak": to_number(object.get(input.jdg_entrepreneur, "loss_years", 0)) >= 3,
        "variance_high": object.get(input.jdg_entrepreneur, "declared_vs_reported_variance", 0) > 0.20,
        "related_parties": object.get(input.jdg_entrepreneur, "related_party_transactions", false),
    },
    "risk_score": inspection_risk_score(input),
    "risk_level": "WYSOKIE" if inspection_risk_score(input) >= 40 else "ŚREDNIE" if inspection_risk_score(input) >= 20 else "NISKIE",
    "_routing": "",
    "_routing_reason": "Silnik ryzyka kontroli skarbowej — scoring wskaźników",
    "_legal_basis": "OrdPU art. 120-129 (postępowanie)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-08: Generator wniosku o ulgi w spłacie (art. 67a-67e).
relief_application_generator := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.relief_application_generator",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1071,
    "matched": true,
    "relief_types": {
        "art67a": "odroczenie terminu płatności / rozłożenie na raty",
        "art67b": "opłata prolongacyjna",
        "art67c": "umorzenie zaległości podatkowej (ważny interes podatnika)",
        "art67d": "zaniechanie poboru",
        "art67e": "ulgi w spłacie zobowiązań",
    },
    "template": ["Wniosek o ulgę w spłacie (art. 67a-67e OrdPU)", "Dane podatnika", "Rodzaj ulgi", "Uzasadnienie (ważny interes / interes publiczny)", "Załączniki"],
    "_routing": "",
    "_routing_reason": "Generator wniosków o ulgi w spłacie (art. 67a-67e OrdPU)",
    "_legal_basis": "OrdPU art. 67a-67e",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-09: Tracker interpretacji podatkowych (art. 14a-14d).
interpretation_tracker := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.interpretation_tracker",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1072,
    "matched": true,
    "interpretations": object.get(input.interpretations, [], []),
    "deadline_days": interpretation_days,
    "protection": "ochrona podatnika — zastosowanie się do interpretacji chroni przed sankcjami (art. 14k-14m)",
    "_routing": "",
    "_routing_reason": "Tracker interpretacji podatkowych (art. 14a-14d) — ochrona art. 14k-14m",
    "_legal_basis": "OrdPU art. 14a-14m",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-10: Menedżer pełnomocnictw (art. 138a-138o).
poa_manager := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.poa_manager",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1073,
    "matched": true,
    "poa_forms": ["pełnomocnictwo ogólne", "pełnomocnictwo szczególne", "pełnomocnictwo do doręczeń"],
    "filing": "pełnomocnictwo składa się przez formularz UPL-1 / pełnomocnictwo w EPUAP",
    "_routing": "",
    "_routing_reason": "Menedżer pełnomocnictw (art. 138a-138o OrdPU)",
    "_legal_basis": "OrdPU art. 138a-138o",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-11: Tracker JPK na żądanie (art. 193a).
jpk_demand_tracker := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.jpk_demand_tracker",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1074,
    "matched": true,
    "jpk_types": ["JPK_VAT", "JPK_KR (księgi rachunkowe)", "JPK_MAG (magazyn)", "JPK_FA (faktury)"],
    "deadline_note": "termin złożenia JPK na żądanie zależy od rodzaju i wielkości podatnika (art. 193a §2)",
    "_routing": "",
    "_routing_reason": "Tracker JPK na żądanie (art. 193a OrdPU)",
    "_legal_basis": "OrdPU art. 193a",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-12: Asystent czynnego żalu (art. 16 OrdPU/KKS).
czynny_zal_assistant := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.czynny_zal_assistant",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1075,
    "matched": true,
    "disclosure_before_detection": object.get(input.jdg_entrepreneur, "disclosure_before_detection", false),
    "control_started": object.get(input.jdg_entrepreneur, "control_started", false),
    "worth_filing": object.get(input.jdg_entrepreneur, "disclosure_before_detection", false) == true and object.get(input.jdg_entrepreneur, "control_started", false) == false,
    "effect": "brak odpowiedzialności karnej skarbowej (art. 16 §1)" if object.get(input.jdg_entrepreneur, "disclosure_before_detection", false) == true and object.get(input.jdg_entrepreneur, "control_started", false) == false else "czynny żal bezskuteczny — kontrola rozpoczęta",
    "_routing": "",
    "_routing_reason": "Asystent czynnego żalu — czy warto złożyć (art. 16 OrdPU/KKS)",
    "_legal_basis": "OrdPU art. 16; KKS art. 16",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-13: Kalkulator korzyści GAAR vs legalna optymalizacja.
gaar_benefit_calculator := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.gaar_benefit_calculator",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1076,
    "matched": true,
    "scheme_benefit": to_number(object.get(input.scheme, "tax_benefit", 0)),
    "artificiality": to_number(object.get(input.scheme, "artificiality", 0)),
    "risk": "GAAR_APPLIES" if to_number(object.get(input.scheme, "tax_benefit", 0)) > 0 and to_number(object.get(input.scheme, "artificiality", 0)) >= gaar_artificiality_threshold else "LEGAL",
    "note": "sztuczność >= 60/100 przy korzyści → ryzyko zastosowania art. 119a (domiar + sankcje)",
    "_routing": "",
    "_routing_reason": "Kalkulator korzyści GAAR vs legalna optymalizacja (art. 119a OrdPU)",
    "_legal_basis": "OrdPU art. 119a-119f",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-14: Auto-aktualizacja terminów proceduralnych (hook temporalny).
ordpu_template_hook := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.ordpu_template_hook",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1077,
    "matched": true,
    "source": "data.jdg.thresholds.ordpu (ADR-002)",
    "trigger": "zmiana Ordynacji (nowe terminy / stawki odsetek / progi)",
    "steps": ["ingest", "generate", "verify", "emit"],
    "hot_reload": true,
    "_routing": "",
    "_routing_reason": "Hook auto-aktualizacji terminów proceduralnych OrdPU",
    "_legal_basis": "OrdPU (Dz.U. 2025 poz. 234); ADR-002",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-15: Panel zgodności proceduralnej (compliance score).
ordpu_compliance_panel := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.ordpu_compliance_panel",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1078,
    "matched": true,
    "checks": {
        "przedawnienie_monitoring": "kalendarz art. 70 — alerty",
        "korekty_w_limicie": sprintf("korekta do %v lat (art. 81b)", [correction_years]),
        "odsetki": "kalkulator 200% lombardu (art. 56)",
        "biala_lista": "monitoring 30 dni / sankcja 20% (art. 117ba)",
        "gaar": "scoring sztuczności (art. 119a)",
        "postępowania": "tracker od pisma do decyzji (art. 120-129)",
    },
    "compliance_score": 100 - to_number(object.get(input.jdg_entrepreneur, "compliance_penalties", 0)) * 10,
    "_routing": "",
    "_routing_reason": "Panel zgodności proceduralnej OrdPU — compliance score",
    "_legal_basis": "OrdPU art. 53-56, 67a-67e, 70, 81b, 117ba, 119a, 120-129",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# ── SEKCJA 7b: NOWE INNOWACJE P11 v9.1 (INN-16..INN-19) ────────────────────────
# INN-16: TRACKER "MILCZĄCEGO ZAŁATWIENIA SPRAWY" (art. 139 — po 2 mies. decyzja pozytywna z mocy prawa).
silent_settlement_tracker := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.silent_settlement_tracker",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1079,
    "matched": true,
    "proceeding_started": object.get(input.jdg_entrepreneur, "proceeding_started", false) == true,
    "months_elapsed": to_number(object.get(input.jdg_entrepreneur, "proceeding_months_elapsed", 0)),
    "default_settlement_deadline_months": 2,
    "silent_positive_settlement": silent_positive_settlement,
    "note": "art. 139 — brak decyzji po 2 mies. → załatwienie sprawy z mocy prawa (sprawy szczególnie skomplikowane: dodatkowe 2 mies.)",
    "_routing": "TRIAGE_QUEUE" if silent_positive_settlement else "",
    "_routing_reason": "Tracker milczącego załatwienia sprawy (art. 139) — brak decyzji po 2 mies. → pozytywne z mocy prawa",
    "_legal_basis": "OrdPU art. 139",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
    silent_positive_settlement := object.get(input.jdg_entrepreneur, "proceeding_started", false) == true and to_number(object.get(input.jdg_entrepreneur, "proceeding_months_elapsed", 0)) >= 2 and object.get(input.jdg_entrepreneur, "proceeding_decision_issued", false) == false
}

# INN-17: KALKULATOR OPŁACALNOŚCI KOREKTY (art. 81) vs ryzyko kontroli skarbowej.
correction_profitability_calculator := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.correction_profitability_calculator",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1080,
    "matched": true,
    "tax_difference": to_number(object.get(input.jdg_entrepreneur, "tax_difference", 0)),
    "correction_cost": correction_cost,
    "inspection_risk_pct": to_number(object.get(input.jdg_entrepreneur, "inspection_risk_pct", 20)),
    "expected_penalty": expected_penalty,
    "correction_profitable": correction_profitable,
    "recommendation": "ZŁÓŻ_KOREKTĘ" if correction_profitable else "ANALIZA_Z_DORADCA",
    "_routing": "",
    "_routing_reason": "Kalkulator opłacalności korekty deklaracji (art. 81) vs ryzyko kontroli skarbowej",
    "_legal_basis": "OrdPU art. 81; KKS art. 54-56",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
    correction_cost := round2(to_number(object.get(input.jdg_entrepreneur, "tax_difference", 0)) * to_number(object.get(ord_limits, "correction_interest_pct", 0.15)))
    expected_penalty := round2(to_number(object.get(input.jdg_entrepreneur, "tax_difference", 0)) * to_number(object.get(input.jdg_entrepreneur, "inspection_risk_pct", 20)) / 100 * to_number(object.get(ord_limits, "kks_penalty_multiplier", 1.5)))
    correction_profitable := correction_cost < expected_penalty
}

# INN-18: SYMULATOR ULG W SPŁACIE (art. 67a-67e) — umorzenie vs raty vs odroczenie.
relief_simulator := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.relief_simulator",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1081,
    "matched": true,
    "tax_arrears": to_number(object.get(input.jdg_entrepreneur, "tax_arrears", 0)),
    "relief_options": {
        "umorzenie": {"art": "67a", "effect": "całkowite/częściowe umorzenie zaległości", "eligibility": object.get(input.jdg_entrepreneur, "important_taxpayer_interest", false) == true or object.get(input.jdg_entrepreneur, "public_interest", false) == true},
        "raty": {"art": "67d", "effect": "rozłożenie na raty — płatność w czasie", "eligibility": object.get(input.jdg_entrepreneur, "able_to_pay_installments", false) == true},
        "odroczenie": {"art": "67d", "effect": "odroczenie terminu płatności", "eligibility": object.get(input.jdg_entrepreneur, "temporary_liquidity_issue", false) == true},
    },
    "recommendation": "WNIOSEK_O_UMORZENIE" if object.get(input.jdg_entrepreneur, "important_taxpayer_interest", false) == true or object.get(input.jdg_entrepreneur, "public_interest", false) == true else "WNIOSEK_O_RATY" if object.get(input.jdg_entrepreneur, "able_to_pay_installments", false) == true else "WNIOSEK_O_ODROCZENIE" if object.get(input.jdg_entrepreneur, "temporary_liquidity_issue", false) == true else "BRAK_ULGI",
    "_routing": "",
    "_routing_reason": "Symulator ulgi w spłacie (art. 67a-67e) — umorzenie vs raty vs odroczenie (ważny interes podatnika / interes publiczny)",
    "_legal_basis": "OrdPU art. 67a, 67d",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# INN-19: AUTO-WYKRYWANIE PRZEDAWNIENIA — wstrzymanie działań windykacyjnych (art. 70).
prescription_windup_guard := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.prescription_windup_guard",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1082,
    "matched": true,
    "liability_year": to_number(object.get(input.jdg_entrepreneur, "liability_year", 2020)),
    "current_year": to_number(object.get(input.jdg_entrepreneur, "current_year", 2026)),
    "limitation_years": limitation_years,
    "years_elapsed": to_number(object.get(input.jdg_entrepreneur, "current_year", 2026)) - to_number(object.get(input.jdg_entrepreneur, "liability_year", 2020)),
    "prescribed": to_number(object.get(input.jdg_entrepreneur, "current_year", 2026)) - to_number(object.get(input.jdg_entrepreneur, "liability_year", 2020)) >= limitation_years,
    "action": "WSTRZYMAJ_DZIALANIA_WINDYKACYJNE — zobowiązanie przedawnione (art. 70 §1)" if to_number(object.get(input.jdg_entrepreneur, "current_year", 2026)) - to_number(object.get(input.jdg_entrepreneur, "liability_year", 2020)) >= limitation_years else "ZOBOWIAZANIE_AKTYWNE — monitoring do przedawnienia",
    "_routing": "TRIAGE_QUEUE" if to_number(object.get(input.jdg_entrepreneur, "current_year", 2026)) - to_number(object.get(input.jdg_entrepreneur, "liability_year", 2020)) >= limitation_years else "",
    "_routing_reason": "Auto-wykrywanie przedawnienia zobowiązania (art. 70) — wstrzymanie windykacji",
    "_legal_basis": "OrdPU art. 70 §1",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}

# ── GŁÓWNY DECIDE (P11) — raport syntetyczny Ordynacja Podatkowa ──────────────
decide := {
    "rule_id": "jdg.p11_ordynacja_podatkowa_innovations.report",
    "package": "jdg.p11_ordynacja_podatkowa_innovations",
    "priority": 1057,
    "matched": true,
    "coverage": ordpu_coverage_report,
    "limitation_engine": limitation_engine,
    "corrections_overpayment": corrections_overpayment_audit,
    "correspondence": correspondence_audit,
    "gaar": gaar_audit,
    "white_list": white_list_monitor,
    "pipeline": ordpu_pipeline_snapshot,
    "silent_settlement": silent_settlement_tracker,
    "correction_profitability": correction_profitability_calculator,
    "relief_simulator": relief_simulator,
    "prescription_guard": prescription_windup_guard,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny Ordynacja Podatkowa (P11) — przedawnienia, korekty/nadpłaty, auto-korespondencja, GAAR, Biała Lista",
    "_legal_basis": "OrdPU (Dz.U. 2025 poz. 234): art. 14a-14d, 53-56, 67a-67e, 70, 72-81b, 117ba, 119a, 120-129, 138a-138o, 193a",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p11_ordynacja_check", false) == true
}
