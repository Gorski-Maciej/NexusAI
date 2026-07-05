# 📚 Spis treści dokumentacji NexusAI

> **Żywy dokument** — daty aktualizacji w stopce każdej sekcji. Zmiany publikowane przez `git commit` i opisane w [`CHANGELOG.md`](CHANGELOG.md).

---

## 🗺️ Nawigacja po modułach

Dokumentacja podzielona jest na **6 logicznych bloków** (modułów iteracyjnych):

```
M1 Fundament        → README, 00_META, INTRODUCTION, QUICKSTART, PROJECT_STRUCTURE
M2 Architektura     → ARCHITECTURE, DATABASE, MODULES, RUST_MODULE, MODELS_MANIFEST
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
- Zawartość: Nawigacja po wszystkich 21 sekcjach + tagowy indeks A–W.

### Sekcja 3 — Wprowadzenie
- Plik: [`docs/INTRODUCTION.md`](INTRODUCTION.md)
- Zawartość: Cel, problem (PWE), propozycja wartości, użytkownicy (4 persony), scenariusze użycia.

### Sekcja 4 — Szybki start (Quick Start)
- Plik: [`docs/QUICKSTART.md`](QUICKSTART.md)
- Zawartość: 15-minutowa instrukcja pierwszego uruchomienia, komendy do skopiowania, najczęstsze problemy.

### Sekcja 5 — Architektura systemu
- Plik: [`docs/ARCHITECTURE.md`](ARCHITECTURE.md)
- Zawartość: **3 diagramy C4** (Context, Container, Component), warstwy DDD, **14 wzorców**, 3 diagramy sekwencji (faktura, Rada Agentów, **NATS JetStream między agentami** — NOWE), **8 ADR**, model domeny (agregaty + VOs), maszyna stanów faktury, stack z uzasadnieniem.

### Sekcja 6 — Struktura projektu
- Plik: [`docs/PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md)
- Zawartość: Drzewo `nexus_ai/`, konwencje nazewnicze, lokalizacja kluczowych plików.

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
- Zawartość: 5 agentów AI, 70+ serwisów (w tym LiquidityOracle, FraudGraphScanner, BudgetaryControlEngine, IdempotentBankImporter, DunningEngine), pipeline OCR z **kodem konsensusu Levenshteina**, tabela porównawcza 4 silników, silnik reguł OPA/Rego, trzy filary nieomylności finansowej, **22 komponenty rdzenia Core** (NATS utils, taskiq middleware, PluginManager, mimalloc heaps, Result monad, OPA client, SecretsManager, FSSpecFactory i inne).

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
- Zawartość: Historia wersji (1.0.0 → 2.3.0), daty, autorzy.

---

## 🔎 Szybkie wyszukiwanie

| Szukam… | Idź do… |
|---|---|
| Jak uruchomić? | [`QUICKSTART.md`](QUICKSTART.md) |
| Jak skonfigurować env vars? | [`INSTALLATION.md`](INSTALLATION.md#3-zmienne-środowiskowe) |
| Jakie mamy endpointy? | [`API.md`](API.md) |
| Jak działa księgowanie? | [`MODULES.md`](MODULES.md#7-diagram-sekwencji--księgowanie-faktury) | [`ARCHITECTURE.md`](ARCHITECTURE.md#4-diagramy-sekwencji-3-krytyczne-procesy)<br>sekwencja faktura→NATS→decyzja |
| Gdzie jest model Invoice? | `nexus_ai/db/models.py` — patrz [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md#4-gdzie-znaleźć-konkretne-rzeczy) |
| Jak rotować klucze? | [`SECURITY.md`](SECURITY.md#6-rotacja-kluczy) — skrypt `rotate_keys.py` w Pythonie |
| Jak działa weryfikacja SHA-256 modeli? | [`RUST_MODULE.md`](RUST_MODULE.md#33-sha-256) |
| Jakie modele AI są używane? | [`MODELS_MANIFEST.md`](MODELS_MANIFEST.md#2-5-głównych-agentów) |
| Jak działa konsensus OCR? | [`MODULES.md`](MODULES.md#32-mechanizm-walidacji-krzyżowej) — kod produkcyjny z algorytmem Levenshtein |
| Co nowego w 2.3.0? | [`CHANGELOG.md`](CHANGELOG.md) |
| Dokumentacja prawna? | [`BIBLIOGRAPHY.md`](BIBLIOGRAPHY.md) |
| Rynek i konkurencja? | [`RELATED.md`](RELATED.md#1-podobneporównywalne-systemy) |

---

## 🏷️ Indeks tagów / słów kluczowych (Ctrl+F friendly)

> Używaj Ctrl+F w przeglądarce. Tagi są w formacie `#TAG` z odnośnikiem do pliku i sekcji.

| Tag | Plik | Sekcja |
|---|---|---|
| `#ADR` | ARCHITECTURE.md | 5. Kluczowe decyzje architektoniczne |
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

---

## 📋 Lista wszystkich plików dokumentacji (25)

| # | Plik | Sekcja | Typ | Status |
|---|---|---|---|---|
| 1 | `docs/00_META.md` | 0. Meta | NOWY | ✅ |
| 2 | `README.md` (root) | 1. Strona główna | Istniejący | ✅ |
| 3 | `docs/INDEX.md` | 2. Spis treści | Istniejący | ✅ |
| 4 | `docs/INTRODUCTION.md` | 3. Wprowadzenie | Istniejący | ✅ |
| 5 | `docs/QUICKSTART.md` | 4. Szybki start | Istniejący | ✅ |
| 6 | `docs/ARCHITECTURE.md` | 5. Architektura | Zaktualizowany | ✅ |
| 7 | `docs/PROJECT_STRUCTURE.md` | 6. Struktura projektu | Zaktualizowany | ✅ |
| 8 | `docs/INSTALLATION.md` | 7. Instalacja | Istniejący | ✅ |
| 9 | `docs/DATABASE.md` | 8. Baza danych | Zaktualizowany | ✅ |
| 10 | `docs/API.md` | 9. API / Komunikacja | Zaktualizowany | ✅ |
| 11 | `docs/MODULES.md` | 10. Moduły / Logika | Zaktualizowany | ✅ |
| 12 | `docs/TESTING.md` | 11. Testowanie | Istniejący | ✅ |
| 13 | `docs/DEPLOYMENT.md` | 12. Wdrożenie | Istniejący | ✅ |
| 14 | `docs/TROUBLESHOOTING.md` | 13. Rozwiązywanie problemów | Istniejący | ✅ |
| 15 | `docs/SECURITY.md` | 14. Bezpieczeństwo | Zaktualizowany | ✅ |
| 16 | `docs/COMPLIANCE.md` | 15. Zgodność z przepisami | Istniejący | ✅ |
| 17 | `docs/CONTRIBUTING.md` | 16. Proces rozwoju | Istniejący | ✅ |
| 18 | `docs/USER_GUIDE.md` | 17. Podręcznik użytkownika | Istniejący | ✅ |
| 19 | `docs/GLOSSARY.md` | 18. Słownik pojęć | Istniejący | ✅ |
| 20 | `docs/FAQ.md` | 19. FAQ | Istniejący | ✅ |
| 21 | `docs/BIBLIOGRAPHY.md` | 20a. Bibliografia | NOWY | ✅ |
| 22 | `docs/RELATED.md` | 20b. Powiązane | NOWY | ✅ |
| 23 | `docs/RUST_MODULE.md` | 20c. Moduł Rust | NOWY | ✅ |
| 24 | `docs/MODELS_MANIFEST.md` | 20d. Manifest AI | NOWY | ✅ |
| 25 | `docs/CHANGELOG.md` | 20e. Changelog | Istniejący | ✅ |

**Razem: 25 plików dokumentacji (5 nowych, 5 zaktualizowanych w tej sesji).**

---

## 🔗 Zobacz również

- [00_META](00_META.md) — strona tytułowa z PWE i zespołem
- [Bibliografia](BIBLIOGRAPHY.md) — formalna bibliografia (akta prawne, stack, white papers)
- [Powiązane](RELATED.md) — konkurencja, konferencje, RFC, zasoby polskie

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** Technical Lead
