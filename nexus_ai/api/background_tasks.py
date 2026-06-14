"""Shared BackgroundTask helper functions for fire-and-forget operations.

All helper functions defined here are designed to be used with Litestar's
``BackgroundTask`` (from ``litestar.background_tasks``) for fire-and-forget
execution after the HTTP response has been sent to the client.

Each function:
  - Accepts only keyword arguments (for ``BackgroundTask(..., kwarg=val)``)
  - Handles all exceptions internally (fire-and-forget pattern)
  - Logs success/failure via ``structlog``
"""

from __future__ import annotations

from typing import Any

import anyio

from structlog import get_logger

from nexus_ai.events.event_emitter import EventEmitter
from nexus_ai.services.notification_service import NotificationService

logger = get_logger("nexus.api.background_tasks")


async def emit_decision_overridden_bg(
    event_emitter: EventEmitter,
    invoice_id: str,
    original_decision: str,
    user_decision: str,
    user_id: str,
    metadata: dict[str, Any],
) -> None:
    """Fire-and-forget: emituje DecisionOverridden event po wysłaniu odpowiedzi.

    Używany przez ``BackgroundTask`` w triage endpointach (``resolve``)
    oraz jako część ``emit_decision_and_notification_bg`` w autopilot.

    Args:
        event_emitter: Instancja EventEmitter.
        invoice_id: ID faktury.
        original_decision: Oryginalna decyzja systemu (np. ``SUGGEST``, ``AUTO_POST``).
        user_decision: Decyzja użytkownika (np. ``CONFIRM_POST``, ``VOID``, ``ACCEPTED``, ``REJECTED``).
        user_id: ID użytkownika.
        metadata: Dodatkowe metadane.
    """
    try:
        await event_emitter.emit_decision_overridden(
            invoice_id=invoice_id,
            original_decision=original_decision,
            user_decision=user_decision,
            user_id=user_id,
            metadata=metadata,
        )
        logger.info(
            "[EVENT] DecisionOverridden emitted (bg) for invoice_id=%s",
            invoice_id,
        )
    except Exception as event_err:
        logger.warning(
            "[EVENT] Failed to emit DecisionOverridden (bg) for %s: %s",
            invoice_id,
            event_err,
        )


async def emit_invoice_created_bg(
    event_emitter: EventEmitter,
    invoice_id: str,
    filename: str,
    file_path: str,
    metadata: dict[str, Any],
) -> None:
    """Fire-and-forget: emituje InvoiceCreated event po wysłaniu odpowiedzi.

    Używany przez ``BackgroundTask`` w ``upload_invoice``.

    Args:
        event_emitter: Instancja EventEmitter.
        invoice_id: ID faktury.
        filename: Nazwa pliku.
        file_path: Ścieżka do pliku.
        metadata: Dodatkowe metadane.
    """
    try:
        await event_emitter.emit_invoice_created(
            invoice_id=invoice_id,
            number=filename,
            file_path=file_path,
            metadata=metadata,
        )
        logger.info(
            "[EVENT] InvoiceCreated emitted (bg) for invoice_id=%s",
            invoice_id,
        )
    except Exception as event_err:
        logger.warning(
            "[EVENT] Failed to emit InvoiceCreated (bg) for %s: %s",
            invoice_id,
            event_err,
        )


async def emit_decision_and_notification_bg(
    event_emitter: EventEmitter | None,
    notification_service: NotificationService | None,
    invoice_id: str,
    original_decision: str,
    user_decision: str,
    user_id: str,
    metadata: dict[str, Any],
    notification_title: str,
) -> None:
    """Fire-and-forget: emituje DecisionOverridden event + wysyła notyfikację.

    Używany przez ``BackgroundTask`` w autopilot ``accept_decision`` i ``reject_decision``.
    Łączy emisję eventu i wysyłkę notyfikacji w jednym BackgroundTask.

    Args:
        event_emitter: Instancja EventEmitter (może być ``None`` — wtedy pomija event).
        notification_service: Instancja NotificationService (może być ``None`` — wtedy pomija notyfikację).
        invoice_id: ID faktury.
        original_decision: Oryginalna decyzja systemu.
        user_decision: Decyzja użytkownika.
        user_id: ID użytkownika.
        metadata: Dodatkowe metadane.
        notification_title: Tytuł notyfikacji.
    """
    # Emituj event (jeśli dostępny EventEmitter)
    if event_emitter is not None:
        try:
            await emit_decision_overridden_bg(
                event_emitter=event_emitter,
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

    # Wyślij notyfikację (jeśli dostępny NotificationService)
    if notification_service is not None:
        try:
            await anyio.to_thread.run_sync(
                notification_service._add_notification,
                user_id="anonymous",
                title=notification_title,
                message=f"Faktura {invoice_id[:8]}...",
                notification_type="user_action",
                reference_type="invoice",
                reference_id=invoice_id,
            )
        except Exception as notif_err:
            logger.warning(
                "[NOTIF] Failed to send notification (bg): %s",
                notif_err,
            )
