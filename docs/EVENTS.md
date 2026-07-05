# Event Sourcing — System zdarzeń domenowych

> **Plik:** `nexus_ai/events/`
> **Status:** Stabilny · **Wersja:** 2.3.0
> **Ostatnia aktualizacja:** 2026-07-05

---

## 1. Przegląd

NexusAI implementuje **Event Sourcing** jako podstawowy mechanizm trwałości dla zdarzeń domenowych. System opiera się na:

- **msgspec** — serializacja Tagged Unions (MsgPack) dla zdarzeń
- **SQLite** — append-only event store z parquet archiving
- **NATS JetStream** — publish/subscribe strumieni zdarzeń między agentami
- **CQRS Projections** — denormalizowane widoki read-side

```
┌─────────────────────────────────────────────────────┐
│                     Event Sourcing                   │
│                                                       │
│  ┌──────────────────┐    ┌──────────────────┐        │
│  │   DomainEvents    │───▶│  AsyncEventStore │        │
│  │  (10 event types) │    │  (append-only)   │        │
│  └──────────────────┘    └────────┬─────────┘        │
│                                    │                  │
│         ┌──────────────────────────┤                  │
│         │                          │                  │
│         ▼                          ▼                  │
│  ┌─────────────┐          ┌──────────────┐           │
│  │ JetStreamBus │          │   Parquet    │           │
│  │  (NATS PUB)  │          │   Archiving  │           │
│  └──────┬──────┘          └──────────────┘           │
│         │                                              │
│         ▼                                              │
│  ┌──────────────┐      ┌─────────────────────┐       │
│  │ JetStream     │──────▶  CQRS Projections  │       │
│  │ Consumer      │      │  (Invoice,Decision) │       │
│  └──────────────┘      └─────────────────────┘       │
└─────────────────────────────────────────────────────┘
```

---

## 2. Domain Events — Definicje

Wszystkie zdarzenia dziedziczą po `DomainEvent` (msgspec.Struct z Tagged Unions) i są automatycznie rejestrowane w `DomainEvent._registry` przez `__init_subclass__`.

### 2.1 Base Event

```python
class DomainEvent(msgspec.Struct, kw_only=True, frozen=True, tag_field="event_type"):
    event_id: str          # uuid.uuid4().hex (automatyczny)
    timestamp: str         # pendulum.now("UTC").isoformat() (automatyczny)
    aggregate_id: str      # ID agregatu
    aggregate_type: str    # Typ agregatu (np. "invoice", "decision")
    version: int           # Numer wersji (kolejność w strumieniu)
    metadata: dict[str, Any]  # Dowolne metadane

    _event_tag: ClassVar[str] = ""
    _event_description: ClassVar[str] = ""
    _registry: ClassVar[dict] = {}
```

### 2.2 Lista zdarzeń

| Zdarzenie | Tag | Opis | Pola specyficzne |
|---|---|---|---|
| `InvoiceCreated` | `invoice.created` | Faktura utworzona (po OCR) | number, contractor_nip, amount_net/gross, currency, category, issue_date, file_path |
| `InvoiceSubmitted` | `invoice.submitted` | Faktura przesłana do decyzji | amount_gross, contractor_nip |
| `InvoiceApproved` | `invoice.approved` | Faktura zatwierdzona | approved_by, trust_score, decision_level |
| `InvoiceRejected` | `invoice.rejected` | Faktura odrzucona | rejected_by, reason |
| `InvoiceBlocked` | `invoice.blocked` | Faktura zablokowana (RiskGuard) | blocked_by, reason, risk_score |
| `InvoicePaid` | `invoice.paid` | Faktura opłacona (TigerBeetle) | amount_gross, paid_at, transaction_id |
| `DecisionMade` | `decision.made` | Decyzja Rady Agentów | decision, trust_score, ai_confidence, alpha/beta/gamma_vote, decision_pattern, reasoning |
| `DecisionOverridden` | `decision.overridden` | Decyzja nadpisana przez usera | original_decision, user_decision, user_id |
| `OutboxEventEmitted` | `outbox.emitted` | Zdarzenie outbox wyemitowane | outbox_event_type, payload_json |
| `NotificationSent` | `notification.sent` | Powiadomienie wysłane | user_id, notification_type, title, channels |

### 2.3 Serializacja

```python
def encode_event(event: DomainEvent) -> bytes:
    return msgspec.msgpack.encode(event)       # MsgPack binary

def decode_event(data: bytes) -> DomainEvent:
    return msgspec.msgpack.decode(data, type=DomainEvent)

def domain_event_from_dict(data: dict) -> DomainEvent:
    return msgspec.convert(data, DomainEvent, strict=False)
```

### 2.4 JSON Schema Registry

System automatycznie generuje **JSON Schema (draft 2020-12)** dla każdego zdarzenia:

```python
class DomainEventSchemaRegistry:
    def get_schema(self, event_type: str) -> dict | None  # Schema dla konkretnego eventu
    def get_all(self) -> dict[str, dict]                   # Wszystkie schematy
    def refresh(self) -> None                              # Odświeżenie cache

get_schema_summary() -> dict  # Pełny summary: total_events, event_types, base_schema, schemas
```

- Każdy schemat zawiera `$id: https://nexusai.app/schemas/events/{type}.json`
- Automatyczna rejestracja przez `__init_subclass__` — zero boilerplate

---

## 3. AsyncEventStore — Append-Only Store

**Plik:** `nexus_ai/events/event_store.py`

Append-only event store oparty na **SQLite z sqlcipher** (opcjonalne szyfrowanie) z wsparciem dla **Parquet archiving** dla starych zdarzeń.

### 3.1 Schemat bazy

```sql
-- Główny strumień zdarzeń
CREATE TABLE IF NOT EXISTS event_stream (
    event_id TEXT PRIMARY KEY,
    aggregate_type TEXT NOT NULL,
    aggregate_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    version INTEGER NOT NULL,
    timestamp TEXT NOT NULL,
    data BLOB NOT NULL,                          -- MsgPack-encoded event
    metadata_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Snapshoty agregatów
CREATE TABLE IF NOT EXISTS snapshots (
    aggregate_id TEXT NOT NULL,
    aggregate_type TEXT NOT NULL,
    version INTEGER NOT NULL,
    state_json TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    PRIMARY KEY (aggregate_id, aggregate_type)
);

-- Checkpointy projekcji
CREATE TABLE IF NOT EXISTS projection_checkpoints (
    projection_name TEXT PRIMARY KEY,
    last_event_id TEXT,
    last_version INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT NOT NULL
);
```

Indeksy:
- `idx_events_aggregate` — (aggregate_type, aggregate_id, version) — szybki odczyt strumienia
- `idx_events_type` — (event_type, timestamp) — filtrowanie po typie
- `idx_events_timestamp` — (timestamp) — zakresy czasowe

### 3.2 API

| Metoda | Opis |
|---|---|
| `append_events(aggregate_type, aggregate_id, events, expected_version)` | Append z **optymistyczną blokadą** (OC check przez SAVEPOINT) |
| `read_events(aggregate_type, aggregate_id, from_version, to_version, limit)` | Odczyta strumień agregatu |
| `read_events_by_type(event_type, since, limit)` | Odczyta zdarzenia po typie |
| `read_stream(aggregate_type, aggregate_id)` | Pełny strumień agregatu (wrapping) |
| `get_version(aggregate_type, aggregate_id)` | Bieżąca wersja agregatu |
| `count_events(aggregate_type, event_type)` | Licznik zdarzeń |
| `save_snapshot(aggregate_type, aggregate_id, version, state)` | Zapisz snapshot |
| `load_snapshot(aggregate_type, aggregate_id)` | Wczytaj snapshot |
| `get/update_checkpoint(projection_name, ...)` | Checkpointy projekcji |
| `list_projections()` | Lista checkpointów |
| `archive_events_to_parquet(before_days, aggregate_type, batch_size)` | Archiwizuj stare zdarzenia do **Parquet (ZSTD, level 7)** |
| `query_archived_events(aggregate_type, event_type, since, limit)` | Zapytaj zarchiwizowane Parquet przez **DuckDB** |
| `get_stats()` | Statystyki: total_events, snapshots, projections, archiwum |
| `close()` | PRAGMA optimize + zamknięcie połączenia |

### 3.3 Optymistyczne blokady (OC)

```python
async def append_events(self, aggregate_type, aggregate_id, events, expected_version=None):
    # SAVEPOINT dla transakcyjności
    conn.execute("SAVEPOINT event_append;")
    try:
        if expected_version is not None:
            current = SELECT MAX(version) FROM event_stream WHERE aggregate_type=? AND aggregate_id=?
            if current != expected_version:
                ROLLBACK TO SAVEPOINT
                raise ValueError(f"OC violation: expected {expected_version}, current {current}")
        # Insert eventów...
        RELEASE SAVEPOINT event_append;
    except:
        ROLLBACK TO SAVEPOINT event_append;
        raise
```

### 3.4 Parquet Archiving

Zdarzenia starsze niż N dni są automatycznie archiwizowane do plików **Parquet**:

```
event_archive_parquet/
  year=2026/
    month=01/
      day=15/
        events_20260101_120000.parquet
      day=20/
        events_20260101_140000.parquet
```

- **Partycjonowanie Hive-style**: year/month/day dla szybkich zapytań
- **Kompresja**: ZSTD level 7
- **Zapytania przez DuckDB**: `read_parquet('archive/**/*.parquet')`
- Batch po 10 000 zdarzeń

### 3.5 Telemetria

Każdy append rejestruje metrykę OpenTelemetry:
```python
record_event_store_append(aggregate_type="invoice", event_count=3, duration_seconds=0.042)
```

---

## 4. JetStreamEventBus — NATS Pub/Sub

**Plik:** `nexus_ai/events/jetstream_bus.py`

Publikuje zdarzenia domenowe do **NATS JetStream** z automatycznym reconnectem i graceful degradation.

### 4.1 Konfiguracja strumieni

| Stream | Tematy | Retention | Max Age | Max Size | Replikacja |
|---|---|---|---|---|---|
| `nexus-invoice` | `nexus-invoice.>` | limits | 90 dni | 64 MB | 1 |
| `nexus-decision` | `nexus-decision.>` | limits | 90 dni | 1 MB | 1 |
| `nexus-outbox` | `nexus-outbox.>` | limits | 30 dni | 1 MB | 1 |
| `nexus-files` | `nexus-files.>`, `nexus-objects.>` | limits | 365 dni | 256 MB | 1 |
| `nexus-config` | `nexus-config.>`, `nexus-kv.>` | limits | 365 dni | 1 MB | 1 |
| `nexus-invoice-mirror` | (mirror) | limits | 365 dni | 64 MB | 1 |
| `nexus-audit` | (sources) | limits | 5 lat | 64 MB | 1 |

- **Mirror**: `nexus-invoice-mirror` — mirror `nexus-invoice` dla izolacji projekcji
- **Sources**: `nexus-audit` — agreguje wszystkie zdarzenia z invoice + decision + outbox
- **Cechy**: Compresja S2, DiscardPolicy.OLD, duplicate_window 120s, deny_delete na audit

### 4.2 API JetStreamEventBus

| Metoda | Opis |
|---|---|
| `connect()` | Nawiąż połączenie (auto-reconnect) |
| `publish(event)` | Publikuj pojedynczy event do `nexus-{type}.{event_type}` |
| `publish_batch(events)` | Batch publish (z obsługą błędów per-event) |
| `get_kv_store(bucket_name)` | Pobierz/stwórz Key-Value store |
| `get_object_store(bucket_name)` | Pobierz/stwórz Object store |
| `get_message(stream_name, seq)` | Pobierz wiadomość po sequence number |
| `get_last_message(stream_name)` | Pobierz ostatnią wiadomość |
| `purge_stream(stream_name)` | Wyczyść strumień |
| `delete_message(stream_name, seq)` | Usuń pojedynczą wiadomość |
| `seal_stream(stream_name)` | Zapieczętuj strumień (read-only) |
| `close()` | Zamknij połączenie |

### 4.3 Reconnect Strategy

```
Exponential backoff z jitterem:
  - Base delay: 1s
  - Max delay: 30s
  - Max attempts: 5 (-1 = nieskończone)
  - Jitter: 0.8–1.2x losowy
  
  Callbacki:
    - disconnected_cb → warning log
    - reconnected_cb → info log
    - closed_cb → info log
```

### 4.4 Global Singleton

```python
def get_event_bus(nats_servers=None, connect_timeout=10.0, reconnect_attempts=5) -> JetStreamEventBus:
    """Thread-safe global singleton."""
```

### 4.5 JetStreamConsumer

**Plik:** `nexus_ai/events/jetstream_bus.py`

Konsumuje eventy z JetStream i dispatchuje do handlerów:

```python
class ConsumerConfig(Struct):
    stream_name: str
    consumer_name: str
    deliver_policy: str = "all"       # all, last, new, by_start_time
    filter_subject: str = ""
    max_deliver: int = 3              # Max retries
    ack_wait: int = 30                # Ack timeout (s)
    max_ack_pending: int = 100
    idle_heartbeat: int = 10
    backoff_delays: list[int]         # Backoff między retries
    replay_policy: str = "instant"    # instant, original
```

- Pull-based subscription z fetch batch=10, timeout=5s
- Auto-decode eventów przez `decode_event()`
- NAK z opóźnieniem przy błędzie (`nak(delay=5)`)
- Anulowanie przez `anyio.CancelledError`

---

## 5. CQRS Projections

**Plik:** `nexus_ai/events/projections.py`

### 5.1 BaseProjection[T]

Generyczna klasa bazowa dla projekcji CQRS:

```python
class BaseProjection[T: DomainEvent](AsyncBaseService):
    schema_sql: ClassVar[str]          # DDL dla tabeli widoku
    aggregate_type: ClassVar[str]      # Typ agregatu w EventStore
    pragma_config: tuple = (           # PRAGMY SQLite
        "cache_size = -25600",         # 25 MB cache
        "temp_store = MEMORY",
        "mmap_size = 2147483648",      # 2 GB mmap
    )

    async def rebuild(self) -> int     # Truncate + reprocess wszystkich eventów
    async def process(self) -> int     # Procesuj nowe eventy od checkpointu (batch 500)
    async def _apply_event(event)      # Aplikuj event na widok (match/case)
    async def get_stats() -> dict      # Statystyki widoku
```

### 5.2 InvoiceProjection

Denormalizowany widok faktur dla szybkich zapytań:

```sql
CREATE TABLE invoice_read_model (
    invoice_id TEXT PRIMARY KEY,
    number TEXT, contractor_nip TEXT, contractor_name TEXT,
    amount_net REAL, amount_gross REAL,
    currency TEXT DEFAULT 'PLN', category TEXT, issue_date TEXT,
    file_path TEXT, status TEXT DEFAULT 'created',
    current_version INTEGER DEFAULT 0,
    approved_by TEXT, rejected_by TEXT, blocked_reason TEXT,
    paid_at TEXT, decision TEXT, trust_score REAL DEFAULT 0,
    created_at TEXT, updated_at TEXT
);
```

- **FTS5**: pełnotekstowe wyszukiwanie po numerze, kontrahencie, kategorii
- **Triggers**: automatyczna synchronizacja FTS na INSERT/UPDATE/DELETE
- **Indeksy warunkowe**: `idx_irm_blocked WHERE status='blocked'`
- Obsługuje wszystkie stany faktury: created → submitted → approved/rejected/blocked → paid

### 5.3 DecisionProjection

Analityczny widok decyzji:

```sql
CREATE TABLE decision_analytics (
    decision_id TEXT PRIMARY KEY,
    invoice_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    decision TEXT, trust_score REAL, ai_confidence REAL,
    alpha_vote TEXT, beta_vote TEXT, gamma_vote TEXT,
    decision_pattern TEXT, reasoning TEXT,
    original_decision TEXT, user_decision TEXT, user_id TEXT,
    version INTEGER DEFAULT 0, timestamp TEXT
);
```

- Śledzi zarówno `DecisionMade` jak i `DecisionOverridden`
- Indeks warunkowy dla nadpisanych decyzji: `idx_da_overridden WHERE event_type='decision.overridden'`

### 5.4 Query Builder

```python
def _query_builder(params: dict, base_sql="WHERE 1=1", order="updated_at DESC") -> tuple[str, list]:
    """Generyczny builder WHERE dla zapytań projekcji."""
```

---

## 6. ProjectionWorker

**Plik:** `nexus_ai/events/projection_worker.py`

Samodzielny proces konsumujący eventy z NATS JetStream i aktualizujący projekcje CQRS.

### 6.1 Architektura

```
ProjectionWorker
├── NATS JetStream Consumer (primary)
│   ├── InvoiceProjection → nexuse-invoice stream
│   └── DecisionProjection → nexuse-decision stream
└── Fallback Poll Loop (co 30s)
    └── Direct EventStore query (gdy NATS niedostępny)
```

### 6.2 API

| Metoda | Opis |
|---|---|
| `add_projection(projection, stream_name, filter_subject)` | Rejestruj projekcję |
| `start()` | Uruchom konsumentów + fallback |
| `stop()` | Anuluj taski + zamknij NATS |
| `handle_signal(sig, frame)` | Signal handler dla graceful shutdown |
| `get_status()` | Status: NATS connected, active projections, task count |

### 6.3 Fallback Poll

Gdy NATS jest niedostępny, worker polluje bezpośrednio EventStore co **30 sekund**:

```python
async def _fallback_poll_loop(self):
    while True:
        await anyio.sleep(self._fallback_poll_seconds)  # 30s
        for projection in self._projections:
            processed = await projection.process()
            if processed > 0:
                logger.info("[FALLBACK] %s processed %d events", ...)
```

### 6.4 Default Worker Factory

```python
async def create_default_worker(
    base_dir=None, nats_servers=None,
    enable_fallback=True, poll_interval=1.0,
    batch_size=10, fallback_poll_seconds=30.0
) -> ProjectionWorker:
    # Tworzy EventStore + InvoiceProjection + DecisionProjection
    # Rejestruje obie projekcje w workerze
```

---

## 7. Diagram przepływu zdarzeń

```
Użytkownik/OCR
     │
     ▼
┌─────────────┐     ┌──────────────────┐
│ Decision     │────▶│ DomainEvent      │
│ Engine       │     │ DecisionMade()   │
└─────────────┘     └────────┬─────────┘
                             │
               ┌─────────────┼─────────────┐
               ▼             ▼             ▼
        ┌────────────┐ ┌──────────┐ ┌────────────┐
        │ EventStore  │ │JetStream │ │  Schema    │
        │(append-only)│ │(publish) │ │  Registry  │
        └──────┬─────┘ └────┬─────┘ └────────────┘
               │             │
               ▼             ▼
        ┌────────────┐ ┌──────────────┐
        │  Parquet   │ │  Projection  │
        │  Archive   │ │  Worker      │
        └────────────┘ └──────┬───────┘
                              ▼
                    ┌──────────────────┐
                    │ DecisionAnalytics│
                    │ (CQRS View)      │
                    └──────────────────┘
```

---

## 8. Event Versioning i Schema Evolution

<!-- UZUPEŁNIONE: dodano sekcję wersjonowania eventów -->

### 8.1 Problem

Zdarzenia domenowe ewoluują w czasie — dodawane są nowe pola, zmieniają się typy, usuwane są nieużywane atrybuty. W systemie Event Sourcing, gdzie stare zdarzenia pozostają w strumieniu, trzeba obsługiwać wiele wersji tego samego typu eventu.

### 8.2 Strategia w NexusAI

NexusAI stosuje **hybrydowe podejście**: tolerancyjny odczyt (forward/backward compatibility) + jawna migracja dla breaking changes.

```
Poziom 0: Tolerancyjny odczyt (msgspec strict=False)
  - Nowe pola: ignorowane przy deserializacji starych eventów
  - Brakujące pola: przyjmują wartość domyślną z class definition
  - Działanie: automatyczne, zero effort

Poziom 1: Soft migration (przy odczycie)
  - Funkcja upgrade(v1) → v2 przy read_events()
  - Stare eventy pozostają w DB w oryginalnej formie

Poziom 2: Hard migration (rewrite)
  - Skrypt migracyjny, który czyta wszystkie eventy i zapisuje w nowej wersji
  - Wymaga downtime
  - Stosowane tylko przy breaking changes (zmiana tagu, usunięcie pola)
```

### 8.3 Mechanizm w kodzie

```python
# Poziom 0: msgspec strict=False już obsługuje brakujące pola
@dataclass
class InvoiceCreated(DomainEvent, tag="invoice.created"):
    number: str = ""               # Domyślna wartość dla starych eventów
    amount_net: Decimal = Decimal("0.00")
    new_field: str = ""            # Dodane w v2 — stary event = ""

# Poziom 1: upgrade przy odczycie (w EventStore)
async def read_events(self, ...) -> list[DomainEvent]:
    raw_events = await self._fetch_raw()
    return [self._upgrade_event(e) for e in raw_events]

def _upgrade_event(self, event: DomainEvent) -> DomainEvent:
    match event:
        case InvoiceCreated() if event.version < 2:
            # Uzupełnij brakujące pole dla v1
            event.new_field = event.old_field  # type: ignore
        # ...
    return event
```

### 8.4 Zasady wersjonowania

| Zmiana | Typ | Strategia | Przykład |
|---|---|---|---|
| Dodanie opcjonalnego pola | Non-breaking | Poziom 0 (domyślna wartość) | `new_field: str = ""` |
| Dodanie wymaganego pola | Breaking | Poziom 2 (hard migration) | Wymaga skryptu migracyjnego |
| Zmiana typu pola | Breaking | Poziom 2 | `str` → `Decimal` wymaga konwersji |
| Zmiana nazwy pola | Breaking | Poziom 1 + alias | `old_field` → `new_field` z mapowaniem |
| Usunięcie pola | Non-breaking | Poziom 0 (pole ignorowane) | Stare eventy mają dane, ale kod ich nie czyta |
| Zmiana tagu eventu | Breaking | Poziom 2 | Nowy tag = nowa klasa, stary tag = deprecated |

### 8.5 Konserwatywne zasady

1. **Never mutate** — nigdy nie modyfikuj zapisanego eventu w SQLite
2. **Append-only** — nie usuwaj eventów (chyba że archiwizacja Parquet)
3. **One version forward** — kod obsługuje max 2 wersje tego samego eventu
4. **Version in metadata** — przechowuj `event_version` w `metadata` dla łatwej identyfikacji
5. **Snapshot speed-up** — dla agregatów z >100 eventami, używaj snapshotów (unikasz replayu starych wersji)

### 8.6 Przykład — migracja InvoiceCreated v1 → v2

```python
# v1 (2026-01): original definition
# v2 (2026-07): added new_field, changed category to enum

class InvoiceCreated(DomainEvent, tag="invoice.created"):
    number: str = ""
    contractor_nip: str = ""
    amount_net: Decimal = Decimal("0.00")
    category: str = ""              # v1: dowolny string
    new_field: str = ""             # v2: nowe pole (domyślnie puste)

@upgrade_event
def upgrade_v1_to_v2(event: InvoiceCreated) -> InvoiceCreated:
    """Upgrade v1 → v2: mapuj starą kategorię na nową."""
    CATEGORY_MAP = {
        "usługi": "services", "towary": "goods", "leasing": "leasing",
    }
    event.category = CATEGORY_MAP.get(event.category.lower(), event.category)
    return event
```

---

## 9. Event Store vs JetStream

| Cecha | AsyncEventStore | JetStreamEventBus |
|---|---|---|
| **Rola** | Trwałość (append-only) | Komunikacja (pub/sub) |
| **Storage** | SQLite + Parquet | NATS JetStream (file) |
| **Retention** | Nieskończona (archiwizacja) | Konfigurowalna (30–365 dni) |
| **Zapytania** | SQL + DuckDB (Parquet) | Seq number |
| **Obsługa błędów** | SAVEPOINT / OC | Nak z backoffem |
| **Gwarancje** | ACID (sqlite3) | At-least-once (JetStream) |
| **Szyfrowanie** | SQLCipher (opcjonalnie) | TLS |
| **Schema evolution** | Poziom 0–2 (tolerancyjny + upgrade) | Tagged Unions (msgspec) |

---

## 10. Najlepsze praktyki

1. **Zdarzenia są niezmienne** — nigdy nie modyfikuj zapisanego eventu
2. **Append-only** — nie usuwaj eventów (chyba że archiwizacja)
3. **Snapshoty** — dla agregatów z >100 eventami, używaj snapshotów
4. **OC wersji** — zawsze używaj `expected_version` przy appendzie
5. **Fallback** — ProjectionWorker ma fallback poll gdy NATS niedostępny
6. **Mirror strumieni** — używaj mirror do izolacji projekcji od głównego strumienia
7. **Parquet archiving** — archiwizuj eventy starsze niż 30 dni
8. **FTS5** — używaj indeksów pełnotekstowych dla wyszukiwania w projekcjach
9. **Event versioning** — stosuj Poziom 0 (tolerancyjny) dla non-breaking, Poziom 2 dla breaking changes
10. **Upgrade przy odczycie** — nigdy nie modyfikuj eventów w store, upgrade'uj w warstwie odczytu

---

> **Zobacz również:**
> - [`ARCHITECTURE.md`](ARCHITECTURE.md) — C4 diagramy, ADR-003 (NATS)
> - [`FOUNDATION.md`](FOUNDATION.md) — AsyncBaseService (klasa bazowa dla projekcji)
> - [`MODULES.md`](MODULES.md) — DecisionEngine, silniki reguł
> - [`DATABASE.md`](DATABASE.md) — SQLite, DuckDB
