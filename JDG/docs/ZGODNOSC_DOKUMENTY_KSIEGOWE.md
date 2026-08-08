# 🧾 ZGODNOŚĆ Z DOKUMENTAMI KSIĘGOWYMI — P02 (sekcja 6)

> Wygenerowano: 2026-08-08T12:11:27.405613+00:00 · generator: `accounting_docs_compliance.py`

| Dokument | Element | Status | Reguły |
|---|---|---|---|
| UoR | Art. 2 — definicje | **COMPLETE** | jdg.security.fortress.small_taxpayer_distinction |
| UoR | Art. 4 — zasady rachunkowości | **COMPLETE** | jdg.uor_live.accounting_principles_check, jdg.ksef_jpk.ksef_duplicate_detected, jdg.ord.innovations.uor_accounting_principles, jdg.p35.uor_foundations_check, jdg.risk.counterparty_trust_low |
| UoR | Art. 20–22 — księgi rachunkowe | **COMPLETE** | jdg.uor_live.accounting_document_validation, jdg.jpk_kr_st.no_match, jdg.jpk_kr_st.kr_eligibility_check, jdg.micro.budownictwo.a5.r8, jdg.ord.innovations.uor_double_entry_validator |
| UoR | Art. 26 — wycena aktywów | **COMPLETE** | jdg.uor_live.asset_valuation_check, jdg.ord.innovations.uor_asset_valuation, jdg.p12_innovations.asset_valuation_engine |
| UoR | Art. 28 — wycena bilansowa | **COMPLETE** | jdg.edge_cases.fx_method_podatkowa_vs_bilansowa, jdg.p33_uor_supplement.art46_balance_sheet |
| UoR | Art. 32 — amortyzacja | **COMPLETE** | jdg.p33_uor_supplement.art32_33_uor_vs_pit_depreciation, jdg.p34.depreciation_uor_vs_pit_split |
| UoR | Art. 74 — dokumentacja | **GAP** | — |
| PKPiR | Kolumna 1 | **GAP** | — |
| PKPiR | Kolumna 2 | **GAP** | — |
| PKPiR | Kolumna 3 | **GAP** | — |
| PKPiR | Kolumna 4 | **GAP** | — |
| PKPiR | Kolumna 5 | **GAP** | — |
| PKPiR | Kolumna 6 | **GAP** | — |
| PKPiR | Kolumna 7 | **GAP** | — |
| PKPiR | Kolumna 8 | **GAP** | — |
| PKPiR | Kolumna 9 | **GAP** | — |
| PKPiR | Kolumna 10 | **GAP** | — |
| PKPiR | Kolumna 11 | **GAP** | — |
| PKPiR | Kolumna 12 | **GAP** | — |
| PKPiR | Kolumna 13 | **GAP** | — |
| PKPiR | Kolumna 14 | **GAP** | — |
| PKPiR | Kolumna 15 | **GAP** | — |
| PKPiR | Kolumna 16 | **GAP** | — |
| PKPiR | Kolumna 17 | **GAP** | — |
| JPK_V7M | Sekcja ewidencja sprzedaży | **GAP** | — |
| JPK_V7M | Sekcja ewidencja zakupów | **GAP** | — |
| JPK_V7M | GTU (grupy towarów) | **COMPLETE** | jdg.cross_validator.ceidg_vs_jpk_pkd, jdg.gtu_checker.no_match, jdg.gtu_checker.completeness_audit, jdg.hyper.audit.wis.gtu.mapping_obligation, jdg.jpk_v7.gtu_code_autoassignment |
| JPK_V7K | Ewidencja sprzedaży | **COMPLETE** | jdg.jpk_v7.v7k_quarterly_support, jdg.p17_ksef_jpk_edeklaracje_innovations.jpk_v7_auto_generator |
| JPK_V7K | Ewidencja zakupów | **GAP** | — |
| PIT-36 | Skala podatkowa | **GAP** | — |
| PIT-36 | Dochód z działalności | **GAP** | — |
| PIT-36L | Podatek liniowy 19% | **GAP** | — |
| PIT-28 | Ryczałt od przychodów | **GAP** | — |
| VAT-7 | Deklaracja VAT-7 | **GAP** | — |
| VAT-7K | Deklaracja VAT-7K (kwartalna) | **GAP** | — |
| VAT-UE | Informacja podsumowująca VAT-UE | **GAP** | — |
| PCC-3 | Deklaracja PCC-3 | **COMPLETE** | jdg.p33_pcc_complete.pcc3_auto_filler |
| ZUS DRA | Deklaracja rozliczeniowa ZUS DRA | **COMPLETE** | jdg.employer.zus_dra_monthly, jdg.hyper.deadlines.tax.zus_dra_10th, jdg.p07_zus_macro_innovations.dra_optimizer, jdg.zus.dra_filing_deadline_check |
| ZUS ZUA | Zgłoszenie ubezpieczonego ZUS ZUA | **COMPLETE** | jdg.employer.zus_zua_registration, jdg.autoform.zus_zua_autofill |

*Status: COMPLETE = reguły implementujące istnieją w rejestrze; GAP = brak reguł (do domknięcia w P09/P04/P17).*
