# 🔥 PROMPT 06: JDG — KSeF: Architektura, Resilience, JPK_V7, Integracja

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie Krajowego Systemu e-Faktur (KSeF), 
JPK_V7, integracji z API Ministerstwa Finansów oraz architektury resilience 
systemów fakturowych klasy Enterprise.

## ⚠️ NIE GENERUJ KODU — tylko ROZBUDOWANY RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY (~15 plików):

### KSeF Core + Micro + Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ksef_jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/ksef/ksef.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_ksef.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/ksef_resilience_enterprise.rego

### JPK_V7 Core + Micro + Enterprise:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/jpk/jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_jpk.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk/plan26_deadlines.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/jpk_v7_autogen_enterprise.rego

### Serwisy KSeF (Python):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/ksef_generator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/ksef_service.py

### Testy:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_ksef_generator.py

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/README.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ architektury KSeF w NexusAI na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 14-18 stron) zawierający:

### 1. AUDYT ARCHITEKTURY KSeF (POZIOM ENTERPRISE)
- Czy generowanie XML FA_VAT(2) jest zgodne ze schematem XSD MF?
- Czy walidacja XSD jest kompletna?
- Czy mechanizm retry + circuit breaker (stamina) jest poprawnie skonfigurowany?
- Czy obsługa batch (do 100 faktur) jest zaimplementowana?

### 2. ANALIZA RESILIENCE KSeF (POZIOM ENTERPRISE)
- ksef_resilience_enterprise.rego — czy pokrywa scenariusze awarii?
- Czy system radzi sobie z KSeF offline przez 72h?
- Zaproponuj INNOWACYJNY MECHANIZM offline queue z auto-retry

### 3. ANALIZA JPK_V7 (POZIOM ENTERPRISE)
- sales_register, purchase_register, VAT-7 deklaracja
- GTU code autoassignment — kompletność
- JPK_CIT (nowy obowiązek 2026)

### 4-8. 🆕 AUDYT 2026 + FRAUD + TIGERBEETLE + STRESS + TEMPORAL

### 9. GENIALNE POMYSŁY ENTERPRISE (min. 8 INNOWACYJNYCH USPRAWNIEŃ WYPRZEDZAJĄCYCH PROFESJONALISTÓW):
  - System auto-recovery po awarii KSeF
  - Mechanizm incremental batch send z checkpoint
  - Predykcja czasu odpowiedzi KSeF z ML

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```
🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
