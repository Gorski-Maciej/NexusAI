# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P12 Cross-Border/MDR/TP/CFC/FX Enterprise — testy rego
# (RAPORT P12 v8.0)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p12_crossborder

import future.keywords.in

# ── 1. Mapa pokrycia artykułów cross-border ───────────────────────────────────
test_crossborder_coverage_report {
    result := data.jdg.p12_crossborder_innovations.crossborder_coverage_report with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}} with
        data.jdg.crossborder_audit as {"articles": {
            "a20": {"status": "COMPLETE"}, "a23o": {"status": "COMPLETE"},
            "a23zf": {"status": "COMPLETE"}, "a29": {"status": "COMPLETE"},
            "a30da": {"status": "COMPLETE"}, "a30f": {"status": "COMPLETE"},
            "a86r": {"status": "COMPLETE"},
        }}
    result.matched == true
    result.summary.total == 12
    result.summary.complete == 7
}

# ── 2. AUDYT WNT/WDT/EXPORT/IMPORT (Sekcja 1) ─────────────────────────────────
test_wnt_wdt_audit {
    result := data.jdg.p12_crossborder_innovations.wnt_wdt_audit with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}}
    result.wnt.vat_rate == 0.23
    result.wnt.deductible == true
    result.wdt.rate == "0%"
    result.wdt.documentation_deadline_days == 30
    result.export == "eksport towarów poza UE — 0% + dokument celny (art. 2 pkt 8 VAT)"
}

# ── 3. MIEJSCE ŚWIADCZENIA B2B/B2C (PRIORYTET — art. 28a-28o) ────────────────
test_place_of_supply_audit {
    result := data.jdg.p12_crossborder_innovations.place_of_supply_audit with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}}
    result.art28a_28o.b2b_services == "miejsce siedziby nabywcy (art. 28b)"
    result.art28a_28o.e_services_b2c == "miejsce konsumenta (art. 28i) — OSS"
    result.art28a_28o.platforms == "domniemany dostawca platform cyfrowych (art. 28m)"
}

test_place_of_supply_calculator_b2b {
    result := data.jdg.p12_crossborder_innovations.place_of_supply_calculator with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true},
                  "service": {"type": "b2b", "customer_country": "DE", "vendor_country": "PL"}}
    result.supply_place == "siedziba_nabywcy"
    result.vat_place == "miejsce siedziby nabywcy B2B (art. 28b)"
    result.cross_border == true
}

test_place_of_supply_calculator_eservices {
    result := data.jdg.p12_crossborder_innovations.place_of_supply_calculator with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true},
                  "service": {"type": "e_services", "customer_country": "FR", "vendor_country": "PL"}}
    result.supply_place == "miejsce_konsumenta"
    result.vat_place == "miejsce konsumenta e-usługi (art. 28i, OSS)"
}

# ── 4. AUDYT MDR/DAC6 (Sekcja 3) ──────────────────────────────────────────────
test_mdr_audit {
    result := data.jdg.p12_crossborder_innovations.mdr_audit with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}}
    result.report_deadline_days == 30
    result.report_to == "Szef Krajowej Administracji Skarbowej (formularz MDR-1)"
    count(result.roles) == 3
}

test_mdr_auto_detector {
    result := data.jdg.p12_crossborder_innovations.mdr_auto_detector with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true},
                  "transaction": {"tax_saving_primary": true, "cross_border_related": true}}
    result.mdr_report_required == true
    "A" in result.matched_hallmarks
    "C" in result.matched_hallmarks
}

# ── 5. AUDYT TP/CFC/REZYDENCJI/FX (Sekcja 4) ──────────────────────────────────
test_tp_cfc_residency_audit {
    result := data.jdg.p12_crossborder_innovations.tp_cfc_residency_audit with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}}
    result.tp.local_file == 500000
    result.tp.master_file == 200000000
    result.cfc.ownership_min_pct == 50
    result.cfc.passive_income_threshold_pct == 33
    result.residency.days_threshold == 183
}

test_residency_decision_engine {
    result := data.jdg.p12_crossborder_innovations.residency_decision_engine with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true, "days_in_poland": 200}}
    result.resident_pl == true
}

test_residency_decision_engine_nonresident {
    result := data.jdg.p12_crossborder_innovations.residency_decision_engine with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true, "days_in_poland": 100,
                                       "center_of_life_pl": false, "center_of_business_pl": false}}
    result.resident_pl == false
}

# ── 6. ViDA/DRR/DAC8/EXIT TAX (Sekcja 5) ──────────────────────────────────────
test_vida_dac8_exit_tax_audit {
    result := data.jdg.p12_crossborder_innovations.vida_dac8_exit_tax_audit with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}}
    result.exit_tax.threshold_pln == 4000000
    result.exit_tax.rate_pct == 19
    "ViDA" in result.vida.timeline
}

test_exit_tax_calculator {
    result := data.jdg.p12_crossborder_innovations.exit_tax_calculator with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true, "assets_value": 5000000}}
    result.exit_tax_applies == true
    result.tax_due == 950000.0
    result.installments == "rozłożenie na raty do 5 lat (art. 30db PIT)"
}

# ── 7. GENIALNE POMYSŁY (INN-04..INN-12) ──────────────────────────────────────
test_wdt_documentation_tracker {
    result := data.jdg.p12_crossborder_innovations.wdt_documentation_tracker with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}, "deliveries": [
            {"delivery_id": "D-1", "documentation_ok": true},
            {"delivery_id": "D-2", "documentation_ok": false},
        ]}
    result.deadline_days == 30
    count(result.documents_missing) == 1
}

test_tp_documentation_calculator {
    result := data.jdg.p12_crossborder_innovations.tp_documentation_calculator with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true, "related_party_revenue": 600000}}
    result.local_file_required == true
    result.master_file_required == false
}

test_fx_difference_calculator {
    result := data.jdg.p12_crossborder_innovations.fx_difference_calculator with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true},
                  "fx": {"receivable_fx": 10000, "exchange_rate_receipt": 4.20, "exchange_rate_due": 4.30}}
    result.fx_difference == 1000.0
    "metoda podatkowa" in result.method
}

test_cfc_calculator {
    result := data.jdg.p12_crossborder_innovations.cfc_calculator with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true},
                  "cfc": {"ownership_pct": 60, "passive_income_pct": 40, "effective_tax_rate": 10}}
    result.cfc_applies == true
}

test_eu_treaty_monitor {
    result := data.jdg.p12_crossborder_innovations.eu_treaty_monitor with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}}
    result.brexit.uk_status == "Państwo trzecie (poza UE)"
    result.brexit.eori_required == true
}

# ── 8. Pipeline + hook + panel (Sekcja 6-7) ───────────────────────────────────
test_crossborder_pipeline_snapshot {
    result := data.jdg.p12_crossborder_innovations.crossborder_pipeline_snapshot with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}}
    result.pipeline.step_1_ingest == "data.jdg.thresholds.crossborder (ADR-002) — progi, terminy"
    result.pipeline.step_4_emit == "hot-reload pakietów jdg.crossborder / jdg.mdr / jdg.tp / jdg.fx"
    result.auto_update == "zmiany prawa UE (ViDA/DRR) → pipeline auto-aktualizacji reguł cross-border"
}

test_crossborder_compliance_panel {
    result := data.jdg.p12_crossborder_innovations.crossborder_compliance_panel with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}}
    count(result.checks) == 7
    result.compliance_score == 100
}

# ── 9. Główny decide (P12) + no_match ─────────────────────────────────────────
test_p12_main_decide {
    result := data.jdg.p12_crossborder_innovations.decide with
        input as {"jdg_entrepreneur": {"p12_crossborder_check": true}}
    result.matched == true
    result.rule_id == "jdg.p12_crossborder_innovations.report"
    result._routing == "REPORT"
    result.place_of_supply.art28a_28o.b2b_services == "miejsce siedziby nabywcy (art. 28b)"
    result.mdr.report_deadline_days == 30
}

test_p12_default_no_match {
    result := data.jdg.p12_crossborder_innovations.decide with input as {"jdg_entrepreneur": {"tax_year": 2026}}
    result.matched == false
    result.rule_id == "jdg.p12_crossborder_innovations.no_match"
}
