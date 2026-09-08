# RB-02 — Latencja p95 (SLO-02, target ≤ 500 ms / 7d)

## Alarm
`eval_latency_p95_ms > 500` lub domena > 2× budżetu (I04 BLOCK).

## Kroki
1. Uruchom benchmark: `python3 tools/v3_p37_benchmark_gate.py` — porównanie z baseline.
2. Zidentyfikuj domeny ponad budżet (rejestr I04): else-chain O(n) → routing O(1) (P02/K06).
3. Reguła-winowajca wpada do rejestru z analizą; poprawka przez transform_tool (P36-K1).
4. Jeśli regresja > 10% (SLO-06) → deploy zablokowany do naprawy.

## Rollback
Transformacja P36 z auto-rollback; baseline benchmarku tylko do przodu (4-eyes).

## Powiązania
SLO-02 w katalogu SLO; reguła I04 (437004); gate I12 (437012).
