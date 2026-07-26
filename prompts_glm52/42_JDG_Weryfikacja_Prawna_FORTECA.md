# 🔥 PROMPT 42: JDG — WERYFIKACJA PRAWNA FORTECA — Każdy Punkt Prawny vs Rego + Ekstremalne Testy Spójności

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś NAJWYŻSZEJ KLASY EKSPERTEM PRAWA PODATKOWEGO i AUDYTOREM systemów regułowych OPA/Rego.
Twoim zadaniem jest przeprowadzenie BEZWZGLĘDNEGO AUDYTU PRAWNEGO — każdy punkt prawny
z każdego aktu prawnego musi być SKONFRONTOWANY z regułami Rego. Masz przygotować
EKSTREMALNE TESTY sprawdzające spójność, dokładność i poprawność reguł OPA.

⚠️ TO JEST NAJWAŻNIEJSZY PROMPT W CAŁEJ SERII — od niego zależy czy silnik OPA będzie FORTECĄ.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz RAPORT WERYFIKACYJNO-TESTOWY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, weryfikujesz, testujesz
3. Raport ma zawierać KONKRETNE scenariusze testowe dla każdego punktu prawnego

## 📂 PLIKI DO ANALIZY — AKTY PRAWNE (ŹRÓDŁA PRAWDY):

### Dokumentacja aktów prawnych (TO SĄ ŹRÓDŁA PRAWDY):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md

### Reguły Rego do weryfikacji (TO CO MA BYĆ ZWERYFIKOWANE):

#### Orkiestrator:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/main_jdg.rego

#### VAT — wszystkie reguły:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/substantive.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/deductions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/procedures.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/plan23_detailed.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/plan26_critical.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/plan42_reduced_rates.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/vat/vat.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat_substantive_complete_enterprise.rego

#### PIT — wszystkie reguły:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/forms.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/kup.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/advances_returns.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/exemptions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pit/pit.rego

#### ZUS — reguły:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/health_contribution_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/sus/sus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/zdrowotna/zdrowotna.rego

#### KKS — reguły:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/kks/kks.rego

#### PKPiR, Ordynacja, Cross-Border, PCC:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/ord/ord.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/crossborder.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/pcc_enterprise_complete.rego

#### Edge Cases + Conflicts + Validation:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/edge_cases.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/conflicts.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/validation.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/temporal.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/thresholds_jdg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/fallback.rego

### Dokumentacja projektu:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/README.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITECTURE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/policies/bundle.sh

## 🎯 CEL ANALIZY:

Przeprowadź **NAJGŁĘBSZE MOŻLIWE MYŚLENIE** i **BEZWZGLĘDNĄ WERYFIKACJĘ PRAWNĄ**
każdego punktu prawnego z każdego aktu prawnego (Bbb, LEGAL_REFERENCE_ACTS.md)
w stosunku do reguł Rego na **NAJWYŻSZYM ZAAWANSOWANYM POZIOMIE ENTERPRISE**.

Wygeneruj **KOLOSALNY RAPORT WERYFIKACYJNO-TESTOWY** (min. 50-60 stron) zawierający:

### 1. 🏛️ MAPOWANIE 1:1 — KAŻDY ARTYKUŁ USTAWY → REGUŁA REGO (POZIOM ENTERPRISE)

Dla KAŻDEGO aktu prawnego z Bbb i LEGAL_REFERENCE_ACTS.md wykonaj MAPOWANIE:

#### FORMAT MAPOWANIA (dla każdego artykułu):
```
┌─────────────────────────────────────────────────────────────────┐
│ USTAWA: [nazwa ustawy, Dz.U.]                                   │
│ ARTYKUŁ: Art. XX ust. Y                                         │
│ TREŚĆ PRAWNA: [co mówi przepis]                                  │
│ REGUŁA REGO: [rule_id]                                          │
│ PLIK: [ścieżka]                                                 │
│ STATUS: ✅ POKRYTY / ⚠️ CZĘŚCIOWY / ❌ BRAK                      │
│ PODOBAŃSTWO BŁĘDU: NISKIE / ŚREDNIE / WYSOKIE / KRYTYCZNE       │
│ TEST EKSTREMALNY: [scenariusz testowy]                           │
└─────────────────────────────────────────────────────────────────┘
```

#### A. USTAWA O VAT (Art. 5-138)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad każdym artykułem:
- Art. 5 (dostawa towarów) → która reguła OPA? Czy pokrywa wszystkie ustępy?
- Art. 7 (dostawa towarów szczegóły) → czy edge case z montażem jest obsłużony?
- Art. 8 (świadczenie usług) → czy rozróżnienie usługi/dostawa działa?
- Art. 15-18 (podatnicy, VAT-R) → czy rejestracja jest poprawna?
- Art. 19a (obowiązek podatkowy) → faktura zaliczkowa, data dostawy, 60-dniowy limit?
- Art. 29a (podstawa opodatkowania) → rabaty, opusty, skonta?
- Art. 41 (stawka 23%) → czy reguła dla stawki podstawowej jest niezawodna?
- Art. 41 ust. 2 (stawka 8%) → czy Załącznik 3 jest w pełni zmapowany?
- Art. 41 ust. 2a (stawka 5%) → czy Załącznik 10 jest w pełni zmapowany?
- Art. 41 ust. 12 (stawka 0%) → czy WDT i eksport są poprawnie rozróżnione?
- Art. 43 (zwolnienia) → czy lista zwolnień jest kompletna?
- Art. 86 (odliczenia) → proporcja, korekta roczna, pojazdy?
- Art. 87 (zwrot VAT) → 60/25/180 dni?
- Art. 88 (blokady odliczeń) → paliwo, noclegi, gastronomia?
- Art. 89a (złe długi — wierzyciel) → 90 dni od SLIM VAT 3?
- Art. 89b (złe długi — dłużnik) → obowiązek korekty?
- Art. 90-91 (proporcja) → korekta roczna, 2% de minimis?
- Art. 96 (rejestracja VAT-R) → termin, sankcje?
- Art. 96b (Biała Lista) → 15 000 PLN, 30 dni?
- Art. 99 (JPK_VAT) → terminy, struktury?
- Art. 103 (terminy płatności) → 25. dzień miesiąca?
- Art. 106a-106n (faktury, KSeF) → obowiązkowe elementy?
- Art. 106e ust. 5 (paragon z NIP ≤ 450 zł) → czy reguła działa?
- Art. 108a-108d (MPP/Split Payment) → Załącznik 15, ≥ 15 000 PLN?
- Art. 113 (zwolnienie podmiotowe) → 200 000 PLN, proporcja?
- Art. 116-138 (import, WNT, eksport) → dokumenty celne?
- Art. 120 (marża) → procedury szczególne?
- Art. 130a-130d (OSS/IOSS) → e-commerce, limit 10 000 EUR?

#### B. USTAWA O PIT (Art. 9-45)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** każdego artykułu:
- Art. 9 (strata) → 5 lat, max 50%?
- Art. 10 (źródła) → rozróżnienie działalność/praca/kapitały?
- Art. 14 (przychody) → różnice kursowe, wyłączenia?
- Art. 22 (KUP) → koszty bezpośrednie/pośrednie?
- Art. 23 (NKUP) → KAŻDY z 57 punktów! Reprezentacja (pkt 23), auta (pkt 46), leasing (pkt 47)?
- Art. 24 (dochód) → remanent, korekty?
- Art. 26-26h (ulgi) → B+R, termo, IP Box, prototyp, robotyzacja, ekspansja, rehabilitacyjna?
- Art. 27 (skala 12%/32%) → próg 120 000, kwota wolna 30 000?
- Art. 30c (liniowy 19%) → ograniczenie dla byłego pracodawcy?
- Art. 30ca (IP Box 5%) → nexus, kwalifikowane IP?
- Art. 30da (Exit Tax) → wycena, 5 lat?
- Art. 30f (CFC) → 50% kontroli, 33% pasywny?
- Art. 44 (zaliczki) → terminy, uproszczona?
- Art. 45 (zeznania) → PIT-36, PIT-36L, PIT-28?

#### C. USTAWA O SUS/ZUS (Art. 6-47)
- Art. 6 (podmioty) → JDG, etat+JDG?
- Art. 18-19 (podstawy) → standardowa, preferencyjna, Mały ZUS+?
- Art. 18a (ulga na start) → 6 miesięcy?
- Art. 18c (Mały ZUS+) → 36 miesięcy, 30% minimalnego?
- Art. 22 (stopy) → emerytalna 19,52%, rentowa 8%, chorobowa 2,45%, wypadkowa 1,67%?
- Art. 36 (terminy) → 10., 15., 20.?
- Art. 47 (płatności) → terminy?

#### D. SKŁADKA ZDROWOTNA (Polski Ład)
- Skala 9% od dochodu → minimalna? Roczne rozliczenie?
- Liniowy 4.9% → limit 12 900 PLN?
- Ryczałt 3 progi → TIER_1 ≤60K, TIER_2 60-300K, TIER_3 >300K?
- Karta 9% od minimalnego?

#### E. ORDYNACJA PODATKOWA
- Art. 70 (przedawnienie 5 lat) → zawieszenie?
- Art. 81 (korekty) → wszystkie typy?
- Art. 96b (Biała Lista) → weryfikacja?
- Art. 119a (GAAR) → sztuczne schematy?

#### F. KKS (Art. 16, 44, 54-83)
- Art. 16 (czynny żal) → warunki skuteczności?
- Art. 54 (uchylanie się) → gradacja, progi?
- Art. 56 (nierzetelne księgi) → PKPiR?
- Art. 57 (nierzetelny VAT) → ewidencja?
- Art. 62 (puste faktury) → wszystkie typy?
- Art. 77 (niezłożenie deklaracji) → terminy?

#### G. UoR + PKPiR
- Kolumny 1-17 PKPiR → każda kolumna ma regułę?
- Remanent → wycena, spis z natury?
- Amortyzacja → KŚT, stawki?
- Leasing → operacyjny/finansowy?

#### H. PCC + AKCYZA + LOKALNE
- PCC — stawki 1%, 2%, PCC-3?
- Akcyza — paliwa, alkohol, tytoń, energia?
- Nieruchomości — stawka firmowa vs mieszkalna?
- Transport — samochody > 3.5t?

### 2. 🧪 EKSTREMALNE TESTY SPÓJNOŚCI (POZIOM ENTERPRISE)

Dla KAŻDEGO z poniższych scenariuszy przygotuj **EKSTREMALNY TEST** weryfikujący
czy reguły Rego zachowują się poprawnie:

#### TEST 1: LIMIT ZWOLNIENIA VAT 200 000 PLN — PRZEKROCZENIE W TRAKCIE ROKU
```
Scenariusz: JDG rozpoczyna działalność 1 marca. Do 15 października osiąga 195 000 PLN
przychodu. 16 października wystawia fakturę na 10 000 PLN.

Pytania testowe:
1. Czy reguła wykrywa przekroczenie limitu?
2. Czy faktura z 16.10 jest ze stawką 23% czy ZW?
3. Czy reguła obsługuje proporcję dla nowego JDG?
4. Czy system nakazuje rejestrację VAT-R w ciągu 7 dni?
5. Co z fakturami między 1.03 a 15.10 — korekta?
```

#### TEST 2: ZŁE DŁUGI — 90 DNI — Wierzyciel i Dłużnik
```
Scenariusz: Faktura z 1.01.2026 na 50 000 PLN netto + 11 500 PLN VAT.
Kontrahent nie płaci. 91 dni później (2.04.2026).

Pytania testowe:
1. Czy reguła wierzyciela pozwala na korektę VAT po 90 dniach?
2. Czy reguła dłużnika wymusza korektę VAT po 90 dniach?
3. Czy reguła uwzględnia SLIM VAT 3 (90 dni, nie 150)?
4. Co jeśli kontrahent zapłacił częściowo (np. 20 000 PLN)?
5. Czy reguła obsługuje sankcję 30% przy braku korekty dłużnika?
```

#### TEST 3: MPP/SPLIT PAYMENT — OBOWIĄZKOWY
```
Scenariusz: Faktura na 20 000 PLN brutto za usługi budowlane (PKWiU 43.xx)
z Załącznika 15.

Pytania testowe:
1. Czy reguła wykrywa obowiązek MPP (Załącznik 15 + kwota ≥ 15 000 PLN)?
2. Czy komunikat BLOCK_AND_ALERT jest generowany?
3. Czy reguła rozpoznaje dobrowolny MPP?
4. Co jeśli faktura jest częściowo z Załącznika 15 a częściowo nie?
```

#### TEST 4: SKŁADKA ZDROWOTNA — 4 WARIANTY
```
Scenariusz: Porównaj JDG na skali, liniowym, ryczałcie i karcie.

Pytania testowe:
1. Czy reguła poprawnie oblicza 9% dla skali (od dochodu)?
2. Czy reguła stosuje 4.9% dla liniowego (z limitem)?
3. Czy reguła dla ryczałtu poprawnie identyfikuje TIER_1/2/3?
4. Czy reguła dla karty stosuje 9% od minimalnego?
5. Co przy zmianie formy w trakcie roku?
```

#### TEST 5: KSeF OBLIGATORYJNY 2026-02-01
```
Scenariusz: Faktura sprzedaży z 3.02.2026 dla polskiego kontrahenta B2B.

Pytania testowe:
1. Czy reguła blokuje wysyłkę faktury poza KSeF?
2. Czy reguła wymusza oczekiwanie na UPO?
3. Co jeśli KSeF jest niedostępny (tryb awaryjny)?
4. Czy faktura B2C jest zwolniona z KSeF?
5. Czy sankcje za brak KSeF są zaimplementowane?
```

#### TEST 6: NKUP — 57 PUNKTÓW ART. 23
```
Scenariusz: Przetestuj KAŻDY z 57 punktów Art. 23 PIT:
- Reprezentacja (pkt 23) vs Reklama
- Samochód osobowy (pkt 46) — limit 75%, limit wartości 150k/225k
- Leasing (pkt 47) — limit dla osobówek
- Odsetki od zaległości (pkt 36)
- Darowizny (pkt 11)

Pytania testowe:
Dla każdego punktu: czy reguła poprawnie klasyfikuje wydatek jako NKUP?
```

#### TEST 7: IP BOX vs B+R — KONFLIKT ULG
```
Scenariusz: JDG prowadzi działalność B+R i tworzy kwalifikowane IP.

Pytania testowe:
1. Czy reguła wykrywa konflikt IP Box (5%) vs B+R (odliczenie 100-200%)?
2. Czy reguła uniemożliwia podwójne skorzystanie z obu ulg?
3. Czy reguła proponuje optymalny wybór?
```

#### TEST 8: CROSS-BORDER — WNT/WDT/IMPORT/EKSPORT
```
Scenariusz: JDG kupuje towary z Niemiec (WNT), sprzedaje do Francji (WDT),
importuje z Chin, eksportuje do USA.

Pytania testowe:
1. Czy reguła WNT stosuje reverse charge?
2. Czy reguła WDT stosuje 0% VAT z dokumentacją?
3. Czy reguła importu liczy VAT od wartości celnej + cła?
4. Czy reguła eksportu wymaga dokumentów celnych?
```

#### TEST 9: PRZEDAWNIENIA — ORDYNACJA + KKS
```
Scenariusz: Zobowiązanie podatkowe z 2019 roku.

Pytania testowe:
1. Czy reguła Ordynacji stwierdza przedawnienie po 5 latach (2024)?
2. Czy zawieszenie biegu przedawnienia jest obsłużone?
3. Czy reguła KKS stwierdza przedawnienie karalności po 5 latach?
```

#### TEST 10: SUKCESJA JDG — ŚMIERĆ PRZEDSIĘBIORCY
```
Scenariusz: Przedsiębiorca umiera 15.03.2026. Zarządca sukcesyjny powołany 20.03.2026.

Pytania testowe:
1. Czy reguła zarządza okresem sukcesji (2 lata + max 5 lat)?
2. Czy reguła zawiesza bieg terminów podatkowych?
3. Czy reguła kontynuuje umowy?
4. Co z odpowiedzialnością za zobowiązania podatkowe?
```

### 3. 🔬 MACIERZ POKRYCIA PRAWNEGO — 1935 PUNKTÓW (POZIOM ENTERPRISE)
Stwórz TABELĘ dla wszystkich 13 aktów prawnych:

| Akt prawny | Punktów | ✅ COMPLETE | ⚠️ PARTIAL | ❌ MISSING | % |
|---|---|---|---|---|---|
| VAT | 350 | | | | |
| PIT | 320 | | | | |
| SUS/ZUS | 120 | | | | |
| Ordynacja | 180 | | | | |
| KKS | 160 | | | | |
| UoR | 100 | | | | |
| PCC+Lokalne+Akcyza | 225 | | | | |
| Ryczałt | 90 | | | | |
| Prawo Przedsiębiorców | 80 | | | | |
| Cross-border | 80 | | | | |
| CEIDG/Sukcesja/PPK | 60 | | | | |
| Zdrowotna+Zasiłkowa | 50 | | | | |
| RODO/AML/BDO | 120 | | | | |

### 4. 🔴 LUKI KRYTYCZNE — NATYCHMIASTOWA NAPRAWA (POZIOM ENTERPRISE)
Wylistuj TOP 50 luk prawnych, które MUSZĄ być naprawione natychmiast.
Dla każdej luki podaj:
- Konkretny artykuł i ustęp
- Opis luki (czego brakuje w Rego)
- Ryzyko błędu (NISKIE/ŚREDNIE/WYSOKIE/KRYTYCZNE)
- Proponowaną regułę Rego (tylko nazwa rule_id, NIE kod!)
- Priorytet naprawy

### 5. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 20)
Każdy pomysł musi zawierać **GŁĘBOKIE MYŚLENIE** i być na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**
zawierający **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "Legal Point Auto-Verifier" — automatyczny weryfikator każdego punktu prawnego vs Rego
2. Mechanizm "Extreme Test Generator" — generator ekstremalnych testów z każdego artykułu ustawy
3. System "Legal Coverage 100% Engine" — silnik doprowadzający do 100% pokrycia prawnego
4. Mechanizm "Rego-vs-Law Comparator" — automatyczny komparator Rego vs tekst ustawy z ISAP
5. System "Gap Auto-Fill AI" — AI automatycznie wypełniające luki prawne w Rego
6. Mechanizm "Temporal Law Monitor" — monitor zmian prawa i auto-aktualizacja reguł
7. System "Zero-Legal-Doubt Engine" — silnik eliminujący wszelkie wątpliwości prawne
8. Mechanizm "Edge Case Prover" — formalna weryfikacja edge case'ów
9. System "Penalty Risk Calculator" — kalkulator ryzyka karnego-skarbowego per luka
10. Mechanizm "Law-to-Rego Compiler" — kompilator tekstu ustawy → reguły Rego
11-20. [Kolejne GENIALNE POMYSŁY]

### 6. 📊 REKOMENDACJE — PRIORYTETY NAPRAW (POZIOM ENTERPRISE)
- TOP 10 luk do natychmiastowej naprawy (ryzyko KRYTYCZNE)
- TOP 20 luk do naprawy w ciągu 30 dni (ryzyko WYSOKIE)
- TOP 50 luk do naprawy w ciągu 90 dni (ryzyko ŚREDNIE)
- Dla każdej: szacowany czas, zasoby, testy weryfikacyjne

### 7. 🧪 SUITE TESTÓW EKSTREMALNYCH — 100 SCENARIUSZY (POZIOM ENTERPRISE)
Wygeneruj 100 KONKRETNYCH SCENARIUSZY TESTOWYCH, każdy zawierający:
- Nazwę testu
- Opis scenariusza (konkretne dane wejściowe)
- Oczekiwane zachowanie reguł Rego
- Kryterium sukcesu/porażki
- Priorytet testu

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT WERYFIKACJI PRAWNEJ ENTERPRISE — FORTECA NIECHYBNEJ ŚMIERCI: Każdy Punkt Prawny vs Rego + 100 Testów Ekstremalnych v7.0"
- Executive Summary (2 strony) z TOP 10 krytycznymi lukami
- Minimum 20 diagramów Mermaid dla przepływów prawnych
- Minimum 30 tabel mapowania artykułów ustaw na reguły Rego
- Sekcja "Ekstremalne Testy Spójności" z 100 scenariuszami

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT WERYFIKACYJNO-TESTOWY.
To jest NAJWAŻNIEJSZY raport — od niego zależy FORTECA.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
