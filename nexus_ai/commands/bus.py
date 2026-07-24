"""
CommandBus — centralny dispatcher komend z rejestracją handlerów.

INNOWACJA #1 z Raportu v7.0: MediatR-style Command → CommandHandler → Events.
Każda komenda przechodzi przez:
1. CommandValidator (walidacja)
2. CommandHandler (logika biznesowa, agregat)
3. EventPublisher (NATS JetStream)

Dzięki temu: pełna audytowalność, możliwość replay, separacja odpowiedzialności.
"""

from __future__ import annotations

import time as _time
from collections.abc import Callable
from typing import TYPE_CHECKING, Any

import msgspec
from structlog import get_logger

if TYPE_CHECKING:
    from nexus_ai.events.event_store import EventStore
    EventStoreType = EventStore
else:
    EventStoreType = Any

logger = get_logger("nexus.commands.bus")


# ── Typy bazowe ──────────────────────────────────────────────────────────


class Command(msgspec.Struct, kw_only=True):
    """Base command — msgspec.Struct dla ultraszybkiej serializacji."""

    command_id: str = ""
    correlation_id: str = ""
    tenant_id: str = ""
    actor_id: str = ""


class CommandResult(msgspec.Struct, kw_only=True):
    """Result wrapper for command execution."""

    success: bool
    command_id: str = ""
    message: str = ""
    events_published: int = 0
    aggregate_id: str = ""
    aggregate_version: int = 0
    duration_ms: float = 0.0
    error_detail: str = ""


class CommandHandler[T: Command]:
    """Base handler for a specific command type.

    Usage:
        class InvoiceSubmitHandler(CommandHandler[InvoiceSubmitCommand]):
            async def handle(self, cmd: InvoiceSubmitCommand) -> CommandResult:
                ...
    """
    __slots__ = ()

    async def validate(self, command: T) -> str | None:
        """Validate command before execution. Return error string or None."""
        return None

    async def handle(self, command: T) -> CommandResult:
        """Execute the command. Must be overridden by subclasses."""
        raise NotImplementedError


# ── Event Publisher Protocol ──────────────────────────────────────────────

class EventPublisher:
    """Publishes domain events to NATS JetStream after command execution."""
    __slots__ = ()

    async def publish(self, events: list[Any]) -> int:
        """Publish events. Returns count of successfully published."""
        raise NotImplementedError


# ── Command Bus ───────────────────────────────────────────────────────────


class CommandBus:
    """Central command dispatcher with handler registry.

    Rejestruje Command → CommandHandler mapowanie.
    Dispatche przechodzą przez: validate → handle → publish events.

    Args:
        event_store: EventStore do zapisu zdarzeń.
        event_publisher: EventPublisher do publikacji na NATS.

    Usage:
        bus = CommandBus(event_store=store, event_publisher=jetstream_pub)
        bus.register(InvoiceSubmitCommand, InvoiceSubmitHandler())
        result = await bus.dispatch(InvoiceSubmitCommand(...))
    """

    __slots__ = ("_event_publisher", "_event_store", "_handlers", "_validators")

    def __init__(
        self,
        event_store: EventStoreType = None,
        event_publisher: EventPublisher | None = None,
    ) -> None:
        self._handlers: dict[type[Command], CommandHandler] = {}
        self._validators: dict[type[Command], list[Callable]] = {}
        self._event_store = event_store
        self._event_publisher = event_publisher

    def register(
        self,
        command_type: type[T],
        handler: CommandHandler[T],
    ) -> None:
        """Register a command handler for a command type.

        Args:
            command_type: The Command subclass to handle.
            handler: The CommandHandler instance.
        """
        self._handlers[command_type] = handler
        logger.info("[CMDBUS] Registered %s → %s", command_type.__name__, type(handler).__name__)

    def register_validator(
        self,
        command_type: type[Command],
        validator: Callable[[Command], str | None],
    ) -> None:
        """Register a custom validator for a command type."""
        if command_type not in self._validators:
            self._validators[command_type] = []
        self._validators[command_type].append(validator)

    async def dispatch(self, command: Command) -> CommandResult:
        """Dispatch a command to its registered handler.

        Flow:
        1. Run validators (custom + handler.validate())
        2. Execute handler.handle()
        3. Return CommandResult

        Args:
            command: The Command instance to dispatch.

        Returns:
            CommandResult with success/failure and metadata.
        """
        t0 = _time.perf_counter()
        command_type = type(command)

        if command_type not in self._handlers:
            return CommandResult(
                success=False,
                command_id=command.command_id,
                message=f"No handler registered for {command_type.__name__}",
                duration_ms=(_time.perf_counter() - t0) * 1000,
            )

        handler = self._handlers[command_type]

        # ── Validation ──────────────────────────────────────────────
        # 1. Custom validators
        for validator in self._validators.get(command_type, []):
            error = validator(command)
            if error:
                return CommandResult(
                    success=False,
                    command_id=command.command_id,
                    message=f"Validation failed: {error}",
                    error_detail=error,
                    duration_ms=(_time.perf_counter() - t0) * 1000,
                )

        # 2. Handler validate()
        error = await handler.validate(command)
        if error:
            return CommandResult(
                success=False,
                command_id=command.command_id,
                message=f"Validation failed: {error}",
                error_detail=error,
                duration_ms=(_time.perf_counter() - t0) * 1000,
            )

        # ── Execute ─────────────────────────────────────────────────
        try:
            result = await handler.handle(command)
            result.command_id = command.command_id or result.command_id
            result.duration_ms = (_time.perf_counter() - t0) * 1000

            logger.info(
                "[CMDBUS] %s executed: success=%s dur=%.1fms",
                command_type.__name__,
                result.success,
                result.duration_ms,
            )
            return result
        except Exception as exc:
            logger.exception("[CMDBUS] %s execution failed", command_type.__name__)
            return CommandResult(
                success=False,
                command_id=command.command_id,
                message=f"Execution failed: {exc}",
                error_detail=str(exc),
                duration_ms=(_time.perf_counter() - t0) * 1000,
            )

    @property
    def handler_count(self) -> int:
        """Number of registered handlers."""
        return len(self._handlers)

    @property
    def registered_commands(self) -> list[str]:
        """List of registered command type names."""
        return [ct.__name__ for ct in self._handlers]


__all__ = [
    "Command",
    "CommandResult",
    "CommandHandler",
    "CommandBus",
    "EventPublisher",
]
