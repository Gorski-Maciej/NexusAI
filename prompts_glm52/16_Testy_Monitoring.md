# 🔥 PROMPT 16: Infrastruktura Testowa + Monitorowanie (OpenTelemetry, Sentry)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie testowania oprogramowania klasy Enterprise, 
observability (OpenTelemetry), monitorowania (Prometheus, Sentry, structlog), 
property-based testing (crosshair), fuzz testing (schemathesis) i inżynierii niezawodności (SRE).

## ⚠️ NIE GENERUJ KODU — tylko ROZBUDOWANY RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY (~25 plików):

### Testy — Core:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/conftest.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/ (cały katalog ~100+ plików testowych)

### Observability / Monitoring:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/otel.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/logger.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/monitor.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/sentry.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/tracing.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/exporters/ (katalog)
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/otel_fallback.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/telemetry.py

### Testy observability:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_health_observability_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_otel_buffer_replayer_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_otel_fallback_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_otel_fallback_enhanced_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_telemetry_fallback_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_telemetry_ops_endpoint_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_finops_telemetry_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_finops_meter_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_system_integrity_endpoint_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_performance_engineering_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_performance_engineering_enhanced_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_performance_ops_endpoint_contract.py

### Property-based / Fuzz testing:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_boundary_fuzz_auto.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_simulation_property_based.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_crosshair_properties.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_trace_generator.py

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/TESTING.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/MONITORING.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ infrastruktury testowej i monitoringu NexusAI 
na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 18-24 stron) zawierający:

### 1. AUDYT STRATEGII TESTOWEJ (POZIOM ENTERPRISE)
- Czy piramida testów (unit → integration → E2E → performance) jest zrównoważona?
- Czy pokrycie testowe jest wystarczające dla systemu finansowego?
- Które moduły NIE mają testów? (przeanalizuj ~100+ plików testowych vs kod źródłowy)
- Zaproponuj INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW

### 2. ANALIZA PROPERTY-BASED I FUZZ TESTING (POZIOM ENTERPRISE)
- Czy crosshair (SMT-driven) jest lepszy od hypothesis dla reguł Rego?
- Czy schemathesis fuzz testing API jest kompletny?
- Czy boundary_fuzz_auto.py generuje poprawne przypadki graniczne?

### 3. ANALIZA OPENTELEMETRY (POZIOM ENTERPRISE)
- Czy tracing (Span, Trace) jest poprawnie skonfigurowany?
- Czy metryki Prometheus są kompletne?
- Czy otel_fallback.py działa przy awarii collector?
- Czy finops_meter.py poprawnie mierzy koszty operacji?

### 4. ANALIZA LOGOWANIA I SENTRY (POZIOM ENTERPRISE)
- Czy structlog + loguru zapewniają wystarczającą strukturalność?
- Czy Sentry SDK poprawnie raportuje błędy?
- Czy PII monitor (log_pii_monitor.py) chroni dane wrażliwe w logach?

### 5-8. 🆕 AUDYT 2026 + FRAUD + STRESS + GENIALNE POMYSŁY (min. 10 INNOWACYJNYCH USPRAWNIEŃ)

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — Testowanie, OpenTelemetry i Monitoring v7.0"

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
