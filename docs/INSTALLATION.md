# ⚙️ Instalacja i konfiguracja

> **Cel:** Szczegółowa instrukcja instalacji NexusAI od zera.  
> **Kiedy czytać:** Przy konfiguracji nowego środowiska (developer/serwer/CI).

---

## 1. Wymagania systemowe

### 1.1 Sprzęt

| Parametr | Minimum | Zalecane |
|---|---|---|
| **CPU** | 4 rdzenie x86_64 z AVX2 | 8+ rdzeni |
| **RAM** | 4 GB | **6 GB** |
| **Dysk** | 5 GB SSD | 10 GB SSD |
| **GPU** | Niewymagane | — |

### 1.2 System operacyjny

| OS | Wsparcie |
|---|---|
| **Linux x86_64** | ✅ Pełne (Ubuntu 22.04+, Debian 12+) |
| **Linux aarch64** | ⚠️ Eksperymentalne (Raspberry Pi 5, Apple Silicon, Termux) — patrz [TROUBLESHOOTING.md](TROUBLESHOOTING.md#aarch64-i-termux) |
| **Windows x64** | ✅ Pełne (Windows 10+) |
| **macOS** | ⚠️ Deweloperskie (brak instalatora Inno Setup) |

### 1.3 Narzędzia wymagane przed instalacją

```bash
# Linux (Ubuntu/Debian)
sudo apt install build-essential gcc cmake curl git unzip

# Linux (Fedora/RHEL)
sudo dnf install gcc make cmake curl git unzip
```

### 1.4 Pre-commit hooks (dla developerów)

Po sklonowaniu repozytorium zainstaluj pre-commit:

```bash
pip install pre-commit
pre-commit install
```

Pre-commit automatycznie uruchamia przy każdym `git commit`:
- **Ruff** — linter + auto-fix (`ruff-lint`, `ruff-format`)
- **mypy** — strict type checking (`--strict`, `--ignore-missing-imports`)
- **Hooks ogólne** — trailing whitespace, end-of-file, YAML/TOML validity, merge conflicts, large files (>2 MB)

Konfiguracja w `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
        args: [--strict, --ignore-missing-imports]
```

---

## 2. Instalacja krok po kroku

### Krok 1: Instalacja pixi

```bash
# Linux / macOS
curl -fsSL https://pixi.sh/install.sh | sh
source ~/.bashrc

# Windows (PowerShell)
irm https://pixi.sh/install.ps1 | iex

# Weryfikacja
pixi --version  # powinno zwrócić >= 0.40
```

### Krok 2: Klonowanie repozytorium

```bash
git clone https://github.com/Gorski-Maciej/NexusAI.git
cd NexusAI
```

### Krok 3: Instalacja środowiska

```bash
pixi install
```

**Co się dzieje:**
1. Pixi tworzy izolowane środowisko `.pixi/`
2. Instaluje Python 3.13t (free-threaded) z conda-forge
3. Instaluje wszystkie pakiety PyPI z `pyproject.toml`
4. Instaluje `nexus-crypto` jako pakiet pure-Python (bez kompilacji Rusta!)

> ⏱️ Pierwsze uruchomienie: ~2 minuty. Kolejne: < 10 sekund (cache).
>
> **Uwaga:** Rust, Tesseract, OpenCV i OCR są opcjonalne — dostępne przez `pixi install --environment ocr`. Moduł kryptograficzny `nexus-crypto` działa jako pure-Python fallback bez potrzeby kompilacji Rusta.

### Krok 4: Migracje bazy danych

```bash
pixi run migrate
```

Tworzy `app_data/nexus.db` z wszystkimi tabelami i seedem RBAC.

### Krok 5: Pobranie modeli AI (opcjonalne)

```bash
pixi run download-models
```

Pobiera modele GGUF do `models/`. Sumy SHA-256 weryfikowane automatycznie.

### Krok 6: Uruchomienie

```bash
pixi run dev    # Pełne środowisko (NATS + TigerBeetle + API + Worker)
pixi run api    # Tylko serwer API
```

---

## 3. Zmienne środowiskowe

### 3.1 Plik `.env` (opcjonalny, pixi ustawia własne)

```bash
# .env.example — wszystkie zmienne środowiskowe NexusAI

# ── Podstawowa konfiguracja ──────────────────────────────────────────────────
NEXUS_LOG_LEVEL=info              # debug|info|warn|error
NEXUS_HOST=127.0.0.1              # Adres nasłuchiwania API
NEXUS_PORT=8000                   # Port API
NEXUS_DB_PATH=app_data/nexus.db   # Ścieżka do bazy SQLite
NEXUS_UNIX_SOCKET=/tmp/nexus-api.sock  # UNIX socket (szybszy niż TCP)
NEXUS_WATCH_INTERVAL=5            # Interwał monitorowania zmian (sekundy)

# ── Granian (serwer ASGI) ───────────────────────────────────────────────────
NEXUS_GRANIAN_BACKLOG=2048        # Kolejka połączeń
NEXUS_GRANIAN_BACKPRESSURE=100    # Limit równoczesnych żądań
NEXUS_GRANIAN_HTTP=auto           # HTTP/1 lub HTTP/2 (auto-wykrywanie)
NEXUS_GRANIAN_WORKERS=1           # Liczba workerów (1=desktop)
NEXUS_GRANIAN_RUNTIME_THREADS=2   # Wątki runtime
NEXUS_GRANIAN_BLOCKING_THREADS=4  # Wątki blokujące
NEXUS_GRANIAN_METRICS=true        # Włącz metryki Prometheus
NEXUS_GRANIAN_METRICS_ADDRESS=127.0.0.1
NEXUS_GRANIAN_METRICS_PORT=9090
NEXUS_GRANIAN_RESPAWN=true        # Automatyczny restart workera
NEXUS_GRANIAN_GRACEFUL_SHUTDOWN=30 # Czas na graceful shutdown

# ── NATS ────────────────────────────────────────────────────────────────────
NEXUS_NATS_URL=nats://127.0.0.1:4222
NEXUS_NATS_CREDS_FILE=            # Plik credentials (opcjonalnie)

# ── TigerBeetle ──────────────────────────────────────────────────────────────
NEXUS_TB_ADDRESS=/tmp/nexus-tb.sock  # UNIX socket
NEXUS_TB_CLUSTER=0

# ── KSeF ────────────────────────────────────────────────────────────────────
NEXUS_KSEF_API_URL=https://ksef.mf.gov.pl/api/
NEXUS_KSEF_TOKEN=                 # Token API KSeF (z panelu MF)
NEXUS_KSEF_NIP=                   # NIP firmy dla KSeF

# ── Integracje zewnętrzne ───────────────────────────────────────────────────
NEXUS_NBP_API_URL=https://api.nbp.pl/api/exchangerates/rates/a/
NEXUS_GUS_API_URL=https://wyszukiwarka.ceidg.gov.pl/CEIDG
NEXUS_WHITE_LIST_API_URL=https://wl-api.mf.gov.pl/api/

# ── Bezpieczeństwo ──────────────────────────────────────────────────────────
NEXUS_JWT_SECRET=                 # Auto-generowany przy pierwszym starcie
NEXUS_JWT_EXPIRY=900             # TTL access token (sekundy, 900=15min)
NEXUS_REFRESH_EXPIRY=604800      # TTL refresh token (7 dni)
NEXUS_CSRF_ENABLED=true          # Włącz CSRF protection

# ── AI ──────────────────────────────────────────────────────────────────────
NEXUS_MODELS_DIR=models/         # Katalog z modelami GGUF
NEXUS_LLM_THREADS=4             # Liczba wątków dla llama.cpp
NEXUS_LLM_GPU_LAYERS=0          # Warstwy GPU (0=CPU only)

# ── RODO ────────────────────────────────────────────────────────────────────
NEXUS_RETENTION_YEARS=5          # Domyślny okres przechowywania
NEXUS_LOG_PII_MASK=true          # Maskowanie PII w logach
```

### 3.2 Profile konfiguracyjne

Pixi automatycznie ładuje zmienne z `[activation.env]` w `pixi.toml`.

Profile dostępne przez `pixi run`:
- **dev** (domyślnie): wszystkie serwisy w trybie deweloperskim
- **prod**: `pixi run prod:api` — produkcyjny, bez reload, workers=4

Konfiguracja aplikacji: `config/base.toml` → `config/dev.toml` / `config/prod.toml`

### 3.3 Różnice dev vs staging vs prod

| Parametr | dev | staging | prod |
|---|---|---|---|
| `NEXUS_LOG_LEVEL` | debug | info | warn |
| `NEXUS_HOST` | 127.0.0.1 | 127.0.0.1 | 127.0.0.1 |
| `NEXUS_WATCH_INTERVAL` | 5 | 5 | 0 |
| `GRANIAN_WORKERS` | 1 | 2 | 4 |
| `GRANIAN_RELOAD` | true | false | false |
| `GRANIAN_RESPAWN` | false | true | true |
| OpenAPI / Swagger | true | false | false |
| Rate limiting | false | true | true |
| Metryki | true | true | true |

---

## 4. Instalacja produkcyjna (Windows)

```bash
# 1. Budowanie .exe
pixi run build-nuitka

# 2. Tworzenie instalatora
pixi run build-nuitka-win    # Tylko na Windows

# Wynik: dist/NexusAI_Setup_3.0.0.exe
```

Instalator Inno Setup zawiera:
- Skompilowaną aplikację (Nuitka standalone)
- NATS Server (plik binarny ~10 MB)
- TigerBeetle (plik binarny)
- Modele AI (opcjonalnie, do pobrania po instalacji)
- mimalloc (wkompilowany statycznie)

---

## 4a. Instalacja z OCR (opcjonalnie)

Jeśli potrzebujesz pełnego pipeline OCR (4 silniki: Tesseract, PaddleOCR, docTR, EasyOCR):

```bash
pixi install --environment ocr
```

To doda Tesseract, OpenCV i wszystkie zależności OCR do środowiska.

## 4b. Kompilacja Rusta (opcjonalnie, tylko dla build produkcyjnego)

Domyślnie `nexus-crypto` działa jako pure-Python. Jeśli potrzebujesz natywnej wydajności Rusta:

```bash
# Zainstaluj Rust (jeśli nie masz)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Odkomentuj linie `rust` w sekcji [dependencies] pixi.toml, następnie:
pixi install
pixi run build-rust
```

## 5. Weryfikacja instalacji

```bash
# Sprawdź wersje komponentów
pixi run env-info

# Diagnostyka
pixi run doctor

# Sprawdź API
curl http://127.0.0.1:8000/health
# → {"status": "healthy", "version": "3.0.0-dev"}

# Sprawdź metryki
curl http://127.0.0.1:9090/metrics | head
```

---

## 🔗 Zobacz również

- [Szybki start](QUICKSTART.md) — 15-minutowa instrukcja uruchomienia
- [Wdrożenie](DEPLOYMENT.md) — build produkcyjny, CI/CD
- [Rozwiązywanie problemów](TROUBLESHOOTING.md) — najczęstsze błędy i rozwiązania

---

> **Data aktualizacji:** 2026-07-07 · **Autor:** NexusAI Team · **Wersja:** 3.0.0-dev
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-07 · **Weryfikator:** NexusAI Team
