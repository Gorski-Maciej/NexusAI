"""
Shared BackgroundTask helper functions for fire-and-forget operations.

All helper functions defined here are designed to be used with Litestar's
``BackgroundTask`` (from ``litestar.background_tasks``) for fire-and-forget
execution after the HTTP response has been sent to the client.

  - Zamiast EventEmitter.emit_*() używamy broker.kick("event_emit_*", ...)
  - Deterministic task_id przez broker._task_id_generator -- JetStream deduplikacja
  - Mniej zależności: nie trzeba przekazywać event_emitter przez app.state

Each function:
  - Accepts only keyword arguments (for ``BackgroundTask(..., kwarg=val)``)
  - Handles all exceptions internally (fire-and-forget pattern)
  - Logs success/failure via ``structlog``
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

from nexus_ai.core.broker import broker

logger = get_logger("nexus.api.background_tasks")


async def emit_decision_overridden_bg(
    invoice_id: str,
    original_decision: str,
    user_decision: str,
    user_id: str,
    metadata: dict[str, Any],
) -> None:
    """Fire-and-forget: emituje DecisionOverridden przez broker.kick().

    Używany przez ``BackgroundTask`` w triage endpointach (``resolve``)
    oraz jako część ``emit_decision_and_notification_bg`` w autopilot.

    Args:
        invoice_id: ID faktury.
        original_decision: Oryginalna decyzja systemu (np. ``SUGGEST``, ``AUTO_POST``).
        user_decision: Decyzja użytkownika (np. ``CONFIRM_POST``, ``VOID``, ``ACCEPTED``, ``REJECTED``).
        user_id: ID użytkownika.
        metadata: Dodatkowe metadane.
    """
    try:
        await broker.kick(
            "event_emit_decision_overridden",
            invoice_id=invoice_id,
            original_decision=original_decision,
            user_decision=user_decision,
            user_id=user_id,
            metadata=metadata,
        )
        logger.info(
            "[EVENT] DecisionOverridden kicked (bg) for invoice_id=%s",
            invoice_id,
        )
    except Exception as event_err:
        logger.warning(
            "[EVENT] Failed to kick DecisionOverridden (bg) for %s: %s",
            invoice_id,
            event_err,
        )


async def emit_invoice_created_bg(
    invoice_id: str,
    filename: str,
    file_path: str,
    metadata: dict[str, Any],
) -> None:
    """Fire-and-forget: emituje InvoiceCreated przez broker.kick().

    Używany przez ``BackgroundTask`` w ``upload_invoice``.

    Args:
        invoice_id: ID faktury.
        filename: Nazwa pliku.
        file_path: Ścieżka do pliku.
        metadata: Dodatkowe metadane.
    """
    try:
        await broker.kick(
            "event_emit_invoice_created",
            invoice_id=invoice_id,
            number=filename,
            file_path=file_path,
            metadata=metadata,
        )
        logger.info(
            "[EVENT] InvoiceCreated kicked (bg) for invoice_id=%s",
            invoice_id,
        )
    except Exception as event_err:
        logger.warning(
            "[EVENT] Failed to kick InvoiceCreated (bg) for %s: %s",
            invoice_id,
            event_err,
        )


async def emit_decision_and_notification_bg(
    invoice_id: str,
    original_decision: str,
    user_decision: str,
    user_id: str,
    metadata: dict[str, Any],
    notification_title: str,
) -> None:
    """Fire-and-forget: emituje DecisionOverridden + notification.

    Używany przez ``BackgroundTask`` w autopilot ``accept_decision`` i ``reject_decision``.
    Łączy emisję eventu i wysyłkę notyfikacji w jednym BackgroundTask.

    Args:
        invoice_id: ID faktury.
        original_decision: Oryginalna decyzja systemu.
        user_decision: Decyzja użytkownika.
        user_id: ID użytkownika.
        metadata: Dodatkowe metadane.
        notification_title: Tytuł notyfikacji.
    """
    # Emituj event przez Taskiq
    try:
        await emit_decision_overridden_bg(
            invoice_id=invoice_id,
            original_decision=original_decision,
            user_decision=user_decision,
            user_id=user_id,
            metadata=metadata,
        )
    except Exception as event_err:
        logger.warning(
            "[EVENT] Failed to emit DecisionOverridden (bg) in notification task: %s",
            event_err,
        )
