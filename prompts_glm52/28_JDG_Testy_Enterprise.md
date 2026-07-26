# 🔥 PROMPT 28: JDG — Testy Enterprise (test_vat_enterprise, test_pkpir_uor, test_pcc_excise, test_kks_enterprise, test_crossborder_enterprise, test_phase5, test_strategic_v2, test_tax_pipeline, test_tax_rules, test_rodo, test_aml, test_bdo, test_conflicts, test_edge_cases, test_hyper_plan45)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie testowania systemów regułowych OPA/Rego,
zapewnienia jakości Enterprise i strategii testowych dla silników podatkowych.
Specjalizujesz się w testach jednostkowych, integracyjnych, automatycznych blokach
testowych i property-based testing dla reguł podatkowych.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY — TESTY ENTERPRISE (~18 plików):

### Testy Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_vat_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_pkpir_uor_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_pcc_excise_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_kks_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_crossborder_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_phase5_modules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_strategic_v2_modules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_tax_pipeline.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_tax_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_tax_audit.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_rodo_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_aml_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_bdo_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_edge_cases_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_conflicts_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_hyper_plan45_enterprise.py

### Auto Tests (kluczowe):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_vat.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_pit.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_kks.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_edge_cases.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_micro.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/auto/test_auto_block_zus.py

### Dokumentacja testów:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/README.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/TESTING.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** strategii testowej JDG
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 30-40 stron) zawierający:

### 1. 🔬 AUDYT POKRYCIA TESTOWEGO (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad strategią testową:

#### A. Testy VAT Enterprise
- `test_vat_enterprise.py` — czy pokrywa wszystkie reguły VAT?
- Czy testy weryfikują MPP, split payment, KSeF, stawki?

#### B. Testy PKPiR/UoR
- `test_pkpir_uor_enterprise.py` — czy pokrywa wszystkie 17 kolumn?

#### C. Testy KKS
- `test_kks_enterprise.py` — czy testy weryfikują wszystkie typy przestępstw?

#### D. Testy Cross-Border
- `test_crossborder_enterprise.py` — WNT, WDT, eksport, import?

#### E. Testy RODO, AML, BDO
- Czy testy compliance są kompletne?

#### F. Testy Edge Cases i Conflicts
- 187 edge cases — czy wszystkie są testowane?
- 27 konfliktów — czy testy potwierdzają wykrywanie?

### 2. 🔬 AUDYT AUTO TEST BLOCKÓW (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** systemu auto testów:
- `test_auto_block_kks.py` (288K — NAJWIĘKSZY plik testowy!)
- `test_auto_block_micro.py` (187K — DRUGI!)
- `test_auto_block_edge_cases.py` (65K)
- `test_auto_block_vat.py`, `pit.py`, `zus.py`
- Czy auto-bloki testują WSZYSTKIE reguły?

### 3. 🔬 GAP ANALYSIS — CZEGO NIE TESTUJEMY? (POZIOM ENTERPRISE)
- Które reguły nie mają testów?
- Które moduły mają 0% pokrycia testowego?
- Wylistuj TOP 50 brakujących testów

### 4. 🔬 STRATEGIA TESTOWA — PROPERTY-BASED + FUZZ TESTING (POZIOM ENTERPRISE)
- Czy property-based testing (crosshair) jest wykorzystany?
- Czy fuzz testing (schemathesis) jest stosowany?
- Zaproponuj **INNOWACYJNĄ STRATEGIĘ TESTOWĄ** na **POZIOMIE ENTERPRISE**

### 5. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 15)
Każdy pomysł z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierający **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "Test Coverage 100%" — roadmapa do 100% pokrycia testowego
2. Mechanizm "Auto Test Generator" — auto-generacja testów z reguł Rego
3. System "Regression Shield" — tarcza przed regresją
4. Mechanizm "Property Test Engine" — silnik testów property-based
5. System "Fuzz Testing Factory" — fabryka fuzz testów
6. Mechanizm "Test Matrix" — macierz testowa dla wszystkich modułów
7. System "Coverage Heatmap" — mapa cieplna pokrycia testowego
8. Mechanizm "Test Speed Optimizer" — optymalizacja czasu testów
9. System "Golden Test Suite" — złoty zestaw testów
10. Mechanizm "Mutation Testing" — testowanie mutacyjne reguł
11. System "Test Auto-Fix" — auto-naprawa testów po zmianie reguł
12. Mechanizm "Load Test Engine" — silnik testów obciążeniowych
13. System "Test Quality Score" — scoring jakości testów
14. Mechanizm "CI/CD Test Pipeline" — pipeline testowy w CI/CD
15. System "Zero-Bug Test Strategy" — strategia zero-bug

### 6. 📊 REKOMENDACJE — MAPA DROGOWA TESTOWANIA (POZIOM ENTERPRISE)
- Heat-mapa pokrycia testowego per moduł
- Priorytety: VAT > KKS > PIT > ZUS > Cross-Border > Compliance

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Testy Enterprise v7.0"
- Executive Summary z TOP 15 rekomendacjami
- Diagramy Mermaid dla strategii testowej
- Tabele pokrycia testowego per moduł JDG

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU. NIE MODYFIKUJ PLIKÓW. Tylko RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
