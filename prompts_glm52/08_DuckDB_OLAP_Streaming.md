# 🔥 PROMPT 08: DuckDB + OLAP Analytics + Streaming Storage

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie baz danych OLAP (DuckDB), 
analityki finansowej klasy Enterprise, streaming storage i przetwarzania 
analitycznego w czasie rzeczywistym.

## ⚠️ NIE GENERUJ KODU — tylko ROZBUDOWANY RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY (~20 plików):

### DuckDB — Core:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/analytics.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/analytics_schema.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/aggregate_functions.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/queries.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/projection_models.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/zpk_schema.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/duckdb_tmp/ (katalog)

### Analityka finansowa:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/compliance_analytics.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/finops_meter.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/facts_aggregator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/analytics.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/forecaster.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/anomaly_detector.py

### Streaming / Event Store:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/message_queue.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/events/ (katalog)
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/events.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/event_log.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/replay_engine.py

### Testy:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_analytics_window_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_streaming_storage_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_streaming_storage_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_forecaster_contract.py

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DATABASE.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ warstwy analitycznej NexusAI 
(DuckDB + OLAP + Streaming) na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 16-22 stron) zawierający:

### 1. AUDYT ARCHITEKTURY DUCKDB (POZIOM ENTERPRISE)
- Czy schemat analityczny (analytics_schema.py) jest optymalny dla zapytań OLAP?
- Czy indeksy i partycjonowanie są poprawne?
- Czy integracja DuckDB ↔ SQLite (OLTP) przez NATS JetStream jest spójna?
- Czy zapytania analityczne nie blokują OLTP?

### 2. ANALIZA WYDAJNOŚCI ANALITYCZNEJ (POZIOM ENTERPRISE)
- Czy aggregate_functions.py wykorzystuje możliwości DuckDB (vectorized execution)?
- Czy PyArrow + Polars pipeline jest optymalny?
- Zaproponuj INNOWACYJNE MECHANIZMY optymalizacji zapytań

### 3. ANALIZA STREAMING STORAGE (POZIOM ENTERPRISE)
- Czy NATS JetStream jako event store spełnia wymogi CQRS/ES?
- Czy replay_engine.py poprawnie odtwarza stan z eventów?
- Czy event_log.py gwarantuje kolejność i niezmienność?

### 4. ANALIZA FORECASTINGU I ML (POZIOM ENTERPRISE)
- Czy forecaster.py używa odpowiednich algorytmów (ARIMA, Prophet, ML)?
- Czy anomaly_detector.py wykrywa anomalie finansowe?
- Zaproponuj INNOWACYJNY SYSTEM predictive analytics z ML

### 5-9. 🆕 AUDYT 2026 + FRAUD + STRESS + TEMPORAL + GENIALNE POMYSŁY (min. 10 INNOWACYJNYCH USPRAWNIEŃ WYPRZEDZAJĄCYCH PROFESJONALISTÓW)

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — DuckDB, OLAP Analytics i Streaming Storage v7.0"

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
