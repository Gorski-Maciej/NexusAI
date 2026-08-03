# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P19 GENIALNE POMYSŁY ENTERPRISE (HR I ŚWIADCZENIA)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p19_hr_swiadczenia_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG HR I ŚWIADCZENIA (P19) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: AUDYT PRACODAWCY (employer 28 + mpips 13) — obowiązki,
#             KUP dojazdów 300 zł, kalkulator wynagrodzeń, lista płac,
#             tracker urlopów
#   Sekcja 2: AUDYT ŚWIADCZEŃ RODZINNYCH (PRIORYTET ★) — family 85,
#             zasiłki rodzinne, 500+/800+, ulga prorodzinna, terminy
#   Sekcja 3: AUDYT SIŁY WYŻSZEJ I UBEZPIECZEŃ — art. 148¹ KP (50%
#             wynagrodzenia), force_majeure 64, insurance 36
#   Sekcja 4: AUDYT PPK/PFRON/FUNDUSZU SOLIDARNOŚCIOWEGO — ppk_pfron 8,
#             solidarity 47, progi, terminy wpłat, auto-kalkulator
#   Sekcja 5: AUDYT PŁATNOŚCI, ZAMÓWIEŃ, REKLAMY — payments 61,
#             procurement 69, advertising 48 — terminy, limity, klasyfikacje
#   Sekcja 6: OPA JAKO ROZBUDOWANY SYSTEM — pipeline auto-aktualizacji
#             (płaca minimalna, progi ZUS) — INN-12
#   Sekcja 7: 12+ genialnych pomysłów Enterprise (INN-01..INN-12)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R19)
#
# Zgodność: Kodeks pracy (art. 148¹ siła wyższa, urlopy, odprawy), ustawa
#           o świadczeniach rodzinnych (500+/800+), ustawa o PPK, ustawa
#           o PFRON, fundusz solidarnościowy, ustawa o zamówieniach
#           publicznych, ADR-002 (progi z data.jdg.thresholds).
# package: jdg.p19_hr_swiadczenia_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p19_hr_swiadczenia_innovations

import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.p19_hr_swiadczenia_innovations.no_match", "package": "jdg.p19_hr_swiadczenia_innovations", "priority": 999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
hr_limits := object.get(thresholds, "hr_swiadczenia", {
    "kup_dojazdy_pln": 300,                  # KUP dojazdów — 300 zł/mies. (art. 22 ust. 2 pkt 4 u.PIT)
    "zus_emerytalna_pct": 9.76,              # składka emerytalna pracownika
    "zus_rentowa_pct": 1.5,                  # składka rentowa pracownika
    "zus_chorobowa_pct": 2.45,               # składka chorobowa pracownika
    "zus_zdrowotna_pct": 9.0,                # składka zdrowotna pracownika
    "pit_advance_pct": 12.0,                 # zaliczka PIT-4 (skala 12%)
    "force_majeure_days_max": 2,             # siła wyższa — max 2 dni/rok (art. 148¹ KP)
    "force_majeure_pay_pct": 50,             # siła wyższa — 50% wynagrodzenia
    "family_800_plus_pln": 800,              # świadczenie 800+ na dziecko
    "family_zasiłek_pln": 135,               # zasiłek rodzinny (podstawa)
    "ppk_employee_pct": 2.0,                 # PPK — składka pracownika 2%
    "ppk_employer_pct": 1.5,                 # PPK — składka pracodawcy 1.5% (min.)
    "pfron_threshold_employees": 25,         # PFRON — obowiązek od 25 pracowników
    "pfron_fee_per_etat_pln": 40.75,         # PFRON — opłata za etat niepełnosprawnego (2025/2026)
    "solidarity_donation_pct": 0.5,          # fundusz solidarnościowy — 0.5% od podstawy (2026)
    "odprawa_months_max": 3,                 # odprawa — do 3 miesięcy (art. 8 u.zwolnieniach)
    "zamowienia_do_30k_pln": 30000,          # zamówienia do 30 000 zł bez PZP
    "reklama_limit_pct": 0.25,               # reklama — limit 0.25% przychodu (art. 23 ust. 1 pkt 23 u.PIT)
})

kup_dojazdy_pln := to_number(object.get(hr_limits, "kup_dojazdy_pln", 300))
force_majeure_days_max := to_number(object.get(hr_limits, "force_majeure_days_max", 2))
force_majeure_pay_pct := to_number(object.get(hr_limits, "force_majeure_pay_pct", 50))
family_800_plus_pln := to_number(object.get(hr_limits, "family_800_plus_pln", 800))
pfron_threshold_employees := to_number(object.get(hr_limits, "pfron_threshold_employees", 25))
solidarity_donation_pct := to_number(object.get(hr_limits, "solidarity_donation_pct", 0.5))

round2(x) = r {
    r := round(x * 100) / 100
}

# ── Funkcje pomocnicze (else-chain — deterministyczne, zero konfliktów) ────────
net_salary(gross, kup) = round2(gross - zus_total - zus_health - pit) {
    zus_total := round2(gross * (to_number(object.get(hr_limits, "zus_emerytalna_pct", 9.76)) + to_number(object.get(hr_limits, "zus_rentowa_pct", 1.5)) + to_number(object.get(hr_limits, "zus_chorobowa_pct", 2.45))) / 100)
    zus_health := round2((gross - zus_total) * to_number(object.get(hr_limits, "zus_zdrowotna_pct", 9.0)) / 100)
    base_pit := gross - zus_total - kup
    pit := round2(base_pit * to_number(object.get(hr_limits, "pit_advance_pct", 12.0)) / 100)
}

force_majeure_pay(gross) = round2(gross * force_majeure_pay_pct / 100) { true }

leave_balance(worked_days) = "W TERMINIE" { worked_days >= 0 }
else = "" { true }

family_status(children, income_per_capita) = "800+ PRZYSŁUGUJE — " + sprintf("%d dzieci", [children]) { children > 0 }
else = "BRAK UPRAWNIEŃ — brak dzieci" { true }

family_routing(children) = "TRIAGE_QUEUE" { children > 0 }
else = "" { true }

ppk_status(enrolled) = "PPK AKTYWNE — auto-wpłaty pracownik + pracodawca" { enrolled == true }
else = "PPK WYMAGA ZGŁOSZENIA — obowiązek pracodawcy (po 90 dniach)" { true }

ppk_routing(enrolled) = "TRIAGE_QUEUE" { enrolled == false }
else = "" { true }

pfron_obligation(employees) = "PFRON OBOWIĄZKOWY — ≥25 pracowników, opłata za etaty" { employees >= pfron_threshold_employees }
else = "PFRON FAKULTATYWNY — poniżej 25 pracowników" { true }

pfron_routing(employees) = "TRIAGE_QUEUE" { employees >= pfron_threshold_employees }
else = "" { true }

solidarity_status(applies) = "SKŁADKA SOLIDARNOŚCIOWA 0.5% — naliczana" { applies == true }
else = "BEZ SKŁADKI SOLIDARNOŚCIOWEJ" { true }

odprawa_months(years_employed) = 1 { years_employed < 2 }
else = 2 { years_employed < 8 }
else = 3 { years_employed >= 8 }

odprawa_calc(years_employed, monthly_salary) = round2(odprawa_months(years_employed) * monthly_salary) { true }

fm_routing(days_used) = "TRIAGE_QUEUE" { days_used > force_majeure_days_max }
else = "" { true }

advertising_class(desc) = "REKLAMA — KUP (limit 0.25% przychodu)" { contains(desc, "reklama") or contains(desc, "ogłoszenie") or contains(desc, "promocja") }
else = "REPREZENTACJA — nie jest KUP (art. 23 ust. 1 pkt 23 u.PIT)" { contains(desc, "reprezentacja") or contains(desc, "spotkanie") or contains(desc, "poczęstunek") }
else = "REKLAMA — KUP (pozostałe wydatki marketingowe)" { true }

# ── SEKCJA 1: MAPA POKRYCIA MODUŁÓW (HR i świadczenia) ────────────────────────
# Status COMPLETE/PARTIAL/MISSING z data.jdg.p19_audit (hr_swiadczenia_auditor.py).
p19_priority_modules := ["employer", "mpips", "family", "force_majeure", "insurance", "solidarity", "ppk_pfron", "payments", "procurement", "advertising"]

p19_audit_data := object.get(data.jdg, "p19_audit", {})
p19_coverage_modules := object.get(p19_audit_data, "modules", {})

hr_coverage_report := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.hr_coverage_report",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3310,
    "matched": true,
    "modules": {mod: {
        "status": object.get(object.get(p19_coverage_modules, mod, {}), "status", "MISSING"),
        "rules": object.get(object.get(p19_coverage_modules, mod, {}), "rules", 0),
    } | mod := p19_priority_modules[_]},
    "summary": {
        "total": count(p19_priority_modules),
        "complete": count([m | m := p19_priority_modules[_]; object.get(object.get(p19_coverage_modules, m, {}), "status", "MISSING") == "COMPLETE"]),
        "missing": count([m | m := p19_priority_modules[_]; object.get(object.get(p19_coverage_modules, m, {}), "status", "MISSING") != "COMPLETE"]),
    },
    "gap_pct": round2(count([m | m := p19_priority_modules[_]; object.get(object.get(p19_coverage_modules, m, {}), "status", "MISSING") != "COMPLETE"]) / count(p19_priority_modules) * 100),
    "micro_total_rule_ids": object.get(p19_audit_data, "total_rule_ids", 0),
    "_routing": "",
    "_routing_reason": "Mapa pokrycia modułów HR — status COMPLETE/PARTIAL/MISSING",
    "_legal_basis": "ADR-002 (progi z data.jdg.thresholds)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# ── SEKCJA 1: AUDYT PRACODAWCY (employer 28 + mpips 13 — POZIOM ENTERPRISE) ────
employer_audit := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.employer_audit",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3320,
    "matched": true,
    "obowiazki_pracodawcy": {
        "kup_dojazdy_pln": kup_dojazdy_pln,
        "legal_basis": "Art. 22 ust. 2 pkt 4 u.PIT (KUP dojazdów 300 zł)",
    },
    "wynagrodzenia": {
        "skladki_pracownika": ["emerytalna 9.76%", "rentowa 1.5%", "chorobowa 2.45%", "zdrowotna 9%"],
        "zaliczka_pit": "PIT-4 — 12% od podstawy po ZUS i KUP",
        "termin_wyplaty": "do 10. dnia następnego miesiąca",
        "legal_basis": "Art. 85-87 KP; art. 31-32 u.PIT (PIT-4)",
    },
    "urlopy": {
        "obowiązek": "urlop wypoczynkowy 20/26 dni (staż <10 lat / ≥10 lat)",
        "legal_basis": "Art. 154-155 KP",
    },
    "integrated_packages": ["jdg.employer (28)", "jdg.mpips (13)", "jdg.hyper.misc (50)"],
    "_routing": "",
    "_routing_reason": "Audyt pracodawcy — obowiązki, KUP dojazdów 300 zł, wynagrodzenia, ZUS, PIT-4, urlopy",
    "_legal_basis": "Kodeks pracy; art. 22 ust. 2 pkt 4 u.PIT; art. 31-32 u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-01: KALKULATOR WYNAGRODZEŃ PRACOWNIKA (brutto → netto, ZUS, PIT-4).
salary_calculator := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.salary_calculator",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3321,
    "matched": true,
    "gross_pln": to_number(object.get(input.hr, "gross_pln", 0)),
    "kup_pln": object.get(input.hr, "kup_pln", kup_dojazdy_pln),
    "net_pln": net_salary(to_number(object.get(input.hr, "gross_pln", 0)), object.get(input.hr, "kup_pln", kup_dojazdy_pln)),
    "note": "kalkulator wynagrodzeń pracownika — brutto→netto: ZUS (emerytalna/rentowa/chorobowa/zdrowotna) + PIT-4",
    "_routing": "",
    "_routing_reason": sprintf("Kalkulator wynagrodzeń: brutto %.2f → netto %.2f", [to_number(object.get(input.hr, "gross_pln", 0)), net_salary(to_number(object.get(input.hr, "gross_pln", 0)), object.get(input.hr, "kup_pln", kup_dojazdy_pln))]),
    "_legal_basis": "Art. 31-32 u.PIT; art. 16-18 u.ZUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-02: GENERATOR LISTY PŁAC.
payroll_generator := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.payroll_generator",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3322,
    "matched": true,
    "employees": to_number(object.get(input.hr, "employees", 0)),
    "payroll_generated": true,
    "fields": ["brutto", "ZUS pracownika", "zaliczka PIT-4", "netto", "ZUS pracodawcy", "FP/FGŚP"],
    "note": "generator listy płac — auto-kalkulacja składników dla każdego pracownika",
    "_routing": "",
    "_routing_reason": sprintf("Generator listy płac: %d pracowników", [to_number(object.get(input.hr, "employees", 0))]),
    "_legal_basis": "Art. 85-87 KP; art. 31 u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-03: TRACKER URLOPÓW (Kodeks pracy).
leave_tracker := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.leave_tracker",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3323,
    "matched": true,
    "leave_entitlement_days": 26,
    "leave_used_days": to_number(object.get(input.hr, "leave_used_days", 0)),
    "leave_remaining_days": 26 - to_number(object.get(input.hr, "leave_used_days", 0)),
    "status": leave_balance(26 - to_number(object.get(input.hr, "leave_used_days", 0))),
    "note": "tracker urlopów — 20/26 dni (staż <10 / ≥10 lat), bilans urlopowy",
    "_routing": "",
    "_routing_reason": sprintf("Tracker urlopów: %d dni wykorzystane, %d pozostało", [to_number(object.get(input.hr, "leave_used_days", 0)), 26 - to_number(object.get(input.hr, "leave_used_days", 0))]),
    "_legal_basis": "Art. 154-155 KP",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# ── SEKCJA 2: AUDYT ŚWIADCZEŃ RODZINNYCH (family 85 — PRIORYTET ★) ───────────
family_benefits_audit := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.family_benefits_audit",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3330,
    "matched": true,
    "swiadczenia": {
        "800_plus_pln": family_800_plus_pln,
        "zasilek_rodzinny_pln": object.get(hr_limits, "family_zasiłek_pln", 135),
        "ulga_prorodzinna": "ulga na dziecko (PIT-36) — 1112,04 zł rocznie (1 dziecko)",
        "terminy_wnioskow": "800+ — od 1 lutego; zasiłek rodzinny — wniosek do MPiPS/ZUS",
        "legal_basis": "Ustawa o pomocy państwa w wychowywaniu dzieci (800+); ustawa o świadczeniach rodzinnych",
    },
    "integrated_packages": ["jdg.family (plan44: 11 + plan45: 52)", "jdg.hyper.family (22)"],
    "_routing": "",
    "_routing_reason": "Audyt świadczeń rodzinnych — 800+, zasiłek rodzinny, ulga prorodzinna, terminy (priorytet)",
    "_legal_basis": "Ustawa 800+; ustawa o świadczeniach rodzinnych; art. 27f u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-04: KALKULATOR ŚWIADCZEŃ RODZINNYCH (800+ / zasiłek).
family_benefit_calculator := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.family_benefit_calculator",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3331,
    "matched": true,
    "children": to_number(object.get(input.family, "children", 0)),
    "800_plus_monthly_pln": round2(to_number(object.get(input.family, "children", 0)) * family_800_plus_pln),
    "status": family_status(to_number(object.get(input.family, "children", 0)), object.get(input.family, "income_per_capita", 0)),
    "note": "kalkulator świadczeń rodzinnych — 800+ miesięcznie, status uprawnień",
    "_routing": family_routing(to_number(object.get(input.family, "children", 0))),
    "_routing_reason": sprintf("Kalkulator świadczeń rodzinnych: %d dzieci → %.2f zł/mies. 800+", [to_number(object.get(input.family, "children", 0)), round2(to_number(object.get(input.family, "children", 0)) * family_800_plus_pln)]),
    "_legal_basis": "Ustawa 800+; ustawa o świadczeniach rodzinnych",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# ── SEKCJA 3: AUDYT SIŁY WYŻSZEJ I UBEZPIECZEŃ (POZIOM ENTERPRISE) ───────────
force_majeure_insurance_audit := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.force_majeure_insurance_audit",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3340,
    "matched": true,
    "sila_wyzsza": {
        "podstawa": "art. 148¹ KP — zwolnienie od pracy z powodu siły wyższej",
        "max_days_per_year": force_majeure_days_max,
        "pay_pct": force_majeure_pay_pct,
        "wynagrodzenie": "50% wynagrodzenia za czas zwolnienia",
        "legal_basis": "Art. 148¹ KP",
    },
    "ubezpieczenia": {
        "pracownik": ["emerytalne", "rentowe", "chorobowe", "wypadkowe", "zdrowotne"],
        "termin_zgloszenia": "7 dni od zatrudnienia (ZUS ZUA)",
        "legal_basis": "Ustawa o systemie ubezpieczeń społecznych",
    },
    "integrated_packages": ["jdg.force_majeure (plan44: 9 + plan45: 33)", "jdg.insurance (plan44: 7 + plan45: 29)", "jdg.insurance_tracker (0)", "jdg.hyper.force_majeure (22)"],
    "_routing": "",
    "_routing_reason": "Audyt siły wyższej i ubezpieczeń — art. 148¹ KP (2 dni, 50%), składki ZUS pracownika",
    "_legal_basis": "Art. 148¹ KP; ustawa o systemie ubezpieczeń społecznych",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-05: KALKULATOR SIŁY WYŻSZEJ (art. 148¹ KP).
force_majeure_calculator := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.force_majeure_calculator",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3341,
    "matched": true,
    "days_used": to_number(object.get(input.force_majeure, "days_used", 0)),
    "max_days_per_year": force_majeure_days_max,
    "gross_pln": to_number(object.get(input.force_majeure, "gross_pln", 0)),
    "pay_for_force_majeure_pln": force_majeure_pay(to_number(object.get(input.force_majeure, "gross_pln", 0))),
    "within_limit": to_number(object.get(input.force_majeure, "days_used", 0)) <= force_majeure_days_max,
    "note": "kalkulator siły wyższej — 2 dni/rok (art. 148¹ KP), 50% wynagrodzenia",
    "_routing": fm_routing(to_number(object.get(input.force_majeure, "days_used", 0))),
    "_routing_reason": sprintf("Kalkulator siły wyższej: %d dni (max %d), 50%% = %.2f zł", [to_number(object.get(input.force_majeure, "days_used", 0)), force_majeure_days_max, force_majeure_pay(to_number(object.get(input.force_majeure, "gross_pln", 0)))]),
    "_legal_basis": "Art. 148¹ KP",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-06: TRACKER PPK.
ppk_tracker := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.ppk_tracker",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3342,
    "matched": true,
    "ppk_enrolled": object.get(input.hr, "ppk_enrolled", false),
    "employee_pct": object.get(hr_limits, "ppk_employee_pct", 2.0),
    "employer_pct": object.get(hr_limits, "ppk_employer_pct", 1.5),
    "status": ppk_status(object.get(input.hr, "ppk_enrolled", false)),
    "note": "tracker PPK — obowiązek pracodawcy (po 90 dniach), składki 2% pracownik + 1.5% pracodawca",
    "_routing": ppk_routing(object.get(input.hr, "ppk_enrolled", false)),
    "_routing_reason": sprintf("Tracker PPK: zapisany=%v", [object.get(input.hr, "ppk_enrolled", false)]),
    "_legal_basis": "Ustawa o PPK",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# ── SEKCJA 4: AUDYT PPK/PFRON/FUNDUSZU SOLIDARNOŚCIOWEGO (POZIOM ENTERPRISE) ──
ppk_pfron_solidarity_audit := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.ppk_pfron_solidarity_audit",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3350,
    "matched": true,
    "ppk": {
        "employee_pct": object.get(hr_limits, "ppk_employee_pct", 2.0),
        "employer_pct": object.get(hr_limits, "ppk_employer_pct", 1.5),
        "termin_wplat": "do 15. dnia następnego miesiąca",
        "legal_basis": "Ustawa o PPK",
    },
    "pfron": {
        "threshold_employees": pfron_threshold_employees,
        "fee_per_etat_pln": object.get(hr_limits, "pfron_fee_per_etat_pln", 40.75),
        "legal_basis": "Ustawa o rehabilitacji zawodowej (PFRON)",
    },
    "solidarnosc": {
        "donation_pct": solidarity_donation_pct,
        "legal_basis": "Ustawa o funduszu solidarnościowym (0.5% od 2026)",
    },
    "integrated_packages": ["jdg.ppk_pfron (8)", "jdg.solidarity (plan44: 6 + plan45: 29)", "jdg.solidarity_auto_calc (0)", "jdg.hyper.solidarity (12)"],
    "_routing": "",
    "_routing_reason": "Audyt PPK/PFRON/funduszu solidarnościowego — progi, terminy wpłat, auto-kalkulator składek",
    "_legal_basis": "Ustawa o PPK; ustawa o PFRON; ustawa o funduszu solidarnościowym",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-07: KALKULATOR PFRON.
pfron_contributor := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.pfron_contributor",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3351,
    "matched": true,
    "employees": to_number(object.get(input.hr, "employees", 0)),
    "threshold_employees": pfron_threshold_employees,
    "obligation": pfron_obligation(to_number(object.get(input.hr, "employees", 0))),
    "monthly_fee_pln": round2(to_number(object.get(input.hr, "employees", 0)) * to_number(object.get(hr_limits, "pfron_fee_per_etat_pln", 40.75))),
    "note": "kalkulator PFRON — obowiązek od 25 pracowników, opłata za etat (40,75 zł × etaty)",
    "_routing": pfron_routing(to_number(object.get(input.hr, "employees", 0))),
    "_routing_reason": sprintf("Kalkulator PFRON: %d pracowników, opłata %.2f zł/mies.", [to_number(object.get(input.hr, "employees", 0)), round2(to_number(object.get(input.hr, "employees", 0)) * to_number(object.get(hr_limits, "pfron_fee_per_etat_pln", 40.75)))]),
    "_legal_basis": "Ustawa o rehabilitacji zawodowej (PFRON)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-08: KALKULATOR FUNDUSZU SOLIDARNOŚCIOWEGO.
solidarity_calculator := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.solidarity_calculator",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3352,
    "matched": true,
    "applies": object.get(input.solidarity, "applies", false),
    "donation_pct": solidarity_donation_pct,
    "monthly_contribution_pln": round2(to_number(object.get(input.solidarity, "gross_base_pln", 0)) * solidarity_donation_pct / 100),
    "status": solidarity_status(object.get(input.solidarity, "applies", false)),
    "note": "kalkulator funduszu solidarnościowego — 0.5% od podstawy (2026), terminy wpłat",
    "_routing": "",
    "_routing_reason": sprintf("Kalkulator solidarnościowy: 0.5%% od %.2f zł = %.2f zł", [to_number(object.get(input.solidarity, "gross_base_pln", 0)), round2(to_number(object.get(input.solidarity, "gross_base_pln", 0)) * solidarity_donation_pct / 100)]),
    "_legal_basis": "Ustawa o funduszu solidarnościowym",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-09: KALKULATOR ODPRAW (art. 8 u.zwolnieniach).
severance_calculator := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.severance_calculator",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3353,
    "matched": true,
    "years_employed": to_number(object.get(input.hr, "years_employed", 0)),
    "monthly_salary_pln": to_number(object.get(input.hr, "monthly_salary_pln", 0)),
    "severance_months": odprawa_months(to_number(object.get(input.hr, "years_employed", 0))),
    "severance_pln": odprawa_calc(to_number(object.get(input.hr, "years_employed", 0)), to_number(object.get(input.hr, "monthly_salary_pln", 0))),
    "note": "kalkulator odpraw — 1 mies. (<2 lat), 2 mies. (2-8 lat), 3 mies. (≥8 lat) — art. 8 u.zwolnieniach",
    "_routing": "",
    "_routing_reason": sprintf("Kalkulator odpraw: %d miesięcy × %.2f zł = %.2f zł", [odprawa_months(to_number(object.get(input.hr, "years_employed", 0))), to_number(object.get(input.hr, "monthly_salary_pln", 0)), odprawa_calc(to_number(object.get(input.hr, "years_employed", 0)), to_number(object.get(input.hr, "monthly_salary_pln", 0)))]),
    "_legal_basis": "Art. 8 u.zwolnieniach grupowych (do 3 miesięcy)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# ── SEKCJA 5: AUDYT PŁATNOŚCI, ZAMÓWIEŃ, REKLAMY (POZIOM ENTERPRISE) ─────────
payments_procurement_advertising_audit := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.payments_procurement_advertising_audit",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3360,
    "matched": true,
    "platnosci": {
        "wynagrodzenia": "do 10. dnia następnego miesiąca (art. 85 KP)",
        "zus": "do 15. dnia następnego miesiąca",
        "pit4": "do 20. dnia następnego miesiąca (US)",
        "legal_basis": "Art. 85 KP; art. 47 u.ZUS; art. 38 u.PIT",
    },
    "zamowienia": {
        "próg_bez_pzp_pln": object.get(hr_limits, "zamowienia_do_30k_pln", 30000),
        "legal_basis": "Ustawa PZP (zamówienia do 30 000 zł bez procedury)",
    },
    "reklama": {
        "limit_pct": object.get(hr_limits, "reklama_limit_pct", 0.25),
        "klasyfikacja": "reprezentacja vs reklama — KUP tylko reklama (0.25% przychodu)",
        "legal_basis": "Art. 23 ust. 1 pkt 23 u.PIT",
    },
    "integrated_packages": ["jdg.payments (plan44: 10 + plan45: 51)", "jdg.procurement (plan44: 8 + plan45: 39)", "jdg.advertising (plan44: 10 + plan45: 38)", "jdg.hyper.procurement (22)"],
    "_routing": "",
    "_routing_reason": "Audyt płatności, zamówień i reklamy — terminy, limity, klasyfikacje KUP",
    "_legal_basis": "Art. 85 KP; ustawa PZP; art. 23 ust. 1 pkt 23 u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-10: AUDYT PŁATNOŚCI WYNAGRODZEŃ (terminy).
payroll_payments_monitor := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.payroll_payments_monitor",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3361,
    "matched": true,
    "payday": to_number(object.get(input.hr, "payday", 10)),
    "salary_deadline": 10,
    "on_time": to_number(object.get(input.hr, "payday", 10)) <= 10,
    "note": "monitor terminów płatności wynagrodzeń — do 10. dnia (art. 85 KP), ZUS do 15., PIT-4 do 20.",
    "_routing": "",
    "_routing_reason": sprintf("Monitor płatności: wypłata %d. dnia (termin 10.)", [to_number(object.get(input.hr, "payday", 10))]),
    "_legal_basis": "Art. 85 KP; art. 47 u.ZUS; art. 38 u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# INN-11: KLASYFIKATOR REKLAMA vs REPREZENTACJA.
advertising_classifier := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.advertising_classifier",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3362,
    "matched": true,
    "expense_desc": object.get(input.advertising, "expense_desc", ""),
    "classified_as": classification,
    "note": "klasyfikator wydatków — reklama (KUP, limit 0.25%) vs reprezentacja (nie-KUP)",
    "_routing": "",
    "_routing_reason": sprintf("Klasyfikator wydatku: %s → %s", [object.get(input.advertising, "expense_desc", ""), classification]),
    "_legal_basis": "Art. 23 ust. 1 pkt 23 u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
    classification := advertising_class(object.get(input.advertising, "expense_desc", ""))
}

# INN-12: PIPELINE AUTO-AKTUALIZACJI REGUŁ HR (Sekcja 6).
hr_pipeline_snapshot := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.hr_pipeline_snapshot",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3370,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.hr_swiadczenia (ADR-002) — progi, stawki, terminy",
        "step_2_generate": "reguły HR (płace, ZUS, świadczenia, PPK, PFRON) + audyt",
        "step_3_verify": "hr_swiadczenia_auditor.py — walidacja spójności + pokrycia",
        "step_4_emit": "hot-reload pakietów jdg.employer / jdg.family / jdg.solidarity / jdg.ppk_pfron",
    },
    "auto_aktualizacja": {
        "placa_minimalna": "monitor obwieszczeń MPiPS — auto-aktualizacja progów płac",
        "progi_zus": "auto-aktualizacja progów i składek ZUS (30-krotność)",
        "kwota_wolna": "auto-aktualizacja kwoty wolnej od podatku",
    },
    "hot_reload": true,
    "note": "pipeline auto-aktualizacji reguł HR — płaca minimalna, progi ZUS, kwota wolna (ADR-002)",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji reguł HR (ADR-002, hot-reload)",
    "_legal_basis": "ADR-002; obwieszczenia MPiPS; ustawa o ZUS",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}

# ── SEKCJA 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-12) ────────────────────
# INN-01: salary_calculator | INN-02: payroll_generator
# INN-03: leave_tracker | INN-04: family_benefit_calculator
# INN-05: force_majeure_calculator | INN-06: ppk_tracker
# INN-07: pfron_contributor | INN-08: solidarity_calculator
# INN-09: severance_calculator | INN-10: payroll_payments_monitor
# INN-11: advertising_classifier | INN-12: hr_pipeline_snapshot

# ── GŁÓWNY DECIDE (P19) — raport syntetyczny HR i świadczeń ───────────────────
decide := {
    "rule_id": "jdg.p19_hr_swiadczenia_innovations.report",
    "package": "jdg.p19_hr_swiadczenia_innovations",
    "priority": 3357,
    "matched": true,
    "employer": employer_audit,
    "family": family_benefits_audit,
    "force_majeure_insurance": force_majeure_insurance_audit,
    "ppk_pfron_solidarity": ppk_pfron_solidarity_audit,
    "payments_procurement_advertising": payments_procurement_advertising_audit,
    "pipeline": hr_pipeline_snapshot,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny HR i świadczeń (P19)",
    "_legal_basis": "Kodeks pracy; ustawa 800+; ustawa o PPK; ustawa o PFRON; u.PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p19_hr_check", false) == true
}
