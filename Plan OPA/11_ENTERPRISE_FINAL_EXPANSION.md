# Enterprise Final Expansion — 36 nowych reguł (P230-P265)

> **Status:** Dokumentacja ENTERPRISE v5.0
> **Data:** 2026-07-07
> **Powiązany:** `09_LEGAL_DEEP_DIVE_RULES.md`, `10_OPA_IMPLEMENTATION_GUIDE.md`
> **Uwaga:** 36 nowych reguł z 18 wcześniej niepokrytych obszarów. Łącznie **191 reguł**.

> **⚠️ Rozszerzenia input:** Wszystkie nowe pola `input.*` użyte w tych regułach wymagają dodania do `01_INPUT_SPEC.md`. Pełna lista: `input.invoice.is_continuous_service`, `invoice_type`, `discount_amount`, `has_returnable_packaging`, `packaging_returned`, `days_since_delivery`, `delivery_date`, `issue_date`, `is_due`, `is_paid`, `language`, `days_since_issue`, `is_correction`, `modifies_closed_vat_period`, `activity_location`, `currency`, `fx_rate_payment`, `fx_rate_invoice`, `withholding_tax_applicable`, `is_cabotage`, `days_overdue`; `input.company.uses_simplified_advances`, `chooses_quarterly_advances`, `status`, `total_assets_eur`, `net_revenue_eur`, `is_accounting_month_closed`, `audit_required`, `legal_form`, `has_ure_concession`, `energy_source`, `uses_full_accounting`, `owns_guard_dog`, `is_dog_registered_in_municipality`; `input.vendor.has_residence_certificate`, `has_transport_license`, `is_b2b_buyer`, `is_b2c`; oraz nowe klucze top-level: `input.tax_type`, `input.document`, `input.system`, `input.request`.

---

## Nowe domeny w tym dokumencie

| # | Domena | Reguły | Priorytety |
|---|--------|:---:|------------|
| 1 | VAT — obowiązek podatkowy (Art. 19a-21) | 2 | P230-P231 |
| 2 | VAT — podstawa opodatkowania (Art. 29a-32) | 2 | P232-P233 |
| 3 | PIT — źródła przychodów (Art. 10, 14) | 2 | P234-P235 |
| 4 | PIT/CIT — zaliczki na podatek | 2 | P236-P237 |
| 5 | CIT — przychody podatkowe (Art. 12) | 2 | P238-P239 |
| 6 | Ordynacja — terminy płatności (Art. 139) | 2 | P240-P241 |
| 7 | Ordynacja — odpowiedzialność (Art. 291-293) | 2 | P242-P243 |
| 8 | UoR — zasady rachunkowości (Art. 4-7) | 2 | P244-P245 |
| 9 | UoR — księgi rachunkowe (Art. 10-24) | 2 | P246-P247 |
| 10 | UoR — sprawozdania finansowe (Art. 35-45) | 2 | P248-P249 |
| 11 | UoR — przechowywanie (Art. 74) | 2 | P250-P251 |
| 12 | Prawo spółdzielcze | 2 | P252-P253 |
| 13 | Prawo energetyczne | 2 | P254-P255 |
| 14 | Transport drogowy | 2 | P256-P257 |
| 15 | KSeF szczegółowy | 2 | P258-P259 |
| 16 | JPK szczegółowy | 2 | P260-P261 |
| 17 | VAT — czynności (Art. 5-14, Miejsce świadczenia) | 2 | P262-P263 |
| 18 | Podatki lokalne szczegółowe | 2 | P264-P265 |

---

## 1. VAT — obowiązek podatkowy (P230-P231)

### P230: `vat_tax_point_continuous_service`

**Cel biznesowy:** Ustalenie momentu powstania obowiązku podatkowego dla usług o charakterze ciągłym (abonamenty, wynajem).

**Przesłanki:** `input.invoice.is_continuous_service == true`

**Rezultat:** `tax_point: "END_OF_PERIOD"`

**Podstawa prawna:** Art. 19a ust. 3 ustawy o VAT

**Pseudokod Rego:**
```rego
# P230: vat_tax_point_continuous_service
decide = verdict {
    input.invoice.is_continuous_service == true
    verdict := {"matched": true, "rule_id": "vat.tax_point.continuous",
        "package": "tax.vat.tax_point", "priority": 230,
        "tax_point": "END_OF_PERIOD",
        "_legal_basis": "Art. 19a ust. 3 VAT"}
}
```

### P231: `vat_tax_point_advance_invoice`

**Cel biznesowy:** Rozpoznanie obowiązku podatkowego w dacie zapłaty dla faktur zaliczkowych.

**Przesłanki:** `input.invoice.invoice_type == "ADVANCE"`

**Rezultat:** `tax_point: "PAYMENT_DATE"`

**Podstawa prawna:** Art. 19a ust. 8 ustawy o VAT

```rego
# P231: vat_tax_point_advance_invoice
decide = verdict {
    input.invoice.invoice_type == "ADVANCE"
    verdict := {"matched": true, "rule_id": "vat.tax_point.advance",
        "package": "tax.vat.tax_point", "priority": 231,
        "tax_point": "PAYMENT_DATE",
        "_legal_basis": "Art. 19a ust. 8 VAT"}
}
```

---

## 2. VAT — podstawa opodatkowania (P232-P233)

### P232: `vat_tax_base_discount`

**Cel biznesowy:** Pomniejszenie podstawy opodatkowania o udzielone rabaty i skonta.

**Przesłanki:** `input.invoice.discount_amount > 0`

**Rezultat:** `tax_base_adjusted` = netto minus rabat

**Podstawa prawna:** Art. 29a ust. 7 ustawy o VAT

```rego
# P232: vat_tax_base_discount
decide = verdict {
    input.invoice.discount_amount > 0
    verdict := {"matched": true, "rule_id": "vat.base.discount",
        "package": "tax.vat.base", "priority": 232,
        "tax_base_adjusted": input.invoice.amount_net - input.invoice.discount_amount,
        "_legal_basis": "Art. 29a ust. 7 VAT"}
}
```

### P233: `vat_tax_base_returnable_packaging`

**Cel biznesowy:** Doliczenie wartości niezwróconych opakowań zwrotnych po 60 dniach.

**Przesłanki:** Opakowania zwrotne niezwrócone, minęło 60 dni od dostawy

**Rezultat:** `packaging_taxable: true`

**Podstawa prawna:** Art. 29a ust. 11 i 12 ustawy o VAT

```rego
# P233: vat_tax_base_returnable_packaging
decide = verdict {
    input.invoice.has_returnable_packaging == true
    input.invoice.packaging_returned == false
    input.invoice.days_since_delivery > 60
    verdict := {"matched": true, "rule_id": "vat.base.packaging",
        "package": "tax.vat.base", "priority": 233,
        "packaging_taxable": true,
        "_legal_basis": "Art. 29a ust. 11-12 VAT"}
}
```

---

## 3. PIT — źródła przychodów (P234-P235)

### P234: `pit_revenue_recognition_date`

**Cel biznesowy:** Rozpoznanie przychodu na najwcześniejszą z dat: wydanie rzeczy, wykonanie usługi, wystawienie faktury.

**Przesłanki:** `input.invoice.delivery_date < input.invoice.issue_date`

**Rezultat:** `revenue_date` = data dostawy

**Podstawa prawna:** Art. 14 ust. 1c ustawy o PIT

```rego
# P234: pit_revenue_recognition_date
decide = verdict {
    input.invoice.delivery_date < input.invoice.issue_date
    verdict := {"matched": true, "rule_id": "pit.revenue.date",
        "package": "tax.direct.pit.revenue", "priority": 234,
        "revenue_date": input.invoice.delivery_date,
        "_legal_basis": "Art. 14 ust. 1c PIT"}
}
```

### P235: `pit_free_benefits_taxable`

**Cel biznesowy:** Opodatkowanie nieodpłatnych świadczeń na rzecz przedsiębiorcy.

**Przesłanki:** `input.invoice.expense_type == "FREE_BENEFIT_RECEIVED"`

**Rezultat:** `free_benefit_revenue: true`

**Podstawa prawna:** Art. 14 ust. 2 pkt 8 ustawy o PIT

```rego
# P235: pit_free_benefits_taxable
decide = verdict {
    input.invoice.expense_type == "FREE_BENEFIT_RECEIVED"
    verdict := {"matched": true, "rule_id": "pit.revenue.free_benefits",
        "package": "tax.direct.pit.revenue", "priority": 235,
        "free_benefit_revenue": true,
        "_legal_basis": "Art. 14 ust. 2 pkt 8 PIT"}
}
```

---

## 4. PIT/CIT — zaliczki na podatek (P236-P237)

### P236: `cit_advance_simplified`

**Cel biznesowy:** Wyliczenie uproszczonych zaliczek CIT (1/12 należnego z lat ubiegłych).

**Przesłanki:** `input.company.uses_simplified_advances == true`

**Rezultat:** `advance_method: "SIMPLIFIED"`

**Podstawa prawna:** Art. 25 ust. 6 CIT

```rego
# P236: cit_advance_simplified
decide = verdict {
    input.company.uses_simplified_advances == true
    verdict := {"matched": true, "rule_id": "cit.advances.simplified",
        "package": "tax.direct.cit.advances", "priority": 236,
        "advance_method": "SIMPLIFIED",
        "_legal_basis": "Art. 25 ust. 6 CIT"}
}
```

### P237: `pit_advance_quarterly`

**Cel biznesowy:** Kwartalne zaliczki PIT dla małych podatników.

**Przesłanki:** `input.company.is_small_taxpayer == true` AND `input.company.chooses_quarterly_advances == true`

**Rezultat:** `advance_frequency: "QUARTERLY"`

**Podstawa prawna:** Art. 44 ust. 3g PIT

```rego
# P237: pit_advance_quarterly
decide = verdict {
    input.company.is_small_taxpayer == true
    input.company.chooses_quarterly_advances == true
    verdict := {"matched": true, "rule_id": "pit.advances.quarterly",
        "package": "tax.direct.pit.advances", "priority": 237,
        "advance_frequency": "QUARTERLY",
        "_legal_basis": "Art. 44 ust. 3g PIT"}
}
```

---

## 5. CIT — przychody podatkowe (P238-P239)

### P238: `cit_fx_differences_positive`

**Cel biznesowy:** Podatkowe rozliczenie dodatnich różnic kursowych.

**Przesłanki:** Waluta != PLN, kurs zapłaty > kurs fakturowania

**Rezultat:** `fx_revenue_applicable: true`

**Podstawa prawna:** Art. 12 ust. 1, Art. 15a CIT

```rego
# P238: cit_fx_differences_positive
decide = verdict {
    input.invoice.currency != "PLN"
    input.invoice.fx_rate_payment > input.invoice.fx_rate_invoice
    verdict := {"matched": true, "rule_id": "cit.revenue.fx_positive",
        "package": "tax.direct.cit.revenue", "priority": 238,
        "fx_revenue_applicable": true,
        "_legal_basis": "Art. 15a CIT"}
}
```

### P239: `cit_revenue_due_unpaid`

**Cel biznesowy:** Zarachowanie przychodu należnego mimo braku zapłaty.

**Przesłanki:** Faktura wymagalna, niezapłacona

**Rezultat:** `cit_revenue_recognized: true`

**Podstawa prawna:** Art. 12 ust. 3 CIT

```rego
# P239: cit_revenue_due_unpaid
decide = verdict {
    input.invoice.is_due == true
    input.invoice.is_paid == false
    verdict := {"matched": true, "rule_id": "cit.revenue.due",
        "package": "tax.direct.cit.revenue", "priority": 239,
        "cit_revenue_recognized": true,
        "_legal_basis": "Art. 12 ust. 3 CIT"}
}
```

---

## 6. Ordynacja — terminy płatności (P240-P241)

### P240: `ord_vat_deadline`

**Cel biznesowy:** Termin płatności VAT — 25. dzień miesiąca.

**Przesłanki:** `input.tax_type == "VAT"`

**Rezultat:** `payment_deadline_day: 25`

**Podstawa prawna:** Art. 103 ust. 1 ustawy o VAT

```rego
# P240: ord_vat_deadline
decide = verdict {
    input.tax_type == "VAT"
    verdict := {"matched": true, "rule_id": "ord.deadline.vat",
        "package": "tax.compliance.ordynacja", "priority": 240,
        "payment_deadline_day": 25,
        "_legal_basis": "Art. 103 VAT"}
}
```

### P241: `ord_cit_deadline`

**Cel biznesowy:** Termin zaliczki CIT — 20. dzień miesiąca.

**Przesłanki:** `input.tax_type == "CIT_ADVANCE"`

**Rezultat:** `payment_deadline_day: 20`

**Podstawa prawna:** Art. 25 ust. 1a CIT

```rego
# P241: ord_cit_deadline
decide = verdict {
    input.tax_type == "CIT_ADVANCE"
    verdict := {"matched": true, "rule_id": "ord.deadline.cit",
        "package": "tax.compliance.ordynacja", "priority": 241,
        "payment_deadline_day": 20,
        "_legal_basis": "Art. 25 CIT"}
}
```

---

## 7. Ordynacja — odpowiedzialność (P242-P243)

### P242: `ord_liability_enterprise_buyer`

**Cel biznesowy:** Solidarna odpowiedzialność nabywcy przedsiębiorstwa/ZCP za zaległości podatkowe.

**Przesłanki:** `input.invoice.expense_type == "ENTERPRISE_ACQUISITION"`

**Rezultat:** `solidary_liability: true`, `_routing: "BLOCK_AND_ALERT"`

**Podstawa prawna:** Art. 112 Ordynacji podatkowej

```rego
# P242: ord_liability_enterprise_buyer
decide = verdict {
    input.invoice.expense_type == "ENTERPRISE_ACQUISITION"
    verdict := {"matched": true, "rule_id": "risk.ordynacja.buyer_liability",
        "package": "tax.risk.ordynacja", "priority": 242,
        "solidary_liability": true,
        "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Art. 112 Ordynacji"}
}
```

### P243: `ord_wht_remitter_liability`

**Cel biznesowy:** Odpowiedzialność płatnika za niepobrany podatek WHT (usługi niematerialne z zagranicy).

**Przesłanki:** WHT applicable, brak certyfikatu rezydencji

**Rezultat:** `remitter_liability_risk: true`, BLOCK_AND_ALERT

**Podstawa prawna:** Art. 30 Ordynacji podatkowej + Art. 26 CIT

```rego
# P243: ord_wht_remitter_liability
decide = verdict {
    input.invoice.withholding_tax_applicable == true
    input.vendor.has_residence_certificate == false
    verdict := {"matched": true, "rule_id": "risk.ordynacja.wht_liability",
        "package": "tax.risk.ordynacja", "priority": 243,
        "remitter_liability_risk": true,
        "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Art. 30 Ordynacji"}
}
```

---

## 8. UoR — zasady rachunkowości (P244-P245)

### P244: `uor_prudence_impairment`

**Cel biznesowy:** Odpis aktualizujący na przeterminowanych należnościach (zasada ostrożności).

**Przesłanki:** `input.invoice.days_overdue > 180`

**Rezultat:** `impairment_write_down_required: true`

**Podstawa prawna:** Art. 7 ust. 1 pkt 1 UoR

```rego
# P244: uor_prudence_impairment
decide = verdict {
    input.invoice.days_overdue > 180
    verdict := {"matched": true, "rule_id": "acc.uor.prudence",
        "package": "tax.accounting.uor", "priority": 244,
        "impairment_write_down_required": true,
        "_legal_basis": "Art. 7 ust. 1 UoR"}
}
```

### P245: `uor_going_concern_threat`

**Cel biznesowy:** Wycena likwidacyjna zamiast kontynuacji działalności przy upadłości.

**Przesłanki:** `input.company.status == "BANKRUPTCY"`

**Rezultat:** `valuation_method: "LIQUIDATION"`

**Podstawa prawna:** Art. 29 ust. 1 UoR

```rego
# P245: uor_going_concern_threat
decide = verdict {
    input.company.status == "BANKRUPTCY"
    verdict := {"matched": true, "rule_id": "acc.uor.going_concern",
        "package": "tax.accounting.uor", "priority": 245,
        "valuation_method": "LIQUIDATION",
        "_legal_basis": "Art. 29 ust. 1 UoR"}
}
```

---

## 9. UoR — księgi rachunkowe (P246-P247)

### P246: `uor_document_foreign_lang`

**Cel biznesowy:** Wymóg tłumaczenia dowodu księgowego w języku obcym.

**Przesłanki:** `input.invoice.language != "PL"`

**Rezultat:** `translation_on_demand: true`

**Podstawa prawna:** Art. 21 ust. 5 UoR

```rego
# P246: uor_document_foreign_lang
decide = verdict {
    input.invoice.language != "PL"
    verdict := {"matched": true, "rule_id": "acc.uor.language",
        "package": "tax.accounting.uor.books", "priority": 246,
        "translation_on_demand": true,
        "_legal_basis": "Art. 21 ust. 5 UoR"}
}
```

### P247: `uor_journal_entry_deadline`

**Cel biznesowy:** Kontrola terminowości księgowań — max 15 dni na ujęcie w dzienniku.

**Przesłanki:** `input.invoice.days_since_issue > 15`, miesiąc nie zamknięty

**Rezultat:** Ostrzeżenie "Zagrożenie terminowości księgowań"

**Podstawa prawna:** Art. 24 ust. 1 i 5 UoR

```rego
# P247: uor_journal_entry_deadline
decide = verdict {
    input.invoice.days_since_issue > 15
    input.company.is_accounting_month_closed == false
    verdict := {"matched": true, "rule_id": "acc.uor.journal_deadline",
        "package": "tax.accounting.uor.books", "priority": 247,
        "_warnings": ["Zagrozenie terminowosci ksiagowan dziennika"],
        "_legal_basis": "Art. 24 ust. 5 UoR"}
}
```

---

## 10. UoR — sprawozdania finansowe (P248-P249)

### P248: `uor_mandatory_audit`

**Cel biznesowy:** Obowiązek badania sprawozdania przez biegłego rewidenta (przekroczenie 2 z 3 progów).

**Przesłanki:** Aktywa >= 2.5M EUR, Przychód >= 5M EUR

**Rezultat:** `audit_required: true`

**Podstawa prawna:** Art. 64 UoR

```rego
# P248: uor_mandatory_audit
decide = verdict {
    input.company.total_assets_eur >= 2500000
    input.company.net_revenue_eur >= 5000000
    verdict := {"matched": true, "rule_id": "acc.uor.audit_mandatory",
        "package": "tax.accounting.uor.reports", "priority": 248,
        "audit_required": true,
        "_legal_basis": "Art. 64 UoR"}
}
```

### P249: `uor_cash_flow_statement_obligation`

**Cel biznesowy:** Obowiązek sporządzenia rachunku przepływów pieniężnych.

**Przesłanki:** `input.company.audit_required == true`

**Rezultat:** `cash_flow_required: true`

**Podstawa prawna:** Art. 45 ust. 3 UoR

```rego
# P249: uor_cash_flow_statement_obligation
decide = verdict {
    input.company.audit_required == true
    verdict := {"matched": true, "rule_id": "acc.uor.cash_flow",
        "package": "tax.accounting.uor.reports", "priority": 249,
        "cash_flow_required": true,
        "_legal_basis": "Art. 45 ust. 3 UoR"}
}
```

---

## 11. UoR — przechowywanie (P250-P251)

### P250: `uor_retention_books`

**Cel biznesowy:** Okres przechowywania dokumentacji księgowej — 5 lat.

**Przesłanki:** `input.document.type == "ACCOUNTING_PROOF"`

**Rezultat:** `retention_years: 5`

**Podstawa prawna:** Art. 74 ust. 2 UoR

```rego
# P250: uor_retention_books
decide = verdict {
    input.document.type == "ACCOUNTING_PROOF"
    verdict := {"matched": true, "rule_id": "compliance.uor.retention_5y",
        "package": "tax.compliance.retention", "priority": 250,
        "retention_years": 5,
        "_legal_basis": "Art. 74 ust. 2 UoR"}
}
```

### P251: `uor_retention_payroll`

**Cel biznesowy:** Wydłużony okres przechowywania akt płacowych — 10 lat.

**Przesłanki:** `input.document.type == "PAYROLL_RECORD"`

**Rezultat:** `retention_years: 10`

**Podstawa prawna:** Ustawa o SUS + Kodeks Pracy

```rego
# P251: uor_retention_payroll
decide = verdict {
    input.document.type == "PAYROLL_RECORD"
    verdict := {"matched": true, "rule_id": "compliance.uor.retention_payroll",
        "package": "tax.compliance.retention", "priority": 251,
        "retention_years": 10,
        "_legal_basis": "Okres przech. akt pracowniczych 10 lat"}
}
```

---

## 12. Prawo spółdzielcze (P252-P253)

### P252: `coop_housing_cit_exemption`

**Cel biznesowy:** Zwolnienie CIT dla spółdzielni mieszkaniowych z gospodarki zasobami mieszkaniowymi.

**Przesłanki:** `legal_form == "HOUSING_COOPERATIVE"`, `category_code == "HOUSING_MAINTENANCE"`

**Rezultat:** `cit_exempt: true`

**Podstawa prawna:** Art. 17 ust. 1 pkt 44 CIT

```rego
# P252: coop_housing_cit_exemption
decide = verdict {
    input.company.legal_form == "HOUSING_COOPERATIVE"
    input.invoice.category_code == "HOUSING_MAINTENANCE"
    verdict := {"matched": true, "rule_id": "special.coop.cit_exempt",
        "package": "tax.compliance.special", "priority": 252,
        "cit_exempt": true,
        "_legal_basis": "Art. 17 ust. 1 pkt 44 CIT"}
}
```

### P253: `coop_statutory_fund_allocation`

**Cel biznesowy:** Odpis zysku na obligatoryjny fundusz udziałowy spółdzielni.

**Przesłanki:** `legal_form == "COOPERATIVE"`, `net_profit_generated == true`

**Rezultat:** `statutory_fund_allocation_required: true`

**Podstawa prawna:** Art. 78 Prawa spółdzielczego

```rego
# P253: coop_statutory_fund_allocation
decide = verdict {
    input.company.legal_form == "COOPERATIVE"
    input.company.net_profit_generated == true
    verdict := {"matched": true, "rule_id": "special.coop.fund_allocation",
        "package": "tax.compliance.special", "priority": 253,
        "statutory_fund_allocation_required": true,
        "_legal_basis": "Art. 78 Prawo spoldzielcze"}
}
```

---

## 13. Prawo energetyczne (P254-P255)

### P254: `energy_concession_trading`

**Cel biznesowy:** Audyt legalności obrotu paliwami — wymóg koncesji URE.

**Przesłanki:** `category_code == "ENERGY_TRADING"`, brak koncesji URE

**Rezultat:** BLOCK_AND_ALERT

**Podstawa prawna:** Art. 32 Prawa energetycznego

```rego
# P254: energy_concession_trading
decide = verdict {
    input.invoice.category_code == "ENERGY_TRADING"
    input.company.has_ure_concession == false
    verdict := {"matched": true, "rule_id": "special.energy.concession_block",
        "package": "tax.compliance.special", "priority": 254,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Brak koncesji URE na obrot energia",
        "_legal_basis": "Art. 32 PE"}
}
```

### P255: `energy_green_certificates`

**Cel biznesowy:** Uprawnienia do świadectw pochodzenia dla OZE.

**Przesłanki:** `input.company.energy_source == "RENEWABLE"`

**Rezultat:** `certificates_of_origin_eligible: true`

**Podstawa prawna:** Art. 9a Prawa energetycznego

```rego
# P255: energy_green_certificates
decide = verdict {
    input.company.energy_source == "RENEWABLE"
    verdict := {"matched": true, "rule_id": "special.energy.green_certificates",
        "package": "tax.compliance.special", "priority": 255,
        "certificates_of_origin_eligible": true,
        "_legal_basis": "Art. 9a Prawo energetyczne"}
}
```

---

## 14. Transport drogowy (P256-P257)

### P256: `transport_license_freight`

**Cel biznesowy:** Walidacja licencji transportowej dla przewozów >3.5t.

**Przesłanki:** Transport >3.5t, brak licencji przewoźnika

**Rezultat:** TRIAGE_QUEUE, ostrzeżenie

**Podstawa prawna:** Art. 5 Ustawy o transporcie drogowym

```rego
# P256: transport_license_freight
decide = verdict {
    input.invoice.category_code == "TRANSPORT"
    input.invoice.vehicle_weight_kg > 3500
    input.vendor.has_transport_license == false
    verdict := {"matched": true, "rule_id": "risk.transport.no_license",
        "package": "tax.risk.transport", "priority": 256,
        "_routing": "TRIAGE_QUEUE",
        "_warnings": ["Brak weryfikacji licencji transportowej przewoznika"],
        "_legal_basis": "Art. 5 Ust. Trans. Drog."}
}
```

### P257: `transport_cabotage_limit`

**Cel biznesowy:** Kontrola limitu kabotażu — max 3 operacje w 7 dni.

**Przesłanki:** Kabotaż, >=3 operacji w 7 dni

**Rezultat:** BLOCK_AND_ALERT

**Podstawa prawna:** Rozp. WE 1072/2009

```rego
# P257: transport_cabotage_limit
decide = verdict {
    input.invoice.is_cabotage == true
    input.company.cabotage_operations_7days >= 3
    verdict := {"matched": true, "rule_id": "compliance.transport.cabotage",
        "package": "tax.compliance.special", "priority": 257,
        "cabotage_violation": true,
        "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Rozp. WE 1072/2009 (limit kabotazu)"}
}
```

---

## 15. KSeF szczegółowy (P258-P259)

### P258: `ksef_consumer_invoice_exemption`

**Cel biznesowy:** Zwolnienie B2C z obowiązku KSeF.

**Przesłanki:** `input.vendor.is_b2c == true`

**Rezultat:** `ksef_mandatory: false`

**Podstawa prawna:** Art. 106ga ust. 2 pkt 4 ustawy o VAT

```rego
# P258: ksef_consumer_invoice_exemption
decide = verdict {
    input.vendor.is_b2c == true
    verdict := {"matched": true, "rule_id": "compliance.ksef.b2c_exempt",
        "package": "tax.compliance.ksef", "priority": 258,
        "ksef_mandatory": false,
        "_legal_basis": "Art. 106ga ust. 2 pkt 4 VAT"}
}
```

### P259: `ksef_offline_recovery`

**Cel biznesowy:** Tryb awaryjny KSeF — 7 dni na przesłanie faktur po awarii.

**Przesłanki:** `input.system.ksef_status == "OFFLINE"`

**Rezultat:** `ksef_submission_deadline_days: 7`

**Podstawa prawna:** Art. 106ne ustawy o VAT

```rego
# P259: ksef_offline_recovery
decide = verdict {
    input.system.ksef_status == "OFFLINE"
    verdict := {"matched": true, "rule_id": "compliance.ksef.offline_mode",
        "package": "tax.compliance.ksef", "priority": 259,
        "ksef_submission_deadline_days": 7,
        "ksef_awaria": true,
        "_legal_basis": "Art. 106ne VAT"}
}
```

---

## 16. JPK szczegółowy (P260-P261)

### P260: `jpk_kr_mandatory`

**Cel biznesowy:** JPK_KR obowiązkowy przy kontroli skarbowej dla pełnej księgowości.

**Przesłanki:** Pełna księgowość + TAX_AUDIT

**Rezultat:** `jpk_kr_required: true`

**Podstawa prawna:** Art. 193a Ordynacji Podatkowej

```rego
# P260: jpk_kr_mandatory
decide = verdict {
    input.company.uses_full_accounting == true
    input.request.type == "TAX_AUDIT"
    verdict := {"matched": true, "rule_id": "compliance.jpk.kr_mandatory",
        "package": "tax.compliance.jpk", "priority": 260,
        "jpk_kr_required": true,
        "_legal_basis": "Art. 193a Ordynacji podatkowej"}
}
```

### P261: `jpk_v7_correction_reason`

**Cel biznesowy:** Poprawne wypełnienie Cel_Zlozenia = 2 dla korekt JPK_V7.

**Przesłanki:** Faktura korygująca zamyka miesiąc VAT

**Rezultat:** `jpk_correction_node_required: true`, `cel_zlozenia: 2`

**Podstawa prawna:** Rozp. MF — struktury JPK

```rego
# P261: jpk_v7_correction_reason
decide = verdict {
    input.invoice.is_correction == true
    input.invoice.modifies_closed_vat_period == true
    verdict := {"matched": true, "rule_id": "compliance.jpk.v7_correction",
        "package": "tax.compliance.jpk", "priority": 261,
        "jpk_correction_node_required": true,
        "cel_zlozenia": 2,
        "_legal_basis": "Struktury logiczne JPK (Cel zlozenia = 2)"}
}
```

---

## 17. VAT — czynności (P262-P263)

### P262: `vat_place_of_supply_b2b_services`

**Cel biznesowy:** Miejsce świadczenia usług B2B za granicę — opodatkowanie u nabywcy (NP).

**Przesłanki:** Usługa, B2B, nabywca spoza PL

**Rezultat:** `vat_rate: "NP"`, `place_of_supply` = kraj nabywcy

**Podstawa prawna:** Art. 28b VAT

```rego
# P262: vat_place_of_supply_b2b_services
decide = verdict {
    input.invoice.type == "SERVICE"
    input.vendor.is_b2b_buyer == true
    input.vendor.country != "PL"
    verdict := {"matched": true, "rule_id": "crossborder.vat.b2b_supply",
        "package": "tax.crossborder.vat", "priority": 262,
        "place_of_supply": input.vendor.country,
        "vat_rate": "NP",
        "_legal_basis": "Art. 28b VAT"}
}
```

### P263: `vat_free_goods_sample`

**Cel biznesowy:** Darmowe próbki handlowe — nie podlegają VAT.

**Przesłanki:** `input.invoice.expense_type == "FREE_SAMPLE"`

**Rezultat:** `vat_taxable: false`

**Podstawa prawna:** Art. 7 ust. 3 ustawy o VAT

```rego
# P263: vat_free_goods_sample
decide = verdict {
    input.invoice.expense_type == "FREE_SAMPLE"
    verdict := {"matched": true, "rule_id": "vat.substantive.free_sample",
        "package": "tax.vat.substantive", "priority": 263,
        "vat_taxable": false,
        "_legal_basis": "Art. 7 ust. 3 VAT"}
}
```

---

## 18. Podatki lokalne szczegółowe (P264-P265)

### P264: `local_tax_market_fee`

**Cel biznesowy:** Opłata targowa dla sprzedaży na targowiskach.

**Przesłanki:** `input.invoice.activity_location == "MARKETPLACE"`

**Rezultat:** `market_fee_applicable: true`

**Podstawa prawna:** Art. 15 Ustawy o podatkach i opłatach lokalnych

```rego
# P264: local_tax_market_fee
decide = verdict {
    input.invoice.activity_location == "MARKETPLACE"
    verdict := {"matched": true, "rule_id": "tax.local.market_fee",
        "package": "tax.local", "priority": 264,
        "market_fee_applicable": true,
        "_legal_basis": "Art. 15 UPoL"}
}
```

### P265: `local_tax_dog_ownership`

**Cel biznesowy:** Opłata od posiadania psów — rejestracja w gminie.

**Przesłanki:** Firma posiada psy stróżujące, brak rejestracji w gminie

**Rezultat:** `dog_tax_applicable: true`

**Podstawa prawna:** Art. 18 Ustawy o podatkach i opłatach lokalnych

```rego
# P265: local_tax_dog_ownership
decide = verdict {
    input.company.owns_guard_dog == true
    input.company.is_dog_registered_in_municipality == false
    verdict := {"matched": true, "rule_id": "tax.local.dog_tax",
        "package": "tax.local", "priority": 265,
        "dog_tax_applicable": true,
        "_warnings": ["Zarejestruj psa w gminie i oplac podatek"],
        "_legal_basis": "Art. 18 UPoL"}
}
```

---

## Podsumowanie

| Domena | Nowe reguły | Priorytety |
|--------|:-----------:|------------|
| VAT — obowiązek podatkowy | 2 | P230-P231 |
| VAT — podstawa opodatkowania | 2 | P232-P233 |
| PIT — źródła przychodów | 2 | P234-P235 |
| PIT/CIT — zaliczki | 2 | P236-P237 |
| CIT — przychody podatkowe | 2 | P238-P239 |
| Ordynacja — terminy | 2 | P240-P241 |
| Ordynacja — odpowiedzialność | 2 | P242-P243 |
| UoR — zasady rachunkowości | 2 | P244-P245 |
| UoR — księgi rachunkowe | 2 | P246-P247 |
| UoR — sprawozdania finansowe | 2 | P248-P249 |
| UoR — przechowywanie | 2 | P250-P251 |
| Prawo spółdzielcze | 2 | P252-P253 |
| Prawo energetyczne | 2 | P254-P255 |
| Transport drogowy | 2 | P256-P257 |
| KSeF szczegółowy | 2 | P258-P259 |
| JPK szczegółowy | 2 | P260-P261 |
| VAT — czynności | 2 | P262-P263 |
| Podatki lokalne szczegółowe | 2 | P264-P265 |
| **RAZEM** | **36** | **P230-P265** |

**Całkowite pokrycie: 155 + 36 = 191 reguł w 35+ domenach prawnych.**

> **⚠️ Reguły w tym dokumencie wprowadzają nowe pola `input.*`** nieopisane jeszcze w `01_INPUT_SPEC.md`. Pełna lista rozszerzeń input znajduje się w nagłówku dokumentu. Wszystkie werdykty zawierają pola standardowe (`vat_rate`, `rounding_level`, `income_tax_qualification`) z wartościami pustymi `""` dla reguł proceduralnych (P240-P241, P246-P251, P254-P255, P264-P265), gdzie VAT/KUP nie ma zastosowania.

---

> **Następny krok:** `12_DATA_INTEGRATION_PATTERNS.md` — wzorce OPA contrib dla systemu podatkowego.
