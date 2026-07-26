# 🔥 PROMPT 07: JDG — VAT Micro Layer (micro/vat/vat.rego + plan33_vat + plan34_vat)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie mikromodułów OPA/Rego, atomowych reguł 
podatkowych per artykuł ustawy oraz zaawansowanej inżynierii reguł VAT na poziomie Micro.
Specjalizujesz się w dekompozycji Macro→Micro i analizie pokrycia prawnego.
To jest NAJWIĘKSZY plik JDG — 1249 reguł, 1.16M znaków. Potrzebna jest absolutna precyzja.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — Twoim zadaniem jest wyłącznie analiza i wygenerowanie 
   ROZBUDOWANEGO RAPORTU ANALITYCZNEGO.
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz istniejący kod, nie tworzysz nowego.
3. Raport ma być gotowy do wykorzystania przez zespół developerski do implementacji ulepszeń.

## 📂 PLIKI DO ANALIZY — VAT MICRO LAYER (~3 pliki):

### VAT Micro — Atomowe reguły per artykuł ustawy:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/vat/vat.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_vat.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_vat.rego

### Dokumentacja i akty prawne:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/policies/bundle.sh

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** modułu VAT Micro Layer 
zawierającego **~1249 atomowych reguł** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**.
Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** (min. 30-40 stron) zawierający:

### 1. 🔬 AUDYT STRUKTURY MICRO — ANALIZA 1249 REGUŁ (POZIOM ENTERPRISE)
- Przeprowadź **GŁĘBOKIE MYŚLENIE** nad strukturą else-chain w micro/vat/vat.rego
- Czy kolejność 1249 reguł jest optymalna dla wydajności?
- Czy reguły są prawidłowo atomowe (jedna reguła = jeden warunek prawny)?
- Czy nazewnictwo `rule_id` jest spójne i zgodne z konwencją?

### 2. 📊 MAPOWANIE ARTYKUŁ PO ARTYKULE — POKRYCIE USTAWY O VAT (POZIOM ENTERPRISE)
Przeprowadź **GŁĘBOKĄ ANALIZĘ** pokrycia każdego artykułu ustawy o VAT przez reguły Micro:

#### A. Art. 5-14 — Czynności opodatkowane
- Ile reguł per artykuł? Czy są luki?
- Sprawdź Art. 5 (dostawa towarów), Art. 7 (dostawa towarów — szczegóły), Art. 8 (świadczenie usług)

#### B. Art. 15-18 — Podatnicy
- Rejestracja VAT-R, VAT-Z, definicja podatnika, mały podatnik

#### C. Art. 19a-21 — Obowiązek podatkowy
- Moment powstania, faktura zaliczkowa, data dostawy, data zapłaty

#### D. Art. 29a-32 — Podstawa opodatkowania
- Rabaty, opusty, skonta — czy reguły uwzględniają korekty podstawy?

#### E. Art. 41-42 — Stawki VAT (ANALIZA SZCZEGÓŁOWA)
- Dla każdej stawki (23%, 8%, 5%, 0%, NP, ZW): ile jest reguł Micro?
- Czy reguły Micro pokrywają wszystkie towary i usługi z Załącznika 3 i 10?
- Przeprowadź **GŁĘBOKIE MYŚLENIE** nad kompletnością stawek obniżonych

#### F. Art. 86-95 — Odliczenia (ANALIZA SZCZEGÓŁOWA)
- Art. 86 ust. 1 (ogólne prawo do odliczenia) — ile reguł?
- Art. 86a (pojazdy samochodowe) — 50% vs 100%
- Art. 88 (blokady odliczeń) — wszystkie kategorie?
- Art. 89a-89b (złe długi) — wierzyciel i dłużnik
- Art. 90-91 (proporcja) — korekta roczna i wieloletnia

#### G. Art. 106a-106nq — Faktury i KSeF
- Elementy faktury, faktura uproszczona, KSeF, faktura korygująca

#### H. Art. 108a-108d — MPP/Split Payment (PRIORYTET KRYTYCZNY)
- Czy reguły Micro pokrywają KAŻDY towar z Załącznika 15?
- Czy obowiązek MPP przy kwocie ≥ 15 000 PLN jest atomowo zaimplementowany?

#### I. Art. 113 — Zwolnienie podmiotowe
- Limit 200 000 PLN, przekroczenie, utrata prawa, korekta

#### J. Art. 116-138 — Import, WNT, eksport
- Import towarów, WNT, procedury uproszczone

#### K. Art. 120-129 — Procedury szczególne
- Marża, dzieła sztuki, towary używane

### 3. 🆚 PORÓWNANIE MICRO vs MACRO — SPÓJNOŚĆ WARSTW (POZIOM ENTERPRISE)
- Przeprowadź **GŁĘBOKIE MYŚLENIE** nad spójnością między Micro i Macro:
  - Czy każda reguła Macro ma odpowiadające reguły Micro?
  - Czy reguły Micro nie duplikują się z Macro?
  - Czy priorytety są spójne między warstwami?

### 4. 🔍 ANALIZA PLAN33_VAT I PLAN34_VAT (POZIOM ENTERPRISE)
- Czym różnią się od micro/vat/vat.rego?
- Czy są to rozszerzenia, zamienniki czy duplikaty?
- Czy integracja z plan33/34 jest poprawna?

### 5. ⚡ OPTYMALIZACJA WYDAJNOŚCI 1249 REGUŁ (POZIOM ENTERPRISE)
- Przeprowadź **GŁĘBOKĄ ANALIZĘ** wydajności:
  - Czy else-chain 1249 elementów jest optymalny?
  - Zaproponuj **INNOWACYJNY SYSTEM** indeksowania dla O(1) dostępu
  - Czy Sharded Router w main_jdg.rego pomija Micro gdy nie jest potrzebne?
- Zaproponuj mechanizm lazy-loading dla rzadko używanych reguł

### 6. 📅 TEMPORAL RESILIENCE W MICRO (POZIOM ENTERPRISE)
- Czy wszystkie reguły Micro mają poprawne valid_from/valid_to?
- SLIM VAT 3, zmiany stawek, KSeF 2026 — czy temporalność jest spójna?

### 7. 🛡️ FRAUD DETECTION W MICRO (POZIOM ENTERPRISE)
- Czy reguły Micro zawierają detekcję:
  - Pustych faktur? Karuzel VAT? Znikającego podatnika?
  - Niewspółmiernych cen? Fikcyjnych transakcji?

### 8. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 12)
Każdy pomysł z **GŁĘBOKIM MYŚLENIEM** na **ZAAWANSOWANYM POZIOMIE ENTERPRISE** 
zawierający **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW**:

1. System "Micro Compiler" — automatyczna generacja reguł Micro z tekstu ustawy przez AI
2. Mechanizm "Micro Index" — B-tree indeks dla O(1) dostępu do 1249 reguł
3. System "Micro Validator" — automatyczna weryfikacja każdej reguły Micro z ustawą
4. Mechanizm "Micro Diff" — wykrywanie zmian w ustawie i proponowanie aktualizacji reguł
5. System "Micro Cache" — cache najczęściej wywoływanych reguł VAT
6. Mechanizm "Micro Tracer" — śledzenie ścieżki decyzyjnej przez Micro do Macro
7. System "Micro Bench" — benchmarking każdej reguły dla optymalizacji
8. Mechanizm "Micro Graph" — graf zależności między regułami Micro
9. System "Micro Safety" — formalna weryfikacja spójności reguł Micro
10. Mechanizm "Micro Lazy" — lazy evaluation dla rzadkich ścieżek
11. System "Micro Auto-Fix" — auto-naprawa reguł po wykryciu błędu w produkcji
12. Mechanizm "Micro Federation" — rozproszona ewaluacja reguł po shardach

### 9. 📊 REKOMENDACJE — MAPA DROGOWA ULEPSZEŃ VAT MICRO (POZIOM ENTERPRISE)
- Uszereguj luki według KRYTYCZNOŚCI
- Dla każdej: szacowany czas naprawy, wpływ, ryzyko
- Stwórz heat-mapę pokrycia ustawy o VAT

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG VAT Micro Layer (1249 reguł) v7.0"
- Executive Summary z TOP 12 rekomendacjami
- Diagramy Mermaid dla struktury Micro, zależności Macro-Micro
- Tabele pokrycia KAŻDEGO artykułu ustawy VAT z licznikiem reguł Micro
- Heat-mapa luk prawnych

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu.
