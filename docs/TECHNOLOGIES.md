# NexusAI — Pełna lista technologii (v2.2)

> **Data:** 2026-06-10
> **Status:** Aktualna — wersja 2.2 (DecisionEngine, NexusCache, async close())
> **Opis:** Nowy, ultralekki stos technologiczny — maksymalna wydajność przy minimalnym zużyciu RAM.

---

## ▶️ Szybki start

```bash
# Instalacja pixi (zalecane — wszystko w jednym)
curl -fsSL https://pixi.sh/install.sh | sh
pixi install
pixi run api

# Alternatywnie: uv (szybszy od pip)
curl -LsSf https://astral.sh/uv/install.sh | sh
uv pip install -r requirements.txt
python -m api.server

# ── Mise — główny task runner ──────────────────────────────────────────────
mise run dev                    # Dev: NATS + TB + API + Worker
mise run test                   # Uruchom testy
mise run doctor                 # Diagnostyka systemu
MISE_ENV=prod mise run api      # Produkcja: API na 0.0.0.0:8000
MISE_ENV=prod mise run migrate  # Migracje w produkcji
```

---

## Spis treści

1. [Runtime i Narzędzia](#1-runtime-i-narzędzia)
2. [Kompilacja i Build](#2-kompilacja-i-build)
3. [API / Serwer ASGI](#3-api--serwer-asgi)
4. [Bazy Danych i Przechowywanie](#4-bazy-danych-i-przechowywanie)
5. [Walidacja Danych i Serializacja](#5-walidacja-danych-i-serializacja)
6. [Kolejki Zadań i Komunikacja](#6-kolejki-zadań-i-komunikacja)
7. [HTTP / Sieć](#7-http--sieć)
8. [Odporność na Błędy (Resilience)](#8-odporność-na-błędy-resilience)
9. [Kryptografia i Bezpieczeństwo](#9-kryptografia-i-bezpieczeństwo)
10. [Finanse / Waluty](#10-finanse--waluty)
11. [AI / Machine Learning](#11-ai--machine-learning)
12. [Modele AI (GGUF)](#12-modele-ai-gguf)
13. [Logowanie i Monitoring](#13-logowanie-i-monitoring)
14. [Narzędzia (Utilities)](#14-narzędzia-utilities)
15. [Testowanie](#15-testowanie)
16. [Interfejs Desktopowy](#16-interfejs-desktopowy)
17. [Infrastruktura / DevOps](#17-infrastruktura--devops)
18. [Główne Serwisy Zewnętrzne (API)](#18-główne-serwisy-zewnętrzne-api)
19. [Agenty AI (Council of LLMs + Extraction + Analytics)](#19-agenty-ai-council-of-llms--extraction--analytics)
20. [Pliki Konfiguracyjne i Build](#20-pliki-konfiguracyjne-i-build)

---

## 1. Runtime i Narzędzia

| Technologia | Wersja | Lokalizacja | Opis |
|---|---|---|---|
| **Python (free-threaded)** | ≥3.13t | `pixi.toml`, `pyproject.toml` | CPython 3.13 bez GIL — prawdziwa wielowątkowość, współdzielona pamięć, -30-40% RAM |
| **pixi** | latest | `pixi.toml` | **Menedżer środowiska "wszystko w jednym"** (Rust) — Python, PyPI, zależności systemowe, bez Dockera. Obsługuje: `[activation.env]` (zmienne środowiskowe), `pixi exec` (ad-hoc narzędzia), `pixi tree` (wizualizacja zależności), `pixi install --locked` (deterministyczne środowisko), task caching z inputs/outputs. |
| **uv (Astral)** | ≥0.5 | `pyproject.toml`, `uv.lock` | **Najszybszy menedżer pakietów PyPI (Rust)** — 10-100× szybszy od pip. `uv sync` → synchronizacja środowiska, `uv lock` → deterministyczny lockfile, `uv run` → uruchom w środowisku, `uv tool` → globalne narzędzia (zamiennik pipx), `uv python` → zarządzanie wersjami Pythona. Wbudowany w pixi, działa też samodzielnie. |
| **mise** | ≥2024.11 | `mise.toml`, `mise.local.toml`, `mise.prod.toml` | **Menedżer wersji + task runner + environment manager** (Rust). Zastępuje: pyenv, asdf, make, just, direnv, dotenv. DAG dependencies, watch mode, file tasks, hierarchia configów (`MISE_ENV={env}` → `mise.{env}.toml`). |

### pixi — szybki start
```bash
# Instalacja
curl -fsSL https://pixi.sh/install.sh | sh

# Podstawowe użycie
pixi install                     # Instaluj środowisko
pixi run python                  # Uruchom w środowisku
pixi shell                       # Aktywuj shell w środowisku

# Zaawansowane funkcje
pixi install --locked            # Deterministyczna instalacja (wymaga zgodnego lockfile'a)
pixi info                        # Diagnostyka środowiska
pixi tree                        # Drzewo zależności — debugowanie wersji
pixi exec --spec ruff ruff check # Uruchom narzędzie w ad-hoc środowisku
pixi clean                       # Wyczyść cache
pixi run --environment dev test  # Uruchom w środowisku deweloperskim
pixi shell-hook                  # Hook dla VS Code / IDE
```

### pixi shell-hook — integracja z VS Code

`pixi shell-hook` wypisuje komendy shella potrzebne do aktywacji środowiska pixi.
Przydaje się do integracji z IDE, które nie uruchamiają `pixi shell` bezpośrednio.

**VS Code — Python interpreter:**

Utwórz `.vscode/settings.json`:
```json
{
    "python.defaultInterpreterPath": ".pixi/envs/default/bin/python",
    "python.terminal.activateEnvironment": true,
    "python.terminal.activateEnvInCurrentTerminal": true,
    "files.watcherExclude": {
        ".pixi/**": true,
        "**/.pixi/**": true
    },
    "search.exclude": {
        ".pixi/**": true
    }
}
```

**VS Code — wybór środowiska przez `pixi shell-hook`:**

Jeśli VS Code nie znajduje automatycznie interpretera, możesz użyć:
```bash
# Terminal VS Code — aktywuj środowisko pixi
source <(pixi shell-hook)

# Dla fish shell:
pixi shell-hook | source

# Dla PowerShell:
pixi shell-hook | Invoke-Expression
```

Możesz też dodać skrypt aktywacyjny do `.bashrc`/`.zshrc`:
```bash
# ~/.bashrc lub ~/.zshrc — automatyczna aktywacja NexusAI
if [ -f "$HOME/NexusAI/pixi.toml" ]; then
    alias nexus="cd $HOME/NexusAI && source <(pixi shell-hook)"
fi
```

### uv — szybki start
```bash
# Synchronizacja środowiska (alternatywa dla pixi install)
uv sync

# Uruchom komendę w środowisku (auto-sync przed startem)
uv run pytest
uv run python -m nexus_ai.scripts.doctor

# Generowanie/aktualizacja lockfile
uv lock

# Eksport do requirements.txt
uv export --format requirements-txt -o requirements.txt

# Zarządzanie narzędziami (zamiennik pipx)
uv tool install ruff
uvx ruff check                 # Jednorazowe uruchomienie

# Zarządzanie Pythonem (zamiennik pyenv)
uv python list
uv python install 3.13
```

Taski uv w `mise.toml`:
```bash
mise run uv-sync          # Synchronizuj środowisko
mise run uv-lock          # Generuj uv.lock
mise run uv-export        # Eksportuj do requirements.txt
mise run uv-cache-clean   # Wyczyść cache
```

### Python 3.13t — dlaczego to rewolucja
- Wszystkie zadania równoległe (AI, OCR, DB, UI) jako zwykłe wątki w jednym procesie
- RAM zużywany raz — modele, cache, dane współdzielone między wątkami
- Spadek pamięci o 30-40% vs architektura procesowa
- Kod pozostaje prosty — standardowy `threading`, bez `multiprocessing`

---

## 2. Kompilacja i Build

| Technologia | Zastępuje | Opis |
|---|---|---|
| **hatchling** | setuptools | Nowoczesny backend budowania (PEP 621) — konfiguracja w czystym `pyproject.toml` |
| **mypyc** | — | Kompilacja typowanego Pythona do C — 2-5× przyspieszenie modeli domenowych |
| **PyO3 + Maturin** | — | Rozszerzenia w Rust dla Pythona — szybki XML, tax engine, crypto |
| **Rust** | C/C++ | Ekstremalna wydajność w krytycznych modułach (przez PyO3) |
| **mimalloc** | glibc malloc | Alokator Microsoftu — 5-15% mniej RAM, statycznie wkompilowany w Nuitkę |
| **Nuitka** | — | Kompilacja całej aplikacji do samodzielnego .exe — start w ułamku sekundy |

---

## 3. API / Serwer ASGI

| Technologia | Zastępuje | Opis |
|---|---|---|
| **Litestar** ≥2.8.0 | FastAPI | Framework ASGI nowej generacji — routing, middleware, DI, OpenAPI (wyłączone w prod) |
| **Granian** ≥1.0.0 | **Uvicorn** | **Serwer ASGI w Rust** — 25-40% mniej RAM niż Uvicorn, obsługa gniazd UNIX |
| **anyio** ≥4.4.0 | — | Lekka warstwa async I/O — preferowany backend dla Litestar i Granian; wszystkie subprocess → anyio.run_process/anyio.Process |

### Kluczowe optymalizacje
- **OpenAPI/Swagger wyłączone** w produkcji — zbędne dla desktopu, oszczędza RAM i czas startu
- **Gniazda UNIX** zamiast TCP/IP — komunikacja lokalna bez narzutu sieciowego
- Tylko niezbędny middleware (CORS, JWT, CSRF, rate limiting)
- **subprocess → anyio** — migracja 9 plików: wszystkie `subprocess.run`, `subprocess.Popen`, `subprocess.check_output` → `anyio.run_process`, `anyio.Process.__aenter__()` |

### subprocess → anyio — zakres migracji

| Plik | Wzorzec zastąpiony | Nowy wzorzec |
|---|---|---|
| `luz/build_nexus.py` | `subprocess.run(command, check=True)` | `anyio.run_process(command)` |
| `luz/main.py` | `subprocess.Popen()` (NATS/Worker/API) | `await anyio.Process().__aenter__()` |
| `installer/dependency_downloader.py` | `subprocess.Popen` + `subprocess.run` | `anyio.Process.__aenter__()` + `anyio.run_process()` |
| `installer/updater.py` | `subprocess.Popen` (fire-and-forget) | `await asyncio.create_subprocess_exec()` |
| `pipeline/ocr_consensus.py` | `subprocess.run` w `anyio.to_thread` | `await anyio.run_process()` — bez wrappera |
| `scripts/security_scan.py` | `subprocess.run` (DAST/SAST) | `await anyio.run_process()` — async funkcje |
| `scripts/performance_engineering.py` | `subprocess.run` (locust) | `await anyio.run_process()` — async funkcje |
| `scripts/doctor.py` | `subprocess.check_output` (nvidia-smi) | `await anyio.run_process()` — async callers |
| `main.py` | `import subprocess` + `subprocess.PIPE` | `asyncio.subprocess.PIPE` |

---

## 4. Bazy Danych i Przechowywanie

| Technologia | Zastępuje | Opis |
|---|---|---|
| **SQLite + SQLCipher** | — | Zaszyfrowana (AES-256) baza transakcyjna — jeden plik, zero serwera, pełne ACID |
| **SQLModel** | SQLAlchemy + Pydantic | **ORM 2 w 1** — jedna definicja dla bazy i API, zero duplikacji kodu |
| **sqlite-vec** | **LanceDB** | **Rozszerzenie wektorowe dla SQLite** — embeddingi w tej samej bazie, czysty SQL |
| **DuckDB** ≥1.0 | — | Lokalna hurtownia danych OLAP — first-match-wins SQL dla reguł podatkowych |
| **PyArrow** ≥15.0 | — | Kolumnowy format danych — most między DuckDB a Polars |
| **Polars** ≥1.0 | pandas | DataFrame w Rust — 5-10× szybszy od pandas, Lazy API, mniej RAM |
| **Alembic** ≥1.13 | — | Migracje schematu — automatyczne generowanie skryptów z SQLModel |

### Dlaczego sqlite-vec zamiast LanceDB
- Faktury, kontrahenci i embeddingi AI w **jednym pliku**
- Jedna transakcja dla danych i wektorów — atomowość gwarantowana
- Wyszukiwanie semantyczne przez czysty SQL: `SELECT * FROM invoices ORDER BY vec_distance_cosine(embedding, ?) LIMIT 5`

---

## 5. Walidacja Danych i Serializacja

| Technologia | Zastępuje | Opis |
|---|---|---|
| **msgspec** ≥0.18 | json, orjson, python-dotenv, pydantic-settings | **Ultraszybka serializacja** — 2-3× szybsza od Pydantic v2, wbudowany parser TOML |
| **Pydantic** | (tylko jako zależność SQLModel) | Używany **wyłącznie** jako fundament SQLModel — nie w API |

### Nowa architektura walidacji
- **msgspec.Struct** dla wszystkich: endpointów API, konfiguracji (TOML), wewnętrznych DTO
- **SQLModel** (oparty na Pydantic) tylko dla modeli bazy danych
- Konfiguracja z `config.toml` przez msgspec — zero dodatkowych bibliotek

---

## 6. Kolejki Zadań i Komunikacja

| Technologia | Opis |
|---|---|
| **NATS Server** ~10 MB | **Samodzielny plik binarny** (nie Docker!) — broker wiadomości uruchamiany jako podproces |
| **nats-py** ≥2.6 | Oficjalny, asynchroniczny klient NATS |
| **NATS JetStream** | Trwałe strumienie, at-least-once delivery, dead letter queue, retry z backoffem |
| **Taskiq** ≥0.11 | Nowoczesna, async-native kolejka zadań (dekoratory, type hints, harmonogram cron) |
| **taskiq-nats** ≥0.5 | Spoiwo łączące Taskiq z NATS JetStream |

### Kluczowe cechy
- Komunikacja przez **gniazdo UNIX** (nie TCP/IP) — zero narzutu sieciowego
- W spoczynku NATS zużywa **15-25 MB RAM**
- Dead Letter Queue — żadna faktura nie przepada bez śladu

---

## 7. HTTP / Sieć

| Technologia | Opis |
|---|---|
| **httpx** ≥0.27 | Nowoczesny, asynchroniczny klient HTTP (HTTP/1.1 + HTTP/2) |
| **hishel** ≥0.1 | **Inteligentny cache HTTP** — automatyczne cache'owanie odpowiedzi API z szacunkiem nagłówków Cache-Control |
| **CachedHttpClient** | Wrapper na hishel/httpx — prekonfigurowany klient z timeoutem, keepalive i `async close()` |
| **fsspec** ≥2024.3 | Jednolita abstrakcja systemów plików (lokalny, S3, SFTP, ZIP) |

### CachedHttpClient + hishel

`CachedHttpClient` (`core/cache/http_client.py`) to prekonfigurowany klient HTTP z:
- **hishel** — inteligentny cache HTTP z SQLite, respektujący Cache-Control i ETag
- **Działanie offline** — cache'owane dane jako fallback przy braku sieci
- **async close()** — czyste zamykanie połączeń przez `await client.aclose()`
- Używany przez: `WhiteListService` (Biała Lista MF), `CurrencyConverter` (NBP API)

Wszystkie serwisy korzystające z `CachedHttpClient` implementują `async close()` do poprawnego zwalniania zasobów HTTP (httpx.AsyncClient + connection pool).

---

## 8. Odporność na Błędy (Resilience)

| Technologia | Zastępuje | Opis |
|---|---|---|
| **stamina** ≥0.1 | tenacity + pybreaker | **Async-native** retry + circuit breaker w jednym — zbudowany na anyio |
| **async close()** | — | Wzorzec czystego zamykania: `HTTPClient.close()` → `CachedHttpClient.close()` → `httpx.AsyncClient.aclose()` |

### Wzorzec async close()

Każdy serwis trzymający połączenia HTTP lub DB implementuje `async def close()`:

```python
class WhiteListService:
    async def close(self) -> None:
        await self._http.close()  # → CachedHttpClient → httpx.AsyncClient.aclose()

class CurrencyConverter:
    async def close(self) -> None:
        self._conn.close()  # → duckdb.DuckDBPyConnection
```

Łańcuch zamykania: `Service.close()` → `CachedHttpClient.close()` → `httpx.AsyncClient.aclose()` zapobiega wyciekom połączeń w długo działających procesach (worker, serwer).

---

## 9. Kryptografia i Bezpieczeństwo

| Technologia | Zastępuje | Opis |
|---|---|---|
| **Nexus-Crypto** (Rust + PyO3) | **cryptography** (częściowo) | **Własny moduł** — AEAD (ChaCha20-Poly1305), Argon2id, SHA-256 (hex) |
| **cryptography** (opcjonalny fallback) | — | **Nadal używany** dla RSA (KSeF), X.509 (signature_validator), legacy AES-CBC (backup) |
| **hashlib** (stdlib, opcjonalny fallback) | — | **Nadal używany** dla streaming SHA-256, HMAC-SHA256, blake2b, MD5 (non-crypto) |
| **Litestar JWT** | pyjwt | Wbudowane w Litestar — zero dodatkowych zależności |
| **Litestar CSRF** | — | Ochrona przed atakami cross-site (wbudowana) |
| **Litestar CORS** | — | Kontrola dostępu między źródłami (wbudowana) |
| **Litestar Rate Limiting** | — | Limitowanie żądań (wbudowane) |

### Architektura krypto — 3 poziomy

| Poziom | Biblioteka | Zastosowanie | Status |
|---|---|---|---|
| **Podstawowy (primary)** | `nexus_crypto` (Rust+PyO3) | AEAD backup, hashowanie haseł (Argon2id), embeddingi SHA-256 | ✅ 100% nowego kodu |
| **Opcjonalny fallback** | `cryptography` (pip) | RSA, X.509, legacy AES-CBC (NEXUSENC1) | ⚠️ Tylko starsze formaty |
| **Opcjonalny fallback** | `hashlib` (stdlib) | Streaming SHA-256 (file digest), HMAC-SHA256 (JWT), blake2b (TigerBeetle IDs), MD5 (non-crypto dedup) | ⚠️ Tylko gdzie nexus_crypto nie wspiera streamingu/algorytmu |

### Nexus-Crypto — co oferuje
- `encrypt(key, plaintext)` / `decrypt(key, data)` — ChaCha20-Poly1305 AEAD
- `hash_password(pw)` / `verify_password(pw, hash)` — Argon2id (PHC winner)
- `sha256(data)` — SHA-256 hex string (tylko dla danych w pamięci, nie streaming)
- `derive_key(password, salt)` — Argon2id KDF

### Co NIE jest w Nexus-Crypto (i świadomie pozostaje w hashlib/cryptography)

| Algorytm | Gdzie używany | Powód |
|---|---|---|
| **Streaming SHA-256** | Weryfikacja modeli GGUF, hashowanie plików | nexus_crypto nie wspiera streamingu |
| **HMAC-SHA256** | JWT signature verification (middleware) | Wymaga obiektu digest function, nie hex stringa |
| **BLAKE2b** | Deterministic account IDs (TigerBeetle) | Niezaimplementowane w nexus_crypto |
| **MD5** | Context dedup (ActiveLearning) | Niezaimplementowane (non-cryptographic use) |
| **RSA / X.509** | KSeF encryption, signature validation | Asymmetric crypto — poza zakresem nexus_crypto |
| **AES-CBC-PKCS7** | Legacy NEXUSENC1 backup format | Tylko starsze formaty — nowe backupi używają AEAD |

---

## 10. Finanse / Waluty

| Technologia | Zastępuje | Opis |
|---|---|---|
| **Nexus-Money** (msgspec.Struct) | **py-moneyed** | **Minimalistyczna reprezentacja pieniędzy** — `amount_cents: int` + `currency: str`, zero Decimal, bezpośrednie mapowanie 1:1 z TigerBeetle |
| **TigerBeetle** | — | Rozproszony silnik księgowy w Zig — podwójny zapis na poziomie protokołu |
| **TigerBeetle Client** (Python) | — | Oficjalny, asynchroniczny klient TigerBeetle — komunikacja przez gniazdo UNIX |

### Nexus-Money — dlaczego zastępuje py-moneyed
- `msgspec.Struct` z `amount_cents: int` i `currency: str` — bezpośrednie mapowanie do TigerBeetle
- Zero konwersji, zero Decimal, zero strat precyzji
- Automatyczna serializacja przez Litestar i msgspec
- Obliczenia na `int` są fundamentalnie szybsze niż na `Decimal`

---

## 11. AI / Machine Learning

| Technologia | Zastępuje | Opis |
|---|---|---|
| **llama-cpp-python** ≥0.2 | — | LLM inference CPU/GPU — uruchamianie modeli GGUF lokalnie |
| **huggingface-hub** ≥0.23 | — | Pobieranie modeli z weryfikacją SHA-256 |
| ~~transformers~~ | — | **Usunięte** — zastąpione przez LightOnOCR-1B + llama-cpp-python |
| ~~torch~~ | — | **Usunięte** — niepotrzebne przy modelach GGUF |
| ~~sentence-transformers~~ | — | **Usunięte** — embeddingi przez sqlite-vec |
| **PaddleOCR** ≥2.8 | — | Drugi silnik OCR — deep learning, obsługa nietypowych czcionek (aa3fvcx.txt) |
| **Surya OCR** ≥0.4 | — | Trzeci silnik OCR — layout-aware (aa3fvcx.txt) |
| **PyMuPDF (fitz)** ≥1.24 | — | Konwersja PDF → obrazy dla OCR (aa3fvcx.txt) |
| **xsdata** ≥24.0 | — | Automatyczne generowanie klas Pythona z XSD (KSeF) |

---

## 12. Modele AI (GGUF)

System wykorzystuje **10 modeli AI** zgrupowanych w **6 grupach funkcyjnych**:

### Council of Agents (Rada Agentów)
| Model | Rozmiar | Agent | Funkcja |
|---|---|---|---|
| **LFM2.5 1.2B** | ~780 MB | Alpha Agent | Szybki decydent — wstępna klasyfikacja faktur |
| **Qwen3 0.6B** | ~430 MB | Beta Agent | Precyzyjny walidator — weryfikacja NIP, kwot, dat |
| **LittleLamb 0.3B (TC)** | ~250 MB | Gamma Agent | Detektor duplikatów i anomalii przez sqlite-vec |

### WorkflowPlanner (Orkiestrator przepływu)
| Model | Rozmiar | Funkcja |
|---|---|---|
| **LittleLamb 0.3B (TC)** | ~250 MB | Klasyfikator simple/complex — decyduje które agenty uruchomić (współdzielony z Gamma) |

> LittleLamb 0.3B jest współdzielony między Council Gamma a WorkflowPlanner — ten sam plik GGUF, dwa osobne zadania inference.

### Extraction Agent (nowy — zastępuje cały pipeline OCR)
| Model | Rozmiar | Funkcja |
|---|---|---|
| **LightOnOCR-1B** | ~800 MB | **Główny silnik** — VLM (Vision Language Model) ekstrahujący dane z obrazów faktur |
| **Phi-3-mini 3.8B** | ~2.2 GB | **Sędzia rezerwowy** — fallback gdy LightOnOCR-1B nie zwróci poprawnego JSON |

### Rules SWAT Team (Kaskada reguł biznesowych)
| Model | Rozmiar | Agent | Funkcja |
|---|---|---|---|
| **LFM2.5 1.2B** | ~780 MB | Level 1 | Szybka klasyfikacja COMPLIANT/FLAG (współdzielony z Alpha) |
| **Granite 4.0 1B Nano** | ~980 MB | Level 2 | Walidacja biznesowa — NIP, limity, polityka |
| **LittleLamb 0.3B (TC)** | ~250 MB | Level 3 | Ternary Classifier — COMPLIANT/FLAG/VIOLATION (współdzielony) |
| **Fin-RWKV-169M** | ~170 MB | Level 4 | Końcowa weryfikacja — LOW/MEDIUM/HIGH (współdzielony z Analytics) |

### Analytics Agent (Miniaturowy Sztab Analityczny)
| Model | Rozmiar | Funkcja |
|---|---|---|
| **Hrida-T2SQL-128k** | ~1.5 GB | Ekspert SQL — tłumaczy pytania na zapytania SQL (128k okno kontekstowe) |
| **Qwen2.5-1.5B-Instruct** | ~980 MB | Główny analityk — interpretuje wyniki SQL w języku naturalnym |
| **Fin-RWKV-169M** | ~170 MB | Detektyw finansowy — wykrywa anomalie (architektura RWKV, attention-free) |

### Decision Agent (JambaStrategist)
| Model | Rozmiar | Funkcja |
|---|---|---|
| **Jamba 3B** | ~1.8 GB | Strategiczne wnioskowanie — ostateczna decyzja AUTO_POST/SUGGEST/ESCALATE na podstawie raportów wszystkich agentów |

**Łącznie: ~10.3 GB modeli na dysku, max ~2 GB RAM w jednym momencie** (dzięki lazy loading + explicit unloading + mutual exclusion przez ModelManager)

---

## 13. Logowanie i Monitoring

| Technologia | Zastępuje | Opis |
|---|---|---|
| **Loguru** ≥0.7 | — | Zaawansowane logowanie z rotacją plików i kolorami |
| **structlog** ≥24.0 | — | **Ustrukturyzowane logowanie z kontekstem** — zdarzenia zamiast płaskiego tekstu, automatyczny kontekst (trace_id, user_id) |
| **OpenTelemetry** (API + SDK) | **prometheus_client** | **Jeden standard dla całej telemetrii** — metryki, ślady, logi; Prometheus Exporter dla /metrics endpointu |
| **DuckDB + Parquet** | — | Lokalna hurtownia telemetrii — logi jako baza danych do przeszukiwania SQL |

> **Uwaga:** Sentry SDK jest opcjonalnym dodatkiem (aa3fvcx.txt Punkt 12). Włączany przez `NEXUS_SENTRY_DSN`. Monitoring błędów + Loguru + structlog + OpenTelemetry.

### Dlaczego OpenTelemetry zamiast prometheus_client
- **Zero nowych zależności** — jeden standard dla metryk, śladów i logów
- **Lekki most Prometheus Exporter** — endpoint /metrics w istniejącym serwerze
- **Skalowalność bez zmiany kodu** — zmiana eksportera (OTLP → Prometheus) to zmiana konfiguracji

---

## 14. Narzędzia (Utilities)

| Technologia | Zastępuje | Opis |
|---|---|---|
| **psutil** ≥5.9 | — | Monitorowanie CPU, RAM, dysku |
| **pendulum** ≥3.0 | **python-dateutil, pytz, dateparser** | **Nowoczesne zarządzanie czasem** — async-safe, jawne parsowanie, strefy czasowe, intuicyjne Duration API |
| **TOML + msgspec** | **PyYAML, python-dotenv** | Konfiguracja w czystym TOML — szybsze parsowanie, bezpieczeństwo typów, zero nowych zależności |
| **NexusCache** (dyscache) | **cachetools, diskcache** | **Multi-level cache** — RAM (L1) + SQLite (L2) przez dyscache, globalny singleton `get_cache()`, `get_or_compute()`, `get_sync/set_sync` dla synchronicznych serwisów |
| **sentry-sdk** ≥2.0 | — | Opcjonalne śledzenie błędów produkcyjnych |

### NexusCache — architektura cache'owania

`NexusCache` (`core/cache/dyscache.py`) to dwupoziomowy system cache:

```
┌─────────────────────────────────────┐
│          NexusCache                 │
├────────────────┬────────────────────┤
│  L1: RAM (dict)│  L2: SQLite/dyscache│
│  fastest       │  persistent        │
│  get_sync/set  │  async get/set     │
│  _ram_cache    │  TTL-aware         │
└────────────────┴────────────────────┘
```

**Zastosowania:**

| Komponent | Klucz cache | TTL | Typ |
|---|---|---|---|
| `WhiteListService` | `whitelist:{nip}:{account}` | 3600s | L1+L2 (async) |
| `CurrencyConverter` | `fx_rate:{currency}:{date}` | 300s (default) | L1 (sync) |
| `_load_prompt_pack` | `prompt_pack:{lang}` | 3600s | L1+L2 (sync) |
| `TimedModelCache` | `_model_cache_ttl:{key}` | 600s | TTL metadata (sync) |

**Wzorzec `get_or_compute()`:**

```python
# Asynchronicznie
result = await cache.get_or_compute("my_key", compute_func, ttl=300)

# Synchronicznie (L1 RAM only)
cached = cache.get_sync(cache_key)
if cached is None:
    cached = compute()
    cache.set_sync(cache_key, cached)
```

### async close() — cleanup pattern

Każdy serwis trzymający zewnętrzne zasoby (HTTP, DB) implementuje `async def close()`:

| Serwis | Zasób | cleanup chain |
|---|---|---|
| `WhiteListService` | `CachedHttpClient` (httpx+hishel) | `await self._http.close()` |
| `CurrencyConverter` | `DuckDBPyConnection` | `self._conn.close()` |
| `CachedHttpClient` | `httpx.AsyncClient` | `await self._client.aclose()` |

### Dlaczego pendulum zamiast dateparser
- Aplikacja księgowa nie może zgadywać formatu daty — pendulum używa jawnego parsowania
- Precyzja zamiast zgadywania: `01/02/2026` to jednoznacznie styczeń lub luty, bez domysłów
- Lżejszy i szybszy od dateparser

---

## 15. Testowanie

| Technologia | Zastępuje | Opis |
|---|---|---|
| **pytest** ≥8.0 | — | Framework testowy |
| **pytest-anyio** ≥0.1 | **pytest-asyncio** | **Natywna asynchroniczność na anyio** — testy działają na tej samej warstwie co kod produkcyjny (Litestar + Granian) |
| **pytest-cov** ≥5.0 | — | Pomiar pokrycia kodu testami |
| **crosshair** ≥0.1 | **Hypothesis** (głównie) | **Property-based testing z SMT solverem** — matematyczne dowody poprawności zamiast losowego fuzzingu; szybszy i deterministyczny |
| **Hypothesis** ≥6.100 | — | Zachowany dla złożonych property-based tests (test_property_based.py) |
| **schemathesis** ≥3.30 | — | Automatyczny fuzz testing API — generuje setki losowych zapytań ze schematu OpenAPI Litestar |
| **locust** ≥2.29 | **k6** | **Pythonowe testy wydajności** — scenariusze w tym samym języku co aplikacja (httpx + msgspec) |
| **py-spy** ≥0.3 | — | **Natywny profiler w Rust** — podpina się do działającego procesu bez restartu, narzut <1% |

### Dlaczego te zmiany w testowaniu
- **pytest-anyio** eliminuje mostkowanie między asyncio a anyio — testy wiernie odzwierciedlają produkcję
- **crosshair** używa analizy statycznej zamiast losowania — błyskawiczne i deterministyczne
- **schemathesis** znajduje błędy, o których nie pomyślisz — testuje tysiące kombinacji nieprawidłowych danych
- **locust** zastępuje k6 — jeden język (Python) dla całego stacku
- **py-spy** diagnostyka w locie bez restartu

---

## 16. Interfejs Desktopowy

| Technologia | Opis |
|---|---|
| **Flet** ≥0.28 | Desktop UI (Python → Flutter) |
| **Flet Router** | Nawigacja między widokami |

---

## 17. Infrastruktura / DevOps

| Technologia | Status | Opis |
|---|---|---|
| **pixi** | **Nowy standard** | Zastępuje Dockera dla środowiska deweloperskiego |
| Docker | Opcjonalnie | Tylko dla TigerBeetle w produkcji (albo pixi + TB binary) |
| Docker Compose | Opcjonalnie | Tylko jeśli potrzebne kontenery |
| **NATS Server** (binarny ~10 MB) | **Nowy standard** | Pakowany z aplikacją przez Nuitka — nie jako osobny kontener |
| Inno Setup | Build | Windows installer dla finalnego .exe (Nuitka) |
| Prometheus | Monitoring | Alert rules dla metryk API |

---

## 18. Główne Serwisy Zewnętrzne (API)

| Technologia | Lokalizacja | Funkcja | Cache/Resilience | cleanup |
|---|---|---|---|---|
| **GUS BIR** (SOAP API) | `nexus_ai/services/gus_bir_client.py` | Dane firm (REGON, NIP, status VAT) | hishel + stamina | `async close()` |
| **Biała Lista MF** (API) | `nexus_ai/services/white_list_service.py` | Weryfikacja rachunków VAT | NexusCache + hishel | `async close()` |
| **NBP API** | `nexus_ai/services/currency_converter.py` | Kursy walut | NexusCache + DuckDB | `async close()` |
| **KSeF** (Krajowy System e-Faktur) | `nexus_ai/core/integrations/ksef/` | Wysyłka faktur elektronicznych | RSA (cryptography) | — |

**Wzorzec komunikacji z API:**
1. Sprawdź lokalny cache (NexusCache L1 RAM → L2 SQLite)
2. Jeśli miss, sprawdź hishel (cache HTTP z Cache-Control/ETag)
3. Jeśli nadal miss, wykonaj zapytanie HTTP z retry (stamina)
4. Zapisz wynik we wszystkich warstwach cache

Wszystkie serwisy API implementują `async def close()` dla poprawnego zamykania połączeń HTTP.

---

## 19. Modele AI (GGUF) — stan faktyczny

> **Uwaga:** Architektura wieloagentowa v2.0 (Council of Agents, WorkflowPlanner, Rules SWAT Team, JambaStrategist, Analytics Agent) została **uproszczona** do jednego silnika decyzyjnego **`DecisionEngine`** (`core/decision_engine.py`) opartego na SQL first-match-wins. Modele AI są nadal używane, ale **wyłącznie do zadań niefinansowych**: OCR, embeddingi, analiza wizualna.

### Modele w użyciu

| Model | Rozmiar | Zastosowanie | Pipeline |
|---|---|---|---|
| **LightOnOCR-1B** | ~800 MB | OCR faktur (VLM — Vision Language Model) — główny silnik ekstrakcji | Pipeline OCR |
| **Phi-3-mini 3.8B** | ~2.2 GB | VisionAgent — fallback OCR, analiza layoutu, wykrywanie anomalii wizualnych | Pipeline OCR (fallback) |
| **llama-cpp-python embedding** | ~300 MB | Embeddingi dla sqlite-vec — semantic search, podobieństwo faktur | FactsAggregator / SemanticGuard |

### Modele usunięte / nieużywane

| Model | Status | Powód |
|---|---|---|
| LFM2.5 1.2B | ❌ Zastąpiony przez reguły DuckDB | `DecisionEngine._match_condition()` |
| Qwen3 0.6B | ❌ Zastąpiony | Walidacja → SQL rules |
| LittleLamb 0.3B TC | ❌ Zastąpiony | Klasyfikacja → `classify_invoice()` |
| Granite 4.0 1B Nano | ❌ Zastąpiony | Walidacja biznesowa → DuckDB rules |
| Fin-RWKV-169M | ❌ Zastąpiony | Weryfikacja → SQL first-match-wins |
| Jamba 3B | ❌ Zastąpiony | Decyzja strategiczna → `DecisionEngine.decide()` |
| Hrida-T2SQL-128k | ❌ Nieużywany | Analityka → DuckDB direct queries |
| Qwen2.5-1.5B-Instruct | ❌ Nieużywany | Interpretacja → natywne SQL |

### Zarządzanie pamięcią

1. **Lazy loading** — modele ładowane dopiero przy pierwszym zadaniu
2. **Explicit unloading** — `del model` + `gc.collect()` po każdym zadaniu
3. **Mutual exclusion** — w danym momencie tylko jeden model w RAM (ModelManager z `asyncio.Semaphore(1)`)
4. **TTL** — 5 minut bezczynności = automatyczne wyładowanie

---

## 20. Pliki Konfiguracyjne i Build

| Plik | Funkcja |
|---|---|
| `mise.toml` | Bazowa konfiguracja mise — narzędzia, taski, env (commitowana) |
| `mise.prod.toml` | Nadpisania produkcyjne mise (ładowane przez `MISE_ENV=prod`) |
| `mise.local.toml` | Lokalne nadpisania mise (gitignorowany, najwyższy priorytet) |
| `pixi.toml` | Menedżer środowiska — Python, PyPI, zależności systemowe |
| `pyproject.toml` | Konfiguracja pakietu, build, narzędzia |
| `requirements.txt` | Lista zależności PyPI (dla uv/pip) |
| `config/dev.toml` | Profil deweloperski (TOML, msgspec) |
| `config/prod.toml` | Profil produkcyjny (TOML, msgspec) |
| `config/models_manifest.json` | Manifest modeli AI z SHA-256 |
| `alembic.ini` | Migracje bazy danych |
| `Dockerfile` | Obraz Docker (opcjonalnie, dla TB w produkcji) |
| `docker-compose.yml` | Orkiestracja (opcjonalnie) |
| `build_scripts/setup.iss` | Instalator Windows (Inno Setup) |

---

## 📊 Statystyki

| Kategoria | Liczba technologii | Zmiana |
|---|---|---|
| Runtime i Narzędzia | 4 | +pixi, +mise, Python 3.13t — **mise jako kręgosłup DX, nie opcjonalny dodatek** |
| Kompilacja i Build | 6 | **Nowa kategoria** — hatchling, mypyc, PyO3, Rust, mimalloc, Nuitka |
| API / Serwer ASGI | 3 | Granian zamiast Uvicorn |
| Bazy Danych | 8 | sqlite-vec zamiast LanceDB, SQLModel zamiast SQLAlchemy+Pydantic |
| Walidacja / Serializacja | 2 | msgspec jako główny, Pydantic tylko jako zależność |
| Kolejki / Komunikacja | 5 | NATS Server jako binarka (nie kontener) |
| HTTP / Sieć | 3 | **+hishel** (nowość) |
| Resilience | 1 | **stamina** zamiast tenacity+pybreaker (-1) |
| Kryptografia / Bezpieczeństwo | 3 (primary) + 2 (fallback) | **Nexus-Crypto** jako primary; **cryptography** opcjonalny dla RSA/X.509; **hashlib** opcjonalny dla streaming/HMAC/blake2b/MD5 |
| Finanse / Waluty | 3 | **Nexus-Money** zamiast py-moneyed (+TigerBeetle Client) |
| AI / ML | 2 | **-5** (usunięto: transformers, torch, sentence-transformers, onnxruntime, opencv) |
| Modele AI | 10 | **+4** (LightOnOCR-1B, Phi-3-mini, Hrida-T2SQL, Fin-RWKV, Granite 4.0 1B, Jamba 3B; usunięto wcześniej: —) |
| Logowanie / Monitoring | 4 | **+structlog, +DuckDB/Parquet**; prometheus_client → **OpenTelemetry**; Sentry usunięty |
| Narzędzia | 4 | **+NexusCache (dyscache)** ; **pendulum** zamiast python-dateutil; **TOML+msgspec** zamiast PyYAML/python-dotenv |
| Testowanie | 8 | **pytest-anyio** zamiast pytest-asyncio; +crosshair, +schemathesis, +locust, +py-spy; **locust** zamiast k6 |
| Interfejs Desktopowy | 2 | — |
| Infrastruktura / DevOps | 5 | **Lżejsze** — pixi zamiast Dockera dla dev |
| Serwisy zewnętrzne | 4 | **+async close()** cleanup pattern |
| Pliki konfiguracyjne | 10 | +pixi.toml; .env → **.toml** (msgspec); +models_manifest.json |
| **Razem** | **~85** | **Zmniejszenie z ~120 do ~85** — mniej, ale wydajniej (+NexusCache, +async close(), +CachedHttpClient; -subprocess, -częściowo cryptography/hashlib) |

---

> Dokument zaktualizowany — 2026-06-10 (wersja 2.1: migracje stdlib → własne moduły)
