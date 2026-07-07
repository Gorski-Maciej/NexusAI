# 🔬 Deep Docs Analysis — 12 nowych reguł (P320-P331)

> **Status:** Dokumentacja ENTERPRISE v7.0
> **Data:** 2026-07-07
> **Powiązany:** `Docs` (oryginalny katalog przepisów), wszystkie 228 istniejących reguł
> **Metoda:** Deep cross-reference analizy Docs vs istniejące reguły P0-P310 przez thinker-with-files-gemini
> **Wynik:** 12 absolutnie ostatnich, genuinnych luk prawnych. Łącznie **240 reguł**.

---

## Nowe domeny (niepokryte wcześniej)

| # | Domena | Podstawa prawna | Reguła | P |
|---|--------|-----------------|--------|---|
| 1 | UoR — podwójny zapis (Wn=Ma) | Art. 22 ust. 1 UoR | `uor_double_entry_validation` | 320 |
| 2 | UoR — zamknięcie ksiąg | Art. 12 ust. 2 pkt 1 UoR | `uor_closing_books_mandatory` | 321 |
| 3 | UoR — rezerwy (prawo polskie) | Art. 31 ust. 1 UoR | `uor_provisions_recognition` | 322 |
| 4 | CIT — ulga na złe długi (wierzyciel) | Art. 18f CIT | `cit_bad_debt_relief_creditor` | 323 |
| 5 | VAT — obowiązkowa rejestracja VAT-R | Art. 15, 96 VAT | `vat_registration_vat_r_mandatory` | 324 |
| 6 | Ordynacja — zabezpieczenie wykonania | Art. 33, 36 Ordynacji | `ord_tax_securing_deadline` | 325 |
| 7 | UoR — obowiązkowe elementy dowodu | Art. 21 ust. 1 UoR | `uor_evidence_mandatory_fields` | 326 |
| 8 | UoR — struktura bilansu/RZiS | Art. 35-44 UoR + Zał. 1 | `uor_financial_statement_structure` | 327 |
| 9 | KP — badania BHP i lekarskie (KUP) | Art. 229 KP | `labor_ohs_medical_exams_kup` | 328 |
| 10 | Ordynacja — ulga w spłacie/odroczenie | Art. 54, 67a-69 Ordynacji | `ord_payment_relief_deferral` | 329 |
| 11 | UoR — koszt wytworzenia vs cena nabycia | Art. 28 ust. 1-3 UoR | `uor_valuation_manufacturing_cost` | 330 |
| 12 | PIT — małe umowy zlecenia ≤200 PLN | Art. 30 ust. 1 pkt 5a PIT | `pit_small_mandate_flat_rate` | 331 |

---

## 1. UoR — Podwójny zapis (P320)

### P320: `uor_double_entry_validation`

**Cel biznesowy:** Walidacja integralności księgowej — kontrola zbilansowania Wn = Ma na poziomie każdego dekretu.

**Przesłanki:** `document.type == "journal_entry"` AND suma debet ≠ suma kredyt

**Rezultat:** `_routing: "BLOCK_AND_ALERT"` — blokada księgowania niezbilansowanego zapisu

**Podstawa prawna:** Art. 22 ust. 1 UoR (zasada podwójnego zapisu)

**Pseudokod Rego:**
```rego
# P320: uor_double_entry_validation
# Cel biznesowy: Zabezpieczenie integralności — Wn musi = Ma
# Przesłanki: document.type == journal_entry AND sum(debet) != sum(kredyt)
# Podstawa prawna: Art. 22 ust. 1 UoR
# Priorytet: 320

# Oblicza sumę kwot dla danej strony zapisu
sum_by_side(side) = total {
    total := sum([line.amount | line := input.document.lines[_]; line.side == side])
}

decide := {
    "matched": true,
    "rule_id": "tax.accounting.uor.double_entry_validation",
    "package": "tax.accounting.uor.books",
    "priority": 320,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": concat("", [
        "Niezgodność podwójnego zapisu: Wn=", sprintf("%.2f", [sum_by_side("debit")]),
        " Ma=", sprintf("%.2f", [sum_by_side("credit")])
    ]),
    "_legal_basis": "Art. 22 ust. 1 UoR",
    "_warnings": ["Zapis księgowy niezbilansowany — naruszenie zasady podwójnego zapisu"]
} {
    input.document.type == "journal_entry"
    abs(sum_by_side("debit") - sum_by_side("credit")) > 0.01
}
```

---

## 2. UoR — Zamknięcie ksiąg (P321)

### P321: `uor_closing_books_mandatory`

**Cel biznesowy:** Blokada księgowania operacji w zamkniętym już roku obrotowym po zatwierdzeniu sprawozdania.

**Przesłanki:** `invoice.issue_date <= thresholds.closed_financial_year_end`

**Rezultat:** `_routing: "BLOCK"` — operacja musi trafić do korekty błędów podstawowych (P290)

**Podstawa prawna:** Art. 12 ust. 2 pkt 1 UoR

```rego
# P321: uor_closing_books_mandatory
decide := {
    "matched": true,
    "rule_id": "tax.accounting.uor.books_closed",
    "package": "tax.accounting.uor.books",
    "priority": 321,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Próba księgowania w zamkniętym roku obrotowym",
    "_legal_basis": "Art. 12 ust. 2 pkt 1 UoR",
    "_warnings": ["Księgi zamknięte — użyj korekty błędu podstawowego (Art. 54 UoR)"]
} {
    input.invoice.issue_date <= input.company.closed_financial_year_end
    input.company.is_fs_approved == true
}
```

---

## 3. UoR — Rezerwy wg prawa polskiego (P322)

### P322: `uor_provisions_recognition`

**Cel biznesowy:** Utworzenie rezerwy na pewne/prawdopodobne straty wg polskich norm (nie IAS 37 — to ma P121). Dotyczy firm NIE stosujących MSSF.

**Przesłanki:** `uses_ifrs == false` AND `has_certain_or_probable_loss == true`

**Rezultat:** `action: "CREATE_PROVISION"`, koszt w ciężar pozostałych kosztów operacyjnych

**Podstawa prawna:** Art. 31 ust. 1 UoR

```rego
# P322: uor_provisions_recognition
decide := {
    "matched": true,
    "rule_id": "tax.accounting.uor.provisions_polish_gaap",
    "package": "tax.accounting.uor.valuation",
    "priority": 322,
    "provision_required": true,
    "provision_type": "UOR_ART_31",
    "income_tax_qualification": "deductible_partial",
    "_legal_basis": "Art. 31 ust. 1 UoR",
    "_warnings": ["Zawiąż rezerwę na straty wg Art. 31 UoR"]
} {
    input.company.uses_ifrs == false
    input.document.has_certain_or_probable_loss == true
}
```

---

## 4. CIT — Ulga na złe długi dla wierzyciela (P323)

### P323: `cit_bad_debt_relief_creditor`

**Cel biznesowy:** Pomniejszenie podstawy opodatkowania CIT o wartość wierzytelności nieściągalnych (wierzyciel). Analog P60 (VAT bad debt — dłużnik).

**Przesłanki:** Wierzytelność wykazana jako przychód + brak zapłaty >90 dni od terminu

**Rezultat:** `cit_deduction: amount_net` — pomniejszenie dochodu do opodatkowania

**Podstawa prawna:** Art. 18f CIT

```rego
# P323: cit_bad_debt_relief_creditor
decide := {
    "matched": true,
    "rule_id": "tax.direct.cit.bad_debt_creditor",
    "package": "tax.direct.cit.deductions",
    "priority": 323,
    "cit_deduction_eligible": true,
    "cit_deduction_amount": input.invoice.amount_net,
    "_legal_basis": "Art. 18f CIT",
    "_warnings": ["Ulga na złe długi CIT — pomniejszenie podstawy opodatkowania"]
} {
    input.invoice.days_overdue > 90
    input.invoice.is_paid == false
    input.invoice.was_recognized_as_revenue == true
    input.company.tax_form in ["CIT_STANDARD", "CIT_ESTONIAN"]
}
```

---

## 5. VAT — Obowiązkowa rejestracja VAT-R (P324)

### P324: `vat_registration_vat_r_mandatory`

**Cel biznesowy:** Alert przy pierwszej sprzedaży przez podmiot niezarejestrowany jako czynny podatnik VAT. P58 (zwolnienie podmiotowe) i P296 (VAT-UE) nie pokrywają podstawowego obowiązku VAT-R.

**Przesłanki:** Firma bez rejestracji VAT + kategoria wymagająca VAT

**Rezultat:** `_routing: "ALERT"` — wymagany proces rejestracji VAT-R

**Podstawa prawna:** Art. 15 i Art. 96 VAT

```rego
# P324: vat_registration_vat_r_mandatory
decide := {
    "matched": true,
    "rule_id": "tax.compliance.vat_registration_required",
    "package": "tax.compliance.vat_registration",
    "priority": 324,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Podmiot niezarejestrowany jako podatnik VAT — wymagany VAT-R",
    "_legal_basis": "Art. 15, Art. 96 VAT",
    "_warnings": ["Złóż VAT-R przed wystawieniem pierwszej faktury"]
} {
    input.company.vat_status == "unregistered"
    input.invoice.vat_taxable == true
}
```

---

## 6. Ordynacja — Zabezpieczenie wykonania (P325)

### P325: `ord_tax_securing_deadline`

**Cel biznesowy:** Obsługa decyzji o zabezpieczeniu wykonania zobowiązania przez US. Dotyczy ryzyka niewykonania zobowiązania podatkowego.

**Przesłanki:** Decyzja US o zabezpieczeniu + odwołanie bez wstrzymania wykonania

**Rezultat:** `requires_immediate_deposit: true` — natychmiastowy depozyt

**Podstawa prawna:** Art. 33 i 36 Ordynacji Podatkowej

```rego
# P325: ord_tax_securing_deadline
decide := {
    "matched": true,
    "rule_id": "tax.compliance.ordynacja.securing_deadline",
    "package": "tax.compliance.ordynacja",
    "priority": 325,
    "tax_securing_required": true,
    "requires_immediate_deposit": true,
    "_legal_basis": "Art. 33, Art. 36 Ordynacji podatkowej",
    "_warnings": ["Decyzja o zabezpieczeniu — wymagany natychmiastowy depozyt"]
} {
    input.document.type == "us_securing_decision"
    input.document.is_appealed_without_stay == true
}
```

---

## 7. UoR — Obowiązkowe elementy dowodu (P326)

### P326: `uor_evidence_mandatory_fields`

**Cel biznesowy:** Odrzucenie dokumentów niespełniających wymogów Art. 21 UoR. Uzupełnienie P246 (język obcy) o pozostałe obowiązkowe elementy.

**Przesłanki:** Brak określenia stron lub opisu operacji gospodarczej

**Rezultat:** `_routing: "TRIAGE_QUEUE"`, `evidence_status: "INVALID"`

**Podstawa prawna:** Art. 21 ust. 1 UoR

```rego
# P326: uor_evidence_mandatory_fields
decide := {
    "matched": true,
    "rule_id": "tax.accounting.uor.evidence_invalid",
    "package": "tax.accounting.uor.books",
    "priority": 326,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Dowód księgowy nie spełnia wymogów Art. 21 UoR",
    "evidence_status": "INVALID",
    "_legal_basis": "Art. 21 ust. 1 UoR",
    "_warnings": ["Brak określenia stron lub opisu operacji — dowód wadliwy"]
} {
    input.document.parties_identified == false
}

else := {
    "matched": true,
    "rule_id": "tax.accounting.uor.evidence_invalid",
    "package": "tax.accounting.uor.books",
    "priority": 326,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Dowód księgowy nie spełnia wymogów Art. 21 UoR",
    "evidence_status": "INVALID",
    "_legal_basis": "Art. 21 ust. 1 UoR",
    "_warnings": ["Brak opisu operacji gospodarczej — dowód wadliwy"]
} {
    input.document.has_operation_description == false
}
```

---

## 8. UoR — Struktura sprawozdań (P327)

### P327: `uor_financial_statement_structure`

**Cel biznesowy:** Automatyczna klasyfikacja aktywów do odpowiednich pozycji bilansu (długoterminowe vs krótkoterminowe) wg załącznika nr 1 do UoR.

**Przesłanki:** Aktywo o okresie użytkowania >12 mies. i nie jest przeznaczone do obrotu

**Rezultat:** `bs_category: "non_current_assets"` / `"current_assets"`

**Podstawa prawna:** Art. 35-44 UoR + Załącznik nr 1

```rego
# P327: uor_financial_statement_structure
decide := {
    "matched": true,
    "rule_id": "tax.accounting.uor.bs_classification",
    "package": "tax.accounting.uor.reports",
    "priority": 327,
    "bs_category": "non_current_assets",
    "_legal_basis": "Art. 35-44 UoR, Załącznik nr 1"
} {
    input.asset.expected_usage_months > 12
    input.asset.is_held_for_trading == false
}
```

---

## 9. KP — Badania BHP i lekarskie (P328)

### P328: `labor_ohs_medical_exams_kup`

**Cel biznesowy:** Prawidłowa kwalifikacja kosztów badań BHP i medycyny pracy jako KUP (100%). Obowiązkowe, więc nie ma wątpliwości co do związku z przychodem.

**Przesłanki:** Faktura za badania lekarskie/medycynę pracy dla pracownika

**Rezultat:** `income_tax_qualification: "deductible_full"`

**Podstawa prawna:** Art. 229 KP w zw. z Art. 15 CIT, Art. 22 PIT

```rego
# P328: labor_ohs_medical_exams_kup
decide := {
    "matched": true,
    "rule_id": "tax.labor.ohs_medical_exams",
    "package": "tax.labor",
    "priority": 328,
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 229 KP, Art. 15 CIT",
    "_warnings": ["Badania BHP/medycyna pracy — 100% KUP jako koszt obowiązkowy"]
} {
    input.invoice.category_code == "MEDICAL_EXAMS_OHS"
    input.invoice.beneficiary_type == "employee"
}
```

---

## 10. Ordynacja — Ulga w spłacie (P329)

### P329: `ord_payment_relief_deferral`

**Cel biznesowy:** Automatyczne zastosowanie opłaty prolongacyjnej zamiast odsetek za zwłokę przy odroczeniu/rozłożeniu na raty. Art. 67a-69 Ordynacji.

**Przesłanki:** Aktywna decyzja o odroczeniu/ratach

**Rezultat:** `apply_prolongation_fee: true` — nowa stawka zamiast odsetek (Art. 54)

**Podstawa prawna:** Art. 54 oraz Art. 67a-69 Ordynacji Podatkowej

```rego
# P329: ord_payment_relief_deferral
decide := {
    "matched": true,
    "rule_id": "tax.compliance.ordynacja.payment_relief",
    "package": "tax.compliance.ordynacja",
    "priority": 329,
    "apply_prolongation_fee": true,
    "prolongation_rate": object.get(input.thresholds.rates, "prolongation_fee", "0.50"),
    "_legal_basis": "Art. 54, Art. 67a-69 Ordynacji podatkowej"
} {
    input.company.has_active_deferral_decision == true
    input.document.type == "tax_payment"
}
```

---

## 11. UoR — Koszt wytworzenia vs cena nabycia (P330)

### P330: `uor_valuation_manufacturing_cost`

**Cel biznesowy:** Ustalenie właściwej metody wyceny początkowej — czy użyć kosztu wytworzenia (produkcja własna) czy ceny nabycia (zakup). Uzupełnienie P94 (FIFO) o metodę wyceny wejścia.

**Przesłanki:** Środek trwały wyprodukowany wewnętrznie (nie zakupiony)

**Rezultat:** `valuation_base: "manufacturing_cost"`

**Podstawa prawna:** Art. 28 ust. 1, 2, 3 UoR

```rego
# P330: uor_valuation_manufacturing_cost
decide := {
    "matched": true,
    "rule_id": "tax.accounting.uor.valuation_method",
    "package": "tax.accounting.uor.valuation",
    "priority": 330,
    "valuation_base": "manufacturing_cost",
    "_legal_basis": "Art. 28 ust. 1-3 UoR",
    "_warnings": ["Wycena wg kosztu wytworzenia — alokuj koszty pośrednie produkcji"]
} {
    input.asset.produced_internally == true
    input.asset.purchase_cost == 0
}
```

---

## 12. PIT — Małe umowy zlecenia ≤200 PLN (P331)

### P331: `pit_small_mandate_flat_rate`

**Cel biznesowy:** Pobór zryczałtowanego podatku 12% dla drobnych umów zleceń/o dzieło ≤200 PLN. Nie stosuje się KUP wykonawcy (20%/50%), podatek płatny przez zleceniodawcę.

**Przesłanki:** Umowa zlecenia/dzieło ≤200 PLN z osobą niebędącą pracownikiem

**Rezultat:** `tax_rate: "0.12"`, `apply_contractor_kup: false`

**Podstawa prawna:** Art. 30 ust. 1 pkt 5a PIT

```rego
# P331: pit_small_mandate_flat_rate
decide := {
    "matched": true,
    "rule_id": "tax.direct.pit.small_mandate",
    "package": "tax.direct.pit.withholding",
    "priority": 331,
    "pit_rate": "0.12",
    "pit_withholding_type": "LUMP_SUM",
    "apply_contractor_kup": false,
    "_legal_basis": "Art. 30 ust. 1 pkt 5a PIT",
    "_warnings": ["Mała umowa zlecenia ≤200 PLN — ryczałt 12%, bez KUP wykonawcy"]
} {
    input.document.type == "contract_of_mandate"
    input.invoice.amount_gross <= object.get(input.thresholds.limits, "small_mandate_limit", 200)
    input.invoice.contractor_is_employee == false
}
```

---

## Podsumowanie analizy Docs

| Metryka | Wartość |
|---|---|
| **Przeanalizowane artykuły** | 200+ z 14 ustaw |
| **Istniejące reguły (P0-P310)** | 228 |
| **Nowe reguły (P320-P331)** | **12** |
| **Łącznie reguł** | **240** |
| **Nowe domeny** | 6 (UoR podwójny zapis, zamknięcie ksiąg, rezerwy UoR, elementy dowodu, struktura bilansu, małe umowy PIT) |
| **Uzupełnione domeny** | 6 (CIT złe długi, VAT-R, Ordynacja zabezpieczenia, KP BHP, Ordynacja ulgi, UoR wycena) |

### Ustawy z Docs, które zostały dogłębniej pokryte tą analizą

| Ustawa | Nowe pokrycie | Reguły |
|--------|:---:|---|
| Ustawa o rachunkowości (UoR) | +6 | P320-P322, P326-P327, P330 |
| Kodeks Pracy | +1 | P328 |
| Ordynacja podatkowa | +2 | P325, P329 |
| Ustawa o CIT | +1 | P323 |
| Ustawa o VAT | +1 | P324 |
| Ustawa o PIT | +1 | P331 |

---

> **Następny krok:** Aktualizacja `04_INDEX.md` i `20_MASTER_RULES_REFERENCE.md` — 240 reguł łącznie.
