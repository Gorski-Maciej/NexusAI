# 🏛️ NexusAI JDG — Silnik Reguł Podatkowych dla Jednoosobowej Działalności Gospodarczej

> **Status:** 🟢 PRODUCTION — ENTERPRISE v8.0 | 🏁 **Certyfikacja końcowa ETAP 28/29 — WDROŻONY_100 (2026-08-22)**
> **Reguły:** ~11 855 unikalnych `rule_id` | **Pliki Rego:** 490 | **Akty prawne:** 13 | **Inicjatywy strategiczne:** 24 (A1–C3, S1–S24)
> **Data wydania:** 2026-08-02 (aktualizacja: 2026-08-30) | **Licencja:** MIT

```
╔══════════════════════════════════════════════════════════════════╗
║   NEXUSAI JDG — Policy-as-Code dla polskich jednoosobowych firm   ║
║   OPA/Rego · Multi-Pass · Sharded Router · Immutable Audit Trail  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 🎯 Misja

> **Automatyzować rozliczenia podatkowe polskich przedsiębiorców (JDG) do poziomu, w którym ~85% transakcji księguje się samodzielnie, z zerowym ryzykiem błędu i pełną audytowalnością każdej decyzji.**

NexusAI JDG zamienia skomplikowane, wielokrotnie nowelizowane prawo podatkowe (VAT, PIT, ZUS, KKS, Ordynacja Podatkowa, UoR, RODO, AML, KSeF, JPK) w **deterministyczny, testowalny i audytowalny zestaw reguł decyzyjnych**, które system może wykonać w czasie poniżej 12 ms na transakcję.

---

## 📋 Status produktu

| Obszar | Status | Uwagi |
|---|---|---|
| **Silnik reguł Rego (JDG/rules)** | 🟢 **PRODUCTION** | 490 plików, ~11 855 rule_id, First-Match-Wins |
| **API (JDG/api/openapi.yaml)** | 🟢 **PRODUCTION (spec 1.0.0)** | 17 endpointów, JWT Bearer |
| **RuleStore DuckDB (JDG/migrations)** | 🟡 **BETA** | 9 tabel, 13 migracji (001–013), seed 50 progów |
| **Bundle OPA (JDG/bundles)** | 🟢 **PRODUCTION** | bundle.sh v8.0, manifest, 22 audit-state |
| **Narzędzia (JDG/tools)** | 🟢 **PRODUCTION** | 298 narzędzi (~22 500+ linii) |
| **Testy (JDG/tests)** | 🟢 **PRODUCTION** | 198 pytest + 207 natywnych testów Rego (`tests/rego/`, `tests/micro/`) |
| **policies/ (mirror reguł)** | 🟢 **SYNCHRONIZED (ETAP 26)** | mirror z hash-parity 0% drift, bundle z overlays v2026/v2027 |

> 🔎 **Wyszukiwarka:** wpisz `Ctrl+F` → `status`, `produkcja`, `production`, `alpha`, `beta`, `enterprise v8` — każda sekcja opisuje swój stan wdrożenia.

---

## ✨ Kluczowe funkcje

- **🧠 Silnik decyzyjny Multi-Pass** — 9 przebiegów (PASS 0–8) + detekcja konfliktów międzydomenowych POST-MERGE (ADR-007).
- **⚡ Sharded Router (B1)** — routing O(1) po kontekście transakcji; p95 < 5 ms na shard (ADR-009).
- **📜 Pokrycie 13 aktów prawnych** — VAT, PIT, ZUS/SUS, Ordynacja Podatkowa, KKS, UoR, Prawo Przedsiębiorców, PCC, podatki lokalne + akcyza, ryczałt, sukcesja, RODO, AML/BDO.
- **🕰️ Temporalność reguł** — `valid_from`/`valid_to`; time-travel: werdykt liczony wg stanu prawnego z dnia transakcji (A2, ADR-003).
- **🔒 Immutable Audit Trail** — werdykty ZUS/zdrowotne podpisywane HMAC-SHA256 + Merkle Tree (A1, ADR-006).
- **📉 Zero Hardcoded Values** — stawki/progi/limity ładowane z DuckDB przez OPA Data API (`data.thresholds.jdg.*`) (B2, ADR-002).
- **🤖 Tryby automatyzacji** — `AUTO_POST` (≥0.92), `SUGGEST` (0.75–0.92), `ASK_USER` (<0.75).
- **🧩 Warstwa mikro-atomowa** — 91 plików `rules/micro/` z regułami per artykuł ustawy (ADR-010).
- **📡 Integracje zewnętrzne** — KSeF, JPK, Biała Lista MF, CEIDG, NBP, ISAP (crawler aktów prawnych), e-Doręczenia, ePUAP, WIS.
- **🗂️ Enterprise S1–S24** — optymalizacja podatkowa, cross-domain intelligence, predykcja wyroków, KSeF resilience, automatyzacja bankowości (PSD2/PolishAPI), auto-deklaracje PIT-36/36L/28, JPK_V7M, monitor legislacyjny.
- **🧪 298 narzędzi deweloperskich** — linter Rego, walidator, generator manifestu, detektor martwych reguł, chaos engineering, self-healing engine, audyty ETAP 10–28.

---

## 💡 Cel aplikacji — problem, który rozwiązuje (zasada PWE)

| Element | Opis |
|---|---|
| **P — Problem** | Przedsiębiorca JDG musi obsługiwać ~200+ obowiązków rocznie (VAT, PIT, ZUS, JPK, KSeF, PCC, BDO, RODO…). Prawo zmienia się kilkanaście razy w roku. Błąd = kara KKS do 25 lat pozbawienia wolności w skrajnych przypadkach, grzywny do 500 000 zł (KSeF) i odsetki. Księgowy ręcznie weryfikuje każdą fakturę. |
| **W — Wartość** | NexusAI JDG koduje prawo jako reguły OPA/Rego. Każda faktura jest automatycznie ewaluowana wg **prawa obowiązującego w dniu transakcji** (temporalność), z pełną podstawą prawną (`_legal_basis`) każdej decyzji i drzewem proweniencji. |
| **E — Efekt** | ~85% transakcji księguje się **zero kliknięć** (AUTO_POST), ~10–12% wymaga 1 kliknięcia (SUGGEST), ~3–5% trafia do człowieka (ASK_USER). Każdą decyzję można odtworzyć i udowodnić przed KAS. Latencja p95 < 5 ms na shard. |

---

## 👥 Główni użytkownicy i scenariusze użycia

| Użytkownik | Scenariusz | Korzyść |
|---|---|---|
| **Przedsiębiorca JDG** | Codzienne księgowanie faktur, deklaracje, terminy ZUS | Zero pracy ręcznej, zero ryzyka kary |
| **Księgowa / biuro rachunkowe** | Weryfikacja decyzji systemu, obsługa ASK_USER, korekty | 85% mniej rutynowej pracy, pełna dokumentacja |
| **Doradca podatkowy** | Analiza ryzyka (simulate), optymalizacja, obrona przed KAS | Symulacja kar, strategia 4-ścieżkowa KKS |
| **Developer / DevOps** | Integracja API, budowa bundle, rozwój reguł | OpenAPI 3.0, 298 narzędzi, CI/CD |
| **Audytor / KAS** | Weryfikacja historycznych decyzji | Merkle-proof, time-travel, niezmienny log |

---

## 📚 Słownik kluczowych pojęć (glosariusz)

> **Zasada spójności:** poniższe terminy są używane **jednolicie w całej dokumentacji** — nie zamieniaj „werdyktu" na „decyzję JSON", „bundle" na „paczkę OPA".

| Termin (synonimy) | Definicja |
|---|---|
| **Werdykt** (verdict, decyzja) | Standardowy obiekt JSON z 25 polami zwracany przez każdą regułę: `matched`, `rule_id`, `vat_rate`, `_legal_basis`, `_routing` itd. |
| **Reguła** (rule, decyzja regułowa) | Pojedyncza klauzula Rego `decide :=` z unikalnym `rule_id` w formacie `jdg.<domena>.<kategoria>`. |
| **Pakiet** (package, moduł reguł) | Przestrzeń nazw Rego `package jdg.<domena>` (np. `jdg.vat.substantive`). |
| **Orkiestrator** (main_jdg.rego) | Główny plik decyzyjny scala werdykty wszystkich pakietów w `final_verdict`. |
| **Przejście / PASS** (faza, pass) | Kolejny etap ewaluacji Multi-Pass (PASS 0: RISK … PASS 8: ZUS/KSeF). |
| **Shard** (ścieżka ewaluacji, shard routingu) | Wyspecjalizowany zestaw pakietów wybrany przez Sharded Router wg kontekstu transakcji. |
| **Próg** (threshold, stawka, limit) | Wartość podatkowa (stawka, limit, termin) przechowywana w DuckDB i dostarczana przez OPA Data API. |
| **Bundle** (paczkowanie OPA, rules bundle) | Archiwum `.tar.gz` z regułami + manifestem, wdrażane na serwer OPA. |
| **Kontekst routingu** (routing context) | Obiekt z flagami: `tax_form`, `transaction_type`, `entity_status`, `evaluation_quarter`, `is_cross_border`, `has_employees`, `is_vat_payer`, `requires_ksef`. |
| **Kod routingu** (action) | Decyzja kontrolna: `ALLOW` / `TRIAGE_QUEUE` / `BLOCK_AND_ALERT`. |
| **Tryb automatyzacji** | `AUTO_POST` (≥0.92), `SUGGEST` (0.75–0.92), `ASK_USER` (<0.75) — na podstawie Trust Score. |
| **Trust Score** | Wynik ufności (0.0–1.0) ekstrakcji AI (field confidence), decyduje o trybie automatyzacji. |
| **Provenance** (drzewo proweniencji, A1) | Pełna ścieżka decyzyjna: które pakiety, warunki i podstawy prawne złożyły się na werdykt. |
| **Temporalność** (time-travel, A2) | Mechanizm wyboru wersji reguły wg daty transakcji (`valid_from`/`valid_to`). |
| **RuleStore** (DuckDB RuleStore) | Baza DuckDB z progami, wersjami reguł i niezmiennym logiem werdyktów. |
| **Inicjatywa strategiczna** | Projekt S1–S24 / A1–C3 rozszerzający silnik (np. S21 VAT Complete, S22 auto-korespondencja z US). |
| **JDG** | Jednoosobowa Działalność Gospodarcza — polska forma działalności jednoosobowej. |
| **KAS / US** | Krajowa Administracja Skarbowa / Urząd Skarbowy. |

---

## 🏗️ Architektura w skrócie — C4 Level 1 (Context)

Pełne diagramy C4 (Context, Container, Component) znajdziesz w **[docs/ARCHITEKTURA.md](docs/ARCHITEKTURA.md)**.

```mermaid
flowchart LR
    subgraph Użytkownicy
        U1[Przedsiębiorca JDG]
        U2[Księgowa / biuro rachunkowe]
        U3[Doradca podatkowy]
        U4[Developer / DevOps]
    end

    subgraph NexusAI JDG
        API["JDG Decision API (Litestar REST)"]
        ENGINE["Silnik reguł OPA/Rego (Multi-Pass + Sharded Router)"]
        STORE["RuleStore DuckDB (progi, wersje, audyt)"]
    end

    subgraph "Systemy zewnętrzne"
        KSEF["KSeF — Krajowy System e-Faktur"]
        MF["Biała Lista MF / CEIDG"]
        NBP["NBP — kursy walut"]
        ISAP["ISAP — internetowy system aktów prawnych"]
        LLM["LLM Bridge (Gemini/Claude/GPT)"]
    end

    U1 --> API
    U2 --> API
    U3 --> API
    U4 --> API
    API --> ENGINE
    ENGINE --> STORE
    ENGINE --> KSEF
    ENGINE --> MF
    ENGINE --> NBP
    ENGINE --> ISAP
    API --> LLM
```

### C4 Level 2 — Container (Containers)

```mermaid
flowchart TB
    subgraph Klient
        C1[Klient REST / Flet UI]
    end

    subgraph NexusAI JDG
        A1["API Litestar<br/>REST + JWT (port 8000)"]
        OPA["OPA Server<br/>Silnik reguł Rego (port 8181)"]
        RS["RuleStore DuckDB<br/>progi, wersje, audyt"]
        LS["Serwis thresholdów<br/>OPA Data API (hot-reload)"]
        LL["LLM Bridge<br/>wyjaśnienia, asystent (C2)"]
        IS["ISAP Crawler<br/>monitoring prawa (C3)"]
    end

    C1 -->|HTTPS/JSON| A1
    A1 -->|POST /v1/jdg/decide| OPA
    OPA -->|data.thresholds| LS
    OPA -->|werdykt 25-polowy| A1
    A1 -->|zapis audytu| RS
    A1 -->|wyjaśnienia| LL
    IS -->|nowelizacje| RS
```

### C4 Level 3 — Component (struktura wewnętrzna OPA)

```mermaid
flowchart LR
    subgraph OPA — Silnik Rego
        M[main_jdg.rego<br/>Orkiestrator Multi-Pass]
        R[risk.rego / routing.rego<br/>PASS 0-1]
        C[compliance.rego / crossborder.rego<br/>PASS 2-3]
        V[vat/ pit/ zus/ accounting/<br/>PASS 4-8]
        E[enterprise S1-S24 + ETAP 10-28]
        G[core_guards_temporal_thresholds.rego<br/>INV-001..042]
        P[provenance.rego<br/>_provenance_tree + decision_hash]
    end

    M --> R
    M --> C
    M --> V
    M --> E
    M --> G
    M --> P

    subgraph Systemy zewnętrzne
        KSEF["KSeF / Biała Lista / NBP / CEIDG / GUS"]
        TH["data.thresholds.jdg.* (DuckDB)"]
    end

    C --> KSEF
    V --> TH
    G --> TH
```

### Warstwy architektoniczne

| Warstwa | Odpowiedzialność | Artefakty |
|---|---|---|
| **Domain** | Reguły prawne i decyzyjne JDG | 490 plików Rego (`JDG/rules/`), 459 pakietów |
| **Application** | Orkiestracja, kontrakt werdyktu, use-case'y | `main_jdg.rego`, Decision API, Control Plane |
| **Infrastructure** | RuleStore, OPA Data API, integracje zewnętrzne | DuckDB (001–013), threshold service, NATS |
| **Presentation** | REST API + Flet UI | Litestar, `api/openapi.yaml` |

### Wzorce projektowe

| Wzorzec | Opis | ADR |
|---|---|---|
| **First-Match-Wins (else-chain)** | Deterministyczna kolejność reguł | ADR-001 |
| **Multi-Pass Evaluation** | PASS 0–8 + POST-MERGE z early abort | ADR-007 |
| **Sharded Router (O(1))** | Routing po kontekście transakcji, p95 < 5 ms | ADR-009 |
| **Safe Merge** | Werdykty niemutowalne, allowlist, priority conflicts | INV-018/042 |
| **Temporalność reguł** | `valid_from`/`valid_to`, time-travel | ADR-003 |
| **Zero Hardcoded Values** | Progi/stawki przez OPA Data API | ADR-002 |
| **Immutable Audit Trail** | HMAC-SHA256 + Merkle Tree | ADR-006 |
| **Werdykt 25-polowy** | Standardowy kontrakt JSON | ADR-004 |
| **Decision Certificate F4** | Klasy pewności, pieczęć SHA-256→Merkle | ADR-019 |

Pełne diagramy i szczegóły: **[docs/ARCHITEKTURA.md](docs/ARCHITEKTURA.md)** (C4 L1–L3, wzorce, ADR 001–022).

### Diagramy sekwencji — procesy krytyczne

**Przetwarzanie faktury — od wpływu do decyzji:**

```mermaid
sequenceDiagram
    participant U as Klient REST
    participant API as API Litestar
    participant OPA as OPA (main_jdg.rego)
    participant TH as Thresholds (DuckDB)
    participant AU as Audit Trail

    U->>API: POST /jdg/decide (faktura)
    API->>API: autoryzacja JWT + walidacja wejścia
    API->>OPA: input {transaction, routing_context}
    OPA->>OPA: PASS 0 RISK → PASS 1 ROUTING (early abort?)
    OPA->>OPA: PASS 2-3 COMPLIANCE/CROSSBORDER (Biała Lista, WNT/WDT)
    OPA->>TH: data.thresholds.jdg.* (stawki, progi)
    OPA->>OPA: PASS 4-8 VAT/PIT/ZUS/ACCOUNTING + POST-MERGE
    OPA->>OPA: enforce() — INV-001..042 + Decision Certificate
    OPA-->>API: werdykt 25-polowy + _provenance_tree
    API->>AU: zapis niezmiennego audytu (HMAC + Merkle)
    API-->>U: 200 {verdict, routing, certainty_class}
```

**Proces decyzyjny (tryby automatyzacji):**

```mermaid
sequenceDiagram
    participant S as System
    participant D as Przedsiębiorca (Centrum decyzji)

    S->>S: Trust Score >= 0.92?
    alt TAK (CERTAIN, AUTO_POST_ALLOWED)
        S-->>D: AUTO_POST — zaksięgowano automatycznie
    else 0.75-0.92 lub CONDITIONAL (MANUAL_REVIEW)
        S-->>D: SUGGEST — 2-5 opcji do wyboru
        D-->>S: wybór opcji
    else < 0.75 lub NEEDS_ADVICE (CERTAINTY_BLOCKED)
        S-->>D: ASK_USER — pytanie z kontekstem
        D-->>S: decyzja + ewentualna korekta
    end
    S->>S: zapis decyzji w audit trail (niezmienny)
```

---

## 🚀 Szybki start

### Walidacja reguł OPA

```bash
# Składnia wszystkich reguł
opa check JDG/rules/ -b

# Testy natywne Rego
opa test JDG/tests/rego/ -v

# Walidacja jakości reguł (9 walidacji)
python JDG/tools/validate_rules.py --strict

# Linter 6-check
python JDG/tools/lint_rego_rules.py --check --strict
```

### Generacja manifestu i raportu pokrycia

```bash
python JDG/tools/generate_manifest.py          # odświeża MANIFEST.md
python JDG/tools/generate_coverage_report.py   # odświeża COVERAGE_REPORT.md
```

### Budowa i wdrożenie bundle OPA

```bash
cd JDG/bundles && bash bundle.sh v8.0.0
curl -X PUT --data-binary @jdg-bundle-v8.0.0.tar.gz \
     http://opa-server:8181/v1/bundles/jdg
```

### Test API (lokalnie)

```bash
curl -X POST http://localhost:8000/v1/jdg/decide \
  -H "Authorization: Bearer <JWT>" \
  -H "Content-Type: application/json" \
  -d @example_request.json
```

---

## 📈 Metryki (auto-generowane — patrz [MANIFEST.md](MANIFEST.md))

| Metryka | Wartość |
|---|---|
| Pliki Rego | **490** |
| Pliki z `matched: true` | **444** |
| Bloki `matched: true` | **11 855** |
| Unikalne `rule_id` | **11 855** |
| Duplikaty `rule_id` | 0 |
| Akty prawne pokryte | **13** |
| Inicjatywy strategiczne | 24 (A1–A3, B1–B3, C1–C3, S1–S24) |
| Pakiety w orkiestratorze | ~60+ |
| Completeness Score (MANIFEST) | 🟢 91/100 |
| Narzędzia Python (JDG/tools) | **298** |
| Testy pytest / natywne Rego | **198** / **207** |
| Migracje DuckDB | **13** (001–013) |
| Audit-state (ETAP 06–28) | **22** — wszystkie `WDROZONY_100` / `PASS` |
| Domeny po certyfikacji końcowej | **18** — 13 CERTIFIED, 5 CONDITIONAL, 0 BLOCKED |
| Raporty kampanii GLM 5.2 | **29/29** — `WDROZONY_100` |

### Warstwy architektury reguł

| Warstwa | Plików | Reguł | Opis |
|---|---:|---:|---|
| **Macro (Core)** | ~231 (root) | ~6 300 | Reguły decyzyjne: VAT, PIT, ZUS, KKS, PKPiR, cross-border |
| **Micro (atomowe)** | 91 | ~3 500 | Atomowe reguły per artykuł ustawy |
| **Enterprise S1–S24 + ETAP 10–28** | 40+ | ~1 000 | Optymalizacja, cross-domain, KSeF, deklaracje, monitoring, audyty |
| **Hyper Plan45** | 14 | ~450 | Reguły hiper-szczegółowe (terminy, limity, sankcje, e-Doręczenia) |

---

## 📖 Dokumentacja — spis treści

| Dokument | Zakres | Dla kogo |
|---|---|---|
| **[docs/ARCHITEKTURA.md](docs/ARCHITEKTURA.md)** | C4 (Context/Container/Component), warstwy, wzorce projektowe, diagramy sekwencji, ADR 001–022 | Architekci, developerzy |
| **[docs/STRUKTURA_PROJEKTU.md](docs/STRUKTURA_PROJEKTU.md)** | Drzewo katalogów, konwencje nazewnicze, ERD, tabele RuleStore, migracje (001–013) i seed | Developerzy, DevOps |
| **[docs/API_REFERENCJA.md](docs/API_REFERENCJA.md)** | 17 endpointów REST, request/response, curl, rate limiting, kody błędów | Integratorzy, frontend |
| **[docs/LOGIKA_BIZNESOWA.md](docs/LOGIKA_BIZNESOWA.md)** | Moduły i algorytmy, diagramy sekwencji procesów krytycznych, błędy i debugowanie | Developerzy, testerzy |
| **[docs/ZGODNOSC_PRAWNA.md](docs/ZGODNOSC_PRAWNA.md)** | UoR/IFRS/GAAP, KSeF, JPK, deklaracje VAT-7/CIT-8/PIT-36, ścieżka audytu, retencja | Compliance, księgowość |
| **[docs/PODRECZNIK_UZYTKOWNIKA.md](docs/PODRECZNIK_UZYTKOWNIKA.md)** | Pierwsze uruchomienie, role RBAC, workflow AUTO_POST/ASK_USER, centrum decyzji, integracje | Użytkownicy końcowi |
| **[docs/FAQ.md](docs/FAQ.md)** | Najczęściej zadawane pytania | Wszyscy |
| **[docs/KATALOG_REGUL.md](docs/KATALOG_REGUL.md)** | Katalog **wszystkich 490 plików Rego** (JDG/rules) + pakiety policies — pakiety, reguły, rule_id | Developerzy, QA |
| **[docs/INWENTARYZACJA_PLIKOW.md](docs/INWENTARYZACJA_PLIKOW.md)** | Inwentaryzacja **wszystkich plików** JDG (1407) i policies (558) — statystyki per katalog | Wszyscy |
| **[docs/KATALOG_NARZEDZI.md](docs/KATALOG_NARZEDZI.md)** | Katalog **wszystkich 298 narzędzi** Python z opisami | Developerzy, DevOps |
| **[MANIFEST.md](MANIFEST.md)** | Tracker pokrycia reguł (auto-generowany) | QA, DevOps |
| **[COVERAGE_REPORT.md](COVERAGE_REPORT.md)** | Raport pokrycia prawnego (auto-generowany) | QA, compliance |
| **[api/openapi.yaml](api/openapi.yaml)** | Specyfikacja OpenAPI 3.0.3 | Integratorzy |

> **Dokumenty tematyczne P02–P24** (np. `docs/VAT_MACRO_P03.md`, `docs/ZUS_MICRO_P08.md`, `docs/AUDYT_KOMPLETNY_P24.md`) opisują poszczególne inicjatywy — pełna lista w `docs/`.
> **Kampania GLM 5.2 (ETAP 10–28):** [`docs/KAMPANIA_GLM52_ETAPY_10_28.md`](docs/KAMPANIA_GLM52_ETAPY_10_28.md) — audyty, certyfikacja końcowa, bramki.

---

## 🧩 Struktura katalogów (skrócona)

```
JDG/
├── README.md                          ← ten dokument (strona główna)
├── MANIFEST.md                        # Tracker pokrycia reguł (auto)
├── COVERAGE_REPORT.md                 # Raport pokrycia prawnego (auto)
├── unified_plan_v8.yaml               # Plan strategiczny v8
├── rules/                             # 490 plików Rego (~11 855 rule_id)
│   ├── main_jdg.rego                  # 🧠 orkiestrator Multi-Pass + Sharded Router
│   ├── risk.rego / routing.rego / compliance.rego / kks.rego
│   ├── vat/ pit/ zus/ kks/ accounting/ crossborder/ pcc/
│   ├── micro/                         # 91 plików atomowych per artykuł
│   └── *_enterprise.rego              # inicjatywy S1–S24
├── tests/                             # pytest + natywne testy Rego
├── tools/                             # 298 narzędzi deweloperskich
├── bundles/                           # bundle.sh + manifest.json → OPA bundle
├── docs/                              # dokumentacja techniczna
├── api/openapi.yaml                   # specyfikacja REST API 1.0.0
├── migrations/                        # DuckDB RuleStore (001–013)
└── policies/ (mirror w repo głównym)  # lżejsza wersja reguł + overlays
```

Pełne drzewo i konwencje: **[docs/STRUKTURA_PROJEKTU.md](docs/STRUKTURA_PROJEKTU.md)**.

---

## 🔗 Powiązane dokumenty

| Dokument | Opis |
|---|---|
| `Plan OPA/38c_JDG_CANONICAL_MAP.md` | Mapa kanoniczna ~779 reguł (plan bazowy — przekroczony do 11 855) |
| `Plan OPA/41_JDG_MEGA_MATRIX_7000_RULES.md` | Dual-Layer Architecture (horyzont ~7000) |
| `Plan OPA/52_AUDYT_JAKOSCI_REGUL.md` | Audyt jakości reguł |
| `NexusAI_JDG_7000_MASTER_IMPLEMENTATION_PLAN.txt` | Master plan strategiczny |

---

*Wygenerowano przez NexusAI JDG Module Engine v8.0 — liczby z MANIFEST.md (2026-08-22)*
*Regeneracja: `python JDG/tools/generate_manifest.py`*
*Certyfikacja: ETAP 28/29 `final_certification_etap28_audit.py` — 14/14 bramek PASSED (2026-08-22)*
