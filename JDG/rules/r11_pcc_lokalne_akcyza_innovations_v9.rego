# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R11 GLM52 PCC / PODATKI LOKALNE / AKCYZĄ — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r11_pcc_lokalne_akcyza_innovations
# Raport: RAPORT_11_PCC_LOKALNE_AKCYZA.txt (Kampania GLM 5.2 — seria 11/25)
#
# Prompt 11/25 (PCC / podatki lokalne / akcyza — nieruchomości, środki
# transportu, umowy, paliwo, alkohol):
#   R11-INN-01 pcc3_deadline_alert_monitor — monitor terminu 14 dni deklaracji
#                                           PCC-3 (art. 10 ustawy PCC) z 3
#                                           poziomami alertów + next_action
#                                           (p14 pcc3_generator dawał
#                                           deklarację bez alarmów terminu)
#   R11-INN-02 real_estate_tax_simulator  — symulator podatku od nieruchomości
#                                           (stawki gminne 1,43/33,10 zł/m²)
#                                           z projekcją roczną i ratami
#                                           (p14 real_estate_tax_calculator
#                                           liczył pojedynczo)
#   R11-INN-03 excise_product_classifier — klasyfikator wyrobów akcyzowych
#                                           (paliwo/alkohol → stawka → obowiązek
#                                           AKC-R/banderole/skład) (p14 miał
#                                           osobne kalkulatory paliw i alkoholu)
#   R11-INN-04 transport_tax_deadline_monitor — monitor DN-1 (14 dni) + raty
#                                           15.03/15.05/15.09/15.11 z alertami
#                                           (p14 dn1_tracker dawał listę rat)
#   R11-INN-05 vat_vs_pcc_arbitrator     — arbiter VAT vs PCC: wyłączenie
#                                           art. 2 pkt 4 ustawy PCC (jeśli VAT,
#                                           to PCC wyłączone) + obowiązek
#                                           (p14 vat_vs_pcc_optimizer dawał
#                                           rekomendację)
#
# Zgodność: ADR-001..009/017/022, ustawa o PCC (art. 1-16), ustawa o podatkach
#           i opłatach lokalnych (art. 1-6, 8, 12), ustawa o podatku akcyzowym
#           (art. 8-11, 16, 30, 46-51, 93-100), KKS art. 65; thresholds.
#           pcc_local_excise (zero hardcode); INV-018; First-Match-Wins.
# package: jdg.r11_pcc_lokalne_akcyza_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r11_pcc_lokalne_akcyza_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r11_pcc_lokalne_akcyza_innovations.no_match", "package": "jdg.r11_pcc_lokalne_akcyza_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_th := object.get(object.get(data, "jdg", {}), "thresholds", {})
_th_ple := object.get(_th, "pcc_local_excise", {})

pcc_sale_rate := object.get(_th_ple, "pcc_sale_rate", 0.02)              # art. 7 PCC
pcc_loan_rate := object.get(_th_ple, "pcc_loan_rate", 0.005)             # art. 7 PCC
pcc_company_rate := object.get(_th_ple, "pcc_company_rate", 0.005)       # art. 7 PCC
pcc_mortgage_rate := object.get(_th_ple, "pcc_mortgage_rate", 0.001)     # art. 7 PCC
pcc_exemption_limit := object.get(_th_ple, "pcc_exemption_limit", 1000)  # art. 9 PCC
pcc_family_loan_limit := object.get(_th_ple, "pcc_family_loan_limit", 36120)  # art. 9 pkt 10 PCC
pcc3_deadline_days := object.get(_th_ple, "pcc3_deadline_days", 14)      # art. 10 PCC
land_business_rate := object.get(_th_ple, "land_business_rate", 1.43)    # art. 5 u.p.l.
building_business_rate := object.get(_th_ple, "building_business_rate", 33.10)  # art. 5 u.p.l.
transport_dn1_deadline_days := object.get(_th_ple, "transport_dn1_deadline_days", 14)  # DN-1
excise_gasoline := object.get(_th_ple, "excise_gasoline", 1566)          # zł/1000l
excise_diesel := object.get(_th_ple, "excise_diesel", 1206)              # zł/1000l
excise_lpg := object.get(_th_ple, "excise_lpg", 695)                     # zł/1000l
excise_ethanol_per_hl := object.get(_th_ple, "excise_ethanol_per_hl", 6900)  # zł/hl
excise_beer_per_plato := object.get(_th_ple, "excise_beer_per_plato", 8.57)  # zł/hl za °Plato
excise_wine_per_hl := object.get(_th_ple, "excise_wine_per_hl", 185)     # zł/hl

# ── Helper: zaokrąglenie 2 miejsca (spójne z p14/round2) ─────────────────────
round2(x) := floor((x * 100) + 0.5) / 100

# ═══════════════════════════════════════════════════════════════════════════════
# R11-INN-01: PCC3 DEADLINE ALERT MONITOR — monitor terminu 14 dni PCC-3
#             (art. 10 ustawy PCC) z 3 poziomami alertów + next_action
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza pcc3_monitor: {items: [{label, days_left, filed}]}.
# Poziom: RED ≤3 dni (BLOCK_AND_ALERT), AMBER ≤7 dni (TRIAGE_QUEUE), GREEN.
pcc3_input := object.get(input, "pcc3_monitor", {})
pcc3_items_in := object.get(pcc3_input, "items", [])

pcc3_level(days) := "RED" if {
    days <= 3
} else := "AMBER" if {
    days <= 7
} else := "GREEN" if {
    true
}

pcc3_item(i) := {
    "label": object.get(i, "label", "PCC-3"),
    "days_left": object.get(i, "days_left", pcc3_deadline_days),
    "filed": object.get(i, "filed", false),
    "level": pcc3_level(object.get(i, "days_left", pcc3_deadline_days)),
    "next_action": "Złóż PCC-3 NATYCHMIAST (art. 10 PCC — 14 dni) — brak = sankcje (art. 10 § 2)." if {not object.get(i, "filed", false)} else "PCC-3 złożona — obowiązek spełniony.",
}

pcc3_items := [pcc3_item(i) | i := pcc3_items_in[_]]
pcc3_red_count := count([x | x := pcc3_items[_]; x.level == "RED"])
pcc3_amber_count := count([x | x := pcc3_items[_]; x.level == "AMBER"])
pcc3_unfiled_count := count([x | x := pcc3_items[_]; not x.filed])

pcc3_routing := "BLOCK_AND_ALERT" if {
    pcc3_red_count > 0
} else := "TRIAGE_QUEUE" if {
    pcc3_amber_count > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r11_pcc_lokalne_akcyza_innovations.pcc3_deadline_alert_monitor",
    "package": "jdg.r11_pcc_lokalne_akcyza_innovations",
    "priority": 11016,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "pcc3_items_total": count(pcc3_items),
    "pcc3_red_count": pcc3_red_count,
    "pcc3_amber_count": pcc3_amber_count,
    "pcc3_unfiled_count": pcc3_unfiled_count,
    "pcc3_deadline_days": pcc3_deadline_days,
    "pcc3_items": pcc3_items,
    "_routing": pcc3_routing,
    "_routing_reason": sprintf("Monitor PCC-3 — %d pozycji (RED: %d, AMBER: %d, niezłożone: %d). Termin %d dni (art. 10 PCC).", [count(pcc3_items), pcc3_red_count, pcc3_amber_count, pcc3_unfiled_count, pcc3_deadline_days]),
    "_legal_basis": "ustawa o PCC art. 10 (PCC-3, 14 dni), art. 10 § 2 (sankcje)",
    "_warnings": [sprintf("PCC-3: %d deklaracji — %d RED (≤3 dni), %d AMBER (≤7 dni), %d niezłożonych. Termin %d dni.", [count(pcc3_items), pcc3_red_count, pcc3_amber_count, pcc3_unfiled_count, pcc3_deadline_days])],
} if {
    object.get(input.jdg_entrepreneur, "r11_pcc_local_excise_check", false) == true
    object.get(input, "pcc3_monitor", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R11-INN-02: REAL ESTATE TAX SIMULATOR — symulator podatku od nieruchomości
#             (stawki gminne 1,43/33,10 zł/m²) z projekcją roczną
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza property_tax: {land_business_m2, building_business_m2,
# months_remaining}.
ret_input := object.get(input, "property_tax", {})
ret_land_m2 := max([0, object.get(ret_input, "land_business_m2", 0)])
ret_building_m2 := max([0, object.get(ret_input, "building_business_m2", 0)])
ret_months := max([1, object.get(ret_input, "months_remaining", 12)])

ret_land_annual := round2(ret_land_m2 * land_business_rate)
ret_building_annual := round2(ret_building_m2 * building_business_rate)
ret_total_annual := round2(ret_land_annual + ret_building_annual)
ret_due_now := round2(ret_total_annual * ret_months / 12)
ret_installment := round2(ret_total_annual / 4)

ret_routing := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r11_pcc_lokalne_akcyza_innovations.real_estate_tax_simulator",
    "package": "jdg.r11_pcc_lokalne_akcyza_innovations",
    "priority": 11017,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "ret_land_business_m2": ret_land_m2,
    "ret_building_business_m2": ret_building_m2,
    "ret_land_annual": ret_land_annual,
    "ret_building_annual": ret_building_annual,
    "ret_total_annual": ret_total_annual,
    "ret_due_now": ret_due_now,
    "ret_installment_quarterly": ret_installment,
    "ret_months_remaining": ret_months,
    "_routing": ret_routing,
    "_routing_reason": sprintf("Symulator podatku od nieruchomości — grunty %.2f zł/m² × %d m², budynki %.2f zł/m² × %d m². Rocznie: %.2f PLN (raty po %.2f).", [land_business_rate, ret_land_m2, building_business_rate, ret_building_m2, ret_total_annual, ret_installment]),
    "_legal_basis": "ustawa o podatkach i opłatach lokalnych art. 2-6 (stawki maksymalne 2026), art. 6 ust. 9 (raty)",
    "_warnings": [sprintf("NIERUCHOMOŚĆ: roczny podatek %.2f PLN (grunty %.2f + budynki %.2f). Do zapłaty teraz: %.2f PLN.", [ret_total_annual, ret_land_annual, ret_building_annual, ret_due_now])],
} if {
    object.get(input.jdg_entrepreneur, "r11_pcc_local_excise_check", false) == true
    object.get(input, "property_tax", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R11-INN-03: EXCISE PRODUCT CLASSIFIER — klasyfikator wyrobów akcyzowych
#             (paliwo/alkohol → stawka → obowiązek AKC-R/banderole/skład)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza excise_product: {product_type, quantity, unit}.
# Typy: GASOLINE/DIESEL/LPG (zł/1000l), ETHANOL/WINE (zł/hl), BEER (zł/hl °Plato).
exc_input := object.get(input, "excise_product", {})
exc_type := object.get(exc_input, "product_type", "")
exc_quantity := max([0, object.get(exc_input, "quantity", 0)])

exc_rate := excise_gasoline if {
    exc_type == "GASOLINE"
} else := excise_diesel if {
    exc_type == "DIESEL"
} else := excise_lpg if {
    exc_type == "LPG"
} else := excise_ethanol_per_hl if {
    exc_type == "ETHANOL"
} else := excise_beer_per_plato if {
    exc_type == "BEER"
} else := excise_wine_per_hl if {
    exc_type == "WINE"
} else := 0 if {
    true
}

exc_duty := round2(exc_quantity * exc_rate) if {
    exc_type != "BEER"
} else := round2(exc_quantity * exc_rate) if {
    exc_type == "BEER"
} else := 0 if {
    true
}

exc_needs_banderole := exc_type == "ETHANOL"

exc_routing := "TRIAGE_QUEUE" if {
    exc_type != ""
    exc_rate == 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r11_pcc_lokalne_akcyza_innovations.excise_product_classifier",
    "package": "jdg.r11_pcc_lokalne_akcyza_innovations",
    "priority": 11018,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "exc_product_type": exc_type,
    "exc_quantity": exc_quantity,
    "exc_rate": exc_rate,
    "exc_duty_pln": exc_duty,
    "exc_needs_banderole": exc_needs_banderole,
    "exc_needs_akcr": exc_type != "",
    "_routing": exc_routing,
    "_routing_reason": sprintf("Klasyfikator akcyzy — typ '%s', ilość %d, stawka %.2f. Akcyza: %.2f PLN. %s", [exc_type, exc_quantity, exc_rate, exc_duty, "Obowiązek AKC-R/banderole." if {exc_type != ""} else "Typ nieznany."]),
    "_legal_basis": "ustawa o podatku akcyzowym art. 8-11 (paliwa), art. 93-100 (alkohol), art. 16 (AKC-R), art. 116-118 (banderole)",
    "_warnings": [sprintf("AKCYZA: %s × %.2f = %.2f PLN. %s", [exc_type, exc_rate, exc_duty, "Wyrób wymaga banderol." if {exc_needs_banderole} else "Bez banderol."])],
} if {
    object.get(input.jdg_entrepreneur, "r11_pcc_local_excise_check", false) == true
    object.get(input, "excise_product", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R11-INN-04: TRANSPORT TAX DEADLINE MONITOR — monitor DN-1 (14 dni) + raty
#             15.03/15.05/15.09/15.11 z 3 poziomami alertów
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza transport_monitor: {items: [{label, days_left, dn1_filed}]}.
trt_input := object.get(input, "transport_monitor", {})
trt_items_in := object.get(trt_input, "items", [])

trt_level(days) := "RED" if {
    days <= 3
} else := "AMBER" if {
    days <= 7
} else := "GREEN" if {
    true
}

trt_item(i) := {
    "label": object.get(i, "label", "DT-1"),
    "days_left": object.get(i, "days_left", transport_dn1_deadline_days),
    "dn1_filed": object.get(i, "dn1_filed", false),
    "level": trt_level(object.get(i, "days_left", transport_dn1_deadline_days)),
    "next_action": "Złóż DN-1 NATYCHMIAST (art. 9 u.p.l. — 14 dni) — raty 15.03/15.05/15.09/15.11." if {not object.get(i, "dn1_filed", false)} else "DN-1 złożona — raty wg harmonogramu.",
}

trt_items := [trt_item(i) | i := trt_items_in[_]]
trt_red_count := count([x | x := trt_items[_]; x.level == "RED"])
trt_amber_count := count([x | x := trt_items[_]; x.level == "AMBER"])
trt_unfiled_count := count([x | x := trt_items[_]; not x.dn1_filed])

trt_routing := "BLOCK_AND_ALERT" if {
    trt_red_count > 0
} else := "TRIAGE_QUEUE" if {
    trt_amber_count > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r11_pcc_lokalne_akcyza_innovations.transport_tax_deadline_monitor",
    "package": "jdg.r11_pcc_lokalne_akcyza_innovations",
    "priority": 11019,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "trt_items_total": count(trt_items),
    "trt_red_count": trt_red_count,
    "trt_amber_count": trt_amber_count,
    "trt_unfiled_count": trt_unfiled_count,
    "trt_dn1_deadline_days": transport_dn1_deadline_days,
    "trt_items": trt_items,
    "_routing": trt_routing,
    "_routing_reason": sprintf("Monitor DN-1 — %d pozycji (RED: %d, AMBER: %d, niezłożone: %d). Termin %d dni. Raty 15.03/15.05/15.09/15.11.", [count(trt_items), trt_red_count, trt_amber_count, trt_unfiled_count, transport_dn1_deadline_days]),
    "_legal_basis": "ustawa o podatkach i opłatach lokalnych art. 9 (DN-1, 14 dni), art. 9 ust. 6 (raty), art. 8 (środki transportu >3,5t)",
    "_warnings": [sprintf("DN-1: %d pojazdów — %d RED (≤3 dni), %d AMBER (≤7 dni), %d niezłożonych. Raty 15.03/15.05/15.09/15.11.", [count(trt_items), trt_red_count, trt_amber_count, trt_unfiled_count])],
} if {
    object.get(input.jdg_entrepreneur, "r11_pcc_local_excise_check", false) == true
    object.get(input, "transport_monitor", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R11-INN-05: VAT VS PCC ARBITRATOR — arbiter VAT vs PCC (art. 2 pkt 4 ustawy
#             PCC: jeśli czynność podlega VAT, PCC wyłączone)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza pcc_arbitration: {transaction_type, value, vat_applies,
# family_loan, in_company}.
arb_input := object.get(input, "pcc_arbitration", {})
arb_type := object.get(arb_input, "transaction_type", "SALE")
arb_value := max([0, object.get(arb_input, "value", 0)])
arb_vat_applies := object.get(arb_input, "vat_applies", false)
arb_family_loan := object.get(arb_input, "family_loan", false)

arb_rate := pcc_sale_rate if {
    arb_type == "SALE"
} else := pcc_loan_rate if {
    arb_type == "LOAN"
} else := pcc_company_rate if {
    arb_type == "COMPANY"
} else := pcc_mortgage_rate if {
    arb_type == "MORTGAGE"
} else := pcc_sale_rate if {
    true
}

arb_pcc_excluded := arb_vat_applies

arb_pcc_due := round2(arb_value * arb_rate) if {
    not arb_pcc_excluded
    arb_value > pcc_exemption_limit
    not (arb_type == "LOAN" and arb_family_loan and arb_value <= pcc_family_loan_limit)
} else := 0 if {
    true
}

arb_routing := "" if {
    arb_pcc_due == 0
} else := "TRIAGE_QUEUE" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r11_pcc_lokalne_akcyza_innovations.vat_vs_pcc_arbitrator",
    "package": "jdg.r11_pcc_lokalne_akcyza_innovations",
    "priority": 11020,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "arb_transaction_type": arb_type,
    "arb_value": arb_value,
    "arb_vat_applies": arb_vat_applies,
    "arb_rate": arb_rate,
    "arb_pcc_excluded": arb_pcc_excluded,
    "arb_pcc_due_pln": arb_pcc_due,
    "_routing": arb_routing,
    "_routing_reason": sprintf("Arbiter VAT vs PCC — typ %s, wartość %.2f, VAT=%s. %s", [arb_type, arb_value, arb_vat_applies, "PCC wyłączone (art. 2 pkt 4 — czynność opodatkowana VAT)." if {arb_pcc_excluded} else sprintf("PCC: %.2f PLN.", [arb_pcc_due]) if {arb_pcc_due > 0} else "PCC zwolnione/brak obowiązku."]),
    "_legal_basis": "ustawa o PCC art. 2 pkt 4 (wyłączenie VAT), art. 7 (stawki), art. 9 (zwolnienia), art. 10 (termin)",
    "_warnings": [sprintf("VAT/PCC: typ %s — %s", [arb_type, "PCC wyłączone (podlega VAT)." if {arb_pcc_excluded} else sprintf("PCC %.2f PLN (stawka %.2f%%).", [arb_pcc_due, arb_rate * 100])])],
} if {
    object.get(input.jdg_entrepreneur, "r11_pcc_local_excise_check", false) == true
    object.get(input, "pcc_arbitration", {}) != {}
}
