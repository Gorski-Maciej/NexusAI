# 🔬 Głęboki Audyt Jakościowy — Dokumenty 22–25 JDG ENTERPRISE

> **Status:** ENTERPRISE Quality Audit v1.0  
> **Data:** 2026-07-12  
> **Autor:** Zespół NexusAI  
> **Plik wynikowy:** `Plan OPA/46_JDG_QUALITY_AUDIT.md`  
> **Dokumenty audytowane:**  
> — `22_JDG_ENTERPRISE_PLAN.md` — plan bazowy (~145 reguł)  
> — `23_JDG_EXPANSION_SUPPLEMENT.md` — rozszerzenia (~69 reguł)  
> — `24_JDG_COMPLETE_INDEX.md` — indeks kompletny (~214 reguł + 46 proponowanych)  
> — `25_JDG_DEEP_LEGAL_AUDIT.md` — audyt prawny (46 luk)  
> **Cel:** Audyt jakościowy, nie dodawanie nowych reguł. Każda reguła sprawdzona pod kątem 8 kryteriów ENTERPRISE.

---

## 📊 1. PODSUMOWANIE OGÓLNE

### Ocena ogólna: ⚠️ **UMIARKOWANA** (5.8/10)

Plan JDG posiada solidną architekturę (first-match-wins, parametryzacja, struktura pakietów), ale **jakość opisów poszczególnych reguł jest bardzo nierówna**. Główne problemy:

| Problem | Dotkliwość | Reguł dotkniętych |
|---------|:----------:|:-----------------:|
| **Brak przykładów ±** | 🔴 KRYTYCZNY | ~210/214 (98%) |
| **Brak scenariuszy brzegowych** | 🔴 KRYTYCZNY | ~200/214 (93%) |
| **Zakodowane wartości liczbowe** | 🟡 WAŻNY | ~35/214 (16%) |
| **Niespójna głębokość opisów** | 🟡 WAŻNY | ~80/214 (37%) |
| **Brak pól temporalnych** | 🟡 WAŻNY | ~210/214 (98%) |
| **Duplikacje i deprecjacje** | 🟡 WAŻNY | 47 reguł zdeprecjonowanych |
| **Niepełne podstawy prawne** | 🟢 ŚREDNI | ~25/214 (12%) |
| **Brak zależności między regułami** | 🟢 ŚREDNI | ~150/214 (70%) |

### Statystyki kompletności

| Poziom | Liczba reguł | % |
|--------|:-----------:|:--:|
| **KOMPLETNE** (8/8 pól) | **0** | 0% |
| **PRAWIE KOMPLETNE** (6-7/8 pól) | **~12** | 5.6% |
| **ŚREDNIE** (4-5/8 pól) | **~120** | 56.1% |
| **SŁABE** (2-3/8 pól) | **~70** | 32.7% |
| **SZKIELETOWE** (1 pole) | **~12** | 5.6% |

### Statystyki dokumentów

| Dokument | Reguł | Śr. ocena | Najlepszy pakiet | Najsłabszy pakiet |
|----------|:-----:|:---------:|------------------|-------------------|
| **Doc 22** | ~145 | 6.0 | `jdg.business.*` | `jdg.retention` |
| **Doc 23** | ~69 | 6.2 | `jdg.statute_liability` | `jdg.representation` |
| **Doc 24** | — | n/d (indeks) | — | — |
| **Doc 25** | 46 (propozycje) | 7.8 | Wszystkie | — |

> **Kluczowa obserwacja:** Paradoksalnie, najlepiej opisane reguły znajdują się w **Dokumencie 25** (audyt prawny), który jest dokumentem *diagnostycznym*, a nie implementacyjnym. Proponowane tam reguły mają pełną strukturę z przesłankami, rezultatem, podstawą prawną i ostrzeżeniami — czego brakuje większości reguł w dokumentach 22 i 23.

---

## 2. TABELA AUDYTU — WSZYSTKIE REGUŁY Z BRAKAMI

### Legenda priorytetów

| Symbol | Znaczenie |
|:------:|-----------|
| 🔴 | **KRYTYCZNY** — reguła niespełnia podstawowych standardów ENTERPRISE |
| 🟡 | **WYSOKI** — poważny brak utrudniający implementację lub audyt |
| 🟢 | **ŚREDNI** — istotny brak, ale nie blokujący |
| ⚪ | **NISKI** — kosmetyczny / nice-to-have |

---

### 2.1 DOC 22 — Pakiet `jdg.risk` (P0-P9)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P0** `fraud_graph_match` | Brak przykładów ±, brak edge case (false positive), brak zależności od FraudGraphScanner | Dodać: przykład faktury z `fraud_flag=true`, edge case gdy fraud_flag zmienia się po fakcie, zależność od `FraudGraphScanner.update_timestamp` | 🟡 |
| **P1** `counterparty_trust_low` | Brak przykładów ±, `trust_score=0` (nowy, brak danych) nie jest obsłużone jako edge case | Dodać: przykład `trust_score=0.72 → TRIAGE`, edge case `trust_score=0` (nowy kontrahent) → `TRIAGE` z adnotacją | 🟡 |
| **P2** `anomaly_amount` | Brak przykładów ±, brak definicji `category_avg` i `category_stddev` (skąd pochodzą?), brak progu σ | Dodać: parametry `anomaly_sigma_threshold` do `input.thresholds`, przykład kwoty 50 000 PLN gdy średnia kategorii = 2000 PLN | 🟡 |
| **P3** `new_counterparty_flag` | Brak przykładów ±, brak rozróżnienia "nowy kontrahent" vs "pierwsza transakcja z istniejącym" | Dodać: definicję "nowy" (np. < 3 transakcje w historii), przykład negatywny dla kontrahenta z 5 transakcjami | 🟢 |
| **P5** `semantic_guard_disallowed` | **Zakodowana lista kategorii** `["ALCOHOL", "ENTERTAINMENT", "LUXURY"]` w opisie — powinna być w `input.thresholds.jdg.disallowed_categories` | Przenieść listę do thresholds; dodać przykład "okulary korekcyjne" (dopuszczalne BHP) vs "okulary przeciwsłoneczne" (niedopuszczalne) | 🔴 |
| **P8** `ceidg_vendor_suspended` | Brak przykładów ±, brak obsługi przypadku `vendor.ceidg_status == "UNKNOWN"` | Dodać: przykład kontrahenta z `SUSPENDED` od 2026-03-01, faktura z 2026-06-15 → BLOCK; edge case `UNKNOWN` → `TRIAGE_QUEUE` z ostrzeżeniem | 🟡 |

### 2.2 DOC 22 — Pakiet `jdg.routing` (P10-P19)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P10** `fc_vat_rate_low_scale` | Brak przykładów ±, próg `0.95` zakodowany w tekście (choć w `input` jest `pit_scale_vat_rate`) | Dodać: przykład `fc_vat_rate=0.91 < 0.95 → BLOCK`, przykład `fc_vat_rate=0.97 → OK` | 🟢 |
| **P11** `fc_total_net_low_scale` | j.w. — brak przykładów | Dodać przykłady ± | 🟢 |
| **P12** `fc_vendor_nip_low` | Brak przykładów ±, brak rozróżnienia NIP=0 (jeszcze nie OCR) vs NIP=niska pewność | Dodać edge case: `fc_vendor_nip=0` → `SKIP_VERIFICATION` (nie oceniono jeszcze) vs `fc_vendor_nip=0.72` → `BLOCK` | 🟡 |
| **P14** `fc_linear_minimum` | Brak przykładów ± | Dodać przykłady | 🟢 |
| **P15** `fc_lump_sum_vat_rate` | Brak przykładów ±, komentarz "ryczałtowcy często nie odliczają VAT" — ale to nie zawsze prawda (czynny VAT + ryczałt istnieje) | Dodać rozróżnienie: ryczałtowiec czynny VAT vs zwolniony; przykłady ± | 🟡 |
| **P16** `fc_lump_sum_total_net` | Próg `0.60` zakodowany w opisie, brak przykładów ± | Przenieść do thresholds; dodać przykłady | 🟢 |
| **P19** `fc_global_minimum_low` | Brak przykładów ±, próg `0.70` zakodowany | Przenieść do thresholds; dodać przykłady | 🟢 |

### 2.3 DOC 22 — Pakiet `jdg.compliance` (P20-P39)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P20** `whitelist_missing_over_limit` | **Próg 15 000 PLN zakodowany** jako `mpp_limit` — ale nazwa sugeruje limit MPP, nie limit weryfikacji białej listy. Brak przykładów ±, brak edge case dla `whitelist_checked_at` starszego niż 30 dni | Dodać osobny `whitelist_verification_limit` w thresholds; dodać regułę wygaśnięcia weryfikacji białej listy po 30 dniach; przykłady ± | 🔴 |
| **P21** `whitelist_account_mismatch` | Brak przykładów ±, brak obsługi przypadku wielu rachunków kontrahenta (jeden zgodny, drugi nie) | Dodać: przykład `account_on_whitelist=false`, edge case wielorachunkowy | 🟡 |
| **P25** `split_payment_mandatory` | **"Kategoria wrażliwa MPP"** — nieokreślona! Które kategorie? Brak listy w thresholds. Brak przykładów ± | Dodać `mpp_sensitive_categories` do thresholds (załącznik nr 15 VAT); przykłady ± | 🔴 |
| **P35** `cash_transaction_over_limit` | **Próg 15 000 PLN** używa `cash_transaction_limit` — OK. Ale brak przykładów ±, brak edge case dla płatności częściowo gotówkowej | Dodać przykład: 15 500 PLN gotówką → NKUP; edge case: 10 000 PLN gotówką + 5 500 PLN przelewem → czy limit liczony łącznie? | 🟡 |

### 2.4 DOC 22 — Pakiet `jdg.crossborder` (P40-P49)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P40** `eu_reverse_charge` | ⚠️ **ZDEPRECJONOWANA** → zastąpiona przez P43 (Doc 23). Brak linku do kanonicznej wersji. | Oznaczyć jako `[DEPRECATED]` z linkiem: `→ P43 w 23_JDG_EXPANSION_SUPPLEMENT.md` | 🟡 |
| **P41** `eu_import_services` | ⚠️ **ZDEPRECJONOWANA** → zastąpiona przez P44 (Doc 23) | Oznaczyć jako `[DEPRECATED]` z linkiem: `→ P44 w 23_JDG_EXPANSION_SUPPLEMENT.md` | 🟡 |
| **P42** `wdt_intracommunity_supply` | ⚠️ **ZDEPRECJONOWANA** → zastąpiona przez P46 (Doc 23) | Oznaczyć jako `[DEPRECATED]` z linkiem: `→ P46 w 23_JDG_EXPANSION_SUPPLEMENT.md` | 🟡 |
| **P45** `import_non_eu` | ⚠️ **ZDEPRECJONOWANA** → zastąpiona przez P47 (Doc 23) | Oznaczyć jako `[DEPRECATED]` z linkiem: `→ P47 w 23_JDG_EXPANSION_SUPPLEMENT.md` | 🟡 |
| **P48** `export_goods` | ⚠️ **ZDEPRECJONOWANA** → zastąpiona przez P49 (Doc 23) | Oznaczyć jako `[DEPRECATED]` z linkiem: `→ P49 w 23_JDG_EXPANSION_SUPPLEMENT.md` | 🟡 |
| **P43** `vat_ue_registration_mandatory` | Brak przykładów ±, **lista EU_COUNTRIES zakodowana** (powinna być w thresholds jako `eu_member_states`) | Przenieść listę krajów UE do `input.thresholds.jdg.lists.eu_member_states`; przykłady ± | 🔴 |

### 2.5 DOC 22 — Pakiet `jdg.vat.*` (P50-P69)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P50** `vat_margin_scheme` | **Stawka "0.23" zakodowana** — ale marża nie zawsze = 23%! Zależy od towaru. Brak przykładów ± | Poprawić: stawka VAT od marży = stawka właściwa dla danego towaru (np. książki → 5% od marży); przykłady ± | 🔴 |
| **P52** `vat_rate_fuel_pl` | Opis skrajnie minimalistyczny (jedna linijka w tabeli). **Brak:** celu biznesowego (3-5 zdań), przesłanek, przykładów, edge case (paliwo lotnicze? opał?). | Rozbudować do pełnego formatu ENTERPRISE | 🔴 |
| **P53** `vat_rate_food_pl` | j.w. — minimalistyczny, brak rozróżnienia żywność podstawowa vs przetworzona vs catering | Rozbudować; dodać listę PKWiU dla 5% żywności w thresholds | 🔴 |
| **P54** `vat_rate_books_pl` | j.w. — brak rozróżnienia książka drukowana vs e-book (różne stawki!) | Dodać: e-book na nośniku fizycznym → 5%, e-book do pobrania → 23% | 🟡 |
| **P55** `vat_exemption_education` | Brak przykładów ±, brak rozróżnienia usługi edukacyjne zwolnione vs szkolenia zawodowe (opodatkowane) | Dodać przykłady: korepetycje z matematyki → zw; szkolenie korporacyjne Excel → 23% | 🟡 |
| **P56** `vat_exemption_healthcare` | Brak przykładów ±, brak rozróżnienia usługa medyczna vs usługa kosmetyczna | Dodać: wizyta lekarska → zw; botoks → 23% | 🟡 |
| **P58** `vat_exemption_subject_jdg` | ⭐ **NAJLEPIEJ OPISANA REGUŁA VAT** — ma szczegółowe przesłanki, zależności, proporcję. ALE: brak przykładu z konkretnymi liczbami. | Dodać przykład: JDG rozpoczęta 1 lipca 2026, obrót do końca roku = 80 000 PLN → proporcjonalny limit = (184/365) × 200 000 ≈ 100 822 PLN → 80 000 < limit → ZWOLNIONA | 🟢 |
| **P60** `vat_bad_debt_relief` | ⚠️ **ZDEPRECJONOWANE** — ale tekst deprecjacji błędnie mówi "150 dni dla wierzyciela VAT". Powinno być: 150 dni od terminu płatności dla ulgi na złe długi (art. 89a VAT znowelizowany SLIM VAT 3). | Poprawić adnotację deprecjacyjną | 🟡 |
| **P65** `gtu_mapping_by_category` | Opis minimalistyczny. Brak pełnej tabeli mapowania w thresholds. | Dodać `gtu_category_map` do thresholds z kompletnym mapowaniem kategoria→GTU | 🟡 |

### 2.6 DOC 22 — Pakiet `jdg.vat.tax_point` (P230-P235)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P230-P231, P235** | ⚠️ **ZDEPRECJONOWANE** — zastąpione przez Doc 28a, ale nadal obecne | Oznaczyć wyraźniej, dodać link do R0546-R0559 | 🟢 |

### 2.7 DOC 22 — Pakiet `jdg.pit.form_scale` (P500-P502)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P500** `pit_form_scale` | ⭐ Dobrze opisana. Brakuje: przykładów ±, edge case dla dochodów bliskich progowi (119 999 vs 120 001) | Dodać przykład: dochód 85 000 PLN → 12% + kwota wolna 30k = podatek około 6 180 PLN; dochód 130 000 PLN → 12% od 120k + 32% od 10k = 14 400 + 3 200 - 3 600 = 14 000 PLN | 🟢 |
| **P501** `pit_scale_bracket_determination` | Próg 120 000 PLN używa `pit_scale_threshold` — OK. Brak przykładów ± | Dodać przykłady z konkretnymi kwotami | 🟢 |
| **P502** `pit_scale_joint_filing` | **2×120 000 = 240 000 zakodowane** w opisie. Brak edge case: co gdy małżonek ma dochody z etatu? | Dodać: wspólne rozliczenie możliwe tylko gdy oboje na skali; nie działa z liniowym/ryczałtem | 🟡 |

### 2.8 DOC 22 — Pakiet `jdg.pit.form_linear` (P510-P511)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P510** `pit_form_linear` | ⭐ Dobrze opisana z blokadami ulg. Brak: przykładów ±, edge case dla byłego pracodawcy (P512) — powinna być zależność | Dodać zależność od P512; przykład: programista na B2B z byłym pracodawcą → NIE może być na liniowym dla tego klienta | 🟡 |
| **P511** `pit_linear_no_tax_free_amount` | Minimalistyczna. Brak przykładu ilustrującego różnicę vs skala | Dodać porównanie: dochód 80 000 PLN — skala: ~6 180 PLN podatku; liniowy: 15 200 PLN podatku | 🟢 |

### 2.9 DOC 22 — Pakiet `jdg.pit.form_lump_sum` (P520-P523)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P520** `pit_form_lump_sum` | Brak przykładów ±, brak zależności od P524 (wyłączenia z ryczałtu) | Dodać zależność od P524; przykład: JDG IT, PKWiU 62.01.Z → stawka ryczałtu 14% od przychodu | 🟡 |
| **P521** `lump_sum_rate_by_pkwiu` | **Tabela stawek zakodowana** w `input.thresholds.jdg.lump_sum_rates.*` — to jest DOBRZE! Ale brak przykładów ± | Dodać przykład: faktura za software development, PKWiU 62.01.Z → 14%; faktura za hosting, PKWiU 63.11.Z → 12% | 🟢 |
| **P522** `lump_sum_multiple_rates` | ⚠️ **Brak faktycznej logiki** — reguła tylko stwierdza `lump_sum_multi_rate: true` ale nie mówi JAK rozdzielać przychody. | Dodać algorytm: dla każdej faktury sprawdź PKWiU → przypisz stawkę → agreguj wg stawek | 🟡 |
| **P523** `lump_sum_annual_limit` | **2 000 000 EUR zakodowane** — powinno być przeliczone na PLN wg kursu. Brak przykładu ± | Dodać: `lump_sum_limit_eur: 2000000` do thresholds; przelicznik: kurs NBP z 1 października poprzedniego roku | 🔴 |

### 2.10 DOC 22 — `jdg.pit.form_tax_card` (P530-P531)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P530** `pit_form_tax_card` | Brak pełnej tabeli stawek (Załącznik nr 3), **termin "7. dnia" zakodowany**, brak przykładów ± | Przenieść tabelę stawek do `input.thresholds.jdg.tax_card_rates`; dodać przykłady | 🟡 |
| **P531** `tax_card_decision_valid` | Minimalistyczna — tylko sprawdza czy data != null. Brak walidacji numeru decyzji | Dodać walidację formatu numeru decyzji US | 🟢 |

### 2.11 DOC 22 — `jdg.pit.advances` (P540-P543)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P540** `pit_advance_monthly` | **"Do 20. dnia" zakodowane**, brak przykładów ±, niejasna formuła obliczeniowa | Przenieść `pit_advance_due_day: 20` do thresholds; dodać przykład z konkretnymi liczbami (dochód narastająco, zapłacone zaliczki, ZUS) | 🔴 |
| **P541** `pit_advance_zus_social_deduction` | Brak przykładu liczbowego | Dodać przykład: dochód 8 000 PLN, zapłacone składki społeczne 1 600 PLN → zaliczka od 6 400 PLN | 🟢 |
| **P542** `pit_advance_quarterly` | "Do 20. dnia miesiąca po kwartale" — OK, ale brak warunku: mały podatnik + zgłoszenie do US | Dodać przesłankę: złożone oświadczenie o kwartalnych zaliczkach (art. 44 ust. 3g PIT) | 🟡 |
| **P543** `pit_advance_simplified` | **"1/12 podatku z roku poprzedniego"** — nie precyzuje który rok (poprzedni czy dwa lata wstecz?) | Dodać szczegóły: podatek z PIT-36/PIT-36L za rok N-2 (jeśli N-1 nie było zeznania); powiadomienie US do 20 lutego | 🟡 |

### 2.12 DOC 22 — `jdg.pit.annual_returns` (P550-P556)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P550** `pit_annual_return_pit36` | **Termin "30 kwietnia" zakodowany**, brak przykładów | Dodać `pit36_deadline_mm_dd: "04-30"` do thresholds; przykład | 🟡 |
| **P552** `pit_annual_return_pit36l` | j.w. | Dodać `pit36l_deadline_mm_dd: "04-30"` do thresholds | 🟡 |
| **P554** `pit_annual_return_pit28` | **Termin "28 lutego" zakodowany** (wcześniejszy niż PIT-36!). Brak przykładów | Dodać `pit28_deadline_mm_dd: "02-28"` do thresholds; podkreślić w przykładzie że to WCZEŚNIEJSZY termin niż PIT-36 | 🟡 |
| **P556** `pit_annual_return_overdue` | Brak rozróżnienia konsekwencji: PIT-36 po terminie vs PIT-28 po terminie (różne sankcje) | Dodać KKS reference (art. 77 § 1 KKS) | 🟢 |

### 2.13 DOC 22 — `jdg.pit.kup` (P560-P570)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P560** `kup_full_deductible` | Opis ogólnikowy "Wydatek związany z działalnością" — co to znaczy? Brak przykładów ± | Dodać definicję związku z działalnością; przykład: zakup laptopa dla programisty → KUP 100%; zakup konsoli do gier → NKUP | 🟡 |
| **P561** `kup_zus_social_deductible` | Brak przykładów liczbowych | Dodać przykład: zapłacone składki społeczne 1 600 PLN/mies. → rocznie 19 200 PLN KUP | 🟢 |
| **P562** `kup_private_mixed_jdg` | Dobry opis. Brak przykładów liczbowych | Dodać: telefon 100 PLN/mies., użytek firmowy 70% → KUP 70 PLN | 🟢 |
| **P564** `kup_car_over_150k_limit` | **150 000 zakodowane w opisie** (mimo że `car_value_kup_limit` istnieje w thresholds). Brak przykładów ± | Użyć `input.thresholds.jdg.limits.car_value_kup_limit` w przykładzie; przykład: auto 200 000 PLN → KUP proporcja = 150 000/200 000 = 75% | 🔴 |
| **P566** `kup_representation_none` | Minimalistyczna. Brak definicji "reprezentacji" — co nią jest, a co nie? | Dodać listę: alkohol na spotkanie z klientem → NKUP; woda/mineralna → KUP (poczęstunek, nie reprezentacja) | 🟡 |
| **P568** `kup_unpaid_zus_social` | Brak przykładu czasowego | Dodać: składki za grudzień zapłacone 10 stycznia → KUP dopiero w styczniu | 🟢 |
| **P570** `kup_health_contrib_linear_deduction` | **Limit 12 900 PLN zakodowany** mimo że `zus_health_linear_deduction_limit` istnieje. Brak przykładów | Użyć thresholdu; przykład: zapłacona składka zdrowotna 15 000 PLN/rok → odliczenie limitowane do 12 900 PLN | 🔴 |

### 2.14 DOC 22 — `jdg.pit.exemptions` (P580-P586)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P580** `pit_exemption_young` | **Wiek "26" zakodowany**, limit 85 528 PLN z thresholds (OK). Brak przykładu | Dodać `young_exemption_max_age: 26` do thresholds; przykład: 24-latek, dochód 50 000 PLN → 0% PIT | 🟡 |
| **P582** `pit_exemption_return` | **"4 lata" zakodowane**, brak przykładu | Dodać `return_exemption_years: 4` do thresholds; przykład | 🟡 |
| **P584** `pit_exemption_family_4plus` | **"4+ dzieci" zakodowane**, brak przykładu | Dodać `family_4plus_min_children: 4` do thresholds | 🟡 |
| **P586** `pit_exemption_working_senior` | Brak definicji "pracujący emeryt" — czy JDG się liczy? Czy trzeba nie pobierać emerytury? | Dodać przesłankę: osiągnięty wiek emerytalny + NIE pobiera emerytury + NIE jest w stosunku pracy | 🟡 |

### 2.15 DOC 22 — `jdg.allowances.*` (P600-P628)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P600** `relief_rd_jdg` | **"100% lub 200% dla CBR" zakodowane**, brak przykładów ± | Dodać `relief_rd_base_pct: 100` i `relief_rd_centrum_pct: 200` do thresholds; przykład | 🟡 |
| **P610** `relief_ip_box_jdg` | **Stawka "5%" zakodowana**, brak przykładów ±, brak zależności od P600 (B+R) — reguły konfliktu | Dodać zależność: IP Box i B+R nie mogą być stosowane do tego samego dochodu; przykład z wyliczeniem | 🔴 |
| **P623** `relief_thermo_jdg` | **53 000 PLN** z thresholds (OK) — jedyna reguła ulgi, która PRAWIDŁOWO używa thresholdów | Dodać przykłady ± | 🟢 |

### 2.16 DOC 22 — `jdg.zus.*` (P700-P742)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P700** `zus_social_standard_jdg` | **Wszystkie stawki zakodowane** w tekście (19.52%, 8%, 2.45%, 1.67%, 2.45%), mimo że są w `input.thresholds.jdg.rates.*`. Brak przykładów ± | Użyć `input.thresholds.jdg.rates.zus_pension` itd. w przykładzie; przykład: podstawa 60% średniej → składki = 1 600 PLN/mies. | 🔴 |
| **P720** `zus_health_scale_jdg` | **"9%" zakodowane**, minimalna podstawa niejasna | Użyć thresholdu; przykład: dochód 8 000 PLN/mies. → składka zdrowotna 720 PLN (minimum od minimalnego wynagrodzenia jeśli dochód za niski) | 🟡 |
| **P722** `zus_health_linear_jdg` | **"4.9%" i "12 900 PLN" zakodowane**, dobra dokumentacja. Brak przykładów ± | Użyć thresholdów; przykład: dochód 15 000 PLN/mies. → składka 735 PLN/mies., rocznie 8 820 PLN (w limicie 12 900) | 🟡 |
| **P724** `zus_health_lump_sum_jdg` | **Progi "60 000 / 300 000 PLN" zakodowane** mimo że są w thresholds. Brak przykładów | Użyć `zus_health_lump_tier1_limit` i `zus_health_lump_tier2_limit`; przykład: przychód 45 000 PLN → I próg; przychód 250 000 PLN → II próg | 🟡 |
| **P740** `zus_start_relief_jdg` | **"6 miesięcy" zakodowane**, brak przykładu wygaśnięcia | Użyć `zus_start_months`; przykład: JDG od 1 marca → ulga do 31 sierpnia → od września standardowy ZUS | 🟡 |
| **P741** `zus_maly_plus_jdg` | **"30%", "36 miesięcy", "120 000 PLN" zakodowane**, brak przykładów | Użyć thresholdów; przykład | 🟡 |
| **P742** `zus_preferential_jdg` | **"30%", "24 miesiące" zakodowane**, brak przykładów | Użyć thresholdów; przykład | 🟡 |

### 2.17 DOC 22 — `jdg.accounting.*` (P800-P859)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P800-P802** | ⚠️ **ZDEPRECJONOWANE** — zastąpione przez Doc 28a R0372-R0399 | — | 🟢 |
| **P820** `lump_sum_evidence_entry` | Brak przykładów struktury ewidencji, brak szablonu | Dodać przykładowy wpis: data, nr faktury, kontrahent, kwota brutto, stawka ryczałtu | 🟡 |
| **P830-P832** | Minimalistyczne, brak przykładów struktury ewidencji | Dodać przykładowe wpisy ewidencji VAT | 🟡 |
| **P840-P842** | ⚠️ **ZDEPRECJONOWANE** — zastąpione przez Doc 28a R0379-R0389 | — | 🟢 |
| **P850** `private_mixed_home_office` | ⭐ Dobrze opisana z proporcją. Brak przykładów liczbowych | Dodać: mieszkanie 60m², pokój biurowy 10m² → 16.7% od czynszu, prądu, internetu | 🟢 |
| **P852** `private_mixed_car` | **"75% KUP" i "50% VAT" zakodowane**, brak przykładów ± | Użyć thresholdów; przykład z ewidencją vs bez ewidencji | 🟡 |

### 2.18 DOC 22 — `jdg.business.*` (P900-P934)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P900** `ceidg_registration_check` | Dobry opis. Brak przykładów ± | Dodać przykład: brak `ceidg_entry_date` → BLOCK z komunikatem "Zarejestruj się w CEIDG" | 🟢 |
| **P902** `ceidg_data_change_notification` | **"7 dni" zakodowane**, brak przykładów | Dodać `ceidg_update_deadline_days: 7` do thresholds; przykład | 🟡 |
| **P904** `ceidg_vendor_verification` | **"próg" nieokreślony** — jaki? 15 000 PLN? Każda transakcja? | Sprecyzować próg weryfikacji CEIDG kontrahenta | 🟡 |
| **P910** `business_suspension_valid` | ⭐ Bardzo dobrze opisana z KUP i VAT implikacjami. Brak przykładów czasowych | Dodać: JDG zawieszone 1 lipca - 30 września, wszystkie daty w tym okresie → odpowiednie flagi | 🟢 |
| **P912** `business_suspension_kup_restrictions` | **Lista dozwolonych wydatków zakodowana** `["RENT", "UTILITIES", "SECURITY", "LEASE_EXISTING", "INSURANCE", "ACCOUNTING"]` | Przenieść do `input.thresholds.jdg.lists.suspension_allowed_expenses` | 🔴 |
| **P914** | ⚠️ **ZDEPRECJONOWANE** — zastąpione przez Doc 28a R0582 (poprawione: zdrowotna NADAL należna) | — | 🟢 |
| **P920-P924** | Dobrze opisane. Brak przykładów czasowych | Dodać przykładowy harmonogram sukcesji | 🟢 |
| **P930** `unregistered_activity_limit` | **"50% minimalnego" i "7 dni" zakodowane**, dobry koncept | Użyć `unregistered_activity_limit_percent` i `minimum_wage_gross`; przykład | 🟡 |

### 2.19 DOC 22 — `jdg.ksef` i `jdg.jpk` (P950-P989)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P950** `ksef_structured_mandatory_jdg` | **Data "2026-02-01" zakodowana**, brak przykładów | Dodać `ksef_mandatory_from: "2026-02-01"` do thresholds; przykład | 🟡 |
| **P952** `ksef_b2c_exemption_jdg` | Brak przykładu B2C vs B2B | Przykład: sprzedaż dla osoby prywatnej → bez KSeF; dla firmy → obowiązek | 🟢 |
| **P970** `jpk_v7m_structure_jdg` | Bardzo minimalistyczna, brak struktury JPK_V7 | Dodać referencję do struktury logicznej JPK_V7M/K | 🟡 |

### 2.20 DOC 22 — `jdg.retention` i `jdg.fallback` (P990-P1099)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P990** `retention_invoice_5y` | **"5 lat" zakodowane**, brak rozróżnienia faktury VAT vs faktury uproszczonej | Użyć thresholds; dodać liczenie od końca roku kalendarzowego, nie od daty faktury | 🟡 |
| **P992** `retention_pkpir_5y` | j.w. | j.w. | 🟡 |
| **P1000** `domestic_fallback_jdg` | **"23%" zakodowane** — powinno używać `input.thresholds.jdg.rates.vat_standard` | Użyć thresholdu | 🟡 |
| **P1099** `no_match_jdg` | Brak przykładu, co się dzieje z fakturą po NO_MATCH | Dodać: faktura trafia do manualnej weryfikacji (TRIAGE_QUEUE) | 🟢 |

> ⚠️ **Dodatkowa uwaga (Doc 24):** Indeks w `24_JDG_COMPLETE_INDEX.md` wciąż wymienia P40, P41, P42, P45, P48 jako aktywne reguły z Doc 22, mimo że `38c_JDG_CANONICAL_MAP.md` oznacza je jako 🔴 DEPRECATED. Jest to **niespójność dokumentacyjna** — Doc 24 powinien zostać zsynchronizowany z mapą kanoniczną (38c).

---

### 2.21 DOC 23 — `jdg.pit.tax_form_change` (P590-P596)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P590-P596** | ⭐ Generalnie DOBRZE opisane jako pakiet. Ale: brak przykładów liczbowych, **wszystkie terminy zakodowane** ("01-01", "20. dnia"), brak edge case dla zmiany wstecznej | Dodać przykłady z konkretnymi datami i skutkami podatkowymi; przenieść terminy do thresholds | 🟡 |

### 2.22 DOC 23 — `jdg.crossborder` rozbudowa (P43-P49, P190-P191, P232)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P46** `intracommunity_acquisition_detailed` | **"15. dnia następnego miesiąca" zakodowane**, brak przykładu | Dodać `wnt_tax_point_default_day: 15` do thresholds; przykład | 🟡 |
| **P49** `triangular_transaction_rules` | Dobry opis, ale brak przykładu trójstronnego z nazwami krajów | Przykład: PL→DE→CZ, faktura 10 000 EUR, JDG jako pośrednik → 0% VAT | 🟢 |
| **P190** `wnt_intra_community_detailed` | Powielenie P46 — te dwie reguły są bardzo podobne (obie o WNT tax point) | Rozważyć konsolidację P46 + P190 w jedną regułę z warunkiem daty otrzymania faktury | 🟡 |

### 2.23 DOC 23 — `jdg.corrections` (P1100-P1114)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P1100-P1114** | ⚠️ **ZDEPRECJONOWANE** (zastąpione przez Doc 28a R0420-R0435) — ale DOBRZE opisane jako koncepty. | — | 🟢 |

### 2.24 DOC 23 — `jdg.statute_liability` (P1150-P1166)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P1150-P1166** | ⚠️ **ZDEPRECJONOWANE** (zastąpione przez Doc 28a R0436-R0449), ALE: opisy w Doc 23 są **lepsze jakościowo** niż odpowiedniki w Doc 28a (mają pełne przesłanki, rezultaty i ostrzeżenia) | Rozważyć zachowanie Doc 23 jako dokumentacji referencyjnej, nawet jeśli reguły kanoniczne są w Doc 28a | 🟡 |
| **P1158** `entrepreneur_personal_liability` | ⭐ Jedna z lepiej opisanych reguł — jasno komunikuje nieograniczoną odpowiedzialność. Brak przykładu z majątkiem wspólnym | Dodać przykład: zaległość 50 000 PLN → komornik może zająć majątek osobisty + wspólny z małżonkiem | 🟢 |
| **P1162** `joint_liability_spouse` | Dobry opis, ale brak przykładu z rozdzielnością majątkową | Dodać: rozdzielność ustanowiona 2025 → zaległość z 2024 = odpowiedzialność solidarna; zaległość z 2026 = tylko przedsiębiorca | 🟢 |

### 2.25 DOC 23 — `jdg.representation` (P1200-P1212)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P1200-P1212** | ⚠️ **ZDEPRECJONOWANE** — ale opisy są szczegółowe. Brakuje przykładów formularzy, brak diagramu przepływu pełnomocnictw | Dodać przykładowy scenariusz: JDG → biuro rachunkowe UPL-1 → podpisanie JPK_V7 | 🟢 |

### 2.26 DOC 23 — `jdg.zus.interactions` (P730-P738)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P730** `health_contribution_rate_matrix` | 🔧 Oznaczona jako HELPER — ale to DOBRA decyzja. Macierz jest czytelna. Brak przykładu dla każdej formy | Dodać wyliczenia dla każdej z 4 form | 🟢 |
| **P732** `form_change_contribution_trigger` | Brak przykładu czasowego (KIEDY dokładnie zmiana ZUS DRA?) | Dodać: od pierwszego miesiąca nowego roku podatkowego | 🟡 |
| **P734** | 🔴 ZDEPRECJONOWANA — wchłonięta do P724 | — | 🟢 |
| **P738** | 🔴 ZDEPRECJONOWANA — redundantna z P720 | — | 🟢 |

### 2.27 DOC 23 — `jdg.accounting.leasing` (P860-P868)

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **P860-P868** | ⭐ DOBRZE opisany pakiet — każda reguła ma przesłanki, rezultaty, ostrzeżenia. Brak: przykładów liczbowych, **"40%" zakodowane**, **"150 000 PLN" zakodowane** | Użyć thresholdów; przykład: samochód 180 000 PLN, rata leasingowa 3 000 PLN → KUP z raty = 3 000 × (150 000/180 000) = 2 500 PLN | 🟡 |

---

### 2.28 DOC 25 — Proponowane reguły z audytu prawnego

| Reguła | Brakujące elementy | Rekomendacja | Priorytet |
|--------|-------------------|-------------|:---------:|
| **Wszystkie 46 propozycji** | ⭐ **NAJLEPIEJ OPISANE REGUŁY W CAŁYM PLANIE** — każda ma: co sprawdza, przesłanki, rezultat, podstawę prawną, priorytet. To jest WZORZEC dla pozostałych dokumentów. JEDYNY brak: przykłady ± i edge cases (ale to dokument diagnostyczny, nie implementacyjny) | Przy implementacji dodać przykłady ± i scenariusze brzegowe | 🟢 |

---

## 3. TOP 20 REGUŁ DO NATYCHMIASTOWEJ ROZBUDOWY

Reguły najbardziej odstające od standardu ENTERPRISE (uporządkowane od najgorszych).

> **Legenda Score:** X/10 = liczba spełnionych pól z 10-elementowego szablonu ENTERPRISE (nazwa, cel biznesowy, przesłanki, rezultat, podstawa prawna, zależności, scenariusze brzegowe, parametry dynamiczne, przykład +, przykład -).

| # | Reguła | Dokument | Główne braki | Score |
|---|--------|:--------:|-------------|:-----:|
| 1 | **P52** `vat_rate_fuel_pl` | Doc 22 | 1 linijka w tabeli, zero opisu | 1/10 |
| 2 | **P53** `vat_rate_food_pl` | Doc 22 | 1 linijka w tabeli, zero opisu | 1/10 |
| 3 | **P54** `vat_rate_books_pl` | Doc 22 | 1 linijka, brak rozróżnienia e-book/druk | 1/10 |
| 4 | **P65** `gtu_mapping_by_category` | Doc 22 | 2 zdania, brak mapowania | 1/10 |
| 5 | **P25** `split_payment_mandatory` | Doc 22 | "kategoria wrażliwa MPP" niezdefiniowana | 2/10 |
| 6 | **P50** `vat_margin_scheme` | Doc 22 | Błędna stawka (marża ≠ zawsze 23%) | 2/10 |
| 7 | **P540** `pit_advance_monthly` | Doc 22 | Niejasna formuła, brak przykładów | 2/10 |
| 8 | **P820** `lump_sum_evidence_entry` | Doc 22 | Brak struktury ewidencji | 2/10 |
| 9 | **P830** `vat_evidence_purchase` | Doc 22 | Super minimalistyczna | 2/10 |
| 10 | **P970** `jpk_v7m_structure_jdg` | Doc 22 | 2 zdania, zero struktury | 2/10 |
| 11 | **P5** `semantic_guard_disallowed` | Doc 22 | Zakodowana lista kategorii | 3/10 |
| 12 | **P560** `kup_full_deductible` | Doc 22 | "Związek z działalnością" niezdefiniowany | 3/10 |
| 13 | **P950** `ksef_structured_mandatory_jdg` | Doc 22 | Data obowiązku zakodowana | 3/10 |
| 14 | **P566** `kup_representation_none` | Doc 22 | Brak definicji reprezentacji | 3/10 |
| 15 | **P610** `relief_ip_box_jdg` | Doc 22 | Brak reguł konfliktu z B+R | 3/10 |
| 16 | **P20** `whitelist_missing_over_limit` | Doc 22 | Nieadekwatna nazwa thresholdu, brak ważności weryfikacji | 3/10 |
| 17 | **P43** `vat_ue_registration_mandatory` | Doc 23 | Zakodowana lista krajów UE | 3/10 |
| 18 | **P700** `zus_social_standard_jdg` | Doc 22 | Wszystkie stawki zakodowane w tekście | 3/10 |
| 19 | **P990** `retention_invoice_5y` | Doc 22 | "5 lat" zakodowane, nie liczone od końca roku | 3/10 |
| 20 | **P1000** `domestic_fallback_jdg` | Doc 22 | "23%" zakodowane zamiast użycia thresholdu | 3/10 |

---

## 4. LUKI GLOBALNE — PROBLEMY CAŁEGO PLANU

### 4.1 🔴 KRYTYCZNE: Brak przykładów pozytywnych i negatywnych

**Dotknięte:** 98% reguł (210/214)

Żadna reguła w dokumentach 22-23 nie zawiera sekcji "Przykład pozytywny" ani "Przykład negatywny". W systemie ENTERPRISE gdzie reguły mają bezpośredni wpływ na finanse użytkowników, brak konkretnych przykładów to poważny defekt.

**Rekomendacja:** Każda reguła powinna zawierać:
```markdown
- **Przykład pozytywny (+):** [konkretna sytuacja, reguła zwraca allow / pasuje]
- **Przykład negatywny (-):** [konkretna sytuacja, reguła zwraca deny / nie pasuje]
```

---

### 4.2 🔴 KRYTYCZNE: Brak scenariuszy brzegowych

**Dotknięte:** 93% reguł (200/214)

Przekroczenie limitów w trakcie roku, zmiana formy opodatkowania, pierwszy/ostatni miesiąc działalności — tylko Doc 28a zawiera edge cases. Dokumenty 22-23 praktycznie ich nie mają.

**Rekomendacja:** Dla każdej reguły dodać sekcję "Scenariusze brzegowe" z minimum 3 przypadkami.

---

### 4.3 🟡 WAŻNE: Zakodowane wartości liczbowe

**Dotknięte:** ~16% reguł (35/214)

Mimo że filozofia "Zero Hardcoded Values" jest zadeklarowana w Doc 22 (§0.1), wiele reguł wciąż ma zakodowane liczby w opisach. Najczęstsze przypadki:

| Wartość | Gdzie zakodowana | Powinna być w |
|---------|-----------------|---------------|
| 23% (stawka VAT) | P50, P1000 | `thresholds.jdg.rates.vat_standard` |
| 19.52%, 8%, 2.45% (ZUS) | P700 | `thresholds.jdg.rates.zus_*` |
| 9%, 4.9% (zdrowotna) | P720, P722 | `thresholds.jdg.rates.zus_health_*` |
| 150 000 PLN (auto) | P564 | `thresholds.jdg.limits.car_value_kup_limit` |
| 15 000 PLN (MPP) | P20, P25 | `thresholds.jdg.limits.mpp_limit` |
| 6 miesięcy, 24, 36 mies. (ZUS ulgi) | P740-P742 | `thresholds.jdg.bounds.zus_*` |
| 5 lat (retencja) | P990-P992 | `thresholds.jdg.limits.retention_years_*` |
| 7 dni (CEIDG) | P902 | `thresholds.jdg.bounds.ceidg_update_days` |
| 20. dzień miesiąca | P540 | `thresholds.jdg.bounds.pit_advance_due_day` |
| "01-01" (zmiana formy) | P590 | `thresholds.jdg.bounds.tax_form_change_date` |
| Lista krajów UE | P43 | `thresholds.jdg.lists.eu_member_states` |
| Lista kategorii MPP | P25 | `thresholds.jdg.lists.mpp_sensitive_categories` |
| Lista kategorii disallowed | P5 | `thresholds.jdg.lists.disallowed_categories` |

---

### 4.4 🟡 WAŻNE: Brak pól temporalnych (`valid_from` / `valid_to`)

**Dotknięte:** 98% reguł

Filozofia "Temporalność" jest zadeklarowana w Doc 22 (§0.1), ale **żadna reguła nie ma przypisanych dat obowiązywania**. W praktyce uniemożliwia to:
- Obsługę zmian stawek podatkowych w trakcie roku
- Okresy przejściowe
- Historyczną poprawność decyzji

**Rekomendacja:** Dodać do każdej reguły:
```rego
valid_from := "2024-01-01"
valid_to := null  # null = "obowiązuje do odwołania"
```

---

### 4.5 🟡 WAŻNE: Niejasna hierarchia deprecjacji

**Dotknięte:** 47 reguł w 3 dokumentach

Reguły zdeprecjonowane w Doc 22 (17) i Doc 23 (28) wciąż zajmują miejsce w dokumentach. Nie zawsze jest jasne, która wersja jest kanoniczna. Doc 24 i 38c próbują to rozwiązać, ale:
- Doc 24 pokazuje P-ID bez informacji o deprecjacji
- Doc 38c jest najlepszym źródłem, ale nie wszyscy o nim wiedzą

**Rekomendacja:** W Docs 22-23:
1. Wyraźnie oznaczać `[DEPRECATED]` w tytule reguły
2. Linkować do kanonicznej wersji: `→ Zastąpiona przez: Doc 28a R0420`
3. Rozważyć przeniesienie zdeprecjonowanych reguł do osobnego pliku `DEPRECATED.md`

---

### 4.6 🟡 WAŻNE: Nierównomierna głębokość opisów

**Dotknięte:** ~37% reguł (80/214)

| Pakiet | Jakość | Przykład dobrej | Przykład słabej |
|--------|:------:|-----------------|-----------------|
| `jdg.business` | ⭐⭐⭐⭐⭐ | P910 (6 przesłanek, 4 rezultaty) | P904 (jedno zdanie) |
| `jdg.pit.kup` | ⭐⭐⭐⭐ | P562 (szczegółowa proporcja) | P566 (lakoniczna) |
| `jdg.zus` | ⭐⭐⭐⭐ | P741 (szczegółowe warunki) | P700 (zakodowane stawki) |
| `jdg.vat.substantive` | ⭐⭐ | P58 (dobra) | P52-P54 (1 linijka) |
| `jdg.compliance` | ⭐⭐⭐ | P20 (przyzwoita) | P25 (niepełna) |
| `jdg.ksef` / `jdg.jpk` | ⭐⭐ | — | Wszystkie minimalistyczne |
| `jdg.retention` | ⭐ | — | P990-P992 (1-2 zdania) |

---

### 4.7 🟢 ŚREDNIE: Brak zależności między regułami

**Dotknięte:** ~70% reguł

Tylko garstka reguł (P58, P510, P541, P610) ma wymienione zależności. W systemie first-match-wins, brak udokumentowanych zależności utrudnia:
- Zrozumienie kolejności reguł
- Wykrywanie konfliktów
- Implementację łańcucha `else`

---

### 4.8 🟢 ŚREDNIE: Niespójne konwencje nazewnicze

Niektóre reguły używają `*_jdg`, inne nie. Niektóre mają prefiks pakietu, inne nie. Przykłady:
- `vat_rate_fuel_pl` — bez `_jdg`
- `zus_health_scale_jdg` — z `_jdg`
- `ceidg_registration_check` — samo `_check`
- `kup_car_over_150k_limit` — wartość liczbowa w nazwie (❌)

---

### 4.9 ⚪ NISKIE: Doc 24 — indeks, nie dokument regulacyjny

Doc 24 jest czystym indeksem — nie zawiera opisów reguł, więc nie podlega audytowi jakościowemu w tym samym sensie. Jest jednak niezbędny jako mapa.

---

### 4.10 ⚪ NISKIE: Doc 25 — WZORZEC JAKOŚCI

Paradoksalnie, Doc 25 (audyt prawny) ma NAJWYŻSZĄ jakość opisów reguł ze wszystkich 4 dokumentów. Każda z 46 proponowanych reguł ma: co sprawdza, przesłanki, rezultat, podstawę prawną, priorytet, a często także ostrzeżenia i uzasadnienie. To powinien być WZORZEC dla Docs 22-23.

---

## 5. PORÓWNANIE DOKUMENTÓW — MACIERZ JAKOŚCI

| Kryterium | Doc 22 | Doc 23 | Doc 24 | Doc 25 |
|-----------|:------:|:------:|:------:|:------:|
| **Kompletność pól** | 🟡 5/8 | 🟡 5/8 | n/d | 🟢 6/8 |
| **Głębia przesłanek** | 🟡 | 🟢 | n/d | 🟢 |
| **Scenariusze brzegowe** | 🔴 | 🔴 | n/d | 🟡 |
| **Przykłady ±** | 🔴 | 🔴 | n/d | 🔴 |
| **Spójność wewnętrzna** | 🟡 | 🟡 | 🟢 | 🟢 |
| **Podstawa prawna** | 🟢 | 🟢 | n/d | 🟢 |
| **Parametryzacja** | 🟡 | 🟡 | n/d | 🟡 |
| **Równomierność** | 🟡 | 🟡 | n/d | 🟢 |
| **Obsługa deprecjacji** | 🟡 | 🟡 | 🟢 | 🟢 |
| **Czytelność** | 🟡 | 🟢 | 🟢 | 🟢 |
| **OCENA CAŁKOWITA** | **5.8** | **6.2** | **n/d** | **7.8** |

---

## 6. REKOMENDACJE NAPRAWCZE

> **Zależności między fazami:** Faza A blokuje Fazę B — przykłady ± (B.5) muszą używać `input.thresholds`, nie zakodowanych wartości (A.2). Faza B blokuje Fazę C — walidator automatyczny (C.12) wymaga ujednoliconego formatu (B.7-B.8).

### Faza A: NATYCHMIAST (Top 20 + globalne) — szacowany nakład: ~5-7 dni analitycznych

1. **Rozbudować Top 20 reguł** (z Sekcji 3) do pełnego formatu ENTERPRISE z przykładami ±
2. **Przenieść wszystkie zakodowane wartości** do `input.thresholds.jdg.*` (lista w Sekcji 4.3) ⚠️ *PREREKWIZYT dla Fazy B.5*
3. **Dodać sekcję "Scenariusze brzegowe"** do minimum 50 najważniejszych reguł (P0-P9, P50-P58, P500-P510, P560-P570, P700-P742, P900-P930)
4. **Dodać pola temporalne** `valid_from`/`valid_to` do każdej reguły
5. **Zsynchronizować Doc 24** z mapą kanoniczną 38c (oznaczyć P40-P42, P45, P48 jako DEPRECATED)

### Faza B: WAŻNE (średnioterminowe) — szacowany nakład: ~8-12 dni

6. **Dodać przykłady ±** do wszystkich 214 reguł ⚠️ *ZALEŻY od A.2 (thresholdy muszą być już w użyciu)*
7. **Uzupełnić zależności** między regułami (szczególnie first-match-wins chain)
8. **Ujednolicić konwencje nazewnicze** — wszystkie reguły JDG z sufiksem `_jdg`
9. **Usunąć zakodowane liczby z nazw reguł** (np. `_150k_limit` → `_car_value_limit`)

### Faza C: DOSKONALENIE (długoterminowe) — szacowany nakład: ~5-8 dni

10. **Wydzielić reguły zdeprecjonowane** do osobnego pliku `DEPRECATED.md`
11. **Użyć Doc 25 jako wzorca** dla formatu wszystkich reguł
12. **Dodać testy walidacyjne** dla każdej reguły (powiązane z przykładami ±) ⚠️ *ZALEŻY od B.7-B.9 (ujednolicone nazwy i format)*
13. **Stworzyć automatyczny walidator** sprawdzający kompletność pól każdej reguły

---

## 7. SZABLON DOCELOWY — Format Reguły ENTERPRISE

Każda reguła w planie JDG powinna być opisana według poniższego szablonu (obecnie żadna reguła nie spełnia go w 100%):

```markdown
### P{ID}: `{nazwa_reguly}`

- **Cel biznesowy:** [3-5 zdań — CO reguła sprawdza, DLACZEGO jest krytyczna, JAKIE ryzyko mityguje]

- **Przesłanki szczegółowe:** 
  1. [Warunek 1 — konkretny, mierzalny, z odwołaniem do input]
  2. [Warunek 2]
  ...

- **Oczekiwany rezultat:** [Co zwraca reguła: allow/deny, konkretne wartości pól werdyktu]

- **Podstawa prawna:** [Dokładny artykuł, ustęp, punkt, wraz z tekstem jednolitym]

- **Zależności:** [Które reguły muszą być sprawdzone PRZED tą regułą]

- **Scenariusze brzegowe:**
  1. [Edge case 1 — np. przekroczenie limitu w trakcie roku]
  2. [Edge case 2 — np. pierwsza transakcja w roku]
  3. [Edge case 3 — np. zmiana formy opodatkowania]

- **Parametry dynamiczne:** [Lista kluczy z `input.thresholds.jdg.*` używanych przez regułę]

- **Przykład pozytywny (+):** 
  - Sytuacja: [konkretne wartości input]
  - Rezultat: [reguła pasuje / zwraca allow]

- **Przykład negatywny (-):** 
  - Sytuacja: [konkretne wartości input]
  - Rezultat: [reguła nie pasuje / zwraca deny]

- **Priorytet:** {P-ID}
- **Ważność od:** {valid_from}
- **Ważność do:** {valid_to}
```

---

## 8. PODSUMOWANIE LICZBOWE

| Metryka | Wartość |
|---------|:------:|
| **Reguł audytowanych** | 214 (Doc 22: 145, Doc 23: 69) |
| **Reguł KOMPLETNYCH (8/8)** | **0** |
| **Reguł PRAWIE KOMPLETNYCH (6-7/8)** | **~12** |
| **Reguł ŚREDNICH (4-5/8)** | **~120** |
| **Reguł SŁABYCH (2-3/8)** | **~70** |
| **Reguł SZKIELETOWYCH (1/8)** | **~12** |
| **Reguł z przykładami ±** | **0** |
| **Reguł ze scenariuszami brzegowymi** | **~14** |
| **Reguł z zakodowanymi wartościami** | **~35** |
| **Reguł zdeprecjonowanych** | **47** |
| **Znalezionych luk globalnych** | **10** |
| **Top 20 do natychmiastowej rozbudowy** | **20** |

---

> **🔥 KONKLUZJA:** Plan JDG ma solidne fundamenty architektoniczne, ale wymaga **radykalnego podniesienia jakości opisów reguł**. Główne priorytety to: (1) przykłady ± dla każdej reguły, (2) scenariusze brzegowe, (3) eliminacja zakodowanych wartości, (4) dodanie pól temporalnych, (5) uporządkowanie deprecjacji.  
> **Doc 25** (audyt prawny) powinien służyć jako **wzorzec jakości** dla wszystkich pozostałych dokumentów.  
> **Rekomendowany następny krok:** Implementacja Fazy A — rozbudowa Top 20 najsłabszych reguł i eliminacja wszystkich zakodowanych wartości.

---

*Wygenerowano przez NexusAI Quality Audit Engine v1.0*  
*Data: 2026-07-12*  
*Audytowane dokumenty: 22_JDG_ENTERPRISE_PLAN.md, 23_JDG_EXPANSION_SUPPLEMENT.md, 24_JDG_COMPLETE_INDEX.md, 25_JDG_DEEP_LEGAL_AUDIT.md*
