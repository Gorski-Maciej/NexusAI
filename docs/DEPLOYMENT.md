# 📦 Wdrożenie / Deployment

> **Cel:** Opisać proces budowania, instalacji i wdrażania NexusAI.  
> **Kiedy czytać:** Przed release'em; przy konfiguracji CI/CD.

---

## 1. Środowiska

| Środowisko | Przeznaczenie | Konfiguracja |
|---|---|---|
| **dev** | Lokalny development | `config/dev.toml` + hot-reload |
| **staging** | Testy przedprodukcyjne | `config/prod.toml` + workers=2 |
| **prod** | Produkcja (użytkownik końcowy) | `config/prod.toml` + workers=4, bez Swagger |

---

## 2. Budowanie finalnej binarki

### 2.1 Kompilacja przez Nuitka

```bash
# Build standalone .exe (z mimalloc)
pixi run build-nuitka

# Wynik: dist/NexusAI  (Linux) lub dist/NexusAI.exe (Windows)
```

**Co Nuitka kompiluje:**
- Cały kod Pythona → C → natywny kod maszynowy
- Wszystkie 35+ zależności PyPI
- nexus-crypto (Rust) → statycznie zlinkowany
- mimalloc → wkompilowany (5-15% mniej RAM)
- Granian ASGI server → wkompilowany

**Opcje kompilacji (z `pyproject.toml [tool.nuitka]`):**
- `onefile=true` — pojedynczy plik .exe
- `standalone=true` — bez zależności systemowych
- `lto=true` — Link Time Optimization (5-15% szybszy kod)
- `enable-plugin=["mimalloc"]` — alokator Microsoft
- `jobs=0` — wszystkie rdzenie CPU

### 2.2 Kompilacja Rust (nexus-crypto)

```bash
# Develop (szybki build)
pixi run build-rust

# Release (.whl)
pixi run build-rust-release
```

### 2.3 Optymalizacja mypyc

```bash
# Kompilacja typowanego Pythona → C (2-5× przyspieszenie)
pixi run mypyc-optimize       # Cały kod
pixi run mypyc-optimize-tax   # Tylko tax/ (krytyczna matematyka)
```

---

## 3. Instalator Windows (Inno Setup)

```bash
# Tylko na Windows
pixi run build-nuitka-win
```

Proces:
1. Nuitka kompiluje Python → .exe
2. Inno Setup tworzy instalator (`build_scripts/setup.iss`)
3. Instalator zawiera: NexusAI.exe + NATS Server + TigerBeetle + OPA

**Podpisywanie kodu:**
```bash
signtool sign /fd SHA256 /a /tr http://timestamp.digicert.com dist/NexusAI_Setup.exe
```

---

## 4. Wymagania systemowe (produkcja)

| Parametr | Minimum | Zalecane |
|---|---|---|
| **CPU** | 4 rdzenie x86_64 | 8+ rdzeni z AVX2 |
| **RAM** | 4 GB + modele AI | **6 GB** (z modelami) |
| **Dysk** | 5 GB + modele AI (3-5 GB) | 10 GB SSD |
| **OS** | Windows 10+ / Linux x86_64 | Windows 11 / Ubuntu 22.04 |
| **GPU** | Niewymagane | — |

### Budżet RAM (6 GB)

| Komponent | RAM |
|---|---|
| NexusAI (aplikacja) | ~500 MB |
| SQLite (OLTP) | ~50 MB |
| DuckDB (OLAP) | ~100 MB |
| TigerBeetle | ~80 MB |
| NATS Server | ~20 MB |
| OPA | ~30 MB |
| **Modele AI (razem)** | **~4 GB** |
| — Granite 3.2 3B | ~2 GB |
| — Granite Guardian 0.5B | ~300 MB |
| — Fin-RWKV-169M | ~100 MB |
| — Pozostałe 10 modeli | ~1.5 GB |
| **System + bufor** | ~1 GB |
| **RAZEM** | **~6 GB** |

---

## 5. Aktualizacje OTA (LiteServ)

### 5.1 Architektura auto-update

```
┌─────────────┐    HTTPS     ┌─────────────┐
│ NexusAI.exe │◄────────────►│ LiteServ     │
│ (klient)    │  check/      │ (serwer      │
│             │  download    │  aktualizacji)│
└─────────────┘              └─────────────┘
```

### 5.2 Proces aktualizacji

1. Przy starcie aplikacja sprawdza `GET /version` na serwerze LiteServ
2. Porównuje wersję lokalną (`config/version.json`) z serwerową
3. Jeśli nowsza → pobiera `.exe` + sumę SHA-256
4. Weryfikuje SHA-256
5. Podmienia plik `.exe` (przez `Updater.exe` — osobny proces)
6. Restartuje aplikację

### 5.3 Konfiguracja serwera aktualizacji

```bash
# Uruchomienie LiteServ (ultralekki serwer plików, ~5 MB)
liteserv --dir ./releases/ --port 8080

# Struktura katalogu releases/
releases/
├── version.json           # {"version": "2.3.1", "url": "/nexus-ai-2.3.1.exe", "sha256": "..."}
├── nexus-ai-2.3.1.exe
├── nexus-ai-2.3.0.exe
└── ...
```

---

## 6. Backup i przywracanie

### 6.1 BackupManager

```bash
# Ręczny backup
pixi run backup

# Automatyczny (przez scheduler) — codziennie o 3:00
# Konfiguracja w scheduled_tasks:
# INSERT INTO scheduled_tasks (name, task_type, interval_minutes, ...)
# VALUES ('daily_backup', 'backup', 1440, ...);
```

### 6.2 Proces backupu

1. Zatrzymanie zapisów do bazy (krótka blokada)
2. Skopiowanie `app_data/nexus.db` + `data/tigerbeetle.bin`
3. Kompresja (LZ4)
4. Szyfrowanie AEAD ChaCha20-Poly1305 (nexus-crypto)
5. Obliczenie SHA-256
6. Zapis do `app_data/backups/nexus_backup_<data>.enc`
7. Wznowienie zapisów

### 6.3 Przywracanie

```bash
# Z konkretnego pliku
pixi run restore --file app_data/backups/nexus_backup_2026-07-04.enc

# Z ostatniego backupu
pixi run restore --latest
```

Proces:
1. Weryfikacja SHA-256
2. Deszyfrowanie AEAD
3. Zatrzymanie serwisów
4. Podmiana plików
5. Restart serwisów

---

## 7. Konfiguracja produkcyjna (`config/prod.toml`)

```toml
# config/prod.toml — nadpisania dla środowiska produkcyjnego

[api]
host = "127.0.0.1"            # Tylko localhost (nie 0.0.0.0!)
port = 8000
openapi_enabled = false       # Wyłącz Swagger/OpenAPI w produkcji
csrf_enabled = true
rate_limit_enabled = true
cors_origins = []             # Brak CORS (tylko UNIX socket)

[logging]
level = "warn"                # Tylko ostrzeżenia i błędy
structured = true             # structlog
output = "parquet"            # DuckDB + Parquet

[security]
jwt_expiry = 900             # 15 minut
refresh_expiry = 604800      # 7 dni
password_min_length = 12
argon2_memory_kb = 65536     # 64 MB
argon2_iterations = 3
```

---

## 8. Proces CI/CD

### 8.1 Pipeline (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  lint-and-typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: prefix-dev/setup-pixi@v0
      - run: pixi install --environment dev
      - run: pixi run lint
      - run: pixi run typecheck
  
  test:
    needs: lint-and-typecheck
    steps:
      - run: pixi run test
      - run: pixi run test-cov
  
  security:
    steps:
      - uses: github/codeql-action/analyze@v3
      - uses: ossf/scorecard-action@v2
  
  build:
    if: github.ref == 'refs/heads/main'
    needs: test
    steps:
      - run: pixi run build-rust-release
      - run: pixi run build-nuitka
      - uses: actions/upload-artifact@v4
        with:
          name: nexus-ai-build
          path: dist/
  
  release:
    if: startsWith(github.ref, 'refs/tags/v')
    needs: build
    steps:
      - uses: softprops/action-gh-release@v2
        with:
          files: dist/*
          generate_release_notes: true
```

### 8.2 Pre-commit (lokalne quality gates)

Przed każdym `git commit` uruchamiane są automatyczne kontrole:
- **Ruff** — lint + auto-fix (`ruff-lint`, `ruff-format`)
- **mypy** — strict type checking (`--strict`)
- **Hooks ogólne** — trailing whitespace, end-of-file, YAML/TOML validity, merge conflicts, large files (>2 MB)

```bash
pip install pre-commit && pre-commit install
```

### 8.3 Wyzwalacze

| Zdarzenie | Akcja |
|---|---|
| `push` do dowolnego brancha | Lint + typecheck |
| `push` do `main` | Testy + build |
| `pull_request` | Pełna walidacja |
| Tag `v*` | Build + GitHub Release |
| `schedule` (codziennie 3:00) | Testy wydajnościowe + crosshair 100k iteracji |
| `workflow_dispatch` | Ręczne wyzwolenie |

### 8.4 CI/CD Security (GitHub Actions)

Workflow `.github/workflows/ci.yml` zawiera:
- **Dependabot** — automatyczne PR dla aktualizacji zależności (weekly)
- **OpenSSF Scorecard** — ocena bezpieczeństwa repozytorium
- **CodeQL** — statyczna analiza bezpieczeństwa kodu
- **Labeler** — automatyczne etykietowanie PR
- **Stale** — oznaczanie nieaktywnych PR/issues
- **Workflow reużywalne** — `setup-pixi.yml` (instalacja pixi dla wszystkich jobów)

---

## 9. Monitorowanie i logowanie (produkcja)

### 9.1 Gdzie są logi

| Typ | Lokalizacja | Format |
|---|---|---|
| **Logi aplikacji** | `app_data/logs/` | Parquet (analityczny) |
| **Logi strukturalne** | DuckDB → tabela `logs` | structlog JSON |
| **Logi dostępu** | Granian stdout/stderr | Combined Log Format |
| **Metryki** | `http://127.0.0.1:9090/metrics` | Prometheus |
| **Traces OTel** | Parquet (offline) lub OTLP (online) | OpenTelemetry |

### 9.2 Konfiguracja alertów

```bash
# Skrypt sprawdzający health co 60s
while true; do
  STATUS=$(curl -s http://127.0.0.1:8000/health | jq -r '.status')
  if [ "$STATUS" != "healthy" ]; then
    # Wyślij alert (email/webhook)
    curl -X POST "$DPO_ALERT_WEBHOOK" -d "NexusAI unhealthy!"
  fi
  sleep 60
done
```

---

## 🔗 Zobacz również

- [Bezpieczeństwo](SECURITY.md) — security checklist produkcyjna, rotacja kluczy
- [Architektura](ARCHITECTURE.md) — stos technologiczny, komunikacja między komponentami
- [Instalacja i konfiguracja](INSTALLATION.md) — setup środowiska deweloperskiego
- [Baza danych](DATABASE.md) — backup i przywracanie

---

> **Data aktualizacji:** 2026-07-04 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-04 · **Weryfikator:** NexusAI Team
