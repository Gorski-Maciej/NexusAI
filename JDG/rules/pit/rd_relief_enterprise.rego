# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE R&D RELIEF (Art. 26e PIT) — Ulga B+R
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise R&D Relief — Ulga Badawczo-Rozwojowa
# description: |
#   ENTERPRISE v7.0 — Wypełnia KRYTYCZNĄ lukę CR1 z Raportu v7.0.
#   Ulga B+R (Art. 26e PIT): odliczenie 100% kosztów kwalifikowanych
#   (200% dla centrum B+R). R100-R113.
#   - R100: Test 3 kryteriów działalności B+R (twórczość, systematyczność, transferowalność)
#   - R101-R105: Katalog kosztów kwalifikowanych (5 kategorii)
#   - R106: Limit odliczenia = dochód z B+R
#   - R107: Zwrot gotówkowy (18% przy stracie)
#   - R108: 200% dla centrum B+R
#   - R109: Obowiązek wyodrębnienia kosztów w ewidencji
#   - R110: Raportowanie MDR dla >5M PLN
#   - R111-R113: Interakcje z IP Box i innymi ulgami
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Art. 26e PIT, Art. 5a pkt 38-40 PIT
# package: jdg.pit.rd_relief
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.rd_relief

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.rd.no_match",
    "package": "jdg.pit.rd_relief", "priority": 999
}

# ═══════════════════════════════════════════════════════════════════════════════
# R100: rd_activity_qualification — Test 3 kryteriów B+R
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.pit.rd.qualification_3criteria",
    "package": "jdg.pit.rd_relief",
    "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "rd_activity_qualified": is_qualified,
    "rd_criteria_tworczosc": criteria_creative,
    "rd_criteria_systematycznosc": criteria_systematic,
    "rd_criteria_transferowalnosc": criteria_transferable,
    "rd_qualification_score": qualification_score,
    "_routing": rd_rt,
    "_routing_reason": rd_rs,
    "_legal_basis": "Art. 5a pkt 38-40 PIT (definicja działalności B+R)",
    "_warnings": [sprintf("🔬 B+R — KWALIFIKACJA: %s (score: %d/3). Kryteria: twórczość=%s, systematyczność=%s, transferowalność=%s. %s",
        [qualification_msg, qualification_score, criteria_creative, criteria_systematic, criteria_transferable, next_step_msg])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}

    # Test 3 kryteriów (Art. 5a pkt 38-40 PIT)
    criteria_creative = "TAK" { object.get(input.jdg_entrepreneur, "rd_activity_is_creative", false) }
    else = "NIE" { object.get(input.jdg_entrepreneur, "rd_activity_is_creative", true) == false }
    criteria_systematic = "TAK" { object.get(input.jdg_entrepreneur, "rd_activity_is_systematic", false) }
    else = "NIE" { object.get(input.jdg_entrepreneur, "rd_activity_is_systematic", true) == false }
    criteria_transferable = "TAK" { object.get(input.jdg_entrepreneur, "rd_activity_is_transferable", false) }
    else = "NIE" { object.get(input.jdg_entrepreneur, "rd_activity_is_transferable", true) == false }

    qualification_score := 0
    qualification_score := qualification_score + 1 { criteria_creative == "TAK" }
    qualification_score := qualification_score + 1 { criteria_systematic == "TAK" }
    qualification_score := qualification_score + 1 { criteria_transferable == "TAK" }

    is_qualified := qualification_score >= 2
    qualification_msg = "KWALIFIKUJE SIĘ do ulgi B+R" { is_qualified }
    qualification_msg = "NIE kwalifikuje — niespełnione kryteria" { not is_qualified }
    next_step_msg = "Przejdź do katalogu kosztów kwalifikowanych (R101-R105)" { is_qualified }
    next_step_msg = "Działalność musi spełniać min. 2 z 3 kryteriów B+R" { not is_qualified }

    rd_rt = "TRIAGE_QUEUE" { is_qualified }
    rd_rt = "BLOCK_AND_ALERT" { not is_qualified }
    rd_rs = sprintf("B+R score %d/3 — %s", [qualification_score, qualification_msg])
}

# ═══════════════════════════════════════════════════════════════════════════════
# R101: rd_qualifying_costs_staff — Wynagrodzenia personelu B+R
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.qualifying_staff_costs",
    "package": "jdg.pit.rd_relief",
    "priority": 101,
    "pit_form": pit_form,
    "rd_cost_category": "STAFF",
    "rd_cost_amount": staff_costs,
    "rd_is_qualifying": staff_costs > 0,
    "rd_deduction_pct": deduction_pct,
    "rd_deductible_amount": staff_costs * deduction_pct,
    "_routing": "",
    "_routing_reason": sprintf("Koszty personelu B+R: %.2f PLN × %.0f%% = %.2f PLN odliczenia",
        [staff_costs, deduction_pct * 100, staff_costs * deduction_pct]),
    "_legal_basis": "Art. 26e ust. 2 pkt 1 PIT (wynagrodzenia pracowników B+R)",
    "_warnings": [sprintf("PERSONEL B+R — Wynagrodzenia: %.2f PLN. Obejmuje: umowy o pracę, zlecenia, dzieło dla personelu B+R. WYMÓG: wyodrębniona ewidencja czasu pracy nad projektami B+R (min. 50%% czasu na B+R).",
        [staff_costs])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    staff_costs := object.get(input.jdg_entrepreneur, "rd_staff_costs_qualified", 0)
    is_rd_center := object.get(input.jdg_entrepreneur, "is_rd_center", false)
    deduction_pct := 1.00 { not is_rd_center }
    deduction_pct := 2.00 { is_rd_center }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R102: rd_qualifying_costs_materials — Materiały i surowce B+R
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.qualifying_materials",
    "package": "jdg.pit.rd_relief",
    "priority": 102,
    "pit_form": pit_form,
    "rd_cost_category": "MATERIALS",
    "rd_cost_amount": mat_costs,
    "rd_is_qualifying": mat_costs > 0,
    "rd_deduction_pct": deduction_pct,
    "_routing": "",
    "_routing_reason": sprintf("Materiały B+R: %.2f PLN", [mat_costs]),
    "_legal_basis": "Art. 26e ust. 2 pkt 2 PIT (materiały i surowce)",
    "_warnings": [sprintf("MATERIAŁY B+R — %.2f PLN. Obejmuje: surowce, półprodukty, odczynniki, materiały zużyte bezpośrednio w działalności B+R. NIE obejmuje: materiałów biurowych ogólnego przeznaczenia.",
        [mat_costs])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    mat_costs := object.get(input.jdg_entrepreneur, "rd_materials_costs_qualified", 0)
    is_rd_center := object.get(input.jdg_entrepreneur, "is_rd_center", false)
    deduction_pct := 1.00 { not is_rd_center }
    deduction_pct := 2.00 { is_rd_center }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R103: rd_qualifying_costs_expertise — Ekspertyzy, opinie, usługi doradcze B+R
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.qualifying_expertise",
    "package": "jdg.pit.rd_relief",
    "priority": 103,
    "pit_form": pit_form,
    "rd_cost_category": "EXPERTISE",
    "rd_cost_amount": expertise_costs,
    "rd_requires_documentation": true,
    "_routing": "",
    "_routing_reason": sprintf("Ekspertyzy B+R: %.2f PLN", [expertise_costs]),
    "_legal_basis": "Art. 26e ust. 2 pkt 3 PIT (ekspertyzy, opinie, doradztwo)",
    "_warnings": [sprintf("EKSPERTYZY B+R — %.2f PLN. Obejmuje: ekspertyzy, opinie, usługi doradcze, badania naukowe zlecone jednostkom naukowym. WYMÓG: umowa/rachunek z wyszczególnieniem zakresu B+R.",
        [expertise_costs])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expertise_costs := object.get(input.jdg_entrepreneur, "rd_expertise_costs_qualified", 0)
}

# ═══════════════════════════════════════════════════════════════════════════════
# R104: rd_qualifying_costs_depreciation — Odpisy amortyzacyjne od ŚT i WNiP
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.qualifying_depreciation",
    "package": "jdg.pit.rd_relief",
    "priority": 104,
    "pit_form": pit_form,
    "rd_cost_category": "DEPRECIATION",
    "rd_cost_amount": depr_costs,
    "rd_depreciation_note": "Tylko odpisy od ŚT i WNiP wykorzystywanych w B+R",
    "_routing": "",
    "_routing_reason": sprintf("Amortyzacja B+R: %.2f PLN", [depr_costs]),
    "_legal_basis": "Art. 26e ust. 2 pkt 4 PIT (odpisy amortyzacyjne)",
    "_warnings": [sprintf("AMORTYZACJA B+R — %.2f PLN. TYLKO odpisy od środków trwałych i WNiP wykorzystywanych w działalności B+R. WYMÓG: wyodrębnienie w ewidencji ŚT z dopiskiem 'B+R'.",
        [depr_costs])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    depr_costs := object.get(input.jdg_entrepreneur, "rd_depreciation_costs_qualified", 0)
}

# ═══════════════════════════════════════════════════════════════════════════════
# R105: rd_qualifying_costs_contracts — Umowy zlecenia/dzieło dla personelu B+R
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.qualifying_contracts",
    "package": "jdg.pit.rd_relief",
    "priority": 105,
    "pit_form": pit_form,
    "rd_cost_category": "CONTRACTS",
    "rd_cost_amount": contract_costs,
    "rd_zus_from_contracts": zus_contracts,
    "_routing": "",
    "_routing_reason": sprintf("Umowy B+R: %.2f PLN + ZUS %.2f PLN", [contract_costs, zus_contracts]),
    "_legal_basis": "Art. 26e ust. 2 pkt 1a PIT (umowy cywilnoprawne dla B+R)",
    "_warnings": [sprintf("UMOWY B+R — %.2f PLN + ZUS %.2f PLN. Obejmuje: umowy zlecenia i o dzieło z osobami niebędącymi pracownikami. WYMÓG: umowa musi wskazywać udział w projektach B+R.",
        [contract_costs, zus_contracts])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    contract_costs := object.get(input.jdg_entrepreneur, "rd_contract_costs_qualified", 0)
    zus_contracts := object.get(input.jdg_entrepreneur, "rd_contract_zus_qualified", 0)
}

# ═══════════════════════════════════════════════════════════════════════════════
# R106: rd_deduction_limit — Limit odliczenia = dochód z B+R
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.deduction_limit",
    "package": "jdg.pit.rd_relief",
    "priority": 106,
    "pit_form": pit_form,
    "rd_total_qualified_costs": total_qualified,
    "rd_total_deductible_raw": total_deductible_raw,
    "rd_income_from_rd": rd_income,
    "rd_deduction_capped": max_deduction,
    "rd_excess_carried_forward": excess_carried,
    "_routing": limit_rt,
    "_routing_reason": sprintf("Limit odliczenia B+R: dochód z B+R = %.2f PLN. Koszty kwalifikowane: %.2f PLN. Odliczenie: %.2f PLN. Nadwyżka na przyszłe lata: %.2f PLN.",
        [rd_income, total_qualified, max_deduction, excess_carried]),
    "_legal_basis": "Art. 26e ust. 6 PIT (limit odliczenia = dochód z działalności B+R)",
    "_warnings": [sprintf("LIMIT ODLICZENIA B+R — Dochód z B+R: %.2f PLN. Koszty kwalifikowane: %.2f PLN. Maksymalne odliczenie: %.2f PLN. Nadwyżka %.2f PLN → odlicz w ciągu 6 lat! Nie przepada!",
        [rd_income, total_qualified, max_deduction, excess_carried])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    total_qualified := object.get(input.jdg_entrepreneur, "rd_total_qualified_costs", 0)
    rd_income := object.get(input.jdg_entrepreneur, "rd_income_current_year", 0)
    is_rd_center := object.get(input.jdg_entrepreneur, "is_rd_center", false)
    multiplier := 1.0 { not is_rd_center }
    multiplier := 2.0 { is_rd_center }
    total_deductible_raw := total_qualified * multiplier
    max_deduction := min([total_deductible_raw, rd_income])
    excess_carried := max([total_deductible_raw - rd_income, 0])

    limit_rt = "TRIAGE_QUEUE" { excess_carried > 50000 }
    limit_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R107: rd_cash_refund — Zwrot gotówkowy (18% kosztów przy stracie)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.cash_refund",
    "package": "jdg.pit.rd_relief",
    "priority": 107,
    "pit_form": pit_form,
    "rd_operating_loss": has_loss,
    "rd_cash_refund_available": refund_available,
    "rd_cash_refund_amount": refund_amount,
    "rd_cash_refund_max_pct": 0.18,
    "_routing": refund_rt,
    "_routing_reason": sprintf("Zwrot gotówkowy B+R: %s — %.2f PLN (18%% kosztów kwalifikowanych przy stracie)",
        [refund_msg, refund_amount]),
    "_legal_basis": "Art. 26e ust. 7-8 PIT (zwrot gotówkowy)",
    "_warnings": [sprintf("ZWRÓT GOTÓWKOWY B+R — %s. Strata operacyjna: %s. Koszty kwalifikowane: %.2f PLN. Zwrot: %.2f PLN (max 18%% kosztów). Wniosek o zwrot do US w terminie złożenia zeznania rocznego.",
        [refund_msg, has_loss, total_qualified, refund_amount])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_loss := object.get(input.jdg_entrepreneur, "rd_has_operating_loss", false)
    total_qualified := object.get(input.jdg_entrepreneur, "rd_total_qualified_costs", 0)

    refund_available := has_loss and total_qualified > 0
    refund_amount := total_qualified * 0.18 { refund_available }
    refund_amount := 0 { not refund_available }
    refund_msg = "DOSTĘPNY" { refund_available }
    refund_msg = "NIEDOSTĘPNY (brak straty)" { not has_loss }

    refund_rt = "TRIAGE_QUEUE" { refund_available; refund_amount > 10000 }
    refund_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R108: rd_center_200pct — 200% dla centrum B+R (status CBR)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.center_200pct",
    "package": "jdg.pit.rd_relief",
    "priority": 108,
    "pit_form": pit_form,
    "rd_is_rd_center": is_rd_center,
    "rd_center_status": center_status,
    "rd_deduction_multiplier": 2.00 { is_rd_center },
    "_routing": "",
    "_routing_reason": sprintf("Centrum B+R: %s — mnożnik %.0fx", [center_status, [1.00, 2.00][is_rd_center]]),
    "_legal_basis": "Art. 26e ust. 3a PIT (centrum badawczo-rozwojowe)",
    "_warnings": [sprintf("CENTRUM B+R — %s. %s Mnożnik %.0fx kosztów kwalifikowanych. WYMÓG: status CBR nadany przez właściwego ministra.",
        [center_status, center_note, [1.0, 2.0][is_rd_center]])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    is_rd_center := object.get(input.jdg_entrepreneur, "is_rd_center", false)
    center_status = "STATUS CBR — 200%% kosztów kwalifikowanych" { is_rd_center }
    center_status = "Standard — 100%% kosztów kwalifikowanych" { not is_rd_center }
    center_note = "Możesz odliczyć 200%% kosztów kwalifikowanych!" { is_rd_center }
    center_note = "Rozważ uzyskanie statusu CBR dla podwojenia ulgi." { not is_rd_center }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R109: rd_separate_evidence — Obowiązek wyodrębnienia ewidencji B+R
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.separate_evidence_required",
    "package": "jdg.pit.rd_relief",
    "priority": 109,
    "pit_form": pit_form,
    "rd_evidence_separated": has_evidence,
    "rd_evidence_risk": evidence_risk,
    "_routing": evidence_rt,
    "_routing_reason": sprintf("Ewidencja B+R: %s", [evidence_msg]),
    "_legal_basis": "Art. 24a ust. 1b PIT (obowiązek wyodrębnienia kosztów B+R w ewidencji)",
    "_warnings": [sprintf("EWIDENCJA B+R — %s. %s Bez wyodrębnionej ewidencji kosztów B+R, US MOŻE zakwestionować ulgę! Prowadź osobną ewidencję księgową dla projektów B+R.",
        [evidence_msg, risk_note])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_evidence := object.get(input.jdg_entrepreneur, "rd_has_separate_evidence", false)
    evidence_msg = "WYODRĘBNIONA — OK" { has_evidence }
    evidence_msg = "BRAK wyodrębnionej ewidencji — RYZYKO!" { not has_evidence }
    risk_note = "" { has_evidence }
    risk_note = "Natychmiast załóż osobną ewidencję kosztów B+R. US może zakwestionować ulgę przy kontroli!" { not has_evidence }
    evidence_rt = "BLOCK_AND_ALERT" { not has_evidence }
    evidence_rt = "" { has_evidence }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R110: rd_mdr_reporting — Obowiązek MDR dla B+R >5M PLN
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.mdr_reporting",
    "package": "jdg.pit.rd_relief",
    "priority": 110,
    "pit_form": pit_form,
    "rd_mdr_required": mdr_required,
    "rd_mdr_threshold_pln": 5000000,
    "_routing": "TRIAGE_QUEUE" { mdr_required },
    "_routing_reason": sprintf("MDR B+R: %s — koszty kwalifikowane przekraczają 5M PLN", ["WYMAGANE" { mdr_required }, "NIE wymagane" { not mdr_required }]),
    "_legal_basis": "Art. 86a Ordynacji podatkowej (MDR — schematy podatkowe)",
    "_warnings": [sprintf("MDR B+R — %s. Koszty kwalifikowane: %.2f PLN. Próg MDR: 5 000 000 PLN. %s",
        [mdr_msg, total_qualified, mdr_action])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    total_qualified := object.get(input.jdg_entrepreneur, "rd_total_qualified_costs", 0)
    mdr_required := total_qualified > 5000000
    mdr_msg = "WYMAGANE zgłoszenie MDR-3 do Szefa KAS" { mdr_required }
    mdr_msg = "NIE wymagane" { not mdr_required }
    mdr_action = "Złóż MDR-3 w ciągu 30 dni!" { mdr_required }
    mdr_action = "" { not mdr_required }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R111: rd_ip_box_interaction — B+R + IP Box = MOŻNA ŁĄCZYĆ!
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.rd.ip_box_interaction",
    "package": "jdg.pit.rd_relief",
    "priority": 111,
    "pit_form": pit_form,
    "rd_ip_box_compatible": true,
    "rd_ip_box_interaction_note": "B+R i IP Box MOŻNA ŁĄCZYĆ, ale NIE na tym samym dochodzie! B+R od dochodu non-IP, IP Box (5%) od dochodu z IP.",
    "rd_ip_box_optimal_strategy": strategy,
    "_routing": "",
    "_routing_reason": strategy,
    "_legal_basis": "Art. 26e PIT + Art. 30ca PIT (łączenie ulg B+R i IP Box)",
    "_warnings": [sprintf("B+R + IP BOX — MOŻNA ŁĄCZYĆ! %s. Strategia: rozdziel dochód na IP (opodatkowany 5%%) i non-IP (gdzie stosujesz B+R 100-200%%). Uzyskujesz KORZYŚCI z OBU ulg jednocześnie!",
        [strategy_detail])]
} {
    input.rd_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    uses_ip_box := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    ip_income := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 0)
    rd_costs := object.get(input.jdg_entrepreneur, "rd_total_qualified_costs", 0)

    strategy_detail = sprintf("Dochód z IP: %.2f PLN @ 5%% = %.2f PLN podatku. Dochód non-IP: %.2f PLN. Zastosuj B+R do non-IP. Łączna oszczędność: %.2f PLN.",
        [ip_income, ip_income * 0.05, 0, 0])
    strategy = "Optymalizacja: B+R + IP Box — rozdziel dochody!" { uses_ip_box; rd_costs > 0 }
    strategy = "B+R bez IP Box — standard" { not uses_ip_box }
}

# ═══════════════════════════════════════════════════════════════════════════════
# NO-MATCH (R04 P1: stub { true } usunięty — nie generuje fałszywego matched:true)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": false,
    "rule_id": "jdg.pit.rd_relief.no_match",
    "package": "jdg.pit.rd_relief",
    "priority": 999,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26e PIT"
} {
    false
}
