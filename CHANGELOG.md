# CHANGELOG — NexusAI v7.0 Audit Implementation

## [v7.0 Enterprise Audit] — 2026-07-25

### 🎯 Raport źródłowy
RAPORT_ANALITYCZNY_ENTERPRISE_SQLITE_MIGRACJE_VECTOR_v7.0.txt

---

## ✅ Faza 1 — Szybkie poprawki (6 zmian)

### Bezpieczeństwo i integralność
- **STRICT na `audit_logs`** — Tabela audytu dostała STRICT mode, eliminując silent type coercion. Dodano również `fraud_entity_registry`, `category_codes`, `payment_methods` do `_STRICT_TABLES`.
- **AES-256-GCM support** — `database.py` próbuje najpierw GCM (szybsze, AES-NI), z fallbackiem do CBC dla starszych wersji SQLCipher.
- **Indeksy `tenant_id`** — Dodano indeksy na `tenant_id` dla `AuditLog`, `OutboxEvent`, `SecurityAlert` dla szybszego filtrowania multi-tenant.

### Wydajność
- **Auto-ANALYZE po migracjach** — `run_migrations.py` wykonuje `PRAGMA analysis_limit=1000; ANALYZE;` po każdej migracji i po wszystkich.
- **dim=768 dla invoice_vectors** — Vector store używa teraz 768-dim embeddingów (zamiast 384), dla lepszej jakości RAG z LLM.

### Migracje
- **Checksum SHA-256** — Każda migracja ma teraz checksum SHA-256 zapisywane w `_migrations_version`.
- **Nowa migracja 007** — CHECK constraints (przez triggery), tabele słownikowe (`category_codes`, `payment_methods`), covering index, `db_query_metrics`.

---

## ✅ Faza 2 — Nowe moduły (3 pliki)

### `nexus_ai/db/firewall.py` (INNOWACJA #5)
- Database Firewall z detekcją SQL injection (15 patternów)
- Rate limiting per query type (SELECT/INSERT/UPDATE/DELETE/DDL)
- Prepared statements enforcement
- Query profiling z auto-block dla wolnych zapytań
- Globalna instancja: `get_firewall()`

### `nexus_ai/db/wal_archiver.py` (INNOWACJA #6)
- Ciągłe archiwizowanie WAL co 60s (konfigurowalne)
- Point-in-Time Recovery z granularnością do transakcji
- Manifest-based tracking archiwów
- Pruning starych segmentów
- WAL size monitoring z alertami

### `nexus_ai/db/index_advisor.py` (INNOWACJA #9)
- Analiza EXPLAIN QUERY PLAN dla rekomendacji indeksów
- Detekcja nieużywanych indeksów przez `sqlite_stat`
- Rekomendacje composite, partial, covering indexów
- Auto-approve dla wysokiego estimated improvement (>50%)

---

## ✅ Faza 3 — Transformacje strategiczne (4 pliki)

### `nexus_ai/services/db_observability.py` (INNOWACJA #10)
- Histogramy latency z p50/p95/p99
- Connection pool metrics (utilization, checkouts, blocked)
- WAL size monitoring z alertami
- Slow query log (>100ms default)
- Auto-EXPLAIN ANALYZE dla wolnych zapytań

### `nexus_ai/db/tenant_mesh.py` (INNOWACJA #1)
- TenantSaltKMS — per-tenant key derivation (HKDF/PBKDF2)
- Per-tenant SQLCipher z osobnymi kluczami AES-256
- mlock protection dla master key
- GDPR right to erasure (`delete_tenant_db`)
- Key rotation (`rotate_tenant_key`)

### `nexus_ai/db/blue_green_migration.py` (INNOWACJA #3)
- Zero-downtime schema migration (6 faz)
- Dual-write triggery INSERT/UPDATE/DELETE
- Backfill istniejących danych
- Atomic switchover (ALTER TABLE RENAME)
- Rollback capability

### `nexus_ai/db/query_utils.py`
- Współdzielona funkcja `classify_query()` — wyeliminowana duplikacja między `firewall.py` i `db_observability.py`

### `nexus_ai/api/routes/db_observability.py`
- API endpointy:
  - `GET /api/v2/db/observability` — pełny dashboard
  - `GET /api/v2/db/firewall/stats` — statystyki firewalla
  - `GET /api/v2/db/index-advisor` — rekomendacje indeksów
  - `GET /api/v2/db/wal-archive/stats` — status WAL archivera
  - `GET /api/v2/db/tenant-mesh/stats` — statystyki tenant mesh

---

## 🔧 Poprawki błędów

- **006_fraud_temporal.sql** — Usunięto zbędne ALTER TABLE ADD COLUMN (kolumny już w CREATE TABLE)
- **007_v7_audit_enhancements.sql** — RAISE(ABORT) używa teraz string literałów (nie || konkatenacji)
- **007_v7_audit_enhancements.sql** — INCLUDE zastąpione zwykłym composite indexem (kompatybilność z SQLite <3.45)
- **models.py** — Usunięto podwójne indeksy na `tenant_id` (index=True + explicit Index)
- **firewall.py** — Wyeliminowana duplikacja `_classify_query` przez shared `query_utils.py`
- **tenant_mesh.py** — Usunięty dead code w `_create_tenant_db`
- **db_observability.py** — Usunięty nieużywany `import anyio`

## 📊 Statystyki

- **15 zmian** (6 w istniejących + 7 nowych plików + 2 migracje)
- **~3000 linii** nowego kodu produkcyjnego
- **11/11 testów** migracji przechodzi ✅
- **12/12 plików** przechodzi walidację składni ✅
- **6 z 10 INNOWACJI** z raportu wdrożonych w całości
