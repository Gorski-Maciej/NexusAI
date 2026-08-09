# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise Strategic Business Intelligence
# ═══════════════════════════════════════════════════════════════════════════════
# Dokumentacja: Strategic Intelligence Layer (SIL) — proactive business optimization.
# Publiczny kontrakt: package jdg.strategic, siedem rule_id S100–S700.
# Warstwa analizuje payload.jdg_entrepreneur i działa fail-closed dla pustego inputu.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.strategic

# ───────────────────────────────────────────────────────────────────────────────
# Wspólne helpery — bez warunkowych przypisań inline (OPA 0.68 compatible)
# ───────────────────────────────────────────────────────────────────────────────

scale_tax_before_free_allowance(income_after_costs) = income_after_costs * 0.12 {
    income_after_costs <= 120000
} else = 14400 + (income_after_costs - 120000) * 0.32 {
    income_after_costs > 120000
}

lump_rate_for(is_b2b) = 0.12 {
    is_b2b
} else = 0.085 {
    not is_b2b
}

current_tax_for(current_form, scale_tax, linear_tax, lump_tax) = scale_tax {
    current_form == "PIT_SCALE"
} else = linear_tax {
    current_form == "LINEAR"
} else = lump_tax {
    current_form == "LUMP_SUM"
}

recommendation_for(current_form, scale_tax, linear_tax, lump_tax) = "ZMIEŃ NA LINIOWY 19%" {
    linear_tax < scale_tax
    linear_tax < lump_tax
    current_form != "LINEAR"
} else = "ZMIEŃ NA RYCZAŁT" {
    lump_tax < scale_tax
    lump_tax < linear_tax
    current_form != "LUMP_SUM"
} else = "ZMIEŃ NA SKALĘ 12%" {
    scale_tax < linear_tax
    scale_tax < lump_tax
    current_form != "PIT_SCALE"
} else = "POZOSTAŃ NA OBECNEJ FORMIE"

confidence_for(delta) = 85 {
    delta > 5000
} else = 60 {
    delta > 1000
    delta <= 5000
} else = 40

append_vat_breach(base, ytd_revenue, projected_annual, monthly_avg, limit) = array.concat(base, [{
    "threshold": "VAT_EXEMPTION_200K",
    "current": ytd_revenue,
    "projected": projected_annual,
    "limit": limit,
    "days_to_breach": floor((limit - ytd_revenue) / max([monthly_avg, 0.01]) * 30),
    "action": "Zarejestruj się jako podatnik VAT czynny (VAT-R) PRZED przekroczeniem limitu!",
    "severity": "CRITICAL"
}]) {
    projected_annual > limit
} else = base

append_zus_breach(base, ytd_revenue, projected_annual, monthly_avg, limit) = array.concat(base, [{
    "threshold": "MALY_ZUS_PLUS_120K",
    "current": ytd_revenue,
    "projected": projected_annual,
    "limit": limit,
    "days_to_breach": floor((limit - ytd_revenue) / max([monthly_avg, 0.01]) * 30),
    "action": "Przekroczenie 120k = utrata Małego ZUS Plus od stycznia. ZUS wzrośnie ~3×!",
    "severity": "HIGH"
}]) {
    projected_annual > limit
} else = base

append_pit_breach(base, ytd_revenue, projected_annual, monthly_avg, limit) = array.concat(base, [{
    "threshold": "PIT_32PCT_BRACKET",
    "current": ytd_revenue,
    "projected": projected_annual,
    "limit": limit,
    "days_to_breach": floor((limit - ytd_revenue) / max([monthly_avg, 0.01]) * 30),
    "action": "Wejdziesz w 32% próg PIT — rozważ przejście na podatek liniowy 19%!",
    "severity": "MEDIUM"
}]) {
    projected_annual > limit
} else = base

earliest_breach_for(breaches) = 999 {
    count(breaches) == 0
} else = min([day | breach := breaches[_]; day := breach.days_to_breach]) {
    count(breaches) > 0
}

breach_routing_for(earliest_breach) = "BLOCK_AND_ALERT" {
    earliest_breach <= 30
} else = "TRIAGE_QUEUE" {
    earliest_breach > 30
    earliest_breach <= 90
} else = "" {
    earliest_breach > 90
}

risk_score_for(cash_months) = 85 {
    cash_months < 0.5
} else = 65 {
    cash_months >= 0.5
    cash_months < 1
} else = 45 {
    cash_months >= 1
    cash_months < 3
} else = 25 {
    cash_months >= 3
    cash_months < 6
} else = 10 {
    cash_months >= 6
}

risk_level_for(risk_score) = "KRYTYCZNE" {
    risk_score >= 70
} else = "WYSOKIE" {
    risk_score >= 40
    risk_score < 70
} else = "UMIARKOWANE" {
    risk_score >= 20
    risk_score < 40
} else = "NISKIE" {
    risk_score < 20
}

liquidity_routing_for(risk_score) = "BLOCK_AND_ALERT" {
    risk_score >= 70
} else = "TRIAGE_QUEUE" {
    risk_score >= 40
    risk_score < 70
} else = "" {
    risk_score < 40
}

liquidity_action_for(cash_months) = "PILNE: Gotówka na <2 tygodnie! Natychmiast zredukuj koszty / zwiększ przychody." {
    cash_months < 0.5
} else = sprintf("UWAGA: Gotówka na %.1f mies. Poduszka poniżej minimum.", [cash_months]) {
    cash_months >= 0.5
    cash_months < 1
} else = sprintf("OK: %.1f mies. buforu.", [cash_months]) {
    cash_months >= 1
    cash_months < 3
} else = sprintf("DOBRZE: %.1f mies. buforu.", [cash_months]) {
    cash_months >= 3
}

lifecycle_for(months_active, revenue_growth, zus_status, has_employees) = "STARTUP" {
    months_active <= 6
    zus_status == "START_RELIEF"
} else = "EARLY_GROWTH" {
    months_active > 6
    months_active <= 24
    revenue_growth > 0.10
} else = "GROWTH" {
    months_active > 24
    revenue_growth > 0.05
    has_employees
} else = "MATURITY" {
    months_active > 24
    revenue_growth <= 0.05
    revenue_growth >= -0.05
} else = "DECLINE_OR_PIVOT" {
    revenue_growth < -0.05
    months_active > 12
} else = "STARTUP" {
    months_active <= 6
} else = "EARLY_GROWTH" {
    months_active <= 24
} else = "MATURITY"

lifecycle_description_for(lifecycle) = "Faza startowa — ulga na start/preferencyjny ZUS. Buduj bazę klientów." {
    lifecycle == "STARTUP"
} else = "Wczesny wzrost — rozważ rezygnację z ulg ZUS jeśli przychód stabilny." {
    lifecycle == "EARLY_GROWTH"
} else = "Wzrost — zatrudniasz pracowników. Rozważ przejście na liniowy PIT." {
    lifecycle == "GROWTH"
} else = "Dojrzałość — stabilne przychody. Optymalizuj koszty stałe." {
    lifecycle == "MATURITY"
} else = "Spadek/Pivot — przychody maleją. Rozważ zmianę modelu biznesowego." {
    lifecycle == "DECLINE_OR_PIVOT"
}

recommendations_for(lifecycle) = [
    "Zarejestruj VAT-R jeśli zbliżasz się do 200k limitu zwolnienia",
    "Rozważ ubezpieczenie chorobowe (dobrowolne)",
    "Załóż ewidencję przebiegu pojazdu dla pełnych odliczeń"
] {
    lifecycle == "STARTUP"
} else = [
    "Sprawdź czy podatek liniowy 19% jest korzystniejszy",
    "Monitoruj limit Małego ZUS Plus (120k)",
    "Rozważ PPK dla siebie jako przedsiębiorcy"
] {
    lifecycle == "EARLY_GROWTH"
} else = [
    "Rozważ IP Box (5%) jeśli tworzysz IP",
    "Zoptymalizuj formę opodatkowania",
    "Sprawdź ulgę B+R na pracowników"
] {
    lifecycle == "GROWTH"
} else = ["Audyt kosztów stałych", "Rozważ inwestycje w środki trwałe (amortyzacja)", "Planuj sukcesję firmy"] {
    lifecycle == "MATURITY"
} else = ["Przeanalizuj strukturę kosztów", "Rozważ zawieszenie zamiast zamykania", "Sprawdź możliwość restrukturyzacji"] {
    lifecycle == "DECLINE_OR_PIVOT"
}

next_deadline_days_for(deadlines, today_day) = days {
    upcoming_days := [day | deadline := deadlines[_]; deadline.day >= today_day; day := deadline.day]
    days := min(upcoming_days) - today_day
} else = deadlines[0].day + 30 - today_day

next_deadline_name_for(deadlines, today_day) = name {
    upcoming := [deadline | deadline := deadlines[_]; deadline.day >= today_day]
    next_day := min([day | deadline := upcoming[_]; day := deadline.day])
    name := [deadline.name | deadline := upcoming[_]; deadline.day == next_day][0]
} else = deadlines[0].name

readiness_score_for(is_vat_payer, has_token, has_software) = 0 {
    not is_vat_payer
} else = 100 {
    is_vat_payer
    has_token
    has_software
} else = 70 {
    is_vat_payer
    has_token
    not has_software
} else = 30 {
    is_vat_payer
    not has_token
    has_software
} else = 0 {
    is_vat_payer
    not has_token
    not has_software
}

missing_ksef_items(is_vat_payer, has_token, has_software) = [] {
    not is_vat_payer
} else = array.concat([], ["Token KSeF (przez e-Urząd Skarbowy lub kwalifikowany podpis)"]) {
    is_vat_payer
    not has_token
    has_software
} else = array.concat(["Token KSeF (przez e-Urząd Skarbowy lub kwalifikowany podpis)"], ["Oprogramowanie do wystawiania faktur KSeF (API lub darmowa aplikacja MF)"]) {
    is_vat_payer
    not has_token
    not has_software
} else = ["Oprogramowanie do wystawiania faktur KSeF (API lub darmowa aplikacja MF)"] {
    is_vat_payer
    has_token
    not has_software
} else = []

ksef_routing_for(readiness_score, is_vat_payer) = "BLOCK_AND_ALERT" {
    is_vat_payer
    readiness_score < 30
} else = "TRIAGE_QUEUE" {
    is_vat_payer
    readiness_score >= 30
    readiness_score < 100
} else = "" {
    is_vat_payer
    readiness_score >= 100
} else = ""

ksef_status_for(readiness_score) = "GOTOWY" {
    readiness_score >= 100
} else = "W TRAKCIE" {
    readiness_score >= 30
    readiness_score < 100
} else = "NIE PRZYGOTOWANY"

deadline_routing_for(days) = "BLOCK_AND_ALERT" {
    days <= 2
} else = "TRIAGE_QUEUE" {
    days > 2
    days <= 5
} else = ""

urgency_for(days) = "PILNE — działaj dziś!" {
    days <= 2
} else = "Przygotuj dokumenty" {
    days > 2
    days <= 5
} else = "Masz czas"

savings_list_for(opportunities) = [sprintf("ANALIZA OSZCZĘDNOŚCI: %s", [concat(" | ", [sprintf("%s: ~%.0f PLN/rok", [opportunity.name, opportunity.savings]) | opportunity := opportunities[_]])])] {
    count(opportunities) > 0
} else = ["Nie znaleziono dodatkowych możliwości oszczędności — wszystko zoptymalizowane!"]

append_rd_opportunity(base, annual_income, has_rd) = array.concat(base, [{"name": "Ulga B+R", "savings": annual_income * 0.05, "action": "Odlicz 100-200%% kosztów kwalifikowanych B+R"}]) {
    has_rd
} else = base

append_ip_opportunity(base, annual_income, has_ip) = array.concat(base, [{"name": "IP Box 5%", "savings": annual_income * 0.07, "action": "Dochód z IP opodatkowany 5%% zamiast 12/19%%"}]) {
    has_ip
} else = base

append_mileage_opportunity(base, uses_car) = array.concat(base, [{"name": "Ewidencja przebiegu", "savings": 2400, "action": "Załóż ewidencję — zyskaj VAT 100%% + KUP 100%% od auta"}]) {
    not uses_car
} else = base

append_ikze_opportunity(base, has_ikze) = array.concat(base, [{"name": "IKZE", "savings": 3000, "action": "Wpłać na IKZE — odlicz od dochodu do ~26k PLN rocznie"}]) {
    not has_ikze
} else = base

savings_routing_for(total_savings) = "TRIAGE_QUEUE" {
    total_savings > 5000
} else = ""

# ───────────────────────────────────────────────────────────────────────────────
# Decision chain. Specific flags make every engine reachable; the generic flag
# keeps the historical S100 behavior when no specialized request is supplied.
# ───────────────────────────────────────────────────────────────────────────────

s100(payload) = {
    "matched": true, "rule_id": "jdg.strategic.tax_form_optimization",
    "package": "jdg.strategic", "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_recommendation": recommendation,
    "strategic_savings_annual_pln": annual_savings,
    "strategic_confidence": confidence_pct,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Optymalizacja podatkowa: %s → oszczędność ~%.0f PLN/rok", [recommendation, annual_savings]),
    "_legal_basis": "Ogólna analiza biznesowa — nie stanowi porady podatkowej",
    "_warnings": [sprintf("STRATEGICZNA ANALIZA FORMY OPODATKOWANIA — Obecnie: %s (dochód roczny ~%.0f PLN, ZUS ~%.0f PLN/rok). %s. Oszczędność: ~%.0f PLN/rok (pewność: %d%%). UWAGA: zmiana formy możliwa tylko od nowego roku! Złóż oświadczenie do 20 lutego.", [current_form, annual_income, annual_zus, analysis, annual_savings, confidence_pct])]
} {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_threshold_requested", false) == false
    object.get(payload.jdg_entrepreneur, "strategic_liquidity_requested", false) == false
    object.get(payload.jdg_entrepreneur, "strategic_lifecycle_requested", false) == false
    object.get(payload.jdg_entrepreneur, "strategic_deadlines_requested", false) == false
    object.get(payload.jdg_entrepreneur, "strategic_ksef_requested", false) == false
    object.get(payload.jdg_entrepreneur, "strategic_savings_requested", false) == false
    current_form := object.get(payload.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_income := object.get(payload.jdg_entrepreneur, "annual_income_net", 60000)
    annual_costs := object.get(payload.jdg_entrepreneur, "annual_costs", 20000)
    annual_zus := object.get(payload.jdg_entrepreneur, "zus_total_annual", 18000)
    is_b2b := object.get(payload.jdg_entrepreneur, "business_model_b2b", true)
    income_after_costs := max([0, annual_income - annual_costs])
    scale_tax := max([0, scale_tax_before_free_allowance(income_after_costs) - 3600])
    linear_tax := income_after_costs * 0.19
    thresholds_zus := object.get(data.thresholds, "zus", {})
    linear_health_deduction := min([annual_zus * 0.049, object.get(thresholds_zus, "health_linear_deduction_limit", 14100)])
    linear_tax_effective := max([0, linear_tax - linear_health_deduction])
    lump_tax := annual_income * lump_rate_for(is_b2b)
    recommendation := recommendation_for(current_form, scale_tax, linear_tax_effective, lump_tax)
    current_tax := current_tax_for(current_form, scale_tax, linear_tax_effective, lump_tax)
    best_tax := min([scale_tax, linear_tax_effective, lump_tax])
    annual_savings := max([0, current_tax - best_tax])
    confidence_pct := confidence_for(abs(best_tax - current_tax))
    analysis := sprintf("Skala: %.0f PLN, Liniowy: %.0f PLN, Ryczałt: %.0f PLN podatku rocznie", [scale_tax, linear_tax_effective, lump_tax])
}

s200(payload) = {
    "matched": true, "rule_id": "jdg.strategic.threshold_prediction",
    "package": "jdg.strategic", "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_threshold_breaches": breaches, "strategic_earliest_breach_days": earliest_breach,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": breach_routing,
    "_routing_reason": sprintf("Przewidywane przekroczenia progów: %d w ciągu %d dni", [breach_count, earliest_breach]),
    "_legal_basis": "Ogólna analiza biznesowa — progi wg odpowiednich ustaw",
    "_warnings": [sprintf("PRZEWIDYWANE PRZEKROCZENIA PROGÓW — Projekcja roczna: %.0f PLN (obecnie YTD: %.0f PLN).", [projected_annual, ytd_revenue])]
} {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_threshold_requested", false) == true
    ytd_revenue := object.get(payload.jdg_entrepreneur, "revenue_ytd", 0)
    monthly_avg := object.get(payload.jdg_entrepreneur, "monthly_revenue_avg", 10000)
    months_active := object.get(payload.jdg_entrepreneur, "months_active_current_year", 6)
    projected_annual := ytd_revenue + (monthly_avg * (12 - months_active))
    breaches_vat := append_vat_breach([], ytd_revenue, projected_annual, monthly_avg, 200000)
    breaches_zus := append_zus_breach(breaches_vat, ytd_revenue, projected_annual, monthly_avg, 120000)
    breaches := append_pit_breach(breaches_zus, ytd_revenue, projected_annual, monthly_avg, 120000)
    breach_count := count(breaches)
    earliest_breach := earliest_breach_for(breaches)
    breach_routing := breach_routing_for(earliest_breach)
}

s300(payload) = {
    "matched": true, "rule_id": "jdg.strategic.liquidity_risk",
    "package": "jdg.strategic", "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_liquidity_score": risk_score, "strategic_cash_buffer_recommended_pln": cash_buffer,
    "strategic_monthly_burn_rate_pln": monthly_burn,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": liquidity_routing,
    "_routing_reason": sprintf("Ryzyko płynności: %s (score %d/100)", [risk_level, risk_score]),
    "_legal_basis": "Ogólna analiza biznesowa",
    "_warnings": [sprintf("ANALIZA PŁYNNOŚCI — Score: %d/100 (%s). Miesięczne obciążenia: ZUS %.0f PLN + PIT %.0f PLN + VAT %.0f PLN + koszty stałe %.0f PLN = %.0f PLN. Przychód miesięczny: %.0f PLN. Gotówka: %.0f PLN. %s. Rekomendowana poduszka: %.0f PLN (3 miesiące).", [risk_score, risk_level, monthly_zus, monthly_pit, monthly_vat, monthly_fixed, monthly_burn, monthly_revenue, cash_on_hand, liquidity_action, cash_buffer])]
} {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_liquidity_requested", false) == true
    monthly_revenue := object.get(payload.jdg_entrepreneur, "monthly_revenue_avg", 10000)
    monthly_zus := object.get(payload.jdg_entrepreneur, "zus_total_monthly", 1800)
    monthly_pit := object.get(payload.jdg_entrepreneur, "pit_monthly_advance", 1000)
    monthly_vat := object.get(payload.jdg_entrepreneur, "vat_monthly_due", 1500)
    monthly_fixed := object.get(payload.jdg_entrepreneur, "monthly_fixed_costs", 3000)
    cash_on_hand := object.get(payload.jdg_entrepreneur, "cash_on_hand", 20000)
    monthly_burn := monthly_zus + monthly_pit + monthly_vat + monthly_fixed
    cash_months := cash_on_hand / max([monthly_burn, 0.01])
    risk_score := risk_score_for(cash_months)
    risk_level := risk_level_for(risk_score)
    cash_buffer := floor(monthly_burn * 3 * 100) / 100
    liquidity_routing := liquidity_routing_for(risk_score)
    liquidity_action := liquidity_action_for(cash_months)
}

s400(payload) = {
    "matched": true, "rule_id": "jdg.strategic.lifecycle_stage",
    "package": "jdg.strategic", "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_lifecycle": lifecycle, "strategic_lifecycle_recommendations": recommendations,
    "business_status": "", "ceidg_registration_required": false, "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ogólna analiza biznesowa",
    "_warnings": [sprintf("ETAP BIZNESOWY: %s. JDG aktywna od %.0f miesięcy. %s. %s", [lifecycle, months_active, lifecycle_description, lifecycle_actions])]
} {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_lifecycle_requested", false) == true
    months_active := object.get(payload.jdg_entrepreneur, "jdg_months_active", 6)
    revenue_growth := object.get(payload.jdg_entrepreneur, "revenue_growth_rate", 0)
    zus_status := object.get(payload.jdg_entrepreneur, "zus_status", "START_RELIEF")
    has_employees := object.get(payload.jdg_entrepreneur, "has_employees", false)
    lifecycle := lifecycle_for(months_active, revenue_growth, zus_status, has_employees)
    lifecycle_description := lifecycle_description_for(lifecycle)
    recommendations := recommendations_for(lifecycle)
    lifecycle_actions := concat(" | ", recommendations)
}

s500(payload) = {
    "matched": true, "rule_id": "jdg.strategic.upcoming_deadlines",
    "package": "jdg.strategic", "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_next_deadline_days": next_deadline_days, "strategic_critical_deadlines": critical_count,
    "business_status": "", "ceidg_registration_required": false, "_routing": deadline_routing,
    "_routing_reason": sprintf("Najbliższy termin: %s za %d dni", [next_deadline_name, next_deadline_days]),
    "_legal_basis": "Ogólne terminy wg odpowiednich ustaw", "_warnings": deadline_list
} {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_deadlines_requested", false) == true
    today_day := object.get(input, "evaluation_day", 17)
    deadlines := [
        {"name": "ZUS DRA + składki (JDG)", "day": 10, "severity": "CRITICAL", "action": "Złóż DRA + opłać składki ZUS"},
        {"name": "ZUS DRA + składki (pracownicy)", "day": 15, "severity": "CRITICAL", "action": "Złóż DRA za pracowników"},
        {"name": "Zaliczka PIT", "day": 20, "severity": "HIGH", "action": "Wpłać zaliczkę PIT do US"},
        {"name": "JPK_VAT + VAT", "day": 25, "severity": "CRITICAL", "action": "Złóż JPK_V7 + zapłać VAT"},
        {"name": "PCC-3 (jeśli dotyczy)", "day": 14, "severity": "MEDIUM", "action": "Złóż PCC-3 jeśli umowa w tym miesiącu"}
    ]
    next_deadline_days := next_deadline_days_for(deadlines, today_day)
    next_deadline_name := next_deadline_name_for(deadlines, today_day)
    critical_count := count([deadline | deadline := deadlines[_]; deadline.severity == "CRITICAL"])
    deadline_routing := deadline_routing_for(next_deadline_days)
    urgency := urgency_for(next_deadline_days)
    deadline_list := [sprintf("TERMINY: ZUS (10.) | PIT (20.) | VAT/JPK (25.). Najbliższy: %s za %d dni. %s", [next_deadline_name, next_deadline_days, urgency])]
}

s600(payload) = {
    "matched": true, "rule_id": "jdg.strategic.ksef_readiness",
    "package": "jdg.strategic", "priority": 600,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_ksef_readiness_score": readiness_score, "strategic_ksef_missing_items": missing_items,
    "business_status": "", "ceidg_registration_required": false, "_routing": ksef_routing,
    "_routing_reason": sprintf("KSeF readiness: %d/100 — %d braków", [readiness_score, missing_count]),
    "_legal_basis": "Art. 106na-106nq VAT (KSeF obowiązkowy od 01.02.2026)",
    "_warnings": [sprintf("KSeF GOTOWOŚĆ — Score: %d/100. %s. Brakujące elementy: %s. KSeF OBOWIĄZKOWY od 01.02.2026!", [readiness_score, ksef_status, missing_list])]
} {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_ksef_requested", false) == true
    is_vat_payer := object.get(payload.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
    has_ksef_token := object.get(payload.jdg_entrepreneur, "ksef_token_obtained", false)
    has_ksef_software := object.get(payload.jdg_entrepreneur, "ksef_software_ready", false)
    readiness_score := readiness_score_for(is_vat_payer, has_ksef_token, has_ksef_software)
    missing_items := missing_ksef_items(is_vat_payer, has_ksef_token, has_ksef_software)
    missing_count := count(missing_items)
    ksef_routing := ksef_routing_for(readiness_score, is_vat_payer)
    ksef_status := ksef_status_for(readiness_score)
    missing_list := concat(" | ", missing_items)
}

s700(payload) = {
    "matched": true, "rule_id": "jdg.strategic.tax_savings_finder",
    "package": "jdg.strategic", "priority": 700,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_savings_opportunities": opportunities_count, "strategic_potential_savings_pln": total_savings,
    "business_status": "", "ceidg_registration_required": false, "_routing": savings_routing,
    "_routing_reason": sprintf("Znaleziono %d możliwości oszczędności: ~%.0f PLN/rok", [opportunities_count, total_savings]),
    "_legal_basis": "Ogólna analiza — nie stanowi porady podatkowej", "_warnings": savings_list
} {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_savings_requested", false) == true
    annual_income := object.get(payload.jdg_entrepreneur, "annual_income_net", 80000)
    has_rd := object.get(payload.jdg_entrepreneur, "has_rd_activity", false)
    has_ip := object.get(payload.jdg_entrepreneur, "has_intellectual_property", false)
    uses_car := object.get(payload.jdg_entrepreneur, "vehicle_mileage_log_maintained", false)
    has_ikze := object.get(payload.jdg_entrepreneur, "ikze_contributing", false)
    opportunities_0 := []
    opportunities_1 := append_rd_opportunity(opportunities_0, annual_income, has_rd)
    opportunities_2 := append_ip_opportunity(opportunities_1, annual_income, has_ip)
    opportunities_3 := append_mileage_opportunity(opportunities_2, uses_car)
    opportunities := append_ikze_opportunity(opportunities_3, has_ikze)
    opportunities_count := count(opportunities)
    total_savings := sum([savings | opportunity := opportunities[_]; savings := opportunity.savings])
    savings_routing := savings_routing_for(total_savings)
    savings_list := savings_list_for(opportunities)
}

strategy_key(payload) = "S100" {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_threshold_requested", false) == false
    object.get(payload.jdg_entrepreneur, "strategic_liquidity_requested", false) == false
    object.get(payload.jdg_entrepreneur, "strategic_lifecycle_requested", false) == false
    object.get(payload.jdg_entrepreneur, "strategic_deadlines_requested", false) == false
    object.get(payload.jdg_entrepreneur, "strategic_ksef_requested", false) == false
    object.get(payload.jdg_entrepreneur, "strategic_savings_requested", false) == false
} else = "S200" {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_threshold_requested", false) == true
} else = "S300" {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_liquidity_requested", false) == true
} else = "S400" {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_lifecycle_requested", false) == true
} else = "S500" {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_deadlines_requested", false) == true
} else = "S600" {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_ksef_requested", false) == true
} else = "S700" {
    payload.jdg_entrepreneur.strategic_analysis_requested == true
    object.get(payload.jdg_entrepreneur, "strategic_savings_requested", false) == true
} else = "NO_MATCH"

decide = s100(input) {
    strategy_key(input) == "S100"
} else = s200(input) {
    strategy_key(input) == "S200"
} else = s300(input) {
    strategy_key(input) == "S300"
} else = s400(input) {
    strategy_key(input) == "S400"
} else = s500(input) {
    strategy_key(input) == "S500"
} else = s600(input) {
    strategy_key(input) == "S600"
} else = s700(input) {
    strategy_key(input) == "S700"
} else = {
    "matched": false,
    "rule_id": "jdg.strategic.no_match",
    "package": "jdg.strategic",
    "priority": 1500
}
