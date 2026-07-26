# 🔥 PROMPT 08: JDG — JPK + KSeF + Ordynacja Podatkowa (Core + Micro + Enterprise)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie JPK, KSeF, Ordynacji Podatkowej, 
systemów raportowania podatkowego i integracji z administracją skarbową. 
Specjalizujesz się w polskich przepisach o JPK_V7, KSeF 2.0 i Ordynacji Podatkowej.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY — JPK + KSeF + ORDYNACJA (~25 plików):

### JPK — Core + Micro + Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ksef_jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk_cit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk/plan26_deadlines.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk_v7_autogen_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/jpk/jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_jpk.rego

### KSeF — Enterprise + Micro:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ksef_resilience_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/ksef/ksef.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_ksef.rego

### Ordynacja Podatkowa — Micro + Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/ord/ord.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_ord.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_ord.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/tax_authority_interaction_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/corrections.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/statute_of_limitations.rego

### Korekty i Edge Cases (istotne dla JPK/Ordynacji):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/liability.rego

### Dokumentacja i akty prawne:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułów JPK_V7, KSeF i Ordynacji Podatkowej
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**. Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** 
(min. 30-40 stron) zawierający:

### 1. 🔬 AUDYT JPK_V7 — KOMPLETNOŚĆ I POPRAWNOŚĆ (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad systemem JPK_V7:

#### A. JPK_V7M (miesięczny) i JPK_V7K (kwartalny)
- Czy reguły generują poprawne struktury JPK_V7M/V7K?
- Czy wszystkie pola obligatoryjne są wypełniane?
- Czy walidacja krzyżowa między ewidencją sprzedaży a zakupów jest poprawna?

#### B. GTU Code Auto-Assignment
- Czy system automatycznie przypisuje kody GTU na podstawie opisu towaru?
- Czy wszystkie 13 kodów GTU (GTU_01 do GTU_13) jest obsługiwanych?
- Przeprowadź **GŁĘBOKĄ ANALIZĘ** mapowania towar→GTU

#### C. Automatyczne generowanie deklaracji VAT-7
- Czy `jpk_v7_autogen_enterprise.rego` poprawnie agreguje dane?
- Czy korekty deklaracji (VAT-7K) są obsługiwane?
- Czy terminy składania (do 25. dnia miesiąca) są walidowane?

### 2. 🔬 AUDYT KSeF 2.0 — KOMPLETNOŚĆ I ODPORNOŚĆ (POZIOM ENTERPRISE — PRIORYTET KRYTYCZNY)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** systemu KSeF:

#### A. Obowiązkowy KSeF od 2026-02-01
- Czy reguły blokują wysyłkę faktur poza KSeF po 2026-02-01?
- Czy sankcje za brak KSeF są zaimplementowane?
- Czy wyjątki (faktury B2C, paragony) są poprawnie obsłużone?

#### B. KSeF Resilience
- Czy `ksef_resilience_enterprise.rego` obsługuje offline mode?
- Czy retry z exponential backoff jest zaimplementowany?
- Czy są reguły dla KSeF niedostępnego > 7 dni (tryb awaryjny)?

#### C. Schemat XSD i walidacja
- Czy reguły walidują faktury zgodnie ze schematem XSD KSeF?
- Czy wszystkie typy faktur (FA(1), FA(2), korekty) są obsłużone?

#### D. UPO (Urzędowe Poświadczenie Odbioru)
- Czy system weryfikuje UPO?
- Czy faktury bez UPO są odpowiednio flagowane?

### 3. 🔬 AUDYT ORDYNACJI PODATKOWEJ (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad regułami Ordynacji:

#### A. Przedawnienia (Art. 70-71)
- Czy reguły obsługują 5-letnie i 10-letnie przedawnienia?
- Czy zawieszenie biegu przedawnienia jest zaimplementowane?

#### B. Korekty deklaracji (Art. 81)
- Czy reguły w `corrections.rego` pokrywają wszystkie typy korekt?
- Czy czynny żal (Art. 16 KKS) jest zintegrowany z systemem korekt?

#### C. Pełnomocnictwa podatkowe
- Czy system obsługuje pełnomocnictwa (UPL-1)?
- Czy reprezentacja (prokura) jest zintegrowana?

#### D. Biała lista VAT (Art. 96b)
- Czy reguły weryfikują kontrahenta przed przelewem > 15 000 PLN?
- Czy sankcje za przelew na niezweryfikowany rachunek są obsłużone?

### 4. 🏛️ TAX AUTHORITY INTERACTION — AUTO-KORESPONDENCJA Z US (POZIOM ENTERPRISE)
- Przeprowadź **GŁĘBOKĄ ANALIZĘ** `tax_authority_interaction_enterprise.rego`
- Auto-generacja pism do US/KAS/ZUS — czy wszystkie typy pism są obsługiwane?
- Czynny żal, odwołania, interpretacje, zwrot nadpłaty, raty
- Monitoring statusu spraw — czy system śledzi odpowiedzi US?

### 5. 🛡️ FRAUD DETECTION — JPK I ORDYNACJA (POZIOM ENTERPRISE)
- Czy reguły JPK wykrywają nieprawidłowości w deklaracjach?
- Czy system ostrzega przed ryzykiem kontroli skarbowej?
- Zaproponuj **GENIALNY SYSTEM** scoringu ryzyka kontroli

### 6. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 15)
Każdy pomysł z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**:

1. System "JPK Auto-Fix" — automatyczna korekta błędów w JPK przed wysyłką
2. Mechanizm "KSeF Shield" — wielowarstwowa ochrona przed awarią KSeF
3. System "Tax Calendar" — inteligentny kalendarz wszystkich terminów podatkowych
4. Mechanizm "US Auto-Reply" — automatyczna analiza pism z US i proponowanie odpowiedzi
5. System "Audit Predictor" — ML predykcja ryzyka kontroli skarbowej
6. Mechanizm "Correction Wizard" — kreator korekt z auto-wypełnianiem
7. System "Deadline Guardian" — proaktywny system pilnowania terminów
8. Mechanizm "Document Matcher" — automatyczne dopasowanie dokumentów US do transakcji
9. System "Whitelist Auto-Check" — automatyczna weryfikacja Białej Listy przed każdym przelewem
10. Mechanizm "Interpretation Engine" — auto-generacja wniosków o interpretację
11. System "JPK Diff" — detekcja różnic między JPK a fakturami źródłowymi
12. Mechanizm "KSeF Queue" — inteligentna kolejka retry dla KSeF
13. System "Penalty Calculator" — automatyczny kalkulator odsetek i sankcji
14. Mechanizm "Multi-Year Archive" — archiwizacja JPK i deklaracji z pełną ścieżką audytu
15. System "Compliance Score" — scoring zgodności podatkowej JDG

### 7. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Uszereguj luki według KRYTYCZNOŚCI (KSeF > JPK > Ordynacja > Interakcje z US)
- Dla każdej: szacowany czas naprawy, wpływ, ryzyko

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG JPK + KSeF + Ordynacja Podatkowa v7.0"
- Executive Summary z TOP 15 rekomendacjami
- Diagramy Mermaid dla JPK flow, KSeF resilience, Ordynacja przedawnienia
- Tabele pokrycia artykułów Ordynacji Podatkowej

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
