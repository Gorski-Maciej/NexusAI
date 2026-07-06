# 🤖 System Agentów AI NexusAI — Specyfikacja Enterprise (v6.0)

> **"Autonomiczne Biuro Księgowe — 5 Agentów, 13 Modeli, Silent Partner v6.0"**

> **"Autonomiczne Biuro Księgowe — 5 Agentów, 13 Modeli, Decision Protocol v5.4"**
>
> **Cel:** Umożliwić developerowi zrozumienie pełnego systemu agentów AI w 15 minut.
> **Kiedy czytać:** Przed implementacją nowego agenta, debugowaniem decyzji, lub dodawaniem modelu AI.
> **Podstawa:** `docs/aa3fvcx.txt` + `RAPORT_TECHNOLOGII_NEXUSAI.txt`

---

## 1. Wizja systemu — Autonomiczne Biuro Księgowe

### 1.1 Filozofia architektury

System agentów AI został zaprojektowany jako **AUTONOMICZNE BIURO KSIĘGOWE** — zestaw **5 wyspecjalizowanych agentów**, które:

- **DZIAŁAJĄ W TLE** — użytkownik nie musi wiedzieć, który agent przetwarza fakturę
- **PODEJMUJĄ DECYZJE** — w zielonej strefie (Trust Score ≥ 0.92) agenci samodzielnie księgują
- **UCZĄ SIĘ** — każda korekta użytkownika jest natychmiast wykorzystywana do poprawy przyszłych decyzji (Cognitive Audit Trail)
- **KOORDYNUJĄ APLIKACJĘ** — sterują UI (Flet), kolejką zadań (Taskiq), NATS i bazami danych
- **SĄ ODPORNE** — każda decyzja przechodzi przez minimum 2 niezależne modele (architektura "zero trust to a single model")

### 1.2 GENIALNY POMYSŁ v5.0: ProactiveWorkflowScheduler — Autonomiczny Silnik Proaktywnych Workflow

**Przełom:** Agenci przestają być REAKTYWNI (czekają na fakturę) — stają się PROAKTYWNYMI zarządcami całego cyklu księgowego.

```
❌ PRZED (reaktywny):
   Użytkownik wrzuca fakturę → Agent przetwarza → Koniec

✅ PO (proaktywny ENTERPRISE):
   06:00 AgentAnalytics budzi się → Daily Briefing
   07:00 AgentDataExtraction → pobiera nowe faktury z KSeF
   08:00 AgentAnalytics → synchronizuje konto bankowe
   09:00 AgentOrchestrator → kontrola należności (dunning)
   10:00 AgentAnalytics → weryfikuje kontrahentów (Biała Lista MF)
   14:00 AgentQualityValidator → alerty podatkowe (ZUS, VAT, PIT)
   16:00 AgentOrchestrator → przygotowuje paczkę przelewów
   18:00 AgentAnalytics → wieczorne podsumowanie dnia
   22:00 ResourceOptimizer → auto-unload nieużywanych modeli
```

**Architektura ProactiveWorkflowScheduler:**
```
AgentOrchestrator (CFO)
  └── ProactiveWorkflowScheduler
        ├── WorkflowManager      — zarządzanie cyklem życia workflow, historia, statystyki
        ├── ResourceOptimizer    — auto-unload modeli (RAM/CPU), dynamiczne skalowanie workerów
        ├── TaxDeadlineMonitor   — alerty ZUS, VAT, PIT/CIT, KSeF
        ├── PaymentScheduler     — przygotowanie paczek przelewów
        ├── VendorMonitor        — monitoring kontrahentów (zmiany kont, VAT)
        └── HealthGuardian       — monitoring agentów, auto-restart
```

**Harmonogram proaktywny (16 workflow przez Taskiq Scheduler):**

| Godzina | Workflow | Agent | Opis |
|---|---|---|---|
| 06:00 | Daily Briefing | Orchestrator | Poranne podsumowanie dla przedsiębiorcy |
| 07:00 | KSeF Fetch | Extraction | Pobranie nowych faktur z KSeF |
| 08:00 | Bank Sync | Analytics | Synchronizacja konta bankowego |
| 09:00 | Dunning Check | Orchestrator | Windykacja automatyczna |
| 10:00 | Vendor Monitor | Analytics | Biała Lista MF, zmiany kont |
| 12:00 | Compliance Scan | Quality | Skan OPA, RODO, KSeF |
| 14:00 | Tax Deadline Alert | Quality | Alerty ZUS, VAT, PIT/CIT |
| 16:00 | Payment Batch | Orchestrator | Przygotowanie paczki przelewów |
| 18:00 | Evening Summary | Orchestrator | Wieczorne podsumowanie |
| 22:00 | Resource Optimizer | System | Auto-unload modeli |
| 03:00 | Auto Backup | System | Backup zaszyfrowany |
| */30 min | Health Check | System | Monitoring agentów i zasobów |
| Pon. 07:00 | Weekly Report | Analytics | P&L, DSO, top kontrahenci |
| 1. dzień mies. | Monthly Closing | Orchestrator | Uzgodnienia, amortyzacja |
| 10, 20, 25 | Tax Calendar | Quality | Kalendarz podatkowy |
| Ostatnie dni | Month-End Closing | Orchestrator | Zamknięcie miesiąca |

**Implementacja:**
- **Plik:** `nexus_ai/agents/proactive_workflow.py` (~950 linii)
- **Zadania cron:** 8 nowych tasków Taskiq w `nexus_ai/agents/tasks.py`
- **Integracja:** `AgentOrchestrator.proactive_scheduler` — property dostępu
- **API:** `execute_proactive_workflow()`, `get_proactive_schedule()`, `get_proactive_stats()`

**Kluczowe cechy ENTERPRISE:**
- **WorkflowManager** — historia wykonań, statystyki success/failure, deduplikacja (was_executed_recently z dynamicznym cooldownem)
- **Decision Feed Refresh (co 30 min)** — automatyczne odświeżanie feedu kart decyzyjnych
- **ResourceOptimizer** — monitorowanie RAM/CPU przez psutil, auto-unload idle modeli, dynamiczne skalowanie workerów
- **16 workflow** — codzienne, tygodniowe, miesięczne, z priorytetami i eskalacją
- **Tax Deadline Alert** — konfigurowalne dni alertów (klasy TAX_DEADLINE_*_DAYS)

### 1.2c GENIALNY POMYSŁ v5.2: Progressive Autonomy — Agent, Który Rośnie z Przedsiębiorcą

**Przełom:** Agent nie tylko reaguje i proponuje — OBSERWUJE jak przedsiębiorca podejmuje decyzje i ADAPTUJE się do jego stylu. Im więcej decyzji, tym więcej agent przejmuje automatycznie.

```
TYDZIEŃ 1:  0% autonomii — wszystkie decyzje przez Action Cards
TYDZIEŃ 2: 40% — rutynowe faktury od znanych kontrahentów → AUTO_POST
TYDZIEŃ 4: 70% — większość decyzji automatyczna
MIESIĄC 3: 90%+ — przedsiębiorca widzi tylko wyjątki
```

**Cztery wymiary uczenia:**
1. **Vendor Trust** — "Zawsze akceptujesz faktury od XYZ" → obniżony próg AUTO_POST
2. **Category Preference** — "Zawsze wybierasz amortyzację liniową dla IT" → domyślna sugestia
3. **Amount Threshold** — "Sprawdzasz ręcznie wszystko > 20k PLN" → adaptacyjne progi
4. **Time Pattern** — "W piątki odrzucasz wszystko" → mniej kart w piątki

**Kluczowa metryka:**
```
Decision Autonomy Score = AUTO_POST / (AUTO_POST + ASK_USER) × 100%

Start:  0%   (wszystko przez karty)
Tydzień 2: 40%
Tydzień 4: 70%
Miesiąc 3: 90%+ ← Cel ENTERPRISE
```

**Implementacja:**
- **Plik:** `nexus_ai/agents/user_decision_profile.py` (~400 linii)
- `UserDecisionProfile` — główna klasa z 4 wymiarami uczenia
- `VendorTrustProfile`, `CategoryPreference`, `AmountThreshold` — struktury danych
- `_derive_patterns()` — wyprowadzanie wzorców decyzyjnych po każdej obserwacji
- `generate_weekly_report()` — cotygodniowy raport autonomii
- **Integracja z Orchestratorem:** adaptacyjne progi (`get_adaptive_threshold`), blended Bayesian + Profile, `observe_decision()`

### 1.2d GENIALNY POMYSŁ: DecisionFeedView — Flet UI "1-Click CFO"

**Przełom:** Pełny interfejs Flet dla kart decyzyjnych — przedsiębiorca widzi strumień kart zamiast tabel i formularzy.

**Implementacja:**
- **Plik:** `nexus_ai/frontend/views/decision_feed.py` (~340 linii)
- `DecisionFeedView` — deklaratywny komponent `@ft.component` + `use_state()`
- **Card stack**: jedna karta na raz z `AnimatedSwitcher` (scale transition)
- **3 kolory przycisków**: zielony (⭐ rekomendacja AI), szary (alternatywy), czerwony (odrzuć)
- **Trust Score bar**: `ft.ProgressBar` z kolorowaniem (zielony/pomarańczowy/czerwony)
- **NATS subscriber**: nasłuch `ui.feed.pending` → karty w czasie rzeczywistym
- **NATS publish**: kliknięcie → `ActionCardResponse` na `ui.feed.action`
- **Demo cards**: 3 przykładowe karty gdy NATS offline
- **Stany UI**: loading skeleton, empty state ("Wszystko zaksięgowane! 🎉")
- **Cleanup**: `page.on_close` → NATS drain

```
┌─────────────────────────────────────────┐
│  📥 Decision Feed          1 / 3        │
│  Dzień dobry! Oto 3 decyzje na dziś.   │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Faktura     Faktura od znanego │    │
│  │              kontrahenta        │    │
│  │  ABC Tech — 4 500 PLN          │    │
│  │  Trust: ██████████░░ 94%       │    │
│  │                                 │    │
│  │  ╔═══════════════════════════╗  │    │
│  │  ║  ⭐ ✅ Zaksięguj          ║  │    │ ← Zielony
│  │  ╚═══════════════════════════╝  │    │
│  │  ┌───────────────────────────┐  │    │
│  │  │  ✏️ Popraw dane           │  │    │ ← Szary
│  │  └───────────────────────────┘  │    │
│  └─────────────────────────────────┘    │
│           ● ● ●  ◀  ▶                   │
└─────────────────────────────────────────┘
```

### 1.2b GENIALNY POMYSŁ v5.1: Action Cards — "Zasada 1-Click CFO"

**Przełom:** Przedsiębiorca NIE widzi 80 parametrów księgowych. Widzi prostą kartę z 2-4 przyciskami. Agent wykonał 95% pracy — użytkownik tylko klika.

```
┌─────────────────────────────────────────┐
│  🤖 Agent: "Kupiłeś laptopy za          │
│   15 000 PLN. Próg przekroczony."       │
│                                         │
│  ╔═══════════════════════════════════╗  │
│  ║  ✅ AMORTYZACJA LINIOWA (3 lata) ║  │ ← Rekomendacja AI
│  ╚═══════════════════════════════════╝  │
│  ┌───────────────────────────────────┐  │
│  │  🔄 Amortyzacja jednorazowa      │  │ ← Alternatywa
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  ❌ Odrzuć — to pomyłka          │  │ ← Reject
│  └───────────────────────────────────┘  │
│  Trust Score: ████████░░ 87%           │
└─────────────────────────────────────────┘

Pod każdym przyciskiem: ukryty payload JSON
z pełnymi parametrami księgowymi. Przedsiębiorca
klika 1 przycisk → system wykonuje resztę.
```

**Implementacja:**
- `ActionCardGenerator` w `proactive_workflow.py` (~300 linii)
- `ActionCard`, `ActionCardOption`, `ActionCardFeed`, `ActionCardResponse` w `models.py`
- `ui.feed.pending` / `ui.feed.action` w NATS (topics.py)
- `generate_action_card()`, `build_daily_decision_feed()`, `handle_user_card_response()` w orchestrator.py
- Qwen3-Nano jako opcjonalny tłumacz NL (prompt zabrania żargonu)

### 1.3 JEDEN poziom automatyzacji (z adaptacyjnymi progami)

| Tryb | Zachowanie | Trust Score |
|---|---|---|
| **AUTO_POST** | Agent samodzielnie księguje, użytkownik informowany | ≥ adaptacyjny próg (0.75-0.92) |
| **SUGGEST** | Agent proponuje decyzję z ostrzeżeniem, użytkownik zatwierdza | ≥ próg - 0.17 |
| **ASK_USER** | Agent pyta użytkownika o decyzję | < próg - 0.17 |

**GENIALNY POMYSŁ v5.2:** Próg AUTO_POST jest teraz adaptacyjny z DWÓCH źródeł:
- **Bayesian Trust Score** — uczy się z poprawności AI per kontrahent
- **UserDecisionProfile** — uczy się z preferencji użytkownika (vendor trust, category, amount)
- Blend: `auto_post_threshold = get_threshold(nip, base=profile.get_adaptive_threshold(nip))`

**Człowiek ZAWSZE jest decydentem.** Agent wykonuje pracę i przedstawia opcje.

### 1.4 GENIALNY POMYSŁ #1: Cognitive Audit Trail (warstwa deterministyczna)

Każda korekta użytkownika tworzy blok poznawczy w łańcuchu dowodowym:
- Embedding korekty → sqlite-vec (768d)
- Podobna faktura → k-NN → automatyczna korekta
- Po 10 korektach tego samego typu → auto-naprawa reguły OPA
- Łańcuch SHA-256 staje się AKTYWNYM systemem uczącym się, nie tylko pasywnym rejestrem

### 1.5 GENIALNY POMYSŁ #2: Dynamiczny Podręcznik Błędów (warstwa probabilistyczna)

Online few-shot learning — model Granite 3.2 uczy się z każdej korekty BEZ fine-tuningu:
- Każda korekta użytkownika → zapisana jako przykład few-shot w DuckDB (`error_handbook`)
- Przed inferencją → kwerenda DuckDB: najbardziej podobne przykłady (ten sam NIP, kategoria, kwota)
- Przykłady wstrzykiwane do promptu jako "Podręcznik Błędów z Przeszłości"
- Model widzi: ❌ co AI zdecydowało błędnie → ✅ co było poprawne
- Im więcej korekt, tym mądrzejszy model — incremental learning
- **v5.4**: dodane `find_similar_by_embedding()` — prawdziwe k-NN przez DuckDB z RAM fallback

```
KOREKTA UŻYTKOWNIKA → DuckDB error_handbook → kwerenda przed inferencją →
→ "Podręcznik Błędów" w prompcie → Granite 3.2 uczy się z przykładów
```

### 1.5e GENIALNY POMYSŁ v5.3: Agent Knowledge Mesh (EASP)

**Przełom:** Agenci przestają działać w izolacji — tworzą SIATKĘ WIEDZY (Knowledge Mesh) z Collective Bayesian Field, Predictive Task Router i Cross-Agent Experience Replay.

```
❌ PRZED (izolowani agenci):
   Każdy agent uczy się osobno, nie dzieli się doświadczeniem

✅ PO (Knowledge Mesh EASP v5.3):
   Agent DataExtraction wykrywa niski konsensus OCR →
   Mesh obniża Trust Score vendora →
   Orchestrator widzi obniżony Trust → podnosi próg AUTO_POST →
   QualityValidator dostaje INCREASE_SCRUTINY →
   Wszyscy agenci wiedzą, że ten vendor jest problematyczny
```

**Cztery komponenty KnowledgeMesh:**

| Komponent | Plik | Opis |
|---|---|---|
| **CollectiveBayesianField** | `knowledge_mesh.py` | Współdzielony Trust Score Beta(α,β) per vendor, aktualizowany przez wszystkie agenty |
| **PredictiveTaskRouter** | `knowledge_mesh.py` | Dynamiczny DAG agentów — wybiera które agenty uruchomić na podstawie Trust Score |
| **CrossAgentExperienceReplay** | `knowledge_mesh.py` | Agenci publikują eventy (`extraction.low_consensus`, `quality.tax_error`, `quality.fraud_detected`) → inne agenty reagują przez CROSS_AGENT_RULES |
| **MeshProtocol** | `knowledge_mesh.py` | Protokół komunikacji mesha: `route()`, `update_trust()`, `share_experience()`, `get_threshold_adjustments()` |

**CROSS_AGENT_RULES — reguły propagacji doświadczeń:**
```
extraction.low_consensus    → QualityValidator: INCREASE_SCRUTINY
quality.tax_error           → Extraction: HIGH_SCRUTINY
quality.tax_error           → Orchestrator: LOWER_AUTO_POST_THRESHOLD
quality.fraud_detected      → ALL: HIGH_ALERT
analytics.anomaly_detected  → QualityValidator: INCREASE_SCRUTINY
analytics.anomaly_detected  → Orchestrator: REVIEW_REQUIRED
```

**Predykcyjny routing (Circuit Breaker):**
- Trust < 0.30 → BLOCK — pomiń wszystkich agentów, wymagaj ręcznej weryfikacji
- Trust ≥ 0.92 → SKIP — pomiń QualityValidator (vendor doskonale znany)
- Trust 0.30-0.92 → standardowy pipeline

**Integracje z agentami (5/5 — pełna siatka):**
- **AgentDataExtraction**: publikuje `extraction.low_consensus` gdy konsensus OCR < 75%, aktualizuje CollectiveBayesianField
- **AgentAnalytics**: publikuje `analytics.anomaly_detected` w 4 tierach (Z-score >3σ, 2-3σ, risk flags, cashflow anomalies), aktualizuje Trust Score
- **AgentQualityValidator**: publikuje `quality.tax_error`, `quality.fraud_detected`, `analytics.anomaly_detected`; aktualizuje Trust Score po każdej walidacji
- **AgentOrchestrator**: używa `PredictiveTaskRouter` do dynamicznego DAG, `get_threshold_adjustments()` do adaptacyjnych progów
- **AgentFixedAssets**: deterministyczny — nie wymaga integracji Mesh

### 1.5g GENIALNY POMYSŁ v6.0: Silent Partner — "Cichy Wspólnik"

**Przełom:** Odwraca paradygmat o 180° — z "Agent pyta → Człowiek odpowiada" (Push) na "Agent robi → Człowiek przegląda" (Pull).

```
Push (v5.x):                    Pull (v6.0):
  Agent → "Zdecyduj!"            Agent → "Zrobiłem. Sprawdź jak chcesz."
  Człowiek → klika               Człowiek → przegląda w 2 min
  Agent → wykonuje               Agent → robi dalej
  Człowiek → następna karta      Człowiek → prowadzi biznes
```

Agent NIE PYTA o decyzje — **PODEJMUJE je wszystkie** (100%). Następnie PREZENTUJE efekt w formie **Executive Summary**. Przedsiębiorca:
- Może zaakceptować wszystko jednym kliknięciem (80% przypadków)
- Może skorygować konkretną pozycję (15% przypadków)
- Może zatrzymać i przeanalizować (5% przypadków)

**Trzy perspektywy, jeden koncept:**

| Perspektywa | Problem v5.x | Rozwiązanie v6.0 |
|---|---|---|
| **UX/Interfejs** | Feed kart wymagających akcji | Executive Dashboard z Accept-All |
| **Agent Intelligence** | Uczy się preferencji (taktyka) | Uczy się strategii (kontekst) |
| **Biznes** | Oszczędza czas na operacjach | Partner w prowadzeniu biznesu |

**Cztery tryby strategiczne (zamiast DecisionMode):**

| Tryb strategiczny | Działanie agenta | Gdy agent ma wątpliwość |
|---|---|---|
| 💰 **Cash Protect** | Maksymalizuj płynność, rozkładaj koszty | Pyta: "Czy to wydatek krytyczny?" |
| 📈 **Growth** | Inwestuj, przyspieszaj amortyzację | Pyta: "Czy to zwiększy przychody?" |
| ⚖️ **Tax Optimal** | Minimalizuj PIT/CIT, rozkładaj dochody | Pyta: "Która opcja podatkowa?" |
| 🎯 **Efficiency** | Najszybsza ścieżka, zero zbędnych kroków | Pyta: "Czy pominiemy walidację?" |

**Pięć wymiarów kontekstu strategicznego (Learning by Context):**

| Wymiar | Co oznacza | Jak wpływa na decyzje |
|---|---|---|
| **Cash Flow Phase** | Wpływy > wydatki vs wydatki > wpływy | Więcej AUTO_POST gdy płynność dobra |
| **Tax Period** | Początek/koniec kwartału, VAT deadline | Więcej SUGGEST przy deadline'ach |
| **Vendor Season** | Sezonowość kontrahentów | Niższy próg dla sezonowych |
| **Growth Phase** | Inwestycja vs konserwacja | Preferencje kosztowe |
| **Macro Context** | Stopy procentowe, inflacja, kursy | Sugestie optymalizacji |

**Executive Dashboard — stany UI:**

| Stan | Co widzi użytkownik | Domyślna akcja |
|---|---|---|
| 🔵 **Normal** | Podsumowanie + "Akceptuj wszystkie" | 1 klik → wszystko zaksięgowane |
| 🟡 **Attention** | 1-2 pozycje oznaczone kolorem | Może kliknąć "Akceptuj" lub "Sprawdź" |
| 🔴 **Alert** | Pilna sprawa z priorytetem | Agent prosi o decyzję |
| ⚪ **Empty** | "Wszystko zaksięgowane. Idź na kawę ☕" | Brak akcji |

**Metryki sukcesu:**

| Metryka | Cel v6.0 | v5.5 |
|---|---|---|
| **Silent Rate** | ≥ 95% | 73% (Autonomy Score) |
| **Faktur na 1 interakcję** | 200+ | 20 |
| **Czas dzienny** | < 30s | 3-5 min |
| **Strategic Queries Ratio** | ≥ 80% | 0% (wszystkie taktyczne) |
| **Accept-All Rate** | ≥ 80% | N/A (brak koncepcji) |

**Implementacja:**
- **Pliki:**
  - `nexus_ai/agents/strategy_engine.py` — Continuous Strategy Engine (~300 linii)
  - `nexus_ai/agents/executive_summary.py` — Executive Summary Generator (~200 linii)
  - `nexus_ai/frontend/views/executive_dashboard.py` — Executive Dashboard (~350 linii)
- **Rozszerzenia:**
  - `nexus_ai/agents/models.py` — StrategicMode, ContextDimension, ExecutiveSummary, DashboardState
  - `nexus_ai/agents/orchestrator.py` — Strategic Pipeline, Silent Mode, Accept-All, build_executive_summary()
  - `nexus_ai/agents/proactive_workflow.py` — 3 nowe workflow: EXECUTIVE_SUMMARY_GENERATION, STRATEGY_REFRESH, SILENT_AUTO_POST
  - `nexus_ai/agents/topics.py` — `ui.executive.summary`

**Integracja z istniejącymi systemami:**

| System v5.x | Rola w v6.0 |
|---|---|
| Action Cards (v5.1) | Tylko dla alertów krytycznych (🔴) |
| Progressive Autonomy (v5.2) | Learning by Context — zamiast preferencji, uczy strategii |
| KnowledgeMesh (v5.3) | Wymiana kontekstu strategicznego między agentami |
| Decision Protocol (v5.4) | Tylko dla transakcji > 100k PLN |
| Proactive Workflow (v5.0) | Silent Mode — wszystkie workflow 24/7 |
| dyscache (v5.5) | Cache dla Executive Summary |

### 1.5h GENIALNY POMYSŁ v7.0: Business Impact Decisions — Decyzje oparte na skutkach biznesowych

**Przełom:** Agent przestaje pytać o metody księgowe (VAT 23%, amortyzacja liniowa), a pokazuje realne skutki finansowe każdej opcji. Przedsiębiorca widzi kwoty, nie parametry.

```
❌ PRZED (v6.x — parametry księgowe):
   ┌──────────────────────────┐
   │  ⭐ Amortyzacja liniowa  │
   │  ○ Amortyzacja jednoraz. │
   │  ○ Odrzuć                │
   └──────────────────────────┘

✅ PO (v7.0 — skutki biznesowe):
   ┌──────────────────────────────────────┐
   │  ⭐ ZACHOWAJ 2 400 PLN w kasie      │
   │     (niższy PIT teraz)               │
   │     ── VAT: +920 PLN ──              │
   │     [CASH_PROTECT] Chroń płynność   │
   │                                       │
   │  ○ ROZBUDUJ WARTOŚĆ FIRMY           │
   │     (koszty rozłożone na 3 lata)     │
   │     ── PIT: -340 PLN ──              │
   │     [GROWTH] Inwestuj w rozwój      │
   │                                       │
   │  💡 "W tym kwartale zwykle           │
   │       chronisz gotówkę"              │
   └──────────────────────────────────────┘
```

**Trzy perspektywy v7.0:**

| Perspektywa | Co się zmienia | Co NIE zmienia się |
|---|---|---|
| **UX (Flet)** | Etykiety księgowe → kwoty i skutki biznesowe | Karty, AnimatedSwitcher, Trust Score bar, NATS subscriber |
| **Agent (AI)** | Uczenie nawyków → uczenie strategii (5. wymiar) | 5 agentów, Decision Protocol, KnowledgeMesh, ULP |
| **Architektura** | DuckDB Shadow Ledger z symulacjami równoległymi | TigerBeetle, SQLite, NATS, Litestar, Granian |

**Shadow Simulation Engine:**
- `ShadowSimulator` w `services/shadow_simulator.py` — DuckDB ATTACH `:memory:`, równoległe symulacje 2-4 wariantów
- `ShadowLedger` — izolowana kopia ksiąg, zero wpływu na TigerBeetle
- Wyniki: VAT, PIT, cash-flow 30-90 dni per wariant
- Python 3.13t free-threaded → symulacje równoległe bez narzutu procesów

**StrategyProfile (5. wymiar uczenia):**
- `BusinessStrategy` enum: CASH_PROTECT, TAX_MINIMIZE, GROWTH, BALANCED
- `StrategyProfile` w `user_decision_profile.py` — obserwuje dlaczego, nie co
- Podpowiedzi kontekstowe: "W Q4 zwykle maksymalizujesz koszty"

**Financial Impact Card rendering:**
- Strzałki (↑/↓) + kolory (zielony/czerwony) w `decision_feed.py`
- Kwota wpływu na cash flow w PLN
- Badge strategii: "Chroń płynność", "Min. podatek", "Rozwój", "Wyważone"
- Agent hint w niebieskim boxie

**Implementacja:**
- **Pliki:** `services/shadow_simulator.py`, `agents/user_decision_profile.py` (StrategyProfile), `agents/orchestrator.py` (bridge), `agents/proactive_workflow.py` (card generator), `frontend/views/decision_feed.py` (rendering)
- **Struktury:** `ShadowLedger`, `ShadowVariant`, `ShadowSimulationReport`, `FinancialImpactOption`, `BusinessStrategy` w `models.py`

### 1.5f GENIALNY POMYSŁ v5.4: Decision Protocol + Unified Learning Protocol

**Przełom:** Każda decyzja jest w pełni śledzona (DecisionTrace z OTel spanami), walidowana przez MultiModelEnsemble (≥2 modele), kalibrowana (Platt Scaling), a każda korekta uruchamia kaskadę 5 systemów uczących się jednocześnie.

**DecisionTrace — pełny tracing decyzji (OTel):**
```
DecisionTrace
├── Span: cache_check          — sprawdzenie Decision Cache
├── Span: mesh_route           — predykcyjny routing KnowledgeMesh
├── Span: extraction           — OCR + ekstrakcja
├── Span: handbook_query       — Dynamiczny Podręcznik Błędów
├── Span: actor_inference      — Granite 3.2 Actor
├── Span: guardian_check       — Granite Guardian
├── Span: ensemble             — MultiModelEnsemble (Actor + Guardian + Handbook)
├── Span: quality_validation   — QualityValidator (tax + fraud + ESG)
├── Span: calibration          — ConfidenceCalibrator (Platt Scaling)
└── Span: final_decision       — AUTO_POST / SUGGEST / ASK_USER
```

**MultiModelEnsemble (≥2 modele):**
- Actor (Granite 3.2 3B) — główny decydent
- Guardian (Granite Guardian 0.5B) — strażnik merytoryczny
- Handbook (DynamicErrorHandbook) — few-shot examples
- Diversity check: jeśli wszystkie modele dają ten sam werdykt → ostrzeżenie o braku dywersyfikacji
- Fallback: jeśli <2 modele dostępne → requires_human=True

**ConfidenceCalibrator (Platt Scaling):**
- Kalibruje surowy Trust Score przez online Platt Scaling (SGD, decay rate 0.99)
- Eliminuje overconfidence modeli ("model mówi 95% ale w rzeczywistości ma 80%")
- Reliability diagram: 10-binowy wykres kalibracji

**AgentTelemetryStore (DuckDB + Parquet):**
- 5 tabel: decisions, corrections, routes, traces, feedback
- Eksport do Parquet dla długoterminowej analityki
- Metryki: time-to-decision, correction_rate, decision_quality_score

### 1.6 Kaskada 5 Systemów — Unified Learning Protocol v5.4

**Problem:** W v5.2 każdy z 5 mechanizmów uczenia działa w izolacji. Korekta użytkownika aktualizuje Handbooka, ale NIE aktualizuje Bayesian Field mesha.

**Rozwiązanie: KASKADA 5 systemów po każdej korekcie:**
```
KOREKTA UŻYTKOWNIKA
  │
  ├─→ 1. DynamicErrorHandbook.record_correction()
  │     Zapisz przykład few-shot w DuckDB + embedding sqlite-vec
  │
  ├─→ 2. ContinuousLearningProvider.record_feedback()
  │     Aktualizuj BayesianTrustScore per agent
  │     Utwórz CognitiveProofBlock z embeddingiem
  │
  ├─→ 3. KnowledgeMesh.update_trust()
  │     Aktualizuj CollectiveBayesianField per vendor
  │     Utwórz Cross-Agent Experience Rules
  │
  ├─→ 4. UserDecisionProfile.observe_decision()
  │     Aktualizuj 4 wymiary (vendor trust, category, amount, time)
  │     Wyprowadź nowe wzorce decyzyjne
  │
  └─→ 5. AgentTelemetryStore.record_correction()
        Zapisz do DuckDB/Parquet dla analityki
```

**Architektura komunikacji (zaktualizowana):**
```
U[Użytkownik / Flet UI] -->|REST| API[Litestar API]
API -->|NATS JetStream| O[AgentOrchestrator]
O -->|NATS| E[AgentDataExtraction — OCR + KSeF + Mesh]
O -->|NATS| A[AgentAnalytics — cashflow + vendor intel]
O -->|NATS| Q[AgentQualityValidator — tax + fraud + ESG + Mesh]
O -->|NATS| FA[AgentFixedAssets — amortyzacja]
O -->|KnowledgeMesh| MESH[CollectiveBayesianField + PredictiveTaskRouter]
E -->|DuckDB + SQLite| DB[(Bazy danych)]
Q -->|OPA/Rego| OPA[Silnik reguł]
O -->|DecisionTrace| TRACE[OTel Tracing]
O -->|TelemetryStore| TELEM[(DuckDB + Parquet)]
```

### 1.7 Stos technologiczny agentów

```
U[Użytkownik / Flet UI] -->|REST| API[Litestar API]
API -->|NATS JetStream| O[AgentOrchestrator]
O -->|NATS| E[AgentDataExtraction — OCR + KSeF]
O -->|NATS| A[AgentAnalytics — cashflow + vendor intel]
O -->|NATS| Q[AgentQualityValidator — tax + fraud + ESG]
O -->|NATS| FA[AgentFixedAssets — amortyzacja]
E -->|DuckDB + SQLite| DB[(Bazy danych)]
Q -->|OPA/Rego| OPA[Silnik reguł]
O -->|TigerBeetle| TB[Księga główna]
```

### 1.7 Stos technologiczny agentów

| Technologia | Rola |
|---|---|
| **llama-cpp-python** | Inferencja modeli GGUF (CPU/GPU) |
| **NATS JetStream + Taskiq** | Komunikacja między agentami |
| **DuckDB** | Pamięć episodyczna i analityka |
| **SQLite + sqlite-vec** | Pamięć semantyczna (wektory) + Cognitive Audit Trail |
| **TigerBeetle** | Księga główna (double-entry) |
| **msgspec** | Wszystkie struktury danych |
| **stamina** | Circuit breaker i retry — chroni KSeF, Białą Listę, GUS BIR, NBP, OPA |
| **nexus-crypto** | Proof chain kryptograficzny (SHA-256) |
| **OPA + Rego** | Deterministyczny silnik reguł (auto-naprawiany) |
| **DuckDB + Parquet** | Telemetria agentów (AgentTelemetryStore v5.4) |
| **Platt Scaling** | Kalibracja Trust Score (ConfidenceCalibrator v5.4) |
| **dyscache** | Dwupoziomowy cache L1 (RAM) + L2 (SQLite) — zastąpił diskcache w DecisionCache |

---

## 2. Pięciu agentów AI — katalog

### 2.1 AgentOrchestrator — Centralny Mózg i Wirtualny CFO

**Rola:** Naczelny dyrektor finansowy. Koordynuje 4 agentów, podejmuje ostateczne decyzje, komunikuje się z użytkownikiem.

| Parametr | Wartość |
|---|---|
| **Model główny** | Granite 3.2 3B (GGUF, IQ4_XS) |
| **Model strażnika** | Granite Guardian 0.5B (GGUF, Q4_K_M) |
| **Model komunikatora** | Qwen3-Nano 0.5B (GGUF, Q4_K_M) |
| **RAM stały** | ~2.98 GB |
| **Plik** | `nexus_ai/agents/orchestrator.py` |

**Kluczowe mechanizmy:**
- **Dynamiczny Trust Score** — aktualizowany Bayesiańsko po każdej decyzji
- **Decision Cache** — każda decyzja wektoryzowana w sqlite-vec, k-NN (k=5)
- **Cognitive Audit Trail** — korekty → embeddingi → auto-naprawa reguł OPA
- **Adaptive Thresholds** — progi AUTO_POST/SUGGEST dynamiczne per kontrahent
- **Proof Chain SHA-256** — niepodważalny dowód dla organów skarbowych
- **4-Eyes Principle** — obowiązkowy dla kwot > 50k PLN

**Proces decyzyjny (10+ kroków — Decision Protocol v5.4):**
1. DecisionTrace: rozpocznij OTel trace dla decyzji
2. KnowledgeMesh: predykcyjny routing (Circuit Breaker, SKIP/BLOCK agentów)
3. Decision Cache: k-NN w podobnych decyzjach
4. AgentDataExtraction → ekstrakcja (4 silniki OCR) + `_publish_mesh_events()`
5. Dynamiczny Podręcznik Błędów → pobierz podobne korekty z DuckDB
6. MultiModelEnsemble: Actor (Granite 3.2) + Guardian + Handbook few-shot
7. AgentQualityValidator → walidacja (tax + fraud + ESG + forecast) + `_publish_mesh_events()`
8. ConfidenceCalibrator: Platt Scaling kalibracja Trust Score
9. Cognitive Audit Trail → sprawdź podobne korekty
10. AgentTelemetryStore → zapisz decyzję do DuckDB/Parquet
11. Ostateczna decyzja: AUTO_POST / SUGGEST / ASK_USER

### 2.2 AgentDataExtraction — Forteca Precyzji

**Rola:** Ekstrakcja danych z dokumentów + obsługa KSeF. Precyzja przewyższająca profesjonalnego księgowego.

| Parametr | Wartość |
|---|---|
| **Silniki OCR** | Tesseract 5.3 + PaddleOCR + Surya OCR |
| **Model walidacji** | Granite Vision Guardian 0.3B + ModernBERT-NER-Finance 0.3B |
| **Klasyfikacja** | ParagonDetect 0.1B (CNN, ONNX) |
| **RAM stały** | ~100 MB |
| **RAM doraźny** | ~500 MB (OCR) |
| **Plik** | `nexus_ai/agents/extraction.py` |

**Kluczowe mechanizmy:**
- **Cross-Validation Matrix (4×4)** — każde pole z 4 silników niezależnie
- **OCR Online Learning** — korekty → embeddingi → k-NN
- **Invoice Template Matching** — wzorce per kontrahent
- **KSeF Integration** — automatyczna wysyłka/odbiór FA(1)/FA(2)
- **Semantyczna walidacja** — NIP, IBAN, kwoty, daty
- **🆕 KnowledgeMesh Integration (v5.3 → v5.5)** — publikuje `extraction.low_consensus` gdy konsensus OCR < **75%** (poprawiony próg: usunięto `and confidence < 0.7`), aktualizuje CollectiveBayesianField

### 2.3 AgentAnalytics — Sztab Analityczny

**Rola:** Analiza kondycji finansowej, prognozy cash flow, wywiad gospodarczy.

| Parametr | Wartość |
|---|---|
| **Model SQL** | Hrida-T2SQL-128k (GGUF, IQ3_M) |
| **Model analityczny** | Granite 3.2 3B (GGUF, IQ4_XS) |
| **Model detekcji** | Fin-RWKV-169M (GGUF, Q4_K_M) |
| **Model prognozy** | Lag-Llama 0.3B (GGUF, Q4_K_M) |
| **RAM stały** | ~100 MB |
| **RAM doraźny** | ~1.0 GB (T2SQL) |
| **Plik** | `nexus_ai/agents/analytics.py` |

**Kluczowe mechanizmy:**
- **Cash Flow Forecast (90 dni)** — 3 scenariusze
- **Vendor Intelligence** — Biała Lista MF, GUS BIR, risk score 0-100
- **Anomaly Detection** — Z-score, IQR, Mahalanobis, Isolation Forest
- **Daily Brief** — codzienne podsumowanie NL
- **Automatyczne raporty** — dzienne/tygodniowe/miesięczne
- **🆕 KnowledgeMesh Integration (v5.5)** — publikuje `analytics.anomaly_detected` w 4 tierach:
  1. 🔴 Z-score > 3σ → QV TRIGGER_DEEP_CHECK + Orch LOWER_THRESHOLD + update_trust
  2. 🟡 Z-score 2-3σ → event (bez obniżania Trust)
  3. ⚠️ Risk flags (overdue/high_amount) → event + update_trust
  4. 💰 Cashflow/forecast → event z detection_method="cashflow_analysis"

### 2.4 AgentQualityValidator — Trójwarstwowa Tarcza

**Rola:** Niezależny audytor. Weryfikuje KAŻDĄ decyzję przed wykonaniem.

| Parametr | Wartość |
|---|---|
| **Model podatkowy** | Granite Guardian 0.5B (GGUF, Q4_K_M) |
| **Model fraud** | GraphSAGE-Encoder 0.1B (ONNX) |
| **Model ryzyka** | FinBERT-ESG 0.1B (GGUF, Q4_K_M) |
| **Model płynności** | Lag-Llama 0.3B (GGUF, Q4_K_M) |
| **RAM stały** | ~670 MB |
| **RAM doraźny** | ~350 MB (Lag-Llama) |
| **Plik** | `nexus_ai/agents/quality_validator.py` |

**Kluczowe mechanizmy:**
- **Tax Compliance** — VAT, PIT, CIT, split payment (OPA/Rego — auto-naprawiany)
- **Fraud Graph Scanner** — grafy powiązań (GraphSAGE): karuzele VAT, słupy
- **ESG Risk Analysis** — ocena ryzyka kontrahenta
- **Liquidity Stress Test** — Monte Carlo 1000 scenariuszy
- **4-Eyes Principle** — obowiązkowy dla kwot > 50k PLN
- **Weighted Voting** — Tax: 0.35, Fraud: 0.30, ESG: 0.20, Forecast: 0.15
- **🆕 KnowledgeMesh Integration (v5.3)** — publikuje `quality.tax_error`, `quality.fraud_detected`, `analytics.anomaly_detected`; aktualizuje Trust Score po każdej walidacji

### 2.5 AgentFixedAssets — Zarządca Majątku

**Rola:** Automatyczna klasyfikacja, amortyzacja i ewidencja środków trwałych.

| Parametr | Wartość |
|---|---|
| **Model** | Amortyzator-KŚT 0.2B (deterministyczny + AI) |
| **RAM doraźny** | ~200 MB |
| **Plik** | `nexus_ai/services/fixed_assets.py` |

**Kluczowe mechanizmy:**
- **Auto-Classification** — ŚT vs materiał vs usługa (>10k PLN, >1 rok)
- **Depreciation Engine** — liniowa, degresywna, jednorazowa
- **TigerBeetle** — miesięczne odpisy w księdze głównej

---

## 3. Decision Engine — Silnik Decyzyjny

### 3.1 Dynamiczne progi decyzyjne

```
auto_post_threshold = 0.92 - adjustment
adjustment = (α_vendor - β_vendor) / (α_vendor + β_vendor) × 0.1
```

| Kontrahent | auto_post_threshold |
|---|---|
| Znany (100 faktur) | 0.824 |
| Nowy (5 faktur) | 0.86 |
| Podejrzany (10 faktur) | 0.90 |

### 3.2 Konsensus między agentami

| Agent | Waga |
|---|---|
| AgentOrchestrator | 0.40 |
| AgentQualityValidator | 0.60 (niezależny audytor) |

### 3.3 Cognitive Audit Trail

```
DECYZJA → KOREKTA → EMBEDDING (sqlite-vec) → k-NN → AUTO-NAPRAWA OPA
```

Po 10 korektach tego samego typu → automatyczna aktualizacja reguł OPA/Rego.

---

## 4. Modele AI — tabela (13 modeli, 5 agentów)

| Agent | Modele | RAM stały | RAM doraźny |
|---|---|---|---|
| **Orkiestrator** | Granite 3.2 3B, Guardian 0.5B, Qwen3-Nano 0.5B | ~2.98 GB | — |
| **Ekstrakcji** | ParagonDetect 0.1B, Vision Guardian 0.3B, ModernBERT 0.3B | ~100 MB | ~500 MB |
| **Analityczny** | Fin-RWKV-169M | ~100 MB | ~1.0 GB |
| **Walidator** | Guardian 0.5B, GraphSAGE 0.1B, FinBERT-ESG 0.1B | ~670 MB | ~350 MB |
| **Środki Trwałe** | Amortyzator-KŚT 0.2B | — | ~200 MB |

**Łącznie:** ~3.85 GB stałego RAM, peak ~5.9 GB (w budżecie 6 GB).

---

## 🔗 Zobacz również

- [Architektura systemu](ARCHITECTURE.md) — C4, ADR, wzorce projektowe
- [Moduły i logika](MODULES.md) — serwisy biznesowe, pipeline OCR
- [Bezpieczeństwo](SECURITY.md) — model zagrożeń, szyfrowanie, RBAC
- [aa3fvcx.txt](aa3fvcx.txt) — blueprint architektury agentów (źródło)

---

> **Ostatnia aktualizacja:** 2026-07-06 · **Wersja:** 6.0.0-draft — "Silent Partner — Cichy Wspólnik"
> **Podstawa:** `docs/aa3fvcx.txt` + `RAPORT_TECHNOLOGII_NEXUSAI.txt` + `docs/GENIALNY_POMYSL_v6_SILENT_PARTNER.md`
