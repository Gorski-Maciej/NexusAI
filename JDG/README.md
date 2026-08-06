# 🏛️ NexusAI JDG — Silnik Reguł Podatkowych dla Jednoosobowej Działalności Gospodarczej

> **Status:** 🟢 PRODUCTION — ENTERPRISE v8.0
> **Reguły:** ~11 452 unikalnych `rule_id` | **Pliki Rego:** 439 | **Akty prawne:** 13 | **Inicjatywy strategiczne:** 24 (A1–C3, S1–S24)
> **Data wydania:** 2026-08-02 | **Licencja:** MIT

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
| **Silnik reguł Rego (JDG/rules)** | 🟢 **PRODUCTION** | 439 plików, ~11 452 rule_id, First-Match-Wins |
| **API (JDG/api/openapi.yaml)** | 🟢 **PRODUCTION (spec 1.0.0)** | 10 endpointów, JWT Bearer |
| **RuleStore DuckDB (JDG/migrations)** | 🟡 **BETA** | 9 tabel, 2 migracje, seed 50 progów |
| **Bundle OPA (JDG/bundles)** | 🟢 **PRODUCTION** | bundle.sh v8.0, manifest 10 878 reguł |
| **Narzędzia (JDG/tools)** | 🟢 **PRODUCTION** | 57+ narzędzi, ~22 500 linii |
| **Testy (JDG/tests)** | 🟡 **BETA** | pytest + natywne testy Rego (`tests/rego/`, `tests/micro/`) |
| **policies/ (mirror reguł)** | 🟡 **BETA** | 32 pakietów, bundle z overlays v2026/v2027 |

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
- **🧩 Warstwa mikro-atomowa** — 106+ plików `rules/micro/` z regułami per artykuł ustawy (ADR-010).
- **📡 Integracje zewnętrzne** — KSeF, JPK, Biała Lista MF, CEIDG, NBP, ISAP (crawler aktów prawnych), e-Doręczenia, ePUAP, WIS.
- **🗂️ Enterprise S1–S24** — optymalizacja podatkowa, cross-domain intelligence, predykcja wyroków, KSeF resilience, automatyzacja bankowości (PSD2/PolishAPI), auto-deklaracje PIT-36/36L/28, JPK_V7M, monitor legislacyjny.
- **🧪 57+ narzędzi deweloperskich** — linter Rego, walidator, generator manifestu, detektor martwych reguł, chaos engineering, self-healing engine.

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
| **Developer / DevOps** | Integracja API, budowa bundle, rozwój reguł | OpenAPI 3.0, 57 narzędzi, CI/CD |
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
| Pliki Rego | **439** |
| Pliki z `matched: true` | **404** |
| Bloki `matched: true` | **11 821** |
| Unikalne `rule_id` | **11 452** |
| Duplikaty `rule_id` | 369 |
| Akty prawne pokryte | **13** |
| Inicjatywy strategiczne | 24 (A1–A3, B1–B3, C1–C3, S1–S24) |
| Pakiety w orkiestratorze | ~60+ |
| Completeness Score (MANIFEST) | 🟢 93/100 |
| Reguły w bundle | 10 878 (bundle manifest 2026-08-02; aktualizowany przy `bundle.sh`) |

### Warstwy architektury reguł

| Warstwa | Plików | Reguł | Opis |
|---|---:|---:|---|
| **Macro (Core)** | ~153 | ~6 300 | Reguły decyzyjne: VAT, PIT, ZUS, KKS, PKPiR, cross-border |
| **Micro (atomowe)** | ~106 | ~3 500 | Atomowe reguły per artykuł ustawy |
| **Enterprise S1–S24** | 25+ | ~350 | Optymalizacja, cross-domain, KSeF, deklaracje, monitoring |
| **Hyper Plan45** | 14 | ~450 | Reguły hiper-szczegółowe (terminy, limity, sankcje, e-Doręczenia) |

---

## 📖 Dokumentacja — spis treści

| Dokument | Zakres | Dla kogo |
|---|---|---|
| **[docs/ARCHITEKTURA.md](docs/ARCHITEKTURA.md)** | C4 (Context/Container/Component), warstwy, wzorce projektowe, diagramy sekwencji, ADR 001–015 | Architekci, developerzy |
| **[docs/STRUKTURA_PROJEKTU.md](docs/STRUKTURA_PROJEKTU.md)** | Drzewo katalogów, konwencje nazewnicze, ERD, 9 tabel RuleStore, migracje i seed | Developerzy, DevOps |
| **[docs/API_REFERENCJA.md](docs/API_REFERENCJA.md)** | 10 endpointów REST, request/response, curl, rate limiting, kody błędów | Integratorzy, frontend |
| **[docs/LOGIKA_BIZNESOWA.md](docs/LOGIKA_BIZNESOWA.md)** | Moduły i algorytmy, diagramy sekwencji procesów krytycznych, błędy i debugowanie | Developerzy, testerzy |
| **[docs/ZGODNOSC_PRAWNA.md](docs/ZGODNOSC_PRAWNA.md)** | UoR/IFRS/GAAP, KSeF, JPK, deklaracje VAT-7/CIT-8/PIT-36, ścieżka audytu, retencja | Compliance, księgowość |
| **[docs/PODRECZNIK_UZYTKOWNIKA.md](docs/PODRECZNIK_UZYTKOWNIKA.md)** | Pierwsze uruchomienie, role RBAC, workflow AUTO_POST/ASK_USER, centrum decyzji, integracje | Użytkownicy końcowi |
| **[docs/FAQ.md](docs/FAQ.md)** | Najczęściej zadawane pytania | Wszyscy |
| **[docs/KATALOG_REGUL.md](docs/KATALOG_REGUL.md)** | Katalog **wszystkich 439 plików Rego** (JDG/rules) + 76 pakietów policies — pakiety, reguły, rule_id | Developerzy, QA |
| **[docs/INWENTARYZACJA_PLIKOW.md](docs/INWENTARYZACJA_PLIKOW.md)** | Inwentaryzacja **wszystkich plików** JDG (1006) i policies (83) — statystyki per katalog | Wszyscy |
| **[docs/KATALOG_NARZEDZI.md](docs/KATALOG_NARZEDZI.md)** | Katalog **wszystkich 130 narzędzi** Python z opisami | Developerzy, DevOps |
| **[MANIFEST.md](MANIFEST.md)** | Tracker pokrycia reguł (auto-generowany) | QA, DevOps |
| **[COVERAGE_REPORT.md](COVERAGE_REPORT.md)** | Raport pokrycia prawnego (auto-generowany) | QA, compliance |
| **[api/openapi.yaml](api/openapi.yaml)** | Specyfikacja OpenAPI 3.0.3 | Integratorzy |

> **Dokumenty tematyczne P02–P24** (np. `docs/VAT_MACRO_P03.md`, `docs/ZUS_MICRO_P08.md`, `docs/AUDYT_KOMPLETNY_P24.md`) opisują poszczególne inicjatywy — pełna lista w `docs/`.

---

## 🧩 Struktura katalogów (skrócona)

```
JDG/
├── README.md                          ← ten dokument (strona główna)
├── MANIFEST.md                        # Tracker pokrycia reguł (auto)
├── COVERAGE_REPORT.md                 # Raport pokrycia prawnego (auto)
├── unified_plan_v8.yaml               # Plan strategiczny v8
├── rules/                             # 439 plików Rego (~11 452 rule_id)
│   ├── main_jdg.rego                  # 🧠 orkiestrator Multi-Pass + Sharded Router
│   ├── risk.rego / routing.rego / compliance.rego / kks.rego
│   ├── vat/ pit/ zus/ kks/ accounting/ crossborder/ pcc/
│   ├── micro/                         # ~106 plików atomowych per artykuł
│   └── *_enterprise.rego              # inicjatywy S1–S24
├── tests/                             # pytest + natywne testy Rego
├── tools/                             # 57+ narzędzi deweloperskich
├── bundles/                           # bundle.sh + manifest.json → OPA bundle
├── docs/                              # dokumentacja techniczna
├── api/openapi.yaml                   # specyfikacja REST API 1.0.0
├── migrations/                        # DuckDB RuleStore (001, 002)
└── policies/ (mirror w repo głównym)  # lżejsza wersja reguł + overlays
```

Pełne drzewo i konwencje: **[docs/STRUKTURA_PROJEKTU.md](docs/STRUKTURA_PROJEKTU.md)**.

---

## 🔗 Powiązane dokumenty

| Dokument | Opis |
|---|---|
| `Plan OPA/38c_JDG_CANONICAL_MAP.md` | Mapa kanoniczna ~779 reguł (źródło prawdy) |
| `Plan OPA/41_JDG_MEGA_MATRIX_7000_RULES.md` | Dual-Layer Architecture (horyzont ~7000) |
| `Plan OPA/52_AUDYT_JAKOSCI_REGUL.md` | Audyt jakości reguł |
| `NexusAI_JDG_7000_MASTER_IMPLEMENTATION_PLAN.txt` | Master plan strategiczny |

---

*Wygenerowano przez NexusAI JDG Module Engine v8.0 — liczby z MANIFEST.md (2026-08-05)*
*Regeneracja: `python JDG/tools/generate_manifest.py`*
