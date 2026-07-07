# 📋 Szczegółowy Opis Reguł — Pseudokod Rego

> **Status:** Dokumentacja v1.0  
> **Data:** 2026-07-07  
> **Powiązany:** `Plan OPA/00_PLAN_STRUKTURA.md`

---

## Pakiet: `tax.risk` — Ryzyko i Fraud (P0-P9)

---

### P0: `fraud_graph_match`

**Cel biznesowy:** Natychmiastowa blokada faktury od kontrahenta zidentyfikowanego w sieci fraudowej VAT.

**Przesłanki:**
- `input.vendor.fraud_flag` == `true`

**Rezultat:**
- `matched: true`
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Kontrahent w sieci fraudowej VAT"`
- `fraud_detected: true`

**Podstawa prawna:** Art. 86 ust. 1 ustawy o VAT, Art. 55 KKS

**Pseudokod Rego:**
```rego
# ── P0: fraud_graph_match ─────────────────────────────────────
# Cel biznesowy: Blokada faktury od kontrahenta w sieci fraudowej VAT
# Przesłanki: vendor.fraud_flag == true
# Podstawa prawna: Art. 86 ust. 1 VAT, Art. 55 KKS
# Priorytet: 0
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.fraud_flag == true
    verdict := {
        "matched": true,
        "rule_id": "tax.risk.fraud_graph_match",
        "package": "tax.risk",
        "priority": 0,
        "vat_rate": "",
        "rounding_level": "",
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Kontrahent w sieci fraudowej VAT",
        "_legal_basis": "Art. 86 ust. 1 VAT, Art. 55 KKS",
        "fraud_detected": true
    }
}
```

---

### P2: `anomaly_amount`

**Cel biznesowy:** Wykrycie anomalii kwotowej — kwota netto przekracza średnią historyczną dla danej kategorii o więcej niż 3 odchylenia standardowe.

**Przesłanki:**
- `input.invoice.amount_net` > (średnia_kategorii + 3 × odchylenie_standardowe)
- Uwaga: średnia i odchylenie muszą być dostarczone jako dodatkowe pola w input (np. `input.invoice.category_avg_amount`, `input.invoice.category_stddev_amount`)

**Rezultat:**
- `matched: true`
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Kwota przekracza 3σ od średniej dla kategorii"`
- `_anomaly_zscore: <wartość>`

**Podstawa prawna:** Art. 22 UoR (zasada ostrożności)

**Pseudokod Rego:**
```rego
# ── P2: anomaly_amount ────────────────────────────────────────
# Cel biznesowy: Wykrycie anomalii kwotowej >3σ
# Przesłanki: amount_net > (avg + 3*stddev)
# Podstawa prawna: Art. 22 UoR
# Priorytet: 2
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.category_avg_amount
    input.invoice.category_stddev_amount
    input.invoice.amount_net > input.invoice.category_avg_amount + 3 * input.invoice.category_stddev_amount
    verdict := {
        "matched": true,
        "rule_id": "tax.risk.anomaly_amount",
        "package": "tax.risk",
        "priority": 2,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Kwota przekracza 3σ od średniej dla kategorii",
        "_legal_basis": "Art. 22 UoR (zasada ostrożności)",
        "_anomaly_zscore": (input.invoice.amount_net - input.invoice.category_avg_amount) / input.invoice.category_stddev_amount
    }
}
```

---

### P5: `semantic_guard_disallowed`

**Cel biznesowy:** Wykrycie wydatków oczywiście niezwiązanych z działalnością gospodarczą (alkohol powyżej limitu reprezentacji, wydatki na rozrywkę).

**Przesłanki:**
- `input.invoice.category_code` in `["ALCOHOL", "ENTERTAINMENT", "LUXURY"]`
- `input.invoice.expense_type` != `"REPRESENTATION"` (reprezentacja ma osobny limit)

**Rezultat:**
- `matched: true`
- `income_tax_qualification: "non_deductible"`
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Wydatek niezwiązany z działalnością gospodarczą"`

**Podstawa prawna:** Art. 23 ust. 1 pkt 23 PIT, Art. 16 ust. 1 pkt 28 CIT

**Pseudokod Rego:**
```rego
# ── P5: semantic_guard_disallowed ─────────────────────────────
# Cel biznesowy: Wydatki niezwiązane z działalnością
# Przesłanki: Kategoria ALCOHOL/ENTERTAINMENT/LUXURY
# Podstawa prawna: Art. 23 ust. 1 pkt 23 PIT, Art. 16 ust. 1 pkt 28 CIT
# Priorytet: 5
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.category_code in ["ALCOHOL", "ENTERTAINMENT", "LUXURY"]
    input.invoice.expense_type != "REPRESENTATION"
    verdict := {
        "matched": true,
        "rule_id": "tax.risk.semantic_guard_disallowed",
        "package": "tax.risk",
        "priority": 5,
        "income_tax_qualification": "non_deductible",
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Wydatek niezwiązany z działalnością gospodarczą",
        "_legal_basis": "Art. 23 ust. 1 pkt 23 PIT, Art. 16 ust. 1 pkt 28 CIT"
    }
}
```

---

## Pakiet: `tax.routing` — Field Confidence (P10-P19)

---

### P10-P19: Field Confidence Rules

**Ogólny wzorzec dla wszystkich reguł FC:**

```rego
# ── P10: fc_vat_rate_low ──────────────────────────────────────
# Cel biznesowy: Niska pewność stawki VAT → BLOCK_AND_ALERT
# Przesłanki: CIT_STANDARD + fc_vat_rate < próg
# Priorytet: 10
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.tax_form == "CIT_STANDARD"
    input.confidence.fc_vat_rate < input.thresholds.fc_thresholds.cit_standard_vat_rate
    input.confidence.fc_vat_rate > 0
    verdict := {
        "matched": true,
        "rule_id": "tax.routing.fc_vat_rate_low",
        "package": "tax.routing",
        "priority": 10,
        "vat_rate": "0.23",
        "rounding_level": "position",
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": concat("", [
            input.company.tax_form,
            ": VAT rate confidence ",
            sprintf("%.2f", [input.confidence.fc_vat_rate]),
            " below threshold ",
            sprintf("%.2f", [input.thresholds.fc_thresholds.cit_standard_vat_rate])
        ])
    }
}
```

**Mapa wszystkich reguł FC:**

| Reguła | Forma podatkowa | Pole confidence | Próg z thresholds | Routing |
|---|---|---|---|---|
| P10 | CIT_STANDARD | `fc_vat_rate` | `fc_thresholds.cit_standard_vat_rate` | BLOCK_AND_ALERT |
| P11 | CIT_STANDARD | `fc_total_net` | `fc_thresholds.cit_standard_total_net` | BLOCK_AND_ALERT |
| P12 | CIT_STANDARD | `fc_minimum` | `fc_thresholds.cit_standard_minimum` | BLOCK_AND_ALERT |
| P13 | CIT_ESTONIAN | `fc_vat_rate` | `fc_thresholds.cit_estonian_vat_rate` | BLOCK_AND_ALERT |
| P14 | LINEAR | `fc_minimum` | `fc_thresholds.linear_minimum` | TRIAGE_QUEUE |
| P15 | LUMP_SUM | `fc_vat_rate` | `fc_thresholds.lump_sum_vat_rate` | TRIAGE_QUEUE |
| P16 | LUMP_SUM | `fc_total_net` | `fc_thresholds.lump_sum_total_net` | TRIAGE_QUEUE |
| P17 | (category) MIXED_AUTO | `fc_minimum` | `fc_thresholds.mixed_auto_minimum` | BLOCK_AND_ALERT |
| P18 | (category) REPRESENTATION | `fc_minimum` | `fc_thresholds.representation_minimum` | BLOCK_AND_ALERT |
| P19-1 | (universal) | `fc_vendor_nip` | `fc_thresholds.vendor_nip` | BLOCK_AND_ALERT |
| P19-2 | (universal) | `fc_category_code` | `fc_thresholds.category_code` | TRIAGE_QUEUE |
| P19-3 | (universal) | `fc_minimum` | `fc_thresholds.global_minimum` | TRIAGE_QUEUE |

---

## Pakiet: `tax.compliance` — Zgodność dokumentacyjna (P20-P39)

---

### P20: `whitelist_missing_over_limit`

**Cel biznesowy:** Weryfikacja Białej Listy MF — blokada gdy kontrahent nie figuruje na WL dla przelewów >15 000 PLN.

**Pseudokod Rego:**
```rego
# ── P20: whitelist_missing_over_limit ─────────────────────────
# Cel biznesowy: Brak kontrahenta na Białej Liście MF >15k PLN
# Przesłanki: amount_gross >= mpp_limit AND !on_whitelist
# Podstawa prawna: Art. 96b VAT, Art. 117ba Ordynacji podatkowej
# Priorytet: 20
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.amount_gross >= input.thresholds.limits.mpp_limit
    input.vendor.on_whitelist == false
    verdict := {
        "matched": true,
        "rule_id": "tax.compliance.whitelist_missing",
        "package": "tax.compliance",
        "priority": 20,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Brak kontrahenta na Białej Liście MF dla przelewu >15 000 PLN",
        "_legal_basis": "Art. 96b VAT, Art. 117ba Ordynacji podatkowej",
        "_warnings": ["Brak na Białej Liście — odpowiedzialność solidarna"]
    }
}
```

---

### P25: `split_payment_mandatory`

**Cel biznesowy:** Obowiązkowy MPP dla faktur >15k PLN brutto, gdy towary/usługi z załącznika nr 15.

**Pseudokod Rego:**
```rego
# ── P25: split_payment_mandatory ──────────────────────────────
# Cel biznesowy: Obowiązkowy MPP dla towarów wrażliwych
# Przesłanki: amount_gross >= mpp_limit AND gtu_sensitive
# Podstawa prawna: Art. 108a VAT
# Priorytet: 25
# ────────────────────────────────────────────────────────────────

# GTU kody wymagające MPP (załącznik nr 15 do ustawy o VAT)
gtu_sensitive {
    input.invoice.category_code in [
        "FUEL",          # GTU_04 — paliwa
        "STEEL",         # GTU_05 — stal, złom
        "ELECTRONICS",   # GTU_01 — elektronika
        "CONSTRUCTION",  # GTU_08 — roboty budowlane
    ]
}

decide = verdict {
    input.invoice.amount_gross >= input.thresholds.limits.mpp_limit
    gtu_sensitive
    verdict := {
        "matched": true,
        "rule_id": "tax.compliance.split_payment_mandatory",
        "package": "tax.compliance",
        "priority": 25,
        "mpp_required": true,
        "_warnings": ["Obowiązkowy mechanizm podzielonej płatności (MPP)"],
        "_legal_basis": "Art. 108a ustawy o VAT"
    }
}
```

---

### P35: `cash_transaction_over_limit`

**Cel biznesowy:** Płatność gotówkowa >15k PLN → brak możliwości zaliczenia do kosztów uzyskania przychodu.

**Pseudokod Rego:**
```rego
# ── P35: cash_transaction_over_limit ──────────────────────────
# Cel biznesowy: Płatność gotówkowa > limit → brak KUP
# Przesłanki: is_cash_payment AND amount_gross >= cash_limit
# Podstawa prawna: Art. 22p PIT, Art. 15d CIT
# Priorytet: 35
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.is_cash_payment == true
    input.invoice.amount_gross >= input.thresholds.limits.cash_transaction_limit
    verdict := {
        "matched": true,
        "rule_id": "tax.compliance.cash_over_limit",
        "package": "tax.compliance",
        "priority": 35,
        "income_tax_qualification": "non_deductible",
        "_warnings": ["Płatność gotówkowa powyżej 15 000 PLN — brak KUP"],
        "_legal_basis": "Art. 22p PIT, Art. 15d CIT"
    }
}
```

---

## Pakiet: `tax.crossborder` — Transgraniczne (P40-P49)

---

### P40: `eu_reverse_charge`

**Cel biznesowy:** Wewnątrzwspólnotowe nabycie towarów — reverse charge (0% VAT u sprzedawcy, rozlicza nabywca).

**Pseudokod Rego:**
```rego
# ── P40: eu_reverse_charge ─────────────────────────────────────
# Cel biznesowy: WDT — reverse charge dla UE
# Przesłanki: vendor.country == EU AND vendor.vat_status == active
# Podstawa prawna: Art. 17 ust. 1 pkt 3 VAT
# Priorytet: 40
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.country == "EU"
    input.vendor.vat_status == "active"
    verdict := {
        "matched": true,
        "rule_id": "tax.crossborder.eu_reverse_charge",
        "package": "tax.crossborder",
        "priority": 40,
        "vat_rate": "0.00",
        "rounding_level": "total",
        "gtu_code": "GTU_12",
        "procedure": "VAT_REVERSE_CHARGE",
        "_legal_basis": "Art. 17 ust. 1 pkt 3 ustawy o VAT"
    }
}
```

---

### P45: `import_non_eu`

**Cel biznesowy:** Import towarów spoza UE — 23% VAT naliczany przez urząd celny.

**Pseudokod Rego:**
```rego
# ── P45: import_non_eu ────────────────────────────────────────
# Cel biznesowy: Import spoza UE → 23% VAT
# Przesłanki: vendor.country == NON_EU
# Podstawa prawna: Art. 17 ust. 1 pkt 1 VAT
# Priorytet: 45
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.country == "NON_EU"
    verdict := {
        "matched": true,
        "rule_id": "tax.crossborder.import_non_eu",
        "package": "tax.crossborder",
        "priority": 45,
        "vat_rate": "0.23",
        "rounding_level": "position",
        "gtu_code": "GTU_13",
        "procedure": "IMPORT",
        "_legal_basis": "Art. 17 ust. 1 pkt 1, Art. 41 ust. 1 ustawy o VAT"
    }
}
```

---

## Pakiet: `tax.vat.substantive` — VAT Merytoryczny (P50-P69)

---

### P52-57: Stawki VAT wg kategorii

**Wzorzec reguł stawkowych:**

```rego
# ── P52: vat_rate_fuel_pl ─────────────────────────────────────
# Cel biznesowy: Paliwo w PL → 23% VAT + GTU_04
# Przesłanki: category_code == FUEL AND vendor.country == PL
# Podstawa prawna: Art. 41 ust. 1 VAT, § 10 rozp. JPK
# Priorytet: 52
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.category_code == "FUEL"
    input.vendor.country == "PL"
    input.invoice.transaction_date >= "2024-01-01"
    verdict := {
        "matched": true,
        "rule_id": "tax.vat.substantive.fuel_pl_23",
        "package": "tax.vat.substantive",
        "priority": 52,
        "vat_rate": "0.23",
        "rounding_level": "position",
        "gtu_code": "GTU_04",
        "_legal_basis": "Art. 41 ust. 1 VAT"
    }
}
```

**Mapa kategorii → stawki:**

| Reguła | Kategoria | Vendor Country | VAT | GTU | Podstawa prawna |
|---|---|---|---|---|---|
| P52 | FUEL | PL | 0.23 | GTU_04 | Art. 41 ust. 1 VAT |
| P53 | FOOD | PL | 0.08 | GTU_07 | Art. 41 ust. 2 VAT |
| P54 | BOOKS | PL | 0.05 | GTU_01 | Art. 41 ust. 2a VAT |
| P55 | EDUCATION | PL | 0.00 | — | Art. 43 ust. 1 pkt 26-29 VAT |
| P56 | HEALTHCARE | PL | 0.00 | — | Art. 43 ust. 1 pkt 18-20 VAT |
| P57 | FINANCE | PL | 0.00 | — | Art. 43 ust. 1 pkt 7, 37-41 VAT |
| P58 | IT_OFFICE | PL | 0.23 | GTU_01 | Art. 41 ust. 1 VAT |
| P59 | CONSTRUCTION | PL | 0.23 | GTU_08 | Art. 41 ust. 1 VAT |
| P60 | TRANSPORT | PL | 0.23 | GTU_06 | Art. 41 ust. 1 VAT |

---

### P65: `vat_gtu_mapping`

**Cel biznesowy:** Automatyczne mapowanie kategorii wydatku na kod GTU dla JPK_V7.

**Pseudokod Rego:**
```rego
# ── P65: gtu_mapping_by_category ──────────────────────────────
# Cel biznesowy: Mapowanie kategorii → kod GTU
# Podstawa prawna: § 10 rozp. w sprawie JPK_VAT
# Priorytet: 65
# ────────────────────────────────────────────────────────────────

# Mapa kategorii na kody GTU
gtu_code = "GTU_04" {
    input.invoice.category_code == "FUEL"
} else = "GTU_01" {
    input.invoice.category_code in ["IT_OFFICE", "ELECTRONICS"]
} else = "GTU_07" {
    input.invoice.category_code == "FOOD"
} else = "GTU_08" {
    input.invoice.category_code == "CONSTRUCTION"
} else = "GTU_06" {
    input.invoice.category_code == "TRANSPORT"
} else = "GTU_02" {
    input.invoice.category_code == "ALCOHOL"
} else = "GTU_09" {
    input.invoice.category_code == "PHARMA"
} else = "GTU_10" {
    input.invoice.category_code == "REAL_ESTATE"
} else = "GTU_11" {
    input.invoice.category_code == "GAS_ENERGY"
} else = "" {
    true
}
```

---

### P60: `vat_bad_debt_relief`

**Cel biznesowy:** Ulga na złe długi — możliwość korekty VAT po 150 dniach od terminu płatności.

**Pseudokod Rego:**
```rego
# ── P60: bad_debt_relief ──────────────────────────────────────
# Cel biznesowy: Ulga na złe długi po 150 dniach
# Przesłanki: days_overdue >= bad_debt_days
# Podstawa prawna: Art. 89a VAT
# Priorytet: 60
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.days_overdue >= input.thresholds.limits.bad_debt_days
    input.invoice.is_paid == false
    verdict := {
        "matched": true,
        "rule_id": "tax.vat.substantive.bad_debt_relief",
        "package": "tax.vat.substantive",
        "priority": 60,
        "bad_debt_relief_eligible": true,
        "_legal_basis": "Art. 89a ustawy o VAT"
    }
}
```

---

## Pakiet: `tax.direct.pit` — PIT (P74-P79)

---

### P74: `pit_lump_sum_rate`

**Cel biznesowy:** Przypisanie stawki ryczałtu na podstawie kodu PKWiU.

**Pseudokod Rego:**
```rego
# ── P74: pit_lump_sum_rate ─────────────────────────────────────
# Cel biznesowy: Stawka ryczałtu wg PKWiU
# Przesłanki: tax_form == LUMP_SUM
# Podstawa prawna: Art. 12 ustawy o ryczałcie ewidencjonowanym
# Priorytet: 74
# ────────────────────────────────────────────────────────────────

# Stawki ryczałtu wg PKWiU
lump_sum_rate = input.thresholds.rates.pit_ip_box {
    input.invoice.pkwiu_code in ["62.01", "62.02", "62.03", "62.09"]
} else = "0.085" {
    input.invoice.pkwiu_code in ["01", "02", "03", "45", "46", "47"]
} else = "0.17" {
    true  # domyślnie 17%
}

decide = verdict {
    input.company.tax_form == "LUMP_SUM"
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.pit.lump_sum_rate",
        "package": "tax.direct.pit",
        "priority": 74,
        "pit_rate": lump_sum_rate,
        "_legal_basis": "Art. 12 ustawy o ryczałcie"
    }
}
```

---

### P75: `pit_tax_scale`

**Cel biznesowy:** Skala podatkowa PIT — 12% do 120 000 PLN, 32% powyżej.

**Pseudokod Rego:**
```rego
# ── P75: pit_tax_scale ────────────────────────────────────────
# Cel biznesowy: Skala podatkowa 12%/32%
# Przesłanki: tax_form == PIT_SCALE, dochód względem progu
# Podstawa prawna: Art. 27 ust. 1 PIT
# Priorytet: 75
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.tax_form == "PIT_SCALE"
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.pit.tax_scale",
        "package": "tax.direct.pit",
        "priority": 75,
        "pit_bracket_low": input.thresholds.rates.pit_scale_low,
        "pit_bracket_high": input.thresholds.rates.pit_scale_high,
        "pit_bracket_threshold": input.thresholds.bounds.pit_scale_threshold,
        "pit_tax_free_amount": input.thresholds.bounds.pit_tax_free_amount,
        "pit_tax_free_reduction": input.thresholds.bounds.pit_tax_free_reduction,
        "_legal_basis": "Art. 27 ust. 1 ustawy o PIT"
    }
}
```

---

## Pakiet: `tax.allowances` — Ulgi Podatkowe (P80-P89)

---

### P80: `relief_rd`

**Cel biznesowy:** Ulga B+R — odliczenie 100% (lub 200% dla CBR) kosztów kwalifikowanych.

**Pseudokod Rego:**
```rego
# ── P80: relief_rd ────────────────────────────────────────────
# Cel biznesowy: Ulga B+R 100%/200%
# Przesłanki: has_rd_status == true
# Podstawa prawna: Art. 26e PIT, Art. 18d CIT
# Priorytet: 80
# ────────────────────────────────────────────────────────────────

rd_relief_percent = input.thresholds.bounds.relief_rd_centrum {
    input.company.rd_is_centrum == true
} else = input.thresholds.bounds.relief_rd_base {
    input.company.rd_is_centrum == false
}

decide = verdict {
    input.company.has_rd_status == true
    verdict := {
        "matched": true,
        "rule_id": "tax.allowances.relief_rd",
        "package": "tax.allowances",
        "priority": 80,
        "relief_type": "RD",
        "relief_percent": rd_relief_percent,
        "_legal_basis": "Art. 26e PIT, Art. 18d CIT"
    }
}
```

---

### P82: `relief_ip_box`

**Cel biznesowy:** IP Box — preferencyjna stawka 5% od dochodów z kwalifikowanego IP.

**Pseudokod Rego:**
```rego
# ── P82: relief_ip_box ────────────────────────────────────────
# Cel biznesowy: IP Box — 5% od dochodów z IP
# Przesłanki: kategoria IT + PKWiU kwalifikowane
# Podstawa prawna: Art. 30ca PIT, Art. 24d CIT
# Priorytet: 82
# ────────────────────────────────────────────────────────────────

ip_box_eligible {
    input.invoice.category_code in ["IT_OFFICE", "SOFTWARE", "RND"]
    input.invoice.pkwiu_code in ["62.01", "62.02", "62.03"]
}

decide = verdict {
    ip_box_eligible
    verdict := {
        "matched": true,
        "rule_id": "tax.allowances.relief_ip_box",
        "package": "tax.allowances",
        "priority": 82,
        "relief_type": "IP_BOX",
        "pit_rate": input.thresholds.rates.pit_ip_box,
        "_legal_basis": "Art. 30ca PIT, Art. 24d CIT"
    }
}
```

---

### P85: `relief_thermomodernization`

**Cel biznesowy:** Ulga termomodernizacyjna — max 53 000 PLN.

**Pseudokod Rego:**
```rego
# ── P85: relief_thermomodernization ────────────────────────────
# Cel biznesowy: Ulga termomodernizacyjna — max 53k PLN
# Przesłanki: expense_type == THERMOMODERNIZATION
# Podstawa prawna: Art. 26h PIT
# Priorytet: 85
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "THERMOMODERNIZATION"
    verdict := {
        "matched": true,
        "rule_id": "tax.allowances.relief_thermo",
        "package": "tax.allowances",
        "priority": 85,
        "relief_type": "THERMOMODERNIZATION",
        "relief_max": input.thresholds.bounds.relief_thermo_max,
        "_legal_basis": "Art. 26h ustawy o PIT"
    }
}
```

---

## Pakiet: `tax.accounting` — Reguły Rachunkowe (P90-P94)

---

### P90: `acc_depreciation_linear`

**Cel biznesowy:** Amortyzacja liniowa — podstawowa metoda dla środków trwałych.

**Pseudokod Rego:**
```rego
# ── P90: acc_depreciation_linear ──────────────────────────────
# Cel biznesowy: Amortyzacja liniowa
# Przesłanki: expense_type == FIXED_ASSET, metoda liniowa
# Podstawa prawna: Art. 32 ust. 1 UoR, KŚT
# Priorytet: 90
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "FIXED_ASSET"
    input.invoice.depreciation_method == "LINEAR"
    verdict := {
        "matched": true,
        "rule_id": "tax.accounting.depreciation_linear",
        "package": "tax.accounting",
        "priority": 90,
        "depreciation_method": "LINEAR",
        "_legal_basis": "Art. 32 ust. 1 UoR"
    }
}
```

---

### P93: `acc_fx_revaluation`

**Cel biznesowy:** Konieczność rewaluacji walutowej na dzień bilansowy.

**Pseudokod Rego:**
```rego
# ── P93: acc_fx_revaluation ────────────────────────────────────
# Cel biznesowy: Rewaluacja walutowa dla faktur w walucie obcej
# Przesłanki: currency != PLN
# Podstawa prawna: Art. 30 UoR, IAS 21
# Priorytet: 93
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.currency != "PLN"
    verdict := {
        "matched": true,
        "rule_id": "tax.accounting.fx_revaluation",
        "package": "tax.accounting",
        "priority": 93,
        "fx_revaluation_required": true,
        "_legal_basis": "Art. 30 UoR, IAS 21"
    }
}
```

---

## Pakiet: `tax.zus` — Składki ZUS (P95-P99)

---

### P95: `zus_maly_plus`

**Cel biznesowy:** Mały ZUS Plus — obniżona podstawa wymiaru składek (30% minimalnego wynagrodzenia) przez 36 miesięcy.

**Pseudokod Rego:**
```rego
# ── P95: zus_maly_plus ────────────────────────────────────────
# Cel biznesowy: Mały ZUS Plus — obniżona podstawa
# Przesłanki: zus_status == MALY_ZUS_PLUS AND months_used < 36
# Podstawa prawna: Art. 18c SUS
# Priorytet: 95
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.zus_status == "MALY_ZUS_PLUS"
    input.company.zus_months_used < input.thresholds.bounds.zus_maly_plus_months
    verdict := {
        "matched": true,
        "rule_id": "tax.zus.maly_plus",
        "package": "tax.zus",
        "priority": 95,
        "zus_base_percent": input.thresholds.bounds.zus_maly_plus_min_wage_percent,
        "_legal_basis": "Art. 18c ustawy o SUS"
    }
}
```

---

### P98: `zus_health_contrib`

**Cel biznesowy:** Ustalenie stawki składki zdrowotnej: 9% dla skali podatkowej, 4.9% dla liniowego i ryczałtu.

**Pseudokod Rego:**
```rego
# ── P98: zus_health_contrib ────────────────────────────────────
# Cel biznesowy: Składka zdrowotna 9% / 4.9%
# Przesłanki: zależne od formy opodatkowania
# Podstawa prawna: Art. 79-81 ustawy zdrowotnej
# Priorytet: 98
# ────────────────────────────────────────────────────────────────

health_rate = input.thresholds.rates.zus_health {
    input.company.tax_form == "PIT_SCALE"
} else = input.thresholds.rates.zus_health_lump {
    input.company.tax_form in ["LINEAR", "LUMP_SUM"]
} else = input.thresholds.rates.zus_health {
    true
}

decide = verdict {
    verdict := {
        "matched": true,
        "rule_id": "tax.zus.health_contrib",
        "package": "tax.zus",
        "priority": 98,
        "zus_health_rate": health_rate,
        "_legal_basis": "Art. 79-81 ustawy o świadczeniach opieki zdrowotnej"
    }
}
```

---

## Pakiet: `tax.fallback` — Reguły Domyślne (P100+)

---

### P100: `domestic_fallback`

**Cel biznesowy:** Domyślna stawka VAT 23% dla polskich kontrahentów, gdy żadna konkretna reguła nie pasuje.

**Pseudokod Rego:**
```rego
# ── P100: domestic_fallback ────────────────────────────────────
# Cel biznesowy: Domyślna stawka VAT 23% dla PL
# Przesłanki: vendor.country == PL
# Podstawa prawna: Art. 41 ust. 1 VAT
# Priorytet: 100
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.country == "PL"
    input.invoice.transaction_date >= "2024-01-01"
    verdict := {
        "matched": true,
        "rule_id": "tax.fallback.domestic",
        "package": "tax.fallback",
        "priority": 100,
        "vat_rate": input.thresholds.rates.vat_standard,
        "rounding_level": "position",
        "gtu_code": "",
        "procedure": "",
        "_legal_basis": "Art. 41 ust. 1 ustawy o VAT"
    }
}
```

---

### P200: `no_match` (default decide)

**Cel biznesowy:** Ostateczny fallback — zawsze na końcu łańcucha.

```rego
default decide = {
    "matched": false,
    "rule_id": "tax.fallback.no_match",
    "package": "tax.fallback",
    "priority": 200,
    "error": "NO_MATCHING_RULE"
}
```

---

## 6. Wzorzec werdyktu — pełna struktura

Każda reguła zwraca ustandaryzowany obiekt werdyktu:

```rego
# Wzorzec struktury werdyktu
verdict_template := {
    # ── Pola obowiązkowe ──
    "matched": true,                     # bool: czy reguła dopasowana
    "rule_id": "tax.<pkg>.<name>",       # string: unikalny identyfikator
    "package": "tax.<pkg>",              # string: pakiet źródłowy
    "priority": 0,                       # number: priorytet (niższy = ważniejszy)

    # ── VAT ──
    "vat_rate": "0.23",                  # string: stawka VAT ("0.23", "0.08", "0.05", "0.00")
    "rounding_level": "position",        # string: "position" | "total"
    "gtu_code": "GTU_04",               # string: kod GTU lub ""
    "procedure": "",                     # string: "VAT_REVERSE_CHARGE" | "IMPORT" | "MARGIN" | "WDT" | "EXPORT" | ""

    # ── Podatek dochodowy ──
    "income_tax_qualification": "deductible_full",  # string: "deductible_full" | "deductible_partial" | "non_deductible"
    "pit_rate": "",                      # string: stawka PIT (dla LUMP_SUM, IP_BOX)
    "pit_bracket_low": "",               # string: dolna stawka PIT
    "pit_bracket_high": "",              # string: górna stawka PIT

    # ── Routing ──
    "_routing": "",                      # string: "" | "BLOCK_AND_ALERT" | "TRIAGE_QUEUE"
    "_routing_reason": "",              # string: czytelny powód routingu

    # ── Ulgi ──
    "relief_type": "",                   # string: "RD" | "IP_BOX" | "PROTOTYPE" | "THERMO" | etc.
    "relief_percent": 0,                # number: procent ulgi
    "relief_max": 0,                    # number: maksymalna kwota ulgi

    # ── Compliance ──
    "mpp_required": false,              # bool: czy wymagany MPP
    "bad_debt_relief_eligible": false,  # bool: czy ulga na złe długi

    # ── Księgowe ──
    "depreciation_method": "",          # string: "LINEAR" | "DEGRESSIVE" | "NATURAL"
    "fx_revaluation_required": false,   # bool: czy wymagana rewaluacja FX

    # ── ZUS ──
    "zus_health_rate": "",              # string: stawka składki zdrowotnej
    "zus_base_percent": 0,             # number: % podstawy wymiaru (dla Małego ZUS)

    # ── Audyt ──
    "_legal_basis": "",                 # string: podstawa prawna
    "_warnings": [],                    # array: lista ostrzeżeń
}
```

---

## 7. Struktura plików Rego — finalna architektura

```
policies/
├── tax/
│   ├── _helpers.rego          # Funkcje pomocnicze (gtu_code, health_rate, itd.)
│   ├── risk.rego               # P0-P9: Fraud, anomalie, semantic guard
│   ├── routing.rego            # P10-P19: Field confidence
│   ├── compliance.rego         # P20-P39: Biała lista, MPP, KSeF
│   ├── crossborder.rego        # P40-P49: UE reverse charge, import, export
│   ├── vat/
│   │   ├── substantive.rego    # P50-P64: Stawki VAT wg kategorii
│   │   └── gtu.rego            # P65-P69: Mapowanie GTU
│   ├── direct/
│   │   ├── cit.rego            # P70-P73: CIT
│   │   └── pit.rego            # P74-P79: PIT
│   ├── allowances.rego         # P80-P89: Ulgi podatkowe
│   ├── accounting.rego         # P90-P94: Amortyzacja, FIFO, FX
│   ├── zus.rego                # P95-P99: Składki ZUS
│   └── fallback.rego           # P100+: Domyślne
└── main.rego                   # Główny pakiet: importuje wszystkie, scala w jeden else-chain
```

### `main.rego` — układ scalający

```rego
package tax

# Import wszystkich sub-pakietów
import data.tax.risk
import data.tax.routing
import data.tax.compliance
import data.tax.crossborder
import data.tax.vat.substantive
import data.tax.vat.gtu
import data.tax.direct.cit
import data.tax.direct.pit
import data.tax.allowances
import data.tax.accounting
import data.tax.zus
import data.tax.fallback

# default decide
default decide = {
    "matched": false,
    "rule_id": "tax.fallback.no_match",
    "package": "tax.fallback",
    "priority": 200,
    "error": "NO_MATCHING_RULE"
}

# Uwaga: else-chain scala wszystkie sub-pakiety w jeden ciąg first-match-wins
```

---

> **Następny krok:** Implementacja fazy 0 → 1: rozszerzenie istniejącego `tax/rules.rego` o compliance i cross-border.
