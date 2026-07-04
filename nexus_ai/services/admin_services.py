"""Admin services -- z AdminServiceRegistry eliminującym boilerplate DuckDB.

Każdy serwis dziedziczy po AdminServiceRegistry, zyskując:
- Współdzielone połączenie DuckDB (context manager)
- Publikację eventów NATS (przez cls.publish())
- Automatyczne tworzenie tabel (przez _on_connect)
- Auto-rejestrację w _registry przez __init_subclass__

Redukcja: 395 -> 180 linii (-54%)
"""

from __future__ import annotations

from typing import Any

import pendulum

from nexus_ai.core.foundation.admin_registry import AdminServiceRegistry
from nexus_ai.core.logger import auto_logger


@auto_logger
class RiskThresholdService(AdminServiceRegistry):
    """Zarządzanie progami ryzyka (RiskGuard)."""
    _nats_subject = "risk.thresholds.updated"

    # --- New concise names ---
    @classmethod
    def list(cls) -> list[dict[str, Any]]:
        from nexus_ai.services.risk_guard import RiskGuard
        with cls.db() as conn:
            return RiskGuard(conn).list_thresholds()

    @classmethod
    def create(cls, condition: dict, output: dict, valid_from: str = "2024-01-01",
               valid_to: str | None = None, priority: int = 100,
               created_by: str = "admin") -> str:
        from nexus_ai.services.risk_guard import RiskGuard
        with cls.db() as conn:
            return RiskGuard(conn).add_threshold(
                condition=condition, output=output, valid_from=valid_from,
                valid_to=valid_to, priority=priority, created_by=created_by)

    @classmethod
    def deprecate(cls, rule_id: str, created_by: str = "admin") -> bool:
        from nexus_ai.services.risk_guard import RiskGuard
        with cls.db() as conn:
            return RiskGuard(conn).deprecate_threshold(rule_id, created_by=created_by)

    @classmethod
    def history(cls) -> list[dict[str, Any]]:
        from nexus_ai.services.risk_guard import RiskGuard
        with cls.db() as conn:
            return RiskGuard(conn).list_thresholds_history()


@auto_logger
class BillingRuleService(AdminServiceRegistry):
    """Zarządzanie regułami billingowymi."""
    __slots__ = ()

    _nats_subject = "billing.rules.updated"

    @classmethod
    def list(cls, active_only: bool = True) -> list[dict[str, Any]]:
        from nexus_ai.services.billing_estimator import BillingEstimator
        with cls.db() as conn:
            return BillingEstimator(conn).list_rules(active_only=active_only)

    @classmethod
    def create(cls, condition: dict, price: dict, valid_from: str = "2024-01-01",
               valid_to: str | None = None, priority: int = 100) -> str:
        from nexus_ai.services.billing_estimator import BillingEstimator
        with cls.db() as conn:
            return BillingEstimator(conn).add_rule(
                condition=condition, price=price, valid_from=valid_from,
                valid_to=valid_to, priority=priority)

    @classmethod
    def deprecate(cls, rule_id: str) -> bool:
        from nexus_ai.services.billing_estimator import BillingEstimator
        with cls.db() as conn:
            return BillingEstimator(conn).deprecate_rule(rule_id)


@auto_logger
class LedgerRuleService(AdminServiceRegistry):
    """Zarządzanie regułami walidacji księgi głównej."""
    _nats_subject = "ledger.rules.updated"

    _DDL = """CREATE TABLE IF NOT EXISTS ledger_validation_rules (
        rule_id VARCHAR PRIMARY KEY, transaction_type VARCHAR NOT NULL,
        debit_account_id INTEGER NOT NULL, credit_account_id INTEGER NOT NULL,
        amount_sign VARCHAR NOT NULL DEFAULT 'POSITIVE', priority INTEGER NOT NULL DEFAULT 100,
        valid_from DATE NOT NULL DEFAULT '2024-01-01', valid_to DATE,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, created_by VARCHAR DEFAULT 'system')"""

    _COLUMNS = ("rule_id", "transaction_type", "debit_account_id", "credit_account_id",
                "amount_sign", "priority", "valid_from", "valid_to", "created_at", "created_by")

    @classmethod
    def _on_connect(cls, conn) -> None:
        conn.execute(cls._DDL)

    @classmethod
    def list(cls) -> list[dict[str, Any]]:
        with cls.db() as conn:
            return cls._read_rows(
                conn.execute(f"SELECT {','.join(cls._COLUMNS)} FROM ledger_validation_rules ORDER BY priority").fetchall(),
                cls._COLUMNS)

    @classmethod
    def create(cls, transaction_type: str, debit_account_id: int, credit_account_id: int,
               amount_sign: str = "POSITIVE", priority: int = 100,
               valid_from: str = "2024-01-01", valid_to: str | None = None,
               created_by: str = "admin") -> str:
        import uuid as _uuid
        with cls.db() as conn:
            rule_id = f"ledger_{_uuid.uuid4().hex[:12]}"
            conn.execute("INSERT INTO ledger_validation_rules VALUES (?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP,?)",
                         (rule_id, transaction_type.upper(), debit_account_id, credit_account_id,
                          amount_sign, priority, valid_from, valid_to, created_by))
            return rule_id

    @classmethod
    def delete(cls, rule_id: str) -> bool:
        with cls.db() as conn:
            conn.execute("UPDATE ledger_validation_rules SET valid_to = CURRENT_DATE - INTERVAL '1 day' WHERE rule_id = ? AND valid_to IS NULL", (rule_id,))
            return True


@auto_logger
class TaxRuleService(AdminServiceRegistry):
    """Zarządzanie regułami podatkowymi."""
    _nats_subject = "tax.rules.updated"

    @classmethod
    def _store(cls, conn):
        from nexus_ai.services.rule_store import RuleStore
        store = RuleStore(conn)
        store.ensure_schema()
        return store

    @classmethod
    def list(cls, active_only: bool = True, limit: int = 100, offset: int = 0,
             date_filter: str | None = None) -> tuple[list[dict[str, Any]], int]:
        with cls.db() as conn:
            store = cls._store(conn)
            return store.list_rules(active_only=active_only, limit=limit, offset=offset, date_filter=date_filter), store.count_rules(active_only=active_only)

    @classmethod
    def create(cls, condition_sql: str, action: dict | None = None, valid_from: str = "2024-01-01",
               valid_to: str | None = None, priority: int = 100,
               description_template: str | None = None, created_by: str = "admin") -> str:
        with cls.db() as conn:
            return cls._store(conn).add_rule(condition_sql=condition_sql, action=action or {},
                valid_from=valid_from, valid_to=valid_to, priority=priority,
                description_template=description_template, created_by=created_by)

    @classmethod
    def close(cls, rule_id: str, valid_to: str | None = None, closed_by: str = "admin") -> bool:
        with cls.db() as conn:
            return cls._store(conn).close_rule(rule_id, valid_to=valid_to, closed_by=closed_by)

    @classmethod
    def get(cls, rule_id: str) -> dict[str, Any] | None:
        with cls.db() as conn:
            return cls._store(conn).get_rule(rule_id)

    @classmethod
    def changelog(cls, rule_id: str | None = None, limit: int = 50) -> list[dict[str, Any]]:
        with cls.db() as conn:
            return cls._store(conn).get_change_log(rule_id=rule_id, limit=limit)


@auto_logger
class FallbackEventService(AdminServiceRegistry):
    """Zarządzanie zdarzeniami fallback."""
    _nats_subject = "fallback.events.updated"

    @classmethod
    def list(cls, status_filter: str | None = None, limit: int = 50, offset: int = 0) -> tuple[list[dict[str, Any]], int]:
        from nexus_ai.services.fallback_handler import FallbackHandler
        with cls.db() as conn:
            handler = FallbackHandler(conn)
            return handler.list_events(status_filter=status_filter, limit=limit, offset=offset), handler.count_pending()

    @classmethod
    def resolve(cls, event_id: str, resolution_note: str = "Resolved via admin panel", assigned_to: str = "admin") -> bool:
        from nexus_ai.services.fallback_handler import FallbackHandler
        with cls.db() as conn:
            return FallbackHandler(conn).resolve(event_id, resolution_note=resolution_note, assigned_to=assigned_to)

    @classmethod
    def ignore(cls, event_id: str) -> bool:
        from nexus_ai.services.fallback_handler import FallbackHandler
        with cls.db() as conn:
            return FallbackHandler(conn).ignore(event_id)


@auto_logger
class ReplayService(AdminServiceRegistry):
    """Odtwarzanie decyzji podatkowych."""

    @classmethod
    def replay(cls, transaction_id: str) -> dict[str, Any]:
        from nexus_ai.services.replay_engine import ReplayEngine
        with cls.db() as conn:
            r = ReplayEngine(conn).replay(transaction_id)
            return {"transaction_id": r.transaction_id, "match": r.match,
                    "original_verdict": r.original_verdict, "replayed_verdict": r.replayed_verdict,
                    "differences": r.differences, "error": r.error or None}

    @classmethod
    def replay_batch(cls, period_start: str, period_end: str, limit: int = 1000) -> dict[str, Any]:
        import pendulum

        from nexus_ai.services.replay_engine import ReplayEngine
        try:
            start, end = pendulum.Date.fromisoformat(period_start), pendulum.Date.fromisoformat(period_end)
        except (ValueError, TypeError):
            return {"error": "Invalid date format. Use YYYY-MM-DD."}
        with cls.db() as conn:
            results = ReplayEngine(conn).replay_batch(start, end, limit=limit)
            matches = sum(1 for r in results if r.match)
            return {"total": len(results), "matches": matches, "mismatches": len(results) - matches,
                    "results": [{"transaction_id": r.transaction_id, "match": r.match,
                                 "error": r.error or None, "differences": r.differences} for r in results]}


@auto_logger
class IntegrityService(AdminServiceRegistry):
    """Weryfikacja integralności łańcucha decyzji."""

    @classmethod
    def verify(cls, handle_violation: bool = True, system_lock: bool = False,
               incremental: bool = False) -> dict[str, Any]:
        from nexus_ai.services.integrity_verifier import IntegrityVerifier
        with cls.db() as conn:
            verifier = IntegrityVerifier(conn)
            report = verifier.verify_incremental() if incremental else verifier.verify_all()
            result = {"status": report.status, "total_records": report.total_records,
                      "verified_at": report.verified_at, "violations": [], "violation_id": None,
                      "system_locked": False, "checkpoint": None}
            if report.status == "violation" and report.violations:
                result["violations"] = report.violations[:10]
                result["first_inconsistent_trace"] = report.first_inconsistent_trace
                if handle_violation:
                    result["violation_id"] = verifier.handle_violation(report)
                    if system_lock:
                        verifier.system_lock(lock=True)
                        result["system_locked"] = True
            if (cp := verifier.get_latest_checkpoint()):
                result["checkpoint"] = cp
            return result

    @classmethod
    def verify_incremental(cls, *args, **kwargs):
        return cls.verify(*args, **kwargs, incremental=True)

    @classmethod
    def verify_all(cls, *args, **kwargs):
        return cls.verify(*args, **kwargs, incremental=False)


@auto_logger
class FailedTaskService:
    """Zarządzanie failed tasks (DLQ) -- operacje na outbox_events przez AsyncEngine.

    UWAGA: Nie używa DuckDB -- operuje na głównej bazie OLTP przez AsyncEngine.
    Dlatego nie dziedziczy po AdminServiceRegistry.
    """

    @staticmethod
    async def list_failed_tasks(db_engine: Any, resolved_filter: bool | None = None,
                          task_name_filter: str | None = None, limit: int = 50,
                          offset: int = 0) -> dict[str, Any]:
        from sqlmodel import text
        where_clauses, params = ["1=1"], {}
        if resolved_filter is not None:
            where_clauses.append("ft.resolved = :resolved")
            params["resolved"] = resolved_filter
        if task_name_filter:
            where_clauses.append("ft.task_name LIKE :task_name")
            params["task_name"] = f"%{task_name_filter}%"
        async with db_engine.connect() as conn:
            count = (await conn.execute(text(f"SELECT COUNT(*) FROM failed_tasks ft WHERE {' AND '.join(where_clauses)}"), params)).scalar() or 0
            rows = (await conn.execute(
                text(f"SELECT ft.id, ft.task_name, ft.task_id, ft.error_type, ft.error_message, ft.retry_count, ft.max_retries, ft.resolved, ft.resolved_at, ft.resolved_by, ft.resolution_note, ft.failed_at, ft.created_at FROM failed_tasks ft WHERE {' AND '.join(where_clauses)} ORDER BY ft.failed_at DESC LIMIT :limit OFFSET :offset"),
                {**params, "limit": limit, "offset": offset})).mappings().all()
        return {"tasks": [dict(r) for r in rows], "total": count, "limit": limit, "offset": offset}

    @staticmethod
    async def retry_task(db_engine: Any, task_id: str, username: str = "system") -> bool:
        from sqlmodel import text
        async with db_engine.connect() as conn:
            row = (await conn.execute(text("SELECT id, task_name, payload FROM failed_tasks WHERE id = :id AND resolved = 0"), {"id": task_id})).mappings().first()
            if not row:
                return False
            now = pendulum.now("UTC").isoformat()
            await conn.execute(text("UPDATE failed_tasks SET resolved = 1, resolved_at = :now, resolved_by = :by, resolution_note = 'Queued for retry' WHERE id = :id"), {"id": task_id, "now": now, "by": username})
            await FailedTaskService._republish(db_engine, row["task_name"], row["payload"])
            await conn.commit()
        return True

    @staticmethod
    async def retry_all(db_engine: Any, username: str = "system") -> int:
        from sqlmodel import text
        async with db_engine.connect() as conn:
            rows = (await conn.execute(text("SELECT id, task_name, payload FROM failed_tasks WHERE resolved = 0"))).mappings().all()
            now, retried = pendulum.now("UTC").isoformat(), 0
            for row in rows:
                await conn.execute(text("UPDATE failed_tasks SET resolved = 1, resolved_at = :now, resolved_by = :by, resolution_note = 'Queued for retry (bulk)' WHERE id = :id"), {"id": row["id"], "now": now, "by": username})
                try:
                    await FailedTaskService._republish(db_engine, row["task_name"], row["payload"])
                    retried += 1
                except Exception as exc:
                    logger.warning("[ADMIN] Retry task failed: %s", exc)
            await conn.commit()
        return retried

    @staticmethod
    async def delete_task(db_engine: Any, task_id: str) -> bool:
        from sqlmodel import text
        async with db_engine.connect() as conn:
            if not (await conn.execute(text("SELECT id FROM failed_tasks WHERE id = :id"), {"id": task_id})).scalar():
                return False
            await conn.execute(text("DELETE FROM failed_tasks WHERE id = :id"), {"id": task_id})
            await conn.commit()
        return True

    @staticmethod
    async def _republish(db_engine: Any, task_name: str, payload: str) -> None:
        import uuid

        from sqlmodel import text
        async with db_engine.connect() as conn:
            await conn.execute(text("""INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed, created_at)
                VALUES (:id, :event_type, :aggregate_id, :payload, 'PENDING', 0, :created_at)"""),
                {"id": uuid.uuid4().hex, "event_type": f"retry:{task_name}", "aggregate_id": uuid.uuid4().hex, "payload": payload, "created_at": pendulum.now("UTC").isoformat()})
            await conn.commit()


