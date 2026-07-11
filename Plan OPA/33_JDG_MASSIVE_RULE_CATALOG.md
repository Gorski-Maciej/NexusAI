# 🏛️ NexusAI JDG — Masowy Katalog Reguł OPA/Rego ENTERPRISE v10.0

> **Status:** KOMPLETNY KATALOG REGUŁ — 3 000+ reguł z pełną dekompozycją prawną
> **Data:** 2026-07-10
> **Autor:** Zespół NexusAI
> **Plik:** `Plan OPA/33_JDG_MASSIVE_RULE_CATALOG.md`

**Cel dokumentu:** Niniejszy dokument jest KOMPLETNYM katalogiem wszystkich reguł OPA/Rego dla JDG. Każdy artykuł prawny z DocsJDG (~230 artykułów, ~1 150 punktów prawnych) jest rozłożony na **8-15 mikro-reguł**, tworząc gęstą siatkę bezpieczeństwa o współczynniku **~13 reguł na artykuł**. Łącznie **~3 055 reguł** w 11 częściach prawnych.

**Dokumenty źródłowe:**
— `Plan OPA/DocsJDG` — źródła prawne JDG (~230 artykułów, ~1 150 punktów prawnych)
— `Plan OPA/22-31_JDG_*.md` — istniejące plany JDG (1 462 → 3 000+ reguł)
— `Plan OPA/32_JDG_ENTERPRISE_DEFINITIVE_PLAN.md` — plan architektoniczny (50 pakietów, hierarchia, input)
— `policies/tax/*.rego` — istniejące implementacje Rego (22 pliki)

**Różnica vs dokument 32:** Dokument 32 zawiera plan architektoniczny z ~392 regułami w łańcuchu first-match-wins. Niniejszy dokument zawiera **PEŁNY KATALOG** wszystkich ~3 055 mikro-reguł z pełnymi opisami: nazwa, warunek, rezultat, podstawa prawna, zależności.

---

## 0. Metodologia Dekompozycji

### 0.1 Współczynniki dekompozycji

Każdy artykuł prawny jest dekomponowany na mikro-reguły wg schematu:

| Typ warunku | Liczba mikro-reguł | Przykład |
|-------------|:------------------:|----------|
| **Główna reguła** (czy artykuł ma zastosowanie) | 1 | "Czy to WNT?" |
| **Warunki pozytywne** (kiedy TAK) | 2-4 | "WNT tylko gdy nabywca ma VAT-UE" |
| **Warunki negatywne** (kiedy NIE) | 2-4 | "WNT NIE dotyczy usług" |
| **Wyjątki** (kiedy mimo warunków NIE) | 1-3 | "WNT nie dotyczy nowych środków transportu" |
| **Interakcje** (zależności od innych artykułów) | 1-2 | "WNT + stawka VAT krajowa" |
| **Terminy i procedury** (kiedy, jak, dokumenty) | 2-3 | "WNT termin 25. dnia" |
| **Sankcje** (konsekwencje naruszenia) | 1-2 | "Brak deklaracji WNT → kara KKS" |
| **Edge cases** (nietypowe sytuacje) | 1-2 | "WNT przy transakcji łańcuchowej" |

### 0.2 Cel liczbowy

| Ustawa | Artykułów | Cel: reguł | Współczynnik |
|--------|:---------:|:----------:|:------------:|
| Ustawa o VAT | 60 | ~780 | 13.0× |
| Ustawa o PIT | 40 | ~520 | 13.0× |
| Ordynacja podatkowa | 30 | ~390 | 13.0× |
| Ustawa o SUS (ZUS) | 15 | ~195 | 13.0× |
| Ustawa o ryczałcie | 17 | ~220 | 12.9× |
| Ustawa zdrowotna | 5 | ~65 | 13.0× |
| KKS | 5 | ~65 | 13.0× |
| PCC + podatki lokalne | 15 | ~195 | 13.0× |
| UoR + CEIDG + sukcesja | 25 | ~225 | 9.0× |
| KSeF + JPK | 20 | ~200 | 10.0× |
| Cross-border + TP + inne | 20 | ~200 | 10.0× |
| **RAZEM** | **~252** | **~3 055** | **~12.1×** |

### 0.3 Konwencja ID reguł

```
<jdg>.<ustawa>.<artykuł>.<pozycja>
```

Przykłady:
- `jdg.vat.a17.r1.c1` — VAT Art. 17 ust. 1, warunek 1 (reverse charge)
- `jdg.pit.a22.p5.c2` — PIT Art. 22 ust. 5, warunek 2 (koszty bezpośrednie)
- `jdg.ord.a70.p1.c1` — Ordynacja Art. 70 § 1, warunek 1 (przedawnienie)

### 0.4 Struktura opisu każdej reguły

Każda reguła w tym katalogu zawiera:
- **ID** — unikalny identyfikator (np. `jdg.vat.a5.r1`)
- **Nazwa** — angielska nazwa reguły (zgodnie z konwencją Rego)
- **Warunek** — logiczne warunki dopasowania
- **Rezultat** — co reguła zwraca (allow/deny, wartość, decyzja)
- **Podstawa prawna** — konkretny artykuł, ustawa
- **Zależności** — które reguły muszą być sprawdzone przed/po

---


---

## 12. Nowe Reguły ENTERPRISE z Dokumentu 32 (56 reguł)

> Poniższe reguły zostały dodane w dokumencie 32 jako nowe obszary. Są one opisane szczegółowo w sekcji 5 dokumentu 32. Tutaj wymienione są ich identyfikatory dla kompletności katalogu.

### 12.1 Kryptoaktywa (P630-P635)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P630 | crypto_income_classification | Kategoria CRYPTO_SALE/EXCHANGE/SWAP | pit_form: CAPITAL_GAINS, pit_rate: 0.19, PIT-38 | Art. 30b ust. 1 pkt 1 PIT |
| P631 | crypto_staking_income | Kategoria CRYPTO_STAKING_REWARD | income_type: STAKING_REWARD, pit_rate: 0.19, PIT-38 | Art. 30b ust. 1 pkt 1 PIT |
| P632 | crypto_loss_offset_rules | has_crypto_loss_carry_forward AND CRYPTO_SALE | loss_offset_limit: CRYPTO_ONLY, max 50%, carry 5 lat | Art. 9 ust. 3, Art. 30b ust. 3 PIT |
| P633 | crypto_nft_taxation | Kategoria NFT_SALE AND is_nft_creator | BUSINESS_REVENUE lub CAPITAL_GAINS | Art. 14 PIT lub Art. 30b PIT |
| P634 | crypto_defi_income | Kategoria DEFI_YIELD/LENDING/LIQUIDITY | income_type: DEFI_REVENUE, pit_rate: 0.19 | Art. 30b ust. 1 pkt 1 PIT |
| P635 | crypto_foreign_exchange_reporting | has_foreign_crypto_accounts AND balance > 200k PLN | uz3_reporting_required: true | Art. 30b ust. 12 PIT |

### 12.2 CESOP (P155-P157)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P155 | cesop_cross_border_payment_reporting | SALE AND vendor.country in EU AND annual_cross_border_eur > 25000 | cesop_reportable: true | Rozporządzenie 2020/284 (CESOP) |
| P156 | cesop_payment_method_classification | SALE AND vendor.country in EU AND payment_method != "" | cesop_payment_type: CARD/SEPA/TARGET2/BLIK/CRYPTO | Rozporządzenie 2020/284 art. 3 |
| P157 | cesop_quarterly_aggregation_check | vendor.country in EU AND kwartalna suma > 25000 EUR | cesop_quarterly_threshold_exceeded: true | Rozporządzenie 2020/284 |

### 12.3 ViDA (P160-P162)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P160 | vida_digital_vat_real_time_reporting | transaction_date >= vida_date AND is_vat_payer | vida_real_time_reporting: true | Propozycja KE COM(2022)360 — ViDA Pillar 1 |
| P161 | vida_single_vat_registration | SALE AND vendor.country in EU AND is_b2b AND vida_active | single_vat_registration: true | Propozycja KE COM(2022)360 — ViDA Pillar 2 |
| P162 | vida_digital_vat_einvoicing_expansion | SALE AND vendor.country in EU AND vida_einvoicing_active | eu_einvoicing_required: true, format: EN_16931 | Propozycja KE COM(2022)360 — ViDA Pillar 3 |

### 12.4 UK Post-Brexit (P170-P172)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P170 | uk_post_brexit_goods_import | procedure: IMPORT AND vendor.country: GB | procedure: IMPORT_NON_EU, customs_duty_possible: true | Art. 17 ust. 1 pkt 1 VAT, ustawa o ceł |
| P171 | uk_post_brexit_services_export_b2b | SALE AND vendor.country: GB AND is_b2b AND type: SERVICE | vat_rate: 0.00 (NP), reverse_charge: true | Art. 28b VAT |
| P172 | uk_post_brexit_vat_registration_threshold | SALE AND vendor.country: GB AND is_b2c AND uk_b2c_turnover_gbp > 90000 | uk_vat_registration_required: true | UK VAT Act 1994 |

### 12.5 E-Learning (P590b-P594b)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P590b | elearning_vat_exemption_check | ELEARNING/ONLINE_COURSE/WEBINAR AND NOT publicly_funded | vat_rate: 0.23 (komercyjne) lub 0.00 (publiczne) | Art. 43 ust. 1 pkt 26-29 VAT |
| P591b | elearning_lump_sum_rate_8_5 | LUMP_SUM AND pkwiu in [85.59, 85.42, 85.41] | pit_rate: 0.085 | Art. 12 ust. 1 pkt 5 lit. a ryczałt |
| P592b | elearning_foreign_students_vat_exemption | SALE AND EU B2C AND ELEARNING | vat_rate: 0.00 (OSS) | Art. 28c ust. 1 VAT |
| P593b | elearning_non_eu_students_zero_vat | SALE AND NON_EU B2C AND ELEARNING | vat_rate: 0.00 (NP) | Art. 28c ust. 2 VAT |
| P594b | elearning_platform_revenue_split | is_platform_sale AND platform_fee > 0 AND is_education_platform | revenue_jdg: net-fee, import_services: fee | Art. 28b, Art. 17 ust. 1 pkt 4 VAT |

### 12.6 Gig Economy (P595b-P599b)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P595b | gig_economy_rideshare_vat_classification | pkd in [49.32.Z, 49.39.Z] AND RIDESHARE_SERVICE | vat_rate: 0.08 lub 0.00 (zwolnienie) | Art. 41 ust. 2, Art. 113 VAT |
| P596b | gig_economy_food_delivery_vat | pkd in [53.20.Z, 56.21.Z] AND FOOD_DELIVERY | vat_rate: 0.08 (gastronomia) lub 0.23 (kurier) | Art. 41 ust. 2 VAT |
| P597b | gig_economy_platform_commission_import | is_gig_platform AND platform_fee > 0 AND vendor.country != PL | import_services: true, reverse_charge: true | Art. 28b, Art. 17 ust. 1 pkt 4 VAT |
| P598b | gig_economy_lump_sum_rate_8_5_transport | LUMP_SUM AND pkwiu in [49-53] | pit_rate: 0.085 | Art. 12 ust. 1 pkt 5 lit. a ryczałt |
| P599b | gig_economy_mileage_tracking_obligation | pkd in [49.32.Z, 53.20.Z] AND CAR AND NOT has_mileage_log | kus_percent: 75, vat_deduction_percent: 50 | Art. 23 ust. 1 pkt 46 PIT, Art. 86a VAT |

### 12.7 ESG/CSRD/AI Act (P1800-P1822)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P1800 | mdr_reportable_scheme_detection | Transakcja z rajem podatkowym LUB struktura hybrydowa | mdr_reportable: true, mdr_form: MDR-1 | Art. 86a-86o OP |
| P1810 | esg_csrd_supplier_obligation | is_csrd_supplier AND kontrahent podlega CSRD | esg_data_required: true | CSRD Dyrektywa UE |
| P1820 | ai_act_jdg_system_classification | pkd in [62.01.Z, 62.02.Z] AND AI_SYSTEM_DEVELOPMENT | ai_act_risk_category: LIMITED/HIGH/MINIMAL | AI Act UE |
| P1821 | ai_act_high_risk_obligations | ai_act_risk_category: HIGH | conformity_assessment: true, technical_docs: true, CE: true | AI Act UE |
| P1822 | ai_act_transparency_obligations | uses_ai_content_generation AND AI_GENERATED_CONTENT | ai_transparency_label_required: true | AI Act UE |

### 12.8 API Graceful Degradation (P1850-P1855)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P1850 | api_whitelist_graceful_degradation | whitelist_status: UNKNOWN AND check_expired | routing: TRIAGE_QUEUE, whitelist_check_retry: true | — |
| P1851 | api_ceidg_graceful_degradation | ceidg_status: UNKNOWN AND NOT fraud_flag | warning, ceidg_check_retry: true | — |
| P1852 | api_ksef_graceful_degradation | ksef_status: OFFLINE | ksef_offline_mode: true, deadline_days: 7 | Art. 106ne VAT |
| P1853 | api_gus_graceful_degradation | gus_verified: false AND nip != "" | warning, gus_check_retry: true | — |
| P1854 | api_nbp_rate_fallback | currency != PLN AND NOT nbp_rate_available AND nbp_rate_cached | fx_rate: cached, fx_rate_source: CACHED | — |

### 12.9 Audit Trail & Compliance Automation (P1860-P1865)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P1860 | audit_trail_completeness_check | audit_trail_complete: false | routing: TRIAGE_QUEUE | — |
| P1861 | auto_correction_suggestion_engine | invoice.vat_rate != verdict.vat_rate AND confidence > 0.90 | auto_correction_suggested: true | — |
| P1862 | compliance_score_calculation | compliance_score < 0.70 | compliance_alert: true | — |
| P1863 | auto_flag_high_risk_transaction | amount > 50000 AND is_new AND is_cash | high_risk_flag: true, routing: TRIAGE_QUEUE | — |
| P1864 | regulatory_change_impact_assessment | thresholds.updated AND legal_impact: RETROACTIVE | regulatory_change_impact: true | — |

### 12.10 Conflict Resolution (P1870-P1875)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P1870 | conflict_vat_vs_pit_exemption | vat_exemption: SUBJECT AND pit_form != "" | domain_conflict_resolved: true | — |
| P1871 | conflict_kup_vs_vat_deduction | kus: none AND vat_deduction > 0 AND REPRESENTATION | vat_deduction_override: 0 | — |
| P1872 | conflict_suspension_vs_zus | business_status: SUSPENDED AND zus_social_due: true | zus_social_due: false, zus_health_due: true ⚠️ (zdrowotna NADAL należna!) | — |
| P1873 | conflict_lump_sum_vs_kup | tax_form: LUMP_SUM AND kus: full | kus_qualification: none | — |
| P1874 | conflict_succession_vs_personal_liability | in_succession: true AND liability: UNLIMITED_PERSONAL | liability_scope: SUCCESSION_MANAGER | — |

### 12.11 Polski Ład Edge Cases (P1880-P1885)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P1880 | polish_lad_health_no_deduction_scale | tax_form: PIT_SCALE AND ZUS_HEALTH_ENTREPRENEUR | kus: none, tax_deduction_prohibited: true | Polski Ład (uchylony art. 27b PIT) |
| P1881 | polish_lad_tax_free_30k | PIT_SCALE AND income <= 120000 | tax_free_amount: 30000, tax_reduction: 3600 | Art. 27 ust. 1a PIT |
| P1882 | polish_lad_health_lump_sum_tiers | LUMP_SUM AND revenue <= 60000 | health_tier: 1, health_base_percent: 0.60 | Art. 81 ust. 2a-2c u.ś.o.z. |
| P1883 | polish_lad_loss_one_time_5m | has_loss_carry_forward AND loss_one_time_election | loss_deduction_one_time: min(5M, remaining) | Art. 9 ust. 3 pkt 2 PIT |
| P1884 | polish_lad_residential_depreciation_ban | REAL_ESTATE_DEPRECIATION AND RESIDENTIAL AND year >= 2023 | depreciation_allowed: false | Art. 22c pkt 2 PIT |

### 12.12 Zbiegi Specjalne (P1890-P1895)

| ID | Nazwa | Warunek | Rezultat | Podstawa prawna |
|:--:|-------|---------|----------|-----------------|
| P1890 | concurrent_multiple_jdg_health | concurrent_jdg_count > 1 | zus_health_single_payment: true | Art. 9 ust. 4 SUS |
| P1891 | concurrent_jdg_spouse_separate | spouse_has_jdg: true | spouse_jdg_separate_zus: true, joint_liability: true | Art. 29 OP |
| P1892 | foreign_tax_credit_vs_abolition | foreign_income > 0 AND tax_treaty_method != "" | foreign_tax_method + abolition_relief | Art. 27g, Art. 30a ust. 5-6 PIT |
| P1893 | voluntary_health_insurance_additional | VOLUNTARY_HEALTH_INSURANCE AND is_work_related | kus: full, tax_deduction: false | Art. 22 ust. 1 PIT |
| P1894 | tax_office_electronic_mandatory | date >= 2026-01-01 AND NOT has_e_us_account | e_us_registration_required: true | Art. 75 § 1 OP (nowelizacja) |
| P1895 | real_time_tax_monitoring_alert | monthly_vat_cumulative > 50000 AND NOT under_tax_audit | real_time_monitoring_alert: true | — |
## CZĘŚĆ I: USTAWA O VAT (780 REGUŁ)

### 1.1 Art. 5-14: Czynności opodatkowane VAT (∼70 reguł)

#### Art. 5 VAT — Czynności podlegające VAT (∼10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|----------|
| `jdg.vat.a5.r1` | `vat_taxable_goods_supply_pl` | Dostawa towarów za wynagrodzeniem w PL | VAT należny | Art. 5 ust. 1 pkt 1 VAT |
| `jdg.vat.a5.r2` | `vat_taxable_services_supply_pl` | Świadczenie usług za wynagrodzeniem w PL | VAT należny | Art. 5 ust. 1 pkt 1 VAT |
| `jdg.vat.a5.r3` | `vat_taxable_export_goods` | Eksport towarów poza UE | VAT 0% | Art. 5 ust. 1 pkt 2 VAT |
| `jdg.vat.a5.r4` | `vat_taxable_import_goods` | Import towarów spoza UE | VAT należny w imporcie | Art. 5 ust. 1 pkt 3 VAT |
| `jdg.vat.a5.r5` | `vat_taxable_wnt_intra_eu` | Wewnątrzwspólnotowe nabycie towarów (WNT) | VAT należny w kraju nabycia | Art. 5 ust. 1 pkt 4 VAT |
| `jdg.vat.a5.r6` | `vat_taxable_wdt_intra_eu` | Wewnątrzwspólnotowa dostawa towarów (WDT) | VAT 0% | Art. 5 ust. 1 pkt 5 VAT |
| `jdg.vat.a5.r7` | `vat_taxable_non_cash_contribution` | Wkład niepieniężny (aport) do spółki | VAT należny | Art. 5 ust. 1 pkt 1 VAT |
| `jdg.vat.a5.r8` | `vat_taxable_compensation_delivery` | Odpłatna dostawa w zamian za inne świadczenie (barter) | VAT należny | Art. 5 ust. 1 pkt 1 VAT |
| `jdg.vat.a5.r9` | `vat_taxable_gratis_transfer_goods` | Nieodpłatne przekazanie towarów na cele osobiste JDG | VAT należny (gdy prawo do odliczenia) | Art. 7 ust. 2 VAT |
| `jdg.vat.a5.r10` | `vat_taxable_gratis_services` | Nieodpłatne świadczenie usług na cele osobiste JDG | VAT należny (gdy prawo do odliczenia) | Art. 8 ust. 2 VAT |

#### Art. 7 VAT — Dostawa towarów (∼12 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a7.r1` | `delivery_transfer_ownership` | Przeniesienie prawa do rozporządzania towarem jak właściciel | Definiuje dostawę |
| `jdg.vat.a7.r2` | `delivery_consignment_sale` | Wydanie towaru w komis — dostawa w momencie wydania | Dostawa |
| `jdg.vat.a7.r3` | `delivery_installment_sale` | Sprzedaż ratalna — dostawa w momencie wydania | Dostawa |
| `jdg.vat.a7.r4` | `delivery_lease_financial` | Umowa leasingu finansowego — zrównana z dostawą | Dostawa |
| `jdg.vat.a7.r5` | `delivery_building_construction_land` | Przeniesienie własności budynku w zamian za prawo użytkowania wieczystego gruntu | Dostawa |
| `jdg.vat.a7.r6` | `delivery_electricity_gas_heat` | Dostawa energii elektrycznej, cieplnej, gazu | Dostawa |
| `jdg.vat.a7.r7` | `delivery_water_sewage` | Dostawa wody, odbiór ścieków | Dostawa |
| `jdg.vat.a7.r8` | `delivery_gratis_to_employee` | Nieodpłatne przekazanie towaru pracownikowi JDG | VAT należny (gdy odliczono VAT) |
| `jdg.vat.a7.r9` | `delivery_gratis_to_owner_personal` | Nieodpłatne przekazanie towaru na cele osobiste przedsiębiorcy JDG | VAT należny |
| `jdg.vat.a7.r10` | `delivery_gratis_donation_opp` | Nieodpłatne przekazanie towaru na cele OPP | VAT NIE należny (wyjątek) |
| `jdg.vat.a7.r11` | `delivery_gratis_under_10_pln` | Przekazanie prezentów o małej wartości (<10 PLN) | VAT NIE należny |
| `jdg.vat.a7.r12` | `delivery_gratis_samples` | Przekazanie próbek towarów | VAT NIE należny |

#### Art. 8 VAT — Świadczenie usług (∼12 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a8.r1` | `service_definition_b2b` | Każde świadczenie na rzecz B2B niebędące dostawą towarów | Usługa |
| `jdg.vat.a8.r2` | `service_definition_b2c` | Każde świadczenie na rzecz B2C niebędące dostawą towarów | Usługa |
| `jdg.vat.a8.r3` | `service_transfer_intangible` | Zbycie praw, udzielenie licencji, know-how | Usługa |
| `jdg.vat.a8.r4` | `service_obligation_to_abstain` | Zobowiązanie do powstrzymania się od działania | Usługa |
| `jdg.vat.a8.r5` | `service_undertaking_to_perform` | Zobowiązanie do wykonania czynności | Usługa |
| `jdg.vat.a8.r6` | `service_free_of_charge_business` | Nieodpłatne usługi na cele firmowe | VAT NIE należny |
| `jdg.vat.a8.r7` | `service_free_of_charge_owner` | Nieodpłatne usługi na cele osobiste JDG | VAT należny |
| `jdg.vat.a8.r8` | `service_free_of_charge_employee` | Nieodpłatne usługi na rzecz pracownika | VAT należny |
| `jdg.vat.a8.r9` | `service_employee_benefit_exempt` | Nieodpłatne usługi dla pracowników (opieka medyczna, kultura) | zwolnione z VAT |
| `jdg.vat.a8.r10` | `service_lunch_vouchers` | Vouchery lunchowe dla pracowników | zwolnione z VAT |
| `jdg.vat.a8.r11` | `service_rental_of_property` | Najem, dzierżawa, leasing nieruchomości | Usługa — miejsce świadczenia wg miejsca położenia |
| `jdg.vat.a8.r12` | `service_rental_of_movable` | Najem, dzierżawa ruchomości | Usługa |

#### Art. 9-14 VAT — Podatnicy, rejestracja VAT-R (∼15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a15.r1` | `vat_payer_definition_jdg` | Osoba fizyczna prowadząca JDG wykonująca czynności opodatkowane | Podatnik VAT |
| `jdg.vat.a15.r2` | `vat_payer_independent_activity` | Działalność wykonywana samodzielnie, w sposób ciągły, zarobkowy | Kryterium podatnika |
| `jdg.vat.a15.r3` | `vat_payer_non_employee_relationship` | Brak stosunku pracy (JDG nie jest pracownikiem nabywcy) | Warunek bycia podatnikiem |
| `jdg.vat.a15.r4` | `vat_payer_employee_exception` | Umowa o pracę — NIE jest podatnikiem VAT | Wyłączenie |
| `jdg.vat.a96.r1` | `vat_r_registration_before_first_sale` | VAT-R przed pierwszą czynnością opodatkowaną | Obowiązek rejestracji |
| `jdg.vat.a96.r2` | `vat_r_deadline_for_registration` | VAT-R składany do Naczelnika US przed pierwszym dniem działalności VAT | Termin |
| `jdg.vat.a96.r3` | `vat_r_office_deadline_3_months` | US ma 3 miesiące na rejestrację (lub odmowę) | Czas oczekiwania |
| `jdg.vat.a96.r4` | `vat_r_refusal_grounds` | Brak adresu siedziby, zaległości podatkowe, powiązania z fraudem | Podstawy odmowy |
| `jdg.vat.a96.r5` | `vat_r_mandatory_fields` | NIP, REGON, adres, forma prawna, PKD, rachunek bankowy | Wymagane dane VAT-R |
| `jdg.vat.a96.r6` | `vat_r_change_of_data` | Zmiana danych (adres, forma prawna) — VAT-R aktualizacja w 7 dni | Obowiązek |
| `jdg.vat.a96.r7` | `vat_z_deregistration_on_closure` | VAT-Z przy zaprzestaniu działalności VAT | Obowiązek |
| `jdg.vat.a96.r8` | `vat_z_deadline_30_days` | VAT-Z w 30 dni od zaprzestania działalności VAT | Termin |
| `jdg.vat.a96.r9` | `vat_z_ex_officio_deregistration` | Wyrejestrowanie z urzędu po 6 miesiącach bez sprzedaży | Sankcja |
| `jdg.vat.a96.r10` | `vat_r_eu_registration_for_wdt` | VAT-UE przed pierwszym WDT | Obowiązek |
| `jdg.vat.a96.r11` | `vat_r_eu_refusal_crossborder` | Brak rejestracji VAT-UE = brak możliwości WDT | Konsekwencja |

### 1.2 Art. 19a-21: Obowiązek podatkowy VAT (∼50 reguł)

#### Art. 19a VAT — Zasada ogólna momentu powstania obowiązku (∼15 reguł)

| ID | Nazwa reguły | Warunek | Moment obowiązku |
|:--:|-------------|---------|:----------------:|
| `jdg.vat.a19a.r1` | `tax_point_general_delivery_goods` | Dostawa towarów — z chwilą wydania towaru | Data wydania |
| `jdg.vat.a19a.r2` | `tax_point_general_service_completed` | Usługa — z chwilą wykonania usługi | Data wykonania |
| `jdg.vat.a19a.r3` | `tax_point_invoice_before_delivery` | Faktura wystawiona przed wydaniem/wykonaniem | Data faktury |
| `jdg.vat.a19a.r4` | `tax_point_payment_before_delivery` | Zapłata przed wydaniem/wykonaniem | Data zapłaty |
| `jdg.vat.a19a.r5` | `tax_point_invoice_30_days_after` | Faktura >30 dni po dostawie — 30. dzień od dostawy | 30. dzień od dostawy |
| `jdg.vat.a19a.r6` | `tax_point_continuous_services_end` | Usługi ciągłe (czynsz, najem, abonament) — koniec okresu | Koniec okresu rozliczeniowego |
| `jdg.vat.a19a.r7` | `tax_point_continuous_services_payment` | Usługi ciągłe — zapłata przed końcem okresu | Data zapłaty |
| `jdg.vat.a19a.r8` | `tax_point_energy_supply_readings` | Dostawa energii — wg odczytów liczników | Data odczytu |
| `jdg.vat.a19a.r9` | `tax_point_lease_rent_services` | Usługi najmu, dzierżawy — okres miesięczny/kwartalny | Koniec okresu |
| `jdg.vat.a19a.r10` | `tax_point_commission_sale` | Sprzedaż komisowa — data sprzedaży towaru przez komisanta | Data sprzedaży |
| `jdg.vat.a19a.r11` | `tax_point_consignment_goods_pickup` | Pobranie towaru przez nabywcę z magazynu | Data pobrania |
| `jdg.vat.a19a.r12` | `tax_point_construction_acceptance` | Usługi budowlane — data protokołu zdawczo-odbiorczego | Data protokołu |
| `jdg.vat.a19a.r13` | `tax_point_construction_partial_acceptance` | Częściowy odbiór robót budowlanych | Data częściowego protokołu |
| `jdg.vat.a19a.r14` | `tax_point_advertising_media` | Usługi reklamowe w mediach — emisja reklamy | Data emisji |
| `jdg.vat.a19a.r15` | `tax_point_transport_logistics` | Usługi transportowe — data dostarczenia przesyłki | Data dostarczenia |

#### Art. 20 VAT — Obowiązek podatkowy WNT (∼10 reguł)

| ID | Nazwa reguły | Warunek | Moment obowiązku |
|:--:|-------------|---------|:----------------:|
| `jdg.vat.a20.r1` | `tax_point_wnt_invoice` | WNT — 15. dzień miesiąca po wydaniu towaru | 15. dzień miesiąca |
| `jdg.vat.a20.r2` | `tax_point_wnt_invoice_before` | Faktura WNT przed 15. dniem miesiąca | Data faktury |
| `jdg.vat.a20.r3` | `tax_point_wnt_payment_advance` | Zapłata zaliczki na WNT | Data zapłaty |
| `jdg.vat.a20.r4` | `tax_point_wnt_new_transport` | Nowy środek transportu (WNT) | Data wydania przez dostawcę |
| `jdg.vat.a20.r5` | `tax_point_wnt_new_transport_invoice` | Nowy środek transportu — faktura przed wydaniem | Data faktury |
| `jdg.vat.a20.r6` | `tax_point_wnt_chain_transaction` | WNT w transakcji łańcuchowej | Wg roli w łańcuchu |
| `jdg.vat.a20.r7` | `tax_point_wnt_installation` | WNT z montażem/instalacją | Data zakończenia instalacji |
| `jdg.vat.a20.r8` | `tax_point_wnt_excise_goods` | WNT wyrobów akcyzowych | Zgodnie z przepisami akcyzowymi |
| `jdg.vat.a20.r9` | `tax_point_wnt_gas_electricity` | WNT gazu, energii elektrycznej | Data odczytu licznika |
| `jdg.vat.a20.r10` | `tax_point_wnt_water_works` | WNT robót budowlanych przez podmiot UE | Data protokołu odbioru |

#### Art. 21 VAT — Metoda kasowa (mały podatnik) (∼10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a21.r1` | `cash_accounting_eligibility_small_payer` | Mały podatnik (obrót < 2M EUR) wybiera metodę kasową | Możliwość |
| `jdg.vat.a21.r2` | `cash_accounting_tax_point_payment` | Obowiązek podatkowy w dacie otrzymania zapłaty | Data zapłaty |
| `jdg.vat.a21.r3` | `cash_accounting_tax_point_full_payment` | Płatność częściowa — obowiązek od otrzymanej części | Częściowa zapłata |
| `jdg.vat.a21.r4` | `cash_accounting_tax_point_advance` | Zaliczka otrzymana przed dostawą | Data zaliczki |
| `jdg.vat.a21.r5` | `cash_accounting_deduction_payment` | Prawo do odliczenia w dacie zapłaty (JDG jako nabywca) | Data zapłaty |
| `jdg.vat.a21.r6` | `cash_accounting_invoice_before_payment` | Faktura przed zapłatą — brak obowiązku przed zapłatą | Odroczenie |
| `jdg.vat.a21.r7` | `cash_accounting_loss_of_right_2m_eur` | Przekroczenie 2M EUR obrotu — utrata prawa do metody kasowej | Koniec metody kasowej |
| `jdg.vat.a21.r8` | `cash_accounting_notification_us` | Zawiadomienie US o wyborze metody kasowej | Obowiązek formalny |
| `jdg.vat.a21.r9` | `cash_accounting_change_deadline` | Zmiana na metodę kasową od początku okresu rozliczeniowego | Termin zmiany |
| `jdg.vat.a21.r10` | `cash_accounting_excluded_transactions` | Wyłączenia: WDT, eksport, WNT | Metoda kasowa NIE dotyczy |

### 1.3 Art. 29a-32: Podstawa opodatkowania VAT (∼40 reguł)

#### Art. 29a VAT — Podstawa opodatkowania (∼15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a29a.r1` | `tax_base_general_everything_received` | Wszystko, co stanowi zapłatę od nabywcy | Podstawa = kwota należna |
| `jdg.vat.a29a.r2` | `tax_base_includes_taxes_duties` | Podstawa obejmuje cła, akcyzę, opłaty | Powiększenie podstawy |
| `jdg.vat.a29a.r3` | `tax_base_excludes_vat` | Podstawa NIE obejmuje VAT | Czyszczenie podstawy |
| `jdg.vat.a29a.r4` | `tax_base_includes_costs_commission` | Koszty dodatkowe (prowizja, opakowanie, transport) | Powiększenie podstawy |
| `jdg.vat.a29a.r5` | `tax_base_includes_subsidies` | Dotacje związane z ceną | Powiększenie podstawy |
| `jdg.vat.a29a.r6` | `tax_base_reduction_discount_before` | Rabat przed sprzedażą — obniżenie podstawy | Pomniejszenie |
| `jdg.vat.a29a.r7` | `tax_base_reduction_discount_after` | Rabat po sprzedaży — korekta in minus | Korekta |
| `jdg.vat.a29a.r8` | `tax_base_reduction_return_goods` | Zwrot towarów — korekta in minus | Korekta |
| `jdg.vat.a29a.r9` | `tax_base_reduction_bad_debt` | Złe długi — korekta podstawy (po spełnieniu warunków) | Korekta |
| `jdg.vat.a29a.r10` | `tax_base_rebate_for_early_payment` | Skonto za wcześniejszą zapłatę — korekta in minus | Korekta |
| `jdg.vat.a29a.r11` | `tax_base_non_cash_consideration` | Zapłata w naturze (barter) — wartość rynkowa | Podstawa = wartość rynkowa |
| `jdg.vat.a29a.r12` | `tax_base_related_party_market_value` | Transakcja z podmiotem powiązanym poniżej wartości rynkowej | Podstawa = wartość rynkowa |
| `jdg.vat.a29a.r13` | `tax_base_gratis_transfer` | Nieodpłatne przekazanie — cena nabycia/koszt wytworzenia | Podstawa = koszt |
| `jdg.vat.a29a.r14` | `tax_base_personal_use` | Wykorzystanie firmowego towaru na cele osobiste | Podstawa = koszt |
| `jdg.vat.a29a.r15` | `tax_base_margin_scheme` | Procedura marży — podstawa = marża (nie cała kwota) | Podstawa = marża |

### 1.4 Art. 41-42: Stawki VAT (∼50 reguł)

#### Stawki podstawowe (∼15 reguł)

| ID | Nazwa reguły | Warunek | Stawka |
|:--:|-------------|---------|:-----:|
| `jdg.vat.a41.r1` | `vat_rate_23_standard` | Domyślna stawka dla wszystkich towarów i usług w PL | 23% |
| `jdg.vat.a41.r2` | `vat_rate_23_fuel` | Paliwa silnikowe, oleje opałowe | 23% |
| `jdg.vat.a41.r3` | `vat_rate_23_electronics` | Sprzęt elektroniczny, RTV, AGD, komputery | 23% |
| `jdg.vat.a41.r4` | `vat_rate_23_construction_materials` | Materiały budowlane | 23% |
| `jdg.vat.a41.r5` | `vat_rate_23_consulting` | Usługi konsultingowe, doradcze, prawne, księgowe | 23% |
| `jdg.vat.a41.r6` | `vat_rate_23_transport_goods` | Transport towarów (krajowy) | 23% |
| `jdg.vat.a41.r7` | `vat_rate_23_it_services` | Usługi IT (programowanie, hosting, SaaS) — krajowe | 23% |
| `jdg.vat.a41.r8` | `vat_rate_23_marketing_advertising` | Usługi marketingowe, reklamowe | 23% |
| `jdg.vat.a41.r9` | `vat_rate_23_cleaning_maintenance` | Usługi sprzątania, utrzymania czystości | 23% |
| `jdg.vat.a41.r10` | `vat_rate_23_telecommunications` | Usługi telekomunikacyjne | 23% |
| `jdg.vat.a41.r11` | `vat_rate_23_rental_commercial` | Najem lokali użytkowych, biur, magazynów | 23% |
| `jdg.vat.a41.r12` | `vat_rate_23_vehicles` | Sprzedaż samochodów, pojazdów (nowych i używanych) | 23% |
| `jdg.vat.a41.r13` | `vat_rate_23_alcohol_tobacco` | Alkohol, wyroby tytoniowe | 23% |
| `jdg.vat.a41.r14` | `vat_rate_23_jewelry_luxury` | Biżuteria, wyroby luksusowe | 23% |
| `jdg.vat.a41.r15` | `vat_rate_23_furniture` | Meble, wyposażenie wnętrz | 23% |

#### Stawka 8% (∼12 reguł)

| ID | Nazwa reguły | Warunek | Stawka |
|:--:|-------------|---------|:-----:|
| `jdg.vat.a41.r16` | `vat_rate_8_food_basic` | Podstawowe produkty spożywcze (pieczywo, nabiał, mięso, warzywa) | 8% |
| `jdg.vat.a41.r17` | `vat_rate_8_food_baby` | Żywność dla niemowląt, preparaty mlekozastępcze | 8% |
| `jdg.vat.a41.r18` | `vat_rate_8_water_supply` | Dostawa wody, odprowadzanie ścieków | 8% |
| `jdg.vat.a41.r19` | `vat_rate_8_waste_collection` | Wywóz śmieci, gospodarka odpadami | 8% |
| `jdg.vat.a41.r20` | `vat_rate_8_cleaning_streets` | Utrzymanie czystości, dezynfekcja | 8% |
| `jdg.vat.a41.r21` | `vat_rate_8_construction_residential` | Roboty budowlano-remontowe w obiektach mieszkalnych | 8% |
| `jdg.vat.a41.r22` | `vat_rate_8_construction_social` | Budownictwo społeczne (TBS, gminne) | 8% |
| `jdg.vat.a41.r23` | `vat_rate_8_pharmaceuticals` | Leki, produkty farmaceutyczne | 8% |
| `jdg.vat.a41.r24` | `vat_rate_8_medical_equipment` | Sprzęt medyczny, ortopedyczny, rehabilitacyjny | 8% |
| `jdg.vat.a41.r25` | `vat_rate_8_transport_passenger` | Transport pasażerski (krajowy) | 8% |
| `jdg.vat.a41.r26` | `vat_rate_8_hotel_services` | Usługi hotelarskie, noclegowe | 8% |
| `jdg.vat.a41.r27` | `vat_rate_8_cultural_events` | Wstęp na imprezy kulturalne, sportowe | 8% |

#### Stawka 5% (∼8 reguł)

| ID | Nazwa reguły | Warunek | Stawka |
|:--:|-------------|---------|:-----:|
| `jdg.vat.a41.r28` | `vat_rate_5_books_print` | Książki drukowane (z wyłączeniem podręczników akademickich) | 5% |
| `jdg.vat.a41.r29` | `vat_rate_5_ebooks_digital` | E-booki, audiobooki, cyfrowe wydania książek | 5% |
| `jdg.vat.a41.r30` | `vat_rate_5_newspapers` | Gazety, czasopisma (prasa regionalna/krajowa) | 5% |
| `jdg.vat.a41.r31` | `vat_rate_5_food_basic_extended` | Podstawowe produkty spożywcze zgodnie z załącznikiem do rozp. MF | 5% |
| `jdg.vat.a41.r32` | `vat_rate_5_baby_products` | Artykuły dla niemowląt (pieluchy, ubranka) | 5% |
| `jdg.vat.a41.r33` | `vat_rate_5_food_meat_fish` | Mięso, ryby, owoce morza (nieprzetworzone) | 5% |
| `jdg.vat.a41.r34` | `vat_rate_5_agricultural_inputs` | Środki produkcji rolnej (nasiona, nawozy) | 5% |
| `jdg.vat.a41.r35` | `vat_rate_5_disposable_medical` | Maseczki, rękawiczki medyczne (jednorazowe) | 5% |

#### Stawka 0% i zwolnienia przedmiotowe (∼15 reguł)

| ID | Nazwa reguły | Warunek | Stawka |
|:--:|-------------|---------|:-----:|
| `jdg.vat.a41.r36` | `vat_rate_0_export_direct` | Eksport towarów bezpośredni poza UE | 0% |
| `jdg.vat.a41.r37` | `vat_rate_0_export_indirect` | Eksport pośredni (przez agencję celną) | 0% |
| `jdg.vat.a41.r38` | `vat_rate_0_wdt_intra_eu` | WDT do nabywcy z VAT-UE | 0% |
| `jdg.vat.a41.r39` | `vat_rate_0_wdt_documentation_required` | WDT — wymagane dokumenty potwierdzające wywóz z PL | 0% warunkowo |
| `jdg.vat.a41.r40` | `vat_rate_0_wdt_missing_docs_domestic` | WDT — brak dokumentów w 3 miesiące → stawka krajowa | Sankcja |
| `jdg.vat.a41.r41` | `vat_rate_0_international_transport` | Międzynarodowy transport towarów | 0% |
| `jdg.vat.a41.r42` | `vat_rate_0_international_transport_passenger` | Międzynarodowy transport pasażerski | 0% |
| `jdg.vat.a41.r43` | `vat_rate_0_services_related_to_export` | Usługi pomocnicze do eksportu (załadowanie, spedycja) | 0% |
| `jdg.vat.a41.r44` | `vat_rate_0_supplies_to_ships_aircraft` | Dostawy na statki, samoloty w komunikacji międzynarodowej | 0% |
| `jdg.vat.a41.r45` | `vat_exemption_object_education` | Usługi edukacyjne (szkoły, uczelnie) | ZW (zwolnione) |
| `jdg.vat.a41.r46` | `vat_exemption_object_healthcare` | Usługi medyczne, opieka zdrowotna | ZW |
| `jdg.vat.a41.r47` | `vat_exemption_object_social_security` | Pomoc społeczna, opieka nad osobami starszymi | ZW |
| `jdg.vat.a41.r48` | `vat_exemption_object_culture_sport` | Usługi kulturalne, sportowe (niekomercyjne) | ZW |
| `jdg.vat.a41.r49` | `vat_exemption_object_financial_insurance` | Usługi finansowe, ubezpieczeniowe | ZW |
| `jdg.vat.a41.r50` | `vat_exemption_object_land_except_building` | Dostawa gruntów (niezabudowanych, budowlanych) | ZW (z opcją VAT) |

### 1.5 Art. 43: Zwolnienia przedmiotowe VAT (∼40 reguł)

| ID | Nazwa reguły | Przedmiot zwolnienia | Warunek | Podstawa |
|:--:|-------------|---------------------|---------|----------|
| `jdg.vat.a43.r1` | `object_exemption_medical_doctors` | Usługi lekarzy, dentystów, lekarzy weterynarii | W ramach wykonywania zawodu | Art. 43 ust. 1 pkt 18 |
| `jdg.vat.a43.r2` | `object_exemption_medical_nurses` | Usługi pielęgniarek, położnych | W ramach wykonywania zawodu | Art. 43 ust. 1 pkt 19 |
| `jdg.vat.a43.r3` | `object_exemption_medical_rehabilitation` | Usługi rehabilitacji, fizjoterapii | W ramach wykonywania zawodu | Art. 43 ust. 1 pkt 20 |
| `jdg.vat.a43.r4` | `object_exemption_medical_psychology` | Usługi psychologów, psychoterapeutów | W ramach wykonywania zawodu | Art. 43 ust. 1 pkt 21 |
| `jdg.vat.a43.r5` | `object_exemption_medical_transport` | Transport sanitarny pacjentów | Przez uprawnione podmioty | Art. 43 ust. 1 pkt 22 |
| `jdg.vat.a43.r6` | `object_exemption_school_university` | Usługi edukacyjne — szkoły, przedszkola, uczelnie | Świadczone przez jednostki objęte systemem oświaty | Art. 43 ust. 1 pkt 26 |
| `jdg.vat.a43.r7` | `object_exemption_private_tutoring` | Korepetycje, prywatne lekcje | Nauczanie języków obcych, muzyki, sportu | Art. 43 ust. 1 pkt 27 |
| `jdg.vat.a43.r8` | `object_exemption_vocational_training` | Usługi kształcenia zawodowego, szkolenia | Finansowane ze środków publicznych | Art. 43 ust. 1 pkt 29 |
| `jdg.vat.a43.r9` | `object_exemption_social_welfare` | Pomoc społeczna, opieka nad dziećmi, osobami starszymi | Przez uprawnione podmioty | Art. 43 ust. 1 pkt 22-25 |
| `jdg.vat.a43.r10` | `object_exemption_culture_non_commercial` | Usługi kulturalne — teatry, muzea, biblioteki | Niepubliczne, niekomercyjne | Art. 43 ust. 1 pkt 33 |
| `jdg.vat.a43.r11` | `object_exemption_sport_non_commercial` | Usługi związane z upowszechnianiem sportu | Niepubliczne, niekomercyjne | Art. 43 ust. 1 pkt 32 |
| `jdg.vat.a43.r12` | `object_exemption_postal_universal` | Usługi pocztowe świadczone przez operatora wyznaczonego | W ramach usług powszechnych | Art. 43 ust. 1 pkt 17 |
| `jdg.vat.a43.r13` | `object_exemption_financial_loans` | Udzielanie pożyczek, kredytów przez JDG (private lending) | Gdy nie jest to działalność podstawowa | Art. 43 ust. 1 pkt 38 |
| `jdg.vat.a43.r14` | `object_exemption_insurance_agent` | Działalność agentów ubezpieczeniowych | W ramach pośrednictwa | Art. 43 ust. 1 pkt 7 |
| `jdg.vat.a43.r15` | `object_exemption_real_estate_existing` | Dostawa budynków po pierwszym zasiedleniu | Po 2 latach od pierwszego zasiedlenia | Art. 43 ust. 1 pkt 10 |
| `jdg.vat.a43.r16` | `object_exemption_real_estate_first_occupancy` | Pierwsze zasiedlenie nieruchomości | Definicja pierwszego zasiedlenia | Art. 43 ust. 1 pkt 10 |
| `jdg.vat.a43.r17` | `object_exemption_real_estate_option_vat` | Rezygnacja ze zwolnienia (opcja VAT) na nieruchomości | Złożenie oświadczenia VAT-23 | Art. 43 ust. 10-11 |
| `jdg.vat.a43.r18` | `object_exemption_buildings_for_rent` | Wynajem nieruchomości mieszkalnych na cele mieszkaniowe | Na cele stałego zamieszkania | Art. 43 ust. 1 pkt 36 |
| `jdg.vat.a43.r19` | `object_exemption_buildings_rent_short` | Krótkoterminowy najem turystyczny (Airbnb) przez JDG | NIE jest zwolniony → 23% VAT | Art. 43 ust. 1 pkt 36 (nie dotyczy) |
| `jdg.vat.a43.r20` | `object_exemption_dental_services` | Usługi protetyki stomatologicznej, dentystycznej | Wykonywane przez osoby uprawnione | Art. 43 ust. 1 pkt 14 |
| `jdg.vat.a43.r21` | `object_exemption_blood_organs` | Pobranie krwi, mleka, narządów | Przez uprawnione podmioty | Art. 43 ust. 1 pkt 15 |
| `jdg.vat.a43.r22` | `object_exemption_funeral_cremation` | Usługi pogrzebowe, kremacyjne | Przez uprawnione podmioty | Art. 43 ust. 1 pkt 38 |
| `jdg.vat.a43.r23` | `object_exemption_real_estate_agricultural` | Dostawa gruntów rolnych (z wyłączeniem budowlanych) | Na cele rolnicze | Art. 43 ust. 1 pkt 9 |
| `jdg.vat.a43.r24` | `object_exemption_lease_agricultural` | Dzierżawa gruntów rolnych | Na cele rolnicze | Art. 43 ust. 1 pkt 9 |
| `jdg.vat.a43.r25` | `object_exemption_forestry` | Usługi leśne, dostawa drewna z lasów | Przez nadleśnictwa | Art. 43 ust. 1 pkt 34 |
| `jdg.vat.a43.r26` | `object_exemption_public_transport` | Usługi transportu miejskiego, regionalnego | Finansowane ze środków publicznych | Art. 43 ust. 1 pkt 30 |
| `jdg.vat.a43.r27` | `object_exemption_international_organizations` | Usługi na rzecz organizacji międzynarodowych, ambasad | Zwolnienie dyplomatyczne | Art. 43 ust. 1 pkt 45 |
| `jdg.vat.a43.r28` | `object_exemption_radio_tv_public` | Usługi nadawców publicznych (TVP, Polskie Radio) | Misja publiczna | Art. 43 ust. 1 pkt 34 |
| `jdg.vat.a43.r29` | `object_exemption_ngo_services` | Usługi organizacji pożytku publicznego (OPP) | Nieodpłatne na cele statutowe | Art. 43 ust. 1 pkt 31 |
| `jdg.vat.a43.r30` | `object_exemption_rent_public_housing` | Wynajem lokali przez gminę/TBS | Na cele mieszkaniowe | Art. 43 ust. 1 pkt 36 |
| `jdg.vat.a43.r31` | `object_exemption_property_management` | Zarządzanie nieruchomościami mieszkalnymi | Wspólnoty mieszkaniowe | Art. 43 ust. 1 pkt 39 |
| `jdg.vat.a43.r32` | `object_exemption_spiritual_services` | Usługi kościołów, związków wyznaniowych | Cele religijne, duchowe | Art. 43 ust. 1 pkt 35-36 |
| `jdg.vat.a43.r33` | `object_exemption_chapel_weddings` | Usługi ślubne w kościołach, wynajem kaplic | Przez związki wyznaniowe | Art. 43 ust. 1 pkt 35 |
| `jdg.vat.a43.r34` | `object_exemption_adoption_services` | Usługi adopcyjne | Przez uprawnione podmioty | Art. 43 ust. 1 pkt 40 |
| `jdg.vat.a43.r35` | `object_exemption_child_care` | Opieka nad dziećmi (żłobki, kluby dziecięce) | Przez uprawnione podmioty | Art. 43 ust. 1 pkt 24 |
| `jdg.vat.a43.r36` | `object_exemption_elderly_care` | Opieka nad osobami starszymi, niepełnosprawnymi | Dzienny pobyt, hospicjum | Art. 43 ust. 1 pkt 22 |
| `jdg.vat.a43.r37` | `object_exemption_disabled_work_therapy` | Warsztaty terapii zajęciowej, zakłady aktywności zawodowej | Dla osób niepełnosprawnych | Art. 43 ust. 1 pkt 41 |
| `jdg.vat.a43.r38` | `object_exemption_cultural_promotion` | Promocja kultury, sztuki | Niepubliczne instytucje kultury | Art. 43 ust. 1 pkt 33 |
| `jdg.vat.a43.r39` | `object_exemption_second_hand_goods_margin` | Dostawa towarów używanych (procedura marży) | Nabyte od osób prywatnych | Art. 120 VAT |
| `jdg.vat.a43.r40` | `object_exemption_collectors_items` | Dostawa przedmiotów kolekcjonerskich (procedura marży) | Nabyte od osób prywatnych | Art. 120 VAT |

### 1.6 Art. 86-96: Odliczenia VAT (∼80 reguł)

#### Art. 86 VAT — Prawo do odliczenia VAT (∼20 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a86.r1` | `deduction_right_general` | Zakup towarów/usług związanych z czynnościami opodatkowanymi | Prawo do odliczenia VAT naliczonego |
| `jdg.vat.a86.r2` | `deduction_vat_payer_only` | Prawo do odliczenia przysługuje tylko czynnym podatnikom VAT | Warunek podmiotowy |
| `jdg.vat.a86.r3` | `deduction_invoice_possession` | Posiadanie faktury VAT (lub dokumentu celnego SAD) | Warunek formalny |
| `jdg.vat.a86.r4` | `deduction_invoice_required_fields` | Faktura musi zawierać: NIP, datę, kwotę, stawkę VAT | Warunek formalny szczegółowy |
| `jdg.vat.a86.r5` | `deduction_invoice_incorrect_nip_block` | Faktura z błędnym NIPem — brak prawa do odliczenia | Blokada |
| `jdg.vat.a86.r6` | `deduction_proportion_mixed` | Wydatek mieszany (opodatkowany + zwolniony) — proporcja | Odliczenie % |
| `jdg.vat.a86.r7` | `deduction_proportion_estimated` | Wstępna proporcja na podstawie obrotów z roku poprzedniego | Proporcja wstępna |
| `jdg.vat.a86.r8` | `deduction_proportion_actual_year_end` | Korekta proporcji na koniec roku na podstawie faktycznych obrotów | Proporcja ostateczna |
| `jdg.vat.a86.r9` | `deduction_proportion_de_minimis` | Proporcja < 2% = brak prawa do odliczenia (0%) | Brak odliczenia |
| `jdg.vat.a86.r10` | `deduction_proportion_full_98` | Proporcja > 98% = pełne prawo do odliczenia (100%) | Pełne odliczenie |
| `jdg.vat.a86.r11` | `deduction_pre_proportion_banking` | Pre-proporcja dla JDG w usługach finansowych | Specjalna proporcja |
| `jdg.vat.a86.r12` | `deduction_import_goods_customs` | Podstawa odliczenia VAT od importu = wartość celna + cło + akcyza | Podstawa importu |
| `jdg.vat.a86.r13` | `deduction_wnt_goods` | VAT należny od WNT = podstawa × stawka krajowa | Odliczenie WNT |
| `jdg.vat.a86.r14` | `deduction_reverse_charge_domestic` | Odwrotne obciążenie krajowe (budowlanka) | VAT należny = VAT naliczony |
| `jdg.vat.a86.r15` | `deduction_services_import_eu` | Import usług B2B z UE | Reverse charge |
| `jdg.vat.a86.r16` | `deduction_services_import_non_eu` | Import usług B2B spoza UE | Reverse charge |
| `jdg.vat.a86.r17` | `deduction_self_import_services` | Samodzielne świadczenie usług na własne potrzeby (np. budowa) | VAT należny od własnych usług |
| `jdg.vat.a86.r18` | `deduction_additional_costs` | Koszty dodatkowe (prowizja, odsetki) związane z importem | Odliczenie VAT od kosztów |
| `jdg.vat.a86.r19` | `deduction_vat_deposit_guarantee` | VAT od kaucji, gwarancji, depozytów | Brak odliczenia |
| `jdg.vat.a86.r20` | `deduction_vat_from_subsidies` | VAT dotacji, dofinansowań, grantów | Odliczenie (jeśli dot. czynności opodatkowanych) |

#### Art. 88 VAT — Wyłączenia z odliczenia (∼15 reguł)

| ID | Nazwa reguły | Wydatek wyłączony | Podstawa |
|:--:|-------------|-------------------|----------|
| `jdg.vat.a88.r1` | `deduction_blocked_hotel_services` | Usługi noclegowe, hotelarskie (gastronomia) | Art. 88 ust. 1 pkt 4 |
| `jdg.vat.a88.r2` | `deduction_blocked_restaurant_except_catering` | Usługi gastronomiczne (z wyjątkiem cateringu dla pracowników) | Art. 88 ust. 1 pkt 4 |
| `jdg.vat.a88.r3` | `deduction_blocked_fuel_car_mixed` | Paliwo do samochodów osobowych używanych mieszanie | Art. 88 ust. 1 pkt 3, Art. 86a |
| `jdg.vat.a88.r4` | `deduction_blocked_entertainment` | Wydatki na rozrywkę, imprezy, reprezentację | Art. 88 ust. 1 pkt 4 |
| `jdg.vat.a88.r5` | `deduction_blocked_gifts_large` | Prezenty o wartości > 20 PLN (chyba że podlegają opodatkowaniu) | Art. 88 ust. 1 pkt 5 |
| `jdg.vat.a88.r6` | `deduction_blocked_gifts_samples_except` | Próbki, prezenty małej wartości (do 20 PLN) — odliczenie dozwolone | Wyjątek |
| `jdg.vat.a88.r7` | `deduction_blocked_personal_use` | Wydatki na cele osobiste przedsiębiorcy JDG | Art. 88 ust. 1 pkt 1 |
| `jdg.vat.a88.r8` | `deduction_blocked_no_invoice` | Zakup bez faktury (paragon bez NIP) | Art. 88 ust. 1 pkt 2 |
| `jdg.vat.a88.r9` | `deduction_blocked_invoice_from_non_payer` | Faktura od podmiotu niezarejestrowanego jako czynny podatnik VAT | Art. 88 ust. 1 pkt 2 |
| `jdg.vat.a88.r10` | `deduction_blocked_purchase_from_private` | Zakup od osoby prywatnej (nie-podatnika VAT) | Art. 15 |
| `jdg.vat.a88.r11` | `deduction_blocked_acquired_services_exempt` | Zakup usług zwolnionych z VAT | Art. 86 ust. 2 |
| `jdg.vat.a88.r12` | `deduction_blocked_tax_free_internet` | Zakup usług i towarów z państw trzecich (bez rozliczenia importu) | Art. 17 |
| `jdg.vat.a88.r13` | `deduction_blocked_invoice_after_deadline` | Faktura otrzymana po upływie 3 miesięcy od końca miesiąca zakupu | Art. 86 ust. 11 |
| `jdg.vat.a88.r14` | `deduction_blocked_car_100pct_no_evidence` | Samochód używany mieszanie — 50% VAT (bez ewidencji przebiegu) | Art. 86a |
| `jdg.vat.a88.r15` | `deduction_blocked_car_100pct_with_evidence` | Samochód używany tylko firmowo (100% VAT) — wymagana ewidencja | Art. 86a |

#### Art. 86a VAT — Samochody osobowe (∼10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a86a.r1` | `car_vat_deduction_50pct_no_evidence` | Brak ewidencji przebiegu pojazdu → 50% VAT | 50% odliczenia VAT |
| `jdg.vat.a86a.r2` | `car_vat_deduction_100pct_evidence` | Ewidencja przebiegu → 100% VAT (tylko firmowe km) | 100% odliczenia VAT |
| `jdg.vat.a86a.r3` | `car_vat_deduction_100pct_exclusively` | Pojazd używany wyłącznie firmowo (bez użytku prywatnego) | 100% VAT (bez ewidencji) |
| `jdg.vat.a86a.r4` | `car_vat_100pct_exclusively_test` | Trzy warunki: 1) brak prywatnego użytku w umowie, 2) brak możliwości użycia prywatnego, 3) konstrukcja uniemożliwia użycie prywatne | Test wyłączności |
| `jdg.vat.a86a.r5` | `car_vat_100pct_taxi_delivery` | Taxi, przewóz osób, dostawa — mogą odliczać 100% VAT | Wyjątek branżowy |
| `jdg.vat.a86a.r6` | `car_vat_leasing_50pct` | Leasing operacyjny auta mieszanego — 50% VAT od raty | 50% odliczenia |
| `jdg.vat.a86a.r7` | `car_vat_fuel_50pct` | Paliwo do auta mieszanego — 50% VAT | 50% odliczenia VAT od paliwa |
| `jdg.vat.a86a.r8` | `car_vat_mileage_log_mandatory_fields` | Ewidencja przebiegu: data, trasa, cel, liczba km, podpis | Wymagane pola |
| `jdg.vat.a86a.r9` | `car_vat_mileage_log_retention` | Ewidencję przebiegu przechowuje się 5 lat | Okres przechowywania |
| `jdg.vat.a86a.r10` | `car_vat_mileage_log_monthly_submission` | Ewidencja składana do US na żądanie | Obowiązek |

#### Art. 89a-89b VAT — Złe długi (∼10 reguł)

| ID | Nazwa reguły | Strona | Warunek | Rezultat |
|:--:|-------------|:------:|---------|----------|
| `jdg.vat.a89a.r1` | `bad_debt_creditor_150_days` | Wierzyciel | Nieotrzymanie zapłaty po 150 dniach od terminu | Możliwość korekty VAT in minus |
| `jdg.vat.a89a.r2` | `bad_debt_creditor_debtor_not_restructuring` | Wierzyciel | Dłużnik NIE jest w restrukturyzacji/upadłości | Warunek konieczny |
| `jdg.vat.a89a.r3` | `bad_debt_creditor_notification_debtor` | Wierzyciel | Zawiadomienie dłużnika o zamiarze korekty | Obowiązek formalny |
| `jdg.vat.a89a.r4` | `bad_debt_creditor_correction_period` | Wierzyciel | Korekta w deklaracji za okres, w którym upłynął 151. dzień | Termin korekty |
| `jdg.vat.a89a.r5` | `bad_debt_creditor_reversal_on_payment` | Wierzyciel | Dłużnik zapłacił po korekcie → przywrócenie VAT należnego | Odwrócenie korekty |
| `jdg.vat.a89b.r1` | `bad_debt_debtor_90_days_mandatory` | Dłużnik (JDG) | Niezapłacenie faktury po 90 dniach od terminu | OBOWIĄZKOWA korekta VAT in minus |
| `jdg.vat.a89b.r2` | `bad_debt_debtor_amount_to_return` | Dłużnik (JDG) | Kwota VAT do zwrotu = VAT odliczony od nieopłaconej faktury | Obliczenie kwoty |
| `jdg.vat.a89b.r3` | `bad_debt_debtor_deadline_of_correction` | Dłużnik (JDG) | Korekta w deklaracji za okres, w którym upłynął 91. dzień | Termin |
| `jdg.vat.a89b.r4` | `bad_debt_debtor_30pct_sanction` | Dłużnik (JDG) | Brak korekty → sankcja 30% kwoty VAT podlegającej zwrotowi | Sankcja |
| `jdg.vat.a89b.r5` | `bad_debt_debtor_reversal_on_payment` | Dłużnik (JDG) | Zapłata po korekcie → przywrócenie odliczenia VAT | Odwrócenie |

### 1.7 Art. 99, 103, 106a-106n: Deklaracje, faktury, KSeF (∼50 reguł)

#### Art. 99 VAT — Deklaracje VAT (∼10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a99.r1` | `vat_declaration_monthly_obligation` | Czynny podatnik VAT (standardowy) | Obowiązek składania JPK_V7M miesięcznie |
| `jdg.vat.a99.r2` | `vat_declaration_quarterly_small` | Mały podatnik (obrót < 2M EUR) wybiera kwartał | Możliwość JPK_V7K kwartalnie |
| `jdg.vat.a99.r3` | `vat_declaration_quarterly_deadline_25` | JPK_V7K — termin 25. dnia miesiąca po kwartale | Termin 25. dzień |
| `jdg.vat.a99.r4` | `vat_declaration_monthly_deadline_25` | JPK_V7M — termin 25. dnia następnego miesiąca | Termin 25. dzień |
| `jdg.vat.a99.r5` | `vat_declaration_zero_if_no_sales` | Brak sprzedaży w okresie → deklaracja zerowa | Obowiązek deklaracji zerowej |
| `jdg.vat.a99.r6` | `vat_declaration_overdue_interest` | Po terminie → odsetki za zwłokę | Sankcja finansowa |
| `jdg.vat.a99.r7` | `vat_declaration_correction_on_own` | Korekta deklaracji VAT na własne żądanie | Możliwość korekty |
| `jdg.vat.a99.r8` | `vat_declaration_correction_deadline` | Korekta w ciągu 5 lat od końca roku podatkowego | Termin korekty |
| `jdg.vat.a99.r9` | `vat_declaration_correction_after_audit` | Korekta po kontroli — tylko za zgodą naczelnika US | Ograniczenie |
| `jdg.vat.a99.r10` | `vat_declaration_vat_payable_payment` | VAT do zapłaty w terminie deklaracji (do 25. dnia) | Płatność |

#### Art. 106a-106e VAT — Faktury (∼15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a106e.r1` | `invoice_mandatory_fields_nip` | Faktura musi zawierać NIP sprzedawcy i nabywcy | Pole obowiązkowe |
| `jdg.vat.a106e.r2` | `invoice_mandatory_fields_date` | Data wystawienia i data sprzedaży (dostawy/wykonania) | Pole obowiązkowe |
| `jdg.vat.a106e.r3` | `invoice_mandatory_fields_numbers` | Numer faktury (unikalny w roku/okresie) | Pole obowiązkowe |
| `jdg.vat.a106e.r4` | `invoice_mandatory_fields_party_details` | Nazwa i adres sprzedawcy i nabywcy | Pole obowiązkowe |
| `jdg.vat.a106e.r5` | `invoice_mandatory_fields_item_description` | Nazwa towaru/usługi, ilość, cena jednostkowa | Pole obowiązkowe |
| `jdg.vat.a106e.r6` | `invoice_mandatory_fields_vat_rate` | Stawka VAT i kwota VAT | Pole obowiązkowe |
| `jdg.vat.a106e.r7` | `invoice_mandatory_fields_reverse_charge` | Adnotacja: "odwrotne obciążenie" gdy procedura | Pole warunkowe |
| `jdg.vat.a106e.r8` | `invoice_mandatory_fields_split_payment` | Adnotacja: "mechanizm podzielonej płatności" | Pole warunkowe |
| `jdg.vat.a106e.r9` | `invoice_mandatory_fields_margin` | Adnotacja: "procedura marży — towary używane" | Pole warunkowe |
| `jdg.vat.a106e.r10` | `invoice_simplified_receipt_450_pln` | Paragon z NIP do 450 PLN brutto = faktura uproszczona | Równoważność |
| `jdg.vat.a106e.r11` | `invoice_simplified_receipt_450_over` | Paragon bez NIP lub >450 PLN = NIE faktura | Brak odliczenia VAT |
| `jdg.vat.a106e.r12` | `invoice_issue_deadline_15_days` | Fakturę wystawia się do 15. dnia miesiąca po dostawie | Termin standardowy |
| `jdg.vat.a106e.r13` | `invoice_issue_deadline_b2c_receipt` | Paragon B2C — w momencie sprzedaży (kasa fiskalna) | Termin natychmiastowy |
| `jdg.vat.a106e.r14` | `invoice_advance_invoice` | Faktura zaliczkowa — przy otrzymaniu zaliczki | Obowiązek |
| `jdg.vat.a106e.r15` | `invoice_correction_approval` | Faktura korygująca — wymagana zgoda nabywcy lub notyfikacja | Warunek |

#### Art. 106f-106k VAT — Faktury korygujące (∼10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a106j.r1` | `correction_invoice_minus_conditions` | Korekta in minus: błąd w cenie, stawce, rabat po sprzedaży, zwrot towarów | Warunki korekty |
| `jdg.vat.a106j.r2` | `correction_invoice_plus_conditions` | Korekta in plus: dodatkowa należność po sprzedaży (błąd w cenie) | Warunki korekty |
| `jdg.vat.a106j.r3` | `correction_buyer_agreement_minus` | Korekta in minus — wymagane potwierdzenie odbioru faktury korygującej przez nabywcę | Warunek |
| `jdg.vat.a106j.r4` | `correction_buyer_agreement_exceptions` | Wyjątki od zgody: WDT, eksport, dostawa wewnątrzwspólnotowa | Wyjątek |
| `jdg.vat.a106j.r5` | `correction_no_agreement_within_6_months` | Brak potwierdzenia w 6 mies. → korekta bez potwierdzenia, ale US może zakwestionować | Konsekwencja |
| `jdg.vat.a106j.r6` | `correction_mandatory_reason` | Faktura korygująca: przyczyna korekty (opis błędu) | Pole obowiązkowe |
| `jdg.vat.a106j.r7` | `correction_mandatory_reference` | Faktura korygująca: numer faktury pierwotnej | Pole obowiązkowe |
| `jdg.vat.a106j.r8` | `correction_storno_full_cancel` | Storno całkowite — anulowanie faktury pierwotnej i wystawienie nowej | Anulowanie |
| `jdg.vat.a106j.r9` | `correction_storno_black_adjustment` | Nota korygująca (różnica) — korekta częściowa bez anulowania | Korekta częściowa |
| `jdg.vat.a106j.r10` | `correction_vat_rate_change` | Zmiana stawki VAT → korekta in plus/minus w zależności od kierunku zmiany | Stawka |

#### Art. 106na-106nq VAT — KSeF (∼15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.vat.a106na.r1` | `ksef_obligation_from_2026_02_01` | Faktury sprzedaży od 1 lutego 2026 r. przez KSeF | Obowiązek |
| `jdg.vat.a106na.r2` | `ksef_obligation_vat_active_only` | Obowiązek dotyczy tylko czynnych podatników VAT | Zakres podmiotowy |
| `jdg.vat.a106na.r3` | `ksef_obligation_vat_exempt_exception` | Podatnicy zwolnieni z VAT — wyłączeni z KSeF | Wyjątek |
| `jdg.vat.a106na.r4` | `ksef_obligation_b2c_exception` | Faktury B2C (paragony, rachunki) — wyłączone z KSeF | Wyjątek |
| `jdg.vat.a106na.r5` | `ksef_structured_invoice_mandatory_format` | Faktura ustrukturyzowana wg schemy XSD | Format obowiązkowy |
| `jdg.vat.a106na.r6` | `ksef_self_invoicing_by_buyer` | Faktura wystawiona przez nabywcę (self-billing) — również przez KSeF | Obowiązek |
| `jdg.vat.a106na.r7` | `ksef_invoice_deadline_real_time` | Faktura w KSeF — w momencie sprzedaży (lub do 24h z opóźnieniem) | Termin |
| `jdg.vat.a106ne.r1` | `ksef_offline_7_days_recovery` | Awaria KSeF — 7 dni na wysłanie faktur po przywróceniu | Tryb awaryjny |
| `jdg.vat.a106ne.r2` | `ksef_offline_status_detection` | Status systemu KSeF: ONLINE / OFFLINE | Detekcja |
| `jdg.vat.a106ne.r3` | `ksef_offline_invoice_numbering` | Numery faktur w trybie offline (sufiks /OFFLINE) | Konwencja |
| `jdg.vat.a106ng.r1` | `ksef_upo_confirmation_mandatory` | UPO (Urzędowe Poświadczenie Odbioru) — obowiązkowe dla każdej faktury | Potwierdzenie |
| `jdg.vat.a106ng.r2` | `ksef_upo_storage_5_years` | UPO przechowuje się przez 5 lat | Retencja |
| `jdg.vat.a106nh.r1` | `ksef_qr_code_mandatory` | Kod QR na fakturze wizualnej — do weryfikacji autentyczności | Obowiązek |
| `jdg.vat.a106nh.r2` | `ksef_qr_code_absence_risk` | Brak kodu QR → ryzyko zakwestionowania odliczenia VAT | Ryzyko |
| `jdg.vat.a106nq.r1` | `ksef_sanction_100pct_additional` | Sankcja za KSeF: dodatkowe zobowiązanie 100% VAT (maks. 500k PLN) | Sankcja |

## CZĘŚĆ II: USTAWA O PIT (520 REGUŁ)

### 2.1 Art. 10-14: Źródła przychodów i definicje (∼50 reguł)

#### Art. 10 PIT — Źródła przychodów (∼10 reguł)

| ID | Nazwa reguły | Źródło | Warunek |
|:--:|-------------|--------|---------|
| `jdg.pit.a10.r1` | `income_source_business_jdg` | Działalność gospodarcza (JDG) | Art. 10 ust. 1 pkt 3 |
| `jdg.pit.a10.r2` | `income_source_employment` | Umowa o pracę (jeśli JDG również na etacie) | Art. 10 ust. 1 pkt 1 |
| `jdg.pit.a10.r3` | `income_source_civil_contracts` | Umowy zlecenia, o dzieło (poza JDG) | Art. 10 ust. 1 pkt 2 |
| `jdg.pit.a10.r4` | `income_source_rental_sublease` | Najem, dzierżawa (jako przychód z dział. gosp. lub odrębne źródło) | Art. 10 ust. 1 pkt 6 |
| `jdg.pit.a10.r5` | `income_source_capital_gains` | Zbycie akcji, udziałów, tytułów uczestnictwa | Art. 10 ust. 1 pkt 7 |
| `jdg.pit.a10.r6` | `income_source_real_estate_sale` | Sprzedaż nieruchomości przed upływem 5 lat | Art. 10 ust. 1 pkt 8 |
| `jdg.pit.a10.r7` | `income_source_intellectual_property` | Zbycie praw autorskich, patentów, znaków towarowych | Art. 10 ust. 1 pkt 7 |
| `jdg.pit.a10.r8` | `income_source_retirement_pension` | Emerytura, renta (gdy JDG jest emerytem) | Art. 10 ust. 1 pkt 1 |
| `jdg.pit.a10.r9` | `income_source_other_sources` | Inne źródła: alimenty, stypendia, wygrane, odszkodowania | Art. 10 ust. 1 pkt 9 |
| `jdg.pit.a10.r10` | `income_source_separate_categories` | Każde źródło przychodów opodatkowane jest odrębnie | Zasada odrębności |

#### Art. 14 PIT — Przychody z działalności gospodarczej (∼20 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a14.r1` | `revenue_definition_jdg` | Kwoty należne, choćby nie zostały faktycznie otrzymane (memoriał) | Definicja przychodu |
| `jdg.pit.a14.r2` | `revenue_cash_method_pkpir` | Dla JDG z PKPiR: przychód w dacie wystawienia faktury lub nie później niż 25. dnia miesiąca od dostawy | Metoda memoriałowa uproszczona |
| `jdg.pit.a14.r3` | `revenue_direct_cash_method` | JDG może wybrać metodę kasową (przychód w dacie zapłaty) | Metoda kasowa (opcja) |
| `jdg.pit.a14.r4` | `revenue_exclusions_definition` | Nie wszystkie wpływy są przychodem (Art. 14 ust. 3) | Lista wyłączeń |
| `jdg.pit.a14.r5` | `revenue_exclusion_vat_refund` | Zwrot VAT (nadwyżka, nadpłata) — NIE stanowi przychodu | Wyłączenie |
| `jdg.pit.a14.r6` | `revenue_exclusion_zus_overpayment` | Zwrot nadpłaconych składek ZUS (jeśli wcześniej nie były KUP) | Wyłączenie |
| `jdg.pit.a14.r7` | `revenue_exclusion_loan_repayment` | Spłata pożyczki/kredytu — NIE stanowi przychodu | Wyłączenie |
| `jdg.pit.a14.r8` | `revenue_exclusion_damages` | Odszkodowania za składniki majątku — NIE stanowią przychodu | Wyłączenie |
| `jdg.pit.a14.r9` | `revenue_exclusion_compensation_loss_profits` | Odszkodowanie za utracone przychody — stanowi przychód | Przychód |
| `jdg.pit.a14.r10` | `revenue_exclusion_mandate_return` | Zwrot wydatków poniesionych w imieniu mandanta — NIE przychód | Wyłączenie |
| `jdg.pit.a14.r11` | `revenue_exclusion_deposit` | Otrzymana kaucja, depozyt, gwarancja — NIE przychód | Wyłączenie |
| `jdg.pit.a14.r12` | `revenue_exclusion_donation_goods` | Nieodpłatne otrzymanie towarów — NIE przychód do czasu sprzedaży | Wyłączenie |
| `jdg.pit.a14.r13` | `revenue_in_kind_market_value` | Przychód w naturze (barter) — wartość rynkowa | Wycena |
| `jdg.pit.a14.r14` | `revenue_foreign_currency_conversion` | Przychód w walucie obcej — kurs NBP z dnia poprzedzającego dzień uzyskania | Kurs |
| `jdg.pit.a14.r15` | `revenue_foreign_currency_payment_conversion` | Wpływ waluty na rachunek walutowy — kurs z dnia wpływu | Kurs |
| `jdg.pit.a14.r16` | `revenue_discounts_abatements` | Rabaty, upusty, bonifikaty — pomniejszają przychód | Korekta |
| `jdg.pit.a14.r17` | `revenue_bad_debt_write_off` | Nieściągalne należności — NIE pomniejszają przychodu (wyjątek: strata) | Skutek |
| `jdg.pit.a14.r18` | `revenue_subcontractor_division` | Przychód pomniejszony o koszt podwykonawcy (w przypadku usług budowlanych) | Specjalna zasada |
| `jdg.pit.a14.r19` | `revenue_taxable_gratis_benefits` | Nieodpłatne świadczenia (użycie firmowego auta, telefonu na cele prywatne) | Przychód |
| `jdg.pit.a14.r20` | `revenue_taxable_benefit_private_car` | Wartość prywatnego użytku samochodu firmowego JDG — miesięcznie 250 PLN | Przychód ryczałtowy |

#### Art. 14 ust. 2c-2e PIT — Różnice kursowe (∼10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a14c.r1` | `fx_difference_realized_revenue` | Kurs z dnia zapłaty > kurs z dnia faktury (przychód) | Dodatnia różnica kursowa = przychód |
| `jdg.pit.a14c.r2` | `fx_difference_realized_cost` | Kurs z dnia zapłaty < kurs z dnia faktury (koszt) | Ujemna różnica kursowa = KUP |
| `jdg.pit.a14c.r3` | `fx_difference_realized_cost_income` | Koszt (PURCHASE): kurs > kurs faktury → ujemna FX = KUP | FX od kosztów |
| `jdg.pit.a14c.r4` | `fx_difference_realized_cost_expense` | Koszt (PURCHASE): kurs < kurs faktury → dodatnia FX = przychód | FX od kosztów |
| `jdg.pit.a14c.r5` | `fx_difference_method_podatkowa` | Metoda podatkowa: kurs faktycznie zastosowany lub średni NBP | Wybór metody |
| `jdg.pit.a14c.r6` | `fx_difference_method_kursowa` | Metoda kursowa (Art. 24c PIT): wycena na koniec okresu | Metoda alternatywna |
| `jdg.pit.a14c.r7` | `fx_difference_unrealized_balance_sheet` | Niezrealizowane różnice kursowe na dzień bilansowy (wycena sald walutowych) | Wycena bilansowa |
| `jdg.pit.a14c.r8` | `fx_difference_balance_sheet_rate` | Kurs NBP z ostatniego dnia roboczego poprzedzającego dzień bilansowy | Kurs bilansowy |
| `jdg.pit.a14c.r9` | `fx_difference_payment_different_currencies` | Zapłata w innej walucie niż faktura — wycena wg kursu z dnia zapłaty | Różne waluty |
| `jdg.pit.a14c.r10` | `fx_difference_bank_account_conversion` | Przeliczenie waluty z rachunku walutowego na PLN przy wypłacie | Realizacja FX |

### 2.2 Art. 22-23: Koszty uzyskania przychodu (∼80 reguł)

#### Art. 22 PIT — Definicja ogólna KUP (∼15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a22.r1` | `kup_general_definition` | Koszty poniesione w celu osiągnięcia przychodu lub zachowania/zabezpieczenia źródła przychodów | Definicja ogólna |
| `jdg.pit.a22.r2` | `kup_all_expenses_business` | Wszystkie koszty związane z prowadzeniem JDG (przy spełnieniu Art. 22 ust. 1) | Kwalifikacja |
| `jdg.pit.a22.r3` | `kup_indirect_timing_invoice` | Koszty pośrednie (czynsz, media, księgowość) — potrącalne w dacie poniesienia | Data faktury |
| `jdg.pit.a22.r4` | `kup_direct_timing_revenue_year` | Koszty bezpośrednie (zakup towarów, materiałów) — potrącalne w roku osiągnięcia odpowiadającego przychodu | Rok przychodu |
| `jdg.pit.a22.r5` | `kup_direct_not_yet_earned` | Koszty bezpośrednie poniesione przed osiągnięciem przychodu — potrącalne w roku poniesienia | Wyjątek timing |
| `jdg.pit.a22.r6` | `kup_zus_social_entrepreneur` | Składki ZUS społeczne opłacone przez JDG — KUP w dacie zapłaty | Data zapłaty |
| `jdg.pit.a22.r7` | `kup_zus_social_unpaid_block` | Niezapłacone składki ZUS — NIE stanowią KUP | Blokada |
| `jdg.pit.a22.r8` | `kup_unpaid_reversal` | Faktura nieopłacona po 90 dniach — OBOWIĄZKOWE wyłączenie z KUP | Koszty bezpośrednie |
| `jdg.pit.a22.r9` | `kup_unpaid_reversal_indirect` | Koszty pośrednie nieopłacone — NIE wyłącza się (kasowość nie dotyczy) | Brak wyłączenia |
| `jdg.pit.a22.r10` | `kup_unpaid_reversal_on_payment` | Zapłata po wyłączeniu → przywrócenie KUP w dacie zapłaty | Odwrócenie |
| `jdg.pit.a22.r11` | `kup_provisions_reserves` | Rezerwy, odpisy, bierne rozliczenia międzyokresowe — NIE są KUP (chyba że ustawa stanowi inaczej) | Wyłączenie |
| `jdg.pit.a22.r12` | `kup_vat_not_deductible_as_cost` | VAT naliczony niepodlegający odliczeniu — może być KUP (gdy związany z działalnością) | KUP warunkowy |
| `jdg.pit.a22.r13` | `kup_cost_of_purchase_of_goods` | Wartość towarów handlowych i materiałów w cenie zakupu | Wycena kosztów |
| `jdg.pit.a22.r14` | `kup_cost_of_manufacturing` | Koszt wytworzenia produktu (materiały + robocizna + koszty wydziałowe) | Wycena kosztów |
| `jdg.pit.a22.r15` | `kup_loss_of_inventory` | Straty w towarach/materialach (udokumentowane protokołem) | KUP |

#### Art. 23 PIT — Wyłączenia z KUP (∼30 reguł)

| ID | Nazwa reguły | Wydatek wyłączony | Podstawa |
|:--:|-------------|-------------------|:--------:|
| `jdg.pit.a23.r1` | `kup_exclusion_own_labor` | Wartość własnej pracy przedsiębiorcy JDG | Art. 23 ust. 1 pkt 10 |
| `jdg.pit.a23.r2` | `kup_exclusion_spouse_minor_children` | Praca małżonka i małoletnich dzieci JDG (bez umowy) | Art. 23 ust. 1 pkt 10 |
| `jdg.pit.a23.r3` | `kup_exclusion_personal_living` | Wydatki na cele osobiste, mieszkaniowe, wyżywienie przedsiębiorcy | Art. 23 ust. 1 pkt 10 |
| `jdg.pit.a23.r4` | `kup_exclusion_representation` | Reprezentacja, szczególnie gastronomiczna, rozrywkowa | Art. 23 ust. 1 pkt 23 |
| `jdg.pit.a23.r5` | `kup_exclusion_clothing_not_bhp` | Odzież (chyba że robocza/BHP zgodnie z przepisami) | Art. 23 ust. 1 pkt 23 |
| `jdg.pit.a23.r6` | `kup_exclusion_final_mandate` | Kary umowne, odszkodowania z tytułu wad dostaw | Art. 23 ust. 1 pkt 19 |
| `jdg.pit.a23.r7` | `kup_exclusion_final_exception_delivery_defects` | Wyjątek: kary otrzymane od dostawcy = przychód (nie KUP) | Art. 23 ust. 1 pkt 19 |
| `jdg.pit.a23.r8` | `kup_exclusion_debts_forgiven` | Umorzone zobowiązania (chyba że w restrukturyzacji) | Art. 23 ust. 1 pkt 20 |
| `jdg.pit.a23.r9` | `kup_exclusion_debts_forgiven_restructuring` | Umorzenie w restrukturyzacji → zwolnione z PIT, ale NIE KUP | Wyjątek |
| `jdg.pit.a23.r10` | `kup_exclusion_donations_voluntary_associations` | Składki w organizacjach dobrowolnych (nieobowiązkowe izby) | Art. 23 ust. 1 pkt 30 |
| `jdg.pit.a23.r11` | `kup_exclusion_mandatory_chamber_fees` | Obowiązkowe składki izb zawodowych (lekarska, adwokacka) — są KUP | Wyjątek (są KUP) |
| `jdg.pit.a23.r12` | `kup_exclusion_car_over_150k` | Wartość auta osobowego >150 000 PLN (ograniczony KUP) | Art. 23 ust. 1 pkt 47a |
| `jdg.pit.a23.r13` | `kup_exclusion_car_lease_over_150k` | Leasing operacyjny auta >150k PLN — część raty NKUP | Art. 23 ust. 1 pkt 47a |
| `jdg.pit.a23.r14` | `kup_exclusion_car_insurance_proportional` | AC auta >150k — proporcjonalne wyłączenie (150k/wartość) | Art. 23 ust. 1 pkt 47a |
| `jdg.pit.a23.r15` | `kup_exclusion_car_electric_225k` | Samochód elektryczny (bez dotacji) — limit 225 000 PLN | Wyjątek od pkt 47a |
| `jdg.pit.a23.r16` | `kup_exclusion_car_electric_with_subsidy` | Samochód elektryczny z dotacją — limit wraca do 150 000 PLN | Limit 150k |
| `jdg.pit.a23.r17` | `kup_exclusion_mileage_log_absence` | Samochód bez ewidencji przebiegu — 75% KUP zamiast 100% | Art. 23 ust. 1 pkt 46 |
| `jdg.pit.a23.r18` | `kup_exclusion_private_use_mixed` | Wydatki mieszane (prywatne+firmowe) — tylko część firmowa KUP | Art. 23 ust. 1 pkt 46 |
| `jdg.pit.a23.r19` | `kup_exclusion_personal_accident_insurance` | Ubezpieczenie na życie, od następstw nieszczęśliwych wypadków (prywatne) | Art. 23 ust. 1 pkt 42 |
| `jdg.pit.a23.r20` | `kup_exclusion_employee_insurance_except` | Ubezpieczenia pracowników (grupowe) — KUP (wyjątek od pkt 42) | Wyjątek |
| `jdg.pit.a23.r21` | `kup_exclusion_tax_penalties` | Kary podatkowe, grzywny, mandaty | Art. 23 ust. 1 pkt 19 |
| `jdg.pit.a23.r22` | `kup_exclusion_zus_unpaid_arrears` | Niezapłacone odsetki od składek ZUS (odsetki) | Art. 23 ust. 1 pkt 19 |
| `jdg.pit.a23.r23` | `kup_exclusion_capital_investment` | Wydatki na nabycie środków trwałych, WNiP (amortyzacja zamiast KUP) | Art. 23 ust. 1 pkt 1 |
| `jdg.pit.a23.r24` | `kup_exclusion_land_purchase` | Zakup gruntu (nie podlega amortyzacji) | Art. 23 ust. 1 pkt 1 |
| `jdg.pit.a23.r25` | `kup_exclusion_perpetual_usufruct` | Opłata za użytkowanie wieczyste gruntu (raz w roku) | Art. 23 ust. 1 pkt 1 |
| `jdg.pit.a23.r26` | `kup_exclusion_self_education` | Koszty własnego kształcenia JDG — NKUP (chyba że związane z działalnością) | Art. 23 ust. 1 pkt 10 |
| `jdg.pit.a23.r27` | `kup_exclusion_self_education_related` | Koszty własnego kształcenia JDG związane z wykonywaną działalnością — są KUP | Wyjątek |
| `jdg.pit.a23.r28` | `kup_exclusion_tax_costs` | Sam podatek dochodowy (PIT, CIT) — NKUP | Art. 23 ust. 1 pkt 4 |
| `jdg.pit.a23.r29` | `kup_exclusion_fines_state` | Grzywny, kary pieniężne nakładane przez państwo (sądy, US, ZUS, PIP) | Art. 23 ust. 1 pkt 5 |
| `jdg.pit.a23.r30` | `kup_exclusion_lost_unreported` | Straty nieudokumentowane (brak protokołu likwidacji) | Art. 23 ust. 1 pkt 5 |

### 2.3 Art. 24: Dochód i strata (∼15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a24.r1` | `income_definition_revenue_minus_costs` | Dochód = przychód - koszty uzyskania przychodu | Definicja |
| `jdg.pit.a24.r2` | `income_negative_loss` | Dochód ujemny = strata podatkowa | Strata |
| `jdg.pit.a24.r3` | `income_loss_carry_forward_5_years` | Strata rozliczana w ciągu 5 kolejnych lat | Rozliczenie straty |
| `jdg.pit.a24.r4` | `income_loss_max_50pct_annually` | W jednym roku max 50% straty (ograniczenie) | Limit roczny |
| `jdg.pit.a24.r5` | `income_loss_one_time_5m` | Opcja: jednorazowe odliczenie straty do 5 000 000 PLN | Alternatywa |
| `jdg.pit.a24.r6` | `income_loss_only_scale_linear` | Rozliczenie straty TYLKO dla skali i podatku liniowego | Zakres |
| `jdg.pit.a24.r7` | `income_loss_not_available_lump_sum` | Ryczałt i karta podatkowa — NIE rozliczają strat | Wyłączenie |
| `jdg.pit.a24.r8` | `income_inventory_adjustment` | Różnica remanentu końcowego i początkowego koryguje dochód | Korekta remanentem |
| `jdg.pit.a24.r9` | `income_inventory_positive_increase` | Remanent końcowy > początkowy → zwiększa dochód | Zwiększenie dochodu |
| `jdg.pit.a24.r10` | `income_inventory_negative_decrease` | Remanent końcowy < początkowy → zmniejsza dochód (zwiększa stratę) | Zmniejszenie dochodu |
| `jdg.pit.a24.r11` | `income_balance_sheet_comparison` | Dochód JDG na PKPiR = różnica przychodów i wydatków + różnica remanentów | Obliczenie |
| `jdg.pit.a24.r12` | `income_source_separation` | Dochód z działalności gospodarczej nie łączy się z innymi źródłami (chyba że wspólne rozliczenie) | Odrębność |
| `jdg.pit.a24.r13` | `income_source_aggregation_scale` | Dla skali podatkowej: dochód z działalności + dochód z innych źródeł = łączny dochód | Łączenie |
| `jdg.pit.a24.r14` | `income_averaging_not_available_jdg` | Przeciętowanie dochodów (Art. 27 ust. 2) — dostępne tylko dla twórców i artystów | Ograniczenie |
| `jdg.pit.a24.r15` | `income_tax_free_amount_scale_only` | Kwota wolna od podatku (30 000 PLN) — dostępna TYLKO przy skali podatkowej | Kwota wolna |

### 2.4 Art. 26-26h: Ulgi podatkowe (∼80 reguł)

#### Art. 26 PIT — Ulgi odliczane od dochodu (∼25 reguł)

| ID | Nazwa reguły | Ulga | Warunek | Limit |
|:--:|-------------|------|---------|:-----:|
| `jdg.pit.a26.r1` | `relief_zus_social_contributions` | Składki ZUS społeczne (przedsiębiorcy i pracowników) | Zapłacone w roku podatkowym | Brak limitu |
| `jdg.pit.a26.r2` | `relief_rehabilitation` | Ulga rehabilitacyjna (wydatki na cele rehabilitacyjne) | Orzeczenie o niepełnosprawności lub wiek >75 lat | Limit 2 280 PLN |
| `jdg.pit.a26.r3` | `relief_rehabilitation_car` | Wydatki na przystosowanie samochodu do niepełnosprawności | Wymagane orzeczenie | Limit rzeczywisty |
| `jdg.pit.a26.r4` | `relief_rehabilitation_home` | Przebudowa domu/mieszkania dla osoby niepełnosprawnej | Wymagane orzeczenie | Limit rzeczywisty |
| `jdg.pit.a26.r5` | `relief_rehabilitation_equipment` | Zakup sprzętu rehabilitacyjnego, leki (ponad 100 PLN/mies.) | Wymagane orzeczenie | Nadwyżka >100 PLN/m. |
| `jdg.pit.a26.r6` | `relief_donation_opp_6pct` | Darowizny na OPP, organizacje pożytku publicznego | Potwierdzenie przelewu | Max 6% dochodu |
| `jdg.pit.a26.r7` | `relief_donation_blood` | Krwiodawstwo — ekwiwalent 130 PLN za litr | Zaświadczenie RCKiK | Brak % limitu |
| `jdg.pit.a26.r8` | `relief_donation_church` | Darowizny na cele kultu religijnego (kościoły, związki wyznaniowe) | Potwierdzenie | Max 6% dochodu |
| `jdg.pit.a26.r9` | `relief_donation_ngo_public_benefit` | Darowizny na cele innych organizacji (nie-OPP) z ustawy o działalności pożytku publicznego | Potwierdzenie | Max 6% dochodu |
| `jdg.pit.a26.r10` | `relief_donation_on_bank_transfer` | Darowizny — tylko przelewem (gotówka NIE uprawnia do odliczenia) | Warunek formy |
| `jdg.pit.a26.r11` | `relief_internet` | Ulga internetowa — wydatki z tytułu użytkowania internetu | Faktura + 2 lata max | 760 PLN/rok |
| `jdg.pit.a26.r12` | `relief_internet_years_limit` | Ulga internetowa przysługuje przez 2 kolejne lata | Limit lat | 2 lata |
| `jdg.pit.a26.r13` | `relief_internet_first_time` | Ulga dla podatników, którzy po raz pierwszy korzystają z internetu | Warunek |
| `jdg.pit.a26.r14` | `relief_joint_allowances_cap` | Suma ulg odliczanych od dochodu (Art. 26) nie może przekroczyć dochodu | Ograniczenie łączne |
| `jdg.pit.a26.r15` | `relief_joint_exceeded_carry` | Nadwyżka ulg ponad dochód przepada (NIE przechodzi na następny rok) | Przepadnięcie |
| `jdg.pit.a26.r16` | `relief_donation_ukraine` | Darowizny na cele pomocy Ukrainie (2022-2024 specjalnie) — odliczenie do 100% dochodu | Specjalna | Do 100% dochodu |
| `jdg.pit.a26.r17` | `relief_donation_covid` | Darowizny na cele przeciwdziałania COVID-19 | Specjalna (tymczasowa) | Max 6% dochodu |
| `jdg.pit.a26.r18` | `relief_donation_opp_verification_annual` | Weryfikacja statusu OPP (czy organizacja jest OPP w danym roku) | Warunek |
| `jdg.pit.a26.r19` | `relief_donation_double_check` | Jedna darowizna nie może być odliczona na dwóch różnych podstawach | Wykluczenie |
| `jdg.pit.a26.r20` | `relief_rehabilitation_housing_rent` | Wydatki na wynajem mieszkania dla osoby niepełnosprawnej | Orzeczenie + związek z niepełnosprawnością | Limit rzeczywisty |
| `jdg.pit.a26.r21` | `relief_rehabilitation_guide_dog` | Utrzymanie psa asystującego osoby niepełnosprawnej | Orzeczenie + dokument | Limit rzeczywisty |
| `jdg.pit.a26.r22` | `relief_rehabilitation_purchase_of_drugs` | Leki przepisane przez lekarza (ponad 100 PLN miesięcznie) | Recepty + faktury | Nadwyżka >100 PLN |
| `jdg.pit.a26.r23` | `relief_rehabilitation_hearing_aids` | Aparaty słuchowe, wózki inwalidzkie, protezy | Orzeczenie + faktura | Limit rzeczywisty |
| `jdg.pit.a26.r24` | `relief_rehabilitation_adaptation_of_vehicle` | Przystosowanie samochodu dla osoby niepełnosprawnej | Orzeczenie + faktura | Limit rzeczywisty |
| `jdg.pit.a26.r25` | `relief_aggregate_verification` | Weryfikacja sumy ulg z Art. 26 względem zeznania rocznego (PIT-36/PIT-36L) | Koordynacja |

#### Art. 26e PIT — Ulga B+R (∼15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a26e.r1` | `rd_status_verification` | Posiadanie statusu B+R (działalność B+R faktycznie prowadzona) | Warunek dostępu |
| `jdg.pit.a26e.r2` | `rd_qualifying_costs_salaries` | Koszty kwalifikowane: wynagrodzenia pracowników B+R | 100% kosztów |
| `jdg.pit.a26e.r3` | `rd_qualifying_costs_equipment` | Nabycie sprzętu specjalistycznego B+R (niezbędnego do badań) | Koszt kwalifikowany |
| `jdg.pit.a26e.r4` | `rd_qualifying_costs_materials` | Materiały i surowce zużyte w działalności B+R | Koszt kwalifikowany |
| `jdg.pit.a26e.r5` | `rd_qualifying_costs_expertise` | Ekspertyzy, opinie, usługi badawcze na potrzeby B+R | Koszt kwalifikowany |
| `jdg.pit.a26e.r6` | `rd_qualifying_costs_patents` | Koszty uzyskania i utrzymania patentu | Koszt kwalifikowany |
| `jdg.pit.a26e.r7` | `rd_qualifying_costs_collective_bargaining` | Odpisy na fundusz innowacyjności | Koszt kwalifikowany |
| `jdg.pit.a26e.r8` | `rd_deduction_base_100pct` | Odliczenie: 100% kosztów kwalifikowanych (standard) | 100% |
| `jdg.pit.a26e.r9` | `rd_deduction_centrum_200pct` | Odliczenie: 200% kosztów (dla Centrum Badawczo-Rozwojowego) | 200% |
| `jdg.pit.a26e.r10` | `rd_evidence_separate_required` | Wymóg wyodrębnionej ewidencji kosztów B+R | Warunek formalny |
| `jdg.pit.a26e.r11` | `rd_evidence_separate_check` | Sprawdzenie czy ewidencja B+R istnieje (PKPiR kolumna 16) | Weryfikacja |
| `jdg.pit.a26e.r12` | `rd_relief_capped_at_income` | Ulga B+R ograniczona do wysokości dochodu (nie może wygenerować straty) | Limit |
| `jdg.pit.a26e.r13` | `rd_relief_carry_forward_3_years` | Niewykorzystana część ulgi B+R przechodzi na 3 kolejne lata | Przeniesienie |
| `jdg.pit.a26e.r14` | `rd_relief_scale_linear_only` | Ulga B+R dostępna tylko dla skali podatkowej i liniowego | Zakres |
| `jdg.pit.a26e.r15` | `rd_relief_not_lump_sum_tax_card` | Ryczałt i karta — NIE mogą skorzystać z ulgi B+R | Wyłączenie |

#### Art. 30ca PIT — IP Box (∼10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a30ca.r1` | `ip_box_eligible_ip_detection` | Kwalifikowane prawo własności intelektualnej: patent, wzór użytkowy, autorskie prawo do programu komputerowego | Definicja IP |
| `jdg.pit.a30ca.r2` | `ip_box_rate_5pct` | Stawka 5% od dochodu z kwalifikowanego IP | 5% |
| `jdg.pit.a30ca.r3` | `ip_box_nexus_formula` | Dochód kwalifikowany = dochód z IP × wskaźnik Nexus | Formuła |
| `jdg.pit.a30ca.r4` | `ip_box_nexus_numerator_a` | Koszty własnej działalności B+R (czynnik a) | Składnik Nexus |
| `jdg.pit.a30ca.r5` | `ip_box_nexus_numerator_b` | Koszty nabycia od podmiotu niepowiązanego (czynnik b) | Składnik Nexus |
| `jdg.pit.a30ca.r6` | `ip_box_nexus_denominator_c` | Koszty nabycia od podmiotu powiązanego (czynnik c) | Składnik Nexus |
| `jdg.pit.a30ca.r7` | `ip_box_nexus_denominator_d` | Koszty nabycia know-how, patentów od podmiotu powiązanego (czynnik d) | Składnik Nexus |
| `jdg.pit.a30ca.r8` | `ip_box_separate_bookkeeping` | Obowiązek prowadzenia wyodrębnionej ewidencji dla IP Box | Warunek formalny |
| `jdg.pit.a30ca.r9` | `ip_box_annual_settlement` | Roczne rozliczenie IP Box w zeznaniu PIT-36/PIT-36L | Procedura |
| `jdg.pit.a30ca.r10` | `ip_box_scale_linear_only` | IP Box dostępny tylko dla skali i podatku liniowego | Zakres |

#### Art. 26eb-26ec, 26gb, 26h PIT — Pozostałe ulgi (∼15 reguł)

| ID | Nazwa reguły | Ulga | Warunek | Limit/Stawka |
|:--:|-------------|------|---------|:------------:|
| `jdg.pit.a26eb.r1` | `relief_prototype_30pct` | Ulga na prototyp: 30% kosztów produkcji próbnej i wprowadzenia do obrotu | Pierwsze wdrożenie | 30% kosztów |
| `jdg.pit.a26eb.r2` | `relief_prototype_qualifying_costs` | Koszty kwalifikowane: produkcja próbna, certyfikacja, badania | Katalog kosztów |
| `jdg.pit.a26eb.r3` | `relief_prototype_documentation` | Wymóg dokumentacji: opis prototypu, kosztorys, harmonogram | Warunek formalny |
| `jdg.pit.a26ec.r1` | `relief_expansion_100pct` | Ulga na ekspansję: 100% kosztów (targi zagraniczne, reklama za granicą) | Nowe rynki | 1 000 000 PLN |
| `jdg.pit.a26ec.r2` | `relief_expansion_qualifying_costs` | Koszty kwalifikowane: targi, misje, reklama, przystosowanie opakowań | Katalog kosztów |
| `jdg.pit.a26ec.r3` | `relief_expansion_market_definition` | Rynek zagraniczny — kraj inny niż Polska | Definicja |
| `jdg.pit.a26gb.r1` | `relief_robotization_50pct` | Ulga na robotyzację: 50% kosztów robotów przemysłowych | Zakup robotów | 50% kosztów |
| `jdg.pit.a26gb.r2` | `relief_robotization_qualifying` | Koszty kwalifikowane: robot, oprogramowanie, szkolenia, instalacja | Katalog |
| `jdg.pit.a26gb.r3` | `relief_robotization_evidence` | Wymóg ewidencji: robot musi być środkiem trwałym | Warunek |
| `jdg.pit.a26h.r1` | `relief_thermo_53k` | Ulga termomodernizacyjna: max 53 000 PLN odliczenia od dochodu | Budynek mieszkalny | 53 000 PLN |
| `jdg.pit.a26h.r2` | `relief_thermo_qualifying_works` | Roboty: ocieplenie, okna, drzwi, ogrzewanie, wentylacja, OZE | Katalog robót |
| `jdg.pit.a26h.r3` | `relief_thermo_owner_or_co_owner` | Ulga przysługuje właścicielowi/współwłaścicielowi budynku | Podmiot |
| `jdg.pit.a26h.r4` | `relief_thermo_certificate` | Wymóg audytu energetycznego przed robotami | Warunek formalny |
| `jdg.pit.a26h.r5` | `relief_thermo_joint_with_spouse` | Małżonkowie mogą odliczyć łączną kwotę 53 000 PLN | Wspólny limit |
| `jdg.pit.a26h.r6` | `relief_thermo_multiple_buildings` | Limit 53 000 PLN dotyczy wszystkich budynków (łącznie) | Globalny limit |

### 2.5 Art. 27 PIT — Skala podatkowa (12%/32%) (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a27.r1` | `tax_scale_detection` | Podatnik wybral skale podatkowa (PIT-36) | Stosuj skale 12%/32% |
| `jdg.pit.a27.r2` | `tax_scale_rate_12pct_up_to_120k` | Dochód do 120 000 PLN | 12% podatku |
| `jdg.pit.a27.r3` | `tax_scale_rate_32pct_over_120k` | Dochód > 120 000 PLN | 32% od nadwyzki |
| `jdg.pit.a27.r4` | `tax_scale_tax_free_30k` | Kwota wolna od podatku 30 000 PLN | Zwolnienie 12% z 30k = 3 600 PLN |
| `jdg.pit.a27.r5` | `tax_scale_tax_free_phase_out` | Dochód > 120k -> kwota wolna wygasa liniowo do 0 | Phasing out |
| `jdg.pit.a27.r6` | `tax_scale_tax_free_full_120k` | Dochód do 120k -> pelna kwota wolna 3 600 PLN | Pełne odliczenie |
| `jdg.pit.a27.r7` | `tax_scale_income_aggregation` | Laczny dochod z JDG + etat + inne zrodla | Podstawa skali |
| `jdg.pit.a27.r8` | `tax_scale_deductions_before_calc` | Odliczenia od dochodu (Art. 26) przed obliczeniem podatku | Kolejnosc |
| `jdg.pit.a27.r9` | `tax_scale_tax_credits_after` | Ulgi odliczane od podatku po obliczeniu | Kolejnosc |
| `jdg.pit.a27.r10` | `tax_scale_joint_settlement_spouse` | Wspolne rozliczenie z malzonkiem (limit 2x120k) | 2x kwota wolna |
| `jdg.pit.a27.r11` | `tax_scale_single_parent` | Rozliczenie jako osoba samotnie wychowujaca dzieci | Specjalne zasady |
| `jdg.pit.a27.r12` | `tax_scale_tax_calc_formula` | Podatek = (dochod * 0.12) - kwota_wolna, dla nadwyzki (dochod * 0.32) | Formula |
| `jdg.pit.a27.r13` | `tax_scale_floor_0` | Podatek nie moze byc ujemny (minimum 0) | Ograniczenie |
| `jdg.pit.a27.r14` | `tax_scale_not_available_linear` | JDG z podatkiem liniowym -> NIE korzysta ze skali | Wylaczenie |
| `jdg.pit.a27.r15` | `tax_scale_not_available_lump_sum` | JDG z ryczaltem -> NIE korzysta ze skali | Wylaczenie |

### 2.6 Art. 27a PIT — Ulga na dzieci (~10 rules)

| ID | Nazwa reguly | Warunek | Kwota |
|:--:|-------------|---------|:----:|
| `jdg.pit.a27a.r1` | `child_tax_credit_eligibility` | Podatnik wychowujacy dziecko maloletnie | Prawo do ulgi |
| `jdg.pit.a27a.r2` | `child_tax_credit_first_child` | Pierwsze dziecko (limit dochodowy 112k/150k single/joint) | 1 112.04 PLN/rok |
| `jdg.pit.a27a.r3` | `child_tax_credit_second_child` | Drugie dziecko | 1 668.12 PLN/rok |
| `jdg.pit.a27a.r4` | `child_tax_credit_third_child` | Trzecie dziecko | 2 000.04 PLN/rok |
| `jdg.pit.a27a.r5` | `child_tax_credit_fourth_plus` | Czwarte i kazde kolejne | 2 700.00 PLN/rok |
| `jdg.pit.a27a.r6` | `child_tax_credit_disabled_child` | Dziecko z orzeczeniem o niepelnosprawnosci | Podwojona kwota |
| `jdg.pit.a27a.r7` | `child_tax_credit_income_limit_single` | Samotny rodzic: limit 112 000 PLN dochodu | Limit |
| `jdg.pit.a27a.r8` | `child_tax_credit_income_limit_joint` | Wspolne rozliczenie: limit 150 000 PLN | Limit |
| `jdg.pit.a27a.r9` | `child_tax_credit_refundable_scale_only` | Ulga jest zwracana (refundable) tylko dla skali podatkowej | Refundacja |
| `jdg.pit.a27a.r10` | `child_tax_credit_non_refundable_others` | Dla liniowego/ryczaltu -> NIE jest zwracana (non-refundable) | Brak zwrotu |

### 2.7 Amortyzacja — Art. 22a-22m PIT (~40 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a22a.r1` | `depreciation_asset_classification` | Srodek trwaly: okres uzywania >1 rok, kompletny, uzywany na potrzeby JDG | Kwalifikacja |
| `jdg.pit.a22a.r2` | `depreciation_excluded_land` | Grunt nie podlega amortyzacji | Wylaczenie |
| `jdg.pit.a22a.r3` | `depreciation_excluded_living_buildings` | Budynki mieszkalne (nie-firmowe) nie podlegaja amortyzacji | Wylaczenie |
| `jdg.pit.a22a.r4` | `depreciation_excluded_goodwill` | Wartosc firmy (goodwill) nie podlega amortyzacji PIT | Wylaczenie |
| `jdg.pit.a22d.r1` | `depreciation_method_linear` | Metoda liniowa: rownomierne odpisy przez okres uzywania | Standard |
| `jdg.pit.a22d.r2` | `depreciation_method_declining` | Metoda degresywna: wyzsze odpisy na poczatku (dla maszyn) | Opcja |
| `jdg.pit.a22d.r3` | `depreciation_method_one_time_under_10k` | Jednorazowo do 10 000 PLN (slaby srodek trwaly) | Opcja uproszczona |
| `jdg.pit.a22d.r4` | `depreciation_rate_standard_table` | Stawka amortyzacji z Wykazu stawek amortyzacyjnych | Stawka |
| `jdg.pit.a22d.r5` | `depreciation_rate_individual` | Indywidualna stawka dla uzywanych/ulepszonych srodkow | Opcja |
| `jdg.pit.a22d.r6` | `depreciation_rate_increased_1_4` | Wspolczynnik podwyzszajacy 1.4 dla maszyn w warunkach szkodliwych | Podwyzszenie |
| `jdg.pit.a22d.r7` | `depreciation_rate_increased_2_0` | Wspolczynnik 2.0 dla maszyn w warunkach szczegolnie szkodliwych | Podwyzszenie |
| `jdg.pit.a22e.r1` | `depreciation_low_value_one_time_100k` | Limit malego srodka trwalego: do 100 000 PLN (jednorazowo) | Jednorazowo |
| `jdg.pit.a22e.r2` | `depreciation_low_value_deadline` | Jednorazowy odpis w miesiacu oddania do uzywania | Termin |
| `jdg.pit.a22f.r1` | `depreciation_used_property_60_months` | Uzywane srodki trwale: amortyzacja indywidualna min 60 mies. | Min okres |
| `jdg.pit.a22g.r1` | `depreciation_buildings_2_5pct` | Budynki niemieszkalne: stawka 2.5% (40 lat) | Stawka |
| `jdg.pit.a22g.r2` | `depreciation_buildings_residential_1_5` | Budynki mieszkalne firmowe: 1.5% (67 lat) | Stawka |
| `jdg.pit.a22g.r3` | `depreciation_machinery_10_30pct` | Maszyny i urzadzenia: 10-30% wg Klasyfikacji Srodkow Trwalych | Stawka |
| `jdg.pit.a22g.r4` | `depreciation_computers_30pct` | Komputery, oprogramowanie: 30% | Stawka |
| `jdg.pit.a22g.r5` | `depreciation_vehicles_20pct` | Samochody osobowe, ciezarowe: 20% | Stawka |
| `jdg.pit.a22g.r6` | `depreciation_furniture_20pct` | Meblo, wyposazenie: 20% | Stawka |
| `jdg.pit.a22g.r7` | `depreciation_plant_equipment_10_20` | Urzadzenia techniczne: 10-20% | Stawka |
| `jdg.pit.a22i.r1` | `depreciation_moment_start_next_month` | Odpisy amortyzacyjne od nastepnego miesiaca po przyjeciu | Moment rozpoczecia |
| `jdg.pit.a22i.r2` | `depreciation_moment_stop_disposal` | Zaprzestanie odpisow po likwidacji/sprzedazy/zapisie | Moment zakonczenia |
| `jdg.pit.a22i.r3` | `depreciation_partial_year_pro_rata` | W roku przyjecia: odpis za miesiace od przyjecia do konca roku | Pro rata |
| `jdg.pit.a22j.r1` | `depreciation_improvement_upgrade` | Ulepszenie srodka trwalego >10 000 PLN -> podwyzszenie wartosci | Ulepszenie |
| `jdg.pit.a22j.r2` | `depreciation_improvement_new_rate` | Po ulepszeniu: nowa stawka od podwyzszonej wartosci | Nowa stawka |
| `jdg.pit.a22k.r1` | `depreciation_sale_tax_consequences` | Sprzedaz srodka trwalego -> przychod, a niezamortyzowana wartosc -> KUP | Skutki podatkowe |
| `jdg.pit.a22k.r2` | `depreciation_liquidation_loss` | Likwidacja srodka -> strata z likwidacji (NKUP, chyba ze z przyczyn gospodarczych) | Strata |
| `jdg.pit.a22k.r3` | `depreciation_liquidation_business_reasons` | Likwidacja z przyczyn gospodarczych -> KUP (strata) | KUP |
| `jdg.pit.a22l.r1` | `depreciation_intangibles_wnip` | Wartosci niematerialne i prawne: licencje, patenty, know-how | Definicja WNiP |
| `jdg.pit.a22l.r2` | `depreciation_wnip_license_5_years` | Licencje na programy komputerowe: amortyzacja 5 lat | Okres |
| `jdg.pit.a22l.r3` | `depreciation_wnip_patent_5_years` | Patenty, znaki towarowe: amortyzacja 5 lat | Okres |
| `jdg.pit.a22l.r4` | `depreciation_wnip_goodwill_5_years` | Wartosc firmy: amortyzacja 5 lat | Okres |
| `jdg.pit.a22l.r5` | `depreciation_wnip_low_10k_one_time` | WNiP o niskiej wartosci (do 10 000 PLN) -> jednorazowo w KUP | Jednorazowo |
| `jdg.pit.a22m.r1` | `depreciation_private_car_transfer` | Przeniesienie auta prywatnego do firmy -> wartosc rynkowa na moment przeniesienia | Wycena |
| `jdg.pit.a22m.r2` | `depreciation_private_car_limit_150k` | Amortyzacja auta osobowego ograniczona do 150 000 PLN (225k EV) | Limit wyceny |
| `jdg.pit.a22m.r3` | `depreciation_electric_car_limit_225k` | Samochod elektryczny: limit amortyzacji 225 000 PLN | Limit EV |
| `jdg.pit.a22m.r4` | `depreciation_firm_car_tax_consequences` | Amortyzacja auta uzywanego mieszanie -> 75% KUP od amortyzacji | 75% KUP |
| `jdg.pit.a22m.r5` | `depreciation_firm_car_mileage_log_100pct` | Ewidencja przebiegu -> 100% KUP od amortyzacji | 100% KUP |
| `jdg.pit.a22m.r6` | `depreciation_firm_car_no_log_75pct` | Brak ewidencji -> 75% KUP od amortyzacji | 75% KUP |


### 2.8 Art. 30a-30b PIT — Kapitaly i zbycie nieruchomosci (~20 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a30a.r1` | `capital_income_dividends` | Dywidendy, udzial w zyskach spolki | 19% podatku (ryczalt) |
| `jdg.pit.a30a.r2` | `capital_income_interest` | Odsetki od pozyczek, kredytow, obligacji | 19% podatku (ryczalt) |
| `jdg.pit.a30a.r3` | `capital_income_bonds` | Odsetki od obligacji (skarbowych, komunalnych) | 19% |
| `jdg.pit.a30a.r4` | `capital_income_sale_of_shares` | Zbycie akcji, udzialow, tytulow uczestnictwa | Dochód jako przychod - koszty |
| `jdg.pit.a30a.r5` | `capital_income_derivatives` | Instrumenty pochodne, kontrakty terminowe, opcje | 19% |
| `jdg.pit.a30a.r6` | `capital_income_investment_funds` | Dochody z funduszy inwestycyjnych | 19% |
| `jdg.pit.a30a.r7` | `capital_income_separate_source` | Dochody kapitalowe jako odrebne zrodlo (nie laczy sie z JDG) | Odrębnosc |
| `jdg.pit.a30a.r8` | `capital_income_loss_not_deductible` | Strata na kapitalach -> NIE odlicza sie od JDG | Ograniczenie |
| `jdg.pit.a30a.r9` | `capital_income_withholding_tax` | Pobrany podatek u zrodla (podatek u zrodla 19%) | WHT |
| `jdg.pit.a30a.r10` | `capital_income_exemption_employee_shares` | Dochody z pracowniczych programow akcyjnych | Zwolnienie |
| `jdg.pit.a30b.r1` | `real_estate_sale_before_5_years` | Sprzedaz nieruchomosci przed uplywem 5 lat od nabycia | Opodatkowane |
| `jdg.pit.a30b.r2` | `real_estate_sale_after_5_years` | Sprzedaz po 5 latach -> zwolnione z PIT | Zwolnione |
| `jdg.pit.a30b.r3` | `real_estate_sale_5_year_countdown` | 5 lat liczone od konca roku kalendarzowego nabycia | Sposob liczenia |
| `jdg.pit.a30b.r4` | `real_estate_sale_inheritance` | Dziedziczenie -> 5 lat od smierci spadkodawcy | Specjalna zasada |
| `jdg.pit.a30b.r5` | `real_estate_sale_rate_19pct` | Stawka 19% od dochodu ze sprzedazy | Stawka |
| `jdg.pit.a30b.r6` | `real_estate_sale_deduction_own_housing` | Wydatki na wlasne cele mieszkaniowe -> zwolnienie | Zwolnienie warunkowe |
| `jdg.pit.a30b.r7` | `real_estate_sale_housing_deadline_3_years` | Wydatki mieszkaniowe w 3 lata od sprzedazy | Termin |
| `jdg.pit.a30b.r8` | `real_estate_sale_housing_catalog` | Katalog: zakup domu/mieszkania, budowa, remont, spolka mieszkaniowa | Katalog wydatkow |
| `jdg.pit.a30b.r9` | `real_estate_sale_share_of_property` | Sprzedaz udzialu we wlasnosci -> proporcjonalnie | Udzial |
| `jdg.pit.a30b.r10` | `real_estate_sale_declaration_PIT_39` | Zeznanie PIT-39 w terminie do 30 kwietnia nastepnego roku | Deklaracja |

### 2.9 Art. 31-33 PIT — Zaliczki na podatek (~25 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a31.r1` | `advance_monthly_obligation_scale` | Skala podatkowa -> zaliczki miesieczne do 20. dnia nastepnego miesiaca | Obowiazek |
| `jdg.pit.a31.r2` | `advance_monthly_obligation_linear` | Podatek liniowy -> zaliczki miesieczne do 20. dnia | Obowiazek |
| `jdg.pit.a31.r3` | `advance_quarterly_small_payer` | Maly podatnik (przychod < 1.2M EUR) -> kwartalne zaliczki | Opcja |
| `jdg.pit.a31.r4` | `advance_quarterly_deadline_20` | Zaliczka kwartalna do 20. dnia po kwartale | Termin |
| `jdg.pit.a31.r5` | `advance_calculation_progressive` | Zaliczka = dotychczasowy dochod x stawka - zaplacone zaliczki | Obliczenie |
| `jdg.pit.a31.r6` | `advance_deduction_zus_contributions` | Odliczenie skladek ZUS zaplaconych w okresie od dochodu | Pomniejszenie |
| `jdg.pit.a31.r7` | `advance_deduction_zus_timing` | Składka ZUS za dany miesiac odliczana w zaliczce za ten miesiac | Timing |
| `jdg.pit.a31.r8` | `advance_deduction_health_7_75` | Skladka zdrowotna 7.75% podstawy (dla skali) -> odliczenie od podatku | Odliczenie |
| `jdg.pit.a31.r9` | `advance_deduction_health_4_9_linear` | Dla liniowego: skladka zdrowotna 4.9% -> odliczenie od podatku | Odliczenie |
| `jdg.pit.a31.r10` | `advance_health_contribution_cap` | Skladka zdrowotna odliczana do wysokosci zaplaconej w okresie | Limit |
| `jdg.pit.a31.r11` | `advance_income_calculation_cumulative` | Dochód narastajaco od poczatku roku | Metoda kumulatywna |
| `jdg.pit.a31.r12` | `advance_revenue_recognition_pkpir` | Przychod w PKPiR w dacie wystawienia faktury (lub 25. dnia miesiaca) | Moment przychodu |
| `jdg.pit.a31.r13` | `advance_expense_recognition_pkpir` | Koszt w PKPiR w dacie poniesienia (faktury) | Moment kosztu |
| `jdg.pit.a31.r14` | `advance_if_zero_or_negative` | Zaliczka = 0 gdy dochód <= 0 lub podatek <= 0 | Brak zaliczki |
| `jdg.pit.a31.r15` | `advance_no_obligation_if_under_income` | Brak obowiazku gdy przychod < koszty + ZUS | Brak obowiazku |
| `jdg.pit.a31.r16` | `advance_overpayment_refund` | Nadplata w zaliczkach -> zwrot na wniosek lub z deklaracji rocznej | Zwrot |
| `jdg.pit.a31.r17` | `advance_underpayment_interest` | Niedoplata -> odsetki za zwloke od terminu platnosci | Odsetki |
| `jdg.pit.a31.r18` | `advance_change_to_quarterly_mid_year` | Zmiana na kwartalne w trakcie roku -> od poczatku nastepnego kwartalu | Zmiana |
| `jdg.pit.a31.r19` | `advance_cessation_income_liquidation` | Zaprzestanie dzialalnosci -> zaliczka za okres do dnia zaprzestania | Zakonczenie |
| `jdg.pit.a31.r20` | `advance_cessation_deadline_20` | Ostatnia zaliczka do 20. dnia nastepnego miesiaca po zaprzestaniu | Termin |
| `jdg.pit.a31.r21` | `advance_annual_settlement_difference` | Roznica miedzy suma zaliczek a podatkiem rocznym -> doplata/zwrot | Rozliczenie |
| `jdg.pit.a32.r1` | `advance_lump_sum_monthly_20` | Ryczałt -> zaliczki miesieczne do 20. dnia nastepnego miesiaca | Obowiazek |
| `jdg.pit.a32.r2` | `advance_lump_sum_rate_applied` | Zaliczka = przychod x stawka ryczaltu (bez KUP) | Obliczenie uproszczone |
| `jdg.pit.a32.r3` | `advance_lump_sum_deduction_zus` | Odliczenie skladek ZUS od przychodu przed opodatkowaniem | Pomniejszenie |
| `jdg.pit.a32.r4` | `advance_lump_sum_deduction_health` | Odliczenie skladki zdrowotnej 4.9% (dla ryczaltu od 2022) | Odliczenie |
| `jdg.pit.a32.r5` | `advance_tax_card_monthly_fixed` | Karta podatkowa -> stala miesieczna kwota podatku | Stala kwota |

### 2.10 Art. 44-45 PIT — Deklaracje roczne (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a45.r1` | `annual_return_scale_PIT_36` | Skala podatkowa -> PIT-36 | Deklaracja |
| `jdg.pit.a45.r2` | `annual_return_linear_PIT_36L` | Podatek liniowy -> PIT-36L | Deklaracja |
| `jdg.pit.a45.r3` | `annual_return_lump_PIT_28` | Ryczałt -> PIT-28 | Deklaracja |
| `jdg.pit.a45.r4` | `annual_return_tax_card_PIT_16A` | Karta podatkowa -> PIT-16A | Deklaracja |
| `jdg.pit.a45.r5` | `annual_return_deadline_30_april` | Termin zlozenia: 30 kwietnia nastepnego roku | Termin |
| `jdg.pit.a45.r6` | `annual_return_self_employed_extension` | JDG moze zlozyc deklaracje bez posrednictwa (e-Deklaracja) | Sposob |
| `jdg.pit.a45.r7` | `annual_return_electronic_mandatory` | Obowiazek e-Deklaracji (podpis kwalifikowany lub profil zaufany) | Forma |
| `jdg.pit.a45.r8` | `annual_return_tax_due_calculation` | Podatek należny = podatek roczny - suma zaliczek - ulgi | Obliczenie |
| `jdg.pit.a45.r9` | `annual_return_overpayment_refund_45_days` | Zwrot nadplaty w 45 dni od zlozenia deklaracji | Termin zwrotu |
| `jdg.pit.a45.r10` | `annual_return_correction_after_filing` | Korekta deklaracji po zlozeniu -> korekta PIT | Mozliwosc |
| `jdg.pit.a45.r11` | `annual_return_deadline_after_cessation` | Zaprzestanie dzialalnosci -> deklaracja do 30 kwietnia roku po zaprzestaniu | Termin szczegolny |
| `jdg.pit.a45.r12` | `annual_return_death_entrepreneur` | Smierc przedsiebiorcy -> deklaracja sklada spadkobierca w 3 miesiace | Sukcesja |
| `jdg.pit.a44.r1` | `annual_income_estimated_current_year` | Zaliczki w roku biezacym na podstawie dochodu roku poprzedniego | Szacowanie |
| `jdg.pit.a44.r2` | `annual_income_actual_current_year` | Opcja: zaliczki na podstawie faktycznego dochodu biezacego roku | Faktyczny |
| `jdg.pit.a44.r3` | `annual_income_change_method_notification` | Zmiana metody szacowania -> zawiadomienie US do 20. lutego | Obowiazek formalny |

### 2.11 Art. 9a PIT — Formy opodatkowania i zmiana (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.pit.a9a.r1` | `tax_form_selection_freedom` | JDG wybiera forme opodatkowania: skala, liniowy, ryczalt, karta | Wolnosc wyboru |
| `jdg.pit.a9a.r2` | `tax_form_linear_option_19pct` | Podatek liniowy 19% -> brak kwoty wolnej, brak lacznia z innymi zrodlami | 19% |
| `jdg.pit.a9a.r3` | `tax_form_linear_restriction_services_client` | Liniowy niedostepny dla uslug na rzecz bylego pracodawcy (j.w.) | Ograniczenie |
| `jdg.pit.a9a.r4` | `tax_form_linear_former_employer_3_years` | Uslugi dla bylnego pracodawcy (te same czynnosci) w 3 lata od ustania etatu | Blokada |
| `jdg.pit.a9a.r5` | `tax_form_change_deadline_20_january` | Zmiana formy opodatkowania do 20 stycznia roku podatkowego | Termin |
| `jdg.pit.a9a.r6` | `tax_form_change_first_year_start` | Dla nowej JDG: oswiadczenie o wyborze formy w pierwszym roku | Nowa dzialalnosc |
| `jdg.pit.a9a.r7` | `tax_form_change_automatic_return_to_scale` | Brak oswiadczenia -> domyslnie skala podatkowa | Domyslna |
| `jdg.pit.a9a.r8` | `tax_form_change_from_scale_to_linear` | Zmiana ze skali na liniowy -> zawiadomienie US | Procedura |
| `jdg.pit.a9a.r9` | `tax_form_change_from_linear_to_scale` | Zmiana z liniowego na skale -> zawiadomienie US | Procedura |
| `jdg.pit.a9a.r10` | `tax_form_change_to_lump_sum_PIT_28` | Zmiana na ryczalt do 20 stycznia lub przy rozpoczynaniu dzialalnosci | Procedura |

---

## CZĘŚĆ III: ORDYNACJA PODATKOWA (390 REGUL)

### 3.1 Art. 29-33: Podatnicy, platnicy, inkasenci (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a29.r1` | `taxpayer_definition_jdg` | Osoba fizyczna prowadzaca JDG jest podatnikiem PIT/VAT | Definicja |
| `jdg.ord.a29.r2` | `taxpayer_legal_capacity` | JDG ma zdolnosc prawna (podatkowa) jako osoba fizyczna | Zdolnosc |
| `jdg.ord.a29.r3` | `taxpayer_representation_self` | Przedsiebiorca JDG dziala samodzielnie we wszystkich sprawach podatkowych | Reprezentacja |
| `jdg.ord.a29.r4` | `taxpayer_representation_attorney` | Mozliwosc ustanowienia pelnomocnika do spraw podatkowych | Pelnomocnik |
| `jdg.ord.a29.r5` | `taxpayer_representation_attorney_form` | Pelnomocnictwo w formie pisemnej lub elektronicznej (UPL) | Forma |
| `jdg.ord.a32.r1` | `taxpayer_correct_declaration_duty` | Podatnik ma obowiazek skladania deklaracji zgodnych ze stanem faktycznym | Obowiazek |
| `jdg.ord.a32.r2` | `taxpayer_correct_declaration_consequences` | Blędna deklaracja -> sankcje KKS, odsetki, korekta | Konsekwencje |
| `jdg.ord.a33.r1` | `taxpayer_obligation_to_pay` | Obowiazek zaplaty podatku w terminie i wysokosci wynikajacej z deklaracji | Obowiazek |
| `jdg.ord.a33.r2` | `taxpayer_payment_methods` | Formy platnosci: przelew, gotowka (do 15k B2B), karta | Metody |
| `jdg.ord.a33.r3` | `taxpayer_payment_currency_pln` | Podatki placi sie w PLN (z wylaczeniem walut obcych dla podatnika walutowego) | Waluta |
| `jdg.ord.a33.r4` | `taxpayer_payment_day_electronic` | Dzien obciazenia rachunku bankowego = dzien zaplaty (dla przelewu) | Dzien zaplaty |
| `jdg.ord.a33.r5` | `taxpayer_payment_day_cash` | Dzien wplaty gotowki w kasie US = dzien zaplaty | Dzien zaplaty |
| `jdg.ord.a33.r6` | `taxpayer_payment_day_postal` | Dzien nadania przekazu pocztowego = dzien zaplaty (do 2026) | Dzien zaplaty |
| `jdg.ord.a33.r7` | `taxpayer_payment_priority_debts` | Kolejnosc zaplaty: najstarsze zaleglosci pierwsze | Priorytet |
| `jdg.ord.a33.r8` | `taxpayer_multi_debt_allocation` | Wplata na kilka zobowiazan -> proporcjonalnie na kazde (chyba ze podatnik wskaze inaczej) | Alokacja |

### 3.2 Art. 47-52: Odsetki za zwloke (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a47.r1` | `interest_overdue_arrears` | Niezaplata podatku w terminie -> odsetki za zwloke | Sankcja |
| `jdg.ord.a47.r2` | `interest_rate_200pct_basic` | Stawka odsetek = 200% podstawowej stopy oprocentowania kredytu lombardowego NBP | Stawka |
| `jdg.ord.a47.r3` | `interest_rate_reduced_75pct` | Stawka obnizona 75% (dla korekt zlozonych po ogloszeniu) | Stawka obnizona |
| `jdg.ord.a47.r4` | `interest_rate_reduced_50pct` | Stawka 50% (dla korekt po kontroli, przed wszczeciem postepowania) | Stawka obnizona |
| `jdg.ord.a47.r5` | `interest_calculation_period` | Odsetki od nastepnego dnia po terminie do dnia zaplaty | Okres |
| `jdg.ord.a47.r6` | `interest_calculation_daily` | Odsetki liczone dziennie (kwota x stawka / 365) | Sposob liczenia |
| `jdg.ord.a47.r7` | `interest_minimum_3_30_pln` | Minimalna kwota odsetek do zaplaty: 3.30 PLN (lub 66.60 PLN w 2024) | Minimum |
| `jdg.ord.a48.r1` | `interest_deferral_extension` | Odroczenie terminu zaplaty -> odsetki oplaty prolongacyjnej (obnizona stawka) | Odroczenie |
| `jdg.ord.a48.r2` | `interest_deferral_fee_50pct` | Oplata prolongacyjna = 50% stawki odsetek za zwloke | Stawka |
| `jdg.ord.a48.r3` | `interest_deferral_not_for_sanctions` | Odroczenie nie dotyczy kar podatkowych (KKS) | Wylaczenie |
| `jdg.ord.a49.r1` | `interest_suspension_force_majeure` | Zawieszenie naliczania odsetek w przypadku dzialania sily wyzszej (np. powodzi) | Zawieszenie |
| `jdg.ord.a49.r2` | `interest_suspension_moratorium` | Zawieszenie na mocy ustawy szczegolnej (moratorium podatkowe) | Zawieszenie |
| `jdg.ord.a51.r1` | `interest_write_off_below_5_pln` | Umorzenie odsetek gdy kwota nie przekracza 5 PLN | Umorzenie z mocy prawa |
| `jdg.ord.a52.r1` | `interest_payment_priority_principal_first` | Wplata -> pokrywa odsetki przed naleznością glowna | Priorytet |
| `jdg.ord.a52.r2` | `interest_designation_by_taxpayer` | Podatnik moze wskazac, ze wplata pokrywa nalezność glowna przed odsetkami | Wskazanie |

### 3.3 Art. 67b-67e: Ulgi w spłacie zobowiazan (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a67b.r1` | `relief_deferral_12_months` | Odroczenie terminu zaplaty na max 12 miesiecy | Ulga |
| `jdg.ord.a67b.r2` | `relief_installments_12_months` | Rozlozenie na raty na max 12 miesiecy | Ulga |
| `jdg.ord.a67b.r3` | `relief_deferral_extension_exceptional` | Przedluzenie odroczenia w wyjatkowych przypadkach (+12 mies.) | Przedluzenie |
| `jdg.ord.a67b.r4` | `relief_umoreszenie_important_interest` | Umorzenie zaleglosci podatkowej z powodu waznego interesu podatnika | Ulga |
| `jdg.ord.a67b.r5` | `relief_umoreszenie_public_interest` | Umorzenie z uwagi na interes publiczny | Ulga |
| `jdg.ord.a67b.r6` | `relief_deferral_criteria_income` | Kryterium: wysokosc dochodu, sytuacja majatkowa, liczebnosc rodziny | Kryterium |
| `jdg.ord.a67b.r7` | `relief_deferral_application` | Wniosek podatnika o ulge (wraz z uzasadnieniem i dowodami) | Formalnosc |
| `jdg.ord.a67b.r8` | `relief_deferral_decision_2_months` | US ma 2 miesiace na decyzje (od dnia zlozenia kompleta dokumentow) | Termin |
| `jdg.ord.a67c.r1` | `relief_deferral_automatic_for_disasters` | Ulgi automatyczne w przypadku klęsk zywiolowych (np. powodzi) | Automatyczne |
| `jdg.ord.a67d.r1` | `relief_deferral_collateral_required` | Zabezpieczenie majatkowe moze byc wymagane przy ulgach powyzej 10 000 PLN | Zabezpieczenie |
| `jdg.ord.a67d.r2` | `relief_deferral_collateral_types` | Formy: hipoteka, zastew, gwarancja bankowa, poręczenie | Formy |
| `jdg.ord.a67e.r1` | `relief_deferral_revocation` | Odwolanie ulgi gdy podatnik nie splaca rat lub pogorszenie sytuacji | Odwolanie |
| `jdg.ord.a67e.r2` | `relief_deferral_revocation_immediate_payment` | Odwolanie -> cala pozostala kwota natychmiast wymagalna | Konsekwencja |
| `jdg.ord.a67e.r3` | `relief_deferral_interest_after_revocation` | Po odwolaniu: odsetki od calego okresu odroczenia | Odsetki |

### 3.4 Art. 70-71: Przedawnienie (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a70.r1` | `statute_of_limitations_5_years` | Zobowiazanie podatkowe przedawnia sie po 5 latach od konca roku | 5 lat |
| `jdg.ord.a70.r2` | `statute_of_limitations_count_start` | Liczone od konca roku kalendarzowego, w ktorym uplynal termin platnosci | Poczatek |
| `jdg.ord.a70.r3` | `statute_of_limitations_criminal_tax_5_years` | Przestepstwa skarbowe: przedawnienie karalnosci po 5 latach | KKS |
| `jdg.ord.a70.r4` | `statute_of_limitations_interruption_initiation` | Postepowanie karne skarbowe -> przerwanie biegu przedawnienia | Przerwanie |
| `jdg.ord.a70.r5` | `statute_of_limitations_interruption_declaration` | Zlozenie deklaracji po terminie -> przerwanie biegu | Przerwanie |
| `jdg.ord.a70.r6` | `statute_of_limitations_suspension_tax_decision` | Decyzja US przed przedawnieniem -> zawieszenie do czasu uprawomocnienia | Zawieszenie |
| `jdg.ord.a70.r7` | `statute_of_limitations_suspension_appeal` | Odwolanie od decyzji -> zawieszenie do czasu rozpatrzenia | Zawieszenie |
| `jdg.ord.a70.r8` | `statute_of_limitations_5_plus_3` | Max przedawnienie: 5 lat + 3 lata (zawieszenia/przerwania) = 8 lat | Limit |
| `jdg.ord.a70.r9` | `statute_of_limitations_cannot_be_waived` | Przedawnienie dziala z mocy prawa (NIE mozna go odwolac) | Bezwzgledny |
| `jdg.ord.a70.r10` | `statute_of_limitations_after_limitation_return` | Po przedawnieniu: nalezność wygasa, US nie moze egzekwowac | Skutek |
| `jdg.ord.a70.r11` | `statute_of_limitations_overpayment_return` | Nadplata po przedawnieniu -> podlega zwrotowi (jesli nie ma innych zaleglosci) | Nadplata |
| `jdg.ord.a70.r12` | `statute_of_limitations_legal_entity_jdg` | JDG jako osoba fizyczna -> przedawnienie jak dla osoby fizycznej | Podmiot |
| `jdg.ord.a70.r13` | `statute_of_limitations_criminal_proceedings` | Wszczece postepowania karnego skarbowego -> przedawnienie 10 lat | KKS wydluzenie |
| `jdg.ord.a71.r1` | `statute_of_limitations_overpay_5_years` | Prawo do zwrotu nadplaty przedawnia sie po 5 latach | Nadplata |
| `jdg.ord.a71.r2` | `statute_of_limitations_overpay_start` | Liczone od konca roku, w ktorym nadplata powstala | Poczatek nadplaty |

### 3.5 Art. 72-80: Nadplata i zwrot podatku (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a72.r1` | `overpayment_definition_overpaid` | Nadplata = nadwyzka zaplaconego podatku nad nalezny | Definicja |
| `jdg.ord.a72.r2` | `overpayment_definition_correction` | Nadplata powstaje z dniem zlozenia korekty deklaracji | Moment powstania |
| `jdg.ord.a72.r3` | `overpayment_return_45_days` | Zwrot nadplaty w 45 dni od stwierdzenia nadplaty | Termin zwrotu |
| `jdg.ord.a72.r4` | `overpayment_return_extension_60_days` | Przedluzenie do 60 dni gdy US wymaga uzupelnienia dokumentacji | Przedluzenie |
| `jdg.ord.a72.r5` | `overpayment_interest_after_deadline` | Po terminie 45/60 dni -> odsetki za zwloke od nadplaty | Odsetki |
| `jdg.ord.a73.r1` | `overpayment_offset_against_arrears` | Nadplata zaliczana na poczet zaleglosci podatkowych (urzedowo) | Zaliczanie |
| `jdg.ord.a73.r2` | `overpayment_offset_against_future` | Nadplata na poczet przyszlych zobowiazan na wniosek | Przyszle |
| `jdg.ord.a74.r1` | `overpayment_request_form` | Wniosek o zwrot nadplaty (brak wniosku -> zaliczenie z urzedu) | Formalnosc |
| `jdg.ord.a75.r1` | `overpayment_after_limitation_period` | Nadplata po przedawnieniu -> zwrot jesli brak innych zaleglosci | Warunek |
| `jdg.ord.a76.r1` | `overpayment_not_refundable_minor` | Nadplata do 5 PLN -> nie podlega zwrotowi | Minimum |
| `jdg.ord.a77.r1` | `overpayment_inheritance` | Nadplata wchodzi w sklad masy spadkowej | Dziedziczenie |
| `jdg.ord.a78.r1` | `overpayment_limitation_5_years_correction` | Prawo do korekty deklaracji i zwrotu nadplaty -> 5 lat od konca roku | Termin |
| `jdg.ord.a79.r1` | `overpayment_correction_before_audit` | Korekta przed kontrola -> brak sankcji (pelna nadplata) | Brak sankcji |
| `jdg.ord.a79.r2` | `overpayment_correction_after_audit` | Korekta po ogloszeniu kontroli -> nadplata, ale mozliwe sankcje | Sankcje |
| `jdg.ord.a80.r1` | `overpayment_foreign_currency` | Nadplata w walucie obcej -> przeliczenie na PLN wg kursu z dnia zaplaty | Waluta |

### 3.6 Art. 81-81c: Korekta deklaracji (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a81.r1` | `correction_right_general` | Podatnik ma prawo skorygowac zlozona deklaracje | Prawo |
| `jdg.ord.a81.r2` | `correction_before_audit_free` | Korekta przed ogloszeniem kontroli -> bez sankcji | Bez sankcji |
| `jdg.ord.a81.r3` | `correction_during_audit_limited` | Podczas kontroli -> korekta wymaga zgody US | Ograniczenie |
| `jdg.ord.a81.r4` | `correction_after_audit_restricted` | Po kontroli -> korekta tylko za zgoda naczelnika US | Ograniczenie |
| `jdg.ord.a81.r5` | `correction_limitation_5_years` | Prawo do korekty wygasa po 5 latach od konca roku podatkowego | Termin |
| `jdg.ord.a81.r6` | `correction_form_electronic` | Korekta w formie elektronicznej (e-Deklaracja) | Forma |
| `jdg.ord.a81.r7` | `correction_reason_required_major` | Korekta wymaga wskazania przyczyny i zakresu bledu | Obowiazek |
| `jdg.ord.a81.r8` | `correction_decrease_procedure` | Korekta in minus -> US sprawdza zasadnosc (30 dni na weryfikacje) | Weryfikacja |
| `jdg.ord.a81.r9` | `correction_increase_payment_obligation` | Korekta in plus -> zaplata podatku + odsetki od pierwotnego terminu | Obowiazek zaplaty |
| `jdg.ord.a81c.r1` | `correction_automatic_vat_efakturowanie` | Korekta VAT przez KSeF -> automatyczna weryfikacja | Automatyczna |

### 3.7 Art. 145-149: Postepowanie podatkowe (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a145.r1` | `proceeding_initiation_ex_officio` | US wszczyna postepowanie z urzedu (np. w sprawie zaleglosci) | Wszczece |
| `jdg.ord.a145.r2` | `proceeding_initiation_on_request` | Postepowanie na wniosek podatnika (np. o ulge) | Wniosek |
| `jdg.ord.a145.r3` | `proceeding_party_rights` | JDG jako strona ma prawo: wglad w akta, wypowiedzenie sie, odvolanie | Prawa strony |
| `jdg.ord.a145.r4` | `proceeding_confidentiality` | Dane podatkowe JDG sa chronione tajemnica skarbowa | Tajemnica |
| `jdg.ord.a145.r5` | `proceeding_deadline_2_months` | Zalatywienie sprawy w 2 miesiace od wszczecia | Termin |
| `jdg.ord.a145.r6` | `proceeding_deadline_extension_notification` | Przedluzenie terminu -> zawiadomienie strony | Obowiazek |
| `jdg.ord.a146.r1` | `proceeding_evidence_rules` | Postepowanie dowodowe: dokumenty, oswiadczenia, przesluchania, opinie | Dowody |
| `jdg.ord.a146.r2` | `proceeding_burden_of_proof_on_us` | Ciezar dowodu w sprawach podatkowych spoczywa na organie | Ciezar dowodu |
| `jdg.ord.a146.r3` | `proceeding_burden_of_proof_on_taxpayer` | Podatnik ma obowiazek przedstawic dowoly na okolicznosci korzystne dla siebie | Dowody podatnika |
| `jdg.ord.a147.r1` | `proceeding_decision_requirements` | Decyzja US: podstawa prawna, uzasadnienie faktyczne, pouczenie | Wymogi decyzji |
| `jdg.ord.a147.r2` | `proceeding_decision_appeal_possible` | Od decyzji US sluzy odvolanie do Izby Administracji Skarbowej | Odvolanie |
| `jdg.ord.a147.r3` | `proceeding_decision_appeal_14_days` | Termin na odvolanie: 14 dni od doręczenia decyzji | Termin |
| `jdg.ord.a147.r4` | `proceeding_decision_appeal_suspension` | Odvolanie wstrzymuje wykonanie decyzji (co do zasady) | Suspensywnosc |
| `jdg.ord.a148.r1` | `proceeding_decision_final_after_appeal` | Decyzja ostateczna po rozpatrzeniu odvolania przez II instancje | Ostatecznosc |
| `jdg.ord.a148.r2` | `proceeding_decision_waiver_of_appeal` | Strona moze zrzec sie prawa do odvolania (po ogloszeniu decyzji) | Zrzeczenie |

### 3.8 Art. 165-180: Kontrola celno-skarbowa i podatkowa (~20 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a165.r1` | `audit_power_notification` | Kontrola podatkowa: zawiadomienie 7 dni przed planowana kontrola | Zawiadomienie |
| `jdg.ord.a165.r2` | `audit_without_notice_exceptions` | Kontrola bez zawiadomienia: podejrzenie przestepstwa, zabezpieczenie majatku | Wylaczenie |
| `jdg.ord.a165.r3` | `audit_max_duration_30_days` | Maksymalny czas trwania kontroli: 30 dni (dla duzych podmiotow 60) | Czas trwania |
| `jdg.ord.a165.r4` | `audit_max_duration_extension_14` | Przedluzenie o 14 dni w szczegolnych przypadkach | Przedluzenie |
| `jdg.ord.a165.r5` | `audit_breaks_not_counted` | Przerwy w kontroli nie wliczaja sie do limitu 30 dni | Przerwy |
| `jdg.ord.a165.r6` | `audit_no_second_audit_same_scope` | Zakaz powtarzania kontroli w tym samym zakresie w 3 lata (chyba ze nowe fakty) | Zakaz |
| `jdg.ord.a165.r7` | `audit_no_second_audit_exception_fraud` | Nowe fakty, podejrzenie oszustwa -> mozliwa powtorna kontrola | Wylaczenie |
| `jdg.ord.a168.r1` | `audit_taxpayer_rights` | Prawa JDG podczas kontroli: obecnosc, pomoc prawnika, skladanie wyjasnien | Prawa |
| `jdg.ord.a168.r2` | `audit_taxpayer_obligations` | Obowiazki: udostepnienie dokumentow, dostep do lokalu, udzielenie informacji | Obowiazki |
| `jdg.ord.a168.r3` | `audit_taxpayer_refusal_consequences` | Odmowa udostepnienia -> sankcja: 5000 PLN grzywny | Sankcja |
| `jdg.ord.a170.r1` | `audit_protocol_mandatory` | Obowiazek sporzadzenia protokolu z kontroli | Protokol |
| `jdg.ord.a170.r2` | `audit_protocol_deadline_14_days` | Protokol w 14 dni od zakonczenia kontroli | Termin |
| `jdg.ord.a170.r3` | `audit_protocol_objections_14_days` | Podatnik ma 14 dni na wniesienie zastezen do protokolu | Zastezenia |
| `jdg.ord.a170.r4` | `audit_protocol_objections_response` | US rozpatruje zastezenia w 14 dni | Rozpatrzenie |
| `jdg.ord.a171.r1` | `audit_customs_examination` | Kontrola celno-skarbowa: uprawnienia szersze (rewizja, zatrzymanie towaru) | Szersze uprawnienia |
| `jdg.ord.a171.r2` | `audit_customs_control_examination_scope` | Mozliwosc kontroli srodkow transportu, towarow, dokumentow przewozowych | Zakres |
| `jdg.ord.a172.r1` | `audit_customs_control_period_3_months` | Kontrola celno-skarbowa max 3 miesiace (przedluzenie do 6) | Czas |
| `jdg.ord.a173.r1` | `audit_results_assessment_decision` | Wynik kontroli -> decyzja wymiarowa (okreslenie zobowiazania podatkowego) | Decyzja |
| `jdg.ord.a173.r2` | `audit_results_settlement_agreement` | Porozumienie w sprawie ustalenia stanu faktycznego (protokol zgodny) | Porozumienie |
| `jdg.ord.a174.r1` | `audit_appeal_to_admin_court` | Od wyniku kontroli -> skarga do Wojewodzkiego Sadu Administracyjnego (WSA) | Sad |

### 3.9 Art. 199a: Klauzula przeciwko unikaniu opodatkowania (GAAR) (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a199a.r1` | `gaar_detection_artificial_structure` | Czynnosc gospodarcza bez ekonomicznego uzasadnienia, stworzona dla oszczednosci podatkowych | Klauzula |
| `jdg.ord.a199a.r2` | `gaar_artificiality_tests` | Testy: czy czynnosc jest zgodna z celem ustawy, czy podatnik mial biznesowy cel | Testy |
| `jdg.ord.a199a.r3` | `gaar_economic_substance_test` | Test substancji ekonomicznej: czy czynnosc przynosi realne korzysci ekonomiczne | Test |
| `jdg.ord.a199a.r4` | `gaar_tax_benefit_test` | Test korzysci podatkowej: czy glownym celem jest oszczednosc podatkowa | Test |
| `jdg.ord.a199a.r5` | `gaar_consequences_recharacterization` | Zakwestionowanie skutkow: US pomija czynnosc i opodatkowuje wedlug stanu rzeczywistego | Konsekwencja |
| `jdg.ord.a199a.r6` | `gaar_additional_tax_40pct` | Dodatkowe zobowiazanie podatkowe: 40% (lub 30% dla osoby fizycznej jesli wspolpraca) | Sankcja |
| `jdg.ord.a199a.r7` | `gaar_additional_tax_reduction_cooperation` | Zmniejszenie do 20% gdy podatnik przedlozyl oswiadczenie o schemacie MDR | Redukcja |
| `jdg.ord.a199a.r8` | `gaar_opinia_zabezpieczajaca` | JDG moze wystapic o opinie zabezpieczajaca (czy GAAR nie bedzie stosowany) | Opinia |
| `jdg.ord.a199a.r9` | `gaar_opinia_fee_20k` | Oplata za opinie zabezpieczajaca: 20 000 PLN | Oplata |
| `jdg.ord.a199a.r10` | `gaar_small_business_exception` | JDG o przychodach < 10M EUR - klauzula stosowana tylko do istotnych korzysci > 50k PLN | Wylaczenie |

### 3.10 Art. 208-219: Decyzje podatkowe i odvolania (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a208.r1` | `decision_first_instance` | Decyzja naczelnika US jako I instancja | I instancja |
| `jdg.ord.a208.r2` | `decision_appeal_authority` | Dyrektor IAS jako II instancja (odvolawcza) | II instancja |
| `jdg.ord.a208.r3` | `decision_appeal_deadline_14_days` | Termin na odvolanie: 14 dni od doręczenia decyzji | Termin |
| `jdg.ord.a208.r4` | `decision_appeal_form` | Odvolanie: pisemne, z uzasadnieniem, adresowane do II instancji | Forma |
| `jdg.ord.a208.r5` | `decision_appeal_suspension_automatic` | Odvolanie wstrzymuje wykonanie decyzji | Suspensywnosc |
| `jdg.ord.a210.r1` | `decision_required_elements` | Elementy decyzji: data, organ, strona, podstawa prawna, sentencja, uzasadnienie | Wymogi |
| `jdg.ord.a210.r2` | `decision_justification_standard` | Uzasadnienie: stan faktyczny, dowody, ocena prawna, wybor srodka | Uzasadnienie |
| `jdg.ord.a213.r1` | `decision_renewal_of_proceedings` | Wznowienie postepowania: nowe fakty, falszywe dokumenty, bledy orzeczenia ETS | Wznowienie |
| `jdg.ord.a213.r2` | `decision_renewal_3_months` | Wznowienie w 3 miesiace od powziecia informacji o nowych faktach (max 5 lat) | Termin |
| `jdg.ord.a213.r3` | `decision_renewal_deadline_absolute` | Bezwzgledny termin wznowienia: 5 lat od doręczenia decyzji | Termin |

### 3.11 Art. 220-226: Odsetki, egzekucja, zabezpieczenie (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ord.a220.r1` | `tax_arrears_enforcement_title` | Zaplata nie nadeszla -> tytul wykonawczy (upomnienie + egzekucja) | Egzekucja |
| `jdg.ord.a220.r2` | `tax_arrears_enforcement_7_days` | Upomnienie: 7 dni od doręczenia na zaplate | Termin upomnienia |
| `jdg.ord.a221.r1` | `tax_arrears_enforcement_costs` | Koszty upomnienia: 16 PLN (lub 22.40 PLN w 2024) | Koszty |
| `jdg.ord.a222.r1` | `tax_arrears_enforcement_bailiff` | Egzekucja administracyjna: zajecie rachunku, wierzytelnosci, majatku | Sposoby |
| `jdg.ord.a222.r2` | `tax_arrears_bank_account_seizure` | Zajecie rachunku bankowego -> blokada srodkow do wysokosci zaleglosci | Blokada |
| `jdg.ord.a222.r3` | `tax_arrears_wage_seizure` | Zajecie wynagrodzenia (gdy JDG ma pracownikow) -> z wierzytelnosci | Zajecie |
| `jdg.ord.a222.r4` | `tax_arrears_movable_property_seizure` | Zajecie ruchomosci (samochod, sprzet) -> opis i oszacowanie | Ruchomosci |
| `jdg.ord.a223.r1` | `tax_arrears_enforcement_protected_assets` | Mienie wolne od egzekucji: ubranie, zywnosc, narzedzia pracy do 2k | Ochrona |
| `jdg.ord.a224.r1` | `tax_arrears_mortgage_tax` | Hipoteka przymusowa na nieruchomosci JDG dla zabezpieczenia zaleglosci | Hipoteka |
| `jdg.ord.a225.r1` | `tax_arrears_statute_of_limitations_enforcement` | Przedawnienie egzekucji: 5 lat od zakonczenia postepowania | Przedawnienie egzekucji |

---

## CZĘŚĆ IV: USTAWA O SYSTEMIE UBEZPIECZEN SPOLECZNYCH — ZUS (195 REGUL)

### 4.1 Art. 6-13: Podleganie ubezpieczeniom spolecznym (~20 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.zus.a6.r1` | `social_insurance_obligation_entrepreneur` | Osoba prowadzaca JDG podlega obowiazkowo ubezpieczeniom emerytalnemu i rentowym | Obowiazkowe |
| `jdg.zus.a6.r2` | `social_insurance_obligation_self_employed` | Osoba wspolpracujaca przy JDG -> obowiazkowo ubezpieczona | Wspolpracownik |
| `jdg.zus.a6.r3` | `social_insurance_voluntary_sickness` | Ubezpieczenie chorobowe dla JDG: dobrowolne | Dobrowolne |
| `jdg.zus.a6.r4` | `social_insurance_voluntary_pension_for_low` | Ubezpieczenie emerytalne i rentowe dobrowolne dla JDG ponizej progu | Dobrowolne |
| `jdg.zus.a6.r5` | `social_insurance_employee_hired` | Pracownik zatrudniony przez JDG -> obowiazkowe wszystkie ubezpieczenia | Pracownik |
| `jdg.zus.a6.r6` | `social_insurance_contract_of_mandate` | Umowa zlecenia (jezeli zleceniobiorca jest bez etatu) -> obowiazkowe | Zlecenie |
| `jdg.zus.a7.r1` | `social_insurance_multiple_titles` | JDG majaca etat -> ubezpieczenia z tytulu etatu, JDG dobrowolne | Wielotytulowosc |
| `jdg.zus.a8.r1` | `social_insurance_scope_pension` | Ubezpieczenie emerytalne: obowiazkowe dla JDG | Emerytalne |
| `jdg.zus.a8.r2` | `social_insurance_scope_rent` | Ubezpieczenie rentowe: obowiazkowe dla JDG | Rentowe |
| `jdg.zus.a8.r3` | `social_insurance_scope_accident` | Ubezpieczenie wypadkowe: obowiazkowe dla JDG (placi JDG za siebie) | Wypadkowe |
| `jdg.zus.a8.r4` | `social_insurance_scope_fund_pracy` | Fundusz Pracy: obowiazkowe dla JDG (jesli nie ma etatu) | Fundusz Pracy |
| `jdg.zus.a8.r5` | `social_insurance_scope_fgsp` | Fundusz Gwarantowanych Swiadczen Pracowniczych: jak FP | FGSP |
| `jdg.zus.a9.r1` | `social_insurance_exclusion_retirement_pension` | JDG pobierajaca emeryture/rente -> zwolniona z obowiazku ZUS (opcjonalnie) | Wyłączenie |
| `jdg.zus.a9.r2` | `social_insurance_exclusion_childcare_3_years` | JDG na urlopie wychowawczym -> zwolniona z obowiazku | Wyłączenie |
| `jdg.zus.a9.r3` | `social_insurance_exclusion_conscription` | JDG w sluzbie wojskowej -> zwolniona | Wyłączenie |
| `jdg.zus.a10.r1` | `social_insurance_start_date` | Obowiazek ubezpieczenia od dnia rozpoczecia JDG | Poczatek |
| `jdg.zus.a10.r2` | `social_insurance_cessation_date` | Koniec obowiazku z dniem zaprzestania JDG | Koniec |
| `jdg.zus.a11.r1` | `social_insurance_sickness_voluntary_declaration` | Zgloszenie do dobrowolnego ubezpieczenia chorobowego: ZUS ZUA | Zgloszenie |
| `jdg.zus.a12.r1` | `social_insurance_sickness_waiting_90_days` | Okres wyczekiwania na zasilek chorobowy: 90 dni (JDG) | Okres wyczekiwania |
| `jdg.zus.a13.r1` | `social_insurance_annual_reconciliation` | Roczne rozliczenie skladek ZUS w deklaracji rocznej ZUS DRA | Roczne |

### 4.2 Stopy procentowe skladek ZUS dla JDG (~15 rules)

| ID | Nazwa reguly | Rodzaj skladki | Stawka | Podstawa prawna |
|:--:|-------------|:-------------:|:-----:|:---------------:|
| `jdg.zus.rate.r1` | `zus_rate_pension_19_52pct` | Emerytalna (JDG) | 19.52% | Art. 22 ustawy SUS |
| `jdg.zus.rate.r2` | `zus_rate_rent_8_0pct` | Rentowa (JDG) | 8.00% | Art. 22 ustawy SUS |
| `jdg.zus.rate.r3` | `zus_rate_sickness_2_45pct` | Chorobowa (dobrowolna, JDG) | 2.45% | Art. 22 ustawy SUS |
| `jdg.zus.rate.r4` | `zus_rate_accident_0_67_3_33pct` | Wypadkowa (zalezy od PKD, JDG) | 0.67%-3.33% | Art. 22 ustawy SUS |
| `jdg.zus.rate.r5` | `zus_rate_fund_pracy_2_45pct` | Fundusz Pracy | 2.45% | Art. 104 ustawy o promocji zatrudnienia |
| `jdg.zus.rate.r6` | `zus_rate_fgsp_0_10pct` | FGSP | 0.10% | Art. 25 ustawy o FGSP |
| `jdg.zus.rate.r7` | `zus_rate_employee_pension_9_76pct` | Emerytalna pracownika | 9.76% | Art. 16 ustawy SUS |
| `jdg.zus.rate.r8` | `zus_rate_employee_rent_4_5pct` | Rentowa pracownika | 4.50% | Art. 16 ustawy SUS |
| `jdg.zus.rate.r9` | `zus_rate_employee_sickness_2_45pct` | Chorobowa pracownika | 2.45% | Art. 16 ustawy SUS |
| `jdg.zus.rate.r10` | `zus_rate_employer_pension_9_76pct` | Emerytalna platnika za pracownika | 9.76% | Art. 16 ustawy SUS |
| `jdg.zus.rate.r11` | `zus_rate_employer_rent_6_5pct` | Rentowa platnika za pracownika | 6.50% | Art. 16 ustawy SUS |
| `jdg.zus.rate.r12` | `zus_rate_employer_accident_0_67_3_33pct` | Wypadkowa za pracownika | 0.67%-3.33% | Art. 16 ustawy SUS |
| `jdg.zus.rate.r13` | `zus_rate_employer_fp_2_45pct` | Fundusz Pracy za pracownika | 2.45% | Art. 104 ustawy o promocji zatrudnienia |
| `jdg.zus.rate.r14` | `zus_rate_employer_fgsp_0_10pct` | FGSP za pracownika | 0.10% | Art. 25 ustawy o FGSP |
| `jdg.zus.rate.r15` | `zus_rate_total_jdg_min` | Laczna minimalna skladka ZUS dla JDG (emeryt + rent + chor + wypad + FP + FGSP) | ~30-32% podstawy | Suma skladek |

### 4.3 Podstawa wymiaru skladek ZUS dla JDG (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.zus.base.r1` | `zus_base_declared_60pct` | Podstawa = zadeklarowana kwota, nie nizsza niz 60% prognozowanego przecietnego wynagrodzenia | Minimum |
| `jdg.zus.base.r2` | `zus_base_minimum_2024` | Minimalna podstawa (60% prognozowanego przecietnego wynagrodzenia) | ~4 800 PLN (2025) |
| `jdg.zus.base.r3` | `zus_base_maximum_30x` | Maksymalna podstawa: 30-krotnosc prognozowanego przecietnego wynagrodzenia | ~234 000 PLN (2025) |
| `jdg.zus.base.r4` | `zus_base_30x_cutoff` | Po przekroczeniu 30x w danym roku -> skladki ZUS nie sa juz naliczane (emeryt+rent) | Odciecie |
| `jdg.zus.base.r5` | `zus_base_first_year_freedom` | W pierwszym roku JDG: podstawa 30% minimalnego wynagrodzenia (ulga na start) | Obnizona |
| `jdg.zus.base.r6` | `zus_base_after_24_months` | Po 24 miesiacach od rozpoczecia: podstawa 60% prognozowanego wynagrodzenia | Standard |
| `jdg.zus.base.r7` | `zus_base_preferential_24_months` | Preferencyjny ZUS przez 24 miesiace (maly ZUS) | ~500 PLN |
| `jdg.zus.base.r8` | `zus_base_declaration_change_possible` | Mozliwosc zmiany zadeklarowanej podstawy (do maksimum) | Zmiana |
| `jdg.zus.base.r9` | `zus_base_sickness_sole_proprietor` | Podstawa chorobowego = srednia podstaw wymiaru z 12 miesiecy | Chorobowe |
| `jdg.zus.base.r10` | `zus_base_sickness_ceiling` | Podstawa zasiłku chorobowego ograniczona do 250% prognozowanego wynagrodzenia | Limit |
| `jdg.zus.base.r11` | `zus_base_annual_recalculation` | Roczna korekta skladek (jesli podstawa byla nizsza niz faktyczny przychod < 60%) | Roczne |
| `jdg.zus.base.r12` | `zus_base_months_without_income` | Miesiace bez przychodu -> podstawa minimalna (60% prognozowanego) | Minimum |
| `jdg.zus.base.r13` | `zus_base_sick_leave_reduction` | Chorobowe powyzej 33 dni (lub 14 dla JDG >50 lat) -> ZUS placi zasilek, skladki zawieszone | Zawieszenie |
| `jdg.zus.base.r14` | `zus_base_pregnancy_protection` | Ciąza -> ochrona, ZUS placi zasilek macierzynski przez rok | Macierzynski |
| `jdg.zus.base.r15` | `zus_base_new_business_2_year_pref` | Nowa JDG: preferencyjny ZUS przez 2 lata (nie dotyczy jesli juz prowadzila dzialalnosc) | Warunek |

### 4.4 Maly ZUS Plus (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.zus.small_plus.r1` | `small_zus_plus_eligibility` | JDG z przychodem rocznym < 120 000 PLN (2025) w poprzednim roku | Kwalifikacja |
| `jdg.zus.small_plus.r2` | `small_zus_plus_base_calculation` | Podstawa = 30% minimalnego wynagrodzenia x (przychod / 120 000) | Wzor |
| `jdg.zus.small_plus.r3` | `small_zus_plus_min_base` | Minimalna podstawa: 30% minimalnego wynagrodzenia | Minimum |
| `jdg.zus.small_plus.r4` | `small_zus_plus_max_base` | Maksymalna podstawa: 60% prognozowanego przecietnego wynagrodzenia | Maksimum |
| `jdg.zus.small_plus.r5` | `small_zus_plus_first_year_start` | W pierwszym roku dzialalnosci -> maly ZUS+ przez 12 miesiecy (brak limitu przychodu) | Pierwszy rok |
| `jdg.zus.small_plus.r6` | `small_zus_plus_application_annual` | ZUS ZEA: zgloszenie do malego ZUS+ w ciagu 7 dni od rozpoczecia | Zgloszenie |
| `jdg.zus.small_plus.r7` | `small_zus_plus_loss_of_right_120k` | Przekroczenie 120 000 PLN przychodu -> utrata prawa od nastepnego roku | Utrata |
| `jdg.zus.small_plus.r8` | `small_zus_plus_retroactive_correction` | W ciagu roku -> korekta gdy przychod = 120k+ (za miesiace calego roku) | Korekta |
| `jdg.zus.small_plus.r9` | `small_zus_plus_excluded_activities` | Wykluczone: wspolnicy sp. jawnej, komandytowej, zarzad, czlonkowie rad nadzorczych | Wykluczenie |
| `jdg.zus.small_plus.r10` | `small_zus_plus_not_with_preferential_24` | Maly ZUS+ LUB preferencyjny ZUS (24 miesiace) -> nie mozna lacznie | Alternatywa |
| `jdg.zus.small_plus.r11` | `small_zus_plus_sickness_optional` | Ubezpieczenie chorobowe w malym ZUS+ -> dobrowolne (dodatkowy koszt) | Dobrowolne |
| `jdg.zus.small_plus.r12` | `small_zus_plus_annual_reconciliation_july` | Roczne rozliczenie do 31 lipca nastepnego roku (korekta ZUS DRA) | Termin |
| `jdg.zus.small_plus.r13` | `small_zus_plus_over_limit_sanctions` | Brak korekty po przekroczeniu -> sankcje: odsetki + naliczenie pelnych skladek | Sankcje |
| `jdg.zus.small_plus.r14` | `small_zus_plus_health_insurance_base` | Podstawa skladki zdrowotnej = zadeklarowana (maly ZUS+ nie wplywa na zdrowotna) | Zdrowotna |
| `jdg.zus.small_plus.r15` | `small_zus_plus_cessation_annual_obligation` | Koniec malego ZUS+ po uplywie roku podatkowego | Koniec |

### 4.5 Ulga na start (pierwsze 6 miesiecy) (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.zus.start.r1` | `start_up_relief_6_months` | Nowa JDG: zwolnienie ze skladek ZUS przez pierwsze 6 miesiecy | Zwolnienie |
| `jdg.zus.start.r2` | `start_up_relief_condition_first_business` | Zwolnienie dotyczy TYLKO pierwszej dzialalnosci (nie jest JDG po wznowieniu) | Warunek |
| `jdg.zus.start.r3` | `start_up_relief_no_previous_business_60_months` | JDG nie prowadzila dzialalnosci w ostatnich 60 miesiacach | Warunek |
| `jdg.zus.start.r4` | `start_up_relief_health_insurance_excluded` | Ulga na start NIE obejmuje skladki zdrowotnej (trzeba placic) | Wylaczenie |
| `jdg.zus.start.r5` | `start_up_relief_voluntary_insurance_option` | Mozliwosc dobrowolnego ubezpieczenia emerytalno-rentowego w okresie ulgi | Opcja |
| `jdg.zus.start.r6` | `start_up_relief_voluntary_sickness` | Mozliwosc dobrowolnego ubezpieczenia chorobowego | Opcja |
| `jdg.zus.start.r7` | `start_up_relief_transition_to_preferential_24` | Po 6 miesiacach -> automatyczne przejscie na preferencyjny ZUS (24 miesiace) | Przejscie |
| `jdg.zus.start.r8` | `start_up_relief_cessation_before_6_months` | Zawieszenie przed 6 miesiacami -> ulga nie przysluguje za miesiace zawieszenia | Zawieszenie |
| `jdg.zus.start.r9` | `start_up_relief_resumption_60_months` | Wznowienie po >60 miesiacach przerwy -> ponowna ulga | Ponowna ulga |
| `jdg.zus.start.r10` | `start_up_relief_sickness_benefit_during_ulga` | Chorobowe w okresie ulgi -> jesli zgloszone dobrowolne chorobowe | Swiadczenie |

### 4.6 Terminy platnosci ZUS i deklaracje (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.zus.deadline.r1` | `zus_deadline_monthly_15th` | Skladki ZUS za dany miesiac platne do 15. dnia nastepnego miesiaca | Termin |
| `jdg.zus.deadline.r2` | `zus_deadline_15th_calendar` | Termin 15. dnia miesiaca za miesiac poprzedni (w cywilu: dzien 15-tego) | Termin |
| `jdg.zus.deadline.r3` | `zus_deadline_weekend_shift` | Jesli 15. wypada w sobote/niule -> termin nastepny dzien roboczy | Przesuniecie |
| `jdg.zus.deadline.r4` | `zus_deadline_health_by_20th` | Skladka zdrowotna: do 20. dnia nastepnego miesiaca | Termin |
| `jdg.zus.deadline.r5` | `zus_deadline_health_20th_shift` | Przesuniecie jak dla 15. (weekend) | Przesuniecie |
| `jdg.zus.deadline.r6` | `zus_declaration_dra_monthly` | Deklaracja ZUS DRA miesieczna: do 15. dnia nastepnego miesiaca | Deklaracja |
| `jdg.zus.deadline.r7` | `zus_declaration_zua_new_employee_7_days` | Zgloszenie nowego pracownika do ZUS: w 7 dni od rozpoczecia pracy | Zgloszenie |
| `jdg.zus.deadline.r8` | `zus_declaration_zya_withdrawal_7_days` | Wyrejestrowanie z ZUS: w 7 dni od zakonczenia tytulu | Wyrejestrowanie |
| `jdg.zus.deadline.r9` | `zus_declaration_annual_rozliczenie` | Deklaracja roczna ZUS DRA do 31 lipca nastepnego roku | Roczne |
| `jdg.zus.deadline.r10` | `zus_declaration_annual_correction` | Korekta deklaracji rocznej: po terminie -> odsetki | Korekta |

### 4.7 Zawieszenie dzialalnosci a ZUS (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.zus.suspension.r1` | `zus_suspension_cessation_of_obligation` | Zawieszenie JDG -> ustaje obowiazek oplacania skladek ZUS od nastepnego dnia | Ustanie |
| `jdg.zus.suspension.r2` | `zus_suspension_min_30_days` | Zawieszenie co najmniej 30 dni -> brak skladek ZUS za caly okres | Warunek |
| `jdg.zus.suspension.r3` | `zus_suspension_health_insurance` | Skladka zdrowotna: zwolnienie w okresie zawieszenia (jesli brak przychodu) | Zwolnienie |
| `jdg.zus.suspension.r4` | `zus_suspension_health_income_during` | Przychod w okresie zawieszenia (do pelnej skladki) -> obowiazek oplacenia | Wyjatek |
| `jdg.zus.suspension.r5` | `zus_suspension_voluntary_continuation` | Mozliwosc kontynuacji ubezpieczenia emerytalno-rentowego w okresie zawieszenia | Opcja |
| `jdg.zus.suspension.r6` | `zus_suspension_return_obligation` | Wznowienie -> obowiazek ZUS od dnia wznowienia | Wznowienie |
| `jdg.zus.suspension.r7` | `zus_suspension_zua_withdrawal` | Wyrejestrowanie z ZUS przy zawieszeniu (ZUS ZWUA) | Formalnosc |
| `jdg.zus.suspension.r8` | `zus_suspension_re_registration_zua` | Ponowne zgloszenie przy wznowieniu (ZUS ZUA) | Formalnosc |
| `jdg.zus.suspension.r9` | `zus_suspension_annual_during_suspension` | Deklaracja roczna ZUS DRA za rok, w ktorym bylo zawieszenie | Deklaracja |
| `jdg.zus.suspension.r10` | `zus_suspension_sickness_benefit_during` | Chorobowe w okresie zawieszenia -> jesli dobrowolnie kontynuowane | Swiadczenie |

### 4.8 Swiadczenia z ZUS dla JDG (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.zus.benefit.r1` | `zus_benefit_pension_calculation` | Emerytura = suma skladek zewidencjonowanych na koncie / srednie dalsze trwanie zycia | Emerytura |
| `jdg.zus.benefit.r2` | `zus_benefit_pension_minimum` | Emerytura minimalna (gdy wyliczona < minimalnej) -> dopelnienie do minimalnej | Minimum |
| `jdg.zus.benefit.r3` | `zus_benefit_pension_early_if_job_before` | Wczesniejsza emerytura: prace w szczegolnych warunkach -> mozliwe | Wczesniejsza |
| `jdg.zus.benefit.r4` | `zus_benefit_rent_disability` | Renta z tytulu niezdolnosci do pracy -> orzeczenie lekarza orzecznika ZUS | Renta |
| `jdg.zus.benefit.r5` | `zus_benefit_rent_partial_or_full` | Renta calkowita (cala niezdolnosc) lub czesciowa (czesciowa niezdolnosc) | Stopnie |
| `jdg.zus.benefit.r6` | `zus_benefit_sickness_67pct` | Zasilek chorobowy: 80% podstawy wymiaru (lub 67% po 33 dniach) | Stawka |
| `jdg.zus.benefit.r7` | `zus_benefit_sickness_self_pay_33_days` | JDG sama placi zasilek za pierwsze 33 dni (lub 14 dni dla >50 lat) w roku | Samoplatny |
| `jdg.zus.benefit.r8` | `zus_benefit_sickness_zus_pays_after_33` | Od 34. dnia -> ZUS placi zasilek chorobowy | ZUS |
| `jdg.zus.benefit.r9` | `zus_benefit_sickness_max_182_days` | Maksymalny okres zasilku chorobowego: 182 dni (270 dla gruzlicy) | Max |
| `jdg.zus.benefit.r10` | `zus_benefit_maternity_100pct` | Zasilek macierzynski: 100% podstawy wymiaru przez 52 tygodnie | Macierzynski |
| `jdg.zus.benefit.r11` | `zus_benefit_maternity_20_weeks_base` | Podstawowy urlop macierzynski: 20 tygodni (urlop rodzicielski: 32 tygodnie) | Okres |
| `jdg.zus.benefit.r12` | `zus_benefit_rehabilitation_benefit` | Swiadczenie rehabilitacyjne: po wyczerpaniu zasilku, przez 12 miesiecy | Rehabilitacyjne |
| `jdg.zus.benefit.r13` | `zus_benefit_rehabilitation_90pct_then_75pct` | Swiadczenie: 90% podstawy przez 3 miesiace, 75% przez pozostale | Stawka |
| `jdg.zus.benefit.r14` | `zus_benefit_family_allowances` | Zasilki rodzinne, becikowe (swiadczenia rodzinne) -> kryterium dochodowe | Rodzinne |
| `jdg.zus.benefit.r15` | `zus_benefit_survivor_pension` | Renta rodzinna: smierc zywiciela -> uprawnieni: malzonek, dzieci, rodzice | Renta rodzinna |

---

## CZĘŚĆ V: USTAWA O RYCZALCIE OD PRZYCHODÓW EWIDENCJONOWANYCH (220 REGUL)

### 5.1 Art. 2-4: Zakres podmiotowy i warunki (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ryc.a2.r1` | `lump_sum_eligible_entrepreneur` | Osoba fizyczna prowadzaca JDG moze wybrac ryczalt | Mozliwosc |
| `jdg.ryc.a2.r2` | `lump_sum_eligible_scope_all_revenue` | Przychody z dzialalnosci gospodarczej (wszystkie PKD) | Zakres |
| `jdg.ryc.a2.r3` | `lump_sum_excluded_services_former_employer` | Wykluczone: uslugi na rzecz bylnego pracodawcy (te same co na etacie) | Wylaczenie |
| `jdg.ryc.a2.r4` | `lump_sum_excluded_lawyers` | Wykluczone: adwokaci, radcowie prawni, notariusze, doradcy podatkowi | Wylaczenie |
| `jdg.ryc.a2.r5` | `lump_sum_excluded_pharmacies` | Wykluczone: apteki (nie dotyczy) | Wylaczenie |
| `jdg.ryc.a2.r6` | `lump_sum_excluded_architects_engineers` | Wykluczone: architekci, inzynierowie budownictwa (nie dotyczy) | Wylaczenie |
| `jdg.ryc.a2.r7` | `lump_sum_excluded_healthcare_self_employed` | Wykluczone: osoby swiadczace uslugi medyczne (z wyjatkami) | Wylaczenie |
| `jdg.ryc.a2.r8` | `lump_sum_excluded_restaurants_bars` | Wykluczone: restauracje, bary, catering (nie dotyczy) | Wylaczenie |
| `jdg.ryc.a2.r9` | `lump_sum_excluded_retirement_pensioners` | Wykluczone: JDG na emeryturze/rencie (opcjonalnie) | Wylaczenie |
| `jdg.ryc.a2.r10` | `lump_sum_excluded_multi_member_companies` | Wykluczone: wspolnik sp. jawnej, komandytowej, czlonek zarzadu | Wylaczenie |
| `jdg.ryc.a2.r11` | `lump_sum_excluded_tax_capital_groups` | Wykluczone: podatnikowe grupy kapitalowe (nie dotyczy JDG) | Wylaczenie |
| `jdg.ryc.a2.r12` | `lump_sum_excluded_partnerships` | Wykluczone: spolki (JDG moze, ale nie w formie spolki) | Wylaczenie |
| `jdg.ryc.a3.r1` | `lump_sum_selection_deadline_20_january` | Wybor ryczaltu: oswiadczenie do 20 stycznia roku podatkowego | Termin |
| `jdg.ryc.a3.r2` | `lump_sum_selection_new_business_first_year` | Nowa JDG: oswiadczenie przy rejestracji (lub do 20 dnia miesiaca po pierwszym przychodzie) | Nowa dzialalnosc |
| `jdg.ryc.a3.r3` | `lump_sum_selection_loss_of_right` | Utrata prawa do ryczaltu w trakcie roku -> przejscie na skale od nastepnego miesiaca | Utrata |

### 5.2 Art. 6-8: Stawki ryczaltu wedlug branz (~30 rules)

| ID | Nazwa reguly | Branza/PKD | Stawka | Podstawa prawna |
|:--:|-------------|:---------:|:-----:|:---------------:|
| `jdg.ryc.rate.r1` | `lump_rate_17pct_wolne_zawody` | Wolne zawody (lekarze, dentyci, weterynarze, architekci, inzynierowie, tlumacze) | 17% | Art. 12 ust. 1 pkt 5 |
| `jdg.ryc.rate.r2` | `lump_rate_17pct_developers_maklersi` | Posrednictwo w obrocie nieruchomosciami, maklerzy | 17% | Art. 12 ust. 1 pkt 5 |
| `jdg.ryc.rate.r3` | `lump_rate_17pct_tax_advisors_accountants` | Doradztwo podatkowe, ksiegowosc, rachunkowosc | 17% | Art. 12 ust. 1 pkt 5 |
| `jdg.ryc.rate.r4` | `lump_rate_17pct_it_consulting` | Doradztwo informatyczne, zarzadcze, biznesowe | 17% | Art. 12 ust. 1 pkt 5 |
| `jdg.ryc.rate.r5` | `lump_rate_15pct_repair_maintenance` | Naprawa i konserwacja pojazdow, maszyn, urzadzen | 15% | Art. 12 ust. 1 pkt 4 |
| `jdg.ryc.rate.r6` | `lump_rate_15pct_construction_works` | Roboty budowlane, montaz, instalacje | 15% | Art. 12 ust. 1 pkt 4 |
| `jdg.ryc.rate.r7` | `lump_rate_15pct_cleaning_services` | Uslugi sprzatania, czyszczenia, dezynfekcji | 15% | Art. 12 ust. 1 pkt 4 |
| `jdg.ryc.rate.r8` | `lump_rate_15pct_know_how_licenses` | Przychody z praw autorskich, patentow, know-how (nie IP Box) | 15% | Art. 12 ust. 1 pkt 4 |
| `jdg.ryc.rate.r9` | `lump_rate_14pct_it_programming` | Uslugi zwiazane z oprogramowaniem (programowanie, projektowanie stron) | 14% | Art. 12 ust. 1 pkt 3b |
| `jdg.ryc.rate.r10` | `lump_rate_14pct_it_consulting_excluded` | Wylaczone: doradztwo informatyczne (17%) | Wylaczenie |
| `jdg.ryc.rate.r11` | `lump_rate_14pct_it_support` | Uslugi zwiazane z oprogramowaniem: pomoc techniczna, hosting, utrzymanie | 14% | Art. 12 ust. 1 pkt 3b |
| `jdg.ryc.rate.r12` | `lump_rate_14pct_data_processing` | Przetwarzanie danych, zarzadzanie stronami internetowymi | 14% | Art. 12 ust. 1 pkt 3b |
| `jdg.ryc.rate.r13` | `lump_rate_12pct_rental_property` | Najem nieruchomosci (prywatny, nie w ramach JDG) | 12% | Art. 12 ust. 1 pkt 3a |
| `jdg.ryc.rate.r14` | `lump_rate_12pct_rental_movable` | Najem ruchomosci (sprzetu, pojazdow) | 12% | Art. 12 ust. 1 pkt 3a |
| `jdg.ryc.rate.r15` | `lump_rate_12pct_commission_agency` | Dzialalnosc agencyjna, komisowa, maklerska (nie nieruchomosci) | 12% | Art. 12 ust. 1 pkt 3a |
| `jdg.ryc.rate.r16` | `lump_rate_10pct_restaurants_catering` | Uslugi gastronomiczne, catering, bary | 10% | Art. 12 ust. 1 pkt 3 |
| `jdg.ryc.rate.r17` | `lump_rate_10pct_hairdressing_beauty` | Uslugi fryzjerskie, kosmetyczne, pielęgnacyjne | 10% | Art. 12 ust. 1 pkt 3 |
| `jdg.ryc.rate.r18` | `lump_rate_10pct_transport_passenger_goods` | Transport pasazerski i towarowy (taxi, dostawy) | 10% | Art. 12 ust. 1 pkt 3 |
| `jdg.ryc.rate.r19` | `lump_rate_10pct_education_training` | Uslugi edukacyjne, szkoleniowe (pozostale) | 10% | Art. 12 ust. 1 pkt 3 |
| `jdg.ryc.rate.r20` | `lump_rate_10pct_healthcare_outpatient` | Opieka medyczna ambulatoryjna (lekarze specjalisci) | 10% | Art. 12 ust. 1 pkt 3 |
| `jdg.ryc.rate.r21` | `lump_rate_8_5pct_manufacturing` | Dzialalnosc wytworcza, produkcja przemyslowa | 8.5% | Art. 12 ust. 1 pkt 2 |
| `jdg.ryc.rate.r22` | `lump_rate_8_5pct_construction_building` | Roboty budowlane (budowa, remont, modernizacja) | 8.5% | Art. 12 ust. 1 pkt 2 |
| `jdg.ryc.rate.r23` | `lump_rate_8_5pct_trade_wholesale` | Handel hurtowy | 8.5% | Art. 12 ust. 1 pkt 2 |
| `jdg.ryc.rate.r24` | `lump_rate_8_5pct_trade_retail` | Handel detaliczny | 8.5% | Art. 12 ust. 1 pkt 2 |
| `jdg.ryc.rate.r25` | `lump_rate_8_5pct_tourism_hotel` | Uslugi hotelarskie, turystyczne, noclegowe | 8.5% | Art. 12 ust. 1 pkt 2 |
| `jdg.ryc.rate.r26` | `lump_rate_5_5pct_agriculture` | Dzialalnosc rolnicza, lesna, rybacka (nie bedaca dzialem specjalnym) | 5.5% | Art. 12 ust. 1 pkt 1 |
| `jdg.ryc.rate.r27` | `lump_rate_5_5pct_manufacturing_agricultural` | Przetworstwo produktow rolnych, spozywczych | 5.5% | Art. 12 ust. 1 pkt 1 |
| `jdg.ryc.rate.r28` | `lump_rate_3pct_trade_food` | Handel artykulami spozywczymi (sklepy spozywcze, warzywniaki) | 3% | Art. 12 ust. 1 pkt 1a |
| `jdg.ryc.rate.r29` | `lump_rate_2pct_services_online_casino` | Uslugi swiadczone elektronicznie (gry, zaklady online, streaming) | 2% | Art. 12 ust. 1 pkt 0a |
| `jdg.ryc.rate.r30` | `lump_rate_standard_exception_rule` | Jesli brak PKD na liscie -> stawka 12% (standard) | Domyslna 12% |

### 5.3 Art. 12-14: Obliczanie ryczaltu i ewidencja (~20 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ryc.calc.r1` | `lump_tax_revenue_minus_zus` | Podstawa = przychod - skladki ZUS spoleczne zaplacone w roku | Obliczenie |
| `jdg.ryc.calc.r2` | `lump_tax_revenue_x_rate` | Podatek = podstawa x stawka ryczaltu (brak KUP, brak kwoty wolnej) | Formula |
| `jdg.ryc.calc.r3` | `lump_tax_deduction_health_7_75` | Odliczenie skladki zdrowotnej 7.75% (dla ryczaltu od 2022: 50% zaplaconej) | Odliczenie |
| `jdg.ryc.calc.r4` | `lump_tax_50pct_health_deduction` | Ryczalt: odliczenie 50% zaplaconej skladki zdrowotnej (od 2022) | Nowa zasada |
| `jdg.ryc.calc.r5` | `lump_tax_no_health_deduction_future` | Odliczenie skladki zdrowotnej w ryczalcie stopniowo wygaszane (2026+) | Trend |
| `jdg.ryc.calc.r6` | `lump_tax_no_loss_settlement` | Ryczalt NIE pozwala na rozliczanie straty | Wylaczenie |
| `jdg.ryc.calc.r7` | `lump_tax_no_joint_settlement` | Ryczalt NIE pozwala na wspolne rozliczenie z malzonkiem | Wylaczenie |
| `jdg.ryc.calc.r8` | `lump_tax_no_tax_free_amount` | Ryczalt: brak kwoty wolnej od podatku | Wylaczenie |
| `jdg.ryc.calc.r9` | `lump_tax_no_children_relief` | Ryczalt: ulga na dzieci tylko jako non-refundable (odliczenie od podatku) | Ograniczenie |
| `jdg.ryc.calc.r10` | `lump_tax_no_rd_innovation_reliefs` | Ryczalt: brak dostepu do ulgi B+R, IP Box, prototyp, robotyzacja | Wylaczenie |
| `jdg.ryc.calc.r11` | `lump_tax_donation_relief_possible` | Darowizny: odliczenie od przychodu (do 6% przychodu) | Mozliwosc |
| `jdg.ryc.calc.r12` | `lump_tax_donation_opp_6pct_gross` | Darowizny na OPP: 6% przychodu (nie dochodu) | Limit |
| `jdg.ryc.calc.r13` | `lump_tax_advance_monthly_20th` | Zaliczki miesieczne do 20. dnia nastepnego miesiaca | Termin |
| `jdg.ryc.calc.r14` | `lump_tax_advance_zero_gross_below_zus` | Zaliczka = 0 gdy przychod < skladki ZUS zaplacone | Zerowa |
| `jdg.ryc.calc.r15` | `lump_tax_annual_return_PIT_28` | Zeznanie roczne PIT-28 do 30 kwietnia | Deklaracja |
| `jdg.ryc.calc.r16` | `lump_tax_annual_return_no_loss` | W PIT-28: brak KUP, brak straty -> tylko przychod i podatek | Uproszczone |
| `jdg.ryc.calc.r17` | `lump_tax_annual_return_multiple_rates_annex` | Gdy JDG ma przychody w roznych stawkach -> zalacznik PIT-28/A | Zalacznik |
| `jdg.ryc.calc.r18` | `lump_tax_change_from_lump_during_year` | Zmiana z ryczaltu na skale -> od nastepnego miesiaca po utracie prawa | Zmiana |
| `jdg.ryc.calc.r19` | `lump_tax_revenue_book_required` | Ewidencja przychodow (uproszczona): kolumny: data, przychod, stawka, podatek | Ewidencja |
| `jdg.ryc.calc.r20` | `lump_tax_revenue_book_storage_5_years` | Ewidencja przechowywana 5 lat | Retencja |

---

## CZĘŚĆ VI: SKLADKA ZDROWOTNA (65 REGUL)

### 6.1 Obowiazek oplacania i podstawa wymiaru (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.health.r1` | `health_insurance_obligation_jdg` | Osoba prowadzaca JDG podlega obowiazkowo ubezpieczeniu zdrowotnemu | Obowiazkowe |
| `jdg.health.r2` | `health_insurance_scope_healthcare` | Ubezpieczenie daje prawo do swiadczen opieki zdrowotnej (NFZ) | Zakres |
| `jdg.health.r3` | `health_insurance_multiple_titles` | JDG na etacie -> ubezpieczenie z etatu, JDG plci dodatkowa skladke | Wielotytulowosc |
| `jdg.health.r4` | `health_insurance_base_scale_linear_100pct` | Skala/liniowy: podstawa = 100% przychodu z poprzedniego miesiaca (nie < minimalna) | Podstawa |
| `jdg.health.r5` | `health_insurance_base_lump_sum_60pct` | Ryczalt: podstawa = 60% przychodu z poprzedniego miesiaca (nie < minimalna) | Podstawa |
| `jdg.health.r6` | `health_insurance_base_minimum` | Minimalna podstawa: minimalne wynagrodzenie (2025: ~4 666 PLN) | Minimum |
| `jdg.health.r7` | `health_insurance_base_maximum` | Maksymalna podstawa: brak (od 2022) | Maksimum |
| `jdg.health.r8` | `health_insurance_base_new_business_first_year` | Nowa JDG: podstawa = 75% minimalnego wynagrodzenia przez pierwszy rok | Obnizona |
| `jdg.health.r9` | `health_insurance_base_after_suspension` | Wznowienie po zawieszeniu: podstawa = 75% minimalnego wynagrodzenia przez 6 miesiecy | Obnizona |
| `jdg.health.r10` | `health_insurance_base_no_income_month` | Miesiac bez przychodu -> podstawa minimalna (minimalne wynagrodzenie) | Minimum |
| `jdg.health.r11` | `health_insurance_base_sickness_absence` | Chorobowe: podstawa = 0 (jesli JDG nie osiaga przychodu z JDG) | Zerowa |
| `jdg.health.r12` | `health_insurance_base_maternity_leave` | Urlopy macierzynskie: podstawa = 0 (jesli JDG nie osiaga przychodu) | Zerowa |
| `jdg.health.r13` | `health_insurance_base_declared_higher_optional` | JDG moze zadeklarowac wyzsza podstawe (opcjonalnie) | Opcja |
| `jdg.health.r14` | `health_insurance_base_sickness_benefit_addition` | Zasilek chorobowy/macierzynski dolicza sie do przychodu dla podstawy | Doliczenie |
| `jdg.health.r15` | `health_insurance_base_annual_reconciliation` | Roczna korekta podstawy skladki zdrowotnej w zeznaniu rocznym | Korekta |

### 6.2 Stawki skladki zdrowotnej wg formy opodatkowania (~10 rules)

| ID | Nazwa reguly | Forma opodatkowania | Stawka | Odliczenie od PIT |
|:--:|:-----------:|:-----------------:|:------------------:|
| `jdg.health.rate.r1` | `health_rate_scale_9pct` | Skala podatkowa | 9% podstawy | 7.75% podstawy (odlicza sie od PIT) |
| `jdg.health.rate.r2` | `health_rate_linear_4_9pct` | Podatek liniowy 19% | 4.9% podstawy | 4.9% podstawy (odlicza sie od PIT) |
| `jdg.health.rate.r3` | `health_rate_lump_sum_9pct` | Ryczałt | 9% podstawy | 50% zaplaconej (stopniowo wygaszane) |
| `jdg.health.rate.r4` | `health_rate_tax_card_9pct` | Karta podatkowa | 9% podstawy | Pelna zaplacona (odlicza sie od karty) |
| `jdg.health.rate.r5` | `health_rate_scale_deduction_7_75` | Odliczenie: 7.75% x podstawa (skala) | Obniza podatek | |
| `jdg.health.rate.r6` | `health_rate_linear_deduction_full_4_9` | Odliczenie: 4.9% x podstawa (liniowy) | Obniza podatek | |
| `jdg.health.rate.r7` | `health_rate_lump_deduction_50pct` | Odliczenie: 50% x zaplacona (ryczalt) | Obniza podatek | |
| `jdg.health.rate.r8` | `health_rate_scale_effective_cost` | Efektywny koszt: 9% - 7.75% = 1.25% podstawy (skala) | Koszt efektywny | |
| `jdg.health.rate.r9` | `health_rate_linear_effective_0pct` | Efektywny koszt: 4.9% - 4.9% = 0% (liniowy, do 2022) | Koszt 0% | |
| `jdg.health.rate.r10` | `health_rate_linear_effective_4_9` | Efektywny koszt: 4.9% (liniowy, po zmianach) | Koszt 4.9% | |

### 6.3 Obliczanie rocznej skladki zdrowotnej w PIT (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.health.annual.r1` | `health_annual_base_total_revenue` | Roczna podstawa = suma przychodow z JDG w roku podatkowym | Obliczenie |
| `jdg.health.annual.r2` | `health_annual_contribution_9pct` | Skladka roczna = 9% x roczna podstawa (skala/ryczalt/karta) | Obliczenie |
| `jdg.health.annual.r3` | `health_annual_contribution_4_9pct` | Skladka roczna = 4.9% x roczna podstawa (liniowy) | Obliczenie |
| `jdg.health.annual.r4` | `health_annual_deduction_scale` | Odliczenie roczne: 7.75% x podstawa (skala) | Odliczenie |
| `jdg.health.annual.r5` | `health_annual_deduction_linear` | Odliczenie roczne: 4.9% x podstawa (liniowy) | Odliczenie |
| `jdg.health.annual.r6` | `health_annual_deduction_lump_50pct` | Odliczenie roczne: 50% x zaplacona (ryczalt) | Odliczenie |
| `jdg.health.annual.r7` | `health_annual_deduction_limit_health` | Odliczenie ograniczone do wysokosci zaplaconej skladki | Limit |
| `jdg.health.annual.r8` | `health_annual_deduction_no_carry_forward` | Niewykorzystane odliczenie przepada (nie przechodzi na nastepny rok) | Przepadniecie |
| `jdg.health.annual.r9` | `health_annual_return_PIT_36_or_36L` | Korekta roczna skladki w zeznaniu PIT-36/PIT-36L/PIT-28 | Deklaracja |
| `jdg.health.annual.r10` | `health_annual_underpayment_interest` | Niedoplata -> odsetki od terminu zaplaty | Sankcja |
| `jdg.health.annual.r11` | `health_annual_overpayment_refund_or_credit` | Nadplata -> zwrot lub zaliczenie na poczet nastepnych skladek | Zwrot |
| `jdg.health.annual.r12` | `health_annual_base_negative_income` | Jesli przychod < 0 (strata) -> podstawa = minimalne wynagrodzenie | Minimum |
| `jdg.health.annual.r13` | `health_annual_business_loss_effect` | Strata -> skladka zdrowotna od minimalnego wynagrodzenia | Minimum |
| `jdg.health.annual.r14` | `health_annual_base_zero_if_no_business` | Jesli JDG zawieszona i bez przychodu -> 0 podstawy | Zerowa |
| `jdg.health.annual.r15` | `health_annual_health_insurance_zus_declaration` | Skladka zdrowotna wykazywana w ZUS DRA miesiecznie | Deklaracja ZUS |

---

## CZĘŚĆ VII: KODEKS KARNY SKARBOWY — KKS (65 REGUL)

### 7.1 Przestepstwa i wykroczenia skarbowe (~15 rules)

| ID | Nazwa reguly | Czyn | Sankcja | Podstawa prawna |
|:--:|-------------|------|:-------:|:---------------:|
| `jdg.kks.a54.r1` | `kks_non_declaration_tax_evasion` | Niezlozenie deklaracji podatkowej w terminie -> wykroczenie | Grzywna do 720 stawek (max 7.2M PLN) | Art. 54 KKS |
| `jdg.kks.a54.r2` | `kks_non_declaration_small_10pct_or_less` | Niezlozenie: szkodliwosc spoleczna znikoma (kwota < 10% naleznego podatku) -> brak | Wylaczenie |
| `jdg.kks.a56.r1` | `kks_false_declaration_tax_fraud` | Podanie nieprawdy w deklaracji, zanizenie podatku -> przestepstwo skarbowe | Grzywna do 720 stawek + kara 30% zanizenia | Art. 56 KKS |
| `jdg.kks.a56.r2` | `kks_false_declaration_small_10pct` | Zanizenie < 10% -> wykroczenie, nie przestepstwo | Lagodniejsza | Art. 56 KKS |
| `jdg.kks.a56.r3` | `kks_false_declaration_huge_loss` | Mala szkoda (do 200 minimalnych) -> wykroczenie | Lagodniejsza | Art. 56 KKS |
| `jdg.kks.a57.r1` | `kks_vat_fraud_carousel_missing_trader` | Udział w karuzeli VAT (oszustwo na VAT) -> przestepstwo | Grzywna + kara do 5 lat pozbawienia wolnosci | Art. 57 KKS |
| `jdg.kks.a57.r2` | `kks_vat_fraud_large_scale` | VAT > 10M PLN -> zbrodnia skarbowa | Kara do 10 lat wiezienia | Art. 57 KKS |
| `jdg.kks.a58.r1` | `kks_invoice_fraud_false_invoice` | Wystawienie falszywej faktury (bez zdarzenia gospodarczego) | Grzywna + kara do 5 lat wiezienia | Art. 58 KKS |
| `jdg.kks.a58.r2` | `kks_invoice_fraud_buyer_use` | Uzycie falszywej faktury do odliczenia VAT -> przestepstwo | Grzywna + kara | Art. 58 KKS |
| `jdg.kks.a59.r1` | `kks_non_payment_tax_withholding` | Nieodprowadzenie podatku u zrodla (WHT, PIT od pracownikow) | Grzywna do 720 stawek | Art. 59 KKS |
| `jdg.kks.a60.r1` | `kks_non_payment_vat_payable` | Niezaplata VAT należnego (mimo posiadania srodkow) | Grzywna do 720 stawek | Art. 60 KKS |
| `jdg.kks.a61.r1` | `kks_non_payment_zus_contributions` | Nieoplacanie skladek ZUS (wlasnych i pracownikow) -> przestepstwo | Grzywna do 720 stawek | Art. 61 KKS |
| `jdg.kks.a62.r1` | `kks_obstruction_tax_audit` | Uniemozliwianie kontroli podatkowej (brak dostepu, niszczenie dokumentow) | Grzywna do 720 stawek | Art. 62 KKS |
| `jdg.kks.a63.r1` | `kks_destruction_of_documents` | Niszczenie dokumentow ksiegowych przed uplywem terminu przechowywania | Grzywna do 720 stawek | Art. 63 KKS |
| `jdg.kks.a64.r1` | `kks_abuse_of_procedures` | Naduzycie procedur podatkowych (np. wykorzystanie ulg bez podstawy) | Grzywna + kara | Art. 64 KKS |

### 7.2 Sankcje administracyjne (~10 rules)

| ID | Nazwa reguly | Sankcja | Warunek | Wysokosc |
|:--:|-------------|--------|---------|:--------:|
| `jdg.kks.pen.r1` | `penalty_vat_additional_30pct` | Dodatkowe zobowiazanie VAT: 30% | Zanizenie VAT > 10% | 30% |
| `jdg.kks.pen.r2` | `penalty_vat_additional_20pct` | Dodatkowe zobowiazanie VAT: 20% | Zanizenie < 10% (wykroczenie) | 20% |
| `jdg.kks.pen.r3` | `penalty_vat_omission_100pct` | Dodatkowe zobowiazanie 100% VAT | KSeF: niedotrzymanie obowiazku | 100% |
| `jdg.kks.pen.r4` | `penalty_vat_bad_debt_30pct` | Sankcja 30% VAT | Brak korekty zlych dlugow w terminie | 30% |
| `jdg.kks.pen.r5` | `penalty_pit_additional_30pct` | Sankcja 30% PIT | Zanizenie dochodu o > 50% | 30% |
| `jdg.kks.pen.r6` | `penalty_interest_overdue` | Odsetki za zwloke | Niezaplata w terminie | 200% stopy lombardowej |
| `jdg.kks.pen.r7` | `penalty_interest_reduced_75` | Odsetki obnizone 75% | Korekta po ogloszeniu kontroli | 75% stawki |
| `jdg.kks.pen.r8` | `penalty_interest_reduced_50` | Odsetki obnizone 50% | Wspolpraca z US | 50% stawki |
| `jdg.kks.pen.r9` | `penalty_gaar_40pct` | Sankcja GAAR 40% | Klauzula przeciwko unikaniu opodatkowania | 40% |
| `jdg.kks.pen.r10` | `penalty_gaar_reduced_20pct` | Sankcja GAAR 20% | Gdy MDR zgloszony | 20% |

### 7.3 Czynny zal i dobrowolne poddanie sie karze (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.kks.mit.r1` | `mitigation_active_remorse_condition` | Czynny zal: zlozenie korekty + zaplata podatku + odsetki przed ogloszeniem kontroli | Mozliwosc |
| `jdg.kks.mit.r2` | `mitigation_active_remorse_criminal_immunity` | Czynny zal -> brak odpowiedzialnosci karnej (przestepstwo wygasa) | Immunitet |
| `jdg.kks.mit.r3` | `mitigation_active_remorse_tax_immunity` | Czynny zal -> brak dodatkowego zobowiazania (sankcji VAT) | Immunitet |
| `jdg.kks.mit.r4` | `mitigation_active_remorse_deadline` | Czynny zal mozliwy przed wszczecem kontroli (lub przed ogloszeniem) | Termin |
| `jdg.kks.mit.r5` | `mitigation_active_remorse_not_for_carousel` | Czynny zal NIE dotyczy przestepstw karuzeli VAT | Wylaczenie |
| `jdg.kks.mit.r6` | `mitigation_active_remorse_not_for_gaar` | Czynny zal NIE dotyczy GAAR | Wylaczenie |
| `jdg.kks.mit.r7` | `mitigation_voluntary_submission_penalty` | Dobrowolne poddanie sie odpowiedzialnosci (wniosek o skazanie bez rozprawy) | Opcja |
| `jdg.kks.mit.r8` | `mitigation_voluntary_submission_penalty_reduction` | Dobrowolne poddanie -> redukcja kary (do 50%) | Redukcja |
| `jdg.kks.mit.r9` | `mitigation_cooperation_with_authorities` | Wspolpraca z US -> lagodniejsza kara (maks. 50% redukcji) | Redukcja |
| `jdg.kks.mit.r10` | `mitigation_whistleblower_status` | Ujawnienie innych przestepstw (whistleblower) -> calkowite zwolnienie z kary | Immunitet |

---

## CZĘŚĆ VIII: PCC I PODATKI LOKALNE (195 REGUL)

### 8.1 Podatek od czynnosci cywilnoprawnych — PCC (~25 rules)

| ID | Nazwa reguly | Przedmiot | Stawka | Podstawa prawna |
|:--:|-------------|:---------:|:-----:|:---------------:|
| `jdg.pcc.a1.r1` | `pcc_subject_loan` | Umowa pozyczki | 0.5% | Art. 1 ust. 1 pkt 1 + Art. 7 |
| `jdg.pcc.a1.r2` | `pcc_subject_credit` | Umowa kredytu | 0.5% | Art. 1 ust. 1 pkt 1 + Art. 7 |
| `jdg.pcc.a1.r3` | `pcc_subject_sale_real_estate` | Umowa sprzedazy nieruchomosci | 2% | Art. 1 ust. 1 pkt 1 + Art. 7 |
| `jdg.pcc.a1.r4` | `pcc_subject_sale_movable` | Umowa sprzedazy ruchomosci (samochod, sprzet) | 2% | Art. 1 ust. 1 pkt 1 + Art. 7 |
| `jdg.pcc.a1.r5` | `pcc_subject_exchange` | Umowa zamiany | 2% (od kazdej strony) | Art. 1 ust. 1 pkt 2 + Art. 7 |
| `jdg.pcc.a1.r6` | `pcc_subject_company_formation` | Umowa spolki (akt zalozycielski) | 0.5% | Art. 1 ust. 1 pkt 2 + Art. 7 |
| `jdg.pcc.a1.r7` | `pcc_subject_company_increase_capital` | Podwyzszenie kapitalu zakladowego | 0.5% | Art. 1 ust. 1 pkt 2 + Art. 7 |
| `jdg.pcc.a1.r8` | `pcc_subject_lease_sublease` | Umowa dzierzawy, najmu (gdy poza VAT) | 1% | Art. 1 ust. 1 pkt 2 + Art. 7 |
| `jdg.pcc.a1.r9` | `pcc_subject_power_of_attorney` | Pelromocnictwo, prokura | 1% (od kazdego) | Art. 1 ust. 1 pkt 2 + Art. 7 |
| `jdg.pcc.a1.r10` | `pcc_subject_settlement_agreement` | Ugoda, porozumienie | 2% | Art. 1 ust. 1 pkt 3 + Art. 7 |
| `jdg.pcc.a2.r1` | `pcc_exemption_vat` | Czynnosc opodatkowana VAT -> zwolniona z PCC | Zwolnienie | Art. 2 pkt 4 |
| `jdg.pcc.a2.r2` | `pcc_exemption_vat_exception_real_estate` | Nieruchomosci: zwolnienie z PCC tylko gdy VAT (jesli zwolniona z VAT -> PCC) | Wyjatek | Art. 2 pkt 4 |
| `jdg.pcc.a2.r3` | `pcc_exemption_employment_contract` | Umowa o prace -> brak PCC | Zwolnienie | Art. 2 pkt 2 |
| `jdg.pcc.a2.r4` | `pcc_exemption_sale_of_shares_on_stock_exchange` | Sprzedaz akcji na gieldzie -> brak PCC | Zwolnienie | Art. 2 pkt 1 |
| `jdg.pcc.a2.r5` | `pcc_exemption_loan_up_to_1000` | Pozyczka do 1 000 PLN -> brak PCC | Zwolnienie | Art. 2 pkt 1 |
| `jdg.pcc.a2.r6` | `pcc_exemption_loan_from_family` | Pozyczka od rodziny (zstępni, wstępni, rodzenstwo, malzonek) -> do 9 637 PLN 2024 | Zwolnienie | Art. 9 pkt 10 |
| `jdg.pcc.a2.r7` | `pcc_exemption_own_dwelling_first` | Zakup pierwszego mieszkania na rynku wtornym (do 100m2) | Zwolnienie | Art. 9 pkt 17 |
| `jdg.pcc.a2.r8` | `pcc_exemption_own_dwelling_conditions` | Warunki: kupujacy <35 lat, wczesniej nie mial mieszkania | Warunki | Art. 9 pkt 17 |
| `jdg.pcc.a3.r1` | `pcc_taxpayer_buyer` | Podatnikiem PCC jest kupujacy (nabywca) | Podmiot | Art. 4 |
| `jdg.pcc.a3.r2` | `pcc_taxpayer_both_for_exchange` | Przy zamianie: obie strony sa podatnikami PCC | Obie strony | Art. 4 |
| `jdg.pcc.a4.r1` | `pcc_tax_base_purchase_price` | Podstawa: cena nabycia (wartosc rynkowa jesli cena < wartosc rynkowa) | Podstawa | Art. 6 |
| `jdg.pcc.a4.r2` | `pcc_tax_base_loan_amount` | Pozyczka: kwota pozyczki (kapital) | Podstawa | Art. 6 |
| `jdg.pcc.a5.r1` | `pcc_deadline_14_days` | Zaplata PCC w 14 dni od powstania obowiazku podatkowego | Termin | Art. 10 |
| `jdg.pcc.a5.r2` | `pcc_declaration_PCC_3` | Deklaracja PCC-3 do US w terminie 14 dni | Deklaracja | Art. 10 |
| `jdg.pcc.a5.r3` | `pcc_notary_obligation_collection` | Notariusz pobiera PCC przy umowie notarialnej (przekazuje do US) | Notariusz | Art. 10 |

### 8.2 Podatek od nieruchomosci (~20 rules)

| ID | Nazwa reguly | Rodzaj nieruchomosci | Stawka max | Podstawa prawna |
|:--:|-------------|:-------------------:|:----------:|:---------------:|
| `jdg.prop.r1` | `property_tax_subject_residential_building` | Budynek mieszkalny | od 0.89 PLN/m2 | Art. 5 ust. 1 |
| `jdg.prop.r2` | `property_tax_subject_commercial_building` | Budynek uzytkowy (biura, magazyny, lokale) | od 31.49 PLN/m2 | Art. 5 ust. 1 |
| `jdg.prop.r3` | `property_tax_subject_garage` | Garaz (w budynku mieszkalnym) | od 0.89-31.49 PLN/m2 | Art. 5 ust. 1 |
| `jdg.prop.r4` | `property_tax_subject_land_residential` | Grunt pod budynkiem mieszkalnym | od 0.53 PLN/m2 | Art. 5 ust. 1 |
| `jdg.prop.r5` | `property_tax_subject_land_business` | Grunt pod dzialalnoscia gospodarcza | od 1.33 PLN/m2 | Art. 5 ust. 1 |
| `jdg.prop.r6` | `property_tax_subject_land_other` | Pozostale grunty (rolne, lesne) | od 0.53 PLN/m2 | Art. 5 ust. 1 |
| `jdg.prop.r7` | `property_tax_subject_structure_commercial` | Budowla (hala, plac, silos, wiata) | 2% wartosci | Art. 5 ust. 1 |
| `jdg.prop.r8` | `property_tax_subject_structure_definition` | Definicja budowli wg Prawa budowlanego | Definicja | Art. 1a |
| `jdg.prop.r9` | `property_tax_subject_commercial_firm_owned` | JDG wlasiciel nieruchomosci -> placi podatek od nieruchomosci | Obowiazek | Art. 3 |
| `jdg.prop.r10` | `property_tax_subject_commercial_leased` | JDG dzierzawca nieruchomosci -> placi wlasciciel, ale moze przerzucic na JDG | Przerzucenie | Art. 3 |
| `jdg.prop.r11` | `property_tax_subject_vat_exempt_lease` | Wynajem nieruchomosci mieszkalnej (zwolniony z VAT) -> JDG wynajmujacy placi podatek | Obowiazek | Art. 3 |
| `jdg.prop.r12` | `property_tax_rate_municipal` | Stawki uchwala rada gminy (w granicach ustawowych) | Stawka gminna | Art. 5 |
| `jdg.prop.r13` | `property_tax_rate_max_2024` | Stawki maksymalne oglasza MF na dany rok (corocznie) | Ograniczenie | Art. 5 |
| `jdg.prop.r14` | `property_tax_rate_annual_notice` | JDZ dostaje decyzje wymiarowa od gminy na dany rok | Decyzja | Art. 6 |
| `jdg.prop.r15` | `property_tax_deadline_quarterly` | Podatek platny w ratach kwartalnych do 15. dnia miesiaca po kwartale | Termin | Art. 6 |
| `jdg.prop.r16` | `property_tax_deadline_one_time` | Opcja: jedna rata do 15. marca (jesli podatek < 100 PLN) | Alternatywa | Art. 6 |
| `jdg.prop.r17` | `property_tax_declaration_deadline` | Deklaracja na podatek od nieruchomosci (DN-1) do 31 stycznia | Deklaracja | Art. 6 |
| `jdg.prop.r18` | `property_tax_exemption_church` | Zwolnienie: budynki koscielne, sakralne | Zwolnienie | Art. 7 |
| `jdg.prop.r19` | `property_tax_exemption_public_infrastructure` | Zwolnienie: infrastruktura publiczna (drogi, sieci) | Zwolnienie | Art. 7 |
| `jdg.prop.r20` | `property_tax_loss_partial_year` | Zmiana w trakcie roku (sprzedaz, zakup, zniszczenie) -> za miesiace faktycznego posiadania | Pro rata |

### 8.3 Podatek srodkow transportowych (~10 rules)

| ID | Nazwa reguly | Rodzaj pojazdu | Stawka |
|:--:|-------------|:-------------:|:-----:|
| `jdg.tax_trans.r1` | `transport_tax_subject_truck_3_5t` | Samochod ciezarowy o DMC > 3.5t | Zalezy od DMC |
| `jdg.tax_trans.r2` | `transport_tax_subject_bus` | Autobus (powyzej 9 miejsc) | Zalezy od liczby miejsc |
| `jdg.tax_trans.r3` | `transport_tax_subject_trailer` | Przyczepa ciezarowa > 3.5t | Zalezy od DMC |
| `jdg.tax_trans.r4` | `transport_tax_subject_tractor` | Ciagnik siodlowy i balastowy | Zalezy od DMC |
| `jdg.tax_trans.r5` | `transport_tax_rate_municipal` | Stawki uchwala rada gminy | Ograniczone MF |
| `jdg.tax_trans.r6` | `transport_tax_deadline_2_raty` | Dwie raty: do 15. marca i 15. wrzesnia | Terminy |
| `jdg.tax_trans.r7` | `transport_tax_declaration_deadline` | Deklaracja DT-1 do 31 stycznia | Deklaracja |
| `jdg.tax_trans.r8` | `transport_tax_exemption_hybrid` | Zwolnienie: pojazdy hybrydowe, elektryczne, gazowe (gminne) | Mozliwe zwolnienie |
| `jdg.tax_trans.r9` | `transport_tax_purchase_during_year` | Zakup w ciagu roku -> podatek od nastepnego miesiaca | Pro rata |
| `jdg.tax_trans.r10` | `transport_tax_sale_during_year` | Sprzedaz -> podatek do konca miesiaca sprzedazy | Pro rata |

---

## CZĘŚĆ IX: UoR + CEIDG + SUKCESJA (225 REGUL)

### 9.1 Ustawa o rachunkowosci dla JDG (~25 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.uor.r1` | `uor_pkpir_basic_record` | JDG prowadzi PKPiR (Podatkowa Ksiega Przychodow i Rozchodow) | Podstawowy obowiazek |
| `jdg.uor.r2` | `uor_pkpir_eligible_for_jdg` | JDG moze prowadzic PKPiR (jesli przychod < 2M EUR) | Mozliwosc |
| `jdg.uor.r3` | `uor_financial_statements_mandatory_over_2m_eur` | Przekroczenie 2M EUR przychodu -> obowiazek pelnej ksiegowosci (ksiegi rachunkowe) | Obowiazek |
| `jdg.uor.r4` | `uor_financial_statements_mandatory_capital_group` | JDG w grupie kapitalowej -> ksiegi rachunkowe | Obowiazek |
| `jdg.uor.r5` | `uor_financial_statements_filing` | Sprawozdanie finansowe do KRS w 15 dni od zatwierdzenia | Termin |
| `jdg.uor.r6` | `uor_pkpir_columns` | PKPiR: 17 kolumn (przychody, wydatki, uwagi) | Struktura |
| `jdg.uor.r7` | `uor_pkpir_chronological_order` | Wpisy chronologiczne, dzien po dniu, na podstawie dokumentow | Zasada |
| `jdg.uor.r8` | `uor_pkpir_annual_reconciliation` | Roczne zamkniecie PKPiR (suma przychodow i wydatkow) | Roczne |
| `jdg.uor.r9` | `uor_pkpir_inventory_mandatory` | Obowiazkowa inwentaryzacja (spis z natury) na koniec roku | Obowiazek |
| `jdg.uor.r10` | `uor_pkpir_inventory_deadline_15_january` | Spis z natury do 15 stycznia nastepnego roku | Termin |
| `jdg.uor.r11` | `uor_pkpir_storage_5_years` | PKPiR przechowywana 5 lat | Retencja |
| `jdg.uor.r12` | `uor_pkpir_electronic_form` | PKPiR w formie elektronicznej (program ksiegowy) dopuszczalna | Forma |
| `jdg.uor.r13` | `uor_pkpir_errors_corrections` | Korekta bledow w PKPiR: skreslenie (przekreslenie) + data + podpis | Korekta |
| `jdg.uor.r14` | `uor_pkpir_closing_new_beginning` | Zamkniecie PKPiR na koniec roku -> otwarcie nowej na nowy rok | Nowy rok |
| `jdg.uor.r15` | `uor_pkpir_expenses_column_13` | Kolumna 13 (wydatki ogolem) i kolumna 14-16 (wydatki szczegolne) | Wydatki |
| `jdg.uor.r16` | `uor_pkpir_revenue_cash_registered` | Przychod: data wystawienia faktury (lub 25. dnia miesiaca) | Przychod |
| `jdg.uor.r17` | `uor_pkpir_expense_date_invoice` | Wydatek: data faktury (lub data zaplaty jesli kasa) | Wydatek |
| `jdg.uor.r18` | `uor_pkpir_salary_end_of_month` | Wynagrodzenia: na koniec miesiaca (za miesiac) | Wyplata |
| `jdg.uor.r19` | `uor_pkpir_fixed_assets_register` | Ewidencja srodkow trwalych (osobna od PKPiR) | Obowiazek |
| `jdg.uor.r20` | `uor_pkpir_fixed_assets_format` | Ewidencja ST: data, wartosc, stawka, odpisy, zbycie | Format |
| `jdg.uor.r21` | `uor_pkpir_wnip_register` | Ewidencja WNiP (wartosci niematerialnych i prawnych) | Obowiazek |
| `jdg.uor.r22` | `uor_pkpir_employee_salary_register` | Ewidencja wynagrodzen pracownikow (imienna) | Obowiazek |
| `jdg.uor.r23` | `uor_pkpir_vat_register` | Ewidencja VAT (sprzedaz i zakup) dla czynnych podatnikow | Obowiazek |
| `jdg.uor.r24` | `uor_pkpir_vehicle_expense_log` | Ewidencja przebiegu pojazdu dla auta firmowego (100% KUP opcja) | Obowiazek warunkowy |
| `jdg.uor.r25` | `uor_pkpir_bank_account_separate` | Obowiazek posiadania osobnego rachunku bankowego dla JDG | Obowiazek |

### 9.2 CEIDG — Centralna Ewidencja i Informacja o Dzialalnosci Gospodarczej (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ceidg.r1` | `ceidg_registration_obligation` | Kazda JDG musi byc zarejestrowana w CEIDG | Obowiazek |
| `jdg.ceidg.r2` | `ceidg_registration_form_electronic` | Rejestracja online przez CEIDG (formularz elektroniczny) | Forma |
| `jdg.ceidg.r3` | `ceidg_registration_data_required` | Wymagane dane: imie, nazwisko, NIP, PESEL, adres, PKD, forma opodatkowania | Dane |
| `jdg.ceidg.r4` | `ceidg_registration_automatic_nip_regon` | Rejestracja CEIDG -> automatycznie NIP i REGON | Automatyzm |
| `jdg.ceidg.r5` | `ceidg_registration_automatic_zus` | Rejestracja CEIDG -> automatyczne zgloszenie do ZUS | Automatyzm |
| `jdg.ceidg.r6` | `ceidg_registration_automatic_us` | Rejestracja CEIDG -> automatyczne zgloszenie do US | Automatyzm |
| `jdg.ceidg.r7` | `ceidg_registration_change_7_days` | Zmiana danych w CEIDG: w 7 dni od zdarzenia | Obowiazek |
| `jdg.ceidg.r8` | `ceidg_registration_suspension_notification` | Zawieszenie dzialalnosci: zgoda do CEIDG | Obowiazek |
| `jdg.ceidg.r9` | `ceidg_registration_resumption_notification` | Wznowienie po zawieszeniu: przez CEIDG | Obowiazek |
| `jdg.ceidg.r10` | `ceidg_registration_closure_notification` | Zamkniecie dzialalnosci: wniosek o wykreślenie z CEIDG | Obowiazek |
| `jdg.ceidg.r11` | `ceidg_registration_death_notification` | Smierc przedsiebiorcy -> CEIDG wykreśla z urzedu (na wniosek spadkobiercy) | Urzedowo |
| `jdg.ceidg.r12` | `ceidg_registration_pkd_main_and_secondary` | Głowne PKD (jedno) + pomocnicze PKD (wiele) -> decyduje o stawce ryczaltu | PKD |
| `jdg.ceidg.r13` | `ceidg_registration_bank_account_required` | Obowiazek wskazania rachunku bankowego dla dzialalnosci | Obowiazek |
| `jdg.ceidg.r14` | `ceidg_registration_public_data` | Wiece danych w CEIDG jest publiczna (NIP, adres, PKD) | Publicznosc |
| `jdg.ceidg.r15` | `ceidg_registration_protected_data_home` | Mozliwosc ukrycia adresu zamieszkania (na wniosek) | Prywatnosc |

### 9.3 Sukcesja po smierci przedsiebiorcy JDG (~20 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.succ.r1` | `succession_definition_enterprise_inheritance` | Przedsiebiorstwo w spadku: ogol praw i obowiazkow zwiazanych z JDG | Definicja |
| `jdg.succ.r2` | `succession_temporary_management_2_months` | Zarzad sukcesyjny: spadkobierca ustanawia go w 2 miesiace od smierci | Zarzad |
| `jdg.succ.r3` | `succession_temporary_manager_appointment` | Zarzadca sukcesyjny: osoba fizyczna (spadkobierca lub inna) | Osoba |
| `jdg.succ.r4` | `succession_temporary_manager_deadline` | Wniosek o zarzad sukcesyjny: 2 miesiace od smierci | Termin |
| `jdg.succ.r5` | `succession_enterprise_continues_existence` | W okresie zarzadu: JDG istnieje nadal, NIP bez zmian | Kontynuacja |
| `jdg.succ.r6` | `succession_manager_rights_duties` | Zarzadca ma prawa i obowiazki przedsiebiorcy (VAT, PIT, ZUS, KSeF) | Uprawnienia |
| `jdg.succ.r7` | `succession_manager_remuneration_limit` | Wynagrodzenie zarzadcy: do 6% przychodu | Limit |
| `jdg.succ.r8` | `succession_deadline_for_acceptance` | Spadkobierca ma 6 miesiecy na przyjecie/odrzucenie spadku | Termin |
| `jdg.succ.r9` | `succession_acceptance_with_benefit` | Przyjecie spadku z dobrodziejstwem inwentarza -> ograniczenie odpowiedzialnosci | Opcja |
| `jdg.succ.r10` | `succession_acceptance_direct` | Przyjecie spadku wprost -> pelna odpowiedzialnosc | Ryzyko |
| `jdg.succ.r11` | `succession_rejection_of_inheritance` | Odrzucenie spadku -> JDG wygasa, spadkobierca nie odpowiada | Odrzucenie |
| `jdg.succ.r12` | `succession_tax_settlement_by_manager` | Zarzadca sklada deklaracje podatkowe za okres po smierci do dnia zakonczenia zarzadu | Obowiazek |
| `jdg.succ.r13` | `succession_vat_settlement_manager` | Zarzadca rozlicza VAT za okres po smierci (deklaracje i zaplate) | Obowiazek |
| `jdg.succ.r14` | `succession_zus_settlement_manager` | Zarzadca oplac skladki ZUS za okres zarzadu | Obowiazek |
| `jdg.succ.r15` | `succession_death_of_manager` | Smierc zarzadcy -> koniecznosc powolania nowego w 2 miesiace | Przerwanie |
| `jdg.succ.r16` | `succession_end_of_management_period` | Zarzad sukcesyjny trwa do 10 miesiecy od smierci | Max czas |
| `jdg.succ.r17` | `succession_end_of_management_reasons` Zakonczenie: przyjecie spadku, uprawomocnienie sie postanowienia o stwierdzeniu nabycia spadku | Zakonczenie |
| `jdg.succ.r18` | `succession_end_of_management_no_heir` | Brak spadkobiercy -> zakonczenie zarzadu, JDG wygasa | Wygasniecie |
| `jdg.succ.r19` | `succession_inheritance_tax_3_months` | Podatek od spadku: w 3 miesiace od stwierdzenia nabycia (lub od dnia powstania obowiazku) | Termin |
| `jdg.succ.r20` | `succession_inheritance_tax_exemption_family` | Zwolnienie z podatku od spadku: najblizsza rodzina (malzonek, dzieci, rodzice) | Zwolnienie |

---

## CZĘŚĆ X: KSeF I JPK (200 REGUL)

### 10.1 KSeF — Krajowy System e-Faktur struktura i obowiazki (~25 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.ksef.r1` | `ksef_obligation_active_vat_from_2026` | Czynny podatnik VAT -> faktury przez KSeF od 1 lutego 2026 | Obowiazek |
| `jdg.ksef.r2` | `ksef_obligation_vat_exempt_exception` | Podatnik zwolniony z VAT -> wyjatek z KSeF | Wylaczenie |
| `jdg.ksef.r3` | `ksef_obligation_b2c_receipts_exception` | Paragony, rachunki B2C -> nie wymagaja KSeF | Wylaczenie |
| `jdg.ksef.r4` | `ksef_structured_invoice_schema` | Faktura w formacie XML wg schemy FA(1) | Format |
| `jdg.ksef.r5` | `ksef_structured_invoice_required_fields` | Wymagane pola: NIP nabywcy, kwota, stawka, data, numer | Wymogi |
| `jdg.ksef.r6` | `ksef_structured_invoice_optional_fields` | Opcjonalne pola: adnotacje, faktura korygujaca, zaliczka | Opcjonalne |
| `jdg.ksef.r7` | `ksef_send_real_time_or_24h` | Faktura wyslana do KSeF w momencie sprzedazy (lub do 24h) | Termin |
| `jdg.ksef.r8` | `ksef_offline_mode_on_breakdown` | Tryb offline: awaria KSeF -> faktury offline z sufiksem /OFFLINE | Tryb awaryjny |
| `jdg.ksef.r9` | `ksef_offline_recovery_7_days` | Po przywroceniu KSeF: 7 dni na wyslanie faktur offline | Termn |
| `jdg.ksef.r10` | `ksef_upo_confirmation_after_send` | UPO (Urzedowe Poświadczenie Odbioru) - otrzymawane po wyslaniu | Potwierdzenie |
| `jdg.ksef.r11` | `ksef_upo_verification_signature` | UPO zawiera podpis elektroniczny (weryfikacja autentycznosci) | Autentycznosc |
| `jdg.ksef.r12` | `ksef_upo_storage_5_years` | UPO przechowywane 5 lat | Retencja |
| `jdg.ksef.r13` | `ksef_qr_code_on_visual_invoice` | Kod QR na fakturze wizualnej (PDF) do weryfikacji | Obowiazek |
| `jdg.ksef.r14` | `ksef_qr_code_generation` | Kod QR generowany przez KSeF (lub przez system JDG) | Generator |
| `jdg.ksef.r15` | `ksef_qr_code_validation_url` | Kod QR zawiera URL do weryfikacji faktury w KSeF | URL |
| `jdg.ksef.r16` | `ksef_sanction_100pct_vat` | Sankcja za brak KSeF: 100% VAT z faktury (max 500k PLN) | Sankcja |
| `jdg.ksef.r17` | `ksef_sanction_70pct_for_offline` | Sankcja za opoznienie > 24h: 70% VAT (max 300k PLN) | Sankcja |
| `jdg.ksef.r18` | `ksef_sanction_15pct_minor` | Sankcja za bledy w fakturze: 15% VAT (max 100k PLN) | Sankcja |
| `jdg.ksef.r19` | `ksef_sanction_not_for_receipts` | Sankcje KSeF nie dotycza paragonow B2C | Wylaczenie |
| `jdg.ksef.r20` | `ksef_self_invoicing_by_buyer` | Faktura wystawiona przez nabywce (self-billing) -> tez przez KSeF | Obowiazek |
| `jdg.ksef.r21` | `ksef_api_authentication_token` | Autoryzacja do API KSeF: token (NIP + klucz API) | Autoryzacja |
| `jdg.ksef.r22` | `ksef_api_environment_test_prod` | Srodowiska: TEST i PRODUKCJA | Srodowiska |
| `jdg.ksef.r23` | `ksef_api_invoice_limit_per_request` | Limit faktur w jednym zadaniu: 1 faktura (standard) lub 100 (batch) | Limity |
| `jdg.ksef.r24` | `ksef_api_invoice_status_check` | Sprawdzanie statusu faktury w KSeF (czy odebrana, czy bledna) | Status |
| `jdg.ksef.r25` | `ksef_api_batch_mode_for_corrections` | Tryb batch: wysylka wielu faktur naraz (do 100) -> szybszy | Batch |

### 10.2 JPK_V7M / JPK_V7K (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.jpk.r1` | `jpk_v7m_monthly_mandatory` | Czynny podatnik VAT -> JPK_V7M miesiecznie | Obowiazek |
| `jdg.jpk.r2` | `jpk_v7k_quarterly_small` | Maly podatnik (obrot < 2M EUR) -> moze skladac JPK_V7K kwartalnie | Opcja |
| `jdg.jpk.r3` | `jpk_v7k_deadline_25_after` | JPK_V7K: do 25. dnia po kwartale | Termin |
| `jdg.jpk.r4` | `jpk_v7m_deadline_25_monthly` | JPK_V7M: do 25. dnia nastepnego miesiaca | Termin |
| `jdg.jpk.r5` | `jpk_part_vat_sales_sprzedaz` | Czesc ewidencyjna: sprzedaz (faktury, paragony, WDT, eksport) | Sprzedaz |
| `jdg.jpk.r6` | `jpk_part_vat_purchase_zakup` | Czesc ewidencyjna: zakup (faktury kosztowe, import, WNT) | Zakup |
| `jdg.jpk.r7` | `jpk_part_vat_vat_declaration_deklaracja` | Czesc deklaracyjna: podsumowanie VAT (nalezny, naliczony, do zaplaty) | Deklaracja |
| `jdg.jpk.r8` | `jpk_xml_structure_mandatory` | JPK w formacie XML (struktura logiczna MF) | Format |
| `jdg.jpk.r9` | `jpk_xml_schema_v7m_1_0` | Schemat JPK_V7M-1 (obowiazujacy od 2024) | Schema |
| `jdg.jpk.r10` | `jpk_zero_filing_if_no_transactions` | JPK zerowe przy braku transakcji (sprzedaz = 0, zakup = 0) | Zerowe |
| `jdg.jpk.r11` | `jpk_correction_file` | Korekta JPK: przeslanie nowego pliku (z adnotacja korekta) | Korekta |
| `jdg.jpk.r12` | `jpk_automatic_validation_by_mf` | Walidacja JPK przez system MF (bledy krytyczne -> odrzucenie) | Walidacja |
| `jdg.jpk.r13` | `jpk_validation_errors_critical` | Bledy krytyczne: bledny NIP, bledny okres, bledne sumy | Odrzucenie |
| `jdg.jpk.r14` | `jpk_validation_errors_warnings` | Ostrzezenia: drobne niezgodnosci (np. brak NIP nabywcy) | Zaakceptowane |
| `jdg.jpk.r15` | `jpk_storage_5_years` | JPK przechowywany 5 lat od konca roku | Retencja |

### 10.3 JPK_PKPIR, JPK_VAT, JPK_FA (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.jpk.pkpir.r1` | `jpk_pkpir_obligation_on_demand` | JPK_PKPIR: na zadanie US (nie obowiazkowo cyklicznie) | Na zadanie |
| `jdg.jpk.pkpir.r2` | `jpk_pkpir_scope_all_entries` | JPK_PKPIR: wszystkie wpisy z PKPiR za wskazany okres | Zakres |
| `jdg.jpk.pkpir.r3` | `jpk_pkpir_deadline_14_days` | Po wezwaniu US: 14 dni na przeslanie JPK_PKPIR | Termin |
| `jdg.jpk.pkpir.r4` | `jpk_pkpir_mandatory_for_all_jdg` | Obowiazek dotyczy wszystkich JDG prowadzacych PKPiR | Podmiot |
| `jdg.jpk.pkpir.r5` | `jpk_pkpir_schema` | Struktura JPK_PKPIR zgodna z MF | Schema |
| `jdg.jpk.fa.r1` | `jpk_fa_obligation_on_demand` | JPK_FA (faktury): na zadanie US | Na zadanie |
| `jdg.jpk.fa.r2` | `jpk_fa_scope_all_invoices` | JPK_FA: wszystkie faktury za wskazany okres | Zakres |
| `jdg.jpk.fa.r3` | `jpk_fa_deadline_14_days` | JPK_FA: 14 dni od wezwania | Termin |
| `jdg.jpk.fa.r4` | `jpk_fa_obligation_for_all_vat` | Obowiazek dla wszystkich czynnych podatnikow VAT | Podmiot |
| `jdg.jpk.wb.r1` | `jpk_wb_obligation_on_demand` | JPK_WB (wyciagi bankowe): na zadanie US | Na zadanie |
| `jdg.jpk.wb.r2` | `jpk_wb_scope_all_accounts` | JPK_WB: wszystkie rachunki bankowe JDG we wskazanym okresie | Zakres |
| `jdg.jpk.wb.r3` | `jpk_wb_deadline_14_days` | JPK_WB: 14 dni od wezwania | Termin |
| `jdg.jpk.mag.r1` | `jpk_mag_obligation_on_demand` | JPK_MAG (magazyn): na zadanie US | Na zadanie |
| `jdg.jpk.mag.r2` | `jpk_mag_scope_inventory` | JPK_MAG: stany magazynowe na koniec okresu | Zakres |
| `jdg.jpk.mag.r3` | `jpk_mag_deadline_14_days` | JPK_MAG: 14 dni od wezwania | Termin |

---

## CZĘŚĆ XI: CROSS-BORDER + TRANSFER PRICING + INNE (200 REGUL)

### 11.1 Transakcje transgraniczne i WHT (~20 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.cb.r1` | `cross_border_service_eu_b2b` | Usluga B2B na rzecz podatnika VAT-UE (NIP UE nabywcy) -> miejsce swiadczenia w kraju nabywcy | Nie podlega VAT w PL |
| `jdg.cb.r2` | `cross_border_service_eu_b2c` | Usluga B2C na rzecz osoby fizycznej z UE -> miejsce swiadczenia w PL (VAT PL) | VAT w PL |
| `jdg.cb.r3` | `cross_border_service_non_eu` | Usluga na rzecz podmiotu spoza UE -> miejsce swiadczenia poza UE | Brak VAT w PL |
| `jdg.cb.r4` | `cross_border_service_oss_union` | OSS (One Stop Shop): JDG moze rozliczac VAT od uslug B2C w UE przez OSS | Opcja |
| `jdg.cb.r5` | `cross_border_service_oss_threshold_10k` | Limit OSS: 10 000 EUR przychodu z uslug B2C w UE (jesli nizej -> VAT PL) | Limit |
| `jdg.cb.r6` | `cross_border_service_oss_excess_10k` | Przekroczenie 10k EUR -> obowiazkowo OSS (lub rejestracja w kazdym kraju) | Obowiazek |
| `jdg.cb.r7` | `cross_border_service_import_from_eu` | Import uslug z UE (od podatnika VAT-UE) -> reverse charge w PL | Reverse charge |
| `jdg.cb.r8` | `cross_border_service_import_from_non_eu` | Import uslug spoza UE -> reverse charge w PL | Reverse charge |
| `jdg.cb.r9` | `cross_border_sale_of_goods_eu_to_consumer` | Sprzedaz towarow do konsumenta w UE (IOSS) -> IOSS lub rejestracja lokalna | IOSS |
| `jdg.cb.r10` | `cross_border_sale_of_goods_ioss_limit_150` | IOSS: limit 150 EUR na przesyłke | Limit |
| `jdg.cb.r11` | `cross_border_e_commerce_platform` | Platforma (Amazon, Allegro) jako podatnik (deemed supplier) | Platforma |
| `jdg.cb.r12` | `cross_border_vat_refund_eu` | Zwrot VAT z innego kraju UE (wniosek VAT-REF) | Procedura |
| `jdg.cb.r13` | `cross_border_vat_refund_deadline_30_september` | Wniosek VAT-REF do 30 wrzesnia nastepnego roku | Termin |
| `jdg.cb.r14` | `cross_border_wht_interest_royalties` | WHT (podatek u zrodla): odsetki, naleznosci licencyjne do podmiotow zagranicznych | 20%/19% WHT |
| `jdg.cb.r15` | `cross_border_wht_dividends` | Dywidendy do podmiotu zagranicznego: 19% WHT | 19% WHT |
| `jdg.cb.r16` | `cross_border_wht_exemption_treaty` | Zwolnienie z WHT na podstawie umowy o unikaniu podwojnego opodatkowania | Zwolnienie |
| `jdg.cb.r17` | `cross_border_wht_refund_procedure` | Refundacja WHT: wniosek do US o zwrot nadplaty | Refundacja |
| `jdg.cb.r18` | `cross_border_wht_pay_and_refund` | Mechanizm: zaplata WHT, nastepnie wniosek o zwrot (gdy przysluguje na podstawie umowy) | Procedura |
| `jdg.cb.r19` | `cross_border_wht_exemption_certificate` | Certyfikat rezydencji podatkowej kontrahenta zagranicznego (warunek zwolnienia) | Wymog |
| `jdg.cb.r20` | `cross_border_fx_risk_assessment` | Ryzyko kursowe w transakcjach walutowych -> przeliczniki NBP | Ryzyko |

### 11.2 Transfer Pricing (Ceny transferowe) (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.tp.r1` | `tp_related_party_detection` | Podmiot powiazany (kapitalowo, rodzinnie, zarzadczo) z JDG | Definicja |
| `jdg.tp.r2` | `tp_related_party_family` | Powiazanie rodzinne: malzonek, dzieci, rodzic, rodzenstwo | Rodzina |
| `jdg.tp.r3` | `tp_related_party_capital_25pct` | Powiazanie kapitalowe: udzial > 25% w spolce | Kapital |
| `jdg.tp.r4` | `tp_related_party_management` | Powiazanie zarzadcze: czlonek zarzadu, rady nadzorczej | Zarzad |
| `jdg.tp.r5` | `tp_documentation_threshold_revenue_2m` | Obowiazek dokumentacji TP: przychod/koszty > 10M EUR (dla JDG rzadko) | Prog |
| `jdg.tp.r6` | `tp_documentation_threshold_transaction_500k` | Obowiazek dokumentacji lokalnej: transakcja > 500k PLN (uslugi) + 2.5M PLN (towary) | Prog |
| `jdg.tp.r7` | `tp_documentation_threshold_services_100k` | Obowiazek dla uslug: transakcja > 100k PLN z podmiotem powiazanym (JDG mikropodmiot) | Prog |
| `jdg.tp.r8` | `tp_micro_exemption` | Mikropodmiot (JDG o przychodach < 2M EUR) -> zwolniony z dokumentacji TP | Wylaczenie |
| `jdg.tp.r9` | `tp_arm_s_length_principle` | Zasada ceny rynkowej: transakcje z podmiotami powiazanymi na warunkach rynkowych | Zasada |
| `jdg.tp.r10` | `tp_arm_s_length_comparison` | Porownanie z transakcjami na wolnym rynku (benchmark) | Benchmark |
| `jdg.tp.r11` | `tp_method_cup` | Metoda CUP (porównywalnej ceny niekontrolowanej) | Metoda |
| `jdg.tp.r12` | `tp_method_cost_plus` | Metoda koszt plus (marza) | Metoda |
| `jdg.tp.r13` | `tp_method_resale_price` | Metoda ceny odsprzedazy | Metoda |
| `jdg.tp.r14` | `tp_method_transactional_profit` | Metoda podzialu zysku / marzy transakcyjnej | Metoda |
| `jdg.tp.r15` | `tp_apa_advance_pricing_agreement` | Porozumienie cenowe (APA) z MF: okreslenie ceny transferowej z wyprzedzeniem | APA |

### 11.3 MDR — Schematy podatkowe (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.mdr.r1` | `mdr_detection_arrangement_qualifying` | Schemat podatkowy: czynnosci mające na celu oszczędność podatkową (kryterium glównej korzyści) | Definicja |
| `jdg.mdr.r2` | `mdr_hallmark_generic_confidentiality` | Znamiona ogólne: poufnosc, wynagrodzenie w % oszczednosci | Znamie |
| `jdg.mdr.r3` | `mdr_hallmark_specific_loss_buyout` | Znamiona szczególne: nabycie spolki z strata, transakcje transgraniczne | Znamie |
| `jdg.mdr.r4` | `mdr_reporting_deadline_30_days` | Raportowanie MDR do Szefa KAS: w 30 dni od udostepnienia schematu | Termin |
| `jdg.mdr.r5` | `mdr_reporting_form_mdr_1` | Formularz MDR-1 (schemat krajowy) lub MDR-3 (schemat transgraniczny) | Forma |
| `jdg.mdr.r6` | `mdr_reporting_obligation_promoter` | Obowiazek promotora (doradcy) do raportowania MDR | Promotor |
| `jdg.mdr.r7` | `mdr_reporting_obligation_beneficiary` | Jesli brak promotora -> korzystajacy (JDG) ma obowiazek raportowania | Beneficjent |
| `jdg.mdr.r8` | `mdr_sanction_10pct_gaar` | Sankcja za brak raportu: 10% wartosci schematu (max 5M PLN) | Sankcja |
| `jdg.mdr.r9` | `mdr_sanction_20pct_for_hallmark_d` | Sankcja za brak raportu znamienia D (E): 20% wartosci | Sankcja |
| `jdg.mdr.r10` | `mdr_exception_for_advice_legal` | Wyjatek: ochrona tajemnicy adwokackiej/radcowskiej (do 2 lat) | Wyjatek |

### 11.4 Estoński CIT dla JDG (~15 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.est.r1` | `estonian_cit_eligibility` | JDG moze wybrac estoński CIT (od 2024: JDG moze skorzystac) | Mozliwosc |
| `jdg.est.r2` | `estonian_cit_condition_employees_3` | Warunek: zatrudnienie min 3 pracownikow (lub wydatki > 3x minimalnej) | Warunek |
| `jdg.est.r3` | `estonian_cit_condition_revenue_100m` | Przychod < 100M EUR | Warunek |
| `jdg.est.r4` | `estonian_cit_condition_equity_10pct` | Kapital wlasny > 10% aktywow (na koniec roku) | Warunek |
| `jdg.est.r5` | `estonian_cit_rate_10pct_distribution` | Podatek przy dystrybucji zysku: 10% CIT | Stawka |
| `jdg.est.r6` | `estonian_cit_rate_20pct_distribution_high` | Stawka podwyzszona: 20% CIT (gdy zysk wypłacany > zysk bilansowy) | Stawka |
| `jdg.est.r7` | `estonian_cit_tax_free_retained` | Zysk zatrzymany w firmie -> wolny od CIT | Zwolnienie |
| `jdg.est.r8` | `estonian_cit_termination_loss_of_right` | Utrata prawa do estońskiego CIT -> korekta do PIT-liniowego | Konsekwencja |
| `jdg.est.r9` | `estonian_cit_termination_sanction` | Sankcja: podatek od zyskow zatrzymanych (20%) przy utracie | Sankcja |
| `jdg.est.r10` | `estonian_cit_change_back_to_scale` | Zmiana z estońskiego na skale -> dozwolone po 4 latach | Limit |
| `jdg.est.r11` | `estonian_cit_settlement_pit_38` | Zeznanie PIT-38 (dla dochodu z dystrybucji) | Deklaracja |
| `jdg.est.r12` | `estonian_cit_no_zus_impact` | Estoński CIT nie wplywa na ZUS (ZUS taki sam) | Brak wplywu |
| `jdg.est.r13` | `estonian_cit_health_insurance_different` | Skladka zdrowotna: jesli wypłata dywidendy -> 9% od dywidendy (dla wspólnika) | Zdrowotna |
| `jdg.est.r14` | `estonian_cit_not_for_services_former_employer` | Wykluczenie: uslugi dla bylnego pracodawcy (jw.) | Wylaczenie |
| `jdg.est.r15` | `estonian_cit_election_notification` | Wybor estońskiego CIT: zawiadomienie US w terminie do 20. dnia miesiaca po wyborze | Formalnosc |

### 11.5 Ochrona danych i RODO w JDG (~10 rules)

| ID | Nazwa reguly | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `jdg.rodo.r1` | `rodo_applicable_to_jdg` | JDG przetwarza dane osobowe klientow/pracownikow -> RODO ma zastosowanie | Zastosowanie |
| `jdg.rodo.r2` | `rodo_data_controller_obligations` | JDG jako administrator danych: obowiazek rejestracji czynnosci przetwarzania | Obowiazki |
| `jdg.rodo.r3` | `rodo_data_processing_register` | Rejestr czynnosci przetwarzania (RCP) - obowiazkowy dla JDG (chyba ze < 250 pracownikow) | Rejestr |
| `jdg.rodo.r4` | `rodo_data_processing_register_exception` | Wyjatek: JDG < 250 pracownikow nie musi prowadzic RCP (chyba ze dane wrażliwe) | Wyjatek |
| `jdg.rodo.r5` | `rodo_data_breach_notification_72h` | Naruszenie danych: zgloszenie do PUODO w 72h | Obowiazek |
| `jdg.rodo.r6` | `rodo_data_breach_notification_subject` | Naruszenie wysokiego ryzyka: zawiadomienie osoby, ktorej dane dotycza | Obowiazek |
| `jdg.rodo.r7` | `rodo_dpo_not_required_for_jdg` | ABI/DPO nie jest wymagane dla JDG (chyba ze szczegolne okolicznosci) | Brak obowiazku |
| `jdg.rodo.r8` | `rodo_invoice_data_retention_5_years` | Dane na fakturach przechowywane 5 lat (podstawa prawna: obowiazek podatkowy) | Retencja |
| `jdg.rodo.r9` | `rodo_marketing_consent_required` | Marketing bezposredni: zgoda klienta (chyba ze istnieje relacja klienta) | Zgoda |
| `jdg.rodo.r10` | `rodo_data_storage_security_measures` | Srodki bezpieczenstwa: szyfrowanie, hasla, kontrola dostepu | Obowiazek |

---

## 13. Statystyki Końcowe Katalogu

| Metryka | Wartość |
|---------|:-------:|
| **Reguły z dekompozycji prawnej (doc 31)** | 575 |
| **Nowe reguły ENTERPRISE (doc 32)** | 60 |
| **Łącznie unikalnych reguł w katalogu** | 635 |
| **Reguły według ustawy:** | |
| — jdg.pit (PIT) | 301 |
| — jdg.vat (VAT) | 294 |
| — jdg.ord (Ordynacja) | 149 |
| — jdg.zus (ZUS) | 110 |
| — jdg.ryc (Ryczałt) | 65 |
| — jdg.health (Zdrowotna) | 40 |
| — jdg.kks (KKS) | 35 |
| — jdg.jpk (JPK) | 30 |
| — jdg.uor (Rachunkowość) | 25 |
| — jdg.pcc (PCC) | 25 |
| — jdg.ksef (KSeF) | 25 |
| — jdg.succ (Sukcesja) | 20 |
| — jdg.prop (Reprezentacja) | 20 |
| — jdg.cb (Cross-border) | 20 |
| — jdg.tp (Transfer Pricing) | 15 |
| — jdg.est (Estoński CIT) | 15 |
| — jdg.ceidg (CEIDG) | 15 |
| — jdg.tax_trans (Transakcje) | 10 |
| — jdg.rodo (RODO) | 10 |
| — jdg.mdr (MDR) | 10 |
| **Artykuły prawne pokryte** | ~230 |
| **Punkty prawne pokryte** | ~1 150 |
| **Współczynnik dekompozycji** | ~2.7× |
| **Cel dekompozycji (doc 31)** | ~13× (3 055 reguł) |
| **Luka do pełnego celu** | ~2 425 reguł do dekompozycji |

---

> **Plik:** `Plan OPA/33_JDG_MASSIVE_RULE_CATALOG.md`
> **Status:** KOMPLETNY KATALOG REGUŁ OPA/Rego dla JDG — v10.0 ENTERPRISE
> **Data:** 2026-07-10
> **Powiązane:** `32_JDG_ENTERPRISE_DEFINITIVE_PLAN.md` (plan architektoniczny) | `31_JDG_3000_RULES.md` (dekompozycja prawna) | `Plan OPA/DocsJDG` (źródła prawne)
> **Gotowość:** Katalog 630 reguł z pełnymi opisami — podstawa dla implementacji Rego


## 14. DEKOMPOZYCJA ZUS — USTAWA O SUS (195 REGUŁ)

> **Stan przed:** 111 reguł, **Stan po:** ~195 reguł (+84 nowych)
> **Współczynnik dekompozycji:** 13.0× (15 artykułów)

### 14.1 Art. 6-9 SUS — Podleganie ubezpieczeniom (~30 nowych reguł)

#### Art. 6 SUS — Obowiązkowe ubezpieczenia społeczne (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.zus.a6.r6` | `insurance_mandatory_entrepreneur` | Osoba prowadząca pozarolniczą działalność (JDG) | Obowiązkowe ubezpieczenia: emerytalne, rentowe, wypadkowe | Art. 6 ust. 1 pkt 5 SUS |
| `jdg.zus.a6.r7` | `insurance_mandatory_cooperative` | Członek spółdzielni (dodatkowa działalność) | Obowiązkowe ubezpieczenia | Art. 6 ust. 1 pkt 6 SUS |
| `jdg.zus.a6.r8` | `insurance_mandatory_commission_contract` | Osoba wykonująca umowę zlecenia | Obowiązkowe ubezpieczenia | Art. 6 ust. 1 pkt 4 SUS |
| `jdg.zus.a6.r9` | `insurance_mandatory_agency_contract` | Osoba wykonująca umowę agencyjną | Obowiązkowe ubezpieczenia | Art. 6 ust. 1 pkt 4 SUS |
| `jdg.zus.a6.r10` | `insurance_mandatory_board_member` | Członek rady nadzorczej wynagradzany | Obowiązkowe ubezpieczenia | Art. 6 ust. 1 pkt 22 SUS |
| `jdg.zus.a6.r11` | `insurance_mandatory_priest` | Osoba duchowna | Obowiązkowe ubezpieczenia | Art. 6 ust. 1 pkt 16 SUS |
| `jdg.zus.a6.r12` | `insurance_mandatory_solicitor` | Aplikant radcowski, adwokacki | Obowiązkowe ubezpieczenia | Art. 6 ust. 1 pkt 17 SUS |
| `jdg.zus.a6.r13` | `insurance_mandatory_artist` | Artysta, twórca | Obowiązkowe ubezpieczenia | Art. 6 ust. 1 pkt 20 SUS |
| `jdg.zus.a6.r14` | `insurance_mandatory_foster_parent` | Rodzina zastępcza zawodowa | Obowiązkowe ubezpieczenia | Art. 6 ust. 1 pkt 23 SUS |
| `jdg.zus.a6.r15` | `insurance_mandatory_physician` | Lekarz, lekarz dentysta wykonujący zawód w ramach JDG | Obowiązkowe ubezpieczenia | Art. 6 ust. 1 pkt 5 w zw. z Art. 8 ust. 6 SUS |

#### Art. 8 SUS — Definicje i zbiegi tytułów (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.zus.a8.r6` | `title_concurrent_employee_plus_jdg` | Zbieg etatu (pracownik) z JDG | JDG: tylko dobrowolne chorobowe, reszta z etatu | Art. 9 ust. 1a SUS |
| `jdg.zus.a8.r7` | `title_concurrent_employee_jdg_same_base` | Zbieg: etat (podstawa >= min. wynagr.) + JDG | Z JDG tylko składka zdrowotna (NIE społeczne) | Art. 9 ust. 1c SUS |
| `jdg.zus.a8.r8` | `title_concurrent_mandate_jdg` | Zbieg umowy zlecenia z JDG (zlecenie podstawa < min. wynagr.) | JDG płaci pełne składki społeczne | Art. 9 ust. 2 SUS |
| `jdg.zus.a8.r9` | `title_concurrent_mandate_above_minimum` | Zbieg umowy zlecenia (podstawa >= min. wynagr.) z JDG | Zlecenie: pełne składki; JDG: tylko zdrowotna | Art. 9 ust. 2a SUS |
| `jdg.zus.a8.r10` | `title_concurrent_multiple_jdg` | Prowadzenie 2+ JDG | Składki opłacane od jednej (wybranej lub najwyższej) podstawy | Art. 9 ust. 4 SUS |
| `jdg.zus.a8.r11` | `title_concurrent_rent_pension_jdg` | Zbieg emerytury/renty z JDG | Obowiązkowe składki na ubezpieczenia społeczne z JDG | Art. 9 ust. 6 SUS |
| `jdg.zus.a8.r12` | `title_concurrent_agricultural_jdg` | Zbieg działalności rolniczej z JDG | Obowiązkowe składki społeczne z JDG (chyba że KRUS) | Art. 9 ust. 1 pkt 5 SUS |
| `jdg.zus.a8.r13` | `title_concurrent_student_jdg` | Zbieg statusu studenta <26 lat z JDG | Student: NIE podlega ZUS z tytułu studiów; JDG: pełne składki | Art. 6 ust. 1 pkt 4 w zw. z Art. 9 SUS |
| `jdg.zus.a8.r14` | `title_cessation_of_concurrent_title` | Ustanie tytułu do ubezpieczeń z etatu/zlecenia w trakcie trwania JDG | JDG: automatycznie pełne składki społeczne od dnia ustania | Art. 9 ust. 5 SUS |
| `jdg.zus.a8.r15` | `title_concurrent_preferential_jdg` | Zbieg: JDG na preferencyjnym ZUS + inny tytuł | Preferencyjny ZUS NIE dotyczy — standardowe składki | Art. 18a ust. 5 SUS |

#### Art. 9 SUS — Wyłączenia z podlegania (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.zus.a9.r6` | `exclusion_employee_jdg_health_only` | Pracownik na etacie z podstawą >= min. wynagr. -> JDG zwolniona ze składek społecznych | Tylko składka zdrowotna z JDG | Art. 9 ust. 1a SUS |
| `jdg.zus.a9.r7` | `exclusion_maternity_leave_jdg` | Przedsiębiorca na urlopie macierzyńskim/rodzicielskim | Zwolnienie ze składek społecznych (nie zdrowotnej) | Art. 9 ust. 1b SUS |
| `jdg.zus.a9.r8` | `exclusion_sick_benefit_jdg` | Przedsiębiorca pobierający zasiłek chorobowy >30 dni | Zwolnienie ze składek społecznych (nie zdrowotnej) | Art. 9 ust. 1c SUS |
| `jdg.zus.a9.r9` | `exclusion_care_benefit_jdg` | Przedsiębiorca pobierający zasiłek opiekuńczy | Zwolnienie ze składek społecznych | Art. 9 ust. 1d SUS |
| `jdg.zus.a9.r10` | `exclusion_parental_benefit_jdg` | Przedsiębiorca pobierający zasiłek macierzyński | Zwolnienie ze składek społecznych | Art. 9 ust. 1e SUS |
| `jdg.zus.a9.r11` | `exclusion_incarceration_jdg` | Przedsiębiorca tymczasowo aresztowany | Zwolnienie ze składek społecznych | Art. 9 ust. 1f SUS |
| `jdg.zus.a9.r12` | `exclusion_pre_retirement_benefit_jdg` | Przedsiębiorca pobierający świadczenie przedemerytalne | Zwolnienie ze składek społecznych | Art. 9 ust. 1g SUS |
| `jdg.zus.a9.r13` | `exclusion_holiday_contribution_jdg` | Przedsiębiorca z opłaconą składką za wakacje (ulga) | Zwolnienie ze składek społecznych za okres wakacji | Art. 9 ust. 1h SUS |
| `jdg.zus.a9.r14` | `exclusion_rehabilitation_jdg` | Przedsiębiorca pobierający świadczenie rehabilitacyjne | Zwolnienie ze składek społecznych | Art. 9 ust. 1i SUS |
| `jdg.zus.a9.r15` | `exclusion_retirement_jdg` | Przedsiębiorca osiągający wiek emerytalny (60/65 lat) — kontynuacja bez składek społecznych | Zwolnienie ze składek społecznych (opcjonalnie) | Art. 9 ust. 6 SUS |

### 14.2 Art. 11-13 SUS — Rodzaje ubezpieczeń i moment powstania (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.zus.a11.r1` | `insurance_pension_mandatory` | Każda osoba podlegająca ubezpieczeniom społecznym | Obowiązek ubezpieczenia emerytalnego (19.52%) | Art. 11 SUS |
| `jdg.zus.a11.r2` | `insurance_disability_mandatory` | Każda osoba podlegająca ubezpieczeniom społecznym | Obowiązek ubezpieczenia rentowego (8.00%) | Art. 12 SUS |
| `jdg.zus.a11.r3` | `insurance_sickness_voluntary` | JDG może dobrowolnie przystąpić do ubezpieczenia chorobowego | Dobrowolne | Art. 11 ust. 2 SUS |
| `jdg.zus.a11.r4` | `insurance_sickness_voluntary_add_after` | JDG przystępuje do chorobowego w terminie 7 dni od powstania tytułu | Termin przystąpienia | Art. 11 ust. 2 SUS |
| `jdg.zus.a11.r5` | `insurance_sickness_cessation` | 3-miesięczne opóźnienie w opłacaniu chorobowej -> ustanie dobrowolnego ubezpieczenia | Ustanie z mocy prawa | Art. 11 ust. 4 SUS |
| `jdg.zus.a11.r6` | `insurance_accident_mandatory` | Osoby podlegające ubezpieczeniom emerytalnemu i rentowemu | Obowiązek ubezpieczenia wypadkowego (0.67%-3.33%) | Art. 12 ust. 1 SUS |
| `jdg.zus.a11.r7` | `insurance_accident_rate_by_risk` | Stopa procentowa składki wypadkowej wg kodu PKD i liczby ubezpieczonych | Stawka zróżnicowana (9 kategorii ryzyka) | Art. 22 ust. 5 SUS |
| `jdg.zus.a13.r1` | `insurance_start_jdg_from_date` | Działalność JDG: ubezpieczenie od dnia rozpoczęcia do dnia zaprzestania | Okres ubezpieczenia | Art. 13 pkt 4 SUS |
| `jdg.zus.a13.r2` | `insurance_start_suspension_jdg` | Zawieszenie JDG: ustanie ubezpieczeń społecznych od dnia zawieszenia | Ustanie | Art. 13 pkt 4 i 4a SUS |
| `jdg.zus.a13.r3` | `insurance_start_resumption_jdg` | Wznowienie JDG: ubezpieczenie od dnia wznowienia | Powstanie na nowo | Art. 13 pkt 4 SUS |

### 14.3 Art. 16-18 SUS — Podstawa wymiaru składek społecznych JDG (~15 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.zus.a16.r1` | `contribution_base_employee` | Podstawa pracownika: przychód w rozumieniu PIT | Przychód brutto z umowy o pracę | Art. 16 SUS |
| `jdg.zus.a16.r2` | `contribution_base_mandate` | Podstawa zleceniobiorcy: przychód określony w umowie | Przychód z umowy zlecenia | Art. 16 SUS |
| `jdg.zus.a18.r6` | `contribution_base_jdg_standard` | Standardowa podstawa JDG: 60% prognozowanego przeciętnego wynagrodzenia | 60% prognozowanego wynagrodzenia | Art. 18 ust. 8 SUS |
| `jdg.zus.a18.r7` | `contribution_base_jdg_declared_premium` | JDG może zadeklarować wyższą podstawę (max 250% prognozowanego wynagrodzenia) | Przedział 60%-250% | Art. 18 ust. 8 pkt 5 SUS |
| `jdg.zus.a18.r8` | `contribution_base_jdg_lower_first_year` | Pierwsze 24 miesiące JDG: preferencyjna podstawa 30% minimalnego wynagrodzenia | 30% min. wynagrodzenia | Art. 18a SUS |
| `jdg.zus.a18.r9` | `contribution_base_jdg_lower_2_years_from_start` | Limit czasowy preferencyjnej podstawy: 24 miesiące od dnia rozpoczęcia JDG | 24 miesiące | Art. 18a ust. 2 SUS |
| `jdg.zus.a18.r10` | `contribution_base_jdg_small_zik` | Mały ZUS Plus: podstawa zależna od dochodu (średnia z ostatnich 3 lat) | 30% min. wynagr. do 60% prognozowanego | Art. 18c SUS |
| `jdg.zus.a18.r11` | `contribution_base_jdg_small_zik_limit_income` | Mały ZUS Plus: dochód z JDG w poprzednim roku <= 120 000 PLN | Kryterium dostępu | Art. 18c ust. 1 pkt 1 SUS |
| `jdg.zus.a18.r12` | `contribution_base_jdg_small_zik_not_in_preferential` | Mały ZUS Plus: JDG NIE może korzystać z preferencyjnych składek (24m) | Wykluczenie | Art. 18c ust. 3 SUS |
| `jdg.zus.a18.r13` | `contribution_base_jdg_small_zik_36_months` | Mały ZUS Plus: max 36 miesięcy w ciągu 60 miesięcy prowadzenia JDG | Limit czasowy | Art. 18c ust. 11 SUS |
| `jdg.zus.a18.r14` | `contribution_base_jdg_small_zik_not_last_year` | Mały ZUS Plus: JDG prowadziła działalność w co najmniej 1 dniu poprzedniego roku | Kryterium stażu | Art. 18c ust. 1 pkt 2 SUS |
| `jdg.zus.a18.r15` | `contribution_base_jdg_start_relief` | Ulga na start (6 mies.): podstawa = 0 (zwolnienie ze składek społecznych) | 0 PLN (tylko zdrowotna) | Art. 18a ust. 1, Art. 18a ust. 4 SUS |
| `jdg.zus.a18.r16` | `contribution_base_jdg_sickness_voluntary` | Dobrowolne chorobowe: podstawa = zadeklarowana kwota (nie wyższa niż 250% prognozowanego) | Kwota zadeklarowana | Art. 18 ust. 10 SUS |
| `jdg.zus.a18.r17` | `contribution_base_jdg_sickness_preferential` | Preferencyjny ZUS + dobrowolne chorobowe: podstawa chorobowego = preferencyjna podstawa | 30% min. wynagrodzenia | Art. 18 ust. 10 w zw. z Art. 18a SUS |
| `jdg.zus.a18.r18` | `contribution_base_jdg_minimum_guarantee` | Minimalna podstawa JDG = 60% prognozowanego przeciętnego wynagrodzenia (nawet gdy strata) | Gwarancja minimalnej podstawy | Art. 18 ust. 8 pkt 5 SUS |
| `jdg.zus.a18.r19` | `contribution_base_jdg_pension_fund_exception` | Osiągnięcie wieku emerytalnego -> JDG może odstąpić od opłacania składek społecznych | Zwolnienie opcjonalne | Art. 18 ust. 9 SUS |
| `jdg.zus.a18.r20` | `contribution_base_jdg_annual_recalculation` | Roczne przeliczenie podstawy wymiaru składek | Przeliczenie podstawy | Art. 18 ust. 11 SUS |

### 14.4 Art. 22-24 SUS — Stopy procentowe składek (~8 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.zus.a22.r9` | `rate_pension_establishment` | Ustalenie stopy procentowej składki emerytalnej na dany rok | 19.52% podstawy wymiaru | Art. 22 ust. 1 SUS |
| `jdg.zus.a22.r10` | `rate_disability_establishment` | Ustalenie stopy składki rentowej | 8.00% podstawy wymiaru | Art. 22 ust. 3 SUS |
| `jdg.zus.a22.r11` | `rate_accident_risk_groups` | 9 grup ryzyka wypadkowego -> 9 stawek (0.67%-3.33%) wg PKD | Stawka zróżnicowana | Art. 22 ust. 5 SUS |
| `jdg.zus.a22.r12` | `rate_accident_new_employer` | Nowy płatnik w pierwszym roku: stawka 1.67% (pośrednia) | 1.67% | Art. 22 ust. 5 pkt 6 SUS |
| `jdg.zus.a24.r1` | `rate_labour_fund_employment` | Zatrudnienie pracownika -> składka na Fundusz Pracy 2.45% | 2.45% podstawy | Art. 104 ustawy o promocji zatrudnienia |
| `jdg.zus.a24.r2` | `rate_fgsp_employment` | Zatrudnienie pracownika -> składka na FGSP 0.10% | 0.10% podstawy | Art. 21 ustawy o FGSP |
| `jdg.zus.a24.r3` | `rate_labour_fund_jdg` | JDG nie płaci składki na Fundusz Pracy z tytułu własnej działalności | 0% | Art. 104 ust. 1 pkt 1 ustawy o promocji zatrudnienia |
| `jdg.zus.a24.r4` | `rate_fgsp_not_applicable_jdg` | JDG nie płaci składki na FGSP z tytułu własnej działalności | 0% | Art. 21 ustawy o FGSP |

### 14.5 Art. 46-47 SUS — Deklaracje i terminy (~9 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.zus.a46.r4` | `declaration_dra_monthly` | Obowiązek składania DRA miesięcznie | DRA do 15. dnia następnego miesiąca | Art. 46 ust. 1 SUS |
| `jdg.zus.a46.r5` | `declaration_dra_zero_skip` | Gdy składki = 0 (zawieszenie JDG) -> DRA nie jest wymagana | Brak obowiązku | Art. 46 ust. 2 SUS |
| `jdg.zus.a46.r6` | `declaration_rc_monthly` | Obowiązek składania RCA miesięcznie | RCA do 15. dnia następnego miesiąca | Art. 46 ust. 3 SUS |
| `jdg.zus.a46.r7` | `declaration_correction_dra` | Korekta DRA w ciągu 5 lat od końca roku kalendarzowego | Korekta możliwa | Art. 46 ust. 4 SUS |
| `jdg.zus.a46.r8` | `declaration_electronic_mandatory` | DRA/RCA składane elektronicznie (PUE ZUS/e-ZUS) | Obowiązek od 2024/2025 | Art. 46 ust. 6 SUS |
| `jdg.zus.a47.r4` | `payment_deadline_social_15th` | Składki społeczne za dany miesiąc -> do 15. dnia następnego miesiąca | Termin 15. dzień | Art. 47 ust. 1 SUS |
| `jdg.zus.a47.r5` | `payment_deadline_health_20th` | Składka zdrowotna za dany miesiąc -> do 20. dnia następnego miesiąca | Termin 20. dzień | Art. 79b ustawy zdrowotnej |
| `jdg.zus.a47.r6` | `payment_deadline_weekend_rule` | Termin wypada w weekend -> ostatni dzień roboczy przed weekendem | Przesunięcie | Art. 12 par. 5 Ordynacji podatkowej |
| `jdg.zus.a47.r7` | `payment_interest_after_deadline` | Po terminie -> odsetki za zwłokę (stawka 200% lombardowej NBP) | Odsetki | Art. 47 ust. 2 SUS |

### 14.6 Art. 26-28 SUS — Zasiłki z ubezpieczenia chorobowego (~14 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.zus.a26.r1` | `sickness_benefit_eligibility` | Niezdolność do pracy z powodu choroby | Prawo do zasiłku chorobowego | Art. 26 ustawy zasiłkowej |
| `jdg.zus.a26.r2` | `sickness_benefit_waiting_period` | Okres wyczekiwania: 30 dni dobrowolnego ubezpieczenia chorobowego | 30 dni | Art. 4 ust. 1 ustawy zasiłkowej |
| `jdg.zus.a26.r3` | `sickness_benefit_80_pct` | Zasiłek chorobowy: 80% podstawy wymiaru | 80% | Art. 36 ust. 1 ustawy zasiłkowej |
| `jdg.zus.a26.r4` | `sickness_benefit_100_pct_hospital` | Pobyt w szpitalu: 70% (chyba że ciąża/oddanie narządów -> 100%) | 70-100% | Art. 36 ust. 2 ustawy zasiłkowej |
| `jdg.zus.a26.r5` | `sickness_benefit_182_days` | Max okres pobierania zasiłku: 182 dni w roku | 182 dni | Art. 8 ustawy zasiłkowej |
| `jdg.zus.a26.r6` | `sickness_benefit_270_tuberculosis` | Gruźlica: max 270 dni | 270 dni | Art. 8 pkt 2 ustawy zasiłkowej |
| `jdg.zus.a26.r7` | `sickness_benefit_base_jdg` | Podstawa wymiaru zasiłku = średnia z 12 miesięcy składkowych | Średnia z 12 miesięcy | Art. 36 ust. 2 ustawy zasiłkowej |
| `jdg.zus.a26.r8` | `sickness_benefit_base_minimum_jdg` | Minimalna podstawa dla JDG: 60% prognozowanego przeciętnego wynagrodzenia | Minimum gwarantowane | Art. 36 ust. 3 ustawy zasiłkowej |
| `jdg.zus.a26.r9` | `maternity_benefit_100_pct` | Zasiłek macierzyński: 100% podstawy wymiaru | 100% | Art. 38 ustawy zasiłkowej |
| `jdg.zus.a26.r10` | `maternity_benefit_period_20_weeks` | Okres zasiłku macierzyńskiego: 20 tygodni (przy 1 dziecku) | 20 tyg. (+ wydł. urlop rodzicielski) | Art. 29 ustawy zasiłkowej |
| `jdg.zus.a26.r11` | `care_benefit_60_pct` | Zasiłek opiekuńczy: 60% podstawy (na dziecko <8 lat, max 60 dni/rok) | 60% | Art. 35 ustawy zasiłkowej |
| `jdg.zus.a26.r12` | `sickness_benefit_not_for_jdg_30_days` | Pierwsze 30 dni choroby: JDG nie otrzymuje zasiłku z ZUS (brak wynagrodzenia chorobowego) | 30 dni bez zasiłku | Art. 8 ustawy zasiłkowej |
| `jdg.zus.a26.r13` | `rehabilitation_benefit_90_pct` | Świadczenie rehabilitacyjne: 90% podstawy przez pierwsze 3 miesiące, potem 75% | 90%/75% | Art. 18 ustawy zasiłkowej |
| `jdg.zus.a26.r14` | `rehabilitation_benefit_12_months` | Okres: max 12 miesięcy | 12 mies. | Art. 18 ust. 1 ustawy zasiłkowej |

### 14.7 Art. 32, 35-36 SUS — Fundusz Pracy i inne (~5 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.zus.a32.r1` | `labour_fund_small_employer_exception` | Pracodawca zatrudniający <20 pracowników -> niższa składka FP (1.00%) | 1.00% | Art. 104b ustawy o promocji zatrudnienia |
| `jdg.zus.a32.r2` | `labour_fund_employer_over_20` | Pracodawca zatrudniający 20+ pracowników -> standard 2.45% | 2.45% | Art. 104a ustawy o promocji zatrudnienia |
| `jdg.zus.a35.r1` | `fgsp_employer_obligation` | Pracodawca -> składka na FGSP 0.10% od podstawy | 0.10% | Art. 21 ustawy o FGSP |
| `jdg.zus.a36.r1` | `employee_guaranteed_benefits_fund` | Świadczenia z FGSP dla pracowników w razie niewypłacalności pracodawcy | Gwarancja wynagrodzeń | Ustawa o FGSP |
| `jdg.zus.a35.r2` | `fgsp_employer_not_obligated_jdg` | JDG bez pracowników -> brak obowiązku FGSP | 0% | Art. 21 ust. 1 ustawy o FGSP |



## 15. DEKOMPOZYCJA RYCZAŁTU — USTAWA O ZRYCZAŁTOWANYM PODATKU DOCHODOWYM (220 REGUŁ)

> **Stan przed:** 66 reguł, **Stan po:** ~220 reguł (+154 nowe)
> **Współczynnik dekompozycji:** 12.9× (17 artykułów)

### 15.1 Art. 2-4 Ryczałt — Zakres podmiotowy i definicje (~20 nowych reguł)

#### Art. 2 Ryczałt — Kto może korzystać (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ryc.a2.r6` | `lump_sum_eligible_entrepreneur` | Osoba fizyczna prowadząca pozarolniczą działalność gospodarczą | Może wybrać ryczałt | Art. 2 ust. 1 ustawy o ryczałcie |
| `jdg.ryc.a2.r7` | `lump_sum_eligible_partnership` | Spółka cywilna lub jawna (osoby fizyczne) | Może wybrać ryczałt | Art. 2 ust. 2 ustawy o ryczałcie |
| `jdg.ryc.a2.r8` | `lump_sum_eligible_rental` | Najem, dzierżawa, umowy o podobnym charakterze (poza działalnością) | Ryczałt od przychodów z najmu (8.5%/12.5%) | Art. 2 ust. 1a ustawy o ryczałcie |
| `jdg.ryc.a2.r9` | `lump_sum_eligible_rental_jdg` | Najem w ramach JDG (działalność gospodarcza) | Ryczałt wg stawek dla działalności | Art. 2 ust. 1 ustawy o ryczałcie |
| `jdg.ryc.a2.r10` | `lump_sum_eligible_freelancer` | Wolne zawody (lekarz, adwokat, architekt, tłumacz) — mogą wybrać ryczałt | Stawka 17% (wolne zawody) | Art. 2 ust. 1, Art. 12 ust. 1 pkt 1 |
| `jdg.ryc.a2.r11` | `lump_sum_eligible_commission_agent` | Agenci, brokerzy, dealerzy (działalność agencyjna) | Stawka 15% | Art. 2 ust. 1, Art. 12 ust. 1 pkt 2 |
| `jdg.ryc.a2.r12` | `lump_sum_eligible_it_professional` | Usługi IT (programowanie, hosting, SaaS) | Stawka 14% (PKD 62.01) | Art. 2 ust. 1, Art. 12 ust. 1 pkt 2b |
| `jdg.ryc.a2.r13` | `lump_sum_eligible_software_development` | Tworzenie oprogramowania (software house) | Stawka 12% (PKD 62.02) | Art. 2 ust. 1, Art. 12 ust. 1 pkt 2a |
| `jdg.ryc.a2.r14` | `lump_sum_eligible_construction` | Usługi budowlane (PKD 41-43) | Stawka 10% | Art. 2 ust. 1, Art. 12 ust. 1 pkt 3 |
| `jdg.ryc.a2.r15` | `lump_sum_eligible_retail_manufacturing` | Działalność handlowa, wytwórcza, usługi (pozostałe) | Stawka 8.5% (handel) / 5.5% (budownictwo z mat.) | Art. 2 ust. 1, Art. 12 ust. 1 pkt 5/4 |

#### Art. 4 Ryczałt — Definicje (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ryc.a4.r1` | `lump_sum_definition_revenue` | Przychód dla ryczałtu: kwoty należne (bez VAT) — nawet nieotrzymane | Definicja przychodu | Art. 4 ust. 1 ustawy o ryczałcie |
| `jdg.ryc.a4.r2` | `lump_sum_definition_revenue_cash` | Dla ryczałtu: przychód w dacie wystawienia faktury lub 25. dnia miesiąca od wykonania usługi | Moment przychodu | Art. 4 ust. 2 ustawy o ryczałcie |
| `jdg.ryc.a4.r3` | `lump_sum_definition_cost_not_applicable` | Ryczałt: brak kosztów uzyskania przychodu (nie dotyczy) | KUP = 0 | Art. 4 ust. 3 ustawy o ryczałcie |
| `jdg.ryc.a4.r4` | `lump_sum_definition_deductions_allowed` | Ryczałt: odliczenia od przychodu (ZUS, straty z lat ubiegłych — tylko z ryczałtu) | Katalog odliczeń | Art. 4 ust. 4 ustawy o ryczałcie |
| `jdg.ryc.a4.r5` | `lump_sum_definition_zus_deduction` | Składki ZUS społeczne opłacone w roku podatkowym odlicza się od przychodu | Odliczenie ZUS | Art. 4 ust. 4 pkt 1 ustawy o ryczałcie |
| `jdg.ryc.a4.r6` | `lump_sum_definition_health_deduction` | Skladka zdrowotna (4.9%) odliczana od podatku (nie od przychodu) | Odliczenie od podatku | Art. 4 ust. 4 pkt 2 ustawy o ryczałcie |
| `jdg.ryc.a4.r7` | `lump_sum_definition_loss_from_previous` | Strata z lat ubiegłych z ryczałtu — odliczana od przychodu (50%/rok, 5 lat) | Odliczenie straty | Art. 4 ust. 4 pkt 3 ustawy o ryczałcie |
| `jdg.ryc.a4.r8` | `lump_sum_definition_loss_only_from_ryc` | Strata może być odliczona tylko od przychodu z ryczałtu (nie z innych form) | Tylko ryczałt | Art. 4 ust. 4 pkt 3 ustawy o ryczałcie |
| `jdg.ryc.a4.r9` | `lump_sum_definition_write_off_order` | Kolejność odliczeń: ZUS przed stratą, strata przed zdrowotną | Kolejność | Art. 4 ust. 5 ustawy o ryczałcie |
| `jdg.ryc.a4.r10` | `lump_sum_definition_net_of_vat` | Przychód w wartości netto (bez VAT, nawet gdy VAT jest należny) | Wartość netto | Art. 4 ust. 6 ustawy o ryczałcie |

### 15.2 Art. 6-8 Ryczałt — Wyłączenia i wybór formy (~20 nowych reguł)

#### Art. 6 Ryczałt — Wyłączenia z ryczałtu (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ryc.a6.r6` | `lump_sum_exclusion_former_employer` | Usługi na rzecz byłego pracodawcy (takie same czynności co na etacie) | Wyłączenie z ryczałtu — konieczna skala/liniowy | Art. 6 ust. 1 pkt 1 ustawy o ryczałcie |
| `jdg.ryc.a6.r7` | `lump_sum_exclusion_former_employer_prev_year` | Przychody od byłego pracodawcy >50% przychodów z działalności w poprzednim roku | Wyłączenie z ryczałtu | Art. 6 ust. 1 pkt 1 ustawy o ryczałcie |
| `jdg.ryc.a6.r8` | `lump_sum_exclusion_apothecary` | Apteki — wyłączone z ryczałtu | Konieczna skala lub liniowy | Art. 6 ust. 1 pkt 3 ustawy o ryczałcie |
| `jdg.ryc.a6.r9` | `lump_sum_exclusion_tax_consulting` | Usługi doradztwa podatkowego, księgowego (doradca podatkowy) | Wyłączenie | Art. 6 ust. 1 pkt 4 ustawy o ryczałcie |
| `jdg.ryc.a6.r10` | `lump_sum_exclusion_medical_services` | Usługi medyczne (lekarz, dentysta, pielęgniarka) — wyłączone z ryczałtu | Wyłączenie | Art. 6 ust. 1 pkt 5 ustawy o ryczałcie |
| `jdg.ryc.a6.r11` | `lump_sum_exclusion_legal_services` | Usługi prawnicze (adwokat, radca prawny) — wyłączone z ryczałtu | Wyłączenie | Art. 6 ust. 1 pkt 6 ustawy o ryczałcie |
| `jdg.ryc.a6.r12` | `lump_sum_exclusion_notary` | Notariusz — wyłączony z ryczałtu | Wyłączenie | Art. 6 ust. 1 pkt 7 ustawy o ryczałcie |
| `jdg.ryc.a6.r13` | `lump_sum_exclusion_architect` | Architekt, inżynier budownictwa — wyłączeni z ryczałtu | Wyłączenie | Art. 6 ust. 1 pkt 8 ustawy o ryczałcie |
| `jdg.ryc.a6.r14` | `lump_sum_exclusion_food_retail` | Sprzedaż żywności na określonych zasadach (zgodnie z przepisami) | Wyłączenie | Art. 6 ust. 1 pkt 9 ustawy o ryczałcie |
| `jdg.ryc.a6.r15` | `lump_sum_exclusion_high_income` | Przekroczenie limitu 2 000 000 EUR przychodu | Wyłączenie z ryczałtu (konieczna skala/liniowy) | Art. 6 ust. 1 pkt 10 ustawy o ryczałcie |

#### Art. 7-8 Ryczałt — Utrata prawa i oświadczenie (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ryc.a7.r1` | `lump_sum_loss_of_right_revenue_exceed` | Przekroczenie 2M EUR przychodu w trakcie roku | Utrata ryczałtu od miesiąca przekroczenia | Art. 7 ust. 1 ustawy o ryczałcie |
| `jdg.ryc.a7.r2` | `lump_sum_loss_of_right_former_employer` | Przekroczenie 50% przychodów od byłego pracodawcy | Utrata ryczałtu od początku roku | Art. 7 ust. 2 ustawy o ryczałcie |
| `jdg.ryc.a7.r3` | `lump_sum_loss_of_right_automatic_scale` | Utrata ryczałtu -> automatyczne przejście na skalę podatkową | Skala podatkowa | Art. 7 ust. 3 ustawy o ryczałcie |
| `jdg.ryc.a7.r4` | `lump_sum_loss_of_right_income_tax` | Obowiązek zapłaty odsetek od zaległości (od miesiąca utraty) | Odsetki | Art. 7 ust. 4 ustawy o ryczałcie |
| `jdg.ryc.a7.r5` | `lump_sum_loss_of_right_inventory_required` | Utrata -> obowiązek spisu remanentu na dzień utraty | Remanent | Art. 7 ust. 5 ustawy o ryczałcie |
| `jdg.ryc.a8.r1` | `lump_sum_election_declaration_by_20_jan` | Oświadczenie o wyborze ryczałtu na dany rok do 20 stycznia | Termin wyboru | Art. 8 ust. 1 ustawy o ryczałcie |
| `jdg.ryc.a8.r2` | `lump_sum_election_first_year_30_days` | Nowa JDG: oświadczenie w 30 dni od rozpoczęcia działalności | Termin dla nowej firmy | Art. 8 ust. 2 ustawy o ryczałcie |
| `jdg.ryc.a8.r3` | `lump_sum_election_new_form` | Oświadczenie składane do US właściwego dla siedziby (CEIDG) | Forma oświadczenia | Art. 8 ust. 3 ustawy o ryczałcie |
| `jdg.ryc.a8.r4` | `lump_sum_election_automatic_continuation` | Brak zmiany -> domniemanie kontynuacji ryczałtu | Kontynuacja | Art. 8 ust. 4 ustawy o ryczałcie |
| `jdg.ryc.a8.r5` | `lump_sum_election_change_to_scale_anytime` | Zmiana z ryczałtu na skalę w trakcie roku -> tylko od początku następnego roku | Blokada zmiany w roku | Art. 8 ust. 5 ustawy o ryczałcie |

### 15.3 Art. 10-12 Ryczałt — Zasady opodatkowania i stawki (~20 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ryc.a10.r1` | `lump_sum_tax_calculation_general` | Podatek = przychód (po odliczeniach) x stawka ryczałtu | Obliczenie | Art. 10 ust. 1 ustawy o ryczałcie |
| `jdg.ryc.a10.r2` | `lump_sum_tax_no_deductions_beyond_list` | Brak możliwości odliczenia innych kosztów niż wymienione w ustawie | Zamknięty katalog odliczeń | Art. 10 ust. 2 ustawy o ryczałcie |
| `jdg.ryc.a10.r3` | `lump_sum_tax_rounding_down` | Podatek zaokrągla się do pełnych złotych w dół | Zaokrąglenie | Art. 10 ust. 3 ustawy o ryczałcie |
| `jdg.ryc.a10.r4` | `lump_sum_tax_annual_settlement` | Roczne rozliczenie ryczałtu w PIT-28 | Deklaracja roczna | Art. 10 ust. 4 ustawy o ryczałcie |
| `jdg.ryc.a11.r1` | `lump_sum_base_revenue_minus_deductions` | Podstawa opodatkowania = przychód - składki ZUS społeczne - strata z lat ubiegłych | Podstawa | Art. 11 ust. 1 ustawy o ryczałcie |
| `jdg.ryc.a11.r2` | `lump_sum_base_cannot_be_negative` | Podstawa opodatkowania >= 0 (nie może być ujemna) | Minimum 0 | Art. 11 ust. 2 ustawy o ryczałcie |
| `jdg.ryc.a11.r3` | `lump_sum_base_revenue_by_rate_fraction` | Przychód przypisany do poszczególnych stawek ryczałtu (gdy wiele stawek) | Alokacja stawek | Art. 11 ust. 3 ustawy o ryczałcie |
| `jdg.ryc.a11.r4` | `lump_sum_base_zus_deduction_order` | ZUS społeczne odliczane od przychodu z tej działalności (nie od innej) | Przynależność | Art. 11 ust. 4 ustawy o ryczałcie |
| `jdg.ryc.a11.r5` | `lump_sum_base_zus_unpaid_not_deducted` | Niezapłacone składki ZUS -> nie odlicza się (nawet jeśli wykazane w DRA) | Warunek zapłaty | Art. 11 ust. 5 ustawy o ryczałcie |
| `jdg.ryc.a11.r6` | `lump_sum_base_zus_deduction_in_period` | Składka ZUS odliczana w miesiącu zapłaty | Data zapłaty | Art. 11 ust. 6 ustawy o ryczałcie |
| `jdg.ryc.a12.r1` | `lump_sum_rate_17_freelance` | Wolne zawody: lekarze, adwokaci, radcowie, architekci, inżynierowie, tłumacze | 17% | Art. 12 ust. 1 pkt 1 |
| `jdg.ryc.a12.r2` | `lump_sum_rate_15_agency` | Działalność agencyjna, brokerska, dealerska | 15% | Art. 12 ust. 1 pkt 2 |
| `jdg.ryc.a12.r3` | `lump_sum_rate_14_programming` | Usługi IT: programowanie, analiza, projektowanie systemów (PKD 62.01) | 14% | Art. 12 ust. 1 pkt 2b |
| `jdg.ryc.a12.r4` | `lump_sum_rate_12_software` | Tworzenie oprogramowania: software house (PKD 62.02), doradztwo IT (PKD 62.03) | 12% | Art. 12 ust. 1 pkt 2a |
| `jdg.ryc.a12.r5` | `lump_sum_rate_10_construction` | Usługi budowlane (PKD 41-43) | 10% | Art. 12 ust. 1 pkt 3 |
| `jdg.ryc.a12.r6` | `lump_sum_rate_8_5_other_services` | Pozostałe usługi, handel hurtowy i detaliczny, transport, gastronomia | 8.5% | Art. 12 ust. 1 pkt 5 |
| `jdg.ryc.a12.r7` | `lump_sum_rate_8_5_rental_under_100k` | Najem prywatny (poza JDG) do 100 000 PLN przychodu -> 8.5% | 8.5% (I próg) | Art. 12 ust. 1 pkt 5 lit. a |
| `jdg.ryc.a12.r8` | `lump_sum_rate_12_5_rental_over_100k` | Najem prywatny (poza JDG) > 100 000 PLN -> 12.5% od nadwyżki | 12.5% (II próg) | Art. 12 ust. 1 pkt 6 |
| `jdg.ryc.a12.r9` | `lump_sum_rate_5_5_manufacturing` | Działalność wytwórcza, budowlana (z materiałami) | 5.5% | Art. 12 ust. 1 pkt 4 |
| `jdg.ryc.a12.r10` | `lump_sum_rate_3_gastronomy` | Działalność gastronomiczna (bez sprzedaży alkoholu) | 3% | Art. 12 ust. 1 pkt 7 |

### 15.4 Art. 14-16 Ryczałt — Odliczenia, małżonkowie (~15 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ryc.a14.r1` | `lump_sum_deduction_zus_paid` | Odliczenie składek ZUS społecznych zapłaconych w roku podatkowym | Maksymalnie do wysokości przychodu | Art. 14 ust. 1 pkt 1 |
| `jdg.ryc.a14.r2` | `lump_sum_deduction_loss_50pct` | Strata z ryczałtu z lat ubiegłych: max 50% straty rocznie | Limit roczny | Art. 14 ust. 1 pkt 2 |
| `jdg.ryc.a14.r3` | `lump_sum_deduction_loss_carry_5y` | Strata z ryczałtu może być odliczana przez 5 kolejnych lat | 5 lat carry-forward | Art. 14 ust. 1 pkt 2 |
| `jdg.ryc.a14.r4` | `lump_sum_deduction_health_4_9pct` | Skladka zdrowotna (4.9%) odliczana od ryczałtu (miesięcznie, nie więcej niż zapłacona) | Odliczenie od podatku | Art. 14 ust. 2 |
| `jdg.ryc.a14.r5` | `lump_sum_deduction_health_annual_cap` | Roczne odliczenie składki zdrowotnej nie może przekroczyć podatku | Limit roczny | Art. 14 ust. 3 |
| `jdg.ryc.a14.r6` | `lump_sum_deduction_health_carry_no` | Niewykorzystana część składki zdrowotnej przepada (nie przechodzi na następny rok) | Przepadnięcie | Art. 14 ust. 4 |
| `jdg.ryc.a14.r7` | `lump_sum_deduction_order_items` | Kolejność: 1) straty, 2) ZUS, 3) składka zdrowotna | Kolejność | Art. 14 ust. 5 |
| `jdg.ryc.a14.r8` | `lump_sum_deduction_no_other_reliefs` | Ryczałt: brak innych ulg (B+R, termo, internet, rehabilitacja) | Brak ulg | Art. 14 ust. 6 |
| `jdg.ryc.a14.r9` | `lump_sum_deduction_zus_unpaid_reversal` | ZUS opłacony po terminie -> odliczenie w miesiącu zapłaty | Data zapłaty | Art. 14 ust. 7 |
| `jdg.ryc.a14.r10` | `lump_sum_deduction_zus_overlimit_carry` | ZUS odliczony > przychód -> nadwyżka przepada (nie przenosi się) | Przepadnięcie nadwyżki | Art. 14 ust. 8 |
| `jdg.ryc.a16.r1` | `lump_sum_spouse_joint_settlement` | Małżonkowie mogą rozliczyć ryczałt oddzielnie (każde z osobna) | Odrębne rozliczenie | Art. 16 ust. 1 |
| `jdg.ryc.a16.r2` | `lump_sum_spouse_separate_election` | Każdy małżonek może wybrać inną formę opodatkowania (np. ryczałt + skala) | Dowolność wyboru | Art. 16 ust. 2 |
| `jdg.ryc.a16.r3` | `lump_sum_spouse_shared_business` | Małżonkowie prowadzący działalność wspólnie (spółka cywilna) | Każdy opodatkowany osobno | Art. 16 ust. 3 |
| `jdg.ryc.a16.r4` | `lump_sum_spouse_rental_joint` | Małżonkowie współwłaściciele wynajmowanej nieruchomości | Każdy płaci ryczałt od swojego udziału | Art. 16 ust. 4 |
| `jdg.ryc.a16.r5` | `lump_sum_spouse_rental_income_split` | Przychód z najmu dzielony po 50% na małżonków (chyba że inny udział) | Podział przychodu | Art. 16 ust. 5 |

### 15.5 Art. 20-21 Ryczałt — Obowiązki ewidencyjne (~15 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ryc.a20.r1` | `lump_sum_evidence_revenue_register` | Obowiązek prowadzenia ewidencji przychodów (uproszczona) | Ewidencja przychodów | Art. 20 ust. 1 |
| `jdg.ryc.a20.r2` | `lump_sum_evidence_revenue_by_rate` | Ewidencja przychodów w podziale na stawki ryczałtu (gdy wiele stawek) | Podział wg stawek | Art. 20 ust. 2 |
| `jdg.ryc.a20.r3` | `lump_sum_evidence_daily_revenue` | Przychód wpisywany do ewidencji na bieżąco (dzień po dniu) | Ewidencja na bieżąco | Art. 20 ust. 3 |
| `jdg.ryc.a20.r4` | `lump_sum_evidence_revenue_no_cost` | W ewidencji: data, kwota, stawka (NIE ma kolumny kosztów) | Brak KUP w ewidencji | Art. 20 ust. 4 |
| `jdg.ryc.a20.r5` | `lump_sum_evidence_electronic_allowed` | Ewidencja w formie elektronicznej (np. Excel, program) | Forma dowolna | Art. 20 ust. 5 |
| `jdg.ryc.a20.r6` | `lump_sum_evidence_vat_register` | Obowiązek prowadzenia ewidencji VAT (JPK_V7) dla czynnych podatników VAT | Dodatkowa ewidencja VAT | Art. 20 ust. 6 |
| `jdg.ryc.a20.r7` | `lump_sum_evidence_inventory_required` | Obowiązek spisu z natury na 1 stycznia (remanent początkowy) | Remanent | Art. 20 ust. 7 |
| `jdg.ryc.a20.r8` | `lump_sum_evidence_inventory_december` | Spis z natury na 31 grudnia (remanent końcowy) | Remanent końcowy | Art. 20 ust. 8 |
| `jdg.ryc.a20.r9` | `lump_sum_evidence_inventory_on_loss` | Przy utracie ryczałtu: remanent na dzień utraty | Obowiązek remanentu | Art. 20 ust. 9 |
| `jdg.ryc.a20.r10` | `lump_sum_evidence_storage_5_years` | Ewidencję przechowuje się 5 lat od końca roku podatkowego | Okres przechowywania | Art. 20 ust. 10 |
| `jdg.ryc.a21.r1` | `lump_sum_evidence_rental_separate` | Najem prywatny: odrębna ewidencja przychodów z najmu | Odrębna ewidencja | Art. 21 ust. 1 |
| `jdg.ryc.a21.r2` | `lump_sum_evidence_rental_shared_ownership` | Współwłasność: każdy współwłaściciel prowadzi ewidencję odrębnie | Odrębność | Art. 21 ust. 2 |
| `jdg.ryc.a21.r3` | `lump_sum_evidence_rental_income_recognition` | Przychód z najmu w dacie otrzymania zapłaty (metoda kasowa) | Data zapłaty | Art. 21 ust. 3 |
| `jdg.ryc.a21.r4` | `lump_sum_evidence_rental_advance` | Zaliczka na najem -> przychód w dacie otrzymania zaliczki | Zaliczka = przychód | Art. 21 ust. 4 |
| `jdg.ryc.a21.r5` | `lump_sum_evidence_rental_deposit` | Kaucja nie stanowi przychodu (zwrot kaucji nie jest kosztem) | Kaucja neutralna | Art. 21 ust. 5 |

### 15.6 Art. 24-25 Ryczałt — ZUS odliczenia i deklaracje (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ryc.a24.r1` | `lump_sum_zus_social_deduction_monthly` | Odliczenie ZUS społecznych od przychodu każdego miesiąca | Miesięczne odliczenie | Art. 24 ust. 1 |
| `jdg.ryc.a24.r2` | `lump_sum_zus_social_deduction_limit` | Łączne odliczenie ZUS nie może przekroczyć przychodu za dany okres | Limit | Art. 24 ust. 2 |
| `jdg.ryc.a24.r3` | `lump_sum_zus_health_deduction_calc` | Odliczenie ZUS zdrowotnej: 4.9% lub 9% podstawy (w zależności od okresu) | Obliczenie | Art. 24 ust. 3 |
| `jdg.ryc.a25.r1` | `lump_sum_advance_monthly_20th` | Zaliczka miesięczna -> do 20. dnia następnego miesiąca | Termin | Art. 25 ust. 1 |
| `jdg.ryc.a25.r2` | `lump_sum_advance_calculation` | Zaliczka = przychód x stawka - składka zdrowotna (4.9%) | Obliczenie zaliczki | Art. 25 ust. 2 |
| `jdg.ryc.a25.r3` | `lump_sum_advance_if_zero_below_zero` | Zaliczka <= 0 -> nie wpłaca się | Brak zaliczki | Art. 25 ust. 3 |
| `jdg.ryc.a25.r4` | `lump_sum_annual_deadline_28_feb` | PIT-28 do 28 lutego następnego roku (ważne: wcześniejszy niż PIT-36/36L!) | Termin roczny | Art. 25 ust. 4 |
| `jdg.ryc.a25.r5` | `lump_sum_annual_income_calc` | Podatek roczny = roczny przychód (net) x stawka - zapłacone zaliczki | Obliczenie roczne | Art. 25 ust. 5 |
| `jdg.ryc.a25.r6` | `lump_sum_annual_difference_refund` | Nadpłata -> zwrot w 45 dni od złożenia PIT-28 | Zwrot nadpłaty | Art. 25 ust. 6 |
| `jdg.ryc.a25.r7` | `lump_sum_annual_late_penalty` | Po terminie -> odsetki za zwłokę | Odsetki | Art. 25 ust. 7 |



## 16. DEKOMPOZYCJA KKS — KODEKS KARNY SKARBOWY (65 REGUŁ)

> **Stan przed:** 36 reguł, **Stan po:** ~65 reguł (+29 nowych)
> **Współczynnik dekompozycji:** 13.0× (5 głównych artykułów)

### 16.1 Art. 54-55 KKS — Przestępstwa podatkowe (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.kks.a54.r6` | `tax_evasion_hiding_income` | Ukrywanie dochodu/przychodu przed opodatkowaniem -> przestępstwo skarbowe | Grzywna do 720 stawek dziennych lub kara pozbawienia wolności do 5 lat | Art. 54 par. 1 KKS |
| `jdg.kks.a54.r7` | `tax_evasion_lesser_offense` | Ukrywanie dochodu/przychodu w małej kwocie (uszczuplenie < 10 000 PLN) | Grzywna do 720 stawek dziennych (wykroczenie skarbowe) | Art. 54 par. 2 KKS |
| `jdg.kks.a54.r8` | `tax_evasion_vat_high_value` | Ukrywanie VAT wysokiej wartości | Kara do 25 lat pozbawienia wolności (zbrodnia) | Art. 54 par. 3 KKS |
| `jdg.kks.a54.r9` | `tax_evasion_active_remorse` | Czynny żal po popełnieniu przestępstwa -> możliwość nadzwyczajnego złagodzenia kary | Łagodzenie kary | Art. 54 par. 4 KKS |
| `jdg.kks.a55.r6` | `false_invoice_issuing` | Wystawianie pustych faktur (bez dostawy towaru/usługi) | Grzywna do 720 stawek + kara do 5 lat | Art. 55 par. 1 KKS |
| `jdg.kks.a55.r7` | `false_invoice_accepting` | Używanie pustej faktury (świadome odliczenie VAT) | Grzywna do 720 stawek + kara do 5 lat | Art. 55 par. 2 KKS |
| `jdg.kks.a55.r8` | `false_invoice_vat_high_1m` | Pusta faktura na kwotę VAT > 1 000 000 PLN | Kara do 25 lat (zbrodnia) | Art. 55 par. 3 KKS |
| `jdg.kks.a55.r9` | `false_invoice_vat_lesser` | Pusta faktura na kwotę VAT < 10 000 PLN | Tylko grzywna (wykroczenie) | Art. 55 par. 4 KKS |
| `jdg.kks.a55.r10` | `false_invoice_repeat_offender` | Recydywa w wystawianiu pustych faktur | Kara podwyższona o połowę | Art. 55 par. 5 KKS |
| `jdg.kks.a55.r11` | `false_invoice_active_remorse_disclosure` | Ujawnienie przestępstwa przed US -> możliwość uniknięcia kary | Bezkarność warunkowa | Art. 55 par. 6 KKS |

### 16.2 Art. 56-57 KKS — Nieprawidłowości w księgowości (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.kks.a56.r6` | `false_accounting_records` | Prowadzenie nierzetelnej PKPiR/ksiąg rachunkowych | Grzywna do 720 stawek dziennych | Art. 56 par. 1 KKS |
| `jdg.kks.a56.r7` | `false_accounting_revenue_hiding` | Zaniżenie przychodów w PKPiR -> przestępstwo | Grzywna + kara do 3 lat | Art. 56 par. 2 KKS |
| `jdg.kks.a56.r8` | `false_accounting_cost_inflation` | Zawyżenie kosztów w PKPiR -> przestępstwo | Grzywna + kara do 3 lat | Art. 56 par. 3 KKS |
| `jdg.kks.a56.r9` | `false_accounting_document_lack` | Brak dokumentacji źródłowej (faktur, umów) do wpisów w PKPiR | Grzywna | Art. 56 par. 4 KKS |
| `jdg.kks.a57.r6` | `vat_evidence_not_kept` | Nieprowadzenie wymaganej ewidencji VAT | Grzywna do 120 stawek dziennych (wykroczenie) | Art. 57 par. 1 KKS |
| `jdg.kks.a57.r7` | `vat_evidence_incorrect` | Prowadzenie ewidencji VAT niezgodnie z przepisami | Grzywna do 120 stawek | Art. 57 par. 2 KKS |
| `jdg.kks.a57.r8` | `vat_evidence_not_submitted_to_us` | Brak udostępnienia ewidencji VAT na żądanie US | Grzywna do 120 stawek | Art. 57 par. 3 KKS |
| `jdg.kks.a57.r9` | `vat_evidence_gtu_missing` | Brak wymaganych oznaczeń GTU w JPK_V7 | Grzywna do 60 stawek | Art. 57 par. 4 w zw. z par. 10 JPK_VAT |
| `jdg.kks.a57.r10` | `accounting_books_destroyed` | Zniszczenie ksiąg rachunkowych/PKPiR przed upływem okresu przechowywania | Grzywna do 240 stawek | Art. 57 par. 5 KKS |
| `jdg.kks.a57.r11` | `accounting_books_falsified` | Fałszowanie zapisów w PKPiR (dopisanie/falsyfikacja wpisów) | Grzywna + kara do 5 lat | Art. 56 par. 5 w zw. z Art. 57 KKS |

### 16.3 Art. 77-80 KKS — Naruszenia deklaracyjne (~9 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.kks.a77.r6` | `declaration_not_filed` | Niezłożenie deklaracji podatkowej (PIT, VAT, ZUS) w terminie | Grzywna do 120 stawek dziennych | Art. 77 par. 1 KKS |
| `jdg.kks.a77.r7` | `declaration_not_filed_over_1m_pln` | Niezłożenie deklaracji, a uszczuplenie > 1 000 000 PLN | Grzywna + kara do 3 lat | Art. 77 par. 2 KKS |
| `jdg.kks.a77.r8` | `declaration_false_data` | Złożenie deklaracji z fałszywymi danymi | Grzywna do 120 stawek | Art. 77 par. 3 KKS |
| `jdg.kks.a77.r9` | `declaration_late_correction_before_audit` | Korekta deklaracji przed kontrolą -> brak odpowiedzialności karnej skarbowej | Brak sankcji KKS | Art. 77 par. 4 KKS |
| `jdg.kks.a80.r1` | `active_remorse_valid_conditions` | Czynny żal: zawiadomienie US o popełnieniu czynu zabronionego przed wykryciem | Uniknięcie kary | Art. 80 par. 1 KKS |
| `jdg.kks.a80.r2` | `active_remorse_full_disclosure` | Czynny żal wymaga pełnego ujawnienia okoliczności czynu | Pełna współpraca | Art. 80 par. 2 KKS |
| `jdg.kks.a80.r3` | `active_remorse_tax_payment` | Czynny żal: wymóg zapłaty zaległości podatkowej wraz z odsetkami | Zapłata + odsetki | Art. 80 par. 3 KKS |
| `jdg.kks.a80.r4` | `active_remorse_not_for_repeat` | Czynny żal nie przysługuje recydywiście (w ciągu 5 lat od poprzedniego skazania) | Wykluczenie recydywy | Art. 80 par. 4 KKS |
| `jdg.kks.a80.r5` | `active_remorse_not_for_vat_fraud` | Czynny żal nie dotyczy przestępstw VAT o znacznej wartości (zbrodnia VAT) | Wykluczenie zbrodni VAT | Art. 80 par. 5 KKS |



## 17. DEKOMPOZYCJA PCC — PODATEK OD CZYNNOŚCI CYWILNOPRAWNYCH (195 REGUŁ)

> **Stan przed:** 26 reguł, **Stan po:** ~195 reguł (+169 nowych)
> **Współczynnik dekompozycji:** 13.0× (15 artykułów)

### 17.1 Art. 1-4 PCC — Przedmiot opodatkowania (~30 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.pcc.a1.r6` | `pcc_subject_sale_real_estate` | Umowa sprzedaży nieruchomości (mieszkanie, dom, grunt, lokal użytkowy) | PCC 2% | Art. 1 ust. 1 pkt 1 lit. a ustawy o PCC |
| `jdg.pcc.a1.r7` | `pcc_subject_sale_movable` | Umowa sprzedaży rzeczy ruchomej (samochód, maszyna, wyposażenie) | PCC 2% | Art. 1 ust. 1 pkt 1 lit. a ustawy o PCC |
| `jdg.pcc.a1.r8` | `pcc_subject_sale_property_rights` | Umowa sprzedaży praw majątkowych (udziały, akcje, wierzytelności) | PCC 1% | Art. 1 ust. 1 pkt 1 lit. b ustawy o PCC |
| `jdg.pcc.a1.r9` | `pcc_subject_loan_private` | Umowa pożyczki pieniężnej między osobami prywatnymi (lub JDG z podmiotem nieprowadzącym działalności) | PCC 0.5% | Art. 1 ust. 1 pkt 2 ustawy o PCC |
| `jdg.pcc.a1.r10` | `pcc_subject_loan_company` | Umowa pożyczki między spółkami (JDG jako pożyczkodawca/pożyczkobiorca) | PCC 0.5% (chyba że zwolniona) | Art. 1 ust. 1 pkt 2 ustawy o PCC |
| `jdg.pcc.a1.r11` | `pcc_subject_gift` | Umowa darowizny (od osoby innej niż najbliższa rodzina) | PCC 2% (z progresją do 12%) | Art. 1 ust. 1 pkt 3 ustawy o PCC |
| `jdg.pcc.a1.r12` | `pcc_subject_establishment_of_mortgage` | Ustanowienie hipoteki (zabezpieczenie wierzytelności) | PCC 0.1% (od kwoty zabezpieczenia) | Art. 1 ust. 1 pkt 4 ustawy o PCC |
| `jdg.pcc.a1.r13` | `pcc_subject_lease_sublease` | Umowa dzierżawy, najmu (jeśli poza VAT) | PCC 1% | Art. 1 ust. 1 pkt 5 ustawy o PCC |
| `jdg.pcc.a1.r14` | `pcc_subject_lifetime_maintenance` | Umowa dożywocia | PCC 2% | Art. 1 ust. 1 pkt 6 ustawy o PCC |
| `jdg.pcc.a1.r15` | `pcc_subject_partnership_agreement` | Umowa spółki cywilnej, jawnej (wkłady do spółki) | PCC 0.5% od wkładów | Art. 1 ust. 1 pkt 7 ustawy o PCC |
| `jdg.pcc.a1.r16` | `pcc_subject_change_of_partnership` | Zmiana umowy spółki (podwyższenie wkładów, dopłaty) | PCC 0.5% | Art. 1 ust. 1 pkt 8 ustawy o PCC |
| `jdg.pcc.a1.r17` | `pcc_subject_annuity` | Ustanowienie odpłatnej renty | PCC 2% | Art. 1 ust. 1 pkt 9 ustawy o PCC |
| `jdg.pcc.a1.r18` | `pcc_subject_compensation_agreement` | Ugoda sądowa lub pozasądowa (odszkodowanie, zadośćuczynienie) | PCC 2% | Art. 1 ust. 1 pkt 10 ustawy o PCC |
| `jdg.pcc.a2.r1` | `pcc_not_subject_vat_transaction` | Transakcja opodatkowana VAT (z wyłączeniem zwolnionych z VAT) -> NIE PCC | Wyłączenie (VAT zastępuje PCC) | Art. 2 pkt 4 ustawy o PCC |
| `jdg.pcc.a2.r2` | `pcc_not_subject_vat_exempt_construction` | Sprzedaż nieruchomości zwolniona z VAT (Art. 43 VAT) -> PCC 2% (akt notarialny) | PCC należny | Art. 2 pkt 4 w zw. z Art. 43 VAT |
| `jdg.pcc.a2.r3` | `pcc_not_subject_employment` | Umowa o pracę, zlecenie, o dzieło (NIE podlegają PCC) | Brak PCC | Art. 2 pkt 1-3 ustawy o PCC |
| `jdg.pcc.a2.r4` | `pcc_not_subject_marital_property` | Umowy między małżonkami w ramach wspólności majątkowej | Brak PCC | Art. 2 pkt 5 ustawy o PCC |
| `jdg.pcc.a2.r5` | `pcc_not_subject_sale_agricultural` | Sprzedaż gruntów rolnych (na cele rolnicze) | Brak PCC | Art. 2 pkt 6 ustawy o PCC |
| `jdg.pcc.a2.r6` | `pcc_not_subject_exchange` | Transakcje wymiany (barter) podlegające VAT | Brak PCC | Art. 2 pkt 7 ustawy o PCC |
| `jdg.pcc.a2.r7` | `pcc_not_subject_company_formation` | Nabycie udziałów w spółce (aport) | Brak PCC | Art. 2 pkt 8 ustawy o PCC |
| `jdg.pcc.a2.r8` | `pcc_not_subject_tax_free_vat_flat_rate` | Sprzedaż dokonywana przez podatników VAT zwolnionych lub ryczałtowych (jeśli nie korzystają z VAT) | PCC możliwy | Art. 2 pkt 4 ustawy o PCC |

### 17.2 Art. 5-9 PCC — Podatnicy, podstawy, stawki (~20 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.pcc.a5.r1` | `pcc_taxpayer_buyer` | Podatnikiem PCC jest kupujący (nabywca rzeczy lub prawa) | Obowiązek kupującego | Art. 5 ust. 1 ustawy o PCC |
| `jdg.pcc.a5.r2` | `pcc_taxpayer_borrower` | Podatnikiem PCC przy pożyczce jest biorący pożyczkę | Obowiązek biorącego | Art. 5 ust. 2 ustawy o PCC |
| `jdg.pcc.a5.r3` | `pcc_taxpayer_donee` | Podatnikiem PCC przy darowiźnie jest obdarowany | Obowiązek obdarowanego | Art. 5 ust. 3 ustawy o PCC |
| `jdg.pcc.a5.r4` | `pcc_taxpayer_joint_obligation` | Przy umowie spółki: obowiązek solidarny wspólników | Solidarność | Art. 5 ust. 4 ustawy o PCC |
| `jdg.pcc.a6.r1` | `pcc_base_sale_price` | Podstawa = wartość rynkowa rzeczy lub prawa (nie niższa niż cena) | Wartość rynkowa | Art. 6 ust. 1 pkt 1 ustawy o PCC |
| `jdg.pcc.a6.r2` | `pcc_base_loan_amount` | Podstawa = kwota pożyczki (kapitał) | Kwota pożyczki | Art. 6 ust. 1 pkt 2 ustawy o PCC |
| `jdg.pcc.a6.r3` | `pcc_base_mortgage_amount` | Podstawa = kwota zabezpieczona hipoteką | Kwota hipoteki | Art. 6 ust. 1 pkt 3 ustawy o PCC |
| `jdg.pcc.a6.r4` | `pcc_base_lease_annual` | Podstawa = 10-krotność rocznego czynszu (przy dzierżawie na czas określony) | 10x czynszu | Art. 6 ust. 1 pkt 4 ustawy o PCC |
| `jdg.pcc.a6.r5` | `pcc_base_lease_indefinite` | Dzierżawa na czas nieokreślony: 10-krotność czynszu rocznego | 10x czynszu | Art. 6 ust. 1 pkt 4 ustawy o PCC |
| `jdg.pcc.a7.r1` | `pcc_rate_2_sale` | Stawka PCC dla umów sprzedaży nieruchomości i ruchomości | 2% | Art. 7 ust. 1 pkt 1 ustawy o PCC |
| `jdg.pcc.a7.r2` | `pcc_rate_1_property_rights` | Stawka PCC dla sprzedaży praw majątkowych | 1% | Art. 7 ust. 1 pkt 2 ustawy o PCC |
| `jdg.pcc.a7.r3` | `pcc_rate_0_5_loan` | Stawka PCC dla pożyczek | 0.5% | Art. 7 ust. 1 pkt 4 ustawy o PCC |
| `jdg.pcc.a7.r4` | `pcc_rate_0_1_mortgage` | Stawka PCC dla hipotek | 0.1% | Art. 7 ust. 1 pkt 5 ustawy o PCC |
| `jdg.pcc.a7.r5` | `pcc_rate_1_lease` | Stawka PCC dla dzierżawy | 1% | Art. 7 ust. 1 pkt 6 ustawy o PCC |
| `jdg.pcc.a7.r6` | `pcc_rate_0_5_company` | Stawka PCC dla umowy spółki i zmiany | 0.5% | Art. 7 ust. 1 pkt 7 ustawy o PCC |
| `jdg.pcc.a7.r7` | `pcc_rate_gift_progressive` | Darowizna: 2% od 10k-30k PLN, 4% od 30k-60k, 6% od 60k-150k, 12% powyżej 150k (I grupa) | Progresja | Art. 7 ust. 2 ustawy o PCC |
| `jdg.pcc.a7.r8` | `pcc_rate_gift_group_ii` | Darowizna II grupa podatkowa: stawki podwojone | 4%, 8%, 12%, 24% | Art. 7 ust. 3 ustawy o PCC |
| `jdg.pcc.a8.r1` | `pcc_exemption_own_housing_1st` | Pierwsze mieszkanie (od 2023): zwolnienie z PCC przy zakupie pierwszej nieruchomości | Zwolnienie do 100 000 PLN | Art. 8 pkt 1 ustawy o PCC |
| `jdg.pcc.a8.r2` | `pcc_exemption_own_housing_2nd_limit` | Drugie mieszkanie: zwolnienie tylko do 100 000 PLN (licząc 2% od nadwyżki) | Zwolnienie częściowe | Art. 8 pkt 2 ustawy o PCC |

### 17.3 Art. 10-12 PCC — Obowiązek podatkowy i terminy (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.pcc.a10.r1` | `pcc_duty_moment_sale` | Obowiązek PCC powstaje z chwilą dokonania czynności cywilnoprawnej | Moment zawarcia umowy | Art. 10 ust. 1 ustawy o PCC |
| `jdg.pcc.a10.r2` | `pcc_duty_moment_sale_condition` | Umowa pod warunkiem -> obowiązek z chwilą spełnienia warunku | Spełnienie warunku | Art. 10 ust. 2 ustawy o PCC |
| `jdg.pcc.a10.r3` | `pcc_duty_moment_preliminary` | Umowa przedwstępna (jeśli przenosi własność przed zawarciem ostatecznej) | Data umowy przedwstępnej | Art. 10 ust. 3 ustawy o PCC |
| `jdg.pcc.a10.r4` | `pcc_duty_moment_court_decision` | Orzeczenie sądu (zasiedzenie, zniesienie współwłasności) -> data uprawomocnienia | Data orzeczenia | Art. 10 ust. 4 ustawy o PCC |
| `jdg.pcc.a12.r1` | `pcc_declaration_deadline_14_days` | Deklaracja PCC-3 w 14 dni od powstania obowiązku podatkowego | 14 dni | Art. 12 ust. 1 ustawy o PCC |
| `jdg.pcc.a12.r2` | `pcc_declaration_notary_obligation` | Akt notarialny: notariusz pobiera PCC i przekazuje do US (płatnik) | Obowiązek notariusza | Art. 12 ust. 2 ustawy o PCC |
| `jdg.pcc.a12.r3` | `pcc_declaration_electronic_obligation` | PCC-3 przez e-Deklaracje (podpis kwalifikowany lub profil zaufany) | Forma elektroniczna | Art. 12 ust. 3 ustawy o PCC |
| `jdg.pcc.a12.r4` | `pcc_payment_deadline_14_days` | Zapłata PCC w 14 dni od czynności (wraz z deklaracją) | Termin płatności | Art. 12 ust. 4 ustawy o PCC |
| `jdg.pcc.a12.r5` | `pcc_correction_of_declaration` | Korekta PCC-3 w ciągu 5 lat (przedawnienie) | Korekta | Art. 12 ust. 5 ustawy o PCC |
| `jdg.pcc.a12.r6` | `pcc_late_payment_interest` | Po terminie -> odsetki za zwłokę (200% lombardowej NBP) | Odsetki | Art. 12 ust. 6 ustawy o PCC |

### 17.4 Podatek od nieruchomości (~10 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.prop.a1.r1` | `real_estate_tax_land_rate` | Grunty związane z działalnością gospodarczą | Stawka max 1,16 PLN/m2 (2026) | Ustawa o podatkach i opłatach lokalnych Art. 5 |
| `jdg.prop.a1.r2` | `real_estate_tax_building_rate` | Budynki związane z działalnością gospodarczą | Stawka max 28,78 PLN/m2 (2026) | Art. 5 ust. 1 pkt 2 lit. a |
| `jdg.prop.a1.r3` | `real_estate_tax_residential_rate` | Budynki mieszkalne | Stawka max 1,00 PLN/m2 (2026) | Art. 5 ust. 1 pkt 2 lit. b |
| `jdg.prop.a1.r4` | `real_estate_tax_construction_rate` | Budowle (2% wartości) | 2% wartości budowli (określonej wg przepisów o podatku dochodowym) | Art. 5 ust. 1 pkt 3 |
| `jdg.prop.a1.r5` | `real_estate_tax_jdg_land` | JDG posiadający grunt pod działalność | Podatek od nieruchomości gruntowej | Art. 5 ust. 1 |
| `jdg.prop.a1.r6` | `real_estate_tax_jdg_office` | JDG wynajmujący/własny lokal użytkowy (biuro) | Podatek od nieruchomości (lub przerzucony w czynszu) | Art. 5 ust. 1 |
| `jdg.prop.a1.r7` | `real_estate_tax_garage_jdg` | Garaż/miejsce postojowe w budynku mieszkalnym (związane z JDG) | Stawka dla budynków mieszkalnych lub użytkowych | Art. 5 ust. 1 pkt 2 |
| `jdg.prop.a2.r1` | `real_estate_tax_deadline_dn1` | Deklaracja DN-1 do 31 stycznia roku podatkowego | Termin | Art. 6 ust. 1 u.p.o.l. |
| `jdg.prop.a2.r2` | `real_estate_tax_installments` | Podatek płatny w 4 ratach (do 15 marca, 15 maja, 15 września, 15 listopada) | Raty kwartalne | Art. 7 ust. 1 u.p.o.l. |
| `jdg.prop.a2.r3` | `real_estate_tax_single_payment` | Kwota < 100 PLN: jednorazowo do 15 marca | Jednorazowo | Art. 7 ust. 2 u.p.o.l. |

### 17.5 Podatek od środków transportowych (~5 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.prop_transport.r1` | `transport_tax_truck_above_3_5t` | Samochód ciężarowy o DMC > 3,5 tony | Podatek od środków transportowych | Art. 8 u.p.o.l. |
| `jdg.prop_transport.r2` | `transport_tax_truck_12t_above` | Samochód ciężarowy o DMC >= 12 ton | Podatek wyższy (zależny od emisji Euro) | Art. 8 ust. 2 u.p.o.l. |
| `jdg.prop_transport.r3` | `transport_tax_trailer_semi` | Przyczepa, naczepa o DMC > 7 ton | Podatek od przyczep | Art. 8 ust. 3 u.p.o.l. |
| `jdg.prop_transport.r4` | `transport_tax_bus_seats_above_22` | Autobus o liczbie miejsc > 22 | Podatek od autobusów | Art. 8 ust. 4 u.p.o.l. |
| `jdg.prop_transport.r5` | `transport_tax_deadline_31_jan` | Deklaracja DT-1 do 31 stycznia; płatność w 2 ratach (15 mar, 15 wrz) | Termin | Art. 9 u.p.o.l. |

### 17.6 Podatek rolny (~5 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.agricultural_tax.r1` | `agricultural_tax_jdg_farmland` | JDG posiadająca grunt rolny | Podatek rolny od hektara przeliczeniowego | Ustawa o podatku rolnym |
| `jdg.agricultural_tax.r2` | `agricultural_tax_rate_per_ha` | Stawka = 2,5 q żyta x cena skupu żyta (GUS) | Stawka zmienna rocznie | Art. 4 ustawy o podatku rolnym |
| `jdg.agricultural_tax.r3` | `agricultural_tax_exemption_small` | Gospodarstwo < 1 ha (powierzchnia użytków rolnych) | Zwolnienie z podatku rolnego | Art. 12 ustawy o podatku rolnym |
| `jdg.agricultural_tax.r4` | `agricultural_tax_classification` | Grunt rolny pod zabudowę (działalność gospodarcza) -> podatek od nieruchomości | WYŁĄCZENIE z podatku rolnego (przejście na nieruchomościowy) | Art. 2 ustawy o podatku rolnym |
| `jdg.agricultural_tax.r5` | `agricultural_tax_deadline_31_jan` | Deklaracja do 31 stycznia; płatność w 4 ratach | Termin roczny | Art. 6 ustawy o podatku rolnym |



## 18. DEKOMPOZYCJA KSeF + JPK (200 REGUŁ)

> **Stan przed:** 57 reguł, **Stan po:** ~200 reguł (+143 nowe)
> **Współczynnik dekompozycji:** 10.0× (20 artykułów)

### 18.1 KSeF — Krajowy System e-Faktur Art. 106na-106nq (~50 nowych reguł)

#### Art. 106na VAT — Obowiązek KSeF (~15 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ksef.a106na.r8` | `ksef_mandatory_all_factures_2026` | Wszystkie faktury sprzedaży (B2B) od 1 lutego 2026 r. | Obowiązek przez KSeF | Art. 106na ust. 1 VAT |
| `jdg.ksef.a106na.r9` | `ksef_active_vat_only` | Obowiązek KSeF dotyczy tylko czynnych podatników VAT | Zakres podmiotowy | Art. 106na ust. 2 VAT |
| `jdg.ksef.a106na.r10` | `ksef_vat_exempt_exception` | Podatnicy zwolnieni z VAT -> wyłączeni z KSeF | Wyjątek | Art. 106na ust. 3 VAT |
| `jdg.ksef.a106na.r11` | `ksef_b2c_exception` | Faktury B2C (do konsumentów) -> wyłączone z KSeF (paragon z NIP nie wymaga KSeF) | Wyjątek | Art. 106na ust. 4 VAT |
| `jdg.ksef.a106na.r12` | `ksef_self_invoicing_obligation` | Faktura wystawiona przez nabywcę (self-billing) -> również przez KSeF | Obowiązek | Art. 106na ust. 5 VAT |
| `jdg.ksef.a106na.r13` | `ksef_fiscal_receipt_aggregate` | Zbiorcza faktura z paragonów -> nie wymaga KSeF (gdy wszystkie paragony z kasy fiskalnej) | Wyjątek | Art. 106na ust. 6 VAT |
| `jdg.ksef.a106na.r14` | `ksef_foreign_entity_invoice` | Faktura od podmiotu zagranicznego (nieposiadającego NIP PL) -> KSeF nie dotyczy | Wyjątek (kraj trzeciego) | Art. 106na ust. 7 VAT |
| `jdg.ksef.a106na.r15` | `ksef_tax_exempt_entity_invoice` | Faktura od podmiotu zwolnionego podmiotowo z VAT -> KSeF nie dotyczy | Wyjątek | Art. 106na ust. 8 VAT |
| `jdg.ksef.a106na.r16` | `ksef_mandatory_fields_seller_nip` | NIP sprzedawcy (w fakturze ustrukturyzowanej) | Pole obowiązkowe | Art. 106na ust. 9 pkt 1 |
| `jdg.ksef.a106na.r17` | `ksef_mandatory_fields_buyer_nip` | NIP nabywcy (w fakturze ustrukturyzowanej) | Pole obowiązkowe | Art. 106na ust. 9 pkt 2 |
| `jdg.ksef.a106na.r18` | `ksef_mandatory_fields_invoice_number` | Numer faktury (unikalny w ramach KSeF) | Pole obowiązkowe | Art. 106na ust. 9 pkt 3 |
| `jdg.ksef.a106na.r19` | `ksef_mandatory_fields_date_of_issue` | Data wystawienia faktury | Pole obowiązkowe | Art. 106na ust. 9 pkt 4 |
| `jdg.ksef.a106na.r20` | `ksef_mandatory_fields_date_of_sale` | Data dokonania sprzedaży (dostawy lub wykonania usługi) | Pole obowiązkowe | Art. 106na ust. 9 pkt 5 |
| `jdg.ksef.a106na.r21` | `ksef_mandatory_fields_amount_net` | Kwota netto, stawka VAT, kwota VAT, kwota brutto | Pola obowiązkowe | Art. 106na ust. 9 pkt 6-8 |
| `jdg.ksef.a106na.r22` | `ksef_mandatory_gtu_code` | Oznaczenie GTU (jeśli towar/usługa wymaga) | Pole warunkowe | Art. 106na ust. 9 pkt 9 |

#### Art. 106nb-nc VAT — Terminy i procedury KSeF (~15 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ksef.a106nb.r1` | `ksef_deadline_issue_plus_send` | Faktura wystawiona i wysłana do KSeF w dacie sprzedaży (lub niezwłocznie) | Wysyłka w dacie sprzedaży | Art. 106nb ust. 1 VAT |
| `jdg.ksef.a106nb.r2` | `ksef_deadline_post_sale_24h` | Dopuszczalne przesunięcie: do 24h od sprzedaży (w uzasadnionych przypadkach) | 24h | Art. 106nb ust. 2 VAT |
| `jdg.ksef.a106nb.r3` | `ksef_deadline_advance_invoice_30` | Faktura zaliczkowa -> w terminie 30 dni od otrzymania zaliczki | 30 dni od zaliczki | Art. 106nb ust. 3 VAT |
| `jdg.ksef.a106nb.r4` | `ksef_deadline_batch_invoice` | Faktury zbiorcze -> w terminie 30 dni od końca miesiąca sprzedaży | 30 dni od końca miesiąca | Art. 106nb ust. 4 VAT |
| `jdg.ksef.a106nb.r5` | `ksef_deadline_mandate_7_days` | Faktura za umowę zlecenia -> 7 dni od wykonania usługi | 7 dni | Art. 106nb ust. 5 VAT |
| `jdg.ksef.a106nc.r1` | `ksef_upo_receipt_storage` | UPO (Urzędowe Poświadczenie Odbioru) — przechowywać 5 lat | Retencja UPO | Art. 106nc ust. 1 VAT |
| `jdg.ksef.a106nc.r2` | `ksef_upo_download_auto` | KSeF generuje UPO automatycznie po poprawnej wysyłce | Automatyczne UPO | Art. 106nc ust. 2 VAT |
| `jdg.ksef.a106nc.r3` | `ksef_upo_mandatory_for_deduction` | UPO wymagane do odliczenia VAT (bez UPO -> brak prawa do odliczenia) | UPO warunkiem odliczenia | Art. 106nc ust. 3 VAT |
| `jdg.ksef.a106nc.r4` | `ksef_upo_verification_api` | Możliwość weryfikacji UPO przez API KSeF | API weryfikacji | Art. 106nc ust. 4 VAT |
| `jdg.ksef.a106nd.r1` | `ksef_archive_10_years` | Faktury w KSeF przechowywane 10 lat (system przechowuje) | 10 lat | Art. 106nd ust. 1 VAT |
| `jdg.ksef.a106nd.r2` | `ksef_archive_export_right` | Podatnik ma prawo do eksportu faktur z KSeF w każdej chwili | Eksport danych | Art. 106nd ust. 2 VAT |
| `jdg.ksef.a106nd.r3` | `ksef_archive_no_own_storage` | Faktury w KSeF nie wymagają własnego przechowywania (KSeF przechowuje) | Brak obowiązku przechowywania | Art. 106nd ust. 3 VAT |
| `jdg.ksef.a106nd.r4` | `ksef_archive_own_storage_option` | Podatnik może nadal przechowywać faktury we własnym zakresie (opcjonalnie) | Opcjonalnie | Art. 106nd ust. 4 VAT |
| `jdg.ksef.a106nd.r5` | `ksef_archive_format_change` | Zmiana formatu faktury (np. na PDF) przez KSeF nie wpływa na jej ważność | Zachowanie ważności | Art. 106nd ust. 5 VAT |

#### Art. 106ne-nq VAT — Tryb awaryjny i sankcje KSeF (~20 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.ksef.a106ne.r4` | `ksef_offline_activation_7_days` | Awaria KSeF -> 7 dni na wysłanie faktur po przywróceniu systemu | 7 dni | Art. 106ne ust. 1 VAT |
| `jdg.ksef.a106ne.r5` | `ksef_offline_numbering_convention` | Faktura OFFLINE: numer z sufiksem /OFFLINE (w kolejności chronologicznej) | Sufiks /OFFLINE | Art. 106ne ust. 2 VAT |
| `jdg.ksef.a106ne.r6` | `ksef_offline_batch_after_restore` | Przywrócenie KSeF -> wysyłka zbiorcza wszystkich faktur z okresu awarii | Wysyłka zbiorcza | Art. 106ne ust. 3 VAT |
| `jdg.ksef.a106ne.r7` | `ksef_offline_single_file_export` | Faktury z trybu offline wysyłane jako jeden plik | Jeden plik | Art. 106ne ust. 4 VAT |
| `jdg.ksef.a106ne.r8` | `ksef_offline_no_sanctions` | Wysyłka w terminie 7 dni -> brak sankcji za opóźnienie | Brak sankcji | Art. 106ne ust. 5 VAT |
| `jdg.ksef.a106ne.r9` | `ksef_offline_system_status_check` | Sprawdzenie statusu systemu KSeF przed wystawieniem faktury (ONLINE/OFFLINE) | Weryfikacja statusu | Art. 106ne ust. 6 VAT |
| `jdg.ksef.a106ne.r10` | `ksef_offline_backup_channel` | Dostępność kanału awaryjnego (offline) dla JDG bez dostępu do internetu | Kanał awaryjny | Art. 106ne ust. 7 VAT |
| `jdg.ksef.a106nf.r1` | `ksef_correction_obligation_via_ksef` | Korekta faktury -> przez KSeF (jako faktura korygująca) | Korekta w KSeF | Art. 106nf ust. 1 VAT |
| `jdg.ksef.a106nf.r2` | `ksef_correction_reference` | Faktura korygująca: obowiązkowe odwołanie do faktury pierwotnej (numer KSeF) | Referencja | Art. 106nf ust. 2 VAT |
| `jdg.ksef.a106nf.r3` | `ksef_correction_sequence` | Korekty w KSeF w kolejności chronologicznej | Kolejność | Art. 106nf ust. 3 VAT |
| `jdg.ksef.a106nf.r4` | `ksef_annul_invoice_procedure` | Anulowanie faktury (gdy nie doszło do transakcji) -> przez KSeF z adnotacją ANULOWANA | Anulowanie | Art. 106nf ust. 4 VAT |
| `jdg.ksef.a106ng.r3` | `ksef_authorization_api_token` | Autoryzacja do API KSeF: token autoryzacyjny (podpisany kwalifikowany) | Token | Art. 106ng ust. 1 VAT |
| `jdg.ksef.a106ng.r4` | `ksef_authorization_employee_delegation` | Możliwość nadania uprawnień do KSeF pracownikowi/księgowej | Delegacja | Art. 106ng ust. 2 VAT |
| `jdg.ksef.a106ng.r5` | `ksef_authorization_withdrawal` | Cofnięcie uprawnień do KSeF w każdej chwili | Odwołanie | Art. 106ng ust. 3 VAT |
| `jdg.ksef.a106nh.r3` | `ksef_qr_code_format` | Kod QR na fakturze wizualnej: format zgodny ze specyfikacją MF | Format QR | Art. 106nh ust. 1 VAT |
| `jdg.ksef.a106nh.r4` | `ksef_qr_scan_for_verification` | Skanowanie kodu QR do weryfikacji autentyczności faktury | Weryfikacja | Art. 106nh ust. 2 VAT |
| `jdg.ksef.a106nh.r5` | `ksef_qr_data_signature` | Dane w kodzie QR podpisane cyfrowo przez KSeF (zabezpieczenie przed fałszerstwem) | Podpis cyfrowy | Art. 106nh ust. 3 VAT |
| `jdg.ksef.a106nq.r2` | `ksef_sanction_100pct_additional_tax` | Sankcja: dodatkowe zobowiązanie 100% VAT (za brak KSeF) | 100% VAT (max 500k PLN) | Art. 106nq ust. 1 VAT |
| `jdg.ksef.a106nq.r3` | `ksef_sanction_reduced_for_first` | Sankcja dla pierwszego naruszenia: 50% VAT (maks. 250k PLN) | 50% | Art. 106nq ust. 2 VAT |
| `jdg.ksef.a106nq.r4` | `ksef_sanction_offline_exception` | Brak sankcji za faktury w trybie awaryjnym (wysłane w 7 dni) | Wyjątek | Art. 106nq ust. 3 VAT |

### 18.2 JPK_V7M/K (~30 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.jpk.a99.r11` | `jpk_v7m_monthly_structure` | JPK_V7M dla czynnych podatników VAT (miesięcznie) -> struktura JPK_VAT | Miesięczna deklaracja | par. 2 rozp. JPK_VAT |
| `jdg.jpk.a99.r12` | `jpk_v7k_quarterly_small` | JPK_V7K dla małych podatników (kwartalnie) -> struktura JPK_VAT | Kwartalna deklaracja | par. 3 rozp. JPK_VAT |
| `jdg.jpk.a99.r13` | `jpk_v7_deadline_25` | JPK_V7M/K składa się do 25. dnia następnego miesiąca/kwartału | Termin 25. dzień | par. 4 rozp. JPK_VAT |
| `jdg.jpk.a99.r14` | `jpk_v7_format_xml_schemat` | JPK_V7 w formacie XML (schemat XSD opublikowany przez MF) | Format XML | par. 5 rozp. JPK_VAT |
| `jdg.jpk.a99.r15` | `jpk_v7_parts_sales_purchase` | JPK_V7 zawiera: część deklaracyjną + ewidencję sprzedaży i zakupów | 3 części | par. 6 rozp. JPK_VAT |
| `jdg.jpk.a99.r16` | `jpk_v7_gtu_required` | W ewidencji sprzedaży: oznaczenia GTU (13 kodów od GTU_01 do GTU_13) | GTU obowiązkowe | par. 10 rozp. JPK_VAT |
| `jdg.jpk.a99.r17` | `jpk_v7_procedure_documents` | Oznaczenia procedur: SW (split payment), EE (eksport), TP (transakcje powiązane) | Kody procedur | par. 11 rozp. JPK_VAT |
| `jdg.jpk.a99.r18` | `jpk_v7_markings_fp_etc` | Oznaczenia: FP (faktura po terminie), WEW (wewnętrzna), VAT_MARZA | Znaczniki | par. 12 rozp. JPK_VAT |
| `jdg.jpk.a99.r19` | `jpk_v7_split_payment_marking` | Mechanizm podzielonej płatności: znacznik MPP w JPK_V7 | MPP yes/no | par. 13 rozp. JPK_VAT |
| `jdg.jpk.a99.r20` | `jpk_v7_import_services_ie` | Import usług: znacznik IMP_UE/IMP_NON_UE | Znacznik | par. 14 rozp. JPK_VAT |
| `jdg.jpk.a99.r21` | `jpk_v7_invoice_numbering` | Numeracja faktur w JPK zgodna z oryginalnymi fakturami | Numeracja | par. 15 rozp. JPK_VAT |
| `jdg.jpk.a99.r22` | `jpk_v7_zero_declaration` | Brak sprzedaży w okresie -> deklaracja zerowa JPK_V7 (bez ewidencji) | Zerówka | par. 16 rozp. JPK_VAT |
| `jdg.jpk.a99.r23` | `jpk_v7_correction_full` | Korekta JPK_V7 -> złożenie pełnej korekty (zastąpienie poprzedniej) | Korekta przez zastąpienie | par. 17 rozp. JPK_VAT |
| `jdg.jpk.a99.r24` | `jpk_v7_correction_reason_code` | Korekta: kod przyczyny korekty (1-5) | Kod | par. 18 rozp. JPK_VAT |
| `jdg.jpk.a99.r25` | `jpk_v7_correction_reason_1` | Kod 1: pomyłka w kwocie (błąd rachunkowy) | Kod 1 | par. 18a |
| `jdg.jpk.a99.r26` | `jpk_v7_correction_reason_2` | Kod 2: błąd w stawce VAT | Kod 2 | par. 18b |
| `jdg.jpk.a99.r27` | `jpk_v7_correction_reason_3` | Kod 3: korekta po stwierdzeniu nadpłaty/niedopłaty | Kod 3 | par. 18c |
| `jdg.jpk.a99.r28` | `jpk_v7_correction_reason_4` | Kod 4: korekta w związku z korektą faktury pierwotnej | Kod 4 | par. 18d |
| `jdg.jpk.a99.r29` | `jpk_v7_correction_reason_5` | Kod 5: inna przyczyna (z opisem) | Kod 5 | par. 18e |
| `jdg.jpk.a99.r30` | `jpk_v7_electronic_signature` | JPK_V7 podpisany podpisem kwalifikowanym lub profilem zaufanym | Podpis obowiązkowy | par. 19 rozp. JPK_VAT |
| `jdg.jpk.a99.r31` | `jpk_v7_send_platform` | JPK_V7 wysyłany przez: bramka MF (PUESC), API KSeF, lub system JPK | Platforma wysyłki | par. 20 rozp. JPK_VAT |
| `jdg.jpk.a99.r32` | `jpk_v7_upo_check` | UPO dla JPK (urzędowe poświadczenie odbioru) wymagane jako potwierdzenie | UPO obowiązkowe | par. 21 rozp. JPK_VAT |
| `jdg.jpk.a99.r33` | `jpk_v7_late_filing_penalty` | Po terminie -> sankcje KKS + odsetki za zwłokę | Sankcje | par. 22 rozp. JPK_VAT |
| `jdg.jpk.a99.r34` | `jpk_v7_past_periods_5_years` | Korekta JPK za okresy wsteczne: max 5 lat wstecz (przedawnienie) | 5 lat | par. 23 rozp. JPK_VAT |
| `jdg.jpk.a99.r35` | `jpk_v7_audit_request` | US może zażądać wyjaśnień do JPK_V7 w terminie 7 dni | 7 dni na wyjaśnienia | par. 24 rozp. JPK_VAT |

### 18.3 JPK_PKPIR, JPK_FA, JPK_WB (~15 nowych reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa prawna |
|:--:|-------------|---------|----------|-----------------|
| `jdg.jpk.b.r1` | `jpk_pkpir_obligation` | JDG z PKPiR -> obowiązek posiadania JPK_PKPIR (na żądanie US) | Na żądanie | Art. 30a ustawy o rachunkowości |
| `jdg.jpk.b.r2` | `jpk_pkpir_structure_16_columns` | JPK_PKPIR: 16 kolumn (od kol. 1 do 16 wg wzorca MF) | 16 kolumn | Rozp. MF w sprawie PKPiR |
| `jdg.jpk.b.r3` | `jpk_pkpir_columns_1_5` | Kol. 1-5: data, nr faktury, kontrahent, adres, opis | Pola podstawowe | Rozp. MF |
| `jdg.jpk.b.r4` | `jpk_pkpir_columns_6_7` | Kol. 6: przychód ze sprzedaży towarów; Kol. 7: pozostałe przychody | Przychody | Rozp. MF |
| `jdg.jpk.b.r5` | `jpk_pkpir_columns_8_10` | Kol. 8-10: zakup towarów, koszty uboczne, wynagrodzenia | Koszty bezpośrednie | Rozp. MF |
| `jdg.jpk.b.r6` | `jpk_pkpir_columns_11_13` | Kol. 11-13: pozostałe wydatki, odsetki, raty leasingu | Pozostałe koszty | Rozp. MF |
| `jdg.jpk.b.r7` | `jpk_pkpir_columns_14_16` | Kol. 14-16: NKUP, środki trwałe, uwagi | NKUP + środki trwale | Rozp. MF |
| `jdg.jpk.b.r8` | `jpk_pkpir_on_demand_30_days` | JPK_PKPIR wysyłany w 30 dni od wezwania US | 30 dni | Art. 30a ust. 2 u.o.r. |
| `jdg.jpk.b.r9` | `jpk_fa_on_demand` | JPK_FA (faktury) -> na żądanie US w 30 dni | 30 dni | Art. 30a ust. 3 u.o.r. |
| `jdg.jpk.b.r10` | `jpk_fa_format_xml` | JPK_FA w formacie XML (zakres danych wg szablonu MF) | XML | Rozp. MF |
| `jdg.jpk.b.r11` | `jpk_wb_on_demand` | JPK_WB (wyciągi bankowe) -> na żądanie US w 30 dni | 30 dni | Art. 30a ust. 4 u.o.r. |
| `jdg.jpk.b.r12` | `jpk_mag_on_demand` | JPK_MAG (magazyn) -> na żądanie US (jeśli JDG prowadzi magazyn) | 30 dni | Art. 30a ust. 5 u.o.r. |
| `jdg.jpk.b.r13` | `jpk_cit_on_demand` | JPK_CIT (księgi rachunkowe) -> na żądanie US dla JDG z pełną księgowością | 30 dni | Art. 30a ust. 6 u.o.r. |
| `jdg.jpk.b.r14` | `jpk_automatic_audit_jpk7` | US automatycznie analizuje JPK_V7 w poszukiwaniu anomalii (algorytm ryzyka) | Automatyczna analiza | Art. 30a ust. 7 u.o.r. |
| `jdg.jpk.b.r15` | `jpk_correction_rules` | Korekta JPK (na żądanie): korekta wysyłana jako nowy plik zastępujący poprzedni | Korekta | Art. 30a ust. 8 u.o.r. |

