# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — P00 (RAPORT_00 P0-2) Legal Coverage Closure
# ===============================================================
# 6 reguł domykających luki GAP wskazane przez
# tools/legal_coverage_gap_report.py (2026-08-11):
#   VAT Art. 17 (jdg.vat.a17.r5), Art. 90 (jdg.vat.a90.r1),
#   Art. 113 (jdg.vat.a113.r1), PIT Art. 9 (loss_carry_forward),
#   Art. 30c (jdg.pit.a30c.r1), OrdPU Art. 117ba (jdg.ord.a117ba.r1)
# Każda reguła ma niepustą kanoniczną podstawę prawną oraz realne
# warunki logiczne (zero-stub policy, RAPORT_00 wskaźniki SLO).
# ═══════════════════════════════════════════════════════════════

package jdg.p00.legal_coverage

# jdg.vat.a17.r5 — Reverse charge: usługi nabywane od podmiotu
# zagranicznego → obowiązek rozliczenia po stronie nabywcy
# (art. 17 ust. 1 pkt 5 ustawy o VAT)
jdg_vat_a17_r5 := {"matched": true, "rule_id": "jdg.vat.a17.r5", "package": "jdg.p00.legal_coverage", "priority": 1705, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "valid_from": "2026-01-01", "valid_to": null, "_routing": "", "_routing_reason": "Usługi nabywane od podmiotu zagranicznego — odwrotne obciążenie (art. 17)", "_legal_basis": "Art. 17 ust. 1 pkt 5 ustawy o VAT", "_warnings": []} {
    object.get(input.invoice, "type", "") == "SERVICE"
    object.get(input.invoice, "direction", "") == "PURCHASE"
    object.get(input.invoice, "supplier_country", "") != "PL"
}

# jdg.vat.a90.r1 — Proporcja odliczenia VAT (prorata) dla działalności
# mieszanej (art. 90 ust. 1-3 ustawy o VAT)
jdg_vat_a90_r1 := {"matched": true, "rule_id": "jdg.vat.a90.r1", "package": "jdg.p00.legal_coverage", "priority": 9001, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "valid_from": "2026-01-01", "valid_to": null, "_routing": "", "_routing_reason": "Proporcja odliczenia VAT — działalność mieszana", "_legal_basis": "Art. 90 ust. 1-3 ustawy o VAT", "_warnings": []} {
    object.get(input.jdg_entrepreneur, "mixed_use_vat", false) == true
    object.get(input.invoice, "deduction_allowed", true) == true
}

# jdg.vat.a113.r1 — Zwolnienie podmiotowe z VAT do 200 000 PLN
# (art. 113 ust. 1 ustawy o VAT)
jdg_vat_a113_r1 := {"matched": true, "rule_id": "jdg.vat.a113.r1", "package": "jdg.p00.legal_coverage", "priority": 11301, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "valid_from": "2026-01-01", "valid_to": null, "_routing": "", "_routing_reason": "Zwolnienie podmiotowe VAT do 200 000 PLN (art. 113)", "_legal_basis": "Art. 113 ust. 1 ustawy o VAT", "_warnings": []} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "EXEMPT"
    object.get(input.jdg_entrepreneur, "revenue_12m_pln", 0) <= 200000  # vat_subject_exemption_limit (art. 113)
}

# jdg.pit.a30c.r1 — Podatek liniowy 19% (art. 30c ust. 1 ustawy o PIT)
jdg_pit_a30c_r1 := {"matched": true, "rule_id": "jdg.pit.a30c.r1", "package": "jdg.p00.legal_coverage", "priority": 30001, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "PIT-36L", "pit_rate": "0.19", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "valid_from": "2026-01-01", "valid_to": null, "_routing": "", "_routing_reason": "Podatek liniowy 19% (art. 30c)", "_legal_basis": "Art. 30c ust. 1 ustawy o PIT", "_warnings": []} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT-36L"
}

# jdg.pit.advances_returns.loss_carry_forward — Strata podatkowa:
# odliczenie w 5 kolejnych latach, maks. 50% rocznie
# (art. 9 ust. 3 ustawy o PIT)
jdg_pit_loss_carry_forward := {"matched": true, "rule_id": "jdg.pit.advances_returns.loss_carry_forward", "package": "jdg.p00.legal_coverage", "priority": 903, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "valid_from": "2026-01-01", "valid_to": null, "_routing": "", "_routing_reason": "Strata podatkowa — odliczenie 50% w 5 kolejnych latach (art. 9 ust. 3)", "_legal_basis": "Art. 9 ust. 3 ustawy o PIT", "_warnings": []} {
    object.get(input.tax_return, "tax_loss_pln", 0) > 0
    object.get(input.tax_return, "loss_year", 0) > 0
}

# jdg.ord.a117ba.r1 — Biała lista podatników VAT: weryfikacja rachunku
# bankowego w 30 dni od płatności (art. 117ba § 1 Ordynacji podatkowej)
jdg_ord_a117ba_r1 := {"matched": true, "rule_id": "jdg.ord.a117ba.r1", "package": "jdg.p00.legal_coverage", "priority": 11701, "vat_rate": "", "rounding_level": "", "gtu_code": "", "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "", "kus_qualification": "", "kus_percent": 0, "zus_social_base_type": "", "zus_health_rate": "", "business_status": "", "valid_from": "2026-01-01", "valid_to": null, "_routing": "", "_routing_reason": "Biała lista — weryfikacja rachunku w 30 dni od płatności (art. 117ba)", "_legal_basis": "Art. 117ba § 1 Ordynacji podatkowej", "_warnings": []} {
    object.get(input.payment, "counterparty_whitelisted", false) == true
    object.get(input.payment, "whitelist_verified_within_days", 0) <= 30
}
