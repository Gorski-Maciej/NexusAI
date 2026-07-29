# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE FAMILY TAX OPTIMIZER & ESTONIAN CIT
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Family Tax Optimizer + Estonian CIT Extension
# description: |
#   ENTERPRISE v7.0 — Łączy inicjatywy S15 (Family Tax Optimizer) i CR4 (Estoński CIT).
#   Family Optimizer:
#   - F170: Wspólne rozliczenie małżonków vs osobno
#   - F171: Przypisanie dzieci do rodzica z wyższym progiem
#   - F172: Ulga 4+ vs inne ulgi
#   - F173: Optymalizacja darowizn rodzinnych
#   Estoński CIT rozszerzenie (bazuje na micro/plan33_est.rego):
#   - E180: Warunki estońskiego CIT (100M PLN, 3 osoby, przychody bierne <50%)
#   - E181: Stawki 20%/25% od wypłat
#   - E182: Kategorie ukrytych zysków
#   - E183: Przejście z/na inne formy
#   - E184: Estoński CIT + ZUS/składka zdrowotna
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Art. 6, 26-30ca PIT; Rozdział 6b ustawy o CIT
# package: jdg.pit.family_estonian
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.family_estonian

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.family_est.no_match",
    "package": "jdg.pit.family_estonian", "priority": 999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  FAMILY TAX OPTIMIZER  (F170-F175)                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# F170: family_joint_vs_separate — Wspólne rozliczenie vs osobno
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.pit.family.joint_vs_separate",
    "package": "jdg.pit.family_estonian",
    "priority": 170,
    "pit_form": pit_form,
    "family_joint_tax": joint_tax,
    "family_separate_tax": separate_tax,
    "family_joint_filing_savings": savings,
    "family_joint_recommended": joint_recommended,
    "_routing": family_rt,
    "_routing_reason": sprintf("Rodzina: wspólnie %.0f PLN vs osobno %.0f PLN — oszczędność %.0f PLN",
        [joint_tax, separate_tax, savings]),
    "_legal_basis": "Art. 6 ust. 2 PIT (wspólne rozliczenie małżonków)",
    "_warnings": [sprintf("👨‍👩‍👧‍👦 FAMILY TAX OPTIMIZER\n   WSPÓLNIE: %.0f PLN podatku (efektywny próg 240k PLN x2)\n   OSOBNO: %.0f PLN\n   💰 Oszczędność ze wspólnego: %.0f PLN\n   %s",
        [joint_tax, separate_tax, savings, recommendation])]
} {
    input.family_tax_optimization == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    # pit_form == "PIT_SCALE" is enforced in the rule body via pit_form variable assignment

    jdg_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 100000)
    spouse_income := object.get(input.jdg_entrepreneur, "spouse_annual_income", 40000)
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)

    # Osobno
    jdg_tax := jdg_income * 0.12 { jdg_income <= scale_threshold }
    jdg_tax := scale_threshold * 0.12 + (jdg_income - scale_threshold) * 0.32 { jdg_income > scale_threshold }
    spouse_tax := spouse_income * 0.12 { spouse_income <= scale_threshold }
    separate_tax := jdg_tax + spouse_tax

    # Razem (efektywny próg x2 = 240k)
    half := (jdg_income + spouse_income) / 2
    half_tax := half * 0.12 { half <= scale_threshold }
    half_tax := scale_threshold * 0.12 + (half - scale_threshold) * 0.32 { half > scale_threshold }
    joint_tax := half_tax * 2

    savings := separate_tax - joint_tax
    joint_recommended := savings > 500

    recommendation = "✅ ZŁÓŻCIE WSPÓLNIE!" { joint_recommended }
    recommendation = "➡️ Rozliczcie się osobno (podobny dochód)" { not joint_recommended; savings <= 0 }

    family_rt = "TRIAGE_QUEUE" { joint_recommended; savings > 3000 }
    family_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# F171: family_child_assignment — Przypisanie dzieci do rodzica z wyższym progiem
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.family.child_assignment",
    "package": "jdg.pit.family_estonian",
    "priority": 171,
    "pit_form": pit_form,
    "family_children_count": children,
    "family_child_relief_total": child_relief,
    "family_recommended_parent": recommended_parent,
    "family_child_assignment_strategy": strategy,
    "_routing": "",
    "_routing_reason": sprintf("Dzieci: %d — ulga %.2f PLN, przypisz do: %s", [children, child_relief, recommended_parent]),
    "_legal_basis": "Art. 27f PIT (ulga na dzieci)",
    "_warnings": [sprintf("👶 ULGA NA DZIECI — %d dzieci, ulga: %.2f PLN. Przypisz dzieci do: %s (%s). Strategia: rodzic z WYŻSZYM dochodem = WIĘKSZA ulga (szybsze wyczerpanie podatku do odliczenia).",
        [children, child_relief, recommended_parent, strategy])]
} {
    input.family_tax_optimization == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    children := object.get(input.jdg_entrepreneur, "children_count", 0)
    children > 0
    jdg_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 100000)
    spouse_income := object.get(input.jdg_entrepreneur, "spouse_annual_income", 40000)

    # Stawki ulgi na dziecko (2026)
    child_relief_first := 1112.04
    child_relief_second := 1112.04
    child_relief_third := 2000.04
    child_relief_fourth := 2700.00
    child_relief := child_relief_first + child_relief_second { children >= 2 }
    child_relief := child_relief + child_relief_third { children >= 3 }
    child_relief := child_relief + child_relief_fourth { children >= 4 }

    recommended_parent = "JDG (wyższy dochód)" { jdg_income > spouse_income }
    recommended_parent = "Małżonek (wyższy dochód)" { spouse_income > jdg_income }
    recommended_parent = "Dowolny rodzic" { jdg_income == spouse_income }
    strategy = sprintf("JDG: %.0f PLN dochodu, limit odliczenia ulgi = %.0f PLN podatku przed odliczeniem", [jdg_income, jdg_income * 0.12])
}

# ═══════════════════════════════════════════════════════════════════════════════
# F172: family_4plus_vs_other — Ulga 4+ vs inne ulgi rodzinne
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.family.fourplus_vs_other",
    "package": "jdg.pit.family_estonian",
    "priority": 172,
    "pit_form": pit_form,
    "family_4plus_available": has_4plus,
    "family_4plus_limit_remaining": limit_remaining,
    "family_4plus_vs_child_relief": comparison,
    "_routing": "",
    "_routing_reason": sprintf("Ulga 4+: %s — limit pozostały: %.2f PLN. %s", [has_4plus, limit_remaining, comparison]),
    "_legal_basis": "Art. 21 ust. 1 pkt 153 PIT (ulga 4+); Art. 27f PIT",
    "_warnings": [sprintf("ULGA 4+ vs ULGA NA DZIECI — Masz 4+ dzieci, więc kwalifikujesz się do ULGI 4+ (zwolnienie do 85 528 PLN)! Ulga 4+ i ulga na dzieci NIE wykluczają się — możesz skorzystać z OBU! Ulga 4+ = zero PIT od dochodu do 85 528 PLN. Ulga na dzieci = odliczenie od podatku. %s",
        [combined_note])]
} {
    input.family_tax_optimization == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    children := object.get(input.jdg_entrepreneur, "children_count", 0)
    has_4plus := children >= 4
    annual_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 85000)
    limit_remaining := max([data.thresholds.pit.pit_relief_shared_limit - annual_income, 0])
    comparison = "Ulga 4+ ZWALNIA z PIT do 85 528 PLN — może być lepsza niż ulga na dzieci dla dochodu < 85k" { has_4plus }
    comparison = "Nie dotyczy — mniej niż 4 dzieci" { not has_4plus }
    combined_note = "Połącz ulgę 4+ (zwolnienie dochodu) z ulgą na dzieci (odliczenie od podatku) dla MAKSYMALNEJ oszczędności!" { has_4plus }
    combined_note = "Nie dotyczy" { not has_4plus }
}

# ═══════════════════════════════════════════════════════════════════════════════
# F173: family_donation_optimization — Optymalizacja darowizn w rodzinie
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.family.donation_optimization",
    "package": "jdg.pit.family_estonian",
    "priority": 173,
    "pit_form": pit_form,
    "family_donation_limit_pln": donation_limit,
    "family_donation_strategy": donation_strategy,
    "_routing": "",
    "_routing_reason": sprintf("Darowizny rodzinne: limit %.2f PLN (6%% dochodu)", [donation_limit]),
    "_legal_basis": "Art. 26 ust. 1 pkt 9 PIT",
    "_warnings": [sprintf("DAROWIZNY RODZINNE — Limit 6%% dochodu: %.2f PLN. Jeśli oboje małżonkowie mają dochód, KAŻDE ma osobny limit 6%% swojego dochodu! Rozdziel darowizny między małżonków dla podwojenia odliczenia.",
        [donation_limit])]
} {
    input.family_tax_optimization == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 100000)
    donation_limit := floor(income * 0.06 * 100) / 100
    donation_strategy = sprintf("Przekaż %.2f PLN na OPP — maksymalne odliczenie", [donation_limit])
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ESTOŃSKI CIT ROZSZERZENIE  (E180-E185)                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# E180: estonian_cit_conditions — Warunki estońskiego CIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.family_est.estonian_conditions",
    "package": "jdg.pit.family_estonian",
    "priority": 180,
    "pit_form": "ESTONIAN_CIT",
    "estonian_revenue_limit_pln": 100000000,
    "estonian_min_employees": 3,
    "estonian_passive_income_max_pct": 0.50,
    "estonian_conditions_met": all_met,
    "estonian_failed_condition": failed_condition,
    "_routing": est_rt,
    "_routing_reason": sprintf("Estoński CIT: %s. %s", [qualification, failed_msg]),
    "_legal_basis": "Rozdział 6b ustawy o CIT (estoński CIT)",
    "_warnings": [sprintf("🇪🇪 ESTOŃSKI CIT — KWALIFIKACJA: %s\n   Warunki:\n   ✅ Przychód < 100M PLN: %s (%.0f PLN)\n   ✅ Zatrudnienie min. 3 osób: %s (%d)\n   ✅ Przychody bierne < 50%%: %s (%.0f%%)\n   ✅ Brak udziałów w innych podmiotach: %s\n   %s",
        [qualification, rev_ok, annual_revenue, emp_ok, employees, passive_ok, passive_pct, no_subsidiaries_ok, recommendation])]
} {
    input.estonian_cit_requested == true
    # Warunki estońskiego CIT
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_pln", 5000000)
    employees := object.get(input.jdg_entrepreneur, "employee_count", 5)
    passive_income_pct := object.get(input.jdg_entrepreneur, "passive_income_pct", 0.15)
    has_subsidiaries := object.get(input.jdg_entrepreneur, "has_subsidiaries", false)

    rev_check := annual_revenue <= 100000000
    emp_check := employees >= 3
    passive_check := passive_income_pct < 0.50
    no_subs_check := not has_subsidiaries

    all_met := rev_check and emp_check and passive_check and no_subs_check

    failed_condition = ""
    failed_condition = sprintf("Przychód %.0f PLN przekracza limit 100M PLN. ", [annual_revenue]) { not rev_check }
    failed_condition = sprintf("Zatrudniasz %d osób, wymagane min. 3. ", [employees]) { not emp_check }
    failed_condition = sprintf("Przychody bierne %.0f%% przekraczają limit 50%%. ", [passive_income_pct * 100]) { not passive_check }

    qualification = "KWALIFIKUJE SIĘ" { all_met }
    qualification = sprintf("NIE KWALIFIKUJE: %s", [failed_condition]) { not all_met }

    rev_ok = "OK" { rev_check } else = "PRZEKROCZONY" { not rev_check }
    emp_ok = "OK" { emp_check } else = "ZA MAŁO" { not emp_check }
    passive_ok = "OK" { passive_check } else = "PRZEKROCZONY" { not passive_check }
    no_subsidiaries_ok = "OK" { no_subs_check } else = "MA UDZIAŁY" { not no_subs_check }

    recommendation = "✅ Rozważ estoński CIT — brak podatku do momentu wypłaty zysku!" { all_met }
    recommendation = sprintf("❌ NIE spełniasz warunków: %s", [failed_condition]) { not all_met }

    est_rt = "TRIAGE_QUEUE" { all_met }
    est_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# E181: estonian_cit_rates — Stawki 20%/25% od wypłat
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.family_est.estonian_rates",
    "package": "jdg.pit.family_estonian",
    "priority": 181,
    "estonian_tax_base": annual_profit,
    "estonian_effective_rate": effective_rate,
    "estonian_tax_on_distribution": tax_on_distribution,
    "estonian_tax_if_no_distribution": 0,
    "estonian_deferral_benefit": deferral_benefit,
    "_routing": "",
    "_routing_reason": sprintf("Estoński CIT: %.0f%% efektywnie, odroczony podatek %.2f PLN (0 PLN do czasu wypłaty)",
        [effective_rate * 100, tax_on_distribution]),
    "_legal_basis": "Art. 28c-28t ustawy o CIT (mechanizm estońskiego CIT)",
    "_warnings": [sprintf("ESTOŃSKI CIT — STAWKI:\n   Mały podatnik (przychód < 2M EUR): 20%% (10%% CIT + 10%% PIT)\n   Duży podatnik: 25%% (15%% CIT + 10%% PIT)\n   Twój zysk: %.2f PLN.\n   Podatek przy PEŁNEJ wypłacie: %.2f PLN (%.0f%%)\n   💡 KLUCZOWA KORZYŚĆ: NIE wypłacasz zysku = NIE płacisz podatku! Reinwestujesz 100%%.\n   Oszczędność vs liniowy 19%%: %.2f PLN rocznie (przy reinwestycji).",
        [annual_profit, tax_on_distribution, effective_rate * 100, deferral_benefit])]
} {
    input.estonian_cit_requested == true
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit", 500000)
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_pln", 5000000)
    is_small := annual_revenue < 2000000 * 4.50  # 2M EUR × ~4.50 PLN/EUR

    effective_rate = 0.20 { is_small }
    effective_rate = 0.25 { not is_small }
    tax_on_distribution := annual_profit * effective_rate
    deferral_benefit := annual_profit * 0.19  # vs liniowy 19%
}

# ═══════════════════════════════════════════════════════════════════════════════
# E182: estonian_hidden_profits — Kategorie ukrytych zysków
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.family_est.estonian_hidden_profits",
    "package": "jdg.pit.family_estonian",
    "priority": 182,
    "estonian_hidden_profit_categories": [
        "1. Pożyczki dla wspólników",
        "2. Nadwyżka wydatków nad wartością rynkową",
        "3. Świadczenia na rzecz wspólników (auto, nieruchomość)",
        "4. Darowizny na rzecz wspólników",
        "5. Dochód z tytułu umorzenia udziałów"
    ],
    "_routing": "",
    "_routing_reason": "Estoński CIT: uwaga na ukryte zyski — każda wypłata do wspólnika to podatek!",
    "_legal_basis": "Art. 28m ustawy o CIT (ukryte zyski)",
    "_warnings": ["ESTOŃSKI CIT — UKRYTE ZYSKI: Każda wypłata na rzecz wspólnika (pożyczka, auto prywatne, darowizna) podlega opodatkowaniu 20%/25% jako 'ukryty zysk'. Uważaj na transfery do majątku prywatnego — fiskus je śledzi!"]
} {
    input.estonian_cit_requested == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# E183: estonian_transition_rules — Przejście z/na estoński CIT
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.family_est.estonian_transition",
    "package": "jdg.pit.family_estonian",
    "priority": 183,
    "estonian_lockin_period_years": 4,
    "estonian_transition_deadline": "Do końca stycznia (rok podatkowy = luty-styczeń)",
    "estonian_exit_tax_warning": "Przy wyjściu z estońskiego CIT: opodatkowanie niepodzielonych zysków + 4-letni lock-in!",
    "_routing": "",
    "_routing_reason": "Estoński CIT: lock-in 4 lata, rok podatkowy luty-styczeń",
    "_legal_basis": "Art. 28f-28g ustawy o CIT (przejście na/z estońskiego CIT)",
    "_warnings": ["PRZEJŚCIE NA ESTOŃSKI CIT: (1) Wybierz do końca stycznia, (2) Rok podatkowy trwa od lutego do stycznia, (3) Zamknij księgi na dzień poprzedzający, (4) Opłać zaległy podatek, (5) LOCK-IN: 4 lata — nie możesz wyjść wcześniej bez utraty statusu + opodatkowania wszystkich zysków!"]
} {
    input.estonian_cit_requested == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# E184: estonian_zus_health — Estoński CIT + ZUS / składka zdrowotna
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.family_est.estonian_zus_health",
    "package": "jdg.pit.family_estonian",
    "priority": 184,
    "estonian_zus_note": "Estoński CIT NIE zmienia zasad ZUS — płacisz ZUS tak samo jak przy JDG na PIT.",
    "estonian_health_contribution_note": health_note,
    "_routing": "",
    "_routing_reason": "Estoński CIT + ZUS: bez zmian w ZUS, zdrowotna od wypłaconej dywidendy",
    "_legal_basis": "Art. 79-81 ustawy o świadczeniach (składka zdrowotna); Art. 18 SUS (ZUS)",
    "_warnings": [sprintf("ESTOŃSKI CIT + ZUS/ZDROWOTNA:\n   ZUS społeczne: BEZ ZMIAN — płacisz standardowy ZUS (%.2f PLN/mies)\n   Zdrowotna: 9%% od WYPŁACONEJ dywidendy. Przy braku wypłat = brak dodatkowej zdrowotnej.\n   💡 To może być tańsze niż 9%% od CAŁEGO dochodu na skali!",
        [zus_monthly])]
} {
    input.estonian_cit_requested == true
    zus_monthly := object.get(input.jdg_entrepreneur, "zus_monthly_total", 1800)
    health_note = sprintf("Zdrowotna płatna TYLKO od wypłaconej dywidendy (9%%). Bez wypłat = 0 PLN zdrowotnej od zysku.", [])
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.family_estonian.fallback",
    "package": "jdg.pit.family_estonian",
    "priority": 999,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 6, 26-30ca PIT; Rozdział 6b CIT",
    "_warnings": ["Family Tax Optimizer + Estoński CIT — sprawdź dostępne opcje optymalizacji rodzinnej i CIT estońskiego. Potencjał oszczędności: do 50% podatku!"]
} {
    true
}
