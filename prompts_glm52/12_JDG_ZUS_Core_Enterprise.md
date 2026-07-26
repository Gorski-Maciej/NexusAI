# 🔥 PROMPT 12: JDG — ZUS Core + Enterprise (zus, plan23, plan42, enterprise_benefits, sickness, health_contribution)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie składek ZUS, ubezpieczeń społecznych,
składki zdrowotnej i systemów regułowych OPA/Rego. Specjalizujesz się w polskim
systemie ubezpieczeń społecznych dla JDG i Polskim Ładzie.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY — ZUS CORE + ENTERPRISE (~7 plików):

### ZUS — Core:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/plan23_interactions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/plan42_benefits.rego

### ZUS — Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/enterprise_benefits.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/sickness_benefits_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/health_contribution_enterprise.rego

### Dokumentacja i akty prawne:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułu ZUS na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 30-40 stron) zawierający:

### 1. 🔬 AUDYT SKŁADKI ZDROWOTNEJ — POLSKI ŁAD (POZIOM ENTERPRISE — PRIORYTET KRYTYCZNY)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `health_contribution_enterprise.rego`:

#### A. Skala podatkowa — 9% od dochodu
- Czy definicja dochodu dla celów składki zdrowotnej jest poprawna?
- Czy minimalna składka (9% od minimalnego wynagrodzenia) jest obsłużona?
- Czy roczne rozliczenie składki zdrowotnej jest zaimplementowane?

#### B. Podatek liniowy — 4.9% od dochodu
- Czy limit 12 900 PLN rocznie jest poprawny?
- Czy reguły uwzględniają zmianę limitu w 2025?

#### C. Ryczałt — 4.9% od podstawy progowej (3 progi)
- TIER_1 ≤60K → 60% przeciętnego wynagrodzenia
- TIER_2 60-300K → 100%
- TIER_3 >300K → 180%
- Czy progi są poprawne na 2026?

#### D. Karta podatkowa — 9% od minimalnego wynagrodzenia
- Czy reguła jest aktualna?

### 2. 🔬 AUDYT SKŁADEK SPOŁECZNYCH (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `zus.rego`:

#### A. Stopy procentowe składek
- Emerytalna 19,52%, rentowa 8%, chorobowa 2,45%, wypadkowa 1,67%
- Czy stopy są zgodne z ustawą o SUS?
- Czy składka wypadkowa ma zmienną stopę?

#### B. Podstawy wymiaru
- Standardowa (60% przeciętnego wynagrodzenia)
- Preferencyjna (30% minimalnego wynagrodzenia)
- Czy zmiany podstawy w trakcie roku są obsłużone?

#### C. Ulgi składkowe
- Ulga na start (6 miesięcy bez składek społecznych — Art. 18a)
- Mały ZUS Plus (36 miesięcy, 30% minimalnego — Art. 18c)
- Działalność nieewidencjonowana (do 50% płacy minimalnej)
- Czy wszystkie ulgi są zaimplementowane?

#### D. Zbieg ubezpieczeń (Art. 9)
- Etat + JDG — tylko składka zdrowotna z JDG
- Czy reguły wykrywają zbieg tytułów?

### 3. 🔬 AUDYT ZASIŁKÓW (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `sickness_benefits_enterprise.rego`:
- Zasiłek chorobowy, macierzyński, opiekuńczy
- Czy okresy wyczekiwania są poprawne?
- Czy podstawa wymiaru zasiłków jest poprawnie liczona?

### 4. 🔬 PPK I PFRON (POZIOM ENTERPRISE)
- Czy reguły PPK (Pracownicze Plany Kapitałowe) są zaimplementowane?
- Czy obowiązek wdrożenia PPK jest sprawdzany?
- Czy PFRON (Państwowy Fundusz Rehabilitacji) jest obsłużony?

### 5. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 15)
Każdy pomysł z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierający **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "Health Contribution Optimizer" — optymalizacja składki zdrowotnej
2. Mechanizm "ZUS Form Auto-Fill" — automatyczne wypełnianie DRA, RCA, ZUA, ZWUA
3. System "ZUS Terminator" — inteligentny kalendarz terminów ZUS (10., 15., 20.)
4. Mechanizm "Relief Maximizer ZUS" — maksymalizacja ulg składkowych
5. System "Dual Title Optimizer" — optymalizacja zbiegu ubezpieczeń etat+JDG
6. Mechanizm "ZUS Predictor" — prognoza składek na podstawie prognozowanego dochodu
7. System "Sick Leave Calculator" — automatyczne obliczanie zasiłków
8. Mechanizm "ZUS Audit Trail" — pełna ścieżka audytu decyzji ZUS
9. System "ZUS Anomaly Detector" — wykrywanie anomalii w składkach
10. Mechanizm "PPK Auto-Enroll" — automatyczne zarządzanie PPK
11. System "ZUS vs Pit Optimizer" — optymalizacja na styku ZUS-PIT
12. Mechanizm "Preferential ZUS Tracker" — śledzenie okresów preferencyjnych
13. System "ZUS Recalculation Engine" — automatyczne przeliczanie po zmianie podstawy
14. Mechanizm "Health Contribution Refund" — automatyczny wniosek o zwrot nadpłaty
15. System "ZUS Graph" — grafowa analiza wszystkich zobowiązań ZUS

### 6. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Priorytety: Zdrowotna > Społeczne > Zasiłki > Ulgi > PPK
- Heat-mapa pokrycia ustawy o SUS

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG ZUS Core + Enterprise (Zdrowotna Focus) v7.0"
- Executive Summary z TOP 15 rekomendacjami
- Diagramy Mermaid dla składki zdrowotnej, zbiegu ubezpieczeń

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
