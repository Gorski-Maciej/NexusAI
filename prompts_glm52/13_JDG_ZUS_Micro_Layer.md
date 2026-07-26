# 🔥 PROMPT 13: JDG — ZUS Micro Layer (micro/sus, micro/zdrowotna, micro/zasilkowa, plan33_zus, plan34_zus, plan33_health)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie mikromodułów ZUS OPA/Rego, 
atomowych reguł składkowych i ubezpieczeniowych. Specjalizujesz się w polskim 
systemie ubezpieczeń społecznych, składce zdrowotnej i zasiłkach dla JDG.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY — ZUS MICRO LAYER (~6 plików):

### ZUS Micro — Atomowe reguły per ustawa:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/sus/sus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/zdrowotna/zdrowotna.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/zasilkowa/zasilkowa.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_zus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_zus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_health.rego

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułu ZUS Micro Layer 
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 25-35 stron) zawierający:

### 1. 🔬 AUDYT SUS MICRO — USTAWA O SYSTEMIE UBEZPIECZEŃ SPOŁECZNYCH (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `micro/sus/sus.rego` (122 reguły):

#### A. Podmioty podlegające ubezpieczeniom (Art. 6)
- Czy reguły Micro pokrywają wszystkie kategorie?
- JDG, wspólnicy spółek, zleceniobiorcy — czy rozróżnienie jest poprawne?

#### B. Podstawy wymiaru składek (Art. 18-19)
- Standardowa, preferencyjna, Mały ZUS Plus
- Czy zmiany podstawy w trakcie roku są obsłużone atomowo?

#### C. Stopy procentowe (Art. 22)
- Czy każda stopa ma osobną regułę Micro?
- Emerytalna, rentowa, chorobowa, wypadkowa, FP, FS

#### D. Ulga na start (Art. 18a)
- 6 miesięcy — czy reguły obsługują warunki i wyjątki?

#### E. Mały ZUS Plus (Art. 18c)
- 36 miesięcy, 30% minimalnego — czy warunki są poprawnie weryfikowane?

#### F. Terminy płatności (Art. 36, Art. 47)
- 10., 15., 20. dzień miesiąca — czy reguły uwzględniają różne terminy?

#### G. Zbieg ubezpieczeń (Art. 9)
- Etat + JDG — tylko składka zdrowotna
- Kilka JDG — czy reguły obsługują?

### 2. 🔬 AUDYT ZDROWOTNA MICRO — POLSKI ŁAD (POZIOM ENTERPRISE — PRIORYTET KRYTYCZNY)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `micro/zdrowotna/zdrowotna.rego` (136 reguł):

#### A. Skala podatkowa — 9%
- Definicja dochodu, minimalna składka
- Czy reguły mikro są atomowe per warunek?

#### B. Liniowy — 4.9%
- Limit roczny, definicja dochodu

#### C. Ryczałt — 3 progi (TIER_1, TIER_2, TIER_3)
- Czy każdy próg ma osobną regułę atomową?
- Czy wartości progów są zgodne z 2026?

#### D. Karta podatkowa — 9% od minimalnego

### 3. 🔬 AUDYT ZASIŁKOWA MICRO (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `micro/zasilkowa/zasilkowa.rego` (38 reguł):
- Zasiłek chorobowy, macierzyński, opiekuńczy, rehabilitacyjny
- Okresy wyczekiwania, podstawa wymiaru
- Czy wszystkie typy zasiłków są pokryte?

### 4. 🔬 PORÓWNANIE PLAN33 i PLAN34 ZUS (POZIOM ENTERPRISE)
- Czym różnią się od micro/sus i micro/zdrowotna?
- Czy są duplikaty? Czy integracja jest spójna?
- Przeprowadź **GŁĘBOKĄ ANALIZĘ** różnic

### 5. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 12)
Z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierające **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "ZUS Micro Compiler" — auto-generacja Micro z ustawy SUS i zdrowotnej
2. Mechanizm "Health Tier Optimizer" — optymalizacja progu zdrowotnego dla ryczałtu
3. System "ZUS Atomizer" — dekompozycja każdego artykułu na atomowe reguły
4. Mechanizm "Contribution Predictor" — ML predykcja składek na kolejny rok
5. System "ZUS Micro Auditor" — automatyczna weryfikacja każdej reguły z ustawą
6. Mechanizm "Dual Title Matrix" — macierzowa analiza zbiegów ubezpieczeń
7. System "ZUS Diff Engine" — wykrywanie zmian w ustawach SUS
8. Mechanizm "Benefit Calculator Micro" — atomowy kalkulator każdego zasiłku
9. System "ZUS Index" — O(1) dostęp do reguł Micro przez indeksowanie
10. Mechanizm "Health Contribution Simulator" — symulacja różnych scenariuszy
11. System "ZUS Temporal Guard" — ochrona temporalna dla zmian stawek
12. Mechanizm "ZUS Coverage Complete" — doprowadzenie do 100% pokrycia SUS

### 6. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Heat-mapa pokrycia ustawy o SUS
- Priorytety: Zdrowotna > SUS > Zasiłkowa

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG ZUS Micro Layer v7.0"
- Executive Summary z TOP 12 rekomendacjami
- Diagramy Mermaid dla struktury Micro ZUS
- Tabele pokrycia każdego artykułu ustawy SUS i zdrowotnej

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
