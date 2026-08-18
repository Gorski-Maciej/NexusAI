# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE CASH-FLOW TAX PREDICTOR (Strategic Initiative S8)
# ═══════════════════════════════════════════════════════════════════════════════
# title: JDG Enterprise Cash-Flow Tax Predictor — Liquidity & Deadline Engine
# description: Forecasts VAT/PIT/ZUS, liquidity gaps, deadlines, seasonality and buffers.
# architecture: Enterprise Predictive Engine, ordered first-match decision chain
# legal_basis: Art. 44 PIT, Art. 103 VAT, Art. 47 SUS
# package: jdg.cashflow_predictor
# deprecated: false
# priority_range: 1700-1749
# Public rule IDs: jdg.cashflow.no_match and CFP-1700..1745.
# The decision chain is ordered: forecast, liquidity, calendar, seasonal, buffer, annual.
# ═══════════════════════════════════════════════════════════════════════════════


package jdg.cashflow_predictor

default decide := {
    "matched": false,
    "rule_id": "jdg.cashflow.no_match",
    "package": "jdg.cashflow_predictor",
    "priority": 9999
}

# -----------------------------------------------------------------------------
# Shared value helpers
# -----------------------------------------------------------------------------

bounds() = object.get(data.thresholds, "bounds", {})
limits() = object.get(data.thresholds, "limits", {})
pit_thresholds() = object.get(data.thresholds, "pit", {})
health_limit() = object.get(limits(), "health_linear_deduction_limit", 14100)
minimum_wage() = object.get(bounds(), "minimum_wage_gross", 4800)
average_wage() = object.get(bounds(), "average_wage", 8000)

tax_liability_form(form, income, revenue) = income * 0.12 {
    form == "PIT_SCALE"
    income <= 10000
} else = 1200 + (income - 10000) * 0.32 {
    form == "PIT_SCALE"
    income > 10000
} else = income * 0.19 {
    form == "LINEAR"
} else = revenue * 0.12 {
    form == "LUMP_SUM"
} else = 0

vat_liability(revenue, true) = revenue * 0.23 - revenue * 0.60 * 0.23
vat_liability(_, false) = 0

social_zus(status, income) = floor(minimum_wage() * 0.60 * 0.3812 * 100) / 100 {
    status == "STANDARD"
} else = floor(minimum_wage() * 0.30 * 0.3812 * 100) / 100 {
    status == "PREFERENTIAL"
} else = floor(income * 0.30 * 0.3812 * 100) / 100 {
    status == "MALY_ZUS_PLUS"
} else = 0

health_zus(form, income) = floor(income * 0.09 * 100) / 100 {
    form == "PIT_SCALE"
} else = floor(min([income * 0.049, health_limit() / 12]) * 100) / 100 {
    form == "LINEAR"
} else = floor(average_wage() * 0.09 * 100) / 100 {
    form == "LUMP_SUM"
} else = 0

health_rate_for(form) = "9%" {
    form == "PIT_SCALE"
} else = "4.9%" {
    form == "LINEAR"
} else = "zależna od przychodu" {
    form == "LUMP_SUM"
} else = ""

employee_zus(has_employees, income) = income * 0.20 {
    has_employees
} else = 0

routing_for_forecast(avg, revenue) = "TRIAGE_QUEUE" {
    avg > revenue * 0.5
} else = ""

routing_reason_for_forecast(avg, revenue) = sprintf("UWAGA: średnie obciążenie podatkowe (%.0f PLN) > 50%% przychodów (%.0f PLN)!", [avg, revenue]) {
    avg > revenue * 0.5
} else = ""

round_amount(value, decimals) = floor(value * multiplier(decimals) + 0.5) / multiplier(decimals)

# Backward-compatible alias for callers that used the original helper name.
round(value, decimals) = round_amount(value, decimals)

multiplier(0) = 1
multiplier(1) = 10
multiplier(2) = 100
multiplier(3) = 1000
multiplier(4) = 10000
multiplier(_) = 100

# -----------------------------------------------------------------------------
# CFP-1700 — 30/60/90 day tax liability forecast
# -----------------------------------------------------------------------------

forecast_decision := {
    "matched": true,
    "rule_id": "jdg.cashflow.tax_liability_forecast_90d",
    "package": "jdg.cashflow_predictor",
    "priority": 1700,
    "valid_from": "2026-01-01", "valid_to": null, "decision_mode": "SUGGEST",
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": health_rate,
    "business_status": business_status, "ceidg_registration_required": false,
    "cashflow_forecast_30d": f30,
    "cashflow_forecast_60d": f60,
    "cashflow_forecast_90d": f90,
    "cashflow_total_liabilities_90d": total_90,
    "cashflow_avg_monthly_tax_burden": average_monthly,
    "_routing": routing_for_forecast(average_monthly, revenue),
    "_routing_reason": routing_reason_for_forecast(average_monthly, revenue),
    "_legal_basis": "Art. 44 PIT, Art. 103 VAT, Art. 47 SUS",
    "_warnings": build_forecast_warnings(f30, f60, f90, total_90, average_monthly)
} {
    form := object.get(object.get(input, "jdg_entrepreneur", {}), "tax_form", "PIT_SCALE")
    zus_status := object.get(object.get(input, "jdg_entrepreneur", {}), "zus_status", "STANDARD")
    business_status := object.get(object.get(input, "jdg_entrepreneur", {}), "business_status", "ACTIVE")
    income := object.get(object.get(input, "jdg_entrepreneur", {}), "monthly_profit_avg", 8000)
    revenue := object.get(object.get(input, "jdg_entrepreneur", {}), "monthly_revenue_avg", 15000)
    vat_payer := object.get(object.get(input, "jdg_entrepreneur", {}), "vat_status", "ACTIVE") != "EXEMPT"
    has_employees := object.get(object.get(input, "jdg_entrepreneur", {}), "has_employees", false)
    pit := tax_liability_form(form, income, revenue)
    vat := max([vat_liability(revenue, vat_payer), 0])
    social := social_zus(zus_status, income)
    health := health_zus(form, income)
    zus := social + health
    employee := employee_zus(has_employees, income)
    monthly := vat + pit + zus + employee
    f30 := {"vat": vat, "pit_advance": pit, "zus": zus, "total": monthly}
    f60 := {
        "vat": vat * 1.05,
        "pit_advance": pit * 1.05,
        "zus": zus * 1.02,
        "total": round_amount((vat + pit) * 1.05 + zus * 1.02 + employee, 2)
    }
    f90 := {
        "vat": vat * 1.10,
        "pit_advance": pit * 1.10,
        "zus": zus * 1.04,
        "total": round_amount((vat + pit) * 1.10 + zus * 1.04 + employee, 2)
    }
    total_90 := f30.total + f60.total + f90.total
    average_monthly := total_90 / 3
    health_rate := health_rate_for(form)
    input.cashflow_forecast_requested == true
}

build_forecast_warnings(f30, f60, f90, total, average) = [
    "📊 PROGNOZA ZOBOWIĄZAŃ PODATKOWYCH — 90 DNI",
    "━━━━━━━━━━━━━━━━━━━━━━━",
    sprintf("📅 NAJBLIŻSZY MIESIĄC: VAT %.0f + PIT %.0f + ZUS %.0f = %.0f PLN", [f30.vat, f30.pit_advance, f30.zus, f30.total]),
    sprintf("📅 ZA 2 MIESIĄCE: VAT %.0f + PIT %.0f + ZUS %.0f = %.0f PLN", [f60.vat, f60.pit_advance, f60.zus, f60.total]),
    sprintf("📅 ZA 3 MIESIĄCE: VAT %.0f + PIT %.0f + ZUS %.0f = %.0f PLN", [f90.vat, f90.pit_advance, f90.zus, f90.total]),
    "━━━━━━━━━━━━━━━━━━━━━━━",
    sprintf("💰 ŁĄCZNIE 90 DNI: %.0f PLN (średnio %.0f PLN/mies)", [total, average]),
    "",
    sprintf("💡 REKOMENDACJA: utrzymuj minimum %.0f PLN bufora gotówkowego (3× średnie miesięczne).", [average * 3])
] {
    total > 0
} else = ["ℹ️ Brak danych do prognozy — uzupełnij monthly_profit_avg i monthly_revenue_avg."]

# -----------------------------------------------------------------------------
# CFP-1710 — liquidity gap
# -----------------------------------------------------------------------------

gap_severity(gap, balance) = "SAFE" {
    gap <= 0
} else = "WARNING" {
    gap > 0
    gap <= balance * 0.25
} else = "DANGER" {
    gap > balance * 0.25
    gap <= balance * 0.50
} else = "CRITICAL"

gap_routing(severity) = "TRIAGE_QUEUE" {
    severity == "WARNING"
} else = "BLOCK_AND_ALERT" {
    severity == "DANGER"
} else = "BLOCK_AND_ALERT" {
    severity == "CRITICAL"
} else = ""

gap_reason(gap, severity) = sprintf("LUKA PŁYNNOŚCIOWA: %.0f PLN — poziom %s", [gap, severity]) {
    severity != "SAFE"
} else = ""

days_until_gap(severity) = 30 {
    severity != "SAFE"
} else = 0

gap_decision := {
    "matched": true,
    "rule_id": "jdg.cashflow.liquidity_gap_detection",
    "package": "jdg.cashflow_predictor",
    "priority": 1710,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cashflow_current_balance": balance,
    "cashflow_upcoming_taxes": taxes,
    "cashflow_gap_amount": gap,
    "cashflow_gap_severity": severity,
    "cashflow_days_until_gap": days,
    "_routing": gap_routing(severity),
    "_routing_reason": gap_reason(gap, severity),
    "_legal_basis": "Ogólne — analiza płynności (best practice)",
    "_warnings": build_gap_warnings(balance, taxes, gap, severity)
} {
    balance := object.get(object.get(input, "jdg_entrepreneur", {}), "bank_balance_pln", 10000)
    taxes := object.get(object.get(input, "jdg_entrepreneur", {}), "next_30_days_tax_total", 5000)
    receivables := object.get(object.get(input, "jdg_entrepreneur", {}), "next_30d_expected_receivables", 3000)
    fixed := object.get(object.get(input, "jdg_entrepreneur", {}), "monthly_fixed_costs", 4000)
    gap := max([taxes + fixed - (balance + receivables), 0])
    severity := gap_severity(gap, balance)
    days := days_until_gap(severity)
    input.cashflow_gap_check == true
}

build_gap_warnings(balance, taxes, gap, severity) = [
    sprintf("🚨 KRYTYCZNA LUKA PŁYNNOŚCIOWA — %.0f PLN!", [gap]),
    sprintf("💰 Stan konta: %.0f PLN | Podatki w ciągu 30 dni: %.0f PLN", [balance, taxes]),
    sprintf("⚠️ BRAKUJE %.0f PLN na pokrycie zobowiązań!", [gap]),
    "",
    "🆘 NATYCHMIASTOWE DZIAŁANIA:",
    "   1. Skontaktuj się z US — wniosek o rozłożenie na raty (Art. 67a OrdPU)",
    "   2. Sprawdź możliwość odroczenia ZUS (Art. 23 SUS)",
    "   3. Ściągnij należności od kontrahentów (windykacja)",
    "   4. Rozważ faktoring należności",
    "   5. W ostateczności: kredyt obrotowy / pożyczka",
    "",
    "📌 Każdy dzień zwłoki = odsetki 14.5% (Art. 56 OrdPU)!"
] {
    severity == "CRITICAL"
} else = [
    sprintf("🔴 ZAGROŻENIE PŁYNNOŚCI — luka %.0f PLN w ciągu 30 dni!", [gap]),
    sprintf("📊 Stan konta: %.0f PLN, potrzeba: %.0f PLN", [balance, gap]),
    "💡 DZIAŁANIA: przyspiesz windykację, odłóż ZUS (możliwość do 6 rat), zredukuj koszty niestałe."
] {
    severity == "DANGER"
} else = [sprintf("🟡 UWAGA: mała luka płynnościowa %.0f PLN — monitoruj saldo.", [gap])] {
    severity == "WARNING"
} else = [sprintf("✅ PŁYNNOŚĆ BEZPIECZNA. Stan konta %.0f PLN pokrywa zobowiązania %.0f PLN.", [balance, taxes])]

# -----------------------------------------------------------------------------
# CFP-1720 — tax deadline calendar
# -----------------------------------------------------------------------------

pit_calendar(form, profit) = profit * 0.19 { form == "LINEAR" }
    else = profit * 0.12 { form == "PIT_SCALE" }
    else = profit * 0.12 { form == "LUMP_SUM" }
    else = 0

zus_calendar(status) = 1800 { status == "STANDARD" }
    else = 850 { status == "PREFERENTIAL" }
    else = 1400 { status == "MALY_ZUS_PLUS" }
    else = 700 { status == "START_RELIEF" }
    else = 0

health_calendar(form, profit) = profit * 0.09 { form == "PIT_SCALE" }
    else = min([profit * 0.049, health_limit() / 12]) { form == "LINEAR" }
    else = 700 { form == "LUMP_SUM" }
    else = 0

calendar_entries(vat_payer, zus, health, pit) = [
    {"date": "10", "description": "ZUS społeczne + FP+FS", "amount": floor(zus * 100) / 100, "priority": "HIGH"},
    {"date": "15", "description": "ZUS zdrowotne", "amount": floor(health * 100) / 100, "priority": "HIGH"},
    {"date": "20", "description": "PIT-5 / zaliczka PIT", "amount": floor(pit * 100) / 100, "priority": "MEDIUM"}
] {
    not vat_payer
} else = array.concat([
    {"date": "10", "description": "ZUS społeczne + FP+FS", "amount": floor(zus * 100) / 100, "priority": "HIGH"},
    {"date": "15", "description": "ZUS zdrowotne", "amount": floor(health * 100) / 100, "priority": "HIGH"},
    {"date": "20", "description": "PIT-5 / zaliczka PIT", "amount": floor(pit * 100) / 100, "priority": "MEDIUM"}
], [{"date": "25", "description": "VAT-7 + JPK_V7", "amount": floor(pit * 0.23 * 100) / 100, "priority": "HIGH"}])

calendar_total(vat_payer, zus, health, pit) = zus + health + pit + pit * 0.23 {
    vat_payer
} else = zus + health + pit

calendar_decision := {
    "matched": true,
    "rule_id": "jdg.cashflow.tax_deadline_calendar",
    "package": "jdg.cashflow_predictor",
    "priority": 1720,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": health_rate_for(form),
    "business_status": "", "ceidg_registration_required": false,
    "tax_calendar_next_30d": entries,
    "tax_calendar_total_due_30d": total,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 44 PIT, Art. 103 VAT, Art. 47 SUS, Art. 12 OrdPU",
    "_warnings": build_calendar_warnings(entries, total)
} {
    form := object.get(object.get(input, "jdg_entrepreneur", {}), "tax_form", "PIT_SCALE")
    zus_status := object.get(object.get(input, "jdg_entrepreneur", {}), "zus_status", "STANDARD")
    vat_payer := object.get(object.get(input, "jdg_entrepreneur", {}), "vat_status", "ACTIVE") != "EXEMPT"
    profit := object.get(object.get(input, "jdg_entrepreneur", {}), "monthly_profit_avg", 8000)
    pit := pit_calendar(form, profit)
    zus := zus_calendar(zus_status)
    health := health_calendar(form, profit)
    entries := calendar_entries(vat_payer, zus, health, pit)
    total := calendar_total(vat_payer, zus, health, pit)
    input.tax_calendar_requested == true
}

calendar_warning_base(entries, total) = [
    sprintf("📅 KALENDARZ PODATKOWY — NAJBLIŻSZE 30 DNI (łącznie: %.0f PLN)", [total]),
    "━━━━━━━━━━━━━━━━━━━━━━━",
    sprintf("🔴 10. dnia: ZUS społeczne — %.2f PLN", [entries[0].amount]),
    sprintf("🔴 15. dnia: ZUS zdrowotne — %.2f PLN", [entries[1].amount]),
    sprintf("🟡 20. dnia: PIT — %.2f PLN", [entries[2].amount])
]

build_calendar_warnings(entries, total) = array.concat(calendar_warning_base(entries, total), [
    sprintf("🔴 25. dnia: VAT-7 + JPK — %.2f PLN", [entries[3].amount]),
    "━━━━━━━━━━━━━━━━━━━━━━━",
    "💡 Ustaw stałe zlecenia w banku na 2 dni przed każdym terminem."
]) {
    count(entries) > 3
} else = array.concat(calendar_warning_base(entries, total), [
    "━━━━━━━━━━━━━━━━━━━━━━━",
    "💡 Ustaw stałe zlecenia w banku na 2 dni przed każdym terminem."
])

# -----------------------------------------------------------------------------
# CFP-1730 — seasonal pattern detection
# -----------------------------------------------------------------------------

q4_spike(q4_avg, yearly_avg) = (q4_avg / yearly_avg - 1) * 100 {
    yearly_avg > 0
    q4_avg > yearly_avg * 1.15
} else = 0

q1_drop(q1_avg, yearly_avg) = (1 - q1_avg / yearly_avg) * 100 {
    yearly_avg > 0
    q1_avg < yearly_avg * 0.85
} else = 0

seasonal_detected(q4, q1) = true {
    q4 > 0
} else = true {
    q1 > 0
} else = false

season_recommendation(q4, q1) = sprintf("Sezonowość Q4→Q1: +%.0f%% → -%.0f%%. Buduj bufor w Q4 na spokojny Q1.", [q4, q1]) {
    q4 > 0
    q1 > 0
} else = sprintf("Q4 wzrost +%.0f%% — odłóż minimum %.0f%% zysków na styczeń (niższe przychody w Q1).", [q4, q4]) {
    q4 > 0
} else = sprintf("Q1 spadek -%.0f%% — przygotuj bufor gotówkowy z Q4.", [q1]) {
    q1 > 0
} else = ""

season_routing(q4) = "TRIAGE_QUEUE" {
    q4 > 30
} else = ""

season_reason(q4) = sprintf("Silna sezonowość Q4 (+%.0f%%) — ryzyko luki płynnościowej w Q1", [q4]) {
    q4 > 30
} else = ""

seasonal_decision := {
    "matched": true,
    "rule_id": "jdg.cashflow.seasonal_pattern_detection",
    "package": "jdg.cashflow_predictor",
    "priority": 1730,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cashflow_seasonal_detected": seasonal,
    "cashflow_seasonal_q4_spike_pct": q4,
    "cashflow_seasonal_q1_drop_pct": q1,
    "cashflow_seasonal_recommendation": season_recommendation(q4, q1),
    "_routing": season_routing(q4),
    "_routing_reason": season_reason(q4),
    "_legal_basis": "Ogólne — analiza biznesowa",
    "_warnings": build_seasonal_warnings(seasonal, q4, q1, season_recommendation(q4, q1))
} {
    q1_avg := object.get(object.get(input, "jdg_entrepreneur", {}), "revenue_q1_avg", 0)
    q4_avg := object.get(object.get(input, "jdg_entrepreneur", {}), "revenue_q4_avg", 0)
    yearly_avg := object.get(object.get(input, "jdg_entrepreneur", {}), "revenue_monthly_avg", 0)
    q4 := q4_spike(q4_avg, yearly_avg)
    q1 := q1_drop(q1_avg, yearly_avg)
    seasonal := seasonal_detected(q4, q1)
    input.cashflow_seasonal_check == true
}

build_seasonal_warnings(seasonal, q4, q1, recommendation) = [
    sprintf("📈 SEZONOWOŚĆ WYKRYTA: Q4 +%.0f%%, Q1 -%.0f%%", [q4, q1]),
    sprintf("💡 %s", [recommendation]),
    "📊 Zaplanuj duże wydatki (sprzęt, szkolenia) w Q4 gdy masz wyższe przychody.",
    "⚠️ Styczeń-Luty to tradycyjnie niższe przychody — przygotuj się na to!"
] {
    seasonal
} else = ["📊 Brak wyraźnej sezonowości — przychody stabilne przez cały rok."]

# -----------------------------------------------------------------------------
# CFP-1740 — buffer recommendation
# -----------------------------------------------------------------------------

base_months_for(freelancer, seasonal) = 6 {
    freelancer
    seasonal
} else = 4 {
    freelancer
} else = 5 {
    seasonal
} else = 3

buffer_status_for(shortfall, recommended) = "OPTIMAL" {
    shortfall == 0
} else = "LOW" {
    shortfall <= recommended * 0.25
} else = "CRITICAL" {
    shortfall <= recommended * 0.50
} else = "DANGEROUS"

buffer_routing_for(status) = "TRIAGE_QUEUE" {
    status == "LOW"
} else = "TRIAGE_QUEUE" {
    status == "CRITICAL"
} else = "BLOCK_AND_ALERT" {
    status == "DANGEROUS"
} else = ""

buffer_reason(shortfall, recommended) = sprintf("Bufor %.0f PLN poniżej rekomendowanego %.0f PLN", [shortfall, recommended]) {
    shortfall > 0
} else = ""

buffer_decision := {
    "matched": true,
    "rule_id": "jdg.cashflow.buffer_recommendation",
    "package": "jdg.cashflow_predictor",
    "priority": 1740,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cashflow_recommended_buffer": recommended,
    "cashflow_current_buffer": current,
    "cashflow_buffer_shortfall": shortfall,
    "cashflow_buffer_status": status,
    "_routing": buffer_routing_for(status),
    "_routing_reason": buffer_reason(shortfall, recommended),
    "_legal_basis": "Ogólne — analiza płynności",
    "_warnings": build_buffer_warnings(current, recommended, shortfall, status)
} {
    tax := object.get(object.get(input, "jdg_entrepreneur", {}), "avg_monthly_tax_total", 5000)
    fixed := object.get(object.get(input, "jdg_entrepreneur", {}), "monthly_fixed_costs", 4000)
    draw := object.get(object.get(input, "jdg_entrepreneur", {}), "monthly_owner_draw", 5000)
    seasonal := object.get(object.get(input, "jdg_entrepreneur", {}), "has_seasonal_revenue", false)
    freelancer := object.get(object.get(input, "jdg_entrepreneur", {}), "is_freelancer_single_client", false)
    current := object.get(object.get(input, "jdg_entrepreneur", {}), "bank_balance_pln", 10000)
    burn := tax + fixed + draw
    months := base_months_for(freelancer, seasonal)
    recommended := burn * months
    shortfall := max([recommended - current, 0])
    status := buffer_status_for(shortfall, recommended)
    input.cashflow_buffer_check == true
}

build_buffer_warnings(current, recommended, shortfall, status) = [
    sprintf("🚨 BUFOR GOTÓWKOWY: %.0f PLN — REKOMENDOWANE %.0f PLN!", [current, recommended]),
    sprintf("   BRAKUJE: %.0f PLN (%.0f%% poniżej rekomendacji)", [shortfall, shortfall / max([recommended, 1]) * 100]),
    "",
    "⚠️ Jesteś NA GRANICY utraty płynności! Każde opóźnienie płatności od klienta = problem.",
    sprintf("💡 NATYCHMIAST: zwiększ bufor do minimum 1 miesiąca wydatków (%.0f PLN).", [recommended / 4])
] {
    status == "DANGEROUS"
} else = [
    sprintf("🟡 NISKI BUFOR: %.0f PLN (rekomendowane %.0f PLN, brakuje %.0f PLN)", [current, recommended, shortfall]),
    "💡 Odkładaj 20% miesięcznego zysku na budowę bufora."
] {
    status == "CRITICAL"
} else = [sprintf("📊 Bufor %.0f PLN — poniżej optymalnego (%.0f PLN). Rozważ zwiększenie.", [current, recommended])] {
    status == "LOW"
} else = [sprintf("✅ BUFOR OPTYMALNY: %.0f PLN — pokrywa 3 miesiące wydatków. Bezpiecznie!", [current])]

# -----------------------------------------------------------------------------
# CFP-1745 — annual settlement forecast
# -----------------------------------------------------------------------------

annual_tax_for(form, income) = max([income - object.get(pit_thresholds(), "tax_free_amount", 30000), 0]) * 0.12 {
    form == "PIT_SCALE"
    income <= object.get(pit_thresholds(), "scale_threshold", 120000)
} else = (object.get(pit_thresholds(), "scale_threshold", 120000) - object.get(pit_thresholds(), "tax_free_amount", 30000)) * 0.12 + (income - object.get(pit_thresholds(), "scale_threshold", 120000)) * 0.32 {
    form == "PIT_SCALE"
    income > object.get(pit_thresholds(), "scale_threshold", 120000)
} else = income * 0.19 {
    form == "LINEAR"
} else = income * 0.15 {
    form == "LUMP_SUM"
} else = 0

annual_health_for(form, income) = income * 0.09 {
    form == "PIT_SCALE"
} else = min([income * 0.049, health_limit()]) {
    form == "LINEAR"
} else = 9600 {
    form == "LUMP_SUM"
} else = 0

annual_decision := {
    "matched": true,
    "rule_id": "jdg.cashflow.annual_settlement_forecast",
    "package": "jdg.cashflow_predictor",
    "priority": 1745,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "cashflow_annual_estimated_income": income,
    "cashflow_annual_estimated_tax": tax,
    "cashflow_annual_health_total": health,
    "cashflow_annual_zus_total": zus,
    "cashflow_annual_total_burden": burden,
    "cashflow_annual_effective_rate_pct": rate,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 27, 30c PIT; Art. 79-81 ustawy zdrowotnej",
    "_warnings": [sprintf("📊 PROGNOZA ROCZNA: Dochód %.0f PLN, Podatek %.0f PLN, Zdrowotna %.0f PLN, ZUS %.0f PLN. Łącznie: %.0f PLN (efektywna stopa %.1f%%)", [income, tax, health, zus, burden, rate])]
} {
    form := object.get(object.get(input, "jdg_entrepreneur", {}), "tax_form", "PIT_SCALE")
    income := object.get(object.get(input, "jdg_entrepreneur", {}), "annual_profit_projected", 96000)
    monthly_zus := object.get(object.get(input, "jdg_entrepreneur", {}), "monthly_zus_total", 1800)
    tax := annual_tax_for(form, income)
    health := annual_health_for(form, income)
    zus := monthly_zus * 12
    burden := tax + health + zus
    rate := effective_rate(burden, income)
    input.cashflow_annual_forecast == true
}

effective_rate(burden, income) = burden / income * 100 {
    income > 0
} else = 0

# -----------------------------------------------------------------------------
# Ordered decision dispatcher
# -----------------------------------------------------------------------------

decide := forecast_decision {
    input.cashflow_forecast_requested == true
} else := gap_decision {
    input.cashflow_gap_check == true
} else := calendar_decision {
    input.tax_calendar_requested == true
} else := seasonal_decision {
    input.cashflow_seasonal_check == true
} else := buffer_decision {
    input.cashflow_buffer_check == true
} else := annual_decision {
    input.cashflow_annual_forecast == true
}
