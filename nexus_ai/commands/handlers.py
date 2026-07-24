"""
Command Handlers — konkretne implementacje dla komend biznesowych.

INNOWACJA #1 z Raportu v7.0: Każdy handler ma pojedynczą odpowiedzialność.
Każda komenda przechodzi przez validate → handle → publish events.
"""

from __future__ import annotations

from decimal import Decimal
from typing import TYPE_CHECKING, Any

from structlog import get_logger

from nexus_ai.commands.bus import Command, CommandHandler, CommandResult

if TYPE_CHECKING:
    from nexus_ai.events.event_store import EventStore
else:
    EventStore = Any

logger = get_logger("nexus.commands.handlers")


# ── Invoice Commands ──────────────────────────────────────────────────────


class InvoiceSubmitCommand(Command):
    """Komenda: Prześlij fakturę do przetwarzania."""

    invoice_id: str = ""
    number: str = ""
    contractor_nip: str = ""
    contractor_name: str = ""
    amount_net: str = "0.00"  # Decimal jako string (kompatybilność z msgspec)
    amount_gross: str = "0.00"
    currency: str = "PLN"
    category: str = ""
    issue_date: str = ""
    file_path: str = ""


class ApproveInvoiceCommand(Command):
    """Komenda: Zatwierdź fakturę (auto-post lub manual)."""

    invoice_id: str = ""
    decision_id: str = ""
    auto_approved: bool = False
    confidence: float = 0.0
    approved_by: str = "system"


class RejectInvoiceCommand(Command):
    """Komenda: Odrzuć fakturę."""

    invoice_id: str = ""
    reason: str = ""
    rejected_by: str = "system"


class BlockInvoiceCommand(Command):
    """Komenda: Zablokuj fakturę (fraud suspicion)."""

    invoice_id: str = ""
    reason: str = ""
    fraud_score: float = 0.0
    blocked_by: str = "risk_guard"


class MarkInvoicePaidCommand(Command):
    """Komenda: Oznacz fakturę jako opłaconą."""

    invoice_id: str = ""
    payment_amount: str = "0.00"
    paid_at: str = ""
    transaction_id: str = ""


# ── Command Handlers ──────────────────────────────────────────────────────


class InvoiceSubmitHandler(CommandHandler[InvoiceSubmitCommand]):
    """Handler dla InvoiceSubmitCommand — tworzy nową fakturę przez agregat."""

    __slots__ = ("_event_store", "_InvoiceAggregate", "_Money")

    def __init__(self, event_store: Any = None) -> None:
        self._event_store = event_store
        # Lazy import tylko raz — nie per dispatch
        from nexus_ai.domain.values import Money as _M
        from nexus_ai.domain.aggregates import InvoiceAggregate as _IA
        self._Money = _M
        self._InvoiceAggregate = _IA

    async def validate(self, command: InvoiceSubmitCommand) -> str | None:
        """Walidacja przed utworzeniem faktury."""
        if not command.contractor_nip:
            return "contractor_nip is required"
        if not command.invoice_id:
            return "invoice_id is required"
        try:
            net = Decimal(command.amount_net)
            gross = Decimal(command.amount_gross)
            if net < 0:
                return "amount_net cannot be negative"
            if gross < 0:
                return "amount_gross cannot be negative"
            if net > gross:
                return "amount_net cannot exceed amount_gross"
        except Exception as exc:
            return f"Invalid amount format: {exc}"
        return None

    async def handle(self, command: InvoiceSubmitCommand) -> CommandResult:
        """Utwórz fakturę przez InvoiceAggregate i zapisz zdarzenia."""
        try:
            net = self._Money(amount=Decimal(command.amount_net), currency=command.currency)
            gross = self._Money(amount=Decimal(command.amount_gross), currency=command.currency)

            # Użyj ID z komendy jako aggregate_id aby eventy były spójne
            import uuid
            aggregate_id = command.invoice_id or uuid.uuid4().hex

            aggregate = self._InvoiceAggregate.create(
                number=command.number,
                contractor_nip=command.contractor_nip,
                amount_net=net,
                amount_gross=gross,
                currency=command.currency,
            )
            aggregate.id = aggregate_id
            events = aggregate.collect_events()

            # Zapis do Event Store
            if self._event_store:
                await self._event_store.append_events(
                    aggregate_type="invoice",
                    aggregate_id=aggregate.id,
                    events=events,
                    expected_version=0,
                )

            logger.info(
                "[CMDHANDLER] Invoice submitted: id=%s number=%s nip=%s",
                aggregate.id,
                command.number,
                command.contractor_nip,
            )

            return CommandResult(
                success=True,
                command_id=command.command_id,
                message=f"Invoice {command.number} submitted successfully",
                events_published=len(events),
                aggregate_id=aggregate.id,
                aggregate_version=aggregate.version,
            )
        except Exception as exc:
            logger.exception("[CMDHANDLER] Invoice submit failed: %s", exc)
            return CommandResult(
                success=False,
                command_id=command.command_id,
                message=f"Invoice submit failed: {exc}",
                error_detail=str(exc),
            )


class ApproveInvoiceHandler(CommandHandler[ApproveInvoiceCommand]):
    """Handler dla ApproveInvoiceCommand — zatwierdza fakturę."""

    __slots__ = ("_event_store", "_InvoiceAggregate")

    def __init__(self, event_store: Any = None) -> None:
        self._event_store = event_store
        from nexus_ai.domain.aggregates import InvoiceAggregate as _IA
        self._InvoiceAggregate = _IA

    async def validate(self, command: ApproveInvoiceCommand) -> str | None:
        if not command.invoice_id:
            return "invoice_id is required"
        if not 0.0 <= command.confidence <= 1.0:
            return "confidence must be 0.0-1.0"
        return None

    async def handle(self, command: ApproveInvoiceCommand) -> CommandResult:
        """Zatwierdź fakturę."""
        try:
            # Rekonstytuuj agregat z Event Store
            if not self._event_store:
                return CommandResult(
                    success=False,
                    command_id=command.command_id,
                    message="EventStore not available for aggregate reconstitution",
                )

            current_version = await self._event_store.get_version(
                aggregate_type="invoice",
                aggregate_id=command.invoice_id,
            )

            # Wczytaj rzeczywisty stan z EventStore dla poprawnego reconstitute
            try:
                events = await self._event_store.read_stream(
                    aggregate_type="invoice",
                    aggregate_id=command.invoice_id,
                )
            except Exception:
                events = []

            # Określ status na podstawie ostatniego eventu
            last_status = "processing"
            if events:
                last_event = events[-1]
                event_type = getattr(last_event, "event_type", "")
                if "approved" in event_type:
                    last_status = "approved"
                elif "rejected" in event_type:
                    last_status = "rejected"
                elif "blocked" in event_type:
                    last_status = "blocked"
                elif "submitted" in event_type:
                    last_status = "pending_review"

            aggregate = self._InvoiceAggregate.reconstitute(
                id=command.invoice_id,
                number=None,
                contractor_nip=None,
                amount_net=None,
                amount_gross=None,
                currency="PLN",
                status=last_status,
                version=current_version,
                created_at=None,
                updated_at=None,
            )
            aggregate.approve(
                decision_id=command.decision_id,
                auto_approved=command.auto_approved,
                confidence=command.confidence,
            )
            events = aggregate.collect_events()

            await self._event_store.append_events(
                aggregate_type="invoice",
                aggregate_id=command.invoice_id,
                events=events,
                expected_version=current_version,
            )

            logger.info(
                "[CMDHANDLER] Invoice approved: id=%s auto=%s conf=%.2f",
                command.invoice_id,
                command.auto_approved,
                command.confidence,
            )

            return CommandResult(
                success=True,
                command_id=command.command_id,
                message=f"Invoice {command.invoice_id} approved",
                events_published=len(events),
                aggregate_id=command.invoice_id,
                aggregate_version=current_version + 1,
            )
        except Exception as exc:
            logger.exception("[CMDHANDLER] Invoice approve failed: %s", exc)
            return CommandResult(
                success=False,
                command_id=command.command_id,
                message=f"Approve failed: {exc}",
                error_detail=str(exc),
            )


__all__ = [
    "InvoiceSubmitCommand",
    "ApproveInvoiceCommand",
    "RejectInvoiceCommand",
    "BlockInvoiceCommand",
    "MarkInvoicePaidCommand",
    "InvoiceSubmitHandler",
    "ApproveInvoiceHandler",
    "CommandHandler",
    "CommandResult",
]
