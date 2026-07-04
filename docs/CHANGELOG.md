# 📝 Changelog

> **Żywy dokument** — każda nowa wersja dodaje wpis na górze listy.  
> Format: [Keep a Changelog](https://keepachangelog.com/) + [SemVer](https://semver.org/).

---

## [2.3.0] — 2026-06-10 — "Free-Threaded Phoenix"

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

---

## Autorzy

| Wersja | Autor |
|---|---|
| 2.3.0 | NexusAI Team |
| 2.2.0 | NexusAI Team |
| 2.1.0 | NexusAI Team |
| 2.0.0 | NexusAI Team |
| 1.0.0 | NexusAI Team |

---

## 🔗 Zobacz również

- [Architektura](ARCHITECTURE.md) — lista ADR z datami decyzji
- [Proces rozwoju](CONTRIBUTING.md) — zasady wersjonowania SemVer
- [Zgodność z przepisami](COMPLIANCE.md) — zmiany prawne wpływające na kolejne wersje

---

> **Data aktualizacji:** 2026-07-04 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-04 · **Weryfikator:** NexusAI Team
