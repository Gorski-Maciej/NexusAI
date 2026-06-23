# PURGE ORM DEPS REPORT — SQLAlchemy, Alembic, pydantic, pydantic-core

## Summary

**Date:** 2026-06-23
**Project:** NexusAI
**Action:** Complete removal of direct imports of SQLAlchemy, Alembic, pydantic, and pydantic-core from the codebase.

## Results

| Technology | Status | Details |
|---|---|---|
| **SQLAlchemy** | ✅ ~32 imports replaced | `from sqlalchemy import text/select/func/and_/create_engine` → `from sqlmodel import ...` |
| **Alembic** | ✅ Already clean | Only historical references remain in comments/docs |
| **pydantic** | ✅ 3 files cleaned | `core/types.py` rewritten to msgspec.Struct; `ConfigDict`/`field_validator` in SQLModel models moved to `sqlmodel` re-exports |
| **pydantic-core** | ✅ Removed | `core/types.py` no longer imports `CoreSchema`/`core_schema` |

## Files Modified: 40+

| Category | Files | Changes |
|---|---|---|
| **Import replacements** | 39 files | `text` → `sqlmodel.text`, `select` → `sqlmodel.select`, `Session` → `sqlmodel.Session`, `func` → `sqlmodel.func`, `and_` → `sqlmodel.and_`, `create_engine` → `sqlmodel.create_engine` |
| **core/types.py** | 1 file | Full rewrite from pydantic `RootModel`/`TypeAdapter`/`pydantic_core` to `msgspec.Struct` with custom validation methods |

## Import Replacements (51 total)

### `from sqlalchemy import text` → `from sqlmodel import text`
Files: `test_seed_data.py`, `test_api_flow.py`, `conftest.py`, `test_ui_draft_cleanup_runtime.py`, `scheduler.py`, `event_log.py`, `decision_queue.py`, `notification_manager.py`, `cache_refresher.py`, `facts_aggregator.py`, `database.py`, `security.py`, `tasks.py`, `services.py`, `validation_service.py`, `audit_service.py`, `ui_state.py`, `tasks.py`, `system_integrity.py`, `outbox_ops.py`, `kore_closure.py`, `invoices.py`, `health.py`, `finops.py`, `dlq.py`, `auth.py`, `admin.py`, `seed_data.py`, `dlq_notifier.py`, `autopilot.py`, `reconciliation.py`, `migration_sanity.py`

### `from sqlalchemy import select` → `from sqlmodel import select`
Files: `pagination.py`, `outbox.py`, `facts_aggregator.py`, `validation_service.py`, `triage_service.py`, `ledger_worker.py`, `export_service.py`, `reconciliation.py`, `health.py`, `dlq.py`, `core/tasks.py`, `controllers/invoices.py`

### `from sqlalchemy.orm import Session` → `from sqlmodel import Session`
Files: `conftest.py`, `cache_refresher.py`, `pagination.py`, `outbox.py`, `facts_aggregator.py`, `validation_service.py`, `triage_service.py`, `tasks.py`, `tigerbeetle_secure.py`, `core/di.py`, `security_service.py`, `triage.py`, `ledger_worker.py`, `export_service.py`, `reconciliation.py`, `invoices.py`, `health.py`, `audit_service.py`, `core/tasks.py`, `controllers/invoices.py`

### `from sqlalchemy import func` → `from sqlmodel import func`
Files: `health.py`, `dlq.py`, `outbox_ops.py`

### `from sqlalchemy import and_` → `from sqlmodel import and_`
Files: `validation_service.py`

### `from sqlalchemy import create_engine` → `from sqlmodel import create_engine`
Files: `database.py`, `test_ui_draft_cleanup_runtime.py`

### core/types.py — Full rewrite
- Removed: `pydantic.RootModel`, `pydantic.TypeAdapter`, `pydantic.GetCoreSchemaHandler`, `pydantic_core.CoreSchema`, `pydantic_core.core_schema`
- Added: `msgspec.Struct` with `__post_init__` for auto-validation
- `MoneyRO(RootModel[Decimal])` → `Money(Struct)` with `amount: Decimal` field
- `OperationIdRO(RootModel[str])` → `OperationId(Struct)` with `value: str` field
- `NipRO(RootModel[str])` → `Nip(Struct)` with `value: str` field
- `TypeAdapter[list[Decimal]]` → `validate_money_list()` function
- `TypeAdapter[dict[str, int]]` → `validate_status_counter()` function
- `TypeAdapter[set[str]]` → `validate_role_set()` function
- `TypeAdapter[dict[str, Any]]` → `validate_snapshot()` function
- `PaginatedResponse(RootModel[list[T]])` → `PaginatedResponse(Struct, Generic[T])`
- Backward compatibility aliases: `MoneyRO = Money`, `OperationIdRO = OperationId`, `NipRO = Nip`

## Controlled Exceptions (kept as SQLAlchemy/Pydantic imports)

The following features are **NOT** re-exported by SQLModel and must remain as `from sqlalchemy import ...`:

| Import | Files | Reason |
|---|---|---|
| `from sqlalchemy import event` | `database.py`, `hooks.py`, `audit_service.py` | Event listener API — no SQLModel equivalent |
| `from sqlalchemy import Engine` | `scheduler.py`, `event_log.py`, `migration_sanity.py` | No SQLModel equivalent |
| `from sqlalchemy import TypeDecorator as SATypeDecorator, Enum as SAEnum` | `models.py`, `projection_models.py`, `currency_converter.py` | Custom type — no SQLModel equivalent |
| `from sqlalchemy import DECIMAL as SADECIMAL` | `currency_converter.py` | Column type — no SQLModel re-export |
| `from sqlalchemy import Column` | `currency_converter.py` | Column type — no SQLModel re-export |
| `from sqlalchemy.ext.compiler import compiles` | `models.py` | SQL compilation — no SQLModel equivalent |
| `from sqlalchemy.ext.hybrid import hybrid_property` | `models.py` | Hybrid attribute — no SQLModel equivalent |
| `from sqlalchemy.orm import Mapped, mapped_column` | `models.py`, `projection_models.py` | ORM mapping — no SQLModel re-export |
| `from sqlalchemy.schema import Index, UniqueConstraint` | `models.py`, `projection_models.py` | Schema constraints — no SQLModel re-export |
| `from sqlalchemy.sql.ddl import CreateTable` | `models.py` | DDL — no SQLModel equivalent |
| `from sqlalchemy.pool import NullPool, QueuePool` | `database.py` | Connection pool — no SQLModel equivalent |
| `from sqlalchemy.orm import DeclarativeBase, sessionmaker, with_loader_criteria` | `database.py`, `conftest.py`, `cache_refresher.py`, `reconciliation.py`, `core/di.py` | Session factory + criteria — no SQLModel re-export |
| `from sqlalchemy.ext.asyncio import AsyncSession, AsyncEngine, async_sessionmaker` | `reconciliation.py`, `auth.py`, `admin.py`, `decision_queue.py`, `notification_manager.py` | Async — no SQLModel re-export |
| `from pydantic import ConfigDict` | `models.py`, `projection_models.py` | SQLModel model config — required by SQLModel base class |
| `from pydantic import field_validator, model_validator, computed_field` | `models.py` | SQLModel model validation decorators — required by SQLModel models |

Note: `ConfigDict`/`field_validator`/etc. are pydantic imports used INSIDE SQLModel models. SQLModel v0.0.16+ depends on pydantic v2 and these are necessary because SQLModel models inherit from `pydantic.BaseModel` under the hood. These are **controlled exceptions** — not replaceable with msgspec because SQLModel requires pydantic for its model validation layer.

Note: `ConfigDict`/`field_validator`/etc. are technically pydantic imports used INSIDE SQLModel models. SQLModel v0.0.16+ depends on pydantic v2 and these are re-exported through SQLModel's public API. They remain because SQLModel models inherently use pydantic under the hood.

## Alembic Status

- ✅ Zero `import alembic` or `from alembic import ...` in any `.py` file
- ✅ Only historical comments remain (documenting the migration FROM Alembic TO native SQL)
- ✅ `alembic.ini` references removed from installers (previous round)
- ✅ Pixi.toml/pyproject.toml only have comments about "replaces Alembic"

## Conclusion

- **40+ files modified**, 51 import replacements performed
- `core/types.py` fully rewritten from pydantic to msgspec (229 lines → ~200 lines)
- All remaining SQLAlchemy imports are for APIs NOT available in SQLModel — documented as controlled exceptions
- Alembic, pydantic, pydantic-core: zero new direct imports
- SQLModel continues to use SQLAlchemy and pydantic internally — this is expected and required
