# 🧠 GENIALNY POMYSŁ v6.0: CICHY WSPÓLNIK (Silent Partner)

> **"Agent prowadzi księgowość. Ty prowadzisz biznes."**
>
> Data: Lipiec 2026 · Status: **Wdrożony** ✅ · Wersja: 6.0.0-draft
>
> **Wdrożenie:** 2026-07-06 — Pełna implementacja w kodzie produkcyjnym NexusAI.

---

## Filozofia: Od "Decyduj" do "Oceń"

### Problem v5.x

NexusAI osiągnął w v5.5 niespotykany poziom autonomii — agenci sami pobierają faktury, weryfikują kontrahentów, księgują i uczą się z korekt. Jednak FUNDAMENTALNY paradygmat pozostaje ten sam:

**Agent pyta → Człowiek odpowiada.**

Nawet najlepsze Action Cards (v5.1) i Progressive Autonomy (v5.2) to wciąż model **push**: system wysyła do przedsiębiorcy kartę i mówi "zdecyduj". Nawet jeśli tylko 1 na 20 faktur wymaga decyzji, to wciąż 1 za dużo dla przedsiębiorcy, który chce prowadzić biznes, a nie być operatorem księgowości.

### Przełom v6.0

**Cichy Wspólnik** odwraca ten paradygmat o 180°:

```
Push (v5.x):                    Pull (v6.0):
  Agent → "Zdecyduj!"            Agent → "Zrobiłem. Sprawdź jak chcesz."
  Człowiek → klika               Człowiek → przegląda w 2 min
  Agent → wykonuje               Agent → robi dalej
  Człowiek → następna karta      Człowiek → prowadzi biznes
```

Agent NIE PYTA o decyzje — **PODEJMUJE je wszystkie** (100%). Następnie PREZENTUJE efekt swojej pracy w formie **Executive Summary**. Przedsiębiorca może:
- Zaakceptować wszystko jednym kliknięciem (80% przypadków)
- Skorygować konkretną pozycję (15% przypadków)
- Zatrzymać i przeanalizować (5% przypadków)

**Różnica:** W v5.x przedsiębiorca MUSIAŁ odpowiedzieć. W v6.0 przedsiębiorca MOŻE odpowiedzieć.

---

## Perspektywa 1 — UX / Interfejs: Executive Dashboard

### Tradycyjny Feed (v5.x)

```
┌─────────────────────────────────────┐
│  📥 Decision Feed       1 / 3      │ ← Karta wymaga AKCJI
│                                     │
│  "Zaksięguj fakturę od ABC Tech"    │
│                                     │
│  ⭐ ✅ Zaksięguj                    │ ← Musisz kliknąć!
│                                     │
│  ✏️ Popraw dane                    │
└─────────────────────────────────────┘
```

### Executive Dashboard (v6.0)

```
┌─────────────────────────────────────────────┐
│  📊 Executive Dashboard         06:00        │ ← Zero akcji wymaganych
│                                             │
│  🌅 Dzień dobry, Michał!                    │
│  Agent przepracował noc. Oto podsumowanie:  │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │ ✅ Zaksięgowano: 12 faktur          │    │ ← Agent zrobił wszystko
│  │   8 AUTO · 4 z weryfikacją          │    │
│  │   Łącznie: 45 230 PLN              │    │
│  │   Oszczędność Twojego czasu: 45 min │    │
│  │                                     │    │
│  │  📈 Trend: +12% vs zeszły tydzień  │    │ ← Analityka, nie akcje
│  │  🔍 1 pozycja do wglądu            │    │ ← Opcjonalnie!
│  └─────────────────────────────────────┘    │
│                                             │
│  ╔═══════════════════════════════════════╗  │
│  ║  ✅ Akceptuję wszystkie               ║  │ ← 1 klik = koniec
│  ╚═══════════════════════════════════════╝  │
│  ┌───────────────────────────────────────┐  │
│  │  🔍 Przejrzyj szczegóły              │  │ ← Opcjonalny wgląd
│  └───────────────────────────────────────┘  │
│  ┌───────────────────────────────────────┐  │
│  │  📅 Pokaż strategię na dziś          │  │ ← Tryb strategiczny
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Szczegóły interfejsu

**Główna metryka:** "Czas od otwarcia do zamknięcia" — cel: < 30 sekund przy 100% akceptacji.

**Stany UI:**

| Stan | Co widzi użytkownik | Domyślna akcja |
|---|---|---|
| 🔵 **Normalny** | Podsumowanie + "Akceptuj wszystkie" | 1 klik → wszystko zaksięgowane |
| 🟡 **Uwaga** | 1-2 pozycje oznaczone kolorem | Może kliknąć "Akceptuj" lub "Sprawdź" |
| 🔴 **Alert** | Pilna sprawa z priorytetem | Agent prosi o decyzję w konkretnej sprawie |
| ⚪ **Pusty** | "Wszystko zaksięgowane. Idź na kawę ☕" | Brak akcji |

**Zasada "3-Second Rule":**
Każda interakcja z dashboardem powinna zająć ≤ 3 sekundy, jeśli użytkownik akceptuje wszystko. Licznik czasu jest wyświetlany: "Zająłeś 12s z 30s budżetu".

---

## Perspektywa 2 — Agent Intelligence: Continuous Strategy Engine

### Ewolucja inteligencji agenta

```
v5.2 Progressive Autonomy:       v6.0 Continuous Strategy Engine:
  Agent uczy się PREFERENCJI       Agent uczy się STRATEGII
  ("zawsze zatwierdzasz XYZ")      ("w tym kwartale oszczędzasz gotówkę")

  pyta: "VAT 23% czy 8%?"         pyta: "Oszczędzamy czy inwestujemy?"
  uczy się: co klikasz             uczy się: dlaczego klikasz
  cel: 90% AUTO_POST               cel: 95% accept rate + strategia
```

### Agent pyta o STRATEGIĘ, nie o TAKTYKĘ

**Takttyczne pytania (v5.x — ELIMINOWANE):**
- "Którą stawkę VAT wybrać?"
- "Amortyzacja liniowa czy jednorazowa?"
- "Na które konto zaksięgować?"
→ Agent sam oblicza i wybiera OPTYMALNĄ opcję

**Strategiczne pytania (v6.0 — NOWE):**
- "Widzę, że masz wysoki stan gotówki. Czy wolisz:"
  1. "💵 Zachować płynność (niższe ryzyko)"
  2. "📈 Zainwestować nadwyżkę (wyższy zysk)"
  3. "🏗️ Rozłożyć koszty w czasie (niższy PIT)"
- "Twoi kontrahenci z branży budowlanej mają opóźnienia. Czy chcesz:"
  1. "⏰ Wzmocnić windykację"
  2. "🤝 Negocjować nowe terminy"
  3. "🔍 Sprawdzić alternatywnych dostawców"

### Learning by Context (LbC)

Zamiast uczyć się *co* przedsiębiorca robi, agent uczy się *w jakim kontekście*:

**5 wymiarów kontekstu strategicznego:**

| Wymiar | Co oznacza | Jak wpływa na decyzje |
|---|---|---|
| **Cash Flow Phase** | Wpływy > wydatki vs wydatki > wpływy | Więcej AUTO_POST gdy płynność dobra |
| **Tax Period** | Początek/koniec kwartału, VAT deadline | Więcej SUGGEST przy deadline'ach |
| **Vendor Season** | Sezonowość kontrahentów | Niższy próg dla sezonowych |
| **Growth Phase** | Inwestycja vs konserwacja | Preferencje kosztowe |
| **Macro Context** | Stopy procentowe, inflacja, kursy | Sugestie optymalizacji |

### Agent pyta o STRATEGIĘ raz, działa TAKTYCZNIE zawsze

```
Przedsiębiorca wybiera strategię na kwartał:
  "Cel: maksymalizacja płynności"

Agent rozumie tę strategię i dla KAŻDEJ faktury:
  - Wybiera opcję najlepszą dla płynności
  - Jeśli opcje są równoważne → wybiera najprostszą
  - Jeśli żadna opcja nie pasuje → pyta (raz, nie wielokrotnie)
  - Uczy się: "przy tej strategii user wybiera X"
```

### 4 tryby strategiczne (zamiast DecisionMode)

| Tryb strategiczny | Działanie agenta | Gdy agent ma wątpliwość |
|---|---|---|
| 💰 **Cash Protect** | Maksymalizuj płynność, rozkładaj koszty | Pyta: "Czy to wydatek krytyczny?" |
| 📈 **Growth** | Inwestuj, przyspieszaj amortyzację | Pyta: "Czy to zwiększy przychody?" |
| ⚖️ **Tax Optimal** | Minimalizuj PIT/CIT, rozkładaj dochody | Pyta: "Która opcja podatkowa?" |
| 🎯 **Efficiency** | Najszybsza ścieżka, zero zbędnych kroków | Pyta: "Czy pominiemy walidację?" |

---

## Perspektywa 3 — Business Value: Od "Narzędzia" do "Wspólnika"

### Koszt ukryty obecnego modelu

Metafora: **Porównanie do asystenta vs menedżera**

| Aspekt | v5.x — Asystent | v6.0 — Wspólnik |
|---|---|---|
| **Rola** | "Przynoszę Ci faktury do podpisu" | "Prowadzę księgowość, raportuję wyniki" |
| **Czas użytkownika** | 5-15 min dziennie | < 1 min dziennie (domyślnie) |
| **Decyzje** | 5-10 dziennie | 0-1 dziennie (tylko strategiczne) |
| **Krzywa uczenia** | Musi uczyć system przez kliknięcia | System uczy się z kontekstu |
| **Zaufanie** | Rośnie z każdą korektą | Wbudowane w koncepcję |
| **Skalowalność** | Liniowa z liczbą faktur | Prawie stała |

### Metryki sukcesu v6.0

| Metryka | Cel | Obecnie (v5.5) |
|---|---|---|
| **Silent Rate** | ≥ 95% | 73% (Autonomy Score) |
| **Faktur na 1 interakcję** | 200+ | 20 |
| **Czas dzienny** | < 30s | 3-5 min |
| **Strategic Queries Ratio** | ≥ 80% | 0% (wszystkie taktyczne) |
| **Accept-All Rate** | ≥ 80% | N/A (brak koncepcji) |

### Przykład: Dzień przedsiębiorcy z v6.0

```
06:00 — Agent budzi się, wykonuje wszystkie workflow:
        - Pobiera 34 faktury z KSeF
        - OCR + walidacja krzyżowa
        - Sprawdza kontrahentów (Biała Lista)
        - KSIĘGUJE WSZYSTKO (AUTO_POST dla wszystkich)
        - Generuje Executive Summary

07:00 — Przedsiębiorca odpala aplikację (15s interakcji):
        ┌─────────────────────────────────────────────┐
        │  📊 Podsumowanie: 34 faktury                │
        │  ✅ Wszystkie zaksięgowane                  │
        │  💰 1 strategiczna rekomendacja              │
        │                                             │
        │  [✅ Akceptuję wszystko] — 1 klik           │
        └─────────────────────────────────────────────┘

08:00 — Przedsiębiorca prowadzi biznes.
        Agent kontynuuje: windykacja, płatności, monitoring.

18:00 — Agent wysyła wieczorne podsumowanie (opcjonalnie).
```

### Model biznesowy: "Pay per Decision Saved"

Zamiast subskrypcji, system mierzy **wartość wygenerowaną dla przedsiębiorcy**:

```
Value = Time_Saved × Hourly_Rate + Error_Prevention × Avg_Error_Cost

Przykład:
  Time_Saved = 45 min dziennie × 22 dni × 200 PLN/h = 3 300 PLN/mies.
  Error_Prevention = 2 korekty/mies. × 500 PLN = 1 000 PLN/mies.
  Total Value = 4 300 PLN/mies.
```

---

## Implementacja

### Nowe / zmodyfikowane pliki (✅ = wdrożone)

| Plik | Status | Opis |
|---|---|---|
| **`nexus_ai/agents/strategy_engine.py`** | ✅ **WDROŻONY** (~330 linii) | Continuous Strategy Engine: 5 wymiarów kontekstu, 4 tryby strategiczne |
| **`nexus_ai/agents/executive_summary.py`** | ✅ **WDROŻONY** (~230 linii) | Generator Executive Summary: podsumowanie dnia, rekomendacje strategiczne |
| **`nexus_ai/frontend/views/executive_dashboard.py`** | ✅ **WDROŻONY** (~370 linii) | Executive Dashboard: 3-stanowy widok z Accept-All |
| **`nexus_ai/agents/models.py`** | ✅ Rozszerzenie | StrategicMode, CashFlowPhase, ContextDimension, ExecutiveSummary, DashboardState, StrategicRecommendation |
| **`nexus_ai/agents/orchestrator.py`** | ✅ Rozszerzenie | Strategic Pipeline + Silent Mode: `build_executive_summary()`, `accept_all()`, `set_strategic_mode()`, `toggle_silent_mode()` |
| **`nexus_ai/agents/proactive_workflow.py`** | ✅ Rozszerzenie | 3 nowe workflow: EXECUTIVE_SUMMARY_GENERATION, STRATEGY_REFRESH, SILENT_AUTO_POST |
| **`nexus_ai/agents/topics.py`** | ✅ Rozszerzenie | `UI_EXECUTIVE_SUMMARY` topic + `ui` JetStream stream |
| **`docs/AGENTS.md`** | ✅ Aktualizacja | Dodana sekcja 1.5g v6.0: Silent Partner, zaktualizowany nagłówek i stopka |
| **`docs/CHANGELOG.md`** | ✅ Aktualizacja | Nowy wpis [6.0.0-draft] ze szczegółami wdrożenia |

### Architektura Strategic Pipeline

```
Invoice comes in
  │
  ▼
1. Executive Summary Generator
   ├── Czy to rutynowa faktura? → AUTO_POST + dodaj do summary
   ├── Czy to wyjątek? → Zastosuj tryb strategiczny
   └── Czy wymaga strategii? → Zapisz do "rekomendacje strategiczne"
  │
  ▼
2. Strategic Engine
   ├── Jaki tryb? (Cash Protect / Growth / Tax Optimal / Efficiency)
   ├── Jaki kontekst? (cash flow, season, tax period, macro)
   └── Optymalna decyzja na podstawie strategii + kontekstu
  │
  ▼
3. Queue for Executive Summary
  │
  ▼
4. User opens app → widzi Executive Summary z 1 kliknięciem
```

### Integracja z istniejącymi systemami

| System v5.x | Rola w v6.0 |
|---|---|
| Action Cards (v5.1) | Tylko dla alertów krytycznych (🔴) |
| Progressive Autonomy (v5.2) | Learning by Context — zamiast preferencji, uczy strategii |
| KnowledgeMesh (v5.3) | Wymiana kontekstu strategicznego między agentami |
| Decision Protocol (v5.4) | Tylko dla transakcji > 100k PLN |
| Unified Learning (v5.4) | Strategia zamiast taktyki — dlaczego, nie co |
| Proactive Workflow (v5.0) | Silent Mode — wszystkie workflow 24/7 |
| dyscache (v5.5) | Cache dla Executive Summary |

### Milestones wdrożenia

| Milestone | Status | Co się zmienia | Wpływ na UX |
|---|---|---|---|
| **M1** Executive Summary | ✅ **WDROŻONY** | Nowy widok z Accept-All | Czas ↓ 80% (3 min → 30s) |
| **M2** Silent Auto-Post | ✅ **WDROŻONY** | Wszystkie decyzje AUTO_POST (strategicznie) | 0 decyzji dziennie |
| **M3** Strategic Engine | ✅ **WDROŻONY** | 4 tryby + Learning by Context | 0 decyzji taktycznych |
| **M4** Full Silent Partner | ✅ **WDROŻONY** | Pełna pętla: strategia → działanie → raport | 1 decyzja strategiczna/tydz. |

---

## ➡️ Następny krok: v7.0 Business Impact Decisions

W v6.0 Silent Partner agent przejął 100% operacji, ale gdy przedsiębiorca MUSI podejmować decyzje (alerty krytyczne, wyjątki > 100k PLN), system nadal pokazywał parametry księgowe (VAT 23%, amortyzacja liniowa).

**v7.0** rozwiązuje ten problem — zamiast parametrów księgowych, przyciski pokazują realne skutki finansowe: "ZACHOWAJ 2 400 PLN w kasie" zamiast "Amortyzacja liniowa". Wszystkie parametry księgowe → `hidden_payload`.

Zobacz: [`docs/GENIALNY_POMYSL_v7_BUSINESS_IMPACT.md`](GENIALNY_POMYSL_v7_BUSINESS_IMPACT.md)

---

## Podsumowanie: 3 perspektywy, 1 koncept

| Perspektywa | Problem v5.x | Rozwiązanie v6.0 |
|---|---|---|
| **UX/Interfejs** | Feed kart wymagających akcji | Executive Dashboard z Accept-All |
| **Agent Intelligence** | Uczy się preferencji (taktyka) | Uczy się strategii (kontekst) |
| **Biznes** | Oszczędza czas na operacjach | Partner w prowadzeniu biznesu |

**Efekt końcowy:** Przedsiębiorca spędza < 30 sekund dziennie na księgowości. Agent przejmuje 100% operacji. Człowiek podejmuje tylko strategiczne decyzje — dokładnie to, w czym jest najlepszy.

Przedsiębiorca nie klika przycisków. **Przedsiębiorca prowadzi biznes.**

---

> **Data utworzenia:** 2026-07-06 · **Autor:** NexusAI Team · **Wersja:** 6.0.0-draft
> **Status dokumentu:** Wdrożony ✅ (M1-M3 zaimplementowane, M4 w toku)
> **Ostatnia aktualizacja:** 2026-07-06 — dodane statusy wdrożenia
