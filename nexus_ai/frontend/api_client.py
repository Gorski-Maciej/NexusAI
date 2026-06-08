"""HTTP communication layer for local Litestar backend."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Any
from uuid import uuid4

import httpx
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
    created_at: datetime
    pending: bool = False

@dataclass(slots=True)
class ApiConfig:
    """API runtime configuration from bootstrap handshake."""
    port: int
    token: str

    @property
    def base_url(self) -> str:
        return f"http://127.0.0.1:{self.port}"

def create_http_client(config: ApiConfig) -> httpx.Client:
    """Create global HTTPX client with connection limits and JWT header."""
    return httpx.Client(
        base_url=config.base_url,
        timeout=10.0,
        limits=httpx.Limits(max_connections=10),
        headers={"Authorization": f"Bearer {config.token}"}
    )

class NexusApiClient:
    """Thin typed wrapper around HTTPX for frontend data access."""
    def __init__(self, client: httpx.Client) -> None:
        self._client = client

    def list_invoices(self) -> list[InvoiceDTO]:
        """Fetch invoice register from local backend."""
        response = self._client.get("/invoices")
        if response.status_code == 404:
            return []
        response.raise_for_status()
        payload = response.json()
        if not isinstance(payload, list):
            return []
        return [self._coerce_invoice(item) for item in payload if isinstance(item, dict)]

    def create_invoice(self, invoice: InvoiceDTO) -> InvoiceDTO:
        """Create invoice in backend and return persisted representation."""
        response = self._client.post("/invoices", json=self._invoice_payload(invoice))
        if response.status_code == 404:
            # Backend endpoint can be wired later; keep optimistic item for now.
            return invoice
        response.raise_for_status()
        payload = response.json()
        if isinstance(payload, dict):
            return self._coerce_invoice(payload)
        return invoice

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

    def get_analytics_summary(self) -> dict:
        # Wywołuje endpoint w Litestar, który robi:
        # SELECT sum(amount_gross), count(*) FROM invoices_replica
        response = self._client.get("/analytics/summary")
        return response.json()

# Wariant asynchroniczny API klienta połączony z resztą definicji
class AsyncNexusApiClient:
    def __init__(self, port: int, token: str):
        self.base_url = f"http://127.0.0.1:{port}"
        self.token = token
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            headers={"Authorization": f"Bearer {self.token}"},
            timeout=10.0
        )

    async def list_invoices(self) -> list[Any]:
        """Pobiera listę wszystkich faktur."""
        response = await self.client.get("/invoices")
        response.raise_for_status()
        return response.json()

    async def get_invoice(self, invoice_id: str) -> dict[str, Any]:
        """Pobiera szczegółowe dane jednej faktury."""
        response = await self.client.get(f"/invoices/{invoice_id}")
        if response.status_code == 404:
            raise Exception("Nie znaleziono faktury w bazie.")
        response.raise_for_status()
        return response.json()

    async def update_invoice(self, invoice_id: str, updated_data: dict[str, Any]) -> bool:
        """Wysyła poprawki wprowadzone przez użytkownika w Widoku Detali."""
        response = await self.client.patch(f"/invoices/{invoice_id}", json=updated_data)
        if response.status_code == 200:
            return True
        response.raise_for_status()
        return False

    async def get_vat_summary(self) -> list[dict[str, Any]]:
        """Pobiera statystyki z DuckDB przez API."""
        response = await self.client.get("/analytics/vat-summary")
        response.raise_for_status()
        return response.json()



    async def approve_bulk(self, invoice_ids: list[str]) -> bool:
        """Wysyła żądanie masowego zatwierdzenia faktur."""
        response = await self.client.post("/invoices/bulk-approve", json={"ids": invoice_ids})
        if response.status_code in (200, 204):
            return True
        response.raise_for_status()
        return False

    async def get_high_confidence_ids(self, threshold: float = 0.95) -> list[str]:
        """Pobiera ID faktur, które AI oceniło jako pewne."""
        response = await self.client.get(f"/invoices/high-confidence?min={threshold}")
        response.raise_for_status()
        payload = response.json()
        if isinstance(payload, list):
            return [str(item) for item in payload]
        return []

    async def close(self):
        """Zamyka połączenie (ważne przy wyłączaniu aplikacji)."""
        await self.client.aclose()


logger = get_logger("nexus.ui.api")

class NexusAPIClientUI:
    """Centralny punkt komunikacji UI z backendem Litestar."""
    def __init__(self, base_url: str = "http://127.0.0.1:8000/api/v1", token: str = None):
        self.base_url = base_url
        self.token = token
        self._client = httpx.AsyncClient(timeout=30.0)

    def _get_headers(self) -> dict:
        headers = {"Content-Type": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        return headers

    async def get(self, endpoint: str, params: dict = None, api_version: str = "v1") -> dict | list:
        try:
            base = self.base_url
            if api_version != "v1":
                base = base.replace("/api/v1", f"/api/{api_version}")
            response = await self._client.get(
                f"{base}{endpoint}",
                headers=self._get_headers(),
                params=params
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"Błąd API {e.response.status_code}: {e.response.text}")
            raise Exception(f"Błąd serwera: {e.response.status_code}")
        except httpx.RequestError as e:
            logger.error(f"Błąd sieci: {e}")
            raise Exception("Nie można połączyć się z serwerem Nexus AI.")

    async def upload_file(self, endpoint: str, file_path: str) -> dict:
        """Specjalna metoda do wysyłania plików PDF na serwer."""
        import os

        import aiofiles
        try:
            async with aiofiles.open(file_path, 'rb') as f:
                content = await f.read()
            files = {'file': (os.path.basename(file_path), content, 'application/pdf')}
            headers = {}
            if self.token:
                headers["Authorization"] = f"Bearer {self.token}"
            response = await self._client.post(
                f"{self.base_url}{endpoint}",
                headers=headers,
                files=files
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Błąd uploadu: {e}")
            raise

    async def get_pending_count(self) -> int:
        """Pobiera liczbę faktur oczekujących na przetworzenie."""
        try:
            response = await self._client.get(f"{self.base_url}/invoices/stats/pending", headers=self._get_headers())
            return response.json().get("count", 0)
        except Exception:
            return 0



    async def approve_bulk(self, invoice_ids: list[str]) -> bool:
        """UI helper for bulk invoice approval action."""
        try:
            response = await self._client.post(
                f"{self.base_url}/invoices/bulk-approve",
                headers=self._get_headers(),
                json={"ids": invoice_ids},
            )
            if response.status_code in (200, 204):
                return True
            response.raise_for_status()
            return False
        except Exception as e:
            logger.error(f"Błąd masowego zatwierdzania: {e}")
            return False

    async def get_high_confidence_ids(self, threshold: float = 0.95) -> list[str]:
        """Pobiera ID faktur o wysokiej pewności z modelu AI."""
        try:
            response = await self._client.get(
                f"{self.base_url}/invoices/high-confidence",
                headers=self._get_headers(),
                params={"min": threshold},
            )
            response.raise_for_status()
            payload = response.json()
            if isinstance(payload, list):
                return [str(item) for item in payload]
            return []
        except Exception as e:
            logger.error(f"Błąd pobierania high-confidence IDs: {e}")
            return []

    async def close(self):
        await self._client.aclose()
