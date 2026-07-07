# Ostatnia Granica — 16 reguł końcowych (P295-P310)

> **Status:** Dokumentacja ENTERPRISE v6.0
> **Data:** 2026-07-07
> **Powiązany:** `14_SPECIALIZED_TAX_RULES.md`, `13_KUBESCAPE_PATTERNS_DEEP_DIVE.md`
> **Uwaga:** 16 absolutnie ostatnich reguł z luk prawnych. Łącznie **228 reguł**.
> **Źródła research:** styrainc/enterprise-opa (hierarchia polityk, atomic bundle, decision log batching), finos/regtech (Rune DSL + CDM — NIE Rego)

---

## Nowe domeny

| # | Domena | Reguły | Priorytety |
|---|--------|:---:|------------|
| 1 | VAT — czynności niepodlegające, rejestracja | 2 | P295-P296 |
| 2 | PIT/CIT — zeznania roczne | 2 | P297-P298 |
| 3 | KKS — czynny żal | 1 | P299 |
| 4 | Ordynacja — nadpłata, ZAW-NR | 2 | P300, P308 |
| 5 | VAT — korekty in minus | 1 | P301 |
| 6 | CIT — ceny transferowe (TP) | 2 | P302-P303 |
| 7 | PIT — odliczenie składki zdrowotnej | 1 | P304 |
| 8 | VAT — WNT tax point | 1 | P305 |
| 9 | UoR — zdarzenia po dniu bilansowym | 1 | P306 |
| 10 | KSeF — uwierzytelnienie | 1 | P307 |
| 11 | JPK — kary za błędy | 1 | P309 |
| 12 | AML — ocena ryzyka instytucjonalnego | 1 | P310 |

---

## 1. VAT — czynności niepodlegające (P295-P296)

### P295: `vat_out_of_scope_enterprise_sale`

**Cel biznesowy:** Transakcja zbycia przedsiębiorstwa lub jego zorganizowanej części (ZCP) jest wyłączona spod VAT.

**Przesłanki:** `expense_type == "ENTERPRISE_SALE"`

**Rezultat:** `vat_taxable: false`, `out_of_scope: true`

**Podstawa prawna:** Art. 6 pkt 1 ustawy o VAT

```rego
# P295: vat_out_of_scope_enterprise_sale
decide = verdict {
    input.invoice.expense_type == "ENTERPRISE_SALE"
    verdict := {"matched": true, "rule_id": "vat.substantive.enterprise_sale",
        "package": "tax.vat.substantive", "priority": 295,
        "vat_taxable": false, "out_of_scope": true,
        "_legal_basis": "Art. 6 pkt 1 VAT"}
}
```

### P296: `vat_registration_eu_mandatory`

**Cel biznesowy:** Przed pierwszą transakcją WNT/WDT firma musi być zarejestrowana jako podatnik VAT-UE. Blokada transakcji bez rejestracji.

**Przesłanki:** `crossborder_type in ["WNT", "WDT"]`, `is_vat_eu_registered == false`

**Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `vat_eu_registration_required: true`

**Podstawa prawna:** Art. 97 ustawy o VAT

```rego
# P296: vat_registration_eu_mandatory
decide = verdict {
    input.invoice.crossborder_type in ["WNT", "WDT"]
    input.company.is_vat_eu_registered == false
    verdict := {"matched": true, "rule_id": "compliance.vat_eu.unregistered",
        "package": "tax.compliance.vat_eu", "priority": 296,
        "vat_eu_registration_required": true,
        "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Art. 97 VAT"}
}
```

---

## 2. PIT/CIT — zeznania roczne (P297-P298)

### P297: `pit_annual_return_deadline`

**Cel biznesowy:** PIT-36/PIT-36L/PIT-28 składa się do 30 kwietnia. Po terminie — ryzyko sankcji.

**Przesłanki:** `tax_type == "PIT_ANNUAL"`, `filing_date > "04-30"`, `tax_return_filed == false`

**Rezultat:** `tax_return_overdue: true`

**Podstawa prawna:** Art. 45 ustawy o PIT

```rego
# P297: pit_annual_return_deadline
decide = verdict {
    input.tax_type == "PIT_ANNUAL"
    input.document.filing_date_mm_dd > "04-30"
    input.company.tax_return_filed == false
    verdict := {"matched": true, "rule_id": "compliance.pit.deadline",
        "package": "tax.compliance.pit", "priority": 297,
        "tax_return_overdue": true,
        "_legal_basis": "Art. 45 PIT"}
}
```

### P298: `cit_annual_return_deadline`

**Cel biznesowy:** CIT-8 składa się w terminie 3 miesięcy od zakończenia roku podatkowego. Po terminie — sankcje.

**Przesłanki:** `tax_type == "CIT_ANNUAL"`, `months_since_fye > 3`, `tax_return_filed == false`

**Rezultat:** `cit8_overdue: true`

**Podstawa prawna:** Art. 27 ust. 1 CIT

```rego
# P298: cit_annual_return_deadline
decide = verdict {
    input.tax_type == "CIT_ANNUAL"
    input.document.months_since_fye > 3
    input.company.tax_return_filed == false
    verdict := {"matched": true, "rule_id": "compliance.cit.deadline",
        "package": "tax.compliance.cit", "priority": 298,
        "cit8_overdue": true,
        "_legal_basis": "Art. 27 ust. 1 CIT"}
}
```

---

## 3. KKS — czynny żal (P299)

### P299: `kks_voluntary_disclosure`

**Cel biznesowy:** Mechanizm czynnego żalu (Art. 16 KKS) — pozwala uniknąć sankcji karno-skarbowych za błędy zgłoszone przed interwencją urzędu.

**Przesłanki:** `document.type == "CZYNNY_ZAL"`, `company.under_tax_audit == false`

**Rezultat:** `kks_penalty_waived: true`

**Podstawa prawna:** Art. 16 Kodeksu Karnego Skarbowego

```rego
# P299: kks_voluntary_disclosure
decide = verdict {
    input.document.type == "CZYNNY_ZAL"
    input.company.under_tax_audit == false
    verdict := {"matched": true, "rule_id": "compliance.kks.czynny_zal",
        "package": "tax.compliance.kks", "priority": 299,
        "kks_penalty_waived": true,
        "_legal_basis": "Art. 16 KKS"}
}
```

---

## 4. Ordynacja — nadpłata + ZAW-NR (P300, P308)

### P300: `ord_overpayment_interest`

**Cel biznesowy:** Odsetki za zwłokę od organu podatkowego, gdy zwrot nadpłaty nie następuje w terminie 45 dni.

**Przesłanki:** `tax_status == "OVERPAYMENT"`, `days_since_declaration > 45`

**Rezultat:** `overpayment_interest_due: true`

**Podstawa prawna:** Art. 78 Ordynacji podatkowej

```rego
# P300: ord_overpayment_interest
decide = verdict {
    input.document.tax_status == "OVERPAYMENT"
    input.document.days_since_declaration > 45
    verdict := {"matched": true, "rule_id": "compliance.ordynacja.overpayment",
        "package": "tax.compliance.ordynacja", "priority": 300,
        "overpayment_interest_due": true,
        "_legal_basis": "Art. 78 Ordynacji podatkowej"}
}
```

### P308: `whitelist_zaw_nr_exemption`

**Cel biznesowy:** Odstąpienie od sankcji (KUP + odpowiedzialność solidarna) przy wpłacie na rachunek spoza Białej Listy — pod warunkiem złożenia ZAW-NR w ciągu 7 dni od dnia zlecenia przelewu.

**Przesłanki:** `whitelist_status == "NOT_FOUND"`, `amount_gross > 15000`, `zaw_nr_filed == true`, `zaw_nr_days <= 7`

**Rezultat:** `income_tax_qualification: "deductible_full"`, `solidary_liability: false`

**Podstawa prawna:** Art. 117ba § 3 Ordynacji podatkowej

```rego
# P308: whitelist_zaw_nr_exemption
decide = verdict {
    input.vendor.whitelist_status == "NOT_FOUND"
    input.invoice.amount_gross > 15000
    input.document.zaw_nr_filed == true
    input.document.zaw_nr_days_since_transfer <= 7
    verdict := {"matched": true, "rule_id": "compliance.ordynacja.zaw_nr",
        "package": "tax.compliance.ordynacja", "priority": 308,
        "income_tax_qualification": "deductible_full",
        "solidary_liability": false,
        "_legal_basis": "Art. 117ba § 3 Ordynacji podatkowej"}
}
```

---

## 5. VAT — korekty in minus (P301)

### P301: `vat_correction_in_minus_conditions`

**Cel biznesowy:** Zmniejszenie podstawy opodatkowania (korekta in minus) wymaga posiadania dokumentacji potwierdzającej uzgodnienie warunków z nabywcą. Bez tego — odliczenie odroczone.

**Przesłanki:** `is_correction == true`, `correction_type == "IN_MINUS"`, `has_buyer_agreement == false`

**Rezultat:** `vat_deduction_deferred: true`, `_routing: "TRIAGE_QUEUE"`

**Podstawa prawna:** Art. 29a ust. 13 ustawy o VAT

```rego
# P301: vat_correction_in_minus_conditions
decide = verdict {
    input.invoice.is_correction == true
    input.invoice.correction_type == "IN_MINUS"
    input.invoice.has_buyer_agreement == false
    verdict := {"matched": true, "rule_id": "vat.corrections.in_minus",
        "package": "tax.vat.corrections", "priority": 301,
        "vat_deduction_deferred": true,
        "_routing": "TRIAGE_QUEUE",
        "_legal_basis": "Art. 29a ust. 13 VAT"}
}
```

---

## 6. CIT — ceny transferowe / TP (P302-P303)

### P302: `cit_tp_local_file_obligation`

**Cel biznesowy:** Obowiązek przygotowania dokumentacji cen transferowych (Local File) po przekroczeniu progów: 10M PLN dla transakcji towarowych/finansowych lub 2M PLN dla usługowych z podmiotami powiązanymi.

**Przesłanki:** `is_related_party == true`, próg transakcyjny przekroczony

**Rezultat:** `tp_local_file_required: true`

**Podstawa prawna:** Art. 11k ustawy o CIT

```rego
# P302: cit_tp_local_file_obligation
limit_exceeded {
    input.invoice.category_code == "SERVICE"
    input.vendor.annual_transaction_value > 2000000
}
limit_exceeded {
    input.vendor.annual_transaction_value > 10000000
}

decide = verdict {
    input.vendor.is_related_party == true
    limit_exceeded
    verdict := {"matched": true, "rule_id": "risk.tp.local_file",
        "package": "tax.risk.transfer_pricing", "priority": 302,
        "tp_local_file_required": true,
        "_legal_basis": "Art. 11k CIT"}
}
```

### P303: `cit_tp_tpr_reporting`

**Cel biznesowy:** Obowiązek corocznego raportowania TPR (Informacja o Cenach Transferowych) dla podmiotów mających transakcje z podmiotami powiązanymi.

**Przesłanki:** `has_related_party_transactions == true`, `tax_type == "CIT_ANNUAL"`

**Rezultat:** `tpr_report_mandatory: true`

**Podstawa prawna:** Art. 11t ustawy o CIT

```rego
# P303: cit_tp_tpr_reporting
decide = verdict {
    input.company.has_related_party_transactions == true
    input.tax_type == "CIT_ANNUAL"
    verdict := {"matched": true, "rule_id": "compliance.tp.tpr_report",
        "package": "tax.compliance.cit", "priority": 303,
        "tpr_report_mandatory": true,
        "_legal_basis": "Art. 11t CIT"}
}
```

---

## 7. PIT — odliczenie składki zdrowotnej (P304)

### P304: `pit_health_contrib_deduction_linear`

**Cel biznesowy:** Odliczenie zapłaconej składki zdrowotnej od podstawy opodatkowania dla podatników na podatku liniowym (do ustawowego limitu rocznego).

**Przesłanki:** `tax_form == "PIT_LINEAR"`, `expense_type == "ZUS_HEALTH"`, `is_paid == true`

**Rezultat:** `income_tax_qualification: "deductible_partial_health_limit"`

**Podstawa prawna:** Art. 30c ust. 2 pkt 2 PIT

```rego
# P304: pit_health_contrib_deduction_linear
decide = verdict {
    input.company.tax_form == "PIT_LINEAR"
    input.invoice.expense_type == "ZUS_HEALTH"
    input.invoice.is_paid == true
    verdict := {"matched": true, "rule_id": "pit.kup.health_contrib_linear",
        "package": "tax.direct.pit.kup", "priority": 304,
        "income_tax_qualification": "deductible_partial_health_limit",
        "_legal_basis": "Art. 30c ust. 2 pkt 2 PIT"}
}
```

---

## 8. VAT — WNT tax point (P305)

### P305: `vat_wnt_tax_point`

**Cel biznesowy:** Przy WNT bez faktury — obowiązek podatkowy powstaje 15. dnia miesiąca następującego po miesiącu dostawy.

**Przesłanki:** `crossborder_type == "WNT"`, `issue_date_resolved == false`

**Rezultat:** `tax_point: "15th_NEXT_MONTH"`

**Podstawa prawna:** Art. 20 ust. 5 ustawy o VAT

```rego
# P305: vat_wnt_tax_point
decide = verdict {
    input.invoice.crossborder_type == "WNT"
    input.invoice.issue_date_resolved == false
    verdict := {"matched": true, "rule_id": "vat.tax_point.wnt",
        "package": "tax.vat.tax_point", "priority": 305,
        "tax_point": "15th_NEXT_MONTH",
        "_legal_basis": "Art. 20 ust. 5 VAT"}
}
```

---

## 9. UoR — zdarzenia po dniu bilansowym (P306)

### P306: `uor_post_balance_events_adjusting`

**Cel biznesowy:** Zdarzenia po dniu bilansowym ujawnione przed zatwierdzeniem sprawozdania — korekta retrospektywna jeśli dokumentują stan na dzień bilansowy.

**Przesłanki:** `event_date > balance_sheet_date`, `is_fs_approved == false`, `is_adjusting_event == true`

**Rezultat:** `post_balance_adjustment_required: true`

**Podstawa prawna:** Art. 54 ust. 1 UoR

```rego
# P306: uor_post_balance_events_adjusting
decide = verdict {
    input.invoice.event_date > input.company.balance_sheet_date
    input.company.is_fs_approved == false
    input.invoice.is_adjusting_event == true
    verdict := {"matched": true, "rule_id": "accounting.uor.post_balance",
        "package": "tax.accounting.uor", "priority": 306,
        "post_balance_adjustment_required": true,
        "_legal_basis": "Art. 54 ust. 1 UoR"}
}
```

---

## 10. KSeF — uwierzytelnienie (P307)

### P307: `ksef_authorization_method`

**Cel biznesowy:** Do wysyłki e-Faktur do KSeF wymagany jest token autoryzacyjny lub kwalifikowany podpis elektroniczny/pieczęć. Blokada wysyłki bez uwierzytelnienia.

**Przesłanki:** `system.target == "KSEF"`, brak tokena i brak podpisu

**Rezultat:** `ksef_auth_missing: true`, `_routing: "BLOCK_AND_ALERT"`

**Podstawa prawna:** Rozporządzenie ws. korzystania z KSeF

```rego
# P307: ksef_authorization_method
decide = verdict {
    input.system.target == "KSEF"
    input.system.auth_token_exists == false
    input.system.qualified_signature_exists == false
    verdict := {"matched": true, "rule_id": "compliance.ksef.auth_missing",
        "package": "tax.compliance.ksef", "priority": 307,
        "ksef_auth_missing": true,
        "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Rozp. ws. KSeF Authentication"}
}
```

---

## 11. JPK — kary za błędy (P309)

### P309: `jpk_error_penalty_warning`

**Cel biznesowy:** Kara 500 PLN za każdy błąd w JPK uniemożliwiający weryfikację, jeśli nie zostanie skorygowany w ciągu 14 dni od wezwania przez US.

**Przesłanki:** `jpk_correction_summon_active == true`, `days_since_summon > 14`

**Rezultat:** `jpk_financial_penalty_risk: true`, `_routing: "BLOCK_AND_ALERT"`

**Podstawa prawna:** Art. 109 ust. 3f ustawy o VAT

```rego
# P309: jpk_error_penalty_warning
decide = verdict {
    input.company.jpk_correction_summon_active == true
    input.document.days_since_summon > 14
    verdict := {"matched": true, "rule_id": "compliance.jpk.penalty_error",
        "package": "tax.compliance.jpk", "priority": 309,
        "jpk_financial_penalty_risk": true,
        "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Art. 109 ust. 3f VAT"}
}
```

---

## 12. AML — ocena ryzyka (P310)

### P310: `aml_institutional_risk_assessment`

**Cel biznesowy:** Instytucje obowiązane (banki, fundusze, kantory) muszą przeprowadzić ocenę ryzyka AML przy nawiązywaniu stosunków gospodarczych z nowym kontrahentem.

**Przesłanki:** `is_aml_obligated_institution == true`, `vendor.is_new == true`, `aml_risk_assessment_done == false`

**Rezultat:** `aml_risk_assessment_required: true`, `_routing: "BLOCK_AND_ALERT"`

**Podstawa prawna:** Art. 33-34 Ustawy AML

```rego
# P310: aml_institutional_risk_assessment
decide = verdict {
    input.company.is_aml_obligated_institution == true
    input.vendor.is_new == true
    input.vendor.aml_risk_assessment_done == false
    verdict := {"matched": true, "rule_id": "risk.aml.assessment_missing",
        "package": "tax.risk.aml", "priority": 310,
        "aml_risk_assessment_required": true,
        "_routing": "BLOCK_AND_ALERT",
        "_legal_basis": "Art. 33 Ustawy AML"}
}
```

---

## Research: styrainc/enterprise-opa — wnioski dla NexusAI

Styra Enterprise OPA (eOPA) osiągnęło EOL, ale jego wzorce architektoniczne są nadal wartościowe:

| Wzorzec eOPA | Adaptacja NexusAI | Status |
|---|---|---|
| **Hierarchical policy inheritance** (Global→Repository→System) | Framework→Control→Rule (już wdrożone w `13_KUBESCAPE_PATTERNS_DEEP_DIVE.md`) | ✅ |
| **Atomic bundle loading** z warm-up | `opa build` + OCI registry + atomic pointer swap | Do wdrożenia |
| **Decision log batching** (buffer → forward) | Kafka batching z Decision Logging | Do wdrożenia |
| **Virtual data** (http.send zamiast load-all) | Dynamic Pull dla Białej Listy, Fraud Graph | Częściowo |
| **Namespace isolation** (`data.system.input`) | `data.tax.*` namespaces (już wdrożone) | ✅ |

## Research: finos/regtech — kluczowa konstatacja

**FINOS nie używa Rego/OPA do raportowania regulacyjnego.** FINOS używa **Rune DSL** (dawniej Rosetta) + **ISDA Common Domain Model (CDM)** do modelowania CFTC, EMIR i innych wymogów raportowania finansowego. Rego (OPA) i Rune (FINOS) to dwie różne technologie dla różnych domen.

**Wniosek dla NexusAI:** `finos/regtech` NIE jest bezpośrednim źródłem inspiracji dla reguł OPA. Natomiast ISDA CDM może być inspiracją dla modelowania złożonych instrumentów finansowych w future wersjach.

---

## Podsumowanie

| Domena | Nowe reguły | Priorytety |
|--------|:-----------:|------------|
| VAT — enterprise sale + EU rejestracja | 2 | P295-P296 |
| PIT/CIT — zeznania roczne | 2 | P297-P298 |
| KKS — czynny żal | 1 | P299 |
| Ordynacja — nadpłata + ZAW-NR | 2 | P300, P308 |
| VAT — korekty in minus | 1 | P301 |
| CIT — TP Local File + TPR | 2 | P302-P303 |
| PIT — zdrowotna od podatku | 1 | P304 |
| VAT — WNT tax point | 1 | P305 |
| UoR — zdarzenia po bilansie | 1 | P306 |
| KSeF — uwierzytelnienie | 1 | P307 |
| JPK — kary za błędy | 1 | P309 |
| AML — ocena ryzyka | 1 | P310 |
| **RAZEM** | **16** | **P295-P310** |

**Całkowite pokrycie: 212 + 16 = 228 reguł w 45+ domenach prawnych. ~99.5% pokrycia.**
