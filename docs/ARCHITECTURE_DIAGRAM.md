# Diagram Architektury NexusAI

> **Wersja:** 2.0
> **Data:** 2026-06-09
> **Format:** Mermaid.js (flowchart, sequence, C4, state, class)

---

## Spis diagramów

1. Diagram warstwowy — 4 warstwy architektury
2. Przepływ decyzyjny AgentOrchestrator
3. Struktura RAG / FactsAggregator
4. Council of Agents — matryca 8 kombinacji
5. Trójwarstwowa pamięć PLE
6. Kaskada Rules SWAT Team
7. Bayesowskie adaptacyjne progi
8. Ekonomia poznawcza — koszty i wydajność
9. Diagram klas — FactSheet i OrchestratorDecision
10. Full system context — C4 poziom 1

---

## 1. Diagram warstwowy

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark", "themeVariables": {"fontSize": "14px", "primaryColor": "#1a1a2e", "secondaryColor": "#16213e", "tertiaryColor": "#0f3460"}}}%%
flowchart TB
    subgraph Warstwa0["🧠 Warstwa Orkiestracyjna"]
        direction TB
        AO["AgentOrchestrator\ncentralny mózg"]
        WP["WorkflowPlanner\nLittleLamb 0.3B\nsimple vs complex"]
        TC["TrustScoreCalculator\n5 komponentów\nai 0.30 + vendor 0.25 + data 0.20 + context 0.10 + risk 0.15"]
        JS["JambaStrategist\nJamba 3B\nAUTO_POST / SUGGEST / ESCALATE"]
        AO --> WP
        AO --> TC
        AO --> JS
    end

    subgraph Warstwa1["⚡ Warstwa Agentów i RAG"]
        direction TB
        RAG["FactsAggregator\nRAG Layer"]
        COA["Council of Agents"]
        RST["Rules SWAT Team"]
        PLE["PLE Engine"]
        RAG --> COA
        RAG --> RST
        COA --> JS
        RST --> JS
        PLE --> AO
    end

    subgraph Warstwa2["💾 Warstwa Danych"]
        direction TB
        SQL[("SQLite + SQLCipher\nOLTP")]
        DDB[("DuckDB\nOLAP")]
        SVEC[("sqlite-vec\nWektory")]
        TBDB[("TigerBeetle\nSecure Ledger")]
        SOP[("ProtocolLoader\nprotocols.toml")]
    end

    subgraph Warstwa3["📈 Warstwa Uczenia"]
        direction TB
        BL["BayesianThresholdLearner\nBeta posterior per (NIP, kat.)"]
        DL["DecisionLogger\ncouncil_decisions\ntrust_score_cache"]
        SG["SemanticGuard\nanomaly_rules\nsqlite-vec"]
        RG["RiskGuard\nrisk_thresholds"]
    end

    %% Połączenia między warstwami
    RAG --> SQL
    RAG --> DDB
    RAG --> SVEC
    RAG --> TBDB
    AO --> SOP
    BL --> JS
    DL --> RAG
    SG --> RAG
    RG --> TC
    PLE --> BL
    PLE --> DL
    PLE --> COA
    WP --> RAG

    style Warstwa0 fill:#1a1a2e,stroke:#e94560,stroke-width:2px
    style Warstwa1 fill:#16213e,stroke:#0f3460,stroke-width:2px
    style Warstwa2 fill:#0f3460,stroke:#533483,stroke-width:2px
    style Warstwa3 fill:#1a1a2e,stroke:#e94560,stroke-width:2px,stroke-dasharray:5,5
```

---

## 2. Przepływ decyzyjny

```mermaid
%%{init: {"sequence": {"showSequenceNumbers": true}, "theme": "dark"}}%%
sequenceDiagram
    actor User as Użytkownik
    participant AO as AgentOrchestrator
    participant RAG as FactsAggregator
    participant DB as SQLite/DuckDB
    participant WP as WorkflowPlanner
    participant CA as Council of Agents
    participant TC as TrustScoreCalculator
    participant RG as RiskGuard
    participant JS as JambaStrategist
    participant BL as BayesianThreshold
    participant PLE as PLE Engine
    participant DL as DecisionLogger

    Note over AO,DL: Krok 0 — RAG
    AO->>+RAG: build(invoice_data)
    RAG->>DB: 4 źródła równolegle
    DB-->>RAG: FactSheet
    RAG-->>-AO: FactSheet

    Note over AO,DL: Krok 1 — Plan
    AO->>+WP: plan(invoice_data, fact_sheet_text)
    WP-->>-AO: plan [simple / complex]

    Note over AO,DL: Krok 1b — Few-shot
    AO->>RAG: build_few_shot_examples()
    RAG-->>AO: few_shot_text

    alt Simple (fast-path)
        Note over AO,DL: Krok 2a — Alpha fast-path
        AO->>+CA: Alpha (LFM2.5)
        CA-->>-AO: APPROVE ≥ 0.92 → AUTO_POST
    else Complex
        Note over AO,DL: Krok 2b — Pełna rada
        AO->>+CA: Alpha + Beta + Gamma
        CA-->>-AO: council_verdict + trust_score
        AO->>+TC: calculate()
        TC-->>-AO: trust_components
        AO->>+RG: evaluate()
        RG-->>-AO: risk_verdict
    end

    Note over AO,DL: Krok 3 — Strategia
    AO->>+JS: analyze(fact_sheet, few_shot, raporty)
    JS-->>-AO: jamba_result

    Note over AO,DL: Krok 4 — Bayesowski override
    AO->>+BL: get_thresholds(contractor_nip, category)
    BL-->>-AO: adapted_thresholds
    Note over AO: if confidence < threshold → downgrade

    Note over AO,DL: Krok 5 — PLE
    AO->>+PLE: record_decision()
    PLE-->>-AO: ple_pattern

    Note over AO,DL: Krok 6 — Logowanie
    AO->>+DL: log_decision()
    DL-->>-AO: logged

    AO-->>-User: OrchestratorDecision
```

---

## 3. Struktura RAG

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
        M1["to_prompt_section()\n→ sekcja === ARKUSZ FAKTÓW ==="]
        M2["to_dict()\n→ JSON dla audytu"]
        M3["build_few_shot_examples(max=3)\n→ dynamiczne few-shot"]
    end

    Sheet --> Methods

    subgraph FewShot["🎯 Źródła few-shot (priorytet)"]
        FS1["1. similar_invoices\n(semantycznie podobne)"]
        FS2["2. global_recent_decisions\n(globalna baza)"]
        FS3["3. recent_invoices\n(historia kontrahenta)"]
    end

    M3 --> FewShot
```

---

## 4. Council of Agents

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart TB
    subgraph Agents["👥 Trójwarstwowa Rada Agentów"]
        direction LR
        A["Alpha (LFM2.5 1.2B)\nOcena kontekstowa\n~780 MB RAM"]
        B["Beta (Qwen3 0.6B)\nPrecyzyjna walidacja\nNIP, kwoty, daty\n~430 MB RAM"]
        G["Gamma (LittleLamb 0.3B)\nDetekcja duplikatów\nanomalii\n~250 MB RAM"]
    end

    subgraph FastPath["⚡ Fast-path"]
        FP["Alpha ≥ 0.92 conf?\n→ pomiń Beta i Gamma\n→ AUTO_POST\noszczędność ~70% czasu"]
    end

    subgraph Matrix["📊 Matryca 8 kombinacji"]
        direction TB
        M1["FULL_APPROVE ✅✅✅ → AUTO_POST"]
        M2["CONTEXT_ANOMALY ✅❌✅ → SUGGEST"]
        M3["CONTEXT_PRECISION ✅✅❌ → SUGGEST"]
        M4["CONTEXT_ONLY ✅❌❌ → ASK_USER"]
        M5["PRECISION_ANOMALY ❌✅✅ → ASK_USER"]
        M6["ANOMALY_ONLY ❌❌✅ → ASK_USER"]
        M7["PRECISION_VETO ❌✅❌ → BLOCK"]
        M8["FULL_REJECT ❌❌❌ → BLOCK"]
    end

    A -->|PASS| B
    A -->|PASS| G
    B -->|PASS| G
    A -->|conf ≥ 0.92| FastPath
    A --> Matrix
    B --> Matrix
    G --> Matrix

    subgraph Emergency["🚨 Protokoły awaryjne"]
        E1["model_timeout → ASYNC_FALLBACK"]
        E2["model_error → PARSE_FALLBACK"]
        E3["model_crash → SAFE_DEFAULT (ESCALATE)"]
        E4["unknown_voting → SAFE_ESCALATE"]
    end

    Matrix -->|nieznana kombinacja| Emergency
```

---

## 5. Trójwarstwowa pamięć PLE

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart TB
    subgraph PLE["🧠 Perpetual Learning Engine"]
        direction TB
        
        subgraph STM["STM — Short-Term Memory"]
            STM1["Ostatnie 50 decyzji"]
            STM2["TTL: 24h"]
            STM3["Data decay co 5 min"]
            STM4["asyncio.Lock"]
        end

        subgraph LTM["LTM — Long-Term Memory"]
            LTM1["∞ pojemność\n100 per bucket"]
            LTM2["Indeks: (NIP, kategoria)"]
            LTM3["Retention decay: 0.95^age"]
            LTM4["Funkcje:\n· get_vendor_profile()\n· query()"]
        end

        subgraph FM["FM — Fusion Memory"]
            FM1["200 artifactów max"]
            FM2["Typy:\n· decision_cache\n· pattern\n· anomaly_insight"]
            FM3["Min frequency: 2"]
            FM4["Kompresja co 1h\n(frequency < 2 lub wiek > 7d → usuń)"]
        end

        subgraph Promotion["⬆️ Automatyczna promocja"]
            P1["Każda decyzja → STM.push()"]
            P2["↓\nLTM.store()"]
            P3["↓\n3+ AUTO_POST? → FM.add_decision_cache()"]
            P4["↓\nWszystkie AUTO_POST? → FM.add_pattern()"]
            P5["↓\nBLOCK/ASK_USER z trust < 0.5?\n→ FM.add_anomaly_insight()"]
        end

        STM --> LTM
        LTM --> FM
        Promotion --> STM
        Promotion --> LTM
        Promotion --> FM
    end

    subgraph Decision["🔗 Wpływ na decyzje"]
        D1["FM ma wzorzec dla (NIP, kat.)\nz confidence ≥ 0.85?"]
        D2["Tak → auto_post -= 0.05\n(minimum 0.70)"]
        D3["Nie → standardowe progi"]
    end

    FM --> Decision
```

---

## 6. Kaskada Rules SWAT Team

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart TB
    subgraph SWAT["🔫 Rules SWAT Team — kaskada 4 poziomów"]
        direction TB

        L1["Level 1: LFM2.5-Thinking (1.2B)\nWalidacja wstępna\n→ COMPLIANT z conf ≥ 0.90?"]
        L1 -->|"Tak (fast-path)"| STOP1["⏹ STOP — zgodne"]
        L1 -->|"FLAG"| L2

        L2["Level 2: Granite 4.0 1B Nano\nWalidacja biznesowa\nNIP, limity, polityka\n→ passed=true?"]
        L2 -->|"Tak"| STOP2["⏹ STOP — zgodne"]
        L2 -->|"Nie (violations)"| L3

        L3["Level 3: LittleLamb 0.3B TC\nTernary Classifier\n→ COMPLIANT / FLAG / VIOLATION?"]
        L3 -->|"COMPLIANT / FLAG"| STOP3["⏹ STOP — zaakceptowane"]
        L3 -->|"VIOLATION"| L4

        L4["Level 4: Fin-RWKV-169M\nKońcowa weryfikacja\n→ LOW / MEDIUM / HIGH"]
        L4 --> LOW["✅ LOW → AUTO_POST"]
        L4 --> MED["⚠️ MEDIUM → SUGGEST"]
        L4 --> HIGH["🚫 HIGH → BLOCK"]
    end
```

---

## 7. Bayesowskie adaptacyjne progi

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart LR
    subgraph Prior["📥 Prior"]
        P["Beta(α=2, β=2)\nlekki sceptycyzm"]
    end

    subgraph Update["🔄 Aktualizacja"]
        U1["Nowa decyzja użytkownika"]
        U2["Waga decyzji:\n<100 PLN → 0.5\n100-1000 → 1.0\n1000-10000 → 1.5\n>10000 → 2.0"]
        U3["Auto-decyzja: 0.3 × waga"]
        U4["Posterior:\nBeta(α+success, β+failure)"]
    end

    subgraph Threshold["📊 Obliczenie progu"]
        T1["n < 6?\n→ Heurystyka:\nmean + 2×uncertainty\nminimum 0.85"]
        T2["n ≥ 6?\n→ Logit-normal\napproximation\n(delta method)"]
        T3["→ inverse CDF\nP(X > threshold) = percentile"]
    end

    subgraph Hierarchy["🏛️ Hierarchia"]
        H1["1. (NIP, kategoria)\nnajbardziej specyficzny"]
        H2["2. (NIP, __global__)\nogólny dla kontrahenta"]
        H3["3. BetaPosterior()\ndomyślny prior"]
    end

    subgraph Override["⚡ Bayesowski override"]
        O1["Jamba → AUTO_POST\nale conf < bayesowski threshold?"]
        O2["Tak → downgrade do\nSUGGEST lub ASK_USER"]
        O3["Na odwrót →\nupgrade do AUTO_POST"]
    end

    Prior --> Update
    Update --> Threshold
    Threshold --> Hierarchy
    Hierarchy --> Override

    subgraph Storage["💾 Persistence (SQLite)"]
        S1["bayesian_posteriors\ncontractor_nip TEXT\ncategory TEXT\nalpha REAL\nbeta REAL\ntotal_decisions INT"]
    end

    Update --> Storage
```

---

## 8. Ekonomia poznawcza

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart LR
    subgraph FastPath["⚡ Szybka ścieżka ~7.7s"]
        F1["WorkflowPlanner\n0.5s / 500 MB"]
        F2["FactsAggregator\n0.1s / 0 MB"]
        F3["Alpha fast-path\n2s / 1.0 GB"]
        F4["TrustScore + RiskGuard\n0.1s / 0 MB"]
        F5["JambaStrategist\n5s / 2.0 GB"]
        F6["Bayesian + PLE\n0.1s / 0 MB"]
        F1 --> F2 --> F3 --> F4 --> F5 --> F6
    end

    subgraph FullPath["🔬 Pełna ścieżka ~18.3s"]
        L1["WorkflowPlanner\n0.5s / 500 MB"]
        L2["FactsAggregator\n0.1s / 0 MB"]
        L3["Alpha+Beta+Gamma\n6s / ~2.4 GB"]
        L4["Rules SWAT L1-L4\n6.5s / ~2.5 GB"]
        L5["TrustScore + RiskGuard\n0.1s / 0 MB"]
        L6["JambaStrategist\n5s / 2.0 GB"]
        L7["Bayesian + PLE\n0.1s / 0 MB"]
        L1 --> L2 --> L3 --> L4 --> L5 --> L6 --> L7
    end

    subgraph MemMgmt["🗑️ Zarządzanie pamięcią"]
        M1["Lazy loading\n— modele przy pierwszym zadaniu"]
        M2["Explicit unloading\n— del model + gc.collect()"]
        M3["Mutual exclusion\n— asyncio.Semaphore(1)"]
        M4["TTL 5 min\n— auto wyładowanie"]
    end
```

---

## 9. Diagram klas

```mermaid
%%{init: {"theme": "dark"}}%%
classDiagram
    class FactSheet {
        +str invoice_id
        +str contractor_nip
        +str contractor_name
        +float amount_net
        +float amount_gross
        +str category
        +str issue_date
        +bool contractor_known
        +int contractor_invoice_count
        +float contractor_trust_score
        +str contractor_vat_status
        +list[dict] recent_invoices
        +list[dict] user_correction_patterns
        +dict trust_score_trend
        +list[dict] active_tax_rules
        +str vendor_intelligence
        +dict correction_stats
        +list[dict] similar_invoices
        +list[dict] global_recent_decisions
        +bool ledger_available
        +dict ledger_accounts
        +float ledger_total_turnover
        +list[dict] ledger_recent_transfers
        +dict sources_available
        +float build_duration_ms
        +str to_prompt_section()
        +dict to_dict()
        +str build_few_shot_examples(max_examples=3)
    }

    class OrchestratorDecision {
        +str decision
        +float confidence
        +str reasoning
        +list[str] workflow_plan
        +CouncilVerdict council_verdict
        +dict trust_components
        +dict adapted_thresholds
        +dict ple_pattern
        +dict risk_verdict
        +str strategy_summary
        +str jamba_analysis
        +dict granite_context
    }

    class AgentOrchestrator {
        +WorkflowPlanner planner
        +TrustScoreCalculator trust_calc
        +JambaStrategist strategist
        +FactsAggregator facts_agg
        +DecisionLogger decision_logger
        +PLEEngine ple_engine
        +BayesianThresholdLearner bayesian
        +OrchestratorDecision orchestrate(invoice_data)
    }

    class FactsAggregator {
        -SQLiteSession _sqlite
        -DuckDBManager _duckdb
        -VectorStore _vector_store
        -TigerBeetleClient _tigerbeetle
        -DecisionLogger _decision_logger
        +FactSheet build(invoice_data)
        -dict _fetch_contractor()
        -dict _fetch_recent_invoices()
        -dict _fetch_duckdb_sources()
        -dict _fetch_similar_invoices()
        -dict _fetch_ledger_history()
        -dict _fetch_global_decisions()
    }

    class PLEEngine {
        -STM stm
        -LTM ltm
        -FM fm
        +record_decision(decision)
        +query_adaptive_thresholds()
        -_promote_to_ltm()
        -_promote_to_fm()
        +get_vendor_profile(nip)
    }

    class BayesianThresholdLearner {
        -BetaPrior prior
        +get_thresholds(contractor_nip, category)
        +record_auto_decision(contractor_nip, category, success, amount)
        +record_user_correction(contractor_nip, category, corrected, amount)
    }

    class QualityValidatorAgent {
        +validate(context)
        +_vote_alpha()
        +_vote_beta()
        +_vote_gamma()
        +_fast_path()
        +_resolve()
    }

    class ProtocolLoader {
        -dict protocols
        +get_protocol(path)
        +get_decision_matrix(name)
        +get_thresholds_with_adaptations(cat, vendor, amount)
        +get_emergency_protocol(name)
        +build_system_prompt(name)
        +reload()
    }

    AgentOrchestrator --> FactsAggregator
    AgentOrchestrator --> OrchestratorDecision
    AgentOrchestrator --> PLEEngine
    AgentOrchestrator --> BayesianThresholdLearner
    FactsAggregator --> FactSheet
    QualityValidatorAgent --> ProtocolLoader
```

---

## 10. Full System Context — C4

```mermaid
%%{init: {"flowchart": {"defaultRenderer": "elk"}, "theme": "dark"}}%%
flowchart TB
    User(("👤 Użytkownik\n(Księgowy / CFO)"))
    External("📄 System zewnętrzny\n(OCR, API bankowe,\nKSeF, GUS BIR)")

    subgraph System["NexusAI — System decyzyjny"]
        direction TB

        subgraph API["🔌 API / CLI"]
            API1["FastAPI / CLI\nPunkt wejścia"]
            API2["Background Tasks\nCelery / asyncio"]
        end

        subgraph Core["🧠 Core"]
            C1["AgentOrchestrator\nKoordynator"]
            C2["FactsAggregator\nRAG Layer"]
            C3["ProtocolLoader\nSOP Engine"]
        end

        subgraph Agents["🤖 Agenci"]
            A1["WorkflowPlanner\nLittleLamb 0.3B"]
            A2["Council of Agents\nAlpha / Beta / Gamma"]
            A3["Rules SWAT Team\nL1-L4 kaskada"]
            A4["JambaStrategist\nJamba 3B"]
        end

        subgraph Learning["📚 Uczenie"]
            L1["PLE Engine\nSTM / LTM / FM"]
            L2["BayesianThreshold\nBeta posterior"]
            L3["DecisionLogger\nDuckDB"]
            L4["SemanticGuard\nsqlite-vec"]
            L5["RiskGuard\nDuckDB"]
        end

        subgraph Storage["💾 Przechowywanie"]
            S1[("SQLite + SQLCipher\nInvoice, Contractor")]
            S2[("DuckDB\nAnalytics, Rules")]
            S3[("sqlite-vec\nEmbeddings")]
            S4[("TigerBeetle\nSecure Ledger")]
            S5[("Config\nprotocols.toml")]
        end
    end

    User --> API1
    External --> API1
    API1 --> C1
    C1 --> C2
    C1 --> C3
    C1 --> A1
    C1 --> A2
    C1 --> A3
    C1 --> A4
    C1 --> L1
    C1 --> L2
    C1 --> L3
    C2 --> S1
    C2 --> S2
    C2 --> S3
    C2 --> S4
    A2 --> L4
    A4 --> L5
    L2 --> S1
    L3 --> S2
    L4 --> S3
    C3 --> S5

    style System fill:#1a1a2e,stroke:#e94560,stroke-width:2px
    style API fill:#16213e,stroke:#0f3460
    style Core fill:#0f3460,stroke:#533483
    style Agents fill:#1a1a2e,stroke:#e94560
    style Learning fill:#16213e,stroke:#0f3460
    style Storage fill:#0f3460,stroke:#533483
```

---

> **Dokumentacja techniczna** — NexusAI v2.0
> **Ostatnia aktualizacja:** 2026-06-09
> **Plik:** `docs/ARCHITECTURE_DIAGRAM.md`
