# 📝 Changelog

> **Żywy dokument** — każda nowa wersja dodaje wpis na górze listy.  
> Format: [Keep a Changelog](https://keepachangelog.com/) + [SemVer](https://semver.org/).

---

## [5.2.0] — 2026-07-05 — "Progressive Autonomy + DecisionFeedView"

### 🧠 GENIALNY POMYSŁ v5.2: Progressive Autonomy Engine

#### ➕ Dodane
- **`nexus_ai/agents/user_decision_profile.py`** (~400 linii) — Progressive Autonomy Engine
  - `UserDecisionProfile` — agent obserwuje wzorce decyzyjne i przejmuje rutynowe decyzje
  - `VendorTrustProfile` — 4 poziomy zaufania (new→learning→trusted→fully_trusted), adaptacyjne progi AUTO_POST
  - `CategoryPreference` — preferencje kategorii (preferred_action, preferred_option)
  - `AmountThreshold` — 5 przedziałów kwotowych z should_auto_post
  - `DecisionPattern` — pojedynczy wzorzec (vendor_trust, category_preference, amount_threshold)
  - `WeeklyAutonomyReport` — cotygodniowy raport z message NL
  - `observe_decision()` — 4 wymiary uczenia (vendor, category, amount, autonomy)
  - `_derive_patterns()` — wyprowadzanie wzorców z profili po każdej decyzji
  - `get_adaptive_threshold()` — adaptacyjny próg per kontrahent
  - `should_auto_post()` — pełna decyzja (vip, amount, trust) → (bool, reason)
  - `generate_weekly_report()` — "Przejąłem 73% decyzji, zaoszczędziłem 45 kliknięć"
  - Decision Autonomy Score: AUTO_POST/(AUTO_POST+ASK_USER)×100%, cel 90%+ w 3 miesiące
- **Integracja w `orchestrator.py`**:
  - `_decision_profile` — `UserDecisionProfile()` w `__init__`
  - Blended threshold: `get_threshold(nip, base=profile.get_adaptive_threshold(nip))`
  - `observe_decision()`: AUTO_POST w `process_invoice`, SUGGEST/ASK_USER w `handle_user_card_response`
  - Nowe metody: `get_autonomy_score()`, `get_decision_profile_summary()`, `generate_weekly_autonomy_report()`
- **Eksport w `__init__.py`**: AmountThreshold, CategoryPreference, DecisionPattern, UserDecisionProfile, VendorTrustProfile, WeeklyAutonomyReport

### 📱 GENIALNY POMYSŁ v5.1: DecisionFeedView — Flet UI "1-Click CFO"

#### ➕ Dodane
- **`nexus_ai/frontend/views/decision_feed.py`** (~340 linii) — widok Flet Decision Feed
  - `DecisionFeedView` — `@ft.component` + `use_state()`, deklaratywny
  - Card stack: jedna karta na raz, `AnimatedSwitcher` (scale transition 350ms)
  - 3 kolory przycisków: zielony (#1B5E20) rekomendacja AI ⭐, szary (#37474F) alternatywy, czerwony (#4A1414) odrzuć
  - Trust Score bar: `ft.ProgressBar` (zielony ≥0.92, pomarańczowy ≥0.75, czerwony <0.75)
  - Urgency banner: "⚠️ PILNE" / "⚡ Wysoki priorytet"
  - Document badge: Faktura / Podatki / Środek trwały / Przelew
  - NATS subscriber: nasłuch `ui.feed.pending` → `msgspec.json.decode` → karty
  - NATS publish: kliknięcie → `ActionCardResponse` na `ui.feed.action`
  - Guard `initialized` ref: tylko 1 połączenie NATS (zapobiega duplikacji przy re-renderach)
  - Cleanup: `page.on_close` → `nats_sub.unsubscribe()` + `nats_nc.drain()`
  - Snackbar potwierdzenia z kolorem akcji
  - 3 karty demo (NATS offline fallback)
  - Stany UI: loading skeleton, empty state ("Wszystko zaksięgowane! 🎉")
- **Eksport**: `frontend/views/__init__.py` — `DecisionFeedView`

### 🃏 Action Cards — "Zasada 1-Click CFO" (v5.1)

#### ➕ Dodane
- **Struktury danych w `models.py`**:
  - `ActionCardOption` — przycisk z `hidden_payload` (pełne parametry księgowe)
  - `ActionCard` — karta: title, summary, 2-4 opcje, trust_score, urgency
  - `ActionCardFeed` — "skrzynka decyzyjna" z greeting NL
  - `ActionCardResponse` — odpowiedź użytkownika
- **`ActionCardGenerator` w `proactive_workflow.py`** (~300 linii):
  - 6 szablonów: INVOICE_STANDARD, INVOICE_HIGH_AMOUNT, INVOICE_NEW_VENDOR, TAX_ALERT, ASSET_CLASSIFICATION, PAYMENT_BATCH
  - `generate_action_card()` — tłumaczenie technicznego `AgentDecision` na prostą kartę
  - `generate_card_from_decision()` — async z opcjonalnym ulepszeniem Qwen3-Nano
  - `build_daily_feed()` — feed na dziś, sortowanie wg urgency, powitanie NL
  - Prompt Qwen3-Nano zabrania żargonu (WN, MA, PKWiU, MPP, JPK)
- **`ui.feed.pending` / `ui.feed.action`** w `topics.py` — nowe topiki NATS
- **Integracja w `orchestrator.py`**:
  - `card_generator` property, `generate_action_card()`, `build_daily_decision_feed()`, `handle_user_card_response()`
  - `handle_user_card_response`: confirm/reject → `record_user_feedback` + Cognitive Audit Trail

### ⚙️ ProactiveWorkflowScheduler — rozszerzenia (v5.0)

#### ➕ Dodane
- **`DECISION_FEED_REFRESH`** — nowy workflow (co 30 min) odświeżający feed kart decyzyjnych
  - Handler `_handle_decision_feed_refresh` w `proactive_workflow.py`
  - Cron task `proactive_decision_feed_refresh` w `tasks.py`

### 🐛 Poprawione
- **Deduplikacja workflow**: `was_executed_today` → `was_executed_recently` z `_cooldown_from_cron()`
  - Dla `*/30` → 30 min cooldown, dla `0 6` → 1440 min cooldown
  - Naprawia bug blokujący powtarzalne wykonania (DECISION_FEED_REFRESH tylko raz dziennie)
- **`loaded` variable w `_handle_resource_optimizer`**: dodano konstrukcję `loaded` przed użyciem
- **`stop()` w Orchestratorze**: wywołanie `_proactive_scheduler.stop()` przed `super().stop()`
- **Podwójne zliczanie w Progressive Autonomy**: `observe_decision` tylko dla AUTO_POST w `process_invoice`, SUGGEST/ASK_USER tylko w `handle_user_card_response`
- **Blended Bayesian + Profile thresholds**: `get_threshold(nip, base=profile_threshold)` zamiast zastępowania Bayesian
- **`_patterns` teraz wypełniane**: `_derive_patterns()` z profili vendor/category/amount
- **`msgspec` import** w `decision_feed.py` — dodany na poziomie modułu
- **NATS cleanup**: `page.on_close` → unsubscribe + drain
- **Guard inicjalizacji NATS**: `initialized` ref zapobiega duplikacji połączeń
- **Martwy error state usunięty** z DecisionFeedView

### 📚 Dokumentacja
- **`docs/AGENTS.md`**: v5.1 → v5.2, dodane sekcje 1.2c (Progressive Autonomy), 1.2d (DecisionFeedView), zaktualizowane progi adaptacyjne, stopka
- **`docs/AGENT_SYSTEM_ENTERPRISE.txt`**: v5.1 → v5.2, dodane sekcje 0b (Progressive Autonomy), 0c (DecisionFeedView), SPIS TREŚCI, PODSUMOWANIE 16→19 innowacji
- **`docs/CHANGELOG.md`**: ten wpis

### 📊 Statystyki
- **2 nowe pliki**: `user_decision_profile.py`, `decision_feed.py`
- **7 zmodyfikowanych**: `orchestrator.py`, `proactive_workflow.py`, `tasks.py`, `models.py`, `topics.py`, `agents/__init__.py`, `frontend/views/__init__.py`
- **2 zmodyfikowane docs**: `AGENTS.md`, `AGENT_SYSTEM_ENTERPRISE.txt`
- **19 kluczowych innowacji** Enterprise v5.2 (z 16 w v5.0)
- **~1200 linii nowego kodu** (user_decision_profile 400 + decision_feed 340 + ActionCardGenerator 300 + rozszerzenia)

---

## [3.0.0-dev] — 2026-07-05 — "Agentic Architecture"

### 📋 Audyt dokumentacji — kompleksowy przegląd 40 plików

#### 🔧 Naprawione
- **`docs/DATABASE.md`** — naprawiono zduplikowany footer (3 linie zamiast 2), ujednolicono separator `⸱`→`·`
- **`docs/PROJECT_STRUCTURE.md`** — naprawiono zduplikowany footer (3 linie zamiast 2), ujednolicono separator `⸱`→`·`

#### ✅ Zweryfikowane
- **Wszystkie 40 plików** — footery spójne z `3.0.0-dev`
- **Wszystkie linki wewnętrzne** — 0 uszkodzonych
- **Stare referencje 2.3.0/2.3.1** — 0 pozostałych
- **Kod źródłowy** — 4 klasy agentów w `nexus_ai/agents/` + 23+ serwisów w `nexus_ai/services/` — zgodne z dokumentacją

#### 🆕 Zaktualizowane
- `.env.example` — utworzono plik z 50+ zmiennymi i komentarzami
- `docs/nexusai_dokumentacja.html` — zregenerowana (40 rozdziałów, 789 KB)
- `docs/nexusai_dokumentacja_dark.html` — zregenerowana (40 rozdziałów, 789 KB)

---

### 🤖 System Agentów AI (v3.0 Enterprise)

### 🤖 System Agentów AI (v3.0 Enterprise)

#### ➕ Dodane
- **`docs/AGENTS.md`** — kompletna specyfikacja 5 agentów AI: Orchestrator, Extraction, Analytics, QualityValidator, FixedAssets (zgodnie z aa3fvcx.txt)
- **Decision Engine** — wielowarstwowy silnik decyzyjny: strefy decyzyjne (Dynamic Thresholds), konsensus między agentami (weighted voting), eskalacja do człowieka, Proof Chain SHA-256
- **Continuous Learning Framework** — Active Learning Loop, Bayesian Trust Score, Online OCR Learning, propagacja korekt (bezpośrednia/pośrednia/globalna/strukturalna)
- **Memory Systems** — 4 typy pamięci: Episodic (DuckDB), Semantic (sqlite-vec), Procedural (OPA/Rego), Working (NATS KV Store)
- **JEDEN poziom automatyzacji** — DecisionMode (AUTO_POST / SUGGEST / ASK_USER) zgodnie z aa3fvcx.txt
- **4-Eyes Principle** — obowiązkowa weryfikacja przez 2 niezależne modele dla kwot > 50,000 PLN
- **ADR-009** — architektura 5 wyspecjalizowanych agentów AI zamiast monolitycznego LLM (zgodnie z aa3fvcx.txt)

#### 🔄 Zaktualizowane
- **`docs/MODULES.md`** — zaktualizowana tabela 5 agentów (zgodnie z aa3fvcx.txt), odwołanie do AGENTS.md
- **`docs/ARCHITECTURE.md`** — dodano ADR-009 (architektura agentów), cross-reference do AGENTS.md
- **`docs/SECURITY.md`** — rozszerzono sekcję "Bezpieczeństwo AI" o 4-Eyes Principle, agent-level RBAC, audit log, Proof Chain
- **`docs/GLOSSARY.md`** — dodano 8 nowych terminów (Active Learning, Adaptive Thresholds, Agent AI, Bayesian Trust Score, Confidence Calibration, Continuous Learning, Decision Engine, Memory Systems, Trust Score)
- **`docs/FAQ.md`** — dodano pytania o 5 agentów, Trust Score, 4-Eyes Principle, zużycie RAM
- **`docs/INDEX.md`** — dodano AGENTS.md do nawigacji (M2b), listy plików (38), indeksu tagów

### 📊 Statystyki
- **38 plików .md** — +1 nowy (AGENTS.md)
- **5 agentów AI** — udokumentowanych z modelami, RAM, mechanizmami (zgodnie z aa3fvcx.txt)
- **9 ADR** — w tym nowy ADR-009

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

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 3.0.0-dev
> **Status dokumentu:** Aktywny (dokumentacja w przebudowie) · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** Technical Lead
