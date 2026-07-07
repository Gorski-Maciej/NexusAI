# 📥 Specyfikacja Struktury `input` dla OPA/Rego

> **Status:** Specyfikacja v2.0 — ENTERPRISE (228 reguł, 18 dokumentów)  
> **Data:** 2026-07-07  
> **Powiązany:** `Plan OPA/00_PLAN_STRUKTURA.md`, `11_ENTERPRISE_FINAL_EXPANSION.md`, `14_SPECIALIZED_TAX_RULES.md`, `16_FINAL_FRONTIER_RULES.md`  
> **Nowe pola v2.0:** ~60 pól z dokumentów rozszerzeń (P230-P310)

---

## 1. Zasady ogólne

### 1.1 Filozofia `input`

Struktura `input` to **kontrakt między NexusAI a OPA**. Wszystkie dane potrzebne do podjęcia decyzji podatkowej muszą być w `input` — OPA NIGDY nie sięga do bazy danych, API zewnętrznych ani plików.

### 1.2 Konwencje nazewnicze

- **snake_case** dla wszystkich kluczy
- **Płaska struktura 2-poziomowa**: `input.<sekcja>.<pole>` (maksymalnie 2 poziomy dla czytelności)
- **Wartości liczbowe**: `number` w JSON (nie string — z wyjątkiem stawek procentowych przechowywanych jako string `"0.23"` dla uniknięcia błędów float)
- **Daty**: string ISO 8601 (`"2026-06-15"`)
- **Bool**: `true` / `false`

### 1.3 Typy pól

| Typ JSON | Użycie w Rego | Przykład |
|---|---|---|
| `number` | Porównania numeryczne (`>`, `<`, `>=`, `<=`) | `input.invoice.amount_net > 1000` |
| `string` | Porównania tekstowe (`==`, `!=`, `startswith`, `contains`) | `input.vendor.country == "PL"` |
| `boolean` | Warunki logiczne | `input.vendor.on_whitelist == false` |

---

## 2. Sekcje `input`

### 2.1 `input.invoice` — Dane faktury

| Pole | Typ | Wymagane | Opis | Przykład |
|---|---|---|---|---|
| `category_code` | `string` | **TAK** | Kod kategorii wydatku (FUEL, IT_OFFICE, FOOD, itd.) | `"FUEL"` |
| `transaction_date` | `string` | **TAK** | Data transakcji (ISO 8601) | `"2026-06-15"` |
| `amount_net` | `number` | **TAK** | Kwota netto w PLN | `10000.00` |
| `amount_net_grosze` | `number` | **TAK** | Kwota netto w groszach (integer) | `1000000` |
| `amount_gross` | `number` | **TAK** | Kwota brutto w PLN | `12300.00` |
| `amount_gross_grosze` | `number` | **TAK** | Kwota brutto w groszach (integer) | `1230000` |
| `currency` | `string` | **TAK** | Kod waluty ISO 4217 | `"PLN"` |
| `procedure` | `string` | Nie | Procedura specjalna (MARGIN, PREPAYMENT, IMPORT) | `""` |
| `expense_type` | `string` | Nie | Typ wydatku (OPERATIONAL, FIXED_ASSET, INVENTORY) | `"OPERATIONAL"` |
| `pkwiu_code` | `string` | Nie | Kod PKWiU (dla ryczałtu) | `"62.01.12.0"` |
| `is_cash_payment` | `boolean` | Nie | Czy płatność gotówkowa | `false` |
| `is_advance` | `boolean` | Nie | Czy zaliczka | `false` |
| `invoice_number` | `string` | Nie | Numer faktury | `"FV/2026/06/001"` |
| `issue_date` | `string` | Nie | Data wystawienia | `"2026-06-15"` |
| `due_date` | `string` | Nie | Termin płatności | `"2026-07-15"` |
| `is_paid` | `boolean` | Nie | Czy faktura opłacona | `false` |
| `days_overdue` | `number` | Nie | Dni po terminie (dla ulgi na złe długi) | `0` |
| `vat_on_import` | `boolean` | Nie | VAT od importu (zgoda na rozliczenie) | `false` |
| `is_continuous_service` | `boolean` | Nie | Czy usługa ciągła (P230) | `true` |
| `invoice_type` | `string` | Nie | Typ faktury (ADVANCE dla zaliczkowej, P231) | `"ADVANCE"` |
| `discount_amount` | `number` | Nie | Wartość rabatu do pomniejszenia podstawy (P232) | `500.00` |
| `has_returnable_packaging` | `boolean` | Nie | Czy faktura zawiera opakowania zwrotne (P233) | `true` |
| `packaging_returned` | `boolean` | Nie | Czy opakowania zwrócone (P233) | `false` |
| `days_since_delivery` | `number` | Nie | Dni od dostawy (dla opakowań zwrotnych, P233) | `65` |
| `delivery_date` | `string` | Nie | Data dostawy towaru/usługi (P234) | `"2026-06-10"` |
| `fx_rate_payment` | `number` | Nie | Kurs waluty w dniu zapłaty (P238) | `4.35` |
| `fx_rate_invoice` | `number` | Nie | Kurs waluty na fakturze (P238) | `4.25` |
| `is_due` | `boolean` | Nie | Czy faktura wymagalna (P239) | `true` |
| `withholding_tax_applicable` | `boolean` | Nie | Czy WHT applicable (P243) | `true` |
| `language` | `string` | Nie | Język dokumentu (P246) | `"EN"` |
| `days_since_issue` | `number` | Nie | Dni od wystawienia (P247, księgowania) | `20` |
| `is_correction` | `boolean` | Nie | Czy faktura korygująca (P261, P301) | `true` |
| `modifies_closed_vat_period` | `boolean` | Nie | Czy korekta dotyczy zamkniętego okresu VAT (P261) | `true` |
| `type` | `string` | Nie | Typ towaru/usługi: SERVICE, GOODS (P262) | `"SERVICE"` |
| `vehicle_weight_kg` | `number` | Nie | Masa pojazdu w kg (transport, P256) | `12000` |
| `is_cabotage` | `boolean` | Nie | Czy operacja kabotażu (P257) | `true` |
| `is_personal_expense` | `boolean` | Nie | Wydatek osobisty — NKUP (P274) | `false` |
| `is_documented_uncollectible` | `boolean` | Nie | Należność uprawdopodobniona jako nieściągalna (P270) | `false` |
| `months_since_issue` | `number` | Nie | Miesiące od wystawienia (P277, VAT odliczenie) | `4` |
| `is_vat_deducted` | `boolean` | Nie | Czy VAT już odliczony (P277) | `false` |
| `vat_taxable` | `boolean` | Nie | Czy podlega VAT (P278, PCC) | `true` |
| `months_since_acquisition` | `number` | Nie | Miesiące od nabycia (SD-Z2, P281) | `3` |
| `is_excise_good` | `boolean` | Nie | Czy wyrób akcyzowy (P284) | `true` |
| `years_since_last_award` | `number` | Nie | Lata od ostatniej nagrody jubileuszowej (P285) | `5` |
| `amount_daily` | `number` | Nie | Kwota dzienna (delegacje, P287) | `200.00` |
| `accounting_event` | `string` | Nie | Zdarzenie księgowe: POLICY_CHANGE, FUNDAMENTAL_ERROR_CORRECTION (P289-P290) | `"POLICY_CHANGE"` |
| `crossborder_type` | `string` | Nie | Typ transakcji transgranicznej: WNT, WDT (P296, P305) | `"WNT"` |
| `correction_type` | `string` | Nie | Typ korekty: IN_MINUS, IN_PLUS (P301) | `"IN_MINUS"` |
| `has_buyer_agreement` | `boolean` | Nie | Czy uzgodniono korektę z nabywcą (P301) | `false` |
| `issue_date_resolved` | `boolean` | Nie | Czy data faktury znana (WNT, P305) | `false` |
| `event_date` | `string` | Nie | Data zdarzenia po bilansie (P306) | `"2026-05-15"` |
| `is_adjusting_event` | `boolean` | Nie | Czy zdarzenie korygujące bilans (P306) | `true` |

### 2.2 `input.vendor` — Dane kontrahenta

| Pole | Typ | Wymagane | Opis | Przykład |
|---|---|---|---|---|
| `nip` | `string` | **TAK** | NIP kontrahenta (10 cyfr) | `"1234567890"` |
| `country` | `string` | **TAK** | Kraj kontrahenta (PL, EU, NON_EU) | `"PL"` |
| `vat_status` | `string` | **TAK** | Status VAT (active, exempt, unknown) | `"active"` |
| `on_whitelist` | `boolean` | **TAK** | Czy na Białej Liście MF | `true` |
| `whitelist_checked_at` | `string` | Nie | Data sprawdzenia WL (ISO 8601) | `"2026-06-15T10:00:00Z"` |
| `account_on_whitelist` | `boolean` | Nie | Czy rachunek na Białej Liście | `true` |
| `pkd` | `string` | Nie | Kod PKD kontrahenta | `"62.01.Z"` |
| `is_related_party` | `boolean` | Nie | Czy podmiot powiązany (TP) | `false` |
| `trust_score` | `number` | Nie | Trust Score kontrahenta (0.0-1.0) | `0.92` |
| `fraud_flag` | `boolean` | Nie | Czy kontrahent w sieci fraudowej | `false` |
| `is_new` | `boolean` | Nie | Czy nowy kontrahent (<3 faktur) | `false` |
| `debt_to_equity_ratio` | `number` | Nie | Wskaźnik zadłużenia (cienka kapitalizacja) | `2.5` |
| `has_residence_certificate` | `boolean` | Nie | Czy kontrahent ma certyfikat rezydencji (WHT, P243) | `true` |
| `has_transport_license` | `boolean` | Nie | Czy przewoźnik ma licencję transportową (P256) | `true` |
| `is_b2b_buyer` | `boolean` | Nie | Czy nabywca B2B (miejsce świadczenia, P262) | `true` |
| `is_b2c` | `boolean` | Nie | Czy sprzedaż konsumencka / B2C (KSeF, P258) | `false` |
| `annual_transaction_value` | `number` | Nie | Roczna wartość transakcji z podmiotem powiązanym (TP, P302) | `5000000.00` |
| `whitelist_status` | `string` | Nie | Szczegółowy status WL: VERIFIED, NOT_FOUND (ZAW-NR, P308) | `"NOT_FOUND"` |
| `aml_risk_assessment_done` | `boolean` | Nie | Czy ocena ryzyka AML wykonana (P310) | `false` |

### 2.3 `input.company` — Dane firmy (podatnika)

| Pole | Typ | Wymagane | Opis | Przykład |
|---|---|---|---|---|
| `tax_form` | `string` | **TAK** | Forma opodatkowania | `"CIT_STANDARD"` |
| `zus_status` | `string` | **TAK** | Status ZUS | `"MALY_ZUS_PLUS"` |
| `is_vat_payer` | `boolean` | **TAK** | Czy czynny podatnik VAT | `true` |
| `is_small_taxpayer` | `boolean` | Nie | Czy mały podatnik (CIT 9%) | `false` |
| `annual_turnover_net` | `number` | Nie | Roczny obrót netto | `500000.00` |
| `has_rd_status` | `boolean` | Nie | Czy ma status B+R | `false` |
| `fiscal_year_start` | `string` | Nie | Początek roku podatkowego | `"2026-01-01"` |
| `employees_count` | `number` | Nie | Liczba pracowników | `5` |
| `taxpayer_age` | `number` | Nie | Wiek podatnika (dla ulgi dla młodych) | `25` |
| `children_count` | `number` | Nie | Liczba dzieci (dla ulgi 4+) | `2` |
| `joint_filing` | `boolean` | Nie | Czy wspólne rozliczenie małżonków | `false` |
| `return_from_emigration` | `boolean` | Nie | Czy ulga na powrót | `false` |
| `return_years_used` | `number` | Nie | Wykorzystane lata ulgi na powrót | `0` |
| `rd_is_centrum` | `boolean` | Nie | Czy Centrum Badawczo-Rozwojowe | `false` |
| `zus_months_used` | `number` | Nie | Wykorzystane miesiące ulgi ZUS | `12` |
| `internet_years_used` | `number` | Nie | Wykorzystane lata ulgi internetowej | `0` |
| `has_loss_carry_forward` | `boolean` | Nie | Czy strata do rozliczenia | `false` |
| `loss_carry_forward_amount` | `number` | Nie | Kwota straty do rozliczenia | `50000.00` |
| `loss_carry_forward_year` | `number` | Nie | Rok poniesienia straty | `2024` |
| `uses_simplified_advances` | `boolean` | Nie | Czy uproszczone zaliczki CIT (P236) | `false` |
| `chooses_quarterly_advances` | `boolean` | Nie | Czy kwartalne zaliczki PIT (P237) | `false` |
| `status` | `string` | Nie | Status firmy: BANKRUPTCY, ACTIVE (P245) | `"ACTIVE"` |
| `total_assets_eur` | `number` | Nie | Suma aktywów w EUR (audyt, P248) | `3000000` |
| `net_revenue_eur` | `number` | Nie | Przychód netto w EUR (audyt, P248) | `6000000` |
| `is_accounting_month_closed` | `boolean` | Nie | Czy miesiąc księgowy zamknięty (P247) | `false` |
| `audit_required` | `boolean` | Nie | Czy badanie sprawozdania obowiązkowe (P249) | `true` |
| `legal_form` | `string` | Nie | Forma prawna: HOUSING_COOPERATIVE, COOPERATIVE (P252-P253) | `"HOUSING_COOPERATIVE"` |
| `net_profit_generated` | `boolean` | Nie | Czy wygenerowano zysk (fundusz spółdzielni, P253) | `true` |
| `has_ure_concession` | `boolean` | Nie | Czy koncesja URE (obrót energią, P254) | `true` |
| `energy_source` | `string` | Nie | Źródło energii: RENEWABLE, FOSSIL (P255) | `"RENEWABLE"` |
| `cabotage_operations_7days` | `number` | Nie | Liczba operacji kabotażowych/7d (P257) | `2` |
| `uses_full_accounting` | `boolean` | Nie | Czy pełna księgowość (JPK_KR, P260) | `true` |
| `owns_guard_dog` | `boolean` | Nie | Czy firma posiada psy stróżujące (P265) | `false` |
| `is_dog_registered_in_municipality` | `boolean` | Nie | Czy pies zarejestrowany w gminie (P265) | `true` |
| `is_mandatory_membership` | `boolean` | Nie | Czy przynależność do organizacji obowiązkowa (P271) | `false` |
| `vat_pre_pro_rata_applicable` | `boolean` | Nie | Czy pre-proporcja VAT ma zastosowanie (P276) | `false` |
| `vat_pre_pro_rata_percent` | `number` | Nie | Wskaźnik pre-proporcji VAT % (P276) | `85` |
| `tax_group` | `number` | Nie | Grupa podatkowa SD: 0=najbliższa rodzina (P281) | `0` |
| `has_fx_permit` | `boolean` | Nie | Czy zezwolenie dewizowe NBP (P282) | `false` |
| `uses_ifrs` | `boolean` | Nie | Czy stosuje MSSF (MSSF 2, P288) | `false` |
| `is_vat_eu_registered` | `boolean` | Nie | Czy zarejestrowany jako VAT-UE (P296) | `true` |
| `tax_return_filed` | `boolean` | Nie | Czy zeznanie roczne złożone (P297-P298) | `false` |
| `has_related_party_transactions` | `boolean` | Nie | Czy transakcje z podmiotami powiązanymi (TPR, P303) | `true` |
| `is_aml_obligated_institution` | `boolean` | Nie | Czy instytucja obowiązana AML (P310) | `false` |
| `jpk_correction_summon_active` | `boolean` | Nie | Czy aktywne wezwanie do korekty JPK (P309) | `false` |
| `balance_sheet_date` | `string` | Nie | Data bilansowa (UoR, P306) | `"2025-12-31"` |
| `is_fs_approved` | `boolean` | Nie | Czy sprawozdanie zatwierdzone (P306) | `false` |
| `under_tax_audit` | `boolean` | Nie | Czy trwa kontrola podatkowa (KKS, P299) | `false` |

### 2.4 `input.confidence` — Pewność pól OCR

| Pole | Typ | Wymagane | Opis | Przykład |
|---|---|---|---|---|
| `fc_minimum` | `number` | **TAK** | Minimalna pewność wszystkich pól | `0.95` |
| `fc_vat_rate` | `number` | **TAK** | Pewność stawki VAT | `0.98` |
| `fc_total_net` | `number` | **TAK** | Pewność kwoty netto | `0.97` |
| `fc_vendor_nip` | `number` | **TAK** | Pewność NIP kontrahenta | `0.99` |
| `fc_category_code` | `number` | **TAK** | Pewność kategorii wydatku | `0.96` |
| `fc_invoice_number` | `number` | Nie | Pewność numeru faktury | `0.99` |
| `fc_total_gross` | `number` | Nie | Pewność kwoty brutto | `0.97` |
| `fc_transaction_date` | `number` | Nie | Pewność daty transakcji | `0.98` |
| `fc_vendor_name` | `number` | Nie | Pewność nazwy kontrahenta | `0.95` |

### 2.5 `input.tax_type` — Kontekst podatkowy (NOWE v2.0)

| Pole | Typ | Wymagane | Opis | Przykład |
|---|---|---|---|---|
| `tax_type` | `string` | Nie | Typ podatku/zdarzenia: VAT, CIT_ADVANCE, CIT_ANNUAL, PIT_ANNUAL (P240-P241, P297-P298, P303) | `"VAT"` |

### 2.6 `input.document` — Metadane dokumentu (NOWE v2.0)

| Pole | Typ | Wymagane | Opis | Przykład |
|---|---|---|---|---|
| `type` | `string` | Nie | Typ dokumentu: ACCOUNTING_PROOF, PAYROLL_RECORD, CZYNNY_ZAL (P250-P251, P299) | `"ACCOUNTING_PROOF"` |
| `filing_date_mm_dd` | `string` | Nie | Data złożenia w formacie MM-DD (P297) | `"05-15"` |
| `months_since_fye` | `number` | Nie | Miesiące od końca roku podatkowego (P298) | `4` |
| `tax_status` | `string` | Nie | Status podatkowy: OVERPAYMENT (P300) | `"OVERPAYMENT"` |
| `days_since_declaration` | `number` | Nie | Dni od deklaracji (nadpłata, P300) | `50` |
| `zaw_nr_filed` | `boolean` | Nie | Czy złożono ZAW-NR (P308) | `true` |
| `zaw_nr_days_since_transfer` | `number` | Nie | Dni od przelewu do ZAW-NR (P308) | `5` |
| `days_since_summon` | `number` | Nie | Dni od wezwania do korekty JPK (P309) | `21` |

### 2.7 `input.system` — Stan systemu (NOWE v2.0)

| Pole | Typ | Wymagane | Opis | Przykład |
|---|---|---|---|---|
| `ksef_status` | `string` | Nie | Status KSeF: ONLINE, OFFLINE (P259) | `"ONLINE"` |
| `target` | `string` | Nie | Cel operacji: KSEF (P307) | `"KSEF"` |
| `auth_token_exists` | `boolean` | Nie | Czy token KSeF istnieje (P307) | `true` |
| `qualified_signature_exists` | `boolean` | Nie | Czy podpis kwalifikowany dostępny (P307) | `false` |

### 2.8 `input.request` — Kontekst zapytania (NOWE v2.0)

| Pole | Typ | Wymagane | Opis | Przykład |
|---|---|---|---|---|
| `type` | `string` | Nie | Typ zapytania: TAX_AUDIT (JPK_KR, P260) | `"TAX_AUDIT"` |

### 2.9 `input.thresholds` — Parametry dynamiczne

> **UWAGA:** Wszystkie wartości liczbowe progów, stawek i limitów. ZERO hardcoded values w `.rego`.

Pełny katalog w: `Plan OPA/02_THRESHOLDS_CATALOG.md`

#### 2.5.1 `input.thresholds.rates.*`

| Klucz | Typ | Przykład | Opis |
|---|---|---|---|
| `rates.vat_standard` | `string` | `"0.23"` | Podstawowa stawka VAT |
| `rates.vat_reduced_8` | `string` | `"0.08"` | Stawka obniżona 8% |
| `rates.vat_reduced_5` | `string` | `"0.05"` | Stawka obniżona 5% |
| `rates.vat_zero` | `string` | `"0.00"` | Stawka 0% / zwolnienie |
| `rates.cit_standard` | `string` | `"0.19"` | CIT 19% |
| `rates.cit_small` | `string` | `"0.09"` | CIT 9% (mały podatnik) |
| `rates.cit_estonian_effective` | `string` | `"0.20"` | CIT estoński efektywny |
| `rates.pit_scale_low` | `string` | `"0.12"` | PIT 12% (I próg) |
| `rates.pit_scale_high` | `string` | `"0.32"` | PIT 32% (II próg) |
| `rates.pit_linear` | `string` | `"0.19"` | PIT liniowy 19% |
| `rates.pit_ip_box` | `string` | `"0.05"` | IP Box 5% |
| `rates.zus_pension` | `string` | `"0.1952"` | Składka emerytalna |
| `rates.zus_disability` | `string` | `"0.08"` | Składka rentowa |
| `rates.zus_sickness` | `string` | `"0.0245"` | Składka chorobowa |
| `rates.zus_accident` | `string` | `"0.0167"` | Składka wypadkowa |
| `rates.zus_health` | `string` | `"0.09"` | Składka zdrowotna (skala) |
| `rates.zus_health_lump` | `string` | `"0.049"` | Składka zdrowotna (liniowy/ryczałt) |
| `rates.zus_labour_fund` | `string` | `"0.0245"` | Fundusz Pracy |
| `rates.zus_fgsp` | `string` | `"0.001"` | FGŚP |

#### 2.5.2 `input.thresholds.bounds.*`

| Klucz | Typ | Przykład | Opis |
|---|---|---|---|
| `bounds.pit_scale_threshold` | `number` | `120000` | Próg 12%→32% |
| `bounds.pit_tax_free_amount` | `number` | `30000` | Kwota wolna od podatku |
| `bounds.pit_tax_free_reduction` | `number` | `3600` | Kwota zmniejszająca podatek |
| `bounds.pit_young_exemption_limit` | `number` | `85528` | Limit ulgi dla młodych |
| `bounds.relief_thermo_max` | `number` | `53000` | Max ulgi termomodernizacyjnej |
| `bounds.relief_internet_max` | `number` | `760` | Max ulgi internetowej |
| `bounds.relief_rd_base` | `number` | `100` | Ulga B+R podst. (%) |
| `bounds.relief_rd_centrum` | `number` | `200` | Ulga B+R centrum (%) |
| `bounds.zus_maly_plus_months` | `number` | `36` | Okres Małego ZUS+ |
| `bounds.zus_start_months` | `number` | `6` | Okres ulgi na start |

#### 2.5.3 `input.thresholds.fc_thresholds.*`

| Klucz | Typ | Przykład | Dla kogo |
|---|---|---|---|
| `fc_thresholds.cit_standard_vat_rate` | `number` | `0.98` | CIT standard |
| `fc_thresholds.cit_standard_total_net` | `number` | `0.95` | CIT standard |
| `fc_thresholds.cit_standard_minimum` | `number` | `0.85` | CIT standard |
| `fc_thresholds.cit_estonian_vat_rate` | `number` | `0.95` | CIT estoński |
| `fc_thresholds.linear_minimum` | `number` | `0.85` | Podatek liniowy |
| `fc_thresholds.lump_sum_vat_rate` | `number` | `0.95` | Ryczałt |
| `fc_thresholds.lump_sum_total_net` | `number` | `0.60` | Ryczałt |
| `fc_thresholds.vendor_nip` | `number` | `0.80` | Uniwersalny |
| `fc_thresholds.category_code` | `number` | `0.80` | Uniwersalny |
| `fc_thresholds.global_minimum` | `number` | `0.70` | Uniwersalny |

#### 2.5.4 `input.thresholds.limits.*`

| Klucz | Typ | Przykład | Opis |
|---|---|---|---|
| `limits.mpp_limit` | `number` | `15000` | Próg MPP (15 000 PLN) |
| `limits.vat_exemption_limit` | `number` | `200000` | Zwolnienie podmiotowe VAT |
| `limits.cash_transaction_limit` | `number` | `15000` | Limit płatności gotówkowych |
| `limits.bad_debt_days` | `number` | `150` | Dni dla ulgi na złe długi |
| `limits.thin_cap_ratio` | `number` | `3.0` | Wskaźnik cienkiej kapitalizacji |
| `limits.transfer_pricing_limit` | `number` | `10000000` | Próg dokumentacji TP |
| `limits.tp_service_limit` | `number` | `2000000` | Próg TP dla usług (P302) |
| `limits.retention_years_invoice` | `number` | `5` | Okres przechowywania faktur |
| `limits.retention_years_ledger` | `number` | `5` | Okres przechowywania ksiąg |
| `limits.retention_years_payroll` | `number` | `10` | Okres przechowywania list płac |
| `limits.overpayment_refund_days` | `number` | `45` | Termin zwrotu nadpłaty (P300) |
| `limits.per_diem_limit` | `number` | `45` | Limit diety dziennej PLN (P287) |
| `limits.zaw_nr_deadline_days` | `number` | `7` | Termin ZAW-NR od przelewu (P308) |
| `limits.trust_auto_post` | `number` | `0.92` | Próg AUTO_POST |
| `limits.trust_suggest` | `number` | `0.75` | Próg SUGGEST |
| `limits.jpk_correction_days` | `number` | `14` | Dni na korektę JPK przed karą (P309) |

---

## 3. Walidacja `input`

### 3.1 Pola wymagane (bez których OPA nie może podjąć decyzji)

```rego
# Walidacja minimalna — wykonywana przed ewaluacją reguł
required_fields := [
    "invoice.category_code",
    "invoice.transaction_date", 
    "vendor.country",
    "vendor.vat_status",
    "company.tax_form",
    "confidence.fc_minimum",
]
```

### 3.2 Wartości dozwolone (enum-like checks)

| Pole | Dozwolone wartości |
|---|---|
| `vendor.country` | `"PL"`, `"EU"`, `"NON_EU"` |
| `vendor.vat_status` | `"active"`, `"exempt"`, `"unknown"` |
| `company.tax_form` | `"CIT_STANDARD"`, `"CIT_ESTONIAN"`, `"PIT_SCALE"`, `"LINEAR"`, `"LUMP_SUM"` |
| `company.zus_status` | `"STANDARD"`, `"MALY_ZUS_PLUS"`, `"PREFERENTIAL"`, `"START_RELIEF"` |
| `invoice.expense_type` | `"OPERATIONAL"`, `"FIXED_ASSET"`, `"INVENTORY"`, `"INTANGIBLE"`, `"FREE_BENEFIT_RECEIVED"`, `"ENTERPRISE_ACQUISITION"`, `"FREE_SAMPLE"`, `"IMPAIRMENT"`, `"MEMBERSHIP_FEE"`, `"SHARE_ACQUISITION"`, `"EXECUTION_COST"`, `"ZUS_SOCIAL_EMPLOYEE_PART"`, `"DONATION_RECEIVED"`, `"SALE_AGREEMENT"`, `"LOAN_AGREEMENT"`, `"CAPITAL_INCREASE"`, `"SHARE_BASED_PAYMENT"`, `"JUBILEE_AWARD"`, `"WORKWEAR_EQUIVALENT"`, `"BUSINESS_TRIP_ALLOWANCE"`, `"ENTERPRISE_SALE"`, `"ZUS_HEALTH"` |
| `invoice.procedure` | `""`, `"MARGIN"`, `"PREPAYMENT"`, `"IMPORT"`, `"WDT"`, `"EXPORT"`, `"TAX_WAREHOUSE_SUSPENSION"` |
| `invoice.category_code` dodatkowe | `"HOUSING_MAINTENANCE"`, `"ENERGY_TRADING"`, `"RESTRICTED_FX"` (vendor.country) |
| `invoice.crossborder_type` | `""`, `"WNT"`, `"WDT"` |
| `invoice.correction_type` | `""`, `"IN_MINUS"`, `"IN_PLUS"` |
| `company.legal_form` | `""`, `"HOUSING_COOPERATIVE"`, `"COOPERATIVE"` |
| `company.energy_source` | `""`, `"RENEWABLE"`, `"FOSSIL"` |
| `document.type` | `"ACCOUNTING_PROOF"`, `"PAYROLL_RECORD"`, `"CZYNNY_ZAL"` |
| `tax_type` | `""`, `"VAT"`, `"CIT_ADVANCE"`, `"CIT_ANNUAL"`, `"PIT_ANNUAL"` |

### 3.3 Walidacja daty

```rego
# Sprawdzenie czy data jest >= 2000-01-01 (sanity check)
valid_date {
    input.invoice.transaction_date >= "2000-01-01"
}
```

---

## 4. Przykład kompletnego `input` (v2.0 ENTERPRISE)

```json
{
  "invoice": {
    "category_code": "FUEL",
    "transaction_date": "2026-06-15",
    "amount_net": 18000.00,
    "amount_net_grosze": 1800000,
    "amount_gross": 22140.00,
    "amount_gross_grosze": 2214000,
    "currency": "PLN",
    "procedure": "",
    "expense_type": "OPERATIONAL",
    "pkwiu_code": "",
    "is_cash_payment": false,
    "is_advance": false,
    "invoice_number": "FV/2026/06/042",
    "issue_date": "2026-06-15",
    "due_date": "2026-07-15",
    "is_paid": false,
    "days_overdue": 0,
    "vat_on_import": false,
    "is_continuous_service": false,
    "invoice_type": "",
    "discount_amount": 0,
    "has_returnable_packaging": false,
    "packaging_returned": false,
    "days_since_delivery": 0,
    "delivery_date": "2026-06-14",
    "fx_rate_payment": 0,
    "fx_rate_invoice": 0,
    "is_due": false,
    "withholding_tax_applicable": false,
    "language": "PL",
    "days_since_issue": 22,
    "is_correction": false,
    "modifies_closed_vat_period": false,
    "type": "GOODS",
    "vehicle_weight_kg": 0,
    "is_cabotage": false,
    "is_personal_expense": false,
    "is_documented_uncollectible": false,
    "months_since_issue": 0,
    "is_vat_deducted": true,
    "vat_taxable": true,
    "months_since_acquisition": 0,
    "is_excise_good": false,
    "years_since_last_award": 0,
    "amount_daily": 0,
    "accounting_event": "",
    "crossborder_type": "",
    "correction_type": "",
    "has_buyer_agreement": false,
    "issue_date_resolved": true,
    "event_date": "",
    "is_adjusting_event": false
  },
  "vendor": {
    "nip": "1234567890",
    "country": "PL",
    "vat_status": "active",
    "on_whitelist": true,
    "whitelist_checked_at": "2026-06-15T10:00:00Z",
    "account_on_whitelist": true,
    "whitelist_status": "VERIFIED",
    "pkd": "47.30.Z",
    "is_related_party": false,
    "trust_score": 0.92,
    "fraud_flag": false,
    "is_new": false,
    "debt_to_equity_ratio": 0.0,
    "has_residence_certificate": false,
    "has_transport_license": true,
    "is_b2b_buyer": false,
    "is_b2c": false,
    "annual_transaction_value": 0,
    "aml_risk_assessment_done": true
  },
  "company": {
    "tax_form": "CIT_STANDARD",
    "zus_status": "STANDARD",
    "is_vat_payer": true,
    "is_small_taxpayer": false,
    "annual_turnover_net": 2000000.00,
    "has_rd_status": false,
    "fiscal_year_start": "2026-01-01",
    "employees_count": 12,
    "taxpayer_age": 0,
    "children_count": 0,
    "joint_filing": false,
    "return_from_emigration": false,
    "return_years_used": 0,
    "rd_is_centrum": false,
    "zus_months_used": 0,
    "internet_years_used": 0,
    "has_loss_carry_forward": false,
    "loss_carry_forward_amount": 0,
    "loss_carry_forward_year": 0,
    "uses_simplified_advances": false,
    "chooses_quarterly_advances": false,
    "status": "ACTIVE",
    "total_assets_eur": 3500000,
    "net_revenue_eur": 7000000,
    "is_accounting_month_closed": false,
    "audit_required": true,
    "legal_form": "",
    "net_profit_generated": true,
    "has_ure_concession": false,
    "energy_source": "",
    "cabotage_operations_7days": 0,
    "uses_full_accounting": true,
    "owns_guard_dog": false,
    "is_dog_registered_in_municipality": false,
    "is_mandatory_membership": false,
    "vat_pre_pro_rata_applicable": false,
    "vat_pre_pro_rata_percent": 0,
    "tax_group": 0,
    "has_fx_permit": true,
    "uses_ifrs": false,
    "is_vat_eu_registered": true,
    "tax_return_filed": true,
    "has_related_party_transactions": false,
    "is_aml_obligated_institution": false,
    "jpk_correction_summon_active": false,
    "balance_sheet_date": "2025-12-31",
    "is_fs_approved": true,
    "under_tax_audit": false
  },
  "tax_type": "VAT",
  "document": {
    "type": "ACCOUNTING_PROOF",
    "filing_date_mm_dd": "04-15",
    "months_since_fye": 0,
    "tax_status": "",
    "days_since_declaration": 0,
    "zaw_nr_filed": false,
    "zaw_nr_days_since_transfer": 0,
    "days_since_summon": 0
  },
  "system": {
    "ksef_status": "ONLINE",
    "target": "",
    "auth_token_exists": true,
    "qualified_signature_exists": true
  },
  "request": {
    "type": ""
  },
  "confidence": {
    "fc_minimum": 0.97,
    "fc_vat_rate": 0.99,
    "fc_total_net": 0.98,
    "fc_vendor_nip": 0.99,
    "fc_category_code": 0.97,
    "fc_invoice_number": 0.99,
    "fc_total_gross": 0.98,
    "fc_transaction_date": 0.99,
    "fc_vendor_name": 0.96
  },
  "thresholds": {
    "rates": {
      "vat_standard": "0.23",
      "vat_reduced_8": "0.08",
      "vat_reduced_5": "0.05",
      "vat_zero": "0.00",
      "cit_standard": "0.19",
      "cit_small": "0.09",
      "cit_estonian_effective": "0.20",
      "pit_scale_low": "0.12",
      "pit_scale_high": "0.32",
      "pit_linear": "0.19",
      "pit_ip_box": "0.05",
      "zus_pension": "0.1952",
      "zus_disability": "0.08",
      "zus_sickness": "0.0245",
      "zus_accident": "0.0167",
      "zus_health": "0.09",
      "zus_health_lump": "0.049",
      "zus_labour_fund": "0.0245",
      "zus_fgsp": "0.001"
    },
    "bounds": {
      "pit_scale_threshold": 120000,
      "pit_tax_free_amount": 30000,
      "pit_tax_free_reduction": 3600,
      "pit_young_exemption_limit": 85528,
      "pit_return_exemption_limit": 85528,
      "pit_family_4plus_limit": 85528,
      "relief_thermo_max": 53000,
      "relief_internet_max": 760,
      "relief_internet_years": 2,
      "relief_rd_base": 100,
      "relief_rd_centrum": 200,
      "relief_prototype_percent": 30,
      "relief_robotization_percent": 50,
      "relief_expansion_max": 1000000,
      "zus_maly_plus_months": 36,
      "zus_maly_plus_min_wage_percent": 0.30,
      "zus_start_months": 6
    },
    "fc_thresholds": {
      "cit_standard_vat_rate": 0.98,
      "cit_standard_total_net": 0.95,
      "cit_standard_minimum": 0.85,
      "cit_estonian_vat_rate": 0.95,
      "linear_minimum": 0.85,
      "lump_sum_vat_rate": 0.95,
      "lump_sum_total_net": 0.60,
      "mixed_auto_minimum": 0.90,
      "representation_minimum": 0.95,
      "vendor_nip": 0.80,
      "category_code": 0.80,
      "global_minimum": 0.70
    },
    "limits": {
      "mpp_limit": 15000,
      "vat_exemption_limit": 200000,
      "cash_transaction_limit": 15000,
      "bad_debt_days": 150,
      "thin_cap_ratio": 3.0,
      "transfer_pricing_limit": 10000000,
      "retention_years_invoice": 5,
      "retention_years_ledger": 5,
      "retention_years_payroll": 10,
      "trust_auto_post": 0.92,
      "trust_suggest": 0.75
    }
  }
}
```

---

## 5. Mapowanie pól → reguły (v2.0)

| Pole `input` | Używane przez reguły |
|---|---|
| `invoice.is_continuous_service` | P230 |
| `invoice.invoice_type` | P231 |
| `invoice.discount_amount` | P232 |
| `invoice.has_returnable_packaging` | P233 |
| `invoice.packaging_returned` | P233 |
| `invoice.days_since_delivery` | P233 |
| `invoice.delivery_date` | P234 |
| `invoice.fx_rate_payment` | P238 |
| `invoice.fx_rate_invoice` | P238 |
| `invoice.is_due` | P239 |
| `invoice.withholding_tax_applicable` | P243 |
| `invoice.language` | P246 |
| `invoice.days_since_issue` | P247 |
| `invoice.is_correction` | P261, P301 |
| `invoice.modifies_closed_vat_period` | P261 |
| `invoice.type` | P262 |
| `invoice.crossborder_type` | P296, P305 |
| `invoice.correction_type` | P301 |
| `invoice.has_buyer_agreement` | P301 |
| `invoice.issue_date_resolved` | P305 |
| `invoice.event_date` | P306 |
| `invoice.is_adjusting_event` | P306 |
| `invoice.is_personal_expense` | P274 |
| `invoice.is_documented_uncollectible` | P270 |
| `invoice.months_since_issue` | P277 |
| `invoice.is_vat_deducted` | P277 |
| `invoice.vat_taxable` | P278 |
| `invoice.months_since_acquisition` | P281 |
| `invoice.is_excise_good` | P284 |
| `invoice.years_since_last_award` | P285 |
| `invoice.amount_daily` | P287 |
| `invoice.accounting_event` | P289-P290 |
| `invoice.vehicle_weight_kg` | P256 |
| `invoice.is_cabotage` | P257 |
| `invoice.activity_location` | P264 |
| `vendor.has_residence_certificate` | P243 |
| `vendor.has_transport_license` | P256 |
| `vendor.is_b2b_buyer` | P262 |
| `vendor.is_b2c` | P258 |
| `vendor.annual_transaction_value` | P302 |
| `vendor.whitelist_status` | P308 |
| `vendor.aml_risk_assessment_done` | P310 |
| `company.uses_simplified_advances` | P236 |
| `company.chooses_quarterly_advances` | P237 |
| `company.status` | P245 |
| `company.total_assets_eur` | P248 |
| `company.net_revenue_eur` | P248 |
| `company.is_accounting_month_closed` | P247 |
| `company.audit_required` | P249 |
| `company.legal_form` | P252-P253 |
| `company.net_profit_generated` | P253 |
| `company.has_ure_concession` | P254 |
| `company.energy_source` | P255 |
| `company.cabotage_operations_7days` | P257 |
| `company.uses_full_accounting` | P260 |
| `company.owns_guard_dog` | P265 |
| `company.is_dog_registered_in_municipality` | P265 |
| `company.is_mandatory_membership` | P271 |
| `company.vat_pre_pro_rata_applicable` | P276 |
| `company.vat_pre_pro_rata_percent` | P276 |
| `company.tax_group` | P281 |
| `company.has_fx_permit` | P282 |
| `company.uses_ifrs` | P288 |
| `company.is_vat_eu_registered` | P296 |
| `company.tax_return_filed` | P297-P298 |
| `company.has_related_party_transactions` | P303 |
| `company.is_aml_obligated_institution` | P310 |
| `company.jpk_correction_summon_active` | P309 |
| `company.balance_sheet_date` | P306 |
| `company.is_fs_approved` | P306 |
| `company.under_tax_audit` | P299 |
| `tax_type` | P240-P241, P297-P298, P303 |
| `document.type` | P250-P251, P299 |
| `document.filing_date_mm_dd` | P297 |
| `document.months_since_fye` | P298 |
| `document.tax_status` | P300 |
| `document.days_since_declaration` | P300 |
| `document.zaw_nr_filed` | P308 |
| `document.zaw_nr_days_since_transfer` | P308 |
| `document.days_since_summon` | P309 |
| `system.ksef_status` | P259 |
| `system.target` | P307 |
| `system.auth_token_exists` | P307 |
| `system.qualified_signature_exists` | P307 |
| `request.type` | P260 |

---

## 6. Odniesienia

- **Master Plan:** `Plan OPA/00_PLAN_STRUKTURA.md`
- **Thresholds Catalog:** `Plan OPA/02_THRESHOLDS_CATALOG.md`
- **Detailed Rules:** `Plan OPA/03_RULES_DETAILED.md`
- **Enterprise Expansion:** `Plan OPA/11_ENTERPRISE_FINAL_EXPANSION.md`
- **Specialized Rules:** `Plan OPA/14_SPECIALIZED_TAX_RULES.md`
- **Final Frontier:** `Plan OPA/16_FINAL_FRONTIER_RULES.md`
- **OPA API Reference:** `Plan OPA/18_OPA_API_REFERENCE.md`
- **Deployment Guide:** `Plan OPA/19_DEPLOYMENT_GUIDE.md`
