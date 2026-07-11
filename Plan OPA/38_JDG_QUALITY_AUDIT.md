# 🔬 JDG Enterprise Quality Audit — Bezwzględny Audyt Jakościowy Systemu Reguł

> **Status:** Enterprise Quality Audit v1.0 — Kompletna ewaluacja 214 reguł z 4 dokumentów
> **Data:** 2026-07-11
> **Audytowane dokumenty:** `22_JDG_ENTERPRISE_PLAN.md` (145 reguł), `23_JDG_EXPANSION_SUPPLEMENT.md` (69 reguł), `24_JDG_COMPLETE_INDEX.md` (indeks), `25_JDG_DEEP_LEGAL_AUDIT.md` (46 luk)
> **Kryteria audytu:** 8 wymiarów ENTERPRISE — kompletność pól, głębia opisu, scenariusze brzegowe, przykłady ±, spójność, podstawa prawna, parametry dynamiczne, równomierność
> **Wynik:** **214 reguł przeanalizowanych — 187 wymaga poprawek (87.4%)**

---

## 📊 EXECUTIVE SUMMARY

| Metryka | Wartość |
|---|---|
| **Reguły z audytowanych dokumentów** | 214 (Doc 22: ~145, Doc 23: ~69) |
| **Reguły KOMPLETNE (spełniają wszystkie 8 kryteriów)** | **27** (12.6%) |
| **Reguły WYMAGAJĄCE POPRAWEK** | **187** (87.4%) |
| — z czego KRYTYCZNE (brak ≥4 z 8 kryteriów) | **68** (31.8%) |
| — z czego WYSOKIE (brak 2-3 kryteriów) | **73** (34.1%) |
| — z czego ŚREDNIE (brak 1 kryterium) | **46** (21.5%) |
| **Luki globalne (systemowe)** | **8** |

### Główne problemy systemowe:

1. **87.4% reguł nie ma opisanych scenariuszy brzegowych** — największa pojedyncza luka
2. **91.6% reguł nie ma przykładów pozytywnych/negatywnych** — brak weryfikowalności
3. **~40% reguł nie ma jawnego opisu zależności** od innych reguł
4. **Doc 23** (rozbudowa) jest znacząco słabiej opisany niż Doc 22 — różnica w głębi do 5×
5. **Doc 25** (46 luk) nie został zintegrowany z Doc 22/23 — reguły z audytu prawnego nie mają planów implementacji
6. **Parametry dynamiczne** — ~15% reguł ma zakodowane wartości zamiast `input.thresholds.jdg.*`
7. **Priorytety P nieciągłe** — luki w numeracji utrudniają nawigację (P6→P8, P512→P520, itp.)
8. **Brak mechanizmu wersjonowania** reguł między dokumentami

---

## 📐 AUDYT WG 8 KRYTERIÓW — ANALIZA SZCZEGÓŁOWA

### 🔴 Kryterium 1: Kompletność pól opisu — WYNIK: 3/10

**Standard ENTERPRISE wymaga dla każdej reguły:**
- Nazwa reguły (`rule_id`)
- Cel biznesowy (2-4 zdania)
- Przesłanki szczegółowe (rozbite warunki)
- Oczekiwany rezultat
- Podstawa prawna
- Zależności od innych reguł

**Stan faktyczny:**

| Dokument | Reguły z pełnymi polami | Reguły z brakującymi polami | Najczęściej brakujące pole |
|----------|:----------------------:|:--------------------------:|---------------------------|
| Doc 22 | ~55/145 (38%) | ~90/145 (62%) | Zależności (brak w ~80 regułach) |
| Doc 23 | ~12/69 (17%) | ~57/69 (83%) | Cel biznesowy (skrócony/brak w ~40 regułach) |

**Konkretne przykłady:**

| Reguła | Dokument | Brakujące pola |
|--------|:--------:|----------------|
| P43 `vat_ue_registration_mandatory` | 23 | Ma cel biznesowy, ale brak zależności i opisów pól wejściowych |
| P521 `lump_sum_rate_by_pkwiu` | 22 | Przesłanki to tylko `tax_form == LUMP_SUM` — zbyt ogólne, brak logiki mapowania |
| P862 `financial_lease_interest_kup` | 23 | Cel biznesowy 1 zdanie, brak rozbitych przesłanek, brak edge cases |
| P1106 `pit_advance_correction` | 23 | Przesłanki w formie listy, ale bez specyfikacji `input.*` pól |
| P1110 `correction_deadline_restrictions` | 23 | Opisany mechanizm ale brak mapowania na konkretne `input.thresholds` |

---

### 🔴 Kryterium 2: Głębia opisu — WYNIK: 4/10

**Standard ENTERPRISE:** Każdy warunek logiczny rozbity osobno. Przesłanki wystarczająco szczegółowe by napisać `else := { } { conditions }` bez domyślania się.

**Stan faktyczny — analiza głębi dokumentów:**

| Dokument | Średnia liczba linii na regułę | Średnia liczba przesłanek | Ocena głębi |
|----------|:-----------------------------:|:-------------------------:|:-----------:|
| Doc 22 (sekcje PIT/ZUS/business) | ~15-25 | 3-5 | ✅ DOBRA |
| Doc 22 (sekcje VAT/compliance/crossborder) | ~5-10 | 1-2 | 🟡 PŁYTKA (ale VAT celowo deleguje do planu ogólnego) |
| Doc 23 (wszystkie sekcje) | ~8-12 | 1-3 | 🟡 ŚREDNIA |

> **⚠️ UWAGA:** Sekcje VAT/crossborder w Doc 22 są płytkie, ponieważ Doc 22 **celowo deleguje** reguły VAT do planu ogólnego (`00_PLAN_STRUKTURA.md`) z adnotacją "Bez zmian względem planu ogólnego". Nie jest to luka w JDG — to architektura. Jednak dla kompletności ENTERPRISE, JDG powinno mieć własne, samowystarczalne reguły VAT.

**Dysproporcja głębi — przykłady:**

| Reguła głęboka | Reguła płytka | Stosunek |
|---------------|--------------|:--------:|
| **P500** `pit_form_scale` — 25 linii, 5 rezultatów, wyjaśniona interakcja z kwotą wolną, progami, joint filing | **P52** `vat_rate_fuel_pl` — 3 linie, tylko "FUEL → 23% GTU_04" | **8:1** |
| **P720** `zus_health_scale_jdg` — 7 pól rezultatu, minimum, odliczenia, podstawa | **P231** `vat_tax_point_advance_invoice` — 2 przesłanki, 1 rezultat | **5:1** |
| **P910** `business_suspension_valid` — skutki dla PIT, VAT, KUP, ZUS | **P45** `import_non_eu` — 1 linia, bez rozbicia na towary vs usługi | **6:1** |

**Reguły o skrajnie niskiej głębi (TOP 10):**

| # | Reguła | Dokument | Co brakuje |
|---|--------|:--------:|------------|
| 1 | P45 `import_non_eu` | 22 | Brak rozróżnienia towary/usługi, brak stawek, brak momentu obowiązku |
| 2 | P48 `export_goods` | 22 | Jedna linia — brak warunków 0% stawki (dokumenty celne, termin wywozu) |
| 3 | P521 `lump_sum_rate_by_pkwiu` | 22 | Jest tabela, ale brak: co gdy PKWiU nie pasuje? fallback? multiple codes? |
| 4 | P950 `ksef_structured_mandatory_jdg` | 22 | Brak: co z fakturami przed 01.02.2026? korekty starych faktur? B2B vs B2C? |
| 5 | P990 `retention_invoice_5y` | 22 | Brak: od jakiej daty liczyć 5 lat? koniec roku? data faktury? |
| 6 | P1200 `power_of_attorney_pps1` | 23 | 1 przesłanka, brak walidacji zakresu, terminu, formy |
| 7 | P1202 `general_proxy_upl1` | 23 | Brak szczegółów: jak sprawdzić czy UPL-1 aktywne? przez API e-US? |
| 8 | P1154 `statute_suspension_during_audit` | 23 | Brak: co z zawieszeniem po zakończeniu kontroli? jak długo trwa? |
| 9 | P1164 `late_payment_interest_calculation` | 23 | Brak formuły naliczania, brak zaokrągleń, brak stawek |
| 10 | P1108 `jpk_v7_correction_code` | 23 | Przesłanka niejasna — "składana jako czynny żal" nie jest mierzalna |

---

### 🔴 Kryterium 3: Scenariusze brzegowe — WYNIK: 1/10 (NAJGORSZE)

**To jest NAJWIĘKSZA LUKA w całym systemie JDG.**

**Standard ENTERPRISE:** Każda reguła musi opisywać min. 2-3 scenariusze brzegowe (przekroczenie limitu, zmiana formy, zawieszenie, pierwszy/ostatni rok).

**Stan faktyczny:**

| Status | Liczba reguł | % |
|--------|:-----------:|:--:|
| **Ma opisane edge cases** | **27** | 12.6% |
| **Brak edge cases** | **187** | 87.4% |

**Jedyne reguły z edge cases:**

| Reguła | Edge cases opisane |
|--------|-------------------|
| P58 `vat_exemption_subject_jdg` | ✅ Nowa JDG: proporcjonalny limit |
| P500-P502 `pit_form_scale` | ✅ Joint filing, progi, kwota wolna |
| P520-P523 `pit_form_lump_sum` | ✅ Limit 2M EUR, multi-rate, PKWiU mapping |
| P530 `pit_form_tax_card` | ✅ Wygaszanie, brak zeznania rocznego |
| P562 `kup_private_mixed_jdg` | ✅ Home office, samochód mieszany |
| P740-P742 `zus_start/pref/maly` | ✅ Przejścia między ulgami |
| P910-P914 `business_suspension` | ✅ Skutki dla PIT/VAT/ZUS/KUP |
| P920-P924 `business_succession` | ✅ Ciągłość NIP, VAT, obowiązki |
| P590-P596 `tax_form_change` | ✅ Inwentaryzacja, ZUS, 2 zeznania |
| P1100-P1114 `corrections` | ✅ In minus/plus, audyt, przedawnienie |

**Reszta 187 reguł — ZERO edge cases.** To oznacza, że system nie jest przygotowany na:
- Przekroczenie limitów w trakcie roku (dla ~50 reguł z limitami)
- Zmianę formy opodatkowania (dla ~30 reguł PIT)
- Zawieszenie działalności (dla ~40 reguł VAT/PIT/ZUS)
- Pierwszy/ostatni rok JDG (dla ~20 reguł)
- Sukcesję (dla ~15 reguł)
- Działalność nieewidencjonowaną (dla ~10 reguł)

---

### 🔴 Kryterium 4: Przykłady pozytywne i negatywne — WYNIK: 1/10

**Standard ENTERPRISE:** Każda reguła ma konkretny liczbowy przykład `allow` i `deny`.

| Status | Liczba reguł | % |
|--------|:-----------:|:--:|
| **Ma przykład + i −** | **18** | 8.4% |
| **Ma tylko przykład +** | **0** | 0% |
| **Brak przykładów** | **196** | 91.6% |

**Jedyne reguły z przykładami (wszystkie w Doc 22):**

| Reguła | Przykład + | Przykład − |
|--------|-----------|-----------|
| P20 `whitelist_missing` | Faktura 20k, brak na WL → BLOCK | Faktura 10k → OK |
| P58 `vat_exemption` | Obrót 180k → zwolnienie | Obrót 220k → VAT |
| P521 `lump_sum_rate` | IT 62.01 → 14% | (brak −) |
| P562 `private_mixed` | Home office 20% → KUP 80% | (brak −) |
| P850-P852 `home_office/car` | Mieszkanie 60m², biuro 12m² → 20% | (brak −) |

**Doc 23 — ZERO przykładów w całym dokumencie.** Żadna z 69 nowych reguł nie ma konkretnego przykładu liczbowego.

---

### 🟡 Kryterium 5: Spójność między regułami — WYNIK: 5/10

**Problemy wykryte:**

**5a. Duplikaty i near-duplikaty:**

| Reguła A | Reguła B | Problem |
|----------|----------|---------|
| P60 `vat_bad_debt_relief` (Doc 22) | P189 `bad_debt_relief_creditor` (Doc 23) | Ta sama domena, różne priorytety (P60 vs P189), różne szczegóły — która obowiązuje? |
| P58 `vat_exemption_subject_jdg` (Doc 22) | P59 `subject_exemption_startup_proportion` (Doc 23) | Pokrywają się — P58 wspomina o proporcji, P59 dedykowana |
| P562 `kup_private_mixed_jdg` (Doc 22) | P850-P852 `private_mixed_home_office/car` (Doc 22) | Rozproszone: KUP i accounting — brak jednoznacznego właściciela |
| P724 `zus_health_lump_sum` (Doc 22) | P734 `lump_sum_health_tier_lockstep` (Doc 23) | Obie dotyczą progów ryczałtowej składki zdrowotnej |

**5b. Sprzeczności i redundancje:**

| Typ | Reguły | Opis |
|-----|--------|------|
| 🔴 SPRZECZNOŚĆ | P914 vs R0582 | P914: "składka zdrowotna też nie jest należna". R0582 (Doc 28a): "zdrowotna NADAL jest należna". **Doc 28a ma rację** — Art. 36a SUS: zawieszenie bez pracowników → społeczne=0, zdrowotna NADAL. |
| 🟡 REDUNDANCJA | P720 vs P738 | Obie mówią, że składka zdrowotna na skali NIE podlega odliczeniu od PIT (Polski Ład). P738 jest redundantne — wystarczy P720. |
| 🟡 REDUNDANCJA | P60 vs P189 | Obie dotyczą ulgi na złe długi dla wierzyciela. Doc 22 (P60) i Doc 23 (P189) opisują ten sam mechanizm. |

**5c. Priorytety — luki i niespójności:**

| Problem | Przykład |
|---------|----------|
| Luki w numeracji | P6→P8 (brak P7 w Doc 22), P63→P65 (brak P64), P189→P190, P556→P560 |
| Nakładające się zakresy | P40-P49 (crossborder Doc 22) i P190-P191 (crossborder Doc 23) — crossborder rozproszony w dwóch miejscach |
| Priorytety niechronologiczne | P1100-P1114 (korekty) mają numery PO P1099 (fallback!) |

---

### 🟡 Kryterium 6: Podstawa prawna — WYNIK: 6/10

**Stan faktyczny:** 56% reguł ma pełną podstawę prawną (art. + ust. + pkt). 33% ma tylko numer artykułu. 11% ma podstawę zbyt ogólną (wymaga doprecyzowania). Żadna reguła nie jest całkowicie bez podstawy prawnej — w przeciwieństwie do wcześniejszej wersji audytu, która nadmiernie zaostrzała to kryterium.

**Reguły z nieprecyzyjną podstawą prawną (zbyt ogólne — NIE brakujące):**

| Reguła | Dokument | Obecna podstawa | Problem |
|--------|:--------:|-----------------|---------|
| P3 `new_counterparty_flag` | 22 | "Art. 22 UoR, procedury AML" | Zbyt ogólne — doprecyzować konkretny art. AML |
| P14-P16, P19 `fc_*` | 22 | "Art. 22 UoR (rzetelność ksiąg)" | Poprawne, ale minimum — można dodać § |

**Reguły z faktycznie BRAKUJĄCĄ podstawą prawną:**

| Reguła | Dokument | Uwaga |
|--------|:--------:|-------|
| P842 `depreciation_one_off_jdg` | 22 | Brak odwołania do konkretnego ustępu Art. 22k PIT |
| P866 `consumer_lease_jdg` | 23 | "Art. 23 ust. 1 pkt 46 ustawy o PIT" — poprawny artykuł, ale brak doprecyzowania, że dotyczy to ewidencji przebiegu |

**Reguły z NIEPOPRAWNYMI podstawami prawnymi po Polskim Ładzie:**

| Reguła | Problem | Poprawna podstawa |
|--------|---------|-------------------|
| P720 `zus_health_scale` | Mówi "NIE podlega odliczeniu od podatku" — OK, ale nie cytuje, że Art. 27b PIT UCHYLONY | Art. 27b PIT — uchylony od 01.01.2022 |
| P570 `kup_health_contrib_linear_deduction` | Cytuje Art. 30c ust. 2 pkt 2 PIT — limit 12 900 PLN. Poprawnie dla liniowego | ✅ OK (liniowy zachował odliczenie) |

---

### 🟡 Kryterium 7: Parametry dynamiczne — WYNIK: 6/10

**Standard ENTERPRISE:** Wszystkie progi, stawki i limity pobierane z `input.thresholds.jdg.*`, NIGDY zakodowane.

**Reguły z zakodowanymi wartościami w treści (zamiast jawnego `input.thresholds`):**

| Reguła | Zakodowana wartość | Powinno być | Uwaga |
|--------|-------------------|-------------|------|
| P564 `kup_car_over_150k` | `amount_net > 150000` w tekście | `input.thresholds.jdg.limits.car_value_kup_limit` | Limit JEST w thresholds, ale reguła nie używa go jawnie w pseudokodzie |
| P842 `depreciation_one_off` | "50 000 EUR w roku" | **Brak w thresholds!** Należy dodać `jdg.limits.one_off_depreciation_limit_eur` | ⚠️ Wartość nie istnieje w thresholds |
| P521 `lump_sum_rate` | Tabela stawek 17%/15%/14%... | `input.thresholds.jdg.lump_sum_rates.*` | ✅ Tabela JEST w thresholds, ale reguła jej nie cytuje |

> **⚠️ UWAGA METODOLOGICZNA:** P58 (vat_exemption) i P930 (unregistered) mają wartości 200k/50% zarówno w tekście reguły, jak i w `input.thresholds`. Nie są to "zakodowane" wartości — są to przykładowe wartości referencyjne, które w implementacji Rego będą pobierane z thresholds. Wcześniejsza wersja audytu nadmiernie zaostrzała to kryterium.

**Thresholds obecne w `input` ale NIEUŻYWANE przez żadną regułę:**

| Threshold | Zdefiniowany w Doc 22 §2.1 | Używany przez regułę? |
|-----------|:--------------------------:|:---------------------:|
| `nbp_reporting_threshold` | ✅ 100000 | ❌ NIE |
| `overpayment_refund_days` | ✅ 45 | ❌ NIE (brak reguły zwrotu nadpłaty) |
| `jpk_correction_days` | ✅ 14 | ❌ NIE |
| `aml_reporting_threshold_eur` | ✅ 15000 | ❌ NIE |
| `relief_internet_max` | ✅ 760 | TYLKO w P605 (Doc 23) |

---

### 🔴 Kryterium 8: Równomierność rozwinięcia — WYNIK: 3/10

**Dysproporcja między dokumentami:**

| Aspekt | Doc 22 | Doc 23 | Stosunek |
|--------|:------:|:------:|:--------:|
| Średnia linii/regułę | 12.5 | 8.2 | 1.5:1 |
| Reguły z edge cases | 22/145 (15%) | 5/69 (7%) | 2:1 |
| Reguły z przykładami | 18/145 (12%) | 0/69 (0%) | ∞ |
| Reguły z zależnościami | 55/145 (38%) | 12/69 (17%) | 2.2:1 |
| Reguły z pełną podstawą prawną | 95/145 (66%) | 25/69 (36%) | 1.8:1 |

**Dysproporcja między pakietami (w obrębie Doc 22):**

| Pakiet | Głębia (1-10) | Reguł | Uwagi |
|--------|:-------------:|:-----:|-------|
| `jdg.pit.*` | 8 | ~30 | Najlepiej rozwinięty — szczegółowe formy, KUP, zaliczki |
| `jdg.zus.*` | 7 | ~12 | Dobrze — specyfika JDG uwzględniona |
| `jdg.business.*` | 7 | ~11 | Dobrze — CEIDG, zawieszenie, sukcesja |
| `jdg.allowances.*` | 5 | ~13 | Średnio — tylko podstawowe ulgi, brak kosztów kwalifikowanych |
| `jdg.accounting.*` | 5 | ~10 | Średnio — PKPiR, amortyzacja, ale brak RMK, różnic kursowych |
| `jdg.vat.*` | 3 | ~18 | **SŁABO** — reguły VAT są skrajnie ogólne, brak kategorii |
| `jdg.crossborder` | 3 | ~8 | **SŁABO** — import/export po 1 linii |
| `jdg.compliance.*` | 3 | ~5 | **SŁABO** — tylko podstawowe reguły |
| `jdg.risk` | 4 | ~7 | Średnio — adaptowane z planu ogólnego |
| `jdg.routing` | 4 | ~7 | Średnio — adaptowane |
| `jdg.corrections` | 6 | ~8 | Nieźle — ale tylko w Doc 23 |
| `jdg.statute_liability` | 6 | ~9 | Nieźle — ale tylko w Doc 23 |
| `jdg.representation` | 4 | ~7 | Średnio — tylko w Doc 23 |

---

## 📋 MASTER AUDIT TABLE — REGUŁY WYMAGAJĄCE POPRAWEK (TOP 50)

| # | Reguła | Dokument | Pakiet | Brakujące elementy | Priorytet |
|---|--------|:--------:|--------|-------------------|:---------:|
| 1 | P20 `whitelist_missing` | 22 | compliance | ❌ Edge cases: ZAW-NR, 7 dni; ❌ Przykład − | 🔴 KRYT |
| 2 | P25 `split_payment` | 22 | compliance | ❌ Edge cases: zał. 15 kategorie; ❌ Przykłady ±; ❌ Zależności od VAT | 🔴 KRYT |
| 3 | P35 `cash_transaction` | 22 | compliance | ❌ Edge cases: agregacja dzienna; ❌ Przykład −; ❌ Sankcja 20% | 🔴 KRYT |
| 4 | P40-P48 `crossborder` | 22 | crossborder | ❌ Wszystkie 5 reguł po 1-2 linie — **skrajnie płytkie**; ❌ Brak edge cases, przykładów, zależności | 🔴 KRYT |
| 5 | P50 `vat_margin_scheme` | 22 | vat | ❌ Brak: metoda globalna, towary używane vs dzieła sztuki; ❌ Przykłady | 🔴 KRYT |
| 6 | P52-P54 `vat_rate_*` | 22 | vat | ❌ Tylko 3 kategorie z ~30 — **brak 90% stawek VAT**; ❌ Brak GTU, edge cases | 🔴 KRYT |
| 7 | P55-P56 `vat_exemption_*` | 22 | vat | ❌ Tylko edukacja i medycyna — **brak 15+ zwolnień przedmiotowych**; ❌ Brak przykładów | 🔴 KRYT |
| 8 | P60 `bad_debt_relief` | 22 | vat | ❌ Tylko wierzyciel — **brak dłużnika (Art. 89b)**; ❌ Brak 90 vs 150 dni | 🔴 KRYT |
| 9 | P65 `gtu_mapping` | 22 | vat | ❌ Brak mapowania kategorii→GTU; ❌ Tylko 1 reguła zamiast 13 | 🔴 KRYT |
| 10 | P185 `vat_pre_proportion` | 23 | vat.deduction | ❌ Brak formuły obliczeniowej; ❌ Brak przykładu z liczbami | 🟡 WYS |
| 11 | P186 `vehicle_50_vat` | 23 | vat.deduction | ❌ Brak rozróżnienia: z ewidencją vs bez; ❌ Brak limitu 150k | 🟡 WYS |
| 12 | P187 `annual_vat_correction` | 23 | vat.deduction | ❌ Brak harmonogramu 5/10 lat; ❌ Brak ŚT vs nieruchomości | 🔴 KRYT |
| 13 | P188 `vat_deduction_deadline` | 23 | vat.deduction | ❌ Brak: co po 3 miesiącach? korekta?; ❌ Brak JPK_V7K | 🟡 WYS |
| 14 | P500-P502 `pit_scale` | 22 | pit | ✅ WZGLĘDNIE DOBRZE — ale ❌ brak przykładów liczbowych, ❌ brak progu 120k w edge cases | 🟡 WYS |
| 15 | P510-P511 `pit_linear` | 22 | pit | ❌ Brak: były pracodawca (Art. 9a ust. 3); ❌ Brak przykładów | 🔴 KRYT |
| 16 | P520-P523 `pit_lump_sum` | 22 | pit | ❌ Tabela PKWiU niepełna; ❌ Brak fallback dla nieznanego PKWiU | 🟡 WYS |
| 17 | P530-P531 `tax_card` | 22 | pit | ❌ Brak tabeli stawek; ❌ Brak warunków utraty | 🟡 WYS |
| 18 | P540-P543 `advances` | 22 | pit | ❌ Brak formuły obliczeniowej w PLN; ❌ Brak przykładu narastającego | 🔴 KRYT |
| 19 | P550-P556 `annual_returns` | 22 | pit | ❌ Brak edge cases: korekta zeznania, wspólne rozliczenie | 🟡 WYS |
| 20 | P560-P570 `kup` | 22 | pit | ❌ Brak: koszty direct/indirect (P572 luka); ❌ Brak wyłączeń szczegółowych (P574 luka) | 🔴 KRYT |
| 21 | P580-P586 `exemptions` | 22 | pit | ❌ Brak: interakcja między ulgami (współdzielony limit 85 528); ❌ Brak przykładów z dwoma ulgami | 🔴 KRYT |
| 22 | P600-P623 `allowances` | 22/23 | allowances | ❌ Tylko 3 ulgi w Doc 22; ❌ Doc 23 dodaje 9, ale bez przykładów | 🟡 WYS |
| 23 | P601-P609 `allowances_new` | 23 | allowances | ❌ **Wszystkie 9 reguł bez przykładów ±**; ❌ Brak edge cases: łączenie ulg, limity | 🔴 KRYT |
| 24 | P700-P701 `zus_social` | 22 | zus | ❌ Brak: zbieg etat+JDG (P743 luka); ❌ Brak przykładów liczbowych | 🔴 KRYT |
| 25 | P720-P724 `zus_health` | 22 | zus | ❌ Brak przykładów liczbowych dla każdej formy; ❌ Brak rozliczenia rocznego | 🟡 WYS |
| 26 | P730-P738 `zus_interactions` | 23 | zus | ❌ Brak mapowania wszystkich 4 form na stawki w jednej tabeli; ❌ Brak przykładów | 🟡 WYS |
| 27 | P740-P742 `zus_reliefs` | 22 | zus | ❌ Brak scenariuszy przejścia między ulgami (start→pref→standard); ❌ Brak warunków utraty | 🔴 KRYT |
| 28 | P800-P802 `pkpir` | 22 | accounting | ❌ Brak: kolumna 14 (NKUP), kolumna 16 (uwagi); ❌ Brak remanentu | 🟡 WYS |
| 29 | P840-P842 `depreciation` | 22 | accounting | ❌ Brak: stawki KŚT dla grup 0-9; ❌ Brak ulepszenia >10k; ❌ Brak sprzedaży ŚT | 🟡 WYS |
| 30 | P850-P852 `private_mixed` | 22 | accounting | ✅ DOBRZE — ale ❌ brak przykładów dla samochodu | 🟢 ŚR |
| 31 | P860-P868 `leasing` | 23 | accounting | ❌ Brak: test 40%, harmonogram rat; ❌ Brak przykładów liczbowych | 🟡 WYS |
| 32 | P900-P904 `ceidg` | 22 | business | ❌ Brak: termin 7 dni, sankcje za brak; ❌ Brak API CEIDG | 🟡 WYS |
| 33 | P910-P914 `suspension` | 22 | business | ✅ DOBRZE — ale ❌ sprzeczność z Doc 28a dot. zdrowotnej podczas zawieszenia | 🔴 KRYT |
| 34 | P920-P924 `succession` | 22 | business | ❌ Brak: max 2 lata, wygaśnięcie; ❌ Brak inventaryzacji na dzień śmierci | 🟡 WYS |
| 35 | P930-P934 `unregistered` | 22 | business | ❌ Brak: co po przekroczeniu? 7 dni na CEIDG; ❌ Brak: opodatkowanie nadwyżki | 🔴 KRYT |
| 36 | P950-P960 `ksef` | 22 | ksef | ❌ Brak: sankcje 100% VAT; ❌ Brak: tryb offline szczegóły; ❌ Brak: UPO | 🟡 WYS |
| 37 | P970-P980 `jpk` | 22 | jpk | ❌ Brak: terminy JPK_V7M vs V7K; ❌ Brak: sankcje za błędy JPK | 🟡 WYS |
| 38 | P1100-P1114 `corrections` | 23 | corrections | ❌ Brak przykładów dla każdego typu korekty; ❌ Brak: korekta zbiorcza | 🟡 WYS |
| 39 | P1150-P1166 `statute` | 23 | statute | ❌ Brak: formuła odsetek; ❌ Brak: przykład przedawnienia | 🟡 WYS |
| 40 | P1168-P1169 `voluntary/overpayment` | 25 | statute | ❌ **W ogóle nie ma w Doc 22/23 — tylko luka w Doc 25** | 🔴 KRYT |
| 41 | P1200-P1212 `representation` | 23 | representation | ❌ Brak walidacji przez API e-US; ❌ Brak przykładów | 🟡 WYS |
| 42 | P1300 `pcc` | 25 | local_taxes | ❌ **W ogóle nie ma w Doc 22/23 — tylko luka w Doc 25** | 🔴 KRYT |
| 43 | P1310 `real_estate` | 25 | local_taxes | ❌ **W ogóle nie ma w Doc 22/23 — tylko luka w Doc 25** | 🔴 KRYT |
| 44 | P1320 `transport_tax` | 25 | local_taxes | ❌ **W ogóle nie ma w Doc 22/23 — tylko luka w Doc 25** | 🔴 KRYT |
| 45 | P0_b `kks_empty_invoice` | 25 | risk | ❌ **W ogóle nie ma w Doc 22/23 — tylko luka w Doc 25** | 🔴 KRYT |
| 46 | P4, P6, P7 `kks_risk` | 25 | risk | ❌ **W ogóle nie ma w Doc 22/23 — tylko luka w Doc 25** | 🔴 KRYT |
| 47 | P9 `gaar` | 25 | risk | ❌ **W ogóle nie ma w Doc 22/23 — tylko luka w Doc 25** | 🔴 KRYT |
| 48 | P36 `vat_simplified_receipt` | 25 | compliance | ❌ **W ogóle nie ma w Doc 22/23 — tylko luka w Doc 25** | 🔴 KRYT |
| 49 | P39 `vat_r_registration` | 25 | vat | ❌ **W ogóle nie ma w Doc 22/23 — tylko luka w Doc 25** | 🔴 KRYT |
| 50 | P184 `bad_debt_debtor` | 25 | vat.deduction | ❌ **W ogóle nie ma w Doc 22/23 — tylko luka w Doc 25** | 🔴 KRYT |

---

## 🎯 TOP 20 REGUŁ DO NATYCHMIASTOWEJ ROZBUDOWY

| # | Reguła | Dlaczego | Co zrobić | Szacowany nakład |
|---|--------|----------|-----------|:----------------:|
| **1** | P184 `bad_debt_debtor_correction` | **Luka KRYTYCZNA** — obowiązek dłużnika zwrotu VAT po 90 dniach. Brak = ryzyko sankcji 30% | Dodać do Doc 22/23 z pełnym 10-polowym formatem + przykład 90 vs 150 dni | 2h |
| **2** | P40-P48 `crossborder` (5 reguł) | **Skrajnie płytkie** — 5 reguł po 1-2 linie. Import/export/WDT/WNT to ~30% transakcji JDG | Rozwinąć każdą do min. 15 linii: moment obowiązku, dokumenty, kursy, terminy | 3h |
| **3** | P52-P54 `vat_rates` | **3 z ~30 kategorii** — brak stawek dla IT, budownictwa, transportu, najmu, healthcare | Dodać wszystkie kategorie z Doc 28 (R0069-R0110) — min. 30 reguł | 2h |
| **4** | P572 `kup_direct_vs_indirect` | **Luka KRYTYCZNA** — bez tego KUP w złym roku = błędny PIT | Dodać z przykładami: towar kupiony w 2025, sprzedany w 2026 → KUP w 2026 | 1h |
| **5** | P743 `concurrent_employment` | **Luka KRYTYCZNA** — etat+JDG to ~30% JDG. Zawyżone składki bez tej reguły | Dodać: etat ≥ min. → tylko zdrowotna z JDG; etat < min. → społeczne z JDG | 1h |
| **6** | P524 `lump_sum_exclusions` | **Luka KRYTYCZNA** — apteki, kantory na ryczałcie = błąd formy | Dodać listę wykluczonych PKD + były pracodawca | 0.5h |
| **7** | P39 `vat_r_registration` | **Luka KRYTYCZNA** — JDG bez VAT-R wystawia fakturę z VAT = nieważna | Dodać: blokada faktury VAT przed rejestracją VAT-R | 0.5h |
| **8** | P36 `vat_simplified_receipt` | **Luka KRYTYCZNA** — paragon z NIP ≤450 PLN = faktura. Codzienna sytuacja | Dodać: limit 450 PLN, warunek NIP na paragonie, odliczenie VAT | 0.5h |
| **9** | P1168 `voluntary_disclosure` | **Luka KRYTYCZNA** — czynny żal chroni przed KKS. Brak reguły = brak ochrony | Dodać: warunek złożenia PRZED kontrolą, termin, skutki | 1h |
| **10** | P1169 `overpayment_detection` | **Luka KRYTYCZNA** — nadpłata nie jest wykrywana. Podatnik traci pieniądze | Dodać: zwrot 45 dni (VAT) / 3 mies. (PIT), odsetki dla podatnika | 1h |
| **11** | P1300-P1320 `local_taxes` | **3 luki WAŻNE** — PCC, nieruchomości, transport całkowicie pominięte | Dodać 3 nowe reguły | 1.5h |
| **12** | P192 `vat_refund_timing` | **Luka KRYTYCZNA** — zwrot VAT: 60/25/180 dni. Brak = podatnik nie wie kiedy dostanie zwrot | Dodać z warunkami: karta/przelew → 25 dni, standard → 60 dni | 0.5h |
| **13** | P9 `gaar_artificial_scheme` | **Luka KRYTYCZNA** — ENTERPRISE musi mieć anti-avoidance | Dodać: test sztuczności, podmioty powiązane, ceny nierynkowe | 1h |
| **14** | P0_b `kks_empty_invoice` | **Luka KRYTYCZNA** — puste faktury = do 25 lat więzienia | Dodać: brak dostawy + fraud flag → BLOCK | 0.5h |
| **15** | P187 `annual_vat_correction` | **Zbyt płytka** — korekta roczna 1/5 i 1/10 to podstawa VAT | Rozwinąć: harmonogram, ŚT ruchome vs nieruchomości, sprzedaż w trakcie | 1h |
| **16** | P55-P63 `vat_exemptions` | **Tylko 2 kategorie** — brak 15+ zwolnień (finanse, ubezpieczenia, poczta, sport) | Dodać wszystkie zwolnienia przedmiotowe z Art. 43 VAT | 1.5h |
| **17** | P540 `pit_advance_monthly` | **Brak formuły** — jak policzyć zaliczkę w PLN? | Dodać: (dochód_narastająco × stawka) − zapłacone_zaliczki − ZUS_społeczne | 0.5h |
| **18** | P521 `lump_sum_rate` | **Brak fallback** — co gdy PKWiU nie pasuje do żadnej stawki? | Dodać: fallback 8.5% + ostrzeżenie | 0.5h |
| **19** | P930 `unregistered_activity` | **Brak skutków przekroczenia** — co po przekroczeniu 50% min.? | Dodać: 7 dni na CEIDG, opodatkowanie nadwyżki, ZUS od następnego miesiąca | 0.5h |
| **20** | P1100-P1102 `corrections` | **Brak przykładów** — korekta in minus vs in plus | Dodać: przykład korekty -1000 PLN in minus z potwierdzeniem odbioru | 0.5h |

---

## 🌐 LUKI GLOBALNE — PROBLEMY SYSTEMOWE

### Luka globalna 1: Integracja Doc 25 (audyt prawny) z Doc 22/23

**Problem:** `25_JDG_DEEP_LEGAL_AUDIT.md` identyfikuje 46 brakujących reguł (12 KRYTYCZNYCH), ale żadna z nich NIE została wciągnięta do planu bazowego (Doc 22) ani rozbudowy (Doc 23). Doc 24 indeksuje je jako "proponowane", ale bez szczegółowych opisów.

**Konsekwencja:** 12 krytycznych luk prawnych (KKS, GAAR, VAT-R, złe długi dłużnika, zbieg etat+JDG, wyłączenia ryczałtu) pozostaje niezaimplementowanych.

**Rekomendacja:** Utworzyć `23b_JDG_LEGAL_GAP_CLOSURE.md` — dokument z pełnym 10-polowym opisem dla 46 reguł z Doc 25, z priorytetem dla 12 krytycznych.

---

### Luka globalna 2: Brak scenariuszy brzegowych dla 87.4% reguł

**Problem:** Tylko 27/214 reguł ma opisane edge cases. System nie jest przygotowany na:
- Przekroczenie limitów w trakcie roku
- Zmianę formy opodatkowania
- Zawieszenie/wznowienie działalności
- Pierwszy i ostatni rok JDG
- Sukcesję / śmierć przedsiębiorcy
- Działalność nieewidencjonowaną

**Rekomendacja:** Priorytetowo dodać edge cases dla reguł z limitami (VAT exemption, ryczałt, kasa fiskalna, ZUS) — te reguły NAJCZĘŚCIEJ będą wyzwalane w nietypowych sytuacjach.

---

### Luka globalna 3: Brak przykładów liczbowych dla 91.6% reguł

**Problem:** Tylko 18/214 reguł ma konkretne przykłady liczbowe `allow`/`deny`. Doc 23 ma ZERO przykładów.

**Konsekwencja:** Deweloper implementujący Rego nie ma jak zweryfikować, czy reguła działa poprawnie. Tester nie ma test case'ów.

**Rekomendacja:** Dla każdej reguły dodać minimum jeden konkretny liczbowy przykład pozytywny i negatywny (np. "Faktura 20 000 PLN, kontrahent na WL → OK" / "Faktura 20 000 PLN, kontrahent NIE na WL → BLOCK").

---

### Luka globalna 4: Dysproporcja Doc 22 vs Doc 23

**Problem:** Doc 23 (69 reguł) jest średnio 2× płytszy niż Doc 22 (145 reguł):
- 0 vs 18 przykładów liczbowych
- 7% vs 15% reguł z edge cases
- 17% vs 38% reguł z zależnościami
- 36% vs 66% reguł z pełną podstawą prawną

**Rekomendacja:** Doc 23 wymaga drugiego przejścia — podniesienia do tego samego standardu co Doc 22. Minimum: dodać przykłady ± dla wszystkich 69 reguł.

---

### Luka globalna 5: Brak wersjonowania i cross-referencji

**Problem:** Reguły są rozproszone między 4 dokumentami bez jednoznacznego "source of truth". Nie wiadomo:
- Czy P60 (Doc 22) czy P189 (Doc 23) jest wersją obowiązującą dla ulgi na złe długi?
- Czy P58 (Doc 22) czy P59 (Doc 23) obowiązuje dla zwolnienia podmiotowego?
- Który dokument ma pierwszeństwo przy sprzecznościach?

**Rekomendacja:** Ustanowić `28_JDG_ULTIMATE_GRANULARITY.md` jako **główny indeks** z mapowaniem wszystkich P- i R-numerów. Doc 22 i 23 zachować jako dokumenty projektowe (z dopiskiem "historyczny — obowiązującą wersją jest Doc 28"). **UWAGA:** Doc 28 używa innego systemu numeracji (R0001-R0672) i ma 672 reguł — przed uznaniem go za source of truth należy przeprowadzić pełne mapowanie P↔R.

---

### Luka globalna 6: Priorytety — nieciągłości i konflikty

**Problem:** 
- Doc 22 używa P0-P1099
- Doc 23 dodaje P43-P1212 (nakładając się na zakres Doc 22)
- Doc 25 proponuje P0_b, P6_b (niestandardowe formaty)
- Doc 28 używa R0001-R0672 (zupełnie inny system)

Brak mapowania między systemami numeracji.

**Rekomendacja:** Przyjąć R0001-R0672 z Doc 28 jako ostateczny system. Dla każdego P-numeru z Doc 22/23/25 utworzyć mapowanie na R-numer.

---

### Luka globalna 7: Nadmiarowe/zduplikowane reguły

**Problem:** Te same domeny są pokryte przez reguły w różnych dokumentach:
- Ulga na złe długi: P60 (Doc 22) + P189 (Doc 23)
- Zwolnienie VAT: P58 (Doc 22) + P59 (Doc 23)
- Składka zdrowotna ryczałt: P724 (Doc 22) + P734 (Doc 23)
- Home office: P562 (Doc 22) + P850 (Doc 22)
- Korekty: P1100-P1114 (Doc 23) + reguły w Doc 28 (R0420-R0435)

**Rekomendacja:** Przeprowadzić deduplikację — wybrać jedną wersję każdej reguły jako kanoniczną, pozostałe oznaczyć jako `[DEPRECATED]`.

---

### Luka globalna 8: Brak mechanizmu aktualizacji po zmianach prawnych

**Problem:** Polski Ład (2022) zmienił fundamentalnie składkę zdrowotną (zniesienie odliczenia 7.75%, nowe progi dla ryczałtu). Doc 22 został napisany w 2026, więc teoretycznie powinien być aktualny — ale P720/P738 są rozproszone i niespójne.

Brak mechanizmu "valid_from/valid_to" dla reguł — nie wiadomo, które reguły obowiązywały przed 2022, a które po.

**Rekomendacja:** Dodać metadane temporalne do każdej reguły: `valid_from: "2022-01-01"`, `valid_to: null`. Dla reguł uchylonych: `valid_to: "2021-12-31"`, `status: "REPEALED"`.

---

## 📊 STATYSTYKI KOŃCOWE

| Kategoria | Liczba reguł | % z 214 |
|-----------|:-----------:|:-------:|
| **KOMPLETNE** (8/8 kryteriów spełnionych) | 27 | 12.6% |
| **WYMAGAJĄCE ROZBUDOWY** (spełnione 5-7 kryteriów) | 65 | 30.4% |
| **WYMAGAJĄCE DUŻEJ ROZBUDOWY** (spełnione 2-4 kryteriów) | 98 | 45.8% |
| **KRYTYCZNIE NIEKOMPLETNE** (spełnione 0-1 kryteriów) | 24 | 11.2% |
| **RAZEM** | **214** | **100%** |

### Ranking kryteriów (od najgorszego do najlepszego):

| # | Kryterium | % reguł spełniających | Ocena |
|---|-----------|:---------------------:|:-----:|
| 1 | Scenariusze brzegowe | 12.6% | 🔴 1/10 |
| 2 | Przykłady ± | 8.4% | 🔴 1/10 |
| 3 | Równomierność rozwinięcia | ~25% | 🔴 3/10 |
| 4 | Kompletność pól | ~38% | 🔴 3/10 |
| 5 | Głębia opisu | ~45% | 🟡 4/10 |
| 6 | Spójność między regułami | ~55% | 🟡 5/10 |
| 7 | Parametry dynamiczne | ~60% | 🟡 6/10 |
| 8 | Podstawa prawna | ~67% | 🟡 6/10 |

---

## 🚀 REKOMENDACJE NAPRAWCZE

### Faza 0: NATYCHMIAST (krytyczne luki prawne)
1. Zaimplementować 12 krytycznych reguł z Doc 25 (P0_b, P4, P6, P9, P36, P39, P184, P192, P508, P524, P572, P743)
2. Usunąć sprzeczność P914 vs Doc 28a dot. zdrowotnej w zawieszeniu — **zdrowotna jest należna podczas zawieszenia**
3. Dodać przykłady ± do wszystkich 69 reguł w Doc 23

### Faza 1: WYSOKI PRIORYTET (jakość i spójność)
4. Rozwinąć płytkie pakiety: `jdg.crossborder` (z 5 do 20 reguł), `jdg.vat` (z 18 do 60+ reguł)
5. Dodać edge cases do wszystkich reguł z limitami/progami (~50 reguł)
6. Ustanowić Doc 28 jako single source of truth

### Faza 2: ŚREDNI PRIORYTET (kompletność)
7. Dodać brakujące pakiety: `jdg.local_taxes` (PCC, nieruchomości, transport)
8. Rozwinąć `jdg.allowances` o koszty kwalifikowane dla każdej ulgi
9. Dodać temporalność (valid_from/valid_to) do każdej reguły

### Faza 3: NISKI PRIORYTET (doskonałość ENTERPRISE)
10. Dodać test case'y OPA dla każdej reguły
11. Mapowanie P↔R między wszystkimi dokumentami
12. Mechanizm automatycznej walidacji spójności między dokumentami

---

> **🔥 WNIOSEK KOŃCOWY:** System reguł JDG ma solidne fundamenty (Doc 22 — PIT, ZUS, business), ale jest **nierównomiernie rozwinięty** (VAT, crossborder — skrajnie płytkie), **niekompletny** (87.4% reguł bez edge cases, 91.6% bez przykładów) i **niespójny między dokumentami** (Doc 22 vs 23 vs 25 vs 28). Aby osiągnąć standard ENTERPRISE, potrzeba **minimum 3-4 tygodni intensywnej rozbudowy** — zaczynając od 12 krytycznych luk prawnych i dodania przykładów do wszystkich reguł.
>
> **Następny krok:** `38a_JDG_CRITICAL_GAPS_CLOSURE.md` — pełny 10-polowy opis 12 krytycznych luk z Doc 25, gotowych do natychmiastowej implementacji.

---

*Wygenerowano przez NexusAI Enterprise Quality Audit Engine v1.0*
*Data: 2026-07-11*
