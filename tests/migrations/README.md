# Migration safety checks

Use both scripts after applying migrations on staging snapshots:

```bash
python Code/scripts/migration_sanity_check.py --before before.db --after after.db
python Code/scripts/schema_drift_check.py --expected before.db --actual after.db
```

- `migration_sanity_check.py` verifies row-count regressions.
- `schema_drift_check.py` verifies table/column drift.

## Model retention maintenance

```bash
python Code/scripts/model_retention_runner.py --root app_data/models --keep-last 3
```
