"""Admin services — z BaseAdminService eliminującym boilerplate DuckDB.

Każdy serwis dziedziczy po BaseAdminService, zyskując:
- Współdzielone połączenie DuckDB (context manager)
- Publikację eventów NATS
- Automatyczne tworzenie tabel
"""

from __future__ import annotations

from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator

import duckdb
import pendulum

from nexus_ai.core.config import AppConfig
from nexus_ai.core.nats_utils import publish_event as _publish_nats_event


class BaseAdminService:
    """Base class for admin services — provides DuckDB connection + NATS publishing."""

    _conn: duckdb.DuckDBPyConnection | None = None

    @classmethod
    @contextmanager
    def _db(cls) -> Iterator[duckdb.DuckDBPyConnection]:
        """Context manager for DuckDB connection — auto-create and close."""
        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        try:
            cls._on_connect(conn)
            yield conn
        finally:
            conn.close()

    @classmethod
    def _on_connect(cls, conn: duckdb.DuckDBPyConnection) -> None:
        """Override to create tables on connect."""

    @staticmethod
    def _nats(subject: str, data: dict[str, Any]) -> None:
        """Publish NATS event (fire-and-forget)."""
        import anyio
        try:
            anyio.ensure_backend().create_task(
                _publish_nats_event(subject, data)
            )
        except RuntimeError:
            pass

    @staticmethod
    def _read_rows(rows: list[Any], columns: tuple[str, ...], key_overrides: dict[str, str] | None = None) -> list[dict[str, Any]]:
        """Convert DuckDB rows to list of dicts with column names."""
        return [
            {
                key_overrides.get(col, col): val
                for col, val in zip(columns, row)
            }
            for row in rows
        ]


class RiskThresholdAdminService(BaseAdminService):
    """Zarządzanie progami ryzyka (RiskGuard)."""

    @staticmethod
    def list_thresholds() -> list[dict[str, Any]]:
        from nexus_ai.services.risk_guard import RiskGuard
        with RiskThresholdAdminService._db() as conn:
            return RiskGuard(conn).list_thresholds()

    @staticmethod
    def create_threshold(
        condition: dict[str, Any], output: dict[str, Any],
        valid_from: str = "2024-01-01", valid_to: str | None = None,
        priority: int = 100, created_by: str = "admin",
    ) -> str:
        from nexus_ai.services.risk_guard import RiskGuard
        with RiskThresholdAdminService._db() as conn:
            return RiskGuard(conn).add_threshold(
                condition=condition, output=output, valid_from=valid_from,
                valid_to=valid_to, priority=priority, created_by=created_by,
            )

    @staticmethod
    def deprecate_threshold(rule_id: str, created_by: str = "admin") -> bool:
        from nexus_ai.services.risk_guard import RiskGuard
        with RiskThresholdAdminService._db() as conn:
            return RiskGuard(conn).deprecate_threshold(rule_id, created_by=created_by)

    @staticmethod
    def list_history() -> list[dict[str, Any]]:
        from nexus_ai.services.risk_guard import RiskGuard
        with RiskThresholdAdminService._db() as conn:
            return RiskGuard(conn).list_thresholds_history()

    @staticmethod
    def publish_event(rule_id: str, action: str) -> None:
        RiskThresholdAdminService._nats("risk.thresholds.updated", {"rule_id": rule_id, "action": action})


class BillingRuleAdminService(BaseAdminService):
    """Zarządzanie regułami billingowymi."""

    @staticmethod
    def list_rules(active_only: bool = True) -> list[dict[str, Any]]:
        from nexus_ai.services.billing_estimator import BillingEstimator
        with BillingRuleAdminService._db() as conn:
            return BillingEstimator(conn).list_rules(active_only=active_only)

    @staticmethod
    def create_rule(
        condition: dict[str, Any], price: dict[str, Any],
        valid_from: str = "2024-01-01", valid_to: str | None = None, priority: int = 100,
    ) -> str:
        from nexus_ai.services.billing_estimator import BillingEstimator
        with BillingRuleAdminService._db() as conn:
            return BillingEstimator(conn).add_rule(
                condition=condition, price=price, valid_from=valid_from,
                valid_to=valid_to, priority=priority,
            )

    @staticmethod
    def deprecate_rule(rule_id: str) -> bool:
        from nexus_ai.services.billing_estimator import BillingEstimator
        with BillingRuleAdminService._db() as conn:
            return BillingEstimator(conn).deprecate_rule(rule_id)

    @staticmethod
    def publish_event(rule_id: str, action: str) -> None:
        BillingRuleAdminService._nats("billing.rules.updated", {"rule_id": rule_id, "action": action})


class LedgerRuleAdminService(BaseAdminService):
    """Zarządzanie regułami walidacji księgi głównej."""

    _DDL = """
        CREATE TABLE IF NOT EXISTS ledger_validation_rules (
            rule_id            VARCHAR PRIMARY KEY,
            transaction_type   VARCHAR NOT NULL,
            debit_account_id   INTEGER NOT NULL,
            credit_account_id  INTEGER NOT NULL,
            amount_sign        VARCHAR NOT NULL DEFAULT 'POSITIVE',
            priority           INTEGER NOT NULL DEFAULT 100,
            valid_from         DATE NOT NULL DEFAULT '2024-01-01',
            valid_to           DATE,
            created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            created_by         VARCHAR DEFAULT 'system'
        )
    """

    _COLUMNS = ("rule_id", "transaction_type", "debit_account_id", "credit_account_id",
                "amount_sign", "priority", "valid_from", "valid_to", "created_at", "created_by")

    @classmethod
    def _on_connect(cls, conn: duckdb.DuckDBPyConnection) -> None:
        conn.execute(cls._DDL)

    @staticmethod
    def list_rules() -> list[dict[str, Any]]:
        with LedgerRuleAdminService._db() as conn:
            rows = conn.execute(
                "SELECT {} FROM ledger_validation_rules ORDER BY priority ASC, rule_id ASC".format(
                    ", ".join(LedgerRuleAdminService._COLUMNS)
                )
            ).fetchall()
            return LedgerRuleAdminService._read_rows(rows, LedgerRuleAdminService._COLUMNS)

    @staticmethod
    def create_rule(
        transaction_type: str, debit_account_id: int, credit_account_id: int,
        amount_sign: str = "POSITIVE", priority: int = 100,
        valid_from: str = "2024-01-01", valid_to: str | None = None, created_by: str = "admin",
    ) -> str:
        import uuid as _uuid
        with LedgerRuleAdminService._db() as conn:
            rule_id = f"ledger_{_uuid.uuid4().hex[:12]}"
            conn.execute(
                "INSERT INTO ledger_validation_rules VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)",
                (rule_id, transaction_type.upper(), debit_account_id, credit_account_id,
                 amount_sign, priority, valid_from, valid_to, created_by),
            )
        return rule_id

    @staticmethod
    def delete_rule(rule_id: str) -> bool:
        with LedgerRuleAdminService._db() as conn:
            conn.execute(
                "UPDATE ledger_validation_rules SET valid_to = CURRENT_DATE - INTERVAL '1 day' WHERE rule_id = ? AND valid_to IS NULL",
                (rule_id,),
            )
            return True

    @staticmethod
    def publish_event(rule_id: str, action: str) -> None:
        LedgerRuleAdminService._nats("ledger.rules.updated", {"rule_id": rule_id, "action": action})


class TaxRuleAdminService(BaseAdminService):
    """Zarządzanie regułami podatkowymi (RuleStore)."""

    @staticmethod
    def list_rules(active_only: bool = True, limit: int = 100, offset: int = 0, date_filter: str | None = None) -> tuple[list[dict[str, Any]], int]:
        from nexus_ai.services.rule_store import RuleStore
        with TaxRuleAdminService._db() as conn:
            store = RuleStore(conn)
            store.ensure_schema()
            return store.list_rules(active_only=active_only, limit=limit, offset=offset, date_filter=date_filter), store.count_rules(active_only=active_only)

    @staticmethod
    def create_rule(condition_sql: str, action: dict[str, Any] | None = None,
                    valid_from: str = "2024-01-01", valid_to: str | None = None,
                    priority: int = 100, description_template: str | None = None, created_by: str = "admin") -> str:
        from nexus_ai.services.rule_store import RuleStore
        with TaxRuleAdminService._db() as conn:
            store = RuleStore(conn)
            store.ensure_schema()
            return store.add_rule(condition_sql=condition_sql, action=action or {}, valid_from=valid_from,
                                  valid_to=valid_to, priority=priority, description_template=description_template, created_by=created_by)

    @staticmethod
    def close_rule(rule_id: str, valid_to: str | None = None, closed_by: str = "admin") -> bool:
        from nexus_ai.services.rule_store import RuleStore
        with TaxRuleAdminService._db() as conn:
            store = RuleStore(conn)
            store.ensure_schema()
            return store.close_rule(rule_id, valid_to=valid_to, closed_by=closed_by)

    @staticmethod
    def get_rule(rule_id: str) -> dict[str, Any] | None:
        from nexus_ai.services.rule_store import RuleStore
        with TaxRuleAdminService._db() as conn:
            store = RuleStore(conn)
            store.ensure_schema()
            return store.get_rule(rule_id)

    @staticmethod
    def get_changelog(rule_id: str | None = None, limit: int = 50) -> list[dict[str, Any]]:
        from nexus_ai.services.rule_store import RuleStore
        with TaxRuleAdminService._db() as conn:
            store = RuleStore(conn)
            store.ensure_schema()
            return store.get_change_log(rule_id=rule_id, limit=limit)

    @staticmethod
    def publish_event(rule_id: str, action: str) -> None:
        TaxRuleAdminService._nats("tax.rules.updated", {"rule_id": rule_id, "action": action})


class FallbackEventAdminService(BaseAdminService):
    """Zarządzanie zdarzeniami fallback."""

    @staticmethod
    def list_events(status_filter: str | None = None, limit: int = 50, offset: int = 0) -> tuple[list[dict[str, Any]], int]:
        from nexus_ai.services.fallback_handler import FallbackHandler
        with FallbackEventAdminService._db() as conn:
            handler = FallbackHandler(conn)
            return handler.list_events(status_filter=status_filter, limit=limit, offset=offset), handler.count_pending()

    @staticmethod
    def resolve_event(event_id: str, resolution_note: str = "Resolved via admin panel", assigned_to: str = "admin") -> bool:
        from nexus_ai.services.fallback_handler import FallbackHandler
        with FallbackEventAdminService._db() as conn:
            return FallbackHandler(conn).resolve(event_id, resolution_note=resolution_note, assigned_to=assigned_to)

    @staticmethod
    def ignore_event(event_id: str) -> bool:
        from nexus_ai.services.fallback_handler import FallbackHandler
        with FallbackEventAdminService._db() as conn:
            return FallbackHandler(conn).ignore(event_id)


class ReplayAdminService(BaseAdminService):
    """Odtwarzanie decyzji podatkowych."""

    @staticmethod
    def replay(transaction_id: str) -> dict[str, Any]:
        from nexus_ai.services.replay_engine import ReplayEngine
        with ReplayAdminService._db() as conn:
            result = ReplayEngine(conn).replay(transaction_id)
            return {"transaction_id": result.transaction_id, "match": result.match,
                    "original_verdict": result.original_verdict, "replayed_verdict": result.replayed_verdict,
                    "differences": result.differences, "error": result.error or None}

    @staticmethod
    def replay_batch(period_start: str, period_end: str, limit: int = 1000) -> dict[str, Any]:
        from nexus_ai.services.replay_engine import ReplayEngine
        try:
            start, end = pendulum.Date.fromisoformat(period_start), pendulum.Date.fromisoformat(period_end)
        except (ValueError, TypeError):
            return {"error": "Invalid date format. Use YYYY-MM-DD."}
        with ReplayAdminService._db() as conn:
            results = ReplayEngine(conn).replay_batch(start, end, limit=limit)
            matches = sum(1 for r in results if r.match)
            return {"total": len(results), "matches": matches, "mismatches": len(results) - matches,
                    "results": [{"transaction_id": r.transaction_id, "match": r.match, "error": r.error or None, "differences": r.differences} for r in results]}


class IntegrityAdminService(BaseAdminService):
    """Weryfikacja integralności łańcucha decyzji."""

    @staticmethod
    def verify(handle_violation: bool = True, system_lock: bool = False, incremental: bool = False) -> dict[str, Any]:
        from nexus_ai.services.integrity_verifier import IntegrityVerifier
        with IntegrityAdminService._db() as conn:
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
            if cp := verifier.get_latest_checkpoint():
                result["checkpoint"] = cp
            return result


class FailedTaskAdminService(BaseAdminService):
    """Zarządzanie failed tasks (DLQ) — operacje na outbox_events."""

    @staticmethod
    async def list_failed_tasks(db_engine: Any, resolved_filter: bool | None = None,
                                 task_name_filter: str | None = None, limit: int = 50, offset: int = 0) -> dict[str, Any]:
        from sqlmodel import text
        where_clauses, params = ["1=1"], {}
        if resolved_filter is not None:
            where_clauses.append("ft.resolved = :resolved")
            params["resolved"] = resolved_filter
        if task_name_filter:
            where_clauses.append("ft.task_name LIKE :task_name")
            params["task_name"] = f"%{task_name_filter}%"
        where_sql = " AND ".join(where_clauses)
        async with db_engine.connect() as conn:
            count = (await conn.execute(text(f"SELECT COUNT(*) FROM failed_tasks ft WHERE {where_sql}"), params)).scalar() or 0
            rows = (await conn.execute(text(f"SELECT ft.id, ft.task_name, ft.task_id, ft.error_type, ft.error_message, ft.retry_count, ft.max_retries, ft.resolved, ft.resolved_at, ft.resolved_by, ft.resolution_note, ft.failed_at, ft.created_at FROM failed_tasks ft WHERE {where_sql} ORDER BY ft.failed_at DESC LIMIT :limit OFFSET :offset"), {**params, "limit": limit, "offset": offset})).mappings().all()
        return {"tasks": [dict(r) for r in rows], "total": count, "limit": limit, "offset": offset}

    @staticmethod
    async def retry_task(db_engine: Any, task_id: str, username: str = "system") -> bool:
        from sqlmodel import text
        import uuid
        async with db_engine.connect() as conn:
            row = (await conn.execute(text("SELECT id, task_name, payload FROM failed_tasks WHERE id = :id AND resolved = 0"), {"id": task_id})).mappings().first()
            if not row:
                return False
            now = pendulum.now("UTC").isoformat()
            await conn.execute(text("UPDATE failed_tasks SET resolved = 1, resolved_at = :now, resolved_by = :by, resolution_note = 'Queued for retry' WHERE id = :id"), {"id": task_id, "now": now, "by": username})
            await FailedTaskAdminService._republish(db_engine, row["task_name"], row["payload"])
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
                    await FailedTaskAdminService._republish(db_engine, row["task_name"], row["payload"])
                    retried += 1
                except Exception:
                    pass
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
        from sqlmodel import text
        import uuid
        async with db_engine.connect() as conn:
            await conn.execute(text("""INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed, created_at)
                VALUES (:id, :event_type, :aggregate_id, :payload, 'PENDING', 0, :created_at)"""),
                {"id": uuid.uuid4().hex, "event_type": f"retry:{task_name}", "aggregate_id": uuid.uuid4().hex, "payload": payload, "created_at": pendulum.now("UTC").isoformat()})
            await conn.commit()
