# RB-03 — Rozjazd z Golden Oracle (SLO-03, target 0 dryfu)

## Alarm
`golden_drift_count > 0` (I08 BLOCK z diffem inputów).

## Kroki
1. Pobierz diff inputów z watcha (tools/v3_p37_golden_drift_watch.py).
2. Oceń: dryf zamierzony (zmiana prawa) vs nieoczekiwany (błąd reguły/danych).
3. Zamierzony → aktualizacja golden cases (P35-I03) z 4-eyes.
4. Nieoczekiwany → rollback reguły (P07 lifecycle ROLLED_BACK) + replay P10.

## Rollback
`rule_lifecycle_manager.py rollback <rule_id>`; replay sezonowy P32-I07 potwierdza.

## Powiązania
SLO-03 w katalogu SLO; reguła I08 (437008); Golden Oracle P10.
