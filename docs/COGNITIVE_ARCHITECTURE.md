# Architektura Poznawcza NexusAI

> **Wersja:** 2.0  
> **Data:** 2026-06-09  
> **Status:** Aktualna  
> **Zakres:** SOP (Standard Operating Procedures) + RAG (Retrieval-Augmented Generation) + Workflow (AgentOrchestrator)

---

## Spis treści

1. [Wprowadzenie — architektura poznawcza](#1-wprowadzenie--architektura-poznawcza)
2. [SOP — Standard Operating Procedures (ProtocolLoader)](#2-sop--standard-operating-procedures-protocolloader)
3. [RAG — Retrieval-Augmented Generation (FactsAggregator)](#3-rag--retrieval-augmented-generation-factsaggregator)
4. [Workflow — AgentOrchestrator](#4-workflow--agentorchestrator)
5. [WorkflowPlanner — planowanie przepływu pracy](#5-workflowplanner--planowanie-przepływu-pracy)
6. [Council of Agents — trójwarstwowa walidacja](#6-council-of-agents--trójwarstwowa-walidacja)
7. [TrustScoreCalculator — kalkulacja zaufania](#7-trustscorecalculator--kalkulacja-zaufania)
8. [JambaStrategist — strategiczne wnioskowanie](#8-jambastrategist--strategiczne-wnioskowanie)
9. [Perpetual Learning Engine (PLE) — trójwarstwowa pamięć](#9-perpetual-learning-engine-ple--trójwarstwowa-pamięć)
10. [BayesianThresholdLearner — Bayesowskie adaptacyjne progi](#10-bayesianthresholdlearner--bayesowskie-adaptacyjne-progi)
11. [RiskGuard — strażnik ryzyka](#11-riskguard--strażnik-ryzyka)
12. [SemanticGuard — wykrywacz anomalii semantycznych](#12-semanticguard--wykrywacz-anomalii-semantycznych)
13. [DecisionLogger — logowanie decyzji](#13-decisionlogger--logowanie-decyzji)
14. [Rules SWAT Team — kaskada reguł biznesowych](#14-rules-swat-team--kaskada-reguł-biznesowych)
15. [Ekonomia poznawcza — koszty i wydajność](#15-ekonomia-poznawcza--koszty-i-wydajność)
16. [Przepływ decyzyjny — sekwencja krok po kroku](#16-przepływ-decyzyjny--sekwencja-krok-po-kroku)
17. [Dynamiczny few-shot learning](#17-dynamiczny-few-shot-learning)
18. [Diagram architektury](#18-diagram-architektury)

---

## 1. Wprowadzenie — architektura poznawcza

Architektura poznawcza NexusAI jest wzorowana na ludzkim procesie decyzyjnym. Zamiast polegać na jednym modelu AI, system używa **wielu wyspecjalizowanych warstw**, które współpracują ze sobą na zasadzie:

| Warstwa | Analogia poznawcza | Komponent |
|---|---|---|
| **SOP** | Procedury i regulamin | `ProtocolLoader` + `protocols.toml` |
| **RAG** | Notatki i dokumentacja | `FactsAggregator` + `FactSheet` |
| **WorkflowPlanner** | Planowanie działania | `WorkflowPlanner` + LittleLamb 0.3B |
| **Council of Agents** | Zespół ekspertów | Alpha/Beta/Gamma (LFM2.5, Qwen3, LittleLamb) |
| **TrustScore** | Intuicja i doświadczenie | `TrustScoreCalculator` |
| **JambaStrategist** | Strategiczna decyzja | `JambaStrategist` + Jamba 3B |
| **PLE** | Pamięć długo- i krótkoterminowa | `PLEEngine` (STM/LTM/FM) |
| **BayesianThreshold** | Uczenie się z doświadczenia | `BayesianThresholdLearner` |
| **RiskGuard** | Instynkt samozachowawczy | `RiskGuard` |
| **SemanticGuard** | Węch do anomalii | `SemanticGuard` + sqlite-vec |

### Kluczowe zasady

1. **Zero zaufania do pojedynczego modelu** — każda decyzja przechodzi przez wiele niezależnych warstw
2. **Separacja SOP od kodu** — procedury decyzyjne w `protocols.toml`, nie w Pythonie
3. **RAG przed decyzją** — model nigdy nie szuka danych samodzielnie; dostaje gotowy arkusz faktów
4. **Uczenie się bez zapominania** — PLE + BayesianThreshold zapewniają ciągłą adaptację
5. **Izolacja błędów** — awaria jednego źródła/zadania nie psuje reszty
6. **Offline-first** — wszystkie modele działają lokalnie, bez zależności od API

---

## 2. SOP — Standard Operating Procedures (ProtocolLoader)

### 2.1. Filozofia

Zamiast pozwalać modelom AI na samodzielne wymyślanie strategii, NexusAI definiuje **sztywne protokoły postępowania** w scentralizowanym pliku `protocols.toml`. Protokoły te określają dokładnie, co model ma robić w każdej sytuacji, jakie są progi decyzyjne, matryce głosowania i procedury awaryjne.

### 2.2. Plik `protocols.toml`

Zlokalizowany w `nexus_ai/config/protocols.toml`. Zawiera sekcje:

| Sekcja | Opis |
|---|---|
| `[metadata]` | Wersja, opis, data modyfikacji |
| `[schema.output_formats]` | Definicje typów JSON dla wyjść modeli |
| `[protocols.workflow_planner]` | Protokoły dla WorkflowPlanner |
| `[protocols.validation]` | Protokoły dla Rady Agentów (Alpha/Beta/Gamma) |
| `[protocols.validation.alpha]` | Warstwa kontekstowa |
| `[protocols.validation.beta]` | Warstwa precyzji |
| `[protocols.validation.gamma]` | Warstwa anomalii |
| `[matrices.validation_verdict]` | **Matryca 8 kombinacji głosów** |
| `[protocols.rules]` | Rules SWAT Team (4 poziomy) |
| `[protocols.decision]` | Protokoły dla JambaStrategist |
| `[thresholds]` | Progi decyzyjne, wagi, adaptacje |
| `[emergency]` | Protokoły awaryjne |

### 2.3. ProtocolLoader

Klasa `ProtocolLoader` (`nexus_ai/core/protocol_loader.py`):

- **Lazy loading** — plik ładowany dopiero przy pierwszym dostępie
- **Singleton** — globalna instancja przez `get_protocol_loader()`
- **Kropkowy dostęp** — `loader.get_protocol("validation.alpha")`
- **Matryce decyzyjne** — `loader.get_decision_matrix("validation_verdict")`
- **Progi adaptacyjne** — `loader.get_thresholds_with_adaptations(category, vendor_known, amount_gross)`
- **Protokoły awaryjne** — `loader.get_emergency_protocol("model_timeout")`
- **Budowanie promptów** — `loader.build_system_prompt("validation.alpha")` generuje gotowy prompt z SOP

### 2.4. Matryca decyzyjna — 8 kombinacji

Deterministyczna matryca mapująca kombinację 3 głosów (Alpha, Beta, Gamma) na konkretną akcję. Model nie ma prawa samodzielnie decydować — tylko głosować. Python (`QualityValidatorAgent`) mapuje głosy na akcję.

| Kombinacja | Alpha | Beta | Gamma | Akcja | Poziom |
|---|---|---|---|---|---|
| `FULL_APPROVE` | ✅ | ✅ | ✅ | `AUTO_POST` | LEVEL_1_AUTO |
| `CONTEXT_ANOMALY_APPROVE` | ✅ | ❌ | ✅ | `SUGGEST` | LEVEL_2_REVIEW |
| `CONTEXT_PRECISION_APPROVE` | ✅ | ✅ | ❌ | `SUGGEST` | LEVEL_2_REVIEW |
| `CONTEXT_ONLY` | ✅ | ❌ | ❌ | `ASK_USER` | LEVEL_3_ESCALATE |
| `PRECISION_ANOMALY_APPROVE` | ❌ | ✅ | ✅ | `ASK_USER` | LEVEL_3_ESCALATE |
| `ANOMALY_ONLY` | ❌ | ❌ | ✅ | `ASK_USER` | LEVEL_3_ESCALATE |
| `PRECISION_VETO` | ❌ | ✅ | ❌ | `BLOCK` | LEVEL_4_BLOCK |
| `FULL_REJECT` | ❌ | ❌ | ❌ | `BLOCK` | LEVEL_4_BLOCK |

### 2.5. Fast-path

Gdy Alpha (warstwa kontekstowa) zwróci `APPROVE` z confidence ≥ 0.92, system pomija warstwy Beta i Gamma i zwraca `AUTO_POST` natychmiast. To oszczędza ~70% czasu inferencji dla typowych faktur.

### 2.6. Progi adaptacyjne

W sekcji `[thresholds]` zdefiniowane są:

- **Wagi komponentów** — `ai_confidence: 0.30`, `vendor_reliability: 0.25`, `data_consistency: 0.20`, `context_trust: 0.10`, `risk_guard: 0.15`
- **Adaptacje kategorii** — kategorie cykliczne (paliwo, czynsz) mają niższy próg; problematyczne (IT, doradztwo) wyższy
- **Adaptacje kontrahenta** — znani kontrahenci mają niższy próg; nowi wyższy
- **Adaptacje kwoty** — niskie kwoty mają niższy próg; wysokie wyższy

### 2.7. Protokoły awaryjne

| Protokół | Warunek | Akcja |
|---|---|---|
| `model_timeout` | Model nie odpowiedział w czasie | `ASYNC_FALLBACK` — statyczna matryca |
| `model_error` | Model zwrócił błąd JSON | `PARSE_FALLBACK` — regex fallback |
| `model_crash` | Wielokrotne błędy | `SAFE_DEFAULT` — ESCALATE |
| `unknown_voting_pattern` | Nieznana kombinacja głosów | `SAFE_ESCALATE` — ASK_USER |
| `workflow_timeout` | WorkflowPlanner timeout | `FULL_WORKFLOW` — pełny zestaw agentów |
| `validation_layer_timeout` | Warstwa walidacji nie odpowiada | `SKIP_LAYER` — pomiń i kontynuuj z ERROR |

---

## 3. RAG — Retrieval-Augmented Generation (FactsAggregator)

### 3.1. Filozofia

Przed każdą decyzją agentów, `FactsAggregator` zbiera dane ze wszystkich źródeł w systemie i pakuje je w jeden, ustrukturyzowany **arkusz faktów** (`FactSheet`), który jest dołączany do promptu modelu decyzyjnego. Model **nigdy nie szuka danych samodzielnie** — dostaje je gotowe, w przetworzonej formie.

### 3.2. Źródła danych

FactsAggregator odpytuje **4 źródła równolegle** (przez `asyncio.create_task`):

| # | Źródło | Typ | Dane |
|---|---|---|---|
| 1 | **SQLite** | OLTP | Kontrahent (Contractor), ostatnie faktury (Invoice), wzorce korekt (ActiveLearningPattern) |
| 2 | **DuckDB** | OLAP | Trust score trend, aktywne reguły podatkowe (RuleStore), vendor intelligence (VendorAnalyst) |
| 3 | **sqlite-vec** | Wektorowa | Semantycznie podobne faktury (embedding search przez VectorStore) |
| 4 | **TigerBeetle** | Secure Ledger | Salda kont księgowych, łączny obrót, ostatnie transfery |

### 3.3. FactSheet

Struktura danych wyjściowych (`@dataclass(slots=True)`):

```python
@dataclass(slots=True)
class FactSheet:
    # ── SQLite (OLTP) ──
    invoice_id: str
    contractor_nip: str
    contractor_name: str
    amount_net: float
    amount_gross: float
    category: str
    issue_date: str
    contractor_known: bool
    contractor_invoice_count: int
    contractor_trust_score: float
    contractor_vat_status: str
    recent_invoices: list[dict]
    user_correction_patterns: list[dict]

    # ── DuckDB (OLAP) ──
    trust_score_trend: dict
    active_tax_rules: list[dict]
    vendor_intelligence: str
    correction_stats: dict

    # ── sqlite-vec ──
    similar_invoices: list[dict]

    # ── TigerBeetle ──
    ledger_available: bool
    ledger_accounts: dict[str, float]
    ledger_total_turnover: float
    ledger_recent_transfers: list[dict]

    # ── Metadane ──
    sources_available: dict[str, bool]
    build_duration_ms: float
```

### 3.4. Metody FactSheet

| Metoda | Opis |
|---|---|
| `to_prompt_section()` | Generuje sekcję `=== ARKUSZ FAKTÓW (FactsAggregator) ===` do promptu modelu |
| `to_dict()` | Konwertuje na słownik JSON dla logowania i audytu |
| `build_few_shot_examples(max_examples=3)` | Buduje dynamiczne przykłady few-shot z historycznych decyzji |

### 3.5. Izolacja błędów

Każde źródło danych jest uruchamiane jako osobny `asyncio.Task`. Jeśli któreś źródło rzuci wyjątkiem, tylko to źródło traci dane — pozostałe działają normalnie. Logowanie przez `logger.warning()`.

### 3.6. Parallel execution

```python
# Wszystkie źródła uruchomione równolegle
tasks[\"sqlite_contractor\"] = asyncio.create_task(...)
tasks[\"sqlite_recent\"] = asyncio.create_task(...)
tasks[\"duckdb_trend\"] = asyncio.create_task(...)
tasks[\"vector_similar\"] = asyncio.create_task(...)
tasks[\"tigerbeetle\"] = asyncio.create_task(...)

# Zbieranie wyników z izolacją błędów
for name, task in tasks.items():
    try:
        result = await task
        # mapowanie na FactSheet
    except Exception as exc:
        logger.warning(\"[FactsAggregator] task %s failed: %s\", name, exc)
```

### 3.7. Wzbogacanie similar_invoices

`_enrich_similar_with_decision()` pobiera dla każdej podobnej faktury z sqlite-vec jej rzeczywisty **status** z SQLite (Invoice). Dzięki temu `build_few_shot_examples()` może pokazać prawdziwe decyzje użytkownika, a nie "dane niedostępne".

### 3.8. TigerBeetle w RAG

`_fetch_ledger_history()`:
- Używa `TigerBeetleMapper` do konwersji polskich symboli księgowych (401-01, 202, 221-01) na uint128 ID
- Odpytuje `get_account_credits_posted()` dla każdego konta
- Konwertuje grosze na PLN (/100)
- Zwraca salda kont, łączny obrót i ostatnie transfery

---

## 4. Workflow — AgentOrchestrator

### 4.1. Rola

`AgentOrchestrator` (`nexus_ai/services/agent_orchestrator.py`) jest **centralnym mózgiem** systemu — jedynym punktem kontaktu z użytkownikiem i nadrzędnym koordynatorem wszystkich agentów wykonawczych.

### 4.2. Komponenty

```python
class AgentOrchestrator:
    def __init__(
        self,
        workflow_planner: WorkflowPlanner,       # planowanie przepływu
        trust_calculator: TrustScoreCalculator,    # kalkulacja zaufania
        jamba_strategist: JambaStrategist,        # strategiczna decyzja
        facts_aggregator: FactsAggregator | None = None,  # RAG
        decision_logger: DecisionLogger | None = None,    # logowanie
        ple_engine: PLEEngine | None = None,       # Perpetual Learning
        bayesian_learner: Any | None = None,       # Bayesowskie progi
    )
```

### 4.3. Główna pętla `orchestrate()`

Sekwencja decyzyjna:

```
Krok 0: FactsAggregator.build(invoice_data) → FactSheet (RAG)
            ↓
Krok 1: WorkflowPlanner.plan(invoice_data, fact_sheet_text) → plan
            ↓
Krok 1b: FactSheet.build_few_shot_examples() → few_shot_examples
            ↓
Krok 2: JambaStrategist.analyze(fact_sheet_text, few_shot_examples) → jamba_result
            ↓
Krok 2b: BayesianThresholdLearner.get_thresholds() → adaptacyjne progi
            ↓
Krok 2c: Bayesowski override: AUTO_POST → SUGGEST/ASK_USER jeśli confidence < próg
            ↓
Krok 3: PLE.record_decision() → zapis do STM/LTM/FM
            ↓
Krok 4: BayesianThresholdLearner.record_auto_decision() → aktualizacja rozkładu
            ↓
Krok 5: Zwróć OrchestratorDecision
```

### 4.4. OrchestratorDecision

```python
@dataclass(slots=True)
class OrchestratorDecision:
    decision: str        # AUTO_POST | SUGGEST | ASK_USER | BLOCK | ESCALATE
    confidence: float    # 0.0 – 1.0
    reasoning: str
    workflow_plan: list[str]
    council_verdict: CouncilVerdict | None
    trust_components: dict[str, float]
    adapted_thresholds: dict[str, float]
    ple_pattern: dict[str, Any] | None
    risk_verdict: dict[str, Any] | None
    strategy_summary: str
    jamba_analysis: str
    granite_context: dict[str, Any]
```

---

## 5. WorkflowPlanner — planowanie przepływu pracy

### 5.1. Rola

`WorkflowPlanner` decyduje, które agenty uruchomić dla danej faktury — czy wystarczy szybka ścieżka (simple), czy potrzebny pełny zestaw (complex).

### 5.2. Model

LittleLamb 0.3B Tool-Calling — mały, szybki model specjalizujący się w klasyfikacji binarnej.

### 5.3. Reguły klasyfikacji

| Typ | Warunek | Agenci |
|---|---|---|
| **Simple** | Kwota brutto ≤ 5000 PLN ORAZ kontrahent znany (≥3 faktury) ORAZ OCR confidence ≥ 0.85 | Tylko `EKSTRAKCJA` + `WALIDACJA` |
| **Complex** | Wysoka kwota LUB nowy kontrahent LUB niski OCR confidence | Pełny: `EKSTRAKCJA` + `WALIDACJA` + `ANALITYKA` + `DECYZJA` |

### 5.4. RAG w planerze

WorkflowPlanner otrzymuje `fact_sheet_text` z FactsAggregator, co pozwala mu podejmować lepsze decyzje na podstawie pełniejszego kontekstu (np. trust score trend, active rules).

### 5.5. Fallback

Timeout → pełny zestaw agentów (safe default).

---

## 6. Council of Agents — trójwarstwowa walidacja

### 6.1. Skład

| Agent | Model | Rozmiar | RAM | Funkcja |
|---|---|---|---|---|
| **Alpha** | LFM2.5 1.2B | ~780 MB | ~1.0 GB | Szybki decydent — ocena kontekstowa |
| **Beta** | Qwen3 0.6B | ~430 MB | ~0.9 GB | Precyzyjny walidator — NIP, kwoty, daty |
| **Gamma** | LittleLamb 0.3B TC | ~250 MB | ~0.5 GB | Detektor duplikatów i anomalii |

### 6.2. Mechanizm

1. **Alpha**: szybka ocena kontekstowa → APPROVE/REJECT + confidence
2. **Beta**: walidacja matematyczno-fiskalna → APPROVE/REJECT + confidence
3. **Gamma**: detekcja duplikatów/anomalii → APPROVE/REJECT + confidence

Jeśli Alpha APPROVE z confidence ≥ 0.92 → **fast-path** (pomiń Beta i Gamma).

### 6.3. Matryca 8 kombinacji

Szczegółowo opisana w sekcji [2.4](#24-matryca-decyzyjna--8-kombinacji).

---

## 7. TrustScoreCalculator — kalkulacja zaufania

### 7.1. Komponenty

| Komponent | Waga | Opis |
|---|---|---|
| `ai_confidence` | 0.30 | OCR confidence, layout confidence, amount consensus |
| `vendor_reliability` | 0.25 | Czy kontrahent znany, liczba faktur, trust score |
| `data_consistency` | 0.20 | Spójność matematyczna (netto+VAT=brutto), NIP, konto |
| `context_trust` | 0.10 | Auto-approve, zgodność kategorii |
| `risk_guard` | 0.15 | Wynik RiskGuard (0.0–1.0) |

### 7.2. Wzór

```
trust_score = (ai × 0.30) + (vendor × 0.25) + (data × 0.20) + (context × 0.10) + (risk × 0.15)
```

### 7.3. Adaptacja progów

`get_adapted_thresholds()` modyfikuje bazowe progi (`auto_post=0.92`, `suggest=0.75`, `ask_user=0.50`) na podstawie:
- Kategorii (cykliczne → niższy próg, problematyczne → wyższy)
- Znajomości kontrahenta (znany → niższy, nowy → wyższy)
- Kwoty (niska → niższy, wysoka → wyższy)
- PLE (wzorzec z FM → niższy próg auto_post)

---

## 8. JambaStrategist — strategiczne wnioskowanie

### 8.1. Rola

JambaStrategist analizuje raporty ze wszystkich agentów i podejmuje **ostateczną decyzję strategiczną**. To największy model w systemie (Jamba 3B), używany tylko dla złożonych faktur.

### 8.2. Prompt

System prompt zawiera:
1. **System prompt** — rola stratega finansowego
2. **Few-shot examples** — dynamiczne przykłady z FactSheet (jeśli dostępne)
3. **Dane faktury** — ID, NIP, kwota, kategoria
4. **Arkusz faktów (RAG)** → `fact_sheet_text` (jeśli dostępny)
5. **Raport walidatora jakości** — decyzja, poziom, zaufanie
6. **Raport analityczny** — trendy, anomalie
7. **Raport ekstrakcji danych** — pola, średnie zaufanie

### 8.3. Decyzje

| Decyzja | Warunek |
|---|---|
| `AUTO_POST` | Wysoki trust score, brak zastrzeżeń, znany kontrahent |
| `SUGGEST` | Średni trust score, drobne zastrzeżenia |
| `ESCALATE` | Niski trust score, poważne zastrzeżenia lub błędy |

### 8.4. Bayesowski override

Po decyzji Jamba, system sprawdza bayesowskie progi:
- Jeśli Jamba zwróci `AUTO_POST` ale confidence < bayesowski `auto_post` → downgrade do `SUGGEST` lub `ASK_USER`
- Jeśli Jamba zwróci `SUGGEST` ale confidence < bayesowski `suggest` → `ASK_USER`

---

## 9. Perpetual Learning Engine (PLE) — trójwarstwowa pamięć

### 9.1. Architektura

PLE (`nexus_ai/services/ple_engine.py`) implementuje trójwarstwowy system pamięci wzorowany na ludzkiej:

```
┌─────────────────────────────────────────────────────┐
│                    PLE Engine                        │
├─────────────────┬─────────────────┬─────────────────┤
│   STM (50)      │   LTM (∞)      │   FM (200)      │
│  Short-Term     │  Long-Term     │  Fusion Memory  │
│  Memory         │  Memory        │                 │
├─────────────────┼─────────────────┼─────────────────┤
│ Ostatnie 50     │ Kategoryzowane  │ Cognitive       │
│ decyzji         │ per kontrahent  │ Artifacts:      │
│ TTL: 24h        │ / kategoria    │ - DecisionCache │
│                 │ Retention:      │ - PatternLib    │
│                 │ 0.95^age       │ - AnomalyInsight│
└─────────────────┴─────────────────┴─────────────────┘
```

### 9.2. STM — Short-Term Memory

| Parametr | Wartość |
|---|---|
| Max rozmiar | 50 rekordów |
| TTL | 24 godziny |
| Data Decay | Co 5 minut, usuwa rekordy starsze niż TTL |
| Konkurencja | `asyncio.Lock` |

### 9.3. LTM — Long-Term Memory

| Parametr | Wartość |
|---|---|
| Max per bucket | 100 rekordów |
| Retention decay | `0.95^age_months` |
| Data Decay | Raz na godzinę, usuwa wagę < 0.1 |
| Indeks | `(contractor_nip, category)` |

Funkcje LTM:
- `get_vendor_profile(nip)` — zwraca profil kontrahenta (avg trust, auto_post_rate, block_rate)
- `query(nip, category, limit)` — przeszukuje z filtrami

### 9.4. FM — Fusion Memory (Cognitive Artifacts)

Trzy typy artifactów:

| Typ | Klucz | Opis |
|---|---|---|
| `decision_cache` | `dc:{nip}:{cat}` | Zapamiętana typowa decyzja dla kontrahenta+kategorii |
| `pattern` | `pat:{key}` | Wzorzec decyzyjny (np. "wszystkie faktury czynsz → AUTO_POST") |
| `anomaly_insight` | `ani:{key}` | Wyjątek/anomalia (np. "BLOCK z niskim trust score") |

| Parametr | Wartość |
|---|---|
| Max artifactów | 200 |
| Min frequency dla patternu | 2 |
| Kompresja | Raz na godzinę, usuwa frequency < 2 i starsze niż 7 dni |

### 9.5. Automatyczna promocja

```
Każda decyzja → STM.push()
                ↓
         LTM.store()
                ↓
    Jeśli 3+ wpisy na kontrahenta w LTM
    i 85%+ AUTO_POST → FM.add_decision_cache()
                ↓
    Jeśli wszystkie decyzje AUTO_POST → FM.add_pattern()
                ↓
    Jeśli BLOCK/ASK_USER z trust < 0.5 → FM.add_anomaly_insight()
```

### 9.6. Adaptacja progów przez PLE

Jeśli FM ma wzorzec dla kontrahenta+kategorii z confidence ≥ 0.85:
```python
adapted["auto_post"] = max(adapted["auto_post"] - 0.05, 0.70)
```

---

## 10. BayesianThresholdLearner — Bayesowskie adaptacyjne progi

### 10.1. Filozofia

Zamiast sztywnych progów (auto_post=0.92, suggest=0.75, ask_user=0.50), każda para (kontrahent, kategoria) ma własny **rozkład Beta** aktualizowany po każdej decyzji użytkownika.

### 10.2. Matematyka

| Komponent | Wzór |
|---|---|
| **Prior** | `Beta(α=2, β=2)` — lekki sceptycyzm |
| **Posterior** | `Beta(α + sukcesy, β + porażki)` |
| **Średnia** | `α / (α + β)` |
| **Wariancja** | `(α × β) / (s² × (s + 1))` gdzie `s = α + β` |
| **Próg** | Odwrotność CDF dla percentyla: P(X > threshold) = percentile |

### 10.3. Threshold dla percentyla

- Dla n < 6: heurystyka `mean + 2 × uncertainty`, minimum 0.85
- Dla n ≥ 6: logit-normal approximation przez delta method

### 10.4. Wagi decyzji

| Kwota | Waga |
|---|---|
| < 100 PLN | 0.5 |
| 100–1000 PLN | 1.0 |
| 1000–10000 PLN | 1.5 |
| > 10000 PLN | 2.0 |

Auto-decyzje mają wagę `0.3 × waga_kwotowa` (mniejsza wartość edukacyjna).

### 10.5. Hierarchia progów

1. `(NIP, kategoria)` — najbardziej specyficzny
2. `(NIP, __global__)` — ogólny dla kontrahenta
3. `BetaPosterior()` — domyślny prior

### 10.6. Persistence

Rozkłady Beta przechowywane w SQLite (`app_data/bayesian_priors.db`):
```sql
CREATE TABLE bayesian_posteriors (
    contractor_nip TEXT,
    category TEXT,
    alpha REAL,
    beta REAL,
    total_decisions INTEGER,
    approved_count INTEGER,
    rejected_count INTEGER,
    last_updated TEXT,
    PRIMARY KEY (contractor_nip, category)
);
```

---

## 11. RiskGuard — strażnik ryzyka

### 11.1. Rola

`RiskGuard` (`nexus_ai/services/risk_guard.py`) definiuje **progi ufności per pole faktury**, zależne od formy opodatkowania i typu wydatku.

### 11.2. Architektura

Reguły przechowywane w DuckDB (`risk_thresholds`). First-match-wins według priorytetu.

### 11.3. Przykładowe reguły

| Forma opodatkowania | Pole | Wymagane confidence | Akcja poniżej |
|---|---|---|---|
| CIT_STANDARD | `vat_rate` | 0.98 | `BLOCK_AND_ALERT` |
| CIT_STANDARD | `total_net` | 0.95 | `BLOCK_AND_ALERT` |
| CIT_ESTONIAN | `vat_rate` | 0.95 | `BLOCK_AND_ALERT` |
| LINEAR | (dowolne) | 0.85 | `TRIAGE_QUEUE` |
| LUMP_SUM | `total_net` | 0.60 | `TRIAGE_QUEUE` |
| LUMP_SUM | `vat_rate` | 0.95 | `TRIAGE_QUEUE` |
| (mixed_auto) | (dowolne) | 0.90 | `BLOCK_AND_ALERT` |
| (representation) | (dowolne) | 0.95 | `BLOCK_AND_ALERT` |

### 11.4. Ewaluacja

`evaluate()` sprawdza wszystkie pola faktury, znajduje najbardziej restrykcyjną akcję i zwraca:
- `AUTO_POST` — wszystkie pola OK
- `TRIAGE_QUEUE` — średnie ryzyko, wymaga recenzji
- `BLOCK_AND_ALERT` — wysokie ryzyko, blokada

---

## 12. SemanticGuard — wykrywacz anomalii semantycznych

### 12.1. Rola

`SemanticGuard` (`nexus_ai/services/semantic_guard.py`) wykrywa anomalie semantyczne w fakturach przez porównanie embeddingów z historią kontrahenta.

### 12.2. Mechanizm

1. Generuje embedding tekstu faktury przez `EmbeddingService` (llama-cpp-python)
2. Szuka najbliższych sąsiadów w sqlite-vec dla tego kontrahenta
3. Oblicza `anomaly_score = średnia odległość kosinusowa`
4. Sprawdza reguły w `anomaly_rules` (przechowywane w DuckDB)

### 12.3. Reguły anomalii

| Min anomaly_score | Min kwota netto | Akcja |
|---|---|---|
| 0.80 | 10,000 PLN | `BLOCK_DECREE` — drastyczna zmiana profilu |
| 0.60 | 10,000 PLN | `WARN` — znacząca zmiana |
| 0.40 | 50,000 PLN | `WARN` — nietypowa wartość |
| 0.0 | 0 | `ALLOW` — catch-all |

---

## 13. DecisionLogger — logowanie decyzji

### 13.1. Rola

`DecisionLogger` (`nexus_ai/services/decision_logger.py`) loguje każdą decyzję do DuckDB z pełnym kontekstem PLE, umożliwiając audyt i analizę trendów.

### 13.2. Tabele

| Tabela | Opis |
|---|---|
| `council_decisions` | Główna tabela decyzji (alpha_vote, beta_vote, gamma_vote, final_decision, trust_score) |
| `trust_score_cache` | Cache trust score dla adaptacji wag (per contractor_nip, category) |
| `council_decisions_meta` | Metadane (czas deliberacji, poziomy, swap_count) |

### 13.3. Kluczowe funkcje

- `log_decision()` — zapis decyzji z pełnym kontekstem PLE (STM snapshot, LTM profile)
- `record_user_correction()` — rejestracja korekty użytkownika
- `get_trust_score_trend(nip, days=30)` — analiza trendu trust score (avg, min, max, trend up/down/stable, decisions_breakdown, component_averages)
- `get_user_correction_stats()` — statystyki korekt (total, corrected, rate, decision_breakdown, level_breakdown, component_correction_rates)
- `get_decisions_for_invoice(invoice_id)` — pobranie wszystkich decyzji dla faktury
- `get_decision_summary(limit=100)` — podsumowanie ostatnich decyzji

---

## 14. Rules SWAT Team — kaskada reguł biznesowych

### 14.1. Architektura

Rules SWAT Team to **hierarchiczna kaskada 4 poziomów** walidacji zgodności reguł biznesowych i podatkowych. Każdy poziom to inny model AI, z fast-path na poziomie 1.

```
Level 1: LFM2.5-Thinking → COMPLIANT z conf ≥ 0.90 → STOP (fast-path)
                              ↓ FLAG
Level 2: Granite 4.0 1B Nano → walidacja biznesowa (NIP, limity, polityka)
                              ↓ passed=true → STOP
                              ↓ passed=false
Level 3: LittleLamb 0.3B TC → Ternary Classifier (COMPLIANT / FLAG / VIOLATION)
                              ↓ COMPLIANT/FLAG → STOP
                              ↓ VIOLATION
Level 4: Fin-RWKV-169M → Końcowa weryfikacja (LOW / MEDIUM / HIGH)
```

### 14.2. Poziomy

| Level | Model | Wejście | Wyjście | Fast-path |
|---|---|---|---|---|
| 1 | LFM2.5 1.2B | Faktura + kontekst | COMPLIANT / FLAG + flags | conf ≥ 0.90 |
| 2 | Granite 4.0 1B | Flagi z L1 | passed=true/false + violations | passed=true |
| 3 | LittleLamb 0.3B | Violations z L2 | COMPLIANT / FLAG / VIOLATION | COMPLIANT/FLAG |
| 4 | Fin-RWKV-169M | VIOLATION z L3 | LOW/MEDIUM/HIGH + final_verdict | — |

---

## 15. Ekonomia poznawcza — koszty i wydajność

### 15.1. Koszt RAM na decyzję

W danym momencie w RAM znajduje się **tylko jeden model** (mutual exclusion przez `ModelManager.acquire()` / `release()`).

| Faza | Model | RAM | Czas (CPU) |
|---|---|---|---|
| WorkflowPlanner | LittleLamb 0.3B | ~500 MB | ~0.5s |
| FactsAggregator | (brak modelu — tylko zapytania DB) | 0 MB | ~0.1s |
| Council (Alpha) | LFM2.5 1.2B | ~1.0 GB | ~2s |
| Council (Beta) | Qwen3 0.6B | ~0.9 GB | ~3s |
| Council (Gamma) | LittleLamb 0.3B | ~0.5 GB | ~1s |
| Rules SWAT (L1) | LFM2.5 1.2B | ~1.0 GB | ~2s |
| Rules SWAT (L2) | Granite 4.0 1B | ~0.8 GB | ~3s |
| Rules SWAT (L3) | LittleLamb 0.3B | ~0.5 GB | ~1s |
| Rules SWAT (L4) | Fin-RWKV-169M | ~170 MB | ~0.5s |
| JambaStrategist | Jamba 3B | ~2.0 GB | ~5s |

### 15.2. Szybka ścieżka (fast-path)

Dla typowej faktury (simple):
```
WorkflowPlanner (0.5s) → FactsAggregator (0.1s) → Alpha fast-path (2s)
→ TrustScore + RiskGuard (0.1s) → JambaStrategist (5s)
→ BayesianThreshold + PLE (0.1s)
= ~7.7s total
```

### 15.3. Pełna ścieżka (complex)

Dla złożonej faktury:
```
WorkflowPlanner (0.5s) → FactsAggregator (0.1s) → Alpha+Beta+Gamma (6s)
→ Rules SWAT L1-L4 (6.5s) → TrustScore + RiskGuard (0.1s)
→ JambaStrategist (5s) → BayesianThreshold + PLE (0.1s)
= ~18.3s total
```

### 15.4. Zarządzanie pamięcią

1. **Lazy loading** — modele ładowane dopiero przy pierwszym zadaniu
2. **Explicit unloading** — `del model` + `gc.collect()` po każdym zadaniu
3. **Mutual exclusion** — `asyncio.Semaphore(1)` przez `ModelManager`
4. **TTL** — 5 minut bezczynności → automatyczne wyładowanie

---

## 16. Przepływ decyzyjny — sekwencja krok po kroku

```
                    ┌──────────────────────────────────────┐
                    │         Invoice Data (OCR)           │
                    └──────────────────┬───────────────────┘
                                       │
                                       ▼
                    ┌──────────────────────────────────────┐
              ┌────▶│      FactsAggregator.build()        │◀─────── RAG
              │     │   ┌──────┐ ┌──────┐ ┌──────┐ ┌────┐ │
              │     │   │SQLite│ │DuckDB│ │sqlite│ │ TB │ │
              │     │   │      │ │      │ │ -vec │ │    │ │
              │     │   └──────┘ └──────┘ └──────┘ └────┘ │
              │     └──────────────────┬───────────────────┘
              │                        │
              │                        ▼ FactSheet
              │     ┌──────────────────────────────────────┐
              │     │     WorkflowPlanner.plan()           │
              │     │  Simple? → EKSTRAKCJA + WALIDACJA    │
              │     │  Complex? → + ANALITYKA + DECYZJA    │
              │     └──────────────────┬───────────────────┘
              │                        │
              │                        ▼ plan
              │     ┌──────────────────────────────────────┐
              │     │     Council of Agents (Alpha/Beta/   │
              │     │     Beta/Gamma) + Rules SWAT Team    │
              │     └──────────────────┬───────────────────┘
              │                        │
              │                        ▼ raporty
              │     ┌──────────────────────────────────────┐
              │     │    TrustScoreCalculator.calculate()   │
              │     │    RiskGuard.evaluate()               │
              │     └──────────────────┬───────────────────┘
              │                        │
              │     ┌──────────────────────────────────────┐
              │     │   FactSheet.build_few_shot_examples() │
              │     └──────────────────┬───────────────────┘
              │                        │
              │                        ▼ few_shot_text
              │     ┌──────────────────────────────────────┐
              │     │    JambaStrategist.analyze()         │
              │     │    (fact_sheet + few_shot)           │
              │     └──────────────────┬───────────────────┘
              │                        │
              │                        ▼ jamba_result
              │     ┌──────────────────────────────────────┐
              │     │   BayesanThresholdLearner            │
              │     │   override?                          │
              │     └──────────────────┬───────────────────┘
              │                        │
              │                        ▼ decyzja
              │     ┌──────────────────────────────────────┐
              │     │   PLE.record_decision()              │
              │     │   → STM → LTM → FM (artifacts)      │
              │     └──────────────────┬───────────────────┘
              │                        │
              │                        ▼
              │     ┌──────────────────────────────────────┐
              │     │   OrchestratorDecision               │
              │     │   AUTO_POST / SUGGEST / ASK_USER     │
              │     │   / BLOCK / ESCALATE                 │
              │     └──────────────────────────────────────┘
              │
              └─────────── Pętla feedbacku z korekt użytkownika
                          (Bayesian + PLE + DecisionLogger)
```

---

## 17. Dynamiczny few-shot learning

### 17.1. Mechanizm

`FactSheet.build_few_shot_examples(max_examples=3)` generuje dynamiczne przykłady few-shot **przed** każdą decyzją JambaStrategist. Przykłady są wstrzykiwane do promptu między system prompt a dane faktury.

### 17.2. Źródła przykładów

1. **Ostatnie faktury kontrahenta** (`recent_invoices`) — najważniejsze, mają priorytet
2. **Semantycznie podobne faktury** (`similar_invoices`) — dopełniają do `max_examples`
3. **Rozkład decyzji** (`trust_score_trend.decisions_breakdown`) — kontekst statystyczny
4. **Korekty użytkownika** (`user_correction_patterns`) — wzorce poprawek

### 17.3. Mapowanie status → decyzja

| Status w SQLite | Decyzja few-shot |
|---|---|
| `PAID` | `AUTO_POST` |
| `APPROVED` | `AUTO_POST` |
| `SUGGESTED` | `SUGGEST` |
| `PENDING` | `ASK_USER` |
| `BLOCKED` | `BLOCK` |
| (inny/nieznany) | `SUGGEST` |

### 17.4. Format promptu

```
=== PRZYKŁADY FEW-SHOT (historyczne decyzje) ===

Przykład 1:
[Historyczna faktura]
  Kwota brutto: 1200.00 PLN
  Kategoria: IT
  Podjęta decyzja: AUTO_POST
  Status: PAID

Przykład 2:
[Podobna faktura (semantycznie, odległość: 0.1234)]
  Kwota brutto: 950.00
  Kategoria: Marketing
  Podjęta decyzja: SUGGEST
  Status: SUGGESTED

[Wzorzec decyzyjny dla tego kontrahenta]
  Liczba decyzji: 15 w ostatnich 30 dniach
  Rozkład decyzji: AUTO_POST: 12, SUGGEST: 3
  Trend trust score: up (śr. 0.85)

[Ostatnie korekty użytkownika]
  - Użytkownik zmienił kategorię z IT na Marketing
```

### 17.5. Wzbogacanie podobnych faktur

`_enrich_similar_with_decision()` pobiera dla każdej podobnej faktury z sqlite-vec jej rzeczywisty **status** z SQLite. Dzięki temu podobne faktury mają prawdziwe decyzje, a nie "dane niedostępne".

### 17.6. Limit przykładów

`max_examples` dzieli budżet między `recent_invoices` (priorytet) a `similar_invoices` (reszta):
- 2 recent + 1 similar = 3 (max)
- 3 recent + 0 similar = 3
- 0 recent + 3 similar = 3

---

## 18. Diagram architektury

```
┌═══════════════════════════════════════════════════════════════════════════┐
║                       NEXUSAI — ARCHITEKTURA POZNAWCZA                   ║
║                               v2.0 (2026)                               ║
└═══════════════════════════════════════════════════════════════════════════┘

┌──────────────────────────────────────────────────────────────────────────┐
│                      WARSTWA ORKIESTRACYJNA                              │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                      AgentOrchestrator                             │  │
│  │  ┌──────────────┐  ┌───────────────┐  ┌────────────────────────┐  │  │
│  │  │WorkflowPlan. │  │TrustScoreCalc │  │  JambaStrategist       │  │  │
│  │  │LittleLamb0.3B│  │5 komponentów  │  │  Jamba 3B             │  │  │
│  │  └──────────────┘  └───────────────┘  └────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  RAG Layer   │ │ Council of   │ │ Rules SWAT   │ │  PLE Engine  │
│ FactsAggreg. │ │ Agents       │ │ Team         │ │              │
│              │ │              │ │              │ │  ┌────────┐  │
│ ┌──────┐     │ │ ┌────────┐   │ │ ┌────────┐   │ │  │ STM   │  │
│ │SQLite│     │ │ │Alpha   │   │ │ │LFM2.5  │   │ │  │ 50    │  │
│ │      │     │ │ │LFM2.5  │   │ │ │L1      │   │ │  └────────┘  │
│ └──────┘     │ │ └────────┘   │ │ └────────┘   │ │              │
│ ┌──────┐     │ │ ┌────────┐   │ │ ┌────────┐   │ │  ┌────────┐  │
│ │DuckDB│     │ │ │Beta    │   │ │ │Granite │   │ │  │ LTM    │  │
│ │      │     │ │ │Qwen3   │   │ │ │L2      │   │ │  │ ∞      │  │
│ └──────┘     │ │ └────────┘   │ │ └────────┘   │ │  └────────┘  │
│ ┌──────┐     │ │ ┌────────┐   │ │ ┌────────┐   │ │              │
│ │sqlite│     │ │ │Gamma   │   │ │ │LittleLa│   │ │  ┌────────┐  │
│ │-vec  │     │ │ │LittleLa│   │ │ │L3      │   │ │  │ FM     │  │
│ └──────┘     │ │ └────────┘   │ │ └────────┘   │ │  │ 200    │  │
│ ┌──────┐     │ │              │ │ ┌────────┐   │ │  └────────┘  │
│ │Tiger │     │ │              │ │ │Fin-RWKV│   │ │              │
│ │Beetle│     │ │              │ │ │L4      │   │ │              │
│ └──────┘     │ │              │ │ └────────┘   │ │              │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                      WARSTWA DANYCH                                      │
│                                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐         │
│  │  SQLite    │  │  DuckDB    │  │ sqlite-vec │  │TigerBeetle │         │
│  │  +SQLCipher│  │  (OLAP)    │  │ (wektory)  │  │ (ledger)   │         │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘         │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐       │
│  │                ProtocolLoader (SOP)                          │       │
│  │                nexus_ai/config/protocols.toml                 │       │
│  └──────────────────────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                      WARSTWA UCZENIA                                     │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐       │
│  │BayesianThreshold │  │  DecisionLogger  │  │ SemanticGuard    │       │
│  │Learner           │  │  (DuckDB)        │  │  (sqlite-vec)    │       │
│  │(SQLite)          │  │                  │  │                  │       │
│  │Beta posterior    │  │  council_decisions│  │  anomaly_rules   │       │
│  │per (NIP, kategoria)│ │  trust_score_cache│ │  vendor_invoices │       │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘       │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐       │
│  │   RiskGuard      │  │  ProtocolLoader  │  │  Dynamic Few-Shot│       │
│  │   (DuckDB)       │  │  (TOML → Python) │  │  (FactSheet)     │       │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘       │
└──────────────────────────────────────────────────────────────────────────┘
```

---

> **Dokumentacja techniczna** — NexusAI v2.0  
> **Ostatnia aktualizacja:** 2026-06-09  
> **Plik:** `docs/COGNITIVE_ARCHITECTURE.md`
