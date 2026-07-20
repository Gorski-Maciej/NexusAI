# 🔥 PROMPT 12: Backend — Litestar + NATS + CQRS/ES + Architektura

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie architektury backendowej klasy Enterprise: 
Litestar (ASGI), NATS JetStream (messaging), CQRS + Event Sourcing, 
Modular Monolith, wzorce projektowe i inżynierii oprogramowania.

## ⚠️ NIE GENERUJ KODU — tylko ROZBUDOWANY RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY (~20 plików):

### Backend — Core:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/main.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/main.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/pyproject.toml
- https://github.com/Gorski-Maciej/NexusAI/blob/main/pixi.toml
- https://github.com/Gorski-Maciej/NexusAI/blob/main/start.sh

### API / Litestar:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/api/ (cały katalog)
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/config/ (katalog)

### NATS / Messaging:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/nats_utils.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/broker.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/bus.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/taskiq.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/tasks.py

### CQRS / ES / Architektura:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/architecture/ (katalog)
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/domain/aggregates.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/domain/values.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/events/ (katalog)
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/events.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/di.py

### Core infrastructure:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/config.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/secrets.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/tenant.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/hot_reload.py (jeśli istnieje)

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/ARCHITECTURE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DOMAIN.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/WORKFLOWS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/CONFIG.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/EVENTS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DECISIONS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/BUILD_CONFIG.md

### Testy:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_startup_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_ci_workflows_contract.py

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ architektury backendowej NexusAI 
na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 20-28 stron) zawierający:

### 1. AUDYT ARCHITEKTURY BACKENDU (POZIOM ENTERPRISE)
- Modular Monolith — czy granice modułów są poprawne?
- CQRS + Event Sourcing — czy separacja Command/Query jest czysta?
- Czy NATS JetStream jako event bus spełnia wymogi?
- Czy Dependency Injection (di.py) jest poprawnie skonfigurowane?
- Zaproponuj INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW

### 2. ANALIZA API / LITESTAR (POZIOM ENTERPRISE)
- Czy routing API jest RESTful i zgodny z OpenAPI?
- Czy middleware (rate limiting, CORS, JWT) jest kompletne?
- Czy Granian (Rust ASGI server) jest optymalnie skonfigurowany?

### 3. ANALIZA NATS / KOLEJKI (POZIOM ENTERPRISE)
- Czy NATS JetStream zapewnia exactly-once delivery?
- Czy taskiq-nats integracja jest stabilna?
- Czy event bus obsługuje saga pattern?

### 4. ANALIZA KONFIGURACJI I TENANTÓW (POZIOM ENTERPRISE)
- Czy system konfiguracji (config.py, TOML) jest elastyczny?
- Czy multi-tenancy (tenant.py) jest poprawnie zaimplementowane?

### 5-10. 🆕 AUDYT 2026 + FRAUD + STRESS + TEMPORAL + GENIALNE POMYSŁY (min. 10 INNOWACYJNYCH USPRAWNIEŃ)

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — Litestar, NATS, CQRS/ES i Architektura Backend v7.0"

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```
🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
