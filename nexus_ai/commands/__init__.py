"""
nexus_ai/commands/ — Command Bus MediatR-Style (INNOWACJA #1 z Raportu v7.0).

Architektura Command Bus:
    ┌──────────────┐      ┌───────────────────┐      ┌──────────────┐
    │  Controller  │─────▶│   CommandBus      │─────▶│ CommandHandler│
    │  (API)       │      │   (dispatch)      │      │ (validate+exec)
    └──────────────┘      └─────────┬─────────┘      └──────┬───────┘
                                    │                        │
                          ┌─────────▼─────────┐    ┌─────────▼─────────┐
                          │  CommandValidator  │    │   Aggregate       │
                          │  (pre-exec)        │    │   (execute+save)  │
                          └───────────────────┘    └─────────┬─────────┘
                                                             │
                                                   ┌─────────▼─────────┐
                                                   │  EventPublisher   │
                                                   │  (NATS JetStream) │
                                                   └───────────────────┘

Usage:
    from nexus_ai.commands import CommandBus, InvoiceSubmitCommand, InvoiceSubmitHandler

    bus = CommandBus(
        event_store=EventStore(...),
        jetstream_bus=JetStreamEventBus(...),
    )
    bus.register(InvoiceSubmitCommand, InvoiceSubmitHandler())

    result = await bus.dispatch(InvoiceSubmitCommand(
        invoice_id="inv-123",
        contractor_nip="1234567890",
        amount_gross=Money(12300),
    ))
"""

from __future__ import annotations

# Lazy imports — nie triggerujemy całego łańcucha importów przy imporcie pakietu
# (EventStore → domain_events → SQLAlchemy → ...)
def __getattr__(name: str) -> Any:
    if name == "CommandBus":
        from nexus_ai.commands.bus import CommandBus as _mod
        return _mod
    if name == "CommandHandler" or name == "CommandResult":
        from nexus_ai.commands.bus import CommandHandler as _ch, CommandResult as _cr
        return _ch if name == "CommandHandler" else _cr
    if name in ("InvoiceSubmitCommand", "InvoiceSubmitHandler",
                "ApproveInvoiceCommand", "ApproveInvoiceHandler"):
        from nexus_ai.commands.handlers import (
            InvoiceSubmitCommand, InvoiceSubmitHandler,
            ApproveInvoiceCommand, ApproveInvoiceHandler,
        )
        return locals()[name]
    raise AttributeError(f"module 'nexus_ai.commands' has no attribute '{name}'")

__all__ = [
    "CommandBus",
    "CommandHandler",
    "CommandResult",
    "InvoiceSubmitCommand",
    "InvoiceSubmitHandler",
    "ApproveInvoiceCommand",
    "ApproveInvoiceHandler",
]
