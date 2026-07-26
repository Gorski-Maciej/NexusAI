# 🔥 PROMPT 05: JDG — Orkiestrator i Infrastruktura Reguł (main_jdg, routing, temporal, validation, fallback, thresholds, metadata, helpers, provenance, api_fallback)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie architektury systemów regułowych OPA/Rego klasy Enterprise, 
wieloprzebiegowych orkiestratorów decyzyjnych, shardowanych routerów kontekstowych 
oraz infrastruktury krytycznej dla systemów podatkowych. Specjalizujesz się w polskim prawie podatkowym.

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — Twoim zadaniem jest wyłącznie analiza i wygenerowanie 
   ROZBUDOWANEGO RAPORTU ANALITYCZNEGO.
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz istniejący kod, nie tworzysz nowego.
3. Raport ma być gotowy do wykorzystania przez zespół developerski do implementacji ulepszeń.

## 📂 PLIKI DO ANALIZY — ORKIESTRATOR I INFRASTRUKTURA (~11 plików):

### 🧠 GŁÓWNY ORKIESTRATOR (MÓZG SYSTEMU):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/main_jdg.rego

### 📐 INFRASTRUKTURA KRYTYCZNA:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/_metadata_jdg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/_helpers_jdg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/routing.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/temporal.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/validation.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/fallback.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/api_fallback.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/thresholds_jdg.rego
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/rules/provenance.rego

### Dokumentacja referencyjna:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/README.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITECTURE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/UNIFIED_PLAN.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb

## 🎯 CEL ANALIZY:

Przeprowadź **GŁĘBOKIE MYŚLENIE** i **GŁĘBOKĄ ANALIZĘ** infrastruktury orkiestratora JDG 
na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**. Wygeneruj **ROZBUDOWANY RAPORT ANALITYCZNY** 
(min. 25-35 stron) zawierający:

### 1. 🔬 AUDYT ARCHITEKTURY MULTI-PASS (POZIOM ENTERPRISE)
- Przeprowadź **GŁĘBOKIE MYŚLENIE** nad architekturą Multi-Pass w main_jdg.rego
- Oceń każdy z 17 PAS-ów — czy kolejność ewaluacji jest optymalna?
- Przeanalizuj mechanizm `safe_merge()` i ochronę `immutable_verdict` — czy jest niezawodny na **POZIOMIE ENTERPRISE**?
- Czy architektura Dual-Layer (Macro + Micro) jest poprawnie zintegrowana z orkiestratorem?

### 2. 🧩 ANALIZA SHARDED ROUTER (B1 STRATEGIC INITIATIVE) — POZIOM ENTERPRISE
- Przeprowadź **GŁĘBOKĄ ANALIZĘ** `routing_context` i `shard_selector` — czy hash kontekstu jest kompletny?
- Czy `sharded_sale_verdict` i `sharded_purchase_verdict` pokrywają wszystkie istotne pakiety?
- Zaproponuj **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW** w mechanizmie routingu
- Czy `use_full_chain` poprawnie wykrywa sytuacje wymagające pełnej ewaluacji?

### 3. ⏱️ SYSTEM TEMPORALNY (POZIOM ENTERPRISE)
- Przeprowadź **GŁĘBOKIE MYŚLENIE** nad `temporal.rego` — czy obsługuje wszystkie zmiany prawne?
- Czy `valid_from`/`valid_to` dla SLIM VAT 3 (90 dni złe długi od 2025-07-01) jest poprawne?
- Czy KSeF mandatory od 2026-02-01 ma poprawną temporalność?
- Zaproponuj **INNOWACYJNY SYSTEM** automatycznej temporalności oparty o ISAP crawler

### 4. 🛡️ SYSTEM WALIDACJI I FALLBACK (POZIOM ENTERPRISE)
- Przeanalizuj `validation.rego` — czy pokrywa wszystkie krytyczne walidacje?
- Czy `fallback.rego` i `api_fallback.rego` zapewniają TRUE zero-defect resilience?
- Oceń mechanizm `_routing` (BLOCK_AND_ALERT, TRIAGE_QUEUE) — czy progi są optymalne?

### 5. 📊 SYSTEM PRIORYTETÓW I METADANYCH (POZIOM ENTERPRISE)
- Przeprowadź **GŁĘBOKĄ ANALIZĘ** hierarchii priorytetów (priority 100-9999)
- Czy `_metadata_jdg.rego` kompletnie dokumentuje wszystkie pakiety?
- Czy `_helpers_jdg.rego` dostarcza wszystkich potrzebnych funkcji pomocniczych?

### 6. 🎯 THRESHOLDS — ZERO HARDCODED VALUES (POZIOM ENTERPRISE)
- Przeanalizuj `thresholds_jdg.rego` — czy WSZYSTKIE wartości są wyekstrahowane?
- Wykryj i wylistuj wszystkie potencjalnie zakodowane na sztywno wartości
- Zaproponuj **INNOWACYJNY SYSTEM** hot-reload thresholdów przez OPA Data API

### 7. 🔗 PROVENANCE I ŚCIEŻKA AUDYTU (POZIOM ENTERPRISE)
- Oceń `provenance.rego` — czy zapewnia pełną śledzalność decyzji?
- Czy `immutable_verdict` i HMAC-SHA256 są poprawnie zaimplementowane?
- Zaproponuj **GENIALNE ROZWIĄZANIA** dla Merkle Tree audit trail

### 8. 🚀 OPTYMALIZACJA WYDAJNOŚCI (POZIOM ENTERPRISE)
- Przeanalizuj ścieżkę krytyczną w main_jdg.rego — gdzie są wąskie gardła?
- Czy Sharded Router faktycznie redukuje latency z ~28s do ~8-12s?
- Zaproponuj **INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW** w optymalizacji

### 9. 🧠 GENIALNE POMYSŁY I INNOWACYJNE USPRAWNIENIA (POZIOM ENTERPRISE — minimum 12)
Każdy pomysł musi zawierać **GŁĘBOKIE MYŚLENIE** i być opisany na **ZAAWANSOWANYM POZIOMIE ENTERPRISE**:
- System auto-naprawy orkiestratora (self-healing orchestrator)
- Mechanizm dynamicznego reorderowania PAS-ów na podstawie statystyk
- Rozproszony orkiestrator multi-instance z konsensusem Raft
- System predykcji obciążenia i pre-shardingu
- Mechanizm "shadow orchestrator" do testowania nowych konfiguracji w izolacji
- Automatyczna detekcja i rozwiązywanie konfliktów między pakietami
- System versionowania reguł z automatycznym rollbackiem
- Mechanizm "orchestrator health score" z proaktywnym monitoringiem
- Innowacyjny system cache'owania werdyktów z invalidation przez temporal.rego
- Mechanizm "decision replay" do odtwarzania i weryfikacji historycznych decyzji
- System A/B testowania ścieżek decyzyjnych w produkcji
- Mechanizm automatycznego wykrywania regresji w regułach

### 10. MAPA DROGOWA (POZIOM ENTERPRISE)
- Uszereguj rekomendacje według KRYTYCZNOŚCI
- Dla każdej: szacowany czas wdrożenia, wpływ, ryzyko
- Stwórz diagram zależności między rekomendacjami

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — JDG Orkiestrator i Infrastruktura Reguł v7.0"
- Executive Summary (1 strona) z TOP 10 rekomendacjami
- Diagramy Mermaid dla Multi-Pass flow, Sharded Router, Temporal System
- Tabele porównawcze pokrycia PAS-ów
- Sekcja "Genialne Pomysły ENTERPRISE — Orkiestrator" jako osobny, rozbudowany rozdział

## ⚠️ PRZYPOMNIENIE:
NIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. 
Generujesz WYŁĄCZNIE RAPORT ANALITYCZNY.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego Promptu. To kluczowe — musisz mieć czyste okno do analizy kolejnej części JDG.
