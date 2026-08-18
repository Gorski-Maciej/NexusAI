# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE TESTS: HYPER PLAN45 / KONTEKSTY (GLM52 P16)
# Testy pakietów jdg.hyper.*: general (danina solidarnościowa, WIS, kontrola,
# siła wyższa, rodzina, e-Doręczenia), limits (sezonowość), deadlines (terminy,
# ubezpieczenia), sanctions (KKS/sankcje).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.native_hyper

import data.jdg.hyper.general as hyper_general
import data.jdg.hyper.limits as hyper_limits
import data.jdg.hyper.deadlines as hyper_deadlines
import data.jdg.hyper.sanctions as hyper_sanctions

# ── Danina solidarnościowa (art. 30h PIT, dochód > 1M PLN) ────────────────────
test_hyper_general_solidarity_levy {
    r := hyper_general.decide with input as {"jdg_entrepreneur": {"annual_income": 1500000}}
    r.matched == true
    r.rule_id == "jdg.hyper.general.solidarity.levy.base.calculation"
    "Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)" in r._legal_basis
}

test_hyper_general_solidarity_levy_no_match_below_1m {
    r := hyper_general.decide with input as {"jdg_entrepreneur": {"annual_income": 500000}}
    r.matched == false
    r.rule_id == "jdg.hyper.general.no_match"
}

# ── WIS (art. 42h VAT) ─────────────────────────────────────────────────────────
test_hyper_general_wis_required {
    r := hyper_general.decide with input as {"invoice": {"wis_required": true}}
    r.matched == true
    r.rule_id == "jdg.hyper.general.wis.monitoring.expiry_alert_6months"
    "Art. 42h ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)" in r._legal_basis
}

test_hyper_general_wis_not_required {
    r := hyper_general.decide with input as {"invoice": {"wis_required": false}}
    r.matched == false
}

# ── Kontrola podatkowa (OrdPU) — przedsiębiorca ACTIVE ────────────────────────
test_hyper_general_audit_trigger {
    r := hyper_general.decide with input as {"jdg_entrepreneur": {"business_status": "ACTIVE"}}
    r.matched == true
    r.rule_id == "jdg.hyper.general.audit.trigger.return_to_correct"
    "Art. 274 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)" in r._legal_basis
}

# ── Siła wyższa (art. 67a/67b OrdPU) ──────────────────────────────────────────
test_hyper_general_force_majeure {
    r := hyper_general.decide with input as {"jdg_entrepreneur": {"force_majeure_declared": true}}
    r.matched == true
    r.rule_id == "jdg.hyper.general.force_majeure.relief.deadline_extension"
    "Art. 67a § 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)" in r._legal_basis
}

# ── Rodzina / transakcje rodzinne ──────────────────────────────────────────────
test_hyper_general_family_spouse {
    r := hyper_general.decide with input as {"vendor": {"relation_to_entrepreneur": "spouse"}}
    r.matched == true
    r.rule_id == "jdg.hyper.general.family.spouse.contract_type.b2b"
}

# ── KKS — ryzyko skazania ──────────────────────────────────────────────────────
test_hyper_general_kks_risk {
    r := hyper_general.decide with input as {"invoice": {"kks_risk_detected": true}}
    r.matched == true
    r.rule_id == "jdg.hyper.general.kks.conviction.bank_account_termination"
}

# ── LIMITS: sezonowość JDG (art. 22 Prawo przedsiębiorców) ────────────────────
test_hyper_limits_seasonal {
    r := hyper_limits.decide with input as {"invoice": {"amount_gross": 12000}}
    r.matched == true
    r.rule_id == "jdg.hyper.limits.seasonal.detection.months_with_revenue"
    "Art. 22 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)" in r._legal_basis
}

test_hyper_limits_no_revenue {
    r := hyper_limits.decide with input as {"invoice": {"amount_gross": 0}}
    r.matched == false
    r.rule_id == "jdg.hyper.limits.no_match"
}

# ── DEADLINES: termin < 30 dni ─────────────────────────────────────────────────
test_hyper_deadlines_insurance {
    r := hyper_deadlines.decide with input as {"invoice": {"days_to_deadline": 15}}
    r.matched == true
    r.rule_id == "jdg.hyper.deadlines.insurance.mandatory.detection_construction"
}

test_hyper_deadlines_no_trigger {
    r := hyper_deadlines.decide with input as {"invoice": {"days_to_deadline": 60}}
    r.matched == false
    r.rule_id == "jdg.hyper.deadlines.no_match"
}

# ── SANCTIONS: naruszenie compliance ───────────────────────────────────────────
test_hyper_sanctions_violation {
    r := hyper_sanctions.decide with input as {"invoice": {"compliance_violation": true}}
    r.matched == true
    r.rule_id == "jdg.hyper.sanctions.kks.conviction.extended_audit_period"
}

test_hyper_sanctions_clean {
    r := hyper_sanctions.decide with input as {"invoice": {"compliance_violation": false}}
    r.matched == false
    r.rule_id == "jdg.hyper.sanctions.no_match"
}
