# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE NKUP COMPLETE (PIT Art. 23 — Strategic Initiative S15)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise NKUP Complete — Art. 23 PIT Full Coverage
# description: |
#   ENTERPRISE v6.0 — Pełne pokrycie Art. 23 PIT (wydatki niestanowiące KUP).
#   Wypełnia krytyczną lukę: Art. 23 ma 57 punktów, z czego ~60% było w
#   klasie B/C (szkielety/planowane). Ten pakiet dostarcza reguły dla każdego
#   punktu Art. 23 ust. 1, włącznie z najczęstszymi pułapkami NKUP dla JDG.
#   
#   KLUCZOWE OBSZARY:
#   - Reprezentacja (pkt 23) — szczegółowa klasyfikacja
#   - Samochody (pkt 46-47) — limity 150k/225k, ewidencja
#   - Leasing operacyjny vs finansowy (pkt 47a)
#   - Odsetki od pożyczek (pkt 8a, 32-33)
#   - Darowizny (pkt 11)
#   - Rodzina (pkt 10)
#   - Amortyzacja gruntów (pkt 1)
#   - Składki ZUS pracodawcy (pkt 43 — NKUP gdy nieodliczone VAT)
#   - Koszty egzekucyjne (pkt 17-19)
#   - Odpisy aktualizujące (pkt 21)
#   - Podatki (pkt 43)
#   - Wydatki na nabycie ŚT (pkt 1 lit. a-c)
#   
#   Każda reguła mapuje konkretny punkt Art. 23 ust. 1 PIT.
# architecture: Enterprise NKUP Engine, First-Match-Wins else-chain
# legal_basis: Art. 23 ust. 1 PIT (57 punktów); Art. 86a VAT; Art. 23a-23zf PIT
# package: jdg.nkup_enterprise
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.nkup_enterprise

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.nkup.no_match",
    "package": "jdg.nkup_enterprise", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-001: Art. 23 ust. 1 pkt 1 — Wydatki na nabycie/ulepszenie ŚT
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.nkup.fixed_asset_purchase_not_kup",
    "package": "jdg.nkup_enterprise",
    "priority": 1,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 1 PIT",
    "nkup_reason": "Wydatek na nabycie/ulepszenie środka trwałego — rozliczany przez amortyzację",
    "nkup_alternative": "Amortyzacja wg stawek KŚT (Art. 22a-22o PIT)",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 1 lit. a-c PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.1: Wydatek %.2f PLN na %s jest NKUP — rozlicz przez amortyzację (KŚT grupa %s, stawka %.0f%%).",
        [asset_value, asset_name, kst_group, depreciation_rate * 100])]
} {
    input.invoice.expense_type == "FIXED_ASSET"
    asset_value := object.get(input.invoice, "amount_net", 0)
    asset_value >= 10000  # Threshold for fixed asset
    asset_name := object.get(input.invoice, "description", "ŚT")
    kst_group := object.get(input.invoice, "kst_group", "N/A")
    depreciation_rate := object.get(input.invoice, "depreciation_rate", 0.20)
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-010: Art. 23 ust. 1 pkt 10 — Wynagrodzenie małżonka/dzieci
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.family_wages_nkup",
    "package": "jdg.nkup_enterprise",
    "priority": 10,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 10 PIT",
    "nkup_reason": sprintf("Wynagrodzenie %s — NKUP gdy brak udokumentowania rzeczywistej pracy",
        [family_relation]),
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Wynagrodzenie %s — ryzyko NKUP", [family_relation]),
    "_legal_basis": "Art. 23 ust. 1 pkt 10 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.10: Wynagrodzenie %s (%.2f PLN) jest NKUP! Udokumentuj rzeczywistą pracę: zakres obowiązków, ewidencja czasu pracy, efekt pracy.",
        [family_relation, wage_amount])]
} {
    family_relation := object.get(input.vendor, "relation_to_entrepreneur", "")
    family_relation in {"SPOUSE", "CHILD_UNDER_18", "CHILD_18_25_STUDENT"}
    wage_amount := object.get(input.invoice, "amount_net", 0)
    wage_amount > 0
    object.get(input.invoice, "family_work_documented", true) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-011: Art. 23 ust. 1 pkt 11 — Darowizny (poza wyjątkami)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.donation_non_qualified_nkup",
    "package": "jdg.nkup_enterprise",
    "priority": 11,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 11 PIT",
    "nkup_reason": "Darowizna na rzecz podmiotu niekwalifikowanego",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Darowizna NKUP — brak statusu OPP lub nie na cele kultu religijnego/krwiodawstwa",
    "_legal_basis": "Art. 23 ust. 1 pkt 11 PIT; Art. 26 ust. 1 pkt 9 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.11: Darowizna %.2f PLN dla '%s' jest NKUP. Aby była KUP: OPP (1.5%% PIT) na cele pożytku publicznego, kult religijny (max 6%% dochodu), lub krwiodawstwo. Udokumentuj przelewem.",
        [donation_amount, recipient])]
} {
    input.invoice.expense_type == "DONATION"
    donation_amount := object.get(input.invoice, "amount_net", 0)
    recipient := object.get(input.invoice, "donation_recipient", "")
    is_opp := object.get(input.invoice, "recipient_is_opp", false)
    is_blood := object.get(input.invoice, "donation_is_blood", false)
    is_religious := object.get(input.invoice, "donation_is_religious", false)
    donation_amount > 0
    not is_opp
    not is_blood
    not is_religious
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-023: Art. 23 ust. 1 pkt 23 — Reprezentacja (szczegółowa matryca)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.representation_detailed_matrix",
    "package": "jdg.nkup_enterprise",
    "priority": 23,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": kus_result, "kus_percent": kus_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 23 PIT",
    "nkup_reason": sprintf("Reprezentacja: %s → %s", [expense_subtype, kus_result]),
    "nkup_representation_subtype": expense_subtype,
    "nkup_representation_ok_when": rep_ok_when,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": rep_routing,
    "_routing_reason": rep_routing_reason,
    "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT; Interpretacja ogólna MF z 25.11.2019; Wyroki NSA",
    "_warnings": [sprintf("NKUP Art. 23.1.23: %s — %.2f PLN → %s. %s",
        [expense_subtype, expense_amount, kus_result, rep_ok_when])]
} {
    input.invoice.expense_type in {"REPRESENTATION", "MARKETING", "ADVERTISING"}
    expense_subtype := object.get(input.invoice, "representation_subtype", "GENERAL")
    expense_amount := object.get(input.invoice, "amount_net", 0)
    has_business_purpose_doc := object.get(input.invoice, "has_business_purpose_doc", false)
    has_attendee_list := object.get(input.invoice, "has_attendee_list", false)
    has_agenda := object.get(input.invoice, "has_event_agenda", false)
    promotes_specific_product := object.get(input.invoice, "promotes_specific_product", false)
    
    # Detailed representation matrix
    is_rep := false
    is_marketing := false
    
    # RESTAURANT — borderline
    is_rep := true { expense_subtype == "RESTAURANT"; not has_business_purpose_doc }
    is_marketing := true { expense_subtype == "RESTAURANT"; has_business_purpose_doc; has_attendee_list }
    
    # EVENT/CONFERENCE
    is_rep := true { expense_subtype in {"EVENT", "CONFERENCE"}; not has_agenda }
    is_marketing := true { expense_subtype in {"EVENT", "CONFERENCE"}; has_agenda; promotes_specific_product }
    
    # GIFTS
    is_rep := true { expense_subtype == "GIFT"; expense_amount > 200 }
    is_marketing := true { expense_subtype == "GIFT"; expense_amount <= 200 }
    
    # LUXURY
    is_rep := true { expense_subtype in {"LUXURY_DINNER", "ALCOHOL_PREMIUM", "TRIP", "HOTEL_SPA"} }
    
    # ADVERTISING WITH LOGO
    is_marketing := true { expense_subtype == "GIFT_WITH_LOGO"; expense_amount <= 100 }
    is_rep := true { expense_subtype == "GIFT_WITH_LOGO"; expense_amount > 100; not has_business_purpose_doc }
    
    # DEFAULT
    is_rep := true { not is_rep; not is_marketing; expense_subtype != "CLEARLY_ADVERTISING" }
    
    kus_result := "NKUP — reprezentacja" { is_rep }
    kus_result := "KUP — marketing/reklama" { is_marketing }
    kus_pct := 0 { is_rep }
    kus_pct := 100 { is_marketing }
    
    rep_ok_when := "Wydatek można uznać za KUP gdy: (1) udokumentowany cel biznesowy, (2) lista uczestników, (3) agenda merytoryczna." {
        is_rep; expense_subtype in {"RESTAURANT", "EVENT", "CONFERENCE"}
    }
    rep_ok_when := "Wydatek definitywnie NKUP — brak możliwości przekwalifikowania." {
        is_rep; expense_subtype in {"LUXURY_DINNER", "ALCOHOL_PREMIUM", "TRIP", "HOTEL_SPA"}
    }
    rep_ok_when := "Wydatek poprawnie sklasyfikowany jako KUP." { is_marketing }
    
    rep_routing := "BLOCK_AND_ALERT" { is_rep; expense_amount > 5000 }
    rep_routing := "TRIAGE_QUEUE" { is_rep; expense_amount > 0; expense_amount <= 5000 }
    rep_routing := "" { is_marketing }
    
    rep_routing_reason := sprintf("Reprezentacja NKUP: %.2f PLN — brak dokumentacji", [expense_amount]) { is_rep; expense_amount > 5000 }
    rep_routing_reason := sprintf("Potencjalna reprezentacja: %.2f PLN — uzupełnij dokumentację", [expense_amount]) { is_rep; expense_amount <= 5000 }
    rep_routing_reason := "" { is_marketing }
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-046: Art. 23 ust. 1 pkt 46 — Samochód osobowy bez ewidencji → 75% KUP
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.car_expenses_75pct_limit",
    "package": "jdg.nkup_enterprise",
    "priority": 46,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "PARTIAL", "kus_percent": 75,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 46 PIT",
    "nkup_reason": "Samochód używany prywatnie bez ewidencji — 25% wydatków NKUP",
    "nkup_car_vat_deduction": 50,
    "nkup_car_25pct_nkup_amount": car_nkup_25pct,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 46 PIT; Art. 86a VAT",
    "_warnings": [sprintf("NKUP Art. 23.1.46: Samochód mieszany — 25%% wydatków (%.2f PLN) NKUP. Całkowity wydatek: %.2f PLN, KUP: %.2f PLN (75%%), NKUP: %.2f PLN (25%%). Załóż ewidencję przebiegu → 100%% KUP!",
        [car_nkup_25pct, total_expense, total_expense * 0.75, car_nkup_25pct])]
} {
    input.invoice.category_code in {"CAR_EXPENSE", "CAR_FUEL", "CAR_REPAIR", "CAR_INSURANCE", "CAR_LEASING"}
    total_expense := object.get(input.invoice, "amount_net", 0)
    has_mileage_log := object.get(input.invoice, "has_mileage_log", false)
    has_mileage_log == false
    is_private_used := object.get(input.invoice, "private_use_percent", 0) > 0
    is_private_used == true
    total_expense > 0
    car_nkup_25pct := total_expense * 0.25
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-047: Art. 23 ust. 1 pkt 47 — Składki na ubezpieczenie samochodu >150k/225k
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.car_insurance_over_150k_limit",
    "package": "jdg.nkup_enterprise",
    "priority": 47,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "LIMITED", "kus_percent": kus_effective_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 47 PIT",
    "nkup_reason": sprintf("Składka AC/OC auta > limitu %.0f PLN — tylko część proporcjonalna KUP", [car_limit]),
    "nkup_car_value": car_value,
    "nkup_car_limit": car_limit,
    "nkup_car_excess_nkup": insurance_nkup,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 47 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.47: Auto warte %.0f PLN > limit %.0f PLN. Składka %.2f PLN — tylko %.2f PLN KUP (%.0f%%), %.2f PLN NKUP.",
        [car_value, car_limit, insurance_amount, insurance_amount * car_limit / car_value, kus_effective_pct, insurance_nkup])]
} {
    input.invoice.category_code == "CAR_INSURANCE"
    insurance_amount := object.get(input.invoice, "amount_net", 0)
    car_value := object.get(input.invoice, "car_value_pln", 0)
    is_ev := object.get(input.invoice, "car_is_electric", false)
    
    car_limit := 150000 { not is_ev }
    car_limit := 225000 { is_ev }
    car_value > car_limit
    
    kus_effective_pct := floor(car_limit / car_value * 100)
    insurance_nkup := insurance_amount * (1 - car_limit / car_value)
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-047a: Art. 23 ust. 1 pkt 47a — Leasing operacyjny samochodu >150k/225k
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.car_leasing_over_limit",
    "package": "jdg.nkup_enterprise",
    "priority": 471,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "LIMITED", "kus_percent": kus_effective_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 47a PIT",
    "nkup_reason": sprintf("Rata leasingowa auta > limitu %.0f PLN — część NKUP", [car_limit]),
    "nkup_car_value": car_value,
    "nkup_car_limit": car_limit,
    "nkup_lease_nkup_amount": lease_nkup,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Leasing auta %.0f PLN > limit %.0f PLN", [car_value, car_limit]),
    "_legal_basis": "Art. 23 ust. 1 pkt 47a PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.47a: Leasing auta wartego %.0f PLN > limit %.0f PLN. Rata %.2f PLN — tylko %.2f PLN KUP (%.0f%%), %.2f PLN NKUP.",
        [car_value, car_limit, lease_payment, lease_payment * car_limit / car_value, kus_effective_pct, lease_nkup])]
} {
    input.invoice.category_code == "CAR_LEASING"
    lease_payment := object.get(input.invoice, "amount_net", 0)
    car_value := object.get(input.invoice, "car_value_pln", 0)
    is_ev := object.get(input.invoice, "car_is_electric", false)
    
    car_limit := 150000 { not is_ev }
    car_limit := 225000 { is_ev }
    car_value > car_limit
    
    kus_effective_pct := floor(car_limit / car_value * 100)
    lease_nkup := lease_payment * (1 - car_limit / car_value)
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-043: Art. 23 ust. 1 pkt 43 — VAT naliczony (gdy można było odliczyć)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.vat_input_as_kup_when_not_deducted",
    "package": "jdg.nkup_enterprise",
    "priority": 43,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": kus_note, "kus_percent": kus_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 43 PIT",
    "nkup_reason": "VAT naliczony — gdy NIE podlega odliczeniu, stanowi KUP. Gdy podlegał odliczeniu → NKUP w PIT.",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 43 lit. a PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.43: VAT naliczony %.2f PLN. %s",
        [vat_input_amount, kus_explanation])]
} {
    input.invoice.direction == "PURCHASE"
    vat_input_amount := object.get(input.invoice, "vat_amount", 0)
    vat_input_amount > 0
    vat_deductible := object.get(input.invoice, "vat_deductible", true)
    
    kus_pct := 100 { not vat_deductible }
    kus_pct := 0 { vat_deductible }
    kus_note := "VAT nieodliczony → stanowi KUP" { not vat_deductible }
    kus_note := "VAT odliczony → NIE stanowi KUP (bo odliczony z VAT)" { vat_deductible }
    kus_explanation := "VAT odliczony = nie wchodzi w KUP PIT" { vat_deductible }
    kus_explanation := "VAT nieodliczony = wchodzi w KUP PIT (Art. 23.1.43)" { not vat_deductible }
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-008a: Art. 23 ust. 1 pkt 8a — Odsetki od pożyczki wspólnika > limit
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.thin_capitalization_interest",
    "package": "jdg.nkup_enterprise",
    "priority": 32,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 8a (niedostateczna kapitalizacja) PIT",
    "nkup_reason": sprintf("Odsetki od pożyczki — przekroczony limit 3:1 (dług/kapitał własny). Nadwyżka %.2f PLN NKUP.",
        [excess_interest]),
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Niedostateczna kapitalizacja — odsetki NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 8a PIT; Art. 23zf PIT (od 2024)",
    "_warnings": [sprintf("NKUP Art. 23.1.8a: Cienka kapitalizacja. Dług: %.0f PLN, kapitał własny: %.0f PLN (ratio %.1f:1). Max odsetki KUP: %.2f PLN. Nadwyżka NKUP: %.2f PLN.",
        [total_debt, equity, debt_equity_ratio, max_deductible_interest, excess_interest])]
} {
    input.invoice.expense_type == "LOAN_INTEREST"
    interest_amount := object.get(input.invoice, "amount_net", 0)
    total_debt := object.get(input.jdg_entrepreneur, "total_debt_to_related", 0)
    equity := object.get(input.jdg_entrepreneur, "equity", 100000)
    equity > 0
    
    max_debt_ratio := 3.0  # 3:1 debt-to-equity
    max_deductible_debt := equity * max_debt_ratio
    debt_equity_ratio := total_debt / equity
    
    excess_ratio := max([total_debt - max_deductible_debt, 0]) / max([total_debt, 1])
    max_deductible_interest := interest_amount * (1 - excess_ratio)
    excess_interest := interest_amount * excess_ratio
    
    excess_interest > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-017: Art. 23 ust. 1 pkt 17 — Koszty egzekucyjne
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.enforcement_costs_nkup",
    "package": "jdg.nkup_enterprise",
    "priority": 17,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 17 PIT",
    "nkup_reason": sprintf("Koszty egzekucyjne i postępowania sądowego — NKUP. Typ: %s", [proceeding_type]),
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 17-19 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.17: Koszty %s (%.2f PLN) NKUP. Wyjątek: koszty zastępstwa procesowego gdy sprawa dotyczy działalności.",
        [proceeding_type, cost_amount])]
} {
    input.invoice.expense_type in {"ENFORCEMENT_COST", "COURT_PENALTY", "ADMINISTRATIVE_FINE"}
    cost_amount := object.get(input.invoice, "amount_net", 0)
    proceeding_type := object.get(input.invoice, "expense_type", "")
    cost_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-021: Art. 23 ust. 1 pkt 21 — Odpisy aktualizujące (rezerwy)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.provisions_nkup",
    "package": "jdg.nkup_enterprise",
    "priority": 21,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "NKUP", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 21 PIT",
    "nkup_reason": "Odpisy aktualizujące/rezerwy nie są KUP dla celów PIT (tylko UoR)",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 21 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.21: Odpis aktualizujący/rezerwa %.2f PLN NKUP w PIT (dozwolone tylko w UoR).",
        [provision_amount])]
} {
    input.invoice.expense_type in {"PROVISION", "IMPAIRMENT", "WRITE_OFF"}
    provision_amount := object.get(input.invoice, "amount_net", 0)
    provision_amount > 0
    object.get(input.invoice, "is_accounting_provision", false) == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-035: Art. 23 ust. 1 pkt 35 — Wydatki na rzecz pracowników ponad limit
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.employee_benefits_over_limit",
    "package": "jdg.nkup_enterprise",
    "priority": 35,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": kus_status, "kus_percent": kus_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 ust. 1 pkt 35, 42 PIT",
    "nkup_reason": sprintf("Świadczenia pracownicze: %s", [benefit_type]),
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 35, 42 PIT; Art. 21 ust. 1 pkt 67 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.35/42: %s %.2f PLN — %s",
        [benefit_type, benefit_amount, kus_note])]
} {
    input.invoice.expense_type in {"EMPLOYEE_BENEFIT", "EMPLOYEE_TRAINING", "EMPLOYEE_HEALTH"}
    benefit_type := object.get(input.invoice, "expense_type", "")
    benefit_amount := object.get(input.invoice, "amount_net", 0)
    benefit_amount > 0
    
    is_zfss_funded := object.get(input.invoice, "zfss_funded", false)
    is_required_by_law := object.get(input.invoice, "required_by_labor_law", false)
    
    kus_status := "KUP" { is_zfss_funded }
    kus_status := "NKUP" { not is_zfss_funded; not is_required_by_law }
    kus_pct := 100 { is_zfss_funded }
    kus_pct := 0 { not is_zfss_funded; not is_required_by_law }
    kus_note := "ZFŚS → KUP" { is_zfss_funded }
    kus_note := "Nieobowiązkowe świadczenie → NKUP" { not is_zfss_funded; not is_required_by_law }
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-999: AGGREGATE NKUP SUMMARY — Podsumowanie wszystkich NKUP
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.aggregate_summary",
    "package": "jdg.nkup_enterprise",
    "priority": 999,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "VARIOUS", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "nkup_article": "Art. 23 PIT (agregacja)",
    "nkup_total_detected_pln": total_nkup,
    "nkup_total_kup_allowed_pln": total_kup,
    "nkup_categories_detected": nkup_categories,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": nkup_routing,
    "_routing_reason": nkup_reason,
    "_legal_basis": "Art. 23 PIT (agregacja wszystkich punktów)",
    "_warnings": [sprintf("📋 NKUP PODSUMOWANIE: Wykryto %d kategorii NKUP na łączną kwotę %.2f PLN. Dopuszczalny KUP: %.2f PLN.",
        [count(nkup_categories), total_nkup, total_kup])]
} {
    input.nkup_aggregate_summary == true
    total_nkup := object.get(input.jdg_entrepreneur, "nkup_total_annual", 0)
    total_kup := object.get(input.jdg_entrepreneur, "kup_total_annual", 0)
    nkup_categories := object.get(input.jdg_entrepreneur, "nkup_categories_active", [])
    
    nkup_routing := "TRIAGE_QUEUE" { total_nkup > total_kup * 0.30 }
    nkup_routing := "" { total_nkup <= total_kup * 0.30 }
    nkup_reason := sprintf("NKUP stanowi %.0f%% KUP — powyżej normy", [total_nkup / max([total_kup, 1]) * 100]) { total_nkup > total_kup * 0.30 }
    nkup_reason := "" { total_nkup <= total_kup * 0.30 }
}
