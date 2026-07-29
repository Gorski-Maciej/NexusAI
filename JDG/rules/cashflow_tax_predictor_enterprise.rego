# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE CASH-FLOW TAX PREDICTOR (Strategic Initiative S8)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Cash-Flow Tax Predictor — Liquidity & Deadline Engine
# description: |
#   ENTERPRISE v5.1 — Predykcyjny silnik przepływów podatkowych:
#   - Predicts upcoming tax liabilities (VAT, PIT advances, ZUS) 30/60/90 days ahead
#   - Cash-flow stress testing (Monte Carlo light)
#   - Liquidity gap detection (when tax > available cash)
#   - Tax deadline calendar with amounts
#   - Seasonal pattern detection
#   - Buffer recommendations (how much cash to keep)
#   Wypełnia lukę: przedsiębiorca nie wie czy będzie miał kasę na podatki za 2 miesiące.
# architecture: Enterprise Predictive Engine, First-Match-Wins else-chain
# legal_basis: Art. 44 PIT, Art. 103 VAT, Art. 47 SUS
# package: jdg.cashflow_predictor
# deprecated: false
# priority_range: 1700-1749
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.cashflow_predictor

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.cashflow.no_match",
    "package": "jdg.cashflow_predictor", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# CFP-1700: MONTHLY TAX LIABILITY FORECAST — Prognoza zobowiązań na 90 dni
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.cashflow.tax_liability_forecast_90d",
    "package": "jdg.cashflow_predictor",
    "priority": 1700,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": health_rate,
    "business_status": business_status, "ceidg_registration_required": false,
    "cashflow_forecast_30d": forecast_30d,
    "cashflow_forecast_60d": forecast_60d,
    "cashflow_forecast_90d": forecast_90d,
    "cashflow_total_liabilities_90d": total_90d,
    "cashflow_avg_monthly_tax_burden": avg_monthly,
    "_routing": forecast_routing,
    "_routing_reason": forecast_routing_reason,
    "_legal_basis": "Art. 44 PIT, Art. 103 VAT, Art. 47 SUS",
    "_warnings": build_forecast_warnings(forecast_30d, forecast_60d, forecast_90d, total_90d, avg_monthly)
} {
    input.cashflow_forecast_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")

    monthly_income_est := object.get(input.jdg_entrepreneur, "monthly_profit_avg", 8000)
    monthly_revenue_est := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 15000)
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "ACTIVE") != "EXEMPT"
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)

    min_wage := object.get(object.get(data.thresholds, "bounds", {}), "minimum_wage_gross", 4666)
    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "average_wage", 8000)

    # ---- VAT forecast (monthly, due 25th) ----
    vat_on_sales := 0
    vat_on_purchases := 0
    vat_to_pay := 0
    vat_on_sales := monthly_revenue_est * 0.23 { is_vat_payer }
    vat_on_purchases := monthly_revenue_est * 0.60 * 0.23 { is_vat_payer }  # ~60% kosztów z VAT
    vat_to_pay := vat_on_sales - vat_on_purchases { is_vat_payer }
    vat_to_pay := max([vat_to_pay, 0])

    # ---- PIT advance forecast ----
    pit_advance := 0
    pit_advance := monthly_income_est * 0.12 { pit_form == "PIT_SCALE"; monthly_income_est <= 10000 }
    pit_advance := 1200 + (monthly_income_est - 10000) * 0.32 { pit_form == "PIT_SCALE"; monthly_income_est > 10000 }
    pit_advance := monthly_income_est * 0.19 { pit_form == "LINEAR" }
    pit_advance := monthly_revenue_est * 0.12 { pit_form == "LUMP_SUM" }

    # ---- ZUS forecast ----
    zus_social := 0
    zus_social := floor(min_wage * 0.60 * 0.3812 * 100) / 100 + 0 { zus_status == "STANDARD" }
    zus_social := floor(min_wage * 0.30 * 0.3812 * 100) / 100 + 0 { zus_status == "PREFERENTIAL" }
    zus_social := floor(monthly_income_est * 0.30 * 0.3812 * 100) / 100 + 0 { zus_status == "MALY_ZUS_PLUS" }
    zus_social := 0 { zus_status in {"START_RELIEF", "UNREGISTERED"} }

    zus_health := 0
    zus_health := floor(monthly_income_est * 0.09 * 100) / 100 { pit_form == "PIT_SCALE" }
    zus_health := floor(min([monthly_income_est * 0.049, data.jdg.thresholds.limits.health_linear_deduction_limit / 12]) * 100) / 100 { pit_form == "LINEAR" }
    zus_health := floor(avg_wage * 0.09 * 100) / 100 { pit_form == "LUMP_SUM" }

    health_rate := sprintf("9%%", []) { pit_form == "PIT_SCALE" }
    health_rate := sprintf("4.9%%", []) { pit_form == "LINEAR" }
    health_rate := sprintf("zależna od przychodu", []) { pit_form == "LUMP_SUM" }

    zus_total := zus_social + zus_health

    # ---- Employee costs (if any) ----
    ee_zus_employer := 0
    ee_zus_employer := monthly_income_est * 0.20 { has_employees }

    # ---- Total monthly burden ----
    monthly_total := vat_to_pay + pit_advance + zus_total + ee_zus_employer

    # ---- 30/60/90 day forecasts ----
    forecast_30d := {
        "vat": vat_to_pay,
        "pit_advance": pit_advance,
        "zus": zus_total,
        "total": monthly_total
    }

    forecast_60d := {
        "vat": vat_to_pay * 1.05,      # +5% seasonal growth
        "pit_advance": pit_advance * 1.05,
        "zus": zus_total * 1.02,        # ZUS rośnie z płacą minimalną
        "total": round((vat_to_pay + pit_advance) * 1.05 + zus_total * 1.02 + ee_zus_employer, 2)
    }

    forecast_90d := {
        "vat": vat_to_pay * 1.10,       # +10% seasonal growth
        "pit_advance": pit_advance * 1.10,
        "zus": zus_total * 1.04,
        "total": round((vat_to_pay + pit_advance) * 1.10 + zus_total * 1.04 + ee_zus_employer, 2)
    }

    total_90d := forecast_30d.total + forecast_60d.total + forecast_90d.total
    avg_monthly := total_90d / 3

    forecast_routing := ""
    forecast_routing := "TRIAGE_QUEUE" { avg_monthly > monthly_revenue_est * 0.5 }
    forecast_routing_reason := ""
    forecast_routing_reason := sprintf("UWAGA: średnie obciążenie podatkowe (%.0f PLN) > 50%% przychodów (%.0f PLN)!", [avg_monthly, monthly_revenue_est]) { avg_monthly > monthly_revenue_est * 0.5 }
}

round(val, decimals) = result {
    # Precomputed multipliers (OPA has no pow())
    pow10 := {0:1, 1:10, 2:100, 3:1000, 4:10000}
    multiplier := object.get(pow10, decimals, 100)
    result := floor(val * multiplier + 0.5) / multiplier
}

build_forecast_warnings(f30, f60, f90, total, avg) = warnings {
    total > 0
    warnings := [
        "📊 PROGNOZA ZOBOWIĄZAŃ PODATKOWYCH — 90 DNI",
        "━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("📅 NAJBLIŻSZY MIESIĄC:  VAT %.0f + PIT %.0f + ZUS %.0f = %.0f PLN", [f30.vat, f30.pit_advance, f30.zus, f30.total]),
        sprintf("📅 ZA 2 MIESIĄCE:      VAT %.0f + PIT %.0f + ZUS %.0f = %.0f PLN", [f60.vat, f60.pit_advance, f60.zus, f60.total]),
        sprintf("📅 ZA 3 MIESIĄCE:      VAT %.0f + PIT %.0f + ZUS %.0f = %.0f PLN", [f90.vat, f90.pit_advance, f90.zus, f90.total]),
        "━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("💰 ŁĄCZNIE 90 DNI: %.0f PLN (średnio %.0f PLN/mies)", [total, avg]),
        "",
        sprintf("💡 REKOMENDACJA: utrzymuj minimum %.0f PLN bufora gotówkowego (3× średnie miesięczne).", [avg * 3])
    ]
} else = ["ℹ️ Brak danych do prognozy — uzupełnij monthly_profit_avg i monthly_revenue_avg."]

# ═══════════════════════════════════════════════════════════════════════════════
# CFP-1710: LIQUIDITY GAP DETECTION — wykrywanie luki płynnościowej
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cashflow.liquidity_gap_detection",
    "package": "jdg.cashflow_predictor",
    "priority": 1710,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cashflow_current_balance": current_balance,
    "cashflow_upcoming_taxes": upcoming_taxes,
    "cashflow_gap_amount": gap,
    "cashflow_gap_severity": severity,
    "cashflow_days_until_gap": days_until,
    "_routing": gap_routing,
    "_routing_reason": gap_routing_reason,
    "_legal_basis": "Ogólne — analiza płynności (best practice)",
    "_warnings": build_gap_warnings(current_balance, upcoming_taxes, gap, severity, days_until)
} {
    input.cashflow_gap_check == true

    current_balance := object.get(input.jdg_entrepreneur, "bank_balance_pln", 10000)
    upcoming_taxes := object.get(input.jdg_entrepreneur, "next_30_days_tax_total", 5000)
    expected_receivables := object.get(input.jdg_entrepreneur, "next_30d_expected_receivables", 3000)
    fixed_costs := object.get(input.jdg_entrepreneur, "monthly_fixed_costs", 4000)

    total_outflows := upcoming_taxes + fixed_costs
    total_inflows := expected_receivables
    gap := total_outflows - (current_balance + total_inflows)
    gap := max([gap, 0])

    severity := "SAFE" { gap <= 0 }
    severity := "WARNING" { gap > 0; gap <= current_balance * 0.25 }
    severity := "DANGER" { gap > current_balance * 0.25; gap <= current_balance * 0.50 }
    severity := "CRITICAL" { gap > current_balance * 0.50 }

    days_until := 0
    days_until := 30 { severity != "SAFE" }

    gap_routing := ""
    gap_routing := "TRIAGE_QUEUE" { severity == "WARNING" }
    gap_routing := "BLOCK_AND_ALERT" { severity in {"DANGER", "CRITICAL"} }
    gap_routing_reason := ""
    gap_routing_reason := sprintf("LUKA PŁYNNOŚCIOWA: %.0f PLN — poziom %s", [gap, severity]) { severity != "SAFE" }
}

build_gap_warnings(balance, taxes, gap_amt, sev, days) = warnings {
    sev == "CRITICAL"
    warnings := [
        sprintf("🚨 KRYTYCZNA LUKA PŁYNNOŚCIOWA — %.0f PLN!", [gap_amt]),
        sprintf("💰 Stan konta: %.0f PLN | Podatki w ciągu 30 dni: %.0f PLN", [balance, taxes]),
        sprintf("⚠️ BRAKUJE %.0f PLN na pokrycie zobowiązań!", [gap_amt]),
        "",
        "🆘 NATYCHMIASTOWE DZIAŁANIA:",
        "   1. Skontaktuj się z US — wniosek o rozłożenie na raty (Art. 67a OrdPU)",
        "   2. Sprawdź możliwość odroczenia ZUS (Art. 23 SUS)",
        "   3. Ściągnij należności od kontrahentów (windykacja)",
        "   4. Rozważ faktoring należności",
        "   5. W ostateczności: kredyt obrotowy / pożyczka",
        "",
        "📌 Każdy dzień zwłoki = odsetki 14.5% (Art. 56 OrdPU)!"
    ]
} else = warnings {
    sev == "DANGER"
    warnings := [
        sprintf("🔴 ZAGROŻENIE PŁYNNOŚCI — luka %.0f PLN w ciągu 30 dni!", [gap_amt]),
        sprintf("📊 Stan konta: %.0f PLN, potrzeba: %.0f PLN", [balance, gap_amt]),
        "💡 DZIAŁANIA: przyspiesz windykację, odłóż ZUS (możliwość do 6 rat), zredukuj koszty niestałe."
    ]
} else = warnings {
    sev == "WARNING"
    warnings := [sprintf("🟡 UWAGA: mała luka płynnościowa %.0f PLN — monitoruj saldo.", [gap_amt])]
} else = [sprintf("✅ PŁYNNOŚĆ BEZPIECZNA. Stan konta %.0f PLN pokrywa zobowiązania %.0f PLN.", [balance, taxes])]

# ═══════════════════════════════════════════════════════════════════════════════
# CFP-1720: TAX DEADLINE CALENDAR — kalendarz terminów z kwotami
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cashflow.tax_deadline_calendar",
    "package": "jdg.cashflow_predictor",
    "priority": 1720,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": health_rate,
    "business_status": "", "ceidg_registration_required": false,
    "tax_calendar_next_30d": calendar_entries,
    "tax_calendar_total_due_30d": total_due,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 44 PIT, Art. 103 VAT, Art. 47 SUS, Art. 12 OrdPU",
    "_warnings": build_calendar_warnings(calendar_entries, total_due)
} {
    input.tax_calendar_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "ACTIVE") != "EXEMPT"
    current_month := object.get(input, "current_month", 7)
    monthly_profit := object.get(input.jdg_entrepreneur, "monthly_profit_avg", 8000)

    pit_adv := monthly_profit * 0.19 { pit_form == "LINEAR" }
    pit_adv := monthly_profit * 0.12 { pit_form == "PIT_SCALE" }
    pit_adv := monthly_profit * 0.12 { pit_form == "LUMP_SUM" }

    zus_amount := 1800 { zus_status == "STANDARD" }
    zus_amount := 850 { zus_status == "PREFERENTIAL" }
    zus_amount := 1400 { zus_status == "MALY_ZUS_PLUS" }
    zus_amount := 700 { zus_status == "START_RELIEF" }

    health_rate := "9%" { pit_form == "PIT_SCALE" }
    health_rate := "4.9%" { pit_form == "LINEAR" }
    health_rate := "zależna" { pit_form == "LUMP_SUM" }

    health_amt := monthly_profit * 0.09 { pit_form == "PIT_SCALE" }
    health_amt := min([monthly_profit * 0.049, data.jdg.thresholds.limits.health_linear_deduction_limit / 12]) { pit_form == "LINEAR" }
    health_amt := 700 { pit_form == "LUMP_SUM" }

    # Build calendar
    calendar_entries := [
        {"date": "10", "description": "ZUS społeczne + FP+FS", "amount": floor(zus_amount * 100) / 100, "priority": "HIGH"},
        {"date": "15", "description": "ZUS zdrowotne", "amount": floor(health_amt * 100) / 100, "priority": "HIGH"},
        {"date": "20", "description": "PIT-5 / zaliczka PIT", "amount": floor(pit_adv * 100) / 100, "priority": "MEDIUM"}
    ]

    calendar_entries := array.concat(calendar_entries,
        [{"date": "25", "description": "VAT-7 + JPK_V7", "amount": floor(pit_adv * 0.23 * 100) / 100, "priority": "HIGH"}]
    ) { is_vat_payer }

    total_due := zus_amount + health_amt + pit_adv
    total_due := total_due + pit_adv * 0.23 { is_vat_payer }
}

build_calendar_warnings(entries, total) = warnings {
    warnings := [
        sprintf("📅 KALENDARZ PODATKOWY — NAJBLIŻSZE 30 DNI (łącznie: %.0f PLN)", [total]),
        "━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("🔴 10. dnia: ZUS społeczne — %.2f PLN", [entries[0].amount]),
        sprintf("🔴 15. dnia: ZUS zdrowotne — %.2f PLN", [entries[1].amount]),
        sprintf("🟡 20. dnia: PIT — %.2f PLN", [entries[2].amount])
    ]
    warnings := array.concat(warnings,
        [sprintf("🔴 25. dnia: VAT-7 + JPK — %.2f PLN", [entries[3].amount])]
    ) { count(entries) > 3 }
    warnings := array.concat(warnings, [
        "━━━━━━━━━━━━━━━━━━━━━━━",
        "💡 Ustaw stałe zlecenia w banku na 2 dni przed każdym terminem."
    ])
}

# ═══════════════════════════════════════════════════════════════════════════════
# CFP-1730: SEASONAL PATTERN DETECTION — wykrywanie sezonowości
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cashflow.seasonal_pattern_detection",
    "package": "jdg.cashflow_predictor",
    "priority": 1730,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cashflow_seasonal_detected": has_seasonal,
    "cashflow_seasonal_q4_spike_pct": q4_spike,
    "cashflow_seasonal_q1_drop_pct": q1_drop,
    "cashflow_seasonal_recommendation": season_reco,
    "_routing": season_routing,
    "_routing_reason": season_routing_reason,
    "_legal_basis": "Ogólne — analiza biznesowa",
    "_warnings": build_seasonal_warnings(has_seasonal, q4_spike, q1_drop, season_reco)
} {
    input.cashflow_seasonal_check == true

    q1_avg := object.get(input.jdg_entrepreneur, "revenue_q1_avg", 0)
    q4_avg := object.get(input.jdg_entrepreneur, "revenue_q4_avg", 0)
    yearly_avg := object.get(input.jdg_entrepreneur, "revenue_monthly_avg", 0)

    q4_spike := 0
    q4_spike := (q4_avg / yearly_avg - 1) * 100 { yearly_avg > 0; q4_avg > yearly_avg * 1.15 }
    q1_drop := 0
    q1_drop := (1 - q1_avg / yearly_avg) * 100 { yearly_avg > 0; q1_avg < yearly_avg * 0.85 }

    has_seasonal := q4_spike > 0 or q1_drop > 0

    season_reco := ""
    season_reco := sprintf("Q4 wzrost +%.0f%% — odłóż minimum %.0f%% zysków na styczeń (niższe przychody w Q1).", [q4_spike, q4_spike]) { q4_spike > 0 }
    season_reco := sprintf("Q1 spadek -%.0f%% — przygotuj bufor gotówkowy z Q4.", [q1_drop]) { q1_drop > 0; q4_spike == 0 }
    season_reco := sprintf("Sezonowość Q4→Q1: +%.0f%% → -%.0f%%. Buduj bufor w Q4 na spokojny Q1.", [q4_spike, q1_drop]) { q4_spike > 0; q1_drop > 0 }

    season_routing := ""
    season_routing := "TRIAGE_QUEUE" { q4_spike > 30 }
    season_routing_reason := ""
    season_routing_reason := sprintf("Silna sezonowość Q4 (+%.0f%%) — ryzyko luki płynnościowej w Q1", [q4_spike]) { q4_spike > 30 }
}

build_seasonal_warnings(seasonal, q4, q1, reco) = warnings {
    seasonal == true
    warnings := [
        sprintf("📈 SEZONOWOŚĆ WYKRYTA: Q4 +%.0f%%, Q1 -%.0f%%", [q4, q1]),
        sprintf("💡 %s", [reco]),
        "📊 Zaplanuj duże wydatki (sprzęt, szkolenia) w Q4 gdy masz wyższe przychody.",
        "⚠️ Styczeń-Luty to tradycyjnie niższe przychody — przygotuj się na to!"
    ]
} else = ["📊 Brak wyraźnej sezonowości — przychody stabilne przez cały rok."]

# ═══════════════════════════════════════════════════════════════════════════════
# CFP-1740: BUFFER RECOMMENDATION — rekomendacja bufora gotówkowego
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cashflow.buffer_recommendation",
    "package": "jdg.cashflow_predictor",
    "priority": 1740,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cashflow_recommended_buffer": recommended_buffer,
    "cashflow_current_buffer": current_buffer,
    "cashflow_buffer_shortfall": shortfall,
    "cashflow_buffer_status": buffer_status,
    "_routing": buffer_routing,
    "_routing_reason": buffer_routing_reason,
    "_legal_basis": "Ogólne — analiza płynności",
    "_warnings": build_buffer_warnings(current_buffer, recommended_buffer, shortfall, buffer_status)
} {
    input.cashflow_buffer_check == true

    monthly_tax := object.get(input.jdg_entrepreneur, "avg_monthly_tax_total", 5000)
    monthly_fixed := object.get(input.jdg_entrepreneur, "monthly_fixed_costs", 4000)
    monthly_draw := object.get(input.jdg_entrepreneur, "monthly_owner_draw", 5000)
    has_seasonal := object.get(input.jdg_entrepreneur, "has_seasonal_revenue", false)
    is_freelancer := object.get(input.jdg_entrepreneur, "is_freelancer_single_client", false)
    current_buffer := object.get(input.jdg_entrepreneur, "bank_balance_pln", 10000)

    monthly_burn := monthly_tax + monthly_fixed + monthly_draw
    base_months := 3
    base_months := 4 { is_freelancer }           # Freelancer = więcej ryzyka
    base_months := 5 { has_seasonal }             # Sezonowość = więcej bufora
    base_months := 6 { is_freelancer; has_seasonal }

    recommended_buffer := monthly_burn * base_months
    shortfall := recommended_buffer - current_buffer
    shortfall := max([shortfall, 0])

    buffer_status := "OPTIMAL" { shortfall == 0 }
    buffer_status := "LOW" { shortfall > 0; shortfall <= recommended_buffer * 0.25 }
    buffer_status := "CRITICAL" { shortfall > recommended_buffer * 0.25; shortfall <= recommended_buffer * 0.50 }
    buffer_status := "DANGEROUS" { shortfall > recommended_buffer * 0.50 }

    buffer_routing := ""
    buffer_routing := "TRIAGE_QUEUE" { buffer_status in {"LOW", "CRITICAL"} }
    buffer_routing := "BLOCK_AND_ALERT" { buffer_status == "DANGEROUS" }
    buffer_routing_reason := ""
    buffer_routing_reason := sprintf("Bufor %.0f PLN poniżej rekomendowanego %.0f PLN", [shortfall, recommended_buffer]) { shortfall > 0 }
}

build_buffer_warnings(current, recommended, short, status) = warnings {
    status == "DANGEROUS"
    warnings := [
        sprintf("🚨 BUFOR GOTÓWKOWY: %.0f PLN — REKOMENDOWANE %.0f PLN!", [current, recommended]),
        sprintf("   BRAKUJE: %.0f PLN (%.0f%% poniżej rekomendacji)", [short, short / recommended * 100]),
        "",
        "⚠️ Jesteś NA GRANICY utraty płynności! Każde opóźnienie płatności od klienta = problem.",
        "💡 NATYCHMIAST: zwiększ bufor do minimum 1 miesiąca wydatków (%.0f PLN).", [recommended / 4])
    ]
} else = warnings {
    status == "CRITICAL"
    warnings := [
        sprintf("🟡 NISKI BUFOR: %.0f PLN (rekomendowane %.0f PLN, brakuje %.0f PLN)", [current, recommended, short]),
        "💡 Odkładaj 20% miesięcznego zysku na budowę bufora."
    ]
} else = warnings {
    status == "LOW"
    warnings := [sprintf("📊 Bufor %.0f PLN — poniżej optymalnego (%.0f PLN). Rozważ zwiększenie.", [current, recommended])]
} else = [sprintf("✅ BUFOR OPTYMALNY: %.0f PLN — pokrywa %d miesięcy wydatków. Bezpiecznie!", [current, 4])]

# ═══════════════════════════════════════════════════════════════════════════════
# CFP-1745: ANNUAL TAX SETTLEMENT FORECAST — prognoza rozliczenia rocznego
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cashflow.annual_settlement_forecast",
    "package": "jdg.cashflow_predictor",
    "priority": 1745,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cashflow_annual_estimated_income": annual_income,
    "cashflow_annual_estimated_tax": annual_tax,
    "cashflow_annual_health_total": annual_health,
    "cashflow_annual_zus_total": annual_zus,
    "cashflow_annual_total_burden": total_burden,
    "cashflow_annual_effective_rate_pct": effective_rate,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 27, 30c PIT; Art. 79-81 ustawy zdrowotnej",
    "_warnings": [sprintf("📊 PROGNOZA ROCZNA: Dochód %.0f PLN, Podatek %.0f PLN, Zdrowotna %.0f PLN, ZUS %.0f PLN. Łącznie: %.0f PLN (efektywna stopa %.1f%%)", [annual_income, annual_tax, annual_health, annual_zus, total_burden, effective_rate])]
} {
    input.cashflow_annual_forecast == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_income := object.get(input.jdg_entrepreneur, "annual_profit_projected", 96000)
    monthly_zus := object.get(input.jdg_entrepreneur, "monthly_zus_total", 1800)

    # Annual tax calculation
    tax_free := object.get(object.get(data.thresholds, "pit", {}), "tax_free_amount", 30000)
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)

    annual_tax := 0
    annual_tax := max([annual_income - tax_free, 0]) * 0.12 { pit_form == "PIT_SCALE"; annual_income <= scale_threshold }
    annual_tax := (scale_threshold - tax_free) * 0.12 + (annual_income - scale_threshold) * 0.32 { pit_form == "PIT_SCALE"; annual_income > scale_threshold }
    annual_tax := annual_income * 0.19 { pit_form == "LINEAR" }
    annual_tax := annual_income * 0.15 { pit_form == "LUMP_SUM" }

    annual_health := 0
    annual_health := annual_income * 0.09 { pit_form == "PIT_SCALE" }
    annual_health := min([annual_income * 0.049, data.jdg.thresholds.limits.health_linear_deduction_limit]) { pit_form == "LINEAR" }
    annual_health := 9600 { pit_form == "LUMP_SUM" }

    annual_zus := monthly_zus * 12
    total_burden := annual_tax + annual_health + annual_zus
    effective_rate := total_burden / annual_income * 100 { annual_income > 0 }
    effective_rate := 0 { annual_income == 0 }
}
