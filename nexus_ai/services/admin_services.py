"""
Admin services — dedykowane serwisy dla operacji panelu administracyjnego.

Eliminuje powtarzalny boilerplate ``import duckdb; conn = duckdb.connect(); try...finally``
z ~15 endpointów w ``api/routes/admin.py``. Każda domena administracyjna ma własną
klasę serwisu, która zarządza połączeniem DuckDB przez współdzielony helper.
"""

from __future__ import annotations

from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator

import duckdb
import pendulum

from nexus_ai.core.config import AppConfig
from nexus_ai.core.nats_utils import publish_event as _publish_nats_event


# ── Helper: zarządzanie połączeniem DuckDB ──────────────────────────────


@contextmanager
def _duckdb_conn() -> Iterator[duckdb.DuckDBPyConnection]:
    """Context manager dla połączenia DuckDB — eliminuje boilerplate.

    Automatycznie tworzy i zamyka połączenie. Zawsze używa ścieżki z AppConfig.
    """
    config = AppConfig()
    conn = duckdb.connect(str(config.duckdb_path))
    try:
        yield conn
    finally:
        conn.close()


# ── Risk Threshold Service ──────────────────────────────────────────────


class RiskThresholdAdminService:
    """Zarządzanie progami ryzyka (RiskGuard) — warstwa administracyjna."""

    @staticmethod
    def list_thresholds() -> list[dict[str, Any]]:
        from nexus_ai.services.risk_guard import RiskGuard

        with _duckdb_conn() as conn:
            guard = RiskGuard(conn)
            return guard.list_thresholds()

    @staticmethod
    def create_threshold(
        condition: dict[str, Any],
        output: dict[str, Any],
        valid_from: str = "2024-01-01",
        valid_to: str | None = None,
        priority: int = 100,
        created_by: str = "admin",
    ) -> str:
        from nexus_ai.services.risk_guard import RiskGuard

        with _duckdb_conn() as conn:
            guard = RiskGuard(conn)
            rule_id = guard.add_threshold(
                condition=condition,
                output=output,
                valid_from=valid_from,
                valid_to=valid_to,
                priority=priority,
                created_by=created_by,
            )
        return rule_id

    @staticmethod
    def deprecate_threshold(rule_id: str, created_by: str = "admin") -> bool:
        from nexus_ai.services.risk_guard import RiskGuard

        with _duckdb_conn() as conn:
            guard = RiskGuard(conn)
            return guard.deprecate_threshold(rule_id, created_by=created_by)

    @staticmethod
    def list_history() -> list[dict[str, Any]]:
        from nexus_ai.services.risk_guard import RiskGuard

        with _duckdb_conn() as conn:
            guard = RiskGuard(conn)
            return guard.list_thresholds_history()

    @staticmethod
    def publish_event(rule_id: str, action: str) -> None:
        """Opublikuj event NATS dla hot-reload."""
        import anyio

        try:
            anyio.ensure_backend().create_task(
                _publish_nats_event("risk.thresholds.updated", {"rule_id": rule_id, "action": action})
            )
        except RuntimeError:
            pass  # Brak event loop


# ── Billing Rule Service ────────────────────────────────────────────────


class BillingRuleAdminService:
    """Zarządzanie regułami billingowymi — warstwa administracyjna."""

    @staticmethod
    def list_rules(active_only: bool = True) -> list[dict[str, Any]]:
        from nexus_ai.services.billing_estimator import BillingEstimator

        with _duckdb_conn() as conn:
            estimator = BillingEstimator(conn)
            return estimator.list_rules(active_only=active_only)

    @staticmethod
    def create_rule(
        condition: dict[str, Any],
        price: dict[str, Any],
        valid_from: str = "2024-01-01",
        valid_to: str | None = None,
        priority: int = 100,
    ) -> str:
        from nexus_ai.services.billing_estimator import BillingEstimator

        with _duckdb_conn() as conn:
            estimator = BillingEstimator(conn)
            rule_id = estimator.add_rule(
                condition=condition,
                price=price,
                valid_from=valid_from,
                valid_to=valid_to,
                priority=priority,
            )
        return rule_id

    @staticmethod
    def deprecate_rule(rule_id: str) -> bool:
        from nexus_ai.services.billing_estimator import BillingEstimator

        with _duckdb_conn() as conn:
            estimator = BillingEstimator(conn)
            return estimator.deprecate_rule(rule_id)

    @staticmethod
    def publish_event(rule_id: str, action: str) -> None:
        import anyio

        try:
            anyio.ensure_backend().create_task(
                _publish_nats_event("billing.rules.updated", {"rule_id": rule_id, "action": action})
            )
        except RuntimeError:
            pass


# ── Ledger Rule Service ─────────────────────────────────────────────────


class LedgerRuleAdminService:
    """Zarządzanie regułami walidacji księgi głównej (Ledger Validation Rules).

    Konsoliduje inline DuckDB DDL/DML z admin.py w jeden serwis.
    """

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

    @staticmethod
    def _ensure_table(conn: duckdb.DuckDBPyConnection) -> None:
        conn.execute(LedgerRuleAdminService._DDL)

    @staticmethod
    def list_rules() -> list[dict[str, Any]]:
        with _duckdb_conn() as conn:
            LedgerRuleAdminService._ensure_table(conn)
            rows = conn.execute(
                """SELECT rule_id, transaction_type, debit_account_id, credit_account_id,
                          amount_sign, priority, valid_from, valid_to, created_at, created_by
                   FROM ledger_validation_rules
                   ORDER BY priority ASC, rule_id ASC"""
            ).fetchall()
            return [
                {
                    "rule_id": str(r[0]),
                    "transaction_type": str(r[1]),
                    "debit_account_id": int(r[2]),
                    "credit_account_id": int(r[3]),
                    "amount_sign": str(r[4]),
                    "priority": int(r[5]),
                    "valid_from": str(r[6]),
                    "valid_to": str(r[7]) if r[7] else None,
                    "created_at": str(r[8]),
                    "created_by": str(r[9]),
                }
                for r in rows
            ]

    @staticmethod
    def create_rule(
        transaction_type: str,
        debit_account_id: int,
        credit_account_id: int,
        amount_sign: str = "POSITIVE",
        priority: int = 100,
        valid_from: str = "2024-01-01",
        valid_to: str | None = None,
        created_by: str = "admin",
    ) -> str:
        import uuid as _uuid

        with _duckdb_conn() as conn:
            LedgerRuleAdminService._ensure_table(conn)
            rule_id = f"ledger_{_uuid.uuid4().hex[:12]}"
            conn.execute(
                """INSERT INTO ledger_validation_rules
                   (rule_id, transaction_type, debit_account_id, credit_account_id,
                    amount_sign, priority, valid_from, valid_to, created_by)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    rule_id,
                    transaction_type.upper(),
                    debit_account_id,
                    credit_account_id,
                    amount_sign,
                    priority,
                    valid_from,
                    valid_to,
                    created_by,
                ),
            )
        return rule_id

    @staticmethod
    def delete_rule(rule_id: str) -> bool:
        with _duckdb_conn() as conn:
            LedgerRuleAdminService._ensure_table(conn)
            conn.execute(
                """UPDATE ledger_validation_rules
                   SET valid_to = CURRENT_DATE - INTERVAL '1 day'
                   WHERE rule_id = ? AND valid_to IS NULL""",
                (rule_id,),
            )
            return True

    @staticmethod
    def publish_event(rule_id: str, action: str) -> None:
        import anyio

        try:
            anyio.ensure_backend().create_task(
                _publish_nats_event("ledger.rules.updated", {"rule_id": rule_id, "action": action})
            )
        except RuntimeError:
            pass


# ── Tax Rule Service ────────────────────────────────────────────────────


class TaxRuleAdminService:
    """Zarządzanie regułami podatkowymi (RuleStore) — warstwa administracyjna."""

    @staticmethod
    def _get_store() -> tuple[Any, duckdb.DuckDBPyConnection]:
        """Zwraca (RuleStore, conn) — caller zamyka conn."""
        from nexus_ai.services.rule_store import RuleStore

        config = AppConfig()
        conn = duckdb.connect(str(config.duckdb_path))
        store = RuleStore(conn)
        store.ensure_schema()
        return store, conn

    @staticmethod
    def list_rules(
        active_only: bool = True,
        limit: int = 100,
        offset: int = 0,
        date_filter: str | None = None,
    ) -> tuple[list[dict[str, Any]], int]:
        from nexus_ai.services.rule_store import RuleStore

        with _duckdb_conn() as conn:
            store = RuleStore(conn)
            store.ensure_schema()
            rules = store.list_rules(
                active_only=active_only,
                limit=limit,
                offset=offset,
                date_filter=date_filter,
            )
            total = store.count_rules(active_only=active_only)
            return rules, total

    @staticmethod
    def create_rule(
        condition_sql: str,
        action: dict[str, Any] | None = None,
        valid_from: str = "2024-01-01",
        valid_to: str | None = None,
        priority: int = 100,
        description_template: str | None = None,
        created_by: str = "admin",
    ) -> str:
        from nexus_ai.services.rule_store import RuleStore

        with _duckdb_conn() as conn:
            store = RuleStore(conn)
            store.ensure_schema()
            rule_id = store.add_rule(
                condition_sql=condition_sql,
                action=action or {},
                valid_from=valid_from,
                valid_to=valid_to,
                priority=priority,
                description_template=description_template,
                created_by=created_by,
            )
        return rule_id

    @staticmethod
    def close_rule(
        rule_id: str,
        valid_to: str | None = None,
        closed_by: str = "admin",
    ) -> bool:
        from nexus_ai.services.rule_store import RuleStore

        with _duckdb_conn() as conn:
            store = RuleStore(conn)
            store.ensure_schema()
            return store.close_rule(rule_id, valid_to=valid_to, closed_by=closed_by)

    @staticmethod
    def get_rule(rule_id: str) -> dict[str, Any] | None:
        from nexus_ai.services.rule_store import RuleStore

        with _duckdb_conn() as conn:
            store = RuleStore(conn)
            store.ensure_schema()
            return store.get_rule(rule_id)

    @staticmethod
    def get_changelog(rule_id: str | None = None, limit: int = 50) -> list[dict[str, Any]]:
        from nexus_ai.services.rule_store import RuleStore

        with _duckdb_conn() as conn:
            store = RuleStore(conn)
            store.ensure_schema()
            return store.get_change_log(rule_id=rule_id, limit=limit)

    @staticmethod
    def publish_event(rule_id: str, action: str) -> None:
        import anyio

        try:
            anyio.ensure_backend().create_task(
                _publish_nats_event("tax.rules.updated", {"rule_id": rule_id, "action": action})
            )
        except RuntimeError:
            pass


# ── Fallback Event Service ──────────────────────────────────────────────


class FallbackEventAdminService:
    """Zarządzanie zdarzeniami fallback — warstwa administracyjna."""

    @staticmethod
    def list_events(
        status_filter: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> tuple[list[dict[str, Any]], int]:
        from nexus_ai.services.fallback_handler import FallbackHandler

        with _duckdb_conn() as conn:
            handler = FallbackHandler(conn)
            events = handler.list_events(
                status_filter=status_filter,
                limit=limit,
                offset=offset,
            )
            pending = handler.count_pending()
            return events, pending

    @staticmethod
    def resolve_event(
        event_id: str,
        resolution_note: str = "Resolved via admin panel",
        assigned_to: str = "admin",
    ) -> bool:
        from nexus_ai.services.fallback_handler import FallbackHandler

        with _duckdb_conn() as conn:
            handler = FallbackHandler(conn)
            return handler.resolve(
                event_id,
                resolution_note=resolution_note,
                assigned_to=assigned_to,
            )

    @staticmethod
    def ignore_event(event_id: str) -> bool:
        from nexus_ai.services.fallback_handler import FallbackHandler

        with _duckdb_conn() as conn:
            handler = FallbackHandler(conn)
            return handler.ignore(event_id)


# ── Replay Service ──────────────────────────────────────────────────────


class ReplayAdminService:
    """Odtwarzanie decyzji podatkowych — warstwa administracyjna."""

    @staticmethod
    def replay(transaction_id: str) -> dict[str, Any]:
        from nexus_ai.services.replay_engine import ReplayEngine

        with _duckdb_conn() as conn:
            engine = ReplayEngine(conn)
            result = engine.replay(transaction_id)
            return {
                "transaction_id": result.transaction_id,
                "match": result.match,
                "original_verdict": result.original_verdict,
                "replayed_verdict": result.replayed_verdict,
                "differences": result.differences,
                "error": result.error or None,
            }

    @staticmethod
    def replay_batch(
        period_start: str,
        period_end: str,
        limit: int = 1000,
    ) -> dict[str, Any]:
        from nexus_ai.services.replay_engine import ReplayEngine

        try:
            start = pendulum.Date.fromisoformat(period_start)
            end = pendulum.Date.fromisoformat(period_end)
        except (ValueError, TypeError):
            return {"error": "Invalid date format. Use YYYY-MM-DD."}

        with _duckdb_conn() as conn:
            engine = ReplayEngine(conn)
            results = engine.replay_batch(start, end, limit=limit)
            matches = sum(1 for r in results if r.match)
            return {
                "total": len(results),
                "matches": matches,
                "mismatches": len(results) - matches,
                "results": [
                    {
                        "transaction_id": r.transaction_id,
                        "match": r.match,
                        "error": r.error or None,
                        "differences": r.differences,
                    }
                    for r in results
                ],
            }


# ── Integrity Verification Service ──────────────────────────────────────


class IntegrityAdminService:
    """Weryfikacja integralności łańcucha decyzji — warstwa administracyjna."""

    @staticmethod
    def verify(
        handle_violation: bool = True,
        system_lock: bool = False,
        incremental: bool = False,
    ) -> dict[str, Any]:
        from nexus_ai.services.integrity_verifier import IntegrityVerifier

        with _duckdb_conn() as conn:
            verifier = IntegrityVerifier(conn)

            if incremental:
                report = verifier.verify_incremental()
            else:
                report = verifier.verify_all()

            result: dict[str, Any] = {
                "status": report.status,
                "total_records": report.total_records,
                "verified_at": report.verified_at,
                "violations": [],
                "violation_id": None,
                "system_locked": False,
                "checkpoint": None,
            }

            if report.status == "violation" and report.violations:
                result["violations"] = report.violations[:10]
                result["first_inconsistent_trace"] = report.first_inconsistent_trace

                if handle_violation:
                    violation_id = verifier.handle_violation(report)
                    result["violation_id"] = violation_id

                    if system_lock:
                        verifier.system_lock(lock=True)
                        result["system_locked"] = True

            cp = verifier.get_latest_checkpoint()
            if cp:
                result["checkpoint"] = cp

            return result


# ── Failed Task Management ──────────────────────────────────────────────


class FailedTaskAdminService:
    """Zarządzanie failed tasks (DLQ) — operacje na outbox_events."""

    @staticmethod
    async def list_failed_tasks(
        db_engine: Any,
        resolved_filter: bool | None = None,
        task_name_filter: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> dict[str, Any]:
        from sqlmodel import text

        where_clauses = ["1=1"]
        params: dict[str, Any] = {}

        if resolved_filter is not None:
            where_clauses.append("ft.resolved = :resolved")
            params["resolved"] = resolved_filter

        if task_name_filter:
            where_clauses.append("ft.task_name LIKE :task_name")
            params["task_name"] = f"%{task_name_filter}%"

        where_sql = " AND ".join(where_clauses)

        async with db_engine.connect() as conn:
            count_row = (
                await conn.execute(
                    text(f"SELECT COUNT(*) FROM failed_tasks ft WHERE {where_sql}"),
                    params,
                )
            ).scalar()
            total = count_row or 0

            rows = (
                (
                    await conn.execute(
                        text(
                            f"""SELECT ft.id, ft.task_name, ft.task_id, ft.error_type,
                                      ft.error_message, ft.retry_count, ft.max_retries,
                                      ft.resolved, ft.resolved_at, ft.resolved_by,
                                      ft.resolution_note, ft.failed_at, ft.created_at
                               FROM failed_tasks ft
                               WHERE {where_sql}
                               ORDER BY ft.failed_at DESC
                               LIMIT :limit OFFSET :offset"""
                        ),
                        {**params, "limit": limit, "offset": offset},
                    )
                )
                .mappings()
                .all()
            )

        return {
            "tasks": [dict(r) for r in rows],
            "total": total,
            "limit": limit,
            "offset": offset,
        }

    @staticmethod
    async def retry_task(
        db_engine: Any,
        task_id: str,
        username: str = "system",
    ) -> bool:
        from sqlmodel import text
        import uuid

        async with db_engine.connect() as conn:
            row = (
                (
                    await conn.execute(
                        text(
                            "SELECT id, task_name, payload, retry_count FROM failed_tasks WHERE id = :id AND resolved = 0"
                        ),
                        {"id": task_id},
                    )
                )
                .mappings()
                .first()
            )

            if not row:
                return False

            now = pendulum.now("UTC").isoformat()
            await conn.execute(
                text(
                    """UPDATE failed_tasks
                       SET resolved = 1, resolved_at = :now, resolved_by = :by,
                           resolution_note = 'Queued for retry'
                       WHERE id = :id"""
                ),
                {"id": task_id, "now": now, "by": username},
            )

            await FailedTaskAdminService._republish(db_engine, row["task_name"], row["payload"])
            await conn.commit()
        return True

    @staticmethod
    async def retry_all(db_engine: Any, username: str = "system") -> int:
        from sqlmodel import text

        async with db_engine.connect() as conn:
            rows = (
                (
                    await conn.execute(
                        text("SELECT id, task_name, payload FROM failed_tasks WHERE resolved = 0")
                    )
                )
                .mappings()
                .all()
            )

            now = pendulum.now("UTC").isoformat()
            retried = 0

            for row in rows:
                await conn.execute(
                    text(
                        """UPDATE failed_tasks
                           SET resolved = 1, resolved_at = :now, resolved_by = :by,
                               resolution_note = 'Queued for retry (bulk)'
                           WHERE id = :id"""
                    ),
                    {"id": row["id"], "now": now, "by": username},
                )
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
            row = (
                await conn.execute(
                    text("SELECT id FROM failed_tasks WHERE id = :id"),
                    {"id": task_id},
                )
            ).scalar()
            if not row:
                return False
            await conn.execute(
                text("DELETE FROM failed_tasks WHERE id = :id"),
                {"id": task_id},
            )
            await conn.commit()
        return True

    @staticmethod
    async def _republish(db_engine: Any, task_name: str, payload: str) -> None:
        from sqlmodel import text
        import uuid

        async with db_engine.connect() as conn:
            event_id = uuid.uuid4().hex
            now = pendulum.now("UTC").isoformat()
            await conn.execute(
                text(
                    """INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed, created_at)
                       VALUES (:id, :event_type, :aggregate_id, :payload, 'PENDING', 0, :created_at)"""
                ),
                {
                    "id": event_id,
                    "event_type": f"retry:{task_name}",
                    "aggregate_id": uuid.uuid4().hex,
                    "payload": payload,
                    "created_at": now,
                },
            )
            await conn.commit()
