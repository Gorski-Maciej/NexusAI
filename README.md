# NexusAI — AI-Powered Accounting & Invoice Processing System

[![Python](https://img.shields.io/badge/Python-3.13t-blue)](https://python.org)
[![Litestar](https://img.shields.io/badge/Litestar-2.8%2B-blueviolet)](https://litestar.dev)
[![NATS](https://img.shields.io/badge/NATS-JetStream-27ae60)](https://nats.io)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

**NexusAI** is a next-generation, AI-driven accounting platform designed for Polish businesses. It combines OCR-based invoice processing, multi-agent AI decision-making (council of LLMs), double-entry ledger integration via TigerBeetle, and real-time event streaming via NATS JetStream — all wrapped in a modern Litestar API and a Flet-based desktop UI.

Built as a **single-file executable** (Nuitka onefile) — no Docker, no complex setup.

---

## Table of Contents

- [Features](#features)
- [Technology Stack (Zgodność z aa3fvcx.txt)](#technology-stack--zgodność-z-aa3fvcxtxt)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Environment Configuration](#environment-configuration)
- [Running the Application](#running-the-application)
  - [Option A: Development (pip / pixi)](#option-a-development-pip--pixi)
  - [Option B: Production Build (Nuitka onefile)](#option-b-production-build-nuitka-onefile)
  - [Option C: Desktop UI (Flet)](#option-c-desktop-ui-flet)
- [Building a Single Executable](#building-a-single-executable)
- [API Documentation](#api-documentation)
- [Running Tests](#running-tests)
- [Project Structure](#project-structure)
- [Key Modules](#key-modules)
- [Environment Variables Reference](#environment-variables-reference)
- [Troubleshooting](#troubleshooting)

---

## Features

- **🤖 AI Agent Council** — Multi-LLM agent system (Qwen, Granite, Jamba, LittleLamb) for invoice classification, anomaly detection, rules validation, and automated posting.
- **📄 Intelligent OCR Pipeline** — Document preprocessing, layout analysis, text extraction, and vision-based validation (Qwen2.5-VL).
- **📊 Real-time Analytics** — DuckDB-powered OLAP views for cashflow projection, monthly summaries, vendor scoring, and anomaly detection.
- **🔒 Double-Entry Ledger** — TigerBeetle integration for two-phase commit transfers with Polish chart of accounts.
- **📨 Event-Driven Architecture** — NATS JetStream message broker with task queues, outbox pattern, and dead-letter replay.
- **🔐 Security** — JWT authentication, SQLCipher at-rest encryption, rate limiting, CSRF protection, and offline-first secrets management.
- **🌐 i18n** — Multi-language support with Polish as primary language.
- **📦 Single-File Executable** — Nuitka onefile build bundles everything into a single `.exe` / Linux binary.

---

## Technology Stack — Zgodność z aa3fvcx.txt

NexusAI jest zbudowany według architektury określonej w pliku [`aa3fvcx.txt`](aa3fvcx.txt) — ultralekkiego, wydajnego stosu technologicznego dla samodzielnej aplikacji księgowej z AI. Poniższa tabela przedstawia pełną mapę zgodności.

### Punkt 1 — Środowisko uruchomieniowe i narzędzia budowania

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Plik konfiguracyjny |
|---|---|---|---|
| **Python ≥3.13 (free-threaded)** | Python <3.13 (z GIL) | ✅ | `pixi.toml` → `python = "3.13.*"` |
| **pixi** — menedżer środowiska (Rust) | Docker, conda, apt-get | ✅ | `pixi.toml` |
| ~~**mise** — task runner~~ | ~~pyenv, asdf, make, just~~ | ➡️ **pixi** (zastąpił mise) | `pixi.toml` |
| **hatchling** — backend budowania | setuptools, setup.py | ✅ | `pyproject.toml` → `build-backend = "hatchling.build"` |
| **mypyc** — kompilacja typowanego Pythona → C | — | ✅ | `pyproject.toml` → `[tool.mypyc]` |
| **PyO3 + Maturin** — Rust extensions | — | ✅ | `nexus_ai/rust/Cargo.toml`, `pyproject.toml` → `[tool.maturin]` |
| **Rust** — język dla krytycznych modułów | C | ✅ | `nexus_ai/rust/Cargo.toml` |
| **mimalloc** — alokator pamięci | glibc malloc | ✅ | `pyproject.toml` → `[tool.nuitka]` → plugin |
| **Nuitka** — kompilacja do .exe | — | ✅ | `main.py` (dyrektywy Nuitka), `pyproject.toml` → `[tool.nuitka]` |

### Punkt 2 — Warstwa API (ASGI)

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **Litestar** — framework API | FastAPI | ✅ | `nexus_ai/api/app.py` → `create_app()` |
| **Granian** — serwer ASGI w Rust | Uvicorn | ✅ | `nexus_ai/api/server.py` → `granian.Granian(...)` |
| **anyio** — lekka warstwa współbieżności | — | ✅ | Używany w `ocr_consensus.py`, `luz/worker.py` |
| **msgspec** — ultraszybka serializacja | json, orjson | ✅ | `nexus_ai/core/msgspec_utils.py` |

### Punkt 3 — Baza danych i warstwa danych

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **SQLite + SQLCipher** — szyfrowana baza | — | ✅ | `nexus_ai/db/database.py` → PRAGMA key |
| **sqlite-vec** — wektory w SQLite | LanceDB | ✅ | `nexus_ai/db/vector_store.py` |
| **SQLModel** — ORM 2w1 | SQLAlchemy + Pydantic (osobno) | ✅ | `nexus_ai/db/models.py` |
| **DuckDB** — lokalna hurtownia OLAP | — | ✅ | `nexus_ai/db/analytics.py` → `DuckDBManager` |
| **PyArrow** — format danych w pamięci | — | ✅ | Używany przez DuckDB |
| **Polars** — DataFrame nowej generacji | pandas | ✅ | `nexus_ai/core/analytics.py` |
| **Natywne migracje SQL** — migracje schematu | Alembic | ✅ | `migrations/*.sql`, `migrations/run_migrations.py` |

### Punkt 4 — Walidacja i serializacja

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **msgspec** — serializacja API + konfiguracja TOML | json, python-dotenv, pydantic-settings | ✅ | `nexus_ai/core/config.py` → `msgspec.toml.decode` |
| **Pydantic** — tylko przez SQLModel (ukryty) | — | ✅ | Tylko jako zależność SQLModel |

### Punkt 5 — Kolejki i komunikacja asynchroniczna

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **NATS Server** — broker komunikatów (~10 MB) | Redis, RabbitMQ | ✅ | `pixi.toml` → `task start-nats` |
| **nats-py** — klient Python | — | ✅ | `nexus_ai/core/broker.py` |
| **NATS JetStream** — trwałe strumienie | Redis Streams | ✅ | `nexus_ai/core/tasks.py` |
| **Taskiq** — kolejka zadań (async-native) | Celery | ✅ | `nexus_ai/core/broker.py` |
| **taskiq-nats** — spoiwo Taskiq ↔ NATS | — | ✅ | `nexus_ai/core/broker.py` |

### Punkt 6 — Warstwa HTTP i sieć

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **httpx** — klient HTTP (async) | — (httpx natywnie) | ✅ | `nexus_ai/services/currency_converter.py` |
| **hishel** — inteligentny cache HTTP | — | ✅ | W `pixi.toml` |
| **fsspec** — abstrakcja systemów plików | — | ✅ | W `pixi.toml` |

### Punkt 7 — Odporność (Resilience)

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **stamina** — retry + circuit breaker (async-native) | — (natywna implementacja) | ✅ | `nexus_ai/core/resilience.py` |

### Punkt 8 — Kryptografia i bezpieczeństwo

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **Nexus-Crypto** (Rust + PyO3) — AEAD + Argon2id + SHA-256 | cryptography (częściowo) | ✅ | `nexus_ai/rust/src/lib.rs` |
| **Litestar JWT** — tokeny (wbudowane) | pyjwt | ✅ | `nexus_ai/api/security.py` |
| **Litestar CSRF** — ochrona (wbudowana) | — | ✅ | `nexus_ai/api/middleware.py` |
| **Litestar CORS** — kontrola dostępu (wbudowana) | — | ✅ | `nexus_ai/api/app.py` |
| **Litestar Rate Limiting** — limitowanie (wbudowane) | — | ✅ | `nexus_ai/api/rate_limit.py` |
| **cryptography** (opcjonalnie) — RSA dla KSeF | — | ⚠️ Tylko KSeF | `nexus_ai/core/integrations/ksef/crypto.py` |

### Punkt 9 — Finanse i waluty

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **TigerBeetle** — silnik księgowy (double-entry) | — | ✅ | `pixi.toml` → `task start-tigerbeetle`, `nexus_ai/roboton_reflekton/ledger_client.py` |
| **Nexus-Money** (msgspec.Struct) | py-moneyed | ✅ | `nexus_ai/services/currency_converter.py` → `class Money` |
| **Nexus-Forex** (Rust + PyO3) — własny moduł walutowy | ForexEngine | ✅ | `nexus_ai/roboton_reflekton/nexus_forex/` → `Cargo.toml`, `src/lib.rs` |
| **TigerBeetle Client (Python)** | — | ✅ | `nexus_ai/roboton_reflekton/ledger_client.py` |

### Punkt 10 — Przetwarzanie dokumentów (OCR)

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **lxml** — parser XML z walidacją XSD | — | ✅ | W `pixi.toml` |
| **xsdata** — XSD → Python code generation | — | ✅ | `nexus_ai/core/integrations/ksef/xsd_bindings.py` |
| **Tesseract OCR** — klasyczny OCR | — | ✅ | `nexus_ai/pipeline/ocr_consensus.py` → `TesseractEngine` |
| **PaddleOCR** — deep learning OCR | — | ✅ | `nexus_ai/pipeline/ocr_consensus.py` → `PaddleOCREngine` |
| **docTR** (Python-docTR) — modułowy OCR (DBNet + PARSeq) | — | ✅ | `nexus_ai/pipeline/ocr_consensus.py` → `DocTREngine` |
| **Mechanizm Walidacji Krzyżowej** (3 silniki) | — | ✅ | `nexus_ai/pipeline/ocr_consensus.py` → `decide_field_consensus()` |
| **Pillow + OpenCV** — preprocessing obrazów | — | ✅ | W `pixi.toml` |
| **pypdfium2** — konwersja PDF → obraz (BSD, zastępuje PyMuPDF/fitz) | — | ✅ | `nexus_ai/pipeline/ocr_consensus.py` → `pdf_to_images()` |

### Punkt 11 — Logowanie i obserwowalność

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **structlog** — ustrukturyzowane logowanie | — | ✅ | `nexus_ai/core/logger.py` |
| **Loguru** — silnik zapisu logów | logging | ✅ | `nexus_ai/core/logger.py` |
| **OpenTelemetry (API + SDK)** — telemetria | — | ✅ | W `pixi.toml` |
| **DuckDB + Parquet** — lokalna hurtownia telemetrii | — | ✅ | `nexus_ai/db/analytics.py` |

### Punkt 12 — Metryki i monitoring

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **OpenTelemetry Metrics** — metryki | prometheus_client | ✅ | `nexus_ai/api/telemetry_metrics.py` |
| **Prometheus Exporter** — endpoint /metrics | — | ✅ | W `pixi.toml` |
| **Sentry SDK** — śledzenie błędów | — | ✅ | `nexus_ai/core/sentry.py` (opcjonalne) |

### Punkt 13 — Cache

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **dyscache** — wielopoziomowy cache (RAM + SQLite) | cachetools, diskcache, Redis | ✅ | W `pixi.toml` |
| **msgspec** — serializacja w cache | pickle, json | ✅ | `nexus_ai/core/msgspec_utils.py` |

### Punkt 14 — Narzędzia

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **TOML + msgspec** — konfiguracja | .env, python-dotenv, YAML | ✅ | `nexus_ai/core/config.py` |
| **pendulum** — daty i czas | datetime, pytz, dateparser | ✅ | Używany w całym projekcie |
| **psutil** — monitorowanie systemu | — | ✅ | `nexus_ai/scripts/doctor.py` |

### Punkt 15 — Testowanie

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **pytest** — framework testowy | — | ✅ | `pyproject.toml` → `[tool.pytest.ini_options]` |
| **pytest-anyio** — natywna asynchroniczność | pytest-asyncio | ✅ | W `[project.optional-dependencies.dev]` |
| **schemathesis** — fuzz testing API | — | ✅ | Dev dependency |
| **locust** — testy wydajności w Pythonie | k6 | ✅ | Dev dependency |
| **crosshair** — property-based testing (SMT) | hypothesis | ✅ | `pyproject.toml` → `[tool.crosshair]` |
| **py-spy** — profiler w Rust | cProfile | ✅ | Dev dependency |

### Punkt 16 — Interfejs użytkownika (Desktop)

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **Flet** — framework GUI (Flutter/Skia) | Electron, NiceGUI, Tkinter | ✅ | `nexus_ai/luz/main.py`, `nexus_ai/frontend/` |
| **Flet Router** — nawigacja | — | ✅ | `nexus_ai/frontend/router.py` |

### Punkt 18 — Infrastruktura i DevOps

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **pixi** — deklaratywne środowisko + task runner | Docker, conda, ~~mise~~ | ✅ (jeden plik zamiast mise + pixi) | `pixi.toml` |
| ~~**mise** — menedżer wersji + task runner~~ | ~~pyenv, asdf, make, just~~ | ➡️ **pixi** (zastąpił mise) | `pixi.toml` |
| **GitHub Actions** — CI/CD | — | ✅ | `.github/workflows/` |

### Punkt 26 — SYSTEM POWIADOMIEŃ I CENTRUM DECYZJI

| Technologia (aa3fvcx.txt) | Zastępuje | Status | Implementacja |
|---|---|---|---|
| **NotificationManager (Python)** — centralny system zarządzania komunikatami od agentów | — | ✅ | `nexus_ai/services/notification_manager.py` |
| **DecisionQueue (SQLite)** — trwała kolejka decyzji z priorytetami i terminami ważności | — | ✅ | `nexus_ai/services/decision_queue.py` |
| **EventLog (DuckDB)** — historia zdarzeń i decyzji, przeszukiwalna | — | ✅ | `nexus_ai/db/event_log.py` |
| **Scheduler (Python + anyio)** — zarządzanie terminami przypomnień (ZUS, licencje, raporty) | — | ✅ | `nexus_ai/services/scheduler.py` |

### Podsumowanie zgodności

| Kategoria | Stan |
|---|---|
| ✅ W pełni zaimplementowane | **~90-95** technologii |
| ⚠️ Uzasadnione wyjątki (RSA dla KSeF) | **2** (`cryptography` — wymóg KSeF) |
| ❌ Brakujące technologie | **0** |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     Flet Desktop UI                      │
│                    (Python / Flutter)                    │
└──────────────┬──────────────────────────────────────────┘
               │ HTTP / WebSocket
┌──────────────▼──────────────────────────────────────────┐
│              Litestar API (ASGI / Granian)               │
│         /api/v1/* (legacy)  /api/v2/* (current)         │
│    JWT Auth | Rate Limit | CORS | OpenAPI / Swagger     │
└──────┬──────────────┬──────────────┬────────────────────┘
       │              │              │
       ▼              ▼              ▼
┌──────────┐  ┌────────────┐  ┌──────────────┐
│ SQLite   │  │  DuckDB    │  │   NATS       │
│ (OLTP)   │  │  (OLAP)    │  │  JetStream   │
│ Invoice  │  │ Analytics  │  │  Task Queue  │
│ Users    │  │ Cashflow   │  │  Events      │
│ Outbox   │  │ Views      │  │  Outbox      │
└──────────┘  └────────────┘  └──────┬───────┘
                                      │
                                      ▼
                              ┌──────────────┐
                              │  Taskiq      │
                              │  Worker(s)   │
                              │  OCR / AI    │
                              │  Agent       │
                              │  Council     │
                              └──────┬───────┘
                                     │
                                     ▼
                              ┌──────────────┐  ┌──────────────────┐
                              │  TigerBeetle  │  │   Nexus-Forex    │
                              │  Ledger       │  │   Forex Engine   │
                              │  (2PC)        │  │   (Rust + PyO3)  │
                              └──────────────┘  └────────┬─────────┘
                                                         │
                                                         ▼
                                                  ┌──────────────┐
                                                  │   NBP API    │
                                                  │   (kursy)    │
                                                  └──────────────┘
```

---

## Installation

### Quick Install (pip)

```bash
# Install the core package
pip install nexus-ai

# Install with desktop UI support
pip install "nexus-ai[ui]"

# Install with AI model support (GPU/CPU inference)
pip install "nexus-ai[ai]"

# Install with development tools
pip install "nexus-ai[dev]"

# Install everything
pip install "nexus-ai[ui,ai,dev]"
```

### Development Install (from source with pixi)

```bash
# 1. Clone the repository
git clone https://github.com/your-org/NexusAI.git
cd NexusAI

# 2. Install pixi (if not already installed)
curl -fsSL https://pixi.sh/install.sh | bash

# 3. Create environment with pixi (Python 3.13t + all deps)
pixi install

# 4. Activate environment
pixi shell

# 5. Configure environment (optional, defaults work for dev)
cp .env.example .env
```

---

## Prerequisites

- **Python** 3.13 or higher (free-threaded 3.13t recommended)
- **NATS Server** (with JetStream support) — `pixi run nats` or [manual download](https://nats.io/download/)
- **TigerBeetle** (optional, local stub included)

### Optional (for AI features)

- **GGUF Model Files** — Download models for agent council (see [Downloading Models](#downloading-models))
- **Tesseract OCR** — For document text extraction
- **CUDA drivers** (NVIDIA GPU) — For local LLM inference

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/your-org/NexusAI.git
cd NexusAI

# 2. Install with pixi (recommended) or pip
pixi install
# OR: pip install -e ".[ui,ai,dev]"

# 3. Run system diagnostics
python -m nexus_ai.scripts.doctor

# 4. Start NATS server (in a separate terminal)
nats-server -p 4222 -js

# 5. Run the application
python main.py
```

The API will be available at **http://127.0.0.1:8000** with Swagger UI at **http://127.0.0.1:8000/schema/swagger**.

### Using pixi tasks

```bash
# Start all services (API + worker + NATS)
pixi run dev

# Start the API server only
pixi run api

# Start the Taskiq worker only
pixi run worker

# Start the desktop UI
pixi run desktop

# Run diagnostics
pixi run doctor
```

---

## Environment Configuration

Copy `.env.example` to `.env` and adjust the values:

```bash
cp .env.example .env
```

### Minimal `.env` for local development

```env
NEXUS_ENV=dev
NEXUS_DEBUG=1
NEXUS_HOST=127.0.0.1
NEXUS_PORT=8000
NEXUS_NATS_URL=nats://localhost:4222
NEXUS_JWT_SECRET=your-local-dev-secret-here
NEXUS_ENCRYPTION_KEY=
NEXUS_BASE_DIR=.
```

**Important:** In `stage`/`prod` environments, `NEXUS_JWT_SECRET` and `NEXUS_ENCRYPTION_KEY` are **required**.
Generate a proper encryption key with:

```python
import base64, os
print(base64.urlsafe_b64encode(os.urandom(32)).decode())
```

---

## Running the Application

### Option A: Development (pip / pixi)

**Prerequisites:** Start NATS server first.

```bash
# Start NATS (required)
nats-server -p 4222 -js

# Terminal 1: Start the API server
python main.py --mode api

# Terminal 2: Start the Taskiq worker (for OCR/AI processing)
python main.py --mode worker
```

Or run everything together:

```bash
python main.py --mode all
```

Or with pixi:

```bash
# Start all services with a single command
pixi run dev
```

### Option B: Production Build (Nuitka onefile)

Build a single-file executable that bundles everything:

```bash
# Build the onefile executable
pixi run build

# Run the built executable
./dist/nexus-ai --mode api
```

See [Building a Single Executable](#building-a-single-executable) for details.

### Option C: Desktop UI (Flet)

```bash
# Using installed CLI
nexus-desktop

# Or directly via Python
python -m nexus_ai.luz.main
```

This starts a full desktop application with:
- Splash screen with startup progress
- NATS server auto-start
- Background worker
- API server (auto-assigned port)
- Flet-based graphical interface

---

## Building a Single Executable

NexusAI can be built as a **single portable executable** using Nuitka's `--onefile` mode. This bundles Python interpreter, all dependencies, and the application code into one file.

### Prerequisites

```bash
pip install nuitka ordered-set  # or pixi run install-build-deps
```

### Build Commands

```bash
# Basic onefile build (Linux/macOS)
python -m nuitka --onefile --standalone --include-package=nexus_ai main.py

# Windows onefile build with icon
python -m nuitka --onefile --standalone --include-package=nexus_ai --windows-icon-from-ico=icon.ico main.py

# With pixi (recommended)
pixi run build
```

### Build Scripts

Pre-configured build scripts are in `build_scripts/`:

| Script | Platform | Description |
|---|---|---|
| `build_exe.sh` | Linux/macOS | Nuitka onefile build |
| `build_exe.bat` | Windows | Nuitka onefile build |
| `setup.iss` | Windows | Inno Setup installer (wraps the .exe) |
| `setup.nsi` | Windows | NSIS installer (wraps the .exe) |

### Onefile Build Configuration (`pyproject.toml`)

```toml
[tool.nuitka]
onefile = true
standalone = true
enable-plugins = ["pydantic"]
include-package = ["nexus_ai", "granian", "litestar"]
```

### What's Included

The single executable contains:
- ✅ Python 3.13t interpreter (Nuitka-compiled)
- ✅ All Python dependencies (Litestar, Granian, SQLModel, etc.)
- ✅ All `nexus_ai` modules (API, services, DB, pipelines)
- ✅ Rust extensions (nexus-crypto via PyO3)
- ❌ AI model files (GGUF) — downloaded separately on first run
- ❌ NATS server — auto-started or embedded

---

## API Documentation

Once the server is running, visit:

| Endpoint | Description |
|---|---|
| `/schema/swagger` | Swagger UI (interactive API explorer) |
| `/schema/openapi.json` | OpenAPI 3.0 JSON schema |
| `/api/v1/health` | Health check (legacy) |
| `/api/v2/health` | Health check (current) |
| `/api/v2/dashboard` | Dashboard analytics data |
| `/api/v2/invoices` | Invoice management CRUD |
| `/api/v2/auth/login` | Authentication endpoint |
| `/api/v2/tasks` | Task status and management |

### Example API Calls

```bash
# Health check
curl http://127.0.0.1:8000/api/v2/health

# Login (get JWT token)
curl -X POST http://127.0.0.1:8000/api/v2/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin"}'

# List invoices (with JWT)
curl http://127.0.0.1:8000/api/v2/invoices \
  -H "Authorization: Bearer <your-token>"

# Upload invoice
curl -X POST http://127.0.0.1:8000/api/v2/invoices/upload \
  -H "Authorization: Bearer <your-token>" \
  -F "file=@invoice.pdf"
```

---

## Running Tests

```bash
# Run all tests
pytest tests/

# Run specific test file
pytest tests/test_inventory_fifo.py -v

# Run with coverage
pytest tests/ --cov=nexus_ai --cov-report=term-missing

# Run with pixi
pixi run test

# Run performance benchmarks
pytest tests/performance/ -v

# Property-based tests
pixi run test-property
```

### Test structure

| Test file | What it covers |
|---|---|
| `tests/test_rules_engine.py` | Rules engine and validation logic |
| `tests/test_fixed_assets_depreciation.py` | Fixed assets depreciation |
| `tests/test_inventory_fifo.py` | FIFO inventory accounting |
| `tests/test_fraud_graph_scanner.py` | Fraud detection graph scanning |
| `tests/test_nexus_forex.py` | Foreign exchange revaluation (Nexus-Forex Rust module) |
| `tests/test_reconciliation_engine.py` | Account reconciliation |
| `tests/test_dunning_engine.py` | Dunning/collections engine |
| `tests/test_smart_approvals.py` | Smart approval workflows |
| `tests/test_council_session.py` | AI agent council coordination |
| `tests/test_autopilot.py` | Autopilot decision automation |
| `tests/test_vision_agent.py` | Vision-based invoice analysis |
| `tests/test_audit_storno.py` | Audit and storno corrections |
| `tests/test_budgetary_control.py` | Budget control enforcement |
| ...and many more | |

---

## Project Structure

```
NexusAI/
├── main.py                        # Central application entry point
├── pyproject.toml                  # Package configuration
├── pixi.toml                      # Pixi environment manager config
├── .gitignore
├── README.md
│
├── nexus_ai/                      # Main package directory
│   ├── __init__.py
│   ├── main.py                    # Application entry logic
│   │
│   ├── api/                       # Litestar API application
│   │   ├── app.py                 # API app factory (create_app)
│   │   ├── server.py              # Granian server entrypoint
│   │   ├── state.py               # Startup/shutdown lifecycle
│   │   ├── security.py            # JWT authentication
│   │   ├── middleware.py           # HTTP middleware
│   │   ├── dependencies.py        # DI providers
│   │   ├── locales/               # i18n translation files
│   │   │   ├── pl.json
│   │   │   └── en.json
│   │   └── routes/                # API route controllers
│   │
│   ├── core/                      # Core shared modules
│   │   ├── config.py              # AppConfig (TOML via msgspec)
│   │   ├── broker.py              # NATS Taskiq broker setup
│   │   ├── tasks.py               # Background task definitions
│   │   ├── secrets.py             # Offline-first secrets manager
│   │   ├── crypto.py              # Encryption (nexus-crypto)
│   │   ├── logger.py              # Loguru + structlog
│   │   ├── bus.py                 # In-process event bus
│   │   ├── saga.py                # Persisted saga store
│   │   ├── prompts/               # AI prompt templates
│   │   │   ├── pl.json
│   │   │   └── en.json
│   │   └── msgspec_utils.py       # msgspec serialization helpers
│   │
│   ├── services/                  # Business logic services
│   │   ├── rules_engine.py        # Invoice validation rules
│   │   ├── analytics_service.py
│   │   ├── fraud_graph_scanner.py
│   │   ├── fixed_assets.py
│   │   ├── inventory_fifo.py
│   │   ├── dunning_engine.py
│   │   ├── liquidity_oracle.py
│   │   └── ...                    # 45+ service modules
│   │
│   ├── db/                        # Database layer
│   │   ├── database.py            # SQLModel engine + session factory
│   │   ├── models.py              # SQLModel ORM models
│   │   ├── analytics.py           # DuckDB manager
│   │   ├── outbox.py              # Outbox pattern models
│   │   ├── views.py               # Analytics materialized views
│   │   ├── hooks.py               # SQLModel event hooks
│   │   └── vector_store.py        # Vector storage (sqlite-vec)
│   │
│   ├── pipeline/                  # Document processing pipeline
│   │   ├── ocr_consensus.py       # OCR consensus engine
│   │   └── parser.py              # Document parser
│   │
│   ├── roboton_reflekton/         # Accounting engine module
│   │   ├── ledger_client.py       # TigerBeetle client (stub)
│   │   ├── ledger_initializer.py
│   │   ├── reconciliation_engine.py
│   │   ├── dunning_engine.py
│   │   ├── shadow_ledger.py       # Tax simulation
│   │   ├── vat_reconciliation.py
│   │   ├── nexus_forex/           # Nexus-Forex (Rust + PyO3) — własny moduł walutowy
│   │   │   ├── Cargo.toml
│   │   │   └── src/lib.rs
│   │   └── models.py              # Domain models
│   │
│   ├── luz/                       # Desktop application (Flet)
│   │   ├── main.py                # Flet UI orchestrator
│   │   └── worker.py              # Taskiq worker entrypoint
│   │
│   ├── frontend/                  # Flet UI components
│   │   ├── ui.py
│   │   └── Braki.py
│   │
│   ├── architecture/              # Architecture documentation
│   │   └── perfect_accounting_architecture.py
│   │
│   └── scripts/                   # Utility scripts
│       ├── download_models.py     # Model downloader (SHA-256 verified)
│       ├── doctor.py              # System diagnostics
│       ├── bootstrap.py           # Environment bootstrap
│       ├── dlq_notifier.py        # Dead Letter Queue notifier
│       └── ...                    # 15+ scripts
│
├── tests/                         # Test suite
│   ├── conftest.py
│   └── test_*.py                  # 80+ test files
│
├── config/                        # TOML configuration profiles
│   ├── dev.toml
│   └── prod.toml
│
├── build_scripts/                 # Build scripts for onefile executable
│   ├── build_exe.bat
│   ├── build_exe.sh
│   ├── setup.iss
│   └── setup.nsi
│
├── nexus_crypto/                  # Rust + PyO3 native crypto
│   ├── Cargo.toml
│   ├── pyproject.toml
│   └── src/lib.rs
│
├── migrations/                    # Alembic database migrations
│   └── versions/
│
└── models/                        # AI model files (GGUF) — downloaded separately
```

---

## Key Modules

### 🤖 AI Agent Council (`nexus_ai/services/council_agents.py`)

Multi-LLM agent system that evaluates invoices through specialized agents:
- **Alpha Agent** (LFM 1.2B) — Primary classification
- **Beta Agent** (Qwen3 0.6B) — Secondary validation
- **Gamma Agent** (LittleLamb 0.3B) — Tiebreaker + reasoning
- **Rules Agent** (Granite 1B) — Business rule enforcement
- **Analytics Agent** (Qwen2.5 1.5B) — Anomaly detection

### 📄 OCR Pipeline (`nexus_ai/pipeline/`)

Document processing pipeline with stages:
1. **Preprocessor** — Image enhancement, deskew, binarization
2. **Splitter** — Multi-page document splitting
3. **OCR Engine** — Tesseract-based text extraction
4. **Vision Agent** — Qwen2.5-VL visual analysis
5. **Refiner** — Post-processing and correction
6. **QA Engine** — Quality assurance checks
7. **Consensus** — Multi-engine OCR consensus voting

### 🔒 Ledger System (`nexus_ai/roboton_reflekton/`)

Double-entry accounting with:
- Polish chart of accounts (symbole kont)
- TigerBeetle two-phase commit transfers
- Financial period locking (HARD_CLOSED)
- Shadow ledger for "what-if" tax simulations
- VAT reconciliation engine

### 🔄 Event System

Event-driven architecture:
- **NATS JetStream** — Durable message streaming
- **Outbox Pattern** — Reliable event publishing
- **Taskiq** — Async task queue with scheduling
- **stamina** — Async-native retry + circuit breaker
- **Saga Pattern** — Distributed transaction orchestration

---

## Environment Variables Reference

| Variable | Default | Description |
|---|---|---|
| **Core** | | |
| `NEXUS_ENV` | `dev` | Environment: `dev`, `stage`, or `prod` |
| `NEXUS_DEBUG` | `0` | Enable debug mode (`1` or `0`) |
| `NEXUS_HOST` | `127.0.0.1` | API server bind address |
| `NEXUS_PORT` | `8000` | API server port |
| `NEXUS_BASE_DIR` | `.` | Base directory for data storage |
| `NEXUS_LOG_LEVEL` | `info` | Logging level |
| **Security** | | |
| `NEXUS_JWT_SECRET` | *(auto-generated)* | JWT signing secret **(required in prod)** |
| `NEXUS_JWT_EXPIRATION_SECONDS` | `900` | JWT token expiry |
| `NEXUS_JWT_ISSUER` | `nexus-ai` | JWT issuer claim |
| `NEXUS_JWT_AUDIENCE` | `nexus-api` | JWT audience claim |
| `NEXUS_REFRESH_TOKEN_DAYS` | `30` | Refresh token validity days |
| `NEXUS_ADMIN_USERNAME` | `admin` | Default admin username |
| `NEXUS_ADMIN_PASSWORD` | `admin` | Default admin password |
| `NEXUS_ENCRYPTION_KEY` | *(empty)* | 32-byte base64-url key **(required in prod)** |
| `NEXUS_SQLCIPHER_KEY` | *(empty)* | SQLCipher database encryption key |
| **Database** | | |
| `NEXUS_SQLITE_FILE` | `nexus_oltp.db` | SQLite OLTP database filename |
| `NEXUS_DUCKDB_FILE` | `nexus_olap.duckdb` | DuckDB OLAP database filename |
| `NEXUS_DUCKDB_MEMORY_LIMIT` | `512MB` | DuckDB memory limit |
| `NEXUS_DUCKDB_THREADS` | `2` | DuckDB thread count |
| **NATS** | | |
| `NEXUS_NATS_URL` | `nats://localhost:4222` | NATS server URL |
| `NEXUS_MAX_PARALLEL_OCR` | `1` | Max concurrent OCR tasks |
| `NEXUS_OCR_TIMEOUT_SEC` | `300` | OCR task timeout in seconds |
| `NEXUS_OUTBOX_REPLAY_LIMIT` | `100` | Max outbox replay per cycle |
| **Storage & Uploads** | | |
| `NEXUS_STORAGE_DIR` | `app_data/uploads` | File upload storage directory |
| `NEXUS_MAX_INVOICE_UPLOAD_MB` | `50` | Max invoice upload size (MB) |
| `NEXUS_MAX_ATTACHMENT_UPLOAD_MB` | `500` | Max attachment upload size (MB) |
| **CORS** | | |
| `NEXUS_CORS_ORIGINS` | `*` | Allowed CORS origins |
| **AI Models (Paths)** | | |
| `NEXUS_COUNCIL_ALPHA_MODEL` | `models/LFM2.5-1.2B-Q4_K_M.gguf` | Alpha agent model path |
| `NEXUS_COUNCIL_BETA_MODEL` | `models/Qwen3-0.6B-Q4_K_M.gguf` | Beta agent model path |
| `NEXUS_COUNCIL_GAMMA_MODEL` | `models/LittleLamb-0.3B-Q4_K_M.gguf` | Gamma agent model path |
| `NEXUS_RULES_MODEL` | `models/granite-4.0-1b-nano-Q4_K_M.gguf` | Rules agent model path |
| `NEXUS_ANALYTICS_MODEL` | `models/qwen2.5-1.5b-instruct-Q4_K_M.gguf` | Analytics agent model path |
| `NEXUS_DECISION_JAMBA_MODEL` | `models/Jamba-Reasoning-3B-Q4_K_M.gguf` | Decision agent (Jamba) path |
| `NEXUS_DECISION_GRANITE_MODEL` | `models/granite-4.0-1b-nano-Q4_K_M.gguf` | Decision agent (Granite) path |
| `NEXUS_ORCHESTRATOR_MODEL` | `models/LittleLamb-0.3B-Q4_K_M.gguf` | Orchestrator agent path |
| **TigerBeetle** | | |
| `TB_CLUSTER_ID` | `0` | TigerBeetle cluster ID |
| `TB_REPLICA_ADDRESSES` | `3000` | TigerBeetle replica addresses |
| **Nexus-Forex** | | |
| `NEXUS_FOREX_ENABLED` | `true` | Enable/disable Nexus-Forex module (Rust + PyO3) |
| `NEXUS_FOREX_NBP_API_URL` | `https://api.nbp.pl/api/exchangerates/rates/A/{currency}/{date}/?format=json` | Base URL dla API kursów NBP (z placeholderami `{currency}` i `{date}`) |
| `NEXUS_FOREX_MAX_LOOKBACK_DAYS` | `5` | Maksymalna liczba dni wstecz do poszukiwania kursu (weekendy/święta) |
| `NEXUS_FOREX_HTTP_TIMEOUT_SEC` | `10` | Timeout żądania HTTP do API NBP (sekundy) |
| `NEXUS_FOREX_RATE_CACHE_MAXSIZE` | `1000` | Maksymalna liczba kursów w pamięci RAM (LRU cache) |
| `NEXUS_FOREX_REFRESH_INTERVAL_HOURS` | `24` | Interwał odświeżania kursów walut (godziny) *(planned)* |
| `NEXUS_FOREX_DEFAULT_CURRENCIES` | `EUR,USD,GBP,CHF,CZK,SEK,NOK,HUF` | Domyślne waluty do śledzenia (oddzielone przecinkami) *(planned)* |
| `NEXUS_FOREX_STAMINA_RETRY_ATTEMPTS` | `3` | Liczba prób pobrania kursu przed circuit breakerem (Python fallback `forex_engine.py`) |
| `NEXUS_FOREX_STAMINA_RETRY_TIMEOUT` | `15` | Timeout na cały cykl retry w sekundach (Python fallback `forex_engine.py` — stamina) |
| `NEXUS_FOREX_MISSING_DATE_TTL_DAYS` | `30` | Jak długo pamiętać brak kursu dla daty (TTL w dniach) |

---

## AI Models Setup

NexusAI uses a Council of LLMs for intelligent invoice processing. Setting up the AI environment involves:

### 1. Hardware Requirements

- **GPU (recommended):** NVIDIA GPU with CUDA support (6 GB+ VRAM)
- **CPU (minimum):** 8 GB RAM, 4+ cores
- **Disk:** ~10 GB free for model files

### 2. Install AI Dependencies

```bash
# For GPU (CUDA):
pip install "nexus-ai[ai]"

# For CPU-only:
pip install "nexus-ai[ai]"
```

### 3. Download AI Models

```bash
# Download all required GGUF models with SHA-256 integrity verification
python -m nexus_ai.scripts.download_models

# Only verify existing models without re-downloading
python -m nexus_ai.scripts.download_models --verify-only

# Download a specific model
python -m nexus_ai.scripts.download_models --model alpha
```

The script downloads the following models:

| Model | Size | Purpose |
|---|---|---|
| `LFM2.5-1.2B-Q4_K_M.gguf` | ~800 MB | Alpha Agent — Primary classification |
| `Qwen3-0.6B-Q4_K_M.gguf` | ~450 MB | Beta Agent — Secondary validation |
| `LittleLamb-0.3B-Q4_K_M.gguf` | ~200 MB | Gamma / Orchestrator Agent |
| `granite-4.0-1b-nano-Q4_K_M.gguf` | ~600 MB | Rules / Decision Agent |
| `qwen2.5-1.5b-instruct-Q4_K_M.gguf` | ~1 GB | Analytics Agent — Anomaly detection |
| `Jamba-Reasoning-3B-Q4_K_M.gguf` | ~2 GB | Decision Agent — Complex reasoning |
| `ParagonDetect-0.1B-Q4_K_M.gguf` | ~100 MB | Agent Ekstrakcji Danych — wykrywanie i ekstrakcja paragonów |
| `FinBERT-ESG-0.1B-Q4_K_M.gguf` | ~100 MB | Agent Walidator Jakości — weryfikacja zgodności ESG |
| `GraphSAGE-Encoder-0.1B-Q4_K_M.gguf` | ~100 MB | Agent Walidator Jakości — grafowa analiza relacji |

### 4. Run Diagnostics

After downloading models, verify the setup:

```bash
python -m nexus_ai.scripts.doctor
```

This checks:
- ✅ Python version (3.13+)
- ✅ CUDA/GPU availability
- ✅ All required GGUF models present and integrity-verified
- ✅ NATS server connectivity
- ✅ Environment configuration
- ✅ System resources (RAM, disk)

---

## Troubleshooting

### NATS Server Not Running

```bash
# Check if NATS is running
nats-server -version

# Start NATS
nats-server -p 4222 -js

# Verify connection
python -c "import nats; import asyncio; print(asyncio.run(nats.connect('nats://localhost:4222')))"
```

### Database Initialization

The application auto-creates tables on startup. If you need to reset:

```bash
rm -f nexus_oltp.db nexus_olap.duckdb
python -c "from nexus_ai.core.config import AppConfig; from nexus_ai.db.database import create_oltp_engine, init_schema; import asyncio; asyncio.run(init_schema(create_oltp_engine(AppConfig())))"
```

### Common Issues

| Issue | Solution |
|---|---|
| `ModuleNotFoundError: No module named 'api'` | Run from project root, not from `nexus_ai/` |
| `NATS connection refused` | Start NATS server first: `nats-server -p 4222 -js` |
| `NEXUS_JWT_SECRET not set` | Set it in `.env` or one will be auto-generated for dev |
| `SQLCipher encryption error` | Ensure nexus-crypto package is installed |

### License

Proprietary. All rights reserved.
