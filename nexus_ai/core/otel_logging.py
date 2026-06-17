"""
core/otel_logging.py — OTel Logging Bridge dla NexusAI.

SUPERMOCE:
  1. OTel LoggingHandler — każdy log ma trace_id, span_id z bieżącego kontekstu
  2. Korelacja logów z trace'ami — logi są automatycznie powiązane z aktywnym spanem
  3. OTLP export — logi mogą być wysyłane do OTLP endpointu
  4. Opcjonalne — działa tylko gdy OTel jest dostępny, nie psuje istniejącego systemu

Zgodnie z aa3fvcx.txt: OpenTelemetry (API + SDK) jako standard dla całej telemetrii.
Logi + trace'e + metryki = pełna obserwowalność.
"""

from __future__ import annotations

import logging
import os
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.otel_logging")

# ── SUPERMOC: OTel Logging Handler ───────────────────────────────────────


def setup_otel_logging(resource: Any | None = None) -> Any | None:
    """SUPERMOC: Konfiguruje OTel LoggingHandler wysyłający logi do OTLP.

    Każdy log przechodzący przez ten handler jest automatycznie wzbogacony
    o trace_id, span_id z bieżącego kontekstu OTel (ContextVar).

    Args:
        resource: Resource do LoggerProvider (opcjonalnie).

    Returns:
        LoggerProvider lub None jeśli OTel Logs SDK nie jest dostępny.
    """
    try:
        from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
        from opentelemetry.sdk._logs.export import BatchLogRecordProcessor

        if resource is None:
            from nexus_ai.core.otel_config import create_otel_resource
            resource = create_otel_resource()

        # SUPERMOC: LoggerProvider z BatchLogRecordProcessor
        log_provider = LoggerProvider(resource=resource)

        # SUPERMOC: OTLP exporter dla logów (opcjonalny)
        otlp_endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "")
        if otlp_endpoint:
            try:
                from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter

                otlp_exporter = OTLPLogExporter(
                    endpoint=otlp_endpoint,
                    insecure=True,
                    timeout=5,
                )
                log_provider.add_log_record_processor(
                    BatchLogRecordProcessor(otlp_exporter)
                )
                logger.info("[OTEL-LOGGING] OTLP log exporter configured: %s", otlp_endpoint)
            except Exception as exc:
                logger.debug("[OTEL-LOGGING] OTLP log exporter failed: %s", exc)

        # Console log exporter w dev
        if os.getenv("NEXUS_ENV", "dev") == "dev":
            try:
                from opentelemetry.sdk._logs.export import ConsoleLogExporter

                log_provider.add_log_record_processor(
                    BatchLogRecordProcessor(ConsoleLogExporter())
                )
            except Exception:
                pass

        # SUPERMOC: LoggingHandler — wstrzykuje trace_id/span_id do każdego logu
        handler = LoggingHandler(
            logger_provider=log_provider,
            level=logging.WARNING,  # Logi WARNING+ trafiają do OTel
        )

        # SUPERMOC: Dodaj handler do root loggera — wszystkie logi (w tym z bibliotek)
        root_logger = logging.getLogger()
        root_logger.addHandler(handler)

        logger.info(
            "[OTEL-LOGGING] OTel LoggingHandler added to root logger (level=WARNING+)"
        )
        return log_provider

    except ImportError as exc:
        logger.debug("[OTEL-LOGGING] OTel Logs SDK not available: %s", exc)
        return None
    except Exception as exc:
        logger.debug("[OTEL-LOGGING] Setup failed: %s", exc)
        return None
