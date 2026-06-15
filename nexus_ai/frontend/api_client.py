"""
HTTP communication layer for local Litestar backend.

SUPERMOCE HTTPX:
  - http2=True — HTTP/2 multiplexing dla szybszych requestów
  - httpx.Limits — ochrona connection pool
  - httpx.Timeout — precyzyjne timeouty (connect/read/write/pool)
  - Jednolity NexusApiClient z sync + async metodami
  - async close() — czyste zamykanie połączeń
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
    """SUPERMOC HTTPX: Jednolity klient API z sync + async metodami.

    Zastępuje stare 3 klasy (NexusApiClient, AsyncNexusApiClient, NexusAPIClientUI)
    jedną spójną implementacją z HTTP/2, Limits, Timeout, event_hooks.

    Usage:
        client = NexusApiClient(config)
        # Sync
        invoices = client.list_invoices()
        # Async
        summary = await client.get_analytics_summary()
        # Cleanup
        await client.close()
    """

    def __init__(self, config: ApiConfig | None = None, port: int = 8000, token: str = "", base_url: str = "http://127.0.0.1:8000/api/v1"):
        if config is not None:
            base_url = config.base_url
            token = config.token
            port = config.port

        self.base_url = f"http://127.0.0.1:{port}" if port != 8000 else base_url
        self.token = token
        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"} if token else {"Content-Type": "application/json"}

        # SUPERMOC HTTPX: Współdzielone konfiguracje dla sync + async
        limits = Limits(max_connections=10, max_keepalive_connections=5, keepalive_expiry=30.0)
        default_timeout = Timeout(connect=5.0, read=10.0, write=10.0, pool=300.0)
        download_timeout = Timeout(connect=5.0, read=30.0, write=10.0, pool=300.0)

        self._sync = httpx.Client(
            base_url=self.base_url,
            timeout=default_timeout,
            limits=limits,
            headers=headers,
        )
        self._async = httpx.AsyncClient(
            base_url=self.base_url,
            http2=True,
            trust_env=True,
            timeout=default_timeout,
            limits=limits,
            headers=headers,
            event_hooks={"request": [self._log_request], "response": [self._log_response]},
        )
        logger = get_logger("nexus.ui.api")

    @staticmethod
    async def _log_request(request: httpx.Request) -> None:
        logger = get_logger("nexus.ui.api")
        logger.debug("[HTTP] → %s %s", request.method, request.url)

    @staticmethod
    async def _log_response(response: httpx.Response) -> None:
        logger = get_logger("nexus.ui.api")
        elapsed = response.elapsed.total_seconds() * 1000 if response.elapsed else 0
        logger.debug("[HTTP] ← %s %s (%d, %.1fms)", response.request.method, response.url, response.status_code, elapsed)

    # ── Sync metody ────────────────────────────────────────────────────

    def list_invoices(self) -> list[InvoiceDTO]:
        """Fetch invoice register from local backend."""
        response = self._sync.get("/invoices")
        if response.status_code == 404:
            return []
        response.raise_for_status()
        payload = response.json()
        if not isinstance(payload, list):
            return []
        return [self._coerce_invoice(item) for item in payload if isinstance(item, dict)]

    def create_invoice(self, invoice: InvoiceDTO) -> InvoiceDTO:
        """Create invoice in backend and return persisted representation."""
        response = self._sync.post("/invoices", json=self._invoice_payload(invoice))
        if response.status_code == 404:
            return invoice
        response.raise_for_status()
        payload = response.json()
        if isinstance(payload, dict):
            return self._coerce_invoice(payload)
        return invoice

    def get_analytics_summary(self) -> dict:
        response = self._sync.get("/analytics/summary")
        return response.json()

    # ── Async metody ───────────────────────────────────────────────────

    async def async_list_invoices(self) -> list[Any]:
        """Pobiera listę wszystkich faktur (async)."""
        response = await self._async.get("/invoices")
        response.raise_for_status()
        return response.json()

    async def get_invoice(self, invoice_id: str) -> dict[str, Any]:
        """Pobiera szczegółowe dane jednej faktury."""
        response = await self._async.get(f"/invoices/{invoice_id}")
        if response.status_code == 404:
            raise Exception("Nie znaleziono faktury w bazie.")
        response.raise_for_status()
        return response.json()

    async def update_invoice(self, invoice_id: str, updated_data: dict[str, Any]) -> bool:
        """Wysyła poprawki wprowadzone przez użytkownika w Widoku Detali."""
        response = await self._async.patch(f"/invoices/{invoice_id}", json=updated_data)
        if response.status_code == 200:
            return True
        response.raise_for_status()
        return False

    async def get_vat_summary(self) -> list[dict[str, Any]]:
        """Pobiera statystyki z DuckDB przez API."""
        response = await self._async.get("/analytics/vat-summary")
        response.raise_for_status()
        return response.json()

    async def approve_bulk(self, invoice_ids: list[str]) -> bool:
        """Wysyła żądanie masowego zatwierdzenia faktur."""
        response = await self._async.post("/invoices/bulk-approve", json={"ids": invoice_ids})
        if response.status_code in (200, 204):
            return True
        response.raise_for_status()
        return False

    async def get_high_confidence_ids(self, threshold: float = 0.95) -> list[str]:
        """Pobiera ID faktur, które AI oceniło jako pewne."""
        response = await self._async.get(f"/invoices/high-confidence?min={threshold}")
        response.raise_for_status()
        payload = response.json()
        if isinstance(payload, list):
            return [str(item) for item in payload]
        return []

    async def get_pending_count(self) -> int:
        """Pobiera liczbę faktur oczekujących na przetworzenie."""
        try:
            response = await self._async.get("/invoices/stats/pending")
            return response.json().get("count", 0)
        except Exception:
            return 0

    async def upload_file(self, endpoint: str, file_path: str) -> dict:
        """Wysyła plik PDF na serwer."""
        import os
        import anyio
        async with await anyio.open_file(file_path, "rb") as f:
            content = await f.read()
        files = {"file": (os.path.basename(file_path), content, "application/pdf")}
        response = await self._async.post(endpoint, files=files)
        response.raise_for_status()
        return response.json()

    async def get(self, endpoint: str, params: dict = None, api_version: str = "v1") -> dict | list:
        """Generic async GET (kompatybilność z NexusAPIClientUI)."""
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
        """Zamyka sync + async klienty."""
        self._sync.close()
        await self._async.aclose()

    # ── Helpers ─────────────────────────────────────────────────────────

    @staticmethod
    def build_optimistic(number: str, gross_amount: Decimal) -> InvoiceDTO:
        """Build local optimistic invoice before backend confirmation."""
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


# ── Wrapper kompatybilności wstecznej ──────────────────────────────────


class AsyncNexusApiClient:
    """DEPRECATED: Użyj NexusApiClient z async metodami.

    Zachowany dla kompatybilności wstecznej.
    """
    def __init__(self, port: int, token: str):
        import warnings
        warnings.warn("AsyncNexusApiClient is deprecated. Use NexusApiClient instead.", DeprecationWarning, stacklevel=2)
        self._impl = NexusApiClient(port=port, token=token)

    async def list_invoices(self): return await self._impl.async_list_invoices()
    async def get_invoice(self, invoice_id): return await self._impl.get_invoice(invoice_id)
    async def update_invoice(self, invoice_id, data): return await self._impl.update_invoice(invoice_id, data)
    async def get_vat_summary(self): return await self._impl.get_vat_summary()
    async def approve_bulk(self, ids): return await self._impl.approve_bulk(ids)
    async def get_high_confidence_ids(self, threshold=0.95): return await self._impl.get_high_confidence_ids(threshold)
    async def close(self): await self._impl.close()


class NexusAPIClientUI:
    """DEPRECATED: Użyj NexusApiClient z async metodami.

    Zachowany dla kompatybilności wstecznej.
    """
    def __init__(self, base_url: str = "http://127.0.0.1:8000/api/v1", token: str = None):
        import warnings
        warnings.warn("NexusAPIClientUI is deprecated. Use NexusApiClient instead.", DeprecationWarning, stacklevel=2)
        self._impl = NexusApiClient(base_url=base_url, token=token or "")

    async def get(self, *args, **kwargs): return await self._impl.get(*args, **kwargs)
    async def upload_file(self, *args, **kwargs): return await self._impl.upload_file(*args, **kwargs)
    async def get_pending_count(self): return await self._impl.get_pending_count()
    async def approve_bulk(self, ids): return await self._impl.approve_bulk(ids)
    async def get_high_confidence_ids(self, threshold=0.95): return await self._impl.get_high_confidence_ids(threshold)
    async def close(self): await self._impl.close()


def create_http_client(config: ApiConfig) -> httpx.Client:
    """SUPERMOC HTTPX: Tworzy globalny klient HTTP z Limits + HTTP/2 Ready.

    DEPRECATED: Użyj NexusApiClient(config) zamiast tego.
    """
    import warnings
    warnings.warn("create_http_client() is deprecated. Use NexusApiClient(config) instead.", DeprecationWarning, stacklevel=2)
    return httpx.Client(
        base_url=config.base_url,
        timeout=Timeout(10.0),
        limits=Limits(max_connections=10),
        headers={"Authorization": f"Bearer {config.token}"},
    )


logger = get_logger("nexus.ui.api")
