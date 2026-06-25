# PYPI_DEPS_CLEANUP_REPORT

**Data:** 25 czerwca 2026
**Autor:** Buffy (AI Agent)

## Cel

Usunięcie 10 zbędnych/nieużywanych pakietów PyPI z list technologii oraz ewentualnych bezpośrednich importów w kodzie źródłowym.

## Wynik skanu

### Bezpośrednie importy w kodzie Python

**Żaden z 10 pakietów nie jest importowany bezpośrednio w kodzie źródłowym.** Skan `grep` przez wszystkie pliki `.py` nie znalazł żadnych importów.

| Pakiet | Importy w kodzie | Status |
|--------|-----------------|--------|
| `jinja2` | 0 | ✅ Już nieużywany |
| `rich` | 0 | ✅ Już nieużywany |
| `tqdm` | 0 | ✅ Już nieużywany |
| `requests` | 0 | ✅ Już nieużywany |
| `python-dotenv` | 0 | ✅ Już nieużywany |
| `scipy` | 0 | ✅ Już nieużywany |
| `scikit-image` | 0 | ✅ Już nieużywany |
| `shapely` | 0 | ✅ Już nieużywany |
| `albumentations` | 0 | ✅ Już nieużywany |
| `regex` | 0 | ✅ Już nieużywany |

### Bezpośrednie zależności w konfiguracji

**Żaden z 10 pakietów nie występuje jako bezpośrednia zależność** w `pyproject.toml` ani `pixi.toml`. `dotenv` występuje jedynie jako extra `granian[dotenv,...]` (wbudowana funkcja serwera Granian, nie biblioteka `python-dotenv`).

## Usunięte pozycje z dokumentacji

### RAPORT_TECHNOLOGII_NEXUSAI.txt (sekcja 3 — lista płaska)

| Lp. | Pakiet | Opis (usunięty) |
|-----|--------|-----------------|
| 1 | `scipy` (v1.17.1) | Obliczenia naukowe |
| 2 | `jinja2` (v3.1.6) | Templating |
| 3 | `rich` (v15.0.0) | Terminal UI |
| 4 | `tqdm` (v4.68.1) | Progress bar |
| 5 | `requests` (v2.34.2) | HTTP (zastąpiony przez httpx) |

### README.md (tabele technologii)

| Pakiet | Lokalizacja | Zmiana |
|--------|------------|--------|
| `python-dotenv` | Punkt 4, tabela msgspec (line 92) | Usunięto z kolumny "Zastępuje" |
| `python-dotenv` | Punkt 14, tabela TOML+msgspec (line 179) | Usunięto z kolumny "Zastępuje" |

### Pozostałe pakiety (`scikit-image`, `shapely`, `albumentations`, `regex`)

Nie występowały jako samodzielne technologie w żadnej dokumentacji — **zero zmian**.

## Zmodyfikowane pliki (3)

| Plik | Zmiany |
|------|--------|
| `RAPORT_TECHNOLOGII_NEXUSAI.txt` | Usunięto 5 pozycji z sekcji 3 (Narzędzia): scipy, jinja2, rich, tqdm, requests. Zaktualizowano statystykę ~303 → ~298. |
| `README.md` | Usunięto `python-dotenv` z kolumny "Zastępuje" w 2 tabelach (Punkt 4 i Punkt 14). |
| `PYPI_DEPS_CLEANUP_REPORT.md` | **NOWY** — niniejszy raport. |

## Weryfikacja

### 1. Brak bezpośrednich importów w kodzie

```bash
grep -r "import jinja2\|import rich\|import tqdm\|import requests\|import dotenv\|import scipy\|import skimage\|import shapely\|import albumentations\|import regex" --include="*.py"
# → PUSTY ✅
```

### 2. Brak pozostałości na listach technologii

```bash
grep -rn "scipy\|jinja2\|rich\|tqdm\|requests" RAPORT_TECHNOLOGII_NEXUSAI.txt
# → PUSTY ✅
```

### 3. Zależności w pixi.lock

Pakiety mogą pozostać w `pixi.lock` jako zależności przechodnie (transitive) innych pakietów — to oczekiwane zachowanie. Nie usuwamy ich fizycznie ze środowiska.

## Podsumowanie

| Kategoria | Liczba |
|-----------|--------|
| Usunięte pozycje z dokumentacji | **5** (scipy, jinja2, rich, tqdm, requests) |
| Usunięte z tabel README.md | **1** (python-dotenv — w 2 miejscach) |
| Pakiety już nieobecne w dokumentacji | **4** (scikit-image, shapely, albumentations, regex) |
| Bezpośrednie importy w kodzie | **0** (żaden pakiet nie był importowany) |
| Bezpośrednie zależności w pyproject.toml/pixi.toml | **0** |
| Zmodyfikowane pliki | **2** (RAPORT, README) |
| Nowe pliki | **1** (niniejszy raport) |
