# Orchestrator Data Contract — ETAP 05/29

> **Status:** WDROŻONY_100
> **Data:** 2026-08-20
> **Walidator:** `JDG/tools/orchestrator_data_contract.py`
> **Testy:** `JDG/tests/test_orchestrator_data_contract.py`

## 1. Przegląd

Kontrakt danych orkiestratora definiuje:
- **25-pól werdyktu** (wejście): matched, rule_id, package, priority, _routing, _routing_reason, _legal_basis, _warnings, vat_rate, pit_form, pit_rate, zus_health_rate, ...
- **Rozszerzoną odpowiedź** (wyjście): + _provenance_tree, _invariant_report, _certainty_class, _certainty_guard, _decision_certificate, _routing_context
- **PASS 0-8**: Multi-Pass architektura z early abort (PASS 0,1,2,3)
- **safe_merge**: niemutowalne werdykty, allowlist, priority conflicts
- **Provenance**: _provenance_tree z decision_hash i wersjami
- **Decision Certificate**: certainty class, seal, guard

## 2. PASS 0-8 Multi-Pass Architecture

| PASS | Nazwa | Pakiety | Early Abort | Opis |
|------|-------|---------|-------------|------|
| 0 | RISK | 1 | BLOCK_AND_ALERT | fraud/GKS/GAAR |
| 1 | ROUTING | 1 | BLOCK_AND_ALERT | field confidence |
| 2 | COMPLIANCE | 8 | BLOCK_AND_ALERT | Biała Lista/MPP/KSeF |
| 3 | CROSSBORDER | 5 | BLOCK_AND_ALERT | WNT/WDT/import |
| 4 | VAT | 3 | — | stawki + GTU + deductions |
| 5 | PIT | 8 | — | forma + KUP + zaliczki |
| 6 | ALLOWANCES | 2 | — | ulgi podatkowe |
| 7 | ACCOUNTING | 7 | — | PKPiR + amortyzacja |
| 8 | ZUS+BUSINESS | 17 | — | ZUS + BUSINESS + MISC |

## 3. safe_merge (INV-018, INV-042)

```
safe_merge(a, b):
  CASE 1: a.immutable_verdict=true  → RETURN a
  CASE 2: b.immutable_verdict=true  → object.union(b, a)
  CASE 3: both non-immutable        → object.union(a, b)
```

**Immutable allowlist:** jdg.zus, jdg.zus.sickness_benefits, jdg.zus.health_contribution, jdg.business, jdg.security.fortress

## 4. Provenance Tree (A1, INV-030)

```json
{
  "path": [{"step": 1, "package": "...", "rule_id": "...", "priority": 100}],
  "root_hash": "sha256:...",
  "bundle_version": "...",
  "rule_version": "...",
  "threshold_version": "...",
  "decision_hash": "sha256:...",
  "evaluation_ms": 4.2,
  "verdict_summary": {"matched": true, "rule_id": "...", "routing": ""}
}
```

## 5. Decision Certificate (F4, INV-035)

| Klasa pewności | Guard | AUTO_POST |
|---------------|-------|-----------|
| CERTAIN | AUTO_POST_ALLOWED | TAK |
| CONDITIONAL | MANUAL_REVIEW | NIE |
| NEEDS_ADVICE | CERTAINTY_BLOCKED | NIE (nigdy) |

## 6. Invariants

| ID | Opis | Severity |
|----|------|----------|
| INV-018 | safe_merge left wins, immutable packages protected | BLOCK |
| INV-020 | routing_context attached BEFORE enforce() | BLOCK |
| INV-030 | versions in provenance tree | BLOCK |
| INV-035 | NEEDS_ADVICE → no AUTO_POST | BLOCK |
| INV-036 | evaluation_date in routing context | BLOCK |
| INV-042 | safe_merge integrity, allowlist enforced | BLOCK |

## 7. Użycie

```bash
# Build bundle + report
python JDG/tools/orchestrator_data_contract.py build

# Validate only
python JDG/tools/orchestrator_data_contract.py validate

# JSON output
python JDG/tools/orchestrator_data_contract.py build --json

# Tests
pytest -q JDG/tests/test_orchestrator_data_contract.py
```
