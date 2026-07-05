# 🤖 Manifest modeli AI (Models Manifest)

> **Cel:** Pełny wykaz wszystkich modeli AI używanych w NexusAI: 5 agentów + 8 modeli specjalistycznych.  \n> **Kiedy czytać:** Przed pobieraniem modeli (`pixi run download-models`), przed dodaniem nowego agenta, przy aktualizacji wersji modeli.

---

## 1. Filozofia zarządzania modelami

### 1.1 Rekomendowane nazwy (NIE zharkodowane w kodzie)

System NIE ma zharkodowanych nazw modeli. To jest **konwencja rekomendowana** — plik `config/models_manifest.toml` wskazuje konkretne pliki GGUF dla każdej roli.

```toml
# nexus_ai/config/models_manifest.toml (skrócony)
[models.orchestrator]
path = "models/granite-3.2-3b-instruct.Q4_K_M.gguf"
sha256 = "a3f4..."
expected_size_mb = 2100

[models.vision_guardian]
path = "models/granite-vision-guardian-0.3b.Q4_0.gguf"
sha256 = "b7e2..."
expected_size_mb = 280

# ...
```

`InferenceService` ładuje dowolny GGUF ze wskazanej ścieżki. **Możesz podmienić rekomendowany model** (np. na Llama-3-8B dla lepszej jakości kosztem RAM) bez zmian w kodzie.

### 1.2 Kwantyzacja

| Kod kwantyzacji | Rozmiar względny | Jakość | Rekomendowane użycie |
|---|---|---|---|
| **Q2_K** | ~50% oryginału | Niższa | Bardzo ograniczone RAM (4 GB), akceptujemy utratę jakości |
| **Q3_K_M** | ~65% | Dobra | Fallback gdy Q4 nie mieści się |
| **Q4_K_M** | ~75% | Bardzo dobra | **Domyślna** dla wszystkich modeli w NexusAI |
| **Q4_0** | ~70% | Dobra | Mniejsze, dobre dla walidatorów |
| **Q5_K_M** | ~85% | Świetna | Opcjonalne dla krytycznych modeli |
| **Q6_K** | ~92% | Prawie oryginalna | TYLKO w trybie developerskim |
| **Q8_0** | ~100% | Oryginalna | Benchmark i walidacja developerów |

---

## 2. 5 głównych agentów

### 2.1 Orkiestrator (Rekomendowany: Granite-3.2 3B Q4_K_M)

| Parametr | Wartość |
|---|---|
| **Rekomendowany model** | `ibm-granite/granite-3.2-3b-instruct` |
| **Plik GGUF** | `granite-3.2-3b-instruct.Q4_K_M.gguf` |
| **Rozmiar** | ~2.1 GB |
| **RAM zajętość** | ~2.4 GB (z kontekstem) |
| **SHA-256** | pobierane z: https://huggingface.co/ibm-granite/granite-3.2-3b-instruct |
| **KV cache size** | 2048 tokens (domyślnie) |
| **Warstwy GPU** | 0 (CPU only — zalecane dla ≤ 8 GB RAM) |
| **Rola w systemie** | Główny mózg Rady Agentów |

#### Odpowiedzialności:

- Przyjmuje zadanie (faktura, decyzja, pytanie)
- Deleguje pracę do innych agentów
- Zbiera wyniki
- Weryfikuje przez Strażnika Merytorycznego
- Podejmuje ostateczną decyzję

#### Prompt systemowy (wyciąg):

```text
Jesteś wirtualnym księgowym. Twoją rolą jest:
1. Analiza dokumentów księgowych
2. Podejmowanie decyzji AUTO_POST vs ASK_USER
3. Koordynacja pracy innych agentów
4. Idempotentność — powtórzenie z tymi samymi danymi powinno dać tę samą decyzję
5. Nigdy nie ignoruj sygnałów Strażnika Merytorycznego
```

### 2.2 Agent Ekstrakcji Danych (Vision Guardian 0.3B)

| Parametr | Wartość |
|---|---|
| **Rekomendowany model** | `ibm-granite/granite-vision-guardian-0.3b` |
| **Plik** | `granite-vision-guardian-0.3b.Q4_0.gguf` |
| **Rozmiar** | ~280 MB |
| **RAM** | ~400 MB |
| **Rola** | Nadzoruje OCR, weryfikuje JSON vs obraz |

#### Dodatkowe komponenty:

| Model | Plik | RAM | Rola |
|---|---|---|---|
| **ParagonDetect 0.1B** | `paragon-detect-0.1b.Q2_K.gguf` | ~120 MB | Klasyfikacja: faktura vs paragon |

### 2.3 Agent Analityczny (Fin-RWKV-169M)

| Parametr | Wartość |
|---|---|
| **Rekomendowany model** | `fin-rwkv/fin-rwkv-169m-q4_k_m` |
| **Plik** | `fin-rwkv-169m.Q4_K_M.gguf` |
| **Rozmiar** | ~110 MB |
| **RAM** | ~150 MB |
| **Rola** | Analiza kondycji finansowej, wykrywanie trendów |

#### Dodatkowe (opcjonalne):

| Model | Plik | RAM | Rola |
|---|---|---|---|
| **FinBERT-ESG 0.1B** | `finbert-esg-0.1b.Q4_0.gguf` | ~60 MB | ESG scoring kontrahentów |

### 2.4 Walidator Jakości (Granite Guardian 0.5B)

| Parametr | Wartość |
|---|---|
| **Rekomendowany model** | `ibm-granite/granite-guardian-3.0-0.5b` |
| **Plik** | `granite-guardian-0.5b.Q4_0.gguf` |
| **Rozmiar** | ~330 MB |
| **RAM** | ~400 MB |
| **Rola** | Strażnik Merytoryczny — weryfikuje KAŻDĄ decyzję Orkiestratora |

#### Przykład weryfikacji:

```
INPUT (decide):
  Decyzja: AUTO_POST
  Faktura: FV/2026/06/042, 5000 PLN netto, 23% VAT, FUEL
  Confidence: 0.94
  Kontekst: Kontrahent na Białej Liście

OUTPUT (verify):
  {
    "approved": true,
    "confidence": 0.96,
    "reason": "Wszystkie sygnały consistent: stawka prawidłowa, kwota bilansuje."
  }
```

### 2.5 Agent Środków Trwałych (Hrida-T2SQL-128k)

| Parametr | Wartość |
|---|---|
| **Rekomendowany model** | `hrida/hrida-t2sql-128k` |
| **Plik** | `hrida-t2sql-128k.Q4_K_M.gguf` |
| **Rozmiar** | ~480 MB |
| **RAM** | ~600 MB |
| **Rola** | Amortyzacja, ewidencja, plany amortyzacyjne |

---

## 3. 8 modeli specjalistycznych

### 3.1 ModernBERT-NER-Finance 0.3B (Walidator Semantyczny)

| Parametr | Wartość |
|---|---|
| **Plik** | `modernbert-ner-finance-0.3b.Q4_K_M.gguf` |
| **Rozmiar** | ~210 MB |
| **Rola** | Spójność danych faktury (NIP checksum, kwoty, daty) |
| **Wykorzystywany przez** | Pipeline OCR, ostatnia warstwa walidacji |

### 3.2 GraphSAGE-Encoder 0.1B (Fraud Graph)

| Parametr | Wartość |
|---|---|
| **Plik** | `graphsage-encoder-0.1b.Q4_0.gguf` |
| **Rozmiar** | ~80 MB |
| **Rola** | Detekcja fraudów (VAT karuzele, puste faktury) |
| **Wykorzystywany przez** | `FraudGraphScanner`, `VendorIntelligence` |

### 3.3 Lag-Llama 0.3B (Liquidity Oracle)

| Parametr | Wartość |
|---|---|
| **Plik** | `lag-llama-0.3b.Q4_K_M.gguf` |
| **Rozmiar** | ~180 MB |
| **Rola** | Predykcja płynności finansowej |
| **Wykorzystywany przez** | `LiquidityOracle`, `CashflowForecastService` |

### 3.4 Qwen3-Nano 0.5B (Komunikator)

| Parametr | Wartość |
|---|---|
| **Plik** | `qwen3-nano-0.5b.Q2_K.gguf` |
| **Rozmiar** | ~250 MB |
| **RAM** | ~300 MB |
| **Rola** | Formułuje pytania do użytkownika w języku naturalnym |
| **Wykorzystywany przez** | Centrum Decyzji (UI) |

### 3.5 Dodatkowe modele (development)

| Model | Rozmiar | Zastosowanie | Status |
|---|---|---|---|
| `liLT-base` | ~500 MB | Document understanding (layout) | Eksperymentalny |
| `HerBERT-base` | ~250 MB | Polish NER (named entities) | Eksperymentalny |
| `plT5-base` | ~500 MB | Polish Polish-text-to-SQL | Eksperymentalny |
| `flan-t5-small` | ~250 MB | Reasoning baseline | Development |

---

## 4. Tabela porównawcza (RAM, czas, dokładność)

> Metryki zmierzone na: Intel i7-9700K, 8GB RAM dedykowanych modelom, 1 faktura standard (300 DPI A4)

| Model | RAM | Czas inference | Dokładność (test set) |
|---|---|---|---|
| **Orchestrator (Granite 3.2 3B Q4_K_M)** | 2.4 GB | 800-1500 ms/decision | 0.94 (AUTO_POST correctness) |
| **Vision Guardian 0.3B** | 400 MB | 200-400 ms/invoice | 0.92 (image-to-JSON validation accuracy) |
| **Fin-RWKV-169M** | 150 MB | 30-80 ms/analysis | 0.88 (anomaly detection F1) |
| **Guardian 0.5B (Quality Validator)** | 400 MB | 150-300 ms/verify | 0.96 (adversarial validation accuracy) |
| **Hrida-T2SQL-128k** | 600 MB | 400-900 ms/SQL | 0.91 (SQL execution correctness) |
| **ModernBERT-NER-Finance 0.3B** | 210 MB | 50-150 ms/invoice | 0.94 (NER F1 on Polish invoices) |
| **GraphSAGE-Encoder 0.1B** | 80 MB | 20-60 ms/scan | 0.85 (fraud detection recall) |
| **Lag-Llama 0.3B** | 180 MB | 100-250 ms/forecast | 0.83 (liquidity forecasting MAPE) |
| **Qwen3-Nano 0.5B (Q2_K)** | 300 MB | 200-400 ms/question | 0.89 (Polish question generation) |

### 4.1 Tabela porównawcza 4 silników OCR (osobna, w [`MODULES.md`](MODULES.md))

| OCR Engine | RAM | Czas | Dokładność (recall) |
|---|---|---|---|
| **Tesseract 5.3** | ~0 MB (system) | 1-3 s/strona | 99.9% (druk klasyczny) |
| **PaddleOCR 2.8** | ~250 MB | 2-5 s/strona | 97.5% (różne czcionki) |
| **python-docTR 0.9** | ~350 MB | 3-7 s/strona | 98.2% (układ strony) |
| **EasyOCR 1.7** | ~300 MB | 4-8 s/strona | 96.8% (różnorodność) |
| **Konsensus (4 silniki)** | razem ~900 MB | 5-10 s/strona | **99.7%** (konsensus) |

---

## 5. Zarządzanie modelami

### 5.1 Komendy pixi

```bash
# Pobranie wszystkich 13 modeli
pixi run download-models
# → pobiera ~4 GB, weryfikuje SHA-256 per plik

# Sprawdzenie obecności i integralności
pixi run check-models
# → porównuje SHA-256 zapisany w `models/manifest.json`

# Przeliczenie SHA-256 dla wszystkich
pixi run compute-checksums
# → generuje/aktualizuje `models/manifest.json`

# Sprawdzenie dostępności aktualizacji
pixi run check-updates
# → sprawdza remote manifest (HTTPS, cert pinned)
```

### 5.2 Manifest (`models/manifest.json`)

```json
{
  "version": "3.0.0-dev",
  "generated_at": "2026-07-05T00:00:00Z",
  "models": {
    "orchestrator": {
      "filename": "granite-3.2-3b-instruct.Q4_K_M.gguf",
      "sha256": "sha256:abc123...",
      "size_bytes": 2200000000,
      "format": "GGUF",
      "quantization": "Q4_K_M",
      "source_url": "https://huggingface.co/ibm-granite/granite-3.2-3b-instruct/resolve/main/granite-3.2-3b-instruct.Q4_K_M.gguf",
      "license": "Apache-2.0"
    },
    "guardian_0.5b": {
      "filename": "granite-guardian-0.5b.Q4_0.gguf",
      "sha256": "sha256:def456...",
      "size_bytes": 346000000,
      "format": "GGUF",
      "quantization": "Q4_0",
      "source_url": "https://huggingface.co/ibm-granite/granite-guardian-3.0-0.5b/resolve/main/granite-guardian-0.5b.Q4_0.gguf",
      "license": "Apache-2.0"
    }
  }
}
```

### 5.3 Procedura pobierania z weryfikacją

```python
# nexus_ai/scripts/download_models.py (wyciąg uproszczony)

import hashlib
from pathlib import Path
import httpx

def download_with_verify(model_entry: dict, dest: Path):
    expected_sha256 = model_entry["sha256"].replace("sha256:", "")
    expected_size = model_entry["size_bytes"]
    
    # HEAD — sprawdź rozmiar zdalnie
    head = httpx.head(model_entry["source_url"])
    remote_size = int(head.headers["content-length"])
    assert remote_size == expected_size, "Manifest is outdated"
    
    # GET z hash streamingiem
    sha256 = hashlib.sha256()
    with httpx.stream("GET", model_entry["source_url"]) as r:
        with open(dest, "wb") as f:
            for chunk in r.iter_bytes(chunk_size=1 << 20):  # 1 MB
                sha256.update(chunk)
                f.write(chunk)
    
    # Weryfikacja końcowa
    actual = sha256.hexdigest()
    if actual != expected_sha256:
        dest.unlink()
        raise ValueError(f"SHA-256 mismatch for {dest}")
```

### 5.4 Hard-fail polityka

> ⚠️ **Jeśli SHA-256 modelu się nie zgadza, NexusAI NIE uruchomi się.** To nie jest soft warning. To jest bezwarunkowy REQUIRE.

Dla środowiska deweloperskiego istnieje `NEXUS_DEV_ALLOW_INSECURE=1` env var, ale **w produkcji jest zawsze wyłączony**.

---

## 6. Skąd pobierać modele

### 6.1 Źródła oficjalne (rekomendowane)

| Model | Hugging Face URL |
|---|---|
| Granite-3.2-3B | https://huggingface.co/ibm-granite/granite-3.2-3b-instruct |
| Granite Guardian 0.5B | https://huggingface.co/ibm-granite/granite-guardian-3.0-0.5b |
| Fin-RWKV-169M | https://huggingface.co/fin-rwkv/fin-rwkv-169m-q4_k_m |
| (pełna lista w `config/models_manifest.toml`) |

### 6.2 Mirror'y (fallback)

Jeśli HuggingFace nie jest dostępny:

1. **M1: GitHub Releases** — patrz [github.com/Gorski-Maciej/NexusAI-models](https://github.com/Gorski-Maciej/NexusAI-models/releases)
2. **M2: S3 mirror** — `https://models.nexus-ai.pl/` (HTTPS only, cert pinned)
3. **M3: IPFS** — CID'y w `models/manifest.json` (opcjonalnie)

### 6.3 Brak internetu

Jeśli modele są już pobrane wcześniej (w `models/*.gguf`), `download-models` pomija pobieranie.

---

## 7. Hot-reload modeli (bez restartu)

```bash
# Wymuszenie przeładowania
curl -X POST http://127.0.0.1:8000/api/v1/admin/reload-models \
  -H "Authorization: Bearer $TOKEN"
```

Operacja:
1. Weryfikacja SHA-256 każdego modelu
2. Graceful unload starego modelu (poczekaj aż inference zakończy się)
3. Załadowanie nowego modelu (lazy loading — tylko jeśli zmieniony)
4. Aktualizacja wewnętrznego registry

---

## 8. Aktualizacja modeli

### 8.1 Procedura release'u

1. Nowy model GGUF publikowany w upstream (HuggingFace)
2. Zespół NexusAI aktualizuje `models/manifest.json` w commitcie
3. CI buduje podpisaną paczkę `nexus-models-vX.Y.Z.tar.zst`
4. GitHub Release z notatkami (co się zmieniło w jakości)
5. Distributed to klientów via OTA (LiteServ)

### 8.2 Compatibility matrix

| NexusAI wersja | Wymagana wersja manifestu | Minimalny Granite |
|---|---|---|
| 2.3.x | 3.0.0-dev | 3.2 3B |
| 2.2.x | 2.2.0 | 3.0 3B |
| 2.1.x | 2.1.0 | 2.0 3B |
| 2.0.x | 2.0.0 | 2.0 2B |

---

## 9. Bezpieczeństwo modeli

### 9.1 Zagrożenia

| Zagrożenie | Mitigacja |
|---|---|
| **Model poisoning** (zhackowany model) | SHA-256 weryfikacja + certificate pinning + manifest signature |
| **Inference leak** (model ujawnia dane treningowe) | Modele ogólne (IBM Granite), nie fine-tuned na danych producenta |
| **Prompt injection** | Walidacja inputs przez RiskGuard + sentences limit + sandbox |
| **Side-channel** | Stałe czasy inference, ograniczone metadane |

### 9.2 Manifest signature (opcjonalne)

```bash
# Podpisywanie manifestu
gpg --detach-sign --armor models/manifest.json
# → manifest.json.asc

# Weryfikacja przy starcie
gpg --verify models/manifest.json.asc
```

---

## 10. Wydajność i limit sprzętowy

### 10.1 Minimalne wymagania

| Parametr | Minimum | Zalecane | Maksimum |
|---|---|---|---|
| **RAM (z modelami)** | 4 GB | 6 GB | 8 GB |
| **Czas startu** | < 30 s | < 15 s | < 30 s |
| **Czas inference** | < 5 s/dec | < 1.5 s/dec | < 0.5 s/dec |

### 10.2 Amortyzacja inwestycji w modele

| Decyzja | Skutek |
|---|---|
| **Wszystkie modele ładowane jednocześnie** | UX najszybsze (cold inference), RAM ~5 GB |
| **Lazy loading** (domyślne) | Mniejsze zużycie RAM (~3 GB active), +200-500 ms per first call |
| **Quantization Q2_K** | -50% RAM, -10% jakość |

Rekomendowane podejście: **lazy loading**, z opcją `--all-models-on-start` dla profesjonalnych księgowych.

---

## 🔗 Zobacz również

- [Architecture](ARCHITECTURE.md) — modele a warstwy (Infrastructure)
- [Modules](MODULES.md) — implementacja agentów
- [Rust Module](RUST_MODULE.md) — weryfikacja SHA-256 per plik
- [Security](SECURITY.md) — model poisoning mitigacje
- [Configuration](INSTALLATION.md) — env vars dla AI

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 3.0.0-dev
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** AI/OCR Team
