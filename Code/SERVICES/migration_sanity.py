from __future__ import annotations

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine


async def run_migration_sanity_checks(engine: AsyncEngine) -> dict[str, int]:
    """
    Lightweight post-migration sanity checks.
    Returns key counters useful for alerting / observability.
    """
    async with engine.connect() as conn:
        invoices_count = int((await conn.execute(text("SELECT COUNT(*) FROM invoices"))).scalar_one())
        outbox_count = int((await conn.execute(text("SELECT COUNT(*) FROM outbox_events"))).scalar_one())
        users_count = int((await conn.execute(text("SELECT COUNT(*) FROM users"))).scalar_one())
    return {
        "invoices_count": invoices_count,
        "outbox_count": outbox_count,
        "users_count": users_count,
    }
