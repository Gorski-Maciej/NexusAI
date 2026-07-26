# 🔥 PROMPT 16: JDG — Księgowość PKPiR Core + Enterprise (accounting, pkpir_enterprise, nkup)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie księgowości JDG, PKPiR, 
systemów regułowych OPA/Rego i rachunkowości klasy Enterprise.
Specjalizujesz się w Podatkowej Księdze Przychodów i Rozchodów, 
Ustawie o Rachunkowości i rozporządzeniach wykonawczych.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY — KSIĘGOWOŚĆ PKPIR (~12 plików):

### PKPiR — Core:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/plan42_pkpir.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/plan23_leasing.rego

### PKPiR — Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/pkpir_enterprise_live.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/pkpir_enterprise_validation.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/pkpir_enterprise_validator.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/uor_enterprise_live.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/nkup_enterprise_complete.rego

### PKPiR — Micro:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_kolumny.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_przychody.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_koszty.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_nkup.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_remanent.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_korekty.rego

### Dokumentacja i akty prawne:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułu księgowości PKPiR 
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 30-40 stron) zawierający:

### 1. 🔬 AUDYT PKPIR — KOLUMNY 1-17 (POZIOM ENTERPRISE — PRIORYTET KRYTYCZNY)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad kompletnym pokryciem PKPiR:

#### A. Kolumna 1 — Liczba porządkowa
- Czy reguły wymuszają ciągłość numeracji?
- Czy luki w numeracji są wykrywane?

#### B. Kolumny 2-3 — Daty
- Czy chronologia zapisów jest walidowana?
- Czy data zdarzenia ≠ data wpisu?

#### C. Kolumny 4-5 — Dokument i kontrahent
- Czy NIP kontrahenta jest walidowany przez Białą Listę?
- Czy numer dokumentu jest weryfikowany?

#### D. Kolumny 6-9 — Opis i przychody
- Kolumna 7 (sprzedane towary), Kolumna 8 (inne przychody)
- Czy reguły poprawnie klasyfikują przychody?

#### E. Kolumny 10-15 — Wydatki/KUP
- Kol. 10 (zakup towarów), Kol. 11 (koszty uboczne)
- Kol. 12 (wynagrodzenia), Kol. 13 (inne wydatki)
- Czy `nkup_enterprise_complete.rego` pokrywa WSZYSTKIE 57 punktów Art. 23?

#### F. Kolumna 16 — NKUP (wydatki niebędące KUP)
- Czy reguły automatycznie przenoszą NKUP z kol. 16?

#### G. Kolumna 17 — Środki trwałe
- Czy ewidencja środków trwałych jest zintegrowana?

#### H. Remanent (§ 27-29 rozporządzenia PKPiR)
- Remanent początkowy, końcowy, śródroczny
- Czy reguły wymuszają spis z natury?
- Wycena remanentu, odpisy aktualizujące

### 2. 🔬 WALIDACJE KRZYŻOWE PKPIR (POZIOM ENTERPRISE)
- Spójność między kolumnami (kol.7+8 vs kol.10-13)
- Zgodność PKPiR z ewidencją VAT
- Zgodność PKPiR z rejestrem środków trwałych
- Przeprowadź **GŁĘBOKĄ ANALIZĘ** `pkpir_enterprise_validator.rego`

### 3. 🔬 NKUP ENTERPRISE COMPLETE (POZIOM ENTERPRISE — PRIORYTET KRYTYCZNY)
- `nkup_enterprise_complete.rego` (13 reguł)
- Przeprowadź **GŁĘBOKIE MYŚLENIE** nad każdym z 57 punktów Art. 23 PIT:
  - Reprezentacja (pkt 23) — szczególnie istotne!
  - Samochody (pkt 46) — limit 75%/150k/225k
  - Leasing (pkt 47) — limit dla osobówek
  - Odsetki od zaległości (pkt 36)
  - Darowizny (pkt 11)
  - Wylistuj WSZYSTKIE BRAKUJĄCE punkty Art. 23

### 4. 🔬 UoR ENTERPRISE LIVE (POZIOM ENTERPRISE)
- `uor_enterprise_live.rego` — pełna księgowość dla większych JDG
- Czy reguły pokrywają zasady UoR (memoriał, współmierność, ostrożność)?
- Czy JDG które muszą prowadzić pełną księgowość są obsłużone?

### 5. 🔬 LEASING (POZIOM ENTERPRISE)
- `plan23_leasing.rego` — leasing operacyjny i finansowy
- Czy klasyfikacja leasingu jest zgodna z KŚT i ustawą PIT?
- Czy limity dla samochodów osobowych są poprawne?

### 6. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 15)
Każdy pomysł z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierający **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "PKPiR Auto-Fill" — automatyczne wypełnianie wszystkich 17 kolumn
2. Mechanizm "NKUP Complete" — 100% pokrycia wszystkich 57 punktów Art. 23
3. System "Cross-Column Auditor" — zaawansowany audyt spójności między kolumnami
4. Mechanizm "Remnant Wizard" — kreator remanentu z auto-wyceną
5. System "PKPiR-to-JPK Bridge" — automatyczne mapowanie PKPiR na JPK_PKPIR
6. Mechanizm "Expense Classifier AI" — AI do klasyfikacji wydatków do kolumn
7. System "Lease Classifier" — automatyczna klasyfikacja leasingu operacyjny/finansowy
8. Mechanizm "PKPiR Anomaly Detector" — wykrywanie anomalii w PKPiR
9. System "Document-to-PKPiR" — automatyczne księgowanie dokumentów w PKPiR
10. Mechanizm "PKPiR Audit Trail" — pełna ścieżka audytu PKPiR
11. System "NKUP Shield" — blokada księgowania NKUP jako KUP
12. Mechanizm "Revenue-Expense Matcher" — automatyczne dopasowanie przychodów do kosztów
13. System "PKPiR Health Score" — scoring jakości PKPiR
14. Mechanizm "Multi-Year PKPiR" — analiza wieloletnia PKPiR
15. System "PKPiR-to-TigerBeetle" — automatyczne mapowanie PKPiR na księgę główną

### 7. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Heat-mapa pokrycia rozporządzenia PKPiR
- Priorytety: NKUP > Kolumny > Remanent > Walidacje > UoR

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG PKPiR i Księgowość Enterprise v7.0"
- Executive Summary z TOP 15 rekomendacjami
- Diagramy Mermaid dla PKPiR kolumn, walidacji krzyżowych
- Tabele pokrycia 57 punktów Art. 23 NKUP

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
