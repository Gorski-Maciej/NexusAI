# 📋 MANIFEST 2.0 — JEDNO ŹRÓDŁO PRAWDY METRYK JDG (P01 Fundament)

> Wygenerowano: 2026-08-17T12:31:49.484505+00:00 · generator: `manifest_v2.py`
> **Zasada:** manifest jest regenerowany w CI ze skanu katalogów; każda rozbieżność
> między dokumentami a tym plikiem = blokada merge (bramka `--check`).

## Metryki autorytatywne (stan faktyczny)

| Metryka | Wartość | SLO |
|---|---|---|
| Pliki Rego (rules/) | 449 | — |
| Bloki reguł | 13033 | — |
| Bloki matched=true | 12134 | — |
| Unikalne rule_id | 12182 | — |
| Duplikaty rule_id | 235 | **0** |
| Stuby { true } | 1028 | **0** |
| Narzędzia Python (tools/) | 223 | — |
| Natywne testy Rego | 109 | ≥ 95% pakietów |
| Pliki testów pytest | 36 | — |
| Completeness Score | 50/100 | → 100 |

## Rozstrzygnięcie luk dokumentacyjnych (L2)

| Metryka | README.md | MANIFEST.md | COVERAGE_REPORT.md | STAN FAKTYCZNY (2.0) |
|---|---|---|---|---|
| Pliki Rego | 439 | 383 | 176 | **449** |
| rule_id | 11452 | 10878 | 10827 | **12182** (unikalne) |
| Narzędzia | 57 | 98 | 130 | **223** |

## SLO docelowe (V1 §0 / V2 §11)

| Metryka | Cel |
|---|---|
| Duplikaty / stuby | 0 (blokada CI) |
| LCI (pokrycie prawa) | ≥ 99% |
| TCL (ciągłość czasowa prawa) | 100% |
| RV (reguła–prawo weryfikacja) | 100% |
| UVR (nieuzasadnione zmiany werdyktów) | 0 |
| Hardcoded wartości w regułach (ADR-002) | 0 |

## Semantyka parsera (ważne — nie „poprawiać” liczb)

- Liczniki pochodzą z `manifest_v2.py` (scan katalogów w CI) i mogą
  różnić się od starszych deklaracji (README/MANIFEST.md): parser liczy
  WSZYSTKIE bloki `:= {` z metadanymi rule_id (w tym duplikaty i bloki
  `else`), a nie tylko bloki `matched: true` jak generate_manifest.py.
- Rozbieżność dokumentów ze stanem faktycznym = BLOKADA CI (bramka
  `--check`), a nie alert — to zamierzone działanie MANIFEST 2.0.
- Właściwy proces: `python manifest_v2.py` → zaktualizuj dokumenty
  źródłowe do liczb z manifestu → bramka zielona.

*Zgodny z: ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md (V1), WIZJA_OPA_ENTERPRISE_V2.md (V2 §8), UNIFIED_PLAN.md.*
