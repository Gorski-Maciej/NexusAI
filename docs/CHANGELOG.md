# 📝 Changelog

> **Żywy dokument** — każda nowa wersja dodaje wpis na górze listy.  
> Format: [Keep a Changelog](https://keepachangelog.com/) + [SemVer](https://semver.org/).

---

## [2.3.1-dev] — 2026-07-05 — „Enterprise Documentation"

### 📚 Dokumentacja (pełna przebudowa)

#### ➕ Dodane (18 nowych plików)
- **`docs/00_META.md`** — strona tytułowa: identyfikacja projektu, PWE, zespół (10 ról), licencja, compliance matrix
- **`docs/FOUNDATION.md`** — warstwa Foundation: UnitOfWork, Pipeline, BaseRepository, BaseService, AdminServiceRegistry, Result[T,E], auto_crud (~10 300 linii oszczędności)
- **`docs/SCRIPTS.md`** — skrypty CLI: bootstrap, download modeli, seed danych, backup, build Nuitka, Taskiq worker
- **`docs/INSTALLER.md`** — instalator Windows/OTA: dependency downloader (NATS, TB, OPA), model downloader (SHA-256), OTA updater, Flet UI dialogs
- **`docs/FRONTEND.md`** — Flet UI: Navigator 2.0, NexusRouter, ThemeManager, 7 widoków, Chart widgets (zero matplotlib)
- **`docs/EVENTS.md`** — Event Sourcing: 10 zdarzeń domenowych, AsyncEventStore, JetStreamBus, CQRS Projections, SchemaRegistry
- **`docs/PIPELINE.md`** — Pipeline OCR: BaseOCREngine, 4 silniki, Consensus voting, InvoiceParser
- **`docs/INFERENCE.md`** — AI Inference: InferenceService (TTL auto-unload), ModelManager, AdaptiveBatcher (NOWY)
- **`docs/MONITORING.md`** — Monitoring: ProcessMonitor (oneshot, USS/PSS), SystemMonitor, WorkerGuard (NOWY)
- **`docs/HTTP_CLIENT.md`** — HTTP Client: CachedHttpClient, HTTP/2, Exporters, NBP cache warming (NOWY)
- **`docs/CONFIG.md`** — Konfiguracja TOML: base.toml, dev/prod profile, 50+ env vars, protocols (NOWY)
- **`docs/DOMAIN.md`** — Warstwa Domenowa: 3 agregaty DDD, 14 Value Objects, Domain Events (wersja bazowa), domenowa maszyna stanów (NOWY)
- **`docs/WORKFLOWS.md`** — CI/CD: 7 workflowów GitHub Actions, analiza statyczna, performance, security, automatyzacja (NOWY)
- **`docs/PDFIUM.md`** — Engine PDF: PdfDocumentSession, RenderFlags, ProgressivePDFLoader, 14 DTO (NOWY)
- **`docs/DECISIONS.md`** — System Decyzyjny: DecisionLogger, DecisionQueue, TrustScore, Autopilot API, CorrectionStats (NOWY)
- **`docs/BUILD_CONFIG.md`** — Build Config: pixi.toml, pyproject.toml, pre-commit, Nuitka config, env vars (NOWY)
- **`docs/BIBLIOGRAPHY.md`** — formalna bibliografia (10 kategorii)
- **`docs/RELATED.md`** — konkurencja rynkowa (7 systemów), RFC
- **`docs/RUST_MODULE.md`** — moduł `nexus-crypto` (Rust+PyO3): 3 algorytmy, Vault
- **`docs/MODELS_MANIFEST.md`** — 13 modeli GGUF, 5 agentów + 8 specjalistycznych

#### 🔄 Zaktualizowane (19 plików)
- **`docs/ARCHITECTURE.md`** — dodano NFR (SLA, SLO), Capacity Planning, Disaster Recovery Plan, Error Budget
- **`docs/FRONTEND.md`** — dodano diagram nawigacji Mermaid, RouteGuard matrix, a11y, performance, UI testing
- **`docs/EVENTS.md`** — dodano Event Versioning 3-poziomowy (tolerancyjny → soft → hard), schema evolution
- **`docs/PROJECT_STRUCTURE.md`** — dodano diagram zależności modułów Mermaid, 6 brakujących serwisów
- **`docs/PIPELINE.md`** — dodano sekcję 9: taski OCR przez Taskiq (process_invoice_ocr, walidacje)
- **`docs/MODULES.md`** — dodano 31 nieudokumentowanych serwisów (3 sekcje 4.7–4.9)
- **`docs/INDEX.md`** — indeks 32 plików, nowe sekcje 6f–6i, moduł M1b, rozszerzone szybkie wyszukiwanie
- **`docs/SECURITY.md`** — dodano parametry Argon2id, skrypt rotacji kluczy, security checklist
- **`docs/INTRODUCTION.md`** — glossary → cross-reference do GLOSSARY.md (eliminacja duplikacji)
- **`docs/QUICKSTART.md`** — linki do SCRIPTS, INSTALLER, FRONTEND
- **`docs/SCRIPTS.md`** — link do TROUBLESHOOTING.md
- **`docs/00_META.md`** — wersja 2.3.1-dev
- **`docs/generate_html.py`** — 35 rozdziałów (dodano INFERENCE, MONITORING, HTTP_CLIENT, CONFIG)
- **`docs/generate_pdf.sh`** — dodano INFERENCE.md, MONITORING.md, HTTP_CLIENT.md, CONFIG.md
- **`docs/generate_html.py`** — 37 rozdziałów (dodano DOMAIN, WORKFLOWS)
- **`docs/generate_pdf.sh`** — dodano DOMAIN.md, WORKFLOWS.md
- **`docs/INDEX.md`** — 34 pliki, sekcje 6j–6k
- **`docs/generate_html.py`** — 40 rozdziałów (dodano PDFIUM, DECISIONS, BUILD_CONFIG)
- **`docs/generate_pdf.sh`** — dodano PDFIUM.md, DECISIONS.md, BUILD_CONFIG.md
- **`docs/INDEX.md`** — 37 plików, sekcje 6l–6n
- **`docs/CHANGELOG.md`** — ten wpis (18 nowych, 19 zaktualizowanych, łącznie 37 plików)

#### ✅ Code Review (6 poprawek)
- **`docs/generate_pdf.sh`** — naprawiono ścieżkę `README.md` z `../../README.md` na `../README.md`
- **`docs/INDEX.md`** — naprawiono licznik „21 sekcji" → dynamiczne sformułowanie
- **`docs/INDEX.md`** — usunięto duplikację tabeli plików
- **`docs/ARCHITECTURE.md`** — dodano cross-reference do FOUNDATION.md
- **`docs/FRONTEND.md`** — usunięto referencję do nieistniejącego `agent_status.py`
- **`docs/SCRIPTS.md`** — naprawiono ścieżki CLI na poprawne `python -m nexus_ai.scripts.*`

#### 🐛 Poprawione
- **`docs/`** — archiwizacja przestarzałych plików `.txt` (`aa3fvcx.txt`, `tfgxzd.txt`) do `docs/.archive/`
- **`docs/MODULES.md`** — kod konsensusu OCR używa `difflib.SequenceMatcher` (stdlib)
- **Audyt linków wewnętrznych** — 0 błędów na 146 linków między plikami .md
- **Audyt referencji do kodu** — wszystkie ścieżki `nexus_ai/*.py` wskazują na istniejące pliki

### 📊 Statystyki
- **37 pliki .md** (18 nowych, 19 zaktualizowanych, ~350 stron)
- **40 rozdziałów HTML**, 750+ KB (oba warianty: light + dark)
- **15+ diagramów Mermaid**, 8 ADR, 250+ linków wewnętrznych
- **70+ serwisów** w MODULES.md, **36 kontrolerów API** w API.md
- **~10 300 linii boilerplate'u** w FOUNDATION.md
- **10 zdarzeń domenowych** w EVENTS.md
- **4 silniki OCR** w PIPELINE.md, **10 nowych sekcji** (6f-6n)

### 🧱 Warstwa Foundation (nowa sekcja docs/FOUNDATION.md)
- **`Result[T, E]`** — monada Either z dyskryminowanymi podklasami (Ok/Err), zero type: ignores
- **`UnitOfWork`** — atomowe transakcje na wielu repozytoriach, sync + async context manager
- **`Pipeline[T]` + `Step[T]`** — sekwencyjne przetwarzanie z PipelineContext
- **`BaseRepository[T]`** — generyczny CRUD dla SQLModel
- **`BaseService[T, CreateDTO, UpdateDTO]`** — auto-CRUD z inferencją modelu
- **`AdminServiceRegistry`** — samo-rejestrujące serwisy admin z DuckDB + NATS
- **`auto_crud()`** — generacja kontrolerów REST z modelu SQLModel
- **`PaginatedResponse[T]`** — generyczna odpowiedź stronicowana

### ⚡ Event Sourcing (nowa sekcja docs/EVENTS.md)
- **10 zdarzeń domenowych**: InvoiceCreated → NotificationSent (msgspec Tagged Unions)
- **AsyncEventStore**: append-only SQLite + optymistyczne blokady + Parquet archiving (ZSTD level 7, Hive-style partycjonowanie)
- **JetStreamEventBus**: 7 strumieni NATS, auto-reconnect (exponential backoff z jitterem), mirror/sourcing
- **CQRS Projections**: InvoiceProjection (FTS5, triggers, indeksy warunkowe), DecisionProjection
- **DomainEventSchemaRegistry**: auto-generacja JSON Schema (draft 2020-12) przez __init_subclass__

### 🔍 Pipeline OCR (nowa sekcja docs/PIPELINE.md)
- **BaseOCREngine**: Template Method + catch_ocr_errors, ~1 500 linii oszczędności
- **4 silniki**: Tesseract (CLI, PSM/OEM), PaddleOCR (PP-OCRv4, PP-Structure, tabele/pieczęcie), docTR (KIE, reading order), EasyOCR (adaptacyjne progi)
- **OCR Consensus**: pole consensus (majority ≥2/4), kwota consensus (tolerance 0.01), confidence_conflict detection
- **InvoiceParser**: regex + bbox analysis (header/body/footer/footer pozycjonowanie), Active Learning integracja

### 📱 Frontend (nowa sekcja docs/FRONTEND.md)
- **NexusRouter**: Navigator 2.0, TemplateRoute, RouteGuard, Breadcrumb, URL=State
- **NexusApiClient**: cache (NexusCache), HTTP/2, async API
- **Chart widgets**: 5 typów (Bar/Line/Pie/Doughnut/Radar), zero matplotlib
- **ThemeManager**: Material 3, dark/light, CSS custom properties
- **7 widoków**: Dashboard, DailyBriefing, InvoiceList/Detail, PartnerHub, TaskMonitor, UITriage

### ⚙️ Skrypty CLI (nowa sekcja docs/SCRIPTS.md)
- **NexusOrchestrator**: 4-etapowy splash screen (TigerBeetle → NATS → OPA → DuckDB)
- **Skrypty**: init, download_models (doctr), seed_data, reset_db, backup
- **Worker**: TaskIQ worker z WorkerGuard
- **Build**: Nuitka build przez build_nexus.py

### 🪟 Instalator Windows (nowa sekcja docs/INSTALLER.md)
- **BinaryManager**: platform detection, SHA-256 verification, resume download (Range headers), CachingFileSystem
- **ModelDownloader**: 13 modeli GGUF, SHA-256, resume, progress callback
- **OTA Updater**: version check (GitHub API), resume download, silent install
- **Flet UI**: instalacja zależności z progress barem, Windows native toasty

### ➕ Dodane (ogólne)
- `pixi run rotate-keys` — nowy task do rotacji kluczy (JWT, SQLCipher, backup)
- `pixi run docs-html` — regeneracja dokumentacji HTML
- `pixi run docs-check` — walidacja kotwic w dokumentacji
- `docs/.gitignore` — ignoruje `.archive/`

### 🐛 Poprawione
- **Code Review v1** (6 poprawek): ścieżki, liczniki, linki, duplikacje
- **`docs/generate_pdf.sh`** — naprawiona ścieżka README.md z `../../` na `../`

---

## [2.3.0] — 2026-06-10 — „Free-Threaded Phoenix"

### 🔄 Zmienione
- **Python 3.13.2 free-threaded (3.13t)** — prawdziwa wielowątkowość, -30-40% RAM
- **SQLCipher** — powrót z Limbo (szyfrowanie AES-256)
- **4 silniki OCR** — zamiast jednego VLM (Tesseract + PaddleOCR + docTR + EasyOCR)

### ➕ Dodane
- **5 nowych agentów AI:** Orkiestrator (Granite 3.2 3B), Ekstrakcji Danych, Analityczny (Fin-RWKV), Walidator Jakości (Guardian), Środków Trwałych
- **OPA/Rego** — deterministyczny silnik reguł podatkowych
- **TaxInvariantGuard** — potrójna weryfikacja matematyczna
- **Crosshair** — property-based testing z SMT solverem (zastąpił hypothesis)
- **fsspec + hishel** — abstrakcja systemów plików + inteligentny cache HTTP
- **BillingEstimator + RiskGuard** — dynamiczny cennik i progi ryzyka
- **Flet UI** — interfejs Flutter Material Design 3

### 🗑️ Usunięte
- **Limbo** (brak szyfrowania)
- **hypothesis** (zastąpione przez crosshair)
- **pandas** (zastąpione przez polars)
- **FastAPI + Uvicorn** (zastąpione przez Litestar + Granian)

---

## [2.2.0] — 2026-02-15

### ➕ Dodane
- **Proof Chain SHA-256** — niezmienny łańcuch audytowy
- **TigerBeetle 0.16** — double-entry ledger z kryptograficznymi dowodami
- **NATS JetStream** — at-least-once delivery z DLQ
- **mypyc** — kompilacja Pythona do C (2-5× szybciej)
- **ruff** — linter w Rust (10-100× szybszy)

### 🔄 Zmienione
- **Litestar 2.8** — migracja z FastAPI
- **Granian 1.0** — migracja z Uvicorn

---

## [2.1.0] — 2025-10-01

### ➕ Dodane
- **Agent AI v1** — pierwsza wersja autonomicznego księgowania
- **KSeF integracja** — generowanie i wysyłka FA_VAT(2)
- **Biała Lista MF** — automatyczna weryfikacja
- **GUS BIR** — weryfikacja kontrahentów

---

## [2.0.0] — 2025-06-01

### ➕ Dodane
- **NexusAI Core** — pierwsza wersja platformy księgowej
- **SQLite + SQLModel** — OLTP
- **DuckDB** — OLAP analityka
- **OCR (Tesseract)** — ekstrakcja danych z faktur
- **RBAC** — role: admin, owner, accountant, worker, viewer
- **pixi** — menedżer środowiska

---

## [1.0.0] — 2025-01-15

### ➕ Dodane
- **Proof of Concept** — pierwsze testy koncepcji wirtualnego księgowego

---

## Legenda

- ➕ **Dodane** (Added) — nowa funkcja
- 🔄 **Zmienione** (Changed) — zmiana istniejącej funkcji
- 🗑️ **Usunięte** (Removed) — usunięta funkcja
- 🐛 **Naprawione** (Fixed) — poprawka błędu
- 🔒 **Bezpieczeństwo** (Security) — poprawka bezpieczeństwa
- 📚 **Dokumentacja** (Documentation) — zmiany w dokumentacji

---

## Autorzy

| Wersja | Autor |
|---|---|
| 2.3.1-dev | NexusAI Team (dokumentacja: przebudowa docs/) |
| 2.3.0 | NexusAI Team |
| 2.2.0 | NexusAI Team |
| 2.1.0 | NexusAI Team |
| 2.0.0 | NexusAI Team |
| 1.0.0 | NexusAI Team |

---

## 🔗 Zobacz również

- [00_META](00_META.md) — strona tytułowa dokumentacji z zespołem
- [INDEX](INDEX.md) — spis treści z listą wszystkich 37 plików
- [Architektura](ARCHITECTURE.md) — lista ADR z datami decyzji
- [Proces rozwoju](CONTRIBUTING.md) — zasady wersjonowania SemVer
- [Zgodność z przepisami](COMPLIANCE.md) — zmiany prawne wpływające na kolejne wersje

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 2.3.1-dev
> **Status dokumentu:** Aktywny (dokumentacja w przebudowie) · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** Technical Lead
