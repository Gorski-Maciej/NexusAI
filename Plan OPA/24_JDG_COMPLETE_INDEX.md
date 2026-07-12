# 📚 NexusAI JDG — Kompletny Indeks Reguł OPA/Rego ENTERPRISE

> **Status:** Master Index JDG v3.0 — zsynchronizowany z mapą kanoniczną 38c ⚠️  
> **Data:** 2026-07-12  
> **Plik:** `Plan OPA/24_JDG_COMPLETE_INDEX.md`  
> **⚠️ MAPA KANONICZNA:** `Plan OPA/38c_JDG_CANONICAL_MAP.md` — **definitywne źródło prawdy** (779 unikalnych reguł)  
> **Dokumenty źródłowe:**  
> — `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` — plan bazowy (~145 reguł)  
> — `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` — rozbudowa (~69 reguł)  
> — `Plan OPA/25_JDG_DEEP_LEGAL_AUDIT.md` — głęboki audyt prawny (46 luk)  
> — `Plan OPA/28a_JDG_EDGE_CASES_FULL.md` — edge cases ENTERPRISE (~254 R-ID)  
> — `Plan OPA/42_JDG_DEEP_GAP_DISCOVERY.md` — deep gaps (55 reguł)  
> — `Plan OPA/43_JDG_KKS_MASSIVE_DECOMPOSITION.md` — dekompozycja KKS (230 reguł)  
> — `Plan OPA/45_JDG_HYPER_GRANULARITY.md` — hyper-granularity (~700 R-ID)  
> — `Plan OPA/48_JDG_STRATEGIC_IMPROVEMENTS_V2.md` — 9 inicjatyw v2.0 (wdrożone ✅)  
> — `Plan OPA/49_JDG_IMPLEMENTATION_SUMMARY.md` — podsumowanie wdrożenia  
> — `Plan OPA/DocsJDG` — źródła prawne JDG  
> **Łącznie:** ~214 reguł (22+23) + ~779 kanonicznych (38c) | 🔴 47 zdeprecjonowanych | 28+ pakietów    

---

## Pokrycie 10+ Obszarów Rozbudowy (Status zsynchronizowany z 38c)

| # | Obszar | Dokumenty | Reguły kanoniczne | Status |
|---|--------|-----------|:------:|--------|
| 1 | Ulgi i odliczenia | 22+23+42 | 28 | ✅ PEŁNE (38c) |
| 2 | Składki ZUS i zdrowotne | 22+23+42 | 27 | ✅ PEŁNE (38c) |
| 3 | Zawieszenie i wznowienie | 22+28a (R0582 ✅) | 5+ | ✅ POPRAWIONE (38c: P914 🔴→R0582) |
| 4 | Sukcesja przedsiębiorstwa | 22 | 8 | ✅ PEŁNE |
| 5 | Zmiana formy opodatkowania | 23 | 8 | ✅ PEŁNE |
| 6 | Eksport i import usług | 22+23 (kanoniczne: Doc 23) | 8 | ✅ PEŁNE (38c: P40-P48 🔴→P43-P49) |
| 7 | Korekty deklaracji i faktur | 23+28a (kanoniczne: Doc 28a) | 16 | ✅ PEŁNE (38c: P1100-P1114 🔴→R0420-R0435) |
| 8 | Przedawnienia i odpowiedzialność | 23+28a (kanoniczne: Doc 28a) | 14 | ✅ PEŁNE (38c: P1150-P1166 🔴→R0436-R0449) |
| 9 | Reprezentacja i pełnomocnictwa | 23+28a (kanoniczne: Doc 28a) | 10 | ✅ PEŁNE (38c: P1200-P1212 🔴→R0450-R0459) |
| 10 | Interakcje forma↔składki | 23 (P730 🔧, P734/P738 🔴) | 4 | ✅ PEŁNE |
| 11 | KKS — przestępstwa i wykroczenia | 42+43 | 252 | ✅ NOWE (38c) |
| 12 | Głębokie luki (PKPiR, KŚT, RODO, PCC) | 42 | 55 | ✅ NOWE (38c) |
| 13 | Hyper-granularity (MDR, Danina, WIS, Kontrole) | 45 | ~700 R-ID | ✅ NOWE |

---

## Kompletny Spis Wszystkich Reguł JDG (posortowany priorytetem)

> ⚠️ **UWAGA:** Reguły oznaczone 🔴 **[DEPRECATED]** zostały zastąpione przez wersje kanoniczne w `38c_JDG_CANONICAL_MAP.md`.  
> Nie implementować reguł zdeprecjonowanych — używać wersji kanonicznych.
> Pełna lista deprecjacji: 17 z Doc 22 + 28 z Doc 23 + 2 z Doc 28a = **47 reguł zdeprecjonowanych**.

| Priorytet | rule_id | Pakiet | Dokument | Obszar | Status |
|:---------:|---------|--------|:--------:|--------|:------:|
| **P0** | `fraud_graph_match` | `jdg.risk` | 22 | Fraud |
| **P1** | `counterparty_trust_low` | `jdg.risk` | 22 | Risk |
| **P2** | `anomaly_amount` | `jdg.risk` | 22 | Risk |
| **P3** | `new_counterparty_flag` | `jdg.risk` | 22 | Risk |
| **P5** | `semantic_guard_disallowed` | `jdg.risk` | 22 | Risk |
| **P8** | `ceidg_vendor_suspended` | `jdg.risk` | 22 | Risk |
| **P10** | `fc_vat_rate_low_scale` | `jdg.routing` | 22 | Routing |
| **P11** | `fc_total_net_low_scale` | `jdg.routing` | 22 | Routing |
| **P12** | `fc_vendor_nip_low` | `jdg.routing` | 22 | Routing |
| **P14** | `fc_linear_minimum` | `jdg.routing` | 22 | Routing |
| **P15** | `fc_lump_sum_vat_rate` | `jdg.routing` | 22 | Routing |
| **P16** | `fc_lump_sum_total_net` | `jdg.routing` | 22 | Routing |
| **P19** | `fc_global_minimum_low` | `jdg.routing` | 22 | Routing |
| **P20** | `whitelist_missing_over_limit` | `jdg.compliance.whitelist` | 22 | Compliance |
| **P21** | `whitelist_account_mismatch` | `jdg.compliance.whitelist` | 22 | Compliance |
| **P25** | `split_payment_mandatory` | `jdg.compliance.mpp` | 22 | Compliance |
| **P35** | `cash_transaction_over_limit` | `jdg.compliance.cash_limit` | 22 | Compliance |
| **P40** | `eu_reverse_charge` | `jdg.crossborder` | 22 | VAT transgraniczny | 🔴 [DEPRECATED] → P43 (Doc 23) |
| **P41** | `eu_import_services` | `jdg.crossborder` | 22 | VAT transgraniczny | 🔴 [DEPRECATED] → P44 (Doc 23) |
| **P42** | `wdt_intracommunity_supply` | `jdg.crossborder` | 22 | VAT transgraniczny | 🔴 [DEPRECATED] → P46 (Doc 23) |
| **P43** | `vat_ue_registration_mandatory` | `jdg.crossborder` | 23 | **Eksport/import (6)** |
| **P44** | `vat_r_ue_filing_deadline` | `jdg.crossborder` | 23 | **Eksport/import (6)** |
| **P45** | `import_non_eu` | `jdg.crossborder` | 22 | VAT transgraniczny | 🔴 [DEPRECATED] → P47 (Doc 23) |
| **P46** | `intracommunity_acquisition_detailed` | `jdg.crossborder` | 23 | **Eksport/import (6)** | ✅ Kanoniczne z Doc 23 |
| **P47** | `import_services_non_eu` | `jdg.crossborder` | 23 | **Eksport/import (6)** |
| **P48** | `export_goods` | `jdg.crossborder` | 22 | VAT transgraniczny | 🔴 [DEPRECATED] → P49 (Doc 23) |
| **P49** | `triangular_transaction_rules` | `jdg.crossborder` | 23 | **Eksport/import (6)** | ✅ Kanoniczne z Doc 23 |
| **P50** | `vat_margin_scheme` | `jdg.vat.substantive` | 22 | VAT |
| **P52** | `vat_rate_fuel_pl` | `jdg.vat.substantive` | 22 | VAT |
| **P53** | `vat_rate_food_pl` | `jdg.vat.substantive` | 22 | VAT |
| **P54** | `vat_rate_books_pl` | `jdg.vat.substantive` | 22 | VAT |
| **P55** | `vat_exemption_education` | `jdg.vat.substantive` | 22 | VAT |
| **P56** | `vat_exemption_healthcare` | `jdg.vat.substantive` | 22 | VAT |
| **P58** | `vat_exemption_subject_jdg` | `jdg.vat.substantive` | 22 | VAT |
| **P59** | `subject_exemption_startup_proportion` | `jdg.vat.exemptions` | 23 | **Zwolnienia (10)** | 🔴 [DEPRECATED] → P58 edge case (Doc 22) |
| **P60** | `vat_bad_debt_relief` | `jdg.vat.substantive` | 22 | VAT | 🔴 [DEPRECATED] → P189 (Doc 23, 150 dni) |
| **P61** | `object_exemption_pkd` | `jdg.vat.exemptions` | 23 | **Zwolnienia (10)** |
| **P62** | `vat_exemption_financial` | `jdg.vat.exemptions` | 23 | **Zwolnienia (10)** |
| **P63** | `vat_exemption_insurance` | `jdg.vat.exemptions` | 23 | **Zwolnienia (10)** |
| **P65** | `gtu_mapping_by_category` | `jdg.vat.gtu` | 22 | VAT |
| **P185** | `vat_pre_proportion_mixed` | `jdg.vat.deduction` | 23 | **VAT szczegółowy (8)** |
| **P186** | `vehicle_50_vat_deduction` | `jdg.vat.deduction` | 23 | **VAT szczegółowy (8)** |
| **P187** | `annual_vat_correction_assets` | `jdg.vat.deduction` | 23 | **VAT szczegółowy (8)** |
| **P188** | `vat_deduction_deadline_3m` | `jdg.vat.deduction` | 23 | **VAT szczegółowy (8)** |
| **P189** | `bad_debt_relief_creditor` | `jdg.vat.deduction` | 23 | **VAT szczegółowy (8)** |
| **P190** | `wnt_intra_community_detailed` | `jdg.crossborder` | 23 | **Eksport/import (6)** |
| **P191** | `import_vat_deduction_timing` | `jdg.crossborder` | 23 | **Eksport/import (6)** |
| **P230** | `vat_tax_point_continuous_service` | `jdg.vat.tax_point` | 22 | VAT | 🔴 [DEPRECATED] → R0546-R0559 (Doc 28a) |
| **P231** | `vat_tax_point_advance_invoice` | `jdg.vat.tax_point` | 22 | VAT | 🔴 [DEPRECATED] → R0546-R0559 (Doc 28a) |
| **P232** | `vat_ue_quarterly_summary` | `jdg.vat.declarations` | 23 | **Eksport/import (6)** |
| **P235** | `vat_cash_accounting_jdg` | `jdg.vat.tax_point` | 22 | VAT | 🔴 [DEPRECATED] → R0546-R0559 (Doc 28a) |
| **P500** | `pit_form_scale` | `jdg.pit.form_scale` | 22 | PIT |
| **P501** | `pit_scale_bracket_determination` | `jdg.pit.form_scale` | 22 | PIT |
| **P502** | `pit_scale_joint_filing` | `jdg.pit.form_scale` | 22 | PIT |
| **P510** | `pit_form_linear` | `jdg.pit.form_linear` | 22 | PIT |
| **P511** | `pit_linear_no_tax_free_amount` | `jdg.pit.form_linear` | 22 | PIT |
| **P520** | `pit_form_lump_sum` | `jdg.pit.form_lump_sum` | 22 | PIT |
| **P521** | `lump_sum_rate_by_pkwiu` | `jdg.pit.form_lump_sum` | 22 | PIT |
| **P522** | `lump_sum_multiple_rates` | `jdg.pit.form_lump_sum` | 22 | PIT |
| **P523** | `lump_sum_annual_limit` | `jdg.pit.form_lump_sum` | 22 | PIT |
| **P530** | `pit_form_tax_card` | `jdg.pit.form_tax_card` | 22 | PIT |
| **P531** | `tax_card_decision_valid` | `jdg.pit.form_tax_card` | 22 | PIT |
| **P540** | `pit_advance_monthly` | `jdg.pit.advances` | 22 | PIT |
| **P541** | `pit_advance_zus_social_deduction` | `jdg.pit.advances` | 22 | PIT |
| **P542** | `pit_advance_quarterly` | `jdg.pit.advances` | 22 | PIT |
| **P543** | `pit_advance_simplified` | `jdg.pit.advances` | 22 | PIT |
| **P550** | `pit_annual_return_pit36` | `jdg.pit.annual_returns` | 22 | PIT |
| **P552** | `pit_annual_return_pit36l` | `jdg.pit.annual_returns` | 22 | PIT |
| **P554** | `pit_annual_return_pit28` | `jdg.pit.annual_returns` | 22 | PIT |
| **P556** | `pit_annual_return_overdue` | `jdg.pit.annual_returns` | 22 | PIT |
| **P560** | `kup_full_deductible` | `jdg.pit.kup` | 22 | PIT |
| **P561** | `kup_zus_social_deductible` | `jdg.pit.kup` | 22 | PIT |
| **P562** | `kup_private_mixed_jdg` | `jdg.pit.kup` | 22 | PIT |
| **P564** | `kup_car_over_150k_limit` | `jdg.pit.kup` | 22 | PIT |
| **P566** | `kup_representation_none` | `jdg.pit.kup` | 22 | PIT |
| **P568** | `kup_unpaid_zus_social` | `jdg.pit.kup` | 22 | PIT |
| **P570** | `kup_health_contrib_linear_deduction` | `jdg.pit.kup` | 22 | PIT |
| **P580** | `pit_exemption_young` | `jdg.pit.exemptions` | 22 | PIT zwolnienia |
| **P582** | `pit_exemption_return` | `jdg.pit.exemptions` | 22 | PIT zwolnienia |
| **P584** | `pit_exemption_family_4plus` | `jdg.pit.exemptions` | 22 | PIT zwolnienia |
| **P586** | `pit_exemption_working_senior` | `jdg.pit.exemptions` | 22 | PIT zwolnienia |
| **P588** | `pit_exemption_interactions` | `jdg.pit.exemptions` | 23 | **Ulgi (1) / Zwolnienia (10)** |
| **P590** | `change_scale_to_linear` | `jdg.pit.tax_form_change` | 23 | **Zmiana formy (5)** |
| **P591** | `change_linear_to_lump_sum` | `jdg.pit.tax_form_change` | 23 | **Zmiana formy (5)** |
| **P592** | `change_lump_sum_to_scale` | `jdg.pit.tax_form_change` | 23 | **Zmiana formy (5)** |
| **P593** | `mid_year_change_restriction` | `jdg.pit.tax_form_change` | 23 | **Zmiana formy (5)** |
| **P594** | `tax_consequences_form_change` | `jdg.pit.tax_form_change` | 23 | **Zmiana formy (5)** |
| **P595** | `inventory_remeasurement_change` | `jdg.pit.tax_form_change` | 23 | **Zmiana formy (5)** |
| **P596** | `zus_health_recalculation_change` | `jdg.pit.tax_form_change` | 23 | **Zmiana formy (5)** |
| **P600** | `relief_rd_jdg` | `jdg.allowances.rd` | 22 | Ulgi |
| **P601** | `relief_prototype_jdg` | `jdg.allowances.prototype` | 23 | **Ulgi (1)** |
| **P602** | `relief_robotization_jdg` | `jdg.allowances.robotization` | 23 | **Ulgi (1)** |
| **P603** | `relief_expansion_jdg` | `jdg.allowances.expansion` | 23 | **Ulgi (1)** |
| **P604** | `relief_rehabilitation_jdg` | `jdg.allowances.rehabilitation` | 23 | **Ulgi (1)** |
| **P605** | `relief_internet_jdg` | `jdg.allowances.internet` | 23 | **Ulgi (1)** |
| **P606** | `relief_donation_ngo_jdg` | `jdg.allowances.donation` | 23 | **Ulgi (1)** |
| **P607** | `relief_donation_blood_jdg` | `jdg.allowances.donation` | 23 | **Ulgi (1)** |
| **P608** | `relief_donation_church_jdg` | `jdg.allowances.donation` | 23 | **Ulgi (1)** |
| **P609** | `relief_abolition_jdg` | `jdg.allowances.abolition` | 23 | **Ulgi (1)** |
| **P610** | `relief_ip_box_jdg` | `jdg.allowances.ip_box` | 22 | Ulgi |
| **P615** | `loss_carry_forward_jdg` | `jdg.pit.advances` | 23 | **Ulgi (1)** |
| **P623** | `relief_thermo_jdg` | `jdg.allowances.thermo` | 22 | Ulgi |
| **P700** | `zus_social_standard_jdg` | `jdg.zus.social` | 22 | ZUS |
| **P701** | `zus_sickness_voluntary_jdg` | `jdg.zus.social` | 22 | ZUS | 🔴 [DEPRECATED] → R0346 (Doc 28a) |
| **P720** | `zus_health_scale_jdg` | `jdg.zus.health` | 22 | ZUS |
| **P722** | `zus_health_linear_jdg` | `jdg.zus.health` | 22 | ZUS |
| **P724** | `zus_health_lump_sum_jdg` | `jdg.zus.health` | 22 | ZUS |
| **P730** | `health_contribution_rate_matrix` | `jdg.zus.interactions` | 23 | **Interakcje (10)** | 🔧 HELPER — nie reguła decyzyjna |
| **P732** | `form_change_contribution_trigger` | `jdg.zus.interactions` | 23 | **Interakcje (10)** |
| **P734** | `lump_sum_health_tier_lockstep` | `jdg.zus.interactions` | 23 | **Interakcje (10)** | 🔴 [DEPRECATED] → P724 edge case |
| **P736** | `tax_card_health_fixed` | `jdg.zus.interactions` | 23 | **Interakcje (10)** |
| **P738** | `scale_health_deduction_prohibition` | `jdg.zus.interactions` | 23 | **Interakcje (10)** | 🔴 [DEPRECATED] → P720 |
| **P740** | `zus_start_relief_jdg` | `jdg.zus.start_relief` | 22 | ZUS |
| **P741** | `zus_maly_plus_jdg` | `jdg.zus.maly_plus` | 22 | ZUS |
| **P742** | `zus_preferential_jdg` | `jdg.zus.preferential` | 22 | ZUS |
| **P800** | `pkpir_column_mapping` | `jdg.accounting.pkpir` | 22 | Księgowość | 🔴 [DEPRECATED] → R0372-R0399 (Doc 28a) |
| **P801** | `pkpir_revenue_recognition` | `jdg.accounting.pkpir` | 22 | Księgowość | 🔴 [DEPRECATED] → R0372-R0399 (Doc 28a) |
| **P802** | `pkpir_expense_recognition` | `jdg.accounting.pkpir` | 22 | Księgowość | 🔴 [DEPRECATED] → R0372-R0399 (Doc 28a) |
| **P820** | `lump_sum_evidence_entry` | `jdg.accounting.lump_sum_evidence` | 22 | Księgowość |
| **P830** | `vat_evidence_purchase` | `jdg.accounting.vat_evidence` | 22 | Księgowość |
| **P832** | `vat_evidence_sale` | `jdg.accounting.vat_evidence` | 22 | Księgowość |
| **P840** | `depreciation_linear_jdg` | `jdg.accounting.depreciation` | 22 | Księgowość | 🔴 [DEPRECATED] → R0379-R0389 (Doc 28a) |
| **P842** | `depreciation_one_off_jdg` | `jdg.accounting.depreciation` | 22 | Księgowość | 🔴 [DEPRECATED] → R0379-R0389 (Doc 28a) |
| **P850** | `private_mixed_home_office` | `jdg.accounting.private_mixed` | 22 | Księgowość |
| **P852** | `private_mixed_car` | `jdg.accounting.private_mixed` | 22 | Księgowość |
| **P860** | `operating_lease_full_kup` | `jdg.accounting.leasing` | 23 | **Leasing (9)** |
| **P862** | `financial_lease_interest_kup` | `jdg.accounting.leasing` | 23 | **Leasing (9)** |
| **P864** | `car_lease_150k_limit` | `jdg.accounting.leasing` | 23 | **Leasing (9)** |
| **P866** | `consumer_lease_jdg` | `jdg.accounting.leasing` | 23 | **Leasing (9)** |
| **P868** | `lease_classification_test` | `jdg.accounting.leasing` | 23 | **Leasing (9)** |
| **P900** | `ceidg_registration_check` | `jdg.business.ceidg` | 22 | Cykl życia |
| **P902** | `ceidg_data_change_notification` | `jdg.business.ceidg` | 22 | Cykl życia |
| **P904** | `ceidg_vendor_verification` | `jdg.business.ceidg` | 22 | Cykl życia |
| **P910** | `business_suspension_valid` | `jdg.business.suspension` | 22 | Cykl życia |
| **P912** | `business_suspension_kup_restrictions` | `jdg.business.suspension` | 22 | Cykl życia |
| **P914** | `business_suspension_zus` | `jdg.business.suspension` | 22 | Cykl życia | 🔴 [DEPRECATED] → R0582 (Doc 28a ⚠️ POPRAWIONA!) |
| **P920** | `succession_continuity` | `jdg.business.succession` | 22 | Cykl życia |
| **P922** | `succession_tax_obligations` | `jdg.business.succession` | 22 | Cykl życia |
| **P924** | `succession_vat_continuity` | `jdg.business.succession` | 22 | Cykl życia |
| **P930** | `unregistered_activity_limit` | `jdg.business.unregistered` | 22 | Cykl życia |
| **P932** | `unregistered_activity_zus_exemption` | `jdg.business.unregistered` | 22 | Cykl życia |
| **P934** | `unregistered_activity_taxation` | `jdg.business.unregistered` | 22 | Cykl życia |
| **P950** | `ksef_structured_mandatory_jdg` | `jdg.ksef.structured_invoice` | 22 | KSeF |
| **P952** | `ksef_b2c_exemption_jdg` | `jdg.ksef.structured_invoice` | 22 | KSeF |
| **P960** | `ksef_offline_recovery` | `jdg.ksef.offline_recovery` | 22 | KSeF |
| **P970** | `jpk_v7m_structure_jdg` | `jdg.jpk.jpk_vat` | 22 | JPK |
| **P980** | `jpk_pkpir_structure_jdg` | `jdg.jpk.jpk_pkpir` | 22 | JPK |
| **P990** | `retention_invoice_5y` | `jdg.retention` | 22 | Retencja |
| **P992** | `retention_pkpir_5y` | `jdg.retention` | 22 | Retencja |
| **P1000** | `domestic_fallback_jdg` | `jdg.fallback` | 22 | Fallback |
| **P1099** | `no_match_jdg` | `jdg.fallback` | 22 | Fallback |
| **P1100** | `correction_invoice_in_minus` | `jdg.corrections` | 23 | **Korekty (7)** | 🔴 [DEPRECATED] → R0420-R0435 (Doc 28a, 16 reguł) |
| **P1102** | `correction_invoice_in_plus` | `jdg.corrections` | 23 | **Korekty (7)** | 🔴 [DEPRECATED] → R0420-R0435 (Doc 28a) |
| **P1104** | `vat_declaration_correction` | `jdg.corrections` | 23 | **Korekty (7)** | 🔴 [DEPRECATED] → R0420-R0435 (Doc 28a) |
| **P1106** | `pit_advance_correction` | `jdg.corrections` | 23 | **Korekty (7)** | 🔴 [DEPRECATED] → R0420-R0435 (Doc 28a) |
| **P1108** | `jpk_v7_correction_code` | `jdg.corrections` | 23 | **Korekty (7)** | 🔴 [DEPRECATED] → R0420-R0435 (Doc 28a) |
| **P1110** | `correction_deadline_restrictions` | `jdg.corrections` | 23 | **Korekty (7)** | 🔴 [DEPRECATED] → R0420-R0435 (Doc 28a) |
| **P1112** | `statute_barred_correction_block` | `jdg.corrections` | 23 | **Korekty (7)** | 🔴 [DEPRECATED] → R0420-R0435 (Doc 28a) |
| **P1114** | `correction_during_audit_block` | `jdg.corrections` | 23 | **Korekty (7)** | 🔴 [DEPRECATED] → R0420-R0435 (Doc 28a) |
| **P1150** | `tax_statute_of_limitations_5y` | `jdg.statute_liability` | 23 | **Przedawnienia (8)** | 🔴 [DEPRECATED] → R0436-R0449 (Doc 28a, 14 reguł) |
| **P1152** | `zus_statute_of_limitations_5y` | `jdg.statute_liability` | 23 | **Przedawnienia (8)** | 🔴 [DEPRECATED] → R0436-R0449 (Doc 28a) |
| **P1154** | `statute_suspension_during_audit` | `jdg.statute_liability` | 23 | **Przedawnienia (8)** | 🔴 [DEPRECATED] → R0436-R0449 (Doc 28a) |
| **P1156** | `statute_interruption_events` | `jdg.statute_liability` | 23 | **Przedawnienia (8)** | 🔴 [DEPRECATED] → R0436-R0449 (Doc 28a) |
| **P1158** | `entrepreneur_personal_liability` | `jdg.statute_liability` | 23 | **Przedawnienia (8)** | 🔴 [DEPRECATED] → R0436-R0449 (Doc 28a) |
| **P1160** | `successor_liability` | `jdg.statute_liability` | 23 | **Przedawnienia (8)** | 🔴 [DEPRECATED] → R0436-R0449 (Doc 28a) |
| **P1162** | `joint_liability_spouse` | `jdg.statute_liability` | 23 | **Przedawnienia (8)** | 🔴 [DEPRECATED] → R0436-R0449 (Doc 28a) |
| **P1164** | `late_payment_interest_calculation` | `jdg.statute_liability` | 23 | **Przedawnienia (8)** | 🔴 [DEPRECATED] → R0436-R0449 (Doc 28a) |
| **P1166** | `penalty_interest_rate` | `jdg.statute_liability` | 23 | **Przedawnienia (8)** | 🔴 [DEPRECATED] → R0436-R0449 (Doc 28a) |
| **P1200** | `power_of_attorney_pps1` | `jdg.representation` | 23 | **Reprezentacja (9)** | 🔴 [DEPRECATED] → R0450-R0459 (Doc 28a, 10 reguł) |
| **P1202** | `general_proxy_upl1` | `jdg.representation` | 23 | **Reprezentacja (9)** | 🔴 [DEPRECATED] → R0450-R0459 (Doc 28a) |
| **P1204** | `commercial_proxy_prokura` | `jdg.representation` | 23 | **Reprezentacja (9)** | 🔴 [DEPRECATED] → R0450-R0459 (Doc 28a) |
| **P1206** | `attorney_authorization_scope` | `jdg.representation` | 23 | **Reprezentacja (9)** | 🔴 [DEPRECATED] → R0450-R0459 (Doc 28a) |
| **P1208** | `proxy_validity_period` | `jdg.representation` | 23 | **Reprezentacja (9)** | 🔴 [DEPRECATED] → R0450-R0459 (Doc 28a) |
| **P1210** | `proxy_revocation_effects` | `jdg.representation` | 23 | **Reprezentacja (9)** | 🔴 [DEPRECATED] → R0450-R0459 (Doc 28a) |
| **P1212** | `representation_tax_audit` | `jdg.representation` | 23 | **Reprezentacja (9)** | 🔴 [DEPRECATED] → R0450-R0459 (Doc 28a) |

**Razem: 141 reguł** indeksowanych (P0-P1212). Pozostałe ~73 reguły uniwersalne z planu ogólnego (VAT, crossborder, compliance szczegółowe) są adaptowane bez zmiany priorytetów.

> 🟣 **Statystyka deprecjacji (zgodna z 38c):**  
> — Z Doc 22: **16 reguł zdeprecjonowanych w tej tabeli** (P40-P42, P45, P48, P60, P230, P231, P235, P701, P800-P802, P840, P842, P914) + **P841** (poza tabelą, → R0379-R0389) = **17 łącznie w Doc 22**  
> — Z Doc 23: **28 reguł zdeprecjonowanych** (P59, P734, P738, P1100-P1114, P1150-P1166, P1200-P1212)  
> — Łącznie: **47 reguł** — NIE implementować, używać zamienników kanonicznych z 38c

---

## Struktura Plików — Finalna Architektura JDG

```
policies/jdg/
├── main_jdg.rego                              # Główny else-chain (importuje wszystkie pakiety)
├── _helpers_jdg.rego                          # Funkcje pomocnicze JDG
├── _metadata_jdg.rego                         # Metadane reguł
│
├── risk.rego                                  # P0-P9
├── routing.rego                               # P10-P19
│
├── compliance/
│   ├── whitelist.rego                         # P20-P21
│   ├── mpp.rego                               # P25
│   └── cash_limit.rego                        # P35
│
├── crossborder.rego                           # P40-P49 + P190-P191
│
├── vat/
│   ├── substantive.rego                       # P50-P65
│   ├── gtu.rego                               # P65
│   ├── exemptions.rego                        # P55-P63
│   ├── tax_point.rego                         # P230-P235
│   ├── deduction.rego                         # P185-P189
│   └── declarations.rego                      # P232
│
├── pit/
│   ├── form_scale.rego                        # P500-P502
│   ├── form_linear.rego                       # P510-P511
│   ├── form_lump_sum.rego                     # P520-P523
│   ├── form_tax_card.rego                     # P530-P531
│   ├── tax_form_change.rego                   # P590-P596 ★
│   ├── advances.rego                          # P540-P543 + P615
│   ├── annual_returns.rego                    # P550-P556
│   ├── kup.rego                               # P560-P570
│   └── exemptions.rego                        # P580-P588
│
├── allowances/
│   ├── rd.rego                                # P600
│   ├── prototype.rego                         # P601 ★
│   ├── robotization.rego                      # P602 ★
│   ├── expansion.rego                         # P603 ★
│   ├── rehabilitation.rego                    # P604 ★
│   ├── internet.rego                          # P605 ★
│   ├── donation.rego                          # P606-P608 ★
│   ├── abolition.rego                         # P609 ★
│   ├── ip_box.rego                            # P610
│   └── thermo.rego                            # P623
│
├── zus/
│   ├── social.rego                            # P700-P701
│   ├── health.rego                            # P720-P724
│   ├── interactions.rego                      # P730-P738 ★
│   ├── start_relief.rego                      # P740
│   ├── maly_zus_plus.rego                     # P741
│   └── preferential.rego                      # P742
│
├── accounting/
│   ├── pkpir.rego                             # P800-P802
│   ├── lump_sum_evidence.rego                 # P820
│   ├── vat_evidence.rego                      # P830-P832
│   ├── depreciation.rego                      # P840-P842
│   ├── private_mixed.rego                     # P850-P852
│   └── leasing.rego                           # P860-P868 ★
│
├── business/
│   ├── ceidg.rego                             # P900-P904
│   ├── suspension.rego                        # P910-P914
│   ├── succession.rego                        # P920-P924
│   └── unregistered.rego                      # P930-P934
│
├── corrections/
│   └── main.rego                              # P1100-P1114 ★
│
├── statute_liability/
│   └── main.rego                              # P1150-P1166 ★
│
├── representation/
│   └── main.rego                              # P1200-P1212 ★
│
├── ksef/
│   ├── structured_invoice.rego                # P950-P952
│   └── offline_recovery.rego                  # P960
│
├── jpk/
│   ├── jpk_vat.rego                           # P970
│   └── jpk_pkpir.rego                         # P980
│
├── retention.rego                             # P990-P992
└── fallback.rego                              # P1000-P1099
```

★ = nowy plik/pakiet z rozbudowy (23_JDG_EXPANSION_SUPPLEMENT.md)

---

## Legenda

| Oznaczenie | Znaczenie |
|------------|----------|
| **Dokument 22** | Reguła z planu bazowego `22_JDG_ENTERPRISE_PLAN.md` |
| **Dokument 23** | Reguła z rozbudowy `23_JDG_EXPANSION_SUPPLEMENT.md` |
| ★ | Nowy plik/pakiet dodany w ramach rozbudowy |
| **(1)** | Przynależność do obszaru rozbudowy nr 1 (Ulgi) |
| **(5)** | Przynależność do obszaru rozbudowy nr 5 (Zmiana formy) |
| **(6)** | Przynależność do obszaru rozbudowy nr 6 (Eksport/import) |
| **(7)** | Przynależność do obszaru rozbudowy nr 7 (Korekty) |
| **(8)** | Przynależność do obszaru rozbudowy nr 8 (Przedawnienia) |
| **(9)** | Przynależność do obszaru rozbudowy nr 9 (Reprezentacja/Leasing) |
| **(10)** | Przynależność do obszaru rozbudowy nr 10 (Interakcje/Zwolnienia) |

---

> **Następny krok:** Implementacja Fazy 0 + Fazy A (6 reguł krytycznych z audytu: P0_b, P4, P9, P36, P39, P184, P524, P572, P743).  
> **Dokumenty źródłowe:** `22_JDG_ENTERPRISE_PLAN.md` | `23_JDG_EXPANSION_SUPPLEMENT.md` | `25_JDG_DEEP_LEGAL_AUDIT.md` | `DocsJDG`  
> **⭐ Mapa kanoniczna:** `38c_JDG_CANONICAL_MAP.md` — **779 unikalnych reguł** (definitywne źródło prawdy)  
> **🚀 Wdrożone inicjatywy v2.0:** `48_JDG_STRATEGIC_IMPROVEMENTS_V2.md` (9 inicjatyw) + `49_JDG_IMPLEMENTATION_SUMMARY.md` (podsumowanie)

---

## Luki wykryte w audycie (25_JDG_DEEP_LEGAL_AUDIT.md) — reguły do dodania

| Priorytet | rule_id | Pakiet | Krytyczność | Podstawa prawna |
|:---------:|---------|--------|:-----------:|------------------|
| **P0_b** | `kks_empty_invoice_fraud` | `jdg.risk` | 🔴 KRYTYCZNA | Art. 62 § 2 KKS |
| **P4** | `kks_hidden_income_flag` | `jdg.risk` | 🟡 WAŻNA | Art. 54 KKS |
| **P6** | `kks_unreliable_books` | `jdg.risk` | 🔴 KRYTYCZNA | Art. 56 KKS |
| **P6_b** | `kks_declaration_overdue` | `jdg.risk` | 🟡 WAŻNA | Art. 77 KKS |
| **P7** | `kks_vat_evidence_gap` | `jdg.risk` | 🟡 WAŻNA | Art. 57 KKS |
| **P9** | `gaar_artificial_scheme` | `jdg.risk` | 🔴 KRYTYCZNA | Art. 119a OP |
| **P36** | `vat_simplified_receipt` | `jdg.compliance` | 🔴 KRYTYCZNA | Art. 106e ust. 5 VAT |
| **P39** | `vat_r_registration_status` | `jdg.vat` | 🔴 KRYTYCZNA | Art. 96 VAT |
| **P183** | `vat_blocked_categories` | `jdg.vat.deduction` | 🟡 WAŻNA | Art. 86 ust. 7a VAT |
| **P184** | `bad_debt_debtor_correction` | `jdg.vat.deduction` | 🔴 KRYTYCZNA | Art. 89b VAT |
| **P192** | `vat_refund_timing` | `jdg.vat` | 🔴 KRYTYCZNA | Art. 87 VAT |
| **P233** | `vat_z_deregistration` | `jdg.vat` | 🟡 WAŻNA | Art. 96 VAT |
| **P234** | `vat_payment_deadline` | `jdg.vat` | 🟡 WAŻNA | Art. 103 VAT |
| **P508** | `pit_revenue_exclusions` | `jdg.pit` | 🟡 WAŻNA | Art. 14 ust. 3 PIT |
| **P509** | `pit_income_calculation` | `jdg.pit` | 🟢 DODATKOWA | Art. 24 PIT |
| **P512** | `linear_former_employer_restriction` | `jdg.pit.form_linear` | 🟡 WAŻNA | Art. 30c ust. 2 PIT |
| **P524** | `lump_sum_statutory_exclusions` | `jdg.pit.form_lump_sum` | 🔴 KRYTYCZNA | Art. 8 u.z.p.d. |
| **P525** | `lump_sum_loss_of_right` | `jdg.pit.form_lump_sum` | 🟡 WAŻNA | Art. 20 u.z.p.d. |
| **P526** | `lump_sum_election_deadline` | `jdg.pit.form_lump_sum` | 🟡 WAŻNA | Art. 9 u.z.p.d. |
| **P532** | `tax_card_rate_table` | `jdg.pit.form_tax_card` | 🟢 DODATKOWA | Art. 23 u.z.p.d. |
| **P533** | `tax_card_loss_events` | `jdg.pit.form_tax_card` | 🟢 DODATKOWA | Art. 27 u.z.p.d. |
| **P572** | `kup_direct_vs_indirect_timing` | `jdg.pit.kup` | 🔴 KRYTYCZNA | Art. 22 ust. 5-5c PIT |
| **P574** | `kup_detailed_exclusions` | `jdg.pit.kup` | 🟢 DODATKOWA | Art. 23 ust. 1 pkt 46-49 PIT |
| **P739** | `health_insurance_obligation` | `jdg.zus` | 🟡 WAŻNA | Art. 66-67 u.ś.o.z. |
| **P743** | `concurrent_employment_exemption` | `jdg.zus` | 🔴 KRYTYCZNA | Art. 9 SUS |
| **P744** | `insurance_cessation` | `jdg.zus` | 🟡 WAŻNA | Art. 8-9 SUS |
| **P745** | `zus_payment_deadlines` | `jdg.zus` | 🟡 WAŻNA | Art. 47 SUS |
| **P746** | `dra_filing_deadline` | `jdg.zus` | 🟢 DODATKOWA | Art. 16-17 SUS |
| **P748** | `health_payment_deadline` | `jdg.zus` | 🟢 DODATKOWA | Art. 82 u.ś.o.z. |
| **P870** | `fx_differences_recognition` | `jdg.accounting` | 🟡 WAŻNA | Art. 14 ust. 2c PIT |
| **P925** | `succession_manager_appointment_valid` | `jdg.business.succession` | 🟡 WAŻNA | Art. 3-4 u.z.s. |
| **P926** | `succession_time_limit` | `jdg.business.succession` | 🟡 WAŻNA | Art. 12-13 u.z.s. |
| **P927** | `succession_termination_events` | `jdg.business.succession` | 🟢 DODATKOWA | Art. 14-15 u.z.s. |
| **P972** | `jpk_v7_filing_deadlines` | `jdg.jpk` | 🟢 DODATKOWA | Art. 99 VAT |
| **P1153** | `zus_statute_suspension` | `jdg.statute_liability` | 🟡 WAŻNA | Art. 24 SUS |
| **P1157** | `statute_interruption_detailed` | `jdg.statute_liability` | 🟡 WAŻNA | Art. 71 OP |
| **P1167** | `tax_arrears_detection` | `jdg.statute_liability` | 🔴 KRYTYCZNA | Art. 20-21 OP |
| **P1168** | `voluntary_disclosure_active` | `jdg.statute_liability` | 🔴 KRYTYCZNA | Art. 16-16b KKS |
| **P1169** | `overpayment_detection` | `jdg.statute_liability` | 🔴 KRYTYCZNA | Art. 72-80 OP |
| **P1170** | `deferral_active` | `jdg.statute_liability` | 🟡 WAŻNA | Art. 48, 67a-67e OP |
| **P1171** | `tax_remission_active` | `jdg.statute_liability` | 🟡 WAŻNA | Art. 51 OP |
| **P1172** | `overpayment_offset` | `jdg.statute_liability` | 🟢 DODATKOWA | Art. 87 OP |
| **P1174** | `tax_proceeding_deadlines` | `jdg.statute_liability` | 🟢 DODATKOWA | Art. 120-129 OP |
| **P1205** | `prokura_types` | `jdg.representation` | 🟢 DODATKOWA | Art. 109¹ KC |
| **P1300** | `pcc_mandatory` | `jdg.local_taxes` | 🟡 WAŻNA | Ustawa o PCC |
| **P1310** | `real_estate_commercial` | `jdg.local_taxes` | 🟡 WAŻNA | Ustawa o pod. lokalnych |
| **P1320** | `transport_tax` | `jdg.local_taxes` | 🟡 WAŻNA | Ustawa o pod. lokalnych |

**Razem: 46 nowych reguł proponowanych** — wszystkie z `25_JDG_DEEP_LEGAL_AUDIT.md`
