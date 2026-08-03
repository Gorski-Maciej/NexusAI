# 📘 RULE LIFECYCLE MANAGEMENT — NexusAI JDG (P01 Fundament OPA, Sekcja 2)

> **Status:** ✅ WDROŻONY (P01 v9.0, 2026-08-02)
> **Pliki:** `JDG/rules/rule_lifecycle_enterprise.rego`, `JDG/rules/temporal.rego`,
> `JDG/tools/rule_lifecycle_manager.py`, `JDG/tools/isap_rule_update_pipeline.py`,
> `JDG/tools/decision_quality_monitor.py`, `JDG/rules/thresholds_jdg.rego`

## Cel

System zarządzania cyklem życia reguł — dodawanie / usuwanie / migracja reguł
**bez przerw w działaniu** (zero-downtime), z shadow-deployment, A/B rollout,
auto-rollback i pełną temporalnością (time-travel OPA, A2). Prawo zmienia się
szybko — silnik musi się adaptować natychmiast i bezbłędnie.

## Architektura

```
                          ┌─────────────────────────────┐
   ISAP / Dziennik Ustaw  │  isap_rule_update_pipeline  │  ingest → impact → plan
   (zmiana prawa)         └──────────────┬──────────────┘
                                         │ threshold_changelog.json
                                         ▼
                          ┌─────────────────────────────┐
   rule_lifecycle_manager │  bundles/rule_registry.json │  register / promote /
   (CLI, hot-reload)      └──────────────┬──────────────┘  rollback / check
                                         │ data.jdg.rule_registry (zero restart)
                                         ▼
                          ┌─────────────────────────────┐
                          │  OPA: jdg.rule_lifecycle    │  SHADOW → CANDIDATE → ACTIVE
                          │  temporal.rego (P1619-P1624)│  A/B bucket < rollout_pct
                          └──────────────┬──────────────┘  auto-rollback przy błędach
                                         │
                                         ▼
                          ┌─────────────────────────────┐
   decision_quality_monitor │  trust_feedback.json      │  KPI + adaptive thresholds
                            └─────────────────────────────┘
```

## Statusy wersji reguł

| Status        | Ewaluacja | Wpływ na decyzję | Kiedy |
|---------------|-----------|------------------|-------|
| `SHADOW`      | ✅ tak    | ❌ nie            | Walidacja nowej wersji na produkcji |
| `CANDIDATE`   | ✅ tak    | ⚠️ A/B (bucket < rollout_pct) | Testy kanarkowe |
| `ACTIVE`      | ✅ tak    | ✅ tak            | Wersja produkcyjna |
| `ROLLED_BACK` | ✅ tak    | ❌ nie            | Po auto-rollback (błąd) |

## Temporalność (time-travel OPA)

- **Pinning wersji**: `active_version(rule_id, eval_date)` wybiera wersję
  obowiązującą **w dacie ewaluacji** — zgodnie z Art. 3 Ordynacji podatkowej.
- **P1619 overlap detector**: wykrywa nakładające się okna ważności
  (overlapping validity) — wymagana korekta przed AUTO_POST.
- **P1620 version pin**: przypina wersję reguły na datę historyczną.
- **P1621 law change calendar**: kalendarz zmian prawa (proaktywne alerty).
- **P1622 shadow window / P1623 rollback window / P1624 gap detector**:
  okna shadow, rollback i luki czasowe między wersjami.

## Thresholds per okres rozliczeniowy (Sekcja 3)

`thresholds_jdg.rego` → `threshold_versions` + `get_threshold_for_period(key, period)`:

- `pit.scale_threshold`: 85 528 → 120 000 (Polski Ład 2022)
- `pit.tax_free_amount`: 8 000 → 30 000 (2022)
- `vat.bad_debt_days`: 150 → 90 (SLIM VAT 3, 2023-07-01)
- `zus.health_linear_deduction`: 8 700 → 14 100 (2026)
- `pit.lump_sum_annual_limit_eur`: 250k → 2M EUR (2022)

## Hot-reload (INN-02)

Zmiana `data.jdg.rule_registry` / `data.jdg.threshold_changelog` = natychmiastowy
efekt **bez restartu OPA i bez rekompilacji bundle**. Host wstrzykuje JSON
przez API/DB (migration 001 `rule_versions`).

## Komendy CLI

```bash
# Rejestracja nowej wersji w trybie kanarkowym (A/B 10%)
python JDG/tools/rule_lifecycle_manager.py register jdg.vat.a113.r1 \
    --version 2.0.0 --status CANDIDATE --rollout 10

# Awans do produkcji
python JDG/tools/rule_lifecycle_manager.py promote jdg.vat.a113.r1

# Auto-rollback przy error_rate > 5%
python JDG/tools/rule_lifecycle_manager.py rollback jdg.vat.a113.r1

# Weryfikacja konfliktów temporalnych (bramka CI)
python JDG/tools/rule_lifecycle_manager.py check

# ISAP: ingest zmiany prawa → impact → plan migracji
python JDG/tools/isap_rule_update_pipeline.py ingest --act "Ustawa o PIT" \
    --article "Art. 27" --effective 2027-01-01 --threshold pit.scale_threshold --value 150000

# Monitoring jakości decyzji + feedback do adaptive trust
python JDG/tools/decision_quality_monitor.py collect --file verdicts.jsonl
python JDG/tools/decision_quality_monitor.py feedback --correct 950 --incorrect 50
```
