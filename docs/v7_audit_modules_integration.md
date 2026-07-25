# NexusAI v7.0 — Dokumentacja integracyjna nowych modułów

## Spis treści
1. [Database Firewall](#1-database-firewall)
2. [WAL Archiver + PITR](#2-wal-archiver--point-in-time-recovery)
3. [Intelligent Index Advisor](#3-intelligent-index-advisor)
4. [Zero-Trust Database Mesh](#4-zero-trust-database-mesh)
5. [Blue-Green Schema Migration](#5-blue-green-schema-migration)
6. [Global Database Observability](#6-global-database-observability)
7. [API Endpointy](#7-api-endpointy)

---

## 1. Database Firewall

**Plik:** `nexus_ai/db/firewall.py`
**INNOWACJA:** #5 — Application-level SQLite query protection

### Użycie jako middleware (zalecane)
```python
from nexus_ai.db.firewall import get_firewall, FirewallBlockedError

firewall = get_firewall()

# W handlerze zapytania:
try:
    firewall.check_query(sql, params)
    result = execute_query(sql, params)
    firewall.profile_query(sql, duration_ms)
except FirewallBlockedError as e:
    return {"error": str(e)}, 403
```

### Konfiguracja
```python
fw = DatabaseFirewall(
    rate_limits={
        "SELECT": (1000, 60),  # 1000 queries / 60s
        "INSERT": (500, 60),
        "UPDATE": (500, 60),
        "DELETE": (100, 60),
    },
    block_threshold=5,       # Po ilu wolnych query blokować typ
    profiling_window=300,    # Okno profilowania w sekundach
)
```

---

## 2. WAL Archiver + Point-in-Time Recovery

**Plik:** `nexus_ai/db/wal_archiver.py`
**INNOWACJA:** #6 — Continuous WAL archiving

### Użycie jako background task
```python
from nexus_ai.db.wal_archiver import WALArchiver

archiver = WALArchiver(
    db_path="app_data/oltp.db",
    archive_dir="app_data/wal_archive",
    interval_seconds=60,
    max_archive_age_days=30,
)

# W on_startup aplikacji:
await archiver.start()

# W on_shutdown:
await archiver.stop()
```

### Point-in-Time Recovery
```python
# Lista dostępnych punktów odzyskiwania
points = archiver.list_recovery_points()

# Przywróć do konkretnego momentu
await archiver.restore_to_point("2026-07-25T10:00:00")
```

---

## 3. Intelligent Index Advisor

**Plik:** `nexus_ai/db/index_advisor.py`
**INNOWACJA:** #9 — ML-based index recommendations

### Analiza indeksów
```python
from nexus_ai.db.index_advisor import IndexAdvisor

advisor = IndexAdvisor(
    db_path="app_data/oltp.db",
    min_query_count=10,
    improvement_threshold_pct=20.0,
    auto_approve_threshold_pct=50.0,
)

# Znajdź nieużywane indeksy
unused = advisor.find_unused_indexes()

# Pobierz rekomendacje
recommendations = advisor.analyze()

# Wdróż rekomendację
for rec in recommendations:
    if rec.auto_approved:
        advisor.create_index(rec)
```

---

## 4. Zero-Trust Database Mesh

**Plik:** `nexus_ai/db/tenant_mesh.py`
**INNOWACJA:** #1 — Per-tenant SQLCipher z osobnym kluczem

### Inicjalizacja
```python
from nexus_ai.db.tenant_mesh import TenantSaltKMS, TenantDatabaseMesh

# Master key z environment variable
kms = TenantSaltKMS(master_key_env="NEXUS_MASTER_SQLCIPHER_KEY")
mesh = TenantDatabaseMesh(kms, data_dir="app_data/tenants")

# Pobierz bazę dla tenant-a (tworzy jeśli nie istnieje)
db_path = mesh.get_tenant_db("tenant-123")

# Lista wszystkich tenantów
tenants = mesh.list_tenants()

# Rotacja klucza (GDPR, security policy)
mesh.rotate_tenant_key("tenant-123")

# Usunięcie tenant-a (GDPR right to erasure)
mesh.delete_tenant_db("tenant-123")
```

---

## 5. Blue-Green Schema Migration

**Plik:** `nexus_ai/db/blue_green_migration.py`
**INNOWACJA:** #3 — Zero-downtime schema changes

### Przykład migracji tabeli invoices
```python
from nexus_ai.db.blue_green_migration import BlueGreenMigration

mgr = BlueGreenMigration(db_path="app_data/oltp.db")

# Faza 1: Stwórz nową tabelę
mgr.create_v2("invoices", """
    CREATE TABLE invoices_v2 (
        id TEXT PRIMARY KEY,
        number TEXT,
        contractor_nip TEXT,
        amount_net_minor INTEGER CHECK(amount_net_minor >= 0),
        amount_gross_minor INTEGER CHECK(amount_gross_minor >= 0),
        category_code TEXT REFERENCES category_codes(code)
    ) STRICT;
""")

# Faza 2: Dual-write triggery
mgr.setup_dual_write("invoices", {
    "id": "id", "number": "number",
    "contractor_nip": "contractor_nip",
    "amount_net_minor": "amount_net_minor",
    "amount_gross_minor": "amount_gross_minor",
})

# Faza 3: Backfill
mgr.backfill("invoices")

# Faza 4: Walidacja
mgr.validate("invoices")

# Faza 5: Atomic switchover
mgr.switch("invoices")

# Faza 6: Cleanup
mgr.cleanup("invoices")

# Rollback w razie problemów:
# mgr.rollback("invoices")
```

---

## 6. Global Database Observability

**Plik:** `nexus_ai/services/db_observability.py`
**INNOWACJA:** #10 — Full database visibility

### Użycie
```python
from nexus_ai.services.db_observability import DatabaseObservability

obs = DatabaseObservability(
    db_path="app_data/oltp.db",
    slow_query_threshold_ms=100.0,
    wal_alert_threshold_mb=500.0,
)

# Start background collection
await obs.start()

# Rejestruj każde zapytanie
obs.record_query("SELECT * FROM invoices WHERE status = ?", 12.5)
obs.record_pool_checkout()
obs.record_pool_checkin()

# Pobierz statystyki
stats = obs.get_stats()
# stats["latency"] → {avg_ms, p50_ms, p95_ms, p99_ms, histogram}
# stats["pool"] → {active, idle, max, utilization_pct}
# stats["database"] → {size_mb, wal_size_mb}
# stats["slow_queries"] → {threshold_ms, count, recent}
```

---

## 7. API Endpointy

**Plik:** `nexus_ai/api/routes/db_observability.py`
**Router:** `/api/v2/db/*`

| Endpoint | Opis |
|----------|------|
| `GET /api/v2/db/observability` | Pełny dashboard z latency, pool, index stats, WAL |
| `GET /api/v2/db/firewall/stats` | Statystyki DatabaseFirewall (allowed/blocked/rate limits) |
| `GET /api/v2/db/index-advisor` | Rekomendacje indeksów + nieużywane indeksy |
| `GET /api/v2/db/wal-archive/stats` | Status WAL archivera + recovery points |
| `GET /api/v2/db/tenant-mesh/stats` | Statystyki tenant mesh + lista tenantów |

---

## Zmienne środowiskowe

| Zmienna | Moduł | Opis |
|---------|-------|------|
| `NEXUS_SQLCIPHER_KEY` | database.py | Główny klucz SQLCipher |
| `NEXUS_MASTER_SQLCIPHER_KEY` | tenant_mesh.py | Master key dla TenantSaltKMS |
| `NEXUS_DB_PATH` | run_migrations.py | Ścieżka do pliku bazy |
| `NEXUS_JWT_SECRET` | middleware.py | Sekret JWT |
