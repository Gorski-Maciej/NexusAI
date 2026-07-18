# 📋 JDG MANIFEST — Tracker Pokrycia Reguł vs Mapa Kanoniczna 38c

> **Auto-generowane:** 2026-07-14 02:54:32
> **Aktualizacja strategiczna:** 2026-07-18 (S1-S5 Enterprise v5.0 + Class IX complete)
> **Plików Rego:** 168
> **Reguł:** ~9900
> **Narzędzi strategicznych:** 9 (A1-A3, B1-B3, C1-C3) + 5 (S1-S5 Enterprise)
> **Mapa kanoniczna:** `Plan OPA/38c_JDG_CANONICAL_MAP.md` (~779 reguł)

---

## 🛠️ NARZĘDZIA STRATEGICZNE (9 Inicjatyw A1-C3)

| Inicjatywa | Nazwa | Plik | Status |
|:---------:|-------|------|:------:|
| A1 | Verdict Provenance Graph | `JDG/rules/provenance.rego` | ✅ |
| A2 | Temporal Causality Chain | `JDG/rules/_metadata_jdg.rego` | ✅ |
| A3 | Legal Cartography RDF | `JDG/rules/_metadata_jdg.rego` | ✅ |
| B1 | Inverted Sharded Index | `JDG/rules/main_jdg.rego` (routing_context) | ✅ |
| B2 | Decoupled Thresholds | `JDG/rules/thresholds_jdg.rego` | ✅ |
| B3 | DRY Compiler + CI Linting | `JDG/tools/lint_rego_rules.py` | ✅ |
| C1 | Judgment Predictor | `JDG/tools/judgment_predictor.py` | ✅ |
| C2 | LLM Co-Pilot Bridge | `JDG/tools/llm_bridge.py` | ✅ |
| C3 | Live Legal Radar | `JDG/tools/isap_crawler.py` | ✅ |
| S1 | Tax Optimization Engine | `JDG/rules/tax_optimization_enterprise.rego` | ✅ |
| S2 | Cross-Domain Intelligence Hub | `JDG/rules/cross_domain_intelligence_enterprise.rego` | ✅ |
| S3 | Judicial Rulings & Interpretations | `JDG/rules/judicial_interpretations_enterprise.rego` | ✅ |
| S4 | Audit Defense & Tax Control | `JDG/rules/audit_defense_enterprise.rego` | ✅ |
| S5 | Strategic Business Advisor | `JDG/rules/strategic_advisor_enterprise.rego` | ✅ |

### Pliki conftest/data/
| Plik | Opis |
|------|------|
| `conftest/data/canonical_map.json` | Rejestr mapy kanonicznej rule_id |
| `conftest/data/legal_basis_map.json` | Mapa podstaw prawnych (13 aktów) |
| `conftest/data/temporal_registry.json` | Rejestr temporalny (seed data) |

---

## 📊 REGUŁY PER PLIK

| Plik | Reguł | BLOCK | TRIAGE |
|------|:-----:|:-----:|:------:|
| `rules/accounting.rego` | 67 | 6 | 13 |
| `rules/accounting/plan23_leasing.rego` | 5 | 0 | 1 |
| `rules/accounting/plan42_pkpir.rego` | 1 | 1 | 0 |
| `rules/accounting/pkpir_enterprise_validation.rego` | 32 | 4 | 6 |
| `rules/accounting/pkpir_enterprise_validator.rego` | 19 | 4 | 2 |
| `rules/advertising/plan44_advertising.rego` | 9 | 0 | 0 |
| `rules/advertising/plan45_advertising.rego` | 8 | 0 | 0 |
| `rules/allowances.rego` | 12 | 0 | 0 |
| `rules/allowances/plan23_reliefs.rego` | 9 | 0 | 0 |
| `rules/audit/plan44_audit.rego` | 15 | 1 | 2 |
| `rules/audit/plan45_audit.rego` | 16 | 2 | 4 |
| `rules/business.rego` | 8 | 3 | 1 |
| `rules/business/plan26_suspension_succession.rego` | 5 | 3 | 1 |
| `rules/calendar/plan44_calendar.rego` | 6 | 0 | 0 |
| `rules/calendar/plan45_calendar.rego` | 6 | 0 | 0 |
| `rules/compliance.rego` | 9 | 3 | 0 |
| `rules/conflicts.rego` | 27 | 6 | 11 |
| `rules/conviction/plan44_conviction.rego` | 6 | 2 | 0 |
| `rules/conviction/plan45_conviction.rego` | 7 | 3 | 0 |
| `rules/corrections.rego` | 16 | 2 | 5 |
| `rules/crossborder.rego` | 18 | 3 | 4 |
| `rules/crossborder/plan23_ue.rego` | 8 | 1 | 2 |
| `rules/digital.rego` | 6 | 3 | 0 |
| `rules/edelivery/plan44_edelivery.rego` | 8 | 1 | 0 |
| `rules/edelivery/plan45_edelivery.rego` | 6 | 1 | 1 |
| `rules/edge_cases.rego` | 149 | 35 | 51 |
| `rules/employer.rego` | 13 | 3 | 0 |
| `rules/environmental.rego` | 8 | 3 | 0 |
| `rules/esig/plan44_esig.rego` | 7 | 0 | 0 |
| `rules/esig/plan45_esig.rego` | 6 | 0 | 0 |
| `rules/fallback.rego` | 1 | 0 | 0 |
| `rules/family/plan44_family.rego` | 10 | 0 | 3 |
| `rules/family/plan45_family.rego` | 8 | 1 | 0 |
| `rules/force_majeure/plan44_force_majeure.rego` | 8 | 0 | 2 |
| `rules/force_majeure/plan45_force_majeure.rego` | 7 | 0 | 3 |
| `rules/fx/plan44_fx.rego` | 9 | 0 | 0 |
| `rules/fx/plan45_fx.rego` | 7 | 0 | 0 |
| `rules/insurance/plan44_insurance.rego` | 6 | 1 | 0 |
| `rules/insurance/plan45_insurance.rego` | 8 | 1 | 0 |
| `rules/international.rego` | 4 | 0 | 1 |
| `rules/jdg/hyper/audit/plan45.rego` | 21 | 0 | 0 |
| `rules/jdg/hyper/deadlines/plan45.rego` | 41 | 0 | 0 |
| `rules/jdg/hyper/edelivery/plan45.rego` | 21 | 0 | 0 |
| `rules/jdg/hyper/family/plan45.rego` | 21 | 0 | 0 |
| `rules/jdg/hyper/force_majeure/plan45.rego` | 21 | 0 | 0 |
| `rules/jdg/hyper/fx/plan45.rego` | 21 | 0 | 0 |
| `rules/jdg/hyper/general/plan45.rego` | 100 | 0 | 0 |
| `rules/jdg/hyper/limits/plan45.rego` | 33 | 0 | 0 |
| `rules/jdg/hyper/mdr/plan45.rego` | 38 | 0 | 0 |
| `rules/jdg/hyper/misc/plan45.rego` | 49 | 0 | 0 |
| `rules/jdg/hyper/procurement/plan45.rego` | 21 | 0 | 0 |
| `rules/jdg/hyper/sanctions/plan45.rego` | 41 | 0 | 0 |
| `rules/jdg/hyper/solidarity/plan45.rego` | 11 | 0 | 0 |
| `rules/jdg/hyper/wis/plan45.rego` | 16 | 0 | 0 |
| `rules/jpk/plan26_deadlines.rego` | 1 | 0 | 0 |
| `rules/kks.rego` | 249 | 165 | 61 |
| `rules/kks/plan42_detailed.rego` | 12 | 7 | 1 |
| `rules/kks/plan43_decomposition.rego` | 21 | 10 | 1 |
| `rules/kks/plan44_kks_conviction.rego` | 2 | 1 | 0 |
| `rules/ksef_jpk.rego` | 6 | 0 | 1 |
| `rules/liability.rego` | 10 | 0 | 1 |
| `rules/local_taxes.rego` | 13 | 0 | 4 |
| `rules/local_taxes/pcc.rego` | 3 | 0 | 2 |
| `rules/local_taxes/plan26_local.rego` | 6 | 0 | 1 |
| `rules/local_taxes/real_estate.rego` | 2 | 0 | 2 |
| `rules/local_taxes/transport.rego` | 1 | 0 | 1 |
| `rules/mdr/plan44_mdr.rego` | 10 | 1 | 7 |
| `rules/mdr/plan45_mdr.rego` | 17 | 2 | 14 |
| `rules/micro/akcyza/akcyza.rego` | 32 | 0 | 0 |
| `rules/micro/aml/aml.rego` | 44 | 0 | 0 |
| `rules/micro/ceidg/ceidg.rego` | 34 | 0 | 0 |
| `rules/micro/crossborder/crossborder.rego` | 72 | 0 | 0 |
| `rules/micro/jpk/jpk.rego` | 35 | 1 | 0 |
| `rules/micro/kks/kks.rego` | 375 | 8 | 0 |
| `rules/micro/ksef/ksef.rego` | 79 | 2 | 0 |
| `rules/micro/ord/ord.rego` | 318 | 3 | 0 |
| `rules/micro/pcc/pcc.rego` | 89 | 1 | 0 |
| `rules/micro/pit/pit.rego` | 521 | 24 | 0 |
| `rules/micro/plan33_agricultural_tax.rego` | 5 | 0 | 0 |
| `rules/micro/plan33_cb.rego` | 20 | 0 | 0 |
| `rules/micro/plan33_ceidg.rego` | 15 | 0 | 0 |
| `rules/micro/plan33_est.rego` | 15 | 0 | 0 |
| `rules/micro/plan33_health.rego` | 40 | 0 | 0 |
| `rules/micro/plan33_jpk.rego` | 70 | 0 | 0 |
| `rules/micro/plan33_kks.rego` | 64 | 0 | 0 |
| `rules/micro/plan33_ksef.rego` | 74 | 0 | 0 |
| `rules/micro/plan33_mdr.rego` | 10 | 0 | 0 |
| `rules/micro/plan33_pcc.rego` | 59 | 0 | 0 |
| `rules/micro/plan33_pit.rego` | 86 | 0 | 0 |
| `rules/micro/plan33_prop.rego` | 30 | 0 | 0 |
| `rules/micro/plan33_prop_transport.rego` | 5 | 0 | 0 |
| `rules/micro/plan33_rodo.rego` | 10 | 0 | 0 |
| `rules/micro/plan33_ryc.rego` | 158 | 0 | 0 |
| `rules/micro/plan33_succ.rego` | 20 | 0 | 0 |
| `rules/micro/plan33_tax_trans.rego` | 10 | 0 | 0 |
| `rules/micro/plan33_tp.rego` | 15 | 0 | 0 |
| `rules/micro/plan33_uor.rego` | 25 | 0 | 0 |
| `rules/micro/plan33_vat.rego` | 115 | 0 | 0 |
| `rules/micro/plan33_zus.rego` | 180 | 0 | 0 |
| `rules/micro/plan34_ord.rego` | 189 | 0 | 0 |
| `rules/micro/plan34_pit.rego` | 265 | 0 | 0 |
| `rules/micro/plan34_vat.rego` | 179 | 0 | 0 |
| `rules/micro/plan34_zus.rego` | 20 | 0 | 0 |
| `rules/micro/pp/pp.rego` | 92 | 1 | 0 |
| `rules/micro/rodo/rodo.rego` | 40 | 0 | 0 |
| `rules/micro/ryczalt/ryczalt.rego` | 97 | 5 | 0 |
| `rules/micro/srodowisko/srodowisko.rego` | 48 | 0 | 0 |
| `rules/micro/sukcesja/sukcesja.rego` | 38 | 0 | 0 |
| `rules/micro/sus/sus.rego` | 122 | 0 | 0 |
| `rules/micro/transport/transport.rego` | 44 | 0 | 0 |
| `rules/micro/uor/uor.rego` | 124 | 4 | 0 |
| `rules/micro/vat/vat.rego` | 571 | 27 | 0 |
| `rules/micro/zasilkowa/zasilkowa.rego` | 38 | 0 | 0 |
| `rules/micro/zdrowotna/zdrowotna.rego` | 62 | 2 | 0 |
| `rules/mpips.rego` | 12 | 0 | 5 |
| `rules/payments/plan44_payments.rego` | 9 | 0 | 0 |
| `rules/payments/plan45_payments.rego` | 13 | 1 | 0 |
| `rules/pcc/plan42_pcc.rego` | 4 | 0 | 0 |
| `rules/pit/advances_returns.rego` | 8 | 1 | 0 |
| `rules/pit/exemptions.rego` | 6 | 0 | 0 |
| `rules/pit/forms.rego` | 10 | 5 | 0 |
| `rules/pit/kup.rego` | 10 | 1 | 0 |
| `rules/pit/plan23_exemptions.rego` | 1 | 1 | 0 |
| `rules/pit/plan23_tax_form_change.rego` | 7 | 1 | 0 |
| `rules/pit/plan26_detailed.rego` | 11 | 5 | 0 |
| `rules/pit/transitions.rego` | 5 | 0 | 1 |
| `rules/procurement/plan44_procurement.rego` | 7 | 1 | 0 |
| `rules/procurement/plan45_procurement.rego` | 6 | 1 | 0 |
| `rules/regulated/plan44_regulated.rego` | 8 | 0 | 0 |
| `rules/regulated/plan45_regulated.rego` | 6 | 1 | 0 |
| `rules/representation.rego` | 7 | 3 | 0 |
| `rules/representation/plan26_prokura.rego` | 1 | 1 | 0 |
| `rules/residency/plan44_residency.rego` | 10 | 1 | 3 |
| `rules/residency/plan45_residency.rego` | 9 | 1 | 1 |
| `rules/restructuring.rego` | 7 | 5 | 0 |
| `rules/retention.rego` | 6 | 1 | 0 |
| `rules/risk.rego` | 8 | 7 | 1 |
| `rules/risk/plan26_kks_gaar.rego` | 4 | 2 | 2 |
| `rules/rodo.rego` | 12 | 2 | 10 |
| `rules/rodo/plan42_rodo.rego` | 3 | 0 | 1 |
| `rules/routing.rego` | 5 | 2 | 3 |
| `rules/seasonal/plan44_seasonal.rego` | 7 | 0 | 0 |
| `rules/seasonal/plan45_seasonal.rego` | 6 | 0 | 0 |
| `rules/solidarity/plan44_solidarity.rego` | 5 | 1 | 0 |
| `rules/solidarity/plan45_solidarity.rego` | 9 | 1 | 0 |
| `rules/statute/plan26_detailed.rego` | 9 | 1 | 1 |
| `rules/statute_of_limitations.rego` | 14 | 5 | 6 |
| `rules/taxfree/plan44_taxfree.rego` | 6 | 0 | 0 |
| `rules/taxfree/plan45_taxfree.rego` | 5 | 0 | 0 |
| `rules/temporal.rego` | 9 | 3 | 0 |
| `rules/tp/plan44_tp.rego` | 9 | 2 | 3 |
| `rules/tp/plan45_tp.rego` | 8 | 2 | 0 |
| `rules/uor/plan42_uor.rego` | 5 | 0 | 1 |
| `rules/validation.rego` | 8 | 5 | 3 |
| `rules/vat/deductions.rego` | 26 | 5 | 3 |
| `rules/vat/plan23_detailed.rego` | 16 | 3 | 1 |
| `rules/vat/plan26_critical.rego` | 16 | 3 | 1 |
| `rules/vat/plan42_reduced_rates.rego` | 6 | 0 | 4 |
| `rules/vat/procedures.rego` | 17 | 1 | 1 |
| `rules/vat/substantive.rego` | 46 | 2 | 3 |
| `rules/wis/plan44_wis.rego` | 8 | 0 | 0 |
| `rules/wis/plan45_wis.rego` | 9 | 0 | 0 |
| `rules/zus.rego` | 21 | 0 | 3 |
| `rules/zus/plan23_interactions.rego` | 9 | 0 | 0 |
| `rules/zus/plan42_benefits.rego` | 8 | 1 | 1 |
| **─── ENTERPRISE v5.0 (S1-S5) ───** | | | |
| `rules/tax_optimization_enterprise.rego` | 6 | 0 | 5 |
| `rules/cross_domain_intelligence_enterprise.rego` | 4 | 0 | 3 |
| `rules/judicial_interpretations_enterprise.rego` | 5 | 1 | 3 |
| `rules/audit_defense_enterprise.rego` | 5 | 2 | 3 |
| `rules/strategic_advisor_enterprise.rego` | 4 | 0 | 4 |
| **─── KLASA IX: PCC + Lokalne + Akcyza (rozszerzone) ───** | | | |
| `rules/local_taxes/pcc_enterprise_complete.rego` | 52 | 12 | 8 |
| **─── KLASA VIII: UoR/PKPiR (rozszerzone) ───** | | | |
| `rules/accounting/pkpir_enterprise_validation.rego` | 32 | 4 | 6 |
**─── KLASA II: PIT Art. 21 zwolnienia (rozszerzone) ───** | | | |
| `rules/pit/art21_exemptions_enterprise.rego` | 30 | 2 | 8 |
| **─── KLASA XII: Zdrowotna+Zasiłkowa (rozszerzone) ───** | | | |
| `rules/zus/health_contribution_enterprise.rego` | 15 | 2 | 3 |
| **─── KKS: Art. 54-83 grzywny (rozszerzone) ───** | | | |
| `rules/kks/enterprise_penalties.rego` | 22 | 12 | 3 |
| **RAZEM** | **~9995** | — | — |

---

## 📋 SZCZEGÓŁOWE REGUŁY

### `rules/accounting.rego` (67 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 472 | `jdg.accounting.remnant_continuity_validation` | 🔴 BLOCK | § 27-29 rozporządzenia PKPiR |
| 473 | `jdg.accounting.remnant_valuation_method` |  | § 29 rozporządzenia PKPiR, Art. 24 ust. 2 PIT |
| 474 | `jdg.accounting.remnant_liquidation_inventory` | 🔴 BLOCK | Art. 24 ust. 3 PIT, § 27-29 PKPiR |
| 475 | `jdg.accounting.remnant_scrap_loss` | 🟡 TRIAGE | § 28 rozporządzenia PKPiR |
| 476 | `jdg.accounting.remnant_market_price_correction` |  | Art. 14 ust. 2 PIT, § 29 ust. 2 rozporządzenia PKPiR |
| 477 | `jdg.accounting.remnant_damage_disposal_protocol` | 🔴 BLOCK | § 28 ust. 4 rozporządzenia PKPiR, Art. 24 ust. 2 PIT |
| 478 | `jdg.accounting.remnant_tax_return_correction` |  | Art. 24 ust. 2 PIT, § 27 rozporządzenia PKPiR |
| 479 | `jdg.accounting.remnant_physical_count_obligation` | 🟡 TRIAGE | § 27 ust. 1 rozporządzenia PKPiR |
| 480 | `jdg.accounting.remnant_goods_in_transit` |  | § 27 ust. 3 rozporządzenia PKPiR |
| 481 | `jdg.accounting.remnant_third_party_goods` |  | § 27 ust. 4 rozporządzenia PKPiR |
| 482 | `jdg.accounting.remnant_consignment_own` |  | § 27 ust. 2 rozporządzenia PKPiR |
| 483 | `jdg.accounting.remnant_write_off_approval` | 🟡 TRIAGE | Art. 24 ust. 2 PIT w zw. z Art. 22 ust. 1 PIT |
| 484 | `jdg.accounting.remnant_charity_donation` |  | Art. 23 ust. 1 pkt 11 PIT, Art. 7 ust. 2 VAT |
| 485 | `jdg.accounting.remnant_theft_documentation` | 🔴 BLOCK | Art. 23 ust. 1 pkt 5 PIT, § 28 rozporządzenia PKPiR |
| 486 | `jdg.accounting.remnant_natural_decay` |  | § 28 ust. 2 rozporządzenia PKPiR |
| 487 | `jdg.accounting.remnant_production_waste` |  | § 28 rozporządzenia PKPiR |
| 488 | `jdg.accounting.remnant_sample_giveaway` |  | Art. 7 ust. 1-2 VAT, Art. 23 ust. 1 pkt 11 PIT |
| 489 | `jdg.accounting.remnant_consignment_return` |  | § 27 rozporządzenia PKPiR |
| 490 | `jdg.accounting.remnant_archive_index` |  | § 29 rozporządzenia PKPiR, Art. 86 § 1 OrdPU |
| 491 | `jdg.accounting.remnant_cross_year_comparison` | 🟡 TRIAGE | § 27-29 rozporządzenia PKPiR |
| 492 | `jdg.accounting.remnant_multi_warehouse_reconciliation` |  | § 27 rozporządzenia PKPiR |
| 493 | `jdg.accounting.remnant_fx_foreign_goods` |  | Art. 24 ust. 2 PIT, § 29 rozporządzenia PKPiR |
| 494 | `jdg.accounting.remnant_seasonal_markdown` |  | § 29 ust. 2 rozporządzenia PKPiR |
| 495 | `jdg.accounting.remnant_digital_record` |  | Art. 193a OrdPU, § 11 rozporządzenia PKPiR |
| 496 | `jdg.accounting.remnant_audit_trail_documentation` | 🟡 TRIAGE | Art. 193 OrdPU, § 11 rozporządzenia PKPiR |
| 497 | `jdg.accounting.remnant_transport_damage` |  | § 28 rozporządzenia PKPiR |
| 498 | `jdg.accounting.remnant_warranty_replacement` |  | § 27 rozporządzenia PKPiR, Kodeks Cywilny art. 577 |
| 499 | `jdg.accounting.remnant_annual_summary_report` |  | § 27-29 rozporządzenia PKPiR |
| 800 | `jdg.accounting.pkpir_column_mapping` |  | Rozporządzenie MF w sprawie PKPiR |
| 801 | `jdg.accounting.pkpir_revenue_recognition` |  | § 20-21 rozporządzenia PKPiR |
| 802 | `jdg.accounting.pkpir_expense_recognition` |  | § 20 rozporządzenia PKPiR |
| 811 | `jdg.accounting.pkpir_col1_sequential` | 🔴 BLOCK | § 10 ust. 1 rozporządzenia PKPiR |
| 812 | `jdg.accounting.pkpir_col2_date_validation` | 🔴 BLOCK | § 10 ust. 1 pkt 2 rozporządzenia PKPiR |
| 813 | `jdg.accounting.pkpir_col6_7_kup_validation` | 🟡 TRIAGE | § 10 ust. 1 pkt 6-7, Art. 22 PIT |
| 814 | `jdg.accounting.pkpir_col8_goods_purchase` |  | § 10 ust. 1 pkt 8 rozporządzenia PKPiR |
| 815 | `jdg.accounting.pkpir_col14_notes_mandatory` | 🟡 TRIAGE | § 10 ust. 1 pkt 14 rozporządzenia PKPiR (od 2025) |
| 816 | `jdg.accounting.pkpir_remnant_midyear_check` | 🟡 TRIAGE | § 27-29 rozporządzenia PKPiR |
| 817 | `jdg.accounting.pkpir_retention_5years` |  | Art. 86 § 1 OrdPU, art. 74 UoR |
| 818 | `jdg.accounting.pkpir_income_calculation` |  | Art. 24 PIT, § 20-21 rozporządzenia PKPiR |
| 819 | `jdg.accounting.pkpir_col10_revenue` | 🟡 TRIAGE | § 10 ust. 1 pkt 10 rozporządzenia PKPiR |
| 820 | `jdg.accounting.pkpir_col11_other_revenue` |  | § 10 ust. 1 pkt 11 rozporządzenia PKPiR |
| 821 | `jdg.accounting.pkpir_col12_purchase_cost` |  | § 10 ust. 1 pkt 12 rozporządzenia PKPiR |
| 822 | `jdg.accounting.pkpir_col13_ancillary` |  | § 10 ust. 1 pkt 13 rozporządzenia PKPiR |
| 823 | `jdg.accounting.pkpir_col14_wages` |  | § 10 ust. 1 pkt 14 rozporządzenia PKPiR |
| 824 | `jdg.accounting.pkpir_col15_other_expenses` |  | § 10 ust. 1 pkt 15 rozporządzenia PKPiR |
| 825 | `jdg.accounting.pkpir_col16_non_kup` | 🟡 TRIAGE | Art. 23 PIT |
| 826 | `jdg.accounting.pkpir_col17_fixed_asset` |  | § 10 ust. 1 pkt 16 rozporządzenia PKPiR (kolumna 17 to ewide... |
| 827 | `jdg.accounting.pkpir_remnant_columns` |  | § 27 rozporządzenia PKPiR |
| 828 | `jdg.accounting.pkpir_col19_remarks` |  | § 10 ust. 1 pkt 17 rozporządzenia PKPiR |
| 829 | `jdg.accounting.pkpir_cross_column_consistency` | 🟡 TRIAGE | § 10-21 rozporządzenia PKPiR, Art. 24 PIT |
| 840 | `jdg.accounting.depreciation_linear` |  | Art. 22a-22o PIT, Rozporządzenie RM KŚT |
| 842 | `jdg.accounting.depreciation_one_off` |  | Art. 22k ust. 7 PIT |
| 850 | `jdg.accounting.private_mixed_home_office` |  | Art. 22 ust. 1 PIT, Art. 86 ust. 1 VAT |
| 852 | `jdg.accounting.private_mixed_car` |  | Art. 23 ust. 1 pkt 46 PIT, Art. 86a VAT |
| 860 | `jdg.accounting.operating_lease_full_kup` |  | Art. 22 ust. 1 PIT |
| 870 | `jdg.accounting.fx_differences_recognition` | 🟡 TRIAGE | Art. 14c, art. 24 ust. 2 PIT |
| 875 | `jdg.accounting.uor_annual_inventory` | 🟡 TRIAGE | Art. 26-27 Ustawy o rachunkowości |
| 876 | `jdg.accounting.uor_asset_valuation` |  | Art. 28-34 Ustawy o rachunkowości |
| 877 | `jdg.accounting.uor_accruals_deferrals` |  | Art. 39 Ustawy o rachunkowości |
| 878 | `jdg.accounting.uor_financial_statement` |  | Art. 45-52 Ustawy o rachunkowości |
| 879 | `jdg.accounting.uor_document_retention` |  | Art. 74 Ustawy o rachunkowości |
| 880 | `jdg.accounting.kst_group_classification` |  | Rozporządzenie RM z 30.12.1999 w sprawie KŚT |
| 881 | `jdg.accounting.depreciation_rate_assignment` |  | Art. 22i PIT, Załącznik nr 1 do ustawy PIT |
| 882 | `jdg.accounting.intangible_assets_classification` |  | Art. 22b, art. 22m PIT |
| 883 | `jdg.accounting.one_time_depreciation_eligibility` |  | Art. 22d ust. 1 PIT |
| 884 | `jdg.accounting.improvement_threshold_check` |  | Art. 22g ust. 17 PIT |
| 899 | `jdg.accounting.no_match` |  | N/A — no accounting rule matched |

### `rules/accounting/plan23_leasing.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 860 | `jdg.accounting.operating_lease_kup` |  | Art. 23b PIT |
| 862 | `jdg.accounting.financial_lease_interest_kup` |  | Art. 23f PIT |
| 864 | `jdg.accounting.car_lease_limit_150k` |  | Art. 23a pkt 47a PIT |
| 866 | `jdg.accounting.consumer_lease_kup` |  | Art. 23 ust. 1 pkt 46 PIT |
| 868 | `jdg.accounting.lease_classification_test` | 🟡 TRIAGE | Art. 23b ust. 1 PIT |

### `rules/accounting/plan42_pkpir.rego` (1 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 816 | `jdg.accounting.pkpir_remnant_consistency` | 🔴 BLOCK | § 27-28 Rozporządzenia ws. PKPiR |

### `rules/advertising/plan44_advertising.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1999 | `jdg.advertising.vs_representation` |  | Art. 23 ust. 1 pkt 23 PIT |
| 2000 | `jdg.advertising.online_digital_kup` |  | Art. 22 PIT |
| 2001 | `jdg.advertising.events_hospitality` |  | Art. 23 ust. 1 pkt 23 PIT |
| 2002 | `jdg.advertising.gifts_limit_200` |  | Art. 23 ust. 1 pkt 23 PIT |
| 2003 | `jdg.advertising.sponsorship_kup` |  | Art. 22 PIT, Art. 26 PIT |
| 2004 | `jdg.advertising.vat_deduction` |  | Art. 86a VAT |
| 2005 | `jdg.advertising.social_media_influencer` |  | Art. 22 PIT |
| 2006 | `jdg.advertising.car_wrapping_vat26` |  | Art. 86a VAT |
| 2007 | `jdg.advertising.foreign_markets_kup` |  | Art. 26ec PIT |

### `rules/advertising/plan45_advertising.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1675 | `jdg.advertising.hyper.product_promotion_kup` |  | Art. 22 ust. 1 PIT |
| 1677 | `jdg.advertising.hyper.personal_prestige_nkup` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1679 | `jdg.advertising.hyper.digital_google_ads_kup` |  | Art. 22 PIT |
| 1684 | `jdg.advertising.hyper.events_trade_fair_kup` |  | Art. 22 PIT |
| 1686 | `jdg.advertising.hyper.events_luxury_trip_nkup` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1690 | `jdg.advertising.hyper.gifts_over_200_nkup` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1693 | `jdg.advertising.hyper.gifts_vat_deduction_100pln` |  | Art. 88 ust. 1 pkt 5 VAT |
| 1708 | `jdg.advertising.hyper.car_wrapping_vat26` |  | Art. 86a VAT |

### `rules/allowances.rego` (12 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 600 | `jdg.allowances.relief_rd_centrum` |  | Art. 26e ust. 10 PIT |
| 600 | `jdg.allowances.relief_rd_standard` |  | Art. 26e ust. 1 PIT |
| 605 | `jdg.allowances.relief_ikze` |  | Art. 26 ust. 1 pkt 2b PIT |
| 605 | `jdg.allowances.relief_ikze_no_contribution` |  | Art. 26 ust. 1 pkt 2b PIT |
| 608 | `jdg.allowances.relief_innovative_employees` |  | Art. 26eb PIT |
| 610 | `jdg.allowances.relief_ip_box` |  | Art. 30ca PIT |
| 612 | `jdg.allowances.relief_csr_sponsoring` |  | Art. 26ha PIT |
| 614 | `jdg.allowances.relief_payment_terminal` |  | Art. 26hd PIT |
| 618 | `jdg.allowances.relief_bad_debt_pit_creditor` |  | Art. 26i PIT |
| 620 | `jdg.allowances.relief_abolition` |  | Art. 27g PIT |
| 622 | `jdg.allowances.relief_union_dues` |  | Art. 26 ust. 1 pkt 2c PIT |
| 630 | `jdg.allowances.crypto_income_classification` |  | Art. 30b ust. 1 pkt 1 PIT |

### `rules/allowances/plan23_reliefs.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 601 | `jdg.allowances.prototype_relief` |  | Art. 26eb PIT |
| 602 | `jdg.allowances.robotization_relief` |  | Art. 26gb PIT |
| 603 | `jdg.allowances.expansion_relief` |  | Art. 26ec PIT |
| 604 | `jdg.allowances.rehabilitation_relief` |  | Art. 26 ust. 1 pkt 6 PIT |
| 605 | `jdg.allowances.internet_relief` |  | Art. 26 ust. 1 pkt 6a PIT |
| 606 | `jdg.allowances.donation_ngo_relief` |  | Art. 26 ust. 1 pkt 9 lit. a PIT |
| 607 | `jdg.allowances.donation_blood_relief` |  | Art. 26 ust. 1 pkt 9 lit. c PIT |
| 608 | `jdg.allowances.donation_church_relief` |  | Art. 26 ust. 1 pkt 9 lit. b PIT |
| 609 | `jdg.allowances.abolition_relief` |  | Art. 27g PIT |

### `rules/audit/plan44_audit.rego` (15 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1830 | `jdg.audit.type_determination` |  | Art. 272-292 Ordynacji podatkowej |
| 1831 | `jdg.audit.rights_and_obligations` |  | Art. 281-292 Ordynacji podatkowej |
| 1832 | `jdg.audit.protocol_objections` |  | Art. 291 § 1-2 Ordynacji podatkowej |
| 1833 | `jdg.audit.statute_suspension` |  | Art. 70 § 6 pkt 1 Ordynacji podatkowej |
| 1834 | `jdg.audit.evidence_collection_rights` |  | Art. 190-200, 287 Ordynacji podatkowej |
| 1835 | `jdg.audit.seizure_of_documents` |  | Art. 288 Ordynacji podatkowej |
| 1836 | `jdg.audit.correction_during_audit` |  | Art. 81b Ordynacji podatkowej |
| 1837 | `jdg.audit.decision_appeal` | 🟡 TRIAGE | Art. 220-247 OP, Art. 52-54 PPSA |
| 1838 | `jdg.audit.right_to_be_heard` |  | Art. 200 Ordynacji podatkowej |
| 1839 | `jdg.audit.legal_privilege` |  | Art. 180 § 3 Ordynacji podatkowej |
| 1840 | `jdg.audit.representation_rights` |  | Art. 178, 138e, 291 Ordynacji podatkowej |
| 1841 | `jdg.audit.obstruction_penalty` | 🔴 BLOCK | Art. 262 OP, Art. 69 KKS |
| 1842 | `jdg.audit.electronic_evidence` |  | Art. 193a-193d Ordynacji podatkowej |
| 1843 | `jdg.audit.foreign_language_documents` |  | Art. 180a Ordynacji podatkowej |
| 1844 | `jdg.audit.closure_and_follow_up` | 🟡 TRIAGE | Art. 291-292 Ordynacji podatkowej |

### `rules/audit/plan45_audit.rego` (16 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1106 | `jdg.audit.hyper.type_verification` |  | Art. 272-280 OP |
| 1107 | `jdg.audit.hyper.type_tax_audit` |  | Art. 281-292 OP |
| 1108 | `jdg.audit.hyper.type_tax_proceeding` | 🟡 TRIAGE | Art. 120-129 OP |
| 1109 | `jdg.audit.hyper.type_customs_fiscal` | 🟡 TRIAGE | Art. 54-93 KAS |
| 1114 | `jdg.audit.hyper.right_notification_7days` |  | Art. 282b OP |
| 1117 | `jdg.audit.hyper.right_exclusion_inspector` |  | Art. 130 OP |
| 1118 | `jdg.audit.hyper.right_refuse_self_incrimination` |  | Art. 199 OP |
| 1126 | `jdg.audit.hyper.right_appeal_14days` | 🟡 TRIAGE | Art. 223 OP |
| 1127 | `jdg.audit.hyper.right_wsa_30days` | 🟡 TRIAGE | Art. 52-54 PPSA |
| 1136 | `jdg.audit.hyper.penalty_obstruction_5000` | 🔴 BLOCK | Art. 262 OP |
| 1137 | `jdg.audit.hyper.penalty_obstruction_kks_art69` | 🔴 BLOCK | Art. 69 KKS |
| 1143 | `jdg.audit.hyper.protocol_deadline_14days` |  | Art. 291 OP |
| 1145 | `jdg.audit.hyper.protocol_objections_period` |  | Art. 291 OP |
| 1148 | `jdg.audit.hyper.representation_pps1` |  | Art. 138e OP |
| 1150 | `jdg.audit.hyper.representation_access_files` |  | Art. 178 OP |
| 1158 | `jdg.audit.hyper.followup_recommendations` |  | Art. 292 OP |

### `rules/business.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 900 | `jdg.business.ceidg_registration_check` | 🔴 BLOCK | Art. 5-7 ustawy o CEIDG |
| 902 | `jdg.business.ceidg_data_change_overdue` | 🟡 TRIAGE | Art. 12-15 ustawy o CEIDG |
| 910 | `jdg.business.suspension_valid` |  | Art. 22-25 Prawa przedsiębiorców, Art. 44 ust. 10 PIT |
| 912 | `jdg.business.suspension_kup_restrictions` | 🔴 BLOCK | Art. 22-25 Prawa przedsiębiorców |
| 914 | `jdg.business.suspension_zus` |  | Art. 36a ustawy o SUS (społeczne=0, ALE zdrowotna NADAL nale... |
| 920 | `jdg.business.succession_continuity` |  | Ustawa o zarządzie sukcesyjnym |
| 930 | `jdg.business.unregistered_activity_limit_exceeded` | 🔴 BLOCK | Art. 5 Prawa przedsiębiorców |
| 932 | `jdg.business.unregistered_zus_exemption` |  | Art. 5 Prawa przedsiębiorców |

### `rules/business/plan26_suspension_succession.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 916 | `jdg.business.resumption_procedure_valid` | 🟡 TRIAGE | Art. 22-25 Prawa przedsiębiorców |
| 918 | `jdg.business.maximum_suspension_period_check` |  | Art. 22 Prawa przedsiębiorców |
| 925 | `jdg.business.succession_manager_appointment` | 🔴 BLOCK | Art. 3-7 ustawy o zarządzie sukcesyjnym |
| 926 | `jdg.business.succession_time_limit_expiry` | 🔴 BLOCK | Art. 12-13 ustawy o zarządzie sukcesyjnym |
| 927 | `jdg.business.succession_termination_events` | 🔴 BLOCK | Art. 14-15 ustawy o zarządzie sukcesyjnym |

### `rules/calendar/plan44_calendar.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1910 | `jdg.calendar.master_payment` |  | Art. 103 VAT, Art. 44 PIT, SUS, PCC |
| 1911 | `jdg.calendar.by_tax_form` |  | Art. 44 PIT |
| 1912 | `jdg.calendar.weekend_shift` |  | Art. 12 § 5 Ordynacji podatkowej |
| 1913 | `jdg.calendar.overdue_alerts` |  | Art. 12 Ordynacji podatkowej |
| 1914 | `jdg.calendar.annual_forecast` |  | Ogólne |
| 1915 | `jdg.calendar.zus_deadlines` |  | Art. 47 SUS |

### `rules/calendar/plan45_calendar.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1368 | `jdg.calendar.hyper.vat_monthly_25th` |  | Art. 103 VAT |
| 1373 | `jdg.calendar.hyper.pit_advance_20th` |  | Art. 44 PIT |
| 1378 | `jdg.calendar.hyper.zus_jdg_10th` |  | Art. 47 SUS |
| 1379 | `jdg.calendar.hyper.zus_employees_15th` |  | Art. 47 SUS |
| 1388 | `jdg.calendar.hyper.alert_7_days` |  | Art. 12 OP |
| 1398 | `jdg.calendar.hyper.weekend_shift_saturday` |  | Art. 12 § 5 OP |

### `rules/compliance.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 20 | `jdg.compliance.whitelist_missing_over_limit` | 🔴 BLOCK | Art. 96b VAT, Art. 117ba Ordynacji podatkowej |
| 21 | `jdg.compliance.whitelist_account_mismatch` | 🔴 BLOCK | Art. 117ba § 1 Ordynacji podatkowej |
| 25 | `jdg.compliance.split_payment_mandatory` |  | Art. 108a VAT |
| 25 | `jdg.compliance.split_payment_voluntary_safe_harbor` |  | Art. 108a ust. 1d VAT |
| 35 | `jdg.compliance.cash_transaction_over_limit` |  | Art. 22p ustawy o PIT |
| 36 | `jdg.compliance.vat_simplified_receipt` |  | Art. 106e ust. 5 pkt 3 VAT |
| 36 | `jdg.compliance.vat_simplified_receipt_over_limit` | 🔴 BLOCK | Art. 106e ust. 5 pkt 3 VAT |
| 145 | `jdg.compliance.cash_register_b2c_exemption` |  | Rozporządzenie MF w sprawie zwolnień z kas rejestrujących |
| 155 | `jdg.compliance.cesop_cross_border` |  | Rozporządzenie 2020/284 (CESOP) |

### `rules/conflicts.rego` (27 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 586 | `jdg.conflicts.ip_box_vs_rd_same_income` | 🔴 BLOCK | Art. 30ca ust. 3 PIT, Art. 26e PIT |
| 587 | `jdg.conflicts.ip_box_no_nexus_indicator` | 🔴 BLOCK | Art. 30ca ust. 4-7 PIT |
| 588 | `jdg.conflicts.ip_box_no_separate_records` | 🔴 BLOCK | Art. 30cb ust. 1-2 PIT |
| 589 | `jdg.conflicts.ip_box_rd_double_counting_costs` | 🟡 TRIAGE | Art. 30ca ust. 3 PIT, Art. 26e PIT |
| 590 | `jdg.conflicts.ip_box_income_threshold_exceeded` |  | Art. 30ca ust. 1 PIT |
| 591 | `jdg.conflicts.ip_box_other_relief_same_asset` | 🟡 TRIAGE | Art. 30ca ust. 3 PIT |
| 592 | `jdg.conflicts.ip_box_qualification_failed` | 🔴 BLOCK | Art. 30ca ust. 2 PIT |
| 593 | `jdg.conflicts.representation_vs_marketing_classification` | 🟡 TRIAGE | Art. 23 ust. 1 pkt 23 PIT |
| 594 | `jdg.conflicts.borderline_expense_restaurant` | 🟡 TRIAGE | Art. 23 ust. 1 pkt 23 PIT, interpretacje podatkowe |
| 595 | `jdg.conflicts.borderline_expense_event` | 🟡 TRIAGE | Art. 23 ust. 1 pkt 23 PIT, wyrok NSA II FSK 2345/17 |
| 596 | `jdg.conflicts.representation_with_business_purpose` |  | Interpretacja ogólna MF z 25.11.2019, wyroki NSA |
| 597 | `jdg.conflicts.advertising_vs_representation_distinction` |  | Art. 23 ust. 1 pkt 23 PIT, Art. 86a VAT |
| 598 | `jdg.conflicts.representation_limit_exceeded` | 🟡 TRIAGE | Praktyka kontroli skarbowych, Art. 23 ust. 1 pkt 23 PIT |
| 599 | `jdg.conflicts.car_vat_vs_kup_asymmetry` |  | Art. 86a VAT vs Art. 23 ust. 1 pkt 46 PIT |
| 600 | `jdg.conflicts.car_with_mileage_log_full_deduction` |  | Art. 86a ust. 3-4 VAT, Art. 23 ust. 1 pkt 46 PIT |
| 601 | `jdg.conflicts.car_no_mileage_log_100pct_vat_blocked` | 🔴 BLOCK | Art. 86a ust. 1 VAT |
| 602 | `jdg.conflicts.car_declared_business_but_private_use` | 🟡 TRIAGE | Art. 86a VAT, Art. 23 ust. 1 pkt 46 PIT |
| 603 | `jdg.conflicts.car_lease_vs_purchase_depreciation_conflict` |  | Art. 23 ust. 1 pkt 47a PIT (leasing), Art. 22a-22o PIT (amor... |
| 604 | `jdg.conflicts.car_insurance_repair_vat_deduction` |  | Art. 86a VAT, Art. 23 ust. 1 pkt 46-47 PIT |
| 605 | `jdg.conflicts.bad_debt_timing_vat_150_vs_pit_90` |  | Art. 26i PIT (90 dni) vs Art. 89a VAT (150 dni) |
| 606 | `jdg.conflicts.bad_debt_creditor_vat_corrected_but_not_pit` | 🟡 TRIAGE | Art. 89a VAT, Art. 26i PIT |
| 607 | `jdg.conflicts.bad_debt_debtor_vat_vs_pit_income` | 🟡 TRIAGE | Art. 89b VAT, Art. 26i ust. 9 PIT |
| 608 | `jdg.conflicts.bad_debt_sold_to_collector` | 🔴 BLOCK | Art. 89a ust. 7 VAT, Art. 26i ust. 6 PIT |
| 609 | `jdg.conflicts.bad_debt_partial_payment_proportional` |  | Art. 89a ust. 1 VAT, Art. 26i ust. 1 PIT |
| 610 | `jdg.conflicts.bad_debt_restructuring_vs_bankruptcy` | 🟡 TRIAGE | Art. 89a ust. 2 pkt 3 VAT, Art. 26i ust. 4 PIT |
| 611 | `jdg.conflicts.depreciation_method_conflict_vat_vs_pit` | 🟡 TRIAGE | Art. 22a-22o PIT, Art. 28-34 UoR |
| 612 | `jdg.conflicts.fx_rate_source_conflict_nbp_a_vs_c` |  | Art. 14c PIT, Art. 30a-c VAT, Tabela C NBP dla ceł |

### `rules/conviction/plan44_conviction.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1960 | `jdg.conviction.professional_consequences` | 🔴 BLOCK | Art. 41 KK, Art. 108 PZP |
| 1961 | `jdg.conviction.banking_access` |  | Ustawa o AML/CFT |
| 1962 | `jdg.conviction.tax_office_relations` |  | Art. 119b Ordynacji podatkowej |
| 1963 | `jdg.conviction.business_partner_impact` |  | Art. 105a VAT |
| 1964 | `jdg.conviction.rehabilitation` |  | Art. 19 KKS |
| 1965 | `jdg.conviction.tax_arrears_enforcement` | 🔴 BLOCK | Art. 36 Ordynacji podatkowej |

### `rules/conviction/plan45_conviction.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1546 | `jdg.conviction.hyper.business_ban_art41kk` | 🔴 BLOCK | Art. 41 KK |
| 1548 | `jdg.conviction.hyper.public_procurement_exclusion` | 🔴 BLOCK | Art. 108 PZP |
| 1551 | `jdg.conviction.hyper.bank_account_termination` |  | Art. 56 Prawo bankowe, AML |
| 1556 | `jdg.conviction.hyper.enhanced_audit_scrutiny` |  | Art. 119b OP |
| 1566 | `jdg.conviction.hyper.rehabilitation_misdemeanor_3y` |  | Art. 21 KKS |
| 1567 | `jdg.conviction.hyper.rehabilitation_crime_5y` |  | Art. 21 KKS |
| 1571 | `jdg.conviction.hyper.full_asset_enforcement` | 🔴 BLOCK | Art. 26 OP |

### `rules/corrections.rego` (16 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 420 | `jdg.corrections.invoice_in_minus` |  | Art. 106j VAT |
| 421 | `jdg.corrections.invoice_in_plus` |  | Art. 106j VAT |
| 422 | `jdg.corrections.vat_declaration_period` |  | Art. 81 OrdPU |
| 423 | `jdg.corrections.jpk_v7_storno` |  | Art. 109 ust. 3b VAT |
| 424 | `jdg.corrections.statute_limitations` | 🟡 TRIAGE | Art. 70, 81 OrdPU |
| 425 | `jdg.corrections.interest_calculation` | 🟡 TRIAGE | Art. 53-56 OrdPU |
| 426 | `jdg.corrections.pit_advance` |  | Art. 44 PIT |
| 427 | `jdg.corrections.zus_base` | 🟡 TRIAGE | Art. 47 SUS |
| 428 | `jdg.corrections.invoice_numbering` | 🔴 BLOCK | Art. 106e ust. 1 pkt 2 VAT |
| 429 | `jdg.corrections.collective_correction` |  | Art. 106j ust. 3 VAT |
| 430 | `jdg.corrections.bad_debt_correction` | 🟡 TRIAGE | Art. 89a-89b VAT |
| 431 | `jdg.corrections.annual_correction` |  | Art. 91 VAT |
| 432 | `jdg.corrections.fixed_asset_correction` |  | Art. 91 ust. 2 VAT |
| 433 | `jdg.corrections.cross_border_correction` | 🟡 TRIAGE | Art. 103 VAT |
| 434 | `jdg.corrections.correction_overpayment` |  | Art. 78 OrdPU |
| 435 | `jdg.corrections.correction_underpayment` | 🔴 BLOCK | Art. 53 OrdPU |

### `rules/crossborder.rego` (18 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 40 | `jdg.crossborder.eu_reverse_charge` |  | Art. 17 ust. 1 pkt 3 VAT |
| 41 | `jdg.crossborder.eu_import_services` |  | Art. 28b VAT |
| 42 | `jdg.crossborder.wdt_no_docs` | 🔴 BLOCK | Art. 42 ust. 1 pkt 1-2 VAT |
| 42 | `jdg.crossborder.wdt_intracommunity_supply` |  | Art. 42 VAT |
| 43 | `jdg.crossborder.customs_warehouse` |  | Art. 33-33a VAT + UKC (EU 952/2013) |
| 44 | `jdg.crossborder.tp_jdg_family` | 🟡 TRIAGE | Art. 23o-23zf PIT (TP dla JDG) |
| 45 | `jdg.crossborder.import_non_eu` |  | Art. 17 ust. 1 pkt 1 VAT |
| 46 | `jdg.crossborder.vida_digital_reporting` | 🟡 TRIAGE | ViDA (EU 2022/890) — Digital Reporting Requirements |
| 47 | `jdg.crossborder.icow_import_control` | 🟡 TRIAGE | ICS2 (EU 2021/348) — Import Control System 2 |
| 48 | `jdg.crossborder.export_goods` |  | Art. 41 ust. 4-11 VAT |
| 49 | `jdg.crossborder.triangular_transaction` |  | Art. 135-138 VAT |
| 50 | `jdg.crossborder.cfc_jdg_controlled` | 🔴 BLOCK | Art. 30f PIT (CFC dla JDG) |
| 51 | `jdg.crossborder.cross_border_services_wht` | 🟡 TRIAGE | Art. 29-30a PIT (WHT) |
| 52 | `jdg.crossborder.pe_permanent_establishment` | 🔴 BLOCK | Art. 4a pkt 11 PIT + Model Tax Convention (OECD) |
| 53 | `jdg.crossborder.wdt_refund_accelerated` |  | Art. 87 ust. 6 pkt 1 VAT |
| 54 | `jdg.crossborder.triangular_simplified` |  | Art. 135-138 VAT |
| 55 | `jdg.crossborder.platform_app_store_export` |  | Art. 28b VAT (miejsce świadczenia = siedziba nabywcy B2B) |
| 56 | `jdg.crossborder.platform_import_services` |  | Art. 17 ust. 1 pkt 4 VAT, Art. 28b VAT |

### `rules/crossborder/plan23_ue.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 43 | `jdg.crossborder.vat_ue_registration_mandatory` | 🔴 BLOCK | Art. 97 ust. 1-3 VAT |
| 44 | `jdg.crossborder.vat_r_ue_filing_deadline` | 🟡 TRIAGE | Art. 97 ust. 1-3 VAT |
| 46 | `jdg.crossborder.intra_community_acquisition_detailed` |  | Art. 9, Art. 11, Art. 20 ust. 5 VAT |
| 47 | `jdg.crossborder.import_services_non_eu` |  | Art. 28b, Art. 17 ust. 1 pkt 4 VAT |
| 49 | `jdg.crossborder.triangular_transaction_rules` |  | Art. 135-138 VAT |
| 190 | `jdg.crossborder.wnt_intra_community_detailed` |  | Art. 20 ust. 5 VAT |
| 191 | `jdg.crossborder.import_vat_deduction_timing` |  | Art. 86 ust. 2 pkt 2, Art. 86 ust. 10b pkt 3 VAT |
| 232 | `jdg.crossborder.vat_ue_quarterly_summary` | 🟡 TRIAGE | Art. 100 ust. 1 i 3 VAT |

### `rules/digital.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 630 | `jdg.digital.crypto_taxable_event` |  | Art. 22d, 22e, 30b PIT |
| 1890 | `jdg.digital.crypto_mining_business` |  | Art. 22d PIT + interpretacje KIS (np. 0114-KDIP2-1.4010.312.... |
| 1892 | `jdg.digital.crypto_mdr_reporting` | 🔴 BLOCK | Art. 86a-86o Ordynacja podatkowa (MDR) + DAC6 |
| 1893 | `jdg.digital.ai_act_compliance_check` | 🔴 BLOCK | Rozporządzenie UE 2024/1689 (AI Act) |
| 1894 | `jdg.digital.api_degradation_fallback` |  | Konfiguracja operacyjna — Art. 3 pkt 7 RODO (integralność i ... |
| 1895 | `jdg.digital.deepfake_ai_disclosure` | 🔴 BLOCK | Art. 50 Rozporządzenia UE 2024/1689 (AI Act) |

### `rules/edelivery/plan44_edelivery.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1870 | `jdg.edelivery.fiction_detection` | 🔴 BLOCK | Ustawa o doręczeniach elektronicznych |
| 1871 | `jdg.edelivery.platform_monitoring` |  | Art. 144b Ordynacji podatkowej |
| 1872 | `jdg.edelivery.epuap_profile` |  | Art. 20a Ordynacji podatkowej |
| 1873 | `jdg.edelivery.qualified_signature` |  | Art. 126 § 5 Ordynacji podatkowej |
| 1874 | `jdg.edelivery.document_retention` |  | Art. 86 OP, eIDAS |
| 1875 | `jdg.edelivery.evidence_value` |  | Art. 180a-194 Ordynacji podatkowej |
| 1876 | `jdg.edelivery.cross_border_e_comm` |  | Dyrektywy DAC, CRS |
| 1877 | `jdg.edelivery.archive_retention` |  | Art. 86 Ordynacji podatkowej |

### `rules/edelivery/plan45_edelivery.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1237 | `jdg.edelivery.hyper.fiction_14_days` | 🔴 BLOCK | Ustawa o doręczeniach elektronicznych |
| 1240 | `jdg.edelivery.hyper.fiction_appeal_deadline` | 🟡 TRIAGE | Art. 144a OP |
| 1242 | `jdg.edelivery.hyper.alert_7_days` |  | Art. 144a OP |
| 1245 | `jdg.edelivery.hyper.eus_platform_required` |  | Art. 144b OP |
| 1257 | `jdg.edelivery.hyper.retention_5years` |  | Art. 86 OP |
| 1262 | `jdg.edelivery.hyper.crs_fatca_reporting` |  | Dyrektywy DAC, CRS |

### `rules/edge_cases.rego` (149 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 546 | `jdg.edge_cases.vat_breach_mid_year` | 🔴 BLOCK | Art. 113 ust. 1 i 5 VAT |
| 547 | `jdg.edge_cases.vat_breach_proportion_new_jdg` | 🔴 BLOCK | Art. 113 ust. 9 VAT |
| 548 | `jdg.edge_cases.vat_first_invoice_tax_point` |  | Art. 19a ust. 1 VAT |
| 549 | `jdg.edge_cases.vat_last_invoice_before_deregister` | 🔴 BLOCK | Art. 14 ust. 1 i 4 VAT |
| 550 | `jdg.edge_cases.vat_exempt_breach_notification_7days` | 🟡 TRIAGE | Art. 96 ust. 1 i 5 VAT |
| 551 | `jdg.edge_cases.vat_exempt_breach_retroactive` | 🔴 BLOCK | Art. 113 ust. 5 VAT |
| 552 | `jdg.edge_cases.vat_prepayment_full_vat` |  | Art. 19a ust. 8 VAT |
| 553 | `jdg.edge_cases.vat_mixed_sale_exempt_taxable` |  | Art. 90 ust. 1-2 VAT |
| 554 | `jdg.edge_cases.vat_correction_chain_reaction` | 🟡 TRIAGE | Art. 91 ust. 1 i 3 VAT |
| 555 | `jdg.edge_cases.vat_currency_conversion_date` |  | Art. 31a ust. 1 VAT |
| 556 | `jdg.edge_cases.vat_self_invoice_obligation` | 🟡 TRIAGE | Art. 106d ust. 1-2 VAT |
| 557 | `jdg.edge_cases.vat_non_deductible_pro_rata` |  | Art. 90 ust. 2-10, Art. 91 ust. 2-7 VAT |
| 558 | `jdg.edge_cases.vat_construction_acceptance_partial` |  | Art. 19a ust. 2 VAT |
| 559 | `jdg.edge_cases.vat_sale_and_leaseback` |  | Art. 5 ust. 1 pkt 1, Art. 19a, Art. 41 VAT |
| 560 | `jdg.edge_cases.pit_first_year_lump_sum_loss` | 🟡 TRIAGE | Art. 6 ust. 1 ustawy o ryczałcie |
| 561 | `jdg.edge_cases.pit_last_year_before_closure` | 🔴 BLOCK | Art. 24 ust. 3 i 3a PIT |
| 562 | `jdg.edge_cases.pit_double_taxation_abroad` | 🟡 TRIAGE | Art. 27 ust. 8-9 PIT + UPO |
| 563 | `jdg.edge_cases.pit_linear_health_underpayment` | 🟡 TRIAGE | Art. 30c ust. 2 PIT |
| 564 | `jdg.edge_cases.pit_lump_sum_health_progressive` |  | Art. 81 ust. 2e ustawy o świadczeniach zdrowotnych |
| 565 | `jdg.edge_cases.pit_loss_multiple_years` |  | Art. 9 ust. 3 PIT |
| 566 | `jdg.edge_cases.pit_inventory_valuation_method` |  | Art. 24 ust. 2 PIT |
| 567 | `jdg.edge_cases.pit_spouse_contract_under_authority` | 🟡 TRIAGE | Art. 23 ust. 1 pkt 10 PIT |
| 568 | `jdg.edge_cases.pit_child_labor_under_18` | 🔴 BLOCK | Art. 23 ust. 1 pkt 10 PIT |
| 569 | `jdg.edge_cases.pit_abroad_relief_abolition` |  | Art. 27g PIT |
| 570 | `jdg.edge_cases.pit_rental_income_jdg_vs_private` |  | Art. 10 ust. 1 pkt 3 i 6 PIT |
| 571 | `jdg.edge_cases.pit_foreign_currency_loan_fx` |  | Art. 14c PIT, Art. 22 ust. 1 PIT |
| 572 | `jdg.edge_cases.pit_donation_excess_loss` |  | Art. 26 ust. 1 pkt 9 PIT |
| 573 | `jdg.edge_cases.pit_health_contrib_scale_9pct_no_deduction` |  | Art. 81 ust. 2 ustawy o świadczeniach (Polski Ład 2022) |
| 574 | `jdg.edge_cases.zus_start_relief_transition_preferential` |  | Art. 18a ust. 1-2 SUS |
| 575 | `jdg.edge_cases.zus_maly_plus_36_months_exhaustion` | 🟡 TRIAGE | Art. 18c ust. 1 i 4 SUS |
| 576 | `jdg.edge_cases.zus_preferential_24_months_exhaustion` | 🟡 TRIAGE | Art. 18a ust. 2 SUS |
| 577 | `jdg.edge_cases.zus_concurrent_jdg_and_mandate` |  | Art. 9 ust. 2a SUS |
| 578 | `jdg.edge_cases.zus_sickness_benefit_waiting_90days` |  | Art. 4 ust. 1 pkt 2 ustawy zasiłkowej |
| 579 | `jdg.edge_cases.zus_maternity_benefit_no_health_exemption` |  | Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych |
| 580 | `jdg.edge_cases.zus_health_annual_overpayment_refund` |  | Art. 81 ust. 2d i 2f ustawy o świadczeniach |
| 581 | `jdg.edge_cases.zus_health_annual_underpayment_deadline_may22` | 🟡 TRIAGE | Art. 81 ust. 2f ustawy o świadczeniach |
| 582 | `jdg.edge_cases.zus_declaration_zero_on_suspension` |  | Art. 36a SUS |
| 583 | `jdg.edge_cases.zus_multiple_titles_concurrent` |  | Art. 9 ust. 2, 2a, 2b SUS |
| 584 | `jdg.edge_cases.zus_retirement_while_jdg` |  | Art. 9 ust. 4b SUS |
| 585 | `jdg.edge_cases.zus_student_under_26_jdg` |  | Art. 6 ust. 4, Art. 9 ust. 2c SUS |
| 586 | `jdg.edge_cases.vat_exemption_exclusions` | 🔴 BLOCK | Art. 113 ust. 13 VAT |
| 587 | `jdg.edge_cases.vat_exemption_lost` | 🔴 BLOCK | Art. 113 ust. 2 i 5 VAT |
| 588 | `jdg.edge_cases.vat_exemption_reacquire` |  | Art. 113 ust. 11 VAT |
| 589 | `jdg.edge_cases.vat_pro_rata_detailed` |  | Art. 113 ust. 9 VAT |
| 590 | `jdg.edge_cases.vat_ue_correction_value` | 🟡 TRIAGE | Art. 103 ust. 1-3 VAT |
| 591 | `jdg.edge_cases.vat_ue_deadline_15th` |  | Art. 103 ust. 1 VAT |
| 592 | `jdg.edge_cases.vat_vida_transaction_reporting` | 🟡 TRIAGE | Dyrektywa ViDA 2025 (DAC8) |
| 593 | `jdg.edge_cases.vat_ksef_mandatory_from_2026` | 🔴 BLOCK | Art. 106na VAT |
| 594 | `jdg.edge_cases.vat_cross_border_oss_ioss` | 🟡 TRIAGE | Art. 130a-130d VAT (OSS), Art. 138a-138j VAT (IOSS) |
| 595 | `jdg.edge_cases.pit_closure_loss_carry` | 🔴 BLOCK | Art. 9 ust. 3 i 5 PIT |
| 596 | `jdg.edge_cases.pit_tax_form_change_midyear` | 🔴 BLOCK | Art. 9a ust. 2-3 PIT, Art. 30c ust. 1 PIT |
| 597 | `jdg.edge_cases.pit_rental_jdg_vs_private` | 🟡 TRIAGE | Art. 10 ust. 1 pkt 3 i 6 PIT |
| 598 | `jdg.edge_cases.pit_bad_debt_art26a` | 🟡 TRIAGE | Art. 26a PIT |
| 599 | `jdg.edge_cases.pit_ip_box_loss` | 🟡 TRIAGE | Art. 30ca ust. 6-7 PIT |
| 600 | `jdg.edge_cases.pit_foreign_tax_credit_limit` |  | Art. 27 ust. 8-9 PIT |
| 601 | `jdg.edge_cases.pit_health_lump_sum_tier` |  | Art. 81 ust. 2e ustawy o świadczeniach |
| 602 | `jdg.edge_cases.suspension_vs_income_generation` | 🔴 BLOCK | Art. 22-25 Prawa przedsiębiorców |
| 603 | `jdg.edge_cases.unregistered_vs_vat_deduction` | 🔴 BLOCK | Art. 5 Prawa przedsiębiorców, Art. 113 VAT |
| 604 | `jdg.edge_cases.health_scale_loss_year` |  | Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych |
| 605 | `jdg.edge_cases.zus_start_vs_preferential` | 🔴 BLOCK | Art. 18a ust. 1 SUS |
| 606 | `jdg.edge_cases.zus_maly_plus_vs_preferential` | 🔴 BLOCK | Art. 18a i 18c SUS |
| 607 | `jdg.edge_cases.car_leasing_vs_buy_kup_limit` | 🟡 TRIAGE | Art. 23 ust. 1 pkt 47a i 47b PIT |
| 608 | `jdg.edge_cases.home_office_vs_exclusive_business` | 🟡 TRIAGE | Art. 22 ust. 1 PIT |
| 609 | `jdg.edge_cases.bad_debt_vat_vs_pit_timing` | 🟡 TRIAGE | Art. 89a-89b VAT, Art. 22 ust. 1a PIT (SLIM VAT 3) |
| 610 | `jdg.edge_cases.fx_method_podatkowa_vs_bilansowa` | 🟡 TRIAGE | Art. 14c PIT, Art. 30 UoR |
| 611 | `jdg.edge_cases.inventory_fifo_vs_weighted_average` | 🔴 BLOCK | Art. 24 ust. 2 PIT |
| 612 | `jdg.edge_cases.donation_limit_6pct_aggregate` |  | Art. 26 ust. 1 pkt 9 PIT |
| 613 | `jdg.edge_cases.nip_checksum_pl` | 🔴 BLOCK | Art. 96b VAT, Rozp. MF ws. NIP |
| 614 | `jdg.edge_cases.iban_checksum_pl` | 🔴 BLOCK | Regulacja UE 260/2012 (SEPA) |
| 615 | `jdg.edge_cases.regon_9digit` | 🟡 TRIAGE | Rozp. GUS ws. REGON |
| 616 | `jdg.edge_cases.invoice_date_consistency` | 🟡 TRIAGE | Art. 106e VAT |
| 617 | `jdg.edge_cases.date_not_future` | 🔴 BLOCK | Art. 106e VAT |
| 618 | `jdg.edge_cases.date_after_1990` | 🟡 TRIAGE | Art. 106e VAT |
| 619 | `jdg.edge_cases.amount_non_negative` | 🔴 BLOCK | Art. 106e VAT |
| 620 | `jdg.edge_cases.vat_rate_valid` | 🔴 BLOCK | Art. 41 VAT |
| 621 | `jdg.edge_cases.pkpir_column_consistency` | 🟡 TRIAGE | Rozp. MF ws. PKPiR |
| 622 | `jdg.edge_cases.invoice_numbering_continuity` | 🟡 TRIAGE | Art. 106e VAT |
| 623 | `jdg.edge_cases.limit_vat_exemption_200k` |  | Art. 113 ust. 1 VAT |
| 624 | `jdg.edge_cases.limit_lump_sum_2m_eur` | 🟡 TRIAGE | Art. 6 ust. 1 ustawy o ryczałcie |
| 625 | `jdg.edge_cases.limit_small_taxpayer_2m_eur` |  | Art. 2 pkt 25 VAT |
| 626 | `jdg.edge_cases.limit_full_accounting_2m_eur` | 🟡 TRIAGE | Art. 24a PIT |
| 627 | `jdg.edge_cases.limit_cash_transaction_15k` | 🔴 BLOCK | Art. 22p PIT |
| 628 | `jdg.edge_cases.limit_mpp_15k` | 🔴 BLOCK | Art. 108a VAT |
| 629 | `jdg.edge_cases.limit_tax_free_30k` |  | Art. 27 ust. 1 PIT |
| 630 | `jdg.edge_cases.limit_pit_scale_120k` |  | Art. 27 ust. 1 PIT |
| 631 | `jdg.edge_cases.limit_car_depreciation_150k` | 🟡 TRIAGE | Art. 23 ust. 1 pkt 47a PIT |
| 632 | `jdg.edge_cases.limit_car_electric_225k` | 🟡 TRIAGE | Art. 23 ust. 1 pkt 47b PIT |
| 633 | `jdg.edge_cases.limit_health_linear_12900` |  | Art. 30c ust. 2 PIT |
| 634 | `jdg.edge_cases.limit_rd_relief_capped` |  | Art. 26e ust. 7 PIT |
| 635 | `jdg.edge_cases.limit_donation_6pct` |  | Art. 26 ust. 1 pkt 9 PIT |
| 636 | `jdg.edge_cases.limit_thermo_53k` |  | Art. 26h PIT |
| 637 | `jdg.edge_cases.limit_prototype_300k` |  | Art. 26eb PIT |
| 638 | `jdg.edge_cases.limit_expansion_1m` |  | Art. 26ec PIT |
| 639 | `jdg.edge_cases.limit_pit0_combined_85528` | 🟡 TRIAGE | Art. 21 ust. 1 pkt 148-154 PIT |
| 640 | `jdg.edge_cases.limit_loss_50pct_annual` |  | Art. 9 ust. 3 PIT |
| 641 | `jdg.edge_cases.limit_loss_one_time_5m` |  | Art. 9 ust. 3a-3b PIT (COVID-19 special) |
| 642 | `jdg.edge_cases.limit_cash_register_20k` | 🟡 TRIAGE | Rozporządzenie MF ws. zwolnień z kasy fiskalnej |
| 643 | `jdg.edge_cases.limit_unregistered_50pct` | 🟡 TRIAGE | Art. 5 Prawa przedsiębiorców |
| 644 | `jdg.edge_cases.limit_giif_15k_eur` | 🟡 TRIAGE | Art. 72 ustawy AML |
| 645 | `jdg.edge_cases.limit_cesop_25k_eur` | 🟡 TRIAGE | Rozporządzenie 2020/284 (CESOP) |
| 646 | `jdg.edge_cases.sanction_jpk_error_500` | 🔴 BLOCK | Art. 109 VAT |
| 647 | `jdg.edge_cases.sanction_ksef_missing_100pct` | 🔴 BLOCK | Art. 106nq VAT |
| 648 | `jdg.edge_cases.sanction_late_filing_vat_500_5000` | 🟡 TRIAGE | Art. 77-79 KKS |
| 649 | `jdg.edge_cases.sanction_unregistered_activity` | 🔴 BLOCK | Art. 60¹ KKS |
| 650 | `jdg.edge_cases.sanction_mpp_violation_30pct` | 🔴 BLOCK | Art. 108a VAT |
| 651 | `jdg.edge_cases.sanction_whitelist_transfer` | 🔴 BLOCK | Art. 117ba OrdPU |
| 652 | `jdg.edge_cases.sanction_bad_debt_debtor_30pct` | 🔴 BLOCK | Art. 89b VAT |
| 653 | `jdg.edge_cases.sanction_cash_over_15k_kup_loss` | 🔴 BLOCK | Art. 22p PIT |
| 654 | `jdg.edge_cases.sanction_dac7_non_reporting_1m` | 🔴 BLOCK | Art. 39q OrdPU |
| 655 | `jdg.edge_cases.sanction_mdr_non_reporting` | 🔴 BLOCK | Art. 86f OrdPU |
| 656 | `jdg.edge_cases.deadline_vat_declaration_25th` |  | Art. 99 VAT |
| 657 | `jdg.edge_cases.deadline_vat_quarterly_25th` |  | Art. 99 VAT |
| 658 | `jdg.edge_cases.deadline_pit_advance_20th` |  | Art. 44 PIT |
| 659 | `jdg.edge_cases.deadline_pit_annual_april30` |  | Art. 45 PIT |
| 660 | `jdg.edge_cases.deadline_pit28_february28` |  | Art. 21 ustawy o ryczałcie |
| 661 | `jdg.edge_cases.deadline_zus_payment_10th` |  | Art. 47 SUS |
| 662 | `jdg.edge_cases.deadline_zus_payment_15th` |  | Art. 47 SUS |
| 663 | `jdg.edge_cases.deadline_whitelist_verification_30days` |  | Art. 96b VAT |
| 664 | `jdg.edge_cases.deadline_whitelist_3day_buffer` |  | Art. 96b ust. 4a VAT |
| 665 | `jdg.edge_cases.deadline_correction_vat_3_months` |  | Art. 86 VAT |
| 666 | `jdg.edge_cases.deadline_ksef_offline_7_days` |  | Art. 106ne VAT |
| 667 | `jdg.edge_cases.deadline_tax_audit_14days_correct` |  | Art. 81 OrdPU |
| 668 | `jdg.edge_cases.deadline_overpayment_refund_45days` |  | Art. 78 OrdPU |
| 669 | `jdg.edge_cases.deadline_annual_health_may22` |  | Art. 81 ust. 2f ustawy o świadczeniach |
| 670 | `jdg.edge_cases.deadline_pit11_employee_feb28` |  | Art. 39 PIT |
| 671 | `jdg.edge_cases.deadline_vat_r_registration_before_first` |  | Art. 96 VAT |
| 672 | `jdg.edge_cases.deadline_statute_limitations_5yr` |  | Art. 70 OrdPU |
| 673 | `jdg.edge_cases.tp_family_jdg` | 🟡 TRIAGE | Art. 23o-23zf PIT |
| 674 | `jdg.edge_cases.tp_documentation_threshold` | 🟡 TRIAGE | Art. 23zf PIT |
| 675 | `jdg.edge_cases.cfc_foreign_company` | 🔴 BLOCK | Art. 30f PIT |
| 676 | `jdg.edge_cases.cfc_passive_income_test` | 🟡 TRIAGE | Art. 30f ust. 3 PIT |
| 677 | `jdg.edge_cases.wht_foreign_service` | 🟡 TRIAGE | Art. 29 PIT w zw. z UPO |
| 678 | `jdg.edge_cases.wht_dividend_interest` | 🟡 TRIAGE | Art. 30a PIT |
| 679 | `jdg.edge_cases.cross_border_pe` | 🟡 TRIAGE | Art. 4a pkt 11 PIT w zw. z UPO |
| 680 | `jdg.edge_cases.cross_border_posted_worker` | 🟡 TRIAGE | Art. 12-16 Rozporządzenia 883/2004 |
| 682 | `jdg.edge_cases.vat_reverse_charge_construction_ext` | 🟡 TRIAGE | Art. 17 ust. 1 pkt 8 VAT, Załącznik nr 14 |
| 683 | `jdg.edge_cases.vat_wnt_acquisition_detailed` | 🟡 TRIAGE | Art. 9-12 VAT |
| 684 | `jdg.edge_cases.vat_export_0pct_documentation` | 🟡 TRIAGE | Art. 41 ust. 4-11 VAT |
| 685 | `jdg.edge_cases.vat_import_deferral` | 🟡 TRIAGE | Art. 33a VAT |
| 686 | `jdg.edge_cases.vat_distance_selling_threshold` | 🟡 TRIAGE | Art. 23a-23b VAT |
| 687 | `jdg.edge_cases.vat_call_off_stock` |  | Art. 13a VAT (Dyrektywa 2018/1910) |
| 688 | `jdg.edge_cases.vat_chain_transaction` | 🟡 TRIAGE | Art. 7 ust. 8 VAT, Art. 22 ust. 2-3 VAT |
| 689 | `jdg.edge_cases.vat_correction_invoice_mandatory` | 🔴 BLOCK | Art. 106j ust. 1 pkt 5 VAT |
| 690 | `jdg.edge_cases.vat_split_payment_nuances` |  | Art. 108a-108f VAT |
| 691 | `jdg.edge_cases.vat_bad_debt_creditor_90d` | 🟡 TRIAGE | Art. 89a VAT (SLIM VAT 3) |
| 692 | `jdg.edge_cases.vat_fiscal_representative` | 🟡 TRIAGE | Art. 18a-18d VAT |
| 693 | `jdg.edge_cases.vat_prepayment_partial` |  | Art. 19a ust. 8 VAT |
| 694 | `jdg.edge_cases.vat_incorrect_rate_correction` | 🔴 BLOCK | Art. 106j VAT |
| 695 | `jdg.edge_cases.vat_group_consolidation` | 🟡 TRIAGE | Art. 15a VAT, Rozdział 1a (Grupy VAT od 2025) |

### `rules/employer.rego` (13 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1200 | `jdg.employer.creative_kup_50` |  | Art. 22 ust. 9 pkt 3 PIT |
| 1202 | `jdg.employer.standard_kup_250` |  | Art. 22 ust. 2 PIT |
| 1204 | `jdg.employer.kup_300_commuting` |  | Art. 22 ust. 2 pkt 3 PIT |
| 1206 | `jdg.employer.multiple_contracts_kup` |  | Art. 22 ust. 2 pkt 4 PIT |
| 1208 | `jdg.employer.civil_law_contract_20` |  | Art. 22 ust. 9 pkt 4 PIT |
| 1210 | `jdg.employer.civil_law_creative_50` |  | Art. 22 ust. 9 pkt 3 PIT |
| 1212 | `jdg.employer.ppk_auto_enrollment` |  | Art. 31-32 ustawy o PPK |
| 1213 | `jdg.employer.ppk_opt_out` |  | Art. 32 ust. 3-4 ustawy o PPK |
| 1214 | `jdg.employer.pit4r_monthly` | 🔴 BLOCK | Art. 38 ust. 1 PIT |
| 1216 | `jdg.employer.annual_pit_summary` | 🔴 BLOCK | Art. 38 ust. 1a i Art. 42 ust. 1a PIT |
| 1218 | `jdg.employer.peron_contribution` | 🔴 BLOCK | Art. 21 ustawy o rehabilitacji zawodowej i społecznej oraz z... |
| 1219 | `jdg.employer.peron_exemption_zpch` |  | Art. 22 ustawy o rehabilitacji |
| 1220 | `jdg.employer.small_mandate_flat_tax` |  | Art. 30 ust. 1 pkt 5a PIT |

### `rules/environmental.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1400 | `jdg.environmental.bdo_registration_required` | 🔴 BLOCK | Art. 49 ust. 1 Ustawy o odpadach |
| 1401 | `jdg.environmental.bdo_waste_ledger` | 🔴 BLOCK | Art. 66-67 Ustawy o odpadach |
| 1402 | `jdg.environmental.fee_annual` |  | Art. 284 Ustawy Prawo ochrony środowiska |
| 1403 | `jdg.environmental.kobize_emission_report` |  | Art. 7 Ustawy o systemie zarządzania emisjami |
| 1404 | `jdg.environmental.battery_disposal_fee` |  | Ustawa o bateriach i akumulatorach |
| 1405 | `jdg.environmental.water_permit_check` | 🔴 BLOCK | Art. 389 Ustawy Prawo wodne |
| 1406 | `jdg.environmental.waste_transport_card` |  | Art. 67 Ustawy o odpadach |
| 1407 | `jdg.environmental.packaging_recycling_fee` |  | Ustawa o gospodarce opakowaniami i odpadami opakowaniowymi |

### `rules/esig/plan44_esig.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1900 | `jdg.esig.qualified_signature_requirement` |  | Art. 126 § 5 OP, eIDAS |
| 1901 | `jdg.esig.signature_validity_monitoring` |  | eIDAS, Art. 126 OP |
| 1902 | `jdg.esig.ksef_invoice_signature` |  | Ustawa o KSeF |
| 1903 | `jdg.esig.document_authenticity` |  | eIDAS, EN 16931 |
| 1904 | `jdg.esig.cross_border_eidas` |  | Rozporządzenie eIDAS (910/2014) |
| 1905 | `jdg.esig.electronic_contracts` |  | Art. 77²-78¹ KC |
| 1906 | `jdg.esig.einvoice_storage_standards` |  | Art. 112a VAT, EN 16931 |

### `rules/esig/plan45_esig.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1340 | `jdg.esig.hyper.qualified_required_appeal` |  | Art. 126 § 5 OP |
| 1345 | `jdg.esig.hyper.profile_zaufany_sufficient` |  | Art. 20a OP |
| 1350 | `jdg.esig.hyper.ksef_token_required` |  | Ustawa o KSeF |
| 1355 | `jdg.esig.hyper.document_authenticity_preserve` |  | eIDAS, EN 16931 |
| 1360 | `jdg.esig.hyper.cross_border_eidas_recognition` |  | Rozp. eIDAS 910/2014 |
| 1365 | `jdg.esig.hyper.contracts_electronic_form` |  | Art. 78¹ KC |

### `rules/fallback.rego` (1 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1000 | `jdg.fallback.domestic_23pct` |  | Art. 41 ust. 1 VAT, Art. 27 ust. 1 PIT (domyślnie skala) |

### `rules/family/plan44_family.rego` (10 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1860 | `jdg.family.spouse_employment_kup` | 🟡 TRIAGE | Art. 22 ust. 1 PIT, Art. 23 ust. 1 pkt 10 PIT |
| 1861 | `jdg.family.child_employment_kup` | 🟡 TRIAGE | Art. 23 ust. 1 pkt 10 PIT |
| 1862 | `jdg.family.health_insurance_deduction` |  | Art. 27b PIT (historycznie) |
| 1863 | `jdg.family.car_usage_kup` |  | Art. 23 ust. 1 pkt 46a PIT |
| 1864 | `jdg.family.cooperation_zus` |  | Art. 8 ust. 2 SUS |
| 1865 | `jdg.family.succession_planning` |  | Ustawa o podatku od spadków i darowizn |
| 1866 | `jdg.family.joint_pit_filing` |  | Art. 6 ust. 2 PIT |
| 1867 | `jdg.family.relief_interaction` |  | Art. 27f PIT |
| 1868 | `jdg.family.pit4r_obligation` |  | Art. 38-42 PIT |
| 1869 | `jdg.family.asset_transfer_tax` | 🟡 TRIAGE | Art. 14 PIT, Art. 7 VAT, Ustawa o PCC |

### `rules/family/plan45_family.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1194 | `jdg.family.hyper.spouse_market_benchmark` |  | Art. 23 ust. 1 pkt 10 PIT |
| 1199 | `jdg.family.hyper.spouse_no_evidence_nkup` | 🔴 BLOCK | Art. 23 ust. 1 pkt 10 PIT |
| 1203 | `jdg.family.hyper.children_under_26_elevated_risk` |  | Art. 23 ust. 1 pkt 10 PIT |
| 1208 | `jdg.family.hyper.cooperation_zus_like_entrepreneur` |  | Art. 8 ust. 2 SUS |
| 1212 | `jdg.family.hyper.car_mixed_75pct_kup` |  | Art. 23 ust. 1 pkt 46a PIT |
| 1215 | `jdg.family.hyper.asset_gift_group_zero` |  | Ustawa o podatku od spadków i darowizn |
| 1221 | `jdg.family.hyper.joint_filing_double_free_amount` |  | Art. 6 ust. 2 PIT |
| 1230 | `jdg.family.hyper.succession_inheritance_exempt` |  | Ustawa o podatku od spadków |

### `rules/force_majeure/plan44_force_majeure.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1850 | `jdg.force_majeure.tax_relief` |  | Art. 67a-67e Ordynacji podatkowej |
| 1851 | `jdg.force_majeure.zus_relief` |  | Art. 28-29 SUS |
| 1852 | `jdg.force_majeure.documentation_loss` | 🟡 TRIAGE | Art. 86 § 2 Ordynacji podatkowej |
| 1853 | `jdg.force_majeure.insurance_cover` |  | Art. 22 PIT, Art. 14 PIT |
| 1854 | `jdg.force_majeure.business_suspension_auto` | 🟡 TRIAGE | Art. 25 PP |
| 1855 | `jdg.force_majeure.tax_loss_carry_back` |  | Spec-regulacje MF (np. COVID-19) |
| 1856 | `jdg.force_majeure.emergency_deadlines` |  | Rozporządzenia MF |
| 1857 | `jdg.force_majeure.documentation_preservation` |  | Art. 86 Ordynacji podatkowej |

### `rules/force_majeure/plan45_force_majeure.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1162 | `jdg.force_majeure.hyper.event_flood` | 🟡 TRIAGE | Art. 67a OP |
| 1167 | `jdg.force_majeure.hyper.relief_tax_deferral` |  | Art. 67a § 1 pkt 1 OP |
| 1168 | `jdg.force_majeure.hyper.relief_tax_installments` |  | Art. 67a § 1 pkt 2 OP |
| 1174 | `jdg.force_majeure.hyper.relief_zus_deferral` |  | Art. 28 SUS |
| 1178 | `jdg.force_majeure.hyper.documents_loss_7days` | 🟡 TRIAGE | Art. 86 § 2 OP |
| 1185 | `jdg.force_majeure.hyper.suspension_automatic` | 🟡 TRIAGE | Art. 25 PP |
| 1188 | `jdg.force_majeure.hyper.loss_carry_back` |  | Specustawy |

### `rules/fx/plan44_fx.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1890 | `jdg.fx.vat_rate_determination` |  | Art. 30a-31a VAT |
| 1891 | `jdg.fx.pit_rate_determination` |  | Art. 14 ust. 1aa PIT |
| 1892 | `jdg.fx.differences_method` |  | Art. 14b PIT |
| 1893 | `jdg.fx.realized_vs_unrealized` |  | Art. 14b PIT |
| 1894 | `jdg.fx.differences_method_selection` |  | Art. 14b ust. 3 PIT |
| 1895 | `jdg.fx.own_funds` |  | Art. 14b ust. 1 PIT |
| 1896 | `jdg.fx.crypto_fx_differences` |  | Art. 14b PIT |
| 1897 | `jdg.fx.hedging_instruments` |  | Art. 14 PIT |
| 1898 | `jdg.fx.multi_currency_accounting` |  | Art. 24a PIT |

### `rules/fx/plan45_fx.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1300 | `jdg.fx.hyper.vat_import_customs_rate` |  | Art. 30a VAT |
| 1306 | `jdg.fx.hyper.pit_revenue_nbp_prev_day` |  | Art. 14 ust. 1aa PIT |
| 1312 | `jdg.fx.hyper.nbp_table_a_average` |  | Art. 14 PIT |
| 1318 | `jdg.fx.hyper.method_tax_fifo` |  | Art. 14b PIT |
| 1324 | `jdg.fx.hyper.realized_only_pit` |  | Art. 14b PIT |
| 1330 | `jdg.fx.hyper.hedging_forward_tax` |  | Art. 14 PIT |
| 1335 | `jdg.fx.hyper.multi_currency_monthly_conversion` |  | Art. 24a PIT |

### `rules/insurance/plan44_insurance.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1980 | `jdg.insurance.mandatory_detection` |  | Ustawy branżowe |
| 1981 | `jdg.insurance.premium_kup` |  | Art. 22 ust. 1 PIT |
| 1982 | `jdg.insurance.voluntary_kup` |  | Art. 22 PIT |
| 1983 | `jdg.insurance.claim_tax_treatment` |  | Art. 14 PIT |
| 1984 | `jdg.insurance.vat_treatment` |  | Art. 43 ust. 1 pkt 37 VAT |
| 1985 | `jdg.insurance.gap_detection` | 🔴 BLOCK | Ustawy branżowe |

### `rules/insurance/plan45_insurance.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1609 | `jdg.insurance.hyper.detection_medical` |  | Ustawa o zawodzie lekarza |
| 1610 | `jdg.insurance.hyper.detection_construction` |  | Art. 648 KC |
| 1613 | `jdg.insurance.hyper.premium_mandatory_100pct_kup` |  | Art. 22 ust. 1 PIT |
| 1618 | `jdg.insurance.hyper.claim_payout_revenue` |  | Art. 14 ust. 1 PIT |
| 1621 | `jdg.insurance.hyper.claim_personal_injury_exempt` |  | Art. 21 ust. 1 pkt 3c PIT |
| 1623 | `jdg.insurance.hyper.vat_exemption_insurance` |  | Art. 43 ust. 1 pkt 37 VAT |
| 1633 | `jdg.insurance.hyper.gap_mandatory_missing` | 🔴 BLOCK | Ustawy branżowe |
| 1635 | `jdg.insurance.hyper.gap_policy_expiring_30days` |  | Ogólne |

### `rules/international.rego` (4 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 29 | `jdg.international.tp_safe_harbour_low_value` |  | Art. 23zf PIT |
| 100 | `jdg.international.wht_obligation` |  | Art. 30a PIT, art. 21 CIT |
| 110 | `jdg.international.pe_risk` | 🟡 TRIAGE | Art. 5 umów o unikaniu podwójnego opodatkowania |
| 114 | `jdg.international.tp_documentation_threshold` |  | Art. 23q-23zf PIT |

### `rules/jdg/hyper/audit/plan45.rego` (21 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1090 | `jdg.hyper.audit.wis.binding_effect.not_against_law_change` |  |  |
| 1091 | `jdg.hyper.audit.wis.binding_effect.covers_future_transactions` |  | R1092 |
| 1092 | `jdg.hyper.audit.wis.gtu.mapping_obligation` |  |  |
| 1093 | `jdg.hyper.audit.wis.sanction.incorrect_rate_no_wis` |  | R1094 |
| 1094 | `jdg.hyper.audit.wis.interaction.tax_audit_protection` |  |  |
| 1095 | `jdg.hyper.audit.wis.interaction.individual_interpretation` |  | R1096 |
| 1096 | `jdg.hyper.audit.wit.eligibility.import_non_eu` |  |  |
| 1097 | `jdg.hyper.audit.wit.validity.3_years` |  | R1098 |
| 1098 | `jdg.hyper.audit.wit.cost.free` |  |  |
| 1099 | `jdg.hyper.audit.wit.binding_effect.customs_authorities` |  | R1100 |
| 1100 | `jdg.hyper.audit.wia.eligibility.excise_goods` |  |  |
| 1101 | `jdg.hyper.audit.wia.validity.3_years` |  | R1102 |
| 1102 | `jdg.hyper.audit.wia.cost.250_pln` |  |  |
| 1103 | `jdg.hyper.audit.binding_info.cost_benefit_analysis` |  | R1104 |
| 1104 | `jdg.hyper.audit.binding_info.renewal_strategy` |  |  |
| 1105 | `jdg.hyper.audit.binding_info.portfolio.management` |  | R-ID |
| 1106 | `jdg.hyper.audit.audit.type.verification` |  | R1107 |
| 1107 | `jdg.hyper.audit.audit.type.tax_audit` |  |  |
| 1108 | `jdg.hyper.audit.audit.type.tax_proceeding` |  | R1109 |
| 1109 | `jdg.hyper.audit.audit.type.customs_fiscal` |  |  |
| 1110 | `jdg.hyper.audit.audit.trigger.cross_checking` |  | R1111 |

### `rules/jdg/hyper/deadlines/plan45.rego` (41 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1610 | `jdg.hyper.deadlines.insurance.mandatory.detection_construction` |  | Art. 648 KC |
| 1611 | `jdg.hyper.deadlines.insurance.mandatory.detection_transport` |  | Ustawa o transporcie drogowym |
| 1612 | `jdg.hyper.deadlines.insurance.mandatory.detection_tax_advisor` |  | Ustawa o doradztwie podatkowym |
| 1613 | `jdg.hyper.deadlines.insurance.kup.mandatory_oc_premium_full` |  | Art. 22 ust. 1 PIT |
| 1614 | `jdg.hyper.deadlines.insurance.kup.mandatory_oc_over_limit_proportion` |  | Art. 22 ust. 1 PIT |
| 1615 | `jdg.hyper.deadlines.insurance.kup.voluntary_oc_business` |  | Art. 22 ust. 1 PIT |
| 1616 | `jdg.hyper.deadlines.insurance.kup.life_insurance_limited` |  | Art. 22 ust. 1 PIT |
| 1617 | `jdg.hyper.deadlines.insurance.kup.property_insurance_full` |  | Art. 22 ust. 1 PIT |
| 1618 | `jdg.hyper.deadlines.insurance.claim.payout_as_revenue` |  | Art. 14 ust. 1 PIT |
| 1619 | `jdg.hyper.deadlines.insurance.claim.payout_reduced_by_damage` |  | Art. 14 ust. 1 PIT |
| 1620 | `jdg.hyper.deadlines.insurance.claim.business_interruption_taxable` |  | Art. 14 PIT |
| 1621 | `jdg.hyper.deadlines.insurance.claim.personal_injury_exempt` |  | Art. 21 ust. 1 pkt 3c PIT |
| 1622 | `jdg.hyper.deadlines.insurance.claim.late_payment_interest_taxable` |  | Art. 17 ust. 1 PIT |
| 1623 | `jdg.hyper.deadlines.insurance.vat.exemption_general` |  | Art. 43 ust. 1 pkt 37 VAT |
| 1624 | `jdg.hyper.deadlines.insurance.vat.exception_assistance_services` |  | Art. 41 VAT |
| 1625 | `jdg.hyper.deadlines.insurance.vat.exception_damage_assessment` |  | Art. 41 VAT |
| 1626 | `jdg.hyper.deadlines.insurance.vat.exception_broker_services` |  | Art. 41 VAT |
| 1627 | `jdg.hyper.deadlines.insurance.vat.input_vat_deduction_blocked` |  | Art. 88 VAT |
| 1628 | `jdg.hyper.deadlines.insurance.voluntary.cyber_risk` |  | Art. 22 PIT |
| 1629 | `jdg.hyper.deadlines.insurance.voluntary.directors_officers` |  | Art. 22 PIT |
| 1630 | `jdg.hyper.deadlines.insurance.voluntary.key_person` |  | Art. 22 PIT |
| 1631 | `jdg.hyper.deadlines.insurance.voluntary.trade_credit` |  | Art. 22 PIT |
| 1632 | `jdg.hyper.deadlines.insurance.voluntary.inventory_theft` |  | Art. 22 PIT |
| 1633 | `jdg.hyper.deadlines.insurance.gap.detection_mandatory_missing` |  | Ustawy branżowe |
| 1634 | `jdg.hyper.deadlines.insurance.gap.detection_sum_insufficient` |  | Ustawy branżowe |
| 1635 | `jdg.hyper.deadlines.insurance.gap.detection_policy_expiring` |  | — |
| 1636 | `jdg.hyper.deadlines.payment.crypto.receiving_as_payment` |  | Art. 14 ust. 1 PIT |
| 1637 | `jdg.hyper.deadlines.payment.crypto.vat_obligation_on_receipt` |  | Art. 19a ust. 8 VAT |
| 1638 | `jdg.hyper.deadlines.payment.crypto.exchange_rate_determination` |  | Art. 14 PIT |
| 1639 | `jdg.hyper.deadlines.payment.crypto.volatility_risk_warning` |  | — |
| 1640 | `jdg.hyper.deadlines.payment.crypto.difference_from_crypto_trading` |  | Art. 14 vs Art. 17 PIT |
| 1641 | `jdg.hyper.deadlines.payment.barter.double_supply` |  | Art. 7, Art. 8 VAT |
| 1642 | `jdg.hyper.deadlines.payment.barter.vat_on_both_sides` |  | Art. 5 VAT |
| 1643 | `jdg.hyper.deadlines.payment.barter.market_value_as_base` |  | Art. 29a VAT |
| 1644 | `jdg.hyper.deadlines.payment.barter.pit_revenue_recognition` |  | Art. 14 PIT |
| 1645 | `jdg.hyper.deadlines.payment.barter.documentation_requirements` |  | Art. 22 UoR |
| 1646 | `jdg.hyper.deadlines.payment.offset.when_recognized` |  | Art. 498 KC + Art. 14 PIT |
| 1647 | `jdg.hyper.deadlines.payment.offset.vat_cash_method` |  | Art. 21 VAT |
| 1648 | `jdg.hyper.deadlines.payment.offset.vat_accrual_method` |  | Art. 19a VAT |
| 1649 | `jdg.hyper.deadlines.payment.offset.mutual_agreement_required` |  | Art. 498-499 KC |
| 1650 | `jdg.hyper.deadlines.payment.offset.documentation_required` |  | Art. 22 UoR |

### `rules/jdg/hyper/edelivery/plan45.rego` (21 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1180 | `jdg.hyper.edelivery.force_majeure.documents.backup_obligation` |  |  |
| 1181 | `jdg.hyper.edelivery.force_majeure.documents.electronic_preservation` |  | R1182 |
| 1182 | `jdg.hyper.edelivery.force_majeure.insurance.cover_check` |  |  |
| 1183 | `jdg.hyper.edelivery.force_majeure.insurance.claim_procedure` |  | R1184 |
| 1184 | `jdg.hyper.edelivery.force_majeure.insurance.payout_tax_treatment` |  |  |
| 1185 | `jdg.hyper.edelivery.force_majeure.suspension.automatic` |  | R1186 |
| 1186 | `jdg.hyper.edelivery.force_majeure.suspension.zus_consequences` |  |  |
| 1187 | `jdg.hyper.edelivery.force_majeure.suspension.tax_consequences` |  | R1188 |
| 1188 | `jdg.hyper.edelivery.force_majeure.loss.carry_back` |  |  |
| 1189 | `jdg.hyper.edelivery.force_majeure.loss.enhanced_deduction` |  | R1190 |
| 1190 | `jdg.hyper.edelivery.force_majeure.deadlines.mf_communication_monitoring` |  |  |
| 1191 | `jdg.hyper.edelivery.force_majeure.deadlines.auto_extension_application` |  | R1192 |
| 1192 | `jdg.hyper.edelivery.force_majeure.aggregate.impact_assessment` |  |  |
| 1193 | `jdg.hyper.edelivery.family.spouse.employment.kup_conditions` |  | R1194 |
| 1194 | `jdg.hyper.edelivery.family.spouse.market_benchmark_test` |  |  |
| 1195 | `jdg.hyper.edelivery.family.spouse.qualifications_check` |  | R1196 |
| 1196 | `jdg.hyper.edelivery.family.spouse.work_evidence_required` |  |  |
| 1197 | `jdg.hyper.edelivery.family.spouse.salary_above_market_red_flag` |  | R1198 |
| 1198 | `jdg.hyper.edelivery.family.spouse.no_qualifications_red_flag` |  |  |
| 1199 | `jdg.hyper.edelivery.family.spouse.no_work_evidence_nkup` |  | R1200 |
| 1200 | `jdg.hyper.edelivery.family.spouse.contract_type.employment` |  |  |

### `rules/jdg/hyper/family/plan45.rego` (21 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1150 | `jdg.hyper.family.audit.representation.access_to_files` |  | R1151 |
| 1151 | `jdg.hyper.family.audit.representation.participation_rights` |  |  |
| 1152 | `jdg.hyper.family.audit.cross_border.mutual_assistance` |  | R1153 |
| 1153 | `jdg.hyper.family.audit.cross_border.simultaneous_audit` |  |  |
| 1154 | `jdg.hyper.family.audit.cross_border.presence_foreign_officials` |  | R1155 |
| 1155 | `jdg.hyper.family.audit.closure.decision_issuance` |  |  |
| 1156 | `jdg.hyper.family.audit.closure.decision_deadline` |  | R1157 |
| 1157 | `jdg.hyper.family.audit.closure.correction_window` |  |  |
| 1158 | `jdg.hyper.family.audit.follow_up.recommendations` |  | R1159 |
| 1159 | `jdg.hyper.family.audit.follow_up.deadline_monitoring` |  |  |
| 1160 | `jdg.hyper.family.audit.aggregate.risk_score_update` |  | R-ID |
| 1161 | `jdg.hyper.family.force_majeure.event.detection` |  | R1162 |
| 1162 | `jdg.hyper.family.force_majeure.event.flood` |  |  |
| 1163 | `jdg.hyper.family.force_majeure.event.fire` |  | R1164 |
| 1164 | `jdg.hyper.family.force_majeure.event.pandemic` |  |  |
| 1165 | `jdg.hyper.family.force_majeure.event.war_effects` |  | R1166 |
| 1166 | `jdg.hyper.family.force_majeure.event.natural_disaster_other` |  |  |
| 1167 | `jdg.hyper.family.force_majeure.relief.tax_deferral` |  | R1168 |
| 1168 | `jdg.hyper.family.force_majeure.relief.tax_installments` |  |  |
| 1169 | `jdg.hyper.family.force_majeure.relief.tax_remission` |  | R1170 |
| 1170 | `jdg.hyper.family.force_majeure.relief.tax_suspension` |  |  |

### `rules/jdg/hyper/force_majeure/plan45.rego` (21 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1120 | `jdg.hyper.force_majeure.audit.right.record_activities` |  | R1121 |
| 1121 | `jdg.hyper.force_majeure.audit.right.break_request` |  |  |
| 1122 | `jdg.hyper.force_majeure.audit.right.oppose_inspection` |  | R1123 |
| 1123 | `jdg.hyper.force_majeure.audit.right.correction_in_minus_blocked` |  |  |
| 1124 | `jdg.hyper.force_majeure.audit.right.correction_in_plus_allowed` |  | R1125 |
| 1125 | `jdg.hyper.force_majeure.audit.right.right_to_be_heard` |  |  |
| 1126 | `jdg.hyper.force_majeure.audit.right.appeal_14_days` |  | R1127 |
| 1127 | `jdg.hyper.force_majeure.audit.right.wsa_complaint_30_days` |  |  |
| 1128 | `jdg.hyper.force_majeure.audit.obligation.provide_documents` |  | R1129 |
| 1129 | `jdg.hyper.force_majeure.audit.obligation.allow_inspection` |  |  |
| 1130 | `jdg.hyper.force_majeure.audit.obligation.provide_explanations` |  | R1131 |
| 1131 | `jdg.hyper.force_majeure.audit.obligation.sign_protocol` |  |  |
| 1132 | `jdg.hyper.force_majeure.audit.obligation.retain_audit_docs` |  | R1133 |
| 1133 | `jdg.hyper.force_majeure.audit.statute.suspension_effect` |  |  |
| 1134 | `jdg.hyper.force_majeure.audit.statute.suspension_duration` |  | R1135 |
| 1135 | `jdg.hyper.force_majeure.audit.statute.resume_after_close` |  |  |
| 1136 | `jdg.hyper.force_majeure.audit.penalty.obstruction_fine_5000` |  | R1137 |
| 1137 | `jdg.hyper.force_majeure.audit.penalty.obstruction_kks_art69` |  |  |
| 1138 | `jdg.hyper.force_majeure.audit.penalty.coercion_measures` |  | R1139 |
| 1139 | `jdg.hyper.force_majeure.audit.document.seizure_receipt` |  |  |
| 1140 | `jdg.hyper.force_majeure.audit.document.seizure_duration` |  | R1141 |

### `rules/jdg/hyper/fx/plan45.rego` (21 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1240 | `jdg.hyper.fx.edelivery.fiction.appeal_deadline_trigger` |  |  |
| 1241 | `jdg.hyper.fx.edelivery.monitoring.unread_messages` |  | R1242 |
| 1242 | `jdg.hyper.fx.edelivery.monitoring.alert_7_days` |  |  |
| 1243 | `jdg.hyper.fx.edelivery.monitoring.alert_3_days` |  | R1244 |
| 1244 | `jdg.hyper.fx.edelivery.monitoring.alert_1_day` |  |  |
| 1245 | `jdg.hyper.fx.eus.platform.required` |  | R1246 |
| 1246 | `jdg.hyper.fx.eus.platform.incoming_letters_check` |  |  |
| 1247 | `jdg.hyper.fx.eus.platform.declarations_status` |  | R1248 |
| 1248 | `jdg.hyper.fx.eus.platform.payment_history` |  |  |
| 1249 | `jdg.hyper.fx.eus.platform.mandates_management` |  | R1250 |
| 1250 | `jdg.hyper.fx.eus.platform.certificates` |  |  |
| 1251 | `jdg.hyper.fx.epuap.profile.required` |  | R1252 |
| 1252 | `jdg.hyper.fx.epuap.signature.profile_zaufany` |  |  |
| 1253 | `jdg.hyper.fx.epuap.submission.confirmation_upo` |  | R1254 |
| 1254 | `jdg.hyper.fx.epuap.submission.timestamp` |  |  |
| 1255 | `jdg.hyper.fx.electronic.delivery.address.update_obligation` |  | R1256 |
| 1256 | `jdg.hyper.fx.electronic.delivery.sanction.outdated_address` |  |  |
| 1257 | `jdg.hyper.fx.electronic.communication.retention.5_years` |  | R1258 |
| 1258 | `jdg.hyper.fx.electronic.communication.evidence_value` |  |  |
| 1259 | `jdg.hyper.fx.electronic.communication.encryption_requirements` |  | R1260 |
| 1260 | `jdg.hyper.fx.electronic.communication.data_breach_notification` |  |  |

### `rules/jdg/hyper/general/plan45.rego` (100 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1044 | `jdg.hyper.general.solidarity.levy.base.calculation` |  | R1045 |
| 1045 | `jdg.hyper.general.solidarity.levy.rate.4pct` |  |  |
| 1046 | `jdg.hyper.general.solidarity.levy.minimum.zero` |  | R1047 |
| 1047 | `jdg.hyper.general.solidarity.levy.income.scale` |  |  |
| 1048 | `jdg.hyper.general.solidarity.levy.income.linear` |  | R1049 |
| 1049 | `jdg.hyper.general.solidarity.levy.income.lump_sum` |  |  |
| 1061 | `jdg.hyper.general.solidarity.levy.payment.method.mandatory_transfer` |  |  |
| 1062 | `jdg.hyper.general.solidarity.levy.sanction.late_payment` |  | R1063 |
| 1063 | `jdg.hyper.general.solidarity.levy.sanction.underpayment_penalty` |  |  |
| 1064 | `jdg.hyper.general.solidarity.levy.interaction.pit_free_amount` |  | R1065 |
| 1065 | `jdg.hyper.general.solidarity.levy.interaction.tax_scale` |  |  |
| 1066 | `jdg.hyper.general.solidarity.levy.edge.first_year_1m` |  | R1067 |
| 1067 | `jdg.hyper.general.solidarity.levy.edge.loss_reduction` |  |  |
| 1068 | `jdg.hyper.general.solidarity.levy.edge.one_time_income` |  | R1069 |
| 1069 | `jdg.hyper.general.solidarity.levy.aggregate.annual_forecast` |  |  |
| 1086 | `jdg.hyper.general.wis.monitoring.expiry_alert_6months` |  |  |
| 1087 | `jdg.hyper.general.wis.monitoring.expiry_alert_3months` |  | R1088 |
| 1088 | `jdg.hyper.general.wis.monitoring.expiry_alert_1month` |  |  |
| 1089 | `jdg.hyper.general.wis.binding_effect.dyrektor_kis` |  | R1090 |
| 1111 | `jdg.hyper.general.audit.trigger.return_to_correct` |  |  |
| 1112 | `jdg.hyper.general.audit.trigger.inspection_warrant` |  | R1113 |
| 1113 | `jdg.hyper.general.audit.trigger.external_information` |  |  |
| 1114 | `jdg.hyper.general.audit.right.notification_7_days` |  | R1115 |
| 1115 | `jdg.hyper.general.audit.right.no_notification_exceptions` |  |  |
| 1116 | `jdg.hyper.general.audit.right.presence_during_activities` |  | R1117 |
| 1117 | `jdg.hyper.general.audit.right.exclusion_of_inspector` |  |  |
| 1118 | `jdg.hyper.general.audit.right.refuse_self_incrimination` |  | R1119 |
| 1119 | `jdg.hyper.general.audit.right.object_to_protocol` |  |  |
| 1141 | `jdg.hyper.general.audit.document.electronic_evidence` |  |  |
| 1142 | `jdg.hyper.general.audit.document.foreign_language` |  | R1143 |
| 1143 | `jdg.hyper.general.audit.protocol.deadline_14_days_after_end` |  |  |
| 1144 | `jdg.hyper.general.audit.protocol.required_elements` |  | R1145 |
| 1145 | `jdg.hyper.general.audit.protocol.objections_period` |  |  |
| 1146 | `jdg.hyper.general.audit.protocol.objections_to_director` |  | R1147 |
| 1147 | `jdg.hyper.general.audit.protocol.electronic_service` |  |  |
| 1148 | `jdg.hyper.general.audit.representation.poa_pps1` |  | R1149 |
| 1149 | `jdg.hyper.general.audit.representation.poa_upl1` |  |  |
| 1171 | `jdg.hyper.general.force_majeure.relief.deadline_extension` |  | R1172 |
| 1172 | `jdg.hyper.general.force_majeure.relief.application_immediate` |  |  |
| 1173 | `jdg.hyper.general.force_majeure.relief.interest_suspension` |  | R1174 |
| 1174 | `jdg.hyper.general.force_majeure.relief.zus_deferral` |  |  |
| 1175 | `jdg.hyper.general.force_majeure.relief.zus_installments` |  | R1176 |
| 1176 | `jdg.hyper.general.force_majeure.relief.zus_remission` |  |  |
| 1177 | `jdg.hyper.general.force_majeure.relief.zus_contribution_suspension` |  | R1178 |
| 1178 | `jdg.hyper.general.force_majeure.documents.loss_reporting` |  |  |
| 1179 | `jdg.hyper.general.force_majeure.documents.reconstruction_procedure` |  | R1180 |
| 1201 | `jdg.hyper.general.family.spouse.contract_type.b2b` |  | R1202 |
| 1202 | `jdg.hyper.general.family.spouse.contract_type.mandate` |  |  |
| 1203 | `jdg.hyper.general.family.children.employment.under_26` |  | R1204 |
| 1204 | `jdg.hyper.general.family.children.work_evidence_required` |  |  |
| 1205 | `jdg.hyper.general.family.children.salary_arm_length` |  | R1206 |
| 1206 | `jdg.hyper.general.family.children.pit_ulga_young_interaction` |  |  |
| 1207 | `jdg.hyper.general.family.children.university_compatibility` |  | R1208 |
| 1208 | `jdg.hyper.general.family.cooperation.zus_person` |  |  |
| 1209 | `jdg.hyper.general.family.cooperation.zus_health` |  | R1210 |
| 1231 | `jdg.hyper.general.family.succession.sd_z2_deadline_6months` |  | R1232 |
| 1232 | `jdg.hyper.general.family.succession.business_continuity` |  |  |
| 1233 | `jdg.hyper.general.family.multi_generation.tax_planning` |  | R1234 |
| 1234 | `jdg.hyper.general.family.aggregate.risk_assessment` |  |  |
| 1235 | `jdg.hyper.general.edelivery.registration.mandatory` |  | R1236 |
| 1236 | `jdg.hyper.general.edelivery.registration.deadline_by_entity_type` |  |  |
| 1237 | `jdg.hyper.general.edelivery.fiction.delivery_14_days` |  | R1238 |
| 1238 | `jdg.hyper.general.edelivery.fiction.consequences_legal` |  |  |
| 1239 | `jdg.hyper.general.edelivery.fiction.critical_alert` |  | R1240 |
| 1261 | `jdg.hyper.general.cross_border.eidas.recognition` |  | R1262 |
| 1262 | `jdg.hyper.general.cross_border.crs.fatca.reporting` |  |  |
| 1263 | `jdg.hyper.general.cross_border.dac.directives.compliance` |  | R1264 |
| 1264 | `jdg.hyper.general.communication.calendar.deadlines_integration` |  |  |
| 1265 | `jdg.hyper.general.communication.offline.backup_procedure` |  | R1266 |
| 1266 | `jdg.hyper.general.communication.offline.paper_allowed_when` |  |  |
| 1267 | `jdg.hyper.general.communication.language.polish_required` |  | R1268 |
| 1268 | `jdg.hyper.general.communication.language.foreign_documents_translation` |  |  |
| 1269 | `jdg.hyper.general.communication.aggregate.status_dashboard` |  | R-ID |
| 1551 | `jdg.hyper.general.kks.conviction.bank_account_termination` |  | Art. 56 Prawa bankowego + AML |
| 1552 | `jdg.hyper.general.kks.conviction.credit_score_impact` |  | BIK, praktyka bankowa |
| 1553 | `jdg.hyper.general.kks.conviction.enhanced_aml_kyc` |  | Art. 43 AML |
| 1554 | `jdg.hyper.general.kks.conviction.fintech_access_restriction` |  | Polityki fintechów |
| 1555 | `jdg.hyper.general.kks.conviction.cash_transaction_monitoring` |  | GIIF |
| 1556 | `jdg.hyper.general.kks.conviction.tax_office_scrutiny_increased` |  | Praktyka US |
| 1557 | `jdg.hyper.general.kks.conviction.risk_profile_reclassification` |  | Art. 119b OP |
| 1558 | `jdg.hyper.general.kks.conviction.public_warning_list_art119b` |  | Art. 119b OP |
| 1559 | `jdg.hyper.general.kks.conviction.statute_interruption` |  | Art. 70 § 4 OP |
| 1601 | `jdg.hyper.general.regulated.cross_border.eu_qualifications_recognition` |  | Dyrektywa 2005/36/WE |
| 1602 | `jdg.hyper.general.regulated.cross_border.non_eu_qualifications` |  | Ustawy branżowe |
| 1603 | `jdg.hyper.general.regulated.cross_border.temporary_services_eu` |  | Dyrektywa 2005/36/WE |
| 1604 | `jdg.hyper.general.regulated.cross_border.double_taxation_specialist` |  | Umowy UPO |
| 1605 | `jdg.hyper.general.regulated.cross_border.vat_registration_abroad` |  | Art. 28k VAT, OSS |
| 1606 | `jdg.hyper.general.regulated.aggregate.profession_specific_risk_profile` |  | — |
| 1607 | `jdg.hyper.general.regulated.aggregate.annual_compliance_checklist` |  | — |
| 1608 | `jdg.hyper.general.insurance.mandatory.detection_legal` |  | Rozp. MS ws. OC adwokatów/radców |
| 1609 | `jdg.hyper.general.insurance.mandatory.detection_medical` |  | Ustawa o zawodzie lekarza |
| 1651 | `jdg.hyper.general.payment.installments.pit_revenue_per_installment` |  | Art. 14 PIT |
| 1652 | `jdg.hyper.general.payment.installments.vat_accrual_full_immediately` |  | Art. 19a VAT |
| 1653 | `jdg.hyper.general.payment.installments.vat_cash_per_installment` |  | Art. 21 VAT |
| 1654 | `jdg.hyper.general.payment.installments.late_payment_interest` |  | Art. 56 OP |
| 1655 | `jdg.hyper.general.payment.installments.contract_termination_consequences` |  | Art. 106j VAT |
| 1656 | `jdg.hyper.general.payment.advance.vat_obligation_on_receipt` |  | Art. 19a ust. 8 VAT |
| 1657 | `jdg.hyper.general.payment.advance.vat_invoice_required_15days` |  | Art. 106i VAT |
| 1658 | `jdg.hyper.general.payment.advance.pit_revenue_on_receipt` |  | Art. 14 PIT |
| 1659 | `jdg.hyper.general.payment.advance.advance_not_refunded_taxable` |  | Art. 14 PIT |

### `rules/jdg/hyper/limits/plan45.rego` (33 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1518 | `jdg.hyper.limits.seasonal.detection.months_with_revenue` |  | Art. 22 PP |
| 1519 | `jdg.hyper.limits.seasonal.detection.revenue_gap_3plus_months` |  | Art. 22 PP |
| 1520 | `jdg.hyper.limits.seasonal.detection.industry_code_tourism` |  | Art. 22 PP |
| 1521 | `jdg.hyper.limits.seasonal.detection.industry_code_agriculture` |  | Art. 22 PP |
| 1522 | `jdg.hyper.limits.seasonal.detection.construction_winter_break` |  | Art. 22 PP |
| 1523 | `jdg.hyper.limits.seasonal.suspension.keep_nip` |  | Art. 22 PP |
| 1524 | `jdg.hyper.limits.seasonal.suspension.max_6_months` |  | Art. 22 PP |
| 1525 | `jdg.hyper.limits.seasonal.closure.nip_loss_consequences` |  | Art. 30 CEIDG |
| 1526 | `jdg.hyper.limits.seasonal.closure.reopening_zus_new_application` |  | Art. 36 SUS |
| 1527 | `jdg.hyper.limits.seasonal.closure.vat_r_new_application` |  | Art. 96 VAT |
| 1528 | `jdg.hyper.limits.seasonal.zus.suspension_no_social` |  | Art. 36a SUS |
| 1529 | `jdg.hyper.limits.seasonal.zus.suspension_health_still_due` |  | Art. 36a SUS |
| 1530 | `jdg.hyper.limits.seasonal.zus.closure_no_contributions` |  | Art. 6 SUS |
| 1531 | `jdg.hyper.limits.seasonal.zus.annual_health_tier_lockstep` |  | Art. 81 ust. 2e-f u.ś.o.z. |
| 1532 | `jdg.hyper.limits.seasonal.zus.maly_plus_revenue_120k_eur_test` |  | Art. 18c SUS |
| 1533 | `jdg.hyper.limits.seasonal.pit.scale_annual_only_active_months` |  | Art. 27 PIT |
| 1534 | `jdg.hyper.limits.seasonal.pit.advances_simplified_recommendation` |  | Art. 44 ust. 6b PIT |
| 1535 | `jdg.hyper.limits.seasonal.pit.advances_no_income_months_zero` |  | Art. 44 ust. 3 PIT |
| 1536 | `jdg.hyper.limits.seasonal.pit.lump_sum_annual_calculation` |  | Art. 12 ust. 1 u.z.p.d. |
| 1537 | `jdg.hyper.limits.seasonal.pit.loss_carry_forward_5years` |  | Art. 9 ust. 3 PIT |
| 1538 | `jdg.hyper.limits.seasonal.vat.zero_returns_in_suspension` |  | Art. 99 ust. 7a VAT |
| 1539 | `jdg.hyper.limits.seasonal.vat.exemption_200k_proportion` |  | Art. 113 ust. 9 VAT |
| 1540 | `jdg.hyper.limits.seasonal.vat.exemption_breach_mid_year` |  | Art. 113 ust. 5 VAT |
| 1541 | `jdg.hyper.limits.seasonal.vat.margin_scheme_seasonal_goods` |  | Art. 120 VAT |
| 1542 | `jdg.hyper.limits.seasonal.vat.deduction_maintenance_costs` |  | Art. 86 VAT |
| 1543 | `jdg.hyper.limits.seasonal.aggregate.annual_summary_pit_zus` |  | — |
| 1544 | `jdg.hyper.limits.seasonal.aggregate.comparison_normal_vs_seasonal` |  | — |
| 1545 | `jdg.hyper.limits.seasonal.aggregate.optimal_strategy` |  | — |
| 1546 | `jdg.hyper.limits.kks.conviction.business_ban_art41kk` |  | Art. 41 KK |
| 1547 | `jdg.hyper.limits.kks.conviction.professional_license_revocation` |  | Art. 41 KK, ustawy korporacyjne |
| 1548 | `jdg.hyper.limits.kks.conviction.public_procurement_exclusion` |  | Art. 108 PZP |
| 1549 | `jdg.hyper.limits.kks.conviction.eu_funds_exclusion` |  | Rozp. 2018/1046 |
| 1550 | `jdg.hyper.limits.kks.conviction.regulated_profession_consequences` |  | Ustawy branżowe |

### `rules/jdg/hyper/mdr/plan45.rego` (38 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1004 | `jdg.hyper.mdr.mdr.hallmark.a4.loss_buying` |  | R1005 |
| 1005 | `jdg.hyper.mdr.mdr.hallmark.a5.conversion_income` |  |  |
| 1006 | `jdg.hyper.mdr.mdr.hallmark.a6.circular_transactions` |  | R1007 |
| 1007 | `jdg.hyper.mdr.mdr.hallmark.a7.double_deduction` |  |  |
| 1008 | `jdg.hyper.mdr.mdr.hallmark.a8.double_depreciation` |  | R1009 |
| 1009 | `jdg.hyper.mdr.mdr.hallmark.a9.double_tax_relief` |  |  |
| 1010 | `jdg.hyper.mdr.mdr.hallmark.a10.main_benefit_test` |  | R-ID |
| 1011 | `jdg.hyper.mdr.mdr.hallmark.b1.loss_utilization_group` |  | R1012 |
| 1012 | `jdg.hyper.mdr.mdr.hallmark.b2.income_conversion_capital` |  |  |
| 1013 | `jdg.hyper.mdr.mdr.hallmark.b3.deduction_cross_border` |  | R1014 |
| 1014 | `jdg.hyper.mdr.mdr.hallmark.b4.tax_haven_transfer` |  |  |
| 1015 | `jdg.hyper.mdr.mdr.hallmark.b5.non_arm_length_payment` |  | R1016 |
| 1016 | `jdg.hyper.mdr.mdr.hallmark.b6.deductible_cross_border` |  |  |
| 1017 | `jdg.hyper.mdr.mdr.hallmark.b7.non_taxation_claim` |  | R1018 |
| 1018 | `jdg.hyper.mdr.mdr.hallmark.b8.hybrid_mismatch` |  |  |
| 1019 | `jdg.hyper.mdr.mdr.hallmark.c1.strategic_acquisition` |  | R1020 |
| 1020 | `jdg.hyper.mdr.mdr.hallmark.c2.income_reclassification` |  |  |
| 1021 | `jdg.hyper.mdr.mdr.hallmark.c3.circular_flow_round_trip` |  | R1022 |
| 1022 | `jdg.hyper.mdr.mdr.hallmark.c4.cross_border_deduction` |  |  |
| 1023 | `jdg.hyper.mdr.mdr.hallmark.c5.transfer_pricing_gap` |  | R1024 |
| 1024 | `jdg.hyper.mdr.mdr.hallmark.c6.ip_transfer_hard_to_value` |  |  |
| 1025 | `jdg.hyper.mdr.mdr.hallmark.c7.business_restructuring` |  | R1026 |
| 1026 | `jdg.hyper.mdr.mdr.hallmark.c8.safe_harbour_manipulation` |  |  |
| 1027 | `jdg.hyper.mdr.mdr.hallmark.d1.ip_transfer_cross_border` |  | R1028 |
| 1028 | `jdg.hyper.mdr.mdr.hallmark.d2.business_transfer` |  |  |
| 1029 | `jdg.hyper.mdr.mdr.hallmark.e1.automatic_exchange_bypass` |  | R1030 |
| 1030 | `jdg.hyper.mdr.mdr.hallmark.e2.ubo_concealment` |  |  |
| 1031 | `jdg.hyper.mdr.mdr.hallmark.e3.trust_foundation_chain` |  | R1032 |
| 1032 | `jdg.hyper.mdr.mdr.hallmark.e4.nominee_director` |  |  |
| 1034 | `jdg.hyper.mdr.mdr.obligation.user_reporting` |  | R1035 |
| 1035 | `jdg.hyper.mdr.mdr.obligation.legal_professional_privilege` |  |  |
| 1036 | `jdg.hyper.mdr.mdr.obligation.quarterly_mdr4_report` |  | R1037 |
| 1037 | `jdg.hyper.mdr.mdr.deadline.30_days_from_scheme_available` |  |  |
| 1038 | `jdg.hyper.mdr.mdr.deadline.30_days_from_first_implementation` |  | R1039 |
| 1039 | `jdg.hyper.mdr.mdr.sanction.administrative_penalty_5m` |  |  |
| 1040 | `jdg.hyper.mdr.mdr.sanction.kks_liability` |  | R1041 |
| 1041 | `jdg.hyper.mdr.mdr.retention.scheme_documentation_6_years` |  |  |
| 1042 | `jdg.hyper.mdr.mdr.aggregate.annual_risk_score` |  | R-ID |

### `rules/jdg/hyper/misc/plan45.rego` (49 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1660 | `jdg.hyper.misc.payment.advance.kup_from_advance_to_supplier` |  | Art. 22 PIT |
| 1661 | `jdg.hyper.misc.payment.inkind.market_value_determination` |  | Art. 14 ust. 2 PIT |
| 1662 | `jdg.hyper.misc.payment.inkind.vat_base_market_value` |  | Art. 29a VAT |
| 1663 | `jdg.hyper.misc.payment.inkind.mixed_cash_inkind_split` |  | Art. 29a VAT |
| 1664 | `jdg.hyper.misc.payment.inkind.employee_compensation_tax` |  | Art. 12 PIT |
| 1665 | `jdg.hyper.misc.payment.inkind.shareholder_benefit_tax` |  | Art. 30a PIT |
| 1666 | `jdg.hyper.misc.payment.foreign.cash_limit_15k_pln_equivalent` |  | Art. 22p PIT |
| 1667 | `jdg.hyper.misc.payment.foreign.transfer_whitelist_required` |  | Art. 96b VAT |
| 1668 | `jdg.hyper.misc.payment.foreign.transfer_giif_reporting` |  | Art. 72 AML |
| 1669 | `jdg.hyper.misc.payment.foreign.swift_sepa_authorization` |  | — |
| 1670 | `jdg.hyper.misc.payment.foreign.fx_spread_recognition` |  | Art. 22 PIT |
| 1671 | `jdg.hyper.misc.payment.terminal.obligation_20k_eur_turnover` |  | Ustawa o usługach płatniczych |
| 1672 | `jdg.hyper.misc.payment.terminal.sanction_no_terminal_5000` |  | Ustawa o usługach płatniczych |
| 1673 | `jdg.hyper.misc.payment.terminal.vat_deduction_terminal_cost` |  | Art. 22 PIT, Art. 86 VAT |
| 1674 | `jdg.hyper.misc.advertising.vs_representation.distinction_test` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1675 | `jdg.hyper.misc.advertising.product_promotion_kup` |  | Art. 22 ust. 1 PIT |
| 1676 | `jdg.hyper.misc.advertising.brand_building_kup` |  | Art. 22 ust. 1 PIT |
| 1677 | `jdg.hyper.misc.advertising.representation_personal_prestige_nkup` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1678 | `jdg.hyper.misc.advertising.representation_limit_0_025pct` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1679 | `jdg.hyper.misc.advertising.digital.google_ads_kup` |  | Art. 22 PIT |
| 1680 | `jdg.hyper.misc.advertising.digital.facebook_ads_kup` |  | Art. 22 PIT |
| 1681 | `jdg.hyper.misc.advertising.digital.seo_sem_kup` |  | Art. 22 PIT |
| 1682 | `jdg.hyper.misc.advertising.digital.email_marketing_kup` |  | Art. 22 PIT |
| 1683 | `jdg.hyper.misc.advertising.digital.affiliate_program_kup` |  | Art. 22 PIT |
| 1684 | `jdg.hyper.misc.advertising.events.trade_fair_kup` |  | Art. 22 PIT, Art. 26ec PIT |
| 1685 | `jdg.hyper.misc.advertising.events.business_dinner_with_agenda_kup` |  | Art. 22 PIT |
| 1686 | `jdg.hyper.misc.advertising.events.luxury_trip_no_agenda_nkup` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1687 | `jdg.hyper.misc.advertising.events.conference_speaker_kup` |  | Art. 22 PIT |
| 1688 | `jdg.hyper.misc.advertising.events.networking_event_kup` |  | Art. 22 PIT |
| 1689 | `jdg.hyper.misc.advertising.gifts.under_200_pln_branded_kup` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1690 | `jdg.hyper.misc.advertising.gifts.over_200_pln_nkup` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1691 | `jdg.hyper.misc.advertising.gifts.unbranded_nkup` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1692 | `jdg.hyper.misc.advertising.gifts.samples_products_kup` |  | Art. 22 PIT |
| 1693 | `jdg.hyper.misc.advertising.gifts.vat_deduction_100_pln_limit` |  | Art. 88 ust. 1 pkt 5 VAT |
| 1694 | `jdg.hyper.misc.advertising.sponsorship.with_benefits_kup` |  | Art. 22 PIT |
| 1695 | `jdg.hyper.misc.advertising.sponsorship.charity_donation_treatment` |  | Art. 26 PIT |
| 1696 | `jdg.hyper.misc.advertising.sponsorship.sport_culture_kup` |  | Art. 22 PIT |
| 1697 | `jdg.hyper.misc.advertising.sponsorship.local_event_kup` |  | Art. 22 PIT |
| 1698 | `jdg.hyper.misc.advertising.sponsorship.vat_on_sponsorship` |  | Art. 86 VAT |
| 1699 | `jdg.hyper.misc.advertising.vat.deduction_full_standard` |  | Art. 86 VAT |
| 1700 | `jdg.hyper.misc.advertising.vat.deduction_gifts_100pln_limit` |  | Art. 88 ust. 1 pkt 5 VAT |
| 1701 | `jdg.hyper.misc.advertising.vat.imported_ad_services_reverse_charge` |  | Art. 28b VAT |
| 1702 | `jdg.hyper.misc.advertising.vat.cross_border_ads_vat_rules` |  | Art. 28b VAT |
| 1703 | `jdg.hyper.misc.advertising.vat.ads_on_platform_google_fb` |  | Art. 28b VAT |
| 1704 | `jdg.hyper.misc.advertising.influencer.kup_with_invoice_description` |  | Art. 22 PIT |
| 1705 | `jdg.hyper.misc.advertising.influencer.nkup_no_business_connection` |  | Art. 23 ust. 1 pkt 23 PIT |
| 1706 | `jdg.hyper.misc.advertising.influencer.vat_treatment_b2b` |  | Art. 28b VAT |
| 1707 | `jdg.hyper.misc.advertising.influencer.gift_vs_service_classification` |  | Art. 22 vs 23 PIT |
| 1708 | `jdg.hyper.misc.advertising.car_wrapping.vat26_full_deduction` |  | Art. 86a VAT, Art. 23 PIT |

### `rules/jdg/hyper/procurement/plan45.rego` (21 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1210 | `jdg.hyper.procurement.family.cooperation.notification_to_zus_7days` |  |  |
| 1211 | `jdg.hyper.procurement.family.cooperation.pit_treatment` |  | R1212 |
| 1212 | `jdg.hyper.procurement.family.car.usage.mixed_75pct_kup` |  |  |
| 1213 | `jdg.hyper.procurement.family.car.usage.mileage_log_family` |  | R1214 |
| 1214 | `jdg.hyper.procurement.family.car.usage.vat_deduction_50pct` |  |  |
| 1215 | `jdg.hyper.procurement.family.asset.transfer.gift_to_spouse` |  | R1216 |
| 1216 | `jdg.hyper.procurement.family.asset.transfer.gift_to_children` |  |  |
| 1217 | `jdg.hyper.procurement.family.asset.transfer.sale_arm_length` |  | R1218 |
| 1218 | `jdg.hyper.procurement.family.asset.transfer.vat_opodatkowanie` |  |  |
| 1219 | `jdg.hyper.procurement.family.asset.transfer.pcc_exemption` |  | R1220 |
| 1220 | `jdg.hyper.procurement.family.joint_filing.conditions` |  |  |
| 1221 | `jdg.hyper.procurement.family.joint_filing.benefit_calculation` |  | R1222 |
| 1222 | `jdg.hyper.procurement.family.joint_filing.deadline_april30` |  |  |
| 1223 | `jdg.hyper.procurement.family.joint_filing.exclusions` |  | R1224 |
| 1224 | `jdg.hyper.procurement.family.single_parent.preferential_calculation` |  |  |
| 1225 | `jdg.hyper.procurement.family.single_parent.child_custody_required` |  | R1226 |
| 1226 | `jdg.hyper.procurement.family.health_insurance.family_members` |  |  |
| 1227 | `jdg.hyper.procurement.family.health_insurance.kup_deduction` |  | R1228 |
| 1228 | `jdg.hyper.procurement.family.pit4r.obligation` |  |  |
| 1229 | `jdg.hyper.procurement.family.pit11.deadline_feb28` |  | R1230 |
| 1230 | `jdg.hyper.procurement.family.succession.planning_inheritance` |  |  |

### `rules/jdg/hyper/sanctions/plan45.rego` (41 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1560 | `jdg.hyper.sanctions.kks.conviction.extended_audit_period` |  | Art. 83 PP |
| 1561 | `jdg.hyper.sanctions.kks.conviction.business_partner_trust_loss` |  | — |
| 1562 | `jdg.hyper.sanctions.kks.conviction.joint_vat_liability_partners` |  | Art. 105a VAT |
| 1563 | `jdg.hyper.sanctions.kks.conviction.supply_chain_due_diligence` |  | Art. 105a VAT |
| 1564 | `jdg.hyper.sanctions.kks.conviction.contract_termination_clauses` |  | KC — klauzule umowne |
| 1565 | `jdg.hyper.sanctions.kks.conviction.isolation_from_business_networks` |  |  |
| 1566 | `jdg.hyper.sanctions.kks.rehabilitation.misdemeanor_3_years` |  | Art. 21 KKS |
| 1567 | `jdg.hyper.sanctions.kks.rehabilitation.crime_5_years` |  | Art. 21 KKS |
| 1568 | `jdg.hyper.sanctions.kks.rehabilitation.effect_clean_record` |  | Art. 106 KK |
| 1569 | `jdg.hyper.sanctions.kks.rehabilitation.business_ban_lift` |  | Art. 41 KK |
| 1570 | `jdg.hyper.sanctions.kks.rehabilitation.tax_office_notification` |  | Praktyka |
| 1571 | `jdg.hyper.sanctions.kks.enforcement.full_personal_liability` |  | Art. 26 OP |
| 1572 | `jdg.hyper.sanctions.kks.enforcement.no_asset_concealment` |  | Art. 36 OP, Art. 61 KKS |
| 1573 | `jdg.hyper.sanctions.kks.enforcement.bank_account_seizure` |  | Art. 75-89 Ustawy o post. egz. |
| 1574 | `jdg.hyper.sanctions.kks.enforcement.collateral_requirements` |  | Art. 33 OP |
| 1575 | `jdg.hyper.sanctions.kks.enforcement.insolvency_filing_obligation` |  | Art. 21 Prawa upadłościowego |
| 1576 | `jdg.hyper.sanctions.regulated.vat.exemption_doctor` |  | Art. 43 ust. 1 pkt 18-19 VAT |
| 1577 | `jdg.hyper.sanctions.regulated.vat.no_exemption_lawyer` |  | Art. 41 ust. 1 VAT |
| 1578 | `jdg.hyper.sanctions.regulated.vat.exemption_nurse_midwife` |  | Art. 43 ust. 1 pkt 19-20 VAT |
| 1579 | `jdg.hyper.sanctions.regulated.vat.education_tutor_exemption` |  | Art. 43 ust. 1 pkt 26-29 VAT |
| 1580 | `jdg.hyper.sanctions.regulated.vat.exemption_psychologist` |  | Art. 43 ust. 1 pkt 21 VAT |
| 1581 | `jdg.hyper.sanctions.regulated.kup.chamber_fees_full` |  | Art. 22 ust. 1 PIT |
| 1582 | `jdg.hyper.sanctions.regulated.kup.professional_insurance_kup` |  | Art. 22 ust. 1 PIT |
| 1583 | `jdg.hyper.sanctions.regulated.kup.continuing_education_kup` |  | Art. 22 ust. 1 PIT |
| 1584 | `jdg.hyper.sanctions.regulated.kup.books_journals_kup` |  | Art. 22 ust. 1 PIT |
| 1585 | `jdg.hyper.sanctions.regulated.kup.office_rent_home_office` |  | Art. 22 ust. 1 PIT |
| 1586 | `jdg.hyper.sanctions.regulated.zus.no_start_relief_former_employer` |  | Art. 18a SUS |
| 1587 | `jdg.hyper.sanctions.regulated.zus.concurrent_chamber_and_jdg` |  | Art. 9 SUS |
| 1588 | `jdg.hyper.sanctions.regulated.zus.mandatory_sickness_insurance` |  | Art. 11 SUS |
| 1589 | `jdg.hyper.sanctions.regulated.zus.dual_health_contribution` |  | Art. 82 u.ś.o.z. |
| 1590 | `jdg.hyper.sanctions.regulated.zus.minimum_base_health` |  | Art. 81 ust. 2 u.ś.o.z. |
| 1591 | `jdg.hyper.sanctions.regulated.privilege.attorney_client` |  | Art. 180 § 3 OP |
| 1592 | `jdg.hyper.sanctions.regulated.privilege.tax_advisor` |  | Art. 180 § 3 OP |
| 1593 | `jdg.hyper.sanctions.regulated.privilege.no_protection_for_business_records` |  | Art. 180 OP |
| 1594 | `jdg.hyper.sanctions.regulated.privilege.mdr_transfer_to_client` |  | Art. 86a OP |
| 1595 | `jdg.hyper.sanctions.regulated.privilege.limits_crime_fraud_exception` |  | Art. 180 § 4 OP |
| 1596 | `jdg.hyper.sanctions.regulated.chamber.membership_mandatory` |  | Ustawy korporacyjne |
| 1597 | `jdg.hyper.sanctions.regulated.chamber.fees_tax_deductible` |  | Art. 26 ust. 1 pkt 13 PIT |
| 1598 | `jdg.hyper.sanctions.regulated.chamber.disciplinary_proceedings` |  | Ustawy korporacyjne |
| 1599 | `jdg.hyper.sanctions.regulated.chamber.license_suspension_consequences` |  | Ustawy korporacyjne |
| 1600 | `jdg.hyper.sanctions.regulated.chamber.practice_certificate_renewal` |  | Ustawy korporacyjne |

### `rules/jdg/hyper/solidarity/plan45.rego` (11 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1050 | `jdg.hyper.solidarity.solidarity.levy.income.ip_box` |  | R1051 |
| 1051 | `jdg.hyper.solidarity.solidarity.levy.income.capital_gains` |  |  |
| 1052 | `jdg.hyper.solidarity.solidarity.levy.income.foreign` |  | R1053 |
| 1053 | `jdg.hyper.solidarity.solidarity.levy.zus.social.exclusion` |  |  |
| 1054 | `jdg.hyper.solidarity.solidarity.levy.zus.health.no_exclusion` |  | R1055 |
| 1055 | `jdg.hyper.solidarity.solidarity.levy.exemption.metoda_wylaczenia` |  |  |
| 1056 | `jdg.hyper.solidarity.solidarity.levy.exemption.foreign_tax_credit` |  | R1057 |
| 1057 | `jdg.hyper.solidarity.solidarity.levy.spouse.individual_calculation` |  |  |
| 1058 | `jdg.hyper.solidarity.solidarity.levy.spouse.no_income_transfer` |  | R1059 |
| 1059 | `jdg.hyper.solidarity.solidarity.levy.payment.deadline.april30` |  |  |
| 1060 | `jdg.hyper.solidarity.solidarity.levy.payment.no_advances` |  | R1061 |

### `rules/jdg/hyper/wis/plan45.rego` (16 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1070 | `jdg.hyper.wis.solidarity.levy.aggregate.alert_900k` |  | R-ID |
| 1071 | `jdg.hyper.wis.wis.eligibility.cn_code_ambiguous` |  | R1072 |
| 1072 | `jdg.hyper.wis.wis.eligibility.composite_product` |  |  |
| 1073 | `jdg.hyper.wis.wis.eligibility.new_product_launch` |  | R1074 |
| 1074 | `jdg.hyper.wis.wis.eligibility.import_first_time` |  |  |
| 1075 | `jdg.hyper.wis.wis.eligibility.contradictory_interpretations` |  | R1076 |
| 1076 | `jdg.hyper.wis.wis.eligibility.food_supplement_borderline` |  |  |
| 1077 | `jdg.hyper.wis.wis.eligibility.software_vs_service` |  | R1078 |
| 1078 | `jdg.hyper.wis.wis.eligibility.annual_turnover_50k` |  |  |
| 1079 | `jdg.hyper.wis.wis.application.cost.40pln` |  | R1080 |
| 1080 | `jdg.hyper.wis.wis.application.form.electronic_only` |  |  |
| 1081 | `jdg.hyper.wis.wis.application.required_fields` |  | R1082 |
| 1082 | `jdg.hyper.wis.wis.application.sample_may_be_required` |  |  |
| 1083 | `jdg.hyper.wis.wis.validity.5_years_from_issue` |  | R1084 |
| 1084 | `jdg.hyper.wis.wis.validity.early_expiry.regulation_change` |  |  |
| 1085 | `jdg.hyper.wis.wis.validity.early_expiry.cjeu_judgment` |  | R1086 |

### `rules/jpk/plan26_deadlines.rego` (1 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 972 | `jdg.jpk.filing_deadlines_detailed` |  | Art. 99 ust. 1-3 VAT |

### `rules/kks.rego` (249 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 130 | `jdg.kks.unreliable_pkpir_art56` | 🔴 BLOCK | Art. 56 § 1-4 KKS |
| 131 | `jdg.kks.unreliable_vat_evidence_art57` | 🔴 BLOCK | Art. 57 § 1 KKS |
| 132 | `jdg.kks.empty_invoice_art62` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 133 | `jdg.kks.wrong_vat_rate_art64` | 🟡 TRIAGE | Art. 64 KKS |
| 134 | `jdg.kks.tax_return_non_filing_art77` | 🔴 BLOCK | Art. 77 § 1-3 KKS |
| 135 | `jdg.kks.non_payment_of_tax_art79` | 🔴 BLOCK | Art. 79 KKS |
| 136 | `jdg.kks.destruction_of_docs_art68` | 🔴 BLOCK | Art. 68 KKS + Art. 86 Ordynacji podatkowej |
| 137 | `jdg.kks.voluntary_disclosure_art16` | 🟡 TRIAGE | Art. 16 § 1-3 KKS |
| 138 | `jdg.kks.statute_of_limitations_art44` |  | Art. 44 § 1-5 KKS |
| 139 | `jdg.kks.fiscal_penalty_calculation` |  | Art. 23 § 1-3 + Art. 48 KKS |
| 140 | `jdg.kks.obstruction_of_tax_audit_art69` | 🔴 BLOCK | Art. 69 § 1-3 KKS |
| 141 | `jdg.kks.aggregate_risk_score` |  | Całość KKS — reguła pomocnicza (risk assessment) |
| 200 | `jdg.kks.voluntary_disclosure_eligible` |  | Art. 16 § 1 KKS |
| 201 | `jdg.kks.voluntary_disclosure_deadline_breach` | 🔴 BLOCK | Art. 16 § 5 KKS |
| 202 | `jdg.kks.voluntary_disclosure_successor` |  | Art. 16 § 3 KKS |
| 203 | `jdg.kks.voluntary_disclosure_partial` | 🟡 TRIAGE | Art. 16 § 2 KKS |
| 204 | `jdg.kks.voluntary_disclosure_payment` | 🟡 TRIAGE | Art. 16 § 4 KKS |
| 205 | `jdg.kks.voluntary_disclosure_multiple_offenses` | 🟡 TRIAGE | Art. 16 § 1-6 KKS |
| 206 | `jdg.kks.voluntary_disclosure_correction_before_audit` | 🟡 TRIAGE | Art. 16 § 1 KKS w zw. z Art. 81 OrdPU |
| 207 | `jdg.kks.voluntary_disclosure_foreign_tax` | 🟡 TRIAGE | Art. 16 § 1 KKS w zw. z umowami o unikaniu podwójnego opodat... |
| 208 | `jdg.kks.voluntary_disclosure_mandatory_reporter` | 🔴 BLOCK | Art. 86a-86o OrdPU (MDR) |
| 209 | `jdg.kks.voluntary_disclosure_bribe_disclosure` | 🔴 BLOCK | Art. 16a KKS |
| 210 | `jdg.kks.extraordinary_mitigation` |  | Art. 17 KKS |
| 211 | `jdg.kks.minor_significance` |  | Art. 18 KKS |
| 212 | `jdg.kks.damage_restitution` |  | Art. 19 § 1 KKS |
| 213 | `jdg.kks.cooperation_with_authorities` |  | Art. 19 § 2 KKS |
| 214 | `jdg.kks.remorse_and_first_offense` |  | Art. 19 § 1-2 KKS |
| 215 | `jdg.kks.voluntary_surrender` |  | Art. 16 § 1-2 KKS |
| 216 | `jdg.kks.repeat_offense_aggravating` | 🔴 BLOCK | Art. 19 § 3 KKS |
| 217 | `jdg.kks.organized_group_aggravating` | 🔴 BLOCK | Art. 19 § 4 KKS |
| 218 | `jdg.kks.large_scale_aggravating` | 🔴 BLOCK | Art. 19 § 3-4 KKS |
| 219 | `jdg.kks.obstruction_of_justice` | 🔴 BLOCK | Art. 83 KKS |
| 220 | `jdg.kks.statute_of_limitations_crime_5y` |  | Art. 44 § 1 KKS |
| 221 | `jdg.kks.statute_of_limitations_misdemeanor_3y` |  | Art. 51 § 1 KKS |
| 222 | `jdg.kks.statute_limitation_suspension` | 🟡 TRIAGE | Art. 44 § 5 KKS |
| 223 | `jdg.kks.statute_limitation_interruption` | 🟡 TRIAGE | Art. 44 § 6 KKS |
| 224 | `jdg.kks.statute_limitation_extension_10y` | 🟡 TRIAGE | Art. 44 § 2 KKS |
| 225 | `jdg.kks.limitation_absolute_bar_p225` |  | Art. 44 § 7 KKS |
| 240 | `jdg.kks.tax_evasion_false_declaration` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 241 | `jdg.kks.tax_declaration_overdue` | 🔴 BLOCK | Art. 54 § 1-2 KKS |
| 242 | `jdg.kks.tax_evasion_hiding_revenue` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 243 | `jdg.kks.tax_evasion_inflated_costs_p243` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 244 | `jdg.kks.tax_evasion_double_books_p244` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 245 | `jdg.kks.tax_evasion_shell_company_p245` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 246 | `jdg.kks.evasion_fictitious_costs_p246` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 247 | `jdg.kks.evasion_identity_theft_p247` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 248 | `jdg.kks.evasion_tp_manipulation_p248` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 249 | `jdg.kks.evasion_crypto_concealment_p249` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 255 | `jdg.kks.unreliable_books_falsified_entries` | 🔴 BLOCK | Art. 56 § 1 KKS |
| 256 | `jdg.kks.unreliable_books_missing_entries` | 🔴 BLOCK | Art. 56 § 2 KKS |
| 257 | `jdg.kks.unreliable_books_wrong_values_p257` | 🔴 BLOCK | Art. 56 § 3 KKS |
| 258 | `jdg.kks.unreliable_books_destroyed_p258` | 🔴 BLOCK | Art. 60 § 1 KKS |
| 259 | `jdg.kks.books_late_entries_p259` | 🟡 TRIAGE | Art. 56 KKS |
| 260 | `jdg.kks.books_backdated_p260` | 🔴 BLOCK | Art. 56 KKS |
| 261 | `jdg.kks.books_ghost_employees_p261` | 🔴 BLOCK | Art. 56 KKS |
| 270 | `jdg.kks.unreliable_vat_records` | 🔴 BLOCK | Art. 57 § 1 KKS |
| 271 | `jdg.kks.vat_records_concealment_p271` | 🔴 BLOCK | Art. 57 § 2 KKS |
| 272 | `jdg.kks.vat_jpk_mismatch_p272` | 🔴 BLOCK | Art. 57 § 1 KKS |
| 273 | `jdg.kks.vat_gtu_misclassification_p273` | 🟡 TRIAGE | Art. 57 § 1 KKS |
| 274 | `jdg.kks.vat_rate_manipulation_p274` | 🔴 BLOCK | Art. 57 § 1 KKS |
| 275 | `jdg.kks.vat_split_payment_evasion_p275` | 🔴 BLOCK | Art. 57 § 1 KKS w zw. z Art. 108a VAT |
| 276 | `jdg.kks.vat_currency_conversion_fraud_p276` | 🔴 BLOCK | Art. 57 KKS |
| 277 | `jdg.kks.vat_reverse_charge_omission_p277` | 🔴 BLOCK | Art. 57 KKS |
| 278 | `jdg.kks.vat_duplicate_deduction_p278` | 🔴 BLOCK | Art. 57 KKS |
| 279 | `jdg.kks.vat_missing_sales_register_p279` | 🔴 BLOCK | Art. 57 KKS |
| 280 | `jdg.kks.documents_destroyed_art60` | 🔴 BLOCK | Art. 60 § 1 KKS |
| 281 | `jdg.kks.documents_hidden_from_authorities` | 🔴 BLOCK | Art. 60 § 2 KKS |
| 282 | `jdg.kks.documents_stolen_claim_p282` | 🟡 TRIAGE | Art. 60 § 1 KKS |
| 283 | `jdg.kks.documents_force_majeure_no_proof_p283` | 🔴 BLOCK | Art. 60 § 1 KKS |
| 284 | `jdg.kks.documents_held_by_former_accountant_p284` | 🔴 BLOCK | Art. 60 KKS w zw. z Art. 83 KKS |
| 285 | `jdg.kks.unjustified_vat_refund_art76` | 🔴 BLOCK | Art. 76 § 1 KKS |
| 286 | `jdg.kks.unjustified_refund_attempt_p286` | 🔴 BLOCK | Art. 76 § 2 KKS |
| 287 | `jdg.kks.refund_overstated_deduction_p287` | 🔴 BLOCK | Art. 76 § 1 KKS |
| 288 | `jdg.kks.refund_fake_export_p288` | 🔴 BLOCK | Art. 76 § 1 KKS |
| 289 | `jdg.kks.refund_fictitious_wnt_p289` | 🔴 BLOCK | Art. 76 KKS |
| 290 | `jdg.kks.tax_collector_not_remitted` | 🔴 BLOCK | Art. 59 § 1 KKS |
| 291 | `jdg.kks.tax_collector_withholding_false_p291` | 🔴 BLOCK | Art. 59 § 2 KKS |
| 292 | `jdg.kks.collector_aiding_evasion_p292` | 🔴 BLOCK | Art. 59 KKS |
| 293 | `jdg.kks.collector_zus_not_remitted_p293` | 🔴 BLOCK | Art. 59 KKS w zw. z Art. 46-47 SUS |
| 294 | `jdg.kks.collector_dac7_non_filing_p294` | 🔴 BLOCK | Art. 59 KKS w zw. z Art. 39q OrdPU |
| 295 | `jdg.kks.false_testimony_kas_p295` | 🔴 BLOCK | Art. 83 § 1 KKS |
| 296 | `jdg.kks.deceitful_evasion_method_p296` | 🔴 BLOCK | Art. 54 § 2 KKS |
| 297 | `jdg.kks.identity_concealment_p297` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 298 | `jdg.kks.chain_transaction_fraud_p298` | 🔴 BLOCK | Art. 54 § 1 KKS w zw. z Art. 62 KKS |
| 299 | `jdg.kks.digital_currency_concealment_p299` | 🔴 BLOCK | Art. 54 KKS w zw. z AML |
| 300 | `jdg.kks.empty_invoice_issued` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 301 | `jdg.kks.fake_invoice_issued` | 🔴 BLOCK | Art. 62 § 1 KKS |
| 302 | `jdg.kks.invoice_carousel_detected` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 303 | `jdg.kks.invoice_falsified_amount_p303` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 304 | `jdg.kks.invoice_counterfeit_p304` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 305 | `jdg.kks.invoice_used_for_tax_fraud_p305` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 306 | `jdg.kks.empty_invoice_systematic_p306` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 307 | `jdg.kks.empty_invoice_organized_scheme_p307` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 308 | `jdg.kks.empty_invoice_cross_border_p308` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 309 | `jdg.kks.empty_invoice_digital_forgery_p309` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 310 | `jdg.kks.empty_invoice_ksef_fraud_p310` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 311 | `jdg.kks.empty_invoice_timestamp_fraud_p311` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 312 | `jdg.kks.empty_invoice_recipient_knowledge_p312` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 313 | `jdg.kks.empty_invoice_intermediary_p313` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 314 | `jdg.kks.empty_invoice_conspirator_p314` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 315 | `jdg.kks.empty_invoice_value_bands_p315` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 316 | `jdg.kks.empty_invoice_cross_border_p316` | 🔴 BLOCK | Art. 62 § 2 KKS w zw. z Dyrektywą VAT |
| 317 | `jdg.kks.empty_invoice_esignature_forgery_p317` | 🔴 BLOCK | Art. 62 § 1-2 KKS + Art. 270 KK + eIDAS |
| 318 | `jdg.kks.empty_invoice_ksef_validation_p318` | 🔴 BLOCK | Art. 106na VAT + Art. 62 KKS |
| 319 | `jdg.kks.empty_invoice_upo_verification_p319` | 🔴 BLOCK | Art. 106na-106nq VAT + Art. 62 KKS |
| 320 | `jdg.kks.failure_to_invoice_p320` | 🔴 BLOCK | Art. 63 § 1 KKS |
| 321 | `jdg.kks.failure_to_invoice_b2b_p321` | 🔴 BLOCK | Art. 63 § 2 KKS w zw. z Art. 106b VAT |
| 322 | `jdg.kks.failure_to_invoice_deadline_p322` | 🟡 TRIAGE | Art. 63 KKS w zw. z Art. 106i VAT |
| 323 | `jdg.kks.failure_to_invoice_over_threshold_p323` | 🔴 BLOCK | Art. 63 KKS |
| 324 | `jdg.kks.failure_to_invoice_serial_p324` | 🔴 BLOCK | Art. 63 KKS (uporczywość) |
| 325 | `jdg.kks.failure_to_invoice_cash_p325` | 🔴 BLOCK | Art. 63 KKS w zw. z Art. 19a VAT |
| 326 | `jdg.kks.invoice_incorrect_data_p326` | 🔴 BLOCK | Art. 63 § 2 KKS |
| 327 | `jdg.kks.invoice_missing_fields_p327` | 🟡 TRIAGE | Art. 63 KKS w zw. z Art. 106e VAT |
| 328 | `jdg.kks.invoice_false_nip_p328` | 🔴 BLOCK | Art. 63 KKS + Art. 81 KKS |
| 329 | `jdg.kks.invoice_failure_aggregate_p329` | 🔴 BLOCK | Art. 62-63 KKS — agregacja |
| 330 | `jdg.kks.wrong_vat_rate_p330` | 🟡 TRIAGE | Art. 64 KKS |
| 331 | `jdg.kks.wrong_vat_rate_significant_p331` | 🔴 BLOCK | Art. 64 KKS (znaczna wartość) |
| 332 | `jdg.kks.vat_refund_overstatement_p332` | 🔴 BLOCK | Art. 65 KKS |
| 333 | `jdg.kks.vat_refund_fictitious_export_p333` | 🔴 BLOCK | Art. 65 KKS w zw. z Art. 76 KKS |
| 334 | `jdg.kks.vat_refund_accelerated_fraud_p334` | 🔴 BLOCK | Art. 65 KKS w zw. z Art. 87 ust. 6 VAT |
| 335 | `jdg.kks.untrue_tax_return_p335` | 🔴 BLOCK | Art. 66 KKS |
| 336 | `jdg.kks.withholding_tax_failure_p336` | 🔴 BLOCK | Art. 67 KKS |
| 337 | `jdg.kks.withholding_tax_non_remittance_p337` | 🔴 BLOCK | Art. 67 KKS w zw. z Art. 59 KKS |
| 338 | `jdg.kks.wht_certificate_fraud_p338` | 🔴 BLOCK | Art. 67 KKS + Art. 60 KKS |
| 339 | `jdg.kks.vat_calculation_errors_aggregate_p339` | 🟡 TRIAGE | Art. 64-67 KKS — agregacja |
| 340 | `jdg.kks.destruction_documents_p340` | 🔴 BLOCK | Art. 68 KKS |
| 341 | `jdg.kks.destruction_before_retention_p341` | 🔴 BLOCK | Art. 68 KKS w zw. z Art. 86 OrdPU |
| 342 | `jdg.kks.destruction_during_audit_p342` | 🔴 BLOCK | Art. 68 KKS + Art. 83 KKS |
| 343 | `jdg.kks.obstruction_audit_p343` | 🔴 BLOCK | Art. 69 KKS |
| 344 | `jdg.kks.obstruction_denial_of_access_p344` | 🔴 BLOCK | Art. 69 KKS |
| 345 | `jdg.kks.obstruction_false_information_p345` | 🔴 BLOCK | Art. 69 KKS w zw. z Art. 83 KKS |
| 346 | `jdg.kks.non_filing_declaration_p346` | 🔴 BLOCK | Art. 70 KKS |
| 347 | `jdg.kks.non_filing_multiple_periods_p347` | 🔴 BLOCK | Art. 70 KKS |
| 348 | `jdg.kks.non_filing_despite_request_p348` | 🔴 BLOCK | Art. 70 KKS w zw. z Art. 83 KKS |
| 349 | `jdg.kks.business_without_registration_p349` | 🔴 BLOCK | Art. 71 KKS |
| 350 | `jdg.kks.business_despite_ban_p350` | 🔴 BLOCK | Art. 72 KKS |
| 351 | `jdg.kks.illegal_gambling_tax_p351` | 🔴 BLOCK | Art. 73 KKS |
| 352 | `jdg.kks.excise_duty_evasion_p352` | 🔴 BLOCK | Art. 74 KKS |
| 353 | `jdg.kks.customs_duty_evasion_p353` | 🔴 BLOCK | Art. 75 KKS |
| 354 | `jdg.kks.import_vat_evasion_p354` | 🔴 BLOCK | Art. 76 KKS |
| 355 | `jdg.kks.vat_fraud_network_detection_p355` | 🔴 BLOCK | Art. 62 KKS + Art. 76a KKS |
| 356 | `jdg.kks.vat_fraud_temporal_pattern_p356` | 🟡 TRIAGE | Art. 62 KKS — analiza wzorców |
| 357 | `jdg.kks.vat_fraud_geographic_clustering_p357` | 🟡 TRIAGE | Art. 62 KKS — geografia fraudu |
| 358 | `jdg.kks.vat_fraud_industry_specific_p358` | 🔴 BLOCK | Art. 62 KKS — branże wrażliwe |
| 359 | `jdg.kks.vat_fraud_new_business_red_flag_p359` | 🟡 TRIAGE | Art. 62 KKS — red flag |
| 360 | `jdg.kks.vat_fraud_rapid_dereg_p360` | 🔴 BLOCK | Art. 62 KKS — znikający podatnik |
| 361 | `jdg.kks.vat_fraud_nip_rotation_p361` | 🟡 TRIAGE | Art. 62 KKS — rotacja podmiotów |
| 362 | `jdg.kks.vat_fraud_bank_account_hopping_p362` | 🟡 TRIAGE | Art. 62 KKS — AML red flag |
| 363 | `jdg.kks.vat_fraud_insolvency_pattern_p363` | 🔴 BLOCK | Art. 62 KKS + Art. 300 KK |
| 364 | `jdg.kks.vat_section_aggregate_risk_p364` | 🔴 BLOCK | Art. 62-76 KKS — agregacja sekcji VAT |
| 365 | `jdg.kks.asset_seizure_risk_p365` | 🔴 BLOCK | Art. 22-31 KKS — zabezpieczenie majątkowe |
| 366 | `jdg.kks.property_security_active_p366` | 🔴 BLOCK | Art. 22 KKS |
| 367 | `jdg.kks.bank_account_blocked_p367` | 🔴 BLOCK | Art. 23 § 1 KKS |
| 368 | `jdg.kks.mortgage_on_property_p368` | 🔴 BLOCK | Art. 23 § 2 KKS w zw. z Art. 34 § 2 OrdPU |
| 369 | `jdg.kks.tax_lien_registered_p369` | 🔴 BLOCK | Art. 24 KKS w zw. z Art. 41 OrdPU |
| 370 | `jdg.kks.third_party_liability_p370` | 🔴 BLOCK | Art. 24a KKS |
| 371 | `jdg.kks.successor_liability_p371` | 🟡 TRIAGE | Art. 25 KKS |
| 372 | `jdg.kks.business_activity_ban_p372` | 🔴 BLOCK | Art. 26 KKS w zw. z Art. 41 KK |
| 373 | `jdg.kks.public_contracts_ban_p373` | 🔴 BLOCK | Art. 108-109 PZP + KKS |
| 374 | `jdg.kks.professional_license_risk_p374` | 🔴 BLOCK | Art. 26 KKS + przepisy korporacyjne |
| 375 | `jdg.kks.cross_offense_pattern_p375` | 🔴 BLOCK | Art. 54-76 KKS — analiza międzyprzestępcza |
| 376 | `jdg.kks.offense_chain_detection_p376` | 🔴 BLOCK | Art. 54-76 KKS — związek przestępstw |
| 377 | `jdg.kks.multi_year_fraud_p377` | 🔴 BLOCK | Art. 54-76 KKS — ciągłość przestępstwa |
| 378 | `jdg.kks.organized_crime_indicators_p378` | 🔴 BLOCK | Art. 19 § 4 KKS — grupa zorganizowana |
| 379 | `jdg.kks.money_laundering_nexus_p379` | 🔴 BLOCK | Art. 299 KK + Art. 54-76 KKS |
| 380 | `jdg.kks.tax_crime_evolution_p380` | 🟡 TRIAGE | Art. 54-76 KKS — analiza trendu |
| 381 | `jdg.kks.cumulative_tax_loss_p381` | 🔴 BLOCK | Art. 54-76 KKS — suma uszczupleń |
| 382 | `jdg.kks.offense_severity_escalation_p382` | 🔴 BLOCK | Art. 54-76 KKS — gradacja kar |
| 383 | `jdg.kks.global_kks_risk_score_p383` | 🔴 BLOCK | Art. 54-76 KKS — scoring globalny |
| 384 | `jdg.kks.risk_to_business_survival_p384` | 🔴 BLOCK | Art. 54-76 KKS — ocena wpływu na JDG |
| 385 | `jdg.kks.mandate_proceedings_eligible_p385` |  | Art. 137-149 KKW — postępowanie mandatowe |
| 386 | `jdg.kks.mandate_amount_p386` |  | Art. 48 KKW — wymiar mandatu |
| 387 | `jdg.kks.mandate_consent_required_p387` | 🟡 TRIAGE | Art. 137 § 2 KKW |
| 388 | `jdg.kks.mandate_refusal_consequences_p388` | 🔴 BLOCK | Art. 137 § 3 KKW |
| 389 | `jdg.kks.mandate_payment_deadline_p389` | 🔴 BLOCK | Art. 140 KKW |
| 390 | `jdg.kks.crime_to_misdemeanor_bridge_p390` | 🟡 TRIAGE | Art. 53 § 3-4 KKS (wypadek mniejszej wagi) |
| 391 | `jdg.kks.criminal_record_check_p391` | 🟡 TRIAGE | Art. 19 § 3 KKS — recydywa skarbowa |
| 392 | `jdg.kks.prosecution_decision_factors_p392` | 🟡 TRIAGE | Art. 54-83 KKS — decyzja prokuratorska |
| 393 | `jdg.kks.cross_tax_type_offenses_p393` | 🔴 BLOCK | Art. 54-76 KKS — zbieg przepisów |
| 394 | `jdg.kks.offense_statute_mapping_p394` |  | Art. 44, 51 KKS — terminy przedawnienia |
| 395 | `jdg.kks.penalty_calculation_input_p395` |  | Art. 22-31 KKS — dane wsadowe kary |
| 396 | `jdg.kks.pre_misdemeanor_screening_p396` | 🟡 TRIAGE | Art. 53, 77-83 KKS — granica przestępstwo/wykroczenie |
| 397 | `jdg.kks.offense_discovery_path_p397` | 🟡 TRIAGE | Art. 16 KKS — czynny żal |
| 398 | `jdg.kks.legal_defense_validity_p398` |  | Art. 10-11 KKS — kontratypy i obrona |
| 399 | `jdg.kks.crime_section_summary_p399` | 🔴 BLOCK | Art. 54-76 KKS — synteza |
| 400 | `jdg.kks.declaration_not_filed_vat` | 🟡 TRIAGE | Art. 77 § 1 KKS |
| 401 | `jdg.kks.declaration_not_filed_pit` | 🟡 TRIAGE | Art. 77 § 2 KKS |
| 402 | `jdg.kks.declaration_not_filed_zus` | 🟡 TRIAGE | Art. 77 § 3 KKS |
| 403 | `jdg.kks.declaration_not_filed_cit_withholding_p403` | 🟡 TRIAGE | Art. 77 KKS |
| 404 | `jdg.kks.declaration_not_filed_local_taxes_p404` | 🟡 TRIAGE | Art. 77 KKS |
| 405 | `jdg.kks.declaration_not_filed_pcc_p405` | 🟡 TRIAGE | Art. 77 KKS |
| 406 | `jdg.kks.declaration_not_filed_intrastat_p406` | 🟡 TRIAGE | Art. 77 KKS |
| 407 | `jdg.kks.declaration_not_filed_tpr_p407` | 🟡 TRIAGE | Art. 77 KKS |
| 410 | `jdg.kks.incorrect_data_in_declaration` | 🟡 TRIAGE | Art. 78 § 1 KKS |
| 411 | `jdg.kks.tax_not_paid_on_time` | 🟡 TRIAGE | Art. 79 KKS |
| 412 | `jdg.kks.incorrect_data_partial_payment_p412` | 🟡 TRIAGE | Art. 79 KKS |
| 413 | `jdg.kks.incorrect_data_late_payment_pattern_p413` | 🟡 TRIAGE | Art. 79 KKS |
| 414 | `jdg.kks.incorrect_data_withholding_not_remitted_p414` | 🔴 BLOCK | Art. 77-79 KKS |
| 415 | `jdg.kks.incorrect_data_wrong_account_p415` | 🟡 TRIAGE | Art. 78 KKS |
| 420 | `jdg.kks.obstruction_no_books_at_premises_p420` | 🔴 BLOCK | Art. 83 KKS |
| 421 | `jdg.kks.obstruction_computer_broken_p421` | 🔴 BLOCK | Art. 83 KKS |
| 422 | `jdg.kks.obstruction_accountant_disappeared_p422` | 🔴 BLOCK | Art. 83 KKS |
| 423 | `jdg.kks.obstruction_data_encrypted_p423` | 🔴 BLOCK | Art. 83 KKS |
| 424 | `jdg.kks.obstruction_force_majeure_false_p424` | 🟡 TRIAGE | Art. 83 KKS |
| 430 | `jdg.kks.risk_aggregation_low` |  | KKS — agregacja ryzyka |
| 431 | `jdg.kks.risk_aggregation_medium` | 🟡 TRIAGE | KKS — agregacja ryzyka |
| 432 | `jdg.kks.risk_aggregation_high` | 🔴 BLOCK | KKS — agregacja ryzyka |
| 433 | `jdg.kks.criminal_threshold_p433` | 🔴 BLOCK | Art. 53 § 3-6 KKS |
| 434 | `jdg.kks.risk_pattern_detection_p434` | 🟡 TRIAGE | KKS — analiza wzorców |
| 435 | `jdg.kks.risk_recidivism_check_p435` | 🟡 TRIAGE | KKS — recydywa |
| 436 | `jdg.kks.risk_seasonal_pattern_p436` | 🟡 TRIAGE | KKS — analiza sezonowa |
| 437 | `jdg.kks.unregistered_activity_p437` | 🔴 BLOCK | Art. 60^1 § 1 KKS |
| 438 | `jdg.kks.ceidg_false_data_p438` | 🔴 BLOCK | Art. 60^1 § 2 KKS |
| 439 | `jdg.kks.nip_not_obtained_p439` | 🔴 BLOCK | Art. 81 § 1 KKS |
| 440 | `jdg.kks.ceidg_change_not_reported_p440` | 🟡 TRIAGE | Art. 81 KKS |
| 441 | `jdg.kks.bank_account_not_reported_p441` | 🟡 TRIAGE | Art. 81 KKS |
| 442 | `jdg.kks.vat_r_not_submitted_p442` | 🔴 BLOCK | Art. 81 KKS w zw. z Art. 96 VAT |
| 443 | `jdg.kks.change_of_accountant_not_reported_p443` | 🟡 TRIAGE | Art. 81 KKS |
| 444 | `jdg.kks.business_address_unreachable_p444` | 🔴 BLOCK | Art. 82 KKS |
| 445 | `jdg.kks.cash_register_not_installed_p445` | 🔴 BLOCK | Art. 84 KKS w zw. z Art. 111 VAT |
| 446 | `jdg.kks.receipt_not_issued_b2c_p446` | 🔴 BLOCK | Art. 84 § 1 KKS |
| 447 | `jdg.kks.bdo_register_missing_p447` | 🟡 TRIAGE | Art. 82 KKS w zw. z ustawa o odpadach |
| 448 | `jdg.kks.employee_tax_forms_missing_p448` | 🟡 TRIAGE | Art. 81-82 KKS |
| 449 | `jdg.kks.intrastat_missing_p449` | 🟡 TRIAGE | Art. 81 KKS w zw. z ustawa o statystyce |
| 450 | `jdg.kks.refused_inspection_p450` | 🔴 BLOCK | Art. 83 § 1 KKS |
| 451 | `jdg.kks.false_evidence_submitted_p451` | 🔴 BLOCK | Art. 83 § 2 KKS |
| 452 | `jdg.kks.unpaid_vat_penalty_30pct_p452` | 🔴 BLOCK | Art. 82-84 KKS w zw. z Art. 108a VAT |
| 453 | `jdg.kks.missing_invoice_numbering_p453` | 🟡 TRIAGE | Art. 82 KKS |
| 454 | `jdg.kks.storage_below_5years_p454` | 🔴 BLOCK | Art. 82 KKS w zw. z Art. 86 OrdPU |
| 455 | `jdg.kks.signature_missing_declaration_p455` | 🟡 TRIAGE | Art. 81 KKS |
| 456 | `jdg.kks.aml_sar_not_filed_p456` | 🔴 BLOCK | Art. 72-86 AML w zw. z Art. 82 KKS |
| 457 | `jdg.kks.cesop_not_reported_p457` | 🟡 TRIAGE | Art. 82 KKS w zw. z Rozp. 2020/284 |
| 458 | `jdg.kks.repeat_minor_offense_p458` | 🟡 TRIAGE | Art. 50 § 2 KKS |
| 459 | `jdg.kks.unauthorized_tax_advice_p459` | 🔴 BLOCK | Art. 81 KKS w zw. z ustawa o doradztwie podatkowym |
| 460 | `jdg.kks.property_seizure_risk_p460` | 🔴 BLOCK | Art. 31-35 KKS |
| 461 | `jdg.kks.travel_ban_risk_p461` | 🔴 BLOCK | Art. 34 KKS |
| 462 | `jdg.kks.business_suspension_risk_p462` | 🔴 BLOCK | Art. 33 KKS |
| 470 | `jdg.kks.aiding_abetting_p470` | 🔴 BLOCK | Art. 24 KKS |
| 471 | `jdg.kks.instigating_p471` | 🔴 BLOCK | Art. 24 KKS |
| 490 | `jdg.kks.daily_rate_calculation` |  | Art. 23 § 3 KKS |
| 491 | `jdg.kks.fine_range_calculation` |  | Art. 23 § 1-2 KKS |
| 492 | `jdg.kks.confiscation_risk` | 🔴 BLOCK | Art. 29-30 KKS |
| 493 | `jdg.kks.probation_eligibility` |  | Art. 28 KKS |
| 494 | `jdg.kks.imprisonment_risk_p494` | 🔴 BLOCK | Art. 27 KKS |
| 495 | `jdg.kks.mandatory_penalty_notice_p495` | 🟡 TRIAGE | Art. 48-52 KKS |
| 496 | `jdg.kks.publication_of_verdict_p496` | 🔴 BLOCK | Art. 30 KKS |
| 497 | `jdg.kks.aggregate_penalty_p497` | 🔴 BLOCK | Art. 24 § 1-3 KKS |
| 498 | `jdg.kks.penalty_payment_plan_p498` | 🟡 TRIAGE | Art. 27 § 1 KKS |
| 499 | `jdg.kks.penalty_execution_timeline_p499` | 🟡 TRIAGE | Art. 25-27, Art. 46-53 KKS |

### `rules/kks/plan42_detailed.rego` (12 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 130 | `jdg.kks.unreliable_pkpir_art56` | 🔴 BLOCK | Art. 56 § 1-4 KKS |
| 131 | `jdg.kks.unreliable_vat_evidence_art57` | 🔴 BLOCK | Art. 57 § 1 KKS |
| 132 | `jdg.kks.empty_invoice_art62` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 133 | `jdg.kks.wrong_vat_rate_art64` | 🔴 BLOCK | Art. 64 KKS |
| 134 | `jdg.kks.tax_return_non_filing_art77` | 🔴 BLOCK | Art. 77 § 1-3 KKS |
| 135 | `jdg.kks.non_payment_of_tax_art79` | 🟡 TRIAGE | Art. 79 KKS |
| 136 | `jdg.kks.destruction_of_documents_art68` | 🔴 BLOCK | Art. 68 KKS |
| 137 | `jdg.kks.voluntary_disclosure_art16` |  | Art. 16 § 1-3 KKS |
| 138 | `jdg.kks.criminal_statute_art44` |  | Art. 44 § 1-5 KKS |
| 139 | `jdg.kks.fiscal_penalty_calculation` |  | Art. 23 § 1-3 KKS |
| 140 | `jdg.kks.obstruction_of_audit_art69` | 🔴 BLOCK | Art. 69 § 1-3 KKS |
| 141 | `jdg.kks.aggregate_risk_score` |  | Całość KKS — reguła pomocnicza |

### `rules/kks/plan43_decomposition.rego` (21 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 200 | `jdg.kks.vd_conditions_art16_p1` |  | Art. 16 § 1 KKS |
| 201 | `jdg.kks.vd_payment_obligation_art16_p2` | 🔴 BLOCK | Art. 16 § 2 KKS |
| 202 | `jdg.kks.vd_incomplete_notification_art16_p3` | 🟡 TRIAGE | Art. 16 § 3 KKS |
| 207 | `jdg.kks.vd_effect_no_penalty_art16_p8` |  | Art. 16 § 8 KKS |
| 220 | `jdg.kks.statute_crime_5y_art20_p1` |  | Art. 20 § 1 KKS |
| 221 | `jdg.kks.statute_misdemeanor_3y_art20_p2` |  | Art. 20 § 2 KKS |
| 222 | `jdg.kks.statute_extension_5y_art20_p3` |  | Art. 20 § 3 KKS |
| 223 | `jdg.kks.statute_interruption_art21_p1` |  | Art. 21 § 1 KKS |
| 240 | `jdg.kks.tax_evasion_elements_art54_p1` | 🔴 BLOCK | Art. 54 § 1 KKS |
| 241 | `jdg.kks.tax_evasion_significant_art54_p2` | 🔴 BLOCK | Art. 54 § 2 KKS |
| 242 | `jdg.kks.tax_evasion_concealed_business_art54_p3` | 🔴 BLOCK | Art. 54 § 3 KKS |
| 256 | `jdg.kks.unreliable_pkpir_systematic_art56_p2` | 🔴 BLOCK | Art. 56 § 2 KKS |
| 257 | `jdg.kks.pkpir_fictitious_entries_art56_p3` | 🔴 BLOCK | Art. 56 § 3 KKS |
| 302 | `jdg.kks.empty_invoice_carousel_art62_p3` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 303 | `jdg.kks.invoice_falsification_art62_p4` | 🔴 BLOCK | Art. 62 § 1 KKS |
| 400 | `jdg.kks.declaration_non_filing_art77_p1` |  | Art. 77 § 1 KKS |
| 401 | `jdg.kks.declaration_persistent_art77_p2` | 🔴 BLOCK | Art. 77 § 2 KKS |
| 411 | `jdg.kks.tax_non_payment_art79_p1` |  | Art. 79 KKS |
| 490 | `jdg.kks.fine_daily_rate_art23` |  | Art. 23 § 1-3 KKS |
| 491 | `jdg.kks.fine_amount_range_art23_p4` |  | Art. 23 § 4 KKS |
| 492 | `jdg.kks.imprisonment_substitute_art25` | 🔴 BLOCK | Art. 25 KKS |

### `rules/kks/plan44_kks_conviction.rego` (2 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1960 | `jdg.kks.conviction_business_ban` | 🔴 BLOCK | Art. 41 KK |
| 1964 | `jdg.kks.conviction_rehabilitation` |  | Art. 21 KKS, Art. 106 KK |

### `rules/ksef_jpk.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 950 | `jdg.ksef_jpk.ksef_mandatory` |  | Art. 106na-106nq VAT |
| 952 | `jdg.ksef_jpk.ksef_b2c_exemption` |  | Art. 106ga ust. 2 pkt 4 VAT |
| 960 | `jdg.ksef_jpk.ksef_offline_recovery` |  | Art. 106ne VAT |
| 970 | `jdg.ksef_jpk.jpk_v7m` |  | Art. 99 VAT, rozporządzenie JPK_VAT |
| 974 | `jdg.ksef_jpk.jpk_gtu_completeness` | 🟡 TRIAGE | § 10 rozporządzenia JPK_VAT |
| 980 | `jdg.ksef_jpk.jpk_pkpir` |  | Art. 193a Ordynacji podatkowej |

### `rules/liability.rego` (10 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1150 | `jdg.liability.statute_5_years` |  | Art. 70 § 1 Ordynacji podatkowej |
| 1158 | `jdg.liability.personal_liability` |  | Art. 33 Ordynacji podatkowej, Art. 415 KC |
| 1164 | `jdg.liability.late_payment_interest` |  | Art. 47-52 Ordynacji podatkowej |
| 1167 | `jdg.liability.tax_arrears_detection` | 🟡 TRIAGE | Art. 20-21 Ordynacji podatkowej |
| 1168 | `jdg.liability.voluntary_disclosure` |  | Art. 16-16b KKS |
| 1169 | `jdg.liability.overpayment_detection` |  | Art. 72-80 Ordynacji podatkowej |
| 1170 | `jdg.liability.deferral_active` |  | Art. 48, Art. 67a-67e Ordynacji podatkowej |
| 1171 | `jdg.liability.tax_remission_active` |  | Art. 51 Ordynacji podatkowej |
| 1172 | `jdg.liability.overpayment_offset` |  | Art. 76-80 Ordynacji podatkowej |
| 1174 | `jdg.liability.tax_proceeding_deadlines` |  | Art. 120-129 Ordynacji podatkowej |

### `rules/local_taxes.rego` (13 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1300 | `jdg.local.pcc_mandatory` |  | Ustawa o podatku od czynności cywilnoprawnych |
| 1301 | `jdg.local.pcc_loan_agreement` | 🟡 TRIAGE | Art. 7 ust. 1 pkt 4 Ustawy o PCC |
| 1302 | `jdg.local.pcc_share_purchase` | 🟡 TRIAGE | Art. 7 ust. 1 pkt 1 lit. a Ustawy o PCC |
| 1303 | `jdg.local.pcc_sale_agreement` | 🟡 TRIAGE | Art. 7 ust. 1 pkt 1 lit. a Ustawy o PCC |
| 1304 | `jdg.local.pcc_exemption_check` |  | Art. 9 Ustawy o PCC |
| 1305 | `jdg.local.agricultural_tax` |  | Ustawa o podatku rolnym |
| 1306 | `jdg.local.forest_tax` |  | Ustawa o podatku leśnym |
| 1307 | `jdg.local.building_tax` | 🟡 TRIAGE | Ustawa o podatkach i opłatach lokalnych |
| 1308 | `jdg.local.water_intake_fee` |  | Prawo wodne — Art. 268-273 |
| 1309 | `jdg.local.waste_management_fee` |  | Ustawa o odpadach, Ustawa o utrzymaniu czystości i porządku ... |
| 1310 | `jdg.local.real_estate_commercial` |  | Ustawa o podatkach i opłatach lokalnych |
| 1310 | `jdg.local.advertising_fee` |  | Ustawa o podatkach i opłatach lokalnych (opłata reklamowa — ... |
| 1320 | `jdg.local.transport_tax` |  | Ustawa o podatkach i opłatach lokalnych |

### `rules/local_taxes/pcc.rego` (3 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1300 | `jdg.local_taxes.pcc.pcc_mandatory_purchase` | 🟡 TRIAGE | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959), Art. ... |
| 1302 | `jdg.local_taxes.pcc.pcc_loan_from_private` | 🟡 TRIAGE | Ustawa o PCC, Art. 7 ust. 1 pkt 4 |
| 1304 | `jdg.local_taxes.pcc.pcc_formation_exempt` |  | Ustawa o PCC — opodatkowaniu podlegają tylko czynności dot. ... |

### `rules/local_taxes/plan26_local.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1300 | `jdg.local_taxes.pcc_purchase_from_private` |  | Ustawa o PCC, Art. 1-2, Art. 7 |
| 1302 | `jdg.local_taxes.pcc_loan_from_private` |  | Ustawa o PCC, Art. 7 ust. 1 pkt 4 |
| 1304 | `jdg.local_taxes.pcc_company_exempt_info` |  | Ustawa o PCC |
| 1310 | `jdg.local_taxes.real_estate_commercial_rate` |  | Ustawa o podatkach i opłatach lokalnych, Art. 2-7 |
| 1312 | `jdg.local_taxes.real_estate_dn1_filing` | 🟡 TRIAGE | Ustawa o podatkach i opłatach lokalnych |
| 1320 | `jdg.local_taxes.transport_tax_applicable` |  | Ustawa o podatkach i opłatach lokalnych, Rozdział 3 |

### `rules/local_taxes/real_estate.rego` (2 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1310 | `jdg.local_taxes.real_estate.commercial_rate` | 🟡 TRIAGE | Ustawa o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 123... |
| 1312 | `jdg.local_taxes.real_estate.deadline_overdue` | 🟡 TRIAGE | Ustawa o podatkach i opłatach lokalnych, Art. 6 ust. 6-7 |

### `rules/local_taxes/transport.rego` (1 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1320 | `jdg.local_taxes.transport.tax_applicable` | 🟡 TRIAGE | Ustawa o podatkach i opłatach lokalnych, Rozdział 3 (Art. 8-... |

### `rules/mdr/plan44_mdr.rego` (10 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1800 | `jdg.mdr.reportable_scheme_detection` | 🟡 TRIAGE | Art. 86a-86o Ordynacji podatkowej |
| 1801 | `jdg.mdr.promoter_vs_user` | 🟡 TRIAGE | Art. 86a § 1 Ordynacji podatkowej |
| 1802 | `jdg.mdr.deadline_tracking` | 🔴 BLOCK | Art. 86o Ordynacji podatkowej |
| 1803 | `jdg.mdr.hallmark_main_benefit_test` | 🟡 TRIAGE | Art. 86a § 2 Ordynacji podatkowej |
| 1804 | `jdg.mdr.hallmark_category_c` | 🟡 TRIAGE | Art. 86d Ordynacji podatkowej |
| 1805 | `jdg.mdr.hallmark_category_d_tp` | 🟡 TRIAGE | Art. 86e Ordynacji podatkowej |
| 1806 | `jdg.mdr.hallmark_category_e_exchange` | 🟡 TRIAGE | Art. 86f Ordynacji podatkowej |
| 1807 | `jdg.mdr.quarterly_summary_mdr4` |  | Art. 86k Ordynacji podatkowej |
| 1808 | `jdg.mdr.statute_of_limitations` |  | Art. 86m Ordynacji podatkowej |
| 1809 | `jdg.mdr.aggregate_risk_jdg` | 🟡 TRIAGE | Art. 86a-86o Ordynacji podatkowej |

### `rules/mdr/plan45_mdr.rego` (17 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1001 | `jdg.mdr.hyper.hallmark_a1_confidentiality` | 🟡 TRIAGE | Art. 86a § 1 pkt 1 OP |
| 1002 | `jdg.mdr.hyper.hallmark_a2_success_fee` | 🟡 TRIAGE | Art. 86a § 1 pkt 2 OP |
| 1003 | `jdg.mdr.hyper.hallmark_a3_standardized` | 🟡 TRIAGE | Art. 86a § 1 pkt 3 OP |
| 1004 | `jdg.mdr.hyper.hallmark_a4_loss_buying` | 🟡 TRIAGE | Art. 86a § 1 OP |
| 1005 | `jdg.mdr.hyper.hallmark_a5_income_conversion` | 🟡 TRIAGE | Art. 86a OP |
| 1006 | `jdg.mdr.hyper.hallmark_a6_circular` | 🟡 TRIAGE | Art. 86a OP |
| 1010 | `jdg.mdr.hyper.hallmark_a10_main_benefit_test` | 🟡 TRIAGE | Art. 86a § 2 OP |
| 1014 | `jdg.mdr.hyper.hallmark_b4_tax_haven` | 🟡 TRIAGE | Art. 86b OP |
| 1018 | `jdg.mdr.hyper.hallmark_b8_hybrid_mismatch` | 🟡 TRIAGE | Art. 86b OP |
| 1019 | `jdg.mdr.hyper.hallmark_c1_strategic_acquisition` | 🟡 TRIAGE | Art. 86d OP |
| 1021 | `jdg.mdr.hyper.hallmark_c3_circular_roundtrip` | 🟡 TRIAGE | Art. 86d OP |
| 1024 | `jdg.mdr.hyper.hallmark_c6_ip_hard_to_value` | 🟡 TRIAGE | Art. 86d OP |
| 1029 | `jdg.mdr.hyper.hallmark_e1_crs_bypass` | 🟡 TRIAGE | Art. 86f OP |
| 1030 | `jdg.mdr.hyper.hallmark_e2_ubo_concealment` | 🟡 TRIAGE | Art. 86f OP |
| 1039 | `jdg.mdr.hyper.sanction_admin_5m` | 🔴 BLOCK | Art. 86o OP |
| 1040 | `jdg.mdr.hyper.sanction_kks_art54_56` | 🔴 BLOCK | Art. 54-56 KKS |
| 1041 | `jdg.mdr.hyper.retention_6years` |  | Art. 86m OP |

### `rules/micro/akcyza/akcyza.rego` (32 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 250002 | `jdg.micro.akcyza.a2.r1` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250003 | `jdg.micro.akcyza.a2.r2` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250004 | `jdg.micro.akcyza.a2.r3` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250005 | `jdg.micro.akcyza.a2.r4` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250006 | `jdg.micro.akcyza.a2.r5` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250007 | `jdg.micro.akcyza.a2.r6` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250008 | `jdg.micro.akcyza.a2.r7` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250009 | `jdg.micro.akcyza.a2.r8` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250010 | `jdg.micro.akcyza.a26.r1` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250011 | `jdg.micro.akcyza.a26.r2` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250012 | `jdg.micro.akcyza.a26.r3` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250013 | `jdg.micro.akcyza.a26.r4` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250014 | `jdg.micro.akcyza.a26.r5` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250015 | `jdg.micro.akcyza.a26.r6` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250016 | `jdg.micro.akcyza.a26.r7` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250017 | `jdg.micro.akcyza.a26.r8` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250018 | `jdg.micro.akcyza.a30.r1` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250019 | `jdg.micro.akcyza.a30.r2` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250020 | `jdg.micro.akcyza.a30.r3` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250021 | `jdg.micro.akcyza.a30.r4` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250022 | `jdg.micro.akcyza.a30.r5` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250023 | `jdg.micro.akcyza.a30.r6` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250024 | `jdg.micro.akcyza.a30.r7` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250025 | `jdg.micro.akcyza.a30.r8` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250026 | `jdg.micro.akcyza.a99.r1` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250027 | `jdg.micro.akcyza.a99.r2` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250028 | `jdg.micro.akcyza.a99.r3` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250029 | `jdg.micro.akcyza.a99.r4` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250030 | `jdg.micro.akcyza.a99.r5` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250031 | `jdg.micro.akcyza.a99.r6` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250032 | `jdg.micro.akcyza.a99.r7` |  | Ustawa o podatku akcyzowym z 06.12.2008 |
| 250033 | `jdg.micro.akcyza.a99.r8` |  | Ustawa o podatku akcyzowym z 06.12.2008 |

### `rules/micro/aml/aml.rego` (44 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 200008 | `jdg.micro.aml.a8.r1` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200009 | `jdg.micro.aml.a8.r2` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200010 | `jdg.micro.aml.a8.r3` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200011 | `jdg.micro.aml.a8.r4` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200012 | `jdg.micro.aml.a8.r5` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200013 | `jdg.micro.aml.a8.r6` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200014 | `jdg.micro.aml.a8.r7` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200015 | `jdg.micro.aml.a8.r8` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200016 | `jdg.micro.aml.a8.r9` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200017 | `jdg.micro.aml.a8.r10` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200018 | `jdg.micro.aml.a10.r1` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200019 | `jdg.micro.aml.a10.r2` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200020 | `jdg.micro.aml.a10.r3` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200021 | `jdg.micro.aml.a10.r4` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200022 | `jdg.micro.aml.a10.r5` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200023 | `jdg.micro.aml.a10.r6` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200024 | `jdg.micro.aml.a10.r7` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200025 | `jdg.micro.aml.a10.r8` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200026 | `jdg.micro.aml.a10.r9` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200027 | `jdg.micro.aml.a10.r10` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200028 | `jdg.micro.aml.a15.r1` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200029 | `jdg.micro.aml.a15.r2` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200030 | `jdg.micro.aml.a15.r3` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200031 | `jdg.micro.aml.a15.r4` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200032 | `jdg.micro.aml.a15.r5` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200033 | `jdg.micro.aml.a15.r6` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200034 | `jdg.micro.aml.a15.r7` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200035 | `jdg.micro.aml.a15.r8` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200036 | `jdg.micro.aml.a18.r1` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200037 | `jdg.micro.aml.a18.r2` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200038 | `jdg.micro.aml.a18.r3` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200039 | `jdg.micro.aml.a18.r4` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200040 | `jdg.micro.aml.a18.r5` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200041 | `jdg.micro.aml.a18.r6` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200042 | `jdg.micro.aml.a18.r7` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200043 | `jdg.micro.aml.a18.r8` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200044 | `jdg.micro.aml.a22.r1` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200045 | `jdg.micro.aml.a22.r2` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200046 | `jdg.micro.aml.a22.r3` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200047 | `jdg.micro.aml.a22.r4` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200048 | `jdg.micro.aml.a22.r5` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200049 | `jdg.micro.aml.a22.r6` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200050 | `jdg.micro.aml.a22.r7` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |
| 200051 | `jdg.micro.aml.a22.r8` |  | Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723) |

### `rules/micro/ceidg/ceidg.rego` (34 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 140005 | `jdg.micro.ceidg.a5.r1` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140006 | `jdg.micro.ceidg.a5.r2` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140007 | `jdg.micro.ceidg.a5.r3` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140008 | `jdg.micro.ceidg.a5.r4` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140009 | `jdg.micro.ceidg.a5.r5` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140010 | `jdg.micro.ceidg.a5.r6` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140011 | `jdg.micro.ceidg.a5.r7` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140012 | `jdg.micro.ceidg.a5.r8` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140013 | `jdg.micro.ceidg.a12.r1` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140014 | `jdg.micro.ceidg.a12.r2` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140015 | `jdg.micro.ceidg.a12.r3` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140016 | `jdg.micro.ceidg.a12.r4` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140017 | `jdg.micro.ceidg.a12.r5` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140018 | `jdg.micro.ceidg.a12.r6` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140019 | `jdg.micro.ceidg.a12.r7` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140020 | `jdg.micro.ceidg.a12.r8` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140021 | `jdg.micro.ceidg.a15.r1` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140022 | `jdg.micro.ceidg.a15.r2` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140023 | `jdg.micro.ceidg.a15.r3` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140024 | `jdg.micro.ceidg.a15.r4` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140025 | `jdg.micro.ceidg.a15.r5` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140026 | `jdg.micro.ceidg.a15.r6` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140027 | `jdg.micro.ceidg.a22.r1` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140028 | `jdg.micro.ceidg.a22.r2` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140029 | `jdg.micro.ceidg.a22.r3` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140030 | `jdg.micro.ceidg.a22.r4` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140031 | `jdg.micro.ceidg.a22.r5` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140032 | `jdg.micro.ceidg.a22.r6` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140033 | `jdg.micro.ceidg.a25.r1` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140034 | `jdg.micro.ceidg.a25.r2` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140035 | `jdg.micro.ceidg.a25.r3` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140036 | `jdg.micro.ceidg.a25.r4` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140037 | `jdg.micro.ceidg.a25.r5` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |
| 140038 | `jdg.micro.ceidg.a25.r6` |  | Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647) |

### `rules/micro/crossborder/crossborder.rego` (72 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 230023 | `jdg.micro.crossborder.a23o.r1` |  | Dyrektywy UE, UPO, TP, CFC |
| 230024 | `jdg.micro.crossborder.a23o.r2` |  | Dyrektywy UE, UPO, TP, CFC |
| 230025 | `jdg.micro.crossborder.a23o.r3` |  | Dyrektywy UE, UPO, TP, CFC |
| 230026 | `jdg.micro.crossborder.a23o.r4` |  | Dyrektywy UE, UPO, TP, CFC |
| 230027 | `jdg.micro.crossborder.a23o.r5` |  | Dyrektywy UE, UPO, TP, CFC |
| 230028 | `jdg.micro.crossborder.a23o.r6` |  | Dyrektywy UE, UPO, TP, CFC |
| 230029 | `jdg.micro.crossborder.a23o.r7` |  | Dyrektywy UE, UPO, TP, CFC |
| 230030 | `jdg.micro.crossborder.a23o.r8` |  | Dyrektywy UE, UPO, TP, CFC |
| 230031 | `jdg.micro.crossborder.a23o.r9` |  | Dyrektywy UE, UPO, TP, CFC |
| 230032 | `jdg.micro.crossborder.a23o.r10` |  | Dyrektywy UE, UPO, TP, CFC |
| 230033 | `jdg.micro.crossborder.a23zf.r1` |  | Dyrektywy UE, UPO, TP, CFC |
| 230034 | `jdg.micro.crossborder.a23zf.r2` |  | Dyrektywy UE, UPO, TP, CFC |
| 230035 | `jdg.micro.crossborder.a23zf.r3` |  | Dyrektywy UE, UPO, TP, CFC |
| 230036 | `jdg.micro.crossborder.a23zf.r4` |  | Dyrektywy UE, UPO, TP, CFC |
| 230037 | `jdg.micro.crossborder.a23zf.r5` |  | Dyrektywy UE, UPO, TP, CFC |
| 230038 | `jdg.micro.crossborder.a23zf.r6` |  | Dyrektywy UE, UPO, TP, CFC |
| 230039 | `jdg.micro.crossborder.a23zf.r7` |  | Dyrektywy UE, UPO, TP, CFC |
| 230040 | `jdg.micro.crossborder.a23zf.r8` |  | Dyrektywy UE, UPO, TP, CFC |
| 230041 | `jdg.micro.crossborder.a30da.r1` |  | Dyrektywy UE, UPO, TP, CFC |
| 230042 | `jdg.micro.crossborder.a30da.r2` |  | Dyrektywy UE, UPO, TP, CFC |
| 230043 | `jdg.micro.crossborder.a30da.r3` |  | Dyrektywy UE, UPO, TP, CFC |
| 230044 | `jdg.micro.crossborder.a30da.r4` |  | Dyrektywy UE, UPO, TP, CFC |
| 230045 | `jdg.micro.crossborder.a30da.r5` |  | Dyrektywy UE, UPO, TP, CFC |
| 230046 | `jdg.micro.crossborder.a30da.r6` |  | Dyrektywy UE, UPO, TP, CFC |
| 230047 | `jdg.micro.crossborder.a30da.r7` |  | Dyrektywy UE, UPO, TP, CFC |
| 230048 | `jdg.micro.crossborder.a30da.r8` |  | Dyrektywy UE, UPO, TP, CFC |
| 230049 | `jdg.micro.crossborder.a30da.r9` |  | Dyrektywy UE, UPO, TP, CFC |
| 230050 | `jdg.micro.crossborder.a30da.r10` |  | Dyrektywy UE, UPO, TP, CFC |
| 230051 | `jdg.micro.crossborder.a30f.r1` |  | Dyrektywy UE, UPO, TP, CFC |
| 230052 | `jdg.micro.crossborder.a30f.r2` |  | Dyrektywy UE, UPO, TP, CFC |
| 230053 | `jdg.micro.crossborder.a30f.r3` |  | Dyrektywy UE, UPO, TP, CFC |
| 230054 | `jdg.micro.crossborder.a30f.r4` |  | Dyrektywy UE, UPO, TP, CFC |
| 230055 | `jdg.micro.crossborder.a30f.r5` |  | Dyrektywy UE, UPO, TP, CFC |
| 230056 | `jdg.micro.crossborder.a30f.r6` |  | Dyrektywy UE, UPO, TP, CFC |
| 230057 | `jdg.micro.crossborder.a30f.r7` |  | Dyrektywy UE, UPO, TP, CFC |
| 230058 | `jdg.micro.crossborder.a30f.r8` |  | Dyrektywy UE, UPO, TP, CFC |
| 230059 | `jdg.micro.crossborder.a30f2.r1` |  | Dyrektywy UE, UPO, TP, CFC |
| 230060 | `jdg.micro.crossborder.a30f2.r2` |  | Dyrektywy UE, UPO, TP, CFC |
| 230061 | `jdg.micro.crossborder.a30f2.r3` |  | Dyrektywy UE, UPO, TP, CFC |
| 230062 | `jdg.micro.crossborder.a30f2.r4` |  | Dyrektywy UE, UPO, TP, CFC |
| 230063 | `jdg.micro.crossborder.a30f2.r5` |  | Dyrektywy UE, UPO, TP, CFC |
| 230064 | `jdg.micro.crossborder.a30f2.r6` |  | Dyrektywy UE, UPO, TP, CFC |
| 230065 | `jdg.micro.crossborder.a30f2.r7` |  | Dyrektywy UE, UPO, TP, CFC |
| 230066 | `jdg.micro.crossborder.a30f2.r8` |  | Dyrektywy UE, UPO, TP, CFC |
| 230067 | `jdg.micro.crossborder.a29.r1` |  | Dyrektywy UE, UPO, TP, CFC |
| 230068 | `jdg.micro.crossborder.a29.r2` |  | Dyrektywy UE, UPO, TP, CFC |
| 230069 | `jdg.micro.crossborder.a29.r3` |  | Dyrektywy UE, UPO, TP, CFC |
| 230070 | `jdg.micro.crossborder.a29.r4` |  | Dyrektywy UE, UPO, TP, CFC |
| 230071 | `jdg.micro.crossborder.a29.r5` |  | Dyrektywy UE, UPO, TP, CFC |
| 230072 | `jdg.micro.crossborder.a29.r6` |  | Dyrektywy UE, UPO, TP, CFC |
| 230073 | `jdg.micro.crossborder.a29.r7` |  | Dyrektywy UE, UPO, TP, CFC |
| 230074 | `jdg.micro.crossborder.a29.r8` |  | Dyrektywy UE, UPO, TP, CFC |
| 230075 | `jdg.micro.crossborder.a29.r9` |  | Dyrektywy UE, UPO, TP, CFC |
| 230076 | `jdg.micro.crossborder.a29.r10` |  | Dyrektywy UE, UPO, TP, CFC |
| 230077 | `jdg.micro.crossborder.a86r.r1` |  | Dyrektywy UE, UPO, TP, CFC |
| 230078 | `jdg.micro.crossborder.a86r.r2` |  | Dyrektywy UE, UPO, TP, CFC |
| 230079 | `jdg.micro.crossborder.a86r.r3` |  | Dyrektywy UE, UPO, TP, CFC |
| 230080 | `jdg.micro.crossborder.a86r.r4` |  | Dyrektywy UE, UPO, TP, CFC |
| 230081 | `jdg.micro.crossborder.a86r.r5` |  | Dyrektywy UE, UPO, TP, CFC |
| 230082 | `jdg.micro.crossborder.a86r.r6` |  | Dyrektywy UE, UPO, TP, CFC |
| 230083 | `jdg.micro.crossborder.a86r.r7` |  | Dyrektywy UE, UPO, TP, CFC |
| 230084 | `jdg.micro.crossborder.a86r.r8` |  | Dyrektywy UE, UPO, TP, CFC |
| 230085 | `jdg.micro.crossborder.a86r.r9` |  | Dyrektywy UE, UPO, TP, CFC |
| 230086 | `jdg.micro.crossborder.a86r.r10` |  | Dyrektywy UE, UPO, TP, CFC |
| 230087 | `jdg.micro.crossborder.a20.r1` |  | Dyrektywy UE, UPO, TP, CFC |
| 230088 | `jdg.micro.crossborder.a20.r2` |  | Dyrektywy UE, UPO, TP, CFC |
| 230089 | `jdg.micro.crossborder.a20.r3` |  | Dyrektywy UE, UPO, TP, CFC |
| 230090 | `jdg.micro.crossborder.a20.r4` |  | Dyrektywy UE, UPO, TP, CFC |
| 230091 | `jdg.micro.crossborder.a20.r5` |  | Dyrektywy UE, UPO, TP, CFC |
| 230092 | `jdg.micro.crossborder.a20.r6` |  | Dyrektywy UE, UPO, TP, CFC |
| 230093 | `jdg.micro.crossborder.a20.r7` |  | Dyrektywy UE, UPO, TP, CFC |
| 230094 | `jdg.micro.crossborder.a20.r8` |  | Dyrektywy UE, UPO, TP, CFC |

### `rules/micro/jpk/jpk.rego` (35 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 190099 | `jdg.micro.jpk.a99.r1` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190100 | `jdg.micro.jpk.a99.r2` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190101 | `jdg.micro.jpk.a99.r3` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190102 | `jdg.micro.jpk.a99.r4` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190103 | `jdg.micro.jpk.a99.r5` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190104 | `jdg.micro.jpk.a99.r6` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190105 | `jdg.micro.jpk.a99.r7` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190106 | `jdg.micro.jpk.a99.r8` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190107 | `jdg.micro.jpk.a99.r9` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190108 | `jdg.micro.jpk.a99.r10` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190109 | `jdg.micro.jpk.a99.r11` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190110 | `jdg.micro.jpk.a99.r12` | 🔴 BLOCK | Rozporządzenie MF w sprawie JPK_VAT |
| 190111 | `jdg.micro.jpk.a99.r13` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190112 | `jdg.micro.jpk.a99.r14` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190113 | `jdg.micro.jpk.a99.r15` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190114 | `jdg.micro.jpk.a99b.r1` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190115 | `jdg.micro.jpk.a99b.r2` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190116 | `jdg.micro.jpk.a99b.r3` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190117 | `jdg.micro.jpk.a99b.r4` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190118 | `jdg.micro.jpk.a99b.r5` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190119 | `jdg.micro.jpk.a99b.r6` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190120 | `jdg.micro.jpk.a99b.r7` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190121 | `jdg.micro.jpk.a99b.r8` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190122 | `jdg.micro.jpk.a99b.r9` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190123 | `jdg.micro.jpk.a99b.r10` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190124 | `jdg.micro.jpk.a193a.r1` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190125 | `jdg.micro.jpk.a193a.r2` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190126 | `jdg.micro.jpk.a193a.r3` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190127 | `jdg.micro.jpk.a193a.r4` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190128 | `jdg.micro.jpk.a193a.r5` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190129 | `jdg.micro.jpk.a193a.r6` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190130 | `jdg.micro.jpk.a193a.r7` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190131 | `jdg.micro.jpk.a193a.r8` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190132 | `jdg.micro.jpk.a193a.r9` |  | Rozporządzenie MF w sprawie JPK_VAT |
| 190133 | `jdg.micro.jpk.a193a.r10` |  | Rozporządzenie MF w sprawie JPK_VAT |

### `rules/micro/kks/kks.rego` (375 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 80016 | `jdg.micro.kks.a16.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80017 | `jdg.micro.kks.a16.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80018 | `jdg.micro.kks.a16.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80019 | `jdg.micro.kks.a16.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80020 | `jdg.micro.kks.a16.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80021 | `jdg.micro.kks.a16.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80022 | `jdg.micro.kks.a16.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80023 | `jdg.micro.kks.a16.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80024 | `jdg.micro.kks.a16.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80025 | `jdg.micro.kks.a16.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80026 | `jdg.micro.kks.a16.r11` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80027 | `jdg.micro.kks.a16.r12` | 🔴 BLOCK | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80028 | `jdg.micro.kks.a20.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80029 | `jdg.micro.kks.a20.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80030 | `jdg.micro.kks.a20.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80031 | `jdg.micro.kks.a20.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80032 | `jdg.micro.kks.a20.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80033 | `jdg.micro.kks.a20.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80034 | `jdg.micro.kks.a20.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80035 | `jdg.micro.kks.a20.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80036 | `jdg.micro.kks.a21.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80037 | `jdg.micro.kks.a21.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80038 | `jdg.micro.kks.a21.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80039 | `jdg.micro.kks.a21.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80040 | `jdg.micro.kks.a21.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80041 | `jdg.micro.kks.a21.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80042 | `jdg.micro.kks.a21.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80043 | `jdg.micro.kks.a21.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80044 | `jdg.micro.kks.a54.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80045 | `jdg.micro.kks.a54.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80046 | `jdg.micro.kks.a54.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80047 | `jdg.micro.kks.a54.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80048 | `jdg.micro.kks.a54.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80049 | `jdg.micro.kks.a54.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80050 | `jdg.micro.kks.a54.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80051 | `jdg.micro.kks.a54.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80052 | `jdg.micro.kks.a54.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80053 | `jdg.micro.kks.a54.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80054 | `jdg.micro.kks.a54.r11` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80055 | `jdg.micro.kks.a54.r12` | 🔴 BLOCK | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80056 | `jdg.micro.kks.a54.r13` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80057 | `jdg.micro.kks.a54.r14` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80058 | `jdg.micro.kks.a54.r15` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80059 | `jdg.micro.kks.a55.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80060 | `jdg.micro.kks.a55.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80061 | `jdg.micro.kks.a55.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80062 | `jdg.micro.kks.a55.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80063 | `jdg.micro.kks.a55.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80064 | `jdg.micro.kks.a55.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80065 | `jdg.micro.kks.a55.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80066 | `jdg.micro.kks.a55.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80067 | `jdg.micro.kks.a55.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80068 | `jdg.micro.kks.a55.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80069 | `jdg.micro.kks.a55.r11` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80070 | `jdg.micro.kks.a55.r12` | 🔴 BLOCK | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80071 | `jdg.micro.kks.a56.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80072 | `jdg.micro.kks.a56.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80073 | `jdg.micro.kks.a56.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80074 | `jdg.micro.kks.a56.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80075 | `jdg.micro.kks.a56.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80076 | `jdg.micro.kks.a56.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80077 | `jdg.micro.kks.a56.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80078 | `jdg.micro.kks.a56.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80079 | `jdg.micro.kks.a56.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80080 | `jdg.micro.kks.a56.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80081 | `jdg.micro.kks.a56.r11` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80082 | `jdg.micro.kks.a56.r12` | 🔴 BLOCK | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80083 | `jdg.micro.kks.a56.r13` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80084 | `jdg.micro.kks.a56.r14` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80085 | `jdg.micro.kks.a56.r15` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80086 | `jdg.micro.kks.a57.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80087 | `jdg.micro.kks.a57.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80088 | `jdg.micro.kks.a57.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80089 | `jdg.micro.kks.a57.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80090 | `jdg.micro.kks.a57.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80091 | `jdg.micro.kks.a57.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80092 | `jdg.micro.kks.a57.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80093 | `jdg.micro.kks.a57.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80094 | `jdg.micro.kks.a57.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80095 | `jdg.micro.kks.a57.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80096 | `jdg.micro.kks.a57.r11` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80097 | `jdg.micro.kks.a57.r12` | 🔴 BLOCK | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80098 | `jdg.micro.kks.a58.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80099 | `jdg.micro.kks.a58.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80100 | `jdg.micro.kks.a58.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80101 | `jdg.micro.kks.a58.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80102 | `jdg.micro.kks.a58.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80103 | `jdg.micro.kks.a58.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80104 | `jdg.micro.kks.a58.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80105 | `jdg.micro.kks.a58.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80106 | `jdg.micro.kks.a58.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80107 | `jdg.micro.kks.a58.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80108 | `jdg.micro.kks.a59.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80109 | `jdg.micro.kks.a59.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80110 | `jdg.micro.kks.a59.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80111 | `jdg.micro.kks.a59.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80112 | `jdg.micro.kks.a59.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80113 | `jdg.micro.kks.a59.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80114 | `jdg.micro.kks.a59.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80115 | `jdg.micro.kks.a59.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80116 | `jdg.micro.kks.a59.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80117 | `jdg.micro.kks.a59.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80118 | `jdg.micro.kks.a60.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80119 | `jdg.micro.kks.a60.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80120 | `jdg.micro.kks.a60.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80121 | `jdg.micro.kks.a60.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80122 | `jdg.micro.kks.a60.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80123 | `jdg.micro.kks.a60.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80124 | `jdg.micro.kks.a60.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80125 | `jdg.micro.kks.a60.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80126 | `jdg.micro.kks.a60.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80127 | `jdg.micro.kks.a60.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80128 | `jdg.micro.kks.a61.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80129 | `jdg.micro.kks.a61.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80130 | `jdg.micro.kks.a61.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80131 | `jdg.micro.kks.a61.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80132 | `jdg.micro.kks.a61.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80133 | `jdg.micro.kks.a61.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80134 | `jdg.micro.kks.a61.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80135 | `jdg.micro.kks.a61.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80136 | `jdg.micro.kks.a61.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80137 | `jdg.micro.kks.a61.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80138 | `jdg.micro.kks.a62.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80139 | `jdg.micro.kks.a62.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80140 | `jdg.micro.kks.a62.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80141 | `jdg.micro.kks.a62.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80142 | `jdg.micro.kks.a62.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80143 | `jdg.micro.kks.a62.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80144 | `jdg.micro.kks.a62.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80145 | `jdg.micro.kks.a62.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80146 | `jdg.micro.kks.a62.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80147 | `jdg.micro.kks.a62.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80148 | `jdg.micro.kks.a62.r11` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80149 | `jdg.micro.kks.a62.r12` | 🔴 BLOCK | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80150 | `jdg.micro.kks.a62.r13` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80151 | `jdg.micro.kks.a62.r14` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80152 | `jdg.micro.kks.a62.r15` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80153 | `jdg.micro.kks.a63.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80154 | `jdg.micro.kks.a63.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80155 | `jdg.micro.kks.a63.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80156 | `jdg.micro.kks.a63.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80157 | `jdg.micro.kks.a63.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80158 | `jdg.micro.kks.a63.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80159 | `jdg.micro.kks.a63.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80160 | `jdg.micro.kks.a63.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80161 | `jdg.micro.kks.a63.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80162 | `jdg.micro.kks.a63.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80163 | `jdg.micro.kks.a64.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80164 | `jdg.micro.kks.a64.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80165 | `jdg.micro.kks.a64.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80166 | `jdg.micro.kks.a64.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80167 | `jdg.micro.kks.a64.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80168 | `jdg.micro.kks.a64.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80169 | `jdg.micro.kks.a64.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80170 | `jdg.micro.kks.a64.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80171 | `jdg.micro.kks.a64.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80172 | `jdg.micro.kks.a64.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80173 | `jdg.micro.kks.a65.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80174 | `jdg.micro.kks.a65.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80175 | `jdg.micro.kks.a65.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80176 | `jdg.micro.kks.a65.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80177 | `jdg.micro.kks.a65.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80178 | `jdg.micro.kks.a65.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80179 | `jdg.micro.kks.a65.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80180 | `jdg.micro.kks.a65.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80181 | `jdg.micro.kks.a65.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80182 | `jdg.micro.kks.a65.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80183 | `jdg.micro.kks.a66.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80184 | `jdg.micro.kks.a66.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80185 | `jdg.micro.kks.a66.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80186 | `jdg.micro.kks.a66.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80187 | `jdg.micro.kks.a66.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80188 | `jdg.micro.kks.a66.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80189 | `jdg.micro.kks.a66.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80190 | `jdg.micro.kks.a66.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80191 | `jdg.micro.kks.a66.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80192 | `jdg.micro.kks.a66.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80193 | `jdg.micro.kks.a67.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80194 | `jdg.micro.kks.a67.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80195 | `jdg.micro.kks.a67.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80196 | `jdg.micro.kks.a67.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80197 | `jdg.micro.kks.a67.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80198 | `jdg.micro.kks.a67.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80199 | `jdg.micro.kks.a67.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80200 | `jdg.micro.kks.a67.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80201 | `jdg.micro.kks.a67.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80202 | `jdg.micro.kks.a67.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80203 | `jdg.micro.kks.a68.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80204 | `jdg.micro.kks.a68.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80205 | `jdg.micro.kks.a68.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80206 | `jdg.micro.kks.a68.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80207 | `jdg.micro.kks.a68.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80208 | `jdg.micro.kks.a68.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80209 | `jdg.micro.kks.a68.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80210 | `jdg.micro.kks.a68.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80211 | `jdg.micro.kks.a68.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80212 | `jdg.micro.kks.a68.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80213 | `jdg.micro.kks.a69.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80214 | `jdg.micro.kks.a69.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80215 | `jdg.micro.kks.a69.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80216 | `jdg.micro.kks.a69.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80217 | `jdg.micro.kks.a69.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80218 | `jdg.micro.kks.a69.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80219 | `jdg.micro.kks.a69.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80220 | `jdg.micro.kks.a69.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80221 | `jdg.micro.kks.a69.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80222 | `jdg.micro.kks.a69.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80223 | `jdg.micro.kks.a70.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80224 | `jdg.micro.kks.a70.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80225 | `jdg.micro.kks.a70.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80226 | `jdg.micro.kks.a70.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80227 | `jdg.micro.kks.a70.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80228 | `jdg.micro.kks.a70.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80229 | `jdg.micro.kks.a70.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80230 | `jdg.micro.kks.a70.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80231 | `jdg.micro.kks.a70.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80232 | `jdg.micro.kks.a70.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80233 | `jdg.micro.kks.a71.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80234 | `jdg.micro.kks.a71.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80235 | `jdg.micro.kks.a71.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80236 | `jdg.micro.kks.a71.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80237 | `jdg.micro.kks.a71.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80238 | `jdg.micro.kks.a71.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80239 | `jdg.micro.kks.a71.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80240 | `jdg.micro.kks.a71.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80241 | `jdg.micro.kks.a71.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80242 | `jdg.micro.kks.a71.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80243 | `jdg.micro.kks.a72.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80244 | `jdg.micro.kks.a72.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80245 | `jdg.micro.kks.a72.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80246 | `jdg.micro.kks.a72.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80247 | `jdg.micro.kks.a72.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80248 | `jdg.micro.kks.a72.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80249 | `jdg.micro.kks.a72.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80250 | `jdg.micro.kks.a72.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80251 | `jdg.micro.kks.a72.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80252 | `jdg.micro.kks.a72.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80253 | `jdg.micro.kks.a73.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80254 | `jdg.micro.kks.a73.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80255 | `jdg.micro.kks.a73.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80256 | `jdg.micro.kks.a73.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80257 | `jdg.micro.kks.a73.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80258 | `jdg.micro.kks.a73.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80259 | `jdg.micro.kks.a73.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80260 | `jdg.micro.kks.a73.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80261 | `jdg.micro.kks.a73.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80262 | `jdg.micro.kks.a73.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80263 | `jdg.micro.kks.a74.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80264 | `jdg.micro.kks.a74.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80265 | `jdg.micro.kks.a74.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80266 | `jdg.micro.kks.a74.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80267 | `jdg.micro.kks.a74.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80268 | `jdg.micro.kks.a74.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80269 | `jdg.micro.kks.a74.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80270 | `jdg.micro.kks.a74.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80271 | `jdg.micro.kks.a74.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80272 | `jdg.micro.kks.a74.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80273 | `jdg.micro.kks.a75.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80274 | `jdg.micro.kks.a75.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80275 | `jdg.micro.kks.a75.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80276 | `jdg.micro.kks.a75.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80277 | `jdg.micro.kks.a75.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80278 | `jdg.micro.kks.a75.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80279 | `jdg.micro.kks.a75.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80280 | `jdg.micro.kks.a75.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80281 | `jdg.micro.kks.a75.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80282 | `jdg.micro.kks.a75.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80283 | `jdg.micro.kks.a76.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80284 | `jdg.micro.kks.a76.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80285 | `jdg.micro.kks.a76.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80286 | `jdg.micro.kks.a76.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80287 | `jdg.micro.kks.a76.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80288 | `jdg.micro.kks.a76.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80289 | `jdg.micro.kks.a76.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80290 | `jdg.micro.kks.a76.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80291 | `jdg.micro.kks.a76.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80292 | `jdg.micro.kks.a76.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80293 | `jdg.micro.kks.a77.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80294 | `jdg.micro.kks.a77.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80295 | `jdg.micro.kks.a77.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80296 | `jdg.micro.kks.a77.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80297 | `jdg.micro.kks.a77.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80298 | `jdg.micro.kks.a77.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80299 | `jdg.micro.kks.a77.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80300 | `jdg.micro.kks.a77.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80301 | `jdg.micro.kks.a77.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80302 | `jdg.micro.kks.a77.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80303 | `jdg.micro.kks.a77.r11` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80304 | `jdg.micro.kks.a77.r12` | 🔴 BLOCK | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80305 | `jdg.micro.kks.a78.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80306 | `jdg.micro.kks.a78.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80307 | `jdg.micro.kks.a78.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80308 | `jdg.micro.kks.a78.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80309 | `jdg.micro.kks.a78.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80310 | `jdg.micro.kks.a78.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80311 | `jdg.micro.kks.a78.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80312 | `jdg.micro.kks.a78.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80313 | `jdg.micro.kks.a78.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80314 | `jdg.micro.kks.a78.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80315 | `jdg.micro.kks.a79.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80316 | `jdg.micro.kks.a79.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80317 | `jdg.micro.kks.a79.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80318 | `jdg.micro.kks.a79.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80319 | `jdg.micro.kks.a79.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80320 | `jdg.micro.kks.a79.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80321 | `jdg.micro.kks.a79.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80322 | `jdg.micro.kks.a79.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80323 | `jdg.micro.kks.a79.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80324 | `jdg.micro.kks.a79.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80325 | `jdg.micro.kks.a80.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80326 | `jdg.micro.kks.a80.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80327 | `jdg.micro.kks.a80.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80328 | `jdg.micro.kks.a80.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80329 | `jdg.micro.kks.a80.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80330 | `jdg.micro.kks.a80.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80331 | `jdg.micro.kks.a80.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80332 | `jdg.micro.kks.a80.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80333 | `jdg.micro.kks.a80.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80334 | `jdg.micro.kks.a80.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80335 | `jdg.micro.kks.a80.r11` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80336 | `jdg.micro.kks.a80.r12` | 🔴 BLOCK | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80337 | `jdg.micro.kks.a81.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80338 | `jdg.micro.kks.a81.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80339 | `jdg.micro.kks.a81.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80340 | `jdg.micro.kks.a81.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80341 | `jdg.micro.kks.a81.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80342 | `jdg.micro.kks.a81.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80343 | `jdg.micro.kks.a81.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80344 | `jdg.micro.kks.a81.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80345 | `jdg.micro.kks.a81.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80346 | `jdg.micro.kks.a81.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80347 | `jdg.micro.kks.a82.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80348 | `jdg.micro.kks.a82.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80349 | `jdg.micro.kks.a82.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80350 | `jdg.micro.kks.a82.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80351 | `jdg.micro.kks.a82.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80352 | `jdg.micro.kks.a82.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80353 | `jdg.micro.kks.a82.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80354 | `jdg.micro.kks.a82.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80355 | `jdg.micro.kks.a82.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80356 | `jdg.micro.kks.a82.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80357 | `jdg.micro.kks.a83.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80358 | `jdg.micro.kks.a83.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80359 | `jdg.micro.kks.a83.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80360 | `jdg.micro.kks.a83.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80361 | `jdg.micro.kks.a83.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80362 | `jdg.micro.kks.a83.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80363 | `jdg.micro.kks.a83.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80364 | `jdg.micro.kks.a83.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80365 | `jdg.micro.kks.a83.r9` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80366 | `jdg.micro.kks.a83.r10` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80367 | `jdg.micro.kks.a85.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80368 | `jdg.micro.kks.a85.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80369 | `jdg.micro.kks.a85.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80370 | `jdg.micro.kks.a85.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80371 | `jdg.micro.kks.a85.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80372 | `jdg.micro.kks.a85.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80373 | `jdg.micro.kks.a85.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80374 | `jdg.micro.kks.a85.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80375 | `jdg.micro.kks.a86.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80376 | `jdg.micro.kks.a86.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80377 | `jdg.micro.kks.a86.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80378 | `jdg.micro.kks.a86.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80379 | `jdg.micro.kks.a86.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80380 | `jdg.micro.kks.a86.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80381 | `jdg.micro.kks.a86.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80382 | `jdg.micro.kks.a86.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80383 | `jdg.micro.kks.a87.r1` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80384 | `jdg.micro.kks.a87.r2` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80385 | `jdg.micro.kks.a87.r3` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80386 | `jdg.micro.kks.a87.r4` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80387 | `jdg.micro.kks.a87.r5` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80388 | `jdg.micro.kks.a87.r6` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80389 | `jdg.micro.kks.a87.r7` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |
| 80390 | `jdg.micro.kks.a87.r8` |  | Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 93... |

### `rules/micro/ksef/ksef.rego` (79 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 180001 | `jdg.micro.ksef.a106na.r1` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180002 | `jdg.micro.ksef.a106na.r2` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180003 | `jdg.micro.ksef.a106na.r3` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180004 | `jdg.micro.ksef.a106na.r4` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180005 | `jdg.micro.ksef.a106na.r5` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180006 | `jdg.micro.ksef.a106na.r6` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180007 | `jdg.micro.ksef.a106na.r7` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180008 | `jdg.micro.ksef.a106na.r8` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180009 | `jdg.micro.ksef.a106na.r9` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180010 | `jdg.micro.ksef.a106na.r10` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180011 | `jdg.micro.ksef.a106na.r11` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180012 | `jdg.micro.ksef.a106na.r12` | 🔴 BLOCK | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180013 | `jdg.micro.ksef.a106na.r13` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180014 | `jdg.micro.ksef.a106na.r14` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180015 | `jdg.micro.ksef.a106na.r15` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180016 | `jdg.micro.ksef.a106nb.r1` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180017 | `jdg.micro.ksef.a106nb.r2` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180018 | `jdg.micro.ksef.a106nb.r3` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180019 | `jdg.micro.ksef.a106nb.r4` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180020 | `jdg.micro.ksef.a106nb.r5` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180021 | `jdg.micro.ksef.a106nb.r6` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180022 | `jdg.micro.ksef.a106nb.r7` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180023 | `jdg.micro.ksef.a106nb.r8` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180024 | `jdg.micro.ksef.a106nb.r9` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180025 | `jdg.micro.ksef.a106nb.r10` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180026 | `jdg.micro.ksef.a106nb.r11` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180027 | `jdg.micro.ksef.a106nb.r12` | 🔴 BLOCK | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180028 | `jdg.micro.ksef.a106nc.r1` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180029 | `jdg.micro.ksef.a106nc.r2` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180030 | `jdg.micro.ksef.a106nc.r3` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180031 | `jdg.micro.ksef.a106nc.r4` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180032 | `jdg.micro.ksef.a106nc.r5` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180033 | `jdg.micro.ksef.a106nc.r6` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180034 | `jdg.micro.ksef.a106nc.r7` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180035 | `jdg.micro.ksef.a106nc.r8` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180036 | `jdg.micro.ksef.a106nc.r9` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180037 | `jdg.micro.ksef.a106nc.r10` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180038 | `jdg.micro.ksef.a106nd.r1` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180039 | `jdg.micro.ksef.a106nd.r2` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180040 | `jdg.micro.ksef.a106nd.r3` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180041 | `jdg.micro.ksef.a106nd.r4` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180042 | `jdg.micro.ksef.a106nd.r5` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180043 | `jdg.micro.ksef.a106nd.r6` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180044 | `jdg.micro.ksef.a106nd.r7` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180045 | `jdg.micro.ksef.a106nd.r8` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180046 | `jdg.micro.ksef.a106nd.r9` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180047 | `jdg.micro.ksef.a106nd.r10` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180048 | `jdg.micro.ksef.a106ne.r1` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180049 | `jdg.micro.ksef.a106ne.r2` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180050 | `jdg.micro.ksef.a106ne.r3` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180051 | `jdg.micro.ksef.a106ne.r4` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180052 | `jdg.micro.ksef.a106ne.r5` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180053 | `jdg.micro.ksef.a106ne.r6` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180054 | `jdg.micro.ksef.a106ne.r7` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180055 | `jdg.micro.ksef.a106ne.r8` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180056 | `jdg.micro.ksef.a106ne.r9` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180057 | `jdg.micro.ksef.a106ne.r10` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180058 | `jdg.micro.ksef.a106nf.r1` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180059 | `jdg.micro.ksef.a106nf.r2` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180060 | `jdg.micro.ksef.a106nf.r3` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180061 | `jdg.micro.ksef.a106nf.r4` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180062 | `jdg.micro.ksef.a106nf.r5` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180063 | `jdg.micro.ksef.a106nf.r6` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180064 | `jdg.micro.ksef.a106nf.r7` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180065 | `jdg.micro.ksef.a106nf.r8` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180066 | `jdg.micro.ksef.a106ng.r1` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180067 | `jdg.micro.ksef.a106ng.r2` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180068 | `jdg.micro.ksef.a106ng.r3` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180069 | `jdg.micro.ksef.a106ng.r4` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180070 | `jdg.micro.ksef.a106ng.r5` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180071 | `jdg.micro.ksef.a106ng.r6` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180072 | `jdg.micro.ksef.a106nh.r1` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180073 | `jdg.micro.ksef.a106nh.r2` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180074 | `jdg.micro.ksef.a106nh.r3` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180075 | `jdg.micro.ksef.a106nh.r4` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180076 | `jdg.micro.ksef.a106nh.r5` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180077 | `jdg.micro.ksef.a106nh.r6` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180078 | `jdg.micro.ksef.a106nh.r7` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |
| 180079 | `jdg.micro.ksef.a106nh.r8` |  | Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398) |

### `rules/micro/ord/ord.rego` (318 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 70016 | `jdg.micro.ord.a16.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70017 | `jdg.micro.ord.a16.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70018 | `jdg.micro.ord.a16.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70019 | `jdg.micro.ord.a16.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70020 | `jdg.micro.ord.a16.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70021 | `jdg.micro.ord.a16.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70022 | `jdg.micro.ord.a20.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70023 | `jdg.micro.ord.a20.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70024 | `jdg.micro.ord.a20.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70025 | `jdg.micro.ord.a20.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70026 | `jdg.micro.ord.a20.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70027 | `jdg.micro.ord.a21.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70028 | `jdg.micro.ord.a21.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70029 | `jdg.micro.ord.a21.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70030 | `jdg.micro.ord.a21.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70031 | `jdg.micro.ord.a21.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70032 | `jdg.micro.ord.a26.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70033 | `jdg.micro.ord.a26.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70034 | `jdg.micro.ord.a26.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70035 | `jdg.micro.ord.a26.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70036 | `jdg.micro.ord.a26.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70037 | `jdg.micro.ord.a26.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70038 | `jdg.micro.ord.a26.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70039 | `jdg.micro.ord.a26.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70040 | `jdg.micro.ord.a27.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70041 | `jdg.micro.ord.a27.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70042 | `jdg.micro.ord.a27.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70043 | `jdg.micro.ord.a27.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70044 | `jdg.micro.ord.a27.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70045 | `jdg.micro.ord.a27.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70046 | `jdg.micro.ord.a28.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70047 | `jdg.micro.ord.a28.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70048 | `jdg.micro.ord.a28.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70049 | `jdg.micro.ord.a28.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70050 | `jdg.micro.ord.a28.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70051 | `jdg.micro.ord.a29.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70052 | `jdg.micro.ord.a29.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70053 | `jdg.micro.ord.a29.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70054 | `jdg.micro.ord.a29.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70055 | `jdg.micro.ord.a29.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70056 | `jdg.micro.ord.a29.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70057 | `jdg.micro.ord.a29.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70058 | `jdg.micro.ord.a29.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70059 | `jdg.micro.ord.a32.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70060 | `jdg.micro.ord.a32.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70061 | `jdg.micro.ord.a32.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70062 | `jdg.micro.ord.a32.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70063 | `jdg.micro.ord.a32.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70064 | `jdg.micro.ord.a33.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70065 | `jdg.micro.ord.a33.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70066 | `jdg.micro.ord.a33.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70067 | `jdg.micro.ord.a33.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70068 | `jdg.micro.ord.a33.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70069 | `jdg.micro.ord.a33.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70070 | `jdg.micro.ord.a33.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70071 | `jdg.micro.ord.a33.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70072 | `jdg.micro.ord.a47.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70073 | `jdg.micro.ord.a47.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70074 | `jdg.micro.ord.a47.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70075 | `jdg.micro.ord.a47.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70076 | `jdg.micro.ord.a47.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70077 | `jdg.micro.ord.a47.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70078 | `jdg.micro.ord.a47.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70079 | `jdg.micro.ord.a47.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70080 | `jdg.micro.ord.a48.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70081 | `jdg.micro.ord.a48.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70082 | `jdg.micro.ord.a48.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70083 | `jdg.micro.ord.a48.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70084 | `jdg.micro.ord.a48.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70085 | `jdg.micro.ord.a51.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70086 | `jdg.micro.ord.a51.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70087 | `jdg.micro.ord.a51.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70088 | `jdg.micro.ord.a51.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70089 | `jdg.micro.ord.a51.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70090 | `jdg.micro.ord.a52.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70091 | `jdg.micro.ord.a52.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70092 | `jdg.micro.ord.a52.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70093 | `jdg.micro.ord.a52.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70094 | `jdg.micro.ord.a52.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70095 | `jdg.micro.ord.a53.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70096 | `jdg.micro.ord.a53.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70097 | `jdg.micro.ord.a53.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70098 | `jdg.micro.ord.a53.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70099 | `jdg.micro.ord.a53.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70100 | `jdg.micro.ord.a54.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70101 | `jdg.micro.ord.a54.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70102 | `jdg.micro.ord.a54.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70103 | `jdg.micro.ord.a54.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70104 | `jdg.micro.ord.a54.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70105 | `jdg.micro.ord.a56.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70106 | `jdg.micro.ord.a56.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70107 | `jdg.micro.ord.a56.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70108 | `jdg.micro.ord.a56.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70109 | `jdg.micro.ord.a56.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70110 | `jdg.micro.ord.a56b.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70111 | `jdg.micro.ord.a56b.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70112 | `jdg.micro.ord.a56b.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70113 | `jdg.micro.ord.a56b.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70114 | `jdg.micro.ord.a56b.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70115 | `jdg.micro.ord.a67a.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70116 | `jdg.micro.ord.a67a.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70117 | `jdg.micro.ord.a67a.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70118 | `jdg.micro.ord.a67a.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70119 | `jdg.micro.ord.a67a.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70120 | `jdg.micro.ord.a67b.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70121 | `jdg.micro.ord.a67b.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70122 | `jdg.micro.ord.a67b.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70123 | `jdg.micro.ord.a67b.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70124 | `jdg.micro.ord.a67b.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70125 | `jdg.micro.ord.a67b.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70126 | `jdg.micro.ord.a67b.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70127 | `jdg.micro.ord.a67b.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70128 | `jdg.micro.ord.a67c.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70129 | `jdg.micro.ord.a67c.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70130 | `jdg.micro.ord.a67c.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70131 | `jdg.micro.ord.a67c.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70132 | `jdg.micro.ord.a67c.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70133 | `jdg.micro.ord.a67d.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70134 | `jdg.micro.ord.a67d.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70135 | `jdg.micro.ord.a67d.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70136 | `jdg.micro.ord.a67d.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70137 | `jdg.micro.ord.a67d.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70138 | `jdg.micro.ord.a67e.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70139 | `jdg.micro.ord.a67e.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70140 | `jdg.micro.ord.a67e.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70141 | `jdg.micro.ord.a67e.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70142 | `jdg.micro.ord.a67e.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70143 | `jdg.micro.ord.a70.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70144 | `jdg.micro.ord.a70.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70145 | `jdg.micro.ord.a70.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70146 | `jdg.micro.ord.a70.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70147 | `jdg.micro.ord.a70.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70148 | `jdg.micro.ord.a70.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70149 | `jdg.micro.ord.a70.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70150 | `jdg.micro.ord.a70.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70151 | `jdg.micro.ord.a70.r9` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70152 | `jdg.micro.ord.a70.r10` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70153 | `jdg.micro.ord.a70.r11` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70154 | `jdg.micro.ord.a70.r12` | 🔴 BLOCK | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70155 | `jdg.micro.ord.a70.r13` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70156 | `jdg.micro.ord.a70.r14` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70157 | `jdg.micro.ord.a70.r15` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70158 | `jdg.micro.ord.a71.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70159 | `jdg.micro.ord.a71.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70160 | `jdg.micro.ord.a71.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70161 | `jdg.micro.ord.a71.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70162 | `jdg.micro.ord.a71.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70163 | `jdg.micro.ord.a71.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70164 | `jdg.micro.ord.a71.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70165 | `jdg.micro.ord.a71.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70166 | `jdg.micro.ord.a71.r9` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70167 | `jdg.micro.ord.a71.r10` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70168 | `jdg.micro.ord.a72.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70169 | `jdg.micro.ord.a72.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70170 | `jdg.micro.ord.a72.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70171 | `jdg.micro.ord.a72.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70172 | `jdg.micro.ord.a72.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70173 | `jdg.micro.ord.a72.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70174 | `jdg.micro.ord.a72.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70175 | `jdg.micro.ord.a72.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70176 | `jdg.micro.ord.a73.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70177 | `jdg.micro.ord.a73.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70178 | `jdg.micro.ord.a73.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70179 | `jdg.micro.ord.a73.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70180 | `jdg.micro.ord.a73.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70181 | `jdg.micro.ord.a74.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70182 | `jdg.micro.ord.a74.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70183 | `jdg.micro.ord.a74.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70184 | `jdg.micro.ord.a74.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70185 | `jdg.micro.ord.a74.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70186 | `jdg.micro.ord.a75.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70187 | `jdg.micro.ord.a75.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70188 | `jdg.micro.ord.a75.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70189 | `jdg.micro.ord.a75.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70190 | `jdg.micro.ord.a75.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70191 | `jdg.micro.ord.a76.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70192 | `jdg.micro.ord.a76.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70193 | `jdg.micro.ord.a76.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70194 | `jdg.micro.ord.a76.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70195 | `jdg.micro.ord.a76.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70196 | `jdg.micro.ord.a77.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70197 | `jdg.micro.ord.a77.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70198 | `jdg.micro.ord.a77.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70199 | `jdg.micro.ord.a77.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70200 | `jdg.micro.ord.a77.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70201 | `jdg.micro.ord.a78.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70202 | `jdg.micro.ord.a78.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70203 | `jdg.micro.ord.a78.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70204 | `jdg.micro.ord.a78.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70205 | `jdg.micro.ord.a78.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70206 | `jdg.micro.ord.a79.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70207 | `jdg.micro.ord.a79.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70208 | `jdg.micro.ord.a79.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70209 | `jdg.micro.ord.a79.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70210 | `jdg.micro.ord.a79.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70211 | `jdg.micro.ord.a80.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70212 | `jdg.micro.ord.a80.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70213 | `jdg.micro.ord.a80.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70214 | `jdg.micro.ord.a80.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70215 | `jdg.micro.ord.a80.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70216 | `jdg.micro.ord.a81.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70217 | `jdg.micro.ord.a81.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70218 | `jdg.micro.ord.a81.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70219 | `jdg.micro.ord.a81.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70220 | `jdg.micro.ord.a81.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70221 | `jdg.micro.ord.a81.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70222 | `jdg.micro.ord.a81.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70223 | `jdg.micro.ord.a81.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70224 | `jdg.micro.ord.a81.r9` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70225 | `jdg.micro.ord.a81.r10` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70226 | `jdg.micro.ord.a81b.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70227 | `jdg.micro.ord.a81b.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70228 | `jdg.micro.ord.a81b.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70229 | `jdg.micro.ord.a81b.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70230 | `jdg.micro.ord.a81b.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70231 | `jdg.micro.ord.a86.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70232 | `jdg.micro.ord.a86.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70233 | `jdg.micro.ord.a86.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70234 | `jdg.micro.ord.a86.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70235 | `jdg.micro.ord.a86.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70236 | `jdg.micro.ord.a86.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70237 | `jdg.micro.ord.a86.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70238 | `jdg.micro.ord.a86.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70239 | `jdg.micro.ord.a87.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70240 | `jdg.micro.ord.a87.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70241 | `jdg.micro.ord.a87.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70242 | `jdg.micro.ord.a87.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70243 | `jdg.micro.ord.a87.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70244 | `jdg.micro.ord.a119a.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70245 | `jdg.micro.ord.a119a.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70246 | `jdg.micro.ord.a119a.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70247 | `jdg.micro.ord.a119a.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70248 | `jdg.micro.ord.a119a.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70249 | `jdg.micro.ord.a119a.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70250 | `jdg.micro.ord.a119a.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70251 | `jdg.micro.ord.a119a.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70252 | `jdg.micro.ord.a119a.r9` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70253 | `jdg.micro.ord.a119a.r10` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70254 | `jdg.micro.ord.a120.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70255 | `jdg.micro.ord.a120.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70256 | `jdg.micro.ord.a120.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70257 | `jdg.micro.ord.a120.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70258 | `jdg.micro.ord.a120.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70259 | `jdg.micro.ord.a121.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70260 | `jdg.micro.ord.a121.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70261 | `jdg.micro.ord.a121.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70262 | `jdg.micro.ord.a121.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70263 | `jdg.micro.ord.a121.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70264 | `jdg.micro.ord.a122.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70265 | `jdg.micro.ord.a122.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70266 | `jdg.micro.ord.a122.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70267 | `jdg.micro.ord.a122.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70268 | `jdg.micro.ord.a122.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70269 | `jdg.micro.ord.a123.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70270 | `jdg.micro.ord.a123.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70271 | `jdg.micro.ord.a123.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70272 | `jdg.micro.ord.a123.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70273 | `jdg.micro.ord.a123.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70274 | `jdg.micro.ord.a124.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70275 | `jdg.micro.ord.a124.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70276 | `jdg.micro.ord.a124.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70277 | `jdg.micro.ord.a124.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70278 | `jdg.micro.ord.a124.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70279 | `jdg.micro.ord.a125.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70280 | `jdg.micro.ord.a125.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70281 | `jdg.micro.ord.a125.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70282 | `jdg.micro.ord.a125.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70283 | `jdg.micro.ord.a125.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70284 | `jdg.micro.ord.a126.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70285 | `jdg.micro.ord.a126.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70286 | `jdg.micro.ord.a126.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70287 | `jdg.micro.ord.a126.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70288 | `jdg.micro.ord.a126.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70289 | `jdg.micro.ord.a127.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70290 | `jdg.micro.ord.a127.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70291 | `jdg.micro.ord.a127.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70292 | `jdg.micro.ord.a127.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70293 | `jdg.micro.ord.a127.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70294 | `jdg.micro.ord.a138a.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70295 | `jdg.micro.ord.a138a.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70296 | `jdg.micro.ord.a138a.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70297 | `jdg.micro.ord.a138a.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70298 | `jdg.micro.ord.a138a.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70299 | `jdg.micro.ord.a138a.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70300 | `jdg.micro.ord.a138a.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70301 | `jdg.micro.ord.a138a.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70302 | `jdg.micro.ord.a138a.r9` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70303 | `jdg.micro.ord.a138a.r10` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70304 | `jdg.micro.ord.a138a.r11` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70305 | `jdg.micro.ord.a138a.r12` | 🔴 BLOCK | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70306 | `jdg.micro.ord.a138a.r13` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70307 | `jdg.micro.ord.a138a.r14` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70308 | `jdg.micro.ord.a138a.r15` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70309 | `jdg.micro.ord.a138a.r16` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70310 | `jdg.micro.ord.a138a.r17` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70311 | `jdg.micro.ord.a138a.r18` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70312 | `jdg.micro.ord.a138a.r19` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70313 | `jdg.micro.ord.a138a.r20` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70314 | `jdg.micro.ord.a138a.r21` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70315 | `jdg.micro.ord.a138a.r22` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70316 | `jdg.micro.ord.a138a.r23` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70317 | `jdg.micro.ord.a138a.r24` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70318 | `jdg.micro.ord.a138a.r25` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70319 | `jdg.micro.ord.a138a.r26` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70320 | `jdg.micro.ord.a138a.r27` | 🔴 BLOCK | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70321 | `jdg.micro.ord.a138a.r28` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70322 | `jdg.micro.ord.a138a.r29` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70323 | `jdg.micro.ord.a138a.r30` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70324 | `jdg.micro.ord.a193a.r1` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70325 | `jdg.micro.ord.a193a.r2` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70326 | `jdg.micro.ord.a193a.r3` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70327 | `jdg.micro.ord.a193a.r4` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70328 | `jdg.micro.ord.a193a.r5` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70329 | `jdg.micro.ord.a193a.r6` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70330 | `jdg.micro.ord.a193a.r7` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70331 | `jdg.micro.ord.a193a.r8` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70332 | `jdg.micro.ord.a193a.r9` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |
| 70333 | `jdg.micro.ord.a193a.r10` |  | Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926... |

### `rules/micro/pcc/pcc.rego` (89 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 170001 | `jdg.micro.pcc.a1.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170002 | `jdg.micro.pcc.a1.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170003 | `jdg.micro.pcc.a1.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170004 | `jdg.micro.pcc.a1.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170005 | `jdg.micro.pcc.a1.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170006 | `jdg.micro.pcc.a1.r6` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170007 | `jdg.micro.pcc.a1.r7` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170008 | `jdg.micro.pcc.a1.r8` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170009 | `jdg.micro.pcc.a1.r9` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170010 | `jdg.micro.pcc.a1.r10` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170011 | `jdg.micro.pcc.a2.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170012 | `jdg.micro.pcc.a2.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170013 | `jdg.micro.pcc.a2.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170014 | `jdg.micro.pcc.a2.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170015 | `jdg.micro.pcc.a2.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170016 | `jdg.micro.pcc.a2.r6` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170017 | `jdg.micro.pcc.a2.r7` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170018 | `jdg.micro.pcc.a2.r8` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170019 | `jdg.micro.pcc.a2.r9` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170020 | `jdg.micro.pcc.a2.r10` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170021 | `jdg.micro.pcc.a2.r11` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170022 | `jdg.micro.pcc.a2.r12` | 🔴 BLOCK | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170023 | `jdg.micro.pcc.a3.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170024 | `jdg.micro.pcc.a3.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170025 | `jdg.micro.pcc.a3.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170026 | `jdg.micro.pcc.a3.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170027 | `jdg.micro.pcc.a3.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170028 | `jdg.micro.pcc.a3.r6` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170029 | `jdg.micro.pcc.a3.r7` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170030 | `jdg.micro.pcc.a3.r8` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170031 | `jdg.micro.pcc.a4.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170032 | `jdg.micro.pcc.a4.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170033 | `jdg.micro.pcc.a4.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170034 | `jdg.micro.pcc.a4.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170035 | `jdg.micro.pcc.a4.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170036 | `jdg.micro.pcc.a4.r6` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170037 | `jdg.micro.pcc.a4.r7` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170038 | `jdg.micro.pcc.a4.r8` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170039 | `jdg.micro.pcc.a4.r9` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170040 | `jdg.micro.pcc.a4.r10` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170041 | `jdg.micro.pcc.a6.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170042 | `jdg.micro.pcc.a6.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170043 | `jdg.micro.pcc.a6.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170044 | `jdg.micro.pcc.a6.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170045 | `jdg.micro.pcc.a6.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170046 | `jdg.micro.pcc.a6.r6` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170047 | `jdg.micro.pcc.a6.r7` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170048 | `jdg.micro.pcc.a6.r8` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170049 | `jdg.micro.pcc.a7.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170050 | `jdg.micro.pcc.a7.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170051 | `jdg.micro.pcc.a7.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170052 | `jdg.micro.pcc.a7.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170053 | `jdg.micro.pcc.a7.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170054 | `jdg.micro.pcc.a7.r6` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170055 | `jdg.micro.pcc.a7.r7` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170056 | `jdg.micro.pcc.a7.r8` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170057 | `jdg.micro.pcc.a5l.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170058 | `jdg.micro.pcc.a5l.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170059 | `jdg.micro.pcc.a5l.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170060 | `jdg.micro.pcc.a5l.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170061 | `jdg.micro.pcc.a5l.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170062 | `jdg.micro.pcc.a5l.r6` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170063 | `jdg.micro.pcc.a5l.r7` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170064 | `jdg.micro.pcc.a5l.r8` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170065 | `jdg.micro.pcc.a5l.r9` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170066 | `jdg.micro.pcc.a5l.r10` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170067 | `jdg.micro.pcc.a9l.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170068 | `jdg.micro.pcc.a9l.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170069 | `jdg.micro.pcc.a9l.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170070 | `jdg.micro.pcc.a9l.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170071 | `jdg.micro.pcc.a9l.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170072 | `jdg.micro.pcc.a9l.r6` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170073 | `jdg.micro.pcc.a9l.r7` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170074 | `jdg.micro.pcc.a9l.r8` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170075 | `jdg.micro.pcc.a13l.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170076 | `jdg.micro.pcc.a13l.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170077 | `jdg.micro.pcc.a13l.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170078 | `jdg.micro.pcc.a13l.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170079 | `jdg.micro.pcc.a13l.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170080 | `jdg.micro.pcc.a14l.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170081 | `jdg.micro.pcc.a14l.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170082 | `jdg.micro.pcc.a14l.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170083 | `jdg.micro.pcc.a14l.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170084 | `jdg.micro.pcc.a14l.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170085 | `jdg.micro.pcc.a16l.r1` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170086 | `jdg.micro.pcc.a16l.r2` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170087 | `jdg.micro.pcc.a16l.r3` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170088 | `jdg.micro.pcc.a16l.r4` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |
| 170089 | `jdg.micro.pcc.a16l.r5` |  | Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959) |

### `rules/micro/pit/pit.rego` (521 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 60006 | `jdg.micro.pit.a6.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60007 | `jdg.micro.pit.a6.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60008 | `jdg.micro.pit.a6.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60009 | `jdg.micro.pit.a6.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60010 | `jdg.micro.pit.a6.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60011 | `jdg.micro.pit.a6.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60012 | `jdg.micro.pit.a6.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60013 | `jdg.micro.pit.a6.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60014 | `jdg.micro.pit.a6.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60015 | `jdg.micro.pit.a6.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60016 | `jdg.micro.pit.a9.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60017 | `jdg.micro.pit.a9.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60018 | `jdg.micro.pit.a9.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60019 | `jdg.micro.pit.a9.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60020 | `jdg.micro.pit.a9.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60021 | `jdg.micro.pit.a9.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60022 | `jdg.micro.pit.a9.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60023 | `jdg.micro.pit.a9.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60024 | `jdg.micro.pit.a9.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60025 | `jdg.micro.pit.a9.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60026 | `jdg.micro.pit.a9a.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60027 | `jdg.micro.pit.a9a.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60028 | `jdg.micro.pit.a9a.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60029 | `jdg.micro.pit.a9a.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60030 | `jdg.micro.pit.a9a.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60031 | `jdg.micro.pit.a9a.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60032 | `jdg.micro.pit.a9a.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60033 | `jdg.micro.pit.a9a.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60034 | `jdg.micro.pit.a9a.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60035 | `jdg.micro.pit.a9a.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60036 | `jdg.micro.pit.a9a.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60037 | `jdg.micro.pit.a9a.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60038 | `jdg.micro.pit.a10.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60039 | `jdg.micro.pit.a10.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60040 | `jdg.micro.pit.a10.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60041 | `jdg.micro.pit.a10.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60042 | `jdg.micro.pit.a10.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60043 | `jdg.micro.pit.a10.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60044 | `jdg.micro.pit.a10.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60045 | `jdg.micro.pit.a10.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60046 | `jdg.micro.pit.a10.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60047 | `jdg.micro.pit.a10.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60048 | `jdg.micro.pit.a10.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60049 | `jdg.micro.pit.a10.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60050 | `jdg.micro.pit.a14.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60051 | `jdg.micro.pit.a14.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60052 | `jdg.micro.pit.a14.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60053 | `jdg.micro.pit.a14.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60054 | `jdg.micro.pit.a14.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60055 | `jdg.micro.pit.a14.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60056 | `jdg.micro.pit.a14.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60057 | `jdg.micro.pit.a14.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60058 | `jdg.micro.pit.a14.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60059 | `jdg.micro.pit.a14.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60060 | `jdg.micro.pit.a14.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60061 | `jdg.micro.pit.a14.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60062 | `jdg.micro.pit.a14.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60063 | `jdg.micro.pit.a14.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60064 | `jdg.micro.pit.a14.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60065 | `jdg.micro.pit.a14.r16` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60066 | `jdg.micro.pit.a14.r17` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60067 | `jdg.micro.pit.a14.r18` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60068 | `jdg.micro.pit.a14.r19` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60069 | `jdg.micro.pit.a14.r20` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60070 | `jdg.micro.pit.a14c.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60071 | `jdg.micro.pit.a14c.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60072 | `jdg.micro.pit.a14c.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60073 | `jdg.micro.pit.a14c.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60074 | `jdg.micro.pit.a14c.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60075 | `jdg.micro.pit.a14c.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60076 | `jdg.micro.pit.a14c.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60077 | `jdg.micro.pit.a14c.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60078 | `jdg.micro.pit.a14c.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60079 | `jdg.micro.pit.a14c.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60080 | `jdg.micro.pit.a14c.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60081 | `jdg.micro.pit.a14c.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60082 | `jdg.micro.pit.a21.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60083 | `jdg.micro.pit.a21.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60084 | `jdg.micro.pit.a21.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60085 | `jdg.micro.pit.a21.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60086 | `jdg.micro.pit.a21.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60087 | `jdg.micro.pit.a21.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60088 | `jdg.micro.pit.a21.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60089 | `jdg.micro.pit.a21.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60090 | `jdg.micro.pit.a21.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60091 | `jdg.micro.pit.a21.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60092 | `jdg.micro.pit.a21.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60093 | `jdg.micro.pit.a21.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60094 | `jdg.micro.pit.a22.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60095 | `jdg.micro.pit.a22.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60096 | `jdg.micro.pit.a22.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60097 | `jdg.micro.pit.a22.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60098 | `jdg.micro.pit.a22.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60099 | `jdg.micro.pit.a22.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60100 | `jdg.micro.pit.a22.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60101 | `jdg.micro.pit.a22.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60102 | `jdg.micro.pit.a22.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60103 | `jdg.micro.pit.a22.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60104 | `jdg.micro.pit.a22.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60105 | `jdg.micro.pit.a22.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60106 | `jdg.micro.pit.a22.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60107 | `jdg.micro.pit.a22.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60108 | `jdg.micro.pit.a22.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60109 | `jdg.micro.pit.a22a.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60110 | `jdg.micro.pit.a22a.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60111 | `jdg.micro.pit.a22a.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60112 | `jdg.micro.pit.a22a.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60113 | `jdg.micro.pit.a22a.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60114 | `jdg.micro.pit.a22a.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60115 | `jdg.micro.pit.a22a.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60116 | `jdg.micro.pit.a22a.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60117 | `jdg.micro.pit.a22a.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60118 | `jdg.micro.pit.a22a.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60119 | `jdg.micro.pit.a22d.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60120 | `jdg.micro.pit.a22d.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60121 | `jdg.micro.pit.a22d.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60122 | `jdg.micro.pit.a22d.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60123 | `jdg.micro.pit.a22d.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60124 | `jdg.micro.pit.a22d.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60125 | `jdg.micro.pit.a22d.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60126 | `jdg.micro.pit.a22d.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60127 | `jdg.micro.pit.a22e.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60128 | `jdg.micro.pit.a22e.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60129 | `jdg.micro.pit.a22e.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60130 | `jdg.micro.pit.a22e.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60131 | `jdg.micro.pit.a22e.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60132 | `jdg.micro.pit.a22e.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60133 | `jdg.micro.pit.a22f.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60134 | `jdg.micro.pit.a22f.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60135 | `jdg.micro.pit.a22f.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60136 | `jdg.micro.pit.a22f.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60137 | `jdg.micro.pit.a22f.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60138 | `jdg.micro.pit.a22f.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60139 | `jdg.micro.pit.a22g.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60140 | `jdg.micro.pit.a22g.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60141 | `jdg.micro.pit.a22g.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60142 | `jdg.micro.pit.a22g.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60143 | `jdg.micro.pit.a22g.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60144 | `jdg.micro.pit.a22g.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60145 | `jdg.micro.pit.a22g.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60146 | `jdg.micro.pit.a22g.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60147 | `jdg.micro.pit.a22i.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60148 | `jdg.micro.pit.a22i.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60149 | `jdg.micro.pit.a22i.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60150 | `jdg.micro.pit.a22i.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60151 | `jdg.micro.pit.a22i.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60152 | `jdg.micro.pit.a22i.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60153 | `jdg.micro.pit.a22j.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60154 | `jdg.micro.pit.a22j.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60155 | `jdg.micro.pit.a22j.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60156 | `jdg.micro.pit.a22j.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60157 | `jdg.micro.pit.a22j.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60158 | `jdg.micro.pit.a22j.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60159 | `jdg.micro.pit.a22k.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60160 | `jdg.micro.pit.a22k.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60161 | `jdg.micro.pit.a22k.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60162 | `jdg.micro.pit.a22k.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60163 | `jdg.micro.pit.a22k.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60164 | `jdg.micro.pit.a22k.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60165 | `jdg.micro.pit.a22l.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60166 | `jdg.micro.pit.a22l.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60167 | `jdg.micro.pit.a22l.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60168 | `jdg.micro.pit.a22l.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60169 | `jdg.micro.pit.a22l.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60170 | `jdg.micro.pit.a22l.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60171 | `jdg.micro.pit.a22l.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60172 | `jdg.micro.pit.a22l.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60173 | `jdg.micro.pit.a22m.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60174 | `jdg.micro.pit.a22m.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60175 | `jdg.micro.pit.a22m.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60176 | `jdg.micro.pit.a22m.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60177 | `jdg.micro.pit.a22m.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60178 | `jdg.micro.pit.a22m.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60179 | `jdg.micro.pit.a22m.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60180 | `jdg.micro.pit.a22m.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60181 | `jdg.micro.pit.a22p.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60182 | `jdg.micro.pit.a22p.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60183 | `jdg.micro.pit.a22p.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60184 | `jdg.micro.pit.a22p.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60185 | `jdg.micro.pit.a22p.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60186 | `jdg.micro.pit.a22p.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60187 | `jdg.micro.pit.a22p.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60188 | `jdg.micro.pit.a22p.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60189 | `jdg.micro.pit.a23.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60190 | `jdg.micro.pit.a23.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60191 | `jdg.micro.pit.a23.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60192 | `jdg.micro.pit.a23.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60193 | `jdg.micro.pit.a23.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60194 | `jdg.micro.pit.a23.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60195 | `jdg.micro.pit.a23.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60196 | `jdg.micro.pit.a23.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60197 | `jdg.micro.pit.a23.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60198 | `jdg.micro.pit.a23.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60199 | `jdg.micro.pit.a23.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60200 | `jdg.micro.pit.a23.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60201 | `jdg.micro.pit.a23.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60202 | `jdg.micro.pit.a23.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60203 | `jdg.micro.pit.a23.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60204 | `jdg.micro.pit.a23.r16` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60205 | `jdg.micro.pit.a23.r17` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60206 | `jdg.micro.pit.a23.r18` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60207 | `jdg.micro.pit.a23.r19` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60208 | `jdg.micro.pit.a23.r20` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60209 | `jdg.micro.pit.a23.r21` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60210 | `jdg.micro.pit.a23.r22` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60211 | `jdg.micro.pit.a23.r23` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60212 | `jdg.micro.pit.a23.r24` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60213 | `jdg.micro.pit.a23.r25` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60214 | `jdg.micro.pit.a23.r26` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60215 | `jdg.micro.pit.a23.r27` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60216 | `jdg.micro.pit.a23.r28` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60217 | `jdg.micro.pit.a23.r29` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60218 | `jdg.micro.pit.a23.r30` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60219 | `jdg.micro.pit.a24.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60220 | `jdg.micro.pit.a24.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60221 | `jdg.micro.pit.a24.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60222 | `jdg.micro.pit.a24.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60223 | `jdg.micro.pit.a24.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60224 | `jdg.micro.pit.a24.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60225 | `jdg.micro.pit.a24.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60226 | `jdg.micro.pit.a24.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60227 | `jdg.micro.pit.a24.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60228 | `jdg.micro.pit.a24.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60229 | `jdg.micro.pit.a24.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60230 | `jdg.micro.pit.a24.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60231 | `jdg.micro.pit.a24.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60232 | `jdg.micro.pit.a24.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60233 | `jdg.micro.pit.a24.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60234 | `jdg.micro.pit.a24a.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60235 | `jdg.micro.pit.a24a.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60236 | `jdg.micro.pit.a24a.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60237 | `jdg.micro.pit.a24a.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60238 | `jdg.micro.pit.a24a.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60239 | `jdg.micro.pit.a24a.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60240 | `jdg.micro.pit.a24a.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60241 | `jdg.micro.pit.a24a.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60242 | `jdg.micro.pit.a24a.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60243 | `jdg.micro.pit.a24a.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60244 | `jdg.micro.pit.a26.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60245 | `jdg.micro.pit.a26.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60246 | `jdg.micro.pit.a26.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60247 | `jdg.micro.pit.a26.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60248 | `jdg.micro.pit.a26.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60249 | `jdg.micro.pit.a26.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60250 | `jdg.micro.pit.a26.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60251 | `jdg.micro.pit.a26.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60252 | `jdg.micro.pit.a26.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60253 | `jdg.micro.pit.a26.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60254 | `jdg.micro.pit.a26.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60255 | `jdg.micro.pit.a26.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60256 | `jdg.micro.pit.a26.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60257 | `jdg.micro.pit.a26.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60258 | `jdg.micro.pit.a26.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60259 | `jdg.micro.pit.a26.r16` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60260 | `jdg.micro.pit.a26.r17` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60261 | `jdg.micro.pit.a26.r18` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60262 | `jdg.micro.pit.a26.r19` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60263 | `jdg.micro.pit.a26.r20` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60264 | `jdg.micro.pit.a26.r21` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60265 | `jdg.micro.pit.a26.r22` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60266 | `jdg.micro.pit.a26.r23` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60267 | `jdg.micro.pit.a26.r24` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60268 | `jdg.micro.pit.a26.r25` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60269 | `jdg.micro.pit.a26e.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60270 | `jdg.micro.pit.a26e.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60271 | `jdg.micro.pit.a26e.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60272 | `jdg.micro.pit.a26e.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60273 | `jdg.micro.pit.a26e.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60274 | `jdg.micro.pit.a26e.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60275 | `jdg.micro.pit.a26e.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60276 | `jdg.micro.pit.a26e.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60277 | `jdg.micro.pit.a26e.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60278 | `jdg.micro.pit.a26e.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60279 | `jdg.micro.pit.a26e.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60280 | `jdg.micro.pit.a26e.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60281 | `jdg.micro.pit.a26e.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60282 | `jdg.micro.pit.a26e.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60283 | `jdg.micro.pit.a26e.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60284 | `jdg.micro.pit.a26eb.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60285 | `jdg.micro.pit.a26eb.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60286 | `jdg.micro.pit.a26eb.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60287 | `jdg.micro.pit.a26eb.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60288 | `jdg.micro.pit.a26eb.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60289 | `jdg.micro.pit.a26eb.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60290 | `jdg.micro.pit.a26ec.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60291 | `jdg.micro.pit.a26ec.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60292 | `jdg.micro.pit.a26ec.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60293 | `jdg.micro.pit.a26ec.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60294 | `jdg.micro.pit.a26ec.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60295 | `jdg.micro.pit.a26ec.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60296 | `jdg.micro.pit.a26gb.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60297 | `jdg.micro.pit.a26gb.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60298 | `jdg.micro.pit.a26gb.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60299 | `jdg.micro.pit.a26gb.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60300 | `jdg.micro.pit.a26gb.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60301 | `jdg.micro.pit.a26gb.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60302 | `jdg.micro.pit.a26gb.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60303 | `jdg.micro.pit.a26gb.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60304 | `jdg.micro.pit.a26h.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60305 | `jdg.micro.pit.a26h.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60306 | `jdg.micro.pit.a26h.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60307 | `jdg.micro.pit.a26h.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60308 | `jdg.micro.pit.a26h.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60309 | `jdg.micro.pit.a26h.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60310 | `jdg.micro.pit.a26h.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60311 | `jdg.micro.pit.a26h.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60312 | `jdg.micro.pit.a27.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60313 | `jdg.micro.pit.a27.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60314 | `jdg.micro.pit.a27.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60315 | `jdg.micro.pit.a27.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60316 | `jdg.micro.pit.a27.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60317 | `jdg.micro.pit.a27.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60318 | `jdg.micro.pit.a27.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60319 | `jdg.micro.pit.a27.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60320 | `jdg.micro.pit.a27.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60321 | `jdg.micro.pit.a27.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60322 | `jdg.micro.pit.a27.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60323 | `jdg.micro.pit.a27.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60324 | `jdg.micro.pit.a27.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60325 | `jdg.micro.pit.a27.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60326 | `jdg.micro.pit.a27.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60327 | `jdg.micro.pit.a27f.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60328 | `jdg.micro.pit.a27f.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60329 | `jdg.micro.pit.a27f.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60330 | `jdg.micro.pit.a27f.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60331 | `jdg.micro.pit.a27f.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60332 | `jdg.micro.pit.a27f.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60333 | `jdg.micro.pit.a27f.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60334 | `jdg.micro.pit.a27f.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60335 | `jdg.micro.pit.a27f.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60336 | `jdg.micro.pit.a27f.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60337 | `jdg.micro.pit.a27f.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60338 | `jdg.micro.pit.a27f.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60339 | `jdg.micro.pit.a30.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60340 | `jdg.micro.pit.a30.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60341 | `jdg.micro.pit.a30.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60342 | `jdg.micro.pit.a30.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60343 | `jdg.micro.pit.a30.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60344 | `jdg.micro.pit.a30.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60345 | `jdg.micro.pit.a30.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60346 | `jdg.micro.pit.a30.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60347 | `jdg.micro.pit.a30.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60348 | `jdg.micro.pit.a30.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60349 | `jdg.micro.pit.a30.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60350 | `jdg.micro.pit.a30.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60351 | `jdg.micro.pit.a30a.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60352 | `jdg.micro.pit.a30a.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60353 | `jdg.micro.pit.a30a.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60354 | `jdg.micro.pit.a30a.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60355 | `jdg.micro.pit.a30a.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60356 | `jdg.micro.pit.a30a.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60357 | `jdg.micro.pit.a30a.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60358 | `jdg.micro.pit.a30a.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60359 | `jdg.micro.pit.a30a.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60360 | `jdg.micro.pit.a30a.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60361 | `jdg.micro.pit.a30a.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60362 | `jdg.micro.pit.a30a.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60363 | `jdg.micro.pit.a30b.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60364 | `jdg.micro.pit.a30b.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60365 | `jdg.micro.pit.a30b.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60366 | `jdg.micro.pit.a30b.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60367 | `jdg.micro.pit.a30b.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60368 | `jdg.micro.pit.a30b.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60369 | `jdg.micro.pit.a30b.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60370 | `jdg.micro.pit.a30b.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60371 | `jdg.micro.pit.a30b.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60372 | `jdg.micro.pit.a30b.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60373 | `jdg.micro.pit.a30b.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60374 | `jdg.micro.pit.a30b.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60375 | `jdg.micro.pit.a30c.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60376 | `jdg.micro.pit.a30c.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60377 | `jdg.micro.pit.a30c.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60378 | `jdg.micro.pit.a30c.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60379 | `jdg.micro.pit.a30c.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60380 | `jdg.micro.pit.a30c.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60381 | `jdg.micro.pit.a30c.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60382 | `jdg.micro.pit.a30c.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60383 | `jdg.micro.pit.a30c.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60384 | `jdg.micro.pit.a30c.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60385 | `jdg.micro.pit.a30c.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60386 | `jdg.micro.pit.a30c.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60387 | `jdg.micro.pit.a30ca.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60388 | `jdg.micro.pit.a30ca.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60389 | `jdg.micro.pit.a30ca.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60390 | `jdg.micro.pit.a30ca.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60391 | `jdg.micro.pit.a30ca.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60392 | `jdg.micro.pit.a30ca.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60393 | `jdg.micro.pit.a30ca.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60394 | `jdg.micro.pit.a30ca.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60395 | `jdg.micro.pit.a30ca.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60396 | `jdg.micro.pit.a30ca.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60397 | `jdg.micro.pit.a30ca.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60398 | `jdg.micro.pit.a30ca.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60399 | `jdg.micro.pit.a30da.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60400 | `jdg.micro.pit.a30da.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60401 | `jdg.micro.pit.a30da.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60402 | `jdg.micro.pit.a30da.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60403 | `jdg.micro.pit.a30da.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60404 | `jdg.micro.pit.a30da.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60405 | `jdg.micro.pit.a30da.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60406 | `jdg.micro.pit.a30da.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60407 | `jdg.micro.pit.a30da.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60408 | `jdg.micro.pit.a30da.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60409 | `jdg.micro.pit.a30da.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60410 | `jdg.micro.pit.a30da.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60411 | `jdg.micro.pit.a30f.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60412 | `jdg.micro.pit.a30f.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60413 | `jdg.micro.pit.a30f.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60414 | `jdg.micro.pit.a30f.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60415 | `jdg.micro.pit.a30f.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60416 | `jdg.micro.pit.a30f.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60417 | `jdg.micro.pit.a30f.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60418 | `jdg.micro.pit.a30f.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60419 | `jdg.micro.pit.a30f.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60420 | `jdg.micro.pit.a30f.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60421 | `jdg.micro.pit.a30f.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60422 | `jdg.micro.pit.a30f.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60423 | `jdg.micro.pit.a30f.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60424 | `jdg.micro.pit.a30f.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60425 | `jdg.micro.pit.a30f.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60426 | `jdg.micro.pit.a31.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60427 | `jdg.micro.pit.a31.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60428 | `jdg.micro.pit.a31.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60429 | `jdg.micro.pit.a31.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60430 | `jdg.micro.pit.a31.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60431 | `jdg.micro.pit.a31.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60432 | `jdg.micro.pit.a31.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60433 | `jdg.micro.pit.a31.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60434 | `jdg.micro.pit.a31.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60435 | `jdg.micro.pit.a31.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60436 | `jdg.micro.pit.a31.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60437 | `jdg.micro.pit.a31.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60438 | `jdg.micro.pit.a31.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60439 | `jdg.micro.pit.a31.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60440 | `jdg.micro.pit.a31.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60441 | `jdg.micro.pit.a31.r16` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60442 | `jdg.micro.pit.a31.r17` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60443 | `jdg.micro.pit.a31.r18` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60444 | `jdg.micro.pit.a31.r19` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60445 | `jdg.micro.pit.a31.r20` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60446 | `jdg.micro.pit.a31.r21` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60447 | `jdg.micro.pit.a31.r22` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60448 | `jdg.micro.pit.a31.r23` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60449 | `jdg.micro.pit.a31.r24` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60450 | `jdg.micro.pit.a31.r25` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60451 | `jdg.micro.pit.a44.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60452 | `jdg.micro.pit.a44.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60453 | `jdg.micro.pit.a44.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60454 | `jdg.micro.pit.a44.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60455 | `jdg.micro.pit.a44.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60456 | `jdg.micro.pit.a44.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60457 | `jdg.micro.pit.a44.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60458 | `jdg.micro.pit.a44.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60459 | `jdg.micro.pit.a44.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60460 | `jdg.micro.pit.a44.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60461 | `jdg.micro.pit.a44.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60462 | `jdg.micro.pit.a44.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60463 | `jdg.micro.pit.a45.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60464 | `jdg.micro.pit.a45.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60465 | `jdg.micro.pit.a45.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60466 | `jdg.micro.pit.a45.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60467 | `jdg.micro.pit.a45.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60468 | `jdg.micro.pit.a45.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60469 | `jdg.micro.pit.a45.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60470 | `jdg.micro.pit.a45.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60471 | `jdg.micro.pit.a45.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60472 | `jdg.micro.pit.a45.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60473 | `jdg.micro.pit.a45.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60474 | `jdg.micro.pit.a45.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60475 | `jdg.micro.pit.a45.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60476 | `jdg.micro.pit.a45.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60477 | `jdg.micro.pit.a45.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60478 | `jdg.micro.pit.a45a.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60479 | `jdg.micro.pit.a45a.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60480 | `jdg.micro.pit.a45a.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60481 | `jdg.micro.pit.a45a.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60482 | `jdg.micro.pit.a45a.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60483 | `jdg.micro.pit.a45a.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60484 | `jdg.micro.pit.a45a.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60485 | `jdg.micro.pit.a45a.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60486 | `jdg.micro.pit.a45a.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60487 | `jdg.micro.pit.a45a.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60488 | `jdg.micro.pit.a45a.r11` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60489 | `jdg.micro.pit.a45a.r12` | 🔴 BLOCK | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60490 | `jdg.micro.pit.a45a.r13` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60491 | `jdg.micro.pit.a45a.r14` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60492 | `jdg.micro.pit.a45a.r15` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60493 | `jdg.micro.pit.a21b.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60494 | `jdg.micro.pit.a21b.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60495 | `jdg.micro.pit.a21b.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60496 | `jdg.micro.pit.a21b.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60497 | `jdg.micro.pit.a21b.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60498 | `jdg.micro.pit.a21b.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60499 | `jdg.micro.pit.a21b.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60500 | `jdg.micro.pit.a21b.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60501 | `jdg.micro.pit.a21b.r9` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60502 | `jdg.micro.pit.a21b.r10` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60503 | `jdg.micro.pit.a21c.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60504 | `jdg.micro.pit.a21c.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60505 | `jdg.micro.pit.a21c.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60506 | `jdg.micro.pit.a21c.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60507 | `jdg.micro.pit.a21c.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60508 | `jdg.micro.pit.a21c.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60509 | `jdg.micro.pit.a21c.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60510 | `jdg.micro.pit.a21c.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60511 | `jdg.micro.pit.a21d.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60512 | `jdg.micro.pit.a21d.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60513 | `jdg.micro.pit.a21d.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60514 | `jdg.micro.pit.a21d.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60515 | `jdg.micro.pit.a21d.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60516 | `jdg.micro.pit.a21d.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60517 | `jdg.micro.pit.a21d.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60518 | `jdg.micro.pit.a21d.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60519 | `jdg.micro.pit.a21e.r1` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60520 | `jdg.micro.pit.a21e.r2` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60521 | `jdg.micro.pit.a21e.r3` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60522 | `jdg.micro.pit.a21e.r4` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60523 | `jdg.micro.pit.a21e.r5` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60524 | `jdg.micro.pit.a21e.r6` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60525 | `jdg.micro.pit.a21e.r7` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |
| 60526 | `jdg.micro.pit.a21e.r8` |  | Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350) |

### `rules/micro/plan33_agricultural_tax.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 7500 | `jdg.agricultural_tax.r1` |  | Ustawa o podatku rolnym |
| 7501 | `jdg.agricultural_tax.r2` |  | Art. 4 ustawy o podatku rolnym |
| 7502 | `jdg.agricultural_tax.r3` |  | Art. 12 ustawy o podatku rolnym |
| 7503 | `jdg.agricultural_tax.r4` |  | Art. 2 ustawy o podatku rolnym |
| 7504 | `jdg.agricultural_tax.r5` |  | Art. 6 ustawy o podatku rolnym |

### `rules/micro/plan33_cb.rego` (20 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 6200 | `jdg.cb.r1` |  |  |
| 6201 | `jdg.cb.r10` |  |  |
| 6202 | `jdg.cb.r11` |  |  |
| 6203 | `jdg.cb.r12` |  |  |
| 6204 | `jdg.cb.r13` |  |  |
| 6205 | `jdg.cb.r14` |  |  |
| 6206 | `jdg.cb.r15` |  |  |
| 6207 | `jdg.cb.r16` |  |  |
| 6208 | `jdg.cb.r17` |  |  |
| 6209 | `jdg.cb.r18` |  |  |
| 6210 | `jdg.cb.r19` |  |  |
| 6211 | `jdg.cb.r2` |  |  |
| 6212 | `jdg.cb.r20` |  |  |
| 6213 | `jdg.cb.r3` |  |  |
| 6214 | `jdg.cb.r4` |  |  |
| 6215 | `jdg.cb.r5` |  |  |
| 6216 | `jdg.cb.r6` |  |  |
| 6217 | `jdg.cb.r7` |  |  |
| 6218 | `jdg.cb.r8` |  |  |
| 6219 | `jdg.cb.r9` |  |  |

### `rules/micro/plan33_ceidg.rego` (15 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 5200 | `jdg.ceidg.r1` |  |  |
| 5201 | `jdg.ceidg.r10` |  |  |
| 5202 | `jdg.ceidg.r11` |  |  |
| 5203 | `jdg.ceidg.r12` |  |  |
| 5204 | `jdg.ceidg.r13` |  |  |
| 5205 | `jdg.ceidg.r14` |  |  |
| 5206 | `jdg.ceidg.r15` |  |  |
| 5207 | `jdg.ceidg.r2` |  |  |
| 5208 | `jdg.ceidg.r3` |  |  |
| 5209 | `jdg.ceidg.r4` |  |  |
| 5210 | `jdg.ceidg.r5` |  |  |
| 5211 | `jdg.ceidg.r6` |  |  |
| 5212 | `jdg.ceidg.r7` |  |  |
| 5213 | `jdg.ceidg.r8` |  |  |
| 5214 | `jdg.ceidg.r9` |  |  |

### `rules/micro/plan33_est.rego` (15 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 6600 | `jdg.est.r1` |  |  |
| 6601 | `jdg.est.r10` |  |  |
| 6602 | `jdg.est.r11` |  |  |
| 6603 | `jdg.est.r12` |  |  |
| 6604 | `jdg.est.r13` |  |  |
| 6605 | `jdg.est.r14` |  |  |
| 6606 | `jdg.est.r15` |  |  |
| 6607 | `jdg.est.r2` |  |  |
| 6608 | `jdg.est.r3` |  |  |
| 6609 | `jdg.est.r4` |  |  |
| 6610 | `jdg.est.r5` |  |  |
| 6611 | `jdg.est.r6` |  |  |
| 6612 | `jdg.est.r7` |  |  |
| 6613 | `jdg.est.r8` |  |  |
| 6614 | `jdg.est.r9` |  |  |

### `rules/micro/plan33_health.rego` (40 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 4400 | `jdg.health.annual.r1` |  |  |
| 4401 | `jdg.health.annual.r10` |  |  |
| 4402 | `jdg.health.annual.r11` |  |  |
| 4403 | `jdg.health.annual.r12` |  |  |
| 4404 | `jdg.health.annual.r13` |  |  |
| 4405 | `jdg.health.annual.r14` |  |  |
| 4406 | `jdg.health.annual.r15` |  |  |
| 4407 | `jdg.health.annual.r2` |  |  |
| 4408 | `jdg.health.annual.r3` |  |  |
| 4409 | `jdg.health.annual.r4` |  |  |
| 4410 | `jdg.health.annual.r5` |  |  |
| 4411 | `jdg.health.annual.r6` |  |  |
| 4412 | `jdg.health.annual.r7` |  |  |
| 4413 | `jdg.health.annual.r8` |  |  |
| 4414 | `jdg.health.annual.r9` |  |  |
| 4415 | `jdg.health.r1` |  |  |
| 4416 | `jdg.health.r10` |  |  |
| 4417 | `jdg.health.r11` |  |  |
| 4418 | `jdg.health.r12` |  |  |
| 4419 | `jdg.health.r13` |  |  |
| 4420 | `jdg.health.r14` |  |  |
| 4421 | `jdg.health.r15` |  |  |
| 4422 | `jdg.health.r2` |  |  |
| 4423 | `jdg.health.r3` |  |  |
| 4424 | `jdg.health.r4` |  |  |
| 4425 | `jdg.health.r5` |  |  |
| 4426 | `jdg.health.r6` |  |  |
| 4427 | `jdg.health.r7` |  |  |
| 4428 | `jdg.health.r8` |  |  |
| 4429 | `jdg.health.r9` |  |  |
| 4430 | `jdg.health.rate.r1` |  |  |
| 4431 | `jdg.health.rate.r10` |  |  |
| 4432 | `jdg.health.rate.r2` |  |  |
| 4433 | `jdg.health.rate.r3` |  |  |
| 4434 | `jdg.health.rate.r4` |  |  |
| 4435 | `jdg.health.rate.r5` |  |  |
| 4436 | `jdg.health.rate.r6` |  |  |
| 4437 | `jdg.health.rate.r7` |  |  |
| 4438 | `jdg.health.rate.r8` |  |  |
| 4439 | `jdg.health.rate.r9` |  |  |

### `rules/micro/plan33_jpk.rego` (70 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 5900 | `jdg.jpk.a99.r11` |  | par. 2 rozp. JPK_VAT |
| 5901 | `jdg.jpk.a99.r12` |  | par. 3 rozp. JPK_VAT |
| 5902 | `jdg.jpk.a99.r13` |  | par. 4 rozp. JPK_VAT |
| 5903 | `jdg.jpk.a99.r14` |  | par. 5 rozp. JPK_VAT |
| 5904 | `jdg.jpk.a99.r15` |  | par. 6 rozp. JPK_VAT |
| 5905 | `jdg.jpk.a99.r16` |  | par. 10 rozp. JPK_VAT |
| 5906 | `jdg.jpk.a99.r17` |  | par. 11 rozp. JPK_VAT |
| 5907 | `jdg.jpk.a99.r18` |  | par. 12 rozp. JPK_VAT |
| 5908 | `jdg.jpk.a99.r19` |  | par. 13 rozp. JPK_VAT |
| 5909 | `jdg.jpk.a99.r20` |  | par. 14 rozp. JPK_VAT |
| 5910 | `jdg.jpk.a99.r21` |  | par. 15 rozp. JPK_VAT |
| 5911 | `jdg.jpk.a99.r22` |  | par. 16 rozp. JPK_VAT |
| 5912 | `jdg.jpk.a99.r23` |  | par. 17 rozp. JPK_VAT |
| 5913 | `jdg.jpk.a99.r24` |  | par. 18 rozp. JPK_VAT |
| 5914 | `jdg.jpk.a99.r25` |  | par. 18a |
| 5915 | `jdg.jpk.a99.r26` |  | par. 18b |
| 5916 | `jdg.jpk.a99.r27` |  | par. 18c |
| 5917 | `jdg.jpk.a99.r28` |  | par. 18d |
| 5918 | `jdg.jpk.a99.r29` |  | par. 18e |
| 5919 | `jdg.jpk.a99.r30` |  | par. 19 rozp. JPK_VAT |
| 5920 | `jdg.jpk.a99.r31` |  | par. 20 rozp. JPK_VAT |
| 5921 | `jdg.jpk.a99.r32` |  | par. 21 rozp. JPK_VAT |
| 5922 | `jdg.jpk.a99.r33` |  | par. 22 rozp. JPK_VAT |
| 5923 | `jdg.jpk.a99.r34` |  | par. 23 rozp. JPK_VAT |
| 5924 | `jdg.jpk.a99.r35` |  | par. 24 rozp. JPK_VAT |
| 5925 | `jdg.jpk.b.r1` |  | Art. 30a ustawy o rachunkowości |
| 5926 | `jdg.jpk.b.r10` |  | Rozp. MF |
| 5927 | `jdg.jpk.b.r11` |  | Art. 30a ust. 4 u.o.r. |
| 5928 | `jdg.jpk.b.r12` |  | Art. 30a ust. 5 u.o.r. |
| 5929 | `jdg.jpk.b.r13` |  | Art. 30a ust. 6 u.o.r. |
| 5930 | `jdg.jpk.b.r14` |  | Art. 30a ust. 7 u.o.r. |
| 5931 | `jdg.jpk.b.r15` |  | Art. 30a ust. 8 u.o.r. |
| 5932 | `jdg.jpk.b.r2` |  | Rozp. MF w sprawie PKPiR |
| 5933 | `jdg.jpk.b.r3` |  | Rozp. MF |
| 5934 | `jdg.jpk.b.r4` |  | Rozp. MF |
| 5935 | `jdg.jpk.b.r5` |  | Rozp. MF |
| 5936 | `jdg.jpk.b.r6` |  | Rozp. MF |
| 5937 | `jdg.jpk.b.r7` |  | Rozp. MF |
| 5938 | `jdg.jpk.b.r8` |  | Art. 30a ust. 2 u.o.r. |
| 5939 | `jdg.jpk.b.r9` |  | Art. 30a ust. 3 u.o.r. |
| 5940 | `jdg.jpk.fa.r1` |  |  |
| 5941 | `jdg.jpk.fa.r2` |  |  |
| 5942 | `jdg.jpk.fa.r3` |  |  |
| 5943 | `jdg.jpk.fa.r4` |  |  |
| 5944 | `jdg.jpk.mag.r1` |  |  |
| 5945 | `jdg.jpk.mag.r2` |  |  |
| 5946 | `jdg.jpk.mag.r3` |  |  |
| 5947 | `jdg.jpk.pkpir.r1` |  |  |
| 5948 | `jdg.jpk.pkpir.r2` |  |  |
| 5949 | `jdg.jpk.pkpir.r3` |  |  |
| 5950 | `jdg.jpk.pkpir.r4` |  |  |
| 5951 | `jdg.jpk.pkpir.r5` |  |  |
| 5952 | `jdg.jpk.r1` |  |  |
| 5953 | `jdg.jpk.r10` |  |  |
| 5954 | `jdg.jpk.r11` |  |  |
| 5955 | `jdg.jpk.r12` |  |  |
| 5956 | `jdg.jpk.r13` |  |  |
| 5957 | `jdg.jpk.r14` |  |  |
| 5958 | `jdg.jpk.r15` |  |  |
| 5959 | `jdg.jpk.r2` |  |  |
| 5960 | `jdg.jpk.r3` |  |  |
| 5961 | `jdg.jpk.r4` |  |  |
| 5962 | `jdg.jpk.r5` |  |  |
| 5963 | `jdg.jpk.r6` |  |  |
| 5964 | `jdg.jpk.r7` |  |  |
| 5965 | `jdg.jpk.r8` |  |  |
| 5966 | `jdg.jpk.r9` |  |  |
| 5967 | `jdg.jpk.wb.r1` |  |  |
| 5968 | `jdg.jpk.wb.r2` |  |  |
| 5969 | `jdg.jpk.wb.r3` |  |  |

### `rules/micro/plan33_kks.rego` (64 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 3600 | `jdg.kks.a54.r1` |  | Art. 54 KKS |
| 3601 | `jdg.kks.a54.r2` |  |  |
| 3602 | `jdg.kks.a54.r6` |  | Art. 54 par. 1 KKS |
| 3603 | `jdg.kks.a54.r7` |  | Art. 54 par. 2 KKS |
| 3604 | `jdg.kks.a54.r8` |  | Art. 54 par. 3 KKS |
| 3605 | `jdg.kks.a54.r9` |  | Art. 54 par. 4 KKS |
| 3606 | `jdg.kks.a55.r10` |  | Art. 55 par. 5 KKS |
| 3607 | `jdg.kks.a55.r11` |  | Art. 55 par. 6 KKS |
| 3608 | `jdg.kks.a55.r6` |  | Art. 55 par. 1 KKS |
| 3609 | `jdg.kks.a55.r7` |  | Art. 55 par. 2 KKS |
| 3610 | `jdg.kks.a55.r8` |  | Art. 55 par. 3 KKS |
| 3611 | `jdg.kks.a55.r9` |  | Art. 55 par. 4 KKS |
| 3612 | `jdg.kks.a56.r1` |  | Art. 56 KKS |
| 3613 | `jdg.kks.a56.r2` |  | Art. 56 KKS |
| 3614 | `jdg.kks.a56.r3` |  | Art. 56 KKS |
| 3615 | `jdg.kks.a56.r6` |  | Art. 56 par. 1 KKS |
| 3616 | `jdg.kks.a56.r7` |  | Art. 56 par. 2 KKS |
| 3617 | `jdg.kks.a56.r8` |  | Art. 56 par. 3 KKS |
| 3618 | `jdg.kks.a56.r9` |  | Art. 56 par. 4 KKS |
| 3619 | `jdg.kks.a57.r1` |  | Art. 57 KKS |
| 3620 | `jdg.kks.a57.r10` |  | Art. 57 par. 5 KKS |
| 3621 | `jdg.kks.a57.r11` |  | Art. 56 par. 5 w zw. z Art. 57 KKS |
| 3622 | `jdg.kks.a57.r2` |  | Art. 57 KKS |
| 3623 | `jdg.kks.a57.r6` |  | Art. 57 par. 1 KKS |
| 3624 | `jdg.kks.a57.r7` |  | Art. 57 par. 2 KKS |
| 3625 | `jdg.kks.a57.r8` |  | Art. 57 par. 3 KKS |
| 3626 | `jdg.kks.a57.r9` |  | Art. 57 par. 4 w zw. z par. 10 JPK_VAT |
| 3627 | `jdg.kks.a58.r1` |  | Art. 58 KKS |
| 3628 | `jdg.kks.a58.r2` |  | Art. 58 KKS |
| 3629 | `jdg.kks.a59.r1` |  | Art. 59 KKS |
| 3630 | `jdg.kks.a60.r1` |  | Art. 60 KKS |
| 3631 | `jdg.kks.a61.r1` |  | Art. 61 KKS |
| 3632 | `jdg.kks.a62.r1` |  | Art. 62 KKS |
| 3633 | `jdg.kks.a63.r1` |  | Art. 63 KKS |
| 3634 | `jdg.kks.a64.r1` |  | Art. 64 KKS |
| 3635 | `jdg.kks.a77.r6` |  | Art. 77 par. 1 KKS |
| 3636 | `jdg.kks.a77.r7` |  | Art. 77 par. 2 KKS |
| 3637 | `jdg.kks.a77.r8` |  | Art. 77 par. 3 KKS |
| 3638 | `jdg.kks.a77.r9` |  | Art. 77 par. 4 KKS |
| 3639 | `jdg.kks.a80.r1` |  | Art. 80 par. 1 KKS |
| 3640 | `jdg.kks.a80.r2` |  | Art. 80 par. 2 KKS |
| 3641 | `jdg.kks.a80.r3` |  | Art. 80 par. 3 KKS |
| 3642 | `jdg.kks.a80.r4` |  | Art. 80 par. 4 KKS |
| 3643 | `jdg.kks.a80.r5` |  | Art. 80 par. 5 KKS |
| 3644 | `jdg.kks.mit.r1` |  |  |
| 3645 | `jdg.kks.mit.r10` |  |  |
| 3646 | `jdg.kks.mit.r2` |  |  |
| 3647 | `jdg.kks.mit.r3` |  |  |
| 3648 | `jdg.kks.mit.r4` |  |  |
| 3649 | `jdg.kks.mit.r5` |  |  |
| 3650 | `jdg.kks.mit.r6` |  |  |
| 3651 | `jdg.kks.mit.r7` |  |  |
| 3652 | `jdg.kks.mit.r8` |  |  |
| 3653 | `jdg.kks.mit.r9` |  |  |
| 3654 | `jdg.kks.pen.r1` |  |  |
| 3655 | `jdg.kks.pen.r10` |  |  |
| 3656 | `jdg.kks.pen.r2` |  |  |
| 3657 | `jdg.kks.pen.r3` |  |  |
| 3658 | `jdg.kks.pen.r4` |  |  |
| 3659 | `jdg.kks.pen.r5` |  |  |
| 3660 | `jdg.kks.pen.r6` |  |  |
| 3661 | `jdg.kks.pen.r7` |  |  |
| 3662 | `jdg.kks.pen.r8` |  |  |
| 3663 | `jdg.kks.pen.r9` |  |  |

### `rules/micro/plan33_ksef.rego` (74 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 5600 | `jdg.ksef.a106na.r10` |  | Art. 106na ust. 3 VAT |
| 5601 | `jdg.ksef.a106na.r11` |  | Art. 106na ust. 4 VAT |
| 5602 | `jdg.ksef.a106na.r12` |  | Art. 106na ust. 5 VAT |
| 5603 | `jdg.ksef.a106na.r13` |  | Art. 106na ust. 6 VAT |
| 5604 | `jdg.ksef.a106na.r14` |  | Art. 106na ust. 7 VAT |
| 5605 | `jdg.ksef.a106na.r15` |  | Art. 106na ust. 8 VAT |
| 5606 | `jdg.ksef.a106na.r16` |  | Art. 106na ust. 9 pkt 1 |
| 5607 | `jdg.ksef.a106na.r17` |  | Art. 106na ust. 9 pkt 2 |
| 5608 | `jdg.ksef.a106na.r18` |  | Art. 106na ust. 9 pkt 3 |
| 5609 | `jdg.ksef.a106na.r19` |  | Art. 106na ust. 9 pkt 4 |
| 5610 | `jdg.ksef.a106na.r20` |  | Art. 106na ust. 9 pkt 5 |
| 5611 | `jdg.ksef.a106na.r21` |  | Art. 106na ust. 9 pkt 6-8 |
| 5612 | `jdg.ksef.a106na.r22` |  | Art. 106na ust. 9 pkt 9 |
| 5613 | `jdg.ksef.a106na.r8` |  | Art. 106na ust. 1 VAT |
| 5614 | `jdg.ksef.a106na.r9` |  | Art. 106na ust. 2 VAT |
| 5615 | `jdg.ksef.a106nb.r1` |  | Art. 106nb ust. 1 VAT |
| 5616 | `jdg.ksef.a106nb.r2` |  | Art. 106nb ust. 2 VAT |
| 5617 | `jdg.ksef.a106nb.r3` |  | Art. 106nb ust. 3 VAT |
| 5618 | `jdg.ksef.a106nb.r4` |  | Art. 106nb ust. 4 VAT |
| 5619 | `jdg.ksef.a106nb.r5` |  | Art. 106nb ust. 5 VAT |
| 5620 | `jdg.ksef.a106nc.r1` |  | Art. 106nc ust. 1 VAT |
| 5621 | `jdg.ksef.a106nc.r2` |  | Art. 106nc ust. 2 VAT |
| 5622 | `jdg.ksef.a106nc.r3` |  | Art. 106nc ust. 3 VAT |
| 5623 | `jdg.ksef.a106nc.r4` |  | Art. 106nc ust. 4 VAT |
| 5624 | `jdg.ksef.a106nd.r1` |  | Art. 106nd ust. 1 VAT |
| 5625 | `jdg.ksef.a106nd.r2` |  | Art. 106nd ust. 2 VAT |
| 5626 | `jdg.ksef.a106nd.r3` |  | Art. 106nd ust. 3 VAT |
| 5627 | `jdg.ksef.a106nd.r4` |  | Art. 106nd ust. 4 VAT |
| 5628 | `jdg.ksef.a106nd.r5` |  | Art. 106nd ust. 5 VAT |
| 5629 | `jdg.ksef.a106ne.r10` |  | Art. 106ne ust. 7 VAT |
| 5630 | `jdg.ksef.a106ne.r4` |  | Art. 106ne ust. 1 VAT |
| 5631 | `jdg.ksef.a106ne.r5` |  | Art. 106ne ust. 2 VAT |
| 5632 | `jdg.ksef.a106ne.r6` |  | Art. 106ne ust. 3 VAT |
| 5633 | `jdg.ksef.a106ne.r7` |  | Art. 106ne ust. 4 VAT |
| 5634 | `jdg.ksef.a106ne.r8` |  | Art. 106ne ust. 5 VAT |
| 5635 | `jdg.ksef.a106ne.r9` |  | Art. 106ne ust. 6 VAT |
| 5636 | `jdg.ksef.a106nf.r1` |  | Art. 106nf ust. 1 VAT |
| 5637 | `jdg.ksef.a106nf.r2` |  | Art. 106nf ust. 2 VAT |
| 5638 | `jdg.ksef.a106nf.r3` |  | Art. 106nf ust. 3 VAT |
| 5639 | `jdg.ksef.a106nf.r4` |  | Art. 106nf ust. 4 VAT |
| 5640 | `jdg.ksef.a106ng.r3` |  | Art. 106ng ust. 1 VAT |
| 5641 | `jdg.ksef.a106ng.r4` |  | Art. 106ng ust. 2 VAT |
| 5642 | `jdg.ksef.a106ng.r5` |  | Art. 106ng ust. 3 VAT |
| 5643 | `jdg.ksef.a106nh.r3` |  | Art. 106nh ust. 1 VAT |
| 5644 | `jdg.ksef.a106nh.r4` |  | Art. 106nh ust. 2 VAT |
| 5645 | `jdg.ksef.a106nh.r5` |  | Art. 106nh ust. 3 VAT |
| 5646 | `jdg.ksef.a106nq.r2` |  | Art. 106nq ust. 1 VAT |
| 5647 | `jdg.ksef.a106nq.r3` |  | Art. 106nq ust. 2 VAT |
| 5648 | `jdg.ksef.a106nq.r4` |  | Art. 106nq ust. 3 VAT |
| 5649 | `jdg.ksef.r1` |  |  |
| 5650 | `jdg.ksef.r10` |  |  |
| 5651 | `jdg.ksef.r11` |  |  |
| 5652 | `jdg.ksef.r12` |  |  |
| 5653 | `jdg.ksef.r13` |  |  |
| 5654 | `jdg.ksef.r14` |  |  |
| 5655 | `jdg.ksef.r15` |  |  |
| 5656 | `jdg.ksef.r16` |  |  |
| 5657 | `jdg.ksef.r17` |  |  |
| 5658 | `jdg.ksef.r18` |  |  |
| 5659 | `jdg.ksef.r19` |  |  |
| 5660 | `jdg.ksef.r2` |  |  |
| 5661 | `jdg.ksef.r20` |  |  |
| 5662 | `jdg.ksef.r21` |  |  |
| 5663 | `jdg.ksef.r22` |  |  |
| 5664 | `jdg.ksef.r23` |  |  |
| 5665 | `jdg.ksef.r24` |  |  |
| 5666 | `jdg.ksef.r25` |  |  |
| 5667 | `jdg.ksef.r3` |  |  |
| 5668 | `jdg.ksef.r4` |  |  |
| 5669 | `jdg.ksef.r5` |  |  |
| 5670 | `jdg.ksef.r6` |  |  |
| 5671 | `jdg.ksef.r7` |  |  |
| 5672 | `jdg.ksef.r8` |  |  |
| 5673 | `jdg.ksef.r9` |  |  |

### `rules/micro/plan33_mdr.rego` (10 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 6800 | `jdg.mdr.r1` |  |  |
| 6801 | `jdg.mdr.r10` |  |  |
| 6802 | `jdg.mdr.r2` |  |  |
| 6803 | `jdg.mdr.r3` |  |  |
| 6804 | `jdg.mdr.r4` |  |  |
| 6805 | `jdg.mdr.r5` |  |  |
| 6806 | `jdg.mdr.r6` |  |  |
| 6807 | `jdg.mdr.r7` |  |  |
| 6808 | `jdg.mdr.r8` |  |  |
| 6809 | `jdg.mdr.r9` |  |  |

### `rules/micro/plan33_pcc.rego` (59 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 4000 | `jdg.pcc.a1.r1` |  | Art. 1 ust. 1 pkt 1 + Art. 7 |
| 4001 | `jdg.pcc.a1.r10` |  | Art. 1 ust. 1 pkt 3 + Art. 7 |
| 4002 | `jdg.pcc.a1.r11` |  | Art. 1 ust. 1 pkt 3 ustawy o PCC |
| 4003 | `jdg.pcc.a1.r12` |  | Art. 1 ust. 1 pkt 4 ustawy o PCC |
| 4004 | `jdg.pcc.a1.r13` |  | Art. 1 ust. 1 pkt 5 ustawy o PCC |
| 4005 | `jdg.pcc.a1.r14` |  | Art. 1 ust. 1 pkt 6 ustawy o PCC |
| 4006 | `jdg.pcc.a1.r15` |  | Art. 1 ust. 1 pkt 7 ustawy o PCC |
| 4007 | `jdg.pcc.a1.r16` |  | Art. 1 ust. 1 pkt 8 ustawy o PCC |
| 4008 | `jdg.pcc.a1.r17` |  | Art. 1 ust. 1 pkt 9 ustawy o PCC |
| 4009 | `jdg.pcc.a1.r18` |  | Art. 1 ust. 1 pkt 10 ustawy o PCC |
| 4010 | `jdg.pcc.a1.r2` |  | Art. 1 ust. 1 pkt 1 + Art. 7 |
| 4011 | `jdg.pcc.a1.r3` |  | Art. 1 ust. 1 pkt 1 + Art. 7 |
| 4012 | `jdg.pcc.a1.r4` |  | Art. 1 ust. 1 pkt 1 + Art. 7 |
| 4013 | `jdg.pcc.a1.r5` |  | Art. 1 ust. 1 pkt 2 + Art. 7 |
| 4014 | `jdg.pcc.a1.r6` |  | Art. 1 ust. 1 pkt 2 + Art. 7 |
| 4015 | `jdg.pcc.a1.r7` |  | Art. 1 ust. 1 pkt 2 + Art. 7 |
| 4016 | `jdg.pcc.a1.r8` |  | Art. 1 ust. 1 pkt 2 + Art. 7 |
| 4017 | `jdg.pcc.a1.r9` |  | Art. 1 ust. 1 pkt 2 + Art. 7 |
| 4018 | `jdg.pcc.a10.r1` |  | Art. 10 ust. 1 ustawy o PCC |
| 4019 | `jdg.pcc.a10.r2` |  | Art. 10 ust. 2 ustawy o PCC |
| 4020 | `jdg.pcc.a10.r3` |  | Art. 10 ust. 3 ustawy o PCC |
| 4021 | `jdg.pcc.a10.r4` |  | Art. 10 ust. 4 ustawy o PCC |
| 4022 | `jdg.pcc.a12.r1` |  | Art. 12 ust. 1 ustawy o PCC |
| 4023 | `jdg.pcc.a12.r2` |  | Art. 12 ust. 2 ustawy o PCC |
| 4024 | `jdg.pcc.a12.r3` |  | Art. 12 ust. 3 ustawy o PCC |
| 4025 | `jdg.pcc.a12.r4` |  | Art. 12 ust. 4 ustawy o PCC |
| 4026 | `jdg.pcc.a12.r5` |  | Art. 12 ust. 5 ustawy o PCC |
| 4027 | `jdg.pcc.a12.r6` |  | Art. 12 ust. 6 ustawy o PCC |
| 4028 | `jdg.pcc.a2.r1` |  | Art. 2 pkt 4 |
| 4029 | `jdg.pcc.a2.r2` |  | Art. 2 pkt 4 |
| 4030 | `jdg.pcc.a2.r3` |  | Art. 2 pkt 2 |
| 4031 | `jdg.pcc.a2.r4` |  | Art. 2 pkt 1 |
| 4032 | `jdg.pcc.a2.r5` |  | Art. 2 pkt 1 |
| 4033 | `jdg.pcc.a2.r6` |  | Art. 9 pkt 10 |
| 4034 | `jdg.pcc.a2.r7` |  | Art. 9 pkt 17 |
| 4035 | `jdg.pcc.a2.r8` |  | Art. 9 pkt 17 |
| 4036 | `jdg.pcc.a3.r1` |  | Art. 4 |
| 4037 | `jdg.pcc.a3.r2` |  | Art. 4 |
| 4038 | `jdg.pcc.a4.r1` |  | Art. 6 |
| 4039 | `jdg.pcc.a4.r2` |  | Art. 6 |
| 4040 | `jdg.pcc.a5.r1` |  | Art. 10 |
| 4041 | `jdg.pcc.a5.r2` |  | Art. 10 |
| 4042 | `jdg.pcc.a5.r3` |  | Art. 10 |
| 4043 | `jdg.pcc.a5.r4` |  | Art. 5 ust. 4 ustawy o PCC |
| 4044 | `jdg.pcc.a6.r1` |  | Art. 6 ust. 1 pkt 1 ustawy o PCC |
| 4045 | `jdg.pcc.a6.r2` |  | Art. 6 ust. 1 pkt 2 ustawy o PCC |
| 4046 | `jdg.pcc.a6.r3` |  | Art. 6 ust. 1 pkt 3 ustawy o PCC |
| 4047 | `jdg.pcc.a6.r4` |  | Art. 6 ust. 1 pkt 4 ustawy o PCC |
| 4048 | `jdg.pcc.a6.r5` |  | Art. 6 ust. 1 pkt 4 ustawy o PCC |
| 4049 | `jdg.pcc.a7.r1` |  | Art. 7 ust. 1 pkt 1 ustawy o PCC |
| 4050 | `jdg.pcc.a7.r2` |  | Art. 7 ust. 1 pkt 2 ustawy o PCC |
| 4051 | `jdg.pcc.a7.r3` |  | Art. 7 ust. 1 pkt 4 ustawy o PCC |
| 4052 | `jdg.pcc.a7.r4` |  | Art. 7 ust. 1 pkt 5 ustawy o PCC |
| 4053 | `jdg.pcc.a7.r5` |  | Art. 7 ust. 1 pkt 6 ustawy o PCC |
| 4054 | `jdg.pcc.a7.r6` |  | Art. 7 ust. 1 pkt 7 ustawy o PCC |
| 4055 | `jdg.pcc.a7.r7` |  | Art. 7 ust. 2 ustawy o PCC |
| 4056 | `jdg.pcc.a7.r8` |  | Art. 7 ust. 3 ustawy o PCC |
| 4057 | `jdg.pcc.a8.r1` |  | Art. 8 pkt 1 ustawy o PCC |
| 4058 | `jdg.pcc.a8.r2` |  | Art. 8 pkt 2 ustawy o PCC |

### `rules/micro/plan33_pit.rego` (86 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1200 | `jdg.pit.a14.r10` |  |  |
| 1201 | `jdg.pit.a14.r11` |  |  |
| 1202 | `jdg.pit.a14.r12` |  |  |
| 1203 | `jdg.pit.a14.r15` |  |  |
| 1204 | `jdg.pit.a14.r17` |  |  |
| 1205 | `jdg.pit.a14.r18` |  |  |
| 1206 | `jdg.pit.a14.r19` |  |  |
| 1207 | `jdg.pit.a14.r4` |  |  |
| 1208 | `jdg.pit.a14.r9` |  |  |
| 1209 | `jdg.pit.a14c.r10` |  |  |
| 1210 | `jdg.pit.a14c.r3` |  |  |
| 1211 | `jdg.pit.a14c.r4` |  |  |
| 1212 | `jdg.pit.a14c.r6` |  |  |
| 1213 | `jdg.pit.a14c.r8` |  |  |
| 1214 | `jdg.pit.a14c.r9` |  |  |
| 1215 | `jdg.pit.a22.r11` |  |  |
| 1216 | `jdg.pit.a22.r14` |  |  |
| 1217 | `jdg.pit.a22.r2` |  |  |
| 1218 | `jdg.pit.a22.r5` |  |  |
| 1219 | `jdg.pit.a22.r9` |  |  |
| 1220 | `jdg.pit.a23.r10` |  | Art. 23 ust. 1 pkt 30 |
| 1221 | `jdg.pit.a23.r11` |  | Wyjątek (są KUP) |
| 1222 | `jdg.pit.a23.r13` |  | Art. 23 ust. 1 pkt 47a |
| 1223 | `jdg.pit.a23.r14` |  | Art. 23 ust. 1 pkt 47a |
| 1224 | `jdg.pit.a23.r16` |  | Limit 150k |
| 1225 | `jdg.pit.a23.r18` |  | Art. 23 ust. 1 pkt 46 |
| 1226 | `jdg.pit.a23.r19` |  | Art. 23 ust. 1 pkt 42 |
| 1227 | `jdg.pit.a23.r20` |  | Wyjątek |
| 1228 | `jdg.pit.a23.r22` |  | Art. 23 ust. 1 pkt 19 |
| 1229 | `jdg.pit.a23.r25` |  | Art. 23 ust. 1 pkt 1 |
| 1230 | `jdg.pit.a23.r5` |  | Art. 23 ust. 1 pkt 23 |
| 1231 | `jdg.pit.a23.r7` |  | Art. 23 ust. 1 pkt 19 |
| 1232 | `jdg.pit.a23.r9` |  | Wyjątek |
| 1233 | `jdg.pit.a26h.r6` |  |  |
| 1234 | `jdg.pit.a27.r11` |  |  |
| 1235 | `jdg.pit.a27.r12` |  |  |
| 1236 | `jdg.pit.a27.r5` |  |  |
| 1237 | `jdg.pit.a27.r6` |  |  |
| 1238 | `jdg.pit.a27.r7` |  |  |
| 1239 | `jdg.pit.a27.r8` |  |  |
| 1240 | `jdg.pit.a27.r9` |  |  |
| 1241 | `jdg.pit.a27a.r10` |  |  |
| 1242 | `jdg.pit.a30a.r10` |  |  |
| 1243 | `jdg.pit.a30a.r3` |  |  |
| 1244 | `jdg.pit.a30a.r4` |  |  |
| 1245 | `jdg.pit.a30a.r5` |  |  |
| 1246 | `jdg.pit.a30a.r6` |  |  |
| 1247 | `jdg.pit.a30a.r9` |  |  |
| 1248 | `jdg.pit.a30b.r10` |  |  |
| 1249 | `jdg.pit.a30b.r3` |  |  |
| 1250 | `jdg.pit.a30b.r4` |  |  |
| 1251 | `jdg.pit.a30b.r5` |  |  |
| 1252 | `jdg.pit.a30b.r7` |  |  |
| 1253 | `jdg.pit.a30b.r8` |  |  |
| 1254 | `jdg.pit.a30b.r9` |  |  |
| 1255 | `jdg.pit.a31.r10` |  |  |
| 1256 | `jdg.pit.a31.r11` |  |  |
| 1257 | `jdg.pit.a31.r12` |  |  |
| 1258 | `jdg.pit.a31.r13` |  |  |
| 1259 | `jdg.pit.a31.r15` |  |  |
| 1260 | `jdg.pit.a31.r16` |  |  |
| 1261 | `jdg.pit.a31.r17` |  |  |
| 1262 | `jdg.pit.a31.r18` |  |  |
| 1263 | `jdg.pit.a31.r19` |  |  |
| 1264 | `jdg.pit.a31.r20` |  |  |
| 1265 | `jdg.pit.a31.r21` |  |  |
| 1266 | `jdg.pit.a31.r4` |  |  |
| 1267 | `jdg.pit.a31.r7` |  |  |
| 1268 | `jdg.pit.a31.r8` |  |  |
| 1269 | `jdg.pit.a31.r9` |  |  |
| 1270 | `jdg.pit.a32.r3` |  |  |
| 1271 | `jdg.pit.a32.r4` |  |  |
| 1272 | `jdg.pit.a32.r5` |  |  |
| 1273 | `jdg.pit.a44.r1` |  |  |
| 1274 | `jdg.pit.a44.r2` |  |  |
| 1275 | `jdg.pit.a44.r3` |  |  |
| 1276 | `jdg.pit.a45.r11` |  |  |
| 1277 | `jdg.pit.a45.r12` |  |  |
| 1278 | `jdg.pit.a45.r4` |  |  |
| 1279 | `jdg.pit.a45.r6` |  |  |
| 1280 | `jdg.pit.a45.r8` |  |  |
| 1281 | `jdg.pit.a9a.r10` |  |  |
| 1282 | `jdg.pit.a9a.r3` |  |  |
| 1283 | `jdg.pit.a9a.r6` |  |  |
| 1284 | `jdg.pit.a9a.r8` |  |  |
| 1285 | `jdg.pit.a9a.r9` |  |  |

### `rules/micro/plan33_prop.rego` (30 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 7100 | `jdg.prop.a1.r1` |  | Ustawa o podatkach i opłatach lokalnych Art. 5 |
| 7101 | `jdg.prop.a1.r2` |  | Art. 5 ust. 1 pkt 2 lit. a |
| 7102 | `jdg.prop.a1.r3` |  | Art. 5 ust. 1 pkt 2 lit. b |
| 7103 | `jdg.prop.a1.r4` |  | Art. 5 ust. 1 pkt 3 |
| 7104 | `jdg.prop.a1.r5` |  | Art. 5 ust. 1 |
| 7105 | `jdg.prop.a1.r6` |  | Art. 5 ust. 1 |
| 7106 | `jdg.prop.a1.r7` |  | Art. 5 ust. 1 pkt 2 |
| 7107 | `jdg.prop.a2.r1` |  | Art. 6 ust. 1 u.p.o.l. |
| 7108 | `jdg.prop.a2.r2` |  | Art. 7 ust. 1 u.p.o.l. |
| 7109 | `jdg.prop.a2.r3` |  | Art. 7 ust. 2 u.p.o.l. |
| 7110 | `jdg.prop.r1` |  | Art. 5 ust. 1 |
| 7111 | `jdg.prop.r10` |  | Art. 3 |
| 7112 | `jdg.prop.r11` |  | Art. 3 |
| 7113 | `jdg.prop.r12` |  | Art. 5 |
| 7114 | `jdg.prop.r13` |  | Art. 5 |
| 7115 | `jdg.prop.r14` |  | Art. 6 |
| 7116 | `jdg.prop.r15` |  | Art. 6 |
| 7117 | `jdg.prop.r16` |  | Art. 6 |
| 7118 | `jdg.prop.r17` |  | Art. 6 |
| 7119 | `jdg.prop.r18` |  | Art. 7 |
| 7120 | `jdg.prop.r19` |  | Art. 7 |
| 7121 | `jdg.prop.r2` |  | Art. 5 ust. 1 |
| 7122 | `jdg.prop.r20` |  |  |
| 7123 | `jdg.prop.r3` |  | Art. 5 ust. 1 |
| 7124 | `jdg.prop.r4` |  | Art. 5 ust. 1 |
| 7125 | `jdg.prop.r5` |  | Art. 5 ust. 1 |
| 7126 | `jdg.prop.r6` |  | Art. 5 ust. 1 |
| 7127 | `jdg.prop.r7` |  | Art. 5 ust. 1 |
| 7128 | `jdg.prop.r8` |  | Art. 1a |
| 7129 | `jdg.prop.r9` |  | Art. 3 |

### `rules/micro/plan33_prop_transport.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 7550 | `jdg.prop_transport.r1` |  | Art. 8 u.p.o.l. |
| 7551 | `jdg.prop_transport.r2` |  | Art. 8 ust. 2 u.p.o.l. |
| 7552 | `jdg.prop_transport.r3` |  | Art. 8 ust. 3 u.p.o.l. |
| 7553 | `jdg.prop_transport.r4` |  | Art. 8 ust. 4 u.p.o.l. |
| 7554 | `jdg.prop_transport.r5` |  | Art. 9 u.p.o.l. |

### `rules/micro/plan33_rodo.rego` (10 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 6900 | `jdg.rodo.r1` |  |  |
| 6901 | `jdg.rodo.r10` |  |  |
| 6902 | `jdg.rodo.r2` |  |  |
| 6903 | `jdg.rodo.r3` |  |  |
| 6904 | `jdg.rodo.r4` |  |  |
| 6905 | `jdg.rodo.r5` |  |  |
| 6906 | `jdg.rodo.r6` |  |  |
| 6907 | `jdg.rodo.r7` |  |  |
| 6908 | `jdg.rodo.r8` |  |  |
| 6909 | `jdg.rodo.r9` |  |  |

### `rules/micro/plan33_ryc.rego` (158 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 3000 | `jdg.ryc.a10.r1` |  | Art. 10 ust. 1 ustawy o ryczałcie |
| 3001 | `jdg.ryc.a10.r2` |  | Art. 10 ust. 2 ustawy o ryczałcie |
| 3002 | `jdg.ryc.a10.r3` |  | Art. 10 ust. 3 ustawy o ryczałcie |
| 3003 | `jdg.ryc.a10.r4` |  | Art. 10 ust. 4 ustawy o ryczałcie |
| 3004 | `jdg.ryc.a11.r1` |  | Art. 11 ust. 1 ustawy o ryczałcie |
| 3005 | `jdg.ryc.a11.r2` |  | Art. 11 ust. 2 ustawy o ryczałcie |
| 3006 | `jdg.ryc.a11.r3` |  | Art. 11 ust. 3 ustawy o ryczałcie |
| 3007 | `jdg.ryc.a11.r4` |  | Art. 11 ust. 4 ustawy o ryczałcie |
| 3008 | `jdg.ryc.a11.r5` |  | Art. 11 ust. 5 ustawy o ryczałcie |
| 3009 | `jdg.ryc.a11.r6` |  | Art. 11 ust. 6 ustawy o ryczałcie |
| 3010 | `jdg.ryc.a12.r1` |  | Art. 12 ust. 1 pkt 1 |
| 3011 | `jdg.ryc.a12.r10` |  | Art. 12 ust. 1 pkt 7 |
| 3012 | `jdg.ryc.a12.r2` |  | Art. 12 ust. 1 pkt 2 |
| 3013 | `jdg.ryc.a12.r3` |  | Art. 12 ust. 1 pkt 2b |
| 3014 | `jdg.ryc.a12.r4` |  | Art. 12 ust. 1 pkt 2a |
| 3015 | `jdg.ryc.a12.r5` |  | Art. 12 ust. 1 pkt 3 |
| 3016 | `jdg.ryc.a12.r6` |  | Art. 12 ust. 1 pkt 5 |
| 3017 | `jdg.ryc.a12.r7` |  | Art. 12 ust. 1 pkt 5 lit. a |
| 3018 | `jdg.ryc.a12.r8` |  | Art. 12 ust. 1 pkt 6 |
| 3019 | `jdg.ryc.a12.r9` |  | Art. 12 ust. 1 pkt 4 |
| 3020 | `jdg.ryc.a14.r1` |  | Art. 14 ust. 1 pkt 1 |
| 3021 | `jdg.ryc.a14.r10` |  | Art. 14 ust. 8 |
| 3022 | `jdg.ryc.a14.r2` |  | Art. 14 ust. 1 pkt 2 |
| 3023 | `jdg.ryc.a14.r3` |  | Art. 14 ust. 1 pkt 2 |
| 3024 | `jdg.ryc.a14.r4` |  | Art. 14 ust. 2 |
| 3025 | `jdg.ryc.a14.r5` |  | Art. 14 ust. 3 |
| 3026 | `jdg.ryc.a14.r6` |  | Art. 14 ust. 4 |
| 3027 | `jdg.ryc.a14.r7` |  | Art. 14 ust. 5 |
| 3028 | `jdg.ryc.a14.r8` |  | Art. 14 ust. 6 |
| 3029 | `jdg.ryc.a14.r9` |  | Art. 14 ust. 7 |
| 3030 | `jdg.ryc.a16.r1` |  | Art. 16 ust. 1 |
| 3031 | `jdg.ryc.a16.r2` |  | Art. 16 ust. 2 |
| 3032 | `jdg.ryc.a16.r3` |  | Art. 16 ust. 3 |
| 3033 | `jdg.ryc.a16.r4` |  | Art. 16 ust. 4 |
| 3034 | `jdg.ryc.a16.r5` |  | Art. 16 ust. 5 |
| 3035 | `jdg.ryc.a2.r1` |  |  |
| 3036 | `jdg.ryc.a2.r10` |  |  |
| 3037 | `jdg.ryc.a2.r11` |  |  |
| 3038 | `jdg.ryc.a2.r12` |  |  |
| 3039 | `jdg.ryc.a2.r13` |  | Art. 2 ust. 1, Art. 12 ust. 1 pkt 2a |
| 3040 | `jdg.ryc.a2.r14` |  | Art. 2 ust. 1, Art. 12 ust. 1 pkt 3 |
| 3041 | `jdg.ryc.a2.r15` |  | Art. 2 ust. 1, Art. 12 ust. 1 pkt 5/4 |
| 3042 | `jdg.ryc.a2.r2` |  |  |
| 3043 | `jdg.ryc.a2.r3` |  |  |
| 3044 | `jdg.ryc.a2.r4` |  |  |
| 3045 | `jdg.ryc.a2.r5` |  |  |
| 3046 | `jdg.ryc.a2.r6` |  |  |
| 3047 | `jdg.ryc.a2.r7` |  |  |
| 3048 | `jdg.ryc.a2.r8` |  |  |
| 3049 | `jdg.ryc.a2.r9` |  |  |
| 3050 | `jdg.ryc.a20.r1` |  | Art. 20 ust. 1 |
| 3051 | `jdg.ryc.a20.r10` |  | Art. 20 ust. 10 |
| 3052 | `jdg.ryc.a20.r2` |  | Art. 20 ust. 2 |
| 3053 | `jdg.ryc.a20.r3` |  | Art. 20 ust. 3 |
| 3054 | `jdg.ryc.a20.r4` |  | Art. 20 ust. 4 |
| 3055 | `jdg.ryc.a20.r5` |  | Art. 20 ust. 5 |
| 3056 | `jdg.ryc.a20.r6` |  | Art. 20 ust. 6 |
| 3057 | `jdg.ryc.a20.r7` |  | Art. 20 ust. 7 |
| 3058 | `jdg.ryc.a20.r8` |  | Art. 20 ust. 8 |
| 3059 | `jdg.ryc.a20.r9` |  | Art. 20 ust. 9 |
| 3060 | `jdg.ryc.a21.r1` |  | Art. 21 ust. 1 |
| 3061 | `jdg.ryc.a21.r2` |  | Art. 21 ust. 2 |
| 3062 | `jdg.ryc.a21.r3` |  | Art. 21 ust. 3 |
| 3063 | `jdg.ryc.a21.r4` |  | Art. 21 ust. 4 |
| 3064 | `jdg.ryc.a21.r5` |  | Art. 21 ust. 5 |
| 3065 | `jdg.ryc.a24.r1` |  | Art. 24 ust. 1 |
| 3066 | `jdg.ryc.a24.r2` |  | Art. 24 ust. 2 |
| 3067 | `jdg.ryc.a24.r3` |  | Art. 24 ust. 3 |
| 3068 | `jdg.ryc.a25.r1` |  | Art. 25 ust. 1 |
| 3069 | `jdg.ryc.a25.r2` |  | Art. 25 ust. 2 |
| 3070 | `jdg.ryc.a25.r3` |  | Art. 25 ust. 3 |
| 3071 | `jdg.ryc.a25.r4` |  | Art. 25 ust. 4 |
| 3072 | `jdg.ryc.a25.r5` |  | Art. 25 ust. 5 |
| 3073 | `jdg.ryc.a25.r6` |  | Art. 25 ust. 6 |
| 3074 | `jdg.ryc.a25.r7` |  | Art. 25 ust. 7 |
| 3075 | `jdg.ryc.a3.r1` |  |  |
| 3076 | `jdg.ryc.a3.r2` |  |  |
| 3077 | `jdg.ryc.a3.r3` |  |  |
| 3078 | `jdg.ryc.a4.r1` |  | Art. 4 ust. 1 ustawy o ryczałcie |
| 3079 | `jdg.ryc.a4.r10` |  | Art. 4 ust. 6 ustawy o ryczałcie |
| 3080 | `jdg.ryc.a4.r2` |  | Art. 4 ust. 2 ustawy o ryczałcie |
| 3081 | `jdg.ryc.a4.r3` |  | Art. 4 ust. 3 ustawy o ryczałcie |
| 3082 | `jdg.ryc.a4.r4` |  | Art. 4 ust. 4 ustawy o ryczałcie |
| 3083 | `jdg.ryc.a4.r5` |  | Art. 4 ust. 4 pkt 1 ustawy o ryczałcie |
| 3084 | `jdg.ryc.a4.r6` |  | Art. 4 ust. 4 pkt 2 ustawy o ryczałcie |
| 3085 | `jdg.ryc.a4.r7` |  | Art. 4 ust. 4 pkt 3 ustawy o ryczałcie |
| 3086 | `jdg.ryc.a4.r8` |  | Art. 4 ust. 4 pkt 3 ustawy o ryczałcie |
| 3087 | `jdg.ryc.a4.r9` |  | Art. 4 ust. 5 ustawy o ryczałcie |
| 3088 | `jdg.ryc.a6.r10` |  | Art. 6 ust. 1 pkt 5 ustawy o ryczałcie |
| 3089 | `jdg.ryc.a6.r11` |  | Art. 6 ust. 1 pkt 6 ustawy o ryczałcie |
| 3090 | `jdg.ryc.a6.r12` |  | Art. 6 ust. 1 pkt 7 ustawy o ryczałcie |
| 3091 | `jdg.ryc.a6.r13` |  | Art. 6 ust. 1 pkt 8 ustawy o ryczałcie |
| 3092 | `jdg.ryc.a6.r14` |  | Art. 6 ust. 1 pkt 9 ustawy o ryczałcie |
| 3093 | `jdg.ryc.a6.r15` |  | Art. 6 ust. 1 pkt 10 ustawy o ryczałcie |
| 3094 | `jdg.ryc.a6.r6` |  | Art. 6 ust. 1 pkt 1 ustawy o ryczałcie |
| 3095 | `jdg.ryc.a6.r7` |  | Art. 6 ust. 1 pkt 1 ustawy o ryczałcie |
| 3096 | `jdg.ryc.a6.r8` |  | Art. 6 ust. 1 pkt 3 ustawy o ryczałcie |
| 3097 | `jdg.ryc.a6.r9` |  | Art. 6 ust. 1 pkt 4 ustawy o ryczałcie |
| 3098 | `jdg.ryc.a7.r1` |  | Art. 7 ust. 1 ustawy o ryczałcie |
| 3099 | `jdg.ryc.a7.r2` |  | Art. 7 ust. 2 ustawy o ryczałcie |
| 3100 | `jdg.ryc.a7.r3` |  | Art. 7 ust. 3 ustawy o ryczałcie |
| 3101 | `jdg.ryc.a7.r4` |  | Art. 7 ust. 4 ustawy o ryczałcie |
| 3102 | `jdg.ryc.a7.r5` |  | Art. 7 ust. 5 ustawy o ryczałcie |
| 3103 | `jdg.ryc.a8.r1` |  | Art. 8 ust. 1 ustawy o ryczałcie |
| 3104 | `jdg.ryc.a8.r2` |  | Art. 8 ust. 2 ustawy o ryczałcie |
| 3105 | `jdg.ryc.a8.r3` |  | Art. 8 ust. 3 ustawy o ryczałcie |
| 3106 | `jdg.ryc.a8.r4` |  | Art. 8 ust. 4 ustawy o ryczałcie |
| 3107 | `jdg.ryc.a8.r5` |  | Art. 8 ust. 5 ustawy o ryczałcie |
| 3108 | `jdg.ryc.calc.r1` |  |  |
| 3109 | `jdg.ryc.calc.r10` |  |  |
| 3110 | `jdg.ryc.calc.r11` |  |  |
| 3111 | `jdg.ryc.calc.r12` |  |  |
| 3112 | `jdg.ryc.calc.r13` |  |  |
| 3113 | `jdg.ryc.calc.r14` |  |  |
| 3114 | `jdg.ryc.calc.r15` |  |  |
| 3115 | `jdg.ryc.calc.r16` |  |  |
| 3116 | `jdg.ryc.calc.r17` |  |  |
| 3117 | `jdg.ryc.calc.r18` |  |  |
| 3118 | `jdg.ryc.calc.r19` |  |  |
| 3119 | `jdg.ryc.calc.r2` |  |  |
| 3120 | `jdg.ryc.calc.r20` |  |  |
| 3121 | `jdg.ryc.calc.r3` |  |  |
| 3122 | `jdg.ryc.calc.r4` |  |  |
| 3123 | `jdg.ryc.calc.r5` |  |  |
| 3124 | `jdg.ryc.calc.r6` |  |  |
| 3125 | `jdg.ryc.calc.r7` |  |  |
| 3126 | `jdg.ryc.calc.r8` |  |  |
| 3127 | `jdg.ryc.calc.r9` |  |  |
| 3128 | `jdg.ryc.rate.r1` |  | Art. 12 ust. 1 pkt 5 |
| 3129 | `jdg.ryc.rate.r10` |  |  |
| 3130 | `jdg.ryc.rate.r11` |  | Art. 12 ust. 1 pkt 3b |
| 3131 | `jdg.ryc.rate.r12` |  | Art. 12 ust. 1 pkt 3b |
| 3132 | `jdg.ryc.rate.r13` |  | Art. 12 ust. 1 pkt 3a |
| 3133 | `jdg.ryc.rate.r14` |  | Art. 12 ust. 1 pkt 3a |
| 3134 | `jdg.ryc.rate.r15` |  | Art. 12 ust. 1 pkt 3a |
| 3135 | `jdg.ryc.rate.r16` |  | Art. 12 ust. 1 pkt 3 |
| 3136 | `jdg.ryc.rate.r17` |  | Art. 12 ust. 1 pkt 3 |
| 3137 | `jdg.ryc.rate.r18` |  | Art. 12 ust. 1 pkt 3 |
| 3138 | `jdg.ryc.rate.r19` |  | Art. 12 ust. 1 pkt 3 |
| 3139 | `jdg.ryc.rate.r2` |  | Art. 12 ust. 1 pkt 5 |
| 3140 | `jdg.ryc.rate.r20` |  | Art. 12 ust. 1 pkt 3 |
| 3141 | `jdg.ryc.rate.r21` |  | Art. 12 ust. 1 pkt 2 |
| 3142 | `jdg.ryc.rate.r22` |  | Art. 12 ust. 1 pkt 2 |
| 3143 | `jdg.ryc.rate.r23` |  | Art. 12 ust. 1 pkt 2 |
| 3144 | `jdg.ryc.rate.r24` |  | Art. 12 ust. 1 pkt 2 |
| 3145 | `jdg.ryc.rate.r25` |  | Art. 12 ust. 1 pkt 2 |
| 3146 | `jdg.ryc.rate.r26` |  | Art. 12 ust. 1 pkt 1 |
| 3147 | `jdg.ryc.rate.r27` |  | Art. 12 ust. 1 pkt 1 |
| 3148 | `jdg.ryc.rate.r28` |  | Art. 12 ust. 1 pkt 1a |
| 3149 | `jdg.ryc.rate.r29` |  | Art. 12 ust. 1 pkt 0a |
| 3150 | `jdg.ryc.rate.r3` |  | Art. 12 ust. 1 pkt 5 |
| 3151 | `jdg.ryc.rate.r30` |  |  |
| 3152 | `jdg.ryc.rate.r4` |  | Art. 12 ust. 1 pkt 5 |
| 3153 | `jdg.ryc.rate.r5` |  | Art. 12 ust. 1 pkt 4 |
| 3154 | `jdg.ryc.rate.r6` |  | Art. 12 ust. 1 pkt 4 |
| 3155 | `jdg.ryc.rate.r7` |  | Art. 12 ust. 1 pkt 4 |
| 3156 | `jdg.ryc.rate.r8` |  | Art. 12 ust. 1 pkt 4 |
| 3157 | `jdg.ryc.rate.r9` |  | Art. 12 ust. 1 pkt 3b |

### `rules/micro/plan33_succ.rego` (20 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 5400 | `jdg.succ.r1` |  |  |
| 5401 | `jdg.succ.r10` |  |  |
| 5402 | `jdg.succ.r11` |  |  |
| 5403 | `jdg.succ.r12` |  |  |
| 5404 | `jdg.succ.r13` |  |  |
| 5405 | `jdg.succ.r14` |  |  |
| 5406 | `jdg.succ.r15` |  |  |
| 5407 | `jdg.succ.r16` |  |  |
| 5408 | `jdg.succ.r17` |  |  |
| 5409 | `jdg.succ.r18` |  |  |
| 5410 | `jdg.succ.r19` |  |  |
| 5411 | `jdg.succ.r2` |  |  |
| 5412 | `jdg.succ.r20` |  |  |
| 5413 | `jdg.succ.r3` |  |  |
| 5414 | `jdg.succ.r4` |  |  |
| 5415 | `jdg.succ.r5` |  |  |
| 5416 | `jdg.succ.r6` |  |  |
| 5417 | `jdg.succ.r7` |  |  |
| 5418 | `jdg.succ.r8` |  |  |
| 5419 | `jdg.succ.r9` |  |  |

### `rules/micro/plan33_tax_trans.rego` (10 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 7400 | `jdg.tax_trans.r1` |  |  |
| 7401 | `jdg.tax_trans.r10` |  |  |
| 7402 | `jdg.tax_trans.r2` |  |  |
| 7403 | `jdg.tax_trans.r3` |  |  |
| 7404 | `jdg.tax_trans.r4` |  |  |
| 7405 | `jdg.tax_trans.r5` |  |  |
| 7406 | `jdg.tax_trans.r6` |  |  |
| 7407 | `jdg.tax_trans.r7` |  |  |
| 7408 | `jdg.tax_trans.r8` |  |  |
| 7409 | `jdg.tax_trans.r9` |  |  |

### `rules/micro/plan33_tp.rego` (15 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 6500 | `jdg.tp.r1` |  |  |
| 6501 | `jdg.tp.r10` |  |  |
| 6502 | `jdg.tp.r11` |  |  |
| 6503 | `jdg.tp.r12` |  |  |
| 6504 | `jdg.tp.r13` |  |  |
| 6505 | `jdg.tp.r14` |  |  |
| 6506 | `jdg.tp.r15` |  |  |
| 6507 | `jdg.tp.r2` |  |  |
| 6508 | `jdg.tp.r3` |  |  |
| 6509 | `jdg.tp.r4` |  |  |
| 6510 | `jdg.tp.r5` |  |  |
| 6511 | `jdg.tp.r6` |  |  |
| 6512 | `jdg.tp.r7` |  |  |
| 6513 | `jdg.tp.r8` |  |  |
| 6514 | `jdg.tp.r9` |  |  |

### `rules/micro/plan33_uor.rego` (25 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 4800 | `jdg.uor.r1` |  |  |
| 4801 | `jdg.uor.r10` |  |  |
| 4802 | `jdg.uor.r11` |  |  |
| 4803 | `jdg.uor.r12` |  |  |
| 4804 | `jdg.uor.r13` |  |  |
| 4805 | `jdg.uor.r14` |  |  |
| 4806 | `jdg.uor.r15` |  |  |
| 4807 | `jdg.uor.r16` |  |  |
| 4808 | `jdg.uor.r17` |  |  |
| 4809 | `jdg.uor.r18` |  |  |
| 4810 | `jdg.uor.r19` |  |  |
| 4811 | `jdg.uor.r2` |  |  |
| 4812 | `jdg.uor.r20` |  |  |
| 4813 | `jdg.uor.r21` |  |  |
| 4814 | `jdg.uor.r22` |  |  |
| 4815 | `jdg.uor.r23` |  |  |
| 4816 | `jdg.uor.r24` |  |  |
| 4817 | `jdg.uor.r25` |  |  |
| 4818 | `jdg.uor.r3` |  |  |
| 4819 | `jdg.uor.r4` |  |  |
| 4820 | `jdg.uor.r5` |  |  |
| 4821 | `jdg.uor.r6` |  |  |
| 4822 | `jdg.uor.r7` |  |  |
| 4823 | `jdg.uor.r8` |  |  |
| 4824 | `jdg.uor.r9` |  |  |

### `rules/micro/plan33_vat.rego` (115 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 500 | `jdg.vat.a106e.r11` |  |  |
| 501 | `jdg.vat.a106e.r12` |  |  |
| 502 | `jdg.vat.a106e.r13` |  |  |
| 503 | `jdg.vat.a106e.r15` |  |  |
| 504 | `jdg.vat.a106e.r3` |  |  |
| 505 | `jdg.vat.a106e.r4` |  |  |
| 506 | `jdg.vat.a106e.r7` |  |  |
| 507 | `jdg.vat.a106e.r8` |  |  |
| 508 | `jdg.vat.a106e.r9` |  |  |
| 509 | `jdg.vat.a106j.r10` |  |  |
| 510 | `jdg.vat.a106j.r2` |  |  |
| 511 | `jdg.vat.a106j.r4` |  |  |
| 512 | `jdg.vat.a106j.r5` |  |  |
| 513 | `jdg.vat.a106j.r6` |  |  |
| 514 | `jdg.vat.a106j.r7` |  |  |
| 515 | `jdg.vat.a106j.r9` |  |  |
| 516 | `jdg.vat.a106na.r2` |  |  |
| 517 | `jdg.vat.a106na.r5` |  |  |
| 518 | `jdg.vat.a106na.r6` |  |  |
| 519 | `jdg.vat.a106na.r7` |  |  |
| 520 | `jdg.vat.a106ne.r2` |  |  |
| 521 | `jdg.vat.a106ne.r3` |  |  |
| 522 | `jdg.vat.a106ng.r2` |  |  |
| 523 | `jdg.vat.a106nh.r2` |  |  |
| 524 | `jdg.vat.a20.r10` |  |  |
| 525 | `jdg.vat.a20.r6` |  |  |
| 526 | `jdg.vat.a20.r7` |  |  |
| 527 | `jdg.vat.a20.r8` |  |  |
| 528 | `jdg.vat.a20.r9` |  |  |
| 529 | `jdg.vat.a41.r10` |  |  |
| 530 | `jdg.vat.a41.r11` |  |  |
| 531 | `jdg.vat.a41.r14` |  |  |
| 532 | `jdg.vat.a41.r15` |  |  |
| 533 | `jdg.vat.a41.r19` |  |  |
| 534 | `jdg.vat.a41.r20` |  |  |
| 535 | `jdg.vat.a41.r22` |  |  |
| 536 | `jdg.vat.a41.r25` |  |  |
| 537 | `jdg.vat.a41.r27` |  |  |
| 538 | `jdg.vat.a41.r30` |  |  |
| 539 | `jdg.vat.a41.r32` |  |  |
| 540 | `jdg.vat.a41.r33` |  |  |
| 541 | `jdg.vat.a41.r34` |  |  |
| 542 | `jdg.vat.a41.r35` |  |  |
| 543 | `jdg.vat.a41.r37` |  |  |
| 544 | `jdg.vat.a41.r39` |  |  |
| 545 | `jdg.vat.a41.r40` |  |  |
| 546 | `jdg.vat.a41.r41` |  |  |
| 547 | `jdg.vat.a41.r43` |  |  |
| 548 | `jdg.vat.a41.r44` |  |  |
| 549 | `jdg.vat.a41.r47` |  |  |
| 550 | `jdg.vat.a41.r48` |  |  |
| 551 | `jdg.vat.a41.r50` |  |  |
| 552 | `jdg.vat.a41.r6` |  |  |
| 553 | `jdg.vat.a41.r8` |  |  |
| 554 | `jdg.vat.a41.r9` |  |  |
| 555 | `jdg.vat.a43.r12` |  | Art. 43 ust. 1 pkt 17 |
| 556 | `jdg.vat.a43.r13` |  | Art. 43 ust. 1 pkt 38 |
| 557 | `jdg.vat.a43.r14` |  | Art. 43 ust. 1 pkt 7 |
| 558 | `jdg.vat.a43.r16` |  | Art. 43 ust. 1 pkt 10 |
| 559 | `jdg.vat.a43.r17` |  | Art. 43 ust. 10-11 |
| 560 | `jdg.vat.a43.r21` |  | Art. 43 ust. 1 pkt 15 |
| 561 | `jdg.vat.a43.r22` |  | Art. 43 ust. 1 pkt 38 |
| 562 | `jdg.vat.a43.r23` |  | Art. 43 ust. 1 pkt 9 |
| 563 | `jdg.vat.a43.r24` |  | Art. 43 ust. 1 pkt 9 |
| 564 | `jdg.vat.a43.r25` |  | Art. 43 ust. 1 pkt 34 |
| 565 | `jdg.vat.a43.r26` |  | Art. 43 ust. 1 pkt 30 |
| 566 | `jdg.vat.a43.r27` |  | Art. 43 ust. 1 pkt 45 |
| 567 | `jdg.vat.a43.r28` |  | Art. 43 ust. 1 pkt 34 |
| 568 | `jdg.vat.a43.r29` |  | Art. 43 ust. 1 pkt 31 |
| 569 | `jdg.vat.a43.r30` |  | Art. 43 ust. 1 pkt 36 |
| 570 | `jdg.vat.a43.r31` |  | Art. 43 ust. 1 pkt 39 |
| 571 | `jdg.vat.a43.r32` |  | Art. 43 ust. 1 pkt 35-36 |
| 572 | `jdg.vat.a43.r33` |  | Art. 43 ust. 1 pkt 35 |
| 573 | `jdg.vat.a43.r34` |  | Art. 43 ust. 1 pkt 40 |
| 574 | `jdg.vat.a43.r37` |  | Art. 43 ust. 1 pkt 41 |
| 575 | `jdg.vat.a43.r38` |  | Art. 43 ust. 1 pkt 33 |
| 576 | `jdg.vat.a43.r40` |  | Art. 120 VAT |
| 577 | `jdg.vat.a43.r5` |  | Art. 43 ust. 1 pkt 22 |
| 578 | `jdg.vat.a8.r1` |  |  |
| 579 | `jdg.vat.a8.r10` |  |  |
| 580 | `jdg.vat.a8.r11` |  |  |
| 581 | `jdg.vat.a8.r12` |  |  |
| 582 | `jdg.vat.a8.r2` |  |  |
| 583 | `jdg.vat.a8.r3` |  |  |
| 584 | `jdg.vat.a8.r4` |  |  |
| 585 | `jdg.vat.a8.r5` |  |  |
| 586 | `jdg.vat.a8.r6` |  |  |
| 587 | `jdg.vat.a8.r7` |  |  |
| 588 | `jdg.vat.a8.r8` |  |  |
| 589 | `jdg.vat.a8.r9` |  |  |
| 590 | `jdg.vat.a86.r11` |  |  |
| 591 | `jdg.vat.a86.r12` |  |  |
| 592 | `jdg.vat.a86.r14` |  |  |
| 593 | `jdg.vat.a86.r17` |  |  |
| 594 | `jdg.vat.a86.r18` |  |  |
| 595 | `jdg.vat.a86.r19` |  |  |
| 596 | `jdg.vat.a86.r20` |  |  |
| 597 | `jdg.vat.a86a.r10` |  |  |
| 598 | `jdg.vat.a86a.r9` |  |  |
| 599 | `jdg.vat.a88.r10` |  | Art. 15 |
| 600 | `jdg.vat.a88.r11` |  | Art. 86 ust. 2 |
| 601 | `jdg.vat.a88.r12` |  | Art. 17 |
| 602 | `jdg.vat.a88.r14` |  | Art. 86a |
| 603 | `jdg.vat.a88.r15` |  | Art. 86a |
| 604 | `jdg.vat.a88.r6` |  | Wyjątek |
| 605 | `jdg.vat.a88.r9` |  | Art. 88 ust. 1 pkt 2 |
| 606 | `jdg.vat.a89a.r4` |  |  |
| 607 | `jdg.vat.a89b.r3` |  |  |
| 608 | `jdg.vat.a89b.r5` |  |  |
| 609 | `jdg.vat.a99.r10` |  |  |
| 610 | `jdg.vat.a99.r3` |  |  |
| 611 | `jdg.vat.a99.r6` |  |  |
| 612 | `jdg.vat.a99.r7` |  |  |
| 613 | `jdg.vat.a99.r8` |  |  |
| 614 | `jdg.vat.a99.r9` |  |  |

### `rules/micro/plan33_zus.rego` (180 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 2300 | `jdg.zus.a11.r2` |  | Art. 12 SUS |
| 2301 | `jdg.zus.a11.r3` |  | Art. 11 ust. 2 SUS |
| 2302 | `jdg.zus.a11.r4` |  | Art. 11 ust. 2 SUS |
| 2303 | `jdg.zus.a11.r5` |  | Art. 11 ust. 4 SUS |
| 2304 | `jdg.zus.a11.r6` |  | Art. 12 ust. 1 SUS |
| 2305 | `jdg.zus.a11.r7` |  | Art. 22 ust. 5 SUS |
| 2306 | `jdg.zus.a13.r2` |  | Art. 13 pkt 4 i 4a SUS |
| 2307 | `jdg.zus.a13.r3` |  | Art. 13 pkt 4 SUS |
| 2308 | `jdg.zus.a16.r1` |  | Art. 16 SUS |
| 2309 | `jdg.zus.a16.r2` |  | Art. 16 SUS |
| 2310 | `jdg.zus.a18.r10` |  | Art. 18c SUS |
| 2311 | `jdg.zus.a18.r11` |  | Art. 18c ust. 1 pkt 1 SUS |
| 2312 | `jdg.zus.a18.r12` |  | Art. 18c ust. 3 SUS |
| 2313 | `jdg.zus.a18.r13` |  | Art. 18c ust. 11 SUS |
| 2314 | `jdg.zus.a18.r14` |  | Art. 18c ust. 1 pkt 2 SUS |
| 2315 | `jdg.zus.a18.r15` |  | Art. 18a ust. 1, Art. 18a ust. 4 SUS |
| 2316 | `jdg.zus.a18.r16` |  | Art. 18 ust. 10 SUS |
| 2317 | `jdg.zus.a18.r17` |  | Art. 18 ust. 10 w zw. z Art. 18a SUS |
| 2318 | `jdg.zus.a18.r18` |  | Art. 18 ust. 8 pkt 5 SUS |
| 2319 | `jdg.zus.a18.r19` |  | Art. 18 ust. 9 SUS |
| 2320 | `jdg.zus.a18.r20` |  | Art. 18 ust. 11 SUS |
| 2321 | `jdg.zus.a18.r6` |  | Art. 18 ust. 8 SUS |
| 2322 | `jdg.zus.a18.r7` |  | Art. 18 ust. 8 pkt 5 SUS |
| 2323 | `jdg.zus.a18.r8` |  | Art. 18a SUS |
| 2324 | `jdg.zus.a18.r9` |  | Art. 18a ust. 2 SUS |
| 2325 | `jdg.zus.a22.r10` |  | Art. 22 ust. 3 SUS |
| 2326 | `jdg.zus.a22.r11` |  | Art. 22 ust. 5 SUS |
| 2327 | `jdg.zus.a22.r12` |  | Art. 22 ust. 5 pkt 6 SUS |
| 2328 | `jdg.zus.a22.r9` |  | Art. 22 ust. 1 SUS |
| 2329 | `jdg.zus.a24.r1` |  | Art. 104 ustawy o promocji zatrudnienia |
| 2330 | `jdg.zus.a24.r2` |  | Art. 21 ustawy o FGSP |
| 2331 | `jdg.zus.a24.r3` |  | Art. 104 ust. 1 pkt 1 ustawy o promocji zatrudnienia |
| 2332 | `jdg.zus.a24.r4` |  | Art. 21 ustawy o FGSP |
| 2333 | `jdg.zus.a26.r1` |  | Art. 26 ustawy zasiłkowej |
| 2334 | `jdg.zus.a26.r10` |  | Art. 29 ustawy zasiłkowej |
| 2335 | `jdg.zus.a26.r11` |  | Art. 35 ustawy zasiłkowej |
| 2336 | `jdg.zus.a26.r12` |  | Art. 8 ustawy zasiłkowej |
| 2337 | `jdg.zus.a26.r13` |  | Art. 18 ustawy zasiłkowej |
| 2338 | `jdg.zus.a26.r14` |  | Art. 18 ust. 1 ustawy zasiłkowej |
| 2339 | `jdg.zus.a26.r2` |  | Art. 4 ust. 1 ustawy zasiłkowej |
| 2340 | `jdg.zus.a26.r3` |  | Art. 36 ust. 1 ustawy zasiłkowej |
| 2341 | `jdg.zus.a26.r4` |  | Art. 36 ust. 2 ustawy zasiłkowej |
| 2342 | `jdg.zus.a26.r5` |  | Art. 8 ustawy zasiłkowej |
| 2343 | `jdg.zus.a26.r6` |  | Art. 8 pkt 2 ustawy zasiłkowej |
| 2344 | `jdg.zus.a26.r7` |  | Art. 36 ust. 2 ustawy zasiłkowej |
| 2345 | `jdg.zus.a26.r8` |  | Art. 36 ust. 3 ustawy zasiłkowej |
| 2346 | `jdg.zus.a26.r9` |  | Art. 38 ustawy zasiłkowej |
| 2347 | `jdg.zus.a32.r1` |  | Art. 104b ustawy o promocji zatrudnienia |
| 2348 | `jdg.zus.a32.r2` |  | Art. 104a ustawy o promocji zatrudnienia |
| 2349 | `jdg.zus.a35.r1` |  | Art. 21 ustawy o FGSP |
| 2350 | `jdg.zus.a35.r2` |  | Art. 21 ust. 1 ustawy o FGSP |
| 2351 | `jdg.zus.a36.r1` |  | Ustawa o FGSP |
| 2352 | `jdg.zus.a46.r4` |  | Art. 46 ust. 1 SUS |
| 2353 | `jdg.zus.a46.r5` |  | Art. 46 ust. 2 SUS |
| 2354 | `jdg.zus.a46.r6` |  | Art. 46 ust. 3 SUS |
| 2355 | `jdg.zus.a46.r7` |  | Art. 46 ust. 4 SUS |
| 2356 | `jdg.zus.a46.r8` |  | Art. 46 ust. 6 SUS |
| 2357 | `jdg.zus.a47.r4` |  | Art. 47 ust. 1 SUS |
| 2358 | `jdg.zus.a47.r5` |  | Art. 79b ustawy zdrowotnej |
| 2359 | `jdg.zus.a47.r6` |  | Art. 12 par. 5 Ordynacji podatkowej |
| 2360 | `jdg.zus.a47.r7` |  | Art. 47 ust. 2 SUS |
| 2361 | `jdg.zus.a6.r10` |  | Art. 6 ust. 1 pkt 22 SUS |
| 2362 | `jdg.zus.a6.r11` |  | Art. 6 ust. 1 pkt 16 SUS |
| 2363 | `jdg.zus.a6.r12` |  | Art. 6 ust. 1 pkt 17 SUS |
| 2364 | `jdg.zus.a6.r13` |  | Art. 6 ust. 1 pkt 20 SUS |
| 2365 | `jdg.zus.a6.r14` |  | Art. 6 ust. 1 pkt 23 SUS |
| 2366 | `jdg.zus.a6.r15` |  | Art. 6 ust. 1 pkt 5 w zw. z Art. 8 ust. 6 SUS |
| 2367 | `jdg.zus.a6.r7` |  | Art. 6 ust. 1 pkt 6 SUS |
| 2368 | `jdg.zus.a6.r8` |  | Art. 6 ust. 1 pkt 4 SUS |
| 2369 | `jdg.zus.a6.r9` |  | Art. 6 ust. 1 pkt 4 SUS |
| 2370 | `jdg.zus.a8.r10` |  | Art. 9 ust. 4 SUS |
| 2371 | `jdg.zus.a8.r11` |  | Art. 9 ust. 6 SUS |
| 2372 | `jdg.zus.a8.r12` |  | Art. 9 ust. 1 pkt 5 SUS |
| 2373 | `jdg.zus.a8.r13` |  | Art. 6 ust. 1 pkt 4 w zw. z Art. 9 SUS |
| 2374 | `jdg.zus.a8.r14` |  | Art. 9 ust. 5 SUS |
| 2375 | `jdg.zus.a8.r15` |  | Art. 18a ust. 5 SUS |
| 2376 | `jdg.zus.a8.r6` |  | Art. 9 ust. 1a SUS |
| 2377 | `jdg.zus.a8.r7` |  | Art. 9 ust. 1c SUS |
| 2378 | `jdg.zus.a8.r8` |  | Art. 9 ust. 2 SUS |
| 2379 | `jdg.zus.a8.r9` |  | Art. 9 ust. 2a SUS |
| 2380 | `jdg.zus.a9.r10` |  | Art. 9 ust. 1e SUS |
| 2381 | `jdg.zus.a9.r11` |  | Art. 9 ust. 1f SUS |
| 2382 | `jdg.zus.a9.r12` |  | Art. 9 ust. 1g SUS |
| 2383 | `jdg.zus.a9.r13` |  | Art. 9 ust. 1h SUS |
| 2384 | `jdg.zus.a9.r14` |  | Art. 9 ust. 1i SUS |
| 2385 | `jdg.zus.a9.r15` |  | Art. 9 ust. 6 SUS |
| 2386 | `jdg.zus.a9.r6` |  | Art. 9 ust. 1a SUS |
| 2387 | `jdg.zus.a9.r7` |  | Art. 9 ust. 1b SUS |
| 2388 | `jdg.zus.a9.r8` |  | Art. 9 ust. 1c SUS |
| 2389 | `jdg.zus.a9.r9` |  | Art. 9 ust. 1d SUS |
| 2390 | `jdg.zus.base.r1` |  |  |
| 2391 | `jdg.zus.base.r10` |  |  |
| 2392 | `jdg.zus.base.r11` |  |  |
| 2393 | `jdg.zus.base.r12` |  |  |
| 2394 | `jdg.zus.base.r13` |  |  |
| 2395 | `jdg.zus.base.r14` |  |  |
| 2396 | `jdg.zus.base.r15` |  |  |
| 2397 | `jdg.zus.base.r2` |  |  |
| 2398 | `jdg.zus.base.r3` |  |  |
| 2399 | `jdg.zus.base.r4` |  |  |
| 2400 | `jdg.zus.base.r5` |  |  |
| 2401 | `jdg.zus.base.r6` |  |  |
| 2402 | `jdg.zus.base.r7` |  |  |
| 2403 | `jdg.zus.base.r8` |  |  |
| 2404 | `jdg.zus.base.r9` |  |  |
| 2405 | `jdg.zus.benefit.r1` |  |  |
| 2406 | `jdg.zus.benefit.r10` |  |  |
| 2407 | `jdg.zus.benefit.r11` |  |  |
| 2408 | `jdg.zus.benefit.r12` |  |  |
| 2409 | `jdg.zus.benefit.r13` |  |  |
| 2410 | `jdg.zus.benefit.r14` |  |  |
| 2411 | `jdg.zus.benefit.r15` |  |  |
| 2412 | `jdg.zus.benefit.r2` |  |  |
| 2413 | `jdg.zus.benefit.r3` |  |  |
| 2414 | `jdg.zus.benefit.r4` |  |  |
| 2415 | `jdg.zus.benefit.r5` |  |  |
| 2416 | `jdg.zus.benefit.r6` |  |  |
| 2417 | `jdg.zus.benefit.r7` |  |  |
| 2418 | `jdg.zus.benefit.r8` |  |  |
| 2419 | `jdg.zus.benefit.r9` |  |  |
| 2420 | `jdg.zus.deadline.r1` |  |  |
| 2421 | `jdg.zus.deadline.r10` |  |  |
| 2422 | `jdg.zus.deadline.r2` |  |  |
| 2423 | `jdg.zus.deadline.r3` |  |  |
| 2424 | `jdg.zus.deadline.r4` |  |  |
| 2425 | `jdg.zus.deadline.r5` |  |  |
| 2426 | `jdg.zus.deadline.r6` |  |  |
| 2427 | `jdg.zus.deadline.r7` |  |  |
| 2428 | `jdg.zus.deadline.r8` |  |  |
| 2429 | `jdg.zus.deadline.r9` |  |  |
| 2430 | `jdg.zus.rate.r1` |  | Art. 22 ustawy SUS |
| 2431 | `jdg.zus.rate.r10` |  | Art. 16 ustawy SUS |
| 2432 | `jdg.zus.rate.r11` |  | Art. 16 ustawy SUS |
| 2433 | `jdg.zus.rate.r12` |  | Art. 16 ustawy SUS |
| 2434 | `jdg.zus.rate.r13` |  | Art. 104 ustawy o promocji zatrudnienia |
| 2435 | `jdg.zus.rate.r14` |  | Art. 25 ustawy o FGSP |
| 2436 | `jdg.zus.rate.r15` |  | Suma skladek |
| 2437 | `jdg.zus.rate.r2` |  | Art. 22 ustawy SUS |
| 2438 | `jdg.zus.rate.r3` |  | Art. 22 ustawy SUS |
| 2439 | `jdg.zus.rate.r4` |  | Art. 22 ustawy SUS |
| 2440 | `jdg.zus.rate.r5` |  | Art. 104 ustawy o promocji zatrudnienia |
| 2441 | `jdg.zus.rate.r6` |  | Art. 25 ustawy o FGSP |
| 2442 | `jdg.zus.rate.r7` |  | Art. 16 ustawy SUS |
| 2443 | `jdg.zus.rate.r8` |  | Art. 16 ustawy SUS |
| 2444 | `jdg.zus.rate.r9` |  | Art. 16 ustawy SUS |
| 2445 | `jdg.zus.small_plus.r1` |  |  |
| 2446 | `jdg.zus.small_plus.r10` |  |  |
| 2447 | `jdg.zus.small_plus.r11` |  |  |
| 2448 | `jdg.zus.small_plus.r12` |  |  |
| 2449 | `jdg.zus.small_plus.r13` |  |  |
| 2450 | `jdg.zus.small_plus.r14` |  |  |
| 2451 | `jdg.zus.small_plus.r15` |  |  |
| 2452 | `jdg.zus.small_plus.r2` |  |  |
| 2453 | `jdg.zus.small_plus.r3` |  |  |
| 2454 | `jdg.zus.small_plus.r4` |  |  |
| 2455 | `jdg.zus.small_plus.r5` |  |  |
| 2456 | `jdg.zus.small_plus.r6` |  |  |
| 2457 | `jdg.zus.small_plus.r7` |  |  |
| 2458 | `jdg.zus.small_plus.r8` |  |  |
| 2459 | `jdg.zus.small_plus.r9` |  |  |
| 2460 | `jdg.zus.start.r1` |  |  |
| 2461 | `jdg.zus.start.r10` |  |  |
| 2462 | `jdg.zus.start.r2` |  |  |
| 2463 | `jdg.zus.start.r3` |  |  |
| 2464 | `jdg.zus.start.r4` |  |  |
| 2465 | `jdg.zus.start.r5` |  |  |
| 2466 | `jdg.zus.start.r6` |  |  |
| 2467 | `jdg.zus.start.r7` |  |  |
| 2468 | `jdg.zus.start.r8` |  |  |
| 2469 | `jdg.zus.start.r9` |  |  |
| 2470 | `jdg.zus.suspension.r1` |  |  |
| 2471 | `jdg.zus.suspension.r10` |  |  |
| 2472 | `jdg.zus.suspension.r2` |  |  |
| 2473 | `jdg.zus.suspension.r3` |  |  |
| 2474 | `jdg.zus.suspension.r4` |  |  |
| 2475 | `jdg.zus.suspension.r5` |  |  |
| 2476 | `jdg.zus.suspension.r6` |  |  |
| 2477 | `jdg.zus.suspension.r7` |  |  |
| 2478 | `jdg.zus.suspension.r8` |  |  |
| 2479 | `jdg.zus.suspension.r9` |  |  |

### `rules/micro/plan34_ord.rego` (189 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 2901 | `jdg.ord.a29.r1` |  |  |
| 2902 | `jdg.ord.a29.r2` |  |  |
| 2903 | `jdg.ord.a29.r3` |  |  |
| 2904 | `jdg.ord.a29.r4` |  |  |
| 2905 | `jdg.ord.a29.r5` |  |  |
| 3201 | `jdg.ord.a32.r1` |  |  |
| 3202 | `jdg.ord.a32.r2` |  |  |
| 3301 | `jdg.ord.a33.r1` |  |  |
| 3302 | `jdg.ord.a33.r2` |  |  |
| 3303 | `jdg.ord.a33.r3` |  |  |
| 3304 | `jdg.ord.a33.r4` |  |  |
| 3305 | `jdg.ord.a33.r5` |  |  |
| 3306 | `jdg.ord.a33.r6` |  |  |
| 3307 | `jdg.ord.a33.r7` |  |  |
| 3308 | `jdg.ord.a33.r8` |  |  |
| 4701 | `jdg.ord.a47.r1` |  |  |
| 4702 | `jdg.ord.a47.r2` |  |  |
| 4703 | `jdg.ord.a47.r3` |  |  |
| 4704 | `jdg.ord.a47.r4` |  |  |
| 4705 | `jdg.ord.a47.r5` |  |  |
| 4706 | `jdg.ord.a47.r6` |  |  |
| 4707 | `jdg.ord.a47.r7` |  |  |
| 4801 | `jdg.ord.a48.r1` |  |  |
| 4802 | `jdg.ord.a48.r2` |  |  |
| 4803 | `jdg.ord.a48.r3` |  |  |
| 4901 | `jdg.ord.a49.r1` |  |  |
| 4902 | `jdg.ord.a49.r2` |  |  |
| 5101 | `jdg.ord.a51.r1` |  |  |
| 5102 | `jdg.ord.a51.r2` |  |  |
| 5103 | `jdg.ord.a51.r3` |  |  |
| 5104 | `jdg.ord.a51.r4` |  |  |
| 5201 | `jdg.ord.a52.r1` |  |  |
| 5202 | `jdg.ord.a52.r2` |  |  |
| 5203 | `jdg.ord.a52.r3` |  |  |
| 5204 | `jdg.ord.a52.r4` |  |  |
| 5205 | `jdg.ord.a52.r5` |  |  |
| 6701 | `jdg.ord.a67b.r1` |  |  |
| 6701 | `jdg.ord.a67c.r1` |  |  |
| 6701 | `jdg.ord.a67d.r1` |  |  |
| 6701 | `jdg.ord.a67e.r1` |  |  |
| 6702 | `jdg.ord.a67b.r2` |  |  |
| 6702 | `jdg.ord.a67c.r2` |  |  |
| 6702 | `jdg.ord.a67d.r2` |  |  |
| 6702 | `jdg.ord.a67e.r2` |  |  |
| 6703 | `jdg.ord.a67b.r3` |  |  |
| 6703 | `jdg.ord.a67e.r3` |  |  |
| 6704 | `jdg.ord.a67b.r4` |  |  |
| 6705 | `jdg.ord.a67b.r5` |  |  |
| 6706 | `jdg.ord.a67b.r6` |  |  |
| 6707 | `jdg.ord.a67b.r7` |  |  |
| 6708 | `jdg.ord.a67b.r8` |  |  |
| 7001 | `jdg.ord.a70.r1` |  |  |
| 7002 | `jdg.ord.a70.r2` |  |  |
| 7003 | `jdg.ord.a70.r3` |  |  |
| 7004 | `jdg.ord.a70.r4` |  |  |
| 7005 | `jdg.ord.a70.r5` |  |  |
| 7006 | `jdg.ord.a70.r6` |  |  |
| 7007 | `jdg.ord.a70.r7` |  |  |
| 7008 | `jdg.ord.a70.r8` |  |  |
| 7009 | `jdg.ord.a70.r9` |  |  |
| 7010 | `jdg.ord.a70.r10` |  |  |
| 7011 | `jdg.ord.a70.r11` |  |  |
| 7012 | `jdg.ord.a70.r12` |  |  |
| 7013 | `jdg.ord.a70.r13` |  |  |
| 7101 | `jdg.ord.a71.r1` |  |  |
| 7102 | `jdg.ord.a71.r2` |  |  |
| 7201 | `jdg.ord.a72.r1` |  |  |
| 7202 | `jdg.ord.a72.r2` |  |  |
| 7203 | `jdg.ord.a72.r3` |  |  |
| 7204 | `jdg.ord.a72.r4` |  |  |
| 7205 | `jdg.ord.a72.r5` |  |  |
| 7301 | `jdg.ord.a73.r1` |  |  |
| 7302 | `jdg.ord.a73.r2` |  |  |
| 7401 | `jdg.ord.a74.r1` |  |  |
| 7501 | `jdg.ord.a75.r1` |  |  |
| 7502 | `jdg.ord.a75.r2` |  |  |
| 7503 | `jdg.ord.a75.r3` |  |  |
| 7601 | `jdg.ord.a76.r1` |  |  |
| 7602 | `jdg.ord.a76.r2` |  |  |
| 7701 | `jdg.ord.a77.r1` |  |  |
| 7702 | `jdg.ord.a77.r2` |  |  |
| 7801 | `jdg.ord.a78.r1` |  |  |
| 7901 | `jdg.ord.a79.r1` |  |  |
| 7902 | `jdg.ord.a79.r2` |  |  |
| 8001 | `jdg.ord.a80.r1` |  |  |
| 8101 | `jdg.ord.a81.r1` |  |  |
| 8101 | `jdg.ord.a81a.r1` |  |  |
| 8101 | `jdg.ord.a81b.r1` |  |  |
| 8101 | `jdg.ord.a81c.r1` |  |  |
| 8102 | `jdg.ord.a81.r2` |  |  |
| 8102 | `jdg.ord.a81a.r2` |  |  |
| 8103 | `jdg.ord.a81.r3` |  |  |
| 8104 | `jdg.ord.a81.r4` |  |  |
| 8105 | `jdg.ord.a81.r5` |  |  |
| 8106 | `jdg.ord.a81.r6` |  |  |
| 8107 | `jdg.ord.a81.r7` |  |  |
| 8108 | `jdg.ord.a81.r8` |  |  |
| 8109 | `jdg.ord.a81.r9` |  |  |
| 11901 | `jdg.ord.a119a.r1` |  |  |
| 11902 | `jdg.ord.a119a.r2` |  |  |
| 11903 | `jdg.ord.a119a.r3` |  |  |
| 11904 | `jdg.ord.a119a.r4` |  |  |
| 11905 | `jdg.ord.a119a.r5` |  |  |
| 11906 | `jdg.ord.a119a.r6` |  |  |
| 11907 | `jdg.ord.a119a.r7` |  |  |
| 11908 | `jdg.ord.a119a.r8` |  |  |
| 11909 | `jdg.ord.a119a.r9` |  |  |
| 11910 | `jdg.ord.a119a.r10` |  |  |
| 14501 | `jdg.ord.a145.r1` |  |  |
| 14502 | `jdg.ord.a145.r2` |  |  |
| 14503 | `jdg.ord.a145.r3` |  |  |
| 14504 | `jdg.ord.a145.r4` |  |  |
| 14505 | `jdg.ord.a145.r5` |  |  |
| 14506 | `jdg.ord.a145.r6` |  |  |
| 14601 | `jdg.ord.a146.r1` |  |  |
| 14602 | `jdg.ord.a146.r2` |  |  |
| 14603 | `jdg.ord.a146.r3` |  |  |
| 14701 | `jdg.ord.a147.r1` |  |  |
| 14702 | `jdg.ord.a147.r2` |  |  |
| 14703 | `jdg.ord.a147.r3` |  |  |
| 14704 | `jdg.ord.a147.r4` |  |  |
| 14801 | `jdg.ord.a148.r1` |  |  |
| 14802 | `jdg.ord.a148.r2` |  |  |
| 14901 | `jdg.ord.a149.r1` |  |  |
| 14902 | `jdg.ord.a149.r2` |  |  |
| 14903 | `jdg.ord.a149.r3` |  |  |
| 14904 | `jdg.ord.a149.r4` |  |  |
| 16501 | `jdg.ord.a165.r1` |  |  |
| 16502 | `jdg.ord.a165.r2` |  |  |
| 16503 | `jdg.ord.a165.r3` |  |  |
| 16504 | `jdg.ord.a165.r4` |  |  |
| 16505 | `jdg.ord.a165.r5` |  |  |
| 16506 | `jdg.ord.a165.r6` |  |  |
| 16507 | `jdg.ord.a165.r7` |  |  |
| 16601 | `jdg.ord.a166.r1` |  |  |
| 16602 | `jdg.ord.a166.r2` |  |  |
| 16801 | `jdg.ord.a168.r1` |  |  |
| 16802 | `jdg.ord.a168.r2` |  |  |
| 16803 | `jdg.ord.a168.r3` |  |  |
| 17001 | `jdg.ord.a170.r1` |  |  |
| 17002 | `jdg.ord.a170.r2` |  |  |
| 17003 | `jdg.ord.a170.r3` |  |  |
| 17004 | `jdg.ord.a170.r4` |  |  |
| 17101 | `jdg.ord.a171.r1` |  |  |
| 17102 | `jdg.ord.a171.r2` |  |  |
| 17103 | `jdg.ord.a171.r3` |  |  |
| 17201 | `jdg.ord.a172.r1` |  |  |
| 17301 | `jdg.ord.a173.r1` |  |  |
| 17302 | `jdg.ord.a173.r2` |  |  |
| 17401 | `jdg.ord.a174.r1` |  |  |
| 18001 | `jdg.ord.a180.r1` |  |  |
| 18002 | `jdg.ord.a180.r2` |  |  |
| 19901 | `jdg.ord.a199a.r1` |  |  |
| 19902 | `jdg.ord.a199a.r2` |  |  |
| 19903 | `jdg.ord.a199a.r3` |  |  |
| 19904 | `jdg.ord.a199a.r4` |  |  |
| 19905 | `jdg.ord.a199a.r5` |  |  |
| 19906 | `jdg.ord.a199a.r6` |  |  |
| 19907 | `jdg.ord.a199a.r7` |  |  |
| 19908 | `jdg.ord.a199a.r8` |  |  |
| 19909 | `jdg.ord.a199a.r9` |  |  |
| 19910 | `jdg.ord.a199a.r10` |  |  |
| 20801 | `jdg.ord.a208.r1` |  |  |
| 20802 | `jdg.ord.a208.r2` |  |  |
| 20803 | `jdg.ord.a208.r3` |  |  |
| 20804 | `jdg.ord.a208.r4` |  |  |
| 20805 | `jdg.ord.a208.r5` |  |  |
| 21001 | `jdg.ord.a210.r1` |  |  |
| 21002 | `jdg.ord.a210.r2` |  |  |
| 21301 | `jdg.ord.a213.r1` |  |  |
| 21302 | `jdg.ord.a213.r2` |  |  |
| 21303 | `jdg.ord.a213.r3` |  |  |
| 21901 | `jdg.ord.a219.r1` |  |  |
| 21902 | `jdg.ord.a219.r2` |  |  |
| 22001 | `jdg.ord.a220.r1` |  |  |
| 22002 | `jdg.ord.a220.r2` |  |  |
| 22101 | `jdg.ord.a221.r1` |  |  |
| 22102 | `jdg.ord.a221.r2` |  |  |
| 22103 | `jdg.ord.a221.r3` |  |  |
| 22104 | `jdg.ord.a221.r4` |  |  |
| 22201 | `jdg.ord.a222.r1` |  |  |
| 22202 | `jdg.ord.a222.r2` |  |  |
| 22203 | `jdg.ord.a222.r3` |  |  |
| 22204 | `jdg.ord.a222.r4` |  |  |
| 22301 | `jdg.ord.a223.r1` |  |  |
| 22401 | `jdg.ord.a224.r1` |  |  |
| 22501 | `jdg.ord.a225.r1` |  |  |
| 22601 | `jdg.ord.a226.r1` |  |  |
| 22602 | `jdg.ord.a226.r2` |  |  |

### `rules/micro/plan34_pit.rego` (265 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1 | `jdg.pit.p580.r1` |  |  |
| 1 | `jdg.pit.p582.r1` |  |  |
| 1 | `jdg.pit.p584.r1` |  |  |
| 1 | `jdg.pit.p586.r1` |  |  |
| 1 | `jdg.pit.p0limit.r1` |  |  |
| 2 | `jdg.pit.p580.r2` |  |  |
| 2 | `jdg.pit.p582.r2` |  |  |
| 2 | `jdg.pit.p584.r2` |  |  |
| 2 | `jdg.pit.p586.r2` |  |  |
| 2 | `jdg.pit.p0limit.r2` |  |  |
| 3 | `jdg.pit.p580.r3` |  |  |
| 3 | `jdg.pit.p582.r3` |  |  |
| 3 | `jdg.pit.p584.r3` |  |  |
| 3 | `jdg.pit.p586.r3` |  |  |
| 3 | `jdg.pit.p0limit.r3` |  |  |
| 4 | `jdg.pit.p0limit.r4` |  |  |
| 901 | `jdg.pit.a9a.r1` |  |  |
| 902 | `jdg.pit.a9a.r2` |  |  |
| 904 | `jdg.pit.a9a.r4` |  |  |
| 905 | `jdg.pit.a9a.r5` |  |  |
| 907 | `jdg.pit.a9a.r7` |  |  |
| 1001 | `jdg.pit.a10.r1` |  |  |
| 1002 | `jdg.pit.a10.r2` |  |  |
| 1003 | `jdg.pit.a10.r3` |  |  |
| 1004 | `jdg.pit.a10.r4` |  |  |
| 1005 | `jdg.pit.a10.r5` |  |  |
| 1006 | `jdg.pit.a10.r6` |  |  |
| 1007 | `jdg.pit.a10.r7` |  |  |
| 1008 | `jdg.pit.a10.r8` |  |  |
| 1009 | `jdg.pit.a10.r9` |  |  |
| 1010 | `jdg.pit.a10.r10` |  |  |
| 1401 | `jdg.pit.a14.r1` |  |  |
| 1401 | `jdg.pit.a14c.r1` |  |  |
| 1402 | `jdg.pit.a14.r2` |  |  |
| 1402 | `jdg.pit.a14c.r2` |  |  |
| 1403 | `jdg.pit.a14.r3` |  |  |
| 1405 | `jdg.pit.a14.r5` |  |  |
| 1405 | `jdg.pit.a14c.r5` |  |  |
| 1406 | `jdg.pit.a14.r6` |  |  |
| 1407 | `jdg.pit.a14.r7` |  |  |
| 1407 | `jdg.pit.a14c.r7` |  |  |
| 1408 | `jdg.pit.a14.r8` |  |  |
| 1413 | `jdg.pit.a14.r13` |  |  |
| 1414 | `jdg.pit.a14.r14` |  |  |
| 1416 | `jdg.pit.a14.r16` |  |  |
| 1420 | `jdg.pit.a14.r20` |  |  |
| 2201 | `jdg.pit.a22.r1` |  |  |
| 2201 | `jdg.pit.a22a.r1` |  |  |
| 2201 | `jdg.pit.a22d.r1` |  |  |
| 2201 | `jdg.pit.a22e.r1` |  |  |
| 2201 | `jdg.pit.a22g.r1` |  |  |
| 2201 | `jdg.pit.a22i.r1` |  |  |
| 2201 | `jdg.pit.a22j.r1` |  |  |
| 2201 | `jdg.pit.a22k.r1` |  |  |
| 2201 | `jdg.pit.a22l.r1` |  |  |
| 2201 | `jdg.pit.a22f.r1` |  |  |
| 2201 | `jdg.pit.a22m.r1` |  |  |
| 2202 | `jdg.pit.a22a.r2` |  |  |
| 2202 | `jdg.pit.a22m.r2` |  |  |
| 2202 | `jdg.pit.a22d.r2` |  |  |
| 2202 | `jdg.pit.a22e.r2` |  |  |
| 2202 | `jdg.pit.a22g.r2` |  |  |
| 2202 | `jdg.pit.a22i.r2` |  |  |
| 2202 | `jdg.pit.a22j.r2` |  |  |
| 2202 | `jdg.pit.a22k.r2` |  |  |
| 2202 | `jdg.pit.a22l.r2` |  |  |
| 2203 | `jdg.pit.a22.r3` |  |  |
| 2203 | `jdg.pit.a22d.r3` |  |  |
| 2203 | `jdg.pit.a22m.r3` |  |  |
| 2203 | `jdg.pit.a22a.r3` |  |  |
| 2203 | `jdg.pit.a22g.r3` |  |  |
| 2203 | `jdg.pit.a22i.r3` |  |  |
| 2203 | `jdg.pit.a22k.r3` |  |  |
| 2203 | `jdg.pit.a22l.r3` |  |  |
| 2204 | `jdg.pit.a22.r4` |  |  |
| 2204 | `jdg.pit.a22g.r4` |  |  |
| 2204 | `jdg.pit.a22m.r4` |  |  |
| 2204 | `jdg.pit.a22a.r4` |  |  |
| 2204 | `jdg.pit.a22d.r4` |  |  |
| 2204 | `jdg.pit.a22l.r4` |  |  |
| 2205 | `jdg.pit.a22g.r5` |  |  |
| 2205 | `jdg.pit.a22d.r5` |  |  |
| 2205 | `jdg.pit.a22l.r5` |  |  |
| 2205 | `jdg.pit.a22m.r5` |  |  |
| 2206 | `jdg.pit.a22.r6` |  |  |
| 2206 | `jdg.pit.a22d.r6` |  |  |
| 2206 | `jdg.pit.a22g.r6` |  |  |
| 2206 | `jdg.pit.a22m.r6` |  |  |
| 2207 | `jdg.pit.a22.r7` |  |  |
| 2207 | `jdg.pit.a22d.r7` |  |  |
| 2207 | `jdg.pit.a22g.r7` |  |  |
| 2208 | `jdg.pit.a22.r8` |  |  |
| 2210 | `jdg.pit.a22.r10` |  |  |
| 2212 | `jdg.pit.a22.r12` |  |  |
| 2213 | `jdg.pit.a22.r13` |  |  |
| 2215 | `jdg.pit.a22.r15` |  |  |
| 2301 | `jdg.pit.a23.r1` |  |  |
| 2302 | `jdg.pit.a23.r2` |  |  |
| 2303 | `jdg.pit.a23.r3` |  |  |
| 2304 | `jdg.pit.a23.r4` |  |  |
| 2306 | `jdg.pit.a23.r6` |  |  |
| 2308 | `jdg.pit.a23.r8` |  |  |
| 2312 | `jdg.pit.a23.r12` |  |  |
| 2315 | `jdg.pit.a23.r15` |  |  |
| 2317 | `jdg.pit.a23.r17` |  |  |
| 2321 | `jdg.pit.a23.r21` |  |  |
| 2323 | `jdg.pit.a23.r23` |  |  |
| 2324 | `jdg.pit.a23.r24` |  |  |
| 2326 | `jdg.pit.a23.r26` |  |  |
| 2327 | `jdg.pit.a23.r27` |  |  |
| 2328 | `jdg.pit.a23.r28` |  |  |
| 2329 | `jdg.pit.a23.r29` |  |  |
| 2330 | `jdg.pit.a23.r30` |  |  |
| 2401 | `jdg.pit.a24.r1` |  |  |
| 2402 | `jdg.pit.a24.r2` |  |  |
| 2403 | `jdg.pit.a24.r3` |  |  |
| 2404 | `jdg.pit.a24.r4` |  |  |
| 2405 | `jdg.pit.a24.r5` |  |  |
| 2406 | `jdg.pit.a24.r6` |  |  |
| 2407 | `jdg.pit.a24.r7` |  |  |
| 2408 | `jdg.pit.a24.r8` |  |  |
| 2409 | `jdg.pit.a24.r9` |  |  |
| 2410 | `jdg.pit.a24.r10` |  |  |
| 2411 | `jdg.pit.a24.r11` |  |  |
| 2412 | `jdg.pit.a24.r12` |  |  |
| 2413 | `jdg.pit.a24.r13` |  |  |
| 2414 | `jdg.pit.a24.r14` |  |  |
| 2415 | `jdg.pit.a24.r15` |  |  |
| 2601 | `jdg.pit.a26.r1` |  |  |
| 2601 | `jdg.pit.a26e.r1` |  |  |
| 2601 | `jdg.pit.a26eb.r1` |  |  |
| 2601 | `jdg.pit.a26ec.r1` |  |  |
| 2601 | `jdg.pit.a26gb.r1` |  |  |
| 2601 | `jdg.pit.a26h.r1` |  |  |
| 2601 | `jdg.pit.a26b.r1` |  |  |
| 2601 | `jdg.pit.a26ha.r1` |  |  |
| 2601 | `jdg.pit.a26hd.r1` |  |  |
| 2601 | `jdg.pit.a26i.r1` |  |  |
| 2602 | `jdg.pit.a26.r2` |  |  |
| 2602 | `jdg.pit.a26e.r2` |  |  |
| 2602 | `jdg.pit.a26eb.r2` |  |  |
| 2602 | `jdg.pit.a26ec.r2` |  |  |
| 2602 | `jdg.pit.a26gb.r2` |  |  |
| 2602 | `jdg.pit.a26h.r2` |  |  |
| 2602 | `jdg.pit.a26b.r2` |  |  |
| 2602 | `jdg.pit.a26ha.r2` |  |  |
| 2602 | `jdg.pit.a26hd.r2` |  |  |
| 2602 | `jdg.pit.a26i.r2` |  |  |
| 2603 | `jdg.pit.a26e.r3` |  |  |
| 2603 | `jdg.pit.a26.r3` |  |  |
| 2603 | `jdg.pit.a26eb.r3` |  |  |
| 2603 | `jdg.pit.a26ec.r3` |  |  |
| 2603 | `jdg.pit.a26gb.r3` |  |  |
| 2603 | `jdg.pit.a26h.r3` |  |  |
| 2603 | `jdg.pit.a26b.r3` |  |  |
| 2603 | `jdg.pit.a26ha.r3` |  |  |
| 2603 | `jdg.pit.a26hd.r3` |  |  |
| 2603 | `jdg.pit.a26i.r3` |  |  |
| 2604 | `jdg.pit.a26e.r4` |  |  |
| 2604 | `jdg.pit.a26h.r4` |  |  |
| 2604 | `jdg.pit.a26.r4` |  |  |
| 2604 | `jdg.pit.a26b.r4` |  |  |
| 2604 | `jdg.pit.a26eb.r4` |  |  |
| 2604 | `jdg.pit.a26ha.r4` |  |  |
| 2604 | `jdg.pit.a26hd.r4` |  |  |
| 2604 | `jdg.pit.a26i.r4` |  |  |
| 2605 | `jdg.pit.a26e.r5` |  |  |
| 2605 | `jdg.pit.a26.r5` |  |  |
| 2605 | `jdg.pit.a26h.r5` |  |  |
| 2605 | `jdg.pit.a26b.r5` |  |  |
| 2605 | `jdg.pit.a26eb.r5` |  |  |
| 2605 | `jdg.pit.a26ha.r5` |  |  |
| 2605 | `jdg.pit.a26hd.r5` |  |  |
| 2605 | `jdg.pit.a26i.r5` |  |  |
| 2606 | `jdg.pit.a26.r6` |  |  |
| 2606 | `jdg.pit.a26e.r6` |  |  |
| 2606 | `jdg.pit.a26b.r6` |  |  |
| 2606 | `jdg.pit.a26eb.r6` |  |  |
| 2606 | `jdg.pit.a26hd.r6` |  |  |
| 2606 | `jdg.pit.a26i.r6` |  |  |
| 2607 | `jdg.pit.a26.r7` |  |  |
| 2607 | `jdg.pit.a26e.r7` |  |  |
| 2607 | `jdg.pit.a26eb.r7` |  |  |
| 2607 | `jdg.pit.a26i.r7` |  |  |
| 2608 | `jdg.pit.a26.r8` |  |  |
| 2608 | `jdg.pit.a26e.r8` |  |  |
| 2609 | `jdg.pit.a26e.r9` |  |  |
| 2609 | `jdg.pit.a26.r9` |  |  |
| 2610 | `jdg.pit.a26.r10` |  |  |
| 2610 | `jdg.pit.a26e.r10` |  |  |
| 2611 | `jdg.pit.a26.r11` |  |  |
| 2611 | `jdg.pit.a26e.r11` |  |  |
| 2612 | `jdg.pit.a26e.r12` |  |  |
| 2612 | `jdg.pit.a26.r12` |  |  |
| 2613 | `jdg.pit.a26e.r13` |  |  |
| 2613 | `jdg.pit.a26.r13` |  |  |
| 2614 | `jdg.pit.a26.r14` |  |  |
| 2614 | `jdg.pit.a26e.r14` |  |  |
| 2615 | `jdg.pit.a26.r15` |  |  |
| 2615 | `jdg.pit.a26e.r15` |  |  |
| 2616 | `jdg.pit.a26.r16` |  |  |
| 2617 | `jdg.pit.a26.r17` |  |  |
| 2618 | `jdg.pit.a26.r18` |  |  |
| 2619 | `jdg.pit.a26.r19` |  |  |
| 2620 | `jdg.pit.a26.r20` |  |  |
| 2621 | `jdg.pit.a26.r21` |  |  |
| 2622 | `jdg.pit.a26.r22` |  |  |
| 2623 | `jdg.pit.a26.r23` |  |  |
| 2624 | `jdg.pit.a26.r24` |  |  |
| 2625 | `jdg.pit.a26.r25` |  |  |
| 2701 | `jdg.pit.a27.r1` |  |  |
| 2701 | `jdg.pit.a27a.r1` |  |  |
| 2701 | `jdg.pit.a27g.r1` |  |  |
| 2702 | `jdg.pit.a27.r2` |  |  |
| 2702 | `jdg.pit.a27a.r2` |  |  |
| 2702 | `jdg.pit.a27g.r2` |  |  |
| 2703 | `jdg.pit.a27.r3` |  |  |
| 2703 | `jdg.pit.a27a.r3` |  |  |
| 2703 | `jdg.pit.a27g.r3` |  |  |
| 2704 | `jdg.pit.a27.r4` |  |  |
| 2704 | `jdg.pit.a27a.r4` |  |  |
| 2704 | `jdg.pit.a27g.r4` |  |  |
| 2705 | `jdg.pit.a27a.r5` |  |  |
| 2705 | `jdg.pit.a27g.r5` |  |  |
| 2706 | `jdg.pit.a27a.r6` |  |  |
| 2706 | `jdg.pit.a27g.r6` |  |  |
| 2707 | `jdg.pit.a27a.r7` |  |  |
| 2708 | `jdg.pit.a27a.r8` |  |  |
| 2709 | `jdg.pit.a27a.r9` |  |  |
| 2710 | `jdg.pit.a27.r10` |  |  |
| 2713 | `jdg.pit.a27.r13` |  |  |
| 2714 | `jdg.pit.a27.r14` |  |  |
| 2715 | `jdg.pit.a27.r15` |  |  |
| 3001 | `jdg.pit.a30ca.r1` |  |  |
| 3001 | `jdg.pit.a30a.r1` |  |  |
| 3001 | `jdg.pit.a30b.r1` |  |  |
| 3002 | `jdg.pit.a30ca.r2` |  |  |
| 3002 | `jdg.pit.a30a.r2` |  |  |
| 3002 | `jdg.pit.a30b.r2` |  |  |
| 3003 | `jdg.pit.a30ca.r3` |  |  |
| 3004 | `jdg.pit.a30ca.r4` |  |  |
| 3005 | `jdg.pit.a30ca.r5` |  |  |
| 3006 | `jdg.pit.a30b.r6` |  |  |
| 3006 | `jdg.pit.a30ca.r6` |  |  |
| 3007 | `jdg.pit.a30a.r7` |  |  |
| 3007 | `jdg.pit.a30ca.r7` |  |  |
| 3008 | `jdg.pit.a30ca.r8` |  |  |
| 3008 | `jdg.pit.a30a.r8` |  |  |
| 3009 | `jdg.pit.a30ca.r9` |  |  |
| 3010 | `jdg.pit.a30ca.r10` |  |  |
| 3101 | `jdg.pit.a31.r1` |  |  |
| 3102 | `jdg.pit.a31.r2` |  |  |
| 3103 | `jdg.pit.a31.r3` |  |  |
| 3105 | `jdg.pit.a31.r5` |  |  |
| 3106 | `jdg.pit.a31.r6` |  |  |
| 3114 | `jdg.pit.a31.r14` |  |  |
| 3201 | `jdg.pit.a32.r1` |  |  |
| 3202 | `jdg.pit.a32.r2` |  |  |
| 4501 | `jdg.pit.a45.r1` |  |  |
| 4502 | `jdg.pit.a45.r2` |  |  |
| 4503 | `jdg.pit.a45.r3` |  |  |
| 4505 | `jdg.pit.a45.r5` |  |  |
| 4507 | `jdg.pit.a45.r7` |  |  |
| 4509 | `jdg.pit.a45.r9` |  |  |
| 4510 | `jdg.pit.a45.r10` |  |  |

### `rules/micro/plan34_vat.rego` (179 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 501 | `jdg.vat.a5.r1` |  |  |
| 502 | `jdg.vat.a5.r2` |  |  |
| 503 | `jdg.vat.a5.r3` |  |  |
| 504 | `jdg.vat.a5.r4` |  |  |
| 505 | `jdg.vat.a5.r5` |  |  |
| 506 | `jdg.vat.a5.r6` |  |  |
| 507 | `jdg.vat.a5.r7` |  |  |
| 508 | `jdg.vat.a5.r8` |  |  |
| 509 | `jdg.vat.a5.r9` |  |  |
| 510 | `jdg.vat.a5.r10` |  |  |
| 701 | `jdg.vat.a7.r1` |  |  |
| 702 | `jdg.vat.a7.r2` |  |  |
| 703 | `jdg.vat.a7.r3` |  |  |
| 704 | `jdg.vat.a7.r4` |  |  |
| 705 | `jdg.vat.a7.r5` |  |  |
| 706 | `jdg.vat.a7.r6` |  |  |
| 707 | `jdg.vat.a7.r7` |  |  |
| 708 | `jdg.vat.a7.r8` |  |  |
| 709 | `jdg.vat.a7.r9` |  |  |
| 710 | `jdg.vat.a7.r10` |  |  |
| 711 | `jdg.vat.a7.r11` |  |  |
| 712 | `jdg.vat.a7.r12` |  |  |
| 1501 | `jdg.vat.a15.r1` |  |  |
| 1502 | `jdg.vat.a15.r2` |  |  |
| 1503 | `jdg.vat.a15.r3` |  |  |
| 1504 | `jdg.vat.a15.r4` |  |  |
| 1901 | `jdg.vat.a19a.r1` |  |  |
| 1902 | `jdg.vat.a19a.r2` |  |  |
| 1903 | `jdg.vat.a19a.r3` |  |  |
| 1904 | `jdg.vat.a19a.r4` |  |  |
| 1905 | `jdg.vat.a19a.r5` |  |  |
| 1906 | `jdg.vat.a19a.r6` |  |  |
| 1907 | `jdg.vat.a19a.r7` |  |  |
| 1908 | `jdg.vat.a19a.r8` |  |  |
| 1909 | `jdg.vat.a19a.r9` |  |  |
| 1910 | `jdg.vat.a19a.r10` |  |  |
| 1911 | `jdg.vat.a19a.r11` |  |  |
| 1912 | `jdg.vat.a19a.r12` |  |  |
| 1913 | `jdg.vat.a19a.r13` |  |  |
| 1914 | `jdg.vat.a19a.r14` |  |  |
| 1915 | `jdg.vat.a19a.r15` |  |  |
| 2001 | `jdg.vat.a20.r1` |  |  |
| 2002 | `jdg.vat.a20.r2` |  |  |
| 2003 | `jdg.vat.a20.r3` |  |  |
| 2004 | `jdg.vat.a20.r4` |  |  |
| 2005 | `jdg.vat.a20.r5` |  |  |
| 2101 | `jdg.vat.a21.r1` |  |  |
| 2102 | `jdg.vat.a21.r2` |  |  |
| 2103 | `jdg.vat.a21.r3` |  |  |
| 2104 | `jdg.vat.a21.r4` |  |  |
| 2105 | `jdg.vat.a21.r5` |  |  |
| 2106 | `jdg.vat.a21.r6` |  |  |
| 2107 | `jdg.vat.a21.r7` |  |  |
| 2108 | `jdg.vat.a21.r8` |  |  |
| 2109 | `jdg.vat.a21.r9` |  |  |
| 2110 | `jdg.vat.a21.r10` |  |  |
| 2901 | `jdg.vat.a29a.r1` |  |  |
| 2902 | `jdg.vat.a29a.r2` |  |  |
| 2903 | `jdg.vat.a29a.r3` |  |  |
| 2904 | `jdg.vat.a29a.r4` |  |  |
| 2905 | `jdg.vat.a29a.r5` |  |  |
| 2906 | `jdg.vat.a29a.r6` |  |  |
| 2907 | `jdg.vat.a29a.r7` |  |  |
| 2908 | `jdg.vat.a29a.r8` |  |  |
| 2909 | `jdg.vat.a29a.r9` |  |  |
| 2910 | `jdg.vat.a29a.r10` |  |  |
| 2911 | `jdg.vat.a29a.r11` |  |  |
| 2912 | `jdg.vat.a29a.r12` |  |  |
| 2913 | `jdg.vat.a29a.r13` |  |  |
| 2914 | `jdg.vat.a29a.r14` |  |  |
| 2915 | `jdg.vat.a29a.r15` |  |  |
| 4101 | `jdg.vat.a41.r1` |  |  |
| 4102 | `jdg.vat.a41.r2` |  |  |
| 4103 | `jdg.vat.a41.r3` |  |  |
| 4104 | `jdg.vat.a41.r4` |  |  |
| 4105 | `jdg.vat.a41.r5` |  |  |
| 4107 | `jdg.vat.a41.r7` |  |  |
| 4112 | `jdg.vat.a41.r12` |  |  |
| 4113 | `jdg.vat.a41.r13` |  |  |
| 4116 | `jdg.vat.a41.r16` |  |  |
| 4117 | `jdg.vat.a41.r17` |  |  |
| 4118 | `jdg.vat.a41.r18` |  |  |
| 4121 | `jdg.vat.a41.r21` |  |  |
| 4123 | `jdg.vat.a41.r23` |  |  |
| 4124 | `jdg.vat.a41.r24` |  |  |
| 4126 | `jdg.vat.a41.r26` |  |  |
| 4128 | `jdg.vat.a41.r28` |  |  |
| 4129 | `jdg.vat.a41.r29` |  |  |
| 4131 | `jdg.vat.a41.r31` |  |  |
| 4136 | `jdg.vat.a41.r36` |  |  |
| 4138 | `jdg.vat.a41.r38` |  |  |
| 4142 | `jdg.vat.a41.r42` |  |  |
| 4145 | `jdg.vat.a41.r45` |  |  |
| 4146 | `jdg.vat.a41.r46` |  |  |
| 4149 | `jdg.vat.a41.r49` |  |  |
| 4301 | `jdg.vat.a43.r1` |  |  |
| 4302 | `jdg.vat.a43.r2` |  |  |
| 4303 | `jdg.vat.a43.r3` |  |  |
| 4304 | `jdg.vat.a43.r4` |  |  |
| 4306 | `jdg.vat.a43.r6` |  |  |
| 4307 | `jdg.vat.a43.r7` |  |  |
| 4308 | `jdg.vat.a43.r8` |  |  |
| 4309 | `jdg.vat.a43.r9` |  |  |
| 4310 | `jdg.vat.a43.r10` |  |  |
| 4311 | `jdg.vat.a43.r11` |  |  |
| 4315 | `jdg.vat.a43.r15` |  |  |
| 4318 | `jdg.vat.a43.r18` |  |  |
| 4319 | `jdg.vat.a43.r19` |  |  |
| 4320 | `jdg.vat.a43.r20` |  |  |
| 4335 | `jdg.vat.a43.r35` |  |  |
| 4336 | `jdg.vat.a43.r36` |  |  |
| 4339 | `jdg.vat.a43.r39` |  |  |
| 8601 | `jdg.vat.a86.r1` |  |  |
| 8601 | `jdg.vat.a86a.r1` |  |  |
| 8602 | `jdg.vat.a86.r2` |  |  |
| 8602 | `jdg.vat.a86a.r2` |  |  |
| 8603 | `jdg.vat.a86.r3` |  |  |
| 8603 | `jdg.vat.a86a.r3` |  |  |
| 8604 | `jdg.vat.a86.r4` |  |  |
| 8604 | `jdg.vat.a86a.r4` |  |  |
| 8605 | `jdg.vat.a86.r5` |  |  |
| 8605 | `jdg.vat.a86a.r5` |  |  |
| 8606 | `jdg.vat.a86.r6` |  |  |
| 8606 | `jdg.vat.a86a.r6` |  |  |
| 8607 | `jdg.vat.a86.r7` |  |  |
| 8607 | `jdg.vat.a86a.r7` |  |  |
| 8608 | `jdg.vat.a86.r8` |  |  |
| 8608 | `jdg.vat.a86a.r8` |  |  |
| 8609 | `jdg.vat.a86.r9` |  |  |
| 8610 | `jdg.vat.a86.r10` |  |  |
| 8613 | `jdg.vat.a86.r13` |  |  |
| 8615 | `jdg.vat.a86.r15` |  |  |
| 8616 | `jdg.vat.a86.r16` |  |  |
| 8801 | `jdg.vat.a88.r1` |  |  |
| 8802 | `jdg.vat.a88.r2` |  |  |
| 8803 | `jdg.vat.a88.r3` |  |  |
| 8804 | `jdg.vat.a88.r4` |  |  |
| 8805 | `jdg.vat.a88.r5` |  |  |
| 8807 | `jdg.vat.a88.r7` |  |  |
| 8808 | `jdg.vat.a88.r8` |  |  |
| 8813 | `jdg.vat.a88.r13` |  |  |
| 8901 | `jdg.vat.a89a.r1` |  |  |
| 8901 | `jdg.vat.a89b.r1` |  |  |
| 8902 | `jdg.vat.a89a.r2` |  |  |
| 8902 | `jdg.vat.a89b.r2` |  |  |
| 8903 | `jdg.vat.a89a.r3` |  |  |
| 8904 | `jdg.vat.a89b.r4` |  |  |
| 8905 | `jdg.vat.a89a.r5` |  |  |
| 9601 | `jdg.vat.a96.r1` |  |  |
| 9602 | `jdg.vat.a96.r2` |  |  |
| 9603 | `jdg.vat.a96.r3` |  |  |
| 9604 | `jdg.vat.a96.r4` |  |  |
| 9605 | `jdg.vat.a96.r5` |  |  |
| 9606 | `jdg.vat.a96.r6` |  |  |
| 9607 | `jdg.vat.a96.r7` |  |  |
| 9608 | `jdg.vat.a96.r8` |  |  |
| 9609 | `jdg.vat.a96.r9` |  |  |
| 9610 | `jdg.vat.a96.r10` |  |  |
| 9611 | `jdg.vat.a96.r11` |  |  |
| 9901 | `jdg.vat.a99.r1` |  |  |
| 9902 | `jdg.vat.a99.r2` |  |  |
| 9904 | `jdg.vat.a99.r4` |  |  |
| 9905 | `jdg.vat.a99.r5` |  |  |
| 10601 | `jdg.vat.a106e.r1` |  |  |
| 10601 | `jdg.vat.a106j.r1` |  |  |
| 10601 | `jdg.vat.a106na.r1` |  |  |
| 10601 | `jdg.vat.a106ne.r1` |  |  |
| 10601 | `jdg.vat.a106ng.r1` |  |  |
| 10601 | `jdg.vat.a106nh.r1` |  |  |
| 10601 | `jdg.vat.a106nq.r1` |  |  |
| 10602 | `jdg.vat.a106e.r2` |  |  |
| 10603 | `jdg.vat.a106j.r3` |  |  |
| 10603 | `jdg.vat.a106na.r3` |  |  |
| 10604 | `jdg.vat.a106na.r4` |  |  |
| 10605 | `jdg.vat.a106e.r5` |  |  |
| 10606 | `jdg.vat.a106e.r6` |  |  |
| 10608 | `jdg.vat.a106j.r8` |  |  |
| 10610 | `jdg.vat.a106e.r10` |  |  |
| 10614 | `jdg.vat.a106e.r14` |  |  |

### `rules/micro/plan34_zus.rego` (20 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 601 | `jdg.zus.a6.r1` |  |  |
| 602 | `jdg.zus.a6.r2` |  |  |
| 603 | `jdg.zus.a6.r3` |  |  |
| 604 | `jdg.zus.a6.r4` |  |  |
| 605 | `jdg.zus.a6.r5` |  |  |
| 606 | `jdg.zus.a6.r6` |  |  |
| 701 | `jdg.zus.a7.r1` |  |  |
| 801 | `jdg.zus.a8.r1` |  |  |
| 802 | `jdg.zus.a8.r2` |  |  |
| 803 | `jdg.zus.a8.r3` |  |  |
| 804 | `jdg.zus.a8.r4` |  |  |
| 805 | `jdg.zus.a8.r5` |  |  |
| 901 | `jdg.zus.a9.r1` |  |  |
| 902 | `jdg.zus.a9.r2` |  |  |
| 903 | `jdg.zus.a9.r3` |  |  |
| 1001 | `jdg.zus.a10.r1` |  |  |
| 1002 | `jdg.zus.a10.r2` |  |  |
| 1101 | `jdg.zus.a11.r1` |  |  |
| 1201 | `jdg.zus.a12.r1` |  |  |
| 1301 | `jdg.zus.a13.r1` |  |  |

### `rules/micro/pp/pp.rego` (92 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 130003 | `jdg.micro.pp.a3.r1` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130004 | `jdg.micro.pp.a3.r2` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130005 | `jdg.micro.pp.a3.r3` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130006 | `jdg.micro.pp.a3.r4` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130007 | `jdg.micro.pp.a3.r5` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130008 | `jdg.micro.pp.a3.r6` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130009 | `jdg.micro.pp.a3.r7` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130010 | `jdg.micro.pp.a3.r8` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130011 | `jdg.micro.pp.a3.r9` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130012 | `jdg.micro.pp.a3.r10` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130013 | `jdg.micro.pp.a4.r1` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130014 | `jdg.micro.pp.a4.r2` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130015 | `jdg.micro.pp.a4.r3` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130016 | `jdg.micro.pp.a4.r4` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130017 | `jdg.micro.pp.a4.r5` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130018 | `jdg.micro.pp.a4.r6` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130019 | `jdg.micro.pp.a4.r7` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130020 | `jdg.micro.pp.a4.r8` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130021 | `jdg.micro.pp.a4.r9` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130022 | `jdg.micro.pp.a4.r10` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130023 | `jdg.micro.pp.a5.r1` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130024 | `jdg.micro.pp.a5.r2` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130025 | `jdg.micro.pp.a5.r3` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130026 | `jdg.micro.pp.a5.r4` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130027 | `jdg.micro.pp.a5.r5` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130028 | `jdg.micro.pp.a5.r6` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130029 | `jdg.micro.pp.a5.r7` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130030 | `jdg.micro.pp.a5.r8` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130031 | `jdg.micro.pp.a5.r9` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130032 | `jdg.micro.pp.a5.r10` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130033 | `jdg.micro.pp.a5.r11` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130034 | `jdg.micro.pp.a5.r12` | 🔴 BLOCK | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130035 | `jdg.micro.pp.a14.r1` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130036 | `jdg.micro.pp.a14.r2` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130037 | `jdg.micro.pp.a14.r3` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130038 | `jdg.micro.pp.a14.r4` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130039 | `jdg.micro.pp.a14.r5` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130040 | `jdg.micro.pp.a14.r6` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130041 | `jdg.micro.pp.a14.r7` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130042 | `jdg.micro.pp.a14.r8` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130043 | `jdg.micro.pp.a17.r1` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130044 | `jdg.micro.pp.a17.r2` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130045 | `jdg.micro.pp.a17.r3` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130046 | `jdg.micro.pp.a17.r4` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130047 | `jdg.micro.pp.a17.r5` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130048 | `jdg.micro.pp.a17.r6` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130049 | `jdg.micro.pp.a17.r7` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130050 | `jdg.micro.pp.a17.r8` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130051 | `jdg.micro.pp.a22.r1` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130052 | `jdg.micro.pp.a22.r2` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130053 | `jdg.micro.pp.a22.r3` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130054 | `jdg.micro.pp.a22.r4` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130055 | `jdg.micro.pp.a22.r5` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130056 | `jdg.micro.pp.a22.r6` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130057 | `jdg.micro.pp.a22.r7` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130058 | `jdg.micro.pp.a22.r8` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130059 | `jdg.micro.pp.a22.r9` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130060 | `jdg.micro.pp.a22.r10` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130061 | `jdg.micro.pp.a23.r1` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130062 | `jdg.micro.pp.a23.r2` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130063 | `jdg.micro.pp.a23.r3` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130064 | `jdg.micro.pp.a23.r4` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130065 | `jdg.micro.pp.a23.r5` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130066 | `jdg.micro.pp.a23.r6` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130067 | `jdg.micro.pp.a23.r7` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130068 | `jdg.micro.pp.a23.r8` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130069 | `jdg.micro.pp.a25.r1` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130070 | `jdg.micro.pp.a25.r2` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130071 | `jdg.micro.pp.a25.r3` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130072 | `jdg.micro.pp.a25.r4` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130073 | `jdg.micro.pp.a25.r5` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130074 | `jdg.micro.pp.a25.r6` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130075 | `jdg.micro.pp.a25.r7` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130076 | `jdg.micro.pp.a25.r8` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130077 | `jdg.micro.pp.a34.r1` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130078 | `jdg.micro.pp.a34.r2` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130079 | `jdg.micro.pp.a34.r3` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130080 | `jdg.micro.pp.a34.r4` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130081 | `jdg.micro.pp.a34.r5` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130082 | `jdg.micro.pp.a34.r6` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130083 | `jdg.micro.pp.a34.r7` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130084 | `jdg.micro.pp.a34.r8` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130085 | `jdg.micro.pp.a34.r9` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130086 | `jdg.micro.pp.a34.r10` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130087 | `jdg.micro.pp.a36.r1` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130088 | `jdg.micro.pp.a36.r2` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130089 | `jdg.micro.pp.a36.r3` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130090 | `jdg.micro.pp.a36.r4` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130091 | `jdg.micro.pp.a36.r5` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130092 | `jdg.micro.pp.a36.r6` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130093 | `jdg.micro.pp.a36.r7` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |
| 130094 | `jdg.micro.pp.a36.r8` |  | Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646) |

### `rules/micro/rodo/rodo.rego` (40 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 210006 | `jdg.micro.rodo.a6.r1` |  | RODO — Rozporządzenie UE 2016/679 |
| 210007 | `jdg.micro.rodo.a6.r2` |  | RODO — Rozporządzenie UE 2016/679 |
| 210008 | `jdg.micro.rodo.a6.r3` |  | RODO — Rozporządzenie UE 2016/679 |
| 210009 | `jdg.micro.rodo.a6.r4` |  | RODO — Rozporządzenie UE 2016/679 |
| 210010 | `jdg.micro.rodo.a6.r5` |  | RODO — Rozporządzenie UE 2016/679 |
| 210011 | `jdg.micro.rodo.a6.r6` |  | RODO — Rozporządzenie UE 2016/679 |
| 210012 | `jdg.micro.rodo.a6.r7` |  | RODO — Rozporządzenie UE 2016/679 |
| 210013 | `jdg.micro.rodo.a6.r8` |  | RODO — Rozporządzenie UE 2016/679 |
| 210014 | `jdg.micro.rodo.a13.r1` |  | RODO — Rozporządzenie UE 2016/679 |
| 210015 | `jdg.micro.rodo.a13.r2` |  | RODO — Rozporządzenie UE 2016/679 |
| 210016 | `jdg.micro.rodo.a13.r3` |  | RODO — Rozporządzenie UE 2016/679 |
| 210017 | `jdg.micro.rodo.a13.r4` |  | RODO — Rozporządzenie UE 2016/679 |
| 210018 | `jdg.micro.rodo.a13.r5` |  | RODO — Rozporządzenie UE 2016/679 |
| 210019 | `jdg.micro.rodo.a13.r6` |  | RODO — Rozporządzenie UE 2016/679 |
| 210020 | `jdg.micro.rodo.a13.r7` |  | RODO — Rozporządzenie UE 2016/679 |
| 210021 | `jdg.micro.rodo.a13.r8` |  | RODO — Rozporządzenie UE 2016/679 |
| 210022 | `jdg.micro.rodo.a15.r1` |  | RODO — Rozporządzenie UE 2016/679 |
| 210023 | `jdg.micro.rodo.a15.r2` |  | RODO — Rozporządzenie UE 2016/679 |
| 210024 | `jdg.micro.rodo.a15.r3` |  | RODO — Rozporządzenie UE 2016/679 |
| 210025 | `jdg.micro.rodo.a15.r4` |  | RODO — Rozporządzenie UE 2016/679 |
| 210026 | `jdg.micro.rodo.a15.r5` |  | RODO — Rozporządzenie UE 2016/679 |
| 210027 | `jdg.micro.rodo.a15.r6` |  | RODO — Rozporządzenie UE 2016/679 |
| 210028 | `jdg.micro.rodo.a15.r7` |  | RODO — Rozporządzenie UE 2016/679 |
| 210029 | `jdg.micro.rodo.a15.r8` |  | RODO — Rozporządzenie UE 2016/679 |
| 210030 | `jdg.micro.rodo.a32.r1` |  | RODO — Rozporządzenie UE 2016/679 |
| 210031 | `jdg.micro.rodo.a32.r2` |  | RODO — Rozporządzenie UE 2016/679 |
| 210032 | `jdg.micro.rodo.a32.r3` |  | RODO — Rozporządzenie UE 2016/679 |
| 210033 | `jdg.micro.rodo.a32.r4` |  | RODO — Rozporządzenie UE 2016/679 |
| 210034 | `jdg.micro.rodo.a32.r5` |  | RODO — Rozporządzenie UE 2016/679 |
| 210035 | `jdg.micro.rodo.a32.r6` |  | RODO — Rozporządzenie UE 2016/679 |
| 210036 | `jdg.micro.rodo.a32.r7` |  | RODO — Rozporządzenie UE 2016/679 |
| 210037 | `jdg.micro.rodo.a32.r8` |  | RODO — Rozporządzenie UE 2016/679 |
| 210038 | `jdg.micro.rodo.a33.r1` |  | RODO — Rozporządzenie UE 2016/679 |
| 210039 | `jdg.micro.rodo.a33.r2` |  | RODO — Rozporządzenie UE 2016/679 |
| 210040 | `jdg.micro.rodo.a33.r3` |  | RODO — Rozporządzenie UE 2016/679 |
| 210041 | `jdg.micro.rodo.a33.r4` |  | RODO — Rozporządzenie UE 2016/679 |
| 210042 | `jdg.micro.rodo.a33.r5` |  | RODO — Rozporządzenie UE 2016/679 |
| 210043 | `jdg.micro.rodo.a33.r6` |  | RODO — Rozporządzenie UE 2016/679 |
| 210044 | `jdg.micro.rodo.a33.r7` |  | RODO — Rozporządzenie UE 2016/679 |
| 210045 | `jdg.micro.rodo.a33.r8` |  | RODO — Rozporządzenie UE 2016/679 |

### `rules/micro/ryczalt/ryczalt.rego` (97 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 100004 | `jdg.micro.ryczalt.a4.r1` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100005 | `jdg.micro.ryczalt.a4.r2` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100006 | `jdg.micro.ryczalt.a4.r3` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100007 | `jdg.micro.ryczalt.a4.r4` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100008 | `jdg.micro.ryczalt.a4.r5` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100009 | `jdg.micro.ryczalt.a4.r6` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100010 | `jdg.micro.ryczalt.a4.r7` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100011 | `jdg.micro.ryczalt.a4.r8` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100012 | `jdg.micro.ryczalt.a4.r9` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100013 | `jdg.micro.ryczalt.a4.r10` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100014 | `jdg.micro.ryczalt.a4.r11` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100015 | `jdg.micro.ryczalt.a4.r12` | 🔴 BLOCK | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100016 | `jdg.micro.ryczalt.a6.r1` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100017 | `jdg.micro.ryczalt.a6.r2` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100018 | `jdg.micro.ryczalt.a6.r3` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100019 | `jdg.micro.ryczalt.a6.r4` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100020 | `jdg.micro.ryczalt.a6.r5` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100021 | `jdg.micro.ryczalt.a6.r6` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100022 | `jdg.micro.ryczalt.a6.r7` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100023 | `jdg.micro.ryczalt.a6.r8` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100024 | `jdg.micro.ryczalt.a6.r9` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100025 | `jdg.micro.ryczalt.a6.r10` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100026 | `jdg.micro.ryczalt.a8.r1` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100027 | `jdg.micro.ryczalt.a8.r2` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100028 | `jdg.micro.ryczalt.a8.r3` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100029 | `jdg.micro.ryczalt.a8.r4` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100030 | `jdg.micro.ryczalt.a8.r5` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100031 | `jdg.micro.ryczalt.a8.r6` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100032 | `jdg.micro.ryczalt.a8.r7` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100033 | `jdg.micro.ryczalt.a8.r8` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100034 | `jdg.micro.ryczalt.a8.r9` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100035 | `jdg.micro.ryczalt.a8.r10` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100036 | `jdg.micro.ryczalt.a8.r11` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100037 | `jdg.micro.ryczalt.a8.r12` | 🔴 BLOCK | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100038 | `jdg.micro.ryczalt.a8.r13` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100039 | `jdg.micro.ryczalt.a8.r14` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100040 | `jdg.micro.ryczalt.a8.r15` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100041 | `jdg.micro.ryczalt.a12.r1` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100042 | `jdg.micro.ryczalt.a12.r2` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100043 | `jdg.micro.ryczalt.a12.r3` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100044 | `jdg.micro.ryczalt.a12.r4` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100045 | `jdg.micro.ryczalt.a12.r5` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100046 | `jdg.micro.ryczalt.a12.r6` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100047 | `jdg.micro.ryczalt.a12.r7` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100048 | `jdg.micro.ryczalt.a12.r8` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100049 | `jdg.micro.ryczalt.a12.r9` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100050 | `jdg.micro.ryczalt.a12.r10` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100051 | `jdg.micro.ryczalt.a12.r11` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100052 | `jdg.micro.ryczalt.a12.r12` | 🔴 BLOCK | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100053 | `jdg.micro.ryczalt.a12.r13` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100054 | `jdg.micro.ryczalt.a12.r14` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100055 | `jdg.micro.ryczalt.a12.r15` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100056 | `jdg.micro.ryczalt.a12.r16` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100057 | `jdg.micro.ryczalt.a12.r17` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100058 | `jdg.micro.ryczalt.a12.r18` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100059 | `jdg.micro.ryczalt.a15.r1` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100060 | `jdg.micro.ryczalt.a15.r2` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100061 | `jdg.micro.ryczalt.a15.r3` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100062 | `jdg.micro.ryczalt.a15.r4` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100063 | `jdg.micro.ryczalt.a15.r5` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100064 | `jdg.micro.ryczalt.a15.r6` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100065 | `jdg.micro.ryczalt.a15.r7` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100066 | `jdg.micro.ryczalt.a15.r8` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100067 | `jdg.micro.ryczalt.a15.r9` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100068 | `jdg.micro.ryczalt.a15.r10` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100069 | `jdg.micro.ryczalt.a21.r1` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100070 | `jdg.micro.ryczalt.a21.r2` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100071 | `jdg.micro.ryczalt.a21.r3` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100072 | `jdg.micro.ryczalt.a21.r4` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100073 | `jdg.micro.ryczalt.a21.r5` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100074 | `jdg.micro.ryczalt.a21.r6` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100075 | `jdg.micro.ryczalt.a21.r7` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100076 | `jdg.micro.ryczalt.a21.r8` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100077 | `jdg.micro.ryczalt.a21.r9` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100078 | `jdg.micro.ryczalt.a21.r10` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100079 | `jdg.micro.ryczalt.a21.r11` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100080 | `jdg.micro.ryczalt.a21.r12` | 🔴 BLOCK | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100081 | `jdg.micro.ryczalt.a27.r1` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100082 | `jdg.micro.ryczalt.a27.r2` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100083 | `jdg.micro.ryczalt.a27.r3` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100084 | `jdg.micro.ryczalt.a27.r4` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100085 | `jdg.micro.ryczalt.a27.r5` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100086 | `jdg.micro.ryczalt.a27.r6` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100087 | `jdg.micro.ryczalt.a27.r7` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100088 | `jdg.micro.ryczalt.a27.r8` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100089 | `jdg.micro.ryczalt.a27.r9` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100090 | `jdg.micro.ryczalt.a27.r10` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100091 | `jdg.micro.ryczalt.a27.r11` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100092 | `jdg.micro.ryczalt.a27.r12` | 🔴 BLOCK | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100093 | `jdg.micro.ryczalt.a30.r1` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100094 | `jdg.micro.ryczalt.a30.r2` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100095 | `jdg.micro.ryczalt.a30.r3` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100096 | `jdg.micro.ryczalt.a30.r4` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100097 | `jdg.micro.ryczalt.a30.r5` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100098 | `jdg.micro.ryczalt.a30.r6` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100099 | `jdg.micro.ryczalt.a30.r7` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |
| 100100 | `jdg.micro.ryczalt.a30.r8` |  | Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930) |

### `rules/micro/srodowisko/srodowisko.rego` (48 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 220007 | `jdg.micro.srodowisko.a7.r1` |  | Ustawa o odpadach, SUP, CBAM |
| 220008 | `jdg.micro.srodowisko.a7.r2` |  | Ustawa o odpadach, SUP, CBAM |
| 220009 | `jdg.micro.srodowisko.a7.r3` |  | Ustawa o odpadach, SUP, CBAM |
| 220010 | `jdg.micro.srodowisko.a7.r4` |  | Ustawa o odpadach, SUP, CBAM |
| 220011 | `jdg.micro.srodowisko.a7.r5` |  | Ustawa o odpadach, SUP, CBAM |
| 220012 | `jdg.micro.srodowisko.a7.r6` |  | Ustawa o odpadach, SUP, CBAM |
| 220013 | `jdg.micro.srodowisko.a7.r7` |  | Ustawa o odpadach, SUP, CBAM |
| 220014 | `jdg.micro.srodowisko.a7.r8` |  | Ustawa o odpadach, SUP, CBAM |
| 220015 | `jdg.micro.srodowisko.a10.r1` |  | Ustawa o odpadach, SUP, CBAM |
| 220016 | `jdg.micro.srodowisko.a10.r2` |  | Ustawa o odpadach, SUP, CBAM |
| 220017 | `jdg.micro.srodowisko.a10.r3` |  | Ustawa o odpadach, SUP, CBAM |
| 220018 | `jdg.micro.srodowisko.a10.r4` |  | Ustawa o odpadach, SUP, CBAM |
| 220019 | `jdg.micro.srodowisko.a10.r5` |  | Ustawa o odpadach, SUP, CBAM |
| 220020 | `jdg.micro.srodowisko.a10.r6` |  | Ustawa o odpadach, SUP, CBAM |
| 220021 | `jdg.micro.srodowisko.a10.r7` |  | Ustawa o odpadach, SUP, CBAM |
| 220022 | `jdg.micro.srodowisko.a10.r8` |  | Ustawa o odpadach, SUP, CBAM |
| 220023 | `jdg.micro.srodowisko.a10.r9` |  | Ustawa o odpadach, SUP, CBAM |
| 220024 | `jdg.micro.srodowisko.a10.r10` |  | Ustawa o odpadach, SUP, CBAM |
| 220025 | `jdg.micro.srodowisko.a15.r1` |  | Ustawa o odpadach, SUP, CBAM |
| 220026 | `jdg.micro.srodowisko.a15.r2` |  | Ustawa o odpadach, SUP, CBAM |
| 220027 | `jdg.micro.srodowisko.a15.r3` |  | Ustawa o odpadach, SUP, CBAM |
| 220028 | `jdg.micro.srodowisko.a15.r4` |  | Ustawa o odpadach, SUP, CBAM |
| 220029 | `jdg.micro.srodowisko.a15.r5` |  | Ustawa o odpadach, SUP, CBAM |
| 220030 | `jdg.micro.srodowisko.a15.r6` |  | Ustawa o odpadach, SUP, CBAM |
| 220031 | `jdg.micro.srodowisko.a15.r7` |  | Ustawa o odpadach, SUP, CBAM |
| 220032 | `jdg.micro.srodowisko.a15.r8` |  | Ustawa o odpadach, SUP, CBAM |
| 220033 | `jdg.micro.srodowisko.a3s.r1` |  | Ustawa o odpadach, SUP, CBAM |
| 220034 | `jdg.micro.srodowisko.a3s.r2` |  | Ustawa o odpadach, SUP, CBAM |
| 220035 | `jdg.micro.srodowisko.a3s.r3` |  | Ustawa o odpadach, SUP, CBAM |
| 220036 | `jdg.micro.srodowisko.a3s.r4` |  | Ustawa o odpadach, SUP, CBAM |
| 220037 | `jdg.micro.srodowisko.a3s.r5` |  | Ustawa o odpadach, SUP, CBAM |
| 220038 | `jdg.micro.srodowisko.a3s.r6` |  | Ustawa o odpadach, SUP, CBAM |
| 220039 | `jdg.micro.srodowisko.a3s.r7` |  | Ustawa o odpadach, SUP, CBAM |
| 220040 | `jdg.micro.srodowisko.a3s.r8` |  | Ustawa o odpadach, SUP, CBAM |
| 220041 | `jdg.micro.srodowisko.a5s.r1` |  | Ustawa o odpadach, SUP, CBAM |
| 220042 | `jdg.micro.srodowisko.a5s.r2` |  | Ustawa o odpadach, SUP, CBAM |
| 220043 | `jdg.micro.srodowisko.a5s.r3` |  | Ustawa o odpadach, SUP, CBAM |
| 220044 | `jdg.micro.srodowisko.a5s.r4` |  | Ustawa o odpadach, SUP, CBAM |
| 220045 | `jdg.micro.srodowisko.a5s.r5` |  | Ustawa o odpadach, SUP, CBAM |
| 220046 | `jdg.micro.srodowisko.a5s.r6` |  | Ustawa o odpadach, SUP, CBAM |
| 220047 | `jdg.micro.srodowisko.a8.r1` |  | Ustawa o odpadach, SUP, CBAM |
| 220048 | `jdg.micro.srodowisko.a8.r2` |  | Ustawa o odpadach, SUP, CBAM |
| 220049 | `jdg.micro.srodowisko.a8.r3` |  | Ustawa o odpadach, SUP, CBAM |
| 220050 | `jdg.micro.srodowisko.a8.r4` |  | Ustawa o odpadach, SUP, CBAM |
| 220051 | `jdg.micro.srodowisko.a8.r5` |  | Ustawa o odpadach, SUP, CBAM |
| 220052 | `jdg.micro.srodowisko.a8.r6` |  | Ustawa o odpadach, SUP, CBAM |
| 220053 | `jdg.micro.srodowisko.a8.r7` |  | Ustawa o odpadach, SUP, CBAM |
| 220054 | `jdg.micro.srodowisko.a8.r8` |  | Ustawa o odpadach, SUP, CBAM |

### `rules/micro/sukcesja/sukcesja.rego` (38 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 150003 | `jdg.micro.sukcesja.a3.r1` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150004 | `jdg.micro.sukcesja.a3.r2` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150005 | `jdg.micro.sukcesja.a3.r3` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150006 | `jdg.micro.sukcesja.a3.r4` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150007 | `jdg.micro.sukcesja.a3.r5` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150008 | `jdg.micro.sukcesja.a3.r6` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150009 | `jdg.micro.sukcesja.a3.r7` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150010 | `jdg.micro.sukcesja.a3.r8` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150011 | `jdg.micro.sukcesja.a12.r1` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150012 | `jdg.micro.sukcesja.a12.r2` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150013 | `jdg.micro.sukcesja.a12.r3` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150014 | `jdg.micro.sukcesja.a12.r4` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150015 | `jdg.micro.sukcesja.a12.r5` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150016 | `jdg.micro.sukcesja.a12.r6` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150017 | `jdg.micro.sukcesja.a12.r7` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150018 | `jdg.micro.sukcesja.a12.r8` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150019 | `jdg.micro.sukcesja.a14.r1` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150020 | `jdg.micro.sukcesja.a14.r2` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150021 | `jdg.micro.sukcesja.a14.r3` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150022 | `jdg.micro.sukcesja.a14.r4` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150023 | `jdg.micro.sukcesja.a14.r5` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150024 | `jdg.micro.sukcesja.a14.r6` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150025 | `jdg.micro.sukcesja.a14.r7` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150026 | `jdg.micro.sukcesja.a14.r8` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150027 | `jdg.micro.sukcesja.a21.r1` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150028 | `jdg.micro.sukcesja.a21.r2` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150029 | `jdg.micro.sukcesja.a21.r3` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150030 | `jdg.micro.sukcesja.a21.r4` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150031 | `jdg.micro.sukcesja.a21.r5` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150032 | `jdg.micro.sukcesja.a21.r6` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150033 | `jdg.micro.sukcesja.a21.r7` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150034 | `jdg.micro.sukcesja.a21.r8` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150035 | `jdg.micro.sukcesja.a24.r1` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150036 | `jdg.micro.sukcesja.a24.r2` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150037 | `jdg.micro.sukcesja.a24.r3` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150038 | `jdg.micro.sukcesja.a24.r4` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150039 | `jdg.micro.sukcesja.a24.r5` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |
| 150040 | `jdg.micro.sukcesja.a24.r6` |  | Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz.... |

### `rules/micro/sus/sus.rego` (122 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 90006 | `jdg.micro.sus.a6.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90007 | `jdg.micro.sus.a6.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90008 | `jdg.micro.sus.a6.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90009 | `jdg.micro.sus.a6.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90010 | `jdg.micro.sus.a6.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90011 | `jdg.micro.sus.a6.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90012 | `jdg.micro.sus.a6.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90013 | `jdg.micro.sus.a6.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90014 | `jdg.micro.sus.a6b.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90015 | `jdg.micro.sus.a6b.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90016 | `jdg.micro.sus.a6b.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90017 | `jdg.micro.sus.a6b.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90018 | `jdg.micro.sus.a6b.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90019 | `jdg.micro.sus.a6b.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90020 | `jdg.micro.sus.a9.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90021 | `jdg.micro.sus.a9.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90022 | `jdg.micro.sus.a9.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90023 | `jdg.micro.sus.a9.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90024 | `jdg.micro.sus.a9.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90025 | `jdg.micro.sus.a9.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90026 | `jdg.micro.sus.a9.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90027 | `jdg.micro.sus.a9.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90028 | `jdg.micro.sus.a11.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90029 | `jdg.micro.sus.a11.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90030 | `jdg.micro.sus.a11.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90031 | `jdg.micro.sus.a11.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90032 | `jdg.micro.sus.a11.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90033 | `jdg.micro.sus.a11.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90034 | `jdg.micro.sus.a11.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90035 | `jdg.micro.sus.a11.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90036 | `jdg.micro.sus.a13.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90037 | `jdg.micro.sus.a13.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90038 | `jdg.micro.sus.a13.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90039 | `jdg.micro.sus.a13.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90040 | `jdg.micro.sus.a13.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90041 | `jdg.micro.sus.a13.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90042 | `jdg.micro.sus.a13.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90043 | `jdg.micro.sus.a13.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90044 | `jdg.micro.sus.a14.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90045 | `jdg.micro.sus.a14.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90046 | `jdg.micro.sus.a14.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90047 | `jdg.micro.sus.a14.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90048 | `jdg.micro.sus.a14.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90049 | `jdg.micro.sus.a14.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90050 | `jdg.micro.sus.a14.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90051 | `jdg.micro.sus.a14.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90052 | `jdg.micro.sus.a18.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90053 | `jdg.micro.sus.a18.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90054 | `jdg.micro.sus.a18.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90055 | `jdg.micro.sus.a18.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90056 | `jdg.micro.sus.a18.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90057 | `jdg.micro.sus.a18.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90058 | `jdg.micro.sus.a18.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90059 | `jdg.micro.sus.a18.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90060 | `jdg.micro.sus.a18.r9` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90061 | `jdg.micro.sus.a18.r10` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90062 | `jdg.micro.sus.a18a.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90063 | `jdg.micro.sus.a18a.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90064 | `jdg.micro.sus.a18a.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90065 | `jdg.micro.sus.a18a.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90066 | `jdg.micro.sus.a18a.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90067 | `jdg.micro.sus.a18a.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90068 | `jdg.micro.sus.a18a.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90069 | `jdg.micro.sus.a18a.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90070 | `jdg.micro.sus.a18a.r9` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90071 | `jdg.micro.sus.a18a.r10` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90072 | `jdg.micro.sus.a18c.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90073 | `jdg.micro.sus.a18c.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90074 | `jdg.micro.sus.a18c.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90075 | `jdg.micro.sus.a18c.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90076 | `jdg.micro.sus.a18c.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90077 | `jdg.micro.sus.a18c.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90078 | `jdg.micro.sus.a18c.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90079 | `jdg.micro.sus.a18c.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90080 | `jdg.micro.sus.a18c.r9` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90081 | `jdg.micro.sus.a18c.r10` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90082 | `jdg.micro.sus.a19.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90083 | `jdg.micro.sus.a19.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90084 | `jdg.micro.sus.a19.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90085 | `jdg.micro.sus.a19.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90086 | `jdg.micro.sus.a19.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90087 | `jdg.micro.sus.a19.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90088 | `jdg.micro.sus.a19.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90089 | `jdg.micro.sus.a19.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90090 | `jdg.micro.sus.a22.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90091 | `jdg.micro.sus.a22.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90092 | `jdg.micro.sus.a22.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90093 | `jdg.micro.sus.a22.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90094 | `jdg.micro.sus.a22.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90095 | `jdg.micro.sus.a22.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90096 | `jdg.micro.sus.a22.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90097 | `jdg.micro.sus.a22.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90098 | `jdg.micro.sus.a24.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90099 | `jdg.micro.sus.a24.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90100 | `jdg.micro.sus.a24.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90101 | `jdg.micro.sus.a24.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90102 | `jdg.micro.sus.a24.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90103 | `jdg.micro.sus.a24.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90104 | `jdg.micro.sus.a36.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90105 | `jdg.micro.sus.a36.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90106 | `jdg.micro.sus.a36.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90107 | `jdg.micro.sus.a36.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90108 | `jdg.micro.sus.a36.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90109 | `jdg.micro.sus.a36.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90110 | `jdg.micro.sus.a36.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90111 | `jdg.micro.sus.a36.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90112 | `jdg.micro.sus.a40.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90113 | `jdg.micro.sus.a40.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90114 | `jdg.micro.sus.a40.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90115 | `jdg.micro.sus.a40.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90116 | `jdg.micro.sus.a40.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90117 | `jdg.micro.sus.a40.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90118 | `jdg.micro.sus.a40.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90119 | `jdg.micro.sus.a40.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90120 | `jdg.micro.sus.a47.r1` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90121 | `jdg.micro.sus.a47.r2` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90122 | `jdg.micro.sus.a47.r3` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90123 | `jdg.micro.sus.a47.r4` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90124 | `jdg.micro.sus.a47.r5` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90125 | `jdg.micro.sus.a47.r6` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90126 | `jdg.micro.sus.a47.r7` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |
| 90127 | `jdg.micro.sus.a47.r8` |  | Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887) |

### `rules/micro/transport/transport.rego` (44 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 240004 | `jdg.micro.transport.a4.r1` |  | Ustawa o transporcie drogowym |
| 240005 | `jdg.micro.transport.a4.r2` |  | Ustawa o transporcie drogowym |
| 240006 | `jdg.micro.transport.a4.r3` |  | Ustawa o transporcie drogowym |
| 240007 | `jdg.micro.transport.a4.r4` |  | Ustawa o transporcie drogowym |
| 240008 | `jdg.micro.transport.a4.r5` |  | Ustawa o transporcie drogowym |
| 240009 | `jdg.micro.transport.a4.r6` |  | Ustawa o transporcie drogowym |
| 240010 | `jdg.micro.transport.a4.r7` |  | Ustawa o transporcie drogowym |
| 240011 | `jdg.micro.transport.a4.r8` |  | Ustawa o transporcie drogowym |
| 240012 | `jdg.micro.transport.a8.r1` |  | Ustawa o transporcie drogowym |
| 240013 | `jdg.micro.transport.a8.r2` |  | Ustawa o transporcie drogowym |
| 240014 | `jdg.micro.transport.a8.r3` |  | Ustawa o transporcie drogowym |
| 240015 | `jdg.micro.transport.a8.r4` |  | Ustawa o transporcie drogowym |
| 240016 | `jdg.micro.transport.a8.r5` |  | Ustawa o transporcie drogowym |
| 240017 | `jdg.micro.transport.a8.r6` |  | Ustawa o transporcie drogowym |
| 240018 | `jdg.micro.transport.a8.r7` |  | Ustawa o transporcie drogowym |
| 240019 | `jdg.micro.transport.a8.r8` |  | Ustawa o transporcie drogowym |
| 240020 | `jdg.micro.transport.a12.r1` |  | Ustawa o transporcie drogowym |
| 240021 | `jdg.micro.transport.a12.r2` |  | Ustawa o transporcie drogowym |
| 240022 | `jdg.micro.transport.a12.r3` |  | Ustawa o transporcie drogowym |
| 240023 | `jdg.micro.transport.a12.r4` |  | Ustawa o transporcie drogowym |
| 240024 | `jdg.micro.transport.a12.r5` |  | Ustawa o transporcie drogowym |
| 240025 | `jdg.micro.transport.a12.r6` |  | Ustawa o transporcie drogowym |
| 240026 | `jdg.micro.transport.a12.r7` |  | Ustawa o transporcie drogowym |
| 240027 | `jdg.micro.transport.a12.r8` |  | Ustawa o transporcie drogowym |
| 240028 | `jdg.micro.transport.a16.r1` |  | Ustawa o transporcie drogowym |
| 240029 | `jdg.micro.transport.a16.r2` |  | Ustawa o transporcie drogowym |
| 240030 | `jdg.micro.transport.a16.r3` |  | Ustawa o transporcie drogowym |
| 240031 | `jdg.micro.transport.a16.r4` |  | Ustawa o transporcie drogowym |
| 240032 | `jdg.micro.transport.a16.r5` |  | Ustawa o transporcie drogowym |
| 240033 | `jdg.micro.transport.a16.r6` |  | Ustawa o transporcie drogowym |
| 240034 | `jdg.micro.transport.a16.r7` |  | Ustawa o transporcie drogowym |
| 240035 | `jdg.micro.transport.a16.r8` |  | Ustawa o transporcie drogowym |
| 240036 | `jdg.micro.transport.a20.r1` |  | Ustawa o transporcie drogowym |
| 240037 | `jdg.micro.transport.a20.r2` |  | Ustawa o transporcie drogowym |
| 240038 | `jdg.micro.transport.a20.r3` |  | Ustawa o transporcie drogowym |
| 240039 | `jdg.micro.transport.a20.r4` |  | Ustawa o transporcie drogowym |
| 240040 | `jdg.micro.transport.a20.r5` |  | Ustawa o transporcie drogowym |
| 240041 | `jdg.micro.transport.a20.r6` |  | Ustawa o transporcie drogowym |
| 240042 | `jdg.micro.transport.a24.r1` |  | Ustawa o transporcie drogowym |
| 240043 | `jdg.micro.transport.a24.r2` |  | Ustawa o transporcie drogowym |
| 240044 | `jdg.micro.transport.a24.r3` |  | Ustawa o transporcie drogowym |
| 240045 | `jdg.micro.transport.a24.r4` |  | Ustawa o transporcie drogowym |
| 240046 | `jdg.micro.transport.a24.r5` |  | Ustawa o transporcie drogowym |
| 240047 | `jdg.micro.transport.a24.r6` |  | Ustawa o transporcie drogowym |

### `rules/micro/uor/uor.rego` (124 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 160004 | `jdg.micro.uor.a4.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160005 | `jdg.micro.uor.a4.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160006 | `jdg.micro.uor.a4.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160007 | `jdg.micro.uor.a4.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160008 | `jdg.micro.uor.a4.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160009 | `jdg.micro.uor.a4.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160010 | `jdg.micro.uor.a4.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160011 | `jdg.micro.uor.a4.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160012 | `jdg.micro.uor.a10.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160013 | `jdg.micro.uor.a10.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160014 | `jdg.micro.uor.a10.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160015 | `jdg.micro.uor.a10.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160016 | `jdg.micro.uor.a10.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160017 | `jdg.micro.uor.a10.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160018 | `jdg.micro.uor.a10.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160019 | `jdg.micro.uor.a10.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160020 | `jdg.micro.uor.a10.r9` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160021 | `jdg.micro.uor.a10.r10` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160022 | `jdg.micro.uor.a20.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160023 | `jdg.micro.uor.a20.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160024 | `jdg.micro.uor.a20.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160025 | `jdg.micro.uor.a20.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160026 | `jdg.micro.uor.a20.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160027 | `jdg.micro.uor.a20.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160028 | `jdg.micro.uor.a20.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160029 | `jdg.micro.uor.a20.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160030 | `jdg.micro.uor.a20.r9` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160031 | `jdg.micro.uor.a20.r10` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160032 | `jdg.micro.uor.a22.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160033 | `jdg.micro.uor.a22.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160034 | `jdg.micro.uor.a22.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160035 | `jdg.micro.uor.a22.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160036 | `jdg.micro.uor.a22.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160037 | `jdg.micro.uor.a22.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160038 | `jdg.micro.uor.a22.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160039 | `jdg.micro.uor.a22.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160040 | `jdg.micro.uor.a22.r9` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160041 | `jdg.micro.uor.a22.r10` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160042 | `jdg.micro.uor.a22.r11` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160043 | `jdg.micro.uor.a22.r12` | 🔴 BLOCK | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160044 | `jdg.micro.uor.a24.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160045 | `jdg.micro.uor.a24.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160046 | `jdg.micro.uor.a24.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160047 | `jdg.micro.uor.a24.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160048 | `jdg.micro.uor.a24.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160049 | `jdg.micro.uor.a24.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160050 | `jdg.micro.uor.a24.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160051 | `jdg.micro.uor.a24.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160052 | `jdg.micro.uor.a24.r9` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160053 | `jdg.micro.uor.a24.r10` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160054 | `jdg.micro.uor.a26.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160055 | `jdg.micro.uor.a26.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160056 | `jdg.micro.uor.a26.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160057 | `jdg.micro.uor.a26.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160058 | `jdg.micro.uor.a26.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160059 | `jdg.micro.uor.a26.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160060 | `jdg.micro.uor.a26.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160061 | `jdg.micro.uor.a26.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160062 | `jdg.micro.uor.a26.r9` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160063 | `jdg.micro.uor.a26.r10` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160064 | `jdg.micro.uor.a26.r11` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160065 | `jdg.micro.uor.a26.r12` | 🔴 BLOCK | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160066 | `jdg.micro.uor.a28.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160067 | `jdg.micro.uor.a28.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160068 | `jdg.micro.uor.a28.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160069 | `jdg.micro.uor.a28.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160070 | `jdg.micro.uor.a28.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160071 | `jdg.micro.uor.a28.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160072 | `jdg.micro.uor.a28.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160073 | `jdg.micro.uor.a28.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160074 | `jdg.micro.uor.a28.r9` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160075 | `jdg.micro.uor.a28.r10` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160076 | `jdg.micro.uor.a28.r11` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160077 | `jdg.micro.uor.a28.r12` | 🔴 BLOCK | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160078 | `jdg.micro.uor.a32.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160079 | `jdg.micro.uor.a32.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160080 | `jdg.micro.uor.a32.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160081 | `jdg.micro.uor.a32.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160082 | `jdg.micro.uor.a32.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160083 | `jdg.micro.uor.a32.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160084 | `jdg.micro.uor.a32.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160085 | `jdg.micro.uor.a32.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160086 | `jdg.micro.uor.a35.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160087 | `jdg.micro.uor.a35.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160088 | `jdg.micro.uor.a35.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160089 | `jdg.micro.uor.a35.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160090 | `jdg.micro.uor.a35.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160091 | `jdg.micro.uor.a35.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160092 | `jdg.micro.uor.a35.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160093 | `jdg.micro.uor.a35.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160094 | `jdg.micro.uor.a35.r9` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160095 | `jdg.micro.uor.a35.r10` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160096 | `jdg.micro.uor.a35.r11` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160097 | `jdg.micro.uor.a35.r12` | 🔴 BLOCK | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160098 | `jdg.micro.uor.a39.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160099 | `jdg.micro.uor.a39.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160100 | `jdg.micro.uor.a39.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160101 | `jdg.micro.uor.a39.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160102 | `jdg.micro.uor.a39.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160103 | `jdg.micro.uor.a39.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160104 | `jdg.micro.uor.a39.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160105 | `jdg.micro.uor.a39.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160106 | `jdg.micro.uor.a39.r9` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160107 | `jdg.micro.uor.a39.r10` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160108 | `jdg.micro.uor.a45.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160109 | `jdg.micro.uor.a45.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160110 | `jdg.micro.uor.a45.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160111 | `jdg.micro.uor.a45.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160112 | `jdg.micro.uor.a45.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160113 | `jdg.micro.uor.a45.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160114 | `jdg.micro.uor.a45.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160115 | `jdg.micro.uor.a45.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160116 | `jdg.micro.uor.a45.r9` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160117 | `jdg.micro.uor.a45.r10` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160118 | `jdg.micro.uor.a74.r1` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160119 | `jdg.micro.uor.a74.r2` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160120 | `jdg.micro.uor.a74.r3` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160121 | `jdg.micro.uor.a74.r4` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160122 | `jdg.micro.uor.a74.r5` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160123 | `jdg.micro.uor.a74.r6` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160124 | `jdg.micro.uor.a74.r7` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160125 | `jdg.micro.uor.a74.r8` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160126 | `jdg.micro.uor.a74.r9` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |
| 160127 | `jdg.micro.uor.a74.r10` |  | Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. ... |

### `rules/micro/vat/vat.rego` (571 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 50005 | `jdg.micro.vat.a5.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50006 | `jdg.micro.vat.a5.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50007 | `jdg.micro.vat.a5.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50008 | `jdg.micro.vat.a5.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50009 | `jdg.micro.vat.a5.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50010 | `jdg.micro.vat.a5.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50011 | `jdg.micro.vat.a5.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50012 | `jdg.micro.vat.a5.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50013 | `jdg.micro.vat.a5.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50014 | `jdg.micro.vat.a5.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50017 | `jdg.micro.vat.a7.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50018 | `jdg.micro.vat.a7.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50019 | `jdg.micro.vat.a7.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50020 | `jdg.micro.vat.a7.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50021 | `jdg.micro.vat.a7.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50022 | `jdg.micro.vat.a7.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50023 | `jdg.micro.vat.a7.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50024 | `jdg.micro.vat.a7.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50025 | `jdg.micro.vat.a7.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50026 | `jdg.micro.vat.a7.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50027 | `jdg.micro.vat.a7.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50028 | `jdg.micro.vat.a7.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50029 | `jdg.micro.vat.a8.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50030 | `jdg.micro.vat.a8.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50031 | `jdg.micro.vat.a8.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50032 | `jdg.micro.vat.a8.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50033 | `jdg.micro.vat.a8.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50034 | `jdg.micro.vat.a8.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50035 | `jdg.micro.vat.a8.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50036 | `jdg.micro.vat.a8.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50037 | `jdg.micro.vat.a8.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50038 | `jdg.micro.vat.a8.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50039 | `jdg.micro.vat.a8.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50040 | `jdg.micro.vat.a8.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50041 | `jdg.micro.vat.a15.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50042 | `jdg.micro.vat.a15.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50043 | `jdg.micro.vat.a15.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50044 | `jdg.micro.vat.a15.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50045 | `jdg.micro.vat.a15.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50046 | `jdg.micro.vat.a15.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50047 | `jdg.micro.vat.a15.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50048 | `jdg.micro.vat.a15.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50049 | `jdg.micro.vat.a17.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50050 | `jdg.micro.vat.a17.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50051 | `jdg.micro.vat.a17.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50052 | `jdg.micro.vat.a17.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50053 | `jdg.micro.vat.a17.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50054 | `jdg.micro.vat.a17.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50055 | `jdg.micro.vat.a17.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50056 | `jdg.micro.vat.a17.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50057 | `jdg.micro.vat.a17.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50058 | `jdg.micro.vat.a17.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50059 | `jdg.micro.vat.a17.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50060 | `jdg.micro.vat.a17.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50061 | `jdg.micro.vat.a19a.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50062 | `jdg.micro.vat.a19a.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50063 | `jdg.micro.vat.a19a.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50064 | `jdg.micro.vat.a19a.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50065 | `jdg.micro.vat.a19a.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50066 | `jdg.micro.vat.a19a.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50067 | `jdg.micro.vat.a19a.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50068 | `jdg.micro.vat.a19a.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50069 | `jdg.micro.vat.a19a.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50070 | `jdg.micro.vat.a19a.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50071 | `jdg.micro.vat.a19a.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50072 | `jdg.micro.vat.a19a.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50073 | `jdg.micro.vat.a19a.r13` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50074 | `jdg.micro.vat.a19a.r14` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50075 | `jdg.micro.vat.a19a.r15` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50076 | `jdg.micro.vat.a20.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50077 | `jdg.micro.vat.a20.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50078 | `jdg.micro.vat.a20.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50079 | `jdg.micro.vat.a20.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50080 | `jdg.micro.vat.a20.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50081 | `jdg.micro.vat.a20.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50082 | `jdg.micro.vat.a20.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50083 | `jdg.micro.vat.a20.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50084 | `jdg.micro.vat.a20.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50085 | `jdg.micro.vat.a20.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50086 | `jdg.micro.vat.a21.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50087 | `jdg.micro.vat.a21.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50088 | `jdg.micro.vat.a21.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50089 | `jdg.micro.vat.a21.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50090 | `jdg.micro.vat.a21.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50091 | `jdg.micro.vat.a21.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50092 | `jdg.micro.vat.a21.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50093 | `jdg.micro.vat.a21.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50094 | `jdg.micro.vat.a21.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50095 | `jdg.micro.vat.a21.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50096 | `jdg.micro.vat.a28a.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50097 | `jdg.micro.vat.a28a.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50098 | `jdg.micro.vat.a28a.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50099 | `jdg.micro.vat.a28a.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50100 | `jdg.micro.vat.a28a.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50101 | `jdg.micro.vat.a28a.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50102 | `jdg.micro.vat.a28a.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50103 | `jdg.micro.vat.a28a.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50104 | `jdg.micro.vat.a28a.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50105 | `jdg.micro.vat.a28a.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50106 | `jdg.micro.vat.a28b.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50107 | `jdg.micro.vat.a28b.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50108 | `jdg.micro.vat.a28b.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50109 | `jdg.micro.vat.a28b.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50110 | `jdg.micro.vat.a28b.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50111 | `jdg.micro.vat.a28b.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50112 | `jdg.micro.vat.a28b.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50113 | `jdg.micro.vat.a28b.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50114 | `jdg.micro.vat.a28c.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50115 | `jdg.micro.vat.a28c.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50116 | `jdg.micro.vat.a28c.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50117 | `jdg.micro.vat.a28c.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50118 | `jdg.micro.vat.a28c.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50119 | `jdg.micro.vat.a28c.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50120 | `jdg.micro.vat.a28c.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50121 | `jdg.micro.vat.a28c.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50122 | `jdg.micro.vat.a29a.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50123 | `jdg.micro.vat.a29a.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50124 | `jdg.micro.vat.a29a.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50125 | `jdg.micro.vat.a29a.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50126 | `jdg.micro.vat.a29a.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50127 | `jdg.micro.vat.a29a.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50128 | `jdg.micro.vat.a29a.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50129 | `jdg.micro.vat.a29a.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50130 | `jdg.micro.vat.a29a.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50131 | `jdg.micro.vat.a29a.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50132 | `jdg.micro.vat.a29a.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50133 | `jdg.micro.vat.a29a.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50134 | `jdg.micro.vat.a29a.r13` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50135 | `jdg.micro.vat.a29a.r14` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50136 | `jdg.micro.vat.a29a.r15` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50137 | `jdg.micro.vat.a31.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50138 | `jdg.micro.vat.a31.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50139 | `jdg.micro.vat.a31.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50140 | `jdg.micro.vat.a31.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50141 | `jdg.micro.vat.a31.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50142 | `jdg.micro.vat.a31.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50143 | `jdg.micro.vat.a31.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50144 | `jdg.micro.vat.a31.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50145 | `jdg.micro.vat.a32.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50146 | `jdg.micro.vat.a32.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50147 | `jdg.micro.vat.a32.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50148 | `jdg.micro.vat.a32.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50149 | `jdg.micro.vat.a32.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50150 | `jdg.micro.vat.a32.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50151 | `jdg.micro.vat.a32.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50152 | `jdg.micro.vat.a32.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50153 | `jdg.micro.vat.a41.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50154 | `jdg.micro.vat.a41.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50155 | `jdg.micro.vat.a41.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50156 | `jdg.micro.vat.a41.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50157 | `jdg.micro.vat.a41.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50158 | `jdg.micro.vat.a41.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50159 | `jdg.micro.vat.a41.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50160 | `jdg.micro.vat.a41.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50161 | `jdg.micro.vat.a41.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50162 | `jdg.micro.vat.a41.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50163 | `jdg.micro.vat.a41.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50164 | `jdg.micro.vat.a41.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50165 | `jdg.micro.vat.a41.r13` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50166 | `jdg.micro.vat.a41.r14` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50167 | `jdg.micro.vat.a41.r15` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50168 | `jdg.micro.vat.a41b.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50169 | `jdg.micro.vat.a41b.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50170 | `jdg.micro.vat.a41b.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50171 | `jdg.micro.vat.a41b.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50172 | `jdg.micro.vat.a41b.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50173 | `jdg.micro.vat.a41b.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50174 | `jdg.micro.vat.a41b.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50175 | `jdg.micro.vat.a41b.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50176 | `jdg.micro.vat.a41b.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50177 | `jdg.micro.vat.a41b.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50178 | `jdg.micro.vat.a41b.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50179 | `jdg.micro.vat.a41b.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50180 | `jdg.micro.vat.a41c.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50181 | `jdg.micro.vat.a41c.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50182 | `jdg.micro.vat.a41c.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50183 | `jdg.micro.vat.a41c.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50184 | `jdg.micro.vat.a41c.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50185 | `jdg.micro.vat.a41c.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50186 | `jdg.micro.vat.a41c.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50187 | `jdg.micro.vat.a41c.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50188 | `jdg.micro.vat.a41c.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50189 | `jdg.micro.vat.a41c.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50190 | `jdg.micro.vat.a41d.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50191 | `jdg.micro.vat.a41d.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50192 | `jdg.micro.vat.a41d.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50193 | `jdg.micro.vat.a41d.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50194 | `jdg.micro.vat.a41d.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50195 | `jdg.micro.vat.a41d.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50196 | `jdg.micro.vat.a41d.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50197 | `jdg.micro.vat.a41d.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50198 | `jdg.micro.vat.a41d.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50199 | `jdg.micro.vat.a41d.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50200 | `jdg.micro.vat.a41d.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50201 | `jdg.micro.vat.a41d.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50202 | `jdg.micro.vat.a41d.r13` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50203 | `jdg.micro.vat.a41d.r14` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50204 | `jdg.micro.vat.a41d.r15` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50205 | `jdg.micro.vat.a42.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50206 | `jdg.micro.vat.a42.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50207 | `jdg.micro.vat.a42.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50208 | `jdg.micro.vat.a42.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50209 | `jdg.micro.vat.a42.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50210 | `jdg.micro.vat.a42.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50211 | `jdg.micro.vat.a42.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50212 | `jdg.micro.vat.a42.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50213 | `jdg.micro.vat.a42.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50214 | `jdg.micro.vat.a42.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50215 | `jdg.micro.vat.a42.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50216 | `jdg.micro.vat.a42.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50217 | `jdg.micro.vat.a43.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50218 | `jdg.micro.vat.a43.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50219 | `jdg.micro.vat.a43.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50220 | `jdg.micro.vat.a43.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50221 | `jdg.micro.vat.a43.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50222 | `jdg.micro.vat.a43.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50223 | `jdg.micro.vat.a43.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50224 | `jdg.micro.vat.a43.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50225 | `jdg.micro.vat.a43.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50226 | `jdg.micro.vat.a43.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50227 | `jdg.micro.vat.a43.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50228 | `jdg.micro.vat.a43.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50229 | `jdg.micro.vat.a43.r13` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50230 | `jdg.micro.vat.a43.r14` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50231 | `jdg.micro.vat.a43.r15` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50232 | `jdg.micro.vat.a43.r16` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50233 | `jdg.micro.vat.a43.r17` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50234 | `jdg.micro.vat.a43.r18` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50235 | `jdg.micro.vat.a43.r19` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50236 | `jdg.micro.vat.a43.r20` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50237 | `jdg.micro.vat.a43.r21` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50238 | `jdg.micro.vat.a43.r22` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50239 | `jdg.micro.vat.a43.r23` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50240 | `jdg.micro.vat.a43.r24` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50241 | `jdg.micro.vat.a43.r25` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50242 | `jdg.micro.vat.a43.r26` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50243 | `jdg.micro.vat.a43.r27` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50244 | `jdg.micro.vat.a43.r28` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50245 | `jdg.micro.vat.a43.r29` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50246 | `jdg.micro.vat.a43.r30` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50247 | `jdg.micro.vat.a43.r31` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50248 | `jdg.micro.vat.a43.r32` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50249 | `jdg.micro.vat.a43.r33` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50250 | `jdg.micro.vat.a43.r34` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50251 | `jdg.micro.vat.a43.r35` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50252 | `jdg.micro.vat.a43.r36` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50253 | `jdg.micro.vat.a43.r37` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50254 | `jdg.micro.vat.a43.r38` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50255 | `jdg.micro.vat.a43.r39` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50256 | `jdg.micro.vat.a43.r40` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50257 | `jdg.micro.vat.a86.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50258 | `jdg.micro.vat.a86.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50259 | `jdg.micro.vat.a86.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50260 | `jdg.micro.vat.a86.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50261 | `jdg.micro.vat.a86.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50262 | `jdg.micro.vat.a86.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50263 | `jdg.micro.vat.a86.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50264 | `jdg.micro.vat.a86.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50265 | `jdg.micro.vat.a86.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50266 | `jdg.micro.vat.a86.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50267 | `jdg.micro.vat.a86.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50268 | `jdg.micro.vat.a86.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50269 | `jdg.micro.vat.a86.r13` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50270 | `jdg.micro.vat.a86.r14` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50271 | `jdg.micro.vat.a86.r15` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50272 | `jdg.micro.vat.a86.r16` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50273 | `jdg.micro.vat.a86.r17` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50274 | `jdg.micro.vat.a86.r18` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50275 | `jdg.micro.vat.a86.r19` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50276 | `jdg.micro.vat.a86.r20` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50277 | `jdg.micro.vat.a86a.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50278 | `jdg.micro.vat.a86a.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50279 | `jdg.micro.vat.a86a.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50280 | `jdg.micro.vat.a86a.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50281 | `jdg.micro.vat.a86a.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50282 | `jdg.micro.vat.a86a.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50283 | `jdg.micro.vat.a86a.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50284 | `jdg.micro.vat.a86a.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50285 | `jdg.micro.vat.a86a.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50286 | `jdg.micro.vat.a86a.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50287 | `jdg.micro.vat.a86a.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50288 | `jdg.micro.vat.a86a.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50289 | `jdg.micro.vat.a87.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50290 | `jdg.micro.vat.a87.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50291 | `jdg.micro.vat.a87.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50292 | `jdg.micro.vat.a87.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50293 | `jdg.micro.vat.a87.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50294 | `jdg.micro.vat.a87.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50295 | `jdg.micro.vat.a87.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50296 | `jdg.micro.vat.a87.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50297 | `jdg.micro.vat.a87.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50298 | `jdg.micro.vat.a87.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50299 | `jdg.micro.vat.a87.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50300 | `jdg.micro.vat.a87.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50301 | `jdg.micro.vat.a88.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50302 | `jdg.micro.vat.a88.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50303 | `jdg.micro.vat.a88.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50304 | `jdg.micro.vat.a88.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50305 | `jdg.micro.vat.a88.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50306 | `jdg.micro.vat.a88.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50307 | `jdg.micro.vat.a88.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50308 | `jdg.micro.vat.a88.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50309 | `jdg.micro.vat.a88.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50310 | `jdg.micro.vat.a88.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50311 | `jdg.micro.vat.a88.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50312 | `jdg.micro.vat.a88.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50313 | `jdg.micro.vat.a88.r13` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50314 | `jdg.micro.vat.a88.r14` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50315 | `jdg.micro.vat.a88.r15` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50316 | `jdg.micro.vat.a89a.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50317 | `jdg.micro.vat.a89a.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50318 | `jdg.micro.vat.a89a.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50319 | `jdg.micro.vat.a89a.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50320 | `jdg.micro.vat.a89a.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50321 | `jdg.micro.vat.a89a.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50322 | `jdg.micro.vat.a89a.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50323 | `jdg.micro.vat.a89a.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50324 | `jdg.micro.vat.a89a.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50325 | `jdg.micro.vat.a89a.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50326 | `jdg.micro.vat.a89a.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50327 | `jdg.micro.vat.a89a.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50328 | `jdg.micro.vat.a89b.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50329 | `jdg.micro.vat.a89b.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50330 | `jdg.micro.vat.a89b.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50331 | `jdg.micro.vat.a89b.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50332 | `jdg.micro.vat.a89b.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50333 | `jdg.micro.vat.a89b.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50334 | `jdg.micro.vat.a89b.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50335 | `jdg.micro.vat.a89b.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50336 | `jdg.micro.vat.a89b.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50337 | `jdg.micro.vat.a89b.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50338 | `jdg.micro.vat.a89b.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50339 | `jdg.micro.vat.a89b.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50340 | `jdg.micro.vat.a96.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50341 | `jdg.micro.vat.a96.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50342 | `jdg.micro.vat.a96.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50343 | `jdg.micro.vat.a96.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50344 | `jdg.micro.vat.a96.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50345 | `jdg.micro.vat.a96.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50346 | `jdg.micro.vat.a96.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50347 | `jdg.micro.vat.a96.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50348 | `jdg.micro.vat.a96.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50349 | `jdg.micro.vat.a96.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50350 | `jdg.micro.vat.a96.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50351 | `jdg.micro.vat.a96.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50352 | `jdg.micro.vat.a96b.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50353 | `jdg.micro.vat.a96b.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50354 | `jdg.micro.vat.a96b.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50355 | `jdg.micro.vat.a96b.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50356 | `jdg.micro.vat.a96b.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50357 | `jdg.micro.vat.a96b.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50358 | `jdg.micro.vat.a96b.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50359 | `jdg.micro.vat.a96b.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50360 | `jdg.micro.vat.a96b.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50361 | `jdg.micro.vat.a96b.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50362 | `jdg.micro.vat.a97.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50363 | `jdg.micro.vat.a97.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50364 | `jdg.micro.vat.a97.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50365 | `jdg.micro.vat.a97.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50366 | `jdg.micro.vat.a97.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50367 | `jdg.micro.vat.a97.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50368 | `jdg.micro.vat.a97.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50369 | `jdg.micro.vat.a97.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50370 | `jdg.micro.vat.a97.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50371 | `jdg.micro.vat.a97.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50372 | `jdg.micro.vat.a99.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50373 | `jdg.micro.vat.a99.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50374 | `jdg.micro.vat.a99.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50375 | `jdg.micro.vat.a99.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50376 | `jdg.micro.vat.a99.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50377 | `jdg.micro.vat.a99.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50378 | `jdg.micro.vat.a99.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50379 | `jdg.micro.vat.a99.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50380 | `jdg.micro.vat.a99.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50381 | `jdg.micro.vat.a99.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50382 | `jdg.micro.vat.a99.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50383 | `jdg.micro.vat.a99.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50384 | `jdg.micro.vat.a100.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50385 | `jdg.micro.vat.a100.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50386 | `jdg.micro.vat.a100.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50387 | `jdg.micro.vat.a100.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50388 | `jdg.micro.vat.a100.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50389 | `jdg.micro.vat.a100.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50390 | `jdg.micro.vat.a100.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50391 | `jdg.micro.vat.a100.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50392 | `jdg.micro.vat.a103.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50393 | `jdg.micro.vat.a103.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50394 | `jdg.micro.vat.a103.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50395 | `jdg.micro.vat.a103.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50396 | `jdg.micro.vat.a103.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50397 | `jdg.micro.vat.a103.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50398 | `jdg.micro.vat.a103.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50399 | `jdg.micro.vat.a103.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50400 | `jdg.micro.vat.a106a.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50401 | `jdg.micro.vat.a106a.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50402 | `jdg.micro.vat.a106a.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50403 | `jdg.micro.vat.a106a.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50404 | `jdg.micro.vat.a106a.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50405 | `jdg.micro.vat.a106a.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50406 | `jdg.micro.vat.a106a.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50407 | `jdg.micro.vat.a106a.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50408 | `jdg.micro.vat.a106a.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50409 | `jdg.micro.vat.a106a.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50410 | `jdg.micro.vat.a106a.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50411 | `jdg.micro.vat.a106a.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50412 | `jdg.micro.vat.a106a.r13` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50413 | `jdg.micro.vat.a106a.r14` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50414 | `jdg.micro.vat.a106a.r15` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50415 | `jdg.micro.vat.a106f.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50416 | `jdg.micro.vat.a106f.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50417 | `jdg.micro.vat.a106f.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50418 | `jdg.micro.vat.a106f.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50419 | `jdg.micro.vat.a106f.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50420 | `jdg.micro.vat.a106f.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50421 | `jdg.micro.vat.a106f.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50422 | `jdg.micro.vat.a106f.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50423 | `jdg.micro.vat.a106f.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50424 | `jdg.micro.vat.a106f.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50425 | `jdg.micro.vat.a106f.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50426 | `jdg.micro.vat.a106f.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50427 | `jdg.micro.vat.a106na.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50428 | `jdg.micro.vat.a106na.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50429 | `jdg.micro.vat.a106na.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50430 | `jdg.micro.vat.a106na.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50431 | `jdg.micro.vat.a106na.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50432 | `jdg.micro.vat.a106na.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50433 | `jdg.micro.vat.a106na.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50434 | `jdg.micro.vat.a106na.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50435 | `jdg.micro.vat.a106na.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50436 | `jdg.micro.vat.a106na.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50437 | `jdg.micro.vat.a106na.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50438 | `jdg.micro.vat.a106na.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50439 | `jdg.micro.vat.a106ne.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50440 | `jdg.micro.vat.a106ne.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50441 | `jdg.micro.vat.a106ne.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50442 | `jdg.micro.vat.a106ne.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50443 | `jdg.micro.vat.a106ne.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50444 | `jdg.micro.vat.a106ne.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50445 | `jdg.micro.vat.a106ne.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50446 | `jdg.micro.vat.a106ne.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50447 | `jdg.micro.vat.a106nq.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50448 | `jdg.micro.vat.a106nq.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50449 | `jdg.micro.vat.a106nq.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50450 | `jdg.micro.vat.a106nq.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50451 | `jdg.micro.vat.a106nq.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50452 | `jdg.micro.vat.a106nq.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50453 | `jdg.micro.vat.a106nq.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50454 | `jdg.micro.vat.a106nq.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50455 | `jdg.micro.vat.a108.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50456 | `jdg.micro.vat.a108.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50457 | `jdg.micro.vat.a108.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50458 | `jdg.micro.vat.a108.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50459 | `jdg.micro.vat.a108.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50460 | `jdg.micro.vat.a108.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50461 | `jdg.micro.vat.a108.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50462 | `jdg.micro.vat.a108.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50463 | `jdg.micro.vat.a108.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50464 | `jdg.micro.vat.a108.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50465 | `jdg.micro.vat.a108.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50466 | `jdg.micro.vat.a108.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50467 | `jdg.micro.vat.a108a.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50468 | `jdg.micro.vat.a108a.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50469 | `jdg.micro.vat.a108a.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50470 | `jdg.micro.vat.a108a.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50471 | `jdg.micro.vat.a108a.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50472 | `jdg.micro.vat.a108a.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50473 | `jdg.micro.vat.a108a.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50474 | `jdg.micro.vat.a108a.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50475 | `jdg.micro.vat.a109.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50476 | `jdg.micro.vat.a109.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50477 | `jdg.micro.vat.a109.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50478 | `jdg.micro.vat.a109.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50479 | `jdg.micro.vat.a109.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50480 | `jdg.micro.vat.a109.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50481 | `jdg.micro.vat.a109.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50482 | `jdg.micro.vat.a109.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50483 | `jdg.micro.vat.a109.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50484 | `jdg.micro.vat.a109.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50485 | `jdg.micro.vat.a113.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50486 | `jdg.micro.vat.a113.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50487 | `jdg.micro.vat.a113.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50488 | `jdg.micro.vat.a113.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50489 | `jdg.micro.vat.a113.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50490 | `jdg.micro.vat.a113.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50491 | `jdg.micro.vat.a113.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50492 | `jdg.micro.vat.a113.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50493 | `jdg.micro.vat.a113.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50494 | `jdg.micro.vat.a113.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50495 | `jdg.micro.vat.a113.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50496 | `jdg.micro.vat.a113.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50497 | `jdg.micro.vat.a113.r13` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50498 | `jdg.micro.vat.a113.r14` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50499 | `jdg.micro.vat.a113.r15` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50500 | `jdg.micro.vat.a113.r16` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50501 | `jdg.micro.vat.a113.r17` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50502 | `jdg.micro.vat.a113.r18` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50503 | `jdg.micro.vat.a119.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50504 | `jdg.micro.vat.a119.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50505 | `jdg.micro.vat.a119.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50506 | `jdg.micro.vat.a119.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50507 | `jdg.micro.vat.a119.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50508 | `jdg.micro.vat.a119.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50509 | `jdg.micro.vat.a119.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50510 | `jdg.micro.vat.a119.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50511 | `jdg.micro.vat.a120.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50512 | `jdg.micro.vat.a120.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50513 | `jdg.micro.vat.a120.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50514 | `jdg.micro.vat.a120.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50515 | `jdg.micro.vat.a120.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50516 | `jdg.micro.vat.a120.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50517 | `jdg.micro.vat.a120.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50518 | `jdg.micro.vat.a120.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50519 | `jdg.micro.vat.a120.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50520 | `jdg.micro.vat.a120.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50521 | `jdg.micro.vat.a120.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50522 | `jdg.micro.vat.a120.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50523 | `jdg.micro.vat.a120.r13` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50524 | `jdg.micro.vat.a120.r14` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50525 | `jdg.micro.vat.a120.r15` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50526 | `jdg.micro.vat.a129.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50527 | `jdg.micro.vat.a129.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50528 | `jdg.micro.vat.a129.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50529 | `jdg.micro.vat.a129.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50530 | `jdg.micro.vat.a129.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50531 | `jdg.micro.vat.a129.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50532 | `jdg.micro.vat.a129.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50533 | `jdg.micro.vat.a129.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50534 | `jdg.micro.vat.a129.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50535 | `jdg.micro.vat.a129.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50536 | `jdg.micro.vat.a129.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50537 | `jdg.micro.vat.a129.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50538 | `jdg.micro.vat.a135.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50539 | `jdg.micro.vat.a135.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50540 | `jdg.micro.vat.a135.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50541 | `jdg.micro.vat.a135.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50542 | `jdg.micro.vat.a135.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50543 | `jdg.micro.vat.a135.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50544 | `jdg.micro.vat.a135.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50545 | `jdg.micro.vat.a135.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50546 | `jdg.micro.vat.a135.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50547 | `jdg.micro.vat.a135.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50548 | `jdg.micro.vat.a135.r11` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50549 | `jdg.micro.vat.a135.r12` | 🔴 BLOCK | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50550 | `jdg.micro.vat.a130.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50551 | `jdg.micro.vat.a130.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50552 | `jdg.micro.vat.a130.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50553 | `jdg.micro.vat.a130.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50554 | `jdg.micro.vat.a130.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50555 | `jdg.micro.vat.a130.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50556 | `jdg.micro.vat.a130.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50557 | `jdg.micro.vat.a130.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50558 | `jdg.micro.vat.a130.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50559 | `jdg.micro.vat.a130.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50560 | `jdg.micro.vat.a131.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50561 | `jdg.micro.vat.a131.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50562 | `jdg.micro.vat.a131.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50563 | `jdg.micro.vat.a131.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50564 | `jdg.micro.vat.a131.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50565 | `jdg.micro.vat.a131.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50566 | `jdg.micro.vat.a131.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50567 | `jdg.micro.vat.a131.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50568 | `jdg.micro.vat.a138.r1` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50569 | `jdg.micro.vat.a138.r2` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50570 | `jdg.micro.vat.a138.r3` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50571 | `jdg.micro.vat.a138.r4` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50572 | `jdg.micro.vat.a138.r5` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50573 | `jdg.micro.vat.a138.r6` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50574 | `jdg.micro.vat.a138.r7` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50575 | `jdg.micro.vat.a138.r8` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50576 | `jdg.micro.vat.a138.r9` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |
| 50577 | `jdg.micro.vat.a138.r10` |  | Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535) |

### `rules/micro/zasilkowa/zasilkowa.rego` (38 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 120019 | `jdg.micro.zasilkowa.a19.r1` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120020 | `jdg.micro.zasilkowa.a19.r2` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120021 | `jdg.micro.zasilkowa.a19.r3` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120022 | `jdg.micro.zasilkowa.a19.r4` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120023 | `jdg.micro.zasilkowa.a19.r5` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120024 | `jdg.micro.zasilkowa.a19.r6` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120025 | `jdg.micro.zasilkowa.a19.r7` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120026 | `jdg.micro.zasilkowa.a19.r8` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120027 | `jdg.micro.zasilkowa.a19.r9` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120028 | `jdg.micro.zasilkowa.a19.r10` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120029 | `jdg.micro.zasilkowa.a29.r1` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120030 | `jdg.micro.zasilkowa.a29.r2` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120031 | `jdg.micro.zasilkowa.a29.r3` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120032 | `jdg.micro.zasilkowa.a29.r4` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120033 | `jdg.micro.zasilkowa.a29.r5` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120034 | `jdg.micro.zasilkowa.a29.r6` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120035 | `jdg.micro.zasilkowa.a29.r7` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120036 | `jdg.micro.zasilkowa.a29.r8` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120037 | `jdg.micro.zasilkowa.a29.r9` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120038 | `jdg.micro.zasilkowa.a29.r10` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120039 | `jdg.micro.zasilkowa.a32.r1` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120040 | `jdg.micro.zasilkowa.a32.r2` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120041 | `jdg.micro.zasilkowa.a32.r3` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120042 | `jdg.micro.zasilkowa.a32.r4` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120043 | `jdg.micro.zasilkowa.a32.r5` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120044 | `jdg.micro.zasilkowa.a32.r6` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120045 | `jdg.micro.zasilkowa.a32.r7` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120046 | `jdg.micro.zasilkowa.a32.r8` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120047 | `jdg.micro.zasilkowa.a32.r9` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120048 | `jdg.micro.zasilkowa.a32.r10` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120049 | `jdg.micro.zasilkowa.a33.r1` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120050 | `jdg.micro.zasilkowa.a33.r2` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120051 | `jdg.micro.zasilkowa.a33.r3` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120052 | `jdg.micro.zasilkowa.a33.r4` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120053 | `jdg.micro.zasilkowa.a33.r5` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120054 | `jdg.micro.zasilkowa.a33.r6` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120055 | `jdg.micro.zasilkowa.a33.r7` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |
| 120056 | `jdg.micro.zasilkowa.a33.r8` |  | Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636) |

### `rules/micro/zdrowotna/zdrowotna.rego` (62 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 110079 | `jdg.micro.zdrowotna.a79.r1` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110080 | `jdg.micro.zdrowotna.a79.r2` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110081 | `jdg.micro.zdrowotna.a79.r3` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110082 | `jdg.micro.zdrowotna.a79.r4` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110083 | `jdg.micro.zdrowotna.a79.r5` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110084 | `jdg.micro.zdrowotna.a79.r6` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110085 | `jdg.micro.zdrowotna.a79.r7` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110086 | `jdg.micro.zdrowotna.a79.r8` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110087 | `jdg.micro.zdrowotna.a79.r9` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110088 | `jdg.micro.zdrowotna.a79.r10` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110089 | `jdg.micro.zdrowotna.a81.r1` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110090 | `jdg.micro.zdrowotna.a81.r2` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110091 | `jdg.micro.zdrowotna.a81.r3` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110092 | `jdg.micro.zdrowotna.a81.r4` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110093 | `jdg.micro.zdrowotna.a81.r5` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110094 | `jdg.micro.zdrowotna.a81.r6` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110095 | `jdg.micro.zdrowotna.a81.r7` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110096 | `jdg.micro.zdrowotna.a81.r8` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110097 | `jdg.micro.zdrowotna.a81.r9` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110098 | `jdg.micro.zdrowotna.a81.r10` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110099 | `jdg.micro.zdrowotna.a81b.r1` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110100 | `jdg.micro.zdrowotna.a81b.r2` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110101 | `jdg.micro.zdrowotna.a81b.r3` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110102 | `jdg.micro.zdrowotna.a81b.r4` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110103 | `jdg.micro.zdrowotna.a81b.r5` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110104 | `jdg.micro.zdrowotna.a81b.r6` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110105 | `jdg.micro.zdrowotna.a81b.r7` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110106 | `jdg.micro.zdrowotna.a81b.r8` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110107 | `jdg.micro.zdrowotna.a81b.r9` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110108 | `jdg.micro.zdrowotna.a81b.r10` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110109 | `jdg.micro.zdrowotna.a81c.r1` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110110 | `jdg.micro.zdrowotna.a81c.r2` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110111 | `jdg.micro.zdrowotna.a81c.r3` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110112 | `jdg.micro.zdrowotna.a81c.r4` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110113 | `jdg.micro.zdrowotna.a81c.r5` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110114 | `jdg.micro.zdrowotna.a81c.r6` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110115 | `jdg.micro.zdrowotna.a81c.r7` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110116 | `jdg.micro.zdrowotna.a81c.r8` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110117 | `jdg.micro.zdrowotna.a81c.r9` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110118 | `jdg.micro.zdrowotna.a81c.r10` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110119 | `jdg.micro.zdrowotna.a81c.r11` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110120 | `jdg.micro.zdrowotna.a81c.r12` | 🔴 BLOCK | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110121 | `jdg.micro.zdrowotna.a81d.r1` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110122 | `jdg.micro.zdrowotna.a81d.r2` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110123 | `jdg.micro.zdrowotna.a81d.r3` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110124 | `jdg.micro.zdrowotna.a81d.r4` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110125 | `jdg.micro.zdrowotna.a81d.r5` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110126 | `jdg.micro.zdrowotna.a81d.r6` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110127 | `jdg.micro.zdrowotna.a81d.r7` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110128 | `jdg.micro.zdrowotna.a81d.r8` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110129 | `jdg.micro.zdrowotna.a81d.r9` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110130 | `jdg.micro.zdrowotna.a81d.r10` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110131 | `jdg.micro.zdrowotna.a81d.r11` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110132 | `jdg.micro.zdrowotna.a81d.r12` | 🔴 BLOCK | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110133 | `jdg.micro.zdrowotna.a82.r1` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110134 | `jdg.micro.zdrowotna.a82.r2` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110135 | `jdg.micro.zdrowotna.a82.r3` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110136 | `jdg.micro.zdrowotna.a82.r4` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110137 | `jdg.micro.zdrowotna.a82.r5` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110138 | `jdg.micro.zdrowotna.a82.r6` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110139 | `jdg.micro.zdrowotna.a82.r7` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |
| 110140 | `jdg.micro.zdrowotna.a82.r8` |  | Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 21... |

### `rules/mpips.rego` (12 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 770 | `jdg.mpips.labour_fund_fp` |  | Art. 104-107 Ustawy o promocji zatrudnienia |
| 771 | `jdg.mpips.fgsp_guaranteed_benefits` |  | Art. 25-29 Ustawy o ochronie roszczeń pracowniczych |
| 772 | `jdg.mpips.pfron_disabled_fund` | 🟡 TRIAGE | Art. 21 Ustawy o rehabilitacji zawodowej |
| 773 | `jdg.mpips.zfss_social_fund` | 🟡 TRIAGE | Art. 3-5 Ustawy o ZFŚS |
| 774 | `jdg.mpips.ppk_employee_capital_plan` | 🟡 TRIAGE | Ustawa o PPK z dn. 4.10.2018 |
| 775 | `jdg.mpips.vacation_benefit` |  | Art. 3 Ustawy o ZFŚS |
| 776 | `jdg.mpips.severance_pay` | 🟡 TRIAGE | Art. 92¹ Kodeksu Pracy |
| 777 | `jdg.mpips.jubilee_award` |  | Art. 77² Kodeksu Pracy (zakładowe układy zbiorowe) |
| 778 | `jdg.mpips.bhp_training_fund` | 🟡 TRIAGE | Art. 237³ KP, Rozporządzenie w sprawie szkolenia BHP |
| 779 | `jdg.mpips.maternity_leave_topup` |  | Art. 184 KP, Ustawa o świadczeniach pieniężnych z ubezp. spo... |
| 780 | `jdg.mpips.parental_leave` |  | Art. 182¹a-182¹e KP, Art. 182³ KP (ojcowski) |
| 781 | `jdg.mpips.childcare_subsidy` |  | Art. 12a Ustawy o opiece nad dziećmi do lat 3, ZFŚS |

### `rules/payments/plan44_payments.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1990 | `jdg.payments.crypto_as_payment` |  | Art. 14 ust. 1 PIT |
| 1991 | `jdg.payments.barter_transaction` |  | Art. 7, 8 VAT |
| 1992 | `jdg.payments.offsetting_kompensata` |  | Art. 498 KC |
| 1993 | `jdg.payments.instalment_recognition` |  | Art. 14 PIT |
| 1994 | `jdg.payments.advance_vat_obligation` |  | Art. 19a ust. 8 VAT |
| 1995 | `jdg.payments.payment_in_kind` |  | Art. 14 PIT, Art. 29a VAT |
| 1996 | `jdg.payments.fx_cash_payment_limit` |  | Art. 19 Prawa przedsiębiorców |
| 1997 | `jdg.payments.electronic_payment_vat` |  | Art. 96b VAT |
| 1998 | `jdg.payments.card_terminal_obligation` |  | Ustawa o usługach płatniczych |

### `rules/payments/plan45_payments.rego` (13 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1636 | `jdg.payments.hyper.crypto_revenue_recognition` |  | Art. 14 ust. 1 PIT |
| 1637 | `jdg.payments.hyper.crypto_vat_on_receipt` |  | Art. 19a ust. 8 VAT |
| 1640 | `jdg.payments.hyper.crypto_vs_trading_distinction` |  | Art. 14 vs 17 PIT |
| 1641 | `jdg.payments.hyper.barter_double_supply` |  | Art. 7, 8 VAT |
| 1643 | `jdg.payments.hyper.barter_market_value_base` |  | Art. 29a VAT |
| 1646 | `jdg.payments.hyper.offset_recognition_date` |  | Art. 498 KC, Art. 14 PIT |
| 1651 | `jdg.payments.hyper.installments_pit_per_installment` |  | Art. 14 PIT |
| 1657 | `jdg.payments.hyper.advance_invoice_15days` |  | Art. 106i VAT |
| 1659 | `jdg.payments.hyper.advance_retained_taxable` |  | Art. 14 PIT |
| 1661 | `jdg.payments.hyper.inkind_market_value` |  | Art. 14 ust. 2 PIT |
| 1666 | `jdg.payments.hyper.foreign_cash_limit_15k` |  | Art. 22p PIT |
| 1671 | `jdg.payments.hyper.terminal_obligation_20k_eur` |  | Ustawa o usługach płatniczych |
| 1672 | `jdg.payments.hyper.terminal_penalty_5000` | 🔴 BLOCK | Ustawa o usługach płatniczych |

### `rules/pcc/plan42_pcc.rego` (4 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1301 | `jdg.pcc.loan_from_private_person` |  | Art. 1 ust. 1 pkt 2, Art. 7 ust. 1 pkt 4 Ustawy o PCC |
| 1302 | `jdg.pcc.car_purchase_from_private` |  | Art. 1 ust. 1 pkt 1 lit. a Ustawy o PCC |
| 1303 | `jdg.pcc.real_estate_purchase` |  | Art. 1 ust. 1 pkt 1 lit. a Ustawy o PCC |
| 1304 | `jdg.pcc.aggregate_liability_check` |  | Ustawa o PCC |

### `rules/pit/advances_returns.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 540 | `jdg.pit.advances.monthly` |  | Art. 44 ust. 1 i 3 PIT |
| 541 | `jdg.pit.advances.zus_social_deduction` |  | Art. 26 ust. 1 pkt 2 PIT |
| 542 | `jdg.pit.advances.quarterly` |  | Art. 44 ust. 3g PIT |
| 543 | `jdg.pit.advances.simplified` |  | Art. 44 ust. 6b PIT |
| 550 | `jdg.pit.advances.annual_pit36` |  | Art. 45 ust. 1 PIT |
| 552 | `jdg.pit.advances.annual_pit36l` |  | Art. 45 ust. 1a PIT |
| 554 | `jdg.pit.advances.annual_pit28` |  | Art. 21 ust. 1 ustawy o ryczałcie |
| 556 | `jdg.pit.advances.return_overdue` | 🔴 BLOCK | Art. 45 PIT, Art. 56 KKS |

### `rules/pit/exemptions.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 508 | `jdg.pit.exemptions.revenue_exclusions` |  | Art. 14 ust. 3 PIT |
| 580 | `jdg.pit.exemptions.young` |  | Art. 21 ust. 1 pkt 148 PIT |
| 582 | `jdg.pit.exemptions.return` |  | Art. 21 ust. 1 pkt 152 PIT |
| 584 | `jdg.pit.exemptions.family_4plus` |  | Art. 21 ust. 1 pkt 153 PIT |
| 586 | `jdg.pit.exemptions.working_senior` |  | Art. 21 ust. 1 pkt 154 PIT |
| 588 | `jdg.pit.exemptions.shared_limit` |  | Art. 21 ust. 1 pkt 148-154 PIT |

### `rules/pit/forms.rego` (10 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 500 | `jdg.pit.forms.scale` |  | Art. 27 ust. 1 PIT |
| 502 | `jdg.pit.forms.scale_joint_filing` |  | Art. 6 ust. 2 PIT |
| 510 | `jdg.pit.forms.linear` |  | Art. 30c PIT |
| 512 | `jdg.pit.forms.linear_former_employer_block` | 🔴 BLOCK | Art. 30c ust. 2 PIT |
| 520 | `jdg.pit.forms.lump_sum` |  | Art. 12 ustawy o ryczałcie ewidencjonowanym |
| 523 | `jdg.pit.forms.lump_sum_limit_exceeded` | 🔴 BLOCK | Art. 6 ust. 4 ustawy o ryczałcie |
| 524 | `jdg.pit.forms.lump_sum_exclusions` | 🔴 BLOCK | Art. 8 ust. 1-2 ustawy o ryczałcie (Dz.U. 2025 poz. 234) |
| 525 | `jdg.pit.forms.lump_sum_loss_of_right` | 🔴 BLOCK | Art. 20 ustawy o ryczałcie |
| 526 | `jdg.pit.forms.lump_sum_election_deadline` | 🔴 BLOCK | Art. 9 ust. 1-4 ustawy o ryczałcie (Dz.U. 2025 poz. 234) |
| 530 | `jdg.pit.forms.tax_card` |  | Art. 21-30 ustawy o ryczałcie (rozdział 3) |

### `rules/pit/kup.rego` (10 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 560 | `jdg.pit.kup.full_deductible` |  | Art. 22 ust. 1 PIT |
| 561 | `jdg.pit.kup.zus_social_deductible` |  | Art. 22 ust. 1 w zw. z art. 23 ust. 1 pkt 37 PIT |
| 562 | `jdg.pit.kup.private_mixed_jdg` |  | Art. 22 ust. 1 PIT |
| 564 | `jdg.pit.kup.car_over_150k` |  | Art. 23 ust. 1 pkt 47a PIT |
| 565 | `jdg.pit.kup.car_electric_225k` |  | Art. 23 ust. 1 pkt 47a PIT (wyjątek EV) |
| 566 | `jdg.pit.kup.representation_none` |  | Art. 23 ust. 1 pkt 23 PIT |
| 568 | `jdg.pit.kup.unpaid_zus_social` |  | Art. 22 ust. 6ba PIT |
| 570 | `jdg.pit.kup.health_linear_deduction` |  | Art. 30c ust. 2 pkt 2 PIT |
| 571 | `jdg.pit.kup.bad_debt_debtor` | 🔴 BLOCK | Art. 22 ust. 8-10 PIT |
| 572 | `jdg.pit.kup.direct_vs_indirect` |  | Art. 22 ust. 5-5c PIT |

### `rules/pit/plan23_exemptions.rego` (1 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 588 | `jdg.pit.exemption_interactions_shared_limit` | 🔴 BLOCK | Art. 21 ust. 1 pkt 148, 152, 153, 154 PIT |

### `rules/pit/plan23_tax_form_change.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 590 | `jdg.pit.tax_form_change.scale_to_linear` |  | Art. 9a ust. 2 PIT |
| 591 | `jdg.pit.tax_form_change.linear_to_lump_sum` |  | Art. 9 ustawy o ryczałcie |
| 592 | `jdg.pit.tax_form_change.lump_sum_to_scale` |  | Art. 24a PIT |
| 593 | `jdg.pit.tax_form_change.mid_year_restriction` | 🔴 BLOCK | Art. 9a ust. 2 PIT |
| 594 | `jdg.pit.tax_form_change.consequences_multiple_returns` |  | Art. 22 ustawy o ryczałcie |
| 595 | `jdg.pit.tax_form_change.inventory_remeasurement` |  | § 24 Rozporządzenia ws. PKPiR |
| 596 | `jdg.pit.tax_form_change.zus_health_recalculation` |  | Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych |

### `rules/pit/plan26_detailed.rego` (11 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 508 | `jdg.pit.revenue_exclusions_detail` |  | Art. 14 ust. 3 PIT |
| 509 | `jdg.pit.income_with_inventory_calculation` |  | Art. 24 ust. 1-1b PIT |
| 512 | `jdg.pit.linear_former_employer_block` | 🔴 BLOCK | Art. 30c ust. 2 pkt 1 PIT, Art. 9a ust. 3 PIT |
| 524 | `jdg.pit.lump_sum_statutory_exclusions` | 🔴 BLOCK | Art. 8 ust. 1-2 ustawy o ryczałcie |
| 525 | `jdg.pit.lump_sum_loss_of_right_midyear` | 🔴 BLOCK | Art. 20 ustawy o ryczałcie |
| 526 | `jdg.pit.lump_sum_election_deadline_check` | 🔴 BLOCK | Art. 9 ust. 1-4 ustawy o ryczałcie |
| 532 | `jdg.pit.tax_card_rate_table_dynamic` |  | Art. 23 ustawy o ryczałcie |
| 533 | `jdg.pit.tax_card_loss_events_detection` | 🔴 BLOCK | Art. 27 ustawy o ryczałcie |
| 572 | `jdg.pit.kup_direct_vs_indirect_timing` |  | Art. 22 ust. 5-5c PIT |
| 574 | `jdg.pit.kup_detailed_exclusions_catalog` |  | Art. 23 PIT |
| 615 | `jdg.pit.loss_carry_forward_5years_5m` |  | Art. 9 ust. 3 PIT |

### `rules/pit/transitions.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 590 | `jdg.pit.transitions.scale_to_linear` |  | Art. 9a ust. 2, Art. 30c PIT |
| 592 | `jdg.pit.transitions.lump_sum_loss_to_scale` |  | Art. 20 ustawy o ryczałcie |
| 593 | `jdg.pit.transitions.mid_year_block` | 🟡 TRIAGE | Art. 9a ust. 5 PIT |
| 594 | `jdg.pit.transitions.dual_return` |  | Art. 45 ust. 1b PIT |
| 596 | `jdg.pit.transitions.health_recalc` |  | Art. 81 ustawy o świadczeniach opieki zdrowotnej |

### `rules/procurement/plan44_procurement.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1880 | `jdg.procurement.tax_clearance` |  | Art. 306e Ordynacji podatkowej |
| 1881 | `jdg.procurement.eu_funds_certificate` |  | Art. 306e Ordynacji podatkowej |
| 1882 | `jdg.procurement.clearance_procedure` |  | Art. 306n Ordynacji podatkowej |
| 1883 | `jdg.procurement.tax_arrears_impact` | 🔴 BLOCK | Art. 108 ust. 1 pkt 4 PZP |
| 1884 | `jdg.procurement.zus_clearance` |  | Art. 22-24 PZP |
| 1885 | `jdg.procurement.tax_representation` |  | Art. 22 PZP |
| 1886 | `jdg.procurement.bid_bond_tax` |  | Art. 22 PIT, Art. 19a VAT |

### `rules/procurement/plan45_procurement.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1270 | `jdg.procurement.hyper.tax_clearance_required` |  | Art. 306e OP |
| 1275 | `jdg.procurement.hyper.zus_clearance_required` |  | Art. 22-24 PZP |
| 1280 | `jdg.procurement.hyper.exclusion_tax_arrears` | 🔴 BLOCK | Art. 108 PZP |
| 1285 | `jdg.procurement.hyper.bid_bond_kup` |  | Art. 22 PIT |
| 1290 | `jdg.procurement.hyper.eu_funds_certificate` |  | Art. 306e OP |
| 1295 | `jdg.procurement.hyper.foreign_tax_representative` |  | Art. 22 PZP |

### `rules/regulated/plan44_regulated.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1970 | `jdg.regulated.vat_exemption` |  | Art. 43 ust. 1 pkt 18-19 VAT |
| 1971 | `jdg.regulated.kup_catalog` |  | Art. 22-23 PIT |
| 1972 | `jdg.regulated.zus_obligations` |  | Art. 18a SUS |
| 1973 | `jdg.regulated.legal_privilege` |  | Art. 180 Ordynacji podatkowej |
| 1974 | `jdg.regulated.compulsory_membership` |  | Art. 22 PIT |
| 1975 | `jdg.regulated.cross_border_qualifications` |  | Ustawa o zawodach regulowanych |
| 1976 | `jdg.regulated.public_office_interaction` |  | Ustawa o notariacie, Ustawa o komornikach |
| 1977 | `jdg.regulated.healthcare_taxation` |  | Art. 43 VAT, Art. 12 PIT |

### `rules/regulated/plan45_regulated.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1576 | `jdg.regulated.hyper.vat_exempt_doctor` |  | Art. 43 ust. 1 pkt 18-19 VAT |
| 1577 | `jdg.regulated.hyper.vat_no_exemption_lawyer` |  | Art. 41 VAT |
| 1581 | `jdg.regulated.hyper.kup_chamber_fees_full` |  | Art. 22 PIT |
| 1586 | `jdg.regulated.hyper.zus_no_start_relief` |  | Art. 18a SUS |
| 1591 | `jdg.regulated.hyper.privilege_attorney_client` |  | Art. 180 § 3 OP |
| 1599 | `jdg.regulated.hyper.license_suspension_business_must_suspend` | 🔴 BLOCK | Ustawy korporacyjne |

### `rules/representation.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1200 | `jdg.representation.pps1_required` | 🔴 BLOCK | Art. 138a § 1 Ordynacja podatkowa |
| 1202 | `jdg.representation.upl1_required` | 🔴 BLOCK | Art. 138d § 1 Ordynacja podatkowa |
| 1204 | `jdg.representation.poa_certified_accountant` |  | Art. 138d § 2 Ordynacja podatkowa |
| 1206 | `jdg.representation.poa_revocation` |  | Art. 138g Ordynacja podatkowa |
| 1208 | `jdg.representation.poa_change_scope` |  | Art. 138f Ordynacja podatkowa |
| 1210 | `jdg.representation.poa_automatic_expiry` | 🔴 BLOCK | Art. 138h § 1 Ordynacja podatkowa |
| 1212 | `jdg.representation.poa_cross_border` |  | Art. 138a § 2 Ordynacja podatkowa + DAC6 |

### `rules/representation/plan26_prokura.rego` (1 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1205 | `jdg.representation.prokura_types_detailed` | 🔴 BLOCK | Art. 109¹-109⁸ KC |

### `rules/residency/plan44_residency.rego` (10 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1940 | `jdg.residency.determination` |  | Art. 3 PIT |
| 1941 | `jdg.residency.treaty_benefit` |  | Art. 27 ust. 8-9 PIT |
| 1942 | `jdg.residency.certificate_of_residence` |  | Art. 26 PIT |
| 1943 | `jdg.residency.foreign_tax_credit` |  | Art. 27g PIT |
| 1944 | `jdg.residency.exit_tax` | 🔴 BLOCK | Art. 30da PIT |
| 1945 | `jdg.residency.dual_residency_conflict` | 🟡 TRIAGE | Umowy bilateralne (OECD MTC Art. 4) |
| 1946 | `jdg.residency.foreign_income_exemption_progression` |  | Art. 27 ust. 8 PIT |
| 1947 | `jdg.residency.foreign_income_credit_method` |  | Art. 27 ust. 9 PIT |
| 1948 | `jdg.residency.permanent_establishment_risk` | 🟡 TRIAGE | Art. 4a PIT, OECD MTC Art. 5 |
| 1949 | `jdg.residency.digital_pe` | 🟡 TRIAGE | OECD BEPS 2.0 Pillar 1 |

### `rules/residency/plan45_residency.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1476 | `jdg.residency.hyper.test_183_days` |  | Art. 3 PIT |
| 1481 | `jdg.residency.hyper.dtt_exemption_progression` |  | Umowy bilateralne |
| 1485 | `jdg.residency.hyper.cfr_validity_12months` |  | Art. 26 PIT |
| 1486 | `jdg.residency.hyper.foreign_tax_credit_limit` |  | Art. 27 ust. 9 PIT |
| 1491 | `jdg.residency.hyper.exit_tax_4m_threshold` | 🔴 BLOCK | Art. 30da PIT |
| 1493 | `jdg.residency.hyper.exit_tax_installments` |  | Art. 30da PIT |
| 1501 | `jdg.residency.hyper.pe_construction_12months` |  | OECD MTC Art. 5 |
| 1504 | `jdg.residency.hyper.digital_pe_server` |  | OECD BEPS 2.0 Pillar 1 |
| 1506 | `jdg.residency.hyper.cfc_control_50pct` | 🟡 TRIAGE | Art. 30f PIT |

### `rules/restructuring.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1500 | `jdg.restructuring.jdg_to_spzoo_transformation` | 🔴 BLOCK | Art. 551 § 5 KSH + Art. 112 Ordynacja podatkowa |
| 1501 | `jdg.restructuring.opening_balance_sheet` | 🔴 BLOCK | Art. 559 § 1 KSH + Art. 24a PIT |
| 1502 | `jdg.restructuring.business_transfer_tax_exempt` |  | Art. 6 pkt 1 VAT (zbycie ZCP wyłączone z VAT) |
| 1503 | `jdg.restructuring.acquirer_liability_tax_arrears` | 🔴 BLOCK | Art. 112 Ordynacja podatkowa |
| 1504 | `jdg.restructuring.succession_manager` | 🔴 BLOCK | Art. 51-54 Ustawy o zarządzie sukcesyjnym |
| 1505 | `jdg.restructuring.business_closure` | 🔴 BLOCK | Art. 14 PIT + Art. 96 ust. 6 VAT + Art. 27 Ustawy CEIDG |
| 1506 | `jdg.restructuring.merger_tax` |  | Art. 21 ust. 1 pkt 50b PIT (wymiana udziałów) |

### `rules/retention.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 990 | `jdg.retention.tax_documents_5yr` |  | Art. 86 § 1 Ordynacja podatkowa |
| 990 | `jdg.retention.vat_invoices_extended` |  | Art. 112 VAT |
| 991 | `jdg.retention.vat_invoices_real_estate_10yr` |  | Art. 43 ust. 1 pkt 10 VAT (nieruchomości — 10 lat korekty VA... |
| 992 | `jdg.retention.hr_documents_extended` |  | Art. 51u Ustawy o systemie ubezpieczeń społecznych (od 1 sty... |
| 993 | `jdg.retention.hr_documents_10yr_post_2019` |  | Art. 51u Ustawy o systemie ubezpieczeń społecznych |
| 994 | `jdg.retention.electronic_archive_requirements` | 🔴 BLOCK | Art. 112a VAT + Art. 106m-106n VAT + eIDAS |

### `rules/risk.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 0 | `jdg.risk.fraud_graph_match` | 🔴 BLOCK | Art. 86 ust. 1 VAT, Art. 55 KKS |
| 0 | `jdg.risk.kks_empty_invoice_fraud` | 🔴 BLOCK | Art. 62 § 2 KKS |
| 1 | `jdg.risk.counterparty_trust_low` | 🔴 BLOCK | Art. 22 UoR (zasada ostrożności) |
| 2 | `jdg.risk.anomaly_amount` | 🔴 BLOCK | Art. 22 UoR (zasada ostrożności) |
| 3 | `jdg.risk.new_counterparty_flag` | 🟡 TRIAGE | Art. 22 UoR, procedury AML |
| 5 | `jdg.risk.semantic_guard_disallowed` | 🔴 BLOCK | Art. 23 ust. 1 pkt 23 PIT (dla JDG) |
| 8 | `jdg.risk.ceidg_vendor_suspended` | 🔴 BLOCK | Art. 88 VAT, Art. 22-25 Prawa przedsiębiorców |
| 9 | `jdg.risk.gaar_artificial_scheme` | 🔴 BLOCK | Art. 119a § 1 Ordynacji podatkowej |

### `rules/risk/plan26_kks_gaar.rego` (4 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 4 | `jdg.risk.kks_hidden_income_flag` | 🔴 BLOCK | Art. 54 KKS |
| 6 | `jdg.risk.kks_unreliable_books` | 🔴 BLOCK | Art. 56 KKS |
| 7 | `jdg.risk.kks_vat_evidence_gap` | 🟡 TRIAGE | Art. 57 KKS |
| 8 | `jdg.risk.kks_declaration_overdue` | 🟡 TRIAGE | Art. 77 KKS |

### `rules/rodo.rego` (12 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1610 | `jdg.rodo.data_processing_register` | 🟡 TRIAGE | Art. 30 RODO (Rozporządzenie 2016/679) |
| 1611 | `jdg.rodo.data_retention` | 🟡 TRIAGE | Art. 5 ust. 1 lit. e RODO + Art. 74 ust. 2 UoR (5 lat przech... |
| 1612 | `jdg.rodo.data_breach_notification` | 🔴 BLOCK | Art. 33-34 RODO |
| 1613 | `jdg.rodo.employee_data_protection` | 🟡 TRIAGE | Art. 13, 35, 37 RODO |
| 1614 | `jdg.rodo.marketing_consent` | 🟡 TRIAGE | Art. 6 ust. 1 lit. a RODO + Art. 10 Ustawy o świadczeniu usł... |
| 1615 | `jdg.rodo.cctv_monitoring` | 🟡 TRIAGE | Art. 6 ust. 1 lit. f RODO + Art. 222 Kodeksu Pracy (pracowni... |
| 1616 | `jdg.rodo.data_transfer_eog` | 🔴 BLOCK | Art. 44-49 RODO (Rozdział V) |
| 1617 | `jdg.rodo.dpia_required` | 🟡 TRIAGE | Art. 35 RODO |
| 1618 | `jdg.rodo.dsar_access_request` | 🟡 TRIAGE | Art. 15-22 RODO (prawa osób, których dane dotyczą) |
| 1619 | `jdg.rodo.cookie_consent` | 🟡 TRIAGE | Art. 173 Prawa telekomunikacyjnego + Art. 6 ust. 1 lit. a RO... |
| 1620 | `jdg.rodo.data_portability` | 🟡 TRIAGE | Art. 20 RODO |
| 1621 | `jdg.rodo.processor_agreement` | 🟡 TRIAGE | Art. 28 RODO |

### `rules/rodo/plan42_rodo.rego` (3 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1610 | `jdg.rodo.dpa_registration_check` | 🟡 TRIAGE | Art. 30, 36 RODO |
| 1612 | `jdg.rodo.data_retention_policy` |  | Art. 5 ust. 1 lit. e RODO |
| 1613 | `jdg.rodo.dpo_requirement` |  | Art. 37 RODO |

### `rules/routing.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 10 | `jdg.routing.fc_vat_rate_low_scale` | 🔴 BLOCK | Art. 22 UoR (rzetelność ksiąg) |
| 12 | `jdg.routing.fc_vendor_nip_low` | 🔴 BLOCK | Art. 96b VAT, Art. 22 UoR |
| 14 | `jdg.routing.fc_linear_minimum` | 🟡 TRIAGE | Art. 22 UoR |
| 15 | `jdg.routing.fc_lump_sum_vat_rate` | 🟡 TRIAGE | Art. 22 UoR |
| 19 | `jdg.routing.fc_global_minimum_low` | 🟡 TRIAGE | Art. 22 UoR |

### `rules/seasonal/plan44_seasonal.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1950 | `jdg.seasonal.identification` |  | Ogólne |
| 1951 | `jdg.seasonal.suspension_vs_closure` |  | Art. 25 PP |
| 1952 | `jdg.seasonal.zus_strategy` |  | Art. 36a SUS |
| 1953 | `jdg.seasonal.pit_advances` |  | Art. 44 ust. 6b PIT |
| 1954 | `jdg.seasonal.vat_consequences` |  | Art. 99 VAT |
| 1955 | `jdg.seasonal.loss_carry_forward` |  | Art. 9 ust. 3 PIT |
| 1956 | `jdg.seasonal.annual_reconciliation` |  | Art. 45 PIT |

### `rules/seasonal/plan45_seasonal.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1520 | `jdg.seasonal.hyper.detection_tourism` |  | Art. 22 PP |
| 1522 | `jdg.seasonal.hyper.detection_construction_winter` |  | Art. 22 PP |
| 1524 | `jdg.seasonal.hyper.suspension_max_6_months` |  | Art. 22 PP |
| 1528 | `jdg.seasonal.hyper.zus_suspension_no_social` |  | Art. 36a SUS |
| 1534 | `jdg.seasonal.hyper.pit_advances_simplified_recommendation` |  | Art. 44 ust. 6b PIT |
| 1538 | `jdg.seasonal.hyper.vat_zero_returns_suspension` |  | Art. 99 ust. 7a VAT |

### `rules/solidarity/plan44_solidarity.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1810 | `jdg.solidarity.threshold_detection` | 🔴 BLOCK | Art. 30h PIT |
| 1811 | `jdg.solidarity.income_aggregation` |  | Art. 30h ust. 2-4 PIT |
| 1812 | `jdg.solidarity.zus_exclusion` |  | Art. 30h ust. 2 PIT |
| 1813 | `jdg.solidarity.payment_deadline` |  | Art. 30h ust. 5 PIT |
| 1814 | `jdg.solidarity.foreign_income_exemption` |  | Art. 30h ust. 3 PIT |

### `rules/solidarity/plan45_solidarity.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1043 | `jdg.solidarity.hyper.threshold_1m` | 🔴 BLOCK | Art. 30h ust. 1 PIT |
| 1044 | `jdg.solidarity.hyper.base_calculation` |  | Art. 30h ust. 2 PIT |
| 1045 | `jdg.solidarity.hyper.rate_4pct` |  | Art. 30h ust. 1 PIT |
| 1051 | `jdg.solidarity.hyper.income_capital_included` |  | Art. 30h ust. 2 PIT |
| 1053 | `jdg.solidarity.hyper.zus_social_exclusion` |  | Art. 30h ust. 2 PIT |
| 1054 | `jdg.solidarity.hyper.health_no_exclusion` |  | Art. 30h ust. 2 PIT |
| 1057 | `jdg.solidarity.hyper.spouse_individual` |  | Art. 30h ust. 3 PIT |
| 1059 | `jdg.solidarity.hyper.deadline_april30` |  | Art. 30h ust. 5 PIT |
| 1070 | `jdg.solidarity.hyper.alert_900k` |  | Art. 30h PIT |

### `rules/statute/plan26_detailed.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1153 | `jdg.statute.zus_suspension_during_proceedings` |  | Art. 24 ust. 5b-5d SUS |
| 1157 | `jdg.statute.interruption_detailed_events` |  | Art. 71 OP |
| 1167 | `jdg.statute.tax_arrears_detection` | 🟡 TRIAGE | Art. 20-21 OP |
| 1168 | `jdg.statute.voluntary_disclosure_protection` | 🔴 BLOCK | Art. 16 § 1-4 KKS, Art. 16a KKS |
| 1169 | `jdg.statute.overpayment_detection_and_refund` |  | Art. 72-80 OP |
| 1170 | `jdg.statute.deferral_active_interest_suspended` |  | Art. 48, Art. 67a-67e OP |
| 1171 | `jdg.statute.tax_remission_liability_extinguished` |  | Art. 51 OP |
| 1172 | `jdg.statute.overpayment_offset_auto` |  | Art. 72-80, Art. 87 OP |
| 1174 | `jdg.statute.tax_proceedings_deadlines_alert` |  | Art. 120-129 OP |

### `rules/statute_of_limitations.rego` (14 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 436 | `jdg.limitations.statute_5_years` |  | Art. 70 § 1 OrdPU |
| 437 | `jdg.limitations.statute_10_years` | 🟡 TRIAGE | Art. 70 § 4-6 OrdPU |
| 438 | `jdg.limitations.suspension_event` | 🔴 BLOCK | Art. 70 § 4 OrdPU |
| 439 | `jdg.limitations.interruption_event` | 🔴 BLOCK | Art. 70 § 5 OrdPU |
| 440 | `jdg.limitations.kks_criminal` | 🟡 TRIAGE | Art. 44 KKS |
| 441 | `jdg.limitations.document_retention` | 🟡 TRIAGE | Art. 86 OrdPU |
| 442 | `jdg.limitations.personal_liability` | 🔴 BLOCK | Art. 26 OrdPU, Art. 108 OrdPU (osoby trzecie) |
| 443 | `jdg.limitations.third_party_liability` | 🟡 TRIAGE | Art. 107-112 OrdPU |
| 444 | `jdg.limitations.late_payment_interest` |  | Art. 53-56 OrdPU |
| 445 | `jdg.limitations.voluntary_disclosure` |  | Art. 16 KKS, Art. 16a KKS |
| 446 | `jdg.limitations.tax_audit_procedures` | 🟡 TRIAGE | Art. 281-292 OrdPU |
| 447 | `jdg.limitations.interruption_proceedings` | 🔴 BLOCK | Art. 70 § 5 OrdPU |
| 448 | `jdg.limitations.liability_succession` | 🟡 TRIAGE | Art. 100-112 OrdPU |
| 449 | `jdg.limitations.audit_extended` | 🔴 BLOCK | Art. 83 ust. 1 OrdPU |

### `rules/taxfree/plan44_taxfree.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1920 | `jdg.taxfree.multi_source` |  | Art. 27 ust. 1 PIT |
| 1921 | `jdg.taxfree.jdg_vs_employment` |  | Art. 32 ust. 3 PIT |
| 1922 | `jdg.taxfree.linear_lump_sum_exclusion` |  | Art. 27, 30c, 30 PIT |
| 1923 | `jdg.taxfree.deduction_optimization` |  | Art. 6 ust. 2 PIT |
| 1924 | `jdg.taxfree.withholding_tax` |  | Art. 29-30a PIT |
| 1925 | `jdg.taxfree.foreign_income` |  | Art. 27 ust. 8 PIT |

### `rules/taxfree/plan45_taxfree.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1403 | `jdg.taxfree.hyper.scale_30k_amount` |  | Art. 27 ust. 1 PIT |
| 1404 | `jdg.taxfree.hyper.scale_250_monthly` |  | Art. 32 ust. 3 PIT |
| 1408 | `jdg.taxfree.hyper.linear_no_free_amount` |  | Art. 30c PIT |
| 1413 | `jdg.taxfree.hyper.multi_source_combined_limit` |  | Art. 27 PIT |
| 1423 | `jdg.taxfree.hyper.joint_filing_60k` |  | Art. 6 ust. 2 PIT |

### `rules/temporal.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1600 | `jdg.temporal.statute_limitations_5yr` | 🔴 BLOCK | Art. 70 § 1 Ordynacja podatkowa |
| 1602 | `jdg.temporal.statute_limitations_10yr` | 🔴 BLOCK | Art. 70 § 2 Ordynacja podatkowa (w zw. z art. 44 KKS) |
| 1603 | `jdg.temporal.statute_suspended` | 🔴 BLOCK | Art. 70 § 6-7 Ordynacja podatkowa |
| 1604 | `jdg.temporal.vat_rate_effective_2026` |  | RMK — mechanizm odwróconego monitorowania krajowego dla VAT |
| 1605 | `jdg.temporal.vat_rate_8pct_rmk_condition` |  | RMK — Art. 146ef VAT (klauzula powrotna) |
| 1606 | `jdg.temporal.historical_pit_rate_2019` |  | Art. 27 PIT (stan prawny na 2019 r.) |
| 1608 | `jdg.temporal.historical_pit_rate_2025` |  | Art. 27 PIT (stan prawny od 1 lipca 2022) |
| 1610 | `jdg.temporal.time_travel_rule_selection` |  | Art. 3 Ordynacja podatkowa (prawo obowiązujące w dacie zdarz... |
| 1612 | `jdg.temporal.document_retention_expiry` |  | Art. 86 § 1 Ordynacja podatkowa + Art. 112 VAT |

### `rules/tp/plan44_tp.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1930 | `jdg.tp.related_party_detection` | 🟡 TRIAGE | Art. 23m-23zf PIT |
| 1931 | `jdg.tp.documentation_thresholds` |  | Art. 23zf PIT |
| 1932 | `jdg.tp.local_file_requirements` | 🟡 TRIAGE | Art. 23zf PIT |
| 1933 | `jdg.tp.master_file_requirements` |  | Art. 23zf PIT |
| 1934 | `jdg.tp.tpr_form_filing` | 🟡 TRIAGE | Art. 23zh PIT |
| 1935 | `jdg.tp.benchmarking_analysis` |  | Art. 23zf PIT |
| 1936 | `jdg.tp.safe_harbor_low_value` |  | Art. 23zf PIT |
| 1937 | `jdg.tp.adjustment_consequences` | 🔴 BLOCK | Art. 58 Ordynacji podatkowej |
| 1938 | `jdg.tp.documentation_penalty` | 🔴 BLOCK | Art. 56 KKS |

### `rules/tp/plan45_tp.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1436 | `jdg.tp.hyper.threshold_2m_goods` |  | Art. 23zf PIT |
| 1437 | `jdg.tp.hyper.threshold_1m_financial` |  | Art. 23zf PIT |
| 1438 | `jdg.tp.hyper.threshold_500k_services` |  | Art. 23zf PIT |
| 1441 | `jdg.tp.hyper.local_file_deadline_10months` |  | Art. 23zf PIT |
| 1451 | `jdg.tp.hyper.tpr_deadline_nov30` |  | Art. 23zh PIT |
| 1461 | `jdg.tp.hyper.safe_harbor_5pct_margin` |  | Art. 23zf PIT |
| 1466 | `jdg.tp.hyper.adjustment_10pct_penalty` | 🔴 BLOCK | Art. 58 OP |
| 1471 | `jdg.tp.hyper.sanction_no_docs_10pct` | 🔴 BLOCK | Art. 56 KKS |

### `rules/uor/plan42_uor.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 875 | `jdg.uor.inventory_obligation` |  | Art. 26 ust. 1-3 UoR |
| 876 | `jdg.uor.asset_valuation` |  | Art. 28 ust. 1-7 UoR |
| 877 | `jdg.uor.accruals_deferrals` |  | Art. 39 UoR |
| 878 | `jdg.uor.financial_statement` | 🟡 TRIAGE | Art. 45, 52 UoR |
| 879 | `jdg.uor.document_storage` |  | Art. 74 UoR |

### `rules/validation.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 613 | `jdg.validation.nip_checksum` | 🔴 BLOCK | Art. 96 VAT (identyfikator podatkowy) |
| 614 | `jdg.validation.regon_checksum` | 🟡 TRIAGE | Ustawa o statystyce publicznej (REGON) |
| 615 | `jdg.validation.invoice_number_continuity` | 🟡 TRIAGE | Art. 106e VAT (faktura ustrukturyzowana) |
| 616 | `jdg.validation.invoice_date_future` | 🔴 BLOCK | Art. 106e ust. 1 pkt 1 VAT |
| 617 | `jdg.validation.sale_delivery_date_range` | 🟡 TRIAGE | Art. 106i ust. 1 VAT (termin wystawienia faktury) |
| 618 | `jdg.validation.invoice_amount_consistency` | 🔴 BLOCK | Art. 106e ust. 1 pkt 11-14 VAT |
| 619 | `jdg.validation.nip_seller_buyer_distinct` | 🔴 BLOCK | Art. 106e VAT (elementy faktury) |
| 620 | `jdg.validation.ksef_upo_required` | 🔴 BLOCK | Art. 106na VAT (obowiązkowy KSeF od 1.02.2026) |

### `rules/vat/deductions.rego` (26 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 39 | `jdg.vat.deductions.vat_r_registration_block` | 🔴 BLOCK | Art. 96 ust. 1, 4-5 VAT |
| 183 | `jdg.vat.deductions.blocked_categories` |  | Art. 88 ust. 1 VAT |
| 184 | `jdg.vat.deductions.bad_debt_debtor_mandatory` | 🔴 BLOCK | Art. 89b VAT |
| 185 | `jdg.vat.deductions.pre_proportion_mixed` |  | Art. 86 ust. 2a-2h VAT |
| 185 | `jdg.vat.deductions.pre_proportion_de_minimis` |  | Art. 86 ust. 2g VAT |
| 186 | `jdg.vat.deductions.vehicle_50pct` |  | Art. 86a VAT |
| 186 | `jdg.vat.deductions.vehicle_100pct` |  | Art. 86a VAT |
| 187 | `jdg.vat.deductions.annual_correction_assets` |  | Art. 91 VAT |
| 188 | `jdg.vat.deductions.deadline_3m_expired` | 🔴 BLOCK | Art. 86 ust. 11 VAT |
| 189 | `jdg.vat.deductions.bad_debt_creditor_150d_pre_slim3` |  | Art. 89a VAT (brzmienie przed SLIM VAT 3, obowiązujące do 20... |
| 189 | `jdg.vat.deductions.bad_debt_creditor_90d_post_slim3` |  | Art. 89a ust. 1a VAT (brzmienie po SLIM VAT 3, obowiązujące ... |
| 191 | `jdg.vat.deductions.import_timing` |  | Art. 86 ust. 2 pkt 2 VAT |
| 192 | `jdg.vat.deductions.refund_standard_60d` |  | Art. 87 VAT |
| 192 | `jdg.vat.deductions.refund_accelerated_25d` |  | Art. 87 ust. 6 VAT |
| 193 | `jdg.vat.deductions.wnt_same_period` |  | Art. 86 ust. 2 pkt 4 VAT |
| 194 | `jdg.vat.deductions.wnt_3months` | 🟡 TRIAGE | Art. 86 ust. 10b pkt 2 VAT |
| 195 | `jdg.vat.deductions.wnt_expired` | 🔴 BLOCK | Art. 86 ust. 10b pkt 2 VAT |
| 196 | `jdg.vat.deductions.import_services` |  | Art. 86 ust. 2 pkt 4 VAT |
| 197 | `jdg.vat.deductions.import_goods_sad` |  | Art. 86 ust. 2 pkt 2 VAT |
| 198 | `jdg.vat.deductions.reverse_charge_deduction` |  | Art. 86 ust. 2 pkt 4 VAT |
| 199 | `jdg.vat.deductions.bad_debt_creditor_correction` |  | Art. 89a ust. 1-2 VAT |
| 200 | `jdg.vat.deductions.bad_debt_reversal_on_payment` | 🟡 TRIAGE | Art. 89a ust. 4 VAT |
| 201 | `jdg.vat.deductions.bad_debt_bankruptcy` |  | Art. 89a ust. 2 pkt 1-3 VAT |
| 202 | `jdg.vat.deductions.vat_zt_deduction_correction` | 🟡 TRIAGE | Art. 86 ust. 10-13 VAT |
| 203 | `jdg.vat.deductions.sanction_deduction_block` | 🔴 BLOCK | Art. 108a ust. 5 VAT, Art. 96 ust. 3 VAT |
| 204 | `jdg.vat.deductions.cross_border_summary` |  | Art. 86 ust. 2 pkt 4 VAT |

### `rules/vat/plan23_detailed.rego` (16 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 36 | `jdg.vat.simplified_receipt_deduction` |  | Art. 106e ust. 5 pkt 3 VAT |
| 39 | `jdg.vat.registration_status_block` | 🔴 BLOCK | Art. 96 ust. 1, 4-5 VAT |
| 59 | `jdg.vat.subject_exemption_startup_proportion` |  | Art. 113 ust. 9 VAT |
| 61 | `jdg.vat.object_exemption_pkd` |  | Art. 43 VAT |
| 62 | `jdg.vat.exemption_financial` |  | Art. 43 ust. 1 pkt 37-41 VAT |
| 63 | `jdg.vat.exemption_insurance` |  | Art. 43 ust. 1 pkt 37 VAT |
| 183 | `jdg.vat.blocked_categories_no_deduction` | 🔴 BLOCK | Art. 88 VAT |
| 184 | `jdg.vat.bad_debt_debtor_mandatory_correction` | 🔴 BLOCK | Art. 89b VAT |
| 185 | `jdg.vat.pre_proportion_mixed` |  | Art. 90 VAT |
| 186 | `jdg.vat.vehicle_50_deduction` |  | Art. 86a VAT |
| 187 | `jdg.vat.annual_correction_assets` |  | Art. 91 VAT |
| 188 | `jdg.vat.deduction_deadline_3m` |  | Art. 86 ust. 11 VAT |
| 189 | `jdg.vat.bad_debt_relief_creditor` |  | Art. 89a VAT |
| 192 | `jdg.vat.refund_timing_and_interest` |  | Art. 87 ust. 2-7 VAT |
| 233 | `jdg.vat.deregistration_vat_z` | 🟡 TRIAGE | Art. 96 ust. 6-8 VAT |
| 234 | `jdg.vat.payment_deadline_and_interest` |  | Art. 103 ust. 1 VAT |

### `rules/vat/plan26_critical.rego` (16 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 36 | `jdg.vat.simplified_receipt_deduction` |  | Art. 106e ust. 5 pkt 3 VAT |
| 39 | `jdg.vat.registration_status_block` | 🔴 BLOCK | Art. 96 ust. 1, 4-5 VAT |
| 59 | `jdg.vat.subject_exemption_startup_proportion` |  | Art. 113 ust. 9 VAT |
| 61 | `jdg.vat.object_exemption_pkd` |  | Art. 43 VAT |
| 62 | `jdg.vat.exemption_financial` |  | Art. 43 ust. 1 pkt 37-41 VAT |
| 63 | `jdg.vat.exemption_insurance` |  | Art. 43 ust. 1 pkt 37 VAT |
| 183 | `jdg.vat.blocked_categories_no_deduction` | 🔴 BLOCK | Art. 88 VAT |
| 184 | `jdg.vat.bad_debt_debtor_mandatory_correction` | 🔴 BLOCK | Art. 89b VAT |
| 185 | `jdg.vat.pre_proportion_mixed` |  | Art. 90 VAT |
| 186 | `jdg.vat.vehicle_50_deduction` |  | Art. 86a VAT |
| 187 | `jdg.vat.annual_correction_assets` |  | Art. 91 VAT |
| 188 | `jdg.vat.deduction_deadline_3m` |  | Art. 86 ust. 11 VAT |
| 189 | `jdg.vat.bad_debt_relief_creditor` |  | Art. 89a VAT |
| 192 | `jdg.vat.refund_timing_and_interest` |  | Art. 87 ust. 2-7 VAT |
| 233 | `jdg.vat.deregistration_vat_z` | 🟡 TRIAGE | Art. 96 ust. 6-8 VAT |
| 234 | `jdg.vat.payment_deadline_and_interest` |  | Art. 103 ust. 1 VAT |

### `rules/vat/plan42_reduced_rates.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 66 | `jdg.vat.reduced_rate_8pct_food` | 🟡 TRIAGE | Rozporządzenie MF z 4.12.2024 r. ws. obniżonych stawek VAT |
| 67 | `jdg.vat.reduced_rate_5pct_books` | 🟡 TRIAGE | Rozporządzenie MF z 4.12.2024 r., Załącznik nr 2 |
| 68 | `jdg.vat.rate_8pct_construction` | 🟡 TRIAGE | Art. 41 ust. 12-12c VAT |
| 70 | `jdg.vat.rate_8pct_medical` | 🟡 TRIAGE | Rozporządzenie MF z 4.12.2024 r., Załącznik nr 1 |
| 71 | `jdg.vat.rate_5pct_baby` |  | Rozporządzenie MF z 4.12.2024 r., Załącznik nr 2 |
| 72 | `jdg.vat.reduced_rate_cross_check` |  | Art. 64 KKS — procedury audytowe |

### `rules/vat/procedures.rego` (17 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 66 | `jdg.vat.procedures.margin_used_goods` |  | Art. 120 ust. 4 VAT |
| 67 | `jdg.vat.procedures.oss_b2c` |  | Art. 28c VAT + rozp. 2019/2026 |
| 68 | `jdg.vat.procedures.ioss_import` |  | Art. 33a VAT |
| 152 | `jdg.vat.procedures.farmer_rr` |  | Art. 115-118 VAT |
| 230 | `jdg.vat.procedures.tax_point_continuous` |  | Art. 19a ust. 3 VAT |
| 231 | `jdg.vat.procedures.tax_point_advance` |  | Art. 19a ust. 8 VAT |
| 232 | `jdg.vat.procedures.vat_ue_quarterly` |  | Art. 100 ust. 1 pkt 2-3 VAT |
| 233 | `jdg.vat.procedures.vat_z_deregistration` |  | Art. 96 ust. 6 VAT |
| 234 | `jdg.vat.procedures.payment_deadline` |  | Art. 103 ust. 1 VAT |
| 235 | `jdg.vat.procedures.cash_accounting_jdg` |  | Art. 21 VAT |
| 235 | `jdg.vat.procedures.cash_accounting_purchase` |  | Art. 21 VAT |
| 236 | `jdg.vat.procedures.vat_23_new_vehicle` |  | Art. 103 ust. 3-4 VAT |
| 237 | `jdg.vat.procedures.vat_25_payment` |  | Art. 103 ust. 5-6 VAT |
| 238 | `jdg.vat.procedures.wis_binding_rate` |  | Art. 42a-42d VAT (WIS) |
| 239 | `jdg.vat.procedures.slim_vat3_procedural` |  | SLIM VAT 3 (Dz.U. 2023 poz. 1050) |
| 240 | `jdg.vat.procedures.empty_invoice_sanction` | 🔴 BLOCK | Art. 108a ust. 5, Art. 109 ust. 5b VAT, Art. 62 KKS |
| 241 | `jdg.vat.procedures.vat_ue_correction` | 🟡 TRIAGE | Art. 100 ust. 4-5 VAT |

### `rules/vat/substantive.rego` (46 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 50 | `jdg.vat.substantive.margin_scheme` |  | Art. 120 ustawy o VAT |
| 52 | `jdg.vat.substantive.fuel_pl` |  | Art. 41 ust. 1 VAT |
| 53 | `jdg.vat.substantive.food_pl` |  | Art. 41 ust. 2a VAT |
| 54 | `jdg.vat.substantive.books_pl` |  | Art. 41 ust. 2a VAT |
| 55 | `jdg.vat.substantive.education_exempt` |  | Art. 43 ust. 1 pkt 26-29 VAT |
| 56 | `jdg.vat.substantive.healthcare_exempt` |  | Art. 43 ust. 1 pkt 18-20 VAT |
| 57 | `jdg.vat.substantive.financial_exempt` |  | Art. 43 ust. 1 pkt 7, 37-38 VAT |
| 58 | `jdg.vat.substantive.subject_exemption_jdg` |  | Art. 113 ust. 1 i 9 VAT |
| 59 | `jdg.vat.substantive.startup_proportion` |  | Art. 113 ust. 9 VAT |
| 60 | `jdg.vat.substantive.bad_debt_relief_creditor_150d` |  | Art. 89a VAT (brzmienie przed SLIM VAT 3, obowiązujące do 20... |
| 60 | `jdg.vat.substantive.bad_debt_relief_creditor_90d` |  | Art. 89a ust. 1a VAT (SLIM VAT 3, od 2023-01-01) |
| 61 | `jdg.vat.substantive.culture_exempt` |  | Art. 43 ust. 1 pkt 32-33 VAT |
| 62 | `jdg.vat.substantive.real_estate_exempt` |  | Art. 43 ust. 1 pkt 10 VAT |
| 63 | `jdg.vat.substantive.postal_exempt` |  | Art. 43 ust. 1 pkt 17 VAT |
| 64 | `jdg.vat.substantive.rate_8pct` |  | Art. 41 ust. 2 VAT w zw. z załącznikiem nr 3 |
| 65 | `jdg.vat.substantive.gtu_mapping` |  | § 10 rozporządzenia JPK_VAT |
| 66 | `jdg.vat.substantive.rate_5pct_extended` |  | Art. 41 ust. 2a VAT |
| 67 | `jdg.vat.substantive.books_5pct_validation` |  | Rozp. MF z 4.12.2024 r., Załącznik nr 2 + Art. 41 ust. 2a VA... |
| 67 | `jdg.vat.substantive.rate_23_standard_pl` |  | Art. 41 ust. 1 VAT |
| 68 | `jdg.vat.substantive.construction_8pct_validation` |  | Art. 41 ust. 12-12c VAT + Rozp. MF z 4.12.2024 r. |
| 70 | `jdg.vat.substantive.medical_equipment_8pct_validation` |  | Rozp. MF z 4.12.2024 r., Załącznik nr 1, poz. 87-105 |
| 70 | `jdg.vat.substantive.reverse_charge_domestic_goods` |  | Art. 17 ust. 1 pkt 7 VAT |
| 71 | `jdg.vat.substantive.reverse_charge_construction` |  | Art. 17 ust. 1 pkt 8 VAT |
| 72 | `jdg.vat.substantive.reverse_charge_waste` |  | Art. 17 ust. 1 pkt 7 VAT |
| 72 | `jdg.vat.substantive.reduced_rate_cross_check` | 🟡 TRIAGE | Art. 64 KKS (niewłaściwa stawka VAT) + procedury audytowe |
| 73 | `jdg.vat.substantive.reverse_charge_certificates` |  | Art. 17 ust. 1 pkt 7 VAT |
| 74 | `jdg.vat.substantive.reverse_charge_precious_metals` |  | Art. 17 ust. 1 pkt 7 VAT (załącznik nr 11) |
| 80 | `jdg.vat.substantive.wnt_goods_from_eu` |  | Art. 9 ust. 1-2 VAT |
| 81 | `jdg.vat.substantive.wnt_new_vehicle` |  | Art. 9 ust. 2 pkt 1 VAT |
| 82 | `jdg.vat.substantive.wnt_excise_goods` |  | Art. 9 ust. 1 VAT, Art. 99 ust. 3 VAT |
| 83 | `jdg.vat.substantive.wnt_triangular_simplification` |  | Art. 135-138 VAT |
| 90 | `jdg.vat.substantive.import_of_services_b2b` |  | Art. 28b VAT |
| 91 | `jdg.vat.substantive.import_of_services_eu` |  | Art. 28b VAT |
| 92 | `jdg.vat.substantive.import_of_services_non_eu` |  | Art. 28b VAT |
| 93 | `jdg.vat.substantive.import_goods_customs` |  | Art. 26a VAT, Art. 86 ust. 2 pkt 2 VAT |
| 100 | `jdg.vat.substantive.split_payment_mandatory` |  | Art. 108a VAT |
| 101 | `jdg.vat.substantive.split_payment_voluntary` |  | Art. 108a ust. 3 VAT |
| 102 | `jdg.vat.substantive.split_payment_sanction` | 🔴 BLOCK | Art. 108a ust. 5-7 VAT |
| 110 | `jdg.vat.substantive.jpk_v7_structure_mapping` |  | § 10 rozporządzenia JPK_VAT |
| 111 | `jdg.vat.substantive.jpk_v7_flags_documentation` |  | § 10 rozporządzenia JPK_VAT |
| 120 | `jdg.vat.substantive.vat_zt_correction_required` | 🟡 TRIAGE | Art. 81-81c OrdPU, Art. 96 ust. 6 VAT |
| 121 | `jdg.vat.substantive.vat_correction_deadline` | 🟡 TRIAGE | Art. 81-81c OrdPU |
| 122 | `jdg.vat.substantive.vat_zt_carry_forward` |  | Art. 87 VAT |
| 130 | `jdg.vat.substantive.wdt_export_0pct` |  | Art. 13 VAT (WDT), Art. 2 pkt 8 VAT (eksport) |
| 131 | `jdg.vat.substantive.vat_sanction_no_registration` | 🔴 BLOCK | Art. 96 ust. 3 VAT, Art. 54 KKS, Art. 77 KKS |
| 140 | `jdg.vat.substantive.receipt_as_invoice` |  | Art. 106e ust. 5 pkt 3 VAT (faktura uproszczona do 450 PLN /... |

### `rules/wis/plan44_wis.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1820 | `jdg.wis.binding_rate_check` |  | Art. 42a-42h VAT |
| 1821 | `jdg.wis.validity_monitoring` |  | Art. 42h VAT |
| 1822 | `jdg.wis.gtu_code_mapping` |  | Art. 42a VAT, Rozporządzenie JPK_V7 |
| 1823 | `jdg.wis.vs_individual_interpretation` |  | Art. 42b VAT |
| 1824 | `jdg.wis.for_import_goods` |  | Art. 42a VAT |
| 1825 | `jdg.wis.wit_tariff_information` |  | Art. 33 UKC (Unijny Kodeks Celny) |
| 1826 | `jdg.wis.wia_excise_information` |  | Ustawa o podatku akcyzowym |
| 1827 | `jdg.wis.cost_benefit_analysis` |  | Art. 42a-42h VAT |

### `rules/wis/plan45_wis.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1071 | `jdg.wis.hyper.eligibility_cn_ambiguous` |  | Art. 42a VAT |
| 1078 | `jdg.wis.hyper.eligibility_turnover_50k` |  | Art. 42a VAT |
| 1079 | `jdg.wis.hyper.application_cost_40pln` |  | Art. 42b VAT |
| 1083 | `jdg.wis.hyper.validity_5years` |  | Art. 42h VAT |
| 1086 | `jdg.wis.hyper.expiry_alert_6months` |  | Art. 42h VAT |
| 1092 | `jdg.wis.hyper.gtu_mapping` |  | Art. 42a VAT |
| 1093 | `jdg.wis.hyper.sanction_no_wis_risk` |  | Art. 64 KKS |
| 1097 | `jdg.wis.hyper.wit_validity_3years` |  | UKC Art. 33 |
| 1103 | `jdg.wis.hyper.cost_benefit` |  | Art. 42a VAT |

### `rules/zus.rego` (21 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 700 | `jdg.zus.social_standard` |  | Art. 18, 18a, 22 ustawy o SUS |
| 720 | `jdg.zus.health_scale` |  | Art. 79 ust. 1, art. 81 ust. 1 ustawy o świadczeniach opieki... |
| 722 | `jdg.zus.health_linear` |  | Art. 79 ust. 2, art. 81 ust. 2, art. 30c ust. 2 pkt 2 PIT |
| 724 | `jdg.zus.health_lump_sum` |  | Art. 81 ust. 2a-2c ustawy o świadczeniach opieki zdrowotnej |
| 740 | `jdg.zus.start_relief` |  | Art. 18a ustawy o SUS |
| 741 | `jdg.zus.maly_plus` |  | Art. 18c ustawy o SUS |
| 742 | `jdg.zus.preferential` |  | Art. 18a ustawy o SUS |
| 743 | `jdg.zus.concurrent_employment` |  | Art. 9 ust. 2a ustawy o SUS |
| 1200 | `jdg.zus.sickness_benefit` |  | Art. 6-18 Ustawy o świadczeniach pieniężnych z ubezpieczenia... |
| 1201 | `jdg.zus.maternity_benefit` |  | Art. 29-31 Ustawy o świadczeniach pieniężnych z ubezpieczeni... |
| 1202 | `jdg.zus.care_benefit` |  | Art. 32-35 Ustawy o świadczeniach pieniężnych z ubezpieczeni... |
| 1203 | `jdg.zus.rehabilitation_benefit` |  | Art. 18 Ustawy o świadczeniach pieniężnych z ubezpieczenia s... |
| 1204 | `jdg.zus.accident_benefit` |  | Art. 6-9 Ustawy o ubezpieczeniu społecznym z tytułu wypadków... |
| 1205 | `jdg.zus.funeral_grant` |  | Art. 77-81 Ustawy o emeryturach i rentach z FUS |
| 1206 | `jdg.zus.benefit_coordination` | 🟡 TRIAGE | Art. 41-43 Ustawy o świadczeniach pieniężnych z ubezpieczeni... |
| 1207 | `jdg.zus.old_age_pension` |  | Art. 24-28 Ustawy o emeryturach i rentach z FUS |
| 1208 | `jdg.zus.bridge_pension` |  | Ustawa o emeryturach pomostowych z dn. 19.12.2008 |
| 1209 | `jdg.zus.disability_pension` | 🟡 TRIAGE | Art. 57-64 Ustawy o emeryturach i rentach z FUS |
| 1210 | `jdg.zus.survivors_pension` |  | Art. 65-74 Ustawy o emeryturach i rentach z FUS |
| 1211 | `jdg.zus.pre_retirement_benefit` | 🟡 TRIAGE | Ustawa o swiadczeniach przedemerytalnych z dn. 30.04.2004 |
| 1212 | `jdg.zus.ikze_ike` |  | Ustawa o IKE z dn. 20.04.2004, Ustawa o IKZE z dn. 12.05.201... |

### `rules/zus/plan23_interactions.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 730 | `jdg.zus.health_contribution_rate_matrix` |  | Art. 81 ustawy o świadczeniach zdrowotnych |
| 732 | `jdg.zus.form_change_contribution_trigger` |  | Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych |
| 736 | `jdg.zus.tax_card_health_fixed` |  | Art. 81 ust. 2za ustawy o świadczeniach zdrowotnych |
| 739 | `jdg.zus.health_insurance_obligation` |  | Art. 66 ust. 1 pkt 1c ustawy o świadczeniach zdrowotnych |
| 743 | `jdg.zus.concurrent_employment_exemption` |  | Art. 9 ust. 1a-2 SUS |
| 744 | `jdg.zus.insurance_cessation_dates` |  | Art. 8-9, Art. 14 SUS |
| 745 | `jdg.zus.payment_deadline_per_entity_type` |  | Art. 47 SUS |
| 746 | `jdg.zus.dra_filing_deadline_check` |  | Art. 16-17 SUS |
| 748 | `jdg.zus.health_payment_deadline_check` |  | Art. 82 ustawy o świadczeniach zdrowotnych |

### `rules/zus/plan42_benefits.rego` (8 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 770 | `jdg.zus.contribution_base_calculation` |  | Art. 18 ust. 8 SUS |
| 771 | `jdg.zus.contribution_split_by_fund` |  | Art. 22 SUS |
| 772 | `jdg.zus.contribution_deadline` |  | Art. 47 ust. 1-2 SUS |
| 773 | `jdg.zus.contribution_payment_verification` | 🟡 TRIAGE | Art. 47 SUS |
| 1200 | `jdg.zus.sickness_benefit_eligibility` |  | Art. 4 ust. 1, Art. 7, Art. 48-54 Ustawy zasiłkowej |
| 1201 | `jdg.zus.sickness_benefit_amount` |  | Art. 36-45 Ustawy zasiłkowej |
| 1205 | `jdg.zus.benefit_payment_deadline` |  | Art. 61-64 Ustawy zasiłkowej |
| 1206 | `jdg.zus.benefit_overpayment_detection` | 🔴 BLOCK | Art. 66-68 Ustawy zasiłkowej |

---
*Wygenerowano automatycznie — 2026-07-14 02:54:32*
*Aktualizuj przez: `python JDG/tools/generate_manifest.py`*