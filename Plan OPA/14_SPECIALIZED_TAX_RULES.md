# Specjalistyczne Reguły Podatkowe — 21 nowych reguł (P270-P290)

> **Status:** Dokumentacja ENTERPRISE v5.0
> **Data:** 2026-07-07
> **Powiązany:** `11_ENTERPRISE_FINAL_EXPANSION.md`, `04_INDEX.md`
> **Uwaga:** 21 nowych reguł z 10 wyspecjalizowanych obszarów. Łącznie **212 reguł**.

> **⚠️ Rozszerzenia input:** Wszystkie nowe pola `input.*` użyte w tych regułach wymagają dodania do `01_INPUT_SPEC.md`. Nowe wartości `expense_type`: IMPAIRMENT, MEMBERSHIP_FEE, SHARE_ACQUISITION, EXECUTION_COST, ZUS_SOCIAL_EMPLOYEE_PART, DONATION_RECEIVED, SALE_AGREEMENT, LOAN_AGREEMENT, CAPITAL_INCREASE, SHARE_BASED_PAYMENT, JUBILEE_AWARD, WORKWEAR_EQUIVALENT, BUSINESS_TRIP_ALLOWANCE. Nowe pola: `is_personal_expense`, `is_documented_uncollectible`, `is_mandatory_membership`, `vat_pre_pro_rata_applicable`, `vat_pre_pro_rata_percent`, `months_since_issue`, `is_vat_deducted`, `vat_taxable`, `tax_group`, `months_since_acquisition`, `has_fx_permit`, `is_excise_good`, `years_since_last_award`, `amount_daily`, `accounting_event`.

---

## Nowe domeny

| # | Domena | Reguły | Priorytety |
|---|--------|:---:|------------|
| 1 | CIT — KUP wyłączenia szczegółowe (Art. 16) | 4 | P270-P273 |
| 2 | PIT — KUP wyłączenia szczegółowe (Art. 23) | 2 | P274-P275 |
| 3 | VAT — odliczenia zaawansowane (Art. 86-96) | 2 | P276-P277 |
| 4 | PCC — podatek od czynności cywilnoprawnych | 3 | P278-P280 |
| 5 | Podatek od spadków i darowizn | 1 | P281 |
| 6 | Prawo dewizowe — zezwolenia | 1 | P282 |
| 7 | Akcyza — wyroby tytoniowe, składy podatkowe | 2 | P283-P284 |
| 8 | Kodeks Pracy — nagrody, odzież, delegacje | 3 | P285-P287 |
| 9 | MSSF 2 — płatności w formie akcji | 1 | P288 |
| 10 | UoR — zmiany zasad, błędy podstawowe | 2 | P289-P290 |

---

## 1. CIT — KUP wyłączenia szczegółowe (P270-P273)

### P270: `cit_kup_impairment_write_offs`

**Cel biznesowy:** Odpisy aktualizujące wartość należności są NKUP, chyba że wierzytelność została uprawdopodobniona jako nieściągalna.

**Przesłanki:** `expense_type == "IMPAIRMENT"` AND `is_documented_uncollectible == false`

**Rezultat:** `income_tax_qualification: "non_deductible"`

**Podstawa prawna:** Art. 16 ust. 1 pkt 26a CIT

```rego
# P270: cit_kup_impairment_write_offs
decide = verdict {
    input.invoice.expense_type == "IMPAIRMENT"
    input.invoice.is_documented_uncollectible == false
    verdict := {"matched": true, "rule_id": "cit.kup.impairment",
        "package": "tax.direct.cit.kup", "priority": 270,
        "income_tax_qualification": "non_deductible",
        "_legal_basis": "Art. 16 ust. 1 pkt 26a CIT"}
}
```

### P271: `cit_kup_membership_fees`

**Cel biznesowy:** Składki na organizacje, do których przynależność nie jest obowiązkowa, są NKUP.

**Przesłanki:** `expense_type == "MEMBERSHIP_FEE"` AND `is_mandatory_membership == false`

**Rezultat:** `income_tax_qualification: "non_deductible"`

**Podstawa prawna:** Art. 16 ust. 1 pkt 37 CIT

```rego
# P271: cit_kup_membership_fees
decide = verdict {
    input.invoice.expense_type == "MEMBERSHIP_FEE"
    input.company.is_mandatory_membership == false
    verdict := {"matched": true, "rule_id": "cit.kup.membership",
        "package": "tax.direct.cit.kup", "priority": 271,
        "income_tax_qualification": "non_deductible",
        "_legal_basis": "Art. 16 ust. 1 pkt 37 CIT"}
}
```

### P272: `cit_kup_share_acquisition`

**Cel biznesowy:** Wydatki na nabycie udziałów/akcji są NKUP w momencie nabycia (rozpoznawane przy zbyciu).

**Przesłanki:** `expense_type == "SHARE_ACQUISITION"`

**Rezultat:** `income_tax_qualification: "deferred_deductible"`

**Podstawa prawna:** Art. 16 ust. 1 pkt 8 CIT

```rego
# P272: cit_kup_share_acquisition
decide = verdict {
    input.invoice.expense_type == "SHARE_ACQUISITION"
    verdict := {"matched": true, "rule_id": "cit.kup.shares",
        "package": "tax.direct.cit.kup", "priority": 272,
        "income_tax_qualification": "deferred_deductible",
        "_legal_basis": "Art. 16 ust. 1 pkt 8 CIT"}
}
```

### P273: `cit_kup_execution_costs`

**Cel biznesowy:** Koszty egzekucyjne związane z niewykonaniem zobowiązań to NKUP.

**Przesłanki:** `expense_type == "EXECUTION_COST"`

**Rezultat:** `income_tax_qualification: "non_deductible"`

**Podstawa prawna:** Art. 16 ust. 1 pkt 17 CIT

```rego
# P273: cit_kup_execution_costs
decide = verdict {
    input.invoice.expense_type == "EXECUTION_COST"
    verdict := {"matched": true, "rule_id": "cit.kup.execution",
        "package": "tax.direct.cit.kup", "priority": 273,
        "income_tax_qualification": "non_deductible",
        "_legal_basis": "Art. 16 ust. 1 pkt 17 CIT"}
}
```

---

## 2. PIT — KUP wyłączenia szczegółowe (P274-P275)

### P274: `pit_kup_personal_expenses`

**Cel biznesowy:** Wyłączenie z KUP wydatków na osobiste potrzeby przedsiębiorcy i rodziny.

**Przesłanki:** `is_personal_expense == true`

**Rezultat:** `income_tax_qualification: "non_deductible"`, `_routing: "BLOCK_AND_ALERT"`

**Podstawa prawna:** Art. 23 ust. 1 PIT

```rego
# P274: pit_kup_personal_expenses
decide = verdict {
    input.invoice.is_personal_expense == true
    verdict := {"matched": true, "rule_id": "pit.kup.personal",
        "package": "tax.direct.pit.kup", "priority": 274,
        "income_tax_qualification": "non_deductible",
        "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Art. 23 ust. 1 PIT"}
}
```

### P275: `pit_kup_employee_insurance`

**Cel biznesowy:** Składki ZUS w części finansowanej przez pracownika są NKUP pracodawcy.

**Przesłanki:** `expense_type == "ZUS_SOCIAL_EMPLOYEE_PART"`

**Rezultat:** `income_tax_qualification: "non_deductible"`

**Podstawa prawna:** Art. 23 ust. 1 pkt 55a PIT

```rego
# P275: pit_kup_employee_insurance
decide = verdict {
    input.invoice.expense_type == "ZUS_SOCIAL_EMPLOYEE_PART"
    verdict := {"matched": true, "rule_id": "pit.kup.employee_zus",
        "package": "tax.direct.pit.kup", "priority": 275,
        "income_tax_qualification": "non_deductible",
        "_legal_basis": "Art. 23 ust. 1 pkt 55a PIT"}
}
```

---

## 3. VAT — odliczenia zaawansowane (P276-P277)

### P276: `vat_pre_pro_rata`

**Cel biznesowy:** Pre-proporcja VAT dla jednostek wykonujących działalność gospodarczą i niegospodarczą (samorządy, uczelnie).

**Przesłanki:** `vat_pre_pro_rata_applicable == true`

**Rezultat:** `vat_deductible_percent` = pre-proporcja z thresholds

**Podstawa prawna:** Art. 86 ust. 2a VAT

```rego
# P276: vat_pre_pro_rata
decide = verdict {
    input.company.vat_pre_pro_rata_applicable == true
    verdict := {"matched": true, "rule_id": "vat.deductions.pre_pro_rata",
        "package": "tax.vat.deductions", "priority": 276,
        "vat_deductible_percent": input.company.vat_pre_pro_rata_percent,
        "_legal_basis": "Art. 86 ust. 2a VAT"}
}
```

### P277: `vat_deduction_deadline`

**Cel biznesowy:** Termin odliczenia VAT — 3 kolejne miesiące od powstania obowiązku (lub korekta).

**Przesłanki:** `months_since_issue > 3` AND `is_vat_deducted == false`

**Rezultat:** `vat_period_correction_required: true`

**Podstawa prawna:** Art. 86 ust. 11 VAT

```rego
# P277: vat_deduction_deadline
decide = verdict {
    input.invoice.months_since_issue > 3
    input.invoice.is_vat_deducted == false
    verdict := {"matched": true, "rule_id": "vat.deductions.deadline",
        "package": "tax.vat.deductions", "priority": 277,
        "vat_period_correction_required": true,
        "_legal_basis": "Art. 86 ust. 11 VAT"}
}
```

---

## 4. PCC — podatek od czynności cywilnoprawnych (P278-P280)

### P278: `pcc_sale_agreement`

**Cel biznesowy:** PCC 2% od umowy sprzedaży rzeczy ruchomych nieobjętych VAT (np. auto od osoby prywatnej).

**Przesłanki:** `expense_type == "SALE_AGREEMENT"` AND `vat_taxable == false`

**Rezultat:** `pcc_applicable: true`, `pcc_rate: "0.02"`

**Podstawa prawna:** Art. 7 ust. 1 pkt 1 ustawy o PCC

```rego
# P278: pcc_sale_agreement
decide = verdict {
    input.invoice.expense_type == "SALE_AGREEMENT"
    input.invoice.vat_taxable == false
    verdict := {"matched": true, "rule_id": "pcc.sale",
        "package": "tax.compliance.pcc", "priority": 278,
        "pcc_applicable": true, "pcc_rate": "0.02",
        "_legal_basis": "Art. 7 ust. 1 pkt 1 PCC"}
}
```

### P279: `pcc_loan_agreement`

**Cel biznesowy:** PCC 0,5% od umowy pożyczki od podmiotu nieobjętego VAT.

**Przesłanki:** `expense_type == "LOAN_AGREEMENT"`

**Rezultat:** `pcc_applicable: true`, `pcc_rate: "0.005"`

**Podstawa prawna:** Art. 7 ust. 1 pkt 4 ustawy o PCC

```rego
# P279: pcc_loan_agreement
decide = verdict {
    input.invoice.expense_type == "LOAN_AGREEMENT"
    verdict := {"matched": true, "rule_id": "pcc.loan",
        "package": "tax.compliance.pcc", "priority": 279,
        "pcc_applicable": true, "pcc_rate": "0.005",
        "_legal_basis": "Art. 7 ust. 1 pkt 4 PCC"}
}
```

### P280: `pcc_company_charter`

**Cel biznesowy:** PCC 0,5% przy wniesieniu lub podwyższeniu kapitału zakładowego spółki.

**Przesłanki:** `expense_type == "CAPITAL_INCREASE"`

**Rezultat:** `pcc_applicable: true`, `pcc_rate: "0.005"`

**Podstawa prawna:** Art. 7 ust. 1 pkt 9 ustawy o PCC

```rego
# P280: pcc_company_charter
decide = verdict {
    input.invoice.expense_type == "CAPITAL_INCREASE"
    verdict := {"matched": true, "rule_id": "pcc.company_charter",
        "package": "tax.compliance.pcc", "priority": 280,
        "pcc_applicable": true, "pcc_rate": "0.005",
        "_legal_basis": "Art. 7 ust. 1 pkt 9 PCC"}
}
```

---

## 5. Podatek od spadków i darowizn (P281)

### P281: `sd_registration_exemption`

**Cel biznesowy:** Zwolnienie z podatku od spadków i darowizn dla grupy zerowej przy zgłoszeniu SD-Z2 w ciągu 6 miesięcy.

**Przesłanki:** `expense_type == "DONATION_RECEIVED"` AND `tax_group == 0` AND `months_since_acquisition <= 6`

**Rezultat:** `sd_tax_rate: "0.00"`, `sd_z2_required: true`

**Podstawa prawna:** Art. 4a ustawy o podatku od spadków i darowizn (zwolnienie dla najbliższej rodziny — tzw. "grupa zerowa")

```rego
# P281: sd_registration_exemption
decide = verdict {
    input.invoice.expense_type == "DONATION_RECEIVED"
    input.company.tax_group == 0
    input.invoice.months_since_acquisition <= 6
    verdict := {"matched": true, "rule_id": "sd.exemption_z2",
        "package": "tax.compliance.sd", "priority": 281,
        "sd_tax_rate": "0.00", "sd_z2_required": true,
        "_legal_basis": "Art. 4a ustawy o podatku od SD"}
}
```

---

## 6. Prawo dewizowe (P282)

### P282: `fx_special_permit`

**Cel biznesowy:** Blokada transakcji dewizowej z krajami objętymi restrykcjami bez zezwolenia NBP.

**Przesłanki:** `currency != "PLN"` AND `vendor.country == "RESTRICTED_FX"` AND `has_fx_permit == false`

**Rezultat:** `_routing: "BLOCK_AND_ALERT"`

**Podstawa prawna:** Prawo dewizowe (ograniczenia dewizowe)

```rego
# P282: fx_special_permit
decide = verdict {
    input.invoice.currency != "PLN"
    input.vendor.country == "RESTRICTED_FX"
    input.company.has_fx_permit == false
    verdict := {"matched": true, "rule_id": "fx.restricted_permit",
        "package": "tax.compliance.fx", "priority": 282,
        "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Prawo dewizowe"}
}
```

---

## 7. Akcyza szczegółowa (P283-P284)

### P283: `excise_tobacco_rate`

**Cel biznesowy:** Identyfikacja obowiązku akcyzowego dla wyrobów tytoniowych.

**Przesłanki:** `category_code == "TOBACCO"`

**Rezultat:** `excise_applicable: true`, `excise_type: "TOBACCO"`

**Podstawa prawna:** Ustawa o podatku akcyzowym, zał. 1

```rego
# P283: excise_tobacco_rate
decide = verdict {
    input.invoice.category_code == "TOBACCO"
    verdict := {"matched": true, "rule_id": "excise.tobacco",
        "package": "tax.compliance.excise", "priority": 283,
        "excise_applicable": true, "excise_type": "TOBACCO",
        "_legal_basis": "Ustawa o podatku akcyzowym"}
}
```

### P284: `excise_tax_warehouse`

**Cel biznesowy:** Brak akcyzy dla towarów w procedurze zawieszenia poboru w składzie podatkowym.

**Przesłanki:** `is_excise_good == true` AND `procedure == "TAX_WAREHOUSE_SUSPENSION"`

**Rezultat:** `excise_suspended: true`

**Podstawa prawna:** Procedura zawieszenia poboru akcyzy

```rego
# P284: excise_tax_warehouse
decide = verdict {
    input.invoice.is_excise_good == true
    input.invoice.procedure == "TAX_WAREHOUSE_SUSPENSION"
    verdict := {"matched": true, "rule_id": "excise.suspension",
        "package": "tax.compliance.excise", "priority": 284,
        "excise_suspended": true,
        "_legal_basis": "Ustawa o podatku akcyzowym - zawieszenie"}
}
```

---

## 8. Kodeks Pracy szczegółowy (P285-P287)

### P285: `labor_jubilee_award`

**Cel biznesowy:** Zwolnienie nagrody jubileuszowej z ZUS (nagroda nie częściej niż co 5 lat).

**Przesłanki:** `expense_type == "JUBILEE_AWARD"` AND `years_since_last_award >= 5`

**Rezultat:** `zus_base_included: false`, `income_tax_qualification: "deductible_full"`

**Podstawa prawna:** Rozp. ZUS par. 2 ust. 1

```rego
# P285: labor_jubilee_award
decide = verdict {
    input.invoice.expense_type == "JUBILEE_AWARD"
    input.invoice.years_since_last_award >= 5
    verdict := {"matched": true, "rule_id": "labor.jubilee_award",
        "package": "tax.labor", "priority": 285,
        "zus_base_included": false,
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "Rozp. w sprawie składek ZUS"}
}
```

### P286: `labor_workwear_equivalent`

**Cel biznesowy:** Ekwiwalent za odzież roboczą — wolny od PIT i ZUS.

**Przesłanki:** `expense_type == "WORKWEAR_EQUIVALENT"`

**Rezultat:** `pit_base_included: false`, `zus_base_included: false`

**Podstawa prawna:** Art. 21 ust. 1 pkt 11 PIT, KP art. 237(9)

```rego
# P286: labor_workwear_equivalent
decide = verdict {
    input.invoice.expense_type == "WORKWEAR_EQUIVALENT"
    verdict := {"matched": true, "rule_id": "labor.workwear",
        "package": "tax.labor", "priority": 286,
        "pit_base_included": false, "zus_base_included": false,
        "_legal_basis": "Art. 21 pkt 11 PIT"}
}
```

### P287: `labor_business_trip_allowance`

**Cel biznesowy:** Diety z delegacji służbowych — wolne od PIT i ZUS do limitu.

**Przesłanki:** `expense_type == "BUSINESS_TRIP_ALLOWANCE"` AND `amount_daily <= input.thresholds.bounds.per_diem_limit`

**Rezultat:** `pit_base_included: false`, `zus_base_included: false`

**Podstawa prawna:** Art. 21 ust. 1 pkt 16 PIT

```rego
# P287: labor_business_trip_allowance
decide = verdict {
    input.invoice.expense_type == "BUSINESS_TRIP_ALLOWANCE"
    input.invoice.amount_daily <= input.thresholds.bounds.per_diem_limit
    verdict := {"matched": true, "rule_id": "labor.business_trip",
        "package": "tax.labor", "priority": 287,
        "pit_base_included": false, "zus_base_included": false,
        "_legal_basis": "Art. 21 pkt 16 PIT"}
}
```

---

## 9. MSSF 2 — płatności w formie akcji (P288)

### P288: `ifrs2_share_based_payment`

**Cel biznesowy:** Rozpoznanie kosztu płatności opartych na akcjach (ESOP) w wartości godziwej na dzień przyznania.

**Przesłanki:** `uses_ifrs == true` AND `expense_type == "SHARE_BASED_PAYMENT"`

**Rezultat:** `ifrs2_applicable: true`, `valuation_method: "FAIR_VALUE_GRANT_DATE"`

**Podstawa prawna:** MSSF 2

```rego
# P288: ifrs2_share_based_payment
decide = verdict {
    input.company.uses_ifrs == true
    input.invoice.expense_type == "SHARE_BASED_PAYMENT"
    verdict := {"matched": true, "rule_id": "ifrs2.share_payments",
        "package": "tax.accounting.ifrs", "priority": 288,
        "ifrs2_applicable": true,
        "valuation_method": "FAIR_VALUE_GRANT_DATE",
        "_legal_basis": "MSSF 2"}
}
```

---

## 10. UoR — zmiany zasad, błędy podstawowe (P289-P290)

### P289: `uor_accounting_policy_change`

**Cel biznesowy:** Retrospektywne ujęcie skutków zmiany polityki rachunkowości.

**Przesłanki:** `accounting_event == "POLICY_CHANGE"`

**Rezultat:** `retrospective_adjustment: true`, `equity_adjustment_required: true`

**Podstawa prawna:** Art. 52 UoR (i MSR 8)

```rego
# P289: uor_accounting_policy_change
decide = verdict {
    input.invoice.accounting_event == "POLICY_CHANGE"
    verdict := {"matched": true, "rule_id": "uor.policy_change",
        "package": "tax.accounting.uor", "priority": 289,
        "retrospective_adjustment": true,
        "equity_adjustment_required": true,
        "_legal_basis": "Art. 52 UoR"}
}
```

### P290: `uor_fundamental_error_correction`

**Cel biznesowy:** Korekta błędu podstawowego z lat ubiegłych — ujmowana w kapitale własnym, nie w bieżącym RZiS.

**Przesłanki:** `accounting_event == "FUNDAMENTAL_ERROR_CORRECTION"`

**Rezultat:** `route_to_retained_earnings: true`, `pnl_impact: false`

**Podstawa prawna:** Art. 54 UoR

```rego
# P290: uor_fundamental_error_correction
decide = verdict {
    input.invoice.accounting_event == "FUNDAMENTAL_ERROR_CORRECTION"
    verdict := {"matched": true, "rule_id": "uor.fundamental_error",
        "package": "tax.accounting.uor", "priority": 290,
        "route_to_retained_earnings": true, "pnl_impact": false,
        "_legal_basis": "Art. 54 UoR"}
}
```

---

## Podsumowanie

| Domena | Nowe reguły | Priorytety |
|--------|:-----------:|------------|
| CIT KUP wyłączenia | 4 | P270-P273 |
| PIT KUP wyłączenia | 2 | P274-P275 |
| VAT odliczenia zaawansowane | 2 | P276-P277 |
| PCC | 3 | P278-P280 |
| Podatek od SD | 1 | P281 |
| Prawo dewizowe | 1 | P282 |
| Akcyza szczegółowa | 2 | P283-P284 |
| Kodeks Pracy | 3 | P285-P287 |
| MSSF 2 | 1 | P288 |
| UoR zmiany/błędy | 2 | P289-P290 |
| **RAZEM** | **21** | **P270-P290** |

**Całkowite pokrycie: 191 + 21 = 212 reguł w 40+ domenach prawnych.**

---

> **Następny krok:** `15_SERVICE_INTEGRATION_MAP.md` — mapa istniejących serwisów NexusAI do reguł OPA.
