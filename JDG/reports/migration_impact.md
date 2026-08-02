# 🗄️ Migration Impact Analysis — NexusAI JDG v8.0

> **Wygenerowano:** 2026-08-02 08:49:05 | **Innowacja 7**
> **Migracji:** 2 | **Tabel:** 9 | **Reguł dotkniętych:** 0

## Analiza per migracja

### `001_jdg_rule_store.sql` (23124 B)

| Tabela | Reguły dotknięte | Przykładowe rule_id | Endpointy API |
|--------|:----------------:|---------------------|---------------|
| `jdg_tax_thresholds` | 0 | — | — |
| `rule_versions` | 0 | — | — |
| `jdg_verdict_audit` | 0 | — | — |
| `isap_history` | 0 | — | — |
| `jdg_legal_cartography` | 0 | — | — |

### `002_jdg_enterprise_v7.sql` (4585 B)

| Tabela | Reguły dotknięte | Przykładowe rule_id | Endpointy API |
|--------|:----------------:|---------------------|---------------|
| `jdg_prediction_history` | 0 | — | — |
| `jdg_stale_rules_registry` | 0 | — | — |
| `jdg_conflict_registry` | 0 | — | — |
| `jdg_explanation_cache` | 0 | — | — |

---
*Wygenerowano — 2026-08-02 08:49:05*
*Innowacja 7 — `python JDG/tools/migration_impact_analyzer.py`*