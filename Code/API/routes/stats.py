from litestar import get
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from db.models import Invoice

@get("/invoices/stats/pending")
async def get_pending_stats(db_session: AsyncSession) -> dict:
    """Zwraca liczbę faktur w stanach blokujących (PENDING, PROCESSING)."""
    query = select(func.count()).select_from(Invoice).where(
        Invoice.status.in_(["PENDING", "PROCESSING"])
    )

    result = await db_session.execute(query)
    count = result.scalar()

    return {"count": count}
