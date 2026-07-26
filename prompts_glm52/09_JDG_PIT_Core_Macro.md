# 🔥 PROMPT 09: JDG — PIT Core Macro Layer (forms, kup, advances, exemptions, transitions, tax_form_intelligence)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie podatku PIT, systemów regułowych 
OPA/Rego oraz architektury Enterprise. Specjalizujesz się w polskiej ustawie o PIT,
formach opodatkowania JDG, kosztach uzyskania przychodu i zaliczkach.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz kodu

## 📂 PLIKI DO ANALIZY — PIT CORE MACRO LAYER (~11 plików):

### PIT — Podstawowe formy i KUP:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/forms.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/kup.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/advances_returns.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/exemptions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/transitions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/tax_form_transition_intelligence.rego

### PIT — Plan Files (rozszerzenia):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/plan23_exemptions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/plan23_tax_form_change.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/plan26_detailed.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/elearning.rego

### Akty prawne i dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułu PIT Core Macro Layer
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**. Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** 
(min. 30-40 stron) zawierający:

### 1. 🔬 AUDYT FORM OPODATKOWANIA PIT (POZIOM ENTERPRISE — PRIORYTET KRYTYCZNY)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `pit/forms.rego`:

#### A. Skala podatkowa 12%/32% (Art. 27)
- Próg 120 000 PLN — czy jest poprawnie zaimplementowany?
- Kwota wolna 30 000 PLN — czy reguły uwzględniają degresywność?
- Czy obliczenia zaliczek są zgodne z art. 44?

#### B. Podatek liniowy 19% (Art. 30c)
- Czy reguły ograniczają liniowy dla byłego pracodawcy (Art. 30c ust. 2)?
- Czy składka zdrowotna 4.9% dla liniowego jest poprawnie powiązana?

#### C. Ryczałt od przychodów ewidencjonowanych
- Czy stawki ryczałtu są zgodne z ustawą o zryczałtowanym podatku?
- Czy limit 2M EUR jest sprawdzany?
- Czy wyłączenia z ryczałtu (Art. 8) są zaimplementowane?

#### D. Karta podatkowa
- Czy reguły obsługują kartę podatkową?
- Czy limity zatrudnienia i przychodów są walidowane?

### 2. 🔬 AUDYT KOSZTÓW UZYSKANIA PRZYCHODU (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `pit/kup.rego`:

#### A. KUP — zasady ogólne (Art. 22)
- Czy definicja KUP (związek z przychodem) jest poprawna?
- Koszty bezpośrednie vs pośrednie (Art. 22 ust. 5-5c) — czy moment potrącenia jest poprawny?

#### B. NKUP — wyłączenia (Art. 23)
- Czy wszystkie 57 punktów Art. 23 jest pokrytych?
- Szczególnie: reprezentacja (pkt 23), samochody (pkt 46), leasing (pkt 47)
- Przeprowadź **GŁĘBOKIE MYŚLENIE** nad kompletnością NKUP

#### C. Prywatny majątek w JDG
- Home office, samochód prywatny — czy proporcja jest poprawna?
- Czy reguły rozróżniają użytek prywatny od firmowego?

### 3. 🔬 AUDYT ZALICZEK I ZEZNAŃ (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `pit/advances_returns.rego`:

#### A. Zaliczki miesięczne/kwartalne (Art. 44)
- Czy terminy (do 20. dnia miesiąca) są walidowane?
- Czy obliczenia zaliczek są poprawne dla każdej formy opodatkowania?
- Czy uproszczona forma zaliczek (1/12 zeszłorocznego) jest obsługiwana?

#### B. Strata podatkowa (Art. 9)
- Czy reguły obsługują odliczenie straty (5 lat, max 50%)?
- Czy kolejność odliczania strat z różnych lat jest poprawna?

#### C. Zeznania roczne PIT-36, PIT-36L, PIT-28
- Czy system wspiera auto-wypełnianie zeznań rocznych?
- Czy ulgi i odliczenia są automatycznie uwzględniane?

### 4. 🔬 AUDYT ZWOLNIEŃ I ULG PIT (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `pit/exemptions.rego` i `plan23_exemptions.rego`:

- Ulga dla młodych (Art. 21 ust. 1 pkt 148) — do 26 lat, limit 85 528 PLN
- Ulga na powrót (pkt 152) — 4 lata, 85 528 PLN
- Ulga dla rodzin 4+ (pkt 153)
- Ulga dla pracujących emerytów (pkt 154)
- Czy wszystkie zwolnienia z Art. 21 są pokryte?

### 5. 🔬 ZMIANY FORMY OPODATKOWANIA (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** `pit/transitions.rego` i `tax_form_transition_intelligence.rego`:

- Czy zmiana formy opodatkowania w trakcie roku jest obsługiwana?
- Czy skutki podatkowe zmiany są poprawnie liczone?
- Czy system sugeruje optymalną formę opodatkowania?

### 6. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 15)
Każdy pomysł z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierający **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "PIT Optimizer" — automatyczna optymalizacja formy opodatkowania co kwartał
2. Mechanizm "KUP Classifier" — AI do automatycznej klasyfikacji wydatków jako KUP/NKUP
3. System "Tax Form Simulator" — symulacja "co by było gdyby" dla różnych form PIT
4. Mechanizm "Loss Harvester" — automatyczna optymalizacja odliczania strat
5. System "Advance Predictor" — ML predykcja zaliczek na podstawie historii
6. Mechanizm "Deduction Maximizer" — automatyczne wyszukiwanie wszystkich dostępnych ulg
7. System "Dual Form Detector" — wykrywanie konfliktów przy łączeniu różnych form PIT
8. Mechanizm "PIT Shield" — ochrona przed błędami w obliczeniach zaliczek
9. System "Annual Auto-Fill" — automatyczne wypełnianie PIT-36/36L/28
10. Mechanizm "Cross-Year Optimizer" — optymalizacja między latami podatkowymi
11. System "Relief Maximizer" — inteligentny dobór ulg dla maksymalizacji zwrotu
12. Mechanizm "Deadline Guardian" — proaktywne pilnowanie terminów PIT
13. System "Scale vs Linear Comparator" — porównanie skali i liniowego w czasie rzeczywistym
14. Mechanizm "NKUP Shield" — automatyczna blokada błędnych odliczeń NKUP
15. System "PIT Audit Trail" — pełna ścieżka audytu dla każdej decyzji PIT

### 7. 📊 REKOMENDACJE — MAPA DROGOWA (POZIOM ENTERPRISE)
- Uszereguj luki według KRYTYCZNOŚCI
- Dla każdej: szacowany czas naprawy, wpływ, ryzyko
- Stwórz heat-mapę pokrycia ustawy o PIT

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG PIT Core Macro Layer v7.0"
- Executive Summary z TOP 15 rekomendacjami
- Diagramy Mermaid dla przepływu decyzji PIT, form opodatkowania, KUP
- Tabele pokrycia artykułów ustawy o PIT

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
