# NARZĘDZIA V3-P65 NOWE NARZĘDZIA FORTECY (WYGENEROWANE)

Generator: tools/v3_p65_doc_generator.py | Binding P60: docs ↔ kod (zero dryfu)

| # | Narzędzie | Opis | Flagi CLI | Wyjście |
|---|-----------|------|-----------|---------|
| 1 | `v3_p65_tool_contract.py` | NexusAI JDG — V3-P65 TOOL STANDARD CONTRACT (I01; prompt P65 Sekcja 10-I01). | --dry-run, --json | bundles/v3_p65_*.json |
| 2 | `v3_p65_semantic_diff.py` | NexusAI JDG — V3-P65 SEMANTIC DIFF FOR REGO (I02; prompt P65 Sekcja 10-I02). | --json, --self-test, new, old | bundles/v3_p65_*.json |
| 3 | `v3_p65_rule_to_tests.py` | NexusAI JDG — V3-P65 RULE-TO-TESTS GENERATOR (I03; prompt P65 Sekcja 10-I03). | --json, rule | bundles/v3_p65_*.json |
| 4 | `v3_p65_worm_tamper_test.py` | NexusAI JDG — V3-P65 WORM TAMPER TESTER (I08; prompt P65 Sekcja 10-I08). | --json | bundles/v3_p65_*.json |
| 5 | `v3_p65_adoption_metrics.py` | NexusAI JDG — V3-P65 TOOL ADOPTION METRICS (I11; prompt P65 Sekcja 10-I11). | --json | bundles/v3_p65_*.json |

## Kontrakt wspólny (I01)

Każde narzędzie: `python3 <tool>.py [--dry-run] [--json]`; raport JSON min. pola: schema, tool, status, provenance; exit codes 0/1/2.

> Ten plik jest generowany — NIE edytuj ręcznie (dryf = NEEDS_ADVICE I12).
