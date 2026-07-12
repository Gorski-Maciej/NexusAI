# 🔬 NexusAI JDG — Advanced Gap Analysis: 20 Obszarów Krytycznych ENTERPRISE

> **Status:** 🔴 CRITICAL GAP DISCOVERY v3.0 — Obszary NIEPOKRYTE w dokumentach 22-43  
> **Data:** 2026-07-12  
> **Autor:** Zespół NexusAI — Deep Analysis  
> **Plik:** `Plan OPA/44_JDG_ADVANCED_GAPS.md`  
> **Bazuje na:** Głębokiej analizie ~800 reguł kanonicznych z `38c_JDG_CANONICAL_MAP.md`, audycie luk w dokumentach 22-43, `DocsJDG` (źródła prawne)  
> **Przeznaczenie:** Identyfikacja 20 całkowicie niepokrytych obszarów o znaczeniu krytycznym dla bezpieczeństwa prawnego, zgodności i zaufania w systemie ENTERPRISE. Każda reguła zawiera: nazwę, cel biznesowy, przesłanki, rezultat, podstawę prawną, zależności, edge cases, parametry z `input.thresholds` oraz przykłady ±.

---

## 📊 EXECUTIVE SUMMARY

### Dlaczego ten dokument?

Po przeanalizowaniu **~800 reguł kanonicznych** w 43 dokumentach (22-43 + 38c), zidentyfikowano **20 obszarów krytycznych**, które są **całkowicie niepokryte** (0% pokrycia) lub pokryte marginalnie (<5%). Obszary te reprezentują ryzyko prawne, compliance i bezpieczeństwa dla systemu klasy ENTERPRISE.

| Metryka | Wartość |
|---------|:-------:|
| **Obszary przeanalizowane** | 20 |
| **Nowe reguły Macro (P-ID)** | **~115** |
| **Nowe pakiety .rego** | **11** |
| **Nowe thresholds** | **~55** |
| **Reguły klasy 🚨 CRITICAL** | **42** |

### Obszary zidentyfikowane jako NIEPOKRYTE

| # | Obszar | Pokrycie obecne | Nowe P-ID | Krytyczność |
|---|--------|:---------------:|:---------:|:-----------:|
| 1 | **MDR (DAC6) — Raportowanie schematów podatkowych** | 0% | P1800-P1809 | 🔴 CRITICAL |
| 2 | **Danina solidarnościowa 4%** | 0% | P1810-P1814 | 🔴 CRITICAL |
| 3 | **WIS/WIA/WIT — Wiążące informacje podatkowe** | 0% | P1820-P1827 | 🟡 HIGH |
| 4 | **Kontrola podatkowa — procedury szczegółowe** | ~5% | P1830-P1844 | 🔴 CRITICAL |
| 5 | **Siła wyższa i ciągłość działania** | 0% | P1850-P1857 | 🟡 HIGH |
| 6 | **Członkowie rodziny w JDG** | ~2% | P1860-P1869 | 🟡 HIGH |
| 7 | **E-komunikacja z organami podatkowymi** | 0% | P1870-P1877 | 🔴 CRITICAL |
| 8 | **Zamówienia publiczne i certyfikaty podatkowe** | 0% | P1880-P1886 | 🟡 HIGH |
| 9 | **Rozliczenia w walutach obcych** | ~3% | P1890-P1898 | 🟡 HIGH |
| 10 | **Podpisy elektroniczne i dokumentacja cyfrowa** | 0% | P1900-P1906 | 🟡 HIGH |
| 11 | **Kalendarz płatności — Master Calendar** | 0% | P1910-P1915 | 🟡 HIGH |
| 12 | **Kwota wolna 30k — interakcje wieloźródłowe** | ~3% | P1920-P1925 | 🟡 HIGH |
| 13 | **Ceny transferowe dla JDG (TPR)** | ~2% (P29, P114 — tylko safe harbor/progi) | P1930-P1938 | 🔴 CRITICAL |
| 14 | **Rezydencja podatkowa i podwójne opodatkowanie** | ~2% | P1940-P1949 | 🔴 CRITICAL |
| 15 | **Działalność sezonowa** | 0% | P1950-P1956 | 🟢 MEDIUM |
| 16 | **Wpływ skazania KKS na działalność JDG** | ~2% | P1960-P1965 | 🟡 HIGH |
| 17 | **Zawody regulowane — specyfika podatkowa** | 0% | P1970-P1977 | 🟢 MEDIUM |
| 18 | **Obowiązkowe ubezpieczenia OC zawodowe** | 0% | P1980-P1985 | 🟢 MEDIUM |
| 19 | **Niestandardowe formy płatności** | ~2% (P1700-P1701 — tylko NFT/DeFi) | P1990-P1998 | 🟡 HIGH |
| 20 | **Reklama i marketing — szczegółowe KUP** | ~1% | P1999-P2007 | 🟢 MEDIUM |

---

# CZĘŚĆ 1: MDR (DAC6) — RAPORTOWANIE SCHEMATÓW PODATKOWYCH 🚨

> **Dlaczego krytyczne:** Dyrektywa DAC6 (2018/822/UE) nakłada na JDG — w tym na doradców podatkowych i biura rachunkowe — obowiązek raportowania transgranicznych schematów podatkowych podlegających zgłoszeniu (MDR). Brak zgłoszenia = sankcje KKS, kary administracyjne do 5M PLN, odpowiedzialność karna-skarbowa. System ENTERPRISE musi automatycznie wykrywać cechy rozpoznawcze (hallmarks) i flagować obowiązek raportowania MDR-1/MDR-3.

---

### P1800 🆕 `mdr_reportable_scheme_detection` 🚨

- **Cel biznesowy:** Automatyczne wykrywanie czy transakcja JDG nosi cechy schematu podatkowego podlegającego zgłoszeniu MDR (Mandatory Disclosure Rules). Analiza cech rozpoznawczych (hallmarks) z Załącznika do Ordynacji podatkowej.
- **Przesłanki — lista hallmark (cech rozpoznawczych):**
  - `input.invoice.cross_border_element == true` (element transgraniczny)
  - `input.invoice.tax_benefit_type` ∈ `["DOUBLE_DEDUCTION", "NO_TAXATION", "LOW_TAXATION", "DEFERRAL", "CONVERSION"]`
  - `input.invoice.confidentiality_clause == true` (klauzula poufności wobec innych doradców/US)
  - `input.invoice.success_fee_structure == true` (wynagrodzenie uzależnione od efektu podatkowego)
  - `input.invoice.standardized_documentation == true` (wystandaryzowana dokumentacja)
  - `input.invoice.loss_buying_scheme == true` (nabywanie spółek ze stratą dla celów podatkowych)
  - `input.invoice.circular_flow == true` (transakcje okrężne)
  - `input.invoice.tax_haven_involved == true` (zaangażowany raj podatkowy)
- **Rezultat:**
  - `mdr_reportable: true`
  - `mdr_hallmarks_matched: [lista dopasowanych cech]`
  - `mdr_report_type: "MDR-1"` (schemat krajowy) lub `"MDR-3"` (schemat transgraniczny)
  - `mdr_deadline_days: 30` (30 dni od udostępnienia/ przygotowania/ pierwszej czynności)
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Transakcja nosi cechy schematu podatkowego MDR — obowiązek zgłoszenia MDR-3 w ciągu 30 dni! Sankcja: kara administracyjna do 5M PLN + KKS."`
- **Podstawa prawna:** Art. 86a-86o Ordynacji podatkowej, Rozporządzenie MF ws. MDR, Dyrektywa DAC6 (2018/822/UE)
- **Edge cases:**
  - (a) JDG-biurow rachunkowe wykrywające schemat u klienta — obowiązek raportowania przez JDG (promotora)
  - (b) Schemat czysto krajowy bez elementu transgranicznego — MDR-1 zamiast MDR-3
  - (c) Legal professional privilege (tajemnica zawodowa adwokata/radcy) — wyłączenie z obowiązku raportowania; obowiązek przechodzi na klienta (JDG)
  - (d) Schemat wdrożony przed obowiązywaniem MDR (przed 01.01.2019) — brak obowiązku raportowania, chyba że modyfikowany po tej dacie
- **Zależności:** Przed regułami Compliance (P20-P39). W pakiecie `jdg.compliance.mdr`.
- **Thresholds:** `jdg.mdr.reporting_deadline_days` (30), `jdg.mdr.hallmarks_catalog` (lista), `jdg.mdr.tax_haven_jurisdictions` (lista)
- **`[TODO: potrzebne źródło]`** — lista jurysdykcji uznawanych za raje podatkowe (Rozporządzenie MF, aktualizowane corocznie)
- **Przykład +:** JDG tworzy strukturę z podmiotem na Cyprze, klauzula poufności, success fee dla doradcy → `mdr_reportable: true`, MDR-3 w 30 dni
- **Przykład −:** Standardowa transakcja B2B w PL, brak elementów transgranicznych → `mdr_reportable: false`

---

### P1801 🆕 `mdr_promoter_vs_user_determination` 🚨

- **Cel biznesowy:** Ustalenie czy JDG działa jako promotor (doradca/biuro rachunkowe tworzące schemat), czy jako korzystający (korzystający ze schematu). Różne obowiązki raportowania dla każdej roli.
- **Przesłanki:**
  - `input.jdg_entrepreneur.pkd_main` ∈ `["69.20.Z" (księgowość), "69.10.Z" (doradztwo prawne), "70.22.Z" (doradztwo podatkowe)]` → POTENCJALNY PROMOTOR
  - `input.jdg_entrepreneur.pkd_main` ∉ powyższych → POTENCJALNY KORZYSTAJĄCY
- **Różnice obowiązków:**

| Rola | Formularz | Termin | Odpowiedzialność |
|:---|:---|:---|:---|
| **PROMOTOR** | MDR-3 | 30 dni od udostępnienia schematu | Odpowiada za niezgłoszenie (nawet jeśli klient zgłosił) |
| **KORZYSTAJĄCY** | MDR-3 | 30 dni od pierwszej czynności w schemacie | Odpowiada za niezgłoszenie własnego udziału |
| **PROMOTOR Z TAJEMNICĄ** | MDR-3 (powiadamia klienta) | 30 dni | Przerzuca obowiązek na korzystającego |

- **Rezultat:**
  - `mdr_role: "PROMOTER" | "USER" | "PROMOTER_WITH_PRIVILEGE"`
  - `mdr_reporting_obligation: <wg tabeli>`
  - `_warning: "Rola MDR: X. Obowiązek raportowania: Y."`
- **Podstawa prawna:** Art. 86a § 1 pkt 1-3 Ordynacji podatkowej
- **Zależności:** Wywoływana po P1800.
- **Przykład +:** Biuro rachunkowe JDG tworzy optymalizację z holenderską spółką → PROMOTOR, obowiązek MDR-3
- **Przykład −:** JDG IT korzysta z gotowego schematu kupionego od doradcy → KORZYSTAJĄCY, obowiązek własny (jeśli promotor nie zgłosił)

---

### P1802 🆕 `mdr_deadline_tracking_and_penalty` 🚨

- **Cel biznesowy:** Śledzenie terminów MDR i kalkulacja potencjalnych kar za brak zgłoszenia. Kara administracyjna + sankcja KKS.
- **Przesłanki:**
  - `input.mdr.reportable_scheme.identified_date` znane
  - `input.mdr.reportable_scheme.mdr_submitted == false`
  - `days_since_identification > input.thresholds.jdg.mdr.reporting_deadline_days`
- **Rezultat:**
  - `mdr_overdue: true`
  - `mdr_days_overdue: <liczba dni po terminie>`
  - `mdr_administrative_penalty: "up_to_5_000_000_PLN"`
  - `mdr_kks_risk: true` (Art. 54-56 KKS w zw. z Art. 86o § 3 OP — odpowiedzialność karna-skarbowa za niezłożenie MDR)
  - `_warning: "MDR-3 niezłożony! Opóźnienie: X dni. Ryzyko kary administracyjnej do 5M PLN + odpowiedzialność KKS (Art. 54-56)."`
- **Podstawa prawna:** Art. 86o Ordynacji podatkowej, Art. 54-56 KKS (odpowiedzialność karna-skarbowa za niezgłoszenie schematu podatkowego) **[TODO: zweryfikować konkretny artykuł KKS dla sankcji MDR — w obecnym stanie prawnym sankcje KKS za MDR wynikają z ogólnych przepisów o uchylaniu się od opodatkowania i nierzetelnych deklaracjach]**
- **Zależności:** Po P1800, P1801.
- **Thresholds:** `jdg.mdr.reporting_deadline_days` (30), `jdg.mdr.administrative_penalty_max` (5_000_000)
- **Przykład +:** Schemat zidentyfikowany 01.01, dziś 15.02 → 45 dni → `mdr_overdue: true`, 15 dni po terminie
- **Przykład −:** Schemat zidentyfikowany 01.01, MDR-3 złożony 20.01 → `mdr_overdue: false`

---

### P1803-P1809 🆕 — POZOSTAŁE REGUŁY MDR

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1803** | `mdr_hallmark_main_benefit_test` | Test głównej korzyści (MBT) — czy główną korzyścią z transakcji jest korzyść podatkowa. Dla hallmarks kategorii A i B. Art. 86a § 2 OP. |
| **P1804** | `mdr_hallmark_category_c_specific` | Hallmarks kategorii C (specyficzne dla transgranicznych): nabycie spółki ze stratą (C1), konwersja dochodu (C2), transakcje okrężne (C3), odliczenia transgraniczne (C4). Art. 86d OP. |
| **P1805** | `mdr_hallmark_category_d_transfer_pricing` | Hallmarks kategorii D (TP-specific): transfer wartości niematerialnych transgranicznie (D1), transfer funkcji/ryzyk (D2). Art. 86e OP. |
| **P1806** | `mdr_hallmark_category_e_exchange` | Hallmarks kategorii E (automatyczna wymiana informacji i beneficial ownership): obchodzenie automatycznej wymiany informacji (CRS/DAC), ukrywanie beneficjenta rzeczywistego. Art. 86f OP. |
| **P1807** | `mdr_quarterly_summary_report` | Obowiązek kwartalnego raportowania MDR-4 (zestawienie wszystkich zgłoszonych schematów w kwartale). Termin: do końca miesiąca po kwartale. |
| **P1808** | `mdr_statute_of_limitations` | Przedawnienie obowiązku raportowania MDR: okres retencji danych o schematach = 6 lat od zakończenia roku, w którym schemat był dostępny. |
| **P1809** | `mdr_aggregate_risk_jdg` | Agregacja ryzyka MDR dla JDG — profil ryzyka, historia zgłoszeń, ekspozycja na sankcje. |

---

# CZĘŚĆ 2: DANINA SOLIDARNOŚCIOWA 4% 🚨

> **Dlaczego krytyczne:** Od 2019 roku osoby fizyczne (w tym JDG) o dochodach > 1 000 000 PLN rocznie płacą dodatkowy podatek 4% (daninę solidarnościową) od nadwyżki ponad 1M PLN. Obowiązek dotyczy dochodów opodatkowanych skalą PIT, liniowym, ryczałtem, IP Box, z kapitałów pieniężnych i z zagranicy. System ENTERPRISE musi automatycznie wykrywać obowiązek i kalkulować daninę.

---

### P1810 🆕 `solidarity_levy_threshold_detection_jdg` 🚨

- **Cel biznesowy:** Automatyczne wykrycie przekroczenia progu 1 000 000 PLN dochodu rocznego, skutkującego obowiązkiem zapłaty daniny solidarnościowej 4%.
- **Przesłanki:**
  - Suma dochodów JDG ze wszystkich źródeł (skala + liniowy + ryczałt + IP Box + kapitały + zagraniczne) > `input.thresholds.jdg.limits.solidarity_levy_threshold`
  - `input.jdg_entrepreneur.tax_form` ∈ `["PIT_SCALE", "LINEAR", "LUMP_SUM"]`
- **Rezultat:**
  - `solidarity_levy_applies: true`
  - `solidarity_levy_threshold: 1_000_000`
  - `solidarity_levy_base: sum(dochod) - 1_000_000`
  - `solidarity_levy_rate: 0.04`
  - `solidarity_levy_due: solidarity_levy_base * 0.04`
  - `solidarity_levy_deadline: "30_kwietnia_nastepnego_roku"`
  - `_warning: "Twój łączny dochód przekroczył 1 000 000 PLN — danina solidarnościowa 4% od nadwyżki. Termin zapłaty: 30 kwietnia."`
- **Podstawa prawna:** Art. 30h PIT (Danina solidarnościowa)
- **Edge cases:**
  - (a) Dochód 1 200 000 PLN → podstawa 200 000 PLN → danina 8 000 PLN
  - (b) Dochód 5 000 000 PLN → podstawa 4 000 000 PLN → danina 160 000 PLN
  - (c) Dochód z zagranicy + dochód z PL → sumuje się do progu 1M
  - (d) Strata z JDG + dochód z kapitałów > 1M → danina TYLKO od nadwyżki, strata JDG nie pomniejsza innych dochodów dla celów daniny (osobne źródła)
  - (e) Wspólne rozliczenie małżonków — próg 1M liczony INDYWIDUALNIE dla każdego małżonka
- **Zależności:** Po P500-P539 (formy opodatkowania PIT). Niezależna od standardowego PIT.
- **Thresholds:** `jdg.limits.solidarity_levy_threshold` (1_000_000), `jdg.rates.solidarity_levy_rate` (0.04)
- **Przykład +:** Dochód JDG 1 500 000 PLN → danina = 20 000 PLN (4% z 500k)
- **Przykład −:** Dochód JDG 800 000 PLN → `solidarity_levy_applies: false`

---

### P1811 🆕 `solidarity_levy_income_aggregation_jdg`

- **Cel biznesowy:** Agregacja dochodów z różnych źródeł dla celów daniny solidarnościowej — skala, liniowy, ryczałt, IP Box, kapitały pieniężne, zagraniczne.
- **Przesłanki:**
  - Agregacja dochodów z: `input.jdg_entrepreneur.income_scale` + `income_linear` + `income_lump_sum` + `income_ip_box` + `income_capital` + `income_foreign`
  - Sumowanie po odliczeniu składek społecznych (ZUS emerytalne + rentowe), ale PRZED składką zdrowotną
- **Rezultat:**
  - `total_income_for_solidarity_levy: <suma>`
  - `income_breakdown: {scale: X, linear: Y, lump_sum: Z, ip_box: A, capital: B, foreign: C}`
  - `solidarity_levy_applies: total_income > 1_000_000`
- **Podstawa prawna:** Art. 30h ust. 2-4 PIT
- **Przykład +:** Skala 600k + kapitały 500k = 1.1M → danina od 100k
- **Przykład −:** Skala 500k + kapitały 400k = 900k → poniżej progu

---

### P1812-P1814 🆕 — POZOSTAŁE REGUŁY DANINY SOLIDARNOŚCIOWEJ

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1812** | `solidarity_levy_zus_exclusion` | Wyłączenie składek ZUS (społecznych) z podstawy daniny. Składki emerytalne i rentowe pomniejszają dochód dla celów daniny. |
| **P1813** | `solidarity_levy_payment_deadline` | Termin zapłaty daniny: do 30 kwietnia następnego roku. Brak zaliczek — płatność jednorazowa roczna. |
| **P1814** | `solidarity_levy_foreign_income_exemption` | Wyłączenie dochodów zagranicznych, które są zwolnione z PIT na podstawie umowy o unikaniu podwójnego opodatkowania (metoda wyłączenia z progresją). |

---

# CZĘŚĆ 3: WIS/WIA/WIT — WIĄŻĄCE INFORMACJE PODATKOWE

> **Dlaczego krytyczne:** WIS (Wiążąca Informacja Stawkowa), WIA (Wiążąca Informacja Akcyzowa) i WIT (Wiążąca Informacja Taryfowa) to instrumenty prawne dające JDG pewność co do klasyfikacji towarów/usług dla celów VAT, akcyzy i ceł. WIS jest kluczowa dla prawidłowego stosowania stawek VAT i kodów GTU w JPK_V7. System ENTERPRISE musi weryfikować czy JDG posiada WIS dla towarów o niejednoznacznej klasyfikacji.

---

### P1820 🆕 `wis_binding_rate_information_check_jdg` 🚨

- **Cel biznesowy:** Identyfikacja towarów/usług, dla których JDG powinien wystąpić o WIS (Wiążącą Informację Stawkową) w celu uniknięcia ryzyka błędnej stawki VAT. Automatyczna analiza niejednoznaczności klasyfikacji CN/PKWiU.
- **Przesłanki:**
  - `input.invoice.cn_code_ambiguous == true` (kod CN/PKWiU niejednoznaczny — wiele możliwych stawek)
  - `input.jdg_entrepreneur.wis_obtained == false`
  - Roczna wartość obrotu towarem > `input.thresholds.jdg.wis.significance_threshold`
- **Rezultat:**
  - `wis_recommended: true`
  - `wis_potential_vat_risk: <kwota potencjalnego uszczuplenia>`
  - `wis_application_deadline: "before_transaction"`
  - `_warning: "Towar X ma niejednoznaczną klasyfikację — rozważ uzyskanie WIS. Ryzyko błędnej stawki VAT i sankcji KKS Art. 64."`
- **Podstawa prawna:** Art. 42a-42h VAT, Rozporządzenie MF ws. WIS
- **Edge cases:**
  - (a) WIS jest wiążąca dla organów podatkowych przez 5 lat
  - (b) WIS wydana dla towaru nie chroni przed zmianą przepisów (ochrona tylko przed zmianą interpretacji)
  - (c) Koszt WIS: 40 PLN za każdy towar
- **Zależności:** Przed P66-P72 (walidacja stawek obniżonych VAT).
- **Thresholds:** `jdg.wis.significance_threshold` (50_000 PLN rocznie — towary o obrocie poniżej są mało istotne)
- **Przykład +:** JDG importuje suplementy diety (CN niejednoznaczne: 23% vs 8%) → `wis_recommended: true`
- **Przykład −:** Standardowy towar z jednoznaczną stawką 23% → `wis_recommended: false`

---

### P1821 🆕 `wis_validity_and_expiry_monitoring_jdg`

- **Cel biznesowy:** Monitorowanie ważności uzyskanych WIS — WIS jest ważna 5 lat od wydania, ale traci moc wstecznie w przypadku zmiany przepisów.
- **Przesłanki:**
  - `input.jdg_entrepreneur.wis_list[*]` — lista posiadanych WIS
  - `input.jdg_entrepreneur.wis_list[*].issue_date` + 5 lat ≤ data bieżąca
- **Rezultat:**
  - `wis_expiring: [{wis_id, expiry_date, days_remaining}]`
  - `wis_expired: [{wis_id, expired_since}]`
  - `_warning: "WIS nr X wygasa za Y dni — złóż wniosek o nową WIS."`
- **Podstawa prawna:** Art. 42h VAT
- **Thresholds:** `jdg.wis.validity_years` (5)
- **Przykład +:** WIS wydana 01.06.2021 → wygasa 01.06.2026 → alert na 3 miesiące przed
- **Przykład −:** WIS wydana 01.01.2024 → ważna do 01.01.2029 → OK

---

### P1822-P1827 🆕 — POZOSTAŁE REGUŁY WIS/WIA/WIT

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1822** | `wis_gtu_code_mapping` | Automatyczne mapowanie WIS na kody GTU w JPK_V7. WIS determinuje kod GTU — system musi zapewniać spójność. |
| **P1823** | `wis_vs_individual_interpretation` | Interakcja WIS z interpretacją indywidualną — WIS ma pierwszeństwo w zakresie klasyfikacji towarowej (CN). |
| **P1824** | `wis_for_import_goods_jdg` | Wymóg WIS przy imporcie towarów z niejednoznaczną klasyfikacją — unikanie błędnej stawki VAT na granicy. |
| **P1825** | `wit_binding_tariff_information_jdg` | WIT (Wiążąca Informacja Taryfowa) — dla ceł przy imporcie spoza UE. Ważna 3 lata. |
| **P1826** | `wia_binding_excise_information_jdg` | WIA (Wiążąca Informacja Akcyzowa) — dla JDG handlujących wyrobami akcyzowymi (alkohol, tytoń, energia). |
| **P1827** | `binding_information_cost_benefit` | Analiza opłacalności uzyskania WIS/WIT/WIA: koszt (40 PLN/WIS) vs. potencjalne ryzyko błędnej stawki VAT. |

---

# CZĘŚĆ 4: KONTROLA PODATKOWA — PROCEDURY SZCZEGÓŁOWE 🚨

> **Dlaczego krytyczne:** Istniejące reguły (P1174, R0449) jedynie powierzchownie dotykają kontroli podatkowej. Brakuje szczegółowych reguł dla różnych typów kontroli (czynności sprawdzające, kontrola podatkowa, postępowanie podatkowe, kontrola celno-skarbowa), praw i obowiązków JDG podczas każdego typu, terminów i protokołów. System ENTERPRISE musi prowadzić JDG przez cały proces kontrolny.

---

### P1830 🆕 `tax_audit_type_determination_jdg` 🚨

- **Cel biznesowy:** Rozróżnienie typów kontroli podatkowej i przypisanie odpowiednich procedur. Każdy typ kontroli ma różne uprawnienia organów, terminy i obowiązki JDG.
- **Typy kontroli i ich charakterystyka:**

| Typ kontroli | Podstawa prawna | Max czas trwania | Uprawnienia organu | Obowiązki JDG |
|:---|:---|:---|:---|:---|
| **Czynności sprawdzające** | Art. 272-280 OP | 7 dni (ciągłych) | Weryfikacja deklaracji, żądanie wyjaśnień, korekta deklaracji z urzędu (art. 274 OP) | Odpowiedź pisemna w terminie 7 dni |
| **Kontrola podatkowa** | Art. 281-292 OP | 30 dni (standard) / 60 dni (przedłużenie) / 90 dni (spółki) | Kontrola ksiąg, dokumentów, przesłuchania świadków, oględziny lokalu | Udostępnienie dokumentów, umożliwienie oględzin, podpisanie protokołu |
| **Postępowanie podatkowe** | Art. 120-129 OP | Bez limitu (do przedawnienia) | Pełne postępowanie dowodowe, decyzja wymiarowa | Aktywny udział w postępowaniu, składanie wyjaśnień, odwołanie w 14 dni od decyzji |
| **Kontrola celno-skarbowa** | Art. 54-93 Ustawy o KAS | 3 miesiące (standard) / 6 miesięcy (przedłużenie) | Rozszerzone uprawnienia KAS (w tym zabezpieczenie majątku, przeszukanie) | Jak przy kontroli podatkowej + szczególne obowiązki |

- **Rezultat:**
  - `audit_type: <"VERIFICATION" | "TAX_AUDIT" | "TAX_PROCEEDING" | "CUSTOMS_FISCAL_AUDIT">`
  - `audit_max_duration_days: <wg tabeli>`
  - `audit_rights: [lista uprawnień organu]`
  - `audit_obligations: [lista obowiązków JDG]`
  - `_warning: "Kontrola typu X rozpoczęta — max. Y dni. Twoje obowiązki: Z."`
- **Podstawa prawna:** Art. 272-292 Ordynacji podatkowej, Art. 54-93 Ustawy o KAS
- **Zależności:** Rozszerza P1174 i R0449.
- **Thresholds:** `jdg.audit.max_days_verification` (7), `jdg.audit.max_days_tax_audit` (30), `jdg.audit.max_days_customs` (90)
- **Przykład +:** US wszczyna czynności sprawdzające → `audit_type: "VERIFICATION"`, max 7 dni
- **Przykład −:** KAS wszczyna kontrolę celno-skarbową → `audit_type: "CUSTOMS_FISCAL_AUDIT"`, max 90 dni

---

### P1831 🆕 `tax_audit_rights_and_obligations_jdg` 🚨

- **Cel biznesowy:** Szczegółowa lista praw i obowiązków JDG podczas kontroli podatkowej. Znajomość praw jest kluczowa dla zabezpieczenia pozycji prawnej JDG.
- **Prawa JDG podczas kontroli:**
  - Prawo do zawiadomienia o kontroli (min. 7 dni przed rozpoczęciem — Art. 282b OP, z wyjątkami)
  - Prawo do obecności podczas czynności kontrolnych
  - Prawo do wyłączenia kontrolera (złożenie wniosku o wyłączenie — Art. 130 OP)
  - Prawo do zgłaszania zastrzeżeń do protokołu (14 dni od podpisania — Art. 291 OP)
  - Prawo do odmowy odpowiedzi na pytania (gdy odpowiedź mogłaby narazić na odpowiedzialność KKS — Art. 199 OP)
  - Prawo do nagrywania czynności kontrolnych (za zgodą kontrolującego — Art. 286 § 3 OP)
  - Prawo do przerwy w kontroli (max 3 dni robocze na wniosek — Art. 84b ust. 3 Ustawy o KAS)
  - Prawo do sprzeciwu wobec kontroli (gdy narusza przepisy — Art. 84c Prawa przedsiębiorców)
- **Obowiązki JDG podczas kontroli:**
  - Udostępnienie dokumentacji (księgi, faktury, umowy, wyciągi bankowe)
  - Umożliwienie oględzin lokalu
  - Składanie wyjaśnień ustnych i pisemnych
  - Podpisanie protokołu kontroli (odmowa podpisu wymaga uzasadnienia)
  - Przechowywanie dokumentacji kontrolnej
- **Rezultat:**
  - `rights_checklist: [{right: str, exercised: bool, notes: str}]`
  - `obligations_checklist: [{obligation: str, fulfilled: bool, notes: str}]`
  - `rights_violated: [lista naruszonych praw]`
  - `_warning: "Twoje prawa podczas kontroli: X. Naruszone prawa: Y. Rozważ sprzeciw / skargę."`
- **Podstawa prawna:** Art. 281-292 Ordynacji podatkowej, Art. 84 Prawa przedsiębiorców
- **Zależności:** Po P1830.
- **Przykład +:** Kontrola bez 7-dniowego zawiadomienia → `rights_violated: ["NO_7_DAY_NOTICE"]`, można złożyć sprzeciw
- **Przykład −:** Kontrola z 7-dniowym zawiadomieniem → prawa dochowane

---

### P1832 🆕 `tax_audit_protocol_objections_jdg` 🚨

- **Cel biznesowy:** Procedura zgłaszania zastrzeżeń do protokołu kontroli. JDG ma 14 dni na zgłoszenie zastrzeżeń — brak zastrzeżeń = akceptacja ustaleń.
- **Przesłanki:**
  - `input.audit.protocol_signed_date` znana
  - `input.audit.objections_filed == false`
  - `days_since_protocol < 14`
- **Rezultat:**
  - `objections_deadline: protocol_signed_date + 14_days`
  - `objections_still_possible: days_since_protocol < 14`
  - `objections_deadline_passed: days_since_protocol >= 14`
  - `_warning: "Masz 14 dni na zgłoszenie zastrzeżeń do protokołu. Pozostało: X dni. Po terminie: akceptacja ustaleń."`
- **Podstawa prawna:** Art. 291 § 1-2 Ordynacji podatkowej
- **Thresholds:** `jdg.audit.objections_deadline_days` (14)
- **Przykład +:** Protokół podpisany 01.06 → zastrzeżenia do 15.06
- **Przykład −:** Protokół podpisany 01.06, dziś 20.06 → `objections_deadline_passed: true`

---

### P1833 🆕 `tax_audit_statute_suspension_effect` 🚨

- **Cel biznesowy:** Automatyczne zawieszenie biegu przedawnienia zobowiązania podatkowego na czas kontroli. Wszczęcie kontroli = zawieszenie przedawnienia do czasu jej zakończenia.
- **Przesłanki:**
  - `input.audit.status == "IN_PROGRESS"`
  - `input.audit.tax_liability_statute_date` (pierwotna data przedawnienia)
- **Rezultat:**
  - `statute_suspended: true`
  - `statute_original_date: <data pierwotna>`
  - `statute_new_estimated_date: <data pierwotna + czas trwania kontroli>`
  - `_warning: "Kontrola podatkowa zawiesza bieg przedawnienia. Nowy szacowany termin: X."`
- **Podstawa prawna:** Art. 70 § 6 pkt 1 Ordynacji podatkowej
- **Zależności:** Wpływa na P1153 `statute_suspension` i R0436-R0449.
- **Przykład +:** Przedawnienie VAT za 2020: 31.12.2025, kontrola od 01.06.2025 do 30.09.2025 → zawieszenie na 4 mies. → nowy termin 30.04.2026

---

### P1834-P1844 🆕 — POZOSTAŁE REGUŁY KONTROLI

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1834** | `tax_audit_evidence_collection_rights` | Prawa organu do zbierania dowodów: żądanie dokumentów od kontrahentów (Art. 287 OP), przesłuchania świadków (Art. 190-200 OP), opinie biegłych (Art. 193 OP), oględziny (Art. 198 OP). |
| **P1835** | `tax_audit_seizure_of_documents` | Zatrzymanie dokumentów przez organ — tylko za pokwitowaniem, max na czas kontroli. Brak zgody JDG = protokół + możliwość odwołania. Art. 288 OP. |
| **P1836** | `tax_audit_correction_during_audit` | Możliwość korekty deklaracji podczas kontroli (Art. 81b OP) — korekta na niekorzyść US jest możliwa, na korzyść jest blokowana (chyba że US wyrazi zgodę). |
| **P1837** | `tax_audit_decision_appeal_jdg` | Procedura odwoławcza od decyzji pokontrolnej: odwołanie w 14 dni do organu II instancji (Dyrektor IAS), skarga do WSA w 30 dni od decyzji II instancji (Art. 220-247 OP, Art. 52-54 PPSA). |
| **P1838** | `tax_audit_right_to_be_heard` | Prawo do wypowiedzenia się przed wydaniem decyzji (Art. 200 OP) — organ musi umożliwić JDG zapoznanie się z aktami i wypowiedzenie przed wydaniem decyzji. |
| **P1839** | `tax_audit_legal_professional_privilege` | Tajemnica zawodowa adwokata/radcy/doradcy — dokumenty objęte tajemnicą nie mogą być przedmiotem kontroli (Art. 180 § 3 OP). Dotyczy tylko JDG w zawodach regulowanych. |
| **P1840** | `tax_audit_representation_rights` | Prawa pełnomocnika podczas kontroli: wgląd w akta (Art. 178 OP), udział w czynnościach (Art. 138e OP), podpisywanie protokołów (Art. 291 OP). Pełnomocnictwo PPS-1/UPL-1. |
| **P1841** | `tax_audit_penalty_for_obstruction` | Sankcje za utrudnianie kontroli: grzywna do 5 000 PLN (Art. 262 OP), odpowiedzialność KKS (Art. 69 — do 720 stawek dziennych), możliwość przymuszenia (Art. 151 OP). |
| **P1842** | `tax_audit_electronic_evidence` | Dowody elektroniczne podczas kontroli: wydruki komputerowe, e-maile, faktury elektroniczne, JPK. Wymagania autentyczności i integralności. Art. 193a-193d OP. |
| **P1843** | `tax_audit_foreign_language_documents` | Dokumenty w języku obcym — organ może żądać tłumaczenia przysięgłego (Art. 180a OP). Koszt tłumaczenia ponosi JDG. |
| **P1844** | `tax_audit_closure_and_follow_up` | Zakończenie kontroli: protokół → zastrzeżenia → decyzja → odwołanie → wykonanie. Monitoring post-kontrolny: realizacja zaleceń, korekty, wpłaty. |

---

# CZĘŚĆ 5: SIŁA WYŻSZA I CIĄGŁOŚĆ DZIAŁANIA

> **Dlaczego krytyczne:** Doświadczenia pandemii COVID-19, powodzi 2024 i skutków wojny w Ukrainie pokazały, że JDG potrzebują mechanizmów ochronnych na wypadek siły wyższej. System ENTERPRISE musi automatycznie identyfikować uprawnienia do ulg, odroczeń i zwolnień w sytuacjach kryzysowych.

---

### P1850 🆕 `force_majeure_tax_relief_eligibility_jdg`

- **Cel biznesowy:** Wykrycie uprawnień JDG do ulg podatkowych w przypadku siły wyższej (klęska żywiołowa, pandemia, stan nadzwyczajny). Automatyczne flagowanie dostępnych mechanizmów.
- **Mechanizmy ulg w przypadku siły wyższej:**
  - Odroczenie terminu płatności podatku (Art. 67a § 1 pkt 1 OP)
  - Rozłożenie na raty (Art. 67a § 1 pkt 2 OP)
  - Umorzenie zaległości (Art. 67a § 1 pkt 3 OP) — tylko z ważnego interesu
  - Zaniechanie poboru podatku (rozporządzenie MF — np. COVID-19)
  - Przedłużenie terminów składania deklaracji (rozporządzenie MF)
- **Przesłanki:**
  - `input.jdg_entrepreneur.force_majeure_event == true`
  - `input.jdg_entrepreneur.force_majeure_type` ∈ `["FLOOD", "FIRE", "PANDEMIC", "WAR_EFFECTS", "OTHER_NATURAL_DISASTER"]`
  - `input.jdg_entrepreneur.business_affected == true` (bezpośredni wpływ na działalność)
- **Rezultat:**
  - `relief_eligible: true`
  - `available_reliefs: [lista dostępnych mechanizmów]`
  - `application_deadline: "ASAP"` (wnioski rozpatrywane priorytetowo)
  - `_warning: "Siła wyższa (X) — przysługują Ci ulgi podatkowe: Y. Złóż wniosek do US niezwłocznie."`
- **Podstawa prawna:** Art. 67a-67e Ordynacji podatkowej, Rozporządzenia MF ws. zaniechania poboru (specyficzne dla zdarzenia)
- **Zależności:** Przed P1177 (odsetki) i P1179 (przedawnienia).
- **Przykład +:** Powódź zniszczyła biuro JDG → `relief_eligible: true`, odroczenie + raty
- **Przykład −:** Standardowa sytuacja, bez siły wyższej → `relief_eligible: false`

---

### P1851 🆕 `force_majeure_zus_relief_jdg`

- **Cel biznesowy:** Ulgi w składkach ZUS w przypadku siły wyższej — odroczenie, układ ratalny, a w szczególnych przypadkach umorzenie składek.
- **Przesłanki:**
  - `input.jdg_entrepreneur.force_majeure_event == true`
  - `input.jdg_entrepreneur.zus_contributions_affected == true`
- **Rezultat:**
  - `zus_relief_eligible: true`
  - `zus_contribution_suspension_period: <okres ulgi>`
  - `_warning: "Siła wyższa — możesz ubiegać się o odroczenie/umorzenie składek ZUS. Złóż wniosek do ZUS."`
- **Podstawa prawna:** Art. 28 Ustawy o SUS, Art. 29 Ustawy o SUS
- **Przykład +:** Powódź — ZUS umarza składki za 3 miesiące → `zus_relief_eligible: true`

---

### P1852-P1857 🆕 — POZOSTAŁE REGUŁY SIŁY WYŻSZEJ

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1852** | `force_majeure_documentation_loss` | Utrata dokumentacji księgowej w wyniku siły wyższej — procedura odtworzenia (Art. 86 § 2 OP). Obowiązek zgłoszenia do US w ciągu 7 dni. |
| **P1853** | `force_majeure_insurance_cover` | Sprawdzenie czy JDG posiada ubezpieczenie od zdarzeń siły wyższej (business interruption). Wpływ na KUP (składka ubezpieczeniowa jest KUP, odszkodowanie jest przychodem). |
| **P1854** | `force_majeure_business_suspension_auto` | Automatyczne zawieszenie działalności z powodu siły wyższej — skutki podatkowe i ZUS-owe (Art. 25 PP). |
| **P1855** | `force_majeure_tax_loss_carry_back` | Możliwość rozliczenia straty powstałej w wyniku siły wyższej w latach wstecz (specjalne regulacje — np. COVID-19 umożliwiał odliczenie straty 2020 od dochodu 2019). |
| **P1856** | `force_majeure_emergency_deadlines` | Specjalne przedłużenia terminów ogłaszane przez MF w związku z siłą wyższą — automatyczne śledzenie komunikatów MF. |
| **P1857** | `force_majeure_documentation_preservation` | Obowiązek zabezpieczenia dokumentacji przed skutkami siły wyższej (backupy cyfrowe, kopie off-site). |

---

# CZĘŚĆ 6: CZŁONKOWIE RODZINY W JDG

> **Dlaczego krytyczne:** Zatrudnianie małżonka/dzieci w JDG to powszechna praktyka optymalizacyjna, ale obarczona wysokim ryzykiem zakwestionowania przez US. System ENTERPRISE musi weryfikować czy wynagrodzenie rodziny spełnia kryteria rynkowe i nie jest ukrytą dywidendą.

---

### P1860 🆕 `family_employment_spouse_kup_jdg` 🚨

- **Cel biznesowy:** Weryfikacja czy wynagrodzenie małżonka w JDG spełnia kryteria rynkowe i może być zaliczone do KUP. US często kwestionuje wynagrodzenia małżonków jako nieuzasadnione ekonomicznie.
- **Przesłanki:**
  - `input.jdg_entrepreneur.employs_spouse == true` (małżonek zatrudniony w JDG)
  - `input.invoice.spouse_salary_market_comparable` (porównanie z rynkową stawką dla podobnego stanowiska)
  - `input.invoice.spouse_work_documented == true` (rzeczywiste wykonywanie pracy — ewidencja czasu, zadania, efekty)
  - `input.invoice.spouse_has_qualifications == true` (kwalifikacje adekwatne do stanowiska)
- **Rezultat:**
  - `spouse_salary_kup_valid: true` (jeśli wszystkie warunki spełnione)
  - `spouse_salary_kup_risk: "LOW" | "MEDIUM" | "HIGH"` (ryzyko zakwestionowania przez US)
  - `_warning: "Wynagrodzenie małżonka — upewnij się, że kwota jest rynkowa, praca udokumentowana, a kwalifikacje adekwatne. Ryzyko zakwestionowania przez US: X."`
- **Podstawa prawna:** Art. 22 ust. 1 PIT, Art. 23 ust. 1 pkt 10 PIT (wyłączenie z KUP — wartość własnej pracy podatnika, jego małżonka i małoletnich dzieci)
- **Edge cases:**
  - (a) Małżonek pracuje w JDG i ma udokumentowane kompetencje (np. księgowa z certyfikatem) → KUP akceptowalne
  - (b) Małżonek \"pracuje\" za 20 000 PLN/mies. bez ewidencji i kwalifikacji → `spouse_salary_kup_risk: "HIGH"`
  - (c) Umowa o pracę z małżonkiem vs. umowa B2B — różne konsekwencje ZUS i PIT
- **Zależności:** Po P560 `kup_full_deductible` i przed P578 `kup_own_work_nkup`.
- **Thresholds:** `jdg.family.market_salary_deviation_threshold` (0.30 — 30% odchylenia od stawki rynkowej)
- **Przykład +:** Małżonek zatrudniony jako księgowa z certyfikatem, pensja 8000 PLN (rynek: 7000-9000 PLN) → `spouse_salary_kup_risk: "LOW"`
- **Przykład −:** Małżonek \"dyrektor marketingu\" bez doświadczenia, pensja 25 000 PLN → `spouse_salary_kup_risk: "HIGH"`

---

### P1861 🆕 `family_employment_children_kup_jdg` 🚨

- **Cel biznesowy:** Zatrudnienie dzieci przez JDG — ograniczenia KUP. Wynagrodzenie dzieci do 26. roku życia może być traktowane jako wartość własnej pracy podatnika (NKUP), chyba że spełnione są rygorystyczne warunki rynkowe.
- **Przesłanki:**
  - `input.jdg_entrepreneur.employs_children == true` (dziecko zatrudnione w JDG)
  - `input.invoice.child_age` ≤ 26 (podwyższone ryzyko kontroli)
  - `input.invoice.child_work_documented == true`
  - `input.invoice.child_salary_arm_length` (wynagrodzenie rynkowe)
- **Rezultat:**
  - `child_salary_kup_valid: true/false`
  - `child_salary_pit_scale: "PIT_SCALE"` (dziecko rozlicza się samodzielnie)
  - `_warning: "Wynagrodzenie dziecka w JDG — podwyższone ryzyko kontroli US. Upewnij się, że praca jest rzeczywista i udokumentowana."`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 10 PIT
- **Przykład +:** Syn student 22 lata, pracuje w weekendy w sklepie JDG → pensja 2000 PLN → rynek → KUP OK
- **Przykład −:** Syn 16 lat, \"konsultant IT\", pensja 10 000 PLN → HIGH risk

---

### P1862-P1869 🆕 — POZOSTAŁE REGUŁY RODZINNE

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1862** | `family_member_health_insurance_deduction` | Ubezpieczenie zdrowotne członków rodziny jako KUP — tylko jeśli są zgłoszeni do ubezpieczenia w ZUS jako osoby współpracujące. Art. 27b PIT (uchylony) — obecnie brak odliczenia od PIT. |
| **P1863** | `family_member_car_usage_kup` | Samochód firmowy używany przez członków rodziny — ograniczenie KUP do 75% (dla samochodów używanych mieszanie). Art. 23 ust. 1 pkt 46a PIT. |
| **P1864** | `family_member_cooperation_zus` | Osoba współpracująca (małżonek, dzieci) — obowiązek opłacania składek ZUS tak jak za przedsiębiorcę. Art. 8 ust. 2 SUS. |
| **P1865** | `family_member_succession_planning` | Planowanie sukcesyjne z udziałem rodziny — przekazanie firmy dzieciom/małżonkowi przed śmiercią. Podatek od darowizny (grupa 0 dla najbliższej rodziny przy zgłoszeniu SD-Z2 w ciągu 6 miesięcy). |
| **P1866** | `family_member_pit_joint_filing` | Wspólne rozliczenie PIT małżonków z JDG — warunek: małżonkowie pozostawali w związku przez cały rok, wspólność majątkowa, złożenie PIT-36 ze wskazaniem wspólnego rozliczenia do 30 kwietnia. |
| **P1867** | `family_member_pit_relief_interaction` | Interakcja ulg podatkowych przy wspólnym rozliczeniu (dzieci, rehabilitacja, internet) — limit dochodów dla ulgi na dziecko liczony łącznie. |
| **P1868** | `family_employer_pit_4r_obligation` | Obowiązek płatnika PIT przy zatrudnieniu członków rodziny — PIT-4R, PIT-11. Terminy: zaliczka do 20. dnia miesiąca, PIT-11 do 31 stycznia. |
| **P1869** | `family_asset_transfer_tax_consequences` | Przekazanie składników majątku JDG członkowi rodziny — skutki w PIT (odpłatne = przychód z działalności, nieodpłatne = darowizna), VAT (opodatkowane jeśli JDG był czynnym VAT), PCC (zwolnione w grupie 0). |

---

# CZĘŚĆ 7: E-KOMUNIKACJA Z ORGANAMI PODATKOWYMI 🚨

> **Dlaczego krytyczne:** Od 2024-2026 komunikacja z US odbywa się elektronicznie (e-US, e-Doręczenia, e-PUAP). Błędne doręczenie, przeoczenie pisma lub brak odbioru w terminie skutkuje fikcją doręczenia i nieodwracalnymi konsekwencjami prawnymi. System ENTERPRISE musi zarządzać kanałami komunikacji elektronicznej.
>
> ⚠️ **UWAGA — ZALEŻNOŚĆ OD ISTNIEJĄCYCH REGUŁ:** P1780 `digital_e_delivery_mandate_jdg` (Doc 40) sprawdza obowiązek rejestracji w Bazie Adresów Elektronicznych (BAE). Poniższa reguła P1870 ROZSZERZA ją — koncentruje się na skutkach fikcji doręczenia (14-dniowy termin) i monitorowaniu nieodebranych pism. Obie reguły są komplementarne: P1780 = warunek wstępny (czy masz adres?), P1870 = skutek (co jeśli nie odbierasz?).

---

### P1870 🆕 `e_delivery_obligation_and_fiction_jdg` 🚨 🔗 (rozszerza P1780 z Doc 40)

- **Cel biznesowy:** Pełna obsługa obowiązku e-Doręczeń z uwzględnieniem fikcji doręczenia. Po 14 dniach od wpłynięcia pisma na adres e-Doręczeń, pismo uznaje się za doręczone — nawet jeśli JDG go nie odebrał! REGUŁA ROZSZERZA P1780 (Doc 40) o skutki nieodbierania korespondencji.
- **Przesłanki:**
  - `input.jdg_entrepreneur.e_delivery_address_active == true`
  - `input.communication.unread_letters[*]` — lista nieodebranych pism z e-US
  - `days_since_delivery > 14`
- **Rezultat:**
  - `fiction_of_delivery: true`
  - `undelivered_consequences: [lista pism uznanych za doręczone]`
  - `legal_deadlines_triggered: [lista terminów (odwołanie 14 dni, zapłata 7 dni itd.)]`
  - `_routing: "CRITICAL_ALERT"`
  - `_warning: "⚠️ PISMO Z US UZNANE ZA DORĘCZONE PRZEZ FIKCJĘ! Od dnia X masz Y dni na odwołanie/zapłatę. NATYCHMIAST sprawdź e-US!"`
- **Podstawa prawna:** Ustawa o doręczeniach elektronicznych (Dz.U. 2020 poz. 2320), Art. 144a Ordynacji podatkowej
- **Thresholds:** `jdg.digital.fiction_of_delivery_days` (14)
- **Przykład +:** Pismo z US wpłynęło 01.06, nieodebrane, dziś 20.06 → fikcja doręczenia od 15.06 → terminy biegną
- **Przykład −:** Pismo odebrane w dniu wpłynięcia → fikcja nie ma zastosowania

---

### P1871 🆕 `e_us_platform_interaction_jdg`

- **Cel biznesowy:** Automatyczne monitorowanie konta e-US — śledzenie korespondencji, terminów, deklaracji i płatności.
- **Monitorowane zdarzenia na e-US:**
  - Nowe pisma od US (termin odbioru: 14 dni)
  - Przypomnienia o niezłożonych deklaracjach
  - Potwierdzenia złożonych deklaracji (UPO)
  - Wezwania do zapłaty
  - Decyzje wymiarowe
  - Interpretacje indywidualne
- **Rezultat:**
  - `eus_unread_items: [lista nieprzeczytanych pism]`
  - `eus_upcoming_deadlines: [lista nadchodzących terminów]`
  - `eus_pending_actions: [lista wymaganych działań]`
  - `_warning: "e-US: X nowych pism, Y nadchodzących terminów, Z wymaganych działań."`
- **Podstawa prawna:** Art. 144b Ordynacji podatkowej
- **Przykład +:** 3 nowe pisma na e-US, 1 termin odwołania w ciągu 5 dni → alert

---

### P1872-P1877 🆕 — POZOSTAŁE REGUŁY E-KOMUNIKACJI

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1872** | `epuap_profile_mandatory_jdg` | Obowiązek posiadania profilu zaufanego ePUAP dla JDG — składanie pism do US, ZUS, CEIDG. Art. 20a OP. |
| **P1873** | `electronic_signature_qualified_requirements` | Kiedy wymagany jest kwalifikowany podpis elektroniczny (a nie tylko profil zaufany) — pisma procesowe, pełnomocnictwa, odwołania. Art. 126 § 5 OP. |
| **P1874** | `electronic_document_retention_jdg` | Przechowywanie dokumentów elektronicznych — wymagania integralności, autentyczności i czytelności przez 5 lat. Art. 86 OP, Rozporządzenie eIDAS. |
| **P1875** | `digital_communication_evidence_value` | Moc dowodowa dokumentów elektronicznych w postępowaniu podatkowym — wymagania dla e-faktur, e-umów, e-dowódów zapłaty. Art. 180a-194 OP. |
| **P1876** | `cross_border_e_communication_jdg` | Komunikacja elektroniczna z zagranicznymi organami podatkowymi — wymiana informacji na żądanie (DAC), automatyczna (CRS), spontaniczna. |
| **P1877** | `communication_archive_retention_policy` | Polityka retencji korespondencji elektronicznej z US: 5 lat od zakończenia postępowania podatkowego. |

---

# CZĘŚĆ 8: ZAMÓWIENIA PUBLICZNE I CERTYFIKATY PODATKOWE

> **Dlaczego krytyczne:** JDG ubiegające się o zamówienia publiczne muszą wykazać brak zaległości podatkowych i ZUS. System ENTERPRISE musi automatycznie weryfikować zdolność JDG do udziału w przetargach.

---

### P1880 🆕 `public_procurement_tax_clearance_jdg`

- **Cel biznesowy:** Automatyczna weryfikacja czy JDG może uzyskać zaświadczenie o niezaleganiu w podatkach (wymagane do zamówień publicznych > 30 000 EUR).
- **Przesłanki:**
  - `input.jdg_entrepreneur.has_tax_arrears == false`
  - `input.jdg_entrepreneur.has_zus_arrears == false`
  - Wszystkie deklaracje złożone w terminie
  - Brak postępowania egzekucyjnego
- **Rezultat:**
  - `tax_clearance_valid: true`
  - `tax_clearance_certificate_available: true` (do pobrania z e-US)
  - `_warning: "Zaświadczenie o niezaleganiu — możesz ubiegać się o zamówienia publiczne."`
- **Podstawa prawna:** Art. 306e Ordynacji podatkowej, Art. 22-24 PZP
- **Przykład +:** JDG bez zaległości → zaświadczenie dostępne
- **Przykład −:** JDG z zaległością 5000 PLN → zaświadczenie niedostępne → blokada zamówień publicznych

---

### P1881-P1886 🆕 — POZOSTAŁE REGUŁY ZAMÓWIEŃ PUBLICZNYCH

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1881** | `public_procurement_european_funds_certificate` | Zaświadczenie o niezaleganiu dla środków unijnych — dodatkowe wymogi dla beneficjentów funduszy UE. |
| **P1882** | `tax_clearance_issuance_procedure` | Procedura uzyskania zaświadczenia: wniosek przez e-US, termin wydania: 7 dni (standard), 3 dni (tryb pilny za dodatkową opłatą). Art. 306n OP. |
| **P1883** | `tax_arrears_impact_on_public_contracts` | Wpływ zaległości podatkowych na zdolność do udziału w zamówieniach publicznych — wykluczenie obligatoryjne (art. 108 ust. 1 pkt 4 PZP). |
| **P1884** | `zus_clearance_for_public_procurement` | Zaświadczenie z ZUS o niezaleganiu — wymagane obok zaświadczenia podatkowego. |
| **P1885** | `public_procurement_tax_representation` | Obowiązek wskazania przedstawiciela podatkowego dla JDG zagranicznych ubiegających się o zamówienia w PL. |
| **P1886** | `bid_bond_tax_treatment_jdg` | Wadium w przetargach — KUP, moment zaliczenia, VAT. |

---

# CZĘŚĆ 9: ROZLICZENIA W WALUTACH OBCYCH

> **Dlaczego krytyczne:** Istniejące reguły (P870 `fx_differences_recognition`) tylko pobieżnie dotykają tematu. Brakuje szczegółowych reguł dla różnych typów transakcji walutowych i metod przeliczania. Import usług (VAT) jest częściowo pokryty przez crossborder P144 `platform_import_of_services` oraz reguły Doc 23 — niniejsza sekcja uzupełnia je o szczegółowe zasady kursowe i różnice między VAT a PIT.

---

### P1890 🆕 `fx_rate_determination_for_vat_jdg`

- **Cel biznesowy:** Prawidłowe określenie kursu waluty dla celów VAT — różne reguły dla różnych typów transakcji.
- **Zasady kursowe dla VAT:**
  - Import towarów: kurs celny (Art. 30a VAT)
  - WNT: kurs NBP z ostatniego dnia roboczego poprzedzającego WNT (Art. 30a VAT)
  - Import usług: kurs NBP z ostatniego dnia roboczego poprzedzającego powstanie obowiązku podatkowego (Art. 31a VAT)
  - Faktury w walucie obcej: kurs NBP z ostatniego dnia roboczego poprzedzającego powstanie obowiązku podatkowego LUB kurs EBC (jeśli faktura w EUR)
  - Korekty: kurs z dnia korekty
- **Rezultat:**
  - `applicable_fx_rate: <kurs>`
  - `fx_rate_source: "NBP" | "ECB" | "CUSTOMS"`
  - `fx_rate_date: <data kursu>`
  - `_warning: "Kurs waluty dla celów VAT: X PLN/EUR z dnia Y (źródło: Z)."`
- **Podstawa prawna:** Art. 30a-31a VAT
- **Przykład +:** Faktura sprzedaży w EUR z 15.06, obowiązek podatkowy 15.06 → kurs NBP z 14.06

---

### P1891 🆕 `fx_rate_determination_for_pit_jdg`

- **Cel biznesowy:** Prawidłowe określenie kursu waluty dla celów PIT — istotnie różne od VAT!
- **Zasady kursowe dla PIT:**
  - Przychody: kurs NBP z ostatniego dnia roboczego poprzedzającego uzyskanie przychodu (Art. 14 ust. 1aa PIT)
  - KUP w walucie obcej: kurs NBP z dnia poprzedzającego poniesienie kosztu (Art. 22 ust. 1e PIT)
  - Różnice kursowe: metoda FIFO/LIFO/AW, kurs NBP z dnia zarachowania/zapłaty (Art. 14b PIT)
- **Rezultat:**
  - `applicable_pit_fx_rate: <kurs>`
  - `pit_fx_rate_date: <data kursu>`
  - `_warning: "Kurs waluty dla PIT różni się od VAT! PIT: kurs NBP z dnia X, VAT: kurs z dnia Y."`
- **Podstawa prawna:** Art. 14 ust. 1aa, Art. 22 ust. 1e, Art. 14b PIT
- **Przykład +:** Faktura w USD z 10.06, kurs NBP z 09.06 → PIT: kurs z 09.06, VAT: kurs z 09.06 (często to samo)

---

### P1892-P1898 🆕 — POZOSTAŁE REGUŁY FX

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1892** | `fx_differences_realized_vs_unrealized` | Rozróżnienie zrealizowanych i niezrealizowanych różnic kursowych — tylko zrealizowane wpływają na PIT (Art. 14b PIT). |
| **P1893** | `fx_differences_method_selection` | Wybór metody rozliczania różnic kursowych: metoda podatkowa (FIFO) vs. metoda rachunkowa (średnia ważona). Oświadczenie raz na rok. |
| **P1894** | `fx_differences_own_funds_jdg` | Różnice kursowe od własnych środków pieniężnych JDG — brak różnic kursowych na rachunku walutowym w PIT (inaczej niż w CIT). |
| **P1895** | `fx_differences_crypto_jdg` | Różnice kursowe na transakcjach kryptowalutowych — specyficzne zasady (przeliczenie PLN na krypto po kursie rynkowym, nie NBP). |
| **P1896** | `fx_rate_hedging_instruments_jdg` | Opodatkowanie instrumentów zabezpieczających ryzyko walutowe (forward, opcje walutowe) — przychody/koszty z pochodnych. |
| **P1897** | `fx_multi_currency_accounting_jdg` | Prowadzenie PKPiR w walucie obcej — przeliczenie na PLN na koniec każdego miesiąca (Art. 24a PIT). |
| **P1898** | `fx_nbp_table_selection_alert` | Alert przy wyborze niewłaściwej tabeli NBP (A vs. B vs. C) — tabela A (średnie kursy) dla PIT, tabela B (ostatnie kursy) dla niektórych transakcji. |

---

# CZĘŚĆ 10-20: POZOSTAŁE OBSZARY KRYTYCZNE

## 10. PODPISY ELEKTRONICZNE — P1900-P1906

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1900** | `qualified_signature_requirement_check` | Weryfikacja kiedy wymagany jest kwalifikowany podpis elektroniczny (deklaracje podatkowe składane przez pełnomocnika, odwołania od decyzji, pełnomocnictwa). |
| **P1901** | `electronic_signature_validity_monitoring` | Monitorowanie ważności certyfikatu kwalifikowanego podpisu — wygasa po 2 latach. Alert przed wygaśnięciem. |
| **P1902** | `electronic_invoice_signature_ksef` | Wymogi podpisu elektronicznego dla faktur KSeF — token KSeF, pieczęć elektroniczna (qualified e-seal), lub kwalifikowany podpis elektroniczny. |
| **P1903** | `electronic_document_authenticity_preservation` | Zachowanie autentyczności dokumentów elektronicznych — zakaz konwersji na formaty niespełniające wymogów (np. zeskanowana faktura z KSeF traci status faktury ustrukturyzowanej). |
| **P1904** | `cross_border_eidas_recognition` | Uznawanie zagranicznych podpisów elektronicznych w Polsce (eIDAS) — podpisy kwalifikowane z innych krajów UE są równoważne. |
| **P1905** | `electronic_contracts_validity_jdg` | Elektroniczne zawieranie umów — wymogi formy elektronicznej (Art. 78(1) KC) i formy dokumentowej (Art. 77(2)-77(3) KC) dla celów podatkowych. |
| **P1906** | `electronic_invoice_storage_standards` | Standardy przechowywania faktur elektronicznych — autentyczność pochodzenia, integralność treści, czytelność. EN 16931 dla e-faktur. |

## 11. KALENDARZ PŁATNOŚCI — P1910-P1915

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1910** | `master_payment_calendar_jdg` | Główny kalendarz wszystkich terminów płatności podatków i składek dla JDG — VAT, PIT zaliczki, ZUS, PCC, danina solidarnościowa. |
| **P1911** | `payment_calendar_by_tax_form` | Kalendarz dynamiczny zależny od formy opodatkowania — różne terminy dla skali (miesięczne), liniowego (miesięczne), ryczałtu (miesięczne/kwartalne). |
| **P1912** | `payment_deadline_weekend_shift_jdg` | Automatyczne przesuwanie terminów przypadających w weekendy i święta na następny dzień roboczy — zgodnie z Art. 12 § 5 OP. |
| **P1913** | `payment_calendar_overdue_alerts` | Alerty dla nadchodzących terminów: 7 dni, 3 dni, 1 dzień przed terminem. Eskalacja po terminie: odsetki. |
| **P1914** | `payment_calendar_annual_forecast` | Prognoza rocznych płatności podatkowych i ZUS na podstawie danych historycznych — narzędzie planowania finansowego. |
| **P1915** | `payment_calendar_zus_deadlines` | Kalendarz terminów ZUS: 10. dzień miesiąca (JDG bez pracowników), 15. dzień (JDG z pracownikami do 5 osób), 20. dzień (JDG z 5+ pracownikami). |

## 12. KWOTA WOLNA 30K — P1920-P1925

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1920** | `tax_free_amount_multi_source_jdg` | Interakcja kwoty wolnej 30 000 PLN z wieloma źródłami dochodu — JDG + etat + najem + kapitały. Kwota wolna stosowana przez płatnika (etat) i/lub w zeznaniu rocznym. |
| **P1921** | `tax_free_amount_jdg_vs_employment` | Gdy JDG jest na skali i ma etat — kwota wolna rozliczana łącznie. Pracodawca stosuje 1/12 kwoty do zaliczek (250 PLN/mies.), JDG nie stosuje kwoty w zaliczkach. |
| **P1922** | `tax_free_amount_linear_lump_sum_exclusion` | Kwota wolna NIE dotyczy podatku liniowego i ryczałtu — tylko skala podatkowa. System musi to wyraźnie komunikować. |
| **P1923** | `tax_free_amount_deduction_optimization` | Optymalizacja wykorzystania kwoty wolnej — czy lepiej rozliczać się indywidualnie czy z małżonkiem (wspólne rozliczenie daje 60k kwoty wolnej). |
| **P1924** | `tax_free_amount_withholding_tax` | Interakcja kwoty wolnej z podatkiem u źródła — WHT nie korzysta z kwoty wolnej (ryczałt 19%/20%). |
| **P1925** | `tax_free_amount_foreign_income` | Dochody zagraniczne opodatkowane metodą progresji (zwolnione z progresją) — kwota wolna stosowana tylko do dochodów polskich. |

## 13. CENY TRANSFEROWE (TPR) — P1930-P1938 🚨

> ⚠️ **UWAGA — ISTNIEJĄCE REGUŁY:** Mapa kanoniczna zawiera już P29 `tp_safe_harbour_low_value_services` oraz P114 `tp_documentation_threshold`. Poniższe reguły P1930-P1938 **znacząco rozszerzają** TP do poziomu ENTERPRISE, dodając: wykrycie podmiotów powiązanych, Local File, Master File, TPR-C, benchmarking, sankcje. P29 i P114 pozostają jako reguły bazowe.

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1930** | `tp_related_party_detection_jdg` 🔗 (rozszerza P29/P114) | Wykrycie transakcji z podmiotami powiązanymi — progi: 25% udziałów/głosów, powiązania rodzinne, powiązania zarządcze. Art. 23m-23zf PIT. |
| **P1931** | `tp_documentation_thresholds_jdg` 🔗 (uszczegóławia P114) | Progi dokumentacyjne dla JDG: 2M PLN (transakcje towarowe), 1M PLN (transakcje finansowe), 0.5M PLN (transakcje usługowe, niematerialne). Wartości EUR przeliczane po kursie NBP z ostatniego dnia poprzedzającego transakcję. |
| **P1932** | `tp_local_file_requirements_jdg` | Wymogi Local File — analiza funkcjonalna, analiza cen transferowych, analiza porównywalna, dane finansowe podmiotów powiązanych. Art. 23zf PIT. |
| **P1933** | `tp_master_file_requirements_jdg` | Wymogi Master File — dla JDG należących do grupy o skonsolidowanych przychodach > 200M PLN. Opis grupy, model biznesowy, polityka TP. |
| **P1934** | `tp_tpr_form_filing_jdg` | Obowiązek złożenia TPR-C za poprzedni rok — termin: 11 miesięcy po zakończeniu roku podatkowego (tj. 30 listopada dla roku kalendarzowego). Art. 23zh PIT. |
| **P1935** | `tp_benchmarking_analysis_requirement` | Wymóg analizy porównawczej (benchmarking) dla transakcji z podmiotami powiązanymi — marże, ceny, warunki rynkowe. |
| **P1936** | `tp_safe_harbor_for_jdg` | Safe harbor dla niskowartościowych usług (low value-adding services) — marża 5%, pułap kosztowy 30% całkowitych kosztów. |
| **P1937** | `tp_adjustment_consequences_jdg` | Konsekwencje podatkowe doszacowania dochodu przez US — 10% dodatkowe opodatkowanie + odsetki za zwłokę. |
| **P1938** | `tp_penalty_for_lack_of_documentation` | Sankcje za brak dokumentacji TP: dodatkowe zobowiązanie podatkowe 10% doszacowanego dochodu, KKS Art. 56. |

## 14. REZYDENCJA PODATKOWA — P1940-P1949 🚨

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1940** | `tax_residency_determination_jdg` | Automatyczne określenie rezydencji podatkowej JDG — test 183 dni + centrum interesów życiowych + ośrodek interesów życiowych. Art. 3 PIT. |
| **P1941** | `double_tax_treaty_benefit_jdg` | Automatyczne wykrywanie korzyści z umów o unikaniu podwójnego opodatkowania — metoda wyłączenia z progresją vs. metoda odliczenia proporcjonalnego. |
| **P1942** | `certificate_of_tax_residence_requirement` | Wymóg posiadania certyfikatu rezydencji (CFR) kontrahenta zagranicznego dla zastosowania WHT i zwolnień — ważność CFR: 12 miesięcy od wydania. |
| **P1943** | `foreign_tax_credit_calculation_jdg` | Kalkulacja ulgi abolicyjnej / odliczenia podatku zagranicznego — maksymalne odliczenie = podatek polski przypadający na dochód zagraniczny. |
| **P1944** | `tax_residency_change_consequences_jdg` | Konsekwencje zmiany rezydencji podatkowej: exit tax (Art. 30da PIT) dla aktywów > 4M PLN, zamknięcie rozliczeń PL, obowiązki raportowe. |
| **P1945** | `dual_residency_conflict_resolution_jdg` | Rozwiązywanie konfliktów podwójnej rezydencji — tie-breaker rules z umów bilateralnych (stałe miejsce zamieszkania → ośrodek interesów życiowych → miejsce zwykłego pobytu → obywatelstwo). |
| **P1946** | `foreign_income_exemption_progression_jdg` | Metoda wyłączenia z progresją — dochód zagraniczny zwolniony, ale wpływa na stawkę podatku od dochodu polskiego (wyższy próg 32%). |
| **P1947** | `foreign_income_credit_method_jdg` | Metoda odliczenia proporcjonalnego — dochód zagraniczny opodatkowany w PL, podatek zagraniczny odliczany do limitu. |
| **P1948** | `permanent_establishment_risk_detailed_jdg` | Szczegółowe warunki powstania zakładu podatkowego za granicą — plac budowy > 12 miesięcy, stałe miejsce prowadzenia działalności, zależny przedstawiciel. |
| **P1949** | `digital_permanent_establishment_jdg` | Zakład wirtualny — serwer w obcym kraju, platforma cyfrowa, znacząca obecność cyfrowa (digital PE wg OECD BEPS 2.0 Pillar 1). |

## 15. DZIAŁALNOŚĆ SEZONOWA — P1950-P1956

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1950** | `seasonal_business_identification_jdg` | Identyfikacja JDG prowadzącej działalność sezonową — kryteria: przychody w ≤ 9 miesiącach roku, wzorzec powtarzalny. |
| **P1951** | `seasonal_business_suspension_vs_closure` 🔗 (współpracuje z P910-P919) | Rozróżnienie między zawieszeniem sezonowym a zamknięciem — zawieszenie zachowuje NIP, zamknięcie wymaga ponownej rejestracji. Reguła współpracuje z istniejącym blokiem zawieszenia P910-P919. |
| **P1952** | `seasonal_business_zus_strategy_jdg` | Strategia ZUS dla działalności sezonowej: zawieszenie vs. kontynuacja. Zawieszenie = brak składek (ale zdrowotna nadal). |
| **P1953** | `seasonal_business_pit_advances_jdg` | Zaliczki uproszczone jako optymalna strategia dla JDG sezonowej — stała zaliczka miesięczna, roczne rozliczenie. |
| **P1954** | `seasonal_business_vat_consequences` | VAT dla działalności sezonowej — deklaracje zerowe w okresie zawieszenia, zwrot VAT kosztów stałych. |
| **P1955** | `seasonal_business_loss_carry_forward` | Rozliczenie straty w działalności sezonowej — możliwość odliczenia od dochodu w ciągu 5 kolejnych lat. |
| **P1956** | `seasonal_business_annual_reconciliation` | Roczne rozliczenie dochodu dla sezonowej JDG — dochód liczony za okres aktywny, składki tylko za miesiące aktywne. |

## 16. WPŁYW SKAZANIA KKS — P1960-P1965

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1960** | `kks_conviction_professional_consequences` | Konsekwencje skazania za KKS dla JDG — zakaz prowadzenia działalności (Art. 41 KK), wykluczenie z zamówień publicznych (Art. 108 PZP), utrata licencji zawodowych. |
| **P1961** | `kks_conviction_banking_access` | Wpływ skazania na dostęp do bankowości — banki mogą wypowiedzieć umowę rachunku (AML/CFT), trudności z kredytem. |
| **P1962** | `kks_conviction_tax_office_relations` | Zaostrzony nadzór US po skazaniu — częstsze kontrole, monitoring transakcji, wpis na listę ostrzeżeń publicznych (Art. 119b OP). |
| **P1963** | `kks_conviction_business_partner_impact` | Wpływ na relacje z kontrahentami — utrata zaufania, odpowiedzialność solidarna kontrahenta za VAT (Art. 105a VAT). |
| **P1964** | `kks_conviction_rehabilitation_jdg` | Zatarcie skazania — po 3 latach od wykonania kary (wykroczenia), po 5 latach (przestępstwa). Skutki podatkowe zatarcia. |
| **P1965** | `kks_conviction_tax_arrears_enforcement` | Egzekucja zaległości podatkowych po skazaniu — odpowiedzialność całym majątkiem, zakaz ukrywania majątku (Art. 36 OP). |

## 17. ZAWODY REGULOWANE — P1970-P1977

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1970** | `regulated_profession_vat_exemption_jdg` | Zwolnienia VAT specyficzne dla zawodów regulowanych — lekarze (Art. 43 ust. 1 pkt 18-19 VAT), radcy prawni, adwokaci (brak zwolnienia — VAT 23%). |
| **P1971** | `regulated_profession_kup_catalog` | Specyficzne KUP dla zawodów regulowanych: składki korporacyjne (KUP — Art. 23 ust. 1 pkt 37 PIT), ubezpieczenie OC zawodowe (KUP — Art. 23 ust. 1 pkt 5 PIT[wyłączenie — ale OC obowiązkowe jest KUP na podstawie art. 22]), doskonalenie zawodowe (KUP — Art. 22 ust. 1 PIT). |
| **P1972** | `regulated_profession_zus_obligations` | Obowiązki ZUS dla zawodów regulowanych — często brak ulgi na start (świadczenie usług dla byłego pracodawcy w ramach JDG). |
| **P1973** | `regulated_profession_legal_privilege` | Tajemnica zawodowa a obowiązki podatkowe — dokumenty objęte tajemnicą adwokacką/radcowską wyłączone z kontroli (Art. 180 OP). |
| **P1974** | `regulated_profession_compulsory_membership` | Obowiązkowe składki korporacyjne (adwokacka, radcowska, lekarska, notarialna, doradców podatkowych) — KUP w dacie poniesienia. |
| **P1975** | `regulated_profession_cross_border_qualifications` | Uznawanie kwalifikacji zagranicznych — wpływ na formę opodatkowania i obowiązki podatkowe. |
| **P1976** | `regulated_profession_public_office_interaction` | Równoczesne pełnienie funkcji publicznych a JDG — notariusz, komornik — ograniczenia i specyfika podatkowa. |
| **P1977** | `regulated_profession_healthcare_taxation` | Specyfika opodatkowania zawodów medycznych: zwolnienie z VAT (usługi terapeutyczne) vs. opodatkowanie 23% (medycyna estetyczna), ryczałtowa stawka 14%. |

## 18. OBOWIĄZKOWE UBEZPIECZENIA OC — P1980-P1985

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1980** | `mandatory_insurance_detection_jdg` | Identyfikacja obowiązkowych ubezpieczeń OC dla JDG wg branży — OC przewoźnika (transport), OC zawodowe (prawnicy, lekarze, architekci, doradcy), OC budowlane. |
| **P1981** | `mandatory_insurance_premium_kup` | Składka na obowiązkowe ubezpieczenie OC — jest KUP w 100% (Art. 22 ust. 1 PIT), nawet jeśli polisa obejmuje elementy ponadobowiązkowe. |
| **P1982** | `voluntary_insurance_kup_jdg` | Dobrowolne ubezpieczenia JDG (OC ponadobowiązkowe, ubezpieczenie mienia, business interruption) — KUP, ale ograniczone do wartości rynkowej. |
| **P1983** | `insurance_claim_tax_treatment_jdg` | Odszkodowanie z ubezpieczenia jako przychód JDG — opodatkowane PIT, ale pomniejszone o stratę, której dotyczyło odszkodowanie. |
| **P1984** | `insurance_vat_treatment_jdg` | VAT od ubezpieczeń — zwolnione z VAT (Art. 43 ust. 1 pkt 37 VAT), ale usługi assistance i dodatkowe mogą być opodatkowane 23%. |
| **P1985** | `insurance_gap_detection_jdg` | Wykrywanie luk w ubezpieczeniach obowiązkowych — brak OC = kara administracyjna + odpowiedzialność odszkodowawcza osobista. |

## 19. NIESTANDARDOWE FORMY PŁATNOŚCI — P1990-P1998

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1990** | `crypto_payment_tax_recognition_jdg` 🔗 (odmienny od P1700-P1701) | Przyjęcie zapłaty w kryptowalucie za towary/usługi — przychód w PIT wg kursu PLN z dnia transakcji (Art. 14 ust. 1 PIT), obowiązek podatkowy VAT w dacie otrzymania zapłaty. **UWAGA:** Różni się od P1700 (NFT/VAT) i P1701 (DeFi/PIT) z Doc 40 — tamte dotyczą TRADINGU/INWESTOWANIA w krypto, ta dotyczy PRZYJMOWANIA krypto jako ZAPŁATY w JDG. |
| **P1991** | `barter_transaction_tax_treatment_jdg` | Transakcje barterowe (wymiana towar za usługę) — dwustronna dostawa towarów/świadczenie usług dla celów VAT. Każda strona wystawia fakturę. |
| **P1992** | `offsetting_kompensata_tax_jdg` | Potrącenie wzajemnych wierzytelności (kompensata) — dla celów PIT uznane za zapłatę w dacie kompensaty. VAT: metoda kasowa vs memoriałowa. |
| **P1993** | `instalment_payment_tax_recognition` | Zapłata w ratach — przychód w PIT w dacie otrzymania każdej raty. VAT: obowiązek podatkowy od całości w dacie dostawy (metoda memoriałowa). |
| **P1994** | `prepayment_advance_tax_jdg` | Zaliczki i przedpłaty — obowiązek podatkowy VAT w dacie otrzymania zaliczki (Art. 19a ust. 8 VAT). PIT: przychód w dacie otrzymania zaliczki. |
| **P1995** | `payment_in_kind_tax_jdg` | Świadczenie niepieniężne jako zapłata — wartość rynkowa świadczenia jako przychód (PIT) i podstawa VAT (Art. 29a VAT). |
| **P1996** | `foreign_currency_cash_payment_limit` | Limit płatności gotówkowych w walucie obcej — równowartość 15 000 PLN, przeliczana wg kursu NBP z dnia transakcji. |
| **P1997** | `electronic_payment_method_vat_jdg` | Przelew elektroniczny jako warunek odliczenia VAT — od 01.01.2025: obowiązek płatności przelewem na rachunek z białej listy dla transakcji >15k. |
| **P1998** | `card_terminal_obligation_jdg` | Obowiązek posiadania terminala płatniczego — JDG B2C o obrocie >20 000 EUR/rok i >50% transakcji z konsumentami. Sankcja: kara do 5 000 PLN za brak terminala. |

## 20. REKLAMA I MARKETING — P1999-P2007

| P-ID | Nazwa reguły | Opis skrócony |
|:----:|-------------|---------------|
| **P1999** | `advertising_vs_representation_kup_jdg` | Kluczowe rozróżnienie reklamy (KUP) od reprezentacji (NKUP) — reklama = informacja o produkcie/usłudze, reprezentacja = budowanie prestiżu/wizerunku osoby. Art. 23 ust. 1 pkt 23 PIT. |
| **P2000** | `advertising_online_digital_kup_jdg` | Wydatki na reklamę cyfrową — Google Ads, Facebook Ads, SEO, SEM — KUP w 100% (są reklamą, nie reprezentacją). |
| **P2001** | `advertising_events_hospitality_jdg` | Zaproszenia dla kontrahentów (event, kolacja) — test: czy głównym celem jest promocja produktu? Jeśli tak, KUP. Jeśli luksusowy wyjazd bez elementu promocyjnego — NKUP. |
| **P2002** | `advertising_gifts_business_jdg` | Prezenty dla kontrahentów — do 200 PLN wartości: KUP (jeśli oznakowane logo firmy). Powyżej 200 PLN: NKUP. Art. 23 ust. 1 pkt 23 PIT. |
| **P2003** | `advertising_sponsorship_kup_jdg` | Sponsoring jako koszt reklamy — KUP jeśli umowa sponsoringu określa świadczenia wzajemne (ekspozycja logo, promocja). Darowizna = inny reżim. |
| **P2004** | `advertising_vat_deduction_jdg` | VAT od wydatków reklamowych — odliczenie w 100% (są związane z czynnościami opodatkowanymi). Limit dla prezentów: 100 PLN netto (VAT odliczalny). |
| **P2005** | `advertising_social_media_influencer_jdg` | Wydatki na influencer marketing — KUP jeśli faktura opisuje świadczenie promocyjne. Ryzyko: US może uznać za reprezentację. |
| **P2006** | `advertising_car_wrapping_kup_jdg` | Oklejenie samochodu firmowego reklamą — KUP + pełne odliczenie VAT (100% zamiast 50%) + pełne KUP paliwa i wydatków eksploatacyjnych. Wymagane: zgłoszenie VAT-26. |
| **P2007** | `advertising_foreign_markets_kup_jdg` | Reklama na rynkach zagranicznych — dodatkowo ulga na ekspansję (do 1M PLN odliczenia od dochodu). Art. 26ec PIT. |

---

# CZĘŚĆ 21: PODSUMOWANIE — MAPA WSZYSTKICH NOWYCH REGUŁ

## 21.1 Statystyki końcowe

| Metryka | Wartość |
|---------|:-------:|
| **Nowe reguły (🆕)** | **~115** |
| **Obszary ENTERPRISE** | **20** |
| **Nowe pakiety .rego** | **11** |
| **Nowe thresholds** | **~55** |
| **Reguły 🚨 CRITICAL** | **42** |
| **[TODO: potrzebne źródło]** | **5** |

## 21.2 Nowe pakiety .rego

| Pakiet | Liczba reguł | Priorytet |
|--------|:-----------:|:---------:|
| `policies/jdg/compliance/mdr/` | 10 | 🔴 CRITICAL |
| `policies/jdg/tax/solidarity_levy/` | 5 | 🔴 CRITICAL |
| `policies/jdg/tax/binding_information/` | 8 | 🟡 HIGH |
| `policies/jdg/audit/procedures/` | 15 | 🔴 CRITICAL |
| `policies/jdg/continuity/force_majeure/` | 8 | 🟡 HIGH |
| `policies/jdg/family/` | 10 | 🟡 HIGH |
| `policies/jdg/digital/communication/` | 8 | 🔴 CRITICAL |
| `policies/jdg/compliance/public_procurement/` | 7 | 🟡 HIGH |
| `policies/jdg/tax/fx_rules/` | 9 | 🟡 HIGH |
| `policies/jdg/international/residency_treaties/` | 10 | 🔴 CRITICAL |
| `policies/jdg/specialized/seasonal/` | 7 | 🟢 MEDIUM |
| `policies/jdg/specialized/regulated_professions/` | 8 | 🟢 MEDIUM |
| **RAZEM** | **~115** | |

## 21.3 Priorytety wdrożenia

| Priorytet | Obszary | Liczba reguł | Czas wdrożenia |
|:---------:|---------|:-----------:|:--------------:|
| **P0 (KRYTYCZNE)** | MDR, Danina solidarnościowa, Kontrole, E-komunikacja, Ceny transferowe, Rezydencja | **~52** | 4 tygodnie |
| **P1 (WYSOKI)** | WIS/WIA/WIT, Siła wyższa, Rodzina w JDG, Zamówienia publiczne, FX, KKS skutki, Niestandardowe płatności | **~43** | 3 tygodnie |
| **P2 (ŚREDNI)** | Podpisy elektroniczne, Kalendarz płatności, Kwota wolna, Działalność sezonowa, Zawody regulowane, OC, Reklama | **~20** | 2 tygodnie |

---

> **🔥 WNIOSEK KOŃCOWY:** Po 43 dokumentach i ~800 regulach kanonicznych, niniejsza analiza identyfikuje **~115 nowych reguł w 20 całkowicie niepokrytych obszarach**. Są to obszary kluczowe dla bezpieczeństwa prawnego, zgodności regulacyjnej i zaufania w systemie ENTERPRISE — od MDR (kryminalizowane obowiązki raportowania), przez daninę solidarnościową (automatyczny podatek dla zamożnych JDG), po szczegółowe procedury kontrolne (prawa i obowiązki JDG wobec organów). Wdrożenie tych reguł podnosi system NexusAI JDG z poziomu "zaawansowanego compliance" do poziomu "full enterprise legal shield".

> **Następny krok:** Integracja 115 reguł z mapą kanoniczną `38c_JDG_CANONICAL_MAP.md`. Priorytet P0: rozpocząć od MDR i daniny solidarnościowej.

---

*Wygenerowano przez NexusAI Advanced Gap Analysis Engine v3.0*  
*Data: 2026-07-12*  
*Bazuje na: 38c_JDG_CANONICAL_MAP.md (~800 reguł), DocsJDG (źródła prawne), dokumentach 22-43*  
*Nowe reguły: ~115 Macro (P-ID)*  
*Gotowość wdrożeniowa: Specyfikacja ENTERPRISE — gotowa do implementacji w Rego*
