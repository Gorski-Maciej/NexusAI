# Architektura Poznawcza NexusAI

> **Wersja:** 2.2  
> **Data:** 2026-06-10  
> **Status:** Aktualna  
> **Zakres:** DecisionEngine (SQL rules) + RAG (FactsAggregator) + SOP (ProtocolLoader) + Cache (NexusCache)

---

## Spis treści

1. [Wprowadzenie — architektura poznawcza](#1-wprowadzenie--architektura-poznawcza)
2. [DecisionEngine — silnik decyzyjny oparty na SQL](#2-decisionengine--silnik-decyzyjny-oparty-na-sql)
3. [SOP — Standard Operating Procedures (ProtocolLoader)](#3-sop--standard-operating-procedures-protocolloader)
4. [RAG — Retrieval-Augmented Generation (FactsAggregator)](#4-rag--retrieval-augmented-generation-factsaggregator)
5. [RiskGuard — strażnik ryzyka](#5-riskguard--strażnik-ryzyka)
6. [SemanticGuard — wykrywacz anomalii semantycznych](#6-semanticguard--wykrywacz-anomalii-semantycznych)
7. [DecisionLogger — logowanie decyzji](#7-decisionlogger--logowanie-decyzji)
8. [Ekonomia poznawcza — koszty i wydajność](#8-ekonomia-poznawcza--koszty-i-wydajność)
9. [NexusCache w architekturze decyzyjnej](#9-nexuscache-w-architekturze-decyzyjnej)
10. [Diagram architektury](#10-diagram-architektury)
11. [Appendix A — Architektura v2.0 (historyczna)](#11-appendix-a--architektura-v20-historyczna)

---

## 1. Wprowadzenie — architektura poznawcza

Architektura poznawcza NexusAI została **uproszczona** względem pierwotnego projektu v2.0. Zamiast 7+ komponentów AI (Council of Agents, WorkflowPlanner, JambaStrategist, PLE Engine, BayesianThresholdLearner, TrustScoreCalculator, Rules SWAT Team), system używa **jednego silnika decyzyjnego opartego na SQL** (`DecisionEngine`) z **deterministycznymi regułami first-match-wins**.

| Warstwa | Analogia poznawcza | Komponent |
|---|---|---|
| **Decision** | Logika decyzyjna | `DecisionEngine` + DuckDB `decision_rules` |
| **SOP** | Procedury i regulamin | `ProtocolLoader` + `protocols.toml` |
| **RAG** | Notatki i dokumentacja | `FactsAggregator` + `FactSheet` |
| **Risk** | Instynkt samozachowawczy | `RiskGuard` + DuckDB `risk_thresholds` |
| **Semantic** | Węch do anomalii | `SemanticGuard` + sqlite-vec |
| **Audit** | Papierkowa robota | `DecisionLogger` + DuckDB `council_decisions` |
| **Cache** | Szybka pamięć podręczna | `NexusCache` (RAM L1 + SQLite L2) |

### Kluczowe zasady

1. **Determinizm zamiast AI** — decyzje podejmowane przez SQL first-match-wins, nie przez LLM
2. **Separacja SOP od kodu** — procedury decyzyjne w `protocols.toml`, nie w Pythonie
3. **RAG przed decyzją** — FactsAggregator dostarcza gotowy arkusz faktów
4. **Izolacja błędów** — awaria jednego źródła/zadania nie psuje reszty
5. **Offline-first** — wszystkie modele AI tylko dla OCR/embeddingów, nie dla decyzji
6. **Czyste zasoby** — `async close()` dla każdego serwisu z połączeniami HTTP/DB

---

## 2. DecisionEngine — silnik decyzyjny oparty na SQL

### 2.1. Rola

`DecisionEngine` (`core/decision_engine.py`) jest **jedynym komponentem decyzyjnym** w systemie. Zastępuje:
- Council of Agents (Alpha/Beta/Gamma) — logika walidacji → DuckDB rules
- JambaStrategist — decyzja strategiczna → matryca decyzyjna w DuckDB
- WorkflowPlanner — klasyfikacja simple/complex → `classify_invoice()`
- Rules SWAT Team — kaskada reguł → hierarchiczne reguły w DuckDB
- TrustScoreCalculator → `calculate_trust_score()`
- PLE Engine → historia decyzji w SQLite
- BayesianThresholdLearner → statystyki w DuckDB

### 2.2. Architektura

```
┌────────────────────────────────────────────────────────────┐
│                    DecisionEngine                          │
│                                                            │
│  classify_invoice() → "simple" / "complex"                │
│  calculate_trust_score() → 0.0–1.0 z 5 komponentów        │
│  decide() → DecisionVerdict (AUTO_POST/SUGGEST/ASK_USER)  │
│       └─ first-match-wins przez decision_rules w DuckDB   │
│                                                            │
│  Wspomagane przez:                                         │
│  - FactsAggregator (arkusz faktów)                        │
│  - RiskGuard (progi ufności per pole)                     │
│  - SemanticGuard (anomalie semantyczne)                   │
│  - DecisionLogger (audyt)                                 │
└────────────────────────────────────────────────────────────┘
```

### 2.3. Reguły decyzyjne (DuckDB `decision_rules`)

Reguły przechowywane w DuckDB z first-match-wins według priorytetu:

| Priorytet | Warunek | Decyzja | Confidence |
|---|---|---|---|
| 10 | Znany kontrahent, ≥10 faktur, trust ≥0.85, kwota ≤5k, OCR ≥0.92 | `AUTO_POST` | 0.95 |
| 20 | Znany kontrahent, ≥3 faktury, trust ≥0.80, kwota ≤3k, OCR ≥0.90 | `AUTO_POST` | 0.90 |
| 30 | Znany kontrahent, kwota ≤10k, OCR ≥0.85 | `SUGGEST` | 0.80 |
| 40 | Nowy kontrahent, kwota ≤5k, OCR ≥0.90 | `SUGGEST` | 0.75 |
| 50 | Kwota ≤50k, OCR ≥0.80 | `ASK_USER` | 0.60 |
| 100 | Kwota ≥50k | `BLOCK` | 0.40 |
| 999 | Zawsze (fallback) | `ASK_USER` | 0.50 |

### 2.4. `classify_invoice()` — klasyfikacja simple/complex

Funkcja zastępuje WorkflowPlanner (LittleLamb 0.3B):

```python
def classify_invoice(invoice_data, vendor_profile=None) -> str:
    """Classify as simple or complex using SQL-like conditions."""
    if amount <= 5000 and vendor_known and vendor_count >= 3 and ocr_conf >= 0.85:
        return "simple"
    return "complex"
```

- **Simple:** niska kwota, znany kontrahent (≥3 faktury), wysoki OCR confidence
- **Complex:** wysoka kwota, nowy kontrahent lub niski OCR

### 2.5. `calculate_trust_score()` — 5-składnikowy trust score

```
trust = (ocr × 0.30) + (vendor_score × 0.25) + (data_consistency × 0.20) + (context × 0.10) + (risk × 0.15)
```

### 2.6. `_match_condition()` — dopasowanie warunków

Obsługuje operatory:
- `field`: dokładne dopasowanie
- `field__gte`: ≥ (greater than or equal)
- `field__lte`: ≤ (less than or equal)
- `field__in`: w liście

Pusta kondycja (`{}`) pasuje zawsze — fallback.

### 2.7. Zarządzanie regułami

Reguły są seedowane automatycznie przy pierwszym uruchomieniu. Mogą być modyfikowane przez API. Reguły mają `valid_from`/`valid_to` — można je czasowo wyłączyć bez usuwania.

---

## 3. SOP — Standard Operating Procedures (ProtocolLoader)

### 3.1. Filozofia

ProtocolLoader ładuje konfigurację `protocols.toml` z procedurami operacyjnymi. W przeciwieństwie do v2.0, protokoły te dotyczą głównie reguł biznesowych i progów, nie wieloagentowych matryc głosowania.

### 3.2. Plik `protocols.toml`

Zlokalizowany w `nexus_ai/config/protocols.toml`. Zawiera sekcje:

| Sekcja | Opis |
|---|---|
| `[metadata]` | Wersja, opis, data modyfikacji |
| `[schema.output_formats]` | Definicje typów JSON |
| `[protocols.validation]` | Konfiguracja walidacji |
| `[protocols.decision]` | Konfiguracja DecisionEngine |
| `[thresholds]` | Progi decyzyjne, wagi |
| `[emergency]` | Protokoły awaryjne |

### 3.3. ProtocolLoader

Klasa `ProtocolLoader` (`nexus_ai/core/protocol_loader.py`):

- **Lazy loading** — plik ładowany przy pierwszym dostępie
- **Singleton** — przez `get_protocol_loader()`
- **Kropkowy dostęp** — `loader.get_protocol("validation")`
- **Protokoły awaryjne** — `loader.get_emergency_protocol("timeout")`
---

## 4. RAG — Retrieval-Augmented Generation (FactsAggregator)

### 4.1. Filozofia

Przed każdą decyzją, `FactsAggregator` zbiera dane ze wszystkich źródeł w systemie i pakuje je w jeden, ustrukturyzowany **arkusz faktów** (`FactSheet`). Dane są wykorzystywane przez `DecisionEngine.decide()` oraz `RiskGuard` i `SemanticGuard`.

### 4.2. Źródła danych

FactsAggregator odpytuje **4 źródła równolegle** (przez `asyncio.create_task`):

| # | Źródło | Typ | Dane |
|---|---|---|---|
| 1 | **SQLite** | OLTP | Kontrahent (Contractor), faktury (Invoice), wzorce korekt (ActiveLearningPattern) |
| 2 | **DuckDB** | OLAP | Trust score trend, reguły podatkowe (RuleStore), vendor intelligence (VendorAnalyst) |
| 3 | **sqlite-vec** | Wektorowa | Semantycznie podobne faktury (embedding search przez VectorStore) |
| 4 | **TigerBeetle** | Secure Ledger | Salda kont księgowych, łączny obrót, ostatnie transfery |

### 4.3. FactSheet

Struktura danych wyjściowych (`@dataclass(slots=True)`) zawiera pola z wszystkich źródeł — metoda `to_prompt_section()` generuje sekcję `=== ARKUSZ FAKTÓW ===`, a `build_few_shot_examples()` generuje dynamiczne przykłady z historią kontrahenta.

### 4.4. Cache w FactSheet — NexusCache

| Cache | Klucz | TTL | Opis |
|---|---|---|---|
| `_few_shot_cache` | `few_shot:{data_hash}:{max_examples}` | 300s | Gotowe sekcje few-shot — NexusCache (L1 RAM + L2 SQLite) |
| `_enrich_cache` | `enrich:{invoice_id}` | 300s | Wzbogacone podobne faktury — NexusCache |

### 4.5. Izolacja błędów

Każde źródło danych uruchamiane jako osobny `asyncio.Task` — awaria jednego nie wpływa na pozostałe.

---

## 5. RiskGuard — strażnik ryzyka

### 5.1. Rola

`RiskGuard` (`nexus_ai/services/risk_guard.py`) definiuje **progi ufności per pole faktury**, zależne od formy opodatkowania i typu wydatku. Reguły przechowywane w DuckDB (`risk_thresholds`), first-match-wins według priorytetu.

### 5.2. Przykładowe reguły

| Forma opodatkowania | Pole | Wymagane confidence | Akcja poniżej |
|---|---|---|---|
| CIT_STANDARD | `vat_rate` | 0.98 | `BLOCK_AND_ALERT` |
| CIT_STANDARD | `total_net` | 0.95 | `BLOCK_AND_ALERT` |
| CIT_ESTONIAN | `vat_rate` | 0.95 | `BLOCK_AND_ALERT` |
| LINEAR | (dowolne) | 0.85 | `TRIAGE_QUEUE` |
| LUMP_SUM | `total_net` | 0.60 | `TRIAGE_QUEUE` |
| LUMP_SUM | `vat_rate` | 0.95 | `TRIAGE_QUEUE` |

---

## 6. SemanticGuard — wykrywacz anomalii semantycznych

### 6.1. Rola

`SemanticGuard` (`nexus_ai/services/semantic_guard.py`) wykrywa anomalie semantyczne przez porównanie embeddingów faktury z historią kontrahenta (sqlite-vec).

### 6.2. Mechanizm

1. Generuje embedding tekstu faktury przez `EmbeddingService`
2. Szuka najbliższych sąsiadów w sqlite-vec dla tego kontrahenta
3. Oblicza `anomaly_score = średnia odległość kosinusowa`
4. Sprawdza reguły w `anomaly_rules` (DuckDB)

---

## 7. DecisionLogger — logowanie decyzji

### 7.1. Rola

`DecisionLogger` (`nexus_ai/services/decision_logger.py`) loguje każdą decyzję do DuckDB z pełnym kontekstem, umożliwiając audyt i analizę trendów.

### 7.2. Tabele

| Tabela | Opis |
|---|---|
| `council_decisions` | Główna tabela decyzji (decision, trust_score, components) |
| `trust_score_cache` | Cache trust score per (contractor_nip, category) |
| `council_decisions_meta` | Metadane decyzji |

### 7.3. Kluczowe funkcje

- `log_decision()` — zapis decyzji
- `get_trust_score_trend(nip, days=30)` — analiza trendu
- `get_decisions_for_invoice(invoice_id)` — decyzje dla faktury
- `get_recent_global_decisions()` — ostatnie decyzje globalne (dla few-shot)

---

## 8. Ekonomia poznawcza — koszty i wydajność

### 8.1. Decision timing (DecisionEngine)

| Operacja | Typowy czas | Uwagi |
|---|---|---|
| `classify_invoice()` | **<1ms** | Tylko porównania SQL |
| `calculate_trust_score()` | **<1ms** | Obliczenia w pamięci |
| `decide()` (first-match-wins) | **<5ms** | Odczyt reguł z DuckDB + dopasowanie |
| `_get_active_rules()` | **<5ms** | SELECT z DuckDB |
| **Całkowity czas decyzji** | **~10ms** | Bez RAG, bez modeli AI |

| Operacja | Typowy czas | Uwagi |
|---|---|---|
| `FactSheet.build()` (RAG) | **~100–300ms** | 7+ zapytań równolegle |
| `build_few_shot_examples()` | **<10ms** | Cache HIT → msgspec deserializacja |
| `RiskGuard.evaluate()` | **<10ms** | First-match-wins w DuckDB |
| `SemanticGuard.evaluate()` | **~50–200ms** | Embedding + sqlite-vec search |

### 8.2. Szybka ścieżka decyzyjna

Dla typowej faktury:
```
FactsAggregator (0.1s) → classify_invoice (<1ms) → calculate_trust_score (<1ms)
→ decide() (<5ms) → RiskGuard (<10ms) → DecisionLogger (<5ms)
= ~0.12s total  (bez modeli AI)
```

### 8.3. Memory usage

| Komponent | RAM |
|---|---|
| DecisionEngine + rules (DuckDB) | ~20 MB |
| FactsAggregator (cache, sqlite-vec) | ~50 MB |
| RiskGuard + SemanticGuard | ~10 MB |
| **Baseline (bez modeli AI)** | **~200 MB** |
| + Model OCR (LightOnOCR-1B) | +~1.0 GB |
| + VisionAgent (Phi-3-mini) | +~2.2 GB |

---

## 9. NexusCache w architekturze decyzyjnej

`NexusCache` jest używany przez komponenty decyzyjne:

| Komponent | Klucz cache | TTL | Opis |
|---|---|---|---|
| `FactsAggregator._enrich_cache` | `enrich:{invoice_id}` | 300s | Wzbogacone podobne faktury |
| `FactSheet._few_shot_cache` | `few_shot:{hash}:{max}` | 300s | Sekcje few-shot |
| `WhiteListService` | `whitelist:{nip}:{account}` | 3600s | Wyniki Białej Listy MF |
| `CurrencyConverter` | `fx_rate:{currency}:{date}` | 300s | Kursy walut NBP |

---

## 10. Diagram architektury

```
┌═══════════════════════════════════════════════════════════════════════════┐
║                       NEXUSAI — ARCHITEKTURA POZNAWCZA                   ║
║                               v2.2 (2026)                               ║
└═══════════════════════════════════════════════════════════════════════════┘

┌──────────────────────────────────────────────────────────────────────────┐
│                    WARSTWA DECYZYJNA                                     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐      │
│  │                    DecisionEngine                              │      │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │      │
│  │  │classify      │  │calculate     │  │ decide()           │   │      │
│  │  │Invoice()     │  │TrustScore()  │  │ first-match-wins   │   │      │
│  │  │simple/complex│  │5 składników  │  │ decision_rules     │   │      │
│  │  └──────────────┘  └──────────────┘  └────────────────────┘   │      │
│  └────────────────────────────────────────────────────────────────┘      │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐      │
│  │              RiskGuard + SemanticGuard                         │      │
│  │  (DuckDB risk_thresholds + sqlite-vec anomaly detection)       │      │
│  └────────────────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                      WARSTWA RAG                                        │
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐               │
│  │ FactsAggreg. │    │  DecisionLog │    │ NexusCache   │               │
│  │ RAG Layer    │    │  (DuckDB)    │    │ L1 RAM + L2  │               │
│  │              │    │  council_de- │    │ SQLite       │               │
│  │ ┌──────┐     │    │  cisions     │    │ get_sync/set │               │
│  │ │SQLite│ ◀───┤    │  trust_score │    │ async get/set│               │
│  │ │DuckDB│ ◀───┤    │  _cache      │    └──────────────┘               │
│  │ │sqlite│ ◀───┤    └──────────────┘                                   │
│  │ │-vec  │ ◀───┤                                                      │
│  │ │Tiger │ ◀───┤                                                      │
│  │ │Beetle│ ◀───┤                                                      │
│  │ └──────┘     │                                                      │
│  └──────────────┘                                                      │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                      WARSTWA UCZENIA I AUDYTU                            │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐       │
│  │  DecisionLogger  │  │  SemanticGuard   │  │  RiskGuard       │       │
│  │  (DuckDB)        │  │  (sqlite-vec)    │  │  (DuckDB)        │       │
│  │  council_decisions│  │  anomaly_rules   │  │  risk_thresholds │       │
│  │  trust_score_cache│  │  vendor_invoices │  │                  │       │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘       │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐                              │
│  │  ProtocolLoader  │  │  DecisionEngine  │                              │
│  │  (TOML)          │  │  (DuckDB rules)  │                              │
│  └──────────────────┘  └──────────────────┘                              │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 11. Appendix A — Architektura v2.0 (historyczna)

Pierwotny projekt v2.0 zakładał rozbudowaną architekturę wieloagentową, która została uproszczona w trakcie implementacji:

| Komponent v2.0 | Model | Status | Zastąpiony przez |
|---|---|---|---|
| **Council of Agents** | Alpha (LFM2.5), Beta (Qwen3), Gamma (LittleLamb) | ❌ Zastąpiony | `DecisionEngine.decide()` + DuckDB `decision_rules` |
| **WorkflowPlanner** | LittleLamb 0.3B | ❌ Zastąpiony | `classify_invoice()` |
| **JambaStrategist** | Jamba 3B | ❌ Zastąpiony | `DecisionEngine.decide()` |
| **Rules SWAT Team** | LFM2.5, Granite, LittleLamb, Fin-RWKV | ❌ Zastąpiony | Hierarchiczne reguły DuckDB |
| **TrustScoreCalculator** | — | ❌ Zastąpiony | `calculate_trust_score()` |
| **PLE Engine** | — | ❌ Zastąpiony | `DecisionLogger.get_trust_score_trend()` |
| **BayesianThresholdLearner** | — | ❌ Zastąpiony | Statystyki w DuckDB |
| **AgentOrchestrator** | — | ⚠️ DEPRECATED | `services/council_session.py`, `services/autopilot.py` |

### Dlaczego uproszczenie?

- **Determinizm zamiast losowości** — reguły SQL dają powtarzalne wyniki, LLM nie
- **Koszt** — 7 modeli AI wymaga ~10 GB RAM, DecisionEngine + RAG <200 MB baseline
- **Szybkość** — decyzja w <10ms vs ~7-18s z LLM
- **Testowalność** — reguły SQL można testować jednostkowo, LLM wymaga kosztownych testów integracyjnych
- **Konserwacja** — zmiana reguły to INSERT do DuckDB, nie fine-tuning modelu

### Gdzie zostały modele AI?

Modele AI (GGUF) są nadal używane, ale **tylko do zadań niefinansowych**:
- **LightOnOCR-1B** → OCR faktur (pipeline OCR)
- **Phi-3-mini 3.8B** → VisionAgent (analiza layoutu, wykrywanie anomalii wizualnych)
- **llama-cpp-python embedding** → embeddingi dla FactsAggregator (sqlite-vec)

---

### Appendix F — Cleanup lifecycle

Każdy serwis trzymający zewnętrzne zasoby (HTTP, DB) implementuje `async def close()`:

| Serwis | Zasób | Metoda |
|---|---|---|
| `WhiteListService` | `CachedHttpClient` (httpx + hishel) | `await self._http.close()` |
| `CurrencyConverter` | `DuckDBPyConnection` | `self._conn.close()` |
| `ContextEnricher` | `WhiteListService` + DuckDB | `await self._white_list.close()` + `self._conn.close()` |
| `CachedHttpClient` | `httpx.AsyncClient` (connection pool) | `await self._client.aclose()` |

Łańcuch zamykania: `Service.close()` → `CachedHttpClient.close()` → `httpx.AsyncClient.aclose()`. W długo działających procesach (worker, serwer) zapobiega wyciekom gniazd i połączeń.
