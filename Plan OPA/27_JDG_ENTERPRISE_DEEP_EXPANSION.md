# 🏗️ NexusAI JDG — Głęboka Ekspansja ENTERPRISE v4.0

> **Status:** Deep Enterprise Expansion v4.0 — 30 nowych obszarów reguł  
> **Data:** 2026-07-09  
> **Autor:** Zespół NexusAI  
> **Plik:** `Plan OPA/27_JDG_ENTERPRISE_DEEP_EXPANSION.md`  
> **Dokumenty bazowe:**  
> — `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` — plan bazowy (~145 reguł)  
> — `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` — pierwsza rozbudowa (~69 reguł)  
> — `Plan OPA/24_JDG_COMPLETE_INDEX.md` — indeks (~214 reguł)  
> — `Plan OPA/25_JDG_DEEP_LEGAL_AUDIT.md` — audyt prawny (46 luk)  
> — `Plan OPA/26_JDG_COMPREHENSIVE_EXPANSION.md` — kompleksowa rozbudowa (58 reguł, ~272 total)  
> — `Plan OPA/DocsJDG` — źródła prawne JDG  

**Nowe reguły:** 30 obszarów × średnio 1-3 reguły = ~55 reguł  
**Nowe pakiety:** 6  
**Cel:** Osiągnięcie PUŁAPU ENTERPRISE — pokrycie JDG jako płatnika, eksportera cyfrowego, uczestnika rynku globalnego, z wymiarem czasowym i audytowym.

---

## 0. Executive Summary — Dlaczego Ten Dokument

Dokumenty 22-26 pokrywają JDG jako **podatnika** (~272 reguły). ENTERPRISE wymaga pokrycia JDG również jako:

1. **Płatnika** (WHT, PIT-4R, PIT-8AR, składki za pracowników/zleceniobiorców)
2. **Eksportera cyfrowego** (OSS, WSTO, usługi cyfrowe do UE)
3. **Uczestnika rynku globalnego** (transfer pricing, PE, certyfikaty rezydencji)
4. **Podmiotu w czasie** (Time-Travel OPA, RMK, zmiany prawa)
5. **Podmiotu audytowanego** (KSeF UPO, ścieżka audytu, BDO, KOBiZE)

---

## 0.1 Aktualizacja Drzewa Pakietów — Finalna Architektura ENTERPRISE

```
policies/jdg/
├── main_jdg.rego                              # [UPDATE] Wszystkie nowe importy
│
├── risk.rego                                  # P0-P9
├── routing.rego                               # P10-P19
│
├── compliance/
│   ├── whitelist.rego                         # P20-P22 [ROZBUDOWA: +P22_b ZAW-NR]
│   ├── mpp.rego                               # P25
│   └── cash_limit.rego                        # P35-P36
│
├── crossborder.rego                           # P40-P49, P190-P191
│
├── vat/
│   ├── substantive.rego                       # P50-P65
│   ├── gtu.rego                               # P65-P69
│   ├── exemptions.rego                        # P55-P63
│   ├── tax_point.rego                         # P230-P235
│   ├── deduction.rego                         # P185-P189, P39, P183-P184, P192
│   ├── declarations.rego                      # P232-P234
│   ├── oss.rego                               # P66-P69 ★ NOWY PLIK ★
│   ├── margin_tourism.rego                    # P64 ★ NOWY PLIK ★
│   └── farmer_rr.rego                         # P62_b ★ NOWY PLIK ★
│
├── pit/
│   ├── form_scale.rego                        
│   ├── form_linear.rego                       
│   ├── form_lump_sum.rego                     
│   ├── form_tax_card.rego                     
│   ├── tax_form_change.rego                   
│   ├── advances.rego                          
│   ├── annual_returns.rego                    
│   ├── kup.rego                               # [ROZBUDOWA: +P571, P573, P575-P577]
│   │   ├── insurance_kup.rego                 # P575 ★ NOWY PLIK ★
│   │   └── bad_debt_pit.rego                  # P576 ★ NOWY PLIK ★
│   ├── exemptions.rego                        
│   └── payer_obligations.rego                 # P590-P599 ★ NOWY PLIK ★
│
├── wht/                                       # ★ NOWY PAKIET ★
│   └── main.rego                              # P100-P109
│
├── international/                             # ★ NOWY PAKIET ★
│   ├── permanent_establishment.rego           # P110-P113
│   └── transfer_pricing.rego                  # P114-P117
│
├── employer/                                  # ★ NOWY PAKIET ★
│   ├── payroll.rego                           # P1200-P1209
│   ├── civil_contracts.rego                   # P1210-P1219
│   └── copyright_kup.rego                     # P1220-P1223
│
├── environmental/                             # ★ NOWY PAKIET ★
│   ├── bdo.rego                               # P1400-P1403
│   └── kobize.rego                            # P1405-P1407
│
├── restructuring/                             # ★ NOWY PAKIET ★
│   └── conversion.rego                        # P1500-P1505
│
├── temporal/                                  # ★ NOWY PAKIET ★
│   ├── rmk.rego                               # P1600-P1604
│   └── time_travel.rego                       # P1610-P1612
│
├── allowances/
├── zus/
├── accounting/
├── business/
├── corrections/
├── statute_liability/
├── representation/
├── local_taxes/
├── ksef/
├── jpk/
├── retention.rego
└── fallback.rego
```

---

## 0.2 Nowe Pola `input` — ENTERPRISE Deep Expansion

| Sekcja | Nowe pole | Typ | Używane przez |
|--------|----------|-----|---------------|
| `jdg_entrepreneur` | `has_employees` | `boolean` | P1200-P1209 |
| `jdg_entrepreneur` | `is_wht_payer` | `boolean` | P100-P109 |
| `jdg_entrepreneur` | `uses_memorial_accounting` | `boolean` | P1600-P1604 |
| `jdg_entrepreneur` | `has_permanent_establishment_risk` | `boolean` | P110-P113 |
| `jdg_entrepreneur` | `bdo_number` | `string` | P1400-P1403 |
| `jdg_entrepreneur` | `kobize_required` | `boolean` | P1405-P1407 |
| `jdg_entrepreneur` | `is_registered_oss` | `boolean` | P66-P69 |
| `jdg_entrepreneur` | `has_psI_decision` | `boolean` | P1500-P1505 |
| `invoice` | `is_foreign_service` | `boolean` | P100-P109 |
| `invoice` | `service_type` | `string` | P100-P109, P1210 |
| `invoice` | `payment_currency` | `string` | P870 |
| `invoice` | `rmk_period_months` | `number` | P1600-P1604 |
| `invoice` | `rmk_start_date` | `string` | P1600-P1604 |
| `invoice` | `car_value_insurance_base` | `number` | P575 |
| `invoice` | `copyright_transfer_percent` | `number` | P1220-P1223 |
| `invoice` | `is_b2c_eu_sale` | `boolean` | P66-P69 |
| `invoice` | `consumer_country` | `string` | P66-P69 |
| `vendor` | `is_related_party_tp` | `boolean` | P114-P117 |
| `vendor` | `country_of_residence` | `string` | P100-P109 |
| `vendor` | `has_tax_residence_certificate` | `boolean` | P100-P109 |
| `vendor` | `tax_certificate_valid_until` | `string` | P100-P109 |
| `document` | `ksef_upo_received` | `boolean` | P1610-P1612 |
| `document` | `ksef_upo_timestamp` | `string` | P1610-P1612 |
| `document` | `evaluation_date` | `string` | P1610-P1612 |
| `thresholds.jdg` | (rozszerzone — patrz sekcja 0.3) | | |

---

## 0.3 Nowe Parametry w `thresholds.jdg.*` ENTERPRISE

| Klucz | Wartość | Opis | Podstawa prawna |
|-------|---------|------|-----------------|
| `rates.wht_standard` | `"0.20"` | WHT stawka podstawowa | Art. 21 ust. 1 PIT |
| `rates.wht_reduced` | `"0.10"` | WHT stawka obniżona (dyrektywa) | Art. 21 ust. 1 PIT |
| `rates.oss_vat_rates` | `{}` | VAT OSS wg kraju UE | Art. 130a-130d VAT |
| `limits.wst_union_threshold_eur` | `10000` | Próg WSTO dla sprzedaży B2C UE | Art. 131a VAT |
| `limits.tp_documentation_threshold` | `2000000` | Próg dokumentacji TP dla JDG | Art. 23zf PIT |
| `limits.tp_related_party_threshold` | `500000` | Próg transakcji z podmiotem powiązanym | Art. 23zf PIT |
| `limits.zaw_nr_deadline_days` | `7` | Termin zawiadomienia ZAW-NR | Art. 117ba OP |
| `limits.small_contract_lump_sum_limit` | `200` | Limit umowy zryczałtowanej 12% | Art. 30 ust. 1 pkt 5a PIT |
| `limits.payroll_advance_deadline_day` | `20` | Termin wpłaty zaliczki PIT-4R | Art. 38 PIT |
| `limits.rmk_default_months` | `12` | Domyślny okres RMK | Art. 39 UoR (analogicznie) |
| `limits.ksef_upo_validation_hours` | `24` | Max godz. na otrzymanie UPO KSeF | Art. 106na VAT |
| `rates.car_insurance_oc_kup_percent` | `100` | % KUP dla OC samochodowego | Interpretacja MF |
| `rates.car_insurance_ac_kup_proportion` | `"proportional"` | AC proporcjonalnie do 150k | Art. 23 ust. 1 pkt 47 PIT |
| `rates.copyright_transfer_kup_50` | `50` | 50% KUP dla praw autorskich | Art. 22 ust. 9 PIT |
| `bounds.pe_risk_months_threshold` | `6` | Miesiące pobytu za granicą (ryzyko PE) | Art. 5 Umowy Modelowej OECD |

---

# CZĘŚĆ I: WITHHOLDING TAX (WHT) — NOWY PAKIET `jdg.wht` (P100-P109)

> **Stan przed:** CAŁKOWICIE pominięty. JDG kupujące SaaS, licencje, oprogramowanie z zagranicy podlega obowiązkom WHT.  
> **Po rozbudowie:** NOWY PAKIET z 5 regułami — kompletna obsługa podatku u źródła.

---

## P100: `wht_obligation_detection`

- **Cel biznesowy:** Wykrycie obowiązku poboru podatku u źródła gdy JDG kupuje usługi niematerialne od podmiotu zagranicznego (SaaS, licencje, doradztwo, oprogramowanie, tantiemy).
- **Przesłanki:** 
  - `input.invoice.direction == "PURCHASE"`
  - `input.invoice.is_foreign_service == true` (usługa od podmiotu zagranicznego)
  - `input.vendor.country_of_residence != "PL"`
  - `input.invoice.service_type in ["SOFTWARE_LICENSE", "SAAS", "CONSULTING_CROSSBORDER", "ROYALTIES", "ADVERTISING_ONLINE", "CLOUD_SERVICES"]`
  - `input.invoice.amount_gross > 0`
- **Rezultat:** 
  - `wht_obligation_detected: true`
  - `wht_base_rate: "0.20"` (20% — stawka podstawowa dla usług niematerialnych)
  - `wht_amount: amount_gross * 0.20`
  - `wht_form: "WHT-26"` (deklaracja o pobranym podatku u źródła)
  - `_warning: "Zakup usługi niematerialnej z zagranicy — obowiązek poboru 20% WHT. Sprawdź czy masz certyfikat rezydencji dla obniżonej stawki."`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 1-4 PIT, Art. 26 ust. 1 PIT
- **Priorytet:** 100

---

## P102: `wht_certificate_of_residence`

- **Cel biznesowy:** Weryfikacja posiadania certyfikatu rezydencji kontrahenta zagranicznego — kluczowe dla zastosowania stawki obniżonej lub zwolnienia z WHT (zgodnie z UPO).
- **Przesłanki:** 
  - `wht_obligation_detected == true` (z P100)
  - `input.vendor.has_tax_residence_certificate == true`
  - `input.vendor.tax_certificate_valid_until >= input.invoice.transaction_date`
  - Certyfikat obejmuje rok podatkowy transakcji
- **Rezultat:** 
  - `wht_certificate_valid: true` → możliwość zastosowania stawki z UPO (np. 5%, 10% lub 0%)
  - `wht_certificate_invalid: true` → `_routing: "BLOCK_AND_ALERT"`, stawka karna 20%
  - `wht_rate_after_treaty: <stawka z UPO>` lub `"0.20"` (gdy brak certyfikatu)
  - `_warning: "Brak ważnego certyfikatu rezydencji — zastosowano stawkę WHT 20%. Uzyskaj certyfikat dla stawki obniżonej."`
- **Podstawa prawna:** Art. 26 ust. 1 PIT, Art. 21 ust. 1 PIT, Umowy o unikaniu podwójnego opodatkowania (UPO)
- **Priorytet:** 102
- **Zależności:** Sprawdzana PO P100
- **`[TODO: potrzebne źródło]`** — baza stawek WHT dla poszczególnych krajów z UPO

---

## P104: `wht_payment_deadline`

- **Cel biznesowy:** Termin wpłaty pobranego WHT do US — do 20. dnia miesiąca następującego po miesiącu pobrania podatku.
- **Przesłanki:** 
  - `wht_amount > 0` (pobrano WHT)
  - `current_date > 20th_day_of_next_month` (po terminie)
- **Rezultat:** 
  - `wht_payment_deadline: "20th_day_of_next_month"`
  - `wht_payment_overdue: true` (po terminie)
  - `wht_late_interest: wht_amount * tax_interest_rate * days_overdue / 365`
  - `_routing: "TRIAGE_QUEUE"`
- **Podstawa prawna:** Art. 26 ust. 3 PIT, Art. 42 PIT
- **Priorytet:** 104

---

## P106: `wht_annual_declaration`

- **Cel biznesowy:** Obowiązek złożenia rocznej deklaracji WHT-26 (do końca stycznia następnego roku) — podsumowanie wszystkich pobranych WHT.
- **Przesłanki:** 
  - W roku podatkowym pobrano jakikolwiek WHT
  - `current_date > "01-31"` AND deklaracja WHT-26 nie złożona
- **Rezultat:** 
  - `wht_26_required: true`
  - `wht_26_deadline: "01-31"`
  - `wht_26_overdue: true` (po terminie)
- **Priorytet:** 106

---

## P108: `wht_double_taxation_avoidance`

- **Cel biznesowy:** Informacja dla JDG o możliwości odliczenia zagranicznego WHT od polskiego PIT (metoda proporcjonalnego odliczenia) lub wyłączenia z progresją.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_treaty_method == "proportional_deduction"` (metoda odliczenia)
  - JDG posiada dochody zagraniczne opodatkowane za granicą
- **Rezultat:** 
  - `foreign_tax_credit_available: true`
  - `max_credit: min(foreign_tax_paid, polish_tax_on_foreign_income)`
  - Dla metody wyłączenia: `foreign_income_exempt: true`, ale wpływa na progresję dla skali
- **Priorytet:** 108

---

# CZĘŚĆ II: OSS / WSTO / E-COMMERCE — NOWY PLIK `jdg.vat.oss` (P66-P69)

> **Stan przed:** CAŁKOWICIE pominięty. JDG sprzedające przez internet do konsumentów UE podlega procedurom OSS/WSTO.  
> **Po rozbudowie:** NOWY PLIK z 4 regułami — kompletna obsługa e-commerce VAT.

---

## P66: `wsto_threshold_monitor`

- **Cel biznesowy:** Monitorowanie progu 10 000 EUR dla WSTO (Wewnątrzwspólnotowa Sprzedaż Towarów na Odległość). Poniżej progu — VAT wg stawki PL. Powyżej — VAT wg stawki kraju konsumenta + rejestracja OSS.
- **Przesłanki:** 
  - `input.invoice.direction == "SALE"`
  - `input.invoice.is_b2c_eu_sale == true` (sprzedaż B2C do UE)
  - `input.invoice.consumer_country in eu_countries` AND `consumer_country != "PL"`
  - Roczna suma sprzedaży B2C do UE (narastająco)
- **Rezultat:** 
  - `wsto_applicable: true` (próg przekroczony → VAT kraju konsumenta)
  - `wsto_not_applicable: true` (poniżej progu → VAT PL)
  - `oss_registration_required: true` (przy przekroczeniu progu)
  - `_warning: "Sprzedaż B2C do UE — monitoruj próg 10 000 EUR dla WSTO."`
- **Podstawa prawna:** Art. 131a-131d VAT, Art. 130a-130d VAT
- **Priorytet:** 66
- **Zależności:** Sprawdzana PRZED regułami stawek VAT (P50-P64)

---

## P67: `oss_vat_rate_assignment`

- **Cel biznesowy:** Dynamiczne przypisanie stawki VAT kraju konsumenta dla sprzedaży OSS — każdy kraj UE ma własne stawki.
- **Przesłanki:** 
  - `wsto_applicable == true` (próg WSTO przekroczony)
  - JDG zarejestrowane w OSS (`is_registered_oss == true`)
- **Rezultat:** 
  - `vat_rate: oss_rate_for_country(consumer_country, category_code)` 
  - Wyciągane z `input.thresholds.jdg.rates.oss_vat_rates` — mapa kraj→stawka
  - `vat_procedure: "OSS"`
  - `oss_country: consumer_country`
- **Podstawa prawna:** Art. 130a-130d VAT
- **Priorytet:** 67
- **`[TODO: potrzebne źródło]`** — pełna tabela stawek VAT dla wszystkich krajów UE (oss_vat_rates)

---

## P68: `oss_quarterly_declaration`

- **Cel biznesowy:** Obowiązek składania kwartalnej deklaracji OSS przez portal e-Urząd Skarbowy — termin do końca miesiąca następującego po kwartale.
- **Przesłanki:** 
  - `is_registered_oss == true`
  - Koniec kwartału: 31.03, 30.06, 30.09, 31.12
  - Deklaracja OSS nie złożona
- **Rezultat:** 
  - `oss_declaration_deadline: "end_of_month_after_quarter"`
  - `oss_declaration_overdue: true` (po terminie)
  - `_warning: "OSS — złóż deklarację kwartalną przez e-US"`
- **Prioryтет:** 68

---

## P69: `ioss_import_detection`

- **Cel biznesowy:** Wykrycie importu towarów spoza UE o wartości ≤150 EUR — możliwość rozliczenia przez IOSS (Import One Stop Shop) zamiast standardowej procedury celnej.
- **Przesłanki:** 
  - `input.invoice.direction == "PURCHASE"`
  - `input.vendor.country == "NON_EU"`
  - `input.invoice.type == "GOODS"`
  - `input.invoice.amount_gross <= 150_EUR`
- **Rezultat:** 
  - `ioss_applicable: true`
  - `ioss_vat_collected_at_checkout: true` (VAT pobrany przy sprzedaży)
  - `_info: "Import ≤150 EUR — możliwość rozliczenia przez IOSS"`
- **Priorytet:** 69

---

# CZĘŚĆ III: JDG JAKO PRACODAWCA — NOWY PAKIET `jdg.employer` (P1200-P1223)

> **Stan przed:** CAŁKOWICIE pominięty. JDG zatrudniające pracowników/zleceniobiorców ma rozbudowane obowiązki płatnika.  
> **Po rozbudowie:** NOWY PAKIET z 12 regułami — payroll, zlecenia, prawa autorskie.

---

## P1200: `employer_obligation_detection`

- **Cel biznesowy:** Aktywacja reguł pracodawcy gdy JDG zatrudnia pracowników lub zleceniobiorców.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.has_employees == true`
  - `input.jdg_entrepreneur.employees_count > 0`
- **Rezultat:** 
  - `employer_mode_active: true`
  - `employer_obligations: ["PIT-4R", "PIT-11", "ZUS_RCA", "ZUS_RSA", "PPK"]`
  - Aktywuje reguły P1200-P1223
- **Priorytet:** 1200
- **Zależności:** Musi być sprawdzana jako pierwsza w pakiecie employer

---

## P1202: `payroll_tax_advance_obligation`

- **Cel biznesowy:** Obowiązek obliczenia, pobrania i wpłaty zaliczki na PIT od wynagrodzeń pracowników (PIT-4R) do 20. dnia następnego miesiąca.
- **Przesłanki:** 
  - `employer_mode_active == true` (z P1200)
  - Wynagrodzenie wypłacone w danym miesiącu
  - `current_date > 20th_day_of_next_month` AND zaliczka nie wpłacona
- **Rezultat:** 
  - `pit_4r_advance_due: true`
  - `pit_4r_amount: (salary - zus_social_employee - kup_employee) * pit_rate - health_deduction`
  - `pit_4r_deadline: "20th_day_of_next_month"`
  - `pit_4r_overdue: true` (po terminie)
  - `_warning: "Zaliczka PIT-4R niezapłacona — termin do 20. dnia miesiąca"`
- **Podstawa prawna:** Art. 31-32 PIT, Art. 38 PIT
- **Priorytet:** 1202

---

## P1204: `payroll_zus_contributions_employer`

- **Cel biznesowy:** Obliczenie i weryfikacja składek ZUS od wynagrodzeń pracowników (ZUS RCA — część pracodawcy i pracownika).
- **Przesłanki:** 
  - `employer_mode_active == true`
  - Wynagrodzenie wypłacone
- **Rezultat:** 
  - `zus_rca_total: employee_part + employer_part`
  - `zus_deadline: 20th_day` (JDG bez pracowników → 15th z pracownikami! ★)
  - **UWAGA:** Termin zmienia się z 20. na 15. dzień gdy JDG zatrudnia choćby 1 pracownika!
  - `zus_rca_overdue: true` (po terminie)
- **Podstawa prawna:** Art. 47 ust. 1a SUS
- **Priorytet:** 1204

---

## P1206: `annual_pit11_filing`

- **Cel biznesowy:** Obowiązek wystawienia PIT-11 dla pracowników do końca lutego następnego roku.
- **Przesłanki:** 
  - `employer_mode_active == true`
  - Zatrudnienie w poprzednim roku podatkowym
  - `current_date > "02-28"` AND PIT-11 nie wystawiony
- **Rezultat:** 
  - `pit11_deadline: "02-28"`
  - `pit11_overdue: true` (po terminie)
  - `_warning: "PIT-11 nie wystawiony w terminie — obowiązek do końca lutego"`
- **Podstawa prawna:** Art. 39 ust. 1 PIT
- **Priorytet:** 1206

---

## P1208: `ppk_obligation_check`

- **Cel biznesowy:** JDG zatrudniające ≥1 pracownika przez ≥3 miesiące ma obowiązek wdrożenia PPK (wpłaty 1,5% pracownika + 1,5% pracodawcy).
- **Przesłanki:** 
  - `employer_mode_active == true`
  - `employees_count >= 1`
  - Zatrudnienie trwa ≥ 3 miesiące
  - PPK nie wdrożone
- **Rezultat:** 
  - `ppk_required: true`
  - `ppk_contribution: "1.5%_employee + 1.5%_employer"`
  - `_warning: "Obowiązek wdrożenia PPK — Twoja firma podlega pod PPK"`
- **Podstawa prawna:** Ustawa o PPK, Art. 15-17
- **Priorytet:** 1208

---

## P1210: `small_mandate_flat_tax`

- **Cel biznesowy:** Umowy zlecenia/dzieło ≤200 PLN — zryczałtowany PIT 12%, bez KUP wykonawcy. JDG jako płatnik pobiera i odprowadza podatek.
- **Przesłanki:** 
  - `input.invoice.expense_type in ["MANDATE_CONTRACT", "SPECIFIC_TASK_CONTRACT"]`
  - `input.invoice.amount_gross <= input.thresholds.jdg.limits.small_contract_lump_sum_limit` (200 PLN)
  - `input.vendor.is_employee == false`
  - Umowa nie dotyczy własnego pracownika
- **Rezultat:** 
  - `pit_rate: "0.12"` (zryczałtowany)
  - `pit_withholding_type: "LUMP_SUM"`
  - `apply_contractor_kup: false` (brak KUP dla wykonawcy)
  - `pit_8ar_filing_required: true` (roczna deklaracja PIT-8AR)
  - `_warning: "Mała umowa ≤200 PLN — ryczałt 12%, pobierz podatek jako płatnik"`
- **Podstawa prawna:** Art. 30 ust. 1 pkt 5a PIT
- **Priorytet:** 1210

---

## P1212: `civil_contract_zus_classification`

- **Cel biznesowy:** Klasyfikacja obowiązków ZUS dla umów cywilnoprawnych — umowa zlecenie = obowiązkowe składki (z pewnymi wyjątkami), umowa o dzieło = brak składek.
- **Przesłanki:** 
  - `input.invoice.expense_type == "MANDATE_CONTRACT"` → obowiązkowe ZUS (emerytalne, rentowe, zdrowotne), chorobowe dobrowolne
  - `input.invoice.expense_type == "SPECIFIC_TASK_CONTRACT"` → BRAK składek ZUS
  - WYJĄTEK: zleceniobiorca zatrudniony na etacie z pensją ≥ minimalnej → z umowy zlecenia NIE ma składek
- **Rezultat:** 
  - `zus_social_required: true` (dla zlecenia) / `false` (dla dzieła)
  - `zus_sickness_voluntary: true` (dla zlecenia)
  - `_warning: "Umowa zlecenia — obowiązkowe składki ZUS społeczne i zdrowotne"`
- **Podstawa prawna:** Art. 6, Art. 9 SUS
- **Priorytet:** 1212

---

## P1220: `copyright_transfer_50_kup`

- **Cel biznesowy:** Gdy JDG (np. IT studio, agencja kreatywna) zatrudnia twórców na umowach z przeniesieniem praw autorskich — zastosowanie 50% KUP od przychodu z praw autorskich.
- **Przesłanki:** 
  - `input.invoice.expense_type in ["COPYRIGHT_CONTRACT", "MANDATE_CONTRACT_WITH_IP"]`
  - `input.invoice.copyright_transfer_percent > 0` (procent honorarium za przeniesienie praw)
  - Umowa wyraźnie rozdziela honorarium autorskie od wynagrodzenia za inne czynności
- **Rezultat:** 
  - `kup_50_percent_applied: true`
  - `kup_amount: min(copyright_honorarium * 0.50, annual_limit_50_kup)`
  - **Limit roczny 50% KUP:** 50% × pierwszy próg podatkowy (120 000 PLN) = max 60 000 PLN KUP rocznie ★
  - `copyright_honorarium_annual_cumulative` — śledzone narastająco
  - `_warning: "50% KUP od praw autorskich — limit roczny: 50% × 120 000 PLN"`
- **Podstawa prawna:** Art. 22 ust. 9 pkt 1-3 PIT
- **Priorytet:** 1220

---

## P1222: `copyright_kup_annual_limit`

- **Cel biznesowy:** Monitorowanie rocznego limitu 50% KUP od praw autorskich — po przekroczeniu limitu, nadwyżka nie korzysta z 50% KUP.
- **Przesłanki:** 
  - `copyright_transfer_50_kup == true` (z P1220)
  - `annual_copyright_kup_used >= 60000` (50% × 120 000 PLN)
- **Rezultat:** 
  - `copyright_kup_exceeded: true`
  - `_warning: "Przekroczono roczny limit 50% KUP od praw autorskich — nadwyżka bez 50% KUP"`
- **Priorytet:** 1222

---

# CZĘŚĆ IV: KUP SZCZEGÓŁOWE — NOWE PLIKI `jdg.pit.kup.insurance_kup` i `jdg.pit.kup.bad_debt_pit` (P571, P573, P575-P577)

---

## P571: `kup_bad_debt_pit_debtor` 🔴 KRYTYCZNA

- **Cel biznesowy:** ANALOGICZNIE do VAT (P184): obowiązek dłużnika JDG do wyłączenia z KUP niezapłaconej faktury po 90 dniach od terminu płatności. Dotyczy PIT, nie VAT!
- **Przesłanki:** 
  - `input.invoice.direction == "PURCHASE"`
  - `input.invoice.is_paid == false`
  - `input.invoice.days_overdue >= 90` (90 dni od terminu płatności)
  - Wydatek był wcześniej zaliczony do KUP
- **Rezultat:** 
  - `kup_reversal_required: true`
  - `kup_to_reverse: <kwota netto>`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "OBOWIĄZKOWE wyłączenie z KUP! Nie zapłaciłeś faktury >90 dni od terminu. Wyłącz kwotę X z KUP."`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 18a PIT (dla skali/liniowego), Art. 11 ustawy o ryczałcie (dla ryczałtowców — obowiązek pomniejszenia przychodu)
- **Priorytet:** 571

---

## P573: `kup_bad_debt_pit_creditor`

- **Cel biznesowy:** Ulga na złe długi w PIT dla wierzyciela — możliwość wyłączenia z przychodów niezapłaconej należności po 90 dniach i spełnieniu warunków.
- **Przesłanki:** 
  - `input.invoice.direction == "SALE"`
  - `input.invoice.is_paid == false`
  - `input.invoice.days_overdue >= 90`
  - Należność była uprzednio zarachowana jako przychód
  - Dłużnik nie jest w trakcie postępowania restrukturyzacyjnego/upadłościowego
- **Rezultat:** 
  - `bad_debt_revenue_reduction_allowed: true`
  - `reduction_amount: <kwota netto>`
  - `_warning: "Ulga na złe długi PIT — możesz pomniejszyć przychód o niezapłaconą należność po 90 dniach"`
- **Podstawa prawna:** Art. 14 ust. 1e PIT (dla skali/liniowego)
- **Priorytet:** 573

---

## P575: `kup_vehicle_insurance` — NOWY PLIK `jdg.pit.kup.insurance_kup`

- **Cel biznesowy:** Rozróżnienie KUP dla różnych typów ubezpieczeń komunikacyjnych pojazdu firmowego JDG:
  - **OC** — 100% KUP (obowiązkowe)
  - **AC** — proporcjonalnie do limitu 150 000 PLN wartości samochodu
  - **GAP** — 100% KUP (związane z finansowaniem zakupu)
  - **NNW** — 100% KUP (jeśli dotyczy działalności)
- **Przesłanki:** 
  - `input.invoice.expense_type in ["CAR_INSURANCE_OC", "CAR_INSURANCE_AC", "CAR_INSURANCE_GAP", "CAR_INSURANCE_NNW"]`
  - `input.invoice.car_value_insurance_base` (wartość samochodu przyjęta do ubezpieczenia AC)
- **Rezultat:** 
  
  | Typ ubezpieczenia | % KUP | Warunek |
  |-------------------|:-----:|---------|
  | OC | 100% | Zawsze — obowiązkowe |
  | AC | proporcjonalny: min(100%, 150000/car_value) | Gdy car_value > 150k |
  | GAP | 100% | Związane z finansowaniem |
  | NNW | 100% | Jeśli związane z działalnością |

- **Podstawa prawna:** Art. 23 ust. 1 pkt 47 PIT (limit 150k dla AC)
- **Priorytet:** 575

---

## P577: `kup_zaw_nr_whitelist_procedure`

- **Cel biznesowy:** Procedura ZAW-NR: zapłata >15 000 PLN na konto spoza Białej Listy → brak KUP. ALE: złożenie ZAW-NR w ciągu 7 dni od przelewu ZWALNIA z odpowiedzialności solidarnej i PRZYWRACA KUP.
- **Przesłanki:** 
  - `input.invoice.amount_gross >= input.thresholds.jdg.limits.mpp_limit` (15 000 PLN)
  - `input.vendor.account_on_whitelist == false` (rachunek spoza WL)
  - Przelew wykonany
  - `input.document.zaw_nr_filed == true` AND `input.document.zaw_nr_days_since_transfer <= 7`
- **Rezultat:** 
  - `kup_restored_by_zaw_nr: true` (KUP przywrócone po złożeniu ZAW-NR)
  - `kup_blocked_no_zaw_nr: true` (gdy ZAW-NR nie złożony w terminie 7 dni → KUT = 0)
  - `_warning: "Zapłata na konto spoza Białej Listy — złóż ZAW-NR w ciągu 7 dni, aby zachować KUP"`
- **Podstawa prawna:** Art. 22p PIT, Art. 117ba OP
- **Priorytet:** 577

---

# CZĘŚĆ V: TIME-TRAVEL I RMK — NOWY PAKIET `jdg.temporal` (P1600-P1612)

> **Stan przed:** CAŁKOWICIE pominięty. System ENTERPRISE musi obsługiwać korekty wsteczne i rozliczenia międzyokresowe.  
> **Po rozbudowie:** NOWY PAKIET z 7 regułami — RMK, Time-Travel OPA.

---

## P1600: `rmk_detection` — NOWY PLIK `jdg.temporal.rmk`

- **Cel biznesowy:** Wykrycie wydatków wymagających rozliczenia międzyokresowego (RMK) — faktura za usługę/polisę/licencję obejmującą wiele miesięcy, gdzie JDG prowadzi księgowość memoriałową.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.uses_memorial_accounting == true` (PKPiR metodą memoriałową)
  - `input.invoice.rmk_period_months > 1` (okres > 1 miesiąc)
  - `input.invoice.rmk_start_date` określona
  - `input.invoice.expense_type in ["INSURANCE", "SOFTWARE_LICENSE_ANNUAL", "RENT_PREPAID", "SUBSCRIPTION_ANNUAL", "SERVICE_CONTRACT_MULTI_MONTH"]`
- **Rezultat:** 
  - `rmk_required: true`
  - `rmk_monthly_amount: amount_net / rmk_period_months`
  - `rmk_periods: <lista miesięcy>`
  - `kup_current_month: rmk_monthly_amount` (tylko bieżący miesiąc)
  - `kup_deferred: amount_net - rmk_monthly_amount` (pozostałe miesiące)
  - `_warning: "RMK — wydatek rozliczany proporcjonalnie przez X miesięcy"`
- **Podstawa prawna:** Art. 39 UoR (rozliczenia międzyokresowe kosztów — stosowane odpowiednio w PKPiR memoriałowej)
- **Priorytet:** 1600

---

## P1602: `rmk_monthly_release`

- **Cel biznesowy:** Automatyczne uwalnianie RMK w kolejnych miesiącach — co miesiąc 1/N kosztu trafia do KUP.
- **Przesłanki:** 
  - `rmk_required == true` (z P1600)
  - `current_month >= rmk_allocated_month`
  - Poprzednie miesiące już rozliczone
- **Rezultat:** 
  - `rmk_release_current_month: rmk_monthly_amount`
  - `rmk_remaining: <pozostała kwota>`
  - `rmk_exhausted: true` (w ostatnim miesiącu)
- **Priorytet:** 1602

---

## P1604: `rmk_prepaid_rent_limit`

- **Cel biznesowy:** Limit RMK dla czynszu najmu — maksymalnie 12 miesięcy z góry może być rozliczane międzyokresowo.
- **Przesłanki:** 
  - `input.invoice.expense_type == "RENT_PREPAID"`
  - `input.invoice.rmk_period_months > 12`
- **Rezultat:** 
  - `rmk_max_period: 12` (nadwyżka ponad 12 miesięcy → NKUP lub kaucja)
  - `_warning: "Czynsz opłacony z góry za >12 miesięcy — nadwyżka nie może być RMK"`
- **Priorytet:** 1604

---

## P1610: `time_travel_evaluation_mode` — NOWY PLIK `jdg.temporal.time_travel`

- **Cel biznesowy:** Włączenie trybu Time-Travel — ewaluacja reguł wg stanu prawnego z daty historycznej (np. korekta deklaracji za 2023 rok oceniana wg przepisów z 2023, nie 2026).
- **Przesłanki:** 
  - `input.document.evaluation_date != input.invoice.transaction_date` (data ewaluacji ≠ data transakcji)
  - Tryb korekty wstecznej
- **Rezultat:** 
  - `time_travel_mode: true`
  - `applicable_thresholds: thresholds_as_of(evaluation_date)` (thresholdy z DuckDB dla daty historycznej)
  - `applicable_rules: rules_valid_at(evaluation_date)` (reguły obowiązujące w dacie historycznej)
  - `_warning: "Time-Travel mode — reguły z daty X, thresholdy z daty X"`
- **Zależności:** Wymaga, aby DuckDB przechowywał historyczne wersje thresholdów z `valid_from`/`valid_to`. Wymaga, aby `main_jdg.rego` uwzględniał `evaluation_date` przy wyborze reguł.
- **Priorytet:** 1610
- **`[TODO: potrzebne źródło]`** — mechanizm wersjonowania reguł Rego (OPA bundle versioning)

---

## P1612: `ksef_upo_timestamp_validation`

- **Cel biznesowy:** Walidacja czy faktura KSeF otrzymała UPO (Urzędowe Poświadczenie Odbioru) — od daty UPO zależy skuteczność prawna faktury i prawo do odliczenia VAT.
- **Przesłanki:** 
  - `input.invoice.direction == "PURCHASE"` (faktura zakupowa)
  - Faktura otrzymana przez KSeF
  - `input.document.ksef_upo_received == false` (brak UPO)
  - Czas od wysyłki > `input.thresholds.jdg.limits.ksef_upo_validation_hours` (24h)
- **Rezultat:** 
  - `ksef_upo_missing: true`
  - `vat_deduction_blocked_until_upo: true`
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Brak UPO dla faktury KSeF — VAT nie może być odliczony do czasu otrzymania UPO"`
  
  **Gdy UPO otrzymane:**
  - `vat_deduction_period: "MONTH_OF_UPO_RECEIPT"`
- **Podstawa prawna:** Art. 106na-106nq VAT
- **Priorytet:** 1612
# CZĘŚĆ VI: TRANSFER PRICING I PERMANENT ESTABLISHMENT — NOWY PAKIET `jdg.international` (P110-P117)

> **Stan przed:** CAŁKOWICIE pominięty. JDG dokonujące transakcji z podmiotami powiązanymi podlegają obowiązkom TP. JDG działające za granicą ryzykują powstanie zakładu (PE).  
> **Po rozbudowie:** NOWY PAKIET z 5 regułami — ceny transferowe i ryzyko PE.

---

## P110: `permanent_establishment_risk` — NOWY PLIK `jdg.international.permanent_establishment`

- **Cel biznesowy:** Wykrycie ryzyka powstania zagranicznego zakładu (PE) polskiego JDG — pobyt za granicą >6 miesięcy, serwerownia/magazyn za granicą, biuro coworkingowe.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.has_foreign_operations == true`
  - `input.jdg_entrepreneur.foreign_stay_months > input.thresholds.jdg.bounds.pe_risk_months_threshold` (6 miesięcy)
  - LUB: posiadanie stałego miejsca prowadzenia działalności za granicą (biuro, magazyn, serwer)
  - LUB: zależny agent za granicą regularnie zawierający umowy w imieniu JDG
- **Rezultat:** 
  - `pe_risk_level: "HIGH"` (powyżej 6 miesięcy + stałe miejsce)
  - `pe_risk_level: "MEDIUM"` (powyżej 6 miesięcy, brak stałego miejsca)
  - `pe_risk_level: "LOW"` (poniżej 6 miesięcy, brak stałego miejsca)
  - `_warning` (dla HIGH): "Ryzyko powstania zagranicznego zakładu! Dochody mogą podlegać opodatkowaniu za granicą. Skonsultuj się z doradcą podatkowym."
  - `_routing: "TRIAGE_QUEUE"` (dla HIGH)
- **Podstawa prawna:** Art. 5 Umowy Modelowej OECD, Art. 4a pkt 11 PIT
- **Priorytet:** 110

---

## P112: `pe_income_allocation`

- **Cel biznesowy:** Oszacowanie, jaka część dochodu JDG może być przypisana do zagranicznego zakładu (PE) — potrzeba wydzielenia księgowości dla PE.
- **Przesłanki:** 
  - `pe_risk_level in ["HIGH", "MEDIUM"]` (z P110)
  - JDG kontynuuje działalność mimo ryzyka PE
- **Rezultat:** 
  - `pe_income_separation_required: true`
  - `pe_income_allocation_method`: "ASSET_BASED" / "REVENUE_BASED" / "COST_PLUS"
  - `_warning: "Wydziel księgowość dla zagranicznego zakładu — oddzielne rozliczenie podatkowe za granicą"`
- **Priorytet:** 112

---

## P114: `transfer_pricing_documentation_threshold` — NOWY PLIK `jdg.international.transfer_pricing`

- **Cel biznesowy:** Wykrycie obowiązku sporządzenia dokumentacji cen transferowych (TP) dla JDG przy transakcjach z podmiotami powiązanymi >2 mln PLN rocznie.
- **Przesłanki:** 
  - `input.vendor.is_related_party_tp == true` (kontrahent powiązany — np. spółka żony, własna sp. z o.o.)
  - Roczna wartość transakcji z tym podmiotem > `input.thresholds.jdg.limits.tp_documentation_threshold` (2 mln PLN)
  - Transakcja jednorodna
- **Rezultat:** 
  - `tp_documentation_required: true`
  - `tp_form: "TPR-C"`
  - `tp_deadline: "end_of_9th_month_after_fye"` (koniec 9. miesiąca po zakończeniu roku podatkowego)
  - `_warning: "Transakcje z podmiotem powiązanym >2 mln PLN — obowiązek dokumentacji TP (TPR-C)"`
- **Podstawa prawna:** Art. 23zf PIT (dla JDG odpowiednik Art. 11a CIT)
- **Priorytet:** 114

---

## P116: `transfer_pricing_arm_length_test`

- **Cel biznesowy:** Test rynkowości ceny (arm's length) dla transakcji z podmiotami powiązanymi — cena musi odpowiadać warunkom rynkowym.
- **Przesłanki:** 
  - `tp_documentation_required == true` (z P114)
  - Cena transakcji odbiega od benchmarku rynkowego o >20%
- **Rezultat:** 
  - `arm_length_violation: true`
  - `price_adjustment_required: <różnica>`
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Cena transakcji z podmiotem powiązanym odbiega od rynkowej — ryzyko zakwestionowania przez US"`
- **Priorytet:** 116

---

# CZĘŚĆ VII: ŚRODOWISKO — NOWY PAKIET `jdg.environmental` (P1400-P1407)

> **Stan przed:** CAŁKOWICIE pominięty. JDG podlegają obowiązkom BDO, KOBiZE i opłatom środowiskowym.  
> **Po rozbudowie:** NOWY PAKIET z 5 regułami — BDO, KOBiZE, opłaty recyklingowe.

---

## P1400: `bdo_registration_check` — NOWY PLIK `jdg.environmental.bdo`

- **Cel biznesowy:** Weryfikacja obowiązku rejestracji w BDO (Baza Danych o Odpadach) — dotyczy JDG wprowadzających produkty w opakowaniach, sprzedających opakowania, generujących odpady.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.pkд_main in bdo_required_pkd` (lista PKD wymagających BDO)
  - LUB: `input.invoice.category_code == "PACKAGING"` (JDG wprowadza opakowania)
  - LUB: `input.invoice.direction == "SALE"` AND produkt jest w opakowaniu (e-commerce)
  - `input.jdg_entrepreneur.bdo_number == ""` (brak numeru BDO)
- **Rezultat:** 
  - `bdo_registration_required: true`
  - `bdo_must_appear_on_invoices: true` (numer BDO musi być na fakturach)
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Brak rejestracji BDO — obowiązek dla firm wprowadzających opakowania. Numer BDO musi być na fakturach."`
- **Podstawa prawna:** Ustawa o odpadach, Ustawa o obowiązkach przedsiębiorców w zakresie gospodarowania odpadami
- **Priorytet:** 1400
- **`[TODO: potrzebne źródło]`** — pełna lista PKD wymagających BDO

---

## P1402: `bdo_invoice_validation`

- **Cel biznesowy:** Walidacja obecności numeru BDO na fakturach sprzedaży — obowiązek dla JDG zarejestrowanych w BDO.
- **Przesłanki:** 
  - `bdo_registration_required == true` (z P1400)
  - `input.jdg_entrepreneur.bdo_number != ""`
  - `input.invoice.direction == "SALE"`
  - Numer BDO nie występuje na fakturze
- **Rezultat:** 
  - `bdo_missing_on_invoice: true`
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Faktura sprzedaży bez numeru BDO — obowiązek umieszczania numeru BDO na fakturach"`
- **Priorytet:** 1402

---

## P1405: `kobize_emission_report` — NOWY PLIK `jdg.environmental.kobize`

- **Cel biznesowy:** Obowiązek raportowania do KOBiZE (Krajowy Ośrodek Bilansowania i Zarządzania Emisjami) dla JDG zużywających paliwa — każde tankowanie samochodu firmowego generuje obowiązek raportowania emisji CO2.
- **Przesłanki:** 
  - `input.invoice.category_code == "FUEL"` (zakup paliwa)
  - `input.invoice.direction == "PURCHASE"`
  - `input.jdg_entrepreneur.kobize_required == true` (JDG podlega KOBiZE)
  - Paliwo zakupione na terytorium PL
- **Rezultat:** 
  - `kobize_emission_report_required: true`
  - `kobize_deadline: "02-28"` (do końca lutego za poprzedni rok)
  - `kobize_emission_total_annual` — narastająco śledzone emisje
  - `_warning: "Zakup paliwa — raportuj emisje do KOBiZE do końca lutego"`
- **Podstawa prawna:** Ustawa o systemie zarządzania emisjami gazów cieplarnianych
- **Priorytet:** 1405

---

## P1406: `kobize_exemption_small_emitter`

- **Cel biznesowy:** Zwolnienie z obowiązku raportowania KOBiZE dla JDG o nieznacznej emisji — poniżej progu 1 Mg CO2 rocznie (~500 litrów benzyny).
- **Przesłanki:** 
  - `kobize_emission_report_required == true` (z P1405)
  - `kobize_emission_total_annual < 1000_kg_co2` (poniżej 1 Mg CO2)
- **Rezultat:** 
  - `kobize_exempt_small_emitter: true`
  - `kobize_report_not_required: true` (zwolnienie)
  - `_info: "Emisja poniżej 1 Mg CO2 — zwolnienie z raportu KOBiZE"`
- **Priorytet:** 1406

---

# CZĘŚĆ VIII: RESTRUKTURYZACJA — NOWY PAKIET `jdg.restructuring` (P1500-P1505)

> **Stan przed:** CAŁKOWICIE pominięty. Przekształcenie JDG w sp. z o.o., aport przedsiębiorstwa, likwidacja.  
> **Po rozbudowie:** NOWY PAKIET z 4 regułami — konwersja JDG→spółka, likwidacja, remanent.

---

## P1500: `jdg_to_company_conversion_detection`

- **Cel biznesowy:** Wykrycie procesu przekształcenia JDG w spółkę z o.o. (lub inną spółkę handlową) — skutki podatkowe, sukcesja praw i obowiązków.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.business_status` zmienia się na `"CONVERTING_TO_COMPANY"`
  - Data planowanej konwersji określona
- **Rezultat:** 
  - `conversion_mode: true`
  - `conversion_requires: ["closing_inventory", "pkpir_closed", "vat_z_or_re_registration", "ceidg_deregistration", "krs_registration"]`
  - `tax_succession: "spolka_przejmuje_prawa_i_obowiazki_podatkowe"`
  - `_warning: "Przekształcenie JDG w spółkę — przeprowadź remanent likwidacyjny, zamknij PKPiR, wyrejestruj CEIDG"`
- **Podstawa prawna:** Art. 551 § 5 KSH, Art. 112-112b OP (sukcesja podatkowa)
- **Priorytet:** 1500

---

## P1502: `conversion_closing_inventory`

- **Cel biznesowy:** Obowiązek sporządzenia remanentu likwidacyjnego na dzień przekształcenia — wycena wszystkich składników majątku JDG.
- **Przesłanki:** 
  - `conversion_mode == true` (z P1500)
  - Data konwersji ustalona
  - Remanent nie sporządzony
- **Rezultat:** 
  - `closing_inventory_required: true`
  - `closing_inventory_date: conversion_date`
  - `closing_inventory_items: wszystkie środki trwałe, towary, materiały, należności, zobowiązania`
  - `_warning: "Sporządź remanent likwidacyjny na dzień przekształcenia — podstawa do wyceny wkładu do spółki"`
- **Podstawa prawna:** Art. 24 ust. 3 PIT (remanent likwidacyjny)
- **Priorytet:** 1502

---

## P1504: `conversion_vat_consequences`

- **Cel biznesowy:** Skutki VAT przekształcenia — jeśli spółka kontynuuje działalność, możliwa sukcesja VAT. Jeśli JDG kończy działalność — obowiązek VAT-Z i opodatkowanie remanentu.
- **Przesłanki:** 
  - `conversion_mode == true` (z P1500)
  - `input.jdg_entrepreneur.is_vat_payer == true`
- **Rezultat:** 
  - `vat_succession_possible: true` (spółka przejmuje NIP i status VAT — Art. 96 ust. 3a VAT)
  - `vat_z_not_required_during_conversion: true` (jeśli spółka kontynuuje)
  - `vat_on_closing_inventory: false` (zwolnione przy sukcesji)
  - `_info: "Przy przekształceniu w spółkę — VAT i NIP przechodzą na następcę prawnego"`
- **Podstawa prawna:** Art. 96 ust. 3a VAT, Art. 14 VAT
- **Priorytet:** 1504

---

## P1505: `conversion_psi_tax_exemption`

- **Cel biznesowy:** Weryfikacja możliwości zwolnienia z PIT/CIT przy przekształceniu — jeśli JDG działa na podstawie decyzji o wsparciu (Polska Strefa Inwestycji).
- **Przesłanki:** 
  - `conversion_mode == true` (z P1500)
  - `input.jdg_entrepreneur.has_psi_decision == true` (decyzja o wsparciu)
  - Nowa spółka kontynuuje działalność na terenie objętym decyzją
- **Rezultat:** 
  - `psi_exemption_continues: true` (zwolnienie podatkowe kontynuowane po przekształceniu)
  - `psi_conditions: "Kontynuacja działalności, utrzymanie zatrudnienia, realizacja inwestycji"`
  - `_info: "Decyzja o wsparciu PSI przechodzi na spółkę — zwolnienie podatkowe kontynuowane"`
- **Podstawa prawna:** Ustawa o wspieraniu nowych inwestycji
- **Priorytet:** 1505

---

# CZĘŚĆ IX: NICE-TO-HAVE — Zaawansowana Analityka i Nisze (P1700-P1799)

---

## P1700: `ip_box_nexus_ratio_calculation`

- **Cel biznesowy:** Automatyczna kalkulacja wskaźnika Nexus dla IP Box — określenie, jaka część dochodu z IP kwalifikuje się do 5% stawki. Wzór: (koszty kwalifikowane własne + koszty nabycia niepowiązanego) / (koszty całkowite IP).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form in ["PIT_SCALE", "LINEAR"]`
  - Dochód z kwalifikowanego IP
  - Koszty związane z wytworzeniem/rozwojem IP
- **Rezultat:** 
  - `nexus_ratio: koszty_kwalifikowane / koszty_calkowite` (min. 0, max. 1)
  - `ip_box_qualified_income: total_ip_income * nexus_ratio`
  - `ip_box_tax: ip_box_qualified_income * 0.05`
  - `remaining_income: total_ip_income - ip_box_qualified_income` (opodatkowane standardowo)
  - `_info: "IP Box Nexus Ratio = X. Kwalifikowany dochód: Y PLN"`
- **Podstawa prawna:** Art. 30ca ust. 4-6 PIT
- **Priorytet:** 1700
- **`[TODO: potrzebne źródło]`** — szczegółowe wytyczne MF do kalkulacji wskaźnika Nexus

---

## P1705: `progressive_amortization_optimization`

- **Cel biznesowy:** Automatyczna optymalizacja metody amortyzacji — analiza czy przejście z degresywnej na liniową lub jednorazowa amortyzacja jest korzystniejsza podatkowo.
- **Przesłanki:** 
  - `input.invoice.expense_type == "FIXED_ASSET"`
  - Środek trwały z grupy 3-6 KŚT (maszyny, urządzenia)
  - `input.jdg_entrepreneur.is_small_taxpayer == true`
- **Rezultat:** 
  - `recommended_method: "DEGRESSIVE"` (wyższe odpisy na początku → niższy podatek teraz)
  - `recommended_method: "ONE_OFF"` (jednorazowa amortyzacja do 50k EUR — najkorzystniejsza)
  - `switch_to_linear_year: <rok gdy degresywna ≤ liniowa>`
  - `_info: "Optymalizacja amortyzacji — metoda degresywna korzystniejsza przez X lat, potem przejdź na liniową"`
- **Priorytet:** 1705

---

## P1710: `crypto_trading_detection`

- **Cel biznesowy:** Rozpoznanie handlu kryptowalutami — przychody z krypto NIE są przychodem z JDG (chyba że to zorganizowana działalność giełdowa). Osobne zeznanie PIT-38.
- **Przesłanki:** 
  - `input.invoice.category_code == "CRYPTO_TRADE"`
  - Transakcja sprzedaży kryptowaluty
  - `input.jdg_entrepreneur.uses_organized_crypto_trading == false` (nie jest to zorganizowana działalność)
- **Rezultat:** 
  - `crypto_not_jdg_revenue: true` (NIE jest przychodem JDG)
  - `crypto_tax_form: "PIT-38"` (osobne zeznanie — source: kapitały pieniężne)
  - `crypto_tax_rate: "0.19"`
  - `_warning: "Handel kryptowalutami — rozlicz na PIT-38 jako przychód z kapitałów pieniężnych, NIE jako JDG"`
- **Podstawa prawna:** Art. 17 ust. 1 pkt 11 PIT, Art. 30b PIT
- **Priorytet:** 1710

---

## P1715: `aport_private_assets_to_jdg`

- **Cel biznesowy:** Automatyzacja zmiany wartości początkowej środka trwałego przy wniesieniu aportu prywatnego do JDG — wycena wg wartości rynkowej z dnia aportu.
- **Przesłanki:** 
  - `input.invoice.expense_type == "APORT_PRIVATE_TO_JDG"`
  - Składnik majątku z majątku prywatnego wnoszony do JDG
  - Protokół wyceny dostępny
- **Rezultat:** 
  - `aport_value: market_value_on_aport_date` (wartość rynkowa)
  - `depreciation_base: aport_value` (podstawa amortyzacji)
  - `_warning: "Aport prywatny — podstawa amortyzacji = wartość rynkowa z dnia aportu (nie cena zakupu prywatnego)"`
- **Podstawa prawna:** Art. 22g ust. 1 pkt 3 PIT
- **Priorytet:** 1715

---

## P1720: `fx_differences_bank_accounts`

- **Cel biznesowy:** Rozpoznanie różnic kursowych od własnych rachunków walutowych JDG — przewalutowania, wpływy w walutach obcych.
- **Przesłanki:** 
  - JDG posiada rachunek walutowy
  - Przewalutowanie środków między walutami
  - Wpływ w walucie obcej i późniejsza zapłata/konwersja
- **Rezultat:** 
  - `fx_bank_difference: (kurs_zbycia - kurs_nabycia) * kwota_waluty` (metoda FIFO/LIFO)
  - `fx_bank_gain: true` (przychód podatkowy)
  - `fx_bank_loss: true` (KUP)
  - `_info: "Różnice kursowe od rachunków walutowych rozliczane metodą FIFO"`
- **Prioryтет:** 1720

---

## P1725: `family_foundation_interaction`

- **Cel biznesowy:** Wykrycie interakcji między JDG a Fundacją Rodzinną — świadczenia z FR dla JDG, ukryte zyski, ograniczenia w działalności.
- **Przesłanki:** 
  - JDG otrzymuje świadczenia od Fundacji Rodzinnej (beneficjent)
  - LUB: JDG jest fundatorem FR
- **Rezultat:** 
  - `fr_benefit_taxable: true` (świadczenia z FR podlegają PIT)
  - `fr_business_restrictions: "FR nie może prowadzić działalności gospodarczej — tylko najem, obrót papierami wartościowymi, pożyczki dla beneficjentów"`
  - `_warning: "Świadczenie z Fundacji Rodzinnej — podlega opodatkowaniu PIT"`
- **Podstawa prawna:** Ustawa o fundacji rodzinnej (Dz.U. 2025 poz. 345)
- **Prioryтет:** 1725
- **`[TODO: potrzebne źródło]`** — szczegółowe regulacje podatkowe FR (PIT od świadczeń)

---

## P1730: `statute_barred_receivables_kup_final`

- **Cel biznesowy:** Całkowite ujęcie w KUP wierzytelności nieściągalnych po wyczerpaniu postępowania egzekucyjnego i uzyskaniu postanowienia o umorzeniu egzekucji.
- **Przesłanki:** 
  - `input.invoice.direction == "SALE"`
  - `input.invoice.is_paid == false`
  - Postępowanie egzekucyjne zakończone umorzeniem (brak majątku dłużnika)
  - `input.invoice.is_documented_uncollectible == true`
- **Rezultat:** 
  - `full_kup_for_statute_barred: true`
  - `kup_amount: kwota_netto_naleznosci`
  - `_warning: "Wierzytelność nieściągalna — ujęcie w KUP po wyczerpaniu egzekucji"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 17 PIT
- **Priorytet:** 1730

---

# CZĘŚĆ X: PODSUMOWANIE GŁĘBOKIEJ EKSPANSJI ENTERPRISE

## 10.1 Nowe Reguły — Pełna Lista ENTERPRISE

| Priorytet | rule_id | Pakiet | Obszar |
|:---------:|---------|--------|--------|
| **P66** | `wsto_threshold_monitor` | `jdg.vat.oss` ★ | E-commerce |
| **P67** | `oss_vat_rate_assignment` | `jdg.vat.oss` ★ | E-commerce |
| **P68** | `oss_quarterly_declaration` | `jdg.vat.oss` ★ | E-commerce |
| **P69** | `ioss_import_detection` | `jdg.vat.oss` ★ | E-commerce |
| **P100** | `wht_obligation_detection` | `jdg.wht` ★ | WHT |
| **P102** | `wht_certificate_of_residence` | `jdg.wht` ★ | WHT |
| **P104** | `wht_payment_deadline` | `jdg.wht` ★ | WHT |
| **P106** | `wht_annual_declaration` | `jdg.wht` ★ | WHT |
| **P108** | `wht_double_taxation_avoidance` | `jdg.wht` ★ | WHT |
| **P110** | `permanent_establishment_risk` | `jdg.international.pe` ★ | PE |
| **P112** | `pe_income_allocation` | `jdg.international.pe` ★ | PE |
| **P114** | `tp_documentation_threshold` | `jdg.international.tp` ★ | TP |
| **P116** | `tp_arm_length_test` | `jdg.international.tp` ★ | TP |
| **P571** | `kup_bad_debt_pit_debtor` | `jdg.pit.kup` | KUP PIT |
| **P573** | `kup_bad_debt_pit_creditor` | `jdg.pit.kup` | KUP PIT |
| **P575** | `kup_vehicle_insurance` | `jdg.pit.kup.insurance_kup` ★ | KUP |
| **P577** | `kup_zaw_nr_whitelist_procedure` | `jdg.pit.kup` | KUP |
| **P1200** | `employer_obligation_detection` | `jdg.employer.payroll` ★ | Employer |
| **P1202** | `payroll_tax_advance_obligation` | `jdg.employer.payroll` ★ | Employer |
| **P1204** | `payroll_zus_contributions_employer` | `jdg.employer.payroll` ★ | Employer |
| **P1206** | `annual_pit11_filing` | `jdg.employer.payroll` ★ | Employer |
| **P1208** | `ppk_obligation_check` | `jdg.employer.payroll` ★ | Employer |
| **P1210** | `small_mandate_flat_tax` | `jdg.employer.civil_contracts` ★ | Employer |
| **P1212** | `civil_contract_zus_classification` | `jdg.employer.civil_contracts` ★ | Employer |
| **P1220** | `copyright_transfer_50_kup` | `jdg.employer.copyright_kup` ★ | Employer |
| **P1222** | `copyright_kup_annual_limit` | `jdg.employer.copyright_kup` ★ | Employer |
| **P1400** | `bdo_registration_check` | `jdg.environmental.bdo` ★ | Środowisko |
| **P1402** | `bdo_invoice_validation` | `jdg.environmental.bdo` ★ | Środowisko |
| **P1405** | `kobize_emission_report` | `jdg.environmental.kobize` ★ | Środowisko |
| **P1406** | `kobize_exemption_small_emitter` | `jdg.environmental.kobize` ★ | Środowisko |
| **P1500** | `jdg_to_company_conversion_detection` | `jdg.restructuring.conversion` ★ | Restrukturyzacja |
| **P1502** | `conversion_closing_inventory` | `jdg.restructuring.conversion` ★ | Restrukturyzacja |
| **P1504** | `conversion_vat_consequences` | `jdg.restructuring.conversion` ★ | Restrukturyzacja |
| **P1505** | `conversion_psi_tax_exemption` | `jdg.restructuring.conversion` ★ | Restrukturyzacja |
| **P1600** | `rmk_detection` | `jdg.temporal.rmk` ★ | RMK |
| **P1602** | `rmk_monthly_release` | `jdg.temporal.rmk` ★ | RMK |
| **P1604** | `rmk_prepaid_rent_limit` | `jdg.temporal.rmk` ★ | RMK |
| **P1610** | `time_travel_evaluation_mode` | `jdg.temporal.time_travel` ★ | Time-Travel |
| **P1612** | `ksef_upo_timestamp_validation` | `jdg.temporal.time_travel` ★ | KSeF UPO |
| **P1700** | `ip_box_nexus_ratio_calculation` | `jdg.allowances.ip_box` | IP Box |
| **P1705** | `progressive_amortization_optimization` | `jdg.accounting.depreciation` | Amortyzacja |
| **P1710** | `crypto_trading_detection` | `jdg.pit.exemptions` | Krypto |
| **P1715** | `aport_private_assets_to_jdg` | `jdg.accounting.depreciation` | Aport |
| **P1720** | `fx_differences_bank_accounts` | `jdg.accounting.fx_differences` | FX |
| **P1725** | `family_foundation_interaction` | `jdg.pit.exemptions` | Fundacja Rodzinna |
| **P1730** | `statute_barred_receivables_kup_final` | `jdg.pit.kup` | KUP |

★ = nowy plik lub pakiet Rego

---

## 10.2 Statystyki — Ewolucja Systemu Reguł JDG

| Metryka | Dok. 22 | +23 | +26 | +27 | **RAZEM ENTERPRISE** |
|---------|:-------:|:---:|:---:|:---:|:---------------------:|
| **Pakiety JDG** | 23 | 28 | 31 | 37 | **37** |
| **Nowe pakiety (ten dokument)** | — | — | — | +6 | **6** |
| **Reguły łącznie** | ~145 | ~214 | ~272 | ~327 | **~327** |
| **Domeny prawne** | 30+ | 45+ | 55+ | 70+ | **70+** |
| **Podstawy prawne** | 70+ | 100+ | 150+ | 200+ | **200+** |
| **Nowe pola input** | ~80 | ~105 | ~145 | ~175 | **~175** |
| **Thresholds** | ~65 | ~85 | ~120 | ~145 | **~145** |

---

## 10.3 Nowe Pakiety ENTERPRISE (6)

| Pakiet | Pliki | Reguły | Odpowiedzialność |
|--------|-------|:------:|------------------|
| `jdg.wht` | `main.rego` | 5 | Withholding Tax — podatek u źródła |
| `jdg.international` | `permanent_establishment.rego`, `transfer_pricing.rego` | 4 | PE, ceny transferowe |
| `jdg.employer` | `payroll.rego`, `civil_contracts.rego`, `copyright_kup.rego` | 9 | JDG jako pracodawca/płatnik |
| `jdg.environmental` | `bdo.rego`, `kobize.rego` | 4 | BDO, KOBiZE, środowisko |
| `jdg.restructuring` | `conversion.rego` | 4 | Przekształcenie JDG→spółka |
| `jdg.temporal` | `rmk.rego`, `time_travel.rego` | 5 | RMK, Time-Travel OPA |

---

## 10.4 Priorytety Wdrożenia ENTERPRISE

| Faza | Liczba reguł | Opis |
|------|:------------:|------|
| **Faza D** (ENTERPRISE CRITICAL) | 19 | WHT (P100-P108), OSS/e-commerce (P66-P69), KUP złe długi PIT (P571-P577), ZAW-NR (P577), RMK (P1600-P1604), Time-Travel (P1610-P1612) |
| **Faza E** (ENTERPRISE CORE) | 14 | Employer (P1200-P1222), BDO (P1400-P1402), Konwersja (P1500-P1505), PE (P110-P112) |
| **Faza F** (ENTERPRISE NICE-TO-HAVE) | 12 | TP (P114-P116), KOBiZE (P1405-P1406), Krypto (P1710), Aport (P1715), FX bank (P1720), Fundacja Rodzinna (P1725), IP Box Nexus (P1700) |

---

> **Plik:** `Plan OPA/27_JDG_ENTERPRISE_DEEP_EXPANSION.md`  
> **Powiązane dokumenty:** `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` | `23_JDG_EXPANSION_SUPPLEMENT.md` | `24_JDG_COMPLETE_INDEX.md` | `25_JDG_DEEP_LEGAL_AUDIT.md` | `26_JDG_COMPREHENSIVE_EXPANSION.md`  
> **Razem reguł ENTERPRISE:** ~327 (145 + 69 + 58 + 55)
