# 📝 Changelog

> **Żywy dokument** — każda nowa wersja dodaje wpis na górze listy.  
> Format: [Keep a Changelog](https://keepachangelog.com/) + [SemVer](https://semver.org/).

---

## [7.0.0-draft] — 2026-07-06 — "Business Impact Decisions — Decyzje oparte na skutkach biznesowych"

### 🧠 GENIALNY POMYSŁ v7.0: Business Impact Decisions

**Przełom:** Agent przestaje pytać o metody księgowe (VAT 23%, amortyzacja liniowa), a pokazuje realne skutki finansowe każdej opcji (+2 400 PLN w kasie, niższy PIT, lepszy bilans). Wszystkie parametry księgowe → `hidden_payload`.

#### ➕ Dodane
- **`nexus_ai/services/shadow_simulator.py`** (~80 linii) — Shadow Simulation Engine v7.0
  - `ShadowLedger` — tymczasowa, izolowana kopia ksiąg w DuckDB (`ATTACH ':memory:'`)
  - `ShadowSimulator` — równoległe symulacje 2-4 wariantów księgowania przez `ThreadPoolExecutor`
  - `build_accounting_variants()` — generuje warianty na podstawie strategii (CASH_PROTECT, TAX_MINIMIZE, GROWTH)
  - Zero wpływu na TigerBeetle — wszystko w RAM, bez plików na dysku
  - Wyniki: VAT, PIT, cash-flow 30-90 dni per wariant

- **`nexus_ai/agents/user_decision_profile.py`** (~50 linii) — StrategyProfile v7.0
  - `StrategyProfile` — 5. wymiar uczenia: Business Strategy
  - 4 strategie: `CASH_PROTECT`, `TAX_MINIMIZE`, `GROWTH`, `BALANCED`
  - `observe_strategy()` — uczy się strategii z kontekstu (kwartał, płynność, kwota)
  - `get_strategy_for_quarter()` — zwraca strategię dla bieżącego kwartału
  - `most_frequent_strategy()` — dominant strategy z historii
  - Podpowiedzi kontekstowe: "W Q4 zwykle maksymalizujesz koszty"

- **`nexus_ai/agents/models.py`** — nowe struktury danych v7.0:
  - `BusinessStrategy` enum — CASH_PROTECT, TAX_MINIMIZE, GROWTH, BALANCED
  - `ShadowLedger` — msgspec struct dla tymczasowej bazy DuckDB
  - `ShadowVariant` — pojedynczy wariant symulacji (name, params, effects)
  - `ShadowSimulationReport` — pełny raport z symulacji (variants, confidence)
  - `FinancialImpactOption` — opcja dla UI (label, description, cash_flow_impact, is_positive, strategy, hidden_payload)

#### 🔄 Rozszerzone
- **`nexus_ai/agents/orchestrator.py`** — bridge Shadow Simulator → Financial Impact Card:
  - `simulate_financial_impact()` — async bridge do ShadowSimulator w thread pool
  - `simulation_to_financial_options()` — konwersja raportu → lista FinancialImpactOption
  - `generate_financial_impact_card()` — pełny pipeline: simulate → options → card + agent_hint
  - `agent_hint` generowany dynamicznie na podstawie StrategyProfile i kwartału
  - Automatyczne dodawanie opcji odrzucenia "To nie mój wydatek"

- **`nexus_ai/agents/proactive_workflow.py`** — `generate_financial_impact_card()` v7.0:
  - Konwertuje `list[FinancialImpactOption]` → `ActionCard` z title="Jak chcesz to rozliczyć?"
  - `card_options` z kwotami, strzałkami, badge'ami strategii
  - `hidden_payload` z pełnymi parametrami księgowymi (nigdy nie widoczne)
  - `agent_hint` w kontekście karty
  - Współistnieje z `generate_action_card()` (v5.1) dla backward compatibility

- **`nexus_ai/frontend/views/decision_feed.py`** — Financial Impact Card rendering:
  - Strzałki (↑/↓) z kolorami: zielony (zwiększa cash flow), czerwony (zmniejsza)
  - Kwota wpływu na cash flow w PLN (`+2 400 PLN`, `-340 PLN`)
  - Badge strategii: "Chroń płynność", "Min. podatek", "Rozwój", "Wyważone"
  - Agent hint w stylizowanym niebieskim boxie pod opcjami
  - Warunkowe renderowanie — rich buttons tylko gdy `has_financial_data`

### 📚 Dokumentacja
- **`docs/GENIALNY_POMYSL_v7_BUSINESS_IMPACT.md`**: pełen koncept v7.0 (nowy plik)
- **`docs/AGENTS.md`**: dodana sekcja 1.5h (Business Impact Decisions), zaktualizowany nagłówek i stopka
- **`docs/CHANGELOG.md`**: ten wpis
- **`docs/FRONTEND.md`**: dodana sekcja o Financial Impact Cards
- **`docs/GENIALNY_POMYSL_v6_SILENT_PARTNER.md`**: odniesienie do v7.0

### 📊 Statystyki
- **1 nowy plik**: `services/shadow_simulator.py` (~80 linii)
- **4 zmodyfikowane pliki agentów**: `orchestrator.py`, `proactive_workflow.py`, `user_decision_profile.py`, `models.py`
- **1 zmodyfikowany plik UI**: `frontend/views/decision_feed.py`
- **5 zmodyfikowanych docs**: nowy v7.md, AGENTS.md, CHANGELOG.md, FRONTEND.md, v6.md
- **~350 linii nowego kodu**

---

## [6.0.0-draft] — 2026-07-06 — "Silent Partner — Cichy Wspólnik"

### 🧠 GENIALNY POMYSŁ v6.0: Silent Partner — odwrócenie paradygmatu

**Push → Pull:** Agent NIE PYTA o decyzje — PODEJMUJE je wszystkie (100%).
Przedsiębiorca widzi Executive Summary z przyciskiem "Akceptuj wszystkie".

#### ➕ Dodane
- **`nexus_ai/agents/strategy_engine.py`** (~330 linii) — Continuous Strategy Engine v6.0
  - `StrategyEngine` — 4 tryby strategiczne: Cash Protect, Growth, Tax Optimal, Efficiency
  - 5 wymiarów kontekstu (Learning by Context): Cash Flow Phase, Tax Period, Vendor Season, Growth Phase, Macro Context
  - `analyze_context()` — automatyczna analiza 5 wymiarów na podstawie danych finansowych
  - `select_strategic_mode()` — wybór optymalnego trybu z priorytetami (user > cash flow > macro > tax)
  - `should_auto_post()` — decyzja AUTO_POST na podstawie strategii + trustu
  - `generate_strategic_recommendations()` — 0-2 rekomendacje strategiczne (liquidity, efficiency, risk)
  - `calculate_silent_rate()` — kluczowa metryka v6.0 (cel ≥95%)
  - `calculate_time_saved()` — oszczędność czasu przedsiębiorcy
  - Adaptacyjne progi per tryb strategiczny (STRATEGY_THRESHOLDS)
  - Modyfikatory okresu podatkowego (TAX_PERIOD_MODIFIERS)

- **`nexus_ai/agents/executive_summary.py`** (~230 linii) — Executive Summary Generator v6.0
  - `ExecutiveSummaryGenerator` — kolekcjonuje decyzje i buduje podsumowanie dnia
  - `add_auto_posted()` / `add_verified()` / `add_item_to_review()` — kolekcjonowanie pozycji
  - `build_summary()` — generowanie pełnego Executive Summary z greeting, trendem, oszczędnością czasu
  - `reset()` — reset na nowy dzień z zachowaniem poprzedniego stanu dla trendu
  - Automatyczne określanie DashboardState (NORMAL/ATTENTION/ALERT/EMPTY)
  - Trend vs poprzedni okres, Silent Rate, time saved

- **`nexus_ai/frontend/views/executive_dashboard.py`** (~370 linii) — Executive Dashboard View
  - `ExecutiveDashboardView` — Flet widget z 3-stanowym widokiem
  - Przycisk "Akceptuj wszystkie" — domyślna akcja (80% przypadków)
  - Secondary buttons: "Przejrzyj szczegóły", "Pokaż strategię na dziś"
  - Summary Card: faktury, kwoty, oszczędność czasu, Silent Rate progress bar, trend
  - Strategic Recommendations section z impact color coding
  - "3-Second Rule" timer — licznik czasu interakcji
  - `build_demo_dashboard()` — demo summary dla trybu offline
  - Dark theme glassmorphism UI

#### 🔄 Rozszerzone
- **`nexus_ai/agents/models.py`** — nowe struktury danych v6.0:
  - `StrategicMode` enum — CASH_PROTECT, GROWTH, TAX_OPTIMAL, EFFICIENCY
  - `CashFlowPhase` enum — SURPLUS, DEFICIT, NEUTRAL
  - `DashboardState` enum — NORMAL, ATTENTION, ALERT, EMPTY
  - `ContextDimension` struct — 5 wymiarów kontekstu strategicznego
  - `StrategicRecommendation` struct — strategiczne rekomendacje z opcjami
  - `ExecutiveSummaryItem` struct — pojedynczy element podsumowania
  - `ExecutiveSummary` struct — pełne podsumowanie z metrykami
  - `AgentContext` rozszerzony o `strategic_mode` i `silent_mode`

- **`nexus_ai/agents/orchestrator.py`** — Strategic Pipeline + Silent Mode:
  - `StrategyEngine` + `ExecutiveSummaryGenerator` w `__init__`
  - `silent_mode` property (get/set) + `silent_stats` tracking
  - `get_silent_rate()` — Silent Rate metryka
  - `process_invoice()` rozszerzony o Executive Summary collection
  - `build_executive_summary()` — generowanie i publikacja na NATS
  - `accept_all()` — 1 klik = wszystkie decyzje zatwierdzone
  - `set_strategic_mode()` — zmiana trybu strategicznego
  - `toggle_silent_mode()` — przełącznik Silent Partner
  - `get_strategy_summary()` — pełne podsumowanie strategii

- **`nexus_ai/agents/proactive_workflow.py`** — 3 nowe workflow v6.0:
  - `EXECUTIVE_SUMMARY_GENERATION` — codziennie 06:00, generuje Executive Summary
  - `STRATEGY_REFRESH` — co 6h, odświeża 5 wymiarów kontekstu
  - `SILENT_AUTO_POST` — co 15 min, wykonuje AUTO_POST dla pending decyzji

- **`nexus_ai/agents/topics.py`** — `UI_EXECUTIVE_SUMMARY` topic
- **`nexus_ai/agents/__init__.py`** — eksport wszystkich nowych klas
- **`nexus_ai/frontend/views/__init__.py`** — eksport ExecutiveDashboardView

### 📚 Dokumentacja
- **`docs/AGENTS.md`**: v5.5 → v6.0, dodana sekcja 1.5g (Silent Partner), zaktualizowany nagłówek i stopka
- **`docs/CHANGELOG.md`**: ten wpis
- **`docs/GENIALNY_POMYSL_v6_SILENT_PARTNER.md`**: pełen koncept (już istnieje)

### 📊 Statystyki
- **3 nowe pliki**: `strategy_engine.py` (~330 linii), `executive_summary.py` (~230 linii), `executive_dashboard.py` (~370 linii)
- **5 zmodyfikowanych**: `models.py`, `orchestrator.py`, `proactive_workflow.py`, `topics.py`, `agents/__init__.py`
- **2 zmodyfikowane docs**: `AGENTS.md`, `CHANGELOG.md`
- **~1100 linii nowego kodu**

---

## [5.5.0] — 2026-07-06 — "dyscache L1+L2 + stamina Circuit Breaker + Full Mesh"

### 🚀 Usprawnienia infrastruktury

#### ➕ Wdrożono: dyscache — Dwupoziomowy cache L1 (RAM) + L2 (SQLite)

- **`nexus_ai/core/dyscache.py`** — NOWY plik (~260 linii)
  - `DysCache` — dwupoziomowy cache: L1 (RAM `OrderedDict` z LRU eviction, maxsize=4096, `threading.Lock`), L2 (SQLite z WAL mode, busy_timeout, TTL)
  - W pełni async przez `anyio.to_thread.run_sync` dla wszystkich operacji SQLite
  - `AsyncDysCache` — alias z lazy initialize()
  - JSON serializacja (bezpieczniejsza niż pickle), TTL per wpis, cleanup_expired()
  - Zgodny z aa3fvcx.txt Punkt 13 (dyscache — nowoczesny, wielopoziomowy cache)

#### ➕ `DecisionCache` w `base.py` — dyscache zamiast diskcache

- **`nexus_ai/agents/base.py`**: `self._diskcache` (diskcache.Cache) → `self._dyscache` (DysCache)
  - `DysCache(l1_maxsize=4096, l2_path=..., default_ttl=86400)` — 24h domyślnie
  - `get()`: L1 RAM (ns) → L2 SQLite (ms) → fallback None
  - `set()`: L1 + L2 równolegle, TTL wspólny
  - `close()`: opróżnienie L1 + zamknięcie SQLite
  - sqlite-vec k-NN dla embeddingów pozostaje bez zmian
  - Zgodny z AGENT_SYSTEM_ENTERPRISE.txt §5.5 + aa3fvcx.txt Punkt 13

#### ➕ stamina Circuit Breaker — ochrona API zewnętrznych

- **`nexus_ai/services/white_list_service.py`** — Biała Lista MF:
  - `_fetch_nip_data()`: `stamina.retry_context(on=(HTTPStatusError, RequestError, ...), attempts=3, timeout=10.0, circuit_breaker=True)`
  - Graceful degradation: `except stamina.RetryingError → return None` z logowaniem

- **`nexus_ai/core/integrations/ksef/client.py`** — KSeF Client:
  - `fetch_invoice()`: stamina retry 3× z CB, `ConnectionError` po wyczerpaniu

- **`nexus_ai/core/integrations/ksef/auth.py`** — KSeF Auth:
  - `login()`: stamina retry 3× z CB, `ConnectionError` po wyczerpaniu

- **`nexus_ai/core/opa_client.py`** — OPA local sidecar:
  - `health()`, `evaluate()`, `load_data()`: stamina retry (bez CB — lokalny proces)

- **Już chronione (bez zmian):** `gus_bir_client.py`, `ksef_service.py`, `core/cache/http_client.py`

### 🔗 KnowledgeMesh — pełna integracja z 5 agentami

#### ➕ AgentAnalytics — ostatni agent zintegrowany z Meshem

- **`nexus_ai/agents/analytics.py`**:
  - `knowledge_mesh: Any = None` w `__init__`, przekazany do `BaseAgent`
  - `_publish_mesh_events()` — nowa metoda z 4 tierami publikacji:
    1. 🔴 Z-score > 3σ (high): `analytics.anomaly_detected` → QV TRIGGER_DEEP_CHECK + Orch LOWER_THRESHOLD + 1× `update_trust(correct=False)`
    2. 🟡 Z-score 2-3σ (medium): event bez obniżania Trust
    3. ⚠️ Risk flags (overdue, high_amount): event + `update_trust` dla overdue
    4. 💰 Cashflow/forecast: event z `detection_method=cashflow_analysis`
  - Wywołanie na końcu `analyze()` (krok 5a) po detekcji anomalii i flag ryzyka
  - Bugfix z code review: `update_trust` zeskalowany z pętli (N× per anomaly) na agregację (1× per call)

#### 🔄 AgentAnalytics — poprawiony warunek publikacji (v5.3 fix)

- **`nexus_ai/agents/extraction.py`**:
  - `medium_consensus_fields and confidence < 0.7` → `elif medium_consensus_fields:`
  - Event `extraction.low_consensus` publikowany TERAZ zawsze gdy konsensus OCR 50-75% (nie tylko gdy ogólna pewność < 70%)
  - QualityValidator dostaje INCREASE_SCRUTINY niezależnie od ogólnej confidence

#### ✅ Stan integracji KnowledgeMesh (5 agentów)

| Agent | Integracja | Eventy |
|---|---|---|
| AgentDataExtraction (extraction.py) | ✅ v5.3 | `extraction.low_consensus` |
| AgentQualityValidator (quality_validator.py) | ✅ v5.3 | `quality.tax_error`, `quality.fraud_detected`, `analytics.anomaly_detected` |
| AgentOrchestrator (orchestrator.py) | ✅ v5.3 | PredictiveTaskRouter + get_threshold_adjustments() |
| AgentAnalytics (analytics.py) | ✅ **v5.5 NOWY** | `analytics.anomaly_detected` (4 tiery) |
| AgentFixedAssets (fixed_assets.py / services/) | ❌ nie wymaga (deterministyczny) | — |

### 🐛 Poprawione

- **`extraction.py`**: Usunięty zbędny warunek `and confidence < 0.7` dla eventu medium-consensus
- **`analytics.py`**: Agregacja `update_trust` z pętli na pojedyncze wywołanie (uniknięcie nadmiernego karania Trust Score)
- **`white_list_service.py`**: Dodana obsługa `stamina.RetryingError` z graceful degradation (`return None` zamiast propagacji wyjątku)
- **`core/dyscache.py`**: Poprawiony `cleanup_expired()` — `cursor.rowcount` zamiast `total_changes`, przywrócony `anyio.to_thread.run_sync` po code review

### 📚 Dokumentacja

- **`docs/CHANGELOG.md`**: ten wpis
- **`docs/AGENTS.md`**: zaktualizowane sekcje KnowledgeMesh (Analytics + Extraction fix), stamina CB, dyscache
- **`docs/MODULES.md`**: dodany moduł dyscache, zaktualizowany DecisionCache opis
- **`docs/AGENT_SYSTEM_ENTERPRISE.txt`**: zaktualizowany spis technologii, Decision Cache, PODSUMOWANIE

### 📊 Statystyki
- **1 nowy plik**: `core/dyscache.py` (~260 linii)
- **5 zmodyfikowanych**: `base.py`, `analytics.py`, `extraction.py`, `white_list_service.py`, `ksef/client.py`, `ksef/auth.py`, `opa_client.py`
- **3 zmodyfikowane docs**: `AGENTS.md`, `MODULES.md`, `AGENT_SYSTEM_ENTERPRISE.txt`
- **~450 linii nowego kodu** (w tym dyscache 260 + stamina 80 + Analytics Mesh 110)

---

## [5.4.0] — 2026-07-06 — "Decision Protocol + Unified Learning Protocol"

### 🧠 GENIALNY POMYSŁ v5.4: Decision Protocol + Unified Learning Protocol

#### ➕ Dodane
- **`nexus_ai/agents/decision_trace.py`** (~620 linii) — Decision Protocol v5.4
  - `DecisionTracer` — OTel tracing każdej decyzji z 10 spanami (cache→mesh→extraction→handbook→actor→guardian→ensemble→quality→calibration→final)
  - `MultiModelEnsemble` — ≥2 modele (Actor + Guardian + Handbook few-shot), diversity check, fallback requires_human
  - `ConfidenceCalibrator` — Platt Scaling online (SGD, decay rate 0.99), reliability diagram, eliminacja overconfidence
  - `FeedbackLoop` — metryki: time-to-decision, correction_rate, avg_quality_score, avg_feedback_latency_ms
  - `DecisionSpan` / `DecisionTrace` — struktury msgspec.Struct dla OTel spanów
  - `EnsembleVote` / `EnsembleResult` — struktury dla głosowania ensemble
- **`nexus_ai/agents/telemetry_store.py`** (~600 linii) — AgentTelemetryStore
  - DuckDB + Parquet dla wszystkich decyzji, korekt, routingów, trace'ów i feedbacku
  - 5 tabel: decisions, corrections, routes, traces, feedback
  - Eksport do Parquet z kompresją ZSTD
  - Metody: record_decision(), record_correction(), record_route(), record_trace(), record_feedback()
- **Integracja w `orchestrator.py`**:
  - DecisionTrace z OTel spanami w każdym kroku pipeline'u decision protocol
  - MultiModelEnsemble (Actor + Guardian + Handbook) z diversity check
  - ConfidenceCalibrator kalibrujący Trust Score przed finalną decyzją
  - AgentTelemetryStore rejestrujący każdą decyzję, routing i trace
  - **UnifiedLearningProtocol** — kaskada 5 systemów po każdej korekcie: Handbook → LearningProvider → KnowledgeMesh → DecisionProfile → TelemetryStore

### 🐛 Poprawione
- **`error_handbook.py`**: dodane `find_similar_by_embedding()` z prawdziwym k-NN przez DuckDB + RAM fallback (zamiast symulowanych wektorów hash)
- **`decision_trace.py`**: `MIN_MODELS` obniżone z 3 → 2 (poprawka z code review)
- **`orchestrator.py`**: `gross_amount_num` używa wartości post-ekstrakcyjnej zamiast sprzed OCR (poprawka z code review)

### 📚 Dokumentacja
- **`docs/AGENTS.md`**: v5.2 → v5.4, dodane sekcje 1.5e (KnowledgeMesh), 1.5f (Decision Protocol), zaktualizowany decision flow
- **`docs/AGENT_SYSTEM_ENTERPRISE.txt`**: v5.2 → v5.4, dodane sekcje 0d/0e, zaktualizowany TOC, Unified Learning Protocol
- **`docs/CHANGELOG.md`**: ten wpis

### 📊 Statystyki
- **2 nowe pliki**: `decision_trace.py`, `telemetry_store.py`
- **4 zmodyfikowane**: `orchestrator.py`, `error_handbook.py`, `__init__.py`, `base.py`
- **5 zmodyfikowanych docs**: `AGENTS.md`, `AGENT_SYSTEM_ENTERPRISE.txt`, `MODULES.md`, `ARCHITECTURE.md`, `SPECYFIKACJA_AGENTOW_ENTERPRISE.txt`
- **~1300 linii nowego kodu**

---

## [5.3.0] — 2026-07-06 — "Agent Knowledge Mesh (EASP)"

### 🧠 GENIALNY POMYSŁ v5.3: Agent Knowledge Mesh (EASP)

#### ➕ Dodane
- **`nexus_ai/agents/knowledge_mesh.py`** — Agent Knowledge Mesh v5.3 (EASP)
  - `KnowledgeMesh` — główna klasa: CollectiveBayesianField + PredictiveTaskRouter + CrossAgentExperienceReplay
  - `CollectiveBayesianField` — współdzielony Trust Score Beta(α,β) per vendor, aktualizowany przez wszystkie agenty
  - `PredictiveTaskRouter` — dynamiczny DAG agentów: Circuit Breaker (trust < 0.30 → BLOCK), SKIP (trust ≥ 0.92)
  - `CrossAgentExperienceReplay` — CROSS_AGENT_RULES: extraction.low_consensus → QualityValidator INCREASE_SCRUTINY, quality.tax_error → Orchestrator LOWER_AUTO_POST_THRESHOLD, quality.fraud_detected → ALL HIGH_ALERT
  - `MeshProtocol` — protokół komunikacji: route(), update_trust(), share_experience(), get_threshold_adjustments()
- **Struktury EASP w `models.py`**:
  - `MeshField` — pole siatki wiedzy (vendor_nip, category, alpha, beta, trust_score)
  - `ExperienceRule` — reguła doświadczenia Cross-Agent (source, target, action, priority)
  - `RouteDecision` — decyzja routingu (target_agents, skip_agents, threshold_adjustments, circuit_breaker_active)
  - `MeshEvent` — event w siatce wiedzy (event_type, severity, source_agent, vendor_nip)

### 🔗 Integracje KnowledgeMesh z agentami

#### ➕ AgentDataExtraction (`extraction.py`)
- Dodany parametr `knowledge_mesh` do `__init__`
- `_publish_mesh_events()` — analizuje macierz walidacji krzyżowej 4×4:
  - Konsensus < 50% → obniża Trust Score + publikuje `extraction.low_consensus`
  - Konsensus 50-75% + confidence < 0.7 → publikuje event z severity="medium"
  - Confidence < 0.5 → obniża Trust + publikuje z reason="overall_confidence_very_low"
  - Confidence ≥ 85% → podnosi Trust Score

#### ➕ AgentQualityValidator (`quality_validator.py`)
- Dodany parametr `knowledge_mesh` do `__init__`
- `_publish_mesh_events()` — po każdej walidacji:
  - Tax ERROR/WARNING → obniża Trust Score + publikuje `quality.tax_error` (Extraction HIGH_SCRUTINY, Orchestrator LOWER_AUTO_POST_THRESHOLD)
  - Fraud ERROR → obniża Trust + publikuje `quality.fraud_detected` (wszyscy agenci HIGH ALERT)
  - ESG ERROR/WARNING → publikuje `analytics.anomaly_detected`
  - All OK → podnosi Trust Score

#### 🔄 Zaktualizowane
- **`base.py`**: `BaseAgent` przyjmuje opcjonalny `knowledge_mesh` parametr, dodane `mesh` property i `set_mesh()`
- **`orchestrator.py`**: zintegrowany predykcyjny routing KnowledgeMesh w `process_invoice`, `register_agent()` propaguje mesh do podległych agentów
- **`__init__.py`**: wyeksportowane KnowledgeMesh, CollectiveBayesianField, CrossAgentExperienceReplay, PredictiveTaskRouter, MeshProtocol + struktury EASP

### 🐛 Poprawione
- **`knowledge_mesh.py`**: usunięte zduplikowane definicje MeshField/ExperienceRule/RouteDecision/MeshEvent (importowane z models.py)
- **`quality_validator.py`**: naprawiony `all_ok` dla pominiętych kontroli, usunięte duplikaty przypisań
- **`extraction.py`**: dodany brakujący event dla skrajnie niskiej confidence

### 📚 Dokumentacja
- **`docs/AGENTS.md`**: dodana sekcja 1.5e (KnowledgeMesh), zaktualizowane opisy Extraction i QualityValidator
- **`docs/AGENT_SYSTEM_ENTERPRISE.txt`**: dodana sekcja SPIS TREŚCI dla 0d

### 📊 Statystyki
- **4 zmodyfikowane pliki agentów**: `knowledge_mesh.py`, `extraction.py`, `quality_validator.py`, `orchestrator.py`
- **3 zmodyfikowane**: `models.py`, `base.py`, `__init__.py`
- **~600 linii zmian** (głównie usunięcie duplikatów + integracje)

---

## [5.2.0] — 2026-07-05 — "Progressive Autonomy + DecisionFeedView"

### 🧠 GENIALNY POMYSŁ v5.2: Progressive Autonomy Engine

#### ➕ Dodane
- **`nexus_ai/agents/user_decision_profile.py`** (~400 linii) — Progressive Autonomy Engine
  - `UserDecisionProfile` — agent obserwuje wzorce decyzyjne i przejmuje rutynowe decyzje
  - `VendorTrustProfile` — 4 poziomy zaufania (new→learning→trusted→fully_trusted), adaptacyjne progi AUTO_POST
  - `CategoryPreference` — preferencje kategorii (preferred_action, preferred_option)
  - `AmountThreshold` — 5 przedziałów kwotowych z should_auto_post
  - `DecisionPattern` — pojedynczy wzorzec (vendor_trust, category_preference, amount_threshold)
  - `WeeklyAutonomyReport` — cotygodniowy raport z message NL
  - `observe_decision()` — 4 wymiary uczenia (vendor, category, amount, autonomy)
  - `_derive_patterns()` — wyprowadzanie wzorców z profili po każdej decyzji
  - `get_adaptive_threshold()` — adaptacyjny próg per kontrahent
  - `should_auto_post()` — pełna decyzja (vip, amount, trust) → (bool, reason)
  - `generate_weekly_report()` — "Przejąłem 73% decyzji, zaoszczędziłem 45 kliknięć"
  - Decision Autonomy Score: AUTO_POST/(AUTO_POST+ASK_USER)×100%, cel 90%+ w 3 miesiące
- **Integracja w `orchestrator.py`**:
  - `_decision_profile` — `UserDecisionProfile()` w `__init__`
  - Blended threshold: `get_threshold(nip, base=profile.get_adaptive_threshold(nip))`
  - `observe_decision()`: AUTO_POST w `process_invoice`, SUGGEST/ASK_USER w `handle_user_card_response`
  - Nowe metody: `get_autonomy_score()`, `get_decision_profile_summary()`, `generate_weekly_autonomy_report()`
- **Eksport w `__init__.py`**: AmountThreshold, CategoryPreference, DecisionPattern, UserDecisionProfile, VendorTrustProfile, WeeklyAutonomyReport

### 📱 GENIALNY POMYSŁ v5.1: DecisionFeedView — Flet UI "1-Click CFO"

#### ➕ Dodane
- **`nexus_ai/frontend/views/decision_feed.py`** (~340 linii) — widok Flet Decision Feed
  - `DecisionFeedView` — `@ft.component` + `use_state()`, deklaratywny
  - Card stack: jedna karta na raz, `AnimatedSwitcher` (scale transition 350ms)
  - 3 kolory przycisków: zielony (#1B5E20) rekomendacja AI ⭐, szary (#37474F) alternatywy, czerwony (#4A1414) odrzuć
  - Trust Score bar: `ft.ProgressBar` (zielony ≥0.92, pomarańczowy ≥0.75, czerwony <0.75)
  - Urgency banner: "⚠️ PILNE" / "⚡ Wysoki priorytet"
  - Document badge: Faktura / Podatki / Środek trwały / Przelew
  - NATS subscriber: nasłuch `ui.feed.pending` → `msgspec.json.decode` → karty
  - NATS publish: kliknięcie → `ActionCardResponse` na `ui.feed.action`
  - Guard `initialized` ref: tylko 1 połączenie NATS (zapobiega duplikacji przy re-renderach)
  - Cleanup: `page.on_close` → `nats_sub.unsubscribe()` + `nats_nc.drain()`
  - Snackbar potwierdzenia z kolorem akcji
  - 3 karty demo (NATS offline fallback)
  - Stany UI: loading skeleton, empty state ("Wszystko zaksięgowane! 🎉")
- **Eksport**: `frontend/views/__init__.py` — `DecisionFeedView`

### 🃏 Action Cards — "Zasada 1-Click CFO" (v5.1)

#### ➕ Dodane
- **Struktury danych w `models.py`**:
  - `ActionCardOption` — przycisk z `hidden_payload` (pełne parametry księgowe)
  - `ActionCard` — karta: title, summary, 2-4 opcje, trust_score, urgency
  - `ActionCardFeed` — "skrzynka decyzyjna" z greeting NL
  - `ActionCardResponse` — odpowiedź użytkownika
- **`ActionCardGenerator` w `proactive_workflow.py`** (~300 linii):
  - 6 szablonów: INVOICE_STANDARD, INVOICE_HIGH_AMOUNT, INVOICE_NEW_VENDOR, TAX_ALERT, ASSET_CLASSIFICATION, PAYMENT_BATCH
  - `generate_action_card()` — tłumaczenie technicznego `AgentDecision` na prostą kartę
  - `generate_card_from_decision()` — async z opcjonalnym ulepszeniem Qwen3-Nano
  - `build_daily_feed()` — feed na dziś, sortowanie wg urgency, powitanie NL
  - Prompt Qwen3-Nano zabrania żargonu (WN, MA, PKWiU, MPP, JPK)
- **`ui.feed.pending` / `ui.feed.action`** w `topics.py` — nowe topiki NATS
- **Integracja w `orchestrator.py`**:
  - `card_generator` property, `generate_action_card()`, `build_daily_decision_feed()`, `handle_user_card_response()`
  - `handle_user_card_response`: confirm/reject → `record_user_feedback` + Cognitive Audit Trail

### ⚙️ ProactiveWorkflowScheduler — rozszerzenia (v5.0)

#### ➕ Dodane
- **`DECISION_FEED_REFRESH`** — nowy workflow (co 30 min) odświeżający feed kart decyzyjnych
  - Handler `_handle_decision_feed_refresh` w `proactive_workflow.py`
  - Cron task `proactive_decision_feed_refresh` w `tasks.py`

### 🐛 Poprawione
- **Deduplikacja workflow**: `was_executed_today` → `was_executed_recently` z `_cooldown_from_cron()`
  - Dla `*/30` → 30 min cooldown, dla `0 6` → 1440 min cooldown
  - Naprawia bug blokujący powtarzalne wykonania (DECISION_FEED_REFRESH tylko raz dziennie)
- **`loaded` variable w `_handle_resource_optimizer`**: dodano konstrukcję `loaded` przed użyciem
- **`stop()` w Orchestratorze**: wywołanie `_proactive_scheduler.stop()` przed `super().stop()`
- **Podwójne zliczanie w Progressive Autonomy**: `observe_decision` tylko dla AUTO_POST w `process_invoice`, SUGGEST/ASK_USER tylko w `handle_user_card_response`
- **Blended Bayesian + Profile thresholds**: `get_threshold(nip, base=profile_threshold)` zamiast zastępowania Bayesian
- **`_patterns` teraz wypełniane**: `_derive_patterns()` z profili vendor/category/amount
- **`msgspec` import** w `decision_feed.py` — dodany na poziomie modułu
- **NATS cleanup**: `page.on_close` → unsubscribe + drain
- **Guard inicjalizacji NATS**: `initialized` ref zapobiega duplikacji połączeń
- **Martwy error state usunięty** z DecisionFeedView

### 📚 Dokumentacja
- **`docs/AGENTS.md`**: v5.1 → v5.2, dodane sekcje 1.2c (Progressive Autonomy), 1.2d (DecisionFeedView), zaktualizowane progi adaptacyjne, stopka
- **`docs/AGENT_SYSTEM_ENTERPRISE.txt`**: v5.1 → v5.2, dodane sekcje 0b (Progressive Autonomy), 0c (DecisionFeedView), SPIS TREŚCI, PODSUMOWANIE 16→19 innowacji
- **`docs/CHANGELOG.md`**: ten wpis

### 📊 Statystyki
- **2 nowe pliki**: `user_decision_profile.py`, `decision_feed.py`
- **7 zmodyfikowanych**: `orchestrator.py`, `proactive_workflow.py`, `tasks.py`, `models.py`, `topics.py`, `agents/__init__.py`, `frontend/views/__init__.py`
- **2 zmodyfikowane docs**: `AGENTS.md`, `AGENT_SYSTEM_ENTERPRISE.txt`
- **19 kluczowych innowacji** Enterprise v5.2 (z 16 w v5.0)
- **~1200 linii nowego kodu** (user_decision_profile 400 + decision_feed 340 + ActionCardGenerator 300 + rozszerzenia)

---

## [3.0.0-dev] — 2026-07-05 — "Agentic Architecture"

### 📋 Audyt dokumentacji — kompleksowy przegląd 40 plików

#### 🔧 Naprawione
- **`docs/DATABASE.md`** — naprawiono zduplikowany footer (3 linie zamiast 2), ujednolicono separator `⸱`→`·`
- **`docs/PROJECT_STRUCTURE.md`** — naprawiono zduplikowany footer (3 linie zamiast 2), ujednolicono separator `⸱`→`·`

#### ✅ Zweryfikowane
- **Wszystkie 40 plików** — footery spójne z `3.0.0-dev`
- **Wszystkie linki wewnętrzne** — 0 uszkodzonych
- **Stare referencje 2.3.0/2.3.1** — 0 pozostałych
- **Kod źródłowy** — 4 klasy agentów w `nexus_ai/agents/` + 23+ serwisów w `nexus_ai/services/` — zgodne z dokumentacją

#### 🆕 Zaktualizowane
- `.env.example` — utworzono plik z 50+ zmiennymi i komentarzami
- `docs/nexusai_dokumentacja.html` — zregenerowana (40 rozdziałów, 789 KB)
- `docs/nexusai_dokumentacja_dark.html` — zregenerowana (40 rozdziałów, 789 KB)

---

### 🤖 System Agentów AI (v3.0 Enterprise)

### 🤖 System Agentów AI (v3.0 Enterprise)

#### ➕ Dodane
- **`docs/AGENTS.md`** — kompletna specyfikacja 5 agentów AI: Orchestrator, Extraction, Analytics, QualityValidator, FixedAssets (zgodnie z aa3fvcx.txt)
- **Decision Engine** — wielowarstwowy silnik decyzyjny: strefy decyzyjne (Dynamic Thresholds), konsensus między agentami (weighted voting), eskalacja do człowieka, Proof Chain SHA-256
- **Continuous Learning Framework** — Active Learning Loop, Bayesian Trust Score, Online OCR Learning, propagacja korekt (bezpośrednia/pośrednia/globalna/strukturalna)
- **Memory Systems** — 4 typy pamięci: Episodic (DuckDB), Semantic (sqlite-vec), Procedural (OPA/Rego), Working (NATS KV Store)
- **JEDEN poziom automatyzacji** — DecisionMode (AUTO_POST / SUGGEST / ASK_USER) zgodnie z aa3fvcx.txt
- **4-Eyes Principle** — obowiązkowa weryfikacja przez 2 niezależne modele dla kwot > 50,000 PLN
- **ADR-009** — architektura 5 wyspecjalizowanych agentów AI zamiast monolitycznego LLM (zgodnie z aa3fvcx.txt)

#### 🔄 Zaktualizowane
- **`docs/MODULES.md`** — zaktualizowana tabela 5 agentów (zgodnie z aa3fvcx.txt), odwołanie do AGENTS.md
- **`docs/ARCHITECTURE.md`** — dodano ADR-009 (architektura agentów), cross-reference do AGENTS.md
- **`docs/SECURITY.md`** — rozszerzono sekcję "Bezpieczeństwo AI" o 4-Eyes Principle, agent-level RBAC, audit log, Proof Chain
- **`docs/GLOSSARY.md`** — dodano 8 nowych terminów (Active Learning, Adaptive Thresholds, Agent AI, Bayesian Trust Score, Confidence Calibration, Continuous Learning, Decision Engine, Memory Systems, Trust Score)
- **`docs/FAQ.md`** — dodano pytania o 5 agentów, Trust Score, 4-Eyes Principle, zużycie RAM
- **`docs/INDEX.md`** — dodano AGENTS.md do nawigacji (M2b), listy plików (38), indeksu tagów

### 📊 Statystyki
- **38 plików .md** — +1 nowy (AGENTS.md)
- **5 agentów AI** — udokumentowanych z modelami, RAM, mechanizmami (zgodnie z aa3fvcx.txt)
- **9 ADR** — w tym nowy ADR-009

---

## [2.3.1-dev] — 2026-07-05 — „Enterprise Documentation"

### 📚 Dokumentacja (pełna przebudowa)

#### ➕ Dodane (18 nowych plików)
- **`docs/00_META.md`** — strona tytułowa: identyfikacja projektu, PWE, zespół (10 ról), licencja, compliance matrix
- **`docs/FOUNDATION.md`** — warstwa Foundation: UnitOfWork, Pipeline, BaseRepository, BaseService, AdminServiceRegistry, Result[T,E], auto_crud (~10 300 linii oszczędności)
- **`docs/SCRIPTS.md`** — skrypty CLI: bootstrap, download modeli, seed danych, backup, build Nuitka, Taskiq worker
- **`docs/INSTALLER.md`** — instalator Windows/OTA: dependency downloader (NATS, TB, OPA), model downloader (SHA-256), OTA updater, Flet UI dialogs
- **`docs/FRONTEND.md`** — Flet UI: Navigator 2.0, NexusRouter, ThemeManager, 7 widoków, Chart widgets (zero matplotlib)
- **`docs/EVENTS.md`** — Event Sourcing: 10 zdarzeń domenowych, AsyncEventStore, JetStreamBus, CQRS Projections, SchemaRegistry
- **`docs/PIPELINE.md`** — Pipeline OCR: BaseOCREngine, 4 silniki, Consensus voting, InvoiceParser
- **`docs/INFERENCE.md`** — AI Inference: InferenceService (TTL auto-unload), ModelManager, AdaptiveBatcher (NOWY)
- **`docs/MONITORING.md`** — Monitoring: ProcessMonitor (oneshot, USS/PSS), SystemMonitor, WorkerGuard (NOWY)
- **`docs/HTTP_CLIENT.md`** — HTTP Client: CachedHttpClient, HTTP/2, Exporters, NBP cache warming (NOWY)
- **`docs/CONFIG.md`** — Konfiguracja TOML: base.toml, dev/prod profile, 50+ env vars, protocols (NOWY)
- **`docs/DOMAIN.md`** — Warstwa Domenowa: 3 agregaty DDD, 14 Value Objects, Domain Events (wersja bazowa), domenowa maszyna stanów (NOWY)
- **`docs/WORKFLOWS.md`** — CI/CD: 7 workflowów GitHub Actions, analiza statyczna, performance, security, automatyzacja (NOWY)
- **`docs/PDFIUM.md`** — Engine PDF: PdfDocumentSession, RenderFlags, ProgressivePDFLoader, 14 DTO (NOWY)
- **`docs/DECISIONS.md`** — System Decyzyjny: DecisionLogger, DecisionQueue, TrustScore, Autopilot API, CorrectionStats (NOWY)
- **`docs/BUILD_CONFIG.md`** — Build Config: pixi.toml, pyproject.toml, pre-commit, Nuitka config, env vars (NOWY)
- **`docs/BIBLIOGRAPHY.md`** — formalna bibliografia (10 kategorii)
- **`docs/RELATED.md`** — konkurencja rynkowa (7 systemów), RFC
- **`docs/RUST_MODULE.md`** — moduł `nexus-crypto` (Rust+PyO3): 3 algorytmy, Vault
- **`docs/MODELS_MANIFEST.md`** — 13 modeli GGUF, 5 agentów + 8 specjalistycznych

#### 🔄 Zaktualizowane (19 plików)
- **`docs/ARCHITECTURE.md`** — dodano NFR (SLA, SLO), Capacity Planning, Disaster Recovery Plan, Error Budget
- **`docs/FRONTEND.md`** — dodano diagram nawigacji Mermaid, RouteGuard matrix, a11y, performance, UI testing
- **`docs/EVENTS.md`** — dodano Event Versioning 3-poziomowy (tolerancyjny → soft → hard), schema evolution
- **`docs/PROJECT_STRUCTURE.md`** — dodano diagram zależności modułów Mermaid, 6 brakujących serwisów
- **`docs/PIPELINE.md`** — dodano sekcję 9: taski OCR przez Taskiq (process_invoice_ocr, walidacje)
- **`docs/MODULES.md`** — dodano 31 nieudokumentowanych serwisów (3 sekcje 4.7–4.9)
- **`docs/INDEX.md`** — indeks 32 plików, nowe sekcje 6f–6i, moduł M1b, rozszerzone szybkie wyszukiwanie
- **`docs/SECURITY.md`** — dodano parametry Argon2id, skrypt rotacji kluczy, security checklist
- **`docs/INTRODUCTION.md`** — glossary → cross-reference do GLOSSARY.md (eliminacja duplikacji)
- **`docs/QUICKSTART.md`** — linki do SCRIPTS, INSTALLER, FRONTEND
- **`docs/SCRIPTS.md`** — link do TROUBLESHOOTING.md
- **`docs/00_META.md`** — wersja 2.3.1-dev
- **`docs/generate_html.py`** — 35 rozdziałów (dodano INFERENCE, MONITORING, HTTP_CLIENT, CONFIG)
- **`docs/generate_pdf.sh`** — dodano INFERENCE.md, MONITORING.md, HTTP_CLIENT.md, CONFIG.md
- **`docs/generate_html.py`** — 37 rozdziałów (dodano DOMAIN, WORKFLOWS)
- **`docs/generate_pdf.sh`** — dodano DOMAIN.md, WORKFLOWS.md
- **`docs/INDEX.md`** — 34 pliki, sekcje 6j–6k
- **`docs/generate_html.py`** — 40 rozdziałów (dodano PDFIUM, DECISIONS, BUILD_CONFIG)
- **`docs/generate_pdf.sh`** — dodano PDFIUM.md, DECISIONS.md, BUILD_CONFIG.md
- **`docs/INDEX.md`** — 37 plików, sekcje 6l–6n
- **`docs/CHANGELOG.md`** — ten wpis (18 nowych, 19 zaktualizowanych, łącznie 37 plików)

#### ✅ Code Review (6 poprawek)
- **`docs/generate_pdf.sh`** — naprawiono ścieżkę `README.md` z `../../README.md` na `../README.md`
- **`docs/INDEX.md`** — naprawiono licznik „21 sekcji" → dynamiczne sformułowanie
- **`docs/INDEX.md`** — usunięto duplikację tabeli plików
- **`docs/ARCHITECTURE.md`** — dodano cross-reference do FOUNDATION.md
- **`docs/FRONTEND.md`** — usunięto referencję do nieistniejącego `agent_status.py`
- **`docs/SCRIPTS.md`** — naprawiono ścieżki CLI na poprawne `python -m nexus_ai.scripts.*`

#### 🐛 Poprawione
- **`docs/`** — archiwizacja przestarzałych plików `.txt` (`aa3fvcx.txt`, `tfgxzd.txt`) do `docs/.archive/`
- **`docs/MODULES.md`** — kod konsensusu OCR używa `difflib.SequenceMatcher` (stdlib)
- **Audyt linków wewnętrznych** — 0 błędów na 146 linków między plikami .md
- **Audyt referencji do kodu** — wszystkie ścieżki `nexus_ai/*.py` wskazują na istniejące pliki

### 📊 Statystyki
- **37 pliki .md** (18 nowych, 19 zaktualizowanych, ~350 stron)
- **40 rozdziałów HTML**, 750+ KB (oba warianty: light + dark)
- **15+ diagramów Mermaid**, 8 ADR, 250+ linków wewnętrznych
- **70+ serwisów** w MODULES.md, **36 kontrolerów API** w API.md
- **~10 300 linii boilerplate'u** w FOUNDATION.md
- **10 zdarzeń domenowych** w EVENTS.md
- **4 silniki OCR** w PIPELINE.md, **10 nowych sekcji** (6f-6n)

### 🧱 Warstwa Foundation (nowa sekcja docs/FOUNDATION.md)
- **`Result[T, E]`** — monada Either z dyskryminowanymi podklasami (Ok/Err), zero type: ignores
- **`UnitOfWork`** — atomowe transakcje na wielu repozytoriach, sync + async context manager
- **`Pipeline[T]` + `Step[T]`** — sekwencyjne przetwarzanie z PipelineContext
- **`BaseRepository[T]`** — generyczny CRUD dla SQLModel
- **`BaseService[T, CreateDTO, UpdateDTO]`** — auto-CRUD z inferencją modelu
- **`AdminServiceRegistry`** — samo-rejestrujące serwisy admin z DuckDB + NATS
- **`auto_crud()`** — generacja kontrolerów REST z modelu SQLModel
- **`PaginatedResponse[T]`** — generyczna odpowiedź stronicowana

### ⚡ Event Sourcing (nowa sekcja docs/EVENTS.md)
- **10 zdarzeń domenowych**: InvoiceCreated → NotificationSent (msgspec Tagged Unions)
- **AsyncEventStore**: append-only SQLite + optymistyczne blokady + Parquet archiving (ZSTD level 7, Hive-style partycjonowanie)
- **JetStreamEventBus**: 7 strumieni NATS, auto-reconnect (exponential backoff z jitterem), mirror/sourcing
- **CQRS Projections**: InvoiceProjection (FTS5, triggers, indeksy warunkowe), DecisionProjection
- **DomainEventSchemaRegistry**: auto-generacja JSON Schema (draft 2020-12) przez __init_subclass__

### 🔍 Pipeline OCR (nowa sekcja docs/PIPELINE.md)
- **BaseOCREngine**: Template Method + catch_ocr_errors, ~1 500 linii oszczędności
- **4 silniki**: Tesseract (CLI, PSM/OEM), PaddleOCR (PP-OCRv4, PP-Structure, tabele/pieczęcie), docTR (KIE, reading order), EasyOCR (adaptacyjne progi)
- **OCR Consensus**: pole consensus (majority ≥2/4), kwota consensus (tolerance 0.01), confidence_conflict detection
- **InvoiceParser**: regex + bbox analysis (header/body/footer/footer pozycjonowanie), Active Learning integracja

### 📱 Frontend (nowa sekcja docs/FRONTEND.md)
- **NexusRouter**: Navigator 2.0, TemplateRoute, RouteGuard, Breadcrumb, URL=State
- **NexusApiClient**: cache (NexusCache), HTTP/2, async API
- **Chart widgets**: 5 typów (Bar/Line/Pie/Doughnut/Radar), zero matplotlib
- **ThemeManager**: Material 3, dark/light, CSS custom properties
- **7 widoków**: Dashboard, DailyBriefing, InvoiceList/Detail, PartnerHub, TaskMonitor, UITriage

### ⚙️ Skrypty CLI (nowa sekcja docs/SCRIPTS.md)
- **NexusOrchestrator**: 4-etapowy splash screen (TigerBeetle → NATS → OPA → DuckDB)
- **Skrypty**: init, download_models (doctr), seed_data, reset_db, backup
- **Worker**: TaskIQ worker z WorkerGuard
- **Build**: Nuitka build przez build_nexus.py

### 🪟 Instalator Windows (nowa sekcja docs/INSTALLER.md)
- **BinaryManager**: platform detection, SHA-256 verification, resume download (Range headers), CachingFileSystem
- **ModelDownloader**: 13 modeli GGUF, SHA-256, resume, progress callback
- **OTA Updater**: version check (GitHub API), resume download, silent install
- **Flet UI**: instalacja zależności z progress barem, Windows native toasty

### ➕ Dodane (ogólne)
- `pixi run rotate-keys` — nowy task do rotacji kluczy (JWT, SQLCipher, backup)
- `pixi run docs-html` — regeneracja dokumentacji HTML
- `pixi run docs-check` — walidacja kotwic w dokumentacji
- `docs/.gitignore` — ignoruje `.archive/`

### 🐛 Poprawione
- **Code Review v1** (6 poprawek): ścieżki, liczniki, linki, duplikacje
- **`docs/generate_pdf.sh`** — naprawiona ścieżka README.md z `../../` na `../`

---

## [2.3.0] — 2026-06-10 — „Free-Threaded Phoenix"

### 🔄 Zmienione
- **Python 3.13.2 free-threaded (3.13t)** — prawdziwa wielowątkowość, -30-40% RAM
- **SQLCipher** — powrót z Limbo (szyfrowanie AES-256)
- **4 silniki OCR** — zamiast jednego VLM (Tesseract + PaddleOCR + docTR + EasyOCR)

### ➕ Dodane
- **5 nowych agentów AI:** Orkiestrator (Granite 3.2 3B), Ekstrakcji Danych, Analityczny (Fin-RWKV), Walidator Jakości (Guardian), Środków Trwałych
- **OPA/Rego** — deterministyczny silnik reguł podatkowych
- **TaxInvariantGuard** — potrójna weryfikacja matematyczna
- **Crosshair** — property-based testing z SMT solverem (zastąpił hypothesis)
- **fsspec + hishel** — abstrakcja systemów plików + inteligentny cache HTTP
- **BillingEstimator + RiskGuard** — dynamiczny cennik i progi ryzyka
- **Flet UI** — interfejs Flutter Material Design 3

### 🗑️ Usunięte
- **Limbo** (brak szyfrowania)
- **hypothesis** (zastąpione przez crosshair)
- **pandas** (zastąpione przez polars)
- **FastAPI + Uvicorn** (zastąpione przez Litestar + Granian)

---

## [2.2.0] — 2026-02-15

### ➕ Dodane
- **Proof Chain SHA-256** — niezmienny łańcuch audytowy
- **TigerBeetle 0.16** — double-entry ledger z kryptograficznymi dowodami
- **NATS JetStream** — at-least-once delivery z DLQ
- **mypyc** — kompilacja Pythona do C (2-5× szybciej)
- **ruff** — linter w Rust (10-100× szybszy)

### 🔄 Zmienione
- **Litestar 2.8** — migracja z FastAPI
- **Granian 1.0** — migracja z Uvicorn

---

## [2.1.0] — 2025-10-01

### ➕ Dodane
- **Agent AI v1** — pierwsza wersja autonomicznego księgowania
- **KSeF integracja** — generowanie i wysyłka FA_VAT(2)
- **Biała Lista MF** — automatyczna weryfikacja
- **GUS BIR** — weryfikacja kontrahentów

---

## [2.0.0] — 2025-06-01

### ➕ Dodane
- **NexusAI Core** — pierwsza wersja platformy księgowej
- **SQLite + SQLModel** — OLTP
- **DuckDB** — OLAP analityka
- **OCR (Tesseract)** — ekstrakcja danych z faktur
- **RBAC** — role: admin, owner, accountant, worker, viewer
- **pixi** — menedżer środowiska

---

## [1.0.0] — 2025-01-15

### ➕ Dodane
- **Proof of Concept** — pierwsze testy koncepcji wirtualnego księgowego

---

## Legenda

- ➕ **Dodane** (Added) — nowa funkcja
- 🔄 **Zmienione** (Changed) — zmiana istniejącej funkcji
- 🗑️ **Usunięte** (Removed) — usunięta funkcja
- 🐛 **Naprawione** (Fixed) — poprawka błędu
- 🔒 **Bezpieczeństwo** (Security) — poprawka bezpieczeństwa
- 📚 **Dokumentacja** (Documentation) — zmiany w dokumentacji

---

## Autorzy

| Wersja | Autor |
|---|---|
| 2.3.1-dev | NexusAI Team (dokumentacja: przebudowa docs/) |
| 2.3.0 | NexusAI Team |
| 2.2.0 | NexusAI Team |
| 2.1.0 | NexusAI Team |
| 2.0.0 | NexusAI Team |
| 1.0.0 | NexusAI Team |

---

## 🔗 Zobacz również

- [00_META](00_META.md) — strona tytułowa dokumentacji z zespołem
- [INDEX](INDEX.md) — spis treści z listą wszystkich 37 plików
- [Architektura](ARCHITECTURE.md) — lista ADR z datami decyzji
- [Proces rozwoju](CONTRIBUTING.md) — zasady wersjonowania SemVer
- [Zgodność z przepisami](COMPLIANCE.md) — zmiany prawne wpływające na kolejne wersje

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 3.0.0-dev
> **Status dokumentu:** Aktywny (dokumentacja w przebudowie) · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** Technical Lead
