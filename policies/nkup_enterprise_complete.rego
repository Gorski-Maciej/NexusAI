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
    "priority": 1,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 10,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 11,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 23,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 46,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 47,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 471,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 43,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 32,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 17,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 21,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
    "priority": 35,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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



# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-002: Art. 23 ust. 1 pkt 2 — Wydatki na cele objęte protokołem
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_2_covered_by_protocol",
    "package": "jdg.nkup_enterprise", "priority": 2,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 2 PIT",
    "nkup_reason": "Wydatki na cele objęte protokołem — NKUP",
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 2 PIT",
    "_warnings": ["NKUP Art. 23.1.2: Wydatek na cel objęty protokołem nie stanowi KUP."]
} {
    input.invoice.expense_type == "PROTOKOL_COVERED"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-003: Art. 23 ust. 1 pkt 3 — Dodatki Dla Ziemi
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_3_land_supplements",
    "package": "jdg.nkup_enterprise", "priority": 3,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 3 PIT",
    "nkup_reason": "Dodatki Dla Ziemi — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 3 PIT",
    "_warnings": ["NKUP Art. 23.1.3: Dodatki Dla Ziemi nie stanowią KUP."]
} {
    input.invoice.expense_type == "LAND_SUPPLEMENT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-004: Art. 23 ust. 1 pkt 4 — Kary, grzywny, odszkodowania karne (CRITICAL)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_4_penalties_fines",
    "package": "jdg.nkup_enterprise", "priority": 4,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 4 PIT",
    "nkup_reason": sprintf("Kary, grzywny, odszkodowania karne — NKUP. Typ: %s", [penalty_type]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Kara/grzywna NKUP — konieczna korekta",
    "_legal_basis": "Art. 23 ust. 1 pkt 4 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.4: %s %.2f PLN — kary, grzywny i odszkodowania karne NIGDY nie są KUP!", [penalty_type, penalty_amount])]
} {
    input.invoice.expense_type in {"PENALTY", "FINE", "PUNITIVE_DAMAGES"}
    penalty_type := object.get(input.invoice, "expense_type", "KARA")
    penalty_amount := object.get(input.invoice, "amount_net", 0)
    penalty_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-005: Art. 23 ust. 1 pkt 5 — Podatki i opłaty niezaliczone do KUP
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_5_taxes_not_kup",
    "package": "jdg.nkup_enterprise", "priority": 5,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 5 PIT",
    "nkup_reason": sprintf("Podatek/opłata %s — NKUP (niezaliczone do KUP)", [tax_name]),
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 5 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.5: %s %.2f PLN — podatek niezaliczony do KUP w PIT.", [tax_name, tax_amount])]
} {
    input.invoice.expense_type in {"TAX_NOT_KUP", "PROPERTY_TAX_PRIVATE", "INHERITANCE_TAX"}
    tax_name := object.get(input.invoice, "expense_type", "PODATEK")
    tax_amount := object.get(input.invoice, "amount_net", 0)
    tax_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-006: Art. 23 ust. 1 pkt 6 — Wydatki zbrojeniowe (CRITICAL)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_6_armament_expenses",
    "package": "jdg.nkup_enterprise", "priority": 6,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 6 PIT",
    "nkup_reason": "Wydatki zbrojeniowe — NKUP",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Wydatki zbrojeniowe NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 6 PIT",
    "_warnings": ["NKUP Art. 23.1.6: Wydatki zbrojeniowe NIE stanowią KUP!"]
} {
    input.invoice.expense_type in {"ARMAMENT", "WEAPONS", "AMMUNITION"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-007: Art. 23 ust. 1 pkt 7 — Wydatki mieszkaniowe prywatne
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_7_private_housing",
    "package": "jdg.nkup_enterprise", "priority": 7,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 7 PIT",
    "nkup_reason": sprintf("Wydatek mieszkaniowy: %s — NKUP", [housing_desc]),
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 7 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.7: %s %.2f PLN — wydatki mieszkaniowe prywatne NKUP.", [housing_desc, housing_amount])]
} {
    input.invoice.expense_type in {"PRIVATE_RENT", "HOME_RENOVATION", "PRIVATE_UTILITIES"}
    housing_desc := object.get(input.invoice, "description", "mieszkanie")
    housing_amount := object.get(input.invoice, "amount_net", 0)
    housing_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-008: Art. 23 ust. 1 pkt 8 — Odzież niereprezentacyjna
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_8_clothing",
    "package": "jdg.nkup_enterprise", "priority": 8,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 8 PIT",
    "nkup_reason": "Odzież niereprezentacyjna — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 8 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.8: Odzież %.2f PLN (%s) — NKUP chyba że służbowa z logo firmy.", [clothing_amount, clothing_desc])]
} {
    input.invoice.expense_type in {"CLOTHING", "FOOTWEAR", "WARDROBE"}
    object.get(input.invoice, "has_company_logo", false) == false
    clothing_amount := object.get(input.invoice, "amount_net", 0)
    clothing_desc := object.get(input.invoice, "description", "odzież")
    clothing_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-009: Art. 23 ust. 1 pkt 9 — Raty z umów najmu
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_9_lease_installments",
    "package": "jdg.nkup_enterprise", "priority": 9,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 9 PIT",
    "nkup_reason": "Raty z umów najmu — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 9 PIT",
    "_warnings": ["NKUP Art. 23.1.9: Raty z umów najmu — klasa NKUP."]
} {
    input.invoice.expense_type == "LEASE_INSTALLMENT_NKUP"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-012: Art. 23 ust. 1 pkt 12 — Spłata kapitału pożyczki
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_12_loan_principal_repayment",
    "package": "jdg.nkup_enterprise", "priority": 12,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 12 PIT",
    "nkup_reason": sprintf("Spłata kapitału pożyczki %.2f PLN — NKUP (tylko odsetki KUP)", [principal_amount]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Spłata kapitału jako KUP — błąd",
    "_legal_basis": "Art. 23 ust. 1 pkt 12 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.12: Spłata kapitału %.2f PLN to NIE KUP! Tylko ODSETKI od pożyczki są KUP.", [principal_amount])]
} {
    input.invoice.expense_type == "LOAN_PRINCIPAL"
    principal_amount := object.get(input.invoice, "amount_net", 0)
    principal_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-013: Art. 23 ust. 1 pkt 13 — Zapłata za zakup niezgodny z przepisami
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_13_illegal_purchase",
    "package": "jdg.nkup_enterprise", "priority": 13,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 13 PIT",
    "nkup_reason": "Zapłata za zakup niezgodny z przepisami — NKUP",
    "_routing": "BLOCK_AND_ALERT",
    "_legal_basis": "Art. 23 ust. 1 pkt 13 PIT",
    "_warnings": ["NKUP Art. 23.1.13: Zakup niezgodny z przepisami — NKUP!"]
} {
    input.invoice.expense_type == "ILLEGAL_PURCHASE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-014: Art. 23 ust. 1 pkt 14 — Wydatki na wyroby akcyzowe
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_14_excise_goods",
    "package": "jdg.nkup_enterprise", "priority": 14,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 14 PIT",
    "nkup_reason": "Wydatki na wyroby akcyzowe — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 14 PIT",
    "_warnings": ["NKUP Art. 23.1.14: Wyroby akcyzowe — NKUP."]
} {
    input.invoice.expense_type == "EXCISE_GOODS"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-015: Art. 23 ust. 1 pkt 15 — Rezerwy nieuznane w UoR
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_15_provisions_non_uor",
    "package": "jdg.nkup_enterprise", "priority": 15,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 15 PIT",
    "nkup_reason": "Rezerwy nieuznane w UoR — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 15 PIT",
    "_warnings": ["NKUP Art. 23.1.15: Rezerwy nieuznane w UoR — NKUP w PIT."]
} {
    input.invoice.expense_type == "NON_UOR_PROVISION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-016: Art. 23 ust. 1 pkt 16 — Wydatki na cele osobiste
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_16_personal_expenses",
    "package": "jdg.nkup_enterprise", "priority": 16,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 16 PIT",
    "nkup_reason": "Wydatki na cele osobiste — NKUP",
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 16 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.16: Wydatek osobisty %.2f PLN (%s) — NKUP.", [personal_amount, personal_desc])]
} {
    input.invoice.expense_type in {"PERSONAL_EXPENSE", "GROCERIES", "VACATION"}
    personal_amount := object.get(input.invoice, "amount_net", 0)
    personal_desc := object.get(input.invoice, "description", "osobiste")
    personal_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-018: Art. 23 ust. 1 pkt 18 — Odsetki budżetowe i od zaległości
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_18_budget_interest",
    "package": "jdg.nkup_enterprise", "priority": 18,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 18 PIT",
    "nkup_reason": sprintf("Odsetki budżetowe %.2f PLN — NKUP", [interest_amount]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Odsetki budżetowe NKUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 18 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.18: Odsetki budżetowe/od zaległości %.2f PLN — NIE stanowią KUP.", [interest_amount])]
} {
    input.invoice.expense_type in {"BUDGET_INTEREST", "TAX_ARREARS_INTEREST"}
    interest_amount := object.get(input.invoice, "amount_net", 0)
    interest_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-019: Art. 23 ust. 1 pkt 19 — Kary umowne i odszkodowania
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_19_contractual_penalties",
    "package": "jdg.nkup_enterprise", "priority": 19,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 19 PIT",
    "nkup_reason": sprintf("Kara umowna %.2f PLN — NKUP", [penalty_amount]),
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 19 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.19: Kara umowna/odszkodowanie %.2f PLN — NKUP (chyba że związane z otrzymanym przychodem).", [penalty_amount])]
} {
    input.invoice.expense_type in {"CONTRACTUAL_PENALTY", "DAMAGES_PAID"}
    penalty_amount := object.get(input.invoice, "amount_net", 0)
    penalty_amount > 0
    object.get(input.invoice, "related_to_revenue", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-020: Art. 23 ust. 1 pkt 20 — Wydatki na zakup gruntów (NKUP — amort. tylko budynki)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_20_land_purchase",
    "package": "jdg.nkup_enterprise", "priority": 20,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 20 PIT",
    "nkup_reason": sprintf("Zakup gruntu %.2f PLN — NKUP (grunty nie podlegają amortyzacji)", [land_value]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Grunt jako KUP — błąd",
    "_legal_basis": "Art. 23 ust. 1 pkt 20 PIT; Art. 22c pkt 1 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.20: Grunt %.2f PLN — NIE podlega amortyzacji = NKUP w kosztach bezpośrednich.", [land_value])]
} {
    input.invoice.expense_type == "LAND_PURCHASE"
    land_value := object.get(input.invoice, "amount_net", 0)
    land_value > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-022: Art. 23 ust. 1 pkt 22 — Wydatki na organizacje non-profit
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_22_nonprofit_contributions",
    "package": "jdg.nkup_enterprise", "priority": 22,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 22 PIT",
    "nkup_reason": "Wydatki na organizacje non-profit (nie OPP) — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 22 PIT",
    "_warnings": ["NKUP Art. 23.1.22: Wydatki na nie-OPP — NKUP. Tylko darowizny na OPP są KUP (max 6% dochodu)."]
} {
    input.invoice.expense_type == "NONPROFIT_CONTRIBUTION"
    object.get(input.invoice, "recipient_is_opp", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-024: Art. 23 ust. 1 pkt 24 — Koszty postępowania sądowego (niezwiązane z działalnością)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_24_court_costs_unrelated",
    "package": "jdg.nkup_enterprise", "priority": 24,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 24 PIT",
    "nkup_reason": "Koszty postępowania sądowego niezwiązane z działalnością — NKUP",
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 24 PIT",
    "_warnings": ["NKUP Art. 23.1.24: Koszty sądowe niezwiązane z JDG — NKUP."]
} {
    input.invoice.expense_type == "COURT_COSTS"
    object.get(input.invoice, "related_to_business", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-025: Art. 23 ust. 1 pkt 25 — Wydatki reklamowe niestandardowe
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_25_nonstandard_advertising",
    "package": "jdg.nkup_enterprise", "priority": 25,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 25 PIT",
    "nkup_reason": "Wydatki reklamowe niestandardowe — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 25 PIT",
    "_warnings": ["NKUP Art. 23.1.25: Niestandardowe wydatki reklamowe — klasa NKUP."]
} {
    input.invoice.expense_type == "NONSTANDARD_ADVERTISING"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-026: Art. 23 ust. 1 pkt 26 — Wydatki na zakup/wytworzenie ŚT (podwójne księgowanie)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_26_double_counting_fa",
    "package": "jdg.nkup_enterprise", "priority": 26,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 26 PIT",
    "nkup_reason": "Wydatek na ŚT ujęty bezpośrednio zamiast przez amortyzację — NKUP",
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 26 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.26: ŚT %.2f PLN ujęty bezpośrednio — rozliczaj przez amortyzację!", [fa_amount])]
} {
    input.invoice.expense_type == "FIXED_ASSET_DIRECT"
    fa_amount := object.get(input.invoice, "amount_net", 0)
    fa_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-027: Art. 23 ust. 1 pkt 27 — WNiP ujęte bezpośrednio
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_27_intangible_direct",
    "package": "jdg.nkup_enterprise", "priority": 27,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 27 PIT",
    "nkup_reason": "WNiP ujęte bezpośrednio — rozliczaj przez amortyzację",
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 27 PIT",
    "_warnings": ["NKUP Art. 23.1.27: WNiP ujęte bezpośrednio — NKUP. Amortyzuj przez okres umowny."]
} {
    input.invoice.expense_type == "INTANGIBLE_DIRECT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-028: Art. 23 ust. 1 pkt 28 — Inwestycje w obcych środkach
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_28_investment_in_foreign_assets",
    "package": "jdg.nkup_enterprise", "priority": 28,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 28 PIT",
    "nkup_reason": "Inwestycje w obcych środkach trwałych — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 28 PIT",
    "_warnings": ["NKUP Art. 23.1.28: Inwestycje w obcych ŚT — NKUP jako wydatek bezpośredni."]
} {
    input.invoice.expense_type == "INVESTMENT_FOREIGN_FA"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-029: Art. 23 ust. 1 pkt 29 — Koszty organizacji produkcji
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_29_production_organization",
    "package": "jdg.nkup_enterprise", "priority": 29,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 29 PIT",
    "nkup_reason": "Koszty organizacji produkcji — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 29 PIT",
    "_warnings": ["NKUP Art. 23.1.29: Koszty organizacji produkcji — NKUP."]
} {
    input.invoice.expense_type == "PRODUCTION_ORG_COST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-030: Art. 23 ust. 1 pkt 30 — Koszty zaniechanych inwestycji
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_30_abandoned_investments",
    "package": "jdg.nkup_enterprise", "priority": 30,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 30 PIT",
    "nkup_reason": "Koszty zaniechanych inwestycji — NKUP",
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 30 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.30: Zaniechana inwestycja %.2f PLN — NKUP.", [abandoned_amount])]
} {
    input.invoice.expense_type == "ABANDONED_INVESTMENT"
    abandoned_amount := object.get(input.invoice, "amount_net", 0)
    abandoned_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-031: Art. 23 ust. 1 pkt 31 — Straty w środkach trwałych
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_31_fixed_asset_losses",
    "package": "jdg.nkup_enterprise", "priority": 31,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 31 PIT",
    "nkup_reason": sprintf("Strata w ŚT %.2f PLN — NKUP (poza likwidacją)", [loss_amount]),
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 31 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.31: Strata w ŚT %.2f PLN — NKUP chyba że likwidacja (wtedy strata = KUP).", [loss_amount])]
} {
    input.invoice.expense_type == "FA_LOSS"
    loss_amount := object.get(input.invoice, "amount_net", 0)
    loss_amount > 0
    object.get(input.invoice, "is_liquidation", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-033: Art. 23 ust. 1 pkt 33 — Odsetki od pożyczek ponad limit
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_33_excess_loan_interest",
    "package": "jdg.nkup_enterprise", "priority": 33,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 33 PIT",
    "nkup_reason": sprintf("Odsetki od pożyczki %.2f PLN ponad limit — NKUP", [excess_amount]),
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 33 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.33: Nadwyżka odsetek %.2f PLN ponad limit — NKUP.", [excess_amount])]
} {
    input.invoice.expense_type == "EXCESS_LOAN_INTEREST"
    excess_amount := object.get(input.invoice, "amount_net", 0)
    excess_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-034: Art. 23 ust. 1 pkt 34 — Wydatki na nabycie udziałów/akcji
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_34_share_acquisition",
    "package": "jdg.nkup_enterprise", "priority": 34,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 34 PIT",
    "nkup_reason": "Wydatki na nabycie udziałów/akcji — NKUP (koszt przy sprzedaży)",
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 34 PIT",
    "_warnings": ["NKUP Art. 23.1.34: Nabycie udziałów/akcji — NKUP w momencie zakupu. Koszt uzyskania przychodu dopiero przy sprzedaży."]
} {
    input.invoice.expense_type == "SHARE_ACQUISITION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-036: Art. 23 ust. 1 pkt 36 — Składki ZUS w części pracownika
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_36_zus_employee_portion",
    "package": "jdg.nkup_enterprise", "priority": 36,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 36 PIT",
    "nkup_reason": "Składki ZUS w części pracownika — NKUP (to wynagrodzenie netto)",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 36 PIT",
    "_warnings": ["NKUP Art. 23.1.36: Składki ZUS pracownika — NKUP (finansowane przez pracownika z wynagrodzenia)."]
} {
    input.invoice.expense_type == "ZUS_EMPLOYEE_PORTION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-037: Art. 23 ust. 1 pkt 37 — Wydatki na PFRON
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_37_pfron_contributions",
    "package": "jdg.nkup_enterprise", "priority": 37,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 37 PIT",
    "nkup_reason": "Wpłaty na PFRON — warunkowo NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 37 PIT",
    "_warnings": ["NKUP Art. 23.1.37: Wpłaty na PFRON — klasa NKUP."]
} {
    input.invoice.expense_type == "PFRON"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-038: Art. 23 ust. 1 pkt 38 — Wyżywienie pracowników ponad limit
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_38_employee_meals_excess",
    "package": "jdg.nkup_enterprise", "priority": 38,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 38 PIT",
    "nkup_reason": sprintf("Wyżywienie pracowników %.2f PLN ponad limit — NKUP", [meal_excess]),
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 38 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.38: Wyżywienie ponad limit dzienny %.2f PLN — NKUP.", [meal_excess])]
} {
    input.invoice.expense_type == "EMPLOYEE_MEALS"
    daily_limit := 15.00  # PLN per day
    meal_amount := object.get(input.invoice, "amount_net", 0)
    employees := max([object.get(input.invoice, "employee_count", 1), 1])
    meal_per_employee := meal_amount / employees
    meal_excess := max([0, meal_amount - daily_limit * employees])
    meal_excess > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-039: Art. 23 ust. 1 pkt 39 — Odzież służbowa nieoznakowana
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_39_unmarked_workwear",
    "package": "jdg.nkup_enterprise", "priority": 39,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 39 PIT",
    "nkup_reason": "Odzież służbowa bez oznakowania firmy — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 39 PIT",
    "_warnings": ["NKUP Art. 23.1.39: Odzież służbowa bez logo firmy — NKUP. Oznakuj logo!"]
} {
    input.invoice.expense_type == "WORKWEAR"
    object.get(input.invoice, "has_company_logo", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-040: Art. 23 ust. 1 pkt 40 — Alkohol (CRITICAL)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_40_alcohol",
    "package": "jdg.nkup_enterprise", "priority": 40,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 40 PIT",
    "nkup_reason": sprintf("Zakup alkoholu %.2f PLN — NKUP", [alcohol_amount]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Alkohol jako KUP — niedozwolone",
    "_legal_basis": "Art. 23 ust. 1 pkt 40 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.40: Alkohol %.2f PLN — KATEGORYCZNIE NKUP!", [alcohol_amount])]
} {
    input.invoice.expense_type in {"ALCOHOL", "ALCOHOL_PREMIUM"}
    alcohol_amount := object.get(input.invoice, "amount_net", 0)
    alcohol_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-041: Art. 23 ust. 1 pkt 41 — Imprezy integracyjne ponad limit
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_41_integration_events_excess",
    "package": "jdg.nkup_enterprise", "priority": 41,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 41 PIT",
    "nkup_reason": "Imprezy integracyjne ponad limit — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 41 PIT",
    "_warnings": ["NKUP Art. 23.1.41: Imprezy integracyjne ponad limit — NKUP."]
} {
    input.invoice.expense_type == "INTEGRATION_EVENT"
    event_amount := object.get(input.invoice, "amount_net", 0)
    employees := max([object.get(input.invoice, "employee_count", 1), 1])
    limit_per_person := 1000.00  # PLN per person
    event_excess := max([0, event_amount - limit_per_person * employees])
    event_excess > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-042: Art. 23 ust. 1 pkt 42 — Świadczenia urlopowe ponad limit ZFŚS
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_42_vacation_benefits_excess",
    "package": "jdg.nkup_enterprise", "priority": 42,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 42 PIT",
    "nkup_reason": "Świadczenia urlopowe ponad limit ZFŚS — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 42 PIT",
    "_warnings": ["NKUP Art. 23.1.42: Świadczenia urlopowe ponad ZFŚS — NKUP."]
} {
    input.invoice.expense_type == "VACATION_BENEFIT"
    object.get(input.invoice, "zfss_funded", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-044: Art. 23 ust. 1 pkt 44 — Składki na ubezpieczenia pracownicze
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_44_employee_insurance_non_required",
    "package": "jdg.nkup_enterprise", "priority": 44,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 44 PIT",
    "nkup_reason": "Składki na ubezpieczenia pracownicze nieobowiązkowe — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 44 PIT",
    "_warnings": ["NKUP Art. 23.1.44: Składki ubezpieczeniowe nieobowiązkowe — NKUP."]
} {
    input.invoice.expense_type == "EMPLOYEE_INSURANCE"
    object.get(input.invoice, "required_by_law", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-045: Art. 23 ust. 1 pkt 45 — Zakup paliw bez ewidencji przebiegu
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_45_fuel_no_mileage_log",
    "package": "jdg.nkup_enterprise", "priority": 45,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 45 PIT",
    "nkup_reason": sprintf("Paliwo %.2f PLN bez ewidencji przebiegu — 25%% NKUP", [fuel_nkup]),
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 45-46 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.45: Paliwo bez ewidencji — %.2f PLN NKUP (25%%).", [fuel_nkup])]
} {
    input.invoice.expense_type == "FUEL"
    object.get(input.invoice, "has_mileage_log", false) == false
    fuel_amount := object.get(input.invoice, "amount_net", 0)
    fuel_nkup := fuel_amount * 0.25
    fuel_nkup > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-048: Art. 23 ust. 1 pkt 48 — Składki członkowskie
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_48_membership_fees",
    "package": "jdg.nkup_enterprise", "priority": 48,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 48 PIT",
    "nkup_reason": sprintf("Składka członkowska w %s — NKUP", [organization]),
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 48 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.48: Składka członkowska %.2f PLN w %s — NKUP.", [fee_amount, organization])]
} {
    input.invoice.expense_type == "MEMBERSHIP_FEE"
    fee_amount := object.get(input.invoice, "amount_net", 0)
    organization := object.get(input.invoice, "description", "organizacja")
    fee_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-049: Art. 23 ust. 1 pkt 49 — Wydatki na radę nadzorczą
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_49_supervisory_board",
    "package": "jdg.nkup_enterprise", "priority": 49,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 49 PIT",
    "nkup_reason": "Wydatki na radę nadzorczą — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 49 PIT",
    "_warnings": ["NKUP Art. 23.1.49: Wydatki na radę nadzorczą — NKUP."]
} {
    input.invoice.expense_type == "SUPERVISORY_BOARD"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-050: Art. 23 ust. 1 pkt 50 — Kult religijny ponad 6% dochodu
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_50_religious_cult_excess",
    "package": "jdg.nkup_enterprise", "priority": 50,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 50 PIT",
    "nkup_reason": sprintf("Kult religijny %.2f PLN ponad 6%% dochodu — NKUP", [excess_amount]),
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 50 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.50: Darowizna na kult religijny %.2f PLN przekracza 6%% dochodu — nadwyżka NKUP.", [excess_amount])]
} {
    input.invoice.expense_type == "RELIGIOUS_DONATION"
    donation_amount := object.get(input.invoice, "amount_net", 0)
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 100000)
    limit_6pct := annual_income * 0.06
    excess_amount := max([0, donation_amount - limit_6pct])
    excess_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-051: Art. 23 ust. 1 pkt 51 — Działalność socjalna ponad ZFŚS
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_51_social_activites_excess",
    "package": "jdg.nkup_enterprise", "priority": 51,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 51 PIT",
    "nkup_reason": "Działalność socjalna ponad ZFŚS — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 51 PIT",
    "_warnings": ["NKUP Art. 23.1.51: Działalność socjalna ponad ZFŚS — NKUP."]
} {
    input.invoice.expense_type in {"SOCIAL_ACTIVITY", "SOCIAL_FUND"}
    object.get(input.invoice, "zfss_funded", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-052: Art. 23 ust. 1 pkt 52 — Ekwiwalent za pranie odzieży
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_52_laundry_equivalent",
    "package": "jdg.nkup_enterprise", "priority": 52,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 52 PIT",
    "nkup_reason": "Ekwiwalent za pranie odzieży — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 52 PIT",
    "_warnings": ["NKUP Art. 23.1.52: Ekwiwalent za pranie — NKUP."]
} {
    input.invoice.expense_type == "LAUNDRY_ALLOWANCE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-053: Art. 23 ust. 1 pkt 53 — Woda i napoje dla pracowników
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_53_water_beverages",
    "package": "jdg.nkup_enterprise", "priority": 53,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 53 PIT",
    "nkup_reason": "Zakup wody i napojów dla pracowników — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 53 PIT",
    "_warnings": ["NKUP Art. 23.1.53: Woda i napoje — NKUP (chyba że obowiązek BHP)."]
} {
    input.invoice.expense_type in {"WATER", "BEVERAGES"}
    object.get(input.invoice, "required_by_labor_law", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-054: Art. 23 ust. 1 pkt 54 — Tłumaczenia przysięgłe (prywatne)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_54_private_translations",
    "package": "jdg.nkup_enterprise", "priority": 54,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 54 PIT",
    "nkup_reason": "Tłumaczenia przysięgłe prywatne — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 54 PIT",
    "_warnings": ["NKUP Art. 23.1.54: Tłumaczenia prywatne — NKUP chyba że związane z działalnością."]
} {
    input.invoice.expense_type == "TRANSLATION"
    object.get(input.invoice, "related_to_business", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-055: Art. 23 ust. 1 pkt 55 — Studia podyplomowe niekwalifikowane
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_55_non_qualifying_studies",
    "package": "jdg.nkup_enterprise", "priority": 55,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 55 PIT",
    "nkup_reason": "Studia podyplomowe niekwalifikowane — NKUP",
    "_routing": "",
    "_legal_basis": "Art. 23 ust. 1 pkt 55 PIT",
    "_warnings": ["NKUP Art. 23.1.55: Studia podyplomowe niezwiązane z profilem JDG — NKUP."]
} {
    input.invoice.expense_type == "POSTGRADUATE_STUDIES"
    object.get(input.invoice, "related_to_business_profile", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-056: Art. 23 ust. 1 pkt 56 — Wydatki związane z dochodami wolnymi
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_56_tax_free_income_expenses",
    "package": "jdg.nkup_enterprise", "priority": 56,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 56 PIT",
    "nkup_reason": "Wydatki związane z dochodami wolnymi od podatku — NKUP",
    "_routing": "TRIAGE_QUEUE",
    "_legal_basis": "Art. 23 ust. 1 pkt 56 PIT",
    "_warnings": ["NKUP Art. 23.1.56: Wydatki na dochody wolne — NKUP (bo przychód też zwolniony)."]
} {
    input.invoice.expense_type == "TAX_FREE_INCOME_RELATED"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NKUP-057: Art. 23 ust. 1 pkt 57 — Wydatki na cele osobiste właściciela
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.nkup.point_57_owner_personal",
    "package": "jdg.nkup_enterprise", "priority": 57,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
    "kus_qualification": "NKUP", "kus_percent": 0,
    "nkup_article": "Art. 23 ust. 1 pkt 57 PIT",
    "nkup_reason": sprintf("Wydatek osobisty właściciela: %s — NKUP", [personal_item]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Wydatek osobisty właściciela jako KUP",
    "_legal_basis": "Art. 23 ust. 1 pkt 57 PIT",
    "_warnings": [sprintf("NKUP Art. 23.1.57: %s %.2f PLN — wydatek osobisty właściciela = NKUP.", [personal_item, personal_amount])]
} {
    input.invoice.expense_type in {"OWNER_PERSONAL", "OWNER_VACATION", "OWNER_HOBBY"}
    personal_item := object.get(input.invoice, "description", "osobiste")
    personal_amount := object.get(input.invoice, "amount_net", 0)
    personal_amount > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.nkup.aggregate_summary",
    "package": "jdg.nkup_enterprise",
    "priority": 999,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,
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
