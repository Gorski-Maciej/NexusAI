# 🤖 System Agentów AI NexusAI — Specyfikacja Enterprise (v5.2)

> **"Autonomiczne Biuro Księgowe — 5 Agentów, 13 Modeli, Progressive Autonomy"**
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

```
KOREKTA UŻYTKOWNIKA → DuckDB error_handbook → kwerenda przed inferencją →
→ "Podręcznik Błędów" w prompcie → Granite 3.2 uczy się z przykładów
```

### 1.6 Architektura komunikacji

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
| **stamina** | Circuit breaker i retry |
| **nexus-crypto** | Proof chain kryptograficzny (SHA-256) |
| **OPA + Rego** | Deterministyczny silnik reguł (auto-naprawiany) |

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

**Proces decyzyjny (7 kroków):**
1. Decision Cache: k-NN w podobnych decyzjach
2. AgentDataExtraction → ekstrakcja (4 silniki OCR)
3. Actor (Granite 3.2) + Guardian (Granite Guardian) → ocena
4. AgentQualityValidator → walidacja (tax + fraud + ESG + forecast)
5. Weighted Voting → konsensus
6. Cognitive Audit Trail → sprawdź podobne korekty
7. Ostateczna decyzja: AUTO_POST / SUGGEST / ASK_USER

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

> **Ostatnia aktualizacja:** 2026-07-05 · **Wersja:** 5.2.0 — "Progressive Autonomy + DecisionFeedView"
> **Podstawa:** `docs/aa3fvcx.txt` + `RAPORT_TECHNOLOGII_NEXUSAI.txt`
