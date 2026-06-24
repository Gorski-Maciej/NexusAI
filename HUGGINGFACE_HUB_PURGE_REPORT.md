# HuggingFace Hub API Purge Report

**Data:** 24 czerwca 2026
**Operacja:** Usunięcie HuggingFace Hub API z kodu, zależności i dokumentacji projektu NexusAI

---

## Zmodyfikowane pliki

| Plik | Zmiana |
|------|--------|
| `nexus_ai/scripts/download_models.py` | Usunięto blok `from huggingface_hub import snapshot_download` (linie 193-213). Zastąpiono komunikatem auto-download. |
| `nexus_ai/installer/models_downloader.py` | Usunięto `import huggingface_hub` check. Usunięto funkcję `_get_hf_download_url()`. Zaktualizowano `ModelEntry` struct: zastąpiono `repo_id` + `filename` polem `url`. Zaktualizowano `load_manifest()` do obsługi formatu listowego i słownikowego. Zaktualizowano `download_all_models()` do użycia `entry.url` z manifestu. |
| `tests/conftest.py` | Usunięto `"huggingface_hub", "huggingface_hub._snapshot_download"` z listy mockowanych modułów. |
| `pyproject.toml` | Usunięto zależność `"huggingface-hub>=0.23.0"` z `[project.dependencies]`. Zaktualizowano komentarz. Usunięto `"huggingface_hub"` z Nuitka `include-package` (zastąpiono komentarzem). |
| `pixi.toml` | Usunięto `huggingface-hub = ">=0.23.0"` z `[pypi-dependencies]`. Zaktualizowano komentarz. |
| `RAPORT_TECHNOLOGII_NEXUSAI.txt` | Usunięto pozycję 89 (`huggingface-hub >=0.23.0`). Usunięto pozycję 157 (`HuggingFace Hub API`). Usunięto `huggingface-hub` z listy w sekcji 3. Zaktualizowano opis `Transformers`. Przenumerowano wszystkie pozycje ≥158. |

## Liczba usuniętych linii kodu

- **Importy:** 2 linie (`import huggingface_hub` + `from huggingface_hub import snapshot_download`)
- **Funkcje:** 1 funkcja (`_get_hf_download_url()`, 4 linie)
- **Mocki testowe:** 2 linie
- **Zależności:** 2 linie (pyproject.toml + pixi.toml)
- **Dokumentacja:** ~5 linii
- **Łącznie:** ~15 linii

## Opis zastąpień

| Stary mechanizm | Nowy mechanizm |
|-----------------|----------------|
| `huggingface_hub.snapshot_download(repo_id, cache_dir)` | Auto-download przy pierwszym użyciu (docTR) |
| `huggingface_hub` availability check | Bezpośrednie HTTP download przez httpx |
| `_get_hf_download_url(repo_id, filename)` → konstrukcja URL HuggingFace | `entry.url` → URL z manifestu `config/models_manifest.json` |

## Weryfikacja

| Sprawdzenie | Wynik |
|-------------|-------|
| `grep -r 'import huggingface_hub' nexus_ai/ tests/` | ✅ CZYSTO — zero importów |
| `grep -r 'huggingface' pyproject.toml pixi.toml` | ✅ Tylko komentarze dokumentujące usunięcie |
| `grep -r 'huggingface' RAPORT_TECHNOLOGII_NEXUSAI.txt README.md` | ✅ CZYSTO |
| `pixi list \| grep -i huggingface` | ✅ Nie jest bezpośrednią zależnością |

## Uwagi końcowe

- `huggingface-hub` może pozostać jako zależność **przechodnia** przez bibliotekę `transformers` — to oczekiwane i nie stanowi problemu.
- Adresy URL w `config/models_manifest.json` nadal wskazują na `huggingface.co` (są to bezpośrednie linki HTTP, nie API calls). W przyszłości można je zmienić na własny serwer LiteServ.
- Komentarze w `pyproject.toml` i `pixi.toml` dokumentujące usunięcie pozostawiono celowo — wyjaśniają dlaczego zależność nie występuje w plikach konfiguracyjnych.
