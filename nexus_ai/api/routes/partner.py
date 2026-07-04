"""Partner Hub API endpoints -- accounting office multi-tenant view."""

from __future__ import annotations

from typing import Any

from litestar import Controller, get

from nexus_ai.api.dto import TAG_FINANCE, GenericListDTO, PartnerClientListDTO
from nexus_ai.core.config import AppConfig


class PartnerController(Controller):
    """Partner Hub -- multi-tenant view for accounting offices."""

    path = "/partner"
    tags = (TAG_FINANCE,)

    @get(
        "/clients",
        return_dto=PartnerClientListDTO,
        summary="Get partner clients",
        description="Returns list of clients (tenants) for the accounting office with cursor pagination (Rozwiązanie 32).",
        operation_id="getPartnerClients",
    )
    async def get_clients(
        self,
        config: AppConfig,
        limit: int = 50,
        cursor: str | None = None,
    ) -> dict:
        """Return list of clients (tenants) for the accounting office (Rozwiązanie 32: paginacja kursorem).

        Each client includes:
          - id, name, nip
          - invoice_count: invoices needing decisions
          - status: OK / UWAGA / PROBLEM
          - last_activity: ISO datetime

        Sorting: clients requiring attention first.

        Query params:
          - limit (int, default 50, max 200)
          - cursor (str, optional): token paginacji

        Returns dict with items, next_cursor, has_more.
        """
        try:
            from db.analytics import DuckDBManager

            mgr = DuckDBManager(
                db_path=config.duckdb_path,
                sqlite_path=config.sqlite_path,
                read_only=True,
            )
            try:
                return self._fetch_clients(mgr, limit=limit, cursor=cursor)
            finally:
                mgr.close()
        except Exception:
            return {"items": [], "next_cursor": None, "has_more": False}

    def _fetch_clients(self, mgr: Any, limit: int = 50, cursor: str | None = None) -> dict:
        """Fetch client list from DuckDB with pagination (Rozwiązanie 32).
        Używa parameterized queries aby zapobiec SQL injection.
        """
        from api.services import CursorPagination

        safe_limit = max(1, min(int(limit), 200)) + 1  # +1 dla detection has_more
        try:
            base_query = """
                SELECT
                    t.id AS tenant_id,
                    t.name AS tenant_name,
                    COALESCE(t.nip, '') AS tenant_nip,
                    COUNT(i.id) AS total_invoices,
                    COUNT(i.id) FILTER (
                        WHERE i.status IN ('MANUAL_REVIEW', 'PENDING_REVIEW')
                    ) AS pending_count,
                    COUNT(i.id) FILTER (
                        WHERE i.status IN ('NEW', 'PROCESSING')
                    ) AS processing_count,
                    COUNT(i.id) FILTER (
                        WHERE i.status IN ('FAILED', 'BLOCKED')
                    ) AS error_count,
                    MAX(i.updated_at) AS last_activity
                FROM oltp.invoices i
                JOIN oltp.tenants t ON i.tenant_id = t.id
            """
            where_clause = ""
            params: list[Any] = []
            if cursor:
                decoded = CursorPagination.decode_cursor(cursor)
                if decoded:
                    cursor_date, cursor_id = decoded
                    where_clause = "WHERE (last_activity < ? OR (last_activity = ? AND t.id < ?))"
                    params = [cursor_date, cursor_date, str(cursor_id)]

            group_order = """
                GROUP BY t.id, t.name, t.nip
                ORDER BY pending_count DESC, error_count DESC, last_activity DESC
                LIMIT ?
            """
            params.append(safe_limit)
            full_query = base_query + where_clause + group_order

            rows = mgr.execute(full_query, params)
            if not rows:
                return {"items": [], "next_cursor": None, "has_more": False}

            has_more = len(rows) > safe_limit - 1
            if has_more:
                rows = rows[: safe_limit - 1]

            clients = []
            for r in rows:
                pending = int(r[4]) if r[4] else 0
                errors = int(r[6]) if r[6] else 0

                if errors > 0:
                    status = "PROBLEM"
                elif pending > 0:
                    status = "UWAGA"
                else:
                    status = "OK"

                clients.append(
                    {
                        "id": str(r[0]) if r[0] else "",
                        "name": str(r[1]) if r[1] else "Nieznany",
                        "nip": str(r[2]) if r[2] else "",
                        "invoice_count": pending,
                        "status": status,
                        "last_activity": str(r[7]) if r[7] else "",
                    }
                )

            next_cursor = CursorPagination.build_next_cursor(
                clients, date_key="last_activity", id_key="id"
            )
            return {"items": clients, "next_cursor": next_cursor, "has_more": has_more}
        except Exception:
            return {"items": [], "next_cursor": None, "has_more": False}

    @get(
        "/clients/{client_id:str}/invoices",
        return_dto=GenericListDTO,
        summary="Get client invoices",
        description="Returns invoices needing decisions for a specific client (tenant).",
        operation_id="getPartnerClientInvoices",
    )
    async def get_client_invoices(
        self,
        client_id: str,
        config: AppConfig,
    ) -> list[dict[str, Any]]:
        """Return invoices needing decisions for a specific client (tenant).

        Returns list of invoices in MANUAL_REVIEW or PENDING_REVIEW status.
        """
        invoices: list[dict[str, Any]] = []

        try:
            from db.analytics import DuckDBManager

            mgr = DuckDBManager(
                db_path=config.duckdb_path,
                sqlite_path=config.sqlite_path,
                read_only=True,
            )
            try:
                rows = mgr.execute(
                    """
                    SELECT
                        i.id,
                        i.number,
                        i.contractor_nip,
                        i.amount_gross,
                        i.currency,
                        i.status,
                        i.issue_date,
                        i.created_at,
                        COALESCE(i.ocr_confidence, 0.0) AS confidence
                    FROM oltp.invoices i
                    WHERE i.tenant_id = ?
                      AND i.status IN ('MANUAL_REVIEW', 'PENDING_REVIEW')
                    ORDER BY i.created_at DESC
                    LIMIT 50
                    """,
                    [client_id],
                )
                if rows:
                    for r in rows:
                        invoices.append(
                            {
                                "invoice_id": str(r[0]) if r[0] else "",
                                "number": str(r[1]) if r[1] else "",
                                "contractor": str(r[2]) if r[2] else "",
                                "amount_gross": float(r[3]) if r[3] else 0.0,
                                "currency": str(r[4]) if r[4] else "PLN",
                                "status": str(r[5]) if r[5] else "",
                                "issue_date": str(r[6]) if r[6] else "",
                                "created_at": str(r[7]) if r[7] else "",
                                "confidence": float(r[8]) if r[8] else 0.0,
                            }
                        )
            finally:
                mgr.close()
        except Exception:
            pass

        return invoices
