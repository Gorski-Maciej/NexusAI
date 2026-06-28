"""HTTP communication layer for local Litestar backend.

SUPERMOCE:
  - Cache warstwa przez in-memory cache z TTL
  - Tylko async API (sync wrappers usunięte — zapobiega crashom)
  - HTTP/2 multiplexing
  - async close() cleanup
"""

from __future__ import annotations

from msgspec import Struct
from decimal import Decimal
from typing import Any
from uuid import uuid4

import httpx
from httpx import Limits, Timeout
import msgspec
import pendulum
from structlog import get_logger


class InvoiceDTO(msgspec.Struct, kw_only=True):
    """Invoice structure consumed by frontend views."""

    id: str
    number: str
    customer_id: str
    amount_net: Decimal
    amount_gross: Decimal
    currency: str = "PLN"
    created_at: pendulum.DateTime
    pending: bool = False


class ApiConfig(Struct):
    """API runtime configuration from bootstrap handshake."""

    port: int
    token: str

    @property
    def base_url(self) -> str:
        return f"http://127.0.0.1:{self.port}"


class NexusApiClient:
    """Jednolity klient API z cache warstwą, HTTP/2.

    Użycie (TYLKO ASYNC):
        client = NexusApiClient(config)
        invoices = await client.async_list_invoices()
        summary = await client.get_analytics_summary()
        await client.close()
    """

    def __init__(
        self,
        config: ApiConfig | None = None,
        port: int = 8000,
        token: str = "",
        base_url: str = "http://127.0.0.1:8000/api/v1",
    ):
        if config is not None:
            base_url = config.base_url
            token = config.token
            port = config.port

        self.base_url = f"http://127.0.0.1:{port}" if port != 8000 else base_url
        self.token = token
        headers = (
            {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
            if token
            else {"Content-Type": "application/json"}
        )

        limits = Limits(max_connections=10, max_keepalive_connections=5, keepalive_expiry=30.0)
        default_timeout = Timeout(connect=5.0, read=10.0, write=10.0, pool=300.0)

        self._async = httpx.AsyncClient(
            base_url=self.base_url,
            http2=True,
            trust_env=True,
            timeout=default_timeout,
            limits=limits,
            headers=headers,
            event_hooks={"request": [self._log_request], "response": [self._log_response]},
        )

        # Cache in-memory
        self._cache: dict[str, tuple[Any, float]] = {}
        self._cache_ttl: float = 5.0

    @staticmethod
    async def _log_request(request: httpx.Request) -> None:
        logger = get_logger("nexus.ui.api")
        logger.debug("[HTTP] → %s %s", request.method, request.url)

    @staticmethod
    async def _log_response(response: httpx.Response) -> None:
        logger = get_logger("nexus.ui.api")
        elapsed = response.elapsed.total_seconds() * 1000 if response.elapsed else 0
        logger.debug(
            "[HTTP] ← %s %s (%d, %.1fms)",
            response.request.method,
            response.url,
            response.status_code,
            elapsed,
        )

    def _cache_get(self, key: str) -> Any | None:
        import time

        if key in self._cache:
            value, timestamp = self._cache[key]
            if time.time() - timestamp < self._cache_ttl:
                return value
            del self._cache[key]
        return None

    def _cache_set(self, key: str, value: Any) -> None:
        import time

        self._cache[key] = (value, time.time())

    def _cache_invalidate(self, pattern: str) -> None:
        """Invalidate cache keys matching pattern."""
        keys_to_delete = [k for k in self._cache if k.startswith(pattern)]
        for k in keys_to_delete:
            self._cache.pop(k, None)

    # ── Async API — preferowane ────────────────────────────────────────

    async def async_list_invoices(self) -> list[Any]:
        """Pobiera listę wszystkich faktur (async z cache)."""
        cache_key = "invoices:list"
        cached = self._cache_get(cache_key)
        if cached is not None:
            return cached

        response = await self._async.get("/invoices")
        if response.status_code == 404:
            return []
        response.raise_for_status()
        payload = response.json()
        data = payload if isinstance(payload, list) else []
        self._cache_set(cache_key, data)
        return data

    async def create_invoice(self, invoice: InvoiceDTO) -> InvoiceDTO:
        """Create invoice in backend."""
        response = await self._async.post("/invoices", json=self._invoice_payload(invoice))
        if response.status_code == 404:
            return invoice
        response.raise_for_status()
        payload = response.json()
        self._cache_invalidate("invoices:")
        if isinstance(payload, dict):
            return self._coerce_invoice(payload)
        return invoice

    async def get_analytics_summary(self) -> dict:
        """Get analytics summary (async z cache)."""
        cache_key = "analytics:summary"
        cached = self._cache_get(cache_key)
        if cached is not None:
            return cached
        response = await self._async.get("/analytics/summary")
        data = response.json()
        self._cache_set(cache_key, data)
        return data

    async def get_invoice(self, invoice_id: str) -> dict[str, Any]:
        """Pobiera szczegółowe dane jednej faktury."""
        cache_key = f"invoices:{invoice_id}"
        cached = self._cache_get(cache_key)
        if cached is not None:
            return cached

        response = await self._async.get(f"/invoices/{invoice_id}")
        if response.status_code == 404:
            raise Exception("Nie znaleziono faktury w bazie.")
        response.raise_for_status()
        data = response.json()
        self._cache_set(cache_key, data)
        return data

    async def update_invoice(self, invoice_id: str, updated_data: dict[str, Any]) -> bool:
        """Wysyła poprawki — czyści cache po zapisie."""
        response = await self._async.patch(f"/invoices/{invoice_id}", json=updated_data)
        if response.status_code == 200:
            self._cache_invalidate(f"invoices:{invoice_id}")
            self._cache_invalidate("invoices:")
            return True
        response.raise_for_status()
        return False

    async def get_vat_summary(self) -> list[dict[str, Any]]:
        response = await self._async.get("/analytics/vat-summary")
        response.raise_for_status()
        return response.json()

    async def approve_bulk(self, invoice_ids: list[str]) -> bool:
        response = await self._async.post("/invoices/bulk-approve", json={"ids": invoice_ids})
        if response.status_code in (200, 204):
            self._cache_invalidate("invoices:")
            return True
        response.raise_for_status()
        return False

    async def get_high_confidence_ids(self, threshold: float = 0.95) -> list[str]:
        response = await self._async.get(f"/invoices/high-confidence?min={threshold}")
        response.raise_for_status()
        payload = response.json()
        if isinstance(payload, list):
            return [str(item) for item in payload]
        return []

    # ── Chart data API methods ─────────────────────────────────────────

    async def get_monthly_trend(self) -> list[dict[str, Any]]:
        """Get monthly trend data for charts.

        Returns:
            List of {month, total} dicts from /api/analytics/monthly-trend.
        """
        cache_key = "analytics:monthly_trend"
        cached = self._cache_get(cache_key)
        if cached is not None:
            return cached
        try:
            response = await self._async.get("/api/analytics/monthly-trend")
            data = response.json()
            self._cache_set(cache_key, data)
            return data if isinstance(data, list) else []
        except Exception:
            return []

    async def get_cashflow_report(
        self,
        start_date: str | None = None,
        end_date: str | None = None,
        dimension: str = "month",
    ) -> dict[str, Any]:
        """Get cashflow report for charts.

        POST /api/analytics/cashflow

        Args:
            start_date: Start date (ISO format). Defaults to 12 months ago.
            end_date: End date (ISO format). Defaults to today.
            dimension: Time dimension (day, month, quarter, year).

        Returns:
            Dict with "rows" containing {period, total_gross, cumulative_gross}.
        """
        cache_key = f"analytics:cashflow:{dimension}"
        cached = self._cache_get(cache_key)
        if cached is not None:
            return cached

        if start_date is None:
            start_date = pendulum.now().subtract(years=1).format("YYYY-MM-DD")
        if end_date is None:
            end_date = pendulum.now().format("YYYY-MM-DD")

        try:
            response = await self._async.post(
                "/api/analytics/cashflow",
                json={
                    "start_date": start_date,
                    "end_date": end_date,
                    "dimension": dimension,
                    "report_currency": "PLN",
                },
            )
            data = response.json()
            self._cache_set(cache_key, data)
            return data if isinstance(data, dict) else {"rows": []}
        except Exception:
            return {"rows": []}

    async def get_dashboard_summary(self) -> dict[str, Any]:
        """Get dashboard summary stats.

        GET /dashboard/summary

        Returns:
            Dict with booked_today, pending_approval, pending_review, etc.
        """
        cache_key = "dashboard:summary"
        cached = self._cache_get(cache_key)
        if cached is not None:
            return cached
        try:
            response = await self._async.get("/dashboard/summary")
            data = response.json()
            self._cache_set(cache_key, data)
            return data if isinstance(data, dict) else {}
        except Exception:
            return {}

    async def get_pending_count(self) -> int:
        try:
            response = await self._async.get("/invoices/stats/pending")
            return response.json().get("count", 0)
        except Exception:
            return 0

    async def upload_file(self, endpoint: str, file_path: str) -> dict:
        import os
        import anyio

        async with await anyio.open_file(file_path, "rb") as f:
            content = await f.read()
        files = {"file": (os.path.basename(file_path), content, "application/pdf")}
        response = await self._async.post(endpoint, files=files)
        response.raise_for_status()
        return response.json()

    async def get(
        self, endpoint: str, params: dict | None = None, api_version: str = "v1"
    ) -> dict | list:
        """Generic async GET."""
        base = self.base_url
        if api_version != "v1":
            base = base.replace("/api/v1", f"/api/{api_version}")
        try:
            response = await self._async.get(f"{base}{endpoint}", params=params)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"Błąd API {e.response.status_code}: {e.response.text}")
            raise Exception(f"Błąd serwera: {e.response.status_code}")
        except httpx.RequestError as e:
            logger.error(f"Błąd sieci: {e}")
            raise Exception("Nie można połączyć się z serwerem Nexus AI.")

    async def close(self):
        """Zamyka async klient."""
        self._cache.clear()
        await self._async.aclose()

    # ── Helpers ─────────────────────────────────────────────────────────

    @staticmethod
    def build_optimistic(number: str, gross_amount: Decimal) -> InvoiceDTO:
        return InvoiceDTO(
            id=str(uuid4()),
            number=number,
            customer_id="bootstrap-customer",
            amount_net=gross_amount,
            amount_gross=gross_amount,
            currency="PLN",
            created_at=pendulum.now("UTC"),
            pending=True,
        )

    @staticmethod
    def _coerce_invoice(payload: dict[str, Any]) -> InvoiceDTO:
        created_at = payload.get("created_at")
        parsed_created_at = pendulum.now("UTC")
        if isinstance(created_at, str):
            try:
                parsed_created_at = pendulum.parse(created_at.replace("Z", "+00:00"))
            except ValueError:
                pass
        return InvoiceDTO(
            id=str(payload.get("id", uuid4())),
            number=str(payload.get("number", "N/A")),
            customer_id=str(payload.get("customer_id", "N/A")),
            amount_net=Decimal(str(payload.get("amount_net", "0"))),
            amount_gross=Decimal(str(payload.get("amount_gross", "0"))),
            currency=str(payload.get("currency", "PLN")),
            created_at=parsed_created_at,
            pending=bool(payload.get("pending", False)),
        )

    @staticmethod
    def _invoice_payload(invoice: InvoiceDTO) -> dict[str, Any]:
        return {
            "number": invoice.number,
            "customer_id": invoice.customer_id,
            "amount_net": str(invoice.amount_net),
            "amount_gross": str(invoice.amount_gross),
            "currency": invoice.currency,
            "created_at": invoice.created_at.isoformat(),
        }


logger = get_logger("nexus.ui.api")
