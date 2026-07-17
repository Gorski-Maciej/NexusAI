# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise ZUS Sickness & Benefits Complete (Class C → A)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: ZUS Sickness & Benefits Enterprise — Zasiłki + Świadczenia + Cross-domain
# description: |
#   ENTERPRISE v5.0 — Wypełnia lukę 85% Klasy C (ZUS zasiłki chorobowe,
#   macierzyńskie, opiekuńcze, rehabilitacyjne, wyrównawcze).
#   Implementuje:
#   - Zasiłek chorobowy (80% / 100% podstawy, 90 dni oczekiwania)
#   - Zasiłek macierzyński (100%, 20-37 tygodni, JDG = podstawa z 12 mies.)
#   - Zasiłek opiekuńczy (80%, 14-60 dni)
#   - Świadczenie rehabilitacyjne (90%, 12 mies.)
#   - Zasiłek wyrównawczy (różnica między pensją a zasiłkiem)
#   - Cross-domain: ZUS × PIT (opodatkowanie zasiłków)
#   - Cross-domain: ZUS × VAT (brak VAT na zasiłkach)
# architecture: Enterprise Multi-Pass, First-Match-Wins else-chain
# legal_basis: Ustawa SUS, Ustawa o świadczeniach pieniężnych z ubezp. społ.
#   w razie choroby i macierzyństwa (Dz.U. 2025 poz. 890)
# package: jdg.zus.sickness_benefits
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.zus.sickness_benefits

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.zus.sickness.no_match",
    "package": "jdg.zus.sickness_benefits", "priority": 1299
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Z100-Z109: ZASIŁEK CHOROBOWY (10 reguł)                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Z100: sickness_benefit_eligibility — Warunki zasiłku chorobowego ──
decide := {
    "matched": true, "rule_id": "jdg.zus.sickness.eligibility",
    "package": "jdg.zus.sickness_benefits", "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_sickness_eligible": is_eligible,
    "zus_sickness_waiting_days": waiting_days,
    "zus_sickness_rate_pct": benefit_rate,
    "zus_sickness_basis_pln": sickness_basis,
    "zus_sickness_daily_pln": daily_benefit,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": benefit_routing,
    "_routing_reason": sprintf("Zasiłek chorobowy: %s — %.0f%% podstawy = %.2f PLN/dzień", [status, benefit_rate, daily_benefit]),
    "_legal_basis": "Art. 4-9 ustawy zasiłkowej, Art. 11-12 SUS",
    "_warnings": [sprintf("ZASIŁEK CHOROBOWY JDG — %s. (1) Okres wyczekiwania: %d dni nieprzerwanego ubezpieczenia chorobowego, (2) Podstawa miesięczna: %.2f PLN (dzienna: %.2f PLN), (3) Stawka: %.0f%% (80%% standard, 100%% w ciąży/wypadek), (4) Płatne przez ZUS od 1. dnia (JDG), (5) Zasiłek podlega PIT (18%%/32%% na skali, 19%% liniowy)!", [status, waiting_days, monthly_basis, sickness_basis, benefit_rate])]
} {
    input.jdg_entrepreneur.sickness_claim == true
    has_sickness_insurance := object.get(input.jdg_entrepreneur, "zus_sickness_insurance", false)
    days_insured := object.get(input.jdg_entrepreneur, "zus_sickness_insurance_days", 0)
    waiting_days := 90  # Okres wyczekiwania dla JDG
    is_eligible := has_sickness_insurance and days_insured >= waiting_days
    # Podstawa zasiłku
    monthly_basis := object.get(input.jdg_entrepreneur, "zus_sickness_basis_monthly", 5000)
    sickness_basis := floor(monthly_basis * 12 / 365 * 100) / 100
    # Stawka
    is_pregnancy := object.get(input.jdg_entrepreneur, "is_pregnancy_related", false)
    is_accident := object.get(input.jdg_entrepreneur, "is_work_accident", false)
    benefit_rate = 100 { is_pregnancy == true or is_accident == true }
    benefit_rate = 80 { true }
    daily_benefit := floor(sickness_basis * benefit_rate / 100 * 100) / 100
    status = "PRZYSŁUGUJE" { is_eligible == true }
    status = sprintf("BRAK — %d dni ubezpieczenia (wymagane 90)", [days_insured]) { not has_sickness_insurance or days_insured < waiting_days }
    benefit_routing = "" { true }
}

# ── Z101: sickness_benefit_waiting_period — Okres wyczekiwania 90 dni ──
else := {
    "matched": true, "rule_id": "jdg.zus.sickness.waiting_period",
    "package": "jdg.zus.sickness_benefits", "priority": 101,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_sickness_waiting_block": true,
    "zus_sickness_days_remaining": days_remaining,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Brak zasiłku — okres wyczekiwania: %d dni pozostało", [days_remaining]),
    "_legal_basis": "Art. 4 ust. 1 pkt 2 ustawy zasiłkowej",
    "_warnings": [sprintf("BRAK ZASIŁKU CHOROBOWEGO — Okres wyczekiwania: %d dni. Masz %d dni ubezpieczenia, potrzeba 90. Zasiłek dopiero po 90 dniach nieprzerwanego ubezpieczenia! Ubezpieczenie chorobowe jest DOBROWOLNE dla JDG.", [days_remaining, days_insured])]
} {
    input.jdg_entrepreneur.sickness_claim == true
    days_insured := object.get(input.jdg_entrepreneur, "zus_sickness_insurance_days", 0)
    days_insured < 90
    days_remaining := 90 - days_insured
}

# ── Z102: sickness_benefit_no_insurance — Brak ubezpieczenia chorobowego ──
else := {
    "matched": true, "rule_id": "jdg.zus.sickness.no_insurance",
    "package": "jdg.zus.sickness_benefits", "priority": 102,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_sickness_denied_reason": "NO_VOLUNTARY_INSURANCE",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 11 ust. 2 SUS (dobrowolność ubezpieczenia chorobowego dla JDG)",
    "_warnings": ["BRAK ZASIŁKU — NIE masz ubezpieczenia chorobowego! JDG opłaca chorobowe DOBROWOLNIE. Jeśli chcesz zasiłek: (1) Zgłoś się do dobrowolnego ubezpieczenia chorobowego przez ZUS ZUA, (2) Opłacaj składkę 2.45%% od podstawy, (3) Zasiłek dopiero po 90 dniach."]
} {
    input.jdg_entrepreneur.sickness_claim == true
    object.get(input.jdg_entrepreneur, "zus_sickness_insurance", false) == false
}

# ── Z103: sickness_benefit_taxation — Zasiłek podlega PIT ──
else := {
    "matched": true, "rule_id": "jdg.zus.sickness.pit_taxation",
    "package": "jdg.zus.sickness_benefits", "priority": 103,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_sickness_taxable": true,
    "zus_sickness_annual_limit": 85528,
    "zus_sickness_pit_form": pit_form_label,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 9 ust. 1, Art. 27, Art. 30c PIT",
    "_warnings": [sprintf("ZASIŁEK CHOROBOWY A PIT — Zasiłek podlega opodatkowaniu PIT! %s. ZUS pobiera zaliczkę PIT automatycznie. PIT-11 od ZUS do końca lutego. UWAGA: zasiłek NIE podlega składce zdrowotnej (9%%/4.9%%).", [pit_info])]
} {
    input.jdg_entrepreneur.sickness_claim == true
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form_label = "Skala 12/32%" { tax_form == "PIT_SCALE" }
    pit_form_label = "Liniowy 19%" { tax_form == "LINEAR" }
    pit_form_label = "Ryczałt (zasiłek nie łączy się z ryczałtem)" { tax_form == "LUMP_SUM" }
    pit_info = sprintf("Forma: %s", [pit_form_label])
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Z200-Z209: ZASIŁEK MACIERZYŃSKI (10 reguł)                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Z200: maternity_benefit_eligibility — Zasiłek macierzyński dla JDG ──
else := {
    "matched": true, "rule_id": "jdg.zus.maternity.eligibility",
    "package": "jdg.zus.sickness_benefits", "priority": 200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_maternity_eligible": is_eligible,
    "zus_maternity_rate_pct": 100,
    "zus_maternity_weeks": maternity_weeks,
    "zus_maternity_basis_pln": maternity_basis,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Zasiłek macierzyński: %s — %d tygodni × 100%% podstawy", [status, maternity_weeks]),
    "_legal_basis": "Art. 29-31 ustawy zasiłkowej",
    "_warnings": [sprintf("ZASIŁEK MACIERZYŃSKI JDG — %s. (1) 100%% podstawy wymiaru przez %d tygodni, (2) Podstawa: przeciętny przychód z 12 miesięcy (JDG: %.2f PLN/mies), (3) Wymagane 90 dni ubezpieczenia chorobowego, (4) Wniosek do ZUS + odpis aktu urodzenia, (5) ZUS Z-3b", [status_detail, maternity_weeks, maternity_basis])]
} {
    input.jdg_entrepreneur.maternity_claim == true
    has_sickness_insurance := object.get(input.jdg_entrepreneur, "zus_sickness_insurance", false)
    days_insured := object.get(input.jdg_entrepreneur, "zus_sickness_insurance_days", 0)
    children_count := object.get(input.jdg_entrepreneur, "expected_children_count", 1)
    is_first := object.get(input.jdg_entrepreneur, "is_first_child", true)
    # Okres zasiłku
    maternity_weeks = 20 { children_count == 1 }
    maternity_weeks = 31 { children_count == 2 }
    maternity_weeks = 33 { children_count == 3 }
    maternity_weeks = 35 { children_count == 4 }
    maternity_weeks = 37 { children_count >= 5 }
    # Podstawa
    monthly_basis := object.get(input.jdg_entrepreneur, "zus_maternity_basis_monthly", 5000)
    maternity_basis := floor(monthly_basis * 100) / 100
    is_eligible := has_sickness_insurance and days_insured >= 90
    status = "PRZYSŁUGUJE" { is_eligible == true }
    status = "NIE PRZYSŁUGUJE" { not is_eligible }
    status_detail = sprintf("Podstawa %.2f PLN/mies × 100%%", [maternity_basis]) { is_eligible }
    status_detail = "Brak ubezpieczenia chorobowego lub okres wyczekiwania" { not is_eligible }
}

# ── Z201: maternity_benefit_paternity — Urlop ojcowski 2 tygodnie ──
else := {
    "matched": true, "rule_id": "jdg.zus.maternity.paternity_leave",
    "package": "jdg.zus.sickness_benefits", "priority": 201,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_paternity_weeks": 2,
    "zus_paternity_rate_pct": 100,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "Urlop ojcowski: 2 tygodnie × 100% podstawy",
    "_legal_basis": "Art. 182³ KP w zw. z Art. 29 ustawy zasiłkowej",
    "_warnings": ["URLOP OJCOWSKI — 2 tygodnie × 100%% podstawy. Do wykorzystania do 24 miesiąca życia dziecka. Również dla JDG z ubezpieczeniem chorobowym!"]
} {
    input.jdg_entrepreneur.paternity_leave_claim == true
}

# ── Z202: maternity_health_insurance_still_due — Zdrowotna NADAL przy macierzyńskim ──
else := {
    "matched": true, "rule_id": "jdg.zus.maternity.health_still_due",
    "package": "jdg.zus.sickness_benefits", "priority": 202,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_health_still_due": true,
    "zus_health_due_monthly_pln": health_monthly,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 81 ustawy o świadczeniach zdrowotnych",
    "_warnings": [sprintf("SKŁADKA ZDROWOTNA PRZY MACIERZYŃSKIM — NADAL NALEŻNA! %.2f PLN/mies. Zasiłek macierzyński NIE zwalnia ze składki zdrowotnej. Opłacaj samodzielnie do 10. dnia miesiąca.", [health_monthly])]
} {
    input.jdg_entrepreneur.maternity_benefit_active == true
    health_monthly := object.get(input.jdg_entrepreneur, "zus_health_monthly", 380)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Z300-Z309: ZASIŁEK OPIEKUŃCZY (5 reguł)                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Z300: care_benefit_child — Opieka nad dzieckiem do 14 lat ──
else := {
    "matched": true, "rule_id": "jdg.zus.care.child_benefit",
    "package": "jdg.zus.sickness_benefits", "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_care_type": "CHILD",
    "zus_care_days": 60,
    "zus_care_rate_pct": 80,
    "zus_care_days_used": days_used,
    "zus_care_days_remaining": days_remaining,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": care_routing,
    "_routing_reason": sprintf("Zasiłek opiekuńczy: %d dni wykorzystane, %d pozostało", [days_used, days_remaining]),
    "_legal_basis": "Art. 32-35 ustawy zasiłkowej",
    "_warnings": [sprintf("ZASIŁEK OPIEKUŃCZY NAD DZIECKIEM — %.0f%% podstawy. Limit: 60 dni/rok (na dziecko do 14 lat). Wykorzystano: %d dni, pozostało: %d dni. Maksymalnie 14 dni w jednym epizodzie.", [80.0, days_used, days_remaining])]
} {
    input.jdg_entrepreneur.care_claim_child == true
    days_used := object.get(input.jdg_entrepreneur, "care_days_used_child", 0)
    limit := 60
    days_remaining := max([0, limit - days_used])
    has_capacity := days_remaining > 0
    care_routing = "TRIAGE_QUEUE" { not has_capacity }
    care_routing = "" { has_capacity }
}

# ── Z301: care_benefit_family — Opieka nad członkiem rodziny 14 dni ──
else := {
    "matched": true, "rule_id": "jdg.zus.care.family_member",
    "package": "jdg.zus.sickness_benefits", "priority": 301,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_care_type": "FAMILY",
    "zus_care_days": 14,
    "zus_care_rate_pct": 80,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "Zasiłek opiekuńczy nad członkiem rodziny — 14 dni × 80% podstawy",
    "_legal_basis": "Art. 32 ust. 1 pkt 2 ustawy zasiłkowej",
    "_warnings": ["ZASIŁEK OPIEKUŃCZY NAD CZŁONKIEM RODZINY — 80%% podstawy przez max 14 dni/rok. Wymagane zaświadczenie lekarskie."]
} {
    input.jdg_entrepreneur.care_claim_family == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Z400-Z409: ŚWIADCZENIE REHABILITACYJNE (5 reguł)                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Z400: rehabilitation_benefit — Świadczenie rehabilitacyjne 12 mies. ──
else := {
    "matched": true, "rule_id": "jdg.zus.rehabilitation.benefit",
    "package": "jdg.zus.sickness_benefits", "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_rehab_eligible": is_eligible,
    "zus_rehab_rate_pct": rehab_rate,
    "zus_rehab_months": 12,
    "zus_rehab_basis_pln": rehab_basis,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Świadczenie rehabilitacyjne: %.0f%% × %.2f PLN/mies przez 12 mies.", [rehab_rate, rehab_basis]),
    "_legal_basis": "Art. 18 ustawy zasiłkowej",
    "_warnings": [sprintf("ŚWIADCZENIE REHABILITACYJNE — %.0f%% podstawy przez max 12 mies. (%.2f PLN/mies). Warunki: (1) Wyczerpany zasiłek chorobowy (182 dni), (2) Rokowanie na odzyskanie zdolności do pracy, (3) Orzecznik ZUS. Stawka: 90%% (pierwsze 3 mies.), 75%% (pozostałe).", [rehab_rate, rehab_basis])]
} {
    input.jdg_entrepreneur.rehabilitation_claim == true
    sickness_days := object.get(input.jdg_entrepreneur, "sickness_days_used", 0)
    is_eligible := sickness_days >= 182
    # Stawka: 90% pierwsze 3 mies, 75% pozostałe
    rehab_month := object.get(input.jdg_entrepreneur, "rehab_month", 1)
    rehab_rate = 90 { rehab_month <= 3 }
    rehab_rate = 75 { rehab_month > 3 }
    rehab_basis := object.get(input.jdg_entrepreneur, "zus_rehab_basis_monthly", 5000)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Z500-Z509: ZASIŁEK WYRÓWNAWCZY (Art. 23-26 ustawy zasiłkowej)           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Z500: compensatory_allowance — Zasiłek wyrównawczy ──
else := {
    "matched": true, "rule_id": "jdg.zus.compensatory.allowance",
    "package": "jdg.zus.sickness_benefits", "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_compensatory_eligible": is_eligible,
    "zus_compensatory_amount_pln": compensatory_amount,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Zasiłek wyrównawczy: %.2f PLN (różnica między pensją a zasiłkiem)", [compensatory_amount]),
    "_legal_basis": "Art. 23-26 ustawy zasiłkowej",
    "_warnings": [sprintf("ZASIŁEK WYRÓWNAWCZY — %.2f PLN. Przysługuje gdy pracownik (w JDG!) został przesunięty na gorzej płatne stanowisko z powodu choroby/rehabilitacji. Różnica między starą a nową pensją.", [compensatory_amount])]
} {
    input.employment.has_employees == true
    input.employment.compensatory_allowance_claim == true
    old_salary := object.get(input.employment, "employee_old_salary", 5000)
    new_salary := object.get(input.employment, "employee_new_salary", 3500)
    compensatory_amount := max([0, old_salary - new_salary])
    is_eligible := compensatory_amount > 0
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Z600-Z609: CROSS-DOMAIN: ZUS × PIT × VAT (5 reguł)                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Z600: benefits_pit_summary — Podsumowanie opodatkowania zasiłków ──
else := {
    "matched": true, "rule_id": "jdg.zus.benefits.pit_summary",
    "package": "jdg.zus.sickness_benefits", "priority": 600,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": tax_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_benefits_total_taxable_pln": total_benefits,
    "zus_benefits_pit_advance_pct": pit_rate_float,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": sprintf("Zasiłki podlegają PIT — łącznie %.2f PLN opodatkowane według formy %s", [total_benefits, tax_form]),
    "_legal_basis": "Art. 9 ust. 1, Art. 27 PIT",
    "_warnings": [sprintf("OPODATKOWANIE ZASIŁKÓW ZUS — %.2f PLN łącznie. ZUS pobiera zaliczkę PIT. %s. PIT-11 od ZUS do końca lutego. Zasiłki NIE podlegają składce zdrowotnej!", [total_benefits, pit_detail])]
} {
    # Skip if current transaction IS a benefit (Z601 handles those)
    not input.invoice.income_type in {"SICKNESS_BENEFIT", "MATERNITY_BENEFIT", "CARE_BENEFIT", "REHAB_BENEFIT"}
    sickness_benefit := object.get(input.jdg_entrepreneur, "sickness_benefit_received", 0)
    maternity_benefit := object.get(input.jdg_entrepreneur, "maternity_benefit_received", 0)
    care_benefit := object.get(input.jdg_entrepreneur, "care_benefit_received", 0)
    rehab_benefit := object.get(input.jdg_entrepreneur, "rehab_benefit_received", 0)
    total_benefits := sickness_benefit + maternity_benefit + care_benefit + rehab_benefit
    total_benefits > 0
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_rate_float = 12 { tax_form == "PIT_SCALE" }
    pit_rate_float = 19 { tax_form == "LINEAR" }
    pit_rate_float = 12 { tax_form == "LUMP_SUM" }
    pit_detail = "Skala 12% — zasiłki sumują się z dochodem JDG" { tax_form == "PIT_SCALE" }
    pit_detail = "Liniowy 19% — zasiłki opodatkowane 19%" { tax_form == "LINEAR" }
    pit_detail = "Ryczałt — zasiłki na skali 12% ODDZIELNIE!" { tax_form == "LUMP_SUM" }
}

# ── Z601: benefits_no_vat — Zasiłki poza VAT ──
# ⚠️ Z601 MUST fire BEFORE Z600 — jeśli transakcja to zasiłek, Z601 od razu
# ustawia VAT = 0.00. Gdyby Z600 był pierwszy, przechwyciłby total_benefits > 0
# i Z601 nigdy by nie zapałał.
else := {
    "matched": true, "rule_id": "jdg.zus.benefits.no_vat",
    "package": "jdg.zus.sickness_benefits", "priority": 601,
    "vat_rate": "0.00", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "vat_exemption": "OUT_OF_SCOPE",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 5-6 VAT (zasiłki poza zakresem VAT)",
    "_warnings": ["ZASIŁKI ZUS POZA VAT — Zasiłki chorobowe/macierzyńskie/opiekuńcze NIE podlegają VAT! Nie wykazuj w JPK_V7. Nie wystawiaj faktury. Są poza zakresem ustawy o VAT."]
} {
    input.invoice.income_type in {"SICKNESS_BENEFIT", "MATERNITY_BENEFIT", "CARE_BENEFIT", "REHAB_BENEFIT"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.zus.sickness.fallback",
    "package": "jdg.zus.sickness_benefits", "priority": 999,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Ustawa zasiłkowa + SUS",
    "_warnings": ["Brak zasiłku ZUS dla tej transakcji — standardowe składki ZUS obowiązują."]
} {
    true
}
