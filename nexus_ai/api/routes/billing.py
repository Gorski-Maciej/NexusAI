"""Billing estimation API endpoint.

GET /api/v2/billing/estimate -- uzywa współdzielonego SQLite store.
"""

from __future__ import annotations

from litestar import Controller, get
from litestar.response import Response

from nexus_ai.services.billing_estimator import BillingEstimator

TAG_FINANCE = "finance"


class BillingController(Controller):
    """Estymacja kosztów i czasu przetwarzania dokumentów."""

    path = "/api/v2/billing"
    tags = [TAG_FINANCE]

    _estimator: BillingEstimator | None = None

    @property
    def estimator(self) -> BillingEstimator:
        if self._estimator is None:
            self._estimator = BillingEstimator()
        return self._estimator

    @get(
        "/estimate",
        summary="Estimate billing cost",
        description="Estimates document processing cost and time based on document type, tax form, and additional services.",
        operation_id="estimateBilling",
    )
    async def estimate(
        self,
        document_type: str = "faktura_krajowa",
        tax_form: str = "CIT_STANDARD",
        additional_services: str = "",
    ) -> Response[dict]:
        """Estymacja kosztu i czasu przetwarzania dokumentu.

        Query params:
            document_type: invoice_national | invoice_foreign | korekta | rachunek
            tax_form: CIT_STANDARD | LUMP_SUM | LINEAR | CIT_ESTONIAN
            additional_services: comma-separated (e.g. ekspres,audyt)
        """
        estimate = self.estimator.estimate(
            doc_type=document_type,
            tax_form=tax_form,
            extra_services=additional_services if additional_services else None,
        )

        return Response(
            {
                "total_price_pln": estimate.total_price_pln,
                "total_time_hours": estimate.total_time_hours,
                "breakdown": estimate.breakdown or [],
                "params": {
                    "document_type": document_type,
                    "tax_form": tax_form,
                    "additional_services": (
                        [s.strip() for s in additional_services.split(",") if s.strip()]
                        if additional_services
                        else []
                    ),
                },
            }
        )
