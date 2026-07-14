# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Tax Allowances (P600-P635)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Tax Allowances — Reliefs, IP Box, Crypto, Bad Debt PIT
# description: |
#   PAS 6 Multi-Pass. First-Match-Wins else-chain. Ulgi: B+R (P600),
#   IKZE (P605), IP Box 5% (P610), CSR/sponsoring 150% (P612),
#   terminal płatniczy 200% (P614), złe długi PIT wierzyciel (P618),
#   abolicyjna (P620), związki zawodowe 840 PLN (P622), krypto 19% (P630).
# architecture: Multi-Pass PAS 6 (ADR-001)
# legal_basis: Art. 26-30ca PIT, ustawa o IKZE, ustawa o ryczałcie
# edge_cases:
#   - P600: Centrum B+R → 200%, standard → 100%
#   - P605: IKZE limit roczny 14 083-16 956 PLN, tylko skala/liniowy
#   - P618: >90 dni + !is_paid + receivable_not_sold
#   - P622: związki NIE dla liniowego! (tylko skala i ryczałt)
# package: jdg.allowances
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły ulg podatkowych dla JDG (jednoosobowa działalność gospodarcza):
#   - Ulga B+R (P600) — 100%/200% kosztów kwalifikowanych
#   - Ulga IKZE (P605) — odliczenie wpłat na IKZE od dochodu
#   - Ulga na innowacyjnych pracowników (P608) — odzysk B+R przez PIT-4
#   - IP Box (P610) — 5% od dochodów z kwalifikowanego IP
#   - Ulga CSR/sponsoringowa (P612) — dodatkowe 50% KUP
#   - Ulga na terminal płatniczy (P614) — 200% wydatków, carry-forward 6 lat
#   - Ulga na złe długi PIT wierzyciel (P618) — pomniejszenie dochodu >90 dni
#   - Ulga abolicyjna (P620) — redukcja podatku 1 360 PLN
#   - Ulga na związki zawodowe (P622) — składki do 840 PLN
#   - Krypto (P630) — klasyfikacja kapitałów pieniężnych 19%
#
# package: jdg.allowances
# rule:     decide (first-match-wins else chain)
#
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.allowances

# ── Default: no matching allowance rule ──────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.allowances.no_match",
    "package": "jdg.allowances",
    "priority": 639
}

# ═══════════════════════════════════════════════════════════════════════════════
# P600: relief_rd_jdg — Ulga B+R (Priority 600)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P600: relief_rd_jdg — Centrum B+R (200%) ──────────────────────────────────
# Cel biznesowy: Ulga B+R — odliczenie 200% kosztów kwalifikowanych (Centrum B+R)
# Przesłanki: has_rd_status == true AND is_rd_centrum == true
# Podstawa prawna: Art. 26e ust. 10 PIT
# Mikro-reguły: jdg.pit.a26e.r1-r15
# Priorytet: 600
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_rd_centrum",
    "package": "jdg.allowances",
    "priority": 600,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "R_AND_D",
    "relief_percent": 200,
    "relief_carry_forward_years": 6,
    "_legal_basis": "Art. 26e ust. 10 PIT",
    "_warnings": []
} {
    input.jdg_entrepreneur.has_rd_status == true
    input.jdg_entrepreneur.is_rd_centrum == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ── P600: relief_rd_jdg — Standard B+R (100%) ─────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_rd_standard",
    "package": "jdg.allowances",
    "priority": 600,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "R_AND_D",
    "relief_percent": 100,
    "relief_carry_forward_years": 6,
    "_legal_basis": "Art. 26e ust. 1 PIT",
    "_warnings": []
} {
    input.jdg_entrepreneur.has_rd_status == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P605: relief_ikze_jdg — Ulga IKZE (Priority 605)
# ═══════════════════════════════════════════════════════════════════════════════
#
# IKZE (Indywidualne Konto Zabezpieczenia Emerytalnego)
# Art. 26 ust. 1 pkt 2b PIT + ustawa o IKZE
#
# Mikro-reguły zaimplementowane:
#   r1: ikze_eligibility          — posiadanie konta IKZE warunkiem odliczenia
#   r2: ikze_limit_2024           — limit 14 083,20 PLN (2024)
#   r3: ikze_limit_2025           — limit 15 611,40 PLN (2025)
#   r4: ikze_limit_2026           — limit 16 956,00 PLN (2026)
#   r5: ikze_annual_return_only   — odliczenie TYLKO w zeznaniu rocznym
#   r6: ikze_excess_not_carried   — nadwyżka NIE przechodzi na kolejny rok
# ═══════════════════════════════════════════════════════════════════════════════

# ── r1: IKZE eligibility — account must exist + scale or linear tax form ──────
ikze_eligible {
    object.get(input.jdg_entrepreneur, "has_ikze_account", false) == true
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    tax_form in {"PIT_SCALE", "LINEAR"}
}

# ── r2-r4: IKZE annual limit per tax year ─────────────────────────────────────
ikze_limit = limit {
    tax_year := object.get(input.invoice, "tax_year", 2025)
    tax_year == 2024
    limit := 14083.20
} else = limit {
    tax_year := object.get(input.invoice, "tax_year", 2025)
    tax_year == 2025
    limit := 15611.40
} else = limit {
    tax_year := object.get(input.invoice, "tax_year", 2025)
    tax_year == 2026
    limit := 16956.00
} else = limit {
    limit := 16956.00
}

# ── P605: IKZE with contribution > 0 ──────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_ikze",
    "package": "jdg.allowances",
    "priority": 605,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "IKZE",
    "relief_limit": ikze_limit,
    "relief_deductible": min([ikze_contribution, ikze_limit]),
    "relief_carry_forward_years": 0,
    "relief_annual_only": true,
    "relief_rule_ids": ["jdg.pit.a26b.r1", "jdg.pit.a26b.r2", "jdg.pit.a26b.r3", "jdg.pit.a26b.r4", "jdg.pit.a26b.r5", "jdg.pit.a26b.r6"],
    "_legal_basis": "Art. 26 ust. 1 pkt 2b PIT",
    "_warnings": ikze_warnings
} {
    ikze_eligible
    ikze_contribution := object.get(input.jdg_entrepreneur, "ikze_annual_contribution", 0)
    ikze_contribution > 0
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")

    # Build warnings — only include over-limit warning when applicable
    ikze_warnings := array.concat(
        [sprintf("IKZE: limit %.2f PLN, wplacono %.2f PLN, odliczono %.2f PLN", [ikze_limit, ikze_contribution, min([ikze_contribution, ikze_limit])])],
        ikze_over_limit_warning(ikze_contribution, ikze_limit)
    )
}

# ── Helper: over-limit warning (empty array when within limit) ─────────────────
ikze_over_limit_warning(contribution, limit) = [msg] {
    contribution > limit
    msg := sprintf("IKZE: wplata %.2f PLN przekracza limit %.2f PLN — nadwyzka %.2f PLN przepada", [contribution, limit, contribution - limit])
} else = [] {
    contribution <= limit
}

# ── P605_b: IKZE — eligible but no contribution this year ─────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_ikze_no_contribution",
    "package": "jdg.allowances",
    "priority": 605,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "IKZE",
    "relief_limit": ikze_limit,
    "relief_deductible": 0,
    "relief_carry_forward_years": 0,
    "relief_annual_only": true,
    "relief_rule_ids": ["jdg.pit.a26b.r1"],
    "_legal_basis": "Art. 26 ust. 1 pkt 2b PIT",
    "_warnings": ["IKZE: konto aktywne, brak wplat w tym roku — odliczenie 0 PLN"]
} {
    ikze_eligible
    ikze_contribution := object.get(input.jdg_entrepreneur, "ikze_annual_contribution", -1)
    ikze_contribution == 0
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P610: relief_ip_box_jdg — IP Box 5% (Priority 610)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P610: relief_ip_box_jdg ────────────────────────────────────────────────────
# Cel biznesowy: IP Box — preferencyjna stawka 5% od dochodów z kwalifikowanego IP
# Przesłanki: Dochód z kwalifikowanego IP (oprogramowanie, patenty)
# Podstawa prawna: Art. 30ca PIT
# Mikro-reguły: jdg.pit.a30ca.r1-r10
# Priorytet: 610
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_ip_box",
    "package": "jdg.allowances",
    "priority": 610,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "0.05",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "IP_BOX",
    "relief_rule_ids": ["jdg.pit.a30ca.r1", "jdg.pit.a30ca.r2", "jdg.pit.a30ca.r3", "jdg.pit.a30ca.r4", "jdg.pit.a30ca.r5", "jdg.pit.a30ca.r6", "jdg.pit.a30ca.r7", "jdg.pit.a30ca.r8", "jdg.pit.a30ca.r9", "jdg.pit.a30ca.r10"],
    "_legal_basis": "Art. 30ca PIT",
    "_warnings": ["IP Box — stawka 5% od kwalifikowanego dochodu z wlasnosci intelektualnej (wymagana wyodrebniona ewidencja + wskaznik Nexus)"]
} {
    input.invoice.expense_type == "IP_INCOME"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    pit_form in {"PIT_SCALE", "LINEAR"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# P608: relief_innovative_employees_jdg — Ulga na innowacyjnych pracowników
# ═══════════════════════════════════════════════════════════════════════════════
#
# Ulga na innowacyjnych pracowników (Art. 26eb PIT)
#
# Pracodawca (JDG), który poniósł stratę lub nie mógł w pełni odliczyć
# ulgi B+R, pomniejsza zaliczki PIT-4 od wynagrodzeń pracowników B+R.
#
# Mikro-reguły: jdg.pit.a26eb.r1-r7
# ═══════════════════════════════════════════════════════════════════════════════

# ── r1: eligibility check ─────────────────────────────────────────────────────
innovative_employee_eligible {
    input.jdg_entrepreneur.has_rd_status == true
    rd_emps := object.get(input.jdg_entrepreneur, "rd_employees", [])
    is_array(rd_emps)
    count(rd_emps) > 0
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    tax_form in {"PIT_SCALE", "LINEAR"}
}

# ── P608: main decision ───────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_innovative_employees",
    "package": "jdg.allowances",
    "priority": 608,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "INNOVATIVE_EMPLOYEES",
    "relief_pit4_reduction": pit4_reduction,
    "relief_requires_rd_evidence": true,
    "relief_rule_ids": ["jdg.pit.a26eb.r1", "jdg.pit.a26eb.r2", "jdg.pit.a26eb.r3", "jdg.pit.a26eb.r4", "jdg.pit.a26eb.r5", "jdg.pit.a26eb.r6", "jdg.pit.a26eb.r7"],
    "_legal_basis": "Art. 26eb PIT",
    "_warnings": ["Ulga na innowacyjnych pracownikow — odzysk niewykorzystanej ulgi B+R przez redukcje PIT-4 (pracownicy >= 50% czasu B+R)"]
} {
    innovative_employee_eligible
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    total_pit4 := object.get(input.jdg_entrepreneur, "rd_employees_monthly_pit4", 0)
    unused_rd := object.get(input.jdg_entrepreneur, "unused_rd_relief", 0)
    pit4_reduction := min([total_pit4, unused_rd])
    unused_rd > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P612: relief_csr_sponsoring_jdg — Ulga CSR / sponsoringowa
# ═══════════════════════════════════════════════════════════════════════════════
#
# Ulga na działalność sportową, kulturalną i naukową (Art. 26ha PIT)
# Dodatkowe 50% KUP (łącznie 150% kosztów) — wydatek musi być uprzednio KUP.
#
# Mikro-reguły: jdg.pit.a26ha.r1-r5
# ═══════════════════════════════════════════════════════════════════════════════

# ── P612: main decision ───────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_csr_sponsoring",
    "package": "jdg.allowances",
    "priority": 612,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "CSR_SPONSORING",
    "relief_percent_additional": 50,
    "relief_total_kup_percent": 150,
    "relief_capped_at_income": true,
    "relief_rule_ids": ["jdg.pit.a26ha.r1", "jdg.pit.a26ha.r2", "jdg.pit.a26ha.r3", "jdg.pit.a26ha.r4", "jdg.pit.a26ha.r5"],
    "_legal_basis": "Art. 26ha PIT",
    "_warnings": ["Ulga CSR/sponsoringowa — dodatkowe 50%% KUP (lacznie 150%%). Wydatek musi byc uprzednio zaliczony do KUP."]
} {
    input.invoice.expense_type == "CSR_SPONSORING"
    input.invoice.is_kup == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    pit_form in {"PIT_SCALE", "LINEAR"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# P614: relief_payment_terminal_jdg — Ulga na terminal płatniczy
# ═══════════════════════════════════════════════════════════════════════════════
#
# Ulga na terminal płatniczy (Art. 26hd PIT)
# 200% wydatków na nabycie i obsługę terminala. Carry-forward 6 lat (łącznie 7).
#
# Mikro-reguły: jdg.pit.a26hd.r1-r6
# ═══════════════════════════════════════════════════════════════════════════════

# ── r3-r4: terminal limit per taxpayer type ────────────────────────────────────
terminal_limit = limit {
    object.get(input.jdg_entrepreneur, "cash_register_exempt", false) == true
    limit := 2500
} else = limit {
    limit := 1000
}

# ── P614: main decision ───────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_payment_terminal",
    "package": "jdg.allowances",
    "priority": 614,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "PAYMENT_TERMINAL",
    "relief_percent": 200,
    "relief_limit": terminal_limit,
    "relief_carry_forward_years": 6,
    "relief_rule_ids": ["jdg.pit.a26hd.r1", "jdg.pit.a26hd.r2", "jdg.pit.a26hd.r3", "jdg.pit.a26hd.r4", "jdg.pit.a26hd.r5", "jdg.pit.a26hd.r6"],
    "_legal_basis": "Art. 26hd PIT",
    "_warnings": ["Ulga na terminal platniczy — 200%% wydatkow, carry-forward 6 lat (lacznie 7). Limit: 2500 PLN (zwolnieni z kasy) lub 1000 PLN (pozostali)."]
} {
    input.invoice.expense_type == "PAYMENT_TERMINAL"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    pit_form in {"PIT_SCALE", "LINEAR"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# P618: relief_bad_debt_pit_creditor_jdg — Ulga na złe długi PIT (wierzyciel)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Ulga na złe długi PIT — wierzyciel (Art. 26i PIT)
# Pomniejszenie dochodu o nieściągalną wierzytelność >90 dni po terminie.
#
# Mikro-reguły: jdg.pit.a26i.r1-r7
# ═══════════════════════════════════════════════════════════════════════════════

# ── r1: 90 days past due ──────────────────────────────────────────────────────
bad_debt_pit_eligible {
    input.invoice.days_overdue >= 90
    input.invoice.is_paid == false
}

# ── r2-r4: additional conditions ──────────────────────────────────────────────
bad_debt_pit_recourse {
    input.invoice.receivable_in_revenue == true
    input.invoice.receivable_not_sold == true
    input.invoice.debtor_not_restructuring == true
}

# ── P618: main decision ───────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_bad_debt_pit_creditor",
    "package": "jdg.allowances",
    "priority": 618,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "BAD_DEBT_PIT_CREDITOR",
    "relief_income_reduction": receivable_amount,
    "relief_days_required": 90,
    "relief_reversal_on_payment": true,
    "relief_rule_ids": ["jdg.pit.a26i.r1", "jdg.pit.a26i.r2", "jdg.pit.a26i.r3", "jdg.pit.a26i.r4", "jdg.pit.a26i.r5", "jdg.pit.a26i.r6", "jdg.pit.a26i.r7"],
    "_legal_basis": "Art. 26i PIT",
    "_warnings": [sprintf("Zle dlugi PIT — wierzyciel: pomniejszenie dochodu o %.2f PLN (niezaplacone >90 dni). Przy pozniejszej zaplacie — OBOWIAZEK zwiekszenia dochodu!", [receivable_amount])]
} {
    bad_debt_pit_eligible
    bad_debt_pit_recourse
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    pit_form in {"PIT_SCALE", "LINEAR"}
    receivable_amount := object.get(input.invoice, "amount_net", 0)
    receivable_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P620: relief_abolition_jdg — Ulga abolicyjna
# ═══════════════════════════════════════════════════════════════════════════════
#
# Ulga abolicyjna (Art. 27g PIT)
# Zmniejsza PODATEK (nie dochód!) o różnicę między metodą kredytu a wyłączenia.
# Limit 1 360 PLN rocznie (od 2021). Wyjątek: marynarze/platformy bez limitu.
#
# Mikro-reguły: jdg.pit.a27g.r1-r6
# ═══════════════════════════════════════════════════════════════════════════════

# ── r1-r5: eligibility ────────────────────────────────────────────────────────
abolition_eligible {
    object.get(input.jdg_entrepreneur, "has_foreign_income_credit_method", false) == true
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    tax_form in {"PIT_SCALE", "LINEAR"}
}

# ── r3: maritime exception — no limit ─────────────────────────────────────────
abolition_is_maritime {
    object.get(input.jdg_entrepreneur, "foreign_income_maritime", false) == true
}

# ── r2: standard limit ────────────────────────────────────────────────────────
abolition_limit = 1360 { not abolition_is_maritime }

# ── P620: main decision ───────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_abolition",
    "package": "jdg.allowances",
    "priority": 620,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "ABOLITION",
    "relief_reduces_tax": true,
    "relief_limit": abolition_limit,
    "relief_maritime_unlimited": abolition_is_maritime,
    "relief_rule_ids": ["jdg.pit.a27g.r1", "jdg.pit.a27g.r2", "jdg.pit.a27g.r3", "jdg.pit.a27g.r4", "jdg.pit.a27g.r5", "jdg.pit.a27g.r6"],
    "_legal_basis": "Art. 27g PIT",
    "_warnings": abolition_warnings
} {
    abolition_eligible
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    abolition_warnings := [sprintf("Ulga abolicyjna: limit %.0f PLN (od podatku). %s", [abolition_limit, abolition_maritime_note])]
    abolition_maritime_note = "Limit NIE obowiazuje — praca na morzu/platformie." {
        abolition_is_maritime
    } else = "" {
        not abolition_is_maritime
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P622: relief_union_dues_jdg — Ulga na związki zawodowe
# ═══════════════════════════════════════════════════════════════════════════════
#
# Ulga na związki zawodowe (Art. 26 ust. 1 pkt 2c PIT)
# Odliczenie składek członkowskich od dochodu. Max 840 PLN rocznie.
# UWAGA: dostępne dla skali i ryczałtu — NIE dla liniowego!
#
# Mikro-reguły: jdg.pit.a26u1p2c.r1-r5
# ═══════════════════════════════════════════════════════════════════════════════

# ── r1, r5: eligibility — union member + scale or lump sum (NOT linear!) ──────
union_dues_eligible {
    object.get(input.jdg_entrepreneur, "is_union_member", false) == true
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    tax_form in {"PIT_SCALE", "LUMP_SUM"}
}

# ── P622: main decision ───────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.relief_union_dues",
    "package": "jdg.allowances",
    "priority": 622,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "full",
    "kus_percent": 100,
    "relief_type": "UNION_DUES",
    "relief_limit": 840,
    "relief_deductible": min([union_dues_paid, 840]),
    "relief_carry_forward_years": 0,
    "relief_rule_ids": ["jdg.pit.a26u1p2c.r1", "jdg.pit.a26u1p2c.r2", "jdg.pit.a26u1p2c.r3", "jdg.pit.a26u1p2c.r4", "jdg.pit.a26u1p2c.r5"],
    "_legal_basis": "Art. 26 ust. 1 pkt 2c PIT",
    "_warnings": [sprintf("Zwiazki zawodowe: odliczono %.2f PLN z limitu 840 PLN (skladki czlonkowskie)", [min([union_dues_paid, 840])])]
} {
    union_dues_eligible
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    union_dues_paid := object.get(input.jdg_entrepreneur, "union_dues_annual", 0)
    union_dues_paid > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P630: crypto_income_classification — Krypto jako kapitały 19% (Priority 630)
# ═══════════════════════════════════════════════════════════════════════════════

# ── P630: crypto_income_classification ─────────────────────────────────────────
# Cel biznesowy: Klasyfikacja przychodów z kryptoaktywów jako odrębne źródło
# Podstawa prawna: Art. 30b ust. 1 pkt 1 PIT
# Priorytet: 630
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.allowances.crypto_income_classification",
    "package": "jdg.allowances",
    "priority": 630,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "CAPITAL_GAINS",
    "pit_rate": "0.19",
    "pit_bracket": "",
    "pit_annual_return_type": "PIT-38",
    "separate_source": true,
    "kus_qualification": "none",
    "_legal_basis": "Art. 30b ust. 1 pkt 1 PIT",
    "_warnings": ["Przychody z kryptoaktywow — odrebne zrodlo (kapitaly pieniezne 19%), NIE laczy sie z JDG!"]
} {
    input.invoice.category_code in {"CRYPTO_SALE", "CRYPTO_EXCHANGE", "CRYPTO_SWAP"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# Standalone Helpers (not in else-chain)
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# P617: income_cap — Suma ulg ≤ dochód (Doc 36)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.allowances.income_cap_reached",
    "package": "jdg.allowances",
    "priority": 617,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": pit_form,
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "relief_type": "INCOME_CAP",
    "relief_total_claimed": total_reliefs,
    "relief_total_capped": min([total_reliefs, annual_income]),
    "relief_excess_forfeited": max([0, total_reliefs - annual_income]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Suma ulg (%.2f PLN) przekracza dochód (%.2f PLN)", [total_reliefs, annual_income]),
    "_legal_basis": "Art. 26 ust. 1 PIT",
    "_warnings": [sprintf("UWAGA: Suma ulg osobistych (%.2f PLN) > dochód (%.2f PLN). Nadwyżka %.2f PLN PRZEPADA (nie przechodzi na kolejny rok)! Wyjątek: ulga B+R (carry-forward 6 lat).", [total_reliefs, annual_income, max([0, total_reliefs - annual_income])])]
} {
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 0)
    annual_income > 0
    total_reliefs := object.get(input.jdg_entrepreneur, "relief_donation_total", 0)
        + object.get(input.jdg_entrepreneur, "relief_rehabilitation_total", 0)
        + object.get(input.jdg_entrepreneur, "relief_internet_total", 0)
        + object.get(input.jdg_entrepreneur, "relief_blood_total", 0)
        + object.get(input.jdg_entrepreneur, "relief_union_dues_total", 0)
    total_reliefs > annual_income
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    # Only check non-RD reliefs — RD has separate carry-forward (Art. 26e ust. 8)
    object.get(input.jdg_entrepreneur, "has_rd_relief", false) == false
}

# ── joint_allowances_limit_info — P616 informational helper ────────────────────
# Cel biznesowy: Łączny limit ulg — suma odliczeń ≤ dochód
# Używane przez upstream passy do walidacji, NIE jest regułą decyzyjną
# Podstawa prawna: Art. 26 ust. 1 PIT
# ────────────────────────────────────────────────────────────────────────────────
joint_allowances_limit_info := {
    "rule_id": "jdg.allowances.joint_allowances_limit",
    "package": "jdg.allowances",
    "priority": 616,
    "relief_total_capped_at_income": true,
    "relief_rd_carry_forward_years": 6,
    "_legal_basis": "Art. 26 ust. 1 PIT",
    "_info": "Suma ulg osobistych NIE MOZE przekroczyc dochodu. WYJATEK: ulga B+R — carry-forward 6 lat (Art. 26e ust. 8 PIT)"
}

# ── relief_rd_carry_forward_info — P616_b informational helper ─────────────────
# Cel biznesowy: Nierozliczona część ulgi B+R przechodzi na 6 lat
# Podstawa prawna: Art. 26e ust. 8 PIT
# ────────────────────────────────────────────────────────────────────────────────
relief_rd_carry_forward_info := {
    "rule_id": "jdg.allowances.relief_rd_carry_forward",
    "package": "jdg.allowances",
    "priority": 616,
    "relief_type": "R_AND_D",
    "relief_carry_forward_years": 6,
    "_legal_basis": "Art. 26e ust. 8 PIT",
    "_info": "Nadwyzka ulgi B+R przechodzi na 6 kolejnych lat (jedyna ulga z carry-forward dla JDG)"
}
