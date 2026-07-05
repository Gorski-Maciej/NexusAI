# 🗄️ Baza danych (Database)

> **Cel:** Zrozumieć schemat bazy danych, strategię migracji i backupu.  
> **Kiedy czytać:** Przed pracą ze schematem DB, przed migracjami.

---

## 1. Architektura wielobazowa

NexusAI używa **4 silników danych**, każdy do innego celu:

```
┌─────────────────────────────────────────────────────────────┐
│ SQLite + SQLCipher (AES-256)                               │
│ OLTP — faktury, kontrahenci, użytkownicy, decyzje          │
│ Plik: app_data/nexus.db (~5-50 MB)                         │
├─────────────────────────────────────────────────────────────┤
│ DuckDB                                                      │
│ OLAP — analityka, symulacje podatkowe, agregacje            │
│ Plik: app_data/analytics.duckdb                             │
├─────────────────────────────────────────────────────────────┤
│ TigerBeetle                                                 │
│ Double-entry ledger — księga główna                         │
│ Plik: data/tigerbeetle.bin                                  │
├─────────────────────────────────────────────────────────────┤
│ sqlite-vec (rozszerzenie SQLite)                            │
│ Wektory embeddingów dla wyszukiwania semantycznego          │
│ Wbudowane w nexus.db                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Diagram ERD (główne encje)

```mermaid
erDiagram
    users ||--o{ user_roles : has
    users ||--o{ refresh_tokens : has
    users ||--o{ audit_logs : performs
    users ||--o{ notifications : receives
    
    roles ||--o{ user_roles : assigned
    roles ||--o{ role_permissions : has
    permissions ||--o{ role_permissions : grants
    
    invoices ||--o{ audit_logs : tracked
    invoices ||--o{ ledger_transfers : generates
    invoices }o--|| contractors : belongs_to
    
    contractors ||--o{ invoices : has
    contractors ||--o{ active_learning_patterns : learns
    
    company_profiles ||--o{ tax_policies : configures
    company_profiles ||--o{ ledger_transfers : owns
    company_profiles ||--o{ financial_periods : defines
    
    users ||--o{ ui_drafts : saves
    outbox_events ||--o{ dead_letter_events : failed_to
    
    users {
        text id PK
        text username UK
        text password_hash
        text role
        text tenant_id
        int is_active
        text email
        text full_name
        int is_verified
        int must_change_password
        int jwt_version
        text last_login
        text created_at
        text updated_at
    }
    
    invoices {
        text id PK
        text number
        decimal amount_net
        decimal amount_gross
        text currency
        text issue_date
        text contractor_nip FK
        text contractor_id FK
        text status
        text file_path
        text tenant_id
        text created_at
        text updated_at
        text created_by
        text updated_by
        text deletion_date
        int retention_period_years
        int version_id
        int is_deleted
        text deleted_at
        int retry_count
        text processing_status
    }
    
    contractors {
        text id PK
        text name
        text nip UK
        text address
        text bank_account
        int version_id
        text created_at
        text updated_at
    }
    
    company_profiles {
        text id PK
        text name
        text nip UK
        text legal_form
        int ksef_active
        text ksef_token
        int vat_active
        numeric vat_proportion
        text tigerbeetle_ledger_map
        text company_policy
        text created_at
    }
```

> **📝 Wersja tekstowa (ASCII fallback):**
> ```
> GŁÓWNY DIAGRAM ERD:
> 
> users ──┬── user_roles ──── roles ──── role_permissions ──── permissions
>         │        │
>         │  refresh_tokens
>         │  audit_logs
>         │
> invoices ──┬── audit_logs
>            ├── ledger_transfers
>            └── contractors (FK: contractor_nip)
> 
> contractors ─── active_learning_patterns
> 
> company_profiles ──┬── tax_policies
>                     ├── ledger_transfers
>                     └── financial_periods
> 
> outbox_events ─── dead_letter_events
> 
> KLUCZOWE RELACJE:
>   users.id          → user_roles.user_id, refresh_tokens.user_id
>   roles.id          → user_roles.role_id, role_permissions.role_id
>   permissions.id    → role_permissions.permission_id
>   invoices.id       → audit_logs.invoice_id, ledger_transfers.source_document_id
>   contractors.id    → active_learning_patterns.contractor_nip
>   company_profiles.id → tax_policies.company_id, ledger_transfers.company_id
> ```

---

## 3. Opis wszystkich tabel

### 3.1 Core OLTP (migracja 001)

#### `invoices` — Faktury

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT PK | UUID faktury |
| `number` | TEXT | Numer faktury (FV/2026/06/001) |
| `amount_net` | DECIMAL(12,2) | Kwota netto |
| `amount_gross` | DECIMAL(12,2) | Kwota brutto |
| `currency` | TEXT(3) | Kod waluty ISO 4217 (domyślnie PLN) |
| `issue_date` | TEXT | Data wystawienia (ISO 8601) |
| `contractor_nip` | TEXT(10) | NIP kontrahenta |
| `contractor_id` | TEXT | FK → contractors.id |
| `status` | TEXT | Status faktury (maszyna stanów) |
| `file_path` | TEXT | Ścieżka do pliku PDF/JPG |
| `tenant_id` | TEXT | ID najemcy (domyślnie 'default') |
| `retention_period_years` | INTEGER | Okres przechowywania (domyślnie 5) |
| `is_deleted` | INTEGER | Miękkie usunięcie (0/1) |
| `deletion_date` | TEXT | Data usunięcia |
| `retry_count` | INTEGER | Liczba ponownych prób przetwarzania |
| `processing_status` | TEXT | Status przetwarzania |

**Indeksy:**
- `idx_invoices_contractor_nip` — wyszukiwanie po NIP
- `idx_invoices_tenant_status` — dashboard per tenant
- `idx_invoices_updated_at` — sortowanie po dacie
- `idx_invoices_number` — wyszukiwanie po numerze

**Statusy:** `NEW`, `PROCESSING`, `PENDING_REVIEW`, `APPROVED`, `REJECTED`, `BLOCKED`, `PAID`, `MANUAL_REVIEW`, `FAILED`, `BLOCKED_FRAUD_SUSPICION`

#### `contractors` — Kontrahenci

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT PK | UUID kontrahenta |
| `name` | TEXT NOT NULL | Nazwa firmy |
| `nip` | TEXT(10) UNIQUE | NIP (10 cyfr) |
| `address` | TEXT | Adres siedziby |
| `bank_account` | TEXT(26) | Numer rachunku (IBAN) |
| `version_id` | INTEGER | Wersja (optimistic locking) |

#### `outbox_events` — Wzorzec Outbox

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT PK | UUID zdarzenia |
| `event_type` | TEXT | Typ zdarzenia |
| `aggregate_id` | TEXT | ID agregatu |
| `payload` | TEXT | JSON z danymi zdarzenia |
| `status` | TEXT | PENDING / PROCESSING / SENT / FAILED |
| `retry_count` | INTEGER | Liczba ponownych prób |
| `processed` | INTEGER | Czy przetworzone (0/1) |

#### `audit_logs` — Log audytu

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT PK | UUID wpisu |
| `invoice_id` | TEXT | FK → invoices.id |
| `user_id` | TEXT | Kto wykonał akcję |
| `action` | TEXT | Rodzaj akcji |
| `field_changed` | TEXT | Które pole |
| `old_value` | TEXT | Stara wartość |
| `new_value` | TEXT | Nowa wartość |
| `timestamp` | TEXT | Czas zdarzenia |

#### `users` — Użytkownicy

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT PK | UUID użytkownika |
| `username` | TEXT UNIQUE | Nazwa użytkownika |
| `password_hash` | TEXT | Hash hasła (Argon2id) |
| `role` | TEXT | Rola (admin/owner/accountant/worker/viewer) |
| `tenant_id` | TEXT | ID najemcy |
| `is_active` | INTEGER | Czy aktywny (0/1) |
| `email` | TEXT | Adres e-mail |
| `full_name` | TEXT | Imię i nazwisko |
| `is_verified` | INTEGER | Czy e-mail zweryfikowany |
| `must_change_password` | INTEGER | Wymuszona zmiana hasła |
| `jwt_version` | INTEGER | Wersja JWT (inkrementacja → unieważnienie) |
| `last_login` | TEXT | Ostatnie logowanie |

### 3.2 RBAC (migracja 002)

#### `roles` — Role systemowe

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT PK | UUID roli |
| `name` | TEXT UNIQUE | Nazwa (admin, owner, accountant, worker, viewer) |
| `description` | TEXT | Opis roli |
| `is_system` | INTEGER | Czy rola systemowa (1) |

#### `permissions` — Uprawnienia

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT PK | UUID uprawnienia |
| `codename` | TEXT UNIQUE | Kod (invoice.read, admin.users) |
| `resource` | TEXT | Zasób (invoice, admin, report) |
| `action` | TEXT | Akcja (read, write, delete) |

### 3.3 Roboton_Reflekton (migracja 001)

#### `company_profiles` — Profile firm

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT(36) PK | UUID profilu |
| `name` | TEXT(255) | Nazwa firmy |
| `nip` | TEXT(10) UNIQUE | NIP |
| `legal_form` | TEXT(32) | Forma prawna (JDG, sp. z o.o., itp.) |
| `ksef_active` | INTEGER | Czy KSeF aktywny |
| `ksef_token` | TEXT(512) | Token API KSeF |
| `vat_active` | INTEGER | Czy VAT czynny |
| `vat_proportion` | NUMERIC(5,4) | Proporcja VAT (domyślnie 1.0) |
| `tigerbeetle_ledger_map` | TEXT | Mapowanie kont na TigerBeetle |
| `company_policy` | TEXT | Polityka rachunkowości (JSON) |

#### `tax_policies` — Polityki podatkowe

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT(36) PK | UUID polityki |
| `company_id` | TEXT(36) FK | FK → company_profiles |
| `tax_form` | TEXT(32) | Forma opodatkowania |
| `pit_costs_enabled` | INTEGER | Czy koszty PIT |
| `requires_full_ledger` | INTEGER | Czy pełna księgowość |
| `vat_settlement_cycle` | TEXT(32) | Cykl VAT (monthly/quarterly) |
| `effective_from` | TEXT | Data wejścia w życie |

#### `ledger_transfers` — Transfery księgowe

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT(36) PK | UUID transferu |
| `company_id` | TEXT(36) FK | FK → company_profiles |
| `source_account` | BIGINT | Konto źródłowe (Wn) |
| `target_account` | BIGINT | Konto docelowe (Ma) |
| `amount_minor` | BIGINT | Kwota w jednostkach (grosze) |
| `currency` | TEXT(3) | Waluta (PLN) |
| `source_document_id` | TEXT(36) | ID dokumentu źródłowego (faktura) |
| `status` | TEXT(32) | pending / committed / failed |

### 3.4 Warstwa dostępu do danych (15 modułów)

NexusAI zawiera rozbudowaną warstwę dostępu do danych z 23 modułami. Poniżej kluczowe:

#### Silnik i sesje (`db/database.py`)
Centralna inicjalizacja SQLAlchemy Engine dla SQLCipher:
- **`create_oltp_engine()`** — tworzy silnik z poolem połączeń (`QueuePool`, pool_size=5, max_overflow=10), PRAGMAMI (WAL, synchronous=NORMAL, cache_size=50MB, mmap_size=4GB, auto_vacuum=FULL) i SQLCipher AES-256 (PRAGMA key, cipher_page_size=4096, kdf_iter=64000, HMAC_SHA512, PBKDF2)
- **`create_session_factory()`** — fabryka sesji z automatycznym multi-tenant filtrem (`with_loader_criteria WHERE tenant_id = ?`)
- **`create_session_factory(tenant_id=...)`** — dedykowana fabryka dla konkretnego tenanta
- **`init_schema()`** — utworzenie wszystkich tabel przy pierwszym starcie
- **`consolidate_database()`** — WAL checkpoint TRUNCATE + VACUUM + ANALYZE
- **`probe_sqlcipher()`** — detekcja SQLCipher (przez PRAGMA cipher_version lub ctypes.CDLL)

#### Modele (`db/models.py`)
Definiuje wszystkie modele SQLModel (Invoice, Contractor, User, OutboxEvent, itp.) z `__slots__` dla oszczędności RAM.

#### Lifecycle hooks (`db/hooks.py`)
Rejestruje zdarzenia SQLAlchemy:
- **`register_db_hooks(config)`** — rejestruje 2 hooki:
  - `after_flush_replicate` — automatyczna replikacja faktur do DuckDB (`invoices_replica`) po każdym flush
  - `before_flush_validate` — walidacja danych przed zapisem (NIP 10 cyfr, waluta 3 znaki, event_type alfanumeryczny, username 3+ znaki, role z dozwolonych)
- **Validator registry**: `_VALIDATORS[Invoice]`, `_VALIDATORS[Contractor]`, itp. — zamiast if/elif/elif

#### Kolejka wiadomości (`db/message_queue.py`)
`AsyncSQLiteQueue` — lekka, atomowa kolejka komunikatów:
- **enqueue/dequeue/ack/nack** — atomiczne operacje w jednej transakcji SQLite
- **Priorytety** (1-10, domyślnie 5)
- **Opóźnione wiadomości** (delay_until)
- **Dead Letter Queue** — automatyczne przenoszenie po max_retries (domyślnie 3)
- **enqueue_batch()** — wiele wiadomości w jednej transakcji
- **replay_dlq()** — przywrócenie DLQ do kolejki
- Partial indexes dla dequeue/delayed/DLQ

#### Zapytania i FTS (`db/queries.py`)
Łączy paginację, FTS5 i widoki analityczne:
- **`CursorPagination`** — keyset/cursor pagination (zamiast OFFSET — wydajniejsza dla 1M+ rekordów)
- **`FTSManager`** — pełnotekstowe wyszukiwanie przez FTS5 z trigram tokenizerem (tabele: `invoices_fts`, `contractors_fts`, `audit_logs_fts`, `events_fts`), hybrydowe FTS5+vec0, automatyczne triggery po INSERT/UPDATE/DELETE
- **`AnalyticsViews`** — zmaterializowane widoki biznesowe w DuckDB: `m_monthly_summary` (statystyki per miesiąc z LAG, moving average), `m_top_contractors` (ranking kontrahentów z share%), `m_cashflow_projection` (prognoza przepływów z window functions)

#### Bezpieczeństwo DB (`db/security.py`)
- **`SQLCipherConfig(Struct)`** — typowana konfiguracja z walidacją zakresów (cipher_page_size, kdf_iter, HMAC, KDF)
- **`KeyRotation`** — rotacja kluczy SQLCipher przez `PRAGMA rekey` (bez dump/restore), szyfrowany backup z innym kluczem, harmonogram rotacji (domyślnie co 90 dni)
- **`SQLCipherConfig.generate_key()`** — generowanie 256-bitowego klucza przez `os.urandom(32)` + base64

#### Transakcje i Outbox (`db/transactions.py`)
- **`OutboxManager.publish()`** — zapis zdarzenia w tej samej transakcji co dane biznesowe (Transactional Outbox)
- **`process_events()`** — przetwarzanie partii zdarzeń z pessimistic locking (`with_for_update(skip_locked=True)`), order_by FIFO, maksymalnie 5 retry zanim trafi do DLQ

#### Pozostałe moduły DB

| Moduł | Odpowiedzialność |
|---|---|
| `db/database.py` | Init silnika SQLCipher + sesji + multi-tenant filtr |
| `db/models.py` | Wszystkie modele SQLModel (Invoice, Contractor, User, OutboxEvent itp.) |
| `db/hooks.py` | Lifecycle hooks: walidacja przed flush, replikacja do DuckDB po flush |
| `db/message_queue.py` | AsyncSQLiteQueue — atomowa kolejka komunikatów z priorytetami, DLQ, batch |
| `db/queries.py` | CursorPagination + FTS5 full-text search + AnalyticsViews (materialized DuckDB views) |
| `db/security.py` | SQLCipherConfig + KeyRotation (PRAGMA rekey) + harmonogram 90 dni |
| `db/transactions.py` | OutboxManager (Transactional Outbox) + pessimistic locking worker |
| `db/async_db_pool.py` | Asynchroniczny pool połączeń SQLite (asyncio-friendly) |
| `db/async_backup.py` | Backup asynchroniczny (online, non-blocking, fsspec) |
| `db/async_base_service.py` | Klasa bazowa dla serwisów asynchronicznych DB |
| `db/projection_models.py` | Modele projekcji CQRS (read models) |
| `db/analytics_schema.py` | Schemat dla zapytań analitycznych (OLAP) |
| `db/aggregate_functions.py` | Niestandardowe funkcje agregujące SQL (MEDIAN, MODE, PERCENTILE, PRODUCT) |
| `db/analytics.py` | Helpery analityczne (DuckDBManager, PolarsSQLContext) |
| `db/vector_store.py` | Integracja sqlite-vec dla embeddingów i wyszukiwania semantycznego |

---

### 3.5 Serwisy (migracja 003)

#### `dq_decisions` — Kolejka decyzji

| Pole | Typ | Opis |
|---|---|---|
| `id` | INTEGER PK | ID decyzji |
| `user_id` | TEXT | FK → users.id |
| `title` | TEXT | Tytuł pytania |
| `message` | TEXT | Treść pytania |
| `source_agent` | TEXT | Który agent zadał pytanie |
| `status` | TEXT | pending / resolved / expired |
| `priority` | INTEGER | Priorytet (1-5) |
| `expires_at` | TEXT | Data wygaśnięcia |
| `resolution` | TEXT | Odpowiedź użytkownika |

#### `notifications` — Powiadomienia

| Pole | Typ | Opis |
|---|---|---|
| `id` | INTEGER PK | ID powiadomienia |
| `user_id` | TEXT | FK → users.id |
| `title` | TEXT | Tytuł |
| `message` | TEXT | Treść |
| `category` | TEXT | Kategoria (info/warning/error/decision) |
| `priority` | INTEGER | Priorytet |
| `is_read` | INTEGER | Czy przeczytane |
| `requires_action` | INTEGER | Czy wymaga akcji |

#### `failed_tasks` — Dead Letter Queue

| Pole | Typ | Opis |
|---|---|---|
| `id` | TEXT PK | UUID zadania |
| `task_name` | TEXT | Nazwa zadania |
| `payload` | TEXT | Dane wejściowe (JSON) |
| `error_message` | TEXT | Komunikat błędu |
| `stack_trace` | TEXT | Stack trace |
| `retry_count` | INTEGER | Liczba prób |
| `resolved` | INTEGER | Czy naprawione |

#### `task_status` — Status zadań asynchronicznych

| Pole | Typ | Opis |
|---|---|---|
| `task_id` | TEXT PK | UUID zadania |
| `task_name` | TEXT | Nazwa zadania |
| `status` | TEXT | PENDING / PROCESSING / COMPLETED / FAILED / CANCELLED |
| `progress` | REAL | Postęp 0.0–1.0 |
| `result` | TEXT | JSON z wynikiem |
| `error_message` | TEXT | Komunikat błędu |
| `created_at` | TEXT | Czas utworzenia |
| `updated_at` | TEXT | Czas aktualizacji |

#### `ui_drafts` — Drafty UI

| Pole | Typ | Opis |
|---|---|---|
| `tenant_id` | TEXT | ID najemcy (PK) |
| `actor_id` | TEXT | ID użytkownika (PK) |
| `draft_key` | TEXT | Klucz draftu (PK) |
| `payload_json` | TEXT | JSON z danymi draftu |
| `updated_at` | TEXT | Czas ostatniej aktualizacji |

#### `scheduled_tasks` — Harmonogram

| Pole | Typ | Opis |
|---|---|---|
| `id` | INTEGER PK | ID zadania |
| `name` | TEXT | Nazwa |
| `task_type` | TEXT | Typ (ksef_sync, nbp_rates, backup) |
| `trigger_at` | TEXT | Czas wyzwolenia |
| `interval_minutes` | INTEGER | Interwał (NULL = jednorazowe) |
| `is_active` | INTEGER | Czy aktywne |
| `next_run_at` | TEXT | Następne uruchomienie |

---

## 4. Strategia migracji

### 4.1 System natywnych migracji SQL

NexusAI używa własnego, minimalistycznego systemu migracji (zastąpił Alembic):

```
migrations/
├── 001_init.sql           # Inicjalizacja (tabele core)
├── 002_missing_tables.sql # RBAC, DLQ, brakujące kolumny
├── 003_service_tables.sql # Tabele serwisowe
├── 004_supermoces.sql     # Indeksy, constraints, seed
└── run_migrations.py      # Runner
```

### 4.2 Zasady migracji

- **Numerowane sekwencyjnie:** `NNN_opis.sql`
- **Idempotentne:** Każda migracja używa `CREATE TABLE IF NOT EXISTS`, `INSERT OR IGNORE`
- **Tylko SQL:** Żadnego Pythona w migracjach (czytelność, audytowalność)
- **Brak rollback:** Forward-only (zgodnie z filozofią Event Sourcing)

### 4.3 Komendy

```bash
pixi run migrate          # Wykonaj wszystkie pending migracje
pixi run migrate-check    # Sprawdź aktualną wersję
pixi run migrate-history  # Pokaż historię
pixi run migrate-dry      # Suchy przebieg
```

---

## 5. Seed danych

```bash
pixi run seed   # ładuje demo dane (faktury, kontrahenci)
```

Dane seed są w `scripts/seed_data.py` + `scripts/seed_data.toml`.  
Role i permissions są seedowane w migracji `004_supermoces.sql`:

```sql
INSERT OR IGNORE INTO roles (id, name, description, is_system) VALUES
    ('role-system-admin', 'admin', 'System administrator', 1),
    ('role-system-owner', 'owner', 'Business owner', 1),
    ('role-system-accountant', 'accountant', 'Accountant', 1),
    ('role-system-worker', 'worker', 'Worker', 1),
    ('role-system-viewer', 'viewer', 'Viewer', 1);
```

---

## 6. Backup i przywracanie

### 6.1 Backup (automatyczny, dzienny)

```bash
# Backup wszystkich danych
pixi run backup
# → app_data/backups/nexus_backup_2026-07-04T12:00:00.enc
```

Co jest backupowane:
- `app_data/nexus.db` (SQLite)
- `data/tigerbeetle.bin` (TigerBeetle ledger)
- `app_data/*.duckdb` (DuckDB)

### 6.2 Szyfrowanie backupu

- Algorytm: AEAD ChaCha20-Poly1305 (nexus-crypto)
- Weryfikacja: SHA-256 checksum
- Klucz: z Vault (keyring systemowy)

### 6.3 Przywracanie

```bash
pixi run restore --file app_data/backups/nexus_backup_2026-07-04.enc
```

Proces:
1. Weryfikacja SHA-256
2. Deszyfrowanie AEAD
3. Zatrzymanie serwisów
4. Podmiana plików
5. Restart

---

## 7. Przykładowe zapytania

### 7.1 Dashboard — faktury oczekujące

```sql
SELECT status, COUNT(*) as cnt, SUM(amount_gross) as total
FROM invoices
WHERE tenant_id = 'default'
  AND is_deleted = 0
GROUP BY status
ORDER BY total DESC;
```

### 7.2 Ślad audytu dla faktury

```sql
SELECT timestamp, user_id, action, field_changed, old_value, new_value
FROM audit_logs
WHERE invoice_id = 'abc123'
ORDER BY timestamp ASC;
```

### 7.3 Decyzje oczekujące na użytkownika

```sql
SELECT title, message, source_agent, priority, created_at
FROM dq_decisions
WHERE user_id = 'user-1'
  AND status = 'pending'
ORDER BY priority ASC, created_at DESC;
```

### 7.4 Analityka — VAT per miesiąc (DuckDB)

```sql
SELECT 
    strftime(issue_date, '%Y-%m') as month,
    SUM(amount_net) as total_net,
    SUM(amount_gross - amount_net) as total_vat,
    COUNT(*) as invoice_count
FROM invoices
WHERE status = 'APPROVED'
  AND issue_date >= '2026-01-01'
GROUP BY month
ORDER BY month;
```

---

## 🔗 Zobacz również

- [Architektura](ARCHITECTURE.md) — 4 silniki danych, ADR-001 (SQLite vs PostgreSQL), ADR-002 (TigerBeetle)
- [Moduły i logika](MODULES.md) — tabele dq_decisions, ledger_transfers w kontekście przepływu decyzji
- [Bezpieczeństwo](SECURITY.md) — SQLCipher AES-256, szyfrowanie backupu
- [Wdrożenie](DEPLOYMENT.md) — BackupManager, przywracanie

---

> **Data aktualizacji:** 2026-07-04 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-04 · **Weryfikator:** NexusAI Team
