# 📚 Master Rules Reference — 240 Reguł OPA/Rego dla NexusAI

> **Status:** Dokumentacja ENTERPRISE v7.0 — Kompletny spis (z Deep Docs Analysis)
> **Data:** 2026-07-07
> **Reguł:** 240 | **Pakietów:** 37+ | **Domen prawnych:** 47+
> **Powiązane:** wszystkie dokumenty Plan OPA (00-21)

---

## 🔍 Szybki Indeks — Priorytety

| Priorytet | Pakiet | Odpowiedzialność | Reguł | Status |
|-----------|--------|-------------------|:-----:|--------|
| **P0-P9** | `tax.risk` | Fraud, anomalie, trust score, semantic guard | 9 | ✅ 5/9 |
| **P10-P19** | `tax.routing` | OCR field confidence, routing decyzji | 10 | ✅ 2/10 |
| **P20-P39** | `tax.compliance` | Biała Lista, MPP, KSeF, retencja, gotówka | 10 | ✅ 3/10 |
| **P40-P49** | `tax.crossborder` | EU reverse charge, WDT, import, export | 6 | ✅ 4/6 |
| **P50-P69** | `tax.vat.substantive` | Stawki VAT, zwolnienia, ulga na złe długi | 13 | ✅ 9/13 |
| **P65-P69** | `tax.vat.gtu` | Kody GTU dla JPK_V7 | 3 | ✅ 1/3 |
| **P70-P74** | `tax.direct.cit` | CIT standard/estonian/small, TP, straty | 5 | ✅ 5/5 |
| **P74-P79** | `tax.direct.pit` | PIT skala/liniowy/ryczałt, ulgi osobiste | 7 | ✅ 7/7 |
| **P80-P89** | `tax.allowances` | Ulgi: B+R, IP Box, termo, prototyp, robotyzacja | 10 | ✅ 10/10 |
| **P90-P94** | `tax.accounting` | Amortyzacja, FIFO, RMK, FX | 5 | ✅ 5/5 |
| **P95-P99** | `tax.zus` | Składki ZUS, Mały ZUS+, ulga na start | 5 | ✅ 5/5 |
| **P320-P331** | `tax.uor_books`, `tax.uor_valuation`, `tax.cit_deductions`, `tax.vat_registration`, `tax.ordynacja_extended`, `tax.labor_extended`, `tax.pit_withholding`, `tax.uor_reports` | Deep Docs: podwójny zapis, zamknięcie ksiąg, rezerwy UoR, CIT złe długi, VAT-R, zabezpieczenia, dowody UoR, bilans, BHP, ulgi w spłacie, koszt wytworzenia, małe umowy PIT | 12 | ✅ 12/12 |
| **P100-P200** | `tax.fallback` | Domyślne stawki, no_match | 2 | ✅ 2/2 |
| **P110-P180** | `compliance.*` | PPK, akcyza, IFRS, leasing, darowizny, KŚT, KUP, JPK, AML, FX, CEIDG, KSH, Ordynacja | 33 | 🟡 plan |
| **P185-P221** | `tax.*`, `compliance.*` | VAT odliczenia, podatki lokalne, praca, zasiłki, BDO, NGO, UoR, MSSF, PKPiR | 27 | 🟡 plan |
| **P230-P265** | `tax.*` | VAT obowiązek/podstawa, PIT/CIT zaliczki, UoR szczegółowe, energetyka, transport, KSeF/JPK | 36 | 🟡 plan |
| **P270-P290** | `tax.*` | CIT/PIT KUP, PCC, SD, dewizy, akcyza, KP, MSSF 2, UoR zmiany | 21 | 🟡 plan |
| **P295-P310** | `tax.*` | VAT rejestracja, zeznania roczne, KKS, TP, korekty, KSeF, JPK, AML | 16 | 🟡 plan |

**✅ = zaimplementowane w `policies/tax/`** | **🟡 = pseudokod w dokumentach planu**

---

## 📦 `tax.risk` — Ryzyko i Fraud (P0-P9)

### P0: `fraud_graph_match` ✅ IMPLEMENTED
> **PRIORYTET 0** | Art. 86 ust. 1 VAT, Art. 55 KKS | `_routing: BLOCK_AND_ALERT`

```rego
# Kontrahent w sieci fraudowej VAT → natychmiastowa blokada
decide := {"matched": true, "rule_id": "tax.risk.fraud_graph_match", ...} {
    input.vendor.fraud_flag == true
}
```

### P1: `counterparty_trust_low` ✅ IMPLEMENTED
> **PRIORYTET 1** | Art. 22 UoR | `_routing: TRIAGE_QUEUE`

```rego
decide := {"matched": true, "rule_id": "tax.risk.counterparty_trust_low", ...} {
    input.vendor.trust_score < object.get(input.thresholds.limits, "trust_auto_post", 0.92)
    input.vendor.trust_score > 0
}
```

### P2: `anomaly_amount` ✅ IMPLEMENTED
> **PRIORYTET 2** | Art. 22 UoR | Kwota > 3σ od średniej kategorii

```rego
decide := {"matched": true, "rule_id": "tax.risk.anomaly_amount", ...} {
    input.invoice.amount_net > input.invoice.category_avg_amount + 3 * input.invoice.category_stddev_amount
}
```

### P3: `new_counterparty_flag` ✅ IMPLEMENTED
> **PRIORYTET 3** | Art. 22 UoR, AML | Nowy kontrahent → TRIAGE

```rego
decide := {"matched": true, "rule_id": "tax.risk.new_counterparty_flag", ...} {
    input.vendor.is_new == true
}
```

### P4: `high_risk_country` 🟡
> **PRIORYTET 4** | Art. 11a-11q CIT | Kraj wysokiego ryzyka podatkowego → BLOCK

```rego
decide = verdict {
    input.vendor.country in input.thresholds.tax_haven_list
    input.invoice.amount_gross >= input.thresholds.limits.transfer_pricing_limit
    verdict := {"matched": true, "rule_id": "tax.risk.high_risk_country",
        "priority": 4, "_routing": "BLOCK_AND_ALERT",
        "transfer_pricing_alert": true, "_legal_basis": "Art. 11a-11q CIT"}
}
```

### P5: `semantic_guard_disallowed` ✅ IMPLEMENTED
> **PRIORYTET 5** | Art. 23 ust. 1 pkt 23 PIT, Art. 16 ust. 1 pkt 28 CIT | Wydatki niezwiązane z działalnością → NKUP

```rego
decide := {"matched": true, "rule_id": "tax.risk.semantic_guard_disallowed",
    "income_tax_qualification": "non_deductible", "_routing": "BLOCK_AND_ALERT", ...} {
    disallowed_category(input.invoice.category_code)
}
```

### P6: `related_party_transaction` 🟡
> **PRIORYTET 6** | Art. 11a-11q CIT | Podmiot powiązany → TP docs

```rego
decide = verdict {
    input.vendor.is_related_party == true
    input.invoice.amount_gross >= input.thresholds.limits.transfer_pricing_limit
    verdict := {"matched": true, "rule_id": "tax.risk.related_party_transaction",
        "priority": 6, "transfer_pricing_required": true,
        "_legal_basis": "Art. 11a-11q CIT"}
}
```

### P8: `duplicate_invoice_suspect` 🟡
> **PRIORYTET 8** | Art. 22 UoR, Art. 55 KKS

### P9: `nip_format_invalid` 🟡
> **PRIORYTET 9** | Art. 96b VAT

---

## 📦 `tax.routing` — Field Confidence (P10-P19)

### P10: `fc_vat_rate_low` ✅ IMPLEMENTED
> Niska pewność stawki VAT (CIT_STANDARD) → BLOCK_AND_ALERT

### P12: `fc_vendor_nip_low` ✅ IMPLEMENTED
> Niska pewność NIP → BLOCK_AND_ALERT (problem z Białą Listą)

### P11, P13-P19: pozostałe 🟡
> P11 (fc_total_net_low_cit), P13 (CIT estoński), P14-P18 (podatek liniowy, ryczałt, kategorie mieszane), P19 (global_minimum)

---

## 📦 `tax.compliance` — Zgodność dokumentacyjna (P20-P39)

### P20: `whitelist_missing_over_limit` ✅ IMPLEMENTED
> **PRIORYTET 20** | Art. 96b VAT, Art. 117ba Ordynacji | Brak na Białej Liście >15k PLN → BLOCK

```rego
decide := {"matched": true, "rule_id": "tax.compliance.whitelist_missing",
    "_routing": "BLOCK_AND_ALERT", "_warnings": ["Brak na Białej Liście — odpowiedzialność solidarna"], ...} {
    input.invoice.amount_gross >= object.get(input.thresholds.limits, "mpp_limit", 15000)
    input.vendor.on_whitelist == false
}
```

### P21: `whitelist_account_mismatch` 🟡
> **PRIORYTET 21** | Art. 117ba § 1 Ordynacji | Rachunek niezgodny z Białą Listą → BLOCK

```rego
decide = verdict {
    input.invoice.amount_gross >= 15000
    input.vendor.account_on_whitelist == false
    input.vendor.on_whitelist == true
    verdict := {"matched": true, "rule_id": "tax.compliance.whitelist_account_mismatch",
        "priority": 21, "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Art. 117ba § 1 Ordynacji podatkowej"}
}
```

### P22: `whitelist_check_expired` 🟡
> Weryfikacja WL przeterminowana >30 dni

### P25: `split_payment_mandatory` ✅ IMPLEMENTED
> **PRIORYTET 25** | Art. 108a VAT | MPP dla towarów wrażliwych >15k PLN

```rego
decide := {"matched": true, "rule_id": "tax.compliance.split_payment_mandatory",
    "mpp_required": true, ...} {
    input.invoice.amount_gross >= object.get(input.thresholds.limits, "mpp_limit", 15000)
    helpers.is_mpp_sensitive(input.invoice.category_code)
}
```

### P26: `vat_on_import_consent` 🟡 | P28: `ksef_structured_invoice` 🟡 | P30: `retention_invoice` 🟡

### P35: `cash_transaction_over_limit` ✅ IMPLEMENTED
> **PRIORYTET 35** | Art. 22p PIT, Art. 15d CIT | Gotówka >15k PLN → brak KUP

```rego
decide := {"matched": true, "rule_id": "tax.compliance.cash_over_limit",
    "income_tax_qualification": "non_deductible", ...} {
    input.invoice.is_cash_payment == true
    input.invoice.amount_gross >= object.get(input.thresholds.limits, "cash_transaction_limit", 15000)
}
```

### P36: `payment_after_due_date` 🟡 | P38: `statute_of_limitations_approaching` 🟡

---

## 📦 `tax.crossborder` — Transgraniczne (P40-P49)

### P40: `eu_reverse_charge` ✅ IMPLEMENTED
> **PRIORYTET 40** | Art. 17 ust. 1 pkt 3 VAT | EU + active VAT → reverse charge

```rego
decide := {"matched": true, "rule_id": "tax.crossborder.eu_reverse_charge",
    "vat_rate": "0.00", "procedure": "VAT_REVERSE_CHARGE", "gtu_code": "GTU_12", ...} {
    input.vendor.country == "EU"
    input.vendor.vat_status == "active"
}
```

### P41: `eu_import_services` 🟡 | Art. 28b VAT | Import usług z UE

### P42: `wdt_intracommunity_supply` ✅ IMPLEMENTED
> **PRIORYTET 42** | Art. 42 VAT | WDT — 0% VAT dla sprzedawcy

### P45: `import_non_eu` ✅ IMPLEMENTED
> **PRIORYTET 45** | Art. 17 ust. 1 pkt 1 VAT | Import spoza UE → 23% + IMPORT

### P46: `non_eu_services_import` 🟡 | Art. 17 ust. 1 pkt 4 VAT

### P48: `export_goods` ✅ IMPLEMENTED
> **PRIORYTET 48** | Art. 41 ust. 4-11 VAT | Eksport → 0% VAT

---

## 📦 `tax.vat.substantive` — VAT merytoryczny (P50-P69)

### P50: `vat_margin_scheme` ✅ IMPLEMENTED
> **PRIORYTET 50** | Art. 120 VAT | Procedura VAT-marża

```rego
decide := {"matched": true, "rule_id": "tax.vat.substantive.margin_scheme",
    "vat_rate": helpers.get_rate("vat_standard", "0.23"), "procedure": "MARGIN", ...} {
    input.invoice.procedure == "MARGIN"
}
```

### P52: `vat_rate_fuel_pl` ✅ IMPLEMENTED
> **PRIORYTET 52** | Art. 41 ust. 1 VAT | Paliwo PL → 23% + GTU_04

### P53: `vat_rate_food_pl` ✅ IMPLEMENTED
> **PRIORYTET 53** | Art. 41 ust. 2a VAT | Żywność PL → 5% + GTU_07

### P54: `vat_rate_books_pl` ✅ IMPLEMENTED
> **PRIORYTET 54** | Art. 41 ust. 2a VAT | Książki → 5% + GTU_01

### P55: `vat_exemption_education` ✅ IMPLEMENTED
> **PRIORYTET 55** | Art. 43 ust. 1 pkt 26-29 VAT | Edukacja → zwolniona

### P56: `vat_exemption_healthcare` ✅ IMPLEMENTED
> **PRIORYTET 56** | Art. 43 ust. 1 pkt 18-20 VAT | Opieka medyczna → zwolniona

### P57: `vat_exemption_finance` ✅ IMPLEMENTED
> **PRIORYTET 57** | Art. 43 ust. 1 pkt 7, 37-41 VAT | Finanse/ubezpieczenia → zwolnione

### P58: `vat_exemption_subject` ✅ IMPLEMENTED
> **PRIORYTET 58** | Art. 113 ust. 1 VAT | Zwolnienie podmiotowe <200k PLN

### P60: `vat_bad_debt_relief` ✅ IMPLEMENTED
> **PRIORYTET 60** | Art. 89a VAT | Ulga na złe długi >150 dni

### P61: `vat_prepayment_rule` 🟡 | P62: `vat_23_correction` 🟡

---

## 📦 `tax.vat.gtu` — Kody GTU (P65-P69)

### P65: `gtu_mapping_by_category` ✅ IMPLEMENTED
> **PRIORYTET 65** | § 10 rozp. JPK_VAT | Mapowanie kategorii → GTU

```rego
decide := {"matched": true, "rule_id": "tax.vat.gtu.mapping",
    "gtu_code": gtu, ...} {
    gtu := helpers.category_to_gtu(input.invoice.category_code)
    gtu != ""
}
```

### P68: `gtu_mapping_transport` 🟡 | P69: `gtu_mapping_gas_energy` 🟡

---

## 📦 `tax.direct.cit` — CIT (P70-P74) ✅ IMPLEMENTED

### P72: `cit_thin_capitalization` (FIRST!)
> **PRIORYTET 72** | Art. 15c CIT | Cienka kapitalizacja → NKUP

```rego
decide := {"matched": true, "rule_id": "tax.direct.cit.thin_cap",
    "income_tax_qualification": "non_deductible", ...} {
    input.vendor.is_related_party == true
    input.invoice.debt_to_equity_ratio > object.get(input.thresholds.limits, "thin_cap_ratio", 3.0)
    input.invoice.expense_type == "INTEREST"
}
```

### P70: `cit_estonian_effective`
> **PRIORYTET 70** | Rozdział 6b CIT | CIT estoński 20% efektywna, odroczenie

### P71: `cit_small_taxpayer`
> **PRIORYTET 71** | Art. 19 ust. 1a CIT | CIT 9% dla małego podatnika

### P73: `cit_standard_taxpayer`
> **PRIORYTET 73** | Art. 19 ust. 1 CIT | Standardowy CIT 19%

### P74: `cit_loss_carry_forward`
> **PRIORYTET 74** | Art. 7 ust. 5 CIT | Rozliczenie straty (50%/rok, max 5 lat)

---

## 📦 `tax.direct.pit` — PIT (P74-P79) ✅ IMPLEMENTED

### P74: `pit_lump_sum_rate` — Stawka ryczałtu wg PKWiU
### P75: `pit_tax_scale` — Skala 12%/32%
### P75b: `pit_linear` — Podatek liniowy 19%
### P76: `pit_joint_filing` — Wspólne rozliczenie (próg ×2)
### P77: `pit_young_exemption` — Ulga <26 lat
### P78: `pit_return_exemption` — Ulga na powrót (4 lata)
### P79: `pit_family_4plus` — Ulga dla rodzin 4+

---

## 📦 `tax.allowances` — Ulgi podatkowe (P80-P89) ✅ IMPLEMENTED

### P80: `relief_rd` — B+R 100%/200% (CBR)
### P81: `relief_prototype` — Prototyp 30%
### P82: `relief_ip_box` — IP Box 5%
### P83: `relief_robotization` — Robotyzacja 50%
### P84: `relief_expansion` — Ekspansja
### P85: `relief_thermo` — Termomodernizacja (max 53k)
### P86: `relief_internet` — Internet (760 PLN/2 lata)
### P87: `relief_rehabilitation` — Rehabilitacja
### P88: `relief_abolition` — Abolicyjna
### P89: `relief_working_senior` — Pracujący senior

---

## 📦 `tax.accounting` — Księgowość (P90-P94) ✅ IMPLEMENTED

### P90: `accounting_linear_depreciation` — Amortyzacja liniowa
### P91: `accounting_degressive_depreciation` — Degresywna (wsp. 2.0)
### P92: `accounting_rmk_deferral` — RMK — rozliczenie w czasie
### P93: `accounting_fx_revaluation` — Rewaluacja walutowa
### P94: `accounting_fifo_inventory` — FIFO — rozchód magazynowy

---

## 📦 `tax.zus` — Składki ZUS (P95-P99) ✅ IMPLEMENTED

### P96: `zus_start_relief` (FIRST!) — Ulga na start (6 mies. tylko zdrowotna)
### P95: `zus_maly_plus` — Mały ZUS+ (30%, 36 mies.)
### P97: `zus_preferential` — Preferencyjny (30%, 24 mies.)
### P99: `zus_standard` — Standardowe stawki
### P98: `zus_health_rate` — Składka zdrowotna (fallback: 9%/4.9% wg tax_form)

---

## 📦 `tax.fallback` — Domyślne (P100+) ✅ IMPLEMENTED

### P100: `domestic_fallback`
> **PRIORYTET 100** | Art. 41 ust. 1 VAT | PL → 23% VAT domyślnie

```rego
decide := {"matched": true, "rule_id": "tax.fallback.domestic_default",
    "vat_rate": helpers.get_rate("vat_standard", "0.23"), "rounding_level": "position", ...} {
    input.vendor.country == "PL"
}
```

### P200: `no_match`
> **PRIORYTET 200** | Zawsze na końcu łańcucha

```rego
else := {"matched": true, "rule_id": "tax.fallback.no_match",
    "vat_rate": helpers.get_rate("vat_standard", "0.23"),
    "_warnings": ["NO_MATCHING_RULE — zastosowano domyślną stawkę 23% VAT"], ...} {
    true
}
```

---

## 📦 Pakiety zaawansowane (P110-P180) 🟡

| Reguła | Priorytet | Podstawa prawna | Kluczowe warunki |
|--------|-----------|-----------------|------------------|
| `ppk_mandatory_enrollment` | P110 | Art. 32 ustawy o PPK | `employees >= PPK threshold AND !ppk_enrolled` |
| `ppk_employer_contributions_kup` | P111 | Art. 15 ust. 1 CIT | `expense_type == PPK_EMPLOYER AND is_paid` |
| `excise_energy_tax` | P115 | Ustawa o pod. akcyzowym | `category == ENERGY AND is_excise_payer` |
| `excise_fuel_tax` | P116 | Ustawa o pod. akcyzowym | `category == FUEL AND !excise_duty_paid` |
| `excise_alcohol_banderoles` | P117 | Ustawa o pod. akcyzowym | `category == ALCOHOL AND domestic` |
| `ifrs16_leasing_recognition` | P120 | MSSF 16 | `uses_ifrs AND lease > 12m` |
| `ias37_provision_recognition` | P121 | MSR 37 | `contingent_liability AND prob ≥ 50%` |
| `ias12_deferred_tax` | P122 | MSR 12 | `accounting_profit != tax_profit` |
| `leasing_operacyjny_tax` | P125 | Art. 17b CIT | Term ≥ 40% normatywnego, raty w KUP |
| `leasing_finansowy_tax` | P126 | Art. 17f CIT | Term < 40% normatywnego, KUP=amortyzacja+odsetki |
| `leasing_car_over_150k_limit` | P127 | Art. 16 ust. 1 pkt 49a CIT | Auto >150k PLN → limit KUP |
| `donation_ngo_limit` | P130 | Art. 18 CIT | Darowizna OPP, limit 10%(CIT)/6%(PIT) |
| `donation_blood` | P131 | Art. 26 PIT | Krew — ekwiwalent 130 PLN/litr |
| `donation_church` | P132 | Art. 18 ust. 1 pkt 7 CIT | Kościół — bez limitu |
| `kst_group_0_land` | P135 | Art. 16c pkt 1 CIT | Grunty — bez amortyzacji |
| `kst_group_1_buildings` | P136 | KŚT zał. 1, gr. 1 | Budynki — 2.5%/rok |
| `kst_group_4_computers` | P137 | KŚT zał. 1, gr. 4 | Komputery — 30%/rok |
| `kst_group_7_cars` | P138 | KŚT zał. 1, gr. 7 | Auta — 20%/rok |
| `kst_low_value_one_off` | P139 | Art. 16d CIT | ≤10k PLN — jednorazowa amortyzacja |
| `kup_representation_non_deductible` | P140 | Art. 16 ust. 1 pkt 28 CIT | Reprezentacja → NKUP |
| `kup_penalties_non_deductible` | P141 | Art. 16 ust. 1 pkt 18-22 CIT | Kary → NKUP |
| `kup_unpaid_zus` | P142 | Art. 15 ust. 4h CIT | Niezapłacony ZUS → NKUP |
| `jpk_margin_procedure_flag` | P145 | § 10 JPK_VAT | MR_UZ/MR_T znacznik |
| `jpk_mpp_marker` | P146 | § 10 JPK_VAT | MPP znacznik |
| `jpk_tp_marker` | P147 | § 10 JPK_VAT | TP znacznik |
| `aml_high_value_transaction` | P150 | Art. 72 AML | >15k EUR → raport GIIF |
| `aml_pep_detection` | P151 | Art. 46 AML | PEP → wzmożona weryfikacja |
| `aml_crbr_mismatch` | P152 | Art. 58-68 AML | Brak UBO w CRBR |
| `fx_nbp_reporting` | P155 | Art. 30 Prawa dewizowego | Raportowanie NBP |
| `ceidg_vendor_suspended` | P160 | Art. 88 VAT | Zawieszony CEIDG → BLOCK |
| `business_unregistered_activity_limit` | P165 | Art. 5 Pr. przedsiębiorców | Limit działalności nieewidencjonowanej |
| `ksh_dividend_capability_check` | P170 | Art. 192 KSH | Zdolność dywidendowa |
| `ord_correction_lock_during_audit` | P180 | Art. 81b § 1 Ordynacji | Korekta zablokowana w trakcie kontroli |

---

## 📦 VAT odliczenia, lokalne, praca, BDO, NGO, UoR, MSSF, PKPiR (P185-P221) 🟡

| Reguła | Priorytet | Podstawa prawna | Kluczowe warunki |
|--------|-----------|-----------------|------------------|
| `vat_input_deduction_pro_rata` | P185 | Art. 90 VAT | Proporcja VAT przy mieszanej działalności |
| `vat_input_deduction_vehicle_50pct` | P186 | Art. 86a VAT | Ograniczenie 50% dla aut mieszanych |
| `vat_correction_annual` | P187 | Art. 91 VAT | Korekta roczna VAT (5/10 lat) |
| `vat_correction_deadline` | P188 | Art. 89a ust. 1 VAT | Termin korekty VAT — 3 miesiące |
| `vat_correction_credit_note` | P189 | Art. 89a ust. 2 VAT | Korekta na podstawie noty kredytowej |
| `property_tax_obligation` | P190 | UPoL | Podatek od nieruchomości |
| `transport_tax_obligation` | P191 | UPoL | Podatek od środków transportu >3.5t |
| `labor_holiday_equivalent` | P192 | Art. 171 KP | Ekwiwalent urlopowy — KUP |
| `labor_severance_pay` | P193 | Art. 92 KP | Odprawa — KUP |
| `labor_minimum_wage_compliance` | P194 | Ustawa o min. wynagr. | Wynagrodzenie ≥ minimalne |
| `sick_leave_benefit` | P195 | Art. 4 ustawy zasiłkowej | Zasiłek chorobowy ZUS/pracodawca |
| `maternity_benefit` | P196 | Art. 29-31 ustawy zasiłkowej | Zasiłek macierzyński 100%/80% |
| `construction_material_vat_refund` | P197 | Ustawa o zwrocie VAT | Zwrot VAT za materiały budowlane |
| `bdo_waste_record_obligation` | P198 | Ustawa o BDO | Obowiązek ewidencji BDO |
| `co2_emission_fee` | P199 | Prawo ochr. środowiska | Opłata CO2 |
| `ngo_tax_exemption_check` | P200 | Art. 17 CIT | Zwolnienie NGO (dział. statutowa) |
| `ngo_business_activity_taxable` | P201 | Art. 17 ust. 1a CIT | Dział. gospodarcza NGO → CIT |
| `uor_matching_principle` | P205 | Art. 6 UoR | Zasada współmierności |
| `uor_inventory_obligation` | P206 | Art. 26 UoR | Inwentaryzacja na dzień bilansowy |
| `uor_financial_statement_deadline` | P207 | Art. 52 UoR | Termin sprawozdania — 3 miesiące |
| `uor_intangible_assets` | P208 | Art. 34 UoR | WNiP — amortyzacja |
| `tax_interpretation_binding` | P210 | Art. 14k Ordynacji | Interpretacja indywidualna |
| `tax_liability_third_party` | P211 | Art. 116 Ordynacji | Odpowiedzialność zarządu |
| `ifrs9_financial_instruments` | P215 | MSSF 9 | Instrumenty finansowe |
| `ifrs15_revenue_recognition` | P216 | MSSF 15 | Rozpoznanie przychodów (5-step) |
| `pkpir_entry_format` | P220 | Rozp. MF PKPiR | Format PKPiR (16 kolumn) |
| `pkpir_revenue_threshold` | P221 | Art. 24a PIT | Limit PKPiR 2M EUR |

---

## 📦 Enterprise Expansion (P230-P265) 🟡

| Reguła | P | Podstawa prawna | Warunki |
|--------|---|-----------------|---------|
| `vat_tax_point_continuous_service` | 230 | Art. 19a ust. 3 | `is_continuous_service` |
| `vat_tax_point_advance_invoice` | 231 | Art. 19a ust. 8 | `invoice_type == ADVANCE` |
| `vat_tax_base_discount` | 232 | Art. 29a ust. 7 | `discount_amount > 0` |
| `vat_tax_base_returnable_packaging` | 233 | Art. 29a ust. 11-12 | Opakowania niezwrócone >60 dni |
| `pit_revenue_recognition_date` | 234 | Art. 14 ust. 1c PIT | Data dostawy < data faktury |
| `pit_free_benefits_taxable` | 235 | Art. 14 ust. 2 pkt 8 | Nieodpłatne świadczenia |
| `cit_advance_simplified` | 236 | Art. 25 ust. 6 CIT | Uproszczone zaliczki |
| `pit_advance_quarterly` | 237 | Art. 44 ust. 3g PIT | Kwartalne zaliczki |
| `cit_fx_differences_positive` | 238 | Art. 15a CIT | Dodatnie różnice kursowe |
| `cit_revenue_due_unpaid` | 239 | Art. 12 ust. 3 CIT | Przychód należny |
| `ord_vat_deadline` | 240 | Art. 103 VAT | Termin VAT: 25. dzień |
| `ord_cit_deadline` | 241 | Art. 25 CIT | Termin zaliczki CIT: 20. dzień |
| `ord_liability_enterprise_buyer` | 242 | Art. 112 Ordynacji | Odpowiedzialność nabywcy |
| `ord_wht_remitter_liability` | 243 | Art. 30 Ordynacji | Odpowiedzialność płatnika WHT |
| `uor_prudence_impairment` | 244 | Art. 7 ust. 1 UoR | Odpis aktualizujący >180 dni |
| `uor_going_concern_threat` | 245 | Art. 29 ust. 1 UoR | Wycena likwidacyjna |
| `uor_document_foreign_lang` | 246 | Art. 21 ust. 5 UoR | Tłumaczenie dokumentów |
| `uor_journal_entry_deadline` | 247 | Art. 24 ust. 5 UoR | Termin księgowania 15 dni |
| `uor_mandatory_audit` | 248 | Art. 64 UoR | Badanie sprawozdania |
| `uor_cash_flow_statement_obligation` | 249 | Art. 45 ust. 3 UoR | RPP obowiązkowy |
| `uor_retention_books` | 250 | Art. 74 ust. 2 UoR | Przechowywanie 5 lat |
| `uor_retention_payroll` | 251 | Ustawa o SUS+KP | Akta płacowe 10 lat |
| `coop_housing_cit_exemption` | 252 | Art. 17 ust. 1 pkt 44 | Spółdzielnia — zwolnienie CIT |
| `coop_statutory_fund_allocation` | 253 | Art. 78 Pr. spółdzielczego | Fundusz udziałowy |
| `energy_concession_trading` | 254 | Art. 32 PE | Koncesja URE |
| `energy_green_certificates` | 255 | Art. 9a PE | Świadectwa pochodzenia OZE |
| `transport_license_freight` | 256 | Art. 5 UTD | Licencja transportowa >3.5t |
| `transport_cabotage_limit` | 257 | Rozp. WE 1072/2009 | Limit kabotażu 3/7 dni |
| `ksef_consumer_invoice_exemption` | 258 | Art. 106ga VAT | B2C — zwolnienie KSeF |
| `ksef_offline_recovery` | 259 | Art. 106ne VAT | Tryb awaryjny KSeF |
| `jpk_kr_mandatory` | 260 | Art. 193a Ordynacji | JPK_KR przy kontroli |
| `jpk_v7_correction_reason` | 261 | Struktury JPK | Cel_Zlozenia=2 dla korekt |
| `vat_place_of_supply_b2b_services` | 262 | Art. 28b VAT | Miejsce świadczenia B2B |
| `vat_free_goods_sample` | 263 | Art. 7 ust. 3 VAT | Próbki handlowe |
| `local_tax_market_fee` | 264 | Art. 15 UPoL | Opłata targowa |
| `local_tax_dog_ownership` | 265 | Art. 18 UPoL | Opłata od psów |

---

## 📦 Specjalistyczne (P270-P290) 🟡

| Reguła | P | Podstawa prawna | Kluczowe |
|--------|---|-----------------|----------|
| `cit_kup_impairment_write_offs` | 270 | Art. 16 ust. 1 pkt 26a CIT | Odpisy bez uprawdopodobnienia → NKUP |
| `cit_kup_membership_fees` | 271 | Art. 16 ust. 1 pkt 37 CIT | Składki nieobowiązkowe → NKUP |
| `cit_kup_share_acquisition` | 272 | Art. 16 ust. 1 pkt 8 CIT | Nabycie udziałów → odroczone KUP |
| `cit_kup_execution_costs` | 273 | Art. 16 ust. 1 pkt 17 CIT | Koszty egzekucyjne → NKUP |
| `pit_kup_personal_expenses` | 274 | Art. 23 ust. 1 PIT | Wydatki osobiste → NKUP |
| `pit_kup_employee_insurance` | 275 | Art. 23 ust. 1 pkt 55a PIT | ZUS pracownika → NKUP pracodawcy |
| `vat_pre_pro_rata` | 276 | Art. 86 ust. 2a VAT | Pre-proporcja VAT |
| `vat_deduction_deadline` | 277 | Art. 86 ust. 11 VAT | Termin odliczenia 3 miesiące |
| `pcc_sale_agreement` | 278 | Art. 7 PCC | PCC 2% od umowy sprzedaży |
| `pcc_loan_agreement` | 279 | Art. 7 PCC | PCC 0.5% od pożyczki |
| `pcc_company_charter` | 280 | Art. 7 PCC | PCC 0.5% od kapitału zakładowego |
| `sd_registration_exemption` | 281 | Art. 4a ustawy o SD | SD-Z2, grupa zerowa |
| `fx_special_permit` | 282 | Prawo dewizowe | Zezwolenie NBP |
| `excise_tobacco_rate` | 283 | Ustawa akcyzowa | Tytoń → akcyza |
| `excise_tax_warehouse` | 284 | Ustawa akcyzowa | Skład podatkowy |
| `labor_jubilee_award` | 285 | Rozp. ZUS | Nagroda jubileuszowa — wolna ZUS |
| `labor_workwear_equivalent` | 286 | Art. 21 pkt 11 PIT | Ekwiwalent za odzież |
| `labor_business_trip_allowance` | 287 | Art. 21 pkt 16 PIT | Diety z delegacji |
| `ifrs2_share_based_payment` | 288 | MSSF 2 | ESOP — płatności akcjami |
| `uor_accounting_policy_change` | 289 | Art. 52 UoR | Zmiana polityki rachunkowości |
| `uor_fundamental_error_correction` | 290 | Art. 54 UoR | Korekta błędu podstawowego |

---

## 📦 Final Frontier (P295-P310) 🟡

| Reguła | P | Podstawa prawna | Kluczowe |
|--------|---|-----------------|----------|
| `vat_out_of_scope_enterprise_sale` | 295 | Art. 6 pkt 1 VAT | Zbycie przedsiębiorstwa |
| `vat_registration_eu_mandatory` | 296 | Art. 97 VAT | VAT-UE rejestracja |
| `pit_annual_return_deadline` | 297 | Art. 45 PIT | PIT do 30.04 |
| `cit_annual_return_deadline` | 298 | Art. 27 ust. 1 CIT | CIT-8 3 miesiące |
| `kks_voluntary_disclosure` | 299 | Art. 16 KKS | Czynny żal |
| `ord_overpayment_interest` | 300 | Art. 78 Ordynacji | Odsetki od nadpłaty |
| `vat_correction_in_minus_conditions` | 301 | Art. 29a ust. 13 VAT | Korekta in minus |
| `cit_tp_local_file_obligation` | 302 | Art. 11k CIT | Local File TP |
| `cit_tp_tpr_reporting` | 303 | Art. 11t CIT | TPR raportowanie |
| `pit_health_contrib_deduction_linear` | 304 | Art. 30c ust. 2 pkt 2 PIT | Odliczenie zdrowotnej |
| `vat_wnt_tax_point` | 305 | Art. 20 ust. 5 VAT | WNT — 15. dzień |
| `uor_post_balance_events_adjusting` | 306 | Art. 54 ust. 1 UoR | Zdarzenia po bilansie |
| `ksef_authorization_method` | 307 | Rozp. KSeF | Uwierzytelnienie KSeF |
| `whitelist_zaw_nr_exemption` | 308 | Art. 117ba § 3 Ordynacji | ZAW-NR wyjątek |
| `jpk_error_penalty_warning` | 309 | Art. 109 ust. 3f VAT | Kara 500 PLN za błąd JPK |
| `aml_institutional_risk_assessment` | 310 | Art. 33 AML | Ocena ryzyka AML |

---

## 📋 Cross-Reference: Podstawa Prawna → Reguła (62 wpisów)

| Podstawa prawna | Reguła | P |
|---|---|---|
| Art. 86 ust. 1 VAT | `fraud_graph_match` | P0 |
| Art. 55 KKS | `fraud_graph_match`, `duplicate_invoice_suspect` | P0, P8 |
| Art. 22 UoR | `counterparty_trust_low`, `anomaly_amount`, `new_counterparty_flag`, `fc_*` | P1-P3, P10-P19 |
| Art. 96b VAT | `whitelist_missing`, `nip_format_invalid` | P20, P9 |
| Art. 108a VAT | `split_payment_mandatory` | P25 |
| Art. 22p PIT / 15d CIT | `cash_transaction_over_limit` | P35 |
| Art. 17 ust. 1 pkt 3 VAT | `eu_reverse_charge` | P40 |
| Art. 28b VAT | `eu_import_services`, `vat_place_of_supply_b2b_services` | P41, P262 |
| Art. 42 VAT | `wdt_intracommunity_supply` | P42 |
| Art. 17 ust. 1 pkt 1 VAT | `import_non_eu` | P45 |
| Art. 41 ust. 4-11 VAT | `export_goods` | P48 |
| Art. 120 VAT | `vat_margin_scheme` | P50 |
| Art. 41 ust. 1 VAT | `vat_rate_fuel_pl`, `domestic_fallback` | P52, P100 |
| Art. 41 ust. 2a VAT | `vat_rate_food_pl`, `vat_rate_books_pl` | P53-P54 |
| Art. 43 VAT | `vat_exemption_education/healthcare/finance` | P55-P57 |
| Art. 113 ust. 1 VAT | `vat_exemption_subject` | P58 |
| Art. 89a VAT | `vat_bad_debt_relief` | P60 |
| § 10 JPK_VAT | `gtu_mapping_by_category` | P65 |
| Rozdział 6b CIT | `cit_estonian_effective` | P70 |
| Art. 19 ust. 1a CIT | `cit_small_taxpayer` | P71 |
| Art. 15c CIT | `cit_thin_capitalization` | P72 |
| Art. 23 ust. 1 pkt 23 PIT | `semantic_guard_disallowed` | P5 |
| Art. 26e PIT / 18d CIT | `relief_rd` | P80 |
| Art. 30ca PIT / 24d CIT | `relief_ip_box` | P82 |
| Art. 18c SUS | `zus_maly_plus` | P95 |
| MSSF 16 | `ifrs16_leasing_recognition` | P120 |
| Art. 16 ust. 1 pkt 28 CIT | `kup_representation_non_deductible` | P140 |
| Art. 72 AML | `aml_high_value_transaction` | P150 |
| Art. 192 KSH | `ksh_dividend_capability_check` | P170 |
| Art. 81b Ordynacji | `ord_correction_lock_during_audit` | P180 |
| Art. 86a VAT | `vat_input_deduction_vehicle_50pct` | P186 |
| Art. 90 VAT | `vat_input_deduction_pro_rata` | P185 |
| Art. 91 VAT | `vat_correction_annual` | P187 |
| Art. 6 UoR | `uor_matching_principle` | P205 |
| Art. 19a ust. 3 VAT | `vat_tax_point_continuous_service` | P230 |
| Art. 7 ust. 1 UoR | `uor_prudence_impairment` | P244 |
| Art. 64 UoR | `uor_mandatory_audit` | P248 |
| Art. 74 ust. 2 UoR | `uor_retention_books` | P250 |
| Art. 193a Ordynacji | `jpk_kr_mandatory` | P260 |
| Art. 7 PCC | `pcc_sale/loan/charter` | P278-P280 |
| Art. 11k CIT | `cit_tp_local_file_obligation` | P302 |
| Art. 16 KKS | `kks_voluntary_disclosure` | P299 |
| Art. 117ba § 3 Ordynacji | `whitelist_zaw_nr_exemption` | P308 |
| Art. 33 AML | `aml_institutional_risk_assessment` | P310 |
| Art. 6 pkt 1 VAT | `vat_out_of_scope_enterprise_sale` | P295 |
| Art. 97 VAT | `vat_registration_eu_mandatory` | P296 |
| Art. 45 PIT | `pit_annual_return_deadline` | P297 |
| Art. 22 ust. 1 UoR | `uor_double_entry_validation` | P320 |
| Art. 12 ust. 2 pkt 1 UoR | `uor_closing_books_mandatory` | P321 |
| Art. 31 ust. 1 UoR | `uor_provisions_recognition` | P322 |
| Art. 18f CIT | `cit_bad_debt_relief_creditor` | P323 |
| Art. 15, 96 VAT | `vat_registration_vat_r_mandatory` | P324 |
| Art. 33, 36 Ordynacji | `ord_tax_securing_deadline` | P325 |
| Art. 21 ust. 1 UoR | `uor_evidence_mandatory_fields` | P326 |
| Art. 35-44 UoR | `uor_financial_statement_structure` | P327 |
| Art. 229 KP | `labor_ohs_medical_exams_kup` | P328 |
| Art. 54, 67a-69 Ordynacji | `ord_payment_relief_deferral` | P329 |
| Art. 28 ust. 1-3 UoR | `uor_valuation_manufacturing_cost` | P330 |
| Art. 30 ust. 1 pkt 5a PIT | `pit_small_mandate_flat_rate` | P331 |
| Art. 52, 54 UoR | `uor_accounting_policy_change`, `uor_fundamental_error_correction` | P289-P290 |
| MSSF 2 | `ifrs2_share_based_payment` | P288 |

---

---

## 📦 Deep Docs Analysis — UoR, Ordynacja, CIT, VAT, PIT, KP (P320-P331) ✅ IMPLEMENTED

> **Źródło:** `21_DEEP_DOCS_ANALYSIS.md` — 12 absolutnie ostatnich luk zidentyfikowanych przez deep cross-reference Docs vs 228 istniejących reguł.

| P | Reguła | Pakiet | Podstawa prawna | Kluczowe warunki |
|---|--------|--------|-----------------|------------------|
| 320 | `uor_double_entry_validation` | `tax.accounting.uor.books` | Art. 22 ust. 1 UoR | `journal_entry` AND Wn≠Ma |
| 321 | `uor_closing_books_mandatory` | `tax.accounting.uor.books` | Art. 12 ust. 2 pkt 1 UoR | Data ≤ zamknięty rok + FS zatwierdzone |
| 322 | `uor_provisions_recognition` | `tax.accounting.uor.valuation` | Art. 31 ust. 1 UoR | `!uses_ifrs` + pewna/prawdopodobna strata |
| 323 | `cit_bad_debt_relief_creditor` | `tax.direct.cit.deductions` | Art. 18f CIT | `days_overdue > 90` + wykazany jako przychód |
| 324 | `vat_registration_vat_r_mandatory` | `tax.compliance.vat_registration` | Art. 15, 96 VAT | `vat_status == "unregistered"` + faktura taxable |
| 325 | `ord_tax_securing_deadline` | `tax.compliance.ordynacja` | Art. 33, 36 Ordynacji | Decyzja US + odwołanie bez wstrzymania |
| 326 | `uor_evidence_mandatory_fields` | `tax.accounting.uor.books` | Art. 21 ust. 1 UoR | Brak stron lub opisu operacji |
| 327 | `uor_financial_statement_structure` | `tax.accounting.uor.reports` | Art. 35-44 UoR + Zał. 1 | Klasyfikacja BS: non-current vs current |
| 328 | `labor_ohs_medical_exams_kup` | `tax.labor` | Art. 229 KP, Art. 15 CIT | Badania BHP/medycyna pracy → 100% KUP |
| 329 | `ord_payment_relief_deferral` | `tax.compliance.ordynacja` | Art. 54, 67a-69 Ordynacji | Aktywna decyzja o odroczeniu/ratach |
| 330 | `uor_valuation_manufacturing_cost` | `tax.accounting.uor.valuation` | Art. 28 ust. 1-3 UoR | Produkcja własna vs cena nabycia |
| 331 | `pit_small_mandate_flat_rate` | `tax.direct.pit.withholding` | Art. 30 ust. 1 pkt 5a PIT | Umowa zlecenia ≤200 PLN, nie pracownik |

### P320: `uor_double_entry_validation`
> **PRIORYTET 320** | Art. 22 ust. 1 UoR | `_routing: BLOCK_AND_ALERT`

```rego
sum_by_side(side) := sum([line.amount | line := input.document.lines[_]; line.side == side])

decide := {"matched": true, "rule_id": "tax.accounting.uor.double_entry_validation",
    "priority": 320, "_routing": "BLOCK_AND_ALERT",
    "_legal_basis": "Art. 22 ust. 1 UoR",
    "_warnings": ["Zapis księgowy niezbilansowany — naruszenie zasady podwójnego zapisu"]} {
    input.document.type == "journal_entry"
    abs(sum_by_side("debit") - sum_by_side("credit")) > 0.01
}
```

### P321: `uor_closing_books_mandatory`
> **PRIORYTET 321** | Art. 12 ust. 2 pkt 1 UoR | Zamknięcie ksiąg → BLOCK

### P322: `uor_provisions_recognition`
> **PRIORYTET 322** | Art. 31 ust. 1 UoR | Rezerwy wg polskiego GAAP (nie IAS 37)

### P323: `cit_bad_debt_relief_creditor`
> **PRIORYTET 323** | Art. 18f CIT | Ulga CIT na złe długi (wierzyciel)

### P324-P331: pozostałe
> Pełny pseudokod i opis: `Plan OPA/21_DEEP_DOCS_ANALYSIS.md`

---

## 🏗️ Status implementacji

| Status | Liczba reguł | Pakiety |
|--------|:-----------:|---------|
| ✅ **Zaimplementowane** (`policies/tax/`) | **69** | risk (5), routing (2), compliance (3), crossborder (4), vat/substantive (9), vat/gtu (1), direct/cit (5), direct/pit (7), allowances (10), accounting (5), zus (5), uor_books (3), uor_valuation (2), cit_deductions (1), vat_registration (1), ordynacja_extended (2), labor_extended (1), pit_withholding (1), uor_reports (1), fallback (2) |
| 🟡 **Pseudokod w dokumentach** | **171** | compliance extended (30), legal deep dive (27), enterprise exp (36), specialized (21), final frontier (16), risk/routing/vat remaining partial (41) |

---

> **Pełny pseudokod dla wszystkich 240 reguł:** patrz dokumenty źródłowe w `Plan OPA/` — `03_RULES_DETAILED.md`, `06_COMPLETE_RULES_SUPPLEMENT.md`, `07_ADVANCED_RULES_EXPANSION.md`, `09_LEGAL_DEEP_DIVE_RULES.md`, `11_ENTERPRISE_FINAL_EXPANSION.md`, `14_SPECIALIZED_TAX_RULES.md`, `16_FINAL_FRONTIER_RULES.md`, `21_DEEP_DOCS_ANALYSIS.md`
