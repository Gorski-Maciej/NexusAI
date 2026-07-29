# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise Strategic Business Intelligence
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Strategic Intelligence — Proactive Business Optimization
# description: |
#   ENTERPRISE v4.0 — "Genialnie funkcjonalna" warstwa inteligencji biznesowej.
#   Nie tylko pokrywa przepisy — aktywnie doradza przedsiębiorcy:
#   - Cashflow-aware decision routing (kiedy ZUS przekracza % przychodu)
#   - Tax form optimization suggestions (kiedy zmienić skalę na liniowy/ryczałt)
#   - Proactive deadline calendar with risk scoring
#   - Revenue threshold breach prediction (VAT, ryczałt, Mały ZUS+)
#   - Business lifecycle stage detection (startup → growth → maturity → exit)
#   - Cross-domain optimization (ZUS + PIT + VAT łącznie)
#   - Automatic KSeF readiness scoring
#   - Liquidity risk scoring with cash buffer recommendation
# architecture: Strategic Intelligence Layer (SIL) — reads final_verdict, adds insights
# package: jdg.strategic
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.strategic

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.strategic.no_match",
    "package": "jdg.strategic", "priority": 1500
}

# ═══════════════════════════════════════════════════════════════════════════════
# S100: TAX FORM OPTIMIZATION ENGINE
# ═══════════════════════════════════════════════════════════════════════════════

# ── S100: optimize_tax_form — Kiedy zmienić formę opodatkowania? ──
decide := {
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
    input.jdg_entrepreneur.strategic_analysis_requested == true
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_net", 60000)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs", 20000)
    annual_zus := object.get(input.jdg_entrepreneur, "zus_total_annual", 18000)
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    is_b2b := object.get(input.jdg_entrepreneur, "business_model_b2b", true)
    # Oblicz podatek dla każdej formy
    income_after_costs := max([0, annual_income - annual_costs])
    # Skala: 12% do 120k, 32% powyżej, minus kwota wolna 3600
    scale_tax := income_after_costs * 0.12 { income_after_costs <= 120000 }
    scale_tax := 14400 + (income_after_costs - 120000) * 0.32 { income_after_costs > 120000 }
    scale_tax := max([0, scale_tax - 3600])
    # Liniowy: 19% + odliczenie zdrowotnej do limitu z thresholds
    linear_tax := income_after_costs * 0.19
    linear_health_deduction := min([annual_zus * 0.049, data.thresholds.zus.health_linear_deduction_limit])
    linear_tax_effective := max([0, linear_tax - linear_health_deduction])
    # Ryczałt: % przychodu (nie dochodu!) — różne stawki
    lump_rate := 0.12 { is_b2b }
    lump_rate := 0.085 { not is_b2b }
    lump_tax := annual_income * lump_rate
    # Rekomendacja
    recommendation = "ZMIEŃ NA LINIOWY 19%" { linear_tax_effective < scale_tax; linear_tax_effective < lump_tax; current_form != "LINEAR" }
    recommendation = "ZMIEŃ NA RYCZAŁT" { lump_tax < scale_tax; lump_tax < linear_tax_effective; current_form != "LUMP_SUM" }
    recommendation = "ZMIEŃ NA SKALĘ 12%" { scale_tax < linear_tax_effective; scale_tax < lump_tax; current_form != "PIT_SCALE" }
    recommendation = "POZOSTAŃ NA OBECNEJ FORMIE" { true }
    # Oszczędności
    current_tax = scale_tax { current_form == "PIT_SCALE" }
    current_tax = linear_tax_effective { current_form == "LINEAR" }
    current_tax = lump_tax { current_form == "LUMP_SUM" }
    best_tax := min([scale_tax, linear_tax_effective, lump_tax])
    annual_savings := max([0, current_tax - best_tax])
    confidence_pct = 85 { abs(best_tax - current_tax) > 5000 }
    confidence_pct = 60 { abs(best_tax - current_tax) > 1000; abs(best_tax - current_tax) <= 5000 }
    confidence_pct = 40 { true }
    analysis = sprintf("Skala: %.0f PLN, Liniowy: %.0f PLN, Ryczałt: %.0f PLN podatku rocznie", [scale_tax, linear_tax_effective, lump_tax])
}

# ═══════════════════════════════════════════════════════════════════════════════
# S200: REVENUE THRESHOLD BREACH PREDICTION ENGINE
# ═══════════════════════════════════════════════════════════════════════════════

# ── S200: predict_threshold_breaches — Przewidywanie przekroczeń progów ──
else := {
    "matched": true, "rule_id": "jdg.strategic.threshold_prediction",
    "package": "jdg.strategic", "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_threshold_breaches": breaches,
    "strategic_earliest_breach_days": earliest_breach,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": breach_routing,
    "_routing_reason": sprintf("Przewidywane przekroczenia progów: %d w ciągu %d dni", [breach_count, earliest_breach]),
    "_legal_basis": "Ogólna analiza biznesowa — progi wg odpowiednich ustaw",
    "_warnings": breach_warnings
} {
    input.jdg_entrepreneur.strategic_analysis_requested == true
    ytd_revenue := object.get(input.jdg_entrepreneur, "revenue_ytd", 0)
    monthly_avg := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 10000)
    months_active := object.get(input.jdg_entrepreneur, "months_active_current_year", 6)
    remaining_months := 12 - months_active
    projected_annual := ytd_revenue + (monthly_avg * remaining_months)
    # Progi do monitorowania
    vat_exempt_limit := 200000
    lump_sum_limit_eur := 2000000
    maly_zus_plus_limit := 120000
    scale_threshold := 120000
    breaches := []
    # VAT exemption breach
    breaches_vat := array.concat(breaches, [{
        "threshold": "VAT_EXEMPTION_200K",
        "current": ytd_revenue,
        "projected": projected_annual,
        "limit": vat_exempt_limit,
        "days_to_breach": floor((vat_exempt_limit - ytd_revenue) / max([monthly_avg, 0.01]) * 30),
        "action": "Zarejestruj się jako podatnik VAT czynny (VAT-R) PRZED przekroczeniem limitu!",
        "severity": "CRITICAL"
    }]) { projected_annual > vat_exempt_limit }
    # Mały ZUS Plus breach
    breaches_zus := array.concat(breaches_vat, [{
        "threshold": "MALY_ZUS_PLUS_120K",
        "current": ytd_revenue,
        "projected": projected_annual,
        "limit": maly_zus_plus_limit,
        "days_to_breach": floor((maly_zus_plus_limit - ytd_revenue) / max([monthly_avg, 0.01]) * 30),
        "action": "Przekroczenie 120k = utrata Małego ZUS Plus od stycznia. ZUS wzrośnie ~3×!",
        "severity": "HIGH"
    }]) { projected_annual > maly_zus_plus_limit }
    # PIT scale threshold breach
    breaches_pit := array.concat(breaches_zus, [{
        "threshold": "PIT_32PCT_BRACKET",
        "current": ytd_revenue,
        "projected": projected_annual,
        "limit": scale_threshold,
        "days_to_breach": floor((scale_threshold - ytd_revenue) / max([monthly_avg, 0.01]) * 30),
        "action": "Wejdziesz w 32% próg PIT — rozważ przejście na podatek liniowy 19%!",
        "severity": "MEDIUM"
    }]) { projected_annual > scale_threshold }
    breach_count := count(breaches_pit)
    earliest_breach := 999 { breach_count <= 0 }
    earliest_breach := min([day | b := breaches_pit[_]; day := b.days_to_breach]) { breach_count > 0 }
    breach_routing = "BLOCK_AND_ALERT" { earliest_breach <= 30 }
    breach_routing = "TRIAGE_QUEUE" { earliest_breach > 30; earliest_breach <= 90 }
    breach_routing = "" { earliest_breach > 90 }
    breach_warnings := [sprintf("PRZEWIDYWANE PRZEKROCZENIA PROGÓW — Projekcja roczna: %.0f PLN (obecnie YTD: %.0f PLN).", [projected_annual, ytd_revenue])]
}

# ═══════════════════════════════════════════════════════════════════════════════
# S300: CASHFLOW & LIQUIDITY RISK SCORING
# ═══════════════════════════════════════════════════════════════════════════════

# ── S300: liquidity_risk_score — Scoring ryzyka płynności ──
else := {
    "matched": true, "rule_id": "jdg.strategic.liquidity_risk",
    "package": "jdg.strategic", "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_liquidity_score": risk_score,
    "strategic_cash_buffer_recommended_pln": cash_buffer,
    "strategic_monthly_burn_rate_pln": monthly_burn,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": liquidity_routing,
    "_routing_reason": sprintf("Ryzyko płynności: %s (score %d/100)", [risk_level, risk_score]),
    "_legal_basis": "Ogólna analiza biznesowa",
    "_warnings": [sprintf("ANALIZA PŁYNNOŚCI — Score: %d/100 (%s). Miesięczne obciążenia: ZUS %.0f PLN + PIT %.0f PLN + VAT %.0f PLN + koszty stałe %.0f PLN = %.0f PLN. Przychód miesięczny: %.0f PLN. Bufor: %.0f PLN. %s. Rekomendowana poduszka: %.0f PLN (3 miesiące).", [risk_score, risk_level, monthly_zus, monthly_pit, monthly_vat, monthly_fixed, monthly_burn, monthly_revenue, cash_on_hand, liquidity_action, cash_buffer])]
} {
    input.jdg_entrepreneur.strategic_analysis_requested == true
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 10000)
    monthly_zus := object.get(input.jdg_entrepreneur, "zus_total_monthly", 1800)
    monthly_pit := object.get(input.jdg_entrepreneur, "pit_monthly_advance", 1000)
    monthly_vat := object.get(input.jdg_entrepreneur, "vat_monthly_due", 1500)
    monthly_fixed := object.get(input.jdg_entrepreneur, "monthly_fixed_costs", 3000)
    cash_on_hand := object.get(input.jdg_entrepreneur, "cash_on_hand", 20000)
    monthly_burn := monthly_zus + monthly_pit + monthly_vat + monthly_fixed
    # Risk scoring
    burn_ratio := monthly_burn / max([monthly_revenue, 0.01])
    cash_months := cash_on_hand / max([monthly_burn, 0.01])
    risk_score = 85 { cash_months < 0.5 }
    risk_score = 65 { cash_months >= 0.5; cash_months < 1 }
    risk_score = 45 { cash_months >= 1; cash_months < 3 }
    risk_score = 25 { cash_months >= 3; cash_months < 6 }
    risk_score = 10 { cash_months >= 6 }
    risk_level = "KRYTYCZNE" { risk_score >= 70 }
    risk_level = "WYSOKIE" { risk_score >= 40; risk_score < 70 }
    risk_level = "UMIARKOWANE" { risk_score >= 20; risk_score < 40 }
    risk_level = "NISKIE" { risk_score < 20 }
    cash_buffer := floor(monthly_burn * 3 * 100) / 100
    liquidity_routing = "BLOCK_AND_ALERT" { risk_score >= 70 }
    liquidity_routing = "TRIAGE_QUEUE" { risk_score >= 40; risk_score < 70 }
    liquidity_routing = "" { risk_score < 40 }
    liquidity_action = "PILNE: Gotówka na <2 tygodnie! Natychmiast zredukuj koszty / zwiększ przychody." { cash_months < 0.5 }
    liquidity_action = sprintf("UWAGA: Gotówka na %.1f mies. Poduszka poniżej minimum.", [cash_months]) { cash_months >= 0.5; cash_months < 1 }
    liquidity_action = sprintf("OK: %.1f mies. buforu.", [cash_months]) { cash_months >= 1; cash_months < 3 }
    liquidity_action = sprintf("DOBRZE: %.1f mies. buforu.", [cash_months]) { cash_months >= 3 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S400: BUSINESS LIFECYCLE DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

# ── S400: business_lifecycle_stage — Na jakim etapie jest JDG? ──
else := {
    "matched": true, "rule_id": "jdg.strategic.lifecycle_stage",
    "package": "jdg.strategic", "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_lifecycle": lifecycle,
    "strategic_lifecycle_recommendations": recommendations,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ogólna analiza biznesowa",
    "_warnings": [sprintf("ETAP BIZNESOWY: %s. JDG aktywna od %.0f miesięcy. %s. %s", [lifecycle, months_active, lifecycle_description, lifecycle_actions])]
} {
    input.jdg_entrepreneur.strategic_analysis_requested == true
    months_active := object.get(input.jdg_entrepreneur, "jdg_months_active", 6)
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 0)
    revenue_growth := object.get(input.jdg_entrepreneur, "revenue_growth_rate", 0)
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "START_RELIEF")
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    # Lifecycle detection
    lifecycle = "STARTUP" { months_active <= 6; zus_status == "START_RELIEF" }
    lifecycle = "EARLY_GROWTH" { months_active > 6; months_active <= 24; revenue_growth > 0.10 }
    lifecycle = "GROWTH" { months_active > 24; revenue_growth > 0.05; has_employees }
    lifecycle = "MATURITY" { months_active > 24; revenue_growth <= 0.05; revenue_growth >= -0.05 }
    lifecycle = "DECLINE_OR_PIVOT" { revenue_growth < -0.05; months_active > 12 }
    lifecycle = "STARTUP" { months_active <= 6 }
    # Lifecycle descriptions
    lifecycle_description = "Faza startowa — ulga na start/preferencyjny ZUS. Buduj bazę klientów." { lifecycle == "STARTUP" }
    lifecycle_description = "Wczesny wzrost — rozważ rezygnację z ulg ZUS jeśli przychód stabilny." { lifecycle == "EARLY_GROWTH" }
    lifecycle_description = "Wzrost — zatrudniasz pracowników. Rozważ przejście na liniowy PIT." { lifecycle == "GROWTH" }
    lifecycle_description = "Dojrzałość — stabilne przychody. Optymalizuj koszty stałe." { lifecycle == "MATURITY" }
    lifecycle_description = "Spadek/Pivot — przychody maleją. Rozważ zmianę modelu biznesowego." { lifecycle == "DECLINE_OR_PIVOT" }
    # Recommendations
    recommendations = ["Zarejestruj VAT-R jeśli zbliżasz się do 200k limitu zwolnienia","Rozważ ubezpieczenie chorobowe (dobrowolne)","Załóż ewidencję przebiegu pojazdu dla pełnych odliczeń"] { lifecycle == "STARTUP" }
    recommendations = ["Sprawdź czy podatek liniowy 19% jest korzystniejszy","Monitoruj limit Małego ZUS Plus (120k)","Rozważ PPK dla siebie jako przedsiębiorcy"] { lifecycle == "EARLY_GROWTH" }
    recommendations = ["Rozważ IP Box (5%) jeśli tworzysz IP","Zoptymalizuj formę opodatkowania","Sprawdź ulgę B+R na pracowników"] { lifecycle == "GROWTH" }
    recommendations = ["Audyt kosztów stałych","Rozważ inwestycje w środki trwałe (amortyzacja)","Planuj sukcesję firmy"] { lifecycle == "MATURITY" }
    recommendations = ["Przeanalizuj strukturę kosztów","Rozważ zawieszenie zamiast zamykania","Sprawdź możliwość restrukturyzacji"] { lifecycle == "DECLINE_OR_PIVOT" }
    lifecycle_actions := concat(" | ", [r | r := recommendations[_]])
}

# ═══════════════════════════════════════════════════════════════════════════════
# S500: DEADLINE INTELLIGENCE CALENDAR
# ═══════════════════════════════════════════════════════════════════════════════

# ── S500: upcoming_deadlines — Najbliższe terminy z priorytetem ──
else := {
    "matched": true, "rule_id": "jdg.strategic.upcoming_deadlines",
    "package": "jdg.strategic", "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_next_deadline_days": next_deadline_days,
    "strategic_critical_deadlines": critical_count,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": deadline_routing,
    "_routing_reason": sprintf("Najbliższy termin: %s za %d dni", [next_deadline_name, next_deadline_days]),
    "_legal_basis": "Ogólne terminy wg odpowiednich ustaw",
    "_warnings": deadline_list
} {
    input.jdg_entrepreneur.strategic_analysis_requested == true
    today_day := object.get(input, "evaluation_day", 17)
    # Definicja terminów miesięcznych
    deadlines := [
        {"name": "ZUS DRA + składki (JDG)", "day": 10, "severity": "CRITICAL", "action": "Złóż DRA + opłać składki ZUS"},
        {"name": "ZUS DRA + składki (pracownicy)", "day": 15, "severity": "CRITICAL", "action": "Złóż DRA za pracowników"},
        {"name": "Zaliczka PIT", "day": 20, "severity": "HIGH", "action": "Wpłać zaliczkę PIT do US"},
        {"name": "JPK_VAT + VAT", "day": 25, "severity": "CRITICAL", "action": "Złóż JPK_V7 + zapłać VAT"},
        {"name": "PCC-3 (jeśli dotyczy)", "day": 14, "severity": "MEDIUM", "action": "Złóż PCC-3 jeśli umowa w tym miesiącu"}
    ]
    # Znajdź najbliższy termin
    upcoming := [d | d := deadlines[_]; d.day >= today_day]
    sorted_upcoming := sort([day | d := upcoming; day := d.day])
    next_deadline_days := sorted_upcoming[0] - today_day { count(sorted_upcoming) > 0 }
    next_deadline_days := deadlines[0].day + 30 - today_day { count(sorted_upcoming) <= 0 }
    next_deadline_name := deadlines[0].name
    critical_count := count([d | d := deadlines[_]; d.severity == "CRITICAL"])
    deadline_routing = "BLOCK_AND_ALERT" { next_deadline_days <= 2 }
    deadline_routing = "TRIAGE_QUEUE" { next_deadline_days <= 5; next_deadline_days > 2 }
    deadline_routing = "" { next_deadline_days > 5 }
    deadline_list := [sprintf("TERMINY: ZUS (10.) | PIT (20.) | VAT/JPK (25.). Najbliższy: %s za %d dni. %s", [next_deadline_name, next_deadline_days, urgency])]
    urgency = "PILNE — działaj dziś!" { next_deadline_days <= 2 }
    urgency = "Przygotuj dokumenty" { next_deadline_days > 2; next_deadline_days <= 5 }
    urgency = "Masz czas" { next_deadline_days > 5 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S600: KSeF READINESS SCORING
# ═══════════════════════════════════════════════════════════════════════════════

# ── S600: ksef_readiness — Czy JDG jest gotowa na KSeF? ──
else := {
    "matched": true, "rule_id": "jdg.strategic.ksef_readiness",
    "package": "jdg.strategic", "priority": 600,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_ksef_readiness_score": readiness_score,
    "strategic_ksef_missing_items": missing_items,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": ksef_routing,
    "_routing_reason": sprintf("KSeF readiness: %d/100 — %d braków", [readiness_score, missing_count]),
    "_legal_basis": "Art. 106na-106nq VAT (KSeF obowiązkowy od 01.02.2026)",
    "_warnings": [sprintf("KSeF GOTOWOŚĆ — Score: %d/100. %s. Brakujące elementy: %s. KSeF OBOWIĄZKOWY od 01.02.2026!", [readiness_score, ksef_status, missing_list])]
} {
    input.jdg_entrepreneur.strategic_analysis_requested == true
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
    has_ksef_token := object.get(input.jdg_entrepreneur, "ksef_token_obtained", false)
    has_ksef_software := object.get(input.jdg_entrepreneur, "ksef_software_ready", false)
    invoices_monthly := object.get(input.jdg_entrepreneur, "invoices_monthly_count", 0)
    # Scoring
    readiness_score = 0 { not is_vat_payer }  # Zwolnieni z VAT nie muszą
    readiness_score = 100 { is_vat_payer; has_ksef_token; has_ksef_software }
    readiness_score = 70 { is_vat_payer; has_ksef_token; not has_ksef_software }
    readiness_score = 30 { is_vat_payer; not has_ksef_token; has_ksef_software }
    readiness_score = 0 { is_vat_payer; not has_ksef_token; not has_ksef_software }
    missing_items := []
    missing_token := array.concat(missing_items, ["Token KSeF (przez e-Urząd Skarbowy lub kwalifikowany podpis)"]) { not has_ksef_token; is_vat_payer }
    missing_soft := array.concat(missing_token, ["Oprogramowanie do wystawiania faktur KSeF (API lub darmowa aplikacja MF)"]) { not has_ksef_software; is_vat_payer }
    missing_count := count(missing_soft)
    ksef_routing = "BLOCK_AND_ALERT" { readiness_score < 30; is_vat_payer }
    ksef_routing = "TRIAGE_QUEUE" { readiness_score >= 30; readiness_score < 100; is_vat_payer }
    ksef_routing = "" { readiness_score >= 100; is_vat_payer }
    ksef_status = "GOTOWY" { readiness_score >= 100 }
    ksef_status = "W TRAKCIE" { readiness_score >= 30; readiness_score < 100 }
    ksef_status = "NIE PRZYGOTOWANY" { readiness_score < 30 }
    missing_list := concat(" | ", [m | m := missing_soft[_]])
}

# ═══════════════════════════════════════════════════════════════════════════════
# S700: CROSS-DOMAIN TAX SAVINGS FINDER
# ═══════════════════════════════════════════════════════════════════════════════

# ── S700: find_tax_savings — Znajdź oszczędności podatkowe ──
else := {
    "matched": true, "rule_id": "jdg.strategic.tax_savings_finder",
    "package": "jdg.strategic", "priority": 700,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_savings_opportunities": opportunities_count,
    "strategic_potential_savings_pln": total_savings,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": savings_routing,
    "_routing_reason": sprintf("Znaleziono %d możliwości oszczędności: ~%.0f PLN/rok", [opportunities_count, total_savings]),
    "_legal_basis": "Ogólna analiza — nie stanowi porady podatkowej",
    "_warnings": savings_list
} {
    input.jdg_entrepreneur.strategic_analysis_requested == true
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_net", 80000)
    has_rd := object.get(input.jdg_entrepreneur, "has_rd_activity", false)
    has_ip := object.get(input.jdg_entrepreneur, "has_intellectual_property", false)
    uses_car := object.get(input.jdg_entrepreneur, "vehicle_mileage_log_maintained", false)
    pays_vat := object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
    has_ikze := object.get(input.jdg_entrepreneur, "ikze_contributing", false)
    # Szukaj oszczędności
    opportunities := []
    # Ulga B+R
    opp_rd := array.concat(opportunities, [{"name": "Ulga B+R", "savings": annual_income * 0.05, "action": "Odlicz 100-200%% kosztów kwalifikowanych B+R"}]) { has_rd }
    # IP Box
    opp_ip := array.concat(opp_rd, [{"name": "IP Box 5%", "savings": annual_income * 0.07, "action": "Dochód z IP opodatkowany 5%% zamiast 12/19%%"}]) { has_ip }
    # Ewidencja przebiegu
    opp_mileage := array.concat(opp_ip, [{"name": "Ewidencja przebiegu", "savings": 2400, "action": "Załóż ewidencję — zyskaj VAT 100%% + KUP 100%% od auta"}]) { not uses_car }
    # IKZE
    opp_ikze := array.concat(opp_mileage, [{"name": "IKZE", "savings": 3000, "action": "Wpłać na IKZE — odlicz od dochodu do ~26k PLN rocznie"}]) { not has_ikze }
    opportunities_count := count(opp_ikze)
    total_savings := sum([savings | o := opp_ikze[_]; savings := o.savings])
    savings_routing = "TRIAGE_QUEUE" { total_savings > 5000 }
    savings_routing = "" { true }
    savings_list := [sprintf("ANALIZA OSZCZĘDNOŚCI: %s", [concat(" | ", [sprintf("%s: ~%.0f PLN/rok", [o.name, o.savings]) | o := opp_ikze[_]])])] { opportunities_count > 0 }
    savings_list := ["Nie znaleziono dodatkowych możliwości oszczędności — wszystko zoptymalizowane!"] { opportunities_count <= 0 }
}
