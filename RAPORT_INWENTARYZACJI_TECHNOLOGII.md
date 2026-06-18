# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI — PEŁNA INWENTARYZACJA TECHNOLOGICZNA
# ═══════════════════════════════════════════════════════════════════════════════
# Data: 2026-06-18
# Źródła: pyproject.toml, pixi.toml, mise.toml, Cargo.toml, uv.lock,
#         352 pliki .py w nexus_ai/, 19 plików .rs w nexus_ai/rust/src/
# Ogółem: ~6,978 linii Rust + tysiące linii Python
# ═══════════════════════════════════════════════════════════════════════════════


# ═══════════════════════════════════════════════════════════════════════════════
# KROK 1: EKSTRAKCJA WSZYSTKICH TECHNOLOGII — PLIK PO PLIKU
# ═══════════════════════════════════════════════════════════════════════════════

## ── 1.1 KONFIGURACJA PROJEKTU ───────────────────────────────────────────────

### [PLIK: pyproject.toml]
# Build system: hatchling>=1.21 + hatch-vcs>=0.4 + maturin>=1.5
# Python: >=3.13
# Zależności bezpośrednie (runtime):
#   litestar>=2.8.0          [AKTYWNA] API framework
#   granian[dotenv,pname,reload,uvloop]>=1.0.0  [AKTYWNA] ASGI server
#   sqlmodel>=0.0.16         [AKTYWNA] ORM (SQLAlchemy + Pydantic)
#   sqlite-vec>=0.1.0        [AKTYWNA] Vector search dla SQLite
#   alembic>=1.13.0          [AKTYWNA] Migracje DB
#   msgspec>=0.18.0          [AKTYWNA] Serializacja (zastępuje json/orjson)
#   anyio>=4.4.0             [AKTYWNA] Async runtime
#   taskiq>=0.11.0           [AKTYWNA] Task queue
#   taskiq-nats>=0.5.0       [AKTYWNA] NATS broker dla Taskiq
#   nats-py>=2.6.0           [AKTYWNA] NATS client
#   httpx>=0.27.0            [AKTYWNA] HTTP client
#   hishel>=0.1.0            [AKTYWNA] HTTP cache
#   fsspec>=2024.3.0         [AKTYWNA] Filesystem abstraction
#   stamina>=0.1.0           [AKTYWNA] Retry + circuit breaker
#   nexus-crypto>=0.1.0      [AKTYWNA] Własny moduł kryptografii Rust+PyO3
#   litestar[jwt]>=2.8.0     [AKTYWNA] JWT auth
#   tigerbeetle>=0.16.0      [AKTYWNA] Double-entry accounting engine
#   lxml>=5.1.0              [AKTYWNA] XML parser
#   xsdata>=24.0.0           [AKTYWNA] XSD → Python code generation
#   pillow>=10.0.0           [AKTYWNA] Image processing
#   pypdfium2>=4.0.0         [AKTYWNA] PDF → image (zastępuje PyMuPDF)
#   paddlepaddle>=3.0.0      [AKTYWNA] Deep learning OCR engine
#   paddleocr>=2.8.0         [AKTYWNA] OCR
#   python-doctr>=0.9.0      [AKTYWNA] OCR (DBNet + PARSeq)
#   easyocr>=1.7.0           [AKTYWNA] OCR (CNN + LSTM)
#   duckdb>=1.0.0            [AKTYWNA] OLAP (zastępuje pandas)
#   pyarrow>=15.0.0          [AKTYWNA] Apache Arrow interop
#   polars>=1.0.0            [AKTYWNA] DataFrame (natywny Rust)
#   llama-cpp-python>=0.2.0  [AKTYWNA] LLM inference (GGUF)
#   huggingface-hub>=0.23.0  [AKTYWNA] Model hub
#   loguru>=0.7.0            [AKTYWNA] Logging
#   structlog>=24.0.0        [AKTYWNA] Structured logging
#   opentelemetry-api>=1.25.0  [AKTYWNA] OpenTelemetry API
#   opentelemetry-sdk>=1.25.0  [AKTYWNA] OpenTelemetry SDK
#   opentelemetry-exporter-prometheus>=0.46b0  [AKTYWNA] Prometheus exporter
#   psutil>=5.9.0            [AKTYWNA] System metrics
#   pendulum>=3.0.0          [AKTYWNA] DateTime (zastępuje pytz)
#   numpy>=2.0.0             [AKTYWNA] Numerical computing
#
# Optional (dev):
#   pytest, pytest-cov, crosshair, hypothesis, ruff, mypy,
#   pre-commit, schemathesis, locust, py-spy, pytest-benchmark,
#   pytest-xdist, pytest-timeout, pytest-sugar, pytest-watch, sentry-sdk
# Optional (ui):
#   flet>=0.28.0
#
# Build deps:
#   maturin>=1.5, mypyc>=1.8.0, nuitka>=1.8

### [PLIK: pixi.toml]
# System dependencies (conda-forge):
#   python 3.13.*_cp313t     [AKTYWNA] Free-threaded Python (bez GIL)
#   tesseract>=5.3.0         [AKTYWNA] OCR engine
#   leptonica>=1.84.0        [ZALEŻNOŚĆ] Image processing dla Tesseract
#   libopencv>=4.9.0         [AKTYWNA] OpenCV preprocessing
#   libxml2>=2.12.0          [ZALEŻNOŚĆ] XML parser dla lxml
#   libxslt>=1.1.39          [ZALEŻNOŚĆ] XSLT dla lxml
#   pkg-config>=0.29.2       [ZALEŻNOŚĆ] Wykrywanie bibliotek systemowych
#   mimalloc>=2.1.0          [AKTYWNA] Microsoft memory allocator
#   rust>=1.78.0             [ZALEŻNOŚĆ] Rust toolchain dla PyO3
#
# Feature dev:
#   cmake>=3.28.0            [ZALEŻNOŚĆ] Kompilacja llama-cpp-python z CUDA
#   semgrep>=1.40.0          [DEWELOPERSKA] SAST security scanning
#   nuitka>=1.8              [DEWELOPERSKA] Python→C compiler

### [PLIK: mise.toml]
# Narzędzia systemowe:
#   python 3.13              [AKTYWNA] Interpreter
#   rust latest              [ZALEŻNOŚĆ] Rust toolchain
#   nats-server 2.10         [AKTYWNA] NATS JetStream broker
#   tigerbeetle 0.16         [AKTYWNA] TigerBeetle ledger

### [PLIK: Cargo.toml]
# Rust crate: nexus-crypto v0.4.0
# Dependencies:
#   pyo3 0.22                [AKTYWNA] Python↔Rust bridge
#   pyo3-log 0.11            [AKTYWNA] Logging bridge
#   chacha20poly1305 0.10    [AKTYWNA] AEAD encryption
#   argon2 0.5               [AKTYWNA] Password hashing
#   sha2 0.10                [AKTYWNA] SHA-256 hashing
#   blake2 0.10              [AKTYWNA] Blake2 hashing
#   rand 0.9                 [AKTYWNA] CSPRNG
#   hex 0.4                  [AKTYWNA] Hex encoding
#   zeroize 1                [AKTYWNA] Secure memory zeroing
#   hmac 0.12                [AKTYWNA] HMAC
#   log 0.4                  [AKTYWNA] Logging
#   rust_decimal 1.36        [AKTYWNA] Decimal arithmetic
#   jsonwebtoken 9           [AKTYWNA] JWT
#   serde 1                  [AKTYWNA] Serialization
#   serde_json 1             [AKTYWNA] JSON
#   base64 0.22              [AKTYWNA] Base64
#   quick-xml 0.36           [AKTYWNA] XML (KSeF)
#   chrono 0.4               [AKTYWNA] DateTime
#   uuid 1                   [AKTYWNA] UUID generation
#   thiserror 2              [AKTYWNA] Error handling
#   rayon 1.10               [AKTYWNA] Parallelism
#   libc 0.2                 [ZALEŻNOŚĆ] System calls
#   mimalloc 0.1 (secure)    [AKTYWNA] Memory allocator
# Dev:
#   criterion 0.5            [DEWELOPERSKA] Benchmarking

## ── 1.2 IMPORTY PYTHON (z 352 plików .py) ──────────────────────────────────

### Biblioteki standardowe (Python stdlib):
#   abc                      [AKTYWNA] Abstract base classes
#   argparse                 [AKTYWNA] CLI argument parsing
#   asyncio                  [AKTYWNA] Async I/O (via anyio)
#   base64                   [AKTYWNA] Base64 encoding
#   calendar                 [SZCZĄTKOWA] Date utilities
#   collections              [AKTYWNA] Data structures
#   collections.abc          [AKTYWNA] ABC for collections
#   contextlib               [AKTYWNA] Context managers
#   contextvars              [AKTYWNA] Context variables
#   csv                      [SZCZĄTKOWA] CSV parsing
#   ctypes                   [SZCZĄTKOWA] C interop
#   dataclasses              [AKTYWNA] Data classes
#   datetime                 [AKTYWNA] Date/time handling
#   decimal                  [AKTYWNA] Decimal arithmetic
#   email                    [SZCZĄTKOWA] Email handling
#   enum                     [AKTYWNA] Enumerations
#   functools                [AKTYWNA] Functional tools
#   gc                       [SZCZĄTKOWA] Garbage collection
#   hashlib                  [AKTYWNA] Hashing
#   hmac                     [AKTYWNA] HMAC (fallback dla Rust)
#   html                     [SZCZĄTKOWA] HTML escaping
#   imaplib                  [SZCZĄTKOWA] IMAP client
#   importlib                [AKTYWNA] Dynamic imports
#   inspect                  [SZCZĄTKOWA] Introspection
#   io                       [AKTYWNA] I/O operations
#   json                     [AKTYWNA] JSON (częściowo zastąpiony msgspec)
#   logging                  [AKTYWNA] Standard logging (via Loguru)
#   math                     [AKTYWNA] Math functions
#   multiprocessing          [SZCZĄTKOWA] Shared memory
#   os                       [AKTYWNA] OS operations
#   pathlib                  [AKTYWNA] Path handling
#   pkgutil                  [SZCZĄTKOWA] Package utilities
#   platform                 [SZCZĄTKOWA] Platform detection
#   random                   [SZCZĄTKOWA] Random numbers
#   re                       [AKTYWNA] Regex
#   resource                 [SZCZĄTKOWA] Resource limits
#   secrets                  [SZCZĄTKOWA] Cryptographically secure random
#   shutil                   [AKTYWNA] File operations
#   signal                   [SZCZĄTKOWA] Signal handling
#   socket                   [SZCZĄTKOWA] Networking
#   sqlite3                  [AKTYWNA] SQLite (via SQLCipher)
#   statistics               [SZCZĄTKOWA] Statistics
#   stat                     [SZCZĄTKOWA] File stats
#   string                   [SZCZĄTKOWA] String utilities
#   subprocess               [SZCZĄTKOWA] Process spawning
#   sys                      [AKTYWNA] System interface
#   tempfile                 [SZCZĄTKOWA] Temp files
#   threading                [SZCZĄTKOWA] Threading (via anyio)
#   time                     [SZCZĄTKOWA] Time functions
#   typing                   [AKTYWNA] Type hints
#   urllib                   [SZCZĄTKOWA] URL handling
#   uuid                     [AKTYWNA] UUID generation
#   warnings                 [SZCZĄTKOWA] Warnings
#   xml                      [SZCZĄTKOWA] XML parsing
#   zipfile                  [SZCZĄTKOWA] ZIP archives

### Biblioteki zewnętrzne (PyPI):
#   PIL (Pillow)             [AKTYWNA] Image processing
#   alembic                  [AKTYWNA] DB migrations
#   anyio                    [AKTYWNA] Async runtime
#   duckdb                   [AKTYWNA] OLAP
#   flet                     [AKTYWNA] Desktop GUI
#   fsspec                   [AKTYWNA] Filesystem abstraction
#   granian                  [AKTYWNA] ASGI server
#   httpx                    [AKTYWNA] HTTP client
#   litestar                 [AKTYWNA] API framework
#   loguru                   [AKTYWNA] Logging
#   lxml                     [AKTYWNA] XML processing
#   matplotlib               [AKTYWNA] Financial charts
#   msgspec                  [AKTYWNA] Serialization
#   nexus_crypto             [AKTYWNA] Rust crypto module
#   numpy                    [AKTYWNA] Numerical computing
#   opentelemetry            [AKTYWNA] Monitoring
#   pendulum                 [AKTYWNA] DateTime
#   polars                   [AKTYWNA] DataFrame
#   psutil                   [AKTYWNA] System metrics
#   pydantic                 [ZALEŻNOŚĆ] Validation (via SQLModel)
#   sqlalchemy               [AKTYWNA] ORM core
#   sqlite_vec               [AKTYWNA] Vector search
#   sqlmodel                 [AKTYWNA] ORM
#   stamina                  [AKTYWNA] Retry + circuit breaker
#   structlog                [AKTYWNA] Structured logging
#   taskiq                   [AKTYWNA] Task queue
#   taskiq_nats              [AKTYWNA] NATS broker
#   tigerbeetle              [AKTYWNA] Accounting engine

## ── 1.3 IMPORTY RUST (z 19 plików .rs, 6,978 linii) ────────────────────────

### Rust crates (bezpośrednie + pośrednie):
#   nexus_crypto (lib.rs)    [AKTYWNA] Główny moduł kryptografii
#     - aead.rs              [AKTYWNA] ChaCha20Poly1305 AEAD → 251 linii
#     - blake.rs             [AKTYWNA] Blake2b512 → 22 linie
#     - digest.rs            [AKTYWNA] SHA-256 → 55 linii
#     - exceptions.rs        [AKTYWNA] Wyjątki PyO3 → 94 linie
#     - jwt.rs               [AKTYWNA] JWT obsługa → 588 linii
#     - ksef.rs              [AKTYWNA] KSeF XML podpis → 445 linii
#     - mac.rs               [AKTYWNA] HMAC → 26 linii
#     - password.rs          [AKTYWNA] Argon2id hashowanie → 64 linie
#     - secure.rs            [AKTYWNA] MlockedVec, SensitiveBytes → 626 linii
#     - tax.rs               [AKTYWNA] Matematyka podatkowa → 588 linii
#     - tax_pipeline.rs      [AKTYWNA] Pipeline podatkowy → 858 linii
#     - temporal_manager.rs  [AKTYWNA] Temporal manager → 537 linii
#     - trace_logger.rs      [AKTYWNA] Śledzenie audytowe → 1,328 linii
#     - engine/              [AKTYWNA] Silnik reguł:
#       - mod.rs             [AKTYWNA] → 27 linii
#       - condition.rs       [AKTYWNA] → 415 linii
#       - pipeline.rs        [AKTYWNA] → 505 linii
#       - priority_engine.rs  [AKTYWNA] → 101 linii
#       - rules_engine.rs    [AKTYWNA] → 259 linii

## ── 1.4 TECHNOLOGIE SYSTEMOWE (conda-forge / external) ─────────────────────

### Systemowe:
#   Tesseract 5.3            [AKTYWNA] OCR engine (binarka + traineddata)
#   Leptonica 1.84           [ZALEŻNOŚĆ] Image processing dla Tesseract
#   OpenCV 4.9               [AKTYWNA] Image preprocessing
#   libxml2 2.12             [ZALEŻNOŚĆ] XML parser
#   libxslt 1.1.39           [ZALEŻNOŚĆ] XSLT
#   mimalloc 2.1             [AKTYWNA] Memory allocator (LD_PRELOAD)
#   Rust 1.78                [ZALEŻNOŚĆ] Toolchain
#   cmake 3.28               [ZALEŻNOŚĆ] Build tool
#
# Usługi zewnętrzne:
#   NATS Server 2.10         [AKTYWNA] Message broker (JetStream)
#   TigerBeetle 0.16         [AKTYWNA] Double-entry accounting engine
#
# CI/CD:
#   GitHub Actions           [AKTYWNA] Pipeline CI/CD
#   Semgrep 1.40             [DEWELOPERSKA] SAST security scanning
#
# Build:
#   Nuitka 1.8               [DEWELOPERSKA] Python→C compiler
#   mypyc 1.8                [DEWELOPERSKA] Python→C compiler (type-based)
#   Maturin 1.5              [DEWELOPERSKA] Rust→Python wheel builder
#   UPX                      [DEWELOPERSKA] Binary compression
#   Inno Setup               [DEWELOPERSKA] Windows installer

### Testowanie:
#   pytest 8+                [DEWELOPERSKA] Test framework
#   pytest-cov               [DEWELOPERSKA] Coverage
#   pytest-xdist             [DEWELOPERSKA] Parallel tests
#   pytest-timeout           [DEWELOPERSKA] Timeout
#   pytest-benchmark         [DEWELOPERSKA] Performance benchmarks
#   pytest-sugar             [DEWELOPERSKA] Pretty output
#   pytest-watch             [DEWELOPERSKA] Auto-retest
#   crosshair 0.1            [DEWELOPERSKA] SMT property testing
#   hypothesis 6.100         [DEWELOPERSKA] Property-based testing
#   schemathesis 3+          [DEWELOPERSKA] API fuzz testing
#   locust 2+                [DEWELOPERSKA] Load testing
#   py-spy 0.3               [DEWELOPERSKA] Sampling profiler


# ═══════════════════════════════════════════════════════════════════════════════
# KROK 2: ALFABETYCZNA LISTA WSZYSTKICH TECHNOLOGII
# ═══════════════════════════════════════════════════════════════════════════════

# Legenda: [A]=AKTYWNA, [S]=SZCZĄTKOWA, [Z]=ZALEŻNOŚĆ POŚREDNIA, [D]=DEWELOPERSKA

Technologia                     | Kategoria                  | Status | Opis
──────────────────────────────────────────────────────────────────────────────────
alembic 1.18+                   | Migracje DB                | [A]    | Migracje schematu SQLAlchemy
anyio 4.13+                     | Async I/O                  | [A]    | Jednolity async runtime (asyncio/trio)
argon2 0.5                      | Kryptografia               | [Z]    | Password hashing (Rust)
base64 0.22                     | Encoding                   | [Z]    | Base64 (Rust)
blake2 0.10                     | Kryptografia               | [Z]    | Blake2b hashing (Rust)
chacha20poly1305 0.10           | Kryptografia               | [Z]    | AEAD szyfrowanie (Rust)
chrono 0.4                      | DateTime                   | [Z]    | DateTime (Rust)
cmake 3.28                      | Build                      | [D]    | Kompilacja llama-cpp
crosshair 0.1                   | Testowanie                 | [D]    | SMT property-based testing
DuckDB 1.0+                     | OLAP/Analytics             | [A]    | SQL OLAP (zastępuje pandas)
EasyOCR 1.7+                    | OCR                        | [A]    | CNN+LSTM OCR engine
Flet 0.28+                      | Desktop GUI                | [A]    | Framework GUI (Flutter-based)
fsspec 2024.3+                  | Filesystem                 | [A]    | Abstrakcja systemu plików
GitHub Actions                  | CI/CD                      | [D]    | Pipeline CI
Granian 1.0+                    | HTTP Server                | [A]    | ASGI server (Rust)
hatchling 1.21+                 | Build                      | [D]    | Python build backend
hishel 0.1+                     | HTTP Cache                 | [A]    | Inteligentny cache HTTP
httpx 0.27+                     | HTTP Client                | [A]    | Async HTTP klient
HuggingFace Hub 0.23+           | AI/ML                      | [A]    | Model hub
hypothesis 6.100+               | Testowanie                 | [D]    | Property-based testing
Inno Setup                      | Instalator                 | [D]    | Windows installer
jsonwebtoken 9                  | Auth                       | [Z]    | JWT (Rust)
Leptonica 1.84                  | Obrazy                     | [Z]    | Image processing (Tesseract)
Litestar 2.8+                   | Web Framework              | [A]    | API framework
llama-cpp-python 0.2+           | AI/ML                      | [A]    | LLM inference (GGUF)
locust 2.29+                    | Testowanie                 | [D]    | Load testing
Loguru 0.7+                     | Logowanie                  | [A]    | Logging
lxml 5.1+                       | XML                        | [A]    | XML/HTML parser
matplotlib 3.8+                 | Wizualizacja               | [A]    | Financial charts
maturin 1.5+                    | Build                      | [D]    | Rust→Python wheel
mimalloc 2.1+                   | Pamięć                     | [A]    | Memory allocator (5-15% mniej RAM)
mise                             | Dev Tools                  | [D]    | Task runner + version manager
msgspec 0.18+                   | Serializacja               | [A]    | Zastępuje json, orjson (10x szybciej)
mypy 1.8+                       | Typowanie                  | [D]    | Type checker
mypyc 1.8+                      | Kompilacja                 | [D]    | Python→C (2-5x szybciej)
NATS Server 2.10                | Kolejkowanie               | [A]    | Message broker (JetStream)
nats-py 2.6+                    | Klient NATS                | [A]    | NATS Python client
nexus-crypto 0.4                | Kryptografia               | [A]    | Rust moduł (AEAD, JWT, Argon2)
Nuitka 1.8+                     | Kompilacja                 | [D]    | Python→standalone .exe
NumPy 2.0+                      | Numeryczna                 | [A]    | Numerical computing
OpenCV 4.9                      | Obrazy                     | [A]    | Image preprocessing
OpenTelemetry 1.25+             | Monitoring                 | [A]    | Metryki + tracing
PaddleOCR 2.8+                  | OCR                        | [A]    | PaddlePaddle OCR
PaddlePaddle 3.0+               | Deep Learning              | [A]    | Framework DL (OCR)
pendulum 3.0+                   | DateTime                   | [A]    | Timezone-aware datetime
Pillow 10+                      | Obrazy                     | [A]    | Image processing
pixi                             | Środowisko                | [D]    | Environment manager (conda + PyPI)
Polars 1.0+                     | DataFrame                  | [A]    | DataFrame (natywny Rust)
pre-commit 3.6+                 | Dev Tools                  | [D]    | Git hooks
psutil 5.9+                     | System                     | [A]    | System metrics
PyArrow 15+                     | Dane                       | [A]    | Apache Arrow interop
pydantic                        | Walidacja                  | [Z]    | Schematy (via SQLModel)
pypdfium2 4.0+                  | PDF                        | [A]    | PDF→image (PDFium)
py-spy 0.3+                     | Profiling                  | [D]    | Sampling profiler
pytest 8+                       | Testowanie                 | [D]    | Test framework
python-doctr 0.9+               | OCR                        | [A]    | DBNet + PARSeq OCR
Python 3.13t                     | Język                      | [A]    | Free-threaded Python (bez GIL)
quick-xml 0.36                  | XML                        | [Z]    | XML (Rust, KSeF)
rayon 1.10                      | Równoległość              | [Z]    | Parallel iterator (Rust)
Ruff 0.3+                       | Linter                     | [D]    | Linter + formatter
Rust 1.78+                      | Język                      | [Z]    | Native extensions
schemathesis 3.30+              | Testowanie                 | [D]    | API fuzz testing
Semgrep 1.40+                   | Security                   | [D]    | SAST scanner
serde 1                         | Serializacja               | [Z]    | Rust serialization
sha2 0.10                       | Kryptografia               | [Z]    | SHA-256 (Rust)
SQLAlchemy                      | ORM                        | [Z]    | Core ORM (via SQLModel)
SQLCipher                       | Baza danych                | [A]    | Szyfrowana SQLite
SQLite                           | Baza danych                | [A]    | Główna baza danych
sqlite-vec 0.1+                 | Vector Search              | [A]    | Embedding search
SQLModel 0.0.16+                | ORM                        | [A]    | SQLAlchemy + Pydantic
stamina 0.1+                    | Resilience                 | [A]    | Retry + circuit breaker
structlog 24+                   | Logowanie                  | [A]    | Structured logging
taskiq 0.11+                    | Task Queue                 | [A]    | Asynchroniczna kolejka zadań
taskiq-nats 0.5+                | Task Queue                 | [A]    | NATS broker dla Taskiq
Tesseract 5.3+                  | OCR                        | [A]    | OCR engine
TigerBeetle 0.16                | Księgowość                | [A]    | Double-entry accounting engine
UPX                              | Kompresja                 | [D]    | Binary compression (30-50%)
uv                               | Package Manager           | [D]    | Szybki menedżer pakietów (Rust)
xsdata 24+                      | XML/XSD                    | [A]    | XSD→Python code gen
zeroize 1                       | Kryptografia               | [Z]    | Secure memory zeroing (Rust)

### Technologie nieaktywne / szczątkowe:
Technologia                     | Kategoria                  | Status | Uwagi
──────────────────────────────────────────────────────────────────────────────────
asyncio                          | Async                      | [S]    | Używane przez anyio (nie bezpośrednio)
json (standardowe)               | Serializacja               | [S]    | W trakcie migracji do msgspec
logging (standardowe)            | Logowanie                  | [S]    | Przeważnie zastąpione przez Loguru
multiprocessing                  | Współbieżność             | [S]    | Tylko shared_memory
threading                        | Wątki                      | [S]    | Rzadko używane (anyio preferowane)
subprocess                       | Procesy                    | [S]    | Tylko skrypty administracyjne
pandas                           | DataFrame                  | [NIEAKTYWNA] | Zastąpiony przez Polars
PyTorch                          | Deep Learning              | [NIEAKTYWNA] | Usunięty, zastąpiony llama-cpp
OpenCV-Python (cv2)              | Obrazy                     | [S]    | Głównie przez libopencv systemowy
cffi                             | C interop                  | [Z]    | Pośrednio przez niektóre biblioteki
sentry-sdk                       | Monitoring                 | [D]    | Tylko dev (error tracking)


# ═══════════════════════════════════════════════════════════════════════════════
# KROK 3: SZACOWANIE PAMIĘCI RAM (± GB)
# ═══════════════════════════════════════════════════════════════════════════════

## ── 3.1 ZAŁOŻENIA ───────────────────────────────────────────────────────────
# - Python 3.13t (free-threaded, bez GIL) → mniejsze zużycie na wątki
# - Granian: 4 workers (prod) lub 1 worker (dev)
# - NATS Server: proces towarzyszący
# - TigerBeetle: proces towarzyszący
# - SQLite/SQLCipher: wbudowane (w procesie)
# - DuckDB: wbudowane (w procesie)
# - mimalloc: zmniejsza fragmentację o 5-15%
# - 4 silniki OCR (tylko 1 aktywny naraz, ale modele załadowane)
# - LLM: model GGUF ~800MB-3GB (ładowany na żądanie)

## ── 3.2 TABELA SZACOWANIA ──────────────────────────────────────────────────

Komponent                    | Minimalne | Typowe   | Szczytowe | Uwagi
─────────────────────────────────────────────────────────────────────────────────
Python interpreter (3.13t)   | 0.05 GB   | 0.05 GB  | 0.05 GB   | Free-threaded (mniejszy footprint)
Granian ASGI (4 workers)     | 0.10 GB   | 0.25 GB  | 0.50 GB   | ~50-125 MB na worker; Rust, niski narzut
Litestar + SQLModel          | 0.05 GB   | 0.10 GB  | 0.20 GB   | Framework web + ORM
SQLite/SQLCipher (wbud.)     | 0.01 GB   | 0.02 GB  | 0.05 GB   | W procesie, cache stron
DuckDB (OLAP)                | 0.05 GB   | 0.15 GB  | 0.50 GB   | Kolumnowy, rośnie z danymi
Polars/NumPy (data)          | 0.05 GB   | 0.10 GB  | 0.50 GB   | DataFrame'y w pamięci
msgspec (serializacja)       | 0.01 GB   | 0.02 GB  | 0.05 GB   | Ultra-lekki
OpenTelemetry (metrics)      | 0.02 GB   | 0.05 GB  | 0.10 GB   | Bufor metryk
Loguru + structlog           | 0.01 GB   | 0.02 GB  | 0.05 GB   | Buffery logów
NATS Server (osobny proces)  | 0.02 GB   | 0.05 GB  | 0.15 GB   | JetStream, wiadomości w pamięci
TigerBeetle (osobny proces)  | 0.02 GB   | 0.05 GB  | 0.10 GB   | Zig, niski narzut
Model LLM (GGUF)             | 0.00 GB   | 0.80 GB  | 3.00 GB   | Tylko przy inferencji
OCR engine (PaddlePaddle)    | 0.00 GB   | 0.50 GB  | 1.50 GB   | Modele GPU/CPU
OCR engine (EasyOCR)         | 0.00 GB   | 0.30 GB  | 0.80 GB   | Modele CNN+LSTM
OCR engine (docTR)           | 0.00 GB   | 0.30 GB  | 0.80 GB   | DBNet + PARSeq
Tesseract (OCR)              | 0.00 GB   | 0.10 GB  | 0.30 GB   | Modele traineddata
Cache (hishel, fsspec)       | 0.01 GB   | 0.05 GB  | 0.20 GB   | HTTP cache w pamięci
Taskiq (kolejka zadań)       | 0.01 GB   | 0.02 GB  | 0.10 GB   | Zadania w tle
Taskiq worker proces         | 0.05 GB   | 0.10 GB  | 0.20 GB   | Osobny proces workera
mimalloc overhead             | 0.01 GB   | 0.02 GB  | 0.05 GB   | Allokator (5-15% oszczędności)
System buffers + overcommit  | 0.10 GB   | 0.25 GB  | 0.50 GB   | 20-30% narzut OS
─────────────────────────────────────────────────────────────────────────────────
RAZEM (bez LLM/OCR)          | 0.50 GB   | 1.50 GB  | 3.50 GB
RAZEM (z LLM)                | 0.50 GB   | 2.50 GB  | 6.50 GB
RAZEM (z LLM + OCR batch)    | 0.50 GB   | 3.50 GB  | 8.00 GB

## ── 3.3 PODSUMOWANIE RAM ────────────────────────────────────────────────────
# Minimalne RAM:  0.5 GB  (sam API, bez AI, bez OCR)
# Typowe RAM:     1.5-3.5 GB (API + worker + NATS + TigerBeetle + okazjonalne AI)
# Szczytowe RAM:  6.5-8.0 GB (batch OCR 4 silników + LLM inferencja + pełne obciążenie)
#
# Rekomendowana konfiguracja:
#   Dev:  8 GB  RAM  (wystarczające dla API + worker + NATS + TigerBeetle)
#   Prod: 16 GB RAM  (z zapasem na batch OCR, LLM i skoki obciążenia)


# ═══════════════════════════════════════════════════════════════════════════════
# KROK 4: SZACOWANIE MIEJSCA NA DYSKU (± GB)
# ═══════════════════════════════════════════════════════════════════════════════

## ── 4.1 ZAŁOŻENIA ───────────────────────────────────────────────────────────
# - System: Linux (produkcja) / macOS / Windows (dev)
# - Python 3.13t z pixi (conda-forge) → ~1 GB dla całego środowiska
# - Model LLM GGUF: ~800 MB (mały model) do 3 GB (duży model)
# - Modele OCR: Tesseract ~15 MB, PaddleOCR ~200 MB, docTR ~200 MB, EasyOCR ~100 MB
# - Rust toolchain: ~500 MB (tylko build)

## ── 4.2 ŚRODOWISKO DEWELOPERSKIE (wszystkie narzędzia) ─────────────────────

Komponent                    | Rozmiar    | Uwagi
─────────────────────────────────────────────────────────────────────────────────
Python 3.13t + stdlib        | 0.10 GB   | Free-threaded interpreter
pixi environment (conda)     | 1.00 GB   | Wszystkie conda + PyPI zależności
  - w tym: OpenCV             | 0.20 GB   | libopencv + python binding
  - w tym: Tesseract + Leptonica | 0.05 GB   | OCR + image processing
  - w tym: libxml2 + libxslt  | 0.01 GB   | XML processing
  - w tym: mimalloc           | 0.01 GB   | Memory allocator
  - w tym: Rust toolchain     | 0.50 GB   | rustc, cargo (build tylko)
  - w tym: cmake              | 0.02 GB   | Build tool
PyPI packages (site-packages)  | 1.50 GB   | Wszystkie biblioteki Python
  - w tym: PaddlePaddle       | 0.60 GB   | Deep learning framework
  - w tym: PyTorch (przez dep) | 0.00 GB   | Usunięty (był ~1.2 GB)
  - w tym: llama-cpp-python   | 0.15 GB   | LLM inference
  - w tym: Polars/PyArrow     | 0.10 GB   | DataFrame + Arrow
  - w tym: DuckDB             | 0.03 GB   | OLAP
  - w tym: Litestar + Granian | 0.05 GB   | API + server
  - w tym: NATS-py + Taskiq   | 0.02 GB   | Messaging
  - w tym: OpenTelemetry      | 0.03 GB   | Monitoring
  - w tym: matplotlib         | 0.05 GB   | Charts
  - w tym: Flet               | 0.10 GB   | Desktop GUI
  - w tym: Reszta (50+ pkg)   | 0.30 GB   | Pozostałe depy
Rust target/ (build cache)   | 0.50 GB   | Skompilowane crate (cache)
Modele AI:
  - Model GGUF (LLM)          | 0.80 GB   | Mały model (np. Phi-3, Llama-3.2)
  - Tesseract traineddata     | 0.02 GB   | Język polski + angielski
  - PaddleOCR models          | 0.20 GB   | Detection + recognition
  - docTR models              | 0.20 GB   | DBNet + PARSeq
  - EasyOCR models            | 0.10 GB   | CNN + LSTM
Pliki źródłowe (Python + Rust) | 0.02 GB   | Kod źródłowy
Artefakty build (Nuitka)     | 0.50 GB   | Skompilowany .exe (onefile ~100-200 MB + cache)
Test cache + __pycache__     | 0.05 GB   | Bytecode cache
Raporty, logs, app_data      | 0.10 GB   | Dane runtime
─────────────────────────────────────────────────────────────────────────────────
RAZEM (dev)                  | 5.00 GB   | Z wszystkimi modelami i cache
RAZEM (dev, bez modeli AI)   | 3.00 GB   | Bez modeli GGUF i OCR

## ── 4.3 ŚRODOWISKO PRODUKCYJNE (tylko runtime) ─────────────────────────────

Komponent                    | Rozmiar    | Uwagi
─────────────────────────────────────────────────────────────────────────────────
Python 3.13t + stdlib        | 0.10 GB   |
Nuitka standalone binary     | 0.20 GB   | Pojedynczy plik .exe (~100-200 MB)
Lub: pixi environment (runtime only) | 1.50 GB | Alternatywa dla Nuitka
  - Minimal PyPI packages     | 1.00 GB   | Tylko runtime (bez dev/test)
  - Modele AI (GGUF)          | 0.80 GB   | Tylko potrzebny model
  - Modele OCR (Tesseract)    | 0.02 GB   | Tylko Tesseract (podstawowe OCR)
NATS Server binary           | 0.01 GB   | ~10 MB binary
TigerBeetle binary           | 0.01 GB   | ~10 MB binary (Zig)
SQLite/SQLCipher (wbudowane)  | 0.00 GB   | W interpreterze
Pliki konfiguracyjne         | 0.00 GB   | TOML, JSON
─────────────────────────────────────────────────────────────────────────────────
RAZEM (prod, Nuitka binary)  | 1.00 GB   | Samodzielny binary + modele
RAZEM (prod, pixi env)       | 2.50 GB   | Pełne środowisko + modele

## ── 4.4 PODSUMOWANIE DYSKU ──────────────────────────────────────────────────
# Środowisko deweloperskie:  5.0 GB  (z modelami AI i cache build)
# Środowisko produkcyjne:    1.0-2.5 GB  (zależnie od deploymentu)
#
# Rekomendacja:
#   Dev:  min. 10 GB wolnego miejsca
#   Prod: min. 5 GB wolnego miejsca


# ═══════════════════════════════════════════════════════════════════════════════
# KROK 5: REKOMENDACJE OPTYMALIZACYJNE
# ═══════════════════════════════════════════════════════════════════════════════

## ── 5.1 TECHNOLOGIE DO USUNIĘCIA (martwy kod / nieużywane) ─────────────────

Technologia                  | Powód                         | Oszczędność RAM | Oszczędność dysku
────────────────────────────────────────────────────────────────────────────────────────────
PyTorch (już usunięty)       | Zastąpiony przez llama-cpp     | 0.5-1.0 GB     | 1.2 GB
pandas (już zastąpiony)      | Zastąpiony przez Polars        | 0.1-0.3 GB     | 0.05 GB
OpenCV Python (cv2)          | Używany systemowy libopencv    | 0.05 GB        | 0.10 GB
dodatkowe silniki OCR*       | 4 silniki OCR to przesada      | 0.5-1.5 GB     | 0.50 GB
────────────────────────────────────────────────────────────────────────────────────────────

* Uwaga: Projekt używa 4 silników OCR jednocześnie (Tesseract, PaddleOCR, docTR, EasyOCR).
  To daje redundancję i lepszą jakość (konsensus wielu OCR), ale kosztem pamięci.
  Można ograniczyć do 2 (Tesseract + 1 DL-based) i zaoszczędzić ~0.5-1.5 GB RAM.

## ── 5.2 TECHNOLOGIE DO ZASTĄPIENIA (lżejsze alternatywy) ────────────────────

Obecna technologia           | Proponowana alternatywa        | Zysk RAM | Zysk dysku
────────────────────────────────────────────────────────────────────────────────────────────
PaddlePaddle (600 MB)        | ONNX Runtime (~150 MB)         | 0.3 GB   | 0.45 GB
OpenCV (system + Python)     | Pillow tylko (dla prostych ops)| 0.1 GB   | 0.15 GB
Flet (desktop GUI)           | Opcjonalnie Web UI (oszczędność)| 0.05 GB  | 0.10 GB
────────────────────────────────────────────────────────────────────────────────────────────

## ── 5.3 OPTYMALIZACJE WDROŻONE JUŻ W PROJEKCIE ────────────────────────────

Optymalizacja                | Opis                          | Efekt
─────────────────────────────────────────────────────────────────────────────────
msgspec zamiast json/orjson  | 10x szybsza serializacja      | Mniej CPU, mniej RAM
Polars zamiast pandas        | DataFrame w Rust (zero-copy)   | 30-50% mniej RAM
free-threaded Python (3.13t) | Bez GIL, prawdziwa wielowątkowość | 20-30% mniej RAM
mimalloc                      | Microsoft allocator           | 5-15% mniej RAM
Granian (Rust) zamiast Uvicorn| Niższy narzut ASGI            | 0.02 GB
myрус kompilacja             | Python→C dla krytycznych modułów | 2-5x szybszy kod
hishel cache HTTP            | Inteligentny cache             | Mniej zapytań sieciowych
SQLCipher encrypted DB       | Szyfrowanie bazy               | Bezpieczeństwo (nie RAM)
─────────────────────────────────────────────────────────────────────────────────

## ── 5.4 POTENCJALNE OSZCZĘDNOŚCI ───────────────────────────────────────────

# Jeśli usunąć nieaktywne technologie i zoptymalizować OCR:
#   RAM:  oszczędność 0.5-1.5 GB (z 3.5 GB → 2.0-3.0 GB typowe)
#   Dysk: oszczędność 0.5-1.0 GB (z 5.0 GB → 4.0-4.5 GB deweloperskie)
#
# Jeśli zastąpić PaddlePaddle → ONNX Runtime:
#   RAM:  oszczędność 0.3 GB
#   Dysk: oszczędność 0.45 GB


# ═══════════════════════════════════════════════════════════════════════════════
# PODSUMOWANIE (SZCZĄTKOWE)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Projekt NexusAI wykorzystuje ~80 aktywnych technologii + ~20 nieaktywnych/szczątkowych.
# Łączna liczba zależności (bezpośrednich + pośrednich): ~150+ paczek PyPI + 50+ Rust crates.
#
# Szacowane zużycie:
#   RAM (typowe):  1.5-3.5 GB  | RAM (szczytowe):  6.5-8.0 GB
#   Dysk (dev):    5.0 GB      | Dysk (prod):      1.0-2.5 GB
#
# Główne "pożeracze" RAM: modele AI/OCR (GGUF: 0.8-3 GB, PaddlePaddle: 0.6 GB),
#                          DuckDB (0.5 GB), Polars (0.5 GB).
# Główne "pożeracze" dysku: pixi environment (1 GB), PaddlePaddle (0.6 GB),
#                            Rust target cache (0.5 GB), Nuitka artifacts (0.5 GB).
#
# Rekomendacja minimalna:
#   Dev:  8 GB RAM, 10 GB dysk
#   Prod: 16 GB RAM, 5 GB dysk  (Nuitka standalone) lub 10 GB (pixi env)
#
# ── KONIEC RAPORTU ──────────────────────────────────────────────────────────
