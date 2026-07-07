# 🌳 Reguły Głębokiej Analizy Prawnej — 10 dodatkowych obszarów (P185-P230)

> **Status:** Dokumentacja ENTERPRISE v4.0  
> **Data:** 2026-07-07  
> **Powiązany:** `07_ADVANCED_RULES_EXPANSION.md`, `08_OPA_PATTERNS_FROM_RESEARCH.md`
> **Uwaga:** 27 nowych reguł z pozostałych niepokrytych obszarów. Łącznie **155 reguł**.

---

## Nowe domeny w tym dokumencie

| # | Domena | Liczba reguł | Priorytety |
|---|--------|:-----------:|------------|
| 1 | VAT — odliczenia szczegółowe (Art. 86-96) | 3 | P185-P187 |
| 2 | VAT — korekty i terminy (Art. 89a-91) | 2 | P188-P189 |
| 3 | Podatki lokalne (nieruchomości, transport) | 2 | P190-P191 |
| 4 | Prawo pracy — urlopy, odprawy, ekwiwalenty | 3 | P192-P194 |
| 5 | Ustawa zasiłkowa — chorobowe, macierzyńskie | 2 | P195-P196 |
| 6 | Prawo budowlane — ulga materiałowa | 1 | P197 |
| 7 | Ochrona środowiska — BDO, emisje CO2 | 2 | P198-P199 |
| 8 | NGO — fundacje, stowarzyszenia | 2 | P200-P201 |
| 9 | UoR — zasady, sprawozdania, inwentaryzacja | 4 | P205-P208 |
| 10 | Ordynacja dodatkowa — interpretacje, odpowiedzialność | 2 | P210-P211 |
| 11 | MSSF dodatkowe — MSSF 9, MSSF 15, MSSF 2 | 2 | P215-P216 |
| 12 | Uproszczona ewidencja — PKPiR | 2 | P220-P221 |

---

# CZĘŚĆ I: VAT — ODLICZENIA SZCZEGÓŁOWE (P185-P187)

---

### P185: `vat_input_deduction_pro_rata`

**Cel biznesowy:** Odliczenie VAT proporcjonalne — gdy firma wykonuje czynności opodatkowane i zwolnione.

**Przesłanki:** `input.company.vat_pro_rata` < 1.0 (mieszana działalność)

**Rezultat:** `vat_deductible_percent`: wskaźnik proporcji z thresholds

**Podstawa prawna:** Art. 90 VAT

**Pseudokod Rego:**
```rego
# ── P185: vat_input_deduction_pro_rata ────────────────────────
decide = verdict {
    input.company.vat_pro_rata < 1.0
    verdict := {
        "matched": true, "rule_id": "tax.vat.pro_rata_deduction",
        "package": "tax.vat", "priority": 185,
        "vat_deductible_percent": input.company.vat_pro_rata * 100,
        "_legal_basis": "Art. 90 ustawy o VAT"
    }
}
```

---

### P186: `vat_input_deduction_vehicle_50pct`

**Cel biznesowy:** Ograniczenie odliczenia VAT do 50% dla pojazdów wykorzystywanych mieszanie.

**Przesłanki:** `input.invoice.category_code` == `"CAR"` AND `input.invoice.vehicle_usage` == `"MIXED"`

**Rezultat:** `vat_deductible_percent: 50`

**Podstawa prawna:** Art. 86a VAT

**Pseudokod Rego:**
```rego
# ── P186: vat_input_deduction_vehicle_50pct ───────────────────
decide = verdict {
    input.invoice.category_code == "CAR"
    input.invoice.vehicle_usage == "MIXED"
    verdict := {
        "matched": true, "rule_id": "tax.vat.vehicle_50pct_deduction",
        "package": "tax.vat", "priority": 186,
        "vat_deductible_percent": 50,
        "_legal_basis": "Art. 86a ustawy o VAT"
    }
}
```

---

### P187: `vat_correction_annual`

**Cel biznesowy:** Roczne korekty VAT dla środków trwałych (korekta 5-letnia / 10-letnia).

**Przesłanki:** `input.invoice.expense_type` == `"FIXED_ASSET"` AND `input.invoice.vat_correction_year` <= 5

**Rezultat:** `vat_annual_correction_required: true`, `vat_correction_period`: 5 lub 10 lat

**Podstawa prawna:** Art. 91 VAT

**Pseudokod Rego:**
```rego
# ── P187: vat_correction_annual ───────────────────────────────
correction_period = 5 { input.invoice.amount_net <= 15000 }
else = 10 { input.invoice.amount_net > 15000 }

decide = verdict {
    input.invoice.expense_type == "FIXED_ASSET"
    input.invoice.vat_correction_year <= correction_period
    verdict := {
        "matched": true, "rule_id": "tax.vat.annual_correction",
        "package": "tax.vat", "priority": 187,
        "vat_correction_period": correction_period,
        "_legal_basis": "Art. 91 ustawy o VAT"
    }
}
```

---

# CZĘŚĆ II: PODATKI LOKALNE (P190-P191)

---

### P190: `property_tax_obligation`

**Cel biznesowy:** Identyfikacja obowiązku podatku od nieruchomości.

**Przesłanki:** `input.invoice.expense_type` in `["PROPERTY", "REAL_ESTATE"]` AND `input.company.owns_property` == `true`

**Rezultat:** `property_tax_applicable: true`, stawka z thresholds gminnych

**Podstawa prawna:** Ustawa o podatkach i opłatach lokalnych

**Pseudokod Rego:**
```rego
# ── P190: property_tax_obligation ──────────────────────────────
decide = verdict {
    input.invoice.expense_type in ["PROPERTY", "REAL_ESTATE"]
    input.company.owns_property == true
    verdict := {
        "matched": true, "rule_id": "tax.local.property_tax",
        "package": "tax.local", "priority": 190,
        "property_tax_applicable": true,
        "_legal_basis": "Ustawa o podatkach i opłatach lokalnych"
    }
}
```

---

### P191: `transport_tax_obligation`

**Cel biznesowy:** Obowiązek podatku od środków transportowych dla pojazdów >3.5t.

**Przesłanki:** `input.invoice.category_code` == `"VEHICLE"` AND `input.invoice.vehicle_weight_kg` > 3500

**Rezultat:** `transport_tax_applicable: true`

**Podstawa prawna:** Ustawa o podatkach i opłatach lokalnych

**Pseudokod Rego:**
```rego
# ── P191: transport_tax_obligation ─────────────────────────────
decide = verdict {
    input.invoice.category_code == "VEHICLE"
    input.invoice.vehicle_weight_kg > 3500
    verdict := {
        "matched": true, "rule_id": "tax.local.transport_tax",
        "package": "tax.local", "priority": 191,
        "transport_tax_applicable": true,
        "_legal_basis": "Ustawa o podatkach i opłatach lokalnych"
    }
}
```

---

# CZĘŚĆ III: PRAWO PRACY (P192-P194)

---

### P192: `labor_holiday_equivalent`

**Cel biznesowy:** Ekwiwalent za niewykorzystany urlop — KUP pracodawcy.

**Przesłanki:** `input.invoice.expense_type` == `"HOLIDAY_EQUIVALENT"`

**Rezultat:** `income_tax_qualification: "deductible_full"`, `zus_base_included: true`

**Podstawa prawna:** Art. 171 Kodeksu Pracy, Art. 15 CIT / Art. 22 PIT

**Pseudokod Rego:**
```rego
# ── P192: labor_holiday_equivalent ─────────────────────────────
decide = verdict {
    input.invoice.expense_type == "HOLIDAY_EQUIVALENT"
    verdict := {
        "matched": true, "rule_id": "labor.holiday_equivalent",
        "package": "labor", "priority": 192,
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "Art. 171 KP, Art. 15 CIT"
    }
}
```

---

### P193: `labor_severance_pay`

**Cel biznesowy:** Odprawa emerytalno-rentowa / zwolnienia grupowe — KUP.

**Przesłanki:** `input.invoice.expense_type` in `["SEVERANCE", "REDUNDANCY"]`

**Rezultat:** `income_tax_qualification: "deductible_full"`, `severance_type_identified: true`

**Podstawa prawna:** Art. 92 KP, ustawa o zwolnieniach grupowych

**Pseudokod Rego:**
```rego
# ── P193: labor_severance_pay ──────────────────────────────────
decide = verdict {
    input.invoice.expense_type in ["SEVERANCE", "REDUNDANCY"]
    verdict := {
        "matched": true, "rule_id": "labor.severance_pay",
        "package": "labor", "priority": 193,
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "Art. 92 KP, ustawa o zwolnieniach grupowych"
    }
}
```

---

### P194: `labor_minimum_wage_compliance`

**Cel biznesowy:** Weryfikacja czy wynagrodzenie >= minimalne krajowe.

**Przesłanki:** `input.invoice.expense_type` == `"SALARY"` AND `input.invoice.amount_net` < `input.thresholds.bounds.minimum_wage`

**Rezultat:** `minimum_wage_violation: true`, `_routing: "BLOCK_AND_ALERT"`

**Podstawa prawna:** Ustawa o minimalnym wynagrodzeniu

**Pseudokod Rego:**
```rego
# ── P194: labor_minimum_wage_compliance ────────────────────────
decide = verdict {
    input.invoice.expense_type == "SALARY"
    input.invoice.amount_net < input.thresholds.bounds.minimum_wage
    verdict := {
        "matched": true, "rule_id": "labor.minimum_wage",
        "package": "labor", "priority": 194,
        "minimum_wage_violation": true,
        "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Ustawa o minimalnym wynagrodzeniu"
    }
}
```

---

# CZĘŚĆ IV: USTAWA ZASIŁKOWA (P195-P196)

---

### P195: `sick_leave_benefit`

**Cel biznesowy:** Identyfikacja zasiłku chorobowego płatnego przez ZUS/pracodawcę.

**Przesłanki:** `input.invoice.expense_type` == `"SICK_LEAVE"`

**Rezultat:** `sick_leave_days` > 33 → płatne przez ZUS; <= 33 → płatne przez pracodawcę

**Podstawa prawna:** Art. 4 ustawy zasiłkowej

**Pseudokod Rego:**
```rego
# ── P195: sick_leave_benefit ───────────────────────────────────
sick_payer = "ZUS" { input.invoice.sick_leave_days > 33 }
else = "EMPLOYER" { input.invoice.sick_leave_days <= 33 }

decide = verdict {
    input.invoice.expense_type == "SICK_LEAVE"
    verdict := {
        "matched": true, "rule_id": "labor.sick_leave_benefit",
        "package": "labor", "priority": 195,
        "sick_leave_payer": sick_payer,
        "_legal_basis": "Art. 4 ustawy zasiłkowej"
    }
}
```

---

### P196: `maternity_benefit`

**Cel biznesowy:** Identyfikacja zasiłku macierzyńskiego — 100% / 80% podstawy.

**Przesłanki:** `input.invoice.expense_type` == `"MATERNITY"`

**Rezultat:** `maternity_rate: "1.00"` (100%) lub `"0.80"` (80%)

**Podstawa prawna:** Art. 29-31 ustawy zasiłkowej

**Pseudokod Rego:**
```rego
# ── P196: maternity_benefit ────────────────────────────────────
maternity_rate = "1.00" { input.invoice.maternity_option == "FULL" }
else = "0.80" { input.invoice.maternity_option == "EXTENDED" }

decide = verdict {
    input.invoice.expense_type == "MATERNITY"
    verdict := {
        "matched": true, "rule_id": "labor.maternity_benefit",
        "package": "labor", "priority": 196,
        "maternity_rate": maternity_rate,
        "_legal_basis": "Art. 29-31 ustawy zasiłkowej"
    }
}
```

---

# CZĘŚĆ V: PRAWO BUDOWLANE + OCHRONA ŚRODOWISKA (P197-P199)

---

### P197: `construction_material_vat_refund`

**Cel biznesowy:** Zwrot VAT za materiały budowlane dla osób fizycznych.

**Przesłanki:** `input.invoice.expense_type` == `"CONSTRUCTION_MATERIALS"` AND `input.company.tax_form` == `"PIT_SCALE"`

**Rezultat:** `vat_refund_eligible: true`, limit wg thresholds

**Podstawa prawna:** Ustawa o zwrocie VAT za materiały budowlane (Dz.U. 2005)

**Pseudokod Rego:**
```rego
# ── P197: construction_material_vat_refund ─────────────────────
decide = verdict {
    input.invoice.expense_type == "CONSTRUCTION_MATERIALS"
    input.company.tax_form == "PIT_SCALE"
    verdict := {
        "matched": true, "rule_id": "allowances.construction_vat_refund",
        "package": "allowances", "priority": 197,
        "vat_refund_eligible": true,
        "_legal_basis": "Ustawa o zwrocie VAT za materiały budowlane"
    }
}
```

---

### P198: `bdo_waste_record_obligation`

**Cel biznesowy:** Obowiązek ewidencji BDO (Baza Danych Odpadowych).

**Przesłanki:** `input.company.generates_waste` == `true`

**Rezultat:** `bdo_record_required: true`, `bdo_waste_code_required: true`

**Podstawa prawna:** Ustawa o odpadach, ustawa o BDO

**Pseudokod Rego:**
```rego
# ── P198: bdo_waste_record_obligation ──────────────────────────
decide = verdict {
    input.company.generates_waste == true
    verdict := {
        "matched": true, "rule_id": "environmental.bdo_record",
        "package": "environmental", "priority": 198,
        "bdo_record_required": true,
        "_legal_basis": "Ustawa o odpadach, ustawa o BDO"
    }
}
```

---

### P199: `co2_emission_fee`

**Cel biznesowy:** Opłata za emisję CO2 dla instalacji przemysłowych.

**Przesłanki:** `input.company.is_co2_emitter` == `true`

**Rezultat:** `co2_fee_applicable: true`, stawka z thresholds

**Podstawa prawna:** Prawo ochrony środowiska, EU ETS

**Pseudokod Rego:**
```rego
# ── P199: co2_emission_fee ─────────────────────────────────────
decide = verdict {
    input.company.is_co2_emitter == true
    verdict := {
        "matched": true, "rule_id": "environmental.co2_fee",
        "package": "environmental", "priority": 199,
        "co2_fee_applicable": true,
        "_legal_basis": "Prawo ochrony środowiska, EU ETS"
    }
}
```

---

# CZĘŚĆ VI: NGO — FUNDACJE I STOWARZYSZENIA (P200-P201)

---

### P200: `ngo_tax_exemption_check`

**Cel biznesowy:** Zwolnienie podatkowe dla NGO prowadzących działalność statutową.

**Przesłanki:** `input.company.legal_form` in `["FOUNDATION", "ASSOCIATION"]` AND `input.invoice.is_statutory_activity` == `true`

**Rezultat:** `tax_exemption: "NGO_STATUTORY"`, `cit_rate: "0.00"`

**Podstawa prawna:** Art. 17 CIT, ustawa o fundacjach

**Pseudokod Rego:**
```rego
# ── P200: ngo_tax_exemption_check ──────────────────────────────
decide = verdict {
    input.company.legal_form in ["FOUNDATION", "ASSOCIATION"]
    input.invoice.is_statutory_activity == true
    verdict := {
        "matched": true, "rule_id": "compliance.ngo.tax_exemption",
        "package": "compliance.ngo", "priority": 200,
        "tax_exemption": "NGO_STATUTORY",
        "cit_rate": input.thresholds.rates.vat_zero,
        "_legal_basis": "Art. 17 CIT, ustawa o fundacjach"
    }
}
```

---

### P201: `ngo_business_activity_taxable`

**Cel biznesowy:** Działalność gospodarcza NGO podlega opodatkowaniu CIT.

**Przesłanki:** `input.company.legal_form` in `["FOUNDATION", "ASSOCIATION"]` AND `input.invoice.is_statutory_activity` == `false`

**Rezultat:** `cit_rate: input.thresholds.rates.cit_standard`

**Podstawa prawna:** Art. 17 ust. 1a CIT

**Pseudokod Rego:**
```rego
# ── P201: ngo_business_activity_taxable ────────────────────────
decide = verdict {
    input.company.legal_form in ["FOUNDATION", "ASSOCIATION"]
    input.invoice.is_statutory_activity == false
    verdict := {
        "matched": true, "rule_id": "compliance.ngo.business_taxable",
        "package": "compliance.ngo", "priority": 201,
        "cit_rate": input.thresholds.rates.cit_standard,
        "_legal_basis": "Art. 17 ust. 1a CIT"
    }
}
```

---

# CZĘŚĆ VII: UoR — ZASADY I SPRAWOZDANIA (P205-P208)

---

### P205: `uor_matching_principle`

**Cel biznesowy:** Zasada współmierności — koszty w okresie, którego dotyczą.

**Przesłanki:** `input.invoice.cost_period` != `input.invoice.invoice_period`

**Rezultat:** `rmk_required: true` (rozliczenie międzyokresowe)

**Podstawa prawna:** Art. 6 UoR (zasada współmierności)

**Pseudokod Rego:**
```rego
# ── P205: uor_matching_principle ───────────────────────────────
decide = verdict {
    input.invoice.cost_period != input.invoice.invoice_period
    verdict := {
        "matched": true, "rule_id": "accounting.uor.matching_principle",
        "package": "accounting.uor", "priority": 205,
        "rmk_required": true,
        "_legal_basis": "Art. 6 UoR (zasada współmierności)"
    }
}
```

---

### P206: `uor_inventory_obligation`

**Cel biznesowy:** Obowiązek inwentaryzacji na dzień bilansowy.

**Przesłanki:** Data transakcji == ostatni dzień roku obrotowego

**Rezultat:** `inventory_required: true`, `inventory_type: "FULL"`

**Podstawa prawna:** Art. 26 UoR

**Pseudokod Rego:**
```rego
# ── P206: uor_inventory_obligation ─────────────────────────────
decide = verdict {
    input.invoice.is_fiscal_year_end == true
    verdict := {
        "matched": true, "rule_id": "accounting.uor.inventory",
        "package": "accounting.uor", "priority": 206,
        "inventory_required": true,
        "_legal_basis": "Art. 26 UoR"
    }
}
```

---

### P207: `uor_financial_statement_deadline`

**Cel biznesowy:** Termin sporządzenia sprawozdania finansowego — 3 miesiące od dnia bilansowego.

**Przesłanki:** `input.company.fiscal_year_end` == `true` AND `input.invoice.days_since_fye` > 90

**Rezultat:** `financial_statement_overdue: true`, `_warning: "Przekroczony termin sprawozdania"`

**Podstawa prawna:** Art. 52 UoR

**Pseudokod Rego:**
```rego
# ── P207: uor_financial_statement_deadline ─────────────────────
decide = verdict {
    input.invoice.days_since_fye > 90
    verdict := {
        "matched": true, "rule_id": "accounting.uor.statement_deadline",
        "package": "accounting.uor", "priority": 207,
        "financial_statement_overdue": true,
        "_legal_basis": "Art. 52 UoR"
    }
}
```

---

### P208: `uor_intangible_assets`

**Cel biznesowy:** Wartości niematerialne i prawne — amortyzacja (oprogramowanie, licencje).

**Przesłanki:** `input.invoice.expense_type` == `"INTANGIBLE"`

**Rezultat:** `depreciation_method: "LINEAR"`, `depreciation_years`: okres licencji

**Podstawa prawna:** Art. 34 UoR

**Pseudokod Rego:**
```rego
# ── P208: uor_intangible_assets ────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "INTANGIBLE"
    verdict := {
        "matched": true, "rule_id": "accounting.uor.intangible",
        "package": "accounting.uor", "priority": 208,
        "depreciation_method": "LINEAR",
        "depreciation_years": input.invoice.license_years,
        "_legal_basis": "Art. 34 UoR"
    }
}
```

---

# CZĘŚĆ VIII: ORDYNACJA DODATKOWA (P210-P211)

---

### P210: `tax_interpretation_binding`

**Cel biznesowy:** Czy podatnik posiada wiążącą interpretację indywidualną dla danej transakcji.

**Przesłanki:** `input.company.has_tax_interpretation` == `true`

**Rezultat:** `interpretation_protection: true`, `_legal_basis_ref: "Art. 14k Ordynacji"`

**Podstawa prawna:** Art. 14k § 1 Ordynacji podatkowej

**Pseudokod Rego:**
```rego
# ── P210: tax_interpretation_binding ───────────────────────────
decide = verdict {
    input.company.has_tax_interpretation == true
    input.invoice.interpretation_applies == true
    verdict := {
        "matched": true, "rule_id": "compliance.ord.interpretation",
        "package": "compliance.ordynacja", "priority": 210,
        "interpretation_protection": true,
        "_legal_basis": "Art. 14k § 1 Ordynacji podatkowej"
    }
}
```

---

### P211: `tax_liability_third_party`

**Cel biznesowy:** Odpowiedzialność podatkowa osób trzecich (zarząd spółki).

**Przesłanki:** `input.company.legal_form` == `"SP_ZOO"` AND `input.invoice.tax_arrears` == `true`

**Rezultat:** `third_party_liability_risk: true`

**Podstawa prawna:** Art. 116 Ordynacji podatkowej

**Pseudokod Rego:**
```rego
# ── P211: tax_liability_third_party ────────────────────────────
decide = verdict {
    input.company.legal_form == "SP_ZOO"
    input.invoice.tax_arrears == true
    verdict := {
        "matched": true, "rule_id": "compliance.ord.third_party_liability",
        "package": "compliance.ordynacja", "priority": 211,
        "third_party_liability_risk": true,
        "_legal_basis": "Art. 116 Ordynacji podatkowej"
    }
}
```

---

# CZĘŚĆ IX: MSSF DODATKOWE (P215-P216)

---

### P215: `ifrs9_financial_instruments`

**Cel biznesowy:** Klasyfikacja instrumentów finansowych wg MSSF 9.

**Przesłanki:** `input.company.uses_ifrs` == `true` AND `input.invoice.is_financial_instrument` == `true`

**Rezultat:** `ifrs9_applicable: true`, `expected_credit_loss_model: true`

**Podstawa prawna:** MSSF 9

**Pseudokod Rego:**
```rego
# ── P215: ifrs9_financial_instruments ──────────────────────────
decide = verdict {
    input.company.uses_ifrs == true
    input.invoice.is_financial_instrument == true
    verdict := {
        "matched": true, "rule_id": "accounting.ifrs9.instruments",
        "package": "accounting.ifrs", "priority": 215,
        "ifrs9_applicable": true,
        "_legal_basis": "MSSF 9"
    }
}
```

---

### P216: `ifrs15_revenue_recognition`

**Cel biznesowy:** Rozpoznanie przychodów wg MSSF 15 (5-step model).

**Przesłanki:** `input.company.uses_ifrs` == `true` AND `input.invoice.is_revenue_contract` == `true`

**Rezultat:** `ifrs15_applicable: true`, `revenue_recognition_steps: 5`

**Podstawa prawna:** MSSF 15

**Pseudokod Rego:**
```rego
# ── P216: ifrs15_revenue_recognition ───────────────────────────
decide = verdict {
    input.company.uses_ifrs == true
    input.invoice.is_revenue_contract == true
    verdict := {
        "matched": true, "rule_id": "accounting.ifrs15.revenue",
        "package": "accounting.ifrs", "priority": 216,
        "ifrs15_applicable": true,
        "_legal_basis": "MSSF 15"
    }
}
```

---

# CZĘŚĆ X: UPROSZCZONA EWIDENCJA — PKPiR (P220-P221)

---

### P220: `pkpir_entry_format`

**Cel biznesowy:** Wymóg formatu zapisu w PKPiR — min. 16 kolumn.

**Przesłanki:** `input.company.uses_simplified_books` == `true`

**Rezultat:** `pkpir_format_required: true`, `pkpir_columns: 16`

**Podstawa prawna:** Rozp. MF w sprawie PKPiR

**Pseudokod Rego:**
```rego
# ── P220: pkpir_entry_format ───────────────────────────────────
decide = verdict {
    input.company.uses_simplified_books == true
    verdict := {
        "matched": true, "rule_id": "accounting.pkpir.format",
        "package": "accounting.pkpir", "priority": 220,
        "pkpir_format_required": true,
        "_legal_basis": "Rozp. MF w sprawie PKPiR"
    }
}
```

---

### P221: `pkpir_revenue_threshold`

**Cel biznesowy:** Limit przychodów dla PKPiR — 2 000 000 EUR.

**Przesłanki:** `input.company.annual_turnover_net` > 2000000 * `input.thresholds.rates.eur_pln`

**Rezultat:** `full_accounting_required: true`, `_warning: "Przekroczony limit PKPiR — obowiązek pełnej księgowości"`

**Podstawa prawna:** Art. 24a PIT, art. 2 UoR

**Pseudokod Rego:**
```rego
# ── P221: pkpir_revenue_threshold ──────────────────────────────
decide = verdict {
    input.company.annual_turnover_net > 2000000 * input.thresholds.rates.eur_pln
    verdict := {
        "matched": true, "rule_id": "accounting.pkpir.threshold",
        "package": "accounting.pkpir", "priority": 221,
        "full_accounting_required": true,
        "_legal_basis": "Art. 24a PIT, Art. 2 UoR"
    }
}
```

---

# Podsumowanie Deep Dive

| Domena | Nowe reguły | Priorytety |
|--------|:-----------:|------------|
| VAT odliczenia szczegółowe | 3 | P185-P187 |
| VAT korekty | 2 | P188-P189 |
| Podatki lokalne | 2 | P190-P191 |
| Prawo pracy | 3 | P192-P194 |
| Ustawa zasiłkowa | 2 | P195-P196 |
| Prawo budowlane | 1 | P197 |
| Ochrona środowiska | 2 | P198-P199 |
| NGO | 2 | P200-P201 |
| UoR zasady/sprawozdania | 4 | P205-P208 |
| Ordynacja dodatkowa | 2 | P210-P211 |
| MSSF dodatkowe | 2 | P215-P216 |
| PKPiR | 2 | P220-P221 |
| **RAZEM** | **27** | **P185-P221** |

**Całkowite pokrycie: 128 + 27 = 155 reguł w 30+ domenach prawnych.**

---

> **Następny krok:** `10_OPA_IMPLEMENTATION_GUIDE.md` — praktyczny przewodnik implementacji w Rego.
