# 📐 CANONICAL COVERAGE REPORT — JDG (AD-01)

> **Generowane:** 2026-08-30T14:06:13+00:00 · narzędzie: `tools/coverage_unifier.py`
> **Zasada:** jedna metryka kanoniczna (LCI na węzłach LKG), jawne mianowniki,
> data pomiaru, rozróżnienie reguła dowodna ↔ szkielet.

## Metryki kanoniczne

| Metryka | Wartość | Mianownik |
|---|---|---|
| **LCI** (Legal Coverage Index) | **100.0%** | 70/70 węzłów materialnych |
| **TCL** (Traceability Completeness) | **100.0%** | 11127/11127 reguł dowodnych |
| **RV** (Rule Validity) | **100.0%** | 11127/(11127+0) |
| **UVR** (Unverified Rules) | **11125** | reguły dowodne bez natywnego testu Rego |
| DOC50 (archiwalny) | None% | punkty Doc 50 — inny byt, nieporównywalny |
| STRUCT (MANIFEST) | 91/100 | bloki matched:true — inny byt, nieporównywalny |

## Rekoncyliacja

DOC50 (punkty Doc 50), LCI (węzły LKG) i STRUCT (bloki matched:true) mierzą RÓŻNE byty i nie są porównywalne wprost. LCI jest metryką kanoniczną: materialne węzły prawne pokryte dowodną regułą.
- COVERAGE_REPORT.md liczy punkty prawne z planu Doc 50 (archiwalny).
- MANIFEST.md liczy bloki matched:true (struktura, nie prawo).

## Struktura reguł

| Kategoria | Liczba |
|---|---:|
| Reguły łącznie | 11591 |
| no_match / fallback | 464 |
| Do decyzji (actionable) | 11127 |
| **Dowodne** (matched + _legal_basis) | **11127** |
| Szkielety (matched bez podstawy) | 0 |
| Bez testu natywnego Rego | 11125 |

## Pokrycie wg domeny

| Domena | Reguły dowodne | Szkielety | Węzły LKG pokryte |
|---|---|---:|---:|
| adaptive_trust | 3 | 0 | 0/0 (0%) |
| advertising | 46 | 0 | 0/0 (0%) |
| agricultural_tax | 5 | 0 | 0/0 (0%) |
| akcyza | 70 | 0 | 0/0 (0%) |
| allowances | 27 | 0 | 0/0 (0%) |
| aml | 45 | 0 | 0/0 (0%) |
| aml_cbdd | 5 | 0 | 0/0 (0%) |
| aml_full | 80 | 0 | 0/0 (0%) |
| aml_ryzyko | 7 | 0 | 0/0 (0%) |
| aml_str_gif | 7 | 0 | 0/0 (0%) |
| aml_transakcje | 6 | 0 | 0/0 (0%) |
| amort_a22a | 9 | 0 | 0/0 (0%) |
| amort_a22b | 6 | 0 | 0/0 (0%) |
| amort_a22c | 6 | 0 | 0/0 (0%) |
| amort_a22h | 6 | 0 | 0/0 (0%) |
| amort_a22i | 8 | 0 | 0/0 (0%) |
| amort_a22k | 6 | 0 | 0/0 (0%) |
| amort_a22n | 6 | 0 | 0/0 (0%) |
| annual_decl | 6 | 0 | 0/0 (0%) |
| api_fallback | 6 | 0 | 0/0 (0%) |
| api_ui | 1 | 0 | 0/0 (0%) |
| audit | 70 | 0 | 0/0 (0%) |
| audit_defense | 4 | 0 | 0/0 (0%) |
| banking | 14 | 0 | 0/0 (0%) |
| bdo_ewc | 7 | 0 | 0/0 (0%) |
| bdo_ewidencja | 8 | 0 | 0/0 (0%) |
| bdo_rejestracja | 8 | 0 | 0/0 (0%) |
| bdo_transport | 6 | 0 | 0/0 (0%) |
| bdo_weee | 5 | 0 | 0/0 (0%) |
| bdo_zezwolenia | 6 | 0 | 0/0 (0%) |
| budownictwo | 64 | 0 | 0/0 (0%) |
| bundles | 1 | 0 | 0/0 (0%) |
| business | 391 | 0 | 10/10 (100.0%) |
| business_lifecycle_etap18 | 1 | 0 | 0/0 (0%) |
| calendar | 41 | 0 | 0/0 (0%) |
| cb | 140 | 0 | 0/0 (0%) |
| cfc | 1 | 0 | 0/0 (0%) |
| compliance | 10 | 0 | 0/0 (0%) |
| conflict_declaration | 3 | 0 | 0/0 (0%) |
| conflicts | 27 | 0 | 0/0 (0%) |
| conviction | 36 | 0 | 0/0 (0%) |
| corrections | 19 | 0 | 0/0 (0%) |
| cross_domain_red_team_etap27 | 1 | 0 | 0/0 (0%) |
| crossborder | 114 | 0 | 0/0 (0%) |
| crossborder_etap17 | 1 | 0 | 0/0 (0%) |
| decision_core_completeness | 5 | 0 | 0/0 (0%) |
| docs | 1 | 0 | 0/0 (0%) |
| edelivery | 49 | 0 | 0/0 (0%) |
| edge_cases | 187 | 0 | 0/0 (0%) |
| employer | 27 | 0 | 0/0 (0%) |
| enterprise | 1 | 0 | 0/0 (0%) |
| enterprise_ai_neural_etap23 | 1 | 0 | 0/0 (0%) |
| environmental | 36 | 0 | 0/0 (0%) |
| epuap | 3 | 0 | 0/0 (0%) |
| esig | 43 | 0 | 0/0 (0%) |
| esig_auto | 4 | 0 | 0/0 (0%) |
| est | 15 | 0 | 0/0 (0%) |
| exit_tax | 8 | 0 | 0/0 (0%) |
| exit_tax_cfc | 16 | 0 | 0/0 (0%) |
| family | 61 | 0 | 0/0 (0%) |
| final | 51 | 0 | 0/0 (0%) |
| final_certification_etap28 | 1 | 0 | 0/0 (0%) |
| force_majeure | 40 | 0 | 0/0 (0%) |
| form_optimizer | 5 | 0 | 0/0 (0%) |
| form_transition | 5 | 0 | 0/0 (0%) |
| fx | 56 | 0 | 0/0 (0%) |
| gaar | 1 | 0 | 0/0 (0%) |
| gaar_shield | 2 | 0 | 0/0 (0%) |
| gtu_checker | 3 | 0 | 0/0 (0%) |
| health | 40 | 0 | 0/0 (0%) |
| hyper | 490 | 0 | 0/0 (0%) |
| hyper_enterprise_contexts_etap22 | 1 | 0 | 0/0 (0%) |
| insurance | 34 | 0 | 0/0 (0%) |
| interest_calculator | 3 | 0 | 0/0 (0%) |
| international | 39 | 0 | 0/0 (0%) |
| jpk_cit | 4 | 0 | 0/0 (0%) |
| jpk_corrections | 3 | 0 | 0/0 (0%) |
| jpk_kr_st | 4 | 0 | 0/0 (0%) |
| jpk_v7 | 7 | 0 | 0/0 (0%) |
| judicial | 5 | 0 | 0/0 (0%) |
| kks | 873 | 0 | 0/0 (0%) |
| kks_ord_etap16 | 1 | 0 | 0/0 (0%) |
| ksef | 269 | 0 | 0/0 (0%) |
| ksef_firewall | 3 | 0 | 0/0 (0%) |
| ksef_innovations | 5 | 0 | 0/0 (0%) |
| ksef_jpk_etap20 | 1 | 0 | 0/0 (0%) |
| ksef_offline_queue | 3 | 0 | 0/0 (0%) |
| ksef_outbox | 4 | 0 | 0/0 (0%) |
| ksef_receipt_digest | 3 | 0 | 0/0 (0%) |
| ksef_resilience | 7 | 0 | 0/0 (0%) |
| ksef_sanction_monitor | 2 | 0 | 0/0 (0%) |
| ksef_sandbox | 3 | 0 | 0/0 (0%) |
| ksef_upo_tracker | 3 | 0 | 0/0 (0%) |
| leasing | 3 | 0 | 0/0 (0%) |
| legislative | 5 | 0 | 0/0 (0%) |
| liability | 15 | 0 | 0/0 (0%) |
| lifecycle | 4 | 0 | 0/0 (0%) |
| limitations | 18 | 0 | 0/0 (0%) |
| local | 45 | 0 | 0/0 (0%) |
| local_excise_etap19 | 1 | 0 | 0/0 (0%) |
| local_taxes | 63 | 0 | 0/0 (0%) |
| mdr | 99 | 0 | 0/0 (0%) |
| mdr_dac6 | 3 | 0 | 0/0 (0%) |
| meta | 3 | 0 | 0/0 (0%) |
| mpips | 12 | 0 | 0/0 (0%) |
| neural_mesh | 19 | 0 | 0/0 (0%) |
| neural_mesh_v2 | 15 | 0 | 0/0 (0%) |
| nkup | 59 | 0 | 0/0 (0%) |
| ordpu | 640 | 0 | 4/4 (100.0%) |
| overpayment_claimer | 2 | 0 | 0/0 (0%) |
| p01_fundament_innovations | 1 | 0 | 0/0 (0%) |
| p01_innovations | 7 | 0 | 0/0 (0%) |
| p02_decision_core_innovations | 1 | 0 | 0/0 (0%) |
| p02_innovations | 7 | 0 | 0/0 (0%) |
| p03_innovations | 7 | 0 | 0/0 (0%) |
| p03_orchestrator_innovations | 1 | 0 | 0/0 (0%) |
| p03_vat_macro_innovations | 1 | 0 | 0/0 (0%) |
| p04_innovations | 7 | 0 | 0/0 (0%) |
| p04_vat_macro_enterprise | 1 | 0 | 0/0 (0%) |
| p04_vat_micro_innovations | 1 | 0 | 0/0 (0%) |
| p05 | 29 | 0 | 0/0 (0%) |
| p05_innovations | 1 | 0 | 0/0 (0%) |
| p05_pit_macro_innovations | 1 | 0 | 0/0 (0%) |
| p05_vat_micro_atomic | 1 | 0 | 0/0 (0%) |
| p06_innovations | 34 | 0 | 0/0 (0%) |
| p06_pit_macro_enterprise | 1 | 0 | 0/0 (0%) |
| p06_pit_micro_innovations | 1 | 0 | 0/0 (0%) |
| p07_innovations | 19 | 0 | 0/0 (0%) |
| p07_pit_micro_atomic | 1 | 0 | 0/0 (0%) |
| p07_zus_macro_innovations | 1 | 0 | 0/0 (0%) |
| p08_innovations | 15 | 0 | 0/0 (0%) |
| p08_zus_macro_enterprise | 1 | 0 | 0/0 (0%) |
| p08_zus_micro_innovations | 1 | 0 | 0/0 (0%) |
| p09_innovations | 14 | 0 | 0/0 (0%) |
| p09_ksiegowosc_pkpir_uor_innovations | 1 | 0 | 0/0 (0%) |
| p10_innovations | 11 | 0 | 0/0 (0%) |
| p10_kks_innovations | 1 | 0 | 0/0 (0%) |
| p11_innovations | 13 | 0 | 0/0 (0%) |
| p11_ordynacja_podatkowa_innovations | 1 | 0 | 0/0 (0%) |
| p12_crossborder_innovations | 1 | 0 | 0/0 (0%) |
| p12_innovations | 1 | 0 | 0/0 (0%) |
| p13_innovations | 1 | 0 | 0/0 (0%) |
| p13_ryczalt_cykl_zycia_innovations | 1 | 0 | 0/0 (0%) |
| p14_pcc_lokalne_akcyza_innovations | 1 | 0 | 0/0 (0%) |
| p15_innovations | 1 | 0 | 0/0 (0%) |
| p15_srodowisko_bdo_innovations | 1 | 0 | 0/0 (0%) |
| p16_innovations | 1 | 0 | 0/0 (0%) |
| p16_rodo_aml_security_innovations | 1 | 0 | 0/0 (0%) |
| p17_ksef_jpk_edeklaracje_innovations | 1 | 0 | 0/0 (0%) |
| p18_automatyzacja_ksiegowosci_innovations | 1 | 0 | 0/0 (0%) |
| p19_hr_swiadczenia_innovations | 1 | 0 | 0/0 (0%) |
| p20_neural_mesh_innovations | 1 | 0 | 0/0 (0%) |
| p21_innovations | 48 | 0 | 0/0 (0%) |
| p21_opa_system_innovations | 1 | 0 | 0/0 (0%) |
| p22_innovations | 48 | 0 | 0/0 (0%) |
| p22_validation_tools_innovations | 1 | 0 | 0/0 (0%) |
| p23_innovations | 20 | 0 | 0/0 (0%) |
| p23_test_rego_ci_innovations | 1 | 0 | 0/0 (0%) |
| p24 | 29 | 0 | 0/0 (0%) |
| p24_audyt_kompletny_innovations | 1 | 0 | 0/0 (0%) |
| p24_innovations | 28 | 0 | 0/0 (0%) |
| p34 | 13 | 0 | 0/0 (0%) |
| p34_innovations | 15 | 0 | 0/0 (0%) |
| p35 | 19 | 0 | 0/0 (0%) |
| p35_innovations | 15 | 0 | 0/0 (0%) |
| payments | 59 | 0 | 0/0 (0%) |
| pcc | 236 | 0 | 0/0 (0%) |
| pcc_akc | 100 | 0 | 0/0 (0%) |
| pcc_lokalne_atomic_p14 | 18 | 0 | 0/0 (0%) |
| pit | 1448 | 0 | 26/26 (100.0%) |
| pit_macro_etap10 | 1 | 0 | 0/0 (0%) |
| pit_micro_reliefs_etap11 | 1 | 0 | 0/0 (0%) |
| pkpir | 13 | 0 | 0/0 (0%) |
| pkpir_columns | 11 | 0 | 0/0 (0%) |
| pkpir_corrections | 8 | 0 | 0/0 (0%) |
| pkpir_costs | 10 | 0 | 0/0 (0%) |
| pkpir_etap14 | 1 | 0 | 0/0 (0%) |
| pkpir_nkup | 10 | 0 | 0/0 (0%) |
| pkpir_remnant | 8 | 0 | 0/0 (0%) |
| pkpir_revenue | 10 | 0 | 0/0 (0%) |
| poa_manager | 2 | 0 | 0/0 (0%) |
| policies_mirror_sync_etap26 | 1 | 0 | 0/0 (0%) |
| ppk_pfron | 7 | 0 | 0/0 (0%) |
| proceeding_tracker | 2 | 0 | 0/0 (0%) |
| procurement | 45 | 0 | 0/0 (0%) |
| prop | 30 | 0 | 0/0 (0%) |
| prop_transport | 5 | 0 | 0/0 (0%) |
| r01_orchestrator_core_innovations | 1 | 0 | 0/0 (0%) |
| r02_vat_core_innovations | 1 | 0 | 0/0 (0%) |
| r03_vat_micro_innovations | 1 | 0 | 0/0 (0%) |
| r04_pit_core_innovations | 1 | 0 | 0/0 (0%) |
| r05_pit_enterprise_innovations | 1 | 0 | 0/0 (0%) |
| r06_zus_innovations | 1 | 0 | 0/0 (0%) |
| r07_kks_innovations | 1 | 0 | 0/0 (0%) |
| r08_ordynacja_obrona_innovations | 5 | 0 | 0/0 (0%) |
| r09_ksiegowosc_pkpir_uor_innovations | 5 | 0 | 0/0 (0%) |
| r10_crossborder_innovations | 5 | 0 | 0/0 (0%) |
| r11_pcc_lokalne_akcyza_innovations | 5 | 0 | 0/0 (0%) |
| r12_ryczalt_cykl_zycia_innovations | 5 | 0 | 0/0 (0%) |
| r13_hyper_konteksty_innovations | 5 | 0 | 0/0 (0%) |
| r14_rodo_aml_bdo_innovations | 5 | 0 | 0/0 (0%) |
| r15_ksef_jpk_edeklaracje_innovations | 5 | 0 | 0/0 (0%) |
| r16_system_opa_innovations | 5 | 0 | 0/0 (0%) |
| r17_enterprise_ai_innovations | 5 | 0 | 0/0 (0%) |
| regulated | 40 | 0 | 0/0 (0%) |
| reliability_guarantee | 4 | 0 | 0/0 (0%) |
| residency | 59 | 0 | 0/0 (0%) |
| restructuring | 12 | 0 | 0/0 (0%) |
| retention | 13 | 0 | 0/0 (0%) |
| risk | 21 | 0 | 0/0 (0%) |
| rodo | 65 | 0 | 0/0 (0%) |
| rodo_ai_marketing | 5 | 0 | 0/0 (0%) |
| rodo_aml_bdo_atomic_p15 | 17 | 0 | 0/0 (0%) |
| rodo_aml_bdo_hr_etap21 | 1 | 0 | 0/0 (0%) |
| rodo_erasure | 4 | 0 | 0/0 (0%) |
| rodo_extended | 16 | 0 | 0/0 (0%) |
| rodo_podprocesorzy | 4 | 0 | 0/0 (0%) |
| rodo_sankcje | 5 | 0 | 0/0 (0%) |
| rodo_zatrudnienie | 4 | 0 | 0/0 (0%) |
| routing | 5 | 0 | 0/0 (0%) |
| rule_lifecycle | 4 | 0 | 0/0 (0%) |
| ryc | 208 | 0 | 0/0 (0%) |
| ryczalt | 105 | 0 | 0/0 (0%) |
| ryczalt_cykl_atomic_p13 | 20 | 0 | 0/0 (0%) |
| sanctions | 4 | 0 | 0/0 (0%) |
| seasonal | 35 | 0 | 0/0 (0%) |
| security | 19 | 0 | 0/0 (0%) |
| solidarity | 33 | 0 | 0/0 (0%) |
| srodowisko | 48 | 0 | 0/0 (0%) |
| statute | 9 | 0 | 0/0 (0%) |
| strategic | 8 | 0 | 0/0 (0%) |
| succ | 20 | 0 | 0/0 (0%) |
| tax_interaction | 6 | 0 | 0/0 (0%) |
| tax_opt | 10 | 0 | 0/0 (0%) |
| tax_trans | 15 | 0 | 0/0 (0%) |
| taxfree | 44 | 0 | 0/0 (0%) |
| temporal | 29 | 0 | 0/0 (0%) |
| tests_ci | 1 | 0 | 0/0 (0%) |
| tests_ci_quality_etap24 | 1 | 0 | 0/0 (0%) |
| tools | 1 | 0 | 0/0 (0%) |
| tools_api_rulestore_bundles_etap25 | 1 | 0 | 0/0 (0%) |
| tp | 79 | 0 | 0/0 (0%) |
| transport | 44 | 0 | 0/0 (0%) |
| uor | 572 | 0 | 8/8 (100.0%) |
| uor_etap15 | 1 | 0 | 0/0 (0%) |
| validation | 8 | 0 | 0/0 (0%) |
| vat | 1581 | 0 | 14/14 (100.0%) |
| vat_cashflow | 4 | 0 | 0/0 (0%) |
| vat_complete | 11 | 0 | 0/0 (0%) |
| vat_deductions_audit | 1 | 0 | 0/0 (0%) |
| vat_fraud_detection | 1 | 0 | 0/0 (0%) |
| vat_mpp_split_payment | 1 | 0 | 0/0 (0%) |
| vat_rates_audit | 1 | 0 | 0/0 (0%) |
| vida | 1 | 0 | 0/0 (0%) |
| wht | 1 | 0 | 0/0 (0%) |
| wis | 43 | 0 | 0/0 (0%) |
| wis_api | 3 | 0 | 0/0 (0%) |
| zasilkowa | 42 | 0 | 0/0 (0%) |
| zus | 546 | 0 | 8/8 (100.0%) |
| zus_core_etap12 | 1 | 0 | 0/0 (0%) |
| zus_micro_etap13 | 1 | 0 | 0/0 (0%) |

## Szkielety (nie liczone jako pokrycie)

- brak

## Węzły materialne LKG bez reguły dowodnej (luki)

- brak

---
*Wygenerowano automatycznie — `python JDG/tools/coverage_unifier.py --report`*
*Standard: LCI ≥ 95% · TCL = 100% · RV = 100% · UVR = 0 (bramka `--check`)*
