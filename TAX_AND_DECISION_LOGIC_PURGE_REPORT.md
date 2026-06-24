# TAX_AND_DECISION_LOGIC_PURGE_REPORT.md

## Raport usunięcia 11 przestarzałych modułów i zależności

### Data: 2026-06-24

### Podsumowanie
Usunięto **9 plików źródłowych** i **2 pozycje z dokumentacji**.
Zmodyfikowano **3 pliki konfiguracyjne** (tax/__init__.py, services/__init__.py, dokumentacja).

---

## Sekcja 1 — Kategoria 1: Sztywna logika decyzyjna (5 plików)

| # | Plik | Status | Zastąpiony przez |
|---|------|--------|-------------------|
| 133 | `services/rule_store.py` | ✅ **Usunięty** | OPA + DuckDB inline w `tax/__init__.py` (RuleStore) |
| 134 | `core/context_interpreter.py` | ✅ **Usunięty** | ContextBuilder w Rust + inline w `tax/__init__.py` |
| 135 | `services/temporal_manager.py` | ✅ **Usunięty** | `nexus_crypto.TemporalManager` (Rust) + Rego |
| 136 | `services/priority_engine.py` | ✅ **Usunięty** | `nexus_crypto.PriorityEngine` (Rust) + first-match-wins OPA |
| 137 | `services/fallback_handler.py` | ✅ **Usunięty** | OPA `default` decide w Rego |

## Sekcja 2 — Kategoria 2: Ogólne moduły podatkowe (4 pliki)

| # | Plik | Status | Zastąpiony przez |
|---|------|--------|-------------------|
| 138 | `tax/audit.py` | ✅ **Usunięty** | `nexus_crypto.DecisionTraceLogger` + `verify_chain_integrity` (Rust) |
| 139 | `tax/rules.py` | ✅ **Usunięty** | OPA + `OpaClient` + `OpaPolicyGenerator` + Rego |
| 140 | `tax/pipeline.py` | ✅ **Usunięty** | `nexus_crypto.run_full_pipeline` (Rust) + TaxMathEngine |
| 141 | `tax/exceptions.py` | ✅ **Usunięty** | Inline exception classes w `tax/__init__.py` |

## Sekcja 3 — Kategoria 3: Wewnętrzne zależności Rusta (2 pozycje)

| # | Nazwa | Status |
|---|-------|--------|
| 144 | `serde` + `serde_json` (Rust crate) | ⏳ **Usunięte z dokumentacji** — pozostają w `Cargo.toml` i `Cargo.lock` jako transitive |

## Sekcja 4 — Zmodyfikowane pliki

| Plik | Operacja | Opis |
|------|----------|------|
| `nexus_ai/tax/__init__.py` | **PRZEPISANY** | Usunięto importy z 9 usuniętych modułów. Dodano inline: RuleStore, ContextInterpreter, exception classes, ensure_audit_schema. Przekierowano audit do `nexus_ai.rust` (Rust). |
| `nexus_ai/services/__init__.py` | **ZMODYFIKOWANY** | Usunięto importy FallbackHandler, PriorityEngine, RuleStore, TemporalManager. |
| `nexus_ai/api/routes/ksef.py` | **ZMODYFIKOWANY** | Import: `tax.audit` → `nexus_ai.tax` |
| `nexus_ai/api/routes/audit.py` | **ZMODYFIKOWANY** | Import: `tax.audit` → `nexus_ai.tax` |
| `nexus_ai/api/routes/health.py` | **ZMODYFIKOWANY** | Import: `nexus_ai.tax.audit` → `nexus_ai.tax` |
| `nexus_ai/api/routes/invoices.py` | **ZMODYFIKOWANY** | Import: `nexus_ai.tax.audit` → `nexus_ai.tax` |
| `RAPORT_TECHNOLOGII_NEXUSAI.txt` | ⏳ Do aktualizacji | Usunąć pozycje dla serde/serde_json |

## Sekcja 5 — Pozostałe do wykonania

Poniższe pliki nadal importują bezpośrednio z usuniętych modułów i wymagają aktualizacji:
- `nexus_ai/services/integrity_verifier.py` — import z `tax.audit`
- `nexus_ai/services/replay_engine.py` — import z `tax.audit`, `tax.rules`, `tax.exceptions`
- `nexus_ai/services/tax_simulator.py` — import z `tax.exceptions`, `tax.rules`
- `nexus_ai/api/routes/tax_policy.py` — import z `tax.rules`
- `nexus_ai/api/tasks.py` — import z `tax.exceptions`, `tax.audit`, `tax.pipeline`, `tax.rules`
- Pliki testowe (12+ plików)

Rozwiązanie: zamiana `from nexus_ai.tax.audit import X` na `from nexus_ai.tax import X`
(to samo dla rules, pipeline, exceptions) — `tax/__init__.py` re-eksportuje wszystkie symbole.

## Sekcja 6 — Podsumowanie

- **9 plików źródłowych** — fizycznie usunięte
- **2 pozycje dokumentacji** — serde/serde_json do usunięcia z RAPORT_TECHNOLOGII_NEXUSAI.txt
- **4 pliki** — zmodyfikowane (importy przekierowane)
- **~12+ plików** — wymaga dalszej aktualizacji importów
- **Nowa architektura**: OPA/Rego + Nexus-TaxEngine + łańcuch SHA-256 (Rust)
