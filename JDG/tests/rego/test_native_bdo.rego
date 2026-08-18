# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: BDO / ŚRODOWISKO / BUDOWNICTWO / TRANSPORT ATOMIC (GLM52 P15)
# Testy reguł atomowych rodo_aml_bdo_atomic_p15 (BDO): rejestracja art. 17-18
# (opłata 100-500 zł), ewidencja art. 49-55 (KPO), EWC, transport art. 66-74,
# kara art. 194 (5000 zł); budownictwo (pozwolenie art. 28 Pb); transport (licencja).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_bdo

import data.jdg.micro.rodo_aml_bdo_atomic_p15 as atomic

# ── Rejestracja BDO (art. 17-18) ──────────────────────────────────────────────
test_bdo_registration_required {
    r := atomic.decide with input as {"bdo": {"registration_required": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_registration.r1"
    r.bdo_registration_fee_pln == 100
    r._routing == "bdo_registration"
    "Dz.U. 2025 poz. 321" in r._legal_basis
}

test_bdo_registration_not_required {
    r := atomic.decide with input as {"bdo": {"registration_required": false}}
    r.matched == false
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.no_match"
}

# ── Ewidencja / KPO (art. 49-55) ──────────────────────────────────────────────
test_bdo_ewidencja_required {
    r := atomic.decide with input as {"bdo": {"ewidencja_required": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_ewidencja.r1"
    r._routing == "bdo_ewidencja"
}

test_bdo_ewidencja_not_required {
    r := atomic.decide with input as {"bdo": {"ewidencja_required": false}}
    r.matched == false
}

# ── EWC (katalog odpadów) ─────────────────────────────────────────────────────
test_bdo_ewc_paper {
    r := atomic.decide with input as {"bdo": {"waste_type": "paper"}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_ewc.r1"
    r.ewc_code == "20 01 01"
}

test_bdo_ewc_hazardous {
    r := atomic.decide with input as {"bdo": {"waste_type": "hazardous"}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_ewc.r1"
    r.ewc_code == "20 01 27*"
}

test_bdo_ewc_unknown_waste {
    r := atomic.decide with input as {"bdo": {"waste_type": "nieznany_odpad"}}
    r.matched == false
}

# ── Transport odpadów (art. 66-74) ────────────────────────────────────────────
test_bdo_transport_required {
    r := atomic.decide with input as {"bdo": {"transport_required": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_transport.r1"
    r._routing == "bdo_transport"
}

test_bdo_transport_not_required {
    r := atomic.decide with input as {"bdo": {"transport_required": false}}
    r.matched == false
}

# ── Kara art. 194 (5000 zł) ───────────────────────────────────────────────────
test_bdo_fine_art194 {
    r := atomic.decide with input as {"bdo": {"violation_detected": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.bdo_fine.r1"
    r.bdo_fine_pln == 5000
    r._routing == "bdo_fine"
}

test_bdo_fine_no_violation {
    r := atomic.decide with input as {"bdo": {"violation_detected": false}}
    r.matched == false
}

# ── Budownictwo (art. 28 Pb) ──────────────────────────────────────────────────
test_budownictwo_permit_required {
    r := atomic.decide with input as {"budownictwo": {"permit_required": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.budownictwo_permit.r1"
    r._routing == "budownictwo_permit"
    "Dz.U. 2025 poz. 1101" in r._legal_basis
}

test_budownictwo_permit_not_required {
    r := atomic.decide with input as {"budownictwo": {"permit_required": false}}
    r.matched == false
}

# ── Transport drogowy (licencja) ──────────────────────────────────────────────
test_transport_license_required {
    r := atomic.decide with input as {"transport": {"license_required": true}}
    r.matched == true
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.transport_license.r1"
    r._routing == "transport_license"
}

test_transport_license_not_required {
    r := atomic.decide with input as {"transport": {"license_required": false}}
    r.matched == false
}

# ── Brak sekcji bdo w inpucie → no_match ──────────────────────────────────────
test_bdo_missing_input_section {
    r := atomic.decide with input as {"other": {"flag": true}}
    r.matched == false
    r.rule_id == "jdg.micro.rodo_aml_bdo_atomic_p15.no_match"
}
