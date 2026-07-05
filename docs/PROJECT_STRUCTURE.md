# 🗂️ Struktura projektu NexusAI

> **Cel:** Pozwolić nowemu developerowi znaleźć dowolny plik w kodzie w mniej niż **30 sekund**.

---

## 1. Top-level — widok z lotu ptaka

```
NexusAI/
├── nexus_ai/                    # ⭐ Główny pakiet aplikacji (Python + Rust)
│   ├── api/                     # Litestar REST API (controllers, routes, DTOs)
│   ├── core/                    # Fundament: config, crypto, mimalloc, brokers, plugins
│   ├── db/                      # SQLModel + SQLAlchemy (OLTP) — modele, sesje│   ├── services/                    # 70+ serwisów biznesowych (accounting, OCR, KSeF, RMK, FinOps, …)
│   ├── events/                  # Event bus: domain events, projections, JetStream
│   ├── domain/                  # Value Objects, agregaty DDD (Money, NIP, IBAN)
│   ├── pipeline/                # Potoki przetwarzania (OCR consensus parser)
│   ├── scripts/                 # Skrypty CLI (download_models, backup, doctor)
│   ├── integrations/            # Integracje zewn.: KSeF, mail_fetcher
│   ├── installer/               # Inno Setup, updater, dependency downloader
│   ├── luz/                     # CLI worker / desktop entry points
│   ├── frontend/                # Flet UI (komponenty Material Design 3)
│   ├── rust/                    # 🔧 nexus-crypto (Rust + PyO3, kompilowane maturin)
│   ├── architecture/            # ADR / schematy architektoniczne
│   ├── config/                  # TOML/JSON: base/dev/prod
│   └── tax/                     # Rego policies (OPA) dla reguł podatkowych
├── migrations/                  # Surowe pliki SQL (001_init.sql, 002_…, 003_…, 004_…)
├── tests/                       # ~120 plików testów (unit + integration + schemathesis + locust)
├── docs/                        # 📚 Ta dokumentacja (patrz [INDEX](INDEX.md))
├── .github/workflows/           # CI/CD pipelines (CI, Security, Dependabot, Setup)
├── models/                      # Modele GGUF (pobierane przez download_models.py)
├── assets/                      # Ikony, logo (.ico, .png)
├── app_data/                    # Runtime: baza SQLite, logi, cache (tworzone dynamicznie)
├── reports/                     # Raporty diagnostyczne
├── pyproject.toml               # ⭐ Hatchling + maturin + mypyc + Ruff + mypy + crosshair
├── pixi.toml                    # ⭐ Środowisko developerskie + 50+ tasków
├── python-source.cfg            # Konfiguracja Nuitka (legacy alias)
├── user.nuitka-package-config.yml # 🌙 Konfiguracja Nuitka (binary .exe)
├── LICENSE.txt                  # Licencja Proprietary
├── README.md                    # Strona główna (mission, quickstart)
├── RAPORT_TECHNOLOGII_NEXUSAI.txt # ⭐ Wiążący opis aktualnego stosu tech.
└── start.sh                     # Skrypt pomocniczy (git pull + auto-commit)
```

---

## 2. Szczegółowe drzewo `nexus_ai/`

```
nexus_ai/
├── __init__.py                  # Re-exports (główna fasada)
├── main.py                      # ⭐ Thin CLI shim — deleguje do pixi
├── api/                         # 🛰️ REST API (Litestar)
│   ├── app.py                   # Litestar konfiguracja (middeware, plugins, route'ry)
│   ├── server.py                # Granian runner
│   ├── routes/                  # 27 route files (1 na tag OpenAPI)
│   │   ├── auth.py                  # JWT, refresh, password reset
│   │   ├── invoices.py              # CRUD faktur + upload
│   │   ├── contractor.py            # CRUD kontrahentów
│   │   ├── ksef.py                  # KSeF XML export (FA_VAT)
│   │   ├── billing.py               # Estymacja kosztów
│   │   ├── analytics.py             # Zapytania analityczne (DuckDB, AS-OF JOIN)
│   │   ├── dashboard.py             # Dashboard + daily briefing
│   │   ├── triage.py                # Centrum decyzji (ASK_USER)
│   │   ├── autopilot.py             # Decyzje AI (accept/reject/trust score)
│   │   ├── admin.py                 # Panel admin (DLQ, rules, users, replay)
│   │   ├── audit.py                 # Kryptograficzny ślad audytowy
│   │   ├── risk.py                  # Risk Guard API (progi ryzyka)
│   │   ├── health.py                # Health/readiness/liveness
│   │   ├── workers.py               # Status workera (Taskiq)
│   │   ├── events_schema.py         # JSON Schema DomainEvents
│   │   ├── ws.py                    # WebSocket (SSE-like progress)
│   │   ├── ui_state.py              # UI Draft persistence
│   │   ├── system_ops.py            # 8 kontrolerów (i18n, security, circuit-breakers, telemetry, finops, privacy, kore, version)
│   │   ├── system_integrity.py      # Integralność migracji + cleanup UI drafts
│   │   ├── performance_ops.py       # Locust performance summary
│   │   ├── partner.py               # Partner Hub (biura rachunkowe)
│   │   ├── exports.py               # Eksport danych (CSV/Excel/JSON/PDF)
│   │   ├── tax_policy.py            # Symulacja polityki podatkowej
│   │   ├── tax_math.py              # Kalkulacja VAT (Decimal)
│   │   ├── kore_closure.py          # KORE closure summary
│   │   ├── tasks.py                 # Status + anulowanie zadań async
│   │   ├── outbox_ops.py            # Outbox stats (deprecated, NATS)
│   │   ├── dlq.py                   # Dead Letter Queue management
│   │   ├── security_alert.py        # SecurityAlert auto-CRUD
│   │   ├── files.py                 # File management (CSP sandbox)
│   │   ├── live_preview.py          # Live preview OCR
│   │   ├── stats.py                 # Podstawowe statystyki
│   │   └── dev/                     # Development-only routes
│   ├── dto.py                   # MsgspecDTO + DTOConfig (request/response)
│   ├── schemas.py               # Raw schemas (Litestar-generated)
│   ├── security.py              # JWT config + hasła (Argon2id przez nexus-crypto)
│   ├── rbac.py                  # Role + Permissions + Guard functions
│   ├── middleware.py            # Tenant context, rate limit, CSRF
│   ├── exceptions.py            # Domain errors → RFC 9457 problem+json
│   ├── i18n.py                  # Internacjonalizacja (en, pl)
│   ├── tasks/                   # Background tasks (decision, ocr, outbox)
│   ├── telemetry_metrics.py     # OpenTelemetry metryki
│   └── locales/                 # en.json, pl.json
│
├── core/                        # 🧠 Fundament
│   ├── config.py                # TOML Loader + Profile stack (base → dev → prod)
│   ├── crypto.py                # Vault: AEAD ChaCha20-Poly1305 + Argon2id + mlock
│   ├── mimalloc_bridge.py       # Microsoft mimalloc integration
│   ├── broker.py                # NATS connection (broker management)
│   ├── bus.py                   # Internal pub/sub (inproc)
│   ├── plugins.py               # Plugin loader (dynamic imports)
│   ├── tasks.py                 # Cross-cutting task base classes
│   ├── events.py                # Core event types
│   ├── secrets.py               # Keyring + encrypted cache (RBAC)
│   ├── sentry.py                # Sentry SDK init
│   ├── otel.py                  # OpenTelemetry setup (traces, metrics, logs)
│   ├── di.py                    # Dependency injection container
│   ├── ai_context.py            # AI context window management
│   ├── inference.py             # LLM inference (llama.cpp wrapper)
│   ├── adaptive_batcher.py      # Dynamic batching for OCR/AI
│   ├── monitoring.py            # System resource monitor (psutil)
│   ├── cache/                   # HTTP cache (hishel), invalidation
│   ├── exporters/               # Data exporters (e.g. CSV/XLSX)
│   ├── protocol_executor.py     # Decision protocol enforcement
│   ├── protocol_loader.py       # YAML/JSON protokoły decyzyjne
│   ├── architectures/           # PerfectAccountingArchitecture (DDD helpers)
│   └── messages_*.py            # Cross-cutting message types
│
├── db/                          # 💾 OLTP (SQLite + SQLCipher)
│   ├── models.py                # ⭐ SQLModel defs (Invoice, Contractor, AuditLog, Outbox…)
│   ├── database.py              # Engine + session factory + tenant context
│   ├── security.py              # SQLCipher key management + rotation
│   ├── hooks.py                 # SQLAlchemy before_flush validation
│   ├── transactions.py          # Unit of Work (DDD)
│   ├── queries.py               # Reużywalne SELECTy (typed)
│   ├── projection_models.py     # Read models (CQRS)
│   ├── analytics.py             # Analityczne helperry (Polars + DuckDB)
│   ├── analytics_schema.py      # Spec OLAP (stary, deprecated)
│   ├── vector_store.py          # sqlite-vec integration
│   ├── async_*.py               # async pool, async_backup (asyncio-friendly)
│   └── zpk_schema.py            # JPK schema helpers
│
├── services/                    # 🏗️ Logika biznesowa (70+ serwisów)
│   ├── accountant_logic.py      # ⭐ ZPKEngine (plan kont, dekretacja)
│   ├── services.py              # Re-eksport (fasada)
│   ├── core_services.py         # ValidationService, AnalyticsService
│   ├── admin_services.py        # RiskThreshold, BillingRule, LDAP rules, Tax rules
│   ├── triage_service.py        # Centrum decyzji (ASK_USER) — logika
│   ├── period_closer.py         # ⭐ Zamknięcie okresu finansowego (KORE) [NOWY]
│   ├── rmk_engine.py            # ⭐ Silnik RMK (rozliczenia międzyokresowe) [NOWY]
│   ├── finops_meter.py          # ⭐ FinOps — zużycie zasobów/billing [NOWY]
│   ├── document_fingerprint.py  # ⭐ Odciski dokumentów (SHA-256 + sig) [NOWY]
│   ├── tigerbeetle_secure.py    # ⭐ Secure TigerBeetle client [NOWY]
│   ├── opa_policy_generator.py  # ⭐ Generowanie reguł Rego [NOWY]
│   ├── decision_structs.py      # Structy decyzyjne (TriageDecision, DecisionMode)
│   ├── decision_queue.py        # Decision Queue (persistence + wyświetlanie)
│   ├── decision_logger.py       # Proof Chain (SHA-256) dla każdej decyzji
│   ├── auto_decree.py           # AutoDecreeService (inteligentna dekretacja)
│   ├── audit_service.py         # Audit trail (5 rodzajów eventów)
│   ├── audit_storno.py          # Storno (korekty księgowe)
│   ├── fraud_graph_scanner.py   # ⭐ GraphSAGE detekcja fraudów (VAT karuzele)
│   ├── vendor_intelligence.py   # ⭐ Risk scoring kontrahentów (Biała Lista + ESG)
│   ├── scheduler.py             # APScheduler-like (cron tasks)
│   ├── bank_import.py           # Import wyciągów bankowych
│   ├── ksef_service.py          # Komunikacja z KSeF API
│   ├── ksef_generator.py        # XML FA_VAT(2) generowanie
│   ├── tax_simulator.py         # Symulacje podatkowe (lump_sum vs linear)
│   ├── tax_strategies.py        # Strategie optymalizacji
│   ├── tax_api.py               # Tax endpoints (CPU/CIT/VAT)
│   ├── tax_math.py              # Matematyka podatkowa (szybkość)
│   ├── vat_reconciliation.py    # JPK_V7 reconciliacja
│   ├── fx_revaluation.py        # Rewaluacja walutowa (NBP rates)
│   ├── inventory_fifo.py        # FIFO magazyn
│   ├── fixed_assets.py          # ⭐ Środki trwałe + amortyzacja
│   ├── billing_estimator.py     # Szacowanie kosztów
│   ├── budget_control.py        # Kontrola budżetowa
│   ├── dunning_engine.py        # Wezwania do zapłaty
│   ├── notification_service.py  # Powiadomienia (kanały: app, email, push)
│   ├── notification_manager.py  # Orkiestracja powiadomień
│   ├── compliance_analytics.py  # Compliance reporting
│   ├── integrity_verifier.py    # SHA-256 proof chain
│   ├── proof_chain.py           # ⭐ SHA-256 chain (każda decyzja = hash)
│   ├── facts_aggregator.py      # ⭐ Fakty (miar. księgowe) + decyzje
│   ├── security_service.py      # Retention + secure delete
│   ├── risk_guard.py            # Risk-API guard (transakcje ryzykowne)
│   ├── hot_reload.py            # Hot reload of rules/configs
│   ├── liquidity_oracle.py      # ⭐ Predykcja płynności (Lag-Llama?)
│   ├── cfo_offline.py           # ⭐ Pakiet usług offline-first CFO
│   │   ├── LocalRAGService      # Lokalny RAG
│   │   ├── KSEFDefenderService  # Detekcja zagrożeń KSeF
│   │   ├── CashflowForecastService # Prognoza cashflow
│   │   ├── PaymentPriorityService # Priorytetyzacja płatności
│   │   └── AutoDecreeService    # Auto-dekrety
│   ├── events.py / event_log.py # Audit event log
│   ├── shadow_resource_correlation.py # Korelacja zasobów
│   ├── fraud_graph_scanner.py   # Detekcja fraud
│   ├── shadow_*.py              # Shadow mode (testowanie decyzji)
│   ├── tax/                     # Rego policies (alternatywa dla service)
│   ├── audit/                   # Specjalne audit checks
│   ├── infrastructure/          # Generic infrastructure
│   ├── accounting/              # Rozszerzenie accountant_logic
│   ├── pdfium/                  # ⭐ PDF render (pypdfium2 wrapper)
│   ├── tigerbeetle/             # Wrapper na TigerBeetle client
│   │   ├── client.py
│   │   ├── ledger_initializer.py
│   │   └── models.py
│   ├── architecture/                # 🏛️ Architectural helpers
│   │   └── perfect_accounting_architecture.py # DDD Aggregate, VO base classes
│   └── … (~70 plików serwisów)
│
├── events/                      # 📡 Event Sourcing & CQRS
│   ├── domain_events.py         # ⭐ Definicje zdarzeń (InvoiceCreated, …)
│   ├── event_store.py           # Trwały magazyn zdarzeń (outbox pattern)
│   ├── projections.py           # Projekcje (read models z eventów)
│   ├── jetstream_bus.py         # NATS JetStream bridge
│   ├── projection_worker.py     # Worker przetwarzający eventy
│   └── taskiq_events.py         # Taskiq task definitions
│
├── domain/                      # 🎯 DDD Value Objects + Agregaty
│   ├── values.py                # ⭐ Money, NIP, IBAN, PESEL, VATRate
│   └── aggregates.py            # ⭐ Invoice, Contractor, Account, Asset, CompanyProfile
│
├── pipeline/                    # 🔄 Potoki przetwarzania
│   ├── ocr_base.py              # Abstrakcyjny silnik OCR
│   ├── ocr_consensus.py         # ⭐ 4 silniki + consensus (Levenshtein + AI Supervisor)
│   └── parser.py                # PDF parser (pypdfium2)
│
├── scripts/                     # 🛠️ CLI scripts
│   ├── download_models.py       # ⭐ Pobiera 5 modeli GGUF + SHA-256 verify
│   ├── backup.py                # Szyfrowany backup (Vault)
│   ├── reset_db.py              # Reset bazy (development)
│   ├── seed_data.py             # Demo data
│   ├── init.py                  # Bootstrap
│   └── seed_data.toml           # Konfiguracja seed
│
├── integrations/                # 🔌 Integracje zewnętrzne
│   ├── mail.py                  # IMAP/POP3 mail fetcher
│   ├── ksef_crypto.py           # RSA helpers for KSeF
│   ├── ksef/                    # Certyfikaty + schematy KSeF
│   │   ├── bindings/                # Generated FA_VAT schemas (xsdata)
│   │   ├── schema/                  # FA_VAT.xsd + HTML pages
│   │   ├── client.py                # KSeF API client
│   │   ├── crypto.py                # RSA encryption
│   │   └── xsd_bindings.py          # XSD-bounded classes
│
├── installer/                   # 📦 Instalator Windows + updater
│   ├── build_scripts/           # Inno Setup (.iss) + NSIS (.nsi)
│   ├── dependency_downloader.py # Pobiera natywne binarki (TigerBeetle, NATS, OPA)
│   ├── dependency_ui.py         # UI progress dialog
│   ├── download_progress_ui.py  # Sub-UI
│   ├── models_downloader.py     # UI dla pobierania modeli
│   ├── notification_win.py      # Windows toast notifications
│   └── updater.py               # ⭐ OTA updater (LiteServ)
│
├── luz/                         # 💡 Worker + desktop entry points
│   ├── main.py                  # Desktop entry (Flet)
│   ├── worker.py                # Worker entry (Taskiq)
│   └── build_nexus.py           # Nuitka build helper
│
├── frontend/                    # 🪟 Flet UI (Flutter)
│   ├── main.py                  # Entry (Flet)
│   ├── router.py                # Flet Router
│   ├── charts.py                # BarChart, LineChart, PieChart
│   ├── components/              # Reużywalne widgety
│   ├── views/                   # 7 widoków (dashboard, partner_hub, …)
│   ├── ui/                      # Theme, state storage, root, validators
│   └── web_app.py               # Web mode (optional)
│
├── rust/                        # 🦀 Rust + PyO3 (nexus-crypto)
│   ├── Cargo.toml               # maturin manifest
│   ├── pyproject.toml           # Build config
│   └── src/                     # AEAD, Argon2id, SHA-256 (Rust)
│
├── architecture/                # 🏛️ Architectural helpers
│   └── perfect_accounting_architecture.py # DDD Aggregate, VO base classes
│
├── config/                      # ⚙️ Konfiguracja
│   ├── base.toml                # ⭐ Konfiguracja bazowa
│   ├── dev.toml                 # Dev overrides
│   ├── prod.toml                # Prod overrides
│   ├── protocols.toml           # Decyzje protokoły
│   └── version.json             # ⭐ Wersja + komponenty
│
└── tax/                         # 📐 Rego (OPA)
    ├── __init__.py
    └── rules.rego               # Zasady podatkowe (reguły)
```

---

## 2.1 Diagram zależności między modułami

<!-- UZUPEŁNIONE: zmieniono z 2a na 2.1 dla zgodności z narzędziami automatycznymi -->

<!-- UZUPEŁNIONE: dodano diagram zależności -->

```mermaid
flowchart TD
    subgraph Prezentacja
        FRONTEND[frontend/ - Flet UI]
    end
    
    subgraph API
        API[api/ - Litestar REST]
        ROUTES[api/routes/ - 27 kontrolerów]
    end
    
    subgraph Aplikacja
        SCRIPTS[scripts/ - CLI]
        WORKER[luz/ - Taskiq Worker]
        SERVICES[services/ - logika biznesowa]
        EVENTS[events/ - Event Sourcing]
        PIPELINE[pipeline/ - OCR]
    end
    
    subgraph Domena
        DOMAIN[domain/ - Value Objects]
        DB[db/ - SQLModel + SQLAlchemy]
    end
    
    subgraph Infrastruktura
        CORE[core/ - config, crypto, otel]
        INTEGRATIONS[integrations/ - KSeF, GUS]
        INSTALLER[installer/ - setup, OTA]
        TAX[tax/ - Rego policies]
        RUST[rust/ - nexus-crypto]
    end
    
    subgraph Dane
        SQLITE[(SQLite + SQLCipher)]
        DUCKDB[(DuckDB)]
        TB[(TigerBeetle)]
        NATS[(NATS JetStream)]
    end
    
    FRONTEND -->|REST/WS| API
    API --> ROUTES
    
    ROUTES -->|Zapytania| DB
    ROUTES -->|Publikuj zadania| NATS
    
    NATS -->|Dostarcz| WORKER
    WORKER --> SERVICES
    
    SERVICES --> DB
    SERVICES -->|Double-entry| TB
    SERVICES -->|Analityka| DUCKDB
    SERVICES -->|Eventy| EVENTS
    SERVICES -->|OCR| PIPELINE
    
    EVENTS -->|Append| DB
    EVENTS -->|Pub/Sub| NATS
    
    PIPELINE --> DOMAIN
    
    DOMAIN --> DB
    
    CORE -->|Kryptografia| RUST
    CORE -->|Config| INTEGRATIONS
    CORE -->|Rego| TAX
    
    SCRIPTS -->|Bootstrap| CORE
    SCRIPTS -->|Seed| DB
    
    INSTALLER -->|Dependencies| CORE
    
    DB --> SQLITE
    SERVICES -->|OLAP| DUCKDB
    SERVICES -->|Ledger| TB
    EVENTS -->|Archiving| DUCKDB
```

**Zależności między modułami:**
1. `frontend/` → `api/` → `services/` → `db/` → `SQLite`
2. `services/` → `events/` → `NATS JetStream`
3. `services/` → `pipeline/` → `domain/`
4. `core/` → `rust/`, `tax/`, `integrations/`
5. Wszystkie moduły → `core/config.py` (centralna konfiguracja)

---

## 3. Konwencje nazewnicze

### 3.1 Pliki

| Konwencja | Przykład | Reguła |
|---|---|---|
| **snake_case** | `triage_service.py` | dla plików Python |
| **PascalCase** | `TriageService` | dla klas |
| **snake_case** | `should_triage_document()` | dla funkcji i metod |
| **SCREAMING_SNAKE** | `TRIAGE_CONFIDENCE_THRESHOLD` | dla stałych modułu |
| **Prefix `_`** | `_billing_store.py` | dla wewnętrznych (nie importuj bezpośrednio) |
| **Suffix `Service`** | `AuditService` | dla głównych serwisów |
| **Suffix `Controller`** | `TriageController` | dla Litestar routes |
| **Suffix `DTO`** | `TriageItemDTO` | dla DTO (msgspec) |
| **Suffix `Model`** | `InvoiceModel`, `UserModel` | dla SQLModel |
| **Suffix `Engine`** | `TigerBeetleEngine` | dla adapterów na zewnętrzne silniki |

### 3.2 Katalogi

| Konwencja | Warianty |
|---|---|
| Wszystkie **lowercase** | `api/`, `services/`, `installers/` (bez `-`/`_`) |
| Wyjątki: `camelCase` | `taxApi/`, `ksefService/` (legacy), `nexusCrypto/` |
| Nowa konwencja | `camelCase` dopuszczalne dla złożonych subdomen |

### 3.3 Testy

| Plik | Co testuje |
|---|---|
| `tests/test_<service>.py` | testy jednostkowe serwisu |
| `tests/integration/test_<process>.py` | testy end-to-end |
| `tests/performance/<file>.py` | locust load tests |
| `tests/schemathesis/<file>.py` | fuzz testing OpenAPI |
| `tests/rego/<file>.rego` | testy reguł podatkowych |

### 3.4 Migracje

| Format | Zastosowanie |
|---|---|
| `NNN_<slug>.sql` | numerowane migracje (001, 002, 003, 004) |
| Idempotentne | każda może być uruchomiona wielokrotnie (`IF NOT EXISTS`, `INSERT OR IGNORE`) |
| Seed w 004 | role, permissions — tylko w ostatniej migracji |

### 3.5 Commity (Conventional Commits)

```
<type>(<scope>): <description>

feat(invoices): add KSeF submit endpoint
fix(api): correct JWT expiry leak
docs(architecture): add C4 sequence diagram
perf(ocr): parallelize 4 OCR engines
test(billing): add property-based tests for VAT calc
refactor(db): migrate from pandas to polars
chore(deps): bump litestar to 2.12.0
security(crypto): rotate JWT signing keys
```

Pełna instrukcja: [`CONTRIBUTING.md`](CONTRIBUTING.md#konwencje-commitów).

---

## 4. Gdzie znaleźć konkretne rzeczy

| Szukam… | Plik / Katalog |
|---|---|
| **Model domeny Invoice** | `nexus_ai/db/models.py` |
| **Money, NIP, IBAN (Value Objects)** | `nexus_ai/domain/values.py` |
| **Agregaty DDD** | `nexus_ai/domain/aggregates.py` |
| **API endpointy** | `nexus_ai/api/routes/*.py` (Litestar `@get`/`@post`) |
| **JWT auth setup** | `nexus_ai/api/security.py` |
| **RBAC role + permissions** | `nexus_ai/api/rbac.py` |
| **Konfiguracja** | `nexus_ai/config/{base,dev,prod}.toml` |
| **Migracje SQL** | `migrations/0*.sql` |
| **Pipeline OCR** | `nexus_ai/pipeline/ocr_consensus.py` |
| **Silniki OCR** | `nexus_ai/services/pdfium/`, `tests/test_tesseract_engine.py` (test jako żywy przykład) |
| **Agenci AI** | `nexus_ai/core/inference.py` + `nexus_ai/core/protocol_executor.py` + `nexus_ai/config/protocols.toml` |
| **Crypto (Rust)** | `nexus_ai/rust/src/*.rs` |
| **Decision protocols** | `nexus_ai/core/protocol_executor.py` + `nexus_ai/config/protocols.toml` |
| **Event Sourcing** | `nexus_ai/events/{domain_events,event_store,projections}.py` |
| **TigerBeetle wrapper** | `nexus_ai/services/tigerbeetle/{client,models,ledger_initializer}.py` |
| **KSeF integracja** | `nexus_ai/core/integrations/ksef/` + `nexus_ai/services/ksef_service.py` |
| **Flet UI** | `nexus_ai/frontend/{app,router,views}/` |
| **Build / Nuitka config** | `user.nuitka-package-config.yml` + `pyproject.toml [tool.nuitka]` |
| **Worker Taskiq** | `nexus_ai/luz/worker.py` + `nexus_ai/core/taskiq.py` |
| **OTA Updater** | `nexus_ai/installer/updater.py` |
| **Rego tax rules** | `nexus_ai/tax/rules.rego` |

---

## 5. Zasady modyfikacji katalogów

1. **Nie modyfikuj `nexus_ai/rust/src/` bez PR review** — zmiany wymagają rekompilacji wszystkich binarek.
2. **Nowe API → nowy plik w `api/routes/`** — nie dodawaj endpointów do istniejących kontrolerów.
3. **Nowy serwis → `services/<name>_service.py`** — klasa `XxxService` + fasada w `services.py` (jeśli globalna).
4. **Nowy model SQL → `db/models.py`** — w sekcji właściwego agregatu.
5. **Nowa migracja → `migrations/00N_<slug>.sql`** — dodaj numer sekwencyjny, **zachowaj idempotencję**.
6. **Nowa reguła podatkowa → `nexus_ai/tax/rules.rego`** — z testami w `tests/rego/`.
7. **Nowy komponent UI → `frontend/components/<name>.py`** — wiksz w `frontend/components/__init__.py`.

---

## 🔗 Zobacz również

- [Architektura](ARCHITECTURE.md) — warstwy, wzorce, ADR
- [Proces rozwoju](CONTRIBUTING.md) — konwencje nazewnicze, standardy kodu
- [Słownik pojęć](GLOSSARY.md) — terminy techniczne

---

> **Data aktualizacji:** 2026-07-04 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-04 · **Weryfikator:** NexusAI Team
