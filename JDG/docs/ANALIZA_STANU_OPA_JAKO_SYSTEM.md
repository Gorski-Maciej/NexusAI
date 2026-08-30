# 🔬 ANALIZA STANU OBECNEGO — OPA JAKO SYSTEM W MODULE JDG

> **Dokument:** ANALIZA_STANU_OPA_JAKO_SYSTEM.md
> **Zakres analizy:** wyłącznie dokumentacja w `JDG/` repozytorium NexusAI
> (README.md, MANIFEST.md, COVERAGE_REPORT.md, docs/ARCHITEKTURA.md, docs/ARCHITECTURE.md (ADR 001–015),
> docs/OPA_JAKO_SYSTEM_P21.md, docs/NARZEDZIA_WALIDACJI_P22.md, docs/TESTY_REGO_CI_P23.md,
> docs/RULE_LIFECYCLE.md, docs/UNIFIED_PLAN.md, docs/DEVELOPER_GUIDE.md, docs/OPA_REGO_DEVELOPER_GUIDE.md,
> docs/FAQ.md, docs/INWENTARYZACJA_PLIKOW.md, docs/KATALOG_NARZEDZI.md, docs/KATALOG_REGUL.md,
> docs/STRUKTURA_PROJEKTU.md, docs/PODRECZNIK_UZYTKOWNIKA.md, docs/LOGIKA_BIZNESOWA.md, docs/P02–P24)
> **Data analizy:** 2026-08-07
> **Odniesienie:** wymóg użytkownika — *„OPA musi być rozbudowanym SYSTEMEM, silnik reguł podatkowych OPA musi się szybko i profesjonalnie adaptować do zmian, dodawanie i usuwanie reguł musi być sprawne, niezawodne i proste"*

---

## 1. Metodologia

Analizę przeprowadzono wyłącznie na podstawie dokumentacji zawartej w katalogu `JDG/` (dokumenty, manifesty, katalogi narzędzi, plany, ADR). Nie analizowano kodu źródłowego poza tym, co dokumentacja wprost cytuje (fragmenty Rego, komendy CLI, schematy tabel).

**Uwaga o niespójnościach:** dokumentacja zawiera rozbieżne liczby (np. pliki Rego: 439 vs 383 vs 176; rule_id: 11 452 vs 10 878 vs 10 827; narzędzia: 57 vs 98 vs 130). Tam, gdzie to możliwe, podano zakres i wskazano źródło. Jest to samo w sobie istotny sygnał dojrzałości (patrz §5, luka L9).

---

## 2. Synteza — co dokumentacja deklaruje o OPA w JDG

### 2.1. Fakty liczbowe (wg README.md / MANIFEST.md, stan 2026-08-22)

| Metryka | Wartość | Źródło |
|---|---|---|
| Pliki Rego | 490 (rules/) | README, MANIFEST (2026-08-30) |
| Unikalne rule_id | 11 855 | README / MANIFEST |
| Bloki `matched: true` | 11 855 | MANIFEST |
| Duplikaty rule_id | 0 | MANIFEST |
| Stuby `{ true }` | 25 (dead_rule_detector, po kampanii P00) | P22 / P00 |
| Akty prawne pokryte | 13 | README |
| Inicjatywy strategiczne | 24 (A1–C3, S1–S24) | README |
| Pakiety w orkiestratorze | ~60+ | OPA_REGO_DEVELOPER_GUIDE / ARCHITEKTURA |
| Reguły w bundle | 11 855 (490 plików) | MANIFEST / bundles |
| Narzędzia Python | 298 | KATALOG_NARZEDZI |
| Natywne testy Rego | 207 plików `test_native_*.rego` (w tym mikro) | INWENTARYZACJA / ETAP 28 |
| Testy pytest | 198 | ETAP 28 / INWENTARYZACJA |
| Audit-state (ETAP 06–28) | 22 — wszystkie WDROZONY_100 | bundles/ |
| Migracje RuleStore | 13 (001–013) | migrations/ |
| Certyfikacja końcowa | ETAP 28/29 — 14/14 bramek, 18 domen (13 CERTIFIED) | final_certification_etap28 |
| Endpointy API | 10–12 | openapi.yaml / api.md |

### 2.2. Architektura decyzyjna (jak OPA podejmuje decyzje)

- **Orkiestrator `main_jdg.rego`** — scalanie werdyktów ~55–60 pakietów przez `safe_merge`, budowa `final_verdict`.
- **Multi-Pass (ADR-007)** — PASS 0 (risk) → PASS 1 (routing) → PASS 2 (compliance) → PASS 3 (crossborder) → PASS 4 (VAT) → PASS 5 (PIT) → PASS 6 (allowances) → PASS 7 (accounting) → PASS 8 (ZUS/business/KSeF/JPK) → POST-MERGE (konflikty + enrichment + provenance). PASS-0 Gate skraca ewaluację transakcji fraudowych o 40–60%.
- **Sharded Router (ADR-009, B1)** — routing O(1) po `routing_context` (tax_form × transaction_type × entity_status × evaluation_quarter × is_cross_border × has_employees × is_vat_payer × requires_ksef); 4 ścieżki: `gated_abort_verdict`, `sharded_sale_verdict`, `sharded_purchase_verdict`, `full_final_verdict`. Deklarowany cel p95 < 5 ms na shard (krajowe 8–12 ms; pełny łańcuch cross-border ~8–12 s).
- **25-polowy werdykt (ADR-004)** — stała struktura JSON (`matched`, `rule_id`, `vat_rate`, `_legal_basis`, `_routing`, `_warnings`…), `safe_merge` chroni werdykty niemutowalne (ZUS, business — allowlist).
- **First-Match-Wins else-chain (ADR-001)** — deterministyczna kolejność reguł; priorytety numeryczne są metadanymi.

### 2.3. Reguły — warstwy i konwencje

| Warstwa | Plików | Reguł (szac.) | Opis |
|---|---|---|---|
| Macro (Core) | ~153 | ~6 300 | Reguły decyzyjne (VAT, PIT, ZUS, KKS…) |
| Micro (atomowa) | ~106 | ~3 500 | Per artykuł ustawy (`micro/plan33_*`) |
| Enterprise S1–S24 | 25+ | ~350 | Optymalizacja, KSeF, deklaracje, monitoring |
| Hyper Plan45 | 14 | ~450 | Terminy, limity, sankcje |

Konwencje: rule_id `jdg.<domena>.<kategoria>` (ADR-008), CHECKPOINT-STUB dla reguł `{ true }` (ADR-015), priorytety numeryczne per domena (UoR 100001+, PCC 200001+…).

### 2.4. Temporalność i dane

- **Temporalność (ADR-003, A2)** — `valid_from`/`valid_to` w `temporal.rego` i `_metadata_jdg.rego`; wersje reguł w tabeli `rule_versions`; time-travel: wybór wersji wg daty transakcji (Art. 3 OrdPU). Detektory P1619–P1624 (overlap, pin, kalendarz zmian prawa, shadow window, rollback window, gap detector).
- **Zero Hardcoded (ADR-002, B2)** — stawki/progi/limity w DuckDB (`jdg_tax_thresholds`), dostarczane przez OPA Data API (`data.thresholds.jdg.*`), hot-reload bez redeployu bundle. **Status: ⚠️ częściowo — ~265 zakodowanych wartości w 32 plikach.**
- **RuleStore DuckDB** — 9 tabel: `jdg_tax_thresholds`, `rule_versions`, `jdg_verdict_audit`, `isap_history`, `jdg_legal_cartography`, `jdg_prediction_history`, `jdg_stale_rules_registry`, `jdg_conflict_registry`, `jdg_explanation_cache`.

### 2.5. Bundle i deployment (ADR-011)

- `bundle.sh` v8.0 buduje `jdg-bundle-{wersja}.tar.gz` z zachowaniem struktury katalogów (fix R1 — 8 kolizji nazw), weryfikacja licznika plików, manifest (11 855 reguł, 490 plików, serwis thresholds, podpis SHA256).
- Deployment: `curl -X PUT --data-binary @bundle.tar.gz http://opa-server:8181/v1/bundles/jdg`.
- `policies/` — lżejszy mirror reguł (32 pakiety, v2026.07.10) z bundle overlays `v2026`/`v2027` (nakładki czasowe). **Zasada deklarowana:** `JDG/rules/` = źródło prawdy, `policies/` = eksperymenty/wersjonowanie. Zasada auto-sync co 24 h (P21 INN-04).
- Rollback: wg PODRECZNIK_UZYTKOWNIKA.md — powrót do wcześniejszej wersji bundle („Aktualizacje → Historia → Wróć do vX.Y"), werdykty historyczne nienaruszone (time-travel).

### 2.6. Cykl życia reguły (co dokumentacja deklaruje)

- **Pipeline 11 kroków (P21):** ISAP → DETEKCJA → ANALIZA WPŁYWU → GENEROWANIE → WALIDACJA → TESTY → SYMULACJA → BUNDLE → DEPLOY KANARY → MONITORING → ROLLBACK.
- **Statusy reguł (RULE_LIFECYCLE):** SHADOW (ewaluacja, bez wpływu) → CANDIDATE (A/B, bucket < rollout_pct) → ACTIVE → ROLLED_BACK. Narzędzia: `rule_lifecycle_manager.py` (register/promote/rollback/check), `isap_rule_update_pipeline.py` (ingest → impact → plan), `decision_quality_monitor.py` (feedback, adaptive thresholds).
- **Hot-reload:** zmiana `data.jdg.rule_registry` / `data.jdg.threshold_changelog` = natychmiastowy efekt bez restartu i bez rekompilacji bundle.
- **Feature-flagi (P21 INN-10):** shadow mode, kill-switch.
- **Auto-adaptacja 24 h (P21 INN-07):** ISAP → reguły → testy → bundle w 24 h.

### 2.7. Jakość i testy (co dokumentacja deklaruje)

- **Pipeline jakości 8 bramek (P22):** LINT → LEGAL_BASIS → DEAD_RULE → TAUTOLOGY → HARDCODED → ZERO_DEFECT → REGRESSION → BUNDLE → PRODUCTION, `block_on_fail`.
- **Control Tower (P21 INN-06):** 7 bramek (syntax, legal_basis, dead_rule, tautology, hardcoded, cross_ref, regression).
- **Zero-Defect (P22):** 7 kryteriów certyfikacji ENTERPRISE-CERTIFIED 100/100; certyfikat per reguła.
- **Testy (P23):** unit (rego) → property (40) → fuzz (10 000 wejść) → mutation (≥70%, 85/100 zabitych) → integration → E2E (15) → regression gate; coverage ≥ 90%; testy graniczne grosze (0.01/0.005/0.999), waluty; testy negatywne no_match (83.3%); kanary testowe na produkcji (shadow, 1000 ewaluacji, 98% match).
- **Symulatory (P22):** digital twin (dryf < 95% → alert), chaos engineering (8 scenariuszy, recovery < 500 ms), predictive audit shield (risk ≥ 0.7 → flag), rule_impact_simulator, legal_change_impact_analyzer, judgment_predictor.
- **Self-healing (P22 INN-06):** auto-korekta reguł z raportów (max 5/cykl); `self_healing_engine.py`.

### 2.8. Monitoring i bezpieczeństwo (co dokumentacja deklaruje)

- **Monitoring:** `GET /jdg/health` (OPA, DuckDB, API zewnętrzne, liczba reguł, uptime), metryki `_cost_ms`/`_shard_routed` w werdyktach, `isap_history`, `jdg_stale_rules_registry`, decision_quality_monitor (30 dni, jakość < 95% → alert), `isap_drift_alarm` (P21 INN-13), telemetria p95 < 5 ms/shard (INN-15).
- **Niezawodność:** resilience_audit (fallbacki, retry 3× backoff, circuit-breaker 5 błędów, timeout 500 ms); chaos engineering; bundle_signature (SHA256, manifest_hash, tamper detection).
- **Audyt:** Immutable Audit Trail (ADR-006) — HMAC-SHA256 + Merkle Tree dla werdyktów ZUS/zdrowotnych; `jdg_verdict_audit` (verdict_id, input_hash, merkle_root, ecdsa_signature, bundle_version, shard_routed, evaluation_ms); rule_change_proof (hash-chain, INN-11).
- **Bezpieczeństwo:** JWT Bearer, RBAC (role: przedsiębiorca/księgowa/doradca/dev/audytor), rate limiting, semantic guard, firewall.

### 2.9. CI/CD (co dokumentacja deklaruje)

- 15 workflow GitHub Actions + pre-commit; bramki blokujące merge: lint FAIL, validate FAIL, manifest niespójny, tautologia, zero-defect < 85%.
- `isap-scheduler.yml` (cron daily): sprawdza nowe akty w ISAP, wykrywa drift temporalny, tworzy Issue z alertem.

---

## 3. Ocena względem wymogu: „OPA jako rozbudowany SYSTEM"

### 3.1. Co dokumentacja potwierdza jako działające koncepcje (✔)

| Wymóg użytkownika | Co istnieje w JDG (wg dokumentacji) | Ocena koncepcyjna |
|---|---|---|
| Szybka adaptacja do zmian prawa | Pipeline 11 kroków (P21), auto-adaptacja 24 h (INN-07), isap_crawler, isap_rule_update_pipeline, hot-reload thresholdów, temporalność z wersjami | ✔ Koncepcja kompletna; **wykonanie częściowe** (patrz luki) |
| Dodawanie/usuwanie reguł proste i niezawodne | rule_registry, rule_lifecycle_manager (SHADOW→CANDIDATE→ACTIVE→ROLLED_BACK), feature flagi, kill-switch, generatory reguł, CHECKPOINT-STUB | ✔ Koncepcja dobra; **wykonanie częściowe** (stuby 512, duplikaty 369) |
| Niezawodność przy zmianach | Kanary 5%/30 min, shadow deployment (delta ≤ 2%), auto-rollback (jakość < 95% / błąd > 1%), bundle signature, persist/rollback bundle, chaos engineering | ✔ Koncepcja dobra; **wykonanie częściowe** (deklaracje w regułach audytujących, nie w infrastrukturze) |
| OPA jako SYSTEM (nie tylko silnik) | P21 „OPA jako System", orkiestrator, RuleStore, narzędzia, CI/CD, monitoring | ✔ Ambicja wyraźna; **luka architektoniczna** (brak realnego control plane — patrz §4) |

### 3.2. Ocena kluczowego ryzyka: deklaracje w regułach vs infrastruktura

Najważniejszy sygnał z analizy dokumentacji: **duża część „systemowości" (P21–P24) jest zaimplementowana jako reguły Rego audytujące stan infrastruktury, a nie jako sama infrastruktura.** Np.:
- `bundle_signature` (P21 INN-03) to **reguła Rego**, która audytuje, czy bundle jest podpisany — a nie mechanizm kryptograficznej weryfikacji w procesie wdrożenia.
- `canary_deploy` (INN-01) to reguła opisująca politykę kanarkową — a nie realny orchestrator rolloutów.
- `control_tower` (INN-06), `quality_pipeline` (P22), `test_shield` (P23) — reguły audytujące narzędzia.
- `rule_lifecycle_pipeline` (P21) — reguła deklarująca pipeline; narzędzia CLI (`rule_lifecycle_manager.py`) istnieją, ale dokumentacja nie opisuje ich integracji z realnym deploymentem OPA (UNIFIED_PLAN Faza 5.3: „Test deploymentu OPA ⬜").

**Konsekwencja:** OPA w JDG jest dziś **silnikiem z bardzo rozbudowanym „systemem audytu samego siebie"**, ale brakuje warstwy wykonawczej (control plane), która realnie: buduje, podpisuje, dystrybuuje, wdraża kanarkowo, monitoruje i wycofuje bundle na środowisku produkcyjnym. To dokładnie obszar, który decyduje o byciu „SYSTEMEM" — i główny temat pliku towarzyszącego [ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md](ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md).

---

## 4. Analiza luk (gap analysis) — na podstawie dokumentacji

### L1. Brak realnego control plane (najkrytyczniejsza luka)
- Dokumentacja nie opisuje serwera bundle z podpisywaniem (`opa sign`), weryfikacją kluczy, delta-bundles, serwera statusu OPA, ani orkiestratora rolloutów (kanary/szarość/blue-green) na produkcji.
- Brak opisanego „policy registry" jako usługi z API dla operatorów (deklarowany INN-09 `/v1/rules` — nie wiadomo, czy zaimplementowany).
- Brak opisanego modelu wdrażania: kto, kiedy, jak wypycha bundle do N instancji OPA.

### L2. Niespójność danych dokumentacyjnych (utrudnia niezawodne operacje)
- Pliki Rego: 490 (README/INWENTARYZACJA/MANIFEST 2026-08-30) — spójne po kampanii GLM 5.2.
- rule_id: 11 855 (README/MANIFEST 2026-08-30) — spójne; historyczne rozbieżności (10 878/10 827/10 509) rozwiązane przez regenerację MANIFEST.
- Testy natywne: UNIFIED_PLAN Faza 4 mówi „0 plików .rego w JDG/tests/" (ADR-013: ❌), a INWENTARYZACJA_PLIKOW raportuje 103+25 plików `test_native_*.rego`, zaś P23 — 98 testów rego w mapie pokrycia. **Wewnętrzna sprzeczność dokumentów.**
- Narzędzia: 57 (README) vs 98 (P21) vs 130 (KATALOG_NARZEDZI).
- Wniosek: brak jednego „single source of truth" dla metryk — konieczny autorytatywny rejestr (manifest 2.0 + API), regenerowany w CI i blokujący przy rozbieżności.

### L3. Niesfinalizowana deduplikacja i higiena reguł
- Duplikaty rule_id: **3** (MANIFEST 2026-08-22) — kampania P00/P01 zredukowała 369 → 99 → 3; deduplikacja domknięta (dawny cel M4: 2026-10-01 zrealizowany wcześniej).
- 512 stubów `{ true }` (P22) — część oznaczona CHECKPOINT-STUB (ADR-015), ale skala wymaga systematycznego procesu „zero stubów w produkcji".
- Wniosek: zanim system będzie „prosty" w dodawaniu reguł, musi istnieć automatyczny guard uniemożliwiający wprowadzenie duplikatu/stuba (blokada CI + pre-commit), a nie proces ręczny.

### L4. Zero-Hardcoded tylko częściowo
- ~265 zakodowanych wartości w 32 plikach (ADR-002, audyt 2026-07-13); migracja do `jdg_tax_thresholds` planowana (Faza C7, ~60%).
- Wniosek: pełne wykonanie ADR-002 jest warunkiem „zmiana stawek = zmiana danych, nie kodu" — kluczowe dla szybkiej adaptacji.

### L5. Dwuwładztwo `rules/` vs `policies/`
- Istnieje ryzyko dryfu (P21: policies_drift_audit, alert ≥ 10%). Zasada „JDG/rules = źródło prawdy + auto-sync co 24 h" redukuje ryzyko, ale 24 h dryfu przy pilnej zmianie prawa to za dużo; docelowo jeden katalog + nakładki (overlays) jako jedyny mechanizm wariantów czasowych.

### L6. Brak opisanego cyklu awaryjnego i DR/BCP
- Dokumentacja nie opisuje: procedur disaster recovery, celu RPO/RTO, kopii zapasowych RuleStore, multi-AZ/multi-region, runbooków, zarządzania incydentami, P0/P1/P2. Chaos engineering deklarowany (8 scenariuszy, recovery < 500 ms) — ale nie opisano, jak wyniki są egzekwowane.

### L7. Testy natywne — luka pomiędzy deklaracją a planem
- P23 deklaruje tarczę testową (coverage ≥ 90%, mutation ≥ 70%), ale ADR-013 i UNIFIED_PLAN wskazują, że natywne testy Rego są w trakcie rozbudowy (cel ≥ 20 plików do Q4 2026; obecnie ~103 wg INWENTARYZACJI — niespójne z ADR-013 „0 plików").
- Brak opisanej strategii **regression-gate dla zmian prawa** na historycznych danych (replay werdyktów) — deklarowany law_change_simulator, ale nie opisano repozytorium „golden verdicts".

### L8. Brak opisanego modelu uprawnień operacyjnych
- RBAC dla użytkowników API jest (role w PODRECZNIK_UZYTKOWNIKA), ale brak opisanego modelu dla operatorów systemu: kto może promować regułę do ACTIVE, kto wdraża bundle, kto ma klucz podpisujący, 4-eyes dla zmian krytycznych, separacja obowiązków (SoD).

### L9. Brak pełnej obserwowalności procesu zmiany
- Brak opisanego end-to-end śledzenia zmian: od nowelizacji (ISAP) przez issue/PR po bundle i werdykt — tzn. brak „traceability chain" łączącego akt prawny → regułę → test → bundle → decyzję. Istnieją elementy (isap_history, rule_provenance_dna, _legal_basis), ale bez spójnego łańcucha.

### L10. Brak metryk SLA/SLO i jakości w czasie
- Jakość decyzji monitorowana (30 dni, < 95% → alert), ale brak opisanego: SLO dla latencji (p95), dostępności, czasu adaptacji (24 h jako cel INN-07, ale bez mechanizmu pomiaru i raportowania), budżetu błędu, raportów okresowych.

### L11. Bezpieczeństwo łańcucha dostaw (supply chain)
- Podpis bundle deklarowany, ale nie opisano: zarządzania kluczami (HSM/KMS), rotacji kluczy, weryfikacji przed aktywacją na wszystkich węzłach, SBOM, skanowania zależności, izolacji węzłów OPA (network policy), WORM dla audytu.

### L12. Proces „dodania reguły" — dokumentowany, ale z lukami
- DEVELOPER_GUIDE opisuje 10 kroków (spec → generacja → lint → walidacja → testy → tautology → zero-defect → review → merge → monitoring). To dobra podstawa. Luki: brak opisanego szablonu/metadanych wymaganych (owner, testy, źródło prawa, data obowiązywania — częściowo w ADR-015), brak automatycznego generowania testów jako bramki (P23 INN-01 deklarowany, ale status wdrożenia niejasny), brak „policy as code review checklist" dla 4-eyes.

---

## 5. Ocena dojrzałości (maturity model) — per wymiar

Skala 1–5: 1 = brak, 2 = koncepcja, 3 = częściowe wdrożenie, 4 = działające wdrożenie z automatyzacją, 5 = klasa światowa (continuous, mierzalne, samouzdrawiające).

| Wymiar | Ocena | Uzasadnienie (wg dokumentacji) |
|---|---|---|
| Silnik decyzyjny (Multi-Pass, sharding, werdykty) | 4 | Dojrzała architektura, determinizm, safe_merge, proweniencja |
| Temporalność / time-travel | 4 | Pełna koncepcja (wersje, pinning, detektory luk/okien) |
| Rozdział danych od reguł (zero hardcode) | 2–3 | Koncepcja pełna (ADR-002), wykonanie ~60% (265 wartości do migracji) |
| Cykl życia reguły (dodawanie/zmiana/usuwanie) | 3 | Narzędzia CLI + statusy + hot-reload istnieją; brak integracji z realnym deploymentem |
| Pipeline adaptacji prawa (ISAP→prod) | 2–3 | Pipeline 11 kroków zdefiniowany; automatyzacja częściowa (crawler daily, generatory); deployment produkc. niedotestowany (Faza 5.3 ⬜) |
| Control plane (bundle, podpisy, rollout, rollback) | 2 | bundle.sh + manifest + curl PUT; brak signingu/kanarów/delta jako infrastruktury |
| Jakość reguł (bramki, zero-defect, self-healing) | 3–4 | Bogaty zestaw narzędzi i bramek; skala stubów/duplikatów wskazuje na niedokończony cykl |
| Testy (unit/property/fuzz/mutation/E2E) | 3 | Strategia kompletna, wykonanie niespójne z planami (ADR-013) |
| Inteligencja/uczenie (adaptive trust, Neural Mesh, predykcje) | 3 | Dowody istnieją: `adaptive_trust_scoring_enterprise.rego`, P20 Neural Mesh (knowledge graph reguł, propagacja pewności), `judgment_predictor.py` (C1), self-healing; brak opisanego domknięcia pętli (uczenie → produkcja) |
| Obserwowalność (metryki, SLO, alerty) | 3 | Health + telemetria + decision quality; brak SLO/dashboards klasy prod |
| Bezpieczeństwo i audyt | 3 | Immutable audit + JWT + HMAC/Merkle; brak modelu operacyjnego i supply chain |
| Dokumentacja i spójność danych | 2 | Bogata, ale sprzeczne liczby i statusy między dokumentami |
| DR/BCP | 1–2 | Brak opisu |

**Wynik syntetyczny: 2.7–3.2 / 5 — „działająca koncepcja systemu w budowie".** Fundament silnika jest silny (to rzadka i wartościowa baza), ale warstwa „systemu" (control plane, proces, niezawodność operacyjna, mierzalność) wymaga ukończenia.

---

## 6. Mocne strony, które należy zachować (fundament klasy światowej)

1. **Temporalność z time-travel** — rzadka cecha w systemach policy; fundament zgodności z Art. 3 OrdPU; zachować i rozbudować.
2. **Rozdział danych od reguł (ADR-002)** — właściwy wzorzec dla zmiennego prawa; dokończyć migrację.
3. **Standardowy werdykt 25-polowy + provenance** — audytowalność decyzji; `decision_hash` + Merkle — solidna podstawa dowodliwości przed KAS.
4. **Pipeline jakości (8 bramek, zero-defect, self-healing)** — koncepcyjnie wzorcowy; wymaga egzekucji infrastrukturalnej.
5. **Strategia testowa** (property, fuzz, mutation, granice groszy, negatywne) — bardzo dojrzała jak na projekt tej skali.
6. **Bogaty zestaw narzędzi** (130) — kapitał do automatyzacji control plane (nie wyrzucać, tylko zintegrować).
7. **Kanary/shadow/auto-rollback zdefiniowane jako polityki** — gotowe wzorce do przeniesienia do warstwy wykonawczej.

---

## 7. Wnioski

1. **Silnik — tak; SYSTEM — nie do końca.** Dokumentacja JDG dowodzi bardzo dojrzałego *silnika* reguł (determinizm, temporalność, audyt, jakość), ale warstwa, która czyni OPA *systemem* (control plane: budowa/podpis/dystrybucja/wdrożenie/monitoring/wycofanie bundle oraz proces operacyjny dodawania–usuwania–zmiany reguł) jest zadeklarowana głównie jako reguły audytujące, a nie jako działająca infrastruktura.

2. **Najwyższy priorytet ukończenia:** (a) realny control plane dla bundle (signing, kanary, delta, rollback), (b) dokończenie ADR-002 (zero hardcode) i deduplikacji (ADR-010), (c) jeden autorytatywny manifest z blokadą niespójności, (d) proces operacyjny „dodaj/zmień/usuń regułę" z pełną automatyzacją testów i bramek.

3. **Luka pomiędzy deklaracją a infrastrukturą** jest głównym ryzykiem niezawodności: system może „wiedzieć", że coś jest źle (audyt w regułach), ale nie mieć mechanizmu, by temu zapobiec (bramka w deployment) ani naprawić (rollback automatyczny na produkcji).

4. **Cel (pełna specyfikacja docelowa)** znajduje się w dokumencie towarzyszącym:
   [ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md](ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md) — opis jak ma wyglądać najdoskonalszy system klasy ENTERPRISE.

---

*Raport wygenerowany na podstawie analizy dokumentacji JDG (2026-08-07). Liczby cytowane za źródłami; rozbieżności opisano w §4/L2.*
