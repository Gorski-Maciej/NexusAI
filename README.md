# NexusAI — AI-Powered Accounting & Invoice Processing System

[![Python](https://img.shields.io/badge/Python-3.11%2B-blue)](https://python.org)
[![Litestar](https://img.shields.io/badge/Litestar-2.8%2B-blueviolet)](https://litestar.dev)
[![NATS](https://img.shields.io/badge/NATS-JetStream-27ae60)](https://nats.io)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

**NexusAI** is a next-generation, AI-driven accounting platform designed for Polish businesses. It combines OCR-based invoice processing, multi-agent AI decision-making (council of LLMs), double-entry ledger integration via TigerBeetle, and real-time event streaming via NATS JetStream — all wrapped in a modern Litestar API and a Flet-based desktop UI.

---

## Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Environment Configuration](#environment-configuration)
- [Running the Application](#running-the-application)
  - [Option A: Local Development (Recommended)](#option-a-local-development-recommended)
  - [Option B: Docker Compose](#option-b-docker-compose)
  - [Option C: Desktop UI (Flet)](#option-c-desktop-ui-flet)
- [API Documentation](#api-documentation)
- [Running Tests](#running-tests)
- [Project Structure](#project-structure)
- [Key Modules](#key-modules)
- [Environment Variables Reference](#environment-variables-reference)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Features

- **🤖 AI Agent Council** — Multi-LLM agent system (Qwen, Granite, Jamba, LittleLamb) for invoice classification, anomaly detection, rules validation, and automated posting.
- **📄 Intelligent OCR Pipeline** — Document preprocessing, layout analysis, text extraction, and vision-based validation (Qwen2.5-VL).
- **📊 Real-time Analytics** — DuckDB-powered OLAP views for cashflow projection, monthly summaries, vendor scoring, and anomaly detection.
- **🔒 Double-Entry Ledger** — TigerBeetle integration for two-phase commit transfers with Polish chart of accounts.
- **📨 Event-Driven Architecture** — NATS JetStream message broker with task queues, outbox pattern, and dead-letter replay.
- **🔐 Security** — JWT authentication, SQLCipher at-rest encryption, rate limiting, CSRF protection, and offline-first secrets management.
- **🌐 i18n** — Multi-language support with Polish as primary language.
- **📦 Containerized** — Full Docker Compose environment for easy deployment.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     Flet Desktop UI                      │
│                    (Python / Flutter)                    │
└──────────────┬──────────────────────────────────────────┘
               │ HTTP / WebSocket
┌──────────────▼──────────────────────────────────────────┐
│              Litestar API (ASGI / Uvicorn)               │
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
                              ┌──────────────┐
                              │  TigerBeetle  │
                              │  Ledger       │
                              │  (2PC)        │
                              └──────────────┘
```

---

## Installation

### Quick Install (pip)

NexusAI can be installed directly via pip as a Python package:

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

### Development Install (from source)

```bash
# 1. Clone the repository
git clone https://github.com/your-org/NexusAI.git
cd NexusAI

# 2. Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# 3. Install in editable mode with all extras
pip install -e ".[ui,ai,dev]"

# 4. Copy and configure environment
cp .env.example .env
# Edit .env with your settings (minimal defaults work for local dev)
```

---

## Prerequisites

- **Python** 3.11 or higher
- **pip** (Python package manager)
- **NATS Server** (with JetStream support) — [Download](https://nats.io/download/)
- **TigerBeetle** (optional, local stub included) — [Download](https://tigerbeetle.com/)
- **Git** (for cloning the repository)

### Optional (for AI features)

- **GGUF Model Files** — Download models for agent council (see [Downloading Models](#downloading-models))
- **Tesseract OCR** — For document text extraction
- **CUDA drivers** (NVIDIA GPU) or **llama-cpp-python** — For local LLM inference

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/your-org/NexusAI.git
cd NexusAI

# 2. Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# 3. Install in editable mode
pip install -e .

# 4. Copy and configure environment
cp .env.example .env
# Edit .env with your settings (minimal defaults work for local dev)

# 5. Run system diagnostics (recommended)
python main.py --mode doctor

# 6. Start NATS server (in a separate terminal)
nats-server -p 4222 -js

# 7. Run the application
python main.py
```

The API will be available at **http://127.0.0.1:8000** with Swagger UI at **http://127.0.0.1:8000/schema/swagger**.

After `pip install -e .`, you can also use the installed CLI commands directly:

```bash
# Start the API server
nexus-api

# Start the Taskiq worker
nexus-worker

# Start the desktop UI (requires flet)
nexus-desktop

# Run diagnostics
nexus --mode doctor
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

### Option A: Local Development (Recommended)

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

### Option B: Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

This starts:
- **api** — Litestar API server (port 8000)
- **worker** — Taskiq worker for background OCR/AI tasks
- **nats** — NATS JetStream message broker (port 4222)
- **tigerbeetle** — TigerBeetle ledger (port 3000)

### Option C: Desktop UI (Flet)

```bash
# Using installed CLI (after pip install -e .)
nexus-desktop

# Or directly via Python
python -m Code.luz.main
```

This starts a full desktop application with:
- Splash screen with startup progress
- NATS server auto-start
- Background worker
- API server (auto-assigned port)
- Flet-based graphical interface

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
python -m pytest tests/

# Run specific test file
python -m pytest tests/test_inventory_fifo.py -v

# Run with coverage
python -m pytest tests/ --cov=Code --cov-report=term-missing

# Run performance benchmarks
python -m pytest tests/performance/ -v
```

### Test structure

| Test file | What it covers |
|---|---|
| `tests/test_rules_engine.py` | Rules engine and validation logic |
| `tests/test_fixed_assets_depreciation.py` | Fixed assets depreciation |
| `tests/test_inventory_fifo.py` | FIFO inventory accounting |
| `tests/test_fraud_graph_scanner.py` | Fraud detection graph scanning |
| `tests/test_forex_engine.py` | Foreign exchange revaluation |
| `tests/test_reconciliation_engine.py` | Account reconciliation |
| `tests/test_dunning_engine.py` | Dunning/collections engine |
| `tests/test_smart_approvals.py` | Smart approval workflows |
| `tests/test_council_session.py` | AI agent council coordination |
| `tests/test_autopilot.py` | Autopilot decision automation |
| `tests/test_vision_agent.py` | Vision-based invoice analysis |
| `tests/test_audit_storno.py` | Audit and storno corrections |
| `tests/test_budgetary_control.py` | Budget control enforcement |
| `tests/test_bank_import.py` | Bank statement import |
| ...and many more | |

---

## Project Structure

```
NexusAI/
├── main.py                    # Central application entry point
├── pyproject.toml              # Package configuration (NEW)
├── requirements.txt           # Python dependencies (legacy)
├── .gitignore                 # Git ignore rules (NEW)
├── .env.example               # Environment template
├── Dockerfile                 # Container build
├── docker-compose.yml         # Multi-service orchestration
├── run_local.py               # Legacy local launcher
│
├── Code/                      # Main package directory
│   ├── API/                   # Litestar API application
│   │   ├── app.py             # API app factory (create_app)
│   │   ├── server.py          # Uvicorn server entrypoint
│   │   ├── state.py           # Startup/shutdown lifecycle
│   │   ├── security.py        # JWT authentication
│   │   ├── middleware.py       # HTTP middleware
│   │   ├── dependencies.py    # DI providers
│   │   └── routes/            # API route controllers
│   │
│   ├── core/                  # Core shared modules
│   │   ├── config.py          # AppConfig dataclass (env vars)
│   │   ├── broker.py          # NATS Taskiq broker setup
│   │   ├── tasks.py           # Background task definitions
│   │   ├── secrets.py         # Offline-first secrets manager
│   │   ├── crypto.py          # Encryption (Fernet + PBKDF2)
│   │   ├── logger.py          # Loguru logging setup
│   │   ├── bus.py             # In-process event bus
│   │   ├── outbox_relay.py    # Outbox → NATS relay
│   │   └── saga.py            # Persisted saga store
│   │
│   ├── services/              # Business logic services
│   │   ├── rules_engine.py    # Invoice validation rules
│   │   ├── analytics_service.py
│   │   ├── fraud_graph_scanner.py
│   │   ├── fixed_assets.py
│   │   ├── inventory_fifo.py
│   │   ├── dunning_engine.py
│   │   ├── liquidity_oracle.py
│   │   └── ...                # 45+ service modules
│   │
│   ├── DB/                    # Database layer
│   │   ├── database.py        # SQLAlchemy engine + session factory
│   │   ├── analytics.py       # DuckDB manager
│   │   ├── outbox.py          # Outbox pattern models
│   │   ├── views.py           # Analytics materialized views
│   │   └── vector_store.py    # Vector storage (LanceDB)
│   │
│   ├── PIPELINE/              # Document processing pipeline
│   │   ├── ocr.py             # OCR engine
│   │   ├── ocr_engine.py      # Tesseract wrapper
│   │   ├── vision_agent.py    # Visual AI analysis
│   │   ├── preprocessor.py    # Document preprocessing
│   │   ├── splitter.py        # Document splitting
│   │   └── ...                # Pipeline stages
│   │
│   ├── Roboton_Reflekton/     # Accounting engine module
│   │   ├── ledger_client.py   # TigerBeetle client (stub)
│   │   ├── ledger_initializer.py
│   │   ├── reconciliation_engine.py
│   │   ├── dunning_engine.py
│   │   ├── shadow_ledger.py   # Tax simulation
│   │   ├── vat_reconciliation.py
│   │   ├── forex_engine.py
│   │   └── models.py          # Domain models
│   │
│   ├── luz/                   # Desktop application (Flet)
│   │   ├── main.py            # Flet UI orchestrator
│   │   └── worker.py          # Taskiq worker entrypoint
│   │
│   ├── FRONTEND/              # Flet UI components
│   ├── MODELS/                # SQLAlchemy ORM models
│   ├── ARCHITECTURE/          # Architecture documentation
│   └── scripts/               # Utility scripts
│       ├── download_models.py # Model downloader (SHA-256 verified)
│       └── doctor.py          # System diagnostics
│
├── tests/                     # Test suite
│   ├── conftest.py            # Shared test fixtures
│   ├── test_reconciliation_engine.py
│   ├── test_fraud_graph_scanner.py
│   └── ...                    # 80+ test files
│
└── app_data/                  # Runtime data directory
    ├── secrets_cache.json     # Local secrets cache
    └── uploads/               # File uploads
```

---

## Key Modules

### 🤖 AI Agent Council (`Code/services/council_agents.py`)

Multi-LLM agent system that evaluates invoices through specialized agents:
- **Alpha Agent** (LFM 1.2B) — Primary classification
- **Beta Agent** (Qwen3 0.6B) — Secondary validation
- **Gamma Agent** (LittleLamb 0.3B) — Tiebreaker + reasoning
- **Rules Agent** (Granite 1B) — Business rule enforcement
- **Analytics Agent** (Qwen2.5 1.5B) — Anomaly detection

### 📄 OCR Pipeline (`Code/PIPELINE/`)

Document processing pipeline with stages:
1. **Preprocessor** — Image enhancement, deskew, binarization
2. **Splitter** — Multi-page document splitting
3. **OCR Engine** — Tesseract-based text extraction
4. **Vision Agent** — Qwen2.5-VL visual analysis
5. **Refiner** — Post-processing and correction
6. **QA Engine** — Quality assurance checks

### 🔒 Ledger System (`Code/Roboton_Reflekton/`)

Double-entry accounting with:
- Polish chart of accounts (symbole kont)
- TigerBeetle two-phase commit transfers
- Financial period locking (HARD_CLOSED)
- Shadow ledger for "what-if" tax simulations
- VAT reconciliation engine

### 🔄 Event System (`Code/core/`)

Event-driven architecture:
- **NATS JetStream** — Durable message streaming
- **Outbox Pattern** — Reliable event publishing
- **Taskiq** — Async task queue with scheduling
- **Circuit Breaker** — Fault tolerance for NATS operations
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
| `NEXUS_JWT_EXPIRATION_SECONDS` | `900` | JWT token expiry (overridden to 900s) |
| `NEXUS_JWT_ISSUER` | `nexus-ai` | JWT issuer claim |
| `NEXUS_JWT_AUDIENCE` | `nexus-api` | JWT audience claim |
| `NEXUS_REFRESH_TOKEN_DAYS` | `30` | Refresh token validity days |
| `NEXUS_ADMIN_USERNAME` | `admin` | Default admin username |
| `NEXUS_ADMIN_PASSWORD` | `admin` | Default admin password |
| `NEXUS_ENCRYPTION_KEY` | *(empty)* | 32-byte base64-url key **(required in prod)** |
| `NEXUS_SQLCIPHER_KEY` | *(empty)* | SQLCipher database encryption key |
| `NEXUS_SQLCIPHER_KEY_ENV` | `NEXUS_SQLCIPHER_KEY` | Env var name for SQLCipher key |
| **Database** | | |
| `NEXUS_SQLITE_FILE` | `nexus_oltp.db` | SQLite OLTP database filename |
| `NEXUS_DUCKDB_FILE` | `nexus_olap.duckdb` | DuckDB OLAP database filename |
| `NEXUS_DUCKDB_MEMORY_LIMIT` | `512MB` | DuckDB memory limit |
| `NEXUS_DUCKDB_THREADS` | `2` | DuckDB thread count |
| `NEXUS_IDEMPOTENCY_DB` | `idempotency.sqlite` | Idempotency store filename |
| **NATS** | | |
| `NEXUS_NATS_URL` | `nats://localhost:4222` | NATS server URL |
| `NEXUS_MAX_PARALLEL_OCR` | `1` | Max concurrent OCR tasks |
| `NEXUS_OCR_TIMEOUT_SEC` | `300` | OCR task timeout in seconds |
| `NEXUS_MODEL_CACHE_TTL_SEC` | `600` | ML model cache TTL |
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
| **Infiscal (Secrets Management)** | | |
| `NEXUS_INFISCAL_JWT_SECRET` | *(empty)* | Infiscal fallback for JWT secret |
| `NEXUS_INFISCAL_ENCRYPTION_KEY` | *(empty)* | Infiscal fallback for encryption key |
| **TigerBeetle** | | |
| `TB_CLUSTER_ID` | `0` | TigerBeetle cluster ID |
| `TB_REPLICA_ADDRESSES` | `3000` | TigerBeetle replica addresses |

---

## AI Models Setup

NexusAI uses a Council of LLMs for intelligent invoice processing. Setting up the AI environment involves:

### 1. Hardware Requirements

- **GPU (recommended):** NVIDIA GPU with CUDA support (6 GB+ VRAM)
- **CPU (minimum):** 8 GB RAM, 4+ cores
- **Disk:** ~10 GB free for model files

### 2. Install AI Dependencies

```bash
# For GPU (CUDA) — install PyTorch with CUDA first:
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu124

# Then install AI extras:
pip install "nexus-ai[ai]"  # or: pip install -e ".[ai]"

# For CPU-only:
pip install "nexus-ai[ai]"
```

### 3. Download AI Models

```bash
# Download all required GGUF models with SHA-256 integrity verification
python Code/scripts/download_models.py

# Only verify existing models without re-downloading
python Code/scripts/download_models.py --verify-only

# Download a specific model
python Code/scripts/download_models.py --model alpha
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

### 4. Run Diagnostics

After downloading models, verify the setup:

```bash
python main.py --mode doctor
```

This checks:
- ✅ Python version (3.11+)
- ✅ CUDA/GPU availability
- ✅ All required GGUF models present and integrity-verified
- ✅ NATS server connectivity
- ✅ Environment configuration (.env)
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
rm -f nexus_oltp.db nexus_olap.duckdb app_data/idempotency.sqlite
python -c "from core.config import AppConfig; from db.database import create_oltp_engine, init_schema; import asyncio; asyncio.run(init_schema(create_oltp_engine(AppConfig())))"
```

### Common Issues

| Issue | Solution |
|---|---|
| `ModuleNotFoundError: No module named 'api'` | Run from project root, not from `Code/` |
| `NATS connection refused` | Start NATS server first: `nats-server -p 4222 -js` |
| `NEXUS_JWT_SECRET not set` | Set it in `.env` or one will be auto-generated for dev |
| `SQLCipher encryption error` | Ensure `cryptography` package is installed |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Coding Standards

- Type hints required for all Python code
- Async-first design (use `asyncio`, avoid blocking calls)
- Follow existing patterns (SQLAlchemy async sessions, DI via Litestar)
- Tests required for new features
- Documentation in Polish and English

---

## License

Proprietary. All rights reserved.

---

## Additional Resources

- [Codebuff CLI](https://codebuff.com) — AI coding assistant used in development
- [Litestar Documentation](https://litestar.dev)
- [NATS Documentation](https://docs.nats.io)
- [TigerBeetle Documentation](https://docs.tigerbeetle.com)
- [Taskiq Documentation](https://taskiq.apachebook.com)
- [Flet Documentation](https://flet.dev)
