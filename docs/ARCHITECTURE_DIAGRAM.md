# Diagram Architektury NexusAI

> **Wersja:** 2.3
> **Data:** 2026-06-10
> **Format:** Mermaid.js (flowchart, sequence, C4)

---

## Spis diagramów

1. [Diagram warstwowy — 4 warstwy architektury](#1-diagram-warstwowy)
2. [Przepływ decyzyjny DecisionEngine](#2-przepływ-decyzyjny-decisionengine)
3. [Struktura RAG / FactsAggregator](#3-struktura-rag--factsaggregator)
4. [Macierz decyzyjna — first-match-wins](#4-macierz-decyzyjna)
5. [Diagram klas — komponenty decyzyjne](#5-diagram-klas)
6. [Ekonomia poznawcza — koszty i wydajność](#6-ekonomia-poznawcza)
7. [NexusCache — dwupoziomowa architektura cache](#7-nexuscache)
8. [Full system context — C4 poziom 1](#8-full-system-context)
9. [Cleanup lifecycle — async close()](#9-cleanup-lifecycle)
10. [Architektura v2.0 (historyczna)](#10-architektura-v20-historyczna)

---

## 1. Diagram warstwowy

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark", "themeVariables": {"fontSize": "14px", "primaryColor": "#1a1a2e", "secondaryColor": "#16213e", "tertiaryColor": "#0f3460"}}}%%
flowchart TB
    subgraph Warstwa0["🧠 Warstwa Decyzyjna"]
        direction TB
        DE["DecisionEngine\ncore/decision_engine.py"]
        CI["classify_invoice()\nsimple / complex\n<1ms"]
        TS["calculate_trust_score()\n5 składników\n<1ms"]
        FW["_match_condition()\nfirst-match-wins\n<5ms"]
        DE --> CI
        DE --> TS
        DE --> FW
    end

    subgraph Warstwa1["⚡ Warstwa Wsparcia"]
        direction TB
        RAG["FactsAggregator\nRAG Layer\n4 źródła równolegle"]
        RG["RiskGuard\nDuckDB thresholdy\nper-pole confidence"]
        SG["SemanticGuard\nsqlite-vec\nanomalie semantyczne"]
        DL["DecisionLogger\nDuckDB\naudyt + trend"]
    end

    subgraph Warstwa2["💾 Warstwa Danych"]
        direction TB
        SQL[("SQLite + SQLCipher\nOLTP")]
        DDB[("DuckDB\nOLAP")]
        SVEC[("sqlite-vec\nWektory")]
        TBDB[("TigerBeetle\nSecure Ledger")]
        SOP[("ProtocolLoader\nprotocols.toml")]
        CACHE[("NexusCache\nL1 RAM + L2 SQLite")]
    end

    subgraph Warstwa3["🤖 Warstwa AI (tylko niefinansowe)"]
        direction TB
        OCR["LightOnOCR-1B\nOCR główny"]
        VA["Phi-3-mini 3.8B\nVisionAgent (fallback)"]
        EMB["llama-cpp-python\nEmbeddingi"]
    end

    %% Połączenia
    DE --> RAG
    DE --> RG
    DE --> SG
    DE --> DL
    RAG --> SQL
    RAG --> DDB
    RAG --> SVEC
    RAG --> TBDB
    RAG --> CACHE
    DE --> SOP
    RG --> DDB
    SG --> SVEC
    DL --> DDB

    style Warstwa0 fill:#1a1a2e,stroke:#e94560,stroke-width:2px
    style Warstwa1 fill:#16213e,stroke:#0f3460,stroke-width:2px
    style Warstwa2 fill:#0f3460,stroke:#533483,stroke-width:2px
    style Warstwa3 fill:#1a1a2e,stroke:#e94560,stroke-width:2px,stroke-dasharray:5,5
```

---

## 2. Przepływ decyzyjny DecisionEngine

```mermaid
%%{init: {"sequence": {"showSequenceNumbers": true}, "theme": "dark"}}%%
sequenceDiagram
    actor User as Użytkownik
    participant DE as DecisionEngine
    participant RAG as FactsAggregator
    participant DB as DuckDB
    participant RG as RiskGuard
    participant DL as DecisionLogger
    participant SRC as SQLite/sqlite-vec/TB

    Note over DE,SRC: Krok 0 — RAG
    DE->>+RAG: build(invoice_data)
    RAG->>SRC: 4 źródła równolegle
    SRC-->>RAG: FactSheet
    RAG-->>-DE: FactSheet

    Note over DE,SRC: Krok 1 — Klasyfikacja
    DE->>DE: classify_invoice()
    DE-->>DE: simple / complex

    Note over DE,SRC: Krok 2 — Trust score
    DE->>DE: calculate_trust_score()
    DE-->>DE: 0.0–1.0

    Note over DE,SRC: Krok 3 — Reguły
    DE->>DB: _get_active_rules()
    DB-->>DE: rules sorted by priority
    loop Dla każdej reguły
        DE->>DE: _match_condition()
        alt Pasuje
            DE->>DE: first-match → break
        end
    end

    Note over DE,SRC: Krok 4 — Risk
    DE->>+RG: evaluate()
    RG->>DB: risk_thresholds
    DB-->>RG: thresholdy
    RG-->>-DE: risk_verdict

    Note over DE,SRC: Krok 5 — Logowanie
    DE->>+DL: log_decision()
    DL->>DB: INSERT
    DL-->>-DE: logged

    DE-->>-User: DecisionVerdict
```

---

## 3. Struktura RAG / FactsAggregator

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart LR
    subgraph Sources["📡 4 źródła danych — równoległe asyncio.create_task()"]
        S1["Task 1: SQLite\nContractor, Recent Invoices\nUser Corrections"]
        S2["Task 2: DuckDB\nTrust Score Trend\nActive Tax Rules\nVendor Intelligence"]
        S3["Task 3: sqlite-vec\nSemantically Similar\nInvoices (embeddings)"]
        S4["Task 4: TigerBeetle\nLedger Account Balances\nTotal Turnover\nRecent Transfers"]
    end

    subgraph Tasks["⚙️ asyncio Tasks (izolacja błędów)"]
        direction LR
        T1[("Task 1 ❌\nSQLite fail\n→ puste dane")]
        T2[("Task 2 ✅\nDuckDB OK")]
        T3[("Task 3 ✅\nsqlite-vec OK")]
        T4[("Task 4 ❌\nTB fail\n→ puste dane")]
    end

    subgraph Sheet["📋 FactSheet (dataclass slots=True)"]
        direction TB
        F1["contractor_nip, amount_net, amount_gross\ncategory, issue_date"]
        F2["recent_invoices: list[dict]\nsimilar_invoices: list[dict]"]
        F3["trust_score_trend, active_tax_rules\nvendor_intelligence"]
        F4["ledger_available, ledger_accounts\nledger_total_turnover"]
        F5["sources_available: dict[str, bool]\nbuild_duration_ms"]
    end

    S1 --> T1
    S2 --> T2
    S3 --> T3
    S4 --> T4
    T1 --> Sheet
    T2 --> Sheet
    T3 --> Sheet
    T4 --> Sheet

    subgraph Methods["🧰 Metody FactSheet"]
        M1["to_prompt_section()\n→ === ARKUSZ FAKTÓW ==="]
        M2["to_dict()\n→ JSON dla audytu"]
        M3["build_few_shot_examples(max=3)\n→ dynamiczne few-shot\n+ NexusCache"]
    end

    Sheet --> Methods

    subgraph Cache["💨 NexusCache w RAG"]
        C1["_few_shot_cache: get_sync/set_sync\nklucz: few_shot:{hash}:{max}\nTTL: 300s"]
        C2["_enrich_cache: await get/set\nklucz: enrich:{invoice_id}\nTTL: 300s"]
    end

    Methods --> Cache
```

---

## 4. Macierz decyzyjna

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart LR
    subgraph Rules["📋 Reguły first-match-wins (DuckDB)"]
        R1["Pri:10 | known + ≥10 invoices + trust≥0.85 + ≤5k + OCR≥0.92\n→ AUTO_POST (0.95)"]
        R2["Pri:20 | known + ≥3 invoices + trust≥0.80 + ≤3k + OCR≥0.90\n→ AUTO_POST (0.90)"]
        R3["Pri:30 | known + ≤10k + OCR≥0.85\n→ SUGGEST (0.80)"]
        R4["Pri:40 | new + ≤5k + OCR≥0.90\n→ SUGGEST (0.75)"]
        R5["Pri:50 | ≤50k + OCR≥0.80\n→ ASK_USER (0.60)"]
        R6["Pri:100 | ≥50k\n→ BLOCK (0.40)"]
        R7["Pri:999 | {} (zawsze)\n→ ASK_USER (0.50)"]
    end

    subgraph Decision["🔀 Dopasowanie"]
        D1["_match_condition(rule, context)\n→ operator: field / field__gte /\n  field__lte / field__in"]
        D2["Pierwsza pasująca reguła = decyzja"]
    end

    subgraph Result["✅ Wynik"]
        O1["AUTO_POST → autonomiczne księgowanie"]
        O2["SUGGEST → sugestia dla użytkownika"]
        O3["ASK_USER → zapytaj użytkownika"]
        O4["BLOCK → blokada (kwota ≥50k)"]
    end

    Rules --> Decision
    Decision --> Result
```

---

## 5. Diagram klas

```mermaid
%%{init: {"theme": "dark"}}%%
classDiagram
    class DecisionEngine {
        +DuckDBConnection _conn
        +FactsAggregator _facts_agg
        +RiskGuard _risk_guard
        +SemanticGuard _semantic_guard
        +DecisionLogger _decision_logger
        +DecisionVerdict decide(invoice_data, fact_sheet, trust_score)
        +str classify_invoice(invoice_data, vendor_profile)
        +float calculate_trust_score(ocr, vendor, data, context, risk)
        -list[dict] _get_active_rules(conn)
        -bool _match_condition(conditions, context)
        +record_decision(invoice_id, decision)
    }

    class DecisionVerdict {
        +str decision
        +float confidence
        +int matched_rule_id
        +str matched_rule_description
        +str risk_action
        +dict context
    }

    class FactsAggregator {
        -SQLiteSession _sqlite
        -DuckDBManager _duckdb
        -VectorStore _vector_store
        -TigerBeetleClient _tigerbeetle
        -DecisionLogger _decision_logger
        -NexusCache _cache
        +FactSheet build(invoice_data)
        -dict _fetch_contractor()
        -dict _fetch_recent_invoices()
        -dict _fetch_duckdb_sources()
        -dict _fetch_similar_invoices()
        -dict _fetch_ledger_history()
        -dict _fetch_global_decisions()
    }

    class FactSheet {
        +str invoice_id
        +str contractor_nip
        +str contractor_name
        +float amount_net
        +float amount_gross
        +str category
        +bool contractor_known
        +float contractor_trust_score
        +list[dict] recent_invoices
        +list[dict] similar_invoices
        +dict trust_score_trend
        +list[dict] active_tax_rules
        +bool ledger_available
        +dict ledger_accounts
        +float build_duration_ms
        +str to_prompt_section()
        +dict to_dict()
        +str build_few_shot_examples(max_examples=3)
    }

    class RiskGuard {
        +DuckDBConnection _conn
        +dict evaluate(invoice_data, contractor_nip)
        -list[dict] _get_active_thresholds(taxation_form)
    }

    class SemanticGuard {
        +VectorStore _vector_store
        +EmbeddingService _embeddings
        +dict evaluate(invoice_data, contractor_nip)
        -float _calculate_anomaly_score(embedding, contractor_invoices)
    }

    class DecisionLogger {
        +DuckDBConnection _conn
        +log_decision(invoice_id, decision, trust_score, risk_verdict, matched_rule)
        +get_trust_score_trend(nip, days=30)
        +get_decisions_for_invoice(invoice_id)
    }

    class ProtocolLoader {
        -dict protocols
        +get_protocol(path)
        +get_emergency_protocol(name)
        +reload()
    }

    class NexusCache {
        -dict _ram_cache
        -DysCache _dyscache
        +get(key): Optional[Any]
        +set(key, value, ttl)
        +get_sync(key): Optional[Any]
        +set_sync(key, value, ttl)
        +get_or_compute(key, compute_func, ttl)
        +clear()
    }

    DecisionEngine --> FactsAggregator
    DecisionEngine --> DecisionVerdict
    DecisionEngine --> RiskGuard
    DecisionEngine --> SemanticGuard
    DecisionEngine --> DecisionLogger
    DecisionEngine --> ProtocolLoader
    FactsAggregator --> FactSheet
    FactsAggregator --> NexusCache
```

---

## 6. Ekonomia poznawcza

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart LR
    subgraph SzybkaSciezka["⚡ Ścieżka decyzyjna ~0.2s"]
        S1["RAG (FactsAggregator)\n~100-300ms"]
        S2["Klasyfikacja\n<1ms"]
        S3["Trust score\n<1ms"]
        S4["DecisionEngine\n<5ms"]
        S5["RiskGuard\n<10ms"]
        S6["DecisionLogger\n<5ms"]
        S1 --> S2 --> S3 --> S4 --> S5 --> S6
    end

    subgraph Porownanie["📊 Porównanie z v2.0"]            V1["v2.3: ~0.2-0.4s | ~200 MB RAM"]
        V2["v2.0: ~7.7-18.3s | ~2.2 GB RAM"]
    end

    subgraph AIOnly["🤖 Tylko zadania AI"]
        A1["LightOnOCR-1B: ~800 MB RAM\nOCR faktur"]
        A2["Phi-3-mini: ~2.2 GB RAM\nVisionAgent (fallback)"]
        A3["llama-cpp-python: ~300 MB\nEmbeddingi"]
    end

    subgraph MemMgmt["🗑️ Zarządzanie pamięcią"]
        M1["Lazy loading\n— modele przy pierwszym zadaniu"]
        M2["Explicit unloading\n— del model + gc.collect()"]
        M3["Mutual exclusion\n— asyncio.Semaphore(1)"]
        M4["TTL 5 min\n— auto wyładowanie"]
    end
```

---

## 7. NexusCache — dwupoziomowa architektura cache

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart TB
    subgraph Cache["💨 NexusCache"]
        direction TB
        
        subgraph L1["L1: RAM (dict)"]
            L1A["get_sync(key) / set_sync(key, value, ttl)\nnajszybszy dostęp synchroniczny\nmsgspec_dumps_bytes / msgspec_loads"]
        end

        subgraph L2["L2: SQLite (dyscache)"]
            L2A["await get(key) / await set(key, value, ttl)\npersystentny (przetrwa restart)\nTTL-aware"]
        end

        subgraph Shared["Wspólne"]
            S1["Globalny singleton: get_cache()\nmsgspec serializacja\nTTL expiry przez timestamp"]
        end
    end

    subgraph Users["Komponenty używające NexusCache"]
        U1["WhiteListService\nwhitelist:{nip}:{account}\nTTL: 3600s"]
        U2["CurrencyConverter\nfx_rate:{currency}:{date}\nTTL: 300s"]
        U3["_load_prompt_pack()\nprompt_pack:{lang}\nTTL: 3600s"]
        U4["FactSheet\nfew_shot:{hash}:{max}\nTTL: 300s"]
        U5["FactsAggregator\nenrich:{invoice_id}\nTTL: 300s"]
        U6["TimedModelCache\n_model_cache_ttl:{key}\nTTL: 600s"]
    end

    Users --> Cache
    L1 --> L2
```

---

## 8. Full System Context — C4 poziom 1

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart TB
    User(("👤 Użytkownik\n(Księgowy / CFO)"))
    External("📄 System zewnętrzny\n(OCR, API bankowe,\nKSeF, GUS BIR)")

    subgraph System["NexusAI — System decyzyjny v2.3"]
        direction TB

        subgraph API["🔌 API / CLI"]
            API1["Litestar / CLI\nPunkt wejścia"]
            API2["Background Tasks\nTaskiq + NATS"]
        end

        subgraph Core["🧠 Core"]
            C1["DecisionEngine\nSilnik decyzyjny"]
            C2["FactsAggregator\nRAG Layer"]
            C3["ProtocolLoader\nSOP Engine"]
            C4["NexusCache\nL1 RAM + L2 SQLite"]
        end

        subgraph Guards["🛡️ Strażnicy"]
            G1["RiskGuard\nDuckDB thresholdy"]
            G2["SemanticGuard\nsqlite-vec"]
        end

        subgraph Audit["📝 Audyt"]
            A1["DecisionLogger\nDuckDB"]
        end

        subgraph Storage["💾 Przechowywanie"]
            S1[("SQLite + SQLCipher\nInvoice, Contractor")]
            S2[("DuckDB\nAnalytics, Rules")]
            S3[("sqlite-vec\nEmbeddings")]
            S4[("TigerBeetle\nSecure Ledger")]
            S5[("Config\nprotocols.toml")]
        end

        subgraph AI["🤖 AI (tylko niefinansowe)"]
            AI1["LightOnOCR-1B\nOCR"]
            AI2["Phi-3-mini\nVisionAgent"]
            AI3["llama-cpp-python\nEmbeddingi"]
        end
    end

    User --> API1
    External --> API1
    API1 --> C1
    C1 --> C2
    C1 --> G1
    C1 --> G2
    C1 --> A1
    C1 --> C3
    C2 --> S1
    C2 --> S2
    C2 --> S3
    C2 --> S4
    C2 --> C4
    G1 --> S2
    G2 --> S3
    A1 --> S2
    C3 --> S5

    style System fill:#1a1a2e,stroke:#e94560,stroke-width:2px
    style API fill:#16213e,stroke:#0f3460
    style Core fill:#0f3460,stroke:#533483
    style Guards fill:#1a1a2e,stroke:#e94560
    style Audit fill:#16213e,stroke:#0f3460
    style Storage fill:#0f3460,stroke:#533483
    style AI fill:#1a1a2e,stroke:#e94560,stroke-dasharray:5,5
```

---

## 9. Cleanup lifecycle — async close()

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart TB
    subgraph Services["Serwisy z zasobami"]
        WLS["WhiteListService\n→ CachedHttpClient (httpx+hishel)"]
        CC["CurrencyConverter\n→ DuckDBPyConnection"]
        CE["ContextEnricher\n→ WhiteListService + DuckDB"]
        CHC["CachedHttpClient\n→ httpx.AsyncClient"]
    end

    subgraph Close["async close() chain"]
        C1["await white_list.close()\n→ await self._http.close()"]
        C2["await converter.close()\n→ self._conn.close()"]
        C3["await enricher.close()\n→ await white_list.close()\n  + self._conn.close()"]
        C4["await http_client.close()\n→ await client.aclose()"]
    end

    WLS --> C1
    CC --> C2
    CE --> C3
    CHC --> C4

    subgraph Effect["Efekt"]
        E1["httpx.AsyncClient\nconnection pool → zamknięty"]
        E2["DuckDB\nplik DB → zamknięty"]
        E3["Brak wycieków gniazd\nw długo działających procesach"]
    end

    C1 --> E1
    C2 --> E2
    C3 --> E3
    C4 --> E1
```

| Serwis | Zasób | Metoda |
|---|---|---|
| `WhiteListService` | `CachedHttpClient` (httpx + hishel) | `await self._http.close()` |
| `CurrencyConverter` | `DuckDBPyConnection` | `self._conn.close()` |
| `ContextEnricher` | `WhiteListService` + DuckDB | `await self._white_list.close()` + `self._conn.close()` |
| `CachedHttpClient` | `httpx.AsyncClient` (connection pool) | `await self._client.aclose()` |

---

## 10. Architektura v2.0 (historyczna)

Poprzednia architektura wieloagentowa została uproszczona. Poniższy diagram jest zachowany jako dokumentacja stanu poprzedniego.

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark", "themeVariables": {"fontSize": "12px"}}}%%
flowchart TB
    subgraph Old["🧠 AgentOrchestrator (v2.0 — historyczny)"]
        direction TB
        AO["AgentOrchestrator"]
        WP["WorkflowPlanner\nLittleLamb 0.3B"]
        CA["Council of Agents\nAlpha (LFM2.5) / Beta (Qwen3) /\nGamma (LittleLamb)"]
        RST["Rules SWAT Team\nL1 (LFM2.5) / L2 (Granite) /\nL3 (LittleLamb) / L4 (Fin-RWKV)"]
        TC["TrustScoreCalculator\n5 składników"]
        JS["JambaStrategist\nJamba 3B"]
        BL["BayesianThresholdLearner\nBeta posterior"]
        PLE["PLE Engine\nSTM → LTM → FM"]
        AO --> WP --> CA --> RST --> TC --> JS --> BL --> PLE
    end

    subgraph New["DecisionEngine (v2.3 — aktualny)"]
        DE["DecisionEngine\ncore/decision_engine.py"]
        CI2["classify_invoice()\n<1ms"]
        TS2["calculate_trust_score()\n<1ms"]
        FW2["_match_condition()\n<5ms"]
        DE --> CI2
        DE --> TS2
        DE --> FW2
    end

    subgraph Legend["Legenda"]
        L1["v2.0: ~7.7–18.3s, ~2.2 GB RAM peak"]
        L2["v2.3: ~0.2–0.4s, ~200 MB RAM baseline"]
        L3["39–61× szybciej, 11× mniej RAM"]
    end
```

### Komponenty v2.0 → v2.3

| Komponent v2.0 | Model | Zastąpiony przez |
|---|---|---|
| Council of Agents | Alpha (LFM2.5), Beta (Qwen3), Gamma (LittleLamb) | `DecisionEngine.decide()` + DuckDB `decision_rules` |
| WorkflowPlanner | LittleLamb 0.3B | `classify_invoice()` |
| JambaStrategist | Jamba 3B | `DecisionEngine.decide()` |
| Rules SWAT Team | LFM2.5, Granite, LittleLamb, Fin-RWKV | Hierarchiczne reguły DuckDB |
| TrustScoreCalculator | — | `calculate_trust_score()` |
| PLE Engine | — | `DecisionLogger.get_trust_score_trend()` |
| BayesianThresholdLearner | — | Statystyki w DuckDB |
| AgentOrchestrator | — | `services/council_session.py`, `services/autopilot.py` (DEPRECATED) |

---

> **Dokumentacja techniczna** — NexusAI v2.3
> **Ostatnia aktualizacja:** 2026-06-10
> **Plik:** `docs/ARCHITECTURE_DIAGRAM.md`
