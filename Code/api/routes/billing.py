"""
Billing estimation API endpoint (Część XI).

GET /api/v2/billing/estimate — publiczny endpoint do estymacji kosztów.
"""

from __future__ import annotations

import duckdb
from litestar import Controller, get
from litestar.response import Response

from services.billing_estimator import BillingEstimator, ensure_schema, seed_default_billing_rules


class BillingController(Controller):
    path = "/api/v2/billing"

    @get("/estimate")
    async def estimate(
        self,
        document_type: str = "invoice_national",
        tax_form: str = "CIT_STANDARD",
        additional_services: str = "",
    ) -> Response[dict]:
        """Estymacja kosztu i czasu przetwarzania dokumentu.

        Query params:
            document_type: invoice_national | invoice_foreign
            tax_form: CIT_STANDARD | LUMP_SUM | LINEAR | CIT_ESTONIAN
            additional_services: comma-separated (e.g. ksef,semantic_guard)
        """
        conn = duckdb.connect(":memory:")
        try:
            ensure_schema(conn)
            seed_default_billing_rules(conn)
            estimator = BillingEstimator(conn)

            services = [s.strip() for s in additional_services.split(",") if s.strip()] if additional_services else None
            estimate = estimator.estimate(
                document_type=document_type,
                tax_form=tax_form,
                additional_services=services,
            )

            return Response({
                "total_price_pln": estimate.total_price_pln,
                "total_time_hours": estimate.total_time_hours,
                "breakdown": estimate.breakdown or [],
                "params": {
                    "document_type": document_type,
                    "tax_form": tax_form,
                    "additional_services": services or [],
                },
            })
        finally:
            conn.close()
