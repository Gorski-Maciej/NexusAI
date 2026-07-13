# 📋 JDG MANIFEST — Tracker Pokrycia Reguł vs Mapa Kanoniczna 38c

> **Auto-generowane:** 2026-07-13 13:14:10
> **Plików Rego:** 36
> **Reguł:** 710
> **Mapa kanoniczna:** `Plan OPA/38c_JDG_CANONICAL_MAP.md` (~779 reguł)

---

## 📊 REGUŁY PER PLIK

| Plik | Reguł | BLOCK | TRIAGE |
|------|:-----:|:-----:|:------:|
| `rules/accounting.rego` | 67 | 6 | 13 |
| `rules/allowances.rego` | 12 | 0 | 0 |
| `rules/business.rego` | 8 | 3 | 1 |
| `rules/compliance.rego` | 7 | 2 | 0 |
| `rules/conflicts.rego` | 27 | 6 | 11 |
| `rules/corrections.rego` | 16 | 2 | 5 |
| `rules/crossborder.rego` | 14 | 3 | 4 |
| `rules/digital.rego` | 6 | 3 | 0 |
| `rules/edge_cases.rego` | 128 | 25 | 42 |
| `rules/employer.rego` | 9 | 2 | 0 |
| `rules/environmental.rego` | 8 | 3 | 0 |
| `rules/fallback.rego` | 1 | 0 | 0 |
| `rules/international.rego` | 4 | 0 | 1 |
| `rules/kks.rego` | 152 | 95 | 42 |
| `rules/ksef_jpk.rego` | 6 | 0 | 1 |
| `rules/liability.rego` | 5 | 0 | 0 |
| `rules/local_taxes.rego` | 13 | 0 | 4 |
| `rules/mpips.rego` | 12 | 0 | 5 |
| `rules/pit/advances_returns.rego` | 8 | 1 | 0 |
| `rules/pit/exemptions.rego` | 5 | 0 | 0 |
| `rules/pit/forms.rego` | 7 | 2 | 0 |
| `rules/pit/kup.rego` | 9 | 1 | 0 |
| `rules/pit/transitions.rego` | 5 | 0 | 1 |
| `rules/representation.rego` | 7 | 3 | 0 |
| `rules/restructuring.rego` | 7 | 5 | 0 |
| `rules/retention.rego` | 6 | 1 | 0 |
| `rules/risk.rego` | 8 | 7 | 1 |
| `rules/rodo.rego` | 12 | 2 | 10 |
| `rules/routing.rego` | 5 | 2 | 3 |
| `rules/statute_of_limitations.rego` | 14 | 5 | 6 |
| `rules/temporal.rego` | 9 | 3 | 0 |
| `rules/validation.rego` | 8 | 5 | 3 |
| `rules/vat/deductions.rego` | 25 | 4 | 3 |
| `rules/vat/procedures.rego` | 17 | 1 | 1 |
| `rules/vat/substantive.rego` | 42 | 2 | 2 |
| `rules/zus.rego` | 21 | 0 | 3 |
| **RAZEM** | **710** | — | — |

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

### `rules/compliance.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 20 | `jdg.compliance.whitelist_missing_over_limit` | 🔴 BLOCK | Art. 96b VAT, Art. 117ba Ordynacji podatkowej |
| 21 | `jdg.compliance.whitelist_account_mismatch` | 🔴 BLOCK | Art. 117ba § 1 Ordynacji podatkowej |
| 25 | `jdg.compliance.split_payment_mandatory` |  | Art. 108a VAT |
| 25 | `jdg.compliance.split_payment_voluntary_safe_harbor` |  | Art. 108a ust. 1d VAT |
| 35 | `jdg.compliance.cash_transaction_over_limit` |  | Art. 22p ustawy o PIT |
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

### `rules/crossborder.rego` (14 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 40 | `jdg.crossborder.eu_reverse_charge` |  | Art. 17 ust. 1 pkt 3 VAT |
| 41 | `jdg.crossborder.eu_import_services` |  | Art. 28b VAT |
| 42 | `jdg.crossborder.wdt_intracommunity_supply` |  | Art. 42 VAT |
| 42 | `jdg.crossborder.wdt_no_docs` | 🔴 BLOCK | Art. 42 ust. 1 pkt 1-2 VAT |
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

### `rules/digital.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 630 | `jdg.digital.crypto_taxable_event` |  | Art. 22d, 22e, 30b PIT |
| 1890 | `jdg.digital.crypto_mining_business` |  | Art. 22d PIT + interpretacje KIS (np. 0114-KDIP2-1.4010.312.... |
| 1892 | `jdg.digital.crypto_mdr_reporting` | 🔴 BLOCK | Art. 86a-86o Ordynacja podatkowa (MDR) + DAC6 |
| 1893 | `jdg.digital.ai_act_compliance_check` | 🔴 BLOCK | Rozporządzenie UE 2024/1689 (AI Act) |
| 1894 | `jdg.digital.api_degradation_fallback` |  | Konfiguracja operacyjna — Art. 3 pkt 7 RODO (integralność i ... |
| 1895 | `jdg.digital.deepfake_ai_disclosure` | 🔴 BLOCK | Art. 50 Rozporządzenia UE 2024/1689 (AI Act) |

### `rules/edge_cases.rego` (128 reguł)

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

### `rules/employer.rego` (9 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1200 | `jdg.employer.creative_kup_50` |  | Art. 22 ust. 9 pkt 3 PIT |
| 1202 | `jdg.employer.standard_kup_250` |  | Art. 22 ust. 2 PIT |
| 1204 | `jdg.employer.kup_300_commuting` |  | Art. 22 ust. 2 pkt 3 PIT |
| 1206 | `jdg.employer.multiple_contracts_kup` |  | Art. 22 ust. 2 pkt 4 PIT |
| 1208 | `jdg.employer.civil_law_contract_20` |  | Art. 22 ust. 9 pkt 4 PIT |
| 1210 | `jdg.employer.civil_law_creative_50` |  | Art. 22 ust. 9 pkt 3 PIT |
| 1212 | `jdg.employer.ppk_contributions` |  | Ustawa o PPK |
| 1214 | `jdg.employer.pit4r_monthly` | 🔴 BLOCK | Art. 38 ust. 1 PIT |
| 1216 | `jdg.employer.annual_pit_summary` | 🔴 BLOCK | Art. 38 ust. 1a i Art. 42 ust. 1a PIT |

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

### `rules/fallback.rego` (1 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1000 | `jdg.fallback.domestic_23pct` |  | Art. 41 ust. 1 VAT, Art. 27 ust. 1 PIT (domyślnie skala) |

### `rules/international.rego` (4 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 29 | `jdg.international.tp_safe_harbour_low_value` |  | Art. 23zf PIT |
| 100 | `jdg.international.wht_obligation` |  | Art. 30a PIT, art. 21 CIT |
| 110 | `jdg.international.pe_risk` | 🟡 TRIAGE | Art. 5 umów o unikaniu podwójnego opodatkowania |
| 114 | `jdg.international.tp_documentation_threshold` |  | Art. 23q-23zf PIT |

### `rules/kks.rego` (152 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
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

### `rules/ksef_jpk.rego` (6 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 950 | `jdg.ksef_jpk.ksef_mandatory` |  | Art. 106na-106nq VAT |
| 952 | `jdg.ksef_jpk.ksef_b2c_exemption` |  | Art. 106ga ust. 2 pkt 4 VAT |
| 960 | `jdg.ksef_jpk.ksef_offline_recovery` |  | Art. 106ne VAT |
| 970 | `jdg.ksef_jpk.jpk_v7m` |  | Art. 99 VAT, rozporządzenie JPK_VAT |
| 974 | `jdg.ksef_jpk.jpk_gtu_completeness` | 🟡 TRIAGE | § 10 rozporządzenia JPK_VAT |
| 980 | `jdg.ksef_jpk.jpk_pkpir` |  | Art. 193a Ordynacji podatkowej |

### `rules/liability.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 1150 | `jdg.liability.statute_5_years` |  | Art. 70 § 1 Ordynacji podatkowej |
| 1158 | `jdg.liability.personal_liability` |  | Art. 33 Ordynacji podatkowej, Art. 415 KC |
| 1164 | `jdg.liability.late_payment_interest` |  | Art. 47-52 Ordynacji podatkowej |
| 1168 | `jdg.liability.voluntary_disclosure` |  | Art. 16-16b KKS |
| 1169 | `jdg.liability.overpayment_detection` |  | Art. 72-80 Ordynacji podatkowej |

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

### `rules/pit/exemptions.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 580 | `jdg.pit.exemptions.young` |  | Art. 21 ust. 1 pkt 148 PIT |
| 582 | `jdg.pit.exemptions.return` |  | Art. 21 ust. 1 pkt 152 PIT |
| 584 | `jdg.pit.exemptions.family_4plus` |  | Art. 21 ust. 1 pkt 153 PIT |
| 586 | `jdg.pit.exemptions.working_senior` |  | Art. 21 ust. 1 pkt 154 PIT |
| 588 | `jdg.pit.exemptions.shared_limit` |  | Art. 21 ust. 1 pkt 148-154 PIT |

### `rules/pit/forms.rego` (7 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 500 | `jdg.pit.forms.scale` |  | Art. 27 ust. 1 PIT |
| 502 | `jdg.pit.forms.scale_joint_filing` |  | Art. 6 ust. 2 PIT |
| 510 | `jdg.pit.forms.linear` |  | Art. 30c PIT |
| 512 | `jdg.pit.forms.linear_former_employer_block` | 🔴 BLOCK | Art. 30c ust. 2 PIT |
| 520 | `jdg.pit.forms.lump_sum` |  | Art. 12 ustawy o ryczałcie ewidencjonowanym |
| 523 | `jdg.pit.forms.lump_sum_limit_exceeded` | 🔴 BLOCK | Art. 6 ust. 4 ustawy o ryczałcie |
| 530 | `jdg.pit.forms.tax_card` |  | Art. 21-30 ustawy o ryczałcie (rozdział 3) |

### `rules/pit/kup.rego` (9 reguł)

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

### `rules/pit/transitions.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 590 | `jdg.pit.transitions.scale_to_linear` |  | Art. 9a ust. 2, Art. 30c PIT |
| 592 | `jdg.pit.transitions.lump_sum_loss_to_scale` |  | Art. 20 ustawy o ryczałcie |
| 593 | `jdg.pit.transitions.mid_year_block` | 🟡 TRIAGE | Art. 9a ust. 5 PIT |
| 594 | `jdg.pit.transitions.dual_return` |  | Art. 45 ust. 1b PIT |
| 596 | `jdg.pit.transitions.health_recalc` |  | Art. 81 ustawy o świadczeniach opieki zdrowotnej |

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

### `rules/routing.rego` (5 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
| 10 | `jdg.routing.fc_vat_rate_low_scale` | 🔴 BLOCK | Art. 22 UoR (rzetelność ksiąg) |
| 12 | `jdg.routing.fc_vendor_nip_low` | 🔴 BLOCK | Art. 96b VAT, Art. 22 UoR |
| 14 | `jdg.routing.fc_linear_minimum` | 🟡 TRIAGE | Art. 22 UoR |
| 15 | `jdg.routing.fc_lump_sum_vat_rate` | 🟡 TRIAGE | Art. 22 UoR |
| 19 | `jdg.routing.fc_global_minimum_low` | 🟡 TRIAGE | Art. 22 UoR |

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

### `rules/vat/deductions.rego` (25 reguł)

| Priorytet | Rule ID | Routing | Podstawa prawna |
|:---------:|---------|:-------:|----------------|
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

### `rules/vat/substantive.rego` (42 reguł)

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
| 67 | `jdg.vat.substantive.rate_23_standard_pl` |  | Art. 41 ust. 1 VAT |
| 70 | `jdg.vat.substantive.reverse_charge_domestic_goods` |  | Art. 17 ust. 1 pkt 7 VAT |
| 71 | `jdg.vat.substantive.reverse_charge_construction` |  | Art. 17 ust. 1 pkt 8 VAT |
| 72 | `jdg.vat.substantive.reverse_charge_waste` |  | Art. 17 ust. 1 pkt 7 VAT |
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

---
*Wygenerowano automatycznie — 2026-07-13 13:14:10*
*Aktualizuj przez: `python JDG/tools/generate_manifest.py`*