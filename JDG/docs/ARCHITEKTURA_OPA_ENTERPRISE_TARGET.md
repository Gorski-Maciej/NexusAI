<!--
artifacts: [docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md]
status: ACTIVE
owner: legal
verified: 2026-09-13
verify_cmd: python3 tools/v3_p60_engines.py I08
-->

# 🏆 ARCHITEKTURA DOCELOWA — SILNIK REGUŁ PODATKOWYCH OPA KLASY ENTERPRISE („ZA MILION DOLARÓW”)

> **Dokument:** ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md
> **Charakter:** specyfikacja docelowa (target architecture) — jak ma wyglądać najdoskonalszy system klasy ENTERPRISE, w którym **OPA jest SYSTEMEM**, a nie tylko silnikiem
> **Wymóg nadrzędny:** *prawo jest bardzo zmienne → zmiana reguł OPA oraz dodawanie i usuwanie reguł musi być sprawne, niezawodne, proste; silnik musi się szybko i profesjonalnie adaptować do zmian prawa*
> **Baza analityczna:** [ANALIZA_STANU_OPA_JAKO_SYSTEM.md](ANALIZA_STANU_OPA_JAKO_SYSTEM.md) (stan obecny JDG) + dobre praktyki branżowe Policy-as-Code (OPA bundles, signing, OPAL, Styra DAS-style control plane, conftest, GitOps)
> **Kontynuacja:** ten dokument to cel **V1**; ulepszona wizja V2 (niezachwiana pewność: Legal Twin, runtime invariants, dowód formalny, Decision Certificate, Law Radar, declarative change) znajduje się w [WIZJA_OPA_ENTERPRISE_V2.md](WIZJA_OPA_ENTERPRISE_V2.md)
> **Data:** 2026-08-07

---

## 0. Streszczenie kierownicze

System klasy ENTERPRISE dla zmiennego prawa podatkowego to **dwie płaszczyzny**:

1. **Control Plane** — warstwa, w której reguły się **tworzy, weryfikuje, testuje, wersjonuje, podpisuje, dystrybuuje, wdraża kanarkowo, monitoruje i wycofuje**. To tutaj rozstrzyga się „prostota i niezawodność zmian".
2. **Data Plane** — klastry serwerów OPA ewaluujące werdykty w mikrosekundy, z niezmiennym audytem.

Zasada przewodnia: **„zmiana prawa = zmiana danych lub mała zmiana reguły w zautomatyzowanym potoku, która nigdy nie może zepsuć produkcji i zawsze można ją cofnąć w minutę"**. Każda operacja na regułach (dodaj / zmień / usuń / wstrzymaj / cofnij) jest: **mierzalna, testowalna, audytowalna, odwracalna, automatycznie weryfikowana i nie wymaga wiedzy eksperckiej** — to jest sedno „prostoty".

Kluczowe liczby docelowe (SLO):

| Metryka | Cel |
|---|---|
| Czas od publikacji nowelizacji (Dz.U.) do reguł w produkcji | ≤ 24 h (rutynowo), ≤ 4 h (pilne/P0) |
| Czas zmiany samego parametru (stawka, próg, limit) | ≤ 15 min (bez bundle, hot-reload danych) |
| Dodanie nowej reguły (od PR do produkcji) | ≤ 2 h czasu maszynowego, ≤ 1 dzień kalendarzowy |
| Awaria/regresja wykryta i cofnięta | MTTR ≤ 15 min (auto-rollback ≤ 5 min) |
| Dostępność data plane | 99,95% (≤ 4,4 h przerwy rocznie) |
| Regresja reguł przedostająca się do produkcji | 0 (bramki blokujące + golden tests + replay historyczny) |
| Latencja p95 decyzji | < 5 ms krajowa, < 50 ms pełny łańcuch |
| Pokrycie reguł testami (natywne Rego) | ≥ 95% pakietów, 100% pakietów krytycznych |
| Duplikaty rule_id / stuby `{true}` w produkcji | 0 (blokowane w CI) |

---

## 1. Zasady nadrzędne (non-negotiable)

1. **Pojedyncze źródło prawdy (Single Source of Truth).** Jeden rejestr reguł (`rule_registry`), jeden manifest, jeden pipeline. Żadnych mirrorów (jak `rules/` vs `policies/`) — warianty czasowe wyłącznie przez **overlays** nakładane na ten sam bazowy zestaw reguł.
2. **Reguła = kod; Parametr = dane.** Logika prawna („jeżeli…to…") w wersjonowanym Rego; stawki/progi/limity/terminy wyłącznie w store danych z hot-reload. Zero wartości liczbowych w regułach (dokończenie ADR-002).
3. **Czas ma znaczenie (temporalność).** Każda reguła i każdy parametr ma `valid_from`/`valid_to`. Werdykt zawsze wg prawa obowiązującego w dniu transakcji (time-travel). Zmiana prawa wchodzi w życie automatycznie o wyznaczonej dacie — bez ręcznej akcji o północy.
4. **Nic nie trafia do produkcji bez testów i podpisu.** Bramki: składnia → semantyka → testy → mutation → golden-replay → podpis kryptograficzny. Bundle bez podpisu = odrzucony.
5. **Zmiana jest zawsze odwracalna.** Każda wersja reguły i każdy bundle jest niezmienny (immutable), wdrożenie jest kanarkowe/szare, a powrót do poprzedniej wersji jest jednym kliknięciem lub automatyczny.
6. **Prostota dla człowieka, złożoność dla maszyny.** Osoba dodająca regułę wypełnia deklaratywny szablon (metadata), a całą resztę (generowanie testów, lint, analiza wpływu, bundle, wdrożenie) wykonuje system automatycznie.
7. **Mierzalność i samouzdrowienie.** Każda operacja, każdy werdykt, każda zmiana — śledzone, z alertami i auto-rollbackiem przy naruszeniu progu jakości.
8. **Bezpieczeństwo łańcucha dostaw.** Klucze w HSM/KMS, podpisywanie bundle, weryfikacja na węzłach, SBOM, rotacja kluczy, WORM dla audytu.
9. **Zero-downtime.** Żadna zmiana (reguły, dane, infrastruktura) nie wymaga restartu ani przerwy.
10. **Enterprise-grade operacje.** Role i separacja obowiązków (4-eyes), runbooki, chaos engineering jako stały element, DR/BCP z RTO ≤ 15 min, RPO ≤ 5 min.

---

## 2. Architektura docelowa — diagram ogólny

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          WARSTWA ŹRÓDŁA PRAWA (Ingest)                        │
│  ISAP · legislacja.gov.pl · Dz.U. feedy · interpretacje · orzecznictwo NSA  │
│  → crawler 24/7 + AI-Reader (nowelizacje → ustrukturyzowany diff prawny)     │
└───────────────┬─────────────────────────────────────────────────────────────┘
                │ (nowelizacja, diff, impact)
                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CONTROL PLANE — POLICY AS CODE                        │
│  ┌────────────┐  ┌──────────────────┐  ┌────────────────────────────────┐   │
│  │ Policy     │  │ Policy Registry  │  │ CI/CD Policy Pipeline           │   │
│  │ Studio     │  │ (katalog reguł,  │  │ lint → test → mutation →        │   │
│  │ (IDE,      │  │  metadane,       │  │ golden-replay → impact →       │   │
│  │  szablony, │  │  wersje, owner,  │  │ bundle-build → sign → deploy    │   │
│  │  generators│  │  valid_from/to)  │  │ → canary → promote → monitor    │   │
│  └────────────┘  └──────────────────┘  └────────────────────────────────┘   │
│        │                  ▲                            │                     │
│        ▼                  │                            ▼                     │
│  ┌────────────┐   ┌───────┴────────┐   ┌────────────────────────────────┐   │
│  │ Rule       │   │ Data/Threshold │   │ Deployment Orchestrator         │   │
│  │ Lifecycle  │   │ Service        │   │ (bundle server, sign, delta,    │   │
│  │ (SHADOW→   │   │ (DuckDB/Postgres│  │  canary %, auto-rollback,       │   │
│  │ CANDIDATE→ │   │  hot-reload)   │   │  blue-green, kill-switch)       │   │
│  │ ACTIVE→    │   └────────────────┘   └────────────────────────────────┘   │
│  │ ROLLBACK)  │                                                             │
│  └────────────┘                                                             │
└───────────────┬─────────────────────────────────────────────────────────────┘
                │ (podpisany bundle + delta data, long-polling/OPAL)
                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DATA PLANE (ewaluacja)                                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐        (klaster OPA, HA,          │
│  │ OPA node │ │ OPA node │ │ OPA node │         WASM, cache,              │
│  └──────────┘ └──────────┘ └──────────┘         sharding, persist=true)    │
│         ▲                                        │                          │
│  API Gateway (Litestar) ← żądania /jdg/decide     ▼                          │
│  ┌────────────────────────────────────────────────────────────┐              │
│  │ RuleStore: thresholds · rule_versions · verdict_audit (WORM)│             │
│  └────────────────────────────────────────────────────────────┘              │
└───────────────┬─────────────────────────────────────────────────────────────┘
                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│              OBSERWOWALNOŚĆ + GOVERNANCE + BEZPIECZEŃSTWO                     │
│  Metrics (prometheus) · Tracing (OTel) · SLO dashboards · Decision Quality    │
│  Monitor · Drift/ISAP alarmy · Audit (Merkle/HMAC) · RBAC/SoD · HSM/KMS · SBOM │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.1. Control Plane — komponenty

| Komponent | Rola | Odpowiednik w JDG (baza) |
|---|---|---|
| **Policy Studio / IDE** | Edycja reguł w szablonach, podgląd metadanych, auto-uzupełnianie rule_id, symulacja werdyktu lokalnie | DEVELOPER_GUIDE, generatory reguł |
| **Policy Registry (API)** | Katalog wszystkich reguł i wersji z metadanymi (owner, źródło prawa, data obowiązywania, testy, status) — wyszukiwarka, API `/rules` | P21 INN-09 (`rule_registry_api`) |
| **Rule Lifecycle Manager** | Statusy SHADOW → CANDIDATE → ACTIVE → ROLLED_BACK; A/B rollout; kill-switch; hot-reload | RULE_LIFECYCLE.md, `rule_lifecycle_manager.py` |
| **CI/CD Policy Pipeline** | Bramki jakości + budowa + podpis + wdrożenie (pkt 5) | P22 `quality_pipeline`, P23 CI |
| **Data/Threshold Service** | Wersjonowane parametry z hot-reload, walidacja poprawności (np. stawka w dozwolonym zakresie) | DuckDB + OPA Data API (B2) |
| **Deployment Orchestrator** | Serwer bundle, podpisywanie, delta-bundles, dystrybucja long-polling, kanary, auto-rollback, blue-green | bundle.sh (baza), P21 canary/shadow (baza) |
| **Law-Change Pipeline** | ISAP → analiza → generacja → wdrożenie (pkt 4) | isap_crawler, isap_rule_update_pipeline |

### 2.2. Data Plane — komponenty

| Komponent | Rola |
|---|---|
| **Klastry OPA (PDP)** | Ewaluacja Rego (WASM), `persist=true` (awaryjny start z ostatniego dobrego bundle), cache werdyktów, weryfikacja podpisu bundle przed aktywacją |
| **API Gateway** | Autoryzacja (JWT + RBAC), rate limiting, walidacja wejścia, routing do PDP |
| **RuleStore** | Parametry + wersje reguł + niezmienny audyt (WORM, Merkle) |
| **Kontekst zewnętrzny** | KSeF, Biała Lista, CEIDG, NBP, GUS — cache z TTL i fallbackiem (degradacja zamiast błędu) |

---

## 3. Cykl życia reguły — „proste dodawanie, zmiana, usuwanie"

### 3.1. Manifest reguły (deklaratywne metadane — klucz do prostoty)

Każda reguła to kod + **manifest** (jedno źródło informacji dla całego systemu):

```yaml
rule_id: jdg.vat.a113.r1
title: Zwolnienie podmiotowe VAT — limit obrotu
legal_basis: Art. 113 ust. 1 ustawy o VAT (Dz.U. 2024 poz. 1557 ze zm.)
valid_from: 2026-01-01
valid_to: null                # null = obowiązuje nadal
severity: BLOCKER             # BLOCKER | WARNING | INFO
owner: zespół-vat
domain: vat
tests: [test_vat_a113_r1_*.rego]
thresholds: [vat.exemption_limit]   # parametry, których używa
impact_rules: [jdg.vat.substantive.*]  # reguły, które mogą kolidować
rollout_pct: 0                # domyślnie 0 (SHADOW) przy pierwszej rejestracji
```

**Konsekwencja:** system (a nie człowiek) wie, *co* sprawdzić przy każdej zmianie: testy, parametry, zależności, konflikty, wpływ na portfel decyzji. „Prostota" = człowiek wypełnia 8 pól, resztę robi maszyna.

### 3.2. DODANIE reguły — 7 kroków, w pełni zautomatyzowanych

```
1. SPECYFIKACJA   – wybór szablonu domeny (VAT/PIT/ZUS…), wypełnienie manifestu
2. GENERACJA      – system generuje szkielet reguły + metadane + placeholder testów
                    (rule_id sprawdzony globalnie: brak duplikatów = bramka)
3. IMPLEMENTACJA  – deweloper uzupełnia warunki (else-chain, bez hardcode: parametry
                    przez data.thresholds.*)
4. AUTO-TESTY     – system generuje testy: happy-path, granice, negatywne (no_match),
                    temporalne (valid_from/valid_to), golden (przeciw historycznym werdyktom)
5. BRAMKI CI      – lint → walidacja → tautologia → dead-rule → hardcoded → zero-defect
                    → mutation ≥ 70% → pokrycie 100% nowej reguły; konflikt wykrywany
                    automatycznie (cross-package conflict detector + impact matrix)
6. REVIEW 4-EYES  – przegląd ludzki tylko różnicy (diff) + manifest; checklista
                    automatyczna (podstawa prawna zweryfikowana vs ISAP, owner, testy)
7. WDROŻENIE      – rejestracja jako SHADOW → (A/B CANDIDATE) → ACTIVE z datą obowiązywania;
                    bundle nowy automatycznie, kanar 5% → 100%; przy błędzie auto-rollback
```

**Czasy docelowe:** kroki 1–6 ≤ 2 h pracy człowieka (głównie implementacja); krok 7 automatyczny (≤ 30 min od merge do 100% ruchu, w tym kanar 30 min).

### 3.3. ZMIANA reguły — nigdy nie edytuj „na żywo"

1. Nowa **wersja** reguły (semver: `rule_id@2.0.0`) — stara wersja pozostaje **niezmienna** w rejestrze (time-travel wymaga, by przeszłość była nienaruszona).
2. Rejestracja w SHADOW: nowa wersja ewaluowana równolegle na produkcji, werdykty porównywane (delta ≤ 2% — jeśli większa, alert i analiza).
3. Awans do CANDIDATE z `rollout_pct` (A/B): np. 5% transakcji nową wersją; monitoring jakości decyzji (decision_quality_monitor) i latencji.
4. Awans do ACTIVE przy zdrowych metrykach; **auto-rollback** do poprzedniej wersji przy: jakości < 95%, błędzie > 1%, anomalii latencji, naruszeniu invariantów (np. werdykt niemutowalny nadpisany).
5. Wersja ACTIVE ma `valid_from` — wejście w życie o właściwej dacie następuje automatycznie.

**Zasada:** „zmiana reguły" w systemie ENTERPRISE to *dodanie nowej wersji i awans*, nigdy *modyfikacja pliku na produkcji*. To eliminuje całą klasę błędów (nadpisanie, utrata kontekstu, nieodwracalność).

### 3.4. USUNIĘCIE reguły — bezpieczne wygaszenie

1. `deprecate` — reguła działa, ale generuje `_warnings: [DEPRECATED: zastąpiona przez jdg.vat.a113.r2]`.
2. Po okresie karencji (domyślnie 2 okresy rozliczeniowe) — `retire` (przestaje ewaluować; historia werdyktów nienaruszona).
3. `purge` — usunięcie z bundle wyłącznie po weryfikacji: zero werdyktów aktywnych odwołujących się do reguły, zero odwołań w innych regułach, testy zaktualizowane, manifest potwierdza brak referencji.
4. Cały cykl śledzony w rejestrze; raport „reguły do usunięcia" generowany automatycznie co tydzień.

### 3.5. Operacje awaryjne (kill-switch)

- **Pauza reguły:** `POST /rules/{id}/suspend` → natychmiast (hot-reload, < 1 s) przestaje wpływać na werdykty; log + alert.
- **Wyłączenie pakietu:** `suspend` całego pakietu (np. przy wykrytej regresji domenowej).
- **Wstrzymanie bundle:** przywrócenie ostatniego zdrowego bundle na wszystkich węzłach (auto lub ręcznie, z weryfikacją podpisu).
- Każda operacja awaryjna ma role (kto może) i jest nieodwracalnie zapisywana w audycie.

---

## 4. Pipeline adaptacji do zmian prawa (ISAP → produkcja)

Cel: **nowelizacja opublikowana w Dz.U. → reguły w produkcji ≤ 24 h (rutynowo) / ≤ 4 h (P0)**. W 100% automatycznie, z jednym punktem kontroli ludzkiej (review diffa).

### 4.1. Monitoring prawa (ciągły, nie codzienny)

- Crawler ISAP/legislacja.gov.pl 24/7 + subskrypcja feedów Dz.U. + webhooki RCL.
- **AI-Reader nowelizacji:** LLM analizuje nowelizację → ustrukturyzowany „diff prawny" (który akt, artykuł, co się zmienia: stawki/progi/definicje/terminy) z pewnością i cytatami. Wynik walidowany przez drugi model (4-eyes AI) + prawnika dla zmian złożonych.
- Kalendarz zmian prawa (P1621) — proaktywne alerty na N dni przed wejściem w życie.

### 4.2. Analiza wpływu (impact matrix)

- Automatycznie: diff prawny → dotknięte reguły (`_legal_basis` → reguły) → dotknięte pakiety → dotknięte decyzje (replay na próbce historycznych transakcji).
- Wynik: macierz (nowelizacja × reguła × priorytet: WYSOKI/ŚREDNI/NISKI), lista testów do aktualizacji, lista parametrów do zmiany, ryzyko.
- Zmiana parametrów (stawki/progi) idzie ścieżką **danych** (hot-reload, 15 min); zmiana logiki — ścieżką **reguł** (24 h).

### 4.3. Generowanie zmian

- Zmiany parametrów: formularz/import → walidacja zakresów → wersjonowany wpis w Data Service → hot-reload → werdykty od `valid_from` używają nowych wartości (time-travel).
- Zmiany logiki: AI proponuje reguły (na bazie diffa prawnego), człowiek zatwierdza; system generuje testy i uruchamia bramki (pkt 3.2).

### 4.4. Walidacja i symulacja przed produkcją

- **Golden replay:** pełna próbka historycznych transakcji (ostatnie 12 mies.) ewaluowana nową wersją; każda zmiana werdyktu musi mieć uzasadnienie w diffie prawnym (w przeciwnym razie blokada).
- **Symulator zmiany prawa** (P21 INN-08, law_change_simulator): „co by było, gdyby prawo weszło w życie wczoraj" — raport wpływu na portfel decyzji, kary, deklaracje.
- **Testy temporalne:** granica przed/po `valid_from` (dzień-1/dzień-0/dzień+1), w tym przejścia między nowelizacjami.

### 4.5. Wdrożenie automatyczne

- Budowa nowego bundle → podpis (HSM) → wdrożenie kanarkowe (5%) → shadow-porównanie → 100% → monitoring 24 h → status „ZMIANA WDROŻONA" w panelu.
- Wszystko z pełnym łańcuchem traceability: **akt prawny → issue → PR → bundle → węzeł → werdykt** (każdy werdykt niesie `bundle_version` + `rule_version` + `_legal_basis`).

---

## 5. Pipeline CI/CD — bramki, które fizycznie uniemożliwiają regresję

```
commit → PR
  1. LINT_REGO          (składnia, konwencje, else-chain)
  2. VALIDATE_RULES     (9 walidacji: rule_id unikalne globalnie, 25-polowy werdykt,
                          _legal_basis obecne i zweryfikowane vs ISAP, brak hardcode)
  3. TAUTOLOGY_GUARD    (zero reguł zawsze-prawdziwych bez CHECKPOINT-STUB)
  4. DEAD_RULE          (zero martwych reguł, zero duplikatów)
  5. HARDCODED_AUDIT    (zero wartości liczbowych w regułach — ADR-002 w 100%)
  6. ZERO_DEFECT        (certyfikacja ≥ 95/100 per reguła; BLOCKER przy < 90)
  7. TESTS              (natywne Rego: unit + property + fuzz 10k + mutation ≥ 70%
                          (cel 75%) + granice groszy/walut + negatywne)
  8. GOLDEN_REPLAY      (replay historyczny; nieuzasadnione zmiany werdyktów = FAIL)
  9. IMPACT             (impact matrix; zmiana > N% decyzji bez zgody = FAIL)
 10. BUNDLE_BUILD       (budowa, manifest 1.0 — spójność liczb wymuszona)
 11. SIGN               (podpis HSM; SBOM dołączony)
 12. DEPLOY_*           (canary → promote → monitor) — osobny workflow z zatwierdzeniem
```

Wszystkie bramki w CI **blokują merge** (block_on_fail). Pre-commit wykonuje bramki 1–6 lokalnie (w < 60 s), żeby deweloper nie czekał na CI.

**Kluczowa różnica vs stan obecny:** bramki są egzekwowane przez infrastrukturę (CI/CD + registry + orchestrator), a nie przez reguły audytujące (P22). Reguły audytujące pozostają jako **kontrola wtórna** (defense-in-depth), nie pierwotna.

---

## 6. Temporalność i wersjonowanie (time-travel klasy światowej)

1. **Reguły:** `rule_versions` (rule_id, wersja, valid_from, valid_to, content_hash, status, signer, signed_at). Pinning per ewaluacja: `active_version(rule_id, eval_date)`.
2. **Parametry:** `threshold_versions` (key, value, valid_from, valid_to, source_act, changed_by) — np. progi PIT, stawki VAT, płaca minimalna, limit KSeF.
3. **Overlays:** nakładki `v2026/v2027/…` na ten sam bazowy zestaw reguł (rozwinięcie wzorca ADR-011/policies) — mechanizm wyłącznie dla wariantów czasowych i jurysdykcyjnych, z automatyczną detekcją nakładania się (P1619 overlap detector) i luk (P1624 gap detector).
4. **Gwarancje:** brak luk w pokryciu czasowym (każda data ma dokładnie jedną wersję reguły); brak nakładania się (jeden kandydat na datę); re-ewaluacja historyczna zawsze deterministyczna (Merkle root połączony z wersją reguł).
5. **Rejestr zmian prawa:** kalendarz nowelizacji + przypięcia („ta decyzja ewaluowana wg prawa na 2025-03-15") — dowód dla KAS.

---

## 7. Dane (parametry) jako osobny strumień zmian

- **Data Service** (wersjonowany, z API): stawki, progi, limity, terminy, kursy, mapy (PKWiU→stawka, GTU, KŚT…).
- **Hot-reload:** zmiana danych = natychmiastowa (≤ 15 min cel, faktycznie < 1 min) bez budowy bundle.
- **Walidacja wejścia:** każda zmiana danych walidowana (zakres, typ, data obowiązywania, zgodność z aktem źródłowym, log zmiany).
- **Wersjonowanie:** time-travel dla danych jak dla reguł — historyczne werdykty używają historycznych parametrów.
- **Testy na danych:** golden dataset (stawki wzorcowe + graniczne) ewaluowany po każdej zmianie; regresja blokowana.

---

## 8. Strategia testowania — „niezniszczalna tarcza" (rozbudowa P23)

| Poziom | Zakres | Narzędzia | Cel |
|---|---|---|---|
| L0 Unit (rego) | per reguła: happy, granice, negatywne, temporalne | `opa test` | 100% nowych reguł, ≥ 95% pakietów |
| L1 Property | własności (np. „suma odliczeń ≤ dochód", „stawka ∈ {0, 5, 8, 23}") | property-based (hypothesis/crosshair) | inwarianty nigdy nie łamane |
| L2 Mutation | mutanci reguł | mutation analysis (bramka CI ≥ 70%, cel 75%) | testy faktycznie łapią błędy |
| L3 Fuzz | 10 000+ losowych wejść (w tym złośliwych) | fuzzer decyzyjny | zero crashy, zero nieokreśloności |
| L4 Golden replay | historyczne transakcje + werdykty | replay engine | żadna zmiana nie zmienia przeszłości bez uzasadnienia |
| L5 Contract | OpenAPI + schemat werdyktu | contract tests | klient zawsze dostaje 25 pól |
| L6 Integration | Data Service, RuleStore, API zewn. (mocki) | pytest + testcontainers | end-to-end poprawność |
| L7 E2E | input → PASS 0–8 → merge → werdykt → audyt | e2e suite | pełny łańcuch |
| L8 Chaos | awarie: bundle uszkodzony, opóźnienia, utrata danych | chaos engineering | recovery ≤ 500 ms, zero utraty werdyktów |
| L9 Security | podpisy, tampering, JWT, supply chain | security suite | odporność na manipulację |

**Reguły gry:** każda zmiana reguły/parametru musi przejść L0–L4 minimum; L5–L9 w CI na merge i cyklicznie (weekly). Pokrycie raportowane w dashboardzie i blokowane przy spadku.

---

## 9. Deployment, niezawodność i rollback

### 9.1. Dystrybucja bundle (wzorowana na OPA bundle API + OPAL)

- **Bundle server:** przechowuje podpisane bundle (immutable, `revision` = hash treści), obsługuje long-polling (ETag), delta-bundles dla dużych zmian, wersjonowanie z listą zdrowych wersji.
- **Węzły OPA:** `persist=true` (start z ostatniego dobrego bundle offline), weryfikacja podpisu kluczem publicznym **przed aktywacją**, raport statusu do centrali (status API).
- **Synchronizacja danych:** delta (tylko zmienione parametry) przez Data Service — bez pełnego bundle.

### 9.2. Wdrażanie zmian (progressive delivery)

| Etap | Zasięg | Czas | Wyjście |
|---|---|---|---|
| Canary | 5% ruchu | 30 min | metryki zdrowe? |
| Shadow compare | 100% ewaluacji, 0% wpływu (werdykty porównywane) | równolegle | delta ≤ 2% |
| Ramped | 25% → 50% → 100% | 1–2 h | bramki jakości per etap |
| Blue-green (opcjonalnie) | pełny switch na nowe środowisko, stare utrzymywane | < 1 min | natychmiastowy powrót (przełączenie) |
| Full + soak | 100% | 24 h | status „wdrożono" |
| Auto-rollback | przy anomali | ≤ 5 min | poprzednia zdrowa wersja |

### 9.3. Odporność

- HA data plane: ≥ 2 węzły na region, ≥ 2 regiony (RPO ≤ 5 min, RTO ≤ 15 min), health checks, circuit-breakery, retry z backoff, degradacja (fallback do ostatnich znanych wartości przy awarii zewnętrznych API — nigdy błąd 500).
- **Wersjonowanie werdyktów:** każdy werdykt trzyma `bundle_version`, `rule_version`, `threshold_version` — możliwość odtworzenia dokładnie w tej samej konfiguracji (determinizm + audyt).
- **Backup/DR:** RuleStore replikowany + snapshoty co 15 min; runbooki DR testowane co kwartał (game day).

---

## 10. Obserwowalność — mierzalność każdej zmiany

### 10.1. Metryki i SLO (cele opisane w §0)

- **Per werdykt:** latency, `shard_routed`, `_cost_ms`, `rule_version`, `bundle_version`, wynik jakości (confirmed/corrected).
- **Per reguła:** liczba dopasowań, współczynnik błędów, dryf względem ISAP, jakość decyzji (feedback loop z księgową).
- **Per zmiana:** czas PR→produkcja, wyniki bramek, delta werdyktów, liczba rollbacków, MTTR.
- **Pipeline:** czas ISAP→produkcja (SLA 24 h / 4 h), powodzenie bramek, pokrycie testów.

### 10.2. Alarmy i dashboardy

- **SLO dashboards:** latencja, dostępność, budżet błędu, jakość decyzji, dryf legislacyjny, stan wdrożeń (kanary), rollbacki.
- **Alarmy:** jakość < 95% (30 dni), delta shadow > 2%, dryf ISAP, liczba reguł < próg (ci_gate), anomalie latencji, nieudane podpisy, nieudane wdrożenia.
- **Traceability chain:** jeden identyfikator łączący nowelizację → issue → PR → bundle → węzeł → werdykt (OpenTelemetry + rejestr zmian).

### 10.3. Pętla jakości (feedback)

- Księgowa może oznaczyć werdykt jako błędny → trafia do Decision Quality Monitor → adaptive trust → alert/auto-cofnięcie przy przekroczeniu progu. To zamyka pętlę „prawo → reguła → decyzja → korekta → reguła".

### 10.4. Inteligencja systemu („bardzo inteligentny system") — warstwy AI/ML

Wymóg użytkownika: OPA musi być **inteligentnym systemem**. Inteligencja nie zastępuje determinizmu reguł (werdykt zawsze deterministyczny), lecz działa *wokół* nich — na metapozio­mie: przewidywanie, wykrywanie, uczenie i samodoskonalenie:

| Warstwa inteligencji | Mechanizm | Baza w JDG (do rozbudowy) |
|---|---|---|
| **Adaptive Trust Scoring** | Dynamiczny trust per reguła/pakiet wg potwierdzeń i korekt (feedback księgowej); tryby AUTO_POST/SUGGEST/ASK_USER reagują na zmiany jakości | `adaptive_trust_scoring_enterprise.rego` |
| **Knowledge Graph reguł (Neural Mesh)** | Graf zależności/konfliktów między domenami (VAT×PIT×ZUS×KKS), propagacja pewności, wykrywanie konfliktów zanim trafią do produkcji | P20 `neural_mesh_*`, `cross_package_conflict_detector` |
| **Predykcja wpływu nowelizacji** | Model szacuje wpływ nowelizacji na portfel decyzji („symulacja jutra") zanim reguły zostaną napisane — priorytetyzacja pracy i alerty ryzyka | `judgment_predictor.py`, `legal_change_impact_analyzer`, P22 INN-08 impact matrix |
| **Detekcja anomalii werdyktów (ML)** | Wykrywanie nietypowych rozkładów werdyktów (nagła zmiana stawki/odmów) — wczesny sygnał błędu reguły lub dryfu danych, z auto-rollbackiem | decision_quality_monitor, temporal_drift_detector |
| **Auto-tuning progów jakości** | Progi (jakość < 95%, delta ≤ 2%) adaptują się do sezonowości podatkowej (np. grudzień = więcej transakcji) — mniej fałszywych alarmów | adaptive thresholds (baza RULE_LIFECYCLE) |
| **Asystent LLM dla policy-engineerów** | Generowanie szkiców reguł/testów z diffu prawnego + 4-eyes (drugi model + człowiek); nigdy bezpośrednio do produkcji | `llm_bridge.py` (C2), AI-Reader (§4.1) |

**Zasada graniczna:** inteligencja może *rekomendować*, *ostrzegać*, *sugerować i cofać* (w granicach polityk), ale **decyzja ewaluacyjna zawsze pozostaje w deterministycznym Rego** — żaden model nie podejmuje decyzji podatkowej wprost. To gwarantuje przewidywalność i audytowalność przy zachowaniu adaptacyjności.

---

## 11. Bezpieczeństwo

| Obszar | Rozwiązanie |
|---|---|
| Supply chain | Podpis bundle (HSM/KMS), weryfikacja na węźle, SBOM, skanowanie zależności, izolacja sieciowa węzłów |
| Klucze | HSM, rotacja kwartalna, klucze offline dla DR, brak kluczy w repo |
| Dostęp | RBAC + SoD: „autor reguły ≠ recenzent ≠ operator wdrożenia"; 4-eyes dla BLOCKER; MFA dla operatorów |
| Audyt | WORM (append-only) dla werdyktów i zmian; Merkle tree + HMAC; retention 50 lat (pracownicze) / bezterminowo (audytowe) |
| API | JWT krótkotrwałe, rate limiting, walidacja wejścia (schema + semantic guard + firewall), PII minimalizacja |
| Prywatność | Werdykty bez danych osobowych w logach, szyfrowanie w spoczynku i transporcie, RODO/AML w zgodzie z prawem |

---

## 12. Organizacja, proces i ludzie

| Rola | Odpowiedzialność | Liczba (docelowa) |
|---|---|---|
| Policy Engineer (per domena) | implementacja reguł, manifesty, testy | 1–2 per domena (VAT, PIT, ZUS, KKS…) |
| Legal Engineer / prawnik podatkowy | walidacja diffów prawnych, legal_basis, interpretacje | 2–3 |
| Platform/DevOps | control plane, bundle, deployment, SLO | 2–3 |
| QA / Test Engineer | testy, golden datasets, chaos | 2 |
| Security Engineer | podpisy, klucze, audyt, supply chain | 1 |
| SRE | monitoring, runbooki, DR, incydenty | 1–2 |

**Proces zmian:** PR-based (GitOps), 4-eyes, template'y, checklisty automatyczne, SLA odpowiedzi na incydent: P0 ≤ 15 min, P1 ≤ 1 h. **Szkolenia:** symulacje zmiany prawa („game days") co kwartał; katalog wzorców reguł (recipes) — dodawanie reguły bez dokumentacji to zła praktyka.

### 12.1. Model ról operatorów (RBAC / SoD / 4-eyes)
| Rola operatora | Uprawnienia | Ograniczenia (SoD) |
|---|---|---|
| Autor reguły | pisze `.rego` + manifest + testy w PR | nie może recenzować ani wdrażać własnej zmiany |
| Recenzent (Legal/Policy) | review diffu prawnego i `_legal_basis` | nie może wdrażać |
| Operator wdrożenia | uruchamia canary→rollout→rollback | nie jest autorem ani recenzentem danej zmiany |
| Auditor | odczyt-only WORM, ścieżka dowodu | brak prawa zapisu |
- **BLOCKER** wymaga 4-eyes (autor + recenzent + operator + audyt wtórny); **MFA** obowiązkowe dla operatorów i auditorów.

### 12.2. DR/BCP — ciągłość działania i odzyskiwanie (RTO/RPO)
- **RTO ≤ 15 min** (odzyskanie usługi decyzyjnej), **RPO ≤ 5 min** (maks. utrata werdyktów/logów).
- **Backup:** codzienny snapshot `rules/` + `bundles/` + RuleStore (SQLite/DuckDB) + legal_graph LKG; retencja 50 lat (pracownicze) / bezterminowo (audytowe) na WORM.
- **Restore:** replikacja bundle na ≥2 strefach; klucze HSM offline dla DR (poza repo); procedura przywrócenia z `healthy_versions.json` (auto-rollback do ostatniej zdrowej wersji).
- **Runbooki:** P0 awaria węzła → failover ≤ 15 min; dryf legislacyjny krytyczny → hotfix parametru ≤ 15 min (wersjonowane dane progów, bez redeploy reguł).
- **Testy DR:** kwartalne „game days" (chaos: kill node, corrupt bundle, expired key, WORM tamper) — scenariusz auto-rollback ≤ 5 min musi przechodzić.

---

## 13. Porównanie: stan obecny (JDG) → cel (ENTERPRISE)

| Wymiar | Obecnie (wg dokumentacji) | Docelowo |
|---|---|---|
| Source of truth | `rules/` + `policies/` (dryf ryzyko) | jeden registry + overlays |
| Bramki jakości | reguły audytujące (P22) + CI | infrastruktura CI/CD egzekwująca, audyt wtórny |
| Podpis bundle | deklarowany (reguła) | faktyczny (HSM, weryfikacja na węźle) |
| Kanary/rollback | deklarowane (reguły) | orchestrator deploymentu (5%→100%, auto-rollback ≤ 5 min) |
| Zero hardcode | ~60% (265 wartości) | 100% |
| Deduplikacja/stuby | 3 duplikaty / 25 stubów (2026-08-22) | 0 (blokada w CI) |
| Testy natywne | częściowo (103+ pliki, plan do Q4 2026) | ≥ 95% pakietów, golden replay, mutation |
| Adaptacja prawa | crawl codzienny, cel 24 h | monitoring 24/7, AI-reader, 24 h rutynowo / 4 h P0, parametr 15 min |
| Obserwowalność | health + telemetria | pełne SLO/SLI, traceability chain, pętla jakości |
| DR/BCP | §12.2 (RTO/RPO, backup, runbooki, game days) | RTO 15 min, RPO 5 min, game days kwartalne |
| Operacje | §12.1 (model ról operatorów RBAC/SoD/4-eyes) | RBAC/SoD/4-eyes/MFA, runbooki |

---

## 14. Roadmap wdrożeniowa (z wykorzystaniem istniejącego fundamentu JDG)

| Faza | Zakres | Czas | Kryterium ukończenia |
|---|---|---|---|
| **F0. Higiena** | dokończenie ADR-002 (0 hardcode), deduplikacja (0 duplikatów), usunięcie stubów, jeden manifest z blokadą niespójności liczb | 4–6 tyg. | CI blokuje naruszenia; liczby spójne w 100% dokumentów |
| **F1. Testy natywne** | ≥ 95% pakietów z `test_native_*.rego`, golden datasets, mutation ≥ 70% (cel 75%) | 4–6 tyg. | `opa test` w CI dla wszystkich pakietów, raport pokrycia automatyczny |
| **F2. Control Plane (MVP)** | Policy Registry (API), bundle server z podpisem (HSM), wdrożenie kanarkowe + auto-rollback, manifest 2.0, traceability | 8–12 tyg. | zmiana parametru w 15 min; rollback w 5 min; podpis weryfikowany |
| **F3. Law-Change Pipeline** | monitoring 24/7, AI-reader nowelizacji, impact matrix automatyczna, golden replay | 8–12 tyg. | nowelizacja P0 wdrożona w 4 h (test pilotażowy) |
| **F4. Obserwowalność i SLO** | SLO dashboards, pętla jakości (feedback księgowej), alarmy, DR/BCP (game days) | 4–8 tyg. | 100% SLO mierzone i raportowane |
| **F5. Operacje i hardening** | RBAC/SoD, runbooki, chaos w CI, security suite, szkolenia | 4–8 tyg. | audyt bezpieczeństwa i chaos bez usterek |

Łącznie **~7–12 miesięcy** przy wykonaniu sekwencyjnym (min. ~32 tyg., max ~52 tyg.); równoległa realizacja niezależnych faz (F0‖F1 oraz F2‖F4) może skrócić czas do **~7–8 miesięcy**. **Uzasadnienie skali „za milion dolarów":** koszt wynika nie z technologii (OPA jest darmowe), lecz z (a) inżynierii niezawodności (control plane, DR, SLO), (b) pracy prawników/policy-engineerów przy jakości zero-defect dla 11 000+ reguł, (c) testów i golden datasets, (d) bezpieczeństwa klasy finansowej (HSM, WORM, audyt). Taki budżet to inwestycja w **pewność prawną i reputację** — dla systemu decyzyjnego, na którym ludzie rozliczają podatki, błąd kosztuje więcej niż system.

---

## 15. Jednozdaniowe podsumowanie

**Najdoskonalszy system OPA klasy ENTERPRISE to nie „więcej reguł", tylko „system, w którym zmiana reguły jest tak prosta, bezpieczna i szybka, że prawo nigdy nie wyprzedza oprogramowania"** — bo każda nowelizacja jest automatycznie wykrywana, analizowana, testowana, wdrażana kanarkowo i — w razie potrzeby — cofana w minuty, z pełnym dowodem dla organów skarbowych.

---

*Dokument bazuje na analizie dokumentacji JDG (ANALIZA_STANU_OPA_JAKO_SYSTEM.md) oraz dobrych praktykach Policy-as-Code (OPA bundles/signing, delta sync, progressive delivery, GitOps, SLO).*
