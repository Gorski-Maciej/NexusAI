# 🔥 PROMPT 18: JDG — Local Taxes + PCC + Excise + Akcyza (Klasa IX — NAJWIĘKSZA LUKA)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie podatków lokalnych, PCC, akcyzy
oraz systemów regułowych OPA/Rego. Specjalizujesz się w podatkach samorządowych,
podatku od czynności cywilnoprawnych i podatku akcyzowym.
⚠️ TO JEST NAJWIĘKSZA LUKA W POKRYCIU PRAWNYM JDG — Klasa IX (225 punktów, ~1% pokrycia).

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY — LOCAL TAXES + PCC + EXCISE (~12 plików):

### Local Taxes Core + Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/pcc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/real_estate.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/transport.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/plan26_local.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/pcc_enterprise_complete.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/pcc_excise_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/excise_enterprise_complete.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/local_taxes/local_procedures_enterprise.rego

### Micro — PCC + Akcyza:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pcc/pcc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/akcyza/akcyza.rego

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułów podatków lokalnych, PCC i akcyzy
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**. To NAJWIĘKSZA LUKA w pokryciu prawnym JDG.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 35-45 stron) zawierający:

### 1. 🔬 AUDYT PCC — PODATEK OD CZYNNOŚCI CYWILNOPRAWNYCH (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad ustawą o PCC:

#### A. Przedmiot opodatkowania (Art. 1-2)
- Umowy sprzedaży, pożyczki, darowizny, spółki, zamiana
- Czy reguły w `pcc_enterprise_complete.rego` (51 reguł) pokrywają wszystkie czynności?
- Wyłączenie spod VAT a PCC — czy reguły są poprawne?

#### B. Stawki PCC (Art. 6-7)
- 2% — sprzedaż rzeczy, praw majątkowych
- 1% — sprzedaż innych praw
- 0.5% — pożyczki, umowy spółki
- Czy stawki są zgodne z ustawą?

#### C. Deklaracja PCC-3 (Art. 10)
- Termin 14 dni od dokonania czynności
- Czy reguły generują PCC-3?

#### D. Zwolnienia z PCC
- Transakcje VAT (wyłączone z PCC)
- Czy reguły poprawnie identyfikują transakcje VAT-wyłączone?

### 2. 🔬 AUDYT PODATKU OD NIERUCHOMOŚCI (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `real_estate.rego`:

#### A. Stawki podatku od nieruchomości (Art. 5)
- Grunty, budynki, budowle
- Stawka firmowa (~33 zł/m²) vs mieszkalna (~1,15 zł/m²)
- Czy reguły rozróżniają przeznaczenie?

#### B. Deklaracja DN-1
- Czy reguły generują DN-1?
- Termin do 31 stycznia — czy walidowany?

#### C. Zwolnienia i ulgi
- Czy reguły pokrywają zwolnienia ustawowe?
- Czy ulgi gminne są konfigurowalne?

### 3. 🔬 AUDYT PODATKU OD ŚRODKÓW TRANSPORTOWYCH (POZIOM ENTERPRISE)
- `transport.rego` — samochody ciężarowe > 3.5t, autobusy, ciągniki
- Czy reguły pokrywają wszystkie kategorie?
- Stawki gminne — czy są konfigurowalne?

### 4. 🔬 AUDYT AKCYZY (POZIOM ENTERPRISE — PRIORYTET KRYTYCZNY)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `akcyza.rego` (132 reguły) i `excise_enterprise_complete.rego`:

#### A. Wyroby akcyzowe
- Paliwa silnikowe, oleje opałowe
- Alkohol etylowy, piwo, wino, wyroby spirytusowe
- Wyroby tytoniowe
- Energia elektryczna
- Czy reguły pokrywają wszystkie kategorie?

#### B. Stawki akcyzy
- Czy stawki są zgodne z ustawą o podatku akcyzowym?
- Czy zmiany stawek (np. podwyżki akcyzy na alkohol i tytoń) są obsłużone?

#### C. Zwolnienia z akcyzy
- Czy reguły pokrywają zwolnienia?
- Składy podatkowe, procedura zawieszenia

#### D. Deklaracje AKC-4/AKC-4ZO
- Czy reguły generują deklaracje akcyzowe?
- Miesięczne terminy — czy walidowane?

### 5. 🔬 LOCAL PROCEDURES ENTERPRISE (POZIOM ENTERPRISE)
- `local_procedures_enterprise.rego` — procedury lokalne
- Czy integracja PCC + Nieruchomości + Transport + Akcyza jest spójna?

### 6. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 18)
Każdy pomysł z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierający **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "PCC Shield" — automatyczna detekcja obowiązku PCC i generowanie PCC-3
2. Mechanizm "Excise Complete" — 100% pokrycia ustawy o podatku akcyzowym
3. System "Property Tax Auto-Report" — automatyczne generowanie DN-1
4. Mechanizm "Transport Tax Tracker" — śledzenie obowiązku podatkowego od transportu
5. System "Multi-Tax Calendar" — kalendarz terminów dla wszystkich podatków lokalnych
6. Mechanizm "Excise Warehouse Manager" — zarządzanie składem podatkowym
7. System "Local Tax Rate Updater" — automatyczna aktualizacja stawek gminnych
8. Mechanizm "PCC vs VAT Detector" — detekcja kolizji PCC-VAT
9. System "Excise Suspension" — obsługa procedury zawieszenia poboru akcyzy
10. Mechanizm "Cross-Tax Optimizer" — optymalizacja na styku PCC-VAT-akcyza
11. System "Local Tax Audit" — audyt zgodności z podatkami lokalnymi
12. Mechanizm "Excise Auto-Declaration" — automatyczne generowanie AKC-4
13. System "Property Classification AI" — AI do klasyfikacji nieruchomości
14. Mechanizm "PCC Loan Tracker" — śledzenie pożyczek i PCC od pożyczek
15. System "Excise Bond Calculator" — kalkulator zabezpieczenia akcyzowego
16. Mechanizm "Multi-Jurisdiction Local Tax" — obsługa wielu gmin
17. System "Local Tax Archive" — archiwizacja deklaracji lokalnych
18. Mechanizm "Class IX Complete" — strategia domknięcia największej luki do 100%

### 7. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Heat-mapa pokrycia Klasa IX (225 punktów prawnych)
- Priorytety: PCC > Akcyza > Nieruchomości > Transport

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Local Taxes + PCC + Excise (Klasa IX) v7.0"
- Executive Summary z TOP 18 rekomendacjami
- Diagramy Mermaid dla PCC flow, Akcyza flow
- Tabele pokrycia ustaw: PCC, akcyzowa, podatki lokalne

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
