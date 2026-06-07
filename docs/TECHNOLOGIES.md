# NexusAI — Pełna lista technologii (v2.0)

> **Data:** 2026-06-07
> **Status:** Przebudowa zgodnie z `aa3fvcx.txt` — wersja finalna
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
| **pixi** | latest | `pixi.toml` | **Menedżer środowiska "wszystko w jednym"** (Rust) — Python, PyPI, zależności systemowe, bez Dockera |
| **uv (Astral)** | ≥0.5 | `pyproject.toml` | Najszybszy menedżer pakietów PyPI (Rust) — wbudowany w pixi |
| **mise** | (opcjonalnie) | — | Globalny przełącznik wersji Pythona dla developera |

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
| **anyio** ≥4.4.0 | — | Lekka warstwa async I/O — preferowany backend dla Litestar i Granian |

### Kluczowe optymalizacje
- **OpenAPI/Swagger wyłączone** w produkcji — zbędne dla desktopu, oszczędza RAM i czas startu
- **Gniazda UNIX** zamiast TCP/IP — komunikacja lokalna bez narzutu sieciowego
- Tylko niezbędny middleware (CORS, JWT, CSRF, rate limiting)

---

## 4. Bazy Danych i Przechowywanie

| Technologia | Zastępuje | Opis |
|---|---|---|
| **SQLite + SQLCipher** | — | Zaszyfrowana (AES-256) baza transakcyjna — jeden plik, zero serwera, pełne ACID |
| **SQLModel** | SQLAlchemy + Pydantic | **ORM 2 w 1** — jedna definicja dla bazy i API, zero duplikacji kodu |
| **aiosqlite** ≥0.20 | — | Cienka, asynchroniczna warstwa dla SQLite |
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
| **fsspec** ≥2024.3 | Jednolita abstrakcja systemów plików (lokalny, S3, SFTP, ZIP) |

### hishel — nowość w stacku
- Automatyczne przyspieszenie bez kodowania — rozumie nagłówki HTTP
- Działanie **offline** — cache'owane dane jako fallback przy braku sieci
- Przechowywanie w SQLite (już masz!) — zero dodatkowej infrastruktury

---

## 8. Odporność na Błędy (Resilience)

| Technologia | Zastępuje | Opis |
|---|---|---|
| **stamina** ≥0.1 | tenacity + pybreaker | **Async-native** retry + circuit breaker w jednym — zbudowany na anyio |

### Dlaczego stamina
- Prawdziwie asynchroniczny — nie blokuje pętli zdarzeń
- Wbudowany Circuit Breaker — po serii błędów odcina dostęp na określony czas
- Wykładnicze opóźnienia z jitterem
- Jedna lekka biblioteka (kilkadziesiąt KB) zamiast dwóch ciężkich

---

## 9. Kryptografia i Bezpieczeństwo

| Technologia | Zastępuje | Opis |
|---|---|---|
| **Nexus-Crypto** (Rust + PyO3) | **cryptography** (całość) | **Własny moduł** — tylko 3 funkcje: AEAD (AES-256-GCM), Argon2id, SHA-256 |
| **Litestar JWT** | pyjwt | Wbudowane w Litestar — zero dodatkowych zależności |
| **Litestar CSRF** | — | Ochrona przed atakami cross-site (wbudowana) |
| **Litestar CORS** | — | Kontrola dostępu między źródłami (wbudowana) |
| **Litestar Rate Limiting** | — | Limitowanie żądań (wbudowane) |

### Nexus-Crypto — dlaczego własny moduł
- Zaledwie kilkadziesiąt KB vs megabajty biblioteki `cryptography`
- Minimalna powierzchnia ataku — tylko to, co niezbędne
- Natywna prędkość Rusta (RustCrypto + ring)
- Nowoczesne algorytmy: AEAD (AES-256-GCM/ChaCha20-Poly1305), Argon2id (zamiast PBKDF2)

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
| ~~surya-ocr~~ | — | **Usunięte** — zastąpione przez LightOnOCR-1B |
| ~~paddleocr~~ | — | **Usunięte** — zastąpione przez LightOnOCR-1B |
| ~~onnxruntime~~ | — | **Usunięte** — niepotrzebne |
| ~~opencv-python~~ | — | **Usunięte** — LightOnOCR-1B robi wszystko |
| ~~PyMuPDF~~ | — | **Usunięte** — LightOnOCR-1B rozumie obrazy bezpośrednio |

---

## 12. Modele AI (GGUF)

System wykorzystuje **8 modeli AI** zgrupowanych w **3 agentach**:

### Council of Agents (Rada Agentów)
| Model | Rozmiar | Agent | Funkcja |
|---|---|---|---|
| **LFM2.5 1.2B** | ~780 MB | Alpha Agent | Szybki decydent — wstępna klasyfikacja faktur |
| **Qwen3 0.6B** | ~430 MB | Beta Agent | Precyzyjny walidator — weryfikacja NIP, kwot, dat |
| **LittleLamb 0.3B (TC)** | ~250 MB | Gamma Agent | Detektor duplikatów i anomalii przez sqlite-vec |

### Extraction Agent (nowy — zastępuje cały pipeline OCR)
| Model | Rozmiar | Funkcja |
|---|---|---|
| **LightOnOCR-1B** | ~800 MB | **Główny silnik** — VLM (Vision Language Model) ekstrahujący dane z obrazów faktur |
| **Phi-3-mini 3.8B** | ~2.2 GB | **Sędzia rezerwowy** — fallback gdy LightOnOCR-1B nie zwróci poprawnego JSON |

### Analytics Agent (Miniaturowy Sztab Analityczny)
| Model | Rozmiar | Funkcja |
|---|---|---|
| **Hrida-T2SQL-128k** | ~1.5 GB | Ekspert SQL — tłumaczy pytania na zapytania SQL (128k okno kontekstowe) |
| **Qwen2.5-1.5B-Instruct** | ~980 MB | Główny analityk — interpretuje wyniki SQL w języku naturalnym |
| **Fin-RWKV-169M** | ~170 MB | Detektyw finansowy — wykrywa anomalie (architektura RWKV, attention-free) |

**Łącznie: ~6.9 GB modeli, max ~2 GB RAM w jednym momencie** (dzięki lazy loading + explicit unloading)

---

## 13. Logowanie i Monitoring

| Technologia | Zastępuje | Opis |
|---|---|---|
| **Loguru** ≥0.7 | — | Zaawansowane logowanie z rotacją plików i kolorami |
| **structlog** ≥24.0 | — | **Ustrukturyzowane logowanie z kontekstem** — zdarzenia zamiast płaskiego tekstu, automatyczny kontekst (trace_id, user_id) |
| **OpenTelemetry** (API + SDK) | **prometheus_client** | **Jeden standard dla całej telemetrii** — metryki, ślady, logi; Prometheus Exporter dla /metrics endpointu |
| **Sentry SDK** (opcjonalnie) | — | Specjalista od błędów produkcyjnych — stack trace + zmienne lokalne + breadcrumbs |
| **DuckDB + Parquet** | — | Lokalna hurtownia telemetrii — logi jako baza danych do przeszukiwania SQL |

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

| Technologia | Lokalizacja | Funkcja |
|---|---|---|
| **GUS BIR** (SOAP API) | `Code/services/gus_bir_client.py` | Dane firm (REGON, NIP, status VAT) |
| **Biała Lista MF** (API) | `Code/services/white_list_service.py` | Weryfikacja rachunków VAT |
| **NBP API** | `Code/services/currency_converter.py` | Kursy walut |
| **KSeF** (Krajowy System e-Faktur) | `Code/core/integrations/ksef/` | Wysyłka faktur elektronicznych |

Komunikacja z zewnętrznymi API zabezpieczona przez **stamina** (retry + circuit breaker) + **hishel** (cache).

---

## 19. Agenty AI (Council of LLMs + Extraction + Analytics)

### Council of Agents (Rada)
| Agent | Model | Funkcja |
|---|---|---|
| **Alpha Agent** | LFM2.5 1.2B | Klasyfikacja faktur — wstępna decyzja |
| **Beta Agent** | Qwen3 0.6B | Walidacja wtórna — potwierdza/odrzuca decyzję Alpha |
| **Gamma Agent** | LittleLamb 0.3B | Tiebreaker + detekcja duplikatów przez sqlite-vec |

### Extraction Agent
| Komponent | Model | Funkcja |
|---|---|---|
| **Główny silnik** | LightOnOCR-1B | Ekstrakcja danych z obrazów faktur (VLM — Vision Language Model) |
| **Fallback** | Phi-3-mini 3.8B | Uruchamiany gdy LightOnOCR-1B zwróci niepoprawny JSON |

### Analytics Agent
| Komponent | Model | Funkcja |
|---|---|---|
| **Hrida-T2SQL-128k** | Text-to-SQL | Tłumaczy pytania na zapytania SQL (128k okno kontekstowe) |
| **Qwen2.5-1.5B-Instruct** | Analityk | Interpretuje wyniki SQL w języku naturalnym |
| **Fin-RWKV-169M** | Detektyw | Wykrywa anomalie finansowe (attention-free, ekstremalnie szybki) |

### Zarządzanie pamięcią (wspólne dla wszystkich agentów)
1. **Lazy loading** — modele ładowane dopiero przy pierwszym zadaniu
2. **Explicit unloading** — `del model` + `gc.collect()` po każdym zadaniu
3. **Mutual exclusion** — w danym momencie tylko jeden model w RAM
4. **TTL** — 5 minut bezczynności = automatyczne wyładowanie

---

## 20. Pliki Konfiguracyjne i Build

| Plik | Funkcja |
|---|---|
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
| Runtime i Narzędzia | 4 | +pixi, +mise, Python 3.13t |
| Kompilacja i Build | 6 | **Nowa kategoria** — hatchling, mypyc, PyO3, Rust, mimalloc, Nuitka |
| API / Serwer ASGI | 3 | Granian zamiast Uvicorn |
| Bazy Danych | 8 | sqlite-vec zamiast LanceDB, SQLModel zamiast SQLAlchemy+Pydantic |
| Walidacja / Serializacja | 2 | msgspec jako główny, Pydantic tylko jako zależność |
| Kolejki / Komunikacja | 5 | NATS Server jako binarka (nie kontener) |
| HTTP / Sieć | 3 | **+hishel** (nowość) |
| Resilience | 1 | **stamina** zamiast tenacity+pybreaker (-1) |
| Kryptografia / Bezpieczeństwo | 5 | **Nexus-Crypto** zamiast cryptography (-1) |
| Finanse / Waluty | 3 | **Nexus-Money** zamiast py-moneyed (+TigerBeetle Client) |
| AI / ML | 2 | **-5** (usunięto: transformers, torch, sentence-transformers, onnxruntime, opencv) |
| Modele AI | 8 | **+2** (LightOnOCR-1B, Phi-3-mini, Hrida-T2SQL, Fin-RWKV; usunięto: Granite, Jamba) |
| Logowanie / Monitoring | 5 | **+structlog, +Sentry, +DuckDB/Parquet**; prometheus_client → **OpenTelemetry** |
| Narzędzia | 3 | **pendulum** zamiast python-dateutil; **TOML+msgspec** zamiast PyYAML/python-dotenv |
| Testowanie | 8 | **pytest-anyio** zamiast pytest-asyncio; +crosshair, +schemathesis, +locust, +py-spy; **locust** zamiast k6 |
| Interfejs Desktopowy | 2 | — |
| Infrastruktura / DevOps | 5 | **Lżejsze** — pixi zamiast Dockera dla dev |
| Serwisy zewnętrzne | 4 | — |
| Agenty AI | 3 | **Przebudowane** — nowe modele i architektura |
| Pliki konfiguracyjne | 10 | +pixi.toml; .env → **.toml** (msgspec); +models_manifest.json |
| **Razem** | **~82** | **Zmniejszenie z ~120 do ~82** — mniej, ale wydajniej |

---

> Dokument zaktualizowany — 2026-06-05 (przebudowa v2.0 wg `aa3fvcx.txt`)
