from __future__ import annotations

import os
import resource

from litestar import Controller, get
from sqlalchemy import text

from api.rbac import owner_only_guard
from core.config import AppConfig
from db.database import create_oltp_engine, create_session_factory
from services.finops_meter import estimate_runtime_cost


class FinOpsController(Controller):
    """Operational FinOps metrics for self-hosted runtime."""

    path = "/api/v1/system/finops"
    guards = [owner_only_guard]

    @get("/cost-per-invoice")
    async def cost_per_invoice(self) -> dict:
        config = AppConfig()
        engine = create_oltp_engine(config)
        session_factory = create_session_factory(engine)

        cpu_cores = float(os.cpu_count() or 1)
        ram_gb = max((resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024 / 1024), 0.1)
        hourly_cost = estimate_runtime_cost(cpu_cores=cpu_cores, ram_gb=ram_gb, runtime_hours=1.0)

        try:
            async with session_factory() as session:
                total_invoices = int((await session.execute(text("SELECT COUNT(*) FROM invoices"))).scalar_one())
        finally:
            await engine.dispose()

        cost_per_invoice = float(hourly_cost) / max(total_invoices, 1)
        return {
            "hourly_cost_usd": float(hourly_cost),
            "invoice_count": total_invoices,
            "cost_per_invoice_usd": float(cost_per_invoice),
            "cpu_cores": cpu_cores,
            "ram_gb": float(ram_gb),
        }
