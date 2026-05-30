"""OpenTelemetry metrics for Prometheus exposition (Rozwiązanie 34)."""
from __future__ import annotations

from typing import Any

# Global meter set by state.py on startup
_meter: Any = None

# Counters
_invoices_processed_total: Any = None
_invoices_failed_total: Any = None
_ai_inference_duration_seconds: Any = None
_ocr_duration_seconds: Any = None
_http_request_duration_seconds: Any = None


def _init_counters(meter: Any) -> None:
    """Initialize all counters with the given meter."""
    global _invoices_processed_total, _invoices_failed_total
    global _ai_inference_duration_seconds, _ocr_duration_seconds
    global _http_request_duration_seconds

    _invoices_processed_total = meter.create_counter(
        name="invoices_processed_total",
        description="Total number of processed invoices",
        unit="1",
    )
    _invoices_failed_total = meter.create_counter(
        name="invoices_failed_total",
        description="Total number of failed invoice processing attempts",
        unit="1",
    )
    _ai_inference_duration_seconds = meter.create_histogram(
        name="ai_inference_duration_seconds",
        description="Duration of AI inference calls",
        unit="s",
    )
    _ocr_duration_seconds = meter.create_histogram(
        name="ocr_duration_seconds",
        description="Duration of OCR processing",
        unit="s",
    )
    _http_request_duration_seconds = meter.create_histogram(
        name="http_request_duration_seconds",
        description="HTTP request duration",
        unit="s",
    )


def record_invoice_processed(status: str = "success") -> None:
    """Record an invoice processing result."""
    global _invoices_processed_total, _invoices_failed_total
    if _invoices_processed_total is not None and status == "success":
        _invoices_processed_total.add(1, {"status": "success"})
    if _invoices_failed_total is not None and status == "failed":
        _invoices_failed_total.add(1, {"status": "failed"})


def record_ai_inference_duration(duration_seconds: float, model: str = "unknown") -> None:
    """Record AI inference duration."""
    global _ai_inference_duration_seconds
    if _ai_inference_duration_seconds is not None:
        _ai_inference_duration_seconds.record(duration_seconds, {"model": model})


def record_ocr_duration(duration_seconds: float) -> None:
    """Record OCR processing duration."""
    global _ocr_duration_seconds
    if _ocr_duration_seconds is not None:
        _ocr_duration_seconds.record(duration_seconds)
