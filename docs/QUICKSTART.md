# 🚀 Szybki start (Quick Start)

> **Cel:** uruchomić NexusAI lokalnie w mniej niż **15 minut** (kompletnie od zera, łącznie z instalacją pixi).

> Jeśli masz już doświadczenie z Pythonem/Rustem, przejdź do sekcji [`Skrócony cheat-sheet`](#skrócony-cheat-sheet).

---

## 1. Wymagania wstępne

### 1.1 Sprzęt

| Parametr | Minimum | Zalecane |
|---|---|---|
| CPU | 4 rdzenie x86_64 z AVX2 | 8+ rdzeni z AVX2 |
| RAM | 4 GB | **6 GB** |
| Dysk | 5 GB SSD | 10 GB SSD |
| Internet (instalacja) | Tak | — |

### 1.2 System operacyjny

- **Linux x86_64** — Ubuntu 22.04 LTS / Debian 12 (testowane).
- **Linux aarch64** — Raspberry Pi 5 / Mac M1-4 (eksperymentalne).
- **Windows x64** — Windows 10+.

> **macOS:** obecnie nie jest w pełni wspierany (brak natywnego instalatora Inno Setup). Można uruchomić dewelopersko przez pixi, ale instalator produkcyjny jest tylko dla Windows/Linux.

### 1.3 Narzędzia systemowe

- **`pixi`** — menedżer środowiska (zastępuje ręczne `pip install`, `apt install`, `cargo install`).
- **System C toolchain** — `gcc`/`clang` dla budowania natywnych modułów Python.
- `git`, `curl`, `unzip` — standardowe narzędzia developerskie.

> **DevTip:** Dzięki temu, że `pixi` zarządza **Pythonem (3.13t), Rustem, Tesseractem, OpenCV, mimalloc, SQLCipher** w jednym pliku `pixi.toml`, nie musisz nic instalować globalnie. Wszystko jest w izolowanym środowisku `.pixi/`.

---

## 2. Instalacja w 6 krokach

### Krok 1 (1 min) — Zainstaluj pixi

```bash
# Linux / macOS
curl -fsSL https://pixi.sh/install.sh | sh

# Windows (PowerShell)
irm https://pixi.sh/install.ps1 | iex
```

Sprawdź:
```bash
pixi --version
```

Powinno zwrócić `pixi 0.4x.x` lub nowsze.

### Krok 2 (1 min) — Sklonuj repo

```bash
git clone https://github.com/Gorski-Maciej/NexusAI.git
cd NexusAI
```

### Krok 3 (5 min) — Zainstaluj środowisko

```bash
pixi install
```

> **Co się dzieje?** Pixi pobiera Pythona 3.13t (free-threaded), Rust ≥1.78, Tesseract ≥5.3, OpenCV ≥4.9, mimalloc ≥2.1, SQLCipher, OPA ≥0.6x, **wszystkie pakiety z `pyproject.toml`** oraz `nexus-crypto` z lokalnego katalogu i kompiluje go przez maturin. Pierwsze uruchomienie trwa 3–5 minut (kompilacja Rust). Kolejne są już cache'owane.

### Krok 4 (2 min) — Wykonaj migracje

```bash
pixi run migrate
```

To polecenie uruchamia `migrations/run_migrations.py`, które tworzy bazę SQLite (`app_data/nexus.db`) ze wszystkimi tabelami z migracji 001–004 + role/permissions seed.

Sprawdź, czy baza istnieje:
```bash
ls -la app_data/
# Powinno być: nexus.db
```

### Krok 5 (3 min) — Uruchom API

```bash
pixi run api
```

> To polecenie włącza Granian (Rust ASGI) z Litestar. Serwer nasłuchuje na `http://127.0.0.1:8000`.

**W osobnym terminalu** sprawdź:

```bash
curl http://127.0.0.1:8000/health
# → {"status": "healthy", "version": "2.3.0", ...}
```

Lub otwórz w przeglądarce:

- **Swagger UI:** <http://127.0.0.1:8000/schema/swagger>
- **Health JSON:** <http://127.0.0.1:8000/api/v1/health>
- **Metryki Granian:** <http://127.0.0.1:9090/metrics>

### Krok 6 (3 min) — Uruchom UI desktopowe (opcjonalnie)

W **jeszcze jednym** osobnym terminalu:

```bash
pixi run desktop
```

To uruchamia aplikację Flet (Flutter) — gotowy interfejs Material Design 3.

---

## 3. Pierwszy test End-to-End (opcjonalnie, ale zalecany)

### 3.1 Uruchom pełen stack developerski

```bash
pixi run dev
```

To polecenie włącza **jednocześnie**:
- NATS JetStream (port 4222)
- TigerBeetle (UNIX socket `/tmp/nexus-tb.sock`)
- API (Granian)
- Worker (Taskiq)

> **DevTip:** Jeśli pierwszy raz uruchamiasz — `pixi run format-tigerbeetle` sformatuje plik danych TigerBeetle.

### 3.2 Zaloguj się i utwórz fakturę

```bash
# Login (domyślny admin po migracji: admin/admin)
curl -X POST http://127.0.0.1:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'

# Wyślij fakturę do OCR (multipart)
curl -X POST http://127.0.0.1:8000/api/v1/invoices/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@tests/fixtures/sample_invoice.pdf"

# Sprawdź status
curl http://127.0.0.1:8000/api/v1/invoices \
  -H "Authorization: Bearer $TOKEN"
```

> Kompletny opis API: [`API.md`](API.md).

### 3.3 Zweryfikuj, że testy przechodzą

```bash
pixi run test
```

Powinno wyświetlić raport `X passed in Y.Ys`. Pełne info: [`TESTING.md`](TESTING.md).

---

## 4. Skrócony cheat-sheet

| Czynność | Komenda |
|---|---|
| Aktywuj shell w środowisku | `pixi shell` |
| Uruchom API | `pixi run api` |
| Uruchom API + worker | `pixi run dev` |
| Uruchom UI desktopowe | `pixi run desktop` |
| Uruchom testy | `pixi run test` |
| Testy + coverage | `pixi run test-cov` |
| Lint (Ruff) | `pixi run lint` |
| Typecheck (mypy) | `pixi run typecheck` |
| Formatowanie (Ruff) | `pixi run format` |
| Migracje bazy danych | `pixi run migrate` |
| Status aktualnej migracji | `pixi run migrate-check` |
| Seed dane demo | `pixi run seed` |
| Diagnostyka systemu | `pixi run doctor` |
| Pobierz modele AI | `pixi run download-models` |
| Sprawdź modele AI | `pixi run check-models` |
| Build Rust (nexus-crypto) | `pixi run build-rust` |
| Build produkcyjny .exe (Nuitka) | `pixi run build-nuitka` |
| Profiluj proces (py-spy) | `pixi run profile` |
| Wyczyść artefakty | `pixi run clean` |
| Wyświetl info o środowisku | `pixi run env-info` |

> Kompletna lista 50+ tasków: [`pixi run --list`](https://pixi.prefix.dev) (pełny opis w [`INSTALLATION.md`](INSTALLATION.md)).

---

## 5. Najczęstsze problemy (rozwiązania)

### 5.1 „pixi: command not found"

```bash
# Po instalacji pixi musisz przeładować PATH:
source ~/.bashrc   # lub restart terminala

# Albo użyj pełnej ścieżki:
~/.local/bin/pixi --version
```

### 5.2 „Failed to compile nexus-crypto"

> Przyczyna: brak `gcc`/`clang` lub `maturin`.

```bash
# Ubuntu/Debian
sudo apt install build-essential gcc

# Fedora/RHEL
sudo dnf install gcc make

# macOS
xcode-select --install
```

Potem:
```bash
pixi run build-rust
```

### 5.3 „Tesseract not found"

> Przyczyna: pixi sam dostarcza Tesseract, ale jeśli używasz Pythona spoza pixi:

```bash
# Upewnij się, że używasz Pythona z pixi:
pixi run python --version
# Powinno zwrócić 3.13.x

# Jeśli uruchamiasz `python main.py` spoza pixi:
pixi shell
```

### 5.4 „Port 8000 already in use"

```bash
# Linux: znajdź i zabij
lsof -i :8000
kill -9 <PID>

# Lub zmień port:
NEXUS_PORT=8080 pixi run api
```

### 5.5 „Migracja się nie powiodła"

```bash
# Sprawdź historię
pixi run migrate-history

# Suchy przebieg
pixi run migrate-dry

# Jeśli problematyczna migracja — usuń bazę i zacznij czysto
rm -f app_data/nexus.db
pixi run migrate
```

Pełna sekcja: [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

---

## 6. Co teraz?

| Chcesz… | Przejdź do… |
|---|---|
| Zrozumieć architekturę | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| Pracować z bazą | [`DATABASE.md`](DATABASE.md) |
| Wywoływać API | [`API.md`](API.md) |
| Pisać testy | [`TESTING.md`](TESTING.md) |
| Zbudować binarkę | [`DEPLOYMENT.md`](DEPLOYMENT.md) |
| Zrozumieć poszczególne serwisy | [`MODULES.md`](MODULES.md) |

---

## 🔗 Zobacz również

- [Wprowadzenie](INTRODUCTION.md) — misja, propozycja wartości, użytkownicy
- [Instalacja i konfiguracja](INSTALLATION.md) — szczegółowy setup i zmienne środowiskowe
- [Architektura](ARCHITECTURE.md) — diagramy C4, ADR, wzorce
- [Rozwiązywanie problemów](TROUBLESHOOTING.md) — najczęstsze błędy i rozwiązania

---

> **Data aktualizacji:** 2026-07-04 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-04 · **Weryfikator:** NexusAI Team
