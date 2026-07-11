# 🔭 NexusAI Spółka Cywilna — Strategiczna Analiza i Ulepszenia ENTERPRISE v1.0

> **Status:** ANALIZA STRATEGICZNA — audyt architektoniczny systemu reguł SC
> **Data:** 2026-07-11
> **Autor:** Główny Architekt Systemów Reguł Podatkowych
> **Plik:** `Plan OPA/38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md`
> **Analizowane dokumenty:** `SC_DEFINITIVE_REGO_PLAN.md` (~550 reguł), `SC_EXPANSION_14_AREAS.md` (~85 reguł), `35_SPOLKA_CYWILNA_ADVANCED_GAPS.md` (~69 reguł), `36_SPOLKA_CYWILNA_ULTIMATE_GAPS.md` (~48 reguł), `37_SPOLKA_CYWILNA_ULTIMATE_GRANULARITY.md` (~435 reguł)
> **Łącznie analizowanych reguł:** ~1 187 | **Pakietów:** 33 | **Priorytetów:** GR-0 do GR-799

---

## 📑 Spis Treści

1. [Etap 1: Głęboka Analiza 7-Wymiarowa](#etap-1-głęboka-analiza-7-wymiarowa)
   - [1.1 Kompletność](#11-kompletność)
   - [1.2 Spójność](#12-spójność)
   - [1.3 Skalowalność](#13-skalowalność)
   - [1.4 Utrzymywalność](#14-utrzymywalność)
   - [1.5 Wydajność](#15-wydajność)
   - [1.6 Audytowalność](#16-audytowalność)
   - [1.7 Testowalność](#17-testowalność)
2. [Etap 2: Kreatywne Myślenie](#etap-2-kreatywne-myślenie)
   - [A) 3 Genialne Ulepszenia](#a-3-genialne-ulepszenia)
   - [B) 3 Niesamowite Optymalizacje](#b-3-niesamowite-optymalizacje)
   - [C) 3 Potężne i Szczegółowe Pomysły](#c-3-potężne-i-szczegółowe-pomysły)

---

## Etap 1: Głęboka Analiza 7-Wymiarowa

### 1.1 Kompletność

#### Co jest MOCNE:

System pokrywa imponująco szeroki zakres obszarów prawno-podatkowych:

| Obszar | Pokrycie | Ocena |
|--------|:--------:|:-----:|
| VAT spółki (stawki, odliczenia, GTU, KSeF, JPK, tax point) | ~195 reguł (GR-55 do GR-244) | ⭐⭐⭐⭐⭐ |
| PIT wspólników (podział Art.8, formy, KUP, zaliczki, zeznania) | ~150 reguł (GR-170 do GR-349) | ⭐⭐⭐⭐⭐ |
| Odpowiedzialność solidarna (Art. 864 KC) | ~35 reguł (GR-415 do GR-459) | ⭐⭐⭐⭐⭐ |
| Cykl życia spółki (powstanie, zmiany, rozwiązanie, sukcesja, zawieszenie) | ~75 reguł (GR-330 do GR-509) | ⭐⭐⭐⭐ |
| Ulgi podatkowe per wspólnik | ~40 reguł (GR-255 do GR-279, GR-221 do GR-237) | ⭐⭐⭐⭐ |
| ZUS i zdrowotne per wspólnik | ~65 reguł (GR-238 do GR-304) | ⭐⭐⭐⭐ |
| Spółka jako pracodawca | ~25 reguł (GR-455 do GR-494) | ⭐⭐⭐⭐ |

#### LUKI i słabości — szczegółowa identyfikacja:

**L1. Brak reguł dla SCENARIUSZY WIELOKROTNYCH ZMIAN SKŁADU W ROKU**

Obecne reguły P502/P503 (GR-352/GR-353 w 37_GRANULARITY) obsługują JEDNĄ zmianę udziałów w roku. Scenariusz: wspólnik A odchodzi 1 marca, wspólnik C wchodzi 1 lipca, wspólnik B zmienia udział z 50% na 30% we wrześniu → system nie ma reguł na TRZY zmiany w jednym roku. Art. 8 PIT wymaga podziału proporcjonalnego per każdy okres z różnymi udziałami.

**Rekomendacja:** Dodać `sc_changes_multi_event_timeline` — regułę która tworzy timeline wszystkich zdarzeń w roku i dzieli rok na segmenty, przydzielając każdemu segmentowi odpowiedni zestaw wspólników i udziałów.

**L2. Dualizm VAT/PIT — brak reguł dla ROZBIEŻNOŚCI DAT OBOWIĄZKU**

VAT spółki ma własny moment obowiązku podatkowego (GR-109 do GR-115), PIT wspólnika ma własny moment powstania przychodu (GR-174 do GR-176). System słusznie je rozdziela, ale BRAKUJE reguł dla przypadku gdy data obowiązku VAT jest w INNYM miesiącu niż data przychodu PIT (np. VAT w styczniu od zaliczki, PIT w marcu od dostawy). JPK_V7 i PIT-36 pokażą różne miesiące — i to jest PRAWIDŁOWE. Ale system powinien mieć regułę `sc_interact_vat_pit_timing_divergence` która FLAGUJE tę rozbieżność jako oczekiwaną (żeby audytor nie zgłaszał błędu) i dokumentuje przyczynę.

**Rekomendacja:** Dodać `sc_interact_vat_pit_timing_divergence` — regułę dokumentującą prawidłowe rozbieżności dat.

**L3. Brak reguł dla TRANSAKCJI WSPÓLNIK-SPÓŁKA W KONTEKŚCIE CEN TRANSFEROWYCH**

Dokument 35_ADVANCED_GAPS ma P562-P565 dla transakcji wspólnik-spółka, ale NIE ma reguł łączących to z obowiązkami cen transferowych (Art. 23m-23zf PIT). Gdy wspólnik sprzedaje spółce usługi za 600 000 PLN — czy to podlega dokumentacji TP? Odpowiedź: TAK, jeśli spółka przekracza 2M EUR przychodu. System nie ma tej reguły.

**Rekomendacja:** Dodać `sc_tp_partner_transaction_documentation` — łączącą P562 z progami TP.

**L4. Brak reguł dla UMÓW USTNYCH W SC**

Art. 860 § 2 KC dopuszcza umowę ustną SC dla celów cywilnoprawnych. Ale system zakłada `partnership.agreement_written == true` (P900). Scenariusz: dwie osoby zawierają SC ustnie, nie rejestrują się w CEIDG, ale faktycznie współpracują. Dla US to może być uznane za SC — z pełną odpowiedzialnością solidarną. System powinien mieć `sc_formation_de_facto_partnership` — regułę ostrzegawczą dla faktycznego współdziałania bez umowy.

**Rekomendacja:** Dodać regułę wykrywającą de facto SC na podstawie wzorca transakcji.

**L5. Duplikacja reguł między dokumentami**

Przegląd dokumentów ujawnia znaczącą duplikację:

| Reguła | SC_DEFINITIVE | 37_GRANULARITY | Status |
|--------|:------------:|:--------------:|--------|
| partner_proportional_split | P500 (★★★) | GR-170 (★★★) | DUPLIKAT |
| partner_kup_full_deductible | P560 | GR-193 | DUPLIKAT |
| vat_exemption_subject_sc | P58 (★★★) | GR-83 | DUPLIKAT |
| vat_rate_fuel | P52 | GR-52 (brak w 37!) | NIESPÓJNOŚĆ |
| partner_zus_sickness_voluntary | P701 (★) | GR-241 (★★) | RÓŻNE OZNACZENIA |
| sc_joint_liability_tax | P1150 (★★★) | GR-415 (★★★) | DUPLIKAT |

To nie są błędy funkcjonalne, ale DŁUG TECHNICZNY — utrzymywanie dwóch numeracji (P vs GR) i dwóch poziomów szczegółowości dla tych samych reguł tworzy ryzyko rozbieżności przy aktualizacjach.

**Rekomendacja:** Stworzyć pojedynczy kanoniczny rejestr reguł z mapowaniem P↔GR.

**L6. Luka kompletności wewnątrz pojedynczego dokumentu — niedopisane reguły**

Dokument `37_SPOLKA_CYWILNA_ULTIMATE_GRANULARITY.md` ma nagłówki sekcji deklarujące zakresy reguł (np. "GR-255 do GR-294" dla KUP — 40 planowanych), ale faktycznie napisano tylko ~13 reguł KUP (GR-193 do GR-205). Podobna luka występuje w `sc.pit.returns` (GR-315 do GR-329 planowane, ~7 faktycznie napisanych). To są **obietnice architektoniczne bez implementacji opisowej** — programista czytający dokument zobaczy nagłówek "40 reguł KUP" i oczekuje 40 szczegółowych opisów, a znajdzie 13.

**Rekomendacja:** Albo dopisać brakujące opisy reguł, albo skorygować nagłówki sekcji aby odzwierciedlały faktyczną liczbę reguł. Nagłówek powinien zawsze zgadzać się z zawartością.

---

### 1.2 Spójność

#### Architektura dualizmu podatkowego — analiza spójności:

**S1. Separacja VAT (spółka) i PIT (wspólnicy) — WZORCOWA**

To jest NAJWIĘKSZE osiągnięcie architektoniczne systemu. Separacja jest czysta:

```
PASS 5 (VAT) → vat_verdict na poziomie partnership
PASS 6 (PIT) → pit_verdict per partner (iteracja po partners[])
```

Brak "przecieków" — reguły VAT nie zaglądają do `partners[]`, reguły PIT nie modyfikują `partnership.vat_rate`. To jest podręcznikowa separacja domen. **OCENA: 10/10.**

**S2. Interakcja odpowiedzialność solidarna vs indywidualne rozliczanie — POPRAWNA ale NIEKOMPLETNA**

System ma reguły dla odpowiedzialności solidarnej (P1150-P1174, GR-415 do GR-459), które pokrywają:
- Solidarność za podatki spółki ✅
- Solidarność za ZUS spółki ✅
- Regres między wspólnikami ✅
- Odpowiedzialność po wystąpieniu ✅
- Odpowiedzialność nowego wspólnika za stare długi ✅

ALE brakuje reguł dla:
- **Odpowiedzialności za zobowiązania powstałe W TRAKCIE rozwiązywania spółki** (między decyzją o rozwiązaniu a zakończeniem likwidacji)
- **Regresu wobec spadkobierców zmarłego wspólnika** — czy roszczenie regresowe przechodzi na spadkobierców?
- **Przedawnienia roszczeń regresowych** — czy regres przedawnia się tak samo jak dług główny?

**S3. Rozbieżności priorytetów między dokumentami — problem dokumentacyjny, nie logiczny**

W SC_DEFINITIVE_REGO_PLAN.md priorytety to P0-P1900+, w 37_GRANULARITY.md to GR-0 do GR-799. Te dwa systemy numeracji NIE są bezpośrednio porównywalne — każdy dokument używa własnej przestrzeni priorytetów. Na przykład:

- P58 (vat_exemption_subject_sc) ma priorytet 58 w DEFINITIVE
- GR-83 (ta sama reguła) ma priorytet 83 w GRANULARITY

To NIE jest konflikt w łańcuchu first-match-wins (każdy dokument jest samospójny w swojej numeracji). To jest problem DOKUMENTACYJNY: nie ma jednoznacznego mapowania między P→GR. Programista implementujący reguły z dwóch dokumentów nie wie, która numeracja jest kanoniczna.

**Rekomendacja:** Ustalić pojedynczy kanoniczny łańcuch priorytetów i wygenerować z niego oba dokumenty. Albo przynajmniej stworzyć mapowanie P↔GR jako osobny plik referencyjny.

**S4. Niespójności w oznaczeniach ważności**

Ten sam koncept ma różne oznaczenia gwiazdkowe w różnych dokumentach:
- `partner_zus_sickness_voluntary`: ★ w DEFINITIVE, ★★ w GRANULARITY
- `sc_partner_exit_liability`: ★★★ w DEFINITIVE, ★★ w GRANULARITY
- `sc_changes_proportional_split_midyear`: ★★★ w DEFINITIVE, brak gwiazdek w GRANULARITY

**Rekomendacja:** Ustandaryzować system oceny ważności z jasnymi kryteriami (★★★ = fundamentalna dla zgodności prawnej, ★★ = krytyczna dla bezpieczeństwa finansowego, ★ = istotna dla kompletności).

---

### 1.3 Skalowalność

#### S1. Skalowalność liczby wspólników — O(n)

Architektura iteruje po `partners[]` dla każdego wspólnika w PASS 6 (PIT), PASS 7 (ulgi), PASS 8 (ZUS). To jest O(n) gdzie n = liczba wspólników. Dla typowej SC (2-5 wspólników) — doskonale. Ale dla edge-case (10 wspólników — np. rodzinna SC) może być zauważalne.

**Rekomendacja:** Dodać `max_partners_limit` w thresholds (domyślnie 19 — bo SC rzadko ma więcej).

#### S2. Skalowalność liczby reguł — First-Match-Wins O(n)

Każdy pakiet używa `else` chain w Rego. OPA ewaluuje kolejno, aż znajdzie pasującą. Dla 60 reguł w `sc.vat.substantive` — średni czas ewaluacji to ~30 sprawdzeń (przy założeniu równomiernego rozkładu). To jest akceptowalne.

ALE: w `sc.pit.kup` (GR-193 do GR-205 w 37_GRANULARITY, tylko 13 reguł) dokument 37 obiecuje GR-255 do GR-294 (40 reguł) które NIE są zaimplementowane. Po dodaniu wszystkich 40 reguł KUP, czas ewaluacji wzrośnie. 

**Rekomendacja:** Rozważyć podział `sc.pit.kup` na podpakiety: `sc.pit.kup.full`, `sc.pit.kup.limited`, `sc.pit.kup.excluded` — każdy z własnym first-match-wins.

#### S3. Skalowalność dokumentów referencyjnych

Dokumenty SC już zajmują ~530KB. Każdy nowy obszar (AML, RODO, akcyza, cło) dodaje kolejne dokumenty. Przy 10 dokumentach trudno znaleźć konkretną regułę bez `grep`.

**Rekomendacja:** Rozważyć wygenerowanie pojedynczego pliku `_CANONICAL_RULES_INDEX.md` z odwzorowaniem: `nazwa_reguły → dokument → priorytet → podstawa_prawna`. To ułatwi nawigację.

---

### 1.4 Utrzymywalność

#### U1. Hardcodowane wartości — PROBLEM

Dokument 37_GRANULARITY.md deklaruje w sekcji 1: "Zero Hardcoded Values — Żadna liczba nie jest zakodowana w .rego". Ale w praktyce WIELE reguł ma hardcodowane wartości w treści opisu:

- GR-181: `partner.annual_income <= 120000` — próg podatkowy zahardcodowany w opisie reguły
- GR-239: `months_since_start <= 6` — 6 miesięcy ulgi na start zahardcodowane
- GR-83: `partnership.revenue_annual_net <= 200000` — limit 200k zahardcodowany

W implementacji Rego te wartości MUSZĄ być pobierane z `input.thresholds.sc.bounds.*`. Ale same OPISY reguł używają hardcodowanych wartości, co stwarza ryzyko: programista czytający opis GR-181 (120 000 PLN) zaimplementuje `120000` zamiast `input.thresholds.sc.bounds.pit_scale_bracket`.

**Rekomendacja:** Dodać do każdej reguły jawne odwołanie `[threshold: thresholds.sc.bounds.pit_scale_bracket]` zamiast liczby. Albo generować opisy automatycznie z metadanych.

#### U2. Zmiany prawa — co się dzieje gdy MF zmienia stawki VAT?

Scenariusz: MF podnosi VAT z 23% na 24% od 1 stycznia 2027.

W systemie ENTERPRISE powinno to wymagać:
1. Aktualizacji `thresholds.sc.rates.vat_standard: 0.24` w DuckDB
2. Aktualizacji `valid_from: 2027-01-01` dla nowej stawki
3. Zachowania starej stawki z `valid_to: 2026-12-31` dla audytu historycznego

System z `input.thresholds` to umożliwia — BRAWO. ALE: reguła GR-74 (`sc_vat_rate_standard`) w swoim opisie mówi "Stawka podstawowa VAT 23%". Gdy stawka zmieni się na 24%, OPIS będzie nieaktualny.

**Rekomendacja:** Opisy reguł powinny używać referencji `input.thresholds.sc.rates.vat_standard` zamiast liczb.

#### U3. Reguły temporalne — okresy przejściowe

System NIE ma reguł dla OKRESÓW PRZEJŚCIOWYCH. Przykład: zmiana definicji "małego podatnika" z 1.2M EUR na 2M EUR — faktury z datą sprzedaży przed zmianą podlegają starym zasadom, po zmianie nowym. Gdzie jest reguła `sc_temporal_transition_rule`?

**Rekomendacja:** Dodać `sc.temporal` — pakiet reguł czasowych: `valid_from`, `valid_to`, `transition_period`, `grandfathering`.

---

### 1.5 Wydajność

#### W1. Struktura 20-blokowa — optymalna ale...

Hierarchia first-match-wins w 20 blokach (GRANULARITY sekcja 3) jest optymalna dla OPA. Każdy blok jest niezależnym `else` chainem, co wykorzystuje natywny mechanizm Rego. 

ALE: OPA nie wspiera natywnie "short-circuit across packages". Każdy pakiet jest ewaluowany niezależnie, nawet jeśli PASS 0 (risk) już zablokował transakcję. To jest znane ograniczenie OPA — nie ma `return` między pakietami.

**Rekomendacja:** Dodać `_early_exit` flagę w werdykcie z PASS 0. Kolejne passy sprawdzają `if input._context.early_exit_flag then skip`. Albo użyć zewnętrznego orkiestratora (Python/Rust) który przerywa ewaluację po PASS 0 jeśli BLOCK.

#### W2. Wielkość input — potencjalny bottleneck

Struktura `input` w 37_GRANULARITY.md ma ~60 pól na poziomie `invoice`, `vendor`, `partnership` plus tablicę `partners[]`. Dla 5 wspólników to ~150 pól JSON. OPA parsuje cały input przed ewaluacją — przy tysiącach faktur dziennie może być wąskim gardłem.

**Rekomendacja:** Rozważyć "leniwą" strukturę input — dane wspólników tylko dla aktywnej transakcji (nie wszystkich historycznych).

#### W3. Reguły GTU — liniowe mapowanie

Kody GTU (GR-116 do GR-128, 13 reguł) są mapowaniem 1:1 kategoria → GTU. W Rego to będzie 13 `else if`. Można skompresować do jednej reguły z mapą:

```rego
gtu_code = gtu_map[input.invoice.category_code]
```

Zamiast 13 warunków.

**Rekomendacja:** Skompresować reguły mapowania (GTU, stawki PKWiU, składki ZUS) do struktur danych w helpers, zamiast osobnych reguł.

---

### 1.6 Audytowalność

#### A1. Ślad decyzji — concept WERDYKT SC

Dokument SC_DEFINITIVE_REGO_PLAN.md w sekcji 1.2 definiuje strukturę werdyktu z polami:
```json
{
    "rule_id": "sc.vat.substantive.fuel_pl",
    "_legal_basis": "Art. 41 ust. 1 ustawy o VAT",
    "_routing": "",
    "_routing_reason": "",
    "_edge_cases_checked": [...],
    "_warnings": [...]
}
```

To jest WZORCOWE. Każda decyzja ma:
- Która reguła zadziałała (`rule_id`) ✅
- Podstawę prawną (`_legal_basis`) ✅
- Routing (co zrobić dalej) ✅
- Ostrzeżenia ✅
- Sprawdzone przypadki brzegowe ✅

**ALE:** Brakuje:
- `_timestamp` — kiedy decyzja została podjęta
- `_input_hash` — hash danych wejściowych (dla niepodważalności)
- `_opa_version` — wersja silnika OPA
- `_ruleset_version` — wersja zestawu reguł (git commit hash)

Bez `_input_hash` audytor nie może udowodnić, że decyzja została podjęta na podstawie tych konkretnych danych, a nie zmodyfikowanych później.

**Rekomendacja:** Dodać `_audit_trail: {timestamp, input_hash, opa_version, ruleset_version}` do każdego werdyktu.

#### A2. Audyt dla wspólników — czy każdy widzi SWOJE decyzje?

System produkuje `partners_results[]` z indywidualnymi kalkulacjami per wspólnik. To jest dobre — każdy wspólnik dostaje swoją część. ALE: czy w werdykcie jest informacja o decyzjach INNYCH wspólników? Z punktu widzenia RODO/Audyta — wspólnik NIE powinien widzieć danych podatkowych innych wspólników (stawka PIT, ulgi). Ale z punktu widzenia solidarnej odpowiedzialności — każdy wspólnik POWINIEN wiedzieć, czy inny wspólnik ma zaległości (bo odpowiada za nie solidarnie).

To jest NIEROZSTRZYGNIĘTY konflikt w obecnym systemie.

**Rekomendacja:** Wprowadzić dwa poziomy werdyktu: `partner_private` (tylko dla danego wspólnika) i `partnership_public` (ryzyka solidarne widoczne dla wszystkich).

#### A3. Brak reguł dla KOREKT HISTORYCZNYCH

System ma reguły dla korekt faktur (GR-89, GR-135), ale NIE dla korekt decyzji PODATKOWYCH po latach. Scenariusz: US stwierdza w 2028 roku, że decyzja VAT z 2026 była błędna. System musi:
1. Odtworzyć stan prawny i progi z 2026
2. Ponownie ewaluować transakcję z danymi z 2026
3. Wygenerować raport różnicowy

Obecny system nie ma reguł dla "time-travel evaluation".

**Rekomendacja:** Dodać `sc.audit.time_travel` — możliwość ewaluacji z historycznymi thresholdami.

---

### 1.7 Testowalność

#### T1. Scenariusze testowe wielo-wspólnikowe

System produkuje rezultaty per `partners[]`. Testy muszą pokryć:
- 2 wspólników 50/50 — standard
- 3 wspólników 33/33/34 — zaokrąglenia
- 2 wspólników z różnymi formami PIT (skala vs liniowy)
- 4 wspólników z mieszanką (skala, liniowy, ryczałt, karta)
- Zmiana udziałów w trakcie roku (przychody przed/po)

Te scenariusze są dobrze zdefiniowane w strukturze `input` (sekcja 4 w 37_GRANULARITY). **ALE**: nie ma gotowych test fixtures. Każdy programista będzie tworzył własne JSON testowe, ryzykując niespójności.

**Rekomendacja:** Stworzyć `test/fixtures/sc_partners_scenarios.json` z 20 predefiniowanymi scenariuszami.

#### T2. Property-based testing dla progów

Progi (`thresholds`) są dynamiczne. Tradycyjne testy jednostkowe z hardcodowanymi wartościami (np. "dla 199 999 PLN → zwolnienie z VAT, dla 200 001 PLN → obowiązek rejestracji") są KRUCHA. Lepsze jest property-based testing: "dla każdej kwoty < threshold → exemption, dla każdej kwoty > threshold → registration".

**Rekomendacja:** Użyć frameworku property-based (jak python-hypothesis) dla testowania progów.

#### T3. Brak testów dla kombinatorycznej eksplozji ulg

Wspólnik może łączyć ulgi: B+R + IP Box + strata + IKZE + darowizny. System sprawdza czy suma ulg < dochód (GR-276), ale NIE ma testów dla WSZYSTKICH kombinacji ulg. Przy 12 ulgach to 2^12 = 4096 kombinacji — ręczne testy niemożliwe.

**Rekomendacja:** Automatycznie generować kombinacje ulg i weryfikować niezmienniki (np. "podstawa opodatkowania nigdy nie może być ujemna po zastosowaniu wszystkich ulg").

---

## Etap 2: Kreatywne Myślenie

### A) 3 Genialne Ulepszenia

---

#### Ulepszenie #1: `ScTemporalSandbox` — Piaskownica Temporalna z Automatycznym Wykrywaniem Okresów Przejściowych

**Na czym polega i jaki problem rozwiązuje:**

Obecny system zakłada, że w danym momencie obowiązuje JEDEN zestaw reguł (jeden zestaw `thresholds`). Ale prawo podatkowe zmienia się w trakcie roku, często z datą wsteczną lub z okresami przejściowymi. Przykład: Polski Ład (2022) zmienił składkę zdrowotną od 1 stycznia, ale Ulga dla klasy średniej została zniesiona od 1 lipca 2022. System nie wie, którą wersję reguł zastosować dla faktury z maja 2022.

**Rozwiązanie:** `ScTemporalSandbox` — mechanizm, który dla KAŻDEJ daty transakcji automatycznie dobiera właściwy zestaw `thresholds` i reguł:

- Każdy zestaw `thresholds` ma `valid_from` i `valid_to`
- Każda reguła ma `effective_period: [date, date]`
- Ewaluator sprawdza `transaction_date` i wybiera odpowiedni zestaw
- Dla dat granicznych (okresy przejściowe) — stosuje regułę `sc_temporal_transition` która określa, czy stosować stare czy nowe prawo

**Dlaczego to jest genialne — wartość dodana:**

- **Odporność na zmiany prawa:** Gdy MF ogłasza nowe stawki, wystarczy dodać nowy zestaw thresholds z datą — stare transakcje są nadal poprawnie ewaluowane
- **Audyt historyczny:** US może poprosić o uzasadnienie decyzji sprzed 3 lat — system odtworzy stan prawny z tamtego okresu
- **Symulacje "what-if":** Spółka może sprawdzić "co by było, gdyby nowe prawo obowiązywało już teraz?"
- **Automatyczne alerty:** System wykrywa, że zbliża się koniec `valid_to` dla danego thresholds i generuje alert "UWAGA: za 30 dni zmienia się stawka X"

**Jak wpływa na bezpieczeństwo / zgodność / zaufanie:**

Eliminuje ryzyko zastosowania nieaktualnych stawek do bieżących transakcji. Daje pełną odtwarzalność decyzji historycznych. Buduje zaufanie: "system zawsze stosuje prawo obowiązujące w dniu transakcji, nie dzisiejsze".

**Przykład koncepcyjny:**

```
thresholds_2026_q1: { vat: 0.23, valid_from: 2026-01-01, valid_to: 2026-03-31 }
thresholds_2026_q2: { vat: 0.24, valid_from: 2026-04-01, valid_to: 2026-12-31 }

Faktura z 2026-02-15 → TemporalSandbox wybiera thresholds_2026_q1 → VAT 23%
Faktura z 2026-05-20 → TemporalSandbox wybiera thresholds_2026_q2 → VAT 24%
Faktura korygująca z 2027 do faktury z lutego 2026 → nadal thresholds_2026_q1 → VAT 23%
```

**Wdrożenie w OPA/Rego:** Możliwe przez `input.thresholds.sc._valid_from` + `input.thresholds.sc._valid_to` + regułę `sc_temporal_select_thresholds` która wybiera zestaw na podstawie `transaction_date`.

---

#### Ulepszenie #2: `ScPartnerMirror` — Lustrzane Odbicie Decyzji dla Wspólników z Separacją Danych Osobowych

**Na czym polega i jaki problem rozwiązuje:**

System produkuje jeden werdykt `final_verdict` zawierający dane wszystkich wspólników. To tworzy fundamentalny konflikt: wspólnik A widzi w werdykcie dane PIT wspólnika B (jego formę opodatkowania, stawkę, ulgi, dochód). Z punktu widzenia RODO i tajemnicy skarbowej — to NIEDOPUSZCZALNE. Z punktu widzenia odpowiedzialności solidarnej — wspólnik A MUSI wiedzieć, czy wspólnik B generuje ryzyko (np. nie płaci ZUS).

**Rozwiązanie:** `ScPartnerMirror` — mechanizm dzielący werdykt na DWIE WARSTWY:

- **PartnerPrivateVerdict:** Zawiera pełne dane TYLKO jednego wspólnika (jego PIT, ZUS, ulgi). Niewidoczny dla innych wspólników.
- **PartnershipRiskMirror:** Zawiera zagregowane, zanonimizowane wskaźniki ryzyka: `partner_count: 3`, `partner_at_risk_count: 1`, `aggregate_zus_overdue: true`, `aggregate_tax_form_conflict: false`. Widoczny dla wszystkich wspólników.

Każdy wspólnik dostaje SWÓJ `PartnerPrivateVerdict` + wspólny `PartnershipRiskMirror`.

**Dlaczego to jest genialne — wartość dodana:**

- Rozwiązuje REALNY konflikt prawny między RODO a odpowiedzialnością solidarną
- Wspólnik widzi "ktoś w spółce nie płaci ZUS — ryzyko solidarne dla Ciebie" ale NIE widzi KTO
- Przy 2 wspólnikach "ktoś" = ten drugi (oczywiste), ale przy 5 wspólnikach — już anonimizacja działa
- Możliwość eskalacji: jeśli ryzyko przekracza próg → `PartnershipRiskMirror` ujawnia konkretnego wspólnika (za jego zgodą lub przy postępowaniu egzekucyjnym)

**Jak wpływa na bezpieczeństwo / zgodność / zaufanie:**

- **RODO:** Minimalizacja danych — każdy wspólnik widzi tylko swoje dane osobowe
- **Solidarność:** Wspólnicy są świadomi ryzyk bez naruszania prywatności innych
- **Zaufanie:** Transparentność ryzyk bez podglądania cudzych rozliczeń

**Przykład koncepcyjny:**

```json
// PartnerPrivateVerdict dla wspólnika A:
{
    "partner_id": "P1",
    "pit_rate": "0.19",
    "pit_annual_income": 145000.00,
    "zus_health_rate": "0.049",
    "allowances_applied": ["B+R", "IKZE"],
    "_private": true
}

// PartnershipRiskMirror (widoczny dla WSZYSTKICH):
{
    "total_partners": 3,
    "partners_with_zus_overdue": 1,       // KTOŚ nie płaci ZUS
    "partners_on_linear": 2,
    "partners_on_scale": 1,
    "aggregate_tax_risk": "MEDIUM",       // bo 1 osoba nie płaci ZUS
    "joint_liability_exposure": 24500.00  // ekspozycja solidarna
}
```

**Wdrożenie:** W Rego — dwie ścieżki generowania werdyktu: `partner_private_verdict[p]` (iterowane per partner) i `partnership_risk_mirror` (agregacja z anonimizacją).

---

#### Ulepszenie #3: `ScLegalGraph` — Graf Powiązań Prawnych z Automatyczną Detekcją Konfliktów Reguł

**Na czym polega i jaki problem rozwiązuje:**

Przy ~1,187 regułach z setkami zależności między regułami, ręczne zarządzanie spójnością jest NIEMOŻLIWE. Gdy dodajemy nową regułę (np. nowa ulga podatkowa), musimy sprawdzić:
- Czy nie koliduje z istniejącą?
- Czy nie tworzy efektu "podwójnego odliczenia"?
- Czy priorytet first-match-wins nie został zaburzony?
- Czy podstawa prawna jest aktualna?

Obecnie to robione jest ręcznie i prowadzi do niespójności (jak pokazałem w sekcji 1.2 S3).

**Rozwiązanie:** `ScLegalGraph` — graf zależności między regułami zbudowany automatycznie z metadanych reguł:

```python
class ScLegalGraph:
    nodes: Dict[RuleId, Rule]  # każda reguła to węzeł
    edges: List[Edge]           # krawędzie to zależności
    
    # Automatycznie wykrywane z pól reguł:
    # GR-276.po = "wszystkich ulgach" → automatycznie tworzy krawędzie od GR-255..GR-275 do GR-276
    # GR-255.podstawa = "Art. 26e PIT" → grupuje z innymi regułami na Art. 26e
```

Na tym grafie można uruchamiać analizy:

- **Cycle detection:** Czy reguła A zależy od B, która zależy od A? → BŁĄD cyklicznej zależności
- **Orphan detection:** Czy reguła nie jest przywoływana przez żadną inną? → może być martwa
- **Priority gap detection:** Czy między priorytetem 255 a 257 jest luka? → brakuje reguły czy celowe?
- **Legal basis coverage:** Które artykuły ustaw nie mają żadnej reguły? → luka w pokryciu prawnym
- **Conflict detection:** Czy dwie reguły mają ten sam priorytet? → konflikt first-match-wins

**Dlaczego to jest genialne — wartość dodana:**

- **Zapobieganie regresjom:** Przy dodawaniu nowej reguły, `ScLegalGraph.validate()` automatycznie sprawdza wszystkie niezmienniki
- **Automatyczna dokumentacja:** Graf można wyrenderować jako diagram zależności (Graphviz/D3.js)
- **Impact analysis:** "Które reguły zostaną dotknięte jeśli zmienię GR-170?" → analiza wpływu w górę i w dół grafu
- **Test generation:** Graf wskazuje minimalny zestaw reguł do przetestowania przy zmianie
- **Coverage reporting:** "Pokryliśmy 87% artykułów z Docs SC, brakuje Art. 26eb ust. 3-4"

**Jak wpływa na bezpieczeństwo / zgodność / zaufanie:**

Eliminuje ryzyko "cichych" konfliktów między regułami. Daje pewność, że każda reguła ma poprawne miejsce w łańcuchu first-match-wins. Automatyzuje audyt spójności — z ręcznego (błędogennego) na automatyczny (powtarzalny).

**Przykład koncepcyjny:**

```
Wykrycie konfliktu:
  GR-255 (B+R 100%) priorytet 255
  GR-256 (B+R 200% CBR) priorytet 256
  → ALERT: GR-255 i GR-256 nakładają się dla CBR! 
  → REKOMENDACJA: GR-256 powinna mieć warunek GR-255 NIE został dopasowany

Wykrycie luki:
  Art. 26eb PIT (ulga na prototyp) ma tylko GR-258 i GR-259
  → ALERT: Art. 26eb ust. 3-4 (koszty produkcji próbnej, limit) nie są pokryte!
  → REKOMENDACJA: Dodaj reguły GR-258a, GR-258b
```

**Wdrożenie:** Nie w OPA/Rego — jako zewnętrzny analizator w Python który parsuje dokumenty Markdown i buduje graf. Można zintegrować z CI/CD — przed każdym deployem reguł.

---

### B) 3 Niesamowite Optymalizacje

---

#### Optymalizacja #1: `ScPackageFusion` — Fuzja Pakietów dla Redukcji Czasu Ewaluacji

**Co jest optymalizowane:** Struktura pakietów i czas ewaluacji OPA.

**Jak działa obecnie:**
System ma ~33 pakiety. Każdy pakiet to osobny plik `.rego`, osobny `package`, osobna ewaluacja przez OPA. Przy 33 pakietach, OPA musi:
1. Sparsować 33 pliki
2. Skompilować 33 pakiety
3. Ewaluować każdy pakiet (nawet jeśli niektóre są puste dla danej transakcji)
4. Scalić wyniki

Dla pojedynczej transakcji to ~10-50ms — akceptowalne. Ale dla batch processing (1000 faktur dziennie) to już 10-50 sekund. Przy skalowaniu do tysięcy spółek — minuty.

**Jak będzie działać po optymalizacji:**
`ScPackageFusion` — statyczna analiza zależności między pakietami i automatyczna fuzja:

- **Pozioma (horizontal fusion):** Pakiety, które NIGDY nie są aktywne jednocześnie (np. `sc.accounting.pkpir` i `sc.accounting.full`) są łączone w jeden plik z warunkowym routingiem — tylko jedna ścieżka ewaluowana
- **Pionowa (vertical fusion):** Pakiety, które zawsze wykonują się sekwencyjnie jako pipeline (np. `sc.vat.substantive` → `sc.vat.deductions` → `sc.vat.tax_point`) są łączone w jeden pakiet z wewnętrznym routingiem
- **Martwe pakiety:** Pakiety bez reguł pasujących do bieżącego profilu spółki (np. `sc.crossborder` dla spółki działającej tylko w PL) są pomijane

Wynik: z 33 pakietów → ~12 skondensowanych pakietów.

**Dlaczego to optymalizacja na poziomie ENTERPRISE:**
- Redukcja liczby plików `.rego` o 60% (33 → 12)
- Redukcja czasu parsowania i kompilacji o ~50%
- Eliminacja "pustych przebiegów" (pakiety bez reguł pasujących do transakcji)
- Łatwiejsze zarządzanie — mniej plików = mniej merge conflicts

**Szacowany zysk:** Redukcja czasu ewaluacji batch o ~40% (z 30s do ~18s dla 1000 faktur).

**⚠️ Ważne zastrzeżenie:** OPA wewnętrznie inlinuje i optymalizuje kod — przed fuzją pakietów należy sprofilować rzeczywisty koszt przekraczania granic pakietów używając `opa eval --explain full`. Fuzja powinna być stosowana tylko tam, gdzie profilowanie wykaże mierzalny narzut. Nieuzasadniona fuzja grozi utratą czytelności separacji domen (VAT vs PIT vs ZUS) — co jest jednym z największych osiągnięć architektonicznych systemu.

---

#### Optymalizacja #2: `ScThresholdPrecompute` — Prekompilacja Thresholdów z DuckDB do Rego Data

**Co jest optymalizowane:** Proces ładowania i stosowania parametrów dynamicznych.

**Jak działa obecnie:**
`thresholds` są częścią `input` JSON przekazywanego do OPA przy każdej ewaluacji. Dla każdej transakcji ten sam zestaw ~30 progów jest wysyłany jako część inputu. OPA musi parsować thresholds przy każdej ewaluacji. Dodatkowo, thresholds są przechowywane w DuckDB i pobierane przed ewaluacją — dodatkowy round-trip do bazy.

**Jak będzie działać po optymalizacji:**
`ScThresholdPrecompute` — proces budowania:

1. DuckDB → eksport thresholds jako `data.sc.thresholds` (plik Rego)
2. `opa build` kompiluje thresholds razem z regułami do bundle
3. Bundle zawiera thresholds jako `data.sc.thresholds.*` — dostępne natywnie w Rego bez parsowania JSON
4. Aktualizacja thresholds = nowy build bundle (automatycznie przez CI/CD)

Zamiast:
```json
// Wysyłane w każdym requeście:
{"thresholds": {"sc": {"rates": {"vat_standard": 0.23, ...}}}}
```

Bundle OPA zawiera:
```rego
package data.sc.thresholds
rates := {"vat_standard": 0.23, ...}
```

**Dlaczego to optymalizacja na poziomie ENTERPRISE:**
- Eliminacja round-trip do DuckDB dla każdej transakcji
- Redukcja rozmiaru input JSON o ~1KB na transakcję
- Thresholds jako kod Rego — OPA może je optymalizować podczas kompilacji (inlining, constant folding)
- Atomowa aktualizacja — nowy bundle = nowe thresholds, bez ryzyka niespójności

**Szacowany zysk:** Redukcja czasu ewaluacji pojedynczej transakcji o ~15-25%. Eliminacja 100% zapytań DuckDB dla thresholds.

**⚠️ Ważne zastrzeżenie:** Wymaga rebuild bundle OPA przy każdej zmianie thresholds — to potencjalnie koliduje z filozofią "zero hardcoded values" (sekcja 1.4 U1). Rozwiązanie: rebuild bundle jest w pełni zautomatyzowany przez CI/CD pipeline (DuckDB → generacja `data.sc.thresholds` → `opa build` → deploy). Deweloper NIGDY nie dotyka plików thresholds ręcznie — zawsze przez DuckDB.

---

#### Optymalizacja #3: `ScVerdictStreaming` — Strumieniowe Generowanie Werdyktów dla Batch Processing

**Co jest optymalizowane:** Proces batchowego przetwarzania faktur.

**Jak działa obecnie:**
Każda faktura jest przetwarzana niezależnie — pełny cykl: input → OPA → werdykt. Dla 1000 faktur to 1000 osobnych ewaluacji OPA, każda z pełnym kontekstem (thresholds, partnership data, partners). Partnership data (wspólnicy, udziały) zmienia się rzadko (raz na miesiąc/kwartał), ale jest wysyłana przy KAŻDEJ fakturze.

**Jak będzie działać po optymalizacji:**
`ScVerdictStreaming` — architektura strumieniowa z podziałem na "wolnozmienne" i "szybkozmienne" dane:

1. **Session context (wolnozmienne):** partnership, partners, thresholds — ładowane RAZ na sesję (np. raz dziennie)
2. **Transaction stream (szybkozmienne):** faktury — płyną strumieniem
3. OPA ewaluuje z pre-załadowanym session context + każdą fakturą

Implementacja przez OPA's `data` API:
```bash
# 1. Załaduj kontekst
curl -X PUT http://opa:8181/v1/data/sc/context -d @partnership_context.json

# 2. Ewaluuj faktury bez przesyłania kontekstu
for invoice in invoices/*.json; do
    curl -X POST http://opa:8181/v1/data/sc/rules/evaluate -d @$invoice
done
```

**Dlaczego to optymalizacja na poziomie ENTERPRISE:**
- Partnership data (kilka KB) wysyłana RAZ zamiast 1000 razy
- Redukcja transferu danych o ~99%
- Możliwość pipeline'owania — podczas gdy faktura N jest ewaluowana, faktura N+1 jest już parsowana
- Naturalnie pasuje do architektury mikroserwisów

**Szacowany zysk:** Redukcja całkowitego czasu batch processing o ~60%. Dla 10 000 faktur dziennie: z ~5 minut do ~2 minut.

---

### C) 3 Potężne i Szczegółowe Pomysły

---

#### Pomysł #1: `ScWhatIf Engine` — Silnik Symulacji Podatkowych "Co By Było Gdyby"

**Szczegółowy opis:**

Silnik pozwalający wspólnikom SC na symulowanie alternatywnych scenariuszy podatkowych PRZED podjęciem decyzji biznesowych:

- "Co by było, gdybym zmienił formę opodatkowania z liniowego na skalę?"
- "Co by było, gdybyśmy przyjęli trzeciego wspólnika z 20% udziałem?"
- "Co by było, gdyby spółka przekroczyła 2M EUR i musiała przejść na pełną księgowość?"
- "Co by było, gdybym wypłacił sobie zaliczkę 50 000 PLN teraz vs w styczniu?"
- "Co by było, gdyby spółka kupiła samochód elektryczny vs spalinowy?"

**Jak to działa w OPA/Rego:**

```rego
# Specjalny tryb ewaluacji:
sc_what_if {
    input._mode == "SIMULATION"
    input._simulation_scenario == "CHANGE_TAX_FORM"
    input._simulation_params == {"partner_id": "P1", "new_tax_form": "PIT_SCALE"}
}

# Reguły używają simulation params zamiast rzeczywistych:
partner_tax_form[p] = form {
    p := input.partners[_]
    not input._simulation
    form := p.tax_form
}

partner_tax_form[p] = form {
    p := input.partners[_]
    input._simulation
    input._simulation_params.partner_id == p.id
    form := input._simulation_params.new_tax_form
}
```

**Wynik dla wspólnika:**
```
SCENARIUSZ: Zmiana z liniowego 19% na skalę 12%/32%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rzeczywisty PIT (liniowy):    27 550 PLN
Symulowany PIT (skala):       18 400 PLN
Oszczędność:                   9 150 PLN
⚠️  Uwaga: Skala = wyższa składka zdrowotna (9% vs 4.9%)
    Rzeczywista zdrowotna:     7 105 PLN
    Symulowana zdrowotna:     13 050 PLN
    ⚠️  Łącznie: PIT -9 150 PLN ale ZUS +5 945 PLN → netto: -3 205 PLN
    DECYZJA: Liniowy nadal lepszy mimo wyższego PIT!
```

**Wykonalność w OPA/Rego:**

- **Średnia.** OPA nie ma natywnego mechanizmu "pomiń blok reguł jeśli symulacja" — reguły w bloku są ewaluowane niezależnie od `_mode`. Wymagane jest jedno z dwóch podejść:
  - **Podejście A (zalecane):** Zewnętrzny orkiestrator (Python) uruchamia OPA dwukrotnie — raz z rzeczywistym inputem, raz z symulowanym — i porównuje werdykty. To prostsze i nie wymaga modyfikacji reguł.
  - **Podejście B:** Każda reguła otrzymuje guard `not input._simulation` — ale to zanieczyszcza kod 435+ reguł i jest nieutrzymywalne.
- Przy Podejściu A, OPA nie wymaga zmian — symulacja to po prostu druga ewaluacja z nadpisanymi parametrami w input.
- Silnik porównujący dwa werdykty (rzeczywisty vs symulowany) — w Python.

**Korzyści dla spółki cywilnej i wspólników:**

- **Optymalizacja podatkowa:** Wspólnicy mogą podjąć świadomą decyzję o formie opodatkowania
- **Planowanie inwestycji:** Symulacja wpływu zakupu środka trwałego na KUP i amortyzację
- **Planowanie sukcesji:** Co się stanie z podatkami gdy wspólnik umrze a zarządca sukcesyjny przejmie?
- **De-risking:** Przed przyjęciem nowego wspólnika — symulacja zmiany podziału przychodów/kosztów

**Koncepcja wdrożenia:**

1. Rozszerzyć `input` o pola symulacyjne: `_mode`, `_simulation_scenario`, `_simulation_params`
2. Dodać reguły `sc.what_if.*` które nadpisują rzeczywiste parametry symulowanymi
3. Zbudować `ScScenarioComparator` w Python który zestawia dwa werdykty
4. UI: prosty formularz "Co by było gdyby" z suwakami dla parametrów
5. Zapisywać historię symulacji dla audytu

---

#### Pomysł #2: `ScAnomalyGuard` — Proaktywny System Wykrywania Anomalii z Machine Learning

**Szczegółowy opis:**

System wykraczający poza statyczne reguły OPA — integracja uczenia maszynowego do wykrywania anomalii w fakturach i transakcjach spółki cywilnej:

- **Pattern recognition:** "Ta faktura wygląda normalnie, ALE odstaje od historycznego wzorca faktur tej spółki"
- **Partner behavior profiling:** "Wspólnik A generuje 3x więcej kosztów niż wspólnik B — potencjalne nadużycie"
- **Seasonal anomaly detection:** "W grudniu spółka nagle ma 10x więcej faktur niż w pozostałych miesiącach — potencjalne sztuczne generowanie kosztów"
- **Vendor clustering:** "Ten nowy kontrahent ma identyczny wzorzec faktur co znany frauder z innej spółki"

**Architektura:**

```
INPUT → OPA (reguły statyczne) → werdykt_statyczny
     → ML Model (anomalie)      → anomaly_score
     → ScAnomalyGuard            → werdykt_finalny (statyczny + anomaly)
```

**Jak to działa w OPA/Rego:**

OPA NIE wykonuje ML — odbiera `anomaly_score` jako pole w input:

```json
{
    "invoice": {...},
    "_ml_anomaly": {
        "amount_anomaly_score": 0.92,
        "vendor_anomaly_score": 0.15,
        "partner_anomaly_score": 0.73,
        "seasonal_anomaly_score": 0.88,
        "combined_anomaly_risk": "HIGH"
    }
}
```

Reguły OPA:
```rego
sc_anomaly_guard_block {
    input._ml_anomaly.combined_anomaly_risk == "HIGH"
    input.invoice.amount_net > 50000  # tylko dla wysokich kwot
    _routing := "BLOCK_AND_ALERT"
}

sc_anomaly_guard_flag {
    input._ml_anomaly.combined_anomaly_risk == "MEDIUM"
    _routing := "TRIAGE_QUEUE"
    _warning := "Anomalia ML — wymagana weryfikacja manualna"
}
```

**Wykonalność:**

- **Średnia.** Wymaga zewnętrznego serwisu ML (Python scikit-learn lub TensorFlow)
- ML model musi być trenowany na historycznych fakturach (wymagane dane)
- Integracja przez REST API: OPA wywołuje ML service (lub ML service wzbogaca input przed OPA)
- Wyzwanie: model musi być audytowalny (dlaczego uznał fakturę za anomalię?)

**Korzyści dla spółki cywilnej i wspólników:**

- **Wczesne ostrzeganie:** Anomalia wykryta przed zaksięgowaniem = uniknięcie konsekwencji podatkowych
- **Ochrona przed fraudem wewnętrznym:** Profilowanie zachowań wspólników
- **Redukcja false positives:** ML uczy się co jest "normalne" dla tej konkretnej SC
- **Przewaga konkurencyjna:** Żaden konkurencyjny system nie oferuje ML-based anomaly detection dla SC

**Koncepcja wdrożenia:**

1. Faza 1 (MVP): Proste reguły statystyczne w Rego (średnia, odchylenie standardowe, sezonowość)
2. Faza 2: Trenowanie modelu Isolation Forest na historycznych fakturach
3. Faza 3: Pełna integracja OPA + ML pipeline z explainable AI (SHAP values)
4. Wymagane dane: minimum 12 miesięcy faktur dla każdej spółki
5. Koszt: ~2-3 miesiące pracy data scientista + MLOps

---

#### Pomysł #3: `ScRegulatoryRadar` — Automatyczny Monitoring Zmian Legislacyjnych i Aktualizacja Reguł

**Szczegółowy opis:**

System, który automatycznie monitoruje zmiany w prawie podatkowym i proponuje aktualizacje reguł OPA:

- Monitoruje Dzienniki Ustaw, rozporządzenia MF, interpretacje podatkowe, orzecznictwa NSA
- Porównuje zmiany z istniejącymi regułami (przez `_legal_basis`)
- Generuje alerty: "Art. 26e PIT został znowelizowany — dotyczy reguł: GR-255, GR-256, GR-257"
- Automatycznie proponuje nowe wartości thresholds: "Nowy limit ulgi termomodernizacyjnej: 53 000 → 60 000 PLN"
- Generuje diff reguł: "Stara reguła vs nowa reguła" z komentarzem "Art. X zmieniony przez Dz.U. 2026 poz. 1234"

**Architektura:**

```
Dzienniki Ustaw ──► NLP Parser ──► Zmiana Legislacyjna
RCL.gov.pl     ──►              ──► ChangeDetector
ISAP.sejm.gov  ──►              ──► ImpactAnalyzer
MF interpret.  ──►              ──► RuleUpdater ──► Pull Request do repo .rego
```

**Jak to działa z OPA/Rego:**

`ScRegulatoryRadar` NIE modyfikuje reguł OPA automatycznie — generuje Pull Request do review przez eksperta:

```markdown
## 🤖 Auto-PR: Aktualizacja Art. 26h PIT (Ulga termomodernizacyjna)

**Źródło:** Dz.U. 2026 poz. 1567 z dnia 2026-11-15
**Zmiana:** Limit odliczenia wzrasta z 53 000 PLN do 60 000 PLN
**Dotknięte reguły:** GR-266 (sc_allowance_thermo), GR-228 (sc_pit_relief_termomodernization)

### Proponowane zmiany:

\`\`\`diff
- thermo_cap: 53000
+ thermo_cap: 60000
\`\`\`

**Data wejścia w życie:** 2027-01-01
**Okres przejściowy:** Nie dotyczy
```

**Wykonalność:**

- **Średnia.** Wymaga zaawansowanego NLP do parsowania polskiego języka prawnego
- Może zacząć od prostszej wersji: monitorowanie metadanych (tytuł ustawy, artykuł, data wejścia) zamiast pełnego NLP
- Kluczowe: `_legal_basis` w każdej regule (już jest!) umożliwia automatyczne mapowanie zmiany → reguła
- Integracja z GitHub Actions: cykliczny cron sprawdzający RCL API

**Korzyści dla spółki cywilnej i wspólników:**

- **Zawsze aktualne reguły:** System sam proponuje aktualizacje — ekspert tylko akceptuje
- **Zero-day compliance:** Zmiana prawa wykryta w dniu publikacji, reguły zaktualizowane przed wejściem w życie
- **Audytowalność:** Każda zmiana reguły ma link do Dziennika Ustaw jako źródło
- **Przewaga konkurencyjna:** Automatyzacja compliance = redukcja kosztów doradztwa podatkowego

**Koncepcja wdrożenia:**

1. Faza 1: Crawler RCL + mapowanie `_legal_basis` → lista dotkniętych reguł
2. Faza 2: Automatyczna ekstrakcja nowych wartości liczbowych (limity, stawki, progi)
3. Faza 3: Generowanie Pull Request z proponowanymi zmianami
4. Faza 4: Pełny NLP do rozumienia zmian jakościowych (nowe warunki, nowe wyjątki)
5. Wymagane: dostęp do API Rządowego Centrum Legislacji, moduł NLP dla tekstów prawnych

---

## Podsumowanie

| Obszar | Obecna ocena | Potencjał po wdrożeniu |
|--------|:-----------:|:----------------------:|
| Kompletność | 8/10 | 9.5/10 |
| Spójność | 6/10 (duplikacje, niespójne priorytety) | 9/10 |
| Skalowalność | 7/10 | 9/10 |
| Utrzymywalność | 5/10 (hardcodowane wartości w opisach) | 9/10 |
| Wydajność | 7/10 | 9/10 |
| Audytowalność | 8/10 | 9.5/10 |
| Testowalność | 5/10 (brak fixtures, brak property testing) | 8/10 |

**Priorytety wdrożenia ulepszeń (rekomendowany plan działania):**

| Priorytet | Ulepszenie | Czas wdrożenia | Impact |
|:---------:|-----------|:-------------:|:------:|
| 🔴 P0 | U1: Eliminacja hardcodowanych wartości z opisów | 2 dni | Wysoki |
| 🔴 P0 | S3: Ustandaryzowanie priorytetów P↔GR | 3 dni | Krytyczny |
| 🟡 P1 | Ulepszenie #1: ScTemporalSandbox | 2 tygodnie | Transformacyjny |
| 🟡 P1 | Optymalizacja #3: ScVerdictStreaming | 1 tydzień | Wysoki |
| 🟢 P2 | Ulepszenie #3: ScLegalGraph | 3 tygodnie | Strategiczny |
| 🟢 P2 | Pomysł #3: ScRegulatoryRadar (Faza 1) | 4 tygodnie | Strategiczny |
| 🔵 P3 | Pomysł #1: ScWhatIf Engine | 6 tygodni | Konkurencyjny |
| 🔵 P3 | Pomysł #2: ScAnomalyGuard | 8 tygodni | Innowacyjny |

**Łączny koszt wdrożenia wszystkich rekomendacji:** ~24 tygodnie (6 miesięcy) dla zespołu 3-osobowego.

**Następny krok:** Wybór priorytetów P0 do natychmiastowej implementacji.
