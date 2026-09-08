# RB-01 — Dostępność silnika (SLO-01, target 99.5%/30d)

## Alarm
`engine_eval_success_ratio < 0.995` w oknie 30 dni.

## Kroki
1. Sprawdź `bundles/metrics.json` (health_score) i ostatnie wdrożenia (`bundles/deployments.json`).
2. Jeśli spadek po wdrożeniu → rollback bundle do ostatniej wersji z
   `bundles/healthy_versions.json` (procedura P38).
3. Jeśli błąd danych wejściowych → tryb fail-closed utrzymuje NEEDS_ADVICE;
   zweryfikuj invarianty P04 (`_invariant_report` w werdykcie).
4. Odbuduj error budget; wyczerpany budżet = freeze wdrożeń (I06, CI odmawia merge).

## Rollback
`rule_lifecycle_manager.py rollback <rule_id>` + wpis w Migration Ledger (P36-K2).

## Powiązania
SLO-01 w `bundles/v3_p37_slo_catalog.json`; reguła I01 (437001); freeze I06.
