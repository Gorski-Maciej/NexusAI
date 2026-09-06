# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P14 PCC + Podatki Lokalne + Akcyza Enterprise — testy rego
# (RAPORT P14 v8.0)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p14_pcc_lokalne_akcyza

import future.keywords.in

round2(x) = r {
    r := round(x * 100) / 100
}

# ── 1. Mapa pokrycia artykułów PCC+lokalne+akcyza ─────────────────────────────
test_p14_coverage_report {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.pcc_local_excise_coverage_report with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true}} with
        data.jdg.p14_audit as {"articles": {
            "a1": {"status": "COMPLETE"}, "a2": {"status": "COMPLETE"},
            "a3": {"status": "COMPLETE"}, "a4": {"status": "COMPLETE"},
            "a6": {"status": "COMPLETE"}, "a7": {"status": "COMPLETE"},
            "a8": {"status": "COMPLETE"}, "a12": {"status": "COMPLETE"},
            "a16": {"status": "COMPLETE"}, "a26": {"status": "COMPLETE"},
            "a30": {"status": "COMPLETE"}, "a99": {"status": "COMPLETE"},
        }}
    result.matched == true
    result.summary.total == 12
    result.summary.complete == 12
}

# ── 2. AUDYT PCC (PRIORYTET — art. 1-10) ──────────────────────────────────────
test_pcc_audit {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.pcc_audit with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true}}
    result.rates.SALE_MOVABLE == 2.0
    result.rates.LOAN == 0.5
    result.rates.MORTGAGE == 0.1
    result.pcc3_deadline_days == 14
    count(result.subject_art1) == 6
    result.exclusions_vat == "transakcje objęte VAT są wyłączone z PCC (art. 2 pkt 4)"
}

# ── 3. Auto-generator PCC-3 (INN-01 — art. 10, 14 dni) ────────────────────────
test_pcc3_generator {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.pcc3_generator with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "transaction": {"type": "SALE_MOVABLE", "amount": 100000}}
    result.tax_due == 2000.0
    result.rate_pct == 2.0
    result.deadline_days == 14
    result.small_value_exempt == false
    "PCC-3" in result.form
}

test_pcc3_generator_small_value {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.pcc3_generator with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "transaction": {"type": "SALE_MOVABLE", "amount": 500}}
    result.small_value_exempt == true
    result.tax_due == 10.0
}

# ── 4. Detektor czynności PCC (INN-02) ────────────────────────────────────────
test_pcc_detector {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.pcc_detector with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "document": {"type": "umowa_sprzedazy"}}
    result.taxable == true
    result.pcc_rate == 2.0
}

# ── 5. AUDYT PODATKÓW LOKALNYCH (PRIORYTET — Sekcja 2) ────────────────────────
test_local_taxes_audit {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.local_taxes_audit with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true}}
    result.real_estate.rates_2026.building_business == 33.10
    result.real_estate.dn1_deadline_days == 14
    result.transport.heavy_threshold_t == 3.5
    count(result.integrated_packages) == 5
}

# ── 6. Rejestr stawek gminnych (INN-03) ───────────────────────────────────────
test_gmina_rates_registry {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.gmina_rates_registry with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true, "gmina": "Warszawa"}}
    result.gmina == "Warszawa"
    result.registry.building_business_pln_m2 == 33.10
    result.auto_update == "zmiana stawek gminnych (uchwała rady gminy) → pipeline auto-aktualizacji thresholdów"
}

# ── 7. Symulator podatku od nieruchomości (INN-04) ────────────────────────────
test_real_estate_tax_calculator {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.real_estate_tax_calculator with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "property": {"land_business_m2": 100, "building_business_m2": 200}}
    result.land_tax == round2(100 * 1.43)
    result.building_tax == round2(200 * 33.10)
    result.total_annual == round2(100 * 1.43 + 200 * 33.10)
}

# ── 8. Kalkulator transportowy (INN-05 — >3,5t) ───────────────────────────────
test_transport_tax_calculator {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.transport_tax_calculator with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "vehicle": {"gvw_t": 4.5}}
    result.taxable == true
}

test_transport_tax_calculator_light {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.transport_tax_calculator with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "vehicle": {"gvw_t": 2.5}}
    result.taxable == false
}

# ── 9. Tracker terminów DN-1 (INN-06) ─────────────────────────────────────────
test_dn1_tracker {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.dn1_tracker with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true}}
    result.dn1_deadline_days == 14
    count(result.payment_schedule) == 4
}

# ── 10. AUDYT AKCYZY (Sekcja 3) ───────────────────────────────────────────────
test_excise_audit {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.excise_audit with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true}}
    result.fuel_2026.benzyna == 1566.0
    result.alcohol_2026.alkohol_etylowy_pln_hl == 6900.0
    "skład podatkowy" in result.excise_warehouse
}

# ── 11. Kalkulatory akcyzy (INN-07/08) ────────────────────────────────────────
test_excise_fuel_calculator {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.excise_fuel_calculator with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "fuel": {"type": "benzyna", "volume_l": 1000}}
    result.excise_due == 1566.0
}

test_excise_alcohol_calculator {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.excise_alcohol_calculator with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "alcohol": {"product": "alkohol_etylowy", "volume_hl": 1}}
    result.excise_due == 6900.0
    result.warehouse_required == true
}

# ── 12. Wykrywacz akcyzy w kosztach (INN-09) + skład (INN-11) ─────────────────
test_excise_cost_detector {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.excise_cost_detector with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true, "costs_with_excise": [
            {"cost": "paliwo", "excise_risk": true},
            {"cost": "biuro", "excise_risk": false},
        ]}}
    count(result.flagged) == 1
}

test_excise_warehouse_tracker {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.excise_warehouse_tracker with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true, "produces_alcohol": true}}
    result.warehouse_required == true
    "PRZESTĘPSTWO SKARBOWE" in result.alert
}

# ── 13. Luki i duplikaty (Sekcja 4) + pipeline (Sekcja 5) ─────────────────────
test_gaps_duplicates_audit {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.gaps_duplicates_audit with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true}} with
        data.jdg.p14_audit as {"total_rule_ids": 135, "duplicate_count": 2, "stub_count": 1}
    result.micro_total_rule_ids == 135
    result.duplicates == 2
    count(result.missing_areas) == 4
}

test_local_taxes_pipeline_snapshot {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.local_taxes_pipeline_snapshot with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true}}
    result.pipeline.step_1_ingest == "data.jdg.thresholds.pcc_local_excise (ADR-002) — stawki PCC, nieruchomości, akcyza"
    result.auto_update == "stawki gminne zmieniają się co roku (uchwały rad gmin) → auto-aktualizacja thresholdów lokalnych"
}

# ── 14. Główny decide (P14) + no_match ────────────────────────────────────────
test_p14_main_decide {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.decide with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true}}
    result.matched == true
    result.rule_id == "jdg.p14_pcc_lokalne_akcyza_innovations.report"
    result._routing == "REPORT"
    result.pcc.rates.LOAN == 0.5
    result.local_taxes.real_estate.rates_2026.building_business == 33.10
}

# ── 9b. NOWE INNOWACJE v9.1 (INN-13..INN-17) ────────────────────────────────
test_pcc_obligation_detector {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.pcc_obligation_detector with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "transaction": {"type": "kupno_pojazdu", "from_private_party": true,
                                   "vat_applicable": false, "amount": 50000}}
    result.pcc_obligation == true
    result.tax_due == 1000.0
    result._routing == "TRIAGE_QUEUE"
}

test_pcc_obligation_detector_vat_excluded {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.pcc_obligation_detector with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "transaction": {"type": "kupno_pojazdu", "from_private_party": true,
                                   "vat_applicable": true, "amount": 50000}}
    result.pcc_obligation == false
    result._routing == ""
}

test_pcc3_zero_click {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.pcc3_zero_click with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "transaction": {"type": "SALE_MOVABLE", "amount": 100000, "days_elapsed": 12}}
    result.tax_due == 2000.0
    result.days_remaining == 2
    result.urgency_alert == true
    result._routing == "TRIAGE_QUEUE"
}

test_gmina_rates_map {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.gmina_rates_map with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true, "gmina": "Warszawa"}}
    result.rates_current_year.building_business == 33.10
    result.rates_changed_ytd == true
    "Law Radar" in result.versioning
}

test_vat_vs_pcc_optimizer {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.vat_vs_pcc_optimizer with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "transaction": {"type": "kupno_pojazdu", "amount": 50000,
                                   "buyer_vat_deductible": false, "from_private_party": true}}
    result.recommendation == "OD_OSOBY_PRYWATNEJ_PCC_2"
    result._routing == "TRIAGE_QUEUE"
}

test_excise_import_detector {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.excise_import_detector with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "import_goods": {"goods": "olej napędowy"}}
    result.excise_goods == true
    result._routing == "TRIAGE_QUEUE"
}

test_excise_import_detector_clean {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.excise_import_detector with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true},
                  "import_goods": {"goods": "stal nierdzewna"}}
    result.excise_goods == false
    result._routing == ""
}

test_p14_main_decide_new_sections {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.decide with
        input as {"jdg_entrepreneur": {"p14_pcc_check": true}}
    result.pcc_detector.rule_id == "jdg.p14_pcc_lokalne_akcyza_innovations.pcc_obligation_detector"
    result.pcc3_click.days_remaining == 14
    result.gmina_map.rates_changed_ytd == true
    result.vat_pcc.recommendation == "ANALIZA"
    result.excise_import.excise_goods == false
}

test_p14_default_no_match {
    result := data.jdg.p14_pcc_lokalne_akcyza_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.matched == false
    result.rule_id == "jdg.p14_pcc_lokalne_akcyza_innovations.no_match"
}
