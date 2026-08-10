# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE PIT MISSING RELIEFS (RAPORT 04 — P0/P1 Gap Closure)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Missing PIT Reliefs — Ulgi zidentyfikowane w Raporcie 04
# description: |
#   ENTERPRISE v8.0 — Domknięcie luk P0/P1 z Raportu 04 (PIT CORE + ULGI).
#   Dodaje brakujące reguły dla ulg:
#   - Ulga rehabilitacyjna (Art. 26 ust. 1 pkt 6 PIT) — R650-R655
#   - Ulga internetowa (Art. 26 ust. 1 pkt 6a PIT, 760 PLN) — R660-R662
#   - Ulga krwiodawstwa (Art. 26 ust. 1 pkt 9c PIT) — R670-R672
#   - Ulga na dzieci (Art. 27f PIT) — R680-R685
#   - Ulga na ekspansję (Art. 26ec PIT, 1M PLN) — R690-R693
#   - Ulga na robotyzację (Art. 26gb PIT, 50%) — R700-R703
#   - Aktywna reguła straty podatkowej (Art. 9 ust. 3 PIT) — R400-R405
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Art. 9, 26, 26ec, 26gb, 27f PIT
# package: jdg.pit.missing_reliefs
# generated_from: RAPORT_04_PIT_CORE.txt (2026-08-10)
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.missing_reliefs

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.pit.missing_reliefs.no_match",
    "package": "jdg.pit.missing_reliefs", "priority": 99999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SEKCJA A: AKTYWNA REGUŁA STRATY PODATKOWEJ (Art. 9 ust. 3 PIT)          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# P0-5: Strata podatkowa — max 5 lat, max 50% dochodu w jednym roku.
# Obecnie istniał tylko info helper P660. Ta reguła AKTYWNIE pomniejsza dochód.

# ═══════════════════════════════════════════════════════════════════════════════
# R400: loss_carry_forward_active — Aktywna reguła odliczenia straty
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.loss_carry_forward_active",
    "package": "jdg.pit.missing_reliefs",
    "priority": 400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "LOSS_CARRY_FORWARD",
    "loss_total_available": total_loss_available,
    "loss_max_deductible_this_year": max_deduction,
    "loss_actual_deducted": actual_deduction,
    "loss_remaining_after_year": remaining_loss,
    "loss_expiring_this_year": expiring_loss,
    "loss_years_tracked": loss_years,
    "_routing": loss_rt,
    "_routing_reason": sprintf("Strata: dostępne %.0f PLN, max odliczenie %.0f PLN (50%% dochodu %.0f PLN), odliczono %.0f PLN, pozostało %.0f PLN",
        [total_loss_available, max_deduction, annual_income, actual_deduction, remaining_loss]),
    "_legal_basis": "Art. 9 ust. 3 PIT (strata — max 5 lat, max 50% rocznie)",
    "_warnings": build_loss_warnings(total_loss_available, actual_deduction, remaining_loss, expiring_loss, max_deduction)
} {
    input.jdg_entrepreneur.tax_form in {"PIT_SCALE", "LINEAR"}
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    annual_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)
    annual_income > 0

    # Salda strat z lat 2021-2025
    loss_2021 := object.get(input.jdg_entrepreneur, "tax_loss_2021", 0.0)
    loss_2022 := object.get(input.jdg_entrepreneur, "tax_loss_2022", 0.0)
    loss_2023 := object.get(input.jdg_entrepreneur, "tax_loss_2023", 0.0)
    loss_2024 := object.get(input.jdg_entrepreneur, "tax_loss_2024", 0.0)
    loss_2025 := object.get(input.jdg_entrepreneur, "tax_loss_2025", 0.0)

    current_year := 2026

    # Tylko straty nie starsze niż 5 lat
    total_loss_available := 0.0
    total_loss_available := loss_2021 { current_year - 2021 <= 5 }
    total_loss_available := total_loss_available + loss_2022 { current_year - 2022 <= 5 }
    total_loss_available := total_loss_available + loss_2023 { current_year - 2023 <= 5 }
    total_loss_available := total_loss_available + loss_2024 { current_year - 2024 <= 5 }
    total_loss_available := total_loss_available + loss_2025 { current_year - 2025 <= 5 }
    total_loss_available > 0

    # Max 50% dochodu
    max_deduction := annual_income * 0.5
    actual_deduction := min([total_loss_available, max_deduction])
    remaining_loss := total_loss_available - actual_deduction

    # Strata przedawniająca się w tym roku
    expiring_loss := loss_2021 { current_year - 2021 == 5; loss_2021 > 0 }
    expiring_loss := loss_2022 { expiring_loss == 0; current_year - 2022 == 5; loss_2022 > 0 }
    expiring_loss := 0 { true }

    loss_years := []
    loss_years := array.concat(loss_years, ["2021"]) { loss_2021 > 0; current_year - 2021 <= 5 }
    loss_years := array.concat(loss_years, ["2022"]) { loss_2022 > 0; current_year - 2022 <= 5 }
    loss_years := array.concat(loss_years, ["2023"]) { loss_2023 > 0; current_year - 2023 <= 5 }
    loss_years := array.concat(loss_years, ["2024"]) { loss_2024 > 0; current_year - 2024 <= 5 }
    loss_years := array.concat(loss_years, ["2025"]) { loss_2025 > 0; current_year - 2025 <= 5 }

    loss_rt = "TRIAGE_QUEUE" { expiring_loss > 50000 }
    loss_rt = "" { true }
}

build_loss_warnings(available, deducted, remaining, expiring, max_ded) = warnings {
    lines := [
        "📊 AKTYWNA STRATA PODATKOWA",
        sprintf("   Strata dostępna: %12.0f PLN", [available]),
        sprintf("   Max odliczenie (50%%): %8.0f PLN", [max_ded]),
        sprintf("   Odliczono w tym roku: %8.0f PLN", [deducted]),
        sprintf("   Pozostało do odliczenia: %5.0f PLN", [remaining]),
    ]
    lines := array.concat(lines, [sprintf("   ⚠️ PRZEDAWNIA SIĘ: %.0f PLN — OSTATNI ROK na odliczenie!", [expiring])]) { expiring > 0 }
    lines := array.concat(lines, ["", "💡 Odliczaj stratę w pierwszej kolejności — przed ulgami B+R, IP Box i innymi!"])
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# R401: loss_carry_forward_exhausted — Strata wykorzystana w całości
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.loss_fully_used",
    "package": "jdg.pit.missing_reliefs",
    "priority": 401,
    "pit_form": pit_form,
    "loss_status": "EXHAUSTED",
    "loss_note": "Wszystkie straty z lat ubiegłych zostały w pełni rozliczone",
    "_routing": "",
    "_routing_reason": "Brak nierozliczonych strat",
    "_legal_basis": "Art. 9 ust. 3 PIT",
    "_warnings": ["✅ Brak nierozliczonych strat podatkowych — dochód nie jest pomniejszany o stratę."]
} {
    input.jdg_entrepreneur.tax_form in {"PIT_SCALE", "LINEAR"}
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    # Brak strat lub już rozliczone
    object.get(input.jdg_entrepreneur, "has_unresolved_losses", false) == false
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SEKCJA B: ULGA REHABILITACYJNA (Art. 26 ust. 1 pkt 6 PIT)               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# R650: relief_rehabilitation — Ulga rehabilitacyjna
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.rehabilitation",
    "package": "jdg.pit.missing_reliefs",
    "priority": 650,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "REHABILITATION",
    "relief_limit": "Wydatki rzeczywiste — limit na samochód: 2 280 PLN rocznie, leki: nadwyżka ponad 100 PLN/mies.",
    "relief_deductible": rehab_expenses,
    "relief_disability_group": disability_group,
    "relief_requires_documentation": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Ulga rehabilitacyjna: %.2f PLN (grupa inw.: %s)", [rehab_expenses, disability_group]),
    "_legal_basis": "Art. 26 ust. 1 pkt 6, ust. 7a-7g PIT",
    "_warnings": [sprintf("♿ ULGA REHABILITACYJNA — %.2f PLN. Grupa inwalidzka: %s. Kategorie: leki (nadwyżka >100 PLN/mies), zabiegi, sprzęt, samochód (max 2 280 PLN). WYMÓG: dokument potwierdzający niepełnosprawność + faktury/rachunki imienne.",
        [rehab_expenses, disability_group])]
} {
    input.jdg_entrepreneur.has_disability == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}

    disability_group := object.get(input.jdg_entrepreneur, "disability_group", "I")
    # Suma wydatków rehabilitacyjnych (leki, zabiegi, sprzęt, samochód do limitu)
    meds := object.get(input.jdg_entrepreneur, "rehab_meds_expenses", 0.0)
    treatments := object.get(input.jdg_entrepreneur, "rehab_treatments_expenses", 0.0)
    equipment := object.get(input.jdg_entrepreneur, "rehab_equipment_expenses", 0.0)
    car := min([object.get(input.jdg_entrepreneur, "rehab_car_expenses", 0.0), 2280.0])

    rehab_expenses := meds + treatments + equipment + car
    rehab_expenses > 0
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SEKCJA C: ULGA INTERNETOWA (Art. 26 ust. 1 pkt 6a PIT, 760 PLN)        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# R660: relief_internet — Ulga internetowa (max 760 PLN, tylko 2 kolejne lata)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.internet",
    "package": "jdg.pit.missing_reliefs",
    "priority": 660,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "INTERNET",
    "relief_limit": 760,
    "relief_deductible": min([internet_expenses, 760]),
    "relief_max_years": 2,
    "relief_years_used": years_used,
    "relief_years_remaining": max([0, 2 - years_used]),
    "_routing": internet_rt,
    "_routing_reason": sprintf("Ulga internetowa: %.2f PLN (rok %d/2)", [min([internet_expenses, 760]), years_used + 1]),
    "_legal_basis": "Art. 26 ust. 1 pkt 6a PIT (ulga internetowa — 760 PLN, 2 lata)",
    "_warnings": [sprintf("🌐 ULGA INTERNETOWA — %.2f PLN (limit 760 PLN). Rok %d z 2 dostępnych. %s",
        [min([internet_expenses, 760]), years_used + 1, warning_extra])]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}

    internet_expenses := object.get(input.jdg_entrepreneur, "internet_expenses_annual", 0.0)
    internet_expenses > 0

    years_used := object.get(input.jdg_entrepreneur, "internet_relief_years_used", 0)
    years_used < 2  # Tylko 2 kolejne lata

    internet_rt = "TRIAGE_QUEUE" { years_used == 1 }
    internet_rt = "" { true }

    warning_extra = "To OSTATNI rok tej ulgi — wykorzystaj w pełni!" { years_used == 1 }
    warning_extra = "Pamiętaj: ulga działa tylko przez 2 kolejne lata." { years_used == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R661: relief_internet_exhausted — Ulga internetowa wykorzystana
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.internet_exhausted",
    "package": "jdg.pit.missing_reliefs",
    "priority": 661,
    "pit_form": pit_form,
    "internet_relief_exhausted": true,
    "internet_relief_note": "Ulga internetowa wykorzystana — limit 2 lat osiągnięty",
    "_routing": "",
    "_routing_reason": "Ulga internetowa: 2-letni limit wykorzystany",
    "_legal_basis": "Art. 26 ust. 1 pkt 6a PIT",
    "_warnings": ["⛔ Ulga internetowa wykorzystana — limit 2 lat osiągnięty. Nie możesz już odliczać internetu w ramach tej ulgi."]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    object.get(input.jdg_entrepreneur, "internet_relief_years_used", 0) >= 2
    object.get(input.jdg_entrepreneur, "internet_expenses_annual", 0.0) > 0
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SEKCJA D: ULGA KRWIODAWSTWA (Art. 26 ust. 1 pkt 9c PIT)                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# R670: relief_blood_donation — Ulga krwiodawstwa (ekwiwalent 130 PLN/litr, max 6% dochodu)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.blood_donation",
    "package": "jdg.pit.missing_reliefs",
    "priority": 670,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "BLOOD_DONATION",
    "relief_blood_liters": blood_liters,
    "relief_blood_value_per_liter": 130.0,
    "relief_deductible": min([blood_value, max_deduction]),
    "relief_max_percent_income": 6.0,
    "_routing": "",
    "_routing_reason": sprintf("Krwiodawstwo: %.1f litrów × 130 PLN = %.2f PLN (max 6%% dochodu = %.2f PLN)",
        [blood_liters, blood_value, max_deduction]),
    "_legal_basis": "Art. 26 ust. 1 pkt 9c PIT (honorowe krwiodawstwo)",
    "_warnings": [sprintf("🩸 ULGA KRWIODAWSTWA — %.1f litrów krwi × 130 PLN/litr = %.2f PLN. Limit: 6%% dochodu (%.2f PLN). Odliczono: %.2f PLN. WYMÓG: zaświadczenie z centrum krwiodawstwa.",
        [blood_liters, blood_value, max_deduction, min([blood_value, max_deduction])])]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}

    blood_liters := object.get(input.jdg_entrepreneur, "blood_donation_liters", 0.0)
    blood_liters > 0

    blood_value := blood_liters * 130.0
    annual_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 0.0)
    max_deduction := annual_income * 0.06  # Max 6% dochodu

    blood_value > 0
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SEKCJA E: ULGA NA DZIECI (Art. 27f PIT)                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# R680: relief_child_tax_credit — Ulga na dzieci (kwoty per dziecko)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.child_tax_credit",
    "package": "jdg.pit.missing_reliefs",
    "priority": 680,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "PIT_SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "CHILD_TAX_CREDIT",
    "relief_child_count_total": total_children,
    "relief_child_eligible_count": eligible_children,
    "relief_amount_per_first_second": relief_per_child_12,
    "relief_amount_per_third": relief_per_child_3,
    "relief_amount_per_fourth_plus": relief_per_child_4p,
    "relief_total_deductible": total_relief,
    "relief_refundable": true,
    "_routing": child_rt,
    "_routing_reason": sprintf("Ulga na dzieci: %d dzieci, odliczenie %.2f PLN",
        [eligible_children, total_relief]),
    "_legal_basis": "Art. 27f PIT (ulga prorodzinna)",
    "_warnings": [sprintf("👶 ULGA NA DZIECI — %d dzieci uprawnionych z %d łącznie. Kwoty: 1 i 2 dziecko: %.2f PLN, 3 dziecko: %.2f PLN, 4+: %.2f PLN. Łączne odliczenie od podatku: %.2f PLN. UWAGA: tylko na skali PIT (PIT-36)! NIE na liniowym/ryczałcie.",
        [eligible_children, total_children, relief_per_child_12, relief_per_child_3, relief_per_child_4p, total_relief])]
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"  # TYLKO skala!
    total_children := object.get(input.jdg_entrepreneur, "children_count", 0)
    total_children > 0

    # Kwoty ulgi na dzieci (2026 — indeksowane)
    # 1 i 2 dziecko: 92.67 PLN/mies = 1112.04 PLN/rok
    # 3 dziecko: 166.67 PLN/mies = 2000.04 PLN/rok
    # 4+ dziecko: 225.00 PLN/mies = 2700.00 PLN/rok
    relief_per_child_12 := 1112.04
    relief_per_child_3 := 2000.04
    relief_per_child_4p := 2700.00

    # Obliczenia
    eligible_children := total_children
    first_two_children := min([total_children, 2])
    third_child := 1 { total_children >= 3 }
    third_child := 0 { total_children < 3 }
    fourth_plus := max([total_children - 3, 0])

    total_relief := (first_two_children * relief_per_child_12) +
        (third_child * relief_per_child_3) +
        (fourth_plus * relief_per_child_4p)

    total_relief > 0

    child_rt = "TRIAGE_QUEUE" { total_relief > 5000 }
    child_rt = "" { true }
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SEKCJA F: ULGA NA EKSPANSJĘ (Art. 26ec PIT, max 1M PLN)                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# R690: relief_expansion — Ulga na ekspansję (targi, reklama zagraniczna)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.expansion",
    "package": "jdg.pit.missing_reliefs",
    "priority": 690,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "EXPANSION",
    "relief_limit": 1000000,
    "relief_categories": ["TARGI_ZAGRANICZNE", "REKLAMA_ZAGRANICZNA", "PRZYGOTOWANIE_EKSPORTU"],
    "relief_deductible": min([expansion_costs, 1000000]),
    "relief_carry_forward_years": 6,
    "_routing": expansion_rt,
    "_routing_reason": sprintf("Ulga ekspansyjna: %.2f PLN (limit 1M PLN)", [min([expansion_costs, 1000000])]),
    "_legal_basis": "Art. 26ec PIT (ulga na ekspansję — max 1M PLN)",
    "_warnings": [sprintf("🌍 ULGA NA EKSPANSJĘ — %.2f PLN (limit 1M PLN). Kwalifikowane koszty: udział w targach zagranicznych, reklama za granicą, przygotowanie dokumentacji eksportowej. Carry-forward: 6 lat. Prowadź osobną ewidencję!",
        [expansion_costs])]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}

    trade_fairs := object.get(input.jdg_entrepreneur, "expansion_trade_fairs_costs", 0.0)
    ads_abroad := object.get(input.jdg_entrepreneur, "expansion_ads_abroad_costs", 0.0)
    export_prep := object.get(input.jdg_entrepreneur, "expansion_export_prep_costs", 0.0)

    expansion_costs := trade_fairs + ads_abroad + export_prep
    expansion_costs > 0

    expansion_rt = "TRIAGE_QUEUE" { expansion_costs > 500000 }
    expansion_rt = "" { true }
}


# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SEKCJA G: ULGA NA ROBOTYZACJĘ (Art. 26gb PIT, 50%)                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ═══════════════════════════════════════════════════════════════════════════════
# R700: relief_robotization — Ulga na robotyzację (50% kosztów)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.robotization",
    "package": "jdg.pit.missing_reliefs",
    "priority": 700,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_type": "ROBOTIZATION",
    "relief_percent": 50,
    "relief_robot_purchase_cost": robot_purchase,
    "relief_robot_training_cost": robot_training,
    "relief_robot_maintenance_cost": robot_maintenance,
    "relief_total_qualified": total_qualified,
    "relief_deductible": total_qualified * 0.5,
    "relief_requires_new_robot": true,
    "_routing": robot_rt,
    "_routing_reason": sprintf("Ulga robotyzacyjna: %.2f PLN kosztów × 50%% = %.2f PLN odliczenia",
        [total_qualified, total_qualified * 0.5]),
    "_legal_basis": "Art. 26gb PIT (ulga na robotyzację — 50% kosztów)",
    "_warnings": [sprintf("🤖 ULGA NA ROBOTYZACJĘ — Koszty kwalifikowane: %.2f PLN (zakup: %.2f, szkolenie: %.2f, serwis: %.2f). Odliczenie 50%%: %.2f PLN. WYMÓG: roboty przemysłowe/magazynowe + faktury + dokumentacja techniczna. Musi być NOWY robot (nie używany)!",
        [total_qualified, robot_purchase, robot_training, robot_maintenance, total_qualified * 0.5])]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}

    robot_purchase := object.get(input.jdg_entrepreneur, "robotization_purchase_costs", 0.0)
    robot_training := object.get(input.jdg_entrepreneur, "robotization_training_costs", 0.0)
    robot_maintenance := object.get(input.jdg_entrepreneur, "robotization_maintenance_first_year", 0.0)

    total_qualified := robot_purchase + robot_training + robot_maintenance
    total_qualified > 0

    robot_rt = "TRIAGE_QUEUE" { total_qualified > 200000 }
    robot_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R999: summary — Raport pokrycia brakujących ulg
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.coverage_summary",
    "package": "jdg.pit.missing_reliefs",
    "priority": 999,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "relief_coverage": {
        "LOSS_CARRY_FORWARD": "R400-R401 (Art. 9 ust. 3 PIT) ✅ NOWE",
        "REHABILITATION": "R650 (Art. 26 ust. 1 pkt 6 PIT) ✅ NOWE",
        "INTERNET": "R660-R661 (Art. 26 ust. 1 pkt 6a PIT) ✅ NOWE",
        "BLOOD_DONATION": "R670 (Art. 26 ust. 1 pkt 9c PIT) ✅ NOWE",
        "CHILD_TAX_CREDIT": "R680 (Art. 27f PIT) ✅ NOWE",
        "EXPANSION": "R690 (Art. 26ec PIT) ✅ NOWE",
        "ROBOTIZATION": "R700 (Art. 26gb PIT) ✅ NOWE"
    },
    "total_new_rules": 7,
    "generated_from": "RAPORT_04_PIT_CORE.txt",
    "_routing": "",
    "_routing_reason": "Raport pokrycia P0/P1 — 7 nowych reguł z Raportu 04",
    "_legal_basis": "Ustawa PIT (Dz.U. 2025 poz. 789)",
    "_warnings": ["📋 RAPORT 04 P0/P1 — Dodano 7 brakujących reguł ulg PIT: strata aktywna, rehabilitacyjna, internetowa, krwiodawstwo, dzieci, ekspansja, robotyzacja. Pokrycie Art. 9, 26, 26ec, 26gb, 27f PIT."]
} {
    1 == 1
}
