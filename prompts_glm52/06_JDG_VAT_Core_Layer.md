# 🔥 PROMPT 06: JDG — VAT Core Layer (substantive, deductions, procedures, plan files, enterprise VAT)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie podatku VAT, systemów regułowych 
OPA/Rego oraz architektury Enterprise silników decyzyjnych. Specjalizujesz się 
w polskiej ustawie o VAT i implementacji reguł podatkowych w Rego.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — Twoim zadaniem jest wyłącznie analiza i wygenerowanie 
   ROZBUDOWANEGO RAPORTU ANALITYCZNEGO.
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz istniejący kod, nie tworzysz nowego.
3. Raport ma być gotowy do wykorzystania przez zespół developerski do implementacji ulepszeń.

## 📂 PLIKI DO ANALIZY — VAT CORE LAYER (~8 plików):

### VAT — Macro Layer (reguły decyzyjne):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/substantive.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/deductions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/procedures.rego

### VAT — Plan Files (rozszerzenia szczegółowe):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/plan23_detailed.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/plan26_critical.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat/plan42_reduced_rates.rego

### VAT — Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/vat_substantive_complete_enterprise.rego

### Akty prawne i dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułu VAT Core Layer 
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**. Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** 
(min. 30-40 stron) zawierający:

### 1. 🔬 AUDYT POKRYCIA USTAWY O VAT — MAPOWANIE ARTYKUŁ PO ARTYKULE (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** każdej reguły w plikach VAT pod kątem zgodności z ustawą:

#### A. Art. 5-14 — Czynności opodatkowane (POZIOM ENTERPRISE)
- Dostawa towarów, świadczenie usług, nieodpłatne przekazanie
- Czy reguły w `substantive.rego` pokrywają KAŻDY ustęp każdego artykułu?
- Przeprowadź **GŁĘBOKIE MYŚLENIE** nad edge casami: towary z montażem, dostawy łańcuchowe, sprzedaż wysyłkowa

#### B. Art. 15-18 — Podatnicy i rejestracja VAT-R (POZIOM ENTERPRISE)
- Czy reguły obsługują rejestrację VAT-R, VAT-Z, VAT-UE?
- Czy limit zwolnienia podmiotowego (200 000 PLN) ma poprawną proporcję dla nowych JDG?

#### C. Art. 19a-21 — Obowiązek podatkowy (POZIOM ENTERPRISE)
- Czy reguły obsługują wszystkie momenty powstania obowiązku (data dostawy, data faktury, data zapłaty)?
- Czy faktura zaliczkowa i końcowa mają poprawne reguły?

#### D. Art. 41-42 — Stawki VAT (POZIOM ENTERPRISE — GŁÓWNY PRIORYTET)
- Przeanalizuj KAŻDĄ stawkę: 23%, 8%, 5%, 0%, NP, ZW
- Czy `plan42_reduced_rates.rego` kompletnie mapuje Załącznik 3 i 10 do ustawy?
- Stawki 2026: czy wszystkie zmiany stawek (żywność, energia, paliwo) są uwzględnione?
- Zaproponuj **INNOWACYJNY SYSTEM** dynamicznego mapowania stawek po zmianach prawnych

#### E. Art. 86-95 — Odliczenia VAT (POZIOM ENTERPRISE)
- Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `deductions.rego`:
  - Proporcja VAT (Art. 90) — czy korekta roczna jest zaimplementowana?
  - Korekty wieloletnie (Art. 91) — czy reguły pokrywają 5-letni i 10-letni okres korekty?
  - Złe długi (Art. 89a-89b) — czy 90 dni od SLIM VAT 3 jest poprawne?
  - Pojazdy samochodowe (Art. 86a) — limit 50% dla osobówek?
  - Wydatki osobiste (Art. 88) — blokada odliczeń?

#### F. Art. 106a-106n — Faktury i KSeF (POZIOM ENTERPRISE)
- Czy reguły pokrywają obowiązkowe elementy faktury (Art. 106e)?
- Paragon ≤ 450 PLN z NIP jako faktura uproszczona — czy reguła jest poprawna?
- KSeF obligatoryjny od 2026-02-01 — reguły sankcji?

#### G. Art. 108a-108d — MPP / Split Payment (POZIOM ENTERPRISE — KRYTYCZNY PRIORYTET)
- Czy reguły wykrywają obowiązek MPP (towary z Zał. 15 + kwota ≥ 15 000 PLN)?
- Czy komunikaty BLOCK_AND_ALERT dla braku MPP są poprawne?
- Czy dobrowolny MPP jest obsługiwany?
- Zaproponuj **INNOWACYJNY SYSTEM** automatycznego oznaczania faktur MPP

#### H. Art. 113 — Zwolnienie podmiotowe (POZIOM ENTERPRISE)
- Czy przekroczenie limitu 200 000 PLN w trakcie roku jest poprawnie obsłużone?
- Czy utrata prawa do zwolnienia i korekta są zaimplementowane?
- Czy proporcja dla nowych JDG jest poprawna?

### 2. 🛡️ FRAUD DETECTION VAT (POZIOM ENTERPRISE)
- Przeprowadź **GŁĘBOKIE MYŚLENIE** nad systemem anty-fraudowym dla VAT:
  - Puste faktury — czy reguły wykrywają fikcyjne faktury?
  - Karuzele VAT — czy wykrywane są transakcje łańcuchowe?
  - Solidarna odpowiedzialność — czy reguły ostrzegają przed ryzykiem?
- Zaproponuj **GENIALNY SYSTEM** scoringu ryzyka fraudu per kontrahent
- Zaproponuj **POTĘŻNY MECHANIZM** "fraud pattern detection" z analizą historyczną

### 3. 💰 INTEGRACJA Z TIGERBEETLE I SHADOW LEDGER (POZIOM ENTERPRISE)
- Czy reguły VAT poprawnie mapują się na double-entry TigerBeetle?
- Czy Shadow Ledger symuluje wpływ decyzji VAT na księgę główną?
- Zaproponuj **INNOWACYJNE USPRAWNIENIA** w integracji VAT-TigerBeetle

### 4. 🌍 VAT TRANGRANICZNY (POZIOM ENTERPRISE)
- WNT, WDT, eksport, import towarów, import usług
- OSS/IOSS — procedury unijne dla e-commerce
- Miejsce świadczenia (Art. 28a-28o) dla usług B2B i B2C
- Czy reguły w `procedures.rego` pokrywają wszystkie procedury szczególne?

### 5. 📅 TEMPORAL RESILIENCE — ZMIANY W CZASIE (POZIOM ENTERPRISE)
- Przeprowadź **GŁĘBOKĄ ANALIZĘ** temporalności reguł VAT:
  - SLIM VAT 3 (2023): złe długi 150→90 dni
  - KSeF obligatoryjny (2026-02-01)
  - Zmiany stawek 2024-2026
  - Nowa matryca stawek VAT
- Czy każda reguła ma poprawne `valid_from`/`valid_to`?

### 6. 🧪 STRESS TESTY I EKSTREMALNE SCENARIUSZE (POZIOM ENTERPRISE)
- Hiperinflacja — stawki zmieniają się co miesiąc
- Upadłość kontrahenta — korekta VAT od nieściągalnych należności
- Atak na KSeF — system niedostępny 72h
- Masowa korekta — 1000 faktur jednocześnie

### 7. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 15)
Każdy pomysł musi być opisany z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
i musi zawierać **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "VAT Brain" — semantyczna analiza opisu towaru do auto-przypisywania GTU i stawek
2. Mechanizm "MPP Auto-Detection" z analizą Załącznika 15 w czasie rzeczywistym
3. System "VAT Shield" — proaktywna ochrona przed karuzelami VAT z ML
4. Auto-korekta proporcji rocznej z integracją JPK_V7
5. Mechanizm "VAT Time Machine" — symulacja decyzji VAT w różnych datach dla optymalizacji
6. System "Zero-VAT-Doubt" — automatyczna weryfikacja każdej decyzji z minimum 3 źródłami
7. Mechanizm "VAT Graph" — grafowa analiza powiązań między kontrahentami dla fraud detection
8. System "VAT Predictor" — predykcja przyszłego VAT należnego/naliczonego
9. Mechanizm "Cross-Border VAT Optimizer" — optymalizacja VAT dla transakcji UE
10. System "VAT Audit Trail" — niezniszczalna ścieżka audytowa dla każdej decyzji VAT
11. Mechanizm "VAT Delta" — automatyczne wykrywanie zmian w ustawie i aktualizacja reguł
12. System "KSeF Resilient" — automatyczna retry queue dla KSeF z exponential backoff
13. Mechanizm "VAT Anomaly" — wykrywanie anomalii w deklaracjach VAT
14. System "Multi-Currency VAT" — automatyczne przeliczanie VAT dla faktur walutowych
15. Mechanizm "VAT Knowledge Graph" — graf wiedzy o wszystkich powiązaniach VAT

### 8. 📊 REKOMENDACJE PRIORYTETÓW — MAPA DROGOWA (POZIOM ENTERPRISE)
- Uszereguj luki według KRYTYCZNOŚCI (MPP > stawki > odliczenia > KSeF > cross-border > fraud)
- Dla każdego problemu: SZACOWANY CZAS NAPRAWY, wpływ, ryzyko błędnej decyzji
- Stwórz MAPĘ DROGOWĄ ulepszeń modułu VAT

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG VAT Core Layer (MPP Focus) v7.0"
- Executive Summary (1 strona) z TOP 15 rekomendacjami
- Diagramy Mermaid dla MPP flow, Fraud Detection, VAT Decision Pipeline
- Tabele pokrycia KAŻDEGO artykułu ustawy o VAT
- Sekcja "Genialne Pomysły ENTERPRISE — VAT" jako osobny, rozbudowany rozdział

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu. To kluczowe — musisz mieć czyste okno do analizy kolejnej części JDG.
