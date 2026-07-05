# 📝 Changelog

> **Żywy dokument** — każda nowa wersja dodaje wpis na górze listy.  
> Format: [Keep a Changelog](https://keepachangelog.com/) + [SemVer](https://semver.org/).

---

## [2.3.1-dev] — 2026-07-05 — „Enterprise Documentation"

### 📚 Dokumentacja (pełna przebudowa)

#### ➕ Dodane (5 nowych plików)
- **`docs/00_META.md`** — strona tytułowa: identyfikacja projektu, PWE, zespół (10 ról), licencja, compliance matrix
- **`docs/BIBLIOGRAPHY.md`** — formalna bibliografia (10 kategorii): akty prawne (UoR, KSeF, RODO), standardy IFRS, dokumentacja stacku, white papers, konferencje
- **`docs/RELATED.md`** — konkurencja rynkowa (7 systemów), materiały konferencyjne, RFC (JWT, Argon2, ChaCha20), zasoby polskie (e-Urząd Skarbowy, Biała Lista, NBP)
- **`docs/RUST_MODULE.md`** — moduł `nexus-crypto` (Rust+PyO3): struktura plików, 3 algorytmy (AEAD, Argon2id, SHA-256), Vault (mlock), benchmarki, error types
- **`docs/MODELS_MANIFEST.md`** — 13 modeli GGUF w tabelach: 5 agentów + 8 specjalistycznych, parametry RAM/czas/dokładność, kwantyzacja (Q2_K→Q8_0), procedura SHA-256 download, manifest JSON

#### 🔄 Zaktualizowane (3 pliki)
- **`docs/ARCHITECTURE.md`** — dodano trzeci (brakujący) diagram sekwencji: komunikacja między agentami przez NATS JetStream z topologią strumieni i gwarancjami
- **`docs/MODULES.md`** — dodano produkcyjny kod konsensusu OCR (Levenshtein), tabelę porównawczą 4 silników OCR (RAM/czas/dokładnoć/mocne/słabe strony), przepływ z metrykami czasowymi
- **`docs/SECURITY.md`** — dodano konkretne parametry Argon2id (memory=64MB, iterations=3, parallelism=4) z uzasadnieniem, skrypt rotacji kluczy w Pythonie, security checklist 10 punktów
- **`docs/INDEX.md`** — pełny przegląd wszystkich 25 plików dokumentacji z tabelami i rozszerzonym indeksem tagów

#### 🐛 Poprawione
- **`docs/MODULES.md`** — kod konsensusu OCR używa `difflib.SequenceMatcher` (standardowa biblioteka) zamiast `python-Levenshtein` (zależność zewnętrzna)

### ➕ Dodane (ogólne)
- `pixi run rotate-keys` — nowy task do rotacji kluczy (JWT, SQLCipher, backup)
- `pixi run docs-html` — regeneracja dokumentacji HTML
- `pixi run docs-check` — walidacja kotwic w dokumentacji

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
- [INDEX](INDEX.md) — spis treści z listą wszystkich 25 plików
- [Architektura](ARCHITECTURE.md) — lista ADR z datami decyzji
- [Proces rozwoju](CONTRIBUTING.md) — zasady wersjonowania SemVer
- [Zgodność z przepisami](COMPLIANCE.md) — zmiany prawne wpływające na kolejne wersje

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 2.3.1-dev
> **Status dokumentu:** Aktywny (dokumentacja w przebudowie) · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** Technical Lead
