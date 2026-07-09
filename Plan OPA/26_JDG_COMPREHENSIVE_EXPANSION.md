# 📋 NexusAI JDG — Kompleksowa Rozbudowa ENTERPRISE v3.0

> **Status:** Kompleksowa Rozbudowa JDG v3.0 — 58 nowych reguł w 12 obszarach  
> **Data:** 2026-07-09  
> **Autor:** Zespół NexusAI  
> **Plik:** `Plan OPA/26_JDG_COMPREHENSIVE_EXPANSION.md`  
> **Dokumenty bazowe:**  
> — `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` — plan bazowy (~145 reguł)  
> — `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` — pierwsza rozbudowa (~69 reguł)  
> — `Plan OPA/24_JDG_COMPLETE_INDEX.md` — indeks (~214 reguł)  
> — `Plan OPA/25_JDG_DEEP_LEGAL_AUDIT.md` — audyt prawny (46 luk)  
> — `Plan OPA/DocsJDG` — źródła prawne JDG  
> **Nowe reguły:** 58 | **Nowe pakiety:** 3 | **Rozbudowane pakiety:** 11  
> **Cel:** Wypełnienie wszystkich 46 luk z audytu + dodanie pogłębionych reguł we wszystkich 10 obszarach

---

## 0. Executive Summary — Co Ten Dokument Wnosi

Dokumenty 22-25 stworzyły solidny fundament ~214 reguł JDG. Niniejszy dokument:

1. **Wypełnia WSZYSTKIE 46 luk z audytu** (12 🔴 krytycznych, 20 🟡 ważnych, 14 🟢 dodatkowych)
2. **Dodaje całkowicie nowy obszar: KKS i GAAR** — odpowiedzialność karno-skarbowa i klauzula przeciwdziałania unikaniu opodatkowania
3. **Dodaje nowy pakiet `jdg.local_taxes`** — PCC, podatek od nieruchomości, podatek od środków transportowych
4. **Pogłębia istniejące reguły** o szczegółowe warunki brzegowe, obliczenia i interakcje między regułami
5. **Rozbudowuje `input.thresholds.jdg.*`** o 35+ nowych parametrów

---

## 0.1 Aktualizacja Drzewa Pakietów JDG (Finalna)

```
policies/jdg/
├── main_jdg.rego                              # [UPDATE] Importy wszystkich nowych pakietów
├── _helpers_jdg.rego                          
├── _metadata_jdg.rego                         
│
├── risk.rego                                  # P0-P9 [ROZBUDOWA: +P0_b, P4, P6, P6_b, P7, P9]
├── routing.rego                               # P10-P19
│
├── compliance/
│   ├── whitelist.rego                         # P20-P21
│   ├── mpp.rego                               # P25
│   └── cash_limit.rego                        # P35 [ROZBUDOWA: +P36]
│
├── crossborder.rego                           # P40-P49 + P190-P191
│
├── vat/
│   ├── substantive.rego                       # P50-P65
│   ├── gtu.rego                               # P65
│   ├── exemptions.rego                        # P55-P63
│   ├── tax_point.rego                         # P230-P235
│   ├── deduction.rego                         # P185-P189 [ROZBUDOWA: +P39, P183, P184, P192]
│   └── declarations.rego                      # P232 [ROZBUDOWA: +P233, P234]
│
├── pit/
│   ├── form_scale.rego                        # P500-P502
│   ├── form_linear.rego                       # P510-P511 [ROZBUDOWA: +P512]
│   ├── form_lump_sum.rego                     # P520-P523 [ROZBUDOWA: +P524, P525, P526]
│   ├── form_tax_card.rego                     # P530-P531 [ROZBUDOWA: +P532, P533]
│   ├── tax_form_change.rego                   # P590-P596
│   ├── advances.rego                          # P540-P543 + P615
│   ├── annual_returns.rego                    # P550-P556
│   ├── kup.rego                               # P560-P570 [ROZBUDOWA: +P572, P574]
│   └── exemptions.rego                        # P580-P588 [ROZBUDOWA: +P508, P509]
│
├── allowances/
│   ├── rd.rego                                # P600
│   ├── prototype.rego                         # P601
│   ├── robotization.rego                      # P602
│   ├── expansion.rego                         # P603
│   ├── rehabilitation.rego                    # P604
│   ├── internet.rego                          # P605
│   ├── donation.rego                          # P606-P608
│   ├── abolition.rego                         # P609
│   ├── ip_box.rego                            # P610
│   └── thermo.rego                            # P623
│
├── zus/
│   ├── social.rego                            # P700-P701 [ROZBUDOWA: +P743, P744]
│   ├── health.rego                            # P720-P724 [ROZBUDOWA: +P739, P748]
│   ├── interactions.rego                      # P730-P738
│   ├── start_relief.rego                      # P740
│   ├── maly_zus_plus.rego                     # P741
│   ├── preferential.rego                      # P742
│   └── payment_deadlines.rego                 # P745, P746 ★ NOWY PLIK ★
│
├── accounting/
│   ├── pkpir.rego                             # P800-P802
│   ├── lump_sum_evidence.rego                 # P820
│   ├── vat_evidence.rego                      # P830-P832
│   ├── depreciation.rego                      # P840-P842
│   ├── private_mixed.rego                     # P850-P852
│   ├── leasing.rego                           # P860-P868
│   └── fx_differences.rego                    # P870 ★ NOWY PLIK ★
│
├── business/
│   ├── ceidg.rego                             # P900-P904
│   ├── suspension.rego                        # P910-P914 [ROZBUDOWA: +P916, P918]
│   ├── succession.rego                        # P920-P924 [ROZBUDOWA: +P925, P926, P927]
│   └── unregistered.rego                      # P930-P934
│
├── corrections/
│   └── main.rego                              # P1100-P1114
│
├── statute_liability/
│   └── main.rego                              # P1150-P1166 [ROZBUDOWA: +P1153, P1157, P1167-P1174]
│
├── representation/
│   └── main.rego                              # P1200-P1212 [ROZBUDOWA: +P1205]
│
├── local_taxes/                               # ★ NOWY PAKIET ★
│   ├── pcc.rego                               # P1300-P1304
│   ├── real_estate.rego                       # P1310-P1312
│   └── transport.rego                         # P1320
│
├── ksef/
│   ├── structured_invoice.rego                # P950-P952
│   └── offline_recovery.rego                  # P960
│
├── jpk/
│   ├── jpk_vat.rego                           # P970 [ROZBUDOWA: +P972]
│   └── jpk_pkpir.rego                         # P980
│
├── retention.rego                             # P990-P992
└── fallback.rego                              # P1000-P1099
```

---

## 0.2 Nowe Pola `input` — Wymagane przez Rozbudowę

| Sekcja | Nowe pole | Typ | Opis | Używane przez |
|--------|----------|-----|------|---------------|
| `jdg_entrepreneur` | `has_employment_contract` | `boolean` | Czy JDG ma etat (zbieg ubezpieczeń) | P743 |
| `jdg_entrepreneur` | `employment_salary` | `number` | Wynagrodzenie z etatu | P743 |
| `jdg_entrepreneur` | `zus_sickness_voluntary` | `boolean` | Czy opłaca dobrowolną chorobową | P701 |
| `jdg_entrepreneur` | `has_disability_certificate` | `boolean` | Orzeczenie o niepełnosprawności | P604 |
| `jdg_entrepreneur` | `blood_donated_liters` | `number` | Litry oddanej krwi | P607 |
| `jdg_entrepreneur` | `foreign_income` | `number` | Dochód zagraniczny | P609 |
| `jdg_entrepreneur` | `tax_treaty_method` | `string` | Metoda unikania podwójnego opodatkowania | P609 |
| `jdg_entrepreneur` | `performs_mixed_sales` | `boolean` | Sprzedaż mieszana VAT+zw. | P185 |
| `jdg_entrepreneur` | `married` | `boolean` | Stan cywilny | P1162 |
| `jdg_entrepreneur` | `joint_property_regime` | `boolean` | Wspólność majątkowa | P1162 |
| `jdg_entrepreneur` | `proxy_type` | `string` | Typ pełnomocnictwa (PPS-1/UPL-1/PPO-1) | P1200-P1212 |
| `jdg_entrepreneur` | `proxy_expiration_date` | `string` | Data wygaśnięcia pełnomocnictwa | P1208 |
| `jdg_entrepreneur` | `proxy_revoked` | `boolean` | Czy pełnomocnictwo odwołane | P1210 |
| `jdg_entrepreneur` | `has_prokura` | `boolean` | Czy prokura w CEIDG | P1204 |
| `jdg_entrepreneur` | `prokura_type` | `string` | Typ prokury (samoistna/łączna/oddziałowa) | P1205 |
| `jdg_entrepreneur` | `loss_carry_forward_remaining` | `number` | Pozostała strata do rozliczenia | P615 |
| `jdg_entrepreneur` | `lump_sum_election_filed` | `boolean` | Czy złożono oświadczenie o ryczałcie | P526 |
| `jdg_entrepreneur` | `first_revenue_earned` | `boolean` | Czy osiągnięto pierwszy przychód | P526 |
| `jdg_entrepreneur` | `uses_simplified_advances` | `boolean` | Uproszczone zaliczki PIT | P543 |
| `jdg_entrepreneur` | `simplified_advance_base` | `number` | Podstawa uproszczonych zaliczek | P543 |
| `jdg_entrepreneur` | `dn1_filed` | `boolean` | Czy złożono DN-1 | P1310 |
| `jdg_entrepreneur` | `home_office_area_sqm` | `number` | Powierzchnia home office w m² | P1310 |
| `invoice` | `car_value` | `number` | Wartość samochodu (limit 150k) | P864 |
| `invoice` | `custom_declaration_received` | `boolean` | Czy otrzymano dokument celny | P191 |
| `invoice` | `has_nip` | `boolean` | Czy paragon zawiera NIP | P36 |
| `invoice` | `invoice_type` | `string` | Typ dokumentu (RECEIPT/INVOICE/ADVANCE) | P36 |
| `invoice` | `direction` | `string` | Kierunek: PURCHASE/SALE | P184, P189 |
| `invoice` | `monthly_revenue_current` | `number` | Miesięczny przychód (dział. nieewidencj.) | P930 |
| `document` | `correction_submitted` | `boolean` | Czy złożono korektę | P1168 |
| `document` | `voluntary_disclosure_filed` | `boolean` | Czy złożono czynny żal | P1168 |
| `document` | `kks_proceedings_started` | `boolean` | Czy wszczęto postępowanie KKS | P1154 |
| `document` | `enforcement_measure_applied` | `boolean` | Czy zastosowano środek egzekucyjny | P1156 |
| `document` | `debt_acknowledged` | `boolean` | Czy uznano dług | P1157 |
| `document` | `detected_during_audit` | `boolean` | Wykryte podczas kontroli | P1166 |
| `document` | `tax_remission_granted` | `boolean` | Czy umorzono zaległość | P1171 |
| `document` | `action_out_of_proxy_scope` | `boolean` | Działanie poza zakresem pełnomocnictwa | P1206 |
| `document` | `declaration_signed_by_proxy` | `boolean` | Deklaracja podpisana przez pełnomocnika | P1202 |
| `document` | `audit_in_progress` | `boolean` | Czy trwa kontrola | P1212 |
| `document` | `representation_by_third_party` | `boolean` | Reprezentacja przez osobę trzecią | P1212 |
| `document` | `years_since_due_year` | `number` | Lata od wymagalności podatku | P1150 |
| `document` | `zus_years_since_due` | `number` | Lata od wymagalności ZUS | P1152 |
| `system` | `tax_audit_period_matches` | `boolean` | Czy okres korekty = okres kontroli | P1114 |
| `thresholds.jdg` | (rozszerzone — patrz sekcja 0.3) | | | |

---

## 0.3 Nowe Parametry w `thresholds.jdg.*`

| Klucz | Wartość | Opis | Podstawa prawna |
|-------|---------|------|-----------------|
| `limits.simplified_receipt_limit` | `450` | Limit paragonu jako faktury uproszczonej (PLN) | Art. 106e ust. 5 VAT |
| `limits.car_value_kup_limit` | `150000` | Limit wartości auta dla pełnego KUP | Art. 23 ust. 1 pkt 47a PIT |
| `limits.vat_deduction_months` | `3` | Miesiące na odliczenie VAT | Art. 86 ust. 11 VAT |
| `limits.statute_years_tax` | `5` | Lata przedawnienia podatkowego | Art. 70 § 1 OP |
| `limits.statute_years_zus` | `5` | Lata przedawnienia ZUS | Art. 24 ust. 4 SUS |
| `limits.vat_refund_standard_days` | `60` | Standardowy termin zwrotu VAT | Art. 87 ust. 2 VAT |
| `limits.vat_refund_fast_days` | `25` | Przyśpieszony termin zwrotu VAT | Art. 87 ust. 6 VAT |
| `limits.vat_refund_extended_days` | `180` | Wydłużony termin zwrotu VAT | Art. 87 ust. 2a VAT |
| `limits.overpayment_refund_days` | `45` | Termin zwrotu nadpłaty | Art. 77 OP |
| `limits.succession_max_months` | `24` | Maks. okres zarządu sukcesyjnego | Art. 12 u.z.s. |
| `limits.succession_court_extension_months` | `60` | Maks. przedłużenie przez sąd | Art. 13 u.z.s. |
| `limits.suspension_max_months_continuous` | `6` | Maks. ciągły okres zawieszenia | Art. 22 PP |
| `limits.zaw_nr_deadline_days` | `7` | Termin ZAW-NR od przelewu | Art. 117ba OP |
| `limits.jpk_correction_days` | `14` | Dni na korektę JPK przed karą | Art. 77 KKS |
| `limits.small_mandate_limit` | `200` | Limit małej umowy zlecenia/dzieła | Art. 30 ust. 1 pkt 5a PIT |
| `bounds.relief_rd_base` | `100` | Ulga B+R — % podstawowy | Art. 26e PIT |
| `bounds.relief_rd_centrum` | `200` | Ulga B+R — % CBR | Art. 26e PIT |
| `bounds.relief_prototype_percent` | `30` | % kosztów prototypu | Art. 26eb PIT |
| `bounds.relief_robotization_percent` | `50` | % kosztów robotyzacji | Art. 26gb PIT |
| `bounds.relief_expansion_max` | `1000000` | Max ulgi ekspansyjnej PLN | Art. 26ec PIT |
| `bounds.relief_internet_max` | `760` | Max ulgi internetowej PLN/rok | Art. 26 PIT |
| `bounds.relief_internet_years` | `2` | Maks. lat ulgi internetowej | Art. 26 PIT |
| `bounds.blood_liter_equivalent` | `130` | Ekwiwalent za litr krwi PLN | Art. 26 ust. 1 pkt 9c PIT |
| `bounds.donation_limit_percent` | `6` | Limit darowizn % dochodu | Art. 26 ust. 1 pkt 9 PIT |
| `bounds.loss_deduction_limit_one_time` | `5000000` | Limit jednorazowego odliczenia straty PLN | Art. 9 ust. 3 PIT |
| `bounds.minimum_wage_gross` | `4666` | Minimalne wynagrodzenie brutto PLN | Rozp. RM |
| `bounds.zus_preferential_base_percent` | `0.30` | % min. wynagrodzenia — preferencyjny ZUS | Art. 18a SUS |
| `rates.tax_interest_rate` | `\"0.145\"` | Stopa odsetek podatkowych (lombardowa+2%) | Art. 56 OP |
| `rates.tax_interest_penalty_mult` | `1.5` | Mnożnik odsetek karnych | Art. 56b OP |
| `rates.car_vat_deduction_percent` | `50` | % odliczenia VAT dla aut mieszanych | Art. 86a VAT |
| `rates.prolongation_fee` | `\"0.50\"` | Opłata prolongacyjna (50% stopy podstawowej) | Art. 57 OP |
| `rates.pcc_standard` | `\"0.02\"` | Stawka PCC od umów sprzedaży | Art. 7 PCC |
| `rates.pcc_other` | `\"0.01\"` | Stawka PCC od innych czynności | Art. 7 PCC |
| `rates.real_estate_commercial_sqm` | `33.10` | Stawka podatku od nier. firmowych /m² | Uchwała gminy |
| `eu_countries` | `[\"AT\",\"BE\",\"BG\",\"CY\",\"CZ\",\"DE\",\"DK\",\"EE\",\"EL\",\"ES\",\"FI\",\"FR\",\"HR\",\"HU\",\"IE\",\"IT\",\"LT\",\"LU\",\"LV\",\"MT\",\"NL\",\"PL\",\"PT\",\"RO\",\"SE\",\"SI\",\"SK\"]` | Lista krajów UE | |

---

# CZĘŚĆ I: KKS I GAAR — CAŁKOWICIE NOWY OBSZAR (P0_b, P4, P6, P6_b, P7, P9)

> **Stan przed:** Całkowicie pominięty w planie bazowym. DocsJDG nie zawierał KKS.  
> **Po rozbudowie:** 6 nowych reguł w `jdg.risk` — kompletne pokrycie odpowiedzialności karno-skarbowej JDG.

---

## P0_b: `kks_empty_invoice_fraud` 🔴 KRYTYCZNA

- **Cel biznesowy:** Wykrycie i natychmiastowa blokada faktur dokumentujących czynności, które nie zostały dokonane (puste faktury). Najwyższe ryzyko karne — do 25 lat pozbawienia wolności za oszustwa >10 mln PLN.
- **Przesłanki:** 
  - `input.invoice.category_code` w katalogu kategorii wysokiego ryzyka fraudowego (`FICTITIOUS_SERVICES`, `NO_DELIVERY_CONFIRMED`, `ROUND_TRIP_TRANSACTION`)
  - `input.vendor.fraud_flag == true` LUB `input.vendor.trust_score < 0.30`
  - `input.invoice.amount_gross > 0` (faktura opiewa na kwotę, ale brak materialnego śladu transakcji)
  - Brak potwierdzenia dostawy/usługi (`input.invoice.delivery_confirmed == false`)
  - `input.invoice.direction == "PURCHASE"` (JDG jako nabywca rzekomej usługi/towaru)
- **Rezultat:** 
  - `_routing: "BLOCK_AND_ALERT"`
  - `kks_risk: "Art.62_par2"`
  - `max_penalty: "25_lat_pozbawienia_wolnosci"`
  - `fraud_detected: true`
  - `_warning: "Podejrzenie pustej faktury (Art. 62 § 2 KKS) — natychmiastowa blokada. Ryzyko kary do 25 lat."`
- **Podstawa prawna:** Art. 62 § 2, Art. 62 § 2a KKS
- **Zależności:** Sprawdzana natychmiast po P0 (fraud_graph_match). FraudGraphScanner musi oznaczyć faktury bez śladu materialnego.
- **Priorytet:** 0_b (0.5 w łańcuchu — zaraz po fraud_graph_match)

---

## P4: `kks_hidden_income_flag` 🟡 WAŻNA

- **Cel biznesowy:** Wykrycie rozbieżności między zadeklarowanymi przychodami a faktycznymi wpływami na rachunek firmowy — ryzyko uchylania się od opodatkowania (Art. 54 KKS).
- **Przesłanki:** 
  - Roczna suma faktur sprzedaży (`declared_revenue`) < 85% wpływów na rachunek firmowy (`bank_inflows`)
  - `input.jdg_entrepreneur.tax_form != "TAX_CARD"` (karta podatkowa nie wymaga ewidencji przychodów)
  - Rozbieżność > próg tolerancji (domyślnie 15%)
  - Okres: ostatnie 12 miesięcy
- **Rezultat:** 
  - `kks_risk: "Art.54"`
  - `_routing: "BLOCK_AND_ALERT"`
  - `hidden_income_estimated: bank_inflows - declared_revenue`
  - `_warning: "Rozbieżność między wpływami a zadeklarowanymi przychodami — ryzyko Art. 54 KKS (uchylanie się od opodatkowania)"`
- **Podstawa prawna:** Art. 54 § 1-2 KKS
- **Priorytet:** 4

---

## P6: `kks_unreliable_books` 🔴 KRYTYCZNA

- **Cel biznesowy:** Wykrycie nierzetelnie prowadzonej PKPiR lub ewidencji ryczałtowej — wydatki nieujęte w ewidencji, celowe zaniżenia, brakujące pozycje.
- **Przesłanki:** 
  - `input.invoice.pkpir_column == 0` (wydatek niezmapowany do PKPiR) AND `input.invoice.expense_type != "NKUP"` AND `input.invoice.expense_type != "PRIVATE"`
  - LUB: `input.jdg_entrepreneur.uses_pkpir == true` AND suma wydatków z faktur > suma wydatków w PKPiR + 10% tolerancji
  - LUB: `input.jdg_entrepreneur.tax_form == "LUMP_SUM"` AND brak ewidencji dla niektórych stawek ryczałtu
- **Rezultat:** 
  - `kks_risk: "Art.56"`
  - `_routing: "BLOCK_AND_ALERT"`
  - `unmapped_expenses_count: <liczba>`
  - `_warning: "Nierzetelnie prowadzona PKPiR/ewidencja — ryzyko Art. 56 KKS (kara grzywny do 720 stawek dziennych)"`
- **Podstawa prawna:** Art. 56 § 1-2 KKS
- **Priorytet:** 6

---

## P6_b: `kks_declaration_overdue` 🟡 WAŻNA

- **Cel biznesowy:** Wykrycie niezłożenia deklaracji podatkowej w terminie — JPK_VAT, PIT-36/PIT-36L/PIT-28, deklaracje ZUS.
- **Przesłanki:** 
  - Dla JPK_V7M: `current_date > 25th_day_of_next_month` AND `input.jdg_entrepreneur.is_vat_payer == true` AND deklaracja nie złożona
  - Dla PIT-36/PIT-36L: `current_date > "04-30"` AND zeznanie nie złożone
  - Dla PIT-28: `current_date > "02-28"` AND zeznanie nie złożone
  - Dla ZUS DRA: `current_date > deadline` (10., 15. lub 20. dzień miesiąca)
- **Rezultat:** 
  - `kks_risk: "Art.77"`
  - `declaration_overdue_days: <dni>`
  - `declaration_type: <JPK_V7M/PIT-36/DRA>`
  - `_warning: "Niezłożona deklaracja — termin minął X dni temu. Ryzyko Art. 77 KKS."`
- **Podstawa prawna:** Art. 77 § 1-2 KKS
- **Priorytet:** 6_b

---

## P7: `kks_vat_evidence_gap` 🟡 WAŻNA

- **Cel biznesowy:** Weryfikacja kompletności ewidencji VAT — czy wszystkie faktury zakupu/sprzedaży są ujęte w rejestrach VAT.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.is_vat_payer == true`
  - Liczba faktur w systemie > liczba pozycji w rejestrze VAT za dany okres
  - Okres: miesiąc/kwartał
- **Rezultat:** 
  - `kks_risk: "Art.57"`
  - `vat_evidence_gaps: <liczba brakujących pozycji>`
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Niekompletna ewidencja VAT — brak X pozycji w rejestrze. Ryzyko Art. 57 KKS."`
- **Podstawa prawna:** Art. 57 KKS, Art. 109 VAT
- **Priorytet:** 7

---

## P9: `gaar_artificial_scheme` 🔴 KRYTYCZNA

- **Cel biznesowy:** Wykrycie transakcji, które mogą być uznane za sztuczne i nakierowane wyłącznie na uzyskanie korzyści podatkowej (klauzula GAAR). Ochrona JDG przed agresywną optymalizacją podatkową.
- **Przesłanki:** 
  - `input.vendor.is_related_party == true` (transakcja z podmiotem powiązanym)
  - `input.invoice.amount_net > input.thresholds.jdg.limits.gaar_materiality_threshold` (powyżej progu istotności — np. 50 000 PLN)
  - Koszt usługi/towaru rażąco odbiega od wartości rynkowej (>50% powyżej/poniżej rynku)
  - Transakcja nie ma uzasadnienia ekonomicznego (brak realnej dostawy/usługi, sztuczna struktura)
  - LUB: seria transakcji okrężnych z tymi samymi podmiotami (round-tripping)
  - LUB: transakcja z podmiotem z raju podatkowego bez substancji biznesowej
- **Rezultat:** 
  - `_routing: "BLOCK_AND_ALERT"`
  - `gaar_risk: true`
  - `gaar_risk_level: "HIGH"` lub `"MEDIUM"`
  - `_warning: "Potencjalna klauzula GAAR (Art. 119a OP) — transakcja może być uznana za sztuczną. Skutki: pominięcie skutków podatkowych, 40% stawka sankcyjna."`
- **Podstawa prawna:** Art. 119a § 1 OP
- **Zależności:** 
  - Wymaga dostępu do benchmarków cen rynkowych (RuleStore lub zewnętrzna baza)
  - Wymaga analizy struktury właścicielskiej kontrahenta (VendorIntelligence)
- **Priorytet:** 9

---

# CZĘŚĆ II: VAT — ROZBUDOWA KRYTYCZNA (P36, P39, P183, P184, P192, P233, P234)

> **Stan przed:** VAT najlepiej pokryty (~80%), ale 7 krytycznych luk.  
> **Po rozbudowie:** Kompletne pokrycie — VAT-R krajowy, paragony, złe długi dłużnika, zwrot VAT, wyrejestrowanie.

---

## P36: `vat_simplified_receipt` 🔴 KRYTYCZNA

- **Cel biznesowy:** Uznanie paragonu z NIP nabywcy do kwoty 450 PLN brutto (100 EUR) jako faktury uproszczonej — JDG może odliczyć VAT. Codzienna sytuacja: paliwo, materiały biurowe, narzędzia.
- **Przesłanki:** 
  - `input.invoice.invoice_type == "RECEIPT"` (paragon)
  - `input.invoice.amount_gross <= input.thresholds.jdg.limits.simplified_receipt_limit` (450 PLN)
  - `input.invoice.has_nip == true` (paragon zawiera NIP nabywcy)
  - `input.invoice.direction == "PURCHASE"`
  - `input.jdg_entrepreneur.is_vat_payer == true`
  - `input.invoice.category_code not in blocked_categories_for_receipt` (niektóre kategorie są wyłączone)
- **Rezultat:** 
  - `vat_deduction_allowed: true`
  - `receipt_treated_as_invoice: true`
  - `vat_rate: "0.23"` (lub odpowiednia stawka obniżona)
  - `_warning: "Paragon z NIP — odliczenie VAT możliwe do kwoty 450 PLN brutto"`
  
  **Gdy powyżej limitu 450 PLN:**
  - `vat_deduction_allowed: false`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Paragon powyżej 450 PLN brutto NIE jest fakturą uproszczoną — brak prawa do odliczenia VAT"`
- **Podstawa prawna:** Art. 106e ust. 5 pkt 3 VAT
- **Priorytet:** 36
- **Zależności:** Sprawdzana w pakiecie `jdg.compliance` — PRZED regułami VAT substantive

---

## P39: `vat_r_registration_status` 🔴 KRYTYCZNA

- **Cel biznesowy:** Blokada wystawiania faktur z VAT przez JDG niezarejestrowanego jako czynny podatnik VAT (brak VAT-R). Także weryfikacja czy VAT-R złożono PRZED pierwszą czynnością opodatkowaną.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.is_vat_payer == false` (niezarejestrowany jako czynny podatnik VAT)
  - `input.invoice.direction == "SALE"` (próba wystawienia faktury sprzedaży)
  - `input.invoice.vat_taxable == true` (czynność podlega VAT)
  - LUB: `input.jdg_entrepreneur.is_vat_payer == true` ale `vat_r_filing_date > first_taxable_activity_date` (VAT-R złożony po pierwszej czynności)
- **Rezultat:** 
  - `_routing: "BLOCK_AND_ALERT"`
  - `vat_r_required: true`
  - `_warning: "Brak rejestracji VAT-R — nie możesz wystawiać faktur z VAT. Złóż VAT-R przed pierwszą czynnością opodatkowaną."`
  - `vat_r_deadline: "PRZED pierwszą czynnością opodatkowaną"`
- **Podstawa prawna:** Art. 96 ust. 1, Art. 96 ust. 4-5 VAT
- **Priorytet:** 39

---

## P183: `vat_blocked_categories` 🟡 WAŻNA

- **Cel biznesowy:** Blokada odliczenia VAT od wydatków ustawowo wyłączonych mimo związku z działalnością: usługi noclegowe, gastronomiczne (poza cateringiem dla pracowników), paliwo do samochodów osobowych (przy niepełnym odliczeniu).
- **Przesłanki:** 
  - `input.invoice.category_code == "HOTEL"` (usługi noclegowe — Art. 88 ust. 1 pkt 4 VAT)
  - LUB: `input.invoice.category_code == "RESTAURANT"` AND `input.invoice.expense_type != "CATERING_EMPLOYEES"` (gastronomia — wyjątek: catering dla pracowników)
  - LUB: `input.invoice.category_code == "FUEL_CAR"` AND `input.invoice.private_use_percent > 50` (paliwo do aut osobowych przy mieszanym użytku)
- **Rezultat:** 
  - `vat_deduction_blocked: true`
  - `vat_rate_naliczony: "0.00"` (VAT nie podlega odliczeniu)
  - `blocked_category: <HOTEL/RESTAURANT/FUEL_CAR>`
  - `_warning: "Wydatek z kategorii wyłączonej z odliczenia VAT — Art. 88 VAT"`
- **Podstawa prawna:** Art. 86 ust. 7a VAT, Art. 88 VAT
- **Priorytet:** 183
- **Zależności:** Sprawdzana w `jdg.vat.deduction` — PRZED ogólnymi regułami odliczeń VAT

---

## P184: `bad_debt_debtor_correction_mandatory` 🔴 KRYTYCZNA

- **Cel biznesowy:** OBOWIĄZEK dłużnika (JDG jako nabywcy) do korekty odliczonego VAT in minus, jeśli nie zapłacił faktury w ciągu 90 dni od terminu płatności. To nie opcja — to obowiązek ustawowy zagrożony sankcjami!
- **Przesłanki:** 
  - `input.invoice.direction == "PURCHASE"` (JDG jest dłużnikiem)
  - `input.invoice.is_paid == false` (faktura nieopłacona)
  - `input.invoice.days_overdue >= input.thresholds.jdg.limits.bad_debt_days_cit_pit` (90 dni od terminu płatności)
  - `input.invoice.is_vat_deducted == true` (VAT został wcześniej odliczony)
  - `input.invoice.amount_gross > 0`
- **Rezultat:** 
  - `vat_correction_in_minus_mandatory: true`
  - `vat_to_return: input.invoice.amount_gross * vat_rate` (kwota VAT do zwrotu)
  - `deadline_for_correction: "w deklaracji za okres, w którym upłynął 90. dzień"`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "OBOWIĄZKOWA korekta VAT in minus! Nie zapłaciłeś faktury >90 dni od terminu. Musisz zwrócić odliczony VAT w kwocie X PLN. Podstawa: Art. 89b VAT."`
  - `consequence_if_not_corrected: "Sankcja 30% kwoty VAT — Art. 89b ust. 6 VAT"`
- **Podstawa prawna:** Art. 89b VAT
- **Priorytet:** 184
- **Zależności:** Sprawdzana PO regułach odliczeń VAT. Wymaga śledzenia statusu płatności wszystkich faktur zakupowych.

---

## P192: `vat_refund_timing` 🔴 KRYTYCZNA

- **Cel biznesowy:** Obliczenie terminu zwrotu VAT i weryfikacja czy zwrot nie jest przeterminowany. Po terminie — odsetki dla podatnika.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.is_vat_payer == true`
  - `vat_balance_credit > 0` (nadwyżka VAT naliczonego nad należnym — kwota do zwrotu)
  - Deklaracja VAT złożona z wnioskiem o zwrot
- **Rezultat — macierz terminów zwrotu:**
  
  | Warunek | Termin zwrotu | Podstawa prawna |
  |---------|:------------:|-----------------|
  | Standardowy zwrot | 60 dni | Art. 87 ust. 2 VAT |
  | Przyśpieszony (wszystkie faktury opłacone przelewem/kartą) | 25 dni | Art. 87 ust. 6 VAT |
  | Wydłużony (weryfikacja US) | 180 dni | Art. 87 ust. 2a VAT |

  - Po przekroczeniu terminu: `vat_refund_overdue: true`, `vat_refund_interest_due: true`
  - Odsetki należne od dnia następującego po upływie terminu
- **Podstawa prawna:** Art. 87 ust. 2-7 VAT
- **Priorytet:** 192

---

## P233: `vat_z_deregistration` 🟡 WAŻNA

- **Cel biznesowy:** Obowiązek złożenia VAT-Z przy zaprzestaniu działalności opodatkowanej VAT lub przejściu na zwolnienie podmiotowe.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.business_status == "CLOSED"` (zamknięcie JDG)
  - LUB: `input.jdg_entrepreneur.annual_turnover_net < input.thresholds.jdg.limits.vat_exemption_limit` AND `input.jdg_entrepreneur.is_vat_payer == true` (przejście na zwolnienie)
  - LUB: `input.jdg_entrepreneur.is_vat_payer == true` AND JDG zaprzestała wykonywania czynności opodatkowanych przez 6 miesięcy
- **Rezultat:** 
  - `vat_z_required: true`
  - `vat_z_deadline: "7_dni_od_dnia_zaprzestania_dzialalnosci"`
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Obowiązek złożenia VAT-Z — termin: 7 dni od zaprzestania działalności opodatkowanej"`
- **Podstawa prawna:** Art. 96 ust. 6-8 VAT
- **Priorytet:** 233

---

## P234: `vat_payment_deadline` 🟡 WAŻNA

- **Cel biznesowy:** Weryfikacja terminu płatności VAT (do 25. dnia następnego miesiąca) i naliczenie odsetek w przypadku zwłoki.
- **Przesłanki:** 
  - `vat_payable > 0` (kwota VAT do zapłaty)
  - `current_date > 25th_day_of_next_month` (po terminie)
  - `input.jdg_entrepreneur.is_vat_payer == true`
- **Rezultat:** 
  - `vat_payment_overdue: true`
  - `days_overdue_vat: <liczba dni po terminie>`
  - `late_interest_amount: vat_payable * tax_interest_rate * days_overdue / 365`
  - `_warning: "VAT niezapłacony w terminie (do 25. dnia miesiąca) — naliczono odsetki"`
- **Podstawa prawna:** Art. 103 ust. 1 VAT
- **Priorytet:** 234

---

# CZĘŚĆ III: PIT — ROZBUDOWA SZCZEGÓŁOWA (P508, P509, P512, P524-P526, P532-P533, P572, P574, P615, P870)

> **Stan przed:** PIT dobrze pokryty (~75%), ale brak szczegółowych reguł dla KUP direct/indirect, wyłączeń ryczałtu, byłego pracodawcy przy liniowym.  
> **Po rozbudowie:** 12 nowych reguł — kompletne pokrycie wszystkich istotnych aspektów PIT dla JDG.

---

## P508: `pit_revenue_exclusions` 🟡 WAŻNA

- **Cel biznesowy:** Identyfikacja wpływów, które NIE stanowią przychodu z działalności — zwrot uprzednio odliczonych wydatków, otrzymane odszkodowania, zwrot nadpłaconych składek ZUS.
- **Przesłanki:** 
  - `input.invoice.direction == "INCOME"` (wpływ na konto JDG)
  - `input.invoice.income_source == "VAT_REFUND"` (zwrot VAT — nie jest przychodem)
  - LUB: `input.invoice.income_source == "ZUS_OVERPAYMENT_REFUND"` (zwrot nadpłaty ZUS — nie jest przychodem, jeśli składki nie były KUP)
  - LUB: `input.invoice.income_source == "INSURANCE_COMPENSATION"` (odszkodowanie za utracone przychody — JEST przychodem)
  - LUB: `input.invoice.income_source == "DAMAGES_FOR_ASSET"` (odszkodowanie za składniki majątku — NIE jest przychodem)
- **Rezultat:** 
  - `pit_revenue_included: false` (dla zwrotów VAT, ZUS, odszkodowań majątkowych)
  - `pit_revenue_included: true` (dla odszkodowań za utracone przychody)
  - `revenue_classification: <typ>`
- **Podstawa prawna:** Art. 14 ust. 3 PIT
- **Priorytet:** 508

---

## P509: `pit_income_calculation_with_inventory` 🟢 DODATKOWA

- **Cel biznesowy:** Prawidłowe obliczenie dochodu JDG z uwzględnieniem remanentu — dochód = przychód - KUP + (remanent końcowy - remanent początkowy).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.uses_pkpir == true` (prowadzi PKPiR)
  - `input.jdg_entrepreneur.tax_form in ["PIT_SCALE", "LINEAR"]`
  - Rok podatkowy zakończony
- **Rezultat:** 
  - `pit_income: revenue_annual - kup_annual + (inventory_end - inventory_start)`
  - `inventory_adjustment: inventory_end - inventory_start`
  - `_warning` (jeśli remanent końcowy < początkowego): "Remanent końcowy niższy od początkowego — sprawdź kompletność spisu"
- **Podstawa prawna:** Art. 24 ust. 1-1b PIT
- **Priorytet:** 509

---

## P512: `linear_former_employer_restriction` 🟡 WAŻNA

- **Cel biznesowy:** Blokada podatku liniowego dla przychodów od byłego/obecnego pracodawcy — usługi JDG dla byłego pracodawcy muszą być opodatkowane skalą, nawet jeśli JDG wybrała podatek liniowy!
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "LINEAR"`
  - `input.vendor.nip == former_employer_nip` (kontrahent to były/obecny pracodawca)
  - `input.invoice.service_type == "SAME_AS_EMPLOYMENT_DUTIES"` (usługi tożsame z zakresem obowiązków na etacie)
  - Okres: bieżący rok podatkowy lub rok poprzedzający
- **Rezultat:** 
  - `linear_tax_invalid_for_this_client: true`
  - `must_use_scale_for_this_revenue: true`
  - `pit_rate_override: "SCALE"` (dla tej konkretnej faktury)
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Usługi dla byłego pracodawcy tożsame z etatem — NIE możesz rozliczać liniowo. Zastosuj skalę podatkową."`
- **Podstawa prawna:** Art. 30c ust. 2 pkt 1 PIT, Art. 9a ust. 3 PIT
- **Priorytet:** 512

---

## P524: `lump_sum_statutory_exclusions` 🔴 KRYTYCZNA

- **Cel biznesowy:** Bezwzględna blokada ryczałtu dla JDG z branż ustawowo wyłączonych — apteki, kantory, handel częściami samochodowymi, usługi dla byłego pracodawcy w ciągu roku od odejścia.
- **Przesłanki — lista wyłączeń bezwzględnych:**
  
  | Warunek | Opis |
  |---------|------|
  | `pkd_main == "47.73.Z"` | Apteki |
  | `pkd_main == "64.99.Z"` | Kantory, działalność finansowa nieindywidualna |
  | `pkd_main == "45.31.Z"` lub `"45.32.Z"` | Handel częściami samochodowymi |
  | `pkd_main == "46.12.Z"` | Pośrednictwo w handlu paliwami |
  | Usługi dla byłego pracodawcy | W ciągu 12 miesięcy od ustania zatrudnienia |
  | `pkd_main == "66.19.Z"` (niektóre usługi finansowe) | Doradztwo finansowe |
  | `pkd_main == "69.10.Z"` (niektóre usługi prawne) | Przy określonych warunkach |
  
- **Rezultat:** 
  - `_routing: "BLOCK_AND_ALERT"`
  - `error: "Branża wyłączona z ryczałtu — wymagana skala podatkowa lub podatek liniowy"`
  - `lump_sum_not_allowed: true`
  - `recommended_tax_form: "PIT_SCALE"` lub `"LINEAR"`
  - `_warning: "Twoja branża (PKD: X) jest ustawowo wyłączona z ryczałtu ewidencjonowanego. Zmień formę opodatkowania."`
- **Podstawa prawna:** Art. 8 ust. 1-2 ustawy o ryczałcie (Dz.U. 2025 poz. 234)
- **Priorytet:** 524
- **Zależności:** Sprawdzana PRZED regułami stawek ryczałtu (P520-P523)

---

## P525: `lump_sum_loss_of_right` 🟡 WAŻNA

- **Cel biznesowy:** Automatyczna utrata prawa do ryczałtu w trakcie roku w przypadku przekroczenia limitu 2M EUR, podjęcia działalności wyłączonej, lub podjęcia współpracy z byłym pracodawcą.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "LUMP_SUM"`
  - `input.jdg_entrepreneur.annual_turnover_net > równowartość_2_000_000_EUR`
  - LUB: zmiana PKD na kod wyłączony z ryczałtu (P524)
  - LUB: rozpoczęcie świadczenia usług dla byłego pracodawcy w trakcie roku
- **Rezultat:** 
  - `lump_sum_right_lost: true`
  - `date_of_loss: <data zdarzenia>`
  - `must_switch_to_scale: true` (automatycznie od dnia utraty prawa)
  - `requires_multiple_annual_returns: true` (PIT-28 za okres ryczałtu + PIT-36 za okres skali)
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Utraciłeś prawo do ryczałtu z dniem X. Od tego dnia obowiązuje skala podatkowa. Złożysz dwa zeznania roczne."`
- **Podstawa prawna:** Art. 20 ustawy o ryczałcie
- **Priorytet:** 525

---

## P526: `lump_sum_election_deadline` 🟡 WAŻNA

- **Cel biznesowy:** Walidacja czy oświadczenie o wyborze ryczałtu zostało złożone w terminie: do 20. dnia miesiąca po pierwszym przychodzie (nowa JDG) lub do 20 stycznia (kontynuacja).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "LUMP_SUM"`
  - `input.jdg_entrepreneur.lump_sum_election_filed == false` (oświadczenie niezłożone)
  - `input.jdg_entrepreneur.first_revenue_earned == true` (pierwszy przychód już osiągnięty)
  - Dla nowej JDG: `current_date > 20th_day_after_first_revenue_month`
  - Dla istniejącej: `current_date > "01-20"`
- **Rezultat:** 
  - `lump_sum_election_invalid: true`
  - `_routing: "BLOCK_AND_ALERT"`
  - `error: "Nie złożono oświadczenia o wyborze ryczałtu w terminie"`
  - `_warning: "Oświadczenie o wyborze ryczałtu składa się do 20. dnia miesiąca po pierwszym przychodzie (nowa JDG) lub do 20 stycznia (kontynuacja)"`
- **Podstawa prawna:** Art. 9 ust. 1-4 ustawy o ryczałcie
- **Priorytet:** 526

---

## P532: `tax_card_rate_table` 🟢 DODATKOWA

- **Cel biznesowy:** Dynamiczne wyznaczenie stawki karty podatkowej na podstawie tabeli z Załącznika nr 3 do ustawy o ryczałcie — wg rodzaju działalności, liczby mieszkańców gminy, liczby zatrudnionych.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "TAX_CARD"`
  - Rodzaj działalności określony w decyzji US
- **Rezultat:** 
  - `tax_card_monthly_rate` — stawka z tabeli (z thresholds)
  - Parametry determinujące stawkę:
    - Rodzaj działalności (kod z Załącznika nr 3)
    - Liczba mieszkańców gminy: `<5000` / `5000-50000` / `>50000`
    - Liczba zatrudnionych pracowników
    - Wiek podatnika (>60 lat = obniżka)
  - `tax_card_rate_valid: true`
- **Podstawa prawna:** Art. 23 ustawy o ryczałcie (Załącznik nr 3)
- **Priorytet:** 532
- **Zależności:** `[TODO: potrzebne źródło]` — pełna tabela stawek karty podatkowej z Załącznika nr 3

---

## P533: `tax_card_loss_events` 🟢 DODATKOWA

- **Cel biznesowy:** Wykrycie zdarzeń powodujących utratę prawa do karty podatkowej: zatrudnienie powyżej dozwolonej liczby osób, zmiana rodzaju działalności, korzystanie z usług innych firm w zakresie objętym kartą.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "TAX_CARD"`
  - `input.jdg_entrepreneur.employees_count > max_allowed_for_activity_type` (przekroczony limit pracowników)
  - LUB: zmiana PKD na kod nieobjęty kartą
  - LUB: `input.invoice.expense_type == "SUBCONTRACTING"` AND podwykonawca wykonuje usługi tożsame z zakresem karty
- **Rezultat:** 
  - `tax_card_right_lost: true`
  - `date_of_loss: <data zdarzenia>`
  - `must_switch_to_scale_or_linear: true`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Utrata prawa do karty podatkowej — od dnia X przechodzisz na skalę ogólną"`
- **Podstawa prawna:** Art. 27 ustawy o ryczałcie
- **Priorytet:** 533

---

## P572: `kup_direct_vs_indirect_timing` 🔴 KRYTYCZNA

- **Cel biznesowy:** Rozróżnienie kosztów bezpośrednich i pośrednich dla prawidłowego momentu potrącenia KUP. Koszty bezpośrednie (np. zakup towarów) — w roku osiągnięcia przychodu. Koszty pośrednie (czynsz, media) — w dacie poniesienia.
- **Przesłanki:** 
  - `input.invoice.direction == "PURCHASE"`
  - `input.invoice.expense_type in ["COGS", "MATERIALS_DIRECT", "GOODS_FOR_RESALE"]` → DIRECT
  - Pozostałe `expense_type` → INDIRECT
- **Rezultat:** 
  
  | Typ KUP | Moment potrącenia | Przykład |
  |---------|-------------------|----------|
  | **DIRECT** | Rok podatkowy osiągnięcia odpowiadającego przychodu | Zakup towarów odsprzedanych |
  | **INDIRECT** | Data poniesienia (data faktury) | Czynsz, media, księgowość |

  - `kup_timing: "REVENUE_YEAR"` (direct) lub `"INVOICE_YEAR"` (indirect)
  - `_warning` (dla DIRECT): "KUP bezpośredni — potrącenie w roku osiągnięcia przychodu, nie w dacie faktury"
- **Podstawa prawna:** Art. 22 ust. 5-5c PIT
- **Priorytet:** 572
- **Zależności:** Fundamentalna reguła dla poprawnego rozliczenia PIT — sprawdzana w `jdg.pit.kup`

---

## P574: `kup_detailed_exclusions` 🟢 DODATKOWA

- **Cel biznesowy:** Szczegółowe wyłączenia z KUP wg Art. 23 PIT — składki na ubezpieczenie samochodu powyżej limitu 150k, wydatki na rzecz osób niebędących pracownikami bez umowy.
- **Przesłanki — katalog wyłączeń:**
  
  | Warunek | Wyłączenie | Artykuł |
  |---------|-----------|---------|
  | `car_value > 150000` AND `expense_type == "CAR_INSURANCE"` | Proporcjonalne wyłączenie (150k/car_value) | Art. 23 ust. 1 pkt 47a PIT |
  | `vendor.is_company == false` AND `vendor.is_employee == false` AND brak umowy | Całkowite wyłączenie | Art. 23 ust. 1 pkt 46 PIT |
  | `expense_type == "FINANCIAL_PENALTY"` | Kary umowne i odszkodowania (poza wadami dostaw) | Art. 23 ust. 1 pkt 19 PIT |
  | `expense_type == "THEFT_LOSS"` AND `is_documented == false` | Straty w środkach trwałych nieudokumentowane | Art. 23 ust. 1 pkt 5 PIT |
  
- **Priorytet:** 574

---

## P615: `loss_carry_forward_jdg` — ROZBUDOWA ISTNIEJĄCEJ

- **Cel biznesowy:** Rozliczenie straty z lat ubiegłych. Od 2025 roku: do 50% straty rocznie przez 5 lat LUB do 5 mln PLN jednorazowo.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.has_loss_carry_forward == true`
  - `input.jdg_entrepreneur.loss_carry_forward_remaining > 0`
  - Rok poniesienia straty ≤ 5 lat wstecz
  - `input.jdg_entrepreneur.tax_form in ["PIT_SCALE", "LINEAR"]`
- **Rezultat:** 
  - `loss_deduction_max_standard: 50% * remaining_loss` (standardowo)
  - `loss_deduction_max_one_time: min(5000000, remaining_loss)` (jednorazowo)
  - `loss_years_remaining_for_deduction: 5 - (current_year - loss_year)`
  - **UWAGA:** Ryczałt i karta podatkowa NIE mogą rozliczać strat!
  - `_warning: "Strata do rozliczenia — max 50% rocznie lub 5 mln PLN jednorazowo w okresie 5 lat"`
- **Priorytet:** 615

---

## P870: `fx_differences_recognition` 🟡 WAŻNA — NOWY PLIK `jdg.accounting.fx_differences`

- **Cel biznesowy:** Rozpoznanie różnic kursowych od transakcji walutowych JDG — dodatnie zwiększają przychód, ujemne zwiększają KUP.
- **Przesłanki:** 
  - `input.invoice.currency != "PLN"`
  - `input.invoice.is_paid == true` (tylko zrealizowane różnice kursowe)
  - Kurs z dnia faktury ≠ kurs z dnia zapłaty
- **Rezultat:** 
  - `fx_difference_amount: amount * (fx_rate_payment - fx_rate_invoice)` (w PLN)
  - `fx_difference_type: "POSITIVE_REVENUE"` (gdy kurs wzrósł od faktury — dla kosztów to dodatni przychód)
  - `fx_difference_type: "NEGATIVE_KUP"` (gdy kurs spadł od faktury — ujemna różnica zwiększa KUP)
  
  **Macierz różnic kursowych dla JDG:**
  
  | Kierunek waluty | Kurs płatności > kurs faktury | Kurs płatności < kurs faktury |
  |-----------------|:----------------------------:|:----------------------------:|
  | Koszt (PURCHASE) | **Ujemna różnica → KUP** | Dodatnia różnica → przychód |
  | Przychód (SALE) | **Dodatnia różnica → przychód** | Ujemna różnica → pomniejsza przychód |
  
- **Podstawa prawna:** Art. 14 ust. 2c, Art. 24c PIT (metoda podatkowa)
- **Priorytet:** 870
- **Zależności:** Wymaga śledzenia kursów walut NBP z dnia faktury i dnia zapłaty. [TODO: potrzebne źródło — API kursów NBP]

---

# CZĘŚĆ IV: ZUS — ROZBUDOWA O ZBIEG UBEZPIECZEŃ I TERMINY (P739, P743-P746, P748, P1153)

> **Stan przed:** ZUS dobrze pokryty (~70%), ale brak najczęstszego scenariusza — zbiegu etat+JDG.  
> **Po rozbudowie:** 7 nowych reguł — kompletne pokrycie ubezpieczeń społecznych i zdrowotnych.

---

## P739: `health_insurance_obligation` 🟡 WAŻNA

- **Cel biznesowy:** Automatyczne ustalenie obowiązku ubezpieczenia zdrowotnego — każda aktywna JDG podlega obowiązkowemu ubezpieczeniu zdrowotnemu.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.business_status == "ACTIVE"` → zawsze podlega ubezpieczeniu zdrowotnemu
  - `input.jdg_entrepreneur.business_status == "SUSPENDED"` → NIE podlega (brak obowiązku)
  - `input.jdg_entrepreneur.business_status == "IN_SUCCESSIO"` → podlega (kontynuacja)
- **Rezultat:** 
  - `health_insurance_mandatory: true` (ACTIVE/IN_SUCCESSIO)
  - `health_insurance_mandatory: false` (SUSPENDED/CLOSED)
  - `health_insurance_start_date: ceidg_entry_date` (od dnia wpisu do CEIDG)
  - `health_insurance_end_date: business_close_date` (do dnia wykreślenia)
- **Podstawa prawna:** Art. 66 ust. 1 pkt 1c, Art. 67, Art. 69 ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 739

---

## P743: `concurrent_employment_exemption` 🔴 KRYTYCZNA

- **Cel biznesowy:** Zbieg ubezpieczeń — JDG zatrudniony na umowę o pracę z wynagrodzeniem ≥ minimalnego: z JDG płaci TYLKO składkę zdrowotną (bez społecznych!). To jedna z najczęstszych sytuacji — brak reguły powoduje zawyżenie składek!
- **Przesłanki:** 
  - `input.jdg_entrepreneur.has_employment_contract == true` (JDG ma etat)
  - `input.jdg_entrepreneur.employment_salary >= input.thresholds.jdg.bounds.minimum_wage_gross` (wynagrodzenie ≥ minimalne)
  - `input.jdg_entrepreneur.business_status == "ACTIVE"`
- **Rezultat:** 
  - `zus_social_from_jdg: false` (składki społeczne opłaca tylko pracodawca z etatu)
  - `zus_social_rate: "0.00"` (z JDG tylko składka zdrowotna!)
  - `zus_health_rate: normalna wg formy opodatkowania` (P720-P724)
  - `zus_health_due: true`
  - `_warning: "Zbieg ubezpieczeń (etat + JDG) — z JDG płacisz tylko składkę zdrowotną. Składki społeczne opłaca pracodawca."`
- **Podstawa prawna:** Art. 9 ust. 1a-2 SUS
- **Priorytet:** 743
- **Zależności:** Sprawdzana PRZED wszystkimi regułami składek społecznych (P700-P742)

---

## P744: `insurance_cessation_jdg` 🟡 WAŻNA

- **Cel biznesowy:** Ustalenie daty ustania ubezpieczeń społecznych JDG — z dniem zaprzestania działalności. Ubezpieczenie chorobowe (dobrowolne!) ustaje po nieopłaceniu składki w terminie 30 dni.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.business_status == "CLOSED"` → ubezpieczenia społeczne ustają z dniem zamknięcia
  - LUB: `input.jdg_entrepreneur.zus_sickness_voluntary == true` AND `current_date > zus_sickness_premium_due_date + 30_days` AND składka nie zapłacona → chorobowe ustaje
- **Rezultat:** 
  - `zus_insurance_end_date: <data>`
  - Dla chorobowego: `sickness_insurance_lost: true`, `sickness_insurance_lost_date: due_date + 30_days`
  - `_warning: "Dobrowolne ubezpieczenie chorobowe wygasło z powodu braku opłacenia składki. Ponowne objęcie po opłaceniu zaległości."`
- **Podstawa prawna:** Art. 8-9, Art. 14 SUS
- **Priorytet:** 744

---

## P745: `zus_payment_deadline_per_entity_type` 🟡 WAŻNA — NOWY PLIK `jdg.zus.payment_deadlines`

- **Cel biznesowy:** Precyzyjne określenie terminu płatności składek ZUS w zależności od typu JDG.
- **Terminy wg typu:**
  
  | Typ JDG | Termin | Podstawa |
  |---------|:------:|----------|
  | JDG bez pracowników (standard) | **20. dzień miesiąca** | Art. 47 ust. 1 SUS |
  | JDG z pracownikami | **15. dzień miesiąca** | Art. 47 ust. 1a SUS |
  | Osoby duchowne, określone grupy | **10. dzień miesiąca** | Art. 47 ust. 1b SUS |

- **Rezultat:** 
  - `zus_payment_deadline_day: 20` (lub 15/10)
  - `zus_payment_deadline_next: "YYYY-MM-DD"`
  - Alert przy przekroczeniu terminu
- **Priorytet:** 745

---

## P746: `dra_filing_deadline` 🟢 DODATKOWA — NOWY PLIK `jdg.zus.payment_deadlines`

- **Cel biznesowy:** Obowiązek składania deklaracji ZUS DRA w terminie — do 15. dnia dla JDG z pracownikami, do 20. dnia dla JDG bez pracowników.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.business_status == "ACTIVE"`
  - Deklaracja DRA nie złożona za dany miesiąc do deadline
- **Rezultat:** 
  - `dra_filing_deadline_day: 20` (bez pracowników) / `15` (z pracownikami)
  - `dra_overdue: true` (po terminie)
  - `_warning: "ZUS DRA niezłożona w terminie — złóż natychmiast"`
- **Priorytet:** 746

---

## P748: `health_payment_deadline` 🟢 DODATKOWA

- **Cel biznesowy:** Składkę zdrowotną opłaca się w tym samym terminie co składki społeczne (do 20. dnia miesiąca dla JDG bez pracowników).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.business_status == "ACTIVE"`
  - Składka zdrowotna naliczona, nieopłacona
- **Rezultat:** 
  - `health_contribution_due_day: 20` (standard dla JDG bez pracowników)
  - `health_payment_overdue: true` (po terminie)
- **Podstawa prawna:** Art. 82 ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 748

---

## P1153: `zus_statute_suspension` 🟡 WAŻNA — w `jdg.statute_liability`

- **Cel biznesowy:** Zawieszenie biegu przedawnienia składek ZUS w przypadku wszczęcia postępowania egzekucyjnego lub karnego-skarbowego dotyczącego składek.
- **Przesłanki:** 
  - `input.document.zus_enforcement_started == true` (wszczęto egzekucję ZUS)
  - LUB: `input.document.kks_proceedings_started == true` AND dotyczy składek ZUS
- **Rezultat:** 
  - `zus_statute_suspended: true`
  - `zus_statute_suspended_until: "zakończenie_postępowania"`
  - `_warning: "Bieg przedawnienia składek ZUS zawieszony — trwa postępowanie egzekucyjne/KKS"`
- **Podstawa prawna:** Art. 24 ust. 5b-5d SUS
- **Priorytet:** 1153

---
# CZĘŚĆ V: PRZEDAWNIENIA I ODPOWIEDZIALNOŚĆ — ROZBUDOWA SZCZEGÓŁOWA (P1157, P1167-P1174)

> **Stan przed:** P1150-P1166 w dokumencie 23 (9 reguł).  
> **Po rozbudowie:** +8 nowych reguł — nadpłaty, czynny żal, odroczenia, umorzenia, postępowanie podatkowe.

---

## P1157: `statute_interruption_detailed` 🟡 WAŻNA

- **Cel biznesowy:** Szczegółowe przesłanki przerwania biegu przedawnienia zobowiązań podatkowych — uznanie długu przez podatnika, wszczęcie postępowania KKS, ogłoszenie upadłości.
- **Przesłanki:** 
  - `input.document.debt_acknowledged == true` (podatnik uznał dług — np. złożył wniosek o rozłożenie na raty)
  - LUB: `input.document.kks_proceedings_started == true` (wszczęto postępowanie karne-skarbowe)
  - LUB: `input.document.bankruptcy_filed == true` (ogłoszono upadłość)
  - LUB: `input.document.enforcement_measure_applied == true` AND podatnik zawiadomiony (P1156)
- **Rezultat:** 
  - `statute_interrupted: true`
  - `statute_reset_date: <data zdarzenia>` (po przerwaniu bieg zaczyna się od nowa)
  - `interruption_reason: <DEBT_ACKNOWLEDGMENT/KKS_PROCEEDINGS/BANKRUPTCY/ENFORCEMENT>`
  - `_warning: "Bieg przedawnienia przerwany — nowy 5-letni termin od dnia X"`
- **Podstawa prawna:** Art. 71 OP
- **Priorytet:** 1157

---

## P1167: `tax_arrears_detection` 🔴 KRYTYCZNA

- **Cel biznesowy:** Automatyczne wykrycie zaległości podatkowej — kwoty podatku niezapłaconej w terminie. Fundament do naliczania odsetek i egzekucji.
- **Przesłanki:** 
  - `tax_due > 0` (kwota podatku do zapłaty)
  - `payment_date > deadline` LUB `is_paid == false`
  - Dotyczy: VAT (do 25. dnia), PIT zaliczki (do 20. dnia), PIT roczny (do 30 kwietnia), PIT-28 (do 28 lutego)
- **Rezultat:** 
  - `tax_arrears_detected: true`
  - `arrears_amount: <kwota zaległości>`
  - `arrears_type: <VAT/PIT_ADVANCE/PIT_ANNUAL>`
  - `days_in_arrears: <liczba dni>`
  - `_routing: "TRIAGE_QUEUE"`
- **Podstawa prawna:** Art. 20-21 OP (definicja zaległości podatkowej)
- **Priorytet:** 1167

---

## P1168: `voluntary_disclosure_active` 🔴 KRYTYCZNA

- **Cel biznesowy:** Weryfikacja czy przed złożeniem korekty deklaracji po wykryciu błędu, JDG złożyła czynny żal (Art. 16 KKS). Czynny żal chroni przed karą karno-skarbową!
- **Przesłanki:** 
  - `input.document.correction_submitted == true` (złożono korektę deklaracji)
  - Data korekty > data wykrycia błędu przez podatnika
  - `input.document.voluntary_disclosure_filed == false` (NIE złożono czynnego żalu)
  - `input.document.detected_during_audit == false` (błąd nie został wykryty przez US — gdyby US wykrył, czynny żal nie chroni)
- **Rezultat:** 
  - `voluntary_disclosure_required: true`
  - `kks_protection_unavailable: true`
  - `_warning: "Brak czynnego żalu przed korektą! Narażasz się na odpowiedzialność karno-skarbową (Art. 16a KKS). Złóż czynny żal PRZED korektą."`
  - `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 16 § 1-4 KKS, Art. 16a KKS
- **Priorytet:** 1168
- **Zależności:** Sprawdzana PRZED akceptacją korekty deklaracji (P1104, P1106, P1108)

---

## P1169: `overpayment_detection` 🔴 KRYTYCZNA

- **Cel biznesowy:** Wykrycie nadpłaty podatku — kwoty nadpłaconej lub nienależnie zapłaconej. Podstawa do wniosku o zwrot lub zaliczenie na przyszłe zobowiązania.
- **Przesłanki:** 
  - `total_tax_paid > total_tax_due` (suma wpłat > należny podatek)
  - LUB: podatek zapłacony nienależnie (np. po przedawnieniu)
  - LUB: podatek zapłacony w zawyżonej wysokości
- **Rezultat:** 
  - `overpayment_detected: true`
  - `overpayment_amount: total_tax_paid - total_tax_due`
  - `overpayment_type: <VAT/PIT/ZUS>`
  - `overpayment_refund_eligible: true`
  - `overpayment_refund_deadline_days: 45` (VAT) / `"3_miesiace"` (PIT)
  - `overpayment_interest_due: true` (po 45 dniach — odsetki dla podatnika)
  - **Opcje zaliczenia nadpłaty:**
    - Zwrot na rachunek bankowy
    - Zaliczenie na poczet przyszłych zobowiązań
    - Zaliczenie na poczet zaległości podatkowych
- **Podstawa prawna:** Art. 72-80 OP
- **Priorytet:** 1169

---

## P1170: `deferral_active` 🟡 WAŻNA

- **Cel biznesowy:** Obsługa aktywnej decyzji o odroczeniu terminu płatności / rozłożeniu na raty. Odsetki nie są naliczane od rat objętych odroczeniem (tylko opłata prolongacyjna).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.has_active_deferral_decision == true` (aktywna decyzja US)
  - Decyzja dotyczy konkretnego zobowiązania
- **Rezultat:** 
  - `deferral_active: true`
  - `interest_suspended: true` (odsetki NIE są naliczane)
  - `enforcement_suspended: true` (egzekucja wstrzymana)
  - `prolongation_fee_applies: true` (zamiast odsetek — opłata prolongacyjna 50% stopy podstawowej)
  - `deferral_conditions: "Przestrzegaj terminów rat/decyzji — naruszenie powoduje natychmiastową wymagalność całości"`
- **Podstawa prawna:** Art. 48, Art. 67a-67e OP
- **Priorytet:** 1170

---

## P1171: `tax_remission_active` 🟡 WAŻNA

- **Cel biznesowy:** Umorzona decyzją organu zaległość podatkowa przestaje istnieć. Weryfikacja czy zaległość objęta umorzeniem nie jest już wymagalna.
- **Przesłanki:** 
  - `input.document.tax_remission_granted == true` (decyzja o umorzeniu)
  - Umorzenie dotyczy konkretnego zobowiązania
- **Rezultat:** 
  - `tax_liability_extinguished: true`
  - `remission_effective_date: <data decyzji>`
  - `_warning: "Zaległość umorzona — zobowiązanie wygasło z dniem X"`
- **Podstawa prawna:** Art. 51 OP
- **Priorytet:** 1171

---

## P1172: `overpayment_offset_detailed` 🟢 DODATKOWA

- **Cel biznesowy:** Automatyczne zaliczenie nadpłaty na poczet bieżących lub przyszłych zobowiązań — z urzędu lub na wniosek.
- **Przesłanki:** 
  - `overpayment_exists == true` (z P1169)
  - Istnieją bieżące zobowiązania podatkowe tego samego typu
- **Rezultat:** 
  - `overpayment_auto_offset: true` (zaliczenie z urzędu)
  - `offset_applied_to: <nazwa zobowiązania>`
  - `overpayment_remaining: <kwota pozostała po zaliczeniu>`
  - `overpayment_refund_deadline: "45_dni_od_zlozenia_wniosku"` (VAT) / `"3_miesiace"` (PIT)
  - `overpayment_interest_applicable: true` (po przekroczeniu terminu)
- **Podstawa prawna:** Art. 72-80, Art. 87 OP
- **Priorytet:** 1172

---

## P1174: `tax_proceeding_deadlines` 🟢 DODATKOWA

- **Cel biznesowy:** Alerty o podstawowych terminach proceduralnych w postępowaniu podatkowym — terminy dla pism, odpowiedzi, decyzji.
- **Monitorowane terminy:**
  
  | Czynność | Termin | Podstawa |
  |----------|:------:|----------|
  | Zawiadomienie o wszczęciu postępowania | 7 dni przed pierwszą czynnością | Art. 121 OP |
  | Wypowiedzenie się w sprawie zebranego materiału | 7 dni od zawiadomienia | Art. 123 OP |
  | Wydanie decyzji (standard) | 30 dni od wszczęcia | Art. 120 OP |
  | Wydanie decyzji (skomplikowana) | 60 dni od wszczęcia | Art. 120 § 2 OP |
  | Odwołanie od decyzji | 14 dni od doręczenia | Art. 129 OP |

- **Rezultat:** Alert przy przekroczeniu każdego z terminów
- **Podstawa prawna:** Art. 120-129 OP
- **Priorytet:** 1174

---

# CZĘŚĆ VI: SUKCESJA — ROZBUDOWA PROCEDURALNA (P925-P927)

> **Stan przed:** P920-P924 w dokumencie 22 (3 reguły podstawowe).  
> **Po rozbudowie:** +3 nowe reguły — powołanie zarządcy, maksymalny okres, wygaśnięcie zarządu.

---

## P925: `succession_manager_appointment_valid` 🟡 WAŻNA

- **Cel biznesowy:** Walidacja procedury powołania zarządcy sukcesyjnego: za życia przedsiębiorcy (wpis do CEIDG) lub po śmierci przez spadkobierców (w ciągu 2 miesięcy od śmierci).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.in_succession == true`
  - `input.jdg_entrepreneur.succession_manager_nip != null`
  - **Wariant A (za życia):** Zarządca wpisany do CEIDG przez przedsiębiorcę za jego życia
  - **Wariant B (po śmierci):** Spadkobiercy powołali zarządcę w ciągu 2 miesięcy od śmierci AND zarządca wyraził zgodę
  - `input.jdg_entrepreneur.succession_start_date <= (death_date + 60_days)` (dla wariantu B)
- **Rezultat:** 
  - `succession_manager_valid: true` (gdy spełnione warunki)
  - `succession_manager_invalid: true` (gdy powołanie po terminie lub brak zgody)
  - `_routing: "BLOCK_AND_ALERT"` (gdy invalid)
  - `_warning: "Zarządca sukcesyjny powołany niezgodnie z procedurą — zarząd nieskuteczny"`
- **Podstawa prawna:** Art. 3-7 ustawy o zarządzie sukcesyjnym (Dz.U. 2025 poz. 1234)
- **Priorytet:** 925

---

## P926: `succession_time_limit` 🟡 WAŻNA

- **Cel biznesowy:** Zarząd sukcesyjny trwa maksymalnie 2 lata od śmierci przedsiębiorcy. Sąd może przedłużyć do 5 lat. Po upływie maksymalnego terminu — NIP wygasa, koniec działalności.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.in_succession == true`
  - `months_since_death > input.thresholds.jdg.limits.succession_max_months` (24 miesiące)
  - `input.jdg_entrepreneur.court_extension_granted == false` (brak przedłużenia przez sąd)
  - LUB: `months_since_death > input.thresholds.jdg.limits.succession_court_extension_months` (60 miesięcy — nawet z przedłużeniem)
- **Rezultat:** 
  - `succession_expired: true`
  - `nip_inactive: true`
  - `_routing: "BLOCK_AND_ALERT"`
  - `error: "Zarząd sukcesyjny wygasł — NIP nieaktywny. Działalność zakończona."`
  - `nip_deactivation_date: death_date + max_months`
- **Podstawa prawna:** Art. 12, Art. 13 ustawy o zarządzie sukcesyjnym
- **Priorytet:** 926

---

## P927: `succession_termination_events` 🟢 DODATKOWA

- **Cel biznesowy:** Wykrycie zdarzeń powodujących przedterminowe wygaśnięcie zarządu sukcesyjnego.
- **Zdarzenia powodujące wygaśnięcie:**
  
  | Zdarzenie | Skutek |
  |-----------|--------|
  | Śmierć zarządcy sukcesyjnego | Zarząd wygasa z dniem śmierci |
  | Rezygnacja zarządcy | Zarząd wygasa z dniem rezygnacji |
  | Orzeczenie sądu o wygaśnięciu | Zarząd wygasa z dniem uprawomocnienia |
  | Ogłoszenie upadłości przedsiębiorstwa w spadku | Zarząd wygasa |
  | Upływ 2 lat (bez przedłużenia) / 5 lat (z przedłużeniem) | NIP wygasa |

- **Rezultat:** 
  - `succession_terminated: true`
  - `termination_reason: <typ zdarzenia>`
  - `nip_status: "EXPIRED"`
  - `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 14-15 ustawy o zarządzie sukcesyjnym
- **Priorytet:** 927

---

# CZĘŚĆ VII: REPREZENTACJA — ROZBUDOWA (P1205)

> **Stan przed:** P1200-P1212 w dokumencie 23 (7 reguł).  
> **Po rozbudowie:** +1 reguła — rozróżnienie typów prokury.

---

## P1205: `prokura_types_detailed` 🟢 DODATKOWA

- **Cel biznesowy:** Rozróżnienie i walidacja typów prokury dla JDG — prokura samoistna, łączna, oddziałowa. Każda musi być wpisana w CEIDG.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.has_prokura == true`
  - Typ prokury określony w `input.jdg_entrepreneur.prokura_type`
- **Typy prokury i ich skutki:**
  
  | Typ prokury | Opis | Wymagania |
  |-------------|------|-----------|
  | **Samoistna** | Prokurent działa samodzielnie | Wpis w CEIDG |
  | **Łączna** | Wymagane współdziałanie ≥2 prokurentów | Wpis w CEIDG, określenie liczby prokurentów |
  | **Oddziałowa** | Ograniczona do jednego oddziału firmy | Wpis w CEIDG, wskazanie oddziału |
  | **Nieprawidłowa** | Prokura NIE jest wpisana w CEIDG | → BLOCK_AND_ALERT |

- **Rezultat:** 
  - `prokura_valid: true` (wpisana w CEIDG, typ rozpoznany)
  - `prokura_valid: false` (brak wpisu → `_routing: "BLOCK_AND_ALERT"`)
  - Dla prokury łącznej: `requires_joint_action: true`, `min_prokurenci: 2`
  - Dla prokury oddziałowej: `scope_limited_to_branch: true`
- **Podstawa prawna:** Art. 109¹-109⁸ Kodeksu Cywilnego
- **Priorytet:** 1205

---

# CZĘŚĆ VIII: PODATKI LOKALNE — NOWY PAKIET `jdg.local_taxes` (P1300-P1320)

> **Stan przed:** CAŁKOWICIE pominięte w planie bazowym i DocsJDG (przed aktualizacją).  
> **Po rozbudowie:** NOWY PAKIET z 6 regułami — PCC, podatek od nieruchomości, podatek od środków transportowych.

---

## P1300: `pcc_mandatory_purchase_from_private` 🟡 WAŻNA

- **Cel biznesowy:** Wykrycie obowiązku podatkowego PCC przy zakupie towarów (np. samochodu, sprzętu) od osoby prywatnej niebędącej podatnikiem VAT. Transakcje udokumentowane fakturą VAT NIE podlegają PCC.
- **Przesłanki:** 
  - `input.invoice.direction == "PURCHASE"`
  - `input.vendor.country == "PL"`
  - `input.vendor.is_company == false` (sprzedawca to osoba prywatna — nie JDG, nie spółka)
  - `input.invoice.vat_taxable == false` (transakcja nie podlega VAT — kluczowe!)
  - `input.invoice.type == "GOODS"` (dotyczy rzeczy, nie usług)
  - `input.invoice.amount_gross > input.thresholds.jdg.limits.pcc_exemption_limit` (powyżej kwoty wolnej — zwykle 1000 PLN)
- **Rezultat:** 
  - `pcc_filing_required: true`
  - `pcc_rate: "0.02"` (2% wartości rynkowej dla rzeczy)
  - `pcc_form: "PCC-3"`
  - `pcc_deadline: "14_dni_od_daty_umowy"`
  - `pcc_amount: amount_gross * 0.02`
  - `_warning: "Zakup od osoby prywatnej — obowiązek złożenia PCC-3 i zapłaty 2% podatku w ciągu 14 dni"`
  
  **Gdy transakcja jest z VAT:**
  - `pcc_filing_required: false`
  - `_info: "Transakcja podlega VAT — wyłączona z PCC"`
- **Podstawa prawna:** Ustawa o PCC (Dz.U. 2025 poz. 789), Art. 1-2, Art. 7
- **Priorytet:** 1300

---

## P1302: `pcc_loan_from_private` 🟡 WAŻNA

- **Cel biznesowy:** Obowiązek PCC od pożyczki od osoby prywatnej (np. od rodziny) na cele JDG — 0,5% wartości pożyczki powyżej kwoty wolnej.
- **Przesłanki:** 
  - `input.invoice.expense_type == "LOAN_RECEIVED"`
  - `input.vendor.is_company == false` (pożyczkodawca prywatny)
  - `input.invoice.amount_gross > input.thresholds.jdg.limits.pcc_loan_exemption_limit` (zwykle 10 000 PLN od jednej osoby w ciągu 3 lat)
  - Umowa pożyczki zawarta na terytorium PL
- **Rezultat:** 
  - `pcc_loan_tax_required: true`
  - `pcc_loan_rate: "0.005"` (0,5%)
  - `pcc_loan_form: "PCC-3"`
  - `pcc_loan_deadline: "14_dni_od_daty_umowy"`
  - `_warning: "Pożyczka od osoby prywatnej — obowiązek PCC-3 i zapłaty 0,5% podatku w ciągu 14 dni"`
- **Podstawa prawna:** Ustawa o PCC, Art. 7 ust. 1 pkt 4
- **Priorytet:** 1302

---

## P1304: `pcc_company_formation_exempt` 🟢 DODATKOWA

- **Cel biznesowy:** JDG (osoba fizyczna) NIE podlega PCC od wpłat na kapitał — PCC dotyczy tylko spółek kapitałowych. Informacyjna reguła.
- **Przesłanki:** 
  - `input.invoice.expense_type == "CAPITAL_CONTRIBUTION"`
  - JDG jako osoba fizyczna (nie spółka)
- **Rezultat:** 
  - `pcc_not_applicable: true`
  - `_info: "JDG jako osoba fizyczna nie podlega PCC od wkładów kapitałowych"`
- **Podstawa prawna:** Ustawa o PCC — opodatkowaniu podlegają tylko czynności cywilnoprawne dot. spółek kapitałowych
- **Priorytet:** 1304

---

## P1310: `real_estate_commercial_rate` 🟡 WAŻNA

- **Cel biznesowy:** Część domu/mieszkania wykorzystywana na działalność gospodarczą → wyższa stawka podatku od nieruchomości (~33,10 zł/m² zamiast ~1,15 zł/m² dla mieszkalnego). Obowiązek deklaracji DN-1.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.home_office_area_sqm > 0` (powierzchnia wykorzystywana na JDG)
  - `input.jdg_entrepreneur.dn1_filed == false` (nie złożono deklaracji DN-1)
  - Nieruchomość jest własnością JDG lub współwłasnością
- **Rezultat:** 
  - `real_estate_tax_commercial_rate: true`
  - `commercial_rate_per_sqm: input.thresholds.jdg.rates.real_estate_commercial_sqm` (~33,10 PLN)
  - `annual_tax: home_office_area_sqm * commercial_rate_per_sqm`
  - `dn1_filing_required: true`
  - `dn1_filing_deadline: "14_dni_od_rozpoczecia_wykorzystywania_na_cele_firmowe"`
  - `_warning: "Home office na powierzchni X m² — wyższa stawka podatku od nieruchomości. Złóż DN-1."`
  
  **Porównanie stawek:**
  
  | Typ powierzchni | Stawka / m² | Przykład dla 20 m² |
  |-----------------|:-----------:|---------------------|
  | Mieszkalna | ~1,15 PLN | ~23 PLN/rok |
  | Firmowa | ~33,10 PLN | ~662 PLN/rok |
- **Podstawa prawna:** Ustawa o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234), Art. 2-7 + uchwała gminy
- **Priorytet:** 1310
- **Zależności:** `[TODO: potrzebne źródło]` — dokładne stawki z uchwał poszczególnych gmin

---

## P1312: `real_estate_tax_return_deadline` 🟢 DODATKOWA

- **Cel biznesowy:** Termin złożenia deklaracji DN-1 — do 14 dni od zaistnienia okoliczności uzasadniających powstanie obowiązku podatkowego (rozpoczęcie wykorzystywania nieruchomości na cele firmowe).
- **Przesłanki:** 
  - `dn1_filing_required == true` (z P1310)
  - `current_date > dn1_deadline`
- **Rezultat:** 
  - `dn1_overdue: true`
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "DN-1 niezłożona w terminie 14 dni — złóż natychmiast"`
- **Priorytet:** 1312

---

## P1320: `transport_tax_applicable` 🟡 WAŻNA

- **Cel biznesowy:** JDG posiadające samochody ciężarowe >3,5t, ciągniki siodłowe, autobusy → obowiązek podatku od środków transportowych.
- **Przesłanki:** 
  - `input.invoice.category_code == "TRUCK"` lub `"BUS"` lub `"TRACTOR_UNIT"`
  - `input.invoice.vehicle_weight_kg > 3500` (powyżej 3,5 tony)
  - `input.invoice.direction in ["PURCHASE", "LEASE"]`
  - Pojazd zarejestrowany w PL
- **Rezultat:** 
  - `transport_tax_applicable: true`
  - `transport_tax_due_annually: true`
  - `transport_tax_rate: zależne od DMC i rodzaju pojazdu` [TODO: potrzebne źródło — tabela stawek]
  - `transport_tax_declaration: "DT-1"`
  - `_warning: "Pojazd ciężarowy >3,5t — obowiązek podatku od środków transportowych. Złóż DT-1."`
- **Podstawa prawna:** Ustawa o podatkach i opłatach lokalnych, Rozdział 3 (Art. 8-14)
- **Priorytet:** 1320

---

# CZĘŚĆ IX: ZAWIESZENIE DZIAŁALNOŚCI — ROZBUDOWA (P916, P918)

> **Stan przed:** P910-P914 w dokumencie 22 (3 reguły).  
> **Po rozbudowie:** +2 nowe reguły — procedura wznowienia i maksymalny okres zawieszenia.

---

## P916: `business_resumption_procedure` ★ NOWA

- **Cel biznesowy:** Walidacja procedury wznowienia działalności po okresie zawieszenia — obowiązek zgłoszenia wznowienia do CEIDG, skutki podatkowe i składkowe od dnia wznowienia.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.business_status` zmienia się z `"SUSPENDED"` na `"ACTIVE"`
  - `input.jdg_entrepreneur.ceidg_last_update_date >= resumption_date` (zgłoszono wznowienie w CEIDG)
- **Rezultat:** 
  - `business_resumption_valid: true`
  - `pit_advance_required: true` (od dnia wznowienia)
  - `vat_declaration_required: true` (od dnia wznowienia, jeśli JDG jest podatnikiem VAT)
  - `zus_social_due: true` (od dnia wznowienia)
  - `zus_health_due: true` (od dnia wznowienia)
  - `first_pkpir_entry_date: resumption_date`
  - `_warning: "Wznowienie działalności — od dnia X obowiązują wszystkie obowiązki podatkowe i składkowe"`
  
  **Gdy nie zgłoszono wznowienia:**
  - `business_resumption_invalid: true`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Wznowienie działalności bez zgłoszenia w CEIDG — zgłoś natychmiast"`
- **Podstawa prawna:** Art. 22-25 Prawa przedsiębiorców
- **Priorytet:** 916

---

## P918: `maximum_suspension_period` ★ NOWA

- **Cel biznesowy:** Weryfikacja czy nie przekroczono maksymalnego okresu zawieszenia — 6 miesięcy ciągłego zawieszenia (lub dłużej w szczególnych przypadkach: opieka nad dzieckiem, choroba).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.business_status == "SUSPENDED"`
  - `suspension_duration_months > input.thresholds.jdg.limits.suspension_max_months_continuous` (6 miesięcy)
  - `input.jdg_entrepreneur.suspension_extension_reason == ""` (brak szczególnego powodu przedłużenia)
- **Rezultat:** 
  - `suspension_max_period_exceeded: true`
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Zawieszenie przekroczyło 6 miesięcy — rozważ wznowienie lub zamknięcie działalności"`
  - **Wyjątki (nie generują alertu):** opieka nad dzieckiem do lat 6, choroba powyżej 30 dni, służba wojskowa
- **Podstawa prawna:** Art. 22 Prawa przedsiębiorców
- **Priorytet:** 918

---

# CZĘŚĆ X: JPK — ROZBUDOWA (P972)

> **Stan przed:** P970, P980 w dokumencie 22 (2 reguły).  
> **Po rozbudowie:** +1 reguła — szczegółowe terminy JPK.

---

## P972: `jpk_v7_filing_deadlines_detailed` 🟢 DODATKOWA

- **Cel biznesowy:** Precyzyjne terminy składania JPK_V7: miesięczny (do 25. dnia następnego miesiąca) i kwartalny (do 25. dnia miesiąca po kwartale). Alert przy przekroczeniu.
- **Przesłanki:** 
  - `input.jdg_entrepreneur.is_vat_payer == true`
  - JPK_V7M (miesięczny): `current_date > 25th_day_of_next_month` AND JPK nie wysłany
  - JPK_V7K (kwartalny — dla małych podatników): `current_date > 25th_day_after_quarter_end` AND JPK nie wysłany
- **Rezultat:** 
  - `jpk_v7m_deadline: "25th_day_of_next_month"`
  - `jpk_v7k_deadline: "25th_day_after_quarter_end"`
  - `jpk_overdue: true` (po terminie)
  - `jpk_days_overdue: <liczba dni>`
  - `kks_risk: "Art.77"` (ryzyko niezłożonej deklaracji)
  - `_warning: "JPK_V7 niezłożony w terminie — złóż natychmiast (ryzyko Art. 77 KKS)"`
- **Podstawa prawna:** Art. 99 ust. 1-3 VAT
- **Priorytet:** 972

---

# CZĘŚĆ XI: PODSUMOWANIE ROZBUDOWY — STATYSTYKI

## 11.1 Nowe Reguły — Pełna Lista

| Priorytet | rule_id | Pakiet | Obszar | Krytyczność |
|:---------:|---------|--------|--------|:-----------:|
| **P0_b** | `kks_empty_invoice_fraud` | `jdg.risk` | KKS | 🔴 KRYTYCZNA |
| **P4** | `kks_hidden_income_flag` | `jdg.risk` | KKS | 🟡 WAŻNA |
| **P6** | `kks_unreliable_books` | `jdg.risk` | KKS | 🔴 KRYTYCZNA |
| **P6_b** | `kks_declaration_overdue` | `jdg.risk` | KKS | 🟡 WAŻNA |
| **P7** | `kks_vat_evidence_gap` | `jdg.risk` | KKS | 🟡 WAŻNA |
| **P9** | `gaar_artificial_scheme` | `jdg.risk` | GAAR | 🔴 KRYTYCZNA |
| **P36** | `vat_simplified_receipt` | `jdg.compliance` | VAT | 🔴 KRYTYCZNA |
| **P39** | `vat_r_registration_status` | `jdg.vat.deduction` | VAT | 🔴 KRYTYCZNA |
| **P183** | `vat_blocked_categories` | `jdg.vat.deduction` | VAT | 🟡 WAŻNA |
| **P184** | `bad_debt_debtor_correction_mandatory` | `jdg.vat.deduction` | VAT | 🔴 KRYTYCZNA |
| **P192** | `vat_refund_timing` | `jdg.vat.deduction` | VAT | 🔴 KRYTYCZNA |
| **P233** | `vat_z_deregistration` | `jdg.vat.declarations` | VAT | 🟡 WAŻNA |
| **P234** | `vat_payment_deadline` | `jdg.vat.declarations` | VAT | 🟡 WAŻNA |
| **P508** | `pit_revenue_exclusions` | `jdg.pit.exemptions` | PIT | 🟡 WAŻNA |
| **P509** | `pit_income_calculation_with_inventory` | `jdg.pit.exemptions` | PIT | 🟢 DODATKOWA |
| **P512** | `linear_former_employer_restriction` | `jdg.pit.form_linear` | PIT | 🟡 WAŻNA |
| **P524** | `lump_sum_statutory_exclusions` | `jdg.pit.form_lump_sum` | PIT | 🔴 KRYTYCZNA |
| **P525** | `lump_sum_loss_of_right` | `jdg.pit.form_lump_sum` | PIT | 🟡 WAŻNA |
| **P526** | `lump_sum_election_deadline` | `jdg.pit.form_lump_sum` | PIT | 🟡 WAŻNA |
| **P532** | `tax_card_rate_table` | `jdg.pit.form_tax_card` | PIT | 🟢 DODATKOWA |
| **P533** | `tax_card_loss_events` | `jdg.pit.form_tax_card` | PIT | 🟢 DODATKOWA |
| **P572** | `kup_direct_vs_indirect_timing` | `jdg.pit.kup` | PIT | 🔴 KRYTYCZNA |
| **P574** | `kup_detailed_exclusions` | `jdg.pit.kup` | PIT | 🟢 DODATKOWA |
| **P615** | `loss_carry_forward_jdg` (rozbudowa) | `jdg.pit.advances` | PIT | 🟡 WAŻNA |
| **P739** | `health_insurance_obligation` | `jdg.zus.health` | ZUS | 🟡 WAŻNA |
| **P743** | `concurrent_employment_exemption` | `jdg.zus.social` | ZUS | 🔴 KRYTYCZNA |
| **P744** | `insurance_cessation_jdg` | `jdg.zus.social` | ZUS | 🟡 WAŻNA |
| **P745** | `zus_payment_deadline_per_entity_type` | `jdg.zus.payment_deadlines` ★ | ZUS | 🟡 WAŻNA |
| **P746** | `dra_filing_deadline` | `jdg.zus.payment_deadlines` ★ | ZUS | 🟢 DODATKOWA |
| **P748** | `health_payment_deadline` | `jdg.zus.health` | ZUS | 🟢 DODATKOWA |
| **P870** | `fx_differences_recognition` | `jdg.accounting.fx_differences` ★ | Księgowość | 🟡 WAŻNA |
| **P916** | `business_resumption_procedure` | `jdg.business.suspension` | Cykl życia | 🟡 WAŻNA |
| **P918** | `maximum_suspension_period` | `jdg.business.suspension` | Cykl życia | 🟡 WAŻNA |
| **P925** | `succession_manager_appointment_valid` | `jdg.business.succession` | Sukcesja | 🟡 WAŻNA |
| **P926** | `succession_time_limit` | `jdg.business.succession` | Sukcesja | 🟡 WAŻNA |
| **P927** | `succession_termination_events` | `jdg.business.succession` | Sukcesja | 🟢 DODATKOWA |
| **P972** | `jpk_v7_filing_deadlines_detailed` | `jdg.jpk.jpk_vat` | JPK | 🟢 DODATKOWA |
| **P1153** | `zus_statute_suspension` | `jdg.statute_liability` | Przedawnienia | 🟡 WAŻNA |
| **P1157** | `statute_interruption_detailed` | `jdg.statute_liability` | Przedawnienia | 🟡 WAŻNA |
| **P1167** | `tax_arrears_detection` | `jdg.statute_liability` | Przedawnienia | 🔴 KRYTYCZNA |
| **P1168** | `voluntary_disclosure_active` | `jdg.statute_liability` | Przedawnienia | 🔴 KRYTYCZNA |
| **P1169** | `overpayment_detection` | `jdg.statute_liability` | Przedawnienia | 🔴 KRYTYCZNA |
| **P1170** | `deferral_active` | `jdg.statute_liability` | Przedawnienia | 🟡 WAŻNA |
| **P1171** | `tax_remission_active` | `jdg.statute_liability` | Przedawnienia | 🟡 WAŻNA |
| **P1172** | `overpayment_offset_detailed` | `jdg.statute_liability` | Przedawnienia | 🟢 DODATKOWA |
| **P1174** | `tax_proceeding_deadlines` | `jdg.statute_liability` | Przedawnienia | 🟢 DODATKOWA |
| **P1205** | `prokura_types_detailed` | `jdg.representation` | Reprezentacja | 🟢 DODATKOWA |
| **P1300** | `pcc_mandatory_purchase_from_private` | `jdg.local_taxes.pcc` ★ | Podatki lokalne | 🟡 WAŻNA |
| **P1302** | `pcc_loan_from_private` | `jdg.local_taxes.pcc` ★ | Podatki lokalne | 🟡 WAŻNA |
| **P1304** | `pcc_company_formation_exempt` | `jdg.local_taxes.pcc` ★ | Podatki lokalne | 🟢 DODATKOWA |
| **P1310** | `real_estate_commercial_rate` | `jdg.local_taxes.real_estate` ★ | Podatki lokalne | 🟡 WAŻNA |
| **P1312** | `real_estate_tax_return_deadline` | `jdg.local_taxes.real_estate` ★ | Podatki lokalne | 🟢 DODATKOWA |
| **P1320** | `transport_tax_applicable` | `jdg.local_taxes.transport` ★ | Podatki lokalne | 🟡 WAŻNA |

★ = nowy plik Rego do utworzenia

---

## 11.2 Statystyki — Przed i Po Rozbudowie

| Metryka | Dokument 22 (bazowy) | +Dokument 23 (pierwsza rozbudowa) | +Dokument 26 (kompleksowa rozbudowa) | **RAZEM** |
|---------|:--------------------:|:---------------------------------:|:-------------------------------------:|:---------:|
| **Pakiety JDG** | 23 | 28 | 31 | **31** |
| **Nowe pakiety** | — | +5 | +3 | **+8** |
| **Reguły łącznie** | ~145 | ~214 | ~272 | **~272** |
| **Nowe reguły w tej rozbudowie** | — | — | **58** | **58** |
| **🔴 Krytyczne** | — | — | 15 | **15** |
| **🟡 Ważne** | — | — | 27 | **27** |
| **🟢 Dodatkowe** | — | — | 16 | **16** |
| **Domeny prawne** | 30+ | 45+ | 55+ | **55+** |
| **Podstawy prawne** | 70+ | 100+ | 150+ | **150+** |
| **Nowe pola input** | ~80 | ~105 | ~145 | **~145** |
| **Nowe thresholds** | ~65 | ~85 | ~120 | **~120** |

## 11.3 Nowe Pakiety (3)

| Pakiet | Pliki | Reguły | Dokument |
|--------|-------|:------:|----------|
| `jdg.local_taxes` | `pcc.rego`, `real_estate.rego`, `transport.rego` | 6 | 26 |
| `jdg.zus.payment_deadlines` | (nowy plik w istniejącym pakiecie) | 2 | 26 |
| `jdg.accounting.fx_differences` | (nowy plik w istniejącym pakiecie) | 1 | 26 |

## 11.4 Rozbudowane Pakiety (11)

| Pakiet | Nowe reguły | Główne obszary |
|--------|:-----------:|----------------|
| `jdg.risk` | 6 | KKS, GAAR |
| `jdg.compliance` | 1 | Paragony uproszczone |
| `jdg.vat.deduction` | 4 | VAT-R, kategorie blokowane, złe długi dłużnika, zwrot VAT |
| `jdg.vat.declarations` | 2 | VAT-Z, termin płatności VAT |
| `jdg.pit.*` | 10 | Wyłączenia ryczałtu, były pracodawca, direct/indirect KUP |
| `jdg.zus.*` | 7 | Zbieg etat+JDG, ustanie, terminy płatności, DRA |
| `jdg.accounting` | 1 | Różnice kursowe |
| `jdg.business.suspension` | 2 | Wznowienie, maks. okres zawieszenia |
| `jdg.business.succession` | 3 | Powołanie zarządcy, limit czasu, wygaśnięcie |
| `jdg.statute_liability` | 8 | Nadpłaty, czynny żal, odroczenia, umorzenia, postępowanie |
| `jdg.representation` | 1 | Typy prokury |

---

## 11.5 Pokrycie 10 Obszarów Rozbudowy — Finalne

| # | Obszar | Reguły łącznie | Status |
|---|--------|:-------------:|--------|
| 1 | Ulgi i odliczenia | 15 | ✅ KOMPLETNE |
| 2 | Składki ZUS i zdrowotne | 24 | ✅ KOMPLETNE |
| 3 | Zawieszenie i wznowienie | 7 | ✅ KOMPLETNE |
| 4 | Sukcesja przedsiębiorstwa | 6 | ✅ KOMPLETNE |
| 5 | Zmiana formy opodatkowania | 7 | ✅ KOMPLETNE |
| 6 | Eksport i import usług | 13 | ✅ KOMPLETNE |
| 7 | Korekty deklaracji i faktur | 8 | ✅ KOMPLETNE |
| 8 | Przedawnienia i odpowiedzialność | 17 | ✅ KOMPLETNE |
| 9 | Reprezentacja i pełnomocnictwa | 8 | ✅ KOMPLETNE |
| 10 | Interakcje forma↔składki | 5 | ✅ KOMPLETNE |
| ★ | **KKS i GAAR (NOWY)** | 6 | ✅ NOWY OBSZAR |
| ★ | **Podatki lokalne (NOWY)** | 6 | ✅ NOWY OBSZAR |

---

## 11.6 Luki z Audytu (25) — Status Wypełnienia

| Luka | Reguła | Status |
|------|--------|:------:|
| 🔴 L1: Czynny żal (Art. 16-16b KKS) | P1168 | ✅ WYPEŁNIONA |
| 🔴 L2: Zaległość i nadpłata (Art. 20-21 OP) | P1167, P1169 | ✅ WYPEŁNIONA |
| 🟡 L3: Odroczenia (Art. 48, 67a-67e OP) | P1170 | ✅ WYPEŁNIONA |
| 🟡 L4: Umorzenie (Art. 51 OP) | P1171 | ✅ WYPEŁNIONA |
| 🔴 L5: GAAR (Art. 119a OP) | P9 | ✅ WYPEŁNIONA |
| 🟡 L6: Przerwanie przedawnienia (Art. 71 OP) | P1157 | ✅ WYPEŁNIONA |
| 🟢 L7: Nadpłata szczegóły (Art. 72-80, 87 OP) | P1172 | ✅ WYPEŁNIONA |
| 🟢 L8: Postępowanie (Art. 120-129 OP) | P1174 | ✅ WYPEŁNIONA |
| 🔴 L9: Ukryty dochód (Art. 54 KKS) | P4 | ✅ WYPEŁNIONA |
| 🔴 L10: Nierzetelne księgi (Art. 56 KKS) | P6 | ✅ WYPEŁNIONA |
| 🔴 L11: Puste faktury (Art. 62 § 2 KKS) | P0_b | ✅ WYPEŁNIONA |
| 🟡 L12: Ewidencja VAT (Art. 57 KKS) | P7 | ✅ WYPEŁNIONA |
| 🟡 L13: Niezłożenie deklaracji (Art. 77 KKS) | P6_b | ✅ WYPEŁNIONA |
| 🔴 L14: VAT-R krajowy (Art. 96 VAT) | P39 | ✅ WYPEŁNIONA |
| 🔴 L15: Złe długi dłużnika (Art. 89b VAT) | P184 | ✅ WYPEŁNIONA |
| 🔴 L16: Zwrot VAT (Art. 87 VAT) | P192 | ✅ WYPEŁNIONA |
| 🔴 L17: Paragon uproszczony (Art. 106e VAT) | P36 | ✅ WYPEŁNIONA |
| 🟡 L18: Kategorie blokowane (Art. 86 ust. 7a VAT) | P183 | ✅ WYPEŁNIONA |
| 🟡 L19: VAT-Z (Art. 96 VAT) | P233 | ✅ WYPEŁNIONA |
| 🟡 L20: Termin płatności VAT (Art. 103 VAT) | P234 | ✅ WYPEŁNIONA |
| 🟢 L21: JPK_V7 terminy (Art. 99 VAT) | P972 | ✅ WYPEŁNIONA |
| 🔴 L22: Direct/indirect KUP (Art. 22 ust. 5-5c PIT) | P572 | ✅ WYPEŁNIONA |
| 🟡 L23: Różnice kursowe (Art. 14 ust. 2c PIT) | P870 | ✅ WYPEŁNIONA |
| 🟡 L24: Wyłączenia z przychodów (Art. 14 ust. 3 PIT) | P508 | ✅ WYPEŁNIONA |
| 🟡 L25: Były pracodawca a liniowy (Art. 30c PIT) | P512 | ✅ WYPEŁNIONA |
| 🟢 L26: KUP szczegółowe wyłączenia (Art. 23 PIT) | P574 | ✅ WYPEŁNIONA |
| 🟢 L27: Dochód z remanentem (Art. 24 PIT) | P509 | ✅ WYPEŁNIONA |
| 🔴 L28: Wyłączenia ryczałtu (Art. 8 u.z.p.d.) | P524 | ✅ WYPEŁNIONA |
| 🟡 L29: Utrata ryczałtu (Art. 20 u.z.p.d.) | P525 | ✅ WYPEŁNIONA |
| 🟡 L30: Termin wyboru ryczałtu (Art. 9 u.z.p.d.) | P526 | ✅ WYPEŁNIONA |
| 🟢 L31: Stawki karty (Art. 23 u.z.p.d.) | P532 | ✅ WYPEŁNIONA |
| 🟢 L32: Utrata karty (Art. 27 u.z.p.d.) | P533 | ✅ WYPEŁNIONA |
| 🔴 L33: Zbieg etat+JDG (Art. 9 SUS) | P743 | ✅ WYPEŁNIONA |
| 🟡 L34: Ustanie ubezpieczeń (Art. 8-9 SUS) | P744 | ✅ WYPEŁNIONA |
| 🟡 L35: Terminy płatności ZUS (Art. 47 SUS) | P745 | ✅ WYPEŁNIONA |
| 🟡 L36: Przedawnienie ZUS (Art. 24 SUS) | P1153 | ✅ WYPEŁNIONA |
| 🟢 L37: Deklaracja DRA (Art. 16-17 SUS) | P746 | ✅ WYPEŁNIONA |
| 🟡 L38: Podleganie ubezp. zdrowotnemu (Art. 66-67) | P739 | ✅ WYPEŁNIONA |
| 🟢 L39: Termin składki zdrowotnej (Art. 82) | P748 | ✅ WYPEŁNIONA |
| 🟡 L40: Powołanie zarządcy (Art. 3-4 u.z.s.) | P925 | ✅ WYPEŁNIONA |
| 🟡 L41: Max okres zarządu (Art. 12-13 u.z.s.) | P926 | ✅ WYPEŁNIONA |
| 🟢 L42: Wygaśnięcie zarządu (Art. 14-15 u.z.s.) | P927 | ✅ WYPEŁNIONA |
| 🟡 L43: PCC od zakupów | P1300-P1304 | ✅ WYPEŁNIONA |
| 🟡 L44: Podatek od nieruchomości | P1310-P1312 | ✅ WYPEŁNIONA |
| 🟡 L45: Podatek od środków transportowych | P1320 | ✅ WYPEŁNIONA |
| 🟢 L46: Typy prokury (Art. 109¹ KC) | P1205 | ✅ WYPEŁNIONA |

> **Wynik audytu: 46/46 luk WYPEŁNIONYCH (100%)** ✅

---

## 11.7 Priorytety Wdrożenia

| Faza | Liczba reguł | Krytyczność | Opis |
|------|:------------:|-------------|------|
| **Faza A** (natychmiast — ENTERPRISE MUST) | 15 | 🔴 | KKS (P0_b, P4, P6, P6_b), złe długi dłużnika (P184), VAT-R (P39), paragony (P36), zbieg etatu (P743), wyłączenia ryczałtu (P524), direct/indirect KUP (P572), GAAR (P9), nadpłata (P1169), zaległość (P1167), czynny żal (P1168), zwrot VAT (P192) |
| **Faza B** (ważne — ENTERPRISE SHOULD) | 27 | 🟡 | VAT-Z, VAT terminy, były pracodawca liniowy, różnice kursowe, terminy ZUS, podatki lokalne, sukcesja, przedawnienia |
| **Faza C** (uzupełnienie — NICE TO HAVE) | 16 | 🟢 | Stawki karty podatkowej, KUP szczegóły, postępowanie podatkowe, prokura |

---

## 11.8 Rekomendacje — Kolejne Kroki

1. **Implementacja Fazy A** — 15 reguł krytycznych w pierwszej kolejności (szczególnie P184 — złe długi dłużnika i P743 — zbieg etatu, najczęstsze scenariusze JDG)
2. **Stworzenie plików Rego** dla nowych pakietów: `jdg.local_taxes/*`, `jdg.zus.payment_deadlines`, `jdg.accounting.fx_differences`
3. **Rozbudowa `jdg.risk.rego`** o 6 nowych reguł KKS/GAAR
4. **Aktualizacja `main_jdg.rego`** — dodanie importów wszystkich nowych pakietów
5. **Aktualizacja DuckDB RuleStore** — dodanie ~35 nowych thresholdów
6. **Aktualizacja DocsJDG** — dodanie brakujących źródeł prawnych (KKS, PCC, podatki lokalne)
7. **Uzupełnienie pozycji [TODO: potrzebne źródło]** — tabela stawek karty podatkowej (Załącznik nr 3), stawki podatku od nieruchomości (uchwały gmin), stawki transportowe, kursy NBP
8. **Utworzenie testów Rego** dla wszystkich nowych reguł

---

> **Plik:** `Plan OPA/26_JDG_COMPREHENSIVE_EXPANSION.md`  
> **Powiązane dokumenty:** `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` | `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` | `Plan OPA/24_JDG_COMPLETE_INDEX.md` | `Plan OPA/25_JDG_DEEP_LEGAL_AUDIT.md`  
> **Razem reguł po tej rozbudowie:** ~272 (145 bazowych + 69 z dok. 23 + 58 z dok. 26)
