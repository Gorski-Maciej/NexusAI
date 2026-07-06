# 📚 Spis treści dokumentacji NexusAI

> **Żywy dokument** — daty aktualizacji w stopce każdej sekcji. Zmiany publikowane przez `git commit` i opisane w [`CHANGELOG.md`](CHANGELOG.md).

---

## 🗺️ Nawigacja po modułach

Dokumentacja podzielona jest na **6 logicznych bloków** (modułów iteracyjnych):

```
M1 Fundament        → README, 00_META, INTRODUCTION, QUICKSTART, PROJECT_STRUCTURE
M1b Rozszerzenia    → SCRIPTS, INSTALLER, FRONTEND, EVENTS, PIPELINE, INFERENCE, MONITORING, HTTP_CLIENT, CONFIG
M2 Architektura     → ARCHITECTURE, FOUNDATION, DOMAIN, PDFIUM, WORKFLOWS, DECISIONS, DATABASE, MODULES, BUILD_CONFIG, RUST_MODULE, MODELS_MANIFEST
M2b Agenci AI       → AGENTS (5 agentów, Decision Engine, Cognitive Audit Trail)
M3 API              → API
M4 Operacje         → INSTALLATION, TESTING, DEPLOYMENT, TROUBLESHOOTING
M5 Bezpieczeństwo   → SECURITY, COMPLIANCE
M6 Ludzie i proces  → CONTRIBUTING, USER_GUIDE, GLOSSARY, FAQ, BIBLIOGRAPHY, RELATED, CHANGELOG
```

---

## 📋 Kompletna lista sekcji

### Sekcja 0 — Strona tytułowa / Meta
- Plik: [`docs/00_META.md`](00_META.md) (NOWY)
- Zawartość: Identyfikacja projektu, misja PWE, zespół (10 ról), licencja, compliance matrix, mapa dokumentacji.

### Sekcja 1 — README (strona główna)
- Plik: [`README.md`](../README.md)
- Zawartość: Logo, misja, status (Beta), kluczowe funkcje, szybki start, wymagania systemowe, licencja.

### Sekcja 2 — Spis treści
- Plik: **ten plik** [`docs/INDEX.md`](INDEX.md)
- Zawartość: Nawigacja po wszystkich sekcjach + tagowy indeks A–W.

### Sekcja 3 — Wprowadzenie
- Plik: [`docs/INTRODUCTION.md`](INTRODUCTION.md)
- Zawartość: Cel, problem (PWE), propozycja wartości, użytkownicy (4 persony), scenariusze użycia.

### Sekcja 4 — Szybki start (Quick Start)
- Plik: [`docs/QUICKSTART.md`](QUICKSTART.md)
- Zawartość: 15-minutowa instrukcja pierwszego uruchomienia, komendy do skopiowania, najczęstsze problemy.

### Sekcja 5 — Architektura systemu
- Plik: [`docs/ARCHITECTURE.md`](ARCHITECTURE.md)
- Zawartość: **3 diagramy C4** (Context, Container, Component), warstwy DDD, **14 wzorców**, 3 diagramy sekwencji (faktura, Rada Agentów, **NATS JetStream między agentami** — NOWE), **9 ADR**, model domeny (agregaty + VOs), maszyna stanów faktury, stack z uzasadnieniem.

### Sekcja 5a — Warstwa Foundation
- Plik: [`docs/FOUNDATION.md`](FOUNDATION.md) (NOWY)
- Zawartość: Generyczne komponenty infrastrukturalne — UnitOfWork, Pipeline, BaseRepository, BaseService, AdminServiceRegistry, Result[T,E] pattern, auto_crud. Oszczędza ~10 300 linii boilerplate'u w całym systemie.

### Sekcja 6 — Struktura projektu
- Plik: [`docs/PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md)
- Zawartość: Drzewo `nexus_ai/` z 70+ serwisami, konwencje nazewnicze, lokalizacja kluczowych plików.

### Sekcja 6a — Skrypty CLI
- Plik: [`docs/SCRIPTS.md`](SCRIPTS.md) (NOWY)
- Zawartość: Narzędzia CLI: bootstrap, download modeli, seed danych, backup, reset DB, build Nuitka, Taskiq worker z WorkerGuard, NexusOrchestrator z 4-etapowym splash screen.

### Sekcja 6b — Instalator Windows / OTA
- Plik: [`docs/INSTALLER.md`](INSTALLER.md) (NOWY)
- Zawartość: Dependency downloader (NATS, TB, OPA), model downloader (SHA-256, resume), OTA updater z Flet UI dialogami, Windows native toasty.

### Sekcja 6c — Frontend (Flet UI)
- Plik: [`docs/FRONTEND.md`](FRONTEND.md) (NOWY)
- Zawartość: Navigator 2.0, TemplateRoute routing, RouteGuard, BareChartLineChart/PieChart (0 zależności od matplotlib), ThemeManager (Material 3), NexusApiClient z cache.

### Sekcja 6d — Event Sourcing / CQRS
- Plik: [`docs/EVENTS.md`](EVENTS.md) (NOWY)
- Zawartość: 10 zdarzeń domenowych, AsyncEventStore (SQLite + Parquet archiving), JetStreamEventBus (NATS), CQRS Projections (InvoiceProjection, DecisionProjection), ProjectionWorker, DomainEventSchemaRegistry, JSON Schema auto-generacja.

### Sekcja 6e — Pipeline OCR
- Plik: [`docs/PIPELINE.md`](PIPELINE.md) (NOWY)
- Zawartość: 4 silniki OCR (Tesseract, PaddleOCR, docTR, EasyOCR), BaseOCREngine Template Method, OCR Consensus (voting), InvoiceParser (regex + bbox), image preprocessing, memory management.

### Sekcja 6f — AI Inference
- Plik: [`docs/INFERENCE.md`](INFERENCE.md) (NOWY)
- Zawartość: InferenceService (lazy loading, TTL auto-unload), ModelManager (cache, cleanup_expired), AdaptiveBatcher (dynamiczne batchowanie GPU z timeoutem).

### Sekcja 6g — Monitorowanie systemu
- Plik: [`docs/MONITORING.md`](MONITORING.md) (NOWY)
- Zawartość: ProcessMonitor (oneshot, USS/PSS), SystemMonitor (CPU/RAM/disk/net), WorkerGuard, health check thresholds, integracja z OpenTelemetry.

### Sekcja 6h — HTTP Client
- Plik: [`docs/HTTP_CLIENT.md`](HTTP_CLIENT.md) (NOWY)
- Zawartość: CachedHttpClient (HTTP/2, connection pool, circuit breaker), Exporters (Optima XML, Insert EPP), FSSpecStorageProvider, NBP API cache warming.

### Sekcja 6i — Konfiguracja systemu
- Plik: [`docs/CONFIG.md`](CONFIG.md) (NOWY)
- Zawartość: Konfiguracja TOML, profile base/dev/prod, zmienne środowiskowe (50+), protocols.toml.

### Sekcja 6j — Warstwa Domenowa (DDD)
- Plik: [`docs/DOMAIN.md`](DOMAIN.md) (NOWY)
- Zawartość: Agregaty (InvoiceAggregate, ContractorAggregate, TaxDecisionAggregate), Value Objects (Money, NIP, IBAN, PESEL, VatRate, AccountCode), Domain Events (wersja bazowa), maszyna stanów domenowa.

### Sekcja 6l — Engine PDF (PDFium)
- Plik: [`docs/PDFIUM.md`](PDFIUM.md) (NOWY)
- Zawartość: PdfDocumentSession, RenderFlags (8 flag), renderowanie stron (PIL/JPEG/PNG), ProgressivePDFLoader, 14 DTO (PDFTextRange, PDFSignature, PDFAnnotation, PDFFormField, PDFACompliance), wydajność i ograniczenia.

### Sekcja 6m — System Decyzyjny
- Plik: [`docs/DECISIONS.md`](DECISIONS.md) (NOWY)
- Zawartość: DecisionLogger (3 tabele DuckDB: decisions, trust_score_cache, decisions_meta), AsyncDecisionQueue (4 priorytety, 4 statusy, auto-expire), TrustScore (4 komponenty), CorrectionStats, Autopilot API (7 endpointów), integracja z ProofChain.

### Sekcja 6n — Konfiguracja Build i Środowiska
- Plik: [`docs/BUILD_CONFIG.md`](BUILD_CONFIG.md) (NOWY)
- Zawartość: pixi.toml (30+ tasków, env vars, dependencje systemowe), pyproject.toml (maturin, mypyc, Nuitka, hatch), pre-commit hooks, user.nuitka-package-config.yml, start.sh.

### Sekcja 7 — Instalacja i konfiguracja
- Plik: [`docs/INSTALLATION.md`](INSTALLATION.md)
- Zawartość: Szczegółowa instalacja, `.env.example`, profile dev/staging/prod.

### Sekcja 8 — Baza danych
- Plik: [`docs/DATABASE.md`](DATABASE.md)
- Zawartość: Diagram ERD, opis 14 tabel, migracje SQL (001–004), backup i przywracanie.

### Sekcja 9 — API / Komunikacja
- Plik: [`docs/API.md`](API.md)
- Zawartość: Pełna specyfikacja REST (JWT, endpointy, rate limiting, kody błędów, curl).

### Sekcja 10 — Moduły / Logika biznesowa
- Plik: [`docs/MODULES.md`](MODULES.md)
- | 5 agentów AI, 13 modeli, 70+ serwisów (zgodnie z aa3fvcx.txt)

### Sekcja 10a — System Agentów AI (NOWY)
- Plik: [`docs/AGENTS.md`](AGENTS.md) (NOWY)
- Zawartość: Kompletna specyfikacja 5 agentów AI (Orchestrator, Extraction, Analytics, QualityValidator, FixedAssets), Decision Engine (strefy, konsensus, eskalacja, Proof Chain), Cognitive Audit Trail (korekty → embeddingi → auto-naprawa OPA), Continuous Learning Framework (Active Learning, Bayesian Trust Score), Memory Systems (4 typy), Protokół NATS JetStream (topologia, gwarancje), Bezpieczeństwo AI (RBAC, audit log), Monitoring (OTel, Prometheus, SLA).

### Sekcja 11 — Testowanie
- Plik: [`docs/TESTING.md`](TESTING.md)
- Zawartość: Strategia (6 poziomów), pytest, crosshair SMT, schemathesis, locust, py-spy, szablon testów.

### Sekcja 12 — Wdrożenie / Deployment
- Plik: [`docs/DEPLOYMENT.md`](DEPLOYMENT.md)
- Zawartość: Budowanie binarki (Nuitka), instalator Windows (Inno Setup), aktualizacje OTA (LiteServ), backup, CI/CD.

### Sekcja 13 — Rozwiązywanie problemów
- Plik: [`docs/TROUBLESHOOTING.md`](TROUBLESHOOTING.md)
- Zawartość: Drzewo decyzyjne diagnostyki, 9 kategorii błędów, logi i debugowanie.

### Sekcja 14 — Bezpieczeństwo
- Plik: [`docs/SECURITY.md`](SECURITY.md)
- Zawartość: Threat model, szyfrowanie (AEAD, Argon2id z konkretnymi parametrami), RBAC, JWT, OWASP Top 10, RODO, **skrypt rotacji kluczy** (NOWY), security checklist.

### Sekcja 15 — Zgodność z przepisami
- Plik: [`docs/COMPLIANCE.md`](COMPLIANCE.md)
- Zawartość: Zgodność z UoR/IFRS/GAAP, KSeF FA_VAT(2), JPK_V7, deklaracje VAT/CIT/PIT, ścieżka audytu, retencja.

### Sekcja 16 — Proces rozwoju / Contributing
- Plik: [`docs/CONTRIBUTING.md`](CONTRIBUTING.md)
- Zawartość: Standardy kodowania (ruff, mypy strict), konwencje commitów, PR checklista, jak dodać agenta/regułę/migrację.

### Sekcja 17 — Podręcznik użytkownika
- Plik: [`docs/USER_GUIDE.md`](USER_GUIDE.md)
- Zawartość: Pierwsze uruchomienie (kreator 5 kroków), role, codzienny workflow (3 minuty), Centrum Decyzji, raporty, konfiguracja, backup.

### Sekcja 18 — Słownik pojęć
- Plik: [`docs/GLOSSARY.md`](GLOSSARY.md)
- Zawartość: Terminy księgowe (UoR, KSeF, NIP, IBAN, FIFO) + techniczne (CQRS, GGUF, NATS, SQLCipher).

### Sekcja 19 — FAQ
- Plik: [`docs/FAQ.md`](FAQ.md)
- Zawartość: 30+ pytań w 6 kategoriach (ogólne, techniczne, AI, bezpieczeństwo, biznesowe, rozwój).

### Sekcja 20a — Dodatki: Bibliografia
- Plik: [`docs/BIBLIOGRAPHY.md`](BIBLIOGRAPHY.md) (NOWY)
- Zawartość: 10 kategorii: akty prawne (UoR, KSeF, RODO, Ordynacja), IFRS/MSSF, dokumentacja stacku (Python, Rust, NATS, TigerBeetle), white papers, konferencje, źródła danych, narzędzia.

### Sekcja 20b — Dodatki: Powiązane dokumenty
- Plik: [`docs/RELATED.md`](RELATED.md) (NOWY)
- Zawartość: Konkurencja rynkowa, materiały konferencyjne, specyfikacje RFC, zasoby polskie, grupy społeczności, narzędzia deweloperskie, identyfikatory standardów.

### Sekcja 20c — Moduł Rust (nexus-crypto)
- Plik: [`docs/RUST_MODULE.md`](RUST_MODULE.md) (NOWY)
- Zawartość: Struktura wewnętrzna `nexus_ai/rust/`, 3 algorytmy (AEAD, Argon2id, SHA-256), Vault (mlock), benchmarki, testy Rust (`cargo test`).

### Sekcja 20d — Manifest modeli AI
- Plik: [`docs/MODELS_MANIFEST.md`](MODELS_MANIFEST.md) (NOWY)
- Zawartość: 13 modeli GGUF, 5 agentów + 8 specjalistycznych, tabela porównawcza RAM/czas/dokładność, źródła pobierania, procedura weryfikacji SHA-256.

### Sekcja 20e — Changelog
- Plik: [`docs/CHANGELOG.md`](CHANGELOG.md)
- Zawartość: Historia wersji (1.0.0 → 3.0.0-dev), daty, autorzy.

---

## 🔎 Szybkie wyszukiwanie

| Szukam… | Idź do… |
|---|---|
| Jak uruchomić? | [`QUICKSTART.md`](QUICKSTART.md) |
| Jak działają agenci AI? | [`AGENTS.md`](AGENTS.md) |
| Jak skonfigurować env vars? | [`INSTALLATION.md`](INSTALLATION.md#3-zmienne-środowiskowe) |
| Jakie mamy endpointy? | [`API.md`](API.md) |
| Jak działa księgowanie? | [`MODULES.md`](MODULES.md#7-diagram-sekwencji--księgowanie-faktury) | [`ARCHITECTURE.md`](ARCHITECTURE.md#4-diagramy-sekwencji-3-krytyczne-procesy)<br>sekwencja faktura→NATS→decyzja |
| Gdzie jest model Invoice? | `nexus_ai/db/models.py` — patrz [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md#4-gdzie-znaleźć-konkretne-rzeczy) |
| Jak rotować klucze? | [`SECURITY.md`](SECURITY.md#6-rotacja-kluczy) — skrypt `rotate_keys.py` w Pythonie |
| Jak działa weryfikacja SHA-256 modeli? | [`RUST_MODULE.md`](RUST_MODULE.md#33-sha-256) |
| Jakie modele AI są używane? | [`MODELS_MANIFEST.md`](MODELS_MANIFEST.md#2-5-głównych-agentów) |
| Jak działa konsensus OCR? | [`MODULES.md`](MODULES.md#32-mechanizm-walidacji-krzyżowej) — kod produkcyjny z algorytmem Levenshtein |
| Jak działa pipeline OCR? | [`PIPELINE.md`](PIPELINE.md) — 4 silniki, consensus, parser |
| Jak działają zdarzenia domenowe? | [`EVENTS.md`](EVENTS.md#2-domain-events) — 10 typów, EventStore, CQRS |
| Gdzie jest definiowany EventStore? | [`EVENTS.md`](EVENTS.md#3-asynceventstore) — append-only SQLite + Parquet |
| Gdzie są udokumentowane widoki UI? | [`FRONTEND.md`](FRONTEND.md#8-widoki) — 7 widoków, nawigacja, diagram przepływu |
| Jak działa instalator Windows? | [`INSTALLER.md`](INSTALLER.md#2-dependency-downloader) — binarki, modele, OTA updater |
| Co nowego w 2.3.1-dev? | [`CHANGELOG.md`](CHANGELOG.md) |
| Dokumentacja prawna? | [`BIBLIOGRAPHY.md`](BIBLIOGRAPHY.md) |
| Rynek i konkurencja? | [`RELATED.md`](RELATED.md#1-podobneporównywalne-systemy) |

---

## 🏷️ Indeks tagów / słów kluczowych (Ctrl+F friendly)

> Używaj Ctrl+F w przeglądarce. Tagi są w formacie `#TAG` z odnośnikiem do pliku i sekcji.

| Tag | Plik | Sekcja |
|---|---|---|
| `#ADR` | ARCHITECTURE.md | 5. Kluczowe decyzje architektoniczne |
| `#ADR-009` `#agenci` | ARCHITECTURE.md, AGENTS.md | ADR-009, 1-10. |
| `#AEAD` `#ChaCha20` | SECURITY.md, RUST_MODULE.md | 2.1, 3.1 |
| `#AES-256` | SECURITY.md, DATABASE.md | 2.1 |
| `#agenci-AI` | MODULES.md, MODELS_MANIFEST.md | 1., 2. |
| `#amortyzacja` | MODULES.md | 4.1 |
| `#API` | API.md | 1.–7. |
| `#Argon2id` | SECURITY.md, RUST_MODULE.md | 2.3, 3.2 |
| `#ASK_USER` | MODULES.md | 2.2 |
| `#audyt` | COMPLIANCE.md | 5. |
| `#AUTO_POST` | MODULES.md | 2.2 |
| `#backup` | DATABASE.md, DEPLOYMENT.md | 6., 6. |
| `#Biała-Lista-MF` | COMPLIANCE.md | 7. |
| `#bibliografia` | BIBLIOGRAPHY.md | 1.–10. |
| `#build` `#Nuitka` | DEPLOYMENT.md | 2. |
| `#C4` | ARCHITECTURE.md | 1. |
| `#CI/CD` | DEPLOYMENT.md | 8. |
| `#CIT` | COMPLIANCE.md | 4.2 |
| `#CQRS` `#Event-Sourcing` | ARCHITECTURE.md | 3. |
| `#crosshair` | TESTING.md | 3.2 |
| `#DuckDB` | DATABASE.md | 1. |
| `#DDD` | ARCHITECTURE.md | 2. |
| `#FIFO` | MODULES.md | 4.1 |
| `#Flet` | ARCHITECTURE.md | ADR-008 |
| `#GGUF` | MODELS_MANIFEST.md | 2. |
| `#Granian` | INSTALLATION.md | 3. |
| `#IFRS` | COMPLIANCE.md | 1.2 |
| `#JPK` | COMPLIANCE.md | 3. |
| `#JWT` | API.md, SECURITY.md | 1., 3. |
| `#KSeF` | COMPLIANCE.md | 2. |
| `#konfiguracja` | INSTALLATION.md | 3. |
| `#konwencje` | PROJECT_STRUCTURE.md | 3. |
| `#konsensus-ocr` | MODULES.md | 3.2 |
| `#licencja` | 00_META.md | Licencja |
| `#migracje` | DATABASE.md | 4. |
| `#mimalloc` | ARCHITECTURE.md | 7. |
| `#model-domeny` | ARCHITECTURE.md | 6. |
| `#monitoring` | DEPLOYMENT.md | 9. |
| `#NATS` `#JetStream` | ARCHITECTURE.md | ADR-003, 4.3 |
| `#nexus-crypto` | RUST_MODULE.md | 1.–10. |
| `#NIP` | ARCHITECTURE.md | 6.2 |
| `#OCR` | MODULES.md | 3. |
| `#OPA` `#Rego` | MODULES.md | 5.4 |
| `#OWASP` | SECURITY.md | 8. |
| `#pixi` | INSTALLATION.md | 2. |
| `#Proof-Chain` | SECURITY.md | 5. |
| `#RBAC` | SECURITY.md | 4. |
| `#researcher-nbp` | USER_GUIDE.md | 7.3 |
| `#RODO` | SECURITY.md | 11. |
| `#Rust` `#PyO3` | RUST_MODULE.md | 1., 2. |
| `#SBOM` | DEPLOYMENT.md | 8. |
| `#silniki-OCR` | MODULES.md | 3.3 |
| `#Solution` | COMPLIANCE.md | 1.1 |
| `#SQLite` | DATABASE.md | 1. |
| `#stos-technologiczny` | ARCHITECTURE.md | 7. |
| `#testy` | TESTING.md | 1.–7. |
| `#TigerBeetle` | ARCHITECTURE.md | ADR-002 |
| `#UoR` | COMPLIANCE.md | 1.1 |
| `#VAT` | COMPLIANCE.md | 4.1 |
| `#wdrożenie` | DEPLOYMENT.md | 1.–9. |
| `#wzorce-projektowe` | ARCHITECTURE.md | 3. |

---

## 📋 Lista decyzji architektonicznych (ADR)

Wszystkie ADR znajdują się w [`ARCHITECTURE.md`](ARCHITECTURE.md#5-kluczowe-decyzje-architektoniczne-adr):

| ADR | Decyzja | Data |
|---|---|---|
| [ADR-001](ARCHITECTURE.md#adr-001-sqlite-zamiast-postgresql) | SQLite zamiast PostgreSQL | 2025-02-01 |
| [ADR-002](ARCHITECTURE.md#adr-002-tigerbeetle-do-księgi-głównej) | TigerBeetle do księgi głównej | 2025-03-15 |
| [ADR-003](ARCHITECTURE.md#adr-003-nats-zamiast-rabbitmq) | NATS zamiast RabbitMQ | 2025-01-10 |
| [ADR-004](ARCHITECTURE.md#adr-004-4-silniki-ocr-zamiast-jednego-vlm) | 4 silniki OCR zamiast jednego VLM | 2025-04-20 |
| [ADR-005](ARCHITECTURE.md#adr-005-python-313-free-threaded-bez-gil) | Python 3.13 free-threaded (bez GIL) | 2025-06-01 |
| [ADR-006](ARCHITECTURE.md#adr-006-modularny-monolit-zamiast-mikrousług) | Modularny Monolit zamiast mikrousług | 2025-02-15 |
| [ADR-007](ARCHITECTURE.md#adr-007-własny-moduł-kryptograficzny-w-rust-nexus-crypto) | Własny moduł kryptograficzny w Rust (nexus-crypto) | 2025-03-01 |
| [ADR-008](ARCHITECTURE.md#adr-008-flet-flutter-zamiast-electronreact-dla-interfejsu-desktopowego) | Flet (Flutter) zamiast Electron/React dla interfejsu desktopowego | 2025-07-15 |
| [ADR-009](ARCHITECTURE.md#adr-009-architektura-5-wyspecjalizowanych-agentów-ai-zamiast-monolitycznego-llm) | Architektura 5 agentów AI zamiast monolitycznego LLM | 2025-11-01 (akt. 2026-07-05) |

---

## 📋 Lista wszystkich plików dokumentacji (38)
|---|---|---|---|---|
| 1 | `docs/00_META.md` | 0. Meta | NOWY | ✅ |
| 2 | `README.md` (root) | 1. Strona główna | Istniejący | ✅ |
| 3 | `docs/INDEX.md` | 2. Spis treści | Istniejący | ✅ |
| 4 | `docs/INTRODUCTION.md` | 3. Wprowadzenie | Istniejący | ✅ |
| 5 | `docs/QUICKSTART.md` | 4. Szybki start | Istniejący | ✅ |
| 6 | `docs/ARCHITECTURE.md` | 5. Architektura | Zaktualizowany | ✅ |
| 7 | **`docs/FOUNDATION.md`** | **5a. Foundation** | **NOWY** | ✅ |
| 8 | `docs/PROJECT_STRUCTURE.md` | 6. Struktura projektu | Zaktualizowany | ✅ |
| 9 | `docs/INSTALLATION.md` | 7. Instalacja | Istniejący | ✅ |
| 10 | `docs/DATABASE.md` | 8. Baza danych | Zaktualizowany | ✅ |
| 11 | `docs/API.md` | 9. API / Komunikacja | Zaktualizowany | ✅ |
| 12 | `docs/MODULES.md` | 10. Moduły / Logika | Zaktualizowany | ✅ |
| 13 | `docs/TESTING.md` | 11. Testowanie | Istniejący | ✅ |
| 14 | `docs/DEPLOYMENT.md` | 12. Wdrożenie | Istniejący | ✅ |
| 15 | `docs/TROUBLESHOOTING.md` | 13. Rozwiązywanie problemów | Istniejący | ✅ |
| 16 | `docs/SECURITY.md` | 14. Bezpieczeństwo | Zaktualizowany | ✅ |
| 17 | `docs/COMPLIANCE.md` | 15. Zgodność z przepisami | Istniejący | ✅ |
| 18 | `docs/CONTRIBUTING.md` | 16. Proces rozwoju | Istniejący | ✅ |
| 19 | `docs/USER_GUIDE.md` | 17. Podręcznik użytkownika | Istniejący | ✅ |
| 20 | `docs/GLOSSARY.md` | 18. Słownik pojęć | Istniejący | ✅ |
| 21 | `docs/FAQ.md` | 19. FAQ | Istniejący | ✅ |
| 22 | `docs/BIBLIOGRAPHY.md` | 20a. Bibliografia | NOWY | ✅ |
| 23 | `docs/RELATED.md` | 20b. Powiązane | NOWY | ✅ |
| 24 | `docs/RUST_MODULE.md` | 20c. Moduł Rust | NOWY | ✅ |
| 25 | `docs/MODELS_MANIFEST.md` | 20d. Manifest AI | NOWY | ✅ |
| 26 | `docs/CHANGELOG.md` | 20e. Changelog | Istniejący | ✅ |
| 27 | **`docs/EVENTS.md`** | **6d. Event Sourcing** | **NOWY** | ✅ |
| 28 | **`docs/PIPELINE.md`** | **6e. Pipeline OCR** | **NOWY** | ✅ |
| 29 | **`docs/INFERENCE.md`** | **6f. AI Inference** | **NOWY** | ✅ |
| 30 | **`docs/MONITORING.md`** | **6g. Monitoring** | **NOWY** | ✅ |
| 31 | **`docs/HTTP_CLIENT.md`** | **6h. HTTP Client** | **NOWY** | ✅ |
| 32 | **`docs/CONFIG.md`** | **6i. Konfiguracja** | **NOWY** | ✅ |
| 33 | **`docs/DOMAIN.md`** | **6j. Warstwa Domenowa** | **NOWY** | ✅ |
| 34 | **`docs/WORKFLOWS.md`** | **6k. CI/CD Workflows** | **NOWY** | ✅ |
| 35 | **`docs/PDFIUM.md`** | **6l. Engine PDF** | **NOWY** | ✅ |
| 36 | **`docs/DECISIONS.md`** | **6m. System Decyzyjny** | **NOWY** | ✅ |
| 37 | **`docs/BUILD_CONFIG.md`** | **6n. Build Config** | **NOWY** | ✅ |

| 38 | **`docs/AGENTS.md`** | **10a. Agenci AI** | **NOWY — v3.0** | ✅ |
| 39 | **`docs/GENIALNY_POMYSL_v6_SILENT_PARTNER.md`** | **10b. Silent Partner v6.0** | **NOWY — v6.0** | ✅ |

**Razem: 39 plików dokumentacji.**

---

## 🔥 Indeks nowych sekcji

| Sekcja | Plik | Opis |
|---|---|---|
| **🆕 10a. Agenci AI** | **[`AGENTS.md`](AGENTS.md)** | **5 agentów, 13 modeli, Cognitive Audit Trail** |
| 5a. Foundation | [`FOUNDATION.md`](FOUNDATION.md) | UnitOfWork, Pipeline, BaseService, Result[T,E] |
| 6a. Skrypty CLI | [`SCRIPTS.md`](SCRIPTS.md) | Bootstrap, download modeli, seed danych, backup |
| 6b. Instalator Windows | [`INSTALLER.md`](INSTALLER.md) | Dependency downloader, OTA updater, modele AI |
| 6c. Frontend | [`FRONTEND.md`](FRONTEND.md) | Flet UI, NexusRouter, ThemeManager, Chart widgets |
| 6d. Event Sourcing | [`EVENTS.md`](EVENTS.md) | DomainEvents, EventStore, JetStream, CQRS |
| 6e. Pipeline OCR | [`PIPELINE.md`](PIPELINE.md) | 4 silniki OCR, Consensus, InvoiceParser |
| 6f. AI Inference | [`INFERENCE.md`](INFERENCE.md) | InferenceService, ModelManager, AdaptiveBatcher |
| 6g. Monitoring | [`MONITORING.md`](MONITORING.md) | ProcessMonitor, SystemMonitor, health checks |
| 6h. HTTP Client | [`HTTP_CLIENT.md`](HTTP_CLIENT.md) | CachedHttpClient, Exporters, NBP cache |
| 6i. Konfiguracja | [`CONFIG.md`](CONFIG.md) | TOML profile, env vars, protocols |
| 6j. Warstwa Domenowa | [`DOMAIN.md`](DOMAIN.md) | Agregaty DDD, Value Objects, domena |
| 6k. CI/CD Workflows | [`WORKFLOWS.md`](WORKFLOWS.md) | GitHub Actions, CI/CD pipelines |
| 6l. Engine PDF | [`PDFIUM.md`](PDFIUM.md) | PDFium, renderowanie, ProgressivePDFLoader |
| 6m. System Decyzyjny | [`DECISIONS.md`](DECISIONS.md) | DecisionLogger, DecisionQueue, TrustScore |
| 6n. Build Config | [`BUILD_CONFIG.md`](BUILD_CONFIG.md) | pixi.toml, pyproject.toml, pre-commit |
| **🆕 10a. Agenci AI** | **[`AGENTS.md`](AGENTS.md)** | **5 agentów, 13 modeli, Cognitive Audit Trail** |

---

## 🔗 Zobacz również

- [00_META](00_META.md) — strona tytułowa z PWE i zespołem
- [Bibliografia](BIBLIOGRAPHY.md) — formalna bibliografia (akta prawne, stack, white papers)
- [Powiązane](RELATED.md) — konkurencja, konferencje, RFC, zasoby polskie

---

> **Data aktualizacji:** 2026-07-06 · **Autor:** NexusAI Team · **Wersja:** 6.0.0-draft — "Silent Partner"
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-06 · **Weryfikator:** Technical Lead
