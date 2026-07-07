# Roadmap Wdrożeniowy — 228 Reguł OPA w 13 Fazach

> **Status:** Plan Wdrożeniowy v1.0
> **Data:** 2026-07-07
> **Zakres:** Wszystkie 228 reguł z dokumentów 03-16
> **Poprzedza:** `05_ARCHITECTURE_DECISION.md` (ADR-001 Multi-Pass)

---

## 0. Przegląd

### 0.1 Metryki końcowe

| Metryka | Wartość |
|---|---|
| **Reguł łącznie** | 228 |
| **Domeny prawne** | 45+ |
| **Fazy implementacji** | 13 (Faza 0-12) |
| **Podstawy prawne** | 80+ cytowanych artykułów |
| **Zbadane projekty ref.** | 10 |
| **Dokumenty Plan OPA** | 18 (Docs + 00-16) |

### 0.2 Priorytety wdrożenia

```
KRYTYCZNE (P0) ──── Faza 0-1:   risk, routing .......... 20 reguł ... 2 tygodnie
WYSOKIE   (P1) ──── Faza 2-4:   compliance, crossborder,
                                 VAT substantive ......... 30 reguł ... 3 tygodnie
ŚREDNIE   (P2) ──── Faza 5-7:   CIT/PIT, ulgi, ZUS ..... 20 reguł ... 3 tygodnie
NISKIE    (P3) ──── Faza 8-12:  rozszerzenia ........... 158 reguł .. 6 tygodni
```

---

## 1. Faza 0: Fundament (ISTNIEJE)

**Status:** ✅ Zrealizowane
**Reguły:** P10-P19 (routing/confidence) + podstawowe VAT
**Pliki:** `nexus_ai/tax/rules.rego`
**Testy:** `tests/rego/tax_rules_test.rego`

| Reguła | Opis | Status |
|---|---|---|
| P10-P19 | Field confidence routing | ✅ |
| P52-P57 | VAT rates (fuel, food, books, exemptions) | ✅ |
| P100 | Domestic fallback 23% | ✅ |
| P200 | NO_MATCHING_RULE | ✅ |

---

## 2. Faza 1: Compliance (KRYTYCZNE)

**Priorytet:** P0 — BLOCK na błąd
**Czas:** 1 tydzień
**Reguły:** P20-P39
**Pliki:** `policies/tax/compliance.rego`

| Reguła | Priorytet | Podstawa prawna | Status |
|---|---|---|---|
| P20 | `whitelist_missing` | Art. 96b VAT | ✅ Zrobione |
| P21 | `whitelist_account_mismatch` | Art. 117ba Ordynacji | Do zrobienia |
| P25 | `split_payment_mandatory` | Art. 108a VAT | ✅ Zrobione |
| P28 | `ksef_structured_invoice` | Art. 106na-106nq VAT | Do zrobienia |
| P30 | `ksef_retention_faktura` | Art. 86 Ordynacji | Do zrobienia |
| P35 | `cash_transaction_over_limit` | Art. 22p PIT, 15d CIT | ✅ Zrobione |
| P36 | `payment_after_due_date` | Art. 53-56 Ordynacji | Do zrobienia |
| P38 | `statute_of_limitations` | Art. 70 Ordynacji | Do zrobienia |

**Testy:** `opa test policies/tax/compliance_test.rego`

---

## 3. Faza 2: Cross-border (WYSOKIE)

**Priorytet:** P1
**Czas:** 1 tydzień
**Reguły:** P40-P49
**Pliki:** `policies/tax/crossborder.rego`

| Reguła | Priorytet | Podstawa prawna | Status |
|---|---|---|---|
| P40 | `eu_reverse_charge` | Art. 17 VAT | ✅ Zrobione |
| P41 | `eu_import_services` | Art. 28b VAT | Do zrobienia |
| P42 | `wdt_intracommunity_supply` | Art. 42 VAT | Do zrobienia |
| P45 | `import_non_eu` | Art. 17 VAT | ✅ Zrobione |
| P48 | `export_goods` | Art. 41 ust. 4-11 VAT | ✅ Zrobione |

---

## 4. Faza 3: VAT substantive + GTU (WYSOKIE)

**Priorytet:** P1
**Czas:** 1.5 tygodnia
**Reguły:** P50-P69
**Pliki:** `policies/tax/vat/substantive.rego`, `policies/tax/vat/gtu.rego`

| Reguła | Priorytet | Podstawa prawna | Status |
|---|---|---|---|
| P50 | `vat_margin_scheme` | Art. 120 VAT | Do zrobienia |
| P52-P57 | VAT rates + exemptions | Art. 41, 43 VAT | Częściowo |
| P58 | `vat_exemption_subject` | Art. 113 VAT | Do zrobienia |
| P60 | `vat_bad_debt_relief` | Art. 89a VAT | Do zrobienia |
| P61 | `vat_prepayment_rule` | Art. 19a ust. 8 VAT | Do zrobienia |
| P65-P69 | GTU mapping | § 10 JPK_VAT | Do zrobienia |

---

## 5. Faza 4: Direct Taxes — CIT/PIT (ŚREDNIE)

**Priorytet:** P2
**Czas:** 1.5 tygodnia
**Reguły:** P70-P79
**Pliki:** `policies/tax/direct/cit.rego`, `policies/tax/direct/pit.rego`

| Reguła | Priorytet | Podstawa prawna |
|---|---|---|
| P70 | `cit_estonian_effective` | Rozdz. 6b CIT |
| P71 | `cit_small_taxpayer` | Art. 19 CIT |
| P72 | `cit_thin_capitalization` | Art. 15c CIT |
| P73 | `cit_standard_taxpayer` | Art. 19 CIT |
| P74 | `cit_loss_carry_forward` | Art. 7 ust. 5 CIT |
| P75 | `pit_tax_scale` | Art. 27 PIT |
| P76 | `pit_joint_filing` | Art. 6 ust. 2 PIT |
| P77-P79 | PIT exemptions | Art. 21 PIT |

---

## 6. Faza 5: Allowances — Ulgi (ŚREDNIE)

**Priorytet:** P2
**Czas:** 1 tydzień
**Reguły:** P80-P89
**Pliki:** `policies/tax/allowances.rego`

| Reguła | Podstawa prawna |
|---|---|
| P80 | `relief_rd` — Art. 26e PIT / 18d CIT |
| P81 | `relief_prototype` — Art. 26eb PIT |
| P82 | `relief_ip_box` — Art. 30ca PIT / 24d CIT |
| P83 | `relief_robotization` — Art. 26gb PIT / 38eb CIT |
| P84 | `relief_expansion` — Art. 26ec PIT / 18dc CIT |
| P85 | `relief_thermomodernization` — Art. 26h PIT |
| P86 | `relief_internet` — Art. 26 PIT |
| P87 | `relief_rehabilitation` — Art. 26 PIT |
| P88 | `relief_abolition` — Art. 27g PIT |
| P89 | `relief_working_senior` — Art. 21 PIT |

---

## 7. Faza 6-7: Accounting + ZUS (ŚREDNIE)

**Priorytet:** P2
**Czas:** 1 tydzień
**Reguły:** P90-P99
**Pliki:** `policies/tax/accounting.rego`, `policies/tax/zus.rego`

**Accounting (P90-P94):**
| Reguła | Podstawa prawna |
|---|---|
| P90 | `acc_depreciation_linear` — Art. 32 UoR |
| P91 | `acc_depreciation_degressive` — Art. 32 UoR |
| P92 | `acc_rmk_deferral` — Art. 39 UoR |
| P93 | `acc_fx_revaluation` — Art. 30 UoR |
| P94 | `acc_fifo_inventory` — Art. 28 UoR |

**ZUS (P95-P99):**
| Reguła | Podstawa prawna |
|---|---|
| P95 | `zus_maly_plus` — Art. 18c SUS |
| P96 | `zus_start_relief` — Art. 18a SUS |
| P97 | `zus_preferential` — Art. 18a SUS |
| P98 | `zus_health_contrib` — Art. 79-81 u. zdrowotnej |
| P99 | `zus_standard` — Art. 22 SUS |

---

## 8. Faza 8: Risk (KRYTYCZNE)

**Priorytet:** P0
**Czas:** 1 tydzień
**Reguły:** P0-P9
**Pliki:** `policies/tax/risk.rego`

| Reguła | Priorytet | Podstawa prawna | Status |
|---|---|---|---|
| P0 | `fraud_graph_match` | Art. 86 VAT, Art. 55 KKS | ✅ Zrobione |
| P1 | `counterparty_trust_low` | Art. 22 UoR | ✅ Zrobione |
| P2 | `anomaly_amount` | Art. 22 UoR | ✅ Zrobione |
| P3 | `new_counterparty_flag` | Art. 22 UoR | ✅ Zrobione |
| P5 | `semantic_guard_disallowed` | Art. 23 PIT, 16 CIT | ✅ Zrobione |

---

## 9-13. Fazy 9-12: Rozszerzenia (NISKIE)

**Priorytet:** P3
**Czas:** 6 tygodni (wszystkie fazy rozszerzeń)
**Reguły:** P110-P310 (158 reguł)
**Dokumenty źródłowe:**

| Faza | Dokument | Zakres | Reguły |
|---|---|---|---|
| 9 | `07_ADVANCED_RULES_EXPANSION.md` | PPK, Akcyza, IFRS, Leasing, AML, KŚT, JPK, Darowizny | 33 |
| 10 | `09_LEGAL_DEEP_DIVE_RULES.md` | VAT odliczenia, Praca, BDO, NGO, UoR, PKPiR | 27 |
| 11 | `11_ENTERPRISE_FINAL_EXPANSION.md` | VAT tax point/base, zaliczki, Ordynacja, UoR, spółdzielnie, energetyka, transport, KSeF/JPK, podatki lokalne | 36 |
| 12 | `14_SPECIALIZED_TAX_RULES.md` | CIT/PIT KUP, PCC, SD, dewizy, akcyza, KP, MSSF2, UoR zmiany | 21 |
| 13 | `16_FINAL_FRONTIER_RULES.md` | VAT enterprise sale/EU, zeznania roczne, KKS, TP, WNT, zdarzenia po bilansie, KSeF auth, JPK kary, AML | 16 |

---

## 10. Kamienie milowe

| Kamień milowy | Fazy | Reguły | Czas | Kryterium sukcesu |
|---|---|---|---|---|
| **M1: MVP** | 0-2 | 50 | 3 tyg. | Risk + Compliance + Crossborder + routing → `opa check --strict` PASS |
| **M2: Core Tax** | 3-4 | 30 | 3 tyg. | VAT substantive + CIT/PIT → `opa test` wszystkie zielone |
| **M3: Full Core** | 5-8 | 40 | 3 tyg. | Ulgi + Accounting + ZUS + Risk → Bundle API działa |
| **M4: Enterprise** | 9-13 | 158 | 6 tyg. | Wszystkie rozszerzenia → CI pipeline + monitoring |

---

## 11. Macierz ryzyka

| Ryzyko | Prawdopodobieństwo | Wpływ | Mitygacja |
|---|---|---|---|
| Zmiana przepisów w trakcie wdrożenia | Średnie | Wysoki | Temporal validation + thresholds zewnętrzne |
| Konflikty priorytetów w Multi-Pass | Niskie | Wysoki | ADR-001 VerdictMerger z testami integracyjnymi |
| Wydajność OPA przy 228 regułach | Niskie | Średni | Bundle API + atomic loading + warm-up |
| Brak spójności input fields | Średnie | Średni | Aktualizacja `01_INPUT_SPEC.md` przed każdą fazą |

---

## 12. Checklist per faza

Dla każdej fazy wdrożeniowej:

- [ ] Plik `.rego` utworzony z poprawnym `package`
- [ ] `default decide` zdefiniowany
- [ ] Else-chain zgodny z first-match-wins
- [ ] Wszystkie thresholdy przez `object.get()` (zero hardcoded)
- [ ] Każda reguła ma `rule_id`, `_legal_basis`, `_routing`
- [ ] `opa check --strict` przechodzi
- [ ] Minimum 2 testy na regułę (positive + negative)
- [ ] `opa test` wszystkie zielone
- [ ] Cross-reference zaktualizowany w `04_INDEX.md`
- [ ] Code review

---

## 13. Szacowany całkowity wysiłek

| Faza | Tygodnie | Deweloperzy | Osobotypodnie |
|---|---|---|---|
| 0 (istnieje) | — | — | 0 |
| 1-2 (compliance, crossborder) | 2 | 2 | 4 |
| 3-4 (VAT, CIT/PIT) | 3 | 2 | 6 |
| 5-8 (ulgi, accounting, ZUS, risk) | 3 | 2 | 6 |
| 9-13 (rozszerzenia) | 6 | 3 | 18 |
| **RAZEM** | **14** | — | **34** |

---

> **Następny krok:** `18_CONFTEST_AND_GENERAL_PATTERNS.md` — wzorce conftest dla testów i walidacji.
