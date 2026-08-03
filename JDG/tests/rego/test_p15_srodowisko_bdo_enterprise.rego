# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P15 Środowisko + BDO + Branża Enterprise — testy rego
# (RAPORT P15 v8.0)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p15_srodowisko_bdo

import future.keywords.in

# ── 1. Mapa pokrycia modułów BDO + środowisko + budownictwo ───────────────────
test_p15_coverage_report {
    result := data.jdg.p15_srodowisko_bdo_innovations.srodowisko_bdo_coverage_report with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}} with
        data.jdg.p15_audit as {"modules": {
            "bdo_rejestracja": {"status": "COMPLETE"}, "bdo_ewidencja": {"status": "COMPLETE"},
            "bdo_ewc": {"status": "COMPLETE"}, "bdo_transport": {"status": "COMPLETE"},
            "bdo_zezwolenia": {"status": "COMPLETE"}, "bdo_weee_baterie": {"status": "COMPLETE"},
            "srodowisko": {"status": "COMPLETE"}, "budownictwo": {"status": "COMPLETE"},
        }}
    result.matched == true
    result.summary.total == 8
    result.summary.complete == 8
    result.summary.missing == 0
}

# ── 2. AUDYT BDO (PRIORYTET — Sekcja 1) ───────────────────────────────────────
test_bdo_audit {
    result := data.jdg.p15_srodowisko_bdo_innovations.bdo_audit with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    result.rejestracja.opłaty.mikro == 100
    result.rejestracja.opłaty.mały == 300
    result.rejestracja.kara_brak_rejestracji == 5000
    result.ewidencja.okres == "kwartalna"
    result.ewidencja.kpo_elektroniczne == true
    count(result.integrated_packages) == 7
}

# ── 3. Asystent BDO (INN-01) ──────────────────────────────────────────────────
test_bdo_assistant_unregistered {
    result := data.jdg.p15_srodowisko_bdo_innovations.bdo_assistant with
        input as {"jdg_entrepreneur": {"p15_branza_check": true, "bdo_registered": false, "company_size": "mikro"}}
    result.registered == false
    result.rejestracja_fee == 100
    "rejestracja w BDO wymagana" in result.alert
}

test_bdo_assistant_registered {
    result := data.jdg.p15_srodowisko_bdo_innovations.bdo_assistant with
        input as {"jdg_entrepreneur": {"p15_branza_check": true, "bdo_registered": true}}
    result.registered == true
    "zarejestrowany" in result.alert
}

# ── 4. Generator KPO (INN-02 — kody EWC) ──────────────────────────────────────
test_kpo_generator {
    result := data.jdg.p15_srodowisko_bdo_innovations.kpo_generator with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "waste": {"ewc_code": "17 01 01"}}
    result.kpo_required == true
    result.ewc_valid == true
    "KPO" in result.form
}

test_kpo_generator_empty {
    result := data.jdg.p15_srodowisko_bdo_innovations.kpo_generator with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "waste": {"ewc_code": ""}}
    result.kpo_required == false
}

# ── 5. Tracker terminów sprawozdań BDO (INN-03) ───────────────────────────────
test_bdo_deadline_tracker {
    result := data.jdg.p15_srodowisko_bdo_innovations.bdo_deadline_tracker with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    count(result.deadlines) == 4
    "15.03" in result.deadlines[1]
}

# ── 6. Tracker opłat produktowych (INN-04) ────────────────────────────────────
test_product_fee_tracker {
    result := data.jdg.p15_srodowisko_bdo_innovations.product_fee_tracker with
        input as {"jdg_entrepreneur": {"p15_branza_check": true, "packaging_kg": 100}}
    result.packaging_fee_due == 200.0
    result.packaging_fee_rate == 2.0
}

# ── 7. AUDYT BUDOWNICTWA (PRIORYTET — Sekcja 2) ───────────────────────────────
test_budownictwo_audit {
    result := data.jdg.p15_srodowisko_bdo_innovations.budownictwo_audit with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    count(result.integrated_packages) == 2
    "pozwolenie" in result.pozwolenie_zgloszenie
}

# ── 8. Kalkulator pozwolenia na budowę / zgłoszenia (INN-05) ──────────────────
test_budowlane_pozwolenie_permit {
    result := data.jdg.p15_srodowisko_bdo_innovations.budowlane_pozwolenie_calculator with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "project": {"type": "nowy_budynek"}}
    result.requires_permit == true
    result.requires_notice == false
}

test_budowlane_pozwolenie_notice {
    result := data.jdg.p15_srodowisko_bdo_innovations.budowlane_pozwolenie_calculator with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "project": {"type": "remont"}}
    result.requires_permit == false
    result.requires_notice == true
}

# ── 9. AUDYT TRANSPORTU I ROLNICTWA (Sekcja 3) ────────────────────────────────
test_transport_rolnictwo_audit {
    result := data.jdg.p15_srodowisko_bdo_innovations.transport_rolnictwo_audit with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    "licencja" in result.transport.licencja
    "rolnik ryczałtowy" in result.rolnictwo.rolnik_ryczałtowy
    result.rolnictwo.integrated == "jdg.micro.plan33_agricultural_tax"
}

# ── 10. AUDYT ZAWODÓW REGULOWANYCH, TAX-FREE, SEZONOWOŚCI (Sekcja 4) ──────────
test_regulated_taxfree_seasonal_audit {
    result := data.jdg.p15_srodowisko_bdo_innovations.regulated_taxfree_seasonal_audit with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    "VAT-REF" in result.taxfree.vat_ref
    result.taxfree.integrated == "jdg.taxfree (plan44/45)"
    result.sezonowość.integrated == "jdg.seasonal (plan44/45)"
}

# ── 11. AUDYT CBAM (Sekcja 5) ─────────────────────────────────────────────────
test_cbam_audit {
    result := data.jdg.p15_srodowisko_bdo_innovations.cbam_audit with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    "2023/956" in result.cbam.zakres
    count(result.integrated_packages) == 2
}

test_cbam_calculator {
    result := data.jdg.p15_srodowisko_bdo_innovations.cbam_calculator with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "import_goods": {"value": 50000, "co2_t": 10}}
    result.cbam_due_eur == 800.0
    result.embedded_emissions_t == 10
}

# ── 12. PIPELINE BDO (Sekcja 6 — ADR-002) ─────────────────────────────────────
test_bdo_pipeline_snapshot {
    result := data.jdg.p15_srodowisko_bdo_innovations.bdo_pipeline_snapshot with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    result.pipeline.step_1_ingest == "data.jdg.thresholds.bdo_environment (ADR-002) — opłaty BDO, kody EWC, CBAM"
    result.auto_update != ""
}

# ── 13. GENIALNE POMYSŁY (INN-07..INN-12) ─────────────────────────────────────
test_branza_compliance_panel {
    result := data.jdg.p15_srodowisko_bdo_innovations.branza_compliance_panel with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    count(result.checks) == 7
    result.compliance_score == 100
}

test_branza_template_hook {
    result := data.jdg.p15_srodowisko_bdo_innovations.branza_template_hook with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    result.hot_reload == true
    count(result.steps) == 4
}

test_regulated_profession_assistant {
    result := data.jdg.p15_srodowisko_bdo_innovations.regulated_profession_assistant with
        input as {"jdg_entrepreneur": {"p15_branza_check": true, "profession": "doradca podatkowy"}}
    result.regulated == true
    count(result.obowiązki) == 4
}

test_taxfree_calculator {
    result := data.jdg.p15_srodowisko_bdo_innovations.taxfree_calculator with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "sale": {"amount": 1230}}
    result.vat_refundable == 230.0
}

test_seasonal_assistant {
    result := data.jdg.p15_srodowisko_bdo_innovations.seasonal_assistant with
        input as {"jdg_entrepreneur": {"p15_branza_check": true, "seasonal": true, "season_months": 4}}
    result.seasonal == true
    result.season_months == 4
}

test_agricultural_tax_calculator {
    result := data.jdg.p15_srodowisko_bdo_innovations.agricultural_tax_calculator with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "farm": {"ha_conversion": 4}}
    result.tax_per_ha == 224.08
    result.annual_tax == 896.3
}

# ── 14. Główny decide (P15) + no_match ────────────────────────────────────────
test_p15_main_decide {
    result := data.jdg.p15_srodowisko_bdo_innovations.decide with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    result.matched == true
    result.rule_id == "jdg.p15_srodowisko_bdo_innovations.report"
    result._routing == "REPORT"
    result.bdo.rejestracja.opłaty.mikro == 100
    result.budownictwo.pozwolenie_zgloszenie != ""
}

test_p15_default_no_match {
    result := data.jdg.p15_srodowisko_bdo_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.matched == false
    result.rule_id == "jdg.p15_srodowisko_bdo_innovations.no_match"
}
