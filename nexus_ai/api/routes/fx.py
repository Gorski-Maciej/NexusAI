"""FX / Exchange Rates management endpoints (Rozwiązanie 28)."""

from __future__ import annotations

from typing import Any

from litestar import Controller, post
from litestar.enums import MediaType
from litestar.exceptions import ClientException

from nexus_ai.api.dto import FXUploadRatesDTO, TAG_FX


class FXController(Controller):
    """FX Management — upload NBP rates CSV and manage exchange rates cache.

    Provides:
      - POST /api/v1/system/fx/upload-rates: ręczne wczytanie kursów NBP z CSV
    """

    path = "/api/v1/system/fx"
    tags = [TAG_FX]

    @post(
        "/upload-rates",
        media_type=MediaType.JSON,
        return_dto=FXUploadRatesDTO,
        summary="Upload FX rates CSV",
        description="Uploads NBP exchange rates from a CSV file. Supports CSV content type or JSON with csv_content field (Rozwiązanie 28).",
        operation_id="uploadFxRates",
    )
    async def upload_rates(
        self,
        request: Any,
    ) -> dict[str, Any]:
        """Ręczne wczytanie kursów NBP z pliku CSV (Rozwiązanie 28).

        Request body: text/csv lub application/json z polem 'csv_content'.
        Format CSV:
          currency_code,rate_date,avg_rate,table_no
          EUR,2025-01-15,4.2500,001/A/NBP/2025

        Returns: { "imported": N, "errors": M }
        """
        try:
            # Determine content type and read CSV content
            content_type = request.headers.get("content-type", "").lower()

            # Parse body based on content type
            if "csv" in content_type or "text/plain" in content_type:
                csv_content = await request.body()
                csv_text = csv_content.decode("utf-8")
            elif "json" in content_type:
                body = await request.json()
                csv_text = body.get("csv_content", "")
                if not csv_text:
                    raise ClientException("Missing csv_content in JSON body")
            else:
                # Try to read as raw text
                csv_content = await request.body()
                csv_text = csv_content.decode("utf-8")

            # Import and run through ForexEngine
            try:
                from nexus_ai.services.forex_engine import ForexEngine
            except ImportError:
                return {
                    "result": "ERROR",
                    "error": "ForexEngine not available in this environment",
                    "imported": 0,
                    "errors": 1,
                }

            from core.config import AppConfig
            from db.analytics import DuckDBManager

            config = AppConfig()
            duckdb = DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path)
            try:
                engine = ForexEngine(
                    duckdb_manager=duckdb,
                    tb_client=None,
                    account_receivable=0,
                    account_fx_gain=0,
                    account_fx_loss=0,
                )
                result = engine.upload_rates_csv(csv_text)
                return {
                    "result": "OK",
                    "imported": result["imported"],
                    "errors": result["errors"],
                }
            finally:
                duckdb.close()

        except Exception as exc:
            return {
                "result": "ERROR",
                "error": str(exc),
                "imported": 0,
                "errors": 0,
            }
