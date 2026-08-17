# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: PCC / LOKALNE / AKCYZA / ROLNY ATOMIC (GLM52 P14)
# Testy reguł atomowych pcc_lokalne_atomic_p14: PCC (stawki 0,5-2%, VAT,
# zwolnienie, PCC-3), nieruchomości/transport, akcyza, podatek rolny.
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_pcc_local_excise

import data.jdg.micro.pcc_lokalne_atomic_p14 as atomic

# ── PCC ────────────────────────────────────────────────────────────────────────
test_pcc_sale_2pct {
    r := atomic.decide with input as {"pcc": {"transaction_type": "sale", "amount": 100000}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.pcc_sale.r1"
    r.pcc_rate_pct == 2.0
    r.pcc_tax_due == 2000.0
}

test_pcc_loan_05pct {
    r := atomic.decide with input as {"pcc": {"transaction_type": "loan", "amount": 100000}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.pcc_loan.r1"
    r.pcc_rate_pct == 0.5
    r.pcc_tax_due == 500.0
}

test_pcc_company_05pct {
    r := atomic.decide with input as {"pcc": {"transaction_type": "company", "amount": 100000}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.pcc_company.r1"
    r.pcc_tax_due == 500.0
}

test_pcc_vat_exclusion {
    r := atomic.decide with input as {"pcc": {"transaction_type": "sale", "amount": 100000, "vat_applicable": true}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.pcc_vat_exclusion.r1"
    r.pcc_tax_due == 0
}

test_pcc_small_value_exempt {
    r := atomic.decide with input as {"pcc": {"transaction_type": "sale", "amount": 500}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.pcc_small_value.r1"
    r.pcc_tax_due == 0
}

test_pcc3_deadline {
    r := atomic.decide with input as {"pcc": {"transaction_type": "sale", "amount": 100000, "days_elapsed": 5}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.pcc3_deadline.r1"
    r.pcc3_days_remaining == 9
}

# ── PODATKI LOKALNE ────────────────────────────────────────────────────────────
test_real_estate_building {
    r := atomic.decide with input as {"local": {"property_type": "building_business", "area_m2": 200}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.real_estate_building.r1"
    r.local_tax_annual == 6620.0
}

test_real_estate_land {
    r := atomic.decide with input as {"local": {"property_type": "land_business", "area_m2": 100}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.real_estate_land.r1"
    r.local_tax_annual == 143.0
}

test_transport_heavy {
    r := atomic.decide with input as {"local": {"gvw_t": 4.5}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.transport_heavy.r1"
    r.transport_taxable == true
}

test_transport_light_no_match {
    r := atomic.decide with input as {"local": {"gvw_t": 2.5}}
    r.matched == false
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.no_match"
}

test_dn1_deadline {
    r := atomic.decide with input as {"local": {"dn1_required": true}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.dn1_deadline.r1"
    r.dn1_deadline_days == 14
}

# ── AKCYZA ─────────────────────────────────────────────────────────────────────
test_excise_gasoline {
    r := atomic.decide with input as {"akcyza": {"product": "gasoline", "volume_l": 1000}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.excise_gasoline.r1"
    r.excise_due == 1566.0
}

test_excise_diesel {
    r := atomic.decide with input as {"akcyza": {"product": "diesel", "volume_l": 1000}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.excise_diesel.r1"
    r.excise_due == 1206.0
}

test_excise_ethanol {
    r := atomic.decide with input as {"akcyza": {"product": "ethanol", "volume_hl": 1}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.excise_ethanol.r1"
    r.excise_due == 6900.0
}

test_excise_wine {
    r := atomic.decide with input as {"akcyza": {"product": "wine", "volume_hl": 1}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.excise_wine.r1"
    r.excise_due == 185.0
}

test_excise_beer {
    r := atomic.decide with input as {"akcyza": {"product": "beer", "volume_hl": 1}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.excise_beer.r1"
    r.excise_due == 8.57
}

test_excise_warehouse {
    r := atomic.decide with input as {"akcyza": {"produces": true}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.excise_warehouse.r1"
    r.excise_warehouse_required == true
}

test_excise_energy {
    r := atomic.decide with input as {"akcyza": {"energy_electricity": true}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.excise_energy.r1"
}

# ── PODATEK ROLNY ──────────────────────────────────────────────────────────────
test_agricultural_tax {
    r := atomic.decide with input as {"rolny": {"hectares": 10}}
    r.matched == true
    r.rule_id == "jdg.micro.pcc_lokalne_atomic_p14.agricultural_tax.r1"
    r.agricultural_tax_annual == 2240.75
}
