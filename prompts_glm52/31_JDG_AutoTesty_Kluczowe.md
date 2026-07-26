# 🔥 PROMPT 31: JDG — Auto Test Blocki Enterprise (VAT, PIT, ZUS, KKS, Accounting, Business, Compliance, Conviction)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie automatycznego testowania reguł OPA/Rego,
auto-bloków testowych, fuzz testingu i strategii zapewnienia jakości Enterprise.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY (~25 plików Auto Testów):

### Auto Testy — VAT, PIT, ZUS, KKS:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_vat.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_vat_complete.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_pit.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_zus.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_kks.py

### Auto Testy — Księgowość, Biznes:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_accounting.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_pkpir_live.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_business.py

### Auto Testy — Compliance, Conviction, Crossborder:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_compliance.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_conviction.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_crossborder.py

### Auto Testy — Edge Cases, Environmental, Family:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_edge_cases.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_environmental.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_family.py

### Auto Testy — Pozostałe:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_ksef_jpk.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_ksef_resilience.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_liability.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_lifecycle.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_limitations.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_local.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_local_taxes.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_mdr.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_micro.py

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/README.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/TESTING.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** wszystkich auto test blocków
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 30-40 stron) zawierający:

### 1. 🔬 AUDYT AUTO TEST VAT — KOMPLETNOŚĆ (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad testami VAT:
- Czy testy pokrywają WSZYSTKIE stawki VAT (23%, 8%, 5%, 0%, ZW)?
- Czy MPP/Split Payment jest testowany?
- Czy KSeF mandatory jest testowany?
- Czy złe długi (90 dni) są testowane?
- Ile reguł VAT ma pokrycie testowe?

### 2. 🔬 AUDYT AUTO TEST PIT — KOMPLETNOŚĆ (POZIOM ENTERPRISE)
- Czy wszystkie formy PIT są testowane?
- Czy ulgi (B+R, IP Box, termo) mają testy?
- Czy NKUP 57 punktów jest testowanych?

### 3. 🔬 AUDYT AUTO TEST ZUS — KOMPLETNOŚĆ (POZIOM ENTERPRISE)
- Czy składka zdrowotna (4 warianty) jest testowana?
- Czy ulgi składkowe są testowane?

### 4. 🔬 AUDYT AUTO TEST KKS (288K — NAJWIĘKSZY PLIK TESTOWY) — POZIOM ENTERPRISE
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `test_auto_block_kks.py`:
- Czy wszystkie 254 reguły KKS mają testy?
- Czy 78 brakujących reguł KKS ma placeholder testy?

### 5. 🔬 AUDYT AUTO TEST MICRO (187K) — POZIOM ENTERPRISE
- Czy testy Micro pokrywają wszystkie mikromoduły?

### 6. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 15)
Z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierające **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "Auto Test Generator z Rego" — generator testów z definicji reguł
2. Mechanizm "Test Coverage 100% Auto" — auto-mapowanie testów na reguły
3. System "KKS Test Fortress" — forteca testowa dla wszystkich 254+78 reguł KKS
4. Mechanizm "VAT Test Matrix" — macierz testowa dla wszystkich stawek VAT
5. System "PIT Relief Test Suite" — zestaw testów dla 11 ulg PIT
6. Mechanizm "ZUS Health Test Grid" — siatka testowa dla 4 wariantów zdrowotnej
7. System "Micro Test Complete" — 100% pokrycia testowego Micro
8. Mechanizm "Auto Test Runner Parallel" — równoległe uruchamianie testów
9. System "Test Flakiness Detector" — wykrywanie niestabilnych testów
10. Mechanizm "Test Speed Optimizer" — optymalizacja czasu testów
11. System "Property Auto-Block" — automatyczne property-based testing
12. Mechanizm "Test Impact Analyzer" — analiza wpływu zmian na testy
13. System "Test Data Factory" — fabryka danych testowych
14. Mechanizm "Test Gap Auto-Fill" — automatyczne wypełnianie luk testowych
15. System "Zero-Untested Rule" — system gwarantujący 0 niestestowanych reguł

### 7. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Heat-mapa pokrycia testowego dla wszystkich modułów JDG
- TOP 50 reguł bez testów (priorytet)

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Auto Test Blocki Enterprise v7.0"
- Executive Summary z TOP 15 rekomendacjami
- Diagramy Mermaid dla pokrycia testowego
- Tabele: reguła → test

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU. NIE MODYFIKUJ PLIKÓW. Tylko RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
