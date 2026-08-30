# 📊 Raport Pokrycia Prawnego JDG

> **Data:** 2026-08-22 (generator wymaga `Plan OPA/50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md` — plik archiwalny; aktualny stan pokrycia w MANIFEST.md i KAMPANIA_GLM52_ETAPY_10_28.md)  
> **Źródło:** `Plan OPA/50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md`  
> **Reguły Rego:** `JDG/rules/` (490 plików, ~11 855 rule_id — w tym S1-S24 Enterprise v8 + ETAP 10–28)  
> **Status kampanii GLM 5.2 (2026-08-22):** 29/29 raportów WDROZONY_100; 18 domen (13 CERTIFIED / 5 CONDITIONAL / 0 BLOCKED); 12 273 referencje prawne

---

## 📈 Statystyki ogólne

| Metryka | Wartość |
|---------|--------:|
| Punktów prawnych w Doc 50 (przeanalizowane V.01-V.195) | **509** |
| ✅ Pokrytych / zmapowanych | **44** (8%) |
| 🟡 Częściowo pokrytych | **0** |
| ❌ Brak pokrycia | **465** |
| 🔴 Krytycznych | **19** |
| 🟡 Ważnych | **4** |
| 🟢 Dodatkowych | **1** |

---

## 📋 Szczegółowa mapa: V.XX → Reguły Rego

| Punkt | Status | Priorytet | Artykuł | ID OPA | Reguły Rego (rule_id) |
|-------|--------|-----------|---------|--------|----------------------|
| V.01 | 🟡 | 🔴 | 5 ust. 1 pkt 1 | `jdg.vat.a5.r1` | `jdg.vat.substantive.goods_delivery_taxable`, `jdg.vat.substantive.no_match` |
| V.02 | 🟡 | 🔴 | 17 ust. 1 pkt 5 | `jdg.vat.a17.r5` | `jdg.vat.substantive.wnt_reverse_charge_buyer` |
| V.03 | 🟡 | 🔴 | 106e ust. 5 pkt 3 | `jdg.vat.a106e.r10` | `jdg.compliance.vat_simplified_receipt`, `jdg.compliance.vat_simplified_receipt_over_limit`, `jdg.vat.substantive.receipt_as_invoice` |
| V.04 | 🟡 | 🔴 | 15 ust. 1 | `jdg.vat.a15.r1` | `jdg.vat.substantive.taxable_person_jdg_v04` |
| V.05 | 🟡 | 🔴 | 17 ust. 1 pkt 1 | `jdg.vat.a17.r1` | `jdg.crossborder.import_non_eu` |
| V.06 | 🟡 | 🔴 | 19a ust. 1 | `jdg.vat.a19a.r1` | `jdg.edge_cases.vat_first_invoice_tax_point` |
| V.07 | 🟡 | 🔴 | 19a ust. 5 pkt 3 | `jdg.vat.a19a.r7` | `jdg.vat.procedures.tax_point_delayed_invoice_60d`, `jdg.vat.procedures.no_match` |
| V.08 | 🟡 | 🔴 | 21 ust. 1 | `jdg.vat.a21.r1` | `jdg.edge_cases.limit_pit0_combined_85528`, `jdg.pit.exemptions.shared_limit`, `jdg.pit.no_match` |
| V.09 | 🟡 | 🟡 | 28b | `jdg.vat.marz.r1` | `jdg.crossborder.platform_app_store_export`, `jdg.crossborder.platform_import_services`, `jdg.crossborder.eu_import_services` |
| V.10 | 🟡 | 🔴 | 41 ust. 1 | `jdg.vat.s.r23` | `jdg.fallback.no_match`, `jdg.vat.substantive.fuel_pl`, `jdg.vat.substantive.rate_23_standard_pl` |
| V.11 | 🟡 | 🔴 | 41 ust. 2 | `jdg.vat.s.r8` | `jdg.vat.substantive.food_pl`, `jdg.vat.substantive.books_5pct_validation`, `jdg.vat.substantive.books_pl` |
| V.12 | ❌ | ⬜ | 41 ust. 13 | `jdg.vat.s.r5` | — |
| V.13 | ❌ | ⬜ | 41 ust. 14 | `jdg.vat.s.r0` | — |
| V.14 | 🟡 | 🔴 | 86 ust. 1 | `jdg.vat.a86.r1` | `jdg.accounting.private_mixed_home_office`, `jdg.risk.no_match`, `jdg.vat.deductions.deadline_3m_expired` |
| V.15 | 🟡 | 🔴 | 86a | `jdg.vat.a86a.r1` | `jdg.accounting.private_mixed_car`, `jdg.conflicts.advertising_vs_representation_distinction`, `jdg.conflicts.car_vat_vs_kup_asymmetry` |
| V.16 | 🟡 | 🟡 | 87 | `jdg.vat.a87.r1` | `jdg.crossborder.wdt_refund_accelerated`, `jdg.kks.vat_refund_accelerated_fraud_p334`, `jdg.vat.deductions.refund_accelerated_25d` |
| V.17 | 🟡 | 🔴 | 88 ust. 1 | `jdg.vat.a88.r1` | `jdg.vat.deductions.blocked_categories`, `jdg.vat.a88.r9`, `jdg.advertising.hyper.gifts_vat_deduction_100pln` |
| V.18 | 🟡 | 🔴 | 89a ust. 1 | `jdg.vat.a89a.r1` | `jdg.conflicts.bad_debt_partial_payment_proportional`, `jdg.vat.deductions.bad_debt_creditor_90d_post_slim3`, `jdg.vat.substantive.bad_debt_relief_creditor_90d` |
| V.19 | 🟡 | 🔴 | 89b ust. 1 | `jdg.vat.a89b.r1` | `jdg.vat.deductions.bad_debt_debtor_mandatory` |
| V.20 | 🟡 | 🔴 | 96 ust. 1 | `jdg.vat.a96.r1` | `jdg.edge_cases.vat_exempt_breach_notification_7days` |
| V.21 | 🟡 | ⬜ | 96 ust. 3 | `jdg.vat.a96.r3` | `jdg.vat.deductions.sanction_deduction_block`, `jdg.vat.substantive.vat_sanction_no_registration` |
| V.22 | ❌ | ⬜ | 96 ust. 5 | `jdg.vat.a96.r5` | — |
| V.23 | ❌ | ⬜ | 96 ust. 20 | `jdg.vat.a96.r20` | — |
| V.24 | ❌ | ⬜ | 97 ust. 1 | `jdg.vat.a97.r1` | — |
| V.25 | ❌ | ⬜ | 99 ust. 1 | `` | — |
| V.26 | ❌ | 🟡 | 99 ust. 12 | `jdg.vat.a99.r12` | — |
| V.27 | 🟡 | ⬜ | 103 ust. 1 | `jdg.vat.a103.r1` | `jdg.edge_cases.vat_ue_deadline_15th`, `jdg.vat.procedures.payment_deadline`, `jdg.vat.payment_deadline_and_interest` |
| V.28 | ❌ | ⬜ | 103 ust. 3 | `jdg.vat.a103.r3` | — |
| V.29 | ❌ | ⬜ | 103 ust. 4 | `` | — |
| V.30 | 🟡 | 🔴 | 106na | `jdg.vat.ksef.r1` | `jdg.edge_cases.vat_ksef_mandatory_from_2026`, `jdg.kks.empty_invoice_ksef_validation_p318`, `jdg.validation.ksef_upo_required` |
| V.31 | 🟡 | ⬜ | 106e | `jdg.vat.a106e.r1` | `jdg.compliance.vat_simplified_receipt`, `jdg.compliance.vat_simplified_receipt_over_limit`, `jdg.vat.substantive.receipt_as_invoice` |
| V.32 | 🟡 | ⬜ | 106g | `` | `jdg.ksef_jpk.ksef_b2c_exemption` |
| V.33 | ❌ | 🟡 | 106h | `` | — |
| V.34 | 🟡 | ⬜ | 106i | `` | `jdg.kks.failure_to_invoice_deadline_p322`, `jdg.payments.hyper.advance_invoice_15days`, `jdg.hyper.general.payment.advance.vat_invoice_required_15days` |
| V.35 | 🟡 | ⬜ | 106nc | `` | `jdg.ksef.a106nc.r1`, `jdg.ksef.a106nc.r2`, `jdg.ksef.a106nc.r3` |
| V.36 | ❌ | ⬜ | 106q | `` | — |
| V.47 | 🟡 | 🔴 | 108a ust. 1 | `jdg.vat.mpp.r1` | `jdg.compliance.split_payment_voluntary_safe_harbor` |
| V.48 | 🟡 | ⬜ | 108a ust. 3 | `` | `jdg.vat.substantive.split_payment_voluntary` |
| V.49 | 🟡 | 🔴 | 113 ust. 1 | `jdg.vat.a113.r1` | `jdg.edge_cases.no_match`, `jdg.vat.substantive.subject_exemption_jdg`, `jdg.edge_cases.vat_exemption_exclusions` |
| V.50 | 🟡 | ⬜ | 113 ust. 5 | `jdg.vat.a113.r5` | `jdg.edge_cases.vat_exempt_breach_retroactive`, `jdg.seasonal.hyper.vat_exemption_breach_mid_season`, `jdg.hyper.limits.seasonal.vat.exemption_breach_mid_year` |
| V.51 | 🟡 | ⬜ | 113 ust. 9 | `jdg.vat.a113.r9` | `jdg.edge_cases.vat_breach_proportion_new_jdg`, `jdg.edge_cases.vat_pro_rata_detailed`, `jdg.vat.substantive.startup_proportion` |
| V.52 | 🟡 | ⬜ | 113 ust. 13 | `jdg.vat.a113.r13` | `jdg.edge_cases.vat_exemption_exclusions` |
| V.53 | ❌ | ⬜ | 113 ust. 19 | `jdg.vat.a113.r19` | — |
| V.54 | 🟡 | ⬜ | 115 | `jdg.vat.rr.r1` | `jdg.vat.procedures.farmer_rr` |
| V.55 | 🟡 | ⬜ | 116 | `jdg.vat.rr.r10` | `jdg.tp.hyper.sanction_management_board_liability` |
| V.56 | 🟡 | ⬜ | 117 | `jdg.vat.rr.r15` | `jdg.compliance.no_match`, `jdg.compliance.whitelist_account_mismatch`, `jdg.edge_cases.sanction_whitelist_transfer` |
| V.57 | 🟡 | ⬜ | 119 | `jdg.vat.rr.r30` | `jdg.risk.gaar_artificial_scheme`, `jdg.audit.hyper.aggregate_risk_update`, `jdg.conviction.hyper.enhanced_audit_scrutiny` |
| V.58 | 🟡 | ⬜ | 120 | `jdg.vat.marz.r10` | `jdg.liability.tax_proceeding_deadlines`, `jdg.audit.hyper.type_tax_proceeding`, `jdg.statute.tax_proceedings_deadlines_alert` |
| V.59 | ❌ | 🟢 | 125 | `` | — |
| V.060 | ❌ | ⬜ | 11 ust. 1 pkt 1 | `jdg.vat.a11.u1.p1` | — |
| V.061 | ❌ | ⬜ | 11 ust. 2 pkt 2 | `jdg.vat.a11.u2.p2` | — |
| V.062 | ❌ | ⬜ | 11 ust. 3 pkt 3 | `jdg.vat.a11.u3.p3` | — |
| V.063 | ❌ | ⬜ | 11 ust. 4 pkt 4 | `jdg.vat.a11.u4.p4` | — |
| V.064 | ❌ | ⬜ | 12 ust. 5 pkt 1 | `jdg.vat.a12.u5.p1` | — |
| V.065 | 🟡 | ⬜ | 12 ust. 1 pkt 2 | `jdg.vat.a12.u1.p2` | `jdg.ryc.a12.r3`, `jdg.ryc.a12.r4`, `jdg.ryc.a2.r13` |
| V.066 | ❌ | ⬜ | 12 ust. 2 pkt 3 | `jdg.vat.a12.u2.p3` | — |
| V.067 | ❌ | ⬜ | 12 ust. 3 pkt 4 | `jdg.vat.a12.u3.p4` | — |
| V.068 | ❌ | ⬜ | 13 ust. 4 pkt 1 | `jdg.vat.a13.u4.p1` | — |
| V.069 | ❌ | ⬜ | 13 ust. 5 pkt 2 | `jdg.vat.a13.u5.p2` | — |
| V.070 | ❌ | ⬜ | 13 ust. 1 pkt 3 | `jdg.vat.a13.u1.p3` | — |
| V.071 | ❌ | ⬜ | 13 ust. 2 pkt 4 | `jdg.vat.a13.u2.p4` | — |
| V.072 | ❌ | ⬜ | 14 ust. 3 pkt 1 | `jdg.vat.a14.u3.p1` | — |
| V.073 | ❌ | ⬜ | 14 ust. 4 pkt 2 | `jdg.vat.a14.u4.p2` | — |
| V.074 | ❌ | ⬜ | 14 ust. 5 pkt 3 | `jdg.vat.a14.u5.p3` | — |
| V.075 | ❌ | ⬜ | 14 ust. 1 pkt 4 | `jdg.vat.a14.u1.p4` | — |
| V.076 | ❌ | ⬜ | 15 ust. 2 pkt 1 | `jdg.vat.a15.u2.p1` | — |
| V.077 | ❌ | ⬜ | 15 ust. 3 pkt 2 | `jdg.vat.a15.u3.p2` | — |
| V.078 | ❌ | ⬜ | 15 ust. 4 pkt 3 | `jdg.vat.a15.u4.p3` | — |
| V.079 | ❌ | ⬜ | 15 ust. 5 pkt 4 | `jdg.vat.a15.u5.p4` | — |
| V.080 | ❌ | ⬜ | 16 ust. 1 pkt 1 | `jdg.vat.a16.u1.p1` | — |
| V.081 | ❌ | ⬜ | 16 ust. 2 pkt 2 | `jdg.vat.a16.u2.p2` | — |
| V.082 | ❌ | ⬜ | 16 ust. 3 pkt 3 | `jdg.vat.a16.u3.p3` | — |
| V.083 | ❌ | ⬜ | 16 ust. 4 pkt 4 | `jdg.vat.a16.u4.p4` | — |
| V.084 | ❌ | ⬜ | 17 ust. 5 pkt 1 | `jdg.vat.a17.u5.p1` | — |
| V.085 | ❌ | ⬜ | 17 ust. 1 pkt 2 | `jdg.vat.a17.u1.p2` | — |
| V.086 | ❌ | ⬜ | 17 ust. 2 pkt 3 | `jdg.vat.a17.u2.p3` | — |
| V.087 | ❌ | ⬜ | 17 ust. 3 pkt 4 | `jdg.vat.a17.u3.p4` | — |
| V.088 | ❌ | ⬜ | 18 ust. 4 pkt 1 | `jdg.vat.a18.u4.p1` | — |
| V.089 | ❌ | ⬜ | 18 ust. 5 pkt 2 | `jdg.vat.a18.u5.p2` | — |
| V.090 | ❌ | ⬜ | 18 ust. 1 pkt 3 | `jdg.vat.a18.u1.p3` | — |
| V.091 | ❌ | ⬜ | 18 ust. 2 pkt 4 | `jdg.vat.a18.u2.p4` | — |
| V.092 | ❌ | ⬜ | 19 ust. 3 pkt 1 | `jdg.vat.a19.u3.p1` | — |
| V.093 | ❌ | ⬜ | 19 ust. 4 pkt 2 | `jdg.vat.a19.u4.p2` | — |
| V.094 | ❌ | ⬜ | 19 ust. 5 pkt 3 | `jdg.vat.a19.u5.p3` | — |
| V.095 | ❌ | ⬜ | 19 ust. 1 pkt 4 | `jdg.vat.a19.u1.p4` | — |
| V.096 | ❌ | ⬜ | 20 ust. 2 pkt 1 | `jdg.vat.a20.u2.p1` | — |
| V.097 | ❌ | ⬜ | 20 ust. 3 pkt 2 | `jdg.vat.a20.u3.p2` | — |
| V.098 | ❌ | ⬜ | 20 ust. 4 pkt 3 | `jdg.vat.a20.u4.p3` | — |
| V.099 | ❌ | ⬜ | 20 ust. 5 pkt 4 | `jdg.vat.a20.u5.p4` | — |
| V.100 | 🟡 | ⬜ | 21 ust. 1 pkt 1 | `jdg.vat.a21.u1.p1` | `jdg.edge_cases.limit_pit0_combined_85528`, `jdg.pit.exemptions.shared_limit`, `jdg.pit.no_match` |
| V.101 | ❌ | ⬜ | 21 ust. 2 pkt 2 | `jdg.vat.a21.u2.p2` | — |
| V.102 | ❌ | ⬜ | 21 ust. 3 pkt 3 | `jdg.vat.a21.u3.p3` | — |
| V.103 | ❌ | ⬜ | 21 ust. 4 pkt 4 | `jdg.vat.a21.u4.p4` | — |
| V.104 | ❌ | ⬜ | 22 ust. 5 pkt 1 | `jdg.vat.a22.u5.p1` | — |
| V.105 | ❌ | ⬜ | 22 ust. 1 pkt 2 | `jdg.vat.a22.u1.p2` | — |
| V.106 | 🟡 | ⬜ | 22 ust. 2 pkt 3 | `jdg.vat.a22.u2.p3` | `jdg.employer.kup_300_commuting` |
| V.107 | ❌ | ⬜ | 22 ust. 3 pkt 4 | `jdg.vat.a22.u3.p4` | — |
| V.108 | ❌ | ⬜ | 23 ust. 4 pkt 1 | `jdg.vat.a23.u4.p1` | — |
| V.109 | ❌ | ⬜ | 23 ust. 5 pkt 2 | `jdg.vat.a23.u5.p2` | — |
| V.110 | 🟡 | ⬜ | 23 ust. 1 pkt 3 | `jdg.vat.a23.u1.p3` | `jdg.pit.kup.zus_social_deductible`, `jdg.pit.a23.r10` |
| V.111 | ❌ | ⬜ | 23 ust. 2 pkt 4 | `jdg.vat.a23.u2.p4` | — |
| V.112 | ❌ | ⬜ | 24 ust. 3 pkt 1 | `jdg.vat.a24.u3.p1` | — |
| V.113 | ❌ | ⬜ | 24 ust. 4 pkt 2 | `jdg.vat.a24.u4.p2` | — |
| V.114 | ❌ | ⬜ | 24 ust. 5 pkt 3 | `jdg.vat.a24.u5.p3` | — |
| V.115 | ❌ | ⬜ | 24 ust. 1 pkt 4 | `jdg.vat.a24.u1.p4` | — |
| V.116 | ❌ | ⬜ | 25 ust. 2 pkt 1 | `jdg.vat.a25.u2.p1` | — |
| V.117 | ❌ | ⬜ | 25 ust. 3 pkt 2 | `jdg.vat.a25.u3.p2` | — |
| V.118 | ❌ | ⬜ | 25 ust. 4 pkt 3 | `jdg.vat.a25.u4.p3` | — |
| V.119 | ❌ | ⬜ | 25 ust. 5 pkt 4 | `jdg.vat.a25.u5.p4` | — |
| V.120 | 🟡 | ⬜ | 26 ust. 1 pkt 1 | `jdg.vat.a26.u1.p1` | `jdg.regulated.hyper.chamber_fees_deductible`, `jdg.hyper.sanctions.regulated.chamber.fees_tax_deductible` |
| V.121 | ❌ | ⬜ | 26 ust. 2 pkt 2 | `jdg.vat.a26.u2.p2` | — |
| V.122 | ❌ | ⬜ | 26 ust. 3 pkt 3 | `jdg.vat.a26.u3.p3` | — |
| V.123 | ❌ | ⬜ | 26 ust. 4 pkt 4 | `jdg.vat.a26.u4.p4` | — |
| V.124 | ❌ | ⬜ | 27 ust. 5 pkt 1 | `jdg.vat.a27.u5.p1` | — |
| V.125 | ❌ | ⬜ | 27 ust. 1 pkt 2 | `jdg.vat.a27.u1.p2` | — |
| V.126 | ❌ | ⬜ | 27 ust. 2 pkt 3 | `jdg.vat.a27.u2.p3` | — |
| V.127 | ❌ | ⬜ | 27 ust. 3 pkt 4 | `jdg.vat.a27.u3.p4` | — |
| V.128 | ❌ | ⬜ | 28 ust. 4 pkt 1 | `jdg.vat.a28.u4.p1` | — |
| V.129 | ❌ | ⬜ | 28 ust. 5 pkt 2 | `jdg.vat.a28.u5.p2` | — |
| V.130 | ❌ | ⬜ | 28 ust. 1 pkt 3 | `jdg.vat.a28.u1.p3` | — |
| V.131 | ❌ | ⬜ | 28 ust. 2 pkt 4 | `jdg.vat.a28.u2.p4` | — |
| V.132 | ❌ | ⬜ | 29 ust. 3 pkt 1 | `jdg.vat.a29.u3.p1` | — |
| V.133 | ❌ | ⬜ | 29 ust. 4 pkt 2 | `jdg.vat.a29.u4.p2` | — |
| V.134 | ❌ | ⬜ | 29 ust. 5 pkt 3 | `jdg.vat.a29.u5.p3` | — |
| V.135 | ❌ | ⬜ | 29 ust. 1 pkt 4 | `jdg.vat.a29.u1.p4` | — |
| V.136 | ❌ | ⬜ | 30 ust. 2 pkt 1 | `jdg.vat.a30.u2.p1` | — |
| V.137 | ❌ | ⬜ | 30 ust. 3 pkt 2 | `jdg.vat.a30.u3.p2` | — |
| V.138 | ❌ | ⬜ | 30 ust. 4 pkt 3 | `jdg.vat.a30.u4.p3` | — |
| V.139 | ❌ | ⬜ | 30 ust. 5 pkt 4 | `jdg.vat.a30.u5.p4` | — |
| V.140 | ❌ | ⬜ | 31 ust. 1 pkt 1 | `jdg.vat.a31.u1.p1` | — |
| V.141 | ❌ | ⬜ | 31 ust. 2 pkt 2 | `jdg.vat.a31.u2.p2` | — |
| V.142 | ❌ | ⬜ | 31 ust. 3 pkt 3 | `jdg.vat.a31.u3.p3` | — |
| V.143 | ❌ | ⬜ | 31 ust. 4 pkt 4 | `jdg.vat.a31.u4.p4` | — |
| V.144 | ❌ | ⬜ | 32 ust. 5 pkt 1 | `jdg.vat.a32.u5.p1` | — |
| V.145 | ❌ | ⬜ | 32 ust. 1 pkt 2 | `jdg.vat.a32.u1.p2` | — |
| V.146 | ❌ | ⬜ | 32 ust. 2 pkt 3 | `jdg.vat.a32.u2.p3` | — |
| V.147 | ❌ | ⬜ | 32 ust. 3 pkt 4 | `jdg.vat.a32.u3.p4` | — |
| V.148 | ❌ | ⬜ | 33 ust. 4 pkt 1 | `jdg.vat.a33.u4.p1` | — |
| V.149 | ❌ | ⬜ | 33 ust. 5 pkt 2 | `jdg.vat.a33.u5.p2` | — |
| V.150 | ❌ | ⬜ | 33 ust. 1 pkt 3 | `jdg.vat.a33.u1.p3` | — |
| V.151 | ❌ | ⬜ | 33 ust. 2 pkt 4 | `jdg.vat.a33.u2.p4` | — |
| V.152 | ❌ | ⬜ | 34 ust. 3 pkt 1 | `jdg.vat.a34.u3.p1` | — |
| V.153 | ❌ | ⬜ | 34 ust. 4 pkt 2 | `jdg.vat.a34.u4.p2` | — |
| V.154 | ❌ | ⬜ | 34 ust. 5 pkt 3 | `jdg.vat.a34.u5.p3` | — |
| V.155 | ❌ | ⬜ | 34 ust. 1 pkt 4 | `jdg.vat.a34.u1.p4` | — |
| V.156 | ❌ | ⬜ | 35 ust. 2 pkt 1 | `jdg.vat.a35.u2.p1` | — |
| V.157 | ❌ | ⬜ | 35 ust. 3 pkt 2 | `jdg.vat.a35.u3.p2` | — |
| V.158 | ❌ | ⬜ | 35 ust. 4 pkt 3 | `jdg.vat.a35.u4.p3` | — |
| V.159 | ❌ | ⬜ | 35 ust. 5 pkt 4 | `jdg.vat.a35.u5.p4` | — |
| V.160 | ❌ | ⬜ | 36 ust. 1 pkt 1 | `jdg.vat.a36.u1.p1` | — |
| V.161 | ❌ | ⬜ | 36 ust. 2 pkt 2 | `jdg.vat.a36.u2.p2` | — |
| V.162 | ❌ | ⬜ | 36 ust. 3 pkt 3 | `jdg.vat.a36.u3.p3` | — |
| V.163 | ❌ | ⬜ | 36 ust. 4 pkt 4 | `jdg.vat.a36.u4.p4` | — |
| V.164 | ❌ | ⬜ | 37 ust. 5 pkt 1 | `jdg.vat.a37.u5.p1` | — |
| V.165 | ❌ | ⬜ | 37 ust. 1 pkt 2 | `jdg.vat.a37.u1.p2` | — |
| V.166 | ❌ | ⬜ | 37 ust. 2 pkt 3 | `jdg.vat.a37.u2.p3` | — |
| V.167 | ❌ | ⬜ | 37 ust. 3 pkt 4 | `jdg.vat.a37.u3.p4` | — |
| V.168 | ❌ | ⬜ | 38 ust. 4 pkt 1 | `jdg.vat.a38.u4.p1` | — |
| V.169 | ❌ | ⬜ | 38 ust. 5 pkt 2 | `jdg.vat.a38.u5.p2` | — |
| V.170 | ❌ | ⬜ | 38 ust. 1 pkt 3 | `jdg.vat.a38.u1.p3` | — |
| V.171 | ❌ | ⬜ | 38 ust. 2 pkt 4 | `jdg.vat.a38.u2.p4` | — |
| V.172 | ❌ | ⬜ | 39 ust. 3 pkt 1 | `jdg.vat.a39.u3.p1` | — |
| V.173 | ❌ | ⬜ | 39 ust. 4 pkt 2 | `jdg.vat.a39.u4.p2` | — |
| V.174 | ❌ | ⬜ | 39 ust. 5 pkt 3 | `jdg.vat.a39.u5.p3` | — |
| V.175 | ❌ | ⬜ | 39 ust. 1 pkt 4 | `jdg.vat.a39.u1.p4` | — |
| V.176 | ❌ | ⬜ | 40 ust. 2 pkt 1 | `jdg.vat.a40.u2.p1` | — |
| V.177 | ❌ | ⬜ | 40 ust. 3 pkt 2 | `jdg.vat.a40.u3.p2` | — |
| V.178 | ❌ | ⬜ | 40 ust. 4 pkt 3 | `jdg.vat.a40.u4.p3` | — |
| V.179 | ❌ | ⬜ | 40 ust. 5 pkt 4 | `jdg.vat.a40.u5.p4` | — |
| V.180 | ❌ | ⬜ | 41 ust. 1 pkt 1 | `jdg.vat.a41.u1.p1` | — |
| V.181 | ❌ | ⬜ | 41 ust. 2 pkt 2 | `jdg.vat.a41.u2.p2` | — |
| V.182 | ❌ | ⬜ | 41 ust. 3 pkt 3 | `jdg.vat.a41.u3.p3` | — |
| V.183 | ❌ | ⬜ | 41 ust. 4 pkt 4 | `jdg.vat.a41.u4.p4` | — |
| V.184 | ❌ | ⬜ | 42 ust. 5 pkt 1 | `jdg.vat.a42.u5.p1` | — |
| V.185 | ❌ | ⬜ | 42 ust. 1 pkt 2 | `jdg.vat.a42.u1.p2` | — |
| V.186 | ❌ | ⬜ | 42 ust. 2 pkt 3 | `jdg.vat.a42.u2.p3` | — |
| V.187 | ❌ | ⬜ | 42 ust. 3 pkt 4 | `jdg.vat.a42.u3.p4` | — |
| V.188 | ❌ | ⬜ | 43 ust. 4 pkt 1 | `jdg.vat.a43.u4.p1` | — |
| V.189 | ❌ | ⬜ | 43 ust. 5 pkt 2 | `jdg.vat.a43.u5.p2` | — |
| V.190 | 🟡 | ⬜ | 43 ust. 1 pkt 3 | `jdg.vat.a43.u1.p3` | `jdg.vat.substantive.culture_exempt`, `jdg.vat.exemption_financial`, `jdg.vat.exemption_insurance` |
| V.191 | ❌ | ⬜ | 43 ust. 2 pkt 4 | `jdg.vat.a43.u2.p4` | — |
| V.192 | ❌ | ⬜ | 44 ust. 3 pkt 1 | `jdg.vat.a44.u3.p1` | — |
| V.193 | ❌ | ⬜ | 44 ust. 4 pkt 2 | `jdg.vat.a44.u4.p2` | — |
| V.194 | ❌ | ⬜ | 44 ust. 5 pkt 3 | `jdg.vat.a44.u5.p3` | — |
| V.195 | ❌ | ⬜ | 44 ust. 1 pkt 4 | `jdg.vat.a44.u1.p4` | — |
| V.196 | ❌ | ⬜ | 45 ust. 2 pkt 1 | `jdg.vat.a45.u2.p1` | — |
| V.197 | ❌ | ⬜ | 45 ust. 3 pkt 2 | `jdg.vat.a45.u3.p2` | — |
| V.198 | ❌ | ⬜ | 45 ust. 4 pkt 3 | `jdg.vat.a45.u4.p3` | — |
| V.199 | ❌ | ⬜ | 45 ust. 5 pkt 4 | `jdg.vat.a45.u5.p4` | — |
| V.200 | ❌ | ⬜ | 46 ust. 1 pkt 1 | `jdg.vat.a46.u1.p1` | — |
| V.201 | ❌ | ⬜ | 46 ust. 2 pkt 2 | `jdg.vat.a46.u2.p2` | — |
| V.202 | ❌ | ⬜ | 46 ust. 3 pkt 3 | `jdg.vat.a46.u3.p3` | — |
| V.203 | ❌ | ⬜ | 46 ust. 4 pkt 4 | `jdg.vat.a46.u4.p4` | — |
| V.204 | ❌ | ⬜ | 47 ust. 5 pkt 1 | `jdg.vat.a47.u5.p1` | — |
| V.205 | 🟡 | ⬜ | 47 ust. 1 pkt 2 | `jdg.vat.a47.u1.p2` | `jdg.calendar.hyper.zus_employees_15th` |
| V.206 | ❌ | ⬜ | 47 ust. 2 pkt 3 | `jdg.vat.a47.u2.p3` | — |
| V.207 | ❌ | ⬜ | 47 ust. 3 pkt 4 | `jdg.vat.a47.u3.p4` | — |
| V.208 | ❌ | ⬜ | 48 ust. 4 pkt 1 | `jdg.vat.a48.u4.p1` | — |
| V.209 | ❌ | ⬜ | 48 ust. 5 pkt 2 | `jdg.vat.a48.u5.p2` | — |
| V.210 | ❌ | ⬜ | 48 ust. 1 pkt 3 | `jdg.vat.a48.u1.p3` | — |
| V.211 | ❌ | ⬜ | 48 ust. 2 pkt 4 | `jdg.vat.a48.u2.p4` | — |
| V.212 | ❌ | ⬜ | 49 ust. 3 pkt 1 | `jdg.vat.a49.u3.p1` | — |
| V.213 | ❌ | ⬜ | 49 ust. 4 pkt 2 | `jdg.vat.a49.u4.p2` | — |
| V.214 | ❌ | ⬜ | 49 ust. 5 pkt 3 | `jdg.vat.a49.u5.p3` | — |
| V.215 | ❌ | ⬜ | 49 ust. 1 pkt 4 | `jdg.vat.a49.u1.p4` | — |
| V.216 | ❌ | ⬜ | 50 ust. 2 pkt 1 | `jdg.vat.a50.u2.p1` | — |
| V.217 | ❌ | ⬜ | 50 ust. 3 pkt 2 | `jdg.vat.a50.u3.p2` | — |
| V.218 | ❌ | ⬜ | 50 ust. 4 pkt 3 | `jdg.vat.a50.u4.p3` | — |
| V.219 | ❌ | ⬜ | 50 ust. 5 pkt 4 | `jdg.vat.a50.u5.p4` | — |
| V.220 | ❌ | ⬜ | 51 ust. 1 pkt 1 | `jdg.vat.a51.u1.p1` | — |
| V.221 | ❌ | ⬜ | 51 ust. 2 pkt 2 | `jdg.vat.a51.u2.p2` | — |
| V.222 | ❌ | ⬜ | 51 ust. 3 pkt 3 | `jdg.vat.a51.u3.p3` | — |
| V.223 | ❌ | ⬜ | 51 ust. 4 pkt 4 | `jdg.vat.a51.u4.p4` | — |
| V.224 | ❌ | ⬜ | 52 ust. 5 pkt 1 | `jdg.vat.a52.u5.p1` | — |
| V.225 | ❌ | ⬜ | 52 ust. 1 pkt 2 | `jdg.vat.a52.u1.p2` | — |
| V.226 | ❌ | ⬜ | 52 ust. 2 pkt 3 | `jdg.vat.a52.u2.p3` | — |
| V.227 | ❌ | ⬜ | 52 ust. 3 pkt 4 | `jdg.vat.a52.u3.p4` | — |
| V.228 | ❌ | ⬜ | 53 ust. 4 pkt 1 | `jdg.vat.a53.u4.p1` | — |
| V.229 | ❌ | ⬜ | 53 ust. 5 pkt 2 | `jdg.vat.a53.u5.p2` | — |
| V.230 | ❌ | ⬜ | 53 ust. 1 pkt 3 | `jdg.vat.a53.u1.p3` | — |
| V.231 | ❌ | ⬜ | 53 ust. 2 pkt 4 | `jdg.vat.a53.u2.p4` | — |
| V.232 | ❌ | ⬜ | 54 ust. 3 pkt 1 | `jdg.vat.a54.u3.p1` | — |
| V.233 | ❌ | ⬜ | 54 ust. 4 pkt 2 | `jdg.vat.a54.u4.p2` | — |
| V.234 | ❌ | ⬜ | 54 ust. 5 pkt 3 | `jdg.vat.a54.u5.p3` | — |
| V.235 | ❌ | ⬜ | 54 ust. 1 pkt 4 | `jdg.vat.a54.u1.p4` | — |
| V.236 | ❌ | ⬜ | 55 ust. 2 pkt 1 | `jdg.vat.a55.u2.p1` | — |
| V.237 | ❌ | ⬜ | 55 ust. 3 pkt 2 | `jdg.vat.a55.u3.p2` | — |
| V.238 | ❌ | ⬜ | 55 ust. 4 pkt 3 | `jdg.vat.a55.u4.p3` | — |
| V.239 | ❌ | ⬜ | 55 ust. 5 pkt 4 | `jdg.vat.a55.u5.p4` | — |
| V.240 | ❌ | ⬜ | 56 ust. 1 pkt 1 | `jdg.vat.a56.u1.p1` | — |
| V.241 | ❌ | ⬜ | 56 ust. 2 pkt 2 | `jdg.vat.a56.u2.p2` | — |
| V.242 | ❌ | ⬜ | 56 ust. 3 pkt 3 | `jdg.vat.a56.u3.p3` | — |
| V.243 | ❌ | ⬜ | 56 ust. 4 pkt 4 | `jdg.vat.a56.u4.p4` | — |
| V.244 | ❌ | ⬜ | 57 ust. 5 pkt 1 | `jdg.vat.a57.u5.p1` | — |
| V.245 | ❌ | ⬜ | 57 ust. 1 pkt 2 | `jdg.vat.a57.u1.p2` | — |
| V.246 | ❌ | ⬜ | 57 ust. 2 pkt 3 | `jdg.vat.a57.u2.p3` | — |
| V.247 | ❌ | ⬜ | 57 ust. 3 pkt 4 | `jdg.vat.a57.u3.p4` | — |
| V.248 | ❌ | ⬜ | 58 ust. 4 pkt 1 | `jdg.vat.a58.u4.p1` | — |
| V.249 | ❌ | ⬜ | 58 ust. 5 pkt 2 | `jdg.vat.a58.u5.p2` | — |
| V.250 | ❌ | ⬜ | 58 ust. 1 pkt 3 | `jdg.vat.a58.u1.p3` | — |
| V.251 | ❌ | ⬜ | 58 ust. 2 pkt 4 | `jdg.vat.a58.u2.p4` | — |
| V.252 | ❌ | ⬜ | 59 ust. 3 pkt 1 | `jdg.vat.a59.u3.p1` | — |
| V.253 | ❌ | ⬜ | 59 ust. 4 pkt 2 | `jdg.vat.a59.u4.p2` | — |
| V.254 | ❌ | ⬜ | 59 ust. 5 pkt 3 | `jdg.vat.a59.u5.p3` | — |
| V.255 | ❌ | ⬜ | 59 ust. 1 pkt 4 | `jdg.vat.a59.u1.p4` | — |
| V.256 | ❌ | ⬜ | 60 ust. 2 pkt 1 | `jdg.vat.a60.u2.p1` | — |
| V.257 | ❌ | ⬜ | 60 ust. 3 pkt 2 | `jdg.vat.a60.u3.p2` | — |
| V.258 | ❌ | ⬜ | 60 ust. 4 pkt 3 | `jdg.vat.a60.u4.p3` | — |
| V.259 | ❌ | ⬜ | 60 ust. 5 pkt 4 | `jdg.vat.a60.u5.p4` | — |
| V.260 | ❌ | ⬜ | 61 ust. 1 pkt 1 | `jdg.vat.a61.u1.p1` | — |
| V.261 | ❌ | ⬜ | 61 ust. 2 pkt 2 | `jdg.vat.a61.u2.p2` | — |
| V.262 | ❌ | ⬜ | 61 ust. 3 pkt 3 | `jdg.vat.a61.u3.p3` | — |
| V.263 | ❌ | ⬜ | 61 ust. 4 pkt 4 | `jdg.vat.a61.u4.p4` | — |
| V.264 | ❌ | ⬜ | 62 ust. 5 pkt 1 | `jdg.vat.a62.u5.p1` | — |
| V.265 | ❌ | ⬜ | 62 ust. 1 pkt 2 | `jdg.vat.a62.u1.p2` | — |
| V.266 | ❌ | ⬜ | 62 ust. 2 pkt 3 | `jdg.vat.a62.u2.p3` | — |
| V.267 | ❌ | ⬜ | 62 ust. 3 pkt 4 | `jdg.vat.a62.u3.p4` | — |
| V.268 | ❌ | ⬜ | 63 ust. 4 pkt 1 | `jdg.vat.a63.u4.p1` | — |
| V.269 | ❌ | ⬜ | 63 ust. 5 pkt 2 | `jdg.vat.a63.u5.p2` | — |
| V.270 | ❌ | ⬜ | 63 ust. 1 pkt 3 | `jdg.vat.a63.u1.p3` | — |
| V.271 | ❌ | ⬜ | 63 ust. 2 pkt 4 | `jdg.vat.a63.u2.p4` | — |
| V.272 | ❌ | ⬜ | 64 ust. 3 pkt 1 | `jdg.vat.a64.u3.p1` | — |
| V.273 | ❌ | ⬜ | 64 ust. 4 pkt 2 | `jdg.vat.a64.u4.p2` | — |
| V.274 | ❌ | ⬜ | 64 ust. 5 pkt 3 | `jdg.vat.a64.u5.p3` | — |
| V.275 | ❌ | ⬜ | 64 ust. 1 pkt 4 | `jdg.vat.a64.u1.p4` | — |
| V.276 | ❌ | ⬜ | 65 ust. 2 pkt 1 | `jdg.vat.a65.u2.p1` | — |
| V.277 | ❌ | ⬜ | 65 ust. 3 pkt 2 | `jdg.vat.a65.u3.p2` | — |
| V.278 | ❌ | ⬜ | 65 ust. 4 pkt 3 | `jdg.vat.a65.u4.p3` | — |
| V.279 | ❌ | ⬜ | 65 ust. 5 pkt 4 | `jdg.vat.a65.u5.p4` | — |
| V.280 | 🟡 | ⬜ | 66 ust. 1 pkt 1 | `jdg.vat.a66.u1.p1` | `jdg.zus.health_insurance_obligation` |
| V.281 | ❌ | ⬜ | 66 ust. 2 pkt 2 | `jdg.vat.a66.u2.p2` | — |
| V.282 | ❌ | ⬜ | 66 ust. 3 pkt 3 | `jdg.vat.a66.u3.p3` | — |
| V.283 | ❌ | ⬜ | 66 ust. 4 pkt 4 | `jdg.vat.a66.u4.p4` | — |
| V.284 | ❌ | ⬜ | 67 ust. 5 pkt 1 | `jdg.vat.a67.u5.p1` | — |
| V.285 | ❌ | ⬜ | 67 ust. 1 pkt 2 | `jdg.vat.a67.u1.p2` | — |
| V.286 | ❌ | ⬜ | 67 ust. 2 pkt 3 | `jdg.vat.a67.u2.p3` | — |
| V.287 | ❌ | ⬜ | 67 ust. 3 pkt 4 | `jdg.vat.a67.u3.p4` | — |
| V.288 | ❌ | ⬜ | 68 ust. 4 pkt 1 | `jdg.vat.a68.u4.p1` | — |
| V.289 | ❌ | ⬜ | 68 ust. 5 pkt 2 | `jdg.vat.a68.u5.p2` | — |
| V.290 | ❌ | ⬜ | 68 ust. 1 pkt 3 | `jdg.vat.a68.u1.p3` | — |
| V.291 | ❌ | ⬜ | 68 ust. 2 pkt 4 | `jdg.vat.a68.u2.p4` | — |
| V.292 | ❌ | ⬜ | 69 ust. 3 pkt 1 | `jdg.vat.a69.u3.p1` | — |
| V.293 | ❌ | ⬜ | 69 ust. 4 pkt 2 | `jdg.vat.a69.u4.p2` | — |
| V.294 | ❌ | ⬜ | 69 ust. 5 pkt 3 | `jdg.vat.a69.u5.p3` | — |
| V.295 | ❌ | ⬜ | 69 ust. 1 pkt 4 | `jdg.vat.a69.u1.p4` | — |
| V.296 | ❌ | ⬜ | 70 ust. 2 pkt 1 | `jdg.vat.a70.u2.p1` | — |
| V.297 | ❌ | ⬜ | 70 ust. 3 pkt 2 | `jdg.vat.a70.u3.p2` | — |
| V.298 | ❌ | ⬜ | 70 ust. 4 pkt 3 | `jdg.vat.a70.u4.p3` | — |
| V.299 | ❌ | ⬜ | 70 ust. 5 pkt 4 | `jdg.vat.a70.u5.p4` | — |
| V.300 | ❌ | ⬜ | 71 ust. 1 pkt 1 | `jdg.vat.a71.u1.p1` | — |
| V.301 | ❌ | ⬜ | 71 ust. 2 pkt 2 | `jdg.vat.a71.u2.p2` | — |
| V.302 | ❌ | ⬜ | 71 ust. 3 pkt 3 | `jdg.vat.a71.u3.p3` | — |
| V.303 | ❌ | ⬜ | 71 ust. 4 pkt 4 | `jdg.vat.a71.u4.p4` | — |
| V.304 | ❌ | ⬜ | 72 ust. 5 pkt 1 | `jdg.vat.a72.u5.p1` | — |
| V.305 | ❌ | ⬜ | 72 ust. 1 pkt 2 | `jdg.vat.a72.u1.p2` | — |
| V.306 | ❌ | ⬜ | 72 ust. 2 pkt 3 | `jdg.vat.a72.u2.p3` | — |
| V.307 | ❌ | ⬜ | 72 ust. 3 pkt 4 | `jdg.vat.a72.u3.p4` | — |
| V.308 | ❌ | ⬜ | 73 ust. 4 pkt 1 | `jdg.vat.a73.u4.p1` | — |
| V.309 | ❌ | ⬜ | 73 ust. 5 pkt 2 | `jdg.vat.a73.u5.p2` | — |
| V.310 | ❌ | ⬜ | 73 ust. 1 pkt 3 | `jdg.vat.a73.u1.p3` | — |
| V.311 | ❌ | ⬜ | 73 ust. 2 pkt 4 | `jdg.vat.a73.u2.p4` | — |
| V.312 | ❌ | ⬜ | 74 ust. 3 pkt 1 | `jdg.vat.a74.u3.p1` | — |
| V.313 | ❌ | ⬜ | 74 ust. 4 pkt 2 | `jdg.vat.a74.u4.p2` | — |
| V.314 | ❌ | ⬜ | 74 ust. 5 pkt 3 | `jdg.vat.a74.u5.p3` | — |
| V.315 | ❌ | ⬜ | 74 ust. 1 pkt 4 | `jdg.vat.a74.u1.p4` | — |
| V.316 | ❌ | ⬜ | 75 ust. 2 pkt 1 | `jdg.vat.a75.u2.p1` | — |
| V.317 | ❌ | ⬜ | 75 ust. 3 pkt 2 | `jdg.vat.a75.u3.p2` | — |
| V.318 | ❌ | ⬜ | 75 ust. 4 pkt 3 | `jdg.vat.a75.u4.p3` | — |
| V.319 | ❌ | ⬜ | 75 ust. 5 pkt 4 | `jdg.vat.a75.u5.p4` | — |
| V.320 | ❌ | ⬜ | 76 ust. 1 pkt 1 | `jdg.vat.a76.u1.p1` | — |
| V.321 | ❌ | ⬜ | 76 ust. 2 pkt 2 | `jdg.vat.a76.u2.p2` | — |
| V.322 | ❌ | ⬜ | 76 ust. 3 pkt 3 | `jdg.vat.a76.u3.p3` | — |
| V.323 | ❌ | ⬜ | 76 ust. 4 pkt 4 | `jdg.vat.a76.u4.p4` | — |
| V.324 | ❌ | ⬜ | 77 ust. 5 pkt 1 | `jdg.vat.a77.u5.p1` | — |
| V.325 | ❌ | ⬜ | 77 ust. 1 pkt 2 | `jdg.vat.a77.u1.p2` | — |
| V.326 | ❌ | ⬜ | 77 ust. 2 pkt 3 | `jdg.vat.a77.u2.p3` | — |
| V.327 | ❌ | ⬜ | 77 ust. 3 pkt 4 | `jdg.vat.a77.u3.p4` | — |
| V.328 | ❌ | ⬜ | 78 ust. 4 pkt 1 | `jdg.vat.a78.u4.p1` | — |
| V.329 | ❌ | ⬜ | 78 ust. 5 pkt 2 | `jdg.vat.a78.u5.p2` | — |
| V.330 | ❌ | ⬜ | 78 ust. 1 pkt 3 | `jdg.vat.a78.u1.p3` | — |
| V.331 | ❌ | ⬜ | 78 ust. 2 pkt 4 | `jdg.vat.a78.u2.p4` | — |
| V.332 | ❌ | ⬜ | 79 ust. 3 pkt 1 | `jdg.vat.a79.u3.p1` | — |
| V.333 | ❌ | ⬜ | 79 ust. 4 pkt 2 | `jdg.vat.a79.u4.p2` | — |
| V.334 | ❌ | ⬜ | 79 ust. 5 pkt 3 | `jdg.vat.a79.u5.p3` | — |
| V.335 | ❌ | ⬜ | 79 ust. 1 pkt 4 | `jdg.vat.a79.u1.p4` | — |
| V.336 | ❌ | ⬜ | 80 ust. 2 pkt 1 | `jdg.vat.a80.u2.p1` | — |
| V.337 | ❌ | ⬜ | 80 ust. 3 pkt 2 | `jdg.vat.a80.u3.p2` | — |
| V.338 | ❌ | ⬜ | 80 ust. 4 pkt 3 | `jdg.vat.a80.u4.p3` | — |
| V.339 | ❌ | ⬜ | 80 ust. 5 pkt 4 | `jdg.vat.a80.u5.p4` | — |
| V.340 | ❌ | ⬜ | 81 ust. 1 pkt 1 | `jdg.vat.a81.u1.p1` | — |
| V.341 | ❌ | ⬜ | 81 ust. 2 pkt 2 | `jdg.vat.a81.u2.p2` | — |
| V.342 | ❌ | ⬜ | 81 ust. 3 pkt 3 | `jdg.vat.a81.u3.p3` | — |
| V.343 | ❌ | ⬜ | 81 ust. 4 pkt 4 | `jdg.vat.a81.u4.p4` | — |
| V.344 | ❌ | ⬜ | 82 ust. 5 pkt 1 | `jdg.vat.a82.u5.p1` | — |
| V.345 | ❌ | ⬜ | 82 ust. 1 pkt 2 | `jdg.vat.a82.u1.p2` | — |
| V.346 | ❌ | ⬜ | 82 ust. 2 pkt 3 | `jdg.vat.a82.u2.p3` | — |
| V.347 | ❌ | ⬜ | 82 ust. 3 pkt 4 | `jdg.vat.a82.u3.p4` | — |
| V.348 | ❌ | ⬜ | 83 ust. 4 pkt 1 | `jdg.vat.a83.u4.p1` | — |
| V.349 | ❌ | ⬜ | 83 ust. 5 pkt 2 | `jdg.vat.a83.u5.p2` | — |
| V.350 | ❌ | ⬜ | 83 ust. 1 pkt 3 | `jdg.vat.a83.u1.p3` | — |
| V.1000 | ❌ | ⬜ | 130 ust. 1 pkt 1 | `jdg.vat.a130.u1.p1` | — |
| V.1001 | ❌ | ⬜ | 130 ust. 2 pkt 2 | `jdg.vat.a130.u2.p2` | — |
| V.1002 | ❌ | ⬜ | 130 ust. 3 pkt 3 | `jdg.vat.a130.u3.p3` | — |
| V.1003 | ❌ | ⬜ | 130 ust. 4 pkt 4 | `jdg.vat.a130.u4.p4` | — |
| V.1004 | ❌ | ⬜ | 131 ust. 5 pkt 1 | `jdg.vat.a131.u5.p1` | — |
| V.1005 | ❌ | ⬜ | 131 ust. 1 pkt 2 | `jdg.vat.a131.u1.p2` | — |
| V.1006 | ❌ | ⬜ | 131 ust. 2 pkt 3 | `jdg.vat.a131.u2.p3` | — |
| V.1007 | ❌ | ⬜ | 131 ust. 3 pkt 4 | `jdg.vat.a131.u3.p4` | — |
| V.1008 | ❌ | ⬜ | 132 ust. 4 pkt 1 | `jdg.vat.a132.u4.p1` | — |
| V.1009 | ❌ | ⬜ | 132 ust. 5 pkt 2 | `jdg.vat.a132.u5.p2` | — |
| V.1010 | ❌ | ⬜ | 132 ust. 1 pkt 3 | `jdg.vat.a132.u1.p3` | — |
| V.1011 | ❌ | ⬜ | 132 ust. 2 pkt 4 | `jdg.vat.a132.u2.p4` | — |
| V.1012 | ❌ | ⬜ | 133 ust. 3 pkt 1 | `jdg.vat.a133.u3.p1` | — |
| V.1013 | ❌ | ⬜ | 133 ust. 4 pkt 2 | `jdg.vat.a133.u4.p2` | — |
| V.1014 | ❌ | ⬜ | 133 ust. 5 pkt 3 | `jdg.vat.a133.u5.p3` | — |
| V.1015 | ❌ | ⬜ | 133 ust. 1 pkt 4 | `jdg.vat.a133.u1.p4` | — |
| V.1016 | ❌ | ⬜ | 134 ust. 2 pkt 1 | `jdg.vat.a134.u2.p1` | — |
| V.1017 | ❌ | ⬜ | 134 ust. 3 pkt 2 | `jdg.vat.a134.u3.p2` | — |
| V.1018 | ❌ | ⬜ | 134 ust. 4 pkt 3 | `jdg.vat.a134.u4.p3` | — |
| V.1019 | ❌ | ⬜ | 134 ust. 5 pkt 4 | `jdg.vat.a134.u5.p4` | — |
| V.1020 | ❌ | ⬜ | 135 ust. 1 pkt 1 | `jdg.vat.a135.u1.p1` | — |
| V.1021 | ❌ | ⬜ | 135 ust. 2 pkt 2 | `jdg.vat.a135.u2.p2` | — |
| V.1022 | ❌ | ⬜ | 135 ust. 3 pkt 3 | `jdg.vat.a135.u3.p3` | — |
| V.1023 | ❌ | ⬜ | 135 ust. 4 pkt 4 | `jdg.vat.a135.u4.p4` | — |
| V.1024 | ❌ | ⬜ | 136 ust. 5 pkt 1 | `jdg.vat.a136.u5.p1` | — |
| V.1025 | ❌ | ⬜ | 136 ust. 1 pkt 2 | `jdg.vat.a136.u1.p2` | — |
| V.1026 | ❌ | ⬜ | 136 ust. 2 pkt 3 | `jdg.vat.a136.u2.p3` | — |
| V.1027 | ❌ | ⬜ | 136 ust. 3 pkt 4 | `jdg.vat.a136.u3.p4` | — |
| V.1028 | ❌ | ⬜ | 137 ust. 4 pkt 1 | `jdg.vat.a137.u4.p1` | — |
| V.1029 | ❌ | ⬜ | 137 ust. 5 pkt 2 | `jdg.vat.a137.u5.p2` | — |
| V.1030 | ❌ | ⬜ | 137 ust. 1 pkt 3 | `jdg.vat.a137.u1.p3` | — |
| V.1031 | ❌ | ⬜ | 137 ust. 2 pkt 4 | `jdg.vat.a137.u2.p4` | — |
| V.1032 | ❌ | ⬜ | 138 ust. 3 pkt 1 | `jdg.vat.a138.u3.p1` | — |
| V.1033 | ❌ | ⬜ | 138 ust. 4 pkt 2 | `jdg.vat.a138.u4.p2` | — |
| V.1034 | ❌ | ⬜ | 138 ust. 5 pkt 3 | `jdg.vat.a138.u5.p3` | — |
| V.1035 | ❌ | ⬜ | 138 ust. 1 pkt 4 | `jdg.vat.a138.u1.p4` | — |
| V.1036 | ❌ | ⬜ | 139 ust. 2 pkt 1 | `jdg.vat.a139.u2.p1` | — |
| V.1037 | ❌ | ⬜ | 139 ust. 3 pkt 2 | `jdg.vat.a139.u3.p2` | — |
| V.1038 | ❌ | ⬜ | 139 ust. 4 pkt 3 | `jdg.vat.a139.u4.p3` | — |
| V.1039 | ❌ | ⬜ | 139 ust. 5 pkt 4 | `jdg.vat.a139.u5.p4` | — |
| V.1040 | ❌ | ⬜ | 140 ust. 1 pkt 1 | `jdg.vat.a140.u1.p1` | — |
| V.1041 | ❌ | ⬜ | 140 ust. 2 pkt 2 | `jdg.vat.a140.u2.p2` | — |
| V.1042 | ❌ | ⬜ | 140 ust. 3 pkt 3 | `jdg.vat.a140.u3.p3` | — |
| V.1043 | ❌ | ⬜ | 140 ust. 4 pkt 4 | `jdg.vat.a140.u4.p4` | — |
| V.1044 | ❌ | ⬜ | 141 ust. 5 pkt 1 | `jdg.vat.a141.u5.p1` | — |
| V.1045 | ❌ | ⬜ | 141 ust. 1 pkt 2 | `jdg.vat.a141.u1.p2` | — |
| V.1046 | ❌ | ⬜ | 141 ust. 2 pkt 3 | `jdg.vat.a141.u2.p3` | — |
| V.1047 | ❌ | ⬜ | 141 ust. 3 pkt 4 | `jdg.vat.a141.u3.p4` | — |
| V.1048 | ❌ | ⬜ | 142 ust. 4 pkt 1 | `jdg.vat.a142.u4.p1` | — |
| V.1049 | ❌ | ⬜ | 142 ust. 5 pkt 2 | `jdg.vat.a142.u5.p2` | — |
| V.1050 | ❌ | ⬜ | 142 ust. 1 pkt 3 | `jdg.vat.a142.u1.p3` | — |
| V.1051 | ❌ | ⬜ | 142 ust. 2 pkt 4 | `jdg.vat.a142.u2.p4` | — |
| V.1052 | ❌ | ⬜ | 143 ust. 3 pkt 1 | `jdg.vat.a143.u3.p1` | — |
| V.1053 | ❌ | ⬜ | 143 ust. 4 pkt 2 | `jdg.vat.a143.u4.p2` | — |
| V.1054 | ❌ | ⬜ | 143 ust. 5 pkt 3 | `jdg.vat.a143.u5.p3` | — |
| V.1055 | ❌ | ⬜ | 143 ust. 1 pkt 4 | `jdg.vat.a143.u1.p4` | — |
| V.1056 | ❌ | ⬜ | 144 ust. 2 pkt 1 | `jdg.vat.a144.u2.p1` | — |
| V.1057 | ❌ | ⬜ | 144 ust. 3 pkt 2 | `jdg.vat.a144.u3.p2` | — |
| V.1058 | ❌ | ⬜ | 144 ust. 4 pkt 3 | `jdg.vat.a144.u4.p3` | — |
| V.1059 | ❌ | ⬜ | 144 ust. 5 pkt 4 | `jdg.vat.a144.u5.p4` | — |
| V.1060 | ❌ | ⬜ | 145 ust. 1 pkt 1 | `jdg.vat.a145.u1.p1` | — |
| V.1061 | ❌ | ⬜ | 145 ust. 2 pkt 2 | `jdg.vat.a145.u2.p2` | — |
| V.1062 | ❌ | ⬜ | 145 ust. 3 pkt 3 | `jdg.vat.a145.u3.p3` | — |
| V.1063 | ❌ | ⬜ | 145 ust. 4 pkt 4 | `jdg.vat.a145.u4.p4` | — |
| V.1064 | ❌ | ⬜ | 146 ust. 5 pkt 1 | `jdg.vat.a146.u5.p1` | — |
| V.1065 | ❌ | ⬜ | 146 ust. 1 pkt 2 | `jdg.vat.a146.u1.p2` | — |
| V.1066 | ❌ | ⬜ | 146 ust. 2 pkt 3 | `jdg.vat.a146.u2.p3` | — |
| V.1067 | ❌ | ⬜ | 146 ust. 3 pkt 4 | `jdg.vat.a146.u3.p4` | — |
| V.1068 | ❌ | ⬜ | 147 ust. 4 pkt 1 | `jdg.vat.a147.u4.p1` | — |
| V.1069 | ❌ | ⬜ | 147 ust. 5 pkt 2 | `jdg.vat.a147.u5.p2` | — |
| V.1070 | ❌ | ⬜ | 147 ust. 1 pkt 3 | `jdg.vat.a147.u1.p3` | — |
| V.1071 | ❌ | ⬜ | 147 ust. 2 pkt 4 | `jdg.vat.a147.u2.p4` | — |
| V.1072 | ❌ | ⬜ | 148 ust. 3 pkt 1 | `jdg.vat.a148.u3.p1` | — |
| V.1073 | ❌ | ⬜ | 148 ust. 4 pkt 2 | `jdg.vat.a148.u4.p2` | — |
| V.1074 | ❌ | ⬜ | 148 ust. 5 pkt 3 | `jdg.vat.a148.u5.p3` | — |
| V.1075 | ❌ | ⬜ | 148 ust. 1 pkt 4 | `jdg.vat.a148.u1.p4` | — |
| V.1076 | ❌ | ⬜ | 149 ust. 2 pkt 1 | `jdg.vat.a149.u2.p1` | — |
| V.1077 | ❌ | ⬜ | 149 ust. 3 pkt 2 | `jdg.vat.a149.u3.p2` | — |
| V.1078 | ❌ | ⬜ | 149 ust. 4 pkt 3 | `jdg.vat.a149.u4.p3` | — |
| V.1079 | ❌ | ⬜ | 149 ust. 5 pkt 4 | `jdg.vat.a149.u5.p4` | — |
| V.1080 | ❌ | ⬜ | 150 ust. 1 pkt 1 | `jdg.vat.a150.u1.p1` | — |
| V.1081 | ❌ | ⬜ | 150 ust. 2 pkt 2 | `jdg.vat.a150.u2.p2` | — |
| V.1082 | ❌ | ⬜ | 150 ust. 3 pkt 3 | `jdg.vat.a150.u3.p3` | — |
| V.1083 | ❌ | ⬜ | 150 ust. 4 pkt 4 | `jdg.vat.a150.u4.p4` | — |
| V.1084 | ❌ | ⬜ | 151 ust. 5 pkt 1 | `jdg.vat.a151.u5.p1` | — |
| V.1085 | ❌ | ⬜ | 151 ust. 1 pkt 2 | `jdg.vat.a151.u1.p2` | — |
| V.1086 | ❌ | ⬜ | 151 ust. 2 pkt 3 | `jdg.vat.a151.u2.p3` | — |
| V.1087 | ❌ | ⬜ | 151 ust. 3 pkt 4 | `jdg.vat.a151.u3.p4` | — |
| V.1088 | ❌ | ⬜ | 152 ust. 4 pkt 1 | `jdg.vat.a152.u4.p1` | — |
| V.1089 | ❌ | ⬜ | 152 ust. 5 pkt 2 | `jdg.vat.a152.u5.p2` | — |
| V.1090 | ❌ | ⬜ | 152 ust. 1 pkt 3 | `jdg.vat.a152.u1.p3` | — |
| V.1091 | ❌ | ⬜ | 152 ust. 2 pkt 4 | `jdg.vat.a152.u2.p4` | — |
| V.1092 | ❌ | ⬜ | 153 ust. 3 pkt 1 | `jdg.vat.a153.u3.p1` | — |
| V.1093 | ❌ | ⬜ | 153 ust. 4 pkt 2 | `jdg.vat.a153.u4.p2` | — |
| V.1094 | ❌ | ⬜ | 153 ust. 5 pkt 3 | `jdg.vat.a153.u5.p3` | — |
| V.1095 | ❌ | ⬜ | 153 ust. 1 pkt 4 | `jdg.vat.a153.u1.p4` | — |
| V.1096 | ❌ | ⬜ | 154 ust. 2 pkt 1 | `jdg.vat.a154.u2.p1` | — |
| V.1097 | ❌ | ⬜ | 154 ust. 3 pkt 2 | `jdg.vat.a154.u3.p2` | — |
| V.1098 | ❌ | ⬜ | 154 ust. 4 pkt 3 | `jdg.vat.a154.u4.p3` | — |
| V.1099 | ❌ | ⬜ | 154 ust. 5 pkt 4 | `jdg.vat.a154.u5.p4` | — |
| V.1100 | ❌ | ⬜ | 155 ust. 1 pkt 1 | `jdg.vat.a155.u1.p1` | — |
| V.1101 | ❌ | ⬜ | 155 ust. 2 pkt 2 | `jdg.vat.a155.u2.p2` | — |
| V.1102 | ❌ | ⬜ | 155 ust. 3 pkt 3 | `jdg.vat.a155.u3.p3` | — |
| V.1103 | ❌ | ⬜ | 155 ust. 4 pkt 4 | `jdg.vat.a155.u4.p4` | — |
| V.1104 | ❌ | ⬜ | 156 ust. 5 pkt 1 | `jdg.vat.a156.u5.p1` | — |
| V.1105 | ❌ | ⬜ | 156 ust. 1 pkt 2 | `jdg.vat.a156.u1.p2` | — |
| V.1106 | ❌ | ⬜ | 156 ust. 2 pkt 3 | `jdg.vat.a156.u2.p3` | — |
| V.1107 | ❌ | ⬜ | 156 ust. 3 pkt 4 | `jdg.vat.a156.u3.p4` | — |
| V.1108 | ❌ | ⬜ | 157 ust. 4 pkt 1 | `jdg.vat.a157.u4.p1` | — |
| V.1109 | ❌ | ⬜ | 157 ust. 5 pkt 2 | `jdg.vat.a157.u5.p2` | — |
| V.1110 | ❌ | ⬜ | 157 ust. 1 pkt 3 | `jdg.vat.a157.u1.p3` | — |
| V.1111 | ❌ | ⬜ | 157 ust. 2 pkt 4 | `jdg.vat.a157.u2.p4` | — |
| V.1112 | ❌ | ⬜ | 158 ust. 3 pkt 1 | `jdg.vat.a158.u3.p1` | — |
| V.1113 | ❌ | ⬜ | 158 ust. 4 pkt 2 | `jdg.vat.a158.u4.p2` | — |
| V.1114 | ❌ | ⬜ | 158 ust. 5 pkt 3 | `jdg.vat.a158.u5.p3` | — |
| V.1115 | ❌ | ⬜ | 158 ust. 1 pkt 4 | `jdg.vat.a158.u1.p4` | — |
| V.1116 | ❌ | ⬜ | 159 ust. 2 pkt 1 | `jdg.vat.a159.u2.p1` | — |
| V.1117 | ❌ | ⬜ | 159 ust. 3 pkt 2 | `jdg.vat.a159.u3.p2` | — |
| V.1118 | ❌ | ⬜ | 159 ust. 4 pkt 3 | `jdg.vat.a159.u4.p3` | — |
| V.1119 | ❌ | ⬜ | 159 ust. 5 pkt 4 | `jdg.vat.a159.u5.p4` | — |
| V.1120 | ❌ | ⬜ | 160 ust. 1 pkt 1 | `jdg.vat.a160.u1.p1` | — |
| V.1121 | ❌ | ⬜ | 160 ust. 2 pkt 2 | `jdg.vat.a160.u2.p2` | — |
| V.1122 | ❌ | ⬜ | 160 ust. 3 pkt 3 | `jdg.vat.a160.u3.p3` | — |
| V.1123 | ❌ | ⬜ | 160 ust. 4 pkt 4 | `jdg.vat.a160.u4.p4` | — |
| V.1124 | ❌ | ⬜ | 161 ust. 5 pkt 1 | `jdg.vat.a161.u5.p1` | — |
| V.1125 | ❌ | ⬜ | 161 ust. 1 pkt 2 | `jdg.vat.a161.u1.p2` | — |
| V.1126 | ❌ | ⬜ | 161 ust. 2 pkt 3 | `jdg.vat.a161.u2.p3` | — |
| V.1127 | ❌ | ⬜ | 161 ust. 3 pkt 4 | `jdg.vat.a161.u3.p4` | — |
| V.1128 | ❌ | ⬜ | 162 ust. 4 pkt 1 | `jdg.vat.a162.u4.p1` | — |
| V.1129 | ❌ | ⬜ | 162 ust. 5 pkt 2 | `jdg.vat.a162.u5.p2` | — |
| V.1130 | ❌ | ⬜ | 162 ust. 1 pkt 3 | `jdg.vat.a162.u1.p3` | — |
| V.1131 | ❌ | ⬜ | 162 ust. 2 pkt 4 | `jdg.vat.a162.u2.p4` | — |
| V.1132 | ❌ | ⬜ | 163 ust. 3 pkt 1 | `jdg.vat.a163.u3.p1` | — |
| V.1133 | ❌ | ⬜ | 163 ust. 4 pkt 2 | `jdg.vat.a163.u4.p2` | — |
| V.1134 | ❌ | ⬜ | 163 ust. 5 pkt 3 | `jdg.vat.a163.u5.p3` | — |
| V.1135 | ❌ | ⬜ | 163 ust. 1 pkt 4 | `jdg.vat.a163.u1.p4` | — |
| V.1136 | ❌ | ⬜ | 164 ust. 2 pkt 1 | `jdg.vat.a164.u2.p1` | — |
| V.1137 | ❌ | ⬜ | 164 ust. 3 pkt 2 | `jdg.vat.a164.u3.p2` | — |
| V.1138 | ❌ | ⬜ | 164 ust. 4 pkt 3 | `jdg.vat.a164.u4.p3` | — |
| V.1139 | ❌ | ⬜ | 164 ust. 5 pkt 4 | `jdg.vat.a164.u5.p4` | — |
| V.1140 | ❌ | ⬜ | 165 ust. 1 pkt 1 | `jdg.vat.a165.u1.p1` | — |
| V.1141 | ❌ | ⬜ | 165 ust. 2 pkt 2 | `jdg.vat.a165.u2.p2` | — |
| V.1142 | ❌ | ⬜ | 165 ust. 3 pkt 3 | `jdg.vat.a165.u3.p3` | — |
| V.1143 | ❌ | ⬜ | 165 ust. 4 pkt 4 | `jdg.vat.a165.u4.p4` | — |
| V.1144 | ❌ | ⬜ | 166 ust. 5 pkt 1 | `jdg.vat.a166.u5.p1` | — |
| V.1145 | ❌ | ⬜ | 166 ust. 1 pkt 2 | `jdg.vat.a166.u1.p2` | — |
| V.1146 | ❌ | ⬜ | 166 ust. 2 pkt 3 | `jdg.vat.a166.u2.p3` | — |
| V.1147 | ❌ | ⬜ | 166 ust. 3 pkt 4 | `jdg.vat.a166.u3.p4` | — |
| V.1148 | ❌ | ⬜ | 167 ust. 4 pkt 1 | `jdg.vat.a167.u4.p1` | — |
| V.1149 | ❌ | ⬜ | 167 ust. 5 pkt 2 | `jdg.vat.a167.u5.p2` | — |
| V.1150 | ❌ | ⬜ | 167 ust. 1 pkt 3 | `jdg.vat.a167.u1.p3` | — |
| V.1151 | ❌ | ⬜ | 167 ust. 2 pkt 4 | `jdg.vat.a167.u2.p4` | — |
| V.1152 | ❌ | ⬜ | 168 ust. 3 pkt 1 | `jdg.vat.a168.u3.p1` | — |
| V.1153 | ❌ | ⬜ | 168 ust. 4 pkt 2 | `jdg.vat.a168.u4.p2` | — |
| V.1154 | ❌ | ⬜ | 168 ust. 5 pkt 3 | `jdg.vat.a168.u5.p3` | — |
| V.1155 | ❌ | ⬜ | 168 ust. 1 pkt 4 | `jdg.vat.a168.u1.p4` | — |
| V.1156 | ❌ | ⬜ | 169 ust. 2 pkt 1 | `jdg.vat.a169.u2.p1` | — |
| V.1157 | ❌ | ⬜ | 169 ust. 3 pkt 2 | `jdg.vat.a169.u3.p2` | — |
| V.1158 | ❌ | ⬜ | 169 ust. 4 pkt 3 | `jdg.vat.a169.u4.p3` | — |
| V.1159 | ❌ | ⬜ | 169 ust. 5 pkt 4 | `jdg.vat.a169.u5.p4` | — |
| V.1160 | ❌ | ⬜ | 170 ust. 1 pkt 1 | `jdg.vat.a170.u1.p1` | — |
| V.1161 | ❌ | ⬜ | 170 ust. 2 pkt 2 | `jdg.vat.a170.u2.p2` | — |
| V.1162 | ❌ | ⬜ | 170 ust. 3 pkt 3 | `jdg.vat.a170.u3.p3` | — |
| V.1163 | ❌ | ⬜ | 170 ust. 4 pkt 4 | `jdg.vat.a170.u4.p4` | — |
| V.1164 | ❌ | ⬜ | 171 ust. 5 pkt 1 | `jdg.vat.a171.u5.p1` | — |
| V.1165 | ❌ | ⬜ | 171 ust. 1 pkt 2 | `jdg.vat.a171.u1.p2` | — |
| V.1166 | ❌ | ⬜ | 171 ust. 2 pkt 3 | `jdg.vat.a171.u2.p3` | — |
| V.1167 | ❌ | ⬜ | 171 ust. 3 pkt 4 | `jdg.vat.a171.u3.p4` | — |
| V.1168 | ❌ | ⬜ | 172 ust. 4 pkt 1 | `jdg.vat.a172.u4.p1` | — |

---

## 📊 Podsumowanie wg statusu


### ✅ Pokryte przez reguły JDG:

- **Łącznie zmapowanych reguł Rego:** 44
- **Unikalne rule_id w JDG/rules:** 6 614
- **Pliki Rego z matched:true:** 163

---

*Raport wygenerowany automatycznie przez `JDG/generate_coverage_report.py`*
