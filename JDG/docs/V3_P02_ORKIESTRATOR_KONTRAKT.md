# V3-P02 ORKIESTRATOR — KONTRAKT WIĄŻĄCY

Status: **WDROŻONY_100** · Raport: `raporty_glm52_v3/RAPORT_V3_P02_ORKIESTRATOR.txt`
Prompt źródłowy: `prompty_v3/V3_PROMPT_P02_ORKIESTRATOR.txt`
Generator: `tools/glm52_v3_campaign/` · Ledger: `bundles/v3_campaign_ledger.json` (P02)

Ten dokument jest **wiążącym kontraktem wyjściowym** dla całego nurtu orkiestracji
(PASS 0–8, routing sharded, safe_merge, mirror policies). Każda późniejsza część
(P37 obserwowalność, P66 chaos, P53 temporalność itd.) musi operować na poniższych
identyfikatorach, metrykach i bramkach — zmiana kontraktu wymaga nowego raportu.

---

## 1. Architektura orkiestratora (stan faktyczny)

```
wejście (fakty + intencja)
  → PASS 0  sanity/gate (abort wcześnie: risk, routing block)   [gated_abort_verdict]
  → PASS 1  routing: shard_selector (domestic_sale/purchase → shard; else → full)
  → PASS 2  sharded_sale_verdict   (sprzedaż — pełny łańcuch sprzedażowy)
  → PASS 3  sharded_purchase_verdict (zakup — pełny łańcuch zakupowy)
  → PASS 4  full_final_verdict     (else: komplet 25 pól z wypełnieniem luk)
  → POST-MERGE: runtime_invariants.enforce()  (INV katalog, BLOCK/ALERT/AUTO_REVERT)
  → safe_merge(3 przypadki) → final_verdict (public contract, 25 pól)
```

- **4 ścieżki werdyktowe**: `gated_abort_verdict`, `sharded_sale_verdict`,
  `sharded_purchase_verdict`, `full_final_verdict` — **dokładnie 1** werdykt na wejście
  (selector `else=true`, kompletność 192 kombinacji, 0 orphan, 0 double).
- **Katalog invariantów**: `rules/audit/runtime_invariants_enterprise.rego` — **42 INV**
  (10 BUILD / 29 RUNTIME / 3 STATISTICAL; 39 BLOCK / 2 ALERT / 1 AUTO_REVERT),
  `enforce()` wołany w POST-MERGE przed public contract; `final_verdict` po enforce.
- **safe_merge**: 3 przypadki (nadpisanie pól kontraktu wartościami z PASS z priorytetem;
  nadpisanie chronione allowlistą niemutowalną: `jdg.zus.*`, `jdg.business`,
  `jdg.security.fortress`; brak nadpisania = wartość zostaje).
- **Allowlista niemutowalna**: `jdg.zus`, `jdg.zus.sickness_benefits`,
  `jdg.zus.enterprise_benefits`, `jdg.zus.health_contribution`, `jdg.business`,
  `jdg.security.fortress` — pola pisane wyłącznie przez domenę właścicielską (I03).
- **Słownik werdyktu**: **25 pól** (public contract) — 25-polowy kontrakt obowiązkowy;
  pole z pustym zapisem `""` = pad kontraktu, nie nadpisanie.
- **Fail-closed**: żadna degradacja nie jest cichym AUTO_POST (I05); każda ścieżka
  early-abort kończy się werdyktem z `_routing` (I10); model wykrywa 100% braków
  kontraktu (I12: 10 000 prób fuzz, kompletność 100%).

## 2. Metryki wiążące (rejestr telemetrii, I08 — przekazany do P37)

| Metryka | Typ | Tagi | Próg / SLO |
|---|---|---|---|
| `jdg_orchestrator_pass_duration_ms` | histogram | pass, shard, transaction_type | p95 ≤ 5000 ms full chain; deklaracja p95 < 5 ms/shard |
| `jdg_orchestrator_early_abort_total` | counter | class (domain_block/routing_block/validation) | każdy abort liczony; 0 cichych |
| `jdg_orchestrator_merge_overrides_total` | counter | field, source_pass, target_pass | każda zmiana przez safe_merge widoczna |
| `jdg_orchestrator_invariant_block_total` | counter | invariant_id, level | każdy BLOCK rejestrowany |
| `jdg_orchestrator_degradation_total` | counter | from_state, to_state | każda degradacja niesie _warnings |
| `jdg_orchestrator_shard_hit_ratio` | gauge | shard | pokrycie routingu |
| `jdg_orchestrator_verdict_incomplete_total` | counter | pass, missing_field | fail-closed; 0 w runtime |
| `jdg_mirror_sync_drift_total` | gauge | file | drifty mirror vs canonical (aktualnie 4) |
| `jdg_orchestrator_provenance_evaluation_ms` | histogram | shard | koszt provenance w ścieżce sharded |

`metric_count = 9` (rejestr w `bundles/v3_p02_telemetry_hooks.json`).
Zakaz zmiany nazw/tagów bez raportu zmiany kontraktu (wiązanie z P37).

## 3. Identyfikatory wiążące

- PASS: `PASS0..PASS8` (fazy orkiestracji, patrz prompt P02 §6.4).
- Werdykty: `gated_abort_verdict`, `sharded_sale_verdict`, `sharded_purchase_verdict`,
  `full_final_verdict`, `final_verdict` (public).
- Invarianty: `INV-001..INV-042` (katalog `runtime_invariants_enterprise.rego`).
- Bramki: `V3-P02-I01..I12` (narzędzia `tools/v3_p02_*.py`).
- Luki: `V3-P02-L01..L0N` (raport; każda z priorytetem P0/P1 i właścicielem).

## 4. Bramki P02 (wszystkie uruchamiane w CI/audycie)

| Bramka | Reguła | Stan |
|---|---|---|
| I01 Constitutional PASS | ≥40 INV, enforce() w POST-MERGE, final po enforce, 0 bypassów | PASS |
| I02 Determinism | 0 duplikatów pakietów w łańcuchu, guardy rozłączne, selector else=true | PASS |
| I03 Field Ownership | pola kwotowe/stawkowe pisane wyłącznie przez domenę właścicielską | **FAIL (6 pól)** → luki L04–L06 |
| I04 Shard Completeness | 192 kombinacje pokryte, 0 orphan, 0 double | PASS (1 finding: dead code `shard_selector_deprecated`) |
| I05 Degradation Ladder | żadna degradacja cichym AUTO_POST; każda niesie _warnings | PASS |
| I06 Latency Budget | żaden PASS nie przekracza budżetu | PASS |
| I07 Merge Monotonicity | merge monotoniczny / chroni werdykt niemutowalny | PASS (2000 prób) |
| I08 Telemetry Hooks | rejestr 9 metryk wiążących | PASS |
| I09 Declarative Shard Registry | aliasy spójne, 0 orphan-pakietów, provenance | PASS |
| I10 Early-Abort Forensics | 19 punktów abort, 0 cichych ścieżek | PASS |
| I11 Mirror Sync Gate | mirror bit-do-bit zgodny z canonical | **FAIL (4 drifty)** → luka L01 |
| I12 Verdict Fuzzer | 0 werdyktów bez pełnego kontraktu (10 000 prób) | PASS |

## 5. Wyjście z P02 (przekazane dalej)

1. **P37 (obserwowalność)**: rejestr metryk I08 + hooki per PASS (nazwy i tagi wiążące).
2. **P66 (chaos/odporność)**: model degradacji I05, early-abort I10, monotoniczność I07.
3. **P53 (temporalność)**: determinizm I02 + brak mutacji czasu w łańcuchu (0 naruszeń).
4. **V3-08..12 (domknięcia)**: shard registry I09 z aliasami pakietów (provenance).
5. **Mirror `policies/` (branch)**: I11 — bramka sync; drifty 4 plików do naprawy (L01).