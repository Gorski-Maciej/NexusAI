# 🚀 NexusAI JDG — Deep Gap Analysis & Final Frontier ENTERPRISE

> **Status:** ENTERPRISE FINAL FRONTIER v1.0 — 10 nowych obszarów, 20+ reguł klasy ENTERPRISE  
> **Data:** 2026-07-12  
> **Autor:** Zespół NexusAI — Chief Architect Deep Analysis  
> **Plik:** `Plan OPA/40_JDG_DEEP_GAP_FINAL_FRONTIER.md`  
> **Bazuje na:** Głębokiej analizie braków (thinker-gemini), `38c_JDG_CANONICAL_MAP.md` (294 reguły), `39_JDG_COMPREHENSIVE_TEN_AREAS_EXPANSION.md` (~140 reguł), `DocsJDG` (źródła prawne)  
> **Przeznaczenie:** Identyfikacja i opis CAŁKOWICIE NOWYCH, zaawansowanych obszarów regulacyjnych, które nie zostały pokryte w żadnym z istniejących dokumentów (22-39). Reguły są gotowe do implementacji ENTERPRISE.

---

## 📊 EXECUTIVE SUMMARY

### Dlaczego ten dokument?

System JDG NexusAI ma już **434+ reguł** (294 kanoniczne + ~140 z rozbudowy). Jednak głęboka analiza ujawniła **20 kluczowych luk** w obszarach, które są absolutnie niezbędne dla systemu klasy ENTERPRISE w 2026 roku:

| # | Obszar | Nowe reguły | Status w istniejących dokumentach |
|---|--------|:-----------:|----------------------------------|
| 1 | **Gospodarka cyfrowa i kryptoaktywa** | 2 | ❌ Całkowicie niepokryte |
| 2 | **Specyficzne branże JDG** | 3 | ❌ Całkowicie niepokryte |
| 3 | **Interakcje kaskadowe** | 1 | ❌ Całkowicie niepokryte |
| 4 | **Audyt, compliance i sygnaliści** | 2 | ❌ Całkowicie niepokryte |
| 5 | **Transgraniczne rozszerzone (CFC, Exit Tax)** | 2 | ❌ Całkowicie niepokryte |
| 6 | **Restrukturyzacja i niewypłacalność** | 2 | ❌ Całkowicie niepokryte |
| 7 | **Prawo pracy JDG jako pracodawcy** | 2 | ❌ Całkowicie niepokryte |
| 8 | **Ochrona środowiska (SUP, CBAM)** | 2 | ❌ Całkowicie niepokryte |
| 9 | **Cyfryzacja (e-Doręczenia)** | 1 | ❌ Całkowicie niepokryte |
| 10 | **Bezpieczeństwo i RODO** | 3 | ❌ Całkowicie niepokryte |
| **RAZEM** | | **20** | **100% nowych obszarów** |

### Legenda

| Symbol | Znaczenie |
|:------:|-----------|
| 🆕 | **CAŁKOWICIE NOWY OBSZAR** — zero pokrycia w dokumentach 22-39 |
| 🚨 | **KRYTYCZNA** — brak reguły = ryzyko sankcji karnych/finansowych |
| ⚖️ | **WYMAGANA PRAWNA** — obowiązek ustawowy od 2024-2026 |
| 🔗 | **Zależność** — łączy się z istniejącymi regułami kanonicznymi |

---

# CZĘŚĆ 0: MAPA INTEGRACJI — NOWE PAKIETY I PLIKI

| Obszar | Nowy pakiet | Nowy plik .rego | Nowe P-ID |
|--------|------------|-----------------|:---------:|
| 1. Kryptoaktywa | `policies/jdg/crypto/` | `crypto_assets.rego` | P1700-P1709 |
| 2. Branże specjalistyczne | `policies/jdg/specialized/` | `transport.rego`, `ecommerce.rego`, `healthcare.rego` | P1710-P1724 |
| 3. Interakcje kaskadowe | `policies/jdg/cascade/` | `cascade_effects.rego` | P1725-P1729 |
| 4. Compliance rozszerzone | `policies/jdg/compliance/` | `whistleblower.rego`, `aml_kyc.rego` | P1730-P1739 |
| 5. Transgraniczne CFC/Exit | `policies/jdg/international/` | `cfc_exit_tax.rego` | P1740-P1749 |
| 6. Niewypłacalność | `policies/jdg/insolvency/` | `bankruptcy_restructuring.rego` | P1750-P1759 |
| 7. Prawo pracy JDG | `policies/jdg/employer/` | `pfron.rego`, `foreign_workers.rego` | P1760-P1769 |
| 8. Ochrona środowiska | `policies/jdg/environmental/` | `sup_plastic.rego`, `cbam.rego` | P1770-P1779 |
| 9. Cyfryzacja | `policies/jdg/digital/` | `e_delivery.rego` | P1780-P1789 |
| 10. Bezpieczeństwo/RODO | `policies/jdg/security/` | `ksef_token.rego`, `gdpr_dpa.rego`, `ksef_offline.rego` | P1790-P1799 |

---

# CZĘŚĆ 1: GOSPODARKA CYFROWA I KRYPTOAKTYWA 🆕

> **Dlaczego krytyczne:** Urzędy Skarbowe intensyfikują kontrole dochodów cyfrowych (OSINT). Błędna kwalifikacja NFT lub DeFi skutkuje karą z KKS i wstecznym naliczeniem podatku. W 2026 roku kryptoaktywa są już mainstreamowym aktywem JDG — system ENTERPRISE musi je obsługiwać.

---

### P1700 🆕 `crypto_nft_vat_classification_jdg`

- **Cel biznesowy:** Rozróżnienie VAT dla NFT użytkowych (utility NFT) od NFT stanowiących certyfikat własności. NFT użytkowe = dostawa usługi elektronicznej (VAT 23%), NFT własnościowe = opodatkowane jak towar bazowy (np. dzieło sztuki = stawka właściwa dla towaru).
- **Przesłanki:**
  - `input.invoice.asset_type == "NFT"`
  - `input.invoice.nft_category` w `["UTILITY", "OWNERSHIP_CERTIFICATE", "COLLECTIBLE"]`
  - `input.invoice.transaction_type` w `["MINT", "SALE", "TRANSFER"]`
- **Klasyfikacja:**

| Kategoria NFT | VAT | Podstawa opodatkowania | Uwagi |
|:---|:---:|:---|:---|
| `UTILITY` (bilet, dostęp do platformy) | 23% | Cała kwota | Traktowane jak usługa elektroniczna |
| `OWNERSHIP_CERTIFICATE` (tokenizowana nieruchomość) | Jak towar bazowy | Wartość rynkowa towaru | Art. 7 VAT |
| `COLLECTIBLE` (cyfrowa sztuka) | 23% (lub marża) | Marża lub całość | Art. 120 VAT jeśli spełnione warunki |
| `GAMING` (przedmioty w grze) | 23% | Cała kwota | Traktowane jak usługa |

- **Rezultat:**
  - `vat_rate: <wg tabeli>`
  - `nft_vat_classification: <kategoria>`
  - `vat_procedure: <"STANDARD" | "MARGIN">`
  - `_warning: "NFT sklasyfikowany jako X — stawka VAT Y%. Sprawdź czy klasyfikacja jest prawidłowa."`
- **Podstawa prawna:** Art. 7, Art. 8 ustawy o VAT, wyrok TSUE C-264/14 (wymienialność walut wirtualnych), Dyrektywa DAC8 (2023)
- **Edge cases:**
  - (a) NFT mintowane przez JDG i sprzedawane na OpenSea → JDG jest twórcą = pierwsza sprzedaż = VAT należny
  - (b) NFT kupiony i odsprzedany → JDG działa jako pośrednik = VAT od marży (jeśli spełnione warunki)
  - (c) NFT w modelu royalty (tantiemy od każdej odsprzedaży) → przychód z praw majątkowych
- **Zależności:** Po P50 `vat_margin_scheme` (jeśli marża). Przed regułami stawek VAT.
- **Thresholds:** `jdg.crypto.nft_categories` (lista), `jdg.crypto.nft_vat_rates` (mapowanie)
- **`[TODO: potrzebne źródło]`** — oficjalne stanowisko MF/KIS w sprawie NFT (interpretacja ogólna)
- **Przykład +:** NFT utility (bilet na koncert) sprzedany za 0.5 ETH → VAT 23% od wartości w PLN na dzień transakcji
- **Przykład −:** NFT ownership certyfikat tokenizowanego złota → opodatkowane jak złoto inwestycyjne (zwolnione z VAT)

---

### P1701 🆕 `crypto_defi_staking_pit_jdg`

- **Cel biznesowy:** Klasyfikacja przychodów z DeFi (staking, liquidity mining, yield farming) dla JDG. Rozróżnienie: przychody z odsetek krypto (prawa majątkowe — skala PIT) vs. przychody z działalności operacyjnej (działalność gospodarcza — też skala, ale z KUP).
- **Przesłanki:**
  - `input.invoice.asset_type == "CRYPTO"`
  - `input.invoice.crypto_income_type` w `["STAKING_REWARDS", "LIQUIDITY_MINING", "LENDING_INTEREST", "AIRDROP"]`
  - `input.jdg_entrepreneur.crypto_activity_regular == true/false` (czy prowadzi zorganizowaną działalność)
- **Klasyfikacja PIT:**

| Typ przychodu krypto | Źródło PIT | Stawka | KUP |
|:---|:---|:---:|:---:|
| `STAKING_REWARDS` (okazjonalny) | Prawa majątkowe (Art. 18) | Skala 12%/32% | 20% ryczałtowe |
| `STAKING_REWARDS` (zorganizowany, JDG) | Działalność gospodarcza (Art. 10) | Skala 12%/32% | Pełny KUP |
| `LIQUIDITY_MINING` | Działalność gospodarcza | Skala 12%/32% | Pełny KUP |
| `LENDING_INTEREST` | Kapitały pieniężne (Art. 17) | 19% ryczałt | Brak KUP |
| `AIRDROP` (promocyjny) | Inne źródła (Art. 20) | Skala 12%/32% | Brak KUP |

- **Rezultat:**
  - `pit_income_source: <źródło>`
  - `pit_rate: <stawka>`
  - `kus_qualification: <"FULL" | "20_PERCENT" | "NONE">`
  - `_warning: "Przychód z DeFi sklasyfikowany jako X — opodatkowany wg Y."`
- **Podstawa prawna:** Art. 10, Art. 17, Art. 18, Art. 20 PIT, KIS 0114-KDIP3-1.4011.xxx (interpretacje indywidualne)
- **Edge cases:**
  - (a) Staking ETH przez JDG IT — jeśli zorganizowany, regularny → działalność gospodarcza
  - (b) Jednorazowy airdrop UNI → inne źródła, skala PIT
  - (c) Lending na Aave → kapitały pieniężne, 19% ryczałt (jak odsetki bankowe)
- **Zależności:** W nowym pakiecie `jdg.crypto`. Niezależna od innych reguł PIT — działa jako pre-klasyfikator.
- **Thresholds:** `jdg.crypto.defi_income_categories` (mapowanie na źródła PIT)
- **`[TODO: potrzebne źródło]`** — oficjalne stanowisko MF w sprawie DeFi (oczekiwana interpretacja ogólna)
- **Przykład +:** JDG IT stakuje ETH regularnie → działalność gospodarcza, skala 12%/32%, pełny KUP
- **Przykład −:** Okazjonalny staking przez osobę nieprowadzącą działalności → prawa majątkowe, 20% KUP

---

# CZĘŚĆ 2: SPECYFICZNE BRANŻE JDG 🆕

> **Dlaczego krytyczne:** Specyficzne branże posiadają wyłączenia, których pominięcie prowadzi do gigantycznego nadpłacania lub unikania podatków. Transport międzynarodowy, e-commerce dropshipping i medycyna estetyczna to obszary szczególnie narażone na kontrole US.

---

### P1710 🆕 `transport_mobility_package_deduction_jdg`

- **Cel biznesowy:** Implementacja Pakietu Mobilności UE — kierowcy międzynarodowi zatrudnieni w JDG transportowym mają prawo do wyłączenia z podstawy ZUS i PIT części wynagrodzenia odpowiadającej zagranicznym dietom i ryczałtom za noclegi. Zmniejsza to podstawę opodatkowania i składkową.
- **Przesłanki:**
  - `input.jdg_entrepreneur.pkd_main` w `["49.41.Z", "49.42.Z"]` (transport drogowy)
  - `input.jdg_entrepreneur.employees_count >= 1`
  - `input.invoice.expense_type == "DRIVER_SALARY"`
  - `input.invoice.driver_days_abroad > 0` (dni pracy za granicą)
- **Kalkulacja ulgi:**
  - `dieta_zagraniczna = stawka_diety_kraj_docelowy * dni_za_granica`
  - `ryczalt_noclegowy = dieta_zagraniczna * 0.25` (jeśli brak udokumentowanych noclegów)
  - `podstawa_ZUS_PIT = wynagrodzenie_brutto - dieta_zagraniczna - ryczalt_noclegowy`
- **Rezultat:**
  - `driver_tax_base_reduction: <kwota wyłączenia>`
  - `zus_base_reduction: <kwota wyłączenia>`
  - `_info: "Pakiet Mobilności — wyłączenie X PLN z podstawy ZUS i PIT za Y dni za granicą"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 23d PIT, Rozporządzenie MPiPS w sprawie diet zagranicznych, Pakiet Mobilności UE (Rozporządzenie 2020/1054)
- **Edge cases:**
  - (a) Kierowca pracuje w kilku krajach w jednym miesiącu → suma diet dla każdego kraju
  - (b) Dieta należy się tylko za minimum 8 godzin pobytu za granicą
  - (c) Ryczałt noclegowy tylko gdy nocleg nieudokumentowany
- **Zależności:** W pakiecie `jdg.specialized.transport`. Przed regułami ZUS i PIT.
- **Thresholds:** `jdg.transport.driver_diet_rates_by_country` (mapa kraj→stawka diety)
- **Przykład +:** Kierowca 20 dni w Niemczech, dieta 49 EUR/dzień → wyłączenie ~980 EUR z podstawy ZUS i PIT
- **Przykład −:** Kierowca krajowy, 0 dni za granicą → brak wyłączenia

---

### P1711 🆕 `ecommerce_dropshipping_agent_vs_supplier_vat_jdg`

- **Cel biznesowy:** Kwalifikacja VAT dla modelu dropshipping — rozróżnienie między modelem agenta (VAT tylko od prowizji) a modelem dostawcy (VAT od całej kwoty). Kluczowe dla JDG sprzedających przez Shopify/Allegro z dostawą z Chin.
- **Przesłanki:**
  - `input.jdg_entrepreneur.business_model == "DROPSHIPPING"`
  - `input.invoice.direction == "SALE"`
  - Analiza czy JDG działa w imieniu własnym czy jako pośrednik
- **Kryteria rozróżnienia (test 3 kroków):**

| Krok | Kryterium | Agent (pośrednik) | Supplier (dostawca) |
|:---:|-----------|:---:|:---:|
| 1 | Kto widnieje na fakturze dla klienta? | Dostawca / platforma | JDG |
| 2 | Kto ponosi ryzyko zwrotu? | Dostawca | JDG |
| 3 | Kto ustala cenę końcową? | JDG (prowizja od ceny) | JDG (marża na cenie) |

- **Rezultat:**
  - `dropshipping_model: <"AGENT" | "SUPPLIER">`
  - `vat_taxable_amount: <prowizja dla AGENT | cała kwota dla SUPPLIER>`
  - `vat_rate: <wg towaru>`
  - `_warning: "Model dropshipping: X. Podstawa VAT: Y PLN."`
- **Podstawa prawna:** Art. 7 ust. 8, Art. 8 VAT (dostawa łańcuchowa), Art. 106e VAT (faktura)
- **Edge cases:**
  - (a) Dropshipping z Chin do klienta PL → import towaru + sprzedaż w PL (JDG importerem)
  - (b) Dropshipping PL→PL (hurtownik→JDG→klient) → JDG sprzedawcą, VAT od całości
  - (c) Dropshipping przez platformę (Amazon FBA) → platforma rozlicza VAT, JDG dostaje raport
- **Zależności:** Przed regułami stawek VAT. W pakiecie `jdg.specialized.ecommerce`.
- **Thresholds:** brak (test jakościowy)
- **Przykład +:** JDG pośredniczy (klient widzi dostawcę), prowizja 50 PLN → VAT od 50 PLN
- **Przykład −:** JDG wystawia fakturę na swoje nazwisko, cena 200 PLN, koszt 100 PLN → VAT od 200 PLN

---

### P1712 🆕 `healthcare_aesthetic_vs_therapeutic_vat_jdg`

- **Cel biznesowy:** Rozróżnienie zwolnienia z VAT dla usług medycznych — tylko usługi o celu ŚCIŚLE LECZNICZYM są zwolnione. Medycyna estetyczna, zabiegi upiększające i wellness podlegają VAT 23%.
- **Przesłanki:**
  - `input.jdg_entrepreneur.pkd_main` w `["86.21.Z", "86.22.Z", "86.90.E"]` (praktyka lekarska, fizjoterapia, medycyna estetyczna)
  - `input.invoice.category_code` w `["HEALTHCARE", "AESTHETIC_MEDICINE"]`
  - `input.invoice.procedure_code` (kod ICD-9 / ICD-10 wykonywanego zabiegu)
- **Klasyfikacja:**

| Kategoria | Cel zabiegu | VAT | Uwagi |
|:---|:---|---:|:---|
| Terapeutyczny | Leczenie choroby, rehabilitacja | ZW | Art. 43 ust. 1 pkt 19 VAT |
| Profilaktyczny | Badania okresowe, szczepienia | ZW | Art. 43 ust. 1 pkt 18 VAT |
| Estetyczny czysty | Powiększanie ust, botoks kosmetyczny | 23% | Wyrok TSUE C-91/12 |
| Mieszany | Korekta przegrody nosa (oddech + wygląd) | ZW (jeśli przeważa cel leczniczy) | Orzecznictwo TSUE |

- **Rezultat:**
  - `vat_rate: <"ZW" | "0.23">`
  - `healthcare_vat_classification: <kategoria>`
  - `_warning: "Zabieg sklasyfikowany jako X — VAT Y%. Zweryfikuj dokumentację medyczną."`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 18-19 VAT, wyrok TSUE C-91/12 (PFC Clinic), wyrok TSUE C-212/20 (estetyka)
- **Edge cases:**
  - (a) Botoks przy migrenie (cel leczniczy) → ZW
  - (b) Botoks przy zmarszczkach (cel estetyczny) → 23% VAT
  - (c) Zabieg dentystyczny wybielania zębów → 23% VAT (nie jest leczeniem)
- **Zależności:** Rozszerza P56 `vat_exemption_healthcare`. Ta reguła jest bardziej szczegółowa — ma pierwszeństwo przed P56.
- **Thresholds:** `jdg.healthcare.aesthetic_procedure_codes` (lista kodów ICD estetycznych)
- **Przykład +:** Fizjoterapia po złamaniu → ZW (cel terapeutyczny)
- **Przykład −:** Powiększanie ust kwasem hialuronowym → 23% VAT (cel estetyczny)

---

# CZĘŚĆ 3: INTERAKCJE KASKADOWE 🆕

> **Dlaczego krytyczne:** W systemach transakcyjnych błąd w jednej metodzie przenosi się kaskadowo — VAT → KUP → PIT → ZUS. System ENTERPRISE musi wykrywać i rozwiązywać te konflikty automatycznie.

---

### P1725 🆕 `advanced_cascade_cash_method_mismatch_jdg`

- **Cel biznesowy:** Wykrycie i rozwiązanie konfliktu między metodą kasową PIT a ulgą na złe długi VAT. Jeśli JDG stosuje metodę kasową (KUP dopiero w dacie zapłaty), a jednocześnie jest dłużnikiem objętym ulgą na złe długi VAT (obowiązek korekty VAT po 90 dniach), system musi zapewnić spójność obu korekt.
- **Przesłanki:**
  - `input.jdg_entrepreneur.uses_cash_method_pit == true` (metoda kasowa PIT)
  - `input.invoice.is_paid == false`
  - `input.invoice.days_overdue >= input.thresholds.jdg.limits.bad_debt_days_cit_pit` (90 dni)
  - `input.invoice.is_vat_deducted == true`
- **Analiza konfliktu:**
  - Krok 1: Metoda kasowa PIT → KUP = 0 (niezapłacone)
  - Krok 2: Ulga na złe długi VAT → korekta VAT in minus
  - Krok 3: Czy kwota netto faktury zmienia się po korekcie VAT?
  - Krok 4: Jeśli netto = const (VAT nie wchodzi do KUP), nie ma konfliktu. Jeśli netto się zmienia → konieczna podwójna korekta.
- **Rezultat:**
  - `cascade_conflict_detected: true/false`
  - `cascade_resolution: <"NO_CONFLICT" | "SEQUENTIAL_ADJUSTMENT" | "MANUAL_REVIEW">`
  - `_warning: "Konflikt kaskadowy metoda kasowa/ulga VAT — rozwiązanie: X."`
- **Podstawa prawna:** Art. 22 ust. 5-5c PIT (metoda kasowa), Art. 89b VAT (złe długi dłużnika)
- **Edge cases:**
  - (a) Faktura częściowo zapłacona → proporcjonalna korekta obu
  - (b) Późniejsza zapłata → odwrócenie korekty VAT + przywrócenie KUP
  - (c) JDG zmienia metodę z kasowej na memoriałową w trakcie roku
- **Zależności:** Między P184 `bad_debt_debtor_correction_mandatory` a P572 `kup_direct_vs_indirect_timing`.
- **Thresholds:** `jdg.limits.bad_debt_days_cit_pit` (90)
- **Przykład +:** Niezapłacona faktura netto 10k + VAT 2.3k, metoda kasowa → KUP=0, po 90 dniach korekta VAT -2.3k, netto nadal 10k → brak konfliktu
- **Przykład −:** Faktura za środek trwały z VAT jako częścią wartości początkowej → konflikt: czy korekta VAT zmienia amortyzację?

---

# CZĘŚĆ 4: AUDYT I COMPLIANCE ROZSZERZONE 🆕

---

### P1730 🆕 `compliance_whistleblower_procedure_required_jdg` 🚨⚖️

- **Cel biznesowy:** Obowiązek wdrożenia procedury przyjmowania zgłoszeń od sygnalistów dla JDG, która przekracza próg 50 osób wykonujących pracę zarobkową (w tym B2B, zlecenia). Brak procedury = kara do 30 000 PLN.
- **Przesłanki:**
  - `input.jdg_entrepreneur.workers_count >= 50` (pracownicy + zleceniobiorcy + B2B)
  - `input.jdg_entrepreneur.whistleblower_procedure_implemented == false`
  - Data wejścia obowiązku: od 25.09.2024 (JDG 50-249 osób) lub od 17.12.2023 (JDG ≥250 osób)
- **Rezultat:**
  - `whistleblower_procedure_required: true`
  - `whistleblower_deadline_passed: true/false`
  - `whistleblower_potential_penalty: "do_30_000_PLN"`
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Obowiązek wdrożenia procedury sygnalistów! Przekraczasz próg 50 pracowników. Kara do 30 000 PLN za brak."`
- **Podstawa prawna:** Ustawa z dnia 14 czerwca 2024 r. o ochronie sygnalistów (Dz.U. 2024 poz. 928), implementacja Dyrektywy UE 2019/1937 **[TODO: potrzebne źródło – dodać do DocsJDG]**
- **Edge cases:**
  - (a) JDG z 48 pracownikami + 3 zleceniobiorcami B2B = 51 osób → obowiązek istnieje (przy założeniu, że B2B wlicza się do limitu) **[TODO: zweryfikować czy B2B wlicza się do progu 50 osób wg finalnych wytycznych PIP/MF]**
  - (b) JDG z 50+ osobami ale tylko przez część roku → obowiązek od miesiąca przekroczenia progu
  - (c) Procedura musi być dostępna również dla byłych pracowników i kandydatów
- **Zależności:** Po regułach pracodawcy (P1200e-P1208e). W pakiecie `jdg.compliance`.
- **Thresholds:** `jdg.compliance.whistleblower_threshold` (50)
- **Przykład +:** JDG z 55 osobami, brak procedury → TRIAGE + alert o karze
- **Przykład −:** JDG z 30 osobami → obowiązek nie istnieje

---

### P1731 🆕 `aml_kyc_procedure_jdg_obligation` 🚨⚖️

- **Cel biznesowy:** Obowiązek AML/KYC dla JDG prowadzących określone rodzaje działalności (biura rachunkowe, obsługa krypto, doradztwo podatkowe, pośrednictwo nieruchomości). Wymagana wewnętrzna procedura AML i raportowanie do GIIF.
- **Przesłanki:**
  - `input.jdg_entrepreneur.pkd_main` w katalogu instytucji obowiązanych AML
  - `input.jdg_entrepreneur.aml_procedure_implemented == false`
- **Katalog PKD objętych AML:**

| PKD | Opis | Obowiązek AML |
|:---|:---|:---:|
| 69.20.Z | Usługi rachunkowo-księgowe | ✅ Pełny |
| 69.10.Z | Doradztwo prawne (niektóre) | ✅ Ograniczony |
| 66.19.Z | Usługi związane z krypto | ✅ Pełny |
| 68.31.Z | Pośrednictwo nieruchomości | ✅ Pełny |
| 64.99.Z | Pozostała działalność finansowa | ✅ Pełny |

- **Rezultat:**
  - `aml_obligated_entity: true`
  - `aml_procedure_required: true`
  - `aml_generates_mdr: true` (dla krypto)
  - `_routing: "TRIAGE_QUEUE"`
  - `_warning: "Twoja działalność podlega AML — wdróż procedurę i raportuj do GIIF. Kara do 5 000 000 PLN."`
- **Podstawa prawna:** Ustawa z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 567 ze zm.)
- **Edge cases:**
  - (a) Biuro rachunkowe JDG → obowiązek rejestracji w GIIF + procedura + szkolenia
  - (b) JDG IT obsługujące giełdy krypto → może podlegać AML jako dostawca usług
- **Zależności:** W pakiecie `jdg.compliance`. Powiązane z P1800 `mdr_reportable_scheme_detection`.
- **Thresholds:** `jdg.compliance.aml_obligated_pkd` (lista PKD)
- **Przykład +:** Biuro rachunkowe JDG, brak procedury AML → TRIAGE + alert
- **Przykład −:** JDG IT z PKD 62.01.Z → nie podlega AML

---

# CZĘŚĆ 5: TRANSGRANICZNE ROZSZERZONE — CFC I EXIT TAX 🆕

---

### P1740 🆕 `crossborder_cfc_jdg_holding` 🚨

- **Cel biznesowy:** Wykrycie obowiązku podatkowego CFC (Controlled Foreign Company) — gdy polski JDG posiada udziały w zagranicznej spółce generującej pasywne dochody. Polski JDG musi zapłacić 19% PIT od dochodów tej zagranicznej spółki proporcjonalnie do udziałów.
- **Przesłanki:**
  - `input.jdg_entrepreneur.foreign_company_shares_percent >= 50` (kontrola >50%) LUB `>= 25` (jeśli powiązane)
  - `input.jdg_entrepreneur.foreign_company_country` w liście krajów CFC (stawka CIT < 14.25% lub brak opodatkowania)
  - `input.jdg_entrepreneur.foreign_company_passive_income_ratio > 0.50` (powyżej 50% przychodów pasywnych)
  - `input.jdg_entrepreneur.foreign_company_annual_income_pln > równowartość 250_000_EUR` (przeliczone wg kursu NBP z ostatniego dnia roku podatkowego zagranicznej spółki)
- **Rezultat:**
  - `cfc_obligation: true`
  - `cfc_tax_rate: "0.19"`
  - `cfc_tax_base: <dochód zagranicznej spółki × udział JDG>`
  - `cfc_requires_pit_cfc_form: true` (PIT-CFC)
  - `_warning: "Posiadasz zagraniczną spółkę kontrolowaną (CFC) — musisz opodatkować jej dochody 19% PIT w Polsce. Złóż PIT-CFC."`
- **Podstawa prawna:** Art. 30f PIT (CFC), Art. 27 ust. 1 ustawy o PIT
- **Edge cases:**
  - (a) Spółka estońska z CIT 0% → podlega CFC (brak realnego opodatkowania)
  - (b) Spółka cypryjska z CIT 12.5% → podlega CFC (poniżej 14.25%)
  - (c) Spółka niemiecka z CIT ~30% → nie podlega CFC
  - (d) Udziały 30% + powiązania rodzinne → może podlegać
- **Zależności:** Po P110 `permanent_establishment_risk` i P114 `tp_documentation_threshold`. W pakiecie `jdg.international`.
- **Thresholds:** `jdg.international.cfc_ownership_threshold` (50), `jdg.international.cfc_effective_tax_threshold` (0.1425), `jdg.international.cfc_de_minimis_eur` (250 000 — przeliczane dynamicznie wg kursu NBP, NIE jako stała kwota PLN) **[TODO: potrzebne źródło — mechanizm dynamicznego przeliczania EUR/PLN przez DuckDB]**
- **Przykład +:** JDG ma 100% spółki w Estonii (CIT 0%), dochód 500k PLN → 19% × 500k = 95k PLN PIT w Polsce
- **Przykład −:** JDG ma 100% spółki w Niemczech (CIT ~30%) → nie podlega CFC

---

### P1741 🆕 `crossborder_exit_tax_jdg` 🚨

- **Cel biznesowy:** Podatek od niezrealizowanych zysków (exit tax) — 19% (lub 3% w ratach) gdy polski JDG przenosi rezydencję podatkową za granicę lub przenosi składniki majątku za granicę o wartości > 4 mln PLN.
- **Przesłanki:**
  - `input.jdg_entrepreneur.tax_residency_changing_to != "PL"` (zmiana rezydencji)
  - `input.jdg_entrepreneur.assets_transferred_abroad_value > input.thresholds.jdg.international.exit_tax_threshold` (4 mln PLN)
  - `input.jdg_entrepreneur.unrealized_gains > 0` (niezrealizowane zyski)
- **Rezultat:**
  - `exit_tax_obligation: true`
  - `exit_tax_rate: "0.19"`
  - `exit_tax_base: <niezrealizowane zyski>`
  - `exit_tax_payment_option: "LUMP_SUM_19PCT"` (płatność jednorazowa 19%)
  - `exit_tax_payment_option: "5_INSTALLMENTS_20PCT_EACH"` (5 równych rat rocznych po 20% kwoty podatku każda, z opłatą prolongacyjną 50% stopy odsetek podstawowych)
  - `exit_tax_due_date: "przed_dniem_utraty_rezydencji"`
  - `_warning: "Zmiana rezydencji podatkowej + aktywa > 4 mln PLN → exit tax 19% od niezrealizowanych zysków! Możliwość rozłożenia na 5 rat rocznych."`
- **Podstawa prawna:** Art. 30da PIT (exit tax)
- **Edge cases:**
  - (a) Całkowita wartość aktywów < 4 mln PLN → brak exit tax
  - (b) Aktywa o wartości 10 mln PLN, koszt nabycia 6 mln PLN → niezrealizowany zysk 4 mln PLN → exit tax 760k PLN jednorazowo (lub 5 × 152k PLN w ratach)
  - (c) Rozłożenie na 5 rat rocznych: każda rata = 20% kwoty podatku (nie 3%!). Opłata prolongacyjna = 50% stopy odsetek podstawowych od kwoty odroczonej. Art. 30da ust. 5-6 PIT.
- **Zależności:** W pakiecie `jdg.international`. Powiązane z P110 `permanent_establishment_risk`.
- **Thresholds:** `jdg.international.exit_tax_threshold` (4 000 000), `jdg.international.exit_tax_rate` (0.19), `jdg.international.exit_tax_installment_rate` (0.20 — każda rata to 20% kwoty podatku) **[TODO: potrzebne źródło — potwierdzenie wartości progowej 4 mln PLN na 2026]**
- **Przykład +:** JDG przenosi się do Szwajcarii, aktywa 8 mln PLN, niezrealizowany zysk 3 mln PLN → exit tax 570k PLN
- **Przykład −:** Aktywa 2 mln PLN → poniżej progu → brak exit tax

---

# CZĘŚĆ 6: RESTRUKTURYZACJA I NIEWYPŁACALNOŚĆ 🆕

---

### P1750 🆕 `insolvency_bankruptcy_business_vs_consumer_jdg` 🚨

- **Cel biznesowy:** Rozróżnienie między upadłością przedsiębiorcy (JDG) a upadłością konsumencką (osoby fizycznej po wykreśleniu JDG z CEIDG). Skutki podatkowe i ZUS są fundamentalnie różne.
- **Przesłanki:**
  - `input.jdg_entrepreneur.is_insolvent == true`
  - `input.jdg_entrepreneur.business_status` w `["ACTIVE", "SUSPENDED", "CLOSED"]`
- **Rozróżnienie:**

| Status JDG | Typ upadłości | Skutki podatkowe | Skutki ZUS |
|:---|:---|:---|:---|
| ACTIVE / SUSPENDED | Upadłość przedsiębiorcy | Syndyk przejmuje majątek, spłata wierzycieli wg kategorii | Syndyk opłaca składki |
| CLOSED (wykreślony z CEIDG) | Upadłość konsumencka | Oddłużenie po wykonaniu planu spłaty | Koniec obowiązku ZUS |

- **Rezultat:**
  - `insolvency_type: <"BUSINESS" | "CONSUMER">`
  - `syndyk_required: true` (dla BUSINESS)
  - `tax_arrears_priority: <kategoria wierzytelności>`
  - `_warning: "Upadłość typu X — procedura Y. Zobowiązania podatkowe w kategorii Z."`
- **Podstawa prawna:** Prawo upadłościowe (Dz.U. 2025 poz. 345), Prawo restrukturyzacyjne
- **Edge cases:**
  - (a) JDG z długami 500k PLN → upadłość przedsiębiorcy → syndyk sprzedaje majątek firmy
  - (b) Były JDG z długami 200k PLN → upadłość konsumencka → plan spłaty + oddłużenie
- **Zależności:** Po P1176 `entrepreneur_personal_liability_jdg`. W nowym pakiecie `jdg.insolvency`.
- **Thresholds:** brak
- **Przykład +:** JDG active, niewypłacalny → upadłość przedsiębiorcy → syndyk

---

### P1751 🆕 `restructuring_simplified_approval_jdg`

- **Cel biznesowy:** Procedura restrukturyzacji — postępowanie o zatwierdzenie układu. Wstrzymanie egzekucji ZUS i US (zamrożenie biegu przedawnienia P1175) na czas otwartego postępowania w Monitorze Sądowym i Gospodarczym (KRZ).
- **Przesłanki:**
  - `input.jdg_entrepreneur.restructuring_procedure_open == true`
  - `input.jdg_entrepreneur.restructuring_published_in_krz == true` (obwieszczenie w KRZ/MSiG)
- **Rezultat:**
  - `statute_of_limitations_suspended: true` (bieg przedawnienia zawieszony)
  - `enforcement_proceedings_stayed: true` (egzekucja wstrzymana)
  - `tax_arrears_included_in_arrangement: true` (jeśli US wyrazi zgodę)
  - `_warning: "Postępowanie restrukturyzacyjne otwarte — egzekucja wstrzymana, przedawnienie zawieszone."`
- **Podstawa prawna:** Prawo restrukturyzacyjne, Art. 70 § 6 Ordynacji podatkowej (zawieszenie przedawnienia)
- **Zależności:** Wpływa na P1175 `tax_statute_of_limitations_5y_detailed_jdg` i P1177 `late_payment_interest_calculation_jdg`.
- **Thresholds:** brak
- **Przykład +:** Postępowanie otwarte 01.06 → przedawnienie zawieszone, egzekucja wstrzymana

---

# CZĘŚĆ 7: PRAWO PRACY JDG JAKO PRACODAWCY 🆕

---

### P1760 🆕 `hr_pfron_mandatory_contributions_jdg` 🚨⚖️

- **Cel biznesowy:** Obowiązkowe wpłaty na PFRON dla JDG zatrudniających ≥25 pracowników (FTE), którzy nie osiągają wskaźnika 6% zatrudnienia osób niepełnosprawnych. **UWAGA: wpłaty na PFRON NIE są KUP.**
- **Przesłanki:**
  - `input.jdg_entrepreneur.employees_fte_count >= 25`
  - `input.jdg_entrepreneur.disabled_employees_percent < 6.0`
  - `input.jdg_entrepreneur.pfron_payment_status == "UNPAID"`
- **Obliczenie wpłaty:**
  - `brakujacy_wskaznik = 6.0 - disabled_employees_percent`
  - `miesieczna_wplata = (brakujacy_wskaznik / 100) * employees_fte_count * przecietne_wynagrodzenie`
- **Rezultat:**
  - `pfron_payment_required: true`
  - `pfron_monthly_amount: <kwota>`
  - `pfron_not_deductible_kup: true` ← KLUCZOWE
  - `_warning: "Wpłata na PFRON X PLN — NIE jest kosztem uzyskania przychodu!"`
- **Podstawa prawna:** Art. 21 ustawy o rehabilitacji zawodowej i zatrudnianiu osób niepełnosprawnych (Dz.U. 2025 poz. 456)
- **Edge cases:**
  - (a) Status pracodawcy o szczególnym charakterze (ZPChr) → zwolnienie z wpłat
  - (b) Zakup usług od ZPChr → pomniejsza wpłatę na PFRON
- **Zależności:** W pakiecie `jdg.employer`. Po P1205 `employer_zus_obligations`.
- **Thresholds:** `jdg.hr.pfron_threshold_employees` (25), `jdg.hr.pfron_threshold_percent` (6.0)
- **Przykład +:** JDG z 30 pracownikami, 2 niepełnosprawnych (6.67%) → wskaźnik ≥ 6% → brak wpłaty
- **Przykład −:** JDG z 30 pracownikami, 0 niepełnosprawnych → brakujący wskaźnik 6% → wpłata miesięczna ~15 000 PLN

---

### P1761 🆕 `hr_foreign_worker_a1_cert_jdg`

- **Cel biznesowy:** Automatyczna walidacja certyfikatu A1 przy delegowaniu pracownika z polskiej JDG do pracy w UE. Brak certyfikatu A1 = ryzyko podlegania ZUS w kraju wykonywania pracy + kary.
- **Przesłanki:**
  - `input.jdg_entrepreneur.delegating_employee_abroad == true`
  - `input.invoice.employee_delegation_country` w krajach UE/EFTA
  - `input.invoice.employee_a1_certificate_valid == false`
  - `input.invoice.delegation_days > 0`
- **Rezultat:**
  - `a1_certificate_required: true`
  - `zus_liability_in_work_country_risk: true`
  - `potential_penalty: <wg prawa kraju docelowego>`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Delegowanie pracownika do UE bez certyfikatu A1 — ryzyko podlegania ZUS w kraju docelowym! Złóż wniosek A1 do ZUS."`
- **Podstawa prawna:** Rozporządzenie Parlamentu Europejskiego i Rady (WE) nr 883/2004, Art. 12 — delegowanie
- **Edge cases:**
  - (a) Delegowanie na 2 dni → A1 nadal wymagane
  - (b) Praca zdalna z zagranicy (digital nomad) → NIE jest delegowaniem → inne zasady
  - (c) Wielokrotne delegowanie do różnych krajów → osobny A1 dla każdego kraju
- **Zależności:** W pakiecie `jdg.employer`. Po P1202e `payroll_tax_advance_obligation`.
- **Thresholds:** brak
- **Przykład +:** Pracownik JDG wysłany na projekt do Niemiec na 2 tygodnie, brak A1 → BLOCK

---

# CZĘŚĆ 8: OCHRONA ŚRODOWISKA — SUP I CBAM 🆕

---

### P1770 🆕 `environment_sup_plastic_fee_jdg` ⚖️

- **Cel biznesowy:** Obowiązek pobrania i odprowadzenia opłaty SUP (Single-Use Plastics) od klientów dla JDG działających w gastronomii/handlu. Opłata doliczana do paragonu jako osobna pozycja. Opłata zwiększa podstawę VAT.
- **Przesłanki:**
  - `input.jdg_entrepreneur.pkd_main` w `["56.10.A", "56.30.Z", "47.11.Z", "47.81.Z"]` (gastronomia, handel spożywczy)
  - `input.invoice.sup_plastic_items_sold > 0` (kubki plastikowe, pojemniki na żywność)
  - `input.invoice.sup_fee_collected == false`
- **Stawki opłat SUP (2026):**

| Produkt | Stawka za sztukę |
|:---|---:|
| Kubek na napoje (plastikowy) | 0.25 PLN |
| Pojemnik na żywność (plastikowy) | 0.25 PLN |
| Lekka torba na zakupy | 0.25 PLN |

- **Rezultat:**
  - `sup_fee_amount: <liczba × stawka>`
  - `sup_fee_included_in_vat_base: true` (opłata zwiększa podstawę VAT)
  - `sup_fee_quarterly_report_required: true`
  - `_warning: "Sprzedałeś X opakowań SUP — pobierz opłatę Y PLN i odprowadź do US kwartalnie."`
- **Podstawa prawna:** Ustawa z dnia 14 kwietnia 2023 r. o zmianie ustawy o obowiązkach przedsiębiorców w zakresie gospodarowania niektórymi odpadami oraz o opłacie produktowej (Dz.U. 2023 poz. 877), Dyrektywa SUP 2019/904 **[TODO: potrzebne źródło – dodać do DocsJDG]**
- **Edge cases:**
  - (a) Opakowania biodegradowalne → NIE podlegają opłacie SUP
  - (b) Sprzedaż na wynos → podlega (klient końcowy)
  - (c) Sprzedaż hurtowa B2B → NIE podlega
- **Zależności:** W pakiecie `jdg.environmental`. Po P1400 `bdo_registration_check`.
- **Thresholds:** `jdg.environmental.sup_fee_rates` (mapa produkt→stawka)
- **Przykład +:** Kawiarnia JDG, sprzedaż 100 kubków plastikowych → opłata SUP 25 PLN, podstawa VAT powiększona o 25 PLN
- **Przykład −:** Sprzedaż w szklanych kubkach → brak opłaty SUP

---

### P1771 🆕 `environment_cbam_importer_reporting_jdg` ⚖️

- **Cel biznesowy:** Obowiązek raportowania CBAM (Carbon Border Adjustment Mechanism) dla JDG importujących towary wysokoemisyjne (stal, cement, nawozy, aluminium, energia elektryczna). Raport kwartalny z emisją wbudowaną.
- **Przesłanki:**
  - `input.invoice.procedure == "IMPORT"`
  - `input.invoice.cn_code` w katalogu towarów CBAM (załącznik I do Rozporządzenia CBAM)
  - `input.invoice.cbam_report_submitted == false`
- **Katalog towarów CBAM:**

| Kod CN | Opis | Uwagi |
|:---|---:|:---|
| 2523 | Cement | Każdy import |
| 72xx | Żelazo i stal | Z wyjątkiem niektórych kodów |
| 76xx | Aluminium | Każdy import |
| 3102-3105 | Nawozy | Każdy import |
| 2716 | Energia elektryczna | Import spoza UE |

- **Rezultat:**
  - `cbam_report_required: true`
  - `cbam_report_deadline: "kwartalnie_do_30_dni_po_kwartale"`
  - `cbam_emission_data_required_from_supplier: true`
  - `_warning: "Import towarów CBAM — obowiązek raportowania kwartalnego. Uzyskaj dane emisyjne od dostawcy."`
- **Podstawa prawna:** Rozporządzenie UE 2023/956 (CBAM), Rozporządzenie wykonawcze 2023/1773 **[TODO: potrzebne źródło – dodać do DocsJDG]**
- **Edge cases:**
  - (a) Import z Chin stali → obowiązek CBAM od 01.10.2023 (okres przejściowy do 31.12.2025, od 2026 pełne opłaty)
  - (b) Import małych ilości (de minimis 150 EUR) → zwolnienie z raportowania
  - (c) Import z kraju z własnym systemem ETS (np. Szwajcaria) → dostosowanie opłaty
- **Zależności:** W pakiecie `jdg.environmental`. Po P45 `import_non_eu`.
- **Thresholds:** `jdg.environmental.cbam_cn_codes` (lista), `jdg.environmental.cbam_de_minimis_eur` (150)
- **Przykład +:** JDG importuje stal z Chin, wartość 50 000 PLN → obowiązek CBAM
- **Przykład −:** Import stali z Niemiec (UE) → brak CBAM (wewnątrzunijny)

---

# CZĘŚĆ 9: CYFRYZACJA — E-DORĘCZENIA 🆕

---

### P1780 🆕 `digital_e_delivery_mandate_jdg` ⚖️🚨

- **Cel biznesowy:** Obowiązek posiadania adresu do doręczeń elektronicznych (e-Doręczenia) i rejestracji w Bazie Adresów Elektronicznych (BAE). Brak rejestracji = fikcja doręczenia pism z US i ZUS — pismo uznaje się za doręczone po 14 dniach mimo braku odbioru!
- **Przesłanki:**
  - `input.jdg_entrepreneur.e_delivery_registered == false`
  - `input.jdg_entrepreneur.e_delivery_mandatory_from` <= data bieżąca (obowiązek od określonej daty dla danego typu podmiotu)
  - `input.jdg_entrepreneur.business_status == "ACTIVE"` (tylko aktywne JDG)
- **Harmonogram obowiązku e-Doręczeń:**
  - Od 10.12.2023: JDG rejestrujące się w CEIDG (NOWE)
  - Od 01.01.2025: Wszystkie JDG aktywne (z wyjątkiem mikro-przedsiębiorców)
  - Od 01.10.2026: Mikro-przedsiębiorcy (włączeni w ostatniej fazie — [TODO: potwierdzić datę])
- **Rezultat:**
  - `e_delivery_mandatory: true`
  - `fiction_of_delivery_risk: true` (pisma z US uznane za doręczone mimo braku odbioru!)
  - `e_delivery_registration_deadline_passed: true/false`
  - `_routing: "BLOCK_AND_ALERT"` (jeśli termin minął)
  - `_warning: "BRAK ADRESU E-DORĘCZEŃ! Pisma z US i ZUS uznawane za doręczone automatycznie. Zarejestruj się w BAE NATYCHMIAST."`
- **Podstawa prawna:** Ustawa z dnia 18 listopada 2020 r. o doręczeniach elektronicznych (Dz.U. 2020 poz. 2320 ze zm.)
- **Edge cases:**
  - (a) JDG zarejestrowana w BAE, ale nie odebrała pisma → pismo uznane za doręczone po 14 dniach
  - (b) JDG niezarejestrowana, ale US wysyła tradycyjnie → przejściowo nadal skuteczne
  - (c) Sankcja: decyzja US może być uznana za ostateczną bez możliwości odwołania (brak odbioru = brak odwołania w terminie)
- **Zależności:** Wpływa na P1175 `tax_statute_of_limitations_5y_detailed_jdg` (doręczenie decyzji wpływa na bieg przedawnienia) i P1177 `late_payment_interest_calculation_jdg` (data doręczenia decyzji = data wszczęcia egzekucji).
- **Thresholds:** `jdg.digital.e_delivery_mandatory_dates_by_entity_type` (mapa typ→data)
- **`[TODO: potrzebne źródło – dodać do DocsJDG]`** — Ustawa z dnia 18 listopada 2020 r. o doręczeniach elektronicznych (Dz.U. 2020 poz. 2320 ze zm.) NIE jest obecnie w `DocsJDG`. Należy dodać.
- **`[TODO: potrzebne źródło]`** — potwierdzenie ostatecznej daty dla mikro-przedsiębiorców
- **Przykład +:** JDG aktywna od 2024, brak BAE → od 01.01.2025 obowiązek → BLOCK
- **Przykład −:** JDG zarejestrowana w BAE → OK

---

# CZĘŚĆ 10: BEZPIECZEŃSTWO I RODO 🆕

---

### P1790 🆕 `security_ksef_token_rotation_enforcement_jdg` 🚨

- **Cel biznesowy:** Wymuszenie regularnej rotacji tokenów KSeF dla JDG i ich pełnomocników. Token niewymieniany przez >90 dni stanowi ryzyko bezpieczeństwa i może być podstawą do odrzucenia faktur przez KSeF.
- **Przesłanki:**
  - `input.jdg_entrepreneur.ksef_token_age_days > input.thresholds.jdg.security.ksef_token_max_age_days`
  - `input.jdg_entrepreneur.is_vat_payer == true`
  - `input.invoice.direction == "SALE"`
- **Rezultat:**
  - `ksef_token_expired_or_stale: true`
  - `ksef_invoice_blocked: true` (faktury nie mogą być wysłane)
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Token KSeF niewymieniany od X dni — wygeneruj nowy token przed wysyłką faktur. Ryzyko odrzucenia przez KSeF."`
- **Podstawa prawna:** Specyfikacja techniczna KSeF v3.0, Polityka bezpieczeństwa MF dla KSeF
- **Edge cases:**
  - (a) Token wygenerowany przez biuro rachunkowe → JDG musi koordynować rotację z biurem
  - (b) Token utracony/skompromitowany → natychmiastowe unieważnienie przez e-US
- **Zależności:** Przed P950 `ksef_structured_mandatory_jdg`. W nowym pakiecie `jdg.security`.
- **Thresholds:** `jdg.security.ksef_token_max_age_days` (90)
- **Przykład +:** Token 95 dni → BLOCK faktur KSeF do czasu wymiany

---

### P1791 🆕 `security_gdpr_dpa_vendor_check_jdg`

- **Cel biznesowy:** Wymóg posiadania podpisanej Umowy Powierzenia Przetwarzania Danych (DPA) z biurem rachunkowym/dostawcą API przed przesłaniem faktur zawierających dane osobowe kontrahentów. Brak DPA = naruszenie RODO.
- **Przesłanki:**
  - `input.jdg_entrepreneur.uses_external_accounting == true` (biuro rachunkowe zewnętrzne)
  - `input.jdg_entrepreneur.dpa_signed_with_accounting == false`
  - `input.invoice.has_personal_data == true` (faktura zawiera dane osobowe kontrahenta)
- **Rezultat:**
  - `dpa_required: true`
  - `data_transfer_blocked: true`
  - `gdpr_violation_risk: true` (potencjalna kara do 20 000 000 EUR lub 4% obrotu)
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Brak Umowy Powierzenia Przetwarzania z biurem rachunkowym! Nie przesyłaj faktur z danymi osobowymi. Ryzyko kary RODO."`
- **Podstawa prawna:** Art. 28 RODO (RODO — Rozporządzenie UE 2016/679)
- **Edge cases:**
  - (a) Biuro rachunkowe jako współadministrator (a nie procesor) → potrzebna inna umowa
  - (b) Przesyłanie danych przez API (auto-księgowanie) → DPA musi obejmować transfer automatyczny
  - (c) Dane zaszyfrowane end-to-end → nadal wymagana DPA (klucz ma biuro)
- **Zależności:** W pakiecie `jdg.security`. Przed regułami KSeF (P950+).
- **Thresholds:** brak (reguła binarna)
- **Przykład +:** JDG wysyła faktury do biura rachunkowego przez API, brak DPA → BLOCK
- **Przykład −:** JDG samodzielnie księguje → brak wymogu DPA

---

### P1792 🆕 `ksef_emergency_offline_batch_sync_jdg` 🚨

- **Cel biznesowy:** Zaawansowana procedura awaryjna podczas ogłoszonej przez MF awarii KSeF. Reguluje dozwolony czas synchronizacji faktur offline i blokuje podwójne odliczenia VAT pomiędzy okresem awarii a powrotem online.
- **Przesłanki:**
  - `input.system.ksef_offline_mode_active == true` (MF ogłosiło awarię KSeF)
  - `input.invoice.issued_during_ksef_outage == true`
  - `input.invoice.direction == "SALE"`
- **Procedura awaryjna:**
  - Krok 1: Wystaw fakturę w formacie KSeF XML (offline)
  - Krok 2: Wyślij fakturę do KSeF w ciągu 7 dni od zakończenia awarii
  - Krok 3: Po wysyłce — faktura otrzymuje UPO i timestamp z datą wysyłki
  - Krok 4: Data obowiązku VAT = data wystawienia (offline), nie data wysyłki do KSeF
- **Rezultat:**
  - `ksef_offline_invoice_allowed: true`
  - `ksef_offline_sync_deadline: <data_zakonczenia_awarii + 7_dni>`
  - `ksef_offline_sync_overdue: true` (jeśli przekroczono 7 dni)
  - `vat_deduction_duplicate_protection: true` (zapobiega podwójnemu odliczeniu)
  - `_warning: "Awaria KSeF — faktury offline dozwolone. Wyślij do KSeF w ciągu 7 dni od zakończenia awarii."`
- **Podstawa prawna:** Ustawa z dnia 16 czerwca 2023 r. o zmianie ustawy o VAT (wprowadzająca KSeF), Art. 106na-106nq VAT, Komunikat MF w sprawie procedury awaryjnej
- **Edge cases:**
  - (a) Awaria trwa 3 dni → 7 dni na synchronizację po zakończeniu = 10 dni łącznie
  - (b) Podwójne odliczenie VAT: raz z faktury offline, raz z UPO → system musi wykryć i zablokować
  - (c) Faktura offline wystawiona 30.06, awaria kończy się 02.07, KSeF wysyłka 08.07 → obowiązek VAT za czerwiec (data wystawienia)
- **Zależności:** Po P950 `ksef_structured_mandatory_jdg` i P960 `ksef_offline_recovery`. Ta reguła jest bardziej szczegółowa.
- **Thresholds:** `jdg.ksef.offline_sync_days` (7)
- **Przykład +:** Awaria KSeF 01-03.07, faktura 02.07 offline → sync deadline 10.07, obowiązek VAT za lipiec
- **Przykład −:** Przekroczono 7 dni na synchronizację → faktura offline traci ważność, należy wystawić nową

---

# CZĘŚĆ 11: STRUKTURA INPUT — NOWE POLA DLA NOWYCH REGUŁ
> ⚠️ **Te pola są ROZSZERZENIEM istniejącej specyfikacji `input` z Doc 22 §2.1 / `00_PLAN_STRUKTURA.md` §2.1.** Pola podstawowe (`invoice.*`, `vendor.*`, `company.*`, `confidence.*`, `thresholds.*`) pozostają bez zmian.

Poniższe pola muszą być dodane do specyfikacji `input` dla obsługi 20 nowych reguł:

```json
{
  "jdg_entrepreneur": {
    "crypto_activity_regular": false,
    "foreign_company_shares_percent": 0,
    "foreign_company_country": "PL",
    "foreign_company_passive_income_ratio": 0,
    "foreign_company_annual_income_pln": 0,
    "unrealized_gains": 0,
    "tax_residency_changing_to": "PL",
    "assets_transferred_abroad_value": 0,
    "is_insolvent": false,
    "restructuring_procedure_open": false,
    "restructuring_published_in_krz": false,
    "employees_fte_count": 0,
    "disabled_employees_percent": 0,
    "pfron_payment_status": "UNPAID",
    "delegating_employee_abroad": false,
    "workers_count": 0,
    "whistleblower_procedure_implemented": false,
    "aml_procedure_implemented": false,
    "e_delivery_registered": false,
    "e_delivery_mandatory_from": "2026-01-01",
    "ksef_token_age_days": 0,
    "uses_external_accounting": false,
    "dpa_signed_with_accounting": false,
    "business_model": "",
    "crypto_activity_regular": false,
    "uses_cash_method_pit": false,
    "sup_plastic_items_sold": 0,
    "sup_fee_collected": false,
    "cbam_report_submitted": false,
    "driver_days_abroad": 0
  },
  "invoice": {
    "nft_category": "",
    "crypto_income_type": "",
    "has_personal_data": false,
    "procedure_code": "",
    "sup_plastic_items_sold": 0,
    "cn_code": "",
    "employee_delegation_country": "",
    "employee_a1_certificate_valid": false,
    "delegation_days": 0,
    "issued_during_ksef_outage": false
  },
  "system": {
    "ksef_offline_mode_active": false,
    "ksef_outage_end_date": null
  }
}
```

---

# CZĘŚĆ 12: NOWE THRESHOLDS

| Klucz | Wartość | Jednostka | Podstawa prawna |
|-------|---------|-----------|-----------------|
| `jdg.crypto.nft_vat_rates.*` | mapowanie | — | Art. 7-8 VAT |
| `jdg.crypto.defi_income_categories.*` | mapowanie | — | Art. 10, 17, 18, 20 PIT |
| `jdg.transport.driver_diet_rates_by_country.*` | mapa stawek | EUR/dzień | Rozp. MPiPS |
| `jdg.healthcare.aesthetic_procedure_codes` | lista ICD | — | Art. 43 VAT |
| `jdg.compliance.whistleblower_threshold` | 50 | osoby | Ustawa o sygnalistach |
| `jdg.compliance.aml_obligated_pkd` | lista PKD | — | Ustawa AML |
| `jdg.international.cfc_ownership_threshold` | 50 | % | Art. 30f PIT |
| `jdg.international.cfc_effective_tax_threshold` | 0.1425 | ratio | Art. 30f PIT |
| `jdg.international.cfc_de_minimis` | 250000 | PLN | Art. 30f PIT |
| `jdg.international.exit_tax_threshold` | 4000000 | PLN | Art. 30da PIT |
| `jdg.international.exit_tax_rate` | 0.19 | ratio | Art. 30da PIT |
| `jdg.international.exit_tax_installment_rate` | 0.03 | ratio | Art. 30da PIT |
| `jdg.hr.pfron_threshold_employees` | 25 | osoby | Art. 21 Ust. rehab. |
| `jdg.hr.pfron_threshold_percent` | 6.0 | % | Art. 21 Ust. rehab. |
| `jdg.environmental.sup_fee_rates.*` | mapowanie | PLN/szt. | Ustawa SUP |
| `jdg.environmental.cbam_cn_codes` | lista | — | Rozp. CBAM |
| `jdg.environmental.cbam_de_minimis_eur` | 150 | EUR | Rozp. CBAM |
| `jdg.digital.e_delivery_mandatory_dates_by_entity_type.*` | mapa dat | — | Ustawa e-Doręczenia |
| `jdg.security.ksef_token_max_age_days` | 90 | dni | Polityka MF |
| `jdg.ksef.offline_sync_days` | 7 | dni | Ustawa KSeF |

---

# CZĘŚĆ 13: HIERARCHIA PRIORYTETÓW — NOWY ŁAŃCUCH

> ⚠️ **Numery bloków (BLOK 0-25) są zgodne z łańcuchem first-match-wins z `28_JDG_ENTERPRISE_MASTER_SYNTHESIS.md` Część I.** Nowe reguły włączane są w istniejący łańcuch w następujących miejscach:

```
═══ PRZED BLOKIEM 0 (RISK): ═══
P1790 ──► ksef_token_expired             Przed wysyłką do KSeF
P1791 ──► gdpr_dpa_vendor_check           Przed przesłaniem danych
P1780 ──► e_delivery_mandate              Blokada przy braku BAE

═══ BLOK 0 (RISK) ROZSZERZONY: ═══
P1700 ──► crypto_nft_classification       Klasyfikacja NFT przed VAT
P1701 ──► crypto_defi_staking_pit         Klasyfikacja DeFi przed PIT
P1740 ──► cfc_detection                   Wykrycie CFC przed PIT
P1741 ──► exit_tax_detection              Wykrycie exit tax

═══ BLOK 2 (COMPLIANCE) ROZSZERZONY: ═══
P1730 ──► whistleblower_procedure         Po regułach WL
P1731 ──► aml_kyc_obligation              Po AML

═══ BLOK 3 (CROSSBORDER) ROZSZERZONY: ═══
P1771 ──► cbam_importer_reporting         Po imporcie spoza UE

═══ BLOK 5-6 (VAT) ROZSZERZONY: ═══
P1711 ──► dropshipping_classification     Przed stawkami VAT
P1712 ──► healthcare_aesthetic_vat        Po P56 (zwolnienia medyczne)
P1792 ──► ksef_offline_batch_sync         Po P950 (KSeF)

═══ BLOK 13 (ZUS) ROZSZERZONY: ═══
P1710 ──► mobility_package_deduction      Przed obliczeniem podstawy ZUS
P1760 ──► pfron_contributions             Po P1205 (ZUS pracodawcy)
P1761 ──► a1_certificate_check            Przed delegowaniem

═══ BLOK 16 (PRZEDAWNIENIA) ROZSZERZONY: ═══
P1725 ──► cascade_cash_method             Między VAT a PIT
P1750 ──► bankruptcy_classification       Przed przedawnieniem
P1751 ──► restructuring_stay              Wpływa na przedawnienie

═══ BLOK 18 (PRACODAWCA) ROZSZERZONY: ═══
P1760 ──► pfron_contributions             W pakiecie employer
P1761 ──► a1_certificate_check            W pakiecie employer

═══ BLOK 21 (ŚRODOWISKO) ROZSZERZONY: ═══
P1770 ──► sup_plastic_fee                 W pakiecie environmental
P1771 ──► cbam_importer_reporting         W pakiecie environmental
```

---

# CZĘŚĆ 14: PODSUMOWANIE KOŃCOWE

## 14.1 Statystyki

| Metryka | Wartość |
|---------|:-------:|
| **Nowe obszary ENTERPRISE** | **10** |
| **Nowe reguły (🆕)** | **20** |
| **Nowe pakiety .rego** | **12** |
| **Nowe pola input** | **~35** |
| **Nowe thresholds** | **~20** |
| **[TODO: potrzebne źródło]** | **4** |

## 14.2 Priorytety wdrożenia

| Priorytet | Reguły | Czas wdrożenia |
|:---------:|--------|:--------------:|
| **P0** (KRYTYCZNE) | P1730, P1731, P1780, P1790, P1791 | 1 tydzień |
| **P1** (WYSOKI) | P1700, P1701, P1740, P1741, P1792 | 2 tygodnie |
| **P2** (ŚREDNI) | P1710, P1711, P1712, P1725, P1750, P1751 | 3 tygodnie |
| **P3** (NORMALNY) | P1760, P1761, P1770, P1771 | 2 tygodnie |

---

> **🔥 WNIOSEK KOŃCOWY:** Ten dokument ujawnia **20 całkowicie nowych reguł** w 10 zaawansowanych obszarach ENTERPRISE, które nie zostały pokryte w żadnym z 39 istniejących dokumentów planu JDG. Są to obszary, które stają się obowiązkowe w 2026 roku (CBAM, SUP, e-Doręczenia, sygnaliści) lub reprezentują najwyższy poziom zaawansowania podatkowego (CFC, Exit Tax, DeFi, NFT). Łącznie z 294 regułami kanonicznymi i ~140 regułami rozbudowy, system NexusAI JDG osiąga **~454 reguł** — poziom ENTERPRISE gotowy na wyzwania 2026+.
>
> **Następny krok:** Implementacja 12 nowych plików `.rego` dla pakietów crypto, specialized, cascade, insolvency, i security. Rozpocząć od P0: P1730 (sygnaliści), P1780 (e-Doręczenia), P1790 (KSeF token).

---

*Wygenerowano przez NexusAI Deep Gap Analysis Engine ENTERPRISE v1.0*  
*Data: 2026-07-12*  
*Bazuje na: głębokiej analizie braków (thinker-gemini), 38c_JDG_CANONICAL_MAP.md, DocsJDG*  
*Zgodność prawna: stan na 2026 r.*  
*Łącznie reguł po tej analizie: ~454 (294 kanoniczne + ~140 rozbudowa + 20 final frontier)*
