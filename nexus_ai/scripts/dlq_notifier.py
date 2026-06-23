"""
dlq_notifier.py — Periodic DLQ (Dead Letter Queue) notification script.

Scans the failed_tasks table for unresolved items and sends notifications
via the configured notification service (email, in-app, etc.).

Usage:
    python -m nexus_ai.scripts.dlq_notifier              # single check
    python -m nexus_ai.scripts.dlq_notifier --watch       # continuous mode (every 60 min)
    python -m nexus_ai.scripts.dlq_notifier --interval 30 # continuous mode (every 30 min)

Integration:
    Can be invoked from main.py or run as a scheduled task.
"""

from __future__ import annotations

import logging
from argparse import ArgumentParser, Namespace
from typing import Any

import anyio
import pendulum
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps

logger = get_logger("nexus.scripts.dlq_notifier")

# ── Thresholds ───────────────────────────────────────────────────────────────
# Minimum count of unresolved DLQ items to trigger a notification
DEFAULT_ALERT_THRESHOLD = 1
# Default check interval in minutes
DEFAULT_INTERVAL_MINUTES = 60


async def count_unresolved_dlq(db_engine: Any) -> int:
    """Count unresolved (non-resolved) tasks in the DLQ / failed_tasks table."""
    from sqlmodel import text

    try:
        async with db_engine.connect() as conn:
            row = await conn.execute(text("SELECT COUNT(*) FROM failed_tasks WHERE resolved = 0"))
            return int(row.scalar() or 0)
    except Exception as exc:
        logger.error("Failed to count unresolved DLQ items: %s", exc)
        return -1


async def fetch_recent_unresolved_dlq(db_engine: Any, limit: int = 10) -> list[dict[str, Any]]:
    """Fetch the most recent unresolved DLQ items for detailed notification."""
    from sqlmodel import text

    try:
        async with db_engine.connect() as conn:
            rows = (
                (
                    await conn.execute(
                        text(
                            """SELECT id, task_name, error_type, error_message,
                                  retry_count, max_retries, failed_at
                           FROM failed_tasks
                           WHERE resolved = 0
                           ORDER BY failed_at DESC
                           LIMIT :limit"""
                        ),
                        {"limit": limit},
                    )
                )
                .mappings()
                .all()
            )
            return [dict(r) for r in rows]
    except Exception as exc:
        logger.error("Failed to fetch unresolved DLQ items: %s", exc)
        return []


async def send_dlq_alert(
    unresolved_count: int,
    recent_items: list[dict[str, Any]],
    config: Any = None,
) -> None:
    """Send a notification about unresolved DLQ items.

    Currently logs the alert and attempts to send via the NotificationService.
    In production, this would send email/Slack/PagerDuty alerts.
    """
    if unresolved_count <= 0:
        return

    # Build summary message
    task_types = {}
    for item in recent_items:
        tname = item.get("task_name", "unknown")
        task_types[tname] = task_types.get(tname, 0) + 1

    type_summary = "; ".join(f"{name}: {count}" for name, count in task_types.items())

    message = (
        f"DLQ Alert: {unresolved_count} unresolved failed task(s) in Dead Letter Queue.\n"
        f"Breakdown: {type_summary}\n"
        f"Most recent failure: {recent_items[0].get('failed_at', 'N/A') if recent_items else 'N/A'}\n"
        f"Highest retry count: {max((i.get('retry_count', 0) for i in recent_items), default=0)}"
    )

    logger.warning("[DLQ_NOTIFIER] %s", message)

    # Attempt to send via NotificationService (non-blocking on failure)
    try:
        from nexus_ai.core.config import AppConfig
        from nexus_ai.services.notification_service import NotificationService

        cfg = config or AppConfig()
        ns = NotificationService(
            db_path=cfg.base_dir / "app_data" / "notifications.db",
            config=cfg,
        )

        # Send to all admin users (we send a generic alert — in production,
        # fetch admin user IDs from the database)
        await ns.send_notification(
            user_id="admin",
            title=f"⚠️ DLQ Alert: {unresolved_count} unresolved task(s)",
            message=msgspec_dumps(
                {
                    "unresolved_count": unresolved_count,
                    "task_breakdown": task_types,
                    "recent_items": [
                        {
                            "id": i.get("id"),
                            "task_name": i.get("task_name"),
                            "error_type": i.get("error_type"),
                            "failed_at": str(i.get("failed_at", "")),
                        }
                        for i in recent_items[:5]
                    ],
                    "timestamp": pendulum.now("UTC").isoformat(),
                },
                ensure_ascii=False,
            ),
            notification_type="warning",
            reference_type="dlq_alert",
        )
        logger.info("[DLQ_NOTIFIER] Notification sent via NotificationService")
    except Exception as exc:
        logger.debug("[DLQ_NOTIFIER] Could not send notification: %s", exc)


async def check_dlq_and_notify(db_engine: Any, config: Any = None) -> int:
    """Single check: count unresolved DLQ items and send alert if needed.

    Returns:
        Number of unresolved DLQ items found (-1 on error).
    """
    count = await count_unresolved_dlq(db_engine)
    if count < 0:
        logger.error("[DLQ_NOTIFIER] Could not query DLQ (database error)")
        return -1

    if count >= DEFAULT_ALERT_THRESHOLD:
        recent = await fetch_recent_unresolved_dlq(db_engine)
        await send_dlq_alert(count, recent, config)
    else:
        logger.info("[DLQ_NOTIFIER] DLQ check passed: %d unresolved items", count)

    return count


async def run_continuous_check(
    db_engine: Any,
    interval_minutes: int = DEFAULT_INTERVAL_MINUTES,
    config: Any = None,
) -> None:
    """Run DLQ checks in a loop at the specified interval."""
    logger.info("[DLQ_NOTIFIER] Starting continuous watcher (interval=%d min)", interval_minutes)
    while True:
        try:
            await check_dlq_and_notify(db_engine, config)
        except Exception as exc:
            logger.error("[DLQ_NOTIFIER] Check failed: %s", exc)
        await anyio.sleep(interval_minutes * 60)


# ── CLI entry point ──────────────────────────────────────────────────────────


def build_parser() -> ArgumentParser:
    parser = ArgumentParser(description="DLQ Notifier — monitor failed tasks and send alerts")
    parser.add_argument(
        "--watch",
        action="store_true",
        help=f"Continuous mode: check every N minutes (default: {DEFAULT_INTERVAL_MINUTES})",
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=DEFAULT_INTERVAL_MINUTES,
        help=f"Check interval in minutes (default: {DEFAULT_INTERVAL_MINUTES})",
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=DEFAULT_ALERT_THRESHOLD,
        help=f"Minimum unresolved count to trigger alert (default: {DEFAULT_ALERT_THRESHOLD})",
    )
    return parser


def main() -> int:
    """CLI entry point: python -m nexus_ai.scripts.dlq_notifier [options]"""
    args: Namespace = build_parser().parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    try:
        # Lazy import to avoid circular deps at module level
        from nexus_ai.core.config import AppConfig
        from nexus_ai.db.database import create_oltp_engine

        config = AppConfig()
        engine = create_oltp_engine(config)

        if args.watch:
            anyio.run(run_continuous_check, engine, interval_minutes=args.interval, config=config)
        else:
            result = anyio.run(check_dlq_and_notify, engine, config=config)
            print(f"[DLQ_NOTIFIER] Unresolved DLQ items: {result}")
            return 0 if result >= 0 else 1
    except Exception as exc:
        logger.critical("[DLQ_NOTIFIER] Fatal error: %s", exc)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
