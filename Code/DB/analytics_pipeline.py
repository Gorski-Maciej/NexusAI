from __future__ import annotations

from datetime import datetime
from pathlib import Path
import sqlite3

import dlt
import polars as pl
from pydantic import BaseModel, Field, field_validator


class InvoiceEventRecord(BaseModel):
    id: str
    issue_date: str | None = None
    contractor_nip: str | None = None
    amount_gross: float = Field(ge=0.0)
    currency: str = "PLN"
    status: str | None = None
    updated_at: str | None = None
    loaded_at: str

    @field_validator("currency")
    @classmethod
    def validate_currency(cls, value: str) -> str:
        normalized = value.strip().upper()
        if len(normalized) != 3 or not normalized.isalpha():
            raise ValueError("Invalid ISO currency code")
        return normalized


def _invoice_events_source(sqlite_path: str):
    @dlt.resource(name="invoice_events", write_disposition="append", primary_key="id")
    def invoice_events():
        with sqlite3.connect(sqlite_path) as conn:
            rows = conn.execute(
                """
                SELECT id, issue_date, contractor_nip, amount_gross, currency, status, updated_at
                FROM invoices
                ORDER BY updated_at ASC
                """
            ).fetchall()
        for row in rows:
            record = InvoiceEventRecord(
                id=row[0],
                issue_date=row[1],
                contractor_nip=row[2],
                amount_gross=float(row[3] or 0.0),
                currency=row[4] or "PLN",
                status=row[5],
                updated_at=row[6],
                loaded_at=datetime.utcnow().isoformat(),
            )
            yield record.model_dump()

    return invoice_events


def run_invoice_events_pipeline(sqlite_path: Path, duckdb_path: Path) -> dict[str, object]:
    pipeline = dlt.pipeline(
        pipeline_name="nexus_invoice_events",
        destination=dlt.destinations.duckdb(str(duckdb_path)),
        dataset_name="nexus_analytics",
    )
    load_info = pipeline.run(_invoice_events_source(str(sqlite_path))())
    return {"load_info": str(load_info)}


def transform_cashflow_with_polars(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    if not rows:
        return []
    frame = pl.DataFrame(rows)
    result = (
        frame.with_columns(
            pl.col("issue_date").str.to_date(strict=False),
            pl.when(pl.col("status") == "PAID").then(pl.col("amount_gross")).otherwise(0.0).alias("paid_amount"),
        )
        .group_by_dynamic("issue_date", every="1d")
        .agg(pl.sum("paid_amount").alias("daily_paid"))
        .sort("issue_date")
        .with_columns(pl.col("daily_paid").cum_sum().alias("running_paid"))
    )
    return result.to_dicts()
