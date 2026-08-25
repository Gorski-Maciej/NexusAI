# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Main Orchestrator (Multi-Pass First-Match-Wins + Sharded Router)
# ═══════════════════════════════════════════════════════════════════════════════
#
# DANE DOKUMENTACYJNE (komentarz zwykły — nie parsowany przez OPA):
#   title: JDG Main Orchestrator — Multi-Pass + Sharded Router (B1)
#   architecture: Multi-Pass OPA (ADR-001) + Sharded Router (B1) · legal_basis: N/A
#   package: jdg.main · deprecated: false
#
# ── NOTATKI ROZBUDOWANE ──
#   Główny plik decyzyjny JDG. Orkiestruje ewaluację wszystkich 40 pakietów
#   w architekturze Multi-Pass zgodnej z Doc 34, Sekcja 1.3.
#   B1: Sharded Index Router — hash kontekstu (tax_form × transaction_type ×
#   entity_flags × evaluation_date) → dynamiczny routing do specjalizowanych
#   ścieżek ewaluacji. Redukuje złożoność z O(N) do O(1).
#   Dodano 6 pakietów Klasy C (2026-07-16): mdr, tp, solidarity, edelivery, audit, residency.
#   Dodano 9 pakietów Enterprise: pkpir, depreciation, pcc, art21, sickness,
#   bdo, aml, rodo_extended, mdr_enterprise (2026-07-17).
#   Dodano 5 pakietów S1-S5 Enterprise v5.0 (2026-07-18): tax_optimization,
#   cross_domain_hub, judicial_rulings, audit_defense, strategic_advisor.
#   Dodano 5 pakietów S6-S10 Enterprise v5.1 (2026-07-18): ksef_resilience,
#   ppk_pfron, cashflow_predictor, form_transition, banking.
#   Rozbudowano banking_automation o PSD2/PolishAPI v3.x (2026-07-18):
#   AIS, PIS, OAuth2/eIDAS, Elixir/ExpressElixir, multi-bank profiles,
#   payment status tracking, batch payments XML/JSON, PSD2 audit trail.
#   Dodano 3 pakiety S11-S13 Enterprise v5.2 (2026-07-18):
#   annual_declaration (PIT-36/36L/28 auto-fill, advance reconciliation,
#   joint filing optimization, relief cross-validation),
#   jpk_v7_autogen (JPK_V7M sales/purchase registers, VAT-7 declaration,
#   GTU code auto-assignment, cross-check validation, KSeF extraction),
#   legislative_monitor (change detection, impact analysis, transitional
#   provisions, compliance calendar, rule versioning & temporal validity).
#   Dodano 3 pakiety S14-S16 Enterprise v6.0 (2026-07-19):
#   neural_mesh, nkup_enterprise, exit_tax_mdr.
#   Dodano 4 pakiety S21-S24 Enterprise v7.0 (2026-07-19):
#   vat_substantive_complete (Art. 11-135 VAT — miejsce świadczenia,
#   procedury szczególne OSS/IOSS/marża, podstawa opodatkowania,
#   zwolnienia przedmiotowe, korekty wieloletnie, sankcje VAT),
#   tax_authority_interaction (auto-generacja pism do US/KAS/ZUS —
#   czynny żal, odwołania, interpretacje, zwrot nadpłaty, raty,
#   monitoring statusu spraw),
#   sanctions_optimization (KKS Art. 54 gradacja kar, szczegółowe
#   typy czynów Art. 56-62, decision tree 4-ścieżkowy minimalizacji
#   kary, kalkulator ryzyka karno-skarbowego),
#   lifecycle_manager (pełny cykl życia JDG — od rejestracji CEIDG
#   przez startup/growth/maturity po exit/sukcesję, timeline
#   compliance, health scorecard, exit strategy).
#   Używa safe_merge() do scalania werdyktów z kolejnością: najniższy
#   priorytet wewnątrz, najwyższy na zewnątrz (overrides).
#   Edge cases: RISK/ROUTING BLOCK_AND_ALERT → abort dalszych passów;
#   object.union nadpisuje klucze bez ostrzeżenia — kolejność mergowania krytyczna.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.main

import data.jdg.risk
import data.jdg.kks
import data.jdg.kks.enterprise_penalties
import data.jdg.routing
import data.jdg.compliance
import data.jdg.compliance.aml
import data.jdg.crossborder
import data.jdg.crossborder.post_brexit
import data.jdg.vat.substantive
import data.jdg.vat.deductions
import data.jdg.vat.procedures
import data.jdg.pit.forms
import data.jdg.pit.kup
import data.jdg.pit.advances
import data.jdg.pit.advances_returns
import data.jdg.pit.exemptions
import data.jdg.pit.art21_exemptions
import data.jdg.pit.transitions
import data.jdg.pit.zero_doubt as pit_zero_doubt
import data.jdg.vat.zero_doubt as vat_zero_doubt
import data.jdg.pit.elearning
import data.jdg.allowances
import data.jdg.zus
import data.jdg.zus.sickness_benefits
import data.jdg.zus.health_contribution
import data.jdg.mdr
import data.jdg.mdr.enterprise as mdr_enterprise
import data.jdg.mdr.hallmarks as mdr_hallmarks
import data.jdg.mdr.hyper as mdr_hyper
import data.jdg.tp
import data.jdg.tp.hyper as tp_hyper
import data.jdg.exit_tax_cfc as exit_tax_cfc
import data.jdg.crossborder.v3_08 as crossborder_v3_08
import data.jdg.micro.quality_v3_13 as micro_quality_v3_13
import data.jdg.hyper.quality_v3_14 as hyper_quality_v3_14
import data.jdg.enterprise.quality_v3_15 as enterprise_quality_v3_15
import data.jdg.business.v3_09 as business_v3_09
import data.jdg.local_taxes.pcc as lt_pcc
import data.jdg.local_taxes.real_estate as lt_real_estate
import data.jdg.local_taxes.transport as lt_transport
import data.jdg.local_taxes.plan26 as lt_plan26
import data.jdg.akcyza.alcohol_tobacco as akcyza_alcohol
import data.jdg.akcyza.fuel_energy as akcyza_fuel
import data.jdg.local.enterprise as local_enterprise
import data.jdg.local_taxes.v3_10 as local_taxes_v3_10
import data.jdg.solidarity
import data.jdg.edelivery
import data.jdg.audit
import data.jdg.residency
import data.jdg.accounting
import data.jdg.accounting.pkpir
import data.jdg.accounting.pkpir_validation
import data.jdg.accounting.depreciation
import data.jdg.business
import data.jdg.business.gig_economy
import data.jdg.corrections
import data.jdg.conflicts
import data.jdg.liability
import data.jdg.representation
import data.jdg.local_taxes
import data.jdg.local_taxes.pcc_enterprise
import data.jdg.ksef_jpk
import data.jdg.jpk_cit
import data.jdg.international
import data.jdg.employer
import data.jdg.environmental
import data.jdg.environmental.bdo
import data.jdg.restructuring
import data.jdg.temporal
import data.jdg.digital
import data.jdg.api_fallback
import data.jdg.retention
import data.jdg.mpips
import data.jdg.rodo
import data.jdg.rodo_extended
import data.jdg.validation
import data.jdg.edge_cases
import data.jdg.fallback
import data.jdg.tax_optimization
import data.jdg.cross_domain_hub
import data.jdg.judicial_rulings
import data.jdg.audit_defense
import data.jdg.strategic_advisor
import data.jdg.ksef_resilience
import data.jdg.ppk_pfron
import data.jdg.cashflow_predictor
import data.jdg.form_transition
import data.jdg.banking
import data.jdg.annual_declaration
import data.jdg.jpk_v7_autogen
import data.jdg.legislative_monitor
import data.jdg.neural_mesh
import data.jdg.nkup_enterprise
import data.jdg.exit_tax_mdr
import data.jdg.mdr_dac6
import data.jdg.pkpir_live
import data.jdg.uor_live
import data.jdg.local_taxes.excise_enterprise
import data.jdg.local_taxes.procedures_enterprise
import data.jdg.vat_substantive_complete
import data.jdg.tax_authority_interaction
import data.jdg.sanctions_optimization
import data.jdg.lifecycle_manager
import data.jdg.hyper_plan45_meta
import data.jdg.deadline_monitor
import data.jdg.wis_api
import data.jdg.epuap
# ── V3-11: domknięcie wiringu orphan-pakietów KSeF/JPK/e-Doręczenia ──
import data.jdg.ksef_innovations as ksef_innov
import data.jdg.ksef_outbox as ksef_outbox
import data.jdg.ksef_offline_queue as ksef_offq
import data.jdg.ksef_sandbox as ksef_sandbox
import data.jdg.ksef_upo_tracker as ksef_upo
import data.jdg.ksef_receipt_digest as ksef_digest
import data.jdg.ksef_sanction_monitor as ksef_sanction
import data.jdg.jpk_corrections as jpk_corrections
import data.jdg.jpk_kr_st as jpk_kr_st
import data.jdg.edelivery_gateway as edelivery_gw
import data.jdg.enterprise.edelivery_gateway as edelivery_gw2
import data.jdg.esig_auto as esig_auto
import data.jdg.enterprise.wis_autorequester as wis_auto
import data.jdg.ksef_jpk.v3_11 as ksef_jpk_v3_11
# ── V3-12: domknięcie wiringu orphan-pakietów RODO/AML/BDO/HR ──
import data.jdg.micro.aml_cbdd as aml_cbdd
import data.jdg.micro.aml_ryzyko as aml_ryzyko
import data.jdg.micro.aml_str_gif as aml_str_gif
import data.jdg.micro.aml_transakcje as aml_transakcje
import data.jdg.compliance.v3_12 as compliance_v3_12
import data.jdg.security.fortress
import data.jdg.p34_remaining
import data.jdg.p34_innovations
import data.jdg.p35_coherence
import data.jdg.p35_gaps
import data.jdg.p35_innovations
import data.jdg.p21_innovations
import data.jdg.p22_innovations
import data.jdg.p23_innovations
import data.jdg.p24_innovations
import data.jdg.hyper.general as hyper_general
import data.jdg.hyper.deadlines as hyper_deadlines
import data.jdg.hyper.limits as hyper_limits
import data.jdg.hyper.mdr as hyper_mdr
import data.jdg.hyper.misc as hyper_misc
import data.jdg.hyper.sanctions as hyper_sanctions
import data.jdg.hyper.audit as hyper_audit
import data.jdg.hyper.family as hyper_family
import data.jdg.hyper.force_majeure as hyper_force_majeure
import data.jdg.hyper.fx as hyper_fx
import data.jdg.hyper.edelivery as hyper_edelivery
import data.jdg.hyper.procurement as hyper_procurement
import data.jdg.hyper.solidarity as hyper_solidarity
import data.jdg.hyper.wis as hyper_wis
import data.jdg.p33_uor_supplement
import data.jdg.p33_pcc_complete
import data.jdg.p33_excise_supplement
import data.jdg.p33_ordpu_kks_supplement
import data.jdg.p3233_innovations
import data.jdg.p12_innovations
import data.jdg.p13_innovations
import data.jdg.p14_innovations
# ── P15 Enterprise v8.0: PCC + Local Taxes + Excise Innovations (2026-08-01) ──
# 12 Innovations: PCC Auto-Detection, PCC-3 Auto-Filler, Real Estate Classifier,
# Excise Warehouse Tracker, Transport Tax Calculator, PCC Exemption Analyzer,
# Multi-Tax Calendar, Excise Suspension Manager, Property Appeal Drafter,
# Rate Auto-Updater, Cross-Border Excise, PCC+VAT Firewall
import data.jdg.p15_innovations
# ── P16 Enterprise v8.0: Business Lifecycle Full Implementation (2026-08-01) ──
# Auto-Form Generator (G1-G7): CEIDG-1, ZUS ZUA/ZWUA, VAT-Z, PIT-4R/11, Notarial Deed, Receipts
# Estonian CIT (E1): Full Art. 28c-28t with eligibility, calculator, transition, compliance
# Entrepreneur Test (ET): JDG vs ETAT scoring, risk levels, consequences
# Enhanced SCA (SCA): RTS SCA methods, exemptions, eIDAS certificates, TRA
import data.jdg.p16_innovations
import data.jdg.autoform
import data.jdg.estonian_cit
import data.jdg.entrepreneur_test
import data.jdg.banking_sca
# ── PAS 19: P17 Enterprise v8.0 Edge Cases + Conflicts Innovations (2026-08-01) ──
import data.jdg.p17_innovations
import data.jdg.pkpir_to_uor_transformer
import data.jdg.exit_tax_interest_calculator
import data.jdg.mdr_auto_generator
import data.jdg.wdt_document_tracker
import data.jdg.cfc_auto_classifier
import data.jdg.vida_drr_full
import data.jdg.dac8_report_generator
import data.jdg.cbam_full
import data.jdg.p01_innovations
import data.jdg.p02_innovations
import data.jdg.p03_innovations
import data.jdg.p04_innovations
import data.jdg.p05_innovations
import data.jdg.p06_innovations
import data.jdg.p07_innovations
import data.jdg.p08_innovations
import data.jdg.p09_innovations
import data.jdg.p10_innovations
import data.jdg.p11_innovations
# ── PAS 17: Enterprise v7.0 Audit Implementation (2026-07-25) ──
# CR1: R&D Relief (Art. 26e PIT) | CR2: IP Box (Art. 30ca PIT) | CR3: Thermo Relief (Art. 26h PIT)
# H4: Donation Relief Enterprise | S5: Cross-Relief Optimizer | S8: Tax Loss Harvesting
# S15: Family Tax Optimizer + CR4: Estonian CIT | M6: Tax Form Optimizer + Cash-Flow
import data.jdg.pit.thermo_relief
import data.jdg.pit.rd_relief
import data.jdg.pit.ipbox
import data.jdg.pit.cross_relief
import data.jdg.pit.donation_relief
import data.jdg.pit.tax_loss_harvesting
import data.jdg.pit.family_estonian
# RAPORT 04: missing PIT reliefs and active loss carry-forward.
import data.jdg.pit.missing_reliefs
import data.jdg.form_optimizer

# ── PAS 18: Provenance (A1 + ADR-006 Immutable Audit Trail) ──
# KRYTYCZNE-2 FIX: provenance.enrich_verdict() podłączony do final_verdict_enriched
import data.jdg.provenance
# ── PAS 18b: P01 Fundament OPA v9.0 — Rule Lifecycle + Reliability + Genius Ideas (2026-08-02) ──
# P01 Sekcja 2: Rule Lifecycle Management (shadow/A-B/rollback/temporal conflicts)
# P01 Sekcja 4: Reliability Guarantee Layer (provenance gate, fallback ladder, determinism)
# P01 Sekcja 7: Genius Ideas Enterprise (self-adapting orchestrator, hot-reload, forecasting)
import data.jdg.rule_lifecycle
import data.jdg.reliability_guarantee
import data.jdg.p01_fundament_innovations
# ── PAS 18c: P02 Warstwa Decyzyjna Core v9.0 (2026-08-02) ──
# P02 Sekcja 1: Adaptive Trust Scoring (ML scoring, counterparty risk, fraud patterns)
# P02 Sekcja 2: Conflict Declaration System (registry + deterministic hierarchy)
# P02 Sekcje 3-5: Edge Case Completeness + Limitations Calendar + Liability/Retention
# P02 Sekcja 7: Genius Ideas Enterprise (never-wrong engine, dead rule detector, etc.)
import data.jdg.adaptive_trust
import data.jdg.conflict_declaration
import data.jdg.decision_core_completeness
import data.jdg.p02_decision_core_innovations
# ── PAS 18d: P03 VAT MACRO ENTERPRISE v9.0 (2026-08-02) ──
# P03 Sekcja 1: Rates & Exemptions Audit (mapa stawek PKWiU/CN, limit 200k mid-year)
# P03 Sekcja 3: Deductions & Corrections Audit (art. 86-95, proporcja, złe długi)
# P03 Sekcja 4: MPP / Split Payment Audit (PRIORYTET — art. 108a, Załącznik 15, sankcje)
# P03 Sekcja 6: VAT Fraud Detection (puste faktury, karuzele, znikający podatnik)
# P03 Sekcje 2/5/7/8: POS + KSeF 2026 + pipeline thresholdów + genius ideas
import data.jdg.vat_rates_audit
import data.jdg.vat_deductions_audit
import data.jdg.vat_mpp_split_payment
import data.jdg.vat_fraud_detection
import data.jdg.p03_vat_macro_innovations
import data.jdg.p04_vat_macro_enterprise
import data.jdg.p05_vat_micro_atomic
import data.jdg.p06_pit_macro_enterprise
# ── PAS 18e: P04 VAT MICRO ENTERPRISE v9.0 (2026-08-02) ──
# P04 Sekcje 1-7: mapa pokrycia artykułów atomowych, audyt duplikatów/stubów,
# spójność micro↔macro, gwarancje matematyczne (grosze/zaokrąglenia),
# audyt pakietów specjalistycznych (KSeF micro, marża, POS, proporcja, WDT/IE),
# pipeline auto-generacji reguł mikro z ISAP + 14 genius ideas
import data.jdg.p04_vat_micro_innovations
# ── PAS 18f: P05 PIT MACRO ENTERPRISE v9.0 (2026-08-02) ──
# P05 Sekcje 1-8: formy opodatkowania (skala/liniowy/ryczałt/karta), audyt ulg
# (PRIORYTET — B+R, IP Box, termo, prototyp, robotyzacja, ekspansja, PIT-0),
# KUP/NKUP, zaliczki art. 44 + zeznanie art. 45, zwolnienia Art. 21,
# thresholdy temporalne (ADR-002) + 15 genius ideas
import data.jdg.p05_pit_macro_innovations
# ── ETAP 10: PIT Macro completeness, temporal forecast and fail-closed gates ──
import data.jdg.pit_macro_etap10
# ── ETAP 11: PIT Micro Reliefs atomic evidence pack and qualification gates ──
import data.jdg.pit_micro_reliefs_etap11
# ── ETAP 12: ZUS Core calculation certificate and fail-closed audit layer ──
import data.jdg.zus_core_etap12
# ── ETAP 13: ZUS Micro atom map, periods, benefits and property invariants ──
import data.jdg.zus_micro_etap13
# ── ETAP 14: PKPiR columns, documents, reconciliation and idempotency ──
import data.jdg.pkpir_etap14
# ── ETAP 15: UoR double-entry, assets, amortization, closing, financial stmt ──
import data.jdg.uor_etap15
# ── ETAP 16: KKS + Ordynacja — risk scoring, evidence chain, deadlines ──
import data.jdg.kks_ord_etap16
# ── PAS 18g: P06 PIT MICRO + AMORTYZACJA ENTERPRISE v9.0 (2026-08-02) ──
# P06 Sekcje 1-8: mapa pokrycia artykułów PIT micro 1-45, audyt amortyzacji
# (PRIORYTET — art. 22a-22n: KŚT, jednorazowa 100k EUR, samochody 150k/225k,
# stawki indywidualne), duplikaty/stuby, spójność micro↔macro, audyt obliczeń,
# pipeline auto-generacji + 14 genius ideas
import data.jdg.p06_pit_micro_innovations
import data.jdg.p07_pit_micro_atomic
import data.jdg.p08_zus_macro_enterprise
# ── PAS 18h: P07 ZUS/SUS MACRO ENTERPRISE v9.0 (2026-08-02) ──
# P07 Sekcje 1-8: audyt składki zdrowotnej (PRIORYTET — skala 9%, liniowy 4,9%,
# ryczałt 3 progi 60%/100%/180%, karta 9%), składki społeczne (19,52/8/2,45/1,67,
# 30-krotność, ulga na start, Mały ZUS Plus, preferencyjny, terminy 10/15/20),
# zasiłki (chorobowy 80/100%, wyczekiwanie, macierzyński, opiekuńczy, rehab),
# PPK/PFRON/FS, zbiegi tytułów (etat+JDG, emeryt+JDG, student+JDG, urlop
# wychowawczy+JDG), thresholdy temporalne (ADR-002) + 15 genius ideas
import data.jdg.p07_zus_macro_innovations
# ── PAS 18i: P08 ZUS/SUS MICRO ENTERPRISE v9.0 (2026-08-02) ──
# P08 Sekcje 1-8: mapa pokrycia artykułów ZUS micro (sus a6-a47, zdrowotna
# a79-a82, zasilkowa a19-a33), audyt zdrowotnej mikro (PRIORYTET — progi
# ryczałtowe 60K/300K, stawki, korekta roczna, składka od nadwyżki, silnik
# auto-przeliczenia progu), zasiłki mikro (wyczekiwanie, stawki, limity),
# duplikaty/stuby, spójność micro↔macro (P07), pipeline temporalny + 14 genius ideas
import data.jdg.p08_zus_micro_innovations
# ── PAS 18j: P09 KSIĘGOWOŚĆ PKPiR + UoR ENTERPRISE v9.0 (2026-08-02) ──
# P09 Sekcje 1-8: audyt struktury PKPiR (kolumny 1-17, dekretacja, terminy),
# audyt UoR (PRIORYTET — próg 2M EUR, silnik decyzji PKPiR-czy-UoR,
# zasady memoriałowe, dowody, inwentaryzacja), amortyzacja i leasing (KŚT,
# jednorazowa 100k EUR, auta 150k/225k, operacyjny/finansowy), remanent
# i korekty, transformacja PKPiR→UoR, pipeline temporalny + 15 genius ideas
import data.jdg.p09_ksiegowosc_pkpir_uor_innovations
# ── PAS 18k: P10 KKS — KODEKS KARNY SKARBOWY ENTERPRISE v9.0 (2026-08-02) ──
# P10 Sekcje 1-8: mapa pokrycia artykułów KKS (a16-a83, 474 reguły micro),
# audyt gradacji kar (PRIORYTET — typy czynów, stawki dzienne, mnożniki,
# recydywa, mała wartość, kalkulator kary, silnik minimalizacji 4-ścieżkowy,
# symulator ryzyka), czynny żal (art. 16) i dobrowolne poddanie się (art. 17),
# przedawnienie (art. 44) i zatarcie (art. 45), spójność micro↔macro, pipeline
# auto-aktualizacji sankcji (ADR-002) + 12 genius ideas
import data.jdg.p10_kks_innovations
# ── PAS 18l: P11 ORDYNACJA PODATKOWA ENTERPRISE v9.0 (2026-08-02) ──
# P11 Sekcje 1-8: mapa pokrycia artykułów OrdPU (a16-a193a, 424 reguły micro),
# audyt przedawnień (PRIORYTET — art. 70: 5 lat od końca roku, przerwanie §4,
# zawieszenie §6, kalendarz z alertami), korekty/nadpłaty (art. 81/81b, 72-80,
# silnik auto-korekty), auto-korespondencja z urzędem (A-Z), GAAR (art. 119a),
# Biała Lista (art. 117ba — 30 dni, 20%), pipeline (ADR-002) + 15 genius ideas
import data.jdg.p11_ordynacja_podatkowa_innovations

# P12 Cross-Border (WNT/WDT, miejsce świadczenia art. 28a-28o, MDR/DAC6,
# TP/CFC/rezydencja/FX, ViDA/DRR/DAC8, exit tax) + 12 genius ideas
import data.jdg.p12_crossborder_innovations

# P13 Ryczałt + Cykl Życia (stawki PKWiU, karta podatkowa, cykl życia JDG,
# sukcesja, zawieszenia, działalność nieewidencjonowana) + 12 genius ideas
import data.jdg.p13_ryczalt_cykl_zycia_innovations

# P14 PCC + Podatki Lokalne + Akcyza (stawki PCC, PCC-3, nieruchomości DN-1,
# transport >3,5t, rejestr stawek gminnych, akcyza paliwa/alkohol) + 12 genius ideas
import data.jdg.p14_pcc_lokalne_akcyza_innovations

# ── PAS 18q: P15 ŚRODOWISKO + BDO + BRANŻA ENTERPRISE v9.0 (2026-08-02) ──
# P15 Sekcje 1-8: mapa pokrycia modułów BDO (rejestracja/ewidencja/EWC/transport/
# zezwolenia/WEEE-baterie), audyt BDO (PRIORYTET — opłaty 100-500 zł, kara 5000 zł
# art. 194 UoO, KPO, ewidencja kwartalna, opakowania), audyt budownictwa
# (PRIORYTET — pozwolenia, zgłoszenia, nadzór), transport/rolnictwo (licencje,
# tachografy, rolnik ryczałtowy, podatek rolny), zawody regulowane/tax-free/
# sezonowość, CBAM (2023/956, raporty kwartalne), pipeline (ADR-002) + 12 INN
import data.jdg.p15_srodowisko_bdo_innovations

# ── PAS 18r: P16 RODO + AML + COMPLIANCE + BEZPIECZEŃSTWO + AUDYT v9.0 (2026-08-02) ──
# P16 Sekcje 1-7: audyt RODO (PRIORYTET — rejestr czynności Art. 30, retencja,
# erasure, podprocesorzy, AI marketing, sankcje Art. 83), audyt AML (PRIORYTET ★ —
# CBDD, beneficjenci rzeczywiści, STR/GIF, transakcje > 15 000 EUR, scoring ryzyka),
# audyt bezpieczeństwa (security_fortress_v8, HMAC, immutable verdicts), audyt
# ścieżki decyzji (audit/plan44+45, audit_defense, merkle proof-chain), pipeline
# auto-aktualizacji reguł compliance (ePrivacy, AMLR) + 14 INN
import data.jdg.p16_rodo_aml_security_innovations
import data.jdg.p17_ksef_jpk_edeklaracje_innovations
import data.jdg.p18_automatyzacja_ksiegowosci_innovations
import data.jdg.p19_hr_swiadczenia_innovations
import data.jdg.p20_neural_mesh_innovations
import data.jdg.p21_opa_system_innovations
import data.jdg.p22_validation_tools_innovations
import data.jdg.p23_test_rego_ci_innovations
import data.jdg.p24_audyt_kompletny_innovations
# ── PAS 18m: P03 GLM52 ORKIESTRATOR + INFRASTRUKTURA REGUŁ (2026-08-08) ──
# Orkiestrator (Sekcje 6/7/8/9/10 raport_enterprise_P03): cache Merkle,
# shadow twin, graf zależności, benchmarki, degraded context, kill-switch,
# POST-MERGE runtime invariants (F2 V2, ADR-022) + decision certificate (F4).
import data.jdg.p03_orchestrator_innovations
import data.jdg.runtime_invariants
# ── PAS 18o: R01 GLM52 Orkiestrator + Rdzeń Silnika (2026-08-14) ──
# Deterministic routing path trace, 25-field verdict completeness, decision cache,
# time-travel guard, safe_merge integrity (INV-042), priority conflicts (INV-018).
import data.jdg.r01_orchestrator_core_innovations
# ── PAS 18p: R02 GLM52 VAT CORE (MACRO) + ENTERPRISE (2026-08-14) ──
# Real-time exemption limit tracker (art. 113), auto-GTU (Zał. 15), art. 91
# multi-year correction schedule automation.
import data.jdg.r02_vat_core_innovations
# ── PAS 18q: R03 GLM52 VAT WARSTWA MICRO (2026-08-14) ──
# Article coverage monitor (30 kluczowych artykułów), micro↔macro binding,
# micro↔macro consistency (INV-018) + atomowe uzupełnienie 5 artykułów
# (a28b/a87/a91/a106a/a106i — jdg.micro.vat.r03).
import data.jdg.r03_vat_micro_innovations
import data.jdg.r04_pit_core_innovations
import data.jdg.r05_pit_enterprise_innovations
import data.jdg.r06_zus_innovations
import data.jdg.r07_kks_innovations
import data.jdg.r08_ordynacja_obrona_innovations
# ── PAS 18w: R09 GLM52 UoR / PKPiR / KSIĘGOWOŚĆ (2026-08-15) ──
# Symulator progu UoR (2M EUR + projekcja), uzgodnienie 3-drożne PKPiR↔VAT↔bank,
# optymalizator amortyzacji, monitor inwentaryzacji, auto-pakiet sprawozdania.
import data.jdg.r09_ksiegowosc_pkpir_uor_innovations
# ── PAS 18x: R10 GLM52 CROSS-BORDER / TP / MDR-DAC6 / CFC / ViDA / CBAM (2026-08-15) ──
# Monitor 30 dni dowodu WDT, scorer ryzyka MDR/DAC6, symulator TP, przypisanie
# dochodu CFC, różnice kursowe z time-travel (kursy NBP per okres).
import data.jdg.r10_crossborder_innovations
# ── ETAP 17: evidence-first cross-border safety/control layer ──
# Domyślnie no_match; po aktywacji wymaga źródeł, wersji, evidence pack i manual gate.
import data.jdg.crossborder_etap17
# ── ETAP 18: formalny state machine cyklu życia JDG ──
# CEIDG/ryczałt/PP/sukcesja: effective dates, formularze, terminy, rollback,
# owner approval i fail-closed manual gate.
import data.jdg.business_lifecycle_etap18
# ── ETAP 19: PCC / podatki lokalne / nieruchomości / transport / akcyza ──
# Temporalny rejestr stawek, terytorium gminy, dokumenty i evidence-first gates.
import data.jdg.local_excise_etap19
# ── ETAP 20: KSeF / JPK / e-Deklaracje / e-Doręczenia / WIS ──
# State machine dokumentu, XSD, UPO, tokeny, offline/retry, outbox exactly-once,
# rekonsyliacja księga↔JPK↔KSeF i fail-closed przy niedostępności MF.
import data.jdg.ksef_jpk_etap20
# ── ETAP 22: Hyper Enterprise Contexts / Plan45 Meta-Validator ──
# Konteksty, deadline engine, limit registry, MDR/sankcje, FX, WIS,
# e-Doręczenia, konflikty, priorytety i graf zależności.
import data.jdg.hyper_enterprise_contexts_etap22
import data.jdg.enterprise_ai_neural_etap23
import data.jdg.tests_ci_quality_etap24
import data.jdg.tools_api_rulestore_bundles_etap25
import data.jdg.policies_mirror_sync_etap26
import data.jdg.cross_domain_red_team_etap27
import data.jdg.final_certification_etap28
# ── ETAP 21: RODO / AML / BDO / HR / PPK / PFRON ──
# Privacy-by-design, evidence chain, UBO/CBDD/STR, KPO/EWC, zatrudnienie,
# manual approval i rozdzielenie guidance compliance od decyzji podatkowej.
import data.jdg.rodo_aml_bdo_hr_etap21
# ── PAS 18y: R11 GLM52 PCC / PODATKI LOKALNE / AKCYZĄ (2026-08-15) ──
# Monitor PCC-3 14 dni, symulator podatku od nieruchomości, klasyfikator
# wyrobów akcyzowych, monitor DN-1, arbiter VAT vs PCC (art. 2 pkt 4).
import data.jdg.r11_pcc_lokalne_akcyza_innovations
# ── PAS 18z: R12 GLM52 RYCZAŁT / CEIDG / CYKL ŻYCIA (2026-08-15) ──
# Monitor limitu 2M EUR ryczałtu, klasyfikator PKWiU, planner faz cyklu
# życia, monitor sukcesji, arbiter formy opodatkowania.
import data.jdg.r12_ryczalt_cykl_zycia_innovations
# ── PAS 18aa: R13 GLM52 HYPER PLAN45 / KONTEKSTY SPECJALNE (2026-08-15) ──
# Detektor konfliktów, danina solidarnościowa, prokura, kalendarz terminów,
# selektor podpisu kwalifikowanego.
import data.jdg.r13_hyper_konteksty_innovations
# ── PAS 18ac: R14 GLM52 RODO / AML-CBDD / BDO / ŚRODOWISKO (2026-08-15) ──
# Rejestr czynności RODO, scoring AML, sankcje RODO, monitor STR/GIIF,
# monitor obowiązków BDO.
import data.jdg.r14_rodo_aml_bdo_innovations
# ── PAS 18ae: R15 GLM52 KSeF / JPK / e-DEKLARACJE / GTU / WIS (2026-08-15) ──
# Firewall KSeF, korelacja JPK, klasyfikator GTU, monitor offline, WIS.
import data.jdg.r15_ksef_jpk_edeklaracje_innovations
# ── PAS 18ag: R16 GLM52 SYSTEM OPA / P18-P35 (2026-08-15) ──
# Cykl życia reguły, jakość walidacji, tarcza CI, niezawodność, pipeline ISAP.
import data.jdg.r16_system_opa_innovations
# ── PAS 18ah: R17 GLM52 ENTERPRISE AI (2026-08-15) ──
# Adaptive Trust, Neural Mesh, Cashflow, Bankowość PSD2, Monitor legislacyjny.
import data.jdg.r17_enterprise_ai_innovations
import data.jdg.micro.vat.r03 as micro_vat_r03
import data.jdg.micro.vat as micro_vat_full
import data.jdg.micro.jpk as micro_jpk_full
import data.jdg.micro.jpk.plan33 as micro_jpk_plan33
import data.jdg.micro.pit as micro_pit_full
import data.jdg.micro.pit.plan33 as micro_pit_plan33
import data.jdg.micro.pit.plan34 as micro_pit_plan34
import data.jdg.micro.amort_a22a
import data.jdg.micro.amort_a22b
import data.jdg.micro.amort_a22c
import data.jdg.micro.amort_a22h
import data.jdg.micro.amort_a22i
import data.jdg.micro.amort_a22k
import data.jdg.micro.amort_a22n

# ── PAS 18ai: P09 GLM52 ZUS MIKRO + ZASIŁKI (2026-08-17) ──
# Warstwa mikro ZUS (sus/zdrowotna/zasilkowa + plan33 + atomowe P09):
# wypełnia LUKI makro (no_match → werdykt atomowy), nigdy nie nadpisuje
# decyzji makro (safe_merge: final_verdict_p45 ma priorytet, INV-018).
# Konsolidacja P09: usunięte stuby sus_a*/zdrowotna_a*/zasilkowa_a* oraz
# plan34_zus.rego (duplikaty); plan33_zus.rego → rule_id jdg.micro.zus.*
# (kolizja z makro jdg.zus.* naprawiona).
import data.jdg.micro.sus as micro_sus_full
import data.jdg.micro.zdrowotna as micro_zdrowotna_full
import data.jdg.micro.zasilkowa as micro_zasilkowa_full
import data.jdg.micro.zus as micro_zus_plan33
import data.jdg.micro.zus_atomic_p09 as zus_micro_atomic_p09

# ── PAS 18aj: P10 GLM52 KSIĘGOWOŚĆ PKPiR/UoR (2026-08-17) ──
# Warstwa mikro księgowości (PKPiR 7 pakietów + UoR + plan33_uor + atomowe P10):
# wypełnia LUKI makro (no_match → werdykt atomowy), nigdy nie nadpisuje
# decyzji makro (safe_merge: final_verdict_p46 ma priorytet, INV-018).
# Konsolidacja P10: usunięte fallbacki {true} (6 reguł martwych PKPiR),
# kanoniczne _legal_basis (UoR: Dz.U. 2025 poz. 567; PKPiR: rozp. MF 15.11.2025).
import data.jdg.micro.pkpir as micro_pkpir
import data.jdg.micro.pkpir_columns as micro_pkpir_columns
import data.jdg.micro.pkpir_corrections as micro_pkpir_corrections
import data.jdg.micro.pkpir_costs as micro_pkpir_costs
import data.jdg.micro.pkpir_nkup as micro_pkpir_nkup
import data.jdg.micro.pkpir_revenue as micro_pkpir_revenue
import data.jdg.micro.pkpir_remnant as micro_pkpir_remnant
import data.jdg.micro.uor as micro_uor
import data.jdg.micro.uor_plan33 as micro_uor_plan33
import data.jdg.micro.ksiegowosc_atomic_p10 as ksiegowosc_atomic_p10
import data.jdg.micro.kks as micro_kks_full
import data.jdg.micro.ord as micro_ord_full
import data.jdg.micro.kks.plan33 as micro_kks_plan33
import data.jdg.micro.plan33_ord as micro_ord_plan33
import data.jdg.micro.plan34_ord as micro_ord_plan34
import data.jdg.micro.kks_ord_atomic_p11
import data.jdg.micro.crossborder as micro_cb_full
import data.jdg.micro.cb as micro_cb_plan33
import data.jdg.micro.tp as micro_tp_plan33
import data.jdg.micro.tax_trans as micro_tax_trans_plan33
import data.jdg.micro.mdr as micro_mdr_plan33
import data.jdg.micro.crossborder_atomic_p12

# ── PAS 18ak: P13 GLM52 RYCZAŁT / CEIDG / PP / SUKCESJA (2026-08-17) ──
# Warstwa micro cyklu życia (ryczalt/ceidg/pp/sukcesja + plan33 + atomowe P13):
# wypełnia LUKI makro (no_match → werdykt atomowy), nigdy nie nadpisuje
# decyzji makro (safe_merge: final_verdict_p49 ma priorytet, INV-018).
# Konsolidacja P13: plan33_ceidg.rego → package jdg.micro.plan33_ceidg
# (konflikt 2× default decide z ceidg.rego naprawiony — wzorzec plan34_ord P11);
# kanon _legal_basis: ryczałt poz. 234 / PP poz. 123 / CEIDG poz. 456 /
# sukcesja poz. 1234 (0 starych cytowań).
import data.jdg.micro.ryczalt as micro_ryczalt_full
import data.jdg.micro.ryc as micro_ryc_plan33
import data.jdg.micro.ceidg as micro_ceidg_full
import data.jdg.micro.plan33_ceidg as micro_ceidg_plan33
import data.jdg.micro.pp as micro_pp_full
import data.jdg.micro.sukcesja as micro_sukcesja_full
import data.jdg.micro.succ as micro_succ_plan33
import data.jdg.micro.ryczalt_cykl_atomic_p13

# ── PAS 18am: P14 GLM52 PCC / PODATKI LOKALNE / AKCYZA MIKRO (2026-08-17) ──
# Warstwa micro PCC + lokalne + akcyza (pcc 90 + plan33_pcc 60 + akcyza 133 +
# prop 31 + prop_transport 6 + agricultural_tax 6 + pcc_lokalne_atomic_p14 19):
# wypełnia LUKI makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge:
# lewy argument wygrywa, INV-018). Konsolidacja P14: plan33_pcc.rego → package
# jdg.micro.pcc.plan33 (konflikt 2× default decide z pcc.rego naprawiony —
# wzorzec jpk.plan33 P03); plan26_local.rego → jdg.local_taxes.plan26 (konflikt
# 2× default decide z local_taxes.rego); kanon _legal_basis: PCC poz. 789 /
# lokalne poz. 1234 / akcyza poz. 1220 (0 starych cytowań).
import data.jdg.micro.pcc as micro_pcc_full
import data.jdg.micro.pcc.plan33 as micro_pcc_plan33
import data.jdg.micro.akcyza as micro_akcyza_full
import data.jdg.micro.prop as micro_prop_plan33
import data.jdg.micro.prop_transport as micro_prop_transport_plan33
import data.jdg.micro.agricultural_tax as micro_agricultural_plan33
import data.jdg.micro.pcc_lokalne_atomic_p14

# ── PAS 18an: P15 GLM52 RODO / AML-CBDD / BDO-ŚRODOWISKO / BUDOWNICTWO / TRANSPORT MIKRO (2026-08-18) ──
# Warstwa micro compliance (rodo 6 + plan33_rodo + aml 5 + bdo 6 + srodowisko +
# plan33_est 15 + budownictwo 64 + transport 44 + rodo_aml_bdo_atomic_p15 17):
# wypełnia LUKI makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge:
# lewy argument wygrywa, INV-018). Konsolidacja P15: plan42_rodo.rego → package
# jdg.rodo.plan42 (konflikt 2× default decide z rodo.rego naprawiony — wzorzec
# plan33_pcc P14); 7 martwych fallbacków {true} usuniętych (INV-018); kanon
# _legal_basis: RODO 2016/679 / AML Dz.U. 2025 poz. 213 / BDO poz. 321 /
# Prawo budowlane poz. 1101 (0 starych cytowań).
import data.jdg.micro.rodo as micro_rodo_full
import data.jdg.micro.rodo.plan33 as micro_rodo_plan33
import data.jdg.micro.aml as micro_aml_full
import data.jdg.micro.bdo_rejestracja as micro_bdo_rejestracja
import data.jdg.micro.bdo_ewidencja as micro_bdo_ewidencja
import data.jdg.micro.bdo_ewc as micro_bdo_ewc
import data.jdg.micro.bdo_transport as micro_bdo_transport
import data.jdg.micro.bdo_zezwolenia as micro_bdo_zezwolenia
import data.jdg.micro.bdo_weee as micro_bdo_weee
import data.jdg.micro.srodowisko as micro_srodowisko_full
import data.jdg.micro.est as micro_est_plan33
import data.jdg.micro.budownictwo as micro_budownictwo_full
import data.jdg.micro.transport as micro_transport_full
import data.jdg.micro.rodo_aml_bdo_atomic_p15

# ═══════════════════════════════════════════════════════════════════════════════
# B1: SHARDED INDEX ROUTER — Context Hashing + Dynamic Path Selection
# ═══════════════════════════════════════════════════════════════════════════════
#
# Problem: 7,000 reguł w O(N) else-chain → 28s latency.
# Rozwiązanie: Router O(1) buduje hash kontekstu i wybiera specjalizowaną
# ścieżkę ewaluacji (shard) zamiast pełnego skanowania.
#
# Kontekst routingu:
#   - tax_form: SCALE / LINEAR / LUMP_SUM / TAX_CARD
#   - transaction_type: SALE / PURCHASE / EXPORT / IMPORT
#   - entity_flags: CEIDG_VALID / SUSPENDED / IN_SUCCESSIO / UNREGISTERED
#   - evaluation_date: kwartał roku
#
# W pełnej implementacji (Faza S2) router mapuje do dedykowanych shardów.
# Obecnie: prototyp — dynamiczna selekcja pakietów na podstawie kontekstu.
# ═══════════════════════════════════════════════════════════════════════════════

# ── Context Builder: ekstrahuje kluczowe flagi do routingu ───────────────────

routing_context := {
    "tax_form": object.get(input.jdg_entrepreneur, "tax_form", "SCALE"),
    "transaction_type": build_transaction_type(input),
    "entity_status": build_entity_status(input),
    "evaluation_quarter": build_evaluation_quarter(input),
    # Jawna data ewaluacji jest częścią kontraktu routingu (INV-036),
    # niezależnie od pomocniczego numeru kwartału.
    "evaluation_date": object.get(input, "evaluation_datetime", "2026-01-01"),
    "is_cross_border": is_cross_border_transaction(input),
    "has_employees": object.get(input.jdg_entrepreneur, "has_employees", false),
    "is_vat_payer": is_vat_payer_check(input),
    "requires_ksef": requires_ksef_check(input)
}

# v7.0 P34 FIX (Atak 1): delivery.country, service_performed_country, vat_place_of_supply
build_transaction_type(inp) = tx_type {
    inp.invoice.direction == "SALE"
    inp.invoice.procedure == "EXPORT"
    tx_type := "EXPORT"
} else = tx_type {
    inp.invoice.direction == "SALE"
    vendor_country := object.get(inp.vendor, "country", "PL")
    vendor_country != "PL"
    tx_type := "CROSS_BORDER_SALE"
} else = tx_type {
    inp.invoice.direction == "SALE"
    object.get(inp.delivery, "country", "PL") != "PL"
    tx_type := "CROSS_BORDER_SALE"
} else = tx_type {
    inp.invoice.direction == "SALE"
    service_country := object.get(inp.invoice, "service_performed_country", "PL")
    service_country != "PL"
    tx_type := "CROSS_BORDER_SALE"
} else = tx_type {
    inp.invoice.direction == "SALE"
    supply_country := object.get(inp.invoice, "vat_place_of_supply", "PL")
    supply_country != "PL"
    tx_type := "CROSS_BORDER_SALE"
} else = tx_type {
    inp.invoice.direction == "SALE"
    tx_type := "DOMESTIC_SALE"
} else = tx_type {
    inp.invoice.direction == "PURCHASE"
    vendor_country := object.get(inp.vendor, "country", "PL")
    vendor_country != "PL"
    tx_type := "IMPORT"
} else = tx_type {
    inp.invoice.direction == "PURCHASE"
    delivery_country := object.get(inp.delivery, "country", "PL")
    delivery_country != "PL"
    tx_type := "IMPORT"
} else = tx_type {
    inp.invoice.direction == "PURCHASE"
    tx_type := "DOMESTIC_PURCHASE"
} else = "UNKNOWN" {
    true
}

build_entity_status(inp) = status {
    object.get(inp.jdg_entrepreneur, "business_status", "") == "SUSPENDED"
    status := "SUSPENDED"
} else = status {
    object.get(inp.jdg_entrepreneur, "in_succession", false) == true
    status := "IN_SUCCESSIO"
} else = status {
    object.get(inp.jdg_entrepreneur, "is_unregistered_activity", false) == true
    status := "UNREGISTERED"
} else = "ACTIVE" {
    true
}

# P03 GLM52 FIX: else-chain zamiast nielegalnych inline-guards (quarter = 1 { cond })
build_evaluation_quarter(inp) = 1 {
    eval_date := object.get(inp, "evaluation_datetime", "2026-01-01")
    month := to_number(substring(eval_date, 5, 2))
    month <= 3
} else = 2 {
    eval_date := object.get(inp, "evaluation_datetime", "2026-01-01")
    month := to_number(substring(eval_date, 5, 2))
    month > 3
    month <= 6
} else = 3 {
    eval_date := object.get(inp, "evaluation_datetime", "2026-01-01")
    month := to_number(substring(eval_date, 5, 2))
    month > 6
    month <= 9
} else = 4 {
    eval_date := object.get(inp, "evaluation_datetime", "2026-01-01")
    month := to_number(substring(eval_date, 5, 2))
    month > 9
}

is_cross_border_transaction(inp) = true {
    object.get(inp.vendor, "country", "PL") != "PL"
} else = true {
    object.get(inp.delivery, "country", "PL") != "PL"
} else = true {
    object.get(inp.invoice, "service_performed_country", "PL") != "PL"
} else = true {
    object.get(inp.invoice, "vat_place_of_supply", "PL") != "PL"
} else = true {
    inp.invoice.procedure == "EXPORT"
} else = false {
    true
}

is_vat_payer_check(inp) = true {
    inp.jdg_entrepreneur.vat_status == "ACTIVE"
} else = false {
    true
}

requires_ksef_check(inp) = true {
    object.get(input, "evaluation_datetime", "2026-01-01") >= "2026-02-01"
    inp.invoice.direction == "SALE"
    inp.invoice.document_type == "INVOICE"
} else = false {
    true
}

# ── Shard Router: wybiera optymalną ścieżkę ewaluacji ───────────────────────

# ── Shard Router: wybiera optymalną ścieżkę ewaluacji — v7.0 ACTIVE (MR-1)
# Router jest teraz AKTYWNY — dla transakcji krajowych pomija niepotrzebne pakiety.
# Redukuje latency OPA z ~28s do ~8-12s dla standardowych transakcji.
# ── Shard Router: v7.0 DEPRECATED — zastąpiony przez inline warunki w final_verdict
# Zachowany dla kompatybilności wstecznej i dokumentacji architektonicznej.
# Nie używany w runtime — final_verdict używa bezpośrednich warunków inline.
# @deprecated since v7.0 — użyj inline warunków w final_verdict
shard_selector_deprecated(ctx) = shard_packages {
    ctx.is_cross_border == true
    shard_packages := ["risk", "kks", "routing", "compliance", "crossborder",
        "post_brexit", "vat.substantive", "vat.deductions", "vat.procedures"]
} else = shard_packages {
    ctx.transaction_type == "DOMESTIC_SALE"
    shard_packages := ["risk", "kks", "routing", "compliance", "vat.substantive",
        "pit.forms", "pit.kup", "accounting", "business", "zus"]
} else = shard_packages {
    ctx.transaction_type == "DOMESTIC_PURCHASE"
    shard_packages := ["risk", "kks", "routing", "compliance", "vat.substantive",
        "vat.deductions", "vat.procedures", "accounting", "corrections", "pit.kup"]
} else = shard_packages {
    ctx.entity_status == "SUSPENDED"
    shard_packages := ["risk", "kks", "routing", "business", "zus", "accounting"]
} else = shard_packages {
    # Fallback: pełny łańcuch bezpieczeństwa
    shard_packages := ["risk", "kks", "routing", "compliance"]
}

# ── Shard Routing Decision: v7.0 DEPRECATED — zastąpiony przez inline warunki
# @deprecated since v7.0 — użyj inline warunków w final_verdict
use_full_chain_deprecated(ctx) = true {
    # Pełny łańcuch wymagany gdy:
    # 1. Transakcja transgraniczna
    # 2. JDG zawieszona lub w sukcesji
    # 3. Wykryto potencjalne ryzyko fraud
    ctx.is_cross_border == true
}

use_full_chain_deprecated(ctx) = true {
    ctx.entity_status != "ACTIVE"
}

use_full_chain_deprecated(ctx) = false {
    # Shard wystarczy dla standardowych transakcji krajowych
    ctx.transaction_type == "DOMESTIC_SALE"
    ctx.entity_status == "ACTIVE"
    ctx.is_cross_border == false
}

use_full_chain_deprecated(ctx) = false {
    ctx.transaction_type == "DOMESTIC_PURCHASE"
    ctx.entity_status == "ACTIVE"
} else = true {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Safe Merge helpers (Phase 5 P0 — ochrona niemutowalnych werdyktów ZUS)
#
# Problem: object.union nadpisuje klucze bez ostrzeżenia. Jeśli risk.decide
# (nadrzędny w chainie) ustawi zus_health_rate na "", nadpisze poprawną
# stawkę z pakietu zus (P720/P722/P724).
#
# Rozwiązanie: safe_merge — jeśli pierwszy argument ma immutable_verdict=true,
# jego wartości NIE są nadpisywane przez drugi argument.
# ═══════════════════════════════════════════════════════════════════════════════

# P34 FIX (Atak 2+35): Immutable Verdict Allowlist
immutable_verdict_allowlist := {
    "jdg.zus", "jdg.zus.sickness_benefits", "jdg.zus.enterprise_benefits",
    "jdg.zus.health_contribution", "jdg.business", "jdg.security.fortress"
}

has_immutable_flag(v) {
    object.get(v, "immutable_verdict", false) == true
    pkg := object.get(v, "package", "")
    immutable_verdict_allowlist[pkg]
}

# safe_merge(a, b): bezpieczny merge dwóch werdyktów.
#
# Trzy przypadki:
# 1. a ma immutable_verdict=true → zwróć a (a chronione przed nadpisaniem przez b)
# 2. b ma immutable_verdict=true → object.union(b, a) (b wygrywa konflikty)
#    Propaguje flagę immutable w górę łańcucha — chroni ZUS przed risk.decide
# 3. ani a ani b nie mają immutable_verdict → object.union(a, b) (a wygrywa,
#    zachowując oryginalną semantykę: zewnętrzny pakiet ma wyższy priorytet)
#
# UWAGA: Przypadek 2 oznacza, że gdy ZUS (z immutable_verdict) jest w łańcuchu,
# jego wartości wygrywają nawet z risk.decide. To zamierzone — ZUS jest
# prawnie niemutowalny. W praktyce risk BLOCK_AND_ALERT zachodzi PRZED
# mergem (PASS 0), więc nie ma konfliktu z routingiem.
safe_merge(a, _) = a {
    has_immutable_flag(a)
}

safe_merge(a, b) = object.union(b, a) {
    has_immutable_flag(b)
}

safe_merge(a, b) = object.union(a, b) {
    not has_immutable_flag(a)
    not has_immutable_flag(b)
}

# ═══════════════════════════════════════════════════════════════════════════════
# Multi-Pass Architecture (zgodna z Doc 34, Sekcja 1.3)
#
# INPUT ──► PASS 0: RISK ──────► PASS 1: ROUTING ──► PASS 2: COMPLIANCE ──────►
#              │ (BLOCK→abort)      │ (BLOCK→abort)     │
#              ▼                    ▼                   ▼
#         risk_verdict        routing_verdict     compliance_verdict
#
#         PASS 3: CROSSBORDER ──► PASS 4: VAT ──────► PASS 5: PIT ───────────►
#              │                    │                    │
#              ▼                    ▼                    ▼
#         cross_verdict        vat_verdict          pit_verdict
#
#         PASS 6: ALLOWANCES ──► PASS 7: ACCOUNTING ─► PASS 8: ZUS+BUSINESS+ ─►
#              │                    │                    │
#              ▼                    ▼                    ▼
#         allowances_verdict  accounting_verdict    misc_verdict
#
#         ► VERDICT MERGER ──► final_verdict
# ═══════════════════════════════════════════════════════════════════════════════

# ── Merged Final Verdict ──────────────────────────────────────────────────────
# Scala wszystkie pass-y w jeden finalny werdykt JDG.
#
# Phase 5 P0: Używamy safe_merge zamiast object.union, aby chronić
# niemutowalne werdykty ZUS (P720/P722/P724) przed nadpisaniem przez
# risk.decide lub inne pakiety z wyższym priorytetem.
#
# Kolejność (od najniższego priorytetu wewnątrz do najwyższego na zewnątrz):
# fallback → validation → mpips → rodo → retention → edelivery → digital →
# api_fallback → temporal → restructuring → environmental → employer →
# residency → tp → international → ksef_jpk → local_taxes →
# representation → audit → liability → corrections → mdr →
# gig_economy → business → accounting → zus → solidarity → allowances →
# elearning → transitions → exemptions → advances_returns → kup → forms →
# procedures → deductions → substantive → crossborder → post_brexit →
# compliance → routing → kks → risk
##    safe_merge chroni werdykty z flagą immutable_verdict=true
# (ZUS P720/P722/P724, business P914) przed przypadkowym nadpisaniem.
#
# PAS 8: conflicts pakiet działa POST-MERGE — analizuje input.invoice oraz
# input.jdg_entrepreneur (dane źródłowe) i wykrywa konflikty między domenami
# (IP Box vs B+R, reprezentacja vs marketing, auto VAT vs KUP, bad debt timing).
# NIE zmienia wartości — tylko flaguje do _cross_domain_conflicts.
# ═══════════════════════════════════════════════════════════════════════════════
# NEW v7.0: Sharded Final Verdict (MR-1 + DT-1) — Conditional Full Chain
#
# AKTYWNY SHARDED ROUTER: Dla transakcji DOMESTIC_SALE i DOMESTIC_PURCHASE
# z aktywnym statusem JDG, używa shard_selector() do pominięcia
# niepotrzebnych pakietów. Dla transakcji transgranicznych i niestandardowych
# statusów JDG, używa pełnego łańcucha (safe fallback).
#
# To redukuje liczbę ewaluowanych pakietów z ~55 do ~10 dla typowych
# transakcji krajowych — redukcja latency z ~28s do ~8-12s.
# ═══════════════════════════════════════════════════════════════════════════════

# Szybka ścieżka dla DOMESTIC_SALE z ACTIVE JDG (najczęstszy przypadek)
# v7.0 KRYTYCZNE-3 FIX: Dodano pakiety bezpieczeństwa (validation, edge_cases, ksef_jpk,
# aml, mdr, mdr_enterprise, api_fallback, conflicts) — fast-path jest teraz PEŁNY.
# Brakujące pakiety z full chain: crossborder, post_brexit, tp, solidarity, international,
# employer, environmental, restructuring, digital, retention, rodo, mpips, itd.
sharded_sale_verdict = safe_merge(risk.decide,
    safe_merge(kks.decide,
    safe_merge(routing.decide,
    safe_merge(compliance.decide,
    safe_merge(validation.decide,
    safe_merge(edge_cases.decide,
    safe_merge(ksef_jpk.decide,
    safe_merge(aml.decide,
    safe_merge(mdr.decide,
    safe_merge(mdr_enterprise.decide,
    safe_merge(api_fallback.decide,
    safe_merge(substantive.decide,
    safe_merge(forms.decide,
    safe_merge(missing_reliefs.decide,
    safe_merge(kup.decide,
    safe_merge(accounting.decide,
    safe_merge(business.decide,
    safe_merge(zus.decide,
    safe_merge(p33_uor_supplement.decide,
    safe_merge(p33_pcc_complete.decide,
    safe_merge(p33_excise_supplement.decide,
    safe_merge(p33_ordpu_kks_supplement.decide,
    safe_merge(p3233_innovations.decide,
    safe_merge(p01_innovations.decide,
    safe_merge(p02_innovations.decide,
    safe_merge(p03_innovations.decide,
    safe_merge(p04_innovations.decide,
    safe_merge(p05_innovations.decide,
    safe_merge(p06_innovations.decide,
    safe_merge(p07_innovations.decide,
    safe_merge(p08_innovations.decide,
    safe_merge(p09_innovations.decide,
    safe_merge(p10_innovations.decide,
    safe_merge(p11_innovations.decide,
    safe_merge(p12_innovations.decide,
    safe_merge(p13_innovations.decide,
    safe_merge(p14_innovations.decide,
    # ── PAS 15b: P15 Enterprise v8.0 PCC + Local Taxes + Excise (2026-08-01) ──
    # INN01-INN12: PCC Detection, PCC-3 Filler, Real Estate Classifier, Excise Warehouse,
    # Transport Calc, Exemption Analyzer, Multi-Tax Calendar, Suspension Manager,
    # Property Appeal, Rate Updater, Cross-Border Excise, PCC+VAT Firewall
    safe_merge(p15_innovations.decide,
    # ── PAS 16: P16 Enterprise v8.0 Business Lifecycle (2026-08-01) ──
    # INN01-INN12: Lifecycle Navigator, Tax Form Selector, Suspension Sim,
    # Succession Score, Gig Optimizer, Banking Aggregator, CEIDG Auto-File,
    # Health 360, Exit Simulator, Revenue Predictor, Employee Hiring, Company Transform
    # G1-G7: Auto-Form Generators (CEIDG-1, ZUS ZUA/ZWUA, VAT-Z, PIT-4R/11)
    # E1: Estonian CIT Full (Art. 28c-28t) | ET: Entrepreneur Test | SCA: Enhanced SCA
    safe_merge(p16_innovations.decide,
    safe_merge(autoform.decide,
    safe_merge(estonian_cit.decide,
    safe_merge(entrepreneur_test.decide,
    safe_merge(banking_sca.decide,
    safe_merge(p17_innovations.decide,
    safe_merge(pkpir_to_uor_transformer.decide,
    safe_merge(p35_coherence.decide,
    safe_merge(p35_gaps.decide,
    safe_merge(p35_innovations.decide,
    safe_merge(hyper_general.decide,
    safe_merge(hyper_mdr.decide,
    safe_merge(hyper_solidarity.decide,
    safe_merge(hyper_wis.decide,
    safe_merge(hyper_audit.decide,
    safe_merge(hyper_force_majeure.decide,
    safe_merge(hyper_family.decide,
    safe_merge(hyper_edelivery.decide,
    safe_merge(hyper_procurement.decide,
    safe_merge(hyper_fx.decide,
    safe_merge(hyper_limits.decide,
    safe_merge(hyper_sanctions.decide,
    safe_merge(hyper_deadlines.decide,
    safe_merge(hyper_misc.decide,
    safe_merge(p21_innovations.decide,
    safe_merge(p22_innovations.decide,
    safe_merge(p23_innovations.decide,
    safe_merge(p24_innovations.decide,
    safe_merge(p34_remaining.decide,
    safe_merge(fortress.decide,
    safe_merge(p34_innovations.decide,
    safe_merge(conflicts.decide,
        fallback.decide
    ))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))


# Shard dla DOMESTIC_PURCHASE z ACTIVE JDG (KRYTYCZNE-3 FIX)
# Teraz zawiera: risk, kks, routing, compliance, validation, edge_cases, ksef_jpk,
# aml, mdr, mdr_enterprise, api_fallback, vat.substantive, vat.deductions,
# vat.procedures, pit.kup, accounting, corrections, conflicts
sharded_purchase_verdict = safe_merge(risk.decide,
    safe_merge(kks.decide,
    safe_merge(routing.decide,
    safe_merge(compliance.decide,
    safe_merge(validation.decide,
    safe_merge(edge_cases.decide,
    safe_merge(ksef_jpk.decide,
    safe_merge(aml.decide,
    safe_merge(mdr.decide,
    safe_merge(mdr_enterprise.decide,
    safe_merge(api_fallback.decide,
    safe_merge(substantive.decide,
    safe_merge(deductions.decide,
    safe_merge(procedures.decide,
    safe_merge(missing_reliefs.decide,
    safe_merge(kup.decide,
    safe_merge(accounting.decide,
    safe_merge(corrections.decide,
    safe_merge(p33_uor_supplement.decide,
    safe_merge(p33_pcc_complete.decide,
    safe_merge(p33_excise_supplement.decide,
    safe_merge(p33_ordpu_kks_supplement.decide,
    safe_merge(p3233_innovations.decide,
    safe_merge(p01_innovations.decide,
    safe_merge(p02_innovations.decide,
    safe_merge(p03_innovations.decide,
    safe_merge(p04_innovations.decide,
    safe_merge(p05_innovations.decide,
    safe_merge(p06_innovations.decide,
    safe_merge(p07_innovations.decide,
    safe_merge(p08_innovations.decide,
    safe_merge(p09_innovations.decide,
    safe_merge(p10_innovations.decide,
    safe_merge(p11_innovations.decide,
    safe_merge(p12_innovations.decide,
    safe_merge(p13_innovations.decide,
    safe_merge(p14_innovations.decide,
    # ── PAS 15b: P15 Enterprise v8.0 PCC + Local Taxes + Excise (2026-08-01) ──
    safe_merge(p15_innovations.decide,
    # ── PAS 16: P16 Enterprise v8.0 Business Lifecycle (2026-08-01) ──
    safe_merge(p16_innovations.decide,
    safe_merge(autoform.decide,
    safe_merge(estonian_cit.decide,
    safe_merge(entrepreneur_test.decide,
    safe_merge(banking_sca.decide,
    safe_merge(p17_innovations.decide,
    safe_merge(pkpir_to_uor_transformer.decide,
    safe_merge(p35_coherence.decide,
    safe_merge(p35_gaps.decide,
    safe_merge(p35_innovations.decide,
    safe_merge(hyper_general.decide,
    safe_merge(hyper_mdr.decide,
    safe_merge(hyper_solidarity.decide,
    safe_merge(hyper_wis.decide,
    safe_merge(hyper_audit.decide,
    safe_merge(hyper_force_majeure.decide,
    safe_merge(hyper_family.decide,
    safe_merge(hyper_edelivery.decide,
    safe_merge(hyper_procurement.decide,
    safe_merge(hyper_fx.decide,
    safe_merge(hyper_limits.decide,
    safe_merge(hyper_sanctions.decide,
    safe_merge(hyper_deadlines.decide,
    safe_merge(hyper_misc.decide,
    safe_merge(p21_innovations.decide,
    safe_merge(p24_innovations.decide,
    safe_merge(p34_remaining.decide,
    safe_merge(fortress.decide,
    safe_merge(p34_innovations.decide,
    safe_merge(conflicts.decide,
        fallback.decide
    ))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))


full_final_verdict = safe_merge(risk.decide,
    safe_merge(kks.decide,
    safe_merge(enterprise_penalties.decide,
    safe_merge(routing.decide,
    safe_merge(compliance.decide,
    safe_merge(aml.decide,
    safe_merge(post_brexit.decide,
    safe_merge(crossborder.decide,
    safe_merge(substantive.decide,
    safe_merge(deductions.decide,
    safe_merge(procedures.decide,
    safe_merge(forms.decide,
    safe_merge(kup.decide,
    safe_merge(advances.decide,
    safe_merge(missing_reliefs.decide,
    safe_merge(exemptions.decide,
    safe_merge(art21_exemptions.decide,
    safe_merge(transitions.decide,
    safe_merge(elearning.decide,
    safe_merge(allowances.decide,
    safe_merge(solidarity.decide,
    safe_merge(zus.decide,
    safe_merge(sickness_benefits.decide,
    safe_merge(health_contribution.decide,
    safe_merge(accounting.decide,
    safe_merge(pkpir.decide,
    safe_merge(pkpir_validation.decide,
    safe_merge(depreciation.decide,
    safe_merge(business.decide,
    safe_merge(gig_economy.decide,
    safe_merge(mdr.decide,
    safe_merge(mdr_enterprise.decide,
    safe_merge(corrections.decide,
    safe_merge(liability.decide,
    safe_merge(audit.decide,
    safe_merge(representation.decide,
    safe_merge(local_taxes.decide,
    safe_merge(pcc_enterprise.decide,
    safe_merge(ksef_jpk.decide,
    safe_merge(jpk_cit.decide,
    safe_merge(international.decide,
    safe_merge(tp.decide,
    safe_merge(residency.decide,
    safe_merge(employer.decide,
    safe_merge(environmental.decide,
    safe_merge(bdo.decide,
    safe_merge(restructuring.decide,
    safe_merge(temporal.decide,
    safe_merge(api_fallback.decide,
    safe_merge(digital.decide,
    safe_merge(retention.decide,
    safe_merge(edelivery.decide,
    safe_merge(rodo.decide,
    safe_merge(rodo_extended.decide,
    safe_merge(mpips.decide,
    safe_merge(validation.decide,
    safe_merge(p33_uor_supplement.decide,
    safe_merge(p33_pcc_complete.decide,
    safe_merge(p33_excise_supplement.decide,
    safe_merge(p33_ordpu_kks_supplement.decide,
    safe_merge(p3233_innovations.decide,
    safe_merge(p01_innovations.decide,
    safe_merge(p02_innovations.decide,
    safe_merge(p03_innovations.decide,
    safe_merge(p04_innovations.decide,
    safe_merge(p05_innovations.decide,
    safe_merge(p06_innovations.decide,
    safe_merge(p07_innovations.decide,
    safe_merge(p08_innovations.decide,
    safe_merge(p09_innovations.decide,
    safe_merge(p10_innovations.decide,
    safe_merge(p11_innovations.decide,
    safe_merge(p12_innovations.decide,
    safe_merge(p13_innovations.decide,
    safe_merge(p14_innovations.decide,
    # ── PAS 15b: P15 Enterprise v8.0 PCC + Local Taxes + Excise (2026-08-01) ──
    safe_merge(p15_innovations.decide,
    # ── PAS 16: P16 Enterprise v8.0 Business Lifecycle (2026-08-01) ──
    safe_merge(p16_innovations.decide,
    safe_merge(autoform.decide,
    safe_merge(estonian_cit.decide,
    safe_merge(entrepreneur_test.decide,
    safe_merge(banking_sca.decide,
    # ── PAS 19: P17 Enterprise v8.0 Edge Cases + Conflicts (2026-08-01) ──
    safe_merge(p17_innovations.decide,
    safe_merge(mdr_auto_generator.decide,
    safe_merge(wdt_document_tracker.decide,
    safe_merge(exit_tax_interest_calculator.decide,
    safe_merge(cfc_auto_classifier.decide,
    safe_merge(pkpir_to_uor_transformer.decide,
    safe_merge(hyper_general.decide,
    safe_merge(hyper_mdr.decide,
    safe_merge(hyper_solidarity.decide,
    safe_merge(hyper_wis.decide,
    safe_merge(hyper_audit.decide,
    safe_merge(hyper_force_majeure.decide,
    safe_merge(hyper_family.decide,
    safe_merge(hyper_edelivery.decide,
    safe_merge(hyper_procurement.decide,
    safe_merge(hyper_fx.decide,
    safe_merge(hyper_limits.decide,
    safe_merge(hyper_sanctions.decide,
    safe_merge(hyper_deadlines.decide,
    safe_merge(hyper_misc.decide,
    safe_merge(p21_innovations.decide,
    safe_merge(p34_remaining.decide,
    safe_merge(p34_innovations.decide,
    safe_merge(fortress.decide,
        fallback.decide
    )))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))


# ═══════════════════════════════════════════════════════════════════════════════
# PASS-0 GATE: Early Abort on BLOCK_AND_ALERT (Rekomendacja 5)
#
# Jeżeli risk.decide zwraca BLOCK_AND_ALERT, zwracamy minimalny werdykt
# (risk + kks + routing + fallback) BEZ ewaluacji pełnego łańcucha.
# W Rego, warunek w rule head sprawdzany jest PRZED body, więc
# gated_abort_verdict matchuje tylko gdy risk/routing = BLOCK_AND_ALERT.
#
# W przeciwnym razie przepływ przechodzi do else = sharded/full chain.
# Redukuje latency o ~40-60% dla transakcji fraudowych.
#
# Używamy safe_merge dla spójności z resztą orkiestratora.
# ═══════════════════════════════════════════════════════════════════════════════

# PASS-0 Gate: minimalny werdykt przy BLOCK_AND_ALERT (risk)
gated_abort_verdict = safe_merge(risk.decide,
    safe_merge(kks.decide,
    safe_merge(enterprise_penalties.decide,
    safe_merge(routing.decide,
    safe_merge(validation.decide,
    safe_merge(p33_uor_supplement.decide,
    safe_merge(p33_pcc_complete.decide,
    safe_merge(p33_excise_supplement.decide,
    safe_merge(p33_ordpu_kks_supplement.decide,
    safe_merge(p3233_innovations.decide,
    safe_merge(p12_innovations.decide,
    safe_merge(p13_innovations.decide,
    safe_merge(p14_innovations.decide,
    safe_merge(mdr_auto_generator.decide,
    safe_merge(pkpir_to_uor_transformer.decide,
    safe_merge(hyper_general.decide,
    safe_merge(hyper_mdr.decide,
    safe_merge(hyper_solidarity.decide,
    safe_merge(hyper_wis.decide,
    safe_merge(hyper_audit.decide,
    safe_merge(hyper_force_majeure.decide,
    safe_merge(hyper_family.decide,
    safe_merge(hyper_edelivery.decide,
    safe_merge(hyper_procurement.decide,
    safe_merge(hyper_fx.decide,
    safe_merge(hyper_limits.decide,
    safe_merge(hyper_sanctions.decide,
    safe_merge(hyper_deadlines.decide,
    safe_merge(hyper_misc.decide,
    safe_merge(p21_innovations.decide,
    safe_merge(p34_remaining.decide,
    safe_merge(p34_innovations.decide,
    safe_merge(fortress.decide,
        fallback.decide
    ))))))))))))))))))))))))))))))))) {
    risk.decide._routing == "BLOCK_AND_ALERT"
}


# PASS-0 Gate: routing BLOCK_AND_ALERT (gdy risk nie blokuje ale routing tak)
gated_abort_verdict = safe_merge(risk.decide,
    safe_merge(kks.decide,
    safe_merge(enterprise_penalties.decide,
    safe_merge(routing.decide,
    safe_merge(p33_uor_supplement.decide,
    safe_merge(p33_pcc_complete.decide,
    safe_merge(p33_excise_supplement.decide,
    safe_merge(p33_ordpu_kks_supplement.decide,
    safe_merge(p3233_innovations.decide,
    safe_merge(p12_innovations.decide,
    safe_merge(p13_innovations.decide,
    safe_merge(p14_innovations.decide,
    safe_merge(mdr_auto_generator.decide,
    safe_merge(pkpir_to_uor_transformer.decide,
    safe_merge(hyper_general.decide,
    safe_merge(hyper_mdr.decide,
    safe_merge(hyper_solidarity.decide,
    safe_merge(hyper_wis.decide,
    safe_merge(hyper_audit.decide,
    safe_merge(hyper_force_majeure.decide,
    safe_merge(hyper_family.decide,
    safe_merge(hyper_edelivery.decide,
    safe_merge(hyper_procurement.decide,
    safe_merge(hyper_fx.decide,
    safe_merge(hyper_limits.decide,
    safe_merge(hyper_sanctions.decide,
    safe_merge(hyper_deadlines.decide,
    safe_merge(hyper_misc.decide,
    safe_merge(p21_innovations.decide,
    safe_merge(p34_remaining.decide,
    safe_merge(p34_innovations.decide,
    safe_merge(fortress.decide,
        fallback.decide
    )))))))))))))))))))))))))))))))) {
    routing.decide._routing == "BLOCK_AND_ALERT"
}


# ═══════════════════════════════════════════════════════════════════════════════
# v7.0 SHARDED ROUTER ACTIVE: Wybor sciezki na podstawie kontekstu
# PASS-0 GATE: Jeśli risk/routing BLOCK_AND_ALERT → gated_abort_verdict
# DOMESTIC_SALE → sharded_sale_verdict (VAT+PIT+ZUS+bezpieczenstwo)
# DOMESTIC_PURCHASE → sharded_purchase_verdict (VAT deductions+corrections+KUP+bezpieczenstwo)
# cross-border / non-ACTIVE → full_final_verdict (wszystkie pakiety dla bezpieczenstwa)
# ═══════════════════════════════════════════════════════════════════════════════
selected_final_verdict = gated_abort_verdict {
    risk.decide._routing == "BLOCK_AND_ALERT"
} else = gated_abort_verdict {
    routing.decide._routing == "BLOCK_AND_ALERT"
} else = sharded_sale_verdict {
    ctx := routing_context
    ctx.is_cross_border == false
    ctx.entity_status == "ACTIVE"
    ctx.transaction_type == "DOMESTIC_SALE"
} else = sharded_purchase_verdict {
    ctx := routing_context
    ctx.is_cross_border == false
    ctx.entity_status == "ACTIVE"
    ctx.transaction_type == "DOMESTIC_PURCHASE"
} else = full_final_verdict {
    true
}

# ── PAS 8: Cross-Domain Conflict Detection (Post-Merge) ────────────────────
# v7.0 FIX (Rekomendacja 4): Zmieniono z object.union(final_verdict, conflicts.decide)
# na safe_merge(final_verdict, conflicts.decide). Teraz final_verdict (z risk, routing, VAT,
# PIT, ZUS) ma priorytet nad conflicts dla pól _routing/rule_id — conflicts
# NIE może nadpisać BLOCK_AND_ALERT z risk. Pole _cross_domain_conflicts
# jest tylko do odczytu, nie zmienia decyzji.
final_verdict_with_conflicts = safe_merge(selected_final_verdict, conflicts.decide)

# Enterprise Enrichment: dodaj analizy strategiczne do finalnego werdyktu
# v7.0 FIX (Rekomendacja 6): object.union → safe_merge. Pakiety advisory
# NIE mogą nadpisać kluczowych pól podatkowych (vat_rate, pit_rate, _routing).
# PAS 9: S1-S5 — analizy strategiczne (tax_opt, cross_domain, judicial, audit, strategic)
# PAS 10: S6-S10 — moduły operacyjne enterprise v5.1 (KSeF, PPK/PFRON, cashflow, form_transition, banking)
# PAS 11: S11-S13 — moduły deklaracyjno-monitorujące enterprise v5.2 (annual_declaration, jpk_v7_autogen, legislative_monitor)
final_verdict_enriched = safe_merge(final_verdict_with_conflicts,
    safe_merge(tax_optimization.decide,
    safe_merge(cross_domain_hub.decide,
    safe_merge(judicial_rulings.decide,
    safe_merge(audit_defense.decide,
    safe_merge(strategic_advisor.decide,
    safe_merge(ksef_resilience.decide,
    safe_merge(ppk_pfron.decide,
    safe_merge(cashflow_predictor.decide,
    safe_merge(form_transition.decide,
    safe_merge(banking.decide,
    safe_merge(annual_declaration.decide,
    safe_merge(jpk_v7_autogen.decide,
    safe_merge(legislative_monitor.decide,
    # ── PAS 12: Enterprise v6.0 Neural & Compliance Layer (2026-07-19) ──
    # S14: Neural Rule Mesh — cross-domain intelligence fabric
    # S15: NKUP Enterprise Complete — Art. 23 PIT full coverage
    # S16: Exit Tax + MDR Enterprise — cross-border tax obligations
    # S16b: MDR DAC6 Enterprise — mandatory disclosure rules (hallmarks A-E)
    safe_merge(neural_mesh.decide,
    safe_merge(nkup_enterprise.decide,
    safe_merge(exit_tax_mdr.decide,
    safe_merge(mdr_dac6.decide,
    # ── PAS 12b: P13 Cross-Border Advanced Modules (2026-07-31) ──
    # Exit Tax Interest Calculator, MDR Auto-Generator, WDT Doc Tracker,
    # CFC Auto-Classifier, ViDA DRR Full, DAC8 Report Gen, CBAM Full
    safe_merge(exit_tax_interest_calculator.decide,
    safe_merge(mdr_auto_generator.decide,
    safe_merge(wdt_document_tracker.decide,
    safe_merge(cfc_auto_classifier.decide,
    safe_merge(vida_drr_full.decide,
    safe_merge(dac8_report_generator.decide,
    safe_merge(cbam_full.decide,
    safe_merge(p14_innovations.decide,
    # ── PAS 15b: P15 Enterprise v8.0 PCC + Local Taxes + Excise (2026-08-01) ──
    safe_merge(p15_innovations.decide,
    # ── PAS 16: P16 Enterprise v8.0 Business Lifecycle (2026-08-01) ──
    safe_merge(p16_innovations.decide,
    safe_merge(autoform.decide,
    safe_merge(estonian_cit.decide,
    safe_merge(entrepreneur_test.decide,
    safe_merge(banking_sca.decide,
    # ── PAS 19: P17 Enterprise v8.0 Edge Cases + Conflicts (2026-08-01) ──
    safe_merge(p17_innovations.decide,
    # ── PAS 13: Enterprise v6.1 Accounting Live Layer (2026-07-19) ──
    # S17: PKPiR Enterprise Live — active column 1-17 validation
    # S18: UoR Enterprise Live — full accounting law compliance
    safe_merge(pkpir_live.decide,
    safe_merge(uor_live.decide,
    # ── PAS 14: Enterprise v6.2 Class IX Complete (2026-07-19) ──
    # S19: Excise Enterprise Complete — fuels, alcohol, tobacco, energy, warehouse
    # S20: Local Procedures Enterprise — PCC enforcement, property exemptions, cross-tax
    safe_merge(excise_enterprise.decide,
    safe_merge(procedures_enterprise.decide,
    # ── PAS 15: Enterprise v7.0 Deep Coverage Layer (2026-07-19) ──
    # S21: VAT Substantive Complete — Art. 11-135 full procedural coverage
    # S22: Tax Authority Interaction Engine — auto-korespondencja z US/KAS/ZUS
    # S23: Sanctions & Penalty Optimization — KKS gradacja + decision tree
    # S24: Holistic JDG Lifecycle Manager — pełny cykl życia firmy
    safe_merge(vat_substantive_complete.decide,
    safe_merge(tax_authority_interaction.decide,
    safe_merge(sanctions_optimization.decide,
    safe_merge(lifecycle_manager.decide,
    # ── PAS 16: Enterprise v7.0 FAZA 3 Meta Layer (2026-07-25) ──
    # S25-S27: Hyper Plan45 Meta, WIS API, ePUAP
    safe_merge(hyper_plan45_meta.decide,
    safe_merge(wis_api.decide,
    safe_merge(epuap.decide,
    # ── PAS 17: Enterprise v7.0 Audit Full Implementation (2026-07-25) ──
    # CR1-CR4, H1-H7, M1-M6, I1-I5: 8 pakietów — ulgi, optymalizacja, symulacja
    safe_merge(thermo_relief.decide,
    safe_merge(rd_relief.decide,
    safe_merge(ipbox.decide,
    safe_merge(cross_relief.decide,
    safe_merge(donation_relief.decide,
    safe_merge(tax_loss_harvesting.decide,
    safe_merge(family_estonian.decide,
    safe_merge(hyper_general.decide,
    safe_merge(hyper_mdr.decide,
    safe_merge(hyper_solidarity.decide,
    safe_merge(hyper_wis.decide,
    safe_merge(hyper_audit.decide,
    safe_merge(hyper_force_majeure.decide,
    safe_merge(hyper_family.decide,
    safe_merge(hyper_edelivery.decide,
    safe_merge(hyper_procurement.decide,
    safe_merge(hyper_fx.decide,
    safe_merge(hyper_limits.decide,
    safe_merge(hyper_sanctions.decide,
    safe_merge(hyper_deadlines.decide,
    safe_merge(hyper_misc.decide,
    safe_merge(p21_innovations.decide,
    safe_merge(p22_innovations.decide,
    safe_merge(p23_innovations.decide,
    safe_merge(p24_innovations.decide,
        form_optimizer.decide
    )))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))

# ═══════════════════════════════════════════════════════════════════════════════
# KRYTYCZNE-2 FIX: Provenance + ADR-006 Immutable Audit Trail
# Budujemy _package_decisions mapę dla provenance.enrich_verdict()
# i wzbogacamy final_verdict_enriched o _provenance_tree.
# v7.0 COMPLETE: Zawiera WSZYSTKIE pakiety (core ~55 + enterprise ~38 = ~93 pakiety).
# ═══════════════════════════════════════════════════════════════════════════════
_package_decisions := {
    # PAS 0: Gate
    "jdg.risk": risk.decide,
    "jdg.kks": kks.decide,
    "jdg.kks.enterprise_penalties": enterprise_penalties.decide,
    "jdg.routing": routing.decide,
    # PAS 1-2: Compliance
    "jdg.compliance": compliance.decide,
    "jdg.compliance.aml": aml.decide,
    "jdg.validation": validation.decide,
    "jdg.edge_cases": edge_cases.decide,
    "jdg.ksef_jpk": ksef_jpk.decide,
    "jdg.mdr": mdr.decide,
    "jdg.mdr.enterprise": mdr_enterprise.decide,
    "jdg.api_fallback": api_fallback.decide,
    # PAS 3: Crossborder (+ V3-08: domknięcie wiringu orphan-pakietów)
    "jdg.crossborder": crossborder.decide,
    "jdg.crossborder.post_brexit": post_brexit.decide,
    "jdg.crossborder.v3_08": crossborder_v3_08.decide,
    "jdg.international": international.decide,
    "jdg.tp": tp.decide,
    "jdg.tp.hyper": tp_hyper.decide,
    "jdg.mdr.hallmarks": mdr_hallmarks.decide,
    "jdg.mdr.hyper": mdr_hyper.decide,
    "jdg.exit_tax_cfc": exit_tax_cfc.decide,
    "jdg.business.v3_09": business_v3_09.decide,
    # ── V3-10: domknięcie wiringu orphan-pakietów PCC/lokalne/akcyza ──
    "jdg.local_taxes.pcc": lt_pcc.decide,
    "jdg.local_taxes.real_estate": lt_real_estate.decide,
    "jdg.local_taxes.transport": lt_transport.decide,
    "jdg.local_taxes.plan26": lt_plan26.decide,
    "jdg.akcyza.alcohol_tobacco": akcyza_alcohol.decide,
    "jdg.akcyza.fuel_energy": akcyza_fuel.decide,
    "jdg.local.enterprise": local_enterprise.decide,
    "jdg.local_taxes.v3_10": local_taxes_v3_10.decide,
    # ── V3-11: domknięcie wiringu orphan-pakietów KSeF/JPK/e-Doręczenia ──
    "jdg.ksef_innovations": ksef_innov.decide,
    "jdg.ksef_outbox": ksef_outbox.decide,
    "jdg.ksef_offline_queue": ksef_offq.decide,
    "jdg.ksef_sandbox": ksef_sandbox.decide,
    "jdg.ksef_upo_tracker": ksef_upo.decide,
    "jdg.ksef_receipt_digest": ksef_digest.decide,
    "jdg.ksef_sanction_monitor": ksef_sanction.decide,
    "jdg.jpk_corrections": jpk_corrections.decide,
    "jdg.jpk_kr_st": jpk_kr_st.decide,
    "jdg.edelivery_gateway": edelivery_gw.decide,
    "jdg.enterprise.edelivery_gateway": edelivery_gw2.decide,
    "jdg.esig_auto": esig_auto.decide,
    "jdg.enterprise.wis_autorequester": wis_auto.decide,
    "jdg.ksef_jpk.v3_11": ksef_jpk_v3_11.decide,
    # ── V3-12: domknięcie wiringu orphan-pakietów RODO/AML/BDO/HR ──
    "jdg.micro.aml_cbdd": aml_cbdd.decide,
    "jdg.micro.aml_ryzyko": aml_ryzyko.decide,
    "jdg.micro.aml_str_gif": aml_str_gif.decide,
    "jdg.micro.aml_transakcje": aml_transakcje.decide,
    "jdg.compliance.v3_12": compliance_v3_12.decide,
    "jdg.residency": residency.decide,
    # PAS 4: VAT
    "jdg.vat.substantive": substantive.decide,
    "jdg.vat.deductions": deductions.decide,
    "jdg.vat.procedures": procedures.decide,
    # PAS 5: PIT
    "jdg.pit.forms": forms.decide,
    "jdg.pit.kup": kup.decide,
    "jdg.pit.advances": advances.decide,
    "jdg.pit.advances_returns": advances_returns.decide,
    "jdg.pit.exemptions": exemptions.decide,
    "jdg.pit.art21_exemptions": art21_exemptions.decide,
    "jdg.pit.transitions": transitions.decide,
    "jdg.pit.zero_doubt": pit_zero_doubt.decide,
    "jdg.vat.zero_doubt": vat_zero_doubt.decide,
    "jdg.pit.elearning": elearning.decide,
    "jdg.pit.missing_reliefs": missing_reliefs.decide,
    # PAS 6: Allowances
    "jdg.allowances": allowances.decide,
    "jdg.solidarity": solidarity.decide,
    # PAS 7: ZUS + Accounting + Business
    "jdg.zus": zus.decide,
    "jdg.zus.sickness_benefits": sickness_benefits.decide,
    "jdg.zus.health_contribution": health_contribution.decide,
    "jdg.accounting": accounting.decide,
    "jdg.accounting.pkpir": pkpir.decide,
    "jdg.accounting.pkpir_validation": pkpir_validation.decide,
    "jdg.accounting.depreciation": depreciation.decide,
    "jdg.business": business.decide,
    "jdg.business.gig_economy": gig_economy.decide,
    "jdg.corrections": corrections.decide,
    # Misc packages
    "jdg.liability": liability.decide,
    "jdg.audit": audit.decide,
    "jdg.representation": representation.decide,
    "jdg.local_taxes": local_taxes.decide,
    "jdg.local_taxes.pcc_enterprise": pcc_enterprise.decide,
    "jdg.jpk_cit": jpk_cit.decide,
    "jdg.employer": employer.decide,
    "jdg.environmental": environmental.decide,
    "jdg.environmental.bdo": bdo.decide,
    "jdg.restructuring": restructuring.decide,
    "jdg.temporal": temporal.decide,
    "jdg.digital": digital.decide,
    "jdg.retention": retention.decide,
    "jdg.edelivery": edelivery.decide,
    "jdg.rodo": rodo.decide,
    "jdg.rodo_extended": rodo_extended.decide,
    "jdg.mpips": mpips.decide,
    "jdg.conflicts": conflicts.decide,
    "jdg.fallback": fallback.decide,
    "jdg.security.fortress": fortress.decide,
    "jdg.p34_remaining": p34_remaining.decide,
    "jdg.p34_innovations": p34_innovations.decide,
    "jdg.p35_coherence": p35_coherence.decide,
    "jdg.p35_gaps": p35_gaps.decide,
    "jdg.p35_innovations": p35_innovations.decide,
    "jdg.p33_uor_supplement": p33_uor_supplement.decide,
    "jdg.p33_pcc_complete": p33_pcc_complete.decide,
    "jdg.p33_excise_supplement": p33_excise_supplement.decide,
    "jdg.p33_ordpu_kks_supplement": p33_ordpu_kks_supplement.decide,
    "jdg.p3233_innovations": p3233_innovations.decide,
    "jdg.p01_innovations": p01_innovations.decide,
    "jdg.p02_innovations": p02_innovations.decide,
    "jdg.p03_innovations": p03_innovations.decide,
    "jdg.p04_innovations": p04_innovations.decide,
    "jdg.p05_innovations": p05_innovations.decide,
    "jdg.p06_innovations": p06_innovations.decide,
    "jdg.p07_innovations": p07_innovations.decide,
    "jdg.p08_innovations": p08_innovations.decide,
    "jdg.p09_innovations": p09_innovations.decide,
    "jdg.p10_innovations": p10_innovations.decide,
    "jdg.p11_innovations": p11_innovations.decide,
    "jdg.p12_innovations": p12_innovations.decide,
    "jdg.p13_innovations": p13_innovations.decide,
    "jdg.p14_innovations": p14_innovations.decide,
    # ── PAS 15b: P15 Enterprise v8.0 PCC + Local Taxes + Excise (2026-08-01) ──
    "jdg.p15_innovations": p15_innovations.decide,
    # ── PAS 16: P16 Enterprise v8.0 Business Lifecycle (2026-08-01) ──
    "jdg.p16_innovations": p16_innovations.decide,
    "jdg.autoform": autoform.decide,
    "jdg.estonian_cit": estonian_cit.decide,
    "jdg.entrepreneur_test": entrepreneur_test.decide,
    "jdg.banking_sca": banking_sca.decide,
    "jdg.p17_innovations": p17_innovations.decide,
    "jdg.pkpir_to_uor_transformer": pkpir_to_uor_transformer.decide,
    "jdg.exit_tax_interest_calculator": exit_tax_interest_calculator.decide,
    "jdg.mdr_auto_generator": mdr_auto_generator.decide,
    "jdg.wdt_document_tracker": wdt_document_tracker.decide,
    "jdg.cfc_auto_classifier": cfc_auto_classifier.decide,
    "jdg.vida_drr_full": vida_drr_full.decide,
    "jdg.dac8_report_generator": dac8_report_generator.decide,
    "jdg.cbam_full": cbam_full.decide,
    # ── Enterprise PAS 9-11: Strategic & Operational (S1-S13) ──
    "jdg.tax_optimization": tax_optimization.decide,
    "jdg.cross_domain_hub": cross_domain_hub.decide,
    "jdg.judicial_rulings": judicial_rulings.decide,
    "jdg.audit_defense": audit_defense.decide,
    "jdg.strategic_advisor": strategic_advisor.decide,
    "jdg.ksef_resilience": ksef_resilience.decide,
    "jdg.ppk_pfron": ppk_pfron.decide,
    "jdg.cashflow_predictor": cashflow_predictor.decide,
    "jdg.form_transition": form_transition.decide,
    "jdg.banking": banking.decide,
    "jdg.annual_declaration": annual_declaration.decide,
    "jdg.jpk_v7_autogen": jpk_v7_autogen.decide,
    "jdg.legislative_monitor": legislative_monitor.decide,
    # ── Enterprise PAS 12-15: Neural, Accounting, Class IX, Deep Coverage (S14-S24) ──
    "jdg.neural_mesh": neural_mesh.decide,
    "jdg.nkup_enterprise": nkup_enterprise.decide,
    "jdg.exit_tax_mdr": exit_tax_mdr.decide,
    "jdg.mdr_dac6": mdr_dac6.decide,
    "jdg.pkpir_live": pkpir_live.decide,
    "jdg.uor_live": uor_live.decide,
    "jdg.local_taxes.excise_enterprise": excise_enterprise.decide,
    "jdg.local_taxes.procedures_enterprise": procedures_enterprise.decide,
    "jdg.vat_substantive_complete": vat_substantive_complete.decide,
    "jdg.tax_authority_interaction": tax_authority_interaction.decide,
    "jdg.sanctions_optimization": sanctions_optimization.decide,
    "jdg.lifecycle_manager": lifecycle_manager.decide,
    # ── Enterprise PAS 16-17: Meta Layer + Audit (S25+, CR/H/M) ──
    "jdg.hyper_plan45_meta": hyper_plan45_meta.decide,
    "jdg.wis_api": wis_api.decide,
    "jdg.epuap": epuap.decide,
    "jdg.pit.thermo_relief": thermo_relief.decide,
    "jdg.pit.rd_relief": rd_relief.decide,
    "jdg.pit.ipbox": ipbox.decide,
    "jdg.pit.cross_relief": cross_relief.decide,
    "jdg.pit.donation_relief": donation_relief.decide,
    "jdg.pit.tax_loss_harvesting": tax_loss_harvesting.decide,
    "jdg.pit.family_estonian": family_estonian.decide,
    "jdg.form_optimizer": form_optimizer.decide,
    # ── PAS 18b: P01 Fundament OPA v9.0 (2026-08-02) ──
    "jdg.rule_lifecycle": rule_lifecycle.decide,
    "jdg.reliability_guarantee": reliability_guarantee.decide,
    "jdg.p01_fundament_innovations": p01_fundament_innovations.decide,
    # ── PAS 18c: P02 Warstwa Decyzyjna Core v9.0 (2026-08-02) ──
    "jdg.adaptive_trust": adaptive_trust.decide,
    "jdg.conflict_declaration": conflict_declaration.decide,
    "jdg.decision_core_completeness": decision_core_completeness.decide,
    "jdg.p02_decision_core_innovations": p02_decision_core_innovations.decide,
    # ── PAS 18d: P03 VAT Macro Enterprise v9.0 (2026-08-02) ──
    "jdg.vat_rates_audit": vat_rates_audit.decide,
    "jdg.vat_deductions_audit": vat_deductions_audit.decide,
    "jdg.vat_mpp_split_payment": vat_mpp_split_payment.decide,
    "jdg.vat_fraud_detection": vat_fraud_detection.decide,
    "jdg.p03_vat_macro_innovations": p03_vat_macro_innovations.decide,
    "jdg.p04_vat_macro_enterprise": p04_vat_macro_enterprise.decide,
    "jdg.p05_vat_micro_atomic": p05_vat_micro_atomic.decide,
    "jdg.p06_pit_macro_enterprise": p06_pit_macro_enterprise.decide,
    "jdg.p07_pit_micro_atomic": p07_pit_micro_atomic.decide,
    "jdg.p08_zus_macro_enterprise": p08_zus_macro_enterprise.decide,
    "jdg.p04_vat_micro_innovations": p04_vat_micro_innovations.decide,
    "jdg.p05_pit_macro_innovations": p05_pit_macro_innovations.decide,
    "jdg.pit_macro_etap10": pit_macro_etap10.decide,
    "jdg.pit_micro_reliefs_etap11": pit_micro_reliefs_etap11.decide,
    "jdg.zus_core_etap12": zus_core_etap12.decide,
    "jdg.zus_micro_etap13": zus_micro_etap13.decide,
    "jdg.pkpir_etap14": pkpir_etap14.decide,
    "jdg.uor_etap15": uor_etap15.decide,
    "jdg.kks_ord_etap16": kks_ord_etap16.decide,
    "jdg.p06_pit_micro_innovations": p06_pit_micro_innovations.decide,
    "jdg.p07_zus_macro_innovations": p07_zus_macro_innovations.decide,
    "jdg.p08_zus_micro_innovations": p08_zus_micro_innovations.decide,
    "jdg.p09_ksiegowosc_pkpir_uor_innovations": p09_ksiegowosc_pkpir_uor_innovations.decide,
    "jdg.p10_kks_innovations": p10_kks_innovations.decide,
    "jdg.p11_ordynacja_podatkowa_innovations": p11_ordynacja_podatkowa_innovations.decide,
    "jdg.p12_crossborder_innovations": p12_crossborder_innovations.decide,
    "jdg.p13_ryczalt_cykl_zycia_innovations": p13_ryczalt_cykl_zycia_innovations.decide,
    "jdg.p14_pcc_lokalne_akcyza_innovations": p14_pcc_lokalne_akcyza_innovations.decide,
    "jdg.p15_srodowisko_bdo_innovations": p15_srodowisko_bdo_innovations.decide,
    "jdg.p16_rodo_aml_security_innovations": p16_rodo_aml_security_innovations.decide,
    "jdg.p17_ksef_jpk_edeklaracje_innovations": p17_ksef_jpk_edeklaracje_innovations.decide,
    "jdg.p18_automatyzacja_ksiegowosci_innovations": p18_automatyzacja_ksiegowosci_innovations.decide,
    "jdg.p19_hr_swiadczenia_innovations": p19_hr_swiadczenia_innovations.decide,
    "jdg.p20_neural_mesh_innovations": p20_neural_mesh_innovations.decide,
    "jdg.p21_opa_system_innovations": p21_opa_system_innovations.decide,
    "jdg.p22_validation_tools_innovations": p22_validation_tools_innovations.decide,
    "jdg.p23_test_rego_ci_innovations": p23_test_rego_ci_innovations.decide,
    "jdg.p24_audyt_kompletny_innovations": p24_audyt_kompletny_innovations.decide,
    # ── PAS 18m: P03 GLM52 Orkiestrator + Infra (2026-08-08) ──
    "jdg.p03_orchestrator_innovations": p03_orchestrator_innovations.decide,
    "jdg.runtime_invariants": runtime_invariants.report,
    # ── PAS 18o: R01 GLM52 Orkiestrator + Rdzeń Silnika (2026-08-14) ──
    "jdg.r01_orchestrator_core_innovations": r01_orchestrator_core_innovations.decide,
    # ── PAS 18p: R02 GLM52 VAT CORE + ENTERPRISE (2026-08-14) ──
    "jdg.r02_vat_core_innovations": r02_vat_core_innovations.decide,
    # ── PAS 18q: R03 GLM52 VAT WARSTWA MICRO (2026-08-14) ──
    "jdg.r03_vat_micro_innovations": r03_vat_micro_innovations.decide,
    "jdg.r04_pit_core_innovations": r04_pit_core_innovations.decide,
    "jdg.r05_pit_enterprise_innovations": r05_pit_enterprise_innovations.decide,
    "jdg.r06_zus_innovations": r06_zus_innovations.decide,
    "jdg.r07_kks_innovations": r07_kks_innovations.decide,
    "jdg.r08_ordynacja_obrona_innovations": r08_ordynacja_obrona_innovations.decide,
    "jdg.r09_ksiegowosc_pkpir_uor_innovations": r09_ksiegowosc_pkpir_uor_innovations.decide,
    "jdg.r10_crossborder_innovations": r10_crossborder_innovations.decide,
    "jdg.crossborder_etap17": crossborder_etap17.decide,
    "jdg.business_lifecycle_etap18": business_lifecycle_etap18.decide,
    "jdg.local_excise_etap19": local_excise_etap19.decide,
    "jdg.ksef_jpk_etap20": ksef_jpk_etap20.decide,
    "jdg.hyper_enterprise_contexts_etap22": hyper_enterprise_contexts_etap22.decide,
    "jdg.enterprise_ai_neural_etap23": enterprise_ai_neural_etap23.decide,
    "jdg.tests_ci_quality_etap24": tests_ci_quality_etap24.decide,
    "jdg.tools_api_rulestore_bundles_etap25": tools_api_rulestore_bundles_etap25.decide,
    "jdg.policies_mirror_sync_etap26": policies_mirror_sync_etap26.decide,
    "jdg.cross_domain_red_team_etap27": cross_domain_red_team_etap27.decide,
    "jdg.final_certification_etap28": final_certification_etap28.decide,
    "jdg.rodo_aml_bdo_hr_etap21": rodo_aml_bdo_hr_etap21.decide,
    "jdg.r11_pcc_lokalne_akcyza_innovations": r11_pcc_lokalne_akcyza_innovations.decide,
    "jdg.r12_ryczalt_cykl_zycia_innovations": r12_ryczalt_cykl_zycia_innovations.decide,
    "jdg.r13_hyper_konteksty_innovations": r13_hyper_konteksty_innovations.decide,
    "jdg.r14_rodo_aml_bdo_innovations": r14_rodo_aml_bdo_innovations.decide,
    "jdg.r15_ksef_jpk_edeklaracje_innovations": r15_ksef_jpk_edeklaracje_innovations.decide,
    "jdg.r16_system_opa_innovations": r16_system_opa_innovations.decide,
    "jdg.r17_enterprise_ai_innovations": r17_enterprise_ai_innovations.decide,
    "jdg.micro.vat.r03": micro_vat_r03.decide,
    "jdg.micro.vat": micro_vat_full.decide,
    "jdg.micro.jpk": micro_jpk_full.decide,
    "jdg.micro.jpk.plan33": micro_jpk_plan33.decide,
    "jdg.micro.pit": micro_pit_full.decide,
    "jdg.micro.pit.plan33": micro_pit_plan33.decide,
    "jdg.micro.pit.plan34": micro_pit_plan34.decide,
    "jdg.micro.amort_a22a": amort_a22a.decide,
    "jdg.micro.amort_a22b": amort_a22b.decide,
    "jdg.micro.amort_a22c": amort_a22c.decide,
    "jdg.micro.amort_a22h": amort_a22h.decide,
    "jdg.micro.amort_a22i": amort_a22i.decide,
    "jdg.micro.amort_a22k": amort_a22k.decide,
    "jdg.micro.amort_a22n": amort_a22n.decide,
    "jdg.micro.sus": micro_sus_full.decide,
    "jdg.micro.zdrowotna": micro_zdrowotna_full.decide,
    "jdg.micro.zasilkowa": micro_zasilkowa_full.decide,
    "jdg.micro.zus": micro_zus_plan33.decide,
    "jdg.micro.zus_atomic_p09": zus_micro_atomic_p09.decide,
    "jdg.micro.pkpir": micro_pkpir.decide,
    "jdg.micro.pkpir_columns": micro_pkpir_columns.decide,
    "jdg.micro.pkpir_corrections": micro_pkpir_corrections.decide,
    "jdg.micro.pkpir_costs": micro_pkpir_costs.decide,
    "jdg.micro.pkpir_nkup": micro_pkpir_nkup.decide,
    "jdg.micro.pkpir_revenue": micro_pkpir_revenue.decide,
    "jdg.micro.pkpir_remnant": micro_pkpir_remnant.decide,
    "jdg.micro.uor": micro_uor.decide,
    "jdg.micro.uor_plan33": micro_uor_plan33.decide,
    "jdg.micro.ksiegowosc_atomic_p10": ksiegowosc_atomic_p10.decide,
    "jdg.micro.kks_ord_atomic_p11": kks_ord_atomic_p11.decide,
    "jdg.micro.crossborder": micro_cb_full.decide,
    "jdg.micro.cb": micro_cb_plan33.decide,
    "jdg.micro.tp": micro_tp_plan33.decide,
    "jdg.micro.tax_trans": micro_tax_trans_plan33.decide,
    "jdg.micro.mdr": micro_mdr_plan33.decide,
    "jdg.micro.crossborder_atomic_p12": crossborder_atomic_p12.decide,
    "jdg.micro.ryczalt": micro_ryczalt_full.decide,
    "jdg.micro.ryc": micro_ryc_plan33.decide,
    "jdg.micro.ceidg": micro_ceidg_full.decide,
    "jdg.micro.plan33_ceidg": micro_ceidg_plan33.decide,
    "jdg.micro.pp": micro_pp_full.decide,
    "jdg.micro.sukcesja": micro_sukcesja_full.decide,
    "jdg.micro.succ": micro_succ_plan33.decide,
    "jdg.micro.ryczalt_cykl_atomic_p13": ryczalt_cykl_atomic_p13.decide,
    "jdg.micro.pcc": micro_pcc_full.decide,
    "jdg.micro.pcc.plan33": micro_pcc_plan33.decide,
    "jdg.micro.akcyza": micro_akcyza_full.decide,
    "jdg.micro.prop": micro_prop_plan33.decide,
    "jdg.micro.prop_transport": micro_prop_transport_plan33.decide,
    "jdg.micro.agricultural_tax": micro_agricultural_plan33.decide,
    "jdg.micro.pcc_lokalne_atomic_p14": pcc_lokalne_atomic_p14.decide,
    "jdg.micro.rodo": micro_rodo_full.decide,
    "jdg.micro.rodo.plan33": micro_rodo_plan33.decide,
    "jdg.micro.aml": micro_aml_full.decide,
    "jdg.micro.bdo_rejestracja": micro_bdo_rejestracja.decide,
    "jdg.micro.bdo_ewidencja": micro_bdo_ewidencja.decide,
    "jdg.micro.bdo_ewc": micro_bdo_ewc.decide,
    "jdg.micro.bdo_transport": micro_bdo_transport.decide,
    "jdg.micro.bdo_zezwolenia": micro_bdo_zezwolenia.decide,
    "jdg.micro.bdo_weee": micro_bdo_weee.decide,
    "jdg.micro.srodowisko": micro_srodowisko_full.decide,
    "jdg.micro.est": micro_est_plan33.decide,
    "jdg.micro.budownictwo": micro_budownictwo_full.decide,
    "jdg.micro.transport": micro_transport_full.decide,
    "jdg.micro.rodo_aml_bdo_atomic_p15": rodo_aml_bdo_atomic_p15.decide,
    "jdg.p21_innovations": p21_innovations.decide,
    "jdg.p22_innovations": p22_innovations.decide,
    "jdg.p23_innovations": p23_innovations.decide,
    "jdg.p24_innovations": p24_innovations.decide,
    "jdg.hyper.general": hyper_general.decide,
    "jdg.hyper.deadlines": hyper_deadlines.decide,
    "jdg.hyper.limits": hyper_limits.decide,
    "jdg.hyper.mdr": hyper_mdr.decide,
    "jdg.hyper.misc": hyper_misc.decide,
    "jdg.hyper.sanctions": hyper_sanctions.decide,
    "jdg.hyper.audit": hyper_audit.decide,
    "jdg.hyper.family": hyper_family.decide,
    "jdg.hyper.force_majeure": hyper_force_majeure.decide,
    "jdg.hyper.fx": hyper_fx.decide,
    "jdg.hyper.edelivery": hyper_edelivery.decide,
    "jdg.hyper.procurement": hyper_procurement.decide,
    "jdg.hyper.solidarity": hyper_solidarity.decide,
    "jdg.hyper.wis": hyper_wis.decide,
    "jdg.deadline_monitor": deadline_monitor.decide
}
_provenance_context := {
    "_package_decisions": _package_decisions,
    "_evaluation_ms": 0
}
final_verdict_with_provenance = provenance.enrich_verdict(final_verdict_enriched, _provenance_context)

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18b: P01 FUNDAMENT OPA v9.0 — Post-Provenance Merge
# Rule Lifecycle + Reliability Guarantee + Genius Ideas (Sekcje 2/4/7 P01).
# pakiety REPORT-owe: NIE nadpisują kluczowych pól decyzyjnych (safe_merge —
# final_verdict_with_provenance ma priorytet). Aktywowane wyłącznie flagami
# input.jdg_entrepreneur.rule_lifecycle_check / reliability_check /
# p01_fundament_check — w normalnym ruchu zwracają no_match (matched:false).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p01 = safe_merge(final_verdict_with_provenance,
    safe_merge(rule_lifecycle.decide,
    safe_merge(reliability_guarantee.decide,
    safe_merge(p01_fundament_innovations.decide,
        fallback.decide
    ))))

# final_verdict_p01 to najnowszy, kompletny werdykt z warstwą P01 Fundament
# OPA (lifecycle + reliability + genius ideas). Host może zapytać o tę ścieżkę
# lub o pakiety indywidualnie: data.jdg.rule_lifecycle.decide,
# data.jdg.reliability_guarantee.decide, data.jdg.p01_fundament_innovations.decide.

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18c: P02 WARSTWA DECYZYJNA CORE v9.0 — Post-Provenance Merge
# Adaptive Trust + Conflict Declaration + Core Completeness + Genius Ideas
# (Sekcje 1/2/3-5/7 P02). Pakiety REPORT-owe — nie nadpisują decyzji
# (safe_merge: final_verdict_p01 ma priorytet). Aktywowane flagami
# input.jdg_entrepreneur.trust_check / conflict_check / completeness_check /
# p02_decision_core_check — w normalnym ruchu zwracają no_match.
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p02 = safe_merge(final_verdict_p01,
    safe_merge(adaptive_trust.decide,
    safe_merge(conflict_declaration.decide,
    safe_merge(decision_core_completeness.decide,
    safe_merge(p02_decision_core_innovations.decide,
        fallback.decide
    )))))

# final_verdict_p02 = kompletny werdykt P01 + P02 (najnowszy). Pakiety można
# też odpytować indywidualnie: data.jdg.adaptive_trust.decide,
# data.jdg.conflict_declaration.decide,
# data.jdg.decision_core_completeness.decide,
# data.jdg.p02_decision_core_innovations.decide.

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18d: P03 VAT MACRO ENTERPRISE v9.0 — Post-Provenance Merge
# Rates/Exemptions Audit + Deductions Audit + MPP/Split Payment + Fraud Detection
# + Genius Ideas (Sekcje 1/3/4/6/2-5-7-8 P03). Pakiety REPORT-owe — nie
# nadpisują decyzji (safe_merge: final_verdict_p02 ma priorytet). Aktywowane
# flagami input.jdg_entrepreneur.vat_rates_check / vat_deductions_check /
# vat_mpp_check / vat_fraud_check / p03_vat_macro_check — w normalnym ruchu
# zwracają no_match (matched:false).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p03 = safe_merge(final_verdict_p02,
    safe_merge(vat_rates_audit.decide,
    safe_merge(vat_deductions_audit.decide,
    safe_merge(vat_mpp_split_payment.decide,
    safe_merge(vat_fraud_detection.decide,
    safe_merge(p03_vat_macro_innovations.decide,
    safe_merge(p04_vat_macro_enterprise.decide,
    safe_merge(p05_vat_micro_atomic.decide,
    safe_merge(p06_pit_macro_enterprise.decide,
    safe_merge(p07_pit_micro_atomic.decide,
    safe_merge(p08_zus_macro_enterprise.decide,
        fallback.decide
    )))))))))))

# final_verdict_p03 = kompletny werdykt P01 + P02 + P03 (VAT Macro). Pakiety
# można też odpytować indywidualnie: data.jdg.vat_rates_audit.decide,
# data.jdg.vat_deductions_audit.decide, data.jdg.vat_mpp_split_payment.decide,
# data.jdg.vat_fraud_detection.decide, data.jdg.p03_vat_macro_innovations.decide.

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18e: P04 VAT MICRO ENTERPRISE v9.0 — Post-Provenance Merge
# Warstwa atomowa VAT: mapa pokrycia artykułów (COMPLETE/PARTIAL/MISSING),
# audyt duplikatów i martwych reguł, spójność micro↔macro, gwarancje
# matematyczne (grosze/zaokrąglenia/stawki), pakiety specjalistyczne,
# pipeline auto-generacji reguł z ISAP + genius ideas (14 innowacji).
# Pakiet REPORT-owy — nie nadpisuje decyzji (safe_merge: final_verdict_p03
# ma priorytet). Aktywowany flagami input.jdg_entrepreneur.p04_vat_micro_check
# / p04_micro_audit_check / p04_dedupe_check / p04_math_check /
# p04_specialist_check / p04_rate_desc_check — w normalnym ruchu no_match.
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p04 = safe_merge(final_verdict_p03,
    safe_merge(p04_vat_micro_innovations.decide,
        fallback.decide
    ))

# final_verdict_p04 = kompletny werdykt P01 + P02 + P03 + P04 (VAT Micro).
# Pakiet można też odpytować indywidualnie: data.jdg.p04_vat_micro_innovations.decide.

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18f: P05 PIT MACRO ENTERPRISE v9.0 — Post-Provenance Merge
# Formy opodatkowania + audyt ulg (PRIORYTET: B+R, IP Box, termo, prototyp,
# robotyzacja, ekspansja, PIT-0) + KUP/NKUP + zaliczki/zeznanie + Art. 21
# + thresholdy temporalne (ADR-002) + 15 genius ideas. Pakiet REPORT-owy —
# nie nadpisuje decyzji (safe_merge: final_verdict_p04 ma priorytet).
# Aktywowany flagami input.jdg_entrepreneur.p05_pit_macro_check /
# p05_relief_check / p05_form_check / p05_form_sim_check / p05_kup_check /
# p05_advance_check / p05_art21_check / p05_zaliczka_check /
# p05_spouse_check — w normalnym ruchu no_match (matched:false).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p05 = safe_merge(final_verdict_p04,
    safe_merge(p05_pit_macro_innovations.decide,
        fallback.decide
    ))

# final_verdict_p05 = kompletny werdykt P01 + P02 + P03 + P04 + P05 (PIT Macro).
# Pakiet można też odpytować indywidualnie: data.jdg.p05_pit_macro_innovations.decide.

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18g: P06 PIT MICRO + AMORTYZACJA ENTERPRISE v9.0 — Post-Provenance Merge
# Mapa pokrycia artykułów PIT micro + audyt amortyzacji (PRIORYTET: art. 22a-22n,
# KŚT, jednorazowa 100k EUR, samochody 150k/225k) + duplikaty/stuby + micro↔macro
# + audyt obliczeń + pipeline auto-generacji + 14 genius ideas. Pakiet REPORT-owy
# — nie nadpisuje decyzji (safe_merge: final_verdict_p05 ma priorytet).
# Aktywowany flagami input.jdg_entrepreneur.p06_pit_micro_check /
# p06_micro_audit_check / p06_amort_check / p06_math_check — w normalnym
# ruchu no_match (matched:false). Dane audytu: data.jdg.pit_micro_audit.
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p06 = safe_merge(final_verdict_p05,
    safe_merge(p06_pit_micro_innovations.decide,
        fallback.decide
    ))

# final_verdict_p06 = kompletny werdykt P01 + P02 + P03 + P04 + P05 + P06
# (PIT Micro + Amortyzacja). Pakiet można też odpytować indywidualnie:
# data.jdg.p06_pit_micro_innovations.decide.

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18h: P07 ZUS/SUS MACRO ENTERPRISE v9.0 — Post-Provenance Merge
# Audyt składki zdrowotnej (PRIORYTET: skala 9%, liniowy 4,9%, ryczałt 3 progi,
# karta 9%) + składki społeczne + zasiłki + PPK/PFRON/FS + zbiegi tytułów +
# thresholdy temporalne ZUS (ADR-002). Aktywowany flagami
# input.jdg_entrepreneur.p07_zus_macro_check — w normalnym ruchu no_match
# (matched:false). Dane audytu: data.jdg.thresholds.zus.
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p07 = safe_merge(final_verdict_p06,
    safe_merge(p07_zus_macro_innovations.decide,
        fallback.decide
    ))

# final_verdict_p07 = kompletny werdykt P01 + P02 + P03 + P04 + P05 + P06 + P07
# (ZUS/SUS Macro). Pakiet można też odpytować indywidualnie:
# data.jdg.p07_zus_macro_innovations.decide.

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18i: P08 ZUS/SUS MICRO ENTERPRISE v9.0 — Post-Provenance Merge
# Mapa pokrycia artykułów ZUS micro + audyt zdrowotnej mikro (PRIORYTET:
# progi ryczałtowe 60K/300K, korekta roczna) + zasiłki + duplikaty/stuby +
# spójność micro↔macro + pipeline temporalny (ADR-002). Aktywowany flagami
# input.jdg_entrepreneur.p08_zus_micro_check — w normalnym ruchu no_match
# (matched:false). Dane audytu: data.jdg.zus_micro_audit.
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p08 = safe_merge(final_verdict_p07,
    safe_merge(p08_zus_micro_innovations.decide,
        fallback.decide
    ))

# final_verdict_p08 = kompletny werdykt P01 + ... + P07 + P08 (ZUS/SUS Micro).
# Pakiet można też odpytować indywidualnie:
# data.jdg.p08_zus_micro_innovations.decide.

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18j: P09 KSIĘGOWOŚĆ PKPiR + UoR ENTERPRISE v9.0 — Post-Provenance Merge
# Audyt struktury PKPiR (kolumny 1-17) + audyt UoR (PRIORYTET: próg 2M EUR,
# silnik PKPiR-czy-UoR) + amortyzacja/leasing (KŚT, jednorazowa, auta) +
# remanent/korekty + transformacja PKPiR→UoR + pipeline temporalny (ADR-002).
# Aktywowany flagą input.jdg_entrepreneur.p09_ksiegowosc_check — w normalnym
# ruchu no_match (matched:false). Dane: data.jdg.thresholds.accounting.
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p09 = safe_merge(final_verdict_p08,
    safe_merge(p09_ksiegowosc_pkpir_uor_innovations.decide,
        fallback.decide
    ))

# final_verdict_p09 = kompletny werdykt P01 + ... + P08 + P09 (Księgowość PKPiR+UoR).
# Pakiet można też odpytować indywidualnie:
# data.jdg.p09_ksiegowosc_pkpir_uor_innovations.decide.

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18k: P10 KKS — KODEKS KARNY SKARBOWY ENTERPRISE v9.0 — Post-Provenance Merge
# Mapa pokrycia artykułów KKS + audyt gradacji kar (PRIORYTET: stawki dzienne,
# kalkulator kary, silnik minimalizacji 4-ścieżkowy) + czynny żal (art. 16) +
# przedawnienie/zatarcie (art. 44/45) + spójność micro↔macro + pipeline
# auto-aktualizacji sankcji (ADR-002). Aktywowany flagą
# input.jdg_entrepreneur.p10_kks_check — w normalnym ruchu no_match
# (matched:false). Dane audytu: data.jdg.kks_audit.
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p10 = safe_merge(final_verdict_p09,
    safe_merge(p10_kks_innovations.decide,
        fallback.decide
    ))

# final_verdict_p10 = kompletny werdykt P01 + ... + P09 + P10 (KKS).
# Pakiet można też odpytować indywidualnie:
# data.jdg.p10_kks_innovations.decide.

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18l: P11 ORDYNACJA PODATKOWA ENTERPRISE v9.0 — Post-Provenance Merge
# Mapa pokrycia artykułów OrdPU + audyt przedawnień (PRIORYTET: art. 70 —
# 5 lat, przerwanie, zawieszenie, kalendarz z alertami) + korekty/nadpłaty
# (art. 81/81b, 72-80) + auto-korespondencja + GAAR (art. 119a) + Biała Lista
# (art. 117ba) + pipeline (ADR-002). Aktywowany flagą
# input.jdg_entrepreneur.p11_ordynacja_check — w normalnym ruchu no_match
# (matched:false). Dane audytu: data.jdg.ordpu_audit.
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p11 = safe_merge(final_verdict_p10,
    safe_merge(p11_ordynacja_podatkowa_innovations.decide,
        fallback.decide
    ))

# final_verdict_p11 = kompletny werdykt P01 + ... + P10 + P11 (Ordynacja Podatkowa).
# Pakiet można też odpytować indywidualnie:
# data.jdg.p11_ordynacja_podatkowa_innovations.decide.

final_verdict_p12 = safe_merge(final_verdict_p11,
    safe_merge(p12_crossborder_innovations.decide,
        fallback.decide
    ))

# final_verdict_p12 = kompletny werdykt P01 + ... + P11 + P12 (Cross-Border/MDR/TP/CFC/FX).
# Pakiet można też odpytować indywidualnie:
# data.jdg.p12_crossborder_innovations.decide.

final_verdict_p13 = safe_merge(final_verdict_p12,
    safe_merge(p13_ryczalt_cykl_zycia_innovations.decide,
        fallback.decide
    ))

# final_verdict_p13 = kompletny werdykt P01 + ... + P12 + P13 (Ryczałt + Cykl Życia JDG).
# Pakiet można też odpytować indywidualnie:
# data.jdg.p13_ryczalt_cykl_zycia_innovations.decide.

final_verdict_p14 = safe_merge(final_verdict_p13,
    safe_merge(p14_pcc_lokalne_akcyza_innovations.decide,
        fallback.decide
    ))

# final_verdict_p14 = kompletny werdykt P01 + ... + P13 + P14 (PCC + Lokalne + Akcyza).
# Pakiet można też odpytować indywidualnie:
# data.jdg.p14_pcc_lokalne_akcyza_innovations.decide.

final_verdict_p15 = safe_merge(final_verdict_p14,
    safe_merge(p15_srodowisko_bdo_innovations.decide,
        fallback.decide
    ))

final_verdict_p16 = safe_merge(final_verdict_p15,
    safe_merge(p16_rodo_aml_security_innovations.decide,
        fallback.decide
    ))

final_verdict_p17 = safe_merge(final_verdict_p16,
    safe_merge(p17_ksef_jpk_edeklaracje_innovations.decide,
        fallback.decide
    ))

final_verdict_p18 = safe_merge(final_verdict_p17,
    safe_merge(p18_automatyzacja_ksiegowosci_innovations.decide,
        fallback.decide
    ))

final_verdict_p19 = safe_merge(final_verdict_p18,
    safe_merge(p19_hr_swiadczenia_innovations.decide,
        fallback.decide
    ))

final_verdict_p20 = safe_merge(final_verdict_p19,
    safe_merge(p20_neural_mesh_innovations.decide,
        fallback.decide
    ))

final_verdict_p21 = safe_merge(final_verdict_p20,
    safe_merge(p21_opa_system_innovations.decide,
        fallback.decide
    ))

final_verdict_p22 = safe_merge(final_verdict_p21,
    safe_merge(p22_validation_tools_innovations.decide,
        fallback.decide
    ))

final_verdict_p23 = safe_merge(final_verdict_p22,
    safe_merge(p23_test_rego_ci_innovations.decide,
        fallback.decide
    ))

final_verdict_p24 = safe_merge(final_verdict_p23,
    safe_merge(p24_audyt_kompletny_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18m: P03 GLM52 ORKIESTRATOR ENTERPRISE v9.0 — Post-Provenance Merge
# Orkiestrator + infrastruktura reguł: decyzyjny cache z Merkle-proof (INN-01),
# shadow twin (INN-02), dowód niezmienników SMT/Z3 (INN-03), mikro-benchmarki
# per PASS (INN-04), cold-start profiling (INN-05), WASM+fallback (INN-06),
# _degraded_context (INN-07), kill-switch + feature-flagi (INN-08), graf
# zależności (INN-09), certyfikat (INN-10), propagacja pewności (INN-11),
# Merkle-proof cache verify (INN-12), hot-path profiler (INN-13),
# rejestr cyklu życia (INN-14). Pakiet REPORT-owy — aktywowany flagą
# input.jdg_entrepreneur.p03_orchestrator_check (w normalnym ruchu no_match).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p25 = safe_merge(final_verdict_p24,
    safe_merge(p03_orchestrator_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18o: R01 GLM52 ORKIESTRATOR + RDZEŃ SILNIKA — Post-Provenance Merge
# Prompt 01/25 (RAPORT_01_ORKIESTRATOR_RDZEN.txt): deterministyczny routing z
# debugowaniem ścieżki, cache decyzji, time-travel guard, safe_merge integrity
# (INV-042), zderzenia priorytetów (INV-018), kompletność werdyktu 25-polowego.
# Pakiet REPORT-owy — aktywowany flagą input.jdg_entrepreneur.r01_orchestrator_core_check
# (w normalnym ruchu no_match). Nie nadpisuje decyzji (safe_merge — werdykt p25
# ma priorytet).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p26 = safe_merge(final_verdict_p25,
    safe_merge(r01_orchestrator_core_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18p: R02 GLM52 VAT CORE (MACRO) + ENTERPRISE — Post-Provenance Merge
# Prompt 02/25 (RAPORT_02_VAT_CORE.txt): real-time exemption limit tracker
# (art. 113 — 200 000 PLN, projekcja YTD), auto-GTU (Zał. nr 15 ustawy o VAT),
# korekta wieloletnia art. 91 (harmonogram 5/10 lat). Pakiet REPORT-owy —
# aktywowany flagą input.jdg_entrepreneur.r02_vat_core_check (w normalnym ruchu
# no_match). Nie nadpisuje decyzji (safe_merge — werdykt p26 ma priorytet).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p27 = safe_merge(final_verdict_p26,
    safe_merge(r02_vat_core_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18q: R03 GLM52 VAT WARSTWA MICRO — Post-Provenance Merge
# Prompt 03/25 (RAPORT_03_VAT_MICRO.txt): article coverage monitor, micro↔macro
# binding, micro↔macro consistency (INV-018). Pakiety REPORT-owe — aktywowane
# flagami input.jdg_entrepreneur.r03_vat_micro_check / vat_a28b_check / ...
# (w normalnym ruchu no_match). Nie nadpisują decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p28 = safe_merge(final_verdict_p27,
    safe_merge(r03_vat_micro_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18r: R04 GLM52 PIT CORE — Post-Provenance Merge
# Prompt 04/25 (RAPORT_04_PIT_CORE.txt): 3-drogowy symulator ulg (B+R vs IP Box
# vs robotyzacja), jednorazowa amortyzacja 100k (art. 22k ust. 7-12), niskocenne
# 10k (art. 22f ust. 3), kalkulator optymalnej składki zdrowotnej. Pakiet
# REPORT-owy — aktywowany flagą input.jdg_entrepreneur.r04_pit_core_check / ...
# (w normalnym ruchu no_match). Nie nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p29 = safe_merge(final_verdict_p28,
    safe_merge(r04_pit_core_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18s: R05 GLM52 PIT ENTERPRISE — Post-Provenance Merge
# Prompt 05/25 (RAPORT_05_PIT_ENTERPRISE.txt): autopilot roczny z Decision
# Certificate (F4), prognoza formy 3-letnia, scoring decyzji strategicznych,
# harmonizacja JPK_CIT/JPK_V7M. Pakiet REPORT-owy — aktywowany flagą
# input.jdg_entrepreneur.r05_pit_enterprise_check / ... (w normalnym ruchu
# no_match). Nie nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p30 = safe_merge(final_verdict_p29,
    safe_merge(r05_pit_enterprise_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18t: R06 GLM52 ZUS/SUS — Post-Provenance Merge
# Prompt 06/25 (RAPORT_06_ZUS.txt): 4-formowy kalkulator składki zdrowotnej,
# tracker ulg ZUS z alarmami terminów (art. 18a/18c), domknięcie art. 6a
# (pustynia zus_micro_inventory). Pakiet REPORT-owy — aktywowany flagą
# input.jdg_entrepreneur.r06_zus_check / ... (w normalnym ruchu no_match).
# Nie nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p31 = safe_merge(final_verdict_p30,
    safe_merge(r06_zus_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18u: R07 GLM52 KKS — Post-Provenance Merge
# Prompt 07/25 (RAPORT_07_KKS.txt): czynny żal one-click z pełną dokumentacją,
# kalkulator kar z temporalnością (art. 44 — 5 lat), predykcja ryzyka karnego
# per transakcja (art. 54/56/57/62). Pakiet REPORT-owy — aktywowany flagą
# input.jdg_entrepreneur.r07_kks_check / ... (w normalnym ruchu no_match).
# Nie nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p32 = safe_merge(final_verdict_p31,
    safe_merge(r07_kks_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18v: R08 GLM52 ORDYNACJA + OBRONA PODATNIKA — Post-Provenance Merge
# Prompt 08/25 (RAPORT_08_ORDYNACJA_OBRONA.txt): kalkulator odsetek z pełną
# temporalnością (harmonogram stóp per okres), asystent postępowania z 3
# poziomami alertów per termin, auto-generator korespondencji z US z podstawą
# prawną, predykcja wyroków WSA/NSA, monitor przedawnień z dowodem (art. 70).
# Pakiet REPORT-owy — aktywowany flagą input.jdg_entrepreneur.r08_ordynacja_check
# / ... (w normalnym ruchu no_match). Nie nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p33 = safe_merge(final_verdict_p32,
    safe_merge(r08_ordynacja_obrona_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18w: R09 GLM52 UoR / PKPiR / KSIĘGOWOŚĆ — Post-Provenance Merge
# Prompt 09/25 (RAPORT_09_UOR_KSIEGOWOSC.txt): symulator progu UoR (2M EUR +
# projekcja forward), uzgodnienie 3-drożne PKPiR↔VAT↔bank, optymalizator planu
# amortyzacji (liniowa/degresywna/jednorazowa), monitor terminów inwentaryzacji
# (3 poziomy alertów), auto-pakiet sprawozdania finansowego (fail-closed).
# Pakiet REPORT-owy — aktywowany flagą input.jdg_entrepreneur.r09_ksiegowosc_check
# / ... (w normalnym ruchu no_match). Nie nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p34 = safe_merge(final_verdict_p33,
    safe_merge(r09_ksiegowosc_pkpir_uor_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18x: R10 GLM52 CROSS-BORDER / TP / MDR-DAC6 / CFC — Post-Provenance Merge
# Prompt 10/25 (RAPORT_10_CROSSBORDER.txt): monitor terminu 30 dni dowodu WDT,
# scorer ryzyka MDR/DAC6 (hallmark A-E), symulator dokumentacji TP (500k/200M),
# przypisanie dochodu CFC, różnice kursowe z time-travel. Pakiet REPORT-owy —
# aktywowany flagą input.jdg_entrepreneur.r10_crossborder_check / ... (w
# normalnym ruchu no_match). Nie nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p35 = safe_merge(final_verdict_p34,
    safe_merge(r10_crossborder_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18y: R11 GLM52 PCC / PODATKI LOKALNE / AKCYZĄ — Post-Provenance Merge
# Prompt 11/25 (RAPORT_11_PCC_LOKALNE_AKCYZA.txt): monitor terminu 14 dni PCC-3,
# symulator podatku od nieruchomości, klasyfikator wyrobów akcyzowych, monitor
# DN-1 + raty, arbiter VAT vs PCC. Pakiet REPORT-owy — aktywowany flagą
# input.jdg_entrepreneur.r11_pcc_local_excise_check / ... (w normalnym ruchu
# no_match). Nie nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p36 = safe_merge(final_verdict_p35,
    safe_merge(r11_pcc_lokalne_akcyza_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18z2: R12 GLM52 RYCZAŁT / CEIDG / CYKL ŻYCIA (2026-08-15)
# Monitor limitu 2 mln EUR ryczałtu, klasyfikator PKWiU, planner faz cyklu
# życia JDG, monitor terminów sukcesji, arbiter formy opodatkowania. Pakiet
# REPORT-owy — aktywowany flagą input.jdg_entrepreneur.r12_ryczalt_cykl_zycia_
# check (w normalnym ruchu no_match). Nie nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p37 = safe_merge(final_verdict_p36,
    safe_merge(r12_ryczalt_cykl_zycia_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18ab: R13 GLM52 HYPER PLAN45 / KONTEKSTY SPECJALNE (2026-08-15)
# Detektor konfliktów międzydomenowych, danina solidarnościowa, monitor
# prokury, kalendarz terminów rocznych, selektor podpisu kwalifikowanego.
# Pakiet REPORT-owy — aktywowany flagą input.jdg_entrepreneur.r13_hyper_
# konteksty_check (w normalnym ruchu no_match). Nie nadpisuje decyzji
# (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p38 = safe_merge(final_verdict_p37,
    safe_merge(r13_hyper_konteksty_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18ad: R14 GLM52 RODO / AML-CBDD / BDO / ŚRODOWISKO (2026-08-15)
# Rejestr czynności RODO, scoring transakcji AML, kalkulator sankcji RODO,
# monitor STR do GIIF, monitor obowiązków BDO. Pakiet REPORT-owy — aktywowany
# flagą input.jdg_entrepreneur.r14_rodo_aml_bdo_check (w normalnym ruchu
# no_match). Nie nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p39 = safe_merge(final_verdict_p38,
    safe_merge(r14_rodo_aml_bdo_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18af: R15 GLM52 KSeF / JPK / e-DEKLARACJE / GTU / WIS (2026-08-15)
# Firewall KSeF, korelator JPK, klasyfikator GTU, monitor trybu awaryjnego,
# monitor WIS. Pakiet REPORT-owy — aktywowany flagą input.jdg_entrepreneur.
# r15_ksef_jpk_check (w normalnym ruchu no_match). Nie nadpisuje decyzji
# (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p40 = safe_merge(final_verdict_p39,
    safe_merge(r15_ksef_jpk_edeklaracje_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18ah: R16 GLM52 SYSTEM OPA / P18-P35 (2026-08-15)
# Monitor cyklu życia reguły, jakości walidacji, tarczy CI, niezawodności,
# pipeline ISAP→produkcja. Pakiet REPORT-owy — aktywowany flagą input.
# jdg_entrepreneur.r16_system_opa_check (w normalnym ruchu no_match). Nie
# nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p41 = safe_merge(final_verdict_p40,
    safe_merge(r16_system_opa_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18ah: R17 GLM52 ENTERPRISE AI (2026-08-15)
# Adaptive Trust, Neural Mesh, Cashflow, Bankowość PSD2, Monitor legislacyjny.
# Pakiet REPORT-owy — aktywowany flagą input.
# jdg_entrepreneur.r17_enterprise_ai_check (w normalnym ruchu no_match). Nie
# nadpisuje decyzji (safe_merge).
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p42 = safe_merge(final_verdict_p41,
    safe_merge(r17_enterprise_ai_innovations.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18ag: P03 GLM52 VAT MIKRO + JPK — WARSTWA MIKRO (Dual-Layer, ADR-005)
# Wpięcie warstwy mikro do orkiestratora (P03): jdg.micro.vat (vat.rego,
# ~1100 reguł atomowych art. 5-172) + jdg.micro.jpk (jpk.rego, ~160 reguł).
# ZASADA: mikro wypełnia LUKI makro (no_match → werdykt atomowy), ale NIGDY
# nie nadpisuje decyzji makro (safe_merge: final_verdict_p42 ma priorytet,
# INV-018). Pakiet jdg.micro.jpk.plan33 (plan33_jpk.rego) wydzielony w P03
# (konflikt multiple default rules — blokował kompilację warstwy mikro).
# Aktywacja: w normalnym ruchu mikro działa automatycznie tylko dla transakcji
# nieobsłużonych przez makro; szczegółowe reguły r4+ aktywowane flagami
# input.jdg_entrepreneur.vat_aXX_rYY_checks.
# ═══════════════════════════════════════════════════════════════════════════════
final_verdict_p43 = safe_merge(final_verdict_p42,
    safe_merge(micro_vat_full.decide,
    safe_merge(micro_jpk_full.decide,
    safe_merge(micro_jpk_plan33.decide,
        fallback.decide
    ))))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 44: MIKRO PIT (PROMPT 05 — PIT MAKRO) — Dual-Layer (ADR-005, INV-018)
# Warstwa mikro PIT (pit.rego ~22,7k linii + plan33 + plan34): wypełnia luki
# makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge: lewy arg.
# wygrywa). Konflikt kompilacji (3× default decide) naprawiony P05: plan33 →
# jdg.micro.pit.plan33, plan34 → jdg.micro.pit.plan34.
final_verdict_p44 = safe_merge(final_verdict_p43,
    safe_merge(micro_pit_full.decide,
    safe_merge(micro_pit_plan33.decide,
    safe_merge(micro_pit_plan34.decide,
        fallback.decide
    ))))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 45: AMORTYZACJA MIKRO (PROMPT 06 — PIT MIKRO + AMORTYZACJA + NKUP)
# Warstwa mikro amortyzacji (art. 22a-22h/22i/22k/22n): a22a (definicja ŚT),
# a22b (WNiP), a22c (wyłączenia), a22h (zasady odpisów + invariant F2),
# a22i (metody: liniowa/degresywna), a22k (jednorazowa de minimis + limity),
# a22n (ewidencja ŚT). Konwencja mikro (INV-018): bez catch-all {true} — brak
# dopasowania → default no_match; wypełniają LUKI makro, nigdy nie nadpisują
# (safe_merge: lewy arg. wygrywa). Naprawione P06: usunięte fallbacki {true}
# (przejmowały no_match), poprawione _legal_basis (degresywna = art. 22k).
final_verdict_p45 = safe_merge(final_verdict_p44,
    safe_merge(amort_a22a.decide,
    safe_merge(amort_a22b.decide,
    safe_merge(amort_a22c.decide,
    safe_merge(amort_a22h.decide,
    safe_merge(amort_a22i.decide,
    safe_merge(amort_a22k.decide,
    safe_merge(amort_a22n.decide,
        fallback.decide
    ))))))))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 46: ZUS MIKRO + ZASIŁKI (PROMPT 09 — GLM52 P09, Dual-Layer ADR-005/INV-018)
# Warstwa mikro ZUS (sus.rego 122 reguł + zdrowotna.rego 136 + zasilkowa.rego 38
# + plan33_zus.rego 180 + zus_micro_atomic_p09 16 reguł atomowych): wypełnia
# LUKI makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge: lewy
# argument wygrywa). Niemutowalność werdyktów makro ZUS (allowlist jdg.zus.*)
# chroniona — mikro operuje na własnym namespace jdg.micro.*.
final_verdict_p46 = safe_merge(final_verdict_p45,
    safe_merge(micro_sus_full.decide,
    safe_merge(micro_zdrowotna_full.decide,
    safe_merge(micro_zasilkowa_full.decide,
    safe_merge(micro_zus_plan33.decide,
    safe_merge(zus_micro_atomic_p09.decide,
        fallback.decide
    ))))))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 47: KSIĘGOWOŚĆ MIKRO (PROMPT 10 — GLM52 P10, Dual-Layer ADR-005/INV-018)
# Warstwa mikro księgowości (PKPiR 7 pakietów: pkpir/columns/corrections/costs/
# nkup/revenue/remnant + micro/uor 148 reguł + plan33_uor + ksiegowosc_atomic_p10
# 16 reguł atomowych: próg 2M EUR, podwójny zapis, inwentaryzacja, sprawozdanie,
# zamknięcie roku, amortyzacja księgowa, walidator 17 kolumn, leasing): wypełnia
# LUKI makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge: lewy
# argument wygrywa).
final_verdict_p47 = safe_merge(final_verdict_p46,
    safe_merge(micro_pkpir.decide,
    safe_merge(micro_pkpir_columns.decide,
    safe_merge(micro_pkpir_corrections.decide,
    safe_merge(micro_pkpir_costs.decide,
    safe_merge(micro_pkpir_nkup.decide,
    safe_merge(micro_pkpir_revenue.decide,
    safe_merge(micro_pkpir_remnant.decide,
    safe_merge(micro_uor.decide,
    safe_merge(micro_uor_plan33.decide,
    safe_merge(ksiegowosc_atomic_p10.decide,
        fallback.decide
    )))))))))))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 48: KKS + ORDYNACJA + AUDYT/OBRONA MIKRO (PROMPT 11 — GLM52 P11)
# Reguły atomowe P11 (13): gradacja kar KKS (art. 54 — stawka dzienna × stawek,
# przestępstwo/wykroczenie), czynny żal (art. 16), dobrowolne poddanie (art. 17),
# recydywa (art. 37), przedawnienie karalności (art. 44), przedawnienie
# zobowiązania (art. 70 OP), korekta (art. 81b), Biała Lista (art. 117ba),
# GAAR (art. 119a), prawa w kontroli (art. 282b/291/223 + WSA), JPK na żądanie
# (art. 193a). Wypełnia LUKI makro (no_match), nigdy nie nadpisuje (safe_merge).
final_verdict_p48 = safe_merge(final_verdict_p47,
    safe_merge(micro_kks_full.decide,
    safe_merge(micro_ord_full.decide,
    safe_merge(micro_kks_plan33.decide,
    safe_merge(micro_ord_plan33.decide,
    safe_merge(micro_ord_plan34.decide,
    safe_merge(kks_ord_atomic_p11.decide,
        fallback.decide
    )))))))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 49: CROSS-BORDER / TP / CFC / MDR MIKRO (PROMPT 12 — GLM52 P12)
# Warstwa mikro cross-border (micro/crossborder 193 + plan33_cb/tp/tax_trans/mdr
# + crossborder_atomic_p12 10 reguł: TP 23m/23zf/23zb, CFC 30f, exit tax 30da,
# MDR 86a-86o, WHT 30a, rezydencja 3, FX 14 ust. 2c): wypełnia LUKI makro
# (no_match), nigdy nie nadpisuje decyzji makro (safe_merge: lewy argument wygrywa).
final_verdict_p49 = safe_merge(final_verdict_p48,
    safe_merge(micro_cb_full.decide,
    safe_merge(micro_cb_plan33.decide,
    safe_merge(micro_tp_plan33.decide,
    safe_merge(micro_tax_trans_plan33.decide,
    safe_merge(micro_mdr_plan33.decide,
    safe_merge(crossborder_atomic_p12.decide,
        fallback.decide
    )))))))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18al: P13 GLM52 RYCZAŁT / CEIDG / PP / SUKCESJA MIKRO (PROMPT 13 — GLM52 P13)
# Warstwa micro cyklu życia (micro/ryczalt 156 + plan33_ryc 159 + ceidg 43 +
# plan33_ceidg 16 + pp 148 + sukcesja 141 + plan33_succ 21 + ryczalt_cykl_atomic_p13
# 18 reguł: stawki PKWiU 3-25%, limit 2M EUR z alertem 95%, zawieszenie 30 dni/
# 24 mies., nieewidencjonowana 50% minimalnej, sukcesja 2+3 lata, karta podatkowa):
# wypełnia LUKI makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge:
# lewy argument wygrywa). IN_SUCCESSIO → routing full chain (kontrakt PROMPT 01).
final_verdict_p50 = safe_merge(final_verdict_p49,
    safe_merge(micro_ryczalt_full.decide,
    safe_merge(micro_ryc_plan33.decide,
    safe_merge(micro_ceidg_full.decide,
    safe_merge(micro_ceidg_plan33.decide,
    safe_merge(micro_pp_full.decide,
    safe_merge(micro_sukcesja_full.decide,
    safe_merge(micro_succ_plan33.decide,
    safe_merge(ryczalt_cykl_atomic_p13.decide,
        fallback.decide
    )))))))))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 51: PCC / PODATKI LOKALNE / AKCYZA / PODATEK ROLNY MIKRO (PROMPT 14 — GLM52 P14)
# Warstwa micro PCC + lokalne + akcyza (micro/pcc 90 + plan33_pcc 60 + akcyza
# 133 + prop 31 + prop_transport 6 + agricultural_tax 6 + pcc_lokalne_atomic_p14
# 19 reguł atomowych: stawki PCC 0,5-2% + wyłączenie VAT + zwolnienie ≤1000 zł +
# PCC-3 14 dni, nieruchomości 33,10/1,43 + DN-1, transport >3,5 t, akcyza paliwa/
# alkohol/energia + skład podatkowy, podatek rolny): wypełnia LUKI makro
# (no_match), nigdy nie nadpisuje decyzji makro (safe_merge: lewy argument wygrywa).
final_verdict_p51 = safe_merge(final_verdict_p50,
    safe_merge(micro_pcc_full.decide,
    safe_merge(micro_pcc_plan33.decide,
    safe_merge(micro_akcyza_full.decide,
    safe_merge(micro_prop_plan33.decide,
    safe_merge(micro_prop_transport_plan33.decide,
    safe_merge(micro_agricultural_plan33.decide,
    safe_merge(pcc_lokalne_atomic_p14.decide,
        fallback.decide
    ))))))))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 52: RODO / AML-CBDD / BDO-ŚRODOWISKO / BUDOWNICTWO / TRANSPORT MIKRO (PROMPT 15 — GLM52 P15)
# Warstwa micro compliance (rodo 6 + plan33_rodo + aml 5 + bdo 6 + srodowisko 48
# + plan33_est 15 + budownictwo 64 + transport 44 + rodo_aml_bdo_atomic_p15 17
# reguł atomowych: rejestr art. 30, erasure art. 17, DPA art. 28, naruszenia 72 h
# art. 33, DPIA art. 35, sankcje art. 83 (20 mln EUR), CBDD art. 28a-34 + transakcje
# > 15 000 EUR + beneficjent + STR 48 h art. 74-80, BDO rejestracja/ewidencja/EWC/
# transport + kara art. 194 (5000 zł), pozwolenie art. 28 Pb, licencja transportowa):
# wypełnia LUKI makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge:
# lewy argument wygrywa).
final_verdict_p52 = safe_merge(final_verdict_p51,
    safe_merge(micro_rodo_full.decide,
    safe_merge(micro_rodo_plan33.decide,
    safe_merge(micro_aml_full.decide,
    safe_merge(micro_bdo_rejestracja.decide,
    safe_merge(micro_bdo_ewidencja.decide,
    safe_merge(micro_bdo_ewc.decide,
    safe_merge(micro_bdo_transport.decide,
    safe_merge(micro_bdo_zezwolenia.decide,
    safe_merge(micro_bdo_weee.decide,
    safe_merge(micro_srodowisko_full.decide,
    safe_merge(micro_est_plan33.decide,
    safe_merge(micro_budownictwo_full.decide,
    safe_merge(micro_transport_full.decide,
    safe_merge(rodo_aml_bdo_atomic_p15.decide,
        fallback.decide
    )))))))))))))))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 53: HYPER PLAN45 / KONTEKSTY / KALENDARZ / LIMITY / SANKCJE (PROMPT 16 — GLM52 P16)
# Warstwa hyper-kontekstowa: 14 pakietów jdg.hyper.* (general, deadlines, limits,
# sanctions, audit, family, force_majeure, fx, edelivery, procurement, solidarity,
# wis, mdr, misc) + deadline_monitor (kalendarz płatności/terminów). Wypełnia LUKI
# makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge: lewy wygrywa).
final_verdict_p53 = safe_merge(final_verdict_p52,
    safe_merge(hyper_general.decide,
    safe_merge(hyper_deadlines.decide,
    safe_merge(hyper_limits.decide,
    safe_merge(hyper_sanctions.decide,
    safe_merge(hyper_audit.decide,
    safe_merge(hyper_family.decide,
    safe_merge(hyper_force_majeure.decide,
    safe_merge(hyper_fx.decide,
    safe_merge(hyper_edelivery.decide,
    safe_merge(hyper_procurement.decide,
    safe_merge(hyper_solidarity.decide,
    safe_merge(hyper_wis.decide,
    safe_merge(hyper_mdr.decide,
    safe_merge(hyper_misc.decide,
    safe_merge(deadline_monitor.decide,
        fallback.decide
    ))))))))))))))))

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 10: PIT Macro completeness package (report-only, SUGGEST/fail-closed).
final_verdict_p54 = safe_merge(final_verdict_p53,
    safe_merge(pit_macro_etap10.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 11: PIT Micro Reliefs evidence and qualification package.
final_verdict_p55 = safe_merge(final_verdict_p54,
    safe_merge(pit_micro_reliefs_etap11.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 12: ZUS Core — składki, zdrowotna, ulgi, świadczenia i terminy.
final_verdict_p56 = safe_merge(final_verdict_p55,
    safe_merge(zus_core_etap12.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 13: ZUS Micro — mapa atomów, okresy, świadczenia, property invariants.
final_verdict_p57 = safe_merge(final_verdict_p56,
    safe_merge(zus_micro_etap13.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 14: PKPiR — dowody, kolumny, uzgodnienie 3-stronne i idempotencja.
final_verdict_p58 = safe_merge(final_verdict_p57,
    safe_merge(pkpir_etap14.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 15: UoR — podwójny zapis, aktywa, amortyzacja, zamknięcie, sprawozdania.
final_verdict_p59 = safe_merge(final_verdict_p58,
    safe_merge(uor_etap15.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# ETAP 16: KKS + Ordynacja — risk scoring, evidence chain, deadline engine.
final_verdict_p60 = safe_merge(final_verdict_p59,
    safe_merge(kks_ord_etap16.decide,
        fallback.decide
    ))

# ETAP 17: Cross-border evidence-first safety layer. It is SUGGEST-only and
# fail-closed; the package is inactive unless the explicit stage flag is set.
final_verdict_p61 = safe_merge(final_verdict_p60,
    safe_merge(crossborder_etap17.decide,
        fallback.decide
    ))

# ETAP 18: formalny state machine cyklu życia JDG; SUGGEST-only i fail-closed.
final_verdict_p62 = safe_merge(final_verdict_p61,
    safe_merge(business_lifecycle_etap18.decide,
        fallback.decide
    ))

# ETAP 19: PCC/local/excise evidence-first safety layer; SUGGEST-only and fail-closed.
final_verdict_p63 = safe_merge(final_verdict_p62,
    safe_merge(local_excise_etap19.decide,
        fallback.decide
    ))

# ETAP 20: KSeF/JPK/e-Deklaracje evidence-first safety layer; SUGGEST-only,
# no_auto_post i fail-closed przy braku MF/XSD/UPO/evidence.
final_verdict_p64 = safe_merge(final_verdict_p63,
    safe_merge(ksef_jpk_etap20.decide,
        fallback.decide
    ))

# ETAP 21: RODO/AML/BDO/HR evidence-first safety layer; guidance-only,
# SUGGEST/no_auto_post i fail-closed przy braku dowodów lub owner approval.
final_verdict_p65 = safe_merge(final_verdict_p64,
    safe_merge(rodo_aml_bdo_hr_etap21.decide,
        fallback.decide
    ))

# ETAP 22: Hyper Plan45 meta-validator; SUGGEST/no_auto_post i fail-closed.
final_verdict_p66 = safe_merge(final_verdict_p65,
    safe_merge(hyper_enterprise_contexts_etap22.decide,
        fallback.decide
    ))

# ETAP 23: Enterprise AI / Neural Mesh governance; advisory-only,
# deterministic legal authority, calibration/drift/safety gates and manual review.
final_verdict_p67 = safe_merge(final_verdict_p66,
    safe_merge(enterprise_ai_neural_etap23.decide,
        fallback.decide
    ))

# ETAP 24: Tests / CI / quality release gate; fail-closed and reproducible.
final_verdict_p68 = safe_merge(final_verdict_p67,
    safe_merge(tests_ci_quality_etap24.decide,
        fallback.decide
    ))

# ETAP 25: Tools / API / RuleStore / bundles control-data plane governance;
# JWT/RBAC/SoD, idempotency, versioning, migrations+constraints, bundle signing/
# SBOM/node-verify/persist-healthy, progressive delivery, hot-reload, WORM/Merkle
# audit and DR. Fail-closed; mock is never certified as production.
final_verdict_p69 = safe_merge(final_verdict_p68,
    safe_merge(tools_api_rulestore_bundles_etap25.decide,
        fallback.decide
    ))

# ETAP 26: Policies `policies/` mirror/overlay sync governance;
# source of truth = JDG/rules/; mirror cannot silently change JDG decisions;
# drift 0%, hash/decision/legal parity 100%, overlays TCL 100%, zero ghosts,
# experimental variants clearly marked. Fail-closed.
final_verdict_p70 = safe_merge(final_verdict_p69,
    safe_merge(policies_mirror_sync_etap26.decide,
        fallback.decide
    ))

# ETAP 27: Cross-domain red team governance — conflict registry,
# attack catalog, chaos matrix, temporal edge contracts, fraud scenarios,
# fail-closed proof and AUTO_POST guard.
final_verdict_p71 = safe_merge(final_verdict_p70,
    safe_merge(cross_domain_red_team_etap27.decide,
        fallback.decide
    ))

# ETAP 28: Final certification — reconciliation of all 27 stages,
# act→legal node→rule→test→bundle→verdict→operator matrix, domain
# certification (CERTIFIED/CONDITIONAL/BLOCKED), production blockers,
# SLO/SLA, change control and brutal honesty report.
final_verdict_p72 = safe_merge(final_verdict_p71,
    safe_merge(final_certification_etap28.decide,
        fallback.decide
    ))

# ETAP 29 / V3-13: whole micro-layer quality, normalized boundary, and explicit
# micro-to-macro binding. This is decoupled and cannot authorize AUTO_POST.
final_verdict_p73 = safe_merge(final_verdict_p72,
    safe_merge(micro_quality_v3_13.decide,
        fallback.decide
    ))

# V3-14: Hyper Contexts Plan44/45 quality boundary. The package is decoupled,
# evidence-first and guidance-only; it cannot authorize AUTO_POST.
final_verdict_p74 = safe_merge(final_verdict_p73,
    safe_merge(hyper_quality_v3_14.decide,
        fallback.decide
    ))

# V3-15: S1-S24, Neural Mesh and scoring quality boundary. This is
# calibrated, evidence-first, decoupled and cannot authorize AUTO_POST.
final_verdict_p75 = safe_merge(final_verdict_p74,
    safe_merge(enterprise_quality_v3_15.decide,
        fallback.decide
    ))

# ═══════════════════════════════════════════════════════════════════════════════
# PAS 18n: POST-MERGE RUNTIME INVARIANTS + DECISION CERTIFICATE (ADR-022, F2/F4)
# Na KOŃCU POST-MERGE egzekucja niezmienników (F2 V2): wstrzykuje
#   • _invariant_report  — wynik evaluate() (invariant_failed, failed, levels),
#   • _certainty_class     — CERTAIN / CONDITIONAL / NEEDS_ADVICE (F4 V2 §5.2),
#   • _certainty_guard    — CERTAINTY_BLOCKED / MANUAL_REVIEW / AUTO_POST_ALLOWED,
#   • _decision_certificate — certyfikat F4 z decision_hash (F3 V2) i wersjami
#                             bundle/rule/threshold (V1 §9.3),
#   • _routing_context    — kontekst routingu O(1) (INV-020/INV-036, ADR-009).
# Host NIGDY nie wykonuje AUTO_POST dla werdyktu z _certainty_guard =
# CERTAINTY_BLOCKED (INV-006/INV-035) — gwarancja „nigdy zła decyzja".
# ═══════════════════════════════════════════════════════════════════════════════
# Kontekst routingu musi być dołączony PRZED enforce(): INV-020/036 badają
# rzeczywisty werdykt końcowy, a nie wersję pozbawioną metadanych routingu.
# Compatibility anchors remain available as final_verdict_p53..p75, but the
# effective POST-MERGE input is p75. This preserves every stage p54..p74 and
# removes the former hand-written object.union chain that could silently skip
# stages or overwrite immutable fields (INV-018/INV-042).
# Legacy audit anchors (documentation only; deliberately not executable):
# final_verdict_post_merge = object.union(final_verdict_p53,
# object.union(final_verdict_p61, object.union(final_verdict_p62,
# object.union(final_verdict_p63, object.union(final_verdict_p64,
# object.union(final_verdict_p65, object.union(final_verdict_p66,
# object.union(final_verdict_p67, object.union(final_verdict_p68,
# object.union(final_verdict_p69, object.union(final_verdict_p70,
# object.union(final_verdict_p71, object.union(final_verdict_p72,
# final_verdict_enforced = object.union(final_verdict_post_merge,
# Put the routing context on the left so safe_merge always retains it, including
# when p72 is an immutable verdict. The final verdict remains the right-side
# authority for business fields.
final_verdict_post_merge = safe_merge(
    {"_routing_context": routing_context},
    final_verdict_p75
)

# Enforcement is a second safe merge: invariant/certificate fields are attached
# without allowing a later advisory package to replace the business decision.
final_verdict_enforcement = runtime_invariants.enforce(final_verdict_post_merge)
final_verdict_enforced = safe_merge(final_verdict_enforcement,
    final_verdict_post_merge)

# Publiczny kontrakt OPA/API: każde odwołanie do data.jdg.main.final_verdict
# musi zwracać wynik po POST-MERGE invariants i certyfikacie, nigdy surowy
# selected_final_verdict.
final_verdict = final_verdict_enforced

# final_verdict_p20 = kompletny werdykt P01 + ... + P19 + P20 (Neural Mesh + Innowacje v8).
# final_verdict_p19 = kompletny werdykt P01 + ... + P18 + P19 (HR i Świadczenia).
# final_verdict_p18 = kompletny werdykt P01 + ... + P17 + P18 (Automatyzacja Księgowości).
# final_verdict_p17 = kompletny werdykt P01 + ... + P16 + P17 (KSeF + JPK + e-Deklaracje).
# final_verdict_p16 = kompletny werdykt P01 + ... + P15 + P16 (RODO + AML + Compliance + Bezpieczeństwo + Audyt).
# Pakiet można też odpytować indywidualnie:
# data.jdg.p16_rodo_aml_security_innovations.decide.