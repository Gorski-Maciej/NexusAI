# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P16 ESTONIAN CIT FULL IMPLEMENTATION (Strategic Initiative E1)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Estonian CIT Full Implementation — Art. 28c-28t CIT Complete
# description: |
#   ENTERPRISE v8.0 — Pelna implementacja Estonskiego CIT.
#   Wypelnia luke z RAPORT_P16: pelne warunki, progi, ograniczenia, symulacja.
#   - Warunki: minimum 3 lata dzialalnosci, zatrudnienie min. 3 osob, limit 50M EUR
#   - Stawki: 20% (standard) / 25% (duzy podatnik >50M EUR)
#   - Dystrybucja zysku: podatek przy wyplacie, 0% przy reinwestycji
#   - Obowiazki: KRS, pelna księgowosc, sprawozdanie finansowe, audyt
#   - Symulacja JDG vs Estonski CIT vs CIT klasyczny
# architecture: Enterprise Estonian CIT Engine
# legal_basis: Art. 28c-28t CIT; Ustawa o podatku dochodowym od osob prawnych
# package: jdg.estonian_cit
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.estonian_cit

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false, "rule_id": "jdg.estonian_cit.no_match",
    "package": "jdg.estonian_cit", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# ECIT-100: ESTONIAN CIT ELIGIBILITY CHECK — Warunki kwalifikacji
# ═══════════════════════════════════════════════════════════════════════════════

decide := verdict {
    object.get(input.jdg_entrepreneur, "estonian_cit_check", false) == true

    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 500000)
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    employee_count := object.get(input.jdg_entrepreneur, "employee_count", 0)
    business_years_active := object.get(input.jdg_entrepreneur, "months_active", 36) / 12
    legal_form := object.get(input.jdg_entrepreneur, "legal_form", "JDG")
    is_spzoo := legal_form in {"SP_ZOO", "SA", "SP_KOMANDYTOWA"}
    has_krs := object.get(input.jdg_entrepreneur, "has_krs_entry", false)
    has_full_accounting := object.get(input.jdg_entrepreneur, "has_full_accounting", false)
    has_financial_statements := object.get(input.jdg_entrepreneur, "has_financial_statements", false)
    share_structure_simple := object.get(input.jdg_entrepreneur, "has_simple_share_structure", true)
    income_passive_pct := object.get(input.jdg_entrepreneur, "passive_income_pct", 5)

    # Warunki podstawowe (Art. 28j CIT)
    min_employees_met := employee_count >= 3 { is_spzoo }
    min_employees_met := false { not is_spzoo }
    revenue_limit_met := annual_revenue <= 50000000  # 50M EUR limit uproszczony
    passive_income_ok := income_passive_pct < 50
    legal_form_ok := is_spzoo
    accounting_ok := has_full_accounting and has_financial_statements

    eligible := legal_form_ok and revenue_limit_met and passive_income_ok and accounting_ok and min_employees_met
    eligible_without_employees := legal_form_ok and revenue_limit_met and passive_income_ok and accounting_ok and not min_employees_met

    # Ograniczenia
    restrictions := []
    restrictions := array.concat(restrictions, ["Wymagana forma: Sp. z o.o., S.A. lub Sp. komandytowa — JDG nie kwalifikuje się!"]) { not legal_form_ok }
    restrictions := array.concat(restrictions, [sprintf("Min. 3 pracowników — masz tylko %d", [employee_count])]) { not min_employees_met; is_spzoo }
    restrictions := array.concat(restrictions, ["Wymagana pełna księgowość + sprawozdania finansowe"]) { not accounting_ok }
    restrictions := array.concat(restrictions, [sprintf("Przychody pasywne %.0f%% — limit 50%%", [income_passive_pct])]) { not passive_income_ok }

    routing := "BLOCK_AND_ALERT" { not legal_form_ok }
    routing := "TRIAGE_QUEUE" { eligible }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.estonian_cit.eligibility",
        "package": "jdg.estonian_cit",
        "priority": 100,
        "action": "CHECK_ESTONIAN_CIT_ELIGIBILITY",
        "estonian_cit_eligible": eligible,
        "estonian_cit_restrictions": restrictions,
        "estonian_cit_legal_form": legal_form,
        "estonian_cit_min_employees": 3,
        "estonian_cit_revenue_limit_eur": 50000000,
        "legal_basis": "Art. 28j-28k CIT",
        "_routing": routing,
        "_routing_reason": sprintf("Estonski CIT: %s — %s", [eligible && "KWALIFIKUJE SIE" || "NIE KWALIFIKUJE SIE",
            eligible && concat("; ", restrictions) || concat("; ", restrictions)]),
        "_warnings": [sprintf("🏢 ECIT-100 ESTONIAN CIT ELIGIBILITY:\n   Forma: %s | Pracownicy: %d/3 | Przychod: %.0f PLN\n   %s\n   ⚠️ JDG NIE kwalifikuje się do Estonskiego CIT — wymagana Sp. z o.o.! Rozwaz przeksztalcenie.",
            [legal_form, employee_count, annual_revenue, eligible && "✅ SPEŁNIA WARUNKI" || sprintf("❌ NIE SPEŁNIA: %s", [concat("; ", restrictions)])])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ECIT-200: ESTONIAN CIT TAX CALCULATOR — Kalkulacja podatku
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "estonian_cit_calculate", false) == true

    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_actual", 500000)
    profit_distributed := object.get(input.jdg_entrepreneur, "profit_distributed_pln", 0)
    profit_reinvested := object.get(input.jdg_entrepreneur, "profit_reinvested_pln", max([annual_profit - profit_distributed, 0]))
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 2000000)
    is_small_taxpayer := annual_revenue <= 2000000  # 2M EUR

    # Stawki podatku Estonskiego CIT
    estonian_rate_small := 0.20
    estonian_rate_large := 0.25
    estonian_rate_effective := estonian_rate_small { is_small_taxpayer }
    estonian_rate_effective := estonian_rate_large { not is_small_taxpayer }

    # Podatek tylko od WYPLACONEGO zysku
    estonian_tax_distributed := profit_distributed * estonian_rate_effective
    estonian_tax_reinvested := 0  # 0% przy reinwestycji

    # CIT klasyczny dla porownania
    cit_classic_rate_small := 0.09
    cit_classic_rate_standard := 0.19
    cit_classic_effective := cit_classic_rate_small { is_small_taxpayer }
    cit_classic_effective := cit_classic_rate_standard { not is_small_taxpayer }
    cit_classic_total := annual_profit * cit_classic_effective

    # Oszczednosc Estonski CIT vs CIT klasyczny (przy pelnej reinwestycji)
    savings_vs_classic := cit_classic_total - estonian_tax_distributed

    estonian_note := "0% podatku przy reinwestycji — podatek tylko od wyplaconych dywidend" { profit_distributed == 0 }
    estonian_note := sprintf("Podatek %.0f%% od %.0f PLN wyplaconego zysku = %.2f PLN", [estonian_rate_effective * 100, profit_distributed, estonian_tax_distributed]) { profit_distributed > 0 }

    routing := "TRIAGE_QUEUE" { savings_vs_classic > 50000 }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.estonian_cit.tax_calculator",
        "package": "jdg.estonian_cit",
        "priority": 200,
        "action": "CALCULATE_ESTONIAN_CIT",
        "estonian_cit_annual_profit": annual_profit,
        "estonian_cit_profit_distributed": profit_distributed,
        "estonian_cit_profit_reinvested": profit_reinvested,
        "estonian_cit_tax_rate_pct": estonian_rate_effective * 100,
        "estonian_cit_tax_distributed_pln": estonian_tax_distributed,
        "estonian_cit_tax_reinvested_pln": 0,
        "estonian_cit_savings_vs_classic_pln": savings_vs_classic,
        "estonian_cit_classic_total_pln": cit_classic_total,
        "estonian_cit_is_small_taxpayer": is_small_taxpayer,
        "estonian_cit_note": estonian_note,
        "legal_basis": "Art. 28c-28t CIT",
        "_routing": routing,
        "_routing_reason": sprintf("Estonski CIT: podatek %.2f PLN (%.0f%%) — oszczednosc vs CIT klasyczny: %.2f PLN",
            [estonian_tax_distributed, estonian_rate_effective * 100, savings_vs_classic]),
        "_warnings": [sprintf("💰 ECIT-200 ESTONIAN CIT CALCULATOR:\n   Zysk: %.0f PLN | Wyplacony: %.0f PLN (podatek: %.2f PLN = %.0f%%) | Reinwestowany: %.0f PLN (podatek: 0 PLN)\n   CIT klasyczny: %.2f PLN (%.0f%%) | Oszczednosc: %.2f PLN/rok\n   💡 %s",
            [annual_profit, profit_distributed, estonian_tax_distributed, estonian_rate_effective * 100, profit_reinvested, cit_classic_total, cit_classic_effective * 100, savings_vs_classic, estonian_note])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ECIT-300: JDG → SP. Z O.O. TRANSITION SIMULATOR (Estonski CIT sciezka)
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    object.get(input.jdg_entrepreneur, "estonian_cit_simulate_transition", false) == true

    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_actual", 200000)
    current_tax_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    employee_count := object.get(input.jdg_entrepreneur, "employee_count", 0)

    # Obecny koszt JDG
    jdg_pit := annual_profit * 0.12 { current_tax_form == "PIT_SCALE"; annual_profit <= 120000 }
    jdg_pit := 120000 * 0.12 + (annual_profit - 120000) * 0.32 { current_tax_form == "PIT_SCALE"; annual_profit > 120000 }
    jdg_pit := annual_profit * 0.19 { current_tax_form == "LINEAR" }
    jdg_health := annual_profit * 0.09
    jdg_zus := 21600
    jdg_total := jdg_pit + jdg_health + jdg_zus

    # Estonski CIT koszt (Sp. z o.o.)
    ecit_tax := 0  # Pelna reinwestycja
    ecit_admin := 21000  # Księgowosc + KRS + audyt
    ecit_zus_owner := 12000  # ZUS wlasciciela (minimalne wynagrodzenie)
    ecit_total := ecit_tax + ecit_admin + ecit_zus_owner

    savings := jdg_total - ecit_total
    savings_pct := floor(savings / jdg_total * 10000) / 100 { jdg_total > 0 }
    savings_pct := 0 { jdg_total == 0 }
    break_even_profit := 80000  # Punkt break-even dla transformacji
    recommended := annual_profit > break_even_profit and employee_count >= 1

    # Steps to transition
    transition_steps := [
        "1. Zaloz Sp. z o.o. — kapital zakladowy min. 5000 PLN",
        "2. Zarejestruj KRS — termin ~2-4 tygodnie + 600 PLN oplaty",
        "3. Aport przedsiebiorstwa JDG → Sp. z o.o. (0% PIT przy aporcie)",
        "4. Przejdz na pelna księgowosc (UoR)",
        "5. Wybierz Estonski CIT — zgloszenie ZAW-CIT-RD do US",
        "6. Zadbaj o min. 3 pracownikow w ciagu roku",
        "7. Zamknij JDG (CEIDG-1 wykreślenie)"
    ]

    routing := "TRIAGE_QUEUE" { recommended; savings > 50000 }
    routing := "" { true }

    verdict := {
        "matched": true,
        "rule_id": "jdg.estonian_cit.jdg_to_spzoo_simulator",
        "package": "jdg.estonian_cit",
        "priority": 300,
        "action": "SIMULATE_JDG_TO_ECIT",
        "estonian_cit_jdg_current_cost_pln": jdg_total,
        "estonian_cit_spzoo_ecit_cost_pln": ecit_total,
        "estonian_cit_annual_savings_pln": savings,
        "estonian_cit_break_even_profit_pln": break_even_profit,
        "estonian_cit_recommended": recommended,
        "estonian_cit_transition_steps": transition_steps,
        "estonian_cit_employees_needed": max([0, 3 - employee_count]),
        "legal_basis": "Art. 551-584 KSH; Art. 28c-28t CIT",
        "_routing": routing,
        "_routing_reason": sprintf("JDG→ECIT: oszczednosc %.2f PLN/rok — %s", [savings, recommended && "ZALECANE" || "POCZEKAJ"]),
        "_warnings": [sprintf("🔄 ECIT-300 JDG→SP. Z O.O. SYMULACJA:\n   JDG rocznie: %.0f PLN (PIT %.0f + ZUS %.0f + Zdrowotna %.0f)\n   Sp. z o.o. ECIT: %.0f PLN (Podatek 0 + Admin %.0f + ZUS %.0f)\n   Oszczednosc: %.0f PLN/rok (%.0f%%)\n   Break-even: %.0f PLN zysku\n   %s\n   ⚠️ Potrzebujesz min. %d pracownikow do ECIT!",
            [jdg_total, jdg_pit, jdg_zus, jdg_health, ecit_total, ecit_admin, ecit_zus_owner, savings, savings_pct, break_even_profit, recommended && "✅ ZALECANE — przeksztalc w Sp. z o.o. + Estonski CIT!" || "⏳ Zwieksz zysk powyzej break-even", max([0, 3 - employee_count])])]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ECIT-400: ESTONIAN CIT COMPLIANCE — Obowiazki i terminy
# ═══════════════════════════════════════════════════════════════════════════════

else := verdict {
    input.jdg_entrepreneur.legal_form in {"SP_ZOO", "SA"}

    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 2000000)

    obligations := [
        "ZAW-CIT-RD — zgloszenie wyboru Estonskiego CIT (do konca 1. miesiaca roku podatkowego)",
        "CIT-8E — deklaracja roczna Estonskiego CIT (do konca 3. miesiaca po zakonczeniu roku)",
        "Pelna księgowosc UoR — obowiazkowa",
        "Sprawozdanie finansowe — audyt przy >2.5M EUR przychodow",
        "KRS — aktualne wpisy, skladanie sprawozdan",
        "Podatek tylko przy wyplacie zysku (dywidenda) — 0% przy reinwestycji",
        "Min. 3 pracownikow przez minimum 300 dni w roku",
        "Limit 50M EUR przychodow rocznie",
        "Udziały tylko osob fizycznych — bez udziałowcow prawnych",
        "Brak udzialow w innych podmiotach (max 5%)",
        "Przychody pasywne < 50% calkowitych przychodow"
    ]

    deadlines := {
        "zaw_cit_rd": "do konca 1. miesiaca roku podatkowego",
        "cit_8e": "do konca 3. miesiaca po zakonczeniu roku",
        "krs_financials": "15 dni od zatwierdzenia sprawozdania",
        "employee_minimum": "min. 300 dni w roku podatkowym"
    }

    verdict := {
        "matched": true,
        "rule_id": "jdg.estonian_cit.compliance",
        "package": "jdg.estonian_cit",
        "priority": 400,
        "action": "CHECK_ECIT_COMPLIANCE",
        "estonian_cit_obligations": obligations,
        "estonian_cit_deadlines": deadlines,
        "estonian_cit_obligation_count": count(obligations),
        "legal_basis": "Art. 28j-28t CIT; UoR; KSH",
        "_routing": "",
        "_routing_reason": sprintf("ECIT Compliance: %d obowiazkow", [count(obligations)]),
        "_warnings": [sprintf("📋 ECIT-400 ESTONIAN CIT OBLIGATIONS:\n   %d kluczowych obowiazkow:\n   %s\n   ⚠️ UWAGA: Utrata warunkow = UTRATA Estonskiego CIT na 3 lata!",
            [count(obligations), concat("\n   • ", obligations)])]
    }
}
