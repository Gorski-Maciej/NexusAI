# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE DONATION RELIEF (Art. 26 ust. 1 pkt 9 PIT)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Donation Relief — Ulga na Darowizny
# description: |
#   ENTERPRISE v7.0 — Wypełnia lukę H4 z Raportu v7.0.
#   Darowizny na cele pożytku publicznego, kultu religijnego i krwiodawstwo
#   z limitem 6% dochodu. D150-D159.
#   - D150: Darowizny OPP — limit 6% dochodu
#   - D151: Darowizny na cele kultu religijnego — limit 6%
#   - D152: Krwiodawstwo — 130 PLN/litr, bez % limitu
#   - D153: Łączny limit 6% (OPP + kościół + krew)
#   - D154: Wymóg przelewu bankowego
#   - D155: Dokumentacja (zaświadczenie OPP, potwierdzenie przelewu)
#   - D156: Nadwyżka PRZEPADA — nie przechodzi na kolejne lata
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Art. 26 ust. 1 pkt 9 PIT
# package: jdg.pit.donation_relief
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.donation_relief

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.donation.no_match",
    "package": "jdg.pit.donation_relief", "priority": 999
}

# ═══════════════════════════════════════════════════════════════════════════════
# D150: donation_opp_relief — Darowizny OPP — limit 6% dochodu
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.pit.donation.opp_relief",
    "package": "jdg.pit.donation_relief",
    "priority": 150,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "donation_opp_total": opp_total,
    "donation_opp_limit_pln": opp_limit,
    "donation_opp_deductible": opp_deductible,
    "donation_opp_excess": opp_excess,
    "_routing": opp_rt,
    "_routing_reason": sprintf("Darowizny OPP: %.2f PLN z limitu %.2f PLN. Odliczenie: %.2f PLN. Nadwyżka: %.2f PLN.",
        [opp_total, opp_limit, opp_deductible, opp_excess]),
    "_legal_basis": "Art. 26 ust. 1 pkt 9 lit. a PIT",
    "_warnings": [sprintf("DAROWIZNY OPP — %.2f PLN. Limit 6%% dochodu (%.2f PLN). Odliczasz: %.2f PLN. %s. Wymagane: przelew bankowy + zaświadczenie OPP.",
        [opp_total, income, opp_deductible, excess_note])]
} {
    input.donation_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 100000)
    opp_total := object.get(input.jdg_entrepreneur, "donations_opp_total", 0)
    opp_limit := floor(income * 0.06 * 100) / 100
    opp_deductible := min([opp_total, opp_limit])
    opp_excess := max([opp_total - opp_limit, 0])
    excess_note = sprintf("Nadwyżka %.2f PLN PRZEPADA — nie przechodzi na kolejne lata!", [opp_excess]) { opp_excess > 0 }
    excess_note = "OK — w limicie" { opp_excess == 0 }
    opp_rt = "TRIAGE_QUEUE" { opp_excess > 2000 }
    opp_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# D151: donation_church_relief — Darowizny na cele kultu religijnego
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.donation.church_relief",
    "package": "jdg.pit.donation_relief",
    "priority": 151,
    "pit_form": pit_form,
    "donation_church_total": church_total,
    "donation_church_limit_pln": church_limit,
    "donation_church_deductible": church_deductible,
    "_routing": "",
    "_routing_reason": sprintf("Darowizny kościelne: %.2f PLN z limitu %.2f PLN", [church_total, church_limit]),
    "_legal_basis": "Art. 26 ust. 1 pkt 9 lit. b PIT (cele kultu religijnego)",
    "_warnings": [sprintf("DAROWIZNY KOŚCIELNE — %.2f PLN. Limit 6%% dochodu (łącznie z OPP i krwią). Odliczasz: %.2f PLN. Wymagane: przelew bankowy + oświadczenie obdarowanego.",
        [church_total, church_deductible])]
} {
    input.donation_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 100000)
    church_total := object.get(input.jdg_entrepreneur, "donations_church_total", 0)
    church_limit := floor(income * 0.06 * 100) / 100
    church_deductible := min([church_total, church_limit])
}

# ═══════════════════════════════════════════════════════════════════════════════
# D152: donation_blood_relief — Krwiodawstwo — 130 PLN/litr
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.donation.blood_relief",
    "package": "jdg.pit.donation_relief",
    "priority": 152,
    "pit_form": pit_form,
    "donation_blood_liters": blood_liters,
    "donation_blood_rate_per_liter": 130,
    "donation_blood_equivalent_pln": blood_value,
    "donation_blood_no_pct_limit": true,
    "_routing": "",
    "_routing_reason": sprintf("Krwiodawstwo: %d litrów × 130 PLN = %.2f PLN odliczenia", [blood_liters, blood_value]),
    "_legal_basis": "Art. 26 ust. 1 pkt 9 lit. c PIT (ekwiwalent za krew — 130 PLN/litr)",
    "_warnings": [sprintf("KRWIODAWSTWO — %d litrów × 130 PLN/litr = %.2f PLN odliczenia. NIE wlicza się do limitu 6%%! Honorowi dawcy mogą odliczać BEZ ograniczenia procentowego.",
        [blood_liters, blood_value])]
} {
    input.donation_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    blood_liters := object.get(input.jdg_entrepreneur, "blood_donation_liters", 0)
    blood_value := blood_liters * 130
    blood_value > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# D153: donation_aggregate_limit — Łączny limit 6% (OPP + kościół)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.donation.aggregate_limit",
    "package": "jdg.pit.donation_relief",
    "priority": 153,
    "pit_form": pit_form,
    "donation_aggregate_limit_pln": agg_limit,
    "donation_aggregate_total": agg_total,
    "donation_aggregate_excess": agg_excess,
    "_routing": agg_rt,
    "_routing_reason": sprintf("Łączny limit darowizn: %.2f PLN / %.2f PLN. Nadwyżka: %.2f PLN PRZEPADA!",
        [agg_total, agg_limit, agg_excess]),
    "_legal_basis": "Art. 26 ust. 1 pkt 9 PIT (łączny limit 6% dla OPP + kościoła)",
    "_warnings": [sprintf("ŁĄCZNY LIMIT DAROWIZN 6%% — OPP: %.2f PLN + Kościół: %.2f PLN = %.2f PLN. Limit 6%% dochodu: %.2f PLN. NADWYŻKA %.2f PLN PRZEPADA! NIE przechodzi na kolejne lata.",
        [opp, church, agg_total, agg_limit, agg_excess])]
} {
    input.donation_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 100000)
    opp := object.get(input.jdg_entrepreneur, "donations_opp_total", 0)
    church := object.get(input.jdg_entrepreneur, "donations_church_total", 0)
    agg_total := opp + church
    agg_limit := floor(income * 0.06 * 100) / 100
    agg_excess := max([agg_total - agg_limit, 0])

    agg_rt = "BLOCK_AND_ALERT" { agg_excess > 5000 }
    agg_rt = "TRIAGE_QUEUE" { agg_excess > 0; agg_excess <= 5000 }
    agg_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# D154: donation_bank_transfer_required — Wymóg przelewu bankowego
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.donation.bank_transfer_missing",
    "package": "jdg.pit.donation_relief",
    "priority": 154,
    "pit_form": pit_form,
    "donation_bank_transfer_ok": false,
    "donation_issue": "BRAK PRZELEWU BANKOWEGO — darowizna gotówkowa NIE podlega odliczeniu!",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Darowizna gotówkowa — NIE podlega odliczeniu od dochodu!",
    "_legal_basis": "Art. 26 ust. 7 pkt 1-2 PIT (wymóg przelewu)",
    "_warnings": [sprintf("BRAK PRZELEWU! Darowizna %.2f PLN na rzecz '%s' przekazana GOTÓWKĄ — NIE podlega odliczeniu! Darowizny muszą być udokumentowane przelewem bankowym. Dowód wpłaty na konto OPP jest obowiązkowy.",
        [donation_amount, recipient])]
} {
    input.donation_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    donation_amount := object.get(input.invoice, "amount_net", 0)
    recipient := object.get(input.invoice, "donation_recipient", "NIEZNANY")
    donation_amount > 0
    input.invoice.is_bank_transfer == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# D155: donation_documentation — Wymagana dokumentacja
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.donation.documentation_check",
    "package": "jdg.pit.donation_relief",
    "priority": 155,
    "pit_form": pit_form,
    "donation_has_opp_certificate": has_cert,
    "donation_has_bank_confirmation": has_bank,
    "donation_documentation_complete": doc_complete,
    "_routing": doc_rt,
    "_routing_reason": sprintf("Dokumentacja darowizny: %s", [doc_msg]),
    "_legal_basis": "Art. 26 ust. 7 PIT (dokumentacja darowizn)",
    "_warnings": [sprintf("DOKUMENTACJA DAROWIZNY — %s. Wymagane: (1) przelew bankowy, (2) zaświadczenie/umowa OPP, (3) w przypadku darowizny > 1000 PLN — oświadczenie obdarowanego o przyjęciu.",
        [doc_msg])]
} {
    input.donation_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_cert := object.get(input.invoice, "has_opp_certificate", false)
    has_bank := object.get(input.invoice, "is_bank_transfer", false)
    doc_complete := has_cert and has_bank
    doc_msg = "KOMPLETNA — OK" { doc_complete }
    doc_msg = "NIEKOMPLETNA — uzupełnij!" { not doc_complete }

    doc_rt = "BLOCK_AND_ALERT" { not doc_complete }
    doc_rt = "" { doc_complete }
}

# ═══════════════════════════════════════════════════════════════════════════════
# D156: donation_excess_lost — Nadwyżka PRZEPADA
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.donation.excess_lost",
    "package": "jdg.pit.donation_relief",
    "priority": 156,
    "pit_form": pit_form,
    "donation_excess_not_carried": true,
    "donation_excess_warning": "Nadwyżka darowizn ponad 6% dochodu PRZEPADA — NIE przechodzi na kolejne lata podatkowe!",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Darowizny: nadwyżka ponad 6% — rozważ rozłożenie na lata",
    "_legal_basis": "Art. 26 ust. 1 pkt 9 PIT (brak carry-forward dla darowizn)",
    "_warnings": ["UWAGA: Nadwyżka darowizn ponad 6% dochodu PRZEPADA! W przeciwieństwie do ulgi B+R (6 lat carry-forward), darowizny nie przechodzą na kolejne lata. ROZŁÓŻ duże darowizny na kilka lat dla maksymalizacji odliczenia."]
} {
    input.donation_relief_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 100000)
    opp := object.get(input.jdg_entrepreneur, "donations_opp_total", 0)
    church := object.get(input.jdg_entrepreneur, "donations_church_total", 0)
    agg_total := opp + church
    agg_total > income * 0.06
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.donation_relief.fallback",
    "package": "jdg.pit.donation_relief",
    "priority": 999,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26 ust. 1 pkt 9 PIT",
    "_warnings": ["Darowizny — odlicz do 6% dochodu (OPP + kościół). Krwiodawstwo BEZ limitu %. Pamiętaj o przelewie bankowym!"]
} {
    true
}
