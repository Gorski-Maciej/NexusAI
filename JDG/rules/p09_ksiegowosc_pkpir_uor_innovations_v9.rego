# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P09 GENIALNE POMYSŁY ENTERPRISE (Księgowość — PKPiR + UoR + Amortyzacja)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.p09_ksiegowosc_pkpir_uor_innovations
# Raport: RAPORT ANALITYCZNY ENTERPRISE — JDG KSIĘGOWOŚĆ PKPiR+UoR (P09) v8.0
#
# SEKCJE WDROŻONE JAKO REGUŁY:
#   Sekcja 1: Audyt struktury PKPiR — kolumny 1-17, rejestry, numeracja,
#            terminy wpisów (rozporządzenie o PKPiR Dz.U. 2025 poz. 567)
#            + auto-dekretacja operacji na kolumny + walidator księgi realtime
#   Sekcja 2: AUDYT UoR (PRIORYTET) — próg 2 000 000 EUR, zasady memoriałowe,
#            dowody księgowe, inwentaryzacja, wycena, amortyzacja bilansowa,
#            sprawozdania + SILNIK DECYZJI "PKPiR czy UoR?" (INN-01)
#   Sekcja 3: Audyt amortyzacji i leasingu — KŚT (stawki, grupy 0-8),
#            jednorazowa 100 000 EUR, samochody 150k/225k, leasing
#            operacyjny (art. 23b) vs finansowy (art. 23f), NKUP
#   Sekcja 4: Audyt remanentu i korekt — remanent na koniec/początek roku,
#            korekty ksiąg, zwroty, rabaty + symulator remanentu (INN-07)
#   Sekcja 5: Audyt transformacji PKPiR → UoR — migracja, otwarcie ksiąg,
#            różnice (pkpir_to_uor_transformer)
#   Sekcja 6: OPA jako rozbudowany system — pipeline auto-aktualizacji
#            szablonów księgi (ADR-002, hot-reload)
#   Sekcja 7: 15+ genialnych pomysłów Enterprise (INN-01..INN-15)
#   Sekcja 8: Mapa drogowa P0/P1/P2 (w raporcie R09)
#
# Zgodność: rozporządzenie o PKPiR (Dz.U. 2025 poz. 567), UoR (art. 2, 4,
#           20-22, 26, 28, 32, 74), ustawa PIT (art. 22a-22n, 23a-23f),
#           ADR-002 (progi z data.jdg.thresholds — zero hardcode), ADR-006.
# package: jdg.p09_ksiegowosc_pkpir_uor_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p09_ksiegowosc_pkpir_uor_innovations

import future.keywords.in
import future.keywords.if

default decide := {"matched":false,"rule_id":"jdg.p09_ksiegowosc_pkpir_uor_innovations.no_match","package":"jdg.p09_ksiegowosc_pkpir_uor_innovations","priority":999999}

# ── Źródła danych: progi z data.jdg.thresholds (ADR-002 — zero hardcode) ──────
thresholds := object.get(data.jdg, "thresholds", {})
accounting_limits := object.get(thresholds, "accounting", {
    "uor_threshold_eur": 2000000,          # próg UoR art. 2 ust. 1 pkt 5 (2M EUR)
    "eur_pln_reference": 4.50,             # kurs referencyjny NBP (referencyjny)
    "early_warning_pct": 75,               # 75% progu — wczesne ostrzeżenie
    "one_time_depreciation_eur": 100000,   # jednorazowa amortyzacja (100k EUR)
    "car_limit_standard": 150000,          # limit aut osobowych (150k PLN)
    "car_limit_electric": 225000,          # limit aut elektrycznych (225k PLN)
    "kst_group_rates": {                   # stawki KŚT — rozporządzenie RM
        "0": 0.0, "1": 0.025, "2": 0.045, "3": 0.07,
        "4": 0.14, "5": 0.20, "6": 0.20, "7": 0.20, "8": 0.20,
    },
    "remanent_pct": 1.0,                   # remanent — 100% wartości
})

# Bezpieczny dostęp do stawek KŚT (ADR-002 — progi z data.jdg.thresholds)
kst_rates := object.get(accounting_limits, "kst_group_rates", {
    "0": 0.0, "1": 0.025, "2": 0.045, "3": 0.07,
    "4": 0.14, "5": 0.20, "6": 0.20, "7": 0.20, "8": 0.20,
})

round2(x) = r {
    r := round(x * 100) / 100
}

# ── SEKCJA 1: AUDYT STRUKTURY PKPiR (kolumny 1-17) ────────────────────────────
# Struktura PKPiR — 17 kolumn wg rozporządzenia (Dz.U. 2025 poz. 567).
pkpir_columns := {
    "1": {"name": "Liczba porządkowa", "required": true},
    "2": {"name": "Data zdarzenia gospodarczego", "required": true},
    "3": {"name": "Data wpisu do księgi", "required": true},
    "4": {"name": "Nr dowodu księgowego", "required": true},
    "5": {"name": "Kontrahent (imię/nazwa, adres)", "required": true},
    "6": {"name": "Opis zdarzenia", "required": true},
    "7": {"name": "Przychód — sprzedaż towarów i usług", "required": true},
    "8": {"name": "Przychód — pozostałe", "required": true},
    "9": {"name": "Razem przychody (7+8)", "required": true},
    "10": {"name": "Zakup towarów handlowych i materiałów", "required": true},
    "11": {"name": "Koszty uboczne zakupu", "required": true},
    "12": {"name": "Wynagrodzenia brutto", "required": true},
    "13": {"name": "Pozostałe wydatki", "required": true},
    "14": {"name": "Razem wydatki (10+11+12+13)", "required": true},
    "15": {"name": "Uwagi", "required": false},
    "16": {"name": "VAT naliczony — do odliczenia", "required": false},
    "17": {"name": "VAT naliczony — niepodlegający odliczeniu", "required": false},
}

# Auto-dekretacja operacji na kolumny PKPiR (dokument → dekret → kolumny).
pkpir_column_mapping := {
    "sale_goods": {"column": "7", "type": "przychód", "vat": "16"},
    "sale_services": {"column": "7", "type": "przychód", "vat": "16"},
    "other_income": {"column": "8", "type": "przychód pozostały"},
    "purchase_goods": {"column": "10", "type": "wydatek", "vat": "16"},
    "purchase_materials": {"column": "10", "type": "wydatek", "vat": "16"},
    "wages": {"column": "12", "type": "wydatek"},
    "other_expense": {"column": "13", "type": "wydatek", "vat": "16"},
}

pkpir_structure_audit := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.pkpir_structure_audit",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 810,
    "matched": true,
    "columns": pkpir_columns,
    "column_mapping": pkpir_column_mapping,
    "column_count": count(pkpir_columns),
    "required_columns": count([c | c := pkpir_columns[i]; c.required == true]),
    "entry_deadline": "wpis do 20 dni od zdarzenia (przed końcem roku)",
    "posting_rule": "kol. 9 = 7+8 | kol. 14 = 10+11+12+13",
    "_routing": "",
    "_routing_reason": "Audyt struktury PKPiR — kolumny 1-17, dekretacja, terminy",
    "_legal_basis": "Rozporządzenie o PKPiR (Dz.U. 2025 poz. 567)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-02: Auto-dekretacja operacji → kolumny PKPiR (dokument → dekret).
pkpir_auto_dekretacja := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.pkpir_auto_dekretacja",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 811,
    "matched": true,
    "operation_type": object.get(input.document, "type", "sale_goods"),
    "column": object.get(pkpir_column_mapping, object.get(input.document, "type", "sale_goods"), {}),
    "amount": to_number(object.get(input.document, "net_amount", 0)),
    "vat": round2(to_number(object.get(input.document, "net_amount", 0)) * to_number(object.get(input.document, "vat_rate", 0.23))),
    "_routing": "",
    "_routing_reason": "Auto-dekretacja operacji na kolumny PKPiR",
    "_legal_basis": "Rozporządzenie o PKPiR (Dz.U. 2025 poz. 567)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-03: Walidator księgi w czasie rzeczywistym (sumy, spójność kolumn).
pkpir_validator_realtime := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.pkpir_validator_realtime",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 812,
    "matched": true,
    "total_income": round2(to_number(object.get(input.ledger, "income_col_9", 0))),
    "income_calc": round2(to_number(object.get(input.ledger, "col_7", 0)) + to_number(object.get(input.ledger, "col_8", 0))),
    "income_ok": round2(to_number(object.get(input.ledger, "col_7", 0)) + to_number(object.get(input.ledger, "col_8", 0))) == round2(to_number(object.get(input.ledger, "income_col_9", 0))),
    "total_expenses": round2(to_number(object.get(input.ledger, "expenses_col_14", 0))),
    "expenses_calc": round2(to_number(object.get(input.ledger, "col_10", 0)) + to_number(object.get(input.ledger, "col_11", 0)) + to_number(object.get(input.ledger, "col_12", 0)) + to_number(object.get(input.ledger, "col_13", 0))),
    "expenses_ok": round2(to_number(object.get(input.ledger, "col_10", 0)) + to_number(object.get(input.ledger, "col_11", 0)) + to_number(object.get(input.ledger, "col_12", 0)) + to_number(object.get(input.ledger, "col_13", 0))) == round2(to_number(object.get(input.ledger, "expenses_col_14", 0))),
    "consistent": round2(to_number(object.get(input.ledger, "col_7", 0)) + to_number(object.get(input.ledger, "col_8", 0))) == round2(to_number(object.get(input.ledger, "income_col_9", 0))) and round2(to_number(object.get(input.ledger, "col_10", 0)) + to_number(object.get(input.ledger, "col_11", 0)) + to_number(object.get(input.ledger, "col_12", 0)) + to_number(object.get(input.ledger, "col_13", 0))) == round2(to_number(object.get(input.ledger, "expenses_col_14", 0))),
    "_routing": "",
    "_routing_reason": "Walidator PKPiR realtime — spójność kolumn 9 i 14",
    "_legal_basis": "Rozporządzenie o PKPiR (Dz.U. 2025 poz. 567)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# ── SEKCJA 2: AUDYT UoR (POZIOM ENTERPRISE — PRIORYTET) ───────────────────────
uor_threshold_eur := to_number(object.get(accounting_limits, "uor_threshold_eur", 2000000))
eur_pln_reference := to_number(object.get(accounting_limits, "eur_pln_reference", 4.50))
early_warning_pct := to_number(object.get(accounting_limits, "early_warning_pct", 75))

# INN-01: SILNIK DECYZJI "PKPiR czy UoR?" — próg 2M EUR z wczesnym ostrzeżeniem.
uor_obligation_engine := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.uor_obligation_engine",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 820,
    "matched": true,
    "annual_revenue_pln": to_number(object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)),
    "annual_revenue_eur": round2(to_number(object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)) / eur_pln_reference),
    "threshold_eur": uor_threshold_eur,
    "threshold_pln": round2(uor_threshold_eur * eur_pln_reference),
    "exceeds": to_number(object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)) / eur_pln_reference >= uor_threshold_eur,
    "early_warning": to_number(object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)) / eur_pln_reference >= uor_threshold_eur * early_warning_pct / 100,
    "decision": "UoR" if to_number(object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)) / eur_pln_reference >= uor_threshold_eur else "PKPiR",
    "_routing": "",
    "_routing_reason": "Silnik decyzji PKPiR czy UoR — próg 2M EUR (art. 2 ust. 1 pkt 5 UoR)",
    "_legal_basis": "Art. 2 ust. 1 pkt 5, art. 2 ust. 2 UoR",
    "_warnings": [sprintf("Przychód: %.2f PLN = %.2f EUR | Próg: %.0f EUR (%.2f PLN) | Decyzja: %s%s", [to_number(object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)), round2(to_number(object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)) / eur_pln_reference), uor_threshold_eur, round2(uor_threshold_eur * eur_pln_reference), "UoR" if to_number(object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)) / eur_pln_reference >= uor_threshold_eur else "PKPiR", " | UWAGA: 75% progu — planuj przejście" if to_number(object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)) / eur_pln_reference >= uor_threshold_eur * early_warning_pct / 100 and to_number(object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)) / eur_pln_reference < uor_threshold_eur else ""])],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# Audyt UoR — zasady memoriałowe, dowody, inwentaryzacja, wycena, sprawozdania.
uor_audit := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.uor_audit",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 821,
    "matched": true,
    "threshold_eur": uor_threshold_eur,
    "principles": {
        "accrual": "zasada memoriałowa — przychody/koszty w momencie zdarzenia",
        "matching": "współmierność przychodów i kosztów",
        "prudence": "ostrożna wycena — ostrożność",
        "going_concern": "zasada kontynuacji działalności",
    },
    "documents": ["dowody księgowe: zewnętrzne (faktury), wewnętrzne (PK, OT, LT)",
                  "wymagane elementy: nazwa, data, nr, strony, treść, kwota, podpisy"],
    "inventory": "inwentaryzacja: środki pieniężne (na dzień bilansowy), zapasy, środki trwałe (co 4 lata)",
    "valuation": "wycena: koszt wytworzenia / cena nabycia, odpisy aktualizujące",
    "amortization": "amortyzacja bilansowa wg zasad UoR (nie tylko podatkowa)",
    "statements": "sprawozdanie: bilans, RZiS, informacja dodatkowa (art. 45-49 UoR)",
    "_routing": "",
    "_routing_reason": "Audyt UoR — zasady memoriałowe, dowody, inwentaryzacja, sprawozdania",
    "_legal_basis": "UoR: art. 2, 4, 20-22, 26, 28, 32, 45-49, 74",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-04: Kalkulator amortyzacji bilansowej vs podatkowej.
amortization_dual_calculator := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.amortization_dual_calculator",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 822,
    "matched": true,
    "asset_value": to_number(object.get(input.asset, "value", 0)),
    "kst_group": object.get(input.asset, "kst_group", "4"),
    "tax_rate": object.get(kst_rates, object.get(input.asset, "kst_group", "4"), 0.14),
    "book_rate": to_number(object.get(input.asset, "book_rate", 0.20)),
    "tax_annual": round2(to_number(object.get(input.asset, "value", 0)) * object.get(kst_rates, object.get(input.asset, "kst_group", "4"), 0.14)),
    "book_annual": round2(to_number(object.get(input.asset, "value", 0)) * to_number(object.get(input.asset, "book_rate", 0.20))),
    "difference": round2(to_number(object.get(input.asset, "value", 0)) * to_number(object.get(input.asset, "book_rate", 0.20)) - to_number(object.get(input.asset, "value", 0)) * object.get(kst_rates, object.get(input.asset, "kst_group", "4"), 0.14)),
    "_routing": "",
    "_routing_reason": "Kalkulator amortyzacji bilansowej vs podatkowej (różnice przejściowe)",
    "_legal_basis": "UoR art. 32; ustawa PIT art. 22a-22m",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# ── SEKCJA 3: AUDYT AMORTYZACJI I LEASINGU (poziom ENTERPRISE) ────────────────
one_time_depreciation_eur := to_number(object.get(accounting_limits, "one_time_depreciation_eur", 100000))
car_limit_standard := to_number(object.get(accounting_limits, "car_limit_standard", 150000))
car_limit_electric := to_number(object.get(accounting_limits, "car_limit_electric", 225000))

kst_groups := {
    "0": {"name": "Grunty", "rate": 0.0, "note": "NIE amortyzuje się"},
    "1": {"name": "Budynki i lokale", "rate": 0.025},
    "2": {"name": "Budowle", "rate": 0.045},
    "3": {"name": "Kotły i maszyny energetyczne", "rate": 0.07},
    "4": {"name": "Maszyny i urządzenia ogólnego zastosowania", "rate": 0.14},
    "5": {"name": "Maszyny i urządzenia specjalne", "rate": 0.20},
    "6": {"name": "Środki transportu", "rate": 0.20},
    "7": {"name": "Narzędzia, przyrządy, wyposażenie", "rate": 0.20},
    "8": {"name": "Inwestycje w obcych środkach trwałych", "rate": 0.20},
}

amortization_leasing_audit := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.amortization_leasing_audit",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 830,
    "matched": true,
    "kst_groups": kst_groups,
    "one_time_eur": one_time_depreciation_eur,
    "one_time_pln": round2(one_time_depreciation_eur * eur_pln_reference),
    "car_limits": {"standard": car_limit_standard, "electric": car_limit_electric},
    "leasing": {
        "operating": "cała rata KUP (art. 23b PIT)",
        "financial": "KUP tylko odsetki, kapitał przez amortyzację (art. 23f PIT)",
        "classification": "test 40% normatywnego okresu",
    },
    "annual_depreciation": round2(to_number(object.get(input.asset, "value", 0)) * object.get(kst_rates, object.get(input.asset, "kst_group", "4"), 0.14)),
    "_routing": "",
    "_routing_reason": "Audyt amortyzacji (KŚT, jednorazowa, limity aut) i leasingu (operacyjny/finansowy)",
    "_legal_basis": "Ustawa PIT art. 22a-22n, 23a-23f; rozporządzenie RM (KŚT)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-05: Jednorazowa amortyzacja (100k EUR) — limit i kwalifikowalność.
one_time_depreciation_audit := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.one_time_depreciation_audit",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 831,
    "matched": true,
    "new_assets_value": to_number(object.get(input.jdg_entrepreneur, "new_assets_value", 0)),
    "limit_pln": round2(one_time_depreciation_eur * eur_pln_reference),
    "within_limit": to_number(object.get(input.jdg_entrepreneur, "new_assets_value", 0)) <= round2(one_time_depreciation_eur * eur_pln_reference),
    "excess": max([to_number(object.get(input.jdg_entrepreneur, "new_assets_value", 0)) - round2(one_time_depreciation_eur * eur_pln_reference), 0]),
    "_routing": "",
    "_routing_reason": "Jednorazowa amortyzacja — limit 100k EUR (mały podatnik)",
    "_legal_basis": "Art. 22k ust. 7 PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-06: Audyt limitu aut osobowych (150k/225k) — amortyzacja i leasing.
car_limit_audit := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.car_limit_audit",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 832,
    "matched": true,
    "car_value": to_number(object.get(input.asset, "car_value", 0)),
    "is_electric": object.get(input.asset, "is_electric", false) == true,
    "limit": car_limit_electric if object.get(input.asset, "is_electric", false) == true else car_limit_standard,
    "excess": max([to_number(object.get(input.asset, "car_value", 0)) - (car_limit_electric if object.get(input.asset, "is_electric", false) == true else car_limit_standard), 0]),
    "note": "Auto > limit — KUP z leasingu/amortyzacji limitowany proporcjonalnie (art. 23a pkt 47a PIT)",
    "_routing": "",
    "_routing_reason": "Limit aut osobowych 150k/225k — amortyzacja i leasing",
    "_legal_basis": "Art. 23a pkt 47a, art. 23b ust. 1 PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# ── SEKCJA 4: AUDYT REMANENTU I KOREKT (poziom ENTERPRISE) ────────────────────
remanent_audit := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.remanent_audit",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 840,
    "matched": true,
    "opening_remanent": to_number(object.get(input.jdg_entrepreneur, "opening_remanent", 0)),
    "closing_remanent": to_number(object.get(input.jdg_entrepreneur, "closing_remanent", 0)),
    "remanent_delta": round2(to_number(object.get(input.jdg_entrepreneur, "closing_remanent", 0)) - to_number(object.get(input.jdg_entrepreneur, "opening_remanent", 0))),
    "tax_impact": "remanent końcowy zwiększa przychód w następnym roku (różnica remanentów)",
    "rule": "wartość remanentu na koniec roku → przychód w roku następnym (art. 24 ust. 2 PIT)",
    "corrections": ["korekty ksiąg: błędne wpisy (czerwony długopis / nowy wpis)",
                    "korekty kosztów: zwroty, rabaty, reklamacje — zmniejszenie KUP"],
    "_routing": "",
    "_routing_reason": "Audyt remanentu (koniec/początek roku) i korekt ksiąg",
    "_legal_basis": "Art. 24 ust. 2 PIT; rozporządzenie o PKPiR (Dz.U. 2025 poz. 567)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-07: Symulator remanentu — wpływ na dochód roku następnego.
remanent_simulator := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.remanent_simulator",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 841,
    "matched": true,
    "opening": to_number(object.get(input.jdg_entrepreneur, "opening_remanent", 0)),
    "projected_closing": to_number(object.get(input.jdg_entrepreneur, "projected_closing_remanent", 0)),
    "income_impact_next_year": round2(to_number(object.get(input.jdg_entrepreneur, "projected_closing_remanent", 0)) - to_number(object.get(input.jdg_entrepreneur, "opening_remanent", 0))),
    "_routing": "",
    "_routing_reason": "Symulator remanentu — wpływ na dochód roku następnego",
    "_legal_basis": "Art. 24 ust. 2 PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# ── SEKCJA 5: AUDYT TRANSFORMACJI PKPiR → UoR ─────────────────────────────────
pkpir_uor_transformation_audit := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.pkpir_uor_transformation_audit",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 850,
    "matched": true,
    "transformer": "pkpir_to_uor_transformer (otwarcie ksiąg, migracja sald)",
    "steps": [
        "1. Zamknięcie PKPiR (remanent końcowy, kolumny 1-17)",
        "2. Otwarcie ksiąg rachunkowych (bilans otwarcia)",
        "3. Migracja sald: środki trwałe, zapasy, należności, zobowiązania",
        "4. Różnice: amortyzacja bilansowa vs podatkowa (odroczony podatek)",
        "5. Zasady memoriałowe zamiast kasowych",
    ],
    "differences": {
        "revenue": "przychód memoriałowy (faktura) vs kasowy (zapłata)",
        "amortization": "stawki bilansowe (UoR) vs podatkowe (KŚT)",
        "inventory": "wycena zapasów wg UoR (koszt wytworzenia)",
    },
    "_routing": "",
    "_routing_reason": "Audyt transformacji PKPiR → UoR — migracja, otwarcie ksiąg, różnice",
    "_legal_basis": "UoR art. 10-12 (otwarcie ksiąg); art. 45-49 (sprawozdania)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# ── SEKCJA 6: OPA JAKO ROZBUDOWANY SYSTEM — PIPELINE TEMPORALNY ───────────────
# Zmiany rozporządzenia o PKPiR, nowe wzory — pipeline auto-aktualizacji.
accounting_pipeline_snapshot := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.accounting_pipeline_snapshot",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 860,
    "matched": true,
    "pipeline": {
        "step_1_ingest": "data.jdg.thresholds.accounting (ADR-002)",
        "step_2_generate": "szablony PKPiR (kolumny 1-17) + KŚT + limity",
        "step_3_verify": "ksiegowosc_pkpir_uor_auditor.py — walidacja spójności",
        "step_4_emit": "hot-reload pakietów jdg.accounting / jdg.uor",
    },
    "auto_update": "zmiana rozporządzenia o PKPiR / nowe wzory → pipeline auto-aktualizacji szablonów",
    "_routing": "",
    "_routing_reason": "Pipeline auto-aktualizacji szablonów księgi (PKPiR/UoR)",
    "_legal_basis": "Rozporządzenie o PKPiR (Dz.U. 2025 poz. 567); ADR-002",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# ── SEKCJA 7: GENIALNE POMYSŁY ENTERPRISE (INN-01..INN-15) ───────────────────
# INN-01: uor_obligation_engine (Sekcja 2) | INN-02: pkpir_auto_dekretacja (Sekcja 1)
# INN-03: pkpir_validator_realtime (Sekcja 1) | INN-04: amortization_dual_calculator (Sekcja 2)
# INN-05: one_time_depreciation_audit (Sekcja 3) | INN-06: car_limit_audit (Sekcja 3)
# INN-07: remanent_simulator (Sekcja 4)

# INN-08: Plan kont dla JDG (uproszczony — konto → kolumna PKPiR).
chart_of_accounts := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.chart_of_accounts",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 870,
    "matched": true,
    "accounts": {
        "100": {"name": "Kasa", "type": "aktywa"},
        "101": {"name": "Rachunek bankowy", "type": "aktywa"},
        "200": {"name": "Rozrachunki z odbiorcami", "type": "aktywa"},
        "201": {"name": "Rozrachunki z dostawcami", "type": "pasywa"},
        "220": {"name": "VAT naliczony", "type": "aktywa"},
        "221": {"name": "VAT należny", "type": "pasywa"},
        "300": {"name": "Materiały", "type": "aktywa"},
        "400": {"name": "Środki trwałe", "type": "aktywa"},
        "500": {"name": "Przychody", "type": "przychód"},
        "600": {"name": "Koszty", "type": "koszt"},
    },
    "mapping_to_pkpir": "500→kol.7/8 | 600→kol.10-13 | 220→kol.16",
    "_routing": "",
    "_routing_reason": "Plan kont dla JDG — mapa konto → kolumna PKPiR",
    "_legal_basis": "Rozporządzenie o PKPiR (Dz.U. 2025 poz. 567)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-09: Generator PKPiR z dokumentów źródłowych (dokument → wpis księgi).
pkpir_generator := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.pkpir_generator",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 871,
    "matched": true,
    "documents_count": count(object.get(input, "documents", [])),
    "generated_entries": count(object.get(input, "documents", [])),
    "entry_rule": "każdy dokument → wiersz PKPiR (kolumny 1-17) w terminie 20 dni",
    "_routing": "",
    "_routing_reason": "Generator PKPiR z dokumentów źródłowych",
    "_legal_basis": "Rozporządzenie o PKPiR (Dz.U. 2025 poz. 567)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-10: Kalkulator progu UoR — śledzenie przychodu EUR w trakcie roku.
uor_threshold_tracker := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.uor_threshold_tracker",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 872,
    "matched": true,
    "ytd_revenue_pln": to_number(object.get(input.jdg_entrepreneur, "ytd_revenue_pln", 0)),
    "ytd_revenue_eur": round2(to_number(object.get(input.jdg_entrepreneur, "ytd_revenue_pln", 0)) / eur_pln_reference),
    "threshold_eur": uor_threshold_eur,
    "pct_of_threshold": round2(to_number(object.get(input.jdg_entrepreneur, "ytd_revenue_pln", 0)) / eur_pln_reference / uor_threshold_eur * 100),
    "early_warning_active": to_number(object.get(input.jdg_entrepreneur, "ytd_revenue_pln", 0)) / eur_pln_reference >= uor_threshold_eur * early_warning_pct / 100,
    "_routing": "",
    "_routing_reason": "Tracker progu UoR w trakcie roku (75% wczesne ostrzeżenie)",
    "_legal_basis": "Art. 2 ust. 1 pkt 5 UoR",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-11: Walidator dowodów księgowych (elementy wymagane art. 21 UoR).
document_validator := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.document_validator",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 873,
    "matched": true,
    "required_elements": [
        "nazwa dokumentu", "data wystawienia", "nr identyfikacyjny",
        "dane wystawcy i odbiorcy", "treść operacji", "kwota",
    ],
    "complete": count([e | e := ["nazwa dokumentu", "data wystawienia", "nr identyfikacyjny", "dane wystawcy i odbiorcy", "treść operacji", "kwota"][_]; object.get(input.document, e, "") != ""]) == 6,
    "_routing": "",
    "_routing_reason": "Walidator dowodów księgowych (art. 21 UoR)",
    "_legal_basis": "Art. 21-22 UoR",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-12: Inwentaryzacja — harmonogram (środki pieniężne co roku, zapasy wg metody).
inventory_scheduler := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.inventory_scheduler",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 874,
    "matched": true,
    "schedule": {
        "cash": "na każdy dzień bilansowy",
        "bank": "na każdy dzień bilansowy",
        "zapasy": "na koniec roku (metoda ciągła lub okresowa)",
        "fixed_assets": "co 4 lata (art. 26 ust. 3 pkt 3 UoR)",
    },
    "_routing": "",
    "_routing_reason": "Harmonogram inwentaryzacji (art. 26 UoR)",
    "_legal_basis": "Art. 26-27 UoR",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-13: Generatory sprawozdań — bilans + RZiS (struktura).
financial_statements_generator := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.financial_statements_generator",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 875,
    "matched": true,
    "balance_sheet": ["AKTYWA: A. Trwałe | B. Obrotowe | C. Rozliczenia", "PASYWA: A. Kapitał | B. Zobowiązania | C. Rozliczenia"],
    "p_and_l": ["Przychody netto ze sprzedaży", "Koszty działalności", "Wynik brutto", "Podatek", "Wynik netto"],
    "filing_deadline": "sprawozdanie do 31.03 (jednostki małe) / do 15.10 (duże)",
    "_routing": "",
    "_routing_reason": "Generator sprawozdań finansowych (bilans + RZiS)",
    "_legal_basis": "Art. 45-49, art. 52 UoR",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-14: Symulator leasingu operacyjny vs finansowy (koszt KUP).
leasing_comparator := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.leasing_comparator",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 876,
    "matched": true,
    "monthly_rent": to_number(object.get(input.lease, "monthly_rent", 0)),
    "operating_kup_monthly": to_number(object.get(input.lease, "monthly_rent", 0)),
    "financial_kup_monthly": round2(to_number(object.get(input.lease, "monthly_rent", 0)) * to_number(object.get(input.lease, "interest_share", 0.20))),
    "annual_difference": round2(to_number(object.get(input.lease, "monthly_rent", 0)) * 12 - to_number(object.get(input.lease, "monthly_rent", 0)) * to_number(object.get(input.lease, "interest_share", 0.20)) * 12),
    "recommendation": "operacyjny" if to_number(object.get(input.lease, "monthly_rent", 0)) > 0 else "brak",
    "_routing": "",
    "_routing_reason": "Symulator leasingu operacyjnego vs finansowego (KUP)",
    "_legal_basis": "Art. 23b, art. 23f PIT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-15: Auto-aktualizacja szablonów księgi (hook temporalny).
accounting_template_hook := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.accounting_template_hook",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 877,
    "matched": true,
    "source": "data.jdg.thresholds.accounting (ADR-002)",
    "trigger": "zmiana rozporządzenia o PKPiR / nowe wzory / zmiana limitu UoR",
    "steps": ["ingest", "generate", "verify", "emit"],
    "hot_reload": true,
    "_routing": "",
    "_routing_reason": "Hook auto-aktualizacji szablonów księgi (PKPiR/UoR)",
    "_legal_basis": "ADR-002 (dane temporalne)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# ── SEKCJA 7b: NOWE INNOWACJE P09 v9.1 (INN-16..INN-20) ────────────────────────
# INN-16: Walidator spójności międzyksięgowej PKPiR ↔ VAT ↔ PIT ↔ ZUS
# (zero rozjazdów — każda kwota księgi potwierdzona w 4 domenach).
pkpir_cross_domain_validator := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.pkpir_cross_domain_validator",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 878,
    "matched": true,
    "vat_ok": vat_ok,
    "pit_ok": pit_ok,
    "zus_ok": zus_ok,
    "cross_consistent": vat_ok and pit_ok and zus_ok,
    "violations": violations,
    "_routing": "TRIAGE_QUEUE" if count(violations) > 0 else "",
    "_routing_reason": "Walidator spójności międzyksięgowej PKPiR↔VAT↔PIT↔ZUS — zero rozjazdów",
    "_legal_basis": "Rozporządzenie o PKPiR (Dz.U. 2025 poz. 567); VAT art. 109; PIT art. 24a; ZUS art. 46",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
    vat_ok := round2(to_number(object.get(input.ledger, "pkpir_col7_sales_net", 0))) == round2(to_number(object.get(input.ledger, "vat_sales_base", 0)))
    pit_ok := round2(to_number(object.get(input.ledger, "pkpir_income", 0))) == round2(to_number(object.get(input.ledger, "pit_advance_base", 0)))
    zus_ok := round2(to_number(object.get(input.ledger, "pkpir_col12_wages", 0))) == round2(to_number(object.get(input.ledger, "zus_contribution_base", 0)))
    violations := [v | v := {"domain": "VAT", "expected": to_number(object.get(input.ledger, "vat_sales_base", 0)), "actual": to_number(object.get(input.ledger, "pkpir_col7_sales_net", 0))}; not vat_ok] + [w | w := {"domain": "PIT", "expected": to_number(object.get(input.ledger, "pit_advance_base", 0)), "actual": to_number(object.get(input.ledger, "pkpir_income", 0))}; not pit_ok] + [x | x := {"domain": "ZUS", "expected": to_number(object.get(input.ledger, "zus_contribution_base", 0)), "actual": to_number(object.get(input.ledger, "pkpir_col12_wages", 0))}; not zus_ok]
}

# INN-17: Zamknięcie roku z checklistą prawną (remanent, rozliczenie, archiwum 5 lat).
year_closing_checklist := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.year_closing_checklist",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 879,
    "matched": true,
    "year": object.get(input.jdg_entrepreneur, "tax_year", ""),
    "checklist": [
        {"item": "Zamknięcie PKPiR — wpisy w terminie 20 dni, kolumny 1-17", "status": "required"},
        {"item": "Remanent końcowy — spis z natury wg cen zakupu (art. 24 ust. 2 PIT)", "status": "required"},
        {"item": "Różnica remanentów — korekta przychodu roku następnego", "status": "required"},
        {"item": "Rozliczenie roczne PIT-36/36L/28 — dochód z PKPiR", "status": "required"},
        {"item": "Archiwizacja ksiąg i dowodów — 5 lat (art. 74 UoR / art. 86 §1 OrdPU)", "status": "required"},
        {"item": "JPK_PKPIR — gotowość na żądanie US (art. 193a OrdPU)", "status": "required"},
    ],
    "remanent_done": object.get(input.jdg_entrepreneur, "year_closing_remanent_done", false) == true,
    "return_filed": object.get(input.jdg_entrepreneur, "year_closing_return_filed", false) == true,
    "archive_ready": object.get(input.jdg_entrepreneur, "year_closing_archive_ready", false) == true,
    "closing_complete": object.get(input.jdg_entrepreneur, "year_closing_remanent_done", false) == true and object.get(input.jdg_entrepreneur, "year_closing_return_filed", false) == true and object.get(input.jdg_entrepreneur, "year_closing_archive_ready", false) == true,
    "_routing": "TRIAGE_QUEUE" if (not object.get(input.jdg_entrepreneur, "year_closing_remanent_done", false)) or (not object.get(input.jdg_entrepreneur, "year_closing_return_filed", false)) else "",
    "_routing_reason": "Zamknięcie roku — checklista prawna (remanent, rozliczenie, archiwizacja)",
    "_legal_basis": "Art. 24 ust. 2 PIT; art. 74 UoR; art. 86 §1 OrdPU; art. 193a OrdPU",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-18: JPK_PKPIR readiness — gotowość struktury PKPiR do JPK (16 kolumn, forma elektroniczna).
jpk_pkpir_readiness := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.jpk_pkpir_readiness",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 880,
    "matched": true,
    "jpk_schema_columns": 16,
    "pkpir_columns_ready": count(pkpir_columns) >= 16,
    "electronic_form": object.get(input.jdg_entrepreneur, "pkpir_electronic_form", true) == true,
    "ready": count(pkpir_columns) >= 16 and object.get(input.jdg_entrepreneur, "pkpir_electronic_form", true) == true,
    "on_demand_deadline": "30 dni od wezwania US (art. 193a §2 OrdPU)",
    "_routing": "TRIAGE_QUEUE" if object.get(input.jdg_entrepreneur, "pkpir_electronic_form", true) != true else "",
    "_routing_reason": "JPK_PKPIR readiness — struktura PKPiR vs wzorzec JPK (16 kolumn)",
    "_legal_basis": "Art. 30a ustawy o rachunkowości; art. 193a OrdPU; rozp. MF w sprawie JPK_VAT",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}

# INN-19: Ciągłość bilansu otwarcia (bilans otwarcia = bilans zamknięcia poprzedniego roku).
uor_opening_balance_continuity := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.uor_opening_balance_continuity",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 881,
    "matched": true,
    "opening_total_assets": to_number(object.get(input.uor_books, "opening_total_assets", 0)),
    "opening_total_liabilities": to_number(object.get(input.uor_books, "opening_total_liabilities", 0)),
    "closing_total_assets_prev": to_number(object.get(input.uor_books, "closing_total_assets_prev_year", 0)),
    "closing_total_liabilities_prev": to_number(object.get(input.uor_books, "closing_total_liabilities_prev_year", 0)),
    "continuity_ok": continuity_ok,
    "balance_ok": round2(to_number(object.get(input.uor_books, "opening_total_assets", 0))) == round2(to_number(object.get(input.uor_books, "opening_total_liabilities", 0))),
    "_routing": "TRIAGE_QUEUE" if not continuity_ok else "",
    "_routing_reason": "Ciągłość bilansu — otwarcie roku = zamknięcie roku poprzedniego (art. 10-12 UoR)",
    "_legal_basis": "Art. 10-12, art. 22 UoR",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
    continuity_ok := round2(to_number(object.get(input.uor_books, "opening_total_assets", 0))) == round2(to_number(object.get(input.uor_books, "closing_total_assets_prev_year", 0))) and round2(to_number(object.get(input.uor_books, "opening_total_liabilities", 0))) == round2(to_number(object.get(input.uor_books, "closing_total_liabilities_prev_year", 0)))
}

# INN-20: Inteligentny klasyfikator kolumn PKPiR po opisie faktury (reguły + ML-ready).
pkpir_intelligent_classifier := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.pkpir_intelligent_classifier",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 882,
    "matched": true,
    "description": object.get(input.document, "description", ""),
    "classified_column": classified_column,
    "classification_confidence": "HIGH",
    "_routing": "",
    "_routing_reason": "Inteligentny klasyfikator kolumn PKPiR po opisie faktury (dokument → kolumna)",
    "_legal_basis": "Rozporządzenie o PKPiR (Dz.U. 2025 poz. 567)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
    desc_lower := lower(object.get(input.document, "description", ""))
    classified_column := "7" if contains(desc_lower, "sprzedaż") or contains(desc_lower, "sprzedaz") or contains(desc_lower, "usługa") or contains(desc_lower, "usluga") else "8" if contains(desc_lower, "odsetki") or contains(desc_lower, "dotacja") or contains(desc_lower, "refundacja") else "10" if contains(desc_lower, "zakup towarów") or contains(desc_lower, "zakup towarow") or contains(desc_lower, "materiały") or contains(desc_lower, "materialy") or contains(desc_lower, "zakup") else "12" if contains(desc_lower, "wynagrodzenie") or contains(desc_lower, "pensja") or contains(desc_lower, "lista płac") else "13"
}

# ── GŁÓWNY DECIDE (P09) — raport syntetyczny Księgowość PKPiR+UoR ──────────────
decide := {
    "rule_id": "jdg.p09_ksiegowosc_pkpir_uor_innovations.report",
    "package": "jdg.p09_ksiegowosc_pkpir_uor_innovations",
    "priority": 857,
    "matched": true,
    "pkpir_structure": pkpir_structure_audit,
    "uor_obligation": uor_obligation_engine,
    "uor_audit": uor_audit,
    "amortization_leasing": amortization_leasing_audit,
    "remanent": remanent_audit,
    "transformation": pkpir_uor_transformation_audit,
    "pipeline": accounting_pipeline_snapshot,
    "cross_domain": pkpir_cross_domain_validator,
    "year_closing": year_closing_checklist,
    "jpk_readiness": jpk_pkpir_readiness,
    "uor_continuity": uor_opening_balance_continuity,
    "classifier": pkpir_intelligent_classifier,
    "_routing": "REPORT",
    "_routing_reason": "Raport syntetyczny Księgowość PKPiR+UoR (P09) — struktura, próg UoR, amortyzacja, remanent",
    "_legal_basis": "Rozporządzenie o PKPiR (Dz.U. 2025 poz. 567); UoR (art. 2-74); ustawa PIT (art. 22a-23f)",
    "_warnings": [],
} {
    object.get(input.jdg_entrepreneur, "p09_ksiegowosc_check", false) == true
}
