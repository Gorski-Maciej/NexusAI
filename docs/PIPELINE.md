# OCR Pipeline — System rozpoznawania dokumentów

> **Plik:** `nexus_ai/pipeline/`
> **Status:** Stabilny · **Wersja:** 3.0.0-dev
> **Ostatnia aktualizacja:** 2026-07-05

---

## 1. Przegląd

NexusAI wykorzystuje **4 silniki OCR** działające równolegle z mechanizmem **konsensusu głosowania**, osiągając nawet **99.7% dokładności** ekstrakcji pól faktur.

```
                     Dokument (PDF/obraz)
                              │
                              ▼
                    ┌─────────────────┐
                    │  Preprocessing   │
                    │  (OpenCV/PIL)    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
        │Tesseract │ │PaddleOCR │ │  docTR   │ │ EasyOCR  │
        │   (CLI)  │ │(Paddle)  │ │(doctr)   │ │ (easyocr)│
        └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
             │            │            │            │
             └────────────┼────────────┼────────────┘
                          ▼            ▼
                   ┌──────────────────────┐
                   │   OCR Consensus      │
                   │  (voting + weights)  │
                   └──────────┬───────────┘
                              ▼
                   ┌──────────────────────┐
                   │   InvoiceParser      │
                   │  (regex + bbox)      │
                   └──────────┬───────────┘
                              ▼
                   ┌──────────────────────┐
                   │   ParsedInvoice      │
                   │  (struktura danych)   │
                   └──────────────────────┘
```

---

## 2. BaseOCREngine — Wzorzec Template Method

**Plik:** `nexus_ai/pipeline/ocr_base.py`

Wspólna klasa bazowa eliminująca **~1 500 linii duplikacji** między 4 silnikami. Każdy silnik definiuje tylko specyficzną implementację, reszta jest współdzielona.

### 2.1 Szablon

```python
class BaseOCREngine(ABC):
    @property
    @abstractmethod
    def name(self) -> str: ...

    def __init__(self):
        self._available = False     # Czy silnik został zainicjalizowany

    @abstractmethod
    def _init_engine(self) -> None: ...

    @abstractmethod
    async def _extract_text_impl(self, image_path: Path) -> str | None: ...
    async def _extract_confidence_impl(self, image_path: Path) -> list[dict] | None: ...
    async def _extract_amount_impl(self, image_path: Path) -> float | None: ...
    async def _extract_digits_impl(self, image_path: Path, expected_length=10) -> str | None: ...
```

### 2.2 Publiczne API (współdzielone)

```python
@catch_ocr_errors()           # Automatyczna obsługa błędów + logowanie
async def extract_text(image_path) -> str | None
async def extract_text_with_confidence(image_path) -> list[dict] | None
async def extract_amount(image_path) -> float | None
async def extract_digits(image_path, expected_length=10) -> str | None
```

### 2.3 Dekorator catch_ocr_errors

```python
def catch_ocr_errors(default=None):
    """Łapie błędy OCR i loguje z nazwą silnika.
    Zastępuje 8x @logger.catch w każdym silniku."""
```

- Sprawdza `self._available` — jeśli False, zwraca `None` bez próby
- Loguje błędy z nazwą silnika: `[OCR] {name}.{func} failed: {exc}`
- Zwraca `default` przy każdym błędzie (graceful degradation)

### 2.4 Domyślne implementacje

Jeśli silnik nie implementuje metody dedykowanej, używane są implementacje bazowe:

- **`_extract_amount_impl`** — regex `\d[\d\s,.-]*\d` na tekście z `_extract_text_impl`
- **`_extract_digits_impl`** — usuwa wszystkie nie-cyfry z tekstu, obcina do `expected_length`

---

## 3. Silniki OCR

### 3.1 TesseractEngine

| Cecha | Wartość |
|---|---|
| **Silnik** | Tesseract OCR (CLI) |
| **Język** | polski (domyślnie) |
| **Metoda** | `subprocess` przez `anyio.run_process` |
| **Dostępność** | `shutil.which("tesseract")` |

#### Konfiguracja

```python
TesseractEngine(
    lang="pol",              # Język OCR
    psm=4,                   # Page Segmentation Mode (0-13)
    oem=1,                   # OCR Engine Mode (0-3)
    dpi=None,                # DPI override
    tessdata_dir=None,       # Ścieżka do tessdata
    user_words_path=None,    # Słownik użytkownika
    user_patterns_path=None, # Wzorce użytkownika
    char_whitelist=None,     # Dozwolone znaki
    char_blacklist=None,     # Wykluczone znaki
)
```

#### Obsługiwane tryby

- **PSM**: 0-13 (domyślnie 4 = blok tekstu)
- **OEM**: 0-3 (domyślnie 1 = LSTM)
- **Dodatkowe**: TSV output dla confidence, digits-only dla NIP/IBAN, amount-only z whitelistem cyfr

#### Ekstrakcja

| Metoda | Implementacja |
|---|---|
| `_extract_text_impl` | `tesseract - - stdout -l pol --psm 4 --oem 1` |
| `_extract_confidence_impl` | `tesseract - - stdout -l pol tsv` → parsowanie TSV, poziom 5 (words) |
| `_extract_amount_impl` | `--psm 6 -c tessedit_char_whitelist=0123456789.,-` |
| `_extract_digits_impl` | `--psm 7 -c tessedit_char_whitelist=0123456789` |

---

### 3.2 PaddleOCREngine

| Cecha | Wartość |
|---|---|
| **Silnik** | PaddleOCR (PP-OCRv4) |
| **Język** | polski |
| **GPU** | Tak (domyślnie), 8 GB VRAM |
| **Framework** | PaddlePaddle |

#### Konfiguracja

```python
PaddleOCREngine(
    lang="pl",
    use_gpu=True,
    rec_batch_num=6,         # Batch size dla recognition
    det_db_thresh=0.3,       # Detection threshold
    det_db_box_thresh=0.5,   # Box threshold
    det_db_score_mode="fast",
    use_dilation=True,
)
```

#### Dodatkowe metody

```python
async def extract_structured(image_path) -> dict    # Pełna struktura: blocks, bbox, confidence
async def extract_layout(image_path) -> list[dict]  # Bloki layoutu
async def extract_tables(image_path) -> list[dict]  # Tabele (przez PP-Structure)
async def detect_seals(image_path) -> list[dict]    # Pieczęcie (przez PP-Structure)
async def extract_text_batch(image_paths) -> list   # Batch processing wielu obrazów
def enable_tensorrt() -> bool                       # Włącz TensorRT (optimizacja GPU)
```

#### PP-Structure Engine

PaddleOCR zawiera również **PP-Structure** do analizy layoutu dokumentów:

- `extract_layout()` — wykrywa bloki tekstu, tabel, pieczęci
- `extract_tables()` — ekstrakcja tabel z HTML output
- `detect_seals()` — wykrywanie pieczęci
- Każda metoda zwraca listę bloków z `type`, `bbox`, `confidence`, `html`

#### Warmup GPU

Aby uniknąć opóźnienia przy pierwszym użyciu, silnik wykonuje warmup na obrazie 100×100 px.

---

### 3.3 DocTREngine

| Cecha | Wartość |
|---|---|
| **Silnik** | docTR (mindee/doctr) |
| **Detektor** | db_resnet50 (domyślnie) |
| **Recognizer** | PARSeq (domyślnie) |
| **GPU** | Tak (domyślnie) |

#### Konfiguracja

```python
DocTREngine(
    det_arch="db_resnet50",          # Architektura detektora
    reco_arch="parseq",              # Architektura recognizera
    detect_orientation=True,         # Auto-detect orientation
    use_gpu=True,
    assume_straight_pages=True,
    straighten_pages=True,
    det_bs=4,                        # Batch size dla detekcji
    reco_bs=8,                       # Batch size dla rozpoznawania
    box_thresh=0.3,                  # Box threshold
    bin_thresh=0.2,                  # Binary threshold
    use_onnx=False,                  # ONNX runtime (opcjonalnie)
)
```

#### Dodatkowe metody

```python
async def extract_structured(image_path) -> dict        # Export pełnej struktury (export())
async def extract_tables(image_path) -> list[dict]      # Tabele (table_predictor)
async def extract_text_from_pdf(pdf_path) -> str | None # PDF bezpośrednio (DocumentFile.from_pdf)
async def extract_key_fields(image_path) -> dict | None # Key Information Extraction (KIE)
async def extract_layout(image_path) -> list[dict]      # Layout z reading_order
```

- **KIE Predictor**: opcjonalny predictor do ekstrakcji kluczowych pól (NIP, kwoty, daty)
- **Reading order**: bloki layoutu są sortowane po `reading_order` dla poprawnej kolejności odczytu

---

### 3.4 EasyOCREngine

| Cecha | Wartość |
|---|---|
| **Silnik** | EasyOCR |
| **Język** | polski + angielski |
| **GPU** | Tak (domyślnie) |
| **Decoder** | greedy (domyślnie) |

#### Konfiguracja

```python
EasyOCREngine(
    lang="pl",
    use_gpu=True,
    batch_size=4,
    workers=2,
    text_threshold=0.5,        # Próg detekcji tekstu
    link_threshold=0.3,        # Próg łączenia fragmentów
    low_text=0.3,              # Próg niskiej jakości tekstu
    min_size=5,                # Minimalny rozmiar tekstu
    canvas_size=2560,          # Maksymalny rozmiar canvas
    mag_ratio=1.0,             # Powiększenie obrazu
    decoder="greedy",          # greedy, beamsearch, wordbeamsearch
    paragraph_mode=True,       # Łączenie w paragrafy
    allowlist=None,            # Dozwolone znaki
    rotation_info=None,        # Auto-rotation (np. [90, 180, 270])
)
```

#### Dodatkowe metody

```python
async def extract_text_adaptive(image_path) -> str | None
    # Adaptacyjna ekstrakcja z dynamicznymi progami
    # Analizuje jakość obrazu (sharpness, contrast, brightness)
    # Dostosowuje text_threshold i low_text do jakości
```

#### Image Quality Assessment

```python
def _assess_image_quality(image_path) -> float:
    # Sharpness: Laplacian variance (0.5 wagi)
    # Contrast: stddev (0.3 wagi)
    # Brightness: odchylenie od 127 (0.2 wagi)
    # Zwraca 0.0–1.0
```

---

## 4. OCR Consensus — Głosowanie

**Plik:** `nexus_ai/pipeline/ocr_consensus.py`

### 4.1 Struktury danych

```python
class OCRFieldResult(Struct):
    value: str | None
    confidence: float
    source: str                    # Nazwa silnika

class OCRAmountResult(Struct):
    amount_gross: Any | None = None
    source: str = "unknown"

class OCRConsensusDecision(Struct, kw_only=True):
    accepted: OCRFieldResult | None     # Zaakceptowana wartość
    amount_gross: Any | None = None     # Zaakceptowana kwota
    confidence_conflict: bool           # Czy był konflikt?
    votes: list[OCRFieldResult]         # Wszystkie głosy
```

### 4.2 Pole consensus (`decide_field_consensus`)

```python
def decide_field_consensus(
    results: list[OCRFieldResult],
    *,
    min_confidence: float = 0.5,        # Minimalny próg ufności
    majority_threshold: int = 2,        # Wymagana większość (z 4)
) -> OCRConsensusDecision:
```

Algorytm:

1. **Filtruj**: tylko wyniki z `confidence >= min_confidence`
2. **Grupuj**: normalizuj wartości (strip, UPPER), zliczaj
3. **Decyzja**: jeśli wartość ma `>= majority_threshold` głosów → **OK**
4. **Konflikt**: jeśli nie ma większości → wybierz najwyższy `confidence`, ustaw `confidence_conflict=True`

### 4.3 Kwota consensus (`decide_amount_consensus`)

```python
def decide_amount_consensus(
    results: list[OCRAmountResult],
    *,
    tolerance: float = 0.01,           # Tolerancja dla kwot (1 grosz)
    majority_threshold: int = 2,
) -> OCRConsensusDecision:
```

Algorytm:

1. **Grupuj**: kwoty różniące się o `<= tolerance` są w tej samej grupie
2. **Wybierz**: grupa z największą liczbą głosów
3. **Zwróć**: pierwsza kwota z grupy + `source_str` z łączonych źródeł

### 4.4 Pipeline OCR

**Ujednolicona funkcja** `_run_ocr_pipeline` (zastępuje 2 osobne funkcje):

```python
async def _run_ocr_pipeline(
    file_path: Path,
    with_confidence: bool = False,     # True → zwraca confidences
    **opts,
) -> dict:
```

Parametry `**opts`:

| Parametr | Domyślnie | Opis |
|---|---|---|
| `use_tesseract` | env `NEXUS_OCR_ENGINES` | Włącz Tesseract |
| `use_paddle` | env `NEXUS_OCR_ENGINES` | Włącz PaddleOCR |
| `use_doctr` | env `NEXUS_OCR_ENGINES` | Włącz docTR |
| `use_easyocr` | env `NEXUS_OCR_ENGINES` | Włącz EasyOCR |
| `use_opencv_preprocessing` | True | Preprocessing OpenCV |
| `doctr_det_arch` | `db_resnet50` | Architektura detektora docTR |
| `doctr_reco_arch` | `parseq` | Architektura recognizera docTR |
| `invoice_id` | file_path.stem | ID faktury (dla InvoiceOCRHeap) |

### 4.5 PDF → Image Conversion

```python
def pdf_to_images(pdf_path: Path, dpi: int = 300) -> list[Path]:
    # Używa pypdfium2 do konwersji PDF → PNG
    # Output: {pdf_stem}_pages/page_001.png, page_002.png, ...
```

### 4.6 OpenCV Preprocessing

```python
def _apply_opencv(file_image, pil_pages, file_path):
    # OpenCVPreprocessor z OpenCV pipeline
    # Zapisuje do {pdf_stem}_cv/{filename}
    # Zwiększa jakość OCR o 5-15%
```

### 4.7 InvoiceOCRHeap

Pipeline używa `InvoiceOCRHeap` z `nexus_ai/core/mimalloc_bridge.py` do zarządzania pamięcią OCR:

```python
async with InvoiceOCRHeap(invoice_id, "ocr_pipeline"):
    # Alokacje OCR są izolowane w dedykowanym heap'ie
```

---

## 5. InvoiceParser — Parsowanie tekstu OCR

**Plik:** `nexus_ai/pipeline/parser.py`

### 5.1 ParsedInvoice

```python
class ParsedInvoice(Struct, kw_only=True):
    number: str | None = None
    nip: str | None = None
    amount_net: Decimal | None = None
    amount_gross: Decimal | None = None
    iban: str | None = None
    currency: str = "PLN"
```

### 5.2 Parser oparty na regex

```python
class InvoiceParser:
    # Wzorce
    re_nip = r"(?:NIP[:\\s]*)?(\\d{3}[-\\s]?\\d{3}[-\\s]?\\d{2}[-\\s]?\\d{2}|\\d{10})"
    re_iban = r"(?:PL)?\\s?(\\d{2}(?:\\s?\\d{4}){6})"
    re_currency = r"\\b(PLN|EUR|USD|zł|PLZ)\\b"

    # Słowa kluczowe
    gross_keywords = ["brutto", "razem", "suma", "total", "do zapłaty"]
    net_keywords = ["netto", "wartość netto"]
```

### 5.3 Parsowanie z bounding boxami

Parser obsługuje **bbox analysis** z PaddleOCR dla inteligentniejszej ekstrakcji:

```python
def parse_with_bbox(
    self,
    raw_text: str,
    blocks: list[dict],          # [{bbox, text, confidence}, ...]
    page_height: float | None = None,
) -> ParsedInvoice:
```

**Pozycjonowanie pól** (procent wysokości strony):

| Pozycja | Zakres | Typ pola |
|---|---|---|
| Header | 0–30% | NIP sprzedawcy, nagłówek |
| Body | 30–60% | Pozycje faktury |
| Footer (kwoty) | 60–80% | Amount gross/net, total |
| Stopka (IBAN) | 80–100% | IBAN, dane bankowe |

### 5.4 Active Learning

Parser integruje się z **Active Learning Engine** dla autokorekty:

```python
async def process_extraction(raw_text, active_learning_engine):
    # 1. Standardowy OCR/Regex
    # 2. Zapytanie do Active Learning o sugerowane korekty
    # 3. Jeśli użytkownik wcześniej poprawił podobne pole → AUTO_CORRECTED

async def check_for_anomalies(nip, current_amount, active_learning_engine):
    # 1. Pobierz ostatnie 10 faktur od tego NIP
    # 2. Oblicz średnią historyczną
    # 3. Jeśli kwota różni się >40% → anomalia
```

---

## 6. Porównanie silników OCR

| Silnik | RAM | Czas/stronę | Dokładność | Zalety | Wady |
|---|---|---|---|---|---|
| **Tesseract** | ~200 MB | 0.5–2s | ⭐⭐⭐ | Szybki, CLI, polski | Brak layout analysis |
| **PaddleOCR** | ~2 GB | 2–5s | ⭐⭐⭐⭐⭐ | PP-Structure, tabele, pieczęcie | Wysokie zużycie RAM |
| **docTR** | ~3 GB | 3–8s | ⭐⭐⭐⭐ | KIE, reading order, PDF | Wolny, dużo RAM |
| **EasyOCR** | ~1.5 GB | 1–3s | ⭐⭐⭐⭐ | Adaptacyjne progi, paragraph | Mniej dokładny niż Paddle |

Domyślnie włączone: **Tesseract + PaddleOCR** (konfigurowalne przez `NEXUS_OCR_ENGINES`).

---

## 7. Zarządzanie pamięcią AI

Każdy silnik OCR implementuje własne czyszczenie pamięci po użyciu:

```python
def _cleanup_model(model: Any, name: str = "model") -> None:
    if model is not None:
        try: del model
        except: pass
    gc.collect()
```

- **Tesseract**: brak (CLI subprocess)
- **PaddleOCR**: cleanup po każdej ekstrakcji (gc.collect)
- **docTR**: cleanup po każdej ekstrakcji (gc.collect)
- **EasyOCR**: cleanup po każdej ekstrakcji (gc.collect)

---

## 8. Konfiguracja środowiskowa

| Zmienna | Domyślnie | Opis |
|---|---|---|
| `NEXUS_OCR_ENGINES` | `tesseract,paddleocr` | Wybór silników (przecinek) |
| `NEXUS_PADDLE_GPU` | `true` | Użycie GPU dla PaddleOCR |
| `NEXUS_DOCTR_DET_ARCH` | `db_resnet50` | Architektura detektora docTR |
| `NEXUS_DOCTR_RECO_ARCH` | `parseq` | Architektura recognizera docTR |
| `NEXUS_TESSERACT_LANG` | `pol` | Język Tesseract |

---

## 9. Taski OCR przez Taskiq

<!-- UZUPEŁNIONE: dodano sekcję o asynchronicznych taskach OCR -->

Pipeline OCR jest uruchamiany asynchronicznie przez **Taskiq worker** (`api/tasks/ocr.py`):

### 9.1 process_invoice_ocr

```python
@broker.task(
    task_name="process_invoice_ocr",
    labels={"service": "api", "operation": "ocr", "criticality": "high"},
    timeout=300.0,
)
async def process_invoice_ocr(invoice_id: str, payload: dict | None = None, ...) -> None:
```

**Przepływ:**

```
invoice.extracted event → OCR Pipeline (Taskiq) → 4 silniki → consensus kwot
  → NIP/IBAN WhiteListService → ContextEnricher → SemanticGuard → Field Confidence
  → Publikuj invoice.extracted przez NATS → Trigger decision_evaluate
```

### 9.2 Walidacje po OCR

| Krok | Serwis | Opis |
|---|---|---|
| **NIP/IBAN** | `WhiteListService` | Weryfikacja przez Białą Listę MF |
| **Context** | `ContextEnricher` | Status VAT, PKD, zaufanie |
| **Semantic** | `SemanticGuard` | Anomalie (kwota vs historia) |
| **Field Confidence** | `RuleEngine` (Zen) | Reguły dla pól z niską ufnością |

### 9.3 process_large_attachment

```python
@broker.task(
    task_name="process_large_attachment",
    labels={"service": "api", "operation": "attachment", "criticality": "medium"},
    timeout=600.0,
)
async def process_large_attachment(attachment_id: str, payload: dict | None = None) -> None:
```

---

> **Zobacz również:**
> - [`MODULES.md`](MODULES.md) — OCR w kontekście logiki biznesowej, tabela porównawcza
> - [`FOUNDATION.md`](FOUNDATION.md) — AsyncBaseService, Result pattern
> - [`INSTALLER.md`](INSTALLER.md) — Instalacja zależności OCR (Tesseract, PaddlePaddle)
> - [`EVENTS.md`](EVENTS.md) — Event sourcing dla zdarzeń po OCR
> - [`SCRIPTS.md`](SCRIPTS.md) — Worker (Taskiq) uruchamiający taski
> - [`INFERENCE.md`](INFERENCE.md) — ModelManager, AdaptiveBatcher
