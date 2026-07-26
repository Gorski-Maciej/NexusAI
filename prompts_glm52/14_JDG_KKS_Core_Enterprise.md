# 🔥 PROMPT 14: JDG — KKS Core + Enterprise (kks.rego, enterprise_penalties, plan42/43/44)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie Kodeksu Karnego Skarbowego, 
systemów regułowych OPA/Rego i compliance podatkowego klasy Enterprise.
Specjalizujesz się w polskim KKS, odpowiedzialności karnej-skarbowej 
i systemach prewencji błędów podatkowych.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY — KKS CORE + ENTERPRISE (~5 plików):

### KKS Core:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/plan42_detailed.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/plan43_decomposition.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/plan44_kks_conviction.rego

### KKS Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/enterprise_penalties.rego

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułu KKS 
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 30-40 stron) zawierający:

### 1. 🔬 AUDYT KKS CORE — 254 REGUŁY (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `kks.rego` (254 reguły, 170 BLOCK, 61 TRIAGE):

#### A. Art. 54 — Uchylanie się od opodatkowania (ANALIZA SZCZEGÓŁOWA)
- Czy reguły pokrywają wszystkie formy uchylania się?
- Czy progi kwotowe (mała wartość, znaczna wartość) są poprawne?
- Czy gradacja kary jest zaimplementowana?

#### B. Art. 56 — Nierzetelne księgi/PKPiR
- Czy reguły wykrywają nierzetelność PKPiR?
- Czy sankcje są odpowiednio gradowane?

#### C. Art. 57 — Nierzetelna ewidencja VAT
- Czy reguły pokrywają wszystkie przypadki?

#### D. Art. 62 § 2 — Puste faktury (fałszerstwo faktur VAT)
- 20 reguł — czy pokrywają wszystkie typy pustych faktur?
- Faktury fikcyjne, zaniżone, zawyżone?

#### E. Art. 77 — Niezłożenie deklaracji w terminie
- Czy reguły pokrywają wszystkie typy deklaracji?

#### F. Art. 16 — Czynny żal
- Czy reguły obsługują czynny żal jako ochronę przed karą?
- Czy warunki skuteczności czynnego żalu są poprawne?

#### G. Art. 16b — Korekta deklaracji
- Czy reguły obsługują ochronę przez korektę deklaracji?

#### H. Art. 44 — Przedawnienie karalności (5 lat)
- Czy reguły uwzględniają przedawnienie?

### 2. 🔬 AUDYT SANKCJI ENTERPRISE (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `enterprise_penalties.rego` (21 reguł):
- Czy kalkulacja stawek dziennych jest poprawna?
- Czy minimalne i maksymalne kary są zgodne z KKS?
- Czy reguły uwzględniają dochód sprawcy przy wymiarze kary?

### 3. 🔬 AUDYT DECOMPOZYCJI KKS — PLAN43 (POZIOM ENTERPRISE)
- Czy dekompozycja na atomowe reguły jest kompletna?
- Czy 78 brakujących reguł KKS (Klasa B) jest zidentyfikowanych?

### 4. 🔬 SYSTEM ROUTINGU KKS (POZIOM ENTERPRISE)
- Czy BLOCK_AND_ALERT jest używany właściwie (170 reguł)?
- Czy TRIAGE_QUEUE (61 reguł) ma poprawne progi?
- Czy eskalacja do człowieka jest odpowiednia?

### 5. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 15)
Każdy pomysł z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierający **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "KKS Shield" — prewencyjny system ochrony przed ryzykiem karno-skarbowym
2. Mechanizm "Penalty Calculator" — pełny kalkulator kar KKS
3. System "Voluntary Disclosure Wizard" — kreator czynnego żalu
4. Mechanizm "Empty Invoice Detector" — zaawansowana detekcja pustych faktur z ML
5. System "KKS Risk Score" — scoring ryzyka KKS per transakcja
6. Mechanizm "Book Audit Auto" — automatyczny audyt PKPiR pod kątem KKS
7. System "Statute of Limitations Tracker" — śledzenie przedawnień
8. Mechanizm "Penalty Minimizer" — strategia minimalizacji kar KKS
9. System "KKS Pattern Detection" — wykrywanie wzorców oszustw
10. Mechanizm "Tax Evasion Detector" — zaawansowana detekcja uchylania się
11. System "KKS Documentation Auto" — automatyczne generowanie dokumentacji obronnej
12. Mechanizm "Fraud Graph" — grafowa analiza powiązań fraudowych
13. System "Penalty Gradation Engine" — silnik gradacji kar
14. Mechanizm "KKS Compliance Score" — scoring compliance KKS
15. System "Auto-RAID" — analiza ryzyka i automatyczna dokumentacja inspekcyjna

### 6. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Heat-mapa pokrycia KKS Art. 54-83
- Priorytety: Puste faktury > Uchylanie się > Nierzetelne księgi > Czynny żal

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG KKS Core + Enterprise v7.0"
- Executive Summary z TOP 15 rekomendacjami
- Diagramy Mermaid dla przepływu decyzji KKS
- Tabele pokrycia każdego artykułu KKS z licznikiem reguł

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
