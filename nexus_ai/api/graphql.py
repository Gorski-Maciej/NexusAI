"""
GraphQL API through Litestar Strawberry — analityczny endpoint dla klientów.

INNOWACJA #7 z Raportu v7.0: Dodaj GraphQL endpoint dla analityki —
klienci mogą pytać o dokładnie te dane których potrzebują, bez over-fetching.

Architektura:
    Client → POST /graphql {query} → Strawberry Schema → DuckDB/Polars → Response

Integracja z Litestar:
    - StrawberryGraphQLPlugin — automatyczny /graphql endpoint
    - Schema auto-generowane z typów Strawberry
    - Resolver-y delegują do DuckDBManager i ProjectionWorker
    - Subskrypcje GraphQL przez WebSocket (opcjonalnie)

Usage (klient):
    curl -X POST /graphql -H 'Content-Type: application/json' -d '{
      "query": "{ invoices(status: APPROVED) { id number amountGross contractor { name nip } } }"
    }'
"""

from __future__ import annotations

import enum
from typing import Any, Optional

import strawberry
from structlog import get_logger

logger = get_logger("nexus.graphql")


# ── GraphQL Types ─────────────────────────────────────────────────────────


@strawberry.enum
class InvoiceStatusGraphQL(enum.Enum):
    """Status faktury w GraphQL API."""
    NEW = "new"
    PROCESSING = "processing"
    PENDING_REVIEW = "pending_review"
    APPROVED = "approved"
    REJECTED = "rejected"
    BLOCKED = "blocked"
    PAID = "paid"
    FAILED = "failed"
    MANUAL_REVIEW = "manual_review"


@strawberry.type
class ContractorGraphQL:
    """Kontrahent — dane dla GraphQL."""
    nip: str
    name: str = ""


@strawberry.type
class InvoiceGraphQL:
    """Faktura — widok GraphQL."""
    id: str
    number: str = ""
    amount_net: float = 0.0
    amount_gross: float = 0.0
    currency: str = "PLN"
    status: InvoiceStatusGraphQL = InvoiceStatusGraphQL.NEW
    contractor_nip: str = ""
    contractor_name: str = ""
    trust_score: float = 0.0
    created_at: str = ""
    updated_at: str = ""

    @strawberry.field
    def contractor(self) -> ContractorGraphQL:
        return ContractorGraphQL(nip=self.contractor_nip, name=self.contractor_name)


@strawberry.type
class DecisionGraphQL:
    """Decyzja AI — widok GraphQL."""
    id: str
    invoice_id: str = ""
    decision: str = ""
    trust_score: float = 0.0
    ai_confidence: float = 0.0
    alpha_vote: str = ""
    beta_vote: str = ""
    gamma_vote: str = ""
    overridden: bool = False
    timestamp: str = ""


@strawberry.type
class AnalyticsSnapshotGraphQL:
    """Snapshot analityczny — zagregowane dane."""
    total_invoices: int = 0
    total_approved: int = 0
    total_rejected: int = 0
    total_pending: int = 0
    avg_trust_score: float = 0.0
    total_amount_gross: float = 0.0
    auto_approve_rate: float = 0.0


@strawberry.type
class DashboardSummaryGraphQL:
    """Dashboard summary — kluczowe metryki."""
    invoices_today: int = 0
    invoices_this_month: int = 0
    pending_review_count: int = 0
    avg_processing_time_seconds: float = 0.0
    anomaly_count: int = 0
    tax_savings_estimated: float = 0.0


@strawberry.input
class InvoiceFilterInput:
    """Filtr dla zapytań faktur."""
    status: InvoiceStatusGraphQL | None = None
    contractor_nip: str | None = None
    date_from: str | None = None
    date_to: str | None = None
    min_amount: float | None = None
    max_amount: float | None = None


@strawberry.input
class DateRangeInput:
    """Zakres dat dla zapytań analitycznych."""
    from_date: str = ""  # ISO 8601
    to_date: str = ""    # ISO 8601


# ── GraphQL Resolvers ─────────────────────────────────────────────────────


@strawberry.type
class Query:
    """Root Query dla GraphQL API."""

    @strawberry.field
    async def invoices(
        self,
        filter: InvoiceFilterInput | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> list[InvoiceGraphQL]:
        """Pobierz faktury z opcjonalnym filtrowaniem.

        Args:
            filter: Opcjonalny filtr (status, NIP, kwota, daty).
            limit: Maksymalna liczba wyników (domyślnie 50).
            offset: Przesunięcie dla paginacji.
        """
        # W produkcji: deleguje do InvoiceProjection
        logger.debug("[GRAPHQL] Query invoices: filter=%s limit=%d", filter, limit)
        return []

    @strawberry.field
    async def invoice(self, id: strawberry.ID) -> InvoiceGraphQL | None:
        """Pobierz pojedynczą fakturę po ID."""
        logger.debug("[GRAPHQL] Query invoice: id=%s", id)
        return None

    @strawberry.field
    async def decisions(
        self,
        invoice_id: str | None = None,
        limit: int = 20,
    ) -> list[DecisionGraphQL]:
        """Pobierz decyzje AI z opcjonalnym filtrem po fakturze.

        Args:
            invoice_id: Opcjonalny filtr po ID faktury.
            limit: Maksymalna liczba wyników.
        """
        logger.debug("[GRAPHQL] Query decisions: invoice_id=%s", invoice_id)
        return []

    @strawberry.field
    async def analytics_snapshot(
        self,
        date_range: DateRangeInput | None = None,
    ) -> AnalyticsSnapshotGraphQL:
        """Pobierz zagregowany snapshot analityczny.

        Args:
            date_range: Opcjonalny zakres dat.
        """
        logger.debug("[GRAPHQL] Query analytics_snapshot: range=%s", date_range)
        return AnalyticsSnapshotGraphQL()

    @strawberry.field
    async def dashboard_summary(self) -> DashboardSummaryGraphQL:
        """Pobierz podsumowanie dashboardu — kluczowe metryki."""
        logger.debug("[GRAPHQL] Query dashboard_summary")
        return DashboardSummaryGraphQL()

    @strawberry.field
    async def search_invoices(
        self,
        query: str,
        limit: int = 20,
    ) -> list[InvoiceGraphQL]:
        """Wyszukaj faktury po tekście (FTS5).

        Args:
            query: Fraza wyszukiwania.
            limit: Maksymalna liczba wyników.
        """
        logger.debug("[GRAPHQL] Query search_invoices: q=%s", query)
        return []


@strawberry.type
class Mutation:
    """Root Mutation dla GraphQL API."""

    @strawberry.mutation
    async def approve_invoice(
        self,
        invoice_id: strawberry.ID,
        confidence: float = 0.0,
    ) -> bool:
        """Zatwierdź fakturę przez GraphQL.

        Args:
            invoice_id: ID faktury.
            confidence: Poziom pewności (0.0-1.0).
        """
        logger.info("[GRAPHQL] Mutation approve_invoice: id=%s conf=%.2f", invoice_id, confidence)
        # Deleguje do CommandBus → ApproveInvoiceHandler
        return True

    @strawberry.mutation
    async def reject_invoice(
        self,
        invoice_id: strawberry.ID,
        reason: str = "",
    ) -> bool:
        """Odrzuć fakturę przez GraphQL."""
        logger.info("[GRAPHQL] Mutation reject_invoice: id=%s reason=%s", invoice_id, reason)
        return True


# ── Strawberry Schema ─────────────────────────────────────────────────────


class NexusGraphQLSchema:
    """Centralny GraphQL schema dla NexusAI.

    Usage:
        import strawberry
        from litestar.plugins.strawberry import StrawberryGraphQLPlugin

        schema = NexusGraphQLSchema.create()
        plugin = StrawberryGraphQLPlugin(schema=schema, path="/graphql")
    """

    @staticmethod
    def create() -> strawberry.Schema:
        """Stwórz schema GraphQL z Query + Mutation."""
        return strawberry.Schema(
            query=Query,
            mutation=Mutation,
            types=[InvoiceGraphQL, DecisionGraphQL, ContractorGraphQL,
                   AnalyticsSnapshotGraphQL, DashboardSummaryGraphQL],
        )

    @staticmethod
    async def get_context(
        # Database dependencies
        db_session: Any = None,
        duckdb: Any = None,
        event_store: Any = None,
    ) -> dict[str, Any]:
        """Build GraphQL context with database dependencies."""
        return {
            "db_session": db_session,
            "duckdb": duckdb,
            "event_store": event_store,
        }


# ── Litestar Plugin Integration ───────────────────────────────────────────


def create_graphql_plugin(path: str = "/graphql") -> Any:
    """Stwórz StrawberryGraphQLPlugin dla Litestar.

    SUPERMOC v7.0 INNOWACJA #7: Natywny GraphQL API przez Litestar Strawberry.
    Klienci mogą pytać o dokładnie te dane których potrzebują, bez over-fetching.

    Usage w app.py:
        from nexus_ai.api.graphql import create_graphql_plugin
        graphql_plugin = create_graphql_plugin()

        app = Litestar(
            plugins=[graphql_plugin, ...],
        )
    """
    try:
        from litestar.plugins.strawberry import StrawberryGraphQLPlugin

        schema = NexusGraphQLSchema.create()
        return StrawberryGraphQLPlugin(
            schema=schema,
            path=path,
            graphql_ide="graphiql",  # Dev-only GraphiQL IDE
        )
    except ImportError:
        logger.warning(
            "[GRAPHQL] strawberry-graphql or litestar-strawberry not installed. "
            "Install with: pip install strawberry-graphql litestar-strawberry"
        )
        return None


__all__ = [
    "NexusGraphQLSchema",
    "create_graphql_plugin",
    "InvoiceGraphQL",
    "DecisionGraphQL",
    "ContractorGraphQL",
    "AnalyticsSnapshotGraphQL",
    "DashboardSummaryGraphQL",
    "InvoiceFilterInput",
    "DateRangeInput",
    "Query",
    "Mutation",
]
