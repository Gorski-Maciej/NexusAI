# 🧠 GENIALNY POMYSŁ v7.0: DECYZJE OPARTE NA SKUTKACH BIZNESOWYCH (Business Impact Decisions)

> **"Przedsiębiorca NIE jest księgowym — on podejmuje decyzje w kategoriach pieniędzy i strategii."**
>
> Data: Lipiec 2026 · Status: **Wdrożony** ✅ · Wersja: 7.0.0-draft
>
> **Wdrożenie:** 2026-07-06 — Pełna implementacja w kodzie produkcyjnym NexusAI.

---

## Filozofia: Od Parametrów Księgowych do Kwot i Strategii

### Problem v6.x

W v6.0 Silent Partner agent przejął 100% operacji księgowych i prezentuje wyniki w Executive Dashboard. Jednak gdy przedsiębiorca MUSI podejmować decyzje (np. alerty krytyczne, wyjątki > 100k PLN, pierwszy raz nowy kontrahent), system nadal pokazuje mu:

- Stawki VAT (23%, 8%, 0%, zwolnienie)
- Konta księgowe (WN, MA, PKPiR, KPiR)
- Metody amortyzacji (liniowa, degresywna, jednorazowa)
- Reguły OPA/Rego (split payment, odwrotne obciążenie, MPP)

**Przedsiębiorca nie rozumie tych parametrów.** On myśli w kategoriach: "Ile to kosztuje?", "Czy mam na to pieniądze?", "Czy to zmniejszy podatek?", "Czy to zwiększy wartość firmy?"

### Przełom v7.0

**Business Impact Decisions** — Agent AI przestaje pytać o metody księgowe, a zamiast tego **oblicza i pokazuje realne skutki finansowe każdej opcji.**

```
v6.x (Silent Partner — alert):
  Agent → "Faktura 15 000 PLN. Wybierz metodę księgowania."
  ┌─────────────────────────────────────┐
  │  ⭐ Amortyzacja liniowa (3 lata)   │ ← Parametr księgowy
  │  ○ Amortyzacja jednorazowa         │ ← Parametr księgowy
  │  ○ Odrzuć                          │
  └─────────────────────────────────────┘

v7.0 (Business Impact):
  Agent → "Laptopy 15 000 PLN. Jak chcesz to rozliczyć?"
  ┌─────────────────────────────────────────────┐
  │  ⭐ ZACHOWAJ 2 400 PLN w kasie             │
  │     w tym miesiącu (niższy PIT teraz)      │ ← Kwota + strategia
  │     ── VAT: +920 PLN ──                    │ ← Efekt finansowy
  │                                             │
  │  ○ ROZBUDUJ WARTOŚĆ FIRMY                 │
  │     (koszty rozłożone na 3 lata,          │ ← Strategia biznesowa
  │      lepsza zdolność kredytowa)            │
  │     ── PIT: -340 PLN ──                  │ ← Efekt finansowy
  │                                             │
  │  ❌ To nie mój wydatek                     │
  │                                             │
  │  Agent: "W tym kwartale zwykle             │
  │           chronisz gotówkę"                │ ← Kontekst
  └─────────────────────────────────────────────┘
```

**Kluczowa różnica:** Przycisk pokazuje nie CO zrobi agent (metoda księgowa), ale CO TO ZNACZY dla przedsiębiorcy (kwota w kasie, podatek, wartość firmy).

---

## Perspektywa 1 — Interfejs / UX: Karty Efektu Finansowego

### Financial Impact Cards

Przełom: Przyciski na kartach pokazują nie metody księgowe, ale ich realny wpływ na portfel przedsiębiorcy.

**Wszystkie parametry księgowe (stawka VAT, konto, metoda amortyzacji) → `hidden_payload` — nigdy nie widoczne dla użytkownika.**

#### Przykład: Zakup laptopów 15 000 PLN

```
┌───────────────────────────────────────────────────────────┐
│  📥 Jak chcesz to rozliczyć?                             │
│                                                           │
│  Faktura: ABC Tech — Laptopy — 15 000 PLN               │
│  Trust: ████████████░░ 91%                               │
│                                                           │
│  ╔═════════════════════════════════════════════════════╗ │
│  ║  ⭐ ZACHOWAJ 2 400 PLN w kasie                     ║ │
│  ║     w tym miesiącu (niższy PIT teraz)              ║ │ ← Zielona strzałka ↑
│  ║     ── VAT: +920 PLN ──                            ║ │
│  ║     [CASH_PROTECT] Chroń płynność                  ║ │ ← Badge strategii
│  ╚═════════════════════════════════════════════════════╝ │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  ○ ROZBUDUJ WARTOŚĆ FIRMY                         │ │
│  │     (koszty rozłożone na 3 lata,                 │ │
│  │      lepsza zdolność kredytowa)                   │ │
│  │     ── PIT: -340 PLN ──                          │ │ ← Czerwona strzałka ↓
│  │     [GROWTH] Inwestuj w rozwój                   │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  ❌ To nie mój wydatek                             │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                           │
│  💡 Agent: "W tym kwartale zwykle                       │ │
│             chronisz gotówkę"                            │ │ ← Agent hint
└───────────────────────────────────────────────────────────┘
```

#### Kluczowe elementy wizualne

| Element | Implementacja | Plik |
|---|---|---|
| **Strzałka kierunku** | ↑ zielona (zwiększa cash flow) / ↓ czerwona (zmniejsza) | `decision_feed.py` — `arrow_icon`, `arrow_color` |
| **Kwota wpływu** | `+2 400 PLN` lub `-340 PLN` w PLN | `decision_feed.py` — `cash_impact` |
| **Opis strategii** | "Chroń płynność", "Min. podatek", "Rozwój", "Wyważone" | `decision_feed.py` — `strategy_badge` |
| **Agent hint** | Podpowiedź kontekstowa pod kartą, np. "W Q4 zwykle maksymalizujesz koszty" | `decision_feed.py` — niebieski box z `agent_hint` |
| **Hidden payload** | Pełne parametry księgowe (VAT 23%, konto, metoda) — nigdy nie widoczne | `proactive_workflow.py` — `hidden_payload` |

#### Stany UI

| Stan | Wygląd | Opis |
|---|---|---|
| **Rekomendacja AI** | Zielony przycisk + gwiazdka ⭐ + duża strzałka | Najlepsza opcja wg strategii |
| **Alternatywa** | Szary przycisk + mała strzałka | Inna opcja z innym skutkiem |
| **Odrzucenie** | Czerwony przycisk + X | "To nie mój wydatek" |
| **Agent Hint** | Niebieski box pod kartą | Kontekst strategiczny |

---

## Perspektywa 2 — Agent Intelligence: Uczenie się Strategii

### Progressive Strategy Autonomy

Przełom: Agent uczy się nie co przedsiębiorca klika, ale **dlaczego** — czyli jaką strategię biznesową realizuje.

#### Wymiary uczenia (z 4 na 5)

```
v5.2: 4 wymiary (preferencje taktyczne)
v7.0: 5 wymiarów (preferencje + STRATEGIA)

UserDecisionProfile
├── Vendor Trust
├── Category Preference
├── Amount Threshold
├── Time Pattern
└──  Business Strategy  ← NOWY wymiar v7.0
     ├── CASH_PROTECT (chroń płynność)
     ├── TAX_MINIMIZE (minimalizuj podatek)
     ├── GROWTH (inwestuj w rozwój)
     └── BALANCED (wyważone)
```

#### Jak działa uczenie się strategii

```
1. AgentOrchestrator przed zbudowaniem karty uruchamia
   MultiModelEnsemble by znaleźć WSZYSTKIE prawnie
   dopuszczalne warianty księgowania (nie tylko "najlepszy")

2. Każdy wariant przepuszczany przez AgentAnalytics
   → prognoza skutku finansowego na 30-90 dni
   → Shadow Simulation Engine (DuckDB)

3. UserDecisionProfile obserwuje, że w Q4 przedsiębiorca
   zawsze wybiera opcje maksymalizujące koszty
   → profil TAX_MINIMIZE dla Q4

4. Od tego momentu w Q4 agent AUTO_POST wybiera opcję
   zgodną ze strategią — bez pytania
```

#### Strategie biznesowe

| Strategia | Kiedy aktywna | Efekt na decyzje |
|---|---|---|
| **CASH_PROTECT** | Płynność < 3 miesięcy | Preferuj jednorazowe koszty, opóźniaj wpływy |
| **TAX_MINIMIZE** | Koniec kwartału, wysokie dochody | Maksymalizuj koszty teraz, opóźniaj przychody |
| **GROWTH** | Nadwyżka gotówki, inwestycje | Rozkładaj koszty (lepszy bilans), przyspieszaj wpływy |
| **BALANCED** | Standardowy tryb | Wybierz najprostszą opcję |

#### Podpowiedzi kontekstowe (Agent Hint)

```
Wzorce obserwowane przez agenta:
- Q1-Q3: zwykle wybiera CASH_PROTECT
- Q4: zwykle wybiera TAX_MINIMIZE
- Dla kwot > 50k: zawsze pyta (Amount Threshold)
- Dla znanych vendorów: AUTO_POST bez pytania

Podpowiedź generowana dynamicznie:
  "W tym kwartale zwykle chronisz gotówkę"
  "W Q4 zwykle maksymalizujesz koszty — pasuje do Twojej strategii"
  "Masz nadwyżkę 45k PLN — możesz rozważyć inwestycję"
```

---

## Perspektywa 3 — Architektura: Shadow Simulation Engine

### Shadow Ledger — Równoległe Symulacje w DuckDB

Przełom: DuckDB (już w projekcie!) w tle tworzy **Shadow Ledger** — tymczasową, izolowaną kopię ksiąg, na której w milisekundach symuluje skutki każdego wariantu decyzji.

#### Proces (w tle, niewidoczny dla użytkownika)

```
Agent znajduje 2 warianty księgowania
  │
  ├── Wariant A (amortyzacja jednorazowa)
  │   └── DuckDB Shadow Ledger #1
  │       ├── SELECT symulacja VAT za ten miesiąc
  │       ├── SELECT symulacja PIT za ten kwartał
  │       └── SELECT symulacja cash-flow 30 dni
  │       → Wynik: +2 400 PLN w kasie
  │
  └── Wariant B (amortyzacja liniowa 3 lata)
      └── DuckDB Shadow Ledger #2
          ├── SELECT symulacja VAT za ten miesiąc
          ├── SELECT symulacja PIT za ten kwartał
          └── SELECT symulacja cash-flow 30 dni
          → Wynik: +920 PLN w kasie, lepszy bilans
```

#### Architektura techniczna

| Komponent | Plik | Opis |
|---|---|---|
| **ShadowSimulator** | `nexus_ai/services/shadow_simulator.py` (~80 linii) | Tworzy tymczasowe DuckDB ATTACH, symuluje warianty |
| **ShadowLedger** | `shadow_simulator.py` — `ShadowLedger` class | Izolowana baza DuckDB w RAM (zero plików na dysku) |
| **ShadowSimulationReport** | `models.py` — msgspec struct | Wynik symulacji: VAT, PIT, cash-flow per wariant |
| **ShadowVariant** | `models.py` — msgspec struct | Pojedynczy wariant: nazwa, parametry, skutki |
| **FinancialImpactOption** | `models.py` — msgspec struct | Opcja dla UI: label, description, cash_flow_impact, strategy |

#### Kluczowe cechy techniczne

1. **DuckDB ATTACH** tymczasowej bazy jako Shadow Ledger — zero wpływu na TigerBeetle (oficjalne księgi)
2. **Python 3.13t free-threaded** → 2-4 symulacje równolegle bez narzutu procesów
3. **Wyniki serializowane przez msgspec** w mikrosekundach → NATS → Flet UI
4. **Po kliknięciu:** tylko wybrany wariant trafia do TigerBeetle jako oficjalny zapis
5. **Całość działa w RAM-ie**, nie tworzy plików na dysku (`:memory:` + ATTACH)

#### Pipeline danych

```
AgentDecision
  │
  ▼
extract_invoice_data() → dict z amount_gross, vat_rate, nip
  │
  ▼
ShadowSimulator.simulate(invoice_data, variants)
  ├── Tworzy ShadowLedger #1 (ATTACH ':memory:')
  ├── Tworzy ShadowLedger #2 (ATTACH ':memory:')
  ├── Równoległe symulacje (ThreadPoolExecutor)
  └── Zwraca ShadowSimulationReport
  │
  ▼
simulation_to_financial_options(report, decision)
  ├── Konwertuje warianty na FinancialImpactOption
  ├── Dobiera label biznesowy (zamiast księgowego)
  └── Dobiera strategię (CASH_PROTECT, TAX_MINIMIZE, ...)
  │
  ▼
generate_financial_impact_card(financial_options, agent_hint)
  ├── Tworzy ActionCard z title="Jak chcesz to rozliczyć?"
  ├── Opcje z kwotami, strzałkami, badge'ami strategii
  └── hidden_payload z pełnymi parametrami księgowymi
  │
  ▼
DecisionFeedView renderuje kartę z:
  ├── Strzałkami (↑/↓) + kolorami
  ├── Kwotami cash flow
  ├── Badge'ami strategii
  └── Agent hint w niebieskim boxie
```

---

## Implementacja

### Nowe / zmodyfikowane pliki (✅ = wdrożone)

| Plik | Status | Opis |
|---|---|---|
| **`nexus_ai/services/shadow_simulator.py`** | ✅ **WDROŻONY** (~80 linii) | Shadow Simulation Engine: DuckDB ATTACH, równoległe symulacje |
| **`nexus_ai/agents/user_decision_profile.py`** | ✅ **WDROŻONY** (~50 linii) | StrategyProfile: 4 strategie, obserwacja Q4, get_strategy_for_quarter() |
| **`nexus_ai/agents/orchestrator.py`** | ✅ **WDROŻONY** (~100 linii) | Bridge: simulate → financial_options → card + agent_hint generation |
| **`nexus_ai/agents/proactive_workflow.py`** | ✅ **WDROŻONY** (~60 linii) | generate_financial_impact_card: ActionCard z kwotami i strategią |
| **`nexus_ai/frontend/views/decision_feed.py`** | ✅ **WDROŻONY** (~80 linii) | Renderowanie: strzałki, kwoty, badge strategii, agent hint |
| **`nexus_ai/agents/models.py`** | ✅ **ROZSZERZENIE** | ShadowLedger, ShadowVariant, ShadowSimulationReport, FinancialImpactOption, BusinessStrategy |

### Schemat integracji

```
┌─────────────────────────────────────────────────────────────┐
│                        UŻYTKOWNIK                           │
│                    (widzi kwoty i strategie)                │
└─────────────────────────────┬───────────────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  DecisionFeedView  │
                    │  (Flet UI)         │
                    │  strzałki, kwoty,  │
                    │  badge, agent hint │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │ ActionCardGenerator│
                    │ generate_financial_│
                    │ impact_card()      │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │ AgentOrchestrator  │
                    │ generate_financial_│
                    │ impact_card()      │
                    │ (bridge)           │
                    └─────────┬──────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
    ┌─────▼─────┐      ┌──────▼──────┐     ┌─────▼─────┐
    │ ShadowSim-│      │ StrategyProf-│     │ simulation│
    │ ulator    │      │ ile         │     │ _to_finan-│
    │ (DuckDB)  │      │ (Q4, cash)  │     │ cial_opts │
    └───────────┘      └─────────────┘     └───────────┘
```

### Metryki sukcesu v7.0

| Metryka | Cel | Jak mierzyć |
|---|---|---|
| **Strategic Understanding** | 90% użytkowników rozumie kartę bez wyjaśnienia | A/B test: czas do kliknięcia |
| **Decision Speed** | < 5s na kartę (zamiast 15s w v6.x) | Telemetry: time-to-click |
| **Strategy Learning Accuracy** | 85% poprawnie przypisanych strategii | Validation: ręczna weryfikacja profilu |
| **Shadow Sim. Performance** | < 200ms dla 3 wariantów | Benchmark: pomiar w orchestratorze |
| **Auto-Post by Strategy** | 60% decyzji bez pytania (po 2 tygodniach) | Telemetry: ASK_USER / AUTO_POST ratio |

### Podsumowanie: 3 perspektywy, 1 koncept

| Perspektywa | Co się zmienia | Co NIE zmienia się |
|---|---|---|
| **UX (Flet)** | Etykiety księgowe → kwoty i skutki biznesowe | Karty, AnimatedSwitcher, Trust Score bar, NATS subscriber |
| **Agent (AI)** | Uczenie nawyków → uczenie strategii | 5 agentów, Decision Protocol, KnowledgeMesh, ULP |
| **Architektura** | DuckDB Shadow Ledger z symulacjami równoległymi | TigerBeetle, SQLite, NATS, Litestar, Granian |

**Efekt końcowy:** Przedsiębiorca widzi 2-3 opcje wyrażone wyłącznie w złotówkach i strategii. Klika jedną. Nigdy nie widzi konta księgowego, stawki VAT, metody amortyzacji ani reguły OPA. Agent uczy się dlaczego wybrał tę opcję i następnym razem sam ją stosuje. System w tle symuluje wszystkie warianty matematycznie — bez Excela, bez formularzy, bez parametrów.

---

> **Data utworzenia:** 2026-07-06 · **Autor:** NexusAI Team · **Wersja:** 7.0.0-draft
> **Status dokumentu:** Wdrożony ✅ (wszystkie perspektywy zaimplementowane)
> **Ostatnia aktualizacja:** 2026-07-06
