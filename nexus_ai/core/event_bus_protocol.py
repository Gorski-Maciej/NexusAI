"""IEventBus Protocol — common interface for EventBus and JetStreamEventBus.

Enables type-safe switching between in-process and NATS-based event buses.
Both EventBus (core/bus.py) and JetStreamEventBus (events/jetstream_bus.py)
implement this protocol implicitly (structural subtyping via Protocol).

Usage:
    def publish_order(bus: IEventBus, order: OrderCreated) -> None:
        await bus.publish(order)
"""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from typing import Any, Protocol, TypeVar

from msgspec import Struct

EventT = TypeVar("EventT", bound=Struct)


class IEventBus(Protocol):
    """Protocol defining the contract for domain event buses.

    Implemented by:
      - EventBus (nexus_ai.core.bus) — in-process, typed, msgspec-based
      - JetStreamEventBus (nexus_ai.events.jetstream_bus) — NATS JetStream distributed
    """

    async def publish(self, event: Struct) -> bool:
        """Publish a domain event to all subscribers.

        Returns True if the event was successfully published.
        """
        ...

    async def connect(self) -> None:
        """Connect to the event bus (for networked buses like NATS)."""
        ...

    async def close(self) -> None:
        """Close the connection and release resources."""
        ...

    def subscribe(
        self,
        event_type: type[EventT],
        callback: Callable[[EventT], Awaitable[None]],
        *,
        name: str = "",
        filter_pred: Callable[[EventT], bool] | None = None,
    ) -> Any:
        """Register a subscriber for a specific event type."""
        ...

    @property
    def is_connected(self) -> bool:
        """Whether the bus is currently connected."""
        ...

    @property
    def subscriber_count(self) -> int:
        """Total number of registered subscribers."""
        ...
