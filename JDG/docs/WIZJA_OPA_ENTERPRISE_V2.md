# 🏆 WIZJA V2 — SILNIK REGUŁ PODATKOWYCH OPA KLASY ENTERPRISE
## „Niezachwiana pewność prawa podatkowego i księgowego w regułach"

> **Dokument:** WIZJA_OPA_ENTERPRISE_V2.md
> **Charakter:** **ulepszenie wizji docelowej** — poziom drugi (V2) specyfikacji ENTERPRISE. Buduje na istniejących dokumentach:
> [ARCHITEKTURA.md](ARCHITEKTURA.md) (stan obecny) · [ANALIZA_STANU_OPA_JAKO_SYSTEM.md](ANALIZA_STANU_OPA_JAKO_SYSTEM.md) (analiza luk L1–L12) · [ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md](ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md) (cel V1) · RULE_LIFECYCLE.md · ADR 001–015
> **Wymóg nadrzędny (użytkownik):** *„Przedsiębiorca musi mieć niezachwianą pewność co do niezawodności prawa podatkowego i księgowego w regułach silnika reguł podatkowych OPA. Silnik musi się szybko i profesjonalnie adaptować do zmian. Dodawanie i usuwanie reguł musi być sprawne, niezawodne i proste. OPA musi być inteligentnym systemem — najdoskonalszym systemem klasy ENTERPRISE."*
> **Data:** 2026-08-07

---

## 0. Streszczenie kierownicze — co daje V2 ponad V1

Wizja V1 (ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md) zdefiniowała **dwie płaszczyzny**: Control Plane (tworzenie, weryfikacja, wdrożenie, wycofanie reguł) i Data Plane (ewaluacja). V1 to fundament: pipeline 11 kroków, kanary, rollback, temporalność, zero-hardcode, testy L0–L9.

**Wizja V2 odpowiada na pytanie, którego V1 nie domyka: skąd „niezachwiana pewność"?** Pewność nie może być deklaracją ani audytem reguł audytujących — musi być **matematycznie, kryptograficznie i operacyjnie egzekwowana w każdym werdykcie**. V2 dodaje sześć nowych filarów:

| # | Filar V2 | Jeden akapit | Nowość względem V1 |
|---|---|---|---|
| **F1** | **Legal Twin — Cyfrowy Bliźniak Prawa** | Pełny, ustrukturyzowany model prawa (akty → artykuły → ustępy → pkt → daty obowiązywania → interpretacje → orzecznictwo) jako **Legal Knowledge Graph (LKG)**. Każda reguła i każdy parametr są dwukierunkowo powiązane z węzłami prawa. Pokrycie prawa jest **mierzone**, a nie szacowane. | LKG jako nowa warstwa domenowa; dwukierunkowa traceability; „pustynia pokrycia" = alarm; możliwość *dowodu*, że cytowany przepis istniał w dniu transakcji |
| **F2** | **Warstwa Konstytucyjna — runtime invariants** | Zbiór ~20–40 twardych niezmienników (np. „suma odliczeń ≤ dochód", „stawka ∈ {0,5,8,23}", „ZUS nigdy nie nadpisany", „kwoty ≥ 0") weryfikowanych **na każdym werdykcie w runtime**, a nie tylko w CI. Naruszenie = BLOCK + alarm + auto-revert. | Z egzekucji build-time przechodzi na **egzekucję runtime**; niezmienniki jako „konstytucja" systemu decyzyjnego |
| **F3** | **Formal Verification + Golden Oracle** | (a) **Weryfikacja formalna** (SMT/Z3) krytycznych podzbiorów reguł — dowód, że niezmienniki nigdy nie zostaną złamane; (b) **Golden Verdicts Repository** — „złote werdykty" z ostatnich 12+ mies. jako **oracle przeszłości**: każda zmiana reguły musi wyjaśnić każdą zmianę werdyktu w diffie prawnym, inaczej merge zablokowany; (c) **ewaluacja różnicowa** — krytyczne domeny liczone na ≥ 2 węzłach, hash werdyktów musi się zgadzać. | Dowody formalne + oracle historyczny + konsensus międzywęzłowy — pewność **dowodliwa**, nie deklarowana |
| **F4** | **Decision Certificate — dowód decyzyjny dla przedsiębiorcy** | Każdy werdykt generuje **certyfikat decyzyjny**: wersja ludzka (PDF po polsku: podstawa prawna, daty, progi, wersje reguł, wyjaśnienie) + **pieczęć kryptograficzna** (SHA-256 → Merkle → podpis HSM) weryfikowalna offline. Werdykt ma klasę pewności: `CERTAIN` / `CONDITIONAL` / `NEEDS_ADVICE`. | Warstwa **pewności dla człowieka** — przedsiębiorca i księgowa widzą *dowód*, nie tylko wynik |
| **F5** | **Law Radar — proaktywna adaptacja** | Monitoring **projektów ustaw** (RCL, Sejm, Senat, uzasadnienia, założenia) — nie tylko opublikowanych nowelizacji. Reguły przygotowuje się **przed** wejściem prawa w życie (lead time), a nie w 24 h po publikacji. | Zmiana paradygmatu: z **reakcji** (publikacja → 24 h) na **proakcję** (projekt → przygotowanie z wyprzedzeniem) |
| **F6** | **Declarative Change — zmiana w języku prostym** | Operator/prawnik zgłasza zmianę w **formularzu deklaratywnym** (np. „stawka VAT na produkt X od 2027-01-01: 23% → 8%"), system sam: mapuje na reguły/parametry, generuje diff, testy, impact, PR, 4-eyes, wdrożenie kanarkowe. | „Prostota" osiągnięta do końca: **człowiek opisuje zmianę, maszyna ją wykonuje** |

**Zasada przewodnia V2:** *„Pewność to nie brak błędów — to zdolność systemu do udowodnienia poprawności każdej decyzji, wykrycia każdego odchylenia w milisekundy i cofnięcia go w minuty, z pełnym, kryptograficznie poświadczonym śladem dla przedsiębiorcy, księgowej i organów skarbowych."*

---

## 1. Fundament analityczny — skąd wiemy, co ulepszyć

Wizja V2 powstała z trzech źródeł:

### 1.1. Analiza dokumentacji JDG (ARCHITEKTURA.md + ANALIZA_STANU_OPA_JAKO_SYSTEM.md)

**Stan obecny (potwierdzony):** orkiestrator `main_jdg.rego` z Multi-Pass (PASS 0–8) i Sharded Routerem (ADR-009, routing O(1), 4 ścieżki); werdykt 25-polowy (ADR-004); `safe_merge` z allowlistą niemutowalną (ZUS/business); temporalność z time-travel (ADR-003); zero-hardcode częściowo (ADR-002, ~265 wartości do migracji); cykl życia reguły SHADOW→CANDIDATE→ACTIVE→ROLLED_BACK (rule_lifecycle_manager.py, hot-reload przez `data.jdg.rule_registry` — bez restartu); pipeline jakości 8 bramek (P22); 15 workflow CI; 9 tabel RuleStore (w tym `jdg_legal_cartography` — **zalążek F1**).

**Główne luki (za ANALIZA_STANU):**
- **L1:** brak realnego control plane (podpis, delta, kanary jako infrastruktura — dziś głównie reguły audytujące);
- **L2:** niespójne metryki między dokumentami (439 vs 383 vs 176 plików; 11 452 vs 10 878 rule_id) — brak autorytatywnego rejestru;
- **L3:** 369 duplikatów / 512 stubów — brak automatycznej blokady;
- **L4:** zero-hardcode tylko ~60%;
- **L6/L8/L9:** brak DR/BCP, modelu ról operatorów, łańcucha traceability;
- **Nowa obserwacja V2:** brakuje warstwy, która czyni pewność **mierzalną i dowodliwą w runtime** (niezmienniki, oracle, certyfikaty) oraz warstwy **proaktywnej** (Law Radar).

> **Konwencja ADR (zgodnie z kulturą projektu — ADR 001–015):** każdy filar V2 zostaje udokumentowany jako osobna decyzja projektowa — proponowane numery: **ADR-016** Legal Twin / LKG, **ADR-017** Warstwa Konstytucyjna (runtime invariants), **ADR-018** Golden Oracle + ewaluacja różnicowa, **ADR-019** Decision Certificate, **ADR-020** Law Radar (proaktywna adaptacja), **ADR-021** Declarative Change. Wdrożenie każdego filaru wymaga wpisu do ARCHITECTURE.md.

### 1.2. Audyt realnej infrastruktury w repo (nie tylko dokumentacji)

| Artefakt | Stan faktyczny | Kierunek V2 |
|---|---|---|
| `JDG/bundles/bundle.sh` v8.0 | Buduje `.tar.gz` z zachowaniem struktury katalogów (fix R1), licznik plików, manifest; deployment przez `curl PUT /v1/bundles/jdg` | Wznieść na **Bundle Server**: podpis HSM (`opa sign`), weryfikacja kluczem na węźle, delta-bundles, long-polling, wersje + lista „zdrowych" |
| `rule_lifecycle_manager.py` | register/promote/rollback/migrate/check; registry JSON → `data.jdg.rule_registry` (hot-reload, zero restartu); `check` wykrywa nakładające się okna ważności | Wznieść na **Policy Registry API** + pełna integracja z deploymentem; `check` rozszerzyć o **dowód ciągłości czasowej** (algebra interwałów: zero luk, zero nakładek) |
| `isap_rule_update_pipeline.py` | ingest → impact → plan → emit (changelog + registry) | Połączyć z **Law Radar** (projekty ustaw) i **Legal Twin** (mapowanie diffu prawnego na węzły LKG) |
| `decision_quality_monitor.py` | KPI, feedback, adaptive thresholds | Pętla jakości + **Decision Certificate** + anomaly detection |
| Migracje 001/002 (DuckDB) | `jdg_tax_thresholds`, `rule_versions`, `jdg_verdict_audit` | Rozbudować **istniejącą** `jdg_legal_cartography` do `legal_graph` (LKG) + dodać: `invariants`, `golden_verdicts`, `decision_certificates`, `draft_law_radar` (migracje 003+) |
| `main_jdg.rego` | Multi-Pass + safe_merge + provenance (Merkle root) | Dodać **runtime invariant check** (F2) na końcu POST-MERGE oraz pole `certainty_class` (F4) |

### 1.3. Dobre praktyki branżowe (research 2026)

OPA jako enterprise: **bundle signing** (`opa sign`, weryfikacja kluczem/JWKS; uwaga: delta bundles nie wspierają podpisu → dla domen krytycznych bundle snapshot), **bundle persistence** (`persist=true` — start offline z ostatniego dobrego bundle), **discovery mode** (bootstrap konfiguracji z centrali), **status mode** (raportowanie stanu węzłów do control plane), **Data API** (`PUT /v1/data` — hot-reload parametrów bez rebuildu), **OPAL** (push-based synchronizacja danych/reguł w czasie rzeczywistym), **Regal** (linter Rego w CI), `opa test --coverage` + `--fail-on-empty`, **shadow/canary policy delivery**, `opa build -t wasm` dla ultra-niskiej latencji. V2 implementuje te mechanizmy jako infrastrukturę — a nie jako reguły, które je tylko audytują.

---

## 2. F1 — Legal Twin: Cyfrowy Bliźniak Prawa (Legal Knowledge Graph)

### 2.1. Koncepcja

Rozbudować **istniejącą** tabelę `jdg_legal_cartography` do pełnego **Legal Knowledge Graph (LKG)** (nazwa robocza tabeli docelowej: `legal_graph` — ewolucja, nie nowy byt) — ustrukturyzowanego modelu prawa polskiego (podatkowego, księgowego, ZUS, KKS, PCC, UoR…):

```
AKT (ustawa, Dz.U. poz. X)
 └─ ARTYKUŁ (Art. 113 ustawy o VAT)
     └─ USTĘP (ust. 1) ──→ PARAGRAF TAKSONOMII (limit obrotu)
         ├─ DANE: wartości liczbowe (limit w zł) — link do jdg_tax_thresholds
         ├─ REGUŁY: [jdg.vat.a113.r1, jdg.vat.substantive.*] — reguły implementujące
         ├─ INTERPRETACJE: interpretacje indywidualne KIS (powiązane orzeczenia)
         └─ HISTORIA: valid_from/valid_to wersji przepisu (nowelizacje)
```

**Węzły prawa** mają `legal_node_id`, tekst, daty obowiązywania (po nowelizacjach — **wersjonowane**, jak reguły), źródło (ISAP/Dz.U.), status (obowiązujący/uchylony/zmieniony).

### 2.2. Gwarancje dwukierunkowej spójności

1. **Reguła → prawo:** każda reguła musi mieć `_legal_basis` wskazujące na istniejące węzły LKG (bramka CI — rozszerzenie `validate_legal_basis.py`). „Podstawa prawna" przestaje być stringiem, staje się **referencją**.
2. **Prawo → reguły:** każdy węzeł materialny (z wartością liczbową, terminem, stawką) musi mieć ≥ 1 regułę implementującą (reverse coverage). Węzeł bez reguły = **alarm pokrycia** („prawo istnieje, system go nie zna").
3. **Diff prawny → LKG:** AI-Reader nowelizacji (V1 §4.1) aktualizuje LKG wprost: „Art. 113 ust. 1: limit 2 000 000 zł → 2 400 000 zł od 2027-01-01" tworzy nową wersję węzła + listę reguł dotkniętych.
4. **Werdykt → prawo:** każdy werdykt niesie `_legal_basis_refs` = [legal_node_id…] + wersje węzłów. **Dowód istnienia:** w każdej chwili można pokazać tekst przepisu w wersji z dnia transakcji (time-travel LKG).

### 2.3. Mierzalne wskaźniki pewności prawnej (nowe metryki)

| Metryka | Definicja | Cel V2 |
|---|---|---|
| **LCI — Legal Coverage Index** | % węzłów materialnych prawa objętych regułami | ≥ 99% domen w zakresie (VAT, PIT, ZUS, KKS…) |
| **TCL — Temporal Continuity of Law** | % węzłów LKG z dowiedzioną ciągłością (zero luk między wersjami) | 100% |
| **RV — Rule–Law Verification** | % reguł, których `_legal_basis` wskazuje zweryfikowane węzły LKG | 100% |
| **UVR — Unexplained Verdict Rate** | % zmian werdyktów bez uzasadnienia w diffie prawnym | 0 |

---

## 3. F2 — Warstwa Konstytucyjna: runtime invariants

### 3.1. Koncepcja

Obok reguł biznesowych (zmiennych — prawo się zmienia) definiujemy **niezmienniki systemowe** (stałe — nigdy się nie zmieniają). Pełnią rolę „konstytucji" systemu decyzyjnego: chronią przed skutkami błędów reguł, danych i integracji, niezależnie od treści prawa.

Przykładowe niezmienniki (katalog startowy, ~30; rozszerzalny przez manifest):

```
INV-001  stawka VAT ∈ {0, 0.05, 0.08, 0.23, ZW, NP, OO}   (zbiór z prawa + LKG)
INV-002  kwota netto ≥ 0, podatek ≥ 0, brutto = netto × (1+stawka) ± epsilon groszowy
INV-003  suma odliczeń ≤ podstawa opodatkowania (dla danego przedmiotu)
INV-004  werdykt domeny niemutowalnej (ZUS, business, fortress) NIGDY nie nadpisany
INV-005  BLOCK_AND_ALERT w PASS 0 → werdykt nie zawiera AUTO_POST
INV-006  każda kwota ma walutę i jest dodatnia lub równa 0
INV-007  rule_id w werdykcie istnieje w rejestrze i jest wersją ACTIVE dla daty ewaluacji
INV-008  _legal_basis_refs niepuste dla werdyktów matched=true (reguła bez podstawy = błąd)
INV-009  determinizm: ten sam input + te same wersje = ten sam hash werdyktu (ewaluacja różnicowa)
INV-010  jeżeli werdykt ma vat_rate, to istnieje węzeł LKG ze stawką dla tej daty
```

### 3.2. Trzy poziomy egzekucji

| Poziom | Gdzie | Działanie przy naruszeniu |
|---|---|---|
| **Build-time** | CI (reguły invariantów + SMT) | Blokada merge |
| **Runtime (każdy werdykt)** | koniec POST-MERGE w `main_jdg.rego` + serwer | `invariant_failed: true` → werdykt oznaczony `CERTAINTY_BLOCKED`, alarm, log; decyzja nie trafia do AUTO_POST |
| **Runtime (statystyczny)** | decision_quality_monitor | naruszenie > 0.01% → auto-rollback ostatniego bundle |

### 3.3. Weryfikacja formalna (F3a)

- **SMT/Z3:** wybrane podzbiory reguł (krytyczne: ZUS, PIT-rozliczenia, KKS) tłumaczone na **model formalny (abstrakcja)** — dane wejściowe + relacje arytmetyczne; Z3 dowodzi, że niezmienniki INV-xxx są **zawsze** spełnione (nie tylko na próbce testowej). **Zakres (uczciwość specyfikacji):** pełne Rego nie jest bezpośrednio weryfikowalne w SMT — dowód dotyczy *abstrakcyjnych modeli* wyprowadzanych z reguł i objęty jest audytem zgodności model↔reguła (każda zmiana reguły → regeneracja modelu → ponowny dowód).
- **Property-based (hypothesis/crosshair — już istnieje):** losowa eksploracja przestrzeni wejść; pozostać jako warstwa empiryczna pod formalną.
- **Mutatnion testing** (istnieje, bramka ≥ 70%): podnieść do **≥ 85% dla pakietów krytycznych** i powiązać z INV (mutant łamiący INV musi zostać zabity).

---

## 4. F3 — Golden Oracle i ewaluacja różnicowa

### 4.1. Golden Verdicts Repository („oracle przeszłości")

Tabela `golden_verdicts`: (input_hash, werdykt, bundle_version, rule_versions, threshold_versions, data transakcji, powód zmiany). Zasada:

> **ŻADNA zmiana (reguły, parametru, bundle) nie może zmienić historycznego werdyktu bez uzasadnienia w diffie prawnym. Nieuzasadniona zmiana = blokada wdrożenia.**

- Golden dataset: reprezentatywna próbka ostatnich 12+ mies. transakcji (wszystkie domeny, granice groszy, przypadki no_match).
- Bramka CI `GOLDEN_REPLAY` (istnieje w V1): rozszerzona o **auto-generowanie wyjaśnienia** — każdy werdykt różniący się od złotego musi mieć mapowanie na węzeł LKG zmieniony przez nowelizację. Bez mapowania — FAIL.
- Wdrożenie zmiany, która celowo zmienia interpretację (np. korzystna interpretacja KIS), wymaga **ręcznej adnotacji „intentional change"** z podpisem 4-eyes — trafia do audytu.

### 4.2. Ewaluacja różnicowa (cross-node consensus)

- Dla domen krytycznych (ZUS, PIT, KKS) ten sam input ewaluowany na **≥ 2 węzłach OPA** z tym samym bundle; hash werdyktu (`decision_hash`, już istnieje) musi się zgadzać. Rozbieżność = alarm `DIVERGENCE` + wyłączenie węzła z ruchu (healthy endpoint).
- Dla przejść nowelizacyjnych: ewaluacja równoległa starej i nowej wersji reguły w trybie **shadow** (werdykt bez wpływu) z porównaniem różnic — identyczne mechanizmy jak canary, ale z automatycznym raportem do człowieka.

---

## 5. F4 — Decision Certificate: dowód decyzyjny dla przedsiębiorcy

### 5.1. Każdy werdykt = certyfikat

```
┌────────────────────────────────────────────────────────────────┐
│  CERTYFIKAT DECYZYJNY — NEXUSAI JDG                            │
│  Nr: DC-2026-08-07-00001234    Data transakcji: 2026-08-05     │
│  Klasyfikacja: ✅ CERTAIN (pełna pewność)                       │
│                                                                │
│  DECYZJA: Faktura sprzedaży VAT 23% → księgowanie PKPiR        │
│  Podstawa prawna: Art. 41 ust. 1 ustawy o VAT (Dz.U. 2024      │
│    poz. 1557 ze zm.), wersja z dnia transakcji [link LKG]      │
│  Stawka: 23% (parametr vat.standard_rate wg 2026-08-05)        │
│  Reguły: jdg.vat.substantive.r12 v3.1 (ACTIVE) · ...           │
│  Bundle: jdg-bundle-v8.0.12 (SHA-256: a1b2…)                   │
│  Niezmienniki: 12/12 spełnione (runtime check)                 │
│  Pieczęć: SHA-256 → Merkle root R7x… → podpis HSM (ECDSA)      │
│  Weryfikacja: https://verify.nexusai.pl/cert/DC-2026-08-07-…   │
└────────────────────────────────────────────────────────────────┘
```

### 5.2. Klasy pewności werdyktu

| Klasa | Warunki | Działanie systemu |
|---|---|---|
| `CERTAIN` | reguła ACTIVE, `_legal_basis` → węzły LKG zweryfikowane, temporalność OK, zero konfliktów, invariants OK | AUTO_POST możliwy |
| `CONDITIONAL` | reguła OK, ale interpretacja wymaga potwierdzenia (np. WIS, interpretacja KIS, niejednoznaczny przepis — wykryte przez LKG/graf konfliktów) | SUGGEST + adnotacja „wymaga interpretacji"; lista pytań generowana automatycznie |
| `NEEDS_ADVICE` | brak reguły, luka pokrycia (LCI dla tej transakcji), konflikt nierozstrzygnięty, invariant naruszony | ASK_USER / doradca; nigdy AUTO_POST |

### 5.3. Dla kogo

- **Przedsiębiorca:** PDF po polsku — co, dlaczego, na jakiej podstawie; weryfikowalny link; podstawy do rozmowy z księgową/doradcą.
- **Księgowa:** pełna proweniencja (V1: `_provenance_tree`) + klasa pewności + ewentualne pytania.
- **Organy (KAS):** eksport certyfikatu (PDF + XML podpisany) — „dlaczego system uznał transakcję za rozliczoną w ten sposób"; Merkle root łączy z niezmiennym audytem (ADR-006).

---

## 6. F5 — Law Radar: proaktywna adaptacja do zmian prawa

### 6.1. Zmiana paradygmatu

| | V1 (reakcja) | V2 (proakcja) |
|---|---|---|
| Źródło | opublikowane nowelizacje (Dz.U.) | **+ projekty ustaw** (RCL, Sejm, Senat, uzasadnienia, założenia do projektów) |
| Moment pracy | po publikacji → 24 h / 4 h (P0) | **przed wejściem w życie** — reguły gotowe w dniu wejścia, lead time tygodnie-miesiące |
| Ryzyko | okno braku zgodności między publikacją a wdrożeniem | okno zminimalizowane; **kalendarz zmian** z countdownem |

### 6.2. Mechanizmy

1. **Crawler projektów** (rozszerzenie `isap_crawler.py`): RCL (rcl.gov.pl), sejm.gov.pl (druk/sejm), senat.gov.pl, orzeczenia NSA, interpretacje KIS — z deduplikacją i klasyfikacją („zmiana stawki/progu/definicji/terminu").
2. **AI-Reader** (LLM + 4-eyes AI + prawnik dla złożonych): projekt ustawy → **przewidywany diff prawny** → kandydackie zmiany w LKG (status `DRAFT_LAW`) → impact matrix na regułach.
3. **Preparacja reguł w trybie SHADOW:** reguły pod przyszłą nowelizację tworzone i testowane **zanim ustawa wejdzie w życie**, z `valid_from` = data wejścia; w dniu wejścia następuje jedynie awans (promote) — automatyczny, zero wysiłku o północy.
4. **Pewność przewidywania:** ryzyko, że projekt nie wejdzie w życie / zmieni treść — mierzone i raportowane (`confidence_draft`); reguły przygotowane na bazie projektu nigdy nie wpływają na werdykty przed wejściem (SHADOW).
5. **KPI adaptacji V2:** `lead_time_avg` = średni czas między pierwszą detekcją projektu a gotową regułą; cel **≥ 30 dni przed wejściem w życie** dla zmian rutynowych; dla zmian po publikacji — SLO V1 (24 h / 4 h) pozostaje jako **fallback**.

---

## 7. F6 — Declarative Change: zmiana w języku prostym

### 7.1. Jeden interfejs dla wszystkich typów zmian

System wystawia **deklaratywny interfejs zmiany** — dla danych i dla reguł:

```
ZMIANA: Stawka VAT
  Produkt/usługa: [wybór z katalogu PKWiU]
  Stawka: 23% → 8%
  Od dnia: 2027-01-01
  Źródło prawa: [link do projektu/ustawy]
  Priorytet: RUTYNOWY | PILNY (P0)

→ System wykonuje automatycznie:
  1. Mapowanie na parametr (vat.rate.PKWiU.X) → nowa wersja w Data Service (hot-reload)
  2. Golden replay na 12 mies. → raport zmienionych werdyktów z uzasadnieniem
  3. Testy graniczne (dzień-1/0/+1), invariants, impact matrix
  4. Generacja PR + checklista 4-eyes (owner, prawnik)
  5. Wdrożenie: bundle (jeśli dotknięta logika) lub data-only (15 min)
  6. Monitoring 24 h + Decision Certificate dla nowych werdyktów
```

### 7.2. Szablony domenowe — „reguła w 8 polach"

Kontynuacja manifestu V1 (§3.1) — **szablony per domena** (VAT, PIT, ZUS, KKS, PCC…): wybór szablonu, uzupełnienie 8 pól, resztę generuje maszyna (szkielet Rego, testy happy/negatywne/temporalne, rule_id bez duplikatów, lista konfliktów). Przy każdej nowelizacji AI proponuje **gotowe wypełnienie szablonu** z diffu prawnego — człowiek tylko zatwierdza (4-eyes).

### 7.3. Czego NIGDY nie robi automatyzacja

- Nie awansuje reguły do ACTIVE bez zdrowych metryk (kanar 5% → 100%).
- Nie zmienia reguły domeny niemutowalnej (ZUS/business) bez podpisu dwóch osób.
- Nie usuwa reguły z bundle bez dowodu „zero aktywnych referencji".
- Nie decyduje o interpretacji przepisu niejednoznacznego — to rola człowieka (doradca/interpretacja KIS).

---

## 8. Control Plane jako infrastruktura (realizacja L1 w V2)

V1 opisała control plane; V2 **konkretyzuje go w mechanizmach OPA** (z research: signing, persistence, discovery, status, delta, Data API):

| Komponent V2 | Mechanizm | Uwagi |
|---|---|---|
| **Bundle Server** | repozytorium podpisanych bundle (snapshot) + delta; long-polling (ETag); lista „zdrowych wersji"; rewizja = hash treści | `opa sign` (HSM); delta-bundle bez podpisu → tylko dla danych, nigdy dla reguł krytycznych |
| **Weryfikacja na węźle** | klucz publiczny (JWKS) w konfiguracji OPA; `bundles[_].signing`; odrzucenie bundle bez podpisu | twarda bramka startu |
| **Persist** | `persist=true` — start offline z ostatniego dobrego bundle | gwarancja dostępności przy awarii sieci |
| **Discovery** | bootstrap konfiguracji (services, bundles, status) z centrali | zmiana konfiguracji bez re-deployu |
| **Status** | status mode — węzły raportują: aktywny bundle, wersje, błędy, health | fundament „świeżości reguł" (wszystkie węzły na tej samej rewizji) |
| **Data hot-reload** | `PUT /v1/data/...` / OPAL push dla parametrów | 15 min → faktycznie < 1 min |
| **Progressive delivery** | canary 5% → shadow-compare → ramped 25/50/100 → soak 24 h → auto-rollback ≤ 5 min | orchestrator rolloutów (nie reguła!) |
| **Policy Registry API** | `/v1/rules` — katalog, wersje, metadane, owner, status; searchable; podpięty do rule_registry.json | rozbudowa `rule_lifecycle_manager.py` do usługi |

**Manifest 2.0 (rozwiązanie L2):** jeden autorytatywny manifest (reguły, rule_id, testy, parametry, węzły LKG, metryki), regenerowany w CI; każda rozbieżność między dokumentami/artefaktami = **blokada CI** (nie alert). To usuwa klasę problemów „439 vs 383 vs 176".

---

## 9. Data Plane, HA i gwarancje runtime

| Obszar | V2 |
|---|---|
| Topologia | ≥ 2 węzły/region, ≥ 2 regiony; klastry per domena (VAT/PIT/ZUS/KKS) opcjonalnie z osobnymi bundle'ami i SLO |
| Latencja | WASM eval dla gorącej ścieżki (cel p95 < 5 ms krajowa, < 50 ms pełny łańcuch); **uwaga**: nie wszystkie wbudowane funkcje Rego kompilują się do WASM (np. `http.send`, niestandardowe built-ins) — pakiety z takimi konstrukcjami pozostają na silniku Go; cache werdyktów (input_hash → werdykt) |
| Dostępność | 99,95%; RPO ≤ 5 min, RTO ≤ 15 min; snapshoty RuleStore co 15 min; DR game days kwartalnie |
| Deterministyczność | `decision_hash` + ewaluacja różnicowa (§4.2) — dwa węzły muszą dać ten sam hash |
| Degradacja zamiast błędu | awaria KSeF/Biała Lista/NBP → fallback do ostatnich znanych danych z TTL + znacznik `_degraded_context` (nigdy 500) |
| Runtime invariants | §3.2 — na każdym werdykcie |
| Wersjonowanie werdyktu | `bundle_version` + `rule_versions` + `threshold_versions` + `legal_node_versions` — pełne odtworzenie konfiguracji decyzji |

---

## 10. Inteligencja V2 — „bardzo inteligentny system" wokół deterministycznego rdzenia

Zasada graniczna V1 pozostaje: **decyzja ewaluacyjna zawsze w deterministycznym Rego; inteligencja rekomenduje, ostrzega, mierzy, uczy i cofa.** V2 dodaje:

| Warstwa | V1 (baza) | V2 (ulepszenie) |
|---|---|---|
| **Legal Twin/LLM** | AI-Reader nowelizacji (4-eyes AI) | + crawler projektów (Law Radar), aktualizacja LKG wprost, generowanie kandydackich reguł z diffu |
| **Adaptive Trust** | per reguła/pakiet, AUTO_POST/SUGGEST/ASK_USER | + korelacja z klasami pewności (F4); **dwa odrębne pojęcia trustu**: (a) Trust Score ekstrakcji agentów (≥ 0.92 dla AUTO_POST — istnieje), (b) adaptive trust per reguła/pakiet z pętli feedbacku — klasa `CERTAIN` wymaga zdrowych metryk obu; `CONDITIONAL` nigdy AUTO_POST |
| **Knowledge Graph** | Neural Mesh P20 (propagacja pewności) | + węzły prawne LKG w grafie — konflikt reguła×prawo×interpretacja wykrywany wcześnie |
| **Predykcja** | judgment_predictor, impact analyzer | + predykcja wpływu **projektu** ustawy (przed wejściem), confidence_draft, priorytetyzacja |
| **Anomalie** | decision_quality_monitor, drift | + wykrywanie zmian rozkładów werdyktów per domena/region (wczesny sygnał błędu), auto-rollback |
| **Auto-tuning progów** | adaptive thresholds | + sezonowość podatkowa i kalendarz zmian prawa jako wejścia |
| **Self-healing** | max 5 korekt/cykl, reguły | + korekty **danych** (parametry) w pełni automatyczne; korekty **logiki** — zawsze 4-eyes |
| **Asystent** | LLM draft + 4-eyes | + „declarative change" (F6) jako główny interfejs pracy z systemem |

**Pętla jakości (closed loop):** księgowa oznacza werdykt → Decision Quality Monitor → adaptive trust → klasy pewności → (jeśli trzeba) auto-rollback → (jeśli trwałe) rekomendacja korekty reguły → 4-eyes → nowa wersja → golden replay. Każde domknięcie pętli jest mierzone i raportowane.

---

## 11. Obserwowalność, SLO i Indeksy Pewności

### 11.1. SLO V2 (aktualizacja tabeli z V1)

| Metryka | Cel V1 | Cel V2 |
|---|---|---|
| Publikacja nowelizacji → produkcja | ≤ 24 h rutynowo / ≤ 4 h P0 | ≤ 24 h / 4 h (fallback) **+ reguły gotowe przed wejściem w życie (lead ≥ 30 dni dla zmian z projektów)** |
| Zmiana parametru | ≤ 15 min | **< 1 min** (Data API hot-reload) |
| Nowa reguła PR→produkcja | ≤ 2 h maszyna / 1 dzień kal. | bez zmian |
| MTTR / auto-rollback | ≤ 15 min / ≤ 5 min | bez zmian |
| Dostępność | 99,95% | bez zmian (RPO 5 min, RTO 15 min) |
| Latencja p95 | < 5 ms / < 50 ms | bez zmian |
| Regresje do produkcji | 0 | 0 + **0 naruszeń runtime invariants** + **0 nieuzasadnionych zmian werdyktów (golden)** |
| Pokrycie testami pakietów krytycznych | 100% | + **dowód formalny (SMT) dla pakietów krytycznych** |
| Duplikaty / stuby | 0 | 0 (blokada CI) |
| **LCI (pokrycie prawa)** | — | **≥ 99%** |
| **TCL (ciągłość czasowa prawa)** | — | **100%** |
| **UVR (nieuzasadnione zmiany)** | — | **0** |

### 11.2. Dashboard „Pewność" (jeden widok dla zarządu i SRE)

- **Indeks Pewności Prawnej (LCI×TCL×RV)** — syntetyczna liczba 0–100 z trendem.
- **Indeks Pewności Decyzyjnej** — % werdyktów CERTAIN / CONDITIONAL / NEEDS_ADVICE; alarm, gdy CONDITIONAL+NEEDS_ADVICE > próg.
- **Świeżość floty** — % węzłów na aktualnej rewizji bundle (ze status mode) — zawsze 100% w granicach okna 60 s.
- **Luki i alerty** — brakujące węzły LKG, reguły bez podstawy, konflikty, anomalie, dryf ISAP.
- **Traceability chain (V1)** — nowelizacja/projekt → węzeł LKG → reguła → test → bundle → węzeł → werdykt → certyfikat; jeden identyfikator (OpenTelemetry + rejestr).

---

## 12. Bezpieczeństwo, supply chain i zgodność (rozbudowa V1 §11)

| Obszar | V2 |
|---|---|
| Podpis bundle | HSM/KMS, weryfikacja na każdym węźle przed aktywacją, rotacja kwartalna, klucze offline DR |
| Supply chain | SBOM per bundle, skanowanie zależności, izolacja sieciowa węzłów, brak kluczy w repo |
| Dostęp | RBAC + SoD: autor ≠ recenzent ≠ operator; 4-eyes dla BLOCKER i domen niemutowalnych; MFA operatorów |
| Audyt | WORM (append-only) werdyktów + zmian + certyfikatów; Merkle + HMAC; retention: 50 lat / bezterminowo dla spraw pracowniczych |
| Dowód dla KAS | eksport: Decision Certificate (PDF+XML podpisany), golden replay, chain of custody bundle, LKG snapshot z datą — **kompletny pakiet dowodowy** |
| Prywatność | werdykty bez danych osobowych w logach; szyfrowanie w spoczynku/transporcie; RODO/AML |

---

## 13. Organizacja i proces (rozbudowa V1 §12)

| Rola | V2 |
|---|---|
| Policy Engineer (per domena) | + praca przez declarative change (F6) i szablony; asystent LLM |
| Legal Engineer / prawnik | + walidacja **projektów ustaw** (Law Radar), aktualizacja LKG, klasyfikacja niejednoznaczności |
| Legal Knowledge Engineer (nowa) | utrzymanie LKG, mapowanie diffów prawnych na węzły, metryki pokrycia prawa |
| Platform/DevOps | control plane jako infrastruktura (§8) |
| QA | golden datasets, dowody formalne (SMT), chaos |
| SRE | SLO, runbooki, DR game days, incident P0 ≤ 15 min / P1 ≤ 1 h |
| Security | podpisy, klucze, WORM, supply chain |

**Proces:** GitOps + PR + 4-eyes + checklisty automatyczne; **weekly „law radar review"** — przegląd projektów ustaw i przygotowanych reguł SHADOW; kwartalne game days (DR, chaos, symulacja nowelizacji).

---

## 14. Porównanie: V1 (TARGET) → V2

| Wymiar | V1 | V2 |
|---|---|---|
| Pokrycie prawa | `_legal_basis` jako string + cartography | **LKG z węzłami, wersjami i dwukierunkową traceability; LCI mierzalne** |
| Pewność | audyt + testy + kanary | **runtime invariants + weryfikacja formalna (SMT) + Golden Oracle + ewaluacja różnicowa** |
| Dowód dla człowieka | werdykt 25-polowy + provenance | **Decision Certificate z klasą pewności i pieczęcią kryptograficzną** |
| Adaptacja | reakcja: 24 h / 4 h po publikacji | **proakcja: Law Radar, reguły gotowe przed wejściem prawa** |
| Prostota zmiany | manifest 8 pól + pipeline | **declarative change: człowiek opisuje, maszyna wykonuje; szablony domenowe** |
| Control plane | opisany (bundle server, kanary) | **konkretne mechanizmy OPA: sign, persist, discovery, status, delta, Data API** |
| Metryki | SLO operacyjne | **+ Indeksy Pewności (LCI, TCL, RV, UVR) i dashboard „Pewność"** |
| Baza danych | 9 tabel (w tym `jdg_legal_cartography`) | **ewolucja cartography → `legal_graph` (LKG) + nowe: `invariants`, `golden_verdicts`, `decision_certificates`, `draft_law_radar`** (migracje 003+) |

---

## 15. Roadmap V2 (nadbudowa nad V1 F0–F5)

| Faza | Zakres | Czas | Kryterium ukończenia |
|---|---|---|---|
| **V2-F0. Legal Twin MVP** | LKG (akty→artykuły→węzły) dla 13 aktów; `_legal_basis` → referencje; bramka RV; metryka LCI | 8–12 tyg. | 100% reguł VAT/PIT/ZUS z referencjami LKG; LCI raportowane |
| **V2-F1. Warstwa Konstytucyjna** | katalog INV + runtime check w main_jdg + blokada CI; golden verdicts table | 4–6 tyg. | 0 naruszeń INV w runtime; golden replay w CI |
| **V2-F2. Dowód formalny** | SMT/Z3 dla pakietów krytycznych (ZUS, PIT, KKS); mutation ≥ 85% dla krytycznych | 8–12 tyg. | dowody w CI; raport formalny per bundle |
| **V2-F3. Decision Certificate** | generacja PDF/XML + pieczęć + klasa pewności + weryfikacja offline | 4–6 tyg. | każdy werdykt z certyfikatem; klasa pewności w API |
| **V2-F4. Law Radar** | crawler projektów (RCL/Sejm/Senat), AI-reader projektów, SHADOW-preparacja, kalendarz z countdownem | 8–12 tyg. | nowelizacja wdrożona w dniu wejścia w życie (test pilotażowy na prawdziwej zmianie) |
| **V2-F5. Declarative Change + control plane infra** | interfejs deklaratywny, szablony domenowe, bundle server + sign + persist + discovery + status | 8–12 tyg. | zmiana parametru < 1 min; zmiana reguły opisana w języku prostym → wdrożona z bramkami |
| **V2-F6. Hardening i zgodność** | eksport dowodów dla KAS, WORM, SBOM, DR game days, dashboard „Pewność" | 4–8 tyg. | audyt zewnętrzny + chaos bez usterek |

Łącznie **~6–9 miesięcy** po/obok faz V1; fazy niezależne (V2-F0 ‖ V2-F1, V2-F3 ‖ V2-F4) można realizować równolegle. V2 nie anuluje V1 — **implementuje fundament V1 (F0–F5) wzbogacony o filary pewności**.

---

## 16. Jednozdaniowe podsumowanie

**Najdoskonalszy system OPA klasy ENTERPRISE to taki, w którym każda decyzja podatkowa jest nie tylko poprawna, ale i *dowodliwie* poprawna — prawo ma cyfrowego bliźniaka, niezmienniki strzegą każdego werdyktu, zmiany prawa przygotowuje się zanim wejdą w życie, a przedsiębiorca dostaje w ręce kryptograficznie poświadczony certyfikat każdej decyzji: *„niezachwiana pewność" nie jest obietnicą — jest architekturą.***

---

*Dokument V2 bazuje na: ARCHITEKTURA.md, ANALIZA_STANU_OPA_JAKO_SYSTEM.md (luki L1–L12), ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md (cel V1), RULE_LIFECYCLE.md, ADR 001–015, audycie realnej infrastruktury repo (bundle.sh v8.0, rule_lifecycle_manager.py, isap_rule_update_pipeline.py, decision_quality_monitor.py, migracje 001/002) oraz dobrych praktykach OPA enterprise (bundle signing, persist/discovery/status, delta bundles, OPAL, Data API, Regal, WASM, progressive delivery). Spójny z: MANIFEST.md · STRUKTURA_PROJEKTU.md · UNIFIED_PLAN.md.*
