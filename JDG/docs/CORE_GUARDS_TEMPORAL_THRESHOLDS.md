# Core Guards Temporal Thresholds — ETAP 06/29

> **Status:** WDROŻONY_100
> **Data:** 2026-08-20
> **Walidator:** `JDG/tools/core_guards_temporal_thresholds.py`
> **Testy:** `JDG/tests/test_core_guards_temporal_thresholds.py`

## 1. Przegląd

Warstwa konstytucyjna systemu JDG — 42 niezmienniki (INV-001..INV-042) egzekwowane:
- **RUNTIME** (21): na KAŻDYM werdykcie przez `enforce(v)` (ADR-022)
- **BUILD** (14): blokada merge w CI (syntax, structural)
- **STATISTICAL** (7): monitoring + auto-rollback

## 2. Invariant Catalog

| ID | Opis | Level | Enforcement |
|----|------|-------|-------------|
| INV-001 | stawka VAT ∈ {0, 0.05, 0.08, 0.23, ZW, NP, OO} | RUNTIME | BLOCK |
| INV-003 | brutto = netto × (1+stawka) ± epsilon | RUNTIME | BLOCK |
| INV-005 | werdykt domeny niemutowalnej nigdy nie nadpisany | RUNTIME | BLOCK |
| INV-018 | brak sprzecznych werdyktów tej samej domeny | RUNTIME | BLOCK |
| INV-030 | bundle_version + rule_version + threshold_version | RUNTIME | BLOCK |
| INV-035 | BLOCK_AND_ALERT → brak AUTO_POST | RUNTIME | BLOCK |
| INV-037 | okna ważności: zero luk + zero nakładek | BUILD | BLOCK |
| INV-039 | provenance_tree.path ≥ 1 dla matched=true | RUNTIME | BLOCK |
| INV-042 | allowlist niemutowalna w runtime (safe_merge) | RUNTIME | BLOCK |

Pełna lista: 42 invariantów w `INVARIANT_CATALOG` (tools/core_guards_temporal_thresholds.py)

## 3. Evaluate → Enforce Chain

```
werdykt → evaluate(v) → {invariant_failed, certainty_class, failed[]}
         → enforce(v) → {_invariant_report, _certainty_guard, _decision_certificate}
```

| Certainty Class | Guard | AUTO_POST |
|----------------|-------|-----------|
| CERTAIN | AUTO_POST_ALLOWED | TAK |
| CONDITIONAL | MANUAL_REVIEW | NIE |
| NEEDS_ADVICE | CERTAINTY_BLOCKED | NIE (nigdy) |

## 4. Temporal Interval Algebra (INV-037)

- **zero gaps**: next_from > end_prev + 86400s
- **zero overlaps**: b_from > a_to (lub a_to == null)
- **deterministic pin**: max(valid_from) among eligible for date
- **P1627**: globalny dowód zero luk + zero nakładek
- **P1632**: dokładnie jedna wersja aktywna na datę

## 5. Hardcoded Audit (ADR-002)

- Target: 0 hardcoded w nowych regułach
- Wagi NIP/REGON: z `thresholds.checksum_weights`
- Stawki VAT/PIT/ZUS: w `data.thresholds.jdg.*` (hot-reload < 1 min)
- CI gate: `hardcoded_audit_gate.py --gate N`

## 6. Validation Rules (R0613-R0620)

- NIP: modulo 11 z wagami [6,5,7,2,3,4,5,6,7]
- REGON: 9-cyfrowy [8,9,2,3,4,5,6,7], 14-cyfrowy [2,4,8,5,0,9,7,3,6,1,2,4,8]
- Amount: netto + VAT = brutto ± 0.01
- Date: issue_date ≤ today, sale_date ≤ issue_date + 30

## 7. Fallback/Degradation

| API | Fallback | Routing |
|-----|----------|---------|
| Whitelist MF | retry + cache 30 dni | TRIAGE_QUEUE |
| CEIDG | retry queue | (brak BLOCK bez fraud) |
| KSeF | FALLBACK_ACTIVE 7 dni | FALLBACK_ACTIVE |
| NBP | cached rate | TRIAGE |
| Multi ≥3 | BLOCK_AND_ALERT | BLOCK |

## 8. Użycie

```bash
python JDG/tools/core_guards_temporal_thresholds.py build
python JDG/tools/core_guards_temporal_thresholds.py validate
pytest -q JDG/tests/test_core_guards_temporal_thresholds.py
```
