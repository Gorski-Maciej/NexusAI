# RB-06 — Regresja benchmarku (SLO-06, max +10% p95)

## Alarm
`benchmark_regression_pct > 10` (I12 BLOCK) lub brak baseline.

## Kroki
1. `python3 tools/v3_p37_benchmark_gate.py` — najnowszy pomiar vs `.benchmarks/eval_baseline.json`.
2. Regresja > 10% → deploy wstrzymany; diff reguł od ostatniego baseline (git).
3. Naprawa (indeks, else-chain) lub jawne podniesienie baseline z 4-eyes (decyzja właściciela SLO).
4. Zaktualizuj `.benchmarks/eval_baseline.json` + zapis w Migration Ledger (P36-K2).

## Rollback
Baseline tylko do przodu z 4-eyes; deploy wraca po naprawie lub zgodzie właściciela.

## Powiązania
SLO-06 w katalogu SLO; reguła I12 (437012); kontrakt P36-K1; CI P39.
