# 🔬 Zaawansowane Reguły ENTERPRISE — Rozszerzenie o 13 nowych domen prawnych

> **Status:** Dokumentacja ENTERPRISE v3.0  
> **Data:** 2026-07-07  
> **Powiązany:** `06_COMPLETE_RULES_SUPPLEMENT.md`, `03_RULES_DETAILED.md`, `05_ARCHITECTURE_DECISION.md`  
> **Uwaga:** Ten dokument dodaje **33 nowe reguły** w 13 nowych domenach prawnych, zwiększając całkowite pokrycie do **128 reguł**.

---

## Nowe domeny prawne (pokryte w tym dokumencie)

| # | Domena | Liczba reguł | Priorytety |
|---|--------|:-----------:|------------|
| 1 | PPK (Pracownicze Plany Kapitałowe) | 2 | P110-P111 |
| 2 | Akcyza | 3 | P115-P117 |
| 3 | IFRS / MSSF | 3 | P120-P122 |
| 4 | Leasing (CIT/PIT) | 3 | P125-P127 |
| 5 | Darowizny | 3 | P130-P132 |
| 6 | KŚT szczegółowe | 5 | P135-P139 |
| 7 | KUP — wyłączenia szczegółowe | 3 | P140-P142 |
| 8 | JPK — znaczniki strukturalne | 3 | P145-P147 |
| 9 | AML / Przeciwdziałanie praniu pieniędzy | 3 | P150-P152 |
| 10 | Prawo dewizowe (NBP) | 1 | P155 |
| 11 | CEIDG / Prawo przedsiębiorców | 2 | P160-P165 |
| 12 | KSH (Kodeks spółek handlowych) | 1 | P170 |
| 13 | Ordynacja — korekty | 1 | P180 |

---

# CZĘŚĆ I: PPK — Pracownicze Plany Kapitałowe (P110-P111)

---

### P110: `ppk_mandatory_enrollment`

**Cel biznesowy:** Weryfikacja obowiązku wdrożenia PPK dla firm >250 pracowników lub po zakończeniu okresów przejściowych.

**Przesłanki:**
- `input.company.employees_count` >= 250 (lub odpowiedni próg czasowy)
- `input.company.ppk_enrolled` == `false`

**Rezultat:**
- `ppk_mandatory: true`
- `_warning: "Obowiązek wdrożenia PPK — firma zatrudnia powyżej 250 osób"`

**Podstawa prawna:** Art. 32 ustawy o PPK (Dz.U. 2025 poz. 456)

**Pseudokod Rego:**
```rego
# ── P110: ppk_mandatory_enrollment ─────────────────────────────
# Cel biznesowy: Obowiązek wdrożenia PPK (>250 pracowników)
# Przesłanki: employees >= PPK threshold AND !ppk_enrolled
# Podstawa prawna: Ustawa o PPK Art. 32
# Priorytet: 110
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.employees_count >= input.thresholds.limits.ppk_mandatory_employees
    input.company.ppk_enrolled == false
    verdict := {
        "matched": true,
        "rule_id": "compliance.ppk.mandatory_enrollment",
        "package": "compliance.ppk",
        "priority": 110,
        "ppk_mandatory": true,
        "_warnings": [concat("", [
            "Obowiązek wdrożenia PPK — firma zatrudnia ",
            sprintf("%d", [input.company.employees_count]),
            " osób (próg: ",
            sprintf("%d", [input.thresholds.limits.ppk_mandatory_employees]), ")"
        ])],
        "_legal_basis": "Art. 32 ustawy o PPK"
    }
}
```

---

### P111: `ppk_employer_contributions_kup`

**Cel biznesowy:** Składki pracodawcy na PPK (1.5% wynagrodzenia) stanowią koszt uzyskania przychodu.

**Przesłanki:**
- `input.invoice.expense_type` == `"PPK_EMPLOYER"`
- `input.invoice.is_paid` == `true`

**Rezultat:**
- `income_tax_qualification: "deductible_full"`
- `ppk_contribution_deductible: true`

**Podstawa prawna:** Art. 15 ust. 1 CIT, Art. 22 ust. 1 PIT (koszty pracownicze)

**Pseudokod Rego:**
```rego
# ── P111: ppk_employer_contributions_kup ────────────────────────
# Cel biznesowy: Składki PPK pracodawcy jako KUP
# Przesłanki: expense_type == PPK_EMPLOYER AND is_paid
# Podstawa prawna: Art. 15 ust. 1 CIT, Art. 22 ust. 1 PIT
# Priorytet: 111
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "PPK_EMPLOYER"
    input.invoice.is_paid == true
    verdict := {
        "matched": true,
        "rule_id": "compliance.ppk.employer_kup",
        "package": "compliance.ppk",
        "priority": 111,
        "income_tax_qualification": "deductible_full",
        "ppk_contribution_deductible": true,
        "_legal_basis": "Art. 15 ust. 1 CIT, Art. 22 ust. 1 PIT"
    }
}
```

---

# CZĘŚĆ II: AKCYZA (P115-P117)

---

### P115: `excise_energy_tax`

**Cel biznesowy:** Identyfikacja obowiązku akcyzowego dla energii elektrycznej.

**Przesłanki:**
- `input.invoice.category_code` == `"ENERGY"`
- `input.company.is_excise_payer` == `true`

**Rezultat:**
- `excise_applicable: true`
- `excise_type: "ENERGY"`

**Podstawa prawna:** Ustawa o podatku akcyzowym (Dz.U. 2025 poz. 789)

**Pseudokod Rego:**
```rego
# ── P115: excise_energy_tax ─────────────────────────────────────
# Cel biznesowy: Akcyza na energię elektryczną
# Przesłanki: category == ENERGY AND is_excise_payer
# Podstawa prawna: Ustawa o podatku akcyzowym
# Priorytet: 115
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.category_code == "ENERGY"
    input.company.is_excise_payer == true
    verdict := {
        "matched": true,
        "rule_id": "excise.energy_tax",
        "package": "excise",
        "priority": 115,
        "excise_applicable": true,
        "excise_type": "ENERGY",
        "_legal_basis": "Ustawa o podatku akcyzowym"
    }
}
```

---

### P116: `excise_fuel_tax`

**Cel biznesowy:** Identyfikacja obowiązku akcyzowego dla paliw silnikowych.

**Przesłanki:**
- `input.invoice.category_code` == `"FUEL"`
- `input.invoice.excise_duty_paid` == `false`

**Rezultat:**
- `excise_applicable: true`
- `excise_type: "FUEL"`

**Podstawa prawna:** Ustawa o podatku akcyzowym, załącznik nr 1

**Pseudokod Rego:**
```rego
# ── P116: excise_fuel_tax ───────────────────────────────────────
# Cel biznesowy: Akcyza na paliwa silnikowe
# Przesłanki: category == FUEL AND !excise_duty_paid
# Podstawa prawna: Ustawa o podatku akcyzowym, zał. 1
# Priorytet: 116
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.category_code == "FUEL"
    input.invoice.excise_duty_paid == false
    verdict := {
        "matched": true,
        "rule_id": "excise.fuel_tax",
        "package": "excise",
        "priority": 116,
        "excise_applicable": true,
        "excise_type": "FUEL",
        "_legal_basis": "Ustawa o podatku akcyzowym, zał. 1"
    }
}
```

---

### P117: `excise_alcohol_banderoles`

**Cel biznesowy:** Obowiązek banderolowania wyrobów alkoholowych.

**Przesłanki:**
- `input.invoice.category_code` == `"ALCOHOL"`
- `input.invoice.is_domestic_production` == `true`

**Rezultat:**
- `banderoles_required: true`
- `excise_type: "ALCOHOL"`

**Podstawa prawna:** Ustawa o podatku akcyzowym, rozdział 4

**Pseudokod Rego:**
```rego
# ── P117: excise_alcohol_banderoles ─────────────────────────────
# Cel biznesowy: Obowiązek banderolowania alkoholu
# Przesłanki: category == ALCOHOL AND domestic_production
# Podstawa prawna: Ustawa o podatku akcyzowym, rozdz. 4
# Priorytet: 117
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.category_code == "ALCOHOL"
    input.invoice.is_domestic_production == true
    verdict := {
        "matched": true,
        "rule_id": "excise.alcohol_banderoles",
        "package": "excise",
        "priority": 117,
        "excise_applicable": true,
        "excise_type": "ALCOHOL",
        "banderoles_required": true,
        "_legal_basis": "Ustawa o podatku akcyzowym, rozdz. 4"
    }
}
```

---

# CZĘŚĆ III: IFRS / MSSF (P120-P122)

---

### P120: `ifrs16_leasing_recognition`

**Cel biznesowy:** Identyfikacja umów leasingu >12 miesięcy wymagających rozpoznania w bilansie wg MSSF 16 (Right-of-Use Asset).

**Przesłanki:**
- `input.company.uses_ifrs` == `true`
- `input.invoice.expense_type` == `"LEASE"`
- `input.invoice.lease_term_months` > 12

**Rezultat:**
- `ifrs16_applicable: true`
- `right_of_use_asset: true`
- `lease_liability: true`

**Podstawa prawna:** MSSF 16 (Rozporządzenie KE nr 1126/2008 z późn. zm.)

**Pseudokod Rego:**
```rego
# ── P120: ifrs16_leasing_recognition ────────────────────────────
# Cel biznesowy: Rozpoznanie leasingu wg MSSF 16
# Przesłanki: uses_ifrs AND lease > 12m
# Podstawa prawna: MSSF 16
# Priorytet: 120
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.uses_ifrs == true
    input.invoice.expense_type == "LEASE"
    input.invoice.lease_term_months > 12
    verdict := {
        "matched": true,
        "rule_id": "accounting.ifrs16.leasing",
        "package": "accounting.ifrs",
        "priority": 120,
        "ifrs16_applicable": true,
        "right_of_use_asset": true,
        "lease_liability": true,
        "_legal_basis": "MSSF 16"
    }
}
```

---

### P121: `ias37_provision_recognition`

**Cel biznesowy:** Identyfikacja obowiązku utworzenia rezerwy na zobowiązania (sprawy sądowe, gwarancje).

**Przesłanki:**
- `input.company.uses_ifrs` == `true`
- `input.invoice.is_contingent_liability` == `true`
- `input.invoice.liability_probability` >= 0.50

**Rezultat:**
- `provision_required: true`
- `provision_type: "IAS37"`

**Podstawa prawna:** MSR 37

**Pseudokod Rego:**
```rego
# ── P121: ias37_provision_recognition ───────────────────────────
# Cel biznesowy: Rezerwy na zobowiązania wg MSR 37
# Przesłanki: uses_ifrs AND contingent_liability AND prob > 50%
# Podstawa prawna: MSR 37
# Priorytet: 121
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.uses_ifrs == true
    input.invoice.is_contingent_liability == true
    input.invoice.liability_probability >= 0.50
    verdict := {
        "matched": true,
        "rule_id": "accounting.ias37.provision",
        "package": "accounting.ifrs",
        "priority": 121,
        "provision_required": true,
        "provision_type": "IAS37",
        "provision_probability": input.invoice.liability_probability,
        "_legal_basis": "MSR 37"
    }
}
```

---

### P122: `ias12_deferred_tax`

**Cel biznesowy:** Identyfikacja różnic przejściowych między wynikiem księgowym a podatkowym → podatek odroczony.

**Przesłanki:**
- `input.company.uses_ifrs` == `true`
- `input.invoice.accounting_profit` != `input.invoice.tax_profit`

**Rezultat:**
- `deferred_tax_required: true`
- `deferred_tax_type`: `"DTA"` (aktyw) lub `"DTL"` (rezerwa)

**Podstawa prawna:** MSR 12

**Pseudokod Rego:**
```rego
# ── P122: ias12_deferred_tax ────────────────────────────────────
# Cel biznesowy: Podatek odroczony wg MSR 12
# Przesłanki: uses_ifrs AND accounting_profit != tax_profit
# Podstawa prawna: MSR 12
# Priorytet: 122
# ────────────────────────────────────────────────────────────────
deferred_tax_type = "DTA" {
    input.invoice.accounting_profit < input.invoice.tax_profit
} else = "DTL" {
    input.invoice.accounting_profit > input.invoice.tax_profit
}

decide = verdict {
    input.company.uses_ifrs == true
    input.invoice.accounting_profit != input.invoice.tax_profit
    verdict := {
        "matched": true,
        "rule_id": "accounting.ias12.deferred_tax",
        "package": "accounting.ifrs",
        "priority": 122,
        "deferred_tax_required": true,
        "deferred_tax_type": deferred_tax_type,
        "_legal_basis": "MSR 12"
    }
}
```

---

# CZĘŚĆ IV: LEASING — Podatkowe (P125-P127)

---

### P125: `leasing_operacyjny_tax`

**Cel biznesowy:** Klasyfikacja umowy leasingu jako operacyjnego dla celów podatkowych — raty w całości KUP.

**Przesłanki:**
- `input.invoice.expense_type` == `"LEASE"`
- `input.invoice.lease_term_months` >= 0.40 * `input.invoice.asset_normative_months`
- `input.invoice.lease_has_purchase_option` == `true`

**Rezultat:**
- `leasing_type: "OPERATING"`
- `income_tax_qualification: "deductible_full"`
- `kup_note: "Całość raty leasingowej stanowi KUP"`

**Podstawa prawna:** Art. 17b CIT, Art. 23a PIT

**Pseudokod Rego:**
```rego
# ── P125: leasing_operacyjny_tax ────────────────────────────────
# Cel biznesowy: Leasing operacyjny → raty w KUP
# Przesłanki: LEASE AND term >= 40% normatywnego AND purchase_option
# Podstawa prawna: Art. 17b CIT, Art. 23a PIT
# Priorytet: 125
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "LEASE"
    input.invoice.lease_term_months >= 0.40 * input.invoice.asset_normative_months
    input.invoice.lease_has_purchase_option == true
    verdict := {
        "matched": true,
        "rule_id": "direct.leasing.operating",
        "package": "direct.leasing",
        "priority": 125,
        "leasing_type": "OPERATING",
        "income_tax_qualification": "deductible_full",
        "kup_note": "Całość raty leasingowej stanowi KUP",
        "_legal_basis": "Art. 17b CIT, Art. 23a PIT"
    }
}
```

---

### P126: `leasing_finansowy_tax`

**Cel biznesowy:** Klasyfikacja leasingu jako finansowego — KUP = amortyzacja + część odsetkowa raty.

**Przesłanki:**
- `input.invoice.expense_type` == `"LEASE"`
- `input.invoice.lease_term_months` < 0.40 * `input.invoice.asset_normative_months`

**Rezultat:**
- `leasing_type: "FINANCIAL"`
- `income_tax_qualification: "deductible_partial"`
- `kup_note: "KUP = amortyzacja + odsetki od raty"`

**Podstawa prawna:** Art. 17f CIT, Art. 23f PIT

**Pseudokod Rego:**
```rego
# ── P126: leasing_finansowy_tax ─────────────────────────────────
# Cel biznesowy: Leasing finansowy → KUP = amortyzacja + odsetki
# Przesłanki: LEASE AND term < 40% normatywnego
# Podstawa prawna: Art. 17f CIT, Art. 23f PIT
# Priorytet: 126
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "LEASE"
    input.invoice.lease_term_months < 0.40 * input.invoice.asset_normative_months
    verdict := {
        "matched": true,
        "rule_id": "direct.leasing.financial",
        "package": "direct.leasing",
        "priority": 126,
        "leasing_type": "FINANCIAL",
        "income_tax_qualification": "deductible_partial",
        "kup_note": "KUP = amortyzacja + część odsetkowa raty leasingowej",
        "_legal_basis": "Art. 17f CIT, Art. 23f PIT"
    }
}
```

---

### P127: `leasing_car_over_150k_limit`

**Cel biznesowy:** Ograniczenie KUP dla samochodów osobowych o wartości >150 000 PLN (leasing i zakup).

**Przesłanki:**
- `input.invoice.category_code` == `"CAR"`
- `input.invoice.amount_net` > 150000
- `input.invoice.expense_type` in `["LEASE", "FIXED_ASSET"]`

**Rezultat:**
- `car_value_limit_exceeded: true`
- `kup_proportion`: `150000 / amount_net`
- `_warning: "Samochód powyżej 150 000 PLN — ograniczenie KUP"`

**Podstawa prawna:** Art. 16 ust. 1 pkt 49a CIT, Art. 23 ust. 1 pkt 47a PIT

**Pseudokod Rego:**
```rego
# ── P127: leasing_car_over_150k_limit ────────────────────────────
# Cel biznesowy: Limit KUP dla aut >150k PLN
# Przesłanki: CAR AND net > 150k AND (LEASE OR FIXED_ASSET)
# Podstawa prawna: Art. 16 ust. 1 pkt 49a CIT, Art. 23 ust. 1 pkt 47a PIT
# Priorytet: 127
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.category_code == "CAR"
    input.invoice.amount_net > 150000
    input.invoice.expense_type in ["LEASE", "FIXED_ASSET"]
    verdict := {
        "matched": true,
        "rule_id": "direct.leasing.car_over_150k",
        "package": "direct.leasing",
        "priority": 127,
        "car_value_limit_exceeded": true,
        "kup_proportion": 150000 / input.invoice.amount_net,
        "_warnings": [concat("", [
            "Samochód powyżej 150 000 PLN (netto: ",
            sprintf("%.0f", [input.invoice.amount_net]),
            " PLN) — ograniczenie KUP proporcjonalnie do 150 000 PLN"
        ])],
        "_legal_basis": "Art. 16 ust. 1 pkt 49a CIT, Art. 23 ust. 1 pkt 47a PIT"
    }
}
```

---

# CZĘŚĆ V: DAROWIZNY (P130-P132)

---

### P130: `donation_ngo_limit`

**Cel biznesowy:** Odliczenie darowizn na rzecz OPP — limit 10% dochodu (CIT) / 6% (PIT).

**Przesłanki:**
- `input.invoice.expense_type` == `"DONATION"`
- `input.vendor.is_ngo` == `true`

**Rezultat:**
- `donation_deductible: true`
- `donation_limit_percent`: 10 (CIT) lub 6 (PIT)
- `donation_recipient_type: "NGO"`

**Podstawa prawna:** Art. 18 CIT, Art. 26 PIT

**Pseudokod Rego:**
```rego
# ── P130: donation_ngo_limit ────────────────────────────────────
# Cel biznesowy: Darowizna dla OPP — limit % dochodu
# Przesłanki: DONATION AND is_ngo
# Podstawa prawna: Art. 18 CIT, Art. 26 PIT
# Priorytet: 130
# ────────────────────────────────────────────────────────────────
donation_limit = 10 {
    input.company.tax_form in ["CIT_STANDARD", "CIT_ESTONIAN"]
} else = 6 {
    true
}

decide = verdict {
    input.invoice.expense_type == "DONATION"
    input.vendor.is_ngo == true
    verdict := {
        "matched": true,
        "rule_id": "allowances.donation.ngo",
        "package": "allowances.donations",
        "priority": 130,
        "donation_deductible": true,
        "donation_limit_percent": donation_limit,
        "donation_recipient_type": "NGO",
        "_legal_basis": "Art. 18 CIT, Art. 26 PIT"
    }
}
```

---

### P131: `donation_blood`

**Cel biznesowy:** Ulga dla honorowych dawców krwi — ekwiwalent 130 PLN za litr (PIT).

**Przesłanki:**
- `input.invoice.expense_type` == `"BLOOD_DONATION"`
- `input.invoice.blood_liters` > 0

**Rezultat:**
- `donation_blood_deductible: true`
- `donation_blood_amount`: litry × stawka z thresholds

**Podstawa prawna:** Art. 26 ust. 1 pkt 9b PIT

**Pseudokod Rego:**
```rego
# ── P131: donation_blood ────────────────────────────────────────
# Cel biznesowy: Ulga dla krwiodawców
# Przesłanki: BLOOD_DONATION AND liters > 0
# Podstawa prawna: Art. 26 ust. 1 pkt 9b PIT
# Priorytet: 131
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "BLOOD_DONATION"
    input.invoice.blood_liters > 0
    verdict := {
        "matched": true,
        "rule_id": "allowances.donation.blood",
        "package": "allowances.donations",
        "priority": 131,
        "donation_blood_deductible": true,
        "donation_blood_liters": input.invoice.blood_liters,
        "donation_blood_equivalent": input.invoice.blood_liters * input.thresholds.bounds.blood_liter_equivalent,
        "_legal_basis": "Art. 26 ust. 1 pkt 9b PIT"
    }
}
```

---

### P132: `donation_church`

**Cel biznesowy:** Darowizny na cele kultu religijnego — pełne odliczenie bez limitu.

**Przesłanki:**
- `input.invoice.expense_type` == `"DONATION"`
- `input.vendor.is_religious_org` == `true`

**Rezultat:**
- `donation_deductible: true`
- `donation_limit: "UNLIMITED"`

**Podstawa prawna:** Art. 18 ust. 1 pkt 7 CIT, Art. 26 ust. 1 pkt 9 PIT

**Pseudokod Rego:**
```rego
# ── P132: donation_church ───────────────────────────────────────
# Cel biznesowy: Darowizna kościelna — bez limitu
# Przesłanki: DONATION AND is_religious_org
# Podstawa prawna: Art. 18 ust. 1 pkt 7 CIT, Art. 26 PIT
# Priorytet: 132
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "DONATION"
    input.vendor.is_religious_org == true
    verdict := {
        "matched": true,
        "rule_id": "allowances.donation.church",
        "package": "allowances.donations",
        "priority": 132,
        "donation_deductible": true,
        "donation_limit": "UNLIMITED",
        "_legal_basis": "Art. 18 ust. 1 pkt 7 CIT, Art. 26 ust. 1 pkt 9 PIT"
    }
}
```

---

# CZĘŚĆ VI: KŚT — Klasyfikacja Środków Trwałych szczegółowa (P135-P139)

---

### P135: `kst_group_0_land`

**Cel biznesowy:** Grunty nie podlegają amortyzacji (NKUP).

**Przesłanki:**
- `input.invoice.kst_group` == 0
- `input.invoice.expense_type` == `"FIXED_ASSET"`

**Rezultat:**
- `depreciation_method: "NONE"`
- `depreciation_rate: "0.00"`
- `_warning: "Grunty nie podlegają amortyzacji"`

**Podstawa prawna:** Art. 16c pkt 1 CIT, Art. 22c pkt 1 PIT

**Pseudokod Rego:**
```rego
# ── P135: kst_group_0_land ──────────────────────────────────────
# Cel biznesowy: Grunty — brak amortyzacji
# Przesłanki: kst_group == 0 AND FIXED_ASSET
# Podstawa prawna: Art. 16c pkt 1 CIT
# Priorytet: 135
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.kst_group == 0
    input.invoice.expense_type == "FIXED_ASSET"
    verdict := {
        "matched": true,
        "rule_id": "accounting.kst.land_no_depreciation",
        "package": "accounting.kst",
        "priority": 135,
        "depreciation_method": "NONE",
        "depreciation_rate": input.thresholds.rates.vat_zero,
        "income_tax_qualification": "non_deductible",
        "_warnings": ["Grunty i prawa wieczystego użytkowania nie podlegają amortyzacji"],
        "_legal_basis": "Art. 16c pkt 1 CIT, Art. 22c pkt 1 PIT"
    }
}
```

---

### P136: `kst_group_1_buildings`

**Cel biznesowy:** Budynki — stawka podstawowa 2.5% rocznie (okres 40 lat).

**Przesłanki:**
- `input.invoice.kst_group` == 1
- `input.invoice.expense_type` == `"FIXED_ASSET"`

**Rezultat:**
- `depreciation_rate: "0.025"`
- `depreciation_years: 40`

**Podstawa prawna:** KŚT — załącznik 1, grupa 1

**Pseudokod Rego:**
```rego
# ── P136: kst_group_1_buildings ─────────────────────────────────
# Cel biznesowy: Budynki — amortyzacja 2.5%/rok
# Przesłanki: kst_group == 1 AND FIXED_ASSET
# Podstawa prawna: KŚT zał. 1, grupa 1
# Priorytet: 136
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.kst_group == 1
    input.invoice.expense_type == "FIXED_ASSET"
    verdict := {
        "matched": true,
        "rule_id": "accounting.kst.buildings_25",
        "package": "accounting.kst",
        "priority": 136,
        "depreciation_method": "LINEAR",
        "depreciation_rate": "0.025",
        "depreciation_years": 40,
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "KŚT — załącznik 1, grupa 1"
    }
}
```

---

### P137: `kst_group_4_computers`

**Cel biznesowy:** Sprzęt komputerowy — stawka 30% (okres 3.33 roku).

**Przesłanki:**
- `input.invoice.kst_group` == 4
- `input.invoice.kst_subgroup` in `[491]` (maszyny cyfrowe)

**Rezultat:**
- `depreciation_rate: "0.30"`
- `depreciation_years: 3.33`

**Podstawa prawna:** KŚT — załącznik 1, grupa 4, podgrupa 491

**Pseudokod Rego:**
```rego
# ── P137: kst_group_4_computers ─────────────────────────────────
# Cel biznesowy: Komputery — amortyzacja 30%
# Przesłanki: kst_group == 4 AND kst_subgroup 491
# Podstawa prawna: KŚT zał. 1, gr. 4, podgr. 491
# Priorytet: 137
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.kst_group == 4
    input.invoice.kst_subgroup == 491
    input.invoice.expense_type == "FIXED_ASSET"
    verdict := {
        "matched": true,
        "rule_id": "accounting.kst.computers_30",
        "package": "accounting.kst",
        "priority": 137,
        "depreciation_method": "LINEAR",
        "depreciation_rate": "0.30",
        "depreciation_years": 3.33,
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "KŚT — załącznik 1, grupa 4, podgrupa 491"
    }
}
```

---

### P138: `kst_group_7_cars`

**Cel biznesowy:** Samochody osobowe — stawka 20% (5 lat).

**Przesłanki:**
- `input.invoice.kst_group` == 7
- `input.invoice.expense_type` == `"FIXED_ASSET"`

**Rezultat:**
- `depreciation_rate: "0.20"`
- `depreciation_years: 5`

**Podstawa prawna:** KŚT — załącznik 1, grupa 7

**Pseudokod Rego:**
```rego
# ── P138: kst_group_7_cars ──────────────────────────────────────
# Cel biznesowy: Samochody — amortyzacja 20%
# Przesłanki: kst_group == 7 AND FIXED_ASSET
# Podstawa prawna: KŚT zał. 1, grupa 7
# Priorytet: 138
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.kst_group == 7
    input.invoice.expense_type == "FIXED_ASSET"
    verdict := {
        "matched": true,
        "rule_id": "accounting.kst.cars_20",
        "package": "accounting.kst",
        "priority": 138,
        "depreciation_method": "LINEAR",
        "depreciation_rate": "0.20",
        "depreciation_years": 5,
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "KŚT — załącznik 1, grupa 7"
    }
}
```

---

### P139: `kst_low_value_one_off`

**Cel biznesowy:** Środki trwałe ≤10 000 PLN — jednorazowa amortyzacja w miesiącu oddania.

**Przesłanki:**
- `input.invoice.expense_type` == `"FIXED_ASSET"`
- `input.invoice.amount_net` <= 10000
- `input.invoice.amount_net` > 0

**Rezultat:**
- `depreciation_method: "ONE_OFF"`
- `depreciation_rate: "1.00"`

**Podstawa prawna:** Art. 16d ust. 1 CIT, Art. 22d ust. 1 PIT

**Pseudokod Rego:**
```rego
# ── P139: kst_low_value_one_off ─────────────────────────────────
# Cel biznesowy: Jednorazowa amortyzacja < 10k PLN
# Przesłanki: FIXED_ASSET AND net <= 10000
# Podstawa prawna: Art. 16d ust. 1 CIT
# Priorytet: 139
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "FIXED_ASSET"
    input.invoice.amount_net <= 10000
    input.invoice.amount_net > 0
    verdict := {
        "matched": true,
        "rule_id": "accounting.kst.low_value_one_off",
        "package": "accounting.kst",
        "priority": 139,
        "depreciation_method": "ONE_OFF",
        "depreciation_rate": "1.00",
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "Art. 16d ust. 1 CIT, Art. 22d ust. 1 PIT"
    }
}
```

---

# CZĘŚĆ VII: KUP — Wyłączenia szczegółowe (P140-P142)

---

### P140: `kup_representation_non_deductible`

**Cel biznesowy:** Wydatki na reprezentację (restauracje, alkohol, upominki) — całkowicie wyłączone z KUP.

**Przesłanki:**
- `input.invoice.expense_type` == `"REPRESENTATION"`

**Rezultat:**
- `income_tax_qualification: "non_deductible"`
- `_warning: "Wydatki na reprezentację nie stanowią KUP"`

**Podstawa prawna:** Art. 16 ust. 1 pkt 28 CIT, Art. 23 ust. 1 pkt 23 PIT

**Pseudokod Rego:**
```rego
# ── P140: kup_representation_non_deductible ─────────────────────
# Cel biznesowy: Reprezentacja → NKUP
# Przesłanki: expense_type == REPRESENTATION
# Podstawa prawna: Art. 16 ust. 1 pkt 28 CIT, Art. 23 ust. 1 pkt 23 PIT
# Priorytet: 140
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "REPRESENTATION"
    verdict := {
        "matched": true,
        "rule_id": "direct.kup.representation",
        "package": "direct.kup",
        "priority": 140,
        "income_tax_qualification": "non_deductible",
        "_warnings": ["Wydatki na reprezentację nie stanowią kosztu uzyskania przychodu"],
        "_legal_basis": "Art. 16 ust. 1 pkt 28 CIT, Art. 23 ust. 1 pkt 23 PIT"
    }
}
```

---

### P141: `kup_penalties_non_deductible`

**Cel biznesowy:** Kary umowne, grzywny, odsetki budżetowe — wyłączone z KUP.

**Przesłanki:**
- `input.invoice.expense_type` in `["PENALTY", "FINE", "BUDGET_INTEREST"]`

**Rezultat:**
- `income_tax_qualification: "non_deductible"`
- `_warning: "Kary i odsetki budżetowe nie stanowią KUP"`

**Podstawa prawna:** Art. 16 ust. 1 pkt 18-22 CIT, Art. 23 ust. 1 pkt 16-18 PIT

**Pseudokod Rego:**
```rego
# ── P141: kup_penalties_non_deductible ──────────────────────────
# Cel biznesowy: Kary i odsetki budżetowe → NKUP
# Przesłanki: expense_type in PENALTY/FINE/BUDGET_INTEREST
# Podstawa prawna: Art. 16 ust. 1 pkt 18-22 CIT
# Priorytet: 141
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type in ["PENALTY", "FINE", "BUDGET_INTEREST"]
    verdict := {
        "matched": true,
        "rule_id": "direct.kup.penalties",
        "package": "direct.kup",
        "priority": 141,
        "income_tax_qualification": "non_deductible",
        "_warnings": ["Kary umowne, grzywny i odsetki budżetowe nie stanowią KUP"],
        "_legal_basis": "Art. 16 ust. 1 pkt 18-22 CIT, Art. 23 ust. 1 pkt 16-18 PIT"
    }
}
```

---

### P142: `kup_unpaid_zus`

**Cel biznesowy:** Niezapłacone składki ZUS (społeczne) — nie stanowią KUP do momentu zapłaty.

**Przesłanki:**
- `input.invoice.expense_type` == `"ZUS_SOCIAL"`
- `input.invoice.is_paid` == `false`

**Rezultat:**
- `income_tax_qualification: "non_deductible"`
- `kup_deferred: true`
- `_warning: "Niezapłacone składki ZUS — KUP dopiero po zapłacie"`

**Podstawa prawna:** Art. 15 ust. 4h CIT, Art. 22 ust. 6ba PIT

**Pseudokod Rego:**
```rego
# ── P142: kup_unpaid_zus ────────────────────────────────────────
# Cel biznesowy: Niezapłacony ZUS → NKUP do momentu zapłaty
# Przesłanki: expense_type == ZUS_SOCIAL AND !is_paid
# Podstawa prawna: Art. 15 ust. 4h CIT
# Priorytet: 142
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "ZUS_SOCIAL"
    input.invoice.is_paid == false
    verdict := {
        "matched": true,
        "rule_id": "direct.kup.unpaid_zus",
        "package": "direct.kup",
        "priority": 142,
        "income_tax_qualification": "non_deductible",
        "kup_deferred": true,
        "_warnings": ["Niezapłacone składki ZUS — staną się KUP po zapłacie"],
        "_legal_basis": "Art. 15 ust. 4h CIT, Art. 22 ust. 6ba PIT"
    }
}
```

---

# CZĘŚĆ VIII: JPK — Znaczniki strukturalne (P145-P147)

---

### P145: `jpk_margin_procedure_flag`

**Cel biznesowy:** Znacznik MR_UZ / MR_T w JPK_V7 dla transakcji objętych procedurą VAT-marża.

**Przesłanki:**
- `input.invoice.procedure` == `"MARGIN"`
- Reguła P50 (vat_margin_scheme) dopasowana

**Rezultat:**
- `jpk_margin_flag: "MR_UZ"` (używane towary) lub `"MR_T"` (dzieła sztuki)

**Podstawa prawna:** § 10 rozporządzenia w sprawie JPK_VAT

**Pseudokod Rego:**
```rego
# ── P145: jpk_margin_procedure_flag ─────────────────────────────
# Cel biznesowy: Znacznik marży w JPK_V7
# Przesłanki: procedure == MARGIN
# Podstawa prawna: § 10 rozp. JPK_VAT
# Priorytet: 145
# ────────────────────────────────────────────────────────────────
jpk_margin_marker = "MR_UZ" {
    input.invoice.procedure == "MARGIN"
    input.invoice.category_code != "ART"
} else = "MR_T" {
    input.invoice.procedure == "MARGIN"
    input.invoice.category_code == "ART"
}

decide = verdict {
    input.invoice.procedure == "MARGIN"
    verdict := {
        "matched": true,
        "rule_id": "compliance.jpk.margin_flag",
        "package": "compliance.jpk",
        "priority": 145,
        "jpk_margin_flag": jpk_margin_marker,
        "jpk_margin_required": true,
        "_legal_basis": "§ 10 rozporządzenia w sprawie JPK_VAT"
    }
}
```

---

### P146: `jpk_mpp_marker`

**Cel biznesowy:** Znacznik MPP w JPK_V7 dla faktur objętych mechanizmem podzielonej płatności.

**Przesłanki:**
- `input.invoice.mpp_applied` == `true`

**Rezultat:**
- `jpk_mpp_flag: "MPP"`

**Podstawa prawna:** § 10 rozp. JPK_VAT, Art. 108a VAT

**Pseudokod Rego:**
```rego
# ── P146: jpk_mpp_marker ────────────────────────────────────────
# Cel biznesowy: Znacznik MPP w JPK_V7
# Przesłanki: mpp_applied == true
# Podstawa prawna: § 10 rozp. JPK_VAT
# Priorytet: 146
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.mpp_applied == true
    verdict := {
        "matched": true,
        "rule_id": "compliance.jpk.mpp_marker",
        "package": "compliance.jpk",
        "priority": 146,
        "jpk_mpp_flag": "MPP",
        "_legal_basis": "§ 10 rozp. JPK_VAT, Art. 108a VAT"
    }
}
```

---

### P147: `jpk_tp_marker`

**Cel biznesowy:** Znacznik TP w JPK_V7 dla transakcji z podmiotami powiązanymi.

**Przesłanki:**
- `input.vendor.is_related_party` == `true`

**Rezultat:**
- `jpk_tp_flag: "TP"`

**Podstawa prawna:** § 10 rozp. JPK_VAT, Art. 11a-11q CIT

**Pseudokod Rego:**
```rego
# ── P147: jpk_tp_marker ─────────────────────────────────────────
# Cel biznesowy: Znacznik TP w JPK_V7
# Przesłanki: is_related_party == true
# Podstawa prawna: § 10 rozp. JPK_VAT
# Priorytet: 147
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.is_related_party == true
    verdict := {
        "matched": true,
        "rule_id": "compliance.jpk.tp_marker",
        "package": "compliance.jpk",
        "priority": 147,
        "jpk_tp_flag": "TP",
        "_legal_basis": "§ 10 rozp. JPK_VAT, Art. 11a-11q CIT"
    }
}
```

---

# CZĘŚĆ IX: AML — Przeciwdziałanie praniu pieniędzy (P150-P152)

---

### P150: `aml_high_value_transaction`

**Cel biznesowy:** Transakcja >15 000 EUR → obowiązek rejestracji w GIIF.

**Przesłanki:**
- `input.invoice.amount_gross` w przeliczeniu na EUR > `input.thresholds.limits.aml_reporting_threshold_eur`
- `input.invoice.is_cash_payment` == `true` lub `input.invoice.currency` in high-risk currencies

**Rezultat:**
- `aml_report_required: true`
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Transakcja powyżej progu AML (>15 000 EUR)"`

**Podstawa prawna:** Art. 72 ustawy o AML (Dz.U. 2025 poz. 567)

**Pseudokod Rego:**
```rego
# ── P150: aml_high_value_transaction ────────────────────────────
# Cel biznesowy: Raportowanie AML >15k EUR
# Przesłanki: gross > 15k EUR (w PLN) AND cash / crypto
# Podstawa prawna: Art. 72 ustawy o AML
# Priorytet: 150
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.amount_gross_eur >= input.thresholds.limits.aml_reporting_threshold_eur
    input.invoice.is_high_risk_payment == true
    verdict := {
        "matched": true,
        "rule_id": "compliance.aml.high_value_transaction",
        "package": "compliance.aml",
        "priority": 150,
        "aml_report_required": true,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": concat("", [
            "Transakcja powyżej progu AML (",
            sprintf("%.0f", [input.thresholds.limits.aml_reporting_threshold_eur]),
            " EUR)"
        ]),
        "_legal_basis": "Art. 72 ustawy o AML"
    }
}
```

---

### P151: `aml_pep_detection`

**Cel biznesowy:** Kontrahent lub UBO z listy PEP (Politically Exposed Persons) → wzmożone środki bezpieczeństwa.

**Przesłanki:**
- `input.vendor.is_pep` == `true`
- `input.invoice.amount_gross` > 0

**Rezultat:**
- `aml_pep_detected: true`
- `_routing: "BLOCK_AND_ALERT"`
- `enhanced_due_diligence_required: true`

**Podstawa prawna:** Art. 46 ustawy o AML

**Pseudokod Rego:**
```rego
# ── P151: aml_pep_detection ─────────────────────────────────────
# Cel biznesowy: Wykrycie PEP → wzmożona weryfikacja
# Przesłanki: vendor.is_pep == true
# Podstawa prawna: Art. 46 ustawy o AML
# Priorytet: 151
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.is_pep == true
    verdict := {
        "matched": true,
        "rule_id": "risk.aml.pep_detection",
        "package": "risk.aml",
        "priority": 151,
        "aml_pep_detected": true,
        "enhanced_due_diligence_required": true,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Kontrahent na liście PEP — wymagana wzmożona weryfikacja",
        "_legal_basis": "Art. 46 ustawy o AML"
    }
}
```

---

### P152: `aml_crbr_mismatch`

**Cel biznesowy:** Niezgodność beneficjenta rzeczywistego (UBO) z Centralnym Rejestrem Beneficjentów Rzeczywistych.

**Przesłanki:**
- `input.vendor.crbr_verified` == `false`
- `input.vendor.is_company` == `true`

**Rezultat:**
- `aml_crbr_alert: true`
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Brak weryfikacji UBO w CRBR"`

**Podstawa prawna:** Art. 58-68 ustawy o AML

**Pseudokod Rego:**
```rego
# ── P152: aml_crbr_mismatch ─────────────────────────────────────
# Cel biznesowy: Brak UBO w CRBR → blokada
# Przesłanki: !crbr_verified AND is_company
# Podstawa prawna: Art. 58-68 ustawy o AML
# Priorytet: 152
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.crbr_verified == false
    input.vendor.is_company == true
    verdict := {
        "matched": true,
        "rule_id": "risk.aml.crbr_mismatch",
        "package": "risk.aml",
        "priority": 152,
        "aml_crbr_alert": true,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Brak weryfikacji beneficjenta rzeczywistego (UBO) w CRBR",
        "_legal_basis": "Art. 58-68 ustawy o AML"
    }
}
```

---

# CZĘŚĆ X: PRAWO DEWIZOWE (P155)

---

### P155: `fx_nbp_reporting`

**Cel biznesowy:** Transakcja walutowa powyżej progu NBP → obowiązek raportowania do NBP.

**Przesłanki:**
- `input.invoice.currency` != `"PLN"`
- `input.invoice.amount_gross` w walucie obcej > próg NBP

**Rezultat:**
- `nbp_report_required: true`
- `_warning: "Transakcja dewizowa powyżej progu NBP — obowiązek raportowania"`

**Podstawa prawna:** Art. 30 Prawa dewizowego (Dz.U. 2025 poz. 345)

**Pseudokod Rego:**
```rego
# ── P155: fx_nbp_reporting ──────────────────────────────────────
# Cel biznesowy: Raportowanie dewizowe NBP
# Przesłanki: currency != PLN AND amount > NBP threshold
# Podstawa prawna: Art. 30 Prawa dewizowego
# Priorytet: 155
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.currency != "PLN"
    input.invoice.amount_gross >= input.thresholds.limits.nbp_reporting_threshold
    verdict := {
        "matched": true,
        "rule_id": "compliance.fx.nbp_reporting",
        "package": "compliance.fx",
        "priority": 155,
        "nbp_report_required": true,
        "nbp_transaction_currency": input.invoice.currency,
        "_warnings": ["Transakcja dewizowa powyżej progu NBP — obowiązek raportowania"],
        "_legal_basis": "Art. 30 Prawa dewizowego"
    }
}
```

---

# CZĘŚĆ XI: CEIDG / PRAWO PRZEDSIĘBIORCÓW (P160-P165)

---

### P160: `ceidg_vendor_suspended`

**Cel biznesowy:** Kontrahent z zawieszoną działalnością w CEIDG — ryzyko fraudu.

**Przesłanki:**
- `input.vendor.ceidg_status` == `"SUSPENDED"`
- `input.invoice.transaction_date` > data zawieszenia

**Rezultat:**
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Kontrahent z zawieszoną działalnością w CEIDG"`
- `fraud_risk_elevated: true`

**Podstawa prawna:** Art. 88 ustawy o VAT (brak prawa do odliczenia), Prawo przedsiębiorców

**Pseudokod Rego:**
```rego
# ── P160: ceidg_vendor_suspended ────────────────────────────────
# Cel biznesowy: Zawieszony kontrahent CEIDG → BLOCK
# Przesłanki: ceidg_status == SUSPENDED
# Podstawa prawna: Art. 88 VAT, Prawo przedsiębiorców
# Priorytet: 160
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.ceidg_status == "SUSPENDED"
    verdict := {
        "matched": true,
        "rule_id": "risk.ceidg.suspended_vendor",
        "package": "risk",
        "priority": 160,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Kontrahent z zawieszoną działalnością w CEIDG",
        "fraud_risk_elevated": true,
        "_legal_basis": "Art. 88 VAT, Prawo przedsiębiorców"
    }
}
```

---

### P165: `business_unregistered_activity_limit`

**Cel biznesowy:** Przekroczenie limitu działalności nieewidencjonowanej (50% minimalnego wynagrodzenia) → obowiązek rejestracji w CEIDG.

**Przesłanki:**
- `input.company.is_unregistered` == `true`
- `input.company.monthly_revenue` > 0.50 * `input.thresholds.bounds.minimum_wage`

**Rezultat:**
- `ceidg_registration_required: true`
- `_warning: "Przekroczony limit działalności nieewidencjonowanej — wymagana rejestracja CEIDG"`

**Podstawa prawna:** Art. 5 Prawa przedsiębiorców

**Pseudokod Rego:**
```rego
# ── P165: business_unregistered_activity_limit ──────────────────
# Cel biznesowy: Limit działalności nieewidencjonowanej
# Przesłanki: is_unregistered AND revenue > 50% min_wage
# Podstawa prawna: Art. 5 Prawa przedsiębiorców
# Priorytet: 165
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.is_unregistered == true
    input.company.monthly_revenue > 0.50 * input.thresholds.bounds.minimum_wage
    verdict := {
        "matched": true,
        "rule_id": "compliance.business.unregistered_limit",
        "package": "compliance.business",
        "priority": 165,
        "ceidg_registration_required": true,
        "_warnings": [concat("", [
            "Przekroczony limit działalności nieewidencjonowanej (",
            sprintf("%.0f", [0.50 * input.thresholds.bounds.minimum_wage]),
            " PLN) — wymagana rejestracja CEIDG"
        ])],
        "_legal_basis": "Art. 5 Prawa przedsiębiorców"
    }
}
```

---

# CZĘŚĆ XII: KSH — Kodeks spółek handlowych (P170)

---

### P170: `ksh_dividend_capability_check`

**Cel biznesowy:** Weryfikacja zdolności dywidendowej spółki z o.o. — kapitał własny > kapitał zakładowy + kapitał zapasowy.

**Przesłanki:**
- `input.company.legal_form` == `"SP_ZOO"`
- `input.invoice.expense_type` == `"DIVIDEND"`
- `input.company.equity` < (`input.company.share_capital` + `input.company.reserve_capital`)

**Rezultat:**
- `dividend_blocked: true`
- `_warning: "Brak zdolności dywidendowej — kapitał własny niższy niż wymagany"`

**Podstawa prawna:** Art. 192 KSH

**Pseudokod Rego:**
```rego
# ── P170: ksh_dividend_capability_check ─────────────────────────
# Cel biznesowy: Zdolność dywidendowa spółki
# Przesłanki: SP_ZOO AND DIVIDEND AND equity < share_capital + reserve
# Podstawa prawna: Art. 192 KSH
# Priorytet: 170
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.legal_form == "SP_ZOO"
    input.invoice.expense_type == "DIVIDEND"
    input.company.equity < (input.company.share_capital + input.company.reserve_capital)
    verdict := {
        "matched": true,
        "rule_id": "compliance.ksh.dividend_capability",
        "package": "compliance.ksh",
        "priority": 170,
        "dividend_blocked": true,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Brak zdolności dywidendowej — naruszenie Art. 192 KSH",
        "_legal_basis": "Art. 192 KSH"
    }
}
```

---

# CZĘŚĆ XIII: ORDYNACJA — Korekty (P180)

---

### P180: `ord_correction_lock_during_audit`

**Cel biznesowy:** Blokada automatycznych korekt deklaracji w trakcie aktywnej kontroli podatkowej.

**Przesłanki:**
- `input.company.under_tax_audit` == `true`
- `input.invoice.is_correction` == `true`
- Rok podatkowy korekty == rok objęty kontrolą

**Rezultat:**
- `correction_blocked: true`
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Korekta zablokowana — aktywna kontrola podatkowa"`

**Podstawa prawna:** Art. 81b § 1 Ordynacji podatkowej

**Pseudokod Rego:**
```rego
# ── P180: ord_correction_lock_during_audit ──────────────────────
# Cel biznesowy: Blokada korekty w trakcie kontroli
# Przesłanki: under_tax_audit AND is_correction
# Podstawa prawna: Art. 81b § 1 Ordynacji podatkowej
# Priorytet: 180
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.under_tax_audit == true
    input.invoice.is_correction == true
    verdict := {
        "matched": true,
        "rule_id": "compliance.ordynacja.correction_lock",
        "package": "compliance.ordynacja",
        "priority": 180,
        "correction_blocked": true,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": concat("", [
            "Korekta deklaracji zablokowana — aktywna kontrola podatkowa za rok ",
            input.company.audit_year
        ]),
        "_legal_basis": "Art. 81b § 1 Ordynacji podatkowej"
    }
}
```

---

# Podsumowanie rozszerzenia

| Domena | Nowe reguły | Priorytety |
|--------|:-----------:|------------|
| PPK | 2 | P110-P111 |
| Akcyza | 3 | P115-P117 |
| IFRS / MSSF | 3 | P120-P122 |
| Leasing (CIT/PIT) | 3 | P125-P127 |
| Darowizny | 3 | P130-P132 |
| KŚT szczegółowe | 5 | P135-P139 |
| KUP — wyłączenia | 3 | P140-P142 |
| JPK — znaczniki | 3 | P145-P147 |
| AML | 3 | P150-P152 |
| Prawo dewizowe (NBP) | 1 | P155 |
| CEIDG / Przedsiębiorcy | 2 | P160-P165 |
| KSH | 1 | P170 |
| Ordynacja — korekty | 1 | P180 |
| **RAZEM** | **33** | **P110-P180** |

**Całkowite pokrycie: 95 (bazowe) + 33 (rozszerzenie) = 128 reguł w 25 domenach prawnych.**

---

> **Następny krok:** `08_OPA_PATTERNS_FROM_RESEARCH.md` — wzorce architektoniczne z FINOS, OpenFisca i OPA library.
