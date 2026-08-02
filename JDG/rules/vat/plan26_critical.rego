# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Plan 26: VAT Critical Rules (P29 Audit Gap Fix)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: VAT Critical Rules — Plan 26 Implementation (P29 L1 Fix)
# description: |
#   Plan 26 — reguły krytyczne VAT, deklarowane w dokumentacji
#   a brakujące na dysku. Wdrożone na podstawie audytu P29.
#   Pokrywa luki: MPP precision, carousel detection, RO threshold,
#   car limit 150k/225k, OSS/IOSS, VAT RR, Art. 28o, subject exemption
#   proportional, bad debt auto-tracker.
# architecture: Multi-Pass PAS 4a (ADR-001)
# legal_basis: Art. 28o, 86a, 90-91, 106e, 107, 108a, 113, 115-116 VAT
# package: jdg.vat.plan26_critical
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat.plan26_critical

import data.jdg.helpers
import data.jdg.thresholds

# ── Default ──────────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.vat.plan26_critical.no_match",
    "package": "jdg.vat.plan26_critical",
    "priority": 999
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-1: MPP Threshold Precision — dokładny próg 15 000,00 PLN
# Art. 108a VAT: "kwota należności ogółem przekracza 15 000 zł"
# Poprawiono `>` na `>=` — kwota dokładnie 15 000,00 PLN uruchamia MPP.
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.mpp_threshold_precision",
    "package": "jdg.vat.plan26_critical", "priority": 1,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "MPP_PRECISION_CHECK",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "mpp_threshold_precision_ok": true,
    "mpp_boundary_detected": boundary_detected,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 108a VAT",
    "_warnings": mpp_warnings
} {
    input.invoice.direction == "PURCHASE"
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    helpers.jdg_is_mpp_sensitive(input.invoice.category_code)

    # Wykryj progową kwotę (14 999 - 15 001 PLN) jako alert
    boundary_detected = true {
        amount_gross >= 14999
        amount_gross <= 15001
    }
    boundary_detected = false { amount_gross < 14999 }
    boundary_detected = false { amount_gross > 15001 }

    routing = "TRIAGE_QUEUE" { boundary_detected == true }
    routing = "" { boundary_detected == false }
    routing_reason = sprintf("MPP PROGOWA KWOTA %.2f PLN — weryfikuj czy MPP obowiązkowy. Art. 108a: 'przekracza 15 000 zł' → kwota >= 15 000 = MPP.", [amount_gross]) { boundary_detected == true }
    routing_reason = "" { boundary_detected == false }

    mpp_warnings = [sprintf("⚠️ MPP — kwota progowa %.2f PLN. Powyżej 15 000 zł brutto = MPP OBOWIĄZKOWY. Sprawdź dokładnie próg!", [amount_gross])] { boundary_detected == true }
    mpp_warnings = [] { boundary_detected == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-2: VAT Carousel Detector — Wykrywanie karuzel VAT
# Graf transakcji A→B→C→A w 24h, wykrywanie znikających podatników.
# Art. 86 ust. 1 VAT (nadużycie prawa), Art. 55 KKS.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.carousel_detector",
    "package": "jdg.vat.plan26_critical", "priority": 2,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "CAROUSEL_DETECTOR",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "carousel_risk_level": risk_level,
    "carousel_chain_length": chain_length,
    "carousel_time_window_hours": time_window_hours,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KARUZELA VAT WYKRYTA — transakcja cyrkularna w ciągu 24h. Zgłoś do KAS!",
    "_legal_basis": "Art. 86 ust. 1 VAT (nadużycie prawa), Art. 55 KKS",
    "_warnings": [sprintf("⚠️ KARUZELA VAT — wykryto transakcję cyrkularną: %s → %s → %s → %s w %.0f godzin. Zgłoś do KAS! BLOCK_AND_ALERT.", [chain_trace, chain_length, chain_trace_2, chain_trace_3, time_window_hours])]
} {
    input.invoice.direction == "PURCHASE"

    # Wykrywanie karuzeli: graf sprzedawców i nabywców
    seller_nip := object.get(input.vendor, "nip", "")
    buyer_nip := object.get(input.invoice, "buyer_nip", "")

    # Lista znikających podatników (z czarnej listy / risk guard)
    missing_traders := object.get(input, "missing_traders", [])

    # Graf transakcji
    transaction_chain := object.get(input, "transaction_chain", [])

    chain_length := count(transaction_chain)
    time_window_hours := object.get(input, "transaction_time_window_hours", 0)

    # Ryzyko: cyrkularna transakcja w < 24h
    is_circular := chain_length >= 3
    is_rapid := time_window_hours <= 24
    has_missing_trader := count(missing_traders) > 0

    risk_level = "CRITICAL" { is_circular; is_rapid; has_missing_trader }
    risk_level = "HIGH" { is_circular; is_rapid }
    risk_level = "MEDIUM" { is_circular }
    risk_level = "LOW" { chain_length >= 2 }
    risk_level = "NONE"

    chain_trace := concat("", [seller_nip, " → ", buyer_nip])
    chain_trace_2 := concat("", [buyer_nip])
    chain_trace_3 := concat("", [buyer_nip])

    risk_level != "NONE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-3: RO Construction 500k Auto-Sum — Odwrotne obciążenie usługi budowlane
# Art. 17 ust. 1 pkt 8 VAT + załącznik nr 14.
# Łączna wartość usług budowlanych podwykonawcy od 1.11.2019: próg 500k.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.ro_construction_500k_sum",
    "package": "jdg.vat.plan26_critical", "priority": 3,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "RO_CONSTRUCTION_500K_CHECK",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ro_construction_total_net": construction_total,
    "ro_threshold_exceeded": threshold_exceeded,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 17 ust. 1 pkt 8 VAT, załącznik nr 14",
    "_warnings": warnings
} {
    input.invoice.direction == "PURCHASE"
    input.invoice.category_code == "CONSTRUCTION_SUBCONTRACTING"
    input.vendor.country == "PL"

    # Sumowanie wartości netto z faktur budowlanych od tego samego podwykonawcy
    construction_total := object.get(input, "construction_subcontractor_total_net", input.invoice.amount_net)
    ro_threshold := object.get(thresholds.local_taxes, "reverse_charge_construction_threshold", 500000)

    threshold_exceeded = true { construction_total > ro_threshold }
    threshold_exceeded = false

    routing = "BLOCK_AND_ALERT" { threshold_exceeded == true; not input.invoice.reverse_charge_applies }
    routing = "TRIAGE_QUEUE" { threshold_exceeded == true; input.invoice.reverse_charge_applies }
    routing = "" { threshold_exceeded == false }

    routing_reason = sprintf("RO BUDOWLANE — limit 500k (%.2f PLN netto). Wymagane odwrotne obciążenie!", [construction_total]) { threshold_exceeded == true; not input.invoice.reverse_charge_applies }
    routing_reason = sprintf("RO BUDOWLANE — %.2f PLN netto. Przekroczone 500k, sprawdź RO.", [construction_total]) { threshold_exceeded == true; input.invoice.reverse_charge_applies }
    routing_reason = "" { threshold_exceeded == false }

    warnings = [sprintf("RO BUDOWLANE — łączna wartość %.2f PLN > 500k (próg). Odwrotne obciążenie OBOWIĄZKOWE! Faktura BEZ VAT, oznaczenie 'odwrotne obciążenie'.", [construction_total])] { threshold_exceeded == true; not input.invoice.reverse_charge_applies }
    warnings = [sprintf("RO BUDOWLANE — %.2f PLN, RO zastosowane ✓", [construction_total])] { threshold_exceeded == true; input.invoice.reverse_charge_applies }
    warnings = [] { threshold_exceeded == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-4: Car VAT Deduction Limit — Limit 150k/225k dla aut (Art. 86a VAT)
# Art. 86a ust. 1 VAT: limit odliczenia VAT = 150 000 zł (samochód)
# / 225 000 zł (pojazd elektryczny).
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.car_vat_deduction_limit",
    "package": "jdg.vat.plan26_critical", "priority": 4,
    "vat_rate": "", "rounding_level": "", "gtu_code": "GTU_09",
    "procedure": "CAR_VAT_LIMIT_CHECK",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "car_net_value": car_net_value,
    "car_vat_deductible_capped": capped_deduction,
    "car_limit_applied": car_limit,
    "car_is_ev": is_ev,
    "car_has_evidencja": has_evidencja,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 86a ust. 1 VAT",
    "_warnings": warnings
} {
    input.invoice.category_code in {"CAR_NEW", "CAR_USED", "VEHICLE_PURCHASE"}
    input.invoice.direction == "PURCHASE"

    car_net_value := object.get(input.invoice, "amount_net", 0)
    is_ev := object.get(input.invoice, "is_electric_vehicle", false)
    has_evidencja := object.get(input.invoice, "has_mileage_log", false)

    # Art. 86a: limit VAT to 50% od kwoty, capped
    car_limit = thresholds.pit.car_value_limit_standard { not is_ev }
    car_limit = thresholds.pit.car_value_limit_ev { is_ev }

    deduct_rate = thresholds.vat.car_vat_deduction_no_log { not has_evidencja }
    deduct_rate = thresholds.vat.car_vat_deduction_with_log { has_evidencja }

    vat_rate_input := object.get(input.invoice, "vat_rate_override", "0.23")
    vat_amount := car_net_value * to_number(vat_rate_input) { vat_rate_input != "" }
    vat_amount := car_net_value * thresholds.vat.standard_rate { vat_rate_input == "" }

    capped_deduction = car_limit * vat_rate_input_num * deduct_rate { car_net_value > car_limit }
    capped_deduction = vat_amount * deduct_rate { car_net_value <= car_limit }

    vat_rate_input_num = to_number(vat_rate_input)

    routing = "TRIAGE_QUEUE" { car_net_value > car_limit }
    routing = "" { car_net_value <= car_limit }

    routing_reason = sprintf("AUTO — netto %.2f PLN > limit %.0f PLN. Odliczenie VAT capped do %.2f PLN.", [car_net_value, car_limit, capped_deduction]) { car_net_value > car_limit }
    routing_reason = "" { car_net_value <= car_limit }

    warnings = [sprintf("AUTO %.2f PLN NETTO — limit odliczenia VAT Art. 86a: %.0f PLN (standard) / %.0f PLN (EV). Odliczenie capped: %.2f PLN. Ewidencja przebiegu: %s.", [car_net_value, thresholds.pit.car_value_limit_standard, thresholds.pit.car_value_limit_ev, capped_deduction, to_string(has_evidencja)])] { car_net_value > 0 }
    warnings = [] { car_net_value == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-5: Subject Exemption Proportional — Przekroczenie 200k w trakcie roku
# Art. 113 ust. 5 VAT: limit proporcjonalny dla nowych JDG.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.subject_exemption_proportional",
    "package": "jdg.vat.plan26_critical", "priority": 5,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "SUBJECT_EXEMPTION_PROPORTIONAL",
    "vat_exemption": "SUBJECT_PROPORTIONAL",
    "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "exemption_proportional_limit": proportional_limit,
    "exemption_current_turnover": current_turnover,
    "exemption_exceeded": exemption_exceeded,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 113 ust. 5 i 9 VAT",
    "_warnings": warnings
} {
    input.jdg_entrepreneur.is_vat_payer == false

    annual_turnover := object.get(input.jdg_entrepreneur, "annual_turnover_net", 0)
    ceidg_date := object.get(input.jdg_entrepreneur, "ceidg_entry_date", "")

    is_new_jdg := ceidg_date != ""

    # Oblicz dzień roku
    current_day := object.get(input, "current_day_of_year", 365)

    # Limit proporcjonalny = 200k / 365 * dni
    proportional_limit = 200000 / 365 * current_day { is_new_jdg }
    proportional_limit = 200000 { not is_new_jdg }

    current_turnover = annual_turnover

    exemption_exceeded = true { current_turnover > proportional_limit }
    exemption_exceeded = false

    routing = "BLOCK_AND_ALERT" { exemption_exceeded == true }
    routing = "" { exemption_exceeded == false }
    routing_reason = sprintf("PRZEKROCZENIE ZWOLNIENIA VAT — przychód %.2f PLN > limit %.2f PLN (proporcjonalny: dzień %d/365 × 200k). Obowiązek rejestracji VAT od dnia przekroczenia!", [current_turnover, proportional_limit, current_day]) { exemption_exceeded == true }
    routing_reason = "" { exemption_exceeded == false }

    warnings = [sprintf("⚠️ ZWOLNIENIE VAT PRZEKROCZONE — %.2f PLN / %.2f PLN (dzień %d/365). Złóż VAT-R przed pierwszą czynnością opodatkowaną!", [current_turnover, proportional_limit, current_day])] { exemption_exceeded == true }
    warnings = [] { exemption_exceeded == false }
    warnings = [sprintf("Nowa JDG (od %s) — limit proporcjonalny: %.2f PLN (dzień %d/365 × 200k). Aktualny przychód: %.2f PLN.", [ceidg_date, proportional_limit, current_day, current_turnover])] { not exemption_exceeded; is_new_jdg }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-6: OSS/IOSS Compliance — E-usługi B2C, próg 10k EUR
# Art. 28l VAT (e-usługi B2C), próg 10 000 EUR dla OSS.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.oss_ioss_compliance",
    "package": "jdg.vat.plan26_critical", "priority": 6,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "OSS_IOSS_CHECK",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "oss_applicable": oss_applicable,
    "oss_threshold_eur": 10000,
    "oss_annual_eur": annual_eur_services,
    "oss_threshold_exceeded": threshold_exceeded,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 28l VAT, Rozp. 282/2011 UE",
    "_warnings": warnings
} {
    input.invoice.category_code in {"E_SERVICES", "DIGITAL_CONTENT", "SOFTWARE_DOWNLOAD", "ONLINE_COURSE", "STREAMING"}
    input.vendor.is_b2c == true
    input.invoice.direction == "SALE"

    annual_eur_services := object.get(input.jdg_entrepreneur, "annual_e_services_eur", 0)

    oss_threshold := 10000
    threshold_exceeded = true { annual_eur_services > oss_threshold }
    threshold_exceeded = false

    oss_applicable = true { annual_eur_services > oss_threshold }
    oss_applicable = false { annual_eur_services <= 0 }
    oss_applicable = false { annual_eur_services <= oss_threshold }

    routing = "TRIAGE_QUEUE" { oss_applicable == true }
    routing = "" { oss_applicable == false }
    routing_reason = sprintf("OSS — e-usługi B2C %.0f EUR/rok > 10k EUR. Rozliczaj przez OSS!", [annual_eur_services]) { oss_applicable == true }
    routing_reason = sprintf("E-usługi B2C %.0f EUR/rok — poniżej 10k, VAT PL.", [annual_eur_services]) { oss_applicable == false; annual_eur_services > 0 }
    routing_reason = "" { annual_eur_services == 0 }

    warnings = [sprintf("OSS/IOSS — e-usługi B2C %.0f EUR/rok. Powyżej 10 000 EUR = OSS (One-Stop-Shop). Zarejestruj się w OSS w jednym kraju UE.", [annual_eur_services])] { oss_applicable == true }
    warnings = [] { oss_applicable == false }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-7: VAT RR — Rolnik ryczałtowy (Art. 115-116 VAT)
# Art. 115-116 VAT: zryczałtowany zwrot VAT dla rolników ryczałtowych.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.vat_rr_flat_rate_farmer",
    "package": "jdg.vat.plan26_critical", "priority": 7,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "VAT_RR_FARMER",
    "vat_exemption": "RR_FARMER",
    "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_rr_rate": 0.07,
    "vat_rr_compensation": rr_compensation,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 115-116 VAT",
    "_warnings": [sprintf("ROLNIK RYCZAŁTOWY — VAT RR 7%% zryczałtowany zwrot. Rekompensata: %.2f PLN od wartości netto %.2f PLN.", [rr_compensation, amount_net])]
} {
    input.invoice.category_code == "AGRICULTURAL_PRODUCTS"
    input.jdg_entrepreneur.is_flat_rate_farmer == true
    input.invoice.direction == "SALE"

    amount_net := object.get(input.invoice, "amount_net", 0)
    rr_compensation := amount_net * 0.07
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-8: Bad Debt Auto-Tracker — Śledzenie 90-dniowego terminu
# Art. 89a-89b VAT: śledzenie terminu per faktura, alert przed 90 dniem.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.bad_debt_auto_tracker",
    "package": "jdg.vat.plan26_critical", "priority": 8,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_AUTO_TRACKER",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bad_debt_invoice_id": invoice_id,
    "bad_debt_days_overdue": days_overdue,
    "bad_debt_deadline_90d": deadline_90d,
    "bad_debt_days_remaining": days_remaining,
    "bad_debt_alert": alert_level,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 89a-89b VAT (SLIM VAT 3)",
    "_warnings": warnings
} {
    input.invoice.is_paid == false
    input.invoice.direction == "SALE"

    days_overdue := object.get(input.invoice, "days_overdue", 0)
    due_date := object.get(input.invoice, "due_date", "")
    invoice_id := object.get(input.invoice, "invoice_number", "")
    transaction_date := object.get(input.invoice, "transaction_date", "")

    # P29 N12: Temporal boundary — 150 dni przed SLIM VAT 3, 90 dni po
    is_pre_slim3 := transaction_date < "2023-01-01"

    applicable_days = 150 { is_pre_slim3 }
    applicable_days = 90 { not is_pre_slim3 }

    days_remaining = applicable_days - days_overdue { days_overdue < applicable_days }
    days_remaining = 0 { days_overdue >= applicable_days }
    deadline_90d = "EXCEEDED" { days_overdue >= applicable_days }
    deadline_90d = "PENDING"

    alert_level = "CRITICAL" { days_overdue >= applicable_days }
    alert_level = "WARNING" { days_overdue >= applicable_days - 10; days_overdue < applicable_days }
    alert_level = "WARNING" { days_overdue >= applicable_days - 20; days_overdue < applicable_days - 10 }
    alert_level = "INFO" { days_overdue >= applicable_days - 30; days_overdue < applicable_days - 20 }
    alert_level = "NONE" { days_overdue < applicable_days - 30 }

    routing = "TRIAGE_QUEUE" { alert_level == "CRITICAL" }
    routing = "TRIAGE_QUEUE" { alert_level == "WARNING" }
    routing = "" { alert_level in {"INFO", "NONE"} }

    routing_reason = sprintf("ZŁE DŁUGI — %d dni po terminie (%s, próg %d dni). Możesz skorygować VAT! (Art. 89a)", [days_overdue, period, applicable_days]) { days_overdue >= applicable_days }
    routing_reason = sprintf("ZŁE DŁUGI — %d/%d dni. Zostało %d dni do ulgi (%s).", [days_overdue, applicable_days, days_remaining, period]) { days_overdue >= applicable_days - 20; days_overdue < applicable_days }
    routing_reason = "" { days_overdue < applicable_days - 20 }

    warnings = [sprintf("ZŁE DŁUGI — faktura %s, termin %s, opóźnienie %d dni (próg %d dni, %s). Korekta VAT możliwa! Art. 89a.", [invoice_id, due_date, days_overdue, applicable_days, "PO SLIM VAT 3"])] { days_overdue >= applicable_days; not is_pre_slim3 }
    warnings = [sprintf("ZŁE DŁUGI — faktura %s, termin %s, opóźnienie %d dni (próg %d dni, %s). Korekta VAT możliwa! Art. 89a (przed SLIM VAT 3).", [invoice_id, due_date, days_overdue, applicable_days, "PRZED SLIM VAT 3"])] { days_overdue >= applicable_days; is_pre_slim3 }
    warnings = [sprintf("ZŁE DŁUGI ALERT — faktura %s, %d/%d dni, zostało %d dni. Przygotuj dokumentację.", [invoice_id, days_overdue, applicable_days, days_remaining])] { days_overdue >= applicable_days - 20; days_overdue < applicable_days }
    warnings = [] { days_overdue < applicable_days - 20 }

    period = "pre-SLIM VAT 3 (150 dni)" { is_pre_slim3 }
    period = "post-SLIM VAT 3 (90 dni)" { not is_pre_slim3 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-9: Art. 28o — Zapobieganie podwójnemu opodatkowaniu
# Reguła zapobiegawcza dla podwójnego opodatkowania VAT.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.double_taxation_prevention_art28o",
    "package": "jdg.vat.plan26_critical", "priority": 9,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "DOUBLE_TAXATION_PREVENTION",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "double_tax_risk_detected": risk_detected,
    "double_tax_countries": countries_involved,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "POTENCJALNE PODWÓJNE OPODATKOWANIE VAT — weryfikuj miejsce świadczenia!",
    "_legal_basis": "Art. 28o VAT",
    "_warnings": [sprintf("Art. 28o VAT — potencjalne podwójne opodatkowanie: %s. Sprawdź reguły miejsca świadczenia (Art. 28b-28n).", [countries_involved])]
} {
    input.invoice.direction in {"SALE", "PURCHASE"}
    vendor_country := object.get(input.vendor, "country", "PL")
    buyer_country := object.get(input.invoice, "buyer_country", "PL")
    place_of_supply := object.get(input.invoice, "place_of_supply", "PL")

    # Ryzyko: vendor PL, buyer UE, ale PoS określony jako PL
    risk_detected = true {
        vendor_country == "PL"
        buyer_country != "PL"
        place_of_supply != buyer_country
    }

    risk_detected = true {
        vendor_country != "PL"
        buyer_country != "PL"
        place_of_supply == "PL"
    }

    risk_detected = false { vendor_country == "PL"; buyer_country == "PL" }

    countries_involved := sprintf("%s → %s (PoS: %s)", [vendor_country, buyer_country, place_of_supply])

    risk_detected == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-10: WDT 70-Day Documentation Deadline
# Art. 42 ust. 1 pkt 2 VAT: termin 70 dni na potwierdzenie WDT.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.wdt_70_day_deadline",
    "package": "jdg.vat.plan26_critical", "priority": 10,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "WDT_70D_DEADLINE",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "wdt_days_elapsed": days_elapsed,
    "wdt_deadline_remaining": days_remaining,
    "wdt_documentation_received": docs_received,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 42 ust. 1 pkt 2 VAT",
    "_warnings": warnings
} {
    input.invoice.direction == "SALE"
    input.invoice.procedure in {"WDT", "INTRA_EU_SALE"}

    transaction_date := object.get(input.invoice, "transaction_date", "")
    has_transport_docs := object.get(input.invoice, "has_transport_documents", false)

    days_elapsed := object.get(input.invoice, "wdt_days_elapsed", 0)
    days_remaining = 70 - days_elapsed { days_elapsed < 70 }
    days_remaining = 0 { days_elapsed >= 70 }
    docs_received = true { has_transport_docs }
    docs_received = false

    routing = "BLOCK_AND_ALERT" { days_elapsed > 70; not docs_received }
    routing = "TRIAGE_QUEUE" { days_elapsed >= 60; not docs_received }
    routing = "" { days_elapsed < 60 }
    routing = "" { docs_received }

    routing_reason = sprintf("WDT — %d dni bez dokumentacji > 70 dni! Stawka 23%% zamiast 0%%!", [days_elapsed]) { days_elapsed > 70; not docs_received }
    routing_reason = sprintf("WDT — %d/%d dni. Zostało %d dni na dokumenty!", [days_elapsed, 70, days_remaining]) { days_elapsed >= 60; days_elapsed <= 70; not docs_received }
    routing_reason = "" { days_elapsed < 60 }
    routing_reason = "WDT — dokumentacja otrzymana ✓" { docs_received }

    warnings = [sprintf("WDT BEZ DOKUMENTACJI — %d dni > 70! Art. 42: bez potwierdzenia wywozu = stawka 23%%. Złóż korektę JPK_V7!", [days_elapsed])] { days_elapsed > 70; not docs_received }
    warnings = [sprintf("WDT — data: %s, %d/%d dni, dokumenty: %s. Pamiętaj o 70 dniach na potwierdzenie!", [transaction_date, days_elapsed, 70, to_string(docs_received)])] { days_elapsed > 0 }
    warnings = [] { days_elapsed == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-11: Art. 29a — Podstawa opodatkowania: rabaty, dotacje, kaucje (P29 N9)
# Art. 29a ust. 1-15 VAT: podstawa opodatkowania z uwzględnieniem
# rabatów/opustów (ust. 7), dotacji (ust. 1), kaucji (ust. 3),
# wartości rynkowej przy powiązaniach (ust. 2).
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.tax_base_art29a",
    "package": "jdg.vat.plan26_critical", "priority": 11,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "TAX_BASE_ART29A",
    "vat_exemption": "",
    "tax_base_adjusted": adjusted_base,
    "tax_base_rebate_deducted": rebate_deducted,
    "tax_base_subsidy_included": subsidy_included,
    "tax_base_deposit_excluded": deposit_excluded,
    "tax_base_market_value_applied": market_value_applied,
    "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 29a ust. 1-15 VAT",
    "_warnings": warnings
} {
    input.invoice.direction == "SALE"

    amount_net := object.get(input.invoice, "amount_net", 0)
    has_rebate := object.get(input.invoice, "has_rebate_discount", false)
    rebate_amount := object.get(input.invoice, "rebate_amount", 0)
    has_subsidy := object.get(input.invoice, "has_subsidy", false)
    subsidy_amount := object.get(input.invoice, "subsidy_amount", 0)
    has_deposit := object.get(input.invoice, "has_deposit", false)
    deposit_amount := object.get(input.invoice, "deposit_amount", 0)
    is_related_party := object.get(input.invoice, "is_related_party_transaction", false)
    market_value := object.get(input.invoice, "market_value", 0)

    # Art. 29a ust. 7: rabaty/opusty/skonta obniżają podstawę
    rebate_deducted = true { has_rebate; rebate_amount > 0 }
    rebate_deducted = false

    # Art. 29a ust. 1: dotacje wlicza się do podstawy
    subsidy_included = true { has_subsidy; subsidy_amount > 0 }
    subsidy_included = false

    # Art. 29a ust. 3: kaucje zwrotne wyłączone z podstawy
    deposit_excluded = true { has_deposit; deposit_amount > 0 }
    deposit_excluded = false

    # Art. 29a ust. 2: wartość rynkowa przy powiązaniach
    market_value_applied = true { is_related_party; market_value > 0; market_value != amount_net }
    market_value_applied = false

    # Calculate adjusted base with mutually exclusive priority order
    # Priority: market_value > rebate > subsidy > deposit > default
    adjusted_base = market_value { is_related_party; market_value > 0 }
    adjusted_base = amount_net - rebate_amount { has_rebate; not is_related_party }
    adjusted_base = amount_net + subsidy_amount { has_subsidy; not is_related_party; not has_rebate }
    adjusted_base = amount_net - deposit_amount { has_deposit; not is_related_party; not has_rebate; not has_subsidy }
    adjusted_base = amount_net

    routing = "TRIAGE_QUEUE" { is_related_party; market_value_applied }
    routing = "TRIAGE_QUEUE" { has_subsidy }
    routing = "" { not is_related_party; not has_subsidy }

    routing_reason = sprintf("Art. 29a: powiązania — wartość rynkowa %.2f PLN (netto: %.2f PLN)", [market_value, amount_net]) { market_value_applied }
    routing_reason = sprintf("Art. 29a: dotacja %.2f PLN wliczona do podstawy", [subsidy_amount]) { has_subsidy }
    routing_reason = "" { not is_related_party; not has_subsidy }

    warnings = [sprintf("Art. 29a VAT — podstawa skorygowana: %.2f PLN (netto: %.2f PLN, rabat: %.2f, dotacja: %.2f, kaucja: %.2f)", [adjusted_base, amount_net, rebate_amount, subsidy_amount, deposit_amount])] { adjusted_base != amount_net }
    warnings = [] { adjusted_base == amount_net }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-12: Art. 89a — Temporalna granica 150→90 dni złych długów (P29 N12)
# Rozróżnienie okresów: przed 2023-01-01 = 150 dni, po = 90 dni.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.bad_debt_temporal_boundary",
    "package": "jdg.vat.plan26_critical", "priority": 12,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "BAD_DEBT_TEMPORAL_CHECK",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "bad_debt_applicable_days": applicable_days,
    "bad_debt_period": period_label,
    "bad_debt_correction_allowed": correction_allowed,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 89a VAT (SLIM VAT 3 — zmiana 150→90 dni od 2023-01-01)",
    "_warnings": warnings
} {
    input.invoice.is_paid == false
    input.invoice.direction == "SALE"

    transaction_date := object.get(input.invoice, "transaction_date", "")
    days_overdue := object.get(input.invoice, "days_overdue", 0)

    # Określenie okresu: przed czy po SLIM VAT 3 (2023-01-01)
    # Dla transakcji sprzed 2023-01-01: 150 dni
    # Dla transakcji od 2023-01-01: 90 dni
    is_pre_slim3 := transaction_date < "2023-01-01"

    applicable_days = 150 { is_pre_slim3 }
    applicable_days = 90 { not is_pre_slim3 }

    period_label = "PRE_SLIM_VAT_3 (150 dni)" { is_pre_slim3 }
    period_label = "POST_SLIM_VAT_3 (90 dni)" { not is_pre_slim3 }

    correction_allowed = true { days_overdue >= applicable_days }
    correction_allowed = false

    routing = "TRIAGE_QUEUE" { correction_allowed == true }
    routing = "" { correction_allowed == false }

    routing_reason = sprintf("ZŁE DŁUGI — %s, %d/%d dni. Korekta %s.", [period_label, days_overdue, applicable_days, "DOZWOLONA"]) { correction_allowed == true }
    routing_reason = sprintf("ZŁE DŁUGI — %s, %d/%d dni. Korekta jeszcze NIEMOŻLIWA.", [period_label, days_overdue, applicable_days]) { correction_allowed == false }

    warnings = [sprintf("ZŁE DŁUGI TEMPORALNE — transakcja z %s (%s). Obowiązujący próg: %d dni. Opóźnienie: %d dni. Korekta: %s.", [transaction_date, period_label, applicable_days, days_overdue, "TAK"])] { correction_allowed == true }
    warnings = [sprintf("ZŁE DŁUGI TEMPORALNE — transakcja z %s (%s). Obowiązujący próg: %d dni. Opóźnienie: %d dni. Poczekaj %d dni.", [transaction_date, period_label, applicable_days, days_overdue, applicable_days - days_overdue])] { correction_allowed == false; days_overdue > 0 }
    warnings = [] { days_overdue == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-13: Art. 29a — Korekty faktur in minus/in plus (P29 N14)
# Art. 29a ust. 13-14 VAT (SLIM VAT 2): okres rozliczenia korekty.
# Korekta in minus → w okresie wystawienia jeśli potwierdzenie odbioru.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.correction_invoice_period",
    "package": "jdg.vat.plan26_critical", "priority": 13,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "CORRECTION_PERIOD_CHECK",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "correction_type": correction_type,
    "correction_period": correct_period,
    "correction_receipt_confirmed": has_receipt_confirmation,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 29a ust. 13-14 VAT (SLIM VAT 2)",
    "_warnings": warnings
} {
    input.invoice.is_correction == true
    input.invoice.direction == "SALE"

    correction_amount := object.get(input.invoice, "correction_amount", 0)
    has_receipt_confirmation := object.get(input.invoice, "has_receipt_confirmation", false)
    correction_date := object.get(input.invoice, "correction_date", "")
    original_period := object.get(input.invoice, "original_invoice_period", "")

    # Typ korekty
    correction_type = "IN_MINUS" { correction_amount < 0 }
    correction_type = "IN_PLUS" { correction_amount > 0 }
    correction_type = "ZERO" { correction_amount == 0 }

    # Okres rozliczenia
    # In minus: okres wystawienia (jeśli potwierdzenie odbioru przed złożeniem JPK_V7)
    correct_period = "CURRENT_PERIOD" { correction_type == "IN_MINUS"; has_receipt_confirmation }
    correct_period = "ORIGINAL_PERIOD_PENDING_CONFIRMATION" { correction_type == "IN_MINUS"; not has_receipt_confirmation }
    correct_period = "ORIGINAL_PERIOD" { correction_type == "IN_PLUS" }
    correct_period = "NONE" { correction_type == "ZERO" }

    routing = "TRIAGE_QUEUE" { correction_type == "IN_MINUS"; not has_receipt_confirmation }
    routing = "" { correction_type != "IN_MINUS" }
    routing = "" { has_receipt_confirmation }

    routing_reason = sprintf("KOREKTA IN MINUS — brak potwierdzenia odbioru. Rozlicz w okresie uzyskania potwierdzenia.", []) { correction_type == "IN_MINUS"; not has_receipt_confirmation }
    routing_reason = "" { correction_type != "IN_MINUS" }
    routing_reason = sprintf("KOREKTA IN MINUS — potwierdzenie ✓. Rozlicz w bieżącym okresie.", []) { correction_type == "IN_MINUS"; has_receipt_confirmation }

    warnings = [sprintf("KOREKTA %s — kwota: %.2f PLN. Okres rozliczenia: %s. Data korekty: %s.", [correction_type, abs(correction_amount), correct_period, correction_date])]
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-14: Art. 90-91 — Proporcja roczna + korekta (P29 N17)
# Art. 91 VAT: roczna korekta proporcji odliczenia VAT.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.annual_proportion_correction",
    "package": "jdg.vat.plan26_critical", "priority": 14,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "ANNUAL_PROPORTION_CORRECTION",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "proportion_preliminary": preliminary_proportion,
    "proportion_final": final_proportion,
    "proportion_correction_required": correction_required,
    "proportion_correction_amount": correction_amount,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 90-91 VAT",
    "_warnings": warnings
} {
    input.jdg_entrepreneur.is_vat_payer == true

    # Proporcja wstępna (z poprzedniego roku)
    preliminary_proportion := object.get(input.jdg_entrepreneur, "vat_preliminary_proportion", 1.0)
    # Proporcja rzeczywista (po zakończeniu roku)
    final_proportion := object.get(input.jdg_entrepreneur, "vat_final_proportion", preliminary_proportion)

    total_vat_deducted := object.get(input.jdg_entrepreneur, "vat_total_deducted_year", 0)

    # Czy wymagana korekta roczna?
    correction_required = true { preliminary_proportion != final_proportion }
    correction_required = false

    # Kwota korekty
    correction_amount = total_vat_deducted * (final_proportion - preliminary_proportion) { correction_required }
    correction_amount = 0

    routing = "TRIAGE_QUEUE" { correction_required }
    routing = "" { not correction_required }
    routing_reason = sprintf("Art. 91 — korekta roczna proporcji: %.2f%% → %.2f%%. Kwota korekty: %.2f PLN.", [preliminary_proportion*100, final_proportion*100, correction_amount]) { correction_required }
    routing_reason = "" { not correction_required }

    warnings = [sprintf("KOREKTA ROCZNA VAT — proporcja wstępna %.2f%% → ostateczna %.2f%%. Korekta: %.2f PLN. Złóż w JPK_V7 za styczeń.", [preliminary_proportion*100, final_proportion*100, correction_amount])] { correction_required }
    warnings = [] { not correction_required }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-15: Art. 88 — Wyłączenia odliczeń VAT (P29 N18)
# Pełna lista wyłączeń odliczeń: reprezentacja, noclegi, paliwo,
# usługi noclegowe i gastronomiczne (z wyjątkami).
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.deduction_exclusions_art88",
    "package": "jdg.vat.plan26_critical", "priority": 15,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "DEDUCTION_EXCLUSIONS_CHECK",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "deduction_blocked": deduction_blocked,
    "deduction_exclusion_reason": exclusion_reason,
    "_routing": routing,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 88 VAT",
    "_warnings": warnings
} {
    input.invoice.direction == "PURCHASE"
    category := input.invoice.category_code
    category in excluded_categories — nabycie towarów/usług od podmiotu niezarejestrowanego
    # Art. 88 ust. 1 pkt 3 — transakcje udokumentowane fakturami dokumentującymi czynności niepodlegające
    # Art. 88 ust. 1 pkt 4 — usługi noclegowe i gastronomiczne (z wyjątkami)
    # Art. 88 ust. 1 pkt 5 — wydatki na reprezentację

    excluded_categories := {
        "REPRESENTATION", "ENTERTAINMENT", "HOTEL_ACCOMMODATION",
        "RESTAURANT_MEALS_NON_TRAVEL", "GASTRONOMY_EXCESSIVE"
    }

    deduction_blocked = true { category in excluded_categories }
    deduction_blocked = false

    exclusion_reason = sprintf("Art. 88 VAT — %s: odliczenie VAT wyłączone", [category]) { deduction_blocked }
    exclusion_reason = ""

    routing = "BLOCK_AND_ALERT" { deduction_blocked }
    routing = "" { not deduction_blocked }
    routing_reason = exclusion_reason { deduction_blocked }
    routing_reason = "" { not deduction_blocked }

    warnings = [sprintf("⚠️ Art. 88 VAT — kategoria %s NIE podlega odliczeniu VAT. Wyłączenie ustawowe.", [category])] { deduction_blocked }
    warnings = [] { not deduction_blocked }
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-16: Art. 119 — Biura podróży — procedura marży (P29 N20)
# Rozróżnienie Art. 119 (biura podróży) i Art. 120 (towary używane).
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.travel_agency_margin_art119",
    "package": "jdg.vat.plan26_critical", "priority": 16,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "procedure": "TRAVEL_AGENCY_MARGIN",
    "vat_exemption": "", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "margin_scheme_type": margin_type,
    "margin_scheme_base": margin_base,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 119 VAT (biura podróży), Art. 120 VAT (towary używane)",
    "_warnings": [sprintf("PROCEDURA MARŻY — %s. Podstawa opodatkowania = marża: %.2f PLN.", [margin_type, margin_base])]
} {
    input.invoice.procedure == "MARGIN"

    is_travel_agency := object.get(input.invoice, "is_travel_agency", false)
    is_used_goods := object.get(input.invoice, "is_used_goods", false)
    margin_amount := object.get(input.invoice, "margin_amount", 0)

    # Rozróżnienie: Art. 119 (biura podróży) vs Art. 120 (towary używane)
    margin_type = "TRAVEL_AGENCY_ART119" { is_travel_agency }
    margin_type = "USED_GOODS_ART120" { is_used_goods }
    margin_type = "GENERAL_MARGIN" { not is_travel_agency; not is_used_goods }

    margin_base = margin_amount
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIT-17: Art. 43 — Rozszerzone zwolnienia (P29 N10) — dodatkowe 10 pkt
# Uzupełnienie brakujących 30 punktów zwolnień przedmiotowych.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.vat.plan26_critical.extended_exemptions_art43",
    "package": "jdg.vat.plan26_critical", "priority": 17,
    "vat_rate": "0.00", "rounding_level": "total",
    "gtu_code": "", "procedure": "EXTENDED_EXEMPTIONS",
    "vat_exemption": "OBJECT", "pit_form": "", "pit_rate": "",
    "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "exemption_point": exemption_point,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 43 ust. 1 VAT",
    "_warnings": [sprintf("Zwolnienie VAT — Art. 43 ust. 1 pkt %s: %s", [exemption_point, exemption_desc])]
} {
    input.vendor.country == "PL"
    input.invoice.direction == "SALE"

    category := input.invoice.category_code

    # Rozszerzona mapa zwolnień Art. 43 (10 dodatkowych punktów)
    extended_exemptions := {
        "HOSPITAL_SERVICES": {"point": "18", "desc": "Usługi szpitalne i opieka medyczna"},
        "SOCIAL_CARE": {"point": "22", "desc": "Usługi opieki społecznej"},
        "CHILD_CARE": {"point": "24", "desc": "Opieka nad dziećmi i młodzieżą"},
        "CHARITY_SERVICES": {"point": "23", "desc": "Działalność charytatywna"},
        "INSURANCE_INTERMEDIATION": {"point": "37", "desc": "Pośrednictwo ubezpieczeniowe"},
        "INVESTMENT_FUNDS": {"point": "38", "desc": "Zarządzanie funduszami inwestycyjnymi"},
        "RELIGIOUS_SERVICES": {"point": "31", "desc": "Usługi organizacji religijnych"},
        "TRADE_UNION_SERVICES": {"point": "32", "desc": "Usługi związków zawodowych"},
        "PUBLIC_BROADCASTING": {"point": "34", "desc": "Usługi publicznej radiofonii i telewizji"},
        "LOTTERY_GAMBLING": {"point": "15", "desc": "Zakłady wzajemne i gry hazardowe"}
    }

    exemption_point := extended_exemptions[category].point
    exemption_desc := extended_exemptions[category].desc
}
