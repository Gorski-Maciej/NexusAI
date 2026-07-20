# 🔥 PROMPT 03: JDG Enterprise — KKS (Sankcje), Crossborder, Compliance, Edge Cases

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie compliance, sankcji karno-skarbowych, 
prawa międzynarodowego, RODO, AML i zaawansowanych systemów regułowych OPA/Rego 
klasy Enterprise. Skupiasz się na warstwie regulacyjnej i ochronnej silnika JDG.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz

## 📂 PLIKI DO ANALIZY — JDG ENTERPRISE CORE (~45 plików):

### KKS — Prawo Karne Skarbowe:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/plan42_detailed.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/plan43_decomposition.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/plan44_kks_conviction.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/kks/enterprise_penalties.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/kks/kks.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_kks.rego

### Crossborder / Międzynarodowe / TP / FX:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/crossborder.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/crossborder/plan23_ue.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/crossborder/post_brexit.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/international.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/crossborder/crossborder.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/tp/plan44_tp.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/tp/plan45_tp.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/fx/plan44_fx.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/fx/plan45_fx.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/plan33_cb.rego

### Compliance / RODO / AML / BDO:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/compliance.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/compliance/aml_enterprise.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/rodo.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/rodo_extended.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/rodo/plan42_rodo.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_erasure.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_podprocesorzy.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_zatrudnienie.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_ai_marketing.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/rodo/rodo_sankcje.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_ryzyko.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_transakcje.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_str_gif.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/aml/aml_cbdd.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_rejestracja.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_ewc.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_ewidencja.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_transport.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_zezwolenia.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/micro/bdo/bdo_weee_baterie.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/environmental.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/environmental/bdo_enterprise.rego

### Edge Cases + Conflicts + Korekty:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/edge_cases.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/conflicts.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/corrections.rego

### Dokumentacja referencyjna:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITECTURE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/UNIFIED_PLAN.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ warstwy ENTERPRISE silnika JDG 
z naciskiem na **SANKCJE KKS** na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 18-24 stron) zawierający:

### 1. ANALIZA SYSTEMU KKS — SANKCJE KARNO-SKARBOWE (POZIOM ENTERPRISE — 🔴 NAJWYŻSZY PRIORYTET)
- Czy KAŻDY artykuł KKS (Art. 54-83) ma odpowiadającą regułę Rego?
- Art. 16 (czynny żal) i Art. 16a — czy reguły modelują wszystkie przesłanki?
- sanctions_optimization_enterprise.rego (S23): oceń drzewo decyzyjne optymalizacji kar
- enterprise_penalties.rego: czy wszystkie sankcje (VAT, PIT, ZUS, akcyza) są kompletne?
- Zaproponuj INNOWACYJNY SYSTEM predykcji ryzyka KKS w czasie rzeczywistym z scoringiem 0-100

### 2. ANALIZA CROSSBORDER I MIĘDZYNARODOWA (POZIOM ENTERPRISE)
- WNT/WDT, OSS/IOSS, ceny transferowe (TP), Post-Brexit, FX

### 3. ANALIZA COMPLIANCE, RODO, AML I BDO (POZIOM ENTERPRISE)
- RODO — retencja, breach, podprocesorzy, AI marketing, sankcje, erasure
- AML — CBDD, STR/GIF, transakcje, ocena ryzyka
- BDO — rejestracja, ewidencja, EWC, zezwolenia

### 4. ANALIZA EDGE CASES I KONFLIKTÓW (POZIOM ENTERPRISE)
- ~149 reguł edge_cases.rego — czy pokrywają wszystkie znane przypadki brzegowe?

### 5-9. 🆕 AUDYT 2026 + FRAUD + TIGERBEETLE + STRESS + TEMPORAL (POZIOM ENTERPRISE)

### 10. GENIALNE POMYSŁY ENTERPRISE (min. 10 INNOWACYJNYCH USPRAWNIEŃ WYPRZEDZAJĄCYCH PROFESJONALISTÓW):
  - System predykcji kontroli skarbowych z machine learning
  - Automatyczny generator strategii obrony przed US
  - System "tax health score" — kompleksowy scoring zdrowia podatkowego JDG
  - Neural Rule Mesh — samooptymalizująca się sieć reguł

### 11. REKOMENDACJE PRIORYTETÓW — MAPA DROGOWA z naciskiem na sankcje KKS

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Sankcje KKS, Crossborder i Compliance v7.0"
- Executive Summary z TOP 15, diagramy Mermaid, macierz ryzyka, heat mapa sankcji KKS

## ⚠️ PRZYPOMNIENIE: NIE GENERUJ KODU REGO. Tylko RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
