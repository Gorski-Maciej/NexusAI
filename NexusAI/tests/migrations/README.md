# Migration safety checks

Migration sanity is now built into the native SQL migration system (`migrations/run_migrations.py`):

```bash
pixi run migrate              # Apply migrations
pixi run migrate-check        # Check current version
pixi run migrate-history      # Show migration history
pixi run migrate-dry          # Dry run
```

The migration runner validates:
- Row-count consistency (no regressions)
- Schema drift detection (table/column changes)
- Checksum verification of applied migrations
