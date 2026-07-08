# 📋 Rozbudowa Planu JDG — Uzupełnienie ENTERPRISE v2.0

> **Status:** Dokument Rozszerzeń JDG v2.0 — 65+ nowych reguł w 10 obszarach  
> **Data:** 2026-07-08  
> **Autor:** Zespół NexusAI  
> **Plik bazowy:** `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` (~145 reguł, P0-P1099)  
> **Plik uzupełniający:** `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` (niniejszy)  
> **Uwaga:** Nowe priorytety: P43-P49 (crossborder luki), P59-P63 (zwolnienia VAT), P185-P191 (VAT szczegółowy), P232 (VAT-UE), P588 (interakcje zwolnień PIT), P590-P599 (zmiana formy), P601-P615 (ulgi), P730-P739 (forma↔składki), P860-P869 (leasing), P1100-P1149 (korekty), P1150-P1199 (przedawnienia), P1200-P1219 (reprezentacja)  

---

## 0. Spis Treści Rozszerzeń

| # | Obszar | Nowe reguły | Zakres priorytetów | Nowe pakiety |
|---|--------|:-----------:|--------------------|--------------|
| 1 | Ulgi i odliczenia | 10 | P601-P615 | `jdg.allowances.*` (rozbudowa) |
| 2 | Zmiana formy opodatkowania | 7 | P590-P596 | `jdg.pit.tax_form_change` ★ NOWY |
| 3 | Eksport i import usług | 8 | P43-P49, P190-P191, P232 | `jdg.crossborder` (rozbudowa), `jdg.vat.declarations` ★ |
| 4 | Korekty deklaracji i faktur | 8 | P1100-P1114 | `jdg.corrections` ★ NOWY |
| 5 | Przedawnienia i odpowiedzialność | 9 | P1150-P1166 | `jdg.statute_liability` ★ NOWY |
| 6 | Reprezentacja i pełnomocnictwa | 7 | P1200-P1212 | `jdg.representation` ★ NOWY |
| 7 | Interakcje forma↔składki | 5 | P730-P738 | `jdg.zus.interactions` ★ NOWY |
| 8 | VAT szczegółowy dla JDG | 7 | P185-P191 | `jdg.vat.deduction` (rozbudowa) |
| 9 | Leasing dla JDG | 5 | P860-P868 | `jdg.accounting.leasing` ★ NOWY |
| 10 | Zwolnienia podmiotowe i przedmiotowe | 5 | P59-P63, P588 | `jdg.vat.exemptions`, `jdg.pit.exemptions` |

---

## 0.1 Aktualizacja drzewa pakietów JDG

```
policies/jdg/
├── main_jdg.rego                              # [UPDATE] Dodane importy nowych pakietów
├── ...
│
├── allowances/                                 # [ROZBUDOWA] Nowe reguły P601-P615
│   ├── rd.rego                                # P600 — istnieje (bez zmian)
│   ├── ip_box.rego                            # P610 — istnieje (bez zmian)
│   ├── prototype.rego                         # P601 — ★ NOWA ★
│   ├── robotization.rego                      # P602 — ★ NOWA ★
│   ├── expansion.rego                         # P603 — ★ NOWA ★
│   ├── rehabilitation.rego                    # P604 — ★ NOWA ★
│   ├── internet.rego                          # P605 — ★ NOWA ★
│   ├── donation.rego                          # P606-P608 — ★ NOWA ★
│   ├── abolition.rego                         # P609 — ★ NOWA ★
│   └── thermo.rego                            # P623 — istnieje (bez zmian)
│
├── pit/
│   ├── form_scale.rego                        # P500-P502 — istnieje
│   ├── form_linear.rego                       # P510-P511 — istnieje
│   ├── form_lump_sum.rego                     # P520-P523 — istnieje
│   ├── form_tax_card.rego                     # P530-P531 — istnieje
│   ├── tax_form_change.rego                   # P590-P596 — ★ NOWY ★
│   ├── advances.rego                          # P540-P543 + P615 — [ROZBUDOWA: P615 strata]
│   ├── annual_returns.rego                    # P550-P556 — istnieje
│   ├── kup.rego                               # P560-P570 — istnieje
│   └── exemptions.rego                        # P580-P586 + P588 — [ROZBUDOWA: P588 interakcje]
│
├── zus/
│   ├── social.rego                            # P700-P701 — istnieje
│   ├── health.rego                            # P720-P724 — istnieje
│   ├── start_relief.rego                      # P740 — istnieje
│   ├── maly_zus_plus.rego                     # P741 — istnieje
│   ├── preferential.rego                      # P742 — istnieje
│   └── interactions.rego                      # P730-P738 — ★ NOWY ★
│
├── accounting/
│   ├── pkpir.rego                             # P800-P802 — istnieje
│   ├── lump_sum_evidence.rego                 # P820 — istnieje
│   ├── vat_evidence.rego                      # P830-P832 — istnieje
│   ├── depreciation.rego                      # P840-P842 — istnieje
│   ├── private_mixed.rego                     # P850-P852 — istnieje
│   └── leasing.rego                           # P860-P868 — ★ NOWY ★
│
├── vat/
│   ├── substantive.rego                       # P50-P65 — istnieje
│   ├── gtu.rego                               # P65 — istnieje
│   ├── exemptions.rego                        # P55-P58 + P59-P63 — [ROZBUDOWA: P59-P63]
│   ├── tax_point.rego                         # P230-P235 — istnieje
│   ├── deduction.rego                         # P185-P189 — ★ ROZBUDOWA ★
│   └── declarations.rego                      # P232 — ★ NOWA ★
│
├── crossborder.rego                           # P40-P49 — [ROZBUDOWA: P43, P44, P46, P47, P49, P190, P191]
│
├── corrections/                               # ★ NOWY PAKIET ★
│   └── main.rego                              # P1100-P1114
│
├── statute_liability/                         # ★ NOWY PAKIET ★
│   └── main.rego                              # P1150-P1166
│
├── representation/                            # ★ NOWY PAKIET ★
│   └── main.rego                              # P1200-P1212
│
└── ...
```

---

## 0.2 Aktualizacja macierzy priorytetów

| Zakres | Pakiet | Odpowiedzialność | Nowe/zmienione |
|--------|--------|-------------------|----------------|
| **P43-P49** | `jdg.crossborder` | VAT-UE rejestracja, WNT szczegóły, import usług, transakcje trójstronne | ★ Rozbudowa |
| **P59-P63** | `jdg.vat.exemptions` | Zwolnienia: startup proportion, PKD, finansowe, ubezpieczenia | ★ Nowe |
| **P185-P191** | `jdg.vat.deduction`, `jdg.crossborder` | Pre-proporcja VAT, auto 50%, korekta roczna, termin 3m, ulga złe długi wierzyciel, WNT szczegóły, import VAT | ★ Rozbudowa |
| **P232** | `jdg.vat.declarations` | VAT-UE podsumowanie kwartalne | ★ Nowa |
| **P588** | `jdg.pit.exemptions` | Interakcje zwolnień PIT (współdzielony limit) | ★ Nowa |
| **P590-P596** | `jdg.pit.tax_form_change` | Zmiana formy opodatkowania JDG | ★ NOWY PAKIET |
| **P601-P615** | `jdg.allowances.*` | Pełny katalog ulg JDG | ★ Rozbudowa |
| **P730-P738** | `jdg.zus.interactions` | Interakcje forma↔składka zdrowotna | ★ NOWY PAKIET |
| **P860-P868** | `jdg.accounting.leasing` | Leasing operacyjny, finansowy, limity | ★ NOWY PAKIET |
| **P1100-P1114** | `jdg.corrections` | Korekty faktur, deklaracji, JPK | ★ NOWY PAKIET |
| **P1150-P1166** | `jdg.statute_liability` | Przedawnienia, odpowiedzialność, odsetki | ★ NOWY PAKIET |
| **P1200-P1212** | `jdg.representation` | Pełnomocnictwa PPS-1, UPL-1, prokura | ★ NOWY PAKIET |

---

## 0.3 Nowe pola `input` wymagane przez rozszerzenia

| Sekcja | Nowe pole | Typ | Opis |
|--------|----------|-----|------|
| `jdg_entrepreneur` | `has_disability_certificate` | `boolean` | Orzeczenie o niepełnosprawności (ulga rehabilitacyjna) |
| `jdg_entrepreneur` | `blood_donated_liters` | `number` | Litry oddanej krwi (ulga krwiodawcza) |
| `jdg_entrepreneur` | `foreign_income` | `number` | Dochód zagraniczny (ulga abolicyjna) |
| `jdg_entrepreneur` | `tax_treaty_method` | `string` | Metoda unikania podwójnego opodatkowania |
| `jdg_entrepreneur` | `performs_mixed_sales` | `boolean` | Czy prowadzi sprzedaż mieszaną (VAT + zw.) |
| `jdg_entrepreneur` | `married` | `boolean` | Stan cywilny (odpowiedzialność małżonka) |
| `jdg_entrepreneur` | `joint_property_regime` | `boolean` | Ustrój wspólności majątkowej |
| `jdg_entrepreneur` | `proxy_type` | `string` | Typ pełnomocnictwa: PPS-1 / UPL-1 / PPO-1 |
| `jdg_entrepreneur` | `proxy_expiration_date` | `string` | Data wygaśnięcia pełnomocnictwa |
| `jdg_entrepreneur` | `proxy_revoked` | `boolean` | Czy pełnomocnictwo odwołane |
| `jdg_entrepreneur` | `has_prokura` | `boolean` | Czy ustanowiono prokurenta w CEIDG |
| `jdg_entrepreneur` | `loss_carry_forward_remaining` | `number` | Pozostała strata do rozliczenia |
| `invoice` | `car_value` | `number` | Wartość samochodu (dla limitu 150k) |
| `invoice` | `excise_duty_paid` | `boolean` | Czy akcyza opłacona |
| `document` | `proxy_id` | `string` | Identyfikator pełnomocnictwa |
| `document` | `signed_by_proxy` | `boolean` | Czy podpisane przez pełnomocnika |
| `document` | `kks_proceedings_started` | `boolean` | Czy wszczęto postępowanie KKS |
| `document` | `enforcement_measure_applied` | `boolean` | Czy zastosowano środek egzekucyjny |
| `document` | `detected_during_audit` | `boolean` | Czy wykryto w trakcie kontroli |
| `document` | `years_since_due_year` | `number` | Lata od roku wymagalności |
| `document` | `zus_years_since_due` | `number` | Lata od wymagalności ZUS |
| `document` | `action_out_of_proxy_scope` | `boolean` | Działanie poza zakresem pełnomocnictwa |
| `document` | `declaration_signed_by_proxy` | `boolean` | Deklaracja podpisana przez pełnomocnika |
| `document` | `audit_in_progress` | `boolean` | Czy trwa kontrola podatkowa |
| `document` | `representation_by_third_party` | `boolean` | Czy reprezentacja przez osobę trzecią |
| `system` | `tax_audit_period_matches` | `boolean` | Czy okres korekty = okres kontroli |

### 0.3.1 Nowe wartości `expense_type` dla JDG

| Wartość | Opis | Powiązane reguły |
|---------|------|------------------|
| `EXPANSION_PROMOTION` | Koszty targów i promocji zagranicznej | P603 |
| `REHABILITATION` | Wydatki rehabilitacyjne | P604 |
| `INTERNET` | Internet (ulga) | P605 |
| `PROTOTYPE` | Produkcja próbna / prototyp | P601 |
| `ROBOTIZATION` | Zakup robotów przemysłowych | P602 |
| `DONATION` | Darowizna | P606-P608 |
| `CAR_LEASE` | Leasing samochodu | P864 |
| `CAR_MIXED_USE` | Samochód użytku mieszanego | P186 |
| `OPERATING_LEASE` | Leasing operacyjny | P860 |
| `FINANCIAL_LEASE` | Leasing finansowy | P862 |
| `CONSUMER_LEASE` | Leasing konsumencki | P866 |

---

## 0.4 Nowe wartości w `thresholds.jdg.*`

| Klucz | Wartość | Opis |
|-------|---------|------|
| `bounds.relief_rd_base` | 100 | Ulga B+R — % podstawowy |
| `bounds.relief_rd_centrum` | 200 | Ulga B+R — % CBR |
| `bounds.relief_prototype_percent` | 30 | % kosztów prototypu |
| `bounds.relief_robotization_percent` | 50 | % kosztów robotyzacji |
| `bounds.relief_expansion_max` | 1000000 | Max ulgi ekspansyjnej PLN |
| `bounds.relief_internet_max` | 760 | Max ulgi internetowej PLN/rok |
| `bounds.relief_internet_years` | 2 | Maks. lat ulgi internetowej |
| `bounds.blood_liter_equivalent` | 130 | Ekwiwalent za litr krwi PLN |
| `bounds.donation_limit_percent` | 6 | Limit darowizn % dochodu |
| `bounds.loss_deduction_limit` | 5000000 | Limit jednorazowego odliczenia straty PLN |
| `limits.car_value_kup_limit` | 150000 | Limit wartości auta dla pełnego KUP |
| `limits.vat_deduction_months` | 3 | Miesiące na odliczenie VAT |
| `limits.statute_years_tax` | 5 | Lata przedawnienia podatkowego |
| `limits.statute_years_zus` | 5 | Lata przedawnienia ZUS |
| `rates.tax_interest_rate` | "0.145" | Stopa odsetek podatkowych |
| `rates.tax_interest_penalty_mult` | 1.5 | Mnożnik odsetek karnych |
| `rates.car_vat_deduction_percent` | 50 | % odliczenia VAT dla aut mieszanych |
| `eu_countries` | `["AT","BE","BG",...]` | Lista krajów UE dla VAT-UE |

---

# CZĘŚĆ 1: ULGI I ODLICZENIA — ROZBUDOWA (P601-P615)

Istniejący plan (P600, P610, P623) pokrywa tylko ulgę B+R, IP Box i termomodernizacyjną. Poniżej pełny katalog ulg dla JDG.

---

## P601: `relief_prototype_jdg`

- **Cel biznesowy:** Odliczenie od podstawy opodatkowania 30% kosztów produkcji próbnej nowego produktu lub wprowadzenia go na rynek.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form` in `["PIT_SCALE", "LINEAR"]` (tylko te formy!)
  - `input.invoice.expense_type == "PROTOTYPE"`
  - Koszt poniesiony w roku podatkowym
  - Produkt nie był wcześniej produkowany przez JDG
- **Rezultat:** 
  - `relief_type: "PROTOTYPE"`
  - `relief_percent: input.thresholds.jdg.bounds.relief_prototype_percent` (30%)
  - `relief_amount: amount_net * 0.30`
  - `kus_qualification: "full"` (koszt w KUP + dodatkowa ulga 30%)
- **Podstawa prawna:** Art. 26eb ustawy o PIT
- **Zależności:** Sprawdzana PO P500-P511 (forma PIT), PRZED P615 (strata)
- **Priorytet:** 601

## P602: `relief_robotization_jdg`

- **Cel biznesowy:** Odliczenie 50% kosztów nabycia fabrycznie nowych robotów przemysłowych, maszyn i urządzeń peryferyjnych oraz wartości niematerialnych i prawnych.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form` in `["PIT_SCALE", "LINEAR"]`
  - `input.invoice.expense_type == "ROBOTIZATION"`
  - Robot musi być fabrycznie nowy
  - Koszty poniesione po 2021 roku
- **Rezultat:** 
  - `relief_type: "ROBOTIZATION"`
  - `relief_percent: input.thresholds.jdg.bounds.relief_robotization_percent` (50%)
- **Podstawa prawna:** Art. 26gb ustawy o PIT
- **Priorytet:** 602

## P603: `relief_expansion_jdg`

- **Cel biznesowy:** Odliczenie kosztów uczestnictwa w targach, działań promocyjno-informacyjnych, przygotowania dokumentacji na rynki zagraniczne — max 1 000 000 PLN rocznie.
- **Przesłanki:** 
  - `input.invoice.expense_type == "EXPANSION_PROMOTION"`
  - Roczna suma ulgi ≤ `input.thresholds.jdg.bounds.relief_expansion_max` (1 000 000 PLN)
- **Rezultat:** 
  - `relief_type: "EXPANSION"`
  - `relief_max: input.thresholds.jdg.bounds.relief_expansion_max`
- **Podstawa prawna:** Art. 26ec ustawy o PIT
- **Priorytet:** 603

## P604: `relief_rehabilitation_jdg`

- **Cel biznesowy:** Odliczenie wydatków na cele rehabilitacyjne oraz ułatwiających wykonywanie czynności życiowych dla JDG z orzeczeniem o niepełnosprawności.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.has_disability_certificate == true`
  - `input.invoice.expense_type == "REHABILITATION"`
  - Wydatek nie był sfinansowany ze środków ZFŚS / PFRON / NFZ
- **Rezultat:** 
  - `relief_type: "REHABILITATION"`
  - `kus_qualification: "deduction_from_income"`
- **Podstawa prawna:** Art. 26 ust. 1 pkt 6 ustawy o PIT
- **Priorytet:** 604

## P605: `relief_internet_jdg`

- **Cel biznesowy:** Odliczenie wydatków na internet (max 760 PLN rocznie) przez maksymalnie dwa następujące po sobie lata podatkowe.
- **Przesłanki:** 
  - `input.invoice.category_code == "INTERNET"` lub expense_type == `"INTERNET"`
  - `input.jdg_entrepreneur.internet_years_used < input.thresholds.jdg.bounds.relief_internet_years` (2)
  - Roczna kwota ≤ `input.thresholds.jdg.bounds.relief_internet_max` (760 PLN)
- **Rezultat:** 
  - `relief_type: "INTERNET"`
  - `relief_max: input.thresholds.jdg.bounds.relief_internet_max`
  - `internet_years_remaining: 2 - used_years`
- **Podstawa prawna:** Art. 26 ust. 1 pkt 6a ustawy o PIT
- **Priorytet:** 605

## P606: `relief_donation_ngo_jdg`

- **Cel biznesowy:** Odliczenie darowizn na rzecz organizacji pożytku publicznego (OPP) do wysokości 6% dochodu.
- **Przesłanki:** 
  - `input.vendor.is_ngo == true`
  - `input.invoice.expense_type == "DONATION"`
  - Darowizna pieniężna potwierdzona dowodem wpłaty na rachunek OPP
  - Roczna suma darowizn ≤ 6% dochodu
- **Rezultat:** 
  - `relief_type: "DONATION_NGO"`
  - `relief_limit_percent: input.thresholds.jdg.bounds.donation_limit_percent` (6%)
- **Podstawa prawna:** Art. 26 ust. 1 pkt 9 lit. a ustawy o PIT
- **Priorytet:** 606

## P607: `relief_donation_blood_jdg`

- **Cel biznesowy:** Odliczenie ekwiwalentu za oddaną krew (130 PLN/litr). Dzieli wspólny limit 6% z darowiznami OPP.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.blood_donated_liters > 0`
  - Suma darowizn OPP + krew ≤ 6% dochodu
- **Rezultat:** 
  - `relief_type: "DONATION_BLOOD"`
  - `relief_amount: blood_liters * input.thresholds.jdg.bounds.blood_liter_equivalent`
  - `relief_limit_percent: 6` (wspólny limit z OPP)
- **Podstawa prawna:** Art. 26 ust. 1 pkt 9 lit. c ustawy o PIT
- **Priorytet:** 607

## P608: `relief_donation_church_jdg`

- **Cel biznesowy:** Odliczenie darowizn na cele kultu religijnego. Limit 6% dochodu (osobny limit, niezależny od OPP).
- **Przesłanki:** 
  - `input.vendor.is_religious_org == true`
  - `input.invoice.expense_type == "DONATION"`
  - Płatność bankowa
- **Rezultat:** 
  - `relief_type: "DONATION_CHURCH"`
  - `relief_limit_percent: 6` (osobny limit od OPP)
- **Podstawa prawna:** Art. 26 ust. 1 pkt 9 lit. b ustawy o PIT
- **Priorytet:** 608

## P609: `relief_abolition_jdg`

- **Cel biznesowy:** Ulga abolicyjna — zrównanie opodatkowania dochodów zagranicznych rozliczanych metodą odliczenia proporcjonalnego z metodą wyłączenia z progresją.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.foreign_income > 0`
  - `input.jdg_entrepreneur.tax_treaty_method == "proportional_deduction"`
  - `input.jdg_entrepreneur.tax_form in ["PIT_SCALE", "LINEAR"]`
- **Rezultat:** 
  - `relief_type: "ABOLITION_RELIEF"`
  - `relief_amount: różnica między metodą odliczenia a wyłączenia`
- **Podstawa prawna:** Art. 27g ustawy o PIT
- **Priorytet:** 609

## P615: `loss_carry_forward_jdg`

- **Cel biznesowy:** Odliczenie straty z lat ubiegłych — do 50% straty rocznie przez 5 lat lub do 5 mln PLN jednorazowo (nowe zasady od 2025).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.has_loss_carry_forward == true`
  - `input.jdg_entrepreneur.loss_carry_forward_remaining > 0`
  - Rok poniesienia straty ≤ 5 lat wstecz
  - `input.jdg_entrepreneur.tax_form in ["PIT_SCALE", "LINEAR"]` (ryczałt i karta NIE mogą rozliczać strat)
- **Rezultat:** 
  - `loss_deduction_applied: true`
  - `max_deduction_one_year: 5000000` (jednorazowo) lub 50% straty
  - `_warning: "Strata rozliczona — max 50% rocznie lub 5 mln PLN jednorazowo w 5-letnim okresie"`
- **Podstawa prawna:** Art. 9 ust. 3 ustawy o PIT
- **Priorytet:** 615

---

# CZĘŚĆ 2: ZMIANA FORMY OPODATKOWANIA — NOWY PAKIET (P590-P596)

★ NOWY PAKIET: `jdg.pit.tax_form_change` ★

---

## P590: `change_scale_to_linear`

- **Cel biznesowy:** Walidacja i skutki przejścia ze skali podatkowej na podatek liniowy. Zmiana możliwa tylko od nowego roku.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form_changed_from == "PIT_SCALE"`
  - `input.jdg_entrepreneur.tax_form == "LINEAR"`
  - `input.jdg_entrepreneur.tax_form_change_date` == `"01-01"` (tylko od nowego roku)
  - Zgłoszenie do US do 20. dnia miesiąca po pierwszym przychodzie
- **Rezultat:** 
  - `tax_form_change_valid: true`
  - `_warning: "Przejście na podatek liniowy — brak kwoty wolnej, brak ulg osobistych, składka zdrowotna 4.9%"`
- **Podstawa prawna:** Art. 9a ust. 2 ustawy o PIT
- **Priorytet:** 590

## P591: `change_linear_to_lump_sum`

- **Cel biznesowy:** Walidacja przejścia z podatku liniowego na ryczałt ewidencjonowany. Konieczność zaprowadzenia ewidencji ryczałtowej. Utrata prawa do amortyzacji.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form_changed_from == "LINEAR"`
  - `input.jdg_entrepreneur.tax_form == "LUMP_SUM"`
  - Roczne przychody w poprzednim roku ≤ równowartość 2 000 000 EUR
- **Rezultat:** 
  - `requires_lump_sum_evidence: true`
  - `ceases_pkpir_depreciation: true`
  - `_warning: "Przejście na ryczałt — koniec amortyzacji, nowa ewidencja, składka zdrowotna wg progów ryczałtowych"`
- **Podstawa prawna:** Art. 9 ustawy o ryczałcie ewidencjonowanym
- **Priorytet:** 591

## P592: `change_lump_sum_to_scale`

- **Cel biznesowy:** Powrót z ryczałtu na skalę ogólną. Konieczność założenia PKPiR i sporządzenia remanentu początkowego.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form_changed_from == "LUMP_SUM"`
  - `input.jdg_entrepreneur.tax_form == "PIT_SCALE"`
- **Rezultat:** 
  - `requires_pkpir: true`
  - `pkpir_opening_inventory: true`
  - `_warning: "Powrót na skalę podatkową — wymagane założenie PKPiR i remanent początkowy"`
- **Podstawa prawna:** Art. 24a ustawy o PIT
- **Priorytet:** 592

## P593: `mid_year_change_restriction`

- **Cel biznesowy:** Blokada zmiany formy opodatkowania w trakcie roku podatkowego. Wyjątek: karta podatkowa → ryczałt (w dowolnym momencie po utracie prawa do karty).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form_change_date != "01-01"`
  - `input.jdg_entrepreneur.tax_form_changed_from != "TAX_CARD"`
  - Zmiana NIE dotyczy karty → ryczałt
- **Rezultat:** 
  - `_routing: "BLOCK_AND_ALERT"`
  - `error: "Niedozwolona zmiana formy opodatkowania w trakcie roku podatkowego"`
- **Podstawa prawna:** Art. 9a ust. 2 PIT, Art. 22 ustawy o ryczałcie
- **Priorytet:** 593

## P594: `tax_consequences_form_change`

- **Cel biznesowy:** Wymuszenie złożenia dwóch osobnych zeznań rocznych, jeśli JDG utraciła prawo do ryczałtu w trakcie roku i przeszła na skalę.
- **Przesłanki:** 
  - `tax_form_changed_during_year == true` (utrata prawa do ryczałtu w trakcie roku)
  - Przychody w trakcie roku przekroczyły limit ryczałtu
- **Rezultat:** 
  - `requires_multiple_annual_returns: true`
  - `return_types: ["PIT-28", "PIT-36"]`
- **Podstawa prawna:** Art. 22 ustawy o ryczałcie
- **Priorytet:** 594

## P595: `inventory_remeasurement_change`

- **Cel biznesowy:** Wymóg sporządzenia remanentu przy zmianie formy opodatkowania między ryczałtem a skalą/liniowym.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form_changed_this_year == true`
  - Zmiana obejmuje przejście między ryczałt ↔ skala/liniowy
  - Data remanentu = 1 stycznia roku zmiany
- **Rezultat:** 
  - `inventory_required: true`
  - `inventory_date: "01-01"`
- **Podstawa prawna:** § 24 rozporządzenia w sprawie PKPiR
- **Priorytet:** 595

## P596: `zus_health_recalculation_change`

- **Cel biznesowy:** Automatyczne przeliczenie składki zdrowotnej po zmianie formy opodatkowania — zmiana podstawy i stawki.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form_changed_this_year == true`
  - Nowa forma ma inną metodę naliczania składki zdrowotnej (skala→liniowy: 9%→4.9%, liniowy→ryczałt: dochód→progi przychodowe)
- **Rezultat:** 
  - `zus_health_base: "NEW_FORM_METHOD"`
  - `requires_zus_dra_update: true`
  - `_warning: "Zmiana formy opodatkowania — konieczna aktualizacja deklaracji ZUS DRA"`
- **Podstawa prawna:** Art. 81 ust. 2 ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 596

---

# CZĘŚĆ 3: EKSPORT I IMPORT USŁUG — ROZBUDOWA (P43-P49, P190-P191, P232)

---

## P43: `vat_ue_registration_mandatory`

- **Cel biznesowy:** Blokada transakcji wewnątrzwspólnotowych dla JDG niezarejestrowanego jako podatnik VAT-UE. Wymóg rejestracji PRZED pierwszą transakcją WNT/WDT.
- **Przesłanki:** 
  - `input.vendor.country` in EU_COUNTRIES (lista z thresholds)
  - `input.jdg_entrepreneur.is_vat_eu_registered == false`
  - `input.invoice.direction in ["PURCHASE", "SALE"]`
- **Rezultat:** 
  - `_routing: "BLOCK_AND_ALERT"`
  - `error: "Brak rejestracji VAT-UE — wymagany formularz VAT-R przed transakcją transgraniczną"`
  - `vat_ue_registration_required: true`
- **Podstawa prawna:** Art. 97 ust. 1-3 ustawy o VAT
- **Priorytet:** 43

## P44: `vat_r_ue_filing_deadline`

- **Cel biznesowy:** Obowiązek zgłoszenia VAT-R przed pierwszą transakcją WNT/WDT. Alert o konieczności rejestracji z wyprzedzeniem.
- **Przesłanki:** 
  - `planned_intra_community_transaction == true` (planowana transakcja UE)
  - `input.jdg_entrepreneur.is_vat_eu_registered == false`
- **Rezultat:** 
  - `vat_r_filing_required: true`
  - `vat_r_deadline: "PRZED pierwszą transakcją WNT/WDT"`
  - `_warning: "Zarejestruj VAT-UE przed pierwszą transakcją wewnątrzwspólnotową"`
- **Podstawa prawna:** Art. 97 ust. 1-3 ustawy o VAT
- **Priorytet:** 44

## P46: `intracommunity_acquisition_detailed`

- **Cel biznesowy:** WNT — szczegółowe reguły: naliczenie VAT należnego wg stawki krajowej i jednoczesne odliczenie (jeśli przysługuje), obowiązek podatkowy 15. dnia następnego miesiąca lub data faktury.
- **Przesłanki:** 
  - `input.invoice.type == "GOODS"` (towary, nie usługi)
  - `input.vendor.country` in EU_COUNTRIES
  - `input.jdg_entrepreneur.is_vat_eu_registered == true`
- **Rezultat:** 
  - `procedure: "WNT"`
  - `vat_rate_nalezny: "DOMESTIC_EQUIVALENT"` (wg stawki krajowej dla danego towaru)
  - `vat_rate_naliczony: "DOMESTIC_EQUIVALENT"` (jednoczesne odliczenie)
  - `tax_point_wnt: "15th_next_month_or_invoice_date"`
- **Podstawa prawna:** Art. 9, Art. 11, Art. 20 ust. 5 ustawy o VAT
- **Priorytet:** 46

## P47: `import_services_non_eu`

- **Cel biznesowy:** Import usług spoza UE — reverse charge. Miejsce świadczenia = Polska (siedziba nabywcy). JDG rozlicza VAT należny i naliczony.
- **Przesłanki:** 
  - `input.invoice.type == "SERVICE"`
  - `input.vendor.country == "NON_EU"`
  - `input.jdg_entrepreneur.is_vat_payer == true`
- **Rezultat:** 
  - `procedure: "IMPORT_SERVICES"`
  - `reverse_charge: true`
  - `vat_rate: "DOMESTIC_EQUIVALENT"`
  - `_warning: "Import usług spoza UE — rozlicz VAT należny i naliczony w JPK_V7"`
- **Podstawa prawna:** Art. 28b, Art. 17 ust. 1 pkt 4 ustawy o VAT
- **Priorytet:** 47

## P49: `triangular_transaction_rules`

- **Cel biznesowy:** Obsługa procedury uproszczonej w wewnątrzwspólnotowych transakcjach trójstronnych. JDG jako pośrednik — brak obowiązku rejestracji VAT w kraju dostawy.
- **Przesłanki:** 
  - `input.invoice.procedure == "TRIANGULAR_EU"`
  - Trzy podmioty z trzech różnych krajów UE
  - Towar wysyłany bezpośrednio od pierwszego do ostatniego podmiotu
- **Rezultat:** 
  - `triangular_simplified: true`
  - `vat_rate: "0.00"` (dla JDG-pośrednika)
  - `_warning: "Transakcja trójstronna — procedura uproszczona, brak rejestracji VAT w kraju dostawy"`
- **Podstawa prawna:** Art. 135-138 ustawy o VAT
- **Priorytet:** 49

## P190: `wnt_intra_community_detailed`

- **Cel biznesowy:** Szczegółowe reguły obowiązku podatkowego WNT — jeśli faktura dotrze do 15. dnia następnego miesiąca, obowiązek powstaje 15. dnia; jeśli później — w dacie wystawienia.
- **Przesłanki:** 
  - `input.invoice.procedure == "WNT"` (lub crossborder_type)
  - Data otrzymania faktury vs 15. dzień następnego miesiąca
- **Rezultat:** 
  - `tax_point_wnt: "15TH_NEXT_MONTH"` lub `"INVOICE_DATE"`
  - `vat_deduction_same_period: true`
- **Podstawa prawna:** Art. 20 ust. 5 ustawy o VAT
- **Priorytet:** 190

## P191: `import_vat_deduction_timing`

- **Cel biznesowy:** Odliczenie VAT od importu towarów — możliwe w deklaracji za okres, w którym otrzymano dokument celny (nie wcześniej).
- **Przesłanki:** 
  - `input.invoice.procedure == "IMPORT"`
  - `input.invoice.custom_declaration_received == true`
  - `input.jdg_entrepreneur.is_vat_payer == true`
- **Rezultat:** 
  - `import_vat_deduction_allowed: true`
  - `vat_deduction_period: "MONTH_OF_CUSTOM_DOCUMENT"`
  - `_warning: "VAT od importu — odliczenie w okresie otrzymania dokumentu celnego"`
- **Podstawa prawna:** Art. 86 ust. 2 pkt 2, Art. 86 ust. 10b pkt 3 ustawy o VAT
- **Priorytet:** 191

## P232: `vat_ue_quarterly_summary`

- **Cel biznesowy:** Obowiązek składania informacji podsumowującej VAT-UE za okresy kwartalne (lub miesięczne przy przekroczeniu progu 50 000 PLN). Termin: 25. dnia miesiąca po kwartale.
- **Przesłanki:** 
  - `has_eu_transactions == true` (WNT lub WDT w okresie)
  - `input.jdg_entrepreneur.is_vat_eu_registered == true`
- **Rezultat:** 
  - `vat_ue_summary_required: true`
  - `vat_ue_frequency: "QUARTERLY"` (domyślnie) lub `"MONTHLY"` (przy > 50 000 PLN)
  - `vat_ue_deadline: "25th_day_after_quarter"`
- **Podstawa prawna:** Art. 100 ust. 1 i 3 ustawy o VAT
- **Priorytet:** 232

---

# CZĘŚĆ 4: KOREKTY DEKLARACJI I FAKTUR — NOWY PAKIET (P1100-P1114)

★ NOWY PAKIET: `jdg.corrections` ★

---

## P1100: `correction_invoice_in_minus`

- **Cel biznesowy:** Zmniejszenie podstawy opodatkowania (korekta in minus) — warunki: posiadanie potwierdzenia uzgodnienia z nabywcą, ujęcie w bieżącym okresie.
- **Przesłanki:** 
  - `input.invoice.is_correction == true`
  - `input.invoice.correction_type == "IN_MINUS"`
  - `input.invoice.has_buyer_agreement == true`
- **Rezultat:** 
  - `correction_recognition: "CURRENT_PERIOD"`
  - `requires_buyer_agreement: true`
  - `_warning: "Korekta in-minus — wymagane potwierdzenie uzgodnienia z nabywcą"`
- **Podstawa prawna:** Art. 29a ust. 13 ustawy o VAT
- **Priorytet:** 1100

## P1102: `correction_invoice_in_plus`

- **Cel biznesowy:** Zwiększenie podstawy opodatkowania (korekta in plus) — rozpoznanie zależy od przyczyny: błąd rachunkowy/pomyłka → korekta wsteczna; nowa okoliczność → na bieżąco.
- **Przesłanki:** 
  - `input.invoice.is_correction == true`
  - `input.invoice.correction_type == "IN_PLUS"`
- **Rezultat:** 
  - `correction_recognition: "CHECK_CAUSE"` (wymaga analizy przyczyny)
  - Korekta wsteczna (błąd) lub bieżąca (nowa okoliczność)
- **Podstawa prawna:** Art. 29a ust. 17 ustawy o VAT
- **Priorytet:** 1102

## P1104: `vat_declaration_correction`

- **Cel biznesowy:** Wymóg złożenia korekty JPK_V7 z kodem `CelZlozenia = 2` (korekta) oraz uzasadnieniem przyczyny korekty.
- **Przesłanki:** 
  - `input.invoice.modifies_closed_vat_period == true`
  - Korekta dotyczy zamkniętego okresu rozliczeniowego VAT
- **Rezultat:** 
  - `requires_jpk_correction: true`
  - `jpk_cel_zlozenia: "2"` (korekta)
  - `requires_correction_reason_code: true`
- **Podstawa prawna:** Art. 81 Ordynacji podatkowej, struktury logiczne JPK_V7
- **Priorytet:** 1104

## P1106: `pit_advance_correction`

- **Cel biznesowy:** Przeliczenie zaliczek na PIT w poprzednich miesiącach ze względu na wsteczne korekty przychodów lub kosztów. Ryzyko odsetek za zwłokę.
- **Przesłanki:** 
  - `backward_income_correction == true` (korekta przychodów wstecz)
  - `backward_expense_correction == true` (korekta kosztów wstecz)
  - Korekta dotyczy miesięcy, za które złożono już zaliczki
- **Rezultat:** 
  - `recalculate_past_advances: true`
  - `interest_penalty_possible: true`
  - `_warning: "Korekta wsteczna zaliczek PIT — możliwe odsetki za zwłokę"`
- **Podstawa prawna:** Art. 44 ustawy o PIT, Art. 53-56 Ordynacji podatkowej
- **Priorytet:** 1106

## P1108: `jpk_v7_correction_code`

- **Cel biznesowy:** Obligatoryjne oznaczenie kodu przyczyny korekty w JPK_V7 przy korekcie składanej w ramach czynnego żalu.
- **Przesłanki:** 
  - `input.invoice.modifies_closed_vat_period == true`
  - Korekta składana jako czynny żal (Art. 16 KKS)
- **Rezultat:** 
  - `add_czynny_zal_justification: true`
  - `correction_reason_code_required: true`
- **Podstawa prawna:** Art. 16a KKS, struktury logiczne JPK_V7
- **Priorytet:** 1108

## P1110: `correction_deadline_restrictions`

- **Cel biznesowy:** Termin na odliczenie VAT poprzez korektę deklaracji: 3 miesiące od końca miesiąca otrzymania faktury (JPK_V7M) lub kwartału (JPK_V7K), maksymalnie do końca roku.
- **Przesłanki:** 
  - `input.invoice.is_vat_deducted == false`
  - `input.invoice.months_since_issue > 0`
  - `input.invoice.months_since_issue <= 3` (dla JPK_V7M) lub odpowiednio dla V7K
- **Rezultat:** 
  - `vat_deduction_correction_window_valid: true`
  - `vat_deduction_deadline_months: 3`
  - `_warning: "Odliczenie VAT przez korektę — max 3 miesiące od otrzymania faktury"`
- **Podstawa prawna:** Art. 86 ust. 13 ustawy o VAT
- **Priorytet:** 1110

## P1112: `statute_barred_correction_block`

- **Cel biznesowy:** Całkowita blokada korekty deklaracji podatkowej dla okresów po upływie terminu przedawnienia (5 lat od końca roku kalendarzowego).
- **Przesłanki:** 
  - `input.document.years_since_due_year > input.thresholds.jdg.limits.statute_years_tax` (5)
  - Korekta dotyczy okresu sprzed > 5 lat
- **Rezultat:** 
  - `_routing: "BLOCK_AND_ALERT"`
  - `error: "Okres podatkowy uległ przedawnieniu — korekta niedopuszczalna"`
  - `statute_barred: true`
- **Podstawa prawna:** Art. 70 § 1 Ordynacji podatkowej, Art. 86 ust. 8 ustawy o VAT
- **Priorytet:** 1112

## P1114: `correction_during_audit_block`

- **Cel biznesowy:** Blokada prawa do składania korekty deklaracji w trakcie kontroli podatkowej lub celno-skarbowej (za okres objęty kontrolą).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.under_tax_audit == true`
  - `input.system.tax_audit_period_matches == true` (okres korekty = okres kontroli)
  - `input.invoice.is_correction == true`
- **Rezultat:** 
  - `_routing: "BLOCK_AND_ALERT"`
  - `error: "Korekta zablokowana — trwa kontrola podatkowa za ten okres"`
  - `correction_blocked_during_audit: true`
- **Podstawa prawna:** Art. 81b § 1 Ordynacji podatkowej
- **Priorytet:** 1114

---

# CZĘŚĆ 5: PRZEDAWNIENIA I ODPOWIEDZIALNOŚĆ — NOWY PAKIET (P1150-P1166)

★ NOWY PAKIET: `jdg.statute_liability` ★

---

## P1150: `tax_statute_of_limitations_5y`

- **Cel biznesowy:** Przedawnienie zobowiązań podatkowych JDG po 5 latach od końca roku kalendarzowego, w którym upłynął termin płatności.
- **Przesłanki:** 
  - `input.document.years_since_due_year > input.thresholds.jdg.limits.statute_years_tax` (5)
  - Brak zawieszenia/przerwania biegu przedawnienia
  - Brak wszczętego postępowania karnego-skarbowego
- **Rezultat:** 
  - `tax_liability_expired: true`
  - `_warning: "Zobowiązanie podatkowe przedawnione — brak obowiązku zapłaty"`
- **Podstawa prawna:** Art. 70 § 1 Ordynacji podatkowej
- **Priorytet:** 1150

## P1152: `zus_statute_of_limitations_5y`

- **Cel biznesowy:** Przedawnienie należności z tytułu składek ZUS po upływie 5 lat od dnia, w którym stały się wymagalne.
- **Przesłanki:** 
  - `input.document.zus_years_since_due > input.thresholds.jdg.limits.statute_years_zus` (5)
  - Brak zawieszenia biegu przedawnienia
- **Rezultat:** 
  - `zus_liability_expired: true`
  - `_warning: "Należności ZUS przedawnione"`
- **Podstawa prawna:** Art. 24 ust. 4 ustawy o SUS
- **Priorytet:** 1152

## P1154: `statute_suspension_during_audit`

- **Cel biznesowy:** Zawieszenie biegu przedawnienia zobowiązania podatkowego w trakcie postępowania karnego-skarbowego lub kontroli celno-skarbowej.
- **Przesłanki:** 
  - `input.document.kks_proceedings_started == true`
  - Postępowanie dotyczy tego samego zobowiązania
- **Rezultat:** 
  - `statute_suspended: true`
  - `_warning: "Bieg przedawnienia zawieszony — toczy się postępowanie KKS"`
- **Podstawa prawna:** Art. 70 § 6 pkt 1 Ordynacji podatkowej
- **Priorytet:** 1154

## P1156: `statute_interruption_events`

- **Cel biznesowy:** Przerwanie biegu przedawnienia przez zastosowanie środka egzekucyjnego, o którym podatnik został zawiadomiony. Po przerwaniu bieg zaczyna się od nowa.
- **Przesłanki:** 
  - `input.document.enforcement_measure_applied == true`
  - Podatnik został zawiadomiony o środku egzekucyjnym
- **Rezultat:** 
  - `statute_interrupted_reset_clock: true`
  - `_warning: "Bieg przedawnienia przerwany — rozpoczyna się od nowa po zakończeniu egzekucji"`
- **Podstawa prawna:** Art. 70 § 4 Ordynacji podatkowej
- **Priorytet:** 1156

## P1158: `entrepreneur_personal_liability`

- **Cel biznesowy:** Oznaczenie pełnej, nieograniczonej odpowiedzialności osobistej całym majątkiem przedsiębiorcy JDG za zobowiązania podatkowe. Fundamentalna różnica vs spółki z o.o.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form != null` (zawsze TRUE dla JDG)
  - JDG jest osobą fizyczną
- **Rezultat:** 
  - `liability_scope: "UNLIMITED_PERSONAL_PROPERTY"`
  - `liability_includes_spouse_property: true` (jeśli wspólność majątkowa)
  - `_warning: "JDG — odpowiadasz całym majątkiem osobistym za zobowiązania podatkowe"`
- **Podstawa prawna:** Art. 26, Art. 29 Ordynacji podatkowej
- **Priorytet:** 1158

## P1160: `successor_liability`

- **Cel biznesowy:** Odpowiedzialność spadkobierców lub zarządcy sukcesyjnego za zaległości podatkowe zmarłego przedsiębiorcy JDG.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.in_succession == true`
  - Zobowiązania powstały przed śmiercią przedsiębiorcy
- **Rezultat:** 
  - `liability_transferred_to_successors: true`
  - `successor_liable_up_to_estate_value: true`
  - `_warning: "Sukcesja — spadkobiercy/zarządca odpowiadają za zobowiązania zmarłego przedsiębiorcy"`
- **Podstawa prawna:** Art. 97-98, Art. 100 Ordynacji podatkowej, Ustawa o zarządzie sukcesyjnym
- **Priorytet:** 1160

## P1162: `joint_liability_spouse`

- **Cel biznesowy:** Odpowiedzialność solidarna małżonka z majątku wspólnego za zaległości podatkowe JDG. Wyłączenie, jeśli ustrój rozdzielności majątkowej został ustanowiony PRZED powstaniem zaległości.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.married == true`
  - `input.jdg_entrepreneur.joint_property_regime == true`
  - Zaległość powstała w trakcie trwania wspólności majątkowej
- **Rezultat:** 
  - `spouse_jointly_liable_from_common_property: true`
  - `_warning: "Małżonek odpowiada solidarnie majątkiem wspólnym za zaległości podatkowe JDG"`
- **Podstawa prawna:** Art. 29 Ordynacji podatkowej
- **Priorytet:** 1162

## P1164: `late_payment_interest_calculation`

- **Cel biznesowy:** Naliczenie odsetek za zwłokę od zaległości podatkowych według stawki podstawowej (stopa lombardowa NBP + 2%, nie mniej niż 8%).
- **Przesłanki:** 
  - `input.invoice.is_paid == true`
  - `input.invoice.days_overdue > 0`
  - Płatność dotyczy zobowiązania podatkowego (VAT, PIT zaliczki)
- **Rezultat:** 
  - `interest_due_calculation_required: true`
  - `interest_rate: input.thresholds.jdg.rates.tax_interest_rate`
  - `interest_amount: kwota_zaleglosci * rate * dni / 365`
- **Podstawa prawna:** Art. 53-56 Ordynacji podatkowej
- **Priorytet:** 1164

## P1166: `penalty_interest_rate`

- **Cel biznesowy:** Zastosowanie podwyższonej stawki odsetek (150% stawki podstawowej) w przypadku ujawnienia zaległości w toku kontroli podatkowej lub celno-skarbowej bez samodzielnej korekty.
- **Przesłanki:** 
  - `input.document.detected_during_audit == true`
  - Podatnik nie złożył korekty przed kontrolą
  - Zaległość > 0
- **Rezultat:** 
  - `interest_rate_multiplier: input.thresholds.jdg.rates.tax_interest_penalty_mult` (1.5)
  - `penalty_interest: true`
  - `_warning: "Podwyższona stawka odsetek (150%) — zaległość wykryta w kontroli"`
- **Podstawa prawna:** Art. 56b Ordynacji podatkowej
- **Priorytet:** 1166

---

# CZĘŚĆ 6: REPREZENTACJA I PEŁNOMOCNICTWA — NOWY PAKIET (P1200-P1212)

★ NOWY PAKIET: `jdg.representation` ★

---

## P1200: `power_of_attorney_pps1`

- **Cel biznesowy:** Rejestracja i walidacja pełnomocnictwa szczególnego PPS-1 do konkretnej sprawy podatkowej (np. postępowanie podatkowe, kontrola).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.proxy_type == "PPS-1"`
  - Pełnomocnictwo zarejestrowane w systemie e-Urząd Skarbowy
  - Zakres: konkretna sprawa, nie ogólne
- **Rezultat:** 
  - `pps1_required: true`
  - `scope: "LIMITED_TO_SPECIFIC_CASE"`
  - `_warning: "PPS-1 — pełnomocnictwo ograniczone do jednej sprawy podatkowej"`
- **Podstawa prawna:** Art. 138e Ordynacji podatkowej
- **Priorytet:** 1200

## P1202: `general_proxy_upl1`

- **Cel biznesowy:** Wymóg zgłoszenia pełnomocnictwa ogólnego UPL-1 do podpisywania i przesyłania deklaracji elektronicznych (w tym JPK). Walidacja przed akceptacją dokumentu.
- **Przesłanki:** 
  - `input.document.declaration_signed_by_proxy == true`
  - Pełnomocnictwo UPL-1 musi być aktywne w systemie
  - Dokument JPK/PIT/VAT podpisany przez pełnomocnika
- **Rezultat:** 
  - `upl1_validation_required: true`
  - `proxy_must_be_active: true`
  - `_warning: "Dokument podpisany przez pełnomocnika — wymagane aktywne UPL-1"`
- **Podstawa prawna:** Art. 80a Ordynacji podatkowej
- **Priorytet:** 1202

## P1204: `commercial_proxy_prokura`

- **Cel biznesowy:** Uznanie umocowania prokurenta dla JDG — prokura musi być wpisana do CEIDG, aby była skuteczna.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.has_prokura == true`
  - Prokura wpisana w CEIDG
  - Dokument podpisany przez prokurenta
- **Rezultat:** 
  - `representation_valid: true`
  - `representation_type: "PROKURA"`
  - `_warning: "Prokura — upewnij się, że prokurent jest wpisany w CEIDG"`
- **Podstawa prawna:** Art. 109¹ Kodeksu Cywilnego, CEIDG
- **Priorytet:** 1204

## P1206: `attorney_authorization_scope`

- **Cel biznesowy:** Blokada działań pełnomocnika wykraczających poza zakres uprawnień określonych w UPL-1 / PPS-1 / PPO-1.
- **Przesłanki:** 
  - `input.document.action_out_of_proxy_scope == true`
  - Działanie pełnomocnika wykracza poza zakres (np. podpisanie deklaracji za okres nieobjęty pełnomocnictwem)
- **Rezultat:** 
  - `_routing: "BLOCK_AND_ALERT"`
  - `error: "Działanie poza zakresem pełnomocnictwa"`
  - `document_rejected: true`
- **Podstawa prawna:** Art. 138a Ordynacji podatkowej
- **Priorytet:** 1206

## P1208: `proxy_validity_period`

- **Cel biznesowy:** Weryfikacja czy w momencie dokonywania czynności (np. wysyłki JPK) e-pełnomocnictwo UPL-1 było wciąż aktywne i nie wygasło.
- **Przesłanki:** 
  - `input.document.declaration_signed_by_proxy == true`
  - `current_date > input.jdg_entrepreneur.proxy_expiration_date`
- **Rezultat:** 
  - `proxy_expired: true`
  - `document_rejected: true`
  - `_routing: "BLOCK_AND_ALERT"`
  - `error: "Pełnomocnictwo wygasło — dokument odrzucony"`
- **Podstawa prawna:** Art. 80a § 1 Ordynacji podatkowej
- **Priorytet:** 1208

## P1210: `proxy_revocation_effects`

- **Cel biznesowy:** Natychmiastowe zablokowanie możliwości działania przez pełnomocnika po zgłoszeniu odwołania pełnomocnictwa (formularz OPL-1).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.proxy_revoked == true`
  - Data odwołania wcześniejsza niż data czynności
- **Rezultat:** 
  - `authentication_blocked_for_proxy: true`
  - `document_rejected: true`
  - `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 80a § 2a Ordynacji podatkowej
- **Priorytet:** 1210

## P1212: `representation_tax_audit`

- **Cel biznesowy:** Wymóg ustanowienia pełnomocnictwa PPO-1 dla osoby reprezentującej JDG wyłącznie w trakcie kontroli podatkowej.
- **Przesłanki:** 
  - `input.document.audit_in_progress == true`
  - `input.document.representation_by_third_party == true`
  - Osoba reprezentująca nie jest przedsiębiorcą
- **Rezultat:** 
  - `ppo1_required: true`
  - `proxy_type_needed: "PPO-1"`
  - `_warning: "Kontrola podatkowa — wymagane pełnomocnictwo PPO-1 dla osoby reprezentującej"`
- **Podstawa prawna:** Art. 281a Ordynacji podatkowej
- **Priorytet:** 1212

---

# CZĘŚĆ 7: INTERAKCJE FORMA OPODATKOWANIA ↔ SKŁADKI (P730-P738)

★ NOWY PAKIET: `jdg.zus.interactions` ★

---

## P730: `health_contribution_rate_matrix`

- **Cel biznesowy:** Centralna reguła mapująca formę opodatkowania JDG na odpowiednią metodę naliczania składki zdrowotnej. Dynamiczne narzucanie stawki i podstawy.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form != null`
- **Rezultat — macierz mapowania:**
  
  | tax_form | health_rate | health_base | deductible |
  |----------|-------------|-------------|------------|
  | PIT_SCALE | 9% | INCOME (dochód) | NIE |
  | LINEAR | 4.9% | INCOME (dochód) | TAK (limit 12 900) |
  | LUMP_SUM | 9%*śr.wynagr. | LUMP_SUM_TIERS | NIE |
  | TAX_CARD | 9%*min.wynagr. | MINIMUM_WAGE | NIE |

- **Podstawa prawna:** Art. 81 ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 730
- **Zależności:** Wywoływana PRZED szczegółowymi regułami P720-P724

## P732: `form_change_contribution_trigger`

- **Cel biznesowy:** Automatyczne wygenerowanie alertu o konieczności przeliczenia deklaracji ZUS DRA przy zmianie formy opodatkowania od nowego roku.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form_change_date != null`
  - Zmiana dotyczy formy z inną metodą składki zdrowotnej
- **Rezultat:** 
  - `zus_dra_recalculation_alert: true`
  - `new_contribution_method: <nowa metoda z P730>`
  - `_warning: "Zmiana formy opodatkowania — zaktualizuj deklarację ZUS DRA od pierwszego miesiąca nowego roku"`
- **Podstawa prawna:** Art. 81 ust. 2 zd. 2 ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 732

## P734: `lump_sum_health_tier_lockstep`

- **Cel biznesowy:** Wymuszenie wejścia na wyższy próg składki zdrowotnej dla ryczałtowca, gdy roczny przychód przekroczy barierę 60 000 PLN lub 300 000 PLN. Konieczność dopłaty różnicy.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "LUMP_SUM"`
  - `revenue_crossed_tier == true` (przekroczono próg w trakcie roku)
- **Rezultat:** 
  - `zus_health_tier_upgraded: true`
  - `requires_zus_surcharge: true` (dopłata różnicy za cały rok)
  - `_warning: "Przekroczono próg ryczałtowej składki zdrowotnej — konieczna dopłata"`
- **Podstawa prawna:** Art. 81 ust. 2e ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 734

## P736: `tax_card_health_fixed`

- **Cel biznesowy:** Składka zdrowotna dla JDG na karcie podatkowej jest stała i wynosi 9% minimalnego wynagrodzenia (nie zależy od dochodu).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "TAX_CARD"`
- **Rezultat:** 
  - `zus_health_base: "MINIMUM_WAGE_9_PERCENT"`
  - `zus_health_amount: 0.09 * minimum_wage_gross`
  - `zus_health_deductible_from_tax: false`
- **Podstawa prawna:** Art. 81 ust. 2za ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 736

## P738: `scale_health_deduction_prohibition`

- **Cel biznesowy:** Bezwzględna blokada odliczenia składki zdrowotnej od podatku lub jako KUP przy skali podatkowej (Polski Ład — zniesienie odliczenia).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "PIT_SCALE"`
  - `input.invoice.expense_type == "ZUS_HEALTH_ENTREPRENEUR"`
- **Rezultat:** 
  - `kus_qualification: "none"`
  - `tax_deduction_prohibited: true`
  - `_warning: "Skala podatkowa — składka zdrowotna NIE podlega odliczeniu od podatku ani jako KUP"`
- **Podstawa prawna:** Polski Ład — brak art. 27b PIT (uchylony)
- **Priorytet:** 738

---

# CZĘŚĆ 8: VAT SZCZEGÓŁOWY DLA JDG (P185-P191)

---

## P185: `vat_pre_proportion_mixed`

- **Cel biznesowy:** Obliczenie pre-współczynnika (proporcji) VAT dla JDG prowadzących sprzedaż mieszaną (opodatkowaną i zwolnioną). Odliczenie tylko w proporcji do sprzedaży opodatkowanej.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.performs_mixed_sales == true`
  - `input.jdg_entrepreneur.is_vat_payer == true`
- **Rezultat:** 
  - `vat_deduction_proportion_applied: true`
  - `vat_pre_proportion: taxable_sales / total_sales`
  - `_warning: "Sprzedaż mieszana — VAT odliczany proporcjonalnie"`
- **Podstawa prawna:** Art. 90 ustawy o VAT
- **Priorytet:** 185

## P186: `vehicle_50_vat_deduction`

- **Cel biznesowy:** Ograniczenie odliczenia VAT do 50% dla wydatków związanych z pojazdami samochodowymi wykorzystywanymi w sposób mieszany (firmowo-prywatnie).
- **Przesłanki:** 
  - `input.invoice.category_code == "CAR_MIXED_USE"` lub `"CAR"`
  - `input.invoice.private_use_percent > 0` lub brak ewidencji przebiegu
- **Rezultat:** 
  - `vat_deduction_percent: input.thresholds.jdg.rates.car_vat_deduction_percent` (50%)
  - `_warning: "Samochód mieszany — ograniczenie odliczenia VAT do 50%"`
- **Podstawa prawna:** Art. 86a ustawy o VAT
- **Priorytet:** 186

## P187: `annual_vat_correction_assets`

- **Cel biznesowy:** Korekta roczna VAT dla środków trwałych nabytych przy mieszanej sprzedaży — 1/5 (ruchomości) lub 1/10 (nieruchomości) podatku w deklaracji za styczeń.
- **Przesłanki:** 
  - `is_january_declaration == true`
  - `mixed_sales_vat_adjusted == true` (sprzedaż mieszana, pre-proporcja)
  - Środek trwały nabyty w poprzednich latach
- **Rezultat:** 
  - `requires_annual_vat_correction: true`
  - `correction_fraction: "1/5"` (ruchomości) lub `"1/10"` (nieruchomości)
- **Podstawa prawna:** Art. 91 ustawy o VAT
- **Priorytet:** 187

## P188: `vat_deduction_deadline_3m`

- **Cel biznesowy:** Prawo do odliczenia VAT przez 3 kolejne okresy miesięczne (JPK_V7M) od daty powstania obowiązku podatkowego u sprzedawcy.
- **Przesłanki:** 
  - `input.invoice.direction == "PURCHASE"`
  - `input.invoice.months_since_issue <= input.thresholds.jdg.limits.vat_deduction_months` (3)
  - `input.invoice.is_vat_deducted == false`
- **Rezultat:** 
  - `vat_deduction_allowed: true`
  - `vat_deduction_window_remaining: 3 - months_since_issue`
- **Podstawa prawna:** Art. 86 ust. 11 ustawy o VAT
- **Priorytet:** 188

## P189: `bad_debt_relief_creditor`

- **Cel biznesowy:** Ulga na złe długi VAT — korekta in minus dla wierzyciela (sprzedawcy) po upływie 90 dni od terminu płatności, jeśli dłużnik nie zapłacił.
- **Przesłanki:** 
  - `input.invoice.direction == "SALE"`
  - `input.invoice.is_paid == false`
  - `input.invoice.days_overdue > input.thresholds.jdg.limits.bad_debt_days_vat` (90 dla wierzyciela)
  - Dłużnik nie jest w trakcie postępowania restrukturyzacyjnego/upadłościowego
- **Rezultat:** 
  - `vat_bad_debt_relief_creditor_active: true`
  - `vat_correction_in_minus_allowed: true`
  - `_warning: "Ulga na złe długi VAT — korekta in minus po 90 dniach braku płatności"`
- **Podstawa prawna:** Art. 89a ustawy o VAT
- **Priorytet:** 189

---

# CZĘŚĆ 9: LEASING DLA JDG — NOWY PAKIET (P860-P868)

★ NOWY PAKIET: `jdg.accounting.leasing` ★

---

## P860: `operating_lease_full_kup`

- **Cel biznesowy:** Kwalifikacja całej raty leasingu operacyjnego jako kosztu uzyskania przychodu. Warunek: umowa spełnia kryteria leasingu operacyjnego (min. 40% normatywnego okresu amortyzacji, opcja wykupu).
- **Przesłanki:** 
  - `input.invoice.expense_type == "OPERATING_LEASE"`
  - `input.invoice.lease_term_months >= 0.40 * input.invoice.asset_normative_months`
  - `input.invoice.lease_has_purchase_option == true`
- **Rezultat:** 
  - `kus_qualification: "full"`
  - `leasing_type: "OPERATING"`
  - `kup_note: "Całość raty leasingowej stanowi KUP"`
- **Podstawa prawna:** Art. 23b ustawy o PIT
- **Priorytet:** 860

## P862: `financial_lease_interest_kup`

- **Cel biznesowy:** Leasing finansowy — część kapitałowa raty = amortyzacja (środek trwały), część odsetkowa = bieżący KUP.
- **Przesłanki:** 
  - `input.invoice.expense_type == "FINANCIAL_LEASE"`
  - Umowa spełnia kryteria leasingu finansowego
- **Rezultat:** 
  - `leasing_type: "FINANCIAL"`
  - `kus_qualification: "partial"`
  - `kus_interest_only: true`
  - `requires_fixed_asset_register: true`
  - `_warning: "Leasing finansowy — KUP tylko odsetki, kapitał przez amortyzację"`
- **Podstawa prawna:** Art. 23f ustawy o PIT
- **Priorytet:** 862

## P864: `car_lease_150k_limit`

- **Cel biznesowy:** Proporcjonalne ograniczenie KUP z rat leasingu operacyjnego i finansowego dla samochodów osobowych powyżej 150 000 PLN wartości.
- **Przesłanki:** 
  - `input.invoice.category_code == "CAR_LEASE"` lub `"CAR"` + `expense_type in ["OPERATING_LEASE", "FINANCIAL_LEASE"]`
  - `input.invoice.car_value > input.thresholds.jdg.limits.car_value_kup_limit` (150 000)
- **Rezultat:** 
  - `kus_qualification: "limited_proportion"`
  - `kus_proportion: 150000 / car_value`
  - `_warning: "Samochód powyżej 150 000 PLN — KUP z rat leasingowych limitowany proporcjonalnie"`
- **Podstawa prawna:** Art. 23a pkt 47a (w zw. z art. 23 ust. 1 pkt 47a) ustawy o PIT
- **Priorytet:** 864

## P866: `consumer_lease_jdg`

- **Cel biznesowy:** Rozliczenie leasingu konsumenckiego (najem długoterminowy bez opcji wykupu) używanego częściowo do firmy — limit 20% KUP jeśli brak ewidencji przebiegu (kilometrówka).
- **Przesłanki:** 
  - `input.invoice.expense_type == "CONSUMER_LEASE"`
  - `input.invoice.private_use_percent > 0` (użytek mieszany)
  - Brak prowadzonej ewidencji przebiegu pojazdu
- **Rezultat:** 
  - `kus_percent: 20`
  - `kus_qualification: "partial"`
  - `_warning: "Leasing konsumencki użytek mieszany — KUP limitowany do 20% bez ewidencji przebiegu"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 46 ustawy o PIT
- **Priorytet:** 866

## P868: `lease_classification_test`

- **Cel biznesowy:** Test klasyfikacji umowy leasingowej — minimum 40% normatywnego okresu amortyzacji dla leasingu operacyjnego. Jeśli warunek niespełniony → leasing finansowy.
- **Przesłanki:** 
  - `input.invoice.expense_type in ["OPERATING_LEASE", "FINANCIAL_LEASE", "LEASE"]`
  - `input.invoice.lease_term_months < 0.40 * input.invoice.asset_normative_months`
- **Rezultat:** 
  - `lease_classification: "FINANCIAL"` (jeśli < 40%)
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Umowa nie spełnia wymogów leasingu operacyjnego (< 40% normatywnego okresu) — klasyfikuj jako finansowy"`
- **Podstawa prawna:** Art. 23b ust. 1 ustawy o PIT
- **Priorytet:** 868

---

# CZĘŚĆ 10: ZWOLNIENIA PODMIOTOWE I PRZEDMIOTOWE — ROZBUDOWA (P59-P63, P588)

---

## P59: `subject_exemption_startup_proportion`

- **Cel biznesowy:** Obliczenie proporcjonalnego limitu zwolnienia podmiotowego VAT dla JDG rozpoczynających działalność w trakcie roku. Limit = (dni pozostałe / 365) × 200 000 PLN.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.ceidg_entry_date > "current_year-01-01"`
  - `input.jdg_entrepreneur.is_vat_payer == false`
  - JDG rozpoczęła działalność w trakcie roku
- **Rezultat:** 
  - `vat_exemption_limit_proportional: (days_remaining / 365) * 200000`
  - `vat_exemption: "SUBJECT_PROPORTIONAL"`
  - `_warning: "Zwolnienie podmiotowe proporcjonalne — limit = (dni do końca roku / 365) × 200 000 PLN"`
- **Podstawa prawna:** Art. 113 ust. 9 ustawy o VAT
- **Priorytet:** 59

## P61: `object_exemption_pkd`

- **Cel biznesowy:** Zwolnienie przedmiotowe z VAT dla JDG wykonujących wyłącznie usługi ustawowo zwolnione (PKD: np. 66.22.Z działalność agentów ubezpieczeniowych, 86.21.Z praktyka lekarska, 85.59.B nauka języków).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.pkd_main` in lista PKD zwolnionych przedmiotowo (z thresholds)
  - `input.invoice.vat_taxable == true` (ale usługa zwolniona)
  - JDG nie zrezygnowała ze zwolnienia
- **Rezultat:** 
  - `vat_rate: "0.00"`
  - `vat_exemption: "OBJECT"`
  - `_warning: "Zwolnienie przedmiotowe VAT — usługa zwolniona na podstawie PKD"`
- **Podstawa prawna:** Art. 43 ustawy o VAT
- **Priorytet:** 61

## P62: `vat_exemption_financial`

- **Cel biznesowy:** Szczegółowe zwolnienie dla usług finansowych — udzielanie kredytów/pożyczek, pośrednictwo kredytowe, zarządzanie funduszami. Wyłączenie: doradztwo finansowe, factoring, windykacja.
- **Przesłanki:** 
  - `input.invoice.category_code == "FINANCIAL"`
  - `input.invoice.service_type != "FACTORING"` (factoring wyłączony)
  - `input.invoice.service_type != "ADVISORY"` (doradztwo wyłączone)
  - Usługa na liście zwolnień z Art. 43 VAT
- **Rezultat:** 
  - `vat_rate: "0.00"`
  - `vat_exemption: "OBJECT"`
  - `_warning: "Usługa finansowa zwolniona z VAT — wyjątek: doradztwo, factoring, windykacja"`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 37-41 ustawy o VAT
- **Priorytet:** 62

## P63: `vat_exemption_insurance`

- **Cel biznesowy:** Zwolnienie usług ubezpieczeniowych i reasekuracyjnych oraz usług pośrednictwa ubezpieczeniowego.
- **Przesłanki:** 
  - `input.invoice.category_code == "INSURANCE"`
  - Usługa pośrednictwa ubezpieczeniowego lub reasekuracyjnego
- **Rezultat:** 
  - `vat_rate: "0.00"`
  - `vat_exemption: "OBJECT"`
  - `_warning: "Usługa ubezpieczeniowa zwolniona z VAT"`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 37 ustawy o VAT
- **Priorytet:** 63

## P588: `pit_exemption_interactions`

- **Cel biznesowy:** Koordynacja zwolnień PIT — ulga dla młodych, na powrót, dla rodzin 4+ i dla pracujących emerytów dzielą WSPÓLNY limit 85 528 PLN rocznie. Nie można ich sumować.
- **Przesłanki:** 
  - Co najmniej dwie spośród ulg: YOUNG, RETURN, FAMILY_4PLUS, WORKING_SENIOR są aktywne jednocześnie
  - Suma dochodów objętych zwolnieniami > `input.thresholds.jdg.bounds.pit_young_exemption_limit` (85 528)
- **Rezultat:** 
  - `shared_exemption_limit_cap_applied: 85528`
  - `exemption_interaction: "SHARED_CAP"`
  - `_warning: "Zwolnienia PIT współdzielą limit 85 528 PLN — nie sumują się"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 148, 152, 153, 154 ustawy o PIT
- **Priorytet:** 588

---

# PODSUMOWANIE ROZSZERZENIA

## Statystyki ogólne

| Metryka | Przed rozszerzeniem | Po rozszerzeniu | Przyrost |
|---------|:-------------------:|:---------------:|:--------:|
| **Pakiety JDG** | 23 | 28 | +5 nowych |
| **Reguły łącznie** | ~145 | ~210 | +65 |
| **Domeny prawne** | 30+ | 45+ | +15 |
| **Podstawy prawne** | 70+ | 100+ | +30 |
| **Pola input JDG** | ~80 | ~105 | +25 |
| **Thresholds** | ~65 | ~85 | +20 |

## Nowe pakiety

| Pakiet | Reguły | Priorytety |
|--------|:------:|------------|
| `jdg.pit.tax_form_change` | 7 | P590-P596 |
| `jdg.corrections` | 8 | P1100-P1114 |
| `jdg.statute_liability` | 9 | P1150-P1166 |
| `jdg.representation` | 7 | P1200-P1212 |
| `jdg.zus.interactions` | 5 | P730-P738 |
| `jdg.accounting.leasing` | 5 | P860-P868 |
| `jdg.vat.declarations` | 1 | P232 |

## Rozbudowane pakiety

| Pakiet | Nowe reguły | Priorytety |
|--------|:-----------:|------------|
| `jdg.allowances.*` | 9 | P601-P609 |
| `jdg.crossborder` | 8 | P43-P49, P190-P191 |
| `jdg.vat.deduction` | 5 | P185-P189 |
| `jdg.vat.exemptions` | 4 | P59-P63 |
| `jdg.pit.advances` | 1 | P615 |
| `jdg.pit.exemptions` | 1 | P588 |

---

> **Następny krok:** Aktualizacja `22_JDG_ENTERPRISE_PLAN.md` — wstawienie cross-referencji do niniejszego dokumentu.  
> **Powiązane dokumenty:** `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` (plan bazowy JDG), `Plan OPA/DocsJDG` (źródła prawne), `Plan OPA/20_MASTER_RULES_REFERENCE.md` (spis 240 reguł ogólnych)
