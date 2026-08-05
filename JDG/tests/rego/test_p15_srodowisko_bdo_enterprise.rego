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

# ── 14. R15 MAPA DROGOWA P0-1: opłaty produktowe per materiał ─────────────────
test_product_fee_material_map {
    result := data.jdg.p15_srodowisko_bdo_innovations.product_fee_material_map with
        input as {"jdg_entrepreneur": {"p15_branza_check": true, "packaging_material": "papier", "packaging_kg": 100}}
    result.matched == true
    result.fee_due == 50.0
    result.material_rate_pln_kg == 0.50
    result.materials_covered == 6
}

test_product_fee_material_map_plastic {
    result := data.jdg.p15_srodowisko_bdo_innovations.product_fee_material_map with
        input as {"jdg_entrepreneur": {"p15_branza_check": true, "packaging_material": "tworzywa_sztuczne", "packaging_kg": 100}}
    result.fee_due == 200.0
}

# ── 15. R15 MAPA DROGOWA P0-2: integracja API BDO ─────────────────────────────
test_bdo_api_integration_ready {
    result := data.jdg.p15_srodowisko_bdo_innovations.bdo_api_integration with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "bdo_api": {"configured": true, "credentials_valid": true}}
    result.ready == true
    result.kpo_submission.required == true
}

test_bdo_api_integration_not_ready {
    result := data.jdg.p15_srodowisko_bdo_innovations.bdo_api_integration with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    result.ready == false
    result.sprawozdania.deadline == "roczne sprawozdanie o odpadach — do 15.03"
}

# ── 16. R15 MAPA DROGOWA P1-1: pełny katalog EWC 6-cyfrowy ───────────────────
test_ewc_full_catalog_lookup {
    result := data.jdg.p15_srodowisko_bdo_innovations.ewc_full_catalog with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "waste": {"ewc_code": "17 01 01"}}
    result.found == true
    result.entry.name == "beton"
    result.entry.hazardous == false
    result.chapter == "17"
    result.catalog_size >= 250
    result.chapters_covered == 20
}

test_ewc_full_catalog_hazardous {
    result := data.jdg.p15_srodowisko_bdo_innovations.ewc_full_catalog with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "waste": {"ewc_code": "17 06 01*"}}
    result.code_normalized == "17 06 01"
    result.hazardous == true
    "azbest" in result.entry.name
}

test_ewc_full_catalog_unknown {
    result := data.jdg.p15_srodowisko_bdo_innovations.ewc_full_catalog with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "waste": {"ewc_code": "99 99 99"}}
    result.found == false
    "NIEZNANY" in result.entry.name
}

# ── 17. R15 MAPA DROGOWA P1-2: stawki podatku rolnego per gmina ───────────────
test_agricultural_tax_registry_gmina {
    result := data.jdg.p15_srodowisko_bdo_innovations.agricultural_tax_rate_registry with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "farm": {"gmina": "Warszawa", "ha_conversion": 4}}
    result.in_registry == true
    result.multiplier == 2.5
    result.tax_per_ha == 224.08
    result.annual_tax == 896.3
}

test_agricultural_tax_registry_default {
    result := data.jdg.p15_srodowisko_bdo_innovations.agricultural_tax_rate_registry with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "farm": {"gmina": "Mała Wioska", "ha_conversion": 2}}
    result.in_registry == false
    result.multiplier == 2.5
}

# ── 18. R15 MAPA DROGOWA P1-3: tabele zezwoleń transportowych ────────────────
test_transport_permit_tables {
    result := data.jdg.p15_srodowisko_bdo_innovations.transport_permit_tables with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "transport": {"route_type": "krajowy"}}
    "krajowy przewóz drogowy" in result.permit.dokument
    result.permit.legal_basis == "art. 5 u.t.d."
    result.tachograf.prog_t == 3.5
    result.tables_covered == 4
}

test_transport_permit_tables_poza_ue {
    result := data.jdg.p15_srodowisko_bdo_innovations.transport_permit_tables with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "transport": {"route_type": "poza_ue"}}
    "ECMT" in result.permit.dokument
}

# ── 19. R15 MAPA DROGOWA P2-1: certyfikaty CBAM 2026 ──────────────────────────
test_cbam_certificates_2026 {
    result := data.jdg.p15_srodowisko_bdo_innovations.cbam_certificates_2026 with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "import_goods": {"authorized_declarant": true, "co2_t": 10}}
    result.certificates_required == true
    result.certificates_to_purchase_eur == 800.0
    result.definitive_regime_from == "2026-01-01"
    result.surrender_deadline == "31.05"
    result.penalty_eur_t == 50.0
}

# ── 20. R15 MAPA DROGOWA P2-2: rejestracja online w BDO ───────────────────────
test_bdo_online_registration {
    result := data.jdg.p15_srodowisko_bdo_innovations.bdo_online_registration with
        input as {"jdg_entrepreneur": {"p15_branza_check": true, "company_size": "mikro"},
                  "bdo_api": {"registration_status": "nie_zarejestrowany"}}
    result.registration_status == "nie_zarejestrowany"
    "wniosek online wymagany" in result.alert
    result.rejestracja_fee == 100
    count(result.steps) == 4
    result.update_deadline_days == 30
}

test_bdo_online_registration_status {
    result := data.jdg.p15_srodowisko_bdo_innovations.bdo_online_registration with
        input as {"jdg_entrepreneur": {"p15_branza_check": true},
                  "bdo_api": {"registration_status": "zarejestrowany"}}
    result.alert == "status: zarejestrowany"
}

# ── 21. R15 MAPA DROGOWA: roadmap_v2 w głównym decide ─────────────────────────
test_p15_roadmap_v2_in_decide {
    result := data.jdg.p15_srodowisko_bdo_innovations.decide with
        input as {"jdg_entrepreneur": {"p15_branza_check": true}}
    result.roadmap_v2.product_fee_material_map.matched == true
    result.roadmap_v2.bdo_api_integration.matched == true
    result.roadmap_v2.ewc_full_catalog.matched == true
    result.roadmap_v2.agricultural_tax_rate_registry.matched == true
    result.roadmap_v2.transport_permit_tables.matched == true
    result.roadmap_v2.cbam_certificates_2026.matched == true
    result.roadmap_v2.bdo_online_registration.matched == true
}

# ── 22. Główny decide (P15) + no_match ────────────────────────────────────────
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
