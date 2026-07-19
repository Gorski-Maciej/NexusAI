# 🔥 PROMPT 09: Bazy Danych — SQLite/SQLCipher + Migracje + ORM + Vector Store

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie baz danych klasy Enterprise: 
SQLite (OLTP), SQLCipher (szyfrowanie), sqlite-vec (wektorowe), SQLModel (ORM), 
migracji danych i strategii backupu. Specjalizujesz się w architekturze 
zero-trust, offline-first i integralności danych.

## ⚠️ NIE GENERUJ KODU — tylko ROZBUDOWANY RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY (~30 plików):

### Baza danych — Core:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/database.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/models.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/async_db_pool.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/async_base_service.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/transactions.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/hooks.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/security.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/async_backup.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/vector_store.py

### ORM / SQLModel / Walidacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/domain/values.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/domain/aggregates.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/msgspec_utils.py

### Migracje:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/001_init.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/002_missing_tables.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/003_service_tables.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/004_supermoces.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/005_amount_minor.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/migrations/run_migrations.py

### Cache:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/dyscache.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/cache/ (katalog)

### Testy:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_migrations.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_schema_drift_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_config_loader.py

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DATABASE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DOMAIN.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ warstwy bazodanowej NexusAI 
na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 18-24 stron) zawierający:

### 1. AUDYT SCHEMATU BAZY DANYCH (POZIOM ENTERPRISE)
- Czy model relacyjny (SQLModel) jest poprawnie znormalizowany?
- Czy indeksy, klucze obce, constraints są optymalne?
- Czy sqlite-vec jest poprawnie wykorzystywany dla embeddingów?
- Czy FTS5 jest używany do wyszukiwania pełnotekstowego?

### 2. ANALIZA BEZPIECZEŃSTWA DANYCH (POZIOM ENTERPRISE)
- Czy SQLCipher (AES-256) jest poprawnie skonfigurowany?
- Czy klucze szyfrowania są bezpiecznie przechowywane?
- Czy WAL mode + szyfrowanie nie powodują konfliktów?
- Czy backup jest szyfrowany?

### 3. ANALIZA MIGRACJI (POZIOM ENTERPRISE)
- Czy system migracji jest idempotentny?
- Czy migracje mają rollback?
- Czy schema drift detection działa?
- Zaproponuj INNOWACYJNY SYSTEM zero-downtime migrations

### 4. ANALIZA VECTOR STORE (POZIOM ENTERPRISE)
- Czy sqlite-vec jest optymalny dla RAG?
- Czy embeddingi są poprawnie indeksowane?
- Czy wyszukiwanie semantyczne jest wydajne?

### 5-9. 🆕 AUDYT 2026 + FRAUD + STRESS + TEMPORAL + GENIALNE POMYSŁY (min. 10 INNOWACYJNYCH USPRAWNIEŃ WYPRZEDZAJĄCYCH PROFESJONALISTÓW)

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — SQLite/SQLCipher, Migracje i Vector Store v7.0"

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```
🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
