# V3-P04 INVARIANTY RUNTIME — KONTRAKT WIĄŻĄCY

Status: **WDROŻONY_100** · Raport: `raporty_glm52_v3/RAPORT_V3_P04_INVARIANTY_RUNTIME.txt`
Prompt źródłowy: `prompty_v3/V3_PROMPT_P04_INVARIANTY_RUNTIME.txt`
Generator: `tools/glm52_v3_campaign/` · Ledger: `bundles/v3_campaign_ledger.json` (P04)

Ten dokument jest **wiążącym kontraktem wyjściowym** części P04 (Warstwa
Konstytucyjna / runtime invariants). Wiąże P05 (temporalność), P06 (progi),
P07 (lifecycle rollback), P29 (KKS), P37 (obserwowalność), P38 (deployment),
P39 (testy/CI), P43 (chaos/DR), P44 (certyfikacja). Zmiana wymaga ADR (I01/P04-AN12).

---

## 1. Katalog niezmienników konstytucyjnych (fakty — I01, 2026-09-03)

Źródło: `rules/audit/runtime_invariants_enterprise.rego` — **42 INV**
(10 BUILD / 29 RUNTIME / 3 STATISTICAL; 37 BLOCK / 2 ALERT / 1 AUTO_REVERT).

| Stan egzekucji | Liczba | INV |
|---|---|---|
| ENFORCED (w `_failed_invariants` + klauzula `_inv_violated`) | 20 | INV-001..007, 009, 020-022, 024, 028, 030, 032, 034-036, 038, 039 |
| DEFERRED (klauzula jest, świadomie poza runtime — post-certyfikacja/CI) | 2 | INV-029, INV-031 (decision_hash — komentarz w rego) |
| NO_IMPL (RUNTIME/BLOCK w katalogu, BRAK klauzuli — luka P0) | 5 | INV-008, 011, 018, 033, 042 |
| DEAD_ENTRY (na liście `_failed_invariants`, BRAK klauzuli — nigdy nie odpali) | 2 | INV-012, INV-014 |
| CATALOG_ONLY (BUILD/STATISTICAL/ALERT — CI lub monitoring) | 13 | pozostałe |

**Luka P0 (L01): 7 niezmienników RUNTIME/BLOCK nie egzekwowanych w runtime**
(NO_IMPL: INV-008 rule_id-ACTIVE, INV-011 stawka↔LKG, INV-018 sprzeczne
werdykty domeny, INV-033 legal_basis_refs spójność, INV-042 werdykt
niemutowalny; DEAD_ENTRY: INV-012 zaokrąglenie groszowe, INV-014 podstawa ≥ 0).

## 2. Protokół naruszenia (I03/I04, P04-AN04) — wiążący

```
naruszenie invariantu (runtime, POST-MERGE enforce())
  → BLOCK (nigdy warning) — INV-006/035
  → alarm (metryka jdg_invariant_block_total, P37)
  → auto-revert do ostatniego zdrowego werdyktu/bundla (I03, P07)
  → incydent append-only (WORM-ready) + post-mortem automatyczny (I03)
  → klasyfikacja: auto_revert=true ⇒ P0; test negatywny wymagany (I10)
```

- **Naruszenie = NEEDS_ADVICE zawsze** (P04-AN05): mapa degradacji I06 —
  29 RUNTIME INV → jednolita degradacja BLOCK→NEEDS_ADVICE+CERTAINTY_BLOCKED;
  ALERT→CONDITIONAL+MANUAL_REVIEW. Zero cichych przejść.
- **Eskalacja (P04-AN11/I07)**: 2× naruszenie BLOCK w 24h → **FREEZE domeny**
  (AUTO_POST wyłączony); odblokowanie wyłącznie 4-eyes + zielony test negatywny.

## 3. Egzekucja i koszt (P04-AN03/I02)

- Egzekucja w POST-MERGE (`runtime_invariants.enforce()`, po safe_merge,
  przed public contract) — na KAŻDYM werdykcie z dowodem (P02).
- Indeks prekompilowany pole→INV + early-exit (pierwszy BLOCK kończy):
  koszt modelowy < 5% p95 (250 ms przy SLO p95=5000 ms) — I02 PASS;
  ścieżka naruszenia: 1 sprawdzenie (fail-fast).
- Rejestr kosztu per INV (I11) — podstawa optymalizacji; pomiar ms z P37.
- Koszt modelowy ms/check=0.02 [ZAŁOŻENIE] — kalibracja z P37.

## 4. Ewaluacja różnicowa (V2/F3 §4.4, I04, P04-AN07)

- Krytyczne domeny ewaluowane na ≥ 2 węzłach; hash kanoniczny werdyktu
  identyczny na wszystkich węzłach przy tej samej wersji bundla.
- Quorum ≥ 2/3; węzeł bez danych = nieuczestniczący (fail-closed).
- Divergence → alarm + auto-revert do węzła większościowego (P04-AN04).
- Narzędzia: `tools/differential_evaluation.py` (istniejące) + I04 P04.
- Wiąże: P38 (deployment 2 węzłów), P43 (chaos).

## 5. Testy warstwy konstytucyjnej (P04-AN06/I05/I10)

- **Negatywne testy invariantów [BM]** (I10): każdy INV runtime ma test
  „naruszenie → BLOCK" — 22 szkielety wygenerowane (P39 wdroży evaluate()).
- **Mutation testing** (I05): mutacja reguły MUSI łamać invariant — 21 mutacji,
  pokrycie 100% (dowód skuteczności katalogu).
- **Chaos drills** (I12): cotygodniowo staging — celowe złamanie → pomiar
  BLOCK+revert; SLO: wykrycie ≤ 60 ms, revert ≤ 300 ms (modelowo), audyt
  zachowany; 4/4 drilli PASS.
- **Golden/CI**: invariant_checker.py (build-time), verify_verdict_invariants.py,
  runtime_invariants_check.py — bramki CI istniejące; nowe INV wymagają testu.

## 6. Rejestr prawny niezmienników (I09, P04-AN10)

Niezmienniki wymuszone prawem — **7 BRAKUJE w katalogu runtime (L02, P1)**:

| INV-L | Prawo | Semantyka |
|---|---|---|
| INV-L01 | VAT art. 86 | odliczenia ≤ podatek należny |
| INV-L02 | PIT art. 27 | podatek ≥ 0 |
| INV-L03 | PIT art. 26 | odliczenia ≤ dochód |
| INV-L04 | ZUS art. 22 | stopy składkowe jako zakresy |
| INV-L05 | zdrowotne art. 79-81 | składka zdrowotna ≥ 0 i progi |
| INV-L06 | OrdPU art. 57 | zakaz dyrektywy wewnętrznej — determinizm |
| INV-L07 | UoR art. 7 | zasada podwójnego zapisu (bilans) |

Powiązanie INV↔legal_node (P01: PL/<akt>/art/<art>) — zmiana przepisu
(nowelizacja) → sugerowany przegląd niezmiennika (Law Radar).

## 7. Metryki do obserwowalności (P37) — wiążące

| Metryka | Typ | Próg/Alarm |
|---|---|---|
| jdg_invariant_block_total | counter | tagi: invariant_id, domain; każdy BLOCK liczony |
| jdg_invariant_checked_total | counter | tagi: invariant_id, level |
| jdg_invariant_violation_rate | gauge | trend — eskalacja 2×/24h → freeze (I07) |
| jdg_invariant_enforce_ms | histogram | budżet < 5% p95 (I02) |
| jdg_constitutional_freezes_active | gauge | liczba zamrożonych domen |
| jdg_dual_node_divergence_total | counter | rozbieżność hashów (I04) |

## 8. Wersjonowanie katalogu (P04-AN12)

- Katalog INV = artefakt wersjonowany (obecnie katalog w rego, 42 INV);
  zmiana (dodanie/usunięcie/zmiana semantyki) = **ADR + nowa wersja katalogu**
  + testy negatywne + przebudowa indeksu (I02) + wpis `_invariant_execution.
  catalog_version` w werdykcie (I08).
- Wiąże: P44 (certyfikacja), P68 (finalna) — katalog jest częścią certyfikatu.

## 9. Bramki P04 (uruchamiane w CI/audycie)

| Bramka | Reguła | Stan |
|---|---|---|
| I01 Constitution Catalog | każdy INV RUNTIME/BLOCK egzekwowany | **FAIL (7 luk)** → L01 |
| I02 Zero-Latency Index | koszt < 5% p95 + early-exit ≤ 3 checki | PASS |
| I03 Violation Autopsy | post-mortem każdego naruszenia | PASS |
| I04 Dual-Node Consensus | quorum ≥ 2/3 na ≥ 2 węzłach | PASS (divergence wykryta) |
| I05 Mutation Testing | 100% wykrywalność mutacji | PASS |
| I06 Graceful Degrade Map | naruszenie → NEEDS_ADVICE, 0 cichych | PASS |
| I07 Constitutional Freeze | 2×/24h → FROZEN; odblokowanie 4-eyes | PASS |
| I08 Invariant Provenance | werdykt niesie wykonane INV + wersję | PASS |
| I09 Legal Invariant Registry | niezmienniki prawne w katalogu | **FAIL (7)** → L02 |
| I10 Negative Test Generator | ≥ 20 testów negatywnych [BM] | PASS |
| I11 Runtime Cost Ledger | rejestr kosztu per INV + hot-spoty | PASS |
| I12 Chaos Drill | 100% drilli BLOCK+revert w SLO | PASS |