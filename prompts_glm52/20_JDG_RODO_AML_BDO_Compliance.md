# 🔥 PROMPT 20: JDG — RODO, AML, BDO, Compliance, Environmental, Risk, Conflicts, Edge Cases

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie compliance, RODO, AML, BDO, 
zarządzania ryzykiem, konfliktów między domenami i obsługi przypadków brzegowych.
Specjalizujesz się w systemach regułowych OPA/Rego dla zgodności regulacyjnej.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY (~25 plików):

### RODO — Core + Micro + Rozszerzenia:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/rodo.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/rodo/plan42_rodo.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/rodo_extended.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_erasure.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_podprocesorzy.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_zatrudnienie.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_ai_marketing.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_sankcje.rego

### AML — Core + Micro:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/compliance.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/compliance/aml_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_cbdd.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_ryzyko.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_str_gif.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_transakcje.rego

### BDO + Environmental:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/environmental.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/environmental/bdo_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_rejestracja.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_ewc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_ewidencja.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_transport.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_zezwolenia.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_weee_baterie.rego

### Risk, Conflicts, Edge Cases:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/risk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/risk/plan26_kks_gaar.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/conflicts.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/edge_cases.rego

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułów compliance, RODO, AML, BDO,
ryzyka i konfliktów na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 35-45 stron) zawierający:

### 1. 🔬 AUDYT RODO — OCHRONA DANYCH OSOBOWYCH (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad systemem RODO:

#### A. Rejestr czynności przetwarzania
- Czy reguły wymuszają prowadzenie rejestru?
- Czy kategorie danych są klasyfikowane?

#### B. Prawo do bycia zapomnianym (erasure)
- `rodo_erasure.rego` — czy procedura usuwania danych jest kompletna?
- Czy terminy (30 dni) są przestrzegane?

#### C. Podprocesorzy i transfery EOG
- Czy reguły weryfikują podprocesorów?
- Czy transfery poza EOG mają zabezpieczenia?

#### D. AI Marketing i zgody
- `rodo_ai_marketing.rego` — czy AI marketing ma podstawę prawną?
- Czy zgody marketingowe są śledzone?

#### E. Sankcje RODO
- `rodo_sankcje.rego` — do 20M EUR lub 4% obrotu
- Czy reguły ostrzegają przed ryzykiem sankcji?

### 2. 🔬 AUDYT AML — PRZECIWDZIAŁANIE PRANIU PIENIĘDZY (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `aml_enterprise.rego` (23 reguły):

#### A. CBDD — Centralny Bazy Danych o Beneficjentach Rzeczywistych
- Czy reguły wymuszają rejestrację CBDD?
- Czy beneficjenci rzeczywiści są identyfikowani?

#### B. STR / GIF — zgłaszanie podejrzanych transakcji
- Czy reguły wykrywają transakcje powyżej 15 000 EUR?
- Czy procedura STR (Suspicious Transaction Report) jest zaimplementowana?

#### C. Ocena ryzyka AML
- `aml_ryzyko.rego` — czy scoring ryzyka AML jest kompletny?

### 3. 🔬 AUDYT BDO — BAZA DANYCH ODPADOWYCH (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `bdo_enterprise.rego` (23 reguły):

#### A. Rejestracja BDO
- Czy reguły wymuszają rejestrację w BDO?
- Czy wszystkie rodzaje odpadów są pokryte?

#### B. Ewidencja odpadów
- Czy reguły obsługują ewidencję BDO?
- EWC — kody odpadów

#### C. Transport i zezwolenia
- Czy reguły dla transportu odpadów są kompletne?
- WEEE, baterie — czy są pokryte?

### 4. 🔬 AUDYT RISK — ZARZĄDZANIE RYZYKIEM (POZIOM ENTERPRISE)
- `risk.rego` — ogólny system ryzyka
- GAAR (Art. 119a OrdPU) — klauzula przeciw unikaniu opodatkowania
- Czy `plan26_kks_gaar.rego` poprawnie implementuje GAAR?

### 5. 🔬 AUDYT CONFLICTS — KONFLIKTY MIĘDZY DOMENAMI (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `conflicts.rego` (27 reguł):
- IP Box vs B+R — konflikt ulg
- Reprezentacja vs marketing — klasyfikacja wydatków
- Auto VAT 50% vs KUP 75% — asymetria
- Bad debt timing — VAT vs PIT
- Czy wszystkie znane konflikty są wykrywane?

### 6. 🔬 AUDYT EDGE CASES — PRZYPADKI BRZEGOWE (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `edge_cases.rego` (187 reguł):
- VAT breach mid-year, VAT exempt retroactive, VAT proportion new JDG
- PIT limits, cross-year transitions, KSeF mandatory edge cases
- Czy system pokrywa wystarczająco przypadków brzegowych?

### 7. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 18)
Każdy pomysł z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierający **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "RODO Fortress" — niezniszczalna forteca ochrony danych osobowych
2. Mechanizm "AML Guardian" — strażnik AML z ML detekcją podejrzanych transakcji
3. System "BDO Auto-Compliance" — automatyczna zgodność BDO
4. Mechanizm "Risk Matrix" — zaawansowana macierz ryzyka
5. System "Conflict Resolver AI" — AI do automatycznego rozwiązywania konfliktów
6. Mechanizm "Edge Case Generator" — automatyczna generacja testów brzegowych
7. System "Compliance Dashboard" — kokpit zgodności regulacyjnej
8. Mechanizm "GAAR Shield" — tarcza przed klauzulą GAAR
9. System "RODO Breach Auto-Report" — auto-zgłaszanie naruszeń RODO (72h)
10. Mechanizm "AML KYC Engine" — automatyczna weryfikacja KYC
11. System "BDO Waste Classifier" — AI do klasyfikacji odpadów (kody EWC)
12. Mechanizm "Conflict Graph" — grafowa analiza konfliktów między domenami
13. System "Risk Heatmap" — mapa cieplna ryzyka
14. Mechanizm "RODO Erasure Auto" — automatyczne usuwanie danych
15. System "Compliance Score" — scoring zgodności regulacyjnej JDG
16. Mechanizm "Fraud Pattern Detection" — wykrywanie wzorców fraudu AML
17. System "Environmental Compliance" — pełna zgodność środowiskowa
18. Mechanizm "Regulatory Radar" — radar zmian regulacyjnych

### 8. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Heat-mapa pokrycia: RODO, AML, BDO, Risk, Conflicts, Edge Cases
- Priorytety: RODO > AML > Conflicts > BDO > Risk > GAAR

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG RODO + AML + BDO + Compliance v7.0"
- Executive Summary z TOP 18 rekomendacjami
- Diagramy Mermaid dla RODO breach flow, AML suspicious transaction, conflict detection

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
