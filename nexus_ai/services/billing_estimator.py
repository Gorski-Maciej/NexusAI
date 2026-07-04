"""Automatyczny estymator kosztów i czasu przetwarzania.

- Współdzielony SQLite store (NIE DuckDB :memory: per request)
- First-match-wins przez zapytania SQL
- Client-Driven Pricing
"""

from __future__ import annotations

from structlog import get_logger

from nexus_ai.services._billing_store import get_rules_connection, query_billing_rule

logger = get_logger("nexus.services.billing")


class BillingResult:
    """Wynik estymacji kosztów."""
    __slots__ = (
        "base_rate_per_minute", "breakdown", "compliance_surcharge_pln",
        "processing_time_minutes", "requires_senior", "rule_id",
        "total_cost", "total_price_pln", "total_time_hours",
    )

    def __init__(
        self,
        processing_time_minutes: float = 0.0,
        compliance_surcharge_pln: float = 0.0,
        requires_senior: bool = False,
        total_cost: float = 0.0,
        rule_id: str = "",
        base_rate_per_minute: float = 0.0,
        breakdown: list[dict] | None = None,
        total_price_pln: float = 0.0,
        total_time_hours: float = 0.0,
    ) -> None:
        self.processing_time_minutes = processing_time_minutes
        self.compliance_surcharge_pln = compliance_surcharge_pln
        self.requires_senior = requires_senior
        self.total_cost = total_cost
        self.rule_id = rule_id
        self.base_rate_per_minute = base_rate_per_minute
        self.breakdown = breakdown or []
        self.total_price_pln = total_cost or total_price_pln
        self.total_time_hours = total_time_hours or (processing_time_minutes / 60.0)


class BillingEstimator:
    """Estymator kosztów używający współdzielonego SQLite store."""
    __slots__ = ()

    def estimate(
        self,
        doc_type: str = "faktura_krajowa",
        tax_form: str = "CIT_STANDARD",
        vendor_region: str = "PL",
        extra_services: str | list[str] | None = None,
    ) -> BillingResult:
        """Estymuj koszt przetwarzania dokumentu."""
        conn = get_rules_connection()
        try:
            rule = query_billing_rule(conn, doc_type, tax_form, vendor_region)
        finally:
            conn.close()

        if rule:
            output = rule["output"]
            result = BillingResult(
                processing_time_minutes=float(output.get("processing_time_minutes", 2.0)),
                compliance_surcharge_pln=float(output.get("compliance_surcharge_pln", 0.0)),
                requires_senior=bool(output.get("requires_senior", False)),
                base_rate_per_minute=float(output.get("base_rate_per_minute", 2.50)),
                rule_id=str(rule["rule_id"]),
            )
        else:
            result = BillingResult(
                processing_time_minutes=2.0,
                base_rate_per_minute=2.50,
                rule_id="fallback_default",
            )

        base_cost = result.processing_time_minutes * result.base_rate_per_minute
        total_cost = base_cost + result.compliance_surcharge_pln

        services = extra_services
        if isinstance(services, str):
            services = [s.strip() for s in services.split(",") if s.strip()]

        if services:
            if "ekspres" in services:
                total_cost *= 1.5
                result.processing_time_minutes *= 0.7
            if "audyt" in services:
                total_cost += 200.0
                result.requires_senior = True

        result.total_cost = round(total_cost, 2)
        result.total_price_pln = result.total_cost
        result.total_time_hours = result.processing_time_minutes / 60.0
        return result
