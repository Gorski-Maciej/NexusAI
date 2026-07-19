# 🔥 PROMPT 02: JDG — PIT (Ulgi+Optymalizacja), ZUS (Zdrowotna), PKPiR, UoR, Micro

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie podatku PIT, składek ZUS, 
PKPiR, Ustawy o Rachunkowości oraz systemów regułowych OPA/Rego. 
Specjalizujesz się w polskim prawie podatkowym dla JDG i architekturze 
silników regułowych Enterprise.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz

## 📂 PLIKI DO ANALIZY — PIT, ZUS, PKPiR, UoR, MICRO (~50 plików):

### PIT — Core (Macro Layer):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/forms.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/kup.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/advances_returns.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/exemptions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/transitions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/plan23_exemptions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/plan23_tax_form_change.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/plan26_detailed.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/art21_exemptions_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/elearning.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/pit/tax_form_transition_intelligence.rego

### PIT — Micro Layer:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pit/pit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_pit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_pit.rego

### PIT — Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/form_transition_simulator_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/annual_declaration_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/exit_tax_mdr_enterprise.rego

### ZUS — Core + Micro + Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/plan23_interactions.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/plan42_benefits.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/enterprise_benefits.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/sickness_benefits_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/zus/health_contribution_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/sus/sus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/zdrowotna/zdrowotna.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/zasilkowa/zasilkowa.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_zus.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan34_zus.rego

### PKPiR / UoR / Księgowość + Amortyzacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/pkpir_enterprise_live.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/uor_enterprise_live.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/depreciation_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/plan23_leasing.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/accounting/plan42_pkpir.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/uor/plan42_uor.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/uor/uor.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_kolumny.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_przychody.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_koszty.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_nkup.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_remanent.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pkpir/pkpir_korekty.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22a.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22i.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22k.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/amortyzacja/pit_a22n.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/nkup_enterprise_complete.rego

### PCC, Ryczałt, CEIDG, PP, Transport, Środowisko, Sukcesja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pcc/pcc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/ryczalt/ryczalt.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/ceidg/ceidg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/pp/pp.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/transport/transport.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/srodowisko/srodowisko.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/sukcesja/sukcesja.rego

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/README.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/MANIFEST.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ modułów PIT (priorytet: **ULGI I OPTYMALIZACJA**), 
ZUS (priorytet: **SKŁADKA ZDROWOTNA**), PKPiR/UoR oraz mikromodułów na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 20-28 stron) zawierający:

### 1. ANALIZA POKRYCIA USTAWY O PIT (POZIOM ENTERPRISE — PRIORYTET: ULGI I OPTYMALIZACJA)
- **🎯 GŁÓWNY PRIORYTET: Ulgi podatkowe i optymalizacja PIT:**
  - Art. 26e (ulga B+R) — przeanalizuj szczegółowo czy reguły pokrywają definicję działalności B+R!
  - Art. 26h (ulga termomodernizacyjna) — czy limit 53 000 PLN i zakres prac są poprawne?
  - Ulga IP Box (5% stawka) — oceń kompletność reguł kwalifikacji
  - Estoński CIT — czy reguły pokrywają warunki i limity?
  - Ulga na prototyp, robotyzację, ekspansję — czy są zaimplementowane?
- Formy opodatkowania (Art. 9a): skala 12%/32%, liniowy 19%, ryczałt, karta
- KUP (Art. 22-23) — podstawowe koszty
- Zaliczki (Art. 44) — czy terminy i obliczenia są poprawne?

### 2. ANALIZA POKRYCIA ZUS/SUS (POZIOM ENTERPRISE — PRIORYTET: SKŁADKA ZDROWOTNA)
- **🎯 GŁÓWNY PRIORYTET: Składka zdrowotna (Polski Ład):**
  - Skala podatkowa (9% od dochodu) — czy reguły są poprawne?
  - Liniowy (4.9%) — czy limit 11 600 PLN rocznie jest obsłużony?
  - Ryczałt (9%/6%/3%) — czy 3 progi przychodu są poprawne?
  - Karta podatkowa (9% od minimalnego) — czy reguła jest aktualna?
- Składki społeczne, ulgi START/mały ZUS, zasiłki

### 3. ANALIZA PKPiR I UoR — kompletność kolumn, remanent, amortyzacja, leasing

### 4. ANALIZA POZOSTAŁYCH MIKROMODUŁÓW — PCC, Ryczałt, CEIDG

### 5-10. 🆕 AUDYT 2026 + FRAUD + TIGERBEETLE + STRESS + TEMPORAL

### 11. GENIALNE POMYSŁY ENTERPRISE (min. 12)
- System automatycznej optymalizacji formy opodatkowania
- Mechanizm "co by było gdyby" dla ulg (symulacja B+R vs IP Box)
- Automatyczny kalkulator optymalnej składki zdrowotnej
- Predykcja zaliczek PIT z ML na podstawie historii

### 12. REKOMENDACJE — MAPA DROGOWA z naciskiem na ulgi PIT i optymalizację zdrowotnej

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG PIT (Ulgi+Optymalizacja) i ZUS (Zdrowotna) v7.0"
- Executive Summary z TOP 10, diagramy Mermaid, tabele pokrycia ulg

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. Tylko RAPORT ANALITYCZNY.
```
🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
