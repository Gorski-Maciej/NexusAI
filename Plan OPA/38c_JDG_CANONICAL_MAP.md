# 🗺️ JDG Canonical Rule Map — ~779 unikalnych reguł po integracji Docs 22-43

> **Status:** ENTERPRISE GOLDEN REFERENCE v2.0 — Definitywne mapowanie kanoniczne  
> **Data:** 2026-07-12  
> **Autor:** Zespół NexusAI  
> **Plik:** `Plan OPA/38c_JDG_CANONICAL_MAP.md`  
> **Bazuje na:** `38b_JDG_DEDUP_REPORT.md` (audyt deduplikacji)  
> **Dokumenty źródłowe:** `22_JDG_ENTERPRISE_PLAN.md`, `23_JDG_EXPANSION_SUPPLEMENT.md`, `28a_JDG_EDGE_CASES_FULL.md`, `42_JDG_DEEP_GAP_DISCOVERY.md`, `43_JDG_KKS_MASSIVE_DECOMPOSITION.md`

---

## 📊 EXECUTIVE SUMMARY

| Metryka | Wartość |
|---|---|
| **Reguły łącznie we wszystkich dokumentach** | **~880** |
| **Reguły po deduplikacji (KANONICZNE)** | **~800** |
| **Reguły zdeprecjonowane** | **47** |
| — z Doc 22 | 17 P-ID |
| — z Doc 23 | 28 P-ID |
| — z Doc 28a | 2 R-ID |
| **Reguły aktywne z Doc 22** | 136 |
| **Reguły aktywne z Doc 23** | 108 |
| **Reguły aktywne z Doc 28a** | 50+ (kluczowe grupy R-ID) |
| **Reguły aktywne z Doc 42** | 55 |
| **Reguły aktywne z Doc 43** | 230 |

### Legenda

| Symbol | Znaczenie |
|:------:|-----------|
| ✅ | **AKTYWNA** — reguła kanoniczna, używana w systemie |
| 🔴 | **[DEPRECATED]** — zastąpiona, nie implementować |
| 🔀 | **MERGE** — wchłonięta jako edge case w innej regule |
| 🔧 | **HELPER** — funkcja pomocnicza, nie reguła decyzyjna |

---

## 📋 CZĘŚĆ I: DOC 22 — 167 P-ID (150 aktywnych, 17 zdeprecjonowanych)

### Grupa 1: Risk & Fraud (P0-P9) — 7 aktywnych

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P0 | `fraud_graph_match` | ✅ | — | |
| P0_b | `kks_empty_invoice_fraud` | ✅ | — | |
| P1 | `counterparty_trust_low` | ✅ | — | |
| P2 | `anomaly_amount` | ✅ | — | |
| P3 | `new_counterparty_flag` | ✅ | — | |
| P4 | `kks_hidden_income_flag` | ✅ | — | |
| P5 | `semantic_guard_disallowed` | ✅ | — | |
| P6 | `kks_unreliable_books` | ✅ | — | |
| P6_b | `kks_declaration_overdue` | ✅ | — | |
| P7 | `kks_vat_evidence_gap` | ✅ | — | |
| P8 | `ceidg_vendor_suspended` | ✅ | — | |
| P9 | `gaar_artificial_scheme` | ✅ | — | |

### Grupa 2: Routing & Field Confidence (P10-P19) — 4 aktywne

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P10 | `fc_vat_rate_low_scale` | ✅ | — | |
| P11 | `fc_total_net_low_scale` | ✅ | — | |
| P12 | `fc_vendor_nip_low` | ✅ | — | |
| P14 | `fc_linear_minimum` | ✅ | — | |
| P15 | `fc_lump_sum_vat_rate` | ✅ | — | |
| P16 | `fc_lump_sum_total_net` | ✅ | — | |
| P19 | `fc_global_minimum_low` | ✅ | — | |

### Grupa 3: Compliance (P20-P39, P140-P157) — 8 aktywnych

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P20 | `whitelist_missing_over_limit` | ✅ | — | |
| P21 | `whitelist_account_mismatch` | ✅ | — | |
| P22 | `whitelist_verification` | ✅ | — | |
| P25 | `split_payment_mandatory` | ✅ | — | |
| P25_b | `split_payment_voluntary_safe_harbor` | ✅ | — | |
| P29 | `tp_safe_harbour_low_value_services` | ✅ | — | |
| P35 | `cash_transaction_over_limit` | ✅ | — | |
| P36 | `vat_simplified_receipt` | ✅ | — | |
| P39 | `vat_r_registration_status` | ✅ | — | |
| P140 | `construction_reverse_charge_jdg` | ✅ | — | |
| P141 | `it_service_export_b2b` | ✅ | — | |
| P143 | `platform_app_store_b2b_export` | ✅ | — | |
| P144 | `platform_import_of_services` | ✅ | — | |
| P145 | `cash_register_b2c_exemption_20k` | ✅ | — | |
| P146 | `e_commerce_virtual_cash_register` | ✅ | — | |
| P152 | `vat_farmer_rr_purchase_invoice` | ✅ | — | |
| P155 | `cesop_cross_border_payment_reporting` | ✅ | — | |

### Grupa 4: Crossborder (P40-P49) — 🔴 5 zdeprecjonowanych, 5 aktywnych

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P40 | `eu_reverse_charge` | 🔴 | P43 (Doc 23) | Płytka wersja z Doc 22 |
| P41 | `eu_import_services` | 🔴 | P44 (Doc 23) | Płytka wersja z Doc 22 |
| P42 | `wdt_intracommunity_supply` | 🔴 | P46 (Doc 23) | Płytka wersja z Doc 22 |
| P42_b | `wdt_vat_refund_accelerated` | ✅ | — | |
| P42_c | `wdt_documentation_evidence` | ✅ | — | |
| P43 | `crossborder_from_doc23` | ✅ | — | Kanoniczne z Doc 23 |
| P44 | `crossborder_from_doc23` | ✅ | — | Kanoniczne z Doc 23 |
| P45 | `import_non_eu` | 🔴 | P47 (Doc 23) | Płytka wersja z Doc 22 |
| P46 | `crossborder_from_doc23` | ✅ | — | Kanoniczne z Doc 23 |
| P47 | `import_services_non_eu` | ✅ | — | Z Doc 23 |
| P48 | `export_goods` | 🔴 | P49 (Doc 23) | Płytka wersja z Doc 22 |
| P49 | `triangular_transaction_rules` | ✅ | — | Kanoniczne z Doc 23 |
| P49_b | `triangular_simplified_conditions` | ✅ | — | |

### Grupa 5: VAT — Stawki i zwolnienia (P50-P69, P183-P235)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P50 | `vat_margin_scheme` | ✅ | — | |
| P52 | `vat_rate_fuel_pl` | ✅ | — | |
| P53 | `vat_rate_food_pl` | ✅ | — | |
| P54 | `vat_rate_books` | ✅ | — | |
| P55 | `vat_exemption_education` | ✅ | — | |
| P56 | `vat_exemption_healthcare` | ✅ | — | |
| P58 | `vat_exemption_subject_jdg` | ✅ | — | 🔑 Reguła GŁÓWNA VAT — NIE deprecjonować! R0546-R0559 to edge cases w `else` |
| P60 | `vat_bad_debt_relief` | 🔴 | P189 (Doc 23) | 150 dni, ale Doc 23 bardziej szczegółowy |
| P64 | `vat_margin_scheme_used_goods` | ✅ | — | |
| P65 | `gtu_mapping_by_category` | ✅ | — | |
| P69 | `vat_correction_rules` | ✅ | — | |
| P183 | `vat_blocked_categories` | ✅ | — | |
| P184 | `bad_debt_debtor_correction_mandatory` | ✅ | — | |
| P185 | `vat_pre_proportion_mixed` | ✅ | — | |
| P186 | `vehicle_50_vat_deduction` | ✅ | — | |
| P189 | `bad_debt_relief_creditor` | ✅ | — | Kanoniczne z Doc 23 (⚠️ wymaga poprawy: 150 dni) |
| P190 | `crossborder_vat_doc23` | ✅ | — | Kanoniczne z Doc 23 |
| P191 | `crossborder_vat_doc23` | ✅ | — | Kanoniczne z Doc 23 |
| P192 | `vat_deduction_rules` | ✅ | — | |
| P230 | `vat_tax_point_continuous_service` | 🔴 | R0546-R0559 (Doc 28a) | Edge case w `else` po P58 |
| P231 | `vat_tax_point_advance_invoice` | 🔴 | R0546-R0559 (Doc 28a) | Edge case w `else` po P58 |
| P232 | `vat_ue_summary` | ✅ | — | Kanoniczne z Doc 23 |
| P233 | `vat_oss_procedure` | ✅ | — | |
| P234 | `vat_oss_union` | ✅ | — | |
| P235 | `vat_cash_accounting_jdg` | 🔴 | R0546-R0559 (Doc 28a) | Edge case w `else` po P58 |

### Grupa 6: PIT — Formy opodatkowania (P500-P539)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P500 | `pit_form_scale` | ✅ | — | |
| P501 | `pit_scale_bracket_determination` | ✅ | — | |
| P502 | `pit_scale_joint_filing` | ✅ | — | |
| P508 | `pit_scale_tax_free_amount` | ✅ | — | |
| P509 | `pit_scale_deductions` | ✅ | — | |
| P510 | `pit_form_linear` | ✅ | — | |
| P511 | `pit_linear_no_tax_free_amount` | ✅ | — | |
| P512 | `linear_former_employer_restriction` | ✅ | — | |
| P519 | `pit_linear_deductions` | ✅ | — | |
| P520 | `pit_form_lump_sum` | ✅ | — | |
| P521 | `lump_sum_rate_by_pkwiu` | ✅ | — | |
| P522 | `lump_sum_limits` | ✅ | — | |
| P523 | `lump_sum_annual_limit` | ✅ | — | |
| P524 | `lump_sum_statutory_exclusions` | ✅ | — | |
| P526 | `lump_sum_excluded_services` | ✅ | — | |
| P529 | `lump_sum_deductions` | ✅ | — | |
| P530 | `pit_form_tax_card` | ✅ | — | |
| P531 | `tax_card_rates` | ✅ | — | |
| P532 | `tax_card_conditions` | ✅ | — | |
| P533 | `tax_card_limits` | ✅ | — | |
| P539 | `tax_card_deductions` | ✅ | — | |

### Grupa 7: PIT — Zaliczki i zeznania (P540-P559)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P540 | `pit_advance_monthly` | ✅ | — | |
| P541 | `pit_advance_zus_social_deduction` | ✅ | — | |
| P542 | `pit_advance_quarterly` | ✅ | — | |
| P543 | `pit_advance_cessation` | ✅ | — | |
| P549 | `pit_advance_calculation` | ✅ | — | |
| P550 | `pit_annual_return_pit36` | ✅ | — | |
| P552 | `pit_annual_return_pit36l` | ✅ | — | |
| P554 | `pit_annual_return_pit28` | ✅ | — | |
| P556 | `pit_annual_return_deadlines` | ✅ | — | |
| P559 | `pit_annual_correction` | ✅ | — | |

### Grupa 8: PIT — KUP (P560-P589)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P560 | `kup_full_deductible` | ✅ | — | |
| P561 | `kup_zus_social_deductible` | ✅ | — | |
| P562 | `kup_private_mixed_jdg` | ✅ | — | Reguła GŁÓWNA — deleguje do P850 dla home office |
| P564 | `kup_car_over_150k_limit` | ✅ | — | |
| P566 | `kup_representation_none` | ✅ | — | |
| P568 | `kup_unpaid_zus_social` | ✅ | — | |
| P570 | `kup_health_contrib_linear_deduction` | ✅ | — | |
| P572 | `kup_loss_carry_forward` | ✅ | — | |
| P574 | `kup_donation_deduction` | ✅ | — | |
| P578 | `kup_own_work_nkup` | ✅ | — | |
| P578_b | `kup_spouse_contract_kup` | ✅ | — | |
| P579 | `kup_professional_chamber_fees` | ✅ | — | |
| P580 | `kup_contractual_penalties_nkup` | ✅ | — | |
| P581 | `kup_workwear_vs_suit_bhp` | ✅ | — | |
| P582 | `kup_abandoned_spoiled_goods` | ✅ | — | |
| P584 | `kup_bad_debt_pit` | ✅ | — | |
| P586 | `kup_inventory_writeoff` | ✅ | — | |
| P589 | `kup_mixed_private_proportion` | ✅ | — | |

### Grupa 9: PIT — Zwolnienia (P580-P588 — część)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P580 | `pit_exemption_young` | ✅ | — | PIT-0 młodzi <26 |
| P582 | `pit_exemption_return` | ✅ | — | PIT-0 powrót |
| P584 | `pit_exemption_family_4plus` | ✅ | — | PIT-0 4+ |
| P586 | `pit_exemption_working_senior` | ✅ | — | PIT-0 senior |

### Grupa 10: Ulgi podatkowe (P600-P635)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P600 | `relief_rd_jdg` | ✅ | — | Ulga B+R |
| P601 | `relief_prototype_jdg` | ✅ | — | |
| P602 | `relief_robotization_jdg` | ✅ | — | |
| P609 | `relief_expansion` | ✅ | — | |
| P610 | `relief_ip_box_jdg` | ✅ | — | IP Box 5% |
| P615 | `loss_carry_forward_jdg` | ✅ | — | |
| P616 | `relief_joint_allowances_limit` | ✅ | — | |
| P619 | `relief_donation_opp` | ✅ | — | |
| P620 | `relief_rehabilitation` | ✅ | — | |
| P621 | `relief_internet` | ✅ | — | |
| P622 | `relief_child_tax_credit` | ✅ | — | |
| P623 | `relief_thermo_jdg` | ✅ | — | |
| P624 | `relief_ikze` | ✅ | — | |
| P625 | `relief_donation_church` | ✅ | — | |
| P626 | `relief_donation_blood` | ✅ | — | |
| P628 | `relief_rd_centrum_200pct` | ✅ | — | |
| P630 | `crypto_income_classification` | ✅ | — | |

### Grupa 11: ZUS (P700-P770)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P700 | `zus_social_standard_jdg` | ✅ | — | |
| P701 | `zus_sickness_voluntary_jdg` | 🔴 | R0346 (Doc 28a) | Doc 28a bardziej szczegółowa |
| P719 | `zus_base_calculation` | ✅ | — | |
| P720 | `zus_health_scale_jdg` | ✅ | — | 9% skala, NIE odlicza się |
| P722 | `zus_health_linear_jdg` | ✅ | — | 4.9% liniowy |
| P724 | `zus_health_lump_sum_jdg` | ✅ | — | Progi ryczałtowe (60k/300k) |
| P739 | `zus_health_summary` | ✅ | — | |
| P740 | `zus_start_relief_jdg` | ✅ | — | Ulga na start 6 mies. |
| P741 | `zus_maly_plus_jdg` | ✅ | — | Mały ZUS Plus 36 mies. |
| P742 | `zus_preferential_jdg` | ✅ | — | Preferencyjny ZUS 24 mies. |
| P743 | `concurrent_employment_exemption` | ✅ | — | |
| P746 | `zus_health_annual_reconciliation` | ✅ | — | |
| P748 | `zus_health_minimum_base` | ✅ | — | |
| P749 | `lump_sum_health_annual_reconciliation` | ✅ | — | |
| P750 | `linear_tax_annual_health_reconciliation` | ✅ | — | |
| P760 | `zus_sickness_benefit_jdg` | ✅ | — | |

### Grupa 12: Księgowość (P800-P870)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P800 | `pkpir_column_mapping` | 🔴 | R0372-R0399 (Doc 28a) | 16 kolumn PKPiR — Doc 28a bardziej szczegółowy |
| P801 | `pkpir_revenue_recognition` | 🔴 | R0372-R0399 (Doc 28a) | |
| P802 | `pkpir_expense_recognition` | 🔴 | R0372-R0399 (Doc 28a) | |
| P810 | `pkpir_revenue_recognition_detailed` | ✅ | — | |
| P819 | `pkpir_summary` | ✅ | — | |
| P820 | `lump_sum_evidence_entry` | ✅ | — | |
| P829 | `lump_sum_summary` | ✅ | — | |
| P830 | `vat_evidence_purchase` | ✅ | — | |
| P832 | `vat_evidence_sale` | ✅ | — | |
| P839 | `vat_evidence_summary` | ✅ | — | |
| P840 | `depreciation_linear_jdg` | 🔴 | R0379-R0389 (Doc 28a) | Doc 28a bardziej kompletny |
| P841 | `depreciation_declining_jdg` | 🔴 | R0379-R0389 (Doc 28a) | Doc 28a bardziej kompletny |
| P842 | `depreciation_one_off_jdg` | 🔴 | R0379-R0389 (Doc 28a) | |
| P845 | `one_off_depreciation_de_minimis` | ✅ | — | |
| P847 | `real_estate_residential_depreciation_ban` | ✅ | — | |
| P849 | `depreciation_summary` | ✅ | — | |
| P850 | `private_mixed_home_office` | ✅ | — | Reguła SZCZEGÓŁOWA — delegowana z P562 |
| P852 | `private_mixed_car` | ✅ | — | |
| P859 | `mixed_expenses_summary` | ✅ | — | |
| P870 | `fx_differences_recognition` | ✅ | — | |
| P870a | `pit_loss_carry_forward_one_time_5m` | ✅ | — | |

### Grupa 13: Cykl życia JDG (P900-P939)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P900 | `ceidg_registration_check` | ✅ | — | |
| P902 | `ceidg_data_change_notification` | ✅ | — | |
| P904 | `ceidg_status_check` | ✅ | — | |
| P909 | `ceidg_summary` | ✅ | — | |
| P910 | `business_suspension_valid` | ✅ | — | |
| P912 | `business_suspension_kup_restrictions` | ✅ | — | |
| P914 | `business_suspension_zus` | 🔴 | R0582 (Doc 28a) | ⚠️ BŁĘDNA — poprawiona w Doc 28a (zdrowotna NADAL należna!) |
| P919 | `suspension_vat_declaration_zero` | ✅ | — | |
| P920 | `succession_continuity` | ✅ | — | |
| P922 | `succession_tax_obligations` | ✅ | — | |
| P924 | `succession_inheritance` | ✅ | — | |
| P925 | `succession_spouse` | ✅ | — | |
| P927 | `succession_children` | ✅ | — | |
| P928 | `succession_inventory_obligation` | ✅ | — | |
| P929 | `succession_summary` | ✅ | — | |
| P930 | `unregistered_activity_limit` | ✅ | — | |
| P932 | `unregistered_activity_zus_exemption` | ✅ | — | |
| P934 | `unregistered_activity_taxation` | ✅ | — | |
| P939 | `business_lifecycle_summary` | ✅ | — | |

### Grupa 14: KSeF i JPK (P950-P989)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P950 | `ksef_structured_mandatory_jdg` | ✅ | — | |
| P952 | `ksef_b2c_exemption_jdg` | ✅ | — | |
| P953 | `ksef_attachment_size_limit` | ✅ | — | |
| P959 | `ksef_summary` | ✅ | — | |
| P960 | `jpk_v7_structure` | ✅ | — | |
| P969 | `jpk_v7_summary` | ✅ | — | |
| P970 | `jpk_v7m_structure_jdg` | ✅ | — | |
| P974 | `jpk_v7_gtu_obligation_check` | ✅ | — | |
| P979 | `jpk_v7_summary` | ✅ | — | |
| P980 | `jpk_pkpir_structure_jdg` | ✅ | — | |
| P989 | `jpk_pkpir_summary` | ✅ | — | |

### Grupa 15: Retencja i Fallback (P990-P1099)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P990 | `retention_invoice_5y` | ✅ | — | |
| P992 | `retention_pkpir_5y` | ✅ | — | |
| P999 | `retention_summary` | ✅ | — | |
| P1000 | `domestic_fallback_jdg` | ✅ | — | Domyślna stawka 23% VAT |
| P1099 | `no_match_jdg` | ✅ | — | Zawsze na końcu łańcucha |

### Grupa 16: Korekty (P1100-P1120) — z Doc 22

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P1100 | `correction_invoice_in_minus` | ✅ | — | |
| P1104 | `vat_declaration_correction` | ✅ | — | |
| P1115 | `correction_storno_red_detection` | ✅ | — | |
| P1116 | `correction_storno_black_detection` | ✅ | — | |

### Grupa 17: Przedawnienia i odpowiedzialność (P1150-P1174) — z Doc 22

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P1150 | `tax_statute_of_limitations_5y` | ✅ | — | |
| P1153 | `statute_suspension` | ✅ | — | |
| P1157 | `statute_interruption` | ✅ | — | |
| P1158 | `entrepreneur_personal_liability` | ✅ | — | |
| P1164 | `late_payment_interest_calculation` | ✅ | — | |
| P1167 | `interest_rate_determination` | ✅ | — | |
| P1168 | `voluntary_disclosure_active` | ✅ | — | |
| P1172 | `liability_summary` | ✅ | — | |
| P1174 | `tax_audit_procedures` | ✅ | — | |

### Grupa 18: Podatki lokalne (P1300-P1320)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P1300 | `pcc_mandatory_purchase_from_private` | ✅ | — | |
| P1310 | `real_estate_commercial_rate` | ✅ | — | |
| P1320 | `transport_tax_applicable` | ✅ | — | |

### Grupa 19: Międzynarodowe (P100-P117)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P100 | `wht_obligation_detection` | ✅ | — | |
| P110 | `permanent_establishment_risk` | ✅ | — | |
| P114 | `tp_documentation_threshold` | ✅ | — | |

### Grupa 20: Pozostałe (P1400-P1612)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P1200e | `employer_obligation_detection` | ✅ | — | |
| P1202e | `payroll_tax_advance_obligation` | ✅ | — | |
| P1205 | `employer_zus_obligations` | ✅ | — | |
| P1208e | `ppk_obligation_check` | ✅ | — | |
| P1210e | `small_mandate_flat_tax` | ✅ | — | |
| P1220 | `copyright_transfer_50_kup` | ✅ | — | |
| P1400 | `bdo_registration_check` | ✅ | — | |
| P1405 | `kobize_emission_report` | ✅ | — | |
| P1500 | `jdg_to_company_conversion_detection` | ✅ | — | |
| P1502 | `conversion_closing_inventory` | ✅ | — | |
| P1600 | `rmk_temporal_rule` | ✅ | — | |

---

## 📋 CZĘŚĆ II: DOC 23 — 122 P-ID (94 aktywnych, 28 zdeprecjonowanych)

### Grupa zdeduplkowana: Crossborder kanoniczne (P43-P49, P190-P191, P232)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P43 | `crossborder_detailed` | ✅ | — | Kanoniczne — zastępuje P40 (Doc 22) |
| P44 | `crossborder_detailed` | ✅ | — | Kanoniczne — zastępuje P41 (Doc 22) |
| P46 | `crossborder_detailed` | ✅ | — | Kanoniczne — zastępuje P42 (Doc 22) |
| P47 | `crossborder_detailed` | ✅ | — | Kanoniczne — zastępuje P45 (Doc 22) |
| P49 | `crossborder_detailed` | ✅ | — | Kanoniczne — zastępuje P48 (Doc 22) |
| P190 | `crossborder_vat` | ✅ | — | Kanoniczne z Doc 23 |
| P191 | `crossborder_vat` | ✅ | — | Kanoniczne z Doc 23 |
| P232 | `vat_ue_summary` | ✅ | — | Kanoniczne z Doc 23 |

### Grupa zdeduplkowana: VAT szczegółowy (P58-P63)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P58 | `vat_exemption_subject_jdg` | ✅ | — | 🔑 Kanoniczne (z Doc 22) |
| P59 | `subject_exemption_startup_proportion` | 🔴 | P58 (rozszerzona) | Wchłonięta jako edge case w P58 |
| P61 | `vat_exemption_financial` | ✅ | — | |
| P62 | `vat_exemption_insurance` | ✅ | — | |
| P63 | `vat_exemption_other` | ✅ | — | |
| P185 | `vat_pre_proportion_mixed` | ✅ | — | |
| P186 | `vat_deduction_proportion` | ✅ | — | |
| P187 | `vat_deduction_full` | ✅ | — | |
| P188 | `vat_deduction_blocked` | ✅ | — | |
| P189 | `bad_debt_relief_creditor` | ✅ | — | ⚠️ Wymaga poprawy: 150 dni (nie 90) |

### Grupa: PIT rozszerzenia (P500-P599)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P500 | `pit_form_scale_extended` | ✅ | — | |
| P502 | `pit_scale_details` | ✅ | — | |
| P510 | `pit_form_linear_extended` | ✅ | — | |
| P511 | `pit_linear_details` | ✅ | — | |
| P520 | `pit_form_lump_sum_extended` | ✅ | — | |
| P523 | `lump_sum_details` | ✅ | — | |
| P530 | `pit_form_tax_card_extended` | ✅ | — | |
| P531 | `tax_card_details` | ✅ | — | |
| P540 | `pit_advance_details` | ✅ | — | |
| P543 | `pit_advance_quarterly_details` | ✅ | — | |
| P550 | `pit_annual_details` | ✅ | — | |
| P556 | `pit_deadlines` | ✅ | — | |
| P560 | `kup_details` | ✅ | — | |
| P570 | `kup_health_details` | ✅ | — | |
| P580 | `pit_exemption_young_extended` | ✅ | — | |
| P586 | `pit_exemption_senior_extended` | ✅ | — | |
| P588 | `pit_exemption_interactions` | ✅ | — | |
| P590 | `change_scale_to_linear` | ✅ | — | |
| P591 | `change_linear_to_lump_sum` | ✅ | — | |
| P592 | `change_lump_sum_to_scale` | ✅ | — | |
| P593 | `mid_year_change_restriction` | ✅ | — | |
| P594 | `tax_consequences_form_change` | ✅ | — | |
| P595 | `inventory_remeasurement_change` | ✅ | — | |
| P596 | `zus_health_recalculation_change` | ✅ | — | |
| P599 | `tax_form_change_summary` | ✅ | — | |

### Grupa: Ulgi rozszerzenia (P600-P623)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P600 | `relief_rd_detailed` | ✅ | — | |
| P601 | `relief_prototype_detailed` | ✅ | — | |
| P602 | `relief_robotization_detailed` | ✅ | — | |
| P603 | `relief_expansion_detailed` | ✅ | — | |
| P604 | `relief_donation_detailed` | ✅ | — | |
| P605 | `relief_rehabilitation_detailed` | ✅ | — | |
| P606 | `relief_internet_detailed` | ✅ | — | |
| P607 | `relief_child_detailed` | ✅ | — | |
| P608 | `relief_thermo_detailed` | ✅ | — | |
| P609 | `relief_ikze_detailed` | ✅ | — | |
| P610 | `ip_box_detailed` | ✅ | — | |
| P615 | `loss_carry_forward_detailed` | ✅ | — | |
| P623 | `relief_thermo_detailed` | ✅ | — | |

### Grupa: ZUS interakcje (P700-P739) — 🔴 3 zdeprecjonowane

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P700 | `zus_social_extended` | ✅ | — | |
| P701 | `zus_sickness_extended` | ✅ | — | |
| P720 | `zus_health_scale_extended` | ✅ | — | |
| P722 | `zus_health_linear_extended` | ✅ | — | |
| P724 | `zus_health_lump_sum_extended` | ✅ | — | |
| P730 | `health_contribution_rate_matrix` | 🔧 | P720/P722/P724/P736 | Helper/macierz, nie reguła decyzyjna |
| P732 | `zus_form_interaction` | ✅ | — | |
| P734 | `lump_sum_health_tier_lockstep` | 🔴 | P724 (rozszerzona) | Wchłonięta jako edge case w P724 |
| P736 | `zus_health_cross_form` | ✅ | — | |
| P738 | `scale_health_deduction_prohibition` | 🔴 | P720 | Całkowicie redundantna |
| P739 | `zus_interactions_summary` | ✅ | — | |
| P740 | `zus_start_relief_extended` | ✅ | — | |
| P741 | `zus_maly_plus_extended` | ✅ | — | |
| P742 | `zus_preferential_extended` | ✅ | — | |

### Grupa: Księgowość rozszerzenia (P800-P869)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P800 | `pkpir_extended` | ✅ | — | |
| P802 | `pkpir_expense_extended` | ✅ | — | |
| P820 | `lump_sum_evidence_extended` | ✅ | — | |
| P830 | `vat_evidence_extended` | ✅ | — | |
| P832 | `vat_sale_extended` | ✅ | — | |
| P840 | `depreciation_extended` | ✅ | — | |
| P842 | `depreciation_one_off_extended` | ✅ | — | |
| P850 | `home_office_extended` | ✅ | — | |
| P852 | `car_mixed_extended` | ✅ | — | |
| P860 | `operating_lease_full_kup` | ✅ | — | 🔑 Kanoniczne dla leasingu — wygrywa z R0390-R0391 |
| P862 | `financial_lease_interest_kup` | ✅ | — | 🔑 Kanoniczne dla leasingu |
| P864 | `lease_operating_details` | ✅ | — | |
| P866 | `lease_financial_details` | ✅ | — | |
| P868 | `lease_mixed_details` | ✅ | — | |
| P869 | `lease_summary` | ✅ | — | |

### Grupa: Korekty — 🔴 8 zdeprecjonowanych (P1100-P1114)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P1100 | `correction_invoice_in_minus` | 🔴 | R0420-R0435 (Doc 28a) | Doc 28a — 16 reguł vs 8 |
| P1102 | `correction_invoice_in_plus` | 🔴 | R0420-R0435 (Doc 28a) | |
| P1104 | `vat_declaration_correction` | 🔴 | R0420-R0435 (Doc 28a) | |
| P1106 | `correction_jpk_v7` | 🔴 | R0420-R0435 (Doc 28a) | |
| P1108 | `correction_statute_limits` | 🔴 | R0420-R0435 (Doc 28a) | |
| P1110 | `correction_interest` | 🔴 | R0420-R0435 (Doc 28a) | |
| P1112 | `correction_procedure` | 🔴 | R0420-R0435 (Doc 28a) | |
| P1114 | `correction_summary` | 🔴 | R0420-R0435 (Doc 28a) | |

### Grupa: Przedawnienia — 🔴 9 zdeprecjonowanych (P1150-P1166)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P1150 | `statute_5y` | 🔴 | R0436-R0449 (Doc 28a) | Doc 28a — 14 reguł vs 9 |
| P1152 | `statute_suspension` | 🔴 | R0436-R0449 (Doc 28a) | |
| P1154 | `statute_interruption` | 🔴 | R0436-R0449 (Doc 28a) | |
| P1156 | `statute_criminal` | 🔴 | R0436-R0449 (Doc 28a) | |
| P1158 | `personal_liability` | 🔴 | R0436-R0449 (Doc 28a) | |
| P1160 | `liability_third_party` | 🔴 | R0436-R0449 (Doc 28a) | |
| P1162 | `interest_calculation` | 🔴 | R0436-R0449 (Doc 28a) | |
| P1164 | `interest_rates` | 🔴 | R0436-R0449 (Doc 28a) | |
| P1166 | `liability_summary` | 🔴 | R0436-R0449 (Doc 28a) | |

### Grupa: Reprezentacja — 🔴 7 zdeprecjonowanych (P1200-P1212)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| P1200 | `poa_pps1_general` | 🔴 | R0450-R0459 (Doc 28a) | Doc 28a — 10 reguł vs 7 |
| P1202 | `poa_upl1_specific` | 🔴 | R0450-R0459 (Doc 28a) | |
| P1204 | `poa_procuration` | 🔴 | R0450-R0459 (Doc 28a) | |
| P1206 | `poa_limits` | 🔴 | R0450-R0459 (Doc 28a) | |
| P1208 | `poa_termination` | 🔴 | R0450-R0459 (Doc 28a) | |
| P1210 | `poa_succession` | 🔴 | R0450-R0459 (Doc 28a) | |
| P1212 | `poa_summary` | 🔴 | R0450-R0459 (Doc 28a) | |

---

## 📋 CZĘŚĆ III: DOC 28A — ~254 R-ID (50+ kluczowych grup, 2 zdeprecjonowane)

### Grupa: Księgowość ENTERPRISE (R0372-R0399) — 🔑 28 reguł kanonicznych

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| R0372 | `pkpir_format_16_columns` | ✅ | — | Kanoniczne — zastępuje P800-P802 |
| R0373-R0378 | `pkpir_column_rules` | ✅ | — | 6 reguł szczegółowych PKPiR |
| R0379 | `depreciation_linear` | ✅ | — | Kanoniczne — zastępuje P840-P842 |
| R0380-R0388 | `depreciation_rules` | ✅ | — | 9 reguł szczegółowych amortyzacji |
| R0389 | `depreciation_sale_consequences` | ✅ | — | |
| R0390 | `lease_operating_basic` | 🔴 | P860-P868 (Doc 23) | Doc 23 ma 5 reguł vs 2 |
| R0391 | `lease_financial_basic` | 🔴 | P860-P868 (Doc 23) | Doc 23 ma 5 reguł vs 2 |
| R0392-R0399 | `car_mileage_log_75pct` + inne | ✅ | — | 8 reguł szczegółowych |

### Grupa: Korekty ENTERPRISE (R0420-R0435) — 🔑 16 reguł kanonicznych

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| R0420 | `correction_invoice_in_minus` | ✅ | — | Kanoniczne — zastępuje P1100-P1114 |
| R0421 | `correction_invoice_in_plus` | ✅ | — | |
| R0422-R0427 | `correction_rules` | ✅ | — | 6 reguł szczegółowych |
| R0428 | `correction_declaration` | ✅ | — | |
| R0429-R0434 | `correction_rules` | ✅ | — | 6 reguł szczegółowych |
| R0435 | `correction_invoice_numbering_continuity` | ✅ | — | |

### Grupa: Przedawnienia ENTERPRISE (R0436-R0449) — 🔑 14 reguł kanonicznych

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| R0436 | `statute_of_limitations_5_years` | ✅ | — | Kanoniczne — zastępuje P1150-P1166 |
| R0437 | `statute_of_limitations_10_years` | ✅ | — | |
| R0438-R0443 | `statute_rules` | ✅ | — | 6 reguł szczegółowych |
| R0444-R0448 | `liability_rules` | ✅ | — | 5 reguł szczegółowych |
| R0449 | `tax_audit_extended_inspection_30_60_days` | ✅ | — | |

### Grupa: Reprezentacja ENTERPRISE (R0450-R0459) — 🔑 10 reguł kanonicznych

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| R0450 | `poa_pps1_general_tax` | ✅ | — | Kanoniczne — zastępuje P1200-P1212 |
| R0451 | `poa_upl1_specific_case` | ✅ | — | |
| R0452-R0458 | `poa_rules` | ✅ | — | 7 reguł szczegółowych |
| R0459 | `joint_procuration_required` | ✅ | — | |

### Grupa: ZUS ENTERPRISE (R0346, R0582)

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| R0346 | `zus_sickness_voluntary` | ✅ | — | Kanoniczne — zastępuje P701 |
| R0582 | `edge_zus_declaration_zero_on_suspension` | ✅ | — | 🔑 POPRAWNA reguła zawieszenia — zastępuje P914 |

### Grupa: VAT Edge Cases (R0546-R0559) — 🔑 14 reguł edge case

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| R0546 | `edge_vat_breach_mid_year` | ✅ | — | Edge case: przekroczenie limitu w trakcie roku |
| R0547 | `edge_vat_breach_proportion_new_jdg` | ✅ | — | Edge case: proporcjonalny limit dla nowych JDG |
| R0548-R0559 | `edge_vat_*` | ✅ | — | 12 reguł edge case VAT — w `else` po P58 |

### Grupa: PIT Edge Cases (R0560-R0573) — 14 reguł

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| R0560-R0573 | `edge_pit_*` | ✅ | — | Edge cases PIT: pierwszy rok, ostatni rok, podwójne opodatkowanie |

### Grupa: ZUS Edge Cases (R0574-R0585) — 12 reguł

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| R0574-R0585 | `edge_zus_*` | ✅ | — | Edge cases ZUS: przejścia między ulgami, wyczerpanie okresów |

### Grupa: Konflikty (R0586-R0612) — 27 reguł

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| R0586-R0612 | `conflict_*` | ✅ | — | Konflikty: IP Box vs B+R, ulgi vs dochód, forma vs składka |

### Grupa: Walidacja (R0613-R0622) — 10 reguł

| ID | Nazwa reguły | Status | Zastąpiona przez | Uwagi |
|:--:|-------------|:------:|-------------------|-------|
| R0613-R0622 | `validation_*` | ✅ | — | Walidacja: NIP checksum, ciągłość numeracji faktur |

---

## 📋 CZĘŚĆ IV: DOC 42 — DEEP GAP DISCOVERY (55 reguł) ℹ️

> **Uwaga:** Szczegółowe opisy tych reguł znajdują się w `42_JDG_DEEP_GAP_DISCOVERY.md`. Poniżej tylko mapowanie P-ID.

### Grupa 21: VAT — Obniżone stawki (P66-P72) — 6 reguł
| ID | Nazwa | Status |
|:--:|-------|:------:|
| P66 | `vat_reduced_rate_8pct_food_validation` | ✅ |
| P67 | `vat_reduced_rate_5pct_books_validation` | ✅ |
| P68 | `vat_rate_8pct_construction_residential_validation` | ✅ |
| P70 | `vat_rate_8pct_medical_equipment_validation` | ✅ |
| P71 | `vat_rate_5pct_baby_products_validation` | ✅ |
| P72 | `vat_reduced_rate_cross_check_thresholds` | ✅ |

### Grupa 22: KKS — Reguły szczegółowe (P130-P141_b) — 12 reguł
| ID | Nazwa | Status |
|:--:|-------|:------:|
| P130 | `kks_unreliable_pkpir_columns_art56` | ✅ |
| P131 | `kks_unreliable_vat_evidence_art57` | ✅ |
| P132 | `kks_empty_invoice_issuance_art62` | ✅ |
| P133 | `kks_wrong_vat_rate_art64` | ✅ |
| P134 | `kks_tax_return_non_filing_art77` | ✅ |
| P135 | `kks_non_payment_of_tax_art79` | ✅ |
| P136 | `kks_destruction_of_documents_art68` | ✅ |
| P137 | `kks_voluntary_disclosure_art16` | ✅ |
| P138 | `kks_statute_of_limitations_criminal_art44` | ✅ |
| P139 | `kks_fiscal_penalty_calculation` | ✅ |
| P140_b | `kks_obstruction_of_tax_audit_art69` | ✅ |
| P141_b | `kks_aggregate_risk_score` | ✅ |

### Grupa 23: PKPiR — Walidacja kolumn (P811-P818) — 8 reguł
| ID | Nazwa | Status |
|:--:|-------|:------:|
| P811 | `pkpir_column_1_lp_validation` | ✅ |
| P812 | `pkpir_column_2_date_validation` | ✅ |
| P813 | `pkpir_column_6_and_7_kup_direct_indirect` | ✅ |
| P814 | `pkpir_column_8_purchase_of_goods_and_materials` | ✅ |
| P815 | `pkpir_column_14_remarks_mandatory_check` | ✅ |
| P816 | `pkpir_remanent_start_end_consistency` | ✅ |
| P817 | `pkpir_evidence_storage_5_years` | ✅ |
| P818 | `pkpir_income_calculation_from_columns` | ✅ |

### Grupa 24: ZUS — Zasiłki (P1200zs-P1206zs) — 7 reguł
| ID | Nazwa | Status |
|:--:|-------|:------:|
| P1200zs | `zus_sickness_benefit_eligibility_jdg` | ✅ |
| P1201zs | `zus_sickness_benefit_amount_jdg` | ✅ |
| P1202zs | `zus_maternity_benefit_jdg` | ✅ |
| P1203zs | `zus_care_benefit_jdg` | ✅ |
| P1204zs | `zus_rehabilitation_benefit_jdg` | ✅ |
| P1205zs | `zus_benefit_payment_deadline` | ✅ |
| P1206zs | `zus_benefit_overpayment_detection` | ✅ |

### Grupa 25: ZUS — Składki MPiPS (P770-P773) — 4 reguły
| ID | Nazwa | Status |
|:--:|-------|:------:|
| P770 | `zus_contribution_base_calculation_jdg` | ✅ |
| P771 | `zus_contribution_split_by_fund_jdg` | ✅ |
| P772 | `zus_contribution_deadline_jdg` | ✅ |
| P773 | `zus_contribution_payment_verification` | ✅ |

### Grupa 26: KŚT — Amortyzacja (P880-P884) — 5 reguł
| ID | Nazwa | Status |
|:--:|-------|:------:|
| P880 | `kst_group_classification` | ✅ |
| P881 | `kst_depreciation_rate_assignment` | ✅ |
| P882 | `kst_intangible_assets_classification` | ✅ |
| P883 | `kst_one_time_depreciation_eligibility` | ✅ |
| P884 | `kst_improvement_threshold_check` | ✅ |

### Grupa 27: UoR — Inwentaryzacja i wycena (P875-P879) — 5 reguł
| ID | Nazwa | Status |
|:--:|-------|:------:|
| P875 | `uor_inventory_obligation_art26` | ✅ |
| P876 | `uor_asset_valuation_art28` | ✅ |
| P877 | `uor_accruals_deferrals_art39` | ✅ |
| P878 | `uor_financial_statement_art45` | ✅ |
| P879 | `uor_document_storage_art74` | ✅ |

### Grupa 28: RODO (P1610-P1613) — 4 reguły
| ID | Nazwa | Status |
|:--:|-------|:------:|
| P1610 | `rodo_dpa_registration_check_jdg` | ✅ |
| P1611 | `rodo_data_breach_notification_jdg` | ✅ |
| P1612 | `rodo_data_retention_policy_jdg` | ✅ |
| P1613 | `rodo_dpo_requirement_jdg` | ✅ |

### Grupa 29: PCC — Stawki szczegółowe (P1301-P1304) — 4 reguły
| ID | Nazwa | Status |
|:--:|-------|:------:|
| P1301 | `pcc_loan_from_private_person` | ✅ |
| P1302 | `pcc_car_purchase_from_private_2pct` | ✅ |
| P1303 | `pcc_real_estate_purchase_from_private` | ✅ |
| P1304 | `pcc_aggregate_liability_check` | ✅ |

---

## 📋 CZĘŚĆ V: DOC 43 — KKS MASSIVE DECOMPOSITION (230 reguł) ℹ️

> **Uwaga:** Szczegółowe opisy tych reguł znajdują się w `43_JDG_KKS_MASSIVE_DECOMPOSITION.md`. Poniżej tylko mapowanie P-ID.

### Grupa 30: KKS — Czynny żal i przedawnienie (P200-P229) — 30 reguł
| Zakres ID | Opis grupy | Status |
|:---------:|------------|:------:|
| P200-P209 | Art. 16 KKS — Czynny żal (10 reguł) | ✅ |
| P210-P215 | Art. 17-19 KKS — Nadzwyczajne złagodzenie (6 reguł) | ✅ |
| P220-P229 | Art. 20-21 KKS — Przedawnienie karalności (10 reguł) | ✅ |

### Grupa 31: KKS — Przestępstwa dochodowe (P240-P319) — 55 reguł
| Zakres ID | Opis grupy | Status |
|:---------:|------------|:------:|
| P240-P254 | Art. 54 KKS — Uchylanie się od opodatkowania (15 reguł) | ✅ |
| P255-P269 | Art. 56 KKS — Nierzetelne księgi/PKPiR (15 reguł) | ✅ |
| P270-P279 | Art. 57 KKS — Nierzetelna ewidencja VAT (10 reguł) | ✅ |
| P280-P294 | Art. 58-61 KKS — Pozostałe przestępstwa dochodowe (15 reguł) | ✅ |

### Grupa 32: KKS — VAT i faktury (P300-P364) — 55 reguł
| Zakres ID | Opis grupy | Status |
|:---------:|------------|:------:|
| P300-P319 | Art. 62 KKS — Puste faktury / fałszerstwo (20 reguł) | ✅ |
| P320-P329 | Art. 63 KKS — Niewystawienie faktury (10 reguł) | ✅ |
| P330-P339 | Art. 64-67 KKS — Stawki i zwrot VAT (10 reguł) | ✅ |
| P340-P354 | Art. 68-76 KKS — Zniszczenie, utrudnianie (15 reguł) | ✅ |

### Grupa 33: KKS — Wykroczenia skarbowe (P400-P459) — 60 reguł
| Zakres ID | Opis grupy | Status |
|:---------:|------------|:------:|
| P400-P409 | Art. 77 KKS — Niezłożenie deklaracji (10 reguł) | ✅ |
| P410-P419 | Art. 78-79 KKS — Nieprawidłowe dane i niezapłacenie (10 reguł) | ✅ |
| P420-P429 | Art. 80-83 KKS — Sankcje za wykroczenia (10 reguł) | ✅ |
| P430-P439 | Agregacja ryzyka KKS (10 reguł) | ✅ |
| P440-P459 | Dokumentacja, audyt i compliance (20 reguł) | ✅ |

### Grupa 34: KKS — Sankcje ogólne (P490-P499) — 10 reguł
| Zakres ID | Opis grupy | Status |
|:---------:|------------|:------:|
| P490-P499 | Art. 23-30 KKS — Stawki dzienne, grzywny, przepadek, probacja | ✅ |

---

## 📊 PODSUMOWANIE STATYSTYCZNE

### Według dokumentu źródłowego (v2.0 — po integracji Doc 42 i Doc 43)

| Dokument | P-ID / R-ID | Aktywne | 🔴 Deprecated | Kanoniczny udział |
|----------|:-----------:|:-------:|:------------:|:-----------------:|
| **22_JDG_ENTERPRISE_PLAN.md** | 167 P-ID | 150 | 17 | 19% |
| **23_JDG_EXPANSION_SUPPLEMENT.md** | 122 P-ID | 94 | 28 | 12% |
| **28a_JDG_EDGE_CASES_FULL.md** | ~254 R-ID | 50+ kluczowych | 2 | 6% |
| **42_JDG_DEEP_GAP_DISCOVERY.md** | 55 P-ID | 55 | 0 | 7% |
| **43_JDG_KKS_MASSIVE_DECOMPOSITION.md** | 230 P-ID | 230 | 0 | 29% |
| **Pozostałe R-ID (28a)** | ~200 R-ID | ~200 | 0 | 25% |
| **ŁĄCZNIE** | ~1,028 identyfikatorów | **~779 unikalnych** | **47** | **100%** |

### Według domeny prawnej

| Domena | Aktywne | Deprecated | Kluczowe grupy |
|--------|:-------:|:----------:|----------------|
| Risk & Fraud | 12 | 0 | P0-P9 |
| Routing & Confidence | 7 | 0 | P10-P19 |
| Compliance | 17 | 0 | P20-P39, P140-P157 |
| Crossborder | 8 | 5 | P40-P49 → Doc 23 |
| VAT (stawki, zwolnienia, GTU) | 26 | 3 | P50-P72 + P230-P235 |
| VAT Edge Cases | 14 | 0 | R0546-R0559 |
| PIT (formy, KUP, zaliczki) | 55 | 0 | P500-P599 |
| PIT Edge Cases | 14 | 0 | R0560-R0573 |
| Ulgi podatkowe | 28 | 0 | P600-P635 |
| ZUS | 27 | 1 | P700-P773, P1200zs-P1206zs |
| ZUS Edge Cases | 12 | 0 | R0574-R0585 |
| Księgowość (PKPiR, amortyzacja) | 36 | 5 | P800-P870, P811-P818, P880-P884, P875-P879 → R0372-R0399 |
| Leasing | 5 | 2 | P860-P868 (wygrywa z R0390-R0391) |
| Cykl życia JDG | 20 | 1 | P900-P939 (P914 → R0582) |
| KSeF i JPK | 20 | 0 | P950-P989 |
| Korekty | 16 | 8 | R0420-R0435 (wygrywa z P1100-P1114) |
| Przedawnienia | 14 | 9 | R0436-R0449 (wygrywa z P1150-P1166) |
| Reprezentacja | 10 | 7 | R0450-R0459 (wygrywa z P1200-P1212) |
| Konflikty | 27 | 0 | R0586-R0612 |
| Walidacja | 10 | 0 | R0613-R0622 |
| Retencja i Fallback | 5 | 0 | P990-P1099 |
| KKS | 252 | 0 | P130-P141_b, P200-P459, P490-P499 |
| RODO | 4 | 0 | P1610-P1613 |
| PCC (szczegółowe) | 4 | 0 | P1301-P1304 |
| Pozostałe | 20 | 0 | P100-P117, P1200e-P1612 |

---

## 🔑 KLUCZOWE DECYZJE KANONICZNE

| # | Decyzja | Kanoniczne źródło | Uzasadnienie |
|---|---------|:-----------------:|--------------|
| 1 | **Crossborder** → Doc 23 | P43-P49, P190-P191, P232 | Doc 23 ma 8-12 linii na regułę vs 1-2 w Doc 22 |
| 2 | **VAT główny** → Doc 22 | P58 | P58 to reguła GŁÓWNA, R0546-R0559 to edge cases |
| 3 | **VAT bad debt** → Doc 23 | P189 | Bardziej szczegółowa (5 przesłanek vs 2) |
| 4 | **Księgowość** → Doc 28a | R0372-R0399 | 28 reguł vs 3 w Doc 22 |
| 5 | **Amortyzacja** → Doc 28a | R0379-R0389 | 11 reguł vs 3 w Doc 22 |
| 6 | **Leasing** → Doc 23 | P860-P868 | 5 reguł vs 2 w Doc 28a (wyjątek!) |
| 7 | **Korekty** → Doc 28a | R0420-R0435 | 16 reguł vs 8 w Doc 23 |
| 8 | **Przedawnienia** → Doc 28a | R0436-R0449 | 14 reguł vs 9 w Doc 23 |
| 9 | **Reprezentacja** → Doc 28a | R0450-R0459 | 10 reguł vs 7 w Doc 23 |
| 10 | **ZUS zawieszenie** → Doc 28a | R0582 | Poprawna prawnie (Art. 36a SUS) |
| 11 | **ZUS chorobowa** → Doc 28a | R0346 | Bardziej szczegółowa |

---

## 🚀 WDROŻONE ULEPSZENIA (z 29_JDG_STRATEGIC_IMPROVEMENTS.md)

### A1: Doc-as-Code METADATA — 32/32 plików (100%)

Wszystkie pliki `.rego` w `policies/jdg/` mają bloki `# METADATA` z polami:
`title`, `description`, `architecture`, `legal_basis`, `edge_cases`, `package`, `deprecated`.

**Pokrycie:** 32/32 plików — w tym 17 core domen (risk, routing, compliance, crossborder,
vat/*, pit/*, zus, business, accounting, allowances) i 15 supporting (corrections,
liability, representation, local_taxes, ksef_jpk, international, employer,
environmental, restructuring, temporal, digital, retention, fallback, pit/exemptions,
pit/transitions).

### A2: Temporal Bundle Routing

Struktura `policies/jdg/bundles/` z architekturą base + overlays:
- `base/manifest.json` — 32 pakiety JDG, OPA v0.60+
- `overlays/v2026/manifest.json` — 3 planowane zmiany na 2026
- `overlays/v2027/manifest.json` — placeholder
- `bundle.sh` — skrypt budujący bundle .tar.gz

### B2: Decoupled Thresholds

`input.thresholds` → `data.thresholds` w 5 plikach: `_helpers_jdg.rego`,
`business.rego`, `pit/forms.rego`, `risk.rego`, `zus.rego`.
Thresholdy ładowane przez OPA Data API, nie w każdym requeście.

### B3: Boundary Fuzz Testing

`tests/test_boundary_fuzz_auto.py` — 175 testów granicznych (Boundary Value Analysis)
dla 25 progów JDG: VAT exemption (200k), cash limit (15k), tax bracket (120k),
car KUP limit (150k/225k), lump sum tiers (60k/300k), ZUS reliefs (6/24/36 mies.),
bad debt days (90/150d), i 15 innych.

### C2: Temporal Action Queue

Pole `_future_events` w werdyktach OPA — 7 zdarzeń w 4 pakietach:
| Pakiet | Reguła | Zdarzenia |
|--------|--------|-----------|
| `business.rego` | P914 (zawieszenie) | `suspension_health_quarterly`, `suspension_end_reactivation` |
| `zus.rego` | P740-P743 (ulgi ZUS) | `start_relief_expiry`, `maly_plus_expiry`, `preferential_expiry`, `concurrent_employment_monitor` |
| `vat/deductions.rego` | P184 (bad debt dłużnik) | `bad_debt_debtor_vat_correction` (CRITICAL) |
| `pit/advances_returns.rego` | P556 (zeznanie roczne) | `annual_return_overdue` (CRITICAL) |

### Python Modules (nexus_ai/tax/)

7 modułów wspierających: `dynamic_dag.py`, `semantic_conflict_resolver.py`,
`boundary_fuzz_generator.py`, `what_if_arbitrage.py`, `temporal_action_queue.py`,
`legal_delta_agent.py`, `__init__.py`.

---

## 🚀 REKOMENDACJE

### Faza 1: UTRZYMANIE (ciągłe)
1. ⚠️ **Doc 23** — 28 reguł zdeprecjonowanych, ale Doc 23 wciąż zawiera rozszerzenia
   crossborder, leasingu i zmiany formy opodatkowania, które są kanonicznie aktywne.
2. **Doc 28a** — ~200 reguł R-ID (R0006-R0360, R0403-R0545, R0623-R1131)
   pozostaje do pełnego zmapowania w tym dokumencie.
3. **Nowe reguły** — każda nowa reguła musi być zarejestrowana w tym dokumencie (38c)
   z jednoznacznym statusem (✅/🔴/🔀/🔧).

### Faza 2: ROZWÓJ
4. Implementować tylko reguły oznaczone ✅ (AKTYWNA)
5. Reguły 🔴 pomijać — używać kanonicznych zamienników
6. Edge cases (R0546-R0622) implementować jako `else` bloki PO regulach głównych
7. Przy zmianach prawnych — aktualizować status i referencje

### Faza 3: DOKUMENTACJA
8. Ten dokument (`38c`) jest **definitywnym źródłem prawdy** dla mapowania ID
9. Wszystkie 32 pliki `.rego` mają teraz bloki `# METADATA` (zob. sekcję WDROŻONE ULEPSZENIA wyżej)
10. `29_JDG_STRATEGIC_IMPROVEMENTS.md` zawiera pełny status wszystkich 9 inicjatyw

---

> **🔥 WNIOSEK:** Z ~1,028 identyfikatorów we wszystkich dokumentach, **~779 to unikalne reguły kanoniczne** (wzrost z 294!).  
> **47 reguł jest zdeprecjonowanych** — 17 z Doc 22, 28 z Doc 23, 2 z Doc 28a.  
> **Doc 42** dodał 55 reguł w 9 nowych obszarach (PKPiR, obniżone stawki VAT, KKS szczegółowe, zasiłki, KŚT, RODO, MPiPS, UoR, PCC).  
> **Doc 43** dodał 230 reguł KKS — z ~5% do ~75% pokrycia (czynny żal, przestępstwa dochodowe, przestępstwa VAT, wykroczenia, sankcje).  
> **Doc 22** dostarcza reguły GŁÓWNE (PIT, VAT, ZUS, compliance).  
> **Doc 23** dostarcza ROZSZERZENIA (crossborder, leasing, zmiana formy).  
> **Doc 28a** dostarcza EDGE CASES i ENTERPRISE (księgowość, korekty, przedawnienia, reprezentacja, konflikty, walidacja).

---

*Wygenerowano przez NexusAI Canonical Map Engine v2.0*  
*Data: 2026-07-12*  
*Bazuje na: 38b_JDG_DEDUP_REPORT.md*  
*Zgodność: 22_JDG_ENTERPRISE_PLAN.md, 23_JDG_EXPANSION_SUPPLEMENT.md, 28a_JDG_EDGE_CASES_FULL.md, 42_JDG_DEEP_GAP_DISCOVERY.md, 43_JDG_KKS_MASSIVE_DECOMPOSITION.md*
