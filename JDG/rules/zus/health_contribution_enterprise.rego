# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise Health Contribution Intelligence (Class XII)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Health Contribution — Składka Zdrowotna per Forma PIT
# description: |
#   ENTERPRISE v5.0 — Wypełnia lukę 25 punktów Klasy XII (Zdrowotna+Zasiłkowa).
#   Szczegółowe reguły naliczania składki zdrowotnej dla każdej formy PIT:
#   - H100-H109: Skala PIT — 9% od dochodu, NIEodliczalna, min. podstawa
#   - H110-H119: Liniowy PIT — 4.9% od dochodu, odliczenie max 14 100 PLN/rok
#   - H120-H129: Ryczałt — 3 progi kwotowe od przychodu rocznego
#   - H130-H139: Karta podatkowa — 9% od minimalnego wynagrodzenia
#   - H140-H149: Minimum base, roczne rozliczenie, nadpłata/zwrot
#   - H150-H159: Zbieg tytułów, podwójna zdrowotna, utrata pokrycia NFZ
#   Wypełnia lukę: szczegółowe podstawy wymiaru, progi, limity odliczeń,
#   rozliczenie roczne, konsekwencje braku opłacania.
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Art. 79-83 Ustawy o świadczeniach opieki zdrowotnej (Dz.U. 2004 nr 210 poz. 2135)
#   Polski Ład 2.0 (Dz.U. 2022 poz. 1740)
# package: jdg.zus.health_contribution
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.zus.health_contribution

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.zus.health.no_match",
    "package": "jdg.zus.health_contribution", "priority": 899
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  H100-H109: SKŁADKA ZDROWOTNA — SKALA PIT (9% od dochodu)                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── H100: health_scale_basis — Podstawa wymiaru: dochód z JDG na skali ──
# FIX v7.1 K6: min_base = 100% min. wynagrodzenia (nie 75%); 75% tylko w pierwszym roku
decide := {
    "matched": true, "rule_id": "jdg.zus.health.scale_basis",
    "package": "jdg.zus.health_contribution", "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "PIT_SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "zus_health_basis_pln": health_basis,
    "zus_health_monthly_pln": health_monthly,
    "zus_health_deductible": false,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": scale_rt,
    "_routing_reason": scale_rs,
    "_legal_basis": "Art. 81 ust. 2 ustawy o świadczeniach (Polski Ład 2022)",
    "_warnings": [sprintf("SKŁADKA ZDROWOTNA — SKALA 9%%. Dochód: %.2f PLN/mies → składka: %.2f PLN/mies. Min. podstawa: %.2f PLN (100%% min. wynagrodzenia = %.2f PLN, 75%% = %.2f PLN tylko w 1. roku). NIE odlicza się od PIT na skali! Zapłać do 10. dnia następnego miesiąca.", [monthly_income, health_monthly, min_base, min_wage, first_year_base])]
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    input.jdg_entrepreneur.health_contribution_active == true
    # thresholds loaded via global data document (package jdg.thresholds)
    monthly_income := object.get(input.jdg_entrepreneur, "monthly_income_net", 0)
    min_wage := object.get(object.get(data.jdg.thresholds, "bounds", {}), "minimum_wage_gross", 4800)
    # Podstawa = 100% min. wynagrodzenia (75% tylko w pierwszym roku działalności)
    is_first_year := object.get(input.jdg_entrepreneur, "is_first_year_of_business", false)
    first_year_base := floor(min_wage * 0.75 * 100) / 100
    min_base = first_year_base { is_first_year }
    min_base = min_wage { not is_first_year }
    # Podstawa = max(dochód miesięczny, minimalna podstawa)
    health_basis := max([monthly_income, min_base])
    health_monthly := floor(health_basis * 0.09 * 100) / 100
    scale_rt = "TRIAGE_QUEUE" { health_monthly > 2000 }
    scale_rt = "" { health_monthly <= 2000 }
    scale_rs = sprintf("Wysoka składka zdrowotna %.2f PLN — sprawdź czy dochód prawidłowy", [health_monthly]) { health_monthly > 2000 }
    scale_rs = "" { health_monthly <= 2000 }
}

# ── H101: health_scale_no_deduction — Skala: składka NIEodliczalna od PIT ──
else := {
    "matched": true, "rule_id": "jdg.zus.health.scale_no_deduction",
    "package": "jdg.zus.health_contribution", "priority": 101,
    "pit_form": "PIT_SCALE", "pit_rate": "", "pit_bracket": "",
    "zus_health_deductible": false, "zus_health_deduction_note": "BRAK ODLICZENIA",
    "_legal_basis": "Art. 26 ust. 1 pkt 2 PIT (brak odliczenia składki zdrowotnej na skali)",
    "_warnings": ["SKALA PIT — składka zdrowotna 9%% NIE podlega odliczeniu od dochodu ani od podatku! Polski Ład 2022 zniósł odliczanie składki zdrowotnej dla osób na skali podatkowej. Efektywne obciążenie = PIT 12/32%% + ZUS zdrowotna 9%%."]
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    input.jdg_entrepreneur.health_contribution_active == true
}

# ── H102: health_scale_zero_income — Skala: zerowy dochód → minimalna składka ──
else := {
    "matched": true, "rule_id": "jdg.zus.health.scale_zero_income",
    "package": "jdg.zus.health_contribution", "priority": 102,
    "pit_form": "PIT_SCALE", "zus_health_rate": "0.09",
    "zus_health_basis_pln": min_wage,
    "zus_health_monthly_pln": health_monthly,
    "zus_health_zero_income_note": "MINIMALNA SKŁADKA — dochód 0 PLN",
    "_legal_basis": "Art. 81 ust. 2b ustawy o świadczeniach",
    "_warnings": [sprintf("SKALA PIT — ZEROWY DOCHÓD. Mimo braku dochodu, składka zdrowotna NALEŻNA od minimalnej podstawy: %.2f PLN × 9%% = %.2f PLN/mies. NIE ma zwolnienia ze składki zdrowotnej dla JDG bez dochodu!", [min_wage, health_monthly])]
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    input.jdg_entrepreneur.monthly_income_net <= 0
    input.jdg_entrepreneur.health_contribution_active == true
    # thresholds loaded via global data document (package jdg.thresholds)
    min_wage := object.get(object.get(data.jdg.thresholds, "bounds", {}), "minimum_wage_gross", 4800)
    health_monthly := floor(min_wage * 0.09 * 100) / 100
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  H110-H119: SKŁADKA ZDROWOTNA — LINIOWY PIT (4.9% od dochodu)            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── H110: health_linear_basis — Podstawa: dochód — liniowy 4.9% ──
# FIX v7.1 K6: min_base = 100% min. wynagrodzenia; 75% tylko w pierwszym roku
decide := {
    "matched": true, "rule_id": "jdg.zus.health.linear_basis",
    "package": "jdg.zus.health_contribution", "priority": 110,
    "pit_form": "LINEAR", "zus_health_rate": "0.049",
    "zus_health_basis_pln": health_basis,
    "zus_health_monthly_pln": health_monthly,
    "zus_health_deductible": true,
    "zus_health_max_annual_deduction_pln": health_linear_deduction_limit,
    "zus_health_deduction_remaining_pln": deduction_remaining,
    "_routing": "",
    "_routing_reason": sprintf("Składka zdrowotna liniowy: %.2f PLN/mies (4.9%% × %.2f PLN). Odliczenie: %.2f/%.0f PLN", [health_monthly, health_basis, deduction_used, health_linear_deduction_limit]),
    "_legal_basis": "Art. 81 ust. 2c ustawy o świadczeniach",
    "_warnings": [sprintf("SKŁADKA ZDROWOTNA — LINIOWY 4.9%%. Dochód: %.2f PLN/mies → składka: %.2f PLN/mies. MOŻNA ODLICZYĆ od dochodu do %.0f PLN/rok! Odliczono: %.2f PLN, pozostało: %.2f PLN.", [monthly_income, health_monthly, health_linear_deduction_limit, deduction_used, deduction_remaining])]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
    input.jdg_entrepreneur.health_contribution_active == true
    # thresholds loaded via global data document (package jdg.thresholds)
    monthly_income := object.get(input.jdg_entrepreneur, "monthly_income_net", 0)
    min_wage := object.get(object.get(data.jdg.thresholds, "bounds", {}), "minimum_wage_gross", 4800)
    is_first_year := object.get(input.jdg_entrepreneur, "is_first_year_of_business", false)
    first_year_base := floor(min_wage * 0.75 * 100) / 100
    min_base = first_year_base { is_first_year }
    min_base = min_wage { not is_first_year }
    health_basis := max([monthly_income, min_base])
    health_monthly := floor(health_basis * 0.049 * 100) / 100
    # SPOF: unified deduction limit 2026 = 14 100 PLN
    health_linear_deduction_limit := object.get(object.get(data.jdg.thresholds, "zus", {}), "health_linear_deduction_limit", 14100)
    annual_paid := object.get(input.jdg_entrepreneur, "health_annual_paid", 0)
    deduction_used := min([annual_paid, health_linear_deduction_limit])
    deduction_remaining := max([0, health_linear_deduction_limit - annual_paid])
}

# ── H111: health_linear_deduction_tracker — Tracker rocznego odliczenia ──
else := {
    "matched": true, "rule_id": "jdg.zus.health.linear_deduction_tracker",
    "package": "jdg.zus.health_contribution", "priority": 111,
    "pit_form": "LINEAR",
    "zus_health_deductible": true,
    "zus_health_annual_paid_pln": annual_paid,
    "zus_health_deduction_limit_pln": data.thresholds.zus.health_linear_deduction_limit,
    "zus_health_deduction_used_pln": deduction_used,
    "zus_health_deduction_remaining_pln": deduction_remaining,
    "_routing": "",
    "_routing_reason": sprintf("Odliczenie zdrowotnej: %.2f PLN wykorzystane z %.0f PLN (%.2f PLN pozostało)", [deduction_used, data.thresholds.zus.health_linear_deduction_limit, deduction_remaining]),
    "_legal_basis": "Art. 30c ust. 2 PIT (odliczenie składki zdrowotnej przy liniowym)",
    "_warnings": [sprintf("ODLICZENIE ZDROWOTNEJ LINIOWY — Zapłacono: %.2f PLN/rok. Limit: %.0f PLN. Odliczono: %.2f PLN. Pozostało: %.2f PLN. Maksymalizuj odliczenie = płać składkę zdrowotną terminowo! Niewykorzystany limit przepada.", [annual_paid, data.thresholds.zus.health_linear_deduction_limit, deduction_used, deduction_remaining])]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
    input.jdg_entrepreneur.health_contribution_active == true
    annual_paid := object.get(input.jdg_entrepreneur, "health_annual_paid", 0)
    annual_paid < data.thresholds.zus.health_linear_deduction_limit
    deduction_used := min([annual_paid, data.thresholds.zus.health_linear_deduction_limit])
    deduction_remaining := max([0, data.thresholds.zus.health_linear_deduction_limit - annual_paid])
}

# ── H112: health_linear_limit_exceeded — Po przekroczeniu limitu ODLICZENIA (składka NADAL należna!) ──
# FIX v7.1 K1: Składka 4.9% płacona ZAWSZE, limit dotyczy tylko ODLICZENIA od dochodu!
# art. 30c ust. 2 PIT: limit odliczenia 14 100 PLN/rok, ale składka bez górnego limitu
else := {
    "matched": true, "rule_id": "jdg.zus.health.linear_limit_exceeded",
    "package": "jdg.zus.health_contribution", "priority": 112,
    "pit_form": "LINEAR", "zus_health_rate": "0.049",
    "zus_health_monthly_pln": health_monthly,
    "zus_health_basis_pln": health_basis,
    "zus_health_deductible": false,
    "zus_health_deduction_exhausted": true,
    "zus_health_annual_paid_pln": annual_paid,
    "zus_health_deduction_limit_pln": health_linear_deduction_limit,
    "zus_health_no_deduction_remaining": true,
    "_routing": "WARNING",
    "_routing_reason": sprintf("LIMIT ODLICZENIA WYCZERPANY — Zapłacono %.2f PLN z limitu %.0f PLN. Składka %.2f PLN NADAL NALEŻNA (4.9%% od dochodu bez limitu!), ale NIE podlega już odliczeniu od dochodu.", [annual_paid, health_linear_deduction_limit, health_monthly]),
    "_legal_basis": "Art. 30c ust. 2 PIT (limit ODLICZENIA, nie składki!); Art. 81 ust. 2c u.ś.o.z.",
    "_warnings": [sprintf("⚠️ LIMIT ODLICZENIA WYCZERPANY — Zapłacono %.2f PLN (limit %.0f PLN/rok). SKŁADKA %.2f PLN NADAL NALEŻNA! Zapłać 4.9%% × dochód = %.2f PLN. Brak odliczenia od PIT oznacza wyższy efektywny koszt. NIEPŁACENIE = utrata NFZ po 30 dniach!", [annual_paid, health_linear_deduction_limit, health_monthly, health_monthly])]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
    input.jdg_entrepreneur.health_contribution_active == true
    monthly_income := object.get(input.jdg_entrepreneur, "monthly_income_net", 0)
    min_wage := object.get(object.get(data.jdg.thresholds, "bounds", {}), "minimum_wage_gross", 4800)
    is_first_year := object.get(input.jdg_entrepreneur, "is_first_year_of_business", false)
    first_year_base := floor(min_wage * 0.75 * 100) / 100
    min_base = first_year_base { is_first_year }
    min_base = min_wage { not is_first_year }
    health_basis := max([monthly_income, min_base])
    health_monthly := floor(health_basis * 0.049 * 100) / 100
    annual_paid := object.get(input.jdg_entrepreneur, "health_annual_paid", 0)
    health_linear_deduction_limit := object.get(object.get(data.jdg.thresholds, "zus", {}), "health_linear_deduction_limit", 14100)
    annual_paid >= health_linear_deduction_limit
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  H120-H129: SKŁADKA ZDROWOTNA — RYCZAŁT (3 progi kwotowe)                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── H120: health_lump_sum_tiers — Ryczałt: 3 progi przychodowe ──
else := {
    "matched": true, "rule_id": "jdg.zus.health.lump_sum_tiers",
    "package": "jdg.zus.health_contribution", "priority": 120,
    "pit_form": "LUMP_SUM", "zus_health_rate": "RYCZAŁT",
    "zus_health_tier": tier,
    "zus_health_monthly_pln": health_monthly,
    "zus_health_annual_revenue_pln": annual_revenue,
    "zus_health_deductible": false,
    "_routing": lump_rt,
    "_routing_reason": sprintf("Ryczałt — próg %s: %.2f PLN/mies", [tier, health_monthly]),
    "_legal_basis": "Art. 81 ust. 2e ustawy o świadczeniach",
    "_warnings": [sprintf("SKŁADKA ZDROWOTNA — RYCZAŁT. Przychód roczny: %.2f PLN → próg %s → składka: %.2f PLN/mies. Progi 2026: (1) ≤60k PLN = 491.40 PLN/mies (60%% przeciętnego), (2) 60-300k PLN = 819.00 PLN/mies (100%% przeciętnego), (3) >300k PLN = 1 474.20 PLN/mies (180%% przeciętnego). Roczne rozliczenie do 22 maja! Nadpłata = zwrot z ZUS.", [annual_revenue, tier, health_monthly])]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    input.jdg_entrepreneur.health_contribution_active == true
    # thresholds loaded via global data document (package jdg.thresholds)
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)
    tier1 := object.get(object.get(data.jdg.thresholds, "zus", {}), "health_lump_tier_1_amount", 491.40)
    tier2 := object.get(object.get(data.jdg.thresholds, "zus", {}), "health_lump_tier_2_amount", 819.00)
    tier3 := object.get(object.get(data.jdg.thresholds, "zus", {}), "health_lump_tier_3_amount", 1474.20)
    limit1 := object.get(object.get(data.jdg.thresholds, "zus", {}), "health_lump_tier_1_limit", 60000)
    limit2 := object.get(object.get(data.jdg.thresholds, "zus", {}), "health_lump_tier_2_limit", 300000)
    tier = "I (≤60k)" { annual_revenue <= limit1 }
    tier = "II (60k-300k)" { annual_revenue > limit1; annual_revenue <= limit2 }
    tier = "III (>300k)" { annual_revenue > limit2 }
    health_monthly = tier1 { annual_revenue <= limit1 }
    health_monthly = tier2 { annual_revenue > limit1; annual_revenue <= limit2 }
    health_monthly = tier3 { annual_revenue > limit2 }
    lump_rt = "BLOCK_AND_ALERT" { annual_revenue > limit2; health_monthly > 1000 }
    lump_rt = "" { true }
}

# ── H121: health_lump_sum_annual_settlement — Roczne rozliczenie ryczałtu ──
else := {
    "matched": true, "rule_id": "jdg.zus.health.lump_sum_annual",
    "package": "jdg.zus.health_contribution", "priority": 121,
    "pit_form": "LUMP_SUM",
    "zus_health_annual_paid_pln": total_paid,
    "zus_health_annual_due_pln": total_due,
    "zus_health_overpayment_pln": overpayment,
    "zus_health_underpayment_pln": underpayment,
    "zus_health_settlement_deadline": "MAY_22",
    "_routing": settle_rt,
    "_routing_reason": sprintf("Rozliczenie roczne: %.2f PLN %s", [abs(balance), balance_type]),
    "_legal_basis": "Art. 81 ust. 2f-2h ustawy o świadczeniach",
    "_warnings": [sprintf("ROCZNE ROZLICZENIE ZDROWOTNEJ RYCZAŁT — Zapłacono: %.2f PLN (12 × %.2f). Należna: %.2f PLN (próg %s). %s: %.2f PLN. Termin: 22 maja. Nadpłatę ZUS zwraca na konto, niedopłatę wpłać do ZUS.", [total_paid, monthly_paid, total_due, tier, balance_type, abs(balance)])]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    input.jdg_entrepreneur.health_annual_settlement == true
    monthly_paid := object.get(input.jdg_entrepreneur, "health_monthly_paid", 491.40)
    total_paid := monthly_paid * 12
    correct_tier := object.get(input.jdg_entrepreneur, "health_correct_tier_monthly", 491.40)
    total_due := correct_tier * 12
    balance := total_paid - total_due
    overpayment := max([0, balance])
    underpayment := max([0, -balance])
    balance_type = "NADPŁATA" { balance > 0 }
    balance_type = "NIEDOPŁATA" { balance < 0 }
    balance_type = "ZGODNE" { balance == 0 }
    settle_rt = "TRIAGE_QUEUE" { underpayment > 0 }
    settle_rt = "" { true }
    tier = "I" { correct_tier == object.get(object.get(data.jdg.thresholds, "zus", {}), "health_lump_tier_1_amount", 491.40) }
    tier = "II" { correct_tier == object.get(object.get(data.jdg.thresholds, "zus", {}), "health_lump_tier_2_amount", 819.00) }
    tier = "III" { correct_tier == object.get(object.get(data.jdg.thresholds, "zus", {}), "health_lump_tier_3_amount", 1474.20) }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  H130-H139: SKŁADKA ZDROWOTNA — KARTA PODATKOWA (9% od min. płacy)      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── H130: health_tax_card_basis — Karta podatkowa: 9% od minimalnej płacy ──
else := {
    "matched": true, "rule_id": "jdg.zus.health.tax_card_basis",
    "package": "jdg.zus.health_contribution", "priority": 130,
    "pit_form": "TAX_CARD", "zus_health_rate": "0.09",
    "zus_health_basis_pln": min_wage,
    "zus_health_monthly_pln": health_monthly,
    "_routing": "",
    "_routing_reason": sprintf("Karta podatkowa: 9%% × %.2f PLN = %.2f PLN/mies", [min_wage, health_monthly]),
    "_legal_basis": "Art. 81 ust. 2a ustawy o świadczeniach",
    "_warnings": [sprintf("SKŁADKA ZDROWOTNA — KARTA PODATKOWA. Podstawa: minimalne wynagrodzenie %.2f PLN × 9%% = %.2f PLN/mies. NIE zależy od dochodu! Stała kwota przez cały rok.", [min_wage, health_monthly])]
} {
    input.jdg_entrepreneur.tax_form == "TAX_CARD"
    input.jdg_entrepreneur.health_contribution_active == true
    # thresholds loaded via global data document (package jdg.thresholds)
    min_wage := object.get(object.get(data.jdg.thresholds, "bounds", {}), "minimum_wage_gross", 4800)
    health_monthly := floor(min_wage * 0.09 * 100) / 100
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  H140-H149: PODSTAWA MINIMALNA + ROCZNE ROZLICZENIE + NADPŁATA          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── H140: health_minimum_base_guard — Minimalna podstawa wymiaru (FIX v7.1 K6) ──
# 100% min. wynagrodzenia (standard), 75% tylko w pierwszym roku
decide := {
    "matched": true, "rule_id": "jdg.zus.health.minimum_base_guard",
    "package": "jdg.zus.health_contribution", "priority": 140,
    "zus_health_min_base_applies": applies_min_base,
    "zus_health_min_base_pln": min_base,
    "zus_health_is_first_year": is_first_year,
    "_routing": minbase_rt,
    "_routing_reason": minbase_rs,
    "_legal_basis": "Art. 81 ust. 2b ustawy o świadczeniach",
    "_warnings": [sprintf("MINIMALNA PODSTAWA ZDROWOTNA — %s. Podstawa: %.2f PLN/mies (%s). Składka: %.2f PLN/mies. Dotyczy wszystkich form PIT!", [minbase_note, min_base, base_type, minbase_value])]
} {
    input.jdg_entrepreneur.health_contribution_active == true
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    tax_form in {"PIT_SCALE", "LINEAR"}
    # thresholds loaded via global data document (package jdg.thresholds)
    min_wage := object.get(object.get(data.jdg.thresholds, "bounds", {}), "minimum_wage_gross", 4800)
    is_first_year := object.get(input.jdg_entrepreneur, "is_first_year_of_business", false)
    first_year_base := floor(min_wage * 0.75 * 100) / 100
    min_base = first_year_base { is_first_year }
    min_base = min_wage { not is_first_year }
    base_type = "75%% min. wyn. (pierwszy rok)" { is_first_year }
    base_type = "100%% min. wyn. (standard)" { not is_first_year }
    monthly_income := object.get(input.jdg_entrepreneur, "monthly_income_net", 0)
    applies_min_base := monthly_income < min_base
    minbase_value := floor(min_base * 0.09 * 100) / 100
    minbase_note = "Dochód poniżej minimalnej podstawy — zapłać od minimum" { applies_min_base }
    minbase_note = "Dochód powyżej minimalnej podstawy — OK" { not applies_min_base }
    minbase_rt = "TRIAGE_QUEUE" { applies_min_base }
    minbase_rt = "" { not applies_min_base }
    minbase_rs = sprintf("Dochód %.2f PLN < min. podstawa %.2f PLN — składka od min. podstawy", [monthly_income, min_base]) { applies_min_base }
    minbase_rs = "" { not applies_min_base }
}

# ── H141: health_annual_reconciliation — Roczne rozliczenie składki zdrowotnej ──
else := {
    "matched": true, "rule_id": "jdg.zus.health.annual_reconciliation",
    "package": "jdg.zus.health_contribution", "priority": 141,
    "zus_health_annual_paid_pln": total_paid,
    "zus_health_annual_due_pln": total_due,
    "zus_health_annual_diff_pln": diff,
    "zus_health_reconciliation_deadline": deadline,
    "_routing": recon_rt,
    "_routing_reason": sprintf("Rozliczenie roczne: %.2f PLN %s — termin %s", [abs(diff), diff_type, deadline]),
    "_legal_basis": "Art. 81 ust. 2f-2g ustawy o świadczeniach",
    "_warnings": [sprintf("ROCZNE ROZLICZENIE SKŁADKI ZDROWOTNEJ — %s. Zapłacono: %.2f PLN. Należna: %.2f PLN. %s: %.2f PLN. Termin złożenia dokumentów rocznych do ZUS: %s. %s", [tax_form, total_paid, total_due, diff_type, abs(diff), deadline, action])]
} {
    input.jdg_entrepreneur.health_annual_settlement == true
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    total_paid := object.get(input.jdg_entrepreneur, "health_annual_paid", 0)
    total_due := object.get(input.jdg_entrepreneur, "health_annual_due", total_paid)
    diff := total_paid - total_due
    diff_type = "NADPŁATA" { diff > 0 }
    diff_type = "NIEDOPŁATA" { diff < 0 }
    diff_type = "ZGODNE" { diff == 0 }
    deadline = "22 maja" { tax_form == "LUMP_SUM" }
    deadline = "30 kwietnia" { tax_form in {"PIT_SCALE", "LINEAR"} }
    deadline = "31 stycznia" { tax_form == "TAX_CARD" }
    action = "ZUS zwróci nadpłatę automatycznie na konto" { diff > 0 }
    action = "Wpłać niedopłatę do ZUS w ciągu 7 dni!" { diff < 0 }
    action = "OK" { diff == 0 }
    recon_rt = "BLOCK_AND_ALERT" { diff < -1000 }
    recon_rt = "TRIAGE_QUEUE" { diff < 0; diff >= -1000 }
    recon_rt = "" { true }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  H150-H159: ZBIEG TYTUŁÓW + UTRATA POKRYCIA NFZ                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── H150: health_concurrent_titles — Podwójna składka zdrowotna ──
else := {
    "matched": true, "rule_id": "jdg.zus.health.concurrent_titles",
    "package": "jdg.zus.health_contribution", "priority": 150,
    "zus_health_concurrent_titles": title_count,
    "zus_health_double_contribution": double_health,
    "zus_health_monthly_jdg_pln": jdg_health,
    "zus_health_monthly_other_pln": other_health,
    "_routing": concurrent_rt,
    "_routing_reason": sprintf("Zbieg tytułów: %d tytuły — składka z każdego osobno!", [title_count]),
    "_legal_basis": "Art. 82 ustawy o świadczeniach zdrowotnych",
    "_warnings": [sprintf("ZBIEG TYTUŁÓW UBEZPIECZENIA — %d tytuły → składka zdrowotna z KAŻDEGO osobno! JDG: %.2f PLN/mies + %s: %.2f PLN/mies. Razem: %.2f PLN/mies. NIE ma kumulacji — każdy tytuł = osobna składka.", [title_count, jdg_health, other_title, other_health, total_health])]
} {
    object.get(input.jdg_entrepreneur, "has_multiple_insurance_titles", false) == true
    title_count := object.get(input.jdg_entrepreneur, "insurance_title_count", 2)
    double_health := title_count >= 2
    jdg_health := object.get(input.jdg_entrepreneur, "health_jdg_monthly", 420)
    other_health := object.get(input.jdg_entrepreneur, "health_other_monthly", 420)
    other_title := object.get(input.jdg_entrepreneur, "other_insurance_title", "etat/zlecenie")
    total_health := jdg_health + other_health
    concurrent_rt = "TRIAGE_QUEUE" { total_health > 1500 }
    concurrent_rt = "" { true }
}

# ── H151: health_nfz_coverage_loss — Utrata ubezpieczenia zdrowotnego ──
else := {
    "matched": true, "rule_id": "jdg.zus.health.nfz_coverage_loss",
    "package": "jdg.zus.health_contribution", "priority": 151,
    "zus_health_coverage_active": false,
    "zus_health_arrears_months": months_arrears,
    "sanction_type": "NFZ_COVERAGE_LOSS",
    "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("UTRATA UBEZPIECZENIA NFZ — %d mies. zaległości!", [months_arrears]),
    "_legal_basis": "Art. 69 ust. 1 ustawy o świadczeniach; Art. 34 ust. 1 ustawy o NFZ",
    "_warnings": [sprintf("KRYTYCZNE! UTRATA UBEZPIECZENIA ZDROWOTNEGO! Zaległość: %d mies. bez opłaconej składki zdrowotnej. KONSEKWENCJE: (1) BRAK prawa do leczenia NFZ od 30. dnia zaległości!, (2) Każda wizyta prywatna = 100-300 PLN, (3) Przywrócenie: spłać zaległość + odsetki + wniosek do NFZ, (4) Okres bez ubezpieczenia = wyższe składki w przyszłości.", [months_arrears])]
} {
    input.jdg_entrepreneur.health_contribution_active == true
    months_arrears := object.get(input.jdg_entrepreneur, "health_months_arrears", 0)
    months_arrears >= 1
}

# ── H152: health_concurrent_jdg_employment — JDG + etat: zdrowotna z obu ──
else := {
    "matched": true, "rule_id": "jdg.zus.health.jdg_plus_employment",
    "package": "jdg.zus.health_contribution", "priority": 152,
    "zus_health_jdg_only_reason": "JDG + ETAT",
    "zus_health_from_employment": emp_health,
    "zus_health_from_jdg": jdg_health,
    "_routing": "",
    "_routing_reason": sprintf("JDG+etat: zdrowotna z etatu %.2f + z JDG %.2f = %.2f PLN/mies", [emp_health, jdg_health, total]),
    "_legal_basis": "Art. 82 ust. 1 ustawy o świadczeniach",
    "_warnings": [sprintf("JDG + ETAT — składka zdrowotna z OBIEDWU tytułów! Z etatu (pobiera pracodawca): %.2f PLN/mies. Z JDG (płacisz sam): %.2f PLN/mies. Łącznie: %.2f PLN/mies. BRAK możliwości uniknięcia podwójnej składki.", [emp_health, jdg_health, total])]
} {
    input.jdg_entrepreneur.business_type == "JDG"
    object.get(input.jdg_entrepreneur, "has_concurrent_employment", false) == true
    emp_base := object.get(input.jdg_entrepreneur, "employment_salary_gross", 5000)
    emp_health := floor(emp_base * 0.09 * 100) / 100
    jdg_health := object.get(input.jdg_entrepreneur, "health_jdg_monthly", 420)
    total := emp_health + jdg_health
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.zus.health.fallback",
    "package": "jdg.zus.health_contribution", "priority": 999,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 79-83 ustawy o świadczeniach zdrowotnych",
    "_warnings": ["Składka zdrowotna — standardowe zasady. Zapłać do 10. dnia następnego miesiąca. Podstawa zależna od formy opodatkowania."]
} {
    true
}
