# Przepływ decyzyjny DecisionEngine.decide()

> **Wersja:** 2.3
> **Data:** 2026-06-10
> **Plik źródłowy:** `nexus_ai/core/decision_engine.py`
> **Format:** Mermaid.js flowchart

---

## Spis treści

1. [Główny przepływ — przegląd](#1-główny-przepływ)
2. [Krok 0 — RAG (FactsAggregator.build)](#2-krok-0--rag)
3. [Krok 1 — Klasyfikacja (classify_invoice)](#3-krok-1--klasyfikacja-classify_invoice)
4. [Krok 2 — Trust score (calculate_trust_score)](#4-krok-2--trust-score-calculate_trust_score)
5. [Krok 3 — Decyzja (decide)](#5-krok-3--decyzja-decide)
6. [Krok 4 — RiskGuard](#6-krok-4--riskguard)
7. [Krok 5 — DecisionLogger](#7-krok-5--decisionlogger)
8. [Pełny przepływ — jeden diagram](#8-pełny-przepływ)
9. [Macierz decyzyjna — reguły first-match-wins](#9-macierz-decyzyjna)
10. [Metryki wydajności](#10-metryki-wydajności)
11. [Appendix A — Architektura v2.0 (historyczna)](#11-appendix-a--architektura-v20-historyczna)
12. [Appendix B — NexusCache w przepływie decyzyjnym](#12-appendix-b--nexuscache-w-przepływie-decyzyjnym)

---

## 1. Główny przepływ

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark", "themeVariables": {"fontSize": "14px"}}}%%
flowchart TB
    START(["DecisionEngine.decide(\n  invoice_data,\n  fact_sheet,\n  vendor_profile\n)"]) 
    
    START --> K0
    
    subgraph K0["Krok 0 · RAG"]
        FA["FactsAggregator.build(invoice_data)\n→ 4 źródła równolegle: SQLite, DuckDB,\n  sqlite-vec, TigerBeetle"]
        FS["FactSheet ← wynik build()"]
        FSP["to_prompt_section() → fact_sheet_text"]
        FA --> FS --> FSP
    end
    FSP --> K1

    subgraph K1["Krok 1 · Klasyfikacja"]
        CI["classify_invoice(\n  invoice_data,\n  vendor_profile\n)\n→ simple / complex"]
    end
    CI --> K2

    subgraph K2["Krok 2 · Trust score"]
        CTS["calculate_trust_score(\n  ocr_conf, vendor_score,\n  data_consistency, context, risk\n)\n→ 0.0–1.0"]
    end
    CTS --> K3

    subgraph K3["Krok 3 · Decyzja (first-match-wins)"]
        RULES["_get_active_rules()\n→ SELECT * FROM decision_rules\n  WHERE valid_from <= now()\n  AND valid_to >= now()\n  ORDER BY priority ASC"]
        MATCH["_match_condition(rule, context)\n→ operator: field / field__gte /\n  field__lte / field__in\n→ {} pasuje zawsze"]
        VERDICT["DecisionVerdict(\n  decision, confidence,\n  matched_rule_id,\n  rule_description\n)"]
        RULES --> MATCH --> VERDICT
    end
    VERDICT --> K4

    subgraph K4["Krok 4 · RiskGuard"]
        RG["RiskGuard.evaluate(\n  invoice_data,\n  fact_sheet.contractor_nip\n)\n→ AUTO_POST / TRIAGE_QUEUE / BLOCK_AND_ALERT"]
    end
    RG --> K5

    subgraph K5["Krok 5 · DecisionLogger"]
        DL["DecisionLogger.log_decision(\n  invoice_id, decision,\n  trust_score, risk_verdict,\n  matched_rule, context\n)"]
        RET["return DecisionVerdict"]
        DL --> RET
    end
    RET --> END(["Koniec"])
```

---

## 2. Krok 0 — RAG

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart LR
    subgraph Input["Wejście"]
        I1["invoice_data: dict\n(OCR + dane faktury)"]
    end

    subgraph Build["FactsAggregator.build()"]
        direction TB
        T1["Task 1: SQLite\n· contractor\n· recent_invoices\n· user_corrections"]
        T2["Task 2: DuckDB\n· trust_score_trend\n· active_tax_rules\n· vendor_intelligence"]
        T3["Task 3: sqlite-vec\n· similar_invoices\n  (embedding search)"]
        T4["Task 4: TigerBeetle\n· ledger_accounts\n· ledger_total_turnover\n· ledger_recent_transfers"]
        T5["Task 5: DecisionLogger\n· global_recent_decisions"]
        T1 & T2 & T3 & T4 & T5 -->|"asyncio.gather\nizolacja błędów"| SHEET
    end

    subgraph Sheet["FactSheet"]
        direction TB
        S1["contractor_nip, amount_net,\namount_gross, category"]
        S2["recent_invoices, similar_invoices"]
        S3["trust_score_trend, active_tax_rules"]
        S4["ledger_available, ledger_accounts"]
        S5["sources_available, build_duration_ms"]
    end

    subgraph Output["Dla DecisionEngine"]
        O1["fact_sheet_text = to_prompt_section()\n→ === ARKUSZ FAKTÓW ==="]
        O2["few_shot_examples = build_few_shot_examples()\n→ === PRZYKŁADY FEW-SHOT ==="]
    end

    I1 --> T1
    I1 --> T2
    I1 --> T3
    I1 --> T4
    I1 --> T5
    SHEET --> Output
```

---

## 3. Krok 1 — Klasyfikacja classify_invoice

`classify_invoice()` to deterministyczna funkcja SQL-like, która zastępuje WorkflowPlanner (LittleLamb 0.3B):

```python
def classify_invoice(invoice_data, vendor_profile=None) -> str:
    if amount <= 5000 and vendor_known and vendor_count >= 3 and ocr_conf >= 0.85:
        return "simple"
    return "complex"
```

| Warunek | Simple | Complex |
|---|---|---|
| Kwota brutto | ≤ 5000 PLN | > 5000 PLN |
| Kontrahent znany | Tak (≥3 faktury) | Opcjonalnie |
| OCR confidence | ≥ 0.85 | Dowolny |
| Czas wykonania | **<1ms** | **<1ms** |

---

## 4. Krok 2 — Trust score calculate_trust_score

5-składnikowa kalkulacja zastępująca TrustScoreCalculator:

```
trust = ocr_conf × 0.30 + vendor_score × 0.25 + data_consistency × 0.20
        + context × 0.10 + risk × 0.15
```

| Składnik | Waga | Źródło |
|---|---|---|
| `ocr_conf` | 0.30 | Pipeline OCR (LightOnOCR-1B, docTR, EasyOCR, PaddleOCR) |
| `vendor_score` | 0.25 | Historia kontrahenta (SQLite) |
| `data_consistency` | 0.20 | Zgodność pędów faktury |
| `context` | 0.10 | Kontekst kontrahenta (DuckDB) |
| `risk` | 0.15 | RiskGuard threshold |

**Czas wykonania:** **<1ms** (obliczenia w pamięci)

---

## 5. Krok 3 — Decyzja decide

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart TB
    START(["decide(invoice_data, fact_sheet, trust_score)"])
    START --> GET

    subgraph GET["Pobranie aktywnych reguł"]
        R1["_get_active_rules(conn)\n→ SELECT * FROM decision_rules\n  WHERE valid_to IS NULL\n  OR valid_to >= now()\n  ORDER BY priority ASC"]
    end

    subgraph MATCHES["Dopasowanie first-match-wins"]
        direction TB
        R1 --> R2["Dla każdej reguły (wg priorytetu):"]
        R2 --> C1["_match_condition(rule.conditions, context)\n→ operator: field / field__gte /\n  field__lte / field__in"]
        C1 --> C2{"condition\nmatched?"}
        C2 -->|"Tak"| WIN["→ matched_rule = rule\n→ decision = rule.decision\n→ confidence = rule.confidence"]
        C2 -->|"Nie"| C3["→ następna reguła"]
        C3 --> C1
    end

    subgraph FALLBACK["Fallback (reguła 999)"]
        F1["Reguła z priorytetem 999:\ncondition: {}\n(zawsze pasuje)\ndecision: ASK_USER\nconfidence: 0.50"]
        WIN --> F1
    end

    subgraph RESULT["Wynik"]
        V1["DecisionVerdict(\n  decision,\n  confidence,\n  matched_rule_id,\n  rule_description\n)"]
    end

    F1 --> V1
    V1 --> END(["→ Krok 4 · RiskGuard"])
```

### Przykład dopasowania

Dla faktury: znany kontrahent, 15 faktur, trust 0.88, kwota 4500 PLN, OCR 0.94:

| Prio | Warunek | Pasuje? | Decyzja |
|---|---|---|---|
| 10 | known + ≥10 + trust ≥0.85 + ≤5k + OCR≥0.92 | ✅ | **AUTO_POST** (conf=0.95) |
| 20 | (skip — już dopasowano) | — | — |

---

## 6. Krok 4 — RiskGuard

`RiskGuard.evaluate()` sprawdza progi ufności per pole faktury w DuckDB `risk_thresholds`:

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart TB
    START(["RiskGuard.evaluate(invoice_data, nip)"])
    START --> RULES

    subgraph RULES["Pobranie progów"]
        R1["SELECT * FROM risk_thresholds\nWHERE taxation_form = ?\nORDER BY priority ASC"]
    end

    subgraph CHECK["Sprawdzenie per pole"]
        direction TB
        R1 --> F1["Dla każdego pola faktury:"]
        F1 --> F2{"field.confidence <\nthreshold.required?"}
        F2 -->|"Tak"| F3["→ threshold.action"]
        F2 -->|"Nie"| F4["→ następne pole"]
        F4 --> F1
    end

    subgraph ACTION["Najbardziej restrykcyjna akcja"]
        A1["AUTO_POST → wszystkie pola OK"]
        A2["TRIAGE_QUEUE → średnie ryzyko"]
        A3["BLOCK_AND_ALERT → wysokie ryzyko"]
    end

    F3 --> ACTION
    ACTION --> END(["→ Krok 5 · DecisionLogger"])
```

---

## 7. Krok 5 — DecisionLogger

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart LR
    subgraph INPUT["Wejście"]
        I1["invoice_id, decision,\ntrust_score, risk_verdict,\nmatched_rule"]
    end

    subgraph LOG["DecisionLogger.log_decision()"]
        L1["INSERT INTO decisions\n  (id, invoice_id, alpha_vote, beta_vote, gamma_vote,\n   final_decision, trust_score, trust_components, context,\n   timestamp, decision_level, decision_pattern)\n  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"]
        L2["UPDATE trust_score_cache\n  SET trust_score = ?,\n      ai_confidence = ?, vendor_reliability = ?,\n      data_consistency = ?, context_trust = ?\n  WHERE contractor_nip = ?"]
    end

    subgraph RETURN["Zwrot"]
        R1["return DecisionVerdict(\n  decision,\n  confidence,\n  matched_rule_id,\n  rule_description\n)"]
    end

    I1 --> L1
    L1 --> L2
    L2 --> R1
```

---

## 8. Pełny przepływ

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark", "themeVariables": {"fontSize": "13px"}}}%%
flowchart TB
    FA(["Invoice Data (OCR)"])
    FA -->|"Krok 0"| RAG

    subgraph RAG["🧠 RAG Layer"]
        FB["FactsAggregator.build()\n→ 4 źródła równolegle"]
        FS["→ FactSheet"]
        FB --> FS
    end
    FS -->|"Krok 1"| KL

    subgraph KL["🔢 Klasyfikacja"]
        CI["classify_invoice()\n→ simple / complex\n<1ms"]
    end
    CI -->|"Krok 2"| TS

    subgraph TS["📊 Trust Score"]
        CTS["calculate_trust_score()\n→ 0.0–1.0\n<1ms"]
    end
    CTS -->|"Krok 3"| DE

    subgraph DE["⚖️ DecisionEngine"]
        DIR["_get_active_rules()\n→ DuckDB"]
        MC["_match_condition()\n→ first-match-wins"]
        DV["DecisionVerdict\n→ decision + confidence"]
        DIR --> MC --> DV
    end
    DV -->|"Krok 4"| RG

    subgraph RG["🛡️ RiskGuard"]
        RGE["RiskGuard.evaluate()\n→ DuckDB thresholdy"]
        RGACT["AUTO_POST /\nTRIAGE_QUEUE /\nBLOCK_AND_ALERT"]
        RGE --> RGACT
    end
    RGACT -->|"Krok 5"| DL

    subgraph DL["📝 DecisionLogger"]
        DLE["log_decision()\n→ DuckDB"]
    end
    DLE --> RET

    subgraph RET["🏁 Zwrot"]
        FINAL["DecisionVerdict"]
    end
    RET --> END(["Koniec"])
```

---

## 9. Macierz decyzyjna

| Priorytet | Warunek | Decyzja | Confidence |
|---|---|---|---|
| 10 | known + ≥10 invoices + trust ≥0.85 + amount ≤5k + OCR ≥0.92 | **AUTO_POST** | 0.95 |
| 20 | known + ≥3 invoices + trust ≥0.80 + amount ≤3k + OCR ≥0.90 | **AUTO_POST** | 0.90 |
| 30 | known + amount ≤10k + OCR ≥0.85 | **SUGGEST** | 0.80 |
| 40 | new + amount ≤5k + OCR ≥0.90 | **SUGGEST** | 0.75 |
| 50 | amount ≤50k + OCR ≥0.80 | **ASK_USER** | 0.60 |
| 100 | amount ≥50k | **BLOCK** | 0.40 |
| 999 | Zawsze (fallback) | **ASK_USER** | 0.50 |

### Czynniki wpływające na końcową decyzję

1. **Dopasowana reguła** — pierwsza reguła, której warunki pasują (priorytet ASC)
2. **Trust score** — 5-składnikowa kalkulacja używana w warunkach reguł
3. **RiskGuard** — może zmienić decyzję na `TRIAGE_QUEUE` / `BLOCK_AND_ALERT`
4. **Klasyfikacja simple/complex** — wpływa na to, które źródła RAG są priorytetowe

### Końcowe wartości `decision`

| Wartość | Znaczenie |
|---|---|
| `AUTO_POST` | Automatyczne księgowanie — wysoka pewność (≥0.85) |
| `SUGGEST` | Sugestia dla użytkownika — umiarkowana pewność (0.75–0.84) |
| `ASK_USER` | Zapytaj użytkownika — niska pewność lub fallback |
| `BLOCK` | Blokada — kwota ≥50k lub wysoki risk |

---

## 10. Metryki wydajności

### Decision timing

| Operacja | Typowy czas | Uwagi |
|---|---|---|
| `classify_invoice()` | **<1ms** | Tylko porównania SQL-like |
| `calculate_trust_score()` | **<1ms** | Obliczenia w pamięci |
| `_get_active_rules()` | **<5ms** | SELECT z DuckDB |
| `_match_condition()` per rule | **<0.5ms** | Porównania słownikowe |
| `decide()` (całość) | **<5ms** | First-match-wins |
| `RiskGuard.evaluate()` | **<10ms** | DuckDB + per-field check |
| `DecisionLogger.log()` | **<5ms** | INSERT do DuckDB |
| **Całkowity czas decyzji** | **~10–20ms** | Bez RAG |

### Z RAG

| Komponent | Typowy czas |
|---|---|
| `FactsAggregator.build()` | ~100–300ms |
| `build_few_shot_examples()` (cache hit) | <10ms |
| `decide()` + `RiskGuard` + `DecisionLogger` | ~20ms |
| **Całkowity** | **~200–400ms** |

### Porównanie z poprzednią architekturą (v2.0)

| Scenariusz | v2.0 (wieloagentowa) | v2.3 (DecisionEngine) | Zmiana |
|---|---|---|---|
| Simple + RAG | ~7.8s | **~0.2s** | **39× szybciej** |
| Complex + RAG | ~18.3s | **~0.3s** | **61× szybciej** |
| RAM peak | ~2.2 GB | **~200 MB** | **11× mniej RAM** |

---

## 11. Appendix A — Architektura v2.0 (historyczna)

### Przepływ decyzyjny AgentOrchestrator (zastąpiony)

Poprzednia architektura używała kaskady 7+ komponentów AI:

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark", "themeVariables": {"fontSize": "12px"}}}%%
flowchart TB
    START(["AgentOrchestrator.orchestrate()"]) -->|"Krok 0"| RAG

    subgraph RAG["🧠 RAG Layer"]
        FA["FactsAggregator.build()\n→ FactSheet"]
    end
    RAG -->|"Krok 1"| WP

    subgraph WP["WorkflowPlanner\nLittleLamb 0.3B\n~0.5s"]
        WPP["plan() → simple/complex"]
    end
    WP -->|"Krok 2"| COA

    subgraph COA["Council of Agents\nAlpha+Beta+Gamma\n~2-6s"]
        CA["LFM2.5 / Qwen3 / LittleLamb"]
    end
    COA -->|"Krok 3"| RST

    subgraph RST["Rules SWAT Team\nL1-L4\n~6.5s"]
        R1["LFM2.5 → Granite → LittleLamb → Fin-RWKV"]
    end
    RST -->|"Krok 4"| JS

    subgraph JS["JambaStrategist\nJamba 3B\n~5s"]
        JI["analyze() → decision"]
    end
    JS -->|"Krok 5"| BL

    subgraph BL["BayesianThreshold\n~0.1s"]
        BT["get_thresholds()\n→ override"]
    end
    BL -->|"Krok 6"| PLE

    subgraph PLE["PLE Engine\n~0.01s"]
        PL["STM → LTM → FM"]
    end

    PLE --> RET
    RET(["OrchestratorDecision"])
```

**Total: ~7.7–18.3s zależnie od ścieżki**

### Dlaczego zastąpiony?

| Czynnik | v2.0 (wieloagentowa) | v2.3 (DecisionEngine) |
|---|---|---|
| Czas decyzji | 7.7–18.3s | 10–20ms |
| RAM | ~2.2 GB peak | ~200 MB baseline |
| Determinizm | LLM z temperature=0.1 | SQL first-match-wins |
| Testowalność | Trudna (LLM non-deterministic) | Łatwa (SQL + reguły) |
| Konserwacja | Fine-tuning modeli | INSERT do DuckDB |
| Koszt | Drogie inferencje GPU | Darmowe (CPU only) |

---

## 12. Appendix B — NexusCache w przepływie decyzyjnym

| Komponent | Cache'owane dane | Klucz | TTL | Typ dostępu |
|---|---|---|---|---|
| `_load_prompt_pack()` | Mapy promptów (lang → template → instrukcja) | `prompt_pack:{lang}` | 3600s | `get_sync/set_sync` (L1+L2) |
| `FactSheet._few_shot_cache` | Sekcje few-shot | `few_shot:{hash}:{max}` | 300s | `get_sync/set_sync` (L1+L2) |
| `FactsAggregator._enrich_cache` | Wzbogacone podobne faktury | `enrich:{invoice_id}` | 300s | `await get/set` (L1+L2) |
| `WhiteListService` | Wyniki Białej Listy MF | `whitelist:{nip}:{account}` | 3600s | L1+L2 (async) |
| `CurrencyConverter` | Kursy walut NBP | `fx_rate:{currency}:{date}` | 300s | L1 (sync) |
| `TimedModelCache` | TTL metadata modeli ML | `_model_cache_ttl:{key}` | 600s | TTL metadata (L1) |

---

> **Dokumentacja techniczna** — NexusAI v2.3
> **Ostatnia aktualizacja:** 2026-06-10
> **Plik:** `docs/DECISION_FLOW.md`
