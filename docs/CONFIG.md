# ⚙️ Konfiguracja systemu — TOML profile i zmienne środowiskowe

> **Plik:** `nexus_ai/config/`
> **Status:** Stabilny · **Wersja:** 3.0.0-dev
> **Ostatnia aktualizacja:** 2026-07-05

---

## 1. Przegląd

NexusAI używa hierarchicznej konfiguracji opartej na plikach **TOML** z możliwością nadpisywania przez zmienne środowiskowe.

```
nexus_ai/config/
├── base.toml           # ⭐ Konfiguracja bazowa (wspólna dla wszystkich)
├── dev.toml            # Nadpisania developerskie
├── prod.toml           # Nadpisania produkcyjne
├── protocols.toml      # Protokoły decyzyjne AI
└── version.json        # ⭐ Wersja + komponenty systemu
```

### Hierarchia ładowania

```
base.toml (zawsze)
  ↓
dev.toml LUB prod.toml (zależnie od NEXUS_ENV)
  ↓
Zmienne środowiskowe (override — najwyższy priorytet)
```

**Zasada:** Im wyżej w hierarchii, tym niższy priorytet. Zmienne env zawsze wygrywają.

---

## 2. base.toml — Konfiguracja bazowa

### 2.1 Struktura

```toml
[app]
name = "NexusAI"
version = "3.0.0-dev"
debug = false
environment = "production"

[server]
host = "127.0.0.1"
port = 8000
workers = 4
backpressure = 100

[database]
sqlite_path = "app_data/nexus.db"
duckdb_path = "app_data/analytics.duckdb"
events_path = "app_data/events.db"
vector_db_path = "app_data/vectors.db"

[tigerbeetle]
data_path = "app_data/tigerbeetle.bin"
replica_count = 1
cluster_id = 0

[nats]
host = "127.0.0.1"
port = 4222
connect_timeout = 10

[opa]
host = "127.0.0.1"
port = 8181
policy_path = "nexus_ai/tax/rules.rego"

[ocr]
engines = ["tesseract", "paddleocr"]
use_gpu = true
max_pages = 5

[ai]
models_dir = "models"
inference_ttl_seconds = 300
n_ctx = 4096
n_threads = 4
n_gpu_layers = 0

[monitoring]
otel_enabled = true
sentry_dsn = ""
metrics_port = 9090
```

### 2.2 Wszystkie sekcje

| Sekcja | Opis | Kluczowe parametry |
|---|---|---|
| `[app]` | Podstawowa konfiguracja | name, version, debug, environment |
| `[server]` | Serwer API (Granian) | host, port, workers, backpressure |
| `[database]` | Bazy danych | sqlite_path, duckdb_path, events_path, vector_db_path |
| `[tigerbeetle]` | TigerBeetle ledger | data_path, replica_count, cluster_id |
| `[nats]` | NATS JetStream | host, port, connect_timeout |
| `[opa]` | OPA Rego engine | host, port, policy_path |
| `[ocr]` | Pipeline OCR | engines, use_gpu, max_pages |
| `[ai]` | AI inference | models_dir, inference_ttl_seconds, n_ctx, n_threads |
| `[monitoring]` | OpenTelemetry + Sentry | otel_enabled, sentry_dsn, metrics_port |
| `[security]` | Bezpieczeństwo | jwt_secret, sqlcipher_key, argon2_memory |
| `[integrations]` | API zewnętrzne | ksef_url, gus_url, nbp_url |
| `[logging]` | Logowanie | level, format, otel_enabled |

---

## 3. Profile (dev / prod)

### 3.1 dev.toml

```toml
[app]
debug = true
environment = "development"

[server]
host = "127.0.0.1"
port = 8000
workers = 1

[nats]
port = 4222
```

### 3.2 prod.toml

```toml
[app]
debug = false
environment = "production"

[server]
host = "0.0.0.0"
port = 8000
workers = 4
backpressure = 100

[monitoring]
otel_enabled = true
sentry_dsn = "${SENTRY_DSN}"  # Z env
metrics_port = 9090
```

---

## 4. Zmienne środowiskowe

Wszystkie zmienne środowiskowe mają prefix `NEXUS_`:

| Zmienna | Odpowiednik TOML | Domyślnie | Opis |
|---|---|---|---|
| `NEXUS_ENV` | `app.environment` | `production` | `development` / `production` |
| `NEXUS_DEBUG` | `app.debug` | `false` | Włącz tryb debug |
| `NEXUS_HOST` | `server.host` | `127.0.0.1` | Bind address API |
| `NEXUS_PORT` | `server.port` | `8000` | Port API |
| `NEXUS_WORKERS` | `server.workers` | `4` | Liczba workerów Granian |
| `NEXUS_DB_PATH` | `database.sqlite_path` | `app_data/nexus.db` | Ścieżka SQLite |
| `NEXUS_DUCKDB_PATH` | `database.duckdb_path` | `app_data/analytics.duckdb` | Ścieżka DuckDB |
| `NEXUS_EVENT_STORE_KEY` | — | — | Klucz SQLCipher dla EventStore |
| `NEXUS_SQLCIPHER_KEY` | `security.sqlcipher_key` | — | Klucz AES-256 SQLCipher |
| `NEXUS_JWT_SECRET` | `security.jwt_secret` | — | Sekret JWT |
| `NEXUS_ADMIN_PASSWORD` | — | losowy 16-znakowy | Hasło admina (seed) |
| `NEXUS_OCR_ENGINES` | `ocr.engines` | `tesseract,paddleocr` | Wybór silników OCR |
| `NEXUS_PADDLE_GPU` | `ocr.use_gpu` | `true` | GPU dla PaddleOCR |
| `NEXUS_NATS_HOST` | `nats.host` | `127.0.0.1` | Host NATS |
| `NEXUS_NATS_PORT` | `nats.port` | `4222` | Port NATS |
| `NEXUS_TB_DATA` | `tigerbeetle.data_path` | `app_data/tigerbeetle.bin` | Ścieżka TigerBeetle |
| `NEXUS_OPA_HOST` | `opa.host` | `127.0.0.1` | Host OPA |
| `NEXUS_OPA_PORT` | `opa.port` | `8181` | Port OPA |
| `NEXUS_MODELS_DIR` | `ai.models_dir` | `models` | Katalog modeli GGUF |
| `LLAMA_N_CTX` | `ai.n_ctx` | `4096` | Kontekst LLM |
| `LLAMA_N_THREADS` | `ai.n_threads` | `4` | Wątki CPU dla LLM |
| `LLAMA_N_GPU_LAYERS` | `ai.n_gpu_layers` | `0` | Warstwy GPU (-1=wszystkie) |
| `SENTRY_DSN` | `monitoring.sentry_dsn` | — | DSN Sentry |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | — | — | Endpoint OpenTelemetry |

---

## 5. protocols.toml — Protokoły decyzyjne

Definiuje zachowanie agentów AI:

```toml
[protocols.default]
min_confidence_auto_post = 0.92
min_confidence_suggest = 0.70
max_triage_items = 5
decision_timeout_seconds = 30

[protocols.ocr]
min_engines = 2
require_consensus = true
consensus_threshold = 0.85
confidence_weights = { tesseract = 0.8, paddleocr = 1.0, doctr = 0.9, easyocr = 0.7 }

[protocols.security]
max_login_attempts = 5
lockout_minutes = 15
require_2fa = false
```

---

## 6. version.json

```json
{
  "version": "3.0.0-dev",
  "release_date": "2026-07-05",
  "components": {
    "python": "3.13.2 (free-threaded)",
    "rust": "1.78+",
    "granian": "1.0+",
    "litestar": "2.8+",
    "tigerbeetle": "0.16.16",
    "nats": "2.10.22",
    "opa": "0.68.0",
    "sqlcipher": "4.5+",
    "llama-cpp-python": "0.3+"
  },
  "checksums": {
    "nexus-crypto": "sha256:abc123...",
    "granian": "sha256:def456..."
  }
}
```

Plik `version.json` jest używany przez:
- **Endpoint `/health`** — raportowanie wersji
- **OTA Updater** — sprawdzanie dostępności aktualizacji
- **OpenTelemetry** — metadane dla traces

---

> **Zobacz również:**
> - [`INSTALLATION.md`](INSTALLATION.md) — zmienne środowiskowe, profile
> - [`ARCHITECTURE.md`](ARCHITECTURE.md) — stack technologiczny
> - [`DEPLOYMENT.md`](DEPLOYMENT.md) — konfiguracja produkcyjna
> - [`SCRIPTS.md`](SCRIPTS.md) — skrypty CLI używające configu
